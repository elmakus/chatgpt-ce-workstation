#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

MODULE_PATH = Path(__file__).parent / "container" / "codex_marketplace_updater.py"
SPEC = importlib.util.spec_from_file_location("codex_marketplace_updater", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
updater = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = updater
SPEC.loader.exec_module(updater)


def completed(stdout: str, returncode: int = 0) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(
        args=list(updater.DEFAULT_COMMAND),
        returncode=returncode,
        stdout=stdout,
        stderr="",
    )


def success_json(
    selected: list[str] | None = None,
    upgraded: list[str] | None = None,
) -> str:
    return json.dumps(
        {
            "selectedMarketplaces": selected or [],
            "upgradedRoots": upgraded or [],
            "errors": [],
        }
    )


class MarketplaceUpdaterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.state_path = Path(self.temp_dir.name) / "state.json"

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def write_state(self, timestamp: float) -> None:
        self.state_path.write_text(
            json.dumps({"lastSuccessUnix": timestamp}),
            encoding="utf-8",
        )

    def read_state(self) -> float:
        return json.loads(self.state_path.read_text(encoding="utf-8"))[
            "lastSuccessUnix"
        ]

    def test_first_run_is_due_immediately(self) -> None:
        self.assertEqual(
            updater.seconds_until_due(None, now=1234.0),
            0.0,
        )

    def test_restart_before_due_waits_only_remaining_time(self) -> None:
        wait = updater.seconds_until_due(
            1_000.0,
            now=1_100.0,
            update_interval_seconds=300.0,
        )
        self.assertEqual(wait, 200.0)

    def test_exact_due_and_overdue_are_due(self) -> None:
        self.assertEqual(
            updater.seconds_until_due(1_000.0, 1_300.0, 300.0),
            0.0,
        )
        self.assertEqual(
            updater.seconds_until_due(1_000.0, 5_000.0, 300.0),
            0.0,
        )

    def test_zero_marketplaces_is_success_and_command_targets_all(self) -> None:
        seen: list[tuple[str, ...]] = []

        def runner(command):
            seen.append(tuple(command))
            return completed(success_json())

        payload = updater.run_marketplace_refresh(runner=runner)
        self.assertEqual(payload["selectedMarketplaces"], [])
        self.assertEqual(payload["upgradedRoots"], [])
        self.assertEqual(payload["errors"], [])
        self.assertEqual(seen, [updater.DEFAULT_COMMAND])
        self.assertEqual(seen[0][-4:], ("plugin", "marketplace", "upgrade", "--json"))

    def test_nonzero_command_status_fails_closed(self) -> None:
        with self.assertRaises(updater.RefreshError):
            updater.run_marketplace_refresh(
                runner=lambda command: completed("", returncode=7)
            )

    def test_json_reported_error_fails_closed(self) -> None:
        raw = json.dumps(
            {
                "selectedMarketplaces": ["broken"],
                "upgradedRoots": [],
                "errors": [{"marketplaceName": "broken", "message": "failed"}],
            }
        )
        with self.assertRaises(updater.RefreshError):
            updater.run_marketplace_refresh(runner=lambda command: completed(raw))

    def test_malformed_or_incomplete_json_fails_closed(self) -> None:
        for raw in ("{", "[]", '{"selectedMarketplaces":[],"errors":[]}'):
            with self.subTest(raw=raw), self.assertRaises(updater.RefreshError):
                updater.run_marketplace_refresh(
                    runner=lambda command, raw=raw: completed(raw)
                )

    def test_malformed_state_triggers_refresh_and_recovers(self) -> None:
        self.state_path.write_text("not-json", encoding="utf-8")
        times = iter([100.0, 125.0])

        result = updater.run_cycle(
            state_path=self.state_path,
            clock=lambda: next(times),
            runner=lambda command: completed(success_json()),
        )

        self.assertEqual(result.status, "success")
        self.assertEqual(result.sleep_seconds, updater.UPDATE_INTERVAL_SECONDS)
        self.assertEqual(self.read_state(), 125.0)

    def test_command_failure_does_not_advance_state_and_uses_bounded_retry(self) -> None:
        self.write_state(10.0)
        before = self.state_path.read_bytes()

        result = updater.run_cycle(
            state_path=self.state_path,
            clock=lambda: 100_000.0,
            runner=lambda command: completed("", returncode=3),
            retry_interval_seconds=321.0,
        )

        self.assertEqual(result, updater.CycleResult("failure", 321.0))
        self.assertEqual(self.state_path.read_bytes(), before)

    def test_json_error_does_not_advance_state(self) -> None:
        self.write_state(10.0)
        before = self.state_path.read_bytes()
        raw = json.dumps(
            {
                "selectedMarketplaces": ["broken"],
                "upgradedRoots": [],
                "errors": [{"marketplaceName": "broken", "message": "failed"}],
            }
        )

        result = updater.run_cycle(
            state_path=self.state_path,
            clock=lambda: 100_000.0,
            runner=lambda command: completed(raw),
        )

        self.assertEqual(result.status, "failure")
        self.assertEqual(self.state_path.read_bytes(), before)

    def test_not_due_does_not_run_command_or_mutate_state(self) -> None:
        self.write_state(1_000.0)
        before = self.state_path.read_bytes()
        calls = 0

        def runner(command):
            nonlocal calls
            calls += 1
            return completed(success_json())

        result = updater.run_cycle(
            state_path=self.state_path,
            clock=lambda: 1_100.0,
            runner=runner,
            update_interval_seconds=300.0,
        )

        self.assertEqual(result, updater.CycleResult("waiting", 200.0))
        self.assertEqual(calls, 0)
        self.assertEqual(self.state_path.read_bytes(), before)

    def test_interrupted_atomic_replace_preserves_previous_state(self) -> None:
        self.write_state(10.0)
        before = self.state_path.read_bytes()

        with mock.patch.object(
            updater.os,
            "replace",
            side_effect=OSError("simulated replace failure"),
        ):
            result = updater.run_cycle(
                state_path=self.state_path,
                clock=lambda: 100_000.0,
                runner=lambda command: completed(success_json(["one"], ["root"])),
                retry_interval_seconds=99.0,
            )

        self.assertEqual(result, updater.CycleResult("failure", 99.0))
        self.assertEqual(self.state_path.read_bytes(), before)
        self.assertEqual(
            list(self.state_path.parent.glob(f".{self.state_path.name}.*.tmp")),
            [],
        )

    def test_directory_fsync_failure_after_replace_keeps_committed_success(self) -> None:
        self.write_state(10.0)
        real_fsync = updater.os.fsync
        fsync_calls = 0
        times = iter([100_000.0, 100_123.0])

        def fail_directory_fsync(fd):
            nonlocal fsync_calls
            fsync_calls += 1
            if fsync_calls == 2:
                raise OSError("simulated directory fsync failure")
            return real_fsync(fd)

        with mock.patch.object(updater.os, "fsync", side_effect=fail_directory_fsync):
            result = updater.run_cycle(
                state_path=self.state_path,
                clock=lambda: next(times),
                runner=lambda command: completed(success_json(["one"], ["root"])),
                retry_interval_seconds=99.0,
            )

        self.assertEqual(
            result,
            updater.CycleResult("success", updater.UPDATE_INTERVAL_SECONDS),
        )
        self.assertEqual(self.read_state(), 100_123.0)
        self.assertEqual(fsync_calls, 2)
        self.assertEqual(
            list(self.state_path.parent.glob(f".{self.state_path.name}.*.tmp")),
            [],
        )

    def test_success_records_completion_time(self) -> None:
        times = iter([100.0, 123.5])

        result = updater.run_cycle(
            state_path=self.state_path,
            clock=lambda: next(times),
            runner=lambda command: completed(success_json(["one"], ["root"])),
        )

        self.assertEqual(result.status, "success")
        self.assertEqual(result.sleep_seconds, updater.UPDATE_INTERVAL_SECONDS)
        self.assertEqual(self.read_state(), 123.5)


if __name__ == "__main__":
    unittest.main()

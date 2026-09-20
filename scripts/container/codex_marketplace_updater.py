#!/usr/bin/env python3
from __future__ import annotations

import json
import logging
import math
import os
from pathlib import Path
import subprocess
import tempfile
import time
from dataclasses import dataclass
from typing import Callable, Sequence

UPDATE_INTERVAL_SECONDS = 24 * 60 * 60
RETRY_INTERVAL_SECONDS = 60 * 60
DEFAULT_STATE_PATH = Path(
    "/home/codex/.local/state/chatgpt-ce-workstation/codex-marketplace-updater.json"
)
DEFAULT_CODEX_BIN = "/opt/codex-desktop/resources/codex"
DEFAULT_COMMAND = (
    DEFAULT_CODEX_BIN,
    "plugin",
    "marketplace",
    "upgrade",
    "--json",
)

LOG = logging.getLogger("codex-marketplace-updater")


class RefreshError(RuntimeError):
    """Marketplace refresh did not produce a verified successful result."""


@dataclass(frozen=True)
class CycleResult:
    status: str
    sleep_seconds: float


def load_last_success(state_path: Path) -> float | None:
    try:
        raw = state_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None
    except OSError as exc:
        LOG.warning("Unable to read updater state; refresh is due now: %s", exc)
        return None

    try:
        data = json.loads(raw)
        value = data["lastSuccessUnix"]
        if isinstance(value, bool):
            raise ValueError("boolean timestamp")
        timestamp = float(value)
        if not math.isfinite(timestamp) or timestamp < 0:
            raise ValueError("invalid timestamp")
        return timestamp
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        LOG.warning("Malformed updater state; refresh is due now: %s", exc)
        return None


def seconds_until_due(
    last_success: float | None,
    now: float,
    update_interval_seconds: float = UPDATE_INTERVAL_SECONDS,
) -> float:
    if last_success is None:
        return 0.0
    return max(0.0, last_success + update_interval_seconds - now)


def atomic_write_last_success(state_path: Path, timestamp: float) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)

    fd, temp_name = tempfile.mkstemp(
        prefix=f".{state_path.name}.",
        suffix=".tmp",
        dir=state_path.parent,
    )
    temp_path = Path(temp_name)

    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(
                {"lastSuccessUnix": float(timestamp)},
                handle,
                separators=(",", ":"),
            )
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())

        os.replace(temp_path, state_path)

        directory_fd = os.open(state_path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    except BaseException:
        try:
            os.close(fd)
        except OSError:
            pass
        try:
            temp_path.unlink()
        except FileNotFoundError:
            pass
        raise


def validate_upgrade_json(stdout: str) -> dict[str, object]:
    try:
        payload = json.loads(stdout)
    except json.JSONDecodeError as exc:
        raise RefreshError("Codex returned malformed JSON") from exc

    if not isinstance(payload, dict):
        raise RefreshError("Codex JSON result is not an object")

    selected = payload.get("selectedMarketplaces")
    upgraded = payload.get("upgradedRoots")
    errors = payload.get("errors")

    if not isinstance(selected, list) or not all(isinstance(item, str) for item in selected):
        raise RefreshError("Codex JSON selectedMarketplaces is invalid")
    if not isinstance(upgraded, list) or not all(isinstance(item, str) for item in upgraded):
        raise RefreshError("Codex JSON upgradedRoots is invalid")
    if not isinstance(errors, list):
        raise RefreshError("Codex JSON errors is invalid")
    if errors:
        raise RefreshError(f"Codex reported {len(errors)} marketplace upgrade error(s)")

    return payload


def _default_runner(command: Sequence[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(command),
        check=False,
        capture_output=True,
        text=True,
    )


def run_marketplace_refresh(
    runner: Callable[[Sequence[str]], subprocess.CompletedProcess[str]] = _default_runner,
    command: Sequence[str] = DEFAULT_COMMAND,
) -> dict[str, object]:
    try:
        completed = runner(command)
    except OSError as exc:
        raise RefreshError("Unable to start bundled Codex marketplace refresh") from exc

    if completed.returncode != 0:
        raise RefreshError(
            f"Bundled Codex marketplace refresh exited with status {completed.returncode}"
        )

    return validate_upgrade_json(completed.stdout)


def run_cycle(
    *,
    state_path: Path = DEFAULT_STATE_PATH,
    clock: Callable[[], float] = time.time,
    runner: Callable[[Sequence[str]], subprocess.CompletedProcess[str]] = _default_runner,
    command: Sequence[str] = DEFAULT_COMMAND,
    update_interval_seconds: float = UPDATE_INTERVAL_SECONDS,
    retry_interval_seconds: float = RETRY_INTERVAL_SECONDS,
) -> CycleResult:
    now = clock()
    last_success = load_last_success(state_path)
    due_in = seconds_until_due(last_success, now, update_interval_seconds)

    if due_in > 0:
        LOG.info("Marketplace refresh is not due yet; waiting %.0f seconds", due_in)
        return CycleResult(status="waiting", sleep_seconds=due_in)

    try:
        payload = run_marketplace_refresh(runner=runner, command=command)
        success_timestamp = clock()
        atomic_write_last_success(state_path, success_timestamp)
    except (RefreshError, OSError) as exc:
        LOG.error(
            "Marketplace refresh failed; last-success state unchanged; retrying in %.0f seconds: %s",
            retry_interval_seconds,
            exc,
        )
        return CycleResult(status="failure", sleep_seconds=retry_interval_seconds)

    selected = payload["selectedMarketplaces"]
    upgraded = payload["upgradedRoots"]
    LOG.info(
        "Marketplace refresh succeeded; selected=%d upgraded=%d; next refresh in %.0f seconds",
        len(selected),
        len(upgraded),
        update_interval_seconds,
    )
    return CycleResult(status="success", sleep_seconds=update_interval_seconds)


def run_forever(
    *,
    state_path: Path = DEFAULT_STATE_PATH,
    clock: Callable[[], float] = time.time,
    sleeper: Callable[[float], None] = time.sleep,
    runner: Callable[[Sequence[str]], subprocess.CompletedProcess[str]] = _default_runner,
    command: Sequence[str] = DEFAULT_COMMAND,
) -> None:
    while True:
        result = run_cycle(
            state_path=state_path,
            clock=clock,
            runner=runner,
            command=command,
        )
        sleeper(result.sleep_seconds)


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="[codex-marketplace-updater] %(levelname)s: %(message)s",
    )
    run_forever()


if __name__ == "__main__":
    main()

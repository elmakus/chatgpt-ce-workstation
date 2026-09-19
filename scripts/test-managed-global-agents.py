#!/usr/bin/env python3
from __future__ import annotations
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[1]
HELPER = REPO_ROOT / "scripts/container/reconcile-global-agents.py"
SPEC = importlib.util.spec_from_file_location("reconcile_global_agents", HELPER)
assert SPEC and SPEC.loader
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)
PAYLOAD = (REPO_ROOT / "defaults/AGENTS.md").read_bytes()
LEGACY = [
    (REPO_ROOT / "defaults/AGENTS.legacy-pre-managed.md").read_bytes(),
    (REPO_ROOT / "defaults/AGENTS.legacy-workspace.md").read_bytes(),
]

def managed(payload: bytes) -> bytes:
    return mod._payload_block(payload)

class ReconcileGlobalAgentsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.target = Path(self.tmp.name) / "AGENTS.md"
        self.uid = os.getuid()
        self.gid = os.getgid()

    def run_reconcile(self) -> str:
        return mod.reconcile(self.target, PAYLOAD, LEGACY, self.uid, self.gid, 0o644)

    def test_fresh_seed_is_managed_and_idempotent(self) -> None:
        self.assertEqual(self.run_reconcile(), "seeded")
        first = self.target.read_bytes()
        self.assertEqual(first, managed(PAYLOAD))
        self.assertEqual(first.count(mod.START_TOKEN), 1)
        self.assertEqual(first.count(mod.END_TOKEN), 1)
        self.assertEqual(self.run_reconcile(), "current")
        self.assertEqual(self.target.read_bytes(), first)

    def test_valid_managed_update_preserves_all_outside_bytes(self) -> None:
        prefix = b"user-before\n\n"
        workflow = (
            b"<!-- codex-workflow-user-managed-start -->\n"
            b"workflow-owned\n"
            b"<!-- codex-workflow-user-managed-end -->\n"
        )
        suffix = b"\nuser-after\n"
        self.target.write_bytes(prefix + managed(b"old workstation policy\n") + workflow + suffix)
        self.assertEqual(self.run_reconcile(), "updated")
        self.assertEqual(self.target.read_bytes(), prefix + managed(PAYLOAD) + workflow + suffix)

    def test_known_live_legacy_layout_migrates_and_preserves_workflow_block(self) -> None:
        workflow = (
            b"\n<!-- codex-workflow-user-managed-start -->\n"
            b"workflow-owned\n"
            b"<!-- codex-workflow-user-managed-end -->\n"
        )
        self.target.write_bytes(LEGACY[0] + workflow)
        self.assertEqual(self.run_reconcile(), "migrated")
        self.assertEqual(self.target.read_bytes(), managed(PAYLOAD) + workflow)

    def test_historical_workspace_legacy_layout_is_exactly_recognized(self) -> None:
        tail = b"\nuser-tail\n"
        self.target.write_bytes(LEGACY[1] + tail)
        self.assertEqual(self.run_reconcile(), "migrated")
        self.assertEqual(self.target.read_bytes(), managed(PAYLOAD) + tail)

    def test_ambiguous_unmarked_content_is_unchanged(self) -> None:
        original = b"!" + LEGACY[0][1:] + b"\nuser-tail\n"
        self.target.write_bytes(original)
        result = self.run_reconcile()
        self.assertTrue(result.startswith("skipped-ambiguous:"))
        self.assertEqual(self.target.read_bytes(), original)

    def test_duplicate_markers_are_unchanged(self) -> None:
        original = managed(b"one\n") + managed(b"two\n")
        self.target.write_bytes(original)
        result = self.run_reconcile()
        self.assertTrue(result.startswith("skipped-malformed:"))
        self.assertEqual(self.target.read_bytes(), original)

    def test_unmatched_markers_are_unchanged(self) -> None:
        for original in (mod.START_TOKEN + b"\nbody\n", b"body\n" + mod.END_TOKEN + b"\n"):
            with self.subTest(original=original):
                self.target.write_bytes(original)
                result = self.run_reconcile()
                self.assertTrue(result.startswith("skipped-malformed:"))
                self.assertEqual(self.target.read_bytes(), original)

    def test_check_reports_only_current_managed_block_state(self) -> None:
        outside = b"private-before\n"
        self.target.write_bytes(outside + managed(PAYLOAD) + b"private-after\n")
        ok, detail = mod.check_current(self.target, PAYLOAD)
        self.assertTrue(ok)
        self.assertEqual(detail, "current managed workstation block verified")
        self.target.write_bytes(outside + managed(b"stale\n") + b"private-after\n")
        ok, detail = mod.check_current(self.target, PAYLOAD)
        self.assertFalse(ok)
        self.assertIn("does not match current image payload", detail)

if __name__ == "__main__":
    unittest.main()

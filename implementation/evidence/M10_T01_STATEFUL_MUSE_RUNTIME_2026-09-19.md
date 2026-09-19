# M10-T01 — Stateful Muse logical-worker runtime evidence

Date: 2026-09-19
Card: `implementation/cards/M10-T01.md`
Result: **GREEN**

## Exact source subject

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Base: `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- Result commit: `b225fad5ffa0497566ff9179ef684968a3d9be16`
- Local/result tree: `820d6c2e46c5954fce515a418ec4d1c90c227b2e`
- GitHub compare: exactly 1 commit ahead, 0 behind, 10 changed files.
- Production version metadata remains `1.1.17-private.11`; no release, tag, main update, or production install/promotion was performed.

## Implemented runtime contract

- Stable logical Muse `session_id` is separate from unique per-turn `invocation_id`.
- Private bounded `muse_sessions` registry binds logical worker identity, role, profile/allocation, canonical workspace, Task ID and opaque caller scope.
- Registry keys include caller scope plus logical-worker label, so identical labels such as A1 can exist independently in different lanes.
- Process-safe per-session `flock` lease permits at most one active invocation.
- Resume probes the exact retained Muse session using redacted export and fails closed on missing/unsafe/busy/binding-invalid state.
- Replacement is explicit: a new logical worker identity receives a new session; the adapter never silently relabels replacement state as A1/B1.
- Existing bounded structured result, private artifacts/retention, changed-path evidence and timeout/cancel process-tree cleanup remain in place.
- Runtime/orchestration docs no longer encode one-shot Muse repair/review behavior or depend on Project Workflow policy/state.

## Verification

Exact candidate checkout, clean after commit:

- `python3 -B scripts/test_workflow_runtime.py -v` — **90/90 GREEN**
- `python3 -B scripts/test_muse_adapter.py -v` — **24/24 GREEN**
- `python3 -B scripts/test_muse_profile.py -v` — **7/7 GREEN**
- `python3 -m compileall -q codex_workflow scripts` — GREEN
- `python3 -B codex_workflow/runtime/workflow.py validate --package-root codex_workflow --json` — `valid=true`
- candidate package build — GREEN
- candidate package archive verification — GREEN
- `git diff --check` — clean

The adapter regressions include same-session resume with distinct invocation IDs, A1/B1 separation, role/workspace/scope binding rejection, cross-scope A1 isolation, same-session busy rejection, unavailable-session fail-closed behavior with explicit A2 replacement, interrupted-turn cleanup followed by exact-session resume, and private registry/lease permissions.

## Production isolation readback

Before T01 source work, the running `chatgpt-ce-workstation` container reported:

- installed workflow version: `1.1.17-private.11`
- Muse Code: `1.3.0`

All T01 source/testing work used an isolated checkout under `/tmp/m10-stateful-muse-lifecycle`; production `~/.codex/codex_workflow` was not modified.

## Continuation

M10-T02 may run only against exact source commit `b225fad5ffa0497566ff9179ef684968a3d9be16`. If source changes, this T01 subject is superseded and applicable deterministic/live gates must be rerun before review freeze.

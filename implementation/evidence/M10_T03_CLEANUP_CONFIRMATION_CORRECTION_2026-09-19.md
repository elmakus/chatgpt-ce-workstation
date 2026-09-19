# M10-T03 — Fail-closed Muse process-tree cleanup correction evidence

Date: 2026-09-19
Card: `implementation/cards/M10-T03.md`
Result: **GREEN**

## Corrected exact source subject

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Prior RED-reviewed subject: `b225fad5ffa0497566ff9179ef684968a3d9be16`
- Corrected result subject: `b67785486ba5e2e996b8c6feaf1a163816a49d47`
- Remote readback: branch is exactly at the corrected result subject and is 3 commits ahead of the prior subject.
- Corrective diff is limited to `runtime/muse_sessions.py`, `runtime/muse_worker.py`, and `scripts/test_muse_adapter.py`.

The exact three corrected remote blob SHAs match the independently tested local tree:
- `runtime/muse_sessions.py`: `2789a07751324f1a8cbe337a502ef33e6636d5a9`
- `runtime/muse_worker.py`: `37243fc52779ba41ef29d67a52259befe47b1ea7`
- `scripts/test_muse_adapter.py`: `e4dc50c6b802f1f3db62b8a889dbd83bba9dd540`

## Correction

The R13 RED finding is corrected at source level:

- process-tree termination now returns an explicit cleanup-confirmation result;
- descendants discovered during graceful shutdown are added to the captured tree before hard escalation;
- after SIGKILL the adapter performs a bounded positive absence check instead of assuming cleanup succeeded;
- an interrupted turn whose cleanup cannot be confirmed returns normalized `adapter_internal` failure and enters durable `cleanup_unconfirmed` state;
- that durable state quarantines the canonical workspace so neither same-worker resume nor an explicit replacement worker can start there while cleanup remains unconfirmed;
- terminal/quarantine state is persisted before the process-local session flock is released; registry-persistence failure leaves the flock held fail-closed for the adapter-process lifetime.

## Deterministic verification

On the corrected tree:

- `python3 -B scripts/test_workflow_runtime.py -q` — **90/90 GREEN**
- `python3 -B scripts/test_muse_adapter.py -q` — **25/25 GREEN**
- `python3 -B scripts/test_muse_profile.py -q` — **7/7 GREEN**
- Python compile — GREEN
- workflow package validation — `valid=true`, version remains `1.1.17-private.11`
- `git diff --check` — clean
- local package build — GREEN
- generated package archive verification — GREEN

The new adapter regression forces an unconfirmed cleanup result and proves:
- the interrupted session is recorded as `cleanup_unconfirmed`;
- same A1 resume is rejected fail-closed;
- explicit A2 replacement in the same workspace is also rejected while the workspace is quarantined.

Existing live-child timeout/cancellation tests continue to prove the ordinary successful-cleanup path.

## Boundary

No release, tag, merge to `codex_workflow:main`, version bump, or production `~/.codex/codex_workflow` mutation was performed. T04 must now rerun the exact M10 live Meta-backed acceptance surface on `b67785486ba5e2e996b8c6feaf1a163816a49d47` before a replacement REQUIRED milestone review subject can be frozen.

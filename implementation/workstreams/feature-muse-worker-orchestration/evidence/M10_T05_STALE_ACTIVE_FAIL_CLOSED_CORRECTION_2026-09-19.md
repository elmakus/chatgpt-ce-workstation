# M10-T05 — stale-active fail-closed correction evidence

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T05.md`
Result: **GREEN**

## Exact corrected subject

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Prior RED-reviewed subject: `b67785486ba5e2e996b8c6feaf1a163816a49d47`
- Corrected immutable subject: `7f6f51fe9faf318fa90ce9414e6024c673ad9226`
- Remote branch readback points exactly to the corrected subject.
- `codex_workflow:main` remains unchanged at `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- Corrective delta is limited to `codex_workflow/runtime/muse_sessions.py` and `scripts/test_muse_adapter.py`.
- Exact corrected remote blobs:
  - `muse_sessions.py`: `11e2797a43558832fea9efb6399394d2c653085d`
  - `test_muse_adapter.py`: `86f392b07f340b44e06153cf6f7509dfb1f9b15c`

## Correction

The second independent-review RED is closed at source level.

Session acquisition now treats a durable workspace record in either `active` or `cleanup_unconfirmed` state as unreconciled and returns fail-closed `session_busy` before a new turn can acquire that workspace.

This preserves the original `cleanup_unconfirmed` quarantine and additionally covers the persistence-failure case where:
1. interrupted-turn process cleanup is not confirmed;
2. persisting the terminal quarantine fails;
3. the adapter process exits and its process-local flock is released by the OS;
4. the registry is left at stale `active`.

A stale `active` record can no longer be resumed as A1 and cannot be bypassed by allocating A2 in the same canonical workspace. Because `retire_worker_session` still requires a free lease, an actually running active invocation remains protected while an abandoned active mapping can be handled only through explicit reconciliation/retirement.

Normal `ready` reuse and the confirmed-cleanup `needs_probe` path remain unchanged.

## Deterministic persistence-failure regression

A new regression executes the failure in a child adapter process:
- the child creates A1 and forces `_run_process` to return timeout with `cleanup_confirmed=False`;
- the registry write is forced to fail specifically while writing `cleanup_unconfirmed`;
- the child process exits with the registry durably left at `active`, which also releases the process-local flock;
- a later fresh process attempts same A1 resume and receives `session_busy`;
- a later A2 replacement attempt in the same workspace also receives `session_busy`.

This directly covers the failure mode reproduced by the independent RED review.

## Verification on exact remote subject

A clean detached worktree was refreshed to remote subject `7f6f51fe9faf318fa90ce9414e6024c673ad9226`; its two corrected files were byte-identical to the locally tested correction tree before the final exact-subject rerun.

Exact-subject results:
- `python3 -B scripts/test_workflow_runtime.py -q` — **90/90 GREEN**
- `python3 -B scripts/test_muse_adapter.py -q` — **26/26 GREEN**
- `python3 -B scripts/test_muse_profile.py -q` — **7/7 GREEN**
- focused persistence-failure regression — **GREEN**
- Python compile — **GREEN**
- package build for `1.1.17-private.11` — **GREEN**
- generated package archive verification — **GREEN**
- `git diff --check` — **GREEN**
- exact remote worktree status after verification — clean

The package build initially rejected locally generated `__pycache__` produced by compile validation. Those disposable cache directories were removed, then package build/verification passed on unchanged source.

## Boundary

No release, tag, merge to `codex_workflow:main`, version bump, or production `~/.codex/codex_workflow` mutation was performed.

M10-T06 must now rerun the applicable isolated Meta-backed lifecycle/fault-injection acceptance surface on exact subject `7f6f51fe9faf318fa90ce9414e6024c673ad9226` before another REQUIRED milestone review subject is frozen.

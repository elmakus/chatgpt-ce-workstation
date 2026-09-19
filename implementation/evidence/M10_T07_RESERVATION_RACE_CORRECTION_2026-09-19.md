# M10-T07 — pre-lock reservation race correction evidence

Date: 2026-09-19
Card: `implementation/cards/M10-T07.md`
Result: **GREEN**

## Exact corrected subject

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Prior RED-reviewed subject: `7f6f51fe9faf318fa90ce9414e6024c673ad9226`
- Corrected immutable subject: `74a7588e5bab0a5b7a89549c4309486dc9e7ba4f`
- Remote branch readback points exactly to the corrected subject.
- `codex_workflow:main` remains unchanged at `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- Corrective delta is limited to `codex_workflow/runtime/muse_sessions.py` and `scripts/test_muse_adapter.py`.

## Correction

Session acquisition now treats `reserved`, `active`, and `cleanup_unconfirmed` records as workspace-level unreconciled states before any other logical worker can enter that canonical workspace.

A same-worker resume or replacement-worker creation arriving while the original creator is between durable reservation and per-session flock acquisition therefore fails closed with `session_busy`.

The losing-creator cleanup path additionally deletes a matching mapping only while it is still `state: reserved`; it cannot delete a mapping another process has advanced to a later state.

Normal `ready` reuse, confirmed-cleanup `needs_probe` resume, stale-`active` quarantine, `cleanup_unconfirmed` quarantine, binding and explicit replacement semantics remain unchanged.

## Deterministic regression

The new regression pauses creator A immediately after its durable A1 reservation and before the session flock:
- same A1 resume is rejected as `session_busy`;
- A2 replacement in the same canonical workspace is rejected as `session_busy`;
- creator A then continues, completes, and leaves the session `ready`;
- a later normal A1 resume succeeds and reuses the exact original session.

This closes the startup interleaving reproduced by the independent RED review.

## Exact-subject verification

Fresh detached exact-subject checkout:
- `python3 -B scripts/test_workflow_runtime.py -q` — **90/90 GREEN**
- `python3 -B scripts/test_muse_adapter.py -q` — **27/27 GREEN**
- `python3 -B scripts/test_muse_profile.py -q` — **7/7 GREEN**
- Python compile — **GREEN**
- package build for `1.1.17-private.11` — **GREEN**
- generated package archive verification — **GREEN**
- `git diff --check` — **GREEN**
- exact checkout remained clean after verification.

## Boundary

No release, tag, merge to `codex_workflow:main`, version bump, or production `~/.codex/codex_workflow` mutation was performed.

M10-T08 must now rerun the applicable isolated Meta-backed lifecycle/interrupted-turn/isolation acceptance surface on exact subject `74a7588e5bab0a5b7a89549c4309486dc9e7ba4f` before another REQUIRED milestone review subject is frozen.

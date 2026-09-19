# M10-T11 — retained resume lock-conflict reconciliation

Date: 2026-09-19
Card: `implementation/cards/M10-T11.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Reviewed RED baseline: `3a5d98b3c21fc37a527c3aa8eb0ed771e6428acb`
- Corrected exact result subject: `eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e`
- Final source blobs:
  - `codex_workflow/runtime/muse_sessions.py`: `b942e808b0981dc3c955d26cfd1195190b2cea6e`
  - `scripts/test_muse_adapter.py`: `8eee86af24df200a4b5f5673b4137512cc0480eb`
- The tested local working tree matched the final remote branch tree exactly.

## Correction

A retained-session resume now remembers the prior resumable state before atomically changing the registry record to `reserved`.

If non-blocking per-session flock acquisition then loses the narrow race against the previous invocation's terminal-state-before-unlock window, the failed resumer reacquires the registry guard and restores that same retained record from `reserved` to its prior `ready|needs_probe` state before returning `session_busy`.

This preserves both required orderings:
- terminal state is durably persisted before the finishing invocation releases its flock;
- resumed workspace reservation occurs before the registry guard is released.

It also prevents a transient flock conflict from leaving an ownerless permanent `reserved` record.

## Deterministic regression

A new regression pauses the finishing invocation after it has durably written `ready` but while it still owns the session flock. A concurrent resume:
- atomically reserves the retained record;
- fails the flock acquisition with `session_busy`;
- restores the retained registry state to `ready`;
- does not strand the workspace;
- succeeds on a later retry after the original invocation releases the flock, using the same retained session.

## Verification

On the exact final remote tree:

- `scripts/test_muse_adapter.py`: **29/29 GREEN**;
- `scripts/test_workflow_runtime.py`: **90/90 GREEN**;
- `scripts/test_muse_profile.py`: **7/7 GREEN**;
- Python compile validation: **GREEN**;
- `git diff --check`: **GREEN**;
- release package build: **GREEN**;
- package verify: **GREEN**;
- ZIP archive integrity: **GREEN**;
- final remote tree readback exactly matched the tested local tree.

## Boundary

No release, tag, merge to `codex_workflow:main`, or production runtime promotion was performed.

M10-T12 must now bind the required live Meta-backed lifecycle/interruption/isolation evidence to exact subject `eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e` before the next REQUIRED milestone review is frozen.

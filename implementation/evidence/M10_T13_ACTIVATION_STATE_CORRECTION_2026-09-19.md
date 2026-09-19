# M10-T13 — activation-state acquisition correction

Date: 2026-09-19
Card: `implementation/cards/M10-T13.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Reviewed RED baseline: `eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e`
- Corrected exact result subject: `ad62ffa515026714a42a610c0310b1f6e92f47bd`
- Final source blobs:
  - `codex_workflow/runtime/muse_sessions.py`: `52db5775bb9b94b245051a9052af4a7277886717`
  - `scripts/test_muse_adapter.py`: `ae1445dd307052f72ef4b64ddc6ede75625a15f6`
- Final remote branch readback exactly matched the tested Tower checkout.

## Correction

Session acquisition now keeps the process-safe registry guard until:
1. the exact per-session flock has been acquired non-blocking; and
2. the `active` state has been durably written.

This removes the previously exposed durable ownerless-`reserved` window between registry validation and session-lock acquisition. The registry guard serializes workspace acquisition while the non-blocking per-session flock preserves the existing no-deadlock lock ordering.

If persistence of the new `active` state fails after the flock was acquired, acquisition inspects durable state while the flock is still held and reconciles it to the exact pre-acquisition state:
- a failed newly-created worker leaves no retained mapping;
- a failed resumed worker remains at its prior `ready|needs_probe` state.

When that reconciliation is confirmed, the flock is released and the caller receives a normalized `adapter_internal` result. If reconciliation itself cannot be confirmed, the flock is deliberately retained fail-closed for the adapter process rather than exposing an unknown session.

Existing `reserved` records are still treated as unreconciled fail-closed state for compatibility/recovery; the corrected normal acquisition path no longer creates a durable reservation before it owns the session lease.

## Deterministic regression

The exact corrected subject adds/updates regression coverage proving:
- new-worker activation-persistence failure returns normalized `adapter_internal`, leaves no A1 mapping, and permits explicit A2 replacement;
- resumed-worker activation-persistence failure returns normalized `adapter_internal`, restores the exact A1 retained mapping to `ready`, and permits same-session retry;
- a creator paused at session-lock acquisition keeps competing same-worker resume and A2 adoption serialized behind the registry guard, after which both fail closed while the creator owns the active workspace;
- two retained sessions for the same workspace cannot cross the resume acquisition window; the competing retained session receives `session_busy`;
- the prior terminal-state-before-unlock lock-conflict, stale-active, cleanup-unconfirmed, binding and isolation guarantees remain covered.

## Verification

On the exact final remote tree:

- `scripts/test_muse_adapter.py`: **31/31 GREEN**;
- `scripts/test_workflow_runtime.py`: **90/90 GREEN**;
- `scripts/test_muse_profile.py`: **7/7 GREEN**;
- Python compile validation: **GREEN**;
- `git diff --check`: **GREEN**;
- release package build: **GREEN**;
- package verify: **GREEN**;
- ZIP archive integrity: **GREEN**;
- final remote tree readback exactly matched the tested Tower tree.

The initial package invocation after compile validation correctly refused generated `__pycache__` content. Those generated test caches were removed and the required clean package build/verify/archive-integrity checks then passed.

## Boundary

No release, tag, merge to `codex_workflow:main`, or production runtime promotion was performed.

M10-T14 must now bind the required live Meta-backed lifecycle/interruption/isolation evidence to exact subject `ad62ffa515026714a42a610c0310b1f6e92f47bd` before the next REQUIRED milestone review is frozen.

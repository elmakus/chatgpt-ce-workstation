# M10-T15 — process-safe nested-workspace isolation correction

Date: 2026-09-19
Card: `implementation/cards/M10-T15.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- RED reviewed baseline: `ad62ffa515026714a42a610c0310b1f6e92f47bd`
- Corrected exact result subject: `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`
- Final remote source/test blob readback exactly matched the independently tested Tower checkout.

## Correction

The process-safe durable session-acquisition boundary now treats two canonical workspaces as conflicting when they are equal or either is an ancestor of the other. The check executes under the existing registry guard before the per-session lease is granted.

This extends the existing exact-workspace guard to the R15 equal-or-nested requirement without changing the managed batch helper, session binding, lock ordering, resume semantics, activation-persistence reconciliation, quarantine behavior or explicit replacement semantics.

## Deterministic regressions

Direct session-registry tests outside `execute_workers_concurrently(...)` prove:
- parent workspace active -> nested child acquisition fails closed with `session_busy`;
- nested child active -> parent acquisition fails closed with `session_busy`;
- sibling/non-overlapping workspaces can hold independent leases concurrently.

The prior managed-batch overlap test remains present.

## Exact-subject verification

On exact remote `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`:
- `scripts/test_muse_adapter.py`: **33/33 GREEN**;
- `scripts/test_workflow_runtime.py`: **90/90 GREEN**;
- `scripts/test_muse_profile.py`: **7/7 GREEN**;
- Python compile validation: **GREEN**;
- `git diff --check`: **GREEN**;
- release package build: **GREEN**;
- package verification: **GREEN**;
- ZIP archive integrity: **GREEN**;
- final exact-subject checkout remained clean.

## Boundary

No release, tag, merge to `codex_workflow:main`, or production runtime promotion was performed.

M10-T16 must now bind the required live Meta-backed lifecycle/interruption/isolation evidence to exact corrected subject `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655` before freezing the next REQUIRED milestone review attempt.

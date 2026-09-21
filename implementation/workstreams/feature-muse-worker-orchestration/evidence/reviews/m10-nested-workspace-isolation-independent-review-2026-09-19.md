# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@ad62ffa515026714a42a610c0310b1f6e92f47bd`
Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Scope checked

The exact immutable candidate was reviewed against the approved M10/R6 milestone contract, `requirements/MUSE_MAX_RUNTIME.md` (R7-R15/R17 plus preserved regression boundaries), D21, M10-T13/T14 contracts/evidence, prior corrective review evidence, and the actual exact-subject source/tests.

Independent exact-subject verification on Tower was GREEN for:
- `scripts/test_workflow_runtime.py`: 90/90;
- `scripts/test_muse_adapter.py`: 31/31;
- `scripts/test_muse_profile.py`: 7/7;
- Python compile and `git diff --check`;
- release package build, package verification, and ZIP integrity.

The M10 diff from the accepted source baseline contains no Project Workflow Task Board/review-state implementation dependency.

## Blocking finding

**Process-safe workspace isolation does not reject nested active workspaces outside one managed batch.**

R15 requires the runtime to reject equal/nested conflicting workspaces for concurrent lanes. The managed `execute_workers_concurrently(...)` helper preflights equal/nested paths, but the durable/process-safe acquisition path in `runtime/muse_sessions.py::acquire_worker_session()` checks active/reserved/quarantined workspace conflicts only with exact string equality.

A deterministic exact-subject reproduction held an active lease for a logical worker bound to a parent workspace, then directly acquired a second logical worker on a nested child workspace using the same durable runtime registry. The second acquisition succeeded and returned a distinct live session instead of `session_busy`/fail-closed rejection.

This means two independent adapter callers/processes can concurrently own overlapping parent/child workspaces even though M10/R15 requires runtime isolation against that conflict. The existing batch-helper test does not cover the process-safe registry boundary.

## Corrective classification

This is a bounded L1/L2 implementation defect inside accepted M10 authority. No Project Definition or Master Plan change is required.

Correction must:
- enforce canonical equal-or-nested workspace conflict detection in the durable acquisition path while the registry guard is held;
- preserve same-worker resume semantics and existing reservation/activation/quarantine fail-closed behavior;
- add deterministic coverage for both parent-active -> child-attempt and child-active -> parent-attempt outside the managed batch helper;
- rerun the complete exact-subject regression/package checks;
- rerun the applicable live M10 lifecycle/interruption/isolation acceptance surface on the corrected immutable subject;
- freeze that corrected subject as a new REQUIRED M10 independent-review attempt.

No additional blocking finding was identified.

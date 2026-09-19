# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@74a7588e5bab0a5b7a89549c4309486dc9e7ba4f`
Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Scope checked

The exact immutable candidate was reviewed against the approved M10/R6 milestone contract, `requirements/MUSE_MAX_RUNTIME.md` (especially R7-R15/R17 and acceptance outcomes), D21, the stateful-session research record, M10-T07/T08 contracts/evidence, and the actual source/tests at the review subject.

Remote readback confirmed:
- `impl/m10-stateful-muse-lifecycle` is identical to the review subject;
- the subject is nine commits ahead of production/source baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- `codex_workflow:main`/production promotion remains outside M10.

Independent exact-subject verification on a disposable Tower checkout was GREEN:
- `scripts/test_workflow_runtime.py`: 90/90;
- `scripts/test_muse_adapter.py`: 27/27;
- `scripts/test_muse_profile.py`: 7/7;
- Python compile and `git diff --check`: GREEN.

M10-T08 live evidence is coherent with the exact subject and demonstrates the required Meta-backed A1/B1 lifecycle, interrupted-turn cleanup/resume, two-lane isolation, private artifacts, and unchanged production runtime for the exercised paths.

## Blocking finding

**Resume acquisition is not atomically reserved at workspace scope, so two existing logical sessions can concurrently become active in the same workspace.**

`runtime/muse_sessions.py::acquire_worker_session()` checks for workspace records in `reserved|active|cleanup_unconfirmed` while holding the registry guard. New-session creation then writes its own record as `reserved` before releasing that guard, which closes the pre-lock creator race addressed by M10-T07.

The `resume=True` path does not perform an equivalent reservation transition. A ready/needs-probe record is validated under the registry guard, the guard is released while its record remains non-reserved, and only after acquiring the per-session flock does `_update_state(..., "active")` run.

A deterministic exact-subject reproduction forced two different retained workers A1/A2, both bound to the same workspace and caller scope, to pause after their registry validation but before their distinct session locks. Both resumptions then proceeded. While both invocations were held in the process-execution path, durable registry readback showed **both A1 and A2 simultaneously `active` for the same canonical workspace**. Both calls had passed normal resume probing and owned different session locks, so per-session locking cannot prevent this workspace collision.

This violates the accepted R15 runtime-safety requirement to reject conflicting concurrent workspaces and the M10 isolation/one-active-lane safety surface. The current T07 reservation regression covers a **new creator** paused before its session lock, but not the equivalent pre-lock window for **resuming existing sessions**.

## Corrective classification

This is a bounded L1/L2 implementation defect inside accepted M10 authority. No Project Definition or Master Plan change is required.

Correction must:
- make workspace acquisition for resume process-safe/atomic before releasing the registry guard, without allowing two retained sessions for the same workspace to cross the pre-lock window;
- preserve per-session locking, binding checks, explicit replacement semantics, stale-active and cleanup-unconfirmed fail-closed behavior;
- add deterministic regression coverage for concurrent resume of two retained sessions sharing one workspace (and preserve the creator-reservation regression);
- rerun the complete exact-subject regression suite;
- rerun the applicable live M10 lifecycle/interrupted-turn/isolation acceptance surface on the corrected immutable source subject;
- freeze the resulting changed source as a new REQUIRED independent M10 review subject.

No additional blocking finding was identified in this review.

# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e`
Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Scope checked

The exact immutable candidate was reviewed against the approved M10/R6 milestone contract, `requirements/MUSE_MAX_RUNTIME.md` (R7-R15/R17 plus preserved regression boundaries), D21, M10-T11/T12 contracts/evidence, prior corrective review evidence, and actual exact-subject source/tests.

Remote readback confirmed `impl/m10-stateful-muse-lifecycle` points exactly to the review subject and `codex_workflow:main` remains the source-only baseline outside M10 publication scope.

Independent exact-subject verification on Tower was GREEN:
- `scripts/test_workflow_runtime.py`: 90/90;
- `scripts/test_muse_adapter.py`: 29/29;
- `scripts/test_muse_profile.py`: 7/7;
- Python compile and `git diff --check`: GREEN.

M10-T12 live evidence is coherent with this exact subject and covers the required Meta-backed A1/B1 lifecycle, interrupted-turn cleanup/resume, two-lane isolation, private artifacts, and unchanged production runtime on the exercised paths.

## Blocking finding

**A failure while advancing a durable session reservation to `active` can leave an ownerless `reserved` record that permanently blocks the workspace and prevents explicit A2/B2 recovery.**

`runtime/muse_sessions.py::acquire_worker_session()` durably writes a new or resumed worker as `reserved`, then acquires its per-session flock, and only afterward calls `_update_state(..., "active")`. If that durable state update raises after the flock has been acquired, the current exception path releases the lease and re-raises but does not delete a newly-created reservation or restore a resumed reservation to its prior resumable state.

An independent deterministic exact-subject reproduction forced `_update_state(..., "active")` to fail after successful lock acquisition. Observed result:
- the adapter raised the persistence error rather than returning a normalized worker result;
- the durable registry remained `state=reserved` after the lease was released;
- a distinct replacement worker A2 in the same canonical workspace failed with `session_busy`: "Muse workspace has an in-flight session reservation; wait for it to resolve";
- no invocation still owned that reservation, so waiting cannot resolve it.

This violates the M10/R9/R14 fail-closed recovery contract: an unsafe/failed logical-worker acquisition must not silently corrupt durable lifecycle state, and explicit replacement recovery must remain possible after the failed worker can no longer proceed. It also leaves a runtime-internal persistence failure outside the normal normalized failure path.

## Corrective classification

This is a bounded L1/L2 implementation defect inside accepted M10 authority. No Project Definition or Master Plan change is required.

Correction must:
- reconcile a `reserved` record safely when the post-lock transition to `active` fails, for both newly-created and resumed logical workers;
- preserve the existing creator-reservation, resume-reservation, terminal-lock-conflict, stale-active and cleanup-unconfirmed fail-closed guarantees;
- avoid exposing an ownerless `reserved` record as an indefinitely in-flight reservation after the lease is gone;
- normalize the acquisition failure when durable reconciliation is possible;
- add deterministic regression coverage for this exact post-lock activation-persistence failure;
- rerun the complete exact-subject regression/package checks;
- rerun the applicable live M10 lifecycle/interruption/isolation acceptance surface on the corrected immutable subject;
- freeze the corrected immutable source as a new REQUIRED M10 independent-review subject.

No additional blocking finding was identified.

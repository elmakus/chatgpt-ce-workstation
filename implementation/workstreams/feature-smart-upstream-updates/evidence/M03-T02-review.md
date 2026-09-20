# M03-T02 independent review

Verdict: **RED**

Review subject: `83e77ed669a2d58da248e052896c6c44a90f8972`
Workstream: `feature-smart-upstream-updates`
Card: `M03-T02`

## Scope reviewed

Independent review against:
- `implementation/workstreams/feature-smart-upstream-updates/cards/M03-T02.md`;
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m03--safe-promoteverifyrollback-updater`;
- requirements R1, R2, R9-R16;
- accepted decisions D4, D5, D10, D15, D16 and D25;
- independently GREEN M02 checkpoint and completed M03-T01 dependency;
- exact M03 source, isolated orchestration tests, target-reconciliation evidence and GitHub CI/candidate-build evidence.

## Evidence verified

- The immutable subject contains the expected resolver -> preflight -> exact build -> candidate readback -> production baseline capture -> promotion -> health/runtime verification -> rollback orchestration.
- GitHub CI run #154 and Exact candidate build run #19 are GREEN.
- Both PR-triggered runs checked out synthetic merge commit `0a73c378071f38f2bc02fd25678b709030acbeaf`, not the literal head SHA. Exact Git comparison `83e77ed... -> 0a73c37...` contains zero changed files, so the tested tree is behaviorally identical to the frozen review subject.
- CI source validation includes `UPDATE_ORCHESTRATION_TESTS_GREEN` and `SOURCE_VALIDATION_GREEN`; candidate build/readback verifies matching resolution label and embedded manifest.
- Current branch commits after the review subject change only Task Board / implementation-evidence bookkeeping, not reviewed behavior.

## Blocking finding

The rollback-failure branch does not emit or persist the **actual post-failure production recovery state** required by the M03 plan and R11.

In `scripts/update.sh`, when rollback recreation fails, rollback health/runtime verification fails, or the restored image mismatches, `rollback_after_failure` records only:
- the intended previous image ID;
- the rollback tag;
- the candidate image ID;
- the original update-failure reason.

It does not re-read and persist the current container existence/ID, running state, health state and actual image ID after the failed rollback attempt.

Therefore a `rollback_failed` result cannot distinguish important real recovery states such as:
- candidate still running;
- previous image recreated but unhealthy;
- container missing/stopped;
- unexpected/mismatched image running.

That falls short of the accepted requirement to fail loudly with the **exact recovery state**. The current `rollback_fail` fixture also does not assert an actual-state snapshot, so the gap is not covered by automated acceptance.

## Corrective route

This is a bounded L1/L2 implementation correction inside existing M03 authority. The correction should:
- capture a best-effort post-rollback production-state snapshot on every rollback failure;
- persist/report that snapshot without secrets;
- add deterministic fixture coverage for representative rollback-failure states;
- rerun the M03 acceptance checks;
- freeze a new exact review subject for fresh independent review.

No requirement, architecture decision, milestone strategy or production-write authorization change is needed.

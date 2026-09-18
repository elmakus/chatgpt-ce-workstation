# M09-T01 independent review — managed Muse lane concurrency

Date: 2026-09-18

## Verdict

**GREEN**

No blocking defect was found in the exact M09-T01 source candidate.

## Exact subject

- reviewed repository: `elmakus/codex_workflow`
- reviewed commit: `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`
- reviewed branch: `impl/m09-muse-lane-concurrency`
- PR: `elmakus/codex_workflow#6`
- accepted predecessor checkpoint: `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`

The PR head readback matched the immutable review subject and remained open/unmerged during review.

## Authority checked

The review applied:

- `implementation/cards/M09-T01.md`;
- approved `planning/MASTER_PLAN.md` R2, Milestone M09;
- `requirements/MUSE_MAX_RUNTIME.md` R1-R16 as applicable, especially R1, R2, R3, R7-R16 and R15 lane ownership;
- `docs/DECISIONS.md` D21;
- `project-handoffs/M08_HANDOFF.md`;
- `implementation/evidence/M08_SEQUENTIAL_ORCHESTRATION_2026-09-18.md`;
- exact accepted Muse adapter predecessor `elmakus/codex_workflow@b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`;
- implementation evidence `implementation/evidence/M09_SOURCE_CANDIDATE_2026-09-18.md`.

## Independent source inspection

GitHub compare from the accepted M07/M08 adapter checkpoint to the review subject reports eight commits and only six changed files:

- `.github/workflows/tests.yml`;
- `README.md`;
- `RELEASING.md`;
- `codex_workflow/delegation.md`;
- `codex_workflow/runtime/muse_worker.py`;
- `scripts/test_muse_adapter.py`.

No `compute_profiles.py`, worker TOML, Companion allocation, or other-profile lifecycle implementation changed in the M09 delta.

The exact source implements a bounded managed batch over the existing single-invocation adapter:

- caller supplies the complete invocation set and assigned workspaces;
- equal and ancestor/descendant workspace overlap is rejected before the pool launches;
- one batch is bounded to eight invocations and a bounded worker count;
- Project Workflow/Main dependency, `parallel_safe`, branch/worktree and Task Board authority is not duplicated;
- each lane reuses `execute_worker`, preserving per-process timeout, cancellation, process-tree cleanup, normalized-result and private-artifact behavior;
- results remain input-ordered while healthy lanes are not cancelled by a normalized failure or cancellation in another lane;
- run IDs/directories are checked for collision;
- retention mutation is serialized in-process and all run directories belonging to the active managed batch are preserved during lane retention passes;
- executor -> Tester -> optional repair -> fresh Tester ordering remains outside the batch helper and is documented as Main/Project Workflow authority.

The concurrency regression section independently covers two-lane simultaneous start, overlap rejection, model-failure isolation, cancellation/process-tree isolation, distinct artifacts and active-run retention protection.

Documentation readback is consistent with D21/R15: `muse-max` remains mixed-harness, Companion remains persistent internal Luna XHigh, six roles remain Muse leaf invocations, unmanaged shell background orchestration remains forbidden, and `plus`, `luna-xhigh`, and `pro-x5` remain Codex-backed.

## Verification readback

Exact-head GitHub Actions run `35378766734` completed successfully. Its job reports GREEN steps for:

- workflow runtime regression;
- Muse adapter regression;
- Python compile check;
- Muse Max profile regression;
- package validation;
- package build;
- release archive verification.

The implementation evidence records 90/90 workflow runtime tests, 17/17 Muse adapter tests and 7/7 profile tests GREEN on the exact subject. The final CI correction removes generated `__pycache__` directories before packaging.

## Review conclusion

M09-T01 satisfies its source-only acceptance contract and may advance to post-review Card finalization and M09 JIT continuation.

This verdict does **not** satisfy or waive the remaining M09 live gates. Still unsatisfied:

- live two-lane Muse smoke on isolated disposable worktrees;
- live creation and in-session reuse of exactly one internal GPT-5.6 Luna XHigh Companion on the exact reviewed candidate;
- publication/release;
- workstation production promotion/readback.

Under approved Master Plan R2, the Companion gate must be GREEN before publication or production promotion; a quota/runtime rejection is not a substitute pass.

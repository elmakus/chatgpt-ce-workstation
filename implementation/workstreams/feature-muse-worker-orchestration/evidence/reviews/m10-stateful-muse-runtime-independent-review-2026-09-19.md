# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@b225fad5ffa0497566ff9179ef684968a3d9be16`

Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`

## Scope checked

The exact immutable candidate was reviewed against M10/R6, amended `requirements/MUSE_MAX_RUNTIME.md` R7-R15 and R17, D21, the M10-T01/T02 contracts, the stateful-session research record, and the bounded live evidence from M10-T02.

GitHub readback confirmed:
- `impl/m10-stateful-muse-lifecycle` is identical to the review subject;
- the review subject is exactly one commit ahead of baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- `codex_workflow:main` remains identical to the baseline, so M10 did not publish/promote the candidate.

Independent rerun on the clean exact candidate checkout was GREEN:
- `scripts/test_workflow_runtime.py`: 90/90;
- `scripts/test_muse_adapter.py`: 24/24;
- `scripts/test_muse_profile.py`: 7/7;
- Python compile, package validation and `git diff --check`: GREEN.

The live M10-T02 evidence is coherent with the reviewed subject and demonstrates the required Meta-backed A1/B1 reuse cycle, successful interrupted-turn cleanup/resume in the exercised case, two-lane isolation, private artifacts, and unchanged production version.

## Blocking finding

**R13 process-tree cleanup confirmation is not enforced by the runtime before the session lease is released.**

R13 requires that after timeout/cancellation the runtime release the session lease **only after process-tree cleanup is confirmed**.

In `codex_workflow/runtime/muse_worker.py`:
- `_terminate_process_tree()` checks `_tree_is_gone(snapshot)` only during the graceful-termination loop;
- after escalation to SIGKILL it waits on the root process but performs no final `_tree_is_gone(snapshot)` check and returns even when cleanup was not confirmed;
- `_run_process()` then returns to `execute_worker()`;
- `execute_worker()` records `needs_probe` and calls `finish_worker_session(...)`, which releases the per-session flock lease.

A read-only fault simulation against the exact candidate forced the termination helper's cleanup probe to remain false and the signal operations to be ineffective. The helper still returned; with zero grace the cleanup predicate was never called at all (`returned_without_confirmed_cleanup=True`). Existing timeout/cancellation regressions prove the normal successful-kill path, but they do not cover fail-closed behavior when cleanup cannot be confirmed.

This is a direct mismatch with accepted R13 and the M10 milestone acceptance surface. The successful live fault injection does not remove the source-level gap because it proves one cleanup instance, not the required invariant for all interrupted turns.

## Corrective classification

The defect is a bounded L1/L2 implementation correction inside already accepted M10 authority. No Project Definition or Master Plan change is required.

Correction must:
- make termination/cancellation explicitly confirm the captured Muse process tree is gone after escalation before treating cleanup as complete and before releasing the logical-session lease;
- fail closed when cleanup cannot be confirmed, without presenting the session as safely resumable;
- add deterministic regression coverage for the unconfirmed-cleanup path;
- preserve the existing successful timeout/cancel cleanup, stateful resume, binding/locking, lane isolation, structured result/artifact and non-`muse-max` behavior;
- rerun the applicable exact-subject regression suite;
- because source changes, produce a new exact M10 review subject and rerun the applicable live interrupted-turn gate needed to bind live evidence to that corrected immutable subject before REQUIRED independent review is frozen again.

No other blocking finding was identified in this review.

# M10 corrected stateful Muse runtime — independent review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@b67785486ba5e2e996b8c6feaf1a163816a49d47`

Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Scope checked

The exact immutable corrected subject was reviewed against M10/R6, approved `requirements/MUSE_MAX_RUNTIME.md` R7-R15/R17 plus the preserved regression boundaries, D21, M10-T03/T04, the prior RED evidence, and the bounded live evidence from M10-T04.

Remote readback confirmed:
- `impl/m10-stateful-muse-lifecycle` points exactly to `b67785486ba5e2e996b8c6feaf1a163816a49d47`;
- `codex_workflow:main` remains `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- the correction from the prior RED subject is limited to `runtime/muse_sessions.py`, `runtime/muse_worker.py`, and `scripts/test_muse_adapter.py`.

Independent clean-worktree verification on the exact subject was GREEN:
- `scripts/test_workflow_runtime.py`: 90/90;
- `scripts/test_muse_adapter.py`: 25/25;
- `scripts/test_muse_profile.py`: 7/7;
- Python compile and `git diff --check`: GREEN.

The M10-T04 evidence is coherent with the exact subject and demonstrates the required Meta-backed A1/B1 reuse cycle, successful live interrupted-turn cleanup/resume, two-lane isolation, private artifacts, and unchanged production runtime.

## Blocking finding

**The new `cleanup_unconfirmed` quarantine is not durable when persisting that state fails, so a later adapter process can unsafely resume the affected logical worker/workspace.**

The corrected source intentionally changed `finish_worker_session()` to persist terminal/quarantine state before releasing the flock. If `_save_registry()` fails, the flock is left open only for the lifetime of the current adapter process. However:
- the durable registry can remain at stale state `active`;
- `acquire_worker_session(..., resume=True)` does not reject an existing `active` record;
- after the failed adapter process exits, the OS closes the leaked flock;
- a new adapter process can acquire the lock, probe the retained session, and resume it even though the prior timeout/cancel cleanup was explicitly unconfirmed.

A two-process read-only fault simulation on the exact subject reproduced this:
1. force `_run_process()` to return timeout + `cleanup_confirmed=False`;
2. force registry persistence to fail exactly when writing `cleanup_unconfirmed`;
3. first adapter process exits with `OSError: simulated registry persistence failure`;
4. durable registry remains `state: active`;
5. second fresh adapter process resumes the same A1/session/workspace and returns `completed`, `session_state=ready`, `resumed=True`.

This violates R13 and M10-T03 acceptance: when cleanup cannot be confirmed, the affected session/workspace must not be exposed as safe for another Muse turn until explicit reconciliation.

## Corrective classification

This is a bounded L1/L2 implementation correction inside accepted M10 authority. No Definition or Master Plan change is required.

Correction must make the fail-closed state survive adapter-process exit even if the primary terminal-state registry update fails. A stale `active` record created by an interrupted/unreconciled process must not be resumable as a normal retained worker without explicit safe reconciliation. Add deterministic cross-process/persistence-failure regression coverage, preserve the normal successful resume path, rerun the complete exact-subject regression suite, and rerun the applicable live M10 interrupted-turn/lifecycle gate on the corrected immutable subject before freezing another REQUIRED milestone review attempt.

No other blocking finding was identified.

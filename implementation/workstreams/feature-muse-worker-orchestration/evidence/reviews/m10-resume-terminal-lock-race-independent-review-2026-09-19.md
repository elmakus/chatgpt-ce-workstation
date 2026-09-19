# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@3a5d98b3c21fc37a527c3aa8eb0ed771e6428acb`
Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Scope checked

The exact immutable candidate was reviewed against the approved M10/R6 milestone contract, `requirements/MUSE_MAX_RUNTIME.md` (especially R7-R15/R17 and acceptance outcomes), D21, M10-T09/T10 contracts/evidence, and the actual source/tests at the review subject.

Remote readback confirmed `impl/m10-stateful-muse-lifecycle` is exactly the review subject. The candidate remains source/test-only relative to production baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.

The T09/T10 evidence is coherent for the exercised paths, including resume-side workspace reservation, live A1/B1 reuse, interrupted-turn cleanup/resume, two-lane isolation, private artifacts, and unchanged production runtime.

## Blocking finding

**A resume attempt can permanently strand a retained worker/workspace in `reserved` when it races with the previous invocation's terminal-state persistence window.**

`runtime/muse_sessions.py::finish_worker_session()` intentionally persists the terminal state (`ready` or `needs_probe`) before releasing the per-session flock. That ordering is fail-closed if persistence itself fails.

The corrected resume path in `acquire_worker_session()` now changes a resumable record from `ready|needs_probe` to `reserved` while still holding the registry guard, then releases the guard and attempts the per-session flock non-blocking.

This creates a narrow but valid interleaving:

1. invocation P1 still owns the session flock;
2. P1 persists its record as `ready` (or `needs_probe`) and has not yet released the flock;
3. P2 starts resume, sees the resumable record, persists it as `reserved`, and releases the registry guard;
4. P2 fails to acquire the still-held session flock with `BlockingIOError`;
5. because this is a retained session (`created == false`), the lock-failure path does not restore the prior resumable state;
6. P1 then releases its flock, but the durable registry remains `reserved` indefinitely.

Every later resume or explicit replacement in that workspace is then rejected as `session_busy` because the stale reservation is treated as an in-flight workspace reservation. The reservation has no owner left that can resolve it.

The current deterministic reservation tests cover:
- a new creator paused before its session lock;
- a retained resumer paused after reservation and before its session lock;
- an already-`active` same-session overlap.

They do not cover the terminal-state-before-flock-release window above.

This violates the M10/R7-R9/R14 recovery contract: a transient lease conflict must fail closed without corrupting durable session state, and explicit A2/B2 recovery must remain possible when the old logical worker cannot proceed.

## Corrective classification

This is a bounded L1/L2 implementation defect inside accepted M10 authority. No Project Definition or Master Plan change is required.

Correction must:
- make retained-session lock-acquisition failure after durable reservation reconcile the reservation safely instead of leaving an ownerless `reserved` record;
- preserve the terminal-state-before-unlock fail-closed ordering and all existing creator/resume workspace-reservation semantics;
- add deterministic regression coverage for the exact finish/resume interleaving;
- rerun the complete exact-subject regression/package checks;
- rerun the applicable live M10 lifecycle/interruption/isolation acceptance surface on the corrected immutable subject;
- freeze the corrected immutable source as a new REQUIRED M10 independent-review subject.

No additional blocking finding was identified in this review.

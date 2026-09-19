# M10 independent implementation review — 2026-09-19

Verdict: **RED**

Review subject: `elmakus/codex_workflow@7f6f51fe9faf318fa90ce9414e6024c673ad9226`
Review owner: M10 milestone in `implementation/TASK_BOARD.yaml`.

## Evidence

- Fresh exact-subject checkout: runtime 90/90 GREEN, Muse adapter 26/26 GREEN, profile 7/7 GREEN, `git diff --check` GREEN.
- M10-T06 live evidence is coherent with this exact subject and the production boundary remained unchanged.

## Blocking finding

`runtime/muse_sessions.py` has a process race between persisting a new worker as `reserved` and acquiring its per-session flock.

A deterministic exact-subject reproduction forced this ordering: creator A persisted A1 as `reserved` and paused before the flock; process B resumed the same binding, acquired the session flock and advanced the record to `active`; creator A then lost the flock race and its `created` cleanup deleted the mapping because it checked only matching `session_id`, not that the record was still creator-owned `reserved`; while B still held the original lease, process C created A1 again in the same caller scope/workspace with a different session and acquired it concurrently.

This violates the M10/R7-R15 invariant that one logical Muse worker/session has at most one active invocation and undermines fail-closed session/workspace ownership. Existing overlap coverage begins only after the first turn is already active and does not cover this startup interleaving.

## Corrective classification

This is bounded L1/L2 corrective implementation inside accepted M10 authority; no Definition or Master Plan change is required.

The correction must make the `reserved` transition process-safe, prevent a losing creator from deleting a mapping advanced by another process, add deterministic regression coverage for this exact interleaving, preserve the existing fail-closed/resume/binding/isolation behavior, rerun full exact-subject regressions, and rerun the applicable live M10 lifecycle/interrupted-turn/isolation acceptance surface on the new immutable source subject before another REQUIRED milestone review is frozen.

No other blocking finding was identified.
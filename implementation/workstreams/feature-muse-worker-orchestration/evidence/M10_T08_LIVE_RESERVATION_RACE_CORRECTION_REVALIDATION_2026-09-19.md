# M10-T08 — live reservation-race correction revalidation

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T08.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Exact source subject used for every T08 phase: `74a7588e5bab0a5b7a89549c4309486dc9e7ba4f`
- Remote candidate readback matched the exact subject before and after live validation.
- `codex_workflow:main` remained `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- Production installed runtime remained `1.1.17-private.11` and its `runtime/muse_worker.py` remained byte-identical to the pre-M10 baseline.
- Muse runtime: Muse Code 1.3.0.

## Exact-subject fail-closed regressions before live run

Inside the same corrected candidate worktree:
- pre-lock `reserved` reservation interleaving regression — **GREEN**;
- stale-`active` persistence-failure regression — **GREEN**;
- `cleanup_unconfirmed` quarantine regression — **GREEN**.

All three focused tests passed in one exact-subject run.

## Meta-backed A1/B1 lifecycle

A disposable isolated `muse-max` runtime used actual Muse Code:
1. A1 produced controlled S1 state.
2. B1 independently reviewed S1 and returned RED without changing workspace bytes.
3. The same A1 logical worker/session resumed and repaired to S2.
4. The same B1 logical worker/session resumed and performed a full S2 recheck, returning GREEN without changing workspace bytes.

Harness assertions proved:
- A1 session identity was stable across implementation/repair;
- B1 session identity was stable across RED/full recheck;
- Executor and Tester sessions were distinct;
- all four physical turns had unique invocation identities;
- Tester remained read-only.

Only these relational assertions are recorded; raw session/invocation identifiers and Muse trajectories are not committed.

## Interrupted-turn acceptance

A controlled actual-adapter cancellation made the Muse turn create a child process and partial workspace state before cancellation.

The corrected exact subject returned the interrupted session as `needs_probe`, positively confirmed the child process tree was absent, retained inspectable partial state, probed the exact retained session, and safely resumed that same logical session to completion. No silent replacement identity was used.

## Two-lane isolation

Two caller-authorized non-overlapping workspaces ran managed Executor turns concurrently, followed by independent read-only Tester turns.

Harness assertions proved:
- expected lane-local state in each workspace;
- Tester did not mutate either workspace;
- four distinct lane role sessions;
- four unique lane invocation identities;
- no cross-lane workspace/session collision.

## Privacy, residue and production boundary

- all candidate Muse runtime directories checked as 0700;
- all candidate Muse runtime files checked as 0600;
- zero residual candidate processes after validation;
- isolated candidate runtime/workspaces/helper/task capsules were removed after readback;
- no release, tag, merge to `codex_workflow:main`, version bump or production runtime mutation occurred.

## Review handoff

M10 can now freeze `elmakus/codex_workflow@74a7588e5bab0a5b7a89549c4309486dc9e7ba4f` as the next exact **REQUIRED independent milestone-review** subject.

This chat implemented that corrected subject and therefore must not issue the next independent verdict.

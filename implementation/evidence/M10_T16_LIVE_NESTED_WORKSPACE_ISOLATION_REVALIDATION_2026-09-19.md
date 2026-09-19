# M10-T16 — live nested-workspace isolation correction revalidation

Date: 2026-09-19
Card: `implementation/cards/M10-T16.md`
Result: **GREEN**

## Exact immutable subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Exact corrected subject used throughout: `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`
- Final remote branch readback remained exactly that SHA.
- `codex_workflow:main` remained `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- No source mutation occurred during T16.

## Exact-subject deterministic gate

Dependency evidence `implementation/evidence/M10_T15_NESTED_WORKSPACE_ISOLATION_CORRECTION_2026-09-19.md` proved on the exact subject:
- direct parent-active -> nested-child acquisition rejection;
- direct child-active -> parent acquisition rejection;
- non-overlapping independent lease control;
- Muse adapter **33/33 GREEN**;
- workflow runtime **90/90 GREEN**;
- muse-max profile **7/7 GREEN**;
- compile, diff-check, release package build/verify and ZIP integrity GREEN;
- tested Tower blobs matched final remote blobs exactly.

## Stateful A1/B1 lifecycle

The exact corrected subject ran through Muse Code 1.3.0 / Meta-backed turns in an isolated candidate runtime:

- A1 created controlled S1.
- B1 independently and read-only verified S1 and returned **RED**.
- A1 resumed the same retained logical session and repaired S1 to S2 using a distinct invocation.
- B1 resumed the same independent Tester session and performed a full S2 recheck, returning **GREEN** using a distinct invocation.
- A1 and B1 remained distinct sessions.
- Tester workspace hashes were unchanged across both verification turns.

## Interrupted-turn cleanup and exact-session reconciliation

A retained C1 session completed an initial turn, then a later resumed turn was interrupted through the candidate adapter timeout/process-control path.

Observed:
- normalized terminal failure kind `timeout`;
- durable state after confirmed cleanup: `needs_probe`;
- pre-existing anchor preserved and bounded partial workspace marker present;
- the spawned child process was absent after adapter return;
- the next invocation probed and resumed the exact retained C1 session;
- recovery completed successfully and returned the session to `ready`;
- no silent replacement identity occurred.

## Two-lane isolation

Two caller-authorized non-overlapping workspaces ran concurrently through the corrected candidate:
- both lane Executors completed GREEN;
- both lane Testers completed GREEN concurrently;
- Tester workspace hashes were unchanged;
- all Executor/Tester sessions were distinct across roles and lanes;
- no cross-lane artifact/session collision was observed.

## Private runtime and final readback

The live harness completed with exit code 0 and final result **GREEN** for exact subject `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`.

Final relational checks proved:
- seven retained logical workers ended in `ready`;
- eleven unique private run directories existed;
- private runtime directories were mode **0700** and files **0600**;
- no candidate Muse/T16 validation process remained after completion.

## Production boundary

Before and after live validation:
- installed production version: `1.1.17-private.11`;
- installed production `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`;
- production remained unchanged.

No release, tag, merge to `codex_workflow:main`, or production promotion was performed.

## Review freeze

The applicable M10 acceptance surface is GREEN on exact subject `elmakus/codex_workflow@cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`.

This exact subject is ready to be frozen as the next **REQUIRED M10 independent implementation review** attempt.

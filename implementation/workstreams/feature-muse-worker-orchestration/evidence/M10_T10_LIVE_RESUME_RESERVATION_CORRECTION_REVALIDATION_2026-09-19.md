# M10-T10 — live resume-reservation correction revalidation

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T10.md`
Result: **GREEN**

## Exact immutable subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Exact subject used for every T10 phase: `3a5d98b3c21fc37a527c3aa8eb0ed771e6428acb`
- Final remote readback: candidate branch is identical to that SHA.
- Exact-subject `scripts/test_muse_adapter.py`: **28/28 GREEN**, including resume-side reservation, creator reservation, stale-active persistence-failure, cleanup-unconfirmed, binding, same-session lease and successful resume coverage.
- No source mutation occurred during T10.

## Stateful A1/B1 live lifecycle

The isolated candidate runtime used Muse Code 1.3.0 with `muse-max` and real `muse exec` turns.

- A1 S1 turn completed and wrote the controlled failing state.
- B1 performed a read-only full check and returned **RED**.
- Workspace byte hash before/after B1 was identical.
- The same logical A1 resumed the same retained Muse session with a distinct invocation and repaired S1 to S2.
- The same logical B1 resumed its same retained Muse session with a distinct invocation and performed a full S2 recheck, returning **GREEN**.
- A1 and B1 session identities were distinct.
- Workspace byte hash before/after the final B1 recheck was identical.

No raw session or invocation identifiers are committed here.

## Interrupted-turn cleanup and exact-session recovery

A separate C1 retained Muse session was created successfully before fault injection.

For the interrupted turn, a test-only wrapper created one controlled child process and bounded partial workspace marker in the same process group immediately before `exec` replacing the wrapper with the real `/usr/local/bin/muse`. The candidate adapter then ran the resumed real Muse turn with a 5-second adapter timeout.

Observed:
- terminal result: failed with `failure_kind=timeout`;
- runtime state after confirmed cleanup: `needs_probe`;
- bounded partial marker existed and the pre-existing anchor remained intact;
- the recorded controlled child PID was absent from `/proc` after adapter return, positively confirming descendant cleanup;
- the next invocation used the ordinary real Muse binary, passed retained-session probing, resumed the **same C1 session**, completed successfully, and returned to `ready`;
- the resumed turn preserved the anchor and partial marker and wrote the expected recovery marker.

Thus the actual adapter timeout/process-tree path, retained-session probe, and safe exact-session reconciliation were exercised against the corrected candidate.

## Two-lane live isolation

Two distinct caller-authorized workspaces were executed concurrently through separate adapter processes against the same candidate registry.

- Lane 1 Executor and Lane 2 Executor both completed GREEN in their own workspaces.
- Lane 1 Tester and Lane 2 Tester then ran concurrently and both returned **GREEN**.
- Tester workspace hashes were identical before/after both read-only reviews.
- The four lane roles used four distinct retained session identities.
- All lane invocation identities were unique.
- No cross-lane artifact/session collision was observed.

## Private artifacts and process cleanup

Relational readback across all T10 results proved:
- A1: one retained session across two unique invocations;
- B1: one retained session across RED then GREEN full checks;
- C1: one retained session across initial completion, timeout/`needs_probe`, and successful resume;
- lane Executor/Tester sessions: all distinct.

The isolated candidate runtime contained **11 unique run artifact directories**. Runtime session/run directories were mode **0700** and their files were **0600**. No candidate `muse_worker.py` process remained after validation.

## Production boundary readback

Before live validation:
- installed production version: `1.1.17-private.11`;
- installed production `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`.

After all live validation:
- installed production version: `1.1.17-private.11`;
- installed production adapter SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`.

No release, tag, merge to `codex_workflow:main`, or production runtime promotion occurred.

## Review freeze

All applicable M10 acceptance surfaces exercised by T10 are GREEN on exact subject `elmakus/codex_workflow@3a5d98b3c21fc37a527c3aa8eb0ed771e6428acb`.

This exact subject is ready to be frozen as the next **REQUIRED M10 independent implementation review** attempt.

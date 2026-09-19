# M10-T12 — live correction revalidation

Date: 2026-09-19
Card: `implementation/cards/M10-T12.md`
Result: **GREEN**

## Exact immutable subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Exact subject used for every T12 phase: `eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e`
- Final remote branch readback remained exactly that SHA after validation.
- Exact-subject `scripts/test_muse_adapter.py`: **29/29 GREEN**, including the new retained-session lock-conflict reconciliation regression and all prior stateful Muse regressions.
- No source mutation occurred during T12.

## Stateful A1/B1 lifecycle

The isolated candidate runtime used the exact corrected source with `muse-max` and real Muse turns.

- A1 completed S1 and produced the controlled failing state.
- B1 performed a read-only full check and returned **RED**.
- The workspace state hash was unchanged by B1.
- The same logical A1 resumed its retained session with a distinct invocation and repaired S1 to S2.
- The same logical B1 resumed its retained session with a distinct invocation and performed the full S2 recheck, returning **GREEN**.
- A1 and B1 used distinct retained sessions.
- The workspace state hash was unchanged by the final B1 check.

No raw session or invocation identifiers are committed here.

## Interrupted-turn cleanup and recovery

A separate retained C1 session completed an initial turn before the interruption test.

The resumed turn was interrupted through the candidate adapter's normal timeout handling.

Observed:

- terminal result: failed with `failure_kind=timeout`;
- durable runtime state after confirmed cleanup: `needs_probe`;
- the bounded partial workspace marker existed and the pre-existing anchor remained intact;
- the temporary child used by the test was absent after adapter return;
- the next invocation used the ordinary Muse runtime, passed retained-session probing, resumed the **same C1 session**, completed successfully, and returned to `ready`;
- the recovery turn preserved the anchor and bounded partial marker and wrote the expected recovery marker.

## Two-lane isolation

Two distinct caller-authorized workspaces were executed concurrently through separate adapter invocations against the same candidate registry.

- Lane 1 Executor and Lane 2 Executor both completed GREEN in their own workspaces.
- Lane 1 Tester and Lane 2 Tester then ran concurrently and both returned **GREEN**.
- Tester workspace hashes were unchanged before/after both read-only reviews.
- The four lane roles used four distinct retained sessions.
- No cross-lane artifact/session collision was observed.

## Private artifacts and final readback

Relational readback across the T12 result set proved:

- A1: one retained session across two unique invocations;
- B1: one retained session across RED then GREEN full checks;
- C1: one retained session across initial completion, timeout/`needs_probe`, and successful resume;
- lane Executor/Tester sessions: all distinct;
- all seven retained logical workers ended in `ready`;
- the isolated runtime contained **11 unique run artifact directories**;
- runtime session/run directories were mode **0700** and their files were **0600**;
- no candidate `muse_worker.py` process remained after validation.

## Production boundary readback

Before T12 validation:

- installed production version: `1.1.17-private.11`;
- installed production `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`.

After all T12 validation:

- installed production version: `1.1.17-private.11`;
- installed production adapter SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`.

No release, tag, merge to `codex_workflow:main`, or production runtime promotion occurred.

## Review freeze

All applicable M10 acceptance surfaces exercised by T12 are GREEN on exact subject `elmakus/codex_workflow@eb490ccfbe04bac0bd3ab7646eceffdea7cdde4e`.

This exact subject is ready to be frozen as the next **REQUIRED M10 independent implementation review** attempt.

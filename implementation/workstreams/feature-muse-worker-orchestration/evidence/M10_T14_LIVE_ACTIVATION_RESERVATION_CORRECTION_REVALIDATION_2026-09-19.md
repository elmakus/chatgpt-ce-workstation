# M10-T14 — live activation-reservation correction revalidation

Date: 2026-09-19  
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T14.md`
Result: **GREEN**

## Exact immutable subject

- Repository: `elmakus/codex_workflow`
- Candidate branch: `impl/m10-stateful-muse-lifecycle`
- Exact subject used for the live validation: `ad62ffa515026714a42a610c0310b1f6e92f47bd`
- Final remote branch readback remained exactly that SHA.
- Dependency evidence `implementation/workstreams/feature-muse-worker-orchestration/evidence/M10_T13_ACTIVATION_STATE_CORRECTION_2026-09-19.md` already proved the exact subject GREEN for the activation-transition and prior reservation/quarantine regressions: Muse adapter 31/31, workflow runtime 90/90, muse-max profile 7/7, compile/diff/package build/verify/ZIP integrity GREEN.
- No source mutation occurred during T14.

## Stateful A1/B1 lifecycle

The isolated candidate runtime used the exact corrected source with Muse Code 1.3.0 / Meta-backed Muse turns.

- A1 created controlled S1.
- B1 performed an independent read-only full check and returned **RED**.
- Workspace hash was unchanged by the B1 RED verification.
- The same logical A1 resumed its retained session with a distinct invocation and repaired S1 to S2.
- The same logical B1 resumed its retained session with a distinct invocation and performed a full S2 recheck, returning **GREEN**.
- A1 and B1 used distinct retained sessions.
- Workspace hash was unchanged by the final B1 verification.

No raw session or invocation identifiers are committed here.

## Interrupted-turn cleanup and recovery

A separate retained C1 session completed an initial turn before the interruption test.

The resumed turn was interrupted through the candidate adapter's normal timeout/process-control path.

Observed:

- terminal result failed with `failure_kind=timeout`;
- durable runtime state after confirmed cleanup was `needs_probe`;
- the bounded partial workspace marker existed and the pre-existing anchor remained intact;
- the temporary child process used by the test was absent after adapter return;
- the next invocation used the ordinary Muse runtime, probed the exact retained session, resumed the **same C1 session**, completed successfully, and returned to `ready`;
- no silent replacement identity occurred.

## Two-lane isolation

Two caller-authorized non-overlapping workspaces were executed concurrently through the candidate adapter.

- Lane 1 Executor and Lane 2 Executor both completed GREEN in their own workspaces.
- Lane 1 Tester and Lane 2 Tester then ran concurrently and both returned **GREEN**.
- Tester workspace hashes were unchanged before/after both read-only reviews.
- Executor/Tester logical sessions were distinct across both lanes.
- No cross-lane artifact/session collision was observed.

## Private runtime and final readback

Final relational assertions from the live run proved:

- seven retained logical workers ended in `ready`;
- eleven unique run artifact directories were created;
- runtime session/run directories were mode **0700** and their files were **0600**;
- no candidate Muse or T14 validation processes remained after completion.

The live validation process exited **0** and emitted final result **GREEN** for exact subject `ad62ffa515026714a42a610c0310b1f6e92f47bd`.

## Production boundary readback

Final readback after live validation:

- installed production version: `1.1.17-private.11`;
- installed production `runtime/muse_worker.py` SHA-256: `c199a458530d0e53ad64e40fe43c2f4072af5b9efe62af4144a03a4cb0570950`;
- residual candidate/T14/Muse processes: **0**.

These values match the pre-validation production baseline recorded by the live gate. No release, tag, merge to `codex_workflow:main`, or production runtime promotion occurred.

## Review freeze

The applicable M10 acceptance surface is GREEN on exact subject `elmakus/codex_workflow@ad62ffa515026714a42a610c0310b1f6e92f47bd`.

This exact subject is ready to be frozen as the next **REQUIRED M10 independent implementation review** attempt.

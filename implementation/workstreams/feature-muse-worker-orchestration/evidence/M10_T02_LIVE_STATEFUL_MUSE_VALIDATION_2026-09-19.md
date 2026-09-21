# M10-T02 live stateful Muse validation — 2026-09-19

## Scope

Validated the exact immutable M10 source subject `elmakus/codex_workflow@b225fad5ffa0497566ff9179ef684968a3d9be16` through the candidate adapter in an isolated runtime on the live workstation. Production installation was excluded and remained untouched.

## Exact-subject readback

- The dedicated `impl/m10-stateful-muse-lifecycle` branch remains exactly one commit ahead of baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`, with no later source mutation.
- The live candidate copy of `runtime/muse_worker.py` and `runtime/muse_sessions.py` matched the clean exact-source checkout by SHA-256 before final evidence capture.
- The exact-source deterministic regression evidence from M10-T01 remains GREEN: runtime 90/90, Muse adapter 24/24, muse-max profile 7/7, compile/package validation/build/archive verification and diff check all GREEN.

## Live provider/runtime

- All ten live adapter invocations produced Muse event records configured with provider `meta` and model `muse-spark-1.3-contributor`.
- Validation used Muse Code 1.3.0 through the candidate adapter; no direct CLI bypass was used to satisfy lifecycle or interruption acceptance.

## A1/B1 stateful lifecycle

The required four-turn lifecycle completed on one workspace:

1. Executor A1 created S1 with the deliberately failing value `BROKEN`.
2. Independent Tester B1 performed a full read-only check and returned RED.
3. A1 resumed its existing logical session, repaired the subject to `FIXED`, and used a new per-turn invocation/artifact identity.
4. B1 resumed its own existing logical session, performed a fresh full verification of S2, and returned GREEN.

Relational identity checks were GREEN: A1 reused A1's prior session, B1 reused B1's prior session, A1 and B1 remained distinct sessions, and all four physical turns had unique invocation identities. No Executor trajectory was supplied to Tester and Tester did not repair production state.

## Interrupted-turn reconciliation

A real candidate-adapter cancellation path was exercised after the worker created a partial-workspace marker and spawned a child process.

- Adapter cancellation normalized the turn as cancelled and moved the logical session to `needs_probe`.
- The recorded descendant process was absent after cancellation.
- The partial workspace effect remained readable and bounded.
- A subsequent resume performed the exact-session probe, safely reused the same retained logical session, created the recovery marker and returned the session to `ready`.
- Because the live interrupted session proved resumable, the exact-subject deterministic unavailable-session regression from M10-T01 supplies the separate negative-path proof: unavailable resume fails closed and recovery requires an explicitly new logical worker/session identity. No silent replacement occurs.

## Two-lane isolation

Two independent caller scopes were exercised concurrently.

- Each lane used its own workspace and lane-local Executor/Tester namespace.
- Both Executors completed their lane-local writes.
- Both independent Testers returned GREEN.
- The four Executor/Tester sessions across the two lanes were all distinct, and all physical invocation identities were distinct.
- Lane A and lane B retained their own expected contents without cross-lane reuse or collision.

## Private artifacts and production boundary

- Candidate `muse_runs` and `muse_sessions` roots were mode 0700.
- Live run/session subdirectories were mode 0700 and private files were mode 0600.
- The installed production workflow version read back as `1.1.17-private.11` after validation.
- No release, tag, merge to `codex_workflow:main`, production installation or production-profile mutation was performed.

## Evidence hygiene

This record intentionally contains no raw Muse trajectory, transcript, session UUID, invocation UUID, credentials, auth material or private artifact payload. It records only exact source provenance and bounded relational/results evidence required by M10 acceptance.

## Result

M10-T02 GREEN. The exact source subject above is ready to be frozen as the M10 REQUIRED independent milestone implementation-review subject. This implementing chat must not issue that independent verdict.

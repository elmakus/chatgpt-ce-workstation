# M10-T04 — corrected stateful Muse live revalidation

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T04.md`
Result: **GREEN**

## Exact subject

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Corrected immutable subject: `b67785486ba5e2e996b8c6feaf1a163816a49d47`
- Remote branch readback remained exactly at that subject; `codex_workflow:main` remained at the published baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- A fresh clean checkout of the exact corrected subject matched the complete candidate source package used for live validation with zero file differences.
- The live candidate and isolated installed runtime carried the exact corrected runtime blobs recorded by M10-T03 for `muse_sessions.py` and `muse_worker.py`.
- Muse Code read back as 1.3.0.

## Stateful A1/B1 lifecycle

The corrected candidate completed the required Meta-backed lifecycle against one isolated workspace:

1. Executor A1 created S1 with the controlled failing value.
2. Independent Tester B1 performed a full read-only verification and returned RED.
3. A1 resumed its retained logical session and reconciled the workspace to S2.
4. B1 resumed its own retained logical session and performed a full S2 verification, returning GREEN.

Relational checks were GREEN:
- A1 repair/reconciliation reused A1's original session.
- B1 S2 verification reused B1's original session.
- A1 and B1 remained distinct logical sessions.
- All lifecycle physical turns had distinct invocation identities.
- Tester did not perform repair.

An external container restart interrupted the first A1 repair process before a durable normalized result was returned. Recovery used the corrected adapter's exact-session resume path; the retained A1 session safely reconciled the already-visible workspace state and completed normally.

## Interrupted-turn reconciliation

A real candidate-adapter cancellation path was exercised after the worker created a bounded partial-workspace marker and spawned a child process.

- Cancellation normalized as `cancelled` and moved the logical session to `needs_probe`.
- The captured child process was positively absent before recovery.
- Partial workspace effects remained inspectable and bounded.
- The next turn used `--resume`, reused the exact retained logical session, completed the bounded recovery edit, and returned the session to `ready`.
- The child process remained absent after recovery.

The corrected exact subject's M10-T03 deterministic regression remains the complementary fail-closed negative-path proof: forced unconfirmed cleanup records `cleanup_unconfirmed`, rejects same-worker resume, and also rejects explicit replacement in the quarantined workspace. Together with the live successful-cleanup branch above, this proves no silent identity substitution.

## Two-lane isolation

Two caller-authorized lanes were exercised concurrently through the actual corrected adapter.

- Lane A and lane B Executors both completed successfully in separate workspaces.
- Independent lane-local Testers ran concurrently and both returned GREEN.
- All four Executor/Tester logical sessions were distinct.
- All four physical invocation identities were distinct.
- Lane A contained only its expected lane marker; lane B contained only its expected lane marker.
- No cross-lane marker, session reuse, or workspace collision was observed.

## Private runtime and cleanup

Before cleanup:
- isolated `muse_runs` and `muse_sessions` roots were mode 0700;
- all checked private runtime directories were mode 0700;
- all checked private runtime files were mode 0600;
- no candidate Muse worker/process remained active.

After evidence capture, the disposable M10-T04 runtime/workspaces/session storage under `/tmp/m10-t04-b677` and host-side T04 helper files were removed. The workstation container remained healthy.

## Production boundary

Final readback after cleanup:
- production workflow version remained `1.1.17-private.11`;
- production `muse_worker.py` remained byte-identical to the published `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8` baseline blob;
- `codex_workflow:main` remained on that baseline;
- no release, tag, main publication, production install, or production-profile mutation was performed.

## Evidence hygiene

This evidence intentionally records only relational identities and bounded outcomes. It contains no raw Muse trajectory, transcript, session UUID, invocation UUID, credentials, auth material, or private artifact payload.

## Result

M10-T04 is GREEN on the corrected immutable subject `elmakus/codex_workflow@b67785486ba5e2e996b8c6feaf1a163816a49d47`.

The corrected subject now satisfies the M10 live acceptance surface and must be frozen as the new **REQUIRED milestone-level independent implementation-review** subject. The previous RED review remains historical evidence for the superseded subject; this implementing session must not issue the replacement independent verdict.

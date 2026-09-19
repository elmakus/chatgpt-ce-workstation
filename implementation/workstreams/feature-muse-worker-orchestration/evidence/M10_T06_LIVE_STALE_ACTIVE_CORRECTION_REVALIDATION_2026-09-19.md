# M10-T06 — live stale-active correction revalidation

Date: 2026-09-19
Card: `implementation/workstreams/feature-muse-worker-orchestration/cards/M10-T06.md`
Result: **GREEN**

## Exact subject and recovery

- Repository: `elmakus/codex_workflow`
- Branch: `impl/m10-stateful-muse-lifecycle`
- Exact immutable subject: `7f6f51fe9faf318fa90ce9414e6024c673ad9226`
- Recovery re-read confirmed the remote candidate branch still pointed exactly to that subject before validation.
- `codex_workflow:main` remained `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- A fresh detached worktree of the exact subject was used for the live candidate runtime.
- Muse Code read back as 1.3.0.

The first prior T06 execution had not persisted durable evidence before interruption, so recovery reran the complete required live acceptance surface instead of treating chat/runtime history as authoritative proof.

## Stale-active fail-closed regression

The exact-subject persistence-failure regression from M10-T05 was rerun on the live workstation and passed.

It proves that after an interrupted turn cannot persist `cleanup_unconfirmed` and leaves durable state at stale `active`, a later process cannot:
- resume the same logical worker/session as normal; or
- allocate a replacement logical worker in the same canonical workspace.

Both remain fail-closed pending explicit reconciliation.

## Stateful A1/B1 lifecycle

The corrected candidate completed the required Meta-backed lifecycle:

1. Executor A1 created controlled S1.
2. Independent Tester B1 performed full read-only verification and returned RED.
3. A1 resumed its retained logical session and repaired to S2.
4. B1 resumed its own retained logical session and performed full S2 verification, returning GREEN.

Relational checks passed:
- A1 repair reused A1's original session.
- B1 full S2 recheck reused B1's original session.
- Executor and Tester sessions remained distinct.
- All four physical turns used unique invocation identities.
- Tester did not modify the workspace in either verification turn.

## Interrupted-turn reconciliation

A real candidate-adapter cancellation path was exercised after the worker produced bounded partial workspace state and a controlled descendant process.

Checks passed:
- cancellation normalized as `cancelled`;
- the logical session entered `needs_probe`;
- the controlled descendant process was positively absent after cancellation;
- partial workspace state remained inspectable;
- the next turn used the exact retained session and safe resume path;
- the resumed turn completed and returned the session to `ready`;
- no silent logical/session identity substitution occurred.

## Two-lane isolation

Two caller-authorized non-overlapping lanes were exercised concurrently through the exact candidate adapter.

Checks passed:
- both lane Executors completed in separate workspaces;
- independent lane-local Testers completed GREEN and remained read-only;
- all four Executor/Tester logical sessions were distinct;
- all four physical invocation identities were distinct;
- lane markers remained lane-local with no cross-lane workspace collision.

## Private runtime and production boundary

- Private candidate runtime directories/files passed mode checks: directories 0700 and files 0600.
- No candidate process remained active after validation.
- Production workflow version remained `1.1.17-private.11`.
- Production `muse_worker.py` remained byte-identical to the published baseline `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`.
- `codex_workflow:main` remained on that baseline.
- No release, tag, main publication, production install or production-profile mutation was performed.

## Evidence hygiene

This record contains only exact source identity and bounded relational outcomes. It contains no raw Muse trajectory/event stream, session UUID, invocation UUID, credentials, authentication material or private artifact payload.

## Result

M10-T06 is GREEN on exact immutable subject `elmakus/codex_workflow@7f6f51fe9faf318fa90ce9414e6024c673ad9226`.

This exact subject now satisfies the corrected M10 live acceptance surface and must become the next **REQUIRED milestone-level independent implementation-review** subject.

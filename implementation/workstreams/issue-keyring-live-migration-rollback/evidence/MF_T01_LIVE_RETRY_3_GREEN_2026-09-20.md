# MF-T01 live retry 3 — GREEN

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Reviewed source subject: `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80`
Independent review evidence: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_REVIEW_7_2026-09-20.md`

## Authorization and execution boundary

The operator explicitly authorized the MF-T01 Tower live retry after REQUIRED independent review attempt 7 was GREEN.

Execution used a detached Tower worktree pinned to the exact reviewed source subject. Host-local `.env` configuration was copied locally into that worktree for the updater; no secret value was read into chat or repository evidence.

## Pre-promotion freshness abort

The first authorized `scripts/update.sh` attempt resolved a frozen upstream set but Ubuntu published a new `noble-updates InRelease` before a later Docker build stage.

The exact APT identity assertion failed closed before promotion:
- updater status: `pre_promotion_failed`;
- reason: `candidate_build_failed`;
- no candidate image was promoted;
- no rollback baseline was consumed;
- production remained running + healthy on exact previous image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`.

This was a normal R15 freshness failure, not a production/keyring mutation.

## Successful retry

The same exact reviewed source was retried with a newly resolved frozen upstream set.

Successful update identity:
- resolution SHA-256: `ff89c28ab47d599919bb98ac70493f5a00b711ce8d36a0e32655b8e454d9bb93`;
- exact candidate image: `sha256:dcf23c733b28b39827b2b6161cea880d3b45151b698ae5a6427bdd397ea1dd5a`;
- retained prior known-working image: `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`;
- rollback tag: `chatgpt-ce-workstation:rollback-ea264b43f32482b8`.

Updater result: `success`.

## Required live verification

After first promotion:
- container running: yes;
- Docker health: healthy;
- exact home/project bind checks: GREEN;
- unprivileged/no-SYS_ADMIN boundary: GREEN;
- canonical desktop D-Bus / Secret Service isolation: GREEN;
- passwordless v2 marker / runtime surface checks: GREEN;
- strict runtime verifier: `WORKSTATION_RUNTIME_GREEN`.

The updater then performed the required second candidate recreate to prove passwordless persistence without relying on the one-time migration credential.

After second recreate:
- container running: yes;
- Docker health: healthy;
- strict candidate runtime verifier again reached `WORKSTATION_RUNTIME_GREEN`.

Only after the second GREEN verification did the updater finalize migration cleanup.

## Independent post-write readback

Direct post-update readback confirmed:
- running image exactly equals candidate `sha256:dcf23c733b28b39827b2b6161cea880d3b45151b698ae5a6427bdd397ea1dd5a`;
- updater evidence status is `success`;
- `login` and `default` aliases both resolve to `/org/freedesktop/secrets/collection/login`;
- the canonical login collection passes the exact format-correct Locked check as unlocked;
- canonical login collection contains 4 items, matching the production-derived legacy login item count established by R1/R2;
- 5 persistent collections remain visible; a non-canonical collection still contains 1 item, so the repair did not collapse/delete the additional failed-v1 collection state;
- v2 marker is present;
- `keyrings.pre-passwordless-v2` is cleaned only after persistence verification;
- host legacy migration secret file is present but empty;
- staged `/run/workstation/keyring-migration-password` is absent.

No keyring secret values were read or recorded. The post-write metadata check used only collection paths, collection labels, item counts and lock state.

## Result

GREEN.

MF-T01 Acceptance 10 is satisfied: the explicitly authorized Tower retry of the independently reviewed exact source reached `WORKSTATION_RUNTIME_GREEN` before migration credential/backup cleanup, and the post-write readback confirms the canonical four-item login keyring is preserved, passwordless, unlocked and persistent across recreate.

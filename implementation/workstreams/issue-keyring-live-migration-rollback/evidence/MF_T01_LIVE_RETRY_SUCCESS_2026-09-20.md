# MF-T01 live retry success evidence — exact reviewed subject

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Reviewed / deployed source subject: `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80`
Independent review: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_REVIEW_7_2026-09-20.md`

## Authorization boundary

The operator explicitly authorized the MF-T01 Tower live retry after REQUIRED independent review GREEN.

The production run used a detached checkout at exactly `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80`. Later workstream bookkeeping commits were not part of the built candidate.

## Fail-closed pre-promotion attempt

The first authorized update attempt stopped before production mutation during candidate build.

Frozen Ubuntu metadata for `noble-updates InRelease` changed while the long candidate build was running:
- frozen expected SHA-256: `6de4b6e0e3e51781773ed0cef83df90f3eb349a36ac5994359771df0786bfa3c`;
- later observed SHA-256: `d57666e1192c95379da0d889f31fcc96b02f048e64d140f77babcb17fe8f014c`.

The build failed closed with `candidate_build_failed` / `pre_promotion_failed`. Readback proved the existing production container still ran the prior rollback image and remained healthy. No production keyring/container promotion occurred in this failed pre-promotion attempt.

The same exact reviewed source was retried with a freshly resolved/frozen upstream set. During retry a second concurrent updater invocation was detected before either could promote; the newer duplicate and its orphaned build subprocesses were terminated, leaving exactly one updater invocation. Production remained on the prior healthy image throughout that reconciliation.

## Successful exact candidate

Successful frozen upstream resolution:
`ff89c28ab47d599919bb98ac70493f5a00b711ce8d36a0e32655b8e454d9bb93`

Exact candidate image:
`sha256:dcf23c733b28b39827b2b6161cea880d3b45151b698ae5a6427bdd397ea1dd5a`

Retained prior known-working image:
`sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`

Rollback tag retained:
`chatgpt-ce-workstation:rollback-ea264b43f32482b8`

The candidate build completed all 24 Dockerfile stages. The refreshed Ubuntu metadata identity was rechecked successfully at the later APT layers before installation continued.

## Live promotion and strict verification

The exact candidate was recreated into production and reached Docker `healthy`.

The first strict `scripts/verify-runtime.sh` run completed:
`WORKSTATION_RUNTIME_GREEN`

This included:
- exact persistent-home/project bind validation;
- unprivileged / no-`SYS_ADMIN` isolation;
- fail-closed non-desktop D-Bus default;
- one canonical desktop Secret Service session;
- login/default alias convergence;
- the format-correct unlocked canonical collection check;
- v2 migration marker presence;
- absence of the staged migration credential;
- codex ownership of active keyring state;
- no root-owned secondary GNOME keyring daemon;
- normal workstation runtime/desktop health.

The updater then performed the required second candidate recreate to prove passwordless persistence across a fresh session. The second strict verifier also completed:
`WORKSTATION_RUNTIME_GREEN`

Only after that second GREEN did the updater finalize legacy migration cleanup.

The update process exited 0 and recorded `status: success`.

## Independent post-run readback

After updater completion, read-only Tower checks proved:
- running image: `sha256:dcf23c733b28b39827b2b6161cea880d3b45151b698ae5a6427bdd397ea1dd5a`;
- container running: `true`;
- container health: `healthy`;
- updater evidence status: `success`;
- `keyring-passwordless-v2` marker: present;
- v2 rollback backup: absent after successful finalization;
- legacy migration credential file size: 0 bytes after successful finalization;
- login/default aliases: converged;
- canonical login collection item count: 4;
- active keyring files with wrong codex ownership: none.

The canonical item count was read through the Secret Service `Items` property only. No secret item values or credential bytes were read or recorded.

## Result

MF-T01 Acceptance 10 is satisfied. The exact independently reviewed source reached production, remained passwordless/unlocked across the required recreate, preserved the four legacy canonical login items, and completed both strict runtime verification passes before cleanup.

The Card may be terminally finalized without changing the reviewed implementation subject.

# MF-T01 final-integration refresh — pending independent review

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Qualified path: `micro_fix`
Integration target: `main`

## Refresh identities

- Pre-refresh workstream branch head: `54b41ba01c7616657c4817a88811dd8117e71d90`.
- Current integration target re-read immediately before reconciliation: `main@1fb9c16aa331b29bc6319bdcf1b53340f161f935`.
- Refreshed immutable integrated subject: `c4d76bdebd22a5a1fc6c6dfd419f00804c03cb8a`.
- Card implementation/review subject remains `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80`.

## Why refresh was required

The integration target materially advanced after the MF-T01 Card review. A trial merge reported textual conflicts in:

- `rootfs/etc/cont-init.d/10-workstation-init`;
- `scripts/verify-runtime.sh`.

The target also changed adjacent runtime/source-validation files through already-integrated work, including passwordless noVNC behavior.

## Reconciliation

The conflicts were resolved as a technical union inside existing authority:

- current `main` passwordless-noVNC behavior remains intact;
- MF-T01 v2 keyring backup/ownership preparation remains intact;
- per-session keyring readiness remains intact;
- canonical login/default convergence and format-correct unlocked verification remain intact;
- strict candidate verification remains intact;
- rollback-baseline verifier and updater rollback semantics remain intact.

No accepted D8/D14/D26 intent or smart-updater requirement was changed. No production/deployment write occurred during this Git integration refresh.

## Affected verification

On the reconciled tree, before freezing the refreshed subject:

- `bash scripts/test-keyring-migration-prep.sh` -> `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- `python3 scripts/test-keyring-passwordless.py` -> 6/6 GREEN;
- `bash scripts/test-keyring-session-readiness.sh` -> `KEYRING_SESSION_READINESS_TESTS_GREEN`;
- `bash scripts/test-keyring-runtime-lock-check.sh` -> `KEYRING_RUNTIME_LOCK_CHECK_TESTS_GREEN`;
- `bash scripts/test-update-orchestration.sh` -> `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `bash scripts/validate-source.sh` -> `SOURCE_VALIDATION_GREEN`, including the current target's passwordless-noVNC boundary and the MF-T01 passwordless-keyring boundary;
- focused `git diff --check` on the conflict-resolved runtime files -> GREEN.

The integration target was fetched again immediately before the merge commit; `origin/main` still equaled `1fb9c16aa331b29bc6319bdcf1b53340f161f935`, and the remote workstream branch still equaled the pre-refresh head. The merge was then committed and pushed as exact subject `c4d76bdebd22a5a1fc6c6dfd419f00804c03cb8a`.

## Review decision

The manifest final-integration review requirement is `REQUIRED`.

Although the MF-T01 Card review is GREEN, this refresh required conflict resolution in runtime verification/init files and produced a new integrated immutable subject. The one-Card exact-subject reuse condition is therefore not asserted. The manifest-owned final-integration review must be performed independently against `c4d76bd...`.

The current chat participated in the reconciliation and must not review this refreshed subject.

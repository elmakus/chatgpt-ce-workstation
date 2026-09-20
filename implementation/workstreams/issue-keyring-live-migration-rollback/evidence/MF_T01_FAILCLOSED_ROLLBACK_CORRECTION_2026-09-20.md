# MF-T01 fail-closed rollback correction evidence

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Corrects review evidence: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_REVIEW_4_2026-09-20.md`

## Correction

The RED finding identified that `restore_keyring_migration_backup` was invoked from `if ! ...` while relying on global `set -e` for several safety-critical operations. Bash suppresses the expected errexit behavior for commands in a function used as a conditional, and the prior implementation also explicitly ignored `docker compose stop` failure.

The correction now:

- rejects a rollback-backup path that exists but is not a directory;
- when a v2 rollback backup exists, requires `docker compose stop workstation` to succeed before any persistent keyring mutation;
- checks marker cleanup explicitly;
- checks candidate-keyring removal explicitly;
- checks publication of the pre-migration backup into the active keyring path explicitly;
- returns non-zero on any failed safety-critical step so `rollback_after_failure` records `keyring_restore_failed:<original reason>` and does not recreate the retained image as though keyring recovery succeeded.

Behavioral correction commit: `a6f12e40c95b404d169bc508953522b96ad2d6ee`.
Regression commit: `b678c0451907fb682d5068dad5cb81c50ee37ee5`.

## Regression coverage

`scripts/test-update-orchestration.sh` now additionally proves:

1. an updater rollback whose keyring restore returns failure records `rollback_failed:keyring_restore_failed:...`, captures recovery state, and never attempts the retained-image recreate;
2. if stopping the candidate workstation fails, active candidate keyring state, the rollback backup, and the v2 marker remain untouched;
3. if active-keyring removal fails after a successful stop, the function returns failure, preserves the active candidate state and keeps the rollback backup unconsumed.

Existing success, persistence-proof and rollback verification scenarios remain covered.

## Exact source validation

A disposable detached worktree on Tower was created at exact commit `b678c0451907fb682d5068dad5cb81c50ee37ee5`. It did not use or mutate the live production keyring or production container.

GREEN checks on that exact commit:

- `bash scripts/test-update-orchestration.sh` -> `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `bash scripts/test-keyring-migration-prep.sh` -> `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- `python3 scripts/test-keyring-passwordless.py` -> 6/6 GREEN;
- `bash scripts/validate-source.sh` -> `SOURCE_VALIDATION_GREEN`;
- `git diff --check` -> GREEN;
- `bash -n` on changed/keyring runtime scripts -> GREEN;
- `docker buildx build --check --file Dockerfile .` -> check complete, no warnings.

The detached worktree was cleaned up after validation.

## Exact hosted CI

The corrected immutable subject was frozen as `8191cbbebe120b842f77b767979ee4f2202ed636`, an empty checkpoint above the evidence/correction tree.

GitHub Actions run `35509724696` / CI #282 completed `success` with `head_sha=8191cbbebe120b842f77b767979ee4f2202ed636`.

All jobs were GREEN:

- `source-validation`: source validation, noVNC desktop workarea semantics and ShellCheck all succeeded;
- `dockerfile-check`: Dockerfile static/buildx check succeeded;
- `secret-scan`: repository-history secret scan succeeded.

PR #13 could not emit a normal pull-request run because its current target `main` has advanced and the PR is presently conflict-marked. A temporary CI-only PR #16 used the immutable original workstream base `e796e2fef00e348e2329be1a4856da335dff6842`, making the PR merge tree equivalent to the exact head tree for this subject. After run #282 completed GREEN, PR #16 was closed and its temporary base branch was deleted. The workstream branch and exact review subject were not changed by that cleanup.

## External state

No production updater run, candidate promotion, live keyring mutation, credential cleanup, or container recreation was performed.

Production retry remains behind the existing explicit operator-authorization gate and a fresh REQUIRED independent review of the corrected exact subject.

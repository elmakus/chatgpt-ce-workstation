# MF-T01 corrective implementation evidence — atomic v2 backup publication

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Origin review: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_REVIEW_3_2026-09-20.md`
Corrected implementation subject: `ef5a4b1ee0d72c2ea6a95363e90fce7fa813a417`
Behavioral correction commit: `7871412b945aaffbebbccd28d4d5ec2f92c52545`
Regression commit: `abbca2a425fded9ef17e96a42a3d02a9aca882d4`
PR: #13

## Correction

The RED finding is corrected inside the existing MF-T01 authority.

`prepare_keyring_passwordless_v2` no longer copies the first v2 rollback snapshot directly into the canonical `keyrings.pre-passwordless-v2` path.

When no canonical backup has yet been published, root init now:

1. removes only the unpublished sibling `keyrings.pre-passwordless-v2.staging` path;
2. copies the complete active keyring directory into that staging path;
3. fails closed and removes ordinary failed-copy staging state if the copy fails;
4. renames the complete staging directory to the canonical backup path only after the copy succeeds;
5. performs active-keyring ownership repair only after the canonical backup has been published.

A hard interruption during the copy may leave only the staging path. On the next attempt that unpublished staging state is discarded and copied again from the still-unmutated active keyring. An already-published canonical backup remains authoritative and is never overwritten.

This preserves the existing updater rollback contract: `restore_keyring_migration_backup` only consumes the canonical backup path, so an incomplete staging directory cannot be restored as if it were a complete pre-attempt snapshot.

## Regression coverage

`scripts/test-keyring-migration-prep.sh` now covers both failure forms:

- an initial copy that writes one file and then returns failure: no canonical backup is published, staging is cleaned, active state is unchanged, and `chown` is not called;
- a simulated hard interruption that leaves a partial staging directory: retry removes that stale staging state, creates a complete canonical backup containing both modeled pre-existing keyring files, and only then reaches `chown`.

Existing checks still prove that a published canonical backup is never overwritten and that completed v2 skips preparation.

## Verification

The behavioral source through regression commit `abbca2a425fded9ef17e96a42a3d02a9aca882d4` was tested in a disposable detached worktree on Tower without production container/keyring mutation:

- `bash scripts/test-keyring-migration-prep.sh` -> `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- `bash scripts/test-update-orchestration.sh` -> `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `python3 scripts/test-keyring-passwordless.py` -> 6/6 GREEN;
- `bash scripts/validate-source.sh` -> `SOURCE_VALIDATION_GREEN`.

The frozen subject `ef5a4b1ee0d72c2ea6a95363e90fce7fa813a417` is one empty checkpoint commit above `abbca2a...`; GitHub compare reports zero changed files between them. On that exact checkpoint, detached-worktree verification also passed:

- `git diff --check 41949c8fdf374c9c3ac21117db38fc90254c7853..HEAD`;
- `bash -n` for both changed shell files;
- `docker buildx build --check --file Dockerfile .` -> GREEN.

A normal PR push was made specifically to request hosted CI, but GitHub had not created a workflow/check run for the exact checkpoint when this evidence was frozen. This record therefore does not claim a hosted GitHub Actions result that does not exist; exact-source validation and the repository/static checks above are the available GREEN verification.

## Scope / production boundary

Only the review-identified v2 backup publication/retry defect and its deterministic regression were changed. D26, the production-copy evidence model, alias behavior, persistence-proof candidate recreate, strict candidate verification and rollback-baseline verifier scope are unchanged.

No production updater/promotion, live keyring mutation, live credential cleanup or live backup restore was performed.

The production retry remains gated by a later REQUIRED independent review GREEN plus explicit operator authorization.

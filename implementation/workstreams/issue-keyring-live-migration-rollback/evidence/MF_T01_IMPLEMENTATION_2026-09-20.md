# MF-T01 implementation evidence — live keyring migration and rollback verifier compatibility

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Implementation subject: `elmakus/chatgpt-ce-workstation@d89b2eb3ae4469349ed39d6bdb6d27e8236efc36`
PR: #13
Base / integration target at freeze: `main@e796e2fef00e348e2329be1a4856da335dff6842`

## Result

Issue #12 is implemented on the exact immutable subject above without incorporating issue #11.

The source now:

- introduces passwordless-keyring migration generation v2;
- creates a whole-directory pre-attempt keyring backup before root-owned legacy keyring ownership is repaired;
- makes the active keyring directory readable by the canonical codex desktop only after that backup exists;
- treats stale v1 completion state as insufficient for v2;
- selects the canonical login collection during credentialed migration using the strongest preserved-item signal instead of blindly trusting a stale replacement alias;
- performs explicit legacy-password -> empty-password migration even when the selected collection is transiently reported unlocked;
- converges both `login` and `default` aliases onto the migrated collection;
- preserves additional collections/files created by the failed v1 attempt rather than deleting them;
- requires v2 marker, alias convergence, unlocked canonical collection and codex ownership in strict candidate runtime verification;
- clears v1/v2 completion markers after a failed candidate even when no migration backup exists;
- restores the v2 pre-attempt backup when present;
- verifies rollback with a version-stable rollback-only verifier bound to the exact retained prior image, while candidate verification remains the strict current `scripts/verify-runtime.sh`.

## Root-cause evidence carried from R1

The completed Research record `implementation/workstreams/issue-keyring-live-migration-rollback/research/R1.md` contains the production read-only evidence that:

- the legacy four-item `login.keyring` was root-owned/mode 0600 and unreadable to the UID-99 desktop;
- the failed candidate created a separate replacement `Login` collection and changed alias state instead of migrating the legacy keyring;
- the candidate-created collection contained the non-secret item label `Chromium Safe Storage`;
- current v1 helper/rollback semantics explain marker-without-backup and rollback-verifier-skew failures.

No secret values were read or persisted as evidence.

## Verification

GitHub CI run `35505509221` (CI #260) completed GREEN on the exact subject:

- source-validation — success;
- secret-scan — success;
- dockerfile-check — success.

The source-validation job explicitly executed the new and existing regression surfaces, including:

- `scripts/test-keyring-passwordless.py` — 6 tests GREEN;
- `scripts/test-keyring-migration-prep.sh` — `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- `scripts/test-update-orchestration.sh` — `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- complete source validation — `SOURCE_VALIDATION_GREEN`.

The updater regression fixture proves that candidate runtime failure invokes the rollback-only verifier for the exact previous image and does not invoke the strict candidate verifier against that older image. Additional fixture coverage verifies stale-marker cleanup without a backup and restoration of the v2 backup.

The migration fixtures cover:

- preserving a full pre-attempt directory before ownership repair;
- not overwriting an existing pre-attempt backup;
- v2 idempotent preparation;
- choosing the preserved item-rich login collection over stale replacement aliases during credentialed migration;
- explicit password change despite transient unlocked state;
- empty-password proof for an unmarked existing passwordless collection;
- alias convergence;
- fresh passwordless collection creation.

## Scope / isolation check

Comparison from the freeze base to the exact implementation subject contains only the issue #12 namespaced workstream artifacts and the bounded keyring/updater/runtime-verification files declared by MF-T01.

Issue #11 image/cache-retention behavior is not part of this subject.

## Production boundary

No production update/recreate, keyring master-password change, live backup restore, legacy-credential cleanup or other live Tower mutation was performed by this implementation stage.

A production retry remains an explicit post-review authorization gate. The exact source subject must first receive REQUIRED independent GREEN review. After that, a separately authorized Tower retry must reach `WORKSTATION_RUNTIME_GREEN` before migration credential/backup cleanup is accepted.

## Review handoff

MF-T01 remains non-terminal until REQUIRED independent review of exact subject `d89b2eb3ae4469349ed39d6bdb6d27e8236efc36` is GREEN.

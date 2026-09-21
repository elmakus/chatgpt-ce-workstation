# MF-T01 corrective implementation evidence — persistence-proof recreate

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Corrected implementation subject: `elmakus/chatgpt-ce-workstation@35d1b9dd91287c2953c56824f91716a77c59afd7`
PR: #13
Origin review evidence: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_REVIEW_2026-09-20.md`

## Correction

The RED finding is corrected inside the existing MF-T01 authority.

After the first successful candidate health + strict runtime verification, `scripts/update.sh` now recreates the exact same candidate a second time before retiring any migration recovery material. It then:

1. reads back the recreated container and requires the exact candidate image identity;
2. waits for health again;
3. runs the strict current `scripts/verify-runtime.sh` again;
4. only after that second GREEN verification calls `finalize_keyring_passwordless_migration`.

Because the v2 completion marker already exists after the first successful migration, container init does not stage the retained legacy migration credential for the second recreate. The second desktop/Secret Service session therefore has to open the canonical persistent login collection under the passwordless state already written to disk.

If the second recreate, image readback, health check or strict runtime verification fails, the updater enters the existing deterministic rollback path while the v2 pre-attempt keyring backup and legacy credential are still retained. The rollback path restores the pre-attempt keyring directory before recreating the retained previous image.

## Regression coverage

`scripts/test-update-orchestration.sh` now proves:

- successful update performs two candidate recreates and two candidate runtime verifications;
- cleanup occurs only after the second recreate and second verification;
- failure of the persistence recreate rolls back and does not finalize keyring migration;
- wrong image after the persistence recreate rolls back and does not finalize;
- persistence-recreate health failure rolls back and does not finalize;
- persistence-recreate strict-runtime failure rolls back and does not finalize.

Existing migration-preparation, keyring-helper, stale-marker, backup-restore and rollback-version-skew coverage remains in place.

## Verification

GitHub CI run `35506152500` (CI #267) completed GREEN on exact subject `35d1b9dd91287c2953c56824f91716a77c59afd7`:

- source-validation — success, including the updater orchestration regression suite;
- ShellCheck — success;
- secret-scan — success;
- dockerfile-check — success.

## Scope / production boundary

The correction changes only updater orchestration and its deterministic regression fixture. It does not change D26, weaken candidate verification, modify the rollback-baseline verifier, or absorb issue #11.

No production update/recreate, live keyring migration, credential cleanup, backup restore or other Tower mutation was performed.

A Tower retry remains gated by REQUIRED independent review GREEN of this corrected exact subject plus explicit operator authorization.

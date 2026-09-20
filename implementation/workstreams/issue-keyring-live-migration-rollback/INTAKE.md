# Issue Intake — live passwordless-keyring migration and rollback verifier skew

Workstream ID: `issue-keyring-live-migration-rollback`
Kind: `issue`
Branch: `fix/keyring-live-migration-rollback`
Integration target: `main`
Base: `e796e2fef00e348e2329be1a4856da335dff6842`
Tracker: `elmakus/chatgpt-ce-workstation#12`

## Operator intent

Correct the production regression exposed by the first real D26 passwordless-keyring deployment attempt. Preserve the accepted passwordless GNOME Secret Service design and deterministic rollback behavior; do not change the accepted security/product decision.

Issue #11 is explicitly independent and handled by another agent. This workstream must not absorb image/cache-retention policy.

## Baseline production evidence

A real `bash scripts/update.sh` on the Tower host built and promoted exact candidate:

- frozen resolution: `6c10d740d4873176f0cd96039490adc0c7c3ce2fe32e9e82941e45ad5808db50`;
- candidate image: `sha256:1e552c66f416b729c48c41fa7bea6fd43ef2125c9734d7682626ffe60762d758`;
- prior known-working image: `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`.

Source validation, host preflight, exact candidate build and Docker health were GREEN.

Candidate runtime verification failed with:

`FAIL: default Secret Service collection is locked`

The updater then recreated the exact prior image. Docker readback showed that exact image running and healthy, but current-source runtime verification failed with:

`FAIL: unexpected non-desktop D-Bus default: missing`

so updater evidence recorded `rollback_failed` even though exact-image restoration itself succeeded.

Post-failure host readback established:

- production remains on exact prior image `ea264b43...`, running and healthy;
- candidate-era `keyring-passwordless-v1` marker had survived rollback;
- `keyrings.pre-passwordless-v1` backup was absent;
- legacy keyring migration secret remained non-empty;
- operator removed only the stale marker and did not rerun the updater.

## Initial technical diagnosis

Two defects are established:

1. **Migration correctness gap.** Current helper treats an existing collection reporting `Locked=false` as already suitable for passwordless operation. That can write the durable completion marker without proving the persistent master password is actually empty and without creating a pre-mutation backup. The real deployment later observed the collection locked.
2. **Rollback verifier version skew.** `rollback_after_failure()` runs the current checkout's `scripts/verify-runtime.sh` against the older retained image. The older image predates the new fail-closed `DBUS_SESSION_BUS_ADDRESS` invariant, so exact known-working rollback can be misclassified RED by a verifier contract it never implemented.

A third bounded rollback-state defect is also established: `restore_keyring_migration_backup()` removes the migration marker only when a backup directory exists, allowing a stale success marker to survive a failed candidate attempt.

## Dependency discovery

The affected D26 implementation and updater behavior are already integrated on `main`. No unmerged parent-only state is required to reproduce, define or correct issue #12.

Issue #11 may touch `scripts/update.sh` later, but it is an independent retention-policy workstream rather than a parent dependency. Any target movement/overlap will be handled by normal integration refresh.

Classification: **independent**.

Parent workstream: none.
Parent branch: none.
Parent dependency: none.

## Path classification

The intended behavior remains fully governed by accepted D8/D14/D26 and the existing smart-updater rollback contract. No product/security/architecture decision currently needs to change.

However the exact root cause of the production keyring state is not yet sufficiently proven for micro-fix execution: issue #12 explicitly requires reproduction against a disposable copy of the real persistent keyring, and the synthetic temporary-HOME fixture did not reproduce the observed live failure.

Path: `research`

Research obligation: `implementation/workstreams/issue-keyring-live-migration-rollback/research/R1.md`

Next route: `research:issue-keyring-live-migration-rollback-R1`

## Research exit criteria

Research must establish, without mutating the live keyring:

- why the real keyring reached marker-present / backup-absent and later locked state;
- whether encrypted-but-currently-unlocked state reproduces the failure;
- the smallest safe migration predicate/operation that proves restart-persistent passwordless state while preserving items;
- the exact rollback verification compatibility model for a retained older image;
- the bounded fix/test shape sufficient to return to Execution Prep without changing D26.

Until this Research completes, do not rerun the production updater.

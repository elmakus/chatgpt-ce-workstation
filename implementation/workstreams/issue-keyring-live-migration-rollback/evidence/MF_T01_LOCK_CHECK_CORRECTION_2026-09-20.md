# MF-T01 correction evidence — format-correct runtime keyring lock verification

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
R3 record: `implementation/workstreams/issue-keyring-live-migration-rollback/research/R3.md`
Corrected behavior commit: `ef677de83dd143da7d3d934f8c66426467313cd3`
Frozen review subject: `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80`
PR: #13

## Root cause

Research R3 established that the two live retry failures reported as:

`FAIL: canonical login Secret Service collection is locked`

were verifier false negatives rather than proven runtime relocks.

The reviewed verifier queried `org.freedesktop.Secret.Collection.Locked` with `gdbus call`, whose actual Tower output for an unlocked collection is `(<false>,)`, then piped that output to `grep -F 'boolean false'`. The predicate therefore failed even when the collection was unlocked.

A read-only equivalent query through `dbus-send --print-reply` returns a typed `boolean false` line. Disposable candidate lifecycle probes also kept the migrated canonical collection unlocked, supporting the parser mismatch diagnosis.

## Correction

The correction keeps the semantic requirement unchanged: the canonical login collection must be unlocked.

- `scripts/check-keyring-unlocked.sh` queries the Locked property with `dbus-send --session --print-reply` and requires `boolean false`.
- `scripts/verify-runtime.sh` delegates only this lock predicate to the helper.
- `scripts/test-keyring-runtime-lock-check.sh` proves unlocked=false passes, locked=true fails, malformed output fails, and an invalid session-bus address fails.
- `scripts/validate-source.sh` runs the new regression and validates the helper wiring.

No D26, R11/R12, migration, readiness or rollback semantics are weakened.

## Verification

Tower detached exact corrected behavior tree validation at `ef677de83dd143da7d3d934f8c66426467313cd3` completed GREEN:

- `KEYRING_RUNTIME_LOCK_CHECK_TESTS_GREEN`;
- `KEYRING_SESSION_READINESS_TESTS_GREEN`;
- `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- passwordless helper 6/6 GREEN;
- `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `SOURCE_VALIDATION_GREEN`;
- `git diff --check` and affected shell syntax checks GREEN.

Commit `5b9afc564e6c2795f4fdd50df2453f3e47dc8b80` is a no-tree-change CI trigger on top of that corrected behavior. GitHub Actions run `35512664624` / CI #284 completed GREEN on this exact frozen subject:

- `source-validation` successful, including noVNC workarea and ShellCheck;
- `dockerfile-check` successful;
- `secret-scan` successful.

## External-state boundary

No production candidate promotion or keyring mutation was performed after this verifier correction.

The previous live authorization was consumed by the failed-and-safely-rolled-back retry of subject `789fc358...`. Any subsequent Tower retry requires REQUIRED independent review GREEN for this new exact subject and a new explicit operator authorization.

# MF-T01 correction evidence — GNOME reserved login alias

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Corrected implementation subject: `41949c8fdf374c9c3ac21117db38fc90254c7853`
PR: #13
Origin: RED review attempt 2 + Research R2 production-derived-copy evidence.

## Defect found by R2

The real production-derived disposable copy reproduced the pre-fix failure and then exposed that GNOME Secret Service rejects `SetAlias("login", collection)` with `org.freedesktop.DBus.Error.NotSupported: Only the 'default' alias is supported`.

An isolated empty-home probe established the platform semantics:
- creating a collection labelled `Login` does not materialize the natural `login` alias;
- creating it as `login` does materialize the natural reserved `login` alias;
- `default` remains the writable alias.

## Correction

The helper now:
- creates fresh canonical collection with GNOME-native lowercase `login` identity;
- never calls unsupported `SetAlias("login", ...)`;
- writes only `default` to the selected/migrated canonical login collection;
- verifies both natural `login` and `default` resolve to that same collection.

Regression fakes reject writes to the reserved login alias and model natural login alias creation.

## Verification

Exact source `41949c8fdf374c9c3ac21117db38fc90254c7853`:
- helper regression tests: 6/6 GREEN;
- migration preparation tests: GREEN;
- updater orchestration tests: GREEN;
- full `scripts/validate-source.sh`: `SOURCE_VALIDATION_GREEN`.

User-run Tower production-derived disposable-copy retest:
- pre-fix failure reproduced: yes;
- source maximum login items: 4;
- source persistent collections: 3;
- corrected first migration status: 0;
- corrected fresh isolated session without legacy password status: 0;
- corrected canonical items: 4;
- aliases converged: yes;
- canonical locked: no;
- persistent collections preserved: 3;
- pre-attempt backup exact: yes;
- fixed migration proved: yes;
- live keyring unchanged: yes;
- live legacy credential unchanged: yes;
- production container unchanged: yes;
- `R2_RESULT=GREEN`.

No production updater/promotion was run. The explicit live retry gate remains unchanged.

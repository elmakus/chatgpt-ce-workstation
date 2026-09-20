# MF-T01 authorized Tower live retry 2 — candidate failed, rollback GREEN

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Reviewed source subject: `789fc358139a73a8bed8aaa38813157853df8b75`
Authorization: explicit operator authorization in the active ChatGPT session before this retry.

## Pre-retry source/runtime

Tower repository HEAD was exactly the reviewed subject and had no tracked diff. The local generated Python bytecode directories were removed before execution.

The live workstation was still on the retained known-working image and the v1/v2 migration markers and v2 rollback backup were absent. The retained legacy migration credential remained present/non-empty; its value was not read or recorded.

## Exact retry result

The updater ran from exact reviewed source `789fc358139a73a8bed8aaa38813157853df8b75`.

Source validation completed `SOURCE_VALIDATION_GREEN`, including:
- passwordless helper 6/6;
- migration preparation regression GREEN;
- per-session keyring readiness regression GREEN;
- updater orchestration GREEN.

Frozen resolution:
`4c925a768263b1d0bf3988e2c99b84095d27156270d63448e722add3a541c540`

Built/promoted candidate:
- ref: `chatgpt-ce-workstation:candidate-4c925a768263b1d0`;
- image ID: `sha256:c4f4028d846048bc13157913a9e21ef0ccac0929f54bc3f41109e40aeb502c1c`.

The candidate reached Docker health `healthy`. Strict current runtime verification then failed at:

`FAIL: canonical login Secret Service collection is locked`

Updater reason:
`candidate_runtime_verification_failed`

This proves the per-session health-readiness marker did not close the live failure class. The candidate was not accepted as production success and no successful migration-finalization cleanup was accepted.

## Rollback

The updater restored the exact retained previous image:

`sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`

Rollback verification returned:

`ROLLBACK_RUNTIME_GREEN image=sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`

Updater evidence records:
- `status=update_failed_rolled_back`;
- `reason=candidate_runtime_verification_failed`.

Post-rollback readback proved the previous image running and healthy, v1/v2 markers absent, v2 rollback backup absent after restore consumption, and the retained legacy migration credential still present without exposing its value.

## New evidence

Post-rollback non-secret keyring metadata shows another empty GNOME keyring file was created during the retry/rollback window. The legacy four-item `login.keyring` remains present. This reinforces that live GNOME keyring session/file lifecycle behavior still differs from the current synthetic readiness model.

## Classification boundary

The reviewed source remains non-terminal because Acceptance 10 did not reach `WORKSTATION_RUNTIME_GREEN`.

The exact cause of the collection becoming locked after helper success is not yet proven. Do not apply another source correction from hypothesis alone and do not run another production retry under this authorization.

Implementation-owned Research R3 is required to establish the post-helper/session lifecycle mechanism and the smallest bounded correction inside existing D26/R11-R12 authority.

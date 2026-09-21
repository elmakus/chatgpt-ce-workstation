# M01-T06 D25 v5.0.14 consumption evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T06`

## Pre-update baseline

- Target host: Tower.
- Workstation checkout: `work/muse-native-upstream`, clean after removing only generated untracked `scripts/**/__pycache__/*.pyc` artifacts.
- Previous production image: `sha256:9a6be62fdab865a9dce65412933acd21d1a944e4c250172ddb8e0afdbceb5248`.
- Previous installed Codex Web GPT: `5.0.13`.
- Container was running and healthy.
- Native upstream: `http://192.168.2.104:2455/backend-api/codex`.
- Muse upstream: unset.

The target-host workstream checkout was fast-forwarded cleanly to the current durable branch state before the D25 update.

## Frozen resolution

A preflight resolver run and the promoted image's embedded `/opt/workstation/upstream-resolution.json` both bind Codex Web GPT to:

- version: `5.0.14`
- identity: `5.0.14@sha256:2c68166425e049241c61ae76eafd42afdde37343e1e887ef977fd43bf636cbf2`
- package SHA-256: `2c68166425e049241c61ae76eafd42afdde37343e1e887ef977fd43bf636cbf2`
- override: false in the preflight resolution

This exactly matches M01-T05 published-release evidence.

## D25 result

Repository-owned `bash scripts/update.sh` completed successfully through the normal D25 lifecycle.

Persisted `.workstation-update/last-update.json` readback:

- status: `success`
- frozen resolution SHA-256: `1aac9191d50cd4a24ebd11bbd5626f04fbf5d4c7eac5db6638bd31eb32bc8b0b`
- promoted candidate: `chatgpt-ce-workstation:candidate-1aac9191d50cd4a2`
- promoted image ID: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- previous image ID: `sha256:9a6be62fdab865a9dce65412933acd21d1a944e4c250172ddb8e0afdbceb5248`
- rollback ref retained: `chatgpt-ce-workstation:rollback-9a6be62fdab865a9`
- image-retention cleanup: success
- BuildKit cache-retention cleanup: success

## Independent runtime readback after update

The frozen build environment was re-rendered from the running image's own embedded resolution before invoking the repository runtime verifiers.

Results:

- `scripts/wait-healthy.sh`: `health: healthy`
- `scripts/verify-runtime.sh`: `WORKSTATION_RUNTIME_GREEN`
- running image ID: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- installed artifact: `/opt/codex-web-gpt/5.0.14/Codex Web GPT.AppImage`
- embedded Codex Web GPT version/checksum/identity match the exact published M01-T05 release
- native upstream remains `http://192.168.2.104:2455/backend-api/codex`
- Muse upstream remains unset
- Workstation container remains running and healthy
- repository working tree was returned to clean state after removing only verifier-generated untracked Python bytecode caches

The runtime verifier also confirmed the current Muse CLI surface (`Muse Code 1.3.0 / 1.3.0-R3401.1`) and all standard Workstation boundary checks.

## Boundary

No Muse upstream activation occurred in this Card.
No CLIProxyAPI ingress-key content was read or emitted.
No routing/provider/catalog source was changed.
The prior production image remains retained as the normal rollback baseline.

**GREEN**

# M01-T11 D25 v5.0.15 consumption evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T11`
State: **GREEN (recovered external success)**

## Recovery context

M01-T11 had been durably blocked on the Ubuntu APT mirror-propagation race. M01-T12 corrected that updater failure mode and received independent GREEN review. During post-review recovery, runtime readback showed that the D25 update had already completed successfully while the Task Board still carried the older blocked state. The successful deployment was therefore verified and reconciled rather than executed again.

## Exact release identity

GitHub latest stable release readback remained `v5.0.15`, target commit `3a6d1d28c28dbe1be885077ae53fe4bba62b9673`, with Linux AppImage SHA-256 `bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`.

The running image embedded `/opt/workstation/upstream-resolution.json` records:

- `codex_web_gpt.version`: `5.0.15`
- `codex_web_gpt.identity`: `5.0.15@sha256:bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`
- `codex_web_gpt.package_sha256`: `bdad25547ae79f29ee27a029bed5ec6c7762f98a92e7578762de40a113b9b49d`
- `codex_web_gpt.override`: `false`

## D25 persisted result

`.workstation-update/last-update.json` readback records:

- `status`: `success`
- frozen resolution SHA-256: `2dff55431e014fb6f21795951cf81d1e3286951aaeef91b2ce2b4f40f45ccd9a`
- promoted candidate: `chatgpt-ce-workstation:candidate-2dff55431e014fb6`
- promoted image ID: `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`
- previous image ID / rollback baseline: `sha256:ce07c414c1442bae243689a17fb32310eed457cb38c52e89394899b9a0289b42`
- image-retention cleanup: `success`
- BuildKit cache-retention cleanup: `success`

The running image's embedded resolution SHA-256 was independently recomputed as the same `2dff55431e014fb6f21795951cf81d1e3286951aaeef91b2ce2b4f40f45ccd9a`.

## Runtime readback

- Workstation container is running and healthy on exact promoted image `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`.
- Installed artifact path is `/opt/codex-web-gpt/5.0.15/Codex Web GPT.AppImage`.
- `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM=http://192.168.2.104:2455/backend-api/codex` remains unchanged.
- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` remains unset/empty.
- Re-rendering the frozen build environment from the running image's embedded resolution and invoking repository verifiers produced `health: healthy` and `WORKSTATION_RUNTIME_GREEN`.
- Repository working tree was clean after removing only verifier-generated `scripts/**/__pycache__` artifacts.

No Muse activation occurred while reconciling this Card, no Muse ingress-key content was read or emitted, and no second D25 deployment was launched after detecting the already-successful external result.

**GREEN**

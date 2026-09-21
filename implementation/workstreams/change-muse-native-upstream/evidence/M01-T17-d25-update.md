# M01-T17 D25 v5.0.16 consumption evidence

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T17`
State: **GREEN**

## Recovery from prior execution-surface blocker

The prior blocker was recovered by executing the already-authorized repository-owned D25 entrypoint on the target host:

`cd /mnt/cachedl/projects/chatgpt-ce-workstation && bash scripts/update.sh`

The production baseline before this recovery remained the previously recorded healthy image `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`, with native upstream unchanged and Muse upstream unset.

## Frozen release identity

The D25 candidate embedded `/opt/workstation/upstream-resolution.json` with:

- `codex_web_gpt.version`: `5.0.16`
- `codex_web_gpt.identity`: `5.0.16@sha256:7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`
- `codex_web_gpt.package_sha256`: `7a46e032a74d1bd848a8d946f36d4d427ec2a89e6aa047c518a0bd6bea922f30`
- `codex_web_gpt.override`: `false`

This exactly matches the independently reviewed and published M01-T15/M01-T16 release subject.

## D25 result

Repository-owned `scripts/update.sh` completed with exit code 0 through its normal resolve/freeze/build/validate/promote/persistence lifecycle.

Persisted `.workstation-update/last-update.json` readback records:

- `status`: `success`
- frozen resolution SHA-256: `d7e2a4529922a1e5f7d2a7f147de8224109fe0f044f965656308b1afd60f9487`
- promoted candidate: `chatgpt-ce-workstation:candidate-d7e2a4529922a1e5`
- promoted image ID: `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`
- previous image ID: `sha256:7470b64402282c56300ea6225c9d316c475b441878d38d68ff7862b5ff30248f`
- rollback ref retained: `chatgpt-ce-workstation:rollback-7470b64402282c56`
- image-retention cleanup: `success`
- BuildKit cache-retention cleanup: `success`

## Runtime readback

After promotion and the updater's persistence recreate:

- container status: `running`
- container health: `healthy`
- running image: `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`
- installed Codex Web GPT artifact exists at `/opt/codex-web-gpt/5.0.16/Codex Web GPT.AppImage`
- `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM=http://192.168.2.104:2455/backend-api/codex` remains unchanged
- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` remains unset/empty
- repository runtime verification returned `WORKSTATION_RUNTIME_GREEN` after initial promotion and again after the persistence recreate
- source validation and host preflight were GREEN before the candidate build
- target-host checkout was restored to a clean `work/muse-native-upstream` state after removing only verifier-generated `scripts/**/__pycache__` artifacts and fast-forwarding the previously recorded blocker commits

No Muse activation occurred in this Card. No Muse ingress-key content was read or emitted. No CLIProxyAPI/provider-routing/catalog source was changed.

**GREEN**

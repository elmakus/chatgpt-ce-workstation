# M01-T18 — Muse activation/native transport blocker

Date: 2026-09-21
Workstream: `change-muse-native-upstream`
Card: `M01-T18`
State: **BLOCKED; Muse rolled back to disabled**

## Pre-activation refresh

- Target-host checkout: `work/muse-native-upstream`, clean and fast-forwarded before execution.
- Running image before activation: `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`.
- Container health: `healthy`.
- Native upstream: `http://192.168.2.104:2455/backend-api/codex`.
- Muse upstream: unset.
- Persistent Muse key host path: `/mnt/user/appdata/chatgpt-ce-workstation/home/.config/codex-web-gpt/muse-proxy-api-key`; mode `0600`, uid/gid `99:100`, readable. Key content was never emitted.
- Direct authenticated CLIProxyAPI `GET /v1/models`: HTTP 200, five public Muse IDs (`muse-spark-1.1`, `muse-spark-1.2`, `muse-spark-1.2-contributor`, `muse-spark-1.3`, `muse-spark-1.3-contributor`) plus twelve non-Muse rows.
- `bash scripts/validate-source.sh`: `SOURCE_VALIDATION_GREEN`.

## Activation

The approved single non-secret endpoint was persisted in local untracked `.env`:

`CODEX_CHATGPT_WEB_MUSE_UPSTREAM=http://192.168.2.104:8317/v1`

The running image's embedded frozen resolution was rendered through `scripts/render-build-env.py`. Repository-owned Compose recreated Workstation with `--no-build` and exact candidate tag `chatgpt-ce-workstation:candidate-d7e2a4529922a1e5`.

Pre/post image identity matched exactly:

`sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`

After recreate:
- health returned `healthy`;
- `bash scripts/verify-runtime.sh` returned `WORKSTATION_RUNTIME_GREEN`;
- native upstream remained unchanged;
- Muse upstream readback matched the approved endpoint;
- `codex-chatgpt-web route status` through the installed 5.0.16 CLI returned `installed: true`, `active: true`, route URL `http://127.0.0.1:17841/v1`, `errors: []`.

## Blocking acceptance failure

A normal Codex 0.155.0-alpha.9.2 client/app-server turn for ordinary `gpt-5.6-sol` could not complete through the local bridge.

Both:
- standalone `codex exec`; and
- the native `codex debug app-server send-message-v2` JSON-RPC client, which initialized a normal thread with the persisted plugin/tool configuration

attempted Responses WebSocket transport to:

`ws://127.0.0.1:17841/v1/responses`

and received:

`HTTP error: 426 Upgrade Required`

The app-server path initialized the normal MCP/tool surface (`codex_apps`, `cua_repl`, `node_repl`) before the sampling transport failed. Therefore this is not a synthetic no-tools/provider-only probe and is not specific to the Muse model route.

Because M01-T18 requires the ordinary native/Codex-LB control to remain GREEN before Muse acceptance, the Card cannot complete. Continuing to Muse functional acceptance would not make the integrated acceptance valid.

## Rollback

Per the M01-T18 contract:
- `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` was reset to empty in local untracked `.env`;
- Workstation was recreated with `--no-build` from the same exact frozen candidate image;
- running image remained exactly `sha256:9ede8f1f522a710707acac32d01fd8c4d7671b91912791e299d1c635d964b893`;
- health returned `healthy`;
- native upstream remained unchanged;
- Muse runtime endpoint is empty;
- `WORKSTATION_RUNTIME_GREEN` passed after rollback;
- target-host Git checkout was restored clean after removing verifier-generated `scripts/**/__pycache__` artifacts.

The runtime/container baseline is therefore safely Muse-disabled again, but ordinary native functional acceptance is still blocked by the Responses transport incompatibility above.

No secret value was emitted or committed.

# Muse native upstream integration

Status: **approved**
Revision: **R1**
Date: 2026-09-21

## Goal

Expose Muse models already served by the operator-managed CLIProxyAPI to Codex through the existing released `codex-chatgpt-web` parallel-native-upstream capability, while preserving Codex-LB and ChatGPT Web behavior.

## Requirements

### R1 — Workstation supplies the optional Muse upstream

The Workstation Compose/runtime configuration MUST expose `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` to `codex-chatgpt-web` as an optional runtime setting. When unset, current Workstation behavior MUST remain unchanged.

### R2 — Muse routes only by the existing `muse-*` contract

The Workstation MUST rely on the released fork's existing routing contract:
- `muse-*` native model IDs route to CLIProxyAPI;
- other native Codex model IDs remain on the normal native/Codex-LB upstream;
- `chatgpt-web/*` remains on the browser-backed ChatGPT Web path.

The Workstation MUST NOT duplicate provider/model-routing logic already owned by `codex-chatgpt-web`.

### R3 — CLIProxyAPI authentication is separate and persistent

The CLIProxyAPI ingress API key MUST remain outside Git and outside the Workstation `.env`. The normal persistent credential path is the fork-owned file under the persistent Workstation home: `~/.config/codex-web-gpt/muse-proxy-api-key`.

The key MUST be readable by the `codex` user and MUST NOT be printed in validation evidence.

### R4 — Catalog degradation remains isolated

When the Muse upstream is configured and healthy, Codex model discovery MUST include public `muse-*` rows exposed by CLIProxyAPI.

A Muse catalog failure MUST NOT remove otherwise available Codex-LB native models or `chatgpt-web/*` models.

### R5 — Production wiring is reproducible

The Muse upstream configuration MUST be represented in repository-owned Compose/example configuration so container recreate/update preserves it. A live-only container mutation is insufficient.

### R6 — Existing routes remain unchanged

Acceptance MUST verify:
- a normal native model still routes through Codex-LB;
- `muse-*` discovery comes from CLIProxyAPI;
- no CLIProxyAPI non-`muse-*` provider rows are imported into the Codex catalog;
- browser-backed `chatgpt-web/*` remains available;
- no secret value is committed or emitted by the verification output.

## Non-goals

- changing Muse Code / `muse-max` worker orchestration;
- adding provider-routing logic to Workstation itself;
- routing every CLIProxyAPI model into Codex;
- moving Codex-LB behind CLIProxyAPI;
- storing CLIProxyAPI ingress credentials in Git or `.env`.

## Acceptance-level outcome

After deployment with the configured CLIProxyAPI endpoint and persistent ingress key, Codex model discovery shows the available `muse-*` models while ordinary native Codex and `chatgpt-web/*` routes remain functional and isolated.

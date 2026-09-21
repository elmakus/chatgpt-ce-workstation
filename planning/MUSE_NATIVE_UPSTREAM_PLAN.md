# Muse native upstream integration plan

Status: **draft**
Revision: **R1**
Date: 2026-09-21
Review requirement: **RECOMMENDED**

## Authority

- Requirements: `requirements/MUSE_NATIVE_UPSTREAM.md` R1
- Decision: `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`
- Workstream: `change-muse-native-upstream`

## Baseline

The released `elmakus/codex-chatgpt-web` already owns the parallel native routing behavior:
- ordinary native models use the primary native/Codex-LB upstream;
- `muse-*` uses the optional Muse/CLIProxyAPI upstream;
- model discovery imports only `muse-*` from the parallel catalog;
- the Muse catalog is optional and failure-isolated;
- Muse uses its own persistent ingress key.

Current Workstation repository and production runtime supply only `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`. CLIProxyAPI itself is healthy and already returns five `muse-*` rows when queried with its ingress key.

## Milestone M01 — Wire and deploy the optional Muse upstream

### Outcome

Workstation reproducibly supplies the optional CLIProxyAPI endpoint to `codex-chatgpt-web`, the ingress key exists only in the persistent fork-owned key file, and production Codex model discovery includes the available `muse-*` rows without changing the primary Codex-LB or `chatgpt-web/*` routes.

### Planned work

1. Repository wiring:
   - add `CODEX_CHATGPT_WEB_MUSE_UPSTREAM: ${CODEX_CHATGPT_WEB_MUSE_UPSTREAM:-}` to the Workstation service environment in `compose.yaml`;
   - document the optional setting in `.env.example` without placing a secret there;
   - keep routing/filtering logic out of Workstation.

2. Persistent credential provisioning:
   - read the existing CLIProxyAPI ingress API key from the operator-managed CLIProxyAPI configuration without printing it;
   - write it as the `codex` user's persistent `~/.config/codex-web-gpt/muse-proxy-api-key`;
   - use restrictive file permissions and verify only presence/ownership/mode, never the secret value.

3. Production activation:
   - set the Workstation runtime value to `http://192.168.2.104:8317/v1`;
   - recreate/restart the Workstation through its repository-owned Compose path so the process receives the new environment;
   - no image rebuild is required solely for this configuration change because production already carries the fork release with Muse routing support.

4. Verification:
   - repository checks prove Compose/example configuration is valid and contains no secret;
   - production readback proves `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` is unchanged and `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is present;
   - key-file readback proves the persistent Muse key exists with restrictive permissions without printing its contents;
   - Workstation-side model discovery includes the expected `muse-*` rows while retaining ordinary native and `chatgpt-web/*` rows;
   - CLIProxyAPI non-`muse-*` rows are not imported;
   - existing Workstation health remains GREEN.

### Rollback

Unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the Workstation. The optional key file may remain dormant or be removed explicitly. This restores the prior runtime route without changing Codex-LB, the image, or persistent ChatGPT/Codex login state.

### Authorization

The operator explicitly authorized this production configuration/deployment change in the current task. No additional live-write approval is required for the bounded M01 activation described above.

## Requirement coverage

- R1, R5 → repository Compose/example wiring and production readback.
- R2, R4 → use the existing fork contract; verify merged model catalog and failure isolation.
- R3 → persistent key file outside Git/`.env`, with secret-safe validation.
- R6 → production catalog/health/readback and preservation of primary routes.

## Planning audit

GREEN.

The implementation is intentionally narrow: Workstation wires an existing released capability rather than duplicating routing logic. No schema migration, image rebuild, data migration, or new service is required. Rollback is configuration-only. The only material external write is the already-authorized production Workstation recreate plus persistent key-file creation.

Independent plan review is RECOMMENDED because this is a new accepted Workstation behavior with production secret/configuration wiring, even though the implementation itself is bounded.

# Muse native upstream integration plan

Status: **draft**
Revision: **R3**
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

Current Workstation repository and production runtime supply only `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`. CLIProxyAPI itself is healthy and already returns five `muse-*` rows when queried with its ingress key. The parallel Muse capability is released in `codex-chatgpt-web` v5.0.10 and later, but the running production image version/capability is not assumed: it must be verified before activation.

## Milestone M01 — Wire and deploy the optional Muse upstream

### Outcome

Workstation reproducibly supplies the optional CLIProxyAPI endpoint to `codex-chatgpt-web`, the ingress key exists only in the persistent fork-owned key file, and production Codex model discovery plus request routing expose the available `muse-*` models without changing the primary Codex-LB or `chatgpt-web/*` routes.

### Planned work

0. Production capability preflight:
   - before any Muse activation, verify without exposing secrets that the running Workstation `codex-web-gpt` is a Muse-capable release/capability (v5.0.10+ or equivalent direct capability evidence);
   - if the running image lacks that capability, do not apply the Muse endpoint/key to the old binary; first use the repository-owned D25 Workstation update/build/validate/promote path, then repeat this preflight before continuing;
   - if the running image is already Muse-capable, no image rebuild is required solely for the configuration wiring below.

1. Repository wiring:
   - add `CODEX_CHATGPT_WEB_MUSE_UPSTREAM: ${CODEX_CHATGPT_WEB_MUSE_UPSTREAM:-}` to the Workstation service environment in `compose.yaml`;
   - document the optional setting in `.env.example` without placing a secret there;
   - keep routing/filtering logic out of Workstation.

2. Persistent credential provisioning:
   - read the existing CLIProxyAPI ingress API key from the operator-managed CLIProxyAPI configuration without printing it;
   - write it as the `codex` user's persistent `~/.config/codex-web-gpt/muse-proxy-api-key`;
   - use restrictive file permissions and verify only presence/ownership/mode, never the secret value.

3. Production activation:
   - only after the capability preflight is GREEN, set the Workstation runtime value to `http://192.168.2.104:8317/v1`;
   - recreate/restart the Workstation through its repository-owned Compose path so the process receives the new environment;
   - when the preflight required a Workstation update/rebuild, require that update's normal D25 candidate validation/rollback gate to complete before this activation.

4. Verification:
   - record the non-secret production capability/version preflight result and whether activation reused the existing image or followed the repository-owned update path;
   - repository checks prove Compose/example configuration is valid and contains no secret;
   - production readback proves `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM` is unchanged and `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` is present;
   - key-file readback proves the persistent Muse key exists with restrictive permissions without printing its contents;
   - Workstation-side model discovery includes the expected `muse-*` rows while retaining ordinary native and `chatgpt-web/*` rows;
   - CLIProxyAPI non-`muse-*` rows are not imported;
   - perform secret-safe functional route smoke checks showing: one ordinary native request still succeeds through the existing Codex-LB route, one available `muse-*` request succeeds through the Muse/CLIProxyAPI route, and one browser-backed `chatgpt-web/*` request remains functional;
   - prove Muse-catalog failure isolation against the exact Muse-capable fork release/capability without intentionally degrading production: prefer existing exact-release automated/source-level evidence; if that evidence is not sufficient, run a bounded isolated/staged instance with an unreachable Muse catalog endpoint and verify ordinary native plus `chatgpt-web/*` discovery remains available. Do not use a production outage as the default failure-injection method;
   - existing Workstation health remains GREEN.

### Rollback

Unset `CODEX_CHATGPT_WEB_MUSE_UPSTREAM` and recreate the Workstation. The optional key file may remain dormant or be removed explicitly. This restores the prior runtime route without changing Codex-LB, the image, or persistent ChatGPT/Codex login state.

### Authorization

The operator explicitly authorized this production configuration/deployment change in the current task. No additional live-write approval is required for the bounded M01 activation described above. Deliberate production failure injection is not part of this authorization and is not required by the plan because failure isolation is to be proven from exact-release evidence or an isolated/staged invocation.

## Requirement coverage

- R1, R5 → repository Compose/example wiring and production readback.
- R2 → use the existing fork contract plus healthy-state functional route smoke checks.
- R3 → persistent key file outside Git/`.env`, with secret-safe validation.
- R4 → merged-catalog verification plus exact-release or isolated/staged failure-isolation evidence.
- R6 → production discovery, secret-safe functional route checks, health/readback, non-`muse-*` filtering and preservation of primary/browser-backed routes.

## Planning audit

GREEN.

The implementation is intentionally narrow: Workstation wires an existing released capability rather than duplicating routing logic. No schema migration, data migration, or new service is required. A rebuild is not required when the running image proves Muse-capable; otherwise the existing repository-owned D25 update/build/validate/promote path is a prerequisite rather than activating unsupported configuration. Rollback of this integration remains configuration-only after a capability-ready image is in place. The material external writes are the already-authorized production Workstation recreate plus persistent key-file creation, and conditionally the existing D25 update path if the preflight proves the running image is stale. Failure-isolation proof does not require a deliberate production outage.

Independent plan review is RECOMMENDED because this is a new accepted Workstation behavior with production secret/configuration wiring, even though the implementation itself is bounded.

# Dual native upstreams — self-check evidence

Date: 2026-09-18

## Review subject

- Repository: `elmakus/codex-chatgpt-web`
- Branch: `feat/dual-native-upstreams`
- Exact implementation subject: `2c7eb2ac5266df0cf198a11abb14eba314f411e0`
- Base: `f8dc469a43cc562a4173bb77f7a7d9fe2b569187`
- Review policy: independent review recommended because the change alters routing architecture and authentication boundaries.

## Intended behavior

- `chatgpt-web/*` remains on the local ChatGPT Web adapter.
- `muse-*` routes to CLIProxyAPI using a dedicated CLIProxyAPI ingress key.
- Other native models continue to use the existing native/Codex-LB upstream.
- Model discovery merges the primary native catalog with only `muse-*` rows from CLIProxyAPI.
- Failure of the optional Muse catalog does not take down the primary Codex-LB or ChatGPT Web catalog.
- Incoming ChatGPT OAuth bearer must not be forwarded to either configured proxy.

## Self-check performed by implementing chat

Static readback was performed from the exact GitHub branch and against current relevant upstream sources.

Confirmed:

- Branch is six commits ahead of `main` and zero behind.
- `src/native-network.ts` selects the Muse proxy only for public model IDs beginning with `muse-`.
- Native/Codex-LB and Muse/CLIProxyAPI credentials are resolved independently.
- The outgoing Authorization header is replaced with the selected proxy's dedicated key.
- The original ChatGPT OAuth bearer is therefore not forwarded to either configured proxy.
- URL rewriting preserves the endpoint suffix and query string.
- CLIProxyAPI current `/v1/models` returns a Codex-client-shaped `{"models":[...]}` catalog when `client_version` is present, matching the merge implementation's assumption.
- Only `muse-*` rows are imported from the CLIProxyAPI catalog; unrelated providers are filtered.
- The launcher/supervisor inherits `process.env`, so the new `CODEX_CHATGPT_WEB_MUSE_*` variables are not dropped before the bridge starts.
- Current Codex standalone `alpha/search` request includes a `model` field, so model-based routing can select the Muse upstream for that endpoint.
- Existing source tests were extended for Muse-vs-Codex routing, separate keys, persistent Muse key lookup, catalog filtering, and secondary-catalog failure isolation.

## Finding requiring independent review

The Muse catalog is merged after `augmentNativeModelCatalog()`. Consequently imported Muse rows do not pass through the same post-processing currently applied to primary native rows.

In particular:

- under `subagentProtocol: compatibility-v1`, primary native rows are pinned to `multi_agent_version: v1` unless explicitly disabled, while imported Muse rows retain CLIProxyAPI's value;
- a configured top-level context override is applied to primary native rows before the merge but not to imported Muse rows.

CLIProxyAPI currently synthesizes non-template models from its Codex default template and may leave `multi_agent_version` null unless its own multi-agent-v2 optimization is enabled. The independent reviewer should decide whether Muse rows must be normalized with the bridge's compatibility-v1 contract before this branch is accepted.

The context-override difference should also be reviewed deliberately: applying the bridge's override to a third-party Muse row could be either required for picker consistency or incorrect if it advertises a context maximum Meta does not actually support.

## Verification gap

Runtime verification was not executed by the implementing chat.

- GitHub Actions CI does not run for this branch by itself; the repository CI triggers on pull requests or pushes to `main`.
- The current ChatGPT container could not clone the repository because outbound DNS/network access to `github.com` is unavailable, so `bun run verify` could not be run locally here.

The independent reviewer should run or obtain equivalent evidence for at least:

- `bun run typecheck`
- the affected Bun tests, preferably `bun run test`
- ideally full `bun run verify`
- a direct model-catalog proof against CLIProxyAPI with Meta OAuth configured
- one ordinary Muse Responses turn
- a long-context/compaction check, because CLIProxyAPI's Meta executor currently rejects the legacy `responses/compact` path

## Review boundary

This file is implementing-chat evidence only. It is not an independent GREEN/RED verdict.

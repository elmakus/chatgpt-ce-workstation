# Intake — Muse native upstream wiring

- Workstream ID: `change-muse-native-upstream`
- Kind: `change`
- Branch: `work/muse-native-upstream`
- Integration target: `main`
- Base: `dfa41ce0867824757a50dc151afe3a87c4826457`
- Status: complete

## Authorized scope

Persist the already-supported Muse/CLIProxyAPI native routing in the Workstation runtime so `codex-chatgpt-web` can discover and route `muse-*` models through the configured CLIProxyAPI endpoint without disrupting Codex-LB or `chatgpt-web/*`.

## Baseline evidence

- Workstation `compose.yaml` passes only `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`; it does not pass `CODEX_CHATGPT_WEB_MUSE_UPSTREAM`.
- Live production Workstation likewise exposes only `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM=http://192.168.2.104:2455/backend-api/codex`.
- CLIProxyAPI is reachable on `192.168.2.104:8317` and authenticated `GET /v1/models` returns HTTP 200 with five `muse-*` model IDs.
- The persistent Workstation home contains the Codex-LB key file but no `muse-proxy-api-key`.
- The released fork `elmakus/codex-chatgpt-web` already implements optional `CODEX_CHATGPT_WEB_MUSE_UPSTREAM`, a separate Muse ingress key, Muse-only catalog merge, fail-closed Muse routing, and Codex-LB isolation.

## Identity / dependency classification

No existing matching Workstation branch or workstream was found. The completed `feature-muse-worker-orchestration` workstream is separate: it owns direct Muse Code worker execution and does not own CLIProxyAPI routing.

This change is independent and branches from current `main`.

## Classification

The repository had no accepted Workstation product/system authority for exposing CLIProxyAPI Muse rows, and the existing implementation plan explicitly kept Muse out of the Codex Web GPT phase. Generic change Intake therefore routed first through Project Definition rather than treating this as an unplanned execution-only edit.

Definition is materialized as:
- `requirements/MUSE_NATIVE_UPSTREAM.md` R1
- `docs/DECISIONS.md#d29--muse-is-an-optional-parallel-native-upstream-through-cliproxyapi`

Next route: strategic planning for this bounded integration.

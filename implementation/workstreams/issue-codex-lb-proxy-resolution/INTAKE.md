# Intake — issue-codex-lb-proxy-resolution

## Identity

- Kind: issue
- Workstream: `issue-codex-lb-proxy-resolution`
- Branch: `fix/codex-lb-proxy-resolution`
- Base: `elmakus/chatgpt-ce-workstation@04440574afb2d85790301c915e9d7f8c90721021`
- Integration target: `main`
- Dependency classification: independent
- Parent workstream: none

## Operator intent

Investigate the ChatGPT CE remote-operation failure shown after routing native Codex traffic from `codex-chatgpt-web` through Codex-LB, identify whether the Codex-LB integration broke session continuation, and correct the bounded transport defect without changing the accepted routing architecture.

## Baseline diagnosis

Observed user-facing failure on 2026-09-20:

- ChatGPT CE reports `502 Bad Gateway: Launcher native proxy resolution failed (HTTP 400)`.
- The failed local bridge request is `http://127.0.0.1:17841/v1/responses`.

Source-level reproduction is deterministic on current `elmakus/codex-chatgpt-web` main:

- `src/native-network.ts` rewrites the official native Codex request to `CODEX_CHATGPT_WEB_NATIVE_UPSTREAM`, then asks the launcher control server to resolve the system proxy for the **rewritten upstream URL**.
- `launcher/electron/control-server.cjs` currently accepts proxy-resolution requests only when the supplied URL origin is exactly `https://chatgpt.com` and the path starts with `/backend-api/codex/`.
- A configured Codex-LB URL such as `http://127.0.0.1:2455/backend-api/codex` therefore fails that launcher allowlist and produces HTTP 400 before any Codex-LB request is attempted.
- `src/native-network.ts` converts that HTTP 400 into the exact error `Launcher native proxy resolution failed (HTTP 400)`, which explains the CE 502 shown by the operator.

The defect was introduced by the native-upstream integration path itself: proxy resolution was moved after upstream rewrite, while the launcher's allowlist remained restricted to the official ChatGPT origin.

## Workstream discovery / base decision

No existing Codex-LB proxy-resolution issue workstream or matching open PR was found in `elmakus/chatgpt-ce-workstation`. The active `feat/smart-upstream-updates` workstream is unrelated: this failure is reproducible from current `main` plus the already-merged Codex-LB fork behavior and does not require parent-only state. The issue is independent and based on current `main`.

The implementation defect lives in the related fork `elmakus/codex-chatgpt-web`; the workstation workstream owns the integration/release evidence and acceptance of the corrected fork artifact.

## Micro-fix qualification

- Root cause and intended behavior are concrete: custom native upstreams must still inherit the launcher's system-proxy decision without being rejected merely because the rewritten URL is not `https://chatgpt.com`.
- Change is bounded and low strategic risk: correct the proxy-resolution boundary and add regression coverage for configured native upstreams.
- No accepted product, routing, authentication, architecture, or model-selection decision needs to change.
- Acceptance is direct: a Codex-LB rewritten native request no longer causes launcher HTTP 400, official ChatGPT-native proxy resolution remains valid, and the launcher does not become a general arbitrary-URL proxy oracle.
- No substantial migration or deployment strategy is required; a corrected fork release plus normal workstation consumption/verification is sufficient.

## Downstream classification

- Path: `micro_fix`
- Next route: `execution_prep:micro_fix`
- Canonical continuation anchor: this completed Intake record plus `WORKSTREAM.yaml`.

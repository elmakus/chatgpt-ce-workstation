# Intake — OpenCodex provider hub

Status: active

## Identity

- Workstream ID: `change-opencodex-provider-hub`
- Kind: `change`
- Branch: `work/opencodex-provider-hub`
- Integration target: `main`
- Creation base: `dfa41ce0867824757a50dc151afe3a87c4826457`

## Authorized scope

Prepare a durable plan for evaluating and, if the live proof succeeds, adopting OpenCodex as the single Codex/ChatGPT CE provider hub/model-catalog owner so the workstation can expose native Codex, Meta Muse, CLIProxyAPI-backed models when retained, and browser-backed `chatgpt-web/*` models without maintaining provider aggregation inside the `elmakus/codex-chatgpt-web` fork.

The operator owns live workstation smoke testing and will report pass/fail observations back to ChatGPT. Planning and implementation must therefore separate repository/static verification from explicit operator-run live gates.

## Relevant discovered state

- Current integrated workstation authority still selects the `elmakus/codex-chatgpt-web` fork as the default Codex Web GPT package source (D11).
- Existing independent workstream `change-muse-native-upstream` on `work/muse-native-upstream` implements an optional Muse path through CLIProxyAPI. The new work does not require that branch's unmerged state and is therefore independent from it.
- `lidge-jun/opencodex` current main can inject itself into stock Codex through `openai_base_url` plus a generated `model_catalog_json`, expose routed `provider/model` entries, configure arbitrary OpenAI-compatible providers, manage ChatGPT/Codex account pools, and includes a Meta Muse OAuth provider.
- Upstream `miuuyy/codex-chatgpt-web` provides a standalone `serve` command and its daemon owns the browser-backed `chatgpt-web/*` Responses path. Whether it can operate cleanly as a downstream OpenCodex provider without owning the Codex route is the primary live compatibility question.
- The earlier `elmakus/codex-chatgpt-web` branch `design/cliproxyapi-native-aggregator` pursued the inverse topology (Codex Web GPT as top-level aggregator). Its own design notes already identify provider aggregation as proxy-owned responsibility rather than browser-adapter responsibility.

## Base/dependency classification

Classification: independent.

Rationale: the proposed proof and architecture can be defined and implemented from workstation `main`. It does not need any unmerged behavior from `work/muse-native-upstream`; instead, successful adoption may supersede parts of that work. Keeping this lane independent avoids making the evaluation depend on the solution it is intended to replace.

## Downstream classification

Path: Project Definition -> Strategic Planning.

Reason: adopting OpenCodex as the route/catalog owner changes accepted workstation architecture, including D11 and the relationship between Codex Web GPT, Muse, Codex-LB and CLIProxyAPI. This is not a bounded implementation continuation.

The Definition must preserve a fail-safe migration rule: no existing working provider path is removed or superseded durably until the corresponding operator-run live acceptance gate is GREEN.

## User-owned live gate

The operator will execute live tests on the workstation and report the observed result. ChatGPT will provide exact commands/checklists and will not claim live success without that report.

## Next durable owner

Pending materialization of canonical requirements/decision authority for this workstream.

# OpenCodex Provider Hub — Project Definition

Revision: `OPH-R1`
Status: `approved`
Updated: `2026-09-22`

## Goal / target state

Evaluate OpenCodex as the single Codex/ChatGPT CE model-catalog and provider-routing owner for the Workstation. If the operator-run live proof is GREEN, adopt it so stock ChatGPT CE can expose and route:

1. native Codex models backed by the existing Codex path / Codex-LB;
2. models exposed by CLIProxyAPI where that service remains useful;
3. browser-backed `chatgpt-web/*` models provided by upstream `miuuyy/codex-chatgpt-web`;
4. Meta Muse through OpenCodex's native Meta Muse integration when it is behaviorally equivalent to the currently intended CLIProxyAPI Muse path.

The migration is evidence-gated. Existing working routes remain available until the corresponding replacement has passed the explicit live acceptance gate.

## Product / system requirements

| ID | Requirement | Priority | Source / decision | Status |
|---|---|---|---|---|
| OPH-REQ-001 | OpenCodex is the candidate single owner of the Codex route/model catalog presented to ChatGPT CE; provider aggregation must not be reimplemented inside the browser adapter when OpenCodex can own it. | MUST | user / D31 | accepted |
| OPH-REQ-002 | The ChatGPT CE model picker must be able to expose distinct, deterministic model rows for the required provider families without ambiguous model ownership. | MUST | user / D31 | accepted |
| OPH-REQ-003 | Native Codex traffic must remain usable through the selected native backend path, initially preserving Codex-LB as an allowed upstream. | MUST | user / existing deployment | accepted |
| OPH-REQ-004 | CLIProxyAPI must remain connectable as an OpenAI-compatible OpenCodex provider during evaluation so its models can be represented in the same picker when required. | MUST | user | accepted |
| OPH-REQ-005 | Browser-backed `chatgpt-web/*` models must continue using the ChatGPT Web/browser path and its Full Harness behavior; OpenCodex must not silently replace them with API/Codex models that consume a different quota or execution path. | MUST | user / existing D11 intent | accepted |
| OPH-REQ-006 | The preferred browser provider is unmodified upstream `miuuyy/codex-chatgpt-web`; the `elmakus/codex-chatgpt-web` fork may be retired only after upstream `serve` works as a downstream provider behind OpenCodex and all required browser-backed acceptance checks pass. | MUST | user / D31 | accepted |
| OPH-REQ-007 | OpenCodex's native Meta Muse provider may replace the CLIProxyAPI Muse route only after the live acceptance surface proves the required Muse model, effort/tool behavior and session path are equivalent enough for this Workstation. | MUST | user / D31 | accepted |
| OPH-REQ-008 | No existing Codex-LB, CLIProxyAPI, Muse or browser-backed route is removed, disabled in production, or declared superseded solely from static/source evidence. | MUST | user live-test ownership / D31 | accepted |
| OPH-REQ-009 | Live acceptance is operator-run: ChatGPT prepares exact commands/checklists and records the result the operator reports; ChatGPT must not claim a live PASS it did not observe through the operator's report or an authorized runtime surface. | MUST | user | accepted |
| OPH-REQ-010 | The proof must be reversible and must not require replacing the production route before the candidate catalog/routing stack is validated. | MUST | D10 / D15 / D25 / D31 | accepted |
| OPH-REQ-011 | A failed OpenCodex proof must leave the currently working CE/Codex Web GPT/Codex-LB/CLIProxyAPI paths recoverable without data loss or forced reauthentication beyond what the tested component itself requires. | MUST | D8 / D10 / D15 / D31 | accepted |
| OPH-REQ-012 | Provider credentials and browser login state remain outside Git and use existing persistent-home/secret mechanisms appropriate to each provider. | MUST | D8 / D14 / D26 | accepted |
| OPH-REQ-013 | The final accepted Workstation configuration must be reproducible from repository-owned image/Compose/source state; ad-hoc live configuration is proof evidence, not the final source of truth. | MUST | D10 / D16 | accepted |
| OPH-REQ-014 | CE Android Remote/native task behavior must not regress as a consequence of making OpenCodex the route/catalog owner. | MUST | D4 / D15 | accepted |
| OPH-REQ-015 | Model-catalog entries must preserve provider-specific capability truth; unsupported compact/search/image/subagent features must not be advertised merely because another provider supports them. | MUST | verified provider constraints / D31 | accepted |
| OPH-REQ-016 | The migration must define an explicit fallback route that restores the previous known-working owner of `openai_base_url` / catalog state if OpenCodex integration fails. | MUST | D15 / D25 / D31 | accepted |
| OPH-REQ-017 | Codex-LB and CLIProxyAPI decommissioning are separate conditional outcomes, not prerequisites for this migration. They may remain deployed behind OpenCodex if they still provide required behavior. | MUST | user / D31 | accepted |
| OPH-REQ-018 | The active `change-muse-native-upstream` workstream must not be merged, deleted, or marked superseded by this workstream until live evidence proves that the new OpenCodex path covers the behavior that workstream was intended to provide and normal workflow closure is performed. | MUST | concurrent-workstream safety / D31 | accepted |

## Constraints

- ChatGPT CE remains the desktop host and CE's bundled Codex remains the authoritative native runtime.
- OpenCodex must integrate with the existing persistent `/home/codex` model and repository-owned image lifecycle.
- The test topology may use temporary ports/configuration, but production ownership of Codex route/catalog state must be singular and deterministic.
- The operator performs live Workstation tests and reports results.
- Existing active workstreams remain independent until an explicit closure/supersession transition is justified by durable evidence.
- A provider advertised in the picker must have a routing path that can actually service the advertised capability.

## Non-goals

- Reimplementing OpenCodex provider routing inside `codex-chatgpt-web`.
- Forking OpenCodex unless a concrete blocking defect is proven and cannot be solved through supported configuration/upstream contribution.
- Removing Codex-LB merely because OpenCodex also supports ChatGPT account pooling.
- Removing CLIProxyAPI merely because OpenCodex also supports Meta Muse.
- Rewriting browser automation owned by upstream `codex-chatgpt-web`.
- Performing production live migration without an explicit operator-run acceptance gate.
- Treating static configuration success as proof that browser-backed Full Harness, compaction, subagents or Android Remote work live.

## Global invariants

- One component owns the Codex-facing route/catalog integration at a time.
- Provider identity in the picker maps deterministically to one intended upstream route.
- Browser-backed ChatGPT Web traffic stays browser-backed.
- Existing production paths remain recoverable until replacement evidence is GREEN.
- Live PASS/FAIL is operator-owned evidence.
- Repository source remains the final reproducible configuration authority.

## External contracts / dependencies

- `lidge-jun/opencodex` current supported Codex integration, provider configuration and catalog sync behavior.
- `miuuyy/codex-chatgpt-web` standalone `serve` behavior and its `chatgpt-web/*` Responses/catalog surface.
- Codex-LB's Codex/OpenAI-compatible Responses and model endpoints.
- CLIProxyAPI's OpenAI-compatible `/v1` surface and configured provider catalog.
- ChatGPT CE/Codex interpretation of `openai_base_url`, `model_catalog_json`, model capabilities, compaction and subagent metadata.

## Acceptance-level requirements

The architecture may be adopted only when the operator reports GREEN for the required live proof:

1. ChatGPT CE starts normally with OpenCodex as the candidate route/catalog owner.
2. The picker contains at least one expected model from each required family under test:
   - native Codex/Codex-LB;
   - CLIProxyAPI;
   - `chatgpt-web/*`;
   - Meta Muse, either direct OpenCodex Meta Muse or the retained CLIProxyAPI route according to the tested topology.
3. One ordinary turn succeeds for each selected family and reaches the intended provider.
4. One browser-backed `chatgpt-web/*` Full Harness turn can use a harmless local Codex tool and return its result.
5. Required compact behavior is verified for native and browser-backed paths; a provider that does not support compact is not falsely advertised as supporting it.
6. Subagent smoke verifies the selected compatibility/native mode without silently rerouting a child to the wrong provider.
7. Android Remote can open/use the resulting CE task path without regression.
8. Restart/recreate preserves required OpenCodex/provider configuration and credentials according to the persistent-home contract.
9. Disabling the candidate integration restores the previous known-working route without damaging login/profile/project state.
10. Only after the relevant checks above are GREEN may the plan authorize source migration away from the custom `codex-chatgpt-web` fork or closure of the older Muse-native-upstream workstream.

## Definition completeness

Definition Complete: GREEN.

No product choice required for planning remains unresolved. The proof intentionally leaves implementation-time compatibility questions (especially upstream `codex-chatgpt-web serve` behind OpenCodex) as evidence gates rather than pretending they are already proven.

# OPH-M01-T03 — Add isolated secret-free provider proof configuration

- Milestone: `OPH-M01`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected manifest-bound workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md` revision `OPH-PLAN-R2`, milestone `OPH-M01 — Reversible provider-hub proof substrate`
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`: OPH-REQ-001, 002, 003, 004, 005, 006, 007, 008, 009, 010, 011, 012, 013, 015, 016, 017, 018
- Accepted decisions: `docs/DECISIONS.md` D8, D10, D11, D14, D15, D16, D25, D31
- Relevant OpenSpec: none
- Accepted dependency results:
  - `OPH-M01-T01` GREEN at `commit:c6e6c8f437d8c378525177a5685862153f1c0ef3` with frozen OpenCodex `@bitkyc08/opencodex@2.59.0`
  - `OPH-M01-T02` GREEN at `commit:22e226ceb4d6d63b98051c738877c85f69bc9ab5` with isolated proof lifecycle evidence in `implementation/workstreams/change-opencodex-provider-hub/evidence/OPH-M01-T02.md`
- Frozen upstream configuration contract: `lidge-jun/opencodex@v2.59.0` / release target `134c92a01b120162f00c7275189cc47858720379`

### JIT facts bound from predecessor/upstream evidence

- `OPENCODEX_HOME` selects the OpenCodex config directory; `config.json` lives directly under that directory.
- `ocx config validate <path> [--json]` validates a candidate configuration without requiring `ocx init`.
- A custom provider row is representable with an explicit provider id plus `adapter` and `baseUrl`; API-key material is not required merely to schema-validate the row.
- Provider ids are constrained by OpenCodex to deterministic routing-safe names using letters/numbers/dot/underscore/hyphen.
- Frozen OpenCodex `v2.59.0` includes the registry provider `meta-muse` using the `openai-responses` adapter at `https://api.meta.ai/v1`, OAuth auth mode, static header `x-api-version: 1.0.0`, and static Muse Spark 1.3 model metadata. Its own upstream note marks first device login/unverified subscription use as unsupported/high-risk; credential acquisition/use remains a later operator-owned live gate.
- The final upstream `codex-chatgpt-web` daemon ownership and final service-manager/layout remain unresolved by design and are not frozen by this Card.

### Must preserve

- The current fork-backed Codex Web GPT route, production Codex home and current CE route/catalog owner remain unchanged.
- All generated or validated proof configuration must live in the isolated proof OpenCodex home established by T02 or in disposable test paths; never write normal `~/.opencodex` or `~/.codex`.
- Provider credentials, ChatGPT/OAuth state, Muse credentials, CLIProxyAPI secrets, browser login/profile state and generated management tokens must not be embedded in Git, image layers, generated fixture output or command-line examples.
- Provider namespaces are deterministic and non-ambiguous. The proof topology uses stable ids for the three downstream families: `codex-lb`, `cliproxyapi`, and `chatgpt-web`; native Meta Muse remains the upstream registry identity `meta-muse`.
- Downstream base URLs and model selections are explicit proof inputs, not guessed production defaults. Loopback/private proof endpoints may be accepted only through an explicit provider-level private-network opt-in supported by OpenCodex.
- Configuration generation/validation is offline and opt-in. It must not start OpenCodex/downstream daemons, run provider tests, perform login, call `ocx init`, call `ocx sync`, install services/shims, or alter CE/Codex injection/catalog state.
- Browser-backed traffic remains designated as browser-backed; this Card must not map `chatgpt-web` rows to native/API Codex or Meta models.
- A static/generated `meta-muse` provider row is not evidence that Muse subscription credential reuse, billing semantics, device login, or behavioral equivalence is GREEN. OPH-REQ-007 remains for later live acceptance.
- The independent `change-muse-native-upstream` workstream remains untouched and unsuperseded.

### Must not / rationale that must travel

- Do not hard-code workstation-specific downstream ports or credentials just to make the generated file look complete; exact live endpoints are operator/runtime evidence inputs.
- Do not freeze the final browser model-id normalization, browser-daemon ownership or production supervisor here. Those depend on later compatibility evidence.
- Do not treat schema validation as provider compatibility or picker/live-route acceptance.
- Do not modify production `openai_base_url`, `model_catalog_json`, Codex auth/account state, or the existing production browser launcher.

## Dependencies

- `OPH-M01-T02`

## Outcome

The repository can deterministically render and validate a secret-free, isolated OpenCodex provider-proof configuration for the required candidate provider families without starting them or changing the currently working CE/Codex route. The resulting artifact is suitable as the bounded input to later exact-candidate/provider compatibility tests.

## Scope

### Included

- Add a repository-owned noninteractive proof-config renderer/helper for the isolated T02 proof home.
- Represent deterministic provider namespaces for:
  - `codex-lb` as an explicitly supplied OpenAI-compatible downstream;
  - `cliproxyapi` as an explicitly supplied OpenAI-compatible downstream;
  - `chatgpt-web` as an explicitly supplied browser-backed downstream;
  - frozen OpenCodex `meta-muse` / Muse Spark metadata without credential material or login.
- Require explicit downstream base URL inputs and bounded adapter/model inputs where the live contract is not yet proven; validate names/URLs/adapter choices fail-closed.
- Make loopback/private downstream intent explicit rather than silently widening outbound-network policy.
- Produce deterministic output for identical inputs and support writing to a caller-selected disposable path or the isolated proof-home config path.
- Add a validation path that invokes the frozen installed `ocx config validate` against the generated candidate under isolated environment roots.
- Add focused negative coverage for malformed URLs, unsupported adapter values, missing required endpoint inputs, unsafe/ambiguous provider ids if configurable, and accidental secret-bearing input/output.
- Record exact generated-config/readback commands for the next compatibility step.

### Excluded

- Starting or probing Codex-LB, CLIProxyAPI, upstream `codex-chatgpt-web serve`, Meta Muse or OpenCodex data-plane traffic.
- Provider credentials, login/import flows, browser profiles, OAuth state or API keys.
- `ocx init`, `ocx sync`, OpenCodex Codex injection, service installation, auto-start or production route/catalog takeover.
- Final browser model-id normalization or proof that upstream `serve` works behind OpenCodex.
- Production CE picker changes, Full Harness/compact/subagent/Android Remote testing.
- Decommissioning or superseding Codex-LB, CLIProxyAPI, the current browser fork or `change-muse-native-upstream`.
- Final OpenCodex service-manager/layout and browser-daemon ownership.

## Acceptance

- Identical inputs render byte-identical provider-proof configuration with stable provider ids `codex-lb`, `cliproxyapi`, `chatgpt-web`, and `meta-muse`.
- Generated configuration contains no API keys, OAuth tokens, browser credentials, passwords, management tokens or secret placeholders that could be mistaken for deployable credentials.
- Required downstream endpoint inputs are explicit and validated; malformed/non-http(s) endpoints fail closed, and loopback/private endpoints require explicit private-network intent.
- The generated candidate validates successfully with the exact frozen installed OpenCodex `2.59.0` using `ocx config validate` under isolated T02 state roots.
- Negative fixtures fail validation deterministically and do not write into production `~/.opencodex` or `~/.codex`.
- Rendering/validation performs no network/provider probe, login, sync, service/shim operation, daemon start or Codex injection.
- Existing normal workstation startup, current CE route/catalog state and production browser path are source-identical outside the bounded proof tooling.
- Documentation/evidence explicitly states that config/schema GREEN is not live provider compatibility evidence.

## Required tests / checks

- focused deterministic proof-config renderer/validation tests, including negative cases and secret scan assertions
- `bash scripts/validate-source.sh`
- exact-candidate invocation of the installed frozen `ocx config validate` against a generated disposable proof configuration
- CI source validation / Dockerfile static check / repository secret scan when the implementation subject is frozen for review

## Optional execution hints

- Priority: `HIGH`
- Complexity: `MEDIUM`
- Phase: `OPH-M01 isolated provider configuration`
- Expected/relevant code locations:
  - `rootfs/usr/local/bin/`
  - `scripts/`
  - `scripts/validate-source.sh`
  - `.github/workflows/candidate-build.yml`
  - `Dockerfile`

## External write/readback needs

GitHub branch source commits and non-production/disposable exact-candidate validation only. No production Workstation route/config mutation and no provider credential write is authorized.

## Independent review

`RECOMMENDED` — this Card establishes the provider namespace/configuration boundary and secret/network fencing that later live routing depends on; independent review should verify deterministic identities, no credential leakage, no production takeover, and exact frozen-OpenCodex validation.

## Contract overrides

None.

# OPH-M02-T01 — Add isolated OpenCodex data-plane probe

## Milestone

`OPH-M02 — Direct provider compatibility proof`

## Outcome

Add one repository-owned, opt-in helper that lets the operator exercise the already-isolated OpenCodex proof data plane without changing ChatGPT CE route/catalog ownership.

The helper provides bounded commands for:
- OpenCodex health;
- provider/model catalog inspection;
- exact model presence verification;
- one fixed harmless non-streaming Responses turn for an explicitly selected model.

It is proof tooling only. It is not the OPH-LIVE-A verdict and it must never run live inference automatically in CI or normal startup.

## Authority

- Master Plan: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md`, revision `OPH-PLAN-R2`, milestone `OPH-M02`.
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md`, revision `OPH-R1`: OPH-REQ-002, OPH-REQ-003, OPH-REQ-004, OPH-REQ-005, OPH-REQ-006, OPH-REQ-007, OPH-REQ-009, OPH-REQ-011, OPH-REQ-012, OPH-REQ-015, OPH-REQ-017.
- Cross-cutting preservation: OPH-REQ-008, OPH-REQ-010, OPH-REQ-013, OPH-REQ-018.
- Decisions: `docs/DECISIONS.md` D8, D10, D11, D14, D15, D16, D25, D31.
- Accepted predecessor: `OPH-M01` GREEN at `commit:33023b6915b1fe80b2e1efa828af3fd2f90348ec`; acceptance `implementation/workstreams/change-opencodex-provider-hub/evidence/OPH-M01.md`.
- Frozen OpenCodex proof runtime: `lidge-jun/opencodex@v2.59.0`, source commit `134c92a01b120162f00c7275189cc47858720379`.
- Frozen upstream browser proof runtime remains `miuuyy/codex-chatgpt-web@v5.0.8`, source commit `00aab23eb78a0d35ab575ff14044e29c0f80e711`; this Card does not start or configure it.

## Dependency facts

- `workstation-opencodex-proof` already owns isolated OpenCodex/Codex roots and proof port `10170` by default.
- `workstation-opencodex-proof-config` already owns deterministic secret-free proof configuration and keeps Codex native injection/steering disabled.
- Frozen OpenCodex serves its local data plane at `/v1`; `GET /v1/models` is the catalog surface and `POST /v1/responses` is the primary Responses inference surface.
- Loopback proof access requires no repository credential. This Card must not add provider keys, admission keys, OAuth material or browser state.

## Included scope

- Add one image-owned helper, `/usr/local/bin/workstation-opencodex-live-a`.
- Add offline focused tests using a fake local curl transport; tests must make no network/provider call.
- Wire the focused test into source validation.
- Add an exact candidate-image smoke that proves the installed helper exists and its offline contract passes.
- Update candidate-build path filters/packaging only as required for this helper.

## Excluded scope

- No provider credential setup or login.
- No automatic or CI inference against Codex-LB, CLIProxyAPI, ChatGPT Web or Meta Muse.
- No upstream browser-profile setup/start/stop.
- No Meta Muse equivalence decision.
- No CE `openai_base_url`, `model_catalog_json`, picker or route ownership change.
- No production OpenCodex service manager, shim, `ocx init`, or production-home mutation.
- No modification of `elmakus/codex-chatgpt-web`, `miuuyy/codex-chatgpt-web`, OpenCodex, or `change-muse-native-upstream`.

## Must preserve

- The helper targets only loopback `http://127.0.0.1:<OPENCODEX_PROOF_PORT>`; arbitrary remote base URLs are not accepted.
- The selected model is always explicit. The helper must not auto-select, rewrite or silently fall back to another model/provider.
- The harmless prompt is fixed in source and contains no project/user data.
- No Authorization/API-key/cookie input is accepted or printed.
- Live response execution is operator-invoked only.
- Failures are nonzero and identify the failed surface without dumping secret-bearing environment/state.
- Normal startup remains unchanged and never invokes this helper.

## Acceptance

1. `health` checks the isolated proof health endpoint on the configured proof port.
2. `models` returns the local OpenCodex model catalog without changing state.
3. `model <exact-id>` succeeds only when the exact id is present and otherwise fails nonzero.
4. `response <exact-id>` sends exactly one non-streaming Responses request with the fixed harmless prompt to that explicit id; it fails nonzero on transport/HTTP/malformed-response failure.
5. The helper rejects extra/missing arguments, invalid proof ports and non-explicit model ids.
6. Focused tests use a fake curl implementation and prove no live network call is needed.
7. Source validation and ShellCheck cover the new helper/test.
8. Exact candidate-image smoke proves the installed helper passes the same offline contract.
9. Repository secret scan remains GREEN.
10. No normal startup or production route/catalog file is changed.

## Review

Independent review: `RECOMMENDED`.

Review must verify the exact implementation subject, the local-only/no-secret/no-auto-inference boundary, fake-transport coverage, candidate-image evidence, and that no CE/catalog ownership transition occurred.

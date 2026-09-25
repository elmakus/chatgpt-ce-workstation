# OPH-M01-T01 — Add frozen OpenCodex and upstream browser proof binaries

- Milestone: `OPH-M01`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected manifest-bound workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md` revision `OPH-PLAN-R2`, milestone `OPH-M01 — Reversible provider-hub proof substrate`
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`: OPH-REQ-001, 003, 008, 010, 011, 012, 013, 016
- Accepted decisions: `docs/DECISIONS.md` D8, D10, D11, D14, D15, D16, D25, D31
- Relevant OpenSpec: none — this Card extends the existing D25 image-managed supply-chain contract and deliberately does not define provider-routing or persistent runtime behavior
- Accepted dependency results: independent plan review `planning/reviews/OPH-PLAN-R2.md` GREEN for the exact R2 subject

### Must preserve

- Current fork-backed Codex Web GPT remains the production/default browser route and remains installed unchanged.
- Adding OpenCodex must not run `ocx init`, start a service, alter `~/.codex`, take over `openai_base_url`, or modify the CE model catalog.
- The unmodified `miuuyy/codex-chatgpt-web` proof runtime must coexist under a distinct non-production path/name; it must not replace the current `elmakus/codex-chatgpt-web` installation in this Card.
- OpenCodex and upstream browser proof artifacts must follow D25 `resolve -> freeze -> build -> validate`: latest trusted stable/current is resolved before build, exact identity/integrity is carried in the frozen resolution manifest, and the build consumes only that frozen identity.
- No provider credential, ChatGPT/OAuth credential, browser state, API key or other secret may enter Git, Docker build args, the frozen resolution manifest, or the image.
- Existing persistent `/home/codex`, CE, Android Remote, current Codex Web GPT startup, Codex-LB/CLIProxyAPI availability and rollback source remain untouched by this Card.
- Runtime application self-update must remain disabled/irrelevant to the image-owned components; repository source remains the reproducible authority.

### Must not / rationale that must travel

- Do not generalize the production fork installer or switch the production resolver to upstream here; OPH-M04 owns source migration after OPH-LIVE-B including recreate persistence is GREEN.
- Do not invent the final OpenCodex service manager, proof port/profile layout, browser daemon supervision or provider configuration. OPH-M01's JIT boundary explicitly defers those choices until the installed isolated runtime can be inspected/proven.
- Do not treat successful installation or a static `--version` check as proof that upstream `serve` works behind OpenCodex.

## Dependencies

- none

## Outcome

The Workstation exact-candidate pipeline can resolve, freeze, build and identify OpenCodex plus an unmodified upstream `miuuyy/codex-chatgpt-web` proof runtime alongside the still-authoritative fork, without enabling either candidate as a production route.

## Scope

### Included

- Extend the D25 upstream-resolution manifest with exact OpenCodex package identity and an exact unmodified upstream Codex Web GPT proof identity.
- Add optional expert/debug version overrides consistent with existing resolver policy without changing the default latest-stable/current behavior.
- Carry those exact identities through build-env rendering and Compose/Docker build arguments.
- Install OpenCodex into the image from the frozen package identity and verify the expected `ocx` executable/version surface.
- Install/extract the upstream Codex Web GPT proof runtime into a separate image-owned location/executable suitable for later isolated `serve` testing.
- Add deterministic resolver/render/install/source-validation coverage proving exact identity, separation from production, absence of automatic route takeover, and no secret material.
- Extend exact-candidate CI/readback only as needed to prove the candidate image contains the two frozen, version-identifiable proof components.

### Excluded

- Starting OpenCodex or upstream `serve` automatically.
- Writing OpenCodex provider configuration or credentials.
- Changing CE `openai_base_url`, `model_catalog_json`, picker rows or provider ownership.
- Removing or changing the current fork-backed Codex Web GPT production install/startup.
- Live provider compatibility, Full Harness, compact, subagent, Android Remote or rollback tests.
- Final service/supervision/port/profile/state design.
- Any change to the independent `change-muse-native-upstream` workstream.

## Acceptance

- Frozen resolution contains separate, deterministic identities for current fork Codex Web GPT, upstream proof Codex Web GPT, and OpenCodex.
- Build inputs reject missing/unknown/malformed candidate identity fields and propagate only the intended exact version/integrity/checksum values.
- Candidate image contains a version-identifiable `ocx` and a separately named upstream `codex-chatgpt-web` proof executable/runtime.
- Current `/usr/local/bin/codex-web-gpt`, its fork source and desktop auto-start behavior remain unchanged.
- No candidate component is auto-started and no Codex route/catalog config is changed by image build or normal container startup.
- Source validation and focused deterministic tests are GREEN.
- Exact-candidate build/readback is GREEN on the Card subject or any concrete failure is durably captured rather than waived.

## Required tests / checks

- `python3 scripts/test-resolve-upstreams.py`
- `python3 scripts/test-render-build-env.py`
- focused installer tests added by this Card
- `bash scripts/validate-source.sh`
- CI source validation / Dockerfile static check / secret scan
- exact-candidate build workflow including image readback for the newly frozen proof components

## Optional execution hints

- Priority: `HIGH`
- Complexity: `MEDIUM`
- Phase: `OPH-M01 supply-chain substrate`
- Expected/relevant code locations:
  - `scripts/resolve-upstreams.py`
  - `scripts/render-build-env.py`
  - `scripts/test-resolve-upstreams.py`
  - `scripts/test-render-build-env.py`
  - `scripts/build/`
  - `Dockerfile`
  - `compose.yaml`
  - `.env.example`
  - `scripts/validate-source.sh`
  - `.github/workflows/candidate-build.yml`

## External write/readback needs

GitHub branch source commits and CI workflow runs only. Required readback: exact branch HEAD plus CI/check results and candidate-image provenance/readback produced by the workflow. No production Workstation mutation is authorized by this Card.

## Independent review

`RECOMMENDED` — the Card changes the image supply chain and installs two third-party runtime artifacts; a fresh review should verify identity pinning, production-route non-interference, secret hygiene and evidence before dependent proof configuration work begins.

## Contract overrides

None.

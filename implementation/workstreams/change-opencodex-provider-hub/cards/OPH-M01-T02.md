# OPH-M01-T02 — Add isolated OpenCodex proof lifecycle

- Milestone: `OPH-M01`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected manifest-bound workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md` revision `OPH-PLAN-R2`, milestone `OPH-M01 — Reversible provider-hub proof substrate`
- Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` revision `OPH-R1`: OPH-REQ-001, 003, 008, 010, 011, 012, 013, 016
- Accepted decisions: `docs/DECISIONS.md` D8, D10, D11, D14, D15, D16, D25, D31
- Relevant OpenSpec: none
- Accepted dependency results: `OPH-M01-T01` GREEN at `commit:c6e6c8f437d8c378525177a5685862153f1c0ef3` with evidence `implementation/workstreams/change-opencodex-provider-hub/evidence/OPH-M01-T01.md`

### Must preserve

- The current fork-backed Codex Web GPT route and the production Codex home remain authoritative and unchanged.
- Every proof lifecycle command must select a dedicated OpenCodex home and a dedicated scratch Codex home before invoking `ocx`; no proof command may operate on the normal `~/.opencodex` or `~/.codex` paths by default.
- The proof state must live under persistent `/home/codex` while remaining distinct from normal user/provider state; disposable tests may override both homes to temporary paths.
- Do not run `ocx init`, install an OpenCodex service/shim, enable autostart, or inject OpenCodex into the production Codex configuration.
- Provider credentials, ChatGPT/OAuth state, API keys, browser state and generated management tokens remain outside Git and image layers.
- The proof lifecycle is an opt-in diagnostic substrate only. It must not start during normal container/desktop startup and must not change CE `openai_base_url`, model catalog ownership or picker rows.
- Keep the final OpenCodex service-manager/layout and upstream browser-daemon ownership deferred by the OPH-M01 JIT boundary.

### Must not / rationale that must travel

- Do not implement provider-family configuration in this Card. The next JIT step will bind provider configuration to the lifecycle behavior proven here.
- Do not use `ocx stop` or any other OpenCodex lifecycle command against the production Codex home: OpenCodex lifecycle operations may reconcile/restore Codex integration, so the proof must fence both state roots.
- Do not treat a successful `ocx --version` as runtime proof; the actual installed frozen candidate must start, answer health, and stop inside the isolated homes.

## Dependencies

- `OPH-M01-T01`

## Outcome

The repository provides an explicit opt-in OpenCodex proof lifecycle that can start the frozen image-owned OpenCodex runtime in isolated state, verify health/status, and stop it without touching the production Codex/OpenCodex homes or changing the current CE route.

## Scope

### Included

- Add one repository-owned proof lifecycle helper with bounded commands for starting, stopping and inspecting the isolated OpenCodex process.
- Use deterministic default proof-state paths under `/home/codex`, distinct from normal OpenCodex/Codex homes, with environment overrides for disposable tests.
- Use a dedicated configurable proof port without publishing or taking over any production route.
- Add deterministic tests proving command/env fencing, forbidden lifecycle operations, opt-in-only behavior and production-path separation.
- Add a disposable candidate-runtime smoke that uses the actual installed `ocx`: isolated start, health/status readback, stop, and proof that the production Codex/OpenCodex paths were not used or mutated.
- Record concise usage/readback commands suitable for the later OPH-M01 operator proof without defining the final production supervisor.

### Excluded

- Provider definitions for Codex-LB, CLIProxyAPI, upstream `codex-chatgpt-web serve` or Meta Muse.
- `ocx init`, `ocx service`, Codex shim/autostart installation, production `~/.codex` injection or production `~/.opencodex` adoption.
- Starting the upstream browser proof daemon.
- CE route/catalog takeover, picker changes, provider credentials or live production mutation.
- Final service-manager, daemon supervision or production port/profile choices.

## Acceptance

- The proof helper always supplies isolated `OPENCODEX_HOME` and `CODEX_HOME` values before any `ocx` lifecycle invocation.
- Defaults are deterministic, persistent under `/home/codex`, and cannot alias the normal production homes; explicit overrides suitable for disposable tests are supported.
- No proof helper path invokes `ocx init`, `ocx service`, `ocx ensure`, `ocx codex-shim`, or changes CE/Codex route/catalog configuration.
- Normal workstation startup remains unchanged and does not launch the proof.
- Source tests are GREEN.
- A disposable exact-candidate runtime using the frozen installed OpenCodex starts in the isolated homes, reports healthy/status as expected, stops cleanly, and leaves the normal production Codex/OpenCodex homes untouched.
- Any upstream CLI incompatibility discovered by the runtime smoke is captured as evidence and routed to bounded correction/research rather than bypassed.

## Required tests / checks

- focused proof-lifecycle unit/shell tests
- `bash scripts/validate-source.sh`
- candidate image/runtime smoke using the exact frozen OpenCodex executable
- CI source validation / Dockerfile static check / secret scan when source changes are frozen for review

## Optional execution hints

- Priority: `HIGH`
- Complexity: `MEDIUM`
- Phase: `OPH-M01 isolated runtime proof`
- Expected/relevant code locations:
  - `scripts/`
  - `scripts/validate-source.sh`
  - `.github/workflows/candidate-build.yml`
  - `Dockerfile`

## External write/readback needs

GitHub branch source commits and non-production candidate/runtime validation only. No production Workstation route/config mutation is authorized.

## Independent review

`RECOMMENDED` — this Card introduces lifecycle tooling around a stateful provider proxy; independent review should verify state-path fencing, no production-route mutation and exact runtime evidence before provider configuration is added.

## Contract overrides

None.

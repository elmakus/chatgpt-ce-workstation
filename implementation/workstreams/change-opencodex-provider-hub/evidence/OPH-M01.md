# OPH-M01 milestone acceptance evidence

Milestone: `OPH-M01 — Reversible provider-hub proof substrate`  
Plan revision: `OPH-PLAN-R2`  
Accepted implementation checkpoint: `commit:33023b6915b1fe80b2e1efa828af3fd2f90348ec`

## Verdict

**GREEN.**

The integrated milestone outcome is satisfied without changing production ChatGPT CE route/catalog ownership.

## Acceptance readback

- `OPH-M01-T01` is terminal GREEN with independent review. The image-managed proof contains frozen, version-identifiable OpenCodex and unmodified upstream `miuuyy/codex-chatgpt-web` binaries while retaining the existing production fork path. Exact candidate/runtime and CI evidence are recorded in `evidence/OPH-M01-T01.md`.
- `OPH-M01-T02` is terminal GREEN with independent review. The installed frozen OpenCodex starts, reports health/status, and stops through dedicated `OPENCODEX_HOME` / scratch `CODEX_HOME` roots; production-home sentinels remain unchanged and normal startup does not launch the proof. Exact evidence is recorded in `evidence/OPH-M01-T02.md`.
- `OPH-M01-T03` is terminal GREEN with independent review on `commit:33023b6915b1fe80b2e1efa828af3fd2f90348ec`. Deterministic provider configuration for `codex-lb`, `cliproxyapi`, `chatgpt-web`, and static `meta-muse` metadata renders without credentials, validates with frozen OpenCodex under isolated roots, and passes exact-subject CI + exact candidate runtime validation. Exact evidence is recorded in `evidence/OPH-M01-T03.md`.
- The reviewed source keeps `codexNativeInjection` and `codexNativeSteering` disabled in the proof config, does not run `ocx init`, does not install/start a production OpenCodex service, and does not mutate CE `openai_base_url`, picker/catalog ownership, existing Codex-LB/CLIProxyAPI routes, the fork-backed browser route, or the independent Muse workstream.
- Credentials, browser state, OAuth material, generated tokens, and provider secrets are absent from repository-owned proof configuration; repository CI secret scan is GREEN.

## Boundary

This checkpoint proves the reversible substrate and schema/configuration boundary only. It does **not** claim downstream live compatibility, browser-backed routing through upstream `serve`, Meta Muse credential/session equivalence, CE picker takeover, or production migration.

Those obligations begin at `OPH-M02` and its operator live gate `OPH-LIVE-A`.

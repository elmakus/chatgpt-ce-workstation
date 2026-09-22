# OPH-M01 cumulative handoff

Milestone: `OPH-M01 — Reversible provider-hub proof substrate`
Plan: `OPH-PLAN-R2`
Accepted implementation checkpoint: `33023b6915b1fe80b2e1efa828af3fd2f90348ec`

## Achieved state

OPH-M01 is GREEN. The workstream has an opt-in OpenCodex proof substrate while the normal ChatGPT CE/Codex route remains unchanged.

- Frozen OpenCodex 2.59.0 and unmodified upstream miuuyy/codex-chatgpt-web proof runtime are image-managed and version-identifiable.
- `workstation-opencodex-proof` provides isolated start, stop, health, status, and paths operations.
- `workstation-opencodex-proof-config` renders and validates deterministic proof configuration for `codex-lb`, `cliproxyapi`, `chatgpt-web`, and `meta-muse`.
- OPH-M01-T01, T02, and T03 are terminal with GREEN independent reviews.

## Authority and evidence

Requirements: `requirements/OPENCODEX_PROVIDER_HUB.md` OPH-R1.
Decisions: `docs/DECISIONS.md` D8, D10, D11, D14, D15, D16, D25, D31.
Plan: `planning/OPENCODEX_PROVIDER_HUB_PLAN.md` OPH-PLAN-R2.
Milestone evidence: `implementation/workstreams/change-opencodex-provider-hub/evidence/OPH-M01.md`.
Card evidence: `evidence/OPH-M01-T01.md`, `evidence/OPH-M01-T02.md`, `evidence/OPH-M01-T03.md`.

## Boundary and continuation

This checkpoint does not claim live downstream compatibility or CE catalog takeover. Final runtime ownership choices remain deferred until direct compatibility proof.

Next approved milestone: `OPH-M02 — Direct provider compatibility proof`. JIT preparation must derive bounded Cards for isolated provider proofs and the OPH-LIVE-A operator checklist. OPH-M02 must not change CE route ownership.

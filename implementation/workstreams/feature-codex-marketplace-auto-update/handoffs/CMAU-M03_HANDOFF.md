# CMAU-M03 cumulative handoff

Date: `2026-09-20`
Milestone: `CMAU-M03 — Runtime validation and release readiness`
Status: **GREEN / complete**

## Completed checkpoint

- Accepted implementation/candidate head: `577a64630b6aa942b89c7c657265f3d6e8f448f3`.
- Terminal Card: `CMAU-M03-T01`.
- Independent Card review: GREEN at `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-T01-review.md`.
- Milestone acceptance: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-acceptance.md`.
- Final integration: PR #8 merged to `main`; merge result `e059a6e4983810c0564f0f763503996461851051`.
- Target-side closure evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-final-integration-result.md`.

## Achieved state

The complete Codex marketplace auto-update workstream is integrated into `main`. The updater is one independent s6-overlay service, runs as `codex` with persistent `/home/codex`, uses CE's bundled Codex runtime, keeps a 24-hour cadence from persisted last success, treats zero marketplaces as success, and isolates bounded failure/retry from desktop/Workstation health.

Disposable candidate validation covered first run, restart/recreate-before-due, controlled due refresh, controlled failure, recovery and cleanup without production persistent-state mutation.

## Authority in force

- `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` (R1).
- `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md` (CMAU-R1).
- `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D15, D17, D24.
- Workstream manifest: `implementation/workstreams/feature-codex-marketplace-auto-update/WORKSTREAM.yaml`.

## Verification
- CMAU-M01 scheduler review: GREEN.
- CMAU-M02 s6/image integration review: GREEN.
- CMAU-M03 exact candidate/runtime review: GREEN.
- Workstream final-integration gate: GREEN through exact CMAU-M03 review coverage after a no-drift target refresh.
- Full source validation on the candidate subject: `SOURCE_VALIDATION_GREEN`.
- PR #8 target readback: GREEN; the namespaced workstream package is present on `main`.
- The source branch was automatically removed after merge, so no fallback `branch_cleanup` lifecycle is required.

## Material exceptions / deferred items

No live production Workstation recreate/cutover was performed. Production deployment or mutation of the user's real persistent Codex marketplace state remains a separate explicit authorization gate if requested later.

## Next durable starting point

The approved CMAU-R1 workstream scope is complete. No further deterministic implementation or integration obligation remains.

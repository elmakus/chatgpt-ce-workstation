# CMAU-M03 cumulative handoff

Date: `2026-09-20`
Milestone: `CMAU-M03 — Runtime validation and release readiness`
Status: **GREEN / implementation and runtime acceptance complete**

## Completed checkpoint

- Accepted implementation/candidate head: `577a64630b6aa942b89c7c657265f3d6e8f448f3`.
- Terminal Card: `CMAU-M03-T01`.
- Independent Card review: GREEN at `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-T01-review.md`.
- Milestone acceptance: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M03-acceptance.md`.

## Achieved state

The workstream now has the complete global Codex marketplace updater implementation plus exact disposable-candidate runtime validation. The updater is one independent s6-overlay service, runs as `codex` with persistent `/home/codex`, uses CE's bundled Codex runtime, keeps a 24-hour cadence from persisted last success, treats zero marketplaces as success, and isolates bounded failure/retry from desktop/Workstation health.

Candidate runtime evidence covers first run, restart/recreate-before-due, controlled due refresh, controlled failure, recovery and cleanup without production persistent-state mutation.

## Authority in force

- `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` (R1).
- `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md` (CMAU-R1).
- `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D15, D17, D24.
- Workstream manifest: `implementation/workstreams/feature-codex-marketplace-auto-update/WORKSTREAM.yaml`.

## Verification

- CMAU-M01 scheduler review: GREEN.
- CMAU-M02 s6/image integration review: GREEN.
- CMAU-M03 exact candidate/runtime review: GREEN.
- Full source validation on the candidate subject: `SOURCE_VALIDATION_GREEN`.
- Candidate build/runtime validation and cleanup: GREEN.

## Material exceptions / deferred items

- No live production Workstation recreate/cutover was performed; that remains a separate explicit authorization gate if later requested.
- Workstream final integration into `main` is not represented as complete until Close performs target refresh, final-integration review reconciliation, merge and target-side readback.

## Next durable starting point

Continue through branch-isolated Close for final integration into `main`.

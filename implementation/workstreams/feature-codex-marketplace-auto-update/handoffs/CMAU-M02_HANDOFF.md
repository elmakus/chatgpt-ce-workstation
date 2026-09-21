# CMAU-M02 cumulative handoff

Date: `2026-09-20`
Milestone: `CMAU-M02 — s6/image integration`
Status: **GREEN / complete**

## Completed checkpoint

- Accepted implementation head: `51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`.
- Terminal Card: `CMAU-M02-T01`.
- Independent Card review: GREEN at `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M02-T01-review.md`.
- Milestone acceptance: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M02-acceptance.md`.

## Achieved state

The repository now contains the deterministic CMAU-M01 marketplace updater core plus its image-owned s6-overlay v3 integration. The updater is registered as an independent Workstation user-bundle longrun, runs as `codex` with persistent `HOME=/home/codex`, launches the repository-owned updater core, and continues to use CE's bundled Codex runtime without adding another CLI.

Desktop lifecycle and Workstation health remain independent of updater success. The service/image integration is fully repository-owned and statically validated.

## Authority in force

- `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` (R1).
- `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md` (CMAU-R1).
- `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D17, D24.
- Workstream manifest: `implementation/workstreams/feature-codex-marketplace-auto-update/WORKSTREAM.yaml`.

## Verification

- New s6 run-script syntax: GREEN.
- Python updater/test compile checks: GREEN.
- Deterministic scheduler tests: 14/14 GREEN.
- Full repository source validation on the exact implementation subject: `SOURCE_VALIDATION_GREEN`.
- Independent exact-subject Card review: GREEN.

## Material exceptions / deferred items

- Candidate/live container runtime behavior is not yet accepted; it belongs to CMAU-M03.
- No live production recreate, real persistent marketplace mutation, or credential mutation was performed.
- Workstream final-integration review is not yet due because CMAU-M02 is an internal milestone checkpoint on the same workstream branch.

## Next durable starting point

Proceed to approved milestone `CMAU-M03 — Runtime validation and release readiness` through normal Execution Prep/JIT refinement. The explicit live production recreate/persistent marketplace mutation gate remains in force and must be honored when that operation becomes necessary.

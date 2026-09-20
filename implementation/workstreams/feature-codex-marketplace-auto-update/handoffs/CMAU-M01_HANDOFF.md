# CMAU-M01 cumulative handoff

Date: `2026-09-20`
Milestone: `CMAU-M01 — Deterministic scheduler core`
Status: **GREEN / complete**

## Completed checkpoint

- Accepted implementation head: `15b399ad0bdaf7ed843039be7e402cd75796352b`.
- Terminal Card: `CMAU-M01-T01`.
- Independent Card review: GREEN at `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-T01-review-2.md`.
- Milestone acceptance: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M01-acceptance.md`.

## Achieved state

The repository now contains a deterministic Codex marketplace updater core under `scripts/container/` with persistent last-success cadence, one all-marketplace bundled-Codex command, fail-closed JSON/command validation, atomic state replacement, bounded retry behavior, and deterministic injected seams for time/command/sleep testing.

The review-attempt-1 persistence defect is corrected: parent-directory fsync failure after an already-successful atomic replace is diagnostic-only rather than producing the contradictory state "failure + advanced last-success".

## Authority in force

- `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` (R1).
- `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md` (CMAU-R1).
- `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D17, D24.
- Workstream manifest: `implementation/workstreams/feature-codex-marketplace-auto-update/WORKSTREAM.yaml`.

## Verification

- Python updater/test compile checks: GREEN.
- Deterministic scheduler tests: 14/14 GREEN.
- Independent exact-subject Card review: GREEN.
- Current upstream Codex CLI contract independently checked during review for optional marketplace name/all-marketplace behavior, JSON fields, and zero-marketplace no-op.

## Material exceptions / deferred items

- Full repository `scripts/validate-source.sh` was not runnable on the prior implementation surface due unavailable Docker Compose/full-checkout dependency.
- No live/runtime marketplace mutation or Workstation deployment was performed.
- Workstream final-integration review is not yet due because this is an internal milestone checkpoint on the same workstream branch.

## Next durable starting point

Proceed to approved milestone `CMAU-M02 — s6/image integration` through normal Execution Prep/JIT refinement. The explicit live production recreate/persistent marketplace mutation gate remains deferred until the plan reaches the CMAU-M03 live-write boundary.

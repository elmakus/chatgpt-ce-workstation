# CMAU-M02 milestone acceptance

Date: `2026-09-20`
Milestone: `CMAU-M02`
Verdict: **GREEN**
Accepted implementation subject: `elmakus/chatgpt-ce-workstation@51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`

## Acceptance basis

- `CMAU-M02-T01` is terminal and its RECOMMENDED independent review is GREEN.
- The repository defines one independent `codex-marketplace-updater` s6-overlay v3 longrun and registers it through the normal Workstation user bundle.
- The service runs through `s6-setuidgid codex`, explicitly uses persistent `HOME=/home/codex`, and launches the repository-owned CMAU-M01 updater core.
- The updater continues to resolve CE's bundled Codex runtime at `/opt/codex-desktop/resources/codex`; no second Codex CLI is introduced.
- Dockerfile/source wiring installs the updater core and makes the s6 run entrypoint executable from repository-owned image state.
- Desktop service and Workstation healthcheck remain independent from updater success.
- No new credential store, credential material, cron/systemd timer, SessionStart refresh path, or per-plugin updater was added.

## Evidence

- Card implementation evidence: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M02-T01-implementation.md`.
- Independent GREEN review: `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M02-T01-review.md`.
- Card result subject: `51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`.
- Exact-subject verification records run-script bash syntax GREEN, Python compile GREEN, deterministic scheduler tests `14/14` GREEN, and full `bash scripts/validate-source.sh` → `SOURCE_VALIDATION_GREEN`.

## Deferred scope

- Candidate-container/runtime validation, real bundled-Codex execution under the service, restart/recreate cadence checks, controlled failure-path runtime checks, and final release readiness remain CMAU-M03 scope.
- Live production Workstation recreate or persistent live marketplace mutation remains behind the explicit authorization gate.

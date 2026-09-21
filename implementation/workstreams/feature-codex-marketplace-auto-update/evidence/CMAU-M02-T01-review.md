# CMAU-M02-T01 independent review

Date: `2026-09-20`
Review subject: `elmakus/chatgpt-ce-workstation@51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`
Verdict: **GREEN**

## Authority checked

- Stable Card: `implementation/workstreams/feature-codex-marketplace-auto-update/cards/CMAU-M02-T01.md`.
- Milestone: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m02--s6image-integration`.
- Definition: CMAU-REQ-001, CMAU-REQ-003, CMAU-REQ-008, CMAU-REQ-009, CMAU-REQ-013..015 in `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md`.
- Accepted architecture: D3, D6, D8, D10, D14, D17 and D24 in `docs/DECISIONS.md`.
- Accepted dependency: `implementation/workstreams/feature-codex-marketplace-auto-update/handoffs/CMAU-M01_HANDOFF.md`.

## Subject/evidence checked

- Exact immutable implementation subject `51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`.
- Added s6 longrun `rootfs/etc/s6-overlay/s6-rc.d/codex-marketplace-updater/{run,type}`.
- Added normal user-bundle registration `rootfs/etc/s6-overlay/user-bundles.d/user/contents.d/codex-marketplace-updater`.
- Dockerfile installation/executable wiring and repository-owned updater core.
- `scripts/validate-source.sh` static assertions.
- Existing desktop longrun and `rootfs/usr/local/bin/workstation-healthcheck`.
- Implementation evidence `implementation/workstreams/feature-codex-marketplace-auto-update/evidence/CMAU-M02-T01-implementation.md`.

## Review result

GREEN. The exact reviewed subject satisfies the CMAU-M02-T01 contract.

- The updater is one independent s6-overlay v3 `longrun` registered through the same user-bundle convention already used by the workstation.
- The run script drops privileges with `s6-setuidgid codex`, explicitly sets `HOME=/home/codex` (plus USER/LOGNAME), and launches the repository-owned updater core.
- The updater core continues to invoke the CE-bundled Codex runtime at `/opt/codex-desktop/resources/codex`; no standalone Codex installation path is introduced.
- Scheduler state remains below the persistent Codex home, preserving restart/recreate cadence ownership from CMAU-M01.
- Dockerfile source installs the updater core through the existing `COPY scripts/container/` path and makes the new service run entrypoint executable.
- The desktop service and Workstation healthcheck do not reference the updater; the reviewed change adds no s6 dependency coupling them to updater success.
- The reviewed source adds no credential material, secret store, cron/systemd path, SessionStart updater, or per-plugin timer.
- Runtime/live container validation and production marketplace mutation remain correctly deferred to CMAU-M03.

## Verification evidence

The implementation evidence records verification on an isolated detached worktree of the exact review subject:

- new run-script `bash -n`: GREEN;
- updater Python compile: GREEN;
- deterministic scheduler tests: `14/14` GREEN;
- full `bash scripts/validate-source.sh`: `SOURCE_VALIDATION_GREEN`.

Independent source inspection found no contradiction with that exact-subject evidence. GitHub exposes no separate status checks for this commit; the repository evidence is therefore the applicable recorded test provenance.

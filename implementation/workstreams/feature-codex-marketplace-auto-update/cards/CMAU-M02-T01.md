# CMAU-M02-T01 — s6/image integration for marketplace updater

- Milestone: `CMAU-M02`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in `implementation/workstreams/feature-codex-marketplace-auto-update/TASK_BOARD.yaml`.

## Authority slice

- Master Plan / milestone contract: `planning/CODEX_MARKETPLACE_AUTO_UPDATE_PLAN.md#milestone-cmau-m02--s6image-integration`
- Requirements: `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md` — CMAU-REQ-001, CMAU-REQ-003, CMAU-REQ-008, CMAU-REQ-009, CMAU-REQ-013..015
- Accepted decisions: `docs/DECISIONS.md` — D3, D6, D8, D10, D14, D17, D24
- Accepted dependency result: `implementation/workstreams/feature-codex-marketplace-auto-update/handoffs/CMAU-M01_HANDOFF.md`
- Relevant OpenSpec: none

### Must preserve

- One global updater service owns automatic refresh for all configured Git marketplaces.
- s6-overlay v3 remains the supervisor; no cron/systemd/session-start/per-plugin timer path.
- The updater runs as user `codex` with persistent `HOME=/home/codex`.
- The default updater command continues to use CE's bundled Codex runtime; no second Codex CLI is installed.
- Scheduler state stays under the persistent Codex home and therefore survives restart/recreate.
- Updater failure must remain independent from desktop lifetime and the Workstation health condition.
- No new credentials or secret store are introduced; existing Codex/Git authentication is used at runtime.
- All runtime/service installation is reproducible from tracked repository source/image state.

### Must not / rationale that must travel

- Do not perform a live Workstation recreate, run a real network marketplace refresh, or mutate persistent live marketplace configuration in this Card.
- Do not add service dependencies that make `desktop` or the container healthcheck depend on updater success.
- Do not add another updater implementation or duplicate the scheduler core from CMAU-M01.
- Do not add a standalone Codex installation or credential material.

## Dependencies

- `CMAU-M01-T01` done and CMAU-M01 accepted GREEN.

## Outcome

The existing CMAU-M01 updater core is installed and registered as an independent repository-owned s6 longrun in the Workstation image, starts under user `codex` with persistent home, resolves the CE-bundled Codex path already used by the core, and is statically validated without coupling updater success to desktop/health behavior.

## Scope

### Included

- Add the updater s6 service source under `rootfs/etc/s6-overlay/s6-rc.d/`.
- Register the service under `rootfs/etc/s6-overlay/user-bundles.d/user/contents.d/`.
- Launch the updater through the accepted s6 privilege-drop primitive as user `codex` and ensure `HOME=/home/codex`.
- Wire service-run executability/installation into the Dockerfile or existing image-owned installation path.
- Extend `scripts/validate-source.sh` with source/static assertions for service type, registration, runtime user/home, updater entrypoint and CE-bundled Codex wiring.
- Preserve the existing deterministic updater tests and source validation wiring.

### Excluded

- Candidate/live container runtime validation (CMAU-M03).
- Live production recreate/deployment.
- Real network marketplace refresh or persistent marketplace mutation.
- Changes to desktop health semantics or desktop service lifecycle.
- Changes to individual marketplace/plugin repositories.

## Acceptance

- Repository source defines exactly one marketplace-updater s6 `longrun` and registers it in the normal Workstation user bundle.
- The service launches the repository-owned updater core as user `codex` with `HOME=/home/codex`.
- The image makes the service run entrypoint executable and installs the updater core through existing repository COPY paths.
- Static validation proves the s6 type, registration, user/home/entrypoint wiring, and CE-bundled Codex command path.
- Desktop healthcheck/source contains no dependency on marketplace updater success.
- No cron/systemd/session-start/per-plugin updater, new credential store, or second Codex CLI is introduced.

## Required tests / checks

- `bash -n` for the new s6 run script and affected shell validation source.
- Existing updater `python3 -m py_compile` and deterministic scheduler tests remain GREEN.
- `scripts/validate-source.sh` when runnable in the verification environment; if an environment dependency prevents the full script, record the exact unavailable dependency and execute the affected static/syntax/deterministic checks directly.
- Source inspection confirming the desktop longrun and Workstation healthcheck are not coupled to updater success.
- Source inspection confirming no credential material or additional Codex installation path was introduced.

## External write/readback needs

Repository writes on `feat/codex-marketplace-auto-update` only. No live runtime, deployment, persistent marketplace or credential write is authorized by this Card.

## Independent review

`RECOMMENDED` — this Card changes image-owned service supervision/runtime identity wiring and should receive an independent exact-subject review before terminal completion.

## Contract overrides

None.

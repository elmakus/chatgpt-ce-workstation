# CMAU-M02-T01 implementation evidence

Date: `2026-09-20`
Implementation subject: `elmakus/chatgpt-ce-workstation@51d9cf2463c03c15dde6ae0c09965fc6ba572ab8`
Card: `CMAU-M02-T01`

## Implemented scope

- Added one independent s6-overlay v3 longrun:
  - `rootfs/etc/s6-overlay/s6-rc.d/codex-marketplace-updater/run`
  - `rootfs/etc/s6-overlay/s6-rc.d/codex-marketplace-updater/type`
- Registered the service in the normal Workstation user bundle:
  - `rootfs/etc/s6-overlay/user-bundles.d/user/contents.d/codex-marketplace-updater`
- The service drops privileges with `s6-setuidgid codex`, sets `HOME=/home/codex`, `USER=codex`, and `LOGNAME=codex`, and launches the repository-owned `/opt/workstation/bin/codex_marketplace_updater.py`.
- Extended the existing Dockerfile executable-installation block for the updater service run script. The existing repository-owned `COPY scripts/container/ /opt/workstation/bin/` path installs the updater core.
- Extended `scripts/validate-source.sh` with static assertions for service type, bundle registration, user/home/entrypoint wiring, Dockerfile installation, and independence from desktop/Workstation health.

No live Workstation recreate, real network marketplace refresh, persistent marketplace mutation, credential mutation, or standalone Codex installation was performed.

## Verification

GREEN on an isolated detached worktree of the exact implementation subject on the authorized Tower repository checkout:

- `bash -n rootfs/etc/s6-overlay/s6-rc.d/codex-marketplace-updater/run`
- `python3 -m py_compile scripts/container/codex_marketplace_updater.py scripts/test-codex-marketplace-updater.py`
- `python3 scripts/test-codex-marketplace-updater.py` → `14/14` GREEN.
- `bash scripts/validate-source.sh` → `SOURCE_VALIDATION_GREEN`.

The full source validator also passed:
- shell syntax for 21 tracked shell/run files;
- 9/9 managed-global-AGENTS fixtures;
- Codex marketplace updater deterministic tests and independent s6 service wiring;
- Docker Compose config validation;
- canonical project paths;
- container boundary checks;
- Codex/CE/image-managed application checks;
- desktop recovery/health independence checks;
- secret hygiene checks.

## Acceptance assessment

- Exactly one repository-owned `codex-marketplace-updater` s6 longrun is defined and registered.
- Service runtime identity is `codex` with persistent `HOME=/home/codex`.
- The service launches the existing CMAU-M01 updater core rather than duplicating scheduler logic.
- The updater core retains the CE-bundled Codex path `/opt/codex-desktop/resources/codex`; no second Codex CLI path was introduced.
- Workstation healthcheck and the desktop s6 run script contain no dependency on `codex-marketplace-updater`.
- No new credential store, secret material, cron/systemd path, SessionStart hook, or per-plugin updater was introduced.

The Card is implementation-complete but non-terminal pending its RECOMMENDED fresh independent exact-subject review.

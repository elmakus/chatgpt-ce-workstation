# M01-T01 implementation evidence — Muse capability substrate

Date: 2026-09-20
Workstream: `issue-muse-worker-mcp-access`
Card: `M01-T01`
Implementation subject: exact commit frozen by the selected Task Board after this evidence is committed.

## Implemented scope

- Reconciled `docs/MUSE_CODE_PLAN.md` with D21/D25/D26 and the accepted cross-repository capability architecture.
- Removed stale workstation-owned worker lifecycle wording, including the old fresh-session-per-worker assumption.
- Documented the existing full `/home/codex` bind as the persistence substrate for Muse-owned config/auth/skills.
- Documented `elmakus/codex_workflow` ownership of structured `MuseCapabilityHints` and `elmakus/muse-capability-admin` ownership of rare capability administration.
- Documented mutation-authority, credential and secret-handling boundaries without introducing a generic vault or new secret wiring.
- Added source validation that protects the persistent Muse HOME and cross-repository documentation boundaries.
- Added read-only runtime verification that the Muse environment uses `HOME=/home/codex`.

## Verification

- `bash -n scripts/validate-source.sh scripts/verify-runtime.sh` — GREEN.
- `git diff --check` — GREEN.
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`.
- Existing managed-global-AGENTS fixture tests — 9/9 GREEN as part of source validation.
- Existing Codex marketplace updater tests — 14/14 GREEN as part of source validation.

## Targeted readback

- Compose still bind-mounts the full persistent home at `/home/codex`.
- Dockerfile still sets `HOME=/home/codex`.
- `rootfs/usr/local/bin/muse` has no non-comment `HOME=` override and therefore inherits the persistent home.
- Runtime verifier contains the explicit `HOME=/home/codex` assertion.
- `docs/MUSE_CODE_PLAN.md` contains the persistent capability/skill plane plus explicit `codex_workflow` and `muse-capability-admin` ownership boundaries.
- `defaults/AGENTS.md` does not contain the Muse capability-administration runbook.

## External-state boundary

No production rebuild/recreate, Muse setting change, MCP configuration/authentication, OAuth grant, user-skill mutation, external-service write, or credential handling was performed by M01-T01.

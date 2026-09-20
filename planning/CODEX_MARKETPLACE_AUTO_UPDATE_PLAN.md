# Master Plan — Codex Marketplace Auto-Update

Plan revision: `CMAU-R1`
Status: `draft`
Date: `2026-09-20`
Independent plan review: `RECOMMENDED`

## Goal and authority

Implement the approved feature defined by:
- `requirements/CODEX_MARKETPLACE_AUTO_UPDATE.md`;
- architecture decisions D3, D6, D8, D10, D14, D17 and D24 in `docs/DECISIONS.md`.

This plan is feature-specific and does not replace the existing Muse-max `planning/MASTER_PLAN.md`.

## Execution baseline

- Workstation already runs s6-overlay v3 and registers user services through `/etc/s6-overlay/user-bundles.d/user/contents.d/`.
- The current desktop is an independent s6 longrun.
- CE's bundled Codex CLI currently supports all-marketplace `plugin marketplace upgrade --json`.
- `/home/codex` is persistent across restart/recreate.
- A no-marketplace refresh is currently a successful no-op.
- No updater service exists yet on this branch.

## Inherited invariants

- s6-overlay remains the service supervisor.
- The updater runs as `codex`, not root.
- No standalone Codex CLI is introduced.
- Last-success state, not container uptime, owns the 24-hour cadence.
- Failure cannot advance success state or affect desktop/Workstation health.
- No LLM/manual/session-start path participates in normal refresh.
- All source/runtime changes must be reproducible from repository-owned image state.

## Milestone CMAU-M01 — Deterministic scheduler core

### Outcome

A small repository-owned updater/scheduler implementation can determine when refresh is due, invoke a configurable Codex command, persist successful cadence state safely, and retry failures without busy looping.

### Requirement ownership

CMAU-REQ-002..CMAU-REQ-007, CMAU-REQ-010..CMAU-REQ-012, CMAU-REQ-016.

### Planned work packages

1. Define the scheduler state contract:
   - persisted last-success time;
   - due-time calculation;
   - first-run behavior;
   - atomic success-state update;
   - failure/retry behavior.
2. Implement the updater core with injectable/overridable command, time and sleep seams sufficient for deterministic tests.
3. Define success classification for Codex `--json` output using current runtime evidence; fail closed if command/JSON reports upgrade errors.
4. Add tests covering:
   - first run;
   - restart before due;
   - exact/overdue refresh;
   - zero-marketplace no-op;
   - command failure;
   - JSON-reported error;
   - malformed state;
   - interrupted/failed refresh not advancing last success;
   - bounded retry without real-time 24-hour waits.

### Acceptance checkpoint

- Scheduler behavior is deterministic under tests.
- Last-success state advances only after verified refresh success.
- Tests require no network and no real 24-hour sleep.
- No secret or model-context output path is introduced.

### JIT boundary

Exact state-file format/path and retry interval may be chosen during Execution Prep inside the approved requirements.

## Milestone CMAU-M02 — s6/image integration

### Outcome

The scheduler is installed as an independent Workstation s6 longrun in the image, registered through the accepted user bundle, running as `codex` with persistent home and CE-bundled Codex resolution.

### Requirement ownership

CMAU-REQ-001, CMAU-REQ-003, CMAU-REQ-008, CMAU-REQ-009, CMAU-REQ-013..CMAU-REQ-015.

### Dependencies

CMAU-M01 GREEN.

### Planned work packages

1. Add the s6 service source under `rootfs/etc/s6-overlay/s6-rc.d/`.
2. Register it under `rootfs/etc/s6-overlay/user-bundles.d/user/contents.d/`.
3. Ensure the longrun launches through `s6-setuidgid codex` (or the equivalent accepted s6 primitive) with `HOME=/home/codex`.
4. Resolve/invoke the CE-bundled Codex runtime without installing a separate CLI.
5. Wire executable permissions/build assertions into the Dockerfile or existing image validation path.
6. Add source-level/static tests that verify service registration, permissions and expected command wiring.
7. Confirm no dependency ties updater lifecycle to the desktop longrun or Workstation healthcheck.

### Acceptance checkpoint

- Image source contains a complete reproducible updater service.
- Service registration matches s6-overlay v3 Workstation conventions.
- It runs as `codex` with persistent state location.
- Desktop service and healthcheck remain independent.
- No cron/systemd/per-skill updater is introduced.

## Milestone CMAU-M03 — Runtime validation and release readiness

### Outcome

The exact built Workstation candidate demonstrates cadence persistence and safe failure behavior in a real container/runtime before integration.

### Requirement ownership

Cross-cutting acceptance for CMAU-REQ-001..CMAU-REQ-016.

### Dependencies

CMAU-M01 and CMAU-M02 GREEN.

### Planned work packages

1. Build the candidate image using normal repository tooling.
2. Validate service presence/user/lifecycle in the candidate container.
3. Exercise first-run refresh and verify persisted success state.
4. Restart/recreate the service/container with a not-yet-due timestamp and verify no extra refresh.
5. Exercise due-state refresh using a controlled state/time adjustment rather than waiting 24 hours.
6. Exercise a controlled failing marketplace/command path and verify:
   - success timestamp unchanged;
   - bounded retry behavior;
   - prior state remains usable;
   - desktop/health remain unaffected.
7. Revalidate a normal zero-marketplace/all-marketplace success path.
8. Record exact runtime evidence required for final integration review.

### Explicit deployment/live-write gate

Rebuilding/recreating the user's live Workstation or mutating persistent live Codex marketplace configuration is not implicitly authorized by this plan. Execution may complete source implementation and disposable/candidate-container verification first. A live production recreate or persistent live marketplace mutation requires explicit user authorization at the point it becomes necessary.

### Acceptance checkpoint

- Runtime behavior matches Definition across restart/recreate semantics.
- Updater failure cannot make the desktop/Workstation unhealthy.
- Exact bundled Codex invocation works under the `codex` user.
- Persistent scheduler state behaves correctly.
- All source and runtime evidence is sufficient for normal final integration review.

## Requirement coverage

| Requirements | Owner milestone | Execution path |
|---|---|---|
| CMAU-REQ-002..007, 010..012, 016 | CMAU-M01 | scheduler core + deterministic tests |
| CMAU-REQ-001, 003, 008, 009, 013..015 | CMAU-M02 | s6/image integration + static validation |
| CMAU-REQ-001..016 | CMAU-M03 | candidate runtime validation + integration evidence |

## Verification strategy

- Unit/component tests own timing/state/failure semantics.
- Static/source validation owns s6 registration and image wiring.
- Candidate-container validation owns user identity, executable discovery and actual Codex CLI behavior.
- Real 24-hour waits are never required in automated testing.
- A live production recreate is a separate authorization gate.

## Data integrity / security strategy

- Atomic last-success persistence.
- Fail closed on ambiguous refresh result; never record success from an unverified error result.
- Do not persist credentials in updater state/logs.
- Use existing user Git/Codex auth environment only.
- Keep all failures isolated from healthcheck/desktop service.
- Avoid root writes into persistent user-owned marketplace state by running the updater as `codex`.

## Deployment / rollback strategy

- Source implementation lands first without modifying the live running container.
- Build/test candidate before any live recreate.
- Because the service is additive and independent, rollback is removal/disable of its image service plus rebuild/recreate; existing marketplace snapshots/user home remain intact.
- Do not delete persistent scheduler state during ordinary rollback unless specifically needed for diagnosis.

## Planning audit

Result: `GREEN`

- Definition coverage: complete.
- Existing architecture decisions preserved.
- Existing Muse plan remains untouched.
- Milestone order is minimal: scheduler semantics → image/service integration → runtime validation.
- Failure/security/persistence semantics are explicit.
- Deployment authorization boundary is explicit.
- No strategic/product decision is deferred to implementation.
- Exact retry/path/parser details are correctly left as bounded JIT choices.
- Independent plan review classification: `RECOMMENDED` because this is a new nontrivial runtime service and review is practical.

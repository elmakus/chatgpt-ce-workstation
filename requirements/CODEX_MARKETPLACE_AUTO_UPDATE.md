# Codex Marketplace Auto-Update — Project Definition

Revision: `R1`
Status: `approved`
Updated: `2026-09-20`

## Goal / target state

The Workstation automatically refreshes all configured Git-backed Codex plugin marketplaces once per 24 hours through one deterministic, machine-level scheduler. The refresh path requires no LLM turn, no agent decision, no SessionStart hook, and no manual user command.

## Product / system requirements

| ID | Requirement | Priority | Source / decision | Status |
|---|---|---|---|---|
| CMAU-REQ-001 | Workstation owns exactly one global automatic marketplace updater for all configured Git-backed Codex marketplaces. | MUST | user / D24 | accepted |
| CMAU-REQ-002 | Normal successful refresh cadence is 24 hours from the last successful refresh, not 24 hours from container start. | MUST | user / D24 | accepted |
| CMAU-REQ-003 | Scheduler state survives container restart/recreate through the persistent Codex user home. | MUST | D8 / D24 | accepted |
| CMAU-REQ-004 | If no successful refresh has ever been recorded, the updater performs its first refresh promptly after the service becomes active. | MUST | D24 | accepted |
| CMAU-REQ-005 | When the last successful refresh is less than 24 hours old, restart/recreate must not trigger an unnecessary refresh; the service waits until the remaining due time. | MUST | D24 | accepted |
| CMAU-REQ-006 | The updater refreshes all configured Git marketplaces in one Codex invocation by omitting a marketplace name. | MUST | verified runtime / D24 | accepted |
| CMAU-REQ-007 | A system with zero configured Git marketplaces is a valid successful no-op and must not be treated as an error. | MUST | verified runtime / D24 | accepted |
| CMAU-REQ-008 | The updater runs under s6-overlay as an independent Workstation service and uses the existing s6 service model; no cron or systemd timer is introduced. | MUST | D6 / D24 | accepted |
| CMAU-REQ-009 | Marketplace refresh runs as user `codex` with the persistent Codex home and uses CE's bundled Codex runtime rather than installing/maintaining a second Codex CLI. | MUST | D3 / D8 / D24 | accepted |
| CMAU-REQ-010 | A refresh failure must not advance the last-success timestamp, corrupt/remove the previously working marketplace snapshot, make the Workstation unhealthy, or restart the desktop. | MUST | user / D24 | accepted |
| CMAU-REQ-011 | After failure the service retries later using a bounded non-busy retry interval; exact retry duration is an implementation parameter unless runtime evidence requires escalation. | MUST | D24 | accepted |
| CMAU-REQ-012 | Refresh diagnostics are available through ordinary service/container logging and are not injected into Codex/LLM session context. | MUST | D24 | accepted |
| CMAU-REQ-013 | The feature adds no new credentials or secret store; Git access uses the existing `codex` user's normal Codex/Git authentication environment. | MUST | D14 / D24 | accepted |
| CMAU-REQ-014 | Individual skills/plugins do not embed their own automatic updater, timer, or SessionStart refresh path as part of this architecture. | MUST | user / D24 | accepted |
| CMAU-REQ-015 | The complete updater implementation and service registration are reproducible from repository-owned image/source state. | MUST | D10 / D24 | accepted |
| CMAU-REQ-016 | Timer behavior is testable without real 24-hour waits through controllable time/command boundaries or equivalent deterministic test seams. | SHOULD | planning constraint | accepted |

## Constraints

- Existing Workstation architecture decisions D3, D6, D8, D10, D14 and D17 remain authoritative.
- The updater is independent of desktop/CE application lifetime.
- The feature must not add a standalone Codex CLI solely for background updates.
- The feature must not require changes to individual marketplace/plugin repositories.

## Non-goals

- SessionStart-based refresh.
- Per-skill/per-plugin updater logic.
- Cron or systemd.
- Updating CE itself.
- Managing plugin installation policy or deciding which plugins should be enabled.
- Providing marketplace credentials.
- Treating marketplace availability as a Workstation health condition.
- Guaranteeing live/hot reload into an already-running Codex session.

## Global invariants

- Last-success time is the source of cadence truth.
- Failure never records success.
- Restart/recreate does not reset cadence.
- All configured Git marketplaces are targeted together.
- Transient network/Git failures remain isolated from desktop/Workstation health.
- The updater runs without LLM/manual intervention.

## External contracts / dependencies

- s6-overlay v3 service lifecycle and Workstation user bundle.
- Persistent `/home/codex`.
- CE-bundled Codex CLI supporting `plugin marketplace upgrade --json`.
- Existing user-level Git/Codex authentication when a configured marketplace requires remote access.

## Data integrity / idempotency / security constraints

- Persist last-success state atomically enough that interruption cannot create a false successful timestamp.
- Only a verified successful refresh may advance last-success state.
- Repeated service starts against a not-yet-due state are non-mutating.
- Do not persist secrets in scheduler state or logs.
- Keep prior working marketplace state usable when refresh fails.

## Acceptance-level requirements

The feature is acceptable when:
1. a fresh state performs one prompt refresh and records success;
2. a restart before 24 hours does not refresh again;
3. the next refresh occurs once due, based on persisted last success;
4. zero configured Git marketplaces succeeds as a no-op;
5. a simulated refresh failure leaves last-success unchanged and retries later without busy looping;
6. service failure does not affect desktop/Workstation health;
7. the service runs as `codex` and invokes the CE-bundled Codex runtime;
8. source/image validation proves the s6 service is registered reproducibly;
9. normal tests exercise timing/failure behavior without waiting a real day.

## Definition completeness

Definition Complete: GREEN.

No unresolved user/product decision remains. Exact state path, retry interval, executable discovery details, and success JSON validation are implementation-time decisions constrained by the requirements above.

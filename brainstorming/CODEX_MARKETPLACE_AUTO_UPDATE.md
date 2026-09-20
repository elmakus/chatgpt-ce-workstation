# Brainstorm — Codex marketplace automatic updater

Date: `2026-09-20`
Scope ID: `codex-marketplace-auto-update`
Revision: `R1`
Status: `ready_for_definition`

## Problem / goal

Add one Workstation-owned, deterministic, non-LLM timer that refreshes all configured Git-backed Codex plugin marketplaces automatically once per 24 hours. Individual skills/plugins must not embed their own updater or require manual user commands.

## Current understanding

### Verified facts

- Workstation uses `s6-overlay` as PID 1/service supervisor (accepted architecture decision D6).
- D6 already defines the s6-overlay v3 user-service membership path as `/etc/s6-overlay/user-bundles.d/user/contents.d/`.
- The current image defines the desktop as an s6 `longrun`; adding another independent longrun fits the existing service model.
- The current Codex runtime exposes `codex plugin marketplace upgrade [MARKETPLACE_NAME]`; omitting the marketplace name refreshes all configured Git marketplaces.
- On the current runtime, `codex plugin marketplace upgrade --json` with no configured Git marketplaces returns an empty successful result and exit code 0.
- The authoritative Codex executable currently used by CE is available at `/opt/codex-desktop/resources/codex`; there is no separate standalone Codex CLI in Workstation architecture (D3).
- `/home/codex` is persistent (D8), so scheduler state can survive container recreate/restart.
- System/application behavior must be reproducible from repository source (D10).

### Explicit user/product choices already made

- Use a **timer**, not a SessionStart hook.
- Refresh automatically once per 24 hours.
- One global updater refreshes all configured Git marketplaces.
- No LLM invocation, no agent decision and no manual user command are part of normal update execution.
- Individual skills/plugins must not carry separate updater hooks/timers.
- The feature belongs in `elmakus/chatgpt-ce-workstation`; `newproject-skill` only supplies a Git-backed marketplace/plugin source.

## Preferred design

### Service model

Add a dedicated s6 `longrun`, tentatively named `codex-marketplace-updater`, registered in the normal Workstation user bundle.

The service runs as user `codex` with `HOME=/home/codex` and invokes the CE-bundled Codex CLI, not a separately installed CLI.

### 24-hour schedule semantics

Prefer a **persistent last-success timestamp** rather than a simple container-lifetime `sleep 86400` loop.

Behavior:
1. on service start, read the persisted last-success timestamp;
2. if no successful refresh has ever been recorded, perform the first refresh promptly;
3. if the last success is less than 24 hours old, sleep only until it becomes due;
4. when due, run `codex plugin marketplace upgrade --json` without a marketplace name;
5. record a new timestamp only after a successful refresh;
6. after success, the next due time is 24 hours later.

Consequences:
- container restarts/recreates do not reset the 24-hour cadence;
- no unnecessary refresh occurs merely because the container restarted;
- adding another Git marketplace automatically makes it participate in the next global refresh;
- no Git marketplaces configured is a valid successful no-op.

### Failure behavior

Preferred tentative behavior:
- never corrupt or remove the previously installed marketplace/plugin snapshot merely because refresh failed;
- do not advance the last-success timestamp after failure;
- log a concise diagnostic;
- retry later with a bounded shorter delay (tentatively one hour) rather than spin/retry continuously;
- a network/GitHub outage must not make the Workstation container unhealthy or restart the desktop.

Exact retry interval is an implementation-level parameter unless evidence shows it materially affects system behavior.

### State and observability

- Persist scheduler state under the persistent codex home in a Workstation-owned path (exact path deferred to implementation).
- Service logs should be available through normal container/s6 logging.
- Do not inject update output into Codex/LLM session context.
- No credentials are added to this feature; marketplace Git access uses the normal Codex/Git environment available to the `codex` user.

### CLI resolution

The service should use the CE-bundled Codex runtime consistent with D3. Exact executable resolution should tolerate upstream packaging changes when practical; do not introduce a second independently managed Codex binary solely for this updater.

## Alternatives considered

### SessionStart hook + 24h TTL

Rejected by explicit user preference. It is lightweight but only refreshes when a Codex session starts/resumes.

### Plain `sleep 86400` longrun

Technically simple, but container restarts reset the cadence and can cause extra refreshes. Persistent due-time semantics are preferable.

### cron/systemd timer

Not preferred. Workstation already standardizes on s6-overlay and explicitly avoids systemd. Adding cron solely for one periodic task creates another lifecycle mechanism.

### One updater per skill/plugin

Rejected. Codex can refresh all Git marketplaces in one command, so per-skill updater logic would duplicate timers and state.

## Constraints / invariants to promote

- s6-overlay remains the only service supervisor.
- The updater is independent of desktop/CE lifetime and must not affect Workstation health on transient update failure.
- It uses CE's bundled Codex runtime.
- It runs as `codex`, not root, for user marketplace/config state.
- Scheduler state survives container restart/recreate.
- Normal refresh cadence is 24 hours from the last successful refresh.
- Refresh targets all configured Git marketplaces in one pass.
- No LLM/manual interaction is required.
- No per-plugin/per-skill scheduler logic.
- Feature is fully reproducible from repository source.

## Research / implementation verification still needed

- Verify the cleanest exact s6 longrun registration/dependency shape in this image; current D6 + runtime layout already establish the accepted bundle path.
- During implementation, verify CLI failure/JSON semantics for a deliberately failing Git marketplace and decide whether success should require both exit 0 and an empty JSON `errors` array.
- Verify the exact persistent state/log path and executable discovery against the then-current CE package.
- Add deterministic tests with a fake Codex command/time source where practical rather than relying on real 24-hour waits.

## Outcome

- Accepted direction: strict timer-based global updater owned by Workstation.
- Recommended architecture: independent s6 longrun with persistent last-success scheduling and all-marketplace Codex refresh.
- No unresolved product/strategic question currently remains; failure retry cadence and exact paths are implementation details.
- Next phase/action: `ready for definition`
- Definition promotion authorization: `pending`
- Definition promotion subject: `none`

> Nothing in this file becomes accepted requirement/decision authority by itself. Project Definition owns promotion into canonical `requirements/` and `decisions/`.

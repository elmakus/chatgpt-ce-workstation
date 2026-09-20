# noVNC Passwordless Access Requirements

Revision: `R1`
Status: `draft`
Updated: `2026-09-20`

## Goal / target state

The Workstation noVNC recovery desktop must open without asking for a VNC/noVNC password.

## Product / system requirements

| ID | Requirement | Priority | Source / decision | Status |
|---|---|---|---|---|
| NPA-001 | noVNC access must not require a VNC password or a noVNC password secret. | MUST | Operator request 2026-09-20 | accepted |
| NPA-002 | Raw VNC must remain bound only to container loopback and must not be published directly. | MUST | D7, D14 | accepted |
| NPA-003 | The published noVNC endpoint remains intended only for trusted-network exposure unless a separate authenticated ingress is deliberately added. | MUST | D14 preserved security boundary | accepted |
| NPA-004 | Fresh setup, preflight, source validation, runtime validation, and deployment must not require or create the legacy `novnc-password` secret or persistent `vnc.pass` file. | MUST | Consequence of NPA-001 | accepted |
| NPA-005 | Removing VNC authentication must not weaken unrelated Docker isolation, mount, privilege, keyring, CE, Remote Control, or desktop-lifecycle constraints. | MUST | Existing Workstation authority | accepted |

## Constraints

- noVNC remains the lightweight recovery/configuration desktop described by D7.
- Docker Compose remains the runtime source of truth.
- The change must be reproducible from repository source; it must not rely on a one-off live-container edit.
- Existing installations may retain obsolete noVNC secret files in appdata, but runtime correctness must not depend on them.

## Non-goals

- Exposing noVNC directly to untrusted/public networks.
- Replacing noVNC with another remote desktop stack.
- Adding a new reverse proxy, SSO layer, VPN, or other authenticated ingress.
- Changing GNOME Keyring behavior.
- Changing Android Remote Control or CE authentication.

## Global invariants

- x11vnc/raw VNC is loopback-only inside the container.
- Only websockify/noVNC is published by the workstation service.
- No credentials or sensitive runtime state are committed to Git.
- Existing container privilege/isolation constraints remain unchanged.

## Data integrity / idempotency / security constraints

The requested target deliberately removes the VNC password barrier. Security therefore depends on restricting the published noVNC endpoint to a trusted network or placing a separately authenticated ingress in front of it before broader exposure.

The implementation must not silently publish raw VNC or broaden network exposure as part of removing the password.

## Acceptance-level requirements

- Opening the configured noVNC URL reaches the desktop without a VNC password prompt.
- Workstation startup succeeds when `APPDATA_ROOT/secrets/novnc-password` does not exist.
- Source/host/runtime verification no longer treats the noVNC password secret or `vnc.pass` as required state.
- Raw TCP VNC is not host-published and remains loopback-only in the container.
- noVNC desktop startup, health/restart semantics, application relaunch behavior, CE, Codex Web GPT, and keyring behavior remain functional.

## Definition completeness

Pending reconciliation of the accepted D14 security decision. No other product choice is currently unresolved.

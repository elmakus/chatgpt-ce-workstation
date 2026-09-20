# Issue Intake — remove noVNC password

Workstream ID: `issue-remove-novnc-password`
Kind: `issue`
Branch: `fix/remove-novnc-password`
Status: `complete`

## Operator intent

Remove the password requirement from the Workstation noVNC access path so opening the noVNC desktop does not require a VNC password.

## Baseline evidence

Baseline: `elmakus/chatgpt-ce-workstation@e796e2fef00e348e2329be1a4856da335dff6842` (`main`).

- `compose.yaml` declares the `novnc_password` secret from `APPDATA_ROOT/secrets/novnc-password`.
- `rootfs/etc/cont-init.d/10-workstation-init` reads `/run/secrets/novnc-password`, requires a non-empty password when present, and materializes `/home/codex/.config/workstation/vnc.pass` with `x11vnc -storepasswd`.
- `scripts/container/desktop-session-inner.sh` starts x11vnc with `-rfbauth "$vnc_auth_file"`.
- `scripts/init-unraid.sh` prompts for and creates the noVNC/VNC password secret.
- `scripts/preflight-host.sh`, `scripts/validate-source.sh`, and `scripts/verify-runtime.sh` require or validate the noVNC secret/auth file.
- Accepted decision `docs/DECISIONS.md#D14 — Security / exposure` currently states that VNC passwords are supplied from Unraid-side secret files.
- Accepted decision D7 keeps raw VNC loopback-only while publishing websockify/noVNC for recovery access.

The requested behavior therefore contradicts current accepted D14 security authority and cannot be treated as a bounded micro-fix under unchanged authority.

## Existing workstream / dependency discovery

Relevant existing noVNC history on `main`:
- `implementation/workstreams/maintenance-novnc-workarea` is terminal/done and concerns Openbox/Tint2 workarea behavior, not authentication.

Current active branches include unrelated keyring/runtime and Docker-retention work. Open PR #13 changes GNOME keyring migration/rollback behavior and is not required to reproduce or define the noVNC password change.

Classification: **independent**.

- Integration target: `main`
- Exact creation base: `elmakus/chatgpt-ce-workstation@e796e2fef00e348e2329be1a4856da335dff6842`
- Parent workstream: none
- Parent dependency: none

## Intake classification

Path: Project Definition.
Next route: `project_definition`.
Canonical starting authority: `requirements/NOVNC_PASSWORDLESS_ACCESS.md`.

Reason: removing noVNC authentication changes accepted security/exposure intent in D14. Definition must explicitly reconcile the intended network exposure/security model before implementation planning/execution.

The issue is independent and intake is complete.

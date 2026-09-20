# Issue Intake — keyring auto-unlock prompts

Workstream ID: `issue-keyring-auto-unlock-prompts`
Kind: `issue`
Branch: `fix/keyring-auto-unlock-prompts`
Integration target: `main`
Base: `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`

## Operator intent

The workstation repeatedly asks for a GNOME keyring password even though the desktop session is intended to unlock the persistent keyring automatically when the container starts. Make the normal workstation path non-interactive without losing the persistent CE/login secret store.

The operator also questioned whether a separate keyring password is needed at all. This issue does **not** remove the password/secret: accepted D14 remains in force. The password protects the persistent login keyring at rest; the defect is that additional sessions can bypass the already-unlocked desktop Secret Service and ask again.

## Baseline evidence

- `compose.yaml` on `main` requires a `keyring_password` secret backed by the Unraid appdata secret file.
- `rootfs/etc/cont-init.d/10-workstation-init` stages that secret to `/run/workstation/keyring-password` for user `codex`.
- `scripts/container/desktop-session-inner.sh` emulates PAM login by piping the password to `gnome-keyring-daemon --login --components=secrets`, then calls `--start`.
- Accepted D8 persists the full user home.
- Accepted D14 requires keyring passwords to be supplied from Unraid-side secret files.

## Live diagnostic evidence — Tower, 2026-09-20

Read-only runtime inspection of the running `chatgpt-ce-workstation` container showed:

- the intended `codex` daemon is running as `gnome-keyring-daemon --login --components=secrets` from desktop-session startup;
- the Secret Service exposes `session` and `login` collections and both reported `Locked=false`, proving the primary auto-unlock path is succeeding;
- `login.keyring` had been modified after container startup, consistent with later keyring interaction;
- three additional `gnome-keyring-daemon --start --foreground --components=secrets` processes existed with effective user `root`;
- each extra daemon was paired with a separate private D-Bus session;
- those root processes inherited `HOME=/home/codex`, `USER=codex`, `LOGNAME=codex`, and `DISPLAY=:1`, while their D-Bus addresses differed from the canonical desktop session.

No live restart, prompt interaction, keyring mutation, or secret content read was performed.

## Root cause

The image exports codex desktop identity globally. A root-context process can therefore retain `HOME=/home/codex` and `DISPLAY=:1` while lacking the desktop session's `DBUS_SESSION_BUS_ADDRESS`. When such a process touches a D-Bus/Secret-Service client, D-Bus autolaunch may create a new private session; that private session can then autostart another `gnome-keyring-daemon` against the persistent codex home instead of using the already-unlocked desktop keyring.

This exact pattern was observed live: multiple root-owned private D-Bus + keyring pairs existed while the canonical codex login collection was already unlocked.

Supporting upstream behavior:
- GNOME keyring documents `--login` as the PAM-style password handoff and `--start` as completing that same daemon/session: https://manpages.debian.org/unstable/gnome-keyring/gnome-keyring-daemon.1.en.html
- D-Bus documents that a client without `DBUS_SESSION_BUS_ADDRESS` may autolaunch a new session bus and thereby end up in a separate session: https://dbus.freedesktop.org/doc/dbus-launch.1.html

## Existing workstream / dependency discovery

- No branch matching `keyring`, `login`, `auth`, or `desktop` was found.
- The only open PR discovered was PR #7, `feat: smart upstream updates`.
- The keyring startup behavior and defect surface already exist on `main`; reproduction/diagnosis does not require PR #7 or another unmerged workstream.

Classification: **independent**.
Parent workstream: none.
Parent branch: none.
Parent dependency: none.

## Micro-fix qualification

- **Root cause and intended behavior are concrete:** canonical keyring unlock works; secondary root-context D-Bus/keyring sessions are the defect. Root-context commands must not autolaunch a user-facing Secret Service against the codex persistent home/display.
- **Bounded and low strategic risk:** fix only environment/session isolation for privileged/root execution paths; do not alter CE authentication, persistent-home topology, or container privilege boundary.
- **No accepted requirement/architecture/product decision changes:** retain D8 persistent home and D14 Unraid-side keyring password.
- **Acceptance is direct:** after the fix, the canonical codex login collection remains unlocked after startup and root-context non-desktop commands cannot create a second user-facing keyring session against `/home/codex`.
- **No substantial migration/deployment strategy:** normal image rebuild/recreate is sufficient; existing keyring data/password remain valid.

Path: `micro_fix`
Next route: `execution_prep:micro_fix`

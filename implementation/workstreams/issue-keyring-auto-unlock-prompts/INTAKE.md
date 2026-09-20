# Issue Intake — keyring auto-unlock prompts

Workstream ID: `issue-keyring-auto-unlock-prompts`
Kind: `issue`
Branch: `fix/keyring-auto-unlock-prompts`
Integration target: `main`
Base: `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`

## Operator intent

The workstation repeatedly asks for a GNOME keyring password even though the desktop session is intended to unlock the persistent keyring automatically when the container starts. Make the normal workstation path non-interactive without losing the persistent CE/login secret store.

The operator explicitly decided on 2026-09-20 that the workstation should keep GNOME Keyring / Secret Service but use a passwordless login keyring. Decision D26 supersedes only D14's requirement for an Unraid-side keyring password. The secondary-session defect remains in scope independently.

## Baseline evidence

- `compose.yaml` on `main` requires a `keyring_password` secret backed by the Unraid appdata secret file.
- `rootfs/etc/cont-init.d/10-workstation-init` stages that secret to `/run/workstation/keyring-password` for user `codex`.
- `scripts/container/desktop-session-inner.sh` emulates PAM login by piping the password to `gnome-keyring-daemon --login --components=secrets`, then calls `--start`.
- Accepted D8 persists the full user home.
- D26 now requires a passwordless persistent login keyring, in-place migration of existing encrypted state without deleting items or forcing a fresh CE login, and retention of one canonical desktop Secret Service session.

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

- **Root cause and intended behavior are concrete:** the canonical desktop Secret Service must remain the only user-facing keyring session; its persistent login keyring must become passwordless under D26.
- **Bounded change:** preserve D8 persistent home, CE authentication data and Docker isolation; change only keyring master-password lifecycle, one-time migration and D-Bus session isolation.
- **Accepted authority is explicit:** D26 records the operator's security trade-off and supersedes only the keyring-password clause of D14.
- **Acceptance is direct:** existing keyring items survive an in-place migration to an empty master password; fresh installations never ask for a keyring password; the canonical login collection is available without unlock prompts; non-desktop/root processes cannot autolaunch a competing Secret Service.
- **Migration is bounded:** one versioned, fail-closed migration with backup/recovery evidence is sufficient; no schema or project-data migration is involved.

Path: `micro_fix`
Next route: `execution_prep:micro_fix`

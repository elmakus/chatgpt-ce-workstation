# Issue Intake — keyring auto-unlock prompts

Workstream ID: `issue-keyring-auto-unlock-prompts`
Kind: `issue`
Branch: `fix/keyring-auto-unlock-prompts`
Integration target: `main`
Base: `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`

## Operator intent

The workstation repeatedly asks for a GNOME keyring password even though the desktop session is intended to unlock the persistent keyring automatically when the container starts. Determine why prompts still appear and make the normal workstation path non-interactive without losing the persistent CE/login secret store.

The operator also questioned whether a separate keyring password is needed at all. Any removal of the password/secret itself must be reconciled against accepted security decision D14 rather than silently changing architecture.

## Baseline evidence

- `compose.yaml` on `main` requires a `keyring_password` secret backed by the Unraid appdata secret file.
- `rootfs/etc/cont-init.d/10-workstation-init` stages that secret to `/run/workstation/keyring-password` for user `codex`.
- `scripts/container/desktop-session-inner.sh` explicitly emulates PAM login by piping the password to `gnome-keyring-daemon --login --components=secrets`, then calls `--start`.
- Accepted D14 currently requires keyring passwords to be supplied from Unraid-side secret files.

## Live diagnostic evidence — Tower, 2026-09-20

Read-only runtime inspection of the running `chatgpt-ce-workstation` container showed:

- the intended `codex` daemon is running as `gnome-keyring-daemon --login --components=secrets` from desktop-session startup;
- the Secret Service exposes `session` and `login` collections and both reported `Locked=false`, proving the primary auto-unlock path is currently succeeding;
- `login.keyring` had been modified after container startup, consistent with later keyring interaction;
- three additional `gnome-keyring-daemon --start --foreground --components=secrets` processes existed with effective user `root`;
- each extra daemon was paired with a separate private D-Bus session;
- those root processes inherited `HOME=/home/codex`, `USER=codex`, `LOGNAME=codex`, and `DISPLAY=:1`, so privileged processes can address the persistent codex home/display while being outside the already-unlocked codex Secret Service session.

This narrows the defect: the normal codex login collection is already unlocked, so repeated GUI prompts are not explained by failure of the primary boot-time unlock. The leading failure mode is creation of secondary Secret Service/keyring sessions by root-context processes that inherit codex desktop identity but do not inherit/use the canonical desktop D-Bus session.

No live restart, prompt interaction, keyring mutation, or secret content read was performed.

## Existing workstream / dependency discovery

- No branch matching `keyring`, `login`, `auth`, or `desktop` was found.
- The only open PR discovered was PR #7, `feat: smart upstream updates`.
- The keyring startup behavior and defect surface already exist on `main`; reproduction/diagnosis does not require PR #7 or another unmerged workstream.

Classification: **independent**.
Parent workstream: none.
Parent branch: none.
Parent dependency: none.

## Intake state

Diagnosis is sufficient to isolate the problem and likely mechanism, but not yet sufficient to choose a bounded implementation safely. The next step must determine which privileged/root launch path is spawning secondary D-Bus/keyring sessions and whether the fix can remain inside accepted D8/D14 architecture.

Path: pending classification
Next route: pending

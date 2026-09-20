# MF-T01 implementation evidence — keyring session isolation

Date: 2026-09-20
Workstream: `issue-keyring-auto-unlock-prompts`
Card: `MF-T01`
Implementation subject: `elmakus/chatgpt-ce-workstation@04a9c200f315cc0f3d99f8793d83a9a31f86caba`
Base: `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`

## Implemented behavior

- The container image now exports `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/workstation/no-session-bus` as a fail-closed default for processes outside the supervised desktop session.
- The existing `dbus-run-session -- /opt/workstation/bin/desktop-session-inner.sh` path remains the canonical desktop override.
- Existing GNOME keyring `--login` password handoff, `--start` completion, persistent home and Compose keyring secret wiring are unchanged.
- Source validation now locks these invariants.
- Runtime verification now checks the non-desktop default, verifies that the desktop owns a different live D-Bus with `org.freedesktop.secrets`, and fails if a root-owned secondary `gnome-keyring-daemon` exists.

## Baseline/runtime diagnosis

Read-only inspection of the pre-fix running workstation showed:

- the canonical codex Secret Service `login` and `session` collections were both unlocked;
- the codex desktop/keyring shared one D-Bus session;
- three additional root-owned `gnome-keyring-daemon --start --foreground --components=secrets` processes existed;
- each root keyring had a separate private D-Bus session while inheriting `HOME=/home/codex`, `USER=codex`, `LOGNAME=codex` and `DISPLAY=:1`.

No keyring secret contents were read and no keyring data was modified.

## Verification

GREEN on the exact implementation subject:

- `bash -n scripts/validate-source.sh scripts/verify-runtime.sh`
- `bash scripts/validate-source.sh` → `SOURCE_VALIDATION_GREEN`; existing managed-AGENTS, upstream-resolution, updater, marketplace-updater, Compose, canonical-path, isolation, desktop and secret-hygiene checks all passed.
- D-Bus behavior probe on the existing runtime proved that an explicit nonexistent session-bus address makes a direct session client fail closed, while `dbus-run-session` replaces it with a new real session-bus address.
- The corrected runtime-readback probe successfully extracted the current desktop bus and confirmed `org.freedesktop.secrets` is owned on it.
- The same probe detected the three known root-owned keyring daemons on the old image, demonstrating that the new runtime verifier catches the observed regression.

## Deployment boundary

No production image build, container recreate/restart, keyring reset, credential change or live deployment was performed. Exact post-fix runtime verification therefore remains a deployment/readback obligation after review/integration, not part of this source-implementation Card.

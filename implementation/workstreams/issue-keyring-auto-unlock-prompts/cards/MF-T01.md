# MF-T01 — Prevent secondary keyring sessions outside the desktop bus

- Milestone: `micro-fix`

> This file is a stable Task Card contract. Mutable execution/review/result state lives only in the selected canonical Task Board.

## Authority slice

- Master Plan / milestone contract: `none — qualified micro-fix under R6 + implementation/workstreams/issue-keyring-auto-unlock-prompts/INTAKE.md`
- Requirements: `implementation/workstreams/issue-keyring-auto-unlock-prompts/INTAKE.md`
- Accepted decisions: `docs/DECISIONS.md#D8`, `docs/DECISIONS.md#D14`
- Relevant OpenSpec: `none`
- Accepted dependency results: `none`

### Must preserve

- Keep the persistent full `/home/codex` home and existing login-keyring data.
- Keep the Unraid-side keyring password secret and automatic desktop-session unlock.
- Keep one canonical desktop D-Bus session created by `dbus-run-session` for Openbox, CE, Codex Web GPT and GNOME Secret Service.
- Keep the container unprivileged; do not add host mounts, Docker socket access or broader capabilities.
- Non-desktop/root execution must fail closed instead of autolaunching a second session bus/keyring against the persistent codex home.

### Must not / rationale that must travel

- Do not remove encryption from the login keyring or replace it with an unencrypted keyring.
- Do not remove `keyring_password` from Compose/init provisioning.
- Do not reset/delete/recreate the user's existing keyring or CE authentication state.
- Do not restart/recreate the live workstation as part of source implementation without a separate deployment authorization.

## Dependencies

- `none`

## Outcome

Processes outside the canonical desktop session cannot implicitly autolaunch a secondary D-Bus/Secret-Service/keyring session, while the normal desktop session continues to override the fail-closed default with its own working D-Bus and automatically unlocked login keyring.

## Scope

### Included

- Add an explicit fail-closed default session-bus address for image-wide/non-desktop process context.
- Preserve `dbus-run-session` as the canonical desktop override.
- Add deterministic source validation for the isolation contract.
- Extend runtime verification so a deployed candidate can prove the root/non-desktop default is fail-closed and the codex desktop owns a distinct real session bus.

### Excluded

- Removing/changing the keyring password.
- Migrating or rewriting existing keyring contents.
- Changing CE login behavior or Remote Control credentials.
- Changing noVNC authentication.
- Production container rebuild/recreate/deployment.

## Acceptance

1. Image-wide environment has an explicit non-autolaunch session-bus address for processes outside the desktop session.
2. `dbus-run-session` still creates and exports a distinct real session bus to the desktop subtree.
3. A non-desktop process using the image default cannot silently autolaunch a private session bus/Secret Service.
4. Existing keyring secret wiring and D8/D14 persistence/security behavior remain intact.
5. Source validation covers the new isolation contract.
6. Runtime verification can prove the deployed desktop bus differs from the fail-closed default and remains usable by the codex desktop.
7. No production restart/recreate is performed by this Card.

## Required tests / checks

- `bash -n` for modified shell scripts.
- `bash scripts/validate-source.sh`.
- Deterministic D-Bus behavior check proving `dbus-run-session` overrides the fail-closed parent address.
- Static verification that Compose still wires `keyring_password` and desktop startup still performs `gnome-keyring-daemon --login` followed by `--start`.
- Review diff for unintended credential/keyring-data changes.

## External write/readback needs

Repository branch writes only. Live workstation rebuild/recreate is excluded and remains a separate deployment/readback gate.

## Independent review

`RECOMMENDED` — this changes runtime session/environment behavior used by authentication/keyring infrastructure, so the exact implementation subject should receive fresh independent review before integration.

## Contract overrides

None.

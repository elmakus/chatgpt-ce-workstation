# MF-T02 — Migrate workstation login keyring to passwordless operation

- Milestone: `micro-fix`

> Stable Task Card contract. Mutable execution/review/result state lives only in the selected workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `none — qualified micro-fix under R6 + implementation/workstreams/issue-keyring-auto-unlock-prompts/INTAKE.md`
- Requirements: `implementation/workstreams/issue-keyring-auto-unlock-prompts/INTAKE.md`
- Accepted decisions: `docs/DECISIONS.md#D8`, `docs/DECISIONS.md#D14`, `docs/DECISIONS.md#D26`
- Relevant OpenSpec: `none`
- Accepted dependency results: `MF-T01 superseded diagnostic/session-isolation evidence only`

### Must preserve

- Persistent `/home/codex` and all existing CE/keyring items.
- One canonical desktop D-Bus / GNOME Secret Service session.
- Fail-closed behavior for non-desktop/root D-Bus clients.
- Docker/Unraid isolation and no-secrets-in-Git constraints.
- Existing noVNC password behavior.

### Must not / rationale that must travel

- Do not delete/reset the real login keyring as a migration technique.
- Do not require a new CE login.
- Do not leave fresh installations requiring the operator to choose a keyring password.
- Do not silently continue if an existing encrypted keyring cannot be migrated safely.
- Do not make production keyring mutation before the exact implementation has passed independent review.

## Dependencies

- `none`

## Outcome

The workstation uses GNOME Secret Service with a persistent login keyring whose master password is empty. Existing encrypted installations migrate in place with backup/recovery semantics; fresh installations initialize passwordless without prompting. Secondary D-Bus/keyring sessions remain blocked.

## Scope

### Included

- Versioned keyring migration helper using one D-Bus connection for Secret Service session + master-password change.
- One-time backup/marker and fail-closed migration semantics.
- Passwordless fresh-install initialization.
- Removal of runtime dependence on the keyring password after successful migration.
- Host provisioning/update cleanup so a fresh installation does not prompt for a keyring password.
- Source/runtime tests and rollback-safe migration verification.

### Excluded

- noVNC password changes.
- CE credential reset or account relogin.
- Production deployment/migration before independent review.
- Unrelated Muse/MCP policy changes.

## Acceptance

1. Existing encrypted `login.keyring` can be changed to an empty master password without deleting stored items.
2. A pre-migration backup exists before the first real keyring mutation and is sufficient for rollback.
3. Migration is idempotent and records a durable versioned completion marker only after success.
4. Fresh home initialization creates/ensures a passwordless login collection without operator password input.
5. Normal desktop startup no longer performs password-based `gnome-keyring-daemon --login`.
6. After migration, runtime does not require a non-empty keyring password.
7. The existing D-Bus fail-closed isolation remains enforced.
8. Source validation and deterministic helper tests are GREEN.
9. Production mutation remains deferred until independent review is GREEN.

## Required tests / checks

- Syntax/compile checks for modified scripts/helper.
- Isolated temporary-HOME integration test covering encrypted-keyring -> passwordless migration and fresh passwordless initialization.
- Verify stored test item remains readable after daemon restart with no password input.
- Verify migration retry/idempotency and marker behavior.
- Full `bash scripts/validate-source.sh`.
- Static Compose/init/update checks ensuring fresh installation does not prompt for a GNOME keyring password.
- Runtime verifier contract for canonical Secret Service and absence of root-owned secondary keyring daemons.

## External write/readback needs

Repository writes only during this Card. Real persistent keyring mutation and workstation recreate are explicitly deferred until independent review.

## Independent review

`REQUIRED` — this changes authentication-secret storage and performs an in-place keyring migration.

## Contract overrides

None.

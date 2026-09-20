# MF-T01 — Repair live keyring migration and rollback verifier compatibility

- Milestone: `micro-fix`

> Stable Task Card contract. Mutable execution/review/result state lives only in the selected workstream Task Board.

## Authority slice

- Master Plan / milestone contract: `none — qualified micro-fix under implementation/workstreams/issue-keyring-live-migration-rollback/INTAKE.md and Research R1`
- Requirements: `requirements/SMART_UPSTREAM_UPDATES.md#R11`, `requirements/SMART_UPSTREAM_UPDATES.md#R12`, issue #12 acceptance
- Accepted decisions: `docs/DECISIONS.md#D8`, `docs/DECISIONS.md#D14`, `docs/DECISIONS.md#D26`
- Research evidence: `implementation/workstreams/issue-keyring-live-migration-rollback/research/R1.md`
- Prior implementation evidence: `implementation/workstreams/issue-keyring-auto-unlock-prompts/evidence/MF_T02_PASSWORDLESS_KEYRING_2026-09-20.md`

### Must preserve

- Persistent `/home/codex`, CE authentication state and every existing keyring collection/item.
- The stranded legacy `login.keyring` bytes/items and the additional failed-v1 collection containing `Chromium Safe Storage`; do not delete either as a repair shortcut.
- One canonical desktop D-Bus / GNOME Secret Service session and fail-closed non-desktop/root behavior.
- Existing Docker/Unraid isolation and project/home bind invariants.
- Deterministic exact-image rollback under smart-updater R11.
- Strict current `scripts/verify-runtime.sh` candidate verification.

### Must not / rationale that must travel

- Do not reset/delete the live keyring, force CE relogin, or log/read secret values as evidence.
- Do not treat transient `Locked=false` as proof that a persistent collection has an empty master password.
- Do not let stale v1 completion state suppress the corrective migration.
- Do not apply current candidate-only runtime invariants to an older retained rollback image.
- Do not weaken candidate verification merely to make rollback pass.
- Do not absorb issue #11 image/cache-retention cleanup.
- Do not rerun/promote on Tower before exact source review is GREEN and the operator explicitly authorizes the live retry.

## Outcome

The corrective v2 migration backs up the whole keyring state before repair, makes the legacy login keyring accessible to the canonical codex Secret Service, changes the canonical login keyring to an empty master password while preserving items, converges `login` and `default` aliases, and never marks success from a replacement collection alone. Failed promotion restores pre-attempt keyring state and verifies an older exact rollback image with a version-stable baseline verifier while keeping strict candidate verification unchanged.

## Included scope

- Root init migration backup/ownership repair before desktop startup.
- Versioned v2 marker/backup/staged-credential plumbing.
- Login-first helper selection, explicit old->empty migration semantics and login/default alias convergence.
- Preservation of additional collections produced by the failed v1 attempt.
- Rollback marker cleanup + keyring restore semantics.
- Backward-compatible rollback-baseline runtime verifier and updater wiring.
- Deterministic helper/update/source-validation regression tests.
- Post-review, explicitly authorized Tower retry/readback.

## Excluded scope

- Any keyring/CE credential reset or item deletion.
- Image/build-cache retention (#11).
- Broader Compose/network/noVNC changes.
- Any new product/security decision replacing D26.

## Acceptance

1. When v2 is pending and a persistent keyring directory exists, a root-readable backup of the whole directory is created before ownership/content mutation; an existing backup is never overwritten.
2. Root-owned/mode-0600 legacy keyring files are repaired to the codex UID/GID only after backup, so the canonical desktop Secret Service can load them.
3. The helper prefers the canonical `login` alias, uses the retained legacy credential to perform explicit old->empty migration even if the collection is transiently unlocked, and sets both `login` and `default` aliases to the migrated collection.
4. Fresh/no-existing-keyring initialization remains passwordless without operator input and sets both aliases. Additional pre-existing collections/files are preserved rather than deleted.
5. Only a successful v2 migration writes `keyring-passwordless-v2`; stale v1 state does not suppress v2. Runtime verification requires v2, alias convergence, unlocked canonical collection and codex-owned active keyring files.
6. Rollback clears candidate-era v1/v2 completion markers regardless of backup existence; when the v2 backup exists it restores the exact pre-attempt keyring directory before the previous image is recreated.
7. Rollback verification checks exact expected image identity plus version-stable running/health/mount/isolation invariants and succeeds for the accepted pre-D26 image; promoted candidates still pass the full strict current runtime verifier.
8. Regression tests cover root-owned/unreadable legacy keyring preparation, login-vs-default selection, transient-unlocked encrypted migration, both aliases, stale-marker/no-backup rollback, backup restore, and rollback verifier version skew.
9. Full source validation/CI are GREEN on the exact frozen subject.
10. A live Tower retry occurs only after REQUIRED independent review GREEN + explicit user authorization and must reach `WORKSTATION_RUNTIME_GREEN` before legacy credential/backup cleanup is accepted.

## External write/readback needs

Repository writes and CI are authorized for implementation. Production container/keyring mutation is a later explicit gate after independent review. Live evidence must avoid secret values and may use item counts/labels only where needed to prove preservation.

## Independent review

`REQUIRED` — this repairs an in-place authentication-secret migration and rollback/recovery behavior after a production failure.

## Contract overrides

None.

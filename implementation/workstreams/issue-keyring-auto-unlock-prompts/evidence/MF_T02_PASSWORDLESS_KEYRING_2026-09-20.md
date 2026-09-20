# MF-T02 implementation evidence — passwordless GNOME keyring

Date: 2026-09-20
Workstream: `issue-keyring-auto-unlock-prompts`
Card: `MF-T02`
Implementation subject: `elmakus/chatgpt-ce-workstation@1addd26a736b1bd64126b1b14daadddf75a2b867`

## Result

The workstation source now implements D26:

- GNOME Secret Service remains enabled on the single canonical desktop D-Bus.
- Desktop startup no longer uses password-based `gnome-keyring-daemon --login`.
- `scripts/container/keyring-passwordless.py` uses one dbus-python connection to open the Secret Service session and either:
  - create a fresh persistent passwordless collection and set it as default;
  - verify an existing passwordless collection; or
  - unlock an existing encrypted collection with the legacy migration credential, back up its keyring files, and change its master password to empty.
- The versioned `keyring-passwordless-v1` marker is written only after the default collection is unlocked.
- The legacy credential is staged only while the marker is absent and is removed from `/run/workstation` after successful desktop initialization.
- Fresh `scripts/init-unraid.sh` no longer prompts for a GNOME keyring password; the historical Compose secret path is an empty placeholder / one-time upgrade channel.
- Updater rollback restores `keyrings.pre-passwordless-v1` before starting the previous image.
- Successful updater completion truncates the legacy host credential and removes the migration backup.
- The fail-closed non-desktop D-Bus default from the superseded MF-T01 direction is retained.

## Source verification

Exact branch source passed:

- `bash scripts/validate-source.sh` → `SOURCE_VALIDATION_GREEN`
- shell syntax GREEN for all tracked shell scripts;
- `keyring-passwordless.py` Python compile GREEN;
- managed global AGENTS fixtures GREEN;
- upstream resolver/render fixtures GREEN;
- update orchestration fixtures GREEN, including the new keyring restore/finalize hooks;
- marketplace updater fixtures GREEN;
- Compose/canonical-path/container-boundary checks GREEN;
- passwordless-keyring + desktop-session isolation static contract GREEN;
- existing CE/Muse/desktop/secret-hygiene checks GREEN.

## Independent-review correction

The first frozen subject `7be2eeb9cb39f7e84b01d5e30822dfa42784d34f` received RED because two shell wrappers contained literal `\\n` text between keyring variable assignments. Bash syntax validation accepted that form, but it joined assignments and left later variables unset under `set -u`.

Correction on the current subject:

- restored real line breaks in `rootfs/etc/cont-init.d/10-workstation-init`;
- restored real line breaks in `scripts/container/desktop-session-inner.sh`;
- added exact-line regression assertions to `scripts/validate-source.sh` so this malformed-assignment class is rejected deterministically;
- GitHub CI run `35501459367` completed GREEN on the corrected subject, including `Validate workstation source`, noVNC desktop workarea semantics, ShellCheck, Dockerfile checks, and repository secret scan.

The correction does not change the keyring migration helper or the previously verified temporary-HOME migration behavior.

## Isolated keyring integration verification

Performed only against temporary homes under `/tmp`; the real `/home/codex/.local/share/keyrings` was not modified.

### Existing encrypted keyring

1. Created a temporary login keyring protected by synthetic password `probe-old-password`.
2. Stored synthetic secret `retained-secret`.
3. Restarted in a fresh D-Bus session.
4. Ran the repository helper with the synthetic legacy password.
5. Verified the versioned marker and pre-migration backup were created.
6. Verified the secret remained readable.
7. Restarted the daemon again with no password input and no migration password passed to the helper.
8. Verified the same secret remained readable.

Result: GREEN.

### Fresh passwordless home

1. Started with an empty temporary HOME.
2. Ran the repository helper without any password.
3. Stored synthetic secret `fresh-secret`.
4. Restarted the daemon in a fresh D-Bus session with no password input.
5. Ran the helper idempotently again and read the same secret.

Result: `KEYRING_PASSWORDLESS_INTEGRATION_GREEN`.

## Refresh Gate

Current `main` advanced after the workstream base, but the target-side changes since the merge base are limited to unrelated completed workstream state/evidence. No current-source overlap was found with the keyring implementation files. Final integration refresh remains a Close responsibility after Card review.

## Deployment boundary

No real keyring master password was changed. No production container was rebuilt/recreated/restarted for this implementation. The current running workstation still has the pre-change keyring state; production migration is intentionally deferred until the REQUIRED independent review is GREEN.

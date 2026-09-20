# MF-T02 independent review — RED

Date: 2026-09-20
Workstream: `issue-keyring-auto-unlock-prompts`
Card: `MF-T02`
Reviewed subject: `elmakus/chatgpt-ce-workstation@7be2eeb9cb39f7e84b01d5e30822dfa42784d34f`
Verdict: `RED`

## Blocking finding

The immutable subject contains literal backslash-n text between keyring variable assignments in both:

- `rootfs/etc/cont-init.d/10-workstation-init`
- `scripts/container/desktop-session-inner.sh`

For example, the init script contains the equivalent of:

`runtime_keyring_secret=".../keyring-migration-password"\nkeyring_marker=".../keyring-passwordless-v1"`

This is not a shell newline. Bash accepts the syntax, so `bash -n` is GREEN, but the escaped `n` joins the text into the preceding assignment. As a result, `keyring_marker` is never assigned. Under `set -u`, the first later reference to `$keyring_marker` aborts the script. The desktop-session script has the same defect for `keyring_marker` and `keyring_backup`.

A local shell reproduction using the exact assignment form produced a corrupted `runtime_keyring_secret` value ending in `nkeyring_marker=...` and then `keyring_marker: unbound variable`.

## Acceptance impact

This blocks the implemented startup/migration path before it can satisfy MF-T02 acceptance for existing or fresh installations. It also explains why shell syntax checks alone did not detect the defect. The isolated helper test does not exercise these malformed wrapper assignments.

## Authority classification

The defect is a bounded implementation error inside the accepted MF-T02/D26 contract. No requirement, decision, or plan change is needed. Corrective route: Execution on the existing Card, followed by a new immutable REQUIRED review subject.

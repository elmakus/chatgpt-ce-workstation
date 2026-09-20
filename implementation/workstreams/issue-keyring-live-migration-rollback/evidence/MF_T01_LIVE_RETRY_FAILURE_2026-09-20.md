# MF-T01 authorized Tower live retry — candidate failed, rollback GREEN

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Reviewed source subject: `8191cbbebe120b842f77b767979ee4f2202ed636`
Authorization: explicit operator authorization in the active ChatGPT session before the retry.

## Pre-retry state

The Tower production workstation was on exact prior image:

`sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`

Readback before the updater:
- container running: true;
- health: healthy;
- v1 marker: absent;
- v2 marker: absent;
- v2 rollback backup: absent;
- retained legacy migration credential: present/non-empty (value not read or recorded).

## Exact candidate

The authorized `scripts/update.sh` run was executed from detached exact reviewed source `8191cbbebe120b842f77b767979ee4f2202ed636`.

Frozen resolution SHA-256:

`4c925a768263b1d0bf3988e2c99b84095d27156270d63448e722add3a541c540`

Built candidate:
- ref: `chatgpt-ce-workstation:candidate-4c925a768263b1d0`;
- image ID: `sha256:6c418579302e083edc0e04940b5609070bbc81d4fe6aacdd7b83fc6ee1f329d1`.

Source validation, host preflight, exact candidate build and candidate promotion reached GREEN/healthy container state before strict runtime verification.

## Live failure

Strict current `scripts/verify-runtime.sh` failed at the D26 keyring check:

`FAIL: canonical login Secret Service collection is locked`

Updater reason:

`candidate_runtime_verification_failed`

The candidate was therefore not accepted as production success and legacy migration credential/backup cleanup was not accepted.

## Rollback result

The corrected rollback path restored the exact pre-attempt keyring snapshot before recreating the retained prior image.

Rollback verification returned:

`ROLLBACK_RUNTIME_GREEN image=sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`

Updater durable evidence recorded:

`status=update_failed_rolled_back`

Post-rollback readback:
- exact prior image restored;
- running: true;
- health: healthy;
- v1 marker: absent;
- v2 marker: absent;
- v2 backup: absent after restore consumed it;
- retained legacy migration credential remains non-empty and unchanged in purpose;
- persistent keyring directory is present.

No secret value was read or recorded.

## Corrective classification

The live failure plus exact source ordering expose a bounded readiness race inside MF-T01 authority.

`desktop-session-inner.sh` starts Openbox/x11vnc/websockify before starting GNOME Secret Service and running `keyring-passwordless.py`. The current `workstation-healthcheck` checks only the earlier desktop/VNC substrate. Consequently Docker can report `healthy` while the per-session keyring migration/unlock helper is still incomplete, allowing `update.sh -> wait_healthy -> verify-runtime.sh` to observe the canonical collection in a transient locked state.

The correction is bounded L1/L2 execution work. It must add an ephemeral per-session keyring-readiness condition that is cleared at each desktop-session start, published only after the helper succeeds, and required by health/readiness before updater runtime verification. Persistent v2 marker alone is insufficient because every later desktop-session restart must again prove the session-local keyring helper completed.

No D26, R11/R12, Definition, or strategic plan change is required.

A second production retry is not authorized by the completed retry authorization; after correction and REQUIRED fresh independent review, a new explicit live-retry authorization is required.

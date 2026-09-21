# MF-T01 corrective implementation evidence — per-session keyring readiness

Date: 2026-09-20
Workstream: `issue-keyring-live-migration-rollback`
Card: `MF-T01`
Origin live evidence: `implementation/workstreams/issue-keyring-live-migration-rollback/evidence/MF_T01_LIVE_RETRY_FAILURE_2026-09-20.md`
Prior independently GREEN subject: `8191cbbebe120b842f77b767979ee4f2202ed636`
Corrected implementation subject: `789fc358139a73a8bed8aaa38813157853df8b75`
PR: #13

## Live finding

The explicitly authorized Tower retry of the prior GREEN subject built and promoted exact candidate `sha256:6c418579302e083edc0e04940b5609070bbc81d4fe6aacdd7b83fc6ee1f329d1`, but strict runtime verification failed because the canonical login Secret Service collection was locked.

The corrected rollback path then restored and verified the exact prior image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852` with `ROLLBACK_RUNTIME_GREEN`. Post-rollback readback proved the old image running/healthy, v1/v2 markers absent, rollback backup consumed by successful restore, and the retained legacy migration credential still present without reading its value.

## Root cause

The live failure exposed a startup-readiness race that the prior production-derived migration harness did not model.

`scripts/container/desktop-session-inner.sh` starts Openbox, x11vnc and websockify before it starts GNOME Secret Service and runs `keyring-passwordless.py`.

The prior `rootfs/usr/local/bin/workstation-healthcheck` checked only those earlier desktop/VNC substrate processes. Therefore Docker could report the candidate `healthy` while the session-local keyring helper was still migrating/unlocking the canonical collection. `scripts/update.sh` then legally advanced from `wait_healthy` to strict `verify-runtime.sh`, which could observe the canonical login collection during that transient locked interval.

This is a bounded implementation/readiness defect inside the existing MF-T01 / D26 / R11-R12 authority. It does not require weakening strict runtime verification or changing accepted product/security intent.

## Correction

The corrected subject adds one ephemeral per-session readiness boundary:

- `desktop-session-inner.sh` binds `KEYRING_SESSION_READY` with default `/run/workstation/keyring-session-ready`;
- it removes that marker at the start of every desktop-service incarnation before the desktop substrate can make health checks otherwise look ready;
- it runs the existing Secret Service + passwordless helper normally;
- only after `keyring-passwordless.py` succeeds and the staged migration credential is removed does it publish the session readiness marker;
- the marker is mode 0600 and lives only under the container-local `/run/workstation`, so it is not persistent migration authority;
- `workstation-healthcheck` now requires the per-session readiness marker in addition to VNC/X11/Openbox/websockify health.

A persistent `keyring-passwordless-v2` marker is deliberately not used as the health readiness signal, because a later desktop-service restart still needs to prove that the new session completed its own keyring helper/unlock step.

## Regression coverage

New `scripts/test-keyring-session-readiness.sh` proves:

1. stale per-session readiness is cleared before desktop substrate startup;
2. the keyring helper occurs after substrate startup in the modeled ordering;
3. readiness is published only after helper success and before application launch;
4. with all other health dependencies stubbed GREEN, workstation health fails when session readiness is absent;
5. the same healthcheck passes after readiness is published.

Existing migration-preparation, keyring-helper and updater rollback regressions remain GREEN.

## Exact verification

Tower detached exact source `789fc358139a73a8bed8aaa38813157853df8b75`:

- `bash scripts/test-keyring-session-readiness.sh` -> `KEYRING_SESSION_READINESS_TESTS_GREEN`;
- `bash scripts/test-keyring-migration-prep.sh` -> `KEYRING_MIGRATION_PREP_TESTS_GREEN`;
- `python3 scripts/test-keyring-passwordless.py` -> 6/6 GREEN;
- `bash scripts/test-update-orchestration.sh` -> `UPDATE_ORCHESTRATION_TESTS_GREEN`;
- `bash scripts/validate-source.sh` -> `SOURCE_VALIDATION_GREEN`;
- `git diff --check` -> GREEN;
- `bash -n` on corrected/readiness scripts -> GREEN;
- `docker buildx build --check --file Dockerfile .` -> check complete, no warnings.

Hosted GitHub Actions run `35511110522` / CI #283 is associated with exact subject `789fc358139a73a8bed8aaa38813157853df8b75` and completed `success`.

All jobs were GREEN:
- `source-validation`, including full source validation, noVNC desktop workarea semantics and ShellCheck;
- `dockerfile-check`;
- `secret-scan`.

Temporary CI-only PR #17 was closed after the exact run completed. It had no integration intent.

## External-state boundary

No second production candidate promotion or keyring mutation was performed after this correction.

Because this chat implemented the corrected subject, REQUIRED independent review must be performed by a fresh normal ChatGPT chat before any further live retry.

The prior operator authorization covered the completed Tower retry that failed safely and rolled back. A subsequent production retry after this correction requires a new explicit operator authorization after the new exact subject receives independent GREEN review.

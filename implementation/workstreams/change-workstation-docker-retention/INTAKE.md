# Intake — workstation Docker retention

Workstream ID: `change-workstation-docker-retention`
Intake kind: `change`

## Authorized scope

Implement GitHub issue #11, “Bound workstation Docker image and build-cache retention”, in `elmakus/chatgpt-ce-workstation`.

The change must bound workstation-specific Docker image/tag retention and BuildKit/build-cache growth while preserving the existing exact-image rollback contract and useful identity-driven cache reuse.

## Baseline evidence

- Issue #11 defines the required safety and acceptance surface: cleanup only after successful promotion + health/runtime verification; retain current production plus exactly one immediately previous known-working rollback image; keep cache bounded and workstation-scoped; never use unscoped/global prune; cleanup failure must be reported distinctly from update success.
- Current `scripts/update.sh` creates `candidate-*` images and a `rollback-<image>` tag but contains no post-success image/cache retention stage.
- Current `scripts/test-update-orchestration.sh` covers promotion/verification/rollback failure paths but does not cover bounded retention across three sequential updates.
- The smart-upstream updater implementation required by this change is already present on `main`; no unmerged parent-only behavior is required.

## Workstream topology

Integration target: `main`
Exact base: `e796e2fef00e348e2329be1a4856da335dff6842`
Classification: independent
Parent workstream: none
Parent dependency: none

## Intake classification

Path: pending
Next route: pending

The change is larger than a micro-fix because it adds lifecycle policy for two distinct resource classes (images/tags and BuildKit cache), requires scoped cleanup semantics, new evidence reporting, and multi-cycle/failure-path acceptance coverage.

The smallest downstream route will be selected after establishing whether existing accepted requirements/decisions already define enough of the retention policy and whether Unraid's concrete Docker/BuildKit backend requires implementation-shaping research.

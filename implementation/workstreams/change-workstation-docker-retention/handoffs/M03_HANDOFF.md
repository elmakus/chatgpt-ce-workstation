# M03 handoff — Multi-cycle orchestration and retention evidence

Milestone: `M03`
Plan revision: `workstation-docker-retention-R1`
Status: **GREEN / done**
Implementation checkpoint: `e4b0570adc975b6cd18d9e1ccf49bc74cb0a4662`

## Achieved state

M03 independently verifies the integrated M01-M03 retention behavior before any live retention mutation:

- the real `scripts/update.sh` orchestration is exercised with deterministic external-operation fakes;
- at least three consecutive successful update cycles keep the Workstation lifecycle set bounded to the exact current candidate ref plus one immediate rollback ref;
- older candidate/rollback refs become removable only after the newer candidate has passed promoted-image, health and runtime verification;
- pre-promotion, promotion, promoted-image mismatch, health/runtime and rollback failure paths run zero retention cleanup;
- a failed candidate rolls back to the exact retained previous image and verifies it GREEN;
- image-cleanup and BuildKit-cache cleanup warnings occur only after verified production success and remain distinct from update/rollback failure;
- durable evidence reports current/rollback identities plus bounded image-cleanup and dedicated-builder cache-cleanup state;
- unrelated/non-lifecycle refs remain outside cleanup scope;
- identity-driven BuildKit reuse remains enabled and no global/default prune, global `buildx use`, or `--no-cache` path is introduced.

## Acceptance and evidence

- Card/evidence: `implementation/workstreams/change-workstation-docker-retention/evidence/M03-T01.md`
- Exact integrated reviewed subject: `e4b0570adc975b6cd18d9e1ccf49bc74cb0a4662`
- Independent Card review: **GREEN**
- Reviewer rerun on an isolated detached Tower worktree: `RETENTION_MULTICYCLE_TESTS_GREEN`, `BUILDKIT_CACHE_TESTS_GREEN`, `UPDATE_ORCHESTRATION_TESTS_GREEN`, `SOURCE_VALIDATION_GREEN`
- shell syntax, `git diff --check`, and forbidden global/default prune / `buildx use` / `--no-cache` scan GREEN
- no real builder creation, candidate build, cache prune, image/tag deletion, production recreate/restart, or live updater invocation occurred.

## Authority in force

- `planning/WORKSTATION_DOCKER_RETENTION_MASTER_PLAN.md#Milestone-M03--Multi-cycle-orchestration-and-retention-evidence`
- `requirements/SMART_UPSTREAM_UPDATES.md#R11`
- `requirements/SMART_UPSTREAM_UPDATES.md#R12`
- `requirements/SMART_UPSTREAM_UPDATES.md#R16` through `#R24`
- `docs/DECISIONS.md#D25`
- `docs/DECISIONS.md#D28`

## Next durable starting point

M04 is the approved live Unraid verification milestone. Before any action that creates/prunes the real Workstation builder/cache, builds or promotes a candidate, removes live image/tag artifacts, recreates production, or invokes the live updater, explicit user live-write/deployment authorization is required.

After authorization, run M04 preparation/execution from this M03 checkpoint and re-refresh against current `main` as required by the approved plan.

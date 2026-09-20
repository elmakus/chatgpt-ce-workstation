# Workstation Docker retention Master Plan

Status: **draft**
Plan revision: **workstation-docker-retention-R1**
Date: 2026-09-20
Independent plan review: **RECOMMENDED**

## Goal and authority

Extend the accepted Smart Upstream Updates lifecycle so normal successful updates do not accumulate unbounded workstation Docker images/tags or BuildKit cache while preserving deterministic rollback and useful identity-driven cache reuse.

Authority:
- `requirements/SMART_UPSTREAM_UPDATES.md`, especially R7-R8, R11-R12 and R17-R24;
- `docs/DECISIONS.md#D25`;
- `docs/DECISIONS.md#D27`;
- GitHub issue #11 as provenance for the authorized change.

The fixed target state is: after a verified successful update, retain the exact current production image and exactly one immediately previous known-working rollback image; clean only older workstation-owned image/tag artifacts; apply a separate bounded workstation-scoped BuildKit cache policy; never use global prune; never touch persistent user data; and report cleanup failure separately from production success.

## Verified baseline

Current `scripts/update.sh`:
- resolves/builds an exact candidate;
- captures the currently running known-working image;
- tags that prior image as `rollback-<short-image-id>`;
- promotes the candidate and requires health/runtime GREEN;
- rolls back to the exact prior image on post-promotion failure;
- writes bounded update evidence;
- has no post-success image/tag retention or BuildKit cache cleanup stage.

Current `scripts/test-update-orchestration.sh` covers pre-promotion, promotion, health/runtime and rollback failures, but does not model three sequential successful cycles or cleanup behavior.

The existing smart-updater source is already integrated on `main`, so this workstream is independent and requires no parent-only state.

## Execution strategy

Use four ordered checkpoints:

1. add a reference-safe workstation image-retention primitive and integrate it only after verified promotion;
2. establish and implement a bounded BuildKit cache policy against the actual target backend without introducing global prune semantics;
3. prove lifecycle ordering, cleanup-failure semantics and bounded retention across at least three sequential update cycles;
4. validate the accepted implementation on the real Unraid workstation only after explicit live-write authorization.

Image/tag retention and BuildKit cache retention remain separate mechanisms even if they are invoked from one post-success cleanup phase.

No cleanup implementation may weaken the existing exact-image rollback contract. If a candidate fails before final verification, cleanup must not run.

## Milestone M01 — Reference-safe image/tag retention

### Outcome

After a successful verified promotion, the updater can identify exactly which workstation image identities/references are protected and safely remove only older workstation-specific candidate/rollback artifacts.

### Requirement ownership

R11-R13, R17-R19, R21-R23.

### Planned work packages

- Define one post-success retention entrypoint invoked only after candidate health and runtime verification are GREEN.
- Protect by exact identity/reference:
  - the current verified production image used by the running/recreatable workstation;
  - the immediately previous known-working image retained as the sole rollback baseline.
- Discover workstation-owned historical `candidate-*` and `rollback-*` references without enumerating or pruning unrelated images.
- Remove stale workstation tags first and remove image objects only when Docker reference state makes that safe.
- Preserve any protected/current/rollback identity even when multiple workstation tags point to the same image.
- Ensure a live Docker reference outside the workstation retention set prevents unsafe image deletion.
- Keep all persistent bind-mounted data outside cleanup scope.
- Extend update evidence with protected current/rollback identities plus bounded image-cleanup result.
- Make image cleanup failure non-fatal after production verification while surfacing a distinct cleanup warning/result.
- Add deterministic unit/orchestration fakes for image inventory, tag removal, protected identities and deletion failures.

### Acceptance

- Cleanup is unreachable before successful health/runtime verification.
- Current production remains recreatable and its exact image remains available.
- Exactly one prior known-working workstation image is retained as rollback baseline.
- Older workstation candidate/rollback references become removable only after a later candidate is fully verified.
- No global/unscoped image/system prune command is used.
- Cleanup cannot delete unrelated project images or persistent data.
- Cleanup failure after production verification does not invoke rollback or report the verified update as failed.
- Evidence identifies protected current/rollback identities and image-cleanup status.

## Milestone M02 — Bounded workstation BuildKit cache retention

### Dependencies

M01 source contract available; no production mutation required.

### Outcome

The updater has a documented and implemented bounded BuildKit/build-cache policy that is demonstrably scoped to the workstation build path and preserves useful identity-driven reuse.

### Requirement ownership

R7-R8, R17, R20-R23.

### JIT technical verification

Before choosing the concrete prune/GC command, verify the target Unraid Docker/BuildKit backend non-destructively:

- active builder/backend/driver used by `docker compose build` / `scripts/build.sh`;
- available cache metadata/filters/labels or builder isolation that can prove workstation-only scope;
- supported age/size/keep-storage semantics;
- whether the workstation needs a dedicated named builder/cache namespace to make safe scoped GC possible;
- how cache required by unchanged-input repeated builds is preserved.

If the actual backend cannot provide a safe workstation-only scope with the current builder arrangement, do not fall back to `docker system prune` or global builder prune. Route through bounded Research/Planning correction and, if needed, introduce a dedicated workstation builder/cache namespace inside accepted authority.

### Planned work packages

- Select the smallest backend-supported workstation-scoped retention mechanism.
- Define bounded retention using supported age/size/keep-storage semantics or an equivalent scoped GC policy.
- Preserve shared/useful recent cache for normal no-change and partially changed builds.
- Keep cache cleanup distinct from image/tag cleanup in implementation and evidence.
- Make cache cleanup failure non-fatal after verified production success and distinguish it in update evidence/output.
- Add source assertions/tests that reject global prune semantics and prove the configured retention boundary is finite.
- Add cache-policy tests/fakes for success, unsupported backend, scoped cleanup failure and no-change cache preservation contract.

### Acceptance

- The concrete cache mechanism is proven compatible with the target backend.
- Scope cannot evict unrelated Unraid projects' cache by construction/verified filtering.
- Retention is bounded rather than indefinite.
- Useful identity-driven BuildKit reuse remains enabled.
- Unsupported/unsafe backend conditions fail the cleanup portion closed without turning a verified production update into a false update failure.
- Evidence identifies the applied cache policy/result at a bounded level.

## Milestone M03 — Multi-cycle orchestration and retention evidence

### Dependencies

M01-M02 implementation GREEN.

### Outcome

The integrated updater proves the full retention lifecycle across repeated updates, including success, failure and cleanup-warning paths.

### Requirement ownership

R11-R12, R16-R24.

### Planned work packages

- Extend the orchestration harness to model at least three sequential successful update cycles with changing candidate/current/rollback identities.
- Prove after cycle N that only the exact current production and one immediately previous rollback baseline remain protected by workstation retention.
- Prove cycle N+1 makes the older N-1 rollback/candidate artifacts eligible for cleanup only after N+1 verification is GREEN.
- Exercise pre-promotion, promotion, image-mismatch, health and runtime failures and assert no retention cleanup runs.
- Exercise rollback after failed candidate and assert the exact protected previous image is restored and verifies GREEN.
- Exercise image-cleanup and cache-cleanup failures after verified production success and assert:
  - production remains successful/healthy;
  - rollback is not spuriously invoked;
  - evidence records cleanup status separately.
- Assert no global prune command appears in source/orchestration paths.
- Serialize/read back the expanded durable evidence contract.
- Run the existing smart-updater source/orchestration regression suite to detect rollback/cache semantic regressions.

### Acceptance

- At least three sequential successful cycles do not produce unbounded workstation candidate/rollback retention.
- Failure-path tests prove rollback baseline preservation before verification.
- Cleanup-warning behavior is distinct from update failure.
- Evidence reports current, rollback, image cleanup and cache cleanup state without secrets.
- Existing updater source/orchestration tests remain GREEN.

### Review

Because M01-M03 add destructive cleanup behavior around rollback-critical Docker state, the exact integrated implementation subject should receive independent implementation review before live production activation.

## Milestone M04 — Live Unraid verification

### Dependencies

M01-M03 implementation and applicable independent review GREEN.

### Outcome

The exact accepted retention implementation is validated against the real workstation Docker/BuildKit backend without risking unrelated Unraid workloads.

### Explicit authorization gate

Before any action that prunes/removes Docker images/cache on the real Unraid host, recreates the production workstation, or otherwise mutates live Docker state, obtain explicit user live-write/deployment authorization.

Read-only/non-destructive backend inspection may be performed earlier when required to select a safe cache mechanism, but private-host access must remain limited to the exact Docker/BuildKit facts required by M02.

### Deployment / verification strategy

At the authorized gate:
- refresh the workstream against current `main` and rerun affected source/orchestration tests;
- inspect current workstation candidate/rollback image state and builder/cache scope before mutation;
- run a normal successful workstation update;
- verify the promoted image health/runtime state;
- verify exactly one previous known-working rollback baseline is retained;
- verify only workstation-owned stale candidate/rollback artifacts are removed;
- verify unrelated Unraid image/container references remain untouched;
- verify the selected BuildKit cache retention command targets only the proven workstation scope;
- confirm a repeated/no-change build still exhibits useful cache reuse after bounded GC;
- verify durable update evidence identifies protected current/rollback identities and both cleanup results;
- confirm persistent home/projects/secrets/keyring data are unchanged.

A destructive synthetic failure against unrelated workloads is out of scope. Failure ordering is proven in M03's isolated orchestration harness.

### Acceptance

- Live production remains healthy on the exact promoted image.
- Exact previous known-working rollback image remains available.
- Older workstation-only image/tag artifacts are bounded.
- BuildKit cache policy is active, bounded and scoped as planned.
- Unrelated Unraid Docker artifacts are unaffected.
- Repeated unchanged-input build still benefits from cache.
- Evidence and source/integration tests are GREEN.

## Requirement coverage

| Requirement | Owner |
| --- | --- |
| R7-R8 identity-driven cache semantics | M02, M03, M04 |
| R11 deterministic rollback | M01, M03, M04 |
| R12 verified update success | M01, M03, M04 |
| R13 persistence/isolation invariants | M01, M04 |
| R16 existing validation contract | M03, M04 |
| R17 cleanup ordering | M01-M03 |
| R18 current + one rollback retention | M01, M03, M04 |
| R19 scoped/reference-safe image cleanup | M01, M03, M04 |
| R20 bounded scoped BuildKit cache | M02-M04 |
| R21 cleanup failure separation | M01-M03 |
| R22 persistent data excluded | M01, M04 |
| R23 retention evidence | M01-M04 |
| R24 multi-cycle/failure validation | M03, M04 |

## Migration / rollback strategy

There is no persistent data-schema migration.

The operational change adds a post-verification cleanup phase to the existing updater. Until that phase runs successfully, existing historical Docker artifacts may remain; this is safe and should be reported as incomplete cleanup rather than forcing recovery.

Rollback semantics remain those of D25: the previous known-working image is captured before promotion and must remain available through every candidate failure path. The new cleanup phase begins only after the candidate has become verified production.

## JIT / execution-prep boundaries

Execution Prep may decide inside accepted authority:
- exact shell/helper decomposition;
- workstation tag/reference discovery implementation;
- safe Docker tag/image removal sequencing;
- evidence JSON schema details;
- test-fixture representation of multi-cycle image state;
- exact BuildKit builder/filter/GC command and bounded age/size thresholds after M02 backend verification;
- whether a dedicated workstation builder/cache namespace is technically required to achieve safe scope.

If backend evidence shows the accepted workstation-only cache scope cannot be achieved without a material architecture change, open Research/Planning/Definition as routed rather than weakening D27.

## Planning audit

GREEN:
- all new retention requirements R17-R24 have explicit milestone ownership;
- existing rollback and identity-driven cache semantics are preserved;
- cleanup is strictly post-verification;
- image retention and BuildKit cache retention are separated;
- global/unscoped prune is explicitly forbidden;
- current production plus exactly one previous rollback baseline is the protected image set;
- cleanup failures after verified production are non-fatal and evidence-visible;
- three-cycle and failure-path acceptance is explicit;
- persistent data remains outside cleanup scope;
- real Docker/BuildKit mutation is behind an explicit user authorization gate;
- uncertain backend mechanics are bounded technical verification/JIT work, not an unresolved product choice;
- no implementation-specific BuildKit command or threshold is frozen before target-backend evidence.

Independent plan review is RECOMMENDED because the plan introduces destructive Docker artifact cleanup adjacent to rollback-critical state and must prove scope/order safety before implementation.

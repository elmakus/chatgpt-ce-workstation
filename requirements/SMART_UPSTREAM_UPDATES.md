# Smart upstream updates

Status: **approved**
Date: 2026-09-20

## Goal

Make workstation updates both current and cache-efficient.

The normal update operation MUST discover the current trusted stable/latest identities of image-managed upstreams, freeze those identities for one candidate build, reuse Docker cache when identities are unchanged, validate the candidate before promotion, and retain a deterministic path back to the previous known-working image if live promotion fails.

The workstation remains image-managed: runtime application self-updaters stay disabled.

## Requirements

### R1 — One normal user-facing update operation

`scripts/update.sh` is the normal workstation update operation.

A normal update MUST perform the full update lifecycle: resolve upstreams, build a candidate, validate it, promote it, wait for health and verify the live workstation.

Users MUST NOT need to run a separate "update dependencies" command followed by a rebuild.

### R2 — `build.sh` remains a lower-level build primitive

`scripts/build.sh` remains available for development, testing and exact-source rebuilds.

Invoking `build.sh` by itself MUST NOT be the mechanism that intentionally advances every moving upstream to the latest release. It should build from explicitly supplied/resolved inputs and normal Docker/base-image behavior.

### R3 — Ubuntu remains on the 24.04 LTS family

The workstation MUST remain based on Ubuntu 24.04 LTS unless a future explicit architecture decision changes the OS family.

A normal update SHOULD use the current available `ubuntu:24.04` image and current supported package set for that 24.04 environment.

The updater MUST NOT switch to `ubuntu:latest` or another Ubuntu release line merely because it is newer.

### R4 — Image-managed upstreams follow latest trusted stable/current channels

Under the normal update policy, the workstation MUST follow the current stable/supported upstream for:

- ChatGPT Community Edition on its selected moving branch, currently `main`;
- the official OpenAI ChatGPT Linux package consumed by CE from OpenAI's signed stable Linux repository;
- Agent Workspace;
- s6-overlay;
- Codex Web GPT from the configured fork/repository;
- Muse Code through Meta's supported stable distribution path;
- Google Chrome stable;
- Rust stable;
- Ubuntu packages within the 24.04 LTS environment.

A permanent repository pin to an old version MUST NOT be required for ordinary updates unless a concrete compatibility/security hold is explicitly accepted.

### R5 — Resolve first, then freeze exact candidate identities

Before building an update candidate, the updater MUST resolve each moving upstream to the strongest practical immutable identity supported by that upstream, such as an exact Git commit, release version/tag, package version plus checksum, or image digest.

The candidate build MUST use the resolved identities rather than independently asking each build step for an unconstrained moving `latest` value.

All build steps belonging to one update attempt MUST therefore refer to one coherent frozen resolution set.

### R6 — CE source and OpenAI application payload are separate freshness inputs

The CE Git revision and the official OpenAI ChatGPT Linux package identity MUST be treated as separate update inputs.

An unchanged CE commit MUST NOT allow a newer signed stable OpenAI package to remain hidden behind Docker cache.

The workstation MUST NOT weaken or replace CE's upstream package authenticity/validation contract. Any workstation-side resolution/probe for freshness must preserve CE as the authority that consumes and validates the official OpenAI package during the build.

### R7 — Real upstream identities replace timestamp-only cache invalidation

The default update path MUST NOT use a changing timestamp or equivalent arbitrary nonce as the primary cache invalidation mechanism for remote upstream components.

When the resolved identity of an upstream and all of its relevant build inputs are unchanged, Docker cache SHOULD remain reusable.

When an upstream identity changes, the relevant build path MUST be invalidated by that real identity.

### R8 — Cache isolation is best-practical, not fictitious

The image architecture SHOULD isolate independently moving upstream acquisition/build work enough to avoid unnecessary repeated downloads/builds where the benefit is material.

The implementation MAY use multi-stage Docker builds or equivalent BuildKit-friendly structure.

However, a change to an earlier/base dependency may legitimately invalidate downstream work. The system MUST NOT claim or depend on impossible "only one layer always rebuilds" semantics.

### R9 — Candidate metadata is inspectable

Every update candidate MUST expose enough resolved-version metadata to determine what was actually selected for at least the major managed upstreams.

This metadata MAY be recorded in image labels/files, bounded updater output and/or durable update evidence, but MUST be tied to the exact candidate image rather than only to transient console text.

The metadata MUST NOT contain secrets.

### R10 — Failed resolution/build/pre-promotion validation leaves production untouched

If upstream resolution, source validation, candidate build or any required pre-promotion candidate check fails, the currently running workstation MUST remain on its previous known-working production image/container state.

The updater MUST fail clearly without forcing a production recreate.

### R11 — Promotion retains deterministic rollback

Immediately before production promotion, the updater MUST identify and retain the previous known-working image identity needed for rollback.

If the new production container fails required health or runtime verification after promotion, the updater MUST attempt deterministic rollback to the retained previous image and verify that rollback.

If rollback itself cannot be completed or verified, the updater MUST fail loudly with the exact recovery state rather than silently declaring update success.

### R12 — Normal update success requires live verification

An update is successful only after:

1. the exact resolved candidate is built;
2. required pre-promotion validation is GREEN;
3. that exact candidate is promoted to production;
4. the workstation becomes healthy;
5. required runtime verification is GREEN.

A build success alone is not update success.

### R13 — Existing runtime isolation and persistence boundaries remain unchanged

Smart updates MUST NOT require:

- Docker socket access inside the workstation container;
- privileged mode;
- host-root mounts;
- `SYS_ADMIN`;
- runtime self-updaters for CE, Codex Web GPT, Muse or other image-managed applications.

Persistent home/projects/secrets behavior remains governed by existing accepted decisions.

### R14 — Expert overrides may exist but must be explicit

Per-component or whole-update override inputs MAY be retained for debugging, compatibility holds, recovery or exact reproduction.

An override MUST be explicit and visible in candidate metadata/output.

Normal default behavior remains latest trusted stable/current according to R3-R4.

### R15 — Network/upstream failure is fail-closed

If an upstream cannot be resolved or its required authenticity/checksum/metadata contract cannot be satisfied, the normal updater MUST fail rather than silently reuse an older cached upstream while reporting that the workstation is current.

An explicit recovery/offline mode, if added later, must be distinguishable from a normal current-update run.

### R16 — Validation covers freshness, cache semantics and rollback behavior

Automated source/integration tests MUST cover at least:

- unchanged resolved inputs produce stable build arguments/manifest content;
- a changed upstream identity changes the relevant resolved input;
- arbitrary timestamp-only invalidation is absent from the normal update path;
- CE revision and OpenAI package identity can change independently;
- expert overrides are explicit;
- failed resolution/build/pre-promotion checks do not recreate production;
- promotion retains the prior image identity;
- health/runtime failure exercises rollback orchestration without falsely reporting success;
- candidate metadata matches the frozen resolution set.

Live validation MUST include at least one successful update cycle on the target workstation and a bounded failure/rollback exercise that does not require deliberately damaging persistent user data.

### R17 — Retention cleanup runs only after verified promotion

Workstation artifact cleanup MUST run only after the exact promoted candidate has passed the required health and runtime verification from R12.

No image/tag/cache cleanup belonging to the retention policy may run on pre-promotion failure, promotion failure, promoted-image mismatch, failed health verification or failed runtime verification.

The image required for deterministic rollback MUST remain available throughout every failure path.

### R18 — Retain current production plus exactly one previous known-working image

After a successful verified update, the workstation MUST retain:

1. the exact current verified production image needed for normal recreation; and
2. exactly one immediately previous known-working workstation image as the deterministic rollback baseline.

Older workstation-specific `candidate-*` and `rollback-*` image/tag artifacts that are no longer required by those two retained identities MUST be eligible for removal after verification.

Retention logic MUST use exact image identity/reference evidence rather than age alone to decide which production and rollback images are protected.

### R19 — Image cleanup is workstation-scoped and reference-safe

Image/tag cleanup MUST be restricted to artifacts owned by this workstation update lifecycle.

The updater MUST NOT invoke an unscoped/global image or system prune that can remove images or layers belonging to unrelated Unraid containers/projects.

Cleanup MUST NOT remove an image or layer still required by the current production image, the retained rollback baseline, or another live Docker reference that makes deletion unsafe.

### R20 — Build cache has a separate bounded workstation-scoped policy

BuildKit/build cache retention MUST be treated separately from image/tag retention.

The workstation MUST define and apply a bounded retention mechanism for build cache attributable to this workstation's build path. The policy SHOULD preserve cache that remains useful/shared for likely future builds while preventing indefinite historical growth.

The exact supported mechanism MAY use scoped builder/cache records, age, size or equivalent BuildKit GC/prune semantics after the target Unraid Docker/BuildKit backend is verified. It MUST NOT rely on an unscoped/global prune that can evict unrelated projects' cache.

The policy MUST preserve the identity-driven cache semantics from R7-R8; a repeated no-change update may still execute the build path and benefit from BuildKit cache.

### R21 — Post-success cleanup failure is reported separately

Once the new production image has passed all success verification from R12, a later retention/cleanup failure MUST NOT falsely convert that already-verified production promotion into an update/rollback failure.

The updater MUST report cleanup status distinctly and persist enough evidence to identify what cleanup succeeded, what failed and which production/rollback identities remain protected.

### R22 — Persistent data is outside retention cleanup scope

The retention implementation MUST NOT delete, rewrite or prune persistent workstation home, projects, secrets, keyring data or other bind-mounted user state.

This cleanup policy applies only to workstation-owned Docker image/tag artifacts and its bounded build-cache scope.

### R23 — Retention evidence records protected identities and cleanup result

Durable update evidence for a successful update MUST identify at least:

- the current verified production image identity/reference;
- the retained previous known-working rollback image identity/reference;
- the image/tag cleanup result and removed/retained workstation artifact identities at a bounded level;
- the build-cache cleanup policy/result at a bounded level;
- any cleanup warning/failure distinct from production verification status.

Evidence MUST NOT contain secrets.

### R24 — Validation covers multi-cycle retention and failure ordering

Automated source/integration tests MUST cover at least three sequential successful update cycles and prove that workstation candidate/rollback artifacts do not grow without bound.

Tests MUST also prove that:

- exactly the current production image and one immediately previous known-working rollback baseline remain protected after a successful cycle;
- an older workstation rollback/candidate artifact becomes removable only after the newer production candidate is fully verified;
- cleanup is not invoked on pre-promotion or post-promotion verification failure paths;
- rollback after a failed candidate still uses the exact retained previous image and verifies GREEN;
- cleanup failure after production verification is surfaced distinctly without reporting the verified production update as failed;
- cleanup operations are workstation-scoped and do not use a global Docker prune;
- the build-cache policy is bounded without disabling useful unchanged-input cache reuse.

## Acceptance-level outcomes

The feature is accepted when all of the following are true:

1. one `update.sh` invocation performs the normal end-to-end update lifecycle;
2. Ubuntu remains on 24.04 LTS while its base/package environment can advance within that line;
3. the normal resolver selects current stable/latest identities for all in-scope upstreams and freezes them for the candidate;
4. unchanged upstream identities no longer rebuild solely because time passed;
5. a new Agent Workspace, s6-overlay, CE, OpenAI ChatGPT package, Codex Web GPT, Muse, Chrome or Rust identity can independently cause the corresponding update input to change;
6. the exact selected identities are inspectable from the candidate/update evidence;
7. pre-promotion failure leaves the current workstation untouched;
8. post-promotion health/runtime failure follows the deterministic rollback path and never reports false success;
9. runtime self-updaters remain disabled and the container isolation boundary is unchanged;
10. source/integration tests and target-host live verification are GREEN.
11. repeated successful updates retain the current verified production image plus exactly one immediately previous known-working rollback image without unbounded historical candidate/rollback growth;
12. rollback to the retained previous image remains deterministic and verifies GREEN after later successful update cycles;
13. workstation-specific image cleanup cannot prune unrelated Unraid image artifacts or persistent user data;
14. BuildKit/build cache uses a documented bounded workstation-scoped retention mechanism while preserving useful identity-driven cache reuse;
15. cleanup is ordered strictly after successful live verification and never removes the rollback baseline needed by a failed update;
16. update evidence distinguishes production success from retention cleanup status and identifies the protected current/rollback image identities.

## Non-goals

- upgrading the workstation to a different Ubuntu release family;
- promising that Docker can reuse downstream layers after every base-layer change;
- replacing upstream authenticity/signature/checksum validation with workstation-specific trust logic;
- automatically accepting beta/nightly/prerelease channels;
- making the running workstation mutate its own image from inside the container;
- using arbitrary `--no-cache` rebuilds as the normal freshness model;
- changing the CE feature set or broader workstation product behavior unrelated to update mechanics.
- using `docker system prune` or another unscoped/global cleanup operation as the retention mechanism;
- deleting persistent home/projects/secrets/keyring data as part of Docker artifact cleanup;
- disabling BuildKit cache or forcing clean rebuilds merely to control storage growth;
- retaining more than one historical known-working workstation image as part of the normal deterministic rollback contract.

## Definition notes

Exact resolver implementation, manifest format, Docker stage layout, package-metadata probe mechanics, candidate tag naming and rollback command structure are implementation/planning details as long as the requirements above are preserved.

The implementation may use bounded technical research to determine the strongest practical identity source for Muse, Ubuntu/Chrome APT metadata and the OpenAI package freshness probe. No unresolved product/system choice blocks Planning.

For artifact retention, the exact Docker/BuildKit commands, builder identity/filtering mechanism and concrete age/size thresholds are implementation/planning details. Bounded technical research MAY verify what the target Unraid Docker/BuildKit backend supports, but the retained-image count, cleanup ordering, workstation-only scope, non-fatal post-success cleanup reporting and bounded-cache outcome are fixed requirements.

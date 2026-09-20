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

## Non-goals

- upgrading the workstation to a different Ubuntu release family;
- promising that Docker can reuse downstream layers after every base-layer change;
- replacing upstream authenticity/signature/checksum validation with workstation-specific trust logic;
- automatically accepting beta/nightly/prerelease channels;
- making the running workstation mutate its own image from inside the container;
- using arbitrary `--no-cache` rebuilds as the normal freshness model;
- changing the CE feature set or broader workstation product behavior unrelated to update mechanics.

## Definition notes

Exact resolver implementation, manifest format, Docker stage layout, package-metadata probe mechanics, candidate tag naming and rollback command structure are implementation/planning details as long as the requirements above are preserved.

The implementation may use bounded technical research to determine the strongest practical identity source for Muse, Ubuntu/Chrome APT metadata and the OpenAI package freshness probe. No unresolved product/system choice blocks Planning.

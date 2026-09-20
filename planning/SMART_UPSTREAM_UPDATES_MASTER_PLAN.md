# Smart upstream updates Master Plan

Status: **approved**
Plan revision: **smart-upstream-updates-R2**
Date: 2026-09-20
Independent plan review: **RECOMMENDED**

R2 supersedes R1 after independent plan review found two bounded planning gaps: incomplete carry-through of D15/D4 deployment regression checkpoints, and ambiguity about whether the Ubuntu base-image identity could be recorded only after an unconstrained build.

## Goal and authority

Implement the approved smart-update lifecycle so `scripts/update.sh` resolves current trusted stable/latest upstream identities, freezes one coherent candidate, reuses Docker cache from those real identities, validates before promotion, and can roll back to the previous known-working image when live verification fails.

Authority:
- `requirements/SMART_UPSTREAM_UPDATES.md`
- `docs/DECISIONS.md#D2`
- `docs/DECISIONS.md#D4`
- `docs/DECISIONS.md#D5`
- `docs/DECISIONS.md#D6` as amended by D24
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D11`
- `docs/DECISIONS.md#D15`
- `docs/DECISIONS.md#D16`
- `docs/DECISIONS.md#D24`

The accepted product policy is latest trusted stable/current channels with Ubuntu held on the 24.04 LTS family. Exact resolver formats, Docker stage decomposition and rollback command details remain implementation decisions.

## Verified baseline

The current implementation:
- uses `UPSTREAM_REFRESH=<timestamp>` in `update.sh`;
- references that token in Chrome, CE, Muse and Codex Web GPT build paths;
- leaves the first Ubuntu APT layer independent of that refresh token;
- pins Agent Workspace and s6-overlay in Compose/Docker defaults;
- uses a mostly single-stage Dockerfile;
- recreates production before `verify-runtime.sh`, without an automatic previous-image rollback contract;
- performs source validation from `build.sh` before build but the new lifecycle must also preserve the accepted D15 host-preflight checkpoint before image build on the real deployment path;
- has `verify-runtime.sh` coverage for substrate/mount/isolation/application-surface checks, while D15/D4 separately require upstream-sensitive post-recreate regression checks such as native CE/Android Remote and the named application integrations;
- already disables runtime application self-updaters and uses Compose as the deployment authority.

Current upstream checks during discovery also proved that a real drift exists today (Agent Workspace workstation default 0.3.2 versus upstream latest 0.3.3), while s6-overlay's current workstation version remains equal to its latest release. This is evidence that static pins can become stale independently.

## Execution strategy

Separate the problem into four checkpoints:

1. establish a deterministic upstream-resolution contract;
2. make the image consume that frozen contract with cache-friendly inputs and inspectable metadata;
3. make `update.sh` promote/rollback exact image identities safely while preserving the accepted source-validation -> host-preflight -> image-build ordering before production mutation;
4. exercise the final updater on the real workstation only after explicit deployment/live-write authorization, then run the full D15/D4 regression sequence after recreation.

Technical probing of vendor metadata is allowed inside M01/JIT when it selects the strongest practical identity source without changing the accepted latest-stable policy.

Do not use a timestamp or random nonce as a substitute when a real upstream identity is available. When a channel cannot expose a stable immutable identifier directly, the implementation must use the strongest verifiable vendor-supported identity available and record the limitation.

The Ubuntu base is not an exception to resolve-first/freeze-first semantics: the selected `ubuntu:24.04` family member must be bound to an exact digest or demonstrably equivalent immutable identity before the candidate build consumes it. BuildKit may perform the mechanical lookup only when that exact identity is frozen before build execution and carried into candidate provenance; post-hoc recording of whatever a moving tag happened to resolve to is insufficient.

## Milestone M01 — Frozen upstream resolution contract

### Outcome

One resolver produces a deterministic, inspectable resolution set for every in-scope moving upstream without mutating production.

### Requirement ownership

R3-R7, R9, R14-R16.

### Planned work packages

- Define one canonical resolver output contract suitable for both shell orchestration and Docker/Compose build inputs.
- Resolve and normalize identities for:
  - Ubuntu 24.04 base image -> exact digest or equivalent immutable pre-build identity;
  - Ubuntu package freshness input;
  - CE selected branch -> exact Git commit;
  - official OpenAI ChatGPT stable Linux package identity from the signed repository path used by CE;
  - Agent Workspace latest stable package/release;
  - s6-overlay latest stable release;
  - Codex Web GPT latest stable release;
  - Muse Code current vendor stable identity;
  - Google Chrome stable package identity;
  - Rust stable toolchain identity.
- Preserve CE's own signed-package verification as authoritative; any pre-build OpenAI probe is a cache/freshness input, not a replacement trust path.
- Preserve existing upstream authenticity/checksum contracts such as the Codex Web GPT release checksum path while changing only how the exact release is selected.
- Define explicit per-component override semantics for compatibility/recovery.
- Define deterministic failure behavior: unavailable/unverifiable required upstream -> resolver failure, no silent stale success.
- Add fixture/unit tests for unchanged output, independent changed identities, malformed/unavailable metadata and explicit overrides.
- Record source/provenance metadata needed to explain where each identity came from.

### JIT technical verification

Before freezing implementation details, verify:
- the best supported machine-readable Muse stable identity available from Meta's installer/distribution path;
- how to derive and freeze an Ubuntu/Chrome package freshness identity without trusting stale local APT lists or allowing the candidate build to silently select a different moving state;
- how to query the OpenAI signed stable package metadata in a way that remains aligned with CE's resolver;
- the strongest practical pre-build mechanism for resolving `ubuntu:24.04` to an exact digest and feeding that frozen identity to the build.

BuildKit may be used as the resolver mechanism for the base image only if the exact digest/identity is materialized and frozen before candidate build execution; merely recording the digest after a tag-based build is not acceptable.

If one of these mechanisms cannot satisfy the approved requirement, route through Research/Definition rather than inventing an unsafe approximation.

### Acceptance

- Same upstream state produces byte-stable normalized resolution content.
- A change to any independently moving component changes only its relevant identity field(s), except for explicit shared metadata dependencies.
- CE Git identity and OpenAI package identity are independently represented.
- The Ubuntu 24.04 base identity is exact and frozen before candidate build execution.
- Normal resolution contains no timestamp/random cache-busting field.
- Override use is explicit in output.
- Resolver failure never invokes production recreate.
- Automated tests are GREEN.

## Milestone M02 — Cache-aware exact candidate build

### Dependencies

M01 GREEN.

### Outcome

The Docker/Compose build consumes one frozen resolution set, builds an exact candidate with inspectable provenance and no timestamp-driven normal invalidation.

### Requirement ownership

R2-R9, R13-R16.

### Planned work packages

- Pass resolved immutable inputs into Compose/Docker builds without requiring users to hand-maintain version pins.
- Bind the Ubuntu 24.04 base to the exact frozen M01 identity while retaining the 24.04 LTS family policy.
- Change CE source acquisition to consume the exact resolved CE commit rather than relying on an unconstrained moving branch inside a cached `RUN`.
- Ensure the OpenAI package freshness identity independently participates in the CE build cache key while CE continues to perform actual package validation.
- Replace the permanent Agent Workspace/s6 default-pin behavior with resolver-fed exact versions for update candidates.
- Make Codex Web GPT consume the resolved exact release rather than resolving `latest` again inside the candidate build, while retaining its checksum verification path.
- Make Muse, Chrome, Rust and Ubuntu package refresh behavior consume or bind to the corresponding frozen resolution identities with the strongest practical cache semantics; a later build step must not silently re-resolve a different moving state.
- Remove `UPSTREAM_REFRESH` timestamp from the normal update path and from source assertions that require it.
- Refactor into Docker build stages where doing so materially isolates expensive independently moving acquisitions/builds; do not restructure merely for aesthetic purity.
- Embed a non-secret resolution manifest or equivalent candidate metadata tied to the exact built image.
- Keep `build.sh` capable of lower-level exact builds from explicit/pre-resolved inputs rather than turning it into a second updater.
- Add source/build tests proving stable inputs preserve stable build args and changed identities reach the intended cache/build boundary.

### Acceptance

- Candidate image provenance identifies all major resolved upstreams, including the exact Ubuntu 24.04 base identity.
- Repeating a build with identical frozen inputs does not invalidate components solely because time passed.
- Changing CE alone, OpenAI package alone, Agent Workspace alone and at least one release-based component independently changes the corresponding candidate input.
- Normal build/update source no longer relies on `UPSTREAM_REFRESH=<timestamp>`.
- Ubuntu remains `24.04` and the candidate consumes the exact frozen base identity rather than a newly re-resolved moving tag.
- Existing upstream authenticity/checksum paths remain intact.
- Runtime self-update disabling and container isolation checks remain intact.
- Source validation and isolated candidate build verification are GREEN.
- Production container has not yet been recreated as part of M02 source implementation/review.

### Review

Because M01-M02 define supply/update and cache behavior across multiple external trust/update boundaries, the exact integrated resolver/build subject should receive independent implementation review before production activation.

## Milestone M03 — Safe promote/verify/rollback updater

### Dependencies

M01-M02 implementation and applicable independent review GREEN.

### Outcome

`scripts/update.sh` becomes the single end-to-end updater: resolve, accepted pre-build validation/preflight, exact candidate build, pre-promotion checks, exact promotion, health/runtime verification, and deterministic rollback on failed live verification.

### Requirement ownership

R1, R9-R16.

### Planned work packages

- Define candidate and previous-known-working image identity handling without relying on a mutable ambiguous `local` tag as the sole rollback reference.
- Capture the running production image identity before promotion.
- Preserve the D15 pre-build order on the real updater path: source validation -> host preflight -> image build.
- Build/tag the exact candidate from the frozen resolution set.
- Run all feasible non-production candidate checks before recreation.
- Ensure any resolver/source-validation/host-preflight/build/pre-promotion failure exits before production mutation.
- Promote exactly the validated candidate through the tracked Compose path.
- Wait for health and run `verify-runtime.sh`.
- On health/runtime failure, restore the prior known-working image identity, recreate, wait for health and verify rollback.
- Report update failure even when rollback succeeds; distinguish "update failed, old production restored" from success.
- If rollback fails, emit exact recovery state and never claim success.
- Preserve bounded update evidence including old image, candidate image and resolution-manifest identities without secrets.
- Add orchestration tests using mocks/isolated Compose/image tags so failure paths can be proven without damaging persistent production data.

### Acceptance

- One normal `update.sh` invocation owns the full lifecycle.
- The updater preserves source validation -> host preflight -> image build before any production recreate on the real deployment path.
- Resolver/source-validation/host-preflight/build/pre-promotion failure provably leaves production untouched.
- Promotion uses the exact candidate identity produced by the frozen resolution set.
- Post-promotion health/runtime failure exercises rollback and never reports success.
- Successful rollback is verified.
- Rollback failure is distinct and explicit.
- Lower-level `build.sh` still works for development/exact builds.
- Automated orchestration/source tests are GREEN.

## Milestone M04 — Production activation and live fault-injection verification

### Dependencies

M03 implementation and applicable independent review GREEN.

### Outcome

The accepted updater is deployed to the real workstation and proves both successful smart update behavior, the full accepted D15/D4 regression sequence, and bounded rollback behavior.

### Explicit authorization gate

Before any action that recreates the currently running workstation, changes its production image, or deliberately triggers a live rollback test, obtain explicit user deployment/live-write authorization.

Feature/plan/implementation approval does not itself grant this production mutation authority.

### Deployment / verification strategy

At the gate:
- refresh against current `main`/target and revalidate the exact candidate;
- preserve the accepted D15 order through source validation -> host preflight -> image build before recreation;
- record the current production image identity as rollback baseline;
- run the updater through its normal resolver/build path;
- confirm the resolved metadata corresponds to the actual candidate;
- confirm production reaches healthy/runtime GREEN on the exact promoted image;
- verify exact runtime mount/isolation invariants;
- perform the native CE regression, including Android Remote after this significant CE/update-path activation;
- verify Codex Web GPT configuration/model routing;
- verify Agent Workspace / Computer Use;
- verify the active major component identities are consistent with the frozen resolution set where observable;
- run a bounded rollback/failure exercise that avoids corrupting persistent home/projects/secrets and proves the previous image path can be restored and reverified;
- after rollback testing, restore/confirm the intended accepted production candidate and repeat the required health/runtime/application regression checks;
- confirm a subsequent normal/no-change update does not use timestamp-only invalidation and reuses cache where expected.

If a live test reveals a behavioral defect, do not normalize it as expected update drift; return through correction/review before final integration.

### Acceptance

- A real update completes GREEN using the new lifecycle.
- Ubuntu remains on 24.04 LTS.
- The live image exposes the exact resolved upstream metadata.
- Production health/runtime verification is GREEN.
- Native CE/Android Remote regression is GREEN for the significant CE/update-path activation.
- Codex Web GPT configuration/model routing is GREEN.
- Agent Workspace / Computer Use regression is GREEN.
- The rollback path is demonstrated safely and the intended accepted candidate is restored/reverified afterward.
- A no-change/repeated resolution run is stable and does not rebuild solely because of time.
- No new privilege/isolation regression appears.
- Existing persistent home/projects/auth state survives update/rollback.

## Requirement coverage

| Requirement | Owner |
| --- | --- |
| R1 one normal updater | M03, M04 |
| R2 lower-level build primitive | M02, M03 |
| R3 Ubuntu 24.04 family | M01, M02, M04 |
| R4 latest stable/current upstreams | M01, M02, M04 |
| R5 resolve/freeze identities | M01, M02 |
| R6 CE/OpenAI separate freshness | M01, M02 |
| R7 no timestamp-only invalidation | M01, M02, M04 |
| R8 best-practical cache isolation | M02 |
| R9 inspectable candidate metadata | M01, M02, M03, M04 |
| R10 pre-promotion failure safety | M03 |
| R11 deterministic rollback | M03, M04 |
| R12 success requires live verification | M03, M04 |
| R13 isolation/self-updater invariants | M02-M04 |
| R14 explicit overrides | M01, M02 |
| R15 fail-closed upstream resolution | M01, M03 |
| R16 validation coverage | M01-M04 |

## Migration / rollback strategy

There is no persistent data-schema migration.

The operational migration is from timestamp-driven `update.sh` to resolver-driven exact candidates.

During M04, keep the previous production image identity until the new updater's full live acceptance is GREEN. Do not prune the rollback image before health/runtime plus D15/D4 application regression acceptance.

A failed candidate never becomes accepted merely because rollback worked.

## JIT / execution-prep boundaries

Execution Prep may choose:
- exact resolver implementation language/format;
- package metadata commands/APIs;
- the exact safe mechanism that freezes Ubuntu/Chrome/APT identities before build;
- image label/file layout;
- Docker stage boundaries;
- candidate/rollback tag naming;
- mock/isolated Compose test harness details;
- the concrete existing/new helper wiring used to realize the accepted host-preflight checkpoint.

Those choices must stay inside D24 and the requirements. In particular, JIT may choose the mechanism for base-image resolution but may not weaken the pre-build frozen-identity invariant. If a vendor channel cannot provide enough stable identity/trust evidence to meet the Definition, open a Research obligation rather than weakening the contract silently.

## Planning audit

GREEN:
- every approved requirement has a milestone owner and execution path;
- latest-stable policy and Ubuntu 24.04 family pin are both preserved;
- the Ubuntu base is frozen to an exact immutable identity before candidate build execution;
- CE and OpenAI payload freshness are not conflated;
- cache goals are realistic about Docker dependency invalidation;
- supply/authenticity checks remain upstream-authoritative rather than reimplemented insecurely;
- candidate validation, production mutation and rollback are separated;
- D15 source validation -> host preflight -> image build ordering is explicit before production mutation;
- M04 explicitly carries the D15/D4 post-recreate regressions for CE/Android Remote, Codex Web GPT routing and Agent Workspace/Computer Use;
- production recreate/fault-injection remains behind explicit user authorization;
- no Docker-socket/privileged/self-updater shortcut is introduced;
- rollback image retention is explicit;
- unresolved items are bounded technical mechanism questions suitable for JIT/Research and do not alter product intent;
- no speculative low-level interface is frozen unnecessarily.

Independent plan review is RECOMMENDED because this is a new multi-upstream supply/update architecture with production rollback semantics.

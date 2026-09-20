# Brainstorm — smart upstream updates

Date: 2026-09-20
Scope ID: `smart-upstream-updates`
Revision: `R1`
Status: `ready_for_definition`

## Problem / goal

The workstation update path currently uses a time-varying `UPSTREAM_REFRESH` token to force several remote-source Docker layers to rerun. That guarantees freshness for those layers, but it also discards useful cache even when upstream identities are unchanged, while the earliest Ubuntu APT layer can remain cached and stale.

The goal is a predictable image-managed update lifecycle that follows current stable/latest upstreams, uses immutable resolved identities as cache keys, avoids unnecessary remote downloads/rebuild work, and promotes only a validated candidate.

## Current understanding

### Verified facts

- `scripts/build.sh` validates source and runs `docker compose build --pull workstation`.
- `scripts/update.sh` currently creates a new timestamp-like `UPSTREAM_REFRESH` value, calls `build.sh`, force-recreates the workstation, waits for health and then runs runtime verification.
- `UPSTREAM_REFRESH` currently invalidates Chrome, CE, Muse and Codex Web GPT remote-source layers even when their actual upstream version/content did not change.
- The initial Ubuntu APT package layer does not use the refresh token.
- The base image is `ubuntu:24.04`; `--pull` can advance that tag within the Ubuntu 24.04 line.
- CE defaults to `CE_REF=main`. Current CE source resolves the official OpenAI `chatgpt` package from OpenAI's signed stable Linux APT metadata and validates the package.
- Agent Workspace is explicitly pinned to `0.3.2` in the current workstation while its current upstream latest release is `v0.3.3`.
- s6-overlay is explicitly pinned to `3.2.3.2`; that is also the current upstream latest release.
- Codex Web GPT already resolves `releases/latest` when no explicit version is supplied, but only when its Docker layer actually reruns.
- Muse currently downloads Meta's installer and resolves the stable binary when its Docker layer reruns; runtime self-update is intentionally disabled.
- Chrome uses the vendor stable APT channel; Rust uses rustup stable.
- The current Dockerfile is mostly single-stage, so a changed early layer can legitimately invalidate later layers even when those later upstream identities are unchanged.
- The current update path recreates production before `verify-runtime.sh`, so post-recreate verification failure does not currently provide a transactional automatic rollback path.

### Existing accepted decisions / explicit user choices

- Normal workstation maintenance should have one user-facing operation: `update.sh`.
- `build.sh` remains a lower-level development/build primitive and should not unexpectedly advance every moving upstream.
- Ubuntu should remain on the **24.04 LTS line**, not `ubuntu:latest`.
- Image-managed upstream applications/components should follow their **latest stable/current supported channel** rather than permanent hand-maintained pins.
- For one update attempt, each moving upstream should first be resolved to a concrete immutable identity/version/SHA/digest where practical, then the build should use that frozen identity.
- If the resolved identity is unchanged from the previous build input, Docker cache should remain reusable; a timestamp alone should not invalidate the component.
- If an update candidate fails validation, the currently working workstation should not be silently replaced by a broken state.
- CE remains responsible for consuming/verifying the official OpenAI stable Linux package; the workstation should detect that package identity as an independent freshness input so a new OpenAI package cannot be hidden behind an unchanged CE Git commit.
- Runtime application self-updaters remain disabled; workstation image rebuild/update is the update authority.

## Ideas / alternatives considered

### Option A — keep timestamp-driven refresh

Simple and freshness-oriented, but unnecessarily reruns unchanged remote-source layers and still does not make Ubuntu package freshness coherent. Rejected as the target model.

### Option B — literal floating `latest` inputs inside Dockerfile only

This looks simple but Docker cannot know that a network resource fetched inside an otherwise unchanged `RUN` instruction changed upstream. It also weakens reproducibility. Rejected as the primary mechanism.

### Option C — resolve → freeze → build

Preferred direction.

Before the build, an update resolver determines the current immutable identity of every moving upstream that materially affects the image. Those identities are passed into the build and recorded in the candidate. Same identities preserve cache; changed identities invalidate the relevant build path.

Examples of suitable identities:
- Ubuntu 24.04 base image digest;
- current Ubuntu package-repository freshness identity or another bounded OS-package refresh key;
- CE Git commit SHA;
- official OpenAI ChatGPT stable package version/SHA from signed metadata;
- Agent Workspace exact npm/release version;
- s6-overlay exact release tag;
- Codex Web GPT exact release tag;
- Muse stable binary/installer identity supported by Meta's distribution mechanism;
- Chrome stable package version/repository identity;
- Rust stable toolchain identity.

### Option D — rebuild everything with `--no-cache`

Fresh but wastes time/network and discards Docker's main benefit. Rejected.

## Cache / image architecture considerations

The user goal is to avoid re-downloading/rebuilding unchanged components. Exact layer reuse is limited by Docker dependency ordering: when an early layer changes, downstream layers also invalidate.

A likely implementation direction is to separate independently moving upstream acquisition/build steps into dedicated build stages where useful, then assemble the final Ubuntu 24.04 runtime image. This can improve component-level cache isolation without pretending that a changed base OS can leave every dependent runtime layer valid.

The requirement should be **no artificial invalidation of unchanged upstreams and best practical component isolation**, not a false promise that every update can rebuild literally one layer.

## Update safety considerations

A smart resolver alone does not make deployment transactional.

Preferred behavior:
1. resolve current upstream identities;
2. build a candidate image with those exact identities;
3. run image/candidate checks that can be performed without touching production;
4. retain the known-working image identity;
5. promote/recreate production only after candidate checks are GREEN;
6. wait for health and run production runtime verification;
7. if post-promotion verification fails, provide a deterministic rollback to the previous known-working image rather than leaving an untracked broken state.

Exact staging/container mechanics belong to Planning/JIT as long as the production-safety outcome is preserved.

## Component policy under consideration

- Ubuntu base: latest current image within `24.04` LTS.
- Ubuntu packages: current packages available for that 24.04 environment during explicit update.
- ChatGPT CE: latest selected upstream branch, currently `main`, frozen to exact commit for the candidate.
- OpenAI ChatGPT package consumed by CE: latest signed stable package, frozen/detected by exact version/hash.
- Agent Workspace: latest published stable package/release.
- s6-overlay: latest stable release.
- Codex Web GPT: latest stable GitHub release.
- Muse Code: latest vendor stable channel.
- Google Chrome: latest stable package.
- Rust: latest stable toolchain.

Manual overrides may remain as an expert/debug/recovery escape hatch, but they should not be required for normal updates and must not silently change the default policy away from latest/stable.

## Research needed

No formal research obligation is required before Project Definition. Current source and upstream distribution contracts establish the target behavior.

Implementation will need bounded technical verification for:
- the safest machine-readable identity source for Meta Muse stable;
- a practical Ubuntu/Chrome package freshness key that preserves cache without trusting stale APT metadata;
- the exact method for detecting OpenAI's signed stable package identity before CE build without weakening CE's own verification;
- which upstreams benefit materially from separate Docker build stages.

Those are mechanism choices, not unresolved product decisions.

## Open questions

- Exact resolver output format: shell env, JSON manifest, generated Compose env, or a combination.
- Whether resolved identities should be persisted only inside the built image/evidence or also in an untracked host-side state file for diagnostics.
- Exact candidate tag/rollback tagging scheme.
- How much multi-stage refactoring is worthwhile versus relying on standard downstream invalidation when the OS/base changes.
- Whether an expert override should be a single opt-out flag or per-component override values.

## Outcome of this session

- Tentative conclusions: replace timestamp invalidation with resolve → freeze → build; keep Ubuntu on 24.04 LTS; follow latest stable/current channels; retain `build.sh` as the lower-level non-updating primitive; make `update.sh` the normal updater; preserve production until candidate validation is GREEN and retain rollback ability for post-promotion failure.
- Explicit user/product choices to promote through Project Definition: all normal upstreams latest/stable; Ubuntu stays on 24.04 LTS; one normal `update.sh`; smart cache from real upstream identities; CE/OpenAI package freshness tracked separately; no broken-candidate promotion.
- Research still needed: none before Definition; bounded mechanism verification can occur during planning/JIT.
- Open questions: implementation-level resolver format, freshness-key mechanics, candidate tags and stage layout.
- Next phase/action: `ready for definition`
- Definition promotion authorization: `pending`
- Definition promotion subject: `none`

> Nothing in this file becomes accepted requirement/decision authority by itself. Project Definition owns promotion into canonical `requirements/` and `decisions/`. The `#feature` directive does not itself authorize phase promotion.

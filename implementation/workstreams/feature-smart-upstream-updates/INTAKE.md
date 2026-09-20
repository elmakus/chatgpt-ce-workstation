# Intake — smart upstream updates

Date: 2026-09-20
Workstream ID: `feature-smart-upstream-updates`
Kind: `feature`
Status: active

## Operator intent

Replace timestamp-driven workstation updates with a smart upstream-update lifecycle: resolve the current stable/latest identity of each image-managed upstream, reuse Docker cache when that identity is unchanged, rebuild only affected dependency layers as far as the image architecture permits, validate the candidate, and avoid promoting a failed update.

## Discovery

- Normal integration target is `main`.
- No existing matching workstream or branch was found.
- Current `scripts/update.sh` generates a new timestamp-like `UPSTREAM_REFRESH` token on every explicit update.
- Current `scripts/build.sh` runs source validation and `docker compose build --pull workstation`.
- `Dockerfile` references `UPSTREAM_REFRESH` in Chrome, CE, Muse and Codex Web GPT layers, so an explicit update deliberately invalidates those remote-source layers even when the upstream identity did not change.
- The initial Ubuntu APT package layer does not reference the refresh token, so explicit updates do not reliably refresh that layer when Docker cache remains valid.
- The workstation currently pins `S6_OVERLAY_VERSION=3.2.3.2` and `AGENT_WORKSPACE_VERSION=0.3.2`; CE defaults to moving `main`; Codex Web GPT resolves latest when its layer actually reruns; Muse uses Meta's stable installer when its layer reruns; Chrome and Rust follow moving stable channels.
- The accepted container architecture keeps Ubuntu on the 24.04 LTS line and disables application self-updaters in favor of image rebuilds.

## Base / dependency classification

Independent workstream.

This feature changes update/build semantics already present on current `main` and does not require unmerged parent-only state.

Base:
`elmakus/chatgpt-ce-workstation@04fb32a47b5bcfbfcf16f6fb77bffbe2a7282acf`

Integration target: `main`.

## Initial scope

Explore and define a single normal user-facing update operation that:
- keeps Ubuntu on 24.04 LTS while refreshing its current image/packages;
- follows latest/stable upstreams for the workstation-managed applications/components;
- resolves immutable version/SHA/digest identities before build where practical;
- uses those real identities as cache keys instead of a timestamp-only refresh token;
- preserves a lower-level build path for development without necessarily advancing upstreams;
- validates before production promotion and keeps the currently working workstation available when an update candidate fails;
- records enough resolved identity/evidence to explain what changed in an update.

## Classification

Path: `brainstorming`

Next route: `brainstorming:smart-upstream-updates@R1`

The `#feature` directive does not authorize Project Definition promotion.

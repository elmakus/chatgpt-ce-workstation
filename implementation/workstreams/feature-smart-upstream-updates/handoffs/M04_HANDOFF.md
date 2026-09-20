# M04 cumulative handoff — smart upstream updates

Date: `2026-09-20`
Milestone: `M04 — Production activation and live fault-injection verification`
Status: **GREEN / accepted; final workstream integration pending**

## Completed checkpoint

- Accepted pre-Close repository checkpoint: `a6fbfd8d9e5a7e3dca3ed3053a2bc7cab214b251`.
- M04-T01: production updater activation and corrected application regressions GREEN.
- M04-T02: bounded live rollback, accepted-candidate restoration and no-change/cache verification GREEN.
- Milestone acceptance: `implementation/workstreams/feature-smart-upstream-updates/evidence/M04-acceptance.md`.
- Final integration refresh: `implementation/workstreams/feature-smart-upstream-updates/evidence/SMART_UPSTREAM_UPDATES-final-integration-refresh.md`.

## Achieved state

Production is running the accepted exact candidate image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852` for frozen resolution `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`, healthy after normal update, controlled rollback/restoration and a subsequent no-change update.

The smart updater now has live evidence for exact-source resolution, deterministic image identity, preflight/build/provenance, exact promotion, health/runtime verification, rollback to the retained prior image, persistent-state survival, restored application behavior and stable cache reuse without timestamp-only invalidation.

## Authority in force

- `requirements/SMART_UPSTREAM_UPDATES.md`.
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` revision `smart-upstream-updates-R2`.
- `docs/DECISIONS.md` — D2, D4, D5, D6, D10, D11, D15, D16, D25.
- Workstream manifest: `implementation/workstreams/feature-smart-upstream-updates/WORKSTREAM.yaml`.

## Verification

- M02-T02 independent review: GREEN.
- M03-T02 corrected-subject independent review: GREEN.
- Related Codex Web GPT C01 and C02 independent reviews: GREEN; corrected release `v5.0.12` is active in production.
- M04-T01 production revalidation: GREEN.
- M04-T02 real rollback/no-change acceptance: GREEN.
- Final integration target refresh: GREEN; PR #7 base is exactly current `main@04440574afb2d85790301c915e9d7f8c90721021`, branch is behind by zero and GitHub reports mergeable.
- Final workstream independent review: **pending**; no prior independent verdict covers the whole final workstream acceptance surface.

## Material exceptions / deferred items

PR #7 is not yet merged. Final workstream integration remains blocked only by the manifest-owned `RECOMMENDED` independent review and subsequent normal Close publication/finalization.

The preserved historical pre-bind backup under the persistent home remains a non-blocking runtime-verifier warning and is outside this workstream's cleanup scope.

## Next durable starting point

Start from `implementation/workstreams/feature-smart-upstream-updates/WORKSTREAM.yaml` once Close freezes its exact final-integration review subject. A fresh normal ChatGPT chat must perform that review. After GREEN, return to Close, re-read current `main`, verify PR #7 publication state, merge into `main`, and reconcile merge-result-dependent terminal state from the target-side package.

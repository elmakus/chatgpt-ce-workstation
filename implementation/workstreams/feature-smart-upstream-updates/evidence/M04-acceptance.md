# M04 milestone acceptance — smart upstream updates

Date: `2026-09-20`
Milestone: `M04 — Production activation and live fault-injection verification`
Result: **GREEN**

## Accepted checkpoint

- Repository checkpoint before Close bookkeeping: `a6fbfd8d9e5a7e3dca3ed3053a2bc7cab214b251`.
- M04-T01 production revalidation: `implementation/workstreams/feature-smart-upstream-updates/evidence/M04-T01-live-regression-3.md`.
- M04-T02 rollback/no-change acceptance: `implementation/workstreams/feature-smart-upstream-updates/evidence/M04-T02-live-rollback.md`.
- Corrected managed upstream: Codex Web GPT `v5.0.12`, containing independently reviewed C01/C02 fixes.

## Acceptance

GREEN against the approved M04 outcome and applicable R1-R16 / D4 / D5 / D10 / D15 / D16 / D25 surface.

The production target demonstrated:

- normal `scripts/update.sh` activation of one exact frozen candidate;
- exact resolution/image provenance readback;
- healthy Ubuntu 24.04 runtime with required persistence and isolation boundaries intact;
- native CE remote-control surface, Codex Web GPT, Agent Workspace and Computer Use regressions GREEN after recreate;
- one bounded post-promotion runtime-verification failure exercising the real updater rollback path;
- deterministic rollback to the exact retained previous image with health and full runtime verification;
- preservation of persistent-home and project-bind sentinel data across rollback and restoration;
- normal restoration of the accepted candidate followed by application regressions;
- a true no-change resolution producing the identical frozen SHA and image ID;
- practical BuildKit cache reuse with 24 `CACHED` markers and no timestamp-only rebuild invalidation.

The final production readback is exact accepted image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852`, running and healthy.

## Publication boundary

M04 behavior/acceptance is complete. Final integration into `main` remains owned by Close and is not yet complete. The branch-isolated final-integration review requirement is `RECOMMENDED` and must be satisfied on an exact refreshed workstream subject before PR #7 can be merged.

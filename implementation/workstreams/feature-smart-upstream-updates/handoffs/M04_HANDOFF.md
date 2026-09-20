# M04 cumulative handoff — smart upstream updates

Date: `2026-09-20`
Milestone: `M04 — Production activation and live fault-injection verification`
Status: **GREEN / complete**

## Completed checkpoint

- Accepted implementation checkpoint: `a6fbfd8d9e5a7e3dca3ed3053a2bc7cab214b251`.
- M04-T01 production updater activation and corrected application regressions: GREEN.
- M04-T02 bounded live rollback, accepted-candidate restoration and no-change/cache verification: GREEN.
- Milestone acceptance: `implementation/workstreams/feature-smart-upstream-updates/evidence/M04-acceptance.md`.
- Final-integration review: GREEN at `implementation/workstreams/feature-smart-upstream-updates/evidence/SMART_UPSTREAM_UPDATES-final-integration-review.md`.
- Final integration: PR #7 merged to `main`; merge result `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`.
- Target-side closure evidence: `implementation/workstreams/feature-smart-upstream-updates/evidence/SMART_UPSTREAM_UPDATES-final-integration-result.md`.

## Achieved state

The complete smart-upstream-updates workstream is integrated into `main`. The normal `scripts/update.sh` path resolves and freezes current trusted stable/current upstreams, builds and validates one exact candidate, promotes only after pre-promotion gates, verifies health/runtime, and retains an exact known-working rollback image.

Production remains on accepted image `sha256:ea264b43f32482b8edd9a6012f0c28a38bab4fd27f1db092ad6ed11d67d27852` for frozen resolution `27a9929c4cb4da99c0c3cd4c4e5807539ad759b5360559a872664162b5ba1fff`, with successful live update, controlled rollback/restoration, persistence checks and stable no-change cache reuse already demonstrated.

## Authority in force

- `requirements/SMART_UPSTREAM_UPDATES.md`.
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md` revision `smart-upstream-updates-R2`.
- `docs/DECISIONS.md` — D2, D4, D5, D6, D10, D11, D15, D16, D25.
- Workstream manifest: `implementation/workstreams/feature-smart-upstream-updates/WORKSTREAM.yaml`.

## Verification

- M02-T02 independent review: GREEN.
- M03-T02 corrected-subject independent review: GREEN.
- Related Codex Web GPT C01/C02 independent reviews: GREEN; corrected release `v5.0.12` is active in production.
- M04-T01 production revalidation: GREEN.
- M04-T02 real rollback/no-change acceptance: GREEN.
- Workstream final-integration independent review: GREEN on subject `272ec9d238ca19ab3c190b1450cd2a19b7bdd4cb`.
- PR #7 target readback: GREEN; exact source head `59a7d17526f5681f2402f562d7a7e4a4fff11041` merged as `3f117a7a69895ba305e1355e3d0a81c8c8f8892d`.
- The source branch was automatically removed after merge, so no fallback `branch_cleanup` lifecycle is required.

## Material exceptions / deferred items

The preserved historical pre-bind backup under the persistent home remains a non-blocking runtime-verifier warning and is outside this workstream's cleanup scope.

No additional production recreate/live write was performed during Git integration.

## Next durable starting point

The approved `smart-upstream-updates-R2` workstream scope is complete. No further deterministic implementation, review or integration obligation remains for this workstream.

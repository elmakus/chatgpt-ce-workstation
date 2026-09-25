# M00 handoff — Codex Web GPT fork release readiness

Milestone: `M00`
Plan revision: `smart-upstream-updates-R4`
Status: **GREEN / done**
Accepted fork subject: `elmakus/codex-chatgpt-web@b39499c391744eaa378b157822e18b9218590b60`

## Achieved state

The Workstation-managed Codex Web GPT fork is synchronized with trusted upstream v6.1.0, preserves the accepted Workstation-specific routing/auth/isolation and packaging behavior, and has an independently reviewed canonical downstream release.

- final-integration review: GREEN for exact subject `b39499c...`;
- fork PR #20 merged that exact subject into fork `main` without tree drift;
- canonical release `v6.1.0-private.1` is published as a stable release;
- the release tag resolves exactly to the independently reviewed subject;
- release workflow attempt 2 passed verify, packaging, Linux AppImage ABI smoke, packaged-app smoke and publication;
- AppImage and checksum manifest expose SHA-256 digests;
- no Workstation production image/container was rebuilt, recreated or promoted.

## Acceptance and evidence

Primary M00 close evidence:
`implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/M00-release-publication.md`

Independent final-integration review:
`implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/final-integration-review-b39499c-green.md`

Card evidence:
- `implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/T01-upstream-v6-sync.md`
- `implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/T02-release-lineage-correction.md`
- `implementation/workstreams/change-codex-web-upstream-v6-sync/evidence/T03-health-privacy-private-lineage-correction.md`

Published release identity:
`v6.1.0-private.1@b39499c391744eaa378b157822e18b9218590b60`

## Authority in force

- `requirements/SMART_UPSTREAM_UPDATES.md`
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m00--codex-web-gpt-fork-release-readiness`
- `docs/DECISIONS.md#D5`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D11`
- `docs/DECISIONS.md#D25`
- workflow-main `workflow/common/FORK_RELEASE_VERSIONING.md`

## Material exceptions

The first `Fork Linux Release` attempt failed before publication while entering the ABI phase. A failed-jobs rerun on the identical immutable subject passed the full release path. No correction commit or review-subject change was required.

## Next durable starting point

M00 is complete and its publication prerequisite for M01 is satisfied.

For this branch-isolated workstream, the immediate remaining obligation is final-target integration into Workstation `main`:
1. keep the current integration refresh valid against `main`;
2. preserve the manifest-owned GREEN final-integration review;
3. open/verify the Workstation PR carrying this closure-ready package;
4. merge to `main` and reconcile only merge-result-dependent terminal manifest/Task Board metadata from target-side state.

No production deployment/live-write action is part of this remaining M00 workstream close.

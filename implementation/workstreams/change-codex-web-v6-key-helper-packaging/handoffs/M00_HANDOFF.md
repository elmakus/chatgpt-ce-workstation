# M00 handoff — Codex Web GPT v6 key-helper packaging repair

Milestone: `M00`
Plan revision: `smart-upstream-updates-R4`
Status: **GREEN / done**
Accepted fork subject: `elmakus/codex-chatgpt-web@78297853c0d17242a241592719e5204e5de30078`

## Achieved state

The Workstation-managed Codex Web GPT fork now has a corrected canonical v6.1 release whose packaged Linux AppImage contains the Codex-LB key helper required by Workstation.

- M00-T04 independent review: GREEN for exact subject `78297853...`;
- manifest final-integration gate: GREEN by exact M00-T04 coverage after unchanged-target refresh;
- fork PR #21 merged the exact reviewed content into fork `main`;
- canonical stable release `v6.1.0-private.2` is published and its tag resolves exactly to the reviewed subject;
- release workflow `36202667930` passed full verify, packaging, Linux AppImage ABI, packaged-app smoke and publication;
- published AppImage digest: `sha256:8addbc2949f395068f3f2fdb95ea1ae38e19557a4df6f6ac13cca0b0d03c4af1`;
- no Workstation production image/container was rebuilt, recreated or promoted as part of M00.

## Acceptance and evidence

Primary M00 close evidence:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-release-publication.md`

Independent Card review:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-T04-review.md`

Final-integration refresh/coverage:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-final-integration-refresh.md`

Implementation evidence:
`implementation/workstreams/change-codex-web-v6-key-helper-packaging/evidence/M00-T04-implementation.md`

Published release identity:
`v6.1.0-private.2@78297853c0d17242a241592719e5204e5de30078`

## Authority in force

- `requirements/SMART_UPSTREAM_UPDATES.md`
- `planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md#milestone-m00--codex-web-gpt-fork-release-readiness`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D11`
- `docs/DECISIONS.md#D25`
- workflow-main `workflow/common/FORK_RELEASE_VERSIONING.md`

## Next durable starting point

M00 and workstream `change-codex-web-v6-key-helper-packaging` are terminally complete.

- Workstation PR #26 merged to `main@ec3336428e6cb157e14bfc63585b6763f4ad14d6`.
- The original source branch was auto-deleted after merge; no cleanup fallback is active.
- Canonical Codex Web GPT release `v6.1.0-private.2` remains pinned to independently reviewed subject `78297853c0d17242a241592719e5204e5de30078`.
- The historical primary `feature-smart-upstream-updates` workstream already has M01-M04 terminally done; this corrective M00 workstream does not open a new implementation milestone.

There is no remaining Card, Research, review, stacked-dependency, integration or release-publication obligation in this workstream.

The normal live Workstation update that originally exposed the packaging defect remains an already-authorized operational continuation outside the M00 production boundary; it may now resume against the corrected published release.

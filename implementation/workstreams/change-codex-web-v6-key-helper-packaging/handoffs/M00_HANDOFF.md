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

M00 is complete. The immediate remaining managed-workstream obligation is final-target integration of this closure-ready namespaced package into Workstation `main`.

The normal live Workstation update that originally exposed the packaging defect is not part of the M00 production boundary. Its already-authorized operational continuation may resume only after the corrected release and this workstream's final-target integration are durably complete.

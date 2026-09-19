# M02 handoff — production activation and live verification

Status: **GREEN acceptance / final integration pending**
Workstream: `feature-managed-persistent-agents`
Milestone: `M02`

## Accepted checkpoint

Repository implementation source remains the independently reviewed managed-AGENTS subject:

`elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`

M02 operational result is durably recorded by:

- deployment-readiness evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_DEPLOYMENT_READINESS_2026-09-20.md`;
- independent M02-T01 review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_INDEPENDENT_REVIEW_2026-09-20.md`;
- authorized production activation evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T02_PRODUCTION_ACTIVATION_2026-09-20.md`.

## Achieved state

The production workstation runs exact candidate image:

`sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`

The persistent global AGENTS target migrated through container initialization to one current workstation-managed block while preserving the independently managed `codex_workflow` region byte-for-byte.

Final live verification proved:

- health/runtime GREEN after two tracked recreates;
- bounded managed-block verification GREEN;
- `codex_workflow` suffix SHA unchanged at `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- migrated full AGENTS SHA `c31f5cd8a9fd9a231c557de07ae472b1f3e2a18e58936e8db2138a7b24da99dd` unchanged across the second recreate;
- image-owned X11/ydotool guidance present;
- container isolation/runtime verification remained GREEN.

Rollback image/tag and the pre-migration `cp -a` AGENTS copy remain available.

## Authority in force

- `requirements/MANAGED_PERSISTENT_AGENTS.md`
- `docs/DECISIONS.md#D8`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D12`
- `docs/DECISIONS.md#D23`
- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md`

## Integration state

The workstream integration target is `main`.

At the M02 close refresh, current `main` is still exactly the workstream base `4c4da56e1c7db6d0cfc69e170ada3800db185c28`; no target reconciliation/rebase is required.

The distinct manifest-owned final-integration review is still required by the workstream contract before PR #6 may be integrated.

## Next durable starting point

Complete the manifest-owned independent final-integration review for the exact refreshed immutable workstream subject. After GREEN, re-read `main`; if it is unchanged or compatibility remains GREEN, continue Close through PR finalization and target-side terminal reconciliation.

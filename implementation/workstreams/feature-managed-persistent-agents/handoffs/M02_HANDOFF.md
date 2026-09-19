# M02 handoff — production activation and live verification

Status: **GREEN acceptance / final integration review GREEN / merge pending**
Workstream: `feature-managed-persistent-agents`
Milestone: `M02`

## Accepted checkpoint

Repository implementation source remains the independently reviewed managed-AGENTS subject:

`elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`

M02 operational result is durably recorded by:

- deployment-readiness evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_DEPLOYMENT_READINESS_2026-09-20.md`;
- independent M02-T01 review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_INDEPENDENT_REVIEW_2026-09-20.md`;
- authorized production activation evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T02_PRODUCTION_ACTIVATION_2026-09-20.md`;
- final-integration independent review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/FINAL_INTEGRATION_INDEPENDENT_REVIEW_2026-09-20.md`.

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

The final-integration reviewer independently re-read the same live image/health/managed-state hashes and current-block verification without mutating production.

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

At final-integration review, current `main` remained exactly the workstream base `4c4da56e1c7db6d0cfc69e170ada3800db185c28`; no target reconciliation/rebase was required.

The distinct manifest-owned final-integration review for subject `2c98036912e62c09db48fd0f06a819313d842aaa` is GREEN. Commits after that subject are limited to review/closure bookkeeping and do not change workstation behavior or the accepted workstream acceptance surface.

## Next durable starting point

Immediately re-read `main` and PR #6, verify the final-integration review coverage remains valid for the unchanged workstream behavior/acceptance surface, then integrate into `main`. After the actual merge, reconcile only merge-result-dependent manifest/Task Board/handoff fields from target-side state and verify the terminal namespaced workstream package.

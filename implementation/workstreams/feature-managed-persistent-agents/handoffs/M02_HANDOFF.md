# M02 handoff — production activation and live verification

Status: **DONE / integrated to main**
Workstream: `feature-managed-persistent-agents`
Milestone: `M02`

## Accepted checkpoint

Repository implementation behavior remains the independently reviewed managed-AGENTS subject:

`elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`

M02 acceptance is durably supported by:

- deployment-readiness evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_DEPLOYMENT_READINESS_2026-09-20.md`;
- independent M02-T01 review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T01_INDEPENDENT_REVIEW_2026-09-20.md`;
- authorized production activation evidence: `implementation/workstreams/feature-managed-persistent-agents/evidence/M02_T02_PRODUCTION_ACTIVATION_2026-09-20.md`;
- final-integration independent review: GREEN, `implementation/workstreams/feature-managed-persistent-agents/evidence/FINAL_INTEGRATION_INDEPENDENT_REVIEW_2026-09-20.md`.

## Achieved state

Production runs exact candidate image:

`sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`

The persistent global AGENTS target contains one current workstation-managed block while preserving the independently managed `codex_workflow` region byte-for-byte.

Accepted live verification proved:

- health/runtime GREEN after two tracked recreates;
- bounded managed-block verification GREEN;
- `codex_workflow` suffix SHA unchanged at `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- full AGENTS SHA `c31f5cd8a9fd9a231c557de07ae472b1f3e2a18e58936e8db2138a7b24da99dd` unchanged across the second recreate;
- image-owned X11/ydotool guidance present;
- container isolation/runtime verification GREEN.

The final-integration reviewer independently re-read the same live image/health/managed-state hashes and current-block verification without mutating production.

Rollback image/tag and the pre-migration `cp -a` AGENTS copy remain available.

## Authority in force

- `requirements/MANAGED_PERSISTENT_AGENTS.md`
- `docs/DECISIONS.md#D8`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D12`
- `docs/DECISIONS.md#D23`
- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md`

## Final integration

The distinct manifest-owned final-integration review for subject `2c98036912e62c09db48fd0f06a819313d842aaa` is GREEN.

After that reviewed subject, the source branch changed only by review/closure bookkeeping; workstation behavior and the accepted workstream acceptance surface did not change.

Immediately before merge, `main` was re-read and remained exactly the original workstream base. CI run #92 on exact source head `354bc99f88b1fc1bf4c7118a48433405d40f95cb` completed GREEN for source validation, Dockerfile checks and secret scan.

PR #6 merged exact source head `354bc99f88b1fc1bf4c7118a48433405d40f95cb` into `main`.

Final integration result:

`elmakus/chatgpt-ce-workstation@63a6fa73410d0b9c9da6bf346736520927e02a0c`

## Terminal recovery

The namespaced workstream manifest, Task Board, Cards, evidence and handoffs are present on `main`. Manifest and Task Board retain the original source branch as provenance.

No Card, Research, review, authorization or integration obligation remains for this workstream after target-side closure reconciliation.

Future recovery starts from current workflow `main`, project `PROJECT.md`, and this namespaced workstream package on `main`.

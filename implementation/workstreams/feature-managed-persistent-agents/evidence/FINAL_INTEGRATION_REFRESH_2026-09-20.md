# Final-integration refresh evidence — managed persistent AGENTS

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Integration target: `main`
PR: #6

## Refresh result

The first final-integration refresh was performed after M02 production acceptance became GREEN.

Current integration target `main` is exactly:

`4c4da56e1c7db6d0cfc69e170ada3800db185c28`

This is identical to the workstream manifest base ref. The target has not moved, so no rebase, merge, retarget or behavioral reconciliation is required.

PR #6 is open, draft, base `main`, head `feat/managed-persistent-agents`, and GitHub currently reports it mergeable.

## Workstream behavior identity

The independently reviewed implementation source remains:

`00c32fa9f34229e2c227352f4891a7a64f119d35`

Comparison from that implementation subject to the refreshed workstream branch shows only selected-workstream Task Board/manifest/Card/evidence/handoff artifacts. No workstation source, Dockerfile, Compose, defaults, rootfs, reconciler, validation or runtime-verification source changed after the reviewed implementation subject.

Therefore the workstream-owned implementation behavior is unchanged from the independently reviewed M01 source.

## Acceptance surface

The refreshed final-integration acceptance surface includes:

- approved requirements R1-R12 and decisions D8/D10/D12/D23;
- GREEN M01 implementation evidence and independent review;
- GREEN M02-T01 exact-candidate deployment-readiness evidence and independent review;
- explicit production-write authorization before M02-T02 execution;
- GREEN M02-T02 production activation evidence;
- exact reviewed candidate image deployed;
- two tracked recreates with `WORKSTATION_RUNTIME_GREEN`;
- one current workstation-managed AGENTS block matching the image payload;
- byte-identical preserved `codex_workflow` suffix;
- live content-idempotency across the second recreate;
- retained rollback image and pre-migration AGENTS copy;
- namespaced M01 and M02 cumulative handoffs;
- no target-side integration drift.

## Final-integration review decision

Manifest final-integration review requirement is `RECOMMENDED`.

Existing independent reviews do not cover the whole refreshed acceptance surface because the live M02-T02 result occurred after those verdicts. Exact stronger-review reuse is therefore not valid.

Freeze a distinct manifest-owned final-integration review for the immutable workstream subject produced by this refresh evidence commit. No final-target merge may occur before that review is GREEN and `main` is re-read immediately before integration.

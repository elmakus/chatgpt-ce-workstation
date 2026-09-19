# Final-integration independent review — managed persistent AGENTS

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Review owner: `implementation/workstreams/feature-managed-persistent-agents/WORKSTREAM.yaml`
Exact reviewed subject: `elmakus/chatgpt-ce-workstation@2c98036912e62c09db48fd0f06a819313d842aaa`
Verdict: **GREEN**

## Authority and acceptance reviewed

- `requirements/MANAGED_PERSISTENT_AGENTS.md` R1-R12 and acceptance outcomes.
- `docs/DECISIONS.md#D8`, `#D10`, `#D12`, `#D23`.
- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md` M01/M02 outcomes and M02 authorization/rollback/live-verification contract.
- Manifest-owned final-integration acceptance surface frozen by `FINAL_INTEGRATION_REFRESH_2026-09-20.md`.
- Selected workstream Task Board, M01/M02 evidence, independent Card reviews, and cumulative handoffs.

## Independent inspection

- The exact workstream diff from base `4c4da56e1c7db6d0cfc69e170ada3800db185c28` to the reviewed subject contains the managed-AGENTS implementation plus its workstream authority/state/evidence package.
- Comparing independently reviewed M01 implementation subject `00c32fa9f34229e2c227352f4891a7a64f119d35` to final-integration subject `2c98036912e62c09db48fd0f06a819313d842aaa` shows only selected-workstream Task Board/manifest/Card/evidence/handoff files. No workstation source, Dockerfile, defaults, rootfs, reconciler, source-validation or runtime-verification code changed after M01 review.
- The reconciler updates only one valid workstation-owned marker span, or one exactly recognized legacy prefix, preserving bytes outside that owned region. Symlink/non-regular targets, unrecognized unmarked content, and malformed/duplicate/unmatched markers fail closed without rewriting the target.
- Container init invokes reconciliation only when `INSTALL_GLOBAL_AGENTS=1`; runtime verification uses bounded `--check` rather than dumping unrelated persistent content.
- GitHub Actions run `35472727638` for exact M01 implementation subject completed successfully.
- Current `main` remains exactly `4c4da56e1c7db6d0cfc69e170ada3800db185c28`, identical to the workstream base. PR #6 is open, draft, base `main`, head `feat/managed-persistent-agents`, and currently mergeable.

## Independent bounded production readback

No production mutation was performed by this review.

Current production readback on Tower confirms:
- container `3233689be534517a78763b2f986e8ebd4ff856db809f728573d2ae1ed9ebb620`;
- image `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`;
- health `healthy`;
- persistent AGENTS SHA-256 `c31f5cd8a9fd9a231c557de07ae472b1f3e2a18e58936e8db2138a7b24da99dd`;
- size/mode/uid/gid `5338/0644/99/100`;
- workstation markers `1/1`;
- `codex_workflow` markers `1/1`;
- `codex_workflow` suffix SHA-256 `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- bounded reconciler `--check` reports the current managed workstation block;
- image-owned payload contains the integrated ydotool guidance.

These values match the accepted M02-T02 production evidence and independently confirm the live accepted state without exposing unrelated AGENTS content.

## Findings

No blocking or acceptance-relevant defect was found in the reviewed final-integration subject or acceptance surface.

The manifest-owned final-integration review is GREEN. Before actual integration, the workflow must still re-read the current integration target and apply the normal integration-refresh/Close contract.

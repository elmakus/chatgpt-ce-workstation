# M02-T01 independent review — exact deployment candidate

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Card: `M02-T01`
Review owner: `implementation/workstreams/feature-managed-persistent-agents/TASK_BOARD.yaml`
Exact reviewed subject: `elmakus/chatgpt-ce-workstation@8f9f4f22c0954811707ac4eb581f4d255af864cf`
Verdict: **GREEN**

## Authority reviewed

- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md#milestone-m02--production-activation-and-live-verification`.
- `requirements/MANAGED_PERSISTENT_AGENTS.md` R1-R12.
- `docs/DECISIONS.md#D8`, `#D10`, `#D12`, `#D23`.
- Stable Card contract `implementation/workstreams/feature-managed-persistent-agents/cards/M02-T01.md`.
- Accepted predecessor M01 subject `00c32fa9f34229e2c227352f4891a7a64f119d35` and its GREEN independent review.

## Independent inspection

The exact immutable review subject was inspected independently of the implementing-session narrative.

- Comparing M01 reviewed subject `00c32fa9f34229e2c227352f4891a7a64f119d35` to M02 review subject `8f9f4f22c0954811707ac4eb581f4d255af864cf` shows only workstream Task Board/manifest/Card/evidence/handoff changes; no workstation source, Dockerfile, Compose, defaults, rootfs or container-script source changed. The deployable workstation source is therefore behaviorally identical to the independently reviewed M01 source.
- The tracked `scripts/build.sh` path validates the current checkout and builds `workstation` through `docker compose build --pull workstation`; it does not invoke `scripts/update.sh`.
- Independent execution of `bash scripts/validate-source.sh` on the exact detached M01 worktree returned 9/9 managed-AGENTS fixtures GREEN and `SOURCE_VALIDATION_GREEN`.
- The exact detached worktree still resolves to `00c32fa9f34229e2c227352f4891a7a64f119d35` and is clean.
- Candidate image `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830` exists locally and `chatgpt-ce-workstation:local` still resolves to that exact content-addressed image.
- The pre-managed production image `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad` also remains locally available for rollback.
- Current production readback remains exactly the recorded baseline: container `ade19cd953f95afb69abe00094e453e389d92616e2b17ba507812b852dc6ae63`, pre-managed image `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`, health `healthy`, and `INSTALL_GLOBAL_AGENTS=1`.
- Compose identity readback is `project=chatgpt-ce-workstation`, `service=workstation`, config `/mnt/user/projects/chatgpt-ce-workstation/compose.yaml`, working directory `/mnt/user/projects/chatgpt-ce-workstation`.
- Persistent AGENTS readback used bounded hashes/counts/stat only. Full SHA-256 remains `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`, size `4458`, mode/uid/gid `0644/0/0`, known legacy-prefix SHA-256 `d6eb6be5954b6dbd7d747c20e47e3df5a4b4402a34eb32c7274a38d9c92b18c2`, workstation marker counts `0/0`, and `codex_workflow` marker counts `1/1`.
- The independently managed `codex_workflow` region begins at the recorded line boundary immediately after the legacy prefix separator; hashing from that exact boundary reproduces `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126` without exposing unrelated file content.
- No production recreate, restart, persistent AGENTS write or backup creation was performed during this review.

## Rollback/deployment capsule assessment

The M02-T01 evidence defines a bounded live-write procedure for M02-T02: re-read and require the reviewed baseline/candidate identity, retain the pre-managed image under a rollback tag, create and verify a timestamped `cp -a` AGENTS backup before migration, recreate only through the tracked deployment path, verify health/runtime and managed-region preservation, prove live idempotency with a second reconciliation cycle, and retain rollback assets until M02 acceptance is GREEN.

This is consistent with the M02 plan and R12 authorization boundary. Any baseline or candidate drift must return to preparation/review rather than being reconciled manually.

## Findings

No blocking or acceptance-relevant defect was found in M02-T01.

M02-T01 satisfies the last reversible deployment-readiness checkpoint. This GREEN review does **not** authorize the M02-T02 production persistent-file/container write; that remains an explicit current-user authorization gate.

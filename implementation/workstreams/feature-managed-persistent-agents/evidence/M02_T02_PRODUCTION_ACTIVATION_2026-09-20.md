# M02-T02 production activation and live verification

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Card: `M02-T02`
Production deployment performed: **yes, explicitly user-authorized**

## Authorization

Immediately before execution, the user explicitly authorized the production deployment/live write for M02-T02.

The Card was moved through `ready` to `in_progress` only after that current authorization and after a fresh baseline/candidate readback matched the independently reviewed M02-T01 capsule.

## Pre-write revalidation

Exact reviewed source/worktree remained:

- source subject: `00c32fa9f34229e2c227352f4891a7a64f119d35`;
- detached worktree clean;
- candidate image/tag: `chatgpt-ce-workstation:local` -> `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`;
- production container before migration: `ade19cd953f95afb69abe00094e453e389d92616e2b17ba507812b852dc6ae63`;
- production image before migration: `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`;
- health: `healthy`;
- pre-migration AGENTS SHA-256: `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`;
- known legacy-prefix SHA-256: `d6eb6be5954b6dbd7d747c20e47e3df5a4b4402a34eb32c7274a38d9c92b18c2`;
- workstation markers: `0 / 0`;
- `codex_workflow` markers: `1 / 1`;
- `codex_workflow` suffix SHA-256: `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- mode/uid/gid: `0644 / 0 / 0`.

Effective Compose config from the exact reviewed worktree resolved the expected image, container, home/projects binds and `INSTALL_GLOBAL_AGENTS=1`; its bounded native-upstream value matched the running container.

## Rollback assets

Before first migration:

- rollback image tag: `chatgpt-ce-workstation:rollback-pre-managed-agents`;
- rollback image ID: `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`;
- rollback AGENTS copy: `/mnt/user/appdata/chatgpt-ce-workstation/home/.codex/AGENTS.md.pre-managed-20260919T233404Z`;
- rollback-copy SHA-256: `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`;
- rollback-copy mode/uid/gid: `0644 / 0 / 0`.

The rollback image and file copy are retained through acceptance.

## First recreate and migration

Executed from the exact reviewed detached worktree:

- `bash scripts/run.sh --recreate`;
- `bash scripts/wait-healthy.sh`;
- `bash scripts/verify-runtime.sh`.

Results:

- container recreated successfully on exact candidate image `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`;
- health: `healthy`;
- `WORKSTATION_RUNTIME_GREEN`;
- bounded reconciler `--check`: current workstation block verified;
- workstation marker counts: `1 / 1`;
- `codex_workflow` marker counts: `1 / 1`;
- preserved `codex_workflow` suffix SHA-256 remained `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- migrated full AGENTS SHA-256: `c31f5cd8a9fd9a231c557de07ae472b1f3e2a18e58936e8db2138a7b24da99dd`;
- migrated size: `5338` bytes;
- resulting mode/uid/gid: `0644 / 99 / 100`, consistent with the reconciler's accepted persistent-home ownership behavior;
- deployed image payload SHA-256: `fb5dc880ec0c01c10791115a061ed6cca395e18c17ccf87bdca893a73e4d7e63`;
- image-owned payload contains the integrated ydotool guidance.

No manual edit or whole-file overwrite was used; migration occurred only through container initialization.

## Second recreate / live idempotency

Executed the same tracked sequence again:

- `bash scripts/run.sh --recreate`;
- `bash scripts/wait-healthy.sh`;
- `bash scripts/verify-runtime.sh`.

Final readback:

- final container: `3233689be534517a78763b2f986e8ebd4ff856db809f728573d2ae1ed9ebb620`;
- image: `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`;
- health: `healthy`;
- `WORKSTATION_RUNTIME_GREEN`;
- full AGENTS SHA-256 remained exactly `c31f5cd8a9fd9a231c557de07ae472b1f3e2a18e58936e8db2138a7b24da99dd`;
- size remained `5338` bytes;
- mode/uid/gid remained `0644 / 99 / 100`;
- workstation marker counts remained `1 / 1`;
- `codex_workflow` marker counts remained `1 / 1`;
- `codex_workflow` suffix SHA-256 remained exactly `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- bounded reconciler `--check` again verified the current workstation block.

Therefore the live reconciliation is content-idempotent and preserves the independently managed `codex_workflow` region byte-for-byte.

## Result

M02-T02 acceptance is GREEN.

The production workstation now runs the exact independently reviewed candidate image with the managed persistent global AGENTS lifecycle active. The accepted foreign-content preservation, current managed payload, X11/ydotool guidance, health/runtime boundary and live idempotency requirements are verified. Rollback assets remain available.

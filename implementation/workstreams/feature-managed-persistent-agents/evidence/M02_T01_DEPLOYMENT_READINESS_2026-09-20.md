# M02-T01 deployment-readiness evidence

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Card: `M02-T01`
Production deployment performed: **no**

## Exact source identity

The candidate was prepared from the detached, clean worktree:

- worktree: `/tmp/chatgpt-ce-managed-agents-00c32fa9f34229e2c227352f4891a7a64f119d35`
- HEAD: `00c32fa9f34229e2c227352f4891a7a64f119d35`
- status: `clean`

This is the exact M01 implementation subject that received GREEN independent review.

No `scripts/update.sh` invocation and no explicit upstream-refresh token was used for this activation preparation. The tracked `bash scripts/build.sh` path was used.

## Pre-build production baseline

Running workstation before build:

- container: `ade19cd953f95afb69abe00094e453e389d92616e2b17ba507812b852dc6ae63`
- image: `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`
- health: `healthy`
- `INSTALL_GLOBAL_AGENTS=1`

Persistent target `/mnt/user/appdata/chatgpt-ce-workstation/home/.codex/AGENTS.md` was inspected only through bounded hashes/counts/stat:

- full SHA-256: `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`
- size: `4458` bytes
- exact recognized legacy prefix: `3170` bytes
- legacy-prefix SHA-256: `d6eb6be5954b6dbd7d747c20e47e3df5a4b4402a34eb32c7274a38d9c92b18c2`
- workstation-managed start/end marker counts: `0 / 0`
- `codex_workflow` start/end marker counts: `1 / 1`
- `codex_workflow` suffix SHA-256: `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`
- mode: `0644`
- uid/gid: `0 / 0`

The legacy-prefix hash is the exact known-live reference frozen by the M01 fixture suite.

## Validation and build

On the exact reviewed worktree:

- `bash scripts/validate-source.sh` -> GREEN.
- Managed global AGENTS fixture suite -> `Ran 9 tests`, `OK`.
- `SOURCE_VALIDATION_GREEN`.
- `bash scripts/build.sh` -> exit code `0`.

The full tracked image build completed successfully. During packaging, the first `dpkg -i` reported missing package dependencies and the existing Dockerfile fallback `apt-get -f install -y` resolved them; the second `dpkg -i` completed and `codex-desktop` was present. The image build then completed normally.

A pre-existing build warning from the CE upstream packaging path was observed:

`Could not find Chrome browser-client backend allowlist needles - skipping remote-mobile Chrome bridge patch`

It did not stop the build and is outside the managed-AGENTS source slice.

The built image contains the exact M01 repository source while normal unpinned/current build inputs resolved through the repository's existing Dockerfile behavior. Observed build outputs included Muse Code `1.3.0 (1.3.0-R3401.1)` and `codex-chatgpt-web` launcher `v5.0.10`.

## Candidate identity

Prepared deployment candidate:

`sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`

Tag at preparation time:

`chatgpt-ce-workstation:local`

The content-addressed image ID, not the mutable tag alone, is the deployment identity required by M02-T02.

## Post-build production readback

After the image build:

- running container remained exactly `ade19cd953f95afb69abe00094e453e389d92616e2b17ba507812b852dc6ae63`;
- running image remained exactly `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`;
- health remained `healthy`;
- production AGENTS SHA remained exactly `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`.

A final bounded readback also reconfirmed:

- legacy-prefix SHA `d6eb6be5954b6dbd7d747c20e47e3df5a4b4402a34eb32c7274a38d9c92b18c2`;
- workstation marker counts `0 / 0`;
- `codex_workflow` marker counts `1 / 1`;
- `codex_workflow` suffix SHA `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- mode/uid/gid `0644 / 0 / 0`.

Therefore M02-T01 did not recreate the workstation and did not mutate the persistent AGENTS target.

## Reviewed live-deployment capsule for M02-T02

M02-T02 must remain blocked until both conditions hold:

1. M02-T01 receives GREEN independent review.
2. The user gives explicit current authorization for the production persistent-file/container write.

Immediately before the first live write, M02-T02 must re-read and require the same bounded baseline and candidate image ID recorded above. Material drift routes back to preparation/review.

After authorization, the execution capsule is:

1. Re-read the current production container/image/health, full AGENTS SHA, exact legacy-prefix SHA/length, marker counts, `codex_workflow` suffix SHA and file stat. Require consistency with this evidence.
2. Verify `chatgpt-ce-workstation:local` still resolves to candidate image `sha256:c1470837045e2a2c57523174f3f3d7527e00e978576a42cd7af27051a6c2b830`.
3. Before migration, retain the current production image as a rollback tag pointing to `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`, and create a timestamped `cp -a` rollback copy of the persistent AGENTS file. Read back the backup's full SHA/stat and require the SHA to equal `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`.
4. From the exact reviewed worktree, recreate through tracked `bash scripts/run.sh --recreate`.
5. Run `bash scripts/wait-healthy.sh` and `bash scripts/verify-runtime.sh`.
6. Verify boundedly that exactly one workstation-managed block exists and matches the deployed image payload, while the preserved `codex_workflow` suffix SHA remains `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`.
7. Record the migrated full AGENTS SHA and file stat.
8. Perform one additional tracked recreate/reconciliation cycle, then re-run health/runtime verification and require the full AGENTS SHA to remain identical to step 7, proving live idempotency.
9. Keep the rollback copy and rollback image tag until M02 acceptance is GREEN.

If the reconciler reports ambiguity/malformed state or any baseline/candidate identity differs from this reviewed capsule, do not manually overwrite the file; stop and route back to preparation/review.

Rollback, if required before acceptance, is to restore the timestamped `cp -a` AGENTS copy and recreate the workstation using the retained pre-managed image `sha256:4a41e7ee17914c5449d3304aa0965de997679c028fe7600945f69786611bf3ad`, followed by health/readback verification.

## Result

M02-T01 preparation is GREEN from the implementing chat's execution perspective. Because the Card declares independent review `REQUIRED`, it is not terminal and M02-T02 is not executable yet.

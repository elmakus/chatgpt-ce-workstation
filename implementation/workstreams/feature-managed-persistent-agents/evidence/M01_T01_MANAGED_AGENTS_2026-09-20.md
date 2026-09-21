# M01-T01 evidence — managed persistent AGENTS reconciliation

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Card: `M01-T01`
Exact implementation subject: `elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`
PR: #6 (draft)

## Implemented behavior

- Added a repository-owned reconciliation helper with one workstation marker pair:
  - `<!-- chatgpt-ce-workstation-managed-start -->`
  - `<!-- chatgpt-ce-workstation-managed-end -->`
- Fresh targets are seeded as one managed workstation block.
- Existing valid managed targets replace only that block; all bytes outside it are preserved.
- Exact known legacy prefixes are migrated once:
  - the verified current live legacy prefix, frozen at 3170 bytes / SHA-256 `d6eb6be5954b6dbd7d747c20e47e3df5a4b4402a34eb32c7274a38d9c92b18c2`;
  - the exact historical `/workspace` stock variant previously handled by the narrow init migration.
- Unrecognized unmarked targets and malformed/duplicate/unmatched workstation markers fail closed with a manual-reconciliation diagnostic and no content rewrite.
- The old pointwise `sed` migration is removed; init now invokes the bounded reconciler only when `INSTALL_GLOBAL_AGENTS=1`.
- The image carries the current payload plus exact legacy references.
- Runtime verification uses the helper's bounded `--check` mode and does not dump unrelated persistent AGENTS content.

## Exact-subject verification

Executed from an isolated detached worktree at `00c32fa9f34229e2c227352f4891a7a64f119d35` on the Tower host:

- `python3 scripts/test-managed-global-agents.py` → GREEN, 9/9 tests.
- `bash -n rootfs/etc/cont-init.d/10-workstation-init scripts/validate-source.sh scripts/verify-runtime.sh` → GREEN.
- `bash scripts/validate-source.sh` → `SOURCE_VALIDATION_GREEN`.
- `docker buildx build --check --file Dockerfile .` → GREEN, no warnings.
- Validation checkout remained clean after tests.

Fixture coverage includes fresh seed, managed update with exact outside-byte preservation, exact `codex_workflow` preservation, verified live legacy migration, historical `/workspace` legacy migration, ambiguous legacy no-op, duplicate markers no-op, unmatched markers no-op, current-block check, and repeated reconciliation idempotency.

## Read-only live-layout proof

The production persistent file was not modified.

A temporary copy of the actual persistent `~/.codex/AGENTS.md` was reconciled with the exact implementation subject:

- helper result: `migrated`;
- bounded `--check`: GREEN;
- second reconciliation result: `current`;
- the suffix beginning at `<!-- codex-workflow-user-managed-start -->` was byte-for-byte identical before and after migration; preserved suffix SHA-256: `2c62a03b36508a45c112683b74e45076c1d059238423361aecf3844d1c7ac126`;
- production file SHA-256 was identical before and after the test: `a24b186fbac9cba0897d21e28382ba42e91efb747d650c9be724da2ad903a0e4`.

This proves the known live layout is recognized without a production write and that the independently owned Codex Workflow block is preserved exactly.

## CI

GitHub Actions CI run #62 for exact subject `00c32fa9f34229e2c227352f4891a7a64f119d35` completed successfully:

- source-validation: success;
- noVNC desktop workarea semantics: success;
- ShellCheck workstation scripts: success;
- dockerfile-check: success;
- secret-scan: success.

Workflow run id: `35472727638`.

## Scope and safety

No workstation rebuild/recreate, live persistent AGENTS migration, production write, Docker socket, host-root mount, privilege increase, or `codex_workflow` ownership change occurred in M01.

Production activation, rollback execution, live persisted-state verification after activation, and the live-write authorization gate remain M02 work.

# M03 target reconciliation evidence

Workstream head before reconciliation: `851775e5809c99166300045e21f59ce07e764c05`
Current integration target reconciled: `main@04440574afb2d85790301c915e9d7f8c90721021`
Original workstream creation/merge base: `04fb32a47b5bcfbfcf16f6fb77bffbe2a7282acf`

## Reason

The integration target advanced through the independently completed Codex marketplace auto-update workstream. PR #7 became merge-conflicting and GitHub therefore stopped creating new `pull_request` workflow runs for later smart-upstream commits.

## Reconciliation

The target merge produced two textual conflicts:
- `docs/DECISIONS.md`: both concurrent workstreams had independently allocated D24 to different accepted decisions.
- `scripts/validate-source.sh`: both workstreams had added independent validation sections at the same insertion point.

Resolution stayed technical and additive:
- current `main` keeps its already-integrated marketplace decision as D24;
- the unchanged smart-upstream decision is renumbered D25, and smart-upstream-owned durable authority references are reconciled to D25;
- both independent `validate-source.sh` validation sections are preserved;
- automatically merged marketplace source/service changes are retained together with the smart-upstream updater changes.

No accepted requirement, behavior, architecture, upstream policy, production-write boundary, rollback semantics or milestone strategy changed.

## Compatibility verification before merge commit

On Tower in an isolated clone, with both workstreams reconciled but before any production updater execution:
- `bash scripts/test-update-orchestration.sh` — `UPDATE_ORCHESTRATION_TESTS_GREEN`.
- `bash scripts/validate-source.sh` — `SOURCE_VALIDATION_GREEN`; this includes both smart-upstream and Codex marketplace deterministic suites.
- `docker buildx build --check --file Dockerfile .` — GREEN, no warnings.
- full CI-equivalent ShellCheck, including explicit bash handling for s6 `with-contenv` files — GREEN.
- `git diff --check --cached` — GREEN and no conflict markers/unmerged paths remained.

No real workstation recreate, promotion or rollback was performed.

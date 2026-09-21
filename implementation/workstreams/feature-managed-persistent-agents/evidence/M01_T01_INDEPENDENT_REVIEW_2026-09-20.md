# M01-T01 independent review — managed persistent AGENTS reconciliation

Date: 2026-09-20
Workstream: `feature-managed-persistent-agents`
Card: `M01-T01`
Review owner: `implementation/workstreams/feature-managed-persistent-agents/TASK_BOARD.yaml`
Exact reviewed subject: `elmakus/chatgpt-ce-workstation@00c32fa9f34229e2c227352f4891a7a64f119d35`
Verdict: **GREEN**

## Authority reviewed

- `requirements/MANAGED_PERSISTENT_AGENTS.md` R1-R12, with M01 owning R1-R11 plus the source-side R12 boundary.
- `planning/MANAGED_PERSISTENT_AGENTS_MASTER_PLAN.md#milestone-m01--managed-reconciliation-source`.
- `docs/DECISIONS.md#D8`, `#D10`, `#D12`, `#D23`.
- Stable Card contract `implementation/workstreams/feature-managed-persistent-agents/cards/M01-T01.md`.

## Independent inspection

The exact source at the immutable subject was inspected independently from the implementing-session narrative.

- `scripts/container/reconcile-global-agents.py` defines one explicit workstation marker pair, writes only a freshly seeded managed file, an existing workstation-owned span, or one exactly recognized legacy prefix, and leaves symlink/non-regular, malformed/duplicate/unmatched marker, and unrecognized unmarked targets unchanged with diagnostics.
- Existing bytes outside a valid workstation block are spliced back unchanged. Exact legacy migration replaces only the recognized prefix and preserves the remaining suffix, which protects the independently owned `codex_workflow` region and unrelated trailing content for the accepted live layout.
- Atomic replacement applies the expected codex uid/gid and `0644` mode without adding privilege, Docker-socket, host-root, or host-control surfaces.
- `10-workstation-init` invokes the reconciler only under `INSTALL_GLOBAL_AGENTS=1` and replaces the former pointwise `/workspace` migration with the bounded exact-reference path.
- The image installs the current payload plus both exact legacy references, source validation requires the reconciler/wiring/fixtures, and runtime verification uses bounded `--check` rather than dumping unrelated persistent content.
- Fixture coverage exercises fresh seed/idempotency, valid managed update with outside-byte preservation, exact `codex_workflow` preservation, known live legacy migration, historical `/workspace` legacy migration, ambiguous legacy no-op, duplicate markers no-op, unmatched markers no-op, and current-block verification.
- The known live legacy reference is frozen by length and SHA-256 in the test suite.

## Exact-subject evidence verified

GitHub Actions CI run #62 / run id `35472727638` is attached to exact subject `00c32fa9f34229e2c227352f4891a7a64f119d35` and completed successfully.

Independent CI readback confirms:
- source-validation: success;
- managed global AGENTS fixtures: `Ran 9 tests`, `OK`;
- `SOURCE_VALIDATION_GREEN`;
- ShellCheck step: success;
- dockerfile-check: success;
- secret-scan: success.

The implementation evidence's read-only live-copy proof is consistent with the reviewed code and M01's no-production-write boundary: the accepted legacy prefix was recognized, the preserved `codex_workflow` suffix stayed byte-identical, second reconciliation was current/idempotent, and the production AGENTS SHA remained unchanged.

## Findings

No blocking or acceptance-relevant defect was found in the reviewed M01 source subject.

M02 production activation remains a separate explicit live-write/deployment authorization gate and is not authorized by this GREEN review.

# Managed persistent AGENTS Master Plan

Status: **draft**
Plan revision: **managed-persistent-agents-R1**
Date: 2026-09-19
Independent plan review: **RECOMMENDED**

## Goal and authority

Implement the approved managed lifecycle for the persistent global Codex policy without taking ownership of the whole `~/.codex/AGENTS.md`.

Authority:
- `requirements/MANAGED_PERSISTENT_AGENTS.md`
- `docs/DECISIONS.md#D8`
- `docs/DECISIONS.md#D10`
- `docs/DECISIONS.md#D12`
- `docs/DECISIONS.md#D23`

The current verified production file is an unmarked legacy workstation policy followed by a distinct `codex-workflow-user-managed` block. Source implementation must not mutate that live file before the explicit deployment/live-write gate.

## Execution strategy

Use one repository-owned reconciliation helper with a testable file-input/file-output contract and call it from container initialization.

The helper should distinguish exactly three normal states:

1. **missing target** — create a fresh file containing the current workstation-managed block;
2. **valid workstation-managed target** — replace only the delimited workstation block and preserve all bytes outside it;
3. **recognized legacy target** — replace only an exactly recognized repository-owned legacy workstation prefix with the managed block and preserve the remainder.

Malformed/duplicate workstation markers or unrecognized unmarked content are safe no-op conditions with a clear diagnostic. They must not become broad text-rewrite heuristics.

The current one-off `/workspace` migration should be retired or subsumed only when the new lifecycle covers its accepted purpose without weakening legacy recognition.

Implementation may choose exact marker strings, helper language/shell structure and optional diagnostic version/hash metadata during JIT refinement.

## Milestone M01 — Managed reconciliation source

### Outcome

Repository source can safely seed, update and conservatively migrate persistent global AGENTS policy using explicit workstation ownership boundaries, with deterministic isolated tests and no production mutation.

### Requirement ownership

R1–R11 and the source-side boundary of R12.

### Planned work packages

- Define the workstation-managed block representation and current image-owned payload.
- Add a reconciliation helper that can operate against an explicit target path for isolated tests and against `~/.codex/AGENTS.md` from container init.
- Encode the known accepted legacy workstation policy shape needed to migrate existing installations without heuristic ownership expansion.
- Integrate reconciliation into the existing `INSTALL_GLOBAL_AGENTS` startup path.
- Preserve file ownership/mode expectations after create/update/migration.
- Replace or retire the old narrow `/workspace` sed migration only after equivalent legacy behavior is covered.
- Add fixture-based tests for fresh seed, managed update, arbitrary outside text, exact `codex_workflow` preservation, current known legacy migration, ambiguous legacy no-op, malformed/duplicate markers and idempotency.
- Extend source validation so the managed lifecycle and safety boundaries cannot silently disappear.
- Extend runtime verification to assert managed/current workstation policy after an authorized deployment without dumping unrelated persistent content.

### Acceptance

- Repository tests exercise every R11 case and are GREEN.
- Reconciliation modifies only the workstation-owned region or an exactly recognized legacy workstation prefix.
- Ambiguous/malformed inputs are byte-identical after the attempted reconciliation.
- Re-running reconciliation against current output is byte-identical.
- The existing `codex_workflow` marker block is preserved exactly in migration/update tests.
- Shell/static/source validation is GREEN.
- No write is made to the production persistent AGENTS file during M01 implementation or review.

### Review

Behavioral persistent-file migration code is reviewable and should receive an independent implementation review before production activation.

## Milestone M02 — Production activation and live verification

### Dependencies

M01 implementation and its required/recommended independent review are GREEN.

### Outcome

The current workstation is rebuilt/recreated with the accepted managed lifecycle, its existing persistent AGENTS file migrates safely, and live verification proves both current workstation policy and preservation of independently managed content.

### Explicit authorization gate

Before any action that can rewrite the currently running workstation's persistent `~/.codex/AGENTS.md`, obtain explicit user authorization for the deployment/live write.

Do not infer this authorization from feature approval, plan approval, implementation approval or review approval.

### Deployment / migration strategy

Before activation:
- capture bounded evidence sufficient to compare the existing workstation policy and the independently managed `codex_workflow` block;
- ensure the candidate image/source exactly matches the reviewed implementation subject;
- retain a practical rollback copy/path for the persistent AGENTS file before first migration.

Then:
- build/recreate through the tracked workstation deployment path;
- let container initialization perform the migration rather than hand-editing production;
- run runtime verification;
- compare the preserved independent block and relevant surrounding content against pre-deployment evidence;
- confirm the workstation-managed block equals the image-owned current payload and includes the integrated X11/ydotool guidance;
- restart/recreate once more if needed to prove live idempotency.

If migration reports ambiguity/malformed state, do not manually overwrite the file as an implicit fallback. Preserve evidence and route the discrepancy through normal correction/recovery.

### Acceptance

- Live target contains exactly one valid workstation-managed block matching the deployed image payload.
- Existing `codex_workflow` managed content is unchanged.
- Unrelated persistent content is preserved.
- X11/ydotool workstation guidance is present through the managed block.
- Reconciliation is idempotent on the live target.
- Workstation health/runtime verification remains GREEN.
- Rollback evidence/path remains available until live acceptance is GREEN.

## Requirement coverage

| Requirement | Owner |
| --- | --- |
| R1 persistent canonical path | M01 |
| R2 explicit workstation ownership | M01 |
| R3 automatic reconciliation | M01, M02 |
| R4 preserve foreign/user content | M01, M02 |
| R5 fresh managed seed | M01 |
| R6 conservative legacy migration | M01, M02 |
| R7 ambiguous legacy fail-closed | M01 |
| R8 malformed managed fail-closed | M01 |
| R9 idempotency | M01, M02 |
| R10 ownership/isolation | M01, M02 |
| R11 validation coverage | M01, M02 |
| R12 deployment/live-write gate | M01 boundary, M02 authorization |

## JIT / execution-prep boundaries

Execution Prep for M01 may select exact markers, helper interfaces, fixture layout and test commands from current source.

Execution Prep for M02 must bind deployment commands, rollback procedure and live verification to the exact reviewed M01 candidate and then-current workstation state. Do not freeze those operational details earlier than necessary.

## Planning audit

GREEN:
- accepted Definition is complete and internally coherent;
- no unresolved product choice affects milestone architecture;
- the plan preserves D12/D23 ownership boundaries;
- production mutation is separated behind an explicit user gate;
- rollback/idempotency and malformed-input behavior are represented;
- every authoritative requirement has milestone coverage;
- no new privilege, host-control or cross-repository ownership is introduced;
- implementation detail is deferred where it does not need strategic freezing.

Independent review remains RECOMMENDED because this is a new behavioral migration plan touching persistent shared user configuration.

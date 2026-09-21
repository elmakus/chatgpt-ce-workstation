# Codex Interrupt Hook Drift Compatibility — Master Plan

Plan revision: `CIH-P1`
Status: `approved`
Review requirement: `RECOMMENDED`
Updated: `2026-09-21`

## Goal and authority

Implement the approved compatibility boundary defined by:

- `requirements/CODEX_INTERRUPT_HOOK_DRIFT.md` R1;
- `docs/DECISIONS.md#D11 — Codex Web GPT included; our fork is the default package source`;
- `docs/DECISIONS.md#D15 — Validation order is part of the architecture`;
- `docs/DECISIONS.md#D25 — Workstation updates resolve latest stable identities before build`;
- `docs/DECISIONS.md#D29 — Native Interrupt-hook disable state is narrowly repairable, while ownership drift remains fail-closed`.

The implementation defect lives in the related fork `elmakus/codex-chatgpt-web`; this workstation workstream owns the accepted behavior, release/integration evidence, and final acceptance.

## Verified execution baseline

At planning time:

- `elmakus/codex-chatgpt-web@2686d2a616864a1bc9cd975901773ab16a54ba47` reports version `5.0.14`;
- the fork's Interrupt-hook verifier rejects `enabled = false` as post-setup drift;
- upstream Codex intentionally allows unmanaged user hooks to be disabled and persists that state as `hooks.state.<key>.enabled = false`;
- the workstation resolver obtains the latest stable fork release plus exact checksum and freezes that identity before build;
- the workstation does not need a permanent source pin to a new fork version when the normal latest-stable resolver is used.

Execution Prep must run the normal Refresh Gate before converting this baseline into concrete Cards.

## Milestone M01 — Bounded fork compatibility repair and release

### Outcome

The fork recognizes the exact native-disabled state as recoverable during explicit route setup/upgrade/recovery, restores the canonical enabled hook, and continues to reject all other ownership drift.

### Requirement ownership

Owns CIH-001 through CIH-006 for source behavior and regression coverage.

### Planned work packages

1. **Classify the exact recoverable state**
   - preserve ordinary status/verification semantics: `enabled = false` remains unhealthy/inconsistent;
   - add a narrow classifier/helper that recognizes only the journal-exact managed Interrupt hook with the native disable override;
   - require every other owned field and journal identity to match exactly before repair is permitted.

2. **Repair only in explicit recovery-capable flows**
   - allow setup/upgrade/recovery to remove or replace the native disable override;
   - immediately re-read/re-verify the resulting hook against journal authority before route startup proceeds;
   - keep arbitrary command/hash/type/timeout/state-key/managed-boundary/structural drift on the existing fail-closed path.

3. **Regression and negative coverage**
   - reproduce the 2026-09-19 forensic shape: exact journal-owned hook + preserved trusted hash + only `enabled = false`;
   - prove setup/upgrade/recovery self-heals that state;
   - prove status before repair remains inconsistent;
   - retain/add negative tests for all non-enable ownership mutations and for malformed/ambiguous state.

4. **Fork integration and release**
   - implement on a dedicated fork branch from refreshed `main`;
   - run the fork's required verification/CI on the exact implementation subject;
   - obtain independent implementation review when required by the execution state;
   - merge the accepted fork change and publish the next exact Linux release through the existing fork release workflow;
   - verify release tag/commit/assets/checksum identity before treating publication as complete.

### Acceptance checkpoint

M01 is GREEN when:

- the exact disabled-only incident state is unhealthy before repair and recoverable only through the allowed explicit flows;
- exact re-verification succeeds after repair;
- unrelated ownership drift still fails closed;
- required fork tests/CI are GREEN on the accepted subject;
- an immutable accepted fork commit is published as a verified Linux release with matching checksums.

## Milestone M02 — Workstation consumption and recurrence verification

### Outcome

The workstation's normal latest-stable update path can resolve the corrected fork release, and the exact historical failure mode no longer strands an active route when validated on a candidate/runtime.

### Dependencies

Depends on M01's verified published release.

### Requirement ownership

Completes CIH-003 and CIH-005 at system-integration level and verifies the recovery invariant from CIH-001/002/004.

### Planned work packages

1. **Resolver/build-path verification**
   - verify `scripts/resolve-upstreams.py` resolves the corrected stable fork release and checksum without a new permanent pin;
   - verify the frozen resolution is accepted by the existing build/install path;
   - do not modify workstation source solely to pin a release unless Refresh Gate evidence proves the normal D25 path cannot consume it.

2. **Exact recurrence smoke**
   - on a disposable/candidate environment, establish the journal-owned Interrupt hook and then inject only the native `enabled = false` state;
   - verify status reports inconsistency before repair;
   - invoke the supported setup/upgrade/recovery path and verify the managed hook returns to journal-exact enabled state;
   - restart/relaunch the relevant runtime path and verify ordinary Sol and chatgpt-web routing are not left pointing at a dead local listener.

3. **Workstream integration evidence**
   - persist exact fork release identity, tests/CI, candidate/runtime evidence, and any workstation source diff actually required;
   - reconcile final workstream review/integration into workstation `main` without treating a live production rollout as implicit.

### Acceptance checkpoint

M02 is GREEN when:

- the corrected release is resolved through the workstation's ordinary D25 latest-stable mechanism;
- the exact disabled-only scenario self-heals through supported recovery and survives the relevant restart path;
- non-recoverable hook drift remains fail-closed;
- ordinary Sol and chatgpt-web routing both function after recovery;
- no manual edit of persistent `~/.codex/config.toml` is required for the verified recurrence test.

## Safety, migration and rollback strategy

- No migration of hook storage or journal format is planned.
- A disabled hook is never silently reclassified as healthy.
- Self-heal is gated by exact journal identity; ambiguity remains fail-closed.
- The existing prior fork release remains the rollback artifact until the corrected release is accepted.
- Workstation D25 candidate/rollback behavior remains the deployment mechanism if a live update is later authorized.
- A live production update of the user's Unraid workstation is **not** implied by source implementation, fork release publication, or workstream merge. It remains an explicit operator live-write/deployment gate.

## Verification strategy

Execution Prep should create concrete Card acceptance covering:

- targeted unit/regression tests around Interrupt hook comparison/repair;
- fork full verification/CI required by the release workflow;
- exact release tag/commit/checksum validation;
- workstation upstream-resolution readback for the corrected release;
- candidate/runtime recurrence smoke for `enabled = false`;
- negative tamper cases proving fail-closed behavior;
- post-recovery routing checks for ordinary Sol and chatgpt-web models.

## Requirement coverage

| Requirement | Owner milestone | Execution path |
|---|---|---|
| CIH-001 | M01 + M02 | Status classifier tests + recurrence smoke |
| CIH-002 | M01 + M02 | Exact-match repair gate + system recurrence smoke |
| CIH-003 | M01 + M02 | Repair/re-read verification + restart validation |
| CIH-004 | M01 + M02 | Negative drift tests + runtime fail-closed check |
| CIH-005 | M01 + M02 | Historical-shape regression + candidate recurrence smoke |
| CIH-006 | M01 | Bounded existing-config implementation; no new managed layer/upstream patch |

## JIT decomposition

Execution Prep may split M01 into implementation/review/release Cards and M02 into resolver/candidate/runtime Cards according to refreshed source and release state.

It may omit a workstation source-change Card if refreshed evidence proves the existing D25 resolver/build path already consumes the corrected release unchanged. It may not weaken D29 or replace the explicit live-deployment gate without returning to Project Definition.

## Planning audit

GREEN:

- approved Definition is coherent and sufficient;
- the plan preserves strict fail-closed ownership outside the one accepted native enablement state;
- release publication and workstation consumption are separated into stable checkpoints;
- all CIH requirements have milestone ownership and an execution path;
- rollback, negative verification, exact recurrence testing, and live-deployment boundaries are explicit;
- the plan uses existing journal, release, resolver, and D25 mechanisms rather than introducing a new config/ownership layer;
- no unresolved research or product choice blocks execution;
- this is a new nontrivial Master Plan and independent review is practical, therefore review is `RECOMMENDED`.

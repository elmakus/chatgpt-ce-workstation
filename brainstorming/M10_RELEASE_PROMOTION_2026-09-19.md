# Brainstorm — Publish and promote M10 stateful Muse runtime

Date: `2026-09-19`
Scope ID: `m10-release-promotion`
Revision: `R1`
Status: `ready_for_definition`

## Problem / goal

The independently accepted M10 stateful Muse runtime exists as source but is not yet published or installed in production. Explore the next scope that publishes that accepted subject through the normal `codex_workflow` release path and promotes the resulting exact release to the workstation.

## Current understanding

### Verified facts

- Current production remains `codex_workflow v1.1.17-private.11` at `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8` with active `muse-max`.
- M10 is independently GREEN at `cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`.
- The M10 subject is 17 commits ahead of the current production/main release commit and has that release commit as its merge base.
- The M10 subject still reports version `1.1.17-private.11`; it has not cut the next release metadata.
- M10 changed Muse runtime/session code, Muse-focused tests, and workflow documentation. It did not change `runtime/compute_profiles.py` or worker allocation files.
- The existing regression explicitly verifies that `plus`, `luna-xhigh`, and `pro-x5` retain their prior Codex-backed allocations. The same allocation regression remained GREEN on the accepted M10 subject.
- Shared workflow documentation changed only to describe the new stateful Muse lifecycle conditionally under `muse-max`; the internal Codex lifecycle for `plus`, `luna-xhigh`, and `pro-x5` remains the documented path.

### Existing accepted decisions

- M10 source behavior is already accepted and independently reviewed.
- M10 intentionally excluded release and production promotion.
- Production promotion must preserve exact release-subject identity and use the normal owner release/update channel.
- User explicitly chose to begin a new scope whose purpose is to publish and promote the accepted M10 stateful runtime.

### Assumptions to verify

- Immediately before release preparation, `codex_workflow` main is still the current production release commit and the M10 branch can still be integrated without a semantic reconciliation.
- The next private release identifier must be selected from fresh release/tag state rather than assumed now.
- Exact release-candidate regressions and live production validation should be repeated where release metadata or deployed-runtime identity makes earlier source-only evidence insufficient.

## Ideas / alternatives considered

### Option A — exact M10 promotion pipeline

Treat the accepted M10 subject as the behavioral source checkpoint, create only the release-synchronization change needed for the next version, independently review the exact release candidate, validate the exact candidate live, publish it, then update production and run bounded production readback/stateful Muse smoke.

This preserves the strongest exact-subject lineage and avoids reopening M10 behavior.

### Option B — publish M10 subject directly without a fresh release-candidate gate

This is simpler but weaker because the source subject still carries the old release version and publication/promotion would create a materially different release subject without an exact release-stage gate.

Tentative preference: Option A.

## Trade-offs / questions

- Release version should be chosen JIT from current tag/release state.
- Production smoke should prove the installed release identity, active `muse-max`, and at least one stateful Muse reuse path without modifying unrelated profiles.
- Any unexpected main-branch divergence or behavioral correction must invalidate direct promotion and route through normal correction/review instead of silently rebasing the accepted subject.

## Research needed

None currently. The required release lineage, production state, and profile-isolation facts are already verified sufficiently to formalize the scope.

## Open questions

No product-level question blocks Definition. Exact release number and detailed Card decomposition are implementation/planning-time choices.

## Outcome of this session

- Tentative conclusions: use an exact-subject release pipeline based on accepted M10, with fresh release metadata, exact-candidate review/live validation, publication, production update, and bounded production stateful-runtime smoke.
- Explicit user/product choices to promote through Project Definition: proceed with a new scope to publish and promote M10 to production; do not intentionally alter the non-`muse-max` profile allocations.
- Research still needed: none.
- Open questions: none that block Definition.
- Next phase/action: `ready for definition`
- Definition promotion authorization: `pending`
- Definition promotion subject: `none`

> Nothing in this file becomes accepted requirement/decision authority by itself. Project Definition owns promotion into canonical `requirements/` and `decisions/`. When the selected policy requires explicit user phase promotion, only an explicit user instruction may set `Definition promotion authorization: user_authorized`, and the authorization must name the exact current `<scope-id>@<revision>`. Any material change to the exploratory scope before Definition starts creates a new revision and resets authorization to `pending`.

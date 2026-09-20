# Independent plan review — Smart upstream updates R1

Plan revision: smart-upstream-updates-R1
Review requirement: RECOMMENDED
Review state: red
Review subject: elmakus/chatgpt-ce-workstation@b9aac41b7886ddc084b3ba469a1a7687bcf101b1
Reviewed plan: planning/SMART_UPSTREAM_UPDATES_MASTER_PLAN.md
Review evidence: RED — bounded plan-only correction required; accepted Definition/decisions remain sufficient.

## Review scope

Independently review the exact immutable plan subject above against:

- approved `requirements/SMART_UPSTREAM_UPDATES.md`;
- accepted `docs/DECISIONS.md#D2`, `#D4`, `#D5`, `#D6`, `#D10`, `#D11`, `#D15`, `#D16` and `#D25`;
- the current workstation build/update baseline referenced by the plan;
- only the upstream/source evidence materially needed to assess feasibility, trust boundaries and update safety.

Audit especially whether the plan:

- preserves Ubuntu 24.04 LTS while making normal upstream policy latest trusted stable/current;
- separates CE Git freshness from the signed OpenAI ChatGPT package freshness without weakening CE's authenticity contract;
- replaces timestamp-only invalidation with reproducible resolved identities;
- states realistic Docker cache semantics rather than promising impossible layer reuse;
- keeps `update.sh` as the one normal updater and `build.sh` as a lower-level exact/development primitive;
- provides inspectable exact candidate provenance without secrets;
- leaves production untouched on resolution/build/pre-promotion failure;
- retains and verifies a deterministic previous-image rollback path on post-promotion failure;
- preserves disabled runtime self-updaters and existing container isolation;
- places real workstation recreate/fault injection behind explicit deployment/live-write authorization;
- covers all approved requirements without freezing vendor-specific mechanisms prematurely.

A GREEN verdict means the plan may be approved and routed to Execution Prep for M01. A RED verdict must identify whether correction belongs to Planning, Project Definition or Research.

## Independent review findings

### RED-1 — D15/D4 deployment validation is not fully carried into the plan

Severity: P1  
Correction owner: Strategic Planning

The immutable subject correctly separates source/build validation, production promotion and rollback, but M03/M04 do not preserve the full accepted validation discipline from D15/D4.

Evidence from the reviewed baseline:
- `scripts/build.sh` performs `scripts/validate-source.sh` and then builds; the plan does not explicitly restore/require the accepted host-preflight checkpoint before the image build.
- `scripts/verify-runtime.sh` verifies the desktop substrate, mounts/isolation, launchers, Muse CLI surface and related runtime invariants, but it does not perform the D15 post-recreate regression checks for native CE/Android Remote, Codex Web GPT configuration/model routing, or Agent Workspace / Computer Use.
- M04 acceptance currently stops at health/runtime/provenance/rollback/isolation outcomes and therefore does not independently require those D15/D4 regression checks after the significant upstream update architecture is activated.

Required correction:
- carry the accepted D15 order into M03/M04, including host preflight before image build where applicable;
- make M04 explicitly require the upstream-sensitive CE/Android Remote regression check and the Codex Web GPT + Agent Workspace/Computer Use checks in the accepted order (conditional only where D4/D15 already permit that distinction).

### RED-2 — Ubuntu base-image freezing must be unambiguous before build

Severity: P1  
Correction owner: Strategic Planning

R5 requires every moving upstream to be resolved to the strongest practical immutable identity before candidate build and requires the build to consume that frozen identity.

The plan's M01 JIT question currently allows considering whether the `ubuntu:24.04` digest can be delegated to BuildKit "while still being recorded". Recording a digest only as a by-product of an unconstrained build would not satisfy the approved resolve-first/freeze-first contract and could create a race between resolution and build.

Required correction:
- require the frozen resolution set to bind the Ubuntu 24.04 base to an exact digest (or another demonstrably equivalent immutable pre-build identity);
- allow BuildKit to perform resolution mechanics only if the resulting identity is fixed before the candidate build consumes it and is included in the exact candidate provenance.

### Areas reviewed GREEN

- Ubuntu remains on the 24.04 LTS family while ordinary upstream policy is latest trusted stable/current.
- CE Git freshness and the official OpenAI package freshness are modeled independently and CE's signed-package trust contract is preserved.
- Timestamp-only cache invalidation is removed from the target design and cache semantics are described realistically.
- `update.sh` remains the one normal updater and `build.sh` remains the lower-level exact/development primitive.
- Candidate provenance, explicit overrides, fail-closed resolution, pre-promotion safety, deterministic rollback, disabled runtime self-updaters and container-isolation constraints are covered.
- Requirement ownership covers R1-R16.
- Current upstream evidence supports feasibility without a Research detour: Agent Workspace has moved beyond the workstation's 0.3.2 default, CE documents a signed stable APT trust chain and exact upstream package metadata, and the current s6-overlay line remains resolvable as a normal stable release.

## Verdict

RED — both findings are bounded plan-only defects inside already accepted Project Definition/architecture authority. Route to Strategic Planning; no Project Definition change and no Research obligation is required.

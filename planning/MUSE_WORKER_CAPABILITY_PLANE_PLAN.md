# Muse worker capability and skill plane plan

Status: **approved**
Plan revision: **muse-worker-capability-plane-R2**
Date: 2026-09-20
Independent plan review: **RECOMMENDED**

## Goal and authority

Operationalize the accepted Muse-owned external capability plane and shared skill catalog in the workstation while integrating with the now-accepted structured Muse capability-hint contract instead of relying on ad-hoc task-capsule prose.

Workstation authority:
- `requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`
- `docs/DECISIONS.md#D21`
- `docs/DECISIONS.md#D25`
- `docs/DECISIONS.md#D26`

Relevant workstation evidence:
- `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`
- `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`

Accepted cross-repository authority now shaping this plan:
- `elmakus/muse-capability-admin@8aecaa42d0ffd40efa2342b5bbace85fcc976d7e`
- `requirements/MUSE_CAPABILITY_ADMIN.md`
- `decisions/MCA-DEC-001-STRUCTURED_CAPABILITY_HINTS.md`
- `decisions/MCA-DEC-002-ADMIN_AUTH_AND_SECRET_REUSE.md`
- approved `planning/MASTER_PLAN.md` revision `MCA-P1`, independently reviewed GREEN.

R2 supersedes the execution assumption from R1 that ordinary task text alone should be the baseline capability-hint mechanism. The accepted cross-repository Definition now requires a structured per-invocation `MuseCapabilityHints` contract owned by `elmakus/codex_workflow`.

## Execution strategy

Keep ownership aligned with repository boundaries:

- **Workstation** owns Muse installation, persistent `/home/codex` substrate, deployment/runtime persistence, workstation-side secret-delivery mechanisms when actually required, and workstation integration/verification.
- **Muse** owns its own native skill discovery/loading, MCP clients, OAuth/config state and tool execution.
- **codex_workflow** owns `muse-max` orchestration, `MuseWorkerInvocation`, structured capability-hint normalization/CLI/prompt semantics, resume behavior and Main-side Muse delegation guidance.
- **muse-capability-admin** owns the progressive-disclosure Codex administrative skill for inspect/install/configure/update/validate/remove operations against Muse-side capabilities.
- **Codex Main** remains the orchestrator and may populate structured capability hints when the task/project context identifies a useful or required Muse-side capability.

Do not duplicate these responsibilities in workstation-global `AGENTS.md`, do not create a Main capability broker, and do not copy credentials into worker packages.

The existing persistent `/home/codex` mount remains the intended state substrate. Do not invent a second Muse home.

## Accepted structured hint dependency

The workstation integration must consume, not reimplement, the accepted `codex_workflow` contract:

```text
MuseWorkerInvocation
└── capability_hints: MuseCapabilityHints
    ├── required_skills
    ├── relevant_skills
    ├── required_capabilities
    └── suggested_capabilities
```

Required semantics inherited from `MCA-DEC-001`:
- hints are per-invocation replace data;
- resume does not make old hints authoritative unless repeated;
- required skill/capability absence is fail-visible;
- relevant/suggested entries are advisory and non-blocking;
- identifiers are bounded opaque IDs;
- no mandatory global capability registry is introduced in v1;
- capability hints never contain credentials or installation authority.

This plan does not implement that contract in the workstation repository. Any `codex_workflow` source change belongs to its own repository/workstream.

## Milestone M01 — Workstation-side capability substrate contract

### Outcome

Workstation source and operational documentation accurately describe the persistent Muse capability substrate and its repository boundaries, without embedding rare administration instructions in global always-loaded policy and without mutating live Muse auth/config.

### Requirement ownership

R1-R12, source-side/workstation-owned portions.

### Planned work packages

- Reconcile Muse installation/runtime documentation with D25/D26 and the accepted cross-repository `MuseCapabilityHints` architecture.
- Document the supported persistent Muse user-scope locations for MCP/auth and skills, including project-scope exceptions.
- Document that capability administration is delegated to the dedicated `muse-capability-admin` skill rather than copied into workstation-global `AGENTS.md`.
- Document repository ownership:
  - workstation = persistent substrate/deployment;
  - Muse = native skills/MCP/auth/tool execution;
  - codex_workflow = structured hints/orchestration;
  - muse-capability-admin = administration procedure.
- Ensure source/runtime verification does not isolate `muse exec` from its persistent user/config root.
- Preserve secret boundaries and document approved-reference reuse without assuming a universal secret vault.
- Add bounded source validation/tests where workstation behavior changes; no real service credentials.
- Preserve existing `plus`, `luna-xhigh`, `pro-x5` behavior and D21 lifecycle.

### Acceptance

- Documentation is internally consistent with D21/D25/D26 and the accepted external capability-hint/admin decisions.
- No source path places credentials/OAuth material in Git or task text.
- Global workstation `AGENTS.md` does not receive the full rare-use administration runbook.
- MCP/tool authorization and skill/domain knowledge remain separate planes.
- Workstation does not duplicate `MuseCapabilityHints` implementation.
- Existing persistent home behavior remains compatible with Muse settings/auth/skills.
- Applicable static/source tests are GREEN.
- No live Muse settings, OAuth grants or user skill directories are modified during M01.

## Milestone M02 — Cross-repository integration readiness

### Dependencies

M01 plus the exact external implementation needed for runtime validation:

1. `elmakus/codex_workflow` has implemented and verified the accepted structured capability-hint protocol from `MCA-P1 M02`; and
2. for managed persistent capability mutation flows, the relevant `muse-capability-admin` administration path is available, or the live validation task explicitly authorizes a bounded equivalent native Muse operation.

Do not silently implement either dependency inside this repository.

### Outcome

The running workstation can use the accepted structured-hint and administration boundaries without configuration duplication or credential transfer through Main.

### Planned work packages

- Verify current deployed `codex_workflow` exposes structured required/relevant skill and required/suggested capability hints for Muse-backed roles.
- Verify capability-free invocations remain behaviorally unchanged.
- Verify workstation persistence exposes the same Muse skill/config/auth state to later fresh Muse processes.
- Verify the administrative skill can address workstation-hosted Muse state through its owning native mechanisms without becoming a workstation state database.
- Reconcile any actual workstation-owned missing substrate only if evidence proves one exists.
- If a workstation secret-delivery gap is proven, implement the smallest backend-specific substrate change while keeping the admin skill backend-agnostic.

### Acceptance

- Structured hints are available through the deployed Muse worker path without workstation-side duplicate parsing.
- Workstation persistence does not break per-invocation replace semantics or Muse native capability discovery.
- No Main connector/auth state is transplanted into Muse.
- Existing approved secret references may be reused without exposing plaintext where the concrete provider supports it.
- No workstation change is introduced merely for convenience when the owning external repository already provides the needed behavior.

## Milestone M03 — Authorized live end-to-end validation

### Dependencies

M02 plus the exact external capability/admin implementations required by the chosen validation cases.

### Outcome

Distinct Muse workers running on the workstation demonstrate persistent Muse-side capability reuse, structured capability guidance, shared skills and independent verification exactly as defined.

### Authorization model

Live persistent mutation follows `MCA-DEC-002`:

- a missing required capability reported by a worker does **not** authorize installation/configuration;
- when existing user/project authority already unambiguously authorizes the exact mutation, do not require a redundant second confirmation;
- when capability choice is ambiguous, return to user/product authority;
- when new credential provisioning is required and no approved secret reference exists, request only the smallest necessary user action;
- possession of a credential never grants mutation authority.

### Validation strategy

Use bounded, reversible examples:

- install/expose one user-approved reusable domain skill at Muse user scope; `HA_Bubble_Skill` remains a candidate, not an image-baked dependency;
- prove at least two distinct Muse roles discover the same persistent skill;
- dispatch an Executor/Investigator with `required_skills` containing the selected skill and confirm it is actually loaded/used;
- dispatch a separate Tester with the same skill as `relevant_skills` and confirm independent evidence/no Executor trajectory;
- configure/authenticate one user-approved external MCP/capability and prove a later fresh `muse exec` process uses the Muse-owned state directly;
- exercise `required_capabilities` fail-visible behavior and `suggested_capabilities` non-blocking behavior;
- exercise resume with changed and empty current hints to prove previous hints are superseded;
- where practical, enforce read-only/toolset/credential restrictions at the MCP/service boundary;
- verify restart/recreate persistence through the workstation's full user-home substrate;
- verify a missing required capability does not trigger implicit installation;
- document rollback/removal before live changes.

GitHub remains a preferred first external MCP validation because it can demonstrate direct authenticated capability reuse with a bounded/read-only surface. Home Assistant can follow through the same architecture without changing ownership.

### Acceptance

- A later Muse process reuses previously configured Muse-side MCP/auth state.
- Shared user-scope skill is discoverable from distinct worker roles.
- Structured required/relevant skill semantics work through the actual deployed `codex_workflow` path.
- Structured required/suggested capability semantics work through the actual deployed path.
- Resume replaces earlier hint authority, including with an empty current set.
- Required unavailability is fail-visible; advisory unavailability remains non-blocking.
- Tester remains a separate logical session and independently grounds GREEN/RED evidence.
- Main does not carry service credentials in task/result paths.
- Least-privilege restrictions are enforced outside prompt text.
- Missing capability does not auto-install.
- Restart/recreate does not lose accepted Muse user state.
- Rollback/removal path is proven/documented for validation changes.

## Requirement coverage

| Workstation requirement | Owner |
| --- | --- |
| R1 persistent capability plane | M01, M02, M03 |
| R2 no implicit Main inheritance | M01, M03 |
| R3 direct worker use | M01, M03 |
| R4 secret boundary | M01, M02, M03 |
| R5 hard least privilege | M01, M03 |
| R6 shared skill catalog | M01, M03 |
| R7 lazy skill use | M01, external structured-hint dependency, M03 |
| R8 Executor/Investigator required skill | external structured-hint dependency, M03 |
| R9 Tester independence with shared skill | external structured-hint dependency, M03 |
| R10 skill scope | M01, M03 |
| R11 skills do not grant tools | M01, M03 |
| R12 existing orchestration invariants | M01, M02, M03 |

## Cross-repository dependency map

```text
elmakus/muse-capability-admin
  M01/M03 admin skill + capability administration
          │
          ├──────────────┐
          │              │
          ▼              │
elmakus/codex_workflow   │
  M02 structured hints   │
          │              │
          └──────┬───────┘
                 ▼
elmakus/chatgpt-ce-workstation
  M01 substrate/docs
        ↓
  M02 integration readiness
        ↓
  M03 live E2E
```

The workstation workstream may progress through M01 without waiting for external implementation. M02/M03 must refresh the actual dependency state when they become current rather than assuming another repository has completed.

## JIT / execution-prep boundaries

Execution Prep for M01 may bind exact workstation documentation/source/test files.

Execution Prep for M02 must bind:
- exact deployed `codex_workflow` version/ref;
- exact structured-hint runtime evidence;
- exact available `muse-capability-admin` version/ref where administration is needed;
- any proven workstation substrate gap.

Execution Prep for M03 must additionally bind:
- exact live Muse config/skill paths;
- exact candidate skill/source revision;
- exact MCP server/auth flow;
- exact structured hint IDs;
- rollback/removal steps;
- safe Executor/Tester validation tasks;
- real least-privilege restrictions;
- exact existing authority for each persistent mutation;
- exact secret reference mechanism if credentials are needed.

Do not freeze OAuth tokens, private endpoints or secret values in the plan.

## Planning audit

GREEN:

- workstation Definition remains valid;
- D25/D26 remain authoritative and compatible with the accepted structured hint/admin architecture;
- R1's text-only execution assumption has been removed;
- structured hint implementation stays in `codex_workflow`;
- administration procedure stays in `muse-capability-admin`;
- workstation owns only its substrate/integration responsibilities;
- global `AGENTS.md` is not expanded with rare-use administration instructions;
- no mandatory capability registry, Main broker or per-role Muse home is introduced;
- secret and mutation-authority boundaries reflect `MCA-DEC-002`;
- every workstation requirement has an execution path;
- external dependencies have explicit refresh/JIT gates rather than speculative implementation detail;
- live validation remains bounded, reversible and evidence-based.

Independent review remains **RECOMMENDED** because R2 materially changes the execution strategy and adds cross-repository runtime/admin dependencies plus persistent-auth/security validation.

## R1 disposition

`muse-worker-capability-plane-R1` was frozen for review before the accepted cross-repository structured-hint architecture existed. No independent verdict was issued. R2 supersedes R1 for active planning because the R1 assumption that text-only task instructions should remain the baseline no longer matches accepted authority.

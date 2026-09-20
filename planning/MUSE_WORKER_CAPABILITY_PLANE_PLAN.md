# Muse worker capability and skill plane plan

Status: **draft**
Plan revision: **muse-worker-capability-plane-R1**
Date: 2026-09-20
Independent plan review: **RECOMMENDED**

## Goal and authority

Operationalize the accepted Muse-owned external capability plane and shared skill catalog without creating a second orchestration/control plane.

Authority:
- `requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`
- `docs/DECISIONS.md#D21`
- `docs/DECISIONS.md#D25`
- `docs/DECISIONS.md#D26`

Relevant evidence:
- `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`
- `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`

## Execution strategy

Keep ownership aligned with existing architecture:

- **Workstation** owns persistent Muse installation, user-home persistence, operational configuration guidance and live setup/verification.
- **Muse** owns its own MCP clients, OAuth/config state and native skill discovery/loading.
- **codex_workflow** continues to own worker/session orchestration under D21. This work does not require a new capability broker.
- A task capsule may name a required skill using ordinary task instructions. Do not add a new cross-repository runtime API merely to solve the baseline case. If execution evidence later proves that a structured `required_skills` runtime field is materially necessary, create a separate `codex_workflow` workstream rather than silently expanding this workstation issue.

The existing full persistent `/home/codex` mount should be reused. Do not invent a second Muse home or copy credentials into repository-managed files.

## Milestone M01 — Source-side Muse capability/skill contract

### Outcome

Repository source and operational documentation describe and validate the accepted persistent Muse capability/skill model without mutating live user auth/config.

### Requirement ownership

R1–R12, source-side portions only.

### Planned work packages

- Reconcile Muse installation/runtime documentation with D25/D26.
- Document the supported persistent Muse user-scope locations for MCP/auth and skills, including project-scope exceptions.
- Document the task-capsule convention for naming a required skill and the fail-visible behavior when it is unavailable.
- Document Tester semantics: shared skill as supporting reference, independent evidence still required.
- Ensure existing source/runtime verification does not accidentally isolate `muse exec` from the persistent user home/config root.
- Add bounded source validation/tests where repository behavior changes; avoid tests that require real service credentials.
- Preserve all current `plus`, `luna-xhigh`, `pro-x5` behavior and D21 session lifecycle.

### Acceptance

- Source documentation is internally consistent with D21/D25/D26.
- No source path places credentials or OAuth state in Git.
- The supported model clearly distinguishes MCP/tool authorization from skill knowledge.
- Required-skill task instructions have an explicit unavailable/limitation path.
- Tester guidance preserves separate-session/no-trajectory independence.
- Static/source tests applicable to changed code/config are GREEN.
- No live Muse settings, OAuth grants or user skill directories are modified during M01.

## Milestone M02 — Authorized live end-to-end validation

### Dependencies

M01 and its required/recommended implementation review are GREEN.

### Outcome

The running workstation proves that separate Muse worker processes can reuse persistent external capability state and a shared persistent skill catalog exactly as defined.

### Explicit authorization gate

Before modifying live Muse user configuration, installing a third-party skill into the persistent Muse catalog, or starting/altering a Muse MCP authentication grant, obtain explicit user authorization for that live write/auth action.

Feature/plan approval alone is not that authorization.

### Validation strategy

Use bounded, reversible examples:

- install or expose one user-approved reusable domain skill at Muse user scope; `HA_Bubble_Skill` is the current candidate but is not image-baked by this plan;
- prove at least two distinct Muse worker roles can discover it;
- run an Executor/Investigator task that explicitly requires the skill and confirm it is actually loaded/used;
- run a separate Tester session against the resulting artifact/state and confirm the Tester can reference the same skill while producing independent evidence;
- configure/authenticate at least one user-approved external MCP in Muse and prove a later `muse exec` process can use it directly without Main passing credentials;
- where practical, use an MCP-side read-only/toolset/credential restriction to prove the least-privilege boundary is external to prompt text;
- verify the live state survives a fresh Muse process and, where relevant, workstation recreate/restart because the full user home is persistent.

GitHub is the preferred first external MCP validation because it can be exercised against repository evidence without requiring Home Assistant control. Home Assistant can be added later through the same model without changing architecture.

### Acceptance

- Persistent Muse-side MCP/auth is reused by a later worker process.
- Main does not carry service credentials in the task/result path.
- Shared user-scope skill is discoverable from distinct worker roles.
- Required-skill unavailability is observable/fail-visible.
- Tester remains a distinct session and its GREEN/RED evidence is independently grounded.
- Any configured least-privilege restriction is enforced by the service/MCP/credential boundary.
- Restart/recreate does not lose accepted Muse user state.
- Rollback/removal path for the validation MCP/skill is documented before live changes.

## Requirement coverage

| Requirement | Owner |
| --- | --- |
| R1 persistent capability plane | M01, M02 |
| R2 no implicit Main inheritance | M01, M02 |
| R3 direct worker use | M01, M02 |
| R4 secret boundary | M01, M02 |
| R5 hard least privilege | M01, M02 |
| R6 shared skill catalog | M01, M02 |
| R7 lazy skill use | M01, M02 |
| R8 Executor/Investigator required skill | M01, M02 |
| R9 Tester independence with shared skill | M01, M02 |
| R10 skill scope | M01, M02 |
| R11 skills do not grant tools | M01, M02 |
| R12 existing orchestration invariants | M01, M02 |

## JIT / execution-prep boundaries

Execution Prep for M01 may bind exact repository files, documentation placement and non-secret tests to the then-current source.

Execution Prep for M02 must bind:
- exact live Muse config/skill paths;
- exact candidate skill/source revision;
- exact MCP server and auth flow;
- rollback/removal steps;
- safe verification tasks for Executor and Tester;
- any external-service write restrictions.

Do not freeze OAuth tokens, private endpoints or service secrets in the plan.

## Planning audit

GREEN:
- Definition is approved and S1 is resolved through D26;
- every requirement has a milestone owner;
- architecture preserves D21 ownership boundaries;
- no Main broker or per-role home is introduced;
- no unnecessary cross-repository API change is assumed;
- live persistent-user/auth changes are separated behind an explicit authorization gate;
- secret handling, least privilege, rollback and persistence verification are represented;
- HA Bubble remains a user-approved validation candidate rather than an undeclared mandatory image dependency.

Independent review is RECOMMENDED because this is a new operational/security plan affecting persistent authenticated tool state and shared worker knowledge across independent Executor/Tester roles.

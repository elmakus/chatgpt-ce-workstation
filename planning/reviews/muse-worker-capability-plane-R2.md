# Independent plan review — Muse worker capability plane R2

Plan revision: muse-worker-capability-plane-R2
Review requirement: RECOMMENDED
Review state: pending
Review subject: elmakus/chatgpt-ce-workstation@ac3ea34a889b4949f345f7bbf08846054a41bcbd
Reviewed plan: planning/MUSE_WORKER_CAPABILITY_PLANE_PLAN.md
Review evidence: pending

## Review scope

Independently review the exact immutable R2 plan subject above against:

### Workstation authority
- approved `requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`;
- accepted `docs/DECISIONS.md#D21`, `#D25`, and `#D26`;
- `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`;
- `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`.

### Accepted cross-repository authority
At exact external evidence ref `elmakus/muse-capability-admin@8aecaa42d0ffd40efa2342b5bbace85fcc976d7e`:
- `requirements/MUSE_CAPABILITY_ADMIN.md`;
- `decisions/MCA-DEC-001-STRUCTURED_CAPABILITY_HINTS.md`;
- `decisions/MCA-DEC-002-ADMIN_AUTH_AND_SECRET_REUSE.md`;
- approved `planning/MASTER_PLAN.md` revision `MCA-P1`;
- GREEN `planning/reviews/MCA-P1.md`.

Audit especially whether R2:

- keeps workstation ownership limited to Muse installation/persistent-home/deployment substrate and only proven workstation-owned secret-delivery changes;
- consumes rather than reimplements structured `MuseCapabilityHints` owned by `elmakus/codex_workflow`;
- correctly treats the dedicated `muse-capability-admin` skill as the rare-use administration plane instead of adding the full procedure to global `AGENTS.md`;
- preserves D21 Executor/Tester/session independence while supporting required/relevant skills and required/suggested capabilities;
- preserves Muse-owned MCP/auth/tool execution and avoids fabricated Main inheritance;
- preserves secret boundaries and the distinction between mutation authority and credential availability;
- does not treat a missing required capability as installation authority;
- represents per-invocation replace/resume semantics in E2E validation without duplicating the runtime implementation;
- uses explicit dependency/JIT refresh gates instead of assuming external repository work is complete;
- keeps live validation bounded, reversible, least-privileged and evidence-based;
- preserves non-`muse-max` behavior and capability-free Muse dispatch;
- maps every workstation requirement to an executable workstation-owned path or explicit external dependency without scope leakage.

A GREEN verdict allows R2 to be approved and routed to Execution Prep for workstation M01. A RED verdict must identify whether correction belongs to Workstation Planning, Workstation Definition, or an external dependency/authority mismatch.

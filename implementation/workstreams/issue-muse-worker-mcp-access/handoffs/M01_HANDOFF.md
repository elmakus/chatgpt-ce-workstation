# M01 handoff — Workstation-side capability substrate

Workstream: `issue-muse-worker-mcp-access`
Milestone: `M01`
Status: **GREEN / done**
Implementation checkpoint: `elmakus/chatgpt-ce-workstation@f175bbdcab094c8daa9d3a27ce05bd3caeff231d`

## Achieved state

- Workstation Muse documentation is reconciled with D21/D25/D26 and the approved capability-plane architecture.
- The existing full persistent `/home/codex` remains the workstation substrate for Muse-native configuration, authentication state, and skills.
- `elmakus/codex_workflow` remains owner of structured `MuseCapabilityHints` and worker lifecycle semantics.
- `elmakus/muse-capability-admin` remains owner of rare capability administration; its runbook is not copied into global `AGENTS.md`.
- Source/runtime guards cover persistent HOME and the ownership documentation boundary.
- M01 performed no live Muse capability-state or production deployment mutation.

## Acceptance and review

Card `M01-T01` is terminal with independent GREEN review for the exact implementation subject above.

Evidence:
- `implementation/workstreams/issue-muse-worker-mcp-access/evidence/M01_T01_CAPABILITY_SUBSTRATE_2026-09-20.md`
- `implementation/workstreams/issue-muse-worker-mcp-access/evidence/M01_T01_INDEPENDENT_REVIEW_2026-09-20.md`

## Authority now in force

- `requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`
- `docs/DECISIONS.md` — D21, D25, D26
- `planning/MUSE_WORKER_CAPABILITY_PLANE_PLAN.md` revision `muse-worker-capability-plane-R2`
- accepted `elmakus/muse-capability-admin@8aecaa42d0ffd40efa2342b5bbace85fcc976d7e`

## Next durable starting point

M02 Execution Prep. Refresh Gate/JIT must bind the exact current `elmakus/codex_workflow` structured-capability-hint implementation and evidence, the exact available `muse-capability-admin` ref where needed, and only any workstation substrate gap actually proven by that refresh.

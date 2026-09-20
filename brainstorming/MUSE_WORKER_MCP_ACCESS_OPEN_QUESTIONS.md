# Open question — Muse worker skills

Status: **resolved**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Resolution

User selected **S1 — shared persistent Muse skill catalog with role-specific use** on 2026-09-20.

Accepted consequences:
- reusable skills are installed once at Muse user scope;
- all Muse worker roles can discover them;
- Executor/Investigator loads a task-relevant skill when required;
- Tester may load the same domain skill as supporting reference while independently validating the artifact and never receiving Executor trajectory;
- repo-specific skills may remain project-scoped;
- separate physical skill catalogs per role are not required.

Canonical decision: `docs/DECISIONS.md#D26`.

# Open question — Muse worker skills

Status: **open**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

The external MCP capability model is resolved by D25: Muse owns a persistent capability plane.

## Decision required

Should Muse workers also use one **shared persistent Muse skill catalog with role-specific use**?

### Option S1 — shared catalog

- Reusable domain skills are installed once at Muse user scope.
- Every Muse worker role can discover them.
- Executor/Investigator loads a relevant skill when required by the task.
- Tester may load the same domain skill as supporting reference but independently validates current state/evidence and never receives Executor trajectory.
- Repo-specific skills can remain project-scoped.

### Option S2 — separate role catalogs

- Executor, Tester, Investigator, etc. receive different skill roots/catalogs.
- This can reduce shared-reference correlation but requires per-role skill-environment isolation, duplication/update policy and more runtime machinery.

## Current evidence

Muse only puts skill metadata into the initial catalog and lazily loads full bodies with `read_skill`, so a shared catalog does not imply loading every skill into every worker context.

The HA Bubble skill is a concrete case where both Executor and Tester benefit from the same domain knowledge, but in different modes: authoring/repair for Executor; independent health-check/reference use for Tester.

See `research/MUSE_WORKER_SKILL_PLANE_2026-09-20.md`.

# M02 blocker — structured Muse capability hints not yet available

Date: 2026-09-20
Workstream: `issue-muse-worker-mcp-access`
Milestone: `M02`
State: **blocked**

## Required predecessor

The approved M02 contract requires `elmakus/codex_workflow` to have implemented and verified the structured Muse capability-hint protocol before Workstation M02 can be contracted/executed. Workstation must not implement that dependency locally.

## Current evidence

- Live workstation container `chatgpt-ce-workstation` reports deployed `codex_workflow` version `1.1.18-private.1`.
- Read-only live inspection of deployed `codex_workflow/runtime/muse_worker.py` and `muse_sessions.py` found no `MuseCapabilityHints`, `required_skills`, `relevant_skills`, `required_capabilities`, or `suggested_capabilities` surface.
- Current `elmakus/codex_workflow/main` is `738ac89eeaa0522348f175eb5e936bda02a3de8c`; exact `codex_workflow/runtime/muse_worker.py` at that ref likewise contains none of those five accepted protocol identifiers.
- No open `codex_workflow` pull request currently supplies this dependency.
- `elmakus/muse-capability-admin` branch `feat/muse-capability-admin-skill` is exactly `8aecaa42d0ffd40efa2342b5bbace85fcc976d7e` and contains the accepted M01 administration foundation only. Its approved `MCA-P1` assigns structured Muse capability hints to its M02, whose primary repository is `elmakus/codex_workflow`.

## Classification

This is an unmet external predecessor, not a Workstation implementation defect and not evidence for a Workstation-owned substrate change. Creating a Workstation M02 execution Card now would freeze speculative scope and violate the approved dependency/JIT gate.

## Smallest remedy

Complete the approved structured capability-hint implementation in `elmakus/codex_workflow` under that repository's own Project Workflow, then return here and rerun M02 Refresh Gate against the exact implemented/deployed ref and evidence.

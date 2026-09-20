# M02 blocker — structured Muse capability hints implemented but not yet released/deployed

Date: 2026-09-20
Workstream: `issue-muse-worker-mcp-access`
Milestone: `M02`
State: **blocked**

## Dependency refresh

The original external implementation blocker has cleared.

`elmakus/codex_workflow` completed the accepted MCA-P1 M02 structured Muse capability-hint workstream:

- workstream `change-structured-muse-capability-hints`: terminal `done`;
- implementation subject `c8fc2d2c60a395bc20562d3f81efc844ee9a7405`: independent review GREEN;
- PR #10 merged to `main`;
- integration result `1b297620f19ff495034ad160465ac90fa29b8ed8`;
- current `main` closure head `760a595125335411288cf3a673356ccdd8ea47af`;
- exact current runtime source contains `MuseCapabilityHints`, `required_skills`, `relevant_skills`, `required_capabilities`, and `suggested_capabilities`.

The external implementation dependency is therefore satisfied.

## Remaining deployment gap

The approved Workstation M02 contract requires the exact deployed `codex_workflow` version/ref before JIT execution can be contracted.

Read-only live inspection of the production `chatgpt-ce-workstation` container shows:

- installed `codex_workflow` version remains `1.1.18-private.1`;
- deployed `runtime/muse_worker.py` contains none of the structured capability-hint symbols;
- persistent `HOME` remains `/home/codex`.

The merged `codex_workflow/main` source also still declares `VERSION=1.1.18-private.1`. The normal installed update path accepts verified GitHub Releases, not arbitrary repository `main`, and release publication is triggered by a synchronized VERSION change.

Per accepted `DEC-005`, later private-only changes on the aligned 1.1.18 generation increment the private suffix, so the next release line is `1.1.18-private.2`.

Installing the changed source while continuing to identify it as `1.1.18-private.1` would destroy exact release provenance and must not be used as the normal integration path.

## Classification

The missing external implementation is no longer the blocker.

The current blocker is the **release/deployment boundary** between the reviewed merged `codex_workflow` implementation and the production Workstation. This is not evidence for a Workstation-owned substrate code change.

A Workstation M02 execution Card is still premature because its JIT contract requires an exact deployed `codex_workflow` version/ref.

## Smallest remedy

1. Prepare and publish reviewed `elmakus/codex_workflow` release `1.1.18-private.2` from current accepted `main`, using the repository's normal synchronized version/release workflow.
2. Explicitly authorize the production Workstation update, then use the normal verified `codex_workflow --check-update` / `--update` path.
3. Read back the installed version and structured-hint runtime surface.
4. Return to this Workstation M02 Refresh/JIT gate. If deployment evidence is GREEN, materialize the exact M02 integration-readiness Card and continue execution.

No production update or release publication was performed by this refresh.

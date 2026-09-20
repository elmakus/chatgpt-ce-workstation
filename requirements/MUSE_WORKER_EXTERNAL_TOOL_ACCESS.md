# Muse worker external-tool access

Status: **definition in progress**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Problem

Muse workers in `muse-max` are separate Muse Code sessions. They do not inherit the Codex Main session's live MCP/connectors/tool objects.

This becomes material when a Muse investigator, Executor, or Tester needs GitHub, Home Assistant or another external service.

## Verified baseline

- Accepted D21 keeps Codex Main as orchestrator and Muse workers as leaf logical sessions.
- Current `elmakus/codex_workflow@main:codex_workflow/runtime/muse_worker.py` launches a separate `muse exec` process with task capsule, workspace, schema and Muse session identity.
- Cross-harness orchestrators in the ecosystem normally treat the callee CLI as an independently configured/authenticated runtime rather than attempting to inherit the caller's tool session.
- Muse Code 1.3.0 supports persistent user MCP configuration in `~/.config/muse/settings.json`, trusted-project `.mcp.json`, and its own OAuth grants via `muse mcp login`.
- New `muse exec` processes load that Muse-owned MCP configuration automatically.
- Muse `enabled_tools` / `disabled_tools` fields are not an enforceable tool-security boundary in 1.3.0.
- Hard least privilege can instead be provided by the MCP server or credential itself; for example GitHub MCP supports server-side read-only/toolset restrictions, while Home Assistant can restrict exposed entities and whether control is enabled.

Research: `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`.

## Existing invariants

1. Main remains orchestration/integration authority.
2. Muse remains a bounded leaf worker harness, not a second project control plane.
3. Caller/Main owns task authorization, workspace assignment and strategic escalation.
4. `codex_workflow` remains Project-Workflow-state agnostic.
5. Secrets and auth material are not copied into task capsules, normalized results or Git.
6. Executor and Tester independence remains intact.

## Refined architecture choices

### A — Muse-owned external capability plane

Treat Muse exactly like other external worker CLIs are commonly treated.

- Configure/authenticate required MCP servers once in the Muse runtime.
- Every `muse exec` worker launched under that Muse user/config root gets the same configured capability plane.
- The orchestrator passes task/workspace/runtime constraints, not connector sessions or credentials.
- OAuth/token lifecycle belongs to Muse/MCP configuration and persistent workstation state.
- Security-sensitive restrictions must be enforced by the MCP server, credential scope, endpoint or another hard runtime boundary rather than by prompt convention.

This does not require per-worker credential duplication or a Main round-trip for ordinary tool calls.

### B — Main-mediated broker only

Muse receives no authenticated external tools and returns capability requests to Main, which performs each external operation and resumes Muse.

This centralizes auth but adds orchestration protocol, latency and Main-context traffic.

### C — Per-dispatch generated capability plane

The orchestrator constructs a dedicated MCP configuration/environment for each Muse invocation or logical worker.

This can provide stronger per-task least privilege, but is substantially more machinery than the common persistent-harness model and requires secure temporary credential/config lifecycle.

## Definition question requiring user authority

Choose the desired capability ownership model:
- A: Muse-owned persistent external capability plane;
- B: Main broker only;
- C: per-dispatch generated capability plane.

The ecosystem research makes A the closest match to common cross-harness CLI orchestration, but Research itself does not make the product decision.

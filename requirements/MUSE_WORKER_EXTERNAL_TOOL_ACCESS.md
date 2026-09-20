# Muse worker external-tool access

Status: **definition in progress**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Problem

Muse workers in `muse-max` are separate Muse Code sessions. They do not automatically inherit the Codex Main session's MCP servers, ChatGPT connectors, authenticated app sessions, or tool authorization context.

This becomes material when a Muse `investigator`, Executor, or Tester needs evidence or an operation from an external system such as GitHub, Home Assistant, another remote MCP server, or a private service.

## Verified baseline

- Accepted D21 keeps Codex Main as orchestrator and Muse workers as leaf logical sessions.
- Current `elmakus/codex_workflow@main:codex_workflow/runtime/muse_worker.py` launches `muse exec` with a bounded task capsule, workspace, output schema, and Muse session identity. It has no Main-to-Muse connector/MCP inheritance contract.
- Muse Code 1.3.0 can load MCP servers from user `settings.json` and trusted-project `.mcp.json`.
- Muse Code can authenticate streamable-HTTP MCP servers with its own OAuth store.
- Muse Code 1.3.0 accepts `enabled_tools` / `disabled_tools` fields but does not enforce them, so native per-tool filtering cannot currently be treated as a security boundary.
- Current worker invocation uses `--trust-workspace`; therefore repository `.mcp.json` is eligible for Muse loading when present.
- Muse MCP credentials are Muse-side state. They are not the same authenticated session as Codex/ChatGPT connectors and must not be assumed to be transferable.

## Existing invariants that remain authoritative

1. Main remains the orchestration and integration authority.
2. Muse workers remain bounded leaf workers and do not become a second project-level control plane.
3. Caller/Main owns task authorization, write ownership, workspace assignment, and strategic escalation.
4. `codex_workflow` remains agnostic to Project Workflow Task Board/review semantics.
5. Secrets, auth tokens, raw Muse session state, and credentials must not be copied into normal worker results, task capsules, or project Git.
6. Executor and Tester independence must remain intact.

## Capability problem to solve

The runtime needs an explicit model for external capabilities. The model must distinguish at least:

- repository-local filesystem/test tools already available inside the assigned workspace;
- Muse-native MCP servers configured independently for Muse;
- Main-native connectors/tools that Muse cannot inherit directly;
- read-only versus mutating external operations;
- capabilities that are available but not authorized for the current role/task;
- capabilities that are authorized but unavailable due to auth/runtime failure.

A worker must never silently act as though Main's connected tools are available when they are not.

## Candidate architecture choices

### A — Direct Muse-native MCP

Configure the required GitHub/Home Assistant/other MCP servers directly for Muse through user `settings.json`, project `.mcp.json`, or an equivalent Muse-supported session surface.

Advantages:
- worker can investigate and act without round trips through Main;
- natural Muse tool-calling path;
- good fit for long investigator/executor turns.

Costs/risks:
- separate credentials/OAuth lifecycle from Main;
- duplicate configuration for services already connected to Codex;
- difficult per-tool least-privilege enforcement in Muse 1.3.0 because tool allow/deny fields are not enforced;
- a broad user-level MCP config may become available to more Muse sessions than intended.

### B — Main-mediated capability broker only

Muse never receives external authenticated MCP/connector access directly. When it needs an external fact/action, it returns a bounded structured capability request to Main; Main performs the operation with its native tool/connector and resumes the same Muse worker with the result.

Advantages:
- one credential/auth boundary;
- Main retains exact authorization and write control;
- works for ChatGPT/Codex-native connectors that cannot be transplanted into Muse.

Costs/risks:
- extra turn/latency and Main context usage;
- investigator autonomy is reduced;
- orchestration protocol must support bounded request/resume cycles cleanly.

### C — Hybrid explicit capability grants

Keep Main-mediated access as the universal fallback/control plane, while permitting selected Muse-native MCP servers when the capability is explicitly configured and safe for the task/role.

A direct Muse capability must be independently authenticated/configured and treated as a separate capability from a similarly named Main connector. Sensitive or unsupported capabilities remain brokered through Main.

Because Muse 1.3.0 does not enforce native per-tool allow/deny lists, a secure direct path would need either:
- server-level separation with only the allowed tools exposed;
- a capability-filtering MCP gateway/proxy;
- or another runtime-enforced session surface proven to enforce the grant.

## Definition questions requiring user authority

The architecture choice A/B/C materially changes credential ownership, security boundaries, latency, autonomy, and implementation scope. It is not safe to infer from the existing Muse runtime definition.

See `brainstorming/MUSE_WORKER_MCP_ACCESS_OPEN_QUESTIONS.md`.

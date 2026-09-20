# Open question — Muse worker external-tool access

Status: **open**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Decision required

Which capability model should become the accepted target for Muse workers?

- **A — Direct Muse-native MCP:** Muse receives its own configured/authenticated MCP servers and uses them directly.
- **B — Main broker only:** Muse never receives external authenticated tools; it requests bounded external operations/evidence from Main and is resumed with the result.
- **C — Hybrid:** Main broker is always available as fallback/control plane, while explicitly approved Muse-native MCP servers may be granted directly when a real least-privilege boundary can be enforced.

## Consequences that depend on the choice

The answer determines:
- whether credentials/OAuth are duplicated into Muse-side state;
- whether `codex_workflow` needs a structured capability-request/resume protocol;
- whether a filtered MCP gateway is needed for direct Muse access;
- whether GitHub/Home Assistant can be called by a worker directly or only through Main;
- the verification/security acceptance surface.

## Evidence

Muse Code 1.3.0 supports configured MCP servers and OAuth, but its documented `enabled_tools` / `disabled_tools` fields are not enforced. Therefore direct access cannot currently rely on native per-tool filtering as a security control.

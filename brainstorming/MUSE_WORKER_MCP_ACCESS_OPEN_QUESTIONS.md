# Open question — Muse worker external-tool access

Status: **open**
Workstream: `issue-muse-worker-mcp-access`
Date: 2026-09-20

## Decision required

Which capability ownership model should become the accepted target?

- **A — Muse-owned persistent capability plane:** configure/authenticate MCP servers once for Muse; all Muse workers use that harness-owned config directly.
- **B — Main broker only:** Muse has no external authenticated tools; Main performs requested external operations.
- **C — Per-dispatch generated capability plane:** Main/runtime creates a restricted MCP/config environment for each worker/task.

## Evidence

Cross-harness systems that launch Codex/Claude/Gemini-style CLIs normally keep authentication and external-tool configuration inside the worker CLI itself. They pass task/workspace/sandbox/config constraints across the process boundary rather than transferring the orchestrator's live MCP session.

Muse 1.3.0 supports exactly this worker-owned pattern through persistent settings, project MCP files and stored OAuth grants.

Hard least privilege should be enforced at the MCP server/credential/runtime boundary where required; Muse's current `enabled_tools` / `disabled_tools` fields are not sufficient as a security boundary.

See `research/MUSE_CROSS_HARNESS_CAPABILITY_PATTERNS_2026-09-20.md`.

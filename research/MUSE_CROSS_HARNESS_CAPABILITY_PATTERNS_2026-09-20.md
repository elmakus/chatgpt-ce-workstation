# Research — cross-harness worker capability patterns

Research ID: R-MUSE-CROSS-HARNESS-CAPABILITIES-2026-09-20
Status: active
Origin role: project_definition
Origin subject: requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Return target: project_definition:requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Research question: How do existing agent systems and real-world workflows handle external tools, MCP servers, authentication, and capability boundaries when an orchestrator runs in one harness and launches workers through a different CLI/harness via exec/subprocess?
Return reconciliation: pending
Return reconciliation result: none

## Scope

Prioritize concrete implementations and official documentation for systems where:
- the orchestrator and worker are different runtime/harness processes;
- the worker is launched through CLI/exec/subprocess or exposed as a tool/server boundary;
- GitHub, MCP, authenticated services, filesystem/workspace, or similar external capabilities matter.

Determine:
- whether workers inherit orchestrator tools/auth or use their own configuration;
- whether credentials/config are mounted/copied/inherited via environment;
- whether external operations are brokered by the orchestrator;
- whether an agent-as-tool/MCP-server pattern is used instead of raw exec;
- how least privilege and write authorization are enforced;
- practical implications for the Muse/Codex architecture.

Research is evidence only and does not choose the product architecture.

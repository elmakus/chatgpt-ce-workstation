# Research — cross-harness worker capability patterns

Research ID: R-MUSE-CROSS-HARNESS-CAPABILITIES-2026-09-20
Status: complete
Origin role: project_definition
Origin subject: requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Return target: project_definition:requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md
Research question: How do existing agent systems and real-world workflows handle external tools, MCP servers, authentication, and capability boundaries when an orchestrator runs in one harness and launches workers through a different CLI/harness via exec/subprocess?
Return reconciliation: applied
Return reconciliation result: requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md; brainstorming/MUSE_WORKER_MCP_ACCESS_OPEN_QUESTIONS.md

## Findings

### F1 — Cross-harness workers normally do not inherit the orchestrator's tool session

Concrete Claude Code -> Codex CLI orchestrators treat Codex as an independently installed/authenticated runtime. The orchestrator passes a task, cwd/worktree, sandbox/config flags and receives structured output. It does not transplant Claude's MCP/tool session into Codex.

Examples:
- Augani/agent-orchestrator: every external CLI is installed and authenticated separately; provider credentials are not stored by the orchestrator.
- dwgx/claude-codex-subagent: Claude launches local `codex exec`; Codex has its own auth, network and sandbox.
- p3nchan/cc-orchestrator and shuaige121/codex-orchestrator: Claude coordinates, Codex CLI workers execute in isolated workspaces/worktrees with their own runtime configuration.

Sources:
- https://github.com/Augani/agent-orchestrator
- https://github.com/dwgx/claude-codex-subagent
- https://github.com/p3nchan/cc-orchestrator
- https://github.com/shuaige121/codex-orchestrator

### F2 — The common direct model is harness-owned persistent configuration, not per-invocation credential copying

Codex CLI loads MCP configuration from its own user/project config. Claude Code and Gemini CLI do the same with their own user/project configuration layers. Cross-CLI wrappers rely on the callee CLI's configuration rather than serializing the caller's live tool objects.

Sources:
- https://developers.openai.com/codex/mcp
- https://docs.anthropic.com/en/docs/claude-code/mcp
- https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html

### F3 — Wrappers commonly pass execution policy/config, not live tool sessions

Wrappers constrain workers with cwd/worktree, sandbox, approval mode, profiles, explicit config overrides and environment. This separates orchestration policy from the worker harness's own tool/auth state.

A more elaborate example, todorkolev/codex-workers-for-claude, uses an MCP bridge for worker lifecycle and Codex app-server control. The bridge handles starting, steering, approvals, artifacts and worktrees; it does not turn Claude's own external tools into inherited Codex tools.

Sources:
- https://github.com/todorkolev/codex-workers-for-claude/blob/main/docs/architecture.md
- https://github.com/dwgx/claude-codex-subagent/blob/main/docs/codex-dispatch-guide.md

### F4 — Muse Code already supports the same harness-owned model

Muse Code 1.3.0 loads MCP servers at process start from:
- user `~/.config/muse/settings.json`;
- trusted-project `.mcp.json`.

Remote MCP OAuth is performed with `muse mcp login <server>`; Muse stores and refreshes that grant. New `muse exec` processes load the configured servers automatically. A settings-level server is the documented place for a server that needs credentials, headers or machine-specific configuration.

Muse also supports environment interpolation for MCP config. Its MCP child-process environment is intentionally filtered, so required variables should be declared explicitly in the MCP server `env` config rather than relying on arbitrary parent-process environment inheritance.

Sources:
- https://meta-models.github.io/muse-code-sdk/next/guides/extend/mcp-servers/
- https://dev.meta.ai/docs/muse-code/extending

### F5 — Least privilege is usually enforced below the orchestrator

Mature tool servers expose their own hard capability restrictions. GitHub's official MCP server supports server-side toolsets, individual tool selection and a read-only mode that removes write tools. Home Assistant's official MCP server controls which entities are exposed and whether clients may control HA.

This is stronger than relying only on a prompt or a model-side tool-name convention.

Sources:
- https://github.com/github/github-mcp-server/blob/main/docs/server-configuration.md
- https://www.home-assistant.io/integrations/mcp_server

### F6 — Agent-as-tool/MCP bridge is mainly an orchestration transport

Projects such as codex-subagents-mcp and codex-workers-for-claude expose delegation through an MCP server and then spawn Codex workers behind it. This improves lifecycle, isolation and structured control, but the worker harness still owns its own auth/config/tool environment. Wrapping the worker in MCP does not automatically make the orchestrator's other MCP tools available inside the worker.

Sources:
- https://github.com/leonardsellem/codex-subagents-mcp
- https://github.com/todorkolev/codex-workers-for-claude

## Implication for Muse/Codex

The dominant cross-harness pattern is:

```text
Codex Main
  -> codex_workflow dispatch
      -> muse exec
          -> Muse-owned persistent config/auth
          -> Muse-owned MCP clients
          -> assigned workspace/sandbox
```

The orchestrator does not need to broker ordinary GitHub/Home Assistant reads/writes merely because Muse is a different harness. If Muse requires those systems, they can be configured once for the Muse runtime and reused by all Muse worker processes that run under that user/config root.

The remaining product question is therefore narrower: which external capabilities should be installed/authenticated in the Muse worker harness, and what hard server-side or credential-level restrictions are required for them?

Research does not choose that policy.

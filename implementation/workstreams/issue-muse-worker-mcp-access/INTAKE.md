# Issue Intake — Muse worker MCP/external-tool access

Status: complete
Workstream ID: `issue-muse-worker-mcp-access`
Kind: issue
Branch: `fix/muse-worker-mcp-access`
Integration target: `main`
Creation base: `04440574afb2d85790301c915e9d7f8c90721021`

## Operator intent

Diagnose and resolve the capability gap where Muse Code workers used by `muse-max` do not automatically inherit the Main/Codex session's MCP servers, connectors, or other authenticated external tools. The motivating cases include GitHub and Home Assistant access needed during diagnosis, investigation, execution, or verification.

## Baseline findings

1. The accepted Muse runtime definition models Muse workers as separate leaf logical sessions launched through Muse Code, with Main remaining the orchestrator and with bounded task capsules/workspace state as the normal handoff.
2. Current `elmakus/codex_workflow` `main` launches Muse through `muse exec` with explicit workspace/session/schema arguments. The adapter does not contain a Main-to-Muse connector/MCP capability propagation contract.
3. Muse Code 1.3.0 itself supports MCP servers through user `settings.json`, project `.mcp.json`, and OAuth login for streamable-HTTP MCP servers. Therefore the technical platform can expose MCP tools to a Muse session, but this is separate from inheriting Codex/ChatGPT Main's connected tools.
4. The current adapter passes `--trust-workspace`, so an admitted project `.mcp.json` can be loaded by Muse; however credentials, OAuth grants, tool scoping, write permissions, and connector identity remain a separate security/authority problem.

## Relevant authority / evidence

- `requirements/MUSE_MAX_RUNTIME.md` — R2, R7, R15, R17.
- `docs/MUSE_CODE_PLAN.md` — Muse is an external worker process with persistent user-home auth/config.
- `elmakus/codex_workflow@main:codex_workflow/runtime/muse_worker.py` — current command/process boundary.
- Muse Code 1.3 MCP documentation: user settings, project `.mcp.json`, OAuth, and tool registration behavior.

## Dependency classification

Independent workstream.

The issue exists on the accepted `main` Muse architecture and current released/runtime contract. It does not require parent-only behavior from the unrelated `feat/smart-upstream-updates` workstream. File overlap or convenience would not justify stacking.

## Intake classification

Not a micro-fix.

Root technical cause is concrete, but the intended behavior is not yet an accepted bounded correction because it requires a strategic capability/security contract covering:
- whether Muse gets direct MCP access, Main-mediated access, or a hybrid;
- per-role/per-task capability grants;
- read versus write authority;
- credential/OAuth ownership and secret isolation;
- behavior when a required external capability is unavailable;
- whether project `.mcp.json` is sufficient or runtime-generated session capability configuration is required.

## Downstream route

Path: `project_definition`

Next route: `project_definition:requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`

Canonical Definition authority:
- `requirements/MUSE_WORKER_EXTERNAL_TOOL_ACCESS.md`
- `brainstorming/MUSE_WORKER_MCP_ACCESS_OPEN_QUESTIONS.md`

The remaining Definition blocker is the user-owned architecture choice among direct Muse-native MCP, Main-mediated capability brokering, or a hybrid model. Intake is complete; recovery continues from the Definition authority above.

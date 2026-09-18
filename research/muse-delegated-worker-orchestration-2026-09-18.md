# Muse delegated-worker orchestration research — 2026-09-18

Status: verified evidence for Project Definition and planning.

## Research question

How should the existing ChatGPT-only project workflow delegate bounded implementation/test work to Muse Code while preserving the main ChatGPT agent as the workflow control plane and avoiding transcript/context bloat?

## Verified external patterns

### Final-envelope subprocess boundary

`jitokim/oh-my-graph` ADR 0001 deliberately runs one Claude node as one raw CLI subprocess and keeps the CLI-specific contract behind a single `NodeRunner` interface. The scheduler consumes the final JSON envelope rather than streaming intermediate model tokens. The ADR explicitly treats the CLI flag/JSON contract as volatile and localizes that risk in the runner seam.

Source:
- https://github.com/jitokim/oh-my-graph/blob/main/docs/adr/0001-subprocess-not-sdk.md

Implication for this project:
- one Muse worker should be one bounded subprocess behind a workstation-owned adapter;
- the orchestrator should consume a final normalized result, not the worker's full event stream;
- Muse CLI compatibility should be isolated in the adapter.

### Awaitable worker lifecycle and schema normalization

`six-ddc/codex-dynamic-workflows` exposes async launch/wait/cancel semantics, normalizes agent results, validates schema output, retries malformed results, enforces per-agent timeout, and treats the backend runner as a replaceable boundary. Its CLI runners drain child output while returning only the normalized agent result to the workflow runtime.

Sources:
- https://github.com/six-ddc/codex-dynamic-workflows/blob/main/src/runtime.ts
- https://github.com/six-ddc/codex-dynamic-workflows/blob/main/CLAUDE.md

Implication:
- the main agent should await worker completion instead of polling;
- result schema validation belongs in the harness, not in the main-agent prompt;
- timeout/cancellation and output bounds are harness responsibilities.

### Separate full trajectory from parent-facing result

`dreadnode/agent-lens` translates backend-native event streams into a normalized engine abstraction while storing full trajectories separately. Subagent trajectories are linked to the parent instead of being copied wholesale into the parent trajectory.

Sources:
- https://github.com/dreadnode/agent-lens/blob/main/src/harness/engines/base.py
- https://github.com/dreadnode/agent-lens/blob/main/src/harness/engines/codex.py
- https://github.com/dreadnode/agent-lens

Implication:
- Muse JSON/JSONL can be retained as a durable/debug artifact;
- normal orchestration should expose only a compact worker result and references to richer evidence when needed.

### Wait instead of busy-loop polling; large data bypasses orchestrator context

`Heretyc/subagent-mcp` explicitly tells the orchestrator not to busy-loop polling and to learn completion through a wait operation. It also routes large inter-agent data through scratch files that the orchestrator does not read.

Source:
- https://github.com/Heretyc/subagent-mcp/blob/main/CLAUDE.md

Implication:
- worker completion should resume the main agent automatically;
- worker-to-tester handoff should primarily be repository/worktree state plus bounded metadata, not executor transcript relayed through main.

### Current Muse evidence

Meta's current Muse Code changelog explicitly refers to `muse exec` JSON output and preserving clean `--json` output across workflow/script errors. The public installer remains `https://dev.meta.ai/install.sh`.

Sources:
- https://dev.meta.ai/docs/muse-code/changelog
- https://dev.meta.ai/

Implication:
- JSON is a valid machine-readable direction for the adapter;
- exact installed `muse exec` flags and event/envelope shape must still be captured from the live workstation's `muse exec --help` before freezing implementation details.

## Project observations

- Workstation `main` already installs Muse Code under `/opt/muse-code` and exposes `/usr/local/bin/muse`.
- Runtime verification already requires `muse --version`, `muse --help`, and `muse exec --help`.
- Full `/home/codex` persistence is already the intended Muse auth/config boundary.
- The active execution policy is `chatgpt_only`; ChatGPT is the fixed Task Card executor.
- Current workflow authority contains no generic delegated-worker contract.

## Recommended architecture supported by evidence

Use two layers:

1. **Workflow control contract** in `elmakus/chatgpt-codex-project-workflow`
   - ChatGPT remains Task Card executor/control plane;
   - delegated workers are bounded leaf execution resources;
   - Task Board/review/publication authority remains with ChatGPT;
   - the workflow consumes normalized worker results rather than raw transcripts.

2. **Muse adapter** in `elmakus/chatgpt-ce-workstation`
   - stable command such as `muse-worker run --role executor|tester ...`;
   - adapter owns raw Muse CLI flags, JSON/JSONL parsing, stdout/stderr draining, timeout and process-tree cancellation;
   - full raw worker log is persisted outside main-agent context;
   - final output is validated against a small role-specific schema.

## Important independence property

The tester should receive the accepted task/review contract and actual resulting repository/worktree state. It should not receive the executor transcript by default. This avoids review anchoring and removes the need for the main agent to relay or summarize the executor's work.

## Remaining uncertainty

The exact Muse CLI argv and final/event JSON shape are intentionally not frozen yet. Live inspection of the installed build's `muse exec --help` and one bounded disposable run is the evidence trigger for that implementation detail.

This uncertainty does not block defining the orchestration boundary or planning the work.

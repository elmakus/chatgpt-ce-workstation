# Muse delegated workers

Status: **approved**
Date: 2026-09-18

## Goal

Extend the existing `chatgpt_only` workflow so the main ChatGPT agent can delegate bounded implementation and testing/review work to Muse Code workers without giving up Task Card ownership, without busy-loop polling, and without importing the worker's full transcript into the main context.

## Requirements

### R1 — ChatGPT remains the workflow control plane

Normal ChatGPT remains the fixed Task Card executor under `chatgpt_only`.

Delegated Muse workers may perform bounded work assigned by ChatGPT, but they do not:
- select or advance Task Cards;
- edit `implementation/TASK_BOARD.yaml`;
- issue independent workflow acceptance on behalf of ChatGPT;
- merge/publish/push unless a later explicit worker contract authorizes a bounded Git action.

### R2 — Stable worker interface

Workflow rules must invoke a stable delegated-worker interface rather than encode raw Muse CLI flags in prompts or workflow semantics.

Muse-specific argv, output parsing and compatibility logic belong behind the workstation adapter.

### R3 — Leaf-worker model

One delegated worker invocation maps to one Muse process and one assigned task/workspace.

Nested Muse-native subagent fan-out is disabled by default. The ChatGPT orchestrator owns fan-out, sequencing and concurrency.

### R4 — Await completion; no normal polling loop

A worker invocation is awaitable. The main agent resumes when the worker finishes, times out, is cancelled or fails.

Periodic status polling is not part of the normal execution path.

### R5 — Context-isolated transcript

The adapter must drain Muse stdout/stderr so the child cannot block, but raw event/transcript output must not be injected into the main ChatGPT context by default.

The full raw log may be retained as a debug/evidence artifact with a reference in the normalized result.

### R6 — Normalized executor result

An executor worker must return a bounded machine-readable result containing at least:
- terminal status;
- concise summary;
- repository/worktree result reference or changed-file summary;
- tests/checks attempted and their outcome;
- blocking issues;
- raw-log/evidence reference when available.

The final schema is owned by the delegated-worker contract, not by free-form Muse prose.

### R7 — Independent tester result

A tester worker must receive:
- the accepted task/review contract;
- the resulting repository/worktree state;
- required test/acceptance instructions.

It must not receive the executor transcript by default.

The tester returns a bounded verdict/result with findings and evidence. This preserves fresh review and avoids relaying executor context through the main agent.

### R8 — Workspace isolation and authority boundary

Workers operate only in the workspace/worktree assigned by the orchestrator.

They must not switch to unrelated worktrees, modify workflow state, or mutate unrelated repositories.

### R9 — Timeout and cancellation

The adapter owns an outer per-worker timeout and process-tree cancellation.

Cancellation must not leave a live Muse child/process subtree behind.

### R10 — Explicit failure semantics

The adapter must distinguish at least:
- success;
- worker/model failure;
- timeout/cancel;
- malformed or unparseable protocol/result;
- harness/runtime failure.

A successful process exit alone is not sufficient if the final normalized result contract is invalid.

### R11 — CLI details are JIT-bound to the installed Muse build

The architecture may rely on Muse Code having a machine-readable `muse exec` path, but exact argv/event/envelope fields must be derived from the actual installed build's:
- `muse --version`;
- `muse exec --help`;
- one bounded disposable-repository run.

Do not freeze guessed flags in the workflow repository.

### R12 — Preserve secrets and subscription auth

Muse authentication remains user/session state under persistent `/home/codex`.

No Muse auth token, browser/session credential or secret may be written to Git, emitted in normalized results, or copied into raw logs intentionally.

### R13 — Backward-compatible pilot

Delegated Muse execution is initially opt-in for explicitly prepared Cards/workflows.

Existing `chatgpt_only` execution remains valid when no delegated-worker profile is selected.

## Acceptance-level outcome

The first integrated pilot is successful when a prepared Task Card can run:

```text
ChatGPT orchestrator
  -> await Muse executor
  -> repository/worktree result
  -> await fresh Muse tester
  -> normalized tester verdict
  -> ChatGPT accepts/rejects and continues workflow
```

while:
- the main context receives only bounded normalized worker results in the normal GREEN path;
- full Muse logs remain available outside the main context for debugging/evidence;
- no polling loop is required;
- the tester does not consume the executor transcript;
- ChatGPT remains the sole Task Board/workflow authority.

## Non-goals for the first implementation

- interactive mid-run steering of Muse;
- `muse serve` / MSP orchestration;
- long-lived conversational worker sessions;
- nested Muse subagents;
- replacing the `chatgpt_only` execution policy;
- forcing every existing project/Card to use Muse;
- designing a provider-agnostic multi-model scheduler beyond the seam needed to keep workflow semantics independent from Muse CLI details.

# Muse delegated-worker Master Plan

Status: **approved**
Date: 2026-09-18

## Authority

This plan organizes:
- `requirements/MUSE_DELEGATED_WORKERS.md`;
- `docs/DECISIONS.md#d20--chatgpt-owned-delegated-muse-workers-behind-a-normalized-harness`;
- `research/muse-delegated-worker-orchestration-2026-09-18.md`;
- the existing Muse installation/live-validation baseline in `docs/MUSE_CODE_PLAN.md`.

Execution policy remains `chatgpt_only`.

## Target state

A normal ChatGPT project execution may opt into delegated Muse workers while preserving ChatGPT as the Task Card executor/control plane.

The normal successful path is:

```text
ChatGPT Task Card executor
  -> invoke/await delegated executor profile
  -> receive compact normalized result
  -> invoke/await fresh tester profile over resulting repository state
  -> receive compact normalized verdict
  -> ChatGPT applies workflow acceptance/state/close rules
```

The raw Muse transcript/event stream is retained outside the main context and consulted only through explicit escalation/debug paths.

## Global invariants

- ChatGPT alone owns Task Board transitions and workflow acceptance.
- Worker processes are leaf workers; nested Muse fan-out is disabled by default.
- The main agent does not busy-loop poll workers.
- The normal GREEN path does not feed raw worker transcripts into main context.
- Tester review is grounded in contract + repository/worktree state, not executor transcript.
- Workflow rules remain backend-neutral; Muse CLI syntax stays in the workstation adapter.
- Existing `chatgpt_only` projects/Cards remain valid without delegated workers.
- No live Unraid mutation occurs without an explicit live-operation authorization gate.

## Milestone M04 — Generic delegated-worker workflow contract

### Outcome

The authoritative workflow repository can represent and execute an opt-in delegated-worker step under `chatgpt_only` without changing the fixed Task Card executor identity.

### Planned work packages

- Add a policy-specific delegated-worker contract under `workflow/chatgpt_only/`.
- Define the distinction between Task Card executor ownership and delegated worker execution.
- Define await/no-poll semantics.
- Define normalized result, transcript isolation, failure escalation and leaf-worker invariants at a backend-neutral level.
- Add JIT/Task Card guidance for opting a Card into one or more worker roles/profiles.
- Reconcile Execution/Execution Prep/Task Card/State/Router wording only where necessary.
- Add/update workflow semantic documentation/tests/audit material appropriate to the repository.

### Acceptance

- `chatgpt_only` still says ChatGPT is the fixed Task Card executor.
- A Task Card may explicitly require a delegated worker profile without assigning the Card itself to that worker.
- Workflow semantics never require raw worker transcript ingestion or periodic polling.
- Worker completion/result handling and failure escalation are deterministic.
- Existing Cards with no delegation contract retain prior behavior.
- No Muse-specific argv or workstation path is embedded in generic workflow authority.

### Review

Because this changes the authoritative workflow used across projects, the exact M04 workflow subject requires an **independent ChatGPT review before merge to workflow `main`**.

### Dependency

M03 complete; approved delegated-worker definition above.

## Milestone M05 — Live Muse CLI/runtime contract capture

### Outcome

The actual workstation Muse build provides durable evidence for the adapter's concrete process/JSON contract.

### Planned work packages

- Update/rebuild the live workstation from current `main`.
- Capture `muse --version`, `muse --help`, and `muse exec --help`.
- Complete/verify normal Muse subscription login under persistent `/home/codex`.
- Verify login persistence after restart/recreate.
- Run one bounded disposable-repository `muse exec` task with machine-readable output.
- Capture exact stdout/stderr shape, terminal result semantics, exit code, session metadata if present, and behavior on one controlled failure.
- Verify sandbox behavior needed by the worker use case.
- Record the observed contract as evidence; do not generalize beyond the installed version without evidence.

### Acceptance

- Exact installed Muse version is known.
- Exact command surface needed by the adapter is known.
- A bounded headless run succeeds.
- A controlled failure produces understood terminal/protocol behavior.
- Auth survives restart/recreate.
- No secrets are captured in committed evidence.

### Gate

This milestone performs live Unraid build/recreate/login/runtime actions and requires explicit live-operation authorization at execution time.

## Milestone M06 — Workstation `muse-worker` adapter

### Outcome

The workstation exposes a stable local worker command/API that hides Muse CLI volatility and returns bounded normalized results.

### Planned work packages

- Define an OpenSpec-relevant worker input/output/failure contract from M04 authority + M05 observed runtime.
- Implement one workstation-owned adapter/command for at least `executor` and `tester` roles.
- Adapter owns:
  - Muse argv construction;
  - task/prompt transport;
  - stdout/stderr draining;
  - raw log persistence;
  - final result extraction;
  - schema validation;
  - bounded output;
  - timeout and process-tree cancellation;
  - worker workspace/cwd enforcement;
  - terminal failure classification.
- Ensure the adapter never updates Task Board or performs implicit push/merge.
- Add deterministic tests with fake/fixture worker output plus targeted live smoke against the installed Muse build.

### Acceptance

- One executor invocation can edit a disposable assigned worktree and return a valid compact result.
- One tester invocation can independently inspect the resulting worktree and return a valid verdict.
- Invalid/malformed worker output is rejected as protocol failure.
- Timeout/cancellation leaves no child process tree.
- Full raw logs remain outside main-agent output while a reference is available.
- Normalized output contains no auth/session secrets.
- Existing workstation runtime behavior remains intact.

### Review

The process-control/protocol implementation receives an independent review before final M06 acceptance.

## Milestone M07 — End-to-end workflow pilot

### Outcome

One real project Task Card executes through the approved workflow using Muse executor + fresh Muse tester while ChatGPT remains the control plane.

### Planned work packages

- Prepare one low-risk disposable/pilot Task Card with explicit delegated-worker roles.
- ChatGPT launches and awaits the executor through the generic workflow contract.
- ChatGPT consumes only the normalized executor result on the normal path.
- Fresh tester receives the Card authority + resulting repo/worktree state, not executor transcript.
- ChatGPT consumes normalized tester verdict and performs ordinary acceptance/Task Board transitions.
- Exercise one RED path so blocking findings are returned without requiring transcript ingestion.
- Confirm logs/evidence can be escalated only when needed.

### Acceptance

- No periodic polling loop is used.
- Main ChatGPT context receives bounded normalized results, not full Muse JSONL.
- Tester operates independently from executor transcript.
- GREEN path completes a Task Card using normal workflow state rules.
- RED path produces actionable bounded findings and does not falsely mark the Card done.
- ChatGPT remains the sole workflow-state authority.
- Nested Muse fan-out stays disabled.

## Deferred decision after M07

Promotion from opt-in pilot to a broader/default delegated-worker policy is intentionally outside this plan. M07 evidence will support a later explicit Definition decision if desired.

## Requirement coverage

| Requirement | Owning milestone(s) |
| --- | --- |
| R1 control-plane ownership | M04, M07 |
| R2 stable worker interface | M04, M06 |
| R3 leaf workers | M04, M06, M07 |
| R4 await/no polling | M04, M06, M07 |
| R5 transcript isolation | M04, M06, M07 |
| R6 executor result | M06, M07 |
| R7 independent tester | M04, M06, M07 |
| R8 workspace boundary | M06, M07 |
| R9 timeout/cancellation | M06 |
| R10 failure semantics | M04, M06, M07 |
| R11 JIT CLI binding | M05, M06 |
| R12 secret/auth protection | M05, M06 |
| R13 backward-compatible pilot | M04, M07 |

## JIT decomposition triggers

- M04 can be decomposed immediately from the approved Definition.
- M05 exact runtime checks should be prepared only from the then-current workstation `main`.
- M06 exact CLI/parser Task Cards must not be frozen until M05 evidence captures the installed Muse contract.
- M07 pilot Card should be chosen only after M06 adapter acceptance is GREEN.

## System verification

The integrated verification sequence is:

```text
workflow contract/static audit
  -> live Muse contract capture
  -> adapter deterministic tests
  -> adapter live disposable smoke
  -> executor -> tester workflow pilot
  -> GREEN/RED path verification
```

## Rollback / compatibility

- M04 is additive and opt-in; removing delegation references returns execution to existing `chatgpt_only` behavior.
- The workstation adapter is image-owned and can be removed/replaced through normal rebuilds.
- No worker owns persistent workflow state, so a failed worker cannot by itself advance project execution state.
- Live Muse auth remains in persistent user home and is not coupled to Task Board state.

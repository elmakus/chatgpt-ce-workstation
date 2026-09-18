# Muse-max runtime orchestration

Status: **approved**
Date: 2026-09-18

## Goal

Make `muse-max` a production-capable `codex_workflow` compute profile in which Codex remains Main/orchestrator, one persistent Luna XHigh Companion retains project context, and the remaining existing worker roles execute as bounded Muse Code leaf workers with compact normalized results.

This Definition governs only `muse-max`. It does not redesign the other compute profiles and does not add a generic delegated-worker runtime to Project Workflow.

## Target architecture

```text
Project Workflow
  -> Task Cards / dependencies / parallel_safe / write ownership / worktrees
  -> Codex Main
       -> persistent Companion: internal Codex GPT-5.6 Luna XHigh
       -> codex_workflow role routing
            -> micro_executor   -> Muse Code / Muse Spark 1.3 Contributor Max
            -> default_executor -> Muse Code / Muse Spark 1.3 Contributor Max
            -> senior_executor  -> Muse Code / Muse Spark 1.3 Contributor Max
            -> tester           -> Muse Code / Muse Spark 1.3 Contributor Max
            -> investigator     -> Muse Code / Muse Spark 1.3 Contributor Max
            -> archivist        -> Muse Code / Muse Spark 1.3 Contributor Max
```

## Requirements

### R1 — Scope is only `muse-max`

Changes for this work MUST preserve the behavior and allocations of `plus`, `luna-xhigh`, and `pro-x5`.

Regression coverage MUST prove that those profiles did not acquire Muse routing or changed lifecycle semantics.

### R2 — Codex Main remains the orchestrator

The user-selected Codex Main remains responsible for:
- task/package direction;
- worker selection;
- dependency and concurrency decisions;
- integration;
- acceptance;
- Project Workflow state;
- strategic escalation;
- final user communication.

A Muse worker is never the project-level orchestrator or Task Board authority.

### R3 — Companion is persistent Luna XHigh

Under `muse-max`, `companion` MUST use the normal internal Codex worker lifecycle with:
- model: GPT-5.6 Luna;
- reasoning effort: XHigh;
- one persistent Companion per workflow session.

It MUST NOT be routed through the Muse adapter.

### R4 — Six existing roles use Muse

Under `muse-max`, these roles MUST route through the native Muse Code harness with Muse Spark 1.3 Contributor / max:
- `micro_executor`;
- `default_executor`;
- `senior_executor`;
- `tester`;
- `investigator`;
- `archivist`.

No new Muse-specific semantic role set is introduced.

### R5 — Shared role contracts remain canonical

Existing `agents/*.toml` files remain the single semantic definitions of worker responsibility, scope, ownership and report expectations.

Do not create `muse_default_executor.toml`, `muse_tester.toml` or equivalent duplicated role contracts.

Harness-only differences such as one-shot execution, no intermediate messaging, no nested workers and strict final structured output belong in a Muse runtime overlay/adapter.

### R6 — Profile-aware adapter

The Muse adapter MUST resolve:
- active compute profile;
- requested role;
- that role's `WorkerModel`;
- expected harness/model/reasoning allocation

through `compute_profiles.py` and shared runtime path semantics.

It MUST reject an invocation when the requested role is not assigned to `muse-code` in the active profile. This includes rejecting `companion` under the defined `muse-max` profile.

The adapter MUST honor `CODEX_HOME` consistently with the rest of `codex_workflow`.

### R7 — Muse workers are leaf one-shot invocations

One Muse worker assignment maps to one bounded `muse exec` process lifecycle.

Muse workers MUST NOT:
- create or coordinate nested workers;
- directly message sibling Muse workers;
- change Project Workflow scheduling/state;
- create/switch project-level worktrees or branches unless a later explicit authority changes this.

Normal completion is process/result driven; periodic status polling is not the normal lifecycle.

### R8 — Separate executor and tester

A verification step ALWAYS uses a distinct tester invocation from the implementing executor.

Tester input is:
- accepted verification/Task Card authority;
- actual resulting repository/worktree state;
- relevant required gates/evidence.

Executor raw transcript/trajectory is not tester input by default.

### R9 — RED repair loop routes through Main

For an ordinary production defect within already accepted scope:

```text
fresh executor
  -> compact result
fresh tester
  -> RED + focused findings
Main
  -> fresh executor repair using findings + durable state
fresh tester
  -> recheck
```

Main may automate this loop while scope/contract/ownership/architecture/security/migration/authority remain unchanged.

Cross-boundary findings return to Main for the applicable strategic/project workflow decision.

### R10 — Compact normalized result

The normal Main-facing result MUST be bounded and machine-readable.

Common fields MUST cover at least:
- schema version;
- logical Task ID;
- role;
- terminal status;
- concise summary;
- blocking findings / decision requirement;
- verification/check outcomes;
- limitations;
- raw artifact references.

Executor results SHOULD additionally include bounded changed-path/diff-stat information when applicable.

Tester results MUST include a bounded verdict such as `GREEN | RED | INCONCLUSIVE` plus focused findings/evidence.

Main MUST NOT receive full reasoning, tool-call streams, raw test stdout, or large diffs on the normal path.

### R11 — Raw event/log isolation

The adapter MUST drain Muse stdout/stderr and persist the raw machine-readable event stream and diagnostic stderr outside:
- Main context;
- Project Workflow Task Board;
- project Git.

Run artifacts SHOULD live under persistent user runtime data beneath `~/.codex` with bounded retention by age/count/size.

No auth/session secret may be intentionally copied into normalized results or committed artifacts.

### R12 — Machine-readable Muse lifecycle

The adapter MUST use the installed Muse build's supported machine-readable headless execution mode and derive terminal outcome from verified lifecycle records rather than scraping human terminal prose.

A zero process exit alone is not sufficient if the terminal protocol or normalized worker report is missing/invalid.

Exact argv/event names remain implementation-time details until captured from the installed workstation version.

### R13 — Timeout and process-tree cancellation

Each Muse invocation MUST have:
- an outer timeout;
- reliable stdout/stderr draining;
- cancellation of the full Muse process group/tree;
- a bounded graceful termination period followed by hard termination when required.

A timeout/cancel MUST NOT leave an active Muse child subtree behind.

### R14 — Failure classification

The adapter MUST distinguish at least:
- success;
- Muse/model failure;
- authentication/runtime availability failure;
- timeout;
- cancellation;
- missing/malformed terminal protocol;
- malformed normalized worker report;
- harness/internal failure.

Failures do not silently become successful worker completion.

### R15 — Project Workflow owns lane parallelism

Project Workflow remains authoritative for:
- Task Card dependencies;
- `parallel_safe`;
- write scopes/exclusive resources;
- isolated lane branch/worktree assignment.

When planning authorizes independent parallel Task Cards, `codex_workflow` MAY run their Muse invocations concurrently against their already assigned isolated workspaces.

Within one lane, executor → tester → optional repair → fresh tester remains ordered.

Do not use unmanaged background shell jobs as the orchestration contract.

### R16 — Workstation boundary

`chatgpt-ce-workstation` owns:
- installation of official Muse Code;
- stable runtime availability on PATH;
- disabling uncontrolled runtime self-update according to workstation policy;
- persistent `/home/codex`;
- Muse login/auth persistence;
- runtime verification surface.

It does NOT own the worker role scheduler or normalized worker lifecycle protocol.

## Acceptance-level outcomes

The Definition is satisfied when the implemented `muse-max` path can demonstrate all of the following:

1. selecting `muse-max` leaves Main unchanged, starts/reuses one internal Luna XHigh Companion, and routes the six other roles to Muse;
2. the adapter refuses roles/profiles whose active harness is not `muse-code`;
3. one executor can modify an assigned disposable workspace and return only a valid compact normalized result to Main;
4. a fresh tester independently verifies that resulting state without executor transcript inheritance;
5. an ordinary RED can flow through Main to fresh repair + fresh tester recheck;
6. raw Muse JSON/events and stderr remain outside Main context while referenced for debugging;
7. timeout/cancellation leaves no surviving worker process tree;
8. two Project Workflow-authorized non-overlapping lanes can execute safely in parallel in isolated worktrees;
9. `plus`, `luna-xhigh`, and `pro-x5` regressions remain unchanged.

## Non-goals

- adding generic delegated-worker semantics to `chatgpt_only`;
- replacing Project Workflow Task Card/state/parallel ownership;
- making workstation code the Muse worker scheduler;
- duplicate Muse-specific role TOMLs;
- Muse-native nested subagent fan-out;
- direct Muse executor ↔ Muse tester messaging;
- persistent conversational Muse worker sessions;
- `muse serve` / MSP as a prerequisite;
- redesigning all compute profiles around a generic provider abstraction;
- freezing exact Muse CLI flags before live installed-version evidence.

## Research uncertainty that does not block Planning

The following are implementation details, not unresolved strategic choices:
- exact installed Muse version and `muse exec --help` surface;
- exact JSONL terminal event names/fields;
- exact step/tool-output limit flags;
- whether bounded lane-level concurrency is implemented by concurrently awaited single-run calls or a small codex_workflow batch/pool helper;
- exact on-disk run-artifact subdirectory naming/retention numbers.

Planning MUST sequence live Muse contract capture before freezing parser/argv-specific implementation cards.

## Provenance

- accepted user choices from the 2026-09-18 brainstorming;
- `research/MUSE_MAX_RUNTIME_AUDIT_2026-09-18.md`;
- current `elmakus/codex_workflow` role/profile/runtime contracts;
- D21 in `docs/DECISIONS.md`.

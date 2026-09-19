# Muse-max runtime orchestration

Status: **approved**
Date: 2026-09-19

## Goal

Make `muse-max` a production-capable `codex_workflow` compute profile in which Codex remains Main/orchestrator, one persistent Luna XHigh Companion retains project context, and the remaining existing worker roles execute as bounded Muse Code leaf workers with compact normalized results and safe stateful worker-session reuse.

This Definition governs only `muse-max`. It does not redesign the other compute profiles and does not make `codex_workflow` aware of Project Workflow state machines or policies.

## Target architecture

```text
external caller / workflow / standalone Codex task
  -> Codex Main
       -> codex_workflow orchestration
            -> persistent Companion: internal Codex GPT-5.6 Luna XHigh
            -> logical Muse workers
                 -> micro_executor
                 -> default_executor
                 -> senior_executor
                 -> tester
                 -> investigator
                 -> archivist
                    each -> Muse Code / Muse Spark 1.3 Contributor Max
```

The caller may supply opaque task/lane/workspace identity and accepted work/verification capsules. `codex_workflow` enforces worker/runtime semantics but does not interpret the caller's project-state model.

## Requirements

### R1 — Scope is only `muse-max`

Changes for this work MUST preserve the behavior and allocations of `plus`, `luna-xhigh`, and `pro-x5`.

Regression coverage MUST prove that those profiles did not acquire Muse routing or changed lifecycle semantics.

### R2 — Codex Main remains the orchestrator

The user-selected Codex Main remains responsible inside `codex_workflow` for:
- task/package direction;
- worker selection;
- sequencing and concurrency of already-authorized worker work;
- routing bounded findings/results between workers;
- integration and acceptance of worker results;
- strategic escalation and final user communication.

A Muse worker is never the top-level orchestrator. `codex_workflow` does not own or interpret an external workflow's Task Board, review state, policy state machine, or project-level authorization semantics.

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

Harness-only lifecycle details such as durable Muse session reuse, per-turn invocation identity, locking, fail-closed resume/fallback, no intermediate sibling messaging, no nested workers and strict structured output belong in the `muse-max` runtime/orchestration layer.

### R6 — Profile-aware adapter

The Muse adapter MUST resolve:
- active compute profile;
- requested role;
- that role's `WorkerModel`;
- expected harness/model/reasoning allocation

through `compute_profiles.py` and shared runtime path semantics.

It MUST reject an invocation when the requested role is not assigned to `muse-code` in the active profile. This includes rejecting `companion` under the defined `muse-max` profile.

The adapter MUST honor `CODEX_HOME` consistently with the rest of `codex_workflow`.

### R7 — Muse workers are leaf logical sessions with bounded turns

One logical Muse worker owns one stable durable Muse `session_id` and may execute multiple sequential bounded `muse exec` turns. Every physical turn/process MUST have a separate unique `invocation_id` and private artifact set.

The runtime MUST bind a logical worker/session to:
- logical worker identity;
- semantic role;
- active `muse-max` profile/allocation;
- canonical assigned workspace;
- any opaque caller-provided task/lane scope used to prevent accidental cross-scope reuse.

At most one invocation may be active for one session at a time. Session reuse MUST NOT permit cross-role, cross-workspace or cross-lane reuse.

Muse workers MUST NOT:
- create or coordinate nested workers;
- directly message sibling Muse workers;
- reinterpret caller workflow/state semantics;
- create/switch project-level worktrees or branches unless the caller explicitly assigns that workspace.

Normal completion remains per-turn process/result driven; a durable session does not require one long-lived Muse OS process.

### R8 — Executor and Tester are independent worker identities

An implementing Executor and verifying Tester MUST always be distinct logical workers with distinct Muse sessions.

Tester:
- receives the accepted verification capsule plus actual repository/workspace state and relevant evidence;
- does not inherit the Executor trajectory by default;
- MUST NOT perform production repair;
- may be reused for later full verification turns while it remains independent of implementation.

Executor findings/changes reach Tester only through Main/caller-provided verification context and shared durable workspace state. Tester findings reach the owning Executor through Main.

### R9 — RED repair loop prefers owning-worker reuse

For an ordinary production defect:

```text
Executor A1 -> implementation target S1
Tester B1   -> independent full verification of S1 -> RED + focused findings
Main        -> routes bounded findings to owning Executor
Executor A1 -> resume -> repair -> changed target S2
Tester B1   -> resume -> full independent verification of S2
```

The S2 turn MUST be a full verification of the current target, not merely a check that the old finding disappeared.

Reuse of A1/B1 is allowed regardless of the size of the changed target as long as role independence still holds and the session can be safely resumed.

A fresh replacement A2/B2 is required only when:
- a controlling higher-level contract explicitly requires a fresh worker/context;
- the existing session is unavailable, corrupt, unsafe to resume, or violates its binding;
- Main has a material reason to request a fresh independent context.

A changed target by itself MUST NOT automatically require B2.

If replacement is required, recovery uses durable evidence/workspace state and the replacement receives a new logical/session identity. The runtime MUST never silently mint a new session while continuing to present it as A1/B1.

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

Runtime-owned session/invocation metadata may be returned to Main for orchestration, but must not be injected into external workflow state unless that caller explicitly chooses to persist a semantic reference.

Main MUST NOT receive full reasoning, tool-call streams, raw test stdout, or large diffs on the normal path.

### R11 — Raw event/log isolation

The adapter MUST drain Muse stdout/stderr and persist the raw machine-readable event stream and diagnostic stderr outside ordinary Main context and project Git.

Run artifacts SHOULD live under persistent user runtime data beneath `~/.codex` with bounded retention by age/count/size.

No auth/session secret may be intentionally copied into normalized results or committed artifacts.

### R12 — Machine-readable Muse lifecycle

The adapter MUST use the installed Muse build's supported machine-readable headless execution mode and derive terminal outcome from verified lifecycle records rather than scraping human terminal prose.

A zero process exit alone is not sufficient if the terminal protocol or normalized worker report is missing/invalid.

Resume MUST use the installed Muse runtime's verified durable-session mechanism. The implementation may use `muse exec --session-id` and an existence/health probe or an equivalent native surface proven on the installed build; it must not assume that passing a UUID proves an existing session was resumed.

### R13 — Timeout, cancellation and interrupted-turn reconciliation

Each Muse invocation MUST have:
- an outer timeout;
- reliable stdout/stderr draining;
- cancellation of the full Muse process group/tree;
- a bounded graceful termination period followed by hard termination when required.

A timeout/cancel MUST NOT leave an active Muse child subtree behind.

After an interrupted turn, the runtime MUST:
- release the session lease only after process-tree cleanup is confirmed;
- inspect/return enough workspace-side-effect evidence for Main to reason about partial changes;
- probe the exact session before reuse;
- either resume safely or fail closed to explicit replacement;
- never treat interruption as automatic proof that either resume or replacement is safe.

### R14 — Failure and recovery classification

The adapter MUST distinguish at least:
- success;
- Muse/model failure;
- authentication/runtime availability failure;
- timeout;
- cancellation;
- missing/malformed terminal protocol;
- malformed normalized worker report;
- harness/internal failure;
- session unavailable/not retained;
- session binding mismatch;
- session busy/lease conflict;
- resume rejected/unsafe.

Failures do not silently become successful worker completion, and resume failure does not silently become a new session under the old logical identity.

### R15 — Caller owns work authorization; codex_workflow enforces runtime isolation

The external caller/Main remains authoritative for:
- task dependencies;
- whether work may run concurrently;
- write ownership/exclusive resources;
- branch/worktree/workspace assignment;
- any project-level review or lifecycle state.

`codex_workflow` MAY concurrently await already-authorized independent Muse invocations against caller-assigned non-overlapping workspaces.

For runtime safety it MUST:
- reject equal/nested conflicting workspaces for concurrent lanes;
- keep each lane's Executor/Tester logical sessions distinct from every other lane;
- prevent cross-lane session reuse;
- serialize turns within each individual session with a lease/lock.

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

### R17 — codex_workflow is policy/state-machine agnostic

`codex_workflow` provides runtime/orchestration semantics only.

It MUST NOT own or interpret:
- Project Workflow execution policy;
- Project Workflow Task Board lifecycle;
- Project Workflow review-state transitions;
- Project Workflow immutable review-attempt bookkeeping;
- another caller's equivalent project/state-machine concepts.

Muse `session_id`, adapter `invocation_id`, session registry/bindings, leases, resume probes and fallback mechanics are exclusively `codex_workflow` runtime details.

A higher-level workflow MAY treat a Tester result as its formal independent-review verdict and MAY persist its own subject/attempt/evidence state, but that interpretation is outside `codex_workflow`.

## Acceptance-level outcomes

The Definition is satisfied when the implemented `muse-max` path can demonstrate all of the following:

1. selecting `muse-max` leaves Main unchanged, starts/reuses one internal Luna XHigh Companion, and routes the six other roles to Muse;
2. the adapter refuses roles/profiles whose active harness is not `muse-code`;
3. one Executor logical worker can execute multiple turns with stable session context while each turn has a distinct invocation/artifact identity;
4. Executor and Tester use distinct sessions, Tester does not repair production, and Tester does not inherit Executor trajectory;
5. the live lifecycle `A1 implement S1 -> B1 RED -> A1 repair S2 -> B1 full recheck GREEN` succeeds using the same A1/B1 sessions;
6. an unavailable/unsafe A1 or B1 resume fails closed to an explicit A2/B2 recovery path without identity masquerading;
7. raw Muse JSON/events/stderr remain outside ordinary Main context and project Git while bounded normalized results remain valid;
8. timeout/cancellation leaves no surviving worker process tree, and a live Meta-backed interrupted-turn fault-injection proves safe resume or safe fail-closed replacement;
9. two caller-authorized non-overlapping lanes can execute concurrently with lane-local Executor/Tester sessions and no cross-lane reuse or artifact collision;
10. `plus`, `luna-xhigh`, and `pro-x5` regressions remain unchanged;
11. the runtime works without reading or mutating Project Workflow Task Board/review-policy state.

## Non-goals

- implementing Project Workflow or another project/state-machine policy inside `codex_workflow`;
- defining future Project Workflow `codex_only` durable review-state semantics;
- adding generic delegated-worker semantics to `chatgpt_only`;
- making workstation code the Muse worker scheduler;
- duplicate Muse-specific role TOMLs;
- Muse-native nested subagent fan-out;
- direct Muse executor ↔ Muse tester messaging;
- one permanently running Muse OS worker process;
- making `muse serve` / MSP a prerequisite when headless session reuse is sufficient;
- redesigning all compute profiles around a generic provider abstraction.

## Research uncertainty that does not block Planning

The following are implementation details, not unresolved strategic choices:
- exact private session-registry/storage layout and retention;
- exact locking primitive used to enforce one active invocation per session;
- whether the fail-closed existence/health probe uses `muse export --session`, MSP/session-store APIs, or another installed-build surface with equivalent proven behavior;
- exact normalized metadata fields used internally for logical-worker/session recovery;
- exact implementation split between reusable adapter primitives and Main-facing orchestration helpers.

Planning MUST include a live Meta-backed interrupted-turn fault-injection gate before stateful reuse becomes the default `muse-max` lifecycle.

## Provenance

- accepted user choices from the 2026-09-18 brainstorming;
- `research/MUSE_MAX_RUNTIME_AUDIT_2026-09-18.md`;
- `research/MUSE_SESSION_RESUME_LIFECYCLE_2026-09-19.md`;
- live Muse Code 1.3.0 stateful-session evidence captured on 2026-09-19;
- current `elmakus/codex_workflow` role/profile/runtime contracts;
- D21 in `docs/DECISIONS.md`.

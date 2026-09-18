# Muse-max production runtime Master Plan

Status: **approved**
Date: 2026-09-18

## Authority

This plan organizes the accepted Muse-max Project Definition without changing it.

Canonical authority:
- `requirements/MUSE_MAX_RUNTIME.md`;
- `docs/DECISIONS.md#d21--muse-max-is-a-mixed-harness-codex_workflow-profile`;
- `research/MUSE_MAX_RUNTIME_AUDIT_2026-09-18.md`.

Relevant implementation baselines:
- `elmakus/codex_workflow@f2b1811853a2c1da5a5af4bb735c84c3111a44d6`;
- workstation Muse installation/runtime baseline from completed M03 and current workstation `main`.

The earlier `planning/MUSE_DELEGATED_WORKERS_MASTER_PLAN.md` is superseded and is not execution authority.

## Goal and target state

Deliver a production-capable `muse-max` profile in `elmakus/codex_workflow` where:

- Codex Main remains the orchestrator;
- one persistent internal Companion uses GPT-5.6 Luna XHigh;
- the other six existing workflow roles use Muse Spark 1.3 Contributor / max through native Muse Code;
- Muse execution is profile-aware, bounded, machine-readable, cancellable and context-isolated;
- executor/tester/repair semantics remain independently grounded;
- Project Workflow-authorized independent lanes can use safe bounded concurrency in isolated worktrees;
- `plus`, `luna-xhigh`, and `pro-x5` are unchanged.

## Global invariants

- Only `muse-max` behavior may change unless live evidence proves a workstation runtime correction is required.
- Existing `agents/*.toml` remain the canonical role-semantic definitions; no parallel Muse role tree.
- `compute_profiles.py` remains the authority for role → model/reasoning/harness allocation.
- Muse workers are leaf one-shot invocations; no nested Muse agents and no direct Muse sibling messaging.
- Main receives compact normalized results, not raw Muse trajectories.
- Raw event/stderr artifacts stay outside project Git and ordinary Main context.
- Project Workflow owns Task Card dependencies, ownership, `parallel_safe`, lane branches/worktrees and project state.
- This project's current `chatgpt_only` implementation route remains serial even though the target `codex_workflow` feature will support Project Workflow-authorized parallel lanes for runtimes/policies that permit them.
- Exact Muse argv/event fields are not frozen before live evidence from the installed workstation build.
- Live Unraid build/recreate/login/runtime mutation requires an explicit authorization gate.

## Milestone M05 — Capture the live Muse runtime contract

### Outcome

The exact Muse Code build installed in the workstation has a durable, source-grounded headless-runtime contract sufficient to implement the adapter without guessing CLI flags, JSONL events, exit semantics or sandbox behavior.

### Requirement ownership

Primary: R12, R16.

Provides required implementation evidence for R6, R10, R11, R13 and R14.

### Dependencies

- M03 workstation Muse installation baseline complete.
- Approved Muse-max Definition/D21.

### Planned work packages

- Refresh the live workstation from then-current workstation `main` using the normal supported deployment path.
- Capture exact:
  - `muse --version`;
  - `muse --help` only where needed;
  - `muse exec --help`.
- Verify Muse subscription login in persistent `/home/codex` and persistence across restart/recreate where the normal deployment sequence already requires recreation.
- Run bounded disposable-repository probes for:
  - read-only/headless machine-readable execution;
  - workspace-write execution;
  - one controlled model/runtime failure;
  - stderr versus stdout behavior;
  - sandbox/write boundaries;
  - relevant network/tool availability for Investigator;
  - process/subprocess behavior needed for later cancellation tests.
- Record exact observed JSONL terminal/lifecycle records and exit-code behavior without committing credentials or raw sensitive session material.
- Record only evidence needed to bind later implementation; do not redesign `muse-max` here.

### Stable acceptance/checkpoint

M05 is GREEN when durable evidence identifies:
- exact installed Muse version;
- exact supported headless/machine-readable argv needed by the adapter;
- terminal event/result shape sufficient for deterministic parsing;
- exit/stderr behavior for success and controlled failure;
- observed sandbox/write/network boundaries relevant to the six Muse roles;
- persistent authentication behavior;
- no secret material in committed evidence.

### Gate

**Explicit live-operation authorization required before Unraid build/recreate/login/runtime work.**

If live access cannot be performed by the executing chat, persist the exact blocker/evidence need and request only the smallest user-run command/output set.

### JIT trigger

Exact parser/argv Task Cards for M07 must be created only from M05 evidence.

---

## Milestone M06 — Establish mixed-harness `muse-max` profile semantics

### Outcome

`elmakus/codex_workflow` represents the accepted mixed profile correctly and prevents profile/harness leakage before deeper Muse protocol handling is added.

### Requirement ownership

Primary: R1–R7.

Supports R16 boundary documentation.

### Dependencies

- M05 GREEN is preferred so profile documentation can name only verified live prerequisites, but M06 implementation itself must not depend on unverified JSON field details.

### Planned work packages

- Change only the `muse-max` allocation in `compute_profiles.py`:
  - `companion` → internal Codex GPT-5.6 Luna XHigh;
  - remaining six roles → Muse Contributor/max with `muse-code`.
- Preserve all other compute-profile allocations exactly.
- Make Companion lifecycle under `muse-max` use the normal persistent internal Codex path.
- Remove/supersede wording that says every `muse-max` role is Muse or that Companion is a one-shot Muse worker.
- Keep existing role TOMLs canonical; make only provider-neutral wording corrections that are required to avoid false model identity claims.
- Refactor the Muse runner boundary enough to:
  - resolve active profile and role allocation through `compute_profiles.py`;
  - honor shared `CODEX_HOME`/runtime path semantics;
  - reject a role whose active harness is not `muse-code`;
  - stop duplicating model/reasoning allocation constants.
- Extend focused profile tests and general regression tests to prove `plus`, `luna-xhigh`, and `pro-x5` remain unchanged.

### Stable acceptance/checkpoint

- `muse-max` resolves exactly one internal Companion and six Muse roles.
- `companion` cannot be launched through the Muse adapter.
- Muse adapter cannot be used to bypass the active profile's per-role harness allocation.
- Other profiles' model/reasoning/harness and lifecycle tests are unchanged/green.
- No duplicate Muse role definition exists.
- Documentation and tests no longer contain contradictory “all seven Muse” semantics.

### Review strategy

No separate publication is required solely for M06. Preserve an exact checkpoint and regression evidence; final production review occurs after the complete runtime subject exists.

---

## Milestone M07 — Build the production Muse process/result adapter

### Outcome

The Muse runtime adapter is a deterministic, profile-aware process boundary that converts verified Muse machine-readable output into a compact `codex_workflow` result while isolating raw trajectories.

### Requirement ownership

Primary: R6, R7, R10–R14.

Supports R4, R5 and R16.

### Dependencies

- M05 exact runtime evidence GREEN.
- M06 mixed-profile semantics GREEN.

### Planned work packages

- Define a versioned internal normalized result contract for common worker fields and tester verdict fields.
- Implement the Muse-only runtime overlay requiring one final structured worker report without changing shared role semantics.
- Build Muse argv strictly from M05-supported CLI behavior and active `WorkerModel`.
- Spawn workers with:
  - assigned cwd/workspace;
  - stdin behavior appropriate to headless operation;
  - continuous stdout/stderr draining;
  - raw machine-readable event persistence outside project Git/Main context;
  - deterministic terminal-event parsing;
  - validated final worker report;
  - bounded Main-facing JSON result.
- Add run identity/artifact references and bounded retention policy in persistent user runtime data under `~/.codex`.
- Implement timeout and process-group/tree cancellation with graceful-then-hard termination.
- Classify success, model/runtime/auth failure, timeout, cancellation, protocol failure, normalized-report failure and adapter/internal failure.
- Collect bounded repository evidence such as changed paths/diff-stat where useful without copying large diffs into Main results.
- Protect normalized output/logging against accidental credential/session leakage.
- Add deterministic fixture/fake-process tests for event parsing, malformed streams, cancellation, timeout, result validation and profile rejection.
- Add a targeted live adapter smoke on the workstation after deterministic tests pass.

### Stable acceptance/checkpoint

- Successful worker run produces exactly one bounded normalized Main-facing result.
- Raw Muse JSONL/stderr are persisted but not forwarded as normal Main output.
- Missing/malformed terminal event or worker report fails closed.
- Timeout/cancel leaves no surviving Muse process subtree.
- Adapter uses active profile/model/harness authority rather than duplicated constants.
- Deterministic protocol/process tests are GREEN.
- One live read-only and one live write smoke using the actual installed Muse build are GREEN.

### OpenSpec boundary

The normalized result/failure protocol is an internal cross-module runtime contract. If `codex_workflow` has no OpenSpec mechanism, encode the contract in the owning runtime module/tests/documentation rather than creating a second specification system solely for this work.

---

## Milestone M08 — Verify sequential role orchestration and RED repair

### Outcome

The complete single-lane `muse-max` behavior works end to end with the existing `codex_workflow` roles and preserves independent verification.

### Requirement ownership

Primary: R2–R9.

Also verifies R10–R14 in real orchestration.

### Dependencies

- M07 production adapter GREEN.

### Planned work packages

- Verify one persistent internal Luna XHigh Companion under active `muse-max`.
- Exercise all six Muse-routed roles sufficiently to prove routing and role boundaries:
  - Micro/Default/Senior Executor;
  - Tester;
  - Investigator;
  - Archivist.
- Run an executor-shaped disposable implementation package.
- Run a fresh Tester against accepted authority + resulting workspace state without executor transcript.
- Exercise a deliberate ordinary RED:
  - Tester returns focused findings;
  - Main constructs a bounded repair capsule;
  - fresh owning Executor repairs;
  - fresh Tester rechecks.
- Verify cross-boundary findings stop at Main instead of silently expanding worker authority.
- Verify worker raw logs are not copied into later worker capsules or Main normal context.
- Verify no Muse worker creates nested workers or directly messages another Muse worker.

### Stable acceptance/checkpoint

- Companion persistence and six-role routing match D21.
- Executor → fresh Tester GREEN path works.
- RED → fresh repair Executor → fresh Tester path works.
- Tester does not inherit executor transcript.
- Main remains acceptance/orchestration authority.
- Investigator/Archivist behavior is viable under observed sandbox/network/write boundaries or any unsupported capability is explicitly surfaced without violating role ownership.
- No hidden conversation continuity is required between Muse invocations.

### JIT trigger

If M08 reveals a role-specific live limitation that does not change Definition, Execution Prep may create bounded corrective work. A limitation that changes the accepted six-role target returns to Project Definition.

---

## Milestone M09 — Add bounded lane concurrency and promote the complete runtime

### Outcome

The reviewed `muse-max` implementation supports safe Project Workflow-authorized parallel lanes, is published through the normal `codex_workflow` release path, and is validated on the workstation as the production candidate.

### Requirement ownership

Primary: R1, R15, R16.

Final integrated verification for R1–R16.

### Dependencies

- M08 GREEN.
- Exact concurrency mechanism becomes knowable from the M07 adapter shape and M08 orchestration evidence.

### Planned work packages

- Choose the smallest managed concurrency mechanism consistent with the accepted Definition:
  - concurrently awaited independent adapter calls; or
  - a small `codex_workflow` batch/pool wrapper over the same single-run adapter.
- Keep worker process ownership explicit and cancellation scoped per invocation/lane.
- Do not add a second project scheduler or task database.
- Use two isolated non-overlapping worktrees/lanes whose Project Workflow authority marks them safe for parallel execution.
- Demonstrate concurrent Muse invocations without shared mutable index/worktree or raw-log collision.
- Run complete `codex_workflow` regression coverage, including unchanged `plus`, `luna-xhigh`, and `pro-x5`.
- Freeze the exact complete implementation subject for independent review before production promotion.
- Correct bounded review findings as required and obtain GREEN on the final subject.
- Publish through the existing `codex_workflow` owner release/update channel.
- With explicit live authorization, update the workstation runtime to the reviewed release and perform final smoke:
  - active `muse-max`;
  - persistent Luna XHigh Companion;
  - Muse executor + fresh Tester;
  - one safe two-lane parallel run where the available Project Workflow/runtime supports it.

### Stable acceptance/checkpoint

- Two independent authorized lanes execute concurrently in isolated workspaces without mutation/log/state collisions.
- A lane failure/cancel does not corrupt or silently cancel an unrelated healthy lane.
- Complete profile regressions are GREEN.
- Final exact subject receives independent review GREEN.
- Published `codex_workflow` release is exactly the reviewed subject.
- Live workstation update/readback confirms the reviewed release and target `muse-max` behavior.
- No workstation-side second scheduler, generic Project Workflow delegated-worker runtime or duplicate Muse role contracts were introduced.

### Gates

- Publication follows normal repository/release authority.
- Live workstation update/recreate/runtime validation requires explicit live-operation authorization.

---

## Requirement coverage

| Requirement | Owning milestone(s) |
| --- | --- |
| R1 only muse-max changes | M06, M09 |
| R2 Codex Main orchestrator | M06, M08, M09 |
| R3 persistent Luna XHigh Companion | M06, M08, M09 |
| R4 six Muse roles | M06, M08 |
| R5 shared role contracts | M06 |
| R6 profile-aware adapter | M06, M07 |
| R7 leaf one-shot Muse workers | M06, M07, M08 |
| R8 separate executor/tester | M08 |
| R9 RED repair through Main | M08 |
| R10 compact normalized result | M07, M08 |
| R11 raw log isolation | M07, M08 |
| R12 machine-readable Muse lifecycle | M05, M07 |
| R13 timeout/process-tree cancellation | M07 |
| R14 failure classification | M07 |
| R15 Project Workflow-owned parallelism | M09 |
| R16 workstation boundary | M05, M09 |

Every requirement has a milestone owner and an execution path. Exact M07 protocol Cards are intentionally deferred until M05 evidence exists; exact M09 concurrency Cards are intentionally deferred until M07/M08 evidence exists.

## System verification strategy

```text
current source/baseline readback
  -> M05 live CLI/auth/JSONL/sandbox evidence
  -> M06 profile-allocation + other-profile regression tests
  -> M07 deterministic process/protocol fixtures
  -> M07 live single-worker smoke
  -> M08 sequential executor/tester/RED-repair role pilot
  -> M09 isolated two-lane concurrency test
  -> full codex_workflow regression
  -> independent review of exact final subject
  -> release exact reviewed subject
  -> live workstation update/readback + final smoke
```

No passing claim may be upgraded from simulated/fixture evidence to live behavior without the corresponding live checkpoint.

## Security, data integrity and idempotency

- Do not commit Muse credentials/session state or raw user-home auth artifacts.
- Normalized results must not intentionally contain secrets.
- Raw logs remain in persistent user runtime storage, not project Git or Task Board.
- Retention is bounded so trajectories cannot grow indefinitely.
- Each worker invocation has independent run identity/artifact files so concurrency cannot overwrite logs.
- Workers receive an assigned workspace and do not change project-level Git/worktree ownership.
- Failure/cancel does not advance Project Workflow state by itself.
- Re-running a failed worker uses durable repository/worktree state plus a fresh invocation, not hidden Muse conversation continuity.
- Profile switching/updates must preserve other profiles and existing user/project state according to current `codex_workflow` lifecycle contracts.

## Rollback / recovery

Before production promotion:
- work remains isolated on implementation branches/checkpoints;
- active users can stay on another existing compute profile;
- a failed Muse invocation is recoverable from workspace state + compact/durable evidence with a fresh invocation.

After release:
- the prior `codex_workflow` release remains the rollback reference;
- switching away from `muse-max` must preserve the existing `plus`, `luna-xhigh`, and `pro-x5` paths;
- workstation image rollback is not the primary rollback mechanism unless M05/M09 evidence requires a workstation-source correction.

## JIT decomposition policy

Execution Prep should create only currently knowable Cards.

- M05 Cards may be prepared immediately from the current workstation runtime baseline, but execution stops at the explicit live authorization gate before live writes/actions.
- M06 Cards may be prepared from current `codex_workflow` source and D21.
- M07 parser/argv-specific Cards are created only after M05 evidence.
- M08 role-pilot Cards are created only after M07 normalized adapter behavior is real.
- M09 concurrency/release Cards are created only after M07/M08 establish the actual adapter/orchestration shape.

Do not create placeholder future Cards merely to fill the Task Board.

## Planning audit

GREEN.

- Definition preconditions are complete and internally coherent.
- Milestone order prevents guessed Muse CLI/protocol details from leaking into implementation.
- Mixed-profile semantics are separated from provider-protocol implementation.
- Sequential role correctness precedes concurrency.
- Concurrency remains subordinate to Project Workflow lane/worktree authority.
- Other compute profiles have explicit regression protection.
- Live authorization gates are explicit at both discovery and final deployment.
- Security/log retention/process cancellation and rollback are covered.
- No duplicate scheduler, role hierarchy or generic delegated-worker framework is introduced.
- Remaining uncertainties are implementation-time evidence/JIT choices already classified by the approved Definition; none requires a new strategic user decision.

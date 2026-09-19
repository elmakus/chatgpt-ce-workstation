# Muse-max stateful worker session lifecycle research — 2026-09-19

## Scope and authority

This is research/evidence only. It does not change the accepted `muse-max` architecture, D21, Project Definition, production `codex_workflow`, or workstation deployment.

Question tested: whether the current fresh follow-up pattern can technically be replaced by a stateful lane-local cycle:

```text
Executor A1 -> Tester B1 -> Executor A1 repair -> Tester B1 recheck
```

The desired property is reuse of the same durable Muse session/context for A1 and separately for B1, while preserving Executor/Tester isolation and exact-subject verification.

## Exact runtime/source examined

- workstation Muse Code: `1.3.0 (1.3.0-R3401.1)`;
- production `codex_workflow`: `v1.1.17-private.11`;
- exact source subject: `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- active production profile remained `muse-max` before and after the research;
- no production source/runtime/profile mutation was made.

Installed CLI help was read directly from the live workstation. Relevant surfaces on this exact binary are:

- `muse exec --session-id <UUID>`;
- `muse resume <session-ref>`, where the ref can be an exact session UUID;
- `muse export --session <id|path>`;
- `muse serve` as a durable MSP session host;
- the exact embedded MSP schema contains `session/start`, `session/list`, `session/resume`, `session/close`, and `turn/cancel`.

The official Meta Muse Code changelog also documents the headless resume remedy as `exec --session-id <uuid>`, plus crash/restart reconciliation and `muse serve` resume behavior.

## Current adapter finding

Current `codex_workflow/runtime/muse_worker.py` already passes a UUID to Muse as `--session-id`, but the same value is also used as the adapter's private run/artifact directory id.

Current flow is effectively:

```text
resolved_run_id
  -> ~/.codex/codex_workflow/muse_runs/<resolved_run_id>/
  -> muse exec ... --session-id <resolved_run_id>
```

A second adapter invocation with the same UUID is rejected before Muse starts because the existing artifact directory causes:

```text
run artifact directory already exists
```

Therefore the present one-shot behavior is an adapter identity-model limitation, not a demonstrated Muse runtime limitation.

The required design split is:

```text
session_id     = stable durable Muse worker identity/context
invocation_id  = unique id for one subprocess/turn and its artifacts
```

## Controlled live cycle

A disposable Git workspace and private temporary harness artifacts were used. The production workflow runtime was not modified.

Two distinct durable Muse session UUIDs were created:

- one session for Executor A1;
- one separate session for Tester B1.

Each step was a fresh `muse exec` OS process. A stable `--session-id` was reused only within the same logical role.

### A1 initial

Executor A1 implemented a small `clamp` contract with one deliberate, bounded above-range defect.

The resulting exact review subject was committed in the disposable repository.

A private continuity token was given only to A1's first prompt, with explicit instruction not to write it to the workspace and not to return it in that first result.

### B1 initial review

Tester B1 received:

- the accepted contract;
- the exact Git review subject;
- current repository/workspace state.

B1 did not receive the Executor transcript/result or private Muse harness artifacts.

B1 returned structured `RED` with the focused finding that the above-range branch returned the input value rather than `high`.

A different private continuity token was given only to B1's first prompt, also with explicit instruction not to write it to the workspace or return it yet.

### A1 resumed repair

A new `muse exec` process was started with the same Executor session UUID as A1.

It received only the contract plus B1's focused findings and repaired the defect.

The result returned the exact private token from A1's first turn without reading session logs/files, proving preserved session context across processes.

A new exact Git subject was committed after the repair.

### B1 resumed recheck

A new `muse exec` process was started with the same Tester session UUID as B1.

The prompt explicitly bound the recheck to the new exact Git subject and stated that the previous RED belonged to a different subject and was not evidence for the new subject.

B1 independently reran verification against current repository state and returned structured `GREEN`.

The result returned the exact private token from B1's first turn without reading session logs/files, proving preserved Tester context across processes.

### Live-cycle result

```text
A1 initial       -> completed
B1 review        -> RED
A1 same session  -> repair completed
B1 same session  -> GREEN recheck
```

Additional readback:

- Executor and Tester session UUIDs were distinct;
- initial and repaired Git subjects were distinct;
- both continuity proofs succeeded;
- continuity tokens were absent from the workspace;
- final direct contract probes were GREEN;
- every one of the four headless turns emitted exactly one terminal lifecycle event;
- structured `--output-schema` output continued to work on resumed sessions.

The live event stream also showed the same durable session stream id across A1 initial/repair and across B1 review/recheck, while each turn had a distinct command/run identity. This directly supports a stable session id plus unique invocation id design.

## Session existence and fail-closed resume

`muse export --session <UUID> --redacted` succeeded offline for both retained A1/B1 sessions after the cycle.

The same command against an unknown random UUID returned non-zero with an explicit "no retained session log found" diagnostic.

This matters because `muse exec --session-id <UUID>` is also how a new session is created. A resume implementation must therefore not blindly pass a stored UUID and assume continuation occurred.

Recommended resume precondition:

1. session mapping says the worker is in resumable state;
2. exact session is confirmed present/usable in the Muse session store;
3. role/profile/model/workspace binding still matches;
4. no concurrent invocation owns that session;
5. only then launch the next turn with the stable `session_id`.

The tested `muse export --session` lookup is a usable fail-closed existence probe on the installed binary. A production implementation may use a lighter native session-store/MSP query if available, but it must preserve equivalent fail-closed semantics.

## Executor / Tester isolation

Stateful reuse does not require sharing a session between roles.

The safe topology is:

```text
lane X:
  Executor A1 -> Muse session EA
  Tester   B1 -> Muse session TB

EA != TB
```

Main remains the only bridge. Tester sees accepted verification authority plus repository state, not Executor trajectory. Executor receives bounded Tester findings through Main, not the Tester trajectory.

The live cycle validated this topology.

## Exact-subject and independent verification semantics

A resumed B1 can safely recheck a new exact subject if the turn is explicitly rebound to the new immutable subject and required to rerun verification from current repository state.

The previous RED can remain contextual memory for what to recheck, but it must not be treated as evidence that the new subject is GREEN.

For implementation-level Muse verification, the same B1 session therefore preserves Executor independence while adding useful continuity.

This must not be confused with Project Workflow's formal REQUIRED/RECOMMENDED independent review boundary. A resumed Muse Tester is not a replacement for the separate fresh normal-ChatGPT independent-review session required by Project Workflow.

## Parallel Task Card lanes and worktrees

Session identity must be lane-scoped, not global by role name.

Recommended logical key:

```text
(workstream/task-card, lane, role-instance) -> session_id
```

Each parallel lane/worktree gets its own Executor and Tester sessions. Normal resume must remain pinned to the same canonical workspace/worktree. The installed CLI exposes `--allow-workspace-switch`, but normal `muse-max` follow-up should not use it.

The current concurrency rule requiring non-overlapping workspaces remains appropriate.

Add one further invariant: the same Muse `session_id` must never have two active invocations concurrently. Use a per-session lease/lock.

## Timeout, cancellation, and recovery

Current adapter timeout/cancellation logic is already process-tree aware: it sends termination to the process group/tree, waits a bounded grace period, then escalates to kill. The existing adapter test suite covers child-process cleanup for both timeout and cancellation.

The installed Muse runtime and embedded MSP expose durable resume/cancel surfaces, and the official changelog documents crash/restart reconciliation.

However, this research did not complete a live fault-injection proof that an actual Meta-backed session can always be safely resumed after the adapter kills a mid-turn process. An attempted cheap `echo`-provider fault injection hit a CLI parser incompatibility for the desired delayed headless invocation and was not counted as evidence.

Production behavior should therefore be conservative:

- timeout/cancel marks the invocation failed/aborted, not the logical session automatically dead;
- release the process/session lease only after process-tree absence is confirmed;
- inspect actual workspace state before retry because a killed turn may have already produced partial side effects;
- probe session health/existence before attempting resume;
- if resume is unavailable/corrupt/locked, fail closed and let Main choose a documented replacement path;
- never silently mint a new session under the old logical A1/B1 identity.

A dedicated live timeout/cancel/resume fault-injection test remains required before promoting stateful reuse as the default production lifecycle.

## Structured output and adapter compatibility

The existing per-turn normalized result contract can be retained.

The live resumed turns proved that `muse exec --json --output-schema ... --session-id <stable-session>` still produces one terminal record and one schema-conformant final answer per invocation.

The adapter should add transport-owned metadata rather than asking the model to self-report it:

- `session_id`;
- `invocation_id`;
- `logical_worker_id`;
- `resumed: true|false`;
- workspace binding/fingerprint;
- exact verification/review subject where applicable.

Raw Muse trajectory remains private and outside Main context.

## Recommended lifecycle for muse-max

Recommended target behavior, subject to an accepted architecture update and implementation review:

```text
Main allocates lane
  |
  +-- create Executor A1 session EA
  |     |
  |     +-- invocation E1
  |
  +-- create Tester B1 session TB
        |
        +-- invocation T1 -> RED
               |
Main passes bounded findings
               |
EA resume -> invocation E2 repair
               |
new exact subject
               |
TB resume -> invocation T2 full recheck -> GREEN
```

Retire EA/TB when the lane/Task Card lifecycle closes. A later unrelated Card must not inherit those sessions by role name alone.

If EA cannot be resumed, Main may create a fresh repair Executor only under an explicit fallback rule and must record that continuity was lost.

If TB cannot be resumed, a fresh Tester can independently verify the new subject and is semantically safe, but it must be recorded as B2 rather than falsely presented as resumed B1.

## Conclusion

**Technical result: GREEN for normal stateful continuation.**

The installed Muse Code runtime genuinely preserves context across separate headless `muse exec` processes when the same session UUID is reused. The full requested A1 -> B1 -> A1 -> B1 cycle worked live, including RED -> repair -> GREEN and independent Executor/Tester sessions.

The current production adapter cannot expose this lifecycle because it conflates Muse `session_id` with one-shot adapter `run_id`.

The fresh follow-up model is therefore not technically required by Muse. Moving to stateful A1/B1 reuse is feasible, but production promotion should wait for:

1. accepted change to the current D21/fresh-follow-up contract;
2. adapter split of stable session identity from per-turn invocation identity;
3. fail-closed session existence/health validation;
4. per-session locking and lane/workspace binding;
5. explicit fallback semantics;
6. a dedicated live timeout/cancel/session-loss recovery test.

No production change was made by this research.

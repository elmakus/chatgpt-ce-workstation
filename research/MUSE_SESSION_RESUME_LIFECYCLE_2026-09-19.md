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

## Exact-subject and independent-review semantics

A resumed B1 can safely review a new exact subject if the turn is explicitly rebound to the new immutable subject and required to rerun the full applicable verification from current repository state.

The previous RED can remain contextual memory for what to recheck, but it is not passing evidence for the new subject. A repair that changes S1 into S2 creates a new exact review subject/attempt even when the same independent Tester B1 performs both attempts.

The key independence property is role/ownership separation, not mandatory reviewer amnesia:

- B1 did not implement S1 or S2;
- B1 never performs production repair;
- Executor trajectory is not Tester input;
- Main is the only bridge for focused findings and orchestration;
- the S2 recheck is a full review of S2 against the current acceptance surface, not merely a regression probe for the old finding.

Policy distinction matters:

- under the currently accepted `chatgpt_only` route, Project Workflow's REQUIRED/RECOMMENDED implementation review boundary is still a fresh normal-ChatGPT boundary because that policy explicitly defines it that way;
- a future `codex_only` policy may instead define the independent Tester worker as the formal Project Workflow reviewer. In that policy, B1's formal verdict/evidence can satisfy the review obligation directly, with no additional fresh normal-ChatGPT review, provided B1 remained independent of the implementation and the policy's review contract is satisfied;
- reuse of B1 across S1 -> S2 is compatible with formal independent review when the correction is bounded and the acceptance/authority surface has not materially changed;
- if scope, authority, acceptance, security, migration surface, or another material review boundary changes, Main may require a fresh independent Tester B2 even if B1 remains technically resumable.

This research does not itself create or authorize `codex_only`. Current Project Workflow `main` has no dedicated `codex_only` route; the target semantics above must be established by that future policy before it can govern formal Project Workflow review.

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

## Current codex_workflow contract compatibility

The current `codex_workflow` semantic worker contracts are compatible with the proposed lifecycle:

- `agents/tester.toml` already defines Tester as an independent verification engineer, permits inspection/testing but forbids production repair, durable documentation changes, and Git-state mutation;
- `agents/default_executor.toml` already assigns ordinary repair to the Executor;
- the generic Heavy orchestration guidance already says `ordinary Tester defect -> owning Executor repair -> same Tester recheck`;
- Tester and Executor remain distinct roles with separate contexts and ownership.

The conflict is in the current `muse-max` transport overlay, not the semantic roles:

- `heavy_route.md` currently says Muse-backed roles are one-shot and that repair/follow-up/recovery/independent review uses a fresh invocation;
- `delegation.md` says Muse follow-up/repair launches a new invocation and fresh independent review uses a fresh Tester invocation;
- README/ownership documentation describes the six Muse roles as fresh one-shot calls;
- `runtime/muse_worker.py` conflates `run_id` with Muse `session_id`, making actual session reuse impossible through the adapter.

Therefore the stateful design can preserve the existing Executor/Tester role contracts. The required change is orchestration/runtime lifecycle semantics for `muse-max`.

## Recommended lifecycle for muse-max

Recommended target behavior, subject to accepted authority updates and implementation review:

```text
Main allocates lane
  |
  +-- create Executor A1 logical worker/session EA
  |     |
  |     +-- invocation E1 -> exact implementation subject S1
  |
  +-- create independent Tester B1 logical worker/session TB
        |
        +-- invocation T1 -> formal review attempt of S1 -> RED
               |
Main records RED + passes bounded findings
               |
EA resume -> invocation E2 repair -> exact subject S2
               |
TB resume -> invocation T2 -> full formal review attempt of S2 -> GREEN
               |
Main records formal verdict/evidence and continues
```

For an ordinary bounded repair, reuse of the owning Executor A1 and independent Tester B1 is preferred.

Retire EA/TB when the lane/Task Card lifecycle closes. A later unrelated Card must not inherit those sessions merely because the role name matches.

Fail-closed fallback:

- if EA cannot be safely resumed, Main creates a new Executor A2/recovery session from durable evidence and records that logical-worker continuity was lost;
- if TB cannot be safely resumed, Main creates a new independent Tester B2 from durable review authority/evidence and records replacement reviewer recovery;
- a failed resume must never silently create a new physical/logical session while continuing to label it A1/B1;
- a material scope/authority/acceptance/security/migration change may require B2 even when B1 is technically resumable.

Project Workflow must own only the semantic review state: exact subject/attempt, verdict, evidence, authority and required review status. Muse `session_id`, adapter `invocation_id`, leases and resume probes remain private `codex_workflow` runtime/orchestration details and must not become Project Workflow state.

## Required authority-change scope before implementation

This research is evidence, not authority. Production implementation must not begin until the accepted authority is updated through the normal workflow.

### Project Definition: `requirements/MUSE_MAX_RUNTIME.md`

The following accepted requirements currently encode one-shot/fresh behavior and must be revised:

1. **R5 — Shared role contracts remain canonical**
   - remove `one-shot execution` from the list of required Muse harness differences;
   - state that stateful session reuse is a harness/runtime lifecycle detail owned by `codex_workflow`, while semantic worker role contracts remain shared.

2. **R7 — Muse workers are leaf one-shot invocations**
   - replace the one-shot requirement with a leaf **logical-worker/session** requirement;
   - allow one logical Muse worker to execute multiple sequential bounded turns/processes in one durable Muse session;
   - retain the prohibitions on nested workers, sibling coordination and uncontrolled fan-out;
   - define one-active-turn-per-session/lease semantics.

3. **R8 — Separate executor and tester**
   - preserve strict Executor/Tester separation;
   - define distinct logical worker/session identity for Executor and Tester;
   - clarify that Tester reuse across review attempts does not collapse that separation.

4. **R9 — RED repair loop routes through Main**
   - replace `fresh executor -> fresh tester -> fresh repair -> fresh tester` with the preferred `A1 -> B1 -> A1 -> B1` lifecycle;
   - each implementation change must create a new exact review subject/attempt;
   - B1 recheck of S2 must be a full review against the current acceptance surface;
   - define Main's material-boundary rule for selecting fresh B2;
   - define explicit A2/B2 recovery fallback when a durable session cannot be safely resumed.

5. **R13 — Timeout and process-tree cancellation**
   - retain full process-tree cleanup;
   - add interrupted-turn session-state reconciliation: after timeout/cancel, session health/existence and workspace side effects must be assessed before resume;
   - a timeout/cancel must not implicitly authorize either reuse or replacement.

6. **R14 — Failure classification**
   - add session/resume/recovery failure classification sufficient for fail-closed behavior;
   - distinguish an unavailable/corrupt/non-resumable session from an ordinary model/task failure.

7. **R15 — Project Workflow owns lane parallelism**
   - retain lane/worktree ownership and sequential per-lane ordering;
   - replace `fresh tester` with preferred same independent B1 recheck for bounded repair;
   - add the invariant that one logical session cannot have two active turns concurrently.

8. **Acceptance-level outcomes**
   - replace the fresh-Tester/fresh-repair outcomes with proof of A1/B1 reuse across RED -> repair -> full recheck;
   - require proof that S1 and S2 are separate exact review attempts;
   - require proof that formal reviewer independence is preserved;
   - add the live interrupted-turn fault-injection acceptance gate described below.

9. **Non-goals**
   - remove `persistent conversational Muse worker sessions` as a non-goal because durable Muse session continuity becomes intentional;
   - keep a **long-lived Muse OS process / `muse serve` as prerequisite** out of scope unless later evidence requires it; the proven `muse exec --session-id` lifecycle is sufficient;
   - keep direct Executor <-> Tester messaging and Muse-native nested fan-out out of scope.

10. **New explicit runtime-boundary requirement**
    - state that Project Workflow must not own or persist Muse `session_id`, adapter `invocation_id`, session leases or resume-probe mechanics;
    - those identifiers and recovery mechanics belong exclusively to `codex_workflow`;
    - Project Workflow receives semantic outputs only: exact subject/attempt, verdict, evidence, blocker/recovery outcome and authority-relevant facts.

### Accepted decision: `docs/DECISIONS.md#D21`

D21 must be revised consistently:

- replace `fresh one-shot Muse invocation` semantics with stable logical worker sessions plus unique per-turn invocations;
- replace ordinary RED routing to fresh repair/fresh Tester with preferred `A1 -> B1 -> A1 -> B1`;
- keep Main as the only orchestration bridge and keep Tester production-repair prohibition;
- state that a changed implementation subject creates a new exact review attempt even when B1 is reused;
- allow/require fresh B2 when the review surface materially changes;
- require fail-closed A2/B2 replacement when session continuity cannot be safely recovered;
- keep session/invocation identifiers outside Project Workflow state;
- preserve lane/worktree ownership, profile allocations and all non-`muse-max` behavior.

### Future Project Workflow `codex_only` authority

A dedicated `codex_only` policy does not yet exist as an accepted route in current Project Workflow `main`. Before B1 can count as the formal Project Workflow reviewer, that future policy must explicitly define:

- the formal implementation-review role may be executed by an independent `codex_workflow` Tester worker;
- independence means the reviewer did not implement/repair the reviewed exact subject and receives only authorized review context/evidence, not Executor trajectory;
- each changed subject S1 -> S2 creates a new immutable review attempt;
- the same independent B1 may perform the S2 attempt after an ordinary bounded repair when the accepted review surface is materially unchanged;
- the recheck must be a full review of S2, not merely confirmation of prior findings;
- material scope/authority/acceptance/security/migration changes may force a fresh B2;
- reviewer/session loss uses an explicit fresh-worker recovery path from durable evidence;
- Main persists the formal verdict/evidence into Project Workflow's canonical review state and then returns to the policy router;
- Project Workflow must remain transport-agnostic: no Muse `session_id`, `invocation_id`, process id, lease or CLI resume mechanism in policy/state contracts.

The existing `chatgpt_only` fresh-normal-ChatGPT review boundary remains unchanged unless that policy is separately redesigned. The future `codex_only` policy must not inherit `chatgpt_only` freshness semantics accidentally.

### codex_workflow implementation/docs after authority acceptance

No semantic change is required to `agents/tester.toml` or the normal Executor ownership contract unless later review finds a wording gap.

The implementation phase should update at least:

- `codex_workflow/heavy_route.md` Muse-specific one-shot/fresh-follow-up clauses;
- `codex_workflow/delegation.md` Muse follow-up, independent review and recovery clauses;
- README/ownership docs that describe Muse roles as one-shot/fresh;
- `runtime/muse_worker.py` to split stable session identity from unique invocation/artifact identity;
- adapter tests for session binding, locking, exact role/workspace/profile binding, structured output, retention and fail-closed recovery;
- any additional docs/tests discovered by repository-wide search for `fresh Muse`, `one-shot`, `fresh tester` or equivalent lifecycle wording.

`compute_profiles.py` and worker model allocations do not need to change for this lifecycle.

## Mandatory live fault-injection gate before stateful-default promotion

Stateful reuse must not become the default merely because the normal four-turn cycle is GREEN.

Before promotion, live Meta-backed Muse evidence must exercise at least:

1. create a real A1 or B1 session and complete an initial turn;
2. start a later turn in that same session;
3. interrupt/kill/cancel that turn through the actual adapter process-control path while it is active;
4. verify no Muse descendant process tree survives;
5. inspect resulting workspace state for partial side effects;
6. probe the exact session through the production resume/existence mechanism;
7. exercise the safe branch:
   - if resumable, resume the same logical worker and prove continuity + correct structured result;
   - if not resumable, fail closed and create the explicit A2/B2 recovery worker from durable evidence;
8. prove the runtime never silently reuses the old logical label for a newly minted session;
9. prove a Tester fallback remains independent and performs a full review of the current exact subject;
10. prove raw session/trajectory data and runtime identifiers do not leak into Project Workflow durable state.

This fault-injection gate is REQUIRED before changing stateful A1/B1 reuse from experimental/opt-in behavior to the default `muse-max` lifecycle.

## Conclusion

**Technical result: GREEN for normal stateful continuation.**

The installed Muse Code runtime genuinely preserves context across separate headless `muse exec` processes when the same session UUID is reused. The full requested A1 -> B1 -> A1 -> B1 cycle worked live, including RED -> repair -> GREEN and independent Executor/Tester sessions.

The current production adapter cannot expose this lifecycle because it conflates Muse `session_id` with one-shot adapter `run_id`.

The fresh follow-up model is therefore not technically required by Muse. Moving to stateful A1/B1 reuse is feasible and is compatible with the existing semantic Tester/Executor role contracts, but production promotion must wait for:

1. accepted Project Definition + D21 lifecycle changes;
2. a future `codex_only` review contract that explicitly allows an independent Tester worker to satisfy formal Project Workflow review without an additional normal-ChatGPT review;
3. adapter split of stable session identity from per-turn invocation identity;
4. fail-closed session existence/health validation;
5. per-session locking and lane/workspace binding;
6. explicit A2/B2 fallback semantics;
7. the mandatory live interrupted-turn fault-injection/resume-or-fallback gate.

The current `chatgpt_only` review semantics remain unchanged by this research.

No production change was made by this research.

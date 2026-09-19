# Muse-max production runtime Master Plan

Status: **draft**
Revision: **R7**
Date: 2026-09-19
Review requirement: **RECOMMENDED**

R4 replanning trigger: after R3 received independent GREEN and was approved, Execution Prep verified the actual `codex_workflow` release path and found an exact-subject publication mismatch that R3 had not modeled. The current published release `v1.1.17-private.10` already targets `elmakus/codex_workflow@f2b1811853a2c1da5a5af4bb735c84c3111a44d6`; the independently reviewed and live two-lane-validated M09 source checkpoint `f6603767115cf7f31ef7d8c3cb3a419a7f430aca` still carries version `1.1.17-private.10`, and PR #6 intentionally excluded a release/version bump. The normal release workflow requires `main`, refuses an existing tag/release, and publishes the checkout commit as release provenance. R4 therefore preserves `f660376...` as the accepted M09 source checkpoint but requires a new metadata-only release-candidate commit on top of it with the next unique synchronized release version; that exact new commit must itself receive independent review GREEN and live two-lane Muse validation GREEN before publication/promotion. The Luna XHigh Companion sequencing introduced by R3 is unchanged: publication/promotion may proceed while Companion quota is unavailable, but M09/project completion remains blocked until the actual Companion creation/reuse proof is GREEN on the exact promoted release.

R5 replanning trigger: after R4 received independent GREEN and was approved, execution of M09-T04 proved that the repository's current release regression contract contains version-coupled expectations in `scripts/test_workflow_runtime.py`. A four-file `.10` -> `.11` metadata bump made the 90-test runtime suite fail only on those stale version literals; a disposable diagnostic that additionally synchronized exactly four release-version literals in that test file made the same suite 90/90 GREEN. GitHub readback of the prior `v1.1.17-private.10` release commit also shows the same test file being version-synchronized during release preparation. R5 therefore keeps the R4 exact-subject strategy unchanged but makes the release-candidate scope explicit: the direct child of `f660376...` may change the four release metadata files plus only the version-coupled assertions/fixture literal in `scripts/test_workflow_runtime.py`, with no test-semantic or runtime-semantic change. Evidence: `implementation/blockers/M09_T04_RELEASE_VERSION_TEST_SYNC_2026-09-18.md`. The blocked over-constrained M09-T04 contract must be superseded through Execution Prep after R5 approval; it must not be silently widened in place.


R6 replanning trigger: on 2026-09-19 the user accepted the revised Muse lifecycle proven by `research/MUSE_SESSION_RESUME_LIFECYCLE_2026-09-19.md` and Project Definition/D21 were amended accordingly. The new target is stateful logical Muse workers with stable session identity and per-turn invocation identity, preferred `A1 -> B1 -> A1 repair -> B1 full recheck`, fail-closed explicit A2/B2 replacement, and a strict boundary in which `codex_workflow` owns runtime/orchestration semantics but never Project Workflow Task Board/review-policy state. R6 preserves completed historical M05-M09 evidence rather than rewriting it. It adds a follow-on M10 source/runtime milestone on top of published `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`. M10 source implementation and isolated live validation may proceed while M09-T03 remains quota-blocked because Companion behavior and the production runtime are not changed by M10. R6 does not authorize a new release or production promotion; that requires later explicit planning/authorization after the stateful implementation is independently reviewed.

R7 planning trigger: M10 is now independently GREEN at `elmakus/codex_workflow@cf4c01f3ef7f35c32fb5ad61c301eb90e1466655`, M09 is fully closed, and on 2026-09-19 the user explicitly authorized continuing into a release candidate for production promotion. Project Definition added R18 and D22: the accepted M10 behavioral subject must be promoted through an exact release-candidate lineage, with other compute profiles unchanged. R7 preserves all completed M10 source/live/review evidence, adds one follow-on M11 release/promotion milestone, and does not reopen the accepted stateful runtime behavior unless release preparation discovers a real behavioral incompatibility.

## Authority

This plan organizes the accepted Muse-max Project Definition without changing it.

Canonical authority:
- `requirements/MUSE_MAX_RUNTIME.md`;
- `docs/DECISIONS.md#d21--muse-max-is-a-mixed-harness-stateful-worker-codex_workflow-profile`;
- `research/MUSE_MAX_RUNTIME_AUDIT_2026-09-18.md`;
- `research/MUSE_SESSION_RESUME_LIFECYCLE_2026-09-19.md`.

Relevant implementation baselines:
- current published `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8` / `v1.1.17-private.11`;
- `implementation/evidence/M09_T08_PRODUCTION_PROMOTION_2026-09-18.md`;
- workstation Muse Code 1.3.0 runtime used by the 2026-09-19 session-resume research.

The earlier `planning/MUSE_DELEGATED_WORKERS_MASTER_PLAN.md` is superseded and is not execution authority.

## Goal and target state

Deliver a production-capable `muse-max` profile in `elmakus/codex_workflow` where:

- Codex Main remains the orchestrator;
- one persistent internal Companion uses GPT-5.6 Luna XHigh;
- the other six existing workflow roles use Muse Spark 1.3 Contributor / max through native Muse Code;
- Muse execution is profile-aware, bounded, machine-readable, cancellable and context-isolated;
- logical Muse workers can safely retain session context across bounded turns while each physical turn keeps a unique invocation/artifact identity;
- Executor and Tester remain independent logical workers; ordinary RED prefers owning Executor repair plus the same independent Tester full recheck;
- session loss/binding failure fails closed to explicit A2/B2 replacement rather than silent identity substitution;
- caller-authorized independent lanes can use safe bounded concurrency in isolated workspaces without cross-lane session reuse;
- `codex_workflow` remains agnostic to Project Workflow Task Board/review-policy state;
- `plus`, `luna-xhigh`, and `pro-x5` are unchanged.

## Global invariants

- Only `muse-max` behavior may change unless live evidence proves a workstation runtime correction is required.
- Existing `agents/*.toml` remain the canonical role-semantic definitions; no parallel Muse role tree.
- `compute_profiles.py` remains the authority for role → model/reasoning/harness allocation.
- Muse workers are leaf logical sessions with sequential bounded turns; no nested Muse agents and no direct Muse sibling messaging.
- Stable Muse session identity and per-turn invocation identity are separate runtime concepts.
- Executor and Tester never share a logical/session identity; Tester never performs production repair.
- A changed verification target does not automatically require a fresh Tester; freshness is driven only by controlling contract, unsafe/unavailable resume, or a material Main decision.
- Main receives compact normalized results, not raw Muse trajectories.
- Raw event/stderr/session artifacts stay outside project Git and ordinary Main context.
- External callers own task dependencies, write ownership, lane/workspace authorization and any project-level state machine. `codex_workflow` treats task/lane identity as opaque runtime binding data and does not interpret Project Workflow policy/review state.
- This project's current `chatgpt_only` implementation route remains serial even though the target `codex_workflow` runtime supports caller-authorized parallel lanes.
- Exact Muse argv/event fields are not frozen before live evidence from the installed workstation build.
- Live Unraid build/recreate/login/runtime mutation requires an explicit authorization gate.


## Historical milestone preservation

M05-M09 below remain authoritative history for the one-shot implementation/release that produced `v1.1.17-private.11`. Their completed evidence, review subjects and Card contracts are not retroactively rewritten to stateful semantics. Where their text conflicts with the amended 2026-09-19 Definition for future work, M10 below owns the changed lifecycle. M09-T03 remains a separate unresolved Companion acceptance gate on the already promoted release.

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

The complete single-lane Muse-backed `muse-max` orchestration behavior works end to end with the existing `codex_workflow` roles and preserves independent verification. Companion allocation remains part of `muse-max`; only the live creation/reuse check may be deferred to M09 final promotion when the internal Codex lifecycle is unavailable for an external execution-surface/quota reason.

### Requirement ownership

Primary: R2, R4–R9.

Also verifies R10–R14 in real orchestration and verifies the R3/D21 Companion allocation contract. Final live Companion persistence verification is owned by M09.

### Dependencies

- M07 production adapter GREEN.

### Planned work packages

- Verify that active `muse-max` renders exactly one internal Companion as GPT-5.6 Luna XHigh.
- When an actual Codex Main worker lifecycle is available, verify live Companion creation/reuse. If that lifecycle is unavailable solely because of the current execution surface or account quota, persist the exact blocker and defer only this live check to the M09 pre-promotion gate.
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

- Six-role Muse routing matches D21.
- Active `muse-max` renders exactly one internal Companion as GPT-5.6 Luna XHigh.
- If live internal Codex lifecycle access is unavailable solely for an external execution-surface/quota reason, M08 may close with a durable explicit deferral of live Companion creation/reuse; this does not satisfy R3 live persistence and cannot satisfy the M09 pre-promotion gate.
- Executor → fresh Tester GREEN path works.
- RED → fresh repair Executor → fresh Tester path works.
- Tester does not inherit executor transcript.
- Main remains acceptance/orchestration authority.
- Investigator/Archivist behavior is viable under observed sandbox/network/write boundaries or any unsupported capability is explicitly surfaced without violating role ownership.
- No hidden conversation continuity is required between Muse invocations.

### JIT trigger

If M08 reveals a role-specific live limitation that does not change Definition, Execution Prep may create bounded corrective work. A limitation that changes the accepted six-role target returns to Project Definition. A pure inability to invoke the internal Codex Companion from the current execution surface does not redefine the target and may use the explicit M09 deferral above.

---

## Milestone M09 — Add bounded lane concurrency and promote the complete runtime

### Outcome

The reviewed `muse-max` implementation supports safe Project Workflow-authorized parallel lanes, is published through the normal `codex_workflow` release path, and is validated on the workstation as the production candidate. The live Luna XHigh Companion proof may follow release/promotion when quota is unavailable, but M09 does not close until that proof is GREEN on the exact promoted release.

### Requirement ownership

Primary: R1, R15, R16.

Final integrated verification for R1–R16.

### Dependencies

- M08 GREEN under the revised M08 acceptance above, including durable documentation of any permitted live-Companion deferral.
- Exact concurrency mechanism becomes knowable from the M07 adapter shape and M08 orchestration evidence.
- M09 source implementation/regression may proceed while the permitted live-Companion check is deferred. Publication/promotion additionally requires a release-candidate commit with the next unique synchronized release metadata on top of the accepted source checkpoint, followed by independent review and live two-lane Muse validation on that exact release-candidate commit. M09 final acceptance/project completion still may not occur until the Companion proof is GREEN.

### Planned work packages

- Choose the smallest managed concurrency mechanism consistent with the accepted Definition:
  - concurrently awaited independent adapter calls; or
  - a small `codex_workflow` batch/pool wrapper over the same single-run adapter.
- Keep worker process ownership explicit and cancellation scoped per invocation/lane.
- Do not add a second project scheduler or task database.
- Use two isolated non-overlapping worktrees/lanes whose Project Workflow authority marks them safe for parallel execution.
- Demonstrate concurrent Muse invocations without shared mutable index/worktree or raw-log collision.
- Preserve `elmakus/codex_workflow@f6603767115cf7f31ef7d8c3cb3a419a7f430aca` as the independently reviewed and live two-lane-validated source implementation checkpoint.
- Read back the current published version/tag state immediately before release preparation and choose the next unique private release version. Create one bounded release-candidate commit directly on top of the accepted source checkpoint that changes only synchronized release-version material required by the existing release contract: `codex_workflow/operate/VERSION`, its marker in `user_AGENTS.md`, README release version text, `RELEASING.md`, and only the version-coupled current/previous/next-version assertions plus update-fixture source literal in `scripts/test_workflow_runtime.py`. The test edits must be literal release-version synchronization only; they must not change test behavior, coverage, runtime semantics, Muse behavior, or any compute-profile allocation.
- Run complete `codex_workflow` regression coverage on that exact release-candidate commit, including unchanged `plus`, `luna-xhigh`, and `pro-x5`.
- Freeze that exact release-candidate commit for independent review. Correct any bounded finding normally; any corrective commit becomes a new exact subject and must be reviewed again.
- After independent review GREEN, run the live M09 two-lane Muse validation on that same exact release-candidate commit. The earlier `f660376...` live smoke remains valid predecessor evidence but does not transfer exact-subject identity across the release-metadata commit.
- Publish through the existing `codex_workflow` owner release/update channel only after the exact release candidate has both independent review GREEN and live two-lane Muse validation GREEN. Preserve commit identity by advancing `main` only when it can fast-forward to that exact candidate; the normal VERSION-triggered release workflow must publish a new unique tag whose release provenance targets that exact commit. If repository divergence would require a merge/squash/rebase commit, do not publish a different SHA; route through normal correction/review/revalidation instead.
- With explicit live authorization, update the workstation runtime to that exact published release and perform the production smoke that is available without consuming Luna XHigh quota:
  - active `muse-max` allocation/readback;
  - Muse executor + fresh Tester;
  - one safe two-lane parallel run where the available Project Workflow/runtime supports it.
- After release/promotion, or earlier if quota becomes available, close the deferred live-Companion obligation using an actual Codex Main session on the exact promoted release to demonstrate one GPT-5.6 Luna XHigh Companion creation and reuse within the same workflow session. A concrete quota/runtime rejection remains an open blocker, not a substitute pass.
- If the deferred Companion proof exposes a defect in the promoted release, M09 remains non-terminal and routes through the normal correction/review/release path before final acceptance.

### Stable acceptance/checkpoint

- Two independent authorized lanes execute concurrently in isolated workspaces without mutation/log/state collisions.
- A lane failure/cancel does not corrupt or silently cancel an unrelated healthy lane.
- Complete profile regressions are GREEN.
- The exact release-candidate commit, including its release metadata, receives independent review GREEN.
- Live two-lane Muse validation is GREEN on that same exact release-candidate commit.
- Published `codex_workflow` release is exactly that reviewed and live-validated release-candidate commit.
- Live workstation update/readback confirms the exact published release and the available target `muse-max` behavior.
- One actual Codex Main workflow session on the exact promoted release creates and later reuses the same GPT-5.6 Luna XHigh Companion before M09 is marked done.
- No workstation-side second scheduler, generic Project Workflow delegated-worker runtime or duplicate Muse role contracts were introduced.

### Gates

- The deferred live Companion check is a hard **final M09 acceptance/project-completion** gate. Under the user-authorized R3 sequencing it is no longer a pre-publication/pre-promotion gate.
- The gate still requires the accepted GPT-5.6 Luna XHigh Companion; Marina, Sol Medium or another substitute worker/model cannot satisfy it.
- Publication/promotion may proceed only for the exact release-candidate commit, including its unique synchronized release metadata, after independent review GREEN and live two-lane Muse validation GREEN on that same commit. The earlier source-only `f660376...` review/live evidence remains predecessor evidence but cannot by itself satisfy release-subject identity after the required version-metadata cut. Publication/promotion still do not count as R3/R5 acceptance.
- Live workstation update/recreate/runtime validation requires explicit live-operation authorization.
- M09 must remain non-terminal until the actual Companion creation/reuse proof is GREEN on the exact promoted release.

---


---

## Milestone M10 — Add stateful Muse logical-worker lifecycle and fail-closed recovery

### Outcome

An exact `codex_workflow` source subject implements the amended stateful `muse-max` lifecycle without importing Project Workflow state semantics: stable session identity per logical worker, unique invocation identity per physical turn, safe A1/B1 reuse, explicit A2/B2 fallback, process-safe session locking/binding, preserved structured results/artifacts, and caller-isolated parallel lanes. The exact subject is fixture-tested, live-tested on Meta-backed Muse Code 1.3.0, and independently reviewed.

M10 does **not** publish a new release or modify the installed production `~/.codex/codex_workflow` runtime.

### Requirement ownership

Primary: amended R5, R7-R15, R17.

Regression/compatibility: R1, R2, R4, R6, R10-R12.

R3 Companion allocation/lifecycle and R16 workstation installation boundary are unchanged.

### Dependencies

- Approved amended `requirements/MUSE_MAX_RUNTIME.md` and D21.
- `research/MUSE_SESSION_RESUME_LIFECYCLE_2026-09-19.md`.
- Current `elmakus/codex_workflow@4081cde7d4f71bcc2083c62cf69b7e3b845eefb8` as source baseline.
- Existing M09-T08 production evidence as regression baseline only.
- M09-T03 Luna Companion quota blocker is **not** a dependency for M10 source implementation or isolated live Muse tests because M10 does not change Companion semantics or production deployment.
- The user's 2026-09-19 instruction explicitly authorizes the requested isolated real-Muse lifecycle/fault-injection validation. It does not authorize production release/promotion.

### Planned work packages

- Refresh `codex_workflow` main and create one dedicated implementation branch from exact current main; do not modify the Project Workflow repository.
- Update only `codex_workflow` runtime/orchestration contracts and implementation:
  - preserve existing semantic worker TOMLs unless a concrete semantic contradiction is found;
  - remove Muse-specific one-shot/fresh-follow-up wording from `heavy_route.md`, `delegation.md`, README/ownership docs;
  - keep Project Workflow Task Board/review-policy concepts out of `codex_workflow`.
- Refactor the Muse adapter/runtime so:
  - one logical worker has a stable `session_id`;
  - every physical turn gets a unique `invocation_id` and private artifact directory;
  - a private runtime session registry binds logical worker identity to role, profile/allocation, canonical workspace and opaque caller task/lane scope;
  - one session has at most one active turn through a process-safe lease/lock;
  - cross-role, cross-workspace and cross-lane reuse is rejected.
- Add create/resume primitives with fail-closed behavior:
  - verify the exact prior Muse session exists/is usable before claiming resume;
  - reject unavailable, binding-invalid, busy or resume-rejected sessions with normalized recovery failure;
  - never auto-create a replacement while retaining the old logical identity;
  - Main may then explicitly allocate A2/B2 and recover from durable workspace/evidence.
- Preserve the current per-invocation structured-output contract, terminal-event validation, private raw event/stderr artifacts, retention limits, changed-path evidence and process-tree timeout/cancellation behavior.
- Add deterministic regression coverage for:
  - stable-session/new-invocation identity;
  - successful same-worker resume;
  - Executor/Tester session separation and Tester no-repair contract;
  - session binding mismatch;
  - one-active-turn lease conflict;
  - unavailable/non-retained session;
  - explicit replacement identity;
  - no cross-lane reuse;
  - concurrency against non-overlapping workspaces;
  - normalized structured output and artifact retention;
  - timeout/cancel child cleanup;
  - unchanged `plus`, `luna-xhigh`, and `pro-x5` behavior.
- On one exact committed source subject, run the real Meta-backed lifecycle:
  `A1 implement S1 -> B1 full review S1 RED -> A1 resume repair S2 -> B1 resume full recheck S2 GREEN`.
- On that same source subject, run the mandatory live interrupted-turn fault injection through the actual adapter process-control path:
  - establish a real logical Muse session;
  - start a later active turn;
  - interrupt/cancel it through adapter cancellation/timeout mechanics;
  - prove the process tree is gone;
  - inspect partial workspace effects;
  - probe exact session resumability;
  - prove either safe same-session continuation or a normalized fail-closed condition followed by explicit new-worker recovery;
  - prove no silent logical identity substitution.
- Re-run a two-lane live regression with separate Executor/Tester session namespaces per lane and prove no cross-lane session/artifact collision.
- Preserve raw Muse session/trajectory material outside Git/evidence; commit only bounded secret-safe evidence.
- Run complete `codex_workflow` regression coverage and `git diff --check`.
- Freeze the exact implementation source subject plus bounded live evidence for **REQUIRED independent implementation review**. Any corrective source commit becomes a new exact review subject and must receive a new review attempt.

### Stable acceptance/checkpoint

M10 is GREEN only when all are true:

- stable logical session identity is demonstrably separate from unique per-turn invocation identity;
- A1 and B1 are distinct sessions, and each is successfully reused in the full RED/repair/full-recheck cycle;
- Tester never performs production repair and receives no Executor trajectory inheritance;
- fail-closed resume refuses missing/unsafe/binding-invalid sessions without silently replacing identity;
- explicit A2/B2 recovery is reproducible from durable workspace/evidence;
- one-active-turn-per-session locking is proven;
- interrupted-turn live Meta evidence proves complete process-tree cleanup and either safe resume or safe explicit fallback;
- structured results, raw artifact isolation, timeout/cancel behavior and retention remain intact;
- two isolated caller-authorized lanes have disjoint logical sessions and no cross-lane reuse;
- full profile/runtime regressions are GREEN;
- exact source subject receives REQUIRED independent review GREEN;
- no Project Workflow Task Board/review-policy implementation or dependency appears in `codex_workflow`;
- production `v1.1.17-private.11` runtime remains unchanged by M10.

### Gates

- Live Meta-backed interrupted-turn fault injection is mandatory; fixture evidence alone cannot satisfy stateful-default acceptance.
- Independent implementation review is REQUIRED by the user's accepted scope.
- A live failure that exposes a Definition contradiction routes back to Project Definition; a bounded implementation defect remains M10 corrective work.
- Publication/release and production promotion of the stateful runtime are outside R6/M10 scope and require a later explicit plan/authorization.
- M09-T03 remains separately blocked/closable according to its existing exact promoted-release Companion contract.

### JIT trigger

After R6 plan review GREEN and approval, Execution Prep may create only the currently knowable M10 Cards. It must bind the exact current `codex_workflow` main SHA and create a dedicated implementation branch before source mutation. Card decomposition may separate source implementation from live validation only if the serial Task Board and final exact-subject review remain coherent; the final review must cover the exact source subject used for the required live evidence.

## Milestone M11 — Cut, validate, publish and promote the stateful Muse release

### Outcome

The independently accepted M10 stateful Muse runtime is carried into one exact next-version release candidate, verified without behavioral drift, published through the normal `codex_workflow` owner release path with commit identity preserved, installed on the workstation, and production-smoke validated as the active `muse-max` runtime.

### Requirement ownership

Primary: R18 and R16.

Release-stage regression/compatibility: R1, R3-R7, R10-R15, R17.

### Dependencies

- M10 GREEN at exact source subject `elmakus/codex_workflow@cf4c01f3ef7f35c32fb5ad61c301eb90e1466655` with REQUIRED independent review GREEN and bounded live evidence.
- M09 production baseline `v1.1.17-private.11` / `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8` remains the rollback baseline until M11 production acceptance is GREEN.
- Approved R18 and D22 exact release-candidate lineage.
- User authorization to proceed with release-candidate preparation is explicit on 2026-09-19. Publication and production mutation remain separate live-write gates and must use the authorization state recorded by execution; do not infer them from source preparation alone.

### Planned work packages

- Refresh current `codex_workflow` `main`, tags/releases and the M10 implementation branch immediately before release preparation. Direct release preparation is allowed only while M10 remains a clean descendant of the current production/main release lineage with no incompatible target drift.
- Choose the next unique private release version from fresh tag/release state; do not pre-bake a version number in this plan.
- Create a dedicated release-candidate branch directly from exact accepted M10 subject `cf4c01f...`.
- Make only synchronized release/version changes required by the existing release contract, including strictly version-coupled test/document literals when current repository tests require them. Do not change runtime behavior, worker allocation, lifecycle semantics or role contracts in the release-only commit.
- Run complete `codex_workflow` regression coverage on the exact candidate, including Muse adapter/session tests, workflow runtime tests, `muse-max` profile tests, unchanged `plus` / `luna-xhigh` / `pro-x5` allocation checks, compile/diff/package build and archive verification.
- Freeze the exact release candidate for **REQUIRED independent release-candidate review**. The review must verify that the candidate is the accepted M10 behavior plus release synchronization only, that no non-`muse-max` allocation/lifecycle drift exists, and that release provenance can preserve exact commit identity.
- After exact-candidate review GREEN, run bounded live Muse validation on that same candidate. Reuse M10's exhaustive stateful/fault-injection evidence for unchanged behavioral blobs, but re-prove on the exact release candidate at least:
  - stable logical Muse session reuse across two bounded turns with distinct invocation identities;
  - distinct Executor/Tester session identities;
  - one safe non-overlapping two-lane invocation batch or equivalent accepted lane-isolation smoke;
  - clean process/artifact termination and no production mutation.
- Publish only if the exact candidate remains a fast-forwardable descendant of current `main` and target refresh finds no behavioral conflict. Advance `main` to that exact candidate without merge/squash/rebase identity change and let the normal VERSION-triggered release workflow publish the exact next tag/assets. Verify tag/release provenance, checksums and release workflow success.
- With explicit production live-write authorization, update the workstation persistent `~/.codex/codex_workflow` runtime from that exact published release through the existing owner update path.
- Perform production readback and bounded stateful smoke:
  - installed version/package provenance equals the published candidate;
  - active profile remains `muse-max`;
  - Companion remains internal GPT-5.6 Luna XHigh;
  - six Muse roles retain Muse Spark 1.3 Contributor / max;
  - one Muse logical worker successfully reuses its retained session across a later bounded turn with new invocation identity;
  - installed profile authority still reports unchanged `plus`, `luna-xhigh`, and `pro-x5` Codex-backed allocations without switching the user's active profile;
  - no residual candidate/validation process tree remains.
- If any source/runtime behavior must change after `cf4c01f...`, stop the release-only path. That correction becomes a new implementation subject and must receive the applicable full regression/live/review cycle before publication.

### Stable acceptance/checkpoint

M11 is GREEN only when:

- the release candidate is a direct release-only descendant of accepted M10 behavior;
- complete exact-candidate regressions are GREEN;
- REQUIRED independent review is GREEN on the exact release candidate;
- bounded live stateful validation is GREEN on that exact candidate;
- published `main`/tag/release provenance resolves to that same exact commit and package checksums verify;
- workstation production installs that exact published release;
- production stateful session reuse is demonstrated through the installed runtime;
- active `muse-max` allocation is correct and the three Codex-backed profiles remain unchanged;
- rollback baseline remains available until all production checks are GREEN;
- no Project Workflow state semantics are introduced into `codex_workflow`.

### Gates

- Release-candidate preparation is authorized by the user's 2026-09-19 instruction.
- Publishing/advancing `codex_workflow` `main` and mutating the workstation production runtime are material external/live writes and require their explicit execution-time authorization gate unless durable project authority already records it for this exact M11 action.
- REQUIRED independent review must be GREEN before exact-candidate live validation proceeds to publication.
- Any target drift that prevents exact fast-forward lineage, or any required behavioral correction, invalidates direct publication and routes through normal correction/review/revalidation.

### JIT trigger

After R7 independent plan review GREEN and approval, Execution Prep may materialize serial M11 Cards for: release-state refresh + candidate cut; exact-candidate verification/review boundary; exact-candidate live validation; publication; production promotion/smoke. It must bind fresh `main`/tag/release state before selecting the version and must not combine publication or production mutation into an earlier Card merely for convenience.

## Requirement coverage

| Requirement | Owning milestone(s) |
| --- | --- |
| R1 only muse-max changes | M06, M09, M10, M11 release regression |
| R2 Codex Main orchestrator / runtime boundary | M06, M08, M10 |
| R3 persistent Luna XHigh Companion | M06, M09 |
| R4 six Muse roles | M06, M08, M10 regression |
| R5 shared role contracts + runtime-only overlay | M06, M10 |
| R6 profile-aware adapter | M06, M07, M10 |
| R7 stateful leaf logical Muse workers | M10 |
| R8 separate Executor/Tester sessions | M08 historical, M10 amended target |
| R9 RED repair through Main with A1/B1 reuse/fallback | M08 historical, M10 amended target |
| R10 compact normalized result | M07, M08, M10 |
| R11 raw log/session isolation | M07, M08, M10 |
| R12 machine-readable Muse lifecycle/resume | M05, M07, M10 |
| R13 timeout/cancel + interrupted-turn reconciliation | M07, M10 |
| R14 failure/recovery classification | M07, M10 |
| R15 caller-owned lane authority + runtime isolation | M09 historical, M10 amended target |
| R16 workstation boundary | M05, M09, M11 |
| R17 policy/state-machine agnostic runtime | M10, M11 regression |
| R18 exact release/promotion of accepted M10 | M11 |

Changed R7-R9/R13-R15 semantics are owned by M10; older milestone evidence remains historical and is not rewritten.

## System verification strategy

Historical M05-M09 verification remains valid for the published one-shot baseline. R6 adds the following stateful path without upgrading historical evidence:

```text
current codex_workflow main 4081cde...
  -> source branch + deterministic session/binding/locking/fallback tests
  -> exact committed stateful implementation subject
  -> live Meta A1 -> B1 RED -> A1 repair -> B1 full recheck GREEN
  -> live interrupted-turn fault injection on actual adapter path
  -> live two-lane session-isolation regression
  -> complete codex_workflow/profile regressions
  -> bounded secret-safe evidence on the exact source subject
  -> REQUIRED independent implementation review
  -> M10 acceptance
```

No passing claim may be upgraded from fixture evidence to live resume/recovery behavior without the corresponding real Muse checkpoint.

R7 adds the production release path:

```text
accepted M10 source cf4c01f...
  -> fresh release-state/version readback
  -> release-only exact candidate
  -> complete exact-candidate regressions/package verification
  -> REQUIRED independent release-candidate review
  -> bounded live stateful smoke on the exact candidate
  -> exact fast-forward main/tag/release publication
  -> production owner-update install
  -> production provenance/profile/stateful-reuse readback
  -> M11 acceptance
```

The exhaustive M10 interrupted-turn/fail-closed evidence remains valid only while release-candidate behavioral blobs are unchanged; a behavioral correction reopens the full applicable live/review cycle.

## Security, data integrity and idempotency

- Do not commit Muse credentials, raw session state, exported trajectories or user-home auth artifacts.
- Normalized results must not intentionally contain secrets.
- Raw run/session artifacts remain in persistent private runtime storage, not project Git or external workflow state.
- Session registry/binding/lease files must be private and bounded; per-turn artifacts retain bounded age/count/size cleanup.
- Session existence probing must not leak raw transcript/reasoning into Main or committed evidence.
- Every invocation has a unique artifact identity even when reusing one stable Muse session.
- Resume requires exact role/profile/workspace/opaque-scope binding and a single active lease.
- Failures/cancellation do not advance any external workflow state by themselves.
- Recovery never silently re-labels a newly created session as an old logical worker.
- `codex_workflow` must not read or mutate Project Workflow Task Board/review-policy state.
- Profile switching/updates must preserve other profiles and existing user/project state according to current lifecycle contracts.

## Rollback / recovery

M10 is source/test-only:

- production remains on `v1.1.17-private.11`;
- the stateful source branch can be discarded without changing installed production runtime;
- disposable candidate runtimes/workspaces/session registries used for live testing must be isolated from production and removable after evidence capture;
- an interrupted invocation first performs process cleanup and session/workspace reconciliation;
- if the prior logical session is safely resumable, reuse it;
- otherwise return a fail-closed recovery result and let Main explicitly create A2/B2 from durable workspace/evidence;
- cross-lane recovery must never adopt another lane's session;
- later publication/promotion, if authorized, must define its own release/rollback contract.

For M11 production rollback, retain the known-good `v1.1.17-private.11` release identity and verified package provenance until the new production smoke is GREEN. If installation or smoke fails, do not mark M11 complete; use the existing owner release/install mechanism to restore the prior verified release or an equivalently verified transactional backup, then read back version/profile/runtime state before further attempts.

## JIT decomposition policy

Historical M05-M09 JIT rules remain historical authority for their existing Cards/evidence.

For M10:

- Execution Prep binds current `codex_workflow` main and creates a dedicated implementation branch before source mutation.
- Do not modify `elmakus/chatgpt-codex-project-workflow`.
- Create only enough serial Cards to implement/test the stateful runtime coherently; avoid placeholder Cards.
- The exact session-registry format, process-safe lock primitive and native session-health probe are L1/L2 implementation choices provided they satisfy the amended Definition and installed Muse 1.3.0 evidence.
- If JIT discovers that `muse exec --session-id` cannot provide the required safe lifecycle without `muse serve`/MSP or another strategic architecture change, route back to Project Definition instead of widening implementation.
- The mandatory live Meta fault-injection must run on an exact committed source subject through the candidate adapter, not by manually bypassing it.
- The final exact source subject used for live evidence requires REQUIRED independent implementation review.
- No release/version bump, `main` publication or production runtime update is authorized by M10.
- No OpenSpec is required at plan time because the accepted change is internal `codex_workflow` orchestration/runtime behavior with unchanged external CLI/profile allocation contracts; if JIT introduces a new public API/schema/cross-package contract, Execution Prep must materialize the appropriate contract before implementation.

For M11:

- Bind fresh `codex_workflow` main/tag/release state before choosing the candidate version.
- Release synchronization must remain behavior-neutral relative to accepted M10; unexpected behavioral edits route out of the release-only path.
- Keep publication and production-promotion Cards distinct because each has its own external-write/readback gate.
- Exact-candidate review is REQUIRED; the chat that cuts or behaviorally changes the candidate cannot independently review it.
- No new OpenSpec is expected for release-only metadata/promotion; if execution discovers a new public behavior/schema contract, route to the appropriate authority before proceeding.

## Planning audit

GREEN for planner self-audit; independent plan review is RECOMMENDED and pending for R7.

- Amended Definition/D21 are approved and contain no unresolved product/architecture choice.
- R6 cleanly separates `codex_workflow` runtime/orchestration semantics from Project Workflow policy/state semantics.
- Historical M05-M09 evidence is preserved instead of being rewritten under the new contract.
- M10 is isolated source/test work and does not disturb the quota-blocked M09-T03 Companion gate or production `v1.1.17-private.11`.
- Stable `session_id` versus per-turn `invocation_id`, binding, one-active-turn locking and fail-closed A2/B2 recovery all have explicit acceptance paths.
- B2 freshness is not tied automatically to subject size/materiality.
- The required live Meta-backed interrupted-turn fault-injection is an explicit hard acceptance gate.
- Parallel-lane regression requires lane-local Executor/Tester sessions and forbids cross-lane reuse.
- Existing structured output, artifact isolation, timeout/cancel and other-profile regressions are preserved as mandatory checks.
- Production release/promotion is explicitly outside scope, keeping rollback simple.
- The final implementation subject has REQUIRED independent implementation review.
- R6 materially changed execution strategy and lifecycle acceptance and remains historical approved authority for M10.
- R7 adds only the authorized release/promotion strategy for accepted M10 behavior, with exact-subject lineage, rollback baseline, other-profile preservation and external-write gates explicit.
- M11 does not reopen M10 runtime architecture: release-only changes are constrained to synchronized metadata/version literals; behavioral drift forces a new implementation subject.
- Exact-candidate regression, REQUIRED release-candidate review, bounded live validation, publication provenance and production stateful smoke form a complete end-to-end acceptance chain.
- Publication and production mutation remain separated from source preparation so authorization/readback boundaries cannot be bypassed.
- R7 is a material new milestone and execution strategy, so independent plan review classification remains RECOMMENDED; the authoring chat cannot issue that verdict.

# Muse-max runtime audit — 2026-09-18

Status: research / brainstorming evidence only. Not accepted architecture or implementation authority.

## Scope

Audit `elmakus/codex_workflow@f2b1811853a2c1da5a5af4bb735c84c3111a44d6` for the intended runtime shape:

- Codex remains Main/orchestrator.
- Only the `muse-max` compute profile is in scope.
- `plus`, `luna-xhigh`, and `pro-x5` must preserve behavior.
- User-selected exception: under `muse-max`, Companion should run as persistent internal Codex GPT-5.6 Luna XHigh.
- Other existing codex_workflow roles remain candidates for Muse Spark 1.3 Contributor / max through Muse Code.
- Tester is always a distinct worker invocation from the executor.
- Independent Project Workflow Task Cards may execute concurrently only when Project Workflow declares them safe and gives them isolated mutable workspaces/worktrees.

## Sources inspected

Repository:
- `codex_workflow/runtime/muse_worker.py`
- `codex_workflow/runtime/compute_profiles.py`
- `codex_workflow/AGENTS.md`
- `codex_workflow/heavy_route.md`
- `codex_workflow/delegation.md`
- all seven `codex_workflow/agents/*.toml` role contracts
- `scripts/test_muse_profile.py`
- relevant profile/runtime regression tests
- public README/runtime documentation

External:
- current Meta Muse Code changelog
- current examples/adapters that drive `muse exec --json` as JSONL and treat `run.terminal.*` as the terminal boundary.

Exact Muse CLI argv/event fields remain implementation-time evidence and must be captured from the installed workstation build before parser/flag behavior is frozen.

## Executive finding

The existing architecture has the correct seam but the current `muse_worker.py` is a proof-of-concept, not a production orchestration adapter.

Do not build a second Muse orchestrator in `chatgpt-ce-workstation` or generic delegated-worker runtime in Project Workflow.

The runtime owner should remain `elmakus/codex_workflow`. Project Workflow owns Task Card/lane/worktree/parallel-safety decisions; codex_workflow owns role routing and Muse process lifecycle; workstation owns installing/persisting the Muse CLI and auth environment.

## Finding A — profile separation is structurally good

`WorkerModel` already has per-role:
- model;
- reasoning effort;
- harness.

`render_worker_for_profile()` already treats external-harness roles differently from internal Codex roles.

Therefore `muse-max` can safely become a mixed-harness profile without modifying the other three profiles:

- companion -> `gpt-5.6-luna`, `xhigh`, harness `codex`;
- micro_executor -> Muse Contributor/max, `muse-code`;
- default_executor -> Muse Contributor/max, `muse-code`;
- senior_executor -> Muse Contributor/max, `muse-code`;
- tester -> Muse Contributor/max, `muse-code`;
- investigator -> Muse Contributor/max, `muse-code`;
- archivist -> Muse Contributor/max, `muse-code`.

This uses an existing abstraction rather than adding a parallel profile mechanism.

## Finding B — Companion should remain the shared role contract but return to internal Codex

Do not create `muse_companion.toml` or duplicate any other role definition.

The existing `companion.toml` is explicitly persistent and context-retaining. That fits the internal Codex worker lifecycle substantially better than a one-shot Muse process.

For `muse-max`:
- render installed Companion to Luna XHigh;
- spawn/reuse one internal persistent Companion using the normal Codex lifecycle;
- do not route Companion through `muse_worker.py`.

Required documentation changes include removing/replacing current statements that every `muse-max` role is Muse and that the Muse Companion is one-shot.

## Finding C — other role definitions are reusable

No duplicate Muse-specific TOML set is recommended.

The role contracts describe semantic ownership and report expectations. Harness-specific behavior should be supplied as a Muse runtime overlay.

Role suitability:
- `micro_executor`: suitable for one-shot Muse.
- `default_executor`: suitable.
- `senior_executor`: suitable; its file description should eventually be provider-neutral because it currently says “Senior Sol executor”, though developer instructions are already provider-neutral.
- `tester`: suitable and should always be a fresh invocation distinct from executor.
- `investigator`: suitable if live validation confirms required project/web evidence tools under the chosen Muse sandbox/network posture.
- `archivist`: suitable for bounded assigned documentation writes.
- `companion`: use internal Luna XHigh instead.

The existing role text mentioning intermediate updates does not justify separate Muse role definitions. A Muse runtime overlay should state that no intermediate worker-to-Main message channel exists and exactly one final structured result is required.

## Finding D — current muse_worker.py has material production gaps

### D1 Profile/harness isolation is not enforced

The runner can currently be called regardless of active compute profile.

It must resolve the active profile and requested role through `compute_profiles.py`, then refuse execution unless that role's active `WorkerModel.harness == "muse-code"`.

This is required to prevent cross-profile leakage and will automatically reject `companion` under the proposed mixed `muse-max`.

### D2 Model/effort are duplicated as constants

`MODEL` and `REASONING_EFFORT` are hard-coded in the runner.

The runner should consume the active role's `WorkerModel`. The profile table should remain the single source of truth.

### D3 CODEX_HOME is ignored

The runner reads `Path.home() / ".codex" / "agents"` directly while the rest of codex_workflow supports `CODEX_HOME`.

The adapter should resolve RuntimePaths through the same CODEX_HOME semantics as the workflow runtime.

### D4 Raw worker output currently leaks to parent context

`subprocess.run()` inherits stdout/stderr. This defeats the desired context-isolation boundary.

The adapter should consume stdout/stderr itself, persist raw output, and emit only one compact normalized result to Codex Main.

### D5 No machine-readable Muse stream

Current invocation omits `--json`.

Current Muse supports headless JSONL output. The adapter should use the installed build's verified machine-readable mode and parse terminal run records rather than pattern-match human prose.

### D6 No normalized result contract

Exit code alone is insufficient.

The adapter needs a versioned normalized envelope with:
- task/run identity;
- role/profile/harness;
- terminal status;
- concise summary;
- blocking findings/decision requirement;
- role-specific verification/result fields;
- bounded repository evidence such as changed paths/diff-stat when applicable;
- raw artifact references.

Tester additionally needs a bounded `GREEN | RED | INCONCLUSIVE` verdict.

### D7 No timeout or process-tree cancellation

The runner has no outer timeout and cannot reliably stop a hung Muse process subtree.

Use a process-group/session boundary, bounded timeout, graceful termination window, then hard kill of the full process group.

### D8 No run artifact store

Raw JSONL/stderr/final normalized result should stay outside the project repository and outside Main context.

Recommended ownership: a persistent user-runtime data path under `~/.codex`, separate from project Git and preferably separate from versioned installed package files. Each invocation gets a run id / attempt directory.

Retention should be bounded by age/count/size so raw trajectories do not grow without limit.

### D9 No protocol failure classification

Distinguish at least:
- success;
- Muse/model failure;
- auth required;
- timeout;
- cancellation;
- malformed/missing terminal event;
- malformed normalized worker report;
- harness/runtime failure.

A process exit of zero is not sufficient.

### D10 No bounded step cap

The live CLI should be inspected for the supported model-step/tool-output caps. If supported by the installed version, the Muse adapter should set sensible role/task defaults or accept a bounded override from codex_workflow.

Do not freeze guessed flags before live `muse exec --help` capture.

## Finding E — result normalization should be two-layered

Layer 1, vendor stream:
- keep full Muse JSONL/stderr as raw artifacts;
- derive terminal outcome from Muse lifecycle records;
- never forward event stream to Main.

Layer 2, codex_workflow report:
- append a Muse-only runtime instruction requiring the final assistant reply to contain one strict compact worker-result object;
- parse/validate that object;
- combine it with harness-derived facts (exit/terminal state, duration, artifact refs, optionally repository diff metadata).

Do not force the shared role TOMLs to become Muse-specific JSON protocol files.

Suggested Main-facing shape:

```json
{
  "schema_version": 1,
  "task_id": "MXX-TYY",
  "role": "default_executor",
  "status": "success",
  "summary": "Implemented ...",
  "changed_files": ["..."],
  "diff_stat": {"files": 2, "insertions": 20, "deletions": 4},
  "verification": [{"check": "...", "result": "passed"}],
  "blocking_findings": [],
  "limitations": [],
  "artifacts": {"raw_log": "...", "stderr": "..."}
}
```

Tester uses the same envelope plus `verdict` and focused findings.

Main should not receive reasoning, searches, tool calls, raw test stdout, or large diffs on the normal path.

## Finding F — executor/tester/repair topology is already conceptually correct

For Muse:
1. fresh executor invocation;
2. Main receives compact normalized result;
3. fresh tester invocation receives accepted authority + actual resulting workspace state, not executor transcript;
4. ordinary RED within existing scope returns focused findings to Main;
5. Main launches a fresh executor repair invocation with the same logical Task ID plus findings/durable state;
6. Main launches a fresh tester recheck.

No direct executor↔tester messaging is needed.

A Main decision is required only when findings cross scope/contract/ownership/architecture/security/migration/authority boundaries.

## Finding G — parallelism should be lane-level, managed by Codex/codex_workflow

The current `muse-max` documentation deliberately says sequential. That was appropriate for the proof-of-concept but does not satisfy Project Workflow bounded-parallel execution.

Target semantics:
- dependencies/overlapping ownership remain sequential;
- Project Workflow decides whether multiple Task Cards are `parallel_safe`;
- Codex Main prepares/owns isolated lane branches/worktrees;
- each Muse invocation receives an already assigned workspace;
- Muse does not create/switch/own Project Workflow worktrees;
- independent lanes may execute concurrently through a managed codex_workflow mechanism;
- within one lane, executor -> tester -> repair -> tester remains ordered.

Do not use Muse's own `--worktree` as the project-lane owner; Project Workflow/Codex Main already owns that boundary.

Do not emulate concurrency with unmanaged shell background jobs.

Implementation choice still open:
- multiple concurrently awaited single-worker adapter calls if the Codex runtime supports that cleanly; or
- a small codex_workflow-managed batch/pool wrapper over the same single-run adapter.

The single-run adapter should be designed concurrency-safe either way.

## Finding H — documents/tests that must change if this target is accepted

At minimum:
- `runtime/compute_profiles.py`
- `runtime/muse_worker.py` (likely substantial rewrite)
- `AGENTS.md`
- `heavy_route.md`
- `delegation.md`
- `README.md`
- `scripts/test_muse_profile.py`
- targeted general profile tests that currently assume all muse-max roles are external Muse.

Other profiles should receive regression coverage proving their worker model/harness allocations and lifecycle language are unchanged.

## Live evidence still required

Before freezing exact implementation details, run on the workstation:
- `muse --version`
- `muse exec --help`
- one read-only JSON run;
- one workspace-write run;
- one controlled failure;
- one timeout/cancel test;
- one executor-shaped run;
- one tester-shaped run;
- two isolated concurrent runs after managed concurrency exists.

Capture:
- exact argv support/order;
- JSONL terminal event shape;
- exit-code semantics;
- auth-required shape;
- stderr behavior;
- sandbox/write/network behavior;
- process-tree behavior on cancellation.

## Recommendation

Keep the existing codex_workflow role set.

Refactor only `muse-max` into:
- Codex Main unchanged;
- persistent internal Companion = GPT-5.6 Luna XHigh;
- the remaining six roles = Muse Spark 1.3 Contributor Max via a rebuilt profile-aware Muse adapter;
- fresh tester invocation for every verification boundary;
- managed lane-level concurrency only when Project Workflow authorizes parallel Task Cards;
- no direct Muse worker-to-worker communication;
- raw Muse stream outside Main context; compact normalized result only.

Do not promote the earlier generic delegated-worker PR #23 as the current design without a new explicit strategic decision; this audit places the runtime mechanics in codex_workflow, where Project Workflow already says they belong.

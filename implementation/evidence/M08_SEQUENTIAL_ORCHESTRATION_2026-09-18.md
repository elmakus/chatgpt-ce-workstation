# M08 sequential Muse-max orchestration live evidence — 2026-09-18

## Scope

Card: `M08-T01 — Validate sequential Muse-max orchestration and RED repair`.

This record contains secret-safe integrated live facts only. Raw Muse trajectories and credential contents were not copied into project Git.

## Authorization and live baseline

- User explicitly authorized M08 live operations on 2026-09-18.
- Workstation container: `chatgpt-ce-workstation`, healthy during the pilot.
- Installed Muse Code: `1.3.0 (1.3.0-R3401.1)`.
- Exact `elmakus/codex_workflow` source used for the pilot: `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b` on `impl/m07-muse-process-result-adapter`, clean local worktree.
- Global user `~/.codex/codex_workflow` was absent and was not installed or modified.
- Isolated pilot runtime: `/home/codex/.codex/m08-live-pilot`.
- Isolated profile readback: `compute_profile = "muse-max"`.
- Profile allocation readback:
  - `companion` → `gpt-5.6-luna` / `xhigh` / `codex`;
  - `micro_executor`, `default_executor`, `senior_executor`, `tester`, `investigator`, `archivist` → `muse-spark-1.3-contributor` / `max` / `muse-code`.
- Disposable workspace: `/home/codex/Documents/ChatGPT/.m08-live-pilot`; removed after live verification with absence read back.
- Private pilot runtime/artifacts remain under the isolated M08 `CODEX_HOME` for bounded evidence/debugging and remain outside project Git.

## Six-role Muse routing

All six Muse-routed roles completed as distinct fresh one-shot adapter invocations with `terminal_status=completed`, process exit `0`, and role identity preserved in the normalized result:

- `default_executor`: implemented the GREEN-path `calculator.py` package;
- `tester`: independently verified the GREEN path without executor transcript/raw artifact input;
- `investigator`: read-only repository inspection;
- `micro_executor`: exact-byte tiny implementation probe;
- `senior_executor`: bounded interval-merging implementation probe;
- `archivist`: documentation-only write to its assigned path.

The Investigator probe had identical complete workspace file hash before and after execution.

## Executor → fresh Tester GREEN path

Default Executor created only `calculator.py` with `add(a, b) = a + b` and returned a compact normalized result.

Main independently read back the workspace and verified:

- `add(2, 3) == 5`;
- `add(-1, 1) == 0`;
- `add(1.5, 2.25) == 3.75`;
- only `calculator.py` was the source change.

A fresh Tester then received only:

- accepted verification authority;
- the resulting workspace state;
- explicit instruction not to inspect private Muse run artifacts or earlier worker capsules.

It did not receive the executor transcript or normalized executor report. The Tester returned `verdict=GREEN` and explicitly reported that it did not inspect executor transcript/private run artifacts.

## Deliberate RED → Main → fresh repair Executor → fresh Tester

Main created a committed disposable RED fixture where `clamp(value, low, high)` returned `value` unconditionally after the invalid-bounds guard. The accepted suite failed 2/4 checks:

- below-low returned `-2` instead of `0`;
- above-high returned `12` instead of `10`.

A fresh Tester received only the contract + actual repository state and returned `verdict=RED` with focused findings:

1. below-low branch missing;
2. above-high branch missing.

`decision_requirement` was null.

Main then built a repair capsule containing:

- the accepted `clamp` contract;
- those two focused findings;
- the durable workspace state;
- ownership limited to `clamp.py`.

The repair capsule contained no raw Muse event/stderr content, no private artifact path, and no previous run identifier.

A fresh Default Executor repaired only `clamp.py`. Main readback showed the intended four-line branch delta and the accepted unittest suite passed 4/4.

A second fresh Tester was launched using the same verification capsule as before the repair. It returned `verdict=GREEN`, independently passing the committed suite and additional boundary probes, and explicitly reported that it did not inspect private Muse run artifacts or previous worker capsules.

## Raw artifact isolation and lifecycle readback

Nine successful Muse invocations were retained privately in the isolated M08 runtime.

For every retained run:

- run directory mode: `0700`;
- `events.jsonl`, `stderr.log`, `result.json`: `0600`;
- raw event stream contained exactly one `run.terminal.completed`;
- raw event stream contained zero `run.terminal.failed`;
- normalized `result.json` contained no `run.terminal.*` raw lifecycle marker.

A scan of all M08 worker capsules found no `codex_workflow/muse_runs/<uuid>` path and no M08 run identifier.

A bounded raw-event scan across the M08 runs found zero occurrences of:

- `spawn_agent`;
- `send_message`;
- nested `muse exec`.

No `muse_worker.py` or M08-scoped Muse process remained after the pilot.

## Disposable workspace cleanup

The final disposable workspace state was clean before deletion. The workspace was removed and absence was read back successfully.

The isolated M08 `CODEX_HOME` was intentionally retained because it owns the private raw runtime evidence and is already subject to the adapter's bounded retention behavior.

## Companion live-validation blocker

The accepted M08 contract also requires live verification of one persistent internal GPT-5.6 Luna XHigh Companion under active `muse-max`.

Static/profile/runtime preparation is GREEN:

- the isolated active profile renders Companion as `gpt-5.6-luna` / `xhigh` / internal `codex`;
- the six Muse roles remain external Muse workers.

However, this normal ChatGPT executor has no internal Codex worker lifecycle operation exposed: no `spawn_agent`, `resume_agent`, or `wait_agent` tool is available. The workstation container also exposes no standalone `codex` CLI, consistent with the accepted workstation architecture. Remote Desktop Commander can operate the host/container but cannot substitute for the internal Codex subagent lifecycle.

Therefore live Companion creation/reuse was not executed and M08 cannot be marked GREEN yet.

Using another internal worker/model such as Sol Medium would not satisfy D21/R3 and must not be counted as the Companion acceptance check.

Smallest remaining evidence need:

- from an actual Codex Main workflow session with active `muse-max`, demonstrate one Companion creation as Luna XHigh and reuse of that same Companion within the same workflow session, or capture the concrete runtime/quota failure if creation is rejected.

## Current acceptance status

**BLOCKED only on live Companion creation/reuse.**

GREEN and durably evidenced:

- all six Muse role routings;
- fresh executor/tester separation;
- ordinary RED repair through Main;
- fresh Tester recheck;
- no raw trajectory transfer into later capsules;
- private raw artifact permissions/lifecycle;
- no observed nested Muse worker / sibling-messaging path;
- Investigator read-only behavior;
- Archivist bounded documentation behavior;
- disposable workspace/process cleanup.

Not yet claimable:

- live persistent internal Luna XHigh Companion creation/reuse.

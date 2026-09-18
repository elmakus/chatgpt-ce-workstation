# M09 live two-lane Muse smoke — 2026-09-18

## Subject

Card: `M09-T02 — Validate reviewed M09 candidate with a live two-lane Muse smoke`.

Exact independently reviewed source subject:

- `elmakus/codex_workflow@f6603767115cf7f31ef7d8c3cb3a419a7f430aca`
- PR `elmakus/codex_workflow#6`
- prior independent review: `implementation/reviews/m09-muse-lane-concurrency-independent-review-2026-09-18.md`

M09 live operations were explicitly authorized by the user on 2026-09-18.

The user also explicitly requested that the separate GPT-5.6 Luna XHigh Companion creation/reuse gate be deferred because Luna XHigh quota is currently unavailable. That gate remains mandatory and is tracked by `M09-T03`; this evidence does not satisfy it.

## Exact-candidate setup

The workstation container `chatgpt-ce-workstation` was healthy and Muse Code reported:

- `Muse Code 1.3.0 (1.3.0-R3401.1)`.

The existing primary `codex_workflow` worktree remained on:

- branch `impl/m07-muse-process-result-adapter`;
- commit `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`.

The reviewed M09 branch was fetched without changing the primary worktree. A detached disposable worktree was created at exactly:

- `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`.

An isolated runtime was bootstrapped at `/home/codex/.codex/m09-live-smoke`; the global `~/.codex/codex_workflow` installation remained absent.

The isolated profile readback was `muse-max`:

- `companion` → `gpt-5.6-luna` / `xhigh` / `codex`;
- `micro_executor`, `default_executor`, `senior_executor`, `tester`, `investigator`, `archivist` → `muse-spark-1.3-contributor` / `max` / `muse-code`.

No live Companion invocation was attempted in this Card.

## Managed two-lane live smoke

Two separate disposable Git workspaces were created:

- lane A: `/home/codex/Documents/ChatGPT/.m09-live-smoke/lane-a`;
- lane B: `/home/codex/Documents/ChatGPT/.m09-live-smoke/lane-b`.

The exact reviewed runtime's `MuseWorkerInvocation` + `execute_workers_concurrently(..., max_workers=2)` surface launched one `default_executor` Muse invocation per lane.

Both tasks required an actual 20-second shell wait before writing one lane-local marker file. While the batch was active, process readback showed two concurrent Muse Code processes at the same time:

- one bound to lane A with run/session ID `75bee16d-0baa-4ecf-ac60-cd8694099809`;
- one bound to lane B with run/session ID `03b7a819-cd2a-4f9a-b7c4-43cd0a1c7e73`.

The two processes had distinct process groups, workspaces, prompt/schema paths and session IDs.

The managed batch completed successfully with process exit 0. Elapsed wall time reported by the batch wrapper was approximately 91.8 seconds.

Normalized results:

- lane A: `terminal_status=completed`, `failure_kind=null`, exit 0, changed path only `lane-result.txt`, expected content `lane-a-green\n`;
- lane B: `terminal_status=completed`, `failure_kind=null`, exit 0, changed path only `lane-result.txt`, expected content `lane-b-green\n`.

Both returned distinct artifact/run references and no blocking finding or decision requirement.

The live concurrency acceptance is therefore GREEN: the exact reviewed managed helper concurrently awaited two independently assigned, non-overlapping Muse workspaces without a shared workspace/log collision or cross-lane cancellation.

## Cleanup / non-promotion readback

Before cleanup:

- exact candidate disposable worktree still read back at `f6603767115cf7f31ef7d8c3cb3a419a7f430aca` with no source modification;
- each lane had only its own untracked `lane-result.txt`;
- no M09 Muse process or batch driver remained;
- primary `codex_workflow` worktree remained at M07 checkpoint `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`;
- global `~/.codex/codex_workflow` remained absent.

Cleanup removed:

- the detached M09 source worktree;
- both disposable lane workspaces;
- the disposable control workspace.

Post-cleanup readback confirmed all three paths absent and residual M09 Muse-process count zero.

The isolated private M09 runtime under `/home/codex/.codex/m09-live-smoke` was retained with exactly two private run directories for bounded runtime evidence; raw event/stderr content remains outside project Git and Main context.

GitHub readback after the smoke confirmed PR #6 remained open and unmerged at exact head `f6603767115cf7f31ef7d8c3cb3a419a7f430aca`. No release publication or workstation production promotion occurred.

## Result

**M09-T02 GREEN.**

Still open and intentionally deferred:

- `M09-T03`: actual Codex Main creation and same-session reuse of one internal GPT-5.6 Luna XHigh Companion.

The Companion gate remains a hard pre-publication/pre-promotion requirement. Current user-reported lack of Luna XHigh quota is a blocker, not a pass, and no substitute model/harness is permitted.

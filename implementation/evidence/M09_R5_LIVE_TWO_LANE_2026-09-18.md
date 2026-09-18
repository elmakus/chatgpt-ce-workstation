# M09-T06 live two-lane Muse revalidation — exact R5 release candidate

Date: 2026-09-18

## Subject

Card: `M09-T06 — Live two-lane revalidation of exact R5 release candidate`.

Exact independently reviewed release candidate:

- repository: `elmakus/codex_workflow`
- branch: `release/m09-muse-max-candidate`
- commit: `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`
- independent review: `implementation/reviews/m09-r5-release-candidate-independent-review-2026-09-18.md`

M09 live operations were explicitly authorized by the user on 2026-09-18.

## Refresh / runtime baseline

Immediately before live validation:

- GitHub release-candidate branch read back at exact `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- workstation container `chatgpt-ce-workstation` was healthy;
- Muse Code reported `Muse Code 1.3.0 (1.3.0-R3401.1)`;
- primary `codex_workflow` worktree remained on `impl/m07-muse-process-result-adapter` at `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`;
- global `/home/codex/.codex/codex_workflow` runtime remained absent.

A detached disposable worktree was created from exactly `4081cde7...`, and an isolated runtime was bootstrapped at:

`/home/codex/.codex/m09-r5-live-smoke-4081cde`

The exact candidate bootstrap reported version `1.1.17-private.11`.

The isolated `muse-max` allocation read back as:

- `companion` -> `gpt-5.6-luna` / `xhigh` / `codex`;
- `micro_executor`, `default_executor`, `senior_executor`, `tester`, `investigator`, `archivist` -> `muse-spark-1.3-contributor` / `max` / `muse-code`.

No live Companion invocation was attempted.

## Managed two-lane live smoke

Two isolated disposable Git workspaces were created:

- lane A: `/home/codex/Documents/ChatGPT/.m09-r5-live-smoke/lane-a`;
- lane B: `/home/codex/Documents/ChatGPT/.m09-r5-live-smoke/lane-b`.

The exact candidate's `MuseWorkerInvocation` + `execute_workers_concurrently(..., max_workers=2)` launched one `default_executor` Muse invocation per lane.

Both tasks required an actual shell `sleep 20` before creating one lane-local marker.

During execution, process readback observed both Muse Code processes concurrently:

- lane A: PID 2277, PGID 2277, workspace lane A, session/run ID `75bee16d-0baa-4ecf-ac60-cd8694099811`;
- lane B: PID 2280, PGID 2280, workspace lane B, session/run ID `03b7a819-cd2a-4f9a-b7c4-43cd0a1c7e82`.

The processes had distinct process groups, workspaces, prompt/schema artifacts and session IDs.

The managed batch completed with exit 0 in approximately 97.39 seconds.

Normalized lane results:

- lane A: `terminal_status=completed`, `failure_kind=null`, exit 0, changed path only `lane-result.txt`, exact content `lane-a-green`;
- lane B: `terminal_status=completed`, `failure_kind=null`, exit 0, changed path only `lane-result.txt`, exact content `lane-b-green`.

Both results reported no blocking findings or decision requirement and referenced distinct private run artifacts.

Independent workspace readback after completion confirmed:

- lane A Git status contained only `?? lane-result.txt`, 12 bytes, content `lane-a-green`;
- lane B Git status contained only `?? lane-result.txt`, 12 bytes, content `lane-b-green`;
- the exact candidate source worktree remained clean at `4081cde7...`;
- no Muse/driver process associated with the validation remained.

## Cleanup / isolation

The detached candidate worktree and all disposable control/lane/task/driver paths under:

`/home/codex/Documents/ChatGPT/.m09-r5-live-smoke`

were removed. Post-cleanup readback reported the disposable root absent.

The isolated private runtime was retained only as bounded runtime evidence. Its Muse run root contains exactly the two run directories above, each mode `0700`. Raw event/stderr content remains outside project Git and Main context.

Global `/home/codex/.codex/codex_workflow` remained absent; no production runtime was installed or updated.

## No-publication / no-promotion readback

After live validation and cleanup:

- `codex_workflow/main` remained `f2b1811853a2c1da5a5af4bb735c84c3111a44d6`;
- `release/m09-muse-max-candidate` remained exactly `4081cde7d4f71bcc2083c62cf69b7e3b845eefb8`;
- `v1.1.17-private.11` still did not resolve as a Git tag/commit.

No main advancement, tag/release publication, published asset, workstation production promotion or Companion validation occurred in this Card.

## Result

**M09-T06 GREEN.**

The exact R5 release candidate now has both:

1. REQUIRED independent review GREEN; and
2. fresh live two-lane Muse validation GREEN on the same immutable commit.

Approved R5 therefore permits JIT preparation of publication/promotion for exact `4081cde7...`. The deferred GPT-5.6 Luna XHigh Companion creation/reuse obligation remains mandatory for final M09/project completion on the exact promoted release.

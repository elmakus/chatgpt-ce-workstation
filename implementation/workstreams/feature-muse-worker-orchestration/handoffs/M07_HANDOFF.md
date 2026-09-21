# M07 Handoff — Production Muse process/result adapter

## Completed checkpoint

- `elmakus/codex_workflow@b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`
- branch: `impl/m07-muse-process-result-adapter`
- predecessor M06 checkpoint: `2ee25a1d84a6a3b111b68a61604276219190d2a0`

## Achieved state

The `muse-max` Muse path now has a production-oriented single-invocation process/result adapter that:

- resolves active profile/role/model/reasoning through shared `codex_workflow` authority;
- selects the installed headless parser as `muse exec`;
- supplies a versioned structured worker-report schema;
- continuously drains JSONL stdout and diagnostic stderr;
- stores raw per-run artifacts privately under the configured persistent `CODEX_HOME`;
- emits one bounded normalized Main-facing result with tester verdict support;
- fails closed on malformed/missing terminal protocol or normalized report;
- distinguishes Muse/model, auth/runtime, timeout, cancellation, protocol/report and adapter/internal failures;
- enforces bounded raw stream size and retained run count/age/aggregate size;
- handles graceful-then-hard process-tree cancellation, including descendants that moved into separate process groups/sessions;
- preserves the mixed-harness profile boundary and other-profile behavior.

M07-T03 corrected the first live-discovered CLI dispatch defect from the initial M07-T01 checkpoint: Muse 1.3.0 requires `muse exec` to select the headless parser before exec-specific flags. The corrected exact subject above also prevents generic Muse help text from misclassifying that argv/parser failure as authentication.

## Acceptance evidence

Deterministic verification on the corrected subject:

- focused adapter suite: 12/12 GREEN;
- mixed-profile suite: 7/7 GREEN;
- workflow runtime regression: 90/90 GREEN;
- Python compileall: GREEN;
- `git diff --check`: GREEN;
- GitHub branch readback: exact corrected subject confirmed.

Live workstation evidence:

- `implementation/workstreams/feature-muse-worker-orchestration/evidence/M07_LIVE_ADAPTER_SMOKE_2026-09-18.md`;
- installed Muse Code 1.3.0 with persistent account auth;
- read-only `investigator` invocation: completed, exit 0, workspace unchanged;
- write `default_executor` invocation: completed, exit 0, exactly one requested 22-byte file created and no other workspace state changed;
- each successful raw event stream contained exactly one `run.terminal.completed`;
- raw run directories/files read back as `0700/0600`;
- normalized results did not embed raw event stream content;
- no residual probe processes;
- disposable workspace removed and cleanup verified.

The user's global compute-profile state was not modified for validation. A dedicated persistent smoke `CODEX_HOME` under `/home/codex/.codex/m07-live-smoke` was used, while the real Muse account credential remained owned by the official CLI and was never read.

## Review/publication

No separate M07 independent review or publication is required. The complete runtime subject receives independent review and production promotion in M09.

## Deferred / next durable starting point

M08 owns sequential role orchestration, separate executor/tester invocation behavior and the ordinary RED repair loop through Main. It must start with JIT Execution Prep from:

- approved M08 plan/requirements;
- exact M07 checkpoint above;
- M07 live adapter evidence.

M09 remains responsible for bounded authorized lane concurrency, final independent review, release/publication and final workstation promotion.

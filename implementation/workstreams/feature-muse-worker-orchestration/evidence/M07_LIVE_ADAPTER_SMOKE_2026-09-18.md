# M07 live adapter smoke evidence — 2026-09-18

## Scope

Card: `M07-T02 — Validate production Muse adapter live on workstation`.

This record contains only secret-safe live facts. Credential contents were not read.

## Live baseline

- exact adapter source before first attempt: `elmakus/codex_workflow@ab9601d9a3e587168b4c3182b3be3dffd7cc12bd`;
- workstation container: healthy;
- Muse Code: `1.3.0 (1.3.0-R3401.1)`;
- persistent Meta account credential file exists at `/home/codex/.config/muse/auth.json`, mode `0600`, owned by `codex:users`; contents were not read;
- global `/home/codex/.codex/codex_workflow/settings.toml` was absent, so the smoke did not change the user's global compute profile;
- isolated persistent smoke runtime: `/home/codex/.codex/m07-live-smoke`, materialized from the exact M07 source with `compute_profile = "muse-max"`;
- disposable workspace: `/home/codex/Documents/ChatGPT/.m07-live-smoke`.

## First read-only attempt

The exact adapter was invoked for role `investigator` with logical task `M07-T02-READ`.

Observed result:

- adapter exit: non-zero;
- Muse process exit recorded by adapter: `2`;
- normalized terminal status: `failed`;
- no terminal JSONL record was emitted; raw events artifact size was `0`;
- raw artifact directory mode `0700`; `events.jsonl`, `stderr.log`, and `result.json` were mode `0600`;
- disposable workspace hashes were unchanged after the failed read-only attempt.

Bounded diagnostic stderr from the adapter-owned artifact showed:

`invalid TUI options: error: unexpected argument '--prompt-file' found`

A help-only diagnostic confirmed:

- `muse exec --help` exposes `--prompt-file`, `--json`, `--output-schema`, `--session-id`, model/reasoning/workspace controls and the safety flags;
- `muse --disable-approval --trust-workspace exec --help` remains in the top-level/TUI parser;
- `muse exec --disable-approval --trust-workspace --help` selects the headless exec parser.

Conclusion: M07-T01's argv order is incompatible with the installed Muse 1.3.0 parser. The correction is bounded inside the accepted M07 contract. The first attempt also exposed a classification bug: the adapter labeled the parser failure `auth_runtime` because generic help text contained auth/login vocabulary.

Live read/write acceptance is not yet claimed. M07-T02 is paused until the corrective Card is GREEN.


## Corrective implementation

Bounded corrective Card `M07-T03` changed only the live-discovered adapter defect:

- corrected Muse argv dispatch to select the headless parser as `muse exec ...`;
- corrected pre-run CLI parser/usage classification so generic help text mentioning login/auth cannot convert an argv defect into `auth_runtime`;
- updated exact command documentation and deterministic expectations.

Corrected exact subject:

`elmakus/codex_workflow@b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b`

Deterministic correction verification:

- focused adapter suite: 12/12 GREEN;
- mixed-profile suite: 7/7 GREEN;
- workflow runtime regression: 90/90 GREEN;
- Python compileall: GREEN;
- `git diff --check`: GREEN;
- GitHub readback confirmed the branch head at the exact subject above.

## Successful read-only live smoke

The read-only smoke was repeated against exact source `b87f4eb4e1611407a9a5aa1d31b16b2cc8f1974b` using:

- role: `investigator`;
- logical task: `M07-T02-READ`;
- actual installed Muse Code 1.3.0;
- the persistent Meta account login;
- isolated `muse-max` smoke runtime under `/home/codex/.codex/m07-live-smoke`.

Observed normalized result:

- terminal status: `completed`;
- process exit code: `0`;
- failure kind: null;
- marker `M07_READ_ONLY_MARKER` was read correctly;
- workspace hashes before/after were identical.

Raw artifact readback for run `e6fea80f-fc30-4307-9c90-cbe3a6c1c8ad`:

- run directory mode `0700`;
- `events.jsonl`, `stderr.log`, `result.json`: mode `0600`;
- JSONL records: 73;
- terminal records: exactly one `run.terminal.completed`;
- stored normalized result: `completed`, exit `0`;
- normalized result did not contain raw `run.terminal.*` event content.

## Successful write live smoke

The write smoke used:

- role: `default_executor`;
- logical task: `M07-T02-WRITE`;
- the same exact corrected adapter subject and live Muse/auth state.

The worker was instructed to create exactly one file:

`M07_WRITE_OK.txt`

with exact bytes:

`MUSE_ADAPTER_WRITE_OK\n`

Observed:

- terminal status: `completed`;
- process exit code: `0`;
- failure kind: null;
- target file byte comparison: GREEN;
- target size: 22 bytes;
- hashes of every pre-existing workspace file remained unchanged;
- complete workspace tree delta contained only the requested target file.

Raw artifact readback for run `7d9f0088-8883-4443-adea-12221032b104`:

- run directory mode `0700`;
- `events.jsonl`, `stderr.log`, `result.json`: mode `0600`;
- JSONL records: 157;
- terminal records: exactly one `run.terminal.completed`;
- stored normalized result: `completed`, exit `0`;
- normalized result did not contain raw `run.terminal.*` event content.

## Process and cleanup readback

After both successful probes:

- no process remained matching either live run session id;
- no process remained tied to the disposable `.m07-live-smoke` workspace;
- the disposable workspace was removed and absence was read back;
- private run artifacts were intentionally retained under `/home/codex/.codex/m07-live-smoke/codex_workflow/muse_runs/` for bounded runtime evidence/debugging;
- the user's global `/home/codex/.codex/codex_workflow/settings.toml` was not created or changed by this validation.

## M07-T02 acceptance summary

GREEN.

- exact corrected M07 adapter subject verified live against installed Muse Code 1.3.0;
- one read-only invocation completed successfully without workspace mutation;
- one write invocation completed successfully with exactly the requested mutation;
- normalized results were bounded and machine-readable;
- raw JSONL/stderr were isolated in private persistent run artifacts;
- raw artifacts were referenced rather than copied into normal Main-facing results;
- no credential contents were read or committed;
- no residual probe processes remained;
- disposable workspace cleanup was verified.

The first failed argv attempt remains recorded above because it is the evidence that produced M07-T03. It is not counted as a passing live smoke.

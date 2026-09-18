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

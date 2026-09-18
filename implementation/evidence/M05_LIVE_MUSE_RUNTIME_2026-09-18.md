# M05 live Muse runtime evidence — 2026-09-18

## Scope

Card: `M05-T01 — Capture live Muse CLI/runtime contract`

This evidence records only secret-safe facts observed from the live Unraid workstation and repository source. Authentication/session material is intentionally excluded.

## Deployment baseline

The workstation was rebuilt from synchronized current `main` after correcting the Muse installer temporary-directory traversal defect.

Observed live update result:

- image build completed successfully;
- workstation container recreated successfully;
- container health: `healthy`;
- runtime verifier: `WORKSTATION_RUNTIME_GREEN`;
- restart policy: `unless-stopped`;
- persistent home bind: `/mnt/user/appdata/chatgpt-ce-workstation/home -> /home/codex`;
- project bind: `/mnt/user/projects -> /home/codex/Documents/ChatGPT`;
- no active `/workspace` mount;
- no Docker socket mount;
- container unprivileged and without `SYS_ADMIN`;
- Openbox, Tint2, xterm, Chrome, CE, Codex Web GPT and Muse launchers are present;
- Tint2 is running;
- canonical project root is writable.

A preserved pre-migration backup directory remains under persistent home and is not part of this Muse contract:

`/mnt/user/appdata/chatgpt-ce-workstation/home/Documents/ChatGPT.pre-bind-20260917-201518`

## Muse installation

Observed live version:

`Muse Code 1.3.0 (1.3.0-R3401.1)`

The runtime verifier confirmed:

- `muse` resolves in PATH;
- `muse --version` succeeds;
- `muse --help` succeeds;
- `muse exec --help` succeeds;
- image-owned Muse executable exists under `/opt/muse-code/bin`.

## Live installer correction

The first synchronized build failed while executing the downloaded vendor installer as the unprivileged `codex` user.

Observed failure:

`bash: /tmp/muse-code.<random>/install.sh: Permission denied`

Root cause was exact and local:

- `mktemp -d` created the per-build parent directory as root-owned mode `0700`;
- the downloaded installer itself was executable;
- `runuser -u codex` could not traverse the root-owned parent directory.

Correction merged through workstation PR #2:

- ownership of only the per-build temporary directory is transferred to `codex`;
- mode remains `0700`;
- installer still runs as `codex`, not root;
- checksum verification, isolated build HOME, install path and auth policy are unchanged.

The next live rebuild passed the former failing step and completed runtime verification GREEN.

## Exact CLI surface observed

`muse --help` confirms:

- provider modes: `echo` and `meta` (default `meta`);
- explicit `--model <MODEL>`;
- Meta reasoning effort: `none|minimal|low|medium|high|xhigh|max|ultra` (default `high`);
- explicit `--workspace <PATH>`;
- Git worktree modes `off|create|existing`;
- approval mode `untrusted|on-request|never`;
- sandbox enabled by default with network modes `restricted|enabled|proxy-only` (default `proxy-only`);
- independent controls for approval, sandbox, workspace writes and shell;
- native subagent/worktree capability exists but is not selected by default.

`muse exec --help` confirms the headless adapter surface:

- `--json` emits machine-readable JSONL events on stdout;
- `--prompt-file <PATH>`;
- `--model <ID>`;
- `--reasoning-effort <EFFORT>`, including `max`;
- `--workspace <PATH>`;
- `--output-schema <FILE>` for final-answer shaping on the Meta provider;
- `--max-model-steps <N>`;
- `--max-tool-output-bytes <N>`;
- `--session-id <UUID>`;
- `--user-input-auto-resolve` for headless request_user_input handling;
- `--approval-mode <MODE>`;
- `--sandbox-network <MODE>`;
- `--disable-write`, `--disable-shell`, `--disable-web-tools`, `--disable-sandbox`, and `--disable-approval`.

These flags are exact live evidence for Muse Code 1.3.0; later adapter implementation must bind to this observed surface rather than public-document assumptions.

## Pre-login persistent-home state

Before any Muse login:

- `/home/codex/.config/muse` — absent;
- `/home/codex/.local/share/muse` — absent;
- `/home/codex/.local/state/muse` — absent.

This provides a clean baseline for identifying login-created durable state.

## Still required for M05 acceptance

Pending live evidence:

- exact `muse login --help` behavior and account/subscription login flow;
- account/subscription login and resulting persistent paths;
- authentication survival across restart/recreate;
- successful machine-readable read-only run;
- successful workspace-write run;
- controlled failure and stdout/stderr/exit semantics;
- observed sandbox/write/network boundaries;
- process/subprocess behavior relevant to later cancellation design.

No passing claim is made yet for these pending items.

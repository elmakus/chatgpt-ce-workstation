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


## Account login and persistence

Exact live login flow:

- `muse login --help` states that login uses a Meta account and browser/device-code approval.
- `muse auth` is a separate API-key credential path and was not used.
- `muse logout` removes the saved Meta credential; environment `META_API_KEY` is a separate higher-priority mechanism.
- Meta account login completed successfully with process exit code `0`.
- Muse reported: credential saved to `/home/codex/.config/muse/auth.json`.
- Muse reported Model API access verified.

Secret-safe persistent path metadata after login:

- `/home/codex/.config/muse/auth.json`: mode `0600`, owner `codex`, group `users`;
- `/home/codex/.config/muse/.auth.json.lock` exists;
- `/home/codex/.local/share/muse/local-tracing/bootstrap/` exists with mode `0700` tracing data;
- `/home/codex/.local/state/muse` remains absent.

Credential file contents were not read or committed.

Persistence is verified across both:

1. ordinary container restart; and
2. full Compose `--force-recreate`.

After each lifecycle operation, a Meta-provider headless run succeeded using the persisted account credential.

## Machine-readable success contract

A read-only probe using `muse exec --json` completed with process exit code `0`.

Observed key records:

- `run.model.configured` identified `model_id: muse-spark-1.3-contributor`, provider `meta`;
- output text arrived through one or more `run.output.delta` status records;
- deterministic terminal success record:
  - `payload_type: run.terminal.completed`;
  - `payload.kind: run_terminal`;
  - `payload.terminal: completed`;
  - `payload.reason: null`;
  - final answer in `payload.text`.

A simple run also emits other task/lifecycle/reminder records, so an adapter must select records by `payload_type`/run identity rather than assuming one JSON object per logical answer.

## Stdout/stderr separation and max effort

After full container recreate, the following was accepted live:

- explicit model `muse-spark-1.3-contributor`;
- explicit `--reasoning-effort max`;
- `--disable-shell`;
- `--disable-write`;
- `--disable-web-tools`;
- `--user-input-auto-resolve`;
- `--max-model-steps 1`;
- `--json`.

Result:

- exit code `0`;
- stdout contained JSONL only (21839 bytes in this probe);
- stderr contained human-readable operational notices only (132 bytes);
- terminal JSONL record was `run.terminal.completed` with expected final text.

This establishes that production parsing should consume stdout as JSONL and treat stderr as diagnostic text, without mixing the two streams.


## Controlled failure contract

A deliberate nonexistent-model probe established deterministic failure behavior:

- process exit code: `1`;
- stderr contains a human-readable provider/model failure;
- JSONL includes `task.lifecycle.failed`;
- terminal JSONL record is `run.terminal.failed`;
- `payload.terminal: failed`;
- `payload.reason` contains the provider/model failure reason;
- `payload.text` is empty for this failure.

The adapter can therefore classify a provider/model failure from structured stdout and use stderr as diagnostic context.

## Workspace write behavior

A disposable explicit workspace under the project bind was used with:

- `--workspace <PATH>`;
- `--disable-shell`;
- `--disable-web-tools`;
- approvals disabled;
- sandbox left enabled;
- explicit model `muse-spark-1.3-contributor`;
- explicit `--reasoning-effort max`.

Muse created exactly one requested file through non-shell workspace tooling and returned `run.terminal.completed` / exit `0`.

Observed file:

- mode `0644`;
- exact bytes: `MUSE_WRITE_OK\n`.

This proves policy-gated non-shell workspace writes function inside the current workstation container while the OS shell sandbox limitation below is independent.

## Sandbox and network boundary

The default Muse OS shell sandbox does **not** function inside the current unprivileged Unraid Docker boundary.

Observed shell-tool failure with sandbox enabled:

- Muse accepted/scheduled `tool.bash`;
- bubblewrap failed before the shell command ran:
  `bwrap: No permissions to create new namespace, likely because the kernel does not allow non-privileged user namespaces.`;
- shell tool task became `task.lifecycle.failed`;
- Muse attempted an unsandboxed retry path, which was rejected when approval prompts were disabled:
  `unsandboxed execution requires human approval, but approval prompts are disabled`.

Therefore production Muse shell execution in this workstation cannot rely on nested bubblewrap/user-namespace sandboxing.

A second probe used `--disable-sandbox` while retaining the Docker container as the outer isolation boundary and keeping approvals disabled.

Observed:

- harmless shell `printf SHELL_OK` completed with exit `0`;
- outbound HTTPS HEAD to `https://example.com` completed with exit `0` and `NET_OK`;
- shell task lifecycle and `tool.result` records were emitted;
- run terminal was `run.terminal.completed` with final text `SHELL_OK NET_OK`.

Binding implication for later implementation: shell-capable Muse profiles on this workstation require `--disable-sandbox`; Docker remains the external isolation boundary. This is an observed runtime requirement, not a general Muse recommendation.

## Process/subprocess and termination behavior

A bounded live process-tree probe used a unique Muse session id and an unsandboxed shell command `sleep 60`.

Observed while the command was active:

- Muse process: PID/PGID/SID `1901/1901/1901`;
- shell-tool process: `/bin/sh -c sleep 60`, PPID `1901`, but its own PGID/SID `1930/1930`;
- `sleep 60` was a child of that shell and shared PGID/SID `1930/1930`.

This proves shell-tool subprocesses may live in a distinct process group/session from the Muse parent, so a future adapter must not assume that signaling only the Muse process group is sufficient by POSIX grouping alone.

Termination probe:

- sent `SIGTERM` only to the active Muse PID;
- two seconds later neither the Muse process nor the shell/sleep subtree remained;
- Muse emitted `received SIGTERM; flushed session logs`;
- outer process exit code was `143`.

Therefore the observed Muse 1.3.0 runtime performs child cleanup on normal TERM. A production adapter should still retain a bounded process-tree verification/fallback kill path for timeout/cancel robustness because the child process group is distinct.

## M05 acceptance summary

GREEN for the live-runtime evidence Card:

- exact installed version recorded;
- exact headless/machine-readable argv surface recorded;
- subscription/account auth path and persistent state recorded without secrets;
- auth survives restart and full recreate;
- read-only machine-readable success observed;
- workspace-write success observed;
- stdout/stderr separation observed;
- controlled provider/model failure observed;
- terminal success/failure JSONL records identified;
- nested sandbox limitation classified;
- unsandboxed shell/network behavior inside the Docker boundary classified;
- process/subprocess layout and TERM cleanup behavior observed.

No credential content, login code, token, cookie, or secret-bearing raw session material is committed in this evidence.

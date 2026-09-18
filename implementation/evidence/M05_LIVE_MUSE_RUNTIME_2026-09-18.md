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

## Still required for M05 acceptance

Pending live evidence:

- exact `muse --help` / `muse exec --help` invocation surface needed by the adapter;
- pre-login Muse filesystem state under persistent `/home/codex`;
- account/subscription login and resulting persistent paths;
- authentication survival across restart/recreate;
- successful machine-readable read-only run;
- successful workspace-write run;
- controlled failure and stdout/stderr/exit semantics;
- observed sandbox/write/network boundaries;
- process/subprocess behavior relevant to later cancellation design.

No passing claim is made yet for these pending items.

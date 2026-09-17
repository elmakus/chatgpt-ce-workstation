# Muse Code integration plan

Status: implementation candidate / live-validation pending
Branch: `feat/muse-code`

This branch keeps Muse Code separate from the workstation baseline until the first live Unraid validation passes.

## Goal

Install the official Muse Code CLI as an immutable workstation tool so the orchestration layer can launch bounded Muse workers beside Codex.

Target topology:

```text
workflow orchestrator
        |
        +--> native Codex work
        |
        `--> Muse Code worker processes
```

Use Muse account/subscription authentication. Do not introduce Meta Model API/PAYG credentials by default.

## Persistence model

The workstation already bind-mounts the complete user home:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home -> /home/codex
```

Therefore native Muse user paths below the home directory already persist without extra mounts, including expected paths such as:

```text
/home/codex/.config/muse/
/home/codex/.local/share/muse/
/home/codex/.local/state/muse/
```

Do not add redundant nested bind mounts for these paths. During the first live login/run, diff `/home/codex` before and after. Add a new bind only if the installed Muse build writes important durable state outside `/home/codex`.

Application binaries must not live only under `/home/codex` in the image because the runtime home bind would hide them. Keep image-owned Muse files under `/opt/muse-code` and expose a workstation wrapper from `/usr/local/bin/muse`.

## Immutable-image candidate

The intended build-time layout is:

```text
/opt/muse-code/bin/muse
/opt/muse-code/bin/muse-bin-*
/usr/local/bin/muse
```

The build helper downloads the official installer to a file, records its SHA-256, optionally verifies a configured expected SHA-256, and runs it with an isolated temporary build HOME. It requests `/opt/muse-code/bin` as the install directory and prevents PATH modification.

The wrapper disables runtime auto-update so ordinary agent runs cannot silently mutate the image-owned Muse installation. Workstation rebuild/update remains the normal upgrade path.

Because a stable first-party exact-version artifact contract has not yet been confirmed, the first implementation follows the stable channel at image-build time and records the resolved `muse --version`. If live inspection exposes a supported exact version/artifact contract, replace this with a strict pin.

## Candidate worker contract

Start with `muse exec` after confirming the installed CLI help. The orchestration adapter should prefer:

```text
machine-readable output
explicit workspace/cwd
explicit model
explicit reasoning effort
non-interactive approval behavior
non-interactive user-input behavior
bounded model steps
outer timeout and process-tree cancellation
fresh session id per worker
```

Current first-party material confirms Muse has an OS-level sandbox with workspace/temp write access and restricted network behavior. Test the sandbox inside this Docker boundary first. Keep it if it works; use `--disable-sandbox` only for profiles/tasks that actually require it or if nested containment fails live.

Muse also supports native subagent fan-out. The workstation orchestration layer already owns concurrency, worktrees and worker lifecycle, so the default integration should keep one orchestrator worker equal to one Muse process. Do not enable nested Muse fan-out by default until its accounting and cancellation behavior are deliberately integrated.

## Authentication

Login/auth state belongs under persistent `/home/codex`; no auth token or API key belongs in the image or Git repository.

First live validation must:

1. capture `muse --version`, `muse --help`, and `muse exec --help`;
2. record filesystem state under `/home/codex` before login;
3. complete normal Muse account/subscription login;
4. record the new/changed Muse paths;
5. restart and recreate the workstation;
6. prove Muse remains authenticated;
7. run one bounded disposable-repository task.

## Validation gates before merge

```text
[ ] workstation source validation passes
[ ] image build installs Muse and records exact version
[ ] Muse binary is image-owned under /opt/muse-code
[ ] runtime wrapper disables Muse auto-update
[ ] native Muse auth/config paths are observed
[ ] Muse login survives restart and recreate
[ ] headless worker does not wait for interactive input
[ ] disposable-repo task succeeds
[ ] selected model/effort is actually accepted
[ ] process cancellation/timeout works cleanly
[ ] sandbox behavior inside Docker is classified
[ ] nested Muse fan-out policy is explicit
[ ] no Muse secret is present in Git or image
```

# Muse Code research snapshot — 2026-09-17

Status: research plus implementation assumptions to validate live. Account-specific subscription details and credentials are intentionally omitted.

## Current first-party evidence

Meta publishes a public Muse Code SDK for programmatic control over Muse Session Protocol (MSP). The SDK is explicitly Developer Preview and its APIs may still change before 1.0. Current public issues also show that `muse serve` / MSP behavior around model pinning and top reasoning effort can lag the CLI/provider path.

For the first workstation integration, prefer the installed Muse CLI and `muse exec` rather than making MSP a hard dependency. The installed CLI remains the authority for exact flags and behavior.

Meta's public cookbook demonstrates that Muse's managed Linux sandbox:

- grants write access to the selected workspace and temp roots;
- keeps other filesystem areas read-only;
- restricts network egress;
- live-probes enforcement and refuses to claim containment if the OS policy is not actually active;
- can be disabled explicitly with `--disable-sandbox` / `--yolo` when a task needs unrestricted behavior.

The same cookbook demonstrates Muse-native subagent fan-out with isolated git worktrees. That is useful capability, but it overlaps with the workstation orchestration layer's own worker/worktree model. Do not enable nested fan-out by default.

## Installation assumptions

Current public installation guidance uses Meta's installer from:

```text
https://dev.meta.ai/install.sh
```

The implementation candidate downloads that installer to a file during image build rather than piping it directly to a shell. It records the installer SHA-256 and can verify an expected SHA-256 when one is configured.

Current ecosystem evidence reports installer controls such as:

```text
MUSE_INSTALL_DIR
MUSE_NO_MODIFY_PATH
MUSE_NO_AUTO_UPDATE
MUSE_SYNC_UPDATE
```

Treat these as implementation assumptions until the first image build confirms them against the live installer. The candidate image layout is `/opt/muse-code/bin`, with a workstation-owned `/usr/local/bin/muse` wrapper that sets `MUSE_NO_AUTO_UPDATE=1`.

No stable exact-version pin contract is assumed yet. The build records the resolved `muse --version`; if first-party live behavior exposes a robust exact artifact/version selector, switch to a strict pin later.

## Persistence

The workstation already persists all of `/home/codex`, so expected native Muse paths are naturally durable:

```text
/home/codex/.config/muse/
/home/codex/.local/share/muse/
/home/codex/.local/state/muse/
```

Do not add extra nested mounts for these paths before evidence requires them. On first login/run, capture a before/after path diff under `/home/codex`. If Muse writes important durable state outside the home directory, add a dedicated bind then.

## Authentication

The intended path is normal Muse account/subscription authentication. Do not bake tokens, auth JSON or Meta Model API keys into the image, Compose file or repository.

The first live login should be done as `codex` with `HOME=/home/codex`. After login, restart and then force-recreate the container while keeping the home bind, proving the session survives both lifecycle boundaries.

## Headless worker boundary

`muse exec` is the preferred first worker boundary. Before freezing the orchestrator adapter, capture:

```bash
muse --version
muse --help
muse exec --help
```

Then verify the exact current support for:

```text
machine-readable output
workspace/cwd selection
model selection
reasoning effort
approval controls
user-input auto resolution
sandbox controls
session identifier
maximum model steps
process cancellation
```

For unattended workers, never rely on an interactive approval or user-question prompt. Keep an outer process timeout and process-tree cancellation even if Muse exposes its own limits.

## Sandbox decision

Default test order:

1. run Muse with its managed sandbox enabled;
2. verify normal read/write work inside the selected disposable repository;
3. verify whether required build/test/network actions are compatible;
4. use an explicit no-sandbox worker profile only where required or if nested sandbox enforcement cannot work correctly inside the workstation container.

Do not globally disable the Muse sandbox merely because the outer Docker container already exists; the two boundaries provide different containment properties.

## Orchestration decision

The workflow/orchestrator should own concurrency and worktree isolation. Default candidate:

```text
one orchestration worker -> one Muse process -> one assigned worktree
```

Muse-native subagents remain off by policy unless a later profile intentionally delegates orchestration to Muse. This avoids double fan-out, unclear cancellation ownership and accidental quota amplification.

## Codex-LB coexistence

Codex-LB routing is independent from Muse. The workstation fork already supports a custom native Codex upstream and replaces the incoming ChatGPT bearer with a dedicated upstream key before forwarding to that custom upstream.

The workstation stores that key in a Docker secret file rather than Compose environment. The upstream URL itself is non-secret configuration and may remain blank until Codex-LB is connected.

## First live implementation sequence

1. Build the image and inspect the Muse installer output plus recorded SHA-256/version.
2. Confirm `/opt/muse-code/bin/muse` and `/usr/local/bin/muse` work as `codex`.
3. Capture CLI help and adjust unsupported assumptions immediately.
4. Diff `/home/codex`, complete Muse login, and diff again.
5. Restart and recreate; confirm auth persists.
6. Run a bounded disposable-repo `muse exec` task.
7. Test approval/user-input non-interactivity.
8. Test sandbox-on behavior, then no-sandbox only if required.
9. Test SIGTERM/SIGINT and outer timeout cleanup.
10. Confirm the requested model/reasoning route is not silently substituted.
11. Only then merge Muse support into `main`.

# Architecture decisions

Date: 2026-09-17

This document records accepted architecture decisions so they do not need to be reconstructed from chat history.

## D1 — Docker instead of VM

**Decision:** run the workstation as an Unraid Docker container.

The workload should consume CPU/RAM on demand instead of reserving resources for a full guest operating system. The user primarily needs an always-on Codex host, not a general-purpose VM.

## D2 — ChatGPT Community Edition is the host application

Use `ilysenko/codex-desktop-linux` / ChatGPT Community Edition as the Linux desktop host.

It builds a Linux desktop around the OpenAI ChatGPT/Codex application payload and exposes Linux-specific integrations required by this workstation, including Remote Mobile Control.

Upstream project:

- https://github.com/ilysenko/codex-desktop-linux

## D3 — No separate standalone Codex CLI in v1

The user intends to work primarily through ChatGPT Remote Control on Android.

A second standalone Codex CLI would introduce a possible version split between CE's bundled Codex and another independently updated executable. The native Remote workflow therefore keeps CE's bundled Codex as the authoritative runtime.

A standalone CLI may be added later only if a concrete terminal workflow requires it.

## D4 — CE Linux features

Current workstation selection:

```json
{
  "enabled": [
    "remote-mobile-control",
    "agent-workspace",
    "computer-use-linux",
    "authored-message-visibility",
    "automation-extensions",
    "mcp-helper-reaper",
    "node-repl-reaper",
    "project-group-last-updated-sort",
    "directory-only-working-tree-watch"
  ]
}
```

`directory-only-working-tree-watch` is the selected repository-watch strategy. Do not enable the conflicting `shallow-repository-watches` path at the same time.

Android Remote Control has been validated on the target workstation. It remains an upstream-sensitive feature and should be regression-tested after significant CE updates.

## D5 — Native `.deb` and accepted Electron sandbox compromise

Build CE through its native Debian packaging path and install the resulting package in the image.

Set:

```text
PACKAGE_WITH_UPDATER=0
```

The CE updater must not mutate a running container. Updating CE means rebuilding the workstation image.

On the target Unraid Docker boundary, CE's Chromium/Electron sandbox does not initialize reliably without broader container privileges. The accepted runtime therefore launches CE with `--no-sandbox` **inside the dedicated unprivileged workstation container** instead of adding `SYS_ADMIN`, `privileged`, a host-root mount, or the Docker socket.

Docker remains the isolation boundary.

## D6 — s6-overlay instead of systemd

Use s6-overlay as PID 1 and supervisor.

Reasons:

- container-native;
- lightweight;
- good lifecycle/restart behavior;
- avoids turning the container into a mini VM just to gain systemd.

Current pinned bootstrap version: `3.2.3.2`. User-service membership follows the s6-overlay v3 path under `/etc/s6-overlay/user-bundles.d/user/contents.d/`.

## D7 — Lightweight recoverable noVNC desktop

Use:

```text
Xvfb
  -> Openbox (desktop lifetime anchor)
  -> Tint2 panel
  -> ChatGPT CE / Codex Web GPT / terminal
  -> x11vnc (localhost only)
  -> websockify/noVNC :6080
```

noVNC is intended for login, configuration, recovery and diagnostics. It is also intentionally capable of relaunching applications without restarting the container.

ChatGPT CE is **not** the desktop lifetime anchor. If CE is closed with Quit, Openbox/noVNC remains alive. CE can be relaunched from the Tint2 panel or Openbox right-click menu.

Critical Openbox/x11vnc/websockify exits terminate the desktop longrun so s6 restarts the desktop session as one clean unit. CE and Codex Web GPT exits do not control the session lifetime.

## D8 — Persistent full user home

Bind mount the entire home:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home
  -> /home/codex
```

Persisting the full home protects state written by CE, Codex, keyring, Remote Control, SSH/GitHub, Codex Web GPT and future tools without requiring per-directory guesses.

## D9 — Projects live directly on Unraid at CE's native project path

Bind:

```text
/mnt/user/projects
  -> /home/codex/Documents/ChatGPT
```

`/home/codex/Documents/ChatGPT` is the single canonical persistent project root and the native CE **Create Project** location.

There is no second `/workspace` project mount and no `/workspace` compatibility symlink in the desired architecture.

Prefer cloning this workstation repository itself to:

```text
/mnt/user/projects/chatgpt-ce-workstation
```

so the running agent sees its own durable source at:

```text
/home/codex/Documents/ChatGPT/chatgpt-ce-workstation
```

A separate project-data share should be added only for a concrete storage-tier or shared-large-data requirement.

## D10 — Image owns system/application state

System/application changes must ultimately be reproducible from the repository.

A live install may temporarily unblock a task, but useful changes must be persisted in `Dockerfile`, `compose.yaml`, `rootfs/`, `scripts/container/`, or the relevant project manifest before the next recreate/update.

## D11 — Codex Web GPT included; our fork is the default package source

The workstation installs Codex Web GPT from:

- https://github.com/elmakus/codex-chatgpt-web

The fork preserves normal browser-backed behavior and additionally contains optional native-upstream routing support for future Codex-LB use. The workstation v1 does not require Codex-LB to function.

The Docker build downloads the fork's Linux x64 release, verifies its checksum, installs it into `/opt/codex-web-gpt`, and exposes `/usr/local/bin/codex-web-gpt`.

Codex Web GPT starts automatically with the desktop session and can be relaunched from the noVNC panel/menu if closed.

## D12 — GitHub pushes and global agent policy

Editing a bind-mounted repository immediately edits the real Unraid file, but does not update GitHub until normal Git operations occur.

Do not create a blind post-commit auto-push hook. Durable agent instructions should require tests/status/commit/push at accepted task completion and forbid force-push without explicit approval.

The workstation-wide instruction template at `defaults/AGENTS.md` is seeded to `~/.codex/AGENTS.md` only when that persistent file does not already exist. Existing user changes are not overwritten automatically.

## D13 — No Docker socket in v1

Do not mount:

```text
/var/run/docker.sock
```

Do not add a host-root bind or privileged container mode as a shortcut either.

Passwordless sudo is intentionally limited to the workstation container's own namespace and mounted project/home data.

## D14 — Security / exposure

- expose noVNC only to trusted networks unless another authenticated ingress is deliberately added;
- raw VNC binds only to loopback inside the container;
- only websockify/noVNC is published;
- no secrets, browser profiles, ChatGPT auth, Remote private keys, SSH private keys or GitHub tokens in Git;
- VNC and keyring passwords are supplied from Unraid-side secret files.

## D15 — Validation order is part of the architecture

Regression/deployment checkpoints remain ordered:

```text
source validation
  -> host preflight
  -> image builds
  -> direct bind migration/recreate
  -> desktop/noVNC healthy
  -> exact runtime mount/isolation verification
  -> native CE/Android Remote regression check
  -> Codex Web GPT configuration/model routing
  -> Agent Workspace / Computer Use
```

The target host has already passed the CE login/keyring, Android Remote and native remote-task gates. They should not be treated as unknowns anymore, but remain regression checks after major upstream changes.

## D16 — Docker Compose is the primary deployment definition

`compose.yaml` is the runtime source of truth for:

- image/build arguments;
- container name/restart policy;
- port publication;
- bind mounts;
- secret wiring;
- `shm_size`;
- environment variables;
- future devices/capabilities if explicitly required.

Unraid Compose Manager may operate the stack, but helper scripts must remain wrappers around the tracked Compose definition rather than creating a second deployment configuration.

## D17 — Desktop health does not require CE to be open

The container healthcheck verifies the desktop substrate:

- noVNC HTTP endpoint;
- X display;
- Openbox;
- x11vnc;
- websockify.

ChatGPT CE and Codex Web GPT are intentionally outside the health condition because either application may be closed and relaunched during recovery without making the workstation itself unhealthy.

## D18 — Project-bind migration is guarded and verifiable

`scripts/init-unraid.sh` must not manipulate the persistent-home nested-bind target while the workstation container is running.

The supported migration path is `scripts/migrate-project-bind.sh`. An existing installation should first `git pull --ff-only` so the current helper exists locally. The helper then requires a clean `main`, fast-forwards/re-execs if needed, runs static source validation plus non-mutating host preflight, builds the replacement image **before downtime**, and only then stops the stack, prepares the bind target, recreates, waits for health and runs `scripts/verify-runtime.sh`.

Runtime verification checks the exact home/project bind sources and destinations plus the intended container isolation boundary, not merely that some mount exists at the canonical destination.

Unexpected pre-bind data under the old persistent-home project target is preserved under a timestamped `ChatGPT.pre-*` backup instead of being silently hidden or deleted. Disposable test-only backups may be deleted after final verification and manual inspection.

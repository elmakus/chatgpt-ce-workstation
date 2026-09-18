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

## D19 — Merge Muse Code candidate before live validation

**Decision:** merge the source-ready Muse Code candidate from PR #1 into workstation `main` before the first live Unraid validation.

The earlier hold on merging before live validation is superseded by the user's explicit 2026-09-18 decision. The purpose is operational simplicity: the next workstation build should be runnable directly from `main`, and any installer/runtime defects discovered during live Muse validation will be corrected on normal follow-up branches/PRs.

This does not waive the live validation itself. Muse authentication persistence, `muse exec` headless behavior, model/effort controls, timeout/cancellation, sandbox behavior, and orchestrator worker integration remain unvalidated until tested on the live workstation.

## D20 — ChatGPT-owned delegated Muse workers behind a normalized harness — SUPERSEDED

**Status:** superseded on 2026-09-18 by D21 after the `muse-max` runtime audit established that internal worker orchestration belongs in `elmakus/codex_workflow`, not in generic `chatgpt_only` workflow semantics.

**Historical decision:** add an opt-in delegated-worker capability under the existing `chatgpt_only` policy. ChatGPT remains the formal Task Card executor/control plane; Muse Code is a bounded leaf worker used initially for `executor` and `tester` roles.

The workflow repository will define only generic delegated-worker semantics: ownership, wait/return behavior, bounded result expectations and authority boundaries. It will not embed Muse-specific CLI syntax.

The workstation repository will own a stable Muse adapter (working name: `muse-worker`) that:
- launches one Muse process for one assigned worker task;
- awaits process completion instead of requiring the main agent to poll;
- drains and stores raw Muse output outside the main context;
- parses the installed Muse machine-readable output;
- validates and emits one compact normalized final result;
- enforces timeout and process-tree cancellation.

For normal GREEN execution, the main ChatGPT agent consumes the normalized result, not the full Muse transcript. Raw logs are escalation/debug evidence only.

A tester receives the accepted task/review contract plus actual repository/worktree state, not the executor transcript. This makes review independently grounded and prevents executor context from being recopied through the orchestrator.

Muse-native nested fan-out remains disabled by default. Fan-out ownership stays with the ChatGPT orchestrator.

The initial rollout is opt-in so existing `chatgpt_only` behavior remains backward compatible while the Muse path is validated.

**Rationale:** current external harnesses converge on the same separation: a small CLI/subprocess runner localizes volatile backend contracts, the orchestrator awaits completion, structured results are schema-normalized, and full trajectories/logs remain separate from parent-facing context. See `research/muse-delegated-worker-orchestration-2026-09-18.md`.

**Rejected for the first implementation:**
- teaching the main agent to call raw `muse exec` flags directly;
- periodic polling as the standard completion mechanism;
- injecting the worker JSONL/transcript into the main context;
- interactive steering/MSP as a prerequisite;
- allowing Muse to create its own subagent tree by default.


## D21 — `muse-max` is a mixed-harness `codex_workflow` profile

**Decision:** define Muse subagents only through the existing `elmakus/codex_workflow` worker-role system. Do not add a generic delegated-worker runtime to Project Workflow and do not create a second Muse orchestration layer in `chatgpt-ce-workstation`.

The `muse-max` profile is the only profile changed by this work. `plus`, `luna-xhigh`, and `pro-x5` must preserve their current model allocations, lifecycle semantics, and internal Codex worker behavior.

Under `muse-max`:

- Main remains the user-selected Codex model and retains orchestration, architecture, scheduling, integration, acceptance, Project Workflow state, and user communication.
- `companion` runs as one persistent internal Codex worker on GPT-5.6 Luna XHigh.
- `micro_executor`, `default_executor`, `senior_executor`, `tester`, `investigator`, and `archivist` run through the native Muse Code harness using Muse Spark 1.3 Contributor with `max` reasoning.
- the existing worker TOMLs remain the canonical semantic role contracts; do not create parallel `muse_*.toml` role definitions.
- Muse-specific process behavior is supplied by a `muse-max` runtime adapter/overlay in `codex_workflow`, not by changing shared role semantics into provider-specific contracts.
- Muse workers are bounded leaf invocations. They do not create nested workers or communicate directly with sibling Muse workers.
- executor and tester are always separate invocations. Tester receives the accepted verification contract plus the resulting repository/worktree state, not the executor transcript.
- ordinary RED verification routes through Main to a fresh executor repair invocation and then a fresh tester recheck; Main makes a strategic decision only when findings cross scope, contract, ownership, architecture, security, migration, or authority boundaries.
- raw Muse event streams/stdout/stderr remain outside Main context. Main receives one compact normalized result plus bounded evidence/log references.
- the Muse runtime adapter must validate the active profile and per-role harness from `compute_profiles.py`; it must not independently hard-code a role/model allocation that can drift from profile authority.
- exact Muse CLI flags/event fields are bound from the installed workstation Muse build and live evidence rather than frozen from assumptions.

Project Workflow continues to own Task Card dependencies, `parallel_safe` decisions, write ownership and isolated lane/worktree authority. Independent Task Card lanes may run concurrently when Project Workflow planning declares them safe. Within a lane, executor → tester → optional repair → fresh tester remains ordered. Muse does not own project-level worktree creation or lane scheduling.

`chatgpt-ce-workstation` owns installation, persistence and runtime availability of the official Muse Code CLI and user authentication state. `codex_workflow` owns role routing, worker lifecycle, result normalization and Muse process control.

**Rationale:** the existing Project Workflow integration contract already assigns internal Codex worker routing/lifecycle to `codex_workflow`. The 2026-09-18 runtime audit found the existing `muse-max` seam structurally appropriate but the current `runtime/muse_worker.py` only a proof-of-concept and identified profile-isolation, output-normalization, cancellation and lifecycle gaps. See `research/MUSE_MAX_RUNTIME_AUDIT_2026-09-18.md`.

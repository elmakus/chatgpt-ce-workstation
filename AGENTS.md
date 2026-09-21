# AGENTS.md

This repository is the durable source of truth for the `chatgpt-ce-workstation` project.

## Product goal

Build a Docker-native, always-on ChatGPT Community Edition workstation for Unraid that is controlled primarily from ChatGPT on Android through Remote Control, with noVNC retained as setup/recovery access.

## Non-negotiable architecture

1. Docker on Unraid, not a VM.
2. ChatGPT Community Edition is the desktop host.
3. Use the Codex binary bundled with CE for v1. Do not add a second standalone Codex CLI unless a later requirement specifically needs terminal-launched Codex.
4. Enable these CE Linux features in v1:
   - `remote-mobile-control`
   - `agent-workspace`
   - `computer-use-linux`
   - `authored-message-visibility`
   - `automation-extensions`
   - `mcp-helper-reaper`
   - `node-repl-reaper`
   - `project-group-last-updated-sort`
   - `directory-only-working-tree-watch`
5. Use s6-overlay as PID 1 / supervisor. Do not redesign the container around systemd without an explicit architecture change.
6. Use Xvfb + Openbox + Tint2 + x11vnc + noVNC for the headless recovery desktop. Openbox is the desktop lifetime anchor; quitting CE must not tear down noVNC.
7. Build/install CE from the native Debian package path with `PACKAGE_WITH_UPDATER=0`. The current Unraid Docker boundary cannot initialize CE/Chromium's inner sandbox reliably, so CE and the workstation Chrome launcher intentionally use `--no-sandbox` **inside this unprivileged container**. Do not replace that accepted compromise with `privileged: true`, `SYS_ADMIN`, a host-root bind, or equivalent host-control access.
8. Install Codex Web GPT from the workstation fork `elmakus/codex-chatgpt-web`. The fork preserves the normal browser-backed path and contains optional native-upstream routing support for future use. The workstation v1 does not configure Codex-LB as part of the base runtime. Finish Codex Web GPT setup only after the native CE/Remote path is healthy.
9. `compose.yaml` is the primary deployment/runtime definition for Unraid. The Compose Manager GUI may operate it, but the tracked YAML remains authoritative.
10. Do not mount `/var/run/docker.sock`, `/`, raw host devices, or add `privileged`/`SYS_ADMIN` without an explicit architecture change.
11. The `codex` user has passwordless sudo **inside this dedicated container** so the agent can unblock development work without waiting for manual package installation.
12. Codex itself runs in no-prompt/full-access mode inside this dedicated container: system defaults use `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`; `/etc/codex/requirements.toml` constrains the allowed policy set while retaining the required `read-only` compatibility profile. Docker remains the external isolation boundary.
13. Use `directory-only-working-tree-watch` as the repository-watch strategy. Do not enable `shallow-repository-watches` at the same time.

## Storage contract

Persistent host data:

- `/mnt/user/appdata/chatgpt-ce-workstation/home` -> `/home/codex`
- `/mnt/user/projects` -> `/home/codex/Documents/ChatGPT`

`/home/codex/Documents/ChatGPT` is the single canonical project root. It is CE's native Create Project location and the container working directory. Do not add a second `/workspace` alias, symlink, or mount.

System/application files such as `/usr`, `/bin`, `/lib`, and `/opt` belong to the Docker image and must ultimately be changed through repository source plus image rebuild.

Project-local binaries, datasets, build outputs and artifacts should normally stay inside the relevant directory under `/home/codex/Documents/ChatGPT` and be controlled with that project's `.gitignore`. Do not introduce `/mnt/user/project-data` unless there is a concrete cross-project or storage-tier reason.

## noVNC recovery desktop contract

The recovery desktop must remain usable after either GUI application is closed.

Expected behavior:

- ChatGPT CE starts automatically;
- Codex Web GPT starts automatically;
- Tint2 provides launchers for CE, Codex Web GPT and a terminal;
- the Openbox right-click menu provides the same recovery launch paths;
- `Quit` in CE closes CE only;
- CE can be started again with `/usr/local/bin/chatgpt-ce` or the GUI launcher;
- critical Openbox/x11vnc/websockify failure restarts the desktop service cleanly through s6;
- intentionally quitting CE must not make the container unhealthy.

Do not make CE itself the s6 or Docker health anchor.

## Persistence rule

Any user state required after container recreation must live below `/home/codex` or another explicitly documented host bind mount. Never rely on the container writable layer for credentials, settings, project data or irreplaceable runtime state.

Persistent user-authored state must be preserved. Workstation-managed generated files, such as helper desktop entries under `~/.local/share/applications`, may be refreshed from immutable image source on boot so rebuilds do not leave stale launchers behind.

## Project-bind migration rule

The direct project-bind migration is host-sensitive. Use the tracked one-shot workflow instead of manually improvising the steps:

```bash
bash scripts/migrate-project-bind.sh
```

The migration must:

1. run only from a clean `main` checkout;
2. fast-forward `main` before changing the host;
3. run source validation and non-mutating host preflight;
4. build the replacement image **before** stopping the current workstation;
5. stop the container before `scripts/init-unraid.sh` touches the nested bind target;
6. preserve unexpected old `Documents/ChatGPT` content as `ChatGPT.pre-*` rather than deleting it;
7. recreate, wait for health, and run `scripts/verify-runtime.sh`.

Disposable test repositories/backups may be removed after the final runtime verification confirms that nothing useful is inside them. Do not make automatic deletion part of the migration.

## Tool installation and self-maintenance rule

The agent may install a missing tool temporarily in the running workstation when that is the fastest safe way to continue, including commands such as:

```bash
sudo apt-get update
sudo apt-get install -y <package>
```

Temporary installation is only an experiment/unblocker. If the tool is confirmed useful, make the durable change before considering workstation infrastructure work complete:

- system package/library/tool -> update `Dockerfile`;
- deployment/runtime setting, mount, port, device, environment or secret wiring -> update `compose.yaml`;
- container service/startup behavior -> update `rootfs/` / s6 definitions or `scripts/container/`;
- project-only dependency -> prefer that project's dependency manifest/environment instead of bloating the global workstation image.

Then run the relevant validation/build/runtime checks and commit/push the durable change when repository policy and credentials permit.

Do not treat a live-container `apt install`, manual file copy under `/usr`/`/opt`, or other writable-layer mutation as a durable fix.

Read `docs/TOOLCHAIN.md` before broad toolchain changes. `openai/codex-universal` is the reference for development-environment breadth; the goal is practical category parity rather than exact package parity.

## Full-access Codex boundary

The workstation intentionally disables Codex's inner approval/sandbox friction because the whole environment is already a dedicated development container. The source of truth is:

```text
/etc/codex/config.toml
/etc/codex/requirements.toml
```

Expected effective values:

```toml
approval_policy = "never"
sandbox_mode = "danger-full-access"
```

Codex may execute shell commands and modify any path visible inside the container without per-command approval prompts. It still must not gain implicit control of the Unraid host.

## Passwordless sudo boundary

Passwordless sudo applies only inside `chatgpt-ce-workstation`. It does not authorize host-Unraid administration.

The agent may modify this repository's Dockerfile/Compose/rootfs/scripts, commit/push those changes, and report that a host-side rebuild/recreate is required. That is preferred to granting the container general Docker-host control.

## Update rule

Application/system dependency changes belong in the Dockerfile/rootfs source, followed by an image rebuild. Runtime/deployment changes belong in `compose.yaml`.

Container recreation during an update is expected. Persistent bind mounts must make it safe.

Preferred tracked helper:

```bash
bash scripts/update.sh
```

`update.sh` refreshes remote-source build layers, rebuilds, recreates, waits for desktop health, and runs runtime verification. `scripts/build.sh` and `scripts/run.sh` remain thin wrappers around Compose and must not become a second deployment definition.

## Deployment / validation sequence

Do not debug all layers simultaneously. Current order is:

1. pull/validate current `main`;
2. complete and verify the direct project-bind migration;
3. verify noVNC panel/menu and CE relaunch after Quit;
4. finish Codex Web GPT login/model/Full Harness configuration and audit that integration;
5. validate routed models from Android Remote;
6. validate Agent Workspace / Computer Use;
7. keep Muse Code work on its separate branch until its own implementation is ready.

Native CE login, keyring persistence, Android Remote, and native Codex tasks were already proven on the target host; do not regress those while changing later layers.

## Change discipline

- Read `README.md`, `docs/DECISIONS.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/TOOLCHAIN.md`, and `docs/CE_FEATURES.md` before changing architecture.
- Preserve existing user data and upgrade paths.
- Prefer reproducible image changes over live-container mutations.
- Never commit secrets, ChatGPT browser state, OAuth material, SSH private keys, Remote Control private keys, VNC/keyring passwords, or GitHub tokens.
- Keep noVNC limited to trusted networks unless a separately authenticated ingress is explicitly designed.
- Avoid automatic force-pushes and destructive Git operations.
- Run `scripts/validate-source.sh` before workstation builds and `scripts/verify-runtime.sh` after a rebuild/recreate when the host is available.

## Git workflow

For changes to this repository:

- inspect `git status` before editing;
- work from the intended branch;
- run available syntax/source/runtime checks;
- make cohesive commits;
- push the accepted current branch to `origin` when credentials and repository policy permit;
- never force-push without explicit approval.

Do not assume that ordinary filesystem edits are automatically synchronized to GitHub. Git add/commit/push is always a separate operation.

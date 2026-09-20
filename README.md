# ChatGPT CE Workstation for Unraid

Docker-native, always-on ChatGPT Community Edition / Codex workstation for Unraid, controlled primarily through **ChatGPT Remote Control on Android** with a lightweight noVNC recovery desktop.

## Current status

Validated on the target Unraid host:

- ChatGPT CE builds and starts;
- CE login and GNOME keyring state persist;
- Android Remote Control pairs and executes native Codex tasks;
- Codex runs with `approval_policy = "never"` and `sandbox_mode = "danger-full-access"` inside the Docker boundary;
- noVNC works for setup/recovery.

Current repository state:

- canonical project path: `/home/codex/Documents/ChatGPT`;
- host project share: `/mnt/user/projects`;
- no active `/workspace` project mount in Compose;
- ChatGPT CE and Codex Web GPT start automatically with the desktop session;
- noVNC uses Openbox + Tint2 so GUI apps can be Quit and relaunched without restarting the container;
- the direct project-bind migration still needs to be applied and verified on the live Unraid host after pulling current `main`.

## Architecture

```text
ChatGPT Android
      |
      | Remote Control
      v
+-----------------------------------------------------------+
| Unraid                                                    |
|                                                           |
| Compose Manager -> compose.yaml                           |
|                    |                                      |
|                    v                                      |
| chatgpt-ce-workstation                                    |
|                                                           |
| s6-overlay                                                |
|  `- desktop service                                      |
|      |- Xvfb                                             |
|      |- Openbox + Tint2                                  |
|      |- x11vnc + websockify/noVNC                        |
|      |- ChatGPT Community Edition                        |
|      `- Codex Web GPT                                    |
|                                                           |
| Google Chrome Stable                                      |
| Git / gh / SSH / Node / Python / Rust / Go / Java        |
| build tools / media tools / diagnostics                   |
|                                                           |
| /home/codex                      -> appdata persistent home |
| /home/codex/Documents/ChatGPT    -> /mnt/user/projects     |
+-----------------------------------------------------------+
```

## Locked-in design decisions

- **Docker, not a VM.**
- **Docker Compose is authoritative.** Unraid Compose Manager may operate the stack, but `compose.yaml` defines runtime state.
- **ChatGPT Community Edition** is the desktop host and provides the bundled Codex used by Android Remote.
- Use **s6-overlay**, not systemd, as PID 1 / service supervisor.
- Use **Xvfb + Openbox + Tint2 + x11vnc + noVNC** as the recovery desktop.
- Use **official Google Chrome Stable** for browser-dependent workflows.
- Build/install CE as a native Debian package with `PACKAGE_WITH_UPDATER=0`; updates happen by rebuilding the image.
- Install **Codex Web GPT** from `elmakus/codex-chatgpt-web`; user/browser state remains under persistent `/home/codex`.
- Pin Agent Workspace to a known version (`0.3.2` by default).
- Persistent user state: `/home/codex` -> `/mnt/user/appdata/chatgpt-ce-workstation/home`.
- Projects: `/home/codex/Documents/ChatGPT` -> `/mnt/user/projects`.
- The workstation repo itself should live at `/mnt/user/projects/chatgpt-ce-workstation`.
- The `codex` user has passwordless sudo **inside this dedicated container**.
- Codex runs full-access/no-approval; Docker is the external isolation boundary.
- Do not mount `/var/run/docker.sock`, the Unraid host root, or use `privileged`/`SYS_ADMIN` as shortcuts.
- CE and the workstation Chrome launcher intentionally use `--no-sandbox` because the accepted unprivileged Unraid Docker boundary cannot initialize their inner Chromium/Electron sandbox reliably. Do not compensate by weakening the container boundary.
- Useful runtime tool installs must be persisted back to `Dockerfile`, `compose.yaml`, `rootfs/`, scripts, or the relevant project manifest.

Enabled CE Linux features are tracked in `config/ce-features.json`; rationale is documented in `docs/CE_FEATURES.md`.

## Persistent vs replaceable data

Replaceable image-owned state includes system packages, CE, Chrome, Codex Web GPT, toolchains and files under `/opt` and `/usr`.

Persistent host-owned state:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home
  -> /home/codex

/mnt/user/projects
  -> /home/codex/Documents/ChatGPT
```

Rebuilding or recreating the container must not delete CE/Codex settings, logins, keyring data, Remote Control keys, SSH/GitHub state, Codex Web GPT profile data, repositories, unpushed commits or project artifacts.

## noVNC desktop behavior

At desktop-session start:

```text
Xvfb starts
Openbox starts
Tint2 panel starts
x11vnc + websockify/noVNC start
Codex Web GPT starts
ChatGPT CE starts
```

The Tint2 panel provides launchers for ChatGPT CE, Codex Web GPT and a terminal. The Openbox right-click menu provides the same recovery paths.

If ChatGPT CE is closed with **Quit**, the noVNC desktop remains alive. Relaunch CE from the panel, the Openbox menu, or `/usr/local/bin/chatgpt-ce`.

The published noVNC endpoint is intentionally **passwordless at the VNC layer**. Network reachability is therefore the access-control boundary: expose it only on a trusted network, or place a separately authenticated ingress in front of it before any broader/untrusted exposure. Raw VNC remains container-loopback-only and is never published directly.

Openbox/x11vnc/websockify are treated as critical desktop-substrate processes. If one exits, the s6 longrun is restarted cleanly. CE itself is deliberately **not** part of Docker health, so intentionally quitting CE does not make the workstation unhealthy.

## Fresh deployment

```bash
cd /mnt/user/projects
git clone git@github.com:elmakus/chatgpt-ce-workstation.git
cd chatgpt-ce-workstation
bash scripts/init-unraid.sh
bash scripts/build.sh
bash scripts/run.sh
```

Then open noVNC on the host port configured in Compose / `.env` (default `6080`). `scripts/run.sh` prints the published binding. The desktop should open without a VNC/noVNC password prompt.

## Existing installation: migrate to the canonical project bind

Run from the Unraid root shell. Pull first because older local checkouts may not yet contain the current migration helper:

```bash
cd /mnt/user/projects/chatgpt-ce-workstation
git pull --ff-only
bash scripts/migrate-project-bind.sh
```

The one-shot migration is intentionally defensive. It:

1. requires a clean `main` checkout;
2. fast-forwards `main` again with `git pull --ff-only` and re-execs itself if that pull advanced the source;
3. runs `scripts/validate-source.sh`;
4. runs non-mutating `scripts/preflight-host.sh` to verify Compose, persistent paths and keyring migration state before downtime;
5. asks for confirmation;
6. builds the replacement image **before** stopping the current workstation;
7. stops the stack;
8. runs `scripts/init-unraid.sh` to normalize the nested bind target;
9. preserves unexpected old `Documents/ChatGPT` content as `ChatGPT.pre-*` rather than deleting it;
10. recreates the workstation;
11. waits for desktop health;
12. runs `scripts/verify-runtime.sh`.

`scripts/init-unraid.sh` refuses to manipulate the nested bind target while the workstation container is running.

A successful verification ends with:

```text
WORKSTATION_RUNTIME_GREEN
```

The verifier checks:

- the **exact** persistent-home and project bind sources/destinations;
- absence of `/workspace`, Docker socket and host-root mounts;
- unprivileged/no-`SYS_ADMIN` container boundary;
- restart policy;
- canonical working directory and project write access;
- passwordless noVNC and keyring runtime state;
- desktop launchers and Tint2 panel;
- noVNC desktop health.

Old `ChatGPT.pre-*` backups are reported but are not a failure. They may contain only disposable test repositories; delete them after confirming nothing useful is inside.

## Source validation

```bash
bash scripts/validate-source.sh
```

A successful result ends with:

```text
SOURCE_VALIDATION_GREEN
```

It validates shell syntax, Compose parsing, canonical path rules, container isolation invariants, Codex policy, CE feature selection, recovery desktop/s6 wiring, and secret-ignore hygiene.

## Updating upstream software

Use:

```bash
bash scripts/update.sh
```

The helper changes `UPSTREAM_REFRESH`, rebuilds, recreates, waits for desktop health and runs runtime verification. This prevents remote-source layers from being satisfied only from stale Docker cache.

Persistent bind mounts remain attached to the replacement container.

## Agent self-maintenance model

The agent may temporarily install a missing tool inside the container, for example:

```bash
sudo apt-get update
sudo apt-get install -y protobuf-compiler
```

If the package is useful, persist it in the source of truth:

```text
system package/tool     -> Dockerfile
mount/port/env/device   -> compose.yaml
service/startup         -> rootfs/ / scripts/container/
project-only dependency -> project manifest/environment
```

Then run checks and commit/push the accepted source change. Host-side image rebuild may happen afterward.

## First-login / recovery flow

For a new persistent home:

1. Start the stack and open noVNC.
2. Sign in to ChatGPT CE.
3. Restart/recreate once and verify login persistence.
4. Pair Android Remote Control.
5. Validate a normal native Codex task from Android.
6. Configure Codex Web GPT in noVNC and verify its routed models.
7. Test Agent Workspace / browser automation only after the native path is healthy.

The target workstation has already passed the CE login/keyring and Android Remote gates. They remain regression checks after major CE/upstream changes.

## Repository map

```text
.
|- README.md
|- AGENTS.md
|- Dockerfile
|- compose.yaml
|- .env.example
|- config/
|  `- ce-features.json
|- defaults/
|  `- AGENTS.md
|- docs/
|  |- CE_FEATURES.md
|  |- DECISIONS.md
|  |- IMPLEMENTATION_PLAN.md
|  `- TOOLCHAIN.md
|- rootfs/
|  |- etc/cont-init.d/10-workstation-init
|  |- etc/s6-overlay/s6-rc.d/desktop/...
|  |- etc/xdg/openbox/menu.xml
|  |- etc/xdg/tint2/tint2rc
|  |- usr/local/bin/chatgpt-ce
|  |- usr/local/bin/workstation-healthcheck
|  `- usr/local/share/applications/...
`- scripts/
   |- build/install-codex-web-gpt.sh
   |- container/...
   |- build.sh
   |- init-unraid.sh
   |- migrate-project-bind.sh
   |- preflight-host.sh
   |- run.sh
   |- update.sh
   |- validate-source.sh
   |- verify-runtime.sh
   `- wait-healthy.sh
```

See `docs/IMPLEMENTATION_PLAN.md` for the current deployment sequence and `docs/DECISIONS.md` for architecture rationale.

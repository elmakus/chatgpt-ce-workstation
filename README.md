# ChatGPT CE Workstation for Unraid

A Docker-native, always-on ChatGPT Community Edition / Codex workstation for Unraid, designed to be controlled primarily through **ChatGPT Remote Control on Android**.

> Status: **PLANNING / BOOTSTRAP SCAFFOLD**. The architecture and decisions are recorded, but the image has not yet been validated end-to-end on the target Unraid host. Follow `docs/IMPLEMENTATION_PLAN.md` in order and do not skip the Remote Control checkpoint.

## Goal

Run a full Linux development workstation in one Unraid Docker container without reserving CPU/RAM for a VM.

```text
ChatGPT Android
      |
      | Remote Control
      v
+------------------------------------------------------+
| Unraid                                               |
|                                                      |
| chatgpt-ce-workstation                               |
|                                                      |
| s6-overlay                                           |
|  |- Xvfb + Openbox + noVNC                          |
|  |- ChatGPT Community Edition                       |
|  |    `- bundled official Codex                     |
|  `- Codex Web GPT / codex-chatgpt-web               |
|                                                      |
| Git / gh / SSH / Node / Python / Rust / Go / Java   |
| build tools / media tools / diagnostics              |
|                                                      |
| /home/codex  -> /mnt/user/appdata/.../home          |
| /workspace   -> /mnt/user/projects                  |
+------------------------------------------------------+
```

## Locked-in design decisions

- **Docker, not a VM.** No permanently reserved guest RAM/CPU and no full guest OS.
- **ChatGPT Community Edition** is the desktop host.
- Use CE's **bundled Codex**. Do **not** install a second standalone Codex CLI in v1; Android Remote is the primary interface and CE Remote explicitly uses the bundled Codex runtime.
- Enable CE Linux features:
  - `remote-mobile-control`
  - `agent-workspace`
  - `computer-use-linux`
- Use **s6-overlay**, not systemd, as container PID 1 / process supervisor.
- Use **Xvfb + Openbox + x11vnc + noVNC** for the headless desktop and first-time setup.
- Build/install CE as a **native Debian package**, not AppImage.
- Disable CE's native updater (`PACKAGE_WITH_UPDATER=0`). Updates happen by rebuilding the Docker image and recreating the container.
- Install **codex-chatgpt-web** in the image. Its user/browser state remains under persistent `/home/codex`.
- Ignore Codex-LB for v1. Do not mix its routing into the first deployment.
- Persistent user state: `/home/codex` -> Unraid `appdata`.
- Projects: `/workspace` -> `/mnt/user/projects`.
- Large project-local files remain inside each project directory and are excluded with that project's `.gitignore`. Do not create a separate `project-data` share unless a later use case actually requires shared/huge data on another pool.
- Do **not** mount `/var/run/docker.sock` in v1.
- Do **not** run Electron as root and do **not** default to `--no-sandbox`.
- noVNC is a setup/recovery surface, not the normal daily interface after Android Remote is paired.

## Persistent vs replaceable data

The Docker image owns replaceable system/application files:

```text
/usr
/bin
/lib
/opt/codex-desktop
/opt/codex-web-gpt
system packages and developer toolchains
```

Unraid owns persistent state:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home
  -> /home/codex

/mnt/user/projects
  -> /workspace
```

Rebuilding the image or recreating the container must not delete logins, CE/Codex settings, SSH/GitHub state, Remote Control keys, codex-chatgpt-web profile data, repositories, unpushed commits, ignored binaries, or project artifacts.

## First-login flow

1. Start the container.
2. Open noVNC in a browser: `http://UNRAID_IP:6080/vnc.html`.
3. Sign in to ChatGPT Community Edition.
4. Restart/recreate the container once and verify that the ChatGPT login persists.
5. Configure CE Remote Control and pair the Android ChatGPT app.
6. Validate a normal native Codex task over Remote before adding another moving part.
7. Open Codex Web GPT through noVNC, sign in to its embedded ChatGPT browser, run its browser smoke test, install routed models and configure Full Harness / `Codex Native2`.
8. Test a routed ChatGPT Web model from Android Remote against a disposable repository.
9. Only then enable/test Agent Workspace and broader Computer Use workflows.

## Main risk

The main uncertainty is **Linux Remote Control**, not Docker/noVNC. `remote-mobile-control` is an experimental CE adaptation. OpenAI may still reject or change Linux host enrollment server-side. Treat successful Android pairing and a real remote Codex turn as the first hard gate before investing time in optional integrations.

## Repository map

```text
.
|- README.md
|- AGENTS.md
|- Dockerfile
|- config/
|  `- ce-features.json
|- defaults/
|  `- AGENTS.md
|- docs/
|  |- DECISIONS.md
|  `- IMPLEMENTATION_PLAN.md
|- rootfs/
|  |- etc/cont-init.d/10-workstation-init
|  |- etc/s6-overlay/s6-rc.d/...
|  `- usr/local/share/applications/codex-web-gpt.desktop
`- scripts/
   |- build.sh
   |- init-unraid.sh
   |- run.sh
   `- update.sh
```

## Tomorrow

Start at `docs/IMPLEMENTATION_PLAN.md`. Build and validate one layer at a time. Do not jump directly to `codex-chatgpt-web` until native CE + persistence + Android Remote are proven.

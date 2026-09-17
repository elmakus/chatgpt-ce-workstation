# Implementation / deployment runbook

Target: Unraid host, Docker-native ChatGPT Community Edition workstation, controlled primarily through ChatGPT Android Remote.

`compose.yaml` is the runtime source of truth. Helper scripts wrap Compose and validation; they do not define a second independent deployment configuration.

## Current checkpoint

Validated on the target workstation:

```text
[GREEN] CE builds and starts
[GREEN] noVNC works
[GREEN] GNOME keyring/login persistence works
[GREEN] Android Remote pairs and runs native Codex tasks
[GREEN] Codex runs full-access/no-approval inside the container boundary
[GREEN] workstation source targets /home/codex/Documents/ChatGPT directly
[GREEN] Codex Web GPT fork/release is wired into the image source
[GREEN] noVNC recovery desktop source includes Openbox + Tint2 + relaunchers
[GREEN] source/runtime validation scripts cover the intended Docker boundary
```

Still requiring live-host execution or configuration:

```text
[PENDING] pull current main on Unraid
[PENDING] run direct project-bind migration/rebuild
[PENDING] verify exact live mounts and no /workspace path/mount
[PENDING] verify new noVNC panel/relaunch behavior after rebuild
[PENDING] finish and audit Codex Web GPT browser/model configuration
[PENDING] Agent Workspace / Computer Use smoke tests
```

Muse Code work remains separate and must not be mixed into this bind migration.

---

## Phase 1 — One-shot project-bind migration

Canonical mapping:

```text
/mnt/user/projects
  -> /home/codex/Documents/ChatGPT
```

There should be no active `/workspace` mount or compatibility symlink after migration.

From an Unraid root shell, pull first because an older local checkout may not yet contain the current migration helper:

```bash
cd /mnt/user/projects/chatgpt-ce-workstation
git pull --ff-only
bash scripts/migrate-project-bind.sh
```

The migration script is intentionally defensive. Before any downtime it:

1. requires a Git working tree;
2. requires the checked-out branch to be `main`;
3. refuses tracked or untracked local changes (ignored `.env` is unaffected);
4. runs `git pull --ff-only` again and re-execs itself if that pull advanced the source;
5. runs `scripts/validate-source.sh`;
6. runs non-mutating `scripts/preflight-host.sh`;
7. asks for confirmation;
8. builds the replacement image while the current workstation is still running.

Only after the replacement image builds successfully does it:

```text
docker compose down
  -> scripts/init-unraid.sh
  -> scripts/run.sh --recreate
  -> scripts/wait-healthy.sh
  -> scripts/verify-runtime.sh
```

`scripts/init-unraid.sh` refuses to manipulate the nested bind target while the workstation container is running.

If unexpected data exists at the previous persistent-home `Documents/ChatGPT` target, it is renamed to a timestamped `ChatGPT.pre-*` backup instead of being deleted.

These backups may contain only disposable test repositories. They are reported by the verifier and may be deleted after confirming that nothing useful is inside them. Automatic deletion is intentionally not part of migration.

Expected final marker:

```text
WORKSTATION_RUNTIME_GREEN
```

---

## Phase 2 — Source validation contract

`migrate-project-bind.sh` runs this automatically, but it can also be run independently:

```bash
bash scripts/validate-source.sh
```

Expected marker:

```text
SOURCE_VALIDATION_GREEN
```

Current checks include:

- Bash syntax for tracked workstation scripts/rootfs shell entrypoints;
- `docker compose config`;
- canonical `/home/codex/Documents/ChatGPT` working directory and project bind;
- absence of active `/workspace` runtime wiring;
- expected persistent-home/project mount declarations;
- restart policy, secret wiring and desktop healthcheck;
- no `privileged`, `SYS_ADMIN` or Docker-socket wiring in Compose;
- Codex `never` / `danger-full-access` policy and requirements;
- required CE feature set and exclusion of `shallow-repository-watches`;
- `PACKAGE_WITH_UPDATER=0`;
- noVNC/Openbox/Tint2 launchers and s6 desktop supervision wiring;
- `.env` and secret exclusion from Git/Docker build context.

Source validation does not prove live Docker mount state; that is the role of runtime verification after the rebuild.

---

## Phase 3 — Host preflight before downtime

`migrate-project-bind.sh` runs:

```bash
bash scripts/preflight-host.sh
```

Expected marker:

```text
HOST_PREFLIGHT_GREEN
```

It is deliberately non-mutating. It checks:

- root execution on Unraid;
- Docker/Compose availability and config parsing;
- persistent-home and project-root existence;
- non-empty noVNC secret;
- non-empty keyring secret;
- current container presence/running state;
- current underlying `Documents/ChatGPT` target shape (legacy symlink, empty directory, non-empty directory, etc.).

A failure here occurs before the current workstation is stopped.

---

## Phase 4 — Runtime verification after rebuild

After the recreated workstation becomes healthy:

```bash
bash scripts/verify-runtime.sh
```

Expected marker:

```text
WORKSTATION_RUNTIME_GREEN
```

The verifier checks the actual running container rather than only source text:

- container exists, runs and is healthy;
- restart policy is `unless-stopped`;
- `/home/codex` is a bind from the expected appdata source;
- `/home/codex/Documents/ChatGPT` is a bind from the expected project source;
- no `/workspace` mount;
- no Docker socket mount;
- no host-root bind;
- container is not privileged and lacks `SYS_ADMIN`;
- in-container `pwd` is the canonical project root;
- `/workspace` and Docker socket are absent inside the container;
- runtime keyring secret and generated VNC password file are readable by `codex`;
- CE, Codex Web GPT, Openbox, Tint2, xterm, Chrome and healthcheck launchers are present;
- Tint2 is actually running;
- the project root is writable;
- the desktop substrate healthcheck passes;
- persistent global AGENTS has no stale `/workspace` text;
- old `ChatGPT.pre-*` directories are reported for later manual cleanup.

---

## Phase 5 — Verify noVNC recovery desktop

Open noVNC on the configured host port (default `6080`).

Expected desktop components:

```text
Xvfb
Openbox
Tint2 panel
x11vnc
websockify/noVNC
ChatGPT CE
Codex Web GPT
```

Manual smoke:

1. Confirm CE and Codex Web GPT both start automatically.
2. Confirm the Tint2 panel is visible.
3. Quit ChatGPT CE from the application.
4. Confirm noVNC/Openbox/Tint2 remain alive.
5. Relaunch CE from the panel.
6. Quit CE again and relaunch from the Openbox right-click menu.
7. Confirm terminal launcher works.

CE intentionally is not part of Docker health. Critical Openbox/x11vnc/websockify exits end the desktop longrun so s6 restarts the desktop session as one clean unit.

---

## Phase 6 — Regression-check native CE / Android Remote

These gates were already proven on the target host, but perform a short regression check after the bind migration because the container/image changed:

```text
[ ] CE is still signed in
[ ] keyring does not prompt unexpectedly
[ ] Android still sees the Remote host
[ ] a native Codex task can read/write in a disposable project
[ ] created/edited files appear physically under /mnt/user/projects
```

Disposable test repositories used only for this smoke may be deleted afterward.

Do not debug Codex Web GPT if this native path regresses; fix the base workstation layer first.

---

## Phase 7 — Codex Web GPT configuration and audit

Only after the direct bind migration and native regression checks are green.

The image already installs the launcher from:

```text
elmakus/codex-chatgpt-web
```

The application starts automatically and can be relaunched from noVNC.

Next work for this phase is intentionally separate from the workstation-baseline audit:

1. audit the current fork and release against upstream behavior;
2. verify persistent profile/config locations;
3. complete browser login/smoke flow;
4. install/verify routed model rows;
5. verify Full Harness / automation integration;
6. verify the native-upstream/Codex-LB extension remains opt-in and does not alter browser-backed behavior when unset;
7. test a routed model from Android Remote in a disposable repo.

Do not mix Muse implementation into this phase.

---

## Phase 8 — Agent Workspace and Computer Use

After native CE and Codex Web GPT are stable:

- run Agent Workspace smoke/doctor using the actual installed version;
- test one disposable hidden workspace first;
- inspect Computer Use doctor output for the current CE build;
- verify X11/Openbox helpers (`xdotool`, `wmctrl`, etc.) against a harmless workflow;
- enable broader Any App behavior only after the baseline doctor result is understood.

Do not guess stale CLI syntax; inspect the installed commands first.

---

## Updates after successful migration

Preferred update path:

```bash
bash scripts/update.sh
```

`update.sh` supplies a fresh `UPSTREAM_REFRESH`, builds the image, recreates the workstation, waits for desktop health and runs runtime verification.

A build failure occurs before recreation, so the existing running container is not replaced by a failed image build.

Persistent `/home/codex` and `/home/codex/Documents/ChatGPT` binds remain the storage contract across updates.

---

## Rollback / data principle

Do not treat persistent mounts as a backup strategy.

Before major upstream changes, keep normal backups/snapshots of:

```text
/mnt/user/appdata/chatgpt-ce-workstation/home
/mnt/user/projects
```

Git remotes protect committed project source but do not protect ignored/untracked local datasets, generated artifacts, credentials or application profile data.

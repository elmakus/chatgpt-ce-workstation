#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "OK: $*"
}

echo '=== shell syntax ==='
mapfile -t shell_files < <(
  {
    find scripts -type f -name '*.sh' -print
    find rootfs -type f \( -name '*.sh' -o -path '*/usr/local/bin/chatgpt-ce' -o -path '*/usr/local/bin/muse' -o -path '*/usr/local/bin/workstation-healthcheck' \) -print
    find rootfs/etc/cont-init.d -type f -print 2>/dev/null || true
    find rootfs/etc/s6-overlay/s6-rc.d -type f -name run -print 2>/dev/null || true
  } | sort -u
)
for file in "${shell_files[@]}"; do
  bash -n "$file" || fail "shell syntax: $file"
done
pass "bash -n (${#shell_files[@]} files)"

echo
echo '=== managed global AGENTS reconciliation ==='
[[ -s scripts/container/reconcile-global-agents.py ]] || fail 'managed AGENTS reconciliation helper missing'
[[ -s defaults/AGENTS.legacy-pre-managed.md ]] || fail 'current known legacy AGENTS reference missing'
[[ -s defaults/AGENTS.legacy-workspace.md ]] || fail 'historical /workspace AGENTS reference missing'
grep -F 'reconcile-global-agents.py' rootfs/etc/cont-init.d/10-workstation-init >/dev/null \
  || fail 'container init does not reconcile managed global AGENTS'
grep -F 'COPY defaults/ /opt/workstation/defaults/' Dockerfile >/dev/null \
  || fail 'Dockerfile does not install managed AGENTS payload and exact legacy references'
grep -F 'reconcile-global-agents.py' scripts/verify-runtime.sh >/dev/null \
  || fail 'runtime verification does not validate managed global AGENTS'
python3 scripts/test-managed-global-agents.py || fail 'managed global AGENTS fixture tests'
pass 'managed global AGENTS reconciliation fixtures and wiring'

echo
echo '=== Codex marketplace updater ==='
python3 -m py_compile \
  scripts/container/codex_marketplace_updater.py \
  scripts/test-codex-marketplace-updater.py \
  || fail 'Codex marketplace updater Python compile check'
python3 scripts/test-codex-marketplace-updater.py \
  || fail 'Codex marketplace updater deterministic tests'
grep -F '"/opt/codex-desktop/resources/codex"' scripts/container/codex_marketplace_updater.py >/dev/null \
  || fail 'Codex marketplace updater does not target CE-bundled Codex'
grep -F '"plugin",' scripts/container/codex_marketplace_updater.py >/dev/null \
  || fail 'Codex marketplace updater command wiring missing plugin subcommand'
grep -F '"marketplace",' scripts/container/codex_marketplace_updater.py >/dev/null \
  || fail 'Codex marketplace updater command wiring missing marketplace subcommand'
grep -F '"upgrade",' scripts/container/codex_marketplace_updater.py >/dev/null \
  || fail 'Codex marketplace updater command wiring missing upgrade subcommand'
grep -F '"--json",' scripts/container/codex_marketplace_updater.py >/dev/null \
  || fail 'Codex marketplace updater command wiring missing JSON mode'

updater_service_root='rootfs/etc/s6-overlay/s6-rc.d/codex-marketplace-updater'
updater_bundle_entry='rootfs/etc/s6-overlay/user-bundles.d/user/contents.d/codex-marketplace-updater'
[[ -s "$updater_service_root/run" ]] || fail 'Codex marketplace updater s6 run script missing'
grep -Fx 'longrun' "$updater_service_root/type" >/dev/null \
  || fail 'Codex marketplace updater s6 service is not longrun'
[[ -f "$updater_bundle_entry" ]] \
  || fail 'Codex marketplace updater is not registered in the user bundle'
bash -n "$updater_service_root/run" \
  || fail 'Codex marketplace updater s6 run script syntax'
grep -F 's6-setuidgid codex env' "$updater_service_root/run" >/dev/null \
  || fail 'Codex marketplace updater does not drop privileges to codex'
grep -F 'HOME=/home/codex' "$updater_service_root/run" >/dev/null \
  || fail 'Codex marketplace updater does not use the persistent codex home'
grep -F 'python3 /opt/workstation/bin/codex_marketplace_updater.py' "$updater_service_root/run" >/dev/null \
  || fail 'Codex marketplace updater s6 service does not launch the repository-owned core'
grep -F '/etc/s6-overlay/s6-rc.d/codex-marketplace-updater/run' Dockerfile >/dev/null \
  || fail 'Dockerfile does not make the Codex marketplace updater s6 run script executable'
grep -F 'COPY scripts/container/ /opt/workstation/bin/' Dockerfile >/dev/null \
  || fail 'Dockerfile does not install the repository-owned updater core'
if grep -F 'codex-marketplace-updater' rootfs/usr/local/bin/workstation-healthcheck >/dev/null; then
  fail 'Workstation healthcheck must not depend on Codex marketplace updater'
fi
if grep -F 'codex-marketplace-updater' rootfs/etc/s6-overlay/s6-rc.d/desktop/run >/dev/null; then
  fail 'desktop s6 service must not depend on Codex marketplace updater'
fi
pass 'Codex marketplace updater deterministic scheduler, bundled CLI and independent s6 service wiring'

echo
echo '=== compose ==='
command -v docker >/dev/null || fail 'docker is required for compose validation'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'
docker compose config >/dev/null || fail 'docker compose config'
pass 'compose config'

echo
echo '=== canonical paths ==='
canonical='/home/codex/Documents/ChatGPT'
grep -F "working_dir: $canonical" compose.yaml >/dev/null || fail 'compose working_dir is not canonical'
grep -F 'target: /home/codex' compose.yaml >/dev/null || fail 'persistent-home bind target is missing'
grep -F 'target: /home/codex/Documents/ChatGPT' compose.yaml >/dev/null || fail 'project bind target is not canonical'
grep -F 'WORKDIR /home/codex/Documents/ChatGPT' Dockerfile >/dev/null || fail 'Dockerfile WORKDIR is not canonical'

active_workspace="$({
  git grep -nE 'target:[[:space:]]*/workspace|working_dir:[[:space:]]*/workspace|WORKDIR[[:space:]]+/workspace|cd[[:space:]]+/workspace|test[[:space:]]+-w[[:space:]]+/workspace|ln[[:space:]].*/workspace' -- compose.yaml Dockerfile scripts rootfs 2>/dev/null || true
} )"
if [[ -n "$active_workspace" ]]; then
  printf '%s\n' "$active_workspace" >&2
  fail 'active /workspace runtime reference detected'
fi
pass 'canonical project root and no active /workspace runtime reference'

echo
echo '=== container boundary ==='
grep -F 'restart: unless-stopped' compose.yaml >/dev/null || fail 'restart policy is not unless-stopped'
grep -F 'source: ${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}/home' compose.yaml >/dev/null || fail 'persistent-home source is unexpected'
grep -F 'source: ${PROJECTS_ROOT:-/mnt/user/projects}' compose.yaml >/dev/null || fail 'project source is unexpected'
grep -F 'file: ${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}/secrets/novnc-password' compose.yaml >/dev/null || fail 'noVNC secret wiring missing'
grep -F 'file: ${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}/secrets/keyring-password' compose.yaml >/dev/null || fail 'keyring secret wiring missing'
grep -F 'CODEX_CHATGPT_WEB_NATIVE_UPSTREAM: ${CODEX_CHATGPT_WEB_NATIVE_UPSTREAM:-}' compose.yaml >/dev/null || fail 'optional native upstream setting missing'
grep -F '/usr/local/bin/workstation-healthcheck' compose.yaml >/dev/null || fail 'desktop-aware healthcheck missing'
if grep -Eq '^[[:space:]]*privileged:[[:space:]]*true|SYS_ADMIN|/var/run/docker\.sock' compose.yaml; then
  fail 'compose.yaml weakens the Docker isolation boundary'
fi
pass 'restart, binds, secrets, optional native upstream, healthcheck and isolation boundary'

echo
echo '=== Codex policy, CE features and image-managed applications ==='
grep -F 'approval_policy = "never"' rootfs/etc/codex/config.toml >/dev/null || fail 'Codex approval policy changed'
grep -F 'sandbox_mode = "danger-full-access"' rootfs/etc/codex/config.toml >/dev/null || fail 'Codex sandbox default changed'
grep -F 'allowed_approval_policies = ["never"]' rootfs/etc/codex/requirements.toml >/dev/null || fail 'Codex approval requirements changed'
grep -F '"danger-full-access"' rootfs/etc/codex/requirements.toml >/dev/null || fail 'Codex full-access mode is not allowed'
for feature in \
  remote-mobile-control \
  agent-workspace \
  computer-use-linux \
  authored-message-visibility \
  automation-extensions \
  mcp-helper-reaper \
  node-repl-reaper \
  project-group-last-updated-sort \
  directory-only-working-tree-watch; do
  grep -F "\"$feature\"" config/ce-features.json >/dev/null || fail "missing CE feature: $feature"
done
if grep -F 'shallow-repository-watches' config/ce-features.json >/dev/null; then
  fail 'conflicting shallow-repository-watches feature is enabled'
fi
grep -F 'PACKAGE_WITH_UPDATER=0' Dockerfile >/dev/null || fail 'CE native updater is not disabled at build time'
grep -F 'CODEX_WEB_GPT_DISABLE_UPDATES="\${CODEX_WEB_GPT_DISABLE_UPDATES:-1}"' scripts/build/install-codex-web-gpt.sh >/dev/null \
  || fail 'Codex Web GPT self-updater is not disabled by default in the workstation wrapper'
grep -Fx 'CODEX_CHATGPT_WEB_VERSION=' .env.example >/dev/null || fail 'Codex Web GPT default version override must stay empty'
grep -F 'releases/latest' scripts/build/install-codex-web-gpt.sh >/dev/null || fail 'Codex Web GPT installer no longer resolves releases/latest when unpinned'
grep -F 'codex-web-gpt-set-codex-lb-key' scripts/build/install-codex-web-gpt.sh >/dev/null || fail 'Codex Web GPT packaged Codex-LB key helper is not installed'
[[ -s scripts/build/install-muse-code.sh ]] || fail 'Muse build installer helper missing'
[[ -s rootfs/usr/local/bin/muse ]] || fail 'Muse runtime wrapper missing'
grep -F '/opt/muse-code/bin/muse' rootfs/usr/local/bin/muse >/dev/null || fail 'Muse wrapper does not target image-owned install'
grep -F 'MUSE_NO_AUTO_UPDATE="${MUSE_NO_AUTO_UPDATE:-1}"' rootfs/usr/local/bin/muse >/dev/null \
  || fail 'Muse runtime auto-update is not disabled by default'
grep -F 'HOME=/home/codex' Dockerfile >/dev/null || fail 'image default HOME no longer targets persistent /home/codex'
if grep -Ev '^[[:space:]]*#' rootfs/usr/local/bin/muse | grep -Eq '(^|[[:space:]])(export[[:space:]]+)?HOME='; then
  fail 'Muse wrapper must inherit persistent HOME instead of overriding it'
fi
grep -F 'MUSE_INSTALLER_URL' Dockerfile >/dev/null || fail 'Muse installer URL build arg missing'
grep -F '/tmp/install-muse-code.sh' Dockerfile >/dev/null || fail 'Muse install helper is not wired into Dockerfile'
grep -F 'muse exec --help' scripts/verify-runtime.sh >/dev/null || fail 'runtime verification does not assert Muse exec surface'
grep -F '[[ \"\$HOME\" == /home/codex ]]' scripts/verify-runtime.sh >/dev/null \
  || fail 'runtime verification does not assert persistent Muse HOME'
grep -F '## Persistent capability and skill plane' docs/MUSE_CODE_PLAN.md >/dev/null \
  || fail 'Muse capability-plane documentation missing'
grep -F 'elmakus/codex_workflow' docs/MUSE_CODE_PLAN.md >/dev/null \
  || fail 'Muse capability-plane documentation lost codex_workflow ownership boundary'
grep -F 'elmakus/muse-capability-admin' docs/MUSE_CODE_PLAN.md >/dev/null \
  || fail 'Muse capability-plane documentation lost administration ownership boundary'
pass 'Codex policy, CE features, latest-release Codex Web GPT and Muse image-managed/persistent capability boundaries'

echo
echo '=== desktop recovery surface ==='
for path in \
  rootfs/usr/local/bin/chatgpt-ce \
  rootfs/usr/local/bin/workstation-healthcheck \
  rootfs/usr/local/share/applications/chatgpt-ce.desktop \
  rootfs/usr/local/share/applications/codex-web-gpt.desktop \
  rootfs/etc/xdg/openbox/menu.xml \
  rootfs/etc/xdg/tint2/tint2rc; do
  [[ -s "$path" ]] || fail "missing $path"
done
grep -F 'tint2' Dockerfile >/dev/null || fail 'tint2 is not installed by Dockerfile'
grep -F 'xdotool' Dockerfile >/dev/null || fail 'xdotool is not installed by Dockerfile'
grep -F '## GUI automation' defaults/AGENTS.md >/dev/null || fail 'global agent GUI automation guidance missing'
grep -F 'Do not install `ydotool`' defaults/AGENTS.md >/dev/null || fail 'global agent guidance no longer rejects ad-hoc ydotool'
grep -F '/dev/uinput' defaults/AGENTS.md >/dev/null || fail 'global agent guidance no longer records uinput boundary'
grep -F '/usr/local/bin/chatgpt-ce' rootfs/etc/xdg/openbox/menu.xml >/dev/null || fail 'Openbox CE launcher missing'
grep -F '/usr/local/bin/codex-web-gpt' rootfs/etc/xdg/openbox/menu.xml >/dev/null || fail 'Openbox Codex Web GPT launcher missing'
grep -Fx 'longrun' rootfs/etc/s6-overlay/s6-rc.d/desktop/type >/dev/null || fail 'desktop s6 service is not longrun'
grep -F 'wait -n "$openbox_pid" "$x11vnc_pid" "$websockify_pid"' scripts/container/desktop-session-inner.sh >/dev/null || fail 'critical desktop processes are not supervised together'
grep -F 'pids+=("$ce_pid")' scripts/container/desktop-session-inner.sh >/dev/null || fail 'CE is not cleaned up on desktop-service restart'
grep -F 'pids+=("$codex_web_pid")' scripts/container/desktop-session-inner.sh >/dev/null || fail 'Codex Web GPT is not cleaned up on desktop-service restart'
grep -Fx 'panel_dock = 0' rootfs/etc/xdg/tint2/tint2rc >/dev/null \
  || fail 'Tint2 panel_dock must remain 0 to preserve full-width Openbox workarea under Xvfb'
pass 'noVNC relaunch, X11 automation guidance, full-width workarea and desktop supervision surface'

echo
echo '=== secret hygiene ==='
grep -Fx '.env' .gitignore >/dev/null || fail '.env is not ignored by Git'
grep -Fx 'secrets/' .gitignore >/dev/null || fail 'secrets/ is not ignored by Git'
grep -Fx '.env' .dockerignore >/dev/null || fail '.env is not excluded from Docker build context'
grep -Fx 'secrets/' .dockerignore >/dev/null || fail 'secrets/ is not excluded from Docker build context'
if grep -Eq 'CODEX_LB_API_KEY:[[:space:]]*[^$[:space:]]|META_API_KEY:[[:space:]]*[^$[:space:]]|MODEL_API_KEY:[[:space:]]*[^$[:space:]]' compose.yaml; then
  fail 'credential material appears to be configured directly in Compose'
fi
pass 'local overrides and secrets excluded from Git/image context'

echo
echo 'SOURCE_VALIDATION_GREEN'

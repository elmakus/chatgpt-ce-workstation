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
    find rootfs -type f \( -name '*.sh' -o -path '*/usr/local/bin/chatgpt-ce' -o -path '*/usr/local/bin/workstation-healthcheck' \) -print
    find rootfs/etc/cont-init.d -type f -print 2>/dev/null || true
    find rootfs/etc/s6-overlay/s6-rc.d -type f -name run -print 2>/dev/null || true
  } | sort -u
)
for file in "${shell_files[@]}"; do
  bash -n "$file" || fail "shell syntax: $file"
done
pass "bash -n (${#shell_files[@]} files)"

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
grep -F '/usr/local/bin/workstation-healthcheck' compose.yaml >/dev/null || fail 'desktop-aware healthcheck missing'
if grep -Eq '^[[:space:]]*privileged:[[:space:]]*true|SYS_ADMIN|/var/run/docker\.sock' compose.yaml; then
  fail 'compose.yaml weakens the Docker isolation boundary'
fi
pass 'restart, binds, secrets, healthcheck and isolation boundary'

echo
echo '=== Codex policy and CE features ==='
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
pass 'Codex policy, CE feature set and image-managed updates'

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
grep -F '/usr/local/bin/chatgpt-ce' rootfs/etc/xdg/openbox/menu.xml >/dev/null || fail 'Openbox CE launcher missing'
grep -F '/usr/local/bin/codex-web-gpt' rootfs/etc/xdg/openbox/menu.xml >/dev/null || fail 'Openbox Codex Web GPT launcher missing'
grep -Fx 'longrun' rootfs/etc/s6-overlay/s6-rc.d/desktop/type >/dev/null || fail 'desktop s6 service is not longrun'
grep -F 'wait -n "$openbox_pid" "$x11vnc_pid" "$websockify_pid"' scripts/container/desktop-session-inner.sh >/dev/null || fail 'critical desktop processes are not supervised together'
grep -F 'pids+=("$ce_pid")' scripts/container/desktop-session-inner.sh >/dev/null || fail 'CE is not cleaned up on desktop-service restart'
grep -F 'pids+=("$codex_web_pid")' scripts/container/desktop-session-inner.sh >/dev/null || fail 'Codex Web GPT is not cleaned up on desktop-service restart'
pass 'noVNC relaunch and desktop supervision surface'

echo
echo '=== secret hygiene ==='
grep -Fx '.env' .gitignore >/dev/null || fail '.env is not ignored by Git'
grep -Fx 'secrets/' .gitignore >/dev/null || fail 'secrets/ is not ignored by Git'
grep -Fx '.env' .dockerignore >/dev/null || fail '.env is not excluded from Docker build context'
grep -Fx 'secrets/' .dockerignore >/dev/null || fail 'secrets/ is not excluded from Docker build context'
pass 'local overrides and secrets excluded from Git/image context'

echo
echo 'SOURCE_VALIDATION_GREEN'

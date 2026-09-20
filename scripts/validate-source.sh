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
echo '=== frozen upstream resolver foundation ==='
[[ -s scripts/resolve-upstreams.py ]] || fail 'upstream resolver missing'
[[ -s scripts/build/Dockerfile.upstream-resolution ]] || fail 'upstream resolver Dockerfile missing'
grep -F 'FROM ${UBUNTU_BASE} AS openai-resolver' scripts/build/Dockerfile.upstream-resolution >/dev/null \
  || fail 'OpenAI metadata resolver is not bound to an explicit base identity'
grep -F 'CE_COMMIT' scripts/build/Dockerfile.upstream-resolution >/dev/null \
  || fail 'OpenAI metadata resolver is not bound to an exact CE commit'
grep -F -- '--metadata-only' scripts/build/Dockerfile.upstream-resolution >/dev/null \
  || fail 'OpenAI metadata resolver does not use CE metadata-only signed resolver path'
python3 scripts/test-resolve-upstreams.py || fail 'frozen upstream resolver fixture tests'
python3 scripts/test-render-build-env.py || fail 'frozen manifest build-input fixture tests'
grep -F 'ARG UBUNTU_BASE' Dockerfile >/dev/null || fail 'Dockerfile has no explicit frozen Ubuntu base arg'
grep -F 'FROM ${UBUNTU_BASE}' Dockerfile >/dev/null || fail 'Dockerfile does not consume the frozen Ubuntu base'
grep -F 'CE_COMMIT' Dockerfile >/dev/null || fail 'Dockerfile does not consume the exact CE commit'
grep -F 'upstream-linux-package.js' Dockerfile >/dev/null || fail 'Dockerfile bypasses CE signed OpenAI package resolver'
grep -F 'OPENAI_PACKAGE_SHA256' Dockerfile >/dev/null || fail 'Dockerfile does not bind the OpenAI package hash'
grep -F 'AGENT_WORKSPACE_INTEGRITY' Dockerfile >/dev/null || fail 'Dockerfile does not bind Agent Workspace integrity'
grep -F 'S6_OVERLAY_NOARCH_SHA256' Dockerfile >/dev/null || fail 'Dockerfile does not bind s6 asset hashes'
grep -F 'CODEX_CHATGPT_WEB_SHA256' Dockerfile >/dev/null || fail 'Dockerfile does not bind Codex Web GPT checksum'
grep -F 'MUSE_EXPECTED_VERSION' Dockerfile >/dev/null || fail 'Dockerfile does not bind Muse stable release id'
grep -F 'CHROME_PACKAGE_SHA256' Dockerfile >/dev/null || fail 'Dockerfile does not bind Chrome package checksum'
grep -F 'RUST_STABLE_MANIFEST_SHA256' Dockerfile >/dev/null || fail 'Dockerfile does not bind Rust stable manifest identity'
grep -F 'COPY .workstation-build/upstream-resolution.json /opt/workstation/upstream-resolution.json' Dockerfile >/dev/null \
  || fail 'candidate image does not embed exact upstream resolution'
grep -F 'io.chatgpt-ce-workstation.upstream-resolution-sha256' Dockerfile >/dev/null \
  || fail 'candidate image does not label exact upstream resolution digest'
if grep -F 'UPSTREAM_REFRESH' Dockerfile compose.yaml scripts/build.sh .env.example >/dev/null; then
  fail 'timestamp-style UPSTREAM_REFRESH remains in exact candidate build path'
fi
pass 'frozen upstream resolution and exact build-input contracts'

echo
echo '=== compose ==='
command -v docker >/dev/null || fail 'docker is required for compose validation'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'
fixture_sha="$(printf 'a%.0s' {1..64})"
fixture_commit="$(printf 'b%.0s' {1..40})"
env \
  UBUNTU_BASE="ubuntu:24.04@sha256:${fixture_sha}" \
  UBUNTU_APT_IDENTITY="sha256:${fixture_sha}" \
  CE_REPOSITORY="https://github.com/ilysenko/codex-desktop-linux.git" \
  CE_REF=main CE_COMMIT="${fixture_commit}" \
  OPENAI_PACKAGE_VERSION=1.0.0 OPENAI_PACKAGE_SHA256="${fixture_sha}" \
  S6_OVERLAY_VERSION=3.2.3.2 S6_OVERLAY_NOARCH_SHA256="${fixture_sha}" S6_OVERLAY_X86_64_SHA256="${fixture_sha}" \
  AGENT_WORKSPACE_VERSION=0.0.0 AGENT_WORKSPACE_INTEGRITY="sha512-fixture" \
  CODEX_CHATGPT_WEB_VERSION=0.0.0 CODEX_CHATGPT_WEB_SHA256="${fixture_sha}" \
  MUSE_INSTALLER_URL=https://dev.meta.ai/install.sh MUSE_INSTALLER_SHA256="${fixture_sha}" MUSE_EXPECTED_VERSION=0.0.0-R0.0 \
  CHROME_VERSION=1.0.0-1 CHROME_PACKAGE_SHA256="${fixture_sha}" GOOGLE_LINUX_SIGNING_KEY_DIGEST_SHA256="${fixture_sha}" \
  RUST_VERSION=1.90.0 RUST_STABLE_MANIFEST_SHA256="${fixture_sha}" RUSTUP_INSTALLER_SHA256="${fixture_sha}" \
  UPSTREAM_RESOLUTION_SHA256="${fixture_sha}" \
  docker compose config >/dev/null || fail 'docker compose config'
pass 'compose config with exact frozen build inputs'

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
grep -F '# CODEX_CHATGPT_WEB_VERSION=' .env.example >/dev/null || fail 'Codex Web GPT expert override is not documented as optional'
if grep -F 'releases/latest' scripts/build/install-codex-web-gpt.sh >/dev/null; then
  fail 'Codex Web GPT build installer still resolves a moving latest release'
fi
grep -F 'CODEX_CHATGPT_WEB_SHA256' scripts/build/install-codex-web-gpt.sh >/dev/null \
  || fail 'Codex Web GPT build installer does not require frozen checksum'
grep -F 'codex-web-gpt-set-codex-lb-key' scripts/build/install-codex-web-gpt.sh >/dev/null || fail 'Codex Web GPT packaged Codex-LB key helper is not installed'
[[ -s scripts/build/install-muse-code.sh ]] || fail 'Muse build installer helper missing'
[[ -s rootfs/usr/local/bin/muse ]] || fail 'Muse runtime wrapper missing'
grep -F '/opt/muse-code/bin/muse' rootfs/usr/local/bin/muse >/dev/null || fail 'Muse wrapper does not target image-owned install'
grep -F 'MUSE_NO_AUTO_UPDATE="${MUSE_NO_AUTO_UPDATE:-1}"' rootfs/usr/local/bin/muse >/dev/null \
  || fail 'Muse runtime auto-update is not disabled by default'
grep -F 'MUSE_INSTALLER_URL' Dockerfile >/dev/null || fail 'Muse installer URL build arg missing'
grep -F '/tmp/install-muse-code.sh' Dockerfile >/dev/null || fail 'Muse install helper is not wired into Dockerfile'
grep -F 'muse exec --help' scripts/verify-runtime.sh >/dev/null || fail 'runtime verification does not assert Muse exec surface'
pass 'Codex policy, CE features, frozen Codex Web GPT and Muse image-managed boundaries'

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

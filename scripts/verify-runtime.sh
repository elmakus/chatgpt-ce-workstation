#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

canonical_root="/home/codex/Documents/ChatGPT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "OK: $*"
}

# Resolve the same host-path overrides Compose uses so verification checks the
# actual bind sources, not just their destinations inside the container.
caller_appdata_set="${APPDATA_ROOT+x}"
caller_appdata="${APPDATA_ROOT-}"
caller_projects_set="${PROJECTS_ROOT+x}"
caller_projects="${PROJECTS_ROOT-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi
[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"
[[ -n "$caller_projects_set" ]] && PROJECTS_ROOT="$caller_projects"
appdata_root="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
projects_root="${PROJECTS_ROOT:-/mnt/user/projects}"
expected_home_source="${appdata_root%/}/home"
expected_project_source="${projects_root%/}"

echo '=== compose ==='
command -v docker >/dev/null || fail 'docker is required'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'
docker compose config >/dev/null || fail 'docker compose config'
pass 'compose config'

echo
echo '=== container ==='
container="$(docker compose ps -q workstation)"
[[ -n "$container" ]] || fail 'workstation container does not exist'
running="$(docker inspect --format='{{.State.Running}}' "$container")"
[[ "$running" == true ]] || fail 'workstation container is not running'
name="$(docker inspect --format='{{.Name}}' "$container" | sed 's#^/##')"
echo "container: $name"
pass 'container running'

health="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container")"
echo "health: $health"
[[ "$health" == healthy ]] || fail "container health is $health"

restart_policy="$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$container")"
[[ "$restart_policy" == unless-stopped ]] || fail "unexpected restart policy: $restart_policy"
pass 'restart policy is unless-stopped'

echo
echo '=== mounts ==='
mounts="$(docker inspect "$container" --format='{{range .Mounts}}{{println .Type .Source "->" .Destination}}{{end}}')"
printf '%s\n' "$mounts"

home_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex"}}{{.Source}}{{end}}{{end}}')"
home_type="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex"}}{{.Type}}{{end}}{{end}}')"
project_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex/Documents/ChatGPT"}}{{.Source}}{{end}}{{end}}')"
project_type="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex/Documents/ChatGPT"}}{{.Type}}{{end}}{{end}}')"

[[ "$home_type" == bind ]] || fail "persistent home is not a bind mount (type: ${home_type:-missing})"
[[ "$project_type" == bind ]] || fail "project root is not a bind mount (type: ${project_type:-missing})"
[[ "${home_source%/}" == "$expected_home_source" ]] || fail "wrong home bind source: ${home_source:-missing} (expected $expected_home_source)"
[[ "${project_source%/}" == "$expected_project_source" ]] || fail "wrong project bind source: ${project_source:-missing} (expected $expected_project_source)"

legacy_workspace_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/workspace"}}{{.Source}}{{end}}{{end}}')"
[[ -z "$legacy_workspace_source" ]] || fail "legacy /workspace mount is still active from $legacy_workspace_source"

docker_socket_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/var/run/docker.sock"}}{{.Source}}{{end}}{{end}}')"
[[ -z "$docker_socket_source" ]] || fail "Docker socket is mounted from $docker_socket_source"

host_root_destination="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Source "/"}}{{.Destination}}{{end}}{{end}}')"
[[ -z "$host_root_destination" ]] || fail "host root is bind-mounted at $host_root_destination"

pass 'exact persistent-home/project binds; no /workspace, Docker socket, or host-root mount'

echo
echo '=== privilege boundary ==='
privileged="$(docker inspect --format='{{.HostConfig.Privileged}}' "$container")"
[[ "$privileged" == false ]] || fail 'container is privileged'
cap_add="$(docker inspect --format='{{json .HostConfig.CapAdd}}' "$container")"
[[ "$cap_add" != *SYS_ADMIN* ]] || fail "SYS_ADMIN capability is enabled: $cap_add"
pass 'container unprivileged and without SYS_ADMIN'

echo
echo '=== D-Bus / keyring session isolation ==='
blocked_session_bus='unix:path=/run/workstation/no-session-bus'
container_session_bus="$(docker exec "$container" /bin/sh -c 'printf "%s" "${DBUS_SESSION_BUS_ADDRESS:-}"')"
[[ "$container_session_bus" == "$blocked_session_bus" ]] \
  || fail "unexpected non-desktop D-Bus default: ${container_session_bus:-missing}"

# The supervised desktop must replace the fail-closed image default with the
# private session bus created by dbus-run-session.
desktop_session_bus="$(
  docker exec -u codex "$container" bash -lc '
    set -Eeuo pipefail
    pid="$(pgrep -u "$(id -u)" -f "^bash /opt/workstation/bin/desktop-session-inner\\.sh$" | head -n 1)"
    [[ -n "$pid" ]]
    tr "\\0" "\\n" <"/proc/$pid/environ" \
      | sed -n "s/^DBUS_SESSION_BUS_ADDRESS=//p" \
      | head -n 1
  '
)"
[[ "$desktop_session_bus" == unix:path=* ]] \
  || fail "desktop session has no usable D-Bus address: ${desktop_session_bus:-missing}"
[[ "$desktop_session_bus" != "$blocked_session_bus" ]] \
  || fail 'desktop session did not replace the fail-closed D-Bus default'

docker exec -u codex "$container" env DBUS_SESSION_BUS_ADDRESS="$desktop_session_bus" \
  dbus-send --session --print-reply --dest=org.freedesktop.DBus / \
    org.freedesktop.DBus.NameHasOwner string:org.freedesktop.secrets \
  | grep -F 'boolean true' >/dev/null \
  || fail 'GNOME Secret Service is not present on the canonical desktop bus'

root_keyrings="$(docker top "$container" -eo pid,user,args \
  | awk '$2 == "root" && /[g]nome-keyring-daemon/ { print }')"
[[ -z "$root_keyrings" ]] || {
  printf '%s\n' "$root_keyrings" >&2
  fail 'root-owned secondary GNOME keyring daemon detected'
}
pass 'non-desktop D-Bus fails closed; desktop owns the only keyring service session'

echo
echo '=== in-container runtime ==='
docker exec -u codex "$container" bash -lc "
set -Eeuo pipefail
[[ \"\$(pwd)\" == '$canonical_root' ]]
[[ ! -e /workspace ]]
[[ ! -e /var/run/docker.sock ]]
[[ -r /run/workstation/keyring-password ]]
[[ -s /home/codex/.config/workstation/vnc.pass ]]
[[ -x /opt/muse-code/bin/muse ]]
for cmd in chatgpt-ce codex-web-gpt muse openbox tint2 xterm google-chrome workstation-healthcheck xdotool wmctrl; do
  command -v \"\$cmd\" >/dev/null
  echo \"OK command: \$cmd\"
done
muse --version
muse --help >/dev/null
muse exec --help >/dev/null
printf '%s\n' 'OK Muse CLI: version/help/exec-help'
pgrep -x tint2 >/dev/null
printf '%s\n' 'OK process: tint2'
xdotool getmouselocation >/dev/null
printf '%s\\n' 'OK X11 automation: xdotool getmouselocation'
if [[ "\${INSTALL_GLOBAL_AGENTS:-0}" == "1" ]]; then
  python3 /opt/workstation/bin/reconcile-global-agents.py \
    --check \
    --target /home/codex/.codex/AGENTS.md \
    --payload /opt/workstation/defaults/AGENTS.md
  printf '%s\\n' 'OK managed global AGENTS: current workstation block'
fi
touch '$canonical_root/.workstation-write-test'
rm -f '$canonical_root/.workstation-write-test'
bash /usr/local/bin/workstation-healthcheck
"
pass 'canonical pwd, launchers, Muse CLI surface, X11 automation, secrets, panel, write access and desktop health'

echo
echo '=== persistent home ==='
# Global AGENTS state is checked inside the container through the bounded
# workstation-owned marker/payload verifier above; do not dump unrelated content.
mapfile -t backups < <(find "$appdata_root/home/Documents" -maxdepth 1 -type d -name 'ChatGPT.pre-*' -print 2>/dev/null | sort)
if (( ${#backups[@]} > 0 )); then
  echo 'WARN: preserved pre-migration project backup(s) exist:' >&2
  printf '  %s\n' "${backups[@]}" >&2
  echo 'They may contain only disposable test repositories; delete them after confirming nothing useful is inside.' >&2
else
  pass 'no preserved pre-migration project directories detected'
fi

echo
echo 'WORKSTATION_RUNTIME_GREEN'

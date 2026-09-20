#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

expected_image_id="${1:-}"
[[ "$expected_image_id" == sha256:* ]] || {
  echo "FAIL: expected rollback image ID must be sha256:*" >&2
  exit 2
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

caller_appdata_set="${APPDATA_ROOT+x}"
caller_appdata="${APPDATA_ROOT-}"
caller_projects_set="${PROJECTS_ROOT+x}"
caller_projects="${PROJECTS_ROOT-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi
[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"
[[ -n "$caller_projects_set" ]] && PROJECTS_ROOT="$caller_projects"

appdata_root="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
projects_root="${PROJECTS_ROOT:-/mnt/user/projects}"
expected_home_source="${appdata_root%/}/home"
expected_project_source="${projects_root%/}"

command -v docker >/dev/null || fail 'docker is required'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'

container="$(docker compose ps -q workstation)"
[[ -n "$container" ]] || fail 'rollback workstation container does not exist'

actual_image="$(docker inspect --format='{{.Image}}' "$container")"
[[ "$actual_image" == "$expected_image_id" ]] || fail "rollback image mismatch: expected $expected_image_id, got ${actual_image:-missing}"
[[ "$(docker inspect --format='{{.State.Running}}' "$container")" == true ]] || fail 'rollback container is not running'
health="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container")"
[[ "$health" == healthy ]] || fail "rollback container health is $health"
[[ "$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$container")" == unless-stopped ]] || fail 'unexpected rollback restart policy'

home_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex"}}{{.Source}}{{end}}{{end}}')"
home_type="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex"}}{{.Type}}{{end}}{{end}}')"
project_source="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex/Documents/ChatGPT"}}{{.Source}}{{end}}{{end}}')"
project_type="$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/home/codex/Documents/ChatGPT"}}{{.Type}}{{end}}{{end}}')"
[[ "$home_type" == bind && "${home_source%/}" == "$expected_home_source" ]] || fail 'wrong rollback home bind'
[[ "$project_type" == bind && "${project_source%/}" == "$expected_project_source" ]] || fail 'wrong rollback project bind'

[[ -z "$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/workspace"}}{{.Source}}{{end}}{{end}}')" ]] || fail 'legacy /workspace mount is active after rollback'
[[ -z "$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Destination "/var/run/docker.sock"}}{{.Source}}{{end}}{{end}}')" ]] || fail 'Docker socket is mounted after rollback'
[[ -z "$(docker inspect "$container" --format='{{range .Mounts}}{{if eq .Source "/"}}{{.Destination}}{{end}}{{end}}')" ]] || fail 'host root is bind-mounted after rollback'

[[ "$(docker inspect --format='{{.HostConfig.Privileged}}' "$container")" == false ]] || fail 'rollback container is privileged'
cap_add="$(docker inspect --format='{{json .HostConfig.CapAdd}}' "$container")"
[[ "$cap_add" != *SYS_ADMIN* ]] || fail "rollback container has SYS_ADMIN: $cap_add"

echo "ROLLBACK_RUNTIME_GREEN image=$actual_image"

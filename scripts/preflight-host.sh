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

if [[ "$(id -u)" -ne 0 ]]; then
  fail 'run this host preflight from an Unraid root shell'
fi

caller_appdata_set="${APPDATA_ROOT+x}"; caller_appdata="${APPDATA_ROOT-}"
caller_projects_set="${PROJECTS_ROOT+x}"; caller_projects="${PROJECTS_ROOT-}"
caller_container_set="${CONTAINER_NAME+x}"; caller_container="${CONTAINER_NAME-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi
[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"
[[ -n "$caller_projects_set" ]] && PROJECTS_ROOT="$caller_projects"
[[ -n "$caller_container_set" ]] && CONTAINER_NAME="$caller_container"

APPDATA_ROOT="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
PROJECTS_ROOT="${PROJECTS_ROOT:-/mnt/user/projects}"
CONTAINER_NAME="${CONTAINER_NAME:-chatgpt-ce-workstation}"
KEYRING_SECRET_FILE="$APPDATA_ROOT/secrets/keyring-password"
CE_PROJECT_TARGET="$APPDATA_ROOT/home/Documents/ChatGPT"

command -v docker >/dev/null || fail 'docker is required'
docker compose version >/dev/null || fail 'Docker Compose v2 is required'
docker compose config >/dev/null || fail 'docker compose config'
pass 'Docker/Compose available and compose.yaml resolves'

[[ -d "$APPDATA_ROOT/home" ]] || fail "persistent home does not exist: $APPDATA_ROOT/home"
[[ -d "$PROJECTS_ROOT" ]] || fail "project root does not exist: $PROJECTS_ROOT"
# D26 intentionally uses an empty file as the steady-state/fresh-install\n# passwordless migration placeholder. Presence is required; non-empty content is\n# only an optional one-time legacy migration credential.\n[[ -f "$KEYRING_SECRET_FILE" ]] || fail "missing keyring migration placeholder: $KEYRING_SECRET_FILE"\npass 'persistent home, project root and keyring migration credential state are ready'

if docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  running="$(docker inspect --format='{{.State.Running}}' "$CONTAINER_NAME")"
  echo "current container: $CONTAINER_NAME (running=$running)"
else
  echo "current container: $CONTAINER_NAME (not present)"
fi

if [[ -L "$CE_PROJECT_TARGET" ]]; then
  echo "legacy project target: $CE_PROJECT_TARGET -> $(readlink "$CE_PROJECT_TARGET")"
elif [[ -d "$CE_PROJECT_TARGET" ]]; then
  if find "$CE_PROJECT_TARGET" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
    echo "non-empty pre-bind project target detected: $CE_PROJECT_TARGET"
    echo 'scripts/init-unraid.sh will preserve it as ChatGPT.pre-* while the container is stopped.'
  else
    echo "project bind target is an empty directory: $CE_PROJECT_TARGET"
  fi
elif [[ -e "$CE_PROJECT_TARGET" ]]; then
  echo "non-directory pre-bind project target detected: $CE_PROJECT_TARGET"
  echo 'scripts/init-unraid.sh will preserve it as ChatGPT.pre-* while the container is stopped.'
else
  echo "project bind target does not yet exist: $CE_PROJECT_TARGET"
fi

echo
echo 'HOST_PREFLIGHT_GREEN'

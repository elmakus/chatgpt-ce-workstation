#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# init-unraid needs host paths before Compose starts. Load the tracked .env-style
# overrides if present, while preserving variables explicitly supplied by the
# caller (matching normal Compose precedence: shell environment > .env > defaults).
caller_appdata_set="${APPDATA_ROOT+x}"; caller_appdata="${APPDATA_ROOT-}"
caller_projects_set="${PROJECTS_ROOT+x}"; caller_projects="${PROJECTS_ROOT-}"
caller_uid_set="${CODEX_UID+x}"; caller_uid="${CODEX_UID-}"
caller_gid_set="${CODEX_GID+x}"; caller_gid="${CODEX_GID-}"
caller_container_set="${CONTAINER_NAME+x}"; caller_container="${CONTAINER_NAME-}"

if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # .env.example is intentionally shell-compatible; keep local .env that way.
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi

[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"
[[ -n "$caller_projects_set" ]] && PROJECTS_ROOT="$caller_projects"
[[ -n "$caller_uid_set" ]] && CODEX_UID="$caller_uid"
[[ -n "$caller_gid_set" ]] && CODEX_GID="$caller_gid"
[[ -n "$caller_container_set" ]] && CONTAINER_NAME="$caller_container"

APPDATA_ROOT="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
PROJECTS_ROOT="${PROJECTS_ROOT:-/mnt/user/projects}"
CODEX_UID="${CODEX_UID:-99}"
CODEX_GID="${CODEX_GID:-100}"
CONTAINER_NAME="${CONTAINER_NAME:-chatgpt-ce-workstation}"
SECRET_DIR="$APPDATA_ROOT/secrets"
VNC_SECRET_FILE="$SECRET_DIR/novnc-password"
KEYRING_SECRET_FILE="$SECRET_DIR/keyring-password"
CE_PROJECT_TARGET="$APPDATA_ROOT/home/Documents/ChatGPT"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script from an Unraid root shell." >&2
  exit 1
fi

# The script may rename/remove the persistent-home mountpoint that receives the
# nested PROJECTS_ROOT bind. Never mutate it while the workstation container is
# running; doing so can leave the live mount hidden behind renamed directories.
if command -v docker >/dev/null 2>&1 \
  && docker inspect "$CONTAINER_NAME" >/dev/null 2>&1 \
  && [[ "$(docker inspect --format='{{.State.Running}}' "$CONTAINER_NAME")" == true ]]; then
  echo "Container $CONTAINER_NAME is running. Stop it first with: docker compose down" >&2
  exit 1
fi

mkdir -p "$APPDATA_ROOT/home" "$SECRET_DIR" "$PROJECTS_ROOT"
chmod 0700 "$SECRET_DIR"

if [[ ! -s "$VNC_SECRET_FILE" ]]; then
  read -r -s -p "Choose a noVNC/VNC password: " password
  echo
  read -r -s -p "Repeat password: " password2
  echo
  if [[ -z "$password" || "$password" != "$password2" ]]; then
    echo "Passwords are empty or do not match." >&2
    exit 1
  fi
  printf '%s' "$password" > "$VNC_SECRET_FILE"
  unset password password2
  chmod 0600 "$VNC_SECRET_FILE"
  echo "Created $VNC_SECRET_FILE"
else
  echo "Keeping existing $VNC_SECRET_FILE"
fi

# D26 uses a passwordless GNOME keyring. Keep the historical secret path only
# as an optional one-time migration credential for already-encrypted installs.
# Fresh installations get an empty placeholder and never prompt for a keyring
# password. Existing non-empty credentials are preserved until migration succeeds.
if [[ ! -e "$KEYRING_SECRET_FILE" ]]; then
  : > "$KEYRING_SECRET_FILE"
  chmod 0600 "$KEYRING_SECRET_FILE"
  echo "Created empty keyring migration placeholder: $KEYRING_SECRET_FILE"
elif [[ -s "$KEYRING_SECRET_FILE" ]]; then
  chmod 0600 "$KEYRING_SECRET_FILE"
  echo "Keeping legacy keyring migration credential until passwordless migration succeeds."
else
  chmod 0600 "$KEYRING_SECRET_FILE"
  echo "Keyring migration credential is already empty (passwordless target)."
fi

# Persistent home must be writable by the configured container user.
chown "$CODEX_UID:$CODEX_GID" "$APPDATA_ROOT/home" || true
chmod 0750 "$APPDATA_ROOT/home"

# CE natively creates projects below ~/Documents/ChatGPT. PROJECTS_ROOT is now
# mounted directly there, so normalize the target in persistent home to a real
# directory. Older workstation builds used a symlink to /workspace; remove that
# compatibility alias before Docker creates the nested bind mount. Preserve any
# unexpected real directory instead of hiding user data beneath the mount.
mkdir -p "$APPDATA_ROOT/home/Documents"
if [[ -L "$CE_PROJECT_TARGET" ]]; then
  echo "Removing legacy CE project symlink: $CE_PROJECT_TARGET -> $(readlink "$CE_PROJECT_TARGET")"
  rm -f "$CE_PROJECT_TARGET"
elif [[ -e "$CE_PROJECT_TARGET" && ! -d "$CE_PROJECT_TARGET" ]]; then
  backup_target="$CE_PROJECT_TARGET.pre-bind-$(date +%Y%m%d-%H%M%S)"
  mv "$CE_PROJECT_TARGET" "$backup_target"
  echo "Preserved unexpected CE project target at: $backup_target"
elif [[ -d "$CE_PROJECT_TARGET" ]] && find "$CE_PROJECT_TARGET" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
  backup_target="$CE_PROJECT_TARGET.pre-bind-$(date +%Y%m%d-%H%M%S)"
  mv "$CE_PROJECT_TARGET" "$backup_target"
  echo "Preserved pre-bind CE project directory at: $backup_target"
fi
mkdir -p "$CE_PROJECT_TARGET"
chown "$CODEX_UID:$CODEX_GID" "$APPDATA_ROOT/home/Documents" "$CE_PROJECT_TARGET" || true

# The project-share root itself must be writable because CE's Create Project flow
# creates new repository directories directly in it. Do not recursively chown all
# existing projects; only normalize the share root and this workstation repo.
chown "$CODEX_UID:$CODEX_GID" "$PROJECTS_ROOT" || true
chmod 2775 "$PROJECTS_ROOT" || true

# If this workstation repository itself is stored under PROJECTS_ROOT (the
# recommended layout), make that one repository writable by the container user
# so Codex can maintain its own Dockerfile/Compose source. Do not recursively
# change ownership of unrelated project repositories.
projects_real="$(realpath -m "$PROJECTS_ROOT")"
repo_real="$(realpath -m "$REPO_ROOT")"
case "$repo_real/" in
  "$projects_real"/*)
    echo "Making workstation repo writable by UID $CODEX_UID / GID $CODEX_GID: $repo_real"
    chown -R "$CODEX_UID:$CODEX_GID" "$repo_real"
    ;;
  *)
    echo "Workstation repo is outside PROJECTS_ROOT; leaving repo ownership unchanged: $repo_real"
    ;;
esac

echo
echo "Prepared:"
echo "  appdata:        $APPDATA_ROOT/home"
echo "  projects host:  $PROJECTS_ROOT"
echo "  projects in CE: /home/codex/Documents/ChatGPT"
echo "  VNC secret:     $VNC_SECRET_FILE"
echo "  keyring migration file: $KEYRING_SECRET_FILE"
echo "  identity:       UID $CODEX_UID / GID $CODEX_GID"
echo
echo "Next: bash scripts/build.sh"

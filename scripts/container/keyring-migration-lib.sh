#!/usr/bin/env bash
set -Eeuo pipefail

prepare_keyring_passwordless_v2() {
  local home="$1"
  local target_uid="$2"
  local target_gid="$3"
  local marker="${4:-$home/.config/workstation/keyring-passwordless-v2}"
  local keyring_dir="${5:-$home/.local/share/keyrings}"
  local backup="${6:-$home/.local/share/keyrings.pre-passwordless-v2}"

  [[ -f "$marker" ]] && return 0
  [[ -d "$keyring_dir" ]] || return 0

  if [[ -e "$backup" && ! -d "$backup" ]]; then
    echo "[keyring-migration] backup path exists but is not a directory: $backup" >&2
    return 1
  fi

  if [[ ! -e "$backup" ]]; then
    cp -a -- "$keyring_dir" "$backup"
  fi

  chown -R "$target_uid:$target_gid" "$keyring_dir"
}

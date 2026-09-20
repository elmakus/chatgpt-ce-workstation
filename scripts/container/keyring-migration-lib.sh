#!/usr/bin/env bash
set -Eeuo pipefail

prepare_keyring_passwordless_v2() {
  local home="$1"
  local target_uid="$2"
  local target_gid="$3"
  local marker="${4:-$home/.config/workstation/keyring-passwordless-v2}"
  local keyring_dir="${5:-$home/.local/share/keyrings}"
  local backup="${6:-$home/.local/share/keyrings.pre-passwordless-v2}"
  local staging="${backup}.staging"

  [[ -f "$marker" ]] && return 0
  [[ -d "$keyring_dir" ]] || return 0

  if [[ -e "$backup" && ! -d "$backup" ]]; then
    echo "[keyring-migration] backup path exists but is not a directory: $backup" >&2
    return 1
  fi

  if [[ ! -e "$backup" ]]; then
    # Never publish a partially copied directory as the canonical rollback
    # snapshot. A hard interruption may leave only the sibling staging path;
    # the next attempt discards that unpublished state and starts a fresh copy.
    rm -rf -- "$staging"
    if ! cp -a -- "$keyring_dir" "$staging"; then
      rm -rf -- "$staging"
      echo "[keyring-migration] failed to stage complete keyring backup: $staging" >&2
      return 1
    fi
    if ! mv -- "$staging" "$backup"; then
      rm -rf -- "$staging"
      echo "[keyring-migration] failed to publish keyring backup: $backup" >&2
      return 1
    fi
  fi

  chown -R "$target_uid:$target_gid" "$keyring_dir"
}

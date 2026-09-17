#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

caller_appdata_set="${APPDATA_ROOT+x}"
caller_appdata="${APPDATA_ROOT-}"
caller_uid_set="${CODEX_UID+x}"
caller_uid="${CODEX_UID-}"
caller_gid_set="${CODEX_GID+x}"
caller_gid="${CODEX_GID-}"

if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi

[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"
[[ -n "$caller_uid_set" ]] && CODEX_UID="$caller_uid"
[[ -n "$caller_gid_set" ]] && CODEX_GID="$caller_gid"

APPDATA_ROOT="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
CODEX_UID="${CODEX_UID:-99}"
CODEX_GID="${CODEX_GID:-100}"
key_dir="$APPDATA_ROOT/home/.config/workstation"
key_file="$key_dir/codex-lb-api-key"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this helper from an Unraid root shell." >&2
  exit 1
fi

case "${1:-}" in
  --clear)
    rm -f "$key_file"
    echo "Removed Codex-LB API key: $key_file"
    exit 0
    ;;
  "") ;;
  *)
    echo "Usage: bash scripts/set-codex-lb-key.sh [--clear]" >&2
    exit 2
    ;;
esac

read -r -s -p "Codex-LB API key: " key
echo
read -r -s -p "Repeat Codex-LB API key: " key2
echo

if [[ -z "$key" || "$key" != "$key2" ]]; then
  unset key key2
  echo "Keys are empty or do not match." >&2
  exit 1
fi

install -d -m 0700 -o "$CODEX_UID" -g "$CODEX_GID" "$key_dir"
umask 077
printf '%s' "$key" > "$key_file"
unset key key2
chown "$CODEX_UID:$CODEX_GID" "$key_file"
chmod 0600 "$key_file"

echo "Stored Codex-LB API key at: $key_file"
echo "The key is read only when codex-web-gpt starts; restart that launcher after changing it."

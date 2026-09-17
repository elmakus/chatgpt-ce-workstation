#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

caller_appdata_set="${APPDATA_ROOT+x}"
caller_appdata="${APPDATA_ROOT-}"
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a
fi
[[ -n "$caller_appdata_set" ]] && APPDATA_ROOT="$caller_appdata"

APPDATA_ROOT="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
secret_dir="$APPDATA_ROOT/secrets"
secret_file="$secret_dir/codex-lb-api-key"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run this script from an Unraid root shell." >&2
  exit 1
fi

mkdir -p "$secret_dir"
chmod 0700 "$secret_dir"
umask 077

if [[ "${1:-}" == "--clear" ]]; then
  : > "$secret_file"
  chmod 0600 "$secret_file"
  echo "Cleared Codex-LB API key: $secret_file"
  exit 0
elif [[ -n "${1:-}" ]]; then
  echo "Usage: bash scripts/set-codex-lb-key.sh [--clear]" >&2
  echo "The key is never accepted as a command-line argument." >&2
  exit 2
fi

read -r -s -p "Codex-LB API key: " key
echo
read -r -s -p "Repeat Codex-LB API key: " key2
echo
if [[ -z "$key" || "$key" != "$key2" ]]; then
  echo "Keys are empty or do not match." >&2
  exit 1
fi

printf '%s' "$key" > "$secret_file"
unset key key2
chmod 0600 "$secret_file"
echo "Saved Codex-LB API key in Docker secret source: $secret_file"
echo "Recreate the workstation container before expecting an already-running launcher to see a newly mounted secret."

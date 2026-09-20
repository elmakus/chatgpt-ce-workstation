#!/usr/bin/env bash
set -Eeuo pipefail

container="${1:-}"
session_bus="${2:-}"
collection="${3:-}"

[[ -n "$container" ]] || { echo 'missing container' >&2; exit 2; }
[[ "$session_bus" == unix:path=* ]] || { echo 'invalid session bus' >&2; exit 2; }
[[ "$collection" == /org/freedesktop/secrets/collection/* ]] || {
  echo 'invalid collection path' >&2
  exit 2
}

docker exec -u codex "$container" env DBUS_SESSION_BUS_ADDRESS="$session_bus" \
  dbus-send --session --print-reply \
    --dest=org.freedesktop.secrets \
    "$collection" \
    org.freedesktop.DBus.Properties.Get \
    string:org.freedesktop.Secret.Collection \
    string:Locked \
  | grep -F 'boolean false' >/dev/null

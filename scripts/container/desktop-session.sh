#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/home/codex
export USER=codex
export LOGNAME=codex
export DISPLAY="${DISPLAY:-:1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-codex}"

screen_width="${SCREEN_WIDTH:-1920}"
screen_height="${SCREEN_HEIGHT:-1080}"
screen_depth="${SCREEN_DEPTH:-24}"

mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"

cleanup() {
  local code=$?
  trap - EXIT INT TERM
  if [[ -n "${session_pid:-}" ]]; then kill "$session_pid" 2>/dev/null || true; fi
  if [[ -n "${xvfb_pid:-}" ]]; then kill "$xvfb_pid" 2>/dev/null || true; fi
  wait 2>/dev/null || true
  exit "$code"
}
trap cleanup EXIT INT TERM

Xvfb "$DISPLAY" \
  -screen 0 "${screen_width}x${screen_height}x${screen_depth}" \
  -nolisten tcp \
  -ac &
xvfb_pid=$!

for _ in $(seq 1 100); do
  if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  echo "[desktop-session] Xvfb did not become ready" >&2
  exit 1
fi

# Keep one shared D-Bus session for Openbox, CE and helper apps.
dbus-run-session -- /opt/workstation/bin/desktop-session-inner.sh &
session_pid=$!
wait "$session_pid"

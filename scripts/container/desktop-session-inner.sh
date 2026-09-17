#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/home/codex
export USER=codex
export LOGNAME=codex
export DISPLAY="${DISPLAY:-:1}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-codex}"

vnc_auth_file="${VNC_AUTH_FILE:-/home/codex/.config/workstation/vnc.pass}"
novnc_port="${NOVNC_PORT:-6080}"
keyring_password_file="${KEYRING_PASSWORD_FILE:-/run/workstation/keyring-password}"

pids=()
cleanup() {
  local code=$?
  trap - EXIT INT TERM
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  exit "$code"
}
trap cleanup EXIT INT TERM

# Openbox anchors the interactive noVNC desktop. Quitting an application must not
# tear down the session, but if Openbox/VNC/websockify dies we restart the whole
# desktop service cleanly through s6 instead of leaving a half-broken session.
openbox-session &
openbox_pid=$!
pids+=("$openbox_pid")

# A small taskbar/launcher makes the otherwise bare Openbox session usable from
# noVNC. The right-click Openbox menu remains available as a second launch path.
if command -v tint2 >/dev/null 2>&1; then
  tint2 -c /etc/xdg/tint2/tint2rc &
  tint2_pid=$!
  pids+=("$tint2_pid")
fi

# Raw VNC stays on container loopback. Only noVNC/websockify is published.
x11vnc \
  -display "$DISPLAY" \
  -forever \
  -shared \
  -localhost \
  -rfbport 5900 \
  -rfbauth "$vnc_auth_file" \
  -noxdamage &
x11vnc_pid=$!
pids+=("$x11vnc_pid")

websockify \
  --web=/usr/share/novnc \
  "0.0.0.0:${novnc_port}" \
  127.0.0.1:5900 &
websockify_pid=$!
pids+=("$websockify_pid")

# Headless Xvfb sessions do not pass through PAM. Reproduce the normal GNOME
# login sequence explicitly: --login receives the login-keyring password and
# keeps it for the not-yet-initialized daemon, then --start completes
# initialization in this D-Bus session. This avoids spawning a second daemon via
# a separate --unlock invocation and keeps CE on the same Secret Service.
if [[ ! -r "$keyring_password_file" ]]; then
  echo "[desktop-session] keyring password file is unavailable: $keyring_password_file" >&2
  exit 1
fi
keyring_password="$(cat "$keyring_password_file")"
if [[ -z "$keyring_password" ]]; then
  echo "[desktop-session] keyring password file is empty" >&2
  exit 1
fi

login_env="$(printf '%s' "$keyring_password" | gnome-keyring-daemon --login --components=secrets)"
unset keyring_password
while IFS= read -r line; do
  case "$line" in
    GNOME_KEYRING_CONTROL=*|SSH_AUTH_SOCK=*) export "$line" ;;
  esac
done <<<"$login_env"
unset login_env

start_env="$(gnome-keyring-daemon --start --components=secrets)"
while IFS= read -r line; do
  case "$line" in
    GNOME_KEYRING_CONTROL=*|SSH_AUTH_SOCK=*) export "$line" ;;
  esac
done <<<"$start_env"
unset start_env

# codex-chatgpt-web is part of the workstation desktop and should come up with
# every desktop session. If it is closed, it can be relaunched from the panel or
# the Openbox right-click menu without restarting the container. Track the PID
# only for desktop-session cleanup; its normal exit does not control the session.
if command -v codex-web-gpt >/dev/null 2>&1; then
  codex-web-gpt &
  codex_web_pid=$!
  pids+=("$codex_web_pid")
else
  echo "[desktop-session] codex-web-gpt launcher is unavailable; continuing with CE only" >&2
fi

# ChatGPT Community starts automatically, but it is not the desktop lifetime
# anchor. Quit therefore closes only CE; /usr/local/bin/chatgpt-ce, the panel
# launcher, or the Openbox menu can start it again in the same session. As with
# Codex Web GPT, keep its PID only so a desktop-service restart cannot leave an
# orphaned old instance behind.
/usr/local/bin/chatgpt-ce &
ce_pid=$!
pids+=("$ce_pid")

# Any critical desktop-substrate exit means the session is degraded. End this
# longrun so s6 restarts Xvfb/Openbox/VNC as one clean unit. Application exits are
# deliberately not in this wait set.
set +e
wait -n "$openbox_pid" "$x11vnc_pid" "$websockify_pid"
critical_status=$?
set -e
if [[ "$critical_status" -eq 0 ]]; then
  critical_status=1
fi
echo "[desktop-session] critical desktop process exited (status $critical_status); restarting session" >&2
exit "$critical_status"

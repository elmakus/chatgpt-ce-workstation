#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${TINT2_CONFIG:-$REPO_ROOT/rootfs/etc/xdg/tint2/tint2rc}"
screen_width="${SCREEN_WIDTH:-1280}"
screen_height="${SCREEN_HEIGHT:-720}"
display_number="${TEST_DISPLAY_NUMBER:-99}"
display=":${display_number}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

for cmd in Xvfb openbox tint2 xprop xwininfo xterm wmctrl xdpyinfo awk grep sed; do
  command -v "$cmd" >/dev/null || fail "missing runtime dependency: $cmd"
done

[[ -r "$config" ]] || fail "Tint2 config is not readable: $config"
panel_height="$(awk '$1 == "panel_size" && $2 == "=" {print $4; exit}' "$config")"
[[ "$panel_height" =~ ^[0-9]+$ ]] || fail "cannot parse panel height from $config"
expected_work_height=$((screen_height - panel_height))
expected_panel_y=$expected_work_height
if xdpyinfo -display "$display" >/dev/null 2>&1 || [[ -e "/tmp/.X${display_number}-lock" ]]; then
  fail "X display $display is already in use"
fi

tmp_dir="$(mktemp -d)"
pids=()
cleanup() {
  local code=$?
  trap - EXIT INT TERM
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  rm -rf "$tmp_dir"
  exit "$code"
}
trap cleanup EXIT INT TERM

Xvfb "$display" -screen 0 "${screen_width}x${screen_height}x24" -nolisten tcp -ac   >"$tmp_dir/xvfb.log" 2>&1 &
pids+=("$!")

for _ in $(seq 1 50); do
  xdpyinfo -display "$display" >/dev/null 2>&1 && break
  sleep 0.1
done
xdpyinfo -display "$display" >/dev/null 2>&1 || fail "Xvfb did not become ready"
DISPLAY="$display" openbox >"$tmp_dir/openbox.log" 2>&1 &
pids+=("$!")
sleep 0.3

DISPLAY="$display" tint2 -c "$config" >"$tmp_dir/tint2.log" 2>&1 &
pids+=("$!")

panel_id=""
for _ in $(seq 1 50); do
  panel_id="$(DISPLAY="$display" xwininfo -root -tree 2>/dev/null     | awk '/"tint2"/ {print $1; exit}')"
  [[ -n "$panel_id" ]] && break
  sleep 0.1
done
[[ -n "$panel_id" ]] || fail "Tint2 panel window did not appear"

expected_tuple="0,0,${screen_width},${expected_work_height}"
workarea=""
for _ in $(seq 1 50); do
  workarea="$(DISPLAY="$display" xprop -root _NET_WORKAREA 2>/dev/null || true)"
  if WORKAREA="$workarea" EXPECTED="$expected_tuple" python3 - <<'PY'
import os, re, sys
nums = [int(x) for x in re.findall(r'-?\d+', os.environ["WORKAREA"].split("=", 1)[-1])]
expected = [int(x) for x in os.environ["EXPECTED"].split(",")]
sys.exit(0 if nums and len(nums) % 4 == 0 and all(nums[i:i+4] == expected for i in range(0, len(nums), 4)) else 1)
PY
  then
    break
  fi
  sleep 0.1
done
WORKAREA="$workarea" EXPECTED="$expected_tuple" python3 - <<'PY'   || fail "unexpected _NET_WORKAREA: $workarea"
import os, re, sys
nums = [int(x) for x in re.findall(r'-?\d+', os.environ["WORKAREA"].split("=", 1)[-1])]
expected = [int(x) for x in os.environ["EXPECTED"].split(",")]
ok = bool(nums) and len(nums) % 4 == 0 and all(nums[i:i+4] == expected for i in range(0, len(nums), 4))
sys.exit(0 if ok else 1)
PY

panel_props="$(DISPLAY="$display" xprop -id "$panel_id"   _NET_WM_WINDOW_TYPE _NET_WM_STRUT _NET_WM_STRUT_PARTIAL)"
grep -F '_NET_WM_WINDOW_TYPE_DOCK' <<<"$panel_props" >/dev/null   || fail "Tint2 is no longer an EWMH dock"
grep -Eq "_NET_WM_STRUT\(CARDINAL\) = 0, 0, 0, ${panel_height}$" <<<"$panel_props"   || fail "Tint2 bottom strut is not ${panel_height}px"

panel_info="$(DISPLAY="$display" xwininfo -id "$panel_id")"
panel_x="$(awk -F: '/Absolute upper-left X:/ {gsub(/ /, "", $2); print $2}' <<<"$panel_info")"
panel_y="$(awk -F: '/Absolute upper-left Y:/ {gsub(/ /, "", $2); print $2}' <<<"$panel_info")"
panel_width="$(awk -F: '/Width:/ {gsub(/ /, "", $2); print $2; exit}' <<<"$panel_info")"
panel_actual_height="$(awk -F: '/Height:/ {gsub(/ /, "", $2); print $2; exit}' <<<"$panel_info")"
[[ "$panel_x" == "0" ]] || fail "Tint2 x=$panel_x, expected 0"
[[ "$panel_y" == "$expected_panel_y" ]] || fail "Tint2 y=$panel_y, expected $expected_panel_y"
[[ "$panel_width" == "$screen_width" ]] || fail "Tint2 width=$panel_width, expected $screen_width"
[[ "$panel_actual_height" == "$panel_height" ]]   || fail "Tint2 height=$panel_actual_height, expected $panel_height"

probe_title="WORKAREA-PROBE-$$"
DISPLAY="$display" xterm -T "$probe_title" >"$tmp_dir/xterm.log" 2>&1 &
probe_pid=$!
pids+=("$probe_pid")

probe_line=""
for _ in $(seq 1 50); do
  probe_line="$(DISPLAY="$display" wmctrl -lG | grep -F "$probe_title" || true)"
  [[ -n "$probe_line" ]] && break
  sleep 0.1
done
[[ -n "$probe_line" ]] || fail "probe window did not appear"
DISPLAY="$display" wmctrl -r "$probe_title" -b add,maximized_vert,maximized_horz || fail "could not maximize probe window"

for _ in $(seq 1 50); do
  probe_line="$(DISPLAY="$display" wmctrl -lG | grep -F "$probe_title" || true)"
  read -r _window_id _desktop probe_x _probe_y probe_width _probe_height _rest <<<"$probe_line"
  if [[ "$probe_x" == "0" && "$probe_width" == "$screen_width" ]]; then
    break
  fi
  sleep 0.1
done
[[ "$probe_x" == "0" ]] || fail "maximized window x=$probe_x, expected 0"
[[ "$probe_width" == "$screen_width" ]] || fail "maximized window width=$probe_width, expected $screen_width"

echo "DESKTOP_WORKAREA_GREEN ${screen_width}x${screen_height} panel=${panel_height}"

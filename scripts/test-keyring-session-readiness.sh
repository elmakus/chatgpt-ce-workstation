#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

desktop="scripts/container/desktop-session-inner.sh"
health="rootfs/usr/local/bin/workstation-healthcheck"

line_of() {
  local needle="$1"
  grep -nF "$needle" "$desktop" | head -n1 | cut -d: -f1
}

reset_line="$(line_of 'rm -f "$keyring_ready"')"
substrate_line="$(line_of 'openbox-session &')"
helper_line="$(line_of 'python3 /opt/workstation/bin/keyring-passwordless.py "${keyring_args[@]}"')"
ready_line="$(line_of "printf 'keyring-session-ready\\n' > \"\$keyring_ready\"")"
app_line="$(line_of 'if command -v codex-web-gpt >/dev/null 2>&1; then')"

[[ -n "$reset_line" && -n "$substrate_line" && -n "$helper_line" && -n "$ready_line" && -n "$app_line" ]] \
  || fail 'desktop keyring readiness wiring is incomplete'
(( reset_line < substrate_line )) \
  || fail 'session readiness is not cleared before desktop substrate startup'
(( substrate_line < helper_line )) \
  || fail 'test fixture no longer models substrate-before-keyring startup'
(( helper_line < ready_line )) \
  || fail 'keyring readiness is published before helper success'
(( ready_line < app_line )) \
  || fail 'applications start before keyring session readiness is published'

grep -F 'test -f "$keyring_session_ready"' "$health" >/dev/null \
  || fail 'workstation healthcheck does not require keyring session readiness'

tmp="$(mktemp -d /tmp/workstation-keyring-readiness-test.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
for cmd in curl xdpyinfo pgrep; do
  cat > "$tmp/bin/$cmd" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod 0755 "$tmp/bin/$cmd"
done

ready="$tmp/keyring-session-ready"
if env PATH="$tmp/bin:$PATH" KEYRING_SESSION_READY="$ready" bash "$health" >/dev/null 2>&1; then
  fail 'healthcheck passed before keyring session readiness existed'
fi

: > "$ready"
env PATH="$tmp/bin:$PATH" KEYRING_SESSION_READY="$ready" bash "$health" >/dev/null \
  || fail 'healthcheck did not pass after keyring session readiness was published'

echo KEYRING_SESSION_READINESS_TESTS_GREEN

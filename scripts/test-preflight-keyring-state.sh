#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d /tmp/workstation-preflight-keyring-test.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

fakebin="$tmp/bin"
mkdir -p "$fakebin"

cat >"$fakebin/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-u" ]]; then
  echo 0
  exit 0
fi
exec /usr/bin/id "$@"
EOF

cat >"$fakebin/docker" <<'EOF'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
  "compose version"|"compose config")
    exit 0
    ;;
esac
if [[ "${1:-}" == "inspect" ]]; then
  exit 1
fi
echo "unexpected fake docker argv: $*" >&2
exit 99
EOF

chmod +x "$fakebin/id" "$fakebin/docker"

run_case() {
  local name="$1"
  local secret_state="$2"
  local expected_status="$3"
  local root="$tmp/$name"
  local appdata="$root/appdata"
  local projects="$root/projects"
  local output="$root/output"
  local status

  mkdir -p "$appdata/home" "$appdata/secrets" "$projects"

  case "$secret_state" in
    empty)
      : >"$appdata/secrets/keyring-password"
      ;;
    legacy)
      printf 'legacy-migration-credential\n' >"$appdata/secrets/keyring-password"
      ;;
    missing)
      ;;
    *)
      echo "unknown secret state: $secret_state" >&2
      exit 1
      ;;
  esac

  set +e
  PATH="$fakebin:$PATH" \
    APPDATA_ROOT="$appdata" \
    PROJECTS_ROOT="$projects" \
    CONTAINER_NAME="preflight-fixture" \
    bash "$REPO_ROOT/scripts/preflight-host.sh" >"$output" 2>&1
  status=$?
  set -e

  [[ "$status" -eq "$expected_status" ]] || {
    echo "$name: expected status $expected_status, got $status" >&2
    cat "$output" >&2
    exit 1
  }

  if [[ "$expected_status" -eq 0 ]]; then
    grep -F 'HOST_PREFLIGHT_GREEN' "$output" >/dev/null || {
      echo "$name: missing HOST_PREFLIGHT_GREEN" >&2
      cat "$output" >&2
      exit 1
    }
  else
    grep -F 'missing keyring migration placeholder:' "$output" >/dev/null || {
      echo "$name: missing expected placeholder failure" >&2
      cat "$output" >&2
      exit 1
    }
  fi
}

run_case empty_placeholder empty 0
run_case legacy_credential legacy 0
run_case missing_placeholder missing 1

echo "PREFLIGHT_KEYRING_STATE_TESTS_GREEN"

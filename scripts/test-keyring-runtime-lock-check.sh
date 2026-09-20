#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper="$REPO_ROOT/scripts/check-keyring-unlocked.sh"
tmp="$(mktemp -d /tmp/workstation-keyring-lock-check.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/docker" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
state="${FAKE_LOCK_STATE:-false}"
case "$state" in
  false)
    printf '%s\n' 'method return sender=:1.0 -> destination=:1.2 reply_serial=2'
    printf '%s\n' '   variant       boolean false'
    ;;
  true)
    printf '%s\n' 'method return sender=:1.0 -> destination=:1.2 reply_serial=2'
    printf '%s\n' '   variant       boolean true'
    ;;
  malformed)
    printf '%s\n' '(<false>,)'
    ;;
  *)
    exit 64
    ;;
esac
EOF
chmod 0755 "$tmp/docker"

run_helper() {
  env PATH="$tmp:$PATH" FAKE_LOCK_STATE="$1" \
    bash "$helper" container-test unix:path=/tmp/session-bus \
      /org/freedesktop/secrets/collection/login
}

run_helper false
if run_helper true; then
  echo 'locked collection was accepted as unlocked' >&2
  exit 1
fi
if run_helper malformed; then
  echo 'unexpected reply format was accepted as unlocked' >&2
  exit 1
fi
if env PATH="$tmp:$PATH" FAKE_LOCK_STATE=false bash "$helper" \
  container-test not-a-session-bus /org/freedesktop/secrets/collection/login; then
  echo 'invalid D-Bus address was accepted' >&2
  exit 1
fi

echo KEYRING_RUNTIME_LOCK_CHECK_TESTS_GREEN

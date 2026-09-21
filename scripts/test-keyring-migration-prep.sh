#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/container/keyring-migration-lib.sh"

test_backup_precedes_ownership_repair() (
  local tmp home keyring backup marker trace
  tmp="$(mktemp -d /tmp/keyring-prep-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyring="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  trace="$tmp/trace"
  mkdir -p "$keyring" "$(dirname "$marker")"
  printf 'legacy' > "$keyring/login.keyring"
  printf 'failed-v1-extra' > "$keyring/Login.keyring"

  chown() {
    test -f "$backup/login.keyring"
    test -f "$backup/Login.keyring"
    cmp "$keyring/login.keyring" "$backup/login.keyring"
    printf 'chown:%s\n' "$*" >> "$trace"
  }

  prepare_keyring_passwordless_v2 "$home" 99 100 "$marker" "$keyring" "$backup"
  grep -F 'chown:-R 99:100' "$trace" >/dev/null
  cmp "$keyring/login.keyring" "$backup/login.keyring"
  cmp "$keyring/Login.keyring" "$backup/Login.keyring"
)

test_failed_or_interrupted_initial_backup_is_never_published() (
  local tmp home keyring backup marker staging trace
  tmp="$(mktemp -d /tmp/keyring-prep-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyring="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  staging="${backup}.staging"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  trace="$tmp/trace"
  mkdir -p "$keyring" "$(dirname "$marker")"
  printf 'legacy' > "$keyring/login.keyring"
  printf 'failed-v1-extra' > "$keyring/Login.keyring"

  cp() {
    test "$1" = -a
    test "$2" = --
    mkdir -p "$4"
    command cp -- "$3/login.keyring" "$4/login.keyring"
    return 1
  }
  chown() {
    printf 'unexpected-chown:%s\n' "$*" >> "$trace"
    return 99
  }

  if prepare_keyring_passwordless_v2 "$home" 99 100 "$marker" "$keyring" "$backup"; then
    echo "expected failed initial backup" >&2
    return 1
  fi
  test ! -e "$backup"
  test ! -e "$staging"
  test ! -s "$trace"
  grep -Fx 'legacy' "$keyring/login.keyring" >/dev/null
  grep -Fx 'failed-v1-extra' "$keyring/Login.keyring" >/dev/null

  # Model a hard interruption (for example SIGKILL/power loss) that prevented
  # cleanup after a partial staging copy. Retry must discard this unpublished
  # state instead of trusting it as the canonical rollback snapshot.
  mkdir -p "$staging"
  printf 'partial-only' > "$staging/login.keyring"
  unset -f cp
  chown() {
    test -f "$backup/login.keyring"
    test -f "$backup/Login.keyring"
    test ! -e "$staging"
    grep -Fx 'legacy' "$backup/login.keyring" >/dev/null
    grep -Fx 'failed-v1-extra' "$backup/Login.keyring" >/dev/null
    printf 'chown:%s\n' "$*" >> "$trace"
  }

  prepare_keyring_passwordless_v2 "$home" 99 100 "$marker" "$keyring" "$backup"
  grep -F 'chown:-R 99:100' "$trace" >/dev/null
  test ! -e "$staging"
  cmp "$keyring/login.keyring" "$backup/login.keyring"
  cmp "$keyring/Login.keyring" "$backup/Login.keyring"
)

test_existing_backup_is_never_overwritten() (
  local tmp home keyring backup marker
  tmp="$(mktemp -d /tmp/keyring-prep-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyring="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  mkdir -p "$keyring" "$backup" "$(dirname "$marker")"
  printf 'current' > "$keyring/login.keyring"
  printf 'original-backup' > "$backup/login.keyring"

  chown() { :; }

  prepare_keyring_passwordless_v2 "$home" 99 100 "$marker" "$keyring" "$backup"
  grep -Fx 'original-backup' "$backup/login.keyring" >/dev/null
)

test_completed_v2_skips_preparation() (
  local tmp home keyring backup marker
  tmp="$(mktemp -d /tmp/keyring-prep-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyring="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  mkdir -p "$keyring" "$(dirname "$marker")"
  printf 'passwordless-v2\n' > "$marker"
  printf 'current' > "$keyring/login.keyring"

  chown() { echo unexpected-chown >&2; return 1; }

  prepare_keyring_passwordless_v2 "$home" 99 100 "$marker" "$keyring" "$backup"
  test ! -e "$backup"
)

test_backup_precedes_ownership_repair
test_failed_or_interrupted_initial_backup_is_never_published
test_existing_backup_is_never_overwritten
test_completed_v2_skips_preparation

echo KEYRING_MIGRATION_PREP_TESTS_GREEN

#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

trace_line() {
  printf '%s\n' "$*" >> "$TRACE_FILE"
}

assert_trace() {
  local needle="$1"
  grep -Fx "$needle" "$TRACE_FILE" >/dev/null || {
    echo "missing trace line: $needle" >&2
    cat "$TRACE_FILE" >&2
    exit 1
  }
}

assert_no_trace_prefix() {
  local prefix="$1"
  if grep -E "^$prefix" "$TRACE_FILE" >/dev/null; then
    echo "unexpected trace prefix: $prefix" >&2
    cat "$TRACE_FILE" >&2
    exit 1
  fi
}

line_number() {
  local needle="$1"
  grep -n -F -x "$needle" "$TRACE_FILE" | head -n1 | cut -d: -f1
}

assert_order() {
  local first="$1"
  local second="$2"
  local a b
  a="$(line_number "$first")"
  b="$(line_number "$second")"
  [[ -n "$a" && -n "$b" && "$a" -lt "$b" ]] || {
    echo "trace order violation: '$first' must precede '$second'" >&2
    cat "$TRACE_FILE" >&2
    exit 1
  }
}

run_case() (
  local scenario="$1"
  local expected_status="$2"
  local tmp
  tmp="$(mktemp -d /tmp/workstation-update-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  TRACE_FILE="$tmp/trace"
  : > "$TRACE_FILE"

  # Source without executing main, then replace all material external operations
  # with deterministic in-process fakes.
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"

  local fixture_old_id fixture_candidate_id fixture_wrong_id fixture_older_id fixture_resolution_sha
  fixture_old_id="sha256:1111111111111111111111111111111111111111111111111111111111111111"
  fixture_candidate_id="sha256:2222222222222222222222222222222222222222222222222222222222222222"
  fixture_wrong_id="sha256:3333333333333333333333333333333333333333333333333333333333333333"
  fixture_older_id="sha256:4444444444444444444444444444444444444444444444444444444444444444"
  fixture_resolution_sha="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  active_image_id="$fixture_old_id"
  container_present=1
  active_running_state=true
  active_health_state=healthy

  require_tools() { trace_line "tools"; }
  load_local_env() { trace_line "env"; }
  source_validate() {
    trace_line "source-validation"
    [[ "$scenario" != source_fail ]]
  }
  resolve_upstreams() {
    trace_line "resolve"
    printf '{}\n' > "$1"
    [[ "$scenario" != resolver_fail ]]
  }
  render_resolution_env() {
    trace_line "render"
    cp "$1" "$2"
    printf 'export UPSTREAM_RESOLUTION_SHA256=%q\n' "$fixture_resolution_sha"
    printf 'export CANDIDATE_IMAGE_TAG=%q\n' "candidate-test"
  }
  host_preflight() {
    trace_line "host-preflight"
    [[ "$scenario" != preflight_fail ]]
  }
  build_candidate() {
    trace_line "build"
    [[ "$scenario" != build_fail ]]
  }
  candidate_image_ref() {
    trace_line "candidate-ref"
    printf '%s\n' "example/workstation:candidate-test"
  }
  image_id() {
    trace_line "image-id:$1"
    case "$1" in
      example/workstation:candidate-test) printf '%s\n' "$fixture_candidate_id" ;;
      example/workstation:rollback-1111111111111111|example/workstation:candidate-previous|"$fixture_old_id")
        printf '%s\n' "$fixture_old_id"
        ;;
      example/workstation:candidate-old|example/workstation:rollback-4444444444444444)
        printf '%s\n' "$fixture_older_id"
        ;;
      *) return 1 ;;
    esac
  }
  candidate_readback() {
    trace_line "candidate-readback"
    [[ "$scenario" != readback_fail ]]
  }
  current_container_id() {
    trace_line "container-id"
    [[ "$container_present" == 1 ]] || return 0
    printf '%s\n' "container-test"
  }
  container_running_state() {
    trace_line "container-running-state"
    printf '%s\n' "$active_running_state"
  }
  container_health_state() {
    trace_line "container-health-state"
    printf '%s\n' "$active_health_state"
  }
  container_image_id() {
    trace_line "container-image"
    printf '%s\n' "$active_image_id"
  }
  tag_image() {
    trace_line "tag:$2"
    return 0
  }
  list_image_refs() {
    trace_line "cleanup-inventory:$1"
    printf '%s|%s\n' "example/workstation" "candidate-test"
    printf '%s|%s\n' "example/workstation" "rollback-1111111111111111"
    printf '%s|%s\n' "example/workstation" "candidate-previous"
    printf '%s|%s\n' "example/workstation" "candidate-old"
    printf '%s|%s\n' "example/workstation" "rollback-4444444444444444"
    printf '%s|%s\n' "example/other" "candidate-foreign"
  }
  remove_image_ref() {
    trace_line "remove-ref:$1"
    if [[ "$scenario" == cleanup_fail && "$1" == "example/workstation:rollback-4444444444444444" ]]; then
      return 1
    fi
    return 0
  }
  restore_keyring_migration_backup() {
    trace_line "keyring-restore"
    return 0
  }
  finalize_keyring_passwordless_migration() {
    trace_line "keyring-finalize"
    return 0
  }
  recreate_with_tag() {
    trace_line "recreate:$1"
    if [[ "$1" == candidate-test ]]; then
      if [[ "$scenario" == promotion_fail ]]; then
        return 1
      fi
      if [[ "$scenario" == promoted_mismatch ]]; then
        active_image_id="$fixture_wrong_id"
      else
        active_image_id="$fixture_candidate_id"
      fi
      return 0
    fi
    if [[ "$scenario" == rollback_fail ]]; then
      return 1
    fi
    if [[ "$scenario" == rollback_missing ]]; then
      container_present=0
      active_running_state=false
      active_health_state=none
      active_image_id=""
      return 1
    fi
    if [[ "$scenario" == rollback_mismatch ]]; then
      active_image_id="$fixture_wrong_id"
      active_running_state=true
      active_health_state=healthy
      return 0
    fi
    active_image_id="$fixture_old_id"
    active_running_state=true
    active_health_state=healthy
  }
  wait_healthy() {
    trace_line "wait:$active_image_id"
    if [[ "$scenario" == health_fail && "$active_image_id" == "$fixture_candidate_id" ]]; then
      return 1
    fi
    if [[ ( "$scenario" == rollback_fail || "$scenario" == rollback_missing || "$scenario" == rollback_mismatch ) && "$active_image_id" == "$fixture_candidate_id" ]]; then
      active_health_state=unhealthy
      return 1
    fi
    return 0
  }
  verify_runtime() {
    trace_line "verify:$active_image_id"
    if [[ "$scenario" == runtime_fail && "$active_image_id" == "$fixture_candidate_id" ]]; then
      return 1
    fi
    return 0
  }
  write_evidence() {
    trace_line "evidence:$1:$2"
    if [[ "$1" == success ]]; then
      trace_line "cleanup-status:${IMAGE_CLEANUP_STATUS:-}"
      local cleanup_ref
      while IFS= read -r cleanup_ref; do
        [[ -n "$cleanup_ref" ]] && trace_line "cleanup-retained:$cleanup_ref"
      done <<< "${IMAGE_CLEANUP_RETAINED_REFS:-}"
      while IFS= read -r cleanup_ref; do
        [[ -n "$cleanup_ref" ]] && trace_line "cleanup-removed:$cleanup_ref"
      done <<< "${IMAGE_CLEANUP_REMOVED_REFS:-}"
      while IFS= read -r cleanup_ref; do
        [[ -n "$cleanup_ref" ]] && trace_line "cleanup-failed:$cleanup_ref"
      done <<< "${IMAGE_CLEANUP_FAILED_REFS:-}"
    fi
    if [[ "$1" == rollback_failed ]]; then
      trace_line "recovery-evidence:${8:-}:${9:-}:${10:-}:${11:-}:${12:-}"
    fi
  }

  UPDATE_EVIDENCE_FILE="$tmp/evidence.json"

  set +e
  main >"$tmp/stdout" 2>"$tmp/stderr"
  local status=$?
  set -e
  [[ "$status" -eq "$expected_status" ]] || {
    echo "scenario $scenario: expected status $expected_status, got $status" >&2
    cat "$tmp/stdout" >&2
    cat "$tmp/stderr" >&2
    cat "$TRACE_FILE" >&2
    exit 1
  }

  assert_trace "source-validation"
  case "$scenario" in
    source_fail)
      assert_trace "evidence:pre_promotion_failed:source_validation_failed"
      assert_no_trace_prefix 'resolve$'
      assert_no_trace_prefix 'host-preflight$'
      assert_no_trace_prefix 'build$'
      assert_no_trace_prefix 'recreate:'
      ;;
    resolver_fail)
      assert_order "source-validation" "resolve"
      assert_trace "evidence:pre_promotion_failed:upstream_resolution_failed"
      assert_no_trace_prefix 'host-preflight$'
      assert_no_trace_prefix 'build$'
      assert_no_trace_prefix 'recreate:'
      ;;
    preflight_fail)
      assert_order "source-validation" "host-preflight"
      assert_trace "evidence:pre_promotion_failed:host_preflight_failed"
      assert_no_trace_prefix 'build$'
      assert_no_trace_prefix 'recreate:'
      ;;
    build_fail)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      assert_trace "evidence:pre_promotion_failed:candidate_build_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    readback_fail)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      assert_trace "evidence:pre_promotion_failed:candidate_readback_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    success)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-finalize"
      assert_order "verify:$fixture_candidate_id" "cleanup-inventory:example/workstation"
      assert_trace "cleanup-status:success"
      assert_trace "cleanup-retained:example/workstation:candidate-test"
      assert_trace "cleanup-retained:example/workstation:rollback-1111111111111111"
      assert_trace "cleanup-retained:example/workstation:candidate-previous"
      assert_trace "cleanup-removed:example/workstation:candidate-old"
      assert_trace "cleanup-removed:example/workstation:rollback-4444444444444444"
      assert_no_trace_prefix 'remove-ref:example/other:'
      assert_trace "evidence:success:"
      assert_no_trace_prefix 'recreate:rollback-'
      ;;
    cleanup_fail)
      assert_trace "recreate:candidate-test"
      assert_order "verify:$fixture_candidate_id" "cleanup-inventory:example/workstation"
      assert_trace "cleanup-status:warning"
      assert_trace "cleanup-removed:example/workstation:candidate-old"
      assert_trace "cleanup-failed:example/workstation:rollback-4444444444444444"
      assert_trace "evidence:success:"
      assert_no_trace_prefix 'recreate:rollback-'
      ;;
    promotion_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:promotion_failed"
      ;;
    promoted_mismatch)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:promoted_image_mismatch"
      ;;
    health_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:candidate_health_failed"
      ;;
    runtime_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:candidate_runtime_verification_failed"
      ;;
    rollback_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:rollback_failed:candidate_health_failed"
      assert_trace "recovery-evidence:complete:container-test:true:unhealthy:$fixture_candidate_id"
      ;;
    rollback_missing)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:rollback_failed:candidate_health_failed"
      assert_trace "recovery-evidence:container_missing::missing:missing:missing"
      ;;
    rollback_mismatch)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:rollback_failed:candidate_health_failed"
      assert_trace "recovery-evidence:complete:container-test:true:healthy:$fixture_wrong_id"
      ;;
    *)
      echo "unknown scenario: $scenario" >&2
      exit 1
      ;;
  esac

  if [[ "$scenario" != success && "$scenario" != cleanup_fail ]]; then
    assert_no_trace_prefix 'cleanup-inventory:'
    assert_no_trace_prefix 'remove-ref:'
  fi
)

run_case source_fail 1
run_case resolver_fail 1
run_case preflight_fail 1
run_case build_fail 1
run_case readback_fail 1
run_case success 0
run_case cleanup_fail 0
run_case promotion_fail 1
run_case promoted_mismatch 1
run_case health_fail 1
run_case runtime_fail 1
run_case rollback_fail 2
run_case rollback_missing 2
run_case rollback_mismatch 2

test_recovery_evidence_serialization() (
  local tmp
  tmp="$(mktemp -d /tmp/workstation-update-evidence-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  UPDATE_EVIDENCE_FILE="$tmp/evidence.json"
  write_evidence \
    "rollback_failed" "candidate_health_failed" \
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
    "example/workstation:candidate-test" \
    "sha256:2222222222222222222222222222222222222222222222222222222222222222" \
    "sha256:1111111111111111111111111111111111111111111111111111111111111111" \
    "example/workstation:rollback-1111111111111111" \
    "complete" "container-test" "true" "unhealthy" \
    "sha256:2222222222222222222222222222222222222222222222222222222222222222"

  python3 - "$UPDATE_EVIDENCE_FILE" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert payload["status"] == "rollback_failed"
assert payload["recovery_state"] == {
    "readback": "complete",
    "container_id": "container-test",
    "running": "true",
    "health": "unhealthy",
    "image_id": "sha256:2222222222222222222222222222222222222222222222222222222222222222",
}
PY
)

test_recovery_evidence_serialization

test_retention_evidence_serialization() (
  local tmp
  tmp="$(mktemp -d /tmp/workstation-update-retention-evidence-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  UPDATE_EVIDENCE_FILE="$tmp/evidence.json"
  IMAGE_CLEANUP_STATUS="warning"
  IMAGE_CLEANUP_RETAINED_REFS="$(printf '%s\\n%s' "example/workstation:candidate-test" "example/workstation:rollback-1111111111111111")"
  IMAGE_CLEANUP_REMOVED_REFS="example/workstation:candidate-old"
  IMAGE_CLEANUP_FAILED_REFS="example/workstation:rollback-4444444444444444"

  write_evidence \
    "success" "" \
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
    "example/workstation:candidate-test" \
    "sha256:2222222222222222222222222222222222222222222222222222222222222222" \
    "sha256:1111111111111111111111111111111111111111111111111111111111111111" \
    "example/workstation:rollback-1111111111111111"

  python3 - "$UPDATE_EVIDENCE_FILE" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert payload["status"] == "success"
retention = payload["retention"]
assert retention["current_image_id"] == "sha256:" + "2" * 64
assert retention["rollback_image_id"] == "sha256:" + "1" * 64
assert retention["rollback_image"] == "example/workstation:rollback-1111111111111111"
cleanup = retention["image_cleanup"]
assert cleanup["status"] == "warning"
assert cleanup["retained"]["count"] == 2
assert cleanup["removed"]["refs"] == ["example/workstation:candidate-old"]
assert cleanup["failed"]["refs"] == ["example/workstation:rollback-4444444444444444"]
assert cleanup["retained"]["truncated"] is False
PY
)

test_no_global_image_prune_or_force_delete() {
  if grep -Eq 'docker[[:space:]]+(system|image)[[:space:]]+prune' "$REPO_ROOT/scripts/update.sh"; then
    echo "global Docker prune is forbidden" >&2
    exit 1
  fi
  if grep -Eq 'docker[[:space:]]+image[[:space:]]+rm[^#]*(--force|[[:space:]]-f([[:space:]]|$))' "$REPO_ROOT/scripts/update.sh"; then
    echo "forced Docker image deletion is forbidden" >&2
    exit 1
  fi
}

test_retention_evidence_serialization
test_no_global_image_prune_or_force_delete

echo "UPDATE_ORCHESTRATION_TESTS_GREEN"

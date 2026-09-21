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
  candidate_recreate_count=0
  candidate_verify_count=0
  candidate_build_count_file="$tmp/candidate-build-count"
  printf '0\n' > "$candidate_build_count_file"

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
  build_candidate_once() {
    local candidate_build_count
    candidate_build_count="$(cat "$candidate_build_count_file")"
    candidate_build_count=$((candidate_build_count + 1))
    printf '%s\n' "$candidate_build_count" > "$candidate_build_count_file"
    trace_line "build"
    case "$scenario" in
      build_fail)
        return 1
        ;;
      apt_mirror_retry_success)
        if [[ "$candidate_build_count" -lt 3 ]]; then
          echo "Ubuntu InRelease SHA-256 mismatch for archive.ubuntu.com_ubuntu_dists_noble-updates_InRelease" >&2
          return 1
        fi
        ;;
      apt_mirror_retry_exhausted)
        echo "Ubuntu InRelease SHA-256 mismatch for archive.ubuntu.com_ubuntu_dists_noble-updates_InRelease" >&2
        return 1
        ;;
    esac
    return 0
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
  cleanup_workstation_build_cache() {
    BUILD_CACHE_CLEANUP_BUILDER="chatgpt-ce-workstation"
    BUILD_CACHE_CLEANUP_MAX_USED_SPACE="24gb"
    BUILD_CACHE_CLEANUP_RESERVED_SPACE="8gb"
    if [[ "$scenario" == cache_cleanup_fail ]]; then
      BUILD_CACHE_CLEANUP_STATUS="warning"
      trace_line "cache-cleanup:warning"
      return 1
    fi
    BUILD_CACHE_CLEANUP_STATUS="success"
    trace_line "cache-cleanup:success"
    return 0
  }
  restore_keyring_migration_backup() {
    trace_line "keyring-restore"
    [[ "$scenario" != keyring_restore_fail ]]
  }
  finalize_keyring_passwordless_migration() {
    trace_line "keyring-finalize"
    return 0
  }
  recreate_with_tag() {
    trace_line "recreate:$1"
    if [[ "$1" == candidate-test ]]; then
      candidate_recreate_count=$((candidate_recreate_count + 1))
      trace_line "candidate-recreate-count:$candidate_recreate_count"
      if [[ "$scenario" == promotion_fail && "$candidate_recreate_count" -eq 1 ]]; then
        return 1
      fi
      if [[ "$scenario" == persistence_recreate_fail && "$candidate_recreate_count" -eq 2 ]]; then
        return 1
      fi
      if [[ "$scenario" == promoted_mismatch && "$candidate_recreate_count" -eq 1 ]]; then
        active_image_id="$fixture_wrong_id"
      elif [[ "$scenario" == persistence_image_mismatch && "$candidate_recreate_count" -eq 2 ]]; then
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
    if [[ "$scenario" == keyring_restore_fail && "$active_image_id" == "$fixture_candidate_id" ]]; then
      active_health_state=unhealthy
      return 1
    fi
    if [[ "$scenario" == persistence_health_fail && "$active_image_id" == "$fixture_candidate_id" && "$candidate_recreate_count" -eq 2 ]]; then
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
    candidate_verify_count=$((candidate_verify_count + 1))
    trace_line "candidate-verify-count:$candidate_verify_count"
    if [[ "$scenario" == runtime_fail && "$active_image_id" == "$fixture_candidate_id" && "$candidate_verify_count" -eq 1 ]]; then
      return 1
    fi
    if [[ "$scenario" == persistence_runtime_fail && "$active_image_id" == "$fixture_candidate_id" && "$candidate_verify_count" -eq 2 ]]; then
      return 1
    fi
    return 0
  }
  verify_rollback_runtime() {
    local expected_image_id="$1"
    trace_line "verify-rollback:$active_image_id:expected:$expected_image_id"
    [[ "$active_image_id" == "$expected_image_id" ]]
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
      trace_line "cache-status:${BUILD_CACHE_CLEANUP_STATUS:-}"
      trace_line "cache-builder:${BUILD_CACHE_CLEANUP_BUILDER:-}"
      trace_line "cache-max:${BUILD_CACHE_CLEANUP_MAX_USED_SPACE:-}"
      trace_line "cache-reserved:${BUILD_CACHE_CLEANUP_RESERVED_SPACE:-}"
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
      [[ "$(grep -Fxc 'build' "$TRACE_FILE")" -eq 1 ]]
      assert_trace "evidence:pre_promotion_failed:candidate_build_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    apt_mirror_retry_exhausted)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      [[ "$(grep -Fxc 'build' "$TRACE_FILE")" -eq 3 ]]
      assert_trace "evidence:pre_promotion_failed:candidate_build_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    readback_fail)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      assert_trace "evidence:pre_promotion_failed:candidate_readback_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    success|apt_mirror_retry_success)
      assert_order "source-validation" "host-preflight"
      assert_order "host-preflight" "build"
      if [[ "$scenario" == apt_mirror_retry_success ]]; then
        [[ "$(grep -Fxc 'build' "$TRACE_FILE")" -eq 3 ]]
      else
        [[ "$(grep -Fxc 'build' "$TRACE_FILE")" -eq 1 ]]
      fi
      assert_trace "recreate:candidate-test"
      assert_trace "candidate-recreate-count:1"
      assert_trace "candidate-recreate-count:2"
      assert_trace "candidate-verify-count:1"
      assert_trace "candidate-verify-count:2"
      assert_trace "keyring-finalize"
      assert_order "candidate-recreate-count:2" "keyring-finalize"
      assert_order "candidate-verify-count:2" "keyring-finalize"
      assert_order "verify:$fixture_candidate_id" "cleanup-inventory:example/workstation"
      assert_trace "cleanup-status:success"
      assert_trace "cleanup-retained:example/workstation:candidate-test"
      assert_trace "cleanup-retained:example/workstation:rollback-1111111111111111"
      assert_trace "cleanup-removed:example/workstation:candidate-previous"
      assert_trace "cleanup-removed:example/workstation:candidate-old"
      assert_trace "cleanup-removed:example/workstation:rollback-4444444444444444"
      assert_no_trace_prefix 'remove-ref:example/other:'
      assert_order "cleanup-inventory:example/workstation" "cache-cleanup:success"
      assert_trace "cache-status:success"
      assert_trace "cache-builder:chatgpt-ce-workstation"
      assert_trace "cache-max:24gb"
      assert_trace "cache-reserved:8gb"
      assert_trace "evidence:success:"
      assert_no_trace_prefix 'recreate:rollback-'
      ;;
    cleanup_fail)
      assert_trace "recreate:candidate-test"
      assert_order "verify:$fixture_candidate_id" "cleanup-inventory:example/workstation"
      assert_trace "cleanup-status:warning"
      assert_trace "cleanup-removed:example/workstation:candidate-old"
      assert_trace "cleanup-failed:example/workstation:rollback-4444444444444444"
      assert_trace "cache-cleanup:success"
      assert_trace "cache-status:success"
      assert_trace "evidence:success:"
      assert_no_trace_prefix 'recreate:rollback-'
      ;;
    cache_cleanup_fail)
      assert_trace "recreate:candidate-test"
      assert_order "verify:$fixture_candidate_id" "cache-cleanup:warning"
      assert_trace "cleanup-status:success"
      assert_trace "cache-status:warning"
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
      assert_trace "verify:$fixture_candidate_id"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "verify-rollback:$fixture_old_id:expected:$fixture_old_id"
      assert_no_trace_prefix "verify:$fixture_old_id"
      assert_trace "evidence:update_failed_rolled_back:candidate_runtime_verification_failed"
      ;;
    persistence_recreate_fail)
      assert_trace "candidate-recreate-count:2"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:persistence_recreate_failed"
      assert_no_trace_prefix 'keyring-finalize$'
      ;;
    persistence_image_mismatch)
      assert_trace "candidate-recreate-count:2"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:persistence_image_mismatch"
      assert_no_trace_prefix 'keyring-finalize$'
      ;;
    persistence_health_fail)
      assert_trace "candidate-recreate-count:2"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:persistence_health_failed"
      assert_no_trace_prefix 'keyring-finalize$'
      ;;
    persistence_runtime_fail)
      assert_trace "candidate-recreate-count:2"
      assert_trace "candidate-verify-count:2"
      assert_trace "keyring-restore"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:persistence_runtime_verification_failed"
      assert_no_trace_prefix 'keyring-finalize$'
      ;;
    keyring_restore_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "keyring-restore"
      assert_trace "evidence:rollback_failed:keyring_restore_failed:candidate_health_failed"
      assert_trace "recovery-evidence:complete:container-test:true:unhealthy:$fixture_candidate_id"
      assert_no_trace_prefix 'recreate:rollback-'
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

  if [[ "$scenario" != success && "$scenario" != apt_mirror_retry_success && "$scenario" != cleanup_fail && "$scenario" != cache_cleanup_fail ]]; then
    assert_no_trace_prefix 'cleanup-inventory:'
    assert_no_trace_prefix 'remove-ref:'
    assert_no_trace_prefix 'cache-cleanup:'
  fi
)

run_case source_fail 1
run_case resolver_fail 1
run_case preflight_fail 1
run_case build_fail 1
run_case apt_mirror_retry_exhausted 1
run_case readback_fail 1
run_case success 0
run_case apt_mirror_retry_success 0
run_case cleanup_fail 0
run_case cache_cleanup_fail 0
run_case promotion_fail 1
run_case promoted_mismatch 1
run_case health_fail 1
run_case runtime_fail 1
run_case persistence_recreate_fail 1
run_case persistence_image_mismatch 1
run_case persistence_health_fail 1
run_case persistence_runtime_fail 1
run_case keyring_restore_fail 2
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
  IMAGE_CLEANUP_RETAINED_REFS="$(printf '%s\n%s' "example/workstation:candidate-test" "example/workstation:rollback-1111111111111111")"
  IMAGE_CLEANUP_REMOVED_REFS="example/workstation:candidate-old"
  IMAGE_CLEANUP_FAILED_REFS="example/workstation:rollback-4444444444444444"
  BUILD_CACHE_CLEANUP_STATUS="warning"
  BUILD_CACHE_CLEANUP_BUILDER="chatgpt-ce-workstation"
  BUILD_CACHE_CLEANUP_MAX_USED_SPACE="24gb"
  BUILD_CACHE_CLEANUP_RESERVED_SPACE="8gb"

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
build_cache = retention["build_cache_cleanup"]
assert build_cache == {
    "status": "warning",
    "builder": "chatgpt-ce-workstation",
    "driver": "docker-container",
    "max_used_space": "24gb",
    "reserved_space": "8gb",
}
PY
)

test_no_global_image_prune_or_force_delete() {
  if grep -Eq 'docker[[:space:]]+(system|image)[[:space:]]+prune' "$REPO_ROOT/scripts/update.sh" "$REPO_ROOT/scripts/buildkit-cache.sh"; then
    echo "global Docker prune is forbidden" >&2
    exit 1
  fi
  if grep -Eq 'docker[[:space:]]+builder[[:space:]]+prune' "$REPO_ROOT/scripts/update.sh" "$REPO_ROOT/scripts/buildkit-cache.sh"; then
    echo "default Docker builder prune is forbidden" >&2
    exit 1
  fi
  if grep -Eq 'docker[[:space:]]+buildx[[:space:]]+use' "$REPO_ROOT/scripts/build.sh" "$REPO_ROOT/scripts/buildkit-cache.sh"; then
    echo "global Buildx builder selection is forbidden" >&2
    exit 1
  fi
  grep -F 'docker buildx prune' "$REPO_ROOT/scripts/buildkit-cache.sh" >/dev/null \
    || { echo "scoped Buildx prune is missing" >&2; exit 1; }
  grep -F -- '--builder "$name"' "$REPO_ROOT/scripts/buildkit-cache.sh" >/dev/null \
    || { echo "Buildx prune is not explicitly builder-scoped" >&2; exit 1; }
  if grep -Eq 'docker[[:space:]]+image[[:space:]]+rm[^#]*(--force|[[:space:]]-f([[:space:]]|$))' "$REPO_ROOT/scripts/update.sh"; then
    echo "forced Docker image deletion is forbidden" >&2
    exit 1
  fi
}

test_retention_evidence_serialization
test_no_global_image_prune_or_force_delete

test_marker_cleanup_without_backup() (
  local tmp home
  tmp="$(mktemp -d /tmp/workstation-keyring-rollback-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  mkdir -p "$home/.config/workstation"
  : > "$home/.config/workstation/keyring-passwordless-v1"
  : > "$home/.config/workstation/keyring-passwordless-v2"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  APPDATA_ROOT="$tmp"
  restore_keyring_migration_backup

  test ! -e "$home/.config/workstation/keyring-passwordless-v1"
  test ! -e "$home/.config/workstation/keyring-passwordless-v2"
)

test_v2_backup_restore() (
  local tmp home
  tmp="$(mktemp -d /tmp/workstation-keyring-rollback-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  mkdir -p "$home/.local/share/keyrings" "$home/.local/share/keyrings.pre-passwordless-v2" "$home/.config/workstation"
  printf 'candidate-state' > "$home/.local/share/keyrings/state"
  printf 'pre-attempt-state' > "$home/.local/share/keyrings.pre-passwordless-v2/state"
  : > "$home/.config/workstation/keyring-passwordless-v2"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  APPDATA_ROOT="$tmp"
  docker() {
    [[ "$1" == compose && "$2" == stop && "$3" == workstation ]]
  }
  restore_keyring_migration_backup

  grep -Fx 'pre-attempt-state' "$home/.local/share/keyrings/state" >/dev/null
  test ! -d "$home/.local/share/keyrings.pre-passwordless-v2"
  test ! -e "$home/.config/workstation/keyring-passwordless-v2"
)

test_v2_backup_restore_stop_failure_is_fail_closed() (
  local tmp home keyrings backup marker
  tmp="$(mktemp -d /tmp/workstation-keyring-rollback-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyrings="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  mkdir -p "$keyrings" "$backup" "$(dirname "$marker")"
  printf 'candidate-state' > "$keyrings/state"
  printf 'pre-attempt-state' > "$backup/state"
  : > "$marker"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  APPDATA_ROOT="$tmp"
  docker() {
    [[ "$1" == compose && "$2" == stop && "$3" == workstation ]]
    return 1
  }

  if restore_keyring_migration_backup; then
    echo "expected keyring restore to fail when workstation stop fails" >&2
    return 1
  fi

  grep -Fx 'candidate-state' "$keyrings/state" >/dev/null
  grep -Fx 'pre-attempt-state' "$backup/state" >/dev/null
  test -e "$marker"
)

test_v2_backup_restore_filesystem_failure_is_fail_closed() (
  local tmp home keyrings backup marker
  tmp="$(mktemp -d /tmp/workstation-keyring-rollback-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  home="$tmp/home"
  keyrings="$home/.local/share/keyrings"
  backup="$home/.local/share/keyrings.pre-passwordless-v2"
  marker="$home/.config/workstation/keyring-passwordless-v2"
  mkdir -p "$keyrings" "$backup" "$(dirname "$marker")"
  printf 'candidate-state' > "$keyrings/state"
  printf 'pre-attempt-state' > "$backup/state"
  : > "$marker"

  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/update.sh"
  APPDATA_ROOT="$tmp"
  docker() {
    [[ "$1" == compose && "$2" == stop && "$3" == workstation ]]
  }
  rm() {
    if [[ "$1" == -rf && "$2" == -- && "$3" == "$keyrings" ]]; then
      return 1
    fi
    command rm "$@"
  }

  if restore_keyring_migration_backup; then
    echo "expected keyring restore to fail when candidate keyring removal fails" >&2
    return 1
  fi

  grep -Fx 'candidate-state' "$keyrings/state" >/dev/null
  grep -Fx 'pre-attempt-state' "$backup/state" >/dev/null
  test ! -e "$marker"
)

test_marker_cleanup_without_backup
test_v2_backup_restore
test_v2_backup_restore_stop_failure_is_fail_closed
test_v2_backup_restore_filesystem_failure_is_fail_closed

echo "UPDATE_ORCHESTRATION_TESTS_GREEN"

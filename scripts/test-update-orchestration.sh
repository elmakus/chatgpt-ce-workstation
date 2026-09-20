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

  local fixture_old_id fixture_candidate_id fixture_resolution_sha
  fixture_old_id="sha256:1111111111111111111111111111111111111111111111111111111111111111"
  fixture_candidate_id="sha256:2222222222222222222222222222222222222222222222222222222222222222"
  fixture_resolution_sha="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  active_image_id="$fixture_old_id"

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
      "$fixture_old_id") printf '%s\n' "$fixture_old_id" ;;
      *) return 1 ;;
    esac
  }
  candidate_readback() {
    trace_line "candidate-readback"
    [[ "$scenario" != readback_fail ]]
  }
  current_container_id() {
    trace_line "container-id"
    printf '%s\n' "container-test"
  }
  container_running() {
    trace_line "container-running"
    return 0
  }
  container_healthy() {
    trace_line "container-healthy"
    return 0
  }
  container_image_id() {
    trace_line "container-image"
    printf '%s\n' "$active_image_id"
  }
  tag_image() {
    trace_line "tag:$2"
    return 0
  }
  recreate_with_tag() {
    trace_line "recreate:$1"
    if [[ "$1" == candidate-test ]]; then
      active_image_id="$fixture_candidate_id"
      return 0
    fi
    if [[ "$scenario" == rollback_fail ]]; then
      return 1
    fi
    active_image_id="$fixture_old_id"
  }
  wait_healthy() {
    trace_line "wait:$active_image_id"
    if [[ "$scenario" == health_fail && "$active_image_id" == "$fixture_candidate_id" ]]; then
      return 1
    fi
    if [[ "$scenario" == rollback_fail && "$active_image_id" == "$fixture_candidate_id" ]]; then
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

  assert_order "source-validation" "host-preflight"
  if [[ "$scenario" != source_fail && "$scenario" != resolver_fail && "$scenario" != preflight_fail ]]; then
    assert_order "host-preflight" "build"
  fi

  case "$scenario" in
    success)
      assert_trace "recreate:candidate-test"
      assert_trace "evidence:success:"
      assert_no_trace_prefix 'recreate:rollback-'
      ;;
    build_fail)
      assert_trace "evidence:pre_promotion_failed:candidate_build_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    readback_fail)
      assert_trace "evidence:pre_promotion_failed:candidate_readback_failed"
      assert_no_trace_prefix 'recreate:'
      ;;
    health_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:candidate_health_failed"
      ;;
    runtime_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:update_failed_rolled_back:candidate_runtime_verification_failed"
      ;;
    rollback_fail)
      assert_trace "recreate:candidate-test"
      assert_trace "recreate:rollback-1111111111111111"
      assert_trace "evidence:rollback_failed:candidate_health_failed"
      ;;
    *)
      echo "unknown scenario: $scenario" >&2
      exit 1
      ;;
  esac
)

run_case success 0
run_case build_fail 1
run_case readback_fail 1
run_case health_fail 1
run_case runtime_fail 1
run_case rollback_fail 2

echo "UPDATE_ORCHESTRATION_TESTS_GREEN"

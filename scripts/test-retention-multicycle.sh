#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/update.sh"

tmp="$(mktemp -d /tmp/workstation-retention-multicycle.XXXXXX)"
TRACE_FILE="$tmp/trace"
: > "$TRACE_FILE"
CURRENT_LABEL=""
SCENARIO=""
NEXT_TAG=""
NEXT_ID=""
IMAGE_REMOVE_FAIL_REF=""

declare -A REF_TO_ID=()

trace_line() {
  printf '%s|%s\n' "$CURRENT_LABEL" "$*" >> "$TRACE_FILE"
}

make_id() {
  local ch="$1"
  local body=""
  local i
  for ((i = 0; i < 64; i++)); do
    body+="$ch"
  done
  printf 'sha256:%s\n' "$body"
}

reset_retention_globals() {
  IMAGE_CLEANUP_STATUS=""
  IMAGE_CLEANUP_RETAINED_REFS=""
  IMAGE_CLEANUP_REMOVED_REFS=""
  IMAGE_CLEANUP_FAILED_REFS=""
  BUILD_CACHE_CLEANUP_STATUS=""
  BUILD_CACHE_CLEANUP_BUILDER=""
  BUILD_CACHE_CLEANUP_MAX_USED_SPACE=""
  BUILD_CACHE_CLEANUP_RESERVED_SPACE=""
}

require_tools() {
  trace_line "tools"
}

load_local_env() {
  trace_line "env"
}

source_validate() {
  trace_line "source-validation"
}

resolve_upstreams() {
  trace_line "resolve"
  printf '{}\n' > "$1"
}

render_resolution_env() {
  trace_line "render"
  cp "$1" "$2"
  printf 'export UPSTREAM_RESOLUTION_SHA256=%q\n' "${NEXT_ID#sha256:}"
  printf 'export CANDIDATE_IMAGE_TAG=%q\n' "$NEXT_TAG"
}

host_preflight() {
  trace_line "host-preflight"
}

build_candidate() {
  local ref="example/workstation:$NEXT_TAG"
  trace_line "build:$ref"
  REF_TO_ID["$ref"]="$NEXT_ID"
}

candidate_image_ref() {
  trace_line "candidate-ref"
  printf '%s\n' "example/workstation:$NEXT_TAG"
}

image_id() {
  local ref="$1"
  local value
  trace_line "image-id:$ref"
  if [[ -n "${REF_TO_ID[$ref]+x}" ]]; then
    printf '%s\n' "${REF_TO_ID[$ref]}"
    return 0
  fi
  if [[ "$ref" == sha256:* ]]; then
    if [[ "$ACTIVE_IMAGE_ID" == "$ref" ]]; then
      printf '%s\n' "$ref"
      return 0
    fi
    for value in "${REF_TO_ID[@]}"; do
      if [[ "$value" == "$ref" ]]; then
        printf '%s\n' "$ref"
        return 0
      fi
    done
  fi
  return 1
}

candidate_readback() {
  trace_line "candidate-readback"
}

current_container_id() {
  trace_line "container-id"
  printf '%s\n' "container-test"
}

container_running_state() {
  trace_line "container-running-state"
  printf '%s\n' "true"
}

container_health_state() {
  trace_line "container-health-state"
  printf '%s\n' "healthy"
}

container_image_id() {
  trace_line "container-image"
  printf '%s\n' "$ACTIVE_IMAGE_ID"
}

tag_image() {
  local id="$1"
  local ref="$2"
  trace_line "tag:$ref"
  REF_TO_ID["$ref"]="$id"
}

list_image_refs() {
  local requested_repo="$1"
  local ref repo tag
  trace_line "cleanup-inventory:$requested_repo"
  for ref in "${!REF_TO_ID[@]}"; do
    repo="${ref%:*}"
    tag="${ref##*:}"
    printf '%s|%s\n' "$repo" "$tag"
  done | sort
}

remove_image_ref() {
  local ref="$1"
  trace_line "remove-ref:$ref"
  if [[ -n "$IMAGE_REMOVE_FAIL_REF" && "$ref" == "$IMAGE_REMOVE_FAIL_REF" ]]; then
    return 1
  fi
  unset "REF_TO_ID[$ref]"
}

recreate_with_tag() {
  local tag="$1"
  local ref="example/workstation:$tag"
  trace_line "recreate:$tag"
  if [[ "$SCENARIO" == promotion_fail && "$tag" == "$NEXT_TAG" ]]; then
    return 1
  fi
  [[ -n "${REF_TO_ID[$ref]+x}" ]] || return 1
  ACTIVE_IMAGE_ID="${REF_TO_ID[$ref]}"
}

wait_healthy() {
  trace_line "wait:$ACTIVE_IMAGE_ID"
  if [[ "$SCENARIO" == health_fail && "$ACTIVE_IMAGE_ID" == "$NEXT_ID" ]]; then
    return 1
  fi
}

verify_runtime() {
  trace_line "verify:$ACTIVE_IMAGE_ID"
  if [[ "$SCENARIO" == runtime_fail && "$ACTIVE_IMAGE_ID" == "$NEXT_ID" ]]; then
    return 1
  fi
}

verify_rollback_runtime() {
  local expected_image_id="$1"
  trace_line "verify-rollback:$ACTIVE_IMAGE_ID:expected:$expected_image_id"
  [[ "$ACTIVE_IMAGE_ID" == "$expected_image_id" ]]
}

restore_keyring_migration_backup() {
  trace_line "keyring-restore"
}

finalize_keyring_passwordless_migration() {
  trace_line "keyring-finalize"
}

prune_workstation_build_cache() {
  trace_line "cache-prune:$(workstation_builder_name):$(workstation_build_cache_max_used_space):$(workstation_build_cache_reserved_space)"
  if [[ "$SCENARIO" == cache_cleanup_fail ]]; then
    return 1
  fi
}

run_update() {
  local label="$1"
  local scenario="$2"
  local cycle="$3"
  local expected_status="$4"
  local stdout_file="$tmp/$label.stdout"
  local stderr_file="$tmp/$label.stderr"
  local status

  CURRENT_LABEL="$label"
  SCENARIO="$scenario"
  NEXT_TAG="candidate-cycle$cycle"
  NEXT_ID="$(make_id "$cycle")"
  UPDATE_EVIDENCE_FILE="$tmp/$label.json"
  reset_retention_globals
  trace_line "begin"

  set +e
  main >"$stdout_file" 2>"$stderr_file"
  status=$?
  set -e
  cleanup_update_work_dir
  trap 'rm -rf "$tmp"' EXIT

  if [[ "$status" -ne "$expected_status" ]]; then
    echo "$label: expected status $expected_status, got $status" >&2
    cat "$stdout_file" >&2
    cat "$stderr_file" >&2
    exit 1
  fi
}

line_number() {
  local label="$1"
  local event="$2"
  grep -n -F -x "$label|$event" "$TRACE_FILE" | head -n1 | cut -d: -f1
}

assert_order() {
  local label="$1"
  local first="$2"
  local second="$3"
  local a b
  a="$(line_number "$label" "$first")"
  b="$(line_number "$label" "$second")"
  [[ -n "$a" && -n "$b" && "$a" -lt "$b" ]] || {
    echo "$label: expected '$first' before '$second'" >&2
    grep -F "$label|" "$TRACE_FILE" >&2 || true
    exit 1
  }
}

assert_trace() {
  local label="$1"
  local event="$2"
  grep -F -x "$label|$event" "$TRACE_FILE" >/dev/null || {
    echo "$label: missing trace '$event'" >&2
    grep -F "$label|" "$TRACE_FILE" >&2 || true
    exit 1
  }
}

assert_no_cleanup() {
  local label="$1"
  if grep -E "^$label\|(cleanup-inventory:|remove-ref:|cache-prune:)" "$TRACE_FILE" >/dev/null; then
    echo "$label: retention cleanup ran on a failure path" >&2
    grep -F "$label|" "$TRACE_FILE" >&2
    exit 1
  fi
}

assert_no_rollback() {
  local label="$1"
  if grep -E "^$label\|recreate:rollback-" "$TRACE_FILE" >/dev/null; then
    echo "$label: unexpected rollback" >&2
    grep -F "$label|" "$TRACE_FILE" >&2
    exit 1
  fi
}

rollback_ref_for_id() {
  local id="$1"
  local short="${id#sha256:}"
  printf 'example/workstation:rollback-%s\n' "${short:0:16}"
}

assert_lifecycle_refs() {
  local current_ref="$1"
  local rollback_ref="$2"
  local actual expected ref
  actual="$(
    for ref in "${!REF_TO_ID[@]}"; do
      case "$ref" in
        example/workstation:candidate-*|example/workstation:rollback-*) printf '%s\n' "$ref" ;;
      esac
    done | sort
  )"
  expected="$(printf '%s\n%s\n' "$current_ref" "$rollback_ref" | sort)"
  [[ "$actual" == "$expected" ]] || {
    echo "unexpected Workstation lifecycle refs" >&2
    printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$actual" >&2
    exit 1
  }
}

assert_success_evidence() {
  local file="$1"
  local current_id="$2"
  local previous_id="$3"
  local image_status="$4"
  local cache_status="$5"
  python3 - "$file" "$current_id" "$previous_id" "$image_status" "$cache_status" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert payload["status"] == "success"
assert payload["candidate_image_id"] == sys.argv[2]
assert payload["previous_image_id"] == sys.argv[3]
retention = payload["retention"]
assert retention["current_image_id"] == sys.argv[2]
assert retention["rollback_image_id"] == sys.argv[3]
assert retention["image_cleanup"]["status"] == sys.argv[4]
cache = retention["build_cache_cleanup"]
assert cache["status"] == sys.argv[5]
assert cache["builder"] == "chatgpt-ce-workstation"
assert cache["driver"] == "docker-container"
assert cache["max_used_space"] == "24gb"
assert cache["reserved_space"] == "8gb"
PY
}

assert_rollback_evidence() {
  local file="$1"
  local previous_id="$2"
  python3 - "$file" "$previous_id" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert payload["status"] == "update_failed_rolled_back"
assert payload["previous_image_id"] == sys.argv[2]
assert "retention" not in payload
PY
}

id0="$(make_id a)"
id1="$(make_id 1)"
id2="$(make_id 2)"
id3="$(make_id 3)"
id4="$(make_id 4)"
id5="$(make_id 5)"
id6="$(make_id 6)"
id8="$(make_id 8)"
id9="$(make_id 9)"
idf="$(make_id f)"

ACTIVE_IMAGE_ID="$id0"
REF_TO_ID["example/workstation:candidate-bootstrap"]="$id0"
REF_TO_ID["example/workstation:candidate-legacy"]="$id8"
REF_TO_ID["example/workstation:rollback-legacy"]="$id9"
REF_TO_ID["example/workstation:stable"]="$id0"
REF_TO_ID["example/other:candidate-foreign"]="$idf"

run_update cycle1 success 1 0
rollback0="$(rollback_ref_for_id "$id0")"
assert_order cycle1 "verify:$id1" "cleanup-inventory:example/workstation"
assert_order cycle1 "cleanup-inventory:example/workstation" "cache-prune:chatgpt-ce-workstation:24gb:8gb"
assert_no_rollback cycle1
assert_lifecycle_refs "example/workstation:candidate-cycle1" "$rollback0"
assert_success_evidence "$tmp/cycle1.json" "$id1" "$id0" success success

run_update cycle2 success 2 0
rollback1="$(rollback_ref_for_id "$id1")"
assert_order cycle2 "verify:$id2" "cleanup-inventory:example/workstation"
assert_no_rollback cycle2
assert_lifecycle_refs "example/workstation:candidate-cycle2" "$rollback1"
assert_success_evidence "$tmp/cycle2.json" "$id2" "$id1" success success

run_update cycle3 success 3 0
rollback2="$(rollback_ref_for_id "$id2")"
assert_order cycle3 "verify:$id3" "cleanup-inventory:example/workstation"
assert_no_rollback cycle3
assert_lifecycle_refs "example/workstation:candidate-cycle3" "$rollback2"
assert_success_evidence "$tmp/cycle3.json" "$id3" "$id2" success success

run_update runtime-failure runtime_fail 4 1
rollback3="$(rollback_ref_for_id "$id3")"
assert_no_cleanup runtime-failure
assert_trace runtime-failure "keyring-restore"
assert_trace runtime-failure "recreate:${rollback3##*:}"
[[ "$ACTIVE_IMAGE_ID" == "$id3" ]] || {
  echo "runtime failure did not restore exact previous production image" >&2
  exit 1
}
assert_rollback_evidence "$tmp/runtime-failure.json" "$id3"

IMAGE_REMOVE_FAIL_REF="example/workstation:candidate-cycle4"
run_update image-cleanup-warning success 5 0
IMAGE_REMOVE_FAIL_REF=""
assert_order image-cleanup-warning "verify:$id5" "cleanup-inventory:example/workstation"
assert_no_rollback image-cleanup-warning
assert_success_evidence "$tmp/image-cleanup-warning.json" "$id5" "$id3" warning success
[[ -n "${REF_TO_ID[example/workstation:candidate-cycle4]+x}" ]] || {
  echo "image cleanup warning fixture did not preserve the failed stale ref" >&2
  exit 1
}

run_update cache-cleanup-warning cache_cleanup_fail 6 0
rollback5="$(rollback_ref_for_id "$id5")"
assert_order cache-cleanup-warning "verify:$id6" "cleanup-inventory:example/workstation"
assert_order cache-cleanup-warning "cleanup-inventory:example/workstation" "cache-prune:chatgpt-ce-workstation:24gb:8gb"
assert_no_rollback cache-cleanup-warning
assert_lifecycle_refs "example/workstation:candidate-cycle6" "$rollback5"
assert_success_evidence "$tmp/cache-cleanup-warning.json" "$id6" "$id5" success warning

[[ -n "${REF_TO_ID[example/workstation:stable]+x}" ]] || {
  echo "same-repository non-lifecycle ref was removed" >&2
  exit 1
}
[[ -n "${REF_TO_ID[example/other:candidate-foreign]+x}" ]] || {
  echo "foreign-repository ref was removed" >&2
  exit 1
}

if grep -F -- '--no-cache' scripts/build.sh >/dev/null; then
  echo "normal Workstation build path disables BuildKit cache" >&2
  exit 1
fi
grep -F -- '--builder "$builder_name"' scripts/build.sh >/dev/null || {
  echo "normal Workstation build path is not bound to the dedicated builder" >&2
  exit 1
}
if grep -Eq 'docker[[:space:]]+(system|builder)[[:space:]]+prune|docker[[:space:]]+buildx[[:space:]]+use' \
  scripts/update.sh scripts/build.sh scripts/buildkit-cache.sh; then
  echo "global/default cleanup or global builder selection detected" >&2
  exit 1
fi

rm -rf "$tmp"
trap - EXIT

echo "RETENTION_MULTICYCLE_TESTS_GREEN"

#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/buildkit-cache.sh"

run_fixture() (
  local scenario="$1"
  local tmp trace
  tmp="$(mktemp -d /tmp/workstation-buildkit-cache-test.XXXXXX)"
  trap 'rm -rf "$tmp"' EXIT
  trace="$tmp/trace"
  : > "$trace"

  local builder_exists=0
  local builder_driver="docker-container"
  case "$scenario" in
    reuse|prune|prune_override) builder_exists=1 ;;
    conflict|prune_conflict) builder_exists=1; builder_driver="docker" ;;
  esac

  trace_cmd() {
    printf '%s\n' "$*" >> "$trace"
  }

  docker() {
    trace_cmd "docker:$*"
    case "$1 $2" in
      "buildx inspect")
        [[ "$builder_exists" == 1 ]] || return 1
        printf 'Name: %s\nDriver: %s\n' "$3" "$builder_driver"
        ;;
      "buildx create")
        builder_exists=1
        builder_driver="docker-container"
        printf '%s\n' "$4"
        ;;
      "buildx prune")
        return 0
        ;;
      *)
        echo "unexpected fake docker argv: $*" >&2
        return 1
        ;;
    esac
  }

  assert_trace() {
    grep -Fx "$1" "$trace" >/dev/null || {
      echo "missing trace: $1" >&2
      cat "$trace" >&2
      exit 1
    }
  }

  assert_no_trace() {
    if grep -F "$1" "$trace" >/dev/null; then
      echo "unexpected trace containing: $1" >&2
      cat "$trace" >&2
      exit 1
    fi
  }

  case "$scenario" in
    create)
      ensure_workstation_builder
      assert_trace "docker:buildx create --name chatgpt-ce-workstation --driver docker-container"
      assert_no_trace "buildx use"
      ;;
    reuse)
      ensure_workstation_builder
      assert_no_trace "buildx create"
      assert_no_trace "buildx use"
      ;;
    conflict)
      if ensure_workstation_builder; then
        echo "conflicting builder driver must fail closed" >&2
        exit 1
      fi
      assert_no_trace "buildx create"
      ;;
    prune)
      prune_workstation_build_cache
      assert_trace "docker:buildx prune --builder chatgpt-ce-workstation --all --max-used-space 24gb --reserved-space 8gb --force"
      assert_no_trace "docker:builder prune"
      ;;
    prune_override)
      WORKSTATION_BUILDER_NAME="workstation-alt"
      WORKSTATION_BUILD_CACHE_MAX_USED_SPACE="30gb"
      WORKSTATION_BUILD_CACHE_RESERVED_SPACE="10gb"
      prune_workstation_build_cache
      assert_trace "docker:buildx prune --builder workstation-alt --all --max-used-space 30gb --reserved-space 10gb --force"
      ;;
    prune_conflict)
      if prune_workstation_build_cache; then
        echo "cache cleanup with conflicting driver must fail closed" >&2
        exit 1
      fi
      assert_no_trace "buildx prune"
      ;;
    *)
      echo "unknown scenario: $scenario" >&2
      exit 1
      ;;
  esac
)

run_invalid_inputs() (
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/buildkit-cache.sh"
  docker() {
    echo "docker must not be reached for invalid input" >&2
    return 99
  }

  WORKSTATION_BUILDER_NAME="../bad"
  if ensure_workstation_builder; then
    echo "invalid builder name accepted" >&2
    exit 1
  fi

  WORKSTATION_BUILDER_NAME="chatgpt-ce-workstation"
  WORKSTATION_BUILD_CACHE_MAX_USED_SPACE="unbounded"
  if prune_workstation_build_cache; then
    echo "invalid cache max accepted" >&2
    exit 1
  fi
)

run_fixture create
run_fixture reuse
run_fixture conflict
run_fixture prune
run_fixture prune_override
run_fixture prune_conflict
run_invalid_inputs

echo "BUILDKIT_CACHE_TESTS_GREEN"

#!/usr/bin/env bash

WORKSTATION_BUILDER_NAME_DEFAULT="chatgpt-ce-workstation"
WORKSTATION_BUILD_CACHE_MAX_USED_SPACE_DEFAULT="24gb"
WORKSTATION_BUILD_CACHE_RESERVED_SPACE_DEFAULT="8gb"
WORKSTATION_BUILDER_DRIVER="docker-container"

buildkit_cache_fail() {
  echo "FAIL: $*" >&2
  return 1
}

workstation_builder_name() {
  printf '%s\n' "${WORKSTATION_BUILDER_NAME:-$WORKSTATION_BUILDER_NAME_DEFAULT}"
}

workstation_build_cache_max_used_space() {
  printf '%s\n' "${WORKSTATION_BUILD_CACHE_MAX_USED_SPACE:-$WORKSTATION_BUILD_CACHE_MAX_USED_SPACE_DEFAULT}"
}

workstation_build_cache_reserved_space() {
  printf '%s\n' "${WORKSTATION_BUILD_CACHE_RESERVED_SPACE:-$WORKSTATION_BUILD_CACHE_RESERVED_SPACE_DEFAULT}"
}

validate_workstation_builder_name() {
  local name="$1"
  [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || {
    buildkit_cache_fail "invalid Workstation builder name: $name"
    return 1
  }
}

validate_workstation_cache_space() {
  local label="$1"
  local value="$2"
  [[ "$value" =~ ^[0-9]+([kKmMgGtT][bB])?$ ]] || {
    buildkit_cache_fail "invalid $label value: $value"
    return 1
  }
}

builder_driver_from_inspect() {
  awk -F':[[:space:]]*' '/^Driver:/ { print $2; exit }'
}

inspect_workstation_builder_driver() {
  local name="$1"
  local output driver
  output="$(docker buildx inspect "$name" 2>/dev/null)" || return 1
  driver="$(printf '%s\n' "$output" | builder_driver_from_inspect)"
  [[ -n "$driver" ]] || return 1
  printf '%s\n' "$driver"
}

ensure_workstation_builder() {
  local name driver
  name="$(workstation_builder_name)"
  validate_workstation_builder_name "$name" || return 1

  if driver="$(inspect_workstation_builder_driver "$name")"; then
    [[ "$driver" == "$WORKSTATION_BUILDER_DRIVER" ]] || {
      buildkit_cache_fail "builder '$name' uses driver '$driver'; expected '$WORKSTATION_BUILDER_DRIVER'"
      return 1
    }
    return 0
  fi

  docker buildx create --name "$name" --driver "$WORKSTATION_BUILDER_DRIVER" >/dev/null || {
    buildkit_cache_fail "could not create dedicated Workstation builder '$name'"
    return 1
  }

  driver="$(inspect_workstation_builder_driver "$name" || true)"
  [[ "$driver" == "$WORKSTATION_BUILDER_DRIVER" ]] || {
    buildkit_cache_fail "created builder '$name' did not read back driver '$WORKSTATION_BUILDER_DRIVER'"
    return 1
  }
}

prune_workstation_build_cache() {
  local name max_used reserved driver
  name="$(workstation_builder_name)"
  max_used="$(workstation_build_cache_max_used_space)"
  reserved="$(workstation_build_cache_reserved_space)"

  validate_workstation_builder_name "$name" || return 1
  validate_workstation_cache_space "max-used-space" "$max_used" || return 1
  validate_workstation_cache_space "reserved-space" "$reserved" || return 1

  driver="$(inspect_workstation_builder_driver "$name" || true)"
  [[ "$driver" == "$WORKSTATION_BUILDER_DRIVER" ]] || {
    buildkit_cache_fail "refusing cache cleanup for builder '$name' with driver '${driver:-missing}'"
    return 1
  }

  docker buildx prune \
    --builder "$name" \
    --all \
    --max-used-space "$max_used" \
    --reserved-space "$reserved" \
    --force
}

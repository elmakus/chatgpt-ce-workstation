#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

UPDATE_EVIDENCE_FILE="${UPDATE_EVIDENCE_FILE:-$REPO_ROOT/.workstation-update/last-update.json}"
UPDATE_WORK_DIR=""

cleanup_update_work_dir() {
  if [[ -n "${UPDATE_WORK_DIR:-}" ]]; then
    rm -rf "$UPDATE_WORK_DIR"
    UPDATE_WORK_DIR=""
  fi
}

fail() {
  echo "FAIL: $*" >&2
  return 1
}

load_local_env() {
  [[ -f "$REPO_ROOT/.env" ]] || return 0

  local tracked=(
    APPDATA_ROOT PROJECTS_ROOT NOVNC_BIND_IP NOVNC_PORT TZ_VALUE SHM_SIZE
    IMAGE_NAME IMAGE_TAG CONTAINER_NAME CODEX_UID CODEX_GID
    CE_REPOSITORY CE_REF UPSTREAM_CE_COMMIT UPSTREAM_UBUNTU_IMAGE
    UPSTREAM_UBUNTU_BASE_DIGEST UPSTREAM_OPENAI_METADATA_FILE UPSTREAM_ARCH
    AGENT_WORKSPACE_VERSION S6_OVERLAY_VERSION CODEX_CHATGPT_WEB_VERSION
    MUSE_INSTALLER_URL MUSE_INSTALLER_SHA256
    CODEX_CHATGPT_WEB_NATIVE_UPSTREAM INSTALL_GLOBAL_AGENTS
  )
  local name
  declare -A had=()
  declare -A saved=()
  for name in "${tracked[@]}"; do
    if [[ -n "${!name+x}" ]]; then
      had["$name"]=1
      saved["$name"]="${!name}"
    fi
  done

  set -a
  # .env.example is intentionally shell-compatible.
  # shellcheck disable=SC1091
  source "$REPO_ROOT/.env"
  set +a

  for name in "${tracked[@]}"; do
    if [[ "${had[$name]:-0}" == 1 ]]; then
      printf -v "$name" '%s' "${saved[$name]}"
      export "$name"
    fi
  done
}

source_validate() {
  bash scripts/validate-source.sh
}

resolve_upstreams() {
  local output="$1"
  python3 scripts/resolve-upstreams.py --output "$output"
}

render_resolution_env() {
  local resolution="$1"
  local stage="$2"
  python3 scripts/render-build-env.py --resolution "$resolution" --stage "$stage"
}

host_preflight() {
  bash scripts/preflight-host.sh
}

build_candidate() {
  local resolution="$1"
  UPSTREAM_RESOLUTION_FILE="$resolution" IMAGE_TAG="$CANDIDATE_IMAGE_TAG" bash scripts/build.sh
}

candidate_image_ref() {
  IMAGE_TAG="$CANDIDATE_IMAGE_TAG" docker compose config --images | sed -n '1p'
}

image_id() {
  docker image inspect "$1" --format '{{.Id}}'
}

candidate_readback() {
  local image_ref="$1"
  local expected_resolution_sha="$2"
  local resolution_file="$3"
  local label cid embedded embedded_sha

  label="$(docker image inspect "$image_ref" --format '{{ index .Config.Labels "io.chatgpt-ce-workstation.upstream-resolution-sha256" }}')"
  [[ "$label" == "$expected_resolution_sha" ]] || {
    echo "candidate provenance label mismatch" >&2
    return 1
  }

  embedded="$(mktemp /tmp/workstation-embedded-resolution.XXXXXX)"
  cid="$(docker create "$image_ref")" || {
    rm -f "$embedded"
    return 1
  }
  if ! docker cp "$cid:/opt/workstation/upstream-resolution.json" "$embedded"; then
    docker rm -f "$cid" >/dev/null 2>&1 || true
    rm -f "$embedded"
    return 1
  fi
  docker rm -f "$cid" >/dev/null 2>&1 || true

  if ! cmp "$resolution_file" "$embedded"; then
    echo "candidate embedded resolution differs from frozen input" >&2
    rm -f "$embedded"
    return 1
  fi
  embedded_sha="$(sha256sum "$embedded" | awk '{print $1}')"
  rm -f "$embedded"
  [[ "$embedded_sha" == "$expected_resolution_sha" ]] || {
    echo "candidate embedded resolution SHA-256 mismatch" >&2
    return 1
  }
}

current_container_id() {
  docker compose ps -q workstation
}

container_running_state() {
  docker inspect --format='{{.State.Running}}' "$1"
}

container_health_state() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$1"
}

container_running() {
  [[ "$(container_running_state "$1")" == true ]]
}

container_healthy() {
  [[ "$(container_health_state "$1")" == healthy ]]
}

container_image_id() {
  docker inspect --format='{{.Image}}' "$1"
}

tag_image() {
  docker image tag "$1" "$2"
}

recreate_with_tag() {
  local tag="$1"
  IMAGE_TAG="$tag" docker compose up -d --force-recreate --no-build workstation
}

restore_keyring_migration_backup() {
  local appdata_root="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
  local home="${appdata_root%/}/home"
  local keyrings="$home/.local/share/keyrings"
  local backup="$home/.local/share/keyrings.pre-passwordless-v2"
  local marker="$home/.config/workstation/keyring-passwordless-v2"

  local marker_v1="$home/.config/workstation/keyring-passwordless-v1"

  # Failed candidates must never leave completion markers behind, even when a
  # migration backup was not created.
  rm -f "$marker" "$marker_v1"
  [[ -d "$backup" ]] || return 0

  docker compose stop workstation >/dev/null 2>&1 || true
  rm -rf "$keyrings"
  mv "$backup" "$keyrings"
}

finalize_keyring_passwordless_migration() {
  local appdata_root="${APPDATA_ROOT:-/mnt/user/appdata/chatgpt-ce-workstation}"
  local home="${appdata_root%/}/home"
  local backup="$home/.local/share/keyrings.pre-passwordless-v2"
  local marker="$home/.config/workstation/keyring-passwordless-v2"
  local legacy_secret="${appdata_root%/}/secrets/keyring-password"

  [[ -f "$marker" ]] || return 0

  if [[ -e "$legacy_secret" ]]; then
    : > "$legacy_secret"
    chmod 0600 "$legacy_secret"
  fi
  rm -rf "$backup"
  rm -f "$home/.config/workstation/keyring-passwordless-v1"
}

wait_healthy() {
  bash scripts/wait-healthy.sh
}

verify_runtime() {
  bash scripts/verify-runtime.sh
}

verify_rollback_runtime() {
  local expected_image_id="$1"
  bash scripts/verify-rollback-runtime.sh "$expected_image_id"
}

require_tools() {
  command -v docker >/dev/null || { fail "docker is required"; return 1; }
  docker compose version >/dev/null || { fail "Docker Compose v2 is required"; return 1; }
  command -v python3 >/dev/null || { fail "python3 is required"; return 1; }
}

write_evidence() {
  local status="$1"
  local reason="$2"
  local resolution_sha="$3"
  local candidate_ref="$4"
  local candidate_id="$5"
  local previous_id="$6"
  local rollback_ref="$7"
  local recovery_readback="${8:-}"
  local recovery_container_id="${9:-}"
  local recovery_running="${10:-}"
  local recovery_health="${11:-}"
  local recovery_image_id="${12:-}"

  mkdir -p "$(dirname "$UPDATE_EVIDENCE_FILE")"
  python3 - "$UPDATE_EVIDENCE_FILE" "$status" "$reason" "$resolution_sha" \
    "$candidate_ref" "$candidate_id" "$previous_id" "$rollback_ref" \
    "$recovery_readback" "$recovery_container_id" "$recovery_running" \
    "$recovery_health" "$recovery_image_id" <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
payload = {
    "status": sys.argv[2],
    "reason": sys.argv[3] or None,
    "resolution_sha256": sys.argv[4] or None,
    "candidate_image": sys.argv[5] or None,
    "candidate_image_id": sys.argv[6] or None,
    "previous_image_id": sys.argv[7] or None,
    "rollback_image": sys.argv[8] or None,
}
recovery_values = sys.argv[9:14]
if any(recovery_values):
    payload["recovery_state"] = {
        "readback": recovery_values[0] or None,
        "container_id": recovery_values[1] or None,
        "running": recovery_values[2] or None,
        "health": recovery_values[3] or None,
        "image_id": recovery_values[4] or None,
    }
tmp = path.with_name(path.name + ".tmp")
tmp.write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
os.replace(tmp, path)
PY
}

RECOVERY_READBACK_STATE=""
RECOVERY_CONTAINER_ID=""
RECOVERY_RUNNING_STATE=""
RECOVERY_HEALTH_STATE=""
RECOVERY_IMAGE_ID=""

capture_recovery_state() {
  RECOVERY_READBACK_STATE=""
  RECOVERY_CONTAINER_ID=""
  RECOVERY_RUNNING_STATE=""
  RECOVERY_HEALTH_STATE=""
  RECOVERY_IMAGE_ID=""

  local container
  if ! container="$(current_container_id 2>/dev/null)"; then
    RECOVERY_READBACK_STATE="container_lookup_failed"
    RECOVERY_RUNNING_STATE="unknown"
    RECOVERY_HEALTH_STATE="unknown"
    RECOVERY_IMAGE_ID="unknown"
    return 0
  fi

  if [[ -z "$container" ]]; then
    RECOVERY_READBACK_STATE="container_missing"
    RECOVERY_RUNNING_STATE="missing"
    RECOVERY_HEALTH_STATE="missing"
    RECOVERY_IMAGE_ID="missing"
    return 0
  fi

  RECOVERY_CONTAINER_ID="$container"
  local complete=1
  if ! RECOVERY_RUNNING_STATE="$(container_running_state "$container" 2>/dev/null)" || [[ -z "$RECOVERY_RUNNING_STATE" ]]; then
    RECOVERY_RUNNING_STATE="unknown"
    complete=0
  fi
  if ! RECOVERY_HEALTH_STATE="$(container_health_state "$container" 2>/dev/null)" || [[ -z "$RECOVERY_HEALTH_STATE" ]]; then
    RECOVERY_HEALTH_STATE="unknown"
    complete=0
  fi
  if ! RECOVERY_IMAGE_ID="$(container_image_id "$container" 2>/dev/null)" || [[ -z "$RECOVERY_IMAGE_ID" ]]; then
    RECOVERY_IMAGE_ID="unknown"
    complete=0
  fi

  if [[ "$complete" == 1 ]]; then
    RECOVERY_READBACK_STATE="complete"
  else
    RECOVERY_READBACK_STATE="partial"
  fi
}

pre_promotion_failure() {
  local reason="$1"
  local resolution_sha="${2:-}"
  local candidate_ref="${3:-}"
  local candidate_id="${4:-}"
  write_evidence "pre_promotion_failed" "$reason" "$resolution_sha" "$candidate_ref" "$candidate_id" "" ""
  echo "Update stopped before production mutation: $reason" >&2
  return 1
}

rollback_after_failure() {
  local reason="$1"
  local resolution_sha="$2"
  local candidate_ref="$3"
  local candidate_id="$4"
  local previous_image_id="$5"
  local rollback_ref="$6"

  echo "Update failed after promotion attempt: $reason" >&2
  echo "Attempting rollback to exact prior image: $previous_image_id" >&2

  if ! restore_keyring_migration_backup; then
    echo "Failed to restore pre-migration keyring backup before rollback." >&2
    capture_recovery_state
    write_evidence "rollback_failed" "keyring_restore_failed:$reason" "$resolution_sha" \
      "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref" \
      "$RECOVERY_READBACK_STATE" "$RECOVERY_CONTAINER_ID" "$RECOVERY_RUNNING_STATE" \
      "$RECOVERY_HEALTH_STATE" "$RECOVERY_IMAGE_ID" || true
    return 1
  fi

  if recreate_with_tag "${rollback_ref##*:}"; then
    local restored_container restored_image
    restored_container="$(current_container_id || true)"
    if [[ -n "$restored_container" ]] \
      && wait_healthy \
      && verify_rollback_runtime "$previous_image_id"; then
      restored_image="$(container_image_id "$restored_container" || true)"
      if [[ "$restored_image" == "$previous_image_id" ]]; then
        write_evidence "update_failed_rolled_back" "$reason" "$resolution_sha"           "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"
        echo "Update failed; previous production image was restored and verified." >&2
        return 0
      fi
      echo "Rollback image mismatch: expected $previous_image_id, got ${restored_image:-<missing>}" >&2
    fi
  fi

  capture_recovery_state
  if ! write_evidence "rollback_failed" "$reason" "$resolution_sha" \
    "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref" \
    "$RECOVERY_READBACK_STATE" "$RECOVERY_CONTAINER_ID" "$RECOVERY_RUNNING_STATE" \
    "$RECOVERY_HEALTH_STATE" "$RECOVERY_IMAGE_ID"; then
    echo "WARNING: failed to persist rollback-failure evidence." >&2
  fi
  echo "ROLLBACK FAILED." >&2
  echo "previous_image_id=$previous_image_id" >&2
  echo "rollback_image=$rollback_ref" >&2
  echo "candidate_image_id=$candidate_id" >&2
  echo "recovery_readback=$RECOVERY_READBACK_STATE" >&2
  echo "current_container_id=${RECOVERY_CONTAINER_ID:-<missing>}" >&2
  echo "current_running=${RECOVERY_RUNNING_STATE:-unknown}" >&2
  echo "current_health=${RECOVERY_HEALTH_STATE:-unknown}" >&2
  echo "current_image_id=${RECOVERY_IMAGE_ID:-unknown}" >&2
  return 1
}

main() {
  require_tools || return 1

  load_local_env

  local work_dir resolution_file env_file staged_resolution
  local resolution_sha candidate_tag candidate_ref candidate_id
  local previous_container previous_image_id rollback_ref repository
  UPDATE_WORK_DIR="$(mktemp -d /tmp/workstation-update.XXXXXX)"
  work_dir="$UPDATE_WORK_DIR"
  resolution_file="$work_dir/upstream-resolution.json"
  env_file="$work_dir/build-env.sh"
  staged_resolution="$work_dir/canonical-upstream-resolution.json"
  trap cleanup_update_work_dir EXIT

  echo '=== source validation ==='
  if ! source_validate; then
    pre_promotion_failure "source_validation_failed"
    return 1
  fi

  echo
  echo '=== resolve and freeze upstreams ==='
  if ! resolve_upstreams "$resolution_file"; then
    pre_promotion_failure "upstream_resolution_failed"
    return 1
  fi
  if ! render_resolution_env "$resolution_file" "$staged_resolution" > "$env_file"; then
    pre_promotion_failure "resolution_render_failed"
    return 1
  fi
  # The renderer emits a fixed allowlist of shell-quoted, non-secret values.
  # shellcheck disable=SC1090
  source "$env_file"
  resolution_sha="$UPSTREAM_RESOLUTION_SHA256"
  candidate_tag="$CANDIDATE_IMAGE_TAG"
  export IMAGE_TAG="$candidate_tag"
  if ! cmp "$resolution_file" "$staged_resolution"; then
    pre_promotion_failure "resolution_not_canonical" "$resolution_sha"
    return 1
  fi
  echo "Frozen resolution SHA-256: $resolution_sha"

  echo
  echo '=== host preflight ==='
  if ! host_preflight; then
    pre_promotion_failure "host_preflight_failed" "$resolution_sha"
    return 1
  fi

  echo
  echo '=== exact candidate build ==='
  if ! build_candidate "$resolution_file"; then
    pre_promotion_failure "candidate_build_failed" "$resolution_sha"
    return 1
  fi

  candidate_ref="$(candidate_image_ref || true)"
  [[ -n "$candidate_ref" ]] || {
    pre_promotion_failure "candidate_reference_missing" "$resolution_sha"
    return 1
  }
  candidate_id="$(image_id "$candidate_ref" || true)"
  [[ "$candidate_id" == sha256:* ]] || {
    pre_promotion_failure "candidate_image_identity_missing" "$resolution_sha" "$candidate_ref"
    return 1
  }
  if ! candidate_readback "$candidate_ref" "$resolution_sha" "$resolution_file"; then
    pre_promotion_failure "candidate_readback_failed" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  fi

  echo
  echo '=== capture rollback baseline ==='
  previous_container="$(current_container_id || true)"
  [[ -n "$previous_container" ]] || {
    pre_promotion_failure "production_container_missing" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  }
  if ! container_running "$previous_container" || ! container_healthy "$previous_container"; then
    pre_promotion_failure "production_not_known_working" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  fi
  previous_image_id="$(container_image_id "$previous_container" || true)"
  [[ "$previous_image_id" == sha256:* ]] || {
    pre_promotion_failure "previous_image_identity_missing" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  }
  image_id "$previous_image_id" >/dev/null || {
    pre_promotion_failure "previous_image_unavailable" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  }

  repository="${candidate_ref%:*}"
  [[ "$repository" != "$candidate_ref" ]] || {
    pre_promotion_failure "candidate_repository_unusable" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  }
  local previous_short
  previous_short="${previous_image_id#sha256:}"
  previous_short="${previous_short:0:16}"
  rollback_ref="$repository:rollback-$previous_short"
  if ! tag_image "$previous_image_id" "$rollback_ref"; then
    pre_promotion_failure "rollback_tag_failed" "$resolution_sha" "$candidate_ref" "$candidate_id"
    return 1
  fi

  write_evidence "ready_to_promote" "" "$resolution_sha" "$candidate_ref" "$candidate_id"     "$previous_image_id" "$rollback_ref"

  echo
  echo '=== promote exact candidate ==='
  if ! recreate_with_tag "$candidate_tag"; then
    if rollback_after_failure "promotion_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  local promoted_container promoted_image
  promoted_container="$(current_container_id || true)"
  promoted_image=""
  [[ -n "$promoted_container" ]] && promoted_image="$(container_image_id "$promoted_container" || true)"
  if [[ "$promoted_image" != "$candidate_id" ]]; then
    if rollback_after_failure "promoted_image_mismatch" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  if ! wait_healthy; then
    if rollback_after_failure "candidate_health_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  if ! verify_runtime; then
    if rollback_after_failure "candidate_runtime_verification_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  echo
  echo '=== verify passwordless persistence after recreate ==='
  if ! recreate_with_tag "$candidate_tag"; then
    if rollback_after_failure "persistence_recreate_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  promoted_container="$(current_container_id || true)"
  promoted_image=""
  [[ -n "$promoted_container" ]] && promoted_image="$(container_image_id "$promoted_container" || true)"
  if [[ "$promoted_image" != "$candidate_id" ]]; then
    if rollback_after_failure "persistence_image_mismatch" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  if ! wait_healthy; then
    if rollback_after_failure "persistence_health_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  if ! verify_runtime; then
    if rollback_after_failure "persistence_runtime_verification_failed" "$resolution_sha" "$candidate_ref" "$candidate_id" "$previous_image_id" "$rollback_ref"; then
      return 1
    fi
    return 2
  fi

  if ! finalize_keyring_passwordless_migration; then
    echo "WARNING: candidate is healthy but keyring migration cleanup was incomplete." >&2
  fi

  write_evidence "success" "" "$resolution_sha" "$candidate_ref" "$candidate_id"     "$previous_image_id" "$rollback_ref"
  echo
  echo "Update complete on exact candidate: $candidate_id"
  echo "Resolution SHA-256: $resolution_sha"
  echo "Rollback baseline retained as: $rollback_ref"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

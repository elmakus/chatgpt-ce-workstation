#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

case "$(uname -m)" in
  x86_64|amd64) ;;
  *)
    echo "This workstation candidate targets x86_64/amd64 because codex-chatgpt-web currently ships Linux x64." >&2
    exit 1
    ;;
esac

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

resolution_file="${UPSTREAM_RESOLUTION_FILE:-${1:-}}"
[[ -n "$resolution_file" && -f "$resolution_file" ]] || {
  echo "Usage: UPSTREAM_RESOLUTION_FILE=/path/to/upstream-resolution.json scripts/build.sh" >&2
  echo "Resolve/freeze upstreams first; build.sh never resolves latest on its own." >&2
  exit 1
}

stage_dir="$REPO_ROOT/.workstation-build"
env_file="$(mktemp /tmp/workstation-build-env.XXXXXX)"
cleanup() {
  rm -f "$env_file"
  rm -rf "$stage_dir"
}
trap cleanup EXIT HUP INT TERM
rm -rf "$stage_dir"
mkdir -p "$stage_dir"

python3 scripts/render-build-env.py   --resolution "$resolution_file"   --stage "$stage_dir/upstream-resolution.json" > "$env_file"
# The renderer emits only a fixed allowlist of shell-quoted, non-secret values.
# shellcheck disable=SC1090
source "$env_file"

export IMAGE_TAG="${IMAGE_TAG:-$CANDIDATE_IMAGE_TAG}"

echo "Validating workstation source"
bash scripts/validate-source.sh

echo "Building exact candidate $IMAGE_TAG through compose.yaml"
docker compose build --pull workstation

image_ref="$(docker compose config --images | sed -n '1p')"
[[ -n "$image_ref" ]] || { echo "could not resolve candidate image reference" >&2; exit 1; }
actual_resolution_sha="$(
  docker image inspect "$image_ref"     --format '{{ index .Config.Labels "io.chatgpt-ce-workstation.upstream-resolution-sha256" }}'
)"
[[ "$actual_resolution_sha" == "$UPSTREAM_RESOLUTION_SHA256" ]] || {
  echo "candidate provenance label mismatch" >&2
  echo "expected: $UPSTREAM_RESOLUTION_SHA256" >&2
  echo "actual:   ${actual_resolution_sha:-<empty>}" >&2
  exit 1
}

echo
echo "Exact candidate image: $image_ref"
echo "Upstream resolution SHA-256: $UPSTREAM_RESOLUTION_SHA256"
docker compose images workstation

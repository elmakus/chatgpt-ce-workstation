#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RECREATE=0
if [[ "${1:-}" == "--recreate" ]]; then
  RECREATE=1
elif [[ -n "${1:-}" ]]; then
  echo "Usage: bash scripts/run.sh [--recreate]" >&2
  exit 2
fi

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required" >&2; exit 1; }
docker compose config >/dev/null

args=(up -d workstation)
if [[ "$RECREATE" -eq 1 ]]; then
  args=(up -d --force-recreate workstation)
fi

docker compose "${args[@]}"

echo "Started workstation through compose.yaml"
binding="$(docker compose port workstation 6080 2>/dev/null | head -n 1 || true)"
if [[ -n "$binding" ]]; then
  echo "noVNC published as: $binding"
else
  echo "noVNC container port: 6080 (check compose.yaml/.env for host binding)"
fi
echo "Logs: docker compose logs -f workstation"

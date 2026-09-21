#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

timeout_seconds="${WAIT_TIMEOUT_SECONDS:-180}"
interval_seconds=2
deadline=$((SECONDS + timeout_seconds))
last_status='container-missing'

while (( SECONDS < deadline )); do
  container="$(docker compose ps -q workstation 2>/dev/null || true)"
  if [[ -n "$container" ]]; then
    last_status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || true)"
    case "$last_status" in
      healthy)
        echo 'health: healthy'
        exit 0
        ;;
      unhealthy)
        echo 'health: unhealthy' >&2
        docker compose logs --tail=120 workstation >&2 || true
        exit 1
        ;;
    esac
  else
    last_status='container-missing'
  fi
  sleep "$interval_seconds"
done

echo "Timed out waiting for healthy workstation after ${timeout_seconds}s (last status: ${last_status:-unknown})." >&2
docker compose logs --tail=120 workstation >&2 || true
exit 1

#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

case "$(uname -m)" in
  x86_64|amd64) ;;
  *)
    echo "This v1 workstation targets x86_64/amd64 because codex-chatgpt-web currently ships Linux x64." >&2
    exit 1
    ;;
esac

command -v docker >/dev/null || { echo "docker is required" >&2; exit 1; }
docker compose version >/dev/null || { echo "Docker Compose v2 is required" >&2; exit 1; }

echo "Validating workstation source"
bash scripts/validate-source.sh

echo "Building workstation through compose.yaml"
echo "Compose will resolve shell variables, .env values, and tracked defaults."
docker compose build --pull workstation

echo
docker compose images workstation

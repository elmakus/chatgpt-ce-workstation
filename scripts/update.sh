#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# --pull only refreshes base-image metadata; it does not invalidate cached RUN
# steps that clone/fetch remote projects. This token deliberately changes for
# an explicit update so CE and codex-chatgpt-web remote-source layers rebuild.
# A caller can still provide an explicit UPSTREAM_REFRESH value if desired.
export UPSTREAM_REFRESH="${UPSTREAM_REFRESH:-$(date -u +%Y%m%dT%H%M%SZ)}"

echo "Rebuilding workstation image with upstream refresh token: $UPSTREAM_REFRESH"
bash scripts/build.sh

echo "Recreating workstation with the same persistent mounts..."
bash scripts/run.sh --recreate

echo "Waiting for the desktop substrate to become healthy..."
bash scripts/wait-healthy.sh

echo "Verifying mounts, launchers and write access..."
bash scripts/verify-runtime.sh

echo "Update complete. Verify CE login/Remote and routed models only when the update changed those upstream components."

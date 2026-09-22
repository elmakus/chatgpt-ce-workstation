#!/usr/bin/env bash
set -Eeuo pipefail

helper="/usr/local/bin/workstation-opencodex-live-a"
[[ -x "$helper" ]] || {
  echo "FAIL: installed OPH-LIVE-A helper missing" >&2
  exit 1
}

LIVE_A_HELPER="$helper" bash /tmp/test-opencodex-live-a.sh

echo "OPENCODEX_LIVE_A_RUNTIME_GREEN"

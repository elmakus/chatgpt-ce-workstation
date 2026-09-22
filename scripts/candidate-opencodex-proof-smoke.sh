#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/tmp/oph-proof-user
mkdir -p "$HOME/.codex" "$HOME/.opencodex"
printf production-codex >"$HOME/.codex/sentinel"
printf production-opencodex >"$HOME/.opencodex/sentinel"
before_codex="$(sha256sum "$HOME/.codex/sentinel" | awk '{print $1}')"
before_ocx="$(sha256sum "$HOME/.opencodex/sentinel" | awk '{print $1}')"

proof=/usr/local/bin/workstation-opencodex-proof
"$proof" start >/tmp/oph-start.log 2>&1 &
starter=$!
healthy=0
for _ in $(seq 1 30); do
  if "$proof" health >/tmp/oph-health.json 2>/dev/null; then
    healthy=1
    break
  fi
  if ! kill -0 "$starter" >/dev/null 2>&1; then
    cat /tmp/oph-start.log >&2
    exit 1
  fi
  sleep 1
done
test "$healthy" -eq 1
"$proof" status >/tmp/oph-status.txt
"$proof" stop >/tmp/oph-stop.log 2>&1
wait "$starter" || true

test "$(sha256sum "$HOME/.codex/sentinel" | awk '{print $1}')" = "$before_codex"
test "$(sha256sum "$HOME/.opencodex/sentinel" | awk '{print $1}')" = "$before_ocx"
test -d "$HOME/.local/state/chatgpt-ce-workstation/opencodex-proof/opencodex"
test -d "$HOME/.local/state/chatgpt-ce-workstation/opencodex-proof/codex-home"

echo "OPENCODEX_PROOF_RUNTIME_GREEN"

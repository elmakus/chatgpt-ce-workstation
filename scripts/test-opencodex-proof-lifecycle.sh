#!/usr/bin/env bash
set -Eeuo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
script="rootfs/usr/local/bin/workstation-opencodex-proof"
bash -n "$script" || fail "proof lifecycle shell syntax"

tmp="$(mktemp -d)"
home="$tmp/home"
mkdir -p "$home"
export HOME="$home"

paths="$("$script" paths)"
expected_root="$home/.local/state/chatgpt-ce-workstation/opencodex-proof"
grep -F "OPENCODEX_HOME=$expected_root/opencodex" <<<"$paths" >/dev/null || fail "default OpenCodex proof home"
grep -F "CODEX_HOME=$expected_root/codex-home" <<<"$paths" >/dev/null || fail "default Codex proof home"
grep -F "PORT=10170" <<<"$paths" >/dev/null || fail "default proof port"

grep -F 'env OPENCODEX_HOME="$proof_home" CODEX_HOME="$proof_codex_home" ocx "$@"' "$script" >/dev/null || fail "lifecycle calls are not fenced by both homes"
grep -F 'run_ocx start --port "$proof_port"' "$script" >/dev/null || fail "start is not fenced"
grep -F 'run_ocx stop' "$script" >/dev/null || fail "stop is not fenced"
grep -F 'run_ocx health --json' "$script" >/dev/null || fail "health is not fenced"
grep -F 'run_ocx status' "$script" >/dev/null || fail "status is not fenced"

if OPENCODEX_PROOF_HOME="$home/.opencodex" "$script" paths >/dev/null 2>&1; then
  fail "production OpenCodex home alias accepted"
fi
if OPENCODEX_PROOF_CODEX_HOME="$home/.codex" "$script" paths >/dev/null 2>&1; then
  fail "production Codex home alias accepted"
fi
if OPENCODEX_PROOF_HOME="$home/.opencodex/proof" "$script" paths >/dev/null 2>&1; then
  fail "nested production OpenCodex home accepted"
fi
if OPENCODEX_PROOF_CODEX_HOME="$home/.codex/proof" "$script" paths >/dev/null 2>&1; then
  fail "nested production Codex home accepted"
fi
if OPENCODEX_PROOF_PORT=0 "$script" paths >/dev/null 2>&1; then
  fail "invalid proof port accepted"
fi

if grep -E 'ocx[[:space:]]+(init|service|ensure|codex-shim)' "$script" >/dev/null; then
  fail "proof helper contains forbidden lifecycle operation"
fi

echo "OK: isolated OpenCodex proof lifecycle contract"

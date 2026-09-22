#!/usr/bin/env bash
set -Eeuo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

helper="${LIVE_A_HELPER:-rootfs/usr/local/bin/workstation-opencodex-live-a}"
[[ -s "$helper" ]] || fail "live-a helper missing"
bash -n "$helper" || fail "live-a helper syntax"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fake_curl="$tmp/fake-curl"
log="$tmp/curl.log"

cat >"$fake_curl" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
url=""
payload=""
method="GET"
while (($#)); do
  case "$1" in
    --data-binary)
      payload="${2:-}"
      shift 2
      ;;
    --request)
      method="${2:-}"
      shift 2
      ;;
    http://*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

[[ "$url" == http://127.0.0.1:10170/* ]] || {
  echo "unexpected URL: $url" >&2
  exit 90
}
printf '%s %s\n' "$method" "$url" >>"${FAKE_CURL_LOG:?}"

case "$url" in
  http://127.0.0.1:10170/healthz)
    printf '%s\n' '{"ok":true,"version":"2.59.0"}'
    ;;
  http://127.0.0.1:10170/v1/models)
    printf '%s\n' '{"object":"list","data":[{"id":"cliproxyapi/proof-model"},{"id":"codex-lb/proof-model"},{"id":"chatgpt-web/chatgpt-web/proof-model"},{"id":"meta-muse/muse-spark-1.3"}]}'
    ;;
  http://127.0.0.1:10170/v1/responses)
    [[ "$method" == "POST" ]] || exit 91
    python3 -c '
import json, sys
body=json.loads(sys.argv[1])
assert body == {
  "model": "codex-lb/proof-model",
  "input": "Reply with exactly: OPH-LIVE-A OK",
  "stream": False,
}
' "$payload"
    if [[ "${FAKE_CURL_MODE:-}" == "malformed-response" ]]; then
      printf '%s\n' '{"object":"response","output":"not-a-list"}'
    else
      printf '%s\n' '{"object":"response","output":[{"type":"message","content":[{"type":"output_text","text":"OPH-LIVE-A OK"}]}]}'
    fi
    ;;
  *)
    exit 92
    ;;
esac
SH
chmod 0755 "$fake_curl"

export OPH_LIVE_A_CURL_BIN="$fake_curl"
export FAKE_CURL_LOG="$log"

health="$(bash "$helper" health)"
grep -F '"ok":true' <<<"$health" >/dev/null || fail "health result missing"

models="$(bash bash "$helper" models)"
expected_models=$'chatgpt-web/chatgpt-web/proof-model\ncliproxyapi/proof-model\ncodex-lb/proof-model\nmeta-muse/muse-spark-1.3'
[[ "$models" == "$expected_models" ]] || fail "model catalog was not normalized deterministically"

[[ "$(bash "$helper" model codex-lb/proof-model)" == "codex-lb/proof-model" ]] ||
  fail "exact model lookup failed"
if bash "$helper" model codex-lb/missing >/dev/null 2>&1; then
  fail "missing exact model was accepted"
fi
if bash "$helper" model gpt-5.6-sol >/dev/null 2>&1; then
  fail "bare model id was accepted"
fi
if bash "$helper" model 'codex-lb/bad id' >/dev/null 2>&1; then
  fail "model id with whitespace was accepted"
fi

[[ "$(bash "$helper" response codex-lb/proof-model)" == "OPH-LIVE-A_RESPONSE_GREEN" ]] ||
  fail "harmless response smoke failed"
if FAKE_CURL_MODE=malformed-response bash "$helper" response codex-lb/proof-model >/dev/null 2>&1; then
  fail "malformed Responses payload was accepted"
fi

if OPENCODEX_PROOF_PORT=0 bash "$helper" health >/dev/null 2>&1; then
  fail "invalid proof port was accepted"
fi
if bash "$helper" health extra >/dev/null 2>&1; then
  fail "extra health argument was accepted"
fi

if grep -Eiq 'authorization|api[_-]?key|cookie|password|secret' "$helper"; then
  fail "live-a helper contains a credential-bearing interface"
fi
if grep -Eq 'openai_base_url|model_catalog_json|ocx[[:space:]]+(init|start|service|codex-shim)' "$helper"; then
  fail "live-a helper contains route takeover or lifecycle mutation"
fi
if grep -vE '^(GET|POST) http://127\.0\.0\.1:10170/(healthz|v1/models|v1/responses)$' "$log" | grep -q .; then
  fail "fake transport observed a non-loopback or unexpected endpoint"
fi

echo "OK: isolated OpenCodex OPH-LIVE-A probe contract"

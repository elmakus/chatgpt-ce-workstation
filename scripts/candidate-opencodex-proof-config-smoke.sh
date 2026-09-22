#!/usr/bin/env bash
set -Eeuo pipefail

helper="${OPENCODEX_PROOF_CONFIG_HELPER:-/usr/local/bin/workstation-opencodex-proof-config}"
command -v ocx >/dev/null
[[ -x "$helper" ]]

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
mkdir -p "$HOME/.codex" "$HOME/.opencodex"
printf 'production-codex-sentinel\n' >"$HOME/.codex/sentinel"
printf 'production-opencodex-sentinel\n' >"$HOME/.opencodex/sentinel"
before_codex="$(sha256sum "$HOME/.codex/sentinel" | awk '{print $1}')"
before_ocx="$(sha256sum "$HOME/.opencodex/sentinel" | awk '{print $1}')"

spec="$tmp/spec.json"
cat >"$spec" <<'JSON'
{
  "version": 1,
  "providers": {
    "codex-lb": {
      "adapter": "openai-responses",
      "baseUrl": "http://127.0.0.1:18741/v1",
      "models": ["oph-codex-proof"],
      "allowPrivateNetwork": true
    },
    "cliproxyapi": {
      "adapter": "openai-chat",
      "baseUrl": "http://127.0.0.1:8317/v1",
      "models": ["oph-cliproxy-proof"],
      "allowPrivateNetwork": true
    },
    "chatgpt-web": {
      "adapter": "openai-responses",
      "baseUrl": "http://127.0.0.1:18080/v1",
      "models": ["chatgpt-web/oph-browser-proof"],
      "allowPrivateNetwork": true
    }
  }
}
JSON

config="$tmp/provider-proof.json"
"$helper" render --spec "$spec" --output "$config" --disposable >/dev/null
set +e
validation="$("$helper" validate --config "$config" --disposable 2>&1)"
validation_rc=$?
set -e
if (( validation_rc != 0 )); then
  printf '%s\n' "$validation" >&2
  exit "$validation_rc"
fi
printf '%s\n' "$validation" | grep -F '"ok":true' >/dev/null

python3 - "$config" <<'PY'
import json, pathlib, sys
cfg=json.loads(pathlib.Path(sys.argv[1]).read_text())
assert sorted(cfg["providers"]) == ["chatgpt-web", "cliproxyapi", "codex-lb", "meta-muse"]
assert cfg["providers"]["meta-muse"]["authMode"] == "oauth"
assert cfg["providers"]["meta-muse"]["headers"] == {"x-api-version": "1.0.0"}
assert cfg["codexNativeInjection"] is False
assert cfg["codexNativeSteering"] is False
PY

after_codex="$(sha256sum "$HOME/.codex/sentinel" | awk '{print $1}')"
after_ocx="$(sha256sum "$HOME/.opencodex/sentinel" | awk '{print $1}')"
[[ "$before_codex" == "$after_codex" ]]
[[ "$before_ocx" == "$after_ocx" ]]

echo "OPENCODEX_PROOF_CONFIG_RUNTIME_GREEN"

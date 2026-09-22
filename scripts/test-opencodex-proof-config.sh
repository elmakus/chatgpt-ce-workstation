#!/usr/bin/env bash
set -Eeuo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }
helper="rootfs/usr/local/bin/workstation-opencodex-proof-config"

python3 -m py_compile "$helper" || fail "proof config helper Python syntax"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
mkdir -p "$home"
export HOME="$home"

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

out1="$tmp/config-1.json"
out2="$tmp/config-2.json"
"$helper" render --spec "$spec" --output "$out1" --disposable >/dev/null
"$helper" render --spec "$spec" --output "$out2" --disposable >/dev/null
cmp "$out1" "$out2" >/dev/null || fail "identical inputs did not render byte-identical output"

python3 - "$out1" <<'PY'
import json
import pathlib
import sys

cfg = json.loads(pathlib.Path(sys.argv[1]).read_text())
expected = {"codex-lb", "cliproxyapi", "chatgpt-web", "meta-muse"}
if set(cfg["providers"]) != expected:
    raise SystemExit("provider ids are not deterministic")
if cfg["defaultProvider"] != "codex-lb":
    raise SystemExit("unexpected default provider")
if cfg.get("codexNativeInjection") is not False or cfg.get("codexNativeSteering") is not False:
    raise SystemExit("Codex injection/steering are not explicitly disabled")
meta = cfg["providers"]["meta-muse"]
if meta["adapter"] != "openai-responses" or meta["authMode"] != "oauth":
    raise SystemExit("meta-muse transport/auth mismatch")
if meta["headers"] != {"x-api-version": "1.0.0"}:
    raise SystemExit("meta-muse static header mismatch")
if meta["models"] != ["muse-spark-1.3", "muse-spark-1.3-contributor"]:
    raise SystemExit("meta-muse model seed mismatch")

secret_names = {
    "apikey", "key", "token", "password", "secret",
    "accesstoken", "refreshtoken", "idtoken", "clientsecret",
}
def walk(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key.lower().replace("_", "") in secret_names:
                raise SystemExit(f"secret-bearing output field: {key}")
            walk(child)
    elif isinstance(value, list):
        for child in value:
            walk(child)
walk(cfg)
PY

[[ "$(stat -c '%a' "$out1")" == "600" ]] || fail "rendered config mode is not 0600"

bad_spec="$tmp/bad-secret.json"
python3 - "$spec" "$bad_spec" <<'PY'
import json, pathlib, sys
data=json.loads(pathlib.Path(sys.argv[1]).read_text())
data["providers"]["codex-lb"]["apiKey"]="not-a-real-secret"
pathlib.Path(sys.argv[2]).write_text(json.dumps(data))
PY
if "$helper" render --spec "$bad_spec" --output "$tmp/bad.json" --disposable >/dev/null 2>&1; then
  fail "secret-bearing provider input was accepted"
fi

bad_private="$tmp/bad-private.json"
python3 - "$spec" "$bad_private" <<'PY'
import json, pathlib, sys
data=json.loads(pathlib.Path(sys.argv[1]).read_text())
data["providers"]["codex-lb"]["allowPrivateNetwork"]=False
pathlib.Path(sys.argv[2]).write_text(json.dumps(data))
PY
if "$helper" render --spec "$bad_private" --output "$tmp/bad-private-out.json" --disposable >/dev/null 2>&1; then
  fail "private endpoint without explicit opt-in was accepted"
fi

bad_adapter="$tmp/bad-adapter.json"
python3 - "$spec" "$bad_adapter" <<'PY'
import json, pathlib, sys
data=json.loads(pathlib.Path(sys.argv[1]).read_text())
data["providers"]["cliproxyapi"]["adapter"]="anthropic"
pathlib.Path(sys.argv[2]).write_text(json.dumps(data))
PY
if "$helper" render --spec "$bad_adapter" --output "$tmp/bad-adapter-out.json" --disposable >/dev/null 2>&1; then
  fail "unsupported proof adapter was accepted"
fi

if "$helper" render --spec "$spec" --output "$home/.opencodex/config.json" --disposable >/dev/null 2>&1; then
  fail "production OpenCodex config path was accepted"
fi
if "$helper" render --spec "$spec" --output "$tmp/no-disposable.json" >/dev/null 2>&1; then
  fail "outside-proof output was accepted without --disposable"
fi

fake_bin="$tmp/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/ocx" <<'SH'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'OPENCODEX_HOME=%s\nCODEX_HOME=%s\nARGS=%s\n' "$OPENCODEX_HOME" "$CODEX_HOME" "$*" >"$OCX_PROOF_LOG"
printf '{"ok":true}\n'
SH
chmod 0755 "$fake_bin/ocx"
export PATH="$fake_bin:$PATH"
export OCX_PROOF_LOG="$tmp/ocx.log"
"$helper" validate --config "$out1" --disposable >/dev/null
grep -F "OPENCODEX_HOME=$home/.local/state/chatgpt-ce-workstation/opencodex-proof/opencodex" "$OCX_PROOF_LOG" >/dev/null   || fail "validate did not fence OPENCODEX_HOME"
grep -F "CODEX_HOME=$home/.local/state/chatgpt-ce-workstation/opencodex-proof/codex-home" "$OCX_PROOF_LOG" >/dev/null   || fail "validate did not fence CODEX_HOME"
grep -F "ARGS=config validate $out1 --json" "$OCX_PROOF_LOG" >/dev/null   || fail "validate did not use bounded offline ocx config validate"

echo "OK: isolated OpenCodex provider proof configuration"

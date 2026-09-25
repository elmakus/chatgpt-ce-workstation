#!/usr/bin/env bash
set -Eeuo pipefail

repository="miuuyy/codex-chatgpt-web"
version="${CODEX_CHATGPT_WEB_UPSTREAM_VERSION:-}"
expected_sha="${CODEX_CHATGPT_WEB_UPSTREAM_SHA256:-}"
install_root="${CODEX_CHATGPT_WEB_UPSTREAM_INSTALL_ROOT:-/opt/codex-chatgpt-web-upstream}"
bin_path="${CODEX_CHATGPT_WEB_UPSTREAM_BIN:-/usr/local/bin/codex-chatgpt-web-upstream}"

[[ -n "$version" ]] || { echo "CODEX_CHATGPT_WEB_UPSTREAM_VERSION is required" >&2; exit 1; }
[[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] || {
  echo "CODEX_CHATGPT_WEB_UPSTREAM_SHA256 must be 64 lowercase hex" >&2
  exit 1
}

asset="codex-web-gpt-$version-linux-x64.AppImage"
url="https://github.com/$repository/releases/download/v$version/$asset"
tmp="$(mktemp -d /tmp/codex-web-gpt-upstream.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 900 "$url" -o "$tmp/$asset"
echo "$expected_sha  $tmp/$asset" | sha256sum -c -

chmod 0755 "$tmp/$asset"
mkdir -p "$tmp/extract"
(
  cd "$tmp/extract"
  "$tmp/$asset" --appimage-extract >/dev/null
)

mapfile -t manifests < <(find "$tmp/extract/squashfs-root" -type f -path '*/resources/runtime/manifest.json' -print)
[[ "${#manifests[@]}" -eq 1 ]] || {
  echo "Expected exactly one packaged upstream runtime manifest, found ${#manifests[@]}" >&2
  exit 1
}
runtime_root="$(dirname "${manifests[0]}")"
python3 - "$runtime_root/manifest.json" "$version" <<'PY'
import json
import pathlib
import sys
manifest = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
if manifest.get("schemaVersion") != 2:
    raise SystemExit("unexpected upstream runtime manifest schema")
if manifest.get("appVersion") != sys.argv[2]:
    raise SystemExit("upstream runtime appVersion mismatch")
if manifest.get("platform") != "linux" or manifest.get("arch") not in {"x64", "amd64"}:
    raise SystemExit("upstream runtime platform/arch mismatch")
if manifest.get("launcher") != "bin/codex-chatgpt-web":
    raise SystemExit("unexpected upstream runtime launcher")
PY
[[ -x "$runtime_root/bin/codex-chatgpt-web" ]] || {
  echo "Upstream runtime launcher is missing/not executable" >&2
  exit 1
}

target="$install_root/$version"
rm -rf "$target"
mkdir -p "$install_root" "$(dirname "$bin_path")"
cp -a "$runtime_root" "$target"
ln -sfn "$target/bin/codex-chatgpt-web" "$bin_path"

"$bin_path" --version | grep -F "$version" >/dev/null

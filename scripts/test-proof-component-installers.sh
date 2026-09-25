#!/usr/bin/env bash
set -Eeuo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

for file in scripts/build/install-opencodex.sh scripts/build/install-codex-web-gpt-upstream.sh; do
  bash -n "$file" || fail "shell syntax: $file"
done

grep -F 'package="@bitkyc08/opencodex"' scripts/build/install-opencodex.sh >/dev/null   || fail 'OpenCodex installer is not pinned to the accepted package'
grep -F 'npm view "$package@$version" dist.integrity' scripts/build/install-opencodex.sh >/dev/null   || fail 'OpenCodex installer does not read back npm integrity'
grep -F 'npm view "$package@$version" dist.shasum' scripts/build/install-opencodex.sh >/dev/null   || fail 'OpenCodex installer does not read back npm shasum'
grep -F 'repository="miuuyy/codex-chatgpt-web"' scripts/build/install-codex-web-gpt-upstream.sh >/dev/null   || fail 'upstream browser proof installer is not bound to canonical upstream'
grep -F 'sha256sum -c -' scripts/build/install-codex-web-gpt-upstream.sh >/dev/null   || fail 'upstream browser proof installer does not verify the frozen asset hash'
grep -F '/opt/codex-chatgpt-web-upstream' scripts/build/install-codex-web-gpt-upstream.sh >/dev/null   || fail 'upstream browser proof runtime is not isolated from production install'
grep -F '/usr/local/bin/codex-chatgpt-web-upstream' scripts/build/install-codex-web-gpt-upstream.sh >/dev/null   || fail 'upstream browser proof runtime lacks its distinct executable'

if grep -E 'ocx[[:space:]]+(init|start)|openai_base_url|model_catalog_json'     scripts/build/install-opencodex.sh scripts/build/install-codex-web-gpt-upstream.sh >/dev/null; then
  fail 'proof installers contain route-takeover behavior'
fi

echo 'OK: frozen proof component installer contracts'

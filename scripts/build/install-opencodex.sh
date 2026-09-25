#!/usr/bin/env bash
set -Eeuo pipefail

package="@bitkyc08/opencodex"
version="${OPENCODEX_VERSION:-}"
integrity="${OPENCODEX_INTEGRITY:-}"
shasum="${OPENCODEX_SHASUM:-}"

[[ -n "$version" ]] || { echo "OPENCODEX_VERSION is required" >&2; exit 1; }
[[ "$integrity" == sha512-* ]] || { echo "OPENCODEX_INTEGRITY must be sha512 integrity" >&2; exit 1; }
[[ "$shasum" =~ ^[0-9a-f]{40}$ ]] || { echo "OPENCODEX_SHASUM must be 40 lowercase hex" >&2; exit 1; }

actual_integrity="$(npm view "$package@$version" dist.integrity)"
actual_shasum="$(npm view "$package@$version" dist.shasum)"
[[ "$actual_integrity" == "$integrity" ]] || {
  echo "OpenCodex npm integrity mismatch" >&2
  exit 1
}
[[ "$actual_shasum" == "$shasum" ]] || {
  echo "OpenCodex npm shasum mismatch" >&2
  exit 1
}

npm install -g "$package@$version"
npm_root="$(npm root -g)"
installed="$(node -p "require('$npm_root/@bitkyc08/opencodex/package.json').version")"
[[ "$installed" == "$version" ]] || {
  echo "OpenCodex installed version mismatch: expected $version got $installed" >&2
  exit 1
}
command -v ocx >/dev/null
ocx --version | grep -F "$version" >/dev/null

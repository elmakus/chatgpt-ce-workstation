#!/usr/bin/env bash
set -Eeuo pipefail

expected="${1:-}"
[[ "$expected" =~ ^sha256:[0-9a-f]{64}$ ]] || {
  echo "invalid expected Ubuntu APT identity: ${expected:-<empty>}" >&2
  exit 1
}

rows=""
found=0
for file in /var/lib/apt/lists/*_InRelease; do
  [[ -f "$file" ]] || continue
  # Google Chrome is added later and is not part of the Ubuntu package-set identity.
  [[ "$(basename "$file")" == dl_google_com_* ]] && continue
  found=1
  rows+="$(basename "$file")"$'\t'"$(sha256sum "$file" | awk '{print $1}')"$'\n'
done
[[ "$found" -eq 1 ]] || {
  echo "no Ubuntu InRelease metadata found" >&2
  exit 1
}

actual="sha256:$(printf '%s' "$rows" | LC_ALL=C sort | sha256sum | awk '{print $1}')"

[[ "$actual" == "$expected" ]] || {
  echo "Ubuntu APT identity mismatch" >&2
  echo "expected: $expected" >&2
  echo "actual:   $actual" >&2
  exit 1
}

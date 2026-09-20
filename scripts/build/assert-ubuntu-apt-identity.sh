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

actual="$(printf '%s' "$rows" | python3 -c '
import hashlib, json, sys
items = []
for line in sys.stdin:
    name, digest = line.rstrip("\n").split("\t", 1)
    items.append({"name": name, "sha256": digest})
items.sort(key=lambda item: item["name"])
payload = json.dumps(items, sort_keys=True, separators=(",", ":")).encode()
print("sha256:" + hashlib.sha256(payload).hexdigest())
')"

[[ "$actual" == "$expected" ]] || {
  echo "Ubuntu APT identity mismatch" >&2
  echo "expected: $expected" >&2
  echo "actual:   $actual" >&2
  exit 1
}

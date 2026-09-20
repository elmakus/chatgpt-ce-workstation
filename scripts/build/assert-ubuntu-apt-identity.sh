#!/usr/bin/env bash
set -Eeuo pipefail

expected_identity="${1:-}"
expected_indexes="${2:-}"

[[ "$expected_identity" =~ ^sha256:[0-9a-f]{64}$ ]] || {
  echo "invalid expected Ubuntu APT identity: ${expected_identity:-<empty>}" >&2
  exit 1
}
[[ -n "$expected_indexes" ]] || {
  echo "exact frozen Ubuntu InRelease index set is required" >&2
  exit 1
}

rows=""
expected_names=""
IFS=';' read -r -a entries <<< "$expected_indexes"
for entry in "${entries[@]}"; do
  [[ "$entry" == *=* ]] || {
    echo "invalid Ubuntu InRelease entry: $entry" >&2
    exit 1
  }
  name="${entry%%=*}"
  expected_sha="${entry#*=}"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "unsafe Ubuntu InRelease filename: $name" >&2
    exit 1
  }
  [[ "$expected_sha" =~ ^[0-9a-f]{64}$ ]] || {
    echo "invalid Ubuntu InRelease SHA-256 for $name" >&2
    exit 1
  }
  file="/var/lib/apt/lists/$name"
  [[ -f "$file" ]] || {
    echo "frozen Ubuntu InRelease is missing: $name" >&2
    exit 1
  }
  actual_sha="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual_sha" == "$expected_sha" ]] || {
    echo "Ubuntu InRelease SHA-256 mismatch for $name" >&2
    echo "expected: $expected_sha" >&2
    echo "actual:   $actual_sha" >&2
    exit 1
  }
  rows+="$name"$'\t'"$actual_sha"$'\n'
  expected_names+="$name"$'\n'
done

# Ignore third-party repositories added by build dependencies (for example
# NodeSource and Google), but reject any newly appearing Ubuntu source because
# the updater froze the complete Ubuntu InRelease set before candidate build.
actual_ubuntu_names=""
for file in /var/lib/apt/lists/*_InRelease; do
  [[ -f "$file" ]] || continue
  name="$(basename "$file")"
  [[ "$name" == *_ubuntu_dists_* ]] || continue
  actual_ubuntu_names+="$name"$'\n'
done

sorted_expected_names="$(printf '%s' "$expected_names" | LC_ALL=C sort -u)"
sorted_actual_names="$(printf '%s' "$actual_ubuntu_names" | LC_ALL=C sort -u)"
[[ "$sorted_actual_names" == "$sorted_expected_names" ]] || {
  echo "Ubuntu InRelease set differs from frozen resolution" >&2
  echo "expected names:" >&2
  printf '%s\n' "$sorted_expected_names" >&2
  echo "actual names:" >&2
  printf '%s\n' "$sorted_actual_names" >&2
  exit 1
}

actual_identity="sha256:$(printf '%s' "$rows" | LC_ALL=C sort | sha256sum | awk '{print $1}')"
[[ "$actual_identity" == "$expected_identity" ]] || {
  echo "Ubuntu APT identity mismatch" >&2
  echo "expected: $expected_identity" >&2
  echo "actual:   $actual_identity" >&2
  exit 1
}

#!/usr/bin/env bash
set -Eeuo pipefail

installer_url="${MUSE_INSTALLER_URL:-https://dev.meta.ai/install.sh}"
expected_sha256="${MUSE_INSTALLER_SHA256:-}"
expected_version="${MUSE_EXPECTED_VERSION:-}"
install_dir="/opt/muse-code/bin"
tmp_dir="$(mktemp -d /tmp/muse-code.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

[[ "$installer_url" == https://* ]] || { echo "Muse installer URL must use HTTPS" >&2; exit 1; }
[[ "$expected_sha256" =~ ^[0-9a-f]{64}$ ]] || { echo "Exact Muse installer SHA-256 is required" >&2; exit 1; }
[[ -n "$expected_version" && ! "$expected_version" =~ [^0-9A-Za-z._+-] ]] || { echo "Exact Muse stable release id is required" >&2; exit 1; }

installer="$tmp_dir/install.sh"
build_home="$tmp_dir/home"

curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 120   "$installer_url" -o "$installer"
actual_sha256="$(sha256sum "$installer" | awk '{print $1}')"
printf 'Muse installer SHA-256: %s\n' "$actual_sha256"

[[ "$actual_sha256" == "$expected_sha256" ]] || {
  echo "Muse installer SHA-256 mismatch" >&2
  echo "expected: $expected_sha256" >&2
  echo "actual:   $actual_sha256" >&2
  exit 1
}

codex_group="$(id -g codex)"
install -d -m 0755 -o codex -g "$codex_group" "$install_dir" "$build_home"
chown codex:"$codex_group" "$tmp_dir" "$installer"
chmod 0700 "$tmp_dir"
chmod 0755 "$installer"

runuser -u codex -- env   HOME="$build_home"   USER=codex   LOGNAME=codex   MUSE_INSTALL_DIR="$install_dir"   MUSE_NO_MODIFY_PATH=1   MUSE_LOGIN=0   MUSE_SYNC_UPDATE=1   bash "$installer"

[[ -x "$install_dir/muse" ]] || {
  echo "Muse installer did not create the expected executable: $install_dir/muse" >&2
  exit 1
}

installed_version="$(
  runuser -u codex -- env     HOME="$build_home"     USER=codex     LOGNAME=codex     MUSE_INSTALL_DIR="$install_dir"     MUSE_NO_MODIFY_PATH=1     MUSE_LOGIN=0     MUSE_SYNC_UPDATE=1     "$install_dir/muse" --version
)"
printf '%s\n' "$installed_version"
grep -F "$expected_version" <<<"$installed_version" >/dev/null || {
  echo "Muse stable channel moved after frozen resolution" >&2
  echo "expected release id: $expected_version" >&2
  echo "installed output: $installed_version" >&2
  exit 1
}

chown -R root:root /opt/muse-code
find /opt/muse-code -type d -exec chmod 0755 {} +
find /opt/muse-code -type f -perm /111 -exec chmod 0755 {} +

printf 'Muse Code installed under %s\n' "$install_dir"

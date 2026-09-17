#!/usr/bin/env bash
set -Eeuo pipefail

installer_url="${MUSE_INSTALLER_URL:-https://dev.meta.ai/install.sh}"
expected_sha256="${MUSE_INSTALLER_SHA256:-}"
install_dir="/opt/muse-code/bin"
tmp_dir="$(mktemp -d /tmp/muse-code.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

installer="$tmp_dir/install.sh"
build_home="$tmp_dir/home"

curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 120 \
  "$installer_url" -o "$installer"
actual_sha256="$(sha256sum "$installer" | awk '{print $1}')"
printf 'Muse installer SHA-256: %s\n' "$actual_sha256"

if [[ -n "$expected_sha256" && "$actual_sha256" != "$expected_sha256" ]]; then
  echo "Muse installer SHA-256 mismatch" >&2
  echo "expected: $expected_sha256" >&2
  echo "actual:   $actual_sha256" >&2
  exit 1
fi

codex_group="$(id -g codex)"
install -d -m 0755 -o codex -g "$codex_group" "$install_dir" "$build_home"
chown codex:"$codex_group" "$installer"
chmod 0755 "$installer"

# Keep all installer/user state out of the image's /home/codex because that path
# is replaced by the persistent home bind at runtime. Only the application files
# below /opt/muse-code are intended to survive from this build step.
runuser -u codex -- env \
  HOME="$build_home" \
  USER=codex \
  LOGNAME=codex \
  MUSE_INSTALL_DIR="$install_dir" \
  MUSE_NO_MODIFY_PATH=1 \
  MUSE_SYNC_UPDATE=1 \
  bash "$installer"

[[ -x "$install_dir/muse" ]] || {
  echo "Muse installer did not create the expected executable: $install_dir/muse" >&2
  exit 1
}

# Resolve the real stable binary during image build if the vendor launcher does
# that lazily. Runtime auto-update is disabled by the workstation wrapper.
runuser -u codex -- env \
  HOME="$build_home" \
  USER=codex \
  LOGNAME=codex \
  MUSE_INSTALL_DIR="$install_dir" \
  MUSE_NO_MODIFY_PATH=1 \
  MUSE_SYNC_UPDATE=1 \
  MUSE_NO_AUTO_UPDATE=1 \
  "$install_dir/muse" --version

chown -R root:root /opt/muse-code
find /opt/muse-code -type d -exec chmod 0755 {} +
find /opt/muse-code -type f -perm /111 -exec chmod 0755 {} +

printf 'Muse Code installed under %s\n' "$install_dir"

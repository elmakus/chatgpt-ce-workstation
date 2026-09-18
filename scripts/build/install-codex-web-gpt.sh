#!/usr/bin/env bash
set -Eeuo pipefail

repository="${CODEX_WEB_GPT_REPOSITORY:-elmakus/codex-chatgpt-web}"
version="${CODEX_CHATGPT_WEB_VERSION:-}"

if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Invalid codex-chatgpt-web repository: $repository" >&2
  exit 1
fi

if [[ -z "$version" ]]; then
  version="$(curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 60 \
    "https://api.github.com/repos/${repository}/releases/latest" \
    | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\([^"]*\)".*/\1/p' \
    | sed -n '1p')"
fi
version="${version#v}"

if [[ -z "$version" || "$version" =~ [^A-Za-z0-9._-] ]]; then
  echo "Invalid or unresolved codex-chatgpt-web version: ${version:-<empty>}" >&2
  exit 1
fi

asset="codex-web-gpt-${version}-linux-x64.AppImage"
base_url="https://github.com/${repository}/releases/download/v${version}"
tmp_dir="$(mktemp -d /tmp/codex-web-gpt.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 900 \
  "$base_url/$asset" -o "$tmp_dir/$asset"
curl -fsSL --retry 3 --retry-all-errors --connect-timeout 15 --max-time 60 \
  "$base_url/checksums.txt" -o "$tmp_dir/checksums.txt"

expected="$(awk -v asset="$asset" '$2 == asset { print $1; exit }' "$tmp_dir/checksums.txt")"
actual="$(sha256sum "$tmp_dir/$asset" | awk '{ print $1}')"
[[ -n "$expected" ]] || { echo "checksums.txt has no entry for $asset" >&2; exit 1; }
[[ "$actual" == "$expected" ]] || { echo "SHA-256 verification failed for $asset" >&2; exit 1; }

chmod 0755 "$tmp_dir/$asset"
mkdir -p "$tmp_dir/extract"
(
  cd "$tmp_dir/extract"
  "$tmp_dir/$asset" --appimage-extract >/dev/null
)

runner_source="$(find "$tmp_dir/extract/squashfs-root" -type f \
  -path '*/app.asar.unpacked/assets/linux-appimage-runner.sh' -print -quit)"
[[ -n "$runner_source" ]] || { echo "Launcher AppImage has no bounded Linux runner" >&2; exit 1; }

key_helper_source="$(find "$tmp_dir/extract/squashfs-root" -type f \
  -path '*/app.asar.unpacked/assets/set-codex-lb-key.sh' -print -quit)"
[[ -n "$key_helper_source" ]] || { echo "Launcher AppImage has no Codex-LB key helper" >&2; exit 1; }

icon_source="$(find "$tmp_dir/extract/squashfs-root" -type f -path '*/512x512/*' -name '*.png' -print -quit)"
if [[ -z "$icon_source" ]]; then
  icon_source="$(find "$tmp_dir/extract/squashfs-root" -type f -name '*.png' -print -quit)"
fi

target_dir="/opt/codex-web-gpt/${version}"
target="$target_dir/Codex Web GPT.AppImage"
runner="/opt/codex-web-gpt/run-appimage"
wrapper="/usr/local/bin/codex-web-gpt"
key_helper="/usr/local/bin/codex-web-gpt-set-codex-lb-key"

install -d -m 0755 "$target_dir" /opt/codex-web-gpt /usr/local/bin
install -m 0755 "$tmp_dir/$asset" "$target"
install -m 0755 "$runner_source" "$runner"
install -m 0755 "$key_helper_source" "$key_helper"

if [[ -n "$icon_source" ]]; then
  install -d -m 0755 /usr/local/share/icons/hicolor/512x512/apps
  install -m 0644 "$icon_source" /usr/local/share/icons/hicolor/512x512/apps/codex-web-gpt.png
fi

cat > "$wrapper" <<EOF
#!/bin/sh
set -eu
export CODEX_WEB_GPT_LAUNCHER_EXECUTABLE="$wrapper"
export CODEX_WEB_GPT_APPIMAGE="$target"
export CODEX_WEB_GPT_DISABLE_UPDATES="\${CODEX_WEB_GPT_DISABLE_UPDATES:-1}"
exec "$runner" "$target" "\$@"
EOF
chmod 0755 "$wrapper"

# Deliberately do not launch the GUI here. Docker image builds have no desktop
# session; the launcher is started later from the running workstation/noVNC.
printf 'Installed codex-chatgpt-web launcher v%s at %s\n' "$version" "$target"
printf 'Installed Codex-LB key helper at %s\n' "$key_helper"

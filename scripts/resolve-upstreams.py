#!/usr/bin/env python3
"""Resolve immutable identities for one smart-upstream update candidate."""

from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Callable, Mapping, Sequence

SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
BARE_SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
GIT_SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SAFE_BRANCH_RE = re.compile(r"^[A-Za-z0-9._/-]+$")
SAFE_VERSION_RE = re.compile(r"^[0-9A-Za-z._+-]+$")

DEFAULT_UBUNTU_IMAGE = "ubuntu:24.04"
DEFAULT_CE_REPOSITORY = "https://github.com/ilysenko/codex-desktop-linux.git"
DEFAULT_CE_REF = "main"
DEFAULT_AGENT_PACKAGE = "@agent-sh/agent-workspace-linux"
DEFAULT_OPENCODEX_PACKAGE = "@bitkyc08/opencodex"
DEFAULT_S6_REPOSITORY = "just-containers/s6-overlay"
DEFAULT_CODEX_WEB_REPOSITORY = "elmakus/codex-chatgpt-web"
DEFAULT_CODEX_WEB_UPSTREAM_REPOSITORY = "miuuyy/codex-chatgpt-web"
DEFAULT_MUSE_INSTALLER_URL = "https://dev.meta.ai/install.sh"
DEFAULT_MUSE_CHANNEL_URL = "https://api.meta.ai/muse-code/channels/muse-stable"
DEFAULT_RUST_MANIFEST_URL = "https://static.rust-lang.org/dist/channel-rust-stable.toml"
DEFAULT_RUST_INSTALLER_URL = "https://sh.rustup.rs"
SCHEMA_VERSION = 1

Runner = Callable[[Sequence[str]], str]
Fetcher = Callable[[str], bytes]


class ResolutionError(RuntimeError):
    pass


def run_command(argv: Sequence[str]) -> str:
    try:
        completed = subprocess.run(
            list(argv),
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except FileNotFoundError as exc:
        raise ResolutionError(f"required command not found: {argv[0]}") from exc
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or "").strip()
        suffix = f": {detail}" if detail else ""
        raise ResolutionError(f"command failed ({argv[0]}){suffix}") from exc
    return completed.stdout


def fetch_url(url: str) -> bytes:
    headers = {
        "Accept": "application/json, application/octet-stream;q=0.9, */*;q=0.8",
        "User-Agent": "chatgpt-ce-workstation-upstream-resolver/1",
    }
    if url.startswith("https://api.github.com/") and os.environ.get("GITHUB_TOKEN"):
        headers["Authorization"] = f"Bearer {os.environ['GITHUB_TOKEN']}"
        headers["X-GitHub-Api-Version"] = "2022-11-28"
    request = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return response.read()
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise ResolutionError(f"failed to fetch required upstream metadata: {url}") from exc


def json_from_bytes(payload: bytes, label: str) -> dict:
    try:
        value = json.loads(payload.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ResolutionError(f"{label} is not valid JSON") from exc
    if not isinstance(value, dict):
        raise ResolutionError(f"{label} must be a JSON object")
    return value


def sha256_bytes(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()


def validate_digest(value: str, label: str = "digest") -> str:
    value = value.strip().lower()
    if not SHA256_RE.fullmatch(value):
        raise ResolutionError(f"{label} must be sha256:<64 lowercase hex>")
    return value


def validate_bare_sha256(value: str, label: str = "SHA-256") -> str:
    value = value.strip().lower()
    if not BARE_SHA256_RE.fullmatch(value):
        raise ResolutionError(f"{label} must be 64 lowercase hex characters")
    return value


def validate_git_sha(value: str, label: str = "Git commit") -> str:
    value = value.strip().lower()
    if not GIT_SHA_RE.fullmatch(value):
        raise ResolutionError(f"{label} must be a full 40-character lowercase SHA")
    return value


def validate_version(value: str, label: str = "version") -> str:
    value = value.strip()
    if not value or not SAFE_VERSION_RE.fullmatch(value):
        raise ResolutionError(f"{label} is empty or unsafe")
    return value


def validate_npm_sha512_integrity(value: str, label: str = "npm integrity") -> str:
    value = value.strip()
    prefix = "sha512-"
    if not value.startswith(prefix):
        raise ResolutionError(f"{label} must use sha512 SRI")
    encoded = value[len(prefix):]
    try:
        digest = base64.b64decode(encoded, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ResolutionError(f"{label} has invalid base64 payload") from exc
    if len(digest) != 64:
        raise ResolutionError(f"{label} must encode exactly 64 SHA-512 bytes")
    return value


def map_openai_arch(machine: str) -> str:
    normalized = machine.strip().lower()
    if normalized in {"x86_64", "amd64", "x64"}:
        return "amd64"
    if normalized in {"aarch64", "arm64"}:
        return "arm64"
    raise ResolutionError(f"unsupported architecture for workstation upstreams: {machine}")


def parse_imagetools_digest(output: str) -> str:
    matches = re.findall(r"(?m)^Digest:\s+(sha256:[0-9a-fA-F]{64})\s*$", output)
    if len(matches) != 1:
        raise ResolutionError(
            f"expected exactly one top-level image digest from buildx imagetools, found {len(matches)}"
        )
    return validate_digest(matches[0], "Ubuntu base digest")


def resolve_ubuntu_base(
    image: str,
    override_digest: str | None,
    runner: Runner = run_command,
) -> dict:
    if image != DEFAULT_UBUNTU_IMAGE:
        raise ResolutionError(
            f"Ubuntu family is fixed to {DEFAULT_UBUNTU_IMAGE}; got {image}"
        )
    if override_digest:
        digest = validate_digest(override_digest, "Ubuntu base override")
        overridden = True
        provenance = "explicit-override"
    else:
        digest = parse_imagetools_digest(
            runner(["docker", "buildx", "imagetools", "inspect", image])
        )
        overridden = False
        provenance = "docker-registry-manifest"
    return {
        "family": image,
        "identity": digest,
        "override": overridden,
        "provenance": provenance,
    }


def exact_ubuntu_base(ubuntu: Mapping[str, object]) -> str:
    family = str(ubuntu["family"])
    if family != DEFAULT_UBUNTU_IMAGE:
        raise ResolutionError(f"unexpected Ubuntu family in resolution: {family}")
    digest = validate_digest(str(ubuntu["identity"]), "Ubuntu base digest")
    return f"{family}@{digest}"


def resolve_ce_commit(
    repository: str,
    ref: str,
    override_commit: str | None,
    runner: Runner = run_command,
) -> dict:
    if override_commit:
        commit = validate_git_sha(override_commit, "CE commit override")
        overridden = True
        provenance = "explicit-override"
    else:
        if not SAFE_BRANCH_RE.fullmatch(ref) or ref.startswith("-") or ".." in ref:
            raise ResolutionError(f"unsafe CE branch ref: {ref!r}")
        query_ref = f"refs/heads/{ref}"
        output = runner(["git", "ls-remote", "--exit-code", repository, query_ref])
        rows = [line.split() for line in output.splitlines() if line.strip()]
        exact = [row for row in rows if len(row) == 2 and row[1] == query_ref]
        if len(exact) != 1:
            raise ResolutionError(
                f"expected exactly one CE branch result for {query_ref}, found {len(exact)}"
            )
        commit = validate_git_sha(exact[0][0], "resolved CE commit")
        overridden = False
        provenance = "git-ls-remote"
    return {
        "repository": repository,
        "ref": ref,
        "identity": commit,
        "override": overridden,
        "provenance": provenance,
    }


def normalize_openai_metadata(raw: Mapping[str, object], *, overridden: bool) -> dict:
    required = {
        "package": str,
        "version": str,
        "architecture": str,
        "repository": str,
        "repositoryPath": str,
        "sha256": str,
        "size": int,
    }
    for key, expected_type in required.items():
        value = raw.get(key)
        if not isinstance(value, expected_type) or (expected_type is str and not value):
            raise ResolutionError(f"OpenAI metadata field {key!r} is missing or invalid")

    if raw["package"] != "chatgpt":
        raise ResolutionError("OpenAI metadata package must be 'chatgpt'")
    if raw["architecture"] not in {"amd64", "arm64"}:
        raise ResolutionError("OpenAI metadata architecture is unsupported")
    package_sha = validate_bare_sha256(str(raw["sha256"]), "OpenAI package SHA-256")
    size = int(raw["size"])
    if size <= 0:
        raise ResolutionError("OpenAI metadata size must be positive")

    version = validate_version(str(raw["version"]), "OpenAI package version")
    repository_path = str(raw["repositoryPath"])
    if not repository_path.startswith("pool/") or not repository_path.endswith(".deb"):
        raise ResolutionError("OpenAI metadata repository path is invalid")
    return {
        "architecture": str(raw["architecture"]),
        "identity": f"{version}@sha256:{package_sha}",
        "override": overridden,
        "package": "chatgpt",
        "provenance": (
            "explicit-metadata-override"
            if overridden
            else "ce-signed-stable-metadata"
        ),
        "repository": str(raw["repository"]).rstrip("/"),
        "repository_path": repository_path,
        "sha256": package_sha,
        "size": size,
        "version": version,
    }


def load_metadata_file(path: Path, *, overridden: bool) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ResolutionError(f"cannot read OpenAI metadata: {path}") from exc
    if not isinstance(raw, dict):
        raise ResolutionError("OpenAI metadata must be a JSON object")
    return normalize_openai_metadata(raw, overridden=overridden)


def resolve_openai_package(
    repo_root: Path,
    ubuntu: Mapping[str, object],
    ce: Mapping[str, object],
    arch: str,
    metadata_override: Path | None,
    runner: Runner = run_command,
) -> dict:
    if metadata_override:
        result = load_metadata_file(metadata_override, overridden=True)
        if result["architecture"] != arch:
            raise ResolutionError(
                f"OpenAI metadata override architecture {result['architecture']} != {arch}"
            )
        return result

    exact_base = exact_ubuntu_base(ubuntu)
    ce_commit = validate_git_sha(str(ce["identity"]), "CE commit")

    with tempfile.TemporaryDirectory(prefix="workstation-upstream-") as temp_dir:
        output_dir = Path(temp_dir) / "output"
        output_dir.mkdir()
        runner(
            [
                "docker",
                "buildx",
                "build",
                "--file",
                str(repo_root / "scripts/build/Dockerfile.upstream-resolution"),
                "--target",
                "openai-metadata",
                "--build-arg",
                f"UBUNTU_BASE={exact_base}",
                "--build-arg",
                f"CE_REPOSITORY={ce['repository']}",
                "--build-arg",
                f"CE_COMMIT={ce_commit}",
                "--build-arg",
                f"OPENAI_ARCH={arch}",
                "--output",
                f"type=local,dest={output_dir}",
                str(repo_root),
            ]
        )
        return load_metadata_file(
            output_dir / "openai-package.json", overridden=False
        )


def parse_deb822(source: str) -> list[dict[str, str]]:
    records = []
    for paragraph in re.split(r"\n\s*\n", source.strip()):
        if not paragraph:
            continue
        fields: dict[str, str] = {}
        current = None
        for line in paragraph.splitlines():
            if line[:1].isspace() and current:
                fields[current] += "\n" + line[1:]
                continue
            if ":" not in line:
                raise ResolutionError(f"malformed Debian metadata line: {line}")
            current, value = line.split(":", 1)
            fields[current] = value.strip()
        records.append(fields)
    return records


APT_METADATA_SCRIPT = r"""
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null
printf '%s\n' '__UBUNTU_INRELEASE__'
found=0
for file in /var/lib/apt/lists/*_InRelease; do
  [ -f "$file" ] || continue
  found=1
  printf '%s\t%s\n' "$(basename "$file")" "$(sha256sum "$file" | awk '{print $1}')"
done
[ "$found" -eq 1 ]
apt-get install -y --no-install-recommends ca-certificates curl gnupg >/dev/null
install -d -m 0755 /etc/apt/keyrings
curl -fsSL --retry 3 --retry-all-errors https://dl.google.com/linux/linux_signing_key.pub -o /tmp/google-key.pub
printf '%s\n' '__CHROME_KEY__'
sha256sum /tmp/google-key.pub | awk '{print $1}'
gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg /tmp/google-key.pub
chmod 0644 /etc/apt/keyrings/google-chrome.gpg
printf '%s\n' 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
apt-get update >/dev/null
candidate="$(apt-cache policy google-chrome-stable | awk '$1 == "Candidate:" {print $2; exit}')"
[ -n "$candidate" ] && [ "$candidate" != "(none)" ]
printf '%s\n' '__CHROME_CANDIDATE__'
printf '%s\n' "$candidate"
printf '%s\n' '__CHROME_RECORDS__'
apt-cache show google-chrome-stable
"""


def resolve_apt_metadata(
    ubuntu: Mapping[str, object],
    runner: Runner = run_command,
) -> tuple[dict, dict]:
    output = runner(
        [
            "docker",
            "run",
            "--rm",
            exact_ubuntu_base(ubuntu),
            "bash",
            "-ceu",
            APT_METADATA_SCRIPT,
        ]
    )
    markers = [
        "__UBUNTU_INRELEASE__",
        "__CHROME_KEY__",
        "__CHROME_CANDIDATE__",
        "__CHROME_RECORDS__",
    ]
    positions = [output.find(marker) for marker in markers]
    if any(position < 0 for position in positions) or positions != sorted(positions):
        raise ResolutionError("APT resolver output is missing required section markers")

    ubuntu_text = output[
        positions[0] + len(markers[0]) : positions[1]
    ].strip()
    key_text = output[
        positions[1] + len(markers[1]) : positions[2]
    ].strip()
    candidate = output[
        positions[2] + len(markers[2]) : positions[3]
    ].strip()
    records_text = output[positions[3] + len(markers[3]) :].strip()

    indexes = []
    for line in ubuntu_text.splitlines():
        parts = line.split("\t")
        if len(parts) != 2:
            raise ResolutionError("malformed Ubuntu InRelease identity row")
        name, digest = parts
        indexes.append(
            {
                "name": name,
                "sha256": validate_bare_sha256(
                    digest, f"Ubuntu InRelease SHA-256 for {name}"
                ),
            }
        )
    indexes.sort(key=lambda item: item["name"])
    if not indexes:
        raise ResolutionError("no signed Ubuntu InRelease metadata was resolved")
    identity_rows = "".join(
        f"{item['name']}\t{item['sha256']}\n" for item in indexes
    )
    composite = sha256_bytes(identity_rows.encode("utf-8"))
    ubuntu_packages = {
        "identity": f"sha256:{composite}",
        "indexes": indexes,
        "override": False,
        "provenance": "ubuntu-apt-signed-inrelease",
    }

    key_sha = validate_bare_sha256(key_text, "Google Linux signing-key SHA-256")
    candidate = validate_version(candidate, "Chrome candidate version")
    records = parse_deb822(records_text)
    matching = [
        record
        for record in records
        if record.get("Package") == "google-chrome-stable"
        and record.get("Version") == candidate
        and record.get("Architecture") in {"amd64", "x86_64"}
    ]
    if len(matching) != 1:
        raise ResolutionError(
            f"expected exactly one Chrome stable metadata record for {candidate}, found {len(matching)}"
        )
    record = matching[0]
    package_sha = validate_bare_sha256(
        record.get("SHA256", ""), "Chrome package SHA-256"
    )
    try:
        size = int(record.get("Size", "0"))
    except ValueError as exc:
        raise ResolutionError("Chrome package Size is invalid") from exc
    if size <= 0:
        raise ResolutionError("Chrome package Size must be positive")
    chrome = {
        "architecture": "amd64",
        "identity": f"{candidate}@sha256:{package_sha}",
        "override": False,
        "package": "google-chrome-stable",
        "package_sha256": package_sha,
        "provenance": "google-apt-signed-metadata",
        "repository_path": record.get("Filename", ""),
        "signing_key_sha256": key_sha,
        "size": size,
        "version": candidate,
    }
    return ubuntu_packages, chrome


def resolve_npm_package(
    package: str,
    version_override: str | None,
    label: str,
    fetcher: Fetcher = fetch_url,
) -> dict:
    encoded = urllib.parse.quote(package, safe="")
    metadata = json_from_bytes(
        fetcher(f"https://registry.npmjs.org/{encoded}"),
        f"{label} npm metadata",
    )
    if version_override:
        version = validate_version(version_override.lstrip("v"), f"{label} override")
        overridden = True
    else:
        dist_tags = metadata.get("dist-tags")
        if not isinstance(dist_tags, dict) or not isinstance(dist_tags.get("latest"), str):
            raise ResolutionError(f"{label} npm metadata has no latest dist-tag")
        version = validate_version(dist_tags["latest"], f"{label} latest version")
        overridden = False
    versions = metadata.get("versions")
    if not isinstance(versions, dict) or not isinstance(versions.get(version), dict):
        raise ResolutionError(f"{label} npm metadata has no version {version}")
    dist = versions[version].get("dist")
    if not isinstance(dist, dict):
        raise ResolutionError(f"{label} npm version has no dist metadata")
    integrity = dist.get("integrity")
    shasum = dist.get("shasum")
    if not isinstance(integrity, str):
        raise ResolutionError(f"{label} npm integrity is missing/invalid")
    integrity = validate_npm_sha512_integrity(integrity, f"{label} npm integrity")
    if not isinstance(shasum, str) or not re.fullmatch(r"[0-9a-f]{40}", shasum):
        raise ResolutionError(f"{label} npm shasum is missing/invalid")
    return {
        "identity": f"{version}@{integrity}",
        "integrity": integrity,
        "override": overridden,
        "package": package,
        "provenance": "npm-registry",
        "shasum": shasum,
        "version": version,
    }


def resolve_agent_workspace(
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    return resolve_npm_package(
        DEFAULT_AGENT_PACKAGE, version_override, "Agent Workspace", fetcher
    )


def resolve_opencodex(
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    return resolve_npm_package(
        DEFAULT_OPENCODEX_PACKAGE, version_override, "OpenCodex", fetcher
    )


def github_release(
    repository: str,
    version_override: str | None,
    fetcher: Fetcher,
) -> tuple[dict, str, bool]:
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ResolutionError(f"invalid GitHub repository: {repository}")
    if version_override:
        version = validate_version(version_override.lstrip("v"), "GitHub release override")
        suffix = f"releases/tags/v{version}"
        overridden = True
    else:
        suffix = "releases/latest"
        overridden = False
    release = json_from_bytes(
        fetcher(f"https://api.github.com/repos/{repository}/{suffix}"),
        f"{repository} release metadata",
    )
    tag = release.get("tag_name")
    if not isinstance(tag, str) or not tag.startswith("v"):
        raise ResolutionError(f"{repository} release tag is missing/invalid")
    resolved_version = validate_version(tag[1:], f"{repository} release version")
    if version_override and resolved_version != version:
        raise ResolutionError(
            f"{repository} release override resolved to unexpected tag {tag}"
        )
    if release.get("draft") is True or release.get("prerelease") is True:
        raise ResolutionError(f"{repository} selected release is not stable")
    return release, resolved_version, overridden


def release_assets(release: Mapping[str, object]) -> list[dict]:
    assets = release.get("assets")
    if not isinstance(assets, list):
        raise ResolutionError("GitHub release assets are missing")
    return [asset for asset in assets if isinstance(asset, dict)]


def release_asset(release: Mapping[str, object], name: str) -> dict:
    matches = [asset for asset in release_assets(release) if asset.get("name") == name]
    if len(matches) != 1:
        raise ResolutionError(f"expected exactly one release asset named {name}")
    return matches[0]


def asset_sha256(asset: Mapping[str, object], fetcher: Fetcher) -> str:
    digest = asset.get("digest")
    if isinstance(digest, str) and SHA256_RE.fullmatch(digest.lower()):
        return digest.lower().split(":", 1)[1]
    url = asset.get("browser_download_url")
    if not isinstance(url, str) or not url.startswith("https://"):
        raise ResolutionError("release asset has no safe download URL")
    return sha256_bytes(fetcher(url))


def resolve_s6_overlay(
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    release, version, overridden = github_release(
        DEFAULT_S6_REPOSITORY, version_override, fetcher
    )
    names = ["s6-overlay-noarch.tar.xz", "s6-overlay-x86_64.tar.xz"]
    hashes = {}
    for name in names:
        hashes[name] = asset_sha256(release_asset(release, name), fetcher)
    identity_payload = "\n".join(f"{name}:{hashes[name]}" for name in sorted(hashes))
    identity = sha256_bytes(identity_payload.encode("utf-8"))
    return {
        "assets": hashes,
        "identity": f"{version}@sha256:{identity}",
        "override": overridden,
        "provenance": "github-stable-release-assets",
        "repository": DEFAULT_S6_REPOSITORY,
        "version": version,
    }


def parse_checksum_file(text: str, asset_name: str) -> str:
    matches = []
    for line in text.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[-1].lstrip("*") == asset_name:
            matches.append(parts[0].lower())
    if len(matches) != 1:
        raise ResolutionError(f"checksum file has {len(matches)} entries for {asset_name}")
    return validate_bare_sha256(matches[0], f"checksum for {asset_name}")


def resolve_codex_web_gpt_repository(
    repository: str,
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    release, version, overridden = github_release(
        repository, version_override, fetcher
    )
    asset_name = f"codex-web-gpt-{version}-linux-x64.AppImage"
    release_asset(release, asset_name)
    checksum_asset = release_asset(release, "checksums.txt")
    checksum_url = checksum_asset.get("browser_download_url")
    if not isinstance(checksum_url, str) or not checksum_url.startswith("https://"):
        raise ResolutionError("Codex Web GPT checksum asset has no safe URL")
    try:
        checksums = fetcher(checksum_url).decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ResolutionError("Codex Web GPT checksum file is not UTF-8") from exc
    package_sha = parse_checksum_file(checksums, asset_name)
    return {
        "asset": asset_name,
        "identity": f"{version}@sha256:{package_sha}",
        "override": overridden,
        "package_sha256": package_sha,
        "provenance": "github-stable-release-checksums",
        "repository": repository,
        "version": version,
    }


def resolve_codex_web_gpt(
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    return resolve_codex_web_gpt_repository(
        DEFAULT_CODEX_WEB_REPOSITORY, version_override, fetcher
    )


def resolve_codex_web_gpt_upstream(
    version_override: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    return resolve_codex_web_gpt_repository(
        DEFAULT_CODEX_WEB_UPSTREAM_REPOSITORY, version_override, fetcher
    )


def resolve_muse_code(
    installer_url: str,
    expected_installer_sha256: str | None,
    fetcher: Fetcher = fetch_url,
) -> dict:
    if not installer_url.startswith("https://"):
        raise ResolutionError("Muse installer URL must use HTTPS")
    installer = fetcher(installer_url)
    installer_sha = sha256_bytes(installer)
    overridden = installer_url != DEFAULT_MUSE_INSTALLER_URL or bool(expected_installer_sha256)
    if expected_installer_sha256:
        expected = validate_bare_sha256(
            expected_installer_sha256, "Muse installer SHA-256 override"
        )
        if installer_sha != expected:
            raise ResolutionError(
                "Muse installer SHA-256 override does not match current installer"
            )
    channel = json_from_bytes(
        fetcher(DEFAULT_MUSE_CHANNEL_URL), "Muse stable channel metadata"
    )
    version_raw = channel.get("version")
    if not isinstance(version_raw, str):
        raise ResolutionError("Muse stable channel has no version")
    version = validate_version(version_raw, "Muse stable version")
    channel_name = channel.get("channel")
    if channel_name not in {None, "muse-stable"}:
        raise ResolutionError(f"unexpected Muse channel: {channel_name}")
    state = channel.get("state")
    if state not in {None, "public"}:
        raise ResolutionError(f"Muse stable channel is not public: {state}")
    return {
        "channel": "muse-stable",
        "identity": f"{version}@sha256:{installer_sha}",
        "installer_sha256": installer_sha,
        "installer_url": installer_url,
        "override": overridden,
        "provenance": "meta-stable-channel-and-installer",
        "version": version,
    }


def resolve_rust_stable(fetcher: Fetcher = fetch_url) -> dict:
    manifest = fetcher(DEFAULT_RUST_MANIFEST_URL)
    checksum_payload = fetcher(DEFAULT_RUST_MANIFEST_URL + ".sha256")
    try:
        expected = checksum_payload.decode("utf-8").strip().split()[0].lower()
    except UnicodeDecodeError as exc:
        raise ResolutionError("Rust stable manifest checksum is not UTF-8") from exc
    expected = validate_bare_sha256(expected, "Rust stable manifest SHA-256")
    actual = sha256_bytes(manifest)
    if actual != expected:
        raise ResolutionError("Rust stable channel manifest SHA-256 mismatch")
    try:
        manifest_text = manifest.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ResolutionError("Rust stable channel manifest is not UTF-8") from exc
    section = re.search(
        r"(?ms)^\[pkg\.rust\]\s*$\n(.*?)(?=^\[|\Z)",
        manifest_text,
    )
    if not section:
        raise ResolutionError("Rust stable channel manifest has no [pkg.rust] section")
    version_match = re.search(r'(?m)^version\s*=\s*"([^"]+)"\s*$', section.group(1))
    if not version_match:
        raise ResolutionError("Rust stable channel manifest has no rust version")
    semver_match = re.match(r"(\d+\.\d+\.\d+)", version_match.group(1))
    if not semver_match:
        raise ResolutionError("Rust stable version is invalid")
    version = validate_version(semver_match.group(1), "Rust stable version")
    installer_sha = sha256_bytes(fetcher(DEFAULT_RUST_INSTALLER_URL))
    return {
        "channel_manifest_sha256": actual,
        "identity": f"{version}@sha256:{actual}",
        "installer_sha256": installer_sha,
        "override": False,
        "provenance": "rust-static-stable-manifest",
        "version": version,
    }


def build_resolution(
    ubuntu: Mapping[str, object],
    ce: Mapping[str, object],
    openai: Mapping[str, object],
    extras: Mapping[str, Mapping[str, object]] | None = None,
) -> dict:
    components = {
        "ce": dict(ce),
        "openai_chatgpt": dict(openai),
        "ubuntu_base": dict(ubuntu),
    }
    if extras:
        for name, value in extras.items():
            if name in components:
                raise ResolutionError(f"duplicate resolution component: {name}")
            components[name] = dict(value)
    overrides = sorted(
        name for name, value in components.items() if value.get("override") is True
    )
    return {
        "components": components,
        "overrides": overrides,
        "policy": {
            "channel": "latest-trusted-stable-current",
            "ubuntu_family": DEFAULT_UBUNTU_IMAGE,
        },
        "schema_version": SCHEMA_VERSION,
    }


def serialize_resolution(resolution: Mapping[str, object]) -> str:
    return json.dumps(
        resolution,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
    ) + "\n"


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--ubuntu-image",
        default=os.environ.get("UPSTREAM_UBUNTU_IMAGE", DEFAULT_UBUNTU_IMAGE),
    )
    parser.add_argument(
        "--ubuntu-base-digest",
        default=os.environ.get("UPSTREAM_UBUNTU_BASE_DIGEST"),
    )
    parser.add_argument(
        "--ce-repository",
        default=os.environ.get("CE_REPOSITORY", DEFAULT_CE_REPOSITORY),
    )
    parser.add_argument("--ce-ref", default=os.environ.get("CE_REF", DEFAULT_CE_REF))
    parser.add_argument("--ce-commit", default=os.environ.get("UPSTREAM_CE_COMMIT"))
    parser.add_argument(
        "--openai-metadata-file",
        type=Path,
        default=(
            Path(os.environ["UPSTREAM_OPENAI_METADATA_FILE"])
            if os.environ.get("UPSTREAM_OPENAI_METADATA_FILE")
            else None
        ),
        help="expert/debug override; normal resolution uses CE's signed stable metadata",
    )
    parser.add_argument(
        "--agent-workspace-version",
        default=os.environ.get("AGENT_WORKSPACE_VERSION"),
    )
    parser.add_argument(
        "--s6-overlay-version",
        default=os.environ.get("S6_OVERLAY_VERSION"),
    )
    parser.add_argument(
        "--opencodex-version",
        default=os.environ.get("OPENCODEX_VERSION") or None,
    )
    parser.add_argument(
        "--codex-web-gpt-version",
        default=os.environ.get("CODEX_CHATGPT_WEB_VERSION") or None,
    )
    parser.add_argument(
        "--codex-web-gpt-upstream-version",
        default=os.environ.get("CODEX_CHATGPT_WEB_UPSTREAM_VERSION") or None,
    )
    parser.add_argument(
        "--muse-installer-url",
        default=os.environ.get("MUSE_INSTALLER_URL", DEFAULT_MUSE_INSTALLER_URL),
    )
    parser.add_argument(
        "--muse-installer-sha256",
        default=os.environ.get("MUSE_INSTALLER_SHA256") or None,
    )
    parser.add_argument(
        "--arch", default=os.environ.get("UPSTREAM_ARCH", platform.machine())
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    repo_root = Path(__file__).resolve().parents[1]
    try:
        arch = map_openai_arch(args.arch)
        ubuntu = resolve_ubuntu_base(args.ubuntu_image, args.ubuntu_base_digest)
        ce = resolve_ce_commit(args.ce_repository, args.ce_ref, args.ce_commit)
        openai = resolve_openai_package(
            repo_root, ubuntu, ce, arch, args.openai_metadata_file
        )
        ubuntu_packages, chrome = resolve_apt_metadata(ubuntu)
        extras = {
            "agent_workspace": resolve_agent_workspace(args.agent_workspace_version),
            "chrome": chrome,
            "codex_web_gpt": resolve_codex_web_gpt(args.codex_web_gpt_version),
            "codex_web_gpt_upstream": resolve_codex_web_gpt_upstream(
                args.codex_web_gpt_upstream_version
            ),
            "opencodex": resolve_opencodex(args.opencodex_version),
            "muse_code": resolve_muse_code(
                args.muse_installer_url, args.muse_installer_sha256
            ),
            "rust": resolve_rust_stable(),
            "s6_overlay": resolve_s6_overlay(args.s6_overlay_version),
            "ubuntu_packages": ubuntu_packages,
        }
        payload = serialize_resolution(build_resolution(ubuntu, ce, openai, extras))
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(payload, encoding="utf-8")
        else:
            sys.stdout.write(payload)
    except ResolutionError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

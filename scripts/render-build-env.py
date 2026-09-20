#!/usr/bin/env python3
"""Validate a frozen upstream manifest and emit exact Docker build inputs."""

from __future__ import annotations

import argparse
import hashlib
import json
import shlex
import sys
from pathlib import Path
from typing import Mapping

COMPONENTS = {
    "agent_workspace",
    "ce",
    "chrome",
    "codex_web_gpt",
    "muse_code",
    "openai_chatgpt",
    "rust",
    "s6_overlay",
    "ubuntu_base",
    "ubuntu_packages",
}

ALLOWED_FIELDS = {
    "agent_workspace": {"identity", "integrity", "override", "package", "provenance", "shasum", "version"},
    "ce": {"identity", "override", "provenance", "ref", "repository"},
    "chrome": {"architecture", "identity", "override", "package", "package_sha256", "provenance", "repository_path", "signing_key_sha256", "size", "version"},
    "codex_web_gpt": {"asset", "identity", "override", "package_sha256", "provenance", "repository", "version"},
    "muse_code": {"channel", "identity", "installer_sha256", "installer_url", "override", "provenance", "version"},
    "openai_chatgpt": {"architecture", "identity", "override", "package", "provenance", "repository", "repository_path", "sha256", "size", "version"},
    "rust": {"channel_manifest_sha256", "identity", "installer_sha256", "override", "provenance", "version"},
    "s6_overlay": {"assets", "identity", "override", "provenance", "repository", "version"},
    "ubuntu_base": {"family", "identity", "override", "provenance"},
    "ubuntu_packages": {"identity", "indexes", "override", "provenance"},
}


class ManifestError(RuntimeError):
    pass


def require_mapping(value: object, label: str) -> Mapping[str, object]:
    if not isinstance(value, dict):
        raise ManifestError(f"{label} must be an object")
    return value


def require_text(component: Mapping[str, object], key: str, label: str) -> str:
    value = component.get(key)
    if not isinstance(value, str) or not value:
        raise ManifestError(f"{label}.{key} is missing/invalid")
    if any(ch in value for ch in "\r\n\0"):
        raise ManifestError(f"{label}.{key} contains control characters")
    return value


def load_manifest(path: Path) -> dict:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ManifestError(f"cannot read frozen upstream manifest: {path}") from exc
    root = require_mapping(raw, "manifest")
    if set(root) != {"components", "overrides", "policy", "schema_version"}:
        raise ManifestError("manifest top-level schema is unexpected")
    if root.get("schema_version") != 1:
        raise ManifestError("unsupported upstream manifest schema version")

    components = require_mapping(root.get("components"), "components")
    if set(components) != COMPONENTS:
        missing = sorted(COMPONENTS - set(components))
        extra = sorted(set(components) - COMPONENTS)
        raise ManifestError(f"component set mismatch; missing={missing} extra={extra}")

    for name in sorted(COMPONENTS):
        component = require_mapping(components[name], name)
        extra_fields = set(component) - ALLOWED_FIELDS[name]
        if extra_fields:
            raise ManifestError(f"{name} has unexpected fields: {sorted(extra_fields)}")
        require_text(component, "identity", name)
        if not isinstance(component.get("override"), bool):
            raise ManifestError(f"{name}.override must be boolean")

    policy = require_mapping(root.get("policy"), "policy")
    if policy.get("channel") != "latest-trusted-stable-current":
        raise ManifestError("unexpected upstream policy channel")
    if policy.get("ubuntu_family") != "ubuntu:24.04":
        raise ManifestError("Ubuntu family must remain ubuntu:24.04")

    overrides = root.get("overrides")
    if not isinstance(overrides, list) or not all(isinstance(item, str) for item in overrides):
        raise ManifestError("manifest overrides must be a string list")
    actual_overrides = sorted(
        name
        for name, value in components.items()
        if isinstance(value, dict) and value.get("override") is True
    )
    if sorted(overrides) != actual_overrides:
        raise ManifestError("manifest override list does not match component flags")

    return json.loads(
        json.dumps(root, sort_keys=True, separators=(",", ":"), ensure_ascii=True)
    )


def canonical_bytes(manifest: Mapping[str, object]) -> bytes:
    return (
        json.dumps(manifest, sort_keys=True, separators=(",", ":"), ensure_ascii=True)
        + "\n"
    ).encode("ascii")


def build_inputs(manifest: Mapping[str, object]) -> dict[str, str]:
    c = require_mapping(manifest["components"], "components")
    ubuntu = require_mapping(c["ubuntu_base"], "ubuntu_base")
    ubuntu_packages = require_mapping(c["ubuntu_packages"], "ubuntu_packages")
    ce = require_mapping(c["ce"], "ce")
    openai = require_mapping(c["openai_chatgpt"], "openai_chatgpt")
    agent = require_mapping(c["agent_workspace"], "agent_workspace")
    s6 = require_mapping(c["s6_overlay"], "s6_overlay")
    codex = require_mapping(c["codex_web_gpt"], "codex_web_gpt")
    muse = require_mapping(c["muse_code"], "muse_code")
    chrome = require_mapping(c["chrome"], "chrome")
    rust = require_mapping(c["rust"], "rust")

    family = require_text(ubuntu, "family", "ubuntu_base")
    digest = require_text(ubuntu, "identity", "ubuntu_base")
    if family != "ubuntu:24.04" or not digest.startswith("sha256:"):
        raise ManifestError("Ubuntu base identity is invalid")

    assets = require_mapping(s6.get("assets"), "s6_overlay.assets")
    noarch_sha = require_text(assets, "s6-overlay-noarch.tar.xz", "s6_overlay.assets")
    x86_sha = require_text(assets, "s6-overlay-x86_64.tar.xz", "s6_overlay.assets")

    values = {
        "UBUNTU_BASE": f"{family}@{digest}",
        "UBUNTU_APT_IDENTITY": require_text(ubuntu_packages, "identity", "ubuntu_packages"),
        "CE_REPOSITORY": require_text(ce, "repository", "ce"),
        "CE_REF": require_text(ce, "ref", "ce"),
        "CE_COMMIT": require_text(ce, "identity", "ce"),
        "OPENAI_PACKAGE_VERSION": require_text(openai, "version", "openai_chatgpt"),
        "OPENAI_PACKAGE_SHA256": require_text(openai, "sha256", "openai_chatgpt"),
        "AGENT_WORKSPACE_VERSION": require_text(agent, "version", "agent_workspace"),
        "AGENT_WORKSPACE_INTEGRITY": require_text(agent, "integrity", "agent_workspace"),
        "S6_OVERLAY_VERSION": require_text(s6, "version", "s6_overlay"),
        "S6_OVERLAY_NOARCH_SHA256": noarch_sha,
        "S6_OVERLAY_X86_64_SHA256": x86_sha,
        "CODEX_CHATGPT_WEB_VERSION": require_text(codex, "version", "codex_web_gpt"),
        "CODEX_CHATGPT_WEB_SHA256": require_text(codex, "package_sha256", "codex_web_gpt"),
        "MUSE_INSTALLER_URL": require_text(muse, "installer_url", "muse_code"),
        "MUSE_INSTALLER_SHA256": require_text(muse, "installer_sha256", "muse_code"),
        "MUSE_EXPECTED_VERSION": require_text(muse, "version", "muse_code"),
        "CHROME_VERSION": require_text(chrome, "version", "chrome"),
        "CHROME_PACKAGE_SHA256": require_text(chrome, "package_sha256", "chrome"),
        "GOOGLE_LINUX_SIGNING_KEY_SHA256": require_text(chrome, "signing_key_sha256", "chrome"),
        "RUST_VERSION": require_text(rust, "version", "rust"),
        "RUST_STABLE_MANIFEST_SHA256": require_text(rust, "channel_manifest_sha256", "rust"),
        "RUSTUP_INSTALLER_SHA256": require_text(rust, "installer_sha256", "rust"),
    }
    return values


def shell_exports(values: Mapping[str, str]) -> str:
    return "".join(
        f"export {key}={shlex.quote(value)}\n" for key, value in sorted(values.items())
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--resolution", required=True, type=Path)
    parser.add_argument("--stage", required=True, type=Path)
    args = parser.parse_args(argv)

    try:
        manifest = load_manifest(args.resolution)
        payload = canonical_bytes(manifest)
        digest = hashlib.sha256(payload).hexdigest()
        args.stage.parent.mkdir(parents=True, exist_ok=True)
        args.stage.write_bytes(payload)
        values = build_inputs(manifest)
        values["UPSTREAM_RESOLUTION_SHA256"] = digest
        values["CANDIDATE_IMAGE_TAG"] = f"candidate-{digest[:16]}"
        sys.stdout.write(shell_exports(values))
    except ManifestError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

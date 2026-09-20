#!/usr/bin/env python3
"""Resolve immutable identities for the smart-upstream update candidate.

M01 intentionally resolves only the highest-risk identities first:
- Ubuntu 24.04 base image digest;
- ChatGPT Community Edition selected Git commit;
- official OpenAI ChatGPT Linux package identity using the exact CE commit's
  signed stable-repository resolver.

The normal path writes deterministic JSON with no wall-clock data. Later M01
work extends the same schema with the remaining managed upstreams.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Callable, Mapping, Sequence

SHA256_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
GIT_SHA_RE = re.compile(r"^[0-9a-f]{40}$")
PACKAGE_SHA_RE = re.compile(r"^[0-9a-f]{64}$")
SAFE_BRANCH_RE = re.compile(r"^[A-Za-z0-9._/-]+$")

DEFAULT_UBUNTU_IMAGE = "ubuntu:24.04"
DEFAULT_CE_REPOSITORY = "https://github.com/ilysenko/codex-desktop-linux.git"
DEFAULT_CE_REF = "main"
SCHEMA_VERSION = 1

Runner = Callable[[Sequence[str]], str]


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


def validate_digest(value: str, label: str = "digest") -> str:
    value = value.strip().lower()
    if not SHA256_RE.fullmatch(value):
        raise ResolutionError(f"{label} must be sha256:<64 lowercase hex>")
    return value


def validate_git_sha(value: str, label: str = "Git commit") -> str:
    value = value.strip().lower()
    if not GIT_SHA_RE.fullmatch(value):
        raise ResolutionError(f"{label} must be a full 40-character lowercase SHA")
    return value


def map_openai_arch(machine: str) -> str:
    normalized = machine.strip().lower()
    if normalized in {"x86_64", "amd64", "x64"}:
        return "amd64"
    if normalized in {"aarch64", "arm64"}:
        return "arm64"
    raise ResolutionError(f"unsupported architecture for OpenAI Linux package: {machine}")


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
    package_sha = str(raw["sha256"]).lower()
    if not PACKAGE_SHA_RE.fullmatch(package_sha):
        raise ResolutionError("OpenAI metadata SHA256 is invalid")
    size = int(raw["size"])
    if size <= 0:
        raise ResolutionError("OpenAI metadata size must be positive")

    version = str(raw["version"])
    repository_path = str(raw["repositoryPath"])
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

    ubuntu_family = str(ubuntu["family"])
    ubuntu_digest = validate_digest(str(ubuntu["identity"]), "Ubuntu base digest")
    exact_base = f"{ubuntu_family}@{ubuntu_digest}"
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


def build_resolution(
    ubuntu: Mapping[str, object],
    ce: Mapping[str, object],
    openai: Mapping[str, object],
) -> dict:
    return {
        "components": {
            "ce": dict(ce),
            "openai_chatgpt": dict(openai),
            "ubuntu_base": dict(ubuntu),
        },
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
    parser.add_argument(
        "--ce-ref",
        default=os.environ.get("CE_REF", DEFAULT_CE_REF),
    )
    parser.add_argument(
        "--ce-commit",
        default=os.environ.get("UPSTREAM_CE_COMMIT"),
    )
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
        "--arch",
        default=os.environ.get("UPSTREAM_ARCH", platform.machine()),
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    repo_root = Path(__file__).resolve().parents[1]
    try:
        arch = map_openai_arch(args.arch)
        ubuntu = resolve_ubuntu_base(
            args.ubuntu_image, args.ubuntu_base_digest
        )
        ce = resolve_ce_commit(
            args.ce_repository, args.ce_ref, args.ce_commit
        )
        openai = resolve_openai_package(
            repo_root,
            ubuntu,
            ce,
            arch,
            args.openai_metadata_file,
        )
        payload = serialize_resolution(build_resolution(ubuntu, ce, openai))
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

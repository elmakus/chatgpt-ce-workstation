#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("resolve-upstreams.py")
SPEC = importlib.util.spec_from_file_location("resolve_upstreams", SCRIPT)
assert SPEC and SPEC.loader
resolver = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(resolver)


class ResolverTests(unittest.TestCase):
    def test_parse_ubuntu_digest(self):
        digest = "sha256:" + "a" * 64
        output = f"Name: docker.io/library/ubuntu:24.04\nMediaType: x\nDigest: {digest}\n"
        self.assertEqual(resolver.parse_imagetools_digest(output), digest)

    def test_parse_ubuntu_digest_rejects_missing_or_ambiguous(self):
        with self.assertRaises(resolver.ResolutionError):
            resolver.parse_imagetools_digest("Name: ubuntu:24.04\n")
        digest = "sha256:" + "a" * 64
        with self.assertRaises(resolver.ResolutionError):
            resolver.parse_imagetools_digest(f"Digest: {digest}\nDigest: {digest}\n")

    def test_ubuntu_override_is_explicit(self):
        digest = "sha256:" + "b" * 64
        result = resolver.resolve_ubuntu_base("ubuntu:24.04", digest)
        self.assertEqual(result["identity"], digest)
        self.assertTrue(result["override"])
        self.assertEqual(result["provenance"], "explicit-override")

    def test_ubuntu_family_cannot_change(self):
        with self.assertRaises(resolver.ResolutionError):
            resolver.resolve_ubuntu_base(
                "ubuntu:latest", "sha256:" + "c" * 64
            )

    def test_ce_branch_resolution_uses_exact_remote_head(self):
        commit = "d" * 40
        calls = []

        def fake_runner(argv):
            calls.append(list(argv))
            return f"{commit}\trefs/heads/main\n"

        result = resolver.resolve_ce_commit(
            "https://example.invalid/ce.git", "main", None, fake_runner
        )
        self.assertEqual(result["identity"], commit)
        self.assertFalse(result["override"])
        self.assertEqual(
            calls[0],
            [
                "git",
                "ls-remote",
                "--exit-code",
                "https://example.invalid/ce.git",
                "refs/heads/main",
            ],
        )

    def test_ce_override_is_explicit(self):
        commit = "e" * 40
        result = resolver.resolve_ce_commit(
            "https://example.invalid/ce.git", "main", commit
        )
        self.assertEqual(result["identity"], commit)
        self.assertTrue(result["override"])

    def test_openai_metadata_normalization(self):
        raw = {
            "package": "chatgpt",
            "version": "1.2.3",
            "architecture": "amd64",
            "repository": "https://packages.example.test/",
            "repositoryPath": "pool/chatgpt_1.2.3_amd64.deb",
            "sha256": "f" * 64,
            "size": 12345,
            "depends": "libc6",
            "path": None,
        }
        normalized = resolver.normalize_openai_metadata(raw, overridden=False)
        self.assertEqual(
            normalized["identity"], "1.2.3@sha256:" + "f" * 64
        )
        self.assertEqual(
            normalized["provenance"], "ce-signed-stable-metadata"
        )
        self.assertNotIn("path", normalized)
        self.assertNotIn("depends", normalized)

    def test_openai_metadata_rejects_bad_hash(self):
        raw = {
            "package": "chatgpt",
            "version": "1.2.3",
            "architecture": "amd64",
            "repository": "https://packages.example.test",
            "repositoryPath": "pool/chatgpt.deb",
            "sha256": "not-a-hash",
            "size": 123,
        }
        with self.assertRaises(resolver.ResolutionError):
            resolver.normalize_openai_metadata(raw, overridden=False)

    def test_openai_metadata_override_is_visible(self):
        raw = {
            "package": "chatgpt",
            "version": "2.0.0",
            "architecture": "amd64",
            "repository": "https://packages.example.test",
            "repositoryPath": "pool/chatgpt_2.0.0_amd64.deb",
            "sha256": "1" * 64,
            "size": 456,
        }
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "metadata.json"
            path.write_text(json.dumps(raw), encoding="utf-8")
            result = resolver.load_metadata_file(path, overridden=True)
        self.assertTrue(result["override"])
        self.assertEqual(result["provenance"], "explicit-metadata-override")

    def test_resolution_serialization_is_stable_and_has_no_time_nonce(self):
        ubuntu = {
            "family": "ubuntu:24.04",
            "identity": "sha256:" + "2" * 64,
            "override": False,
            "provenance": "docker-registry-manifest",
        }
        ce = {
            "repository": "https://example.invalid/ce.git",
            "ref": "main",
            "identity": "3" * 40,
            "override": False,
            "provenance": "git-ls-remote",
        }
        openai = {
            "architecture": "amd64",
            "identity": "1.0@sha256:" + "4" * 64,
            "override": False,
            "package": "chatgpt",
            "provenance": "ce-signed-stable-metadata",
            "repository": "https://packages.example.test",
            "repository_path": "pool/chatgpt.deb",
            "sha256": "4" * 64,
            "size": 789,
            "version": "1.0",
        }
        resolution = resolver.build_resolution(ubuntu, ce, openai)
        first = resolver.serialize_resolution(resolution)
        second = resolver.serialize_resolution(resolution)
        self.assertEqual(first, second)
        self.assertNotIn("timestamp", first.lower())
        self.assertNotIn("nonce", first.lower())
        self.assertEqual(json.loads(first)["schema_version"], 1)

    def test_openai_build_uses_exact_frozen_base_and_ce_commit(self):
        ubuntu = {
            "family": "ubuntu:24.04",
            "identity": "sha256:" + "5" * 64,
        }
        ce = {
            "repository": "https://example.invalid/ce.git",
            "identity": "6" * 40,
        }
        metadata = {
            "package": "chatgpt",
            "version": "3.0.0",
            "architecture": "amd64",
            "repository": "https://packages.example.test",
            "repositoryPath": "pool/chatgpt_3.0.0_amd64.deb",
            "sha256": "7" * 64,
            "size": 987,
        }
        calls = []

        def fake_runner(argv):
            calls.append(list(argv))
            destination = next(
                item.split("=", 2)[2]
                for item in argv
                if item.startswith("type=local,dest=")
            )
            Path(destination, "openai-package.json").write_text(
                json.dumps(metadata), encoding="utf-8"
            )
            return ""

        result = resolver.resolve_openai_package(
            Path("/repo"), ubuntu, ce, "amd64", None, fake_runner
        )
        command = calls[0]
        self.assertIn(
            "UBUNTU_BASE=ubuntu:24.04@sha256:" + "5" * 64,
            command,
        )
        self.assertIn("CE_COMMIT=" + "6" * 40, command)
        self.assertEqual(
            result["provenance"], "ce-signed-stable-metadata"
        )


if __name__ == "__main__":
    unittest.main()

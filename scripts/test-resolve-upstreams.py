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


VALID_SHA512_X = "sha512-eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eA=="
VALID_SHA512_Y = "sha512-eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eXl5eQ=="

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


    def test_apt_metadata_uses_signed_ubuntu_indexes_and_chrome_package_hash(self):
        ubuntu = {
            "family": "ubuntu:24.04",
            "identity": "sha256:" + "8" * 64,
        }
        output = """__UBUNTU_INRELEASE__
archive_InRelease\taaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
security_InRelease\tbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__CHROME_KEY__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
__CHROME_CANDIDATE__
145.0.7632.75-1
__CHROME_RECORDS__
Package: google-chrome-stable
Version: 145.0.7632.75-1
Architecture: amd64
Filename: pool/main/g/google-chrome-stable/google-chrome-stable_145.0.7632.75-1_amd64.deb
Size: 123456789
SHA256: dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
"""
        calls = []

        def fake_runner(argv):
            calls.append(list(argv))
            return output

        ubuntu_packages, chrome = resolver.resolve_apt_metadata(
            ubuntu, fake_runner
        )
        self.assertEqual(
            calls[0][3], "ubuntu:24.04@sha256:" + "8" * 64
        )
        self.assertEqual(
            ubuntu_packages["provenance"], "ubuntu-apt-signed-inrelease"
        )
        identity_rows = (
            "archive_InRelease\t" + "a" * 64 + "\n"
            + "security_InRelease\t" + "b" * 64 + "\n"
        )
        self.assertEqual(
            ubuntu_packages["identity"],
            "sha256:" + resolver.sha256_bytes(identity_rows.encode()),
        )
        self.assertEqual(chrome["version"], "145.0.7632.75-1")
        self.assertEqual(chrome["package_sha256"], "d" * 64)
        self.assertEqual(chrome["signing_key_sha256"], "c" * 64)

    def test_agent_workspace_uses_latest_npm_integrity(self):
        payload = {
            "dist-tags": {"latest": "0.3.3"},
            "versions": {
                "0.3.3": {
                    "dist": {
                        "integrity": VALID_SHA512_X,
                        "shasum": "a" * 40,
                    }
                }
            },
        }

        def fetcher(_url):
            return json.dumps(payload).encode()

        result = resolver.resolve_agent_workspace(None, fetcher)
        self.assertEqual(result["version"], "0.3.3")
        self.assertEqual(result["identity"], f"0.3.3@{VALID_SHA512_X}")
        self.assertFalse(result["override"])

    def test_agent_workspace_override_is_explicit(self):
        payload = {
            "dist-tags": {"latest": "0.3.3"},
            "versions": {
                "0.3.2": {
                    "dist": {
                        "integrity": VALID_SHA512_Y,
                        "shasum": "b" * 40,
                    }
                }
            },
        }
        result = resolver.resolve_agent_workspace(
            "0.3.2", lambda _url: json.dumps(payload).encode()
        )
        self.assertEqual(result["version"], "0.3.2")
        self.assertTrue(result["override"])

    def test_s6_release_binds_both_asset_hashes(self):
        release = {
            "tag_name": "v3.2.3.2",
            "draft": False,
            "prerelease": False,
            "assets": [
                {
                    "name": "s6-overlay-noarch.tar.xz",
                    "digest": "sha256:" + "1" * 64,
                    "browser_download_url": "https://example.invalid/noarch",
                },
                {
                    "name": "s6-overlay-x86_64.tar.xz",
                    "digest": "sha256:" + "2" * 64,
                    "browser_download_url": "https://example.invalid/x86",
                },
            ],
        }
        result = resolver.resolve_s6_overlay(
            None, lambda _url: json.dumps(release).encode()
        )
        self.assertEqual(result["version"], "3.2.3.2")
        self.assertEqual(
            result["assets"]["s6-overlay-noarch.tar.xz"], "1" * 64
        )
        self.assertFalse(result["override"])

    def test_codex_web_gpt_uses_upstream_checksums_contract(self):
        version = "9.9.9"
        asset = f"codex-web-gpt-{version}-linux-x64.AppImage"
        release = {
            "tag_name": f"v{version}",
            "draft": False,
            "prerelease": False,
            "assets": [
                {
                    "name": asset,
                    "browser_download_url": "https://example.invalid/app",
                },
                {
                    "name": "checksums.txt",
                    "browser_download_url": "https://example.invalid/checksums",
                },
            ],
        }

        def fetcher(url):
            if url.endswith("/releases/latest"):
                return json.dumps(release).encode()
            if url == "https://example.invalid/checksums":
                return f'{"3" * 64}  {asset}\n'.encode()
            raise AssertionError(url)

        result = resolver.resolve_codex_web_gpt(None, fetcher)
        self.assertEqual(result["version"], version)
        self.assertEqual(result["package_sha256"], "3" * 64)
        self.assertEqual(
            result["provenance"], "github-stable-release-checksums"
        )

    def test_muse_uses_stable_channel_and_installer_hash(self):
        installer = b"#!/bin/sh\necho muse\n"
        channel = {
            "channel": "muse-stable",
            "version": "1.1.1-R2514.1",
            "state": "public",
        }

        def fetcher(url):
            if url == resolver.DEFAULT_MUSE_INSTALLER_URL:
                return installer
            if url == resolver.DEFAULT_MUSE_CHANNEL_URL:
                return json.dumps(channel).encode()
            raise AssertionError(url)

        result = resolver.resolve_muse_code(
            resolver.DEFAULT_MUSE_INSTALLER_URL, None, fetcher
        )
        self.assertEqual(result["version"], "1.1.1-R2514.1")
        self.assertEqual(
            result["installer_sha256"], resolver.sha256_bytes(installer)
        )
        self.assertFalse(result["override"])

    def test_muse_installer_override_must_match(self):
        installer = b"installer"
        channel = {
            "channel": "muse-stable",
            "version": "1.2.3-R4.5",
            "state": "public",
        }

        def fetcher(url):
            if url == resolver.DEFAULT_MUSE_INSTALLER_URL:
                return installer
            return json.dumps(channel).encode()

        with self.assertRaises(resolver.ResolutionError):
            resolver.resolve_muse_code(
                resolver.DEFAULT_MUSE_INSTALLER_URL,
                "0" * 64,
                fetcher,
            )

    def test_rust_stable_verifies_manifest_checksum_and_exact_version(self):
        manifest = b'''manifest-version = "2"\ndate = "2026-09-20"\n\n[pkg.rust]\nversion = "1.90.0 (abcdef123 2026-09-18)"\n'''
        digest = resolver.sha256_bytes(manifest)
        installer = b"rustup installer"

        def fetcher(url):
            if url == resolver.DEFAULT_RUST_MANIFEST_URL:
                return manifest
            if url == resolver.DEFAULT_RUST_MANIFEST_URL + ".sha256":
                return f"{digest}  channel-rust-stable.toml\n".encode()
            if url == resolver.DEFAULT_RUST_INSTALLER_URL:
                return installer
            raise AssertionError(url)

        result = resolver.resolve_rust_stable(fetcher)
        self.assertEqual(result["version"], "1.90.0")
        self.assertEqual(result["channel_manifest_sha256"], digest)
        self.assertEqual(
            result["installer_sha256"], resolver.sha256_bytes(installer)
        )

    def test_all_component_overrides_are_listed_and_component_changes_are_local(self):
        ubuntu = {
            "family": "ubuntu:24.04",
            "identity": "sha256:" + "4" * 64,
            "override": True,
            "provenance": "explicit-override",
        }
        ce = {
            "repository": "https://example.invalid/ce.git",
            "ref": "main",
            "identity": "5" * 40,
            "override": False,
            "provenance": "git-ls-remote",
        }
        openai = {
            "identity": "1.0@sha256:" + "6" * 64,
            "override": False,
        }
        extras = {
            "agent_workspace": {
                "identity": "0.3.3@sha512-x",
                "override": True,
            },
            "rust": {
                "identity": "1.90.0@sha256:" + "7" * 64,
                "override": False,
            },
        }
        first = resolver.build_resolution(ubuntu, ce, openai, extras)
        self.assertEqual(
            first["overrides"], ["agent_workspace", "ubuntu_base"]
        )
        changed_extras = json.loads(json.dumps(extras))
        changed_extras["rust"]["identity"] = "1.91.0@sha256:" + "8" * 64
        second = resolver.build_resolution(
            ubuntu, ce, openai, changed_extras
        )
        self.assertEqual(
            first["components"]["agent_workspace"],
            second["components"]["agent_workspace"],
        )
        self.assertNotEqual(
            first["components"]["rust"], second["components"]["rust"]
        )


    def test_npm_integrity_rejects_malformed_sha512_payload(self):
        metadata = {
            "dist-tags": {"latest": "3.4.5"},
            "versions": {
                "3.4.5": {
                    "dist": {
                        "integrity": "sha512-not-valid-base64!",
                        "shasum": "a" * 40,
                    }
                }
            },
        }
        with self.assertRaises(resolver.ResolutionError):
            resolver.resolve_opencodex(
                None, lambda _url: json.dumps(metadata).encode("utf-8")
            )

    def test_opencodex_uses_frozen_npm_identity(self):
        metadata = {
            "dist-tags": {"latest": "3.4.5"},
            "versions": {
                "3.4.5": {
                    "dist": {
                        "integrity": VALID_SHA512_X,
                        "shasum": "a" * 40,
                    }
                }
            },
        }

        def fake_fetcher(url):
            self.assertIn("%40bitkyc08%2Fopencodex", url)
            return json.dumps(metadata).encode("utf-8")

        result = resolver.resolve_opencodex(None, fake_fetcher)
        self.assertEqual(result["package"], "@bitkyc08/opencodex")
        self.assertEqual(result["version"], "3.4.5")
        self.assertEqual(result["identity"], f"3.4.5@{VALID_SHA512_X}")
        self.assertFalse(result["override"])

    def test_upstream_codex_web_identity_is_distinct_from_fork(self):
        checksum = "b" * 64
        release = {
            "tag_name": "v5.0.8",
            "draft": False,
            "prerelease": False,
            "assets": [
                {
                    "name": "codex-web-gpt-5.0.8-linux-x64.AppImage",
                    "browser_download_url": "https://example.invalid/upstream.AppImage",
                },
                {
                    "name": "checksums.txt",
                    "browser_download_url": "https://example.invalid/checksums.txt",
                },
            ],
        }

        def fake_fetcher(url):
            if url.endswith("/releases/latest"):
                self.assertIn("miuuyy/codex-chatgpt-web", url)
                return json.dumps(release).encode("utf-8")
            if url.endswith("/checksums.txt"):
                return (
                    checksum
                    + "  codex-web-gpt-5.0.8-linux-x64.AppImage\n"
                ).encode("utf-8")
            raise AssertionError(url)

        result = resolver.resolve_codex_web_gpt_upstream(None, fake_fetcher)
        self.assertEqual(result["repository"], "miuuyy/codex-chatgpt-web")
        self.assertEqual(result["package_sha256"], checksum)
        self.assertNotEqual(
            resolver.DEFAULT_CODEX_WEB_REPOSITORY,
            resolver.DEFAULT_CODEX_WEB_UPSTREAM_REPOSITORY,
        )

if __name__ == "__main__":
    unittest.main()

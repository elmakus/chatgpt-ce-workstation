#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("render-build-env.py")
SPEC = importlib.util.spec_from_file_location("render_build_env", SCRIPT)
assert SPEC and SPEC.loader
bridge = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bridge)


def manifest():
    ubuntu_index_name = "archive.ubuntu.com_ubuntu_dists_noble_InRelease"
    ubuntu_index_sha = "9" * 64
    ubuntu_rows = f"{ubuntu_index_name}\t{ubuntu_index_sha}\n"
    ubuntu_identity = "sha256:" + hashlib.sha256(ubuntu_rows.encode()).hexdigest()
    return {
        "components": {
            "agent_workspace": {"identity":"0.3.3@sha512-x","integrity":"sha512-x","override":False,"package":"@agent-sh/agent-workspace-linux","provenance":"npm-registry","shasum":"a"*40,"version":"0.3.3"},
            "ce": {"identity":"b"*40,"override":False,"provenance":"git-ls-remote","ref":"main","repository":"https://example.invalid/ce.git"},
            "chrome": {"architecture":"amd64","identity":"145@sha256:"+"c"*64,"override":False,"package":"google-chrome-stable","package_sha256":"c"*64,"provenance":"google-apt-signed-metadata","repository_path":"pool/chrome.deb","signing_key_sha256":"d"*64,"size":1,"version":"145.0.0-1"},
            "codex_web_gpt": {"asset":"codex.AppImage","identity":"1@sha256:"+"e"*64,"override":False,"package_sha256":"e"*64,"provenance":"github-stable-release-checksums","repository":"elmakus/codex-chatgpt-web","version":"1.0.0"},
            "codex_web_gpt_upstream": {"asset":"codex-upstream.AppImage","identity":"2@sha256:"+"8"*64,"override":False,"package_sha256":"8"*64,"provenance":"github-stable-release-checksums","repository":"miuuyy/codex-chatgpt-web","version":"2.0.0"},
            "muse_code": {"channel":"muse-stable","identity":"1@sha256:"+"f"*64,"installer_sha256":"f"*64,"installer_url":"https://dev.meta.ai/install.sh","override":False,"provenance":"meta-stable-channel-and-installer","version":"1.1.1-R1.1"},
            "openai_chatgpt": {"architecture":"amd64","identity":"1@sha256:"+"1"*64,"override":False,"package":"chatgpt","provenance":"ce-signed-stable-metadata","repository":"https://packages.example","repository_path":"pool/chatgpt.deb","sha256":"1"*64,"size":2,"version":"1.0.0"},
            "opencodex": {"identity":"3.0.0@sha512-z","integrity":"sha512-z","override":False,"package":"@bitkyc08/opencodex","provenance":"npm-registry","shasum":"9"*40,"version":"3.0.0"},
            "rust": {"channel_manifest_sha256":"2"*64,"identity":"1@sha256:"+"2"*64,"installer_sha256":"3"*64,"override":False,"provenance":"rust-static-stable-manifest","version":"1.90.0"},
            "s6_overlay": {"assets":{"s6-overlay-noarch.tar.xz":"4"*64,"s6-overlay-x86_64.tar.xz":"5"*64},"identity":"3.2@sha256:"+"6"*64,"override":False,"provenance":"github-stable-release-assets","repository":"just-containers/s6-overlay","version":"3.2.3.2"},
            "ubuntu_base": {"family":"ubuntu:24.04","identity":"sha256:"+"7"*64,"override":False,"provenance":"docker-registry-manifest"},
            "ubuntu_packages": {"identity":ubuntu_identity,"indexes":[{"name":ubuntu_index_name,"sha256":ubuntu_index_sha}],"override":False,"provenance":"ubuntu-apt-signed-inrelease"},
        },
        "overrides": [],
        "policy": {"channel":"latest-trusted-stable-current","ubuntu_family":"ubuntu:24.04"},
        "schema_version": 1,
    }


class BuildEnvTests(unittest.TestCase):
    def test_exact_inputs_and_candidate_tag_are_stable(self):
        data = manifest()
        payload = bridge.canonical_bytes(data)
        expected_digest = hashlib.sha256(payload).hexdigest()
        values = bridge.build_inputs(data)
        values["UPSTREAM_RESOLUTION_SHA256"] = expected_digest
        values["CANDIDATE_IMAGE_TAG"] = f"candidate-{expected_digest[:16]}"
        self.assertEqual(values["UBUNTU_BASE"], "ubuntu:24.04@sha256:" + "7"*64)
        self.assertEqual(values["CE_COMMIT"], "b"*40)
        self.assertEqual(values["OPENAI_PACKAGE_SHA256"], "1"*64)
        self.assertEqual(values["S6_OVERLAY_NOARCH_SHA256"], "4"*64)
        self.assertEqual(
            values["UBUNTU_APT_INDEXES"],
            "archive.ubuntu.com_ubuntu_dists_noble_InRelease=" + "9"*64,
        )
        self.assertEqual(values["CANDIDATE_IMAGE_TAG"], f"candidate-{expected_digest[:16]}")
        self.assertEqual(values["CODEX_CHATGPT_WEB_UPSTREAM_VERSION"], "2.0.0")
        self.assertEqual(values["OPENCODEX_VERSION"], "3.0.0")

    def test_unknown_fields_are_rejected_before_manifest_embedding(self):
        data = manifest()
        data["components"]["ce"]["secret"] = "do-not-embed"
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "resolution.json"
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(bridge.ManifestError):
                bridge.load_manifest(path)

    def test_override_list_must_match_component_flags(self):
        data = manifest()
        data["components"]["ce"]["override"] = True
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "resolution.json"
            path.write_text(json.dumps(data), encoding="utf-8")
            with self.assertRaises(bridge.ManifestError):
                bridge.load_manifest(path)

    def test_component_changes_reach_only_expected_build_inputs(self):
        cases = [
            ("ce", {"identity": "c"*40}, {"CE_COMMIT"}),
            (
                "openai_chatgpt",
                {"sha256": "a"*64, "identity": "1@sha256:" + "a"*64},
                {"OPENAI_PACKAGE_SHA256"},
            ),
            (
                "agent_workspace",
                {"integrity": "sha512-y", "identity": "0.3.3@sha512-y"},
                {"AGENT_WORKSPACE_INTEGRITY"},
            ),
            (
                "codex_web_gpt",
                {"package_sha256": "a"*64, "identity": "1@sha256:" + "a"*64},
                {"CODEX_CHATGPT_WEB_SHA256"},
            ),
            (
                "codex_web_gpt_upstream",
                {"package_sha256": "a"*64, "identity": "2@sha256:" + "a"*64},
                {"CODEX_CHATGPT_WEB_UPSTREAM_SHA256"},
            ),
            (
                "opencodex",
                {"integrity": "sha512-y", "shasum": "b"*40, "identity": "3.0.0@sha512-y"},
                {"OPENCODEX_INTEGRITY", "OPENCODEX_SHASUM"},
            ),
            (
                "muse_code",
                {"installer_sha256": "a"*64, "identity": "1@sha256:" + "a"*64},
                {"MUSE_INSTALLER_SHA256"},
            ),
            (
                "chrome",
                {"package_sha256": "a"*64, "identity": "145@sha256:" + "a"*64},
                {"CHROME_PACKAGE_SHA256"},
            ),
            (
                "rust",
                {"version": "1.91.0", "identity": "1.91@sha256:" + "a"*64},
                {"RUST_VERSION"},
            ),

        ]
        for component, updates, expected in cases:
            with self.subTest(component=component):
                first = bridge.build_inputs(manifest())
                changed = manifest()
                changed["components"][component].update(updates)
                second = bridge.build_inputs(changed)
                differing = {key for key in first if first[key] != second[key]}
                self.assertEqual(differing, expected)

    def test_ubuntu_index_change_reaches_identity_and_exact_index_set(self):
        first = bridge.build_inputs(manifest())
        changed = manifest()
        index = changed["components"]["ubuntu_packages"]["indexes"][0]
        index["sha256"] = "a"*64
        rows = f'{index["name"]}\t{index["sha256"]}\n'
        changed["components"]["ubuntu_packages"]["identity"] = (
            "sha256:" + hashlib.sha256(rows.encode()).hexdigest()
        )
        second = bridge.build_inputs(changed)
        differing = {key for key in first if first[key] != second[key]}
        self.assertEqual(
            differing, {"UBUNTU_APT_IDENTITY", "UBUNTU_APT_INDEXES"}
        )

    def test_inconsistent_ubuntu_index_identity_is_rejected(self):
        changed = manifest()
        changed["components"]["ubuntu_packages"]["identity"] = "sha256:" + "a"*64
        with self.assertRaises(bridge.ManifestError):
            bridge.build_inputs(changed)

    def test_s6_asset_change_reaches_only_that_frozen_asset_input(self):
        first = bridge.build_inputs(manifest())
        changed = manifest()
        changed["components"]["s6_overlay"]["assets"]["s6-overlay-noarch.tar.xz"] = "a"*64
        changed["components"]["s6_overlay"]["identity"] = "3.2@sha256:" + "a"*64
        second = bridge.build_inputs(changed)
        differing = {key for key in first if first[key] != second[key]}
        self.assertEqual(differing, {"S6_OVERLAY_NOARCH_SHA256"})

    def test_base_digest_change_reaches_exact_from_input(self):
        first = bridge.build_inputs(manifest())
        changed = manifest()
        changed["components"]["ubuntu_base"]["identity"] = "sha256:" + "a"*64
        second = bridge.build_inputs(changed)
        differing = {key for key in first if first[key] != second[key]}
        self.assertEqual(differing, {"UBUNTU_BASE"})

    def test_any_manifest_change_changes_candidate_tag_seed_but_not_unrelated_build_args(self):
        first_manifest = manifest()
        second_manifest = manifest()
        second_manifest["components"]["ce"]["identity"] = "c"*40

        first_digest = hashlib.sha256(bridge.canonical_bytes(first_manifest)).hexdigest()
        second_digest = hashlib.sha256(bridge.canonical_bytes(second_manifest)).hexdigest()
        self.assertNotEqual(first_digest, second_digest)
        self.assertNotEqual(
            f"candidate-{first_digest[:16]}",
            f"candidate-{second_digest[:16]}",
        )

        first_inputs = bridge.build_inputs(first_manifest)
        second_inputs = bridge.build_inputs(second_manifest)
        differing = {key for key in first_inputs if first_inputs[key] != second_inputs[key]}
        self.assertEqual(differing, {"CE_COMMIT"})

    def test_shell_exports_quote_values(self):
        rendered = bridge.shell_exports({"CE_REF":"feature/test", "X":"a b"})
        self.assertIn("export CE_REF=feature/test\n", rendered)
        self.assertIn("export X='a b'\n", rendered)


if __name__ == "__main__":
    unittest.main()

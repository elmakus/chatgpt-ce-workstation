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
    return {
        "components": {
            "agent_workspace": {"identity":"0.3.3@sha512-x","integrity":"sha512-x","override":False,"package":"@agent-sh/agent-workspace-linux","provenance":"npm-registry","shasum":"a"*40,"version":"0.3.3"},
            "ce": {"identity":"b"*40,"override":False,"provenance":"git-ls-remote","ref":"main","repository":"https://example.invalid/ce.git"},
            "chrome": {"architecture":"amd64","identity":"145@sha256:"+"c"*64,"override":False,"package":"google-chrome-stable","package_sha256":"c"*64,"provenance":"google-apt-signed-metadata","repository_path":"pool/chrome.deb","signing_key_sha256":"d"*64,"size":1,"version":"145.0.0-1"},
            "codex_web_gpt": {"asset":"codex.AppImage","identity":"1@sha256:"+"e"*64,"override":False,"package_sha256":"e"*64,"provenance":"github-stable-release-checksums","repository":"elmakus/codex-chatgpt-web","version":"1.0.0"},
            "muse_code": {"channel":"muse-stable","identity":"1@sha256:"+"f"*64,"installer_sha256":"f"*64,"installer_url":"https://dev.meta.ai/install.sh","override":False,"provenance":"meta-stable-channel-and-installer","version":"1.1.1-R1.1"},
            "openai_chatgpt": {"architecture":"amd64","identity":"1@sha256:"+"1"*64,"override":False,"package":"chatgpt","provenance":"ce-signed-stable-metadata","repository":"https://packages.example","repository_path":"pool/chatgpt.deb","sha256":"1"*64,"size":2,"version":"1.0.0"},
            "rust": {"channel_manifest_sha256":"2"*64,"identity":"1@sha256:"+"2"*64,"installer_sha256":"3"*64,"override":False,"provenance":"rust-static-stable-manifest","version":"1.90.0"},
            "s6_overlay": {"assets":{"s6-overlay-noarch.tar.xz":"4"*64,"s6-overlay-x86_64.tar.xz":"5"*64},"identity":"3.2@sha256:"+"6"*64,"override":False,"provenance":"github-stable-release-assets","repository":"just-containers/s6-overlay","version":"3.2.3.2"},
            "ubuntu_base": {"family":"ubuntu:24.04","identity":"sha256:"+"7"*64,"override":False,"provenance":"docker-registry-manifest"},
            "ubuntu_packages": {"identity":"sha256:"+"8"*64,"indexes":[{"name":"archive_InRelease","sha256":"9"*64}],"override":False,"provenance":"ubuntu-apt-signed-inrelease"},
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
        self.assertEqual(values["CANDIDATE_IMAGE_TAG"], f"candidate-{expected_digest[:16]}")

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

    def test_component_change_changes_only_corresponding_build_input(self):
        first = bridge.build_inputs(manifest())
        changed = manifest()
        changed["components"]["rust"]["version"] = "1.91.0"
        changed["components"]["rust"]["identity"] = "1.91@sha256:" + "a"*64
        second = bridge.build_inputs(changed)
        differing = {key for key in first if first[key] != second[key]}
        self.assertEqual(differing, {"RUST_VERSION"})

    def test_shell_exports_quote_values(self):
        rendered = bridge.shell_exports({"CE_REF":"feature/test", "X":"a b"})
        self.assertIn("export CE_REF=feature/test\n", rendered)
        self.assertIn("export X='a b'\n", rendered)


if __name__ == "__main__":
    unittest.main()

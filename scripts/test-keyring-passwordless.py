#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import sys
import tempfile
import types
import unittest


class FakeDBusException(Exception):
    pass


fake_dbus = types.ModuleType("dbus")
fake_dbus.DBusException = FakeDBusException
fake_dbus.ByteArray = bytes
fake_dbus.String = lambda value, **_kwargs: value
fake_dbus.Dictionary = lambda value, **_kwargs: value
fake_dbus.SessionBus = object
fake_dbus.Interface = lambda obj, _iface: obj
sys.modules["dbus"] = fake_dbus

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "keyring_passwordless",
    ROOT / "scripts" / "container" / "keyring-passwordless.py",
)
assert SPEC and SPEC.loader
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class FakeService:
    def __init__(self, login="/login", default="/replacement"):
        self.aliases = {"login": login, "default": default}
        self.set_calls: list[tuple[str, str]] = []

    def ReadAlias(self, name):
        return self.aliases[name]

    def SetAlias(self, name, collection):
        if name == "login":
            raise FakeDBusException("Only the default alias is supported")
        self.aliases[name] = str(collection)
        self.set_calls.append((name, str(collection)))

    def OpenSession(self, _algorithm, _value):
        return b"", "/session"


class FakeInternal:
    def __init__(self, service=None):
        self.calls: list[tuple] = []
        self.created = "/fresh"
        self.service = service

    def CreateWithMasterPassword(self, attrs, _master):
        self.calls.append(("create", attrs["org.freedesktop.Secret.Collection.Label"]))
        if self.service is not None and attrs["org.freedesktop.Secret.Collection.Label"] == "login":
            self.service.aliases["login"] = self.created
        return self.created

    def UnlockWithMasterPassword(self, collection, _secret):
        self.calls.append(("unlock", str(collection)))

    def ChangeWithMasterPassword(self, collection, _old, _new):
        self.calls.append(("change", str(collection)))


class HelperTests(unittest.TestCase):
    def test_migration_prefers_item_rich_login_collection_over_stale_alias(self):
        selected = helper.choose_collection(
            "/empty-login",
            "/replacement",
            [
                ("/empty-login", "Login", 0),
                ("/replacement", "Login", 1),
                ("/legacy", "Login", 4),
            ],
            migration_mode=True,
        )
        self.assertEqual(selected, "/legacy")

    def test_nonmigration_prefers_login_alias(self):
        selected = helper.choose_collection(
            "/login",
            "/default",
            [("/login", "Login", 0), ("/default", "Login", 9)],
            migration_mode=False,
        )
        self.assertEqual(selected, "/login")

    def run_ensure(self, *, old_password, marker_exists=False, aliases=("/login", "/default")):
        td = tempfile.TemporaryDirectory()
        self.addCleanup(td.cleanup)
        root = pathlib.Path(td.name)
        marker = root / "marker"
        backup = root / "backup"
        keyrings = root / "keyrings"
        keyrings.mkdir()
        (keyrings / "login.keyring").write_bytes(b"legacy-bytes")
        if marker_exists:
            marker.write_text(helper.MARKER_PAYLOAD, encoding="utf-8")

        service = FakeService(*aliases)
        internal = FakeInternal(service)

        helper.service_collections = lambda _obj: ["/login", "/default", "/session"]
        helper.collection_metadata = lambda _bus, path: (
            ("Login", 4) if path == "/login" else ("Login", 1)
        )
        helper.collection_locked = lambda _bus, _collection: False

        result = helper.ensure_passwordless(
            object(),
            object(),
            service,
            internal,
            marker,
            backup,
            keyrings,
            old_password,
        )
        return result, marker, backup, service, internal

    def test_transient_unlocked_credentialed_collection_still_changes_password(self):
        result, marker, backup, service, internal = self.run_ensure(old_password=b"legacy")
        self.assertEqual(result, "/login")
        self.assertIn(("change", "/login"), internal.calls)
        self.assertTrue(backup.is_dir())
        self.assertEqual(marker.read_text(encoding="utf-8"), "passwordless-v2\n")
        self.assertEqual(service.aliases["login"], "/login")
        self.assertEqual(service.aliases["default"], "/login")

    def test_existing_unmarked_passwordless_collection_is_proved_empty(self):
        _result, marker, _backup, _service, internal = self.run_ensure(old_password=None)
        self.assertIn(("change", "/login"), internal.calls)
        self.assertTrue(marker.is_file())

    def test_v2_marker_skips_master_password_change_but_converges_aliases(self):
        _result, _marker, _backup, service, internal = self.run_ensure(
            old_password=None,
            marker_exists=True,
        )
        self.assertNotIn(("change", "/login"), internal.calls)
        self.assertEqual(service.aliases["login"], "/login")
        self.assertEqual(service.aliases["default"], "/login")

    def test_fresh_collection_sets_login_and_default_aliases(self):
        td = tempfile.TemporaryDirectory()
        self.addCleanup(td.cleanup)
        root = pathlib.Path(td.name)
        service = FakeService("/", "/")
        internal = FakeInternal(service)
        helper.service_collections = lambda _obj: ["/session"]
        helper.collection_locked = lambda _bus, _collection: False
        result = helper.ensure_passwordless(
            object(),
            object(),
            service,
            internal,
            root / "marker",
            root / "backup",
            root / "keyrings",
            None,
        )
        self.assertEqual(result, "/fresh")
        self.assertEqual(service.aliases, {"login": "/fresh", "default": "/fresh"})
        self.assertNotIn(("login", "/fresh"), service.set_calls)
        self.assertIn(("default", "/fresh"), service.set_calls)
        self.assertIn(("create", "login"), internal.calls)


if __name__ == "__main__":
    unittest.main()

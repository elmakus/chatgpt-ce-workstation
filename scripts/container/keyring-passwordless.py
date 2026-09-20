#!/usr/bin/env python3
"""Ensure the workstation Secret Service uses a passwordless persistent collection."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import sys

import dbus

BUS_NAME = "org.freedesktop.secrets"
SERVICE_PATH = "/org/freedesktop/secrets"
SERVICE_IFACE = "org.freedesktop.Secret.Service"
INTERNAL_IFACE = "org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface"
COLLECTION_IFACE = "org.freedesktop.Secret.Collection"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--marker", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--password-file")
    return parser.parse_args()


def secret(session: object, value: bytes) -> tuple[object, object, object, str]:
    return (
        session,
        dbus.ByteArray(b""),
        dbus.ByteArray(value),
        "text/plain",
    )


def read_password(path: str | None) -> bytes | None:
    if not path:
        return None
    password_path = Path(path)
    if not password_path.is_file():
        return None
    value = password_path.read_bytes().rstrip(b"\r\n")
    return value or None


def atomic_marker(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text("passwordless-v1\n", encoding="utf-8")
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def backup_keyrings(source: Path, backup: Path) -> None:
    if backup.exists() or not source.exists():
        return
    shutil.copytree(source, backup, symlinks=True)


def locked(bus: dbus.SessionBus, collection: object) -> bool:
    obj = bus.get_object(BUS_NAME, str(collection))
    props = dbus.Interface(obj, PROPERTIES_IFACE)
    return bool(props.Get(COLLECTION_IFACE, "Locked"))


def main() -> int:
    args = parse_args()
    marker = Path(args.marker)
    backup = Path(args.backup)
    keyring_dir = Path.home() / ".local" / "share" / "keyrings"
    old_password = read_password(args.password_file)

    bus = dbus.SessionBus()
    obj = bus.get_object(BUS_NAME, SERVICE_PATH)
    service = dbus.Interface(obj, SERVICE_IFACE)
    internal = dbus.Interface(obj, INTERNAL_IFACE)

    collection = service.ReadAlias("default")
    if str(collection) == "/":
        login_alias = service.ReadAlias("login")
        if str(login_alias) != "/":
            collection = login_alias

    _, session = service.OpenSession("plain", b"")
    empty = secret(session, b"")

    if str(collection) == "/":
        attrs = dbus.Dictionary(
            {"org.freedesktop.Secret.Collection.Label": dbus.String("Login", variant_level=1)},
            signature="sv",
        )
        collection = internal.CreateWithMasterPassword(attrs, empty)
        service.SetAlias("default", collection)
    elif locked(bus, collection):
        try:
            internal.UnlockWithMasterPassword(collection, empty)
        except dbus.DBusException:
            if old_password is None:
                raise RuntimeError(
                    "existing keyring is encrypted and no migration password is available"
                )
            backup_keyrings(keyring_dir, backup)
            old = secret(session, old_password)
            internal.UnlockWithMasterPassword(collection, old)
            internal.ChangeWithMasterPassword(collection, old, empty)

    if locked(bus, collection):
        raise RuntimeError("passwordless keyring remained locked after migration")

    atomic_marker(marker)
    print(str(collection))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"keyring-passwordless: {exc}", file=sys.stderr)
        raise SystemExit(1)

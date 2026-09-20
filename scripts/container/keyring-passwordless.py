#!/usr/bin/env python3
"""Ensure the workstation Secret Service uses a passwordless persistent login collection."""

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
MARKER_PAYLOAD = "passwordless-v2\n"


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
    tmp.write_text(MARKER_PAYLOAD, encoding="utf-8")
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def backup_keyrings(source: Path, backup: Path) -> None:
    if backup.exists() or not source.exists():
        return
    shutil.copytree(source, backup, symlinks=True)


def collection_properties(bus: dbus.SessionBus, collection: object) -> object:
    obj = bus.get_object(BUS_NAME, str(collection))
    return dbus.Interface(obj, PROPERTIES_IFACE)


def collection_locked(bus: dbus.SessionBus, collection: object) -> bool:
    props = collection_properties(bus, collection)
    return bool(props.Get(COLLECTION_IFACE, "Locked"))


def collection_metadata(bus: dbus.SessionBus, collection: object) -> tuple[str, int]:
    props = collection_properties(bus, collection)
    label = str(props.Get(COLLECTION_IFACE, "Label"))
    items = props.Get(COLLECTION_IFACE, "Items")
    return label, len(items)


def service_collections(service_object: object) -> list[str]:
    props = dbus.Interface(service_object, PROPERTIES_IFACE)
    return [str(path) for path in props.Get(SERVICE_IFACE, "Collections")]


def choose_collection(
    login_alias: str,
    default_alias: str,
    candidates: list[tuple[str, str, int]],
    migration_mode: bool,
) -> str:
    selected = login_alias if login_alias != "/" else default_alias
    if not migration_mode:
        return selected

    login_candidates = [
        (item_count, path)
        for path, label, item_count in candidates
        if path != "/" and not path.endswith("/session") and label.casefold() == "login"
    ]
    if not login_candidates:
        return selected

    login_candidates.sort(reverse=True)
    best_count, best_path = login_candidates[0]
    selected_count = next(
        (count for path, _label, count in candidates if path == selected),
        -1,
    )
    if selected == "/" or best_count > selected_count:
        return best_path
    return selected


def ensure_passwordless(
    bus: dbus.SessionBus,
    service_object: object,
    service: object,
    internal: object,
    marker: Path,
    backup: Path,
    keyring_dir: Path,
    old_password: bytes | None,
) -> object:
    login_alias = str(service.ReadAlias("login"))
    default_alias = str(service.ReadAlias("default"))

    metadata: list[tuple[str, str, int]] = []
    for path in service_collections(service_object):
        if path.endswith("/session"):
            continue
        try:
            label, count = collection_metadata(bus, path)
        except dbus.DBusException:
            continue
        metadata.append((path, label, count))

    collection = choose_collection(
        login_alias,
        default_alias,
        metadata,
        migration_mode=(old_password is not None and not marker.exists()),
    )

    _, session = service.OpenSession("plain", b"")
    empty = secret(session, b"")

    if str(collection) == "/":
        if marker.exists():
            raise RuntimeError("passwordless marker exists but persistent login collection is missing")
        attrs = dbus.Dictionary(
            {"org.freedesktop.Secret.Collection.Label": dbus.String("login", variant_level=1)},
            signature="sv",
        )
        collection = internal.CreateWithMasterPassword(attrs, empty)
    elif not marker.exists():
        backup_keyrings(keyring_dir, backup)

        if old_password is not None:
            old = secret(session, old_password)
            if collection_locked(bus, collection):
                internal.UnlockWithMasterPassword(collection, old)
            internal.ChangeWithMasterPassword(collection, old, empty)
        else:
            if collection_locked(bus, collection):
                internal.UnlockWithMasterPassword(collection, empty)
            internal.ChangeWithMasterPassword(collection, empty, empty)

    if collection_locked(bus, collection):
        internal.UnlockWithMasterPassword(collection, empty)
    if collection_locked(bus, collection):
        raise RuntimeError("passwordless keyring remained locked after migration")

    # GNOME keyring exposes "login" as a natural/reserved alias derived from
    # the canonical login collection; this implementation only permits writing
    # the "default" alias. Preserve/prove the natural login alias and converge
    # default onto the same collection.
    service.SetAlias("default", collection)

    if str(service.ReadAlias("login")) != str(collection):
        raise RuntimeError("login alias did not converge on migrated collection")
    if str(service.ReadAlias("default")) != str(collection):
        raise RuntimeError("default alias did not converge on migrated collection")

    atomic_marker(marker)
    return collection


def main() -> int:
    args = parse_args()
    marker = Path(args.marker)
    backup = Path(args.backup)
    keyring_dir = Path.home() / ".local" / "share" / "keyrings"
    old_password = read_password(args.password_file)

    bus = dbus.SessionBus()
    service_object = bus.get_object(BUS_NAME, SERVICE_PATH)
    service = dbus.Interface(service_object, SERVICE_IFACE)
    internal = dbus.Interface(service_object, INTERNAL_IFACE)

    collection = ensure_passwordless(
        bus,
        service_object,
        service,
        internal,
        marker,
        backup,
        keyring_dir,
        old_password,
    )
    print(str(collection))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"keyring-passwordless: {exc}", file=sys.stderr)
        raise SystemExit(1)

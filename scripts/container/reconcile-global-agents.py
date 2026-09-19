#!/usr/bin/env python3
from __future__ import annotations
import argparse
import os
from pathlib import Path
import stat
import sys
import tempfile

START_TOKEN = b"<!-- chatgpt-ce-workstation-managed-start -->"
END_TOKEN = b"<!-- chatgpt-ce-workstation-managed-end -->"

class MalformedManagedState(ValueError):
    pass

def _payload_block(payload: bytes) -> bytes:
    if not payload.endswith(b"\n"):
        payload += b"\n"
    return START_TOKEN + b"\n" + payload + END_TOKEN + b"\n"

def _managed_span(data: bytes) -> tuple[int, int] | None:
    starts = data.count(START_TOKEN)
    ends = data.count(END_TOKEN)
    if starts == 0 and ends == 0:
        return None
    if starts != 1 or ends != 1:
        raise MalformedManagedState(
            f"expected one workstation marker pair, found start={starts} end={ends}"
        )
    start = data.find(START_TOKEN)
    end = data.find(END_TOKEN)
    start_after = start + len(START_TOKEN)
    end_after = end + len(END_TOKEN)
    if start > 0 and data[start - 1 : start] != b"\n":
        raise MalformedManagedState("workstation start marker is not on its own line")
    if data[start_after : start_after + 1] != b"\n":
        raise MalformedManagedState("workstation start marker is not newline-terminated")
    if end <= start_after:
        raise MalformedManagedState("workstation end marker does not follow start marker")
    if data[end - 1 : end] != b"\n":
        raise MalformedManagedState("workstation end marker is not on its own line")
    if data[end_after : end_after + 1] != b"\n":
        raise MalformedManagedState("workstation end marker is not newline-terminated")
    return start, end_after + 1

def _atomic_write(path: Path, data: bytes, uid: int, gid: int, mode: int) -> None:
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp = Path(temp_name)
    try:
        with os.fdopen(fd, "wb", closefd=True) as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
            os.fchmod(handle.fileno(), mode)
            try:
                os.fchown(handle.fileno(), uid, gid)
            except PermissionError:
                if uid != os.getuid() or gid != os.getgid():
                    raise
        os.replace(temp, path)
        try:
            dir_fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        except (AttributeError, OSError):
            return
        try:
            os.fsync(dir_fd)
        finally:
            os.close(dir_fd)
    finally:
        if temp.exists():
            temp.unlink()

def reconcile(target: Path, payload: bytes, legacy_payloads: list[bytes],
              uid: int, gid: int, mode: int) -> str:
    managed = _payload_block(payload)
    if target.is_symlink():
        return "skipped-ambiguous: target is a symlink; manual reconciliation required"
    if target.exists() and not stat.S_ISREG(target.stat().st_mode):
        return "skipped-ambiguous: target is not a regular file; manual reconciliation required"
    if not target.exists():
        _atomic_write(target, managed, uid, gid, mode)
        return "seeded"

    data = target.read_bytes()
    try:
        span = _managed_span(data)
    except MalformedManagedState as exc:
        return f"skipped-malformed: {exc}; manual reconciliation required"

    if span is not None:
        start, stop = span
        updated = data[:start] + managed + data[stop:]
        if updated == data:
            return "current"
        _atomic_write(target, updated, uid, gid, mode)
        return "updated"

    matches = [legacy for legacy in legacy_payloads if data.startswith(legacy)]
    if len(matches) == 1:
        legacy = matches[0]
        _atomic_write(target, managed + data[len(legacy):], uid, gid, mode)
        return "migrated"
    if len(matches) > 1:
        return "skipped-ambiguous: multiple legacy workstation prefixes match; manual reconciliation required"
    return "skipped-ambiguous: unrecognized unmarked AGENTS content; manual reconciliation required"

def check_current(target: Path, payload: bytes) -> tuple[bool, str]:
    if target.is_symlink() or not target.is_file():
        return False, "target is missing or not a regular file"
    data = target.read_bytes()
    try:
        span = _managed_span(data)
    except MalformedManagedState as exc:
        return False, str(exc)
    if span is None:
        return False, "workstation-managed block is missing"
    start, stop = span
    if data[start:stop] != _payload_block(payload):
        return False, "workstation-managed block does not match current image payload"
    return True, "current managed workstation block verified"

def _parse_mode(value: str) -> int:
    try:
        mode = int(value, 8)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("mode must be octal, e.g. 0644") from exc
    if not 0 <= mode <= 0o7777:
        raise argparse.ArgumentTypeError("mode is outside valid permission range")
    return mode

def main() -> int:
    parser = argparse.ArgumentParser(description="Reconcile workstation-owned global AGENTS content.")
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--payload", type=Path, required=True)
    parser.add_argument("--legacy", type=Path, action="append", default=[])
    parser.add_argument("--uid", type=int, default=os.getuid())
    parser.add_argument("--gid", type=int, default=os.getgid())
    parser.add_argument("--mode", type=_parse_mode, default=0o644)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    payload = args.payload.read_bytes()
    if args.check:
        ok, detail = check_current(args.target, payload)
        print(f"[global-agents] {detail}", file=sys.stdout if ok else sys.stderr)
        return 0 if ok else 1

    legacy_payloads = [path.read_bytes() for path in args.legacy]
    result = reconcile(args.target, payload, legacy_payloads, args.uid, args.gid, args.mode)
    print(f"[global-agents] {result}",
          file=sys.stderr if result.startswith("skipped-") else sys.stdout)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

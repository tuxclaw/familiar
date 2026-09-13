#!/usr/bin/env python3
"""Fixed-path dock pin storage. Arguments contain an operation and data, never a path."""
import fcntl
import json
import os
import re
from pathlib import Path
import stat
import sys
import tempfile


def app_id(value):
    if not isinstance(value, str):
        raise ValueError("expected app id")
    value = value.strip().removesuffix(".desktop")
    if not value or value in (".", "..") or re.search(r"[/\\\x00-\x1f\x7f]", value):
        raise ValueError("invalid app id")
    return value


def validate(data):
    if not isinstance(data, dict) or set(data) != {"pins"} or not isinstance(data["pins"], list):
        raise ValueError("expected {pins: [...]}")
    seen, folders, pins = set(), set(), []

    def unique(value):
        value = app_id(value)
        if value in seen:
            return None
        seen.add(value)
        return value

    for pin in data["pins"]:
        if isinstance(pin, str):
            value = unique(pin)
            if value is not None:
                pins.append(value)
            continue
        if (not isinstance(pin, dict) or set(pin) != {"type", "id", "name", "items"}
                or pin["type"] != "folder" or not isinstance(pin["id"], str)
                or not re.fullmatch(r"[A-Za-z0-9_-]{1,80}", pin["id"]) or pin["id"] in folders
                or not isinstance(pin["name"], str) or not pin["name"].strip()
                or len(pin["name"].encode("utf-16-le")) // 2 > 64
                or re.search(r"[/\\\x00-\x1f\x7f]", pin["name"])
                or not isinstance(pin["items"], list)):
            raise ValueError("invalid folder")
        folders.add(pin["id"])
        items = [value for item in pin["items"] if (value := unique(item)) is not None]
        pins.append({"type": "folder", "id": pin["id"], "name": pin["name"].strip(), "items": items})
    return {"pins": pins}


def read_json(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd) as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ValueError("refusing non-regular file")
        return json.load(stream)


def run(args):
    if args == ["--read"]:
        data = None
    elif len(args) == 2 and args[0] == "--write":
        data = validate(json.loads(args[1]))
    else:
        raise ValueError("expected --read or --write JSON; paths are not accepted")

    directory = Path.home() / ".config" / "omarchy"
    for parent in reversed([directory, *directory.parents]):
        if parent.is_symlink():
            raise ValueError("refusing symlink directory")
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / "familiar-dock.json"
    lock = os.open(directory / ".familiar-dock.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(lock, "w") as guard:
        fcntl.flock(guard, fcntl.LOCK_EX)
        if target.is_symlink():
            raise ValueError("refusing symlink pin file")
        if data is None and target.exists():
            return validate(read_json(target))
        if data is None:
            # Only absence triggers migration. Empty or invalid existing files never do.
            try:
                config = read_json(directory / "shell.json")
            except FileNotFoundError:
                config = {}
            legacy = config.get("bar", {}).get("dockPinned", "")
            pins = []
            for pin in legacy.split(",") if isinstance(legacy, str) else []:
                pin = pin.strip().removesuffix(".desktop")
                if pin and pin not in pins:
                    pins.append(pin)
            data = validate({"pins": pins})
        temporary = None
        try:
            fd, temporary = tempfile.mkstemp(prefix=".familiar-dock-", dir=directory)
            with os.fdopen(fd, "w") as stream:
                json.dump(data, stream)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            if target.is_symlink():
                raise ValueError("refusing symlink pin file")
            os.replace(temporary, target)
            temporary = None
            fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
        finally:
            if temporary is not None:
                os.unlink(temporary)
        return data


if __name__ == "__main__":
    try:
        print(json.dumps(run(sys.argv[1:])))
    except (OSError, ValueError, TypeError, AttributeError) as error:
        print("Familiar dock pins: " + str(error), file=sys.stderr)
        sys.exit(1)

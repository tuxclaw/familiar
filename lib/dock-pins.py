#!/usr/bin/env python3
"""Fixed-path dock pin storage. Arguments select an operation; JSON arrives on stdin."""
import fcntl
import json
import os
import re
from pathlib import Path
import stat
import sys
import secrets
from contextlib import contextmanager

MAX_STDIN_BYTES = 1024 * 1024


def app_id(value):
    if not isinstance(value, str):
        raise ValueError("expected app id")
    value = value.strip().removesuffix(".desktop")
    if not value or value in (".", "..") or re.search(r"[/\\\x00-\x1f\x7f]", value):
        raise ValueError("invalid app id")
    return value


WIDGET_IDS = {"omarchy.weather", "omarchy.audio", "omarchy.microphone", "omarchy.bluetooth",
              "omarchy.network", "omarchy.power", "omarchy.clock", "omarchy.monitor", "omarchy.tailscale"}


def validate(data):
    if not isinstance(data, dict) or set(data) not in ({"pins"}, {"pins", "widgets", "widgetSide"}) or not isinstance(data["pins"], list):
        raise ValueError("expected {pins: [...]}")
    widgets, side = data.get("widgets", []), data.get("widgetSide", "right")
    if (not isinstance(widgets, list) or not isinstance(side, str) or side not in ("left", "right")
            or any(not isinstance(value, str) or value not in WIDGET_IDS for value in widgets)):
        raise ValueError("invalid widgets or side")
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
    return {"pins": pins, "widgets": list(dict.fromkeys(widgets)), "widgetSide": side}


@contextmanager
def config_directory():
    # Anchor each component before traversing the next: renames cannot redirect
    # later storage operations, and no component may be a symlink.
    directory = Path.home() / ".config" / "omarchy"
    if not directory.is_absolute() or ".." in directory.parts:
        raise ValueError("invalid home directory")
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    fd = os.open("/", flags)
    try:
        for component in directory.parts[1:]:
            try:
                child = os.open(component, flags, dir_fd=fd)
            except FileNotFoundError:
                try:
                    os.mkdir(component, 0o700, dir_fd=fd)
                except FileExistsError:
                    pass
                child = os.open(component, flags, dir_fd=fd)
            os.close(fd)
            fd = child
        yield fd
    finally:
        os.close(fd)


def refuse_symlink(directory_fd, name):
    try:
        info = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
    except FileNotFoundError:
        return
    if stat.S_ISLNK(info.st_mode):
        raise ValueError("refusing symlink pin file")


def read_json(directory_fd, name):
    fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory_fd)
    with os.fdopen(fd) as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ValueError("refusing non-regular file")
        return json.load(stream)


def run(args):
    if args == ["--read"]:
        data = None
    elif args == ["--write"]:
        payload = sys.stdin.buffer.readline(MAX_STDIN_BYTES + 1)
        if len(payload) > MAX_STDIN_BYTES:
            raise ValueError("stdin size limit exceeded")
        data = validate(json.loads(payload.decode("utf-8")))
    else:
        raise ValueError("expected only --read or --write")

    with config_directory() as directory_fd:
        return store(directory_fd, data)


def store(directory_fd, data):
    target = "familiar-dock.json"
    lock = os.open(".familiar-dock.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600,
                   dir_fd=directory_fd)
    with os.fdopen(lock, "w") as guard:
        fcntl.flock(guard, fcntl.LOCK_EX)
        refuse_symlink(directory_fd, target)
        if data is None:
            try:
                stored = read_json(directory_fd, target)
            except FileNotFoundError:
                pass
            else:
                data = validate(stored)
                if set(stored) == {"pins", "widgets", "widgetSide"}:
                    return data
                # Upgrade a pre-widget document using the same atomic replacement.

        if data is None:
            # Only absence triggers migration. Empty or invalid existing files never do.
            try:
                config = read_json(directory_fd, "shell.json")
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
            for attempt in range(100):
                candidate = ".familiar-dock-" + secrets.token_hex(16)
                try:
                    fd = os.open(candidate, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                 0o600, dir_fd=directory_fd)
                except FileExistsError:
                    continue
                temporary = candidate
                break
            else:
                raise FileExistsError("cannot create temporary file")
            with os.fdopen(fd, "w") as stream:
                json.dump(data, stream)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            refuse_symlink(directory_fd, target)
            os.replace(temporary, target, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
            temporary = None
            os.fsync(directory_fd)
        finally:
            if temporary is not None:
                os.unlink(temporary, dir_fd=directory_fd)
        return data


if __name__ == "__main__":
    try:
        print(json.dumps(run(sys.argv[1:])))
    except (OSError, ValueError, TypeError, AttributeError, RecursionError):
        # Exceptions can contain document contents or user paths; never log them.
        print("Familiar dock pins: operation refused", file=sys.stderr)
        sys.exit(1)

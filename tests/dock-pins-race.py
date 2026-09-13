#!/usr/bin/env python3
"""Exercise the real stdin CLI with deterministic parent swaps in isolated HOME."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
DOCUMENT = {"pins": ["safe-app"], "widgets": ["omarchy.clock"], "widgetSide": "left"}
HARNESS = r'''
import fcntl
import os
from pathlib import Path
import runpy
import sys

writer, component, stage = sys.argv[1:]
home = Path.home()
parent = home / ".config"
if component == "omarchy":
    parent /= "omarchy"
outside = home / "outside"

def swap():
    parent.rename(parent.with_name(parent.name + "-held"))
    parent.symlink_to(outside, target_is_directory=True)

if stage == "locked":
    original = fcntl.flock
    def flock(*args):
        original(*args)
        swap()
    fcntl.flock = flock
else:
    original = os.replace
    def replace(*args, **kwargs):
        swap()
        return original(*args, **kwargs)
    os.replace = replace

sys.argv = [writer, "--write"]
runpy.run_path(writer, run_name="__main__")
'''


class ParentSwapTests(unittest.TestCase):
    def test_swapped_parent_cannot_redirect_write(self):
        for component in ("omarchy", ".config"):
            for stage in ("locked", "replace"):
                for existing in (False, True):
                    with self.subTest(component=component, stage=stage, existing=existing):
                        with tempfile.TemporaryDirectory(prefix="dock-race-", dir=ROOT) as temporary:
                            home = Path(temporary)
                            directory = home / ".config" / "omarchy"
                            directory.mkdir(parents=True)
                            outside = home / "outside"
                            outside.mkdir()
                            outside_config = outside if component == "omarchy" else outside / "omarchy"
                            outside_config.mkdir(exist_ok=True)
                            target = outside_config / "familiar-dock.json"
                            sentinel = b"outside document must remain untouched\n"
                            if existing:
                                target.write_bytes(sentinel)
                            result = subprocess.run(
                                [sys.executable, "-c", HARNESS, str(ROOT / "lib/dock-pins.py"),
                                 component, stage],
                                input=json.dumps(DOCUMENT) + "\n", text=True, capture_output=True,
                                env={**os.environ, "HOME": str(home)}, timeout=10,
                            )
                            self.assertEqual(result.returncode, 0, result.stderr)
                            self.assertEqual(result.stderr, "")
                            self.assertEqual(json.loads(result.stdout), DOCUMENT)
                            if existing:
                                self.assertEqual(target.read_bytes(), sentinel)
                            else:
                                self.assertFalse(target.exists())
                            held = (directory.with_name("omarchy-held") if component == "omarchy"
                                    else home / ".config-held" / "omarchy")
                            self.assertEqual(json.loads((held / "familiar-dock.json").read_text()), DOCUMENT)
                            self.assertEqual(sorted(p.name for p in held.iterdir()),
                                             [".familiar-dock.lock", "familiar-dock.json"])
                            self.assertEqual(sorted(p.name for p in outside_config.iterdir()),
                                             ["familiar-dock.json"] if existing else [])


if __name__ == "__main__":
    unittest.main()

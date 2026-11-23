#!/usr/bin/env python3
"""The map of Grace's parts cannot drift (unit `docs: the map of Grace's parts`): check.py's map_findings."""
import os
import sys
import tempfile
import unittest
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check  # noqa: E402

MAP = """<!-- grace-map:start -->
## The map

- **Atoms** — one idea. Example: [Personal Todo](./atoms/personal-todo.md).
- **Bonds** *(planned)* — how atoms connect. Not yet: `bonds.md`.
<!-- grace-map:end -->
"""


class MapTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "atoms").mkdir()
        (self.root / "atoms" / "personal-todo.md").write_text("# x\n")
        for name in check.MAP_FILES:
            (self.root / name).write_text("# top\n" + MAP)

    def codes(self):
        return [f.code for f in check.map_findings(self.root)]

    def test_two_equal_copies_that_resolve_pass(self):
        self.assertEqual(self.codes(), [])

    def test_a_missing_map_is_named(self):
        (self.root / "readme.md").write_text("# no map\n")
        self.assertEqual(self.codes(), ["G-map-missing"])

    def test_a_copy_that_differs_is_named(self):
        (self.root / "readme.md").write_text("# top\n" + MAP.replace("one idea", "one idea, reworded"))
        self.assertEqual(self.codes(), ["G-map-differs"])

    def test_an_example_that_is_no_file_is_named_in_each_copy(self):
        for name in check.MAP_FILES:
            (self.root / name).write_text("# top\n" + MAP.replace("personal-todo.md", "gone.md"))
        self.assertEqual(self.codes(), ["G-map-dead", "G-map-dead"])

    def test_a_planned_part_whose_file_exists_must_drop_its_mark(self):
        (self.root / "bonds.md").write_text("# Bonds\n")
        self.assertEqual(self.codes(), ["G-map-planned", "G-map-planned"])

    def test_not_yet_on_a_part_not_marked_planned_is_named(self):
        for name in check.MAP_FILES:
            (self.root / name).write_text("# top\n" + MAP.replace("*(planned)*", ""))
        self.assertEqual(self.codes(), ["G-map-planned", "G-map-planned"])

    def test_the_repository_map_passes(self):
        self.assertEqual(check.map_findings(Path(HERE).resolve().parents[1]), [])


if __name__ == "__main__":
    unittest.main()

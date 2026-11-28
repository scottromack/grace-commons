#!/usr/bin/env python3
"""tools/grace/layout.py: the move of `library: the files match the tree` maps both ways, and a page
compares equal to itself across the move whatever its links and its menu keys say.

    python3 tools/grace/test_layout.py
"""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import layout  # noqa: E402


class Paths(unittest.TestCase):
    def test_a_page_maps_both_ways(self):
        for old, new in (("atoms/lease.md", "library/atoms/lease.idd"),
                         ("compositions/models/x.tla", "library/compositions/models/x.tla"),
                         ("method.md", "how/method.md"), ("GRACE-lang.hist.md", "how/GRACE-lang.hist.md"),
                         ("roadmap.md", "log/roadmap.md"), ("atoms", "library/atoms")):
            self.assertEqual(layout.new_path(old), new)
            self.assertEqual(layout.old_path(new), old)

    def test_a_page_renamed_after_its_move(self):
        # atoms/lease.md -> library/atoms/lease.md (the folder move) -> library/atoms/lease.idd (the .idd sweep)
        self.assertEqual(layout.new_path("library/atoms/lease.md"), "library/atoms/lease.idd")
        self.assertEqual(layout.new_path("library/compositions/login.md"), "library/compositions/login.md")

    def test_a_page_that_never_moved_is_itself(self):
        for path in ("readme.md", "corpus.md", "evidence.md", "tools/grace/check.py", "library/atoms/lease.idd"):
            self.assertEqual(layout.new_path(path), path)


class Neutral(unittest.TestCase):
    BEFORE = ("---\ntitle: X\nparent: Atomic Concepts\nnav_order: 3\n---\n"
              "See [m](../method.md#a), [e](../execution-contract.md) and "
              "[g](https://github.com/scottromack/grace-commons/blob/main/atoms/models/x.tla).\n")
    AFTER = ("---\ntitle: X\n---\n"
             "See [m](../../how/method.md#a), [e](../execution-contract.md) and "
             "[g](https://github.com/scottromack/grace-commons/blob/main/library/atoms/models/x.tla).\n")

    def test_the_move_changes_nothing_a_reader_reads(self):
        self.assertEqual(layout.neutral(self.BEFORE, "atoms/x.md"), layout.neutral(self.AFTER, "library/atoms/x.md"))

    def test_a_retargeted_link_still_shows(self):
        moved = self.AFTER.replace("how/method.md", "how/glossary.md")
        self.assertNotEqual(layout.neutral(self.BEFORE, "atoms/x.md"), layout.neutral(moved, "library/atoms/x.md"))

    def test_a_changed_title_still_shows(self):
        retitled = self.AFTER.replace("title: X", "title: Y")
        self.assertNotEqual(layout.neutral(self.BEFORE, "atoms/x.md"), layout.neutral(retitled, "library/atoms/x.md"))


class FoundAt(unittest.TestCase):
    def test_a_page_is_read_at_a_revision_under_its_old_path(self):
        with tempfile.TemporaryDirectory() as d:
            git = lambda *a: subprocess.run(["git", "-C", d, *a], capture_output=True, text=True, check=True)
            git("init", "-q")
            git("config", "user.email", "t@example.com")
            git("config", "user.name", "t")
            (Path(d) / "atoms").mkdir()
            (Path(d) / "atoms" / "x.md").write_text("old\n", encoding="utf-8")
            git("add", "-A")
            git("commit", "-q", "-m", "before")
            rev = git("rev-parse", "HEAD").stdout.strip()
            (Path(d) / "library").mkdir()
            git("mv", "atoms", "library/atoms")
            git("commit", "-q", "-m", "moved")
            self.assertEqual(layout.found_at(d, rev, "library/atoms/x.md"), ("old\n", "atoms/x.md"))
            self.assertEqual(layout.text_at(d, "HEAD", "library/atoms/x.md"), "old\n")
            self.assertEqual(layout.found_at(d, rev, "library/atoms/none.md"), (None, None))


if __name__ == "__main__":
    unittest.main()

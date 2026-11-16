#!/usr/bin/env python3
"""Tests for external_links.py (unit `site: a weekly report of links to other sites`): which links it reads, nothing asked.

    python3 tools/linter/test_external_links.py
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import external_links as X  # noqa: E402


def repo(files: dict[str, str]) -> Path:
    root = Path(tempfile.mkdtemp(prefix="ext-links-"))
    for name, text in files.items():
        p = root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")
    subprocess.run(["git", "init", "-q"], cwd=root, check=True)
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    return root


class ExternalLinks(unittest.TestCase):
    def test_a_link_and_a_bare_address_are_read_with_their_line(self):
        root = repo({"_config.yml": "exclude:\n  - tools/\n", "a.md": "---\ntitle: A\n---\n\nSee [x](https://example.com/x).\nAnd https://example.org/y, then.\n"})
        got = X.links(root)
        self.assertEqual(got, {"https://example.com/x": [("a.md", 5)], "https://example.org/y": [("a.md", 6)]})

    def test_an_excluded_folder_a_dot_folder_and_a_file_with_no_front_matter_are_not_read(self):
        root = repo({"_config.yml": "exclude:\n  - tools/\n", "tools/t.md": "---\ntitle: T\n---\nhttps://example.com/t\n",
                     ".github/p.md": "---\ntitle: P\n---\nhttps://example.com/p\n", "AGENTS.md": "https://example.com/n\n"})
        self.assertEqual(X.links(root), {})

    def test_a_relative_link_is_no_address(self):
        root = repo({"_config.yml": "exclude:\n", "a.md": "---\ntitle: A\n---\n[m](./method.md) and [n](/method.html)\n"})
        self.assertEqual(X.links(root), {})

    def test_the_front_of_a_string_a_script_builds_is_no_address(self):
        root = repo({"_config.yml": "exclude:\n", "a.md": "---\ntitle: A\n---\nfetch(\"https://api.github.com/repos/\" + repo)\n"})
        self.assertEqual(X.links(root), {})


if __name__ == "__main__":
    unittest.main()

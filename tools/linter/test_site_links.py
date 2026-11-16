#!/usr/bin/env python3
"""Tests for site_links.py (unit `site: the links between pages work again`): a synthetic built site, each kind of link once.

    python3 tools/linter/test_site_links.py
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import site_links  # noqa: E402


def build(files: dict[str, str]) -> Path:
    tmp = Path(tempfile.mkdtemp(prefix="site-links-"))
    for name, html in files.items():
        p = tmp / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(html, encoding="utf-8")
    return tmp


def page(body: str) -> str:
    return "<html><body>%s</body></html>" % body


def dead(files: dict[str, str]) -> int:
    site = build(files)
    import io
    import contextlib
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        return site_links.main(["site_links.py", str(site)])


class SiteLinks(unittest.TestCase):
    PAGES = {"method.html": page('<h2 id="the-bridge-test">x</h2><a name="old"></a>'),
             "atoms/favorite.html": page("<p>a</p>"), "compositions/index.html": page("<p>c</p>")}

    def test_every_form_of_a_link_that_resolves_passes(self):
        links = ('<a href="/method.html">a</a><a href="method.html">b</a><a href="/method">c</a><a href="/method.html#the-bridge-test">d</a>'
                 '<a href="/method.html#old">e</a><a href="atoms/favorite.html">f</a><a href="/compositions/">g</a><a href="#top">h</a>'
                 '<a href="https://gracecommons.dev/method.html">i</a><a href="./atoms/../method.html">j</a>')
        self.assertEqual(dead({**self.PAGES, "index.html": page(links + '<span id="top"></span>')}), 0)

    def test_a_link_written_as_a_file_path_is_dead(self):
        self.assertEqual(dead({**self.PAGES, "index.html": page('<a href="./method.md">m</a>')}), 1)

    def test_a_missing_page_and_a_missing_anchor_are_dead(self):
        self.assertEqual(dead({**self.PAGES, "index.html": page('<a href="/nowhere.html">m</a>')}), 1)
        self.assertEqual(dead({**self.PAGES, "index.html": page('<a href="/method.html#no-such-heading">m</a>')}), 1)
        self.assertEqual(dead({**self.PAGES, "index.html": page("<a href=\"#missing\">m</a>")}), 1)

    def test_a_link_that_leaves_the_site_is_not_read(self):
        links = '<a href="https://example.com/x.md">a</a><a href="mailto:a@b.c">b</a><a href="http://github.com/x/y/blob/main/method.md">c</a>'
        self.assertEqual(dead({**self.PAGES, "index.html": page(links)}), 0)


    def test_an_id_two_elements_of_one_page_carry_is_reported_with_both_places(self):
        import io
        import contextlib
        site = build({**self.PAGES, "index.html": page('<h1 id="live-status">x</h1><div id="live-status">y</div>')})
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
            code = site_links.main(["site_links.py", str(site)])
        self.assertEqual(code, 1)
        self.assertIn("index.html: id 'live-status' on 2 elements: <h1> at line 1 column", out.getvalue())
        self.assertIn("<div> at line 1 column", out.getvalue())

    def test_the_same_id_on_two_pages_is_no_fault(self):
        self.assertEqual(dead({**self.PAGES, "index.html": page('<h2 id="top">a</h2>'), "other.html": page('<h2 id="top">b</h2>')}), 0)


if __name__ == "__main__":
    unittest.main()

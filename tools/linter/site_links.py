#!/usr/bin/env python3
"""site_links.py — every internal link of the built site resolves (unit `site: the links between pages work again`).

    python3 tools/linter/site_links.py [_site]           # exit 1 when a link is dead; prints each, and the counts

Reads the HTML `jekyll build` wrote, nothing else: for each page, every `href` that stays on the site (a relative path, a path from the root,
or an address on the site's own host) must name a file the build wrote, and a `#fragment` on it must be an `id` or a `name` of that page.
An address that leaves the site (another host, `mailto:`, `tel:`) is not read. A path answers as GitHub Pages serves it: the file itself,
the file with `.html`, or a folder's `index.html`.

Why it exists: the site was built by GitHub's own Pages build, which turned a link to `./method.md` into `method.html`
(`jekyll-relative-links`); the workflow that replaced it did not, and every link a person wrote as a file path was a 404 until a
reader found one. The check runs in the site's workflow after the build and before the deploy, so a build with a dead internal link does not ship.
"""
from __future__ import annotations

import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

HOST = "gracecommons.dev"


class Page(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.hrefs: list[str] = []
        self.anchors: set[str] = set()
        self.base: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k: v for k, v in attrs if v is not None}
        if tag == "a" and "href" in a:
            self.hrefs.append(a["href"])
        if tag == "base" and "href" in a:
            self.base = a["href"]
        for k in ("id", "name"):
            if k in a:
                self.anchors.add(a[k])


def read(path: Path) -> Page:
    p = Page()
    p.feed(path.read_text(encoding="utf-8", errors="replace"))
    return p


def target(site: Path, page: Path, href: str) -> tuple[Path | None, str, bool]:
    """(the file the href names or None, its fragment, whether it is an internal link at all)"""
    u = urlsplit(href.strip())
    if u.scheme in ("mailto", "tel", "javascript", "data", "sms") or (u.scheme and u.scheme not in ("http", "https")):
        return None, "", False
    if u.netloc and u.netloc != HOST:
        return None, "", False
    if not u.netloc and not u.path:
        return page, u.fragment, True                       # a bare `#fragment`: this page
    rel = unquote(u.path)
    if rel.startswith("/") or u.netloc:
        base = site / rel.lstrip("/")
    else:
        base = (page.parent / rel)
    base = Path(str(base).replace("//", "/"))
    base = Path(*[x for x in base.parts if x != "."]) if base.parts else base
    parts: list[str] = []
    for x in base.parts:
        if x == "..":
            if parts:
                parts.pop()
        else:
            parts.append(x)
    base = Path(*parts) if parts else site
    for c in (base, Path(str(base) + ".html"), base / "index.html"):
        if c.is_file():
            return c, u.fragment, True
    return None, u.fragment, True


def main(argv: list[str]) -> int:
    site = Path(argv[1] if len(argv) > 1 else "_site").resolve()
    if not site.is_dir():
        print(f"site_links: {site} is not a folder; build the site first (bundle exec jekyll build)", file=sys.stderr)
        return 2
    pages = {p: read(p) for p in sorted(site.rglob("*.html"))}
    dead: list[str] = []
    internal = 0
    for page, info in pages.items():
        for href in info.hrefs:
            where, frag, inside = target(site, page, href)
            if not inside:
                continue
            internal += 1
            rel = page.relative_to(site)
            if where is None:
                dead.append(f"{rel}: {href}: no file")
            elif frag and where.suffix == ".html":
                if where not in pages:
                    pages[where] = read(where)
                if unquote(frag) not in pages[where].anchors and frag not in pages[where].anchors:
                    dead.append(f"{rel}: {href}: no anchor #{frag} on {where.relative_to(site)}")
    for d in dead:
        print(d)
    print(f"site_links: {len(pages)} pages, {internal} internal links, {len(dead)} dead", file=sys.stderr)
    return 1 if dead else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

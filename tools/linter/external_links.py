#!/usr/bin/env python3
"""external_links.py — the links from a site page to another site, asked once each (unit `site: a weekly report of links to other sites`).

    python3 tools/linter/external_links.py [--list] [root]    # prints a Markdown report; --list asks nothing and prints the links

Reads the Markdown the site builds (every `.md` with front matter outside `_config.yml`'s `exclude` and the dot folders) and takes each
`http(s)` address a link or a bare URL names. Each address is asked once: a HEAD, then a GET where the host refuses a HEAD (403, 405, 501
or an error), redirects followed, one request a host a second, a plain user agent that names the project. The report holds the links
that did not answer 200 after the redirects, by file and line, and nothing else. It gates nothing: the exit code is 0 whatever it finds
(2 when it could not run), and no issue is opened and no file written. The weekly workflow (`.github/workflows/external-links.yml`) puts
the report in its run summary.
"""
from __future__ import annotations

import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import defaultdict
from pathlib import Path
from urllib.parse import urlsplit

UA = "grace-commons-link-report (+https://gracecommons.dev; a weekly look at the links that leave the site)"
URL = re.compile(r"https?://[^\s<>()\[\]\"'`]+")
GAP = 1.0     # seconds between two requests to one host
TIMEOUT = 20


def excluded(root: Path) -> list[str]:
    out, on = [], False
    for line in (root / "_config.yml").read_text(encoding="utf-8").splitlines():
        if line.startswith("exclude:"):
            on = True
        elif on and line.startswith("  - "):
            out.append(line[4:].strip())
        elif on and line.strip() and not line.startswith(" "):
            break
    return out


def pages(root: Path) -> list[Path]:
    skip = excluded(root)
    files = subprocess.run(["git", "-C", str(root), "ls-files", "*.md", "*.idd"], capture_output=True, text=True, check=True).stdout.split("\n")
    out = []
    for f in sorted(x for x in files if x):
        if f.startswith(".") or any(f == s or f.startswith(s if s.endswith("/") else s + "/") for s in skip):
            continue
        if (root / f).read_text(encoding="utf-8", errors="replace").startswith("---\n"):
            out.append(root / f)
    return out


def links(root: Path) -> dict[str, list[tuple[str, int]]]:
    found: dict[str, list[tuple[str, int]]] = defaultdict(list)
    for p in pages(root):
        front = True
        for n, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if n > 1 and front and line.strip() == "---":
                front = False
                continue
            for m in URL.finditer(line):
                if re.match(r"[\"'`]\s*\+", line[m.end():]):
                    continue          # the front of a string built in a script (`"https://api.github.com/repos/" + repo`): no address yet
                u = m.group(0).rstrip(".,;:!?*_")
                if urlsplit(u).hostname:
                    found[u].append((str(p.relative_to(root)), n))
    return found


def ask(url: str) -> str:
    """the status after the redirects: a number, or the error's name"""
    status = "error"
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers={"User-Agent": UA, "Accept": "*/*"})
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                return str(r.status)
        except urllib.error.HTTPError as e:
            status = str(e.code)
            if method == "HEAD" and e.code in (403, 405, 501):
                continue
            return status
        except Exception as e:   # a host that is down, a name that does not resolve, a timeout
            status = type(e).__name__
            if method == "HEAD":
                continue
            return status
    return status


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    root = Path(args[0]).resolve() if args else Path(__file__).resolve().parents[2]
    found = links(root)
    if "--list" in argv:
        for u, where in sorted(found.items()):
            print(u, *("%s:%d" % w for w in where[:3]))
        print(f"{len(found)} addresses, {sum(len(v) for v in found.values())} links", file=sys.stderr)
        return 0
    last: dict[str, float] = {}
    bad: list[tuple[str, str]] = []
    for u in sorted(found, key=lambda x: (urlsplit(x).hostname, x)):
        host = urlsplit(u).hostname
        wait = last.get(host, 0) + GAP - time.time()
        if wait > 0:
            time.sleep(wait)
        status = ask(u)
        last[host] = time.time()
        if status != "200":
            bad.append((u, status))
    print("## Links to other sites")
    print()
    print(f"{len(found)} addresses asked once each; {len(bad)} did not answer 200 after the redirects.")
    for u, status in bad:
        print()
        print(f"- `{status}` {u}")
        for f, n in found[u]:
            print(f"  - {f}:{n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

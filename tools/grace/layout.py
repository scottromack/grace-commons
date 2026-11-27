"""The library's layout: where each page sits now and where it sat before.

Unit `library: the files match the tree` (Scott 2026-11-23 9:57 and 10:00 PM Central: "The fix is to
just fix the fucking files?"): every menu section is a folder, so the pages that sat at the root moved
into library/, how/, evidence/, community/, log/ and essays/, and atoms/, compositions/ and apps/ moved
under library/. `_data/moves.json` is the one record of the move: the site's redirects
(_plugins/moved.rb) read it, and so does this module, which the tools that compare a page with its own
past (a pin, a frozen round) use to find the page's old path and to compare its text whatever folder
each copy sat in.

    new_path(old)            the path a page has now ("atoms/lease.md" -> "library/atoms/lease.md")
    old_path(new)            the path it had before the move (the inverse; itself where it never moved)
    text_at(repo, rev, path) a page's text at a revision, under its path then, or None
    found_at(repo, rev, path) the same, with the path it was found under: (text, path) or (None, None)
    neutral(text, path)      the text with every relative link written as the path it names now and the
                             navigation keys of its front matter dropped, so a page reads the same before
                             and after the move: the move changes no word a reader reads
"""
from __future__ import annotations

import json
import posixpath
import re
import subprocess
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
MOVES = "_data/moves.json"
OWN = r"https://github\.com/scottromack/grace-commons/(?:blob|tree)/main/"
# the front matter keys the move rewrote: the menu reads them, no reader does
NAV_KEYS = ("parent", "grand_parent", "nav_order", "permalink", "redirect_from")


@lru_cache(maxsize=None)
def moves(root: str | None = None) -> dict:
    # a root that carries no map (a test's temporary corpus) reads the repository's own
    path = Path(root or ROOT) / MOVES
    if not path.exists():
        path = ROOT / MOVES
    if not path.exists():
        return {"dirs": {}, "files": {}, "deleted": {}}
    return json.loads(path.read_text(encoding="utf-8"))


def new_path(old: str, root: str | None = None) -> str:
    """Where the page at `old` (a repo-relative path, before the move) is now."""
    m = moves(root)
    old = old[2:] if old.startswith("./") else old
    if old in m["files"]:
        return m["files"][old]
    for before, after in m["dirs"].items():
        if old == before.rstrip("/"):
            return after.rstrip("/")
        if old.startswith(before):
            return after + old[len(before):]
    return old


def old_path(new: str, root: str | None = None) -> str:
    """Where the page at `new` sat before the move; itself where it never moved."""
    m = moves(root)
    for before, after in m["files"].items():
        if after == new:
            return before
    for before, after in m["dirs"].items():
        if new == after.rstrip("/"):
            return before.rstrip("/")
        if new.startswith(after):
            return before + new[len(after):]
    return new


def found_at(repo, rev: str, path: str) -> tuple[str | None, str | None]:
    """`path`'s text at `rev`, read under the path it had at that revision, and that path."""
    # a pattern renamed to .idd (Scott 2026-11-26) sat at its .md name between the move and the rename
    for name in dict.fromkeys((path, old_path(path), new_path(path), re.sub(r"\.idd$", ".md", path))):
        done = subprocess.run(["git", "--no-optional-locks", "-C", str(repo), "show", f"{rev}:{name}"],
                              capture_output=True, text=True)
        if done.returncode == 0:
            return done.stdout, name
    return None, None


def text_at(repo, rev: str, path: str) -> str | None:
    """`path`'s text at `rev`, read under the path it had at that revision."""
    return found_at(repo, rev, path)[0]


LINK = re.compile(r"(\]\(\s*<?|^\[[^\]]+\]:[ \t]*<?|href=\")([^)\s\">]+)", re.M)


def _target(page: str, target: str) -> str | None:
    """The repo path a relative link on `page` names, in the layout `page` was written in."""
    if re.match(r"^(?:[a-z][a-z0-9+.-]*:|#|/|\{\{|@)", target, re.I):
        return None
    path = target.split("#", 1)[0].split("?", 1)[0]
    if not path:
        return None
    return posixpath.normpath(posixpath.join(posixpath.dirname(page), path))


def neutral(text: str, path: str) -> str:
    """`text`, read as the page at `path` (the path that copy sat at, in either layout), with each relative link and each link to
    the repository's own GitHub page written `@<path now>`, and the front matter's navigation keys
    dropped: the same page before and after the move compares equal; any other change still shows."""
    def link(m):
        target = m.group(2)
        own = re.match(OWN + r"(.+)$", target)
        if own:
            body, _, anchor = own.group(1).partition("#")
            return m.group(1) + "@" + new_path(body.rstrip("/")) + ("#" + anchor if anchor else "")
        where = _target(path, target)
        if where is None:
            return m.group(0)
        anchor = "#" + target.split("#", 1)[1] if "#" in target else ""
        return m.group(1) + "@" + new_path(where) + anchor

    lines = text.split("\n")
    if lines and lines[0].strip() == "---":
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
        if end is not None:
            front = [l for l in lines[1:end] if not re.match(r"(%s):" % "|".join(NAV_KEYS), l)]
            lines = ["---"] + front + lines[end:]
    return LINK.sub(link, "\n".join(lines))

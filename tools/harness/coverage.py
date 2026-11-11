#!/usr/bin/env python3
"""The coverage matrices, counted.

Every row of a coverage matrix (tools/harness/coverage/<page>.md, a table with a
Verdict column) is one rule of its page, and its Verdict cell opens with one word in
backticks, the word this script counts (unit `tooling: every check has a twin that
breaks it`, Scott 2026-11-10 12:29 PM Central):

  `checked`     a check of a model that holds states it, and the row names the twin
                that breaks that check (a `-buggy` file)
  `elsewhere`   another page's model checks it, and the row names the page
  `owed`        no model checks it yet, and a model could
  `unstatable`  no model in the page's tools can state it (a wiring rule, a non-goal,
                a deployment's duty); the row says why
  `retired`     the rule is deleted or merged into another row: not a rule, not counted

The words replace the sort the coverage unit of 2026-11-10 kept by hand in
coverage/owed-2026-11-10.md (a, b and c there are elsewhere, owed and unstatable here).

  python3 tools/harness/coverage.py             each page's counts; exit 1 if a row has
                                                no word, or a checked row names no twin
  python3 tools/harness/coverage.py --summary   one line, every page together (the
                                                status skill reads it)
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
WORDS = ("checked", "elsewhere", "owed", "unstatable", "retired")
NOT_MATRICES = {"README.md"}
SEPARATOR = re.compile(r"^\|[\s:|-]+\|$")
TWIN = re.compile(r"[\w.-]*buggy[\w.-]*\.(?:tla|als)")


def cells(line):
    """The cells of a table line (a `|` inside a code span does not split)."""
    out, cur, code = [], "", False
    for ch in line.strip().strip("|"):
        if ch == "`":
            code = not code
        if ch == "|" and not code:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    return out + [cur.strip()]


def rows(text):
    """(line number, cells, index of the Verdict cell) for every row of every table with a Verdict column."""
    lines = text.split("\n")
    head = None
    for i, line in enumerate(lines):
        if not line.startswith("|"):
            head = None
            continue
        if SEPARATOR.match(line.strip()):
            continue
        if i + 1 < len(lines) and SEPARATOR.match(lines[i + 1].strip()):
            head = cells(line)
            continue
        if head and "Verdict" in head:
            yield i + 1, cells(line), head.index("Verdict")


def word(cell):
    """The verdict word a Verdict cell opens with, or None."""
    m = re.match(r"\s*\**`([a-z]+)`", cell)
    return m.group(1) if m and m.group(1) in WORDS else None


def count(directory=HERE / "coverage"):
    """page -> {word: n}, and the problems: (page, line, what)."""
    pages, problems = {}, []
    for path in sorted(pathlib.Path(directory).glob("*.md")):
        if path.name in NOT_MATRICES:
            continue
        n = {w: 0 for w in WORDS}
        found = False
        for line, row, v in rows(path.read_text(encoding="utf-8")):
            found = True
            w = word(row[v]) if v < len(row) else None
            if w is None:
                problems.append((path.stem, line, "no verdict word"))
                continue
            n[w] += 1
            if w == "checked" and not TWIN.search(" ".join(row)):
                problems.append((path.stem, line, "checked, and names no twin that breaks it"))
        if found:
            pages[path.stem] = n
    return pages, problems


def summary(pages):
    t = {w: sum(p[w] for p in pages.values()) for w in WORDS}
    rules = t["checked"] + t["elsewhere"] + t["owed"] + t["unstatable"]
    pct = lambda k: f"{t[k]} ({round(100 * t[k] / rules) if rules else 0}%)"
    counted = sum(1 for p in pages.values() if p["checked"] + p["elsewhere"] + p["owed"] + p["unstatable"])
    return (f"Of {rules} rules on {counted} matrices: {pct('checked')} checked by a model that holds, "
            f"{pct('elsewhere')} checked on another page, {pct('owed')} owed, {pct('unstatable')} cannot be stated")


def main(argv):
    pages, problems = count()
    if "--summary" in argv:
        print(summary(pages))
        return 0
    print(f"{'page':44} " + " ".join(f"{w:>10}" for w in WORDS))
    for page, n in pages.items():
        print(f"{page:44} " + " ".join(f"{n[w]:>10}" for w in WORDS))
    print(summary(pages))
    for page, line, what in problems:
        print(f"  {page}.md:{line}: {what}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

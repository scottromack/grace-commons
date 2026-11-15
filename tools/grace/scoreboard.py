#!/usr/bin/env python3
"""The scoreboard of what the parser must reject — one page, generated.

    python3 tools/grace/scoreboard.py [root]          writes <root>/enforcement.md
    python3 tools/grace/scoreboard.py --check [root]  exits 1 when the page is stale

GRACE-lang.md has labelled rules that say *The parser MUST reject …*. The
checker (`check.py`, `lint.py`, `normalize.py`) is the parser's mechanical
slice, and this page says, rule by rule, how much of each sentence it holds:
`gates` (a finding fails `check.py --gate` or the linter), `gates in part`
(one reading of the sentence gates and another is read by nothing that gates)
or `only counted` (the finding is advisory, or the normalizer's, and no run
fails on it).

Two things are read, never kept by hand: the sentences, from GRACE-lang.md, and
whether a code gates, from the tools' own advisory sets (`check.ADVISORY`,
`lint.ADVISORY_CODES`, and every `N-` code of normalize.py). What a person
decides, once, is in ROWS below: which codes hold which label, and, where the
codes read only part of a sentence, what slips through. test_scoreboard.py
proves each of those claims by running the checker on a rule that breaks the
sentence, so a row cannot say more than the checker does.

The page's date is the day its rows last changed: a run that finds the same
rows keeps the date already on the page, so the page is no function of the
calendar and the linter's V-views-current can compare it.
"""
from __future__ import annotations

import datetime
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PAGE = "enforcement.md"

# label -> (the codes that hold it, what slips through or None). A code names
# its tool by its place: N- is normalize.py's; the rest are check.py's, or
# lint.py's where TOOL_OF_CODE says so.
ROWS: dict[str, tuple[tuple[str, ...], str | None]] = {
    "Surface 19": (("F-fence-first",), None),
    "Hard invariant 1": (("F-unlabelled", "F-fence-first"), None),
    "Hard invariant 2": (("N-unlowered",), None),
    "Hard invariant 3": (("R-no-modal",), None),
    "Hard invariant 4": (("P-pronoun", "W-demonstrative"),
        "*it*, *its*, *itself*, *they*, *their*, *them*, *he*, *she*, *his* and *her* gate; *these* and *those* alone are only counted, and *this* and *that* are not read."),
    "Hard invariant 5": (("W-two-obligations",), None),
    "Hard invariant 6": (("R-nested-when",), None),
    "Hard invariant 7": (("V-mixed",), None),
    "Hard invariant 8": (("V-or-obligation",), None),
    "Hard invariant 9": (("B-before",),
        "Only a `MUST` or `MAY` rule's `BEFORE` is read; a `BEFORE` under `IS AUTHORITATIVE FOR`, or in a condition, is not."),
    "Hard invariant 10": (("B-after",),
        "Only an `AFTER` under `MUST NOT` is read; an `AFTER` in a condition is not, and a lower-case one is only counted."),
    "Hard invariant 11": (("B-before",),
        "The pattern stops at a full stop, so a label or step number (`step 0.1a`) before the `BEFORE` hides it."),
    "Hard invariant 13": (("N-ordinal-ref",), None),
    "Hard invariant 14": (("N-value-set",), None),
    "Hard invariant 30": (("F-range-form",), None),
    "Hard invariant 31": (("F-range-form",), None),
    "Hard invariant 32": (("D-condition-form",), None),
    "Hard invariant 34": (("D-condition-form",), None),
    "Hard invariant 35": (("A-decl-arith",), None),
    "Hard invariant 36": (("A-arith", "D-rule-symbol", "A-decl-arith"),
        "A `/` in a rule, and a division inside a parenthesized group, gate; a bare `÷` in a rule is read by nothing."),
    "Hard invariant 37": (("A-decl-arith",), None),
    "Value set 2": (("N-value-set",), None),
}

# lint.py's codes among those above; every other non-N code is check.py's
LINT_CODES = {"F-range-form"}

SENTENCE = re.compile(r"^([A-Z][A-Za-z ]*? \d+(?:\.\d+)?): (The parser MUST reject .*)$")


def sentences(grammar: str) -> list[tuple[str, str]]:
    """Every labelled rule of the grammar that says the parser MUST reject."""
    out = []
    for line in grammar.splitlines():
        m = SENTENCE.match(line.strip())
        if m:
            out.append((m.group(1), m.group(2)))
    return out


def _advisory() -> set[str]:
    """The codes that gate nothing, read from the tools themselves."""
    sys.path.insert(0, str(HERE))
    sys.path.insert(0, str(HERE.parent / "linter"))
    import check
    import lint
    return set(check.ADVISORY) | set(lint.ADVISORY_CODES)


def tool_of(code: str) -> str:
    if code.startswith("N-"):
        return "normalize.py"
    return "lint.py" if code in LINT_CODES else "check.py"


def gates(code: str, advisory: set[str]) -> bool:
    return not code.startswith("N-") and code not in advisory


def state(label: str, advisory: set[str]) -> str:
    codes, slips = ROWS[label]
    if not any(gates(c, advisory) for c in codes):
        return "only counted"
    return "gates in part" if slips else "gates"


def verify(root: Path, advisory: set[str]) -> list[str]:
    """What is wrong with ROWS against the grammar and the tools, one line each."""
    bad = []
    found = {lab for lab, _ in sentences((root / "GRACE-lang.md").read_text(encoding="utf-8"))}
    for lab in sorted(found - ROWS.keys()):
        bad.append(f"{lab}: GRACE-lang.md says the parser MUST reject, and ROWS has no row for it")
    for lab in sorted(ROWS.keys() - found):
        bad.append(f"{lab}: ROWS has a row, and GRACE-lang.md has no such sentence")
    source = {t: (root / "tools" / d / t).read_text(encoding="utf-8")
              for t, d in (("check.py", "grace"), ("lint.py", "linter"), ("normalize.py", "grace"))}
    for lab, (codes, _slips) in ROWS.items():
        for c in codes:
            if f'"{c}"' not in source[tool_of(c)]:
                bad.append(f"{lab}: {tool_of(c)} has no code {c}")
    return bad


def render(root: Path, advisory: set[str], date: str) -> str:
    rows = [(lab, text) for lab, text in sentences((root / "GRACE-lang.md").read_text(encoding="utf-8"))]
    states = {lab: state(lab, advisory) for lab, _ in rows}
    n = {w: sum(1 for s in states.values() if s == w) for w in ("gates", "gates in part", "only counted")}
    out = [
        "---",
        "title: What the checker enforces",
        "nav_order: 4",
        "parent: Evidence",
        "---",
        "",
        "# What the checker enforces",
        "",
        f"GRACE-lang.md has {len(rows)} rules that say the parser MUST reject something: "
        f"the checker gates {n['gates']} of them, gates {n['gates in part']} in part, and only counts "
        f"{n['only counted']}. This page was generated on {date} from the grammar and the checker's own "
        "codes; its date moves only when a row does. Nothing on it is hand-written.",
        "",
        "Each row is one rule of the grammar, in its own words, the check that holds it, and one of three states:",
        "",
        "- **gates** — a finding makes `check.py --gate` exit 1, the corpus gate every change reports 0 findings on before it merges "
        "(the pull-request template asks for it; no workflow runs it), or, for a `lint.py` code, fails the public lint workflow.",
        "- **gates in part** — one reading of the sentence gates, and another is read by nothing that gates; what slips through is listed under the table.",
        "- **only counted** — the check is advisory or the normalizer's: it is read and counted, and no run fails on it. This is the list of what is still owed.",
        "",
        "| Rule | The grammar says | Held by | State |",
        "|---|---|---|---|",
    ]
    for lab, text in rows:
        codes, _ = ROWS[lab]
        held = ", ".join(f"`{tool_of(c)}` {c}" for c in codes)
        out.append(f"| {lab} | {text} | {held} | {states[lab]} |")
    partial = [(lab, ROWS[lab][1]) for lab, _ in rows if states[lab] == "gates in part"]
    if partial:
        out += ["", "## What slips through", ""]
        out += [f"- **{lab}** — {slip}" for lab, slip in partial]
    out += [
        "",
        "Nothing is gated and nothing is retired by this page: it is the list of what is owed.",
        "",
        "The checks themselves are run by [Verify It Yourself](./verify.md); the grammar is [GRACE-lang](./GRACE-lang.md).",
        "",
    ]
    return "\n".join(out)


def generate(root: Path) -> str:
    """The page for `root`, keeping the date already on it while its rows stand."""
    advisory = _advisory()
    bad = verify(root, advisory)
    if bad:
        raise SystemExit("scoreboard.py: " + "\n  ".join(["ROWS and the sources disagree:"] + bad))
    page = root / PAGE
    old = page.read_text(encoding="utf-8") if page.exists() else ""
    m = re.search(r"was generated on (\d{4}-\d{2}-\d{2})", old)
    if m and render(root, advisory, m.group(1)) == old:
        return old
    return render(root, advisory, datetime.date.today().isoformat())


def main(argv: list[str]) -> int:
    check = "--check" in argv
    args = [a for a in argv[1:] if not a.startswith("--")]
    root = Path(args[0]).resolve() if args else HERE.parents[1]
    text = generate(root)
    page = root / PAGE
    if check:
        if not page.exists() or page.read_text(encoding="utf-8") != text:
            print(f"{PAGE}: stale — regenerate with python3 tools/grace/scoreboard.py", file=sys.stderr)
            return 1
        return 0
    page.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

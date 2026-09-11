#!/usr/bin/env python3
"""What re-opens when a rule changes — the citation walker.

`check.py` resolves a citation forward: a reference names a rule that exists.
Nothing walked it backward, and that is how a vacuous check survives a repair.
Lease's Check 6.1 measured the fence margin against the allowance; Fence 5 was
the rule that set the margin; when Fence 5 changed, nothing re-opened the check
that rested on it, and the pair stayed mutually vacuous for a day (CR-8).

A citation here is either kind of dependence a rule can carry:

  * a label — `Fence 5`, `Invariant 2.3`, `record_action step 3.2`;
  * a declared term — `fence margin`, `window`, `under guard` — including a
    term a term's own definition computes over, walked transitively.

Nothing here decides whether a re-read finds anything. The tool names the
reading, the human does it (GRACE-lang Principle 8).

    python3 tools/grace/cites.py 'Fence 5'          # what rests on this
    python3 tools/grace/cites.py --changed HEAD~1   # what today's edits re-open
    python3 tools/grace/cites.py --changed HEAD~1 --paths atoms/lease.md
"""
from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

LABEL = re.compile(
    r"^((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?):\s*(.*)$")
TERM_DECL = re.compile(r"^\s*Terms › `([^`]+)`:\s*(.*)$")
FENCE = re.compile(r"^\s*```(\w*)")
NAME_NUM = re.compile(r"( step [\d½]+(?:\.\d+[a-z]?)?| \d+(?:\.\d+)?[a-z]?)$")


@dataclass
class Spec:
    path: Path
    rules: dict[str, int] = field(default_factory=dict)      # label -> line
    text_of: dict[str, str] = field(default_factory=dict)    # label -> statement
    terms: dict[str, tuple[int, str]] = field(default_factory=dict)


def parse(path: Path) -> Spec:
    spec = Spec(path)
    in_text_fence = False
    for i, raw in enumerate(path.read_text(encoding="utf-8").split("\n"), start=1):
        fm = FENCE.match(raw)
        if fm:
            in_text_fence = (fm.group(1) == "text") if not in_text_fence else False
            continue
        dm = TERM_DECL.match(raw)
        if dm:
            spec.terms[dm.group(1)] = (i, dm.group(2))
            continue
        if not in_text_fence:
            continue
        lm = LABEL.match(raw.strip())
        if lm and not raw.strip().startswith(("NOTE:", "WHY:", "UX:", "PROVISIONAL:")):
            spec.rules[lm.group(1)] = i
            spec.text_of[lm.group(1)] = lm.group(2)
    return spec


def _label_pattern(labels: set[str]) -> re.Pattern | None:
    names = {NAME_NUM.sub("", lab) for lab in labels}
    names = {n for n in names if n}
    if not names:
        return None
    alt = "|".join(re.escape(n) for n in sorted(names, key=len, reverse=True))
    return re.compile(r"(?<![\w-])(" + alt + r")( step [\d½]+(?:\.\d+[a-z]?)?| \d+(?:\.\d+)?[a-z]?)(?![\w.]\d)")


def uses(text: str, spec: Spec, lab_re, holder: str) -> tuple[set[str], set[str]]:
    """The labels and the terms one piece of text rests on."""
    labels, terms = set(), set()
    if lab_re:
        for m in lab_re.finditer(text):
            ref = m.group(1) + m.group(2)
            if ref in spec.rules and ref != holder:
                labels.add(ref)
    for name in spec.terms:
        if name != holder and re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", text):
            terms.add(name)
    return labels, terms


def reopened_by(spec: Spec, seeds: set[str]) -> dict[str, set[str]]:
    """What a change to `seeds` puts back in front of a reader.

    A definition chain is walked to its end — a term defined over a changed
    term is itself changed — and rules are the last hop, never a step in the
    walk. Walking rule to rule to rule re-opens the whole document, which is
    the same as re-opening nothing.
    """
    lab_re = _label_pattern(set(spec.rules))
    seed_labels = {s for s in seeds if not s.startswith("`")}
    seed_terms = {s.strip("`") for s in seeds if s.startswith("`")}

    # definition chain: a term whose definition rests on a changed term
    changed_terms = set(seed_terms)
    growing = True
    while growing:
        growing = False
        for name, (_, body) in spec.terms.items():
            if name in changed_terms:
                continue
            _, used = uses(body, spec, lab_re, name)
            if used & changed_terms:
                changed_terms.add(name)
                growing = True

    CATALOGUE = {"actors", "records", "record verbs", "value sets", "bounds",
                 "cadences", "terms", "qualifiers", "composing patterns", "cited"}
    out: dict[str, set[str]] = {}
    for name in changed_terms - seed_terms - CATALOGUE:
        _, used = uses(spec.terms[name][1], spec, lab_re, name)
        out[f"`{name}`"] = {f"`{x}`" for x in used & changed_terms}
    for label, text in spec.text_of.items():
        if label in seed_labels:
            continue
        cited, used = uses(text, spec, lab_re, label)
        via = (cited & seed_labels) | {f"`{x}`" for x in used & changed_terms}
        if via:
            out[label] = via
    return out


def specs_with_rules(root: Path, paths: list[Path] | None) -> list[Spec]:
    if paths:
        candidates = paths
    else:
        candidates = [root / "GRACE-lang.md"] + sorted(root.glob("atoms/*.md")) + \
                     sorted(root.glob("compositions/*.md"))
    out = []
    for p in candidates:
        if not p.exists():
            continue
        spec = parse(p)
        if spec.rules:
            out.append(spec)
    return out


def changed_seeds(root: Path, rev: str, spec: Spec) -> set[str]:
    rel = spec.path.relative_to(root).as_posix()
    diff = subprocess.run(["git", "-C", str(root), "diff", "-U0", rev, "--", rel],
                          capture_output=True, text=True).stdout
    seeds: set[str] = set()
    for line in diff.split("\n"):
        if not line or line[0] not in "+-" or line.startswith(("+++", "---")):
            continue
        body = line[1:].strip()
        lm = LABEL.match(body)
        if lm and lm.group(1) in spec.rules:
            seeds.add(lm.group(1))
        dm = TERM_DECL.match(body)
        if dm and dm.group(1) in spec.terms:
            seeds.add(f"`{dm.group(1)}`")
    return seeds


def report(spec: Spec, seeds: set[str]) -> int:
    if not seeds:
        return 0
    reopened = reopened_by(spec, seeds)
    rel = spec.path.name
    if not reopened:
        print(f"{rel}: {len(seeds)} changed, nothing rests on {'it' if len(seeds) == 1 else 'them'}")
        return 0
    print(f"{rel}: {len(seeds)} changed — {len(reopened)} to re-read")
    for holder in sorted(reopened):
        where = spec.rules.get(holder) or spec.terms.get(holder.strip("`"), (0, ""))[0]
        via = ", ".join(sorted(reopened[holder]))
        print(f"  {rel}:{where}: {holder} rests on {via}")
    return len(reopened)


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parents[2]
    args = [a for a in argv[1:] if not a.startswith("--")]
    rev = None
    if "--changed" in argv:
        i = argv.index("--changed")
        rev = argv[i + 1] if i + 1 < len(argv) else "HEAD"
        if rev in args:
            args.remove(rev)
    paths = None
    if "--paths" in argv:
        i = argv.index("--paths")
        paths = [Path(a) if Path(a).is_absolute() else root / a for a in argv[i + 1:]
                 if not a.startswith("--")]
        args = [a for a in args if (root / a) not in paths and Path(a) not in paths]

    specs = specs_with_rules(root, paths)
    total = 0
    if rev:
        for spec in specs:
            total += report(spec, changed_seeds(root, rev, spec))
        if total == 0:
            print(f"— nothing to re-read against {rev}.")
        else:
            print(f"— {total} reading(s). A re-read is a human's (Principle 8).")
        return 0

    if not args:
        print(__doc__)
        return 2
    seed = args[0]
    seed = seed if seed.startswith("`") or " " in seed else f"`{seed}`"
    found = False
    for spec in specs:
        if seed in spec.rules or seed.strip("`") in spec.terms:
            found = True
            total += report(spec, {seed})
    if not found:
        print(f"— no rule or term named {seed}.")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

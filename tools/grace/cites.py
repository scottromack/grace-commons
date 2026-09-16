#!/usr/bin/env python3
"""What re-opens when a rule changes — the citation walker.

`check.py` resolves a citation forward: a reference names a rule that exists.
Nothing walked it backward, and that is how a vacuous check survives a repair.
Lease's Check 6.1 measured the fence margin against the allowance; Fence 5 was
the rule that set the margin; when Fence 5 changed, nothing re-opened the check
that rested on it, and the pair stayed mutually vacuous for a day (council read 8).

A citation here is either kind of dependence a rule can carry:

  * a label — `Fence 5`, `Invariant 2.3`, `record_action step 3.2`;
  * a declared term — `fence margin`, `window`, `under guard` — including a
    term a term's own definition computes over, walked transitively.

Nothing here decides whether a re-read finds anything. The tool names the
reading, the human does it (GRACE-lang Principle 8).

    python3 tools/grace/cites.py 'Fence 5'          # what rests on this
    python3 tools/grace/cites.py --changed HEAD~1   # what today's edits re-open
    python3 tools/grace/cites.py --changed HEAD~1 --paths atoms/lease.md
    python3 tools/grace/cites.py --unread            # migrated, but no council read
    python3 tools/grace/cites.py --standard          # which families ARE standard, and what each means
    python3 tools/grace/cites.py --promote Housekeeping
    python3 tools/grace/cites.py --promote 'Action wiring' --means 'what the promotion would declare'

`--standard` exists because the standard set's membership went wrong three
times in two days, in two readers, after two corrections: a promoted family is
recorded in a register entry and a changelog and printed by nothing, so the
answer was recalled rather than read. `--promote` stages the hearing and, for a
family already standard, audits it — the maintainer supplies the meaning, the
tool supplies the reading order (Principle 8, Standard label 6).
"""
from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

LABEL = re.compile(
    r"^((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?):\s*(.*)$")
TERM_DECL = re.compile(r"^\s*Term ([^:`]+?): (.*)$")
FENCE = re.compile(r"^\s*```(\w*)")
REGISTER = re.compile(r"\*\*Council read (?P<n>\d+) — \w+ on (?P<spec>[^,]+),")
MIGRATED = re.compile(r"^Term qualifiers:[^\n]*\bmigrated\b", re.M)
NAME_NUM = re.compile(r"( step [\d½]+(?:\.\d+[a-z]?)?| \d+(?:\.\d+)?[a-z]?)$")
# the last number of a range citation, `Operation 3 through 7` (Hard invariant 29)
RANGE_END = re.compile(r" through ([\d½]+(?:\.\d+)?[a-z]?)(?![\w.]\d)")


def _num_key(num: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", num))


def in_range(label: str, family: str, first: str, last: str) -> bool:
    """Whether a range citation covers `label` — `family` and `first` as the
    citation writes them (`Invariant`, ` 2.1`; `reconcile`, ` step 5.2`), `last`
    the bare number after *through*. Both ends are included, and a range of
    majors covers their minors: `Invariant 1 through 4` covers `Invariant 4.2`."""
    m = NAME_NUM.search(label)
    if not m or label[:m.start()] != family:
        return False
    if m.group(1).startswith(" step ") != first.startswith(" step "):
        return False
    lo, hi, k = _num_key(first), _num_key(last), _num_key(m.group(1))
    return lo <= k[:len(lo)] and k[:len(hi)] <= hi


@dataclass
class Spec:
    path: Path
    rules: dict[str, int] = field(default_factory=dict)      # label -> line
    text_of: dict[str, str] = field(default_factory=dict)    # label -> statement
    terms: dict[str, tuple[int, str]] = field(default_factory=dict)


def parse(path: Path) -> Spec:
    spec = Spec(path)
    lines = path.read_text(encoding="utf-8").split("\n")
    in_fence = normative = False
    for i, raw in enumerate(lines, start=1):
        fm = FENCE.match(raw)
        if fm:
            in_fence = not in_fence
            normative = False
            if in_fence and fm.group(1) == "":
                # a bare fence is normative when its first line is a rule or a
                # tombstone (GRACE-lang Surface 18)
                first = next((x.strip() for x in lines[i:] if x.strip()), "")
                normative = bool(LABEL.match(first)) and not first.startswith(
                    ("NOTE:", "WHY:", "UX:", "PROVISIONAL:")) or first.startswith("Deleted:")
            continue
        dm = TERM_DECL.match(raw)
        if dm:
            spec.terms[dm.group(1)] = (i, dm.group(2))
            continue
        if not normative:
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
            end = RANGE_END.match(text, m.end())
            if end:
                labels |= {lab for lab in spec.rules if lab != holder
                           and in_range(lab, m.group(1), m.group(2), end.group(1))}
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


def spec_name(path: Path) -> str:
    """A spec's name as Hard invariant 28 writes it: the file stem, spaced."""
    if path.name == "GRACE-lang.md":
        return "GRACE-lang"
    return " ".join(w.capitalize() for w in path.stem.split("-"))


def across(specs: list[Spec], seeds: dict[Path, set[str]]) -> dict[str, list[str]]:
    """Rules in other specs that cite a changed rule by the cross-spec form —
    `Tamper Evidence Invariant 1` (GRACE-lang Hard invariant 28). A citation
    the corpus can make is a citation something has to walk."""
    wanted: list[tuple[str, str]] = []
    ranged: list[tuple[str, str, str]] = []   # spec name, label, origin
    for path, labels in seeds.items():
        name = spec_name(path)
        for label in labels:
            if label.startswith("`"):
                continue
            wanted.append((f"{name} {label}", path.name))
            ranged.append((name, label, path.name))
            group = re.match(r"^(.*?) (\d+)\.\d+[a-z]?$", label)
            if group:
                wanted.append((f"{name} {group.group(1)} {group.group(2)}", path.name))
    def hits(text: str, origin_name: str) -> set[str]:
        found = {ref for ref, origin in wanted if ref in text and origin != origin_name}
        # a range citation cites every label between its ends (Hard invariant 29)
        for m in CROSS_REF.finditer(text):
            end = RANGE_END.match(text, m.end())
            if not end:
                continue
            fam = NAME_NUM.search(m.group(2))
            for name, label, origin in ranged:
                if (m.group(1) == name and origin != origin_name and fam and
                        in_range(label, m.group(2)[:fam.start()], fam.group(1), end.group(1))):
                    found.add(f"{name} {label}")
        return found

    out: dict[str, list[str]] = {}
    for spec in specs:
        rule_lines = set(spec.rules.values())
        for label, text in spec.text_of.items():
            for ref in hits(text, spec.path.name):
                out.setdefault(ref, []).append(
                    f"{spec.path.name}:{spec.rules[label]}: {label}")
        # a citation in prose carries no obligation and still sends a reader
        for i, raw in enumerate(spec.path.read_text(encoding="utf-8").split("\n"), start=1):
            if i in rule_lines:
                continue
            for ref in hits(raw, spec.path.name):
                out.setdefault(ref, []).append(f"{spec.path.name}:{i}: (prose)")
    return out


CATEGORY_NAMES = {"actors", "records", "record verbs", "value sets", "bounds",
                  "cadences", "terms", "qualifiers", "composing patterns", "cited"}
_FAMILY_LINE = re.compile(r"^Term standard label family:(.+)$", re.M)


def standard_families(grammar_path=None):
    """The standard label families, from GRACE-lang.md rather than from a copy.

    This set was hand-copied here for four versions. It happened to be correct
    every time it was read, which is the only reason the drift never showed:
    a family the grammar declares and this file has not heard of is reported as
    a non-standard family spreading across specs, and a family this file lists
    that the grammar has dropped is silently exempt from that report. Council
    read 35 asked whether the tools knew `Capability requirement`; they did,
    by luck rather than by derivation. Same cure as check.py's category set —
    read the declaration, exit rather than guess (Closed vocabulary 1)."""
    g = Path(grammar_path) if grammar_path else Path(__file__).resolve().parents[2] / "GRACE-lang.md"
    try:
        m = _FAMILY_LINE.search(g.read_text(encoding="utf-8"))
    except OSError:
        m = None
    if not m:
        raise SystemExit(
            "cites.py: GRACE-lang.md carries no `Term standard label family` "
            "line; the standard set has no authority to derive from "
            "(GRACE-lang Standard label 1)")
    return set(_family_glosses(m.group(1)))


def _family_glosses(body: str) -> dict[str, str]:
    """`Name (gloss) | Name (gloss)` — the family line's value set, its names bare
    since v0.51. The `|` inside a gloss's parentheses is not a separator."""
    out: dict[str, str] = {}
    depth, cur, parts = 0, "", []
    for ch in body.strip().rstrip("."):
        depth += ch == "("
        depth -= ch == ")"
        if ch == "|" and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    parts.append(cur)
    for part in parts:
        pm = re.match(r"^\s*`?([^`(]+?)`?\s*\((.*)\)\s*$", part, re.S)
        if pm:
            out[pm.group(1).strip()] = pm.group(2)
    return out


STANDARD_FAMILIES = standard_families()
LABEL_PARTS = re.compile(
    r"^(?P<name>.+?)(?: step (?P<step>[\d½]+)\.(?P<sn>\d+)| (?P<major>\d+)\.(?P<minor>\d+)| (?P<num>\d+))(?P<letter>[a-z]?)$")
CROSS_REF = re.compile(
    r"(?<![\w-])([A-Z][A-Za-z-]*(?: [A-Z][A-Za-z-]*){0,3}) "
    r"((?:[A-Z][a-z]+|[a-z_]+)(?: [a-z]+){0,2} \d+(?:\.\d+)?[a-z]?)(?![\w.]\d)")


_GLOSS_WORD = re.compile(r"[a-z]+")
_GLOSS_STOP = frozenset(
    "the a an of to in on at by for and or with is are as it its this that what one every "
    "any no not nothing something whose which than then from".split())


def standard_glosses(grammar_path=None) -> dict[str, str]:
    """Each standard family with the meaning the grammar declares for it —
    the parenthetical on the same `Term standard label family` line
    `standard_families` reads the names from. Derived, never copied, for the
    reason that function's docstring gives."""
    g = Path(grammar_path) if grammar_path else Path(__file__).resolve().parents[2] / "GRACE-lang.md"
    m = _FAMILY_LINE.search(g.read_text(encoding="utf-8"))
    if not m:
        raise SystemExit("cites.py: GRACE-lang.md carries no `Term standard label family` line")
    return _family_glosses(m.group(1))


def _content(s: str) -> set[str]:
    return {w for w in _GLOSS_WORD.findall(s.lower())
            if w not in _GLOSS_STOP and len(w) > 2}


def promote(specs: list["Spec"], family: str, means: str | None) -> int:
    """Stage a promotion hearing, or audit a family already standard.

    `Standard label 2` forbids a specification redeclaring a standard label
    family, so a promotion silently converts every local restatement of the
    candidate's meaning into a defect. Four sites were converted that way
    across three promotions — Customer Onboarding's `reconciliation`, Actor
    Suspension's `sweep`, Attributed Permissions Admin's `failed-grant leg`,
    Idempotent Reservation's `eviction leg` — and nothing reported any of
    them; each was caught by a human reading the specs the promotion named
    (council reads 69, 71, the docket row opened at 72).

    This is not a classifier and does not decide. The maintainer supplies the
    meaning the promotion would declare (Principle 8, Standard label 6); the
    tool supplies the reading order, ranking each member spec's `Term`
    declarations by how much of that meaning they already carry. A verdict
    from word overlap would be a second owner for a judgment the grammar
    reserves to a person — and `Audit arm`'s meaning is written in the
    corpus's commonest nouns, so such a verdict fires on innocent entries."""
    glosses = standard_glosses()
    standard = family in glosses
    if standard:
        means = means or glosses[family]
        print(f"{family} — already standard. The grammar declares it: {means}")
        print("  (this run is a standing audit, not a hearing)")
    else:
        print(f"{family} — not in the standard set.")
        if not means:
            print("  no meaning supplied. A hearing needs the meaning the promotion "
                  "would declare; pass --means \"…\". The maintainer decides every "
                  "promotion (Principle 8, Standard label 6).")
            return 2
    members = [(s, sum(1 for lab in s.rules if NAME_NUM.sub("", lab) == family))
               for s in specs]
    members = sorted([(s, n) for s, n in members if n], key=lambda r: -r[1])
    print(f"\n  {len(members)} specification(s) name it, {sum(n for _, n in members)} rules:")
    for s, n in members:
        print(f"    {spec_name(s.path):<34}{n:>4}")
    if not standard:
        print(f"  Standard label 4: three specifications make it a candidate — "
              f"{'met' if len(members) >= 3 else 'NOT met'}.")
    want = _content(means)
    rows = []
    for s, _ in members:
        for term, (line, text) in s.terms.items():
            shared = want & _content(text)
            if len(shared) >= 2:
                rows.append((len(shared), spec_name(s.path), term, line, sorted(shared)))
    print(f"\n  `Term` declarations in the member specs, most of the meaning first —"
          f"\n  every one of these is a Standard label 2 defect if it states the meaning "
          f"rather than pointing at the spec's own rules:")
    if not rows:
        print("    none carrying two words of it.")
    for n, name, term, line, shared in sorted(rows, key=lambda r: (-r[0], r[1], r[2])):
        print(f"    {n}  {name}:{line}  `{term}` — {', '.join(shared)}")
    print(f"\n— {len(rows)} declaration(s) to read. Standard label 7's drift pass is not "
          f"mechanical: read the rules, not this list (Principle 8).")
    return 0


def into(specs: list[Spec], target: str) -> dict[str, list[str]]:
    """Every rule in the corpus citing the named spec, by cited label. Run it
    before rewriting a spec: a label the corpus cites is a label that keeps its
    number, or a citation that breaks silently (Hard invariant 28)."""
    theirs = next((set(s.rules) for s in specs if spec_name(s.path) == target), set())

    def cited(text: str, own: set[str]) -> list[str]:
        found: list[str] = []
        for m in CROSS_REF.finditer(text):
            if m.group(1) != target or f"{m.group(1)} {m.group(2)}" in own:
                continue
            found.append(m.group(2))
            # a range citation cites every label between its ends (Hard invariant 29)
            end = RANGE_END.match(text, m.end())
            fam = NAME_NUM.search(m.group(2))
            if end and fam:
                found += sorted(lab for lab in theirs if lab != m.group(2) and
                                in_range(lab, m.group(2)[:fam.start()], fam.group(1), end.group(1)))
        return found

    out: dict[str, list[str]] = {}
    for spec in specs:
        if spec_name(spec.path) == target:
            continue
        rule_lines = set(spec.rules.values())
        own = set(spec.rules)
        for label, text in spec.text_of.items():
            for ref in cited(text, own):
                out.setdefault(ref, []).append(
                    f"{spec.path.name}:{spec.rules[label]}: {label}")
        # a citation in prose carries no obligation and still sends a reader
        for i, raw in enumerate(spec.path.read_text(encoding="utf-8").split("\n"), start=1):
            if i in rule_lines:
                continue
            for ref in cited(raw, own):
                out.setdefault(ref, []).append(f"{spec.path.name}:{i}: (prose)")
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
        text = p.read_text(encoding="utf-8")
        # a spec says it is migrated; the tools never guess it from a fence
        if p.name != "GRACE-lang.md" and not MIGRATED.search(text):
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

    if "--standard" in argv:
        glosses = standard_glosses()
        print(f"the standard label families — {len(glosses)}, as GRACE-lang declares them:")
        for i, (fam, gl) in enumerate(glosses.items(), start=1):
            print(f"  {i:>2}. {fam} — {gl}")
        print("— a family here is standard; a specification MUST NOT redeclare one "
              "(Standard label 2).")
        return 0

    if "--promote" in argv:
        i = argv.index("--promote")
        fam = argv[i + 1] if i + 1 < len(argv) and not argv[i + 1].startswith("--") else None
        means = None
        if "--means" in argv:
            j = argv.index("--means")
            means = argv[j + 1] if j + 1 < len(argv) else None
        if not fam:
            print("cites.py --promote <Family> [--means \"the meaning the promotion declares\"]")
            return 2
        return promote(specs, fam, means)
    if "--unchecked" in argv:
        # the inverse of K-check-bare: a rule no check names. A rule with no
        # check is a claim nobody audits — the silence is the finding (council read 11).
        i = argv.index("--unchecked")
        stem = argv[i + 1] if i + 1 < len(argv) and not argv[i + 1].startswith("--") else None
        for spec in specs_with_rules(root, paths):
            if stem and spec.path.stem != stem:
                continue
            lab_re = _label_pattern(set(spec.rules))
            checked: set[str] = set()
            for label, text in spec.text_of.items():
                parts = LABEL_PARTS.match(label)
                if not parts or parts.group("name") not in ("Check", "External check"):
                    continue
                if lab_re:
                    for m in lab_re.finditer(text):
                        checked.add(m.group(1) + m.group(2))
                        grp = re.match(r"^(.*?) (\d+)\.\d+[a-z]?$", m.group(1) + m.group(2))
                        if grp:
                            checked.add(f"{grp.group(1)} {grp.group(2)}")
            bare = [lab for lab in spec.rules
                    if (LABEL_PARTS.match(lab) or None) and
                    LABEL_PARTS.match(lab).group("name") not in ("Check", "External check")
                    and lab not in checked]
            if not spec.rules or not checked:
                print(f"{spec.path.name}: no checks — nothing audits any of its {len(spec.rules)} rules")
                continue
            by_family: dict[str, list[str]] = {}
            for lab in bare:
                by_family.setdefault(LABEL_PARTS.match(lab).group("name"), []).append(lab)
            print(f"{spec.path.name}: {len(bare)} of {len(spec.rules)} rules named by no check")
            # an unchecked invariant is the one that matters: a claim the spec
            # makes about every reachable state, and nothing tests it
            for fam in ("Invariant", "Identity", "State"):
                if fam in by_family:
                    labs = sorted(by_family.pop(fam))
                    print(f"  {fam}: {len(labs)} unchecked — {', '.join(labs[:8])}"
                          + (" …" if len(labs) > 8 else ""))
            rest = ", ".join(f"{f} ({len(v)})" for f, v in sorted(by_family.items()))
            if rest:
                print(f"  elsewhere: {rest}")
        return 0
    if "--drift" in argv:
        # the same name, declared twice, differently — and the same label family
        # carrying different rules in two specs. The corpus's error mass moved
        # between the documents; this is the walker pointed there (council read 10).
        corpus = specs_with_rules(root, None)
        decls: dict[str, list[tuple[str, str]]] = {}
        families: dict[str, set[str]] = {}
        for spec in corpus:
            for name, (_, body) in spec.terms.items():
                if name in CATEGORY_NAMES:
                    continue
                decls.setdefault(name, []).append((spec.path.name, body.strip()))
            for label in spec.rules:
                parts = LABEL_PARTS.match(label)
                if parts:
                    families.setdefault(parts.group("name"), set()).add(spec.path.name)
        term_drift = {n: v for n, v in decls.items()
                      if len(v) > 1 and len({b for _, b in v}) > 1}
        family_spread = {f: s for f, s in families.items()
                         if len(s) > 1 and f not in STANDARD_FAMILIES}
        if term_drift:
            print(f"terms declared more than one way — {len(term_drift)}:")
            for name in sorted(term_drift):
                print(f"  `{name}`")
                for path, body in term_drift[name]:
                    print(f"      {path}: {body[:110]}")
        if family_spread:
            print(f"label families outside the standard set, used in more than one spec — {len(family_spread)}:")
            for fam in sorted(family_spread):
                print(f"  {fam}: {', '.join(sorted(family_spread[fam]))}")
        if not term_drift and not family_spread:
            print("— no term declared two ways, no local family spread across specs.")
        return 0
    if "--terms" in argv:
        i = argv.index("--terms")
        name = argv[i + 1] if i + 1 < len(argv) else ""
        # every declaration of one name, across the corpus: a term is one
        # concept or it is several wearing one name (council read 9)
        seen = []
        for spec in specs_with_rules(root, None):
            if name in spec.terms:
                line, body = spec.terms[name]
                seen.append((spec.path.name, line, body))
        if not seen:
            print(f"— no spec declares `{name}`.")
            return 0
        print(f"`{name}`: {len(seen)} declaration(s)")
        for path, line, body in seen:
            print(f"  {path}:{line}: {body}")
        if len(seen) > 1:
            print("— one name, several declarations. A reader of two specs reads both.")
        return 0
    if "--queue" in argv:
        # what the corpus cites but has not migrated, most-cited first
        corpus = specs_with_rules(root, None)
        migrated = {spec_name(s.path) for s in corpus}
        counts: dict[str, int] = {}
        for spec in corpus:
            for i, raw in enumerate(spec.path.read_text(encoding="utf-8").split("\n"), start=1):
                for m in CROSS_REF.finditer(raw):
                    target = m.group(1)
                    if f"{m.group(1)} {m.group(2)}" in spec.rules:
                        continue  # the citing spec's own label family, not a citation
                    if target not in migrated and (root / "atoms" / (target.lower().replace(" ", "-") + ".md")).exists():
                        counts[target] = counts.get(target, 0) + 1
        if not counts:
            print("— every spec the corpus cites by label is migrated.")
            return 0
        print("unmigrated specs the corpus cites, most-cited first:")
        for target, n in sorted(counts.items(), key=lambda kv: -kv[1]):
            print(f"  {target}: {n} citation(s)")
        return 0
    if "--unread" in argv:
        # what the rewrite outran: a migrated spec no council read has read.
        # The register names every read and the qualifiers line names every
        # migration, so the gap is derived rather than kept by hand — the same
        # discipline open-questions.md §Generated index asks for. The register's
        # subject is prose ("Lease as rewritten and relabelled"), so a spec is
        # read when its name appears in that phrase; a version there is a read
        # of the grammar.
        reg = (root / "governance.md").read_text(encoding="utf-8")
        reads = [(m.group("n"), m.group("spec").strip()) for m in REGISTER.finditer(reg)]
        rows = []
        for path in [root / "GRACE-lang.md"] + sorted(root.glob("atoms/*.md")) + \
                    sorted(root.glob("compositions/*.md")):
            if not path.exists() or not MIGRATED.search(path.read_text(encoding="utf-8")):
                continue
            name = spec_name(path)
            # A register subject is prose, so it spells a multi-word name the way
            # English wants it — Session-Gated Authorization for the spec this
            # tool calls Session Gated Authorization. Match on a hyphen- and
            # case-insensitive form so a hyphen does not read as an unread spec.
            flat = lambda t: t.replace("-", " ").casefold()
            hits = [n for n, phrase in reads
                    if flat(name) in flat(phrase)
                    or (name == "GRACE-lang" and phrase.startswith("v0."))]
            rows.append((name, path, hits))
        unread = [r for r in rows if not r[2]]
        print(f"{len(rows)} migrated; {len(unread)} carry no council read.")
        for name, path, _ in unread:
            print(f"  {path.relative_to(root).as_posix()}: {name} — unread")
        if not unread:
            print("  — every migrated spec has been read.")
        return 0
    if "--into" in argv:
        i = argv.index("--into")
        stem = argv[i + 1] if i + 1 < len(argv) else ""
        target = spec_name(Path(stem if stem.endswith(".md") else stem + ".md"))
        cited = into(specs_with_rules(root, None), target)
        if not cited:
            print(f"— nothing in the corpus cites {target} by label.")
            return 0
        print(f"{target}: {len(cited)} label(s) the corpus cites — each keeps its number")
        for label in sorted(cited):
            print(f"  {target} {label}  ← {len(cited[label])} site(s)")
            for site in sorted(set(cited[label])):
                print(f"      {site}")
        return 0
    if rev:
        seeds_by_path = {}
        for spec in specs:
            seeds = changed_seeds(root, rev, spec)
            seeds_by_path[spec.path] = seeds
            total += report(spec, seeds)
        # a cited rule's own spec is never the whole blast radius
        corpus = specs if paths is None else specs_with_rules(root, None)
        elsewhere = across(corpus, seeds_by_path)
        for ref in sorted(elsewhere):
            print(f"cross-spec: {ref} changed — {len(set(elsewhere[ref]))} to re-read")
            for site in sorted(set(elsewhere[ref])):
                print(f"  {site}")
            total += len(set(elsewhere[ref]))
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
            elsewhere = across(specs, {spec.path: {seed}})
            for ref in sorted(elsewhere):
                print(f"cross-spec: {ref} — {len(set(elsewhere[ref]))} to re-read")
                for site in sorted(elsewhere[ref]):
                    print(f"  {site}")
    if not found:
        print(f"— no rule or term named {seed}.")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

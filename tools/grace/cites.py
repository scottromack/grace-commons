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
REGISTER = re.compile(r"\*\*Council read (?P<n>\d+) — \w+ on (?P<spec>[^,]+),")
MIGRATED = re.compile(r"^Terms › `qualifiers`:[^\n]*`migrated`", re.M)
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
    for path, labels in seeds.items():
        name = spec_name(path)
        for label in labels:
            if label.startswith("`"):
                continue
            wanted.append((f"{name} {label}", path.name))
            group = re.match(r"^(.*?) (\d+)\.\d+[a-z]?$", label)
            if group:
                wanted.append((f"{name} {group.group(1)} {group.group(2)}", path.name))
    out: dict[str, list[str]] = {}
    for spec in specs:
        rule_lines = set(spec.rules.values())
        for label, text in spec.text_of.items():
            for ref, origin in wanted:
                if ref in text and spec.path.name != origin:
                    out.setdefault(ref, []).append(
                        f"{spec.path.name}:{spec.rules[label]}: {label}")
        # a citation in prose carries no obligation and still sends a reader
        for i, raw in enumerate(spec.path.read_text(encoding="utf-8").split("\n"), start=1):
            if i in rule_lines:
                continue
            for ref, origin in wanted:
                if ref in raw and spec.path.name != origin:
                    out.setdefault(ref, []).append(f"{spec.path.name}:{i}: (prose)")
    return out


CATEGORY_NAMES = {"actors", "records", "record verbs", "value sets", "bounds",
                  "cadences", "terms", "qualifiers", "composing patterns", "cited"}
STANDARD_FAMILIES = {"Identity", "State", "Operation", "Invariant", "Check",
                     "External check", "Non-goal", "Composition note", "Composes",
                     "Capability requirement"}
LABEL_PARTS = re.compile(
    r"^(?P<name>.+?)(?: step (?P<step>[\d½]+)\.(?P<sn>\d+)| (?P<major>\d+)\.(?P<minor>\d+)| (?P<num>\d+))(?P<letter>[a-z]?)$")
CROSS_REF = re.compile(
    r"(?<![\w-])([A-Z][A-Za-z-]*(?: [A-Z][A-Za-z-]*){0,3}) "
    r"((?:[A-Z][a-z]+|[a-z_]+)(?: [a-z]+){0,2} \d+(?:\.\d+)?[a-z]?)(?![\w.]\d)")


def into(specs: list[Spec], target: str) -> dict[str, list[str]]:
    """Every rule in the corpus citing the named spec, by cited label. Run it
    before rewriting a spec: a label the corpus cites is a label that keeps its
    number, or a citation that breaks silently (Hard invariant 28)."""
    out: dict[str, list[str]] = {}
    for spec in specs:
        if spec_name(spec.path) == target:
            continue
        rule_lines = set(spec.rules.values())
        own = set(spec.rules)
        for label, text in spec.text_of.items():
            for m in CROSS_REF.finditer(text):
                if m.group(1) == target and f"{m.group(1)} {m.group(2)}" not in own:
                    out.setdefault(m.group(2), []).append(
                        f"{spec.path.name}:{spec.rules[label]}: {label}")
        # a citation in prose carries no obligation and still sends a reader
        for i, raw in enumerate(spec.path.read_text(encoding="utf-8").split("\n"), start=1):
            if i in rule_lines:
                continue
            for m in CROSS_REF.finditer(raw):
                if m.group(1) == target and f"{m.group(1)} {m.group(2)}" not in own:
                    out.setdefault(m.group(2), []).append(
                        f"{spec.path.name}:{i}: (prose)")
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
            hits = [n for n, phrase in reads
                    if name in phrase or (name == "GRACE-lang" and phrase.startswith("v0."))]
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

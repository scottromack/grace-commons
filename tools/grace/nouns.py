#!/usr/bin/env python3
"""Which nouns in a rule resolve to nothing — Closed vocabulary 4's first reader.

Closed vocabulary 8 has an instrument: `check.py`'s `C-verb` reads the verb after
every modal against the specification's declared record verbs. Closed vocabulary
4 — EVERY normative identifier MUST resolve to a declaration — had none, and a
measurement over the migrated corpus found almost one noun phrase in five
resolving to nothing (council read 100). This tool is that measurement, kept.

It reads the labelled rules of every migrated specification, removes code
spans, bracket markers, label citations, reserved tokens and specification
names, tags the rest with NLTK's averaged-perceptron tagger (the word after a
modal is read as a verb), and matches each noun phrase against the names the
specification declares, its constituents declare and the grammar declares:
whole first, then by any declared name inside the phrase.

    python3 tools/grace/nouns.py                 # per-spec counts and the most common misses
    python3 tools/grace/nouns.py --spec lease    # every miss in one spec, by line
    python3 tools/grace/nouns.py --json          # the whole reading, for another tool

Advisory by design: a tagger decides what is a noun, so the count is good to a
few percent and never gates. It needs `nltk` and the tagger model:

    pip install nltk
    python3 -c "import nltk; nltk.download('averaged_perceptron_tagger_eng')"
"""
from __future__ import annotations

import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
import check as C  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
STOP = {"n", "who", "which", "that", "each", "one", "two", "must", "if", "then", "when", "equals"}
NOUN_TAGS = ("NN", "NNS", "NNP", "NNPS")


def norm(w: str) -> str:
    return re.sub(r"['’]s$", "", w.lower().strip("'’"))


def forms(p: str) -> set[str]:
    p = norm(p)
    out = {p}
    for suf, rep in (("ies", "y"), ("es", ""), ("s", ""), ("ed", ""), ("ing", "")):
        if p.endswith(suf) and len(p) > len(suf) + 2:
            out.add(p[: -len(suf)] + rep)
    return out


def names_of(text: str) -> set[str]:
    """Every name a document declares, in each of its plain forms."""
    extra: set[str] = set()
    for m in re.finditer(r"^\s*Term (actors|records|terms|bounds|cadences|cited):(.*)$", text, re.M):
        body = m.group(2)
        for alias in re.findall(r"\((?:also: )?([^)]*)\)", body):
            extra |= {a.strip() for a in re.split(r",|;| or ", alias)}
        body = re.sub(r"\([^)]*\)", "", body)
        extra |= {a.strip() for a in re.split(r",|;| and ", body.split(" — ")[0].rstrip("."))}
    extra |= set(re.findall(r"^\s*- \*\*([a-z][a-z0-9_ -]*)\*\* — ", text, re.M))
    m = re.search(r"^Term rule noun:.*? — (.+)\.$", text, re.M)
    if m:
        extra |= {x.strip() for x in m.group(1).split(",")}
    out: set[str] = set()
    for x in C.declared_names(text) | set(C.declared_terms(text)) | extra:
        x = re.sub(r"^(a|an|the|every) ", "", x.lower().strip())
        if x:
            out |= forms(x)
    return out


def constituents(path: Path, text: str) -> list[Path]:
    m = re.search(r"^Term constituents:(.*)$", text, re.M)
    if not m:
        return []
    return [(path.parent / link).resolve() for link in re.findall(r"\]\(([^)]+\.md)", m.group(1))]


def rules_of(text: str):
    """(line, rule text) for every labelled rule in a normative block."""
    lines = text.split("\n")
    i, n = 0, len(lines)
    while i < n:
        m = C.FENCE.match(lines[i])
        if not m:
            i += 1
            continue
        j = i + 1
        while j < n and not (C.FENCE.match(lines[j]) and C.FENCE.match(lines[j]).group(2) == ""):
            j += 1
        block = lines[i + 1:j]
        first = next((b.strip() for b in block if b.strip()), "")
        if m.group(2) == "" and C.LABEL.match(first) and not C.PREFIX.match(first):
            for k, b in enumerate(block):
                s = b.strip()
                if C.LABEL.match(s) and not C.PREFIX.match(s):
                    yield i + 2 + k, s
        i = j + 1


def clean(rule: str) -> str:
    body = re.sub(r"^[^:]+?\d+(?:\.\d+)?[a-z]?:\s*", "", rule)
    body = re.sub(r"`[^`]*`", " , ", body)
    body = re.sub(r"\[[^\]]*\]", " , ", body)
    body = re.sub(r"\([^)]*\)", " , ", body)
    body = re.sub(r"\b[A-Z][A-Za-z]*(?: [A-Z][a-z]+)* (?:step )?\d+(?:\.\d+)?[a-z]?\b", " , ", body)
    body = re.sub(r"\b(MUST NOT|MUST|MAY)\b", " must ", body)
    body = re.sub(r"\bIF\b", " , if ", body)
    body = re.sub(r"\bTHEN\b", " then ", body)
    body = re.sub(r"\bWHEN\b", " , when ", body)
    body = re.sub(r"\b(DOES NOT EQUAL|EQUALS|EXISTS|EXCEEDS|DOES NOT EXCEED|IS NOT IN|IS IN|EXCEED)\b", " equals ", body)
    body = re.sub(r"\b[A-Z]{2,}(?: [A-Z]{2,})*\b", " , ", body)
    body = re.sub(r"\bcomposing (?=[A-Z])", "", body)  # "the composing Audit Trail" names a spec
    body = re.sub(r"\b[A-Z][a-z]+(?: [A-Z][a-z]+)*\b", " , ", body)
    return body


def phrases(body: str, tagger) -> list[list[str]]:
    toks = re.findall(r"[a-z][a-z0-9_]*(?:[-'’][a-z0-9_]+)*|[,.;:—]", body)
    if not toks:
        return []
    out, cur, prev = [], [], None
    for w, t in tagger(toks):
        if "_" in w:
            t = "NN"
        if prev == "must":
            t = "VB"
        prev = w
        if t in ("JJ", "VBN", "VBG") + NOUN_TAGS and w not in STOP:
            cur.append((w, t))
        elif cur:
            out.append(cur)
            cur = []
    if cur:
        out.append(cur)
    res = []
    for ph in out:
        while ph and ph[-1][1] not in NOUN_TAGS:
            ph = ph[:-1]
        if ph:
            res.append([norm(w) for w, _ in ph])
    return res


def resolve(ph: list[str], known: set[str]) -> str:
    """whole | inner | none"""
    if forms(" ".join(ph)) & known:
        return "whole"
    if any(forms(" ".join(ph[i:j])) & known for i in range(len(ph)) for j in range(i + 1, len(ph) + 1)):
        return "inner"
    return "none"


def read(paths: list[Path], grammar: Path, tagger):
    gnames = names_of(grammar.read_text(encoding="utf-8"))
    cache: dict[Path, set[str]] = {}

    def own(p: Path) -> set[str]:
        if p not in cache:
            cache[p] = names_of(p.read_text(encoding="utf-8")) if p.exists() else set()
        return cache[p]

    report = {"rules": 0, "whole": 0, "inner": 0, "none": 0, "specs": {}}
    for p in paths:
        text = p.read_text(encoding="utf-8")
        known = own(p) | gnames
        for c in constituents(p, text):
            known |= own(c)
        spec = report["specs"].setdefault(p.stem, {"none": 0, "misses": defaultdict(list)})
        for line, rule in rules_of(text):
            report["rules"] += 1
            for ph in phrases(clean(rule), tagger):
                kind = resolve(ph, known)
                report[kind] += 1
                if kind == "none":
                    spec["none"] += 1
                    spec["misses"][" ".join(ph)].append(line)
    return report


def environment(nltk) -> str:
    """The tagger the count was taken under: a retrained model moves the count."""
    import hashlib
    try:
        d = Path(nltk.data.find("taggers/averaged_perceptron_tagger_eng/"))
        w = next(d.glob("*weights*"))
        digest = hashlib.sha256(w.read_bytes()).hexdigest()[:12]
    except Exception:
        digest = "unknown"
    return f"nltk {nltk.__version__}, averaged_perceptron_tagger_eng weights {digest}"


def main(argv: list[str]) -> int:
    try:
        import nltk
        tagger = nltk.pos_tag
        tagger(["probe"])
    except Exception as e:  # nltk or its model missing
        print(f"nouns.py: needs nltk and averaged_perceptron_tagger_eng ({type(e).__name__}); see the module docstring")
        return 2
    only = argv[argv.index("--spec") + 1] if "--spec" in argv else None
    paths = []
    for d in ("atoms", "compositions"):
        for p in sorted((ROOT / d).glob("*.md")):
            if only and p.stem != only:
                continue
            if C.MIGRATED.search(p.read_text(encoding="utf-8")):
                paths.append(p)
    rep = read(paths, ROOT / "GRACE-lang.md", tagger)
    rep["environment"] = environment(nltk)
    if "--json" in argv:
        print(json.dumps(rep, indent=1, default=list))
        return 0
    total = rep["whole"] + rep["inner"] + rep["none"]
    print(f"{rep['rules']} rules in {len(paths)} spec(s); {total} noun phrases: "
          f"{rep['whole']} resolve whole, {rep['inner']} only through a declared name inside, "
          f"{rep['none']} to nothing (Closed vocabulary 4) — under {rep['environment']}")
    if only:
        for phrase, lines in sorted(rep["specs"][only]["misses"].items(), key=lambda x: -len(x[1])):
            print(f"  {phrase}: " + ", ".join(str(n) for n in lines))
        return 0
    rows = sorted(((s["none"], name) for name, s in rep["specs"].items() if s["none"]), reverse=True)
    print("unresolved by spec: " + ", ".join(f"{name} {n}" for n, name in rows))
    common = Counter()
    for s in rep["specs"].values():
        for phrase, lines in s["misses"].items():
            common[phrase] += len(lines)
    print("most common: " + ", ".join(f"{w} {n}" for w, n in common.most_common(30)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""GRACE lang surface checker — the mechanical slice of `GRACE-lang.md`.

Reads a spec's normative surface the way §2 and §17 of the grammar say a parser
must — a fenced ```text block classified by its first line, `Terms ›`
declarations — and reports what a form-reader can decide without semantics:
fence classification (Surface 18, Surface 19) and signature blocks (Surface 20), unlabelled lines (Hard invariant 1, Sugar 3), label uniqueness
and tombstone reuse (Hard invariant 25, Hard invariant 27), the rule form and the statement shapes (Rule shape 1, Rule shape 2,
Rule shape 6, Hard invariant 2, Hard invariant 3), WHEN blocks (WHEN block 3, Hard invariant 6), mixed AND/OR and OR outside a condition (Hard invariant 7,
Hard invariant 8), BEFORE and AFTER outside their admitted places (Hard invariant 9–11), the banned
words (Timing 10, Timing 11), arithmetic in a rule (Hard invariant 24), pronouns (Hard invariant 4), the copula after
a modal (Closed vocabulary 8, Closed vocabulary 14), the record verb after the modal against the declared
vocabulary (Closed vocabulary 8), a declared term nothing uses, and a cross-rule reference to a
label no rule carries (Hard invariant 12).

Standard library only. `python3 tools/grace/check.py [paths...]`; with no path
it reads GRACE-lang.md and every file under atoms/ and compositions/ that
carries a ```text fence. Prints one finding per line, `path:line: [CODE] message`.
Non-gating by default: exits 0 whatever it finds; `--gate` exits 1 on any
finding that is not advisory (the W- codes).

What it does not do: resolve every identifier (Closed vocabulary 4), parse value sets against
conditions (Hard invariant 14), or normalize (§16). Those need the parser this is the
forerunner of.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

LABEL = re.compile(r"^((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?):\s*(.*)$")
LABEL_PARTS = re.compile(r"^(?P<name>.+?)(?: step (?P<step>[\d½]+)\.(?P<sn>\d+)| (?P<major>\d+)\.(?P<minor>\d+)| (?P<num>\d+))(?P<letter>[a-z]?)$")
PREFIX = re.compile(r"^(WHY|NOTE|UX|PROVISIONAL):")
FENCE = re.compile(r"^(\s*)```(\w*)\s*$")
MIGRATED = re.compile(r"^Terms › `qualifiers`:[^\n]*`migrated`", re.M)
TERM_DECL = re.compile(r"^\s*Terms › `([^`]+)`:\s*(.*)$")
MODAL = re.compile(r"\b(MUST NOT|MUST|MAY)\b")
TOMBSTONE = re.compile(r"^NOTE:\s*((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?)\s+deleted\b")
PRONOUN = re.compile(r"\b(it|its|itself|they|their|them|he|she|his|her)\b")
ARITH = re.compile(r"[+×−]|\s-\s")
MARKER = re.compile(r"\[([^\]\[]+)\]")
CODE_SPAN = re.compile(r"`[^`]*`")
SIGNATURE = re.compile(r"^[a-z_][a-z0-9_]*\(")
ADVISORY = {"W-or-word", "W-watch-word", "W-term-unused", "W-lowercase-after",
            "D-decl-modal", "D-decl-selfref", "D-decl-unresolved",
            "K-check-bare", "S-action-unused"}
# A declaration may carry arithmetic and comparison where a rule may not
# (Closed vocabulary 9, Closed vocabulary 11) — which is where complexity
# goes when a rule cannot hold it, and the one place nothing read it.
DECL_ARITH = re.compile(r"[−+×÷]|\bmax\(|\bmin\(")
DECL_TOKEN = re.compile(r"[a-z_][a-z0-9_]*")
DECL_SKIP = {"max", "min", "of", "the", "a", "an", "and", "or", "per", "less", "true", "false"}
RESERVED_VERBS = {"EXCEED"}


@dataclass
class Rule:
    line: int
    label: str
    text: str
    indent: int
    parent: str | None = None


@dataclass
class Finding:
    path: Path
    line: int
    code: str
    message: str


def _words(s: str) -> list[str]:
    s = s.replace("`", " ").lower()
    out = []
    for w in re.split(r"[\s/=—–(),.:;*-]+", s):
        w = w.strip("'’")
        if not w:
            continue
        if w.endswith("ies") and len(w) > 4:
            w = w[:-3] + "y"
        elif w.endswith("s") and len(w) > 3 and not w.endswith("ss"):
            w = w[:-1]
        out.append(w)
    return out


def _matches(word: str, heading_words: list[str]) -> bool:
    for h in heading_words:
        if word == h or (min(len(word), len(h)) >= 4 and (h.startswith(word) or word.startswith(h))):
            return True
    return False


def declared_verbs(text: str) -> set[str] | None:
    m = re.search(r"^\s*(?:Terms › `record verbs`|Record verbs):\s*(.*)$", text, re.M)
    if not m:
        return None
    return {v.strip().strip("`").rstrip(".") for v in m.group(1).split(",") if v.strip()}


def declared_terms(text: str) -> dict[str, int]:
    out: dict[str, int] = {}
    for i, line in enumerate(text.split("\n"), start=1):
        m = TERM_DECL.match(line)
        if m:
            out.setdefault(m.group(1), i)
    return out


def scan(path: Path) -> list[Finding]:
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    findings: list[Finding] = []
    rules: list[Rule] = []
    labels: dict[str, int] = {}
    tombstones: dict[str, int] = {}
    exemplars: set[str] = set()
    signatures: list[tuple[int, str]] = []

    def add(line: int, code: str, msg: str) -> None:
        findings.append(Finding(path, line, code, msg))

    ctx = {"h2": "", "h3": "", "h4": "", "bullet": "", "italic": "", "inv": None, "step": None}

    def track(ln: str) -> None:
        hm = re.match(r"^(#{2,4}) (.*)$", ln)
        if hm:
            lvl = len(hm.group(1))
            if lvl == 2:
                ctx.update(h2=hm.group(2), h3="", h4="")
            elif lvl == 3:
                ctx.update(h3=hm.group(2), h4="")
            else:
                ctx["h4"] = hm.group(2)
            ctx.update(bullet="", italic="", inv=None, step=None)
            return
        im = re.match(r"^\s*- \*\*Invariant (\d+) —(.*)", ln)
        if im:
            ctx.update(inv=im.group(1), bullet="Invariant " + im.group(2), step=None)
            return
        bm = re.match(r"^- \*\*([^*]+)\*\*", ln)
        if bm and not bm.group(1).startswith("["):
            ctx.update(bullet=bm.group(1), italic="", inv=None, step=None)
            return
        sm = re.match(r"^\s*(\d+)\. \*\*", ln) or re.match(r"^\s*\*\*Step ([\d½]+)", ln)
        if sm:
            ctx["step"] = sm.group(1)
            return
        it = re.match(r"^\*([A-Z][^*]*?)\*", ln)
        if it:
            ctx["italic"] = it.group(1)

    i = 0
    n = len(lines)
    while i < n:
        m = FENCE.match(lines[i])
        if not m:
            track(lines[i])
            i += 1
            continue
        if m.group(2) != "text":
            # Surface 20/Surface 21: a bare fence opening with a signature line is a signature block; any other fence is nothing
            k = i + 1
            while k < n and not lines[k].strip():
                k += 1
            head = lines[k].strip() if k < n else ""
            if m.group(2) == "" and SIGNATURE.match(head):
                end = k
                while end < n and not (FENCE.match(lines[end]) and FENCE.match(lines[end]).group(2) == ""):
                    end += 1
                body = " ".join(x.strip() for x in lines[k:end])
                if "→" not in body:
                    add(k, "F-signature", f"signature block without a result arrow: {head[:60]}")
                # v0.35: one line per action, one or more lines per block
                for off, sig in enumerate(lines[k:end]):
                    if SIGNATURE.match(sig.strip()):
                        signatures.append((k + off, sig.strip().split("(")[0]))
                i = end + 1
                continue
            i += 1
            continue
        fence_indent = len(m.group(1))
        start = i + 1
        j = start
        while j < n and not (FENCE.match(lines[j]) and FENCE.match(lines[j]).group(2) == ""):
            j += 1
        block = lines[start:j]
        # Surface 18: classify by the first non-blank line
        first = next((b.strip() for b in block if b.strip()), "")
        if not first:
            add(start, "F-fence-empty", "empty ```text fence")
        elif PREFIX.match(first):
            # Surface 22: the prefix covers the whole block — not normative; labels inside are exemplars
            for raw in block:
                lm = LABEL.match(raw.strip())
                if lm:
                    exemplars.add(lm.group(1))
        elif LABEL.match(first):
            stack: list[Rule] = []
            for k, raw in enumerate(block, start=start + 1):
                s = raw.strip()
                if not s:
                    continue
                indent = len(raw) - len(raw.lstrip()) - fence_indent
                if PREFIX.match(s):
                    t = TOMBSTONE.match(s)
                    if t:
                        lab = t.group(1)
                        if lab in tombstones:
                            add(k, "L-dup-tombstone", f"{lab} tombstoned twice")
                        tombstones[lab] = k
                    continue  # Surface 23: a later-line prefix covers that line alone
                lm = LABEL.match(s)
                if not lm:
                    add(k, "F-unlabelled", f"unprefixed line in a normative block is not a rule: {s[:80]}")
                    continue
                lab, body = lm.group(1), lm.group(2)
                parts = LABEL_PARTS.match(lab)
                if parts:
                    name = parts.group("name")
                    heading = " ".join(str(ctx[k] or "") for k in ("h2", "h3", "h4", "bullet", "italic"))
                    hw = _words(heading)
                    missing = [w for w in _words(name) if not _matches(w, hw)]
                    if missing:
                        add(k, "R-label-heading", f"{lab}: the label's name is not the heading it sits under ({', '.join(missing)}) (Rule shape 7)")
                    if any(re.fullmatch(r"[A-Z]{2,3}", w) and w != "WHEN" for w in name.split()):
                        add(k, "R-label-abbrev", f"{lab}: an abbreviation in a label (Rule shape 8)")
                    if parts.group("major") and name == "Invariant" and ctx["inv"] and parts.group("major") != ctx["inv"]:
                        add(k, "R-label-heading", f"{lab}: sits under Invariant {ctx['inv']} (Rule shape 7)")
                    if parts.group("step") and ctx["step"] and fence_indent > 0 and parts.group("step") != ctx["step"]:
                        add(k, "R-label-heading", f"{lab}: sits under step {ctx['step']} (Rule shape 7)")
                if lab in labels:
                    add(k, "L-dup-label", f"label {lab} already used at line {labels[lab]}")
                labels[lab] = k
                # WHEN children: indented under a WHEN parent, labelled parent + letter
                while stack and indent <= stack[-1].indent:
                    stack.pop()
                parent = stack[-1] if stack else None
                rule = Rule(k, lab, body, indent, parent.label if parent else None)
                rules.append(rule)
                if parent:
                    if not re.match(r"^" + re.escape(parent.label) + r"[a-z]$", lab):
                        add(k, "R-child-label", f"child of {parent.label} carries label {lab}")
                    if body.startswith("WHEN "):
                        add(k, "R-nested-when", f"{lab}: a WHEN block inside a WHEN block (Hard invariant 6)")
                if body.startswith("WHEN "):
                    stack.append(rule)
            # WHEN with no children
            for r in rules:
                if r.line >= start and r.text.startswith("WHEN ") and not any(x.parent == r.label for x in rules):
                    add(r.line, "R-when-empty", f"{r.label}: WHEN block with no child rule")
        else:
            add(start, "F-fence-first", f"fenced block's first line is neither a labelled rule nor a surface prefix (Surface 19): {first[:80]}")
        i = j + 1

    # tombstone reuse (Hard invariant 25, Hard invariant 27)
    for lab, k in tombstones.items():
        if lab in labels:
            add(labels[lab], "L-tombstone-reuse", f"{lab} is tombstoned at line {k} and used as a rule (Hard invariant 27)")

    verbs = declared_verbs(text)
    for r in rules:
        body = CODE_SPAN.sub("QUOTED", r.text)  # a code span quotes text; never the rule's own tokens
        if body.startswith("PROVISIONAL:"):
            continue  # Surface 14: no normative force; not shape-checked
        if body.startswith("WHEN "):
            if not body.endswith(":"):
                add(r.line, "R-when-colon", f"{r.label}: WHEN condition must end with a colon")
            cond = body[5:].rstrip(":")
            if " AND " in cond and " OR " in cond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
            continue
        stmt = body
        cond = ""
        if body.startswith("IF "):
            im = re.match(r"^IF (.*?) THEN (.*)$", body)
            if not im:
                add(r.line, "R-if-then", f"{r.label}: IF without THEN")
                continue
            cond, stmt = im.groups()
            if " AND " in cond and " OR " in cond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
        if " IS AUTHORITATIVE FOR " in stmt:
            continue  # Authority 1 shape; carries no modal (outside Closed vocabulary 8)
        mm = MODAL.search(stmt)
        if not mm:
            add(r.line, "R-no-modal", f"{r.label}: no modal and no IS AUTHORITATIVE FOR — a definitional sentence is a declaration (Closed vocabulary 14): {stmt[:80]}")
            continue
        obligation = stmt
        tail = re.search(r"\bONLY IF\b(.*)$", stmt)
        if tail:
            obligation = stmt[: tail.start()]
            tcond = tail.group(1)
            if " AND " in tcond and " OR " in tcond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
        if re.search(r"\bOR\b", obligation) and "EXACTLY ONE OF" not in obligation:
            add(r.line, "V-or-obligation", f"{r.label}: OR outside a condition (Hard invariant 8)")
        if re.search(r"\bor\b", obligation):
            add(r.line, "W-or-word", f"{r.label}: 'or' inside an obligation — an enumeration the parser cannot read (Earned vocabulary 3)")
        if re.search(r"\bMUST (?!NOT\b)[^.]*\bBEFORE\b", stmt) or re.search(r"\bMAY\b[^.]*\bBEFORE\b", stmt):
            add(r.line, "B-before", f"{r.label}: positive MUST/MAY … BEFORE (Timing 6, Hard invariant 11)")
        if re.search(r"\bAFTER\b", stmt) and not re.search(r"\bONLY AFTER\b", stmt):
            if re.search(r"\bMUST NOT\b", stmt):
                add(r.line, "B-after", f"{r.label}: AFTER under MUST NOT (Timing 4)")
            # under MUST / MAY it is the deterministic sugar (Timing 2, Timing 3)
        if re.search(r"\bAT LEAST\b|\bSTRICTLY\b", stmt):
            add(r.line, "B-banned", f"{r.label}: AT LEAST / STRICTLY (Timing 10, Timing 11)")
        if re.search(r"\bMUST EXCEED\b|\bMAY EXCEED\b", stmt):
            add(r.line, "B-exceed", f"{r.label}: ≥ is written MUST NOT EXCEED (Timing 9)")
        if ARITH.search(stmt) or ARITH.search(cond):
            add(r.line, "A-arith", f"{r.label}: arithmetic in a rule; name a term (Hard invariant 24, Closed vocabulary 9)")
        if PRONOUN.search(stmt) or PRONOUN.search(cond):
            add(r.line, "P-pronoun", f"{r.label}: pronoun in a rule (Hard invariant 4)")
        if re.search(r"\b(MUST NOT|MUST|MAY)\s+(be|is|are|been|being)\b", stmt):
            add(r.line, "C-copula", f"{r.label}: copula after the modal — no declared record verb (Closed vocabulary 8)")
        if re.search(r"\b(until|while|unless)\b", stmt) or re.search(r"\b(after|before)\b", stmt):
            add(r.line, "W-watch-word", f"{r.label}: lower-case after/before/until/while/unless — an ordering or duration the tails do not carry (§18 watch list)")
        if verbs is not None:
            for vm in re.finditer(r"\b(MUST NOT|MUST|MAY)\s+(\S+)", stmt):
                v = vm.group(2).strip(",.;:")
                if v in RESERVED_VERBS or v.startswith("("):
                    continue
                if v not in verbs:
                    add(r.line, "C-verb", f"{r.label}: '{v}' after the modal is not a declared record verb (Closed vocabulary 8)")
        # a [Marker] that is not a term card — a bracket range read as a marker
        for mk in MARKER.findall(stmt):
            if not re.match(r"^[A-Z][A-Za-z ]+$", mk):
                add(r.line, "F-bracket", f"{r.label}: '[{mk}]' in a rule reads as a term marker; write the range in a term")

    # cross-rule references to labels no rule carries (Hard invariant 12) — names used by this spec's labels only
    names: set[str] = set()
    groups: set[str] = set()
    for lab in list(labels) + list(tombstones):
        parts = LABEL_PARTS.match(lab)
        if not parts:
            continue
        names.add(parts.group("name"))
        if parts.group("major"):
            groups.add(f"{parts.group('name')} {parts.group('major')}")
        if parts.group("step"):
            groups.add(f"{parts.group('name')} step {parts.group('step')}")
    if names:
        name_re = re.compile(r"(?<![\w-])(" + "|".join(re.escape(x) for x in sorted(names, key=len, reverse=True)) +
                             r")( step [\d½]+(?:\.\d+[a-z]?)?| \d+(?:\.\d+)?[a-z]?)(?![\w.]\d)")
        seen: set[str] = set()
        for k, raw in enumerate(lines, start=1):
            if TERM_DECL.match(raw):
                continue
            for fm in name_re.finditer(raw):
                ref = fm.group(1) + fm.group(2)
                before = raw[:fm.start()]
                if re.search(r"[A-Z][\w'’]*\s$", before) and fm.group(1) in ("Invariant", "Check"):
                    continue  # another spec's invariant or check, cited by the corpus form
                if ref in labels or ref in tombstones or ref in exemplars or ref in groups or ref in seen:
                    continue
                seen.add(ref)
                add(k, "X-ref", f"reference to {ref}, which no rule in this spec carries (Hard invariant 12)")

    # what a declaration carries: an obligation, or a name that resolves nowhere
    decls = declared_terms(text)
    # every name the spec declares anywhere: a Terms › name, a name inside a
    # vocabulary declaration (the records, bounds, cadences and value-set
    # lines), a signature block's action and argument names.
    CATEGORIES = {"actors", "records", "record verbs", "value sets", "bounds",
                  "cadences", "terms", "qualifiers", "composing patterns", "cited"}
    universe = set(decls)
    for name in decls:
        universe.update(DECL_TOKEN.findall(name))
    # a name a constituent owns is cited, never redeclared (Closed vocabulary
    # 15-17): a token the spec uses as a code span elsewhere is a name, and
    # this checker resolves no cross-spec registry
    for line in lines:
        if TERM_DECL.match(line):
            continue
        for span in re.findall(r"`([^`]+)`", line):
            if DECL_TOKEN.fullmatch(span):
                universe.add(span)
    for line in lines:
        m = TERM_DECL.match(line)
        if m and m.group(1) in CATEGORIES:
            universe.update(x for span in re.findall(r"`([^`]+)`", m.group(2))
                            for x in DECL_TOKEN.findall(span))
        sm = re.match(r"^([a-z_][a-z0-9_]*)\(([^)]*)\)\s*(?:→|->)(.*)$", line.strip())
        if sm:
            universe.add(sm.group(1))
            universe.update(DECL_TOKEN.findall(sm.group(2)))
            universe.update(DECL_TOKEN.findall(sm.group(3)))
    for name, k in decls.items():
        body = TERM_DECL.match(lines[k - 1]).group(2)
        bare = CODE_SPAN.sub(" ", body)
        if MODAL.search(bare):
            add(k, "D-decl-modal",
                f"Terms › `{name}` carries a modal — a definition is not a rule "
                f"(Closed vocabulary 12, Closed vocabulary 14)")
        for span in re.findall(r"`([^`]+)`", body):
            if not DECL_ARITH.search(span):
                continue
            if re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", span):
                add(k, "D-decl-selfref", f"Terms › `{name}` computes over `{name}`")
                continue
            for ident in DECL_TOKEN.findall(span):
                # a datum this corpus would declare looks like a datum: prose
                # inside a code span, and a bare English word, are neither
                if ident in DECL_SKIP or "_" not in ident:
                    continue
                if ident not in universe:
                    add(k, "D-decl-unresolved",
                        f"Terms › `{name}` computes over `{ident}`, which this spec declares nowhere "
                        f"(Closed vocabulary 4)")

    # an action the spec declares and no rule names (advisory): a signature
    # block is a declaration, and a declaration nothing uses is a loose end
    if signatures:
        named = set()
        for r in rules:
            for m in MARKER.finditer(r.text):
                named.add(m.group(1).strip().lower().replace(" ", "_"))
            for m in re.finditer(r"\b([a-z_][a-z0-9_]*)\b", r.text):
                named.add(m.group(1))
        for k, action in signatures:
            if action.strip() not in named:
                add(k, "S-action-unused",
                    f"`{action.strip()}` is declared in a signature block and no rule names it "
                    f"(Closed vocabulary 20)")

    # a check that names no rule (advisory): the auditor is the last reader
    # nobody audits, and a check whose failure nobody can state passes forever
    if names:
        for label, line_no in [(r.label, r.line) for r in rules]:
            parts = LABEL_PARTS.match(label)
            if not parts or parts.group("name") not in ("Check", "External check"):
                continue
            text_of_rule = next((r.text for r in rules if r.label == label), "")
            if not name_re.search(text_of_rule):
                add(line_no, "K-check-bare",
                    f"{label} names no rule — a check whose failure nobody can state (CR-8)")

    # declared terms nothing uses (advisory)
    for name, k in declared_terms(text).items():
        if name in {"actors", "records", "record verbs", "cited", "value sets", "bounds", "cadences", "qualifiers", "terms", "composing patterns"}:
            continue  # the vocabulary's own categories (Closed vocabulary 1, Closed vocabulary 2)
        pat = re.escape(name)
        # a declaration that mentions its own name is not a use of it
        elsewhere = "\n".join(x for j, x in enumerate(lines, start=1) if j != k)
        uses = len(re.findall(pat, elsewhere))
        if uses < 1:
            add(k, "W-term-unused", f"Terms › `{name}` is declared and used nowhere")
    return findings


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    gate = "--gate" in argv
    root = Path(__file__).resolve().parents[2]
    if args:
        paths = [Path(a) for a in args]
    else:
        paths = [root / "GRACE-lang.md"]
        for d in ("atoms", "compositions"):
            for p in sorted((root / d).glob("*.md")):
                # a spec declares itself migrated; a stray fence is not a claim
                if MIGRATED.search(p.read_text(encoding="utf-8")):
                    paths.append(p)
    findings: list[Finding] = []
    for p in paths:
        if p.exists():
            findings += scan(p)
    findings.sort(key=lambda f: (str(f.path), f.line, f.code))
    for f in findings:
        try:
            rel = f.path.resolve().relative_to(root)
        except ValueError:
            rel = f.path
        tag = " (advisory)" if f.code in ADVISORY else ""
        print(f"{rel}:{f.line}: [{f.code}]{tag} {f.message}")
    gating = [f for f in findings if f.code not in ADVISORY]
    advisory = [f for f in findings if f.code in ADVISORY]
    print(f"\n— {len(paths)} file(s); {len(gating)} finding(s) + {len(advisory)} advisory.", file=sys.stderr)
    return 1 if (gate and gating) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

#!/usr/bin/env python3
"""GRACE lang surface checker — the mechanical slice of `GRACE-lang.md`.

Reads a spec's normative surface the way §2 and §17 of the grammar say a parser
must — a fenced ```text block classified by its first line, `Terms ›`
declarations — and reports what a form-reader can decide without semantics:
fence classification (S17, S17a) and signature blocks (S17b), unlabelled lines (I1, U3), label uniqueness
and tombstone reuse (I25, I27), the rule form and the statement shapes (R1, R2,
R6, I2, I3), WHEN blocks (W3, I7), mixed AND/OR and OR outside a condition (I8,
I9), BEFORE and AFTER outside their admitted places (I10–I12), the banned
words (B10, B11), arithmetic in a rule (I24), pronouns (I5), the copula after
a modal (C7, C12), the record verb after the modal against the declared
vocabulary (C7), a declared term nothing uses, and a cross-rule reference to a
label no rule carries (I13).

Standard library only. `python3 tools/grace/check.py [paths...]`; with no path
it reads GRACE-lang.md and every file under atoms/ and compositions/ that
carries a ```text fence. Prints one finding per line, `path:line: [CODE] message`.
Non-gating by default: exits 0 whatever it finds; `--gate` exits 1 on any
finding that is not advisory (the W- codes).

What it does not do: resolve every identifier (C3), parse value sets against
conditions (I14), or normalize (§16). Those need the parser this is the
forerunner of.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

LABEL = re.compile(r"^([A-Z]{1,3}\d+[a-z]?\d?):\s*(.*)$")
PREFIX = re.compile(r"^(WHY|NOTE|UX|PROVISIONAL):")
FENCE = re.compile(r"^(\s*)```(\w*)\s*$")
TERM_DECL = re.compile(r"^\s*Terms › `([^`]+)`:\s*(.*)$")
MODAL = re.compile(r"\b(MUST NOT|MUST|MAY)\b")
TOMBSTONE = re.compile(r"^NOTE:\s*([A-Z]{1,3}\d+[a-z]?\d?)\s+deleted\b")
PRONOUN = re.compile(r"\b(it|its|itself|they|their|them|he|she|his|her)\b")
ARITH = re.compile(r"[+×−]|\s-\s")
MARKER = re.compile(r"\[([^\]\[]+)\]")
CODE_SPAN = re.compile(r"`[^`]*`")
SIGNATURE = re.compile(r"^[a-z_][a-z0-9_]*\(")
ADVISORY = {"W-or-word", "W-watch-word", "W-term-unused", "W-lowercase-after"}
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

    i = 0
    n = len(lines)
    while i < n:
        m = FENCE.match(lines[i])
        if not m:
            i += 1
            continue
        if m.group(2) != "text":
            # S17b/S17c: a bare fence opening with a signature line is a signature block; any other fence is nothing
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
                signatures.append((k, head.split("(")[0]))
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
        # S17: classify by the first non-blank line
        first = next((b.strip() for b in block if b.strip()), "")
        if not first:
            add(start, "F-fence-empty", "empty ```text fence")
        elif PREFIX.match(first):
            # S18: the prefix covers the whole block — not normative; labels inside are exemplars
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
                    continue  # S18a: a later-line prefix covers that line alone
                lm = LABEL.match(s)
                if not lm:
                    add(k, "F-unlabelled", f"unprefixed line in a normative block is not a rule: {s[:80]}")
                    continue
                lab, body = lm.group(1), lm.group(2)
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
                    if not re.match(r"^" + re.escape(parent.label) + r"[a-z]\d?$", lab):
                        add(k, "R-child-label", f"child of {parent.label} carries label {lab}")
                    if body.startswith("WHEN "):
                        add(k, "R-nested-when", f"{lab}: a WHEN block inside a WHEN block (I7)")
                if body.startswith("WHEN "):
                    stack.append(rule)
            # WHEN with no children
            for r in rules:
                if r.line >= start and r.text.startswith("WHEN ") and not any(x.parent == r.label for x in rules):
                    add(r.line, "R-when-empty", f"{r.label}: WHEN block with no child rule")
        else:
            add(start, "F-fence-first", f"fenced block's first line is neither a labelled rule nor a surface prefix (S17a): {first[:80]}")
        i = j + 1

    # tombstone reuse (I25, I27)
    for lab, k in tombstones.items():
        if lab in labels:
            add(labels[lab], "L-tombstone-reuse", f"{lab} is tombstoned at line {k} and used as a rule (I27)")

    verbs = declared_verbs(text)
    for r in rules:
        body = CODE_SPAN.sub("QUOTED", r.text)  # a code span quotes text; never the rule's own tokens
        if body.startswith("PROVISIONAL:"):
            continue  # S13: no normative force; not shape-checked
        if body.startswith("WHEN "):
            if not body.endswith(":"):
                add(r.line, "R-when-colon", f"{r.label}: WHEN condition must end with a colon")
            cond = body[5:].rstrip(":")
            if " AND " in cond and " OR " in cond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (I8)")
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
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (I8)")
        if " IS AUTHORITATIVE FOR " in stmt:
            continue  # A1 shape; carries no modal (outside C7)
        mm = MODAL.search(stmt)
        if not mm:
            add(r.line, "R-no-modal", f"{r.label}: no modal and no IS AUTHORITATIVE FOR — a definitional sentence is a declaration (C12): {stmt[:80]}")
            continue
        obligation = stmt
        tail = re.search(r"\bONLY IF\b(.*)$", stmt)
        if tail:
            obligation = stmt[: tail.start()]
            tcond = tail.group(1)
            if " AND " in tcond and " OR " in tcond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (I8)")
        if re.search(r"\bOR\b", obligation) and "EXACTLY ONE OF" not in obligation:
            add(r.line, "V-or-obligation", f"{r.label}: OR outside a condition (I9)")
        if re.search(r"\bor\b", obligation):
            add(r.line, "W-or-word", f"{r.label}: 'or' inside an obligation — an enumeration the parser cannot read (V3)")
        if re.search(r"\bMUST (?!NOT\b)[^.]*\bBEFORE\b", stmt) or re.search(r"\bMAY\b[^.]*\bBEFORE\b", stmt):
            add(r.line, "B-before", f"{r.label}: positive MUST/MAY … BEFORE (B6, I12)")
        if re.search(r"\bAFTER\b", stmt) and not re.search(r"\bONLY AFTER\b", stmt):
            if re.search(r"\bMUST NOT\b", stmt):
                add(r.line, "B-after", f"{r.label}: AFTER under MUST NOT (B4)")
            # under MUST / MAY it is the deterministic sugar (B2, B3)
        if re.search(r"\bAT LEAST\b|\bSTRICTLY\b", stmt):
            add(r.line, "B-banned", f"{r.label}: AT LEAST / STRICTLY (B10, B11)")
        if re.search(r"\bMUST EXCEED\b|\bMAY EXCEED\b", stmt):
            add(r.line, "B-exceed", f"{r.label}: ≥ is written MUST NOT EXCEED (B9)")
        if ARITH.search(stmt) or ARITH.search(cond):
            add(r.line, "A-arith", f"{r.label}: arithmetic in a rule; name a term (I24, C8)")
        if PRONOUN.search(stmt) or PRONOUN.search(cond):
            add(r.line, "P-pronoun", f"{r.label}: pronoun in a rule (I5)")
        if re.search(r"\b(MUST NOT|MUST|MAY)\s+(be|is|are|been|being)\b", stmt):
            add(r.line, "C-copula", f"{r.label}: copula after the modal — no declared record verb (C7)")
        if re.search(r"\b(until|while|unless)\b", stmt) or re.search(r"\b(after|before)\b", stmt):
            add(r.line, "W-watch-word", f"{r.label}: lower-case after/before/until/while/unless — an ordering or duration the tails do not carry (§18 watch list)")
        if verbs is not None:
            for vm in re.finditer(r"\b(MUST NOT|MUST|MAY)\s+(\S+)", stmt):
                v = vm.group(2).strip(",.;:")
                if v in RESERVED_VERBS or v.startswith("("):
                    continue
                if v not in verbs:
                    add(r.line, "C-verb", f"{r.label}: '{v}' after the modal is not a declared record verb (C7)")
        # a [Marker] that is not a term card — a bracket range read as a marker
        for mk in MARKER.findall(stmt):
            if not re.match(r"^[A-Z][A-Za-z ]+$", mk):
                add(r.line, "F-bracket", f"{r.label}: '[{mk}]' in a rule reads as a term marker; write the range in a term")

    # a NOTE declaring labels never used reserves them like a tombstone (a gap is not a deletion)
    reserved: set[str] = set()
    for raw in lines:
        s = raw.strip()
        if s.startswith("NOTE:") and re.search(r"\bnever (?:used|carried)\b", s):
            for a, b in re.findall(r"\b([A-Z]{1,3}\d+)(?:–([A-Z]{1,3}\d+))?\b", s):
                if b:
                    fa, na = re.match(r"([A-Z]+)(\d+)", a).groups()
                    fb, nb = re.match(r"([A-Z]+)(\d+)", b).groups()
                    if fa == fb:
                        reserved.update(f"{fa}{k}" for k in range(int(na), int(nb) + 1))
                reserved.add(a)
    # cross-rule references to labels no rule carries (I13) — families present in this file only
    families = {re.match(r"^[A-Z]+", lab).group(0) for lab in list(labels) + list(tombstones)}
    if families:
        fam_re = re.compile(r"\b(" + "|".join(sorted(families, key=len, reverse=True)) + r")(\d+[a-z]?\d?)\b")
        seen: set[str] = set()
        for k, raw in enumerate(lines, start=1):
            # skip code spans and fenced non-text? references count everywhere; the labels are the same namespace
            for fm in fam_re.finditer(raw):
                lab = fm.group(1) + fm.group(2)
                if lab in labels or lab in tombstones or lab in exemplars or lab in reserved or lab in seen:
                    continue
                # ranges like RA25–RA47 are two labels; both are matched separately
                seen.add(lab)
                add(k, "X-ref", f"reference to {lab}, which no rule in this spec carries (I13)")

    # declared terms nothing uses (advisory)
    for name, k in declared_terms(text).items():
        pat = re.escape(name)
        uses = len(re.findall(pat, text))
        if uses <= 1:
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
                if "```text" in p.read_text(encoding="utf-8"):
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

#!/usr/bin/env python3
"""The normalizer: every labelled rule lowered to its normalized form.

GRACE-lang section 16 obliges the parser to lower every parsed rule to an
explicit structural representation, carrying only what the normative source
states or a ratified deterministic sugar rewrite adds (Normalized form 1 and
2), and nothing from WHY:, UX:, NOTE: or PROVISIONAL: (Normalized form 3).
ir.py reads each rule as labelled text; this module lowers that text. It reads
the grammar's sections 5, 8, 9 and 12:

  * the statement shape (section 5): `[IF condition THEN] [quantifier] subject
    modal act object tails`, or `subject IS AUTHORITATIVE FOR proposition`, or
    `WHEN condition:` over indented children;
  * the condition (section 5, Earned vocabulary 6 to 12): `AND` or `OR`, never
    both, each clause one of EQUALS, DOES NOT EQUAL, EXCEEDS, DOES NOT EXCEED,
    PRECEDES, DOES NOT PRECEDE, IS IN, IS NOT IN, EXISTS and its absence form
    `no thing EXISTS` (Hard invariant 33), or a predicate the spec's own verbs
    carry;
  * the timing tails (section 8): `ONLY AFTER`, `BEFORE`, `WITHIN`, `PER`; and
    the gates `ONLY IF` and `ONLY UNDER`;
  * the WHEN block (section 9): each child an independent rule that carries
    the block's condition;
  * the sugar (section 12): `AFTER` under `MUST` or `MAY` is `ONLY AFTER`
    (Timing 2, Timing 3). A rule carries no arithmetic (Closed vocabulary 9,
    v0.70): a parenthesized group carrying an arithmetic operator leaves the
    rule unlowered, since the value belongs in a declared term.

The form is the same whatever the order of the rules or the order of a rule's
tails (Hard invariant 15), exclusive only where `EXACTLY ONE OF` states it
(Hard invariant 17), and written back with `render()` lowers to itself, so the
sugar adds no meaning and each sugar form has one canonical form (Hard
invariant 18 and 19). WHY:, UX:, NOTE: and PROVISIONAL: lines are never rules
and never enter it (Hard invariant 21 through 23); a rule whose body opens with one
of those prefixes is lowered to `excluded`, carrying nothing of the line.

A rule the normalizer cannot lower is an advisory finding, `N-unlowered`, with
the form it could not read, and is carried in the IR as `unlowered` with its
text as written, so the reverse diff never assumes it equivalent to anything
else (Reverse diff 4). Two more advisory checks read the normalized form:
`N-ordinal-ref`, a cross-rule reference by ordinal (Hard invariant 13), and
`N-value-set`, an EQUALS or DOES NOT EQUAL value in a condition that belongs to
no closed value set the spec or a constituent declares (Hard invariant 14).
Nothing here gates: `check.py --gate` and `ir.py --check` are unchanged.

    python3 tools/grace/normalize.py                  # every spec's advisory findings and the count
    python3 tools/grace/normalize.py atoms/cart.md    # one spec's normalized form, printed

Standard library only. One finding per line, `path:line: [CODE] message`; the
exit is 0, since the findings are advisory.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import check  # noqa: E402

# the shape of the normalized form; a change a reader of it must know about moves it
NORMAL_VERSION = 1

MODAL = re.compile(r"\b(MUST NOT|MUST|MAY)\b")
COMPOUND = re.compile(r",? AND (?=(?:MUST NOT|MUST|MAY) )")
TAIL = re.compile(r" (ONLY AFTER|ONLY IF|ONLY UNDER|AFTER|BEFORE|WITHIN|PER) ")
TIMING_ORDER = ("ONLY AFTER", "BEFORE", "WITHIN", "PER")
EXCLUSIVE = re.compile(r"(?:^| )EXACTLY ONE OF ")
QUANTIFIER = re.compile(r"^(EVERY|EXACTLY ONE) (.+)$")
AUTHORITY = " IS AUTHORITATIVE FOR "
WHEN_RULE = re.compile(r"^WHEN (.+):$")
CITED = re.compile(r" \(([^()]*\d[^()]*)\)$")
BARE_VALUE = re.compile(r"^[a-z][a-z0-9_-]*$")
OPERATORS = (  # longest first: `DOES NOT EQUAL` before `EQUALS`
    ("DOES NOT EQUAL", re.compile(r"^(.+?) DOES NOT EQUAL (.+)$")),
    ("EQUALS", re.compile(r"^(.+?) EQUALS (.+)$")),
    ("DOES NOT EXCEED", re.compile(r"^(.+?) DOES NOT EXCEED (.+)$")),
    ("EXCEEDS", re.compile(r"^(.+?) EXCEEDS (.+)$")),
    ("DOES NOT PRECEDE", re.compile(r"^(.+?) DOES NOT PRECEDE (.+)$")),
    ("PRECEDES", re.compile(r"^(.+?) PRECEDES (.+)$")),
    ("IS NOT IN", re.compile(r"^(.+?) IS NOT IN (.+)$")),
    ("IS IN", re.compile(r"^(.+?) IS IN (.+)$")),
)
PRESENCE = re.compile(r"^(no )?(.+?) EXISTS\b ?(.*)$")
ORDINAL_REF = re.compile(
    r"\b(?:(?:the|a) )?(?:previous|preceding|prior|next|following) (?:rule|line)s?\b|"
    r"\b(?:rule|line)s? (?:above|below)\b|\b(?:rule|line) \d+(?![\d(])\b|\b\d+(?:st|nd|rd|th) (?:rule|line)\b")
# the values the grammar and the Execution Contract declare for every spec
GRAMMAR_VALUES = {"blank"}
NUMBER_WORDS = {"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}


def mask(text: str) -> str:
    """The text with each parenthesis, bracket and code span blanked out to a
    NUL of the same length, so a keyword inside one is no keyword and every
    index into the mask is an index into the text."""
    out, depth, tick = [], 0, False
    for ch in text:
        if ch == "`":
            tick = not tick
            out.append("\0")
        elif tick or depth:
            out.append("\0")
            depth += (ch in "([") - (ch in ")]")
        elif ch in "([":
            depth += 1
            out.append("\0")
        else:
            out.append(ch)
    return "".join(out)


def squeeze(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def lower_arithmetic(text: str) -> list[str]:
    """Why the text cannot be lowered for its arithmetic: each parenthesized
    group that carries an arithmetic operator is arithmetic in a rule, which
    the grammar deleted at v0.70 (Closed vocabulary 9; Sugar 4 through 12 and
    Hard invariant 24 deleted to Closed vocabulary 31 through 34 and Hard
    invariant 35 through 37)."""
    problems = []
    depth = start = 0
    for i, ch in enumerate(text):
        if ch == "(":
            if depth == 0:
                start = i
            depth += 1
        elif ch == ")" and depth:
            depth -= 1
            group = text[start + 1:i]
            if depth or not check.ARITH_GROUP.search(group):
                continue
            problems.append(f"the group ({group}) is arithmetic in a rule; a rule names a declared term")
    return problems


def split_top(text: str, sep: re.Pattern | str) -> list[str]:
    """Cut the text at each match of `sep` outside a parenthesis, bracket or
    code span."""
    rx = re.compile(sep) if isinstance(sep, str) else sep
    masked, parts, at = mask(text), [], 0
    for m in rx.finditer(masked):
        parts.append(text[at:m.start()])
        at = m.end()
    return parts + [text[at:]]


def lower_clause(text: str) -> dict:
    """One condition clause: the text as written and what it says, an operator
    comparison, a thing's presence or absence (`no thing EXISTS`, Hard
    invariant 33), or a predicate the spec's own verbs carry."""
    text = squeeze(text)
    masked = mask(text)
    for op, rx in OPERATORS:
        m = rx.match(masked)
        if m:
            return {"text": text, "kind": "comparison", "op": op,
                    "left": text[m.start(1):m.end(1)], "right": text[m.start(2):m.end(2)]}
    m = PRESENCE.match(masked)
    if m:
        thing = text[m.start(2):m.end(2)]
        return {"text": text, "kind": "absence" if m.group(1) else "presence", "thing": thing,
                "qualifier": text[m.start(3):m.end(3)]}
    return {"text": text, "kind": "predicate"}


def lower_condition(text: str, problems: list[str]) -> dict:
    """A condition: its clauses joined by `AND` or by `OR`, never both (Hard
    invariant 7)."""
    text = squeeze(text)
    ands, ors = split_top(text, " AND "), split_top(text, " OR ")
    if len(ands) > 1 and len(ors) > 1:
        problems.append(f"a condition mixes AND and OR: {text}")
    join, parts = ("OR", ors) if len(ors) > 1 and len(ands) == 1 else ("AND", ands)
    clauses = [lower_clause(p) for p in parts if p.strip()]
    if not clauses:
        problems.append("a condition with no clause")
    return {"join": join, "clauses": clauses}


def lower_obligation(chunk: str, problems: list[str]) -> dict | None:
    """One obligation: a modal, the act and its object, the timing tails and
    the gates. `AFTER` is `ONLY AFTER` under MUST and MAY (Timing 2, Timing 3)."""
    m = MODAL.match(chunk)
    if not m:
        problems.append(f"no modal opens the obligation: {chunk}")
        return None
    modal, rest = m.group(1), chunk[m.end():].strip()
    pieces, masked = [], mask(rest)
    cuts = [(t.start(), t.end(), t.group(1)) for t in TAIL.finditer(masked)]
    head = rest[:cuts[0][0]] if cuts else rest
    for i, (_, end, kind) in enumerate(cuts):
        stop = cuts[i + 1][0] if i + 1 < len(cuts) else len(rest)
        pieces.append((kind, squeeze(rest[end:stop])))
    cited = ""
    tail_text = pieces[-1][1] if pieces else head
    c = CITED.search(tail_text)
    if c:
        cited = c.group(1)
        if pieces:
            pieces[-1] = (pieces[-1][0], tail_text[:c.start()].strip())
        else:
            head = tail_text[:c.start()]
    head = squeeze(head)
    obligation: dict = {"modal": modal}
    ex = EXCLUSIVE.search(mask(head))
    lead = head
    if ex:
        members = [squeeze(x) for x in split_top(head[ex.end():], ", ") if x.strip()]
        lead = head[:ex.start()].strip()
        obligation["exclusive"] = members
    act, _, obj = lead.partition(" ")
    if not act:
        problems.append(f"the obligation names no act: {chunk}")
    obligation["act"], obligation["object"] = act, obj.strip()
    timing, only_if, only_under = [], [], []
    for kind, term in pieces:
        if not term:
            problems.append(f"{kind} names no term: {chunk}")
            continue
        if kind == "AFTER":
            if modal == "MUST NOT":
                problems.append(f"AFTER under MUST NOT: {chunk}")
                continue
            kind = "ONLY AFTER"
        elif kind == "BEFORE" and modal != "MUST NOT":
            problems.append(f"a positive {modal} ... BEFORE ordering: {chunk}")
            continue
        if kind == "ONLY IF":
            only_if.append(lower_condition(term, problems))
        elif kind == "ONLY UNDER":
            only_under.append(lower_condition(term, problems))
        else:
            timing.append({"kind": kind, "term": term})
    obligation["timing"] = sorted(timing, key=lambda t: TIMING_ORDER.index(t["kind"]))
    if only_if:
        obligation["only_if"] = only_if
    if only_under:
        obligation["only_under"] = only_under
    if cited:
        obligation["cited"] = cited
    return obligation


def lower_statement(text: str) -> tuple[dict, list[str]]:
    """The form of one rule's statement, WHEN context apart, and why any part
    could not be read. A statement that cannot be lowered is `unlowered`."""
    problems: list[str] = []
    text = squeeze(text)
    written = text[:-1] if text.endswith(".") else text
    text = written
    m = check.PREFIX.match(text)
    if m:
        return {"kind": "excluded", "prefix": m.group(1)}, []
    problems += lower_arithmetic(text)
    m = WHEN_RULE.match(text)
    if m:
        return {"kind": "when", "condition": lower_condition(m.group(1), problems)}, problems
    form: dict = {"kind": "rule"}
    masked = mask(text)
    cut = masked.find(" THEN ")
    start = masked.rfind("IF ", 0, cut) if cut >= 0 else -1
    if cut >= 0 and start >= 0 and (start == 0 or masked[start - 1] == " "):
        pre = squeeze(text[:start]).rstrip(",").strip()
        if pre:
            form["scope"] = pre
        form["if"] = lower_condition(text[start + 3:cut], problems)
        text = text[cut + len(" THEN "):].strip()
    elif re.match(r"^IF ", masked) or " THEN " in masked:
        problems.append(f"IF and THEN do not pair: {text}")
    masked = mask(text)
    at = masked.find(AUTHORITY)
    if at >= 0:
        form["kind"] = "authority"
        form["subject"], form["proposition"] = squeeze(text[:at]), squeeze(text[at + len(AUTHORITY):])
        if not form["subject"] or not form["proposition"]:
            problems.append(f"IS AUTHORITATIVE FOR lacks a side: {text}")
    else:
        chunks = split_top(text, COMPOUND)
        first = MODAL.search(mask(chunks[0]))
        if not first:
            problems.append(f"no modal: {text}")
        else:
            subject = squeeze(chunks[0][:first.start()])
            q = QUANTIFIER.match(subject)
            if q:
                form["quantifier"], subject = q.group(1), q.group(2)
            if not subject:
                problems.append(f"no subject: {text}")
            form["subject"] = subject
            chunks[0] = chunks[0][first.start():]
            obligations = [lower_obligation(squeeze(c), problems) for c in chunks]
            form["obligations"] = [o for o in obligations if o]
    if problems:
        return {"kind": "unlowered", "text": written}, problems
    return form, problems


def render_group(group: dict) -> str:
    return f" {group['join']} ".join(c["text"] for c in group["clauses"])


def render(form: dict) -> str:
    """The canonical text a form lowers to: lowering it again gives the form,
    so the sugar adds nothing and each sugar form has one spelling."""
    kind = form["kind"]
    if kind == "excluded":
        return form["prefix"] + ":"
    if kind == "unlowered":
        return form["text"] + "."
    if kind == "when":
        return f"WHEN {render_group(form['condition'])}:"
    head = (form["scope"] + ", " if "scope" in form else "") + \
           (f"IF {render_group(form['if'])} THEN " if "if" in form else "")
    if kind == "authority":
        return f"{head}{form['subject']}{AUTHORITY}{form['proposition']}."
    subject = (form.get("quantifier", "") + " " + form["subject"]).strip()
    obligations = []
    for o in form["obligations"]:
        s = f"{o['modal']} {o['act']}"
        if o["object"]:
            s += " " + o["object"]
        if "exclusive" in o:
            s += " EXACTLY ONE OF " + ", ".join(o["exclusive"])
        for t in o["timing"]:
            s += f" {t['kind']} {t['term']}"
        for k, groups in (("ONLY IF", o.get("only_if", [])), ("ONLY UNDER", o.get("only_under", []))):
            for g in groups:
                s += f" {k} {render_group(g)}"
        if "cited" in o:
            s += f" ({o['cited']})"
        obligations.append(s)
    return f"{head}{subject} {' AND '.join(obligations)}."


def lower_rules(rules: list[dict]) -> tuple[dict[str, dict], list[tuple[dict, str]]]:
    """Every labelled rule's form, by label and in label order, so the order
    the rules are read in is not in it (Hard invariant 15); and each rule that
    could not be lowered with the form it could not read. A WHEN block's child
    carries the block's condition as `when` and the block lists its children."""
    forms: dict[str, dict] = {}
    unlowered: list[tuple[dict, str]] = []
    for r in rules:
        form, problems = lower_statement(r["text"])
        for p in problems:
            unlowered.append((r, p))
        forms[r["label"]] = form
    for r in rules:
        parent = r.get("parent")
        if parent in forms and forms[parent]["kind"] == "when":
            forms[parent].setdefault("children", []).append(r["label"])
            forms[r["label"]]["when"] = {"label": parent, "condition": forms[parent]["condition"]}
    for form in forms.values():
        if "children" in form:
            form["children"].sort()
    return dict(sorted(forms.items())), unlowered


def lower_doc(doc: dict) -> dict:
    """The normalized form of one spec's IR document: `normalized`, by label."""
    forms, _ = lower_rules(doc["rules"])
    return {"normal": NORMAL_VERSION, "rules": forms}


# ── the advisory checks over the normalized form ──────────────────────────── #

def strings(form: dict):
    """Each string of a form's own text, for the reference scan: the subject,
    the object and the timing terms, and each condition clause as written."""
    if form["kind"] in ("excluded", "unlowered"):
        return
    groups = [form["if"]] if "if" in form else []
    if form["kind"] == "when":
        groups.append(form["condition"])
    for g in groups:
        for c in g["clauses"]:
            yield c["text"]
    for key in ("subject", "proposition", "scope"):
        if key in form:
            yield form[key]
    for o in form.get("obligations", []):
        yield o["object"]
        for t in o["timing"]:
            yield t["term"]
        for g in o.get("only_if", []) + o.get("only_under", []):
            for c in g["clauses"]:
                yield c["text"]


def ordinal_references(forms: dict[str, dict]) -> list[tuple[str, str]]:
    """Each rule that refers to another rule by its place, not its label (Hard
    invariant 13): `the previous rule`, `rule 3`, `the rule above`."""
    out = []
    for label, form in forms.items():
        for s in strings(form):
            m = ORDINAL_REF.search(s)
            if m:
                out.append((label, m.group()))
                break
    return out


def members(text: str) -> set[str]:
    """The values a declaration's text names between bars, or a list's
    members: `[Add] | [Clear] | [Read] — the actions ...` is three."""
    body = re.split(r" — |\.$", text)[0]
    if "|" not in body:
        return set()
    return {re.sub(r"\(.*$", "", p).strip().strip("[]`").strip() for p in body.split("|")}


def declared_values(doc: dict, docs: dict[str, dict], forms: dict[str, dict]) -> set[str]:
    """The closed value sets a spec and its constituents declare: a `Term`
    declaration's bar-separated members, a signature's answers and refusal
    codes, and an EXACTLY ONE OF list in a rule (Closed vocabulary 21)."""
    seen: set[str] = set(GRAMMAR_VALUES)
    todo, done = [doc], set()
    while todo:
        d = todo.pop()
        if d["spec"] in done:
            continue
        done.add(d["spec"])
        for t in d["terms"]:
            seen |= members(t["definition"])
        for v in d["vocabulary"].values():
            seen |= members(v)
        for s in d["signatures"]:
            for arm in s["answers"] + s["refuses"]:
                seen.add(re.sub(r"\(.*$", "", arm).strip())
        for r in d["rules"]:
            for m in re.finditer(r"EXACTLY ONE OF ([^()]*?)(?: \(|\.?$)", r["text"]):
                seen |= {re.sub(r"\(.*$", "", x).strip() for x in m.group(1).split(", ")}
        for c in d.get("composes", []):
            if c["path"] in docs:
                todo.append(docs[c["path"]])
    return seen


def comparison_clauses(form: dict):
    """Each EQUALS or DOES NOT EQUAL clause in a rule's conditions, and a
    clause a presence test carries as its `whose` qualifier."""
    groups = [form["if"]] if "if" in form else []
    if form["kind"] == "when":
        groups.append(form["condition"])
    groups += [g for o in form.get("obligations", []) for g in o.get("only_if", []) + o.get("only_under", [])]
    for g in groups:
        for c in g["clauses"]:
            if c["kind"] == "comparison" and c["op"] in ("EQUALS", "DOES NOT EQUAL"):
                yield c["left"], c["right"]
            elif c["kind"] in ("presence", "absence"):
                m = re.search(r"\b(?:whose|where) (.+?) (?:DOES NOT EQUAL|EQUALS) (\S+)$", c["qualifier"])
                if m:
                    yield m.group(1), m.group(2)


def undeclared_values(doc: dict, docs: dict[str, dict], forms: dict[str, dict]) -> list[tuple[str, str]]:
    """Each EQUALS or DOES NOT EQUAL whose right side is one bare value, not
    blank, that no closed value set the spec or a constituent declares holds
    (Hard invariant 14). A right side that is a phrase or a number names a
    term to compare, not a value, and a one-word name the spec declares as a
    term is a term too; a number written as a word is a number."""
    values = declared_values(doc, docs, forms)
    names = {t["name"] for t in doc["terms"]} | {t["name"] for t in doc["term_entries"]}
    out = []
    for label, form in forms.items():
        for _, right in comparison_clauses(form):
            word = right.strip().strip("`")
            if not BARE_VALUE.match(word) or word in values or word in names or word in NUMBER_WORDS:
                continue
            out.append((label, word))
    return out


def findings(doc: dict, docs: dict[str, dict] | None = None) -> list[tuple[str, int, str, str]]:
    """Every advisory finding on one spec's document: (path, line, code, message)."""
    docs = docs or {}
    line = {r["label"]: r["line"] for r in doc["rules"]}
    forms, unlowered = lower_rules(doc["rules"])
    out = [(doc["spec"], r["line"], "N-unlowered", f"{r['label']}: {why}") for r, why in unlowered]
    out += [(doc["spec"], line[lab], "N-ordinal-ref", f"{lab} refers to a rule by its place: {ref}")
            for lab, ref in ordinal_references(forms)]
    out += [(doc["spec"], line[lab], "N-value-set", f"{lab} compares with {v}, which belongs to no closed value set the "
                                                      f"spec or a constituent declares") for lab, v in undeclared_values(doc, docs, forms)]
    return sorted(out, key=lambda f: (f[0], f[1], f[2]))


def main(argv: list[str]) -> int:
    import ir
    root = HERE.parents[1]
    args = [a for a in argv[1:] if not a.startswith("--")]
    if args:
        for a in args:
            print(json.dumps(lower_doc(ir.parse(Path(a), root)), indent=2, ensure_ascii=False))
        return 0
    docs, _ = ir.build(root)
    by_path = {d["spec"]: d for d in docs}
    total: dict[str, int] = {}
    for d in docs:
        for f in findings(d, by_path):
            print(f"{f[0]}:{f[1]}: [{f[2]}] {f[3]}")
            total[f[2]] = total.get(f[2], 0) + 1
    n_rules = sum(len(d["rules"]) for d in docs)
    counts = ", ".join(f"{n} {code}" for code, n in sorted(total.items())) or "none"
    print(f"normalize: {len(docs)} specs, {n_rules} rules lowered; advisory: {counts}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

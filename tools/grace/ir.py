#!/usr/bin/env python3
"""The parser: every spec in atoms/ and compositions/ to a derived IR.

The IR is derived, never canonical: the specs stay the source (Scott,
2026-10-28). One JSON document per spec, written to build/ir/<spec>.json and
ignored by git, holds what a test generator or the Grace connector reads from a
page: its title, kind and status, its Summary, every labelled rule, every Term
with its term entry's Kind, every signature, every case-table row, every Check
with the rules it tests, the Non-goals with their owners, the Composes list,
and every rule lowered to its normalized form (normalize.py, GRACE-lang section
16). Beside a rule it carries what the rule rests on: the Execution Contract rule
it cites for what a word means (label and text), the key an Identity rule names
as the fields of the Term that names it, and the term entries that give the half
of an operation a rule states only as a necessary condition, the settings a deployment may declare with their defaults, and the sets a Term defines from the call. Where the page does
not give enough to carry one of these, `reader_gaps` says so and nothing is
guessed.
README.md, section *The IR*, gives the shape.

It reads with the readers the corpus already has, not a second copy of their
forms: check.py's fence, label, tombstone and signature forms; cites.py's
parse, the labelled-rule count the census and the rewrite commits use;
lint.py's spec set, its Status line and its reading of the Execution
Contract's labels; and the Composes list as write-reads.py's composes() reads
it for the council's reading sets, so a spec's constituents here are the pages
its readers are given.

Then it proves the IR on the whole corpus: every spec parses; each document's
rule count equals cites.py's; every label is unique on its page; every rule a
Check names exists; every Composes entry resolves to a spec. A spec the parser
cannot read is a finding, never an exception.

    python3 tools/grace/ir.py                  # every spec to build/ir/, then the proof
    python3 tools/grace/ir.py --check          # the proof alone, nothing written
    python3 tools/grace/ir.py atoms/cart.md    # one spec's document, printed

One-spec mode reads a draft outside the repo too, the Grace connector's: its
`spec` is the path as given, it is a composition when it has a Composes
section and an atom otherwise, and its links resolve as from atoms/ or
compositions/, so the constituents it names are the repo's specs.

Standard library only. One finding per line, `path:line: [CODE] message`; exit
1 on any finding.
"""
from __future__ import annotations

import functools
import json
import posixpath
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "linter"))
import check  # noqa: E402
import cites  # noqa: E402
import normalize  # noqa: E402
from lint import CONTRACT_CITE, HISTORY_FILE, PATTERN_DIRS, contract_label_set, status_token_of  # noqa: E402

# the shape of a document; a change a reader of the IR must know about moves it,
# and an added field is none
IR_VERSION = 1

H34 = re.compile(r"^(#{3,4}) (.*?)\s*$")
BULLET_LEAD = re.compile(r"^\s*- \*\*([^*]+)\*\*")
LINK_DEF = re.compile(r"^\[[^\]]+\]:\s*\S")
ENTRY_OF = re.compile(r"— an? \[([^\]]+)\]")
KIND_LINE = re.compile(r"^([A-Z][A-Za-z ]*?):\s+(.*?)\s*$")
TABLE_RULE = re.compile(r"^\|(?:\s*:?-+:?\s*\|)+\s*$")
CELL_SPLIT = re.compile(r"(?<!\\)\|")
CLOSING = re.compile(r"\(([^()]*)\)\.?$")
NUMBER = r"[\d½]+(?:\.\d+)?[a-z]?"
BARE_NUMBER = re.compile(r"^(?:step )?" + NUMBER + r"(?: through " + NUMBER + r")?$")
OWNERS = "NOTE: the owners — "
FORTHCOMING = re.compile(r"\*\((?:forthcoming|not yet in the library)\)\*")
NEXT_OWNER = re.compile(r",?\s+(?:and|or)\s+|,\s+")
OPENS_OWNER = re.compile(r"\[|(?:a|an|the)\s|[A-Z]")


def section_lines(lines: list[str], name: str) -> range:
    """Line indexes of the `##` section titled `name`, in either heading form."""
    start = next((i for i, ln in enumerate(lines) if (check.h2_name(ln) or "").strip() == name), None)
    if start is None:
        return range(0)
    end = next((i for i in range(start + 1, len(lines)) if check.h2_name(lines[i]) is not None), len(lines))
    return range(start + 1, end)


def outline(lines: list[str]) -> list[tuple[tuple[str, ...], str]]:
    """For each line, the headings it sits under (`##` in either form, `###`,
    `####`) and the bold bullet lead since the last of them — the title line of
    `- **Invariant 1 — One line per item.**`, which an indented fence sits in."""
    out = []
    heads, lead, fence = ["", "", ""], "", False
    for ln in lines:
        if check.FENCE.match(ln):
            fence = not fence
        elif not fence:
            h2, h34 = check.h2_name(ln), H34.match(ln)
            if h2 is not None:
                heads, lead = [h2.strip(), "", ""], ""
            elif h34:
                deep = len(h34.group(1)) == 4
                heads = [heads[0], heads[1] if deep else h34.group(2), h34.group(2) if deep else ""]
                lead = ""
            elif BULLET_LEAD.match(ln):
                lead = BULLET_LEAD.match(ln).group(1).strip()
        out.append((tuple(h for h in heads if h), lead))
    return out


def blocks(lines: list[str]):
    """Each bare fenced block, classified by its first non-blank line as
    check.py's scan classifies it (GRACE-lang Surface 18 to 22): `rules` (a
    labelled rule or a tombstone opens it), `signatures` (`name(`, unless the
    call carries values and is an example), or `other`. Yields the kind, the
    fence's indent, and the index of each line inside."""
    i, n = 0, len(lines)
    while i < n:
        m = check.FENCE.match(lines[i])
        if not m:
            i += 1
            continue
        j = i + 1
        while j < n and not (check.FENCE.match(lines[j]) and check.FENCE.match(lines[j]).group(2) == ""):
            j += 1
        if m.group(2) in ("", "text"):
            body = range(i + 1, j)
            at = next((k for k in body if lines[k].strip()), None)
            first = lines[at].strip() if at is not None else ""
            if first and not check.PREFIX.match(first) and (check.LABEL.match(first) or first.startswith("Deleted:")):
                kind = "rules"
            elif first and check.SIGNATURE.match(first) and not check.example_call(lines, at):
                kind = "signatures"
            else:
                kind = "other"
            yield kind, len(m.group(1)), body
        i = j + 1


def split_label(label: str) -> tuple[str, str]:
    """A label's family and its number: `Invariant 2.1` is `Invariant`, `2.1`;
    `record_action step 3.2` is `record_action`, `step 3.2`."""
    parts = check.LABEL_PARTS.match(label)
    if parts:
        return parts.group("name"), label[len(parts.group("name")) + 1:]
    m = cites.NAME_NUM.search(label)
    return (label[:m.start()], m.group(1).strip()) if m else (label, "")


def walk_rules(lines: list[str], where) -> tuple[list[dict], list[dict]]:
    """Every labelled rule and every tombstone in a normative block, in file
    order, duplicates kept so the proof can see them. A rule indented under a
    WHEN rule is that rule's child (WHEN block 3), as check.py reads it."""
    rules, tombstones = [], []
    for kind, fence_indent, body in blocks(lines):
        if kind != "rules":
            continue
        stack: list[dict] = []
        for k in body:
            raw = lines[k]
            s = raw.strip()
            if not s or check.PREFIX.match(s):
                continue
            if s.startswith("Deleted:"):
                t = check.TOMBSTONE.match(s)
                if t:
                    tombstones.append({"label": t.group(1), "text": s[len("Deleted: " + t.group(1) + ". "):],
                                       "line": k + 1})
                continue
            lm = check.LABEL.match(s)
            if not lm:
                continue  # an unlabelled line: the gate's F-unlabelled
            indent = len(raw) - len(raw.lstrip()) - fence_indent
            while stack and indent <= stack[-1]["indent"]:
                stack.pop()
            heads, lead = where[k]
            family, number = split_label(lm.group(1))
            rule = {"label": lm.group(1), "family": family, "number": number, "text": lm.group(2),
                    "section": list(heads) + ([lead] if lead and fence_indent else []),
                    "line": k + 1, "parent": stack[-1]["label"] if stack else None, "indent": indent}
            rules.append(rule)
            if lm.group(2).startswith("WHEN "):
                stack.append(rule)
    for rule in rules:
        del rule["indent"]
    return rules, tombstones


def history_tombstones(path: Path, root: Path) -> list[dict]:
    """The tombstones in the section titled *Deleted rules* of the history file
    beside the spec, where a done pattern keeps them (GRACE-lang Hard invariant
    25, v0.71), in file order, each with the file it stands in."""
    hist = cites.history_file(path)
    where = repo_path(hist, root) or hist.as_posix()
    out = []
    for k, raw in cites.deleted_rules(path):
        s = raw.strip()
        t = check.TOMBSTONE.match(s)
        if t:
            out.append({"label": t.group(1), "text": s[len("Deleted: " + t.group(1) + ". "):],
                        "line": k, "file": where})
    return out


def walk_signatures(lines: list[str]) -> list[dict]:
    """Every signature in a signature block (Closed vocabulary 24): the action,
    its inputs, its answers arms and its refuses codes, as written."""
    out: list[dict] = []
    for kind, _, body in blocks(lines):
        if kind != "signatures":
            continue
        sig = None
        for k in body:
            raw = lines[k].rstrip()
            head = check.SIG_HEAD.match(raw)
            if head:
                inputs = [x for x in (head.group(2) or "").split(", ") if x]
                sig = {"action": head.group(1),
                       "inputs": [{"name": x.removeprefix("optional "), "optional": x.startswith("optional ")}
                                  for x in inputs],
                       "answers": [], "refuses": [], "line": k + 1}
                out.append(sig)
            elif sig and raw.startswith("  answers "):
                sig["answers"] = raw[len("  answers "):].split(" | ")
            elif sig and raw.startswith("  refuses "):
                sig["refuses"] = raw[len("  refuses "):].split(" | ")
    return out


def walk_terms(spec: cites.Spec, lines: list[str], where) -> tuple[list[dict], dict, list[dict]]:
    """The `Term` declarations, as cites.py parses them, split into the
    vocabulary lines (`Term actors:` and the other categories) and the terms;
    and the term entries under `## Terms`. A declaration owns its definition,
    and the term entry its marker lands on (`— a [Cart]`) carries the reader's
    copy and the Kind (spec-format.md, *The term entry*)."""
    entries: list[dict] = []
    terms_at = section_lines(lines, "Terms")
    entry = None
    for k in terms_at:
        ln = lines[k]
        h4 = re.match(r"^#### (.*?)\s*$", ln)
        if h4:
            entry = {"name": h4.group(1), "text": "", "kind": {}, "line": k + 1}
            entries.append(entry)
            continue
        if entry is None:
            continue
        if ln.startswith("#") or LINK_DEF.match(ln) or ln.lstrip().startswith("<!--"):
            entry = None
            continue
        kl = KIND_LINE.match(ln)
        if kl and (entry["kind"] or kl.group(1) == "Kind"):
            entry["kind"][kl.group(1)] = kl.group(2)
        elif ln.strip() and not entry["kind"]:
            entry["text"] = (entry["text"] + "\n" + ln.strip()).strip()
    by_name = {e["name"]: e for e in entries}

    vocabulary: dict[str, str] = {}
    terms: list[dict] = []
    for name, (line, definition) in sorted(spec.terms.items(), key=lambda t: t[1][0]):
        if name in cites.CATEGORY_NAMES:
            vocabulary[name] = definition
            continue
        marker = ENTRY_OF.search(definition)
        landed = by_name.get(marker.group(1)) if marker else None
        terms.append({"name": name, "definition": definition, "line": line,
                      "section": list(where[line - 1][0]),
                      "entry": landed["name"] if landed else None,
                      "kind": dict(landed["kind"]) if landed else None})
    return terms, vocabulary, entries


def walk_tables(lines: list[str], where, spec: cites.Spec) -> list[dict]:
    """Every table above `## Status`: the case tables, each row a case with
    what it answers and the rules that own it, which the row names by label —
    the page's own, then the Execution Contract's."""
    status = next((i for i, ln in enumerate(lines) if (check.h2_name(ln) or "").strip() == "Status"), len(lines))
    lab_re = cites._label_pattern(set(spec.rules))
    out: list[dict] = []
    fence, i = False, 0
    while i < status:
        ln = lines[i]
        if check.FENCE.match(ln):
            fence = not fence
        elif not fence and ln.startswith("|") and i + 1 < status and TABLE_RULE.match(lines[i + 1]):
            caption = next((lines[k].strip() for k in range(i - 1, -1, -1) if lines[k].strip()), "")
            table = {"line": i + 1, "section": list(where[i][0]), "caption": caption,
                     "columns": cells(ln), "rows": []}
            j = i + 2
            while j < status and lines[j].startswith("|"):
                named, _ = cites.uses(lines[j], spec, lab_re, "")
                contract = [f"Execution Contract {m.group(1)} {m.group(2)}"
                            for m in CONTRACT_CITE.finditer(lines[j])]
                table["rows"].append({"line": j + 1, "cells": cells(lines[j]),
                                      "rules": sorted(named, key=lambda lab: spec.rules[lab]) + contract})
                j += 1
            out.append(table)
            i = j
            continue
        i += 1
    return out


def cells(row: str) -> list[str]:
    return [c.strip() for c in CELL_SPLIT.split(row.strip().strip("|"))]


def references(text: str) -> list[str]:
    """The labels a list of citations names, written out: `Non-goal 1, 2;
    External check 1` names `Non-goal 1`, `Non-goal 2` and `External check 1`.
    A citation may carry another spec's name or `Execution Contract` before its
    label (GRACE-lang Hard invariant 28), and a range keeps its form, `Invariant
    1 through 4` (Hard invariant 29). An item that names no label is left out."""
    out: list[str] = []
    family, sep = None, " "
    for item in re.split(r"\s*[;,]\s*|\s+and\s+", text):
        item = item.strip()
        if not item:
            continue
        if BARE_NUMBER.match(item) and family:
            item = family + (sep if not item.startswith("step ") else " ") + item
        head = item.split(" through ")[0]
        m = cites.NAME_NUM.search(head)
        if not m or not re.match(r"^[A-Za-z]", head):
            continue
        family, sep = head[:m.start()], " step " if m.group(1).startswith(" step ") else " "
        out.append(item)
    return out


def walk_checks(rules: list[dict]) -> list[dict]:
    """Every Check and External check, with the rules it tests: the labels its
    closing parenthesis names (spec-format.md: each check references the
    invariant it verifies). A check with no closing citation tests none the
    IR can read."""
    out = []
    for r in rules:
        if r["family"] not in ("Check", "External check"):
            continue
        m = CLOSING.search(r["text"])
        out.append({"label": r["label"], "line": r["line"],
                    "tests": references(m.group(1)) if m else []})
    return out


def walk_non_goals(rel: str, lines: list[str], rules: list[dict], spec: cites.Spec) -> list[dict]:
    """Every Non-goal with its owners, from the section's `NOTE: the owners —`
    line: owners separated by `;`, each followed by the labels it owns in
    parentheses (spec-format.md section Non-goals: each points at the pattern
    or mechanism that owns it, by link, `*(forthcoming)*` if it has not
    landed). Each owner says whether it is forthcoming, so a part that names a
    forthcoming owner beside others gives each its own entry (owner_parts)."""
    owned: dict[str, list[dict]] = {}
    for k in section_lines(lines, "Non-goals"):
        if not lines[k].startswith(OWNERS):
            continue
        for group in top_level_split(lines[k][len(OWNERS):].strip().rstrip(".")):
            cited, owner = [], group
            for par in re.findall(r"\(([^()]*)\)", group):
                labels = references(par)
                if labels and not FORTHCOMING.search("*(" + par + ")*"):
                    cited += labels
                    owner = owner.replace("(" + par + ")", " ")
            whos = [{"owner": part,
                     "links": [posixpath.normpath(posixpath.join(posixpath.dirname(rel), lk))
                               for _, lk in check.MD_LINK.findall(part) if lk.endswith(".md")],
                     "forthcoming": bool(FORTHCOMING.search(part)), "line": k + 1}
                    for part in owner_parts(owner)]
            for label in expand(cited, spec):
                owned.setdefault(label, []).extend(whos)
    return [{"label": r["label"], "line": r["line"], "owners": owned.get(r["label"], [])}
            for r in rules if r["family"] == "Non-goal"]


def owner_parts(owner: str) -> list[str]:
    """The owners one part of the owners line names, its labels already cut. A
    part that marks a name forthcoming is split at each comma, `and` or `or`
    outside a link and a parenthesis that a link, an article or a capitalized
    word follows: `[Audit Trail](./audit-trail.md), the deployment and
    Reverse Index *(forthcoming)*` is three owners, and `a
    priority and ordering pattern *(forthcoming)*` one. A part with no marker
    is one owner, since none of its owners is forthcoming, and its prose is
    not split: in `[Permissions](../atoms/permissions.md) and
    [Session](../atoms/session.md), an identity-keyed access model` the last
    phrase glosses the two."""
    if not FORTHCOMING.search(owner):
        return [re.sub(r"\s+", " ", owner).strip()]
    parts, depth, start, i = [], 0, 0, 0
    while i < len(owner):
        depth += (owner[i] in "([") - (owner[i] in ")]")
        m = NEXT_OWNER.match(owner, i) if depth == 0 else None
        if m and OPENS_OWNER.match(owner, m.end()):
            parts.append(owner[start:i])
            start = i = m.end()
            continue
        i += 1
    return [p for p in (re.sub(r"\s+", " ", p).strip() for p in parts + [owner[start:]]) if p]


def top_level_split(text: str) -> list[str]:
    """`;`-separated parts, a `;` inside parentheses not separating."""
    parts, depth, cur = [], 0, ""
    for ch in text:
        depth += (ch == "(") - (ch == ")")
        if ch == ";" and depth == 0:
            parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    return [p for p in parts + [cur.strip()] if p]


def expand(citations: list[str], spec: cites.Spec) -> list[str]:
    """Same-page citations as labels, a range as every label it covers."""
    out = []
    for c in citations:
        if " through " not in c:
            out.append(c)
            continue
        first, last = c.split(" through ", 1)
        m = cites.NAME_NUM.search(first)
        out += [lab for lab in spec.rules if cites.in_range(lab, first[:m.start()], m.group(1), last)]
    return out


def walk_composes(rel: str, lines: list[str]) -> list[dict]:
    """The constituents the `## Composes` section lists, read as
    write-reads.py's composes() reads them: each bullet that links an atom or a
    composition, before the wiring's first fence (spec-format.md, the
    composition shape's Composes section)."""
    out, seen = [], set()
    base = posixpath.dirname(rel)
    for k in section_lines(lines, "Composes"):
        ln = lines[k]
        if ln.lstrip()[:3] in ("```", "~~~"):
            break
        link = re.match(r"[-*] .*?\[([^\]]+)\]\(([^)#\s]+\.md)\)", ln)
        if not link:
            continue
        target = posixpath.normpath(posixpath.join(base, link.group(2)))
        if target.startswith(("atoms/", "compositions/")) and target not in seen:
            seen.add(target)
            role = ln.split(" — ", 1)[1].strip() if " — " in ln else ""
            out.append({"name": link.group(1), "path": target, "role": role, "line": k + 1})
    return out


CONTRACT_PARA = re.compile(r"^\*\*((?:[A-Z][a-z]+)(?: [a-z]+)*) (\d+[a-z]?): (.*?)\*\*\s*(.*)$")
IDENTIFY = re.compile(r"identify (?:a|an|the) (?P<thing>.+?) by (?P<by>.+?)\.?$")
KEY_TERM = re.compile(r"(?:the|a|an) (?P<thing>.+?)'s (?P<term>.+)$")
LIST_SEP = re.compile(r"\s*(?:,\s*and\s+|,\s*|and\s+)")


@functools.lru_cache(maxsize=8)
def contract_rules(root: str, stamp: int) -> dict[str, dict]:
    """Each rule of execution-contract.md by its label (`Query 5`): its title,
    its text, its line. Empty where the root carries no contract. `stamp`, the
    file's mtime, keeps a cached read from outliving an edit."""
    try:
        lines = (Path(root) / "execution-contract.md").read_text(encoding="utf-8").split("\n")
    except OSError:
        return {}
    out = {}
    for k, ln in enumerate(lines):
        m = CONTRACT_PARA.match(ln)
        if m:
            out[f"{m.group(1)} {m.group(2)}"] = {"title": m.group(3).strip(), "text": m.group(4).strip(),
                                                  "line": k + 1}
    return out


def contract_of(root: Path) -> dict[str, dict]:
    try:
        stamp = (root / "execution-contract.md").stat().st_mtime_ns
    except OSError:
        return {}
    return contract_rules(str(root.resolve()), stamp)


def predicates(form) -> list[str]:
    """The text of every predicate clause a normalized form carries, in order:
    a clause the grammar's operators do not give a meaning to (`the person
    reference is malformed`), whose meaning the page leaves to the rule it cites."""
    out: list[str] = []
    if isinstance(form, dict):
        if form.get("kind") == "predicate":
            out.append(form["text"])
        for v in form.values():
            out += predicates(v)
    elif isinstance(form, list):
        for v in form:
            out += predicates(v)
    return out


def cited_meaning(rule: dict, form: dict, contract: dict[str, dict]) -> list[dict]:
    """For a rule with a predicate clause, the Execution Contract rules its
    text cites, each with its label, title and text; and the rule the cited
    text sends the predicate's own word on to (`malformed (Query 1)` in Query
    5), with the citing rule in `via`. Nothing is carried for a rule with no
    predicate, nor for a label the contract does not carry."""
    words = {p.split()[-1] for p in predicates(form)}
    if not words:
        return []
    out: list[dict] = []
    seen: set[str] = set()

    def take(key: str, via: str | None) -> None:
        if key in seen or key not in contract:
            return
        seen.add(key)
        c = contract[key]
        out.append({"label": "Execution Contract " + key, "title": c["title"], "text": c["text"], "via": via})
        for w in words:
            for m in re.finditer(r"\b%s\b[^.()]{0,40}\((?:Execution Contract )?([A-Z][a-z]+(?: [a-z]+)* \d+[a-z]?)\)"
                                 % re.escape(w), c["text"]):
                take(m.group(1), "Execution Contract " + key)

    for m in CONTRACT_CITE.finditer(rule["text"]):
        take(f"{m.group(1)} {m.group(2)}", None)
    return out


def cited_texts(rule: dict, contract: dict[str, dict]) -> list[dict]:
    """The Execution Contract rules a rule's text cites, each with its label,
    title and text: what an order or a shape the rule leaves to them means."""
    out: list[dict] = []
    for m in CONTRACT_CITE.finditer(rule["text"]):
        key = f"{m.group(1)} {m.group(2)}"
        if key in contract and not any(o["label"] == "Execution Contract " + key for o in out):
            out.append({"label": "Execution Contract " + key, "title": contract[key]["title"], "text": contract[key]["text"]})
    return out


def completed_by(form: dict, entries: list[dict]) -> list[dict]:
    """For a rule that states only a necessary condition on an answer (`EXACTLY
    ONE OF`, `ONLY IF`), the term entries that give the rest: the Operation
    entry its subject names, and the Member entry of each value it answers.
    The text is the entry's own; ir.py does not read it for a rule."""
    by_name = {e["name"].lower(): e for e in entries}
    obs = form.get("obligations", []) if form.get("kind") == "rule" else []
    if not any(o.get("exclusive") or o.get("only_if") for o in obs):
        return []
    subject = re.fullmatch(r"\[(.+)\]", form.get("subject", "").strip())
    head = by_name.get(subject.group(1).lower()) if subject else None
    if not head or head["kind"].get("Kind") != "Operation":
        return []
    out = [{"entry": head["name"], "kind": "Operation", "line": head["line"], "text": head["text"]}]
    names = []
    for o in obs:
        names += list(o.get("exclusive", [])) + ([o["object"]] if o.get("object") else [])
    for n in names:
        e = by_name.get(n.lower())
        if e and e["kind"].get("Kind") == "Member" and e["name"] not in [x["entry"] for x in out]:
            out.append({"entry": e["name"], "kind": "Member", "line": e["line"], "text": e["text"]})
    return out


def term_fields(term: dict, entries: list[dict]) -> tuple[list[dict], str]:
    """The Field entries a Term's definition lists at its start (`the person
    reference and the item reference ...`), in the order it gives them, or
    the reason it gives none: the list is not carried in part."""
    fields = {e["name"].lower(): e for e in entries if e["kind"].get("Kind") == "Field"}
    rest, got, after_sep = term["definition"].strip(), [], False
    while True:
        hit = next((n for n in sorted(fields, key=len, reverse=True)
                    if re.match(r"(?:the |a |an )?%s\b" % re.escape(n), rest, re.I)), None)
        if not hit and after_sep:
            return [], (f"the definition of Term {term['name']} lists `{rest[:30].strip()}` after "
                        f"`{got[-1]['name']}`, which is no Field entry: the list is not carried in part")
        if not hit:
            break
        got.append(fields[hit])
        rest = rest[re.match(r"(?:the |a |an )?%s" % re.escape(hit), rest, re.I).end():]
        sep = LIST_SEP.match(rest)
        if not sep:
            break
        rest, after_sep = rest[sep.end():], True
    if not got:
        return [], f"the definition of Term {term['name']} does not begin with a list of Field entries"
    return got, ""


def key_of(rule: dict, terms: list[dict], entries: list[dict]) -> tuple[dict | None, str]:
    """The key an Identity rule names: `identify a favorite by the favorite's
    pair` names the Term pair, and the fields are those the Term's definition
    lists at its start (`the person reference and the item reference ...`),
    each a Field entry, in the order the definition gives them. Returns the key,
    or None and what the page does not give."""
    m = IDENTIFY.search(rule["text"])
    if not m:
        return None, "the rule does not say `identify a <thing> by <the thing's term>`"
    k = KEY_TERM.fullmatch(m.group("by"))
    if not k or k.group("thing") != m.group("thing"):
        return None, f"the key `{m.group('by')}` is not named through a Term of the form `the {m.group('thing')}'s <term>`"
    term = next((t for t in terms if t["name"].lower() == k.group("term").lower()), None)
    if not term:
        return None, f"no Term `{k.group('term')}` is declared"
    got, why = term_fields(term, entries)
    if not got:
        return None, why
    return ({"rule": rule["label"], "line": rule["line"], "thing": m.group("thing"), "term": term["name"],
             "names": [e["name"].lower() for e in got],
             "fields": [e["kind"].get("Projection") or e["name"] for e in got]}, "")


# an answer that is a shape, not an arm of the signature: what the read side of a page says it answers
SHAPE_COUNT = re.compile(r"the (?P<count>.+?) of EVERY (?P<by>.+?) an? (?P<what>.+?) carrying (?P<x>.+?) carries$")
SHAPE_EVERY = re.compile(r"(?:the (?P<of>.+?) of )?EVERY (?P<what>.+?) carrying (?P<x>.+)$")
SHAPE_FIELDS = re.compile(r"an? (?P<thing>.+?)'s (?P<fields>.+? AND .+)$")
SHAPE_EMPTY = re.compile(r"an empty list(?: for (?:an?|the) (?P<x>.+?) no (?P<what>.+?) carries)?$")
SHAPE_BY = re.compile(r"(?P<arm>.+?) by (?P<by>.+)$")
SHAPE_CODEPOINT = re.compile(r"(?P<arm>.+?) in codepoint order(?: of (?P<of>.+))?$")
DIRECTIONS = {"earliest first": "ascending", "oldest first": "ascending", "ascending": "ascending",
              "latest first": "descending", "newest first": "descending", "descending": "descending"}
MEMBER_ANSWER = re.compile(r"\[(?P<op>[^\]]+)\]'s answer for one(?: and for (?:an?|the) [^.;,]*? with no (?P<none>[a-z ]+?))?(?=[.;,]|$)")


def shape_context(doc: dict) -> dict:
    """The names a shape resolves through: the record type, its Field entries,
    and the Member entries of its status, each by lower-cased name."""
    entries = doc["term_entries"]
    rtype = next((e for e in entries if e["kind"].get("Kind") == "Type" and "Projection" not in e["kind"]), None)
    fields = {e["name"].lower(): e["kind"].get("Projection") or e["name"]
              for e in entries if e["kind"].get("Kind") == "Field"}
    members = {e["name"].lower(): (e["kind"].get("Member of", "").removeprefix("the ").lower(), e["kind"].get("Projection") or e["name"].lower())
               for e in entries if e["kind"].get("Kind") == "Member"}
    return {"type": rtype["name"].lower() if rtype else None, "fields": fields, "members": members,
            "terms": {t["name"].lower(): t for t in doc["terms"]}, "entries": entries}


def field_of(phrase: str, cx: dict) -> str | None:
    return cx["fields"].get(re.sub(r"^(?:the|a|an) ", "", phrase.strip()).lower())


def carrying_of(phrase: str, cx: dict) -> tuple[list[str], str]:
    """`the person reference`, or a Term (`the pair`) whose definition lists Field entries -> projection names"""
    name = re.sub(r"^(?:the|a|an) ", "", phrase.strip()).lower()
    if name in cx["fields"]:
        return [cx["fields"][name]], ""
    t = cx["terms"].get(name)
    if t:
        got, why = term_fields(t, cx["entries"])
        return [e["kind"].get("Projection") or e["name"] for e in got], why
    return [], f"`{phrase.strip()}` is neither a Field entry nor a Term"


def what_of(phrase: str, cx: dict) -> tuple[list[dict], str]:
    """`marked favorite`, `held reaction` -> the record type and the Member entries before it, each a status test"""
    words = phrase.strip().lower().split()
    if not cx["type"] or not words or " ".join(words[-len(cx["type"].split()):]) != cx["type"]:
        return [], f"`{phrase.strip()}` does not end in the record type"
    where = []
    for w in words[:-len(cx["type"].split())]:
        if w not in cx["members"]:
            return [], f"`{w}` is no Member entry"
        field, value = cx["members"][w]
        if field not in cx["fields"]:
            return [], f"`{w}` is a Member of `{field}`, which is no Field entry"
        where.append({"field": cx["fields"][field], "value": value})
    return where, ""


def answer_shape(form: dict, doc: dict, cx: dict) -> tuple[dict | None, str]:
    """For an Operation rule that answers something that is no arm of its
    action's signature, the shape it says, with every noun resolved to the
    projection of the Field entry or Member entry it names: `every` (the
    records carrying a field set, a status test, and the fields answered),
    `fields` (the fields of one record), `empty` (an empty list), `count_by`
    (a count of the records by one field) and `order` (the arm's rows ordered by fields,
    each with a direction). Returns the shape, or None and what the page does
    not give; nothing is guessed."""
    sigs = {re.sub(r"[^a-z0-9]+", "_", s["action"].lower()).strip("_"): s for s in doc["signatures"]}
    sub = re.fullmatch(r"\[(.+)\]", form.get("subject", "").strip())
    action = re.sub(r"[^a-z0-9]+", "_", sub.group(1).lower()).strip("_") if sub else None
    sig = sigs.get(action)
    if not sig:
        return None, "the rule's subject is no action of the signatures"
    ob = form["obligations"][0]["object"]
    arms = []
    for a in sig["answers"]:
        m = re.fullmatch(r"([a-z_]+)\((.*)\)", a)
        if m:
            arms.append({"name": m.group(1), "fields": [x.strip() for x in m.group(2).split(",") if x.strip()]})
    arm = arms[0] if len(arms) == 1 else None
    out: dict | None = None
    m = SHAPE_COUNT.fullmatch(ob)
    if m:
        by, what, x = field_of(m.group("by"), cx), what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
        if not by or what[1] or x[1]:
            return None, (what[1] or x[1] or f"`{m.group('by')}` is no Field entry")
        out = {"shape": "count_by", "count": m.group("count"), "by": by, "thing": cx["type"], "where": what[0], "carrying": x[0]}
    m = None if out else SHAPE_EVERY.fullmatch(ob)
    if m:
        what, x = what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
        of = [field_of(m.group("of"), cx)] if m.group("of") else []
        if what[1] or x[1] or (m.group("of") and not of[0]):
            return None, what[1] or x[1] or f"`{m.group('of')}` is no Field entry"
        out = {"shape": "every", "thing": cx["type"], "where": what[0], "carrying": x[0], "of": of}
    m = None if out else SHAPE_FIELDS.fullmatch(ob)
    if m:
        fs = [field_of(x, cx) for x in re.split(r"\s+AND\s+", m.group("fields"))]
        if m.group("thing").lower() != cx["type"] or not all(fs):
            return None, f"`{m.group('fields')}` names a thing that is no Field entry of the record"
        out = {"shape": "fields", "thing": cx["type"], "fields": fs}
    m = None if out else SHAPE_EMPTY.fullmatch(ob)
    if m:
        out = {"shape": "empty"}
        if m.group("x"):
            what, x = what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
            if what[1] or x[1]:
                return None, what[1] or x[1]
            out.update({"thing": cx["type"], "where": what[0], "carrying": x[0]})
    m = None if out else SHAPE_CODEPOINT.fullmatch(ob)
    if m:
        name = re.sub(r"[^a-z0-9]+", "_", m.group("arm").lower()).strip("_")
        own = next((a for a in arms if a["name"] == name), None)
        by = [field_of(m.group("of"), cx)] if m.group("of") else (own["fields"][:1] if own and len(own["fields"]) == 1 else [])
        if not own or not by or not by[0]:
            return None, f"`{m.group('arm')}` names no arm of the signature with one field to order by"
        out = {"shape": "order", "arm": own["name"], "by": [{"field": by[0], "direction": "ascending"}]}
    m = None if out else SHAPE_BY.fullmatch(ob)
    if m:
        name = re.sub(r"[^a-z0-9]+", "_", m.group("arm").lower()).strip("_")
        own = next((a for a in arms if a["name"] == name), None)
        keys = []
        for part in re.split(r",? then by ", m.group("by")):
            direction = next((d for d in DIRECTIONS if part.endswith(", " + d)), None)
            f = field_of(re.sub(r", %s$" % re.escape(direction), "", part) if direction else part, cx)
            keys.append({"field": f, "direction": DIRECTIONS[direction] if direction else None})
        if not own or not all(k["field"] for k in keys):
            return None, f"`{ob}` orders by something that is no Field entry, or an arm that is no arm of the signature"
        out = {"shape": "order", "arm": own["name"], "by": keys}
    if not out:
        return None, f"the reader reads no shape in `{ob}`"
    out["arm"] = out.get("arm") or (arm["name"] if arm else None)
    out["arm_fields"] = arm["fields"] if arm else []
    return out, ""


def member_answers(entry: dict) -> list[dict]:
    """On a Member entry whose text says `[Look Up]'s answer for one` (and
    for a pair with no favorite), what it answers for: a record standing in
    the member, and where the text says so, no record."""
    out = []
    for m in MEMBER_ANSWER.finditer(entry["text"]):
        out.append({"operation": m.group("op"), "value": entry["kind"].get("Projection") or entry["name"].lower(),
                    "for": ["a record standing in the member"] + (["no record"] if m.group("none") else [])})
    return out


# a setting a deployment may declare, and what stands where it declares none; a set the page defines
# from the record type, one field's value and the call
SETTING_DECLARE = re.compile(r"MAY declare the (?P<term>[a-z ]+?) PER\b")
SETTING_DEFAULT = re.compile(r";\s*(?P<text>[^;—]+?) where a deployment declares none")
SETTING_NAMES = re.compile(r"^the (?P<of>[a-z ]+?) names\b")
SETTING_VALUES = re.compile(r"\b[a-z]+(?:-[a-z]+)+\b")
TERM_SET = re.compile(r"^an? (?P<what>.+?) carrying the (?P<by>.+?) of the call and an? (?P<other>.+?) other than the (?P<same>.+?) of the call\.?$")


def settings_of(doc: dict, cx: dict) -> tuple[list[dict], list[dict]]:
    """The settings a deployment may declare (`The deployment MAY declare the
    reaction set`), each with what stands where it declares none, as the Term's
    definition says it (`the single name like where a deployment declares none`),
    the values the Term lists where it lists them, and the Field a set holds
    where the Term says `the reaction names`. A setting whose Term gives no
    default is a gap, and nothing is guessed."""
    terms = cx["terms"]
    out, gaps = [], []
    for r in doc["rules"]:
        m = SETTING_DECLARE.search(r["text"]) if r["family"] == "Capability requirement" else None
        if not m:
            continue
        t = terms.get(m.group("term"))
        d = SETTING_DEFAULT.search(t["definition"]) if t else None
        if not d:
            gaps.append({"rule": r["label"], "line": r["line"],
                         "what": f"no default read: the Term `{m.group('term')}` does not say what stands where a deployment declares none"})
            continue
        text = d.group("text").strip()
        value: object = text
        n = re.fullmatch(r"([\d,]+)(?: [a-z ]+)?", text)
        names = re.fullmatch(r"the single name (.+)", text)
        if names:
            value = [names.group(1)]
        elif n:
            value = int(n.group(1).replace(",", ""))
        setting = {"term": t["name"], "rule": r["label"], "line": r["line"], "default": {"text": text, "value": value}}
        head = t["definition"].split("—")[0].split(";")[0]
        vals = SETTING_VALUES.findall(head)
        if vals:
            setting["values"] = vals
        of = SETTING_NAMES.match(t["definition"])
        if of:
            f = field_of(of.group("of") + " name", cx)
            if f:
                setting["of"] = f
        out.append(setting)
    return out, gaps


def term_sets_of(doc: dict, cx: dict) -> tuple[list[dict], list[dict]]:
    """A Term that defines a set of records from the call (`a held reaction
    carrying the pair of the call and a reaction name other than the reaction
    name of the call`): the record type and the Member tests (`where`), the
    Fields the set shares with the call (`carrying`) and the Field that differs
    (`other_than`)."""
    out, gaps = [], []
    for t in doc["terms"]:
        if " other than " not in t["definition"] or not re.search(r" carrying the .+ of the call and ", t["definition"]):
            continue
        m = TERM_SET.match(t["definition"].strip())
        if not m:
            gaps.append({"rule": f"Term {t['name']}", "line": t["line"], "what": "no set read: the definition says `other than` and does not fit `a <member> <thing> carrying the <term> of the call and a <field> other than the <field> of the call`"})
            continue
        where, why = what_of(m.group("what"), cx)
        carrying, why2 = carrying_of(m.group("by"), cx)
        other, same = field_of(m.group("other"), cx), field_of(m.group("same"), cx)
        if why or why2 or not other or other != same:
            gaps.append({"rule": f"Term {t['name']}", "line": t["line"], "what": "no set read: " + (why or why2 or "the field that differs is not the field the call names")})
            continue
        out.append({"term": t["name"], "line": t["line"], "thing": cx["type"], "where": where, "carrying": carrying, "other_than": other})
    return out, gaps


def repo_path(path: Path, root: Path) -> str | None:
    """A spec's path in the repo, or None for a draft outside it. Compared as
    given, then resolved, so a root reached through a symlink still holds."""
    for p, r in ((path, root), (path.resolve(), root.resolve())):
        try:
            return p.relative_to(r).as_posix()
        except ValueError:
            continue
    return None


def parse(path: Path, root: Path) -> dict:
    """One spec's document. A draft outside the repo keeps its path as given,
    and its links resolve as from the folder its shape would put it in."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rel = repo_path(path, root)
    if rel is None:
        composes = any((check.h2_name(ln) or "").strip() == "Composes" for ln in lines)
        kind = "composition" if composes else "atom"
        home = f"{kind}s/{path.name}"
    else:
        kind = "atom" if Path(rel).parent.name == "atoms" else "composition"
        home = rel
    where = outline(lines)
    spec = cites.parse(path)
    rules, tombstones = walk_rules(lines, where)
    # a tombstone stands on the page or in the history file: each says which
    tombstones = [dict(t, file=rel or path.as_posix()) for t in tombstones] + history_tombstones(path, root)
    terms, vocabulary, entries = walk_terms(spec, lines, where)
    summary = "\n".join(lines[k].strip() for k in section_lines(lines, "Summary") if lines[k].strip() != "---")
    doc = {
        "ir": IR_VERSION,
        "spec": rel or path.as_posix(),
        "name": cites.spec_name(path),
        "title": next((ln[2:].strip() for ln in lines if ln.startswith("# ")), ""),
        "kind": kind,
        "status": status_token_of(text)[0],
        "summary": "\n\n".join(p.strip() for p in re.split(r"\n\s*\n", summary) if p.strip()),
        "rules": rules,
        "tombstones": tombstones,
        "terms": terms,
        "vocabulary": vocabulary,
        "term_entries": entries,
        "signatures": walk_signatures(lines),
        "case_tables": walk_tables(lines, where, spec),
        "checks": walk_checks(rules),
        "non_goals": walk_non_goals(home, lines, rules, spec),
        "composes": walk_composes(home, lines),
    }
    doc["normalized"] = normalize.lower_doc(doc)
    carry(doc, root)
    return doc


def carry(doc: dict, root: Path) -> None:
    """What the reader adds beside the rules (additions only): `cited_meaning`
    and `completed_by` on the rules that need them, `keys` for the Identity
    rules that name a key, and `reader_gaps` for each place the page gives too
    little to carry one, which no gate reads."""
    forms, contract = doc["normalized"]["rules"], contract_of(root)
    gaps: list[dict] = []
    keys: list[dict] = []
    cx = shape_context(doc)
    for e in doc["term_entries"]:
        ma = member_answers(e) if e["kind"].get("Kind") == "Member" else []
        if ma:
            e["answers"] = ma
    for r in doc["rules"]:
        form = forms.get(r["label"], {})
        cm = cited_meaning(r, form, contract)
        if cm:
            r["cited_meaning"] = cm
        elif predicates(form) and CONTRACT_CITE.search(r["text"]) and contract:
            gaps.append({"rule": r["label"], "line": r["line"],
                         "what": "a predicate rests on an Execution Contract rule the contract does not carry"})
        cb = completed_by(form, doc["term_entries"])
        if cb:
            r["completed_by"] = cb
        elif (form.get("kind") == "rule" and r["family"] == "Operation"
              and any(o.get("exclusive") or o.get("only_if") for o in form.get("obligations", []))):
            gaps.append({"rule": r["label"], "line": r["line"],
                         "what": "a necessary condition on an answer, and no Operation or Member term entry gives the rest"})
        obs = form.get("obligations", []) if form.get("kind") == "rule" and r["family"] == "Operation" else []
        if (len(obs) == 1 and obs[0]["act"] == "answer" and obs[0].get("object") and not obs[0].get("exclusive")
                and not obs[0].get("only_if") and re.fullmatch(r"\[.+\]", form.get("subject", "").strip())
                and not re.fullmatch(r"[a-z]+(?:-[a-z]+)*", obs[0]["object"])
                and obs[0]["object"] not in {a.split("(")[0] for s in doc["signatures"] for a in s["answers"]}):
            shape, why = answer_shape(form, doc, cx)
            if shape:
                cited = cited_texts(r, contract)
                if cited:
                    shape["cited"] = cited
                r["answer_shape"] = shape
            else:
                gaps.append({"rule": r["label"], "line": r["line"], "what": "no answer shape read: " + why})
        if r["family"] == "Identity" and IDENTIFY.search(r["text"]):
            key, why = key_of(r, doc["terms"], doc["term_entries"])
            if key:
                keys.append(key)
            else:
                gaps.append({"rule": r["label"], "line": r["line"], "what": "no key read: " + why})
    doc["keys"] = keys
    doc["settings"], more = settings_of(doc, cx)
    gaps += more
    doc["term_sets"], more = term_sets_of(doc, cx)
    gaps += more
    doc["reader_gaps"] = gaps


def specs(root: Path) -> list[Path]:
    """The specs lint.py's load_patterns loads: atoms/ and compositions/, less
    the catalogues, the taxonomy proposal and every `.hist.md`. Found without
    reading them, so a spec that cannot be read is a finding of its own."""
    return sorted(md for d in PATTERN_DIRS for md in (root / d).rglob("*.md")
                  if md.name.lower() not in ("readme.md", "index.md", "taxonomy.md")
                  and not md.match(HISTORY_FILE))


def build(root: Path) -> tuple[list[dict], list[tuple[str, int, str, str]]]:
    """Every spec's document, and a finding for each spec the parser cannot read."""
    docs, findings = [], []
    for p in specs(root):
        try:
            docs.append(parse(p, root))
        except Exception as e:  # a spec the parser cannot read is a finding
            findings.append((p.relative_to(root).as_posix(), 1, "IR-unreadable",
                             f"the parser cannot read this spec: {type(e).__name__}: {e}"))
    return docs, findings


def prove(root: Path, docs: list[dict]) -> list[tuple[str, int, str, str]]:
    """The proof: each document's rule count equals cites.py's, every label is
    unique on its page, every rule a Check names exists, and every Composes
    entry resolves to a spec."""
    findings = []
    live = {d["name"]: {r["label"] for r in d["rules"]} for d in docs}
    dead = {d["name"]: {t["label"]: t for t in d["tombstones"]} for d in docs}
    by_path = {d["spec"] for d in docs}
    contract = contract_label_set(root) or set()
    for d in docs:
        rel = d["spec"]
        counted = cites.parse(root / rel).rules
        mine = {r["label"] for r in d["rules"]}
        if len(d["rules"]) != len(counted) or mine != set(counted):
            gone, extra = sorted(set(counted) - mine), sorted(mine - set(counted))
            findings.append((rel, 1, "IR-count",
                             f"{len(d['rules'])} rules in the IR, {len(counted)} by cites.py's count; "
                             f"cites.py only: {', '.join(gone) or 'none'}; IR only: {', '.join(extra) or 'none'}"))
        seen: Counter = Counter()
        for x in d["rules"] + d["tombstones"]:
            seen[x["label"]] += 1
            if seen[x["label"]] == 2:
                findings.append((x.get("file", rel), x["line"], "IR-label",
                                 f"label {x['label']} is used more than once on the page"
                                 + (" and its history file" if x.get("file", rel) != rel else "")))
        for c in d["checks"]:
            for cited in c["tests"]:
                why = unresolved(cited, d["name"], live, dead, contract)
                if why:
                    findings.append((rel, c["line"], "IR-check", f"{c['label']} names {cited}, {why}"))
        for e in d["composes"]:
            if e["path"] not in by_path:
                findings.append((rel, e["line"], "IR-composes",
                                 f"the Composes entry {e['name']} links {e['path']}, which is no spec"))
    return findings


def unresolved(cited: str, page: str, live: dict, dead: dict, contract: set) -> str | None:
    """Why a citation names no rule, or None when it does. A citation resolves
    on its own page first, then on the spec whose name it opens with, or on the
    Execution Contract's labels as lint.py reads them."""
    if cited.startswith("Execution Contract "):
        return resolve(cited[len("Execution Contract "):], contract, {}, "the Execution Contract")
    why = resolve(cited, live[page], dead[page], "the page")
    family = cites.NAME_NUM.sub("", cited.partition(" through ")[0])
    if not why or any(split_label(lab)[0] == family for lab in live[page] | set(dead[page])):
        return why  # the page's own family: `Capability requirement 7f` is no Capability rule
    owner = next((n for n in sorted(live, key=len, reverse=True)
                  if n != page and cited.startswith(n + " ")), None)
    return resolve(cited[len(owner) + 1:], live[owner], dead[owner], owner) if owner else why


def resolve(cited: str, labels: set, gone: dict, where: str) -> str | None:
    """A label resolves to a rule, or to a group: `Invariant 2` names `Invariant
    2.1` and on, as a range of majors covers its minors (cites.py's in_range),
    and `Operation 5` names a WHEN block's children. A range resolves when both
    its ends do (GRACE-lang Hard invariant 29). A tombstoned end is named with
    the owner its tombstone names, wherever the tombstone stands."""
    first, _, last = cited.partition(" through ")
    ends = [first]
    if last:
        m = cites.NAME_NUM.search(first)
        step = " step " if m.group(1).startswith(" step ") else " "
        ends.append(first[:m.start()] + step + last.removeprefix("step "))
    for end in ends:
        if end in labels or any(lab.startswith(end + ".") or re.fullmatch(re.escape(end) + "[a-z]", lab)
                                for lab in labels):
            continue
        if end in gone:
            t = gone[end]
            return f"which {where} tombstones ({t['file']}:{t['line']}: {t['text']})"
        return f"which no rule of {where} carries"
    return None


def emit(findings) -> None:
    for path, line, code, msg in findings:
        print(f"{path}:{line}: [{code}] {msg}")


def main(argv: list[str]) -> int:
    root = HERE.parents[1]
    args = [a for a in argv[1:] if not a.startswith("--")]
    if args:
        for a in args:
            print(json.dumps(parse(Path(a), root), indent=2, ensure_ascii=False))
        return 0
    docs, findings = build(root)
    findings += prove(root, docs)
    if "--check" not in argv:
        out = root / "build" / "ir"
        out.mkdir(parents=True, exist_ok=True)
        written = set()
        for d in docs:
            name = Path(d["spec"]).stem + ".json"
            (out / name).write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            written.add(name)
        for stale in out.glob("*.json"):
            if stale.name not in written:
                stale.unlink()  # a retired spec's document
    emit(findings)
    advisory = sum(len(normalize.findings(d, {x["spec"]: x for x in docs})) for d in docs)
    n_rules = sum(len(d["rules"]) for d in docs)
    n_checks = sum(len(d["checks"]) for d in docs)
    untested = sum(1 for d in docs for c in d["checks"] if not c["tests"])
    gaps = sum(len(d["reader_gaps"]) for d in docs)
    print(f"ir: {len(docs)} specs, {n_rules} rules, {n_checks} checks ({untested} naming no rule in a closing "
          f"citation); {len(findings)} finding(s); {advisory} advisory from normalize.py "
          f"(none gates); {gaps} reader gap(s) in {sum(1 for d in docs if d['reader_gaps'])} spec(s) "
          f"(none gates)", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

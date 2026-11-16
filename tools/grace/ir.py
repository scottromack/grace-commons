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
not give enough to carry one of these, `reader_gaps` says so (each with its `kind`)
and nothing is guessed. For every rule `projectable` says what a consumer may take it
as (`guard`, `shape`, `transition`, `wiring`, `step`, `key`, `check-only` or
`not-carried`), so that a consumer re-derives none of the reader's judgments.
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
    python3 tools/grace/ir.py --gaps           # the reader's gaps: spec by kind by count
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
import hashlib
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
                # a list that gives a family once and bare numbers after it (`Action wiring 2, 3, 12`) names every label in it:
                # cites.uses reads the first, so the rest are read here, with the same family-carrying reading as `references`
                for cell in cells(lines[j]):
                    # the cell as a list (an Owner cell), and each parenthesis in it (`one tag lands (Operation 1, 2, 3)`)
                    for item in references(cell) + [i for g in re.findall(r"\(([^()]*)\)", cell) for i in references(g)]:
                        if item in spec.rules:
                            named = set(named) | {item}
                        elif item.startswith("Execution Contract ") and " through " not in item and item not in contract:
                            contract.append(item)
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
        return [], f"the reader read no list of Field entries at the start of the definition of Term {term['name']}"
    return got, ""


ID_KEY = re.compile(r"the (?P<id>(?!.* and )[a-z]+(?: [a-z]+)* id)")


def id_key_of(rule: dict, thing: str, idterm: str, entries: list[dict], rules: list[dict] | None,
              forms: dict) -> tuple[dict | None, str]:
    """A key that is an id the system makes (`identify an event by the event id`): the Field entry named for the id, and the rule
    that says where it comes from, one that has the host or the atom `allocate` or `assign` it from the seam (`The host MUST allocate
    an event id at the atom's seam`). The key is carried only with both: the Field entry gives the field, the rule the source (`fresh`:
    a value the seam supplies, which the atom never makes). An id with no such rule, or no Field entry, is a reader gap."""
    field = next((e for e in entries if e["name"].lower() == idterm and e["kind"].get("Kind") == "Field"), None)
    if not field:
        return None, f"the reader found no Field entry `{idterm}` for the key `the {idterm}`"
    src = None
    for r in rules or []:
        f = forms.get(r["label"], {})
        if r["family"] != "Identity" or f.get("kind") != "rule":
            continue
        for o in f.get("obligations", []):
            if (o["modal"] == "MUST" and o["act"] in ("allocate", "assign")
                    and re.match(r"(?:an?|the) %s\b" % re.escape(idterm), o.get("object", ""))):
                src = {"how": "fresh", "rule": r["label"], "line": r["line"]}
    if not src:
        return None, f"the key `the {idterm}` is an id, and the reader read no Identity rule that says the host or the seam allocates it (it reads the Identity rules for this, not the Capability requirements)"
    return ({"rule": rule["label"], "line": rule["line"], "thing": thing, "term": idterm, "names": [idterm],
             "fields": [field["kind"].get("Projection") or field["name"]], "id": True, "source": src}, "")


def key_of(rule: dict, terms: list[dict], entries: list[dict], rules: list[dict] | None = None,
           forms: dict | None = None) -> tuple[dict | None, str]:
    """The key an Identity rule names: `identify a favorite by the favorite's
    pair` names the Term pair, and the fields are those the Term's definition
    lists at its start (`the person reference and the item reference ...`),
    each a Field entry, in the order the definition gives them. Returns the key,
    or None and what the page does not give."""
    m = IDENTIFY.search(rule["text"])
    if not m:
        return None, "the reader could not read the rule as `identify a <thing> by <the thing's term>`"
    mid = ID_KEY.fullmatch(m.group("by"))
    if mid:
        return id_key_of(rule, m.group("thing"), mid.group("id"), entries, rules, forms or {})
    k = KEY_TERM.fullmatch(m.group("by"))
    if not k or k.group("thing") != m.group("thing"):
        return None, f"the reader could not read the key `{m.group('by')}` as named through a Term of the form `the {m.group('thing')}'s <term>`"
    term = next((t for t in terms if t["name"].lower() == k.group("term").lower()), None)
    if not term:
        return None, f"the reader found no Term `{k.group('term')}` among the pattern's Terms"
    got, why = term_fields(term, entries)
    if not got:
        return None, why
    return ({"rule": rule["label"], "line": rule["line"], "thing": m.group("thing"), "term": term["name"],
             "names": [e["name"].lower() for e in got],
             "fields": [e["kind"].get("Projection") or e["name"] for e in got]}, "")


# an answer that is a shape, not an arm of the signature: what the read side of a page says it answers
SHAPE_COUNT = re.compile(r"the (?P<count>.+?) of EVERY (?P<by>.+?) an? (?P<what>.+?) carrying (?P<x>.+?) carries$")
SHAPE_EVERY = re.compile(r"(?:the (?P<of>.+?) of )?EVERY (?P<what>.+?) carrying (?P<x>.+)$")
SHAPE_FIELDS = re.compile(r"(?:an?|the) (?P<thing>.+?)'s (?P<fields>.+)$")
SHAPE_STORED = re.compile(r"(?:an?|the) (?P<thing>.+?)'s stored fields$")
SHAPE_EMPTY = re.compile(r"an empty list(?: for (?:an?|the) (?P<x>.+?) no (?P<what>.+?) carries)?$")
SHAPE_EMPTY_QUERY = re.compile(r"an empty (?:[a-z]+ )?(?:list|sequence) for a well-formed query (?:matching nothing|no (?P<what>.+?) matches)$")
SHAPE_MATCHING = re.compile(r"(?:EVERY (?P<thing>.+?)|the (?P<things>.+?)) the (?P<by>.+?) matches$")
SHAPE_PAGE = re.compile(r"the matching (?P<thing>.+?) with the earliest (?P<key>.+?), up to the (?P<limit>.+)$")
SHAPE_NONE = re.compile(r"no (?P<thing>.+)$")
SHAPE_BY = re.compile(r"(?P<arm>.+?) by (?P<by>.+)$")
SHAPE_CODEPOINT = re.compile(r"(?P<arm>.+?) in codepoint order(?: of (?P<of>.+))?$")
DIRECTIONS = {"earliest first": "ascending", "oldest first": "ascending", "ascending": "ascending",
              "latest first": "descending", "newest first": "descending", "descending": "descending"}
MEMBER_ANSWER = re.compile(r"\[(?P<op>[^\]]+)\]'s answer for one(?: and for (?:an?|the) [^.;,]*? with no (?P<none>[a-z ]+?))?(?=[.;,]|$)")


def field_types(entries: list[dict]) -> list[str]:
    """The record types the Field entries name, each once, in page order: `Field of: the notification record` names `notification`."""
    out: list[str] = []
    for e in entries:
        if e["kind"].get("Kind") == "Field":
            t = re.sub(r"^(?:the|a|an) ", "", e["kind"].get("Field of", "").strip().lower())
            t = t.removesuffix(" record")
            if t and t not in out:
                out.append(t)
    return out


def shape_context(doc: dict) -> dict:
    """The names a shape resolves through: the record type, its Field entries,
    and the Member entries of its status, each by lower-cased name. The record
    type is the Type entry's name; a page with none gives it through its Field
    entries (`Field of: the <type> record`), and only where they name one type."""
    entries = doc["term_entries"]
    rtype = next((e for e in entries if e["kind"].get("Kind") == "Type" and "Projection" not in e["kind"]), None)
    named = field_types(entries)
    if not rtype and len(named) == 1:
        rtype = {"name": named[0]}
    fields = {e["name"].lower(): e["kind"].get("Projection") or e["name"]
              for e in entries if e["kind"].get("Kind") == "Field"}
    members = {e["name"].lower(): (e["kind"].get("Member of", "").removeprefix("the ").lower(), e["kind"].get("Projection") or e["name"].lower())
               for e in entries if e["kind"].get("Kind") == "Member"}
    owners = {e["name"].lower(): re.sub(r"^(?:the|a|an) ", "", e["kind"].get("Field of", "").strip().lower()).removesuffix(" record")
              for e in entries if e["kind"].get("Kind") == "Field"}
    return {"type": rtype["name"].lower() if rtype else None, "fields": fields, "members": members, "owners": owners,
            "types": ([rtype["name"].lower()] if rtype else []) + [t for t in named if not rtype or t != rtype["name"].lower()],
            "terms": {t["name"].lower(): t for t in doc["terms"]}, "entries": entries}


def thing_of(phrase: str, cx: dict) -> str | None:
    """The record type a shape's noun names: the record type or a type a Field entry names, the noun read as written, without a trailing `record`, or as the
    regular plural of either (`the holds` is `hold`, `owed records` is `owed record`). None where the page names no such type; nothing is guessed."""
    t = re.sub(r"^(?:the|a|an) ", "", phrase.strip().lower())
    for c in (t, t.removesuffix(" record"), t.removesuffix("s"), t.removesuffix("s").removesuffix(" record")):
        if c in cx["types"]:
            return c
    return None


def fields_of(thing: str, parts: list[str], cx: dict) -> tuple[list[str], str]:
    """Each part names a Field entry of the record type `thing` (`the gift card's balance` names it with its possessive); -> the projections, or what the page does not give"""
    out = []
    for part in parts:
        m = re.match(r"^(?:an?|the) (?P<t>.+?)'s (?P<f>.+)$", part.strip())
        if m and thing_of(m.group("t"), cx) != thing:
            return [], f"the reader read `{part.strip()}` as naming a record that is not `{thing}`"
        name = (m.group("f") if m else part).strip()
        f = field_of(name, cx)
        if not f:
            return [], f"the reader found no Field entry `{name}`"
        if cx["owners"].get(re.sub(r"^(?:the|a|an) ", "", name).lower()) != thing:
            return [], f"`{name}` is a Field entry of another record than `{thing}`"
        out.append(f)
    return out, ""


def names_an_arm(obj: str, doc: dict) -> bool:
    """An answer that is an arm of the signatures in another spelling (`the notification id` for `notification_id`, `EVERY attestation` for `every attestation`) is the arm, not a shape"""
    spell = lambda x: re.sub(r"[^a-z0-9]+", "_", re.sub(r"^(?:the|a|an) ", "", x.strip().lower())).strip("_")
    return spell(obj) in {spell(a.split("(")[0]) for sg in doc["signatures"] for a in sg["answers"]}


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
        return [], f"the reader read `{phrase.strip()}` as not ending in the record type"
    where = []
    for w in words[:-len(cx["type"].split())]:
        if w not in cx["members"]:
            return [], f"the reader found no Member entry `{w}`"
        field, value = cx["members"][w]
        if field not in cx["fields"] and field.startswith(cx["type"] + " "):
            field = field[len(cx["type"]) + 1:]       # `Member of: the notification status` is the Field entry `status`
        if field not in cx["fields"]:
            return [], f"the reader read `{w}` as a Member of `{field}`, and found no Field entry `{field}`"
        where.append({"field": cx["fields"][field], "value": value})
    return where, ""


def answer_shape(form: dict, doc: dict, cx: dict) -> tuple[dict | None, str]:
    """For an Operation rule that answers something that is no arm of its
    action's signature, the shape it says, with every noun resolved to the
    projection of the Field entry or Member entry it names: `every` (the
    records carrying a field set, a status test, and the fields answered),
    `fields` (the fields of one record), `record` (all of them), `empty` (an empty
    list, or an empty sequence for a well-formed query), `count_by` (a count of the
    records by one field), `matching` (the records a Term of the page says match),
    `page` (the matching records by a listing key, up to a page size, each a Term of
    the page), `none` (no record) and `order` (the arm's rows ordered by fields,
    each with a direction). Returns the shape, or None and what the page does
    not give; nothing is guessed."""
    sigs = {re.sub(r"[^a-z0-9]+", "_", s["action"].lower()).strip("_"): s for s in doc["signatures"]}
    sub = re.fullmatch(r"\[(.+)\]", form.get("subject", "").strip())
    action = re.sub(r"[^a-z0-9]+", "_", sub.group(1).lower()).strip("_") if sub else None
    sig = sigs.get(action)
    if not sig:
        return None, "the reader read the rule's subject as no action of the pattern's signatures"
    ob = form["obligations"][0]["object"]
    arms = []
    for a in sig["answers"]:
        m = re.fullmatch(r"([a-z_]+)\((.*)\)", a)
        if m:
            arms.append({"name": m.group(1), "fields": [x.strip() for x in m.group(2).split(",") if x.strip()]})
    arm = arms[0] if len(arms) == 1 else None
    out: dict | None = None
    m = SHAPE_STORED.fullmatch(ob)
    if m:
        thing = thing_of(m.group("thing"), cx)
        own = next((x for x in sig["answers"] if thing and re.sub(r"[^a-z0-9]+", "_", x.lower()).strip("_") == re.sub(r"[^a-z0-9]+", "_", thing).strip("_")), None)
        stored = [e["kind"].get("Projection") or e["name"] for e in cx["entries"]
                  if e["kind"].get("Kind") == "Field" and thing and cx["owners"].get(e["name"].lower()) == thing]
        if not thing or not stored:
            return None, f"the reader read `{ob}` as naming no record type of the pattern, or a record with no Field entry"
        if not own:
            return None, f"`{ob}`: the reader read no answer arm of {sig['action']} named for the record type `{thing}`"
        out = {"shape": "record", "thing": thing, "fields": stored, "arm": own}
    m = None if out else SHAPE_COUNT.fullmatch(ob)
    if m:
        by, what, x = field_of(m.group("by"), cx), what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
        if not by or what[1] or x[1]:
            return None, (what[1] or x[1] or f"the reader found no Field entry `{m.group('by')}`")
        out = {"shape": "count_by", "count": m.group("count"), "by": by, "thing": cx["type"], "where": what[0], "carrying": x[0]}
    m = None if out else SHAPE_EVERY.fullmatch(ob)
    if m:
        what, x = what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
        of = [field_of(m.group("of"), cx)] if m.group("of") else []
        if what[1] or x[1] or (m.group("of") and not of[0]):
            return None, what[1] or x[1] or f"the reader found no Field entry `{m.group('of')}`"
        out = {"shape": "every", "thing": cx["type"], "where": what[0], "carrying": x[0], "of": of}
    m = None if out else SHAPE_FIELDS.fullmatch(ob)
    if m:
        thing = thing_of(m.group("thing"), cx)
        fs, why = fields_of(thing, re.split(r",\s*(?:AND\s+)?|\s+AND\s+", m.group("fields")), cx) if thing else ([], f"the reader read `{m.group('thing')}` as no record type of the pattern")
        if why:
            return None, why
        out = {"shape": "fields", "thing": thing, "fields": fs}
    m = None if out else SHAPE_EMPTY.fullmatch(ob)
    if m:
        out = {"shape": "empty"}
        if m.group("x"):
            what, x = what_of(m.group("what"), cx), carrying_of(m.group("x"), cx)
            if what[1] or x[1]:
                return None, what[1] or x[1]
            out.update({"thing": cx["type"], "where": what[0], "carrying": x[0]})
    m = None if out else SHAPE_EMPTY_QUERY.fullmatch(ob)
    if m:
        thing = thing_of(m.group("what"), cx) if m.group("what") else None
        if "query" not in cx["terms"] or (m.group("what") and not thing):
            return None, f"`{ob}`: the reader found no Term `query` on the pattern, or read `{m.group('what')}` as no record type of the pattern"
        out = {"shape": "empty", "query": "query"}
        if thing:
            out["thing"] = thing
    m = None if out else SHAPE_MATCHING.fullmatch(ob)
    if m:
        thing, by = thing_of(m.group("thing") or m.group("things"), cx), (m.group("by") or "").strip().lower()
        if not thing or by not in cx["terms"]:
            return None, f"`{ob}`: the reader read `{m.group('thing') or m.group('things')}` as no record type of the pattern, or found no Term `{by}` on it"
        out = {"shape": "matching", "thing": thing, "by": by}
    m = None if out else SHAPE_PAGE.fullmatch(ob)
    if m:
        thing = thing_of(m.group("thing"), cx)
        said = m.group("thing").strip().lower()
        matching = next((f"matching {c}" for c in (said, said.removesuffix("s")) if f"matching {c}" in cx["terms"]), f"matching {said}")
        key = m.group("key").strip().lower()
        key = next((c for c in (key, key.removesuffix("s")) if c in cx["terms"]), key)
        names = {"matching": matching, "order": key, "limit": m.group("limit").strip().lower()} if thing else {}
        if not thing or not all(n in cx["terms"] for n in names.values()):
            return None, f"`{ob}`: the reader read `{m.group('thing')}` as no record type of the pattern, or found none of the three Terms it names"
        out = {"shape": "page", "thing": thing, "direction": "ascending", **{k: v for k, v in names.items()}}
    m = None if out else SHAPE_NONE.fullmatch(ob)
    if m:
        thing = thing_of(m.group("thing"), cx)
        if not thing:
            return None, f"`{ob}`: the reader read `{m.group('thing')}` as no record type of the pattern"
        out = {"shape": "none", "thing": thing}
    m = None if out else SHAPE_CODEPOINT.fullmatch(ob)
    if m:
        name = re.sub(r"[^a-z0-9]+", "_", m.group("arm").lower()).strip("_")
        own = next((a for a in arms if a["name"] == name), None)
        by = [field_of(m.group("of"), cx)] if m.group("of") else (own["fields"][:1] if own and len(own["fields"]) == 1 else [])
        if not own or not by or not by[0]:
            return None, f"the reader read `{m.group('arm')}` as naming no arm of the signature with one field to order by"
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
            return None, f"the reader read `{ob}` as ordering by something with no Field entry, or by an arm that is no arm of the signature"
        out = {"shape": "order", "arm": own["name"], "by": keys}
    if not out:
        return None, f"the reader reads no shape in `{ob}`"
    out["arm"] = out.get("arm") or (arm["name"] if arm else None)
    out["arm_fields"] = arm["fields"] if arm else []
    return out, ""


# the order Execution Contract Read 5 states for a read that answers many records and names none
READ_5 = re.compile(r"answers them by each record's creation instant, earliest first, then by id ascending")


def read_orders(doc: dict, cx: dict, keys: list[dict], contract: dict[str, dict]) -> list[dict]:
    """A read that answers many records, whose page names no order but cites Execution Contract Read 5 on the read's own Operation
    entry (`in the order Execution Contract Read 5 states`), answers them in the order Read 5 states: the records' creation instant
    (the Field entry the contract's words name, `creation instant`), earliest first, then the id the page's key is, ascending. Added to the
    shape as `order_default`; where the page lacks either field the order is a reader gap and the shape carries none."""
    gaps: list[dict] = []
    read5 = contract.get("Read 5")
    ids = [k for k in keys if k.get("id") and k["thing"].lower() == cx["type"]]
    for r in doc["rules"]:
        sh = r.get("answer_shape")
        if not sh or sh["shape"] != "every" or not read5 or not READ_5.search(read5["text"]):
            continue
        acts = r.get("actions", [])
        if any(o.get("answer_shape", {}).get("shape") == "order" and set(o.get("actions", [])) & set(acts) for o in doc["rules"]):
            continue                 # the page names an order for this read
        entry = next((e for e in doc["term_entries"] if e["kind"].get("Kind") == "Operation"
                      and re.sub(r"[^a-z0-9]+", "_", e["name"].lower()).strip("_") in acts), None)
        if not entry or "Execution Contract Read 5" not in [c["label"] for c in cited_texts({"text": entry["text"]}, contract)]:
            continue
        made = cx["fields"].get("creation instant")
        if not made or len(ids) != 1:
            gaps.append({"rule": r["label"], "line": r["line"],
                         "kind": "no-order", "what": "the read's order is Execution Contract Read 5's, which needs the record's creation instant "
                                 f"and its id: the reader found {'no Field entry `creation instant`' if not made else 'no one id key'}"})
            continue
        sh["order_default"] = {"rule": "Execution Contract Read 5",
                               "by": [{"field": made, "direction": "ascending"}, {"field": ids[0]["fields"][0], "direction": "ascending"}]}
    return gaps


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
                         "kind": "no-default", "what": f"no default read: the reader read no default in the Term `{m.group('term')}` (what stands where a deployment declares none)"})
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
            gaps.append({"rule": f"Term {t['name']}", "line": t["line"], "kind": "no-set", "what": "no set read: the reader could not fit the definition, which says `other than`, to `a <member> <thing> carrying the <term> of the call and a <field> other than the <field> of the call`"})
            continue
        where, why = what_of(m.group("what"), cx)
        carrying, why2 = carrying_of(m.group("by"), cx)
        other, same = field_of(m.group("other"), cx), field_of(m.group("same"), cx)
        if why or why2 or not other or other != same:
            gaps.append({"rule": f"Term {t['name']}", "line": t["line"], "kind": "no-set", "what": "no set read: " + (why or why2 or "the reader read the field that differs as not the field the call names")})
            continue
        out.append({"term": t["name"], "line": t["line"], "thing": cx["type"], "where": where, "carrying": carrying, "other_than": other})
    return out, gaps

CALL_OBJECT = re.compile(r"^(?P<who>[A-Z][A-Za-z ]*?)'s (?P<act>[a-z][a-z_-]*)(?: with (?P<args>.+?)| for (?P<each>.+?)| (?P<note>.+?))?$")
ANSWERS_CLAUSE = re.compile(r"^(?P<who>[A-Z][A-Za-z ]*?)'s (?P<act>[a-z][a-z_-]*) answers (?P<arms>[a-z][a-z-]*(?: OR [a-z][a-z-]*)*)(?P<rest> for .+)?$")
# an answer the Execution Contract gives every read (Read 3), which no signature lists
CONTRACT_ARMS = {"state-unavailable"}
ARG_SPLIT = re.compile(r",\s*(?:AND\s+)?|\s+AND\s+")
IN_ONE_TX = re.compile(r"^(?P<writes>.+?) in one transaction$")
IN_TX_OF = re.compile(r"^(?P<writes>.+?) in the transaction of (?P<label>[A-Z][A-Za-z ]*? \d+[a-z]?)$")


def light(path: Path) -> dict | None:
    """What a composition reads of a constituent: its signatures and its term entries, and
    nothing that carries (so a composition's constituent that is itself a composition does
    not send the reader down its own constituents)."""
    if not path.is_file():
        return None
    lines = path.read_text(encoding="utf-8").split("\n")
    _, _, entries = walk_terms(cites.parse(path), lines, outline(lines))
    return {"signatures": walk_signatures(lines), "term_entries": entries}


def bind_arg(phrase: str, action: str, inputs: list[str], entries: list[dict]) -> dict | None:
    """One argument phrase of a call, bound to the callee's input the callee's own term entry
    names: an entry whose name is the phrase and whose Projection is one of the action's
    inputs (a Parameter entry only for that action). By name through the entry, never by
    resemblance: 'the cascade reason' is no entry of Session, and stays unbound."""
    want = re.sub(r"^(?:the|a|an)\s+", "", phrase.strip(), flags=re.I).lower()
    for e in entries:
        k = e["kind"]
        if e["name"].lower() != want or k.get("Projection") not in inputs:
            continue
        if k.get("Parameter of") and k["Parameter of"].lower() != action.lower():
            continue
        return {"phrase": phrase, "binds": k["Projection"], "entry": e["name"]}
    return None


def input_entries(action: str, inputs: list[str], entries: list[dict]) -> str:
    """For a binding gap, what bind_arg could have bound to: each input of the callee's action with the term entry that names it (a Projection that is
    the input, a Parameter entry only for that action), and the inputs with no such entry, which no phrase of the caller can bind to."""
    named: dict[str, str] = {}
    for e in entries:
        k = e["kind"]
        if k.get("Projection") in inputs and (not k.get("Parameter of") or k["Parameter of"].lower() == action.lower()):
            named.setdefault(k["Projection"], e["name"])
    have = [f"{i} (entry `{named[i]}`)" for i in inputs if i in named]
    lack = [i for i in inputs if i not in named]
    return (f"its inputs with a term entry: {', '.join(have) or 'none'}; its inputs with no Parameter or Field entry naming them: "
            f"{', '.join(lack) or 'none'}")


def wiring_of(doc: dict, root: Path) -> tuple[list[dict], list[dict], list[dict]]:
    """A composition's calls to its constituents and the tests it makes on their answers,
    read through the constituents' own signatures and term entries (additions only; a
    phrase that binds to no input, or an answer that is no arm, is a reader gap and
    nothing is guessed). `calls`: for each `call` obligation of the form `<Constituent>'s
    <action>` [`with` <arguments> | `for` <each>], the constituent, its path, the action as
    its signature names it, and each argument with the input it binds to; `answer_tests`:
    for each condition of the form `<Constituent>'s <action> answers <arm>`, the arms."""
    if doc["kind"] != "composition":
        return [], [], []
    view = {c["name"]: (c, light(root / c["path"])) for c in doc["composes"]}
    calls, tests, gaps = [], [], []

    def callee(who: str, act: str, rule: dict, where: str):
        if who not in view or view[who][1] is None:
            gaps.append({"rule": rule["label"], "line": rule["line"], "kind": "no-constituent", "what": f"the reader read {who} as no constituent the Composes section links, or found its pattern absent"})
            return None
        c, v = view[who]
        sig = next((s for s in v["signatures"] if snake_of(s["action"]) == snake_of(act)), None)
        if sig is None:
            gaps.append({"rule": rule["label"], "line": rule["line"], "kind": "no-action", "what": f"the reader found no action {act!r} on the signature list of {who} ({where})"})
            return None
        return c, v, sig

    for r in doc["rules"]:
        form = doc["normalized"]["rules"].get(r["label"], {})
        if form.get("kind") != "rule":
            continue
        for o in form.get("obligations", []):
            m = CALL_OBJECT.match(o.get("object", "")) if o.get("act") == "call" else None
            if not m:
                continue
            got = callee(m.group("who"), m.group("act"), r, "a call")
            if not got:
                continue
            c, v, sig = got
            inputs = [i["name"] for i in sig["inputs"]]
            entry = {"rule": r["label"], "line": r["line"], "modal": o.get("modal"), "constituent": c["name"],
                     "path": c["path"], "action": sig["action"], "args": []}
            for t in o.get("timing", []):
                if t.get("kind") == "ONLY AFTER":
                    entry["only_after"] = t["term"]
            if m.group("each"):
                entry["each"] = m.group("each")
            if m.group("note"):
                entry["note"] = m.group("note")
            for phrase in ARG_SPLIT.split(m.group("args") or ""):
                if not phrase.strip():
                    continue
                if phrase.strip() == "now":
                    entry["args"].append({"phrase": "now", "binds": None, "clock": True})
                    continue
                b = bind_arg(phrase, sig["action"], inputs, v["term_entries"])
                entry["args"].append(b or {"phrase": phrase.strip(), "binds": None})
                if not b:
                    gaps.append({"rule": r["label"], "line": r["line"], "kind": "no-binding", "what": f"the reader bound {phrase.strip()!r} to no input of {c['name']}'s {sig['action']} through its term entries"
                                 f"; {input_entries(sig['action'], inputs, v['term_entries'])}"})
            calls.append(entry)
        last = None
        for cl in (form.get("if") or {}).get("clauses", []):
            m = ANSWERS_CLAUSE.match(cl.get("text", ""))
            if not m and last and re.fullmatch(r"[a-z][a-z-]*", cl.get("text", "")):
                # `answers expired OR revoked`: the grammar splits the OR, the second clause is a bare arm
                n = cl["text"]
                if n in last[1]:
                    last[0]["arms"].append(n)
                else:
                    gaps.append({"rule": r["label"], "line": r["line"], "kind": "no-arm", "what": f"the reader read {n!r} as no arm of {last[0]['constituent']}'s {last[0]['action']} (its arms: {sorted(last[1])})"})
                continue
            if not m:
                last = None
                continue
            got = callee(m.group("who"), m.group("act"), r, "an answer test")
            if not got:
                continue
            c, v, sig = got
            arms = {a.split("(")[0] for a in sig["answers"] + sig["refuses"]} | CONTRACT_ARMS
            names = m.group("arms").split(" OR ")
            test = {"rule": r["label"], "line": r["line"], "constituent": c["name"], "path": c["path"],
                    "action": sig["action"], "arms": [n for n in names if n in arms]}
            if m.group("rest"):
                test["for"] = m.group("rest").strip()[4:]
            for n in names:
                if n not in arms:
                    gaps.append({"rule": r["label"], "line": r["line"], "kind": "no-arm", "what": f"the reader read {n!r} as no arm of {c['name']}'s {sig['action']} (its arms: {sorted(arms)})"})
            tests.append(test)
            last = (test, arms)
    return calls, tests, gaps


def snake_of(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


ADMITTED_SUBJECT = re.compile(r"(?:an? |the )?admitted ([a-z][a-z0-9 -]*)", re.I)
# a Term `admitted <action>` whose definition says no more of the call than that the action admits it, that no rule refused it, or that it answers
ADMITTED_CALL = re.compile(r"an? \[([^\]]+)\] call(?: the action admits| no rule refused| that answers)?(?: \([^)]*\))?\.?")
ACTION_LIST = re.compile(r"(?:(?:an?|the) )?\[[^\]]+\](?:(?:,\s*|\s+(?:and|or)\s+)(?:(?:an?|the) )?\[[^\]]+\])*(?:\s+calls?)?\.?")


# a Term that names a set of actions by a bar list (`[Suspend Pool] | [Resume Pool] | [Close Pool]`), by the complement of a list (`every action but [Query]`),
# or by an input every one of them carries (`any action carrying a pool id`; the signatures say which)
BAR_LIST = re.compile(r"\[[^\]]+\](?:\s*\|\s*\[[^\]]+\])+\.?")
EVERY_BUT = re.compile(r"every action but (\[[^\]]+\](?:(?:,\s*|\s+(?:and|or)\s+)\[[^\]]+\])*)\.?")
CARRYING = re.compile(r"any action carrying (?:an? |the )?([a-z][a-z0-9 -]*?)\.?")


def action_set_of(head: str, sigs: list[dict]) -> list[str] | None:
    """The actions a Term's head names where it names a set by a bar list, a complement (`every action but [X]`) or an input the actions carry
    (`any action carrying a pool id`: the signatures that take that input), resolved against the page's own signatures. None where the head is
    no such form; an empty list where it is one and the signatures do not resolve it (an action no signature carries, or an input none takes)."""
    names = {snake_of(s["action"]) for s in sigs}
    if BAR_LIST.fullmatch(head):
        got = [snake_of(x) for x in re.findall(r"\[([^\]]+)\]", head)]
        return got
    m = EVERY_BUT.fullmatch(head)
    if m:
        out = {snake_of(x) for x in re.findall(r"\[([^\]]+)\]", m.group(1))}
        return [a for a in (snake_of(s["action"]) for s in sigs) if a not in out] if out <= names else []
    m = CARRYING.fullmatch(head)
    if m:
        want = snake_of(m.group(1))
        return [snake_of(s["action"]) for s in sigs if want in {snake_of(i["name"]) for i in s["inputs"]}]
    return None


def actions_of(subject: str, terms: list[dict], sigs: list[dict] | None = None) -> list[str]:
    """The actions a rule's subject names, as the signatures spell them: a bracketed action (`[Deliver]`), or a Term whose
    definition begins with a list of them (`a terminal transition` is `a [Deliver], a [Fail] or an [Expire] call`). A subject
    that names none (`A refused call`, `A caller`) names none; an action named and on no signature is still named here, for
    the reader of the document to say. A Term whose definition begins with a bar list of them, with `every action but` a list of them or with
    `any action carrying` an input names those the signatures give (`action_set_of`); a set the signatures do not resolve names none. An `admitted <action>` Term is the call of that action where its definition says no more
    of the call than that the action admits it, that no rule refused it, or that it answers (`an [Order] call the action admits`) and
    the action its bracket names is the one its name does; a call narrowed by anything else (`a [Fire] call whose tasks ...`) names none."""
    m = re.fullmatch(r"\[(.+)\]", subject.strip())
    if m:
        return [snake_of(m.group(1))]
    t = next((t for t in terms if t["name"].lower() == re.sub(r"^(?:a|an|the) ", "", subject.strip(), flags=re.I).lower()), None)
    head = t["definition"].split(" \u2014 ")[0].strip() if t else ""
    if head and ACTION_LIST.fullmatch(head):
        return [snake_of(x) for x in re.findall(r"\[([^\]]+)\]", head)]
    if head and sigs is not None:
        got = action_set_of(head, sigs)
        if got:
            return got
    adm = ADMITTED_SUBJECT.fullmatch(subject.strip())
    call = ADMITTED_CALL.fullmatch(head) if adm and t else None
    if call and snake_of(call.group(1)) == snake_of(adm.group(1)):
        return [snake_of(call.group(1))]
    return []


def unresolved_set(subject: str, doc: dict) -> bool:
    """True where the subject is a Term whose head is a set of actions by a form `action_set_of` reads and the signatures resolve it to none"""
    t = next((t for t in doc["terms"] if t["name"].lower() == re.sub(r"^(?:a|an|the|every|any|each) ", "", subject.strip(), flags=re.I).lower()), None)
    head = t["definition"].split(" \u2014 ")[0].strip() if t else ""
    return bool(head) and action_set_of(head, doc["signatures"]) == []


def bracketed_head(subject: str, doc: dict) -> str:
    """The head of the definition of the Term a rule's subject names, where it is a list of bracketed actions that `actions_of` read as none for the period it
    ends in (`[Record Sighting], [Report Standing] or [Report Clear].`): '' where it is not. The rule names no action, which the reader says, since a consumer
    that reads the Term itself reads actions the reader did not. A call narrowed by anything else (`a [Fire] call whose tasks ...`) names none by design and is no gap."""
    t = next((t for t in doc["terms"] if t["name"].lower() == re.sub(r"^(?:a|an|the|every|any|each) ", "", subject.strip(), flags=re.I).lower()), None)
    head = t["definition"].split(" \u2014 ")[0].strip() if t else ""
    return head if ACTION_LIST.fullmatch(head.rstrip(". ")) and not actions_of(subject, doc["terms"], doc["signatures"]) else ""


def transitions_of(doc: dict, cx: dict) -> tuple[list[dict], list[dict]]:
    """For each action whose call names an existing record by its id (every field of an id key is an input of the signature) and
    stands it in a state (`[Deliver] MUST stand the notification in delivered`): the state it stands (a Member entry of a Field
    entry), the states it may stand from (the rule that refuses every other: `IF the notification's status DOES NOT EQUAL pending
    THEN ... answer not-pending`), the answer where no record carries the id, and the stamp the transition makes (the Term the stamp
    rule names lists Field entries, and the Invariant `A <thing> carrying <stamp> MUST stand in <state>` pairs each with its state).
    A part the page does not give is a reader gap and the transition is not carried; nothing is guessed."""
    keys = [k for k in doc.get("keys", []) if k.get("id")]
    if len(keys) > 1:
        return [], [{"rule": keys[1]["rule"], "line": keys[1]["line"], "kind": "no-transition",
                     "what": f"no transition read: the pattern names {len(keys)} id keys ({', '.join(k['thing'] for k in keys)}), and the reader carries transitions for a pattern that names one"}]
    if not keys:
        return [], []
    key, thing = keys[0], keys[0]["thing"]
    forms = doc["normalized"]["rules"]
    sigs = {snake_of(s["action"]): s for s in doc["signatures"]}
    fields = {e["name"].lower(): e for e in doc["term_entries"] if e["kind"].get("Kind") == "Field"}
    of_thing = {thing, f"the {thing} record", f"a {thing} record"}
    record_fields = [e["kind"].get("Projection") or e["name"] for e in fields.values()
                     if e["kind"].get("Field of", "").lower() in of_thing]
    pairs = {}      # a stamp's Field entry name -> (the state a record carrying it stands in, the rule)
    for r in doc["rules"]:
        f = forms.get(r["label"], {})
        for o in f.get("obligations", []) if f.get("kind") == "rule" else []:
            m = re.fullmatch(r"an? %s carrying (.+)" % re.escape(thing), f.get("subject", ""), re.I)
            n = re.fullmatch(r"in (.+)", o.get("object", ""))
            if m and n and o["modal"] == "MUST" and o["act"] == "stand":
                pairs[m.group(1).lower()] = (n.group(1), r["label"])
    out, gaps = [], []
    for action, sig in sigs.items():
        if not set(key["fields"]) <= {snake_of(i["name"]) for i in sig["inputs"]}:
            continue
        mine = [r for r in doc["rules"] if action in r.get("actions", []) and r["family"] in ("Operation", "State")]
        stands = []
        for r in mine:
            f = forms.get(r["label"], {})
            obs = f.get("obligations", []) if f.get("kind") == "rule" and not f.get("if") else []
            m = re.fullmatch(r"the %s in ([a-z-]+)" % re.escape(thing), obs[0].get("object", "")) if len(obs) == 1 and obs[0]["act"] == "stand" and obs[0]["modal"] == "MUST" else None
            if m:
                stands.append((r, m.group(1)))
        if not stands:
            continue                    # a call that only reads the record: no transition
        if len(stands) != 1:
            gaps.append({"rule": stands[1][0]["label"], "line": stands[1][0]["line"],
                         "kind": "no-transition", "what": f"no transition read: {action} names a {thing} by its id and stands it in {len(stands)} states: the reader carries one"})
            continue
        (sr, value), = stands
        member = cx["members"].get(value)
        fname = (member[0] if member else "").removeprefix("the ")
        fent = fields.get(fname) or fields.get(fname.removeprefix(thing + " "))
        if not member or not fent:
            gaps.append({"rule": sr["label"], "line": sr["line"], "kind": "no-transition", "what": f"no transition read: the reader found `{value}` in no Member entry of a Field entry"})
            continue
        refusals = set(sig["refuses"]) | set(a.split("(")[0] for a in sig["answers"])

        def answer_of(f):
            o = f.get("obligations", [{}])[0]
            return o.get("object") if len(f.get("obligations", [])) == 1 and o.get("act") == "answer" and o["modal"] == "MUST" and o.get("object") in refusals else None
        absent = frm = None
        for r in mine:
            f = forms.get(r["label"], {})
            if f.get("kind") != "rule" or not f.get("if") or len(f["if"]["clauses"]) != 1 or not answer_of(f):
                continue
            cl = f["if"]["clauses"][0]
            if cl["kind"] == "absence" and cl.get("thing") == thing and cl.get("qualifier") == "for the " + key["term"]:
                absent = {"rule": r["label"], "line": r["line"], "answer": answer_of(f)}
            elif (cl["kind"] == "comparison" and cl["op"] == "DOES NOT EQUAL" and cl["left"] == f"the {thing}'s {fent['name'].lower()}"
                  and cl["right"] in cx["members"]):
                frm = {"rule": r["label"], "line": r["line"], "values": [cl["right"]], "answer": answer_of(f)}
        stamp, spend = None, None
        for r in mine:
            f = forms.get(r["label"], {})
            o = f.get("obligations", [{}])[0] if f.get("kind") == "rule" and len(f.get("obligations", [])) == 1 else {}
            m = re.fullmatch(r"(.+) from the injected (?:now|clock)", o.get("object", "")) if o.get("act") == "stamp" and o["modal"] == "MUST" and not f.get("if") else None
            if not m:
                continue
            term = cx["terms"].get(re.sub(r"^(?:the |a |an )?(?:[a-z -]+'s )?", "", m.group(1).strip(), flags=re.I).lower())
            names = [x.strip().lower() for x in term["definition"].split(" \u2014 ")[0].split("|")] if term else []
            if m.group(1).strip().lower() in fields:
                names = [m.group(1).strip().lower()]
            paired = [n for n in names if n in pairs and pairs[n][0] == value and n in fields]
            if len(paired) == 1:
                stamp = {"rule": r["label"], "line": r["line"], "field": fields[paired[0]]["kind"].get("Projection") or fields[paired[0]]["name"],
                         "paired_by": pairs[paired[0]][1]}
            else:
                spend = {"rule": r["label"], "line": r["line"], "kind": "no-transition", "what": f"no transition read: the reader read no Invariant of the form `a {thing} carrying <stamp> MUST stand in <state>` that pairs the stamp `{m.group(1)}` with `{value}`"}
        missing = [name for part, name in ((absent, "what is answered where no %s carries the id" % thing), (frm, "which states it may stand it from")) if not part]
        if spend:
            gaps.append(spend)
        if missing:
            gaps.append({"rule": sr["label"], "line": sr["line"],
                         "kind": "no-transition", "what": f"no transition read: {action} stands the {thing} its id names in {value}, and the reader read no rule that says {' or '.join(missing)}"})
        if absent and frm and not spend:
            out.append({"action": action, "thing": thing, "key": key["rule"], "id": list(key["fields"]),
                        "stands": {"rule": sr["label"], "line": sr["line"], "value": value, "field": fent["kind"].get("Projection") or fent["name"].lower()},
                        "from": frm, "absent": absent, "stamp": stamp, "record_fields": record_fields})
    return out, gaps


def records_of(doc: dict) -> tuple[list[dict], list[dict], list[dict]]:
    """A composition's own records, from its Composition state rules (`store a <record>`, `store
    the strict inverse of the <record>`, `append a <record> entry`), the key a `key the <record>
    by <field>` rule names, and what an entry `carry`s. A record the page names no key for is
    a reader gap; nothing is guessed. `transactions`: each `write <writes> in one transaction`
    rule and each `write <writes> in the transaction of <rule>` that joins it, with its condition."""
    if doc["kind"] != "composition":
        return [], [], []
    forms = doc["normalized"]["rules"]
    recs: dict[str, dict] = {}
    gaps, txs = [], []
    article = re.compile(r"^(?:a|an|the)\s+", re.I)
    for r in doc["rules"]:
        form = forms.get(r["label"], {})
        if form.get("kind") != "rule":
            continue
        for o in form.get("obligations", []):
            act, obj = o.get("act"), o.get("object", "")
            if r["family"] == "Composition state" and act == "store":
                inv = re.match(r"^the strict inverse of the (?P<of>.+)$", obj)
                name = (f"inverse of {inv.group('of')}" if inv else article.sub("", obj))
                recs.setdefault(name, {"name": name, "rule": r["label"], "line": r["line"], "key": None,
                                       "inverse_of": inv.group("of") if inv else None, "carries": []})
            elif r["family"] == "Composition state" and act == "key":
                m = re.match(r"^the (?P<rec>.+?) by (?P<by>.+)$", obj)
                if m and m.group("rec") in recs:
                    recs[m.group("rec")]["key"] = m.group("by")
                    recs[m.group("rec")]["key_rule"] = r["label"]
            elif r["family"] == "Composition state" and act == "append":
                m = re.match(r"^(?:a|an) (?P<rec>.+?) entry\b", obj)
                if m and m.group("rec") in recs:
                    recs[m.group("rec")].setdefault("appended_by", r["label"])
            elif r["family"] == "Composition state" and act == "carry":
                m = re.match(r"^(?:A|An) (?P<rec>.+?) entry$", form.get("subject", ""))
                if m and m.group("rec") in recs:
                    recs[m.group("rec")]["carries"].append(article.sub("", obj))
            if act == "write":
                m1, m2 = IN_ONE_TX.match(obj), IN_TX_OF.match(obj)
                if m1 or m2:
                    m = m1 or m2
                    tx = {"rule": r["label"], "line": r["line"], "writes": [article.sub("", w) for w in re.split(r"\s+AND\s+|,\s*", m.group("writes"))]}
                    if m2:
                        tx["joins"] = m2.group("label")
                    if o.get("cited"):
                        tx["cited"] = o["cited"]
                    cl = [c["text"] for c in (form.get("if") or {}).get("clauses", [])]
                    if cl:
                        tx["if"] = cl
                    txs.append(tx)
    out = list(recs.values())
    for rec in out:
        if rec["key"] is None:
            why = ("an inverse map's key is the first map's value, which the reader read no rule naming" if rec["inverse_of"]
                   else "the reader read no rule that keys it")
            gaps.append({"rule": rec["rule"], "line": rec["line"], "kind": "no-key", "what": f"no key read for the {rec['name']}: {why}"})
    return out, txs, gaps


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
        "source_sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
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


def guard_test(cl: dict, doc: dict, cx: dict, keys: list[dict], inputs: set[str], rule: dict) -> dict:
    """What one clause of a guard reads, nothing guessed: `record_by_id` (a record EXISTS, or none does, for the key's term), `input` (a call's input is
    blank, exceeds a bound a Term of the page names, is malformed, or is, or is not, a value), `record_state` (the record is, or is not, a Member entry's
    value), `setting_member` (no member of a set a deployment declares, a setting the page gives an `of` field, EQUALS that field of the call), `database_refusal` (the database refuses the write), `seam_value` (a Term of the page that is a list of values, `material | unknown-actor | unreachable`, which the outside supplies, is, or is not,
    one of them), or `prose` (the clause rests on a Term's sentence, or on nothing the reader resolves), with `why`."""
    k, text = cl["kind"], cl["text"]
    key = keys[0] if keys else None
    if k in ("presence", "absence") and key and cl.get("qualifier") == f"for the {key['term']}":
        if re.sub(r"^(?:a|an|the|no) ", "", cl.get("thing", "").strip().lower()) == key["thing"]:
            return {"clause": text, "reads": "record_by_id", "present": k == "presence"}
    if k == "comparison":
        left, op, right = cl["left"], cl["op"], cl["right"]
        neg = op == "DOES NOT EQUAL"
        member = re.fullmatch(r"no member of (.+)", left.strip())
        setting = next((x for x in doc.get("settings", []) if member and x.get("of")
                        and re.sub(r"^(?:the|a|an) ", "", member.group(1).strip().lower()) == x["term"].lower()), None)
        if setting and op == "EQUALS" and field_of(right, cx) == setting["of"] and setting["of"] in inputs:
            return {"clause": text, "reads": "setting_member", "setting": setting["term"], "input": setting["of"]}
        field = field_of(left, cx)
        term = cx["terms"].get(re.sub(r"^(?:the|a|an) ", "", left.strip().lower()))
        values = re.match(r"^([a-z-]+(?: \| [a-z-]+)+)\b", term["definition"]) if term else None
        if field in inputs and op in ("EQUALS", "DOES NOT EQUAL") and right == "blank":
            return {"clause": text, "reads": "input", "input": field, "test": "blank", "negated": neg}
        if field in inputs and op == "EXCEEDS" and re.sub(r"^(?:the|a|an) ", "", right.strip().lower()) in cx["terms"]:
            return {"clause": text, "reads": "input", "input": field, "test": "exceeds", "bound": re.sub(r"^(?:the|a|an) ", "", right.strip().lower())}
        if field in inputs and op in ("EQUALS", "DOES NOT EQUAL") and re.fullmatch(r"[a-z-]+", right):
            return {"clause": text, "reads": "input", "input": field, "test": "value", "value": right, "negated": neg}
        rec = re.match(r"^the (?P<rec>.+?)'s (?P<f>.+)$", left.strip())
        if rec and key and rec.group("rec") in (key["thing"], key["thing"].removesuffix(" record")) and op in ("EQUALS", "DOES NOT EQUAL") and right in cx["members"]:
            fld, value = cx["members"][right]
            rtype = key["thing"].removesuffix(" record")
            fld = fld[len(rtype) + 1:] if fld not in cx["fields"] and fld.startswith(rtype + " ") else fld
            if cx["fields"].get(fld) and cx["fields"].get(fld) == field_of(rec.group("f"), cx):
                return {"clause": text, "reads": "record_state", "field": cx["fields"][fld], "value": value, "negated": neg}
        if left == "a string input" and op == "EXCEEDS" and re.sub(r"^(?:the|a|an) ", "", right.strip().lower()) in cx["terms"]:
            return {"clause": text, "reads": "input", "input": "every string input", "test": "exceeds", "bound": re.sub(r"^(?:the|a|an) ", "", right.strip().lower())}
        if values and op in ("EQUALS", "DOES NOT EQUAL") and right in values.group(1).split(" | "):
            return {"clause": text, "reads": "seam_value", "term": term["name"], "value": right, "negated": neg}
    if k == "predicate" and re.fullmatch(r"the database refuses the (?:\[[^\]]+\] )?write", text):
        return {"clause": text, "reads": "database_refusal"}
    if k == "predicate":
        m = re.fullmatch(r"(?:a supplied )?(.+) is malformed", text)
        field = field_of(m.group(1), cx) if m else None
        if field in inputs:
            return {"clause": text, "reads": "input", "input": field, "test": "malformed", "cited": bool(rule.get("cited_meaning"))}
        m = re.fullmatch(r"the (?P<rec>.+?) is (?P<not>not )?(?P<word>[a-z-]+)", text)
        if m and key and m.group("rec") in (key["thing"], key["thing"].removesuffix(" record")) and m.group("word") in cx["members"]:
            fld, value = cx["members"][m.group("word")]
            rtype = key["thing"].removesuffix(" record")
            if fld not in cx["fields"] and fld.startswith(rtype + " "):
                fld = fld[len(rtype) + 1:]
            if fld in cx["fields"]:
                return {"clause": text, "reads": "record_state", "field": cx["fields"][fld], "value": value, "negated": bool(m.group("not"))}
        if m and m.group("word") in cx["terms"]:
            return {"clause": text, "reads": "prose", "why": f"`{m.group('word')}` is a Term whose sentence says what it tests"}
    return {"clause": text, "reads": "prose", "why": "the clause rests on a Term's sentence or on nothing the reader resolves"}


def guards_of(doc: dict, cx: dict, keys: list[dict]) -> list[dict]:
    """Each Operation rule that says `IF <tests> THEN [X] MUST answer <an arm of the signature>`: the guard (`join`, `tests` each with what it reads, `whole`
    where none rests on prose) and `answer`, the arm, with `refusal` true where the signature lists it among the action's refusals."""
    forms = doc["normalized"]["rules"]
    sigs = {snake_of(s["action"]): s for s in doc["signatures"]}
    out: list[dict] = []
    for r in doc["rules"]:
        f = forms.get(r["label"], {})
        if r["family"] != "Operation" or f.get("kind") != "rule" or not f.get("if") or len(f.get("obligations", [])) != 1 or not r.get("actions"):
            continue
        o = f["obligations"][0]
        arms = {x.split("(")[0] for act in r["actions"] if act in sigs for x in sigs[act]["answers"] + sigs[act]["refuses"]}
        if o["act"] != "answer" or o["modal"] != "MUST" or o.get("object") not in arms:
            continue
        inputs = {snake_of(i["name"]) for act in r["actions"] if act in sigs for i in sigs[act]["inputs"]}
        tests = [guard_test(c, doc, cx, keys, inputs, r) for c in f["if"]["clauses"]]
        out.append({"rule": r["label"], "line": r["line"], "actions": r["actions"], "join": f["if"]["join"], "tests": tests,
                    "answer": o["object"], "refusal": any(o["object"] in sigs[act]["refuses"] for act in r["actions"] if act in sigs),
                    "whole": all(t["reads"] != "prose" for t in tests)})
    return out


PROJECTABLE = ("key", "guard", "shape", "transition", "wiring", "step", "check-only", "not-carried")


def projectable_of(doc: dict, gaps: list[dict]) -> list[dict]:
    """One entry per rule: what a consumer of the IR may take it as, from what the reader carried and nothing the consumer need re-derive. `as` is one of
    `key` (the Identity rule that names a key, or the rule that says where an id comes from), `transition` (a rule a carried transition reads), `guard` (a carried
    guard, `whole` where no test rests on prose; one that is not whole is `not-carried`), `shape` (an answer shape the reader read), `wiring` (a call or an answer
    test of a composition), `step` (an Operation or State rule of one obligation whose subject names the actions in `actions`, or a State rule of a fresh record),
    `check-only` (the rule holds as a property or a constraint on the caller, and no action takes a step from it), `not-carried` (the reader could not carry it:
    `why`, and `gaps`, the places in `reader_gaps` it rests on). `actions` is the reader's, as on the rule."""
    forms = doc["normalized"]["rules"]
    sigs = {snake_of(x["action"]) for x in doc["signatures"]}
    gap_at: dict[str, list[int]] = {}
    for i, g in enumerate(gaps):
        gap_at.setdefault(g["rule"], []).append(i)
    keyed = {k["rule"] for k in doc["keys"]} | {k["source"]["rule"] for k in doc["keys"] if k.get("source")}
    stepped = {t[part]["rule"] for t in doc["transitions"] for part in ("stands", "from", "absent", "stamp") if t.get(part)}
    guards = {g["rule"]: g for g in doc["guards"]}
    wired = {c["rule"] for c in doc["calls"]} | {t["rule"] for t in doc["answer_tests"]}
    out = []
    for r in doc["rules"]:
        label, f = r["label"], forms.get(r["label"], {})
        acts = r.get("actions", [])
        entry: dict = {"rule": label, "line": r["line"]}
        mine = gap_at.get(label, [])

        def took(kind, why=None, **more):
            entry["as"] = kind
            if acts:
                entry["actions"] = acts
            if why:
                entry["why"] = why
            if mine:
                entry["gaps"] = mine
            entry.update(more)
            out.append(entry)

        obs = f.get("obligations", [])
        if label in keyed:
            took("key")
        elif r["family"] not in ("Operation", "State"):
            took("check-only", f"rules of the {r['family']} family hold of the records and the answers, and name no step")
        elif f.get("kind") != "rule" or len(obs) != 1:
            took("not-carried", "a rule with more than one obligation" if f.get("kind") == "rule" and len(obs) > 1 else
                 f"the reader reads {len(obs)} obligations in it" + ("" if f.get("kind") == "rule" else f", and reads the rule as a {f.get('kind')}, not a rule"))
        elif acts and not set(acts) <= sigs:
            took("not-carried", "the subject names an action (%s) that the reader found on no signature of the pattern" % ", ".join(sorted(set(acts) - sigs)))
        elif label in stepped:
            took("transition")
        elif (obs[0]["modal"], obs[0]["act"]) in (("MUST NOT", "answer"), ("MUST NOT", "require"), ("MUST", "accept")):
            took("check-only", "a constraint on what an answer carries" if obs[0]["act"] == "answer" else
                 "a prohibition on a precondition, which names no step" if obs[0]["act"] == "require" else "an obligation not to refuse names no step")
        elif mine and not acts:
            took("not-carried", gaps[mine[0]]["what"])
        elif r["family"] == "State" and not acts and not re.match(r"a fresh ", f.get("subject", ""), re.I):
            took("check-only", "what the second record MUST carry: the records' shape, not a step")
        elif r["family"] == "Operation" and not acts:
            took("check-only", "a constraint on the caller, not a step of the action")
        elif label in guards:
            g = guards[label]
            if g["whole"]:
                took("guard", tests=len(g["tests"]))
            else:
                prose = next(t for t in g["tests"] if t["reads"] == "prose")
                took("not-carried", "a guard whose test rests on a Term's sentence or on nothing the reader resolves: " + prose["clause"], tests=len(g["tests"]))
        elif "answer_shape" in r:
            took("shape")
        elif label in wired:
            took("wiring")
        elif mine:
            took("not-carried", gaps[mine[0]]["what"])
        else:
            took("step")
    return out


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
        acts = actions_of(form.get("subject", ""), doc["terms"], doc["signatures"]) if form.get("kind") == "rule" else []
        if acts:
            r["actions"] = acts
        elif form.get("kind") == "rule" and (unresolved_set(form.get("subject", ""), doc) or bracketed_head(form.get("subject", ""), doc)):
            gaps.append({"rule": r["label"], "line": r["line"],
                         "kind": "no-action", "what": (f"no action read: {form['subject'].strip()!r} is a Term that names a set of actions, which the reader could not resolve against the pattern's signatures"
                                                       if unresolved_set(form.get("subject", ""), doc) else
                                                       f"no action read: {form['subject'].strip()!r} is a Term whose definition begins with a bracketed action ({bracketed_head(form.get('subject', ''), doc)!r}), and the reader reads that as no list of actions")})
        cm = cited_meaning(r, form, contract)
        if cm:
            r["cited_meaning"] = cm
        elif predicates(form) and CONTRACT_CITE.search(r["text"]) and contract:
            gaps.append({"rule": r["label"], "line": r["line"],
                         "kind": "no-contract-rule", "what": "a predicate cites an Execution Contract rule the reader did not find in the contract"})
        cb = completed_by(form, doc["term_entries"])
        if cb:
            r["completed_by"] = cb
        elif (form.get("kind") == "rule" and r["family"] == "Operation"
              and any(o.get("exclusive") or o.get("only_if") for o in form.get("obligations", []))):
            gaps.append({"rule": r["label"], "line": r["line"],
                         "kind": "no-completion", "what": "a necessary condition on an answer, and the reader read no Operation rule or Member term entry that gives the rest"})
        obs = form.get("obligations", []) if form.get("kind") == "rule" and r["family"] == "Operation" else []
        if (len(obs) == 1 and obs[0]["act"] == "answer" and obs[0].get("object") and not obs[0].get("exclusive")
                and not obs[0].get("only_if") and re.fullmatch(r"\[.+\]", form.get("subject", "").strip())
                and not re.fullmatch(r"[a-z]+(?:-[a-z]+)*", obs[0]["object"])
                and obs[0]["object"] not in {a.split("(")[0] for s in doc["signatures"] for a in s["answers"]}
                and not names_an_arm(obs[0]["object"], doc)):
            shape, why = answer_shape(form, doc, cx)
            if shape:
                cited = cited_texts(r, contract)
                if cited:
                    shape["cited"] = cited
                r["answer_shape"] = shape
            else:
                gaps.append({"rule": r["label"], "line": r["line"], "kind": "no-answer-shape", "what": "no answer shape read: " + why})
        if r["family"] == "Identity" and IDENTIFY.search(r["text"]):
            key, why = key_of(r, doc["terms"], doc["term_entries"], doc["rules"], forms)
            if key:
                keys.append(key)
            else:
                gaps.append({"rule": r["label"], "line": r["line"], "kind": "no-key", "what": "no key read: " + why})
    doc["keys"] = keys
    for r in doc["rules"]:      # a shape takes the page's first record type (`cx["type"]`): where the rule's words name another, the shape is not read
        sh = r.get("answer_shape")
        named = [t for t in cx["types"][1:] if sh and sh.get("thing") == cx["type"] and re.search(rf"\b{re.escape(t)}s?\b", r["text"].lower())]
        if named:
            r.pop("answer_shape")
            gaps.append({"rule": r["label"], "line": r["line"], "kind": "record-types",
                         "what": f"no answer shape read: the pattern names {len(cx['types'])} record types ({', '.join(cx['types'])}), the reader reads a shape's record as "
                                 f"`{cx['type']}`, and the rule's words name {', '.join(named)} too"})
    doc["settings"], setting_gaps = settings_of(doc, cx)       # before the guards: a guard test reads a setting's set
    doc["guards"] = guards_of(doc, cx, keys)
    gaps += read_orders(doc, cx, keys, contract)
    gaps += setting_gaps
    doc["term_sets"], more = term_sets_of(doc, cx)
    gaps += more
    doc["calls"], doc["answer_tests"], more = wiring_of(doc, root)
    gaps += more
    doc["records"], doc["transactions"], more = records_of(doc)
    gaps += more
    doc["transitions"], more = transitions_of(doc, cx)
    gaps += more
    doc["reader_gaps"] = gaps
    doc["projectable"] = projectable_of(doc, gaps)


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
    read3 = contract_of(root).get("Read 3")
    if read3 is not None:     # CONTRACT_ARMS is what the reader takes Read 3 to give every read: proved against the contract's own words
        missing = sorted(a for a in CONTRACT_ARMS if a not in read3["title"] + " " + read3["text"])
        if missing:
            findings.append(("execution-contract.md", read3["line"], "IR-contract-arms",
                             f"CONTRACT_ARMS holds {', '.join(missing)}, which Read 3 no longer says: the reader takes it as an arm every read answers"))
    for d in docs:
        rel = d["spec"]
        counted = cites.parse(root / rel).rules
        mine = {r["label"] for r in d["rules"]}
        if len(d["rules"]) != len(counted) or mine != set(counted):
            gone, extra = sorted(set(counted) - mine), sorted(mine - set(counted))
            findings.append((rel, 1, "IR-count",
                             f"{len(d['rules'])} rules in the IR, {len(counted)} by cites.py's count; "
                             f"cites.py only: {', '.join(gone) or 'none'}; IR only: {', '.join(extra) or 'none'}"))
        if [x["rule"] for x in d["projectable"]] != [r["label"] for r in d["rules"]] or any(x["as"] not in PROJECTABLE for x in d["projectable"]):
            findings.append((rel, 1, "IR-projectable", "the projectable table is not one entry of a known class for each rule, in the pattern's order"))
        named: dict[str, int] = {}
        for e in d["term_entries"]:
            if e["name"].lower() in named:
                findings.append((rel, e["line"], "IR-entry", f"the term entry {e['name']} is declared twice on the pattern (first at line {named[e['name'].lower()]}): "
                                 f"the reader would take the later one and drop the first"))
            named.setdefault(e["name"].lower(), e["line"])
        seen: Counter = Counter()
        for x in d["rules"] + d["tombstones"]:
            seen[x["label"]] += 1
            if seen[x["label"]] == 2:
                findings.append((x.get("file", rel), x["line"], "IR-label",
                                 f"label {x['label']} is used more than once on the pattern"
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
    why = resolve(cited, live[page], dead[page], "the pattern")
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


def gap_table(docs: list[dict]) -> str:
    """The reader's gaps as a table: a row for each spec that has any, a column for each kind of gap, and the totals."""
    kinds = sorted({g["kind"] for d in docs for g in d["reader_gaps"]})
    rows = [(d["name"], Counter(g["kind"] for g in d["reader_gaps"])) for d in docs if d["reader_gaps"]]
    rows.sort(key=lambda r: (-sum(r[1].values()), r[0]))
    width = max([len("spec")] + [len(n) for n, _ in rows])
    head = f"{'spec':<{width}}  " + "  ".join(f"{k:>{max(len(k), 5)}}" for k in kinds) + "  total"
    lines = [head]
    for name, c in rows:
        lines.append(f"{name:<{width}}  " + "  ".join(f"{c[k] or '.':>{max(len(k), 5)}}" for k in kinds) + f"  {sum(c.values()):>5}")
    total = Counter(g["kind"] for d in docs for g in d["reader_gaps"])
    lines.append(f"{'all':<{width}}  " + "  ".join(f"{total[k]:>{max(len(k), 5)}}" for k in kinds) + f"  {sum(total.values()):>5}")
    return "\n".join(lines)


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
    if "--gaps" in argv:
        print(gap_table(docs))
        return 0
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

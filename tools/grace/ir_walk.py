"""The walk of a spec's file: its outline, its labelled rules, signatures, Terms, case tables, Checks, Non-goals and Composes list, read as the file lays them out (a part of ir.py; unit `tooling: the Reader in parts, the same IR to the byte`)."""
from __future__ import annotations

import posixpath
import re
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "linter"))
import check  # noqa: E402
import cites  # noqa: E402
from lint import CONTRACT_CITE  # noqa: E402


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


def block_lines(lines: list[str], name: str) -> range:
    """Line indexes of the section titled `name`, read by its name and not its level: the `##` section where the page
    carries one, or else the `###` block of that name, as a pattern in the tree order carries `### Composes` under
    `## What it is` (spec-format.md, *The tree order*)."""
    got = section_lines(lines, name)
    if got:
        return got
    start = next((i for i, ln in enumerate(lines) if ln.rstrip() == "### " + name), None)
    if start is None:
        return range(0)
    end = next((i for i in range(start + 1, len(lines)) if re.match(r"^#{2,3} ", lines[i]) or check.h2_name(lines[i]) is not None), len(lines))
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
    beside the spec, where a pattern keeps them, whatever its status (GRACE-lang Hard invariant
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
    copy and the Kind (spec-format.md, *The term entry*).

    An entry is read by its form, not its position (spec-format.md, *The tree
    order*: "should the parser be that brittle?", Scott 2026-11-18): under
    `## Terms` every `####` is an entry, as it always was; anywhere else a `###`
    or `####` heading is an entry where a `Kind:` line follows its prose, as on
    a pattern in the tree order, whose entries stand where each name is first
    used (an action's entry is its `###` branch)."""
    entries = term_entries(lines)
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


def term_entries(lines: list[str]) -> list[dict]:
    """Every term entry on the page, in page order: each `####` under `## Terms`, and each entry outside it read by its
    form (`entries_by_form`). Each is `name`, `text` (the prose before the fields), `kind` (the fields, `Kind` first)
    and `line`."""
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
    entries += entries_by_form(lines, set(terms_at))
    entries.sort(key=lambda e: e["line"])
    return entries


def entries_by_form(lines: list[str], skip: set[int] = frozenset()) -> list[dict]:
    """The term entries outside `## Terms` (the indexes in `skip`): a `###` or
    `####` heading, outside a fence, whose prose is followed by a `Kind:` line;
    the fields run to the first line that is not one. A heading followed by no
    `Kind:` line before the next heading, fence or `Term` line is no entry."""
    out: list[dict] = []
    entry, fence, fields_done = None, False, False
    for k, ln in enumerate(lines):
        if check.FENCE.match(ln):
            fence = not fence
            entry = None
            continue
        if fence or k in skip:
            entry = None if k in skip else entry
            continue
        h = H34.match(ln)
        if h or ln.startswith("#") or LINK_DEF.match(ln) or ln.lstrip().startswith("<!--") or cites.TERM_DECL.match(ln):
            entry = {"name": h.group(2), "text": "", "kind": {}, "line": k + 1} if h else None
            fields_done = False
            if h:
                out.append(entry)
            continue
        if entry is None or fields_done:
            continue
        kl = KIND_LINE.match(ln)
        if kl and (entry["kind"] or kl.group(1) == "Kind"):
            entry["kind"][kl.group(1)] = kl.group(2)
        elif entry["kind"]:
            fields_done = True      # the fields are one run of lines; a blank line or prose ends them
        elif ln.strip():
            entry["text"] = (entry["text"] + "\n" + ln.strip()).strip()
    return [e for e in out if e["kind"]]


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
    # by form, not position: the owners line under `## Non-goals`, or, on a page with no such section (the tree order's
    # `## Left to others`), the owners line wherever it stands
    at = section_lines(lines, "Non-goals") or range(len(lines))
    for k in at:
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
                               for _, lk in check.MD_LINK.findall(part) if lk.endswith((".md", ".idd"))],
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
    for k in block_lines(lines, "Composes"):
        ln = lines[k]
        if ln.lstrip()[:3] in ("```", "~~~"):
            break
        link = re.match(r"[-*] .*?\[([^\]]+)\]\(([^)#\s]+\.md)\)", ln)
        if not link:
            continue
        target = posixpath.normpath(posixpath.join(base, link.group(2)))
        if target.startswith(("library/atoms/", "library/compositions/")) and target not in seen:
            seen.add(target)
            role = ln.split(" — ", 1)[1].strip() if " — " in ln else ""
            out.append({"name": link.group(1), "path": target, "role": role, "line": k + 1})
    return out


def snake_of(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")


def repo_path(path: Path, root: Path) -> str | None:
    """A spec's path in the repo, or None for a draft outside it. Compared as
    given, then resolved, so a root reached through a symlink still holds."""
    for p, r in ((path, root), (path.resolve(), root.resolve())):
        try:
            return p.relative_to(r).as_posix()
        except ValueError:
            continue
    return None

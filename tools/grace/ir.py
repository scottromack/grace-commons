#!/usr/bin/env python3
"""The parser: every spec in atoms/ and compositions/ to a derived IR.

The IR is derived, never canonical: the specs stay the source (Scott,
2026-10-28). One JSON document per spec, written to build/ir/<spec>.json and
ignored by git, holds what a test generator or the Grace connector reads from a
page: its title and kind, its Summary, every labelled rule, every Term with its
term entry's Kind, every signature, every case-table row, every Check with the
rules it tests, the Non-goals with their owners, and the Composes list.
README.md, section *The IR*, gives the shape.

It reads with the readers the corpus already has, not a second copy of their
forms: check.py's fence, label, tombstone and signature forms; cites.py's
parse, the labelled-rule count the census and the rewrite commits use;
lint.py's spec set and its reading of the Execution Contract's labels; and
the Composes list as write-reads.py's composes() reads it for the council's
reading sets, so a spec's constituents here are the pages its readers are
given.

Then it proves the IR on the whole corpus: every spec parses; each document's
rule count equals cites.py's; every label is unique on its page; every rule a
Check names exists; every Composes entry resolves to a spec. A spec the parser
cannot read is a finding, never an exception.

    python3 tools/grace/ir.py                  # every spec to build/ir/, then the proof
    python3 tools/grace/ir.py --check          # the proof alone, nothing written
    python3 tools/grace/ir.py atoms/cart.md    # one spec's document, printed

Standard library only. One finding per line, `path:line: [CODE] message`; exit
1 on any finding.
"""
from __future__ import annotations

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
from lint import CONTRACT_CITE, CONTRACT_LABEL, HISTORY_FILE, PATTERN_DIRS  # noqa: E402

# the shape of a document; a change a reader of the IR must know about moves it
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
    copy and the Kind (spec-format.md, *A term entry is the reader's copy*)."""
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
    landed)."""
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
            who = {"owner": re.sub(r"\s+", " ", owner).strip(),
                   "links": [posixpath.normpath(posixpath.join(posixpath.dirname(rel), lk))
                             for _, lk in check.MD_LINK.findall(group) if lk.endswith(".md")],
                   "forthcoming": bool(FORTHCOMING.search(group)), "line": k + 1}
            for label in expand(cited, spec):
                owned.setdefault(label, []).append(who)
    return [{"label": r["label"], "line": r["line"], "owners": owned.get(r["label"], [])}
            for r in rules if r["family"] == "Non-goal"]


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


def parse(path: Path, root: Path) -> dict:
    """One spec's document."""
    rel = path.relative_to(root).as_posix()
    lines = path.read_text(encoding="utf-8").split("\n")
    where = outline(lines)
    spec = cites.parse(path)
    rules, tombstones = walk_rules(lines, where)
    terms, vocabulary, entries = walk_terms(spec, lines, where)
    summary = "\n".join(lines[k].strip() for k in section_lines(lines, "Summary") if lines[k].strip() != "---")
    return {
        "ir": IR_VERSION,
        "spec": rel,
        "name": cites.spec_name(path),
        "title": next((ln[2:].strip() for ln in lines if ln.startswith("# ")), ""),
        "kind": "atom" if path.parent.name == "atoms" else "composition",
        "summary": "\n\n".join(p.strip() for p in re.split(r"\n\s*\n", summary) if p.strip()),
        "rules": rules,
        "tombstones": tombstones,
        "terms": terms,
        "vocabulary": vocabulary,
        "term_entries": entries,
        "signatures": walk_signatures(lines),
        "case_tables": walk_tables(lines, where, spec),
        "checks": walk_checks(rules),
        "non_goals": walk_non_goals(rel, lines, rules, spec),
        "composes": walk_composes(rel, lines),
    }


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
    dead = {d["name"]: {t["label"] for t in d["tombstones"]} for d in docs}
    by_path = {d["spec"] for d in docs}
    try:
        contract = {f"{m.group(1)} {m.group(2)}" for m in
                    CONTRACT_LABEL.finditer((root / "execution-contract.md").read_text(encoding="utf-8"))}
    except OSError:
        contract = set()
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
                findings.append((rel, x["line"], "IR-label", f"label {x['label']} is used more than once on the page"))
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
        return resolve(cited[len("Execution Contract "):], contract, set(), "the Execution Contract")
    why = resolve(cited, live[page], dead[page], "the page")
    family = cites.NAME_NUM.sub("", cited.partition(" through ")[0])
    if not why or any(split_label(lab)[0] == family for lab in live[page] | dead[page]):
        return why  # the page's own family: `Capability requirement 7f` is no Capability rule
    owner = next((n for n in sorted(live, key=len, reverse=True)
                  if n != page and cited.startswith(n + " ")), None)
    return resolve(cited[len(owner) + 1:], live[owner], dead[owner], owner) if owner else why


def resolve(cited: str, labels: set, gone: set, where: str) -> str | None:
    """A label resolves to a rule, or to a group: `Invariant 2` names `Invariant
    2.1` and on, as a range of majors covers its minors (cites.py's in_range),
    and `Operation 5` names a WHEN block's children. A range resolves when both
    its ends do (GRACE-lang Hard invariant 29)."""
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
        return f"which {where} tombstones" if end in gone else f"which no rule of {where} carries"
    return None


def emit(findings) -> None:
    for path, line, code, msg in findings:
        print(f"{path}:{line}: [{code}] {msg}")


def main(argv: list[str]) -> int:
    root = HERE.parents[1]
    args = [a for a in argv[1:] if not a.startswith("--")]
    if args:
        for a in args:
            print(json.dumps(parse(Path(a).resolve(), root), indent=2, ensure_ascii=False))
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
    n_rules = sum(len(d["rules"]) for d in docs)
    n_checks = sum(len(d["checks"]) for d in docs)
    untested = sum(1 for d in docs for c in d["checks"] if not c["tests"])
    print(f"ir: {len(docs)} specs, {n_rules} rules, {n_checks} checks ({untested} naming no rule in a closing "
          f"citation); {len(findings)} finding(s)", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

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
    python3 tools/grace/ir.py --misses         # what each family of expression matched and what it passed over, over the library
    python3 tools/grace/ir.py atoms/cart.md    # one spec's document, printed
    python3 tools/grace/ir.py --same OLD NEW   # a reorganisation's receipt: what the reader reads differently in NEW than in OLD

One-spec mode reads a draft outside the repo too, the Grace connector's: its
`spec` is the path as given, it is a composition when it has a Composes
section and an atom otherwise, and its links resolve as from atoms/ or
compositions/, so the constituents it names are the repo's specs.

Standard library only. One finding per line, `path:line: [CODE] message`; exit
1 on any finding.

THE PARTS (unit `tooling: the Reader in parts, the same IR to the byte`, 2026-11-16). This file is the command and the one import every other tool uses
(`import ir`; every name of the parts is importable from it): `parse` reads a spec, `carry` calls the parts in an order and puts what they read on the document,
`build` and `prove` run the corpus, `main` prints. The reading is in six parts, each importing only the ones above it:

    ir_gap.py       a gap as a thing (kind, rule, line, template, slots), rendered to the same four fields the document carries
    ir_walk.py      the walk of a file: outline, rules, signatures, Terms, case tables, Checks, Non-goals, Composes
    ir_keys.py      what a rule names: the contract rule a word's meaning rests on, the key an Identity rule names, the actions a subject or a Term names, the transitions
    ir_shapes.py    what a rule says of the call: the shape of an answer, a read's order, the settings, the sets, the guards
    ir_wiring.py    a composition's calls and bindings, the records it writes and the transactions that hold them
    ir_project.py   what a consumer may take a rule as (`projectable`) and the type of an input
    ir_misses.py    what the parts passed over in silence, counted over the library (`--misses`) and said as a `not-read` gap where it is a miss
    ir_data.py      the data claims said in the standard sentences (a key, a key within an owner, a link, a range, the record types), and
                    those said another way, which lint.py's Y-key-sentence, Y-owner-key-sentence, Y-link-sentence, Y-range-sentence and
                    Y-record-type report as advisories

The order `carry` keeps: the cited meaning and completed-by of each rule, the keys and the answer shapes, the settings (before the guards: a guard test reads a setting's
set), the guards, the orders of reads, the term sets, the calls and answer tests, the records and transactions, the transitions, the type of each input, what the parts
passed over (`ir_misses`), and `projectable` last, because it says what the others did. The document is the same to the byte before and after the split.

WHAT THIS READER EXPECTS OF THE TEXT IT READS, so that a change there knows to come here:

  The Execution Contract (execution-contract.md): its rules are paragraphs that open `**<Family> <n>: <title>.**` (CONTRACT_PARA); a predicate that cites one by label
  (`Execution Contract Query 5`) is carried with that rule's text (`cited_meaning`), and a label the contract does not hold is a `no-contract-rule` gap. Read 3 is
  taken to give every read the arm `state-unavailable` (CONTRACT_ARMS, proved against the contract's own words by `prove`). Read 5 is taken to say that a read answering
  many records and naming no order answers them by creation instant, earliest first, then by id ascending (READ_5 matches that sentence; a change of its words
  moves every read's `order_default`). Input 2 gives the string cap its meaning, and Query 1 and 5 give a filter's axis and its cap; the reader names them where a
  predicate cites them and reads nothing else of them.

  The term entries (spec-format.md, *The term entry*): an entry is `#### <Name>` with `Kind:` one of Field, Member, Type, Operation, Parameter; a Field carries `Field of:`
  (the record it belongs to) and `Projection:` (the snake_case name an input or a stored field is called); a Member carries `Member of:`; a Parameter carries
  `Parameter of:`. The Term of the same name (the line `Term <name>: <definition>`) gives the words: its first sentence before ` \u2014 ` is the definition the reader
  reads for a list of actions, a set, a key, a type of an input (`INPUT_TYPES`). A Field entry with no Projection is not an input; an input whose Term says nothing of its
  type has none, and `no-input-type` says so.

  The signatures (check.py's SIG_HEAD): `action(input, optional input)` with `answers` and `refuses` lines of arms; an arm written with fields is `arm(field, field)`.
"""
from __future__ import annotations

from ir_gap import gap
from ir_misses import miss_table, passed_over

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
from ir_walk import history_tombstones, outline, repo_path, section_lines, split_label, walk_checks, walk_composes, walk_non_goals, walk_rules, walk_signatures, walk_tables, walk_terms  # noqa: E402
from ir_keys import IDENTIFY, actions_of, bracketed_head, cited_meaning, cited_texts, completed_by, contract_of, key_of, predicates, transitions_of, unresolved_set  # noqa: E402
from ir_shapes import answer_shape, guards_of, member_answers, names_an_arm, read_orders, settings_of, shape_context, term_sets_of  # noqa: E402
from ir_wiring import CONTRACT_ARMS, records_of, wiring_of  # noqa: E402
from ir_project import PROJECTABLE, input_types_of, projectable_of  # noqa: E402
from ir_data import standard  # noqa: E402
from ir_walk import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)
from ir_keys import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)
from ir_shapes import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)
from ir_wiring import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)
from ir_project import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)
from ir_data import *  # noqa: E402,F401,F403  (the parts' names stay importable from `ir`)


# the shape of a document; a change a reader of the IR must know about moves it,
# and an added field is none
IR_VERSION = 1


def parse(path: Path, root: Path) -> dict:
    """One spec's document. A draft outside the repo keeps its path as given,
    and its links resolve as from the folder its shape would put it in."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    rel = repo_path(path, root)
    if rel is None:
        composes = any((check.h2_name(ln) or "").strip() == "Composes" or ln.rstrip() == "### Composes" for ln in lines)
        kind = "composition" if composes else "atom"
        home = f"library/{kind}s/{path.name}"
    else:
        kind = "atom" if Path(rel).parent.name == "atoms" else "composition"
        home = rel
    where = outline(lines)
    spec = cites.parse(path)
    rules, tombstones = walk_rules(lines, where)
    # a tombstone stands on the page or in the history file: each says which
    tombstones = [dict(t, file=rel or path.as_posix()) for t in tombstones] + history_tombstones(path, root)
    terms, vocabulary, entries = walk_terms(spec, lines, where)
    summary = "\n".join(lines[k].strip() for k in summary_lines(lines) if lines[k].strip() != "---")
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


def summary_lines(lines: list[str]) -> range:
    """The Summary: the `## Summary` section, or on a pattern in the tree order the prose that opens `## What it is`, up to
    its first folded block or `###` (spec-format.md, *The tree order*)."""
    got = section_lines(lines, "Summary")
    if got:
        return got
    at = section_lines(lines, "What it is")
    end = next((k for k in at if lines[k].lstrip().startswith(("<details", "###"))), at.stop)
    return range(at.start, end)


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
            gaps.append(gap("no-action", r["label"], r["line"], '{s1}', s1=f"no action read: {form['subject'].strip()!r} is a Term that names a set of actions, which the reader could not resolve against the pattern's signatures"
                                                       if unresolved_set(form.get("subject", ""), doc) else
                                                       f"no action read: {form['subject'].strip()!r} is a Term whose definition begins with a bracketed action ({bracketed_head(form.get('subject', ''), doc)!r}), and the reader reads that as no list of actions"))
        cm = cited_meaning(r, form, contract)
        if cm:
            r["cited_meaning"] = cm
        elif predicates(form) and CONTRACT_CITE.search(r["text"]) and contract:
            gaps.append(gap("no-contract-rule", r["label"], r["line"], 'a predicate cites an Execution Contract rule the reader did not find in the contract'))
        cb = completed_by(form, doc["term_entries"])
        if cb:
            r["completed_by"] = cb
        elif (form.get("kind") == "rule" and r["family"] == "Operation"
              and any(o.get("exclusive") or o.get("only_if") for o in form.get("obligations", []))):
            gaps.append(gap("no-completion", r["label"], r["line"], 'a necessary condition on an answer, and the reader read no Operation rule or Member term entry that gives the rest'))
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
                gaps.append(gap("no-answer-shape", r["label"], r["line"], 'no answer shape read: {why}', why=why))
        if r["family"] == "Identity" and IDENTIFY.search(r["text"]):
            key, why = key_of(r, doc["terms"], doc["term_entries"], doc["rules"], forms)
            if key:
                keys.append(key)
            else:
                gaps.append(gap("no-key", r["label"], r["line"], 'no key read: {why}', why=why))
    # the standard sentences (GRACE-lang, *Standard sentences*; ir_data.py): a key and a key within an owner join the keys,
    # after the Identity keys, each with its `form`; links and ranges are their own lists; the record types join `records`
    std = standard(doc["rules"], doc["term_entries"], {t["name"].lower() for t in doc["terms"]}, keys)
    doc["keys"] = keys + std["keys"]
    doc["links"], doc["ranges"] = std["links"], std["ranges"]
    for r in doc["rules"]:      # a shape takes the page's first record type (`cx["type"]`): where the rule's words name another, the shape is not read
        sh = r.get("answer_shape")
        named = [t for t in cx["types"][1:] if sh and sh.get("thing") == cx["type"] and re.search(rf"\b{re.escape(t)}s?\b", r["text"].lower())]
        if named:
            r.pop("answer_shape")
            gaps.append(gap("record-types", r["label"], r["line"], "no answer shape read: the pattern names {s1} record types ({s2}), the reader reads a shape's record as `{s3}`, and the rule's words name {s4} too", s1=len(cx['types']), s2=', '.join(cx['types']), s3=cx['type'], s4=', '.join(named)))
    doc["settings"], setting_gaps = settings_of(doc, cx)       # before the guards: a guard test reads a setting's set
    doc["guards"] = guards_of(doc, cx, keys)
    gaps += read_orders(doc, cx, keys, contract)
    gaps += setting_gaps
    doc["term_sets"], more = term_sets_of(doc, cx)
    gaps += more
    doc["calls"], doc["answer_tests"], more = wiring_of(doc, root)
    gaps += more
    doc["records"], doc["transactions"], more = records_of(doc)
    doc["records"] += std["records"]
    gaps += more
    doc["transitions"], more = transitions_of(doc, cx)
    gaps += more
    gaps += input_types_of(doc)
    doc["reader_gaps"] = gaps
    gaps += passed_over(doc)[1]       # what it passed over in silence, said (ir_misses.py); before the table, so a rule it rests on says so
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


SAME_FIELDS = ("summary", "rules", "tombstones", "terms", "term_entries", "signatures", "case_rows", "checks", "non_goals", "composes")


def _bare(x):
    """A reading without where it stands: line numbers, sections, captions and gap indexes dropped, lists as sets."""
    if isinstance(x, dict):
        return {k: _bare(v) for k, v in x.items() if k not in ("line", "section", "caption", "gaps", "file")}
    if isinstance(x, list):
        return sorted((_bare(v) for v in x), key=lambda v: json.dumps(v, sort_keys=True, ensure_ascii=False))
    return x


def same(old: dict, new: dict) -> list[str]:
    """What the reader reads differently in `new` than in `old`, order and line numbers aside: the receipt of a
    reorganisation (spec-format.md, *The tree order*), whose only differences are the data claims it rewrote into their
    standard sentences and the record types it declared. One line per difference, naming the rule or entry."""
    out = []
    for f in SAME_FIELDS:
        a = [r for t in old["case_tables"] for r in t["rows"]] if f == "case_rows" else old[f]
        b = [r for t in new["case_tables"] for r in t["rows"]] if f == "case_rows" else new[f]
        if _bare(a) == _bare(b):
            continue
        if isinstance(a, list):
            ka = {json.dumps(_bare(x), sort_keys=True, ensure_ascii=False) for x in a}
            kb = {json.dumps(_bare(x), sort_keys=True, ensure_ascii=False) for x in b}
            out += [f"{f}: only in the old: {x[:200]}" for x in sorted(ka - kb)]
            out += [f"{f}: only in the new: {x[:200]}" for x in sorted(kb - ka)]
        else:
            out.append(f"{f}: differs")
    return out


def emit(findings) -> None:
    for path, line, code, msg in findings:
        print(f"{path}:{line}: [{code}] {msg}")


def main(argv: list[str]) -> int:
    root = HERE.parents[1]
    args = [a for a in argv[1:] if not a.startswith("--")]
    if "--same" in argv:
        if len(args) != 2:
            print("usage: ir.py --same OLD NEW", file=sys.stderr)
            return 2
        diff = same(parse(Path(args[0]), root), parse(Path(args[1]), root))
        print("\n".join(diff) if diff else "same: " + ", ".join(SAME_FIELDS))
        return 1 if diff else 0
    if args:
        for a in args:
            print(json.dumps(parse(Path(a), root), indent=2, ensure_ascii=False))
        return 0
    docs, findings = build(root)
    if "--gaps" in argv:
        print(gap_table(docs))
        return 0
    if "--misses" in argv:
        print(miss_table(docs))
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

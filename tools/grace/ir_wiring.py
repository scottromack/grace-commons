"""A composition's wiring: the calls it makes to a constituent, what each answer is tested against, the records it writes and the transactions that hold them (a part of ir.py)."""
from __future__ import annotations

from ir_gap import gap

import re
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "linter"))
import cites  # noqa: E402
from ir_walk import outline, snake_of, walk_signatures, walk_terms  # noqa: E402


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
            gaps.append(gap("no-constituent", rule["label"], rule["line"], 'the reader read {who} as no constituent the Composes section links, or found its pattern absent', who=who))
            return None
        c, v = view[who]
        sig = next((s for s in v["signatures"] if snake_of(s["action"]) == snake_of(act)), None)
        if sig is None:
            gaps.append(gap("no-action", rule["label"], rule["line"], 'the reader found no action {act!r} on the signature list of {who} ({where})', act=act, who=who, where=where))
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
                    gaps.append(gap("no-binding", r["label"], r["line"], "the reader bound {s1!r} to no input of {s2}'s {s3} through its term entries; {s4}", s1=phrase.strip(), s2=c['name'], s3=sig['action'], s4=input_entries(sig['action'], inputs, v['term_entries'])))
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
                    gaps.append(gap("no-arm", r["label"], r["line"], "the reader read {n!r} as no arm of {s2}'s {s3} (its arms: {s4})", n=n, s2=last[0]['constituent'], s3=last[0]['action'], s4=sorted(last[1])))
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
                    gaps.append(gap("no-arm", r["label"], r["line"], "the reader read {n!r} as no arm of {s2}'s {s3} (its arms: {s4})", n=n, s2=c['name'], s3=sig['action'], s4=sorted(arms)))
            tests.append(test)
            last = (test, arms)
    return calls, tests, gaps


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
            gaps.append(gap("no-key", rec["rule"], rec["line"], 'no key read for the {s1}: {why}', s1=rec['name'], why=why))
    return out, txs, gaps

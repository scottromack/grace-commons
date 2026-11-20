"""What a consumer may take a rule as (`projectable`) and the type of an input, each said from what the other parts read (a part of ir.py)."""
from __future__ import annotations

from ir_gap import gap

import re
from ir_walk import snake_of


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
    # an Identity key; a key a standard sentence says (`form`) stays what its family makes it, so this table is the same as before
    # the standard sentences were read (unit `method: the forms of the tree reorganisation and the standard sentences`)
    keyed = {k["rule"] for k in doc["keys"] if not k.get("form")} | {k["source"]["rule"] for k in doc["keys"] if k.get("source")}
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


# what an input is, from the pattern's own words (unit `tooling: the Case Tests on the current IR, typed inputs, and the fourteen rows`): the Term the input's
# Field or Parameter entry names, by its words, and nothing guessed. `id` is a value the host allocates at the seam, which a call takes from an earlier answer.
INPUT_TYPES = [
    ("id", re.compile(r"host-allocated|allocated at the seam", re.I)),
    ("positive count", re.compile(r"\bpositive count\b", re.I)),
    ("whole count", re.compile(r"\bwhole count\b", re.I)),
    ("instant", re.compile(r"\binstant\b", re.I)),
    ("string", re.compile(r"\b(?:opaque (?:string|value|reference|payload|content)|string|reference)\b", re.I)),
]


def input_types_of(doc: dict) -> list[dict]:
    """Put `type` on every input of every signature (`{"type": ..., "words": <the Term the type was read from>}`, or None where the pattern's words give none) and say each
    input with none as a `no-input-type` gap, once for its name."""
    proj = {e["kind"].get("Projection"): e for e in doc["term_entries"] if e["kind"].get("Projection")}
    terms = {t["name"].lower(): t for t in doc["terms"]}
    gaps, said = [], set()
    for sig in doc["signatures"]:
        for i in sig["inputs"]:
            n = i["name"]
            e = proj.get(n)
            t = terms.get(e["name"].lower()) if e else None
            t = t or terms.get(n.replace("_", " "))
            text = (t["definition"] if t else "") or (e["text"] if e else "") or ""
            name = e["name"] if e else n.replace("_", " ")
            got = next((k for k, rx in INPUT_TYPES if rx.search(text)), None)
            if got is None and re.search(r"\breference\b", name, re.I):
                got, text = "string", name
            i["type"] = {"type": got, "words": (text.split(" \u2014 ")[0] if text else name)[:120]} if got else None
            if got is None and n not in said:
                said.add(n)
                gaps.append(gap("no-input-type", f"Input {n}", sig["line"], 'the reader read no type for the input `{n}` of {s2}: {s3}', n=n, s2=sig['action'], s3=f"its Term says `{text[:90]}`, in which it found no count, instant, string, reference or id" if text
                                     else "it found no Term of that name carrying a definition, so no value is made for it"))
    return gaps

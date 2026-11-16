"""What the Reader passed over in silence (a part of ir.py; unit `tooling: the Reader in parts, the same IR to the byte`).

Every family of expression that reads a list, a subject or a Term's form has lines it matched and lines that look like its kind and that it passed over. A pass-over
is either said (a reader gap already names it), by design (the Reader's own rule says it reads none: a call a condition narrows names no action), or a miss: the
Reader read nothing and said nothing. `passed_over` counts each family over one document and gives the `not-read` gap for each miss; `ir.py --misses` prints the
count over the library. Nothing here reads more than the Reader did: a miss is said, not cured.
"""
from __future__ import annotations

import re

from ir_gap import gap
from ir_walk import snake_of

# the families: key, what it reads, how a pass-over is judged
FAMILIES = [
    ("subject-term", "a rule whose subject is a Term that opens with a bracketed action", "by design: a call a condition narrows names no action (`bracketed_head`'s rule)"),
    ("subject-named-action", "an Operation rule that names an action in its words", "a miss: the subject is a role or an outcome (`a refused [Redeem]`) and the Reader read no action"),
    ("answer-of-records", "an Operation rule that answers records or values, not an arm", "a miss: `answer_shape` read none and no gap says why"),
    ("setting-capability", "a Capability requirement that says a deployment MAY declare, override or supply", "a miss: no setting of `settings` is in the rule's words"),
    ("term-set", "a Term whose definition says `the set of`, `every X carrying` or `other than`", "not a miss: the form `term_sets` reads is the set of records a call selects; these define sets of values or another kind of Term"),
]
ANSWER_LOOKS = re.compile(r"\b(?:EVERY|each|the matching|records?|listed|count of|number of|the [a-z ]+ of)\b", re.I)
MAY = re.compile(r"\bMAY (?:declare|override|supply|set)\b")
SET_LOOKS = re.compile(r"\b(?:every|each|any) [a-z ]+ carrying\b|\bthe set of\b|\bother than\b", re.I)


def _said(doc: dict, label: str) -> bool:
    return any(g["rule"] == label and g["kind"] != "not-read" for g in doc["reader_gaps"])


def passed_over(doc: dict) -> tuple[dict, list[dict]]:
    """({family: {"matched": n, "passed": n, "said": n, "by_design": n, "miss": n}}, the `not-read` gaps, one for each miss)"""
    count = {k: {"matched": 0, "passed": 0, "said": 0, "by_design": 0, "miss": 0} for k, _, _ in FAMILIES}
    gaps: list[dict] = []
    terms = {t["name"].lower(): t for t in doc["terms"]}
    sigs = {snake_of(s["action"]) for s in doc["signatures"]}
    arms = {re.sub(r"[^a-z0-9]+", "-", a.split("(")[0].strip().lower()) for s in doc["signatures"] for a in s["answers"] + s["refuses"]}
    set_terms = {x["term"].lower() for x in doc.get("term_sets", [])}
    settings = [x["term"].lower() for x in doc.get("settings", [])]
    for r in doc["rules"]:
        n = doc["normalized"]["rules"].get(r["label"], {})
        subject = (n.get("subject") or "").strip()
        term = terms.get(re.sub(r"^(?:a|an|the|every|any|each) ", "", subject, flags=re.I).lower())
        if term and re.match(r"^(?:(?:an?|the) )?\[", term["definition"].split(" — ")[0].strip()):
            c = count["subject-term"]
            if r.get("actions"):
                c["matched"] += 1
            else:
                c["passed"] += 1
                c["said" if _said(doc, r["label"]) else "by_design"] += 1
        if r["family"] == "Operation" and any(snake_of(b) in sigs for b in re.findall(r"\[([^\]]+)\]", r["text"])):
            c = count["subject-named-action"]
            if r.get("actions"):
                c["matched"] += 1
            else:
                c["passed"] += 1
                if _said(doc, r["label"]):
                    c["said"] += 1
                else:
                    c["miss"] += 1
                    gaps.append(gap("not-read", r["label"], r["line"], "the reader read no action in {subject!r}, and the rule's words name {named}",
                                    subject=subject or r["text"][:40], named=", ".join("[" + b + "]" for b in re.findall(r"\[([^\]]+)\]", r["text"]) if snake_of(b) in sigs)))
        obs = n.get("obligations") or []
        if r["family"] == "Operation" and obs and obs[0].get("act") == "answer":
            obj = obs[0].get("object", "")
            if re.sub(r"[^a-z0-9]+", "-", obj.lower()).strip("-") not in arms and ANSWER_LOOKS.search(r["text"]):
                c = count["answer-of-records"]
                if r.get("answer_shape"):
                    c["matched"] += 1
                else:
                    c["passed"] += 1
                    if _said(doc, r["label"]):
                        c["said"] += 1
                    else:
                        c["miss"] += 1
                        gaps.append(gap("not-read", r["label"], r["line"], "the reader read no answer shape for a rule that answers `{obj}`, and no gap says why", obj=obj or r["text"][:60]))
        if r["family"] == "Capability requirement" and MAY.search(r["text"]):
            c = count["setting-capability"]
            if any(s in r["text"].lower() for s in settings):
                c["matched"] += 1
            else:
                c["passed"] += 1
                if _said(doc, r["label"]):
                    c["said"] += 1
                else:
                    c["miss"] += 1
                    gaps.append(gap("not-read", r["label"], r["line"], "the reader read no setting from a rule that says a deployment {may}: {text}", may=MAY.search(r["text"]).group(0), text=r["text"][:80]))
    for t in doc["terms"]:
        if SET_LOOKS.search(t["definition"]):
            c = count["term-set"]
            if t["name"].lower() in set_terms:
                c["matched"] += 1
            else:
                c["passed"] += 1
                c["said" if any(t["name"].lower() in g["rule"].lower() for g in doc["reader_gaps"]) else "by_design"] += 1
    return count, gaps


def miss_table(docs: list[dict]) -> str:
    """The count over the library, one row for each family."""
    tot = {k: {"matched": 0, "passed": 0, "said": 0, "by_design": 0, "miss": 0} for k, _, _ in FAMILIES}
    for d in docs:
        count, _ = passed_over(d)
        for k, v in count.items():
            for f, n in v.items():
                tot[k][f] += n
    out = ["%-22s %8s %8s %6s %10s %6s  %s" % ("family", "matched", "passed", "said", "by design", "miss", "judged")]
    for k, what, judged in FAMILIES:
        v = tot[k]
        out.append("%-22s %8d %8d %6d %10d %6d  %s" % (k, v["matched"], v["passed"], v["said"], v["by_design"], v["miss"], judged))
    out.append("")
    for k, what, _ in FAMILIES:
        out.append("  %-22s %s" % (k, what))
    return "\n".join(out)

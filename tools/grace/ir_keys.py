"""What a rule names: the Execution Contract rule it cites for a word's meaning, the key an Identity rule names, the actions a subject or a Term names, and the transitions a record makes (a part of ir.py)."""
from __future__ import annotations

from ir_gap import gap

import functools
import re
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "linter"))
from lint import CONTRACT_CITE  # noqa: E402
from ir_walk import snake_of  # noqa: E402


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
        lines = (Path(root) / "library" / "execution-contract.md").read_text(encoding="utf-8").split("\n")
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
        stamp = (root / "library" / "execution-contract.md").stat().st_mtime_ns
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
        return [], [gap("no-transition", keys[1]["rule"], keys[1]["line"], 'no transition read: the pattern names {s1} id keys ({s2}), and the reader carries transitions for a pattern that names one', s1=len(keys), s2=', '.join(k['thing'] for k in keys))]
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
            gaps.append(gap("no-transition", stands[1][0]["label"], stands[1][0]["line"], 'no transition read: {action} names a {thing} by its id and stands it in {s3} states: the reader carries one', action=action, thing=thing, s3=len(stands)))
            continue
        (sr, value), = stands
        member = cx["members"].get(value)
        fname = (member[0] if member else "").removeprefix("the ")
        fent = fields.get(fname) or fields.get(fname.removeprefix(thing + " "))
        if not member or not fent:
            gaps.append(gap("no-transition", sr["label"], sr["line"], 'no transition read: the reader found `{value}` in no Member entry of a Field entry', value=value))
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
                spend = gap("no-transition", r["label"], r["line"], 'no transition read: the reader read no Invariant of the form `a {thing} carrying <stamp> MUST stand in <state>` that pairs the stamp `{s2}` with `{value}`', thing=thing, s2=m.group(1), value=value)
        missing = [name for part, name in ((absent, "what is answered where no %s carries the id" % thing), (frm, "which states it may stand it from")) if not part]
        if spend:
            gaps.append(spend)
        if missing:
            gaps.append(gap("no-transition", sr["label"], sr["line"], 'no transition read: {action} stands the {thing} its id names in {value}, and the reader read no rule that says {s4}', action=action, thing=thing, value=value, s4=' or '.join(missing)))
        if absent and frm and not spend:
            out.append({"action": action, "thing": thing, "key": key["rule"], "id": list(key["fields"]),
                        "stands": {"rule": sr["label"], "line": sr["line"], "value": value, "field": fent["kind"].get("Projection") or fent["name"].lower()},
                        "from": frm, "absent": absent, "stamp": stamp, "record_fields": record_fields})
    return out, gaps

"""What a rule says of the call: the shape of an answer, the order of a read, the settings a deployment may declare, the sets a Term defines, and a rule's guards (a part of ir.py)."""
from __future__ import annotations

from ir_gap import gap

import re
from ir_walk import snake_of
from ir_keys import cited_texts, term_fields


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
            return [], f"the reader read `{name}` as a Field entry of another record than `{thing}`"
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
    return [], f"the reader found `{phrase.strip()}` neither a Field entry nor a Term"


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
            gaps.append(gap("no-order", r["label"], r["line"], "the read's order is Execution Contract Read 5's, which needs the record's creation instant and its id: the reader found {s1}", s1='no Field entry `creation instant`' if not made else 'no one id key'))
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
            gaps.append(gap("no-default", r["label"], r["line"], 'no default read: the reader read no default in the Term `{s1}` (what stands where a deployment declares none)', s1=m.group('term')))
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
            gaps.append(gap("no-set", f"Term {t['name']}", t["line"], 'no set read: the reader could not fit the definition, which says `other than`, to `a <member> <thing> carrying the <term> of the call and a <field> other than the <field> of the call`'))
            continue
        where, why = what_of(m.group("what"), cx)
        carrying, why2 = carrying_of(m.group("by"), cx)
        other, same = field_of(m.group("other"), cx), field_of(m.group("same"), cx)
        if why or why2 or not other or other != same:
            gaps.append(gap("no-set", f"Term {t['name']}", t["line"], 'no set read: {s1}', s1=why or why2 or "the reader read the field that differs as not the field the call names"))
            continue
        out.append({"term": t["name"], "line": t["line"], "thing": cx["type"], "where": where, "carrying": carrying, "other_than": other})
    return out, gaps


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

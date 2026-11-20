"""The data claims a pattern says in the standard sentences: a key, a key within an owner, a link, a range, and the record
types its Field entries name (GRACE-lang, the section titled *Standard sentences*; a part of ir.py, unit `method: the forms of
the tree reorganisation and the standard sentences`, Scott 2026-11-19).

One reader for the IR and the linter. `standard(rules, entries, terms)` reads each labelled rule against the four sentence
forms and each Field entry against its record type, and returns what it read: the claims in a standard sentence, with the
Field entries they name, for the IR (`keys`, `links`, `ranges`, `records`), and the claims of the same kind said another
way, each with what departs from the form, for the linter's advisories (`Y-key-sentence`, `Y-owner-key-sentence`,
`Y-link-sentence`, `Y-range-sentence`, `Y-record-type`). Nothing is guessed: a claim the forms do not fit is read as no
claim, and only its departure is said. The variants the forms replace are the ones the CQL trial found
(~/Develop/grace-cql-trial/generated/README.md): `Field of: Permissions` where Permissions is no declared Type, and one key
said four ways ("Two lines one cart carries", "Two grants", "Two distinct landed events", "Two events in the log").

The forms, each one line, the names in them as the page declares them (case aside), the Field entry's name or its
Projection for a field:

    a key                 Two <Type>s MUST NOT share a <field>.
    a key within an owner Two <Type>s one <Owner> carries MUST NOT share a <field>.
    a link                EVERY <Type>'s <field> MUST name a <Type>.
    a range               EVERY <Type> MUST carry a positive|whole <Term> as the <Type>'s <field>.
    a record              a Type entry (`Kind: Type`), and each of its fields a Field entry whose `Field of:` names that Type.

`<Type>s` is the Type's regular English plural (`lines`, `categories`, `boxes`); `a` may be `an`; `<field>` is a Field entry
whose `Field of` is the Type the sentence names; `<Term>` is a Term the page declares whose name opens with the word
before it (`positive count`, `whole amount`).
"""
from __future__ import annotations

import re

# what makes a rule a claim of each kind, said in a standard sentence or not (the linter's triggers, kept tight: a firing
# is worth reading)
KEY_CLAIM = re.compile(r"^Two .+ MUST NOT share ")
LINK_CLAIM = re.compile(r"^(?:EVERY|Each|An?) .+? MUST name (?:an?|EXACTLY ONE) ")
RANGE_CLAIM = re.compile(r"^EVERY .*\b(?:positive|whole) (?:count|amount|number)s?\b")
OWNED = re.compile(r" (?:in|of) (?:one|the|a|an) [a-z]| one [a-z][a-z -]* carries$")

# the forms
KEY = re.compile(r"^Two (?P<things>[a-z][a-z0-9 -]*?) MUST NOT share an? (?P<field>[a-z][a-z0-9 -]*?)\.?$")
OWNER_KEY = re.compile(r"^Two (?P<things>[a-z][a-z0-9 -]*?) one (?P<owner>[a-z][a-z0-9 -]*?) carries MUST NOT share an? (?P<field>[a-z][a-z0-9 -]*?)\.?$")
LINK = re.compile(r"^EVERY (?P<thing>[a-z][a-z0-9 -]*?)'s (?P<field>[a-z][a-z0-9 -]*?) MUST name an? (?P<target>[a-z][a-z0-9 -]*?)\.?$")
RANGE = re.compile(r"^EVERY (?P<thing>[a-z][a-z0-9 -]*?) MUST carry an? (?P<term>(?P<bound>positive|whole) [a-z][a-z0-9 -]*?) "
                   r"as the (?P<owner>[a-z][a-z0-9 -]*?)'s (?P<field>[a-z][a-z0-9 -]*?)\.?$")

# the families whose rules are about a call, a deployment or a reader and are no data claim, whatever their words
NOT_DATA = {"Operation", "Action wiring", "Non-goal", "Composition note", "Check", "External check", "Capability requirement",
            "Composes", "Reconciliation", "Housekeeping", "Audit arm", "Wiring decision", "Verdict", "Scope vocabulary"}


def plural(name: str) -> str:
    """The regular English plural of a name's last word: `line` lines, `category` categories, `box` boxes."""
    head, _, last = name.rpartition(" ")
    if re.search(r"[^aeiou]y$", last):
        last = last[:-1] + "ies"
    elif re.search(r"(?:s|x|z|ch|sh)$", last):
        last += "es"
    else:
        last += "s"
    return (head + " " + last).strip()


def record_types(entries: list[dict]) -> dict[str, dict]:
    """The page's declared Types, lower-cased name to `{name, line, fields}`, `fields` the Field entries whose `Field of`
    names the Type, in page order."""
    types = {e["name"].lower(): {"name": e["name"], "line": e["line"], "fields": []}
             for e in entries if e["kind"].get("Kind") == "Type"}
    for e in entries:
        if e["kind"].get("Kind") == "Field" and e["kind"].get("Field of", "").strip().lower() in types:
            types[e["kind"]["Field of"].strip().lower()]["fields"].append(e)
    return types


def _type(words: str, types: dict, many: bool) -> str | None:
    """The declared Type a phrase names, as the Type's name or (where `many`) its regular plural."""
    w = words.strip().lower()
    for key in types:
        if w == (plural(key) if many else key):
            return key
    return None


def _field(words: str, of: str, types: dict) -> dict | None:
    """The Field entry of the Type `of` the phrase names, by its name or its Projection."""
    w = words.strip().lower()
    return next((f for f in types[of]["fields"]
                 if w in (f["name"].lower(), f["kind"].get("Projection", "").strip().replace("_", " ").lower())), None)


def _proj(f: dict) -> str:
    return f["kind"].get("Projection") or f["name"]


def read_rule(rule: dict, types: dict, terms: set[str]) -> tuple[str | None, dict | None, str | None]:
    """One rule: (the kind of data claim it makes or None, what the standard sentence says or None, why it is not a standard
    sentence or None). A rule of a family that states no data claim is none."""
    text = rule["text"].strip()
    if rule["family"] in NOT_DATA:
        return None, None, None
    if KEY_CLAIM.match(text):
        m = OWNER_KEY.match(text)
        if m:
            kind = "owner key"
            thing, owner = _type(m.group("things"), types, True), _type(m.group("owner"), types, False)
            if not thing:
                return kind, None, f"`{m.group('things')}` is not the plural of a Type the pattern declares"
            if not owner:
                return kind, None, f"the owner `{m.group('owner')}` is not a Type the pattern declares"
            f = _field(m.group("field"), thing, types)
            if not f:
                return kind, None, f"`{m.group('field')}` is no Field entry of {types[thing]['name']}"
            return kind, {"rule": rule["label"], "line": rule["line"], "form": "key within an owner", "thing": thing,
                          "owner": owner, "names": [f["name"].lower()], "fields": [_proj(f)]}, None
        m = KEY.match(text)
        things = m.group("things") if m else text[4:text.index(" MUST NOT share ")]
        kind = "owner key" if OWNED.search(" " + things) else "key"
        if not m:
            return kind, None, "the shared value is not one field (`share a <field>`): several fields, a list or a qualifier"
        thing = _type(things, types, True)
        if not thing:
            if kind == "owner key":
                return kind, None, f"`{things}` names an owner another way; the form is `Two <Type>s one <Owner> carries`"
            return kind, None, f"`{things}` is not the plural of a Type the pattern declares (a qualifier, or a record no Type entry declares)"
        f = _field(m.group("field"), thing, types)
        if not f:
            return kind, None, f"`{m.group('field')}` is no Field entry of {types[thing]['name']}"
        return kind, {"rule": rule["label"], "line": rule["line"], "form": "key", "thing": thing,
                      "names": [f["name"].lower()], "fields": [_proj(f)]}, None
    if LINK_CLAIM.match(text):
        m = LINK.match(text)
        if not m:
            return "link", None, "the sentence does not take the link's form"
        thing, target = _type(m.group("thing"), types, False), _type(m.group("target"), types, False)
        if not thing:
            return "link", None, f"`{m.group('thing')}` is not a Type the pattern declares"
        if not target:
            return "link", None, f"`{m.group('target')}` is not a Type the pattern declares"
        # the field is the Type's own Field entry, or the target's (a line's cart id is the Cart Id entry: one entry
        # names one field, and the record that carries another record's id carries that entry)
        f = _field(m.group("field"), thing, types) or _field(m.group("field"), target, types)
        if not f:
            return "link", None, f"`{m.group('field')}` is no Field entry of {types[thing]['name']} or of {types[target]['name']}"
        return "link", {"rule": rule["label"], "line": rule["line"], "thing": thing, "names": [f["name"].lower()],
                        "fields": [_proj(f)], "field_of": f["kind"]["Field of"].strip().lower(), "target": target}, None
    m = RANGE.match(text)
    if m or RANGE_CLAIM.match(text):
        if not m:
            return "range", None, "the sentence does not take the range's form"
        thing = _type(m.group("thing"), types, False)
        if not thing or _type(m.group("owner"), types, False) != thing:
            return "range", None, f"`{m.group('thing')}` is not a Type the pattern declares, named the same twice"
        if m.group("term").lower() not in terms:
            return "range", None, f"`{m.group('term')}` is no Term the pattern declares"
        f = _field(m.group("field"), thing, types)
        if not f:
            return "range", None, f"`{m.group('field')}` is no Field entry of {types[thing]['name']}"
        return "range", {"rule": rule["label"], "line": rule["line"], "thing": thing, "names": [f["name"].lower()],
                         "fields": [_proj(f)], "bound": m.group("bound"), "term": m.group("term").lower()}, None
    return None, None, None


def standard(rules: list[dict], entries: list[dict], terms: set[str], known_keys: list[dict] = ()) -> dict:
    """What the page says in the standard sentences, and what it says another way. `terms` is the page's declared Term
    names, lower-cased. Returns `keys`, `links`, `ranges`, `records` (one for each declared Type a Field entry names: its
    `name`, `line`, `carries` the fields' Projections in page order, and `key` and `key_rule` where a key names one: the
    first of `known_keys`, the keys the Identity rules name, then a standard key sentence), and `departures`: `(kind, rule or entry name, line, why)` for each claim said another way, `kind` one of
    `key`, `owner key`, `link`, `range`, `record`."""
    types = record_types(entries)
    out: dict = {"keys": [], "links": [], "ranges": [], "records": [], "departures": []}
    for r in rules:
        kind, got, why = read_rule(r, types, terms)
        if kind is None:
            continue
        if got is None:
            out["departures"].append((kind, r["label"], r["line"], why))
        elif kind in ("key", "owner key"):
            out["keys"].append(got)
        else:
            out[kind + "s"].append(got)
    for e in entries:
        if e["kind"].get("Kind") == "Field" and e["kind"].get("Field of", "").strip().lower() not in types:
            out["departures"].append(("record", e["name"], e["line"],
                                      f"`Field of: {e['kind'].get('Field of', '').strip()}` names no Type the pattern declares"))
    for key, t in types.items():
        if not t["fields"]:
            continue    # a Type no Field entry names is a value, not a record the pattern keeps
        k = next((x for x in list(known_keys) + out["keys"] if x["thing"].lower() == key and x.get("form", "key") == "key"), None)
        out["records"].append({"name": key, "form": "type", "rule": None, "line": t["line"],
                               "key": k["fields"] if k else None, "key_rule": k["rule"] if k else None,
                               "inverse_of": None, "carries": [_proj(f) for f in t["fields"]]})
    return out

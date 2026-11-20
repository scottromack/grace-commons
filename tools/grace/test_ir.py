#!/usr/bin/env python3
"""Tests for ir.py's readers: the parsers a rename in check.py or normalize.py would break without the corpus proof noticing.

    python3 tools/grace/test_ir.py                    # run
    python3 tools/grace/test_ir.py --update-golden    # rewrite testdata/reaction.ir.json from testdata/reaction.md, then run

The corpus proof (`ir.py --check`) pins acceptance: every spec parses, the counts and labels agree. It does not pin the shape of what a reader
carries, and the projector reads the shape. These cases do: the small parsers one at a time (the owners line, a Term's list of Field entries, a guard's
clause, the setting a guard reads, the table of what a rule may be taken as), the proof's own findings, and one golden file: the document of a fixed spec
(testdata/reaction.md, a copy of the page as it stood when the golden was written), less the fields that say where and when it was read
(`spec`, `source_sha256`) and the normalized forms (normalize.py's own).
"""
from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ir  # noqa: E402

FIXTURE = HERE / "testdata" / "reaction.md"
GOLDEN = HERE / "testdata" / "reaction.ir.json"
KINDS = {"no-key", "no-answer-shape", "no-completion", "no-contract-rule", "no-action", "no-order", "no-default", "no-set", "no-transition",
         "no-constituent", "no-arm", "no-binding", "record-types", "no-input-type", "not-read"}


def entry(name: str, **kind: str) -> dict:
    return {"name": name, "text": "", "kind": dict(kind), "line": 1}


def root_with(spec: str, contract: str | None = None) -> tuple[tempfile.TemporaryDirectory, Path]:
    tmp = tempfile.TemporaryDirectory()
    root = Path(tmp.name)
    (root / "atoms").mkdir()
    (root / "compositions").mkdir()
    (root / "atoms" / "reaction.md").write_text(spec, encoding="utf-8")
    if contract is not None:
        (root / "execution-contract.md").write_text(contract, encoding="utf-8")
    return tmp, root


def golden_of(doc: dict) -> dict:
    return {k: v for k, v in doc.items() if k not in ("spec", "source_sha256", "normalized")}


class Owners(unittest.TestCase):
    def test_forthcoming_part_splits_where_a_link_an_article_or_a_capital_follows(self):
        got = ir.owner_parts("[Audit Trail](./audit-trail.md), the deployment and Reverse Index *(forthcoming)*")
        self.assertEqual(len(got), 3)
        self.assertIn("forthcoming", got[2])
        self.assertNotIn("forthcoming", got[0] + got[1])

    def test_one_forthcoming_name_with_an_and_in_it_stays_one(self):
        self.assertEqual(len(ir.owner_parts("a priority and ordering pattern *(forthcoming)*")), 1)

    def test_a_part_with_no_marker_is_not_split(self):
        part = "[Permissions](../atoms/permissions.md) and [Session](../atoms/session.md), an identity-keyed access model"
        self.assertEqual(ir.owner_parts(part), [part])


class ActionLists(unittest.TestCase):
    TERMS = [{"name": "writing action", "definition": "[Record Sighting], [Report Standing] or [Report Clear]."},
             {"name": "terminal call", "definition": "a [Deliver], a [Fail] or an [Expire] call"},
             {"name": "narrowed call", "definition": "a [Fire] call whose tasks are all closed"}]

    def test_a_list_of_bracketed_actions_that_ends_in_a_period_names_its_actions(self):
        self.assertEqual(ir.actions_of("a writing action", self.TERMS), ["record_sighting", "report_standing", "report_clear"])

    def test_the_same_list_with_no_period_names_the_same_actions(self):
        self.assertEqual(ir.actions_of("a terminal call", self.TERMS), ["deliver", "fail", "expire"])

    def test_a_call_narrowed_by_anything_else_names_none(self):
        self.assertEqual(ir.actions_of("a narrowed call", self.TERMS), [])


class InputTypes(unittest.TestCase):
    def doc(self, entry_name, projection, definition, input_name):
        return {"signatures": [{"action": "Go", "line": 5, "inputs": [{"name": input_name, "optional": False}]}],
                "term_entries": [{"name": entry_name, "text": "", "kind": {"Kind": "Field", "Projection": projection}, "line": 1}],
                "terms": [{"name": entry_name.lower(), "definition": definition, "line": 2}]}

    def test_the_words_of_the_term_give_the_type(self):
        for definition, want in (("a whole count, set at declaration", "whole count"), ("a positive count.", "positive count"), ("the instant a call evaluates against", "instant"),
                                 ("the opaque value naming one pool; host-allocated at the seam", "id"), ("the opaque string naming who it is for", "string")):
            d = self.doc("Thing", "thing", definition, "thing")
            self.assertEqual(ir.input_types_of(d), [])
            self.assertEqual(d["signatures"][0]["inputs"][0]["type"]["type"], want, definition)

    def test_a_term_that_gives_none_leaves_the_input_untyped_and_says_so_once(self):
        d = self.doc("Thing", "thing", "the filter set a read accepts", "thing")
        d["signatures"].append({"action": "Stop", "line": 9, "inputs": [{"name": "thing", "optional": False}]})
        gaps = ir.input_types_of(d)
        self.assertEqual([g["kind"] for g in gaps], ["no-input-type"])
        self.assertIsNone(d["signatures"][0]["inputs"][0]["type"])
        self.assertIn("found no count", gaps[0]["what"])

    def test_a_name_that_says_reference_is_a_string_where_the_term_says_nothing(self):
        d = self.doc("Closing Actor Reference", "closer_ref", "", "closer_ref")
        self.assertEqual(ir.input_types_of(d), [])
        self.assertEqual(d["signatures"][0]["inputs"][0]["type"]["type"], "string")


class PassedOver(unittest.TestCase):
    def doc(self, gaps=()):
        rule = {"label": "Operation 5", "family": "Operation", "text": "A refused [Make] MUST NOT record a widget.", "line": 7}
        return {"rules": [rule], "terms": [], "signatures": [{"action": "Make", "inputs": [], "answers": [], "refuses": [], "line": 1}], "reader_gaps": list(gaps),
                "normalized": {"rules": {"Operation 5": {"subject": "a refused call", "obligations": [{"act": "record", "modal": "MUST NOT", "object": "a widget"}]}}}}

    def test_a_rule_that_names_an_action_and_reads_none_is_a_miss_and_says_so(self):
        count, gaps = ir.passed_over(self.doc())
        self.assertEqual(count["subject-named-action"]["miss"], 1)
        self.assertEqual([(g["kind"], g["rule"]) for g in gaps], [("not-read", "Operation 5")])
        self.assertIn("[Make]", gaps[0]["what"])

    def test_a_pass_over_a_gap_already_names_is_counted_said_and_adds_none(self):
        said = {"rule": "Operation 5", "line": 7, "kind": "no-action", "what": "the reader read no action"}
        count, gaps = ir.passed_over(self.doc([said]))
        self.assertEqual((count["subject-named-action"]["said"], count["subject-named-action"]["miss"], gaps), (1, 0, []))

    def test_a_gap_renders_from_its_template_and_slots_and_is_the_dict_the_document_carries(self):
        g = ir.gap("no-set", "Term x", 3, "no set read: {why!r} in {where}", why="a", where="b")
        self.assertEqual(dict(g), {"rule": "Term x", "line": 3, "kind": "no-set", "what": "no set read: 'a' in b"})
        self.assertEqual(g.slots, {"why": "a", "where": "b"})
        self.assertEqual(json.loads(json.dumps(g)), dict(g))


class TermFields(unittest.TestCase):
    ENTRIES = [entry("person reference", Kind="Field"), entry("item reference", Kind="Field")]

    def test_the_list_a_definition_opens_with_is_the_fields_in_its_order(self):
        got, why = ir.term_fields({"name": "pair", "definition": "the item reference and the person reference of a favorite"}, self.ENTRIES)
        self.assertEqual([e["name"] for e in got], ["item reference", "person reference"])
        self.assertEqual(why, "")

    def test_a_list_that_runs_on_to_a_non_field_is_carried_in_no_part(self):
        got, why = ir.term_fields({"name": "pair", "definition": "the person reference and the colour of the item"}, self.ENTRIES)
        self.assertEqual(got, [])
        self.assertIn("the list is not carried in part", why)

    def test_a_definition_that_opens_with_no_field_gives_none(self):
        got, why = ir.term_fields({"name": "pair", "definition": "an opaque string"}, self.ENTRIES)
        self.assertEqual(got, [])
        self.assertIn("read no list of Field entries", why)


class Guards(unittest.TestCase):
    """guard_test: what one clause reads."""

    def setUp(self):
        self.doc = {"term_entries": [entry("Reaction Name", Kind="Field", Projection="reaction_name"),
                                     entry("Item Reference", Kind="Field", Projection="item_reference")],
                    "terms": [], "settings": [{"term": "reaction set", "of": "reaction_name", "rule": "Capability requirement 3", "line": 1,
                                               "default": {"text": "x", "value": "x"}}]}
        self.cx = ir.shape_context(self.doc)
        self.inputs = {"reaction_name", "item_reference"}

    def read(self, clause: dict, keys=None) -> dict:
        return ir.guard_test(clause, self.doc, self.cx, keys or [], self.inputs, {"label": "Operation 1"})

    def test_a_blank_input_is_an_input_test(self):
        got = self.read({"kind": "comparison", "text": "the reaction name EQUALS blank", "left": "the reaction name", "op": "EQUALS", "right": "blank"})
        self.assertEqual((got["reads"], got["input"], got["test"], got["negated"]), ("input", "reaction_name", "blank", False))

    def test_does_not_equal_blank_is_negated(self):
        got = self.read({"kind": "comparison", "text": "t", "left": "the reaction name", "op": "DOES NOT EQUAL", "right": "blank"})
        self.assertTrue(got["negated"])

    def test_no_member_of_a_setting_equal_to_its_field_is_a_setting_member_test(self):
        got = self.read({"kind": "comparison", "text": "no member of the reaction set EQUALS the reaction name", "left": "no member of the reaction set",
                         "op": "EQUALS", "right": "the reaction name"})
        self.assertEqual((got["reads"], got["setting"], got["input"]), ("setting_member", "reaction set", "reaction_name"))

    def test_no_member_of_a_set_that_is_no_setting_is_prose(self):
        got = self.read({"kind": "comparison", "text": "no member of the other set EQUALS the reaction name", "left": "no member of the other set",
                         "op": "EQUALS", "right": "the reaction name"})
        self.assertEqual(got["reads"], "prose")

    def test_the_database_refusing_the_write_is_read_as_it(self):
        got = self.read({"kind": "predicate", "text": "the database refuses the write"})
        self.assertEqual(got["reads"], "database_refusal")

    def test_a_predicate_that_is_no_known_form_is_prose_and_says_why(self):
        got = self.read({"kind": "predicate", "text": "the reaction is weird"})
        self.assertEqual(got["reads"], "prose")
        self.assertTrue(got["why"])


def kinded(name: str, line: int, **kind: str) -> dict:
    return {"name": name, "text": "", "kind": dict(kind), "line": line}


def rule(label: str, text: str, line: int = 1) -> dict:
    return {"label": label, "family": label.rsplit(" ", 1)[0], "text": text, "line": line}


class StandardSentences(unittest.TestCase):
    """ir_data.standard: each standard sentence read into the IR's keys, links, ranges and records, and each claim of the
    same kind said another way read as no claim and named as a departure (GRACE-lang, the section titled Standard sentences)."""
    ENTRIES = [kinded("Box", 1, Kind="Type"), kinded("Box Id", 2, Kind="Field", **{"Field of": "Box", "Projection": "box_id"}),
               kinded("Label", 3, Kind="Field", **{"Field of": "Box", "Projection": "label"}),
               kinded("Item", 4, Kind="Type"), kinded("Item Id", 5, Kind="Field", **{"Field of": "Item", "Projection": "item_id"}),
               kinded("Item Reference", 6, Kind="Field", **{"Field of": "Item", "Projection": "item_reference"}),
               kinded("Count", 7, Kind="Field", **{"Field of": "Item", "Projection": "count"}),
               kinded("Colour", 8, Kind="Field", **{"Field of": "Boxes", "Projection": "colour"})]
    TERMS = {"positive count", "whole amount"}

    def read(self, *rules: dict) -> dict:
        return ir.standard(list(rules), self.ENTRIES, self.TERMS)

    def test_a_key_in_its_sentence_is_a_key_of_the_record_type(self):
        got = self.read(rule("Invariant 1.1", "Two boxes MUST NOT share a label."))
        self.assertEqual([(k["form"], k["thing"], k["fields"]) for k in got["keys"]], [("key", "box", ["label"])])

    def test_a_key_within_an_owner_names_the_owner(self):
        got = self.read(rule("Invariant 1.2", "Two items one box carries MUST NOT share an item reference."))
        self.assertEqual([(k["form"], k["thing"], k["owner"], k["fields"]) for k in got["keys"]],
                         [("key within an owner", "item", "box", ["item_reference"])])

    def test_a_link_takes_its_field_from_the_record_type_or_the_linked_one(self):
        got = self.read(rule("Invariant 2.1", "EVERY item's box id MUST name a box."))
        self.assertEqual([(x["thing"], x["fields"], x["field_of"], x["target"]) for x in got["links"]], [("item", ["box_id"], "box", "box")])

    def test_a_range_names_its_bound_and_the_term(self):
        got = self.read(rule("Invariant 3.1", "EVERY item MUST carry a positive count as the item's count."))
        self.assertEqual([(x["thing"], x["fields"], x["bound"], x["term"]) for x in got["ranges"]], [("item", ["count"], "positive", "positive count")])

    def test_every_declared_type_with_fields_is_a_record_and_takes_its_key(self):
        got = self.read(rule("Invariant 1.1", "Two boxes MUST NOT share a label."))
        self.assertEqual([(r["name"], r["form"], r["carries"], r["key"]) for r in got["records"]],
                         [("box", "type", ["box_id", "label"], ["label"]), ("item", "type", ["item_id", "item_reference", "count"], None)])

    def test_each_variant_is_no_claim_and_a_departure_of_its_kind(self):
        got = self.read(rule("Invariant 4.1", "Two distinct boxes MUST NOT share a label."),
                        rule("Invariant 4.2", "Two items in one box MUST NOT share an item reference."),
                        rule("Invariant 4.3", "Two boxes MUST NOT share a label AND a box id."),
                        rule("Invariant 4.4", "EVERY item MUST name EXACTLY ONE box."),
                        rule("Invariant 4.5", "EVERY item's count MUST stand as a positive count."),
                        rule("Operation 9", "Two boxes MUST NOT share a label."))
        self.assertEqual((got["keys"], got["links"], got["ranges"]), ([], [], []))
        self.assertEqual(sorted((d[0], d[1]) for d in got["departures"]),
                         [("key", "Invariant 4.1"), ("key", "Invariant 4.3"), ("link", "Invariant 4.4"), ("owner key", "Invariant 4.2"),
                          ("range", "Invariant 4.5"), ("record", "Colour")])

    def test_the_plural_is_the_regular_english_plural(self):
        self.assertEqual([ir.plural(n) for n in ("line", "category", "box", "consent record", "day")], ["lines", "categories", "boxes", "consent records", "days"])


class TreeOrder(unittest.TestCase):
    """spec-format.md, the section titled The tree order: the reader reads a pattern in the tree order by form, to the same rules, terms, term
    entries, signatures, checks, Non-goals with their owners, case rows, Summary, keys, guards and settings as the pattern in the section shape, with
    only their order and their line numbers changed. The pair is Tenure, as it stood when the forms unit landed, and the maintainer's approved trial
    of it (working-ideas/tenure-tree.md, 2026-11-18), each a fixed copy in testdata."""

    @classmethod
    def setUpClass(cls):
        cls.docs = {}
        for name in ("tenure.md", "tenure.tree.md"):
            tmp, root = root_with("")
            with tmp:
                (root / "atoms" / "tenure.md").write_text((HERE / "testdata" / name).read_text(encoding="utf-8"), encoding="utf-8")
                cls.docs[name] = ir.parse(root / "atoms" / "tenure.md", root)

    @staticmethod
    def bare(x):
        if isinstance(x, dict):
            return {k: TreeOrder.bare(v) for k, v in x.items() if k not in ("line", "section", "caption", "gaps")}
        if isinstance(x, list):
            return sorted((TreeOrder.bare(v) for v in x), key=lambda v: json.dumps(v, sort_keys=True))
        return x

    def test_the_tree_order_reads_the_same_as_the_section_shape(self):
        a, b = self.docs["tenure.md"], self.docs["tenure.tree.md"]
        self.assertGreater(len(a["term_entries"]), 0)
        for k in ("rules", "terms", "term_entries", "signatures", "checks", "non_goals", "summary", "keys", "links", "ranges", "records",
                  "guards", "settings", "transitions", "projectable"):
            self.assertEqual(self.bare(a[k]), self.bare(b[k]), k)
        self.assertEqual(self.bare([r for t in a["case_tables"] for r in t["rows"]]), self.bare([r for t in b["case_tables"] for r in t["rows"]]))

    def test_same_reads_no_difference_between_the_shapes_and_names_a_changed_rule(self):
        tmp, root = root_with("")
        with tmp:
            old, new = root / "atoms" / "tenure.md", root / "atoms" / "tenure-tree.md"
            old.write_text((HERE / "testdata" / "tenure.md").read_text(encoding="utf-8"), encoding="utf-8")
            tree = (HERE / "testdata" / "tenure.tree.md").read_text(encoding="utf-8")
            new.write_text(tree, encoding="utf-8")
            self.assertEqual(ir.same(ir.parse(old, root), ir.parse(new, root)), [])
            new.write_text(tree.replace("The start date of EVERY tenure carrying", "The start date of a tenure carrying", 1), encoding="utf-8")
            got = ir.same(ir.parse(old, root), ir.parse(new, root))
            self.assertEqual([g.split(":", 1)[0] for g in got], ["rules", "rules"])
            self.assertTrue(all("Invariant 1.1" in g for g in got))

    def test_the_tree_order_keeps_an_action_entry_at_its_branch(self):
        begin = next(e for e in self.docs["tenure.tree.md"]["term_entries"] if e["name"] == "Begin")
        self.assertEqual(begin["kind"], {"Kind": "Operation"})


class Corpus(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp, cls.root = root_with(FIXTURE.read_text(encoding="utf-8"))
        cls.doc = ir.parse(cls.root / "atoms" / "reaction.md", cls.root)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_golden(self):
        want = json.loads(GOLDEN.read_text(encoding="utf-8"))
        got = json.loads(json.dumps(golden_of(self.doc)))
        for k in sorted(set(want) | set(got)):
            self.assertEqual(want.get(k), got.get(k), f"`{k}` of the document differs from testdata/reaction.ir.json (--update-golden if the reader meant to)")

    def test_every_gap_has_a_known_kind(self):
        for g in self.doc["reader_gaps"]:
            self.assertIn(g.get("kind"), KINDS, g)

    def test_the_projectable_table_is_one_entry_of_a_known_class_for_each_rule_in_order(self):
        self.assertEqual([x["rule"] for x in self.doc["projectable"]], [r["label"] for r in self.doc["rules"]])
        for x in self.doc["projectable"]:
            self.assertIn(x["as"], ir.PROJECTABLE)
            if x["as"] in ("check-only", "not-carried"):
                self.assertTrue(x["why"], x)

    def test_a_rule_that_is_not_carried_names_what_it_rests_on(self):
        for x in self.doc["projectable"]:
            if x["as"] == "not-carried":
                self.assertTrue(x["why"])

    def test_the_reaction_set_guard_is_a_whole_guard_of_the_setting(self):
        guard = next(g for g in self.doc["guards"] if any(t["reads"] == "setting_member" for t in g["tests"]))
        self.assertTrue(guard["whole"])
        self.assertEqual(next(x for x in self.doc["projectable"] if x["rule"] == guard["rule"])["as"], "guard")

    def test_the_document_carries_the_sha256_of_its_text(self):
        import hashlib
        self.assertEqual(self.doc["source_sha256"], hashlib.sha256(FIXTURE.read_bytes()).hexdigest())

    def test_the_gap_table_has_a_row_and_a_total(self):
        table = ir.gap_table([self.doc])
        self.assertTrue(table.splitlines()[0].startswith("spec"))
        self.assertTrue(table.splitlines()[-1].startswith("all"))


class Proof(unittest.TestCase):
    def findings(self, spec: str, contract: str | None = None) -> list:
        tmp, root = root_with(spec, contract)
        with tmp:
            docs, found = ir.build(root)
            return found + ir.prove(root, docs)

    def test_the_fixture_alone_has_no_finding(self):
        self.assertEqual(self.findings(FIXTURE.read_text(encoding="utf-8")), [])

    def test_a_term_entry_declared_twice_is_a_finding(self):
        text = FIXTURE.read_text(encoding="utf-8")
        m = re.search(r"^(#### [^\n]+\n(?:[^\n#][^\n]*\n|\n)+?)(?=####|\n## |\Z)", text[text.index("## Terms"):], re.M)
        twice = text.replace(m.group(1), m.group(1) + "\n" + m.group(1), 1)
        self.assertIn("IR-entry", [f[2] for f in self.findings(twice)])

    def test_contract_arms_are_proved_against_read_3(self):
        spec = FIXTURE.read_text(encoding="utf-8")
        said = "**Read 3: A state-unavailable answer writes nothing.** An action that answers it writes nothing."
        gone = "**Read 3: A failed read writes nothing.** An action that fails to read writes nothing."
        self.assertNotIn("IR-contract-arms", [f[2] for f in self.findings(spec, said)])
        self.assertIn("IR-contract-arms", [f[2] for f in self.findings(spec, gone)])


# One golden document for each part the Reader was split into (unit `tooling: the Reader in parts, the same IR to the byte`): the fixtures of tools/linter/test_checks.py,
# read as a whole, so a change to what any part reads shows as a change to a document, with the fields that say where and when it was read left out.
sys.path.insert(0, str(HERE.parent / "linter"))
import test_checks as T  # noqa: E402

PART_GOLDENS = {
    "id-key": ("atoms", "tag", T.IR_ID_KEY, None),
    "transitions": ("atoms", "tag", T.IR_TRANSITION, None),
    "shapes": ("atoms", "gift", T.IR_READ_ANSWERS, None),
    "guards": ("atoms", "tag", T.IR_GUARDS, None),
    "wiring": ("compositions", "room", T.IR_WIRING_ROOM, ("atoms", "lamp", T.IR_WIRING_LAMP)),
}


def read_part(name: str) -> dict:
    kind, stem, text, other = PART_GOLDENS[name]
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "atoms").mkdir()
        (root / "compositions").mkdir()
        (root / "execution-contract.md").write_text(T.IR_READER_CONTRACT, encoding="utf-8")
        (root / kind / (stem + ".md")).write_text(text, encoding="utf-8")
        if other:
            (root / other[0] / (other[1] + ".md")).write_text(other[2], encoding="utf-8")
        return golden_of(ir.parse(root / kind / (stem + ".md"), root))


class PartGoldens(unittest.TestCase):
    def check(self, name: str):
        want = json.loads((HERE / "testdata" / f"part-{name}.ir.json").read_text(encoding="utf-8"))
        got = json.loads(json.dumps(read_part(name), ensure_ascii=False, sort_keys=True))
        for k in sorted(set(want) | set(got)):
            self.assertEqual(want.get(k), got.get(k), f"`{k}` of the {name} document differs from testdata/part-{name}.ir.json (--update-golden if the reader meant to)")

    def test_an_id_key_the_host_allocates(self):
        self.check("id-key")

    def test_the_transitions_of_a_record(self):
        self.check("transitions")

    def test_the_shapes_of_what_a_read_answers(self):
        self.check("shapes")

    def test_the_guards_of_a_rule(self):
        self.check("guards")

    def test_a_compositions_calls_bindings_records_and_transactions(self):
        self.check("wiring")


if __name__ == "__main__":
    if "--update-golden" in sys.argv:
        sys.argv.remove("--update-golden")
        tmp, root = root_with(FIXTURE.read_text(encoding="utf-8"))
        with tmp:
            GOLDEN.write_text(json.dumps(golden_of(ir.parse(root / "atoms" / "reaction.md", root)), indent=1, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
        for name in PART_GOLDENS:
            (HERE / "testdata" / f"part-{name}.ir.json").write_text(json.dumps(read_part(name), indent=1, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    unittest.main()

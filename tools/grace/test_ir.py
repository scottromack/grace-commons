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
         "no-constituent", "no-arm", "no-binding", "record-types"}


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


if __name__ == "__main__":
    if "--update-golden" in sys.argv:
        sys.argv.remove("--update-golden")
        tmp, root = root_with(FIXTURE.read_text(encoding="utf-8"))
        with tmp:
            GOLDEN.write_text(json.dumps(golden_of(ir.parse(root / "atoms" / "reaction.md", root)), indent=1, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    unittest.main()

#!/usr/bin/env python3
"""Tests for the normalizer (tools/grace/normalize.py) and the reverse diff
(tools/grace/rdiff.py), beside test_checks.py.

    python3 tools/linter/test_normalize.py [repo_root]

Each case pins one parser property of GRACE-lang section 11 or one rule of
section 16 and 17 on a small spec written for it, and the round-trip property
on every rule of the corpus: a rule normalizes to the same form whatever order
the rules come in (Hard invariant 15), two outcomes stay non-exclusive unless
`EXACTLY ONE OF` states it (17), normalizing twice gives the same form and each
sugar form maps to one (18, 19), no WHY: or UX: line reaches the form (21, 22,
23), `no thing EXISTS` lowers to the thing's absence (33), and the two advisory
checks over the form read what they are written to read: a cross-rule reference
by ordinal (13) and a value in a condition that belongs to no declared closed
value set (14).
"""
from __future__ import annotations

import contextlib
import io
import json
import random
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE.parent / "grace"))
sys.path.insert(0, str(HERE))
import ir  # noqa: E402
import normalize as n  # noqa: E402
import rdiff  # noqa: E402


def spec(*rules: str, head: str = "", tail: str = "") -> str:
    """A small atom whose one rules block holds the rules, a rule per line."""
    return (f"# Probe\n\nTerm qualifiers: migrated.\n\n{head}\n\n```\n" + "\n".join(rules) + f"\n```\n{tail}\n")


def parse(text: str) -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "probe.md"
        path.write_text(text, encoding="utf-8")
        return ir.parse(path, Path(tmp))


def forms(*rules: str, **kw) -> dict:
    return parse(spec(*rules, **kw))["normalized"]["rules"]


def one(rule: str) -> dict:
    """The form of one rule written with the label `Operation 1`."""
    return forms(f"Operation 1: {rule}")["Operation 1"]


class Hard15Order(unittest.TestCase):
    """Hard invariant 15: the parser MUST NOT infer from rule order."""

    RULES = [
        "Operation 1: IF the cart EQUALS blank THEN [Add] MUST answer invalid-cart.",
        "Operation 2: [Add] MUST NOT write ONLY AFTER the cart check.",
        "Operation 3: WHEN the line EXISTS:",
        "    Operation 3a: [Remove] MUST remove the line.",
        "    Operation 3b: [Remove] MUST answer removed.",
        "Operation 4: EVERY line MUST carry a quantity.",
    ]

    def test_shuffled_rules_give_the_same_form(self):
        groups = [self.RULES[0:1], self.RULES[1:2], self.RULES[2:5], self.RULES[5:6]]
        want = parse(spec(*self.RULES))["normalized"]
        for seed in range(12):
            random.Random(seed).shuffle(groups)
            got = parse(spec(*[line for g in groups for line in g]))["normalized"]
            self.assertEqual(json.dumps(got, sort_keys=True), json.dumps(want, sort_keys=True), seed)

    def test_the_form_holds_no_line_number_and_no_position(self):
        text = json.dumps(parse(spec(*self.RULES))["normalized"])
        self.assertNotIn('"line":', text)
        self.assertNotIn('"section":', text)

    def test_a_when_child_carries_the_blocks_condition(self):
        f = forms(*self.RULES)
        self.assertEqual(f["Operation 3a"]["when"]["label"], "Operation 3")
        self.assertEqual(f["Operation 3a"]["when"]["condition"], f["Operation 3"]["condition"])
        self.assertEqual(f["Operation 3"]["children"], ["Operation 3a", "Operation 3b"])

    def test_the_corpus_reads_the_same_shuffled(self):
        for rel in ("atoms/cart.md", "atoms/session.md"):
            path = ROOT / rel
            if not path.exists():
                continue
            lines = path.read_text(encoding="utf-8").split("\n")
            for kind, _, body in ir.blocks(lines):
                if kind != "rules":
                    continue
                run = [lines[k] for k in body if lines[k].strip() and not lines[k].startswith((" ", "WHY", "NOTE", "UX"))]
                if len(run) != sum(1 for k in body if lines[k].strip()):
                    continue  # a block with a WHEN child, a prefix line or a continuation stays as written
                shuffled = list(run)
                random.Random(1).shuffle(shuffled)
                at = [k for k in body if lines[k].strip()]
                for k, line in zip(at, shuffled):
                    lines[k] = line
            before = ir.parse(path, ROOT)["normalized"]["rules"]
            with tempfile.TemporaryDirectory() as tmp:
                p = Path(tmp) / path.name
                p.write_text("\n".join(lines), encoding="utf-8")
                after = ir.parse(p, Path(tmp))["normalized"]["rules"]
            self.assertEqual(json.dumps(after, sort_keys=True), json.dumps(before, sort_keys=True), rel)


class Hard17Exclusivity(unittest.TestCase):
    """Hard invariant 17: no exclusivity among outcomes unless EXACTLY ONE OF states it."""

    def test_two_outcomes_are_not_exclusive(self):
        f = forms("Operation 1: [Check] MUST answer seen.", "Operation 2: [Check] MUST answer not-seen.")
        for form in f.values():
            self.assertNotIn("exclusive", form["obligations"][0])
        self.assertNotIn("exclusive", json.dumps(f))

    def test_exactly_one_of_states_it(self):
        o = one("[Check] MUST answer EXACTLY ONE OF seen, not-seen.")["obligations"][0]
        self.assertEqual(o["exclusive"], ["seen", "not-seen"])
        self.assertEqual((o["act"], o["object"]), ("answer", ""))

    def test_a_quantified_subject_is_not_an_exclusive_set(self):
        f = one("EXACTLY ONE lifecycle state MUST stand PER actor.")
        self.assertEqual(f["quantifier"], "EXACTLY ONE")
        self.assertNotIn("exclusive", f["obligations"][0])


class Hard18And19Sugar(unittest.TestCase):
    """Hard invariant 18 and 19: sugar normalizes without adding meaning, to one canonical form."""

    def test_after_is_only_after_under_must_and_may(self):
        for modal in ("MUST", "MAY"):
            a = one(f"[Sweep] {modal} run AFTER the edge.")
            b = one(f"[Sweep] {modal} run ONLY AFTER the edge.")
            self.assertEqual(a, b)
            self.assertEqual(a["obligations"][0]["timing"], [{"kind": "ONLY AFTER", "term": "the edge"}])

    def test_multiply_sign_is_star_and_the_expression_an_unnamed_term(self):
        a = one("IF the line total EXCEEDS (unit price × quantity) THEN [Check] MUST answer over-limit.")
        b = one("IF the line total EXCEEDS (unit price * quantity) THEN [Check] MUST answer over-limit.")
        self.assertEqual(a, b)
        self.assertEqual(a["terms"], [{"op": "*", "left": "unit price", "right": "quantity"}])
        self.assertIn("(unit price * quantity)", n.render(a))

    def test_the_tails_read_in_one_order(self):
        a = one("[Sweep] MUST run WITHIN the bound ONLY AFTER the edge.")
        b = one("[Sweep] MUST run ONLY AFTER the edge WITHIN the bound.")
        self.assertEqual(a, b)

    def test_normalizing_twice_gives_the_same_form(self):
        for rule in (
            "IF the cart EQUALS blank OR the cart EXCEEDS the cap THEN [Add] MUST answer invalid-cart.",
            "[Sweep] MAY run AFTER the edge ONLY IF the lease EXISTS AND the bound DOES NOT EXCEED now.",
            "IF no hold EXISTS for the hold id THEN [Release] MUST answer not-known AND MUST NOT write.",
            "EVERY pool MUST stand in EXACTLY ONE OF open, closed.",
            "The step log IS AUTHORITATIVE FOR a workflow's progress.",
            "A deployment MUST supply the records PER Execution Contract Database 1 through 4 (Invariant 2.1).",
        ):
            f = one(rule)
            again, problems = n.lower_statement(n.render(f))
            self.assertEqual((again, problems), (f, []), rule)

    def test_every_rule_of_the_corpus_lowers_to_itself(self):
        bad = []
        for d in ir.build(ROOT)[0]:
            forms_, _ = n.lower_rules(d["rules"])
            for label, f in forms_.items():
                if f["kind"] in ("excluded", "unlowered"):
                    continue
                again, problems = n.lower_statement(n.render(f))
                if problems or again != {k: v for k, v in f.items() if k not in ("when", "children")}:
                    bad.append(f"{d['spec']} {label}")
        self.assertEqual(bad, [])


class Hard21To23NoWhyOrUx(unittest.TestCase):
    """Hard invariant 21 through 23: WHY: and UX: carry no normative force and no meaning."""

    RULES = ("Operation 1: [Add] MUST answer added.", "Operation 2: [Add] MUST NOT write ONLY IF the cart EXISTS.")

    def test_no_why_or_ux_line_reaches_the_form(self):
        bare = parse(spec(*self.RULES))["normalized"]
        noted = parse(spec(
            "Operation 1: [Add] MUST answer added.", "WHY: zebra because the cart must hold lines.",
            "UX: the screen shows a quokka.", "NOTE: giraffe a remark.",
            "Operation 2: [Add] MUST NOT write ONLY IF the cart EXISTS.", "PROVISIONAL: llama this may change."))["normalized"]
        self.assertEqual(noted, bare)
        for word in ("zebra", "quokka", "giraffe", "llama"):
            self.assertNotIn(word, json.dumps(noted))

    def test_a_prefixed_rule_body_is_excluded_and_carries_nothing(self):
        f = forms("Operation 1: PROVISIONAL: Invariant 4.2 DEGRADES TO Invariant 4.6.")["Operation 1"]
        self.assertEqual(f, {"kind": "excluded", "prefix": "PROVISIONAL"})


class Hard33Absence(unittest.TestCase):
    """Hard invariant 33: `no thing EXISTS` is the thing's absence."""

    def test_no_thing_exists_lowers_to_absence(self):
        c = one("IF no hold EXISTS for the hold id THEN [Release] MUST answer not-known.")["if"]["clauses"][0]
        self.assertEqual((c["kind"], c["thing"], c["qualifier"]), ("absence", "hold", "for the hold id"))

    def test_thing_exists_lowers_to_presence(self):
        c = one("IF a hold EXISTS THEN [Release] MUST answer released.")["if"]["clauses"][0]
        self.assertEqual((c["kind"], c["thing"]), ("presence", "a hold"))


class Unlowered(unittest.TestCase):
    """A rule the normalizer cannot lower is an advisory finding, carried as written."""

    def test_a_positive_before_is_unlowered(self):
        text = spec("Operation 1: [Sweep] MUST run BEFORE the edge.")
        d = parse(text)
        self.assertEqual(d["normalized"]["rules"]["Operation 1"]["kind"], "unlowered")
        codes = [(f[2], f[3]) for f in n.findings(d)]
        self.assertEqual([c for c, _ in codes], ["N-unlowered"])
        self.assertIn("BEFORE", codes[0][1])

    def test_a_mixed_condition_is_unlowered(self):
        f = n.findings(parse(spec("Operation 1: IF a EQUALS b AND c EQUALS d OR e EQUALS f THEN [X] MUST answer y.")))
        self.assertEqual([x[2] for x in f if x[2] == "N-unlowered"], ["N-unlowered"])

    def test_a_statement_with_no_modal_is_unlowered(self):
        f = one("The cart holds lines.")
        self.assertEqual(f["kind"], "unlowered")

    def test_a_lowered_rule_raises_no_finding(self):
        self.assertEqual(n.findings(parse(spec("Operation 1: [Add] MUST answer added."))), [])


class Hard13OrdinalReference(unittest.TestCase):
    def codes(self, rule):
        return [f[2] for f in n.findings(parse(spec(f"Operation 1: {rule}")))]

    def test_a_reference_by_place_fires(self):
        for ref in ("IF no rule above names the arm THEN [X] MUST answer y.",
                    "[X] MUST apply the previous rule.", "[X] MUST follow rule 3."):
            self.assertEqual(self.codes(ref), ["N-ordinal-ref"], ref)

    def test_a_reference_by_label_stays_silent(self):
        self.assertEqual(self.codes("[X] MUST follow Operation 3 (Invariant 2.1)."), [])
        self.assertEqual(self.codes("A deployment under Rule 37(e) of the Federal Rules MUST NOT set advisory."), [])


class Hard14ValueSet(unittest.TestCase):
    VALUES = "Term lease state: held | released | lapsed — where a lease stands."

    def codes(self, rule, head=VALUES):
        return [f[2] for f in n.findings(parse(spec(f"Operation 1: {rule}", head=head)))]

    def test_a_declared_value_stays_silent(self):
        self.assertEqual(self.codes("IF the lease EQUALS held THEN [X] MUST answer y."), [])
        self.assertEqual(self.codes("IF the lease DOES NOT EQUAL lapsed THEN [X] MUST answer y."), [])

    def test_blank_and_a_compared_term_stay_silent(self):
        self.assertEqual(self.codes("IF the cart EQUALS blank THEN [X] MUST answer y."), [])
        self.assertEqual(self.codes("IF the new quantity EQUALS the line's quantity THEN [X] MUST NOT write."), [])
        self.assertEqual(self.codes("IF the count EQUALS zero THEN [X] MUST answer y."), [])

    def test_an_undeclared_value_fires(self):
        self.assertEqual(self.codes("IF the lease EQUALS expired THEN [X] MUST answer y."), ["N-value-set"])
        self.assertEqual(self.codes("IF a hold EXISTS whose state EQUALS frozen THEN [X] MUST answer y."), ["N-value-set"])

    def test_a_signature_answer_and_an_exclusive_set_declare_values(self):
        sig = "```\ncheck(token)\n  answers seen | not-seen\n```"
        self.assertEqual(self.codes("IF the answer EQUALS seen THEN [X] MUST answer y.", head=sig), [])
        self.assertEqual(self.codes("IF the answer EQUALS seen THEN [X] MUST answer y.", head=""), ["N-value-set"])


class ReverseDiff(unittest.TestCase):
    """GRACE-lang section 17."""

    BASE = ("Operation 1: [Add] MUST answer added.", "Operation 2: [Sweep] MUST run AFTER the edge.",
            "Operation 3: IF the unit price EXCEEDS (a × b) THEN [Add] MUST answer too-dear.")

    def run_diff(self, old, new):
        return [(r, lab) for r, lab, _, _ in rdiff.diff(rdiff.forms_of(spec(*old)), rdiff.forms_of(spec(*new)))]

    def test_added_removed_and_changed(self):
        new = ("Operation 1: [Add] MUST answer accepted.", self.BASE[1], self.BASE[2], "Operation 4: [Add] MUST NOT write.")
        self.assertEqual(self.run_diff(self.BASE, new), [("CHANGED", "Operation 1"), ("ADDED", "Operation 4")])
        self.assertEqual(self.run_diff(self.BASE, self.BASE[:2]), [("REMOVED", "Operation 3")])

    def test_forms_that_normalize_identically_are_equivalent(self):
        new = (self.BASE[0], "Operation 2: [Sweep] MUST run ONLY AFTER the edge.",
               "Operation 3: IF the unit price EXCEEDS (a * b) THEN [Add] MUST answer too-dear.")
        self.assertEqual(self.run_diff(self.BASE, new), [])

    def test_a_change_to_why_or_ux_is_not_reported(self):
        old = spec(*self.BASE)
        new = spec(self.BASE[0], "WHY: a new reason.", "UX: a new screen.", "NOTE: a new note.", *self.BASE[1:])
        self.assertEqual(rdiff.diff(rdiff.forms_of(old), rdiff.forms_of(new)), [])

    def test_a_rule_moved_to_another_label_unchanged_is_equivalent(self):
        new = (self.BASE[0], self.BASE[1], "Operation 9: IF the unit price EXCEEDS (a * b) THEN [Add] MUST answer too-dear.")
        self.assertEqual(self.run_diff(self.BASE, new), [])

    def test_an_unlowered_rule_is_compared_by_its_text(self):
        old = ("Operation 1: The cart holds lines.",)
        self.assertEqual(self.run_diff(old, ("Operation 1: The cart holds lines.",)), [])
        self.assertEqual(self.run_diff(old, ("Operation 1: The cart holds items.",)), [("CHANGED", "Operation 1")])

    def test_a_changed_condition_or_modal_is_changed(self):
        new = (self.BASE[0], "Operation 2: [Sweep] MUST NOT run ONLY AFTER the edge.", self.BASE[2])
        self.assertEqual(self.run_diff(self.BASE, new), [("CHANGED", "Operation 2")])


class Corpus(unittest.TestCase):
    def test_every_rule_has_a_form_and_the_advisories_name_no_missing_rule(self):
        docs, _ = ir.build(ROOT)
        by_path = {d["spec"]: d for d in docs}
        for d in docs:
            self.assertEqual(sorted(d["normalized"]["rules"]), sorted(r["label"] for r in d["rules"]), d["spec"])
            for _, _, code, _ in n.findings(d, by_path):
                self.assertIn(code, ("N-unlowered", "N-ordinal-ref", "N-value-set"))

    def test_the_advisories_do_not_gate(self):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(n.main(["normalize.py"]), 0)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if args:
        ROOT = Path(args[0]).resolve()
        sys.argv = [sys.argv[0]]
    unittest.main(verbosity=1)

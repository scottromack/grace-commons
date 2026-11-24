#!/usr/bin/env python3
"""The bonds (unit `bonds: the fifty`): check.py's bond_findings reads bonds.md, declarations.md and
the atoms' `Term need <kind>:` and `Term offer <kind>:` lines, and matches each need to its offers by type."""
import os
import sys
import tempfile
import unittest
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import check  # noqa: E402

BONDS = """# Bonds

Term guard need fields: key, the key; holder, the holder; span, how long; calls, the calls; arms, the answers; writes, the records.

Term guard offer fields: key, the keys; holder, the holders; span, the length; calls, the calls; arms, the answers.

Term key need fields: key, the value; pairs, the records.

Term key offer fields: key, the value; carried by, the records.
"""

DECLARATIONS = """# Declarations

Term declaration type: opaque | duration.

Term section key: opaque — a key.

Term section holder: opaque — a holder.

Term invocation id: opaque — an id.
"""

OFFER = "Term offer guard: key opaque; holder opaque; span duration; calls take, remaining, release; arms expires_at, none, released.\n"
NEED = "Term need guard: key section key; holder section holder; span duration; calls take, release; arms expires_at, released; writes closing record.\n"


def atom(title: str, body: str) -> str:
    return f"---\ntitle: {title}\nid: 1\n---\n\n# {title}\n\n{body}"


class BondTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "atoms").mkdir()
        (self.root / "bonds.md").write_text(BONDS)
        (self.root / "declarations.md").write_text(DECLARATIONS)
        self.write("guard-offerer", atom("Guard Offerer", OFFER))
        self.write("guard-needer", atom("Guard Needer", NEED))

    def write(self, name: str, text: str) -> None:
        (self.root / "atoms" / f"{name}.md").write_text(text)

    def codes(self):
        return sorted(f.code for f in check.bond_findings(self.root))

    def test_a_need_that_meets_exactly_one_offer_passes(self):
        self.assertEqual(self.codes(), [])

    def test_a_kind_the_bonds_page_does_not_state_gates(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("need guard", "need priority")))
        self.assertEqual(self.codes(), ["B-bond-kind"])

    def test_a_field_the_kind_does_not_carry_gates(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("; writes", "; colour red; writes")))
        self.assertEqual(self.codes(), ["B-bond-field"])

    def test_an_undeclared_typed_value_gates_and_meets_nothing(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("key section key", "key the act's key")))
        self.assertEqual(self.codes(), ["B-bond-type", "B-bond-unmet"])

    def test_a_line_naming_an_atom_gates(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("closing record", "Guard Offerer's record")))
        self.assertEqual(self.codes(), ["B-bond-names-atom"])

    def test_a_call_the_offer_lacks_meets_nothing(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("calls take,", "calls try_take,")))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_two_offers_are_reported_not_forced(self):
        self.write("second-offerer", atom("Second Offerer", OFFER))
        self.assertEqual(self.codes(), ["B-bond-ambiguous"])

    def test_a_key_need_meets_only_the_same_declared_word(self):
        self.write("key-offerer", atom("Key Offerer", "Term offer key: key invocation id; carried by intent record.\n"))
        self.write("key-needer", atom("Key Needer", "Term need key: key invocation id; pairs closing record.\n"))
        self.write("other-needer", atom("Other Needer", "Term need key: key section key; pairs closing record.\n"))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_an_atom_meets_no_offer_of_its_own(self):
        self.write("guard-offerer", atom("Guard Offerer", OFFER + NEED))
        self.write("guard-needer", atom("Guard Needer", ""))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_the_repository_bonds_gate(self):
        root = Path(HERE).parents[1]
        gating = [f for f in check.bond_findings(root) if f.code not in check.ADVISORY]
        self.assertEqual(gating, [])


if __name__ == "__main__":
    unittest.main()

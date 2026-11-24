#!/usr/bin/env python3
"""The bonds (unit `bonds: the fifty`): check.py's bond_findings reads bonds.md, declarations.md and
the atoms' `Term need <kind>:` and `Term offer <kind>:` lines, and matches each need to its offers by type.
Unit `bonds: five rulings`: an offer's arms per call, a key need's pairs within carried by, and an app's unmet need gating."""
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

JOURNAL = """
Term journal need fields: records, the records; calls, the calls; arms, the answers; keep, how long; tamper, how a change shows; stream, the stream.

Term journal offer fields: calls, the calls; arms, the answers; keep, how long; tamper, how a change shows; order, the order.
"""

OFFER = "Term offer guard: key opaque; holder opaque; span duration; calls take, remaining, release; arms take: expires_at / remaining: none / release: released.\n"
NEED = "Term need guard: key section key; holder section holder; span duration; calls take, release; arms expires_at, released; writes closing record.\n"


def atom(title: str, body: str) -> str:
    return f"---\ntitle: {title}\nid: 1\n---\n\n# {title}\n\n{body}"


class BondTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.root = Path(self._tmp.name)
        (self.root / "library" / "atoms").mkdir(parents=True)
        (self.root / "library" / "bonds.md").write_text(BONDS)
        (self.root / "library" / "declarations.md").write_text(DECLARATIONS)
        self.write("guard-offerer", atom("Guard Offerer", OFFER))
        self.write("guard-needer", atom("Guard Needer", NEED))

    def write(self, name: str, text: str) -> None:
        (self.root / "library" / "atoms" / f"{name}.md").write_text(text)

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
        self.write("key-offerer", atom("Key Offerer", "Term offer key: key invocation id; carried by intent record, closing record.\n"))
        self.write("key-needer", atom("Key Needer", "Term need key: key invocation id; pairs closing record.\n"))
        self.write("other-needer", atom("Other Needer", "Term need key: key section key; pairs closing record.\n"))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_an_atom_meets_no_offer_of_its_own(self):
        self.write("guard-offerer", atom("Guard Offerer", OFFER + NEED))
        self.write("guard-needer", atom("Guard Needer", ""))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_a_contract_need_names_a_contract_the_contracts_page_states(self):
        (self.root / "library" / "contracts.md").write_text("# Contracts\n\nTerm commit contract: the call that makes an act.\n")
        self.write("guard-needer", atom("Guard Needer", NEED + "\nTerm contract need commit: asks the act; answers committed; bound commit round trip.\n"))
        self.assertEqual(self.codes(), [])
        self.write("guard-needer", atom("Guard Needer", NEED + "\nTerm contract need ledger: asks a row; answers ok; bound read bound.\n"))
        self.assertEqual(self.codes(), ["B-contract-unknown"])

    def test_an_offer_whose_arms_are_not_named_per_call_gates_and_meets_nothing(self):
        self.write("guard-offerer", atom("Guard Offerer", OFFER.replace("take: expires_at / remaining: none / release: released", "expires_at, none, released")))
        self.assertEqual(self.codes(), ["B-bond-arms", "B-bond-unmet"])

    def test_an_offer_naming_arms_for_a_call_it_does_not_offer_gates(self):
        self.write("guard-offerer", atom("Guard Offerer", OFFER.replace("release: released", "release: released / try_take: held")))
        self.assertEqual(self.codes(), ["B-bond-arms"])

    def test_an_arm_only_a_call_the_need_does_not_list_gives_meets_nothing(self):
        self.write("guard-needer", atom("Guard Needer", NEED.replace("arms expires_at, released", "arms expires_at, none, released")))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_a_key_need_meets_only_where_its_pairs_lie_within_carried_by(self):
        self.write("key-offerer", atom("Key Offerer", "Term offer key: key invocation id; carried by intent record, closing record.\n"))
        self.write("key-needer", atom("Key Needer", "Term need key: key invocation id; pairs closing record.\n"))
        self.assertEqual(self.codes(), [])
        self.write("key-needer", atom("Key Needer", "Term need key: key invocation id; pairs closing record, marker record.\n"))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_an_unmet_need_of_an_apps_atoms_fails_the_app(self):
        (self.root / "library" / "apps" / "pair").mkdir(parents=True)
        app = self.root / "library" / "apps" / "pair" / "index.md"
        app.write_text("# Pair\n\n- [Guard Offerer](../../atoms/guard-offerer.md)\n- [Guard Needer](../../atoms/guard-needer.md)\n")
        self.assertEqual(self.codes(), [])
        app.write_text("# Pair\n\n- [Guard Needer](../../atoms/guard-needer.md)\n")
        self.assertEqual(self.codes(), ["B-app-unmet"])
        self.assertNotIn("B-app-unmet", check.ADVISORY)
        self.write("guard-offerer", atom("Guard Offerer", ""))
        self.assertEqual(self.codes(), ["B-app-unmet", "B-bond-unmet"])

    def test_a_cycle_of_needs_met_by_offers_fails_the_app(self):
        (self.root / "library" / "apps" / "pair").mkdir(parents=True)
        app = self.root / "library" / "apps" / "pair" / "index.md"
        app.write_text("# Pair\n\n- [Guard Offerer](../../atoms/guard-offerer.md)\n- [Guard Needer](../../atoms/guard-needer.md)\n")
        self.assertEqual(self.codes(), [])
        # the offerer comes to need what the needer offers: guard-needer -> guard-offerer -> guard-needer
        self.write("guard-offerer", atom("Guard Offerer", OFFER + "\nTerm need key: key invocation id; pairs closing record.\n"))
        self.write("guard-needer", atom("Guard Needer", NEED + "\nTerm offer key: key invocation id; carried by closing record.\n"))
        self.assertEqual(self.codes(), ["B-app-cycle"])
        self.assertNotIn("B-app-cycle", check.ADVISORY)
        self.assertEqual(check.need_cycle([], {}, set()), [])

    def test_a_journal_need_meets_an_offer_whose_keep_is_the_type(self):
        (self.root / "library" / "bonds.md").write_text(BONDS + JOURNAL)
        self.write("log", atom("Log", "Term offer journal: calls append, read; arms append: place, too-large / read: records, bad-range; keep duration; tamper opaque; order per stream.\n"))
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append, read; arms place, records; keep duration.\n"))
        self.assertEqual(self.codes(), [])
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append, read; arms place, records; keep forever.\n"))
        self.assertEqual(self.codes(), ["B-bond-type", "B-bond-unmet"])

    def test_a_need_whose_keep_exceeds_the_offers_keep_meets_nothing(self):
        (self.root / "library" / "bonds.md").write_text(BONDS + JOURNAL)
        self.write("log", atom("Log", "Term offer journal: calls append, read; arms append: place / read: records; keep 7 y; tamper opaque; order per stream.\n"))
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append; arms place; keep 5 y.\n"))
        self.assertEqual(self.codes(), [])
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append; arms place; keep 9 y.\n"))
        self.assertEqual(self.codes(), ["B-bond-unmet"])

    def test_a_tamper_need_meets_the_same_word_or_the_type_the_offer_names(self):
        (self.root / "library" / "bonds.md").write_text(BONDS + JOURNAL)
        (self.root / "library" / "declarations.md").write_text(DECLARATIONS + "\nTerm sealed: opaque — a seal covers it.\n")
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append; arms place; tamper sealed.\n"))
        self.write("log", atom("Log", "Term offer journal: calls append; arms append: place; keep duration; tamper opaque; order per stream.\n"))
        self.assertEqual(self.codes(), [])
        self.write("log", atom("Log", "Term offer journal: calls append; arms append: place; keep duration; tamper sealed; order per stream.\n"))
        self.assertEqual(self.codes(), [])
        self.write("log", atom("Log", "Term offer journal: calls append; arms append: place; keep duration; tamper opaque; order per stream.\n"))
        self.write("writer", atom("Writer", "Term need journal: records action record; calls append; arms place; tamper unsealed.\n"))
        self.assertEqual(self.codes(), ["B-bond-type", "B-bond-unmet"])

    def test_an_atoms_layer_is_computed_from_its_needs_and_a_layered_cycle_has_none(self):
        (self.root / "library" / "bonds.md").write_text(BONDS + JOURNAL)
        mid = "Term offer guard: key opaque; holder opaque; span duration; calls take, remaining, release; arms take: expires_at / remaining: none / release: released.\n"
        lines = []
        for name, body in (("lease", mid), ("log", "Term offer journal: calls append; arms append: place; keep duration; tamper opaque; order per stream.\n"),
                           ("intent", NEED + "Term need journal: records record; calls append; arms place.\n" + "Term offer key: key invocation id; carried by record.\n"),
                           ("sweep", NEED + "Term need key: key invocation id; pairs record.\n")):
            self.write(name, atom(name.title(), body))
        kinds = check.bond_kinds(self.root)
        words, types = check.declared_words(self.root)
        files = [p for p in sorted((self.root / "library" / "atoms").glob("*.md")) if p.stem in ("lease", "log", "intent", "sweep")]
        lines = [b for p in files for b in check.bond_lines(p, kinds)]
        layers, bad = check.app_layers(lines, words, types)
        self.assertEqual(layers, {"intent": 1, "lease": 0, "log": 0, "sweep": 1})
        self.assertEqual(bad, [])
        # the offering atoms come to need what the needing atoms offer on a layered kind: no layer is computable
        self.write("lease", atom("Lease", mid + "Term need journal: records record; calls append; arms place.\n"))
        self.write("log", atom("Log", "Term offer journal: calls append; arms append: place; keep duration; tamper opaque; order per stream.\n" + NEED))
        lines = [b for p in files for b in check.bond_lines(p, kinds)]
        layers, bad = check.app_layers(lines, words, types)
        self.assertTrue(bad)

    def test_the_repository_bonds_gate(self):
        root = Path(HERE).parents[1]
        gating = [f for f in check.bond_findings(root) if f.code not in check.ADVISORY]
        self.assertEqual(gating, [])


if __name__ == "__main__":
    unittest.main()

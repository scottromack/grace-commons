#!/usr/bin/env python3
"""Tests for scoreboard.py: the page says no more than the checker does.

    python3 tools/grace/test_scoreboard.py

A row of the scoreboard is a claim about the checker, so each claim is run: a
rule that breaks the sentence is written to a throwaway spec, and `check.py`
either reports the code the row names or, for a reach the row says slips
through, reports nothing. A row whose probe fails is a row that says more, or
less, than the checker does.
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import check  # noqa: E402
import scoreboard  # noqa: E402

ROOT = HERE.parents[1]
FENCE = "```"

# label -> (a rule that breaks the sentence, the code that must fire)
CAUGHT = {
    "Surface 19": ("The opening line opens nothing\nProbe 1: The system MUST store the value.", "F-fence-first"),
    "Hard invariant 1": ("Probe 1: The system MUST store the value.\nthis line is no rule at all", "F-unlabelled"),
    "Hard invariant 3": ("Probe 1: The system stores the value.", "R-no-modal"),
    "Hard invariant 4": ("Probe 1: The system MUST store its value.", "P-pronoun"),
    "Hard invariant 6": ("Probe 1: WHEN the status EQUALS open:\n  Probe 1.1: WHEN the status EQUALS closed:\n"
                         "    Probe 1.1.1: The system MUST store the value.", "R-nested-when"),
    "Hard invariant 7": ("Probe 1: IF the a EQUALS b AND the c EQUALS d OR the e EQUALS f THEN the system MUST store the value.",
                         "V-mixed"),
    "Hard invariant 8": ("Probe 1: The system MUST store the value OR send the notice.", "V-or-obligation"),
    "Hard invariant 9": ("Probe 1: The system MAY store the value BEFORE the notice.", "B-before"),
    "Hard invariant 10": ("Probe 1: The system MUST NOT store the value AFTER the notice.", "B-after"),
    "Hard invariant 11": ("Probe 1: The system MUST store the value BEFORE the notice.", "B-before"),
    "Hard invariant 32": ("Probe 1: IF the record NOT EXISTS THEN the system MUST store the value.", "D-condition-form"),
    "Hard invariant 34": ("Probe 1: IF the count NOT EXCEEDS the limit THEN the system MUST store the value.",
                          "D-condition-form"),
    "Hard invariant 36": ("Probe 1: The system MUST store the value of a / b.", "D-rule-symbol"),
}
# declarations are outside a fence
CAUGHT_DECL = {
    "Hard invariant 35": ("Term total: `(a + b) * c`.", "A-decl-arith"),
    "Hard invariant 37": ("Term share: (a / b).", "A-decl-arith"),
}
# the reach each "gates in part" row says slips through: nothing may fire
SLIPS = {
    "Hard invariant 4": "Probe 1: The system MUST store this value.",
    "Hard invariant 9": "Probe 1: The ledger IS AUTHORITATIVE FOR the value BEFORE the notice.",
    "Hard invariant 10": "Probe 1: IF the notice AFTER the value THEN the system MUST store the value.",
    "Hard invariant 11": "Probe 1: The system MUST store the value, per step 0.1a, BEFORE the notice.",
    "Hard invariant 36": "Probe 1: The system MUST store the value of a ÷ b.",
}
# gating in part, but a parenthesized division still gates
SLIPS_NOT = {"Hard invariant 36": ("Probe 1: The system MUST store the value (a / b).", "A-arith")}
# noise the probes carry on purpose: a throwaway spec has no heading the label can name
NOISE = {"R-label-heading", "D-decl-form", "W-term-unused", "R-child-label", "R-when-empty", "F-unlabelled"}


def codes(body: str, in_fence: bool = True, keep: set[str] = frozenset()) -> set[str]:
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / "probe.md"
        fenced = f"{FENCE}\n{body}\n{FENCE}" if in_fence else body
        p.write_text(f"Term qualifiers: migrated\n\n## Probe\n\n{fenced}\n", encoding="utf-8")
        return {f.code for f in check.scan(p)} - (NOISE - keep)


class ScoreboardTest(unittest.TestCase):
    def setUp(self):
        self.advisory = scoreboard._advisory()

    def test_every_sentence_has_a_row_and_every_row_a_sentence(self):
        self.assertEqual([], scoreboard.verify(ROOT, self.advisory))

    def test_the_page_is_current(self):
        page = (ROOT / scoreboard.PAGE).read_text(encoding="utf-8")
        self.assertEqual(page, scoreboard.generate(ROOT))

    def test_each_caught_row_fires_its_code(self):
        for label, (body, code) in CAUGHT.items():
            with self.subTest(label):
                self.assertIn(code, ROWS_CODES(label))
                self.assertIn(code, codes(body, keep={"F-unlabelled"} if code == "F-unlabelled" else set()))
        for label, (body, code) in CAUGHT_DECL.items():
            with self.subTest(label):
                self.assertIn(code, ROWS_CODES(label))
                self.assertIn(code, codes(body, in_fence=False))

    def test_the_reach_a_row_says_slips_is_read_by_nothing(self):
        for label, body in SLIPS.items():
            with self.subTest(label):
                self.assertEqual("gates in part", scoreboard.state(label, self.advisory))
                self.assertEqual(set(), codes(body) - {"W-demonstrative"})
        for label, (body, code) in SLIPS_NOT.items():
            with self.subTest(label):
                self.assertIn(code, codes(body))

    def test_a_row_that_only_counts_has_no_gating_code(self):
        for label in ("Hard invariant 2", "Hard invariant 5", "Hard invariant 13", "Hard invariant 14", "Value set 2"):
            with self.subTest(label):
                self.assertEqual("only counted", scoreboard.state(label, self.advisory))

    def test_a_row_with_no_slip_note_gates_in_full(self):
        for label, (_codes, slips) in scoreboard.ROWS.items():
            with self.subTest(label):
                if scoreboard.state(label, self.advisory) == "gates":
                    self.assertIsNone(slips)
                if slips:
                    self.assertEqual("gates in part", scoreboard.state(label, self.advisory))

    def test_the_first_sentence_gives_the_totals(self):
        page = (ROOT / scoreboard.PAGE).read_text(encoding="utf-8")
        states = [scoreboard.state(lab, self.advisory) for lab, _ in
                  scoreboard.sentences((ROOT / "GRACE-lang.md").read_text(encoding="utf-8"))]
        want = (f"has {len(states)} rules that say the parser MUST reject something: the checker gates "
                f"{states.count('gates')} of them, gates {states.count('gates in part')} in part, and only counts "
                f"{states.count('only counted')}.")
        self.assertIn(want, page)

    def test_a_missing_row_stops_the_generator(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "tools/grace").mkdir(parents=True)
            (root / "tools/linter").mkdir(parents=True)
            for rel in ("tools/grace/check.py", "tools/grace/normalize.py", "tools/linter/lint.py"):
                (root / rel).write_text((ROOT / rel).read_text(encoding="utf-8"), encoding="utf-8")
            grammar = (ROOT / "GRACE-lang.md").read_text(encoding="utf-8")
            (root / "GRACE-lang.md").write_text(
                grammar + "\nHard invariant 99: The parser MUST reject a thing no row holds.\n", encoding="utf-8")
            self.assertEqual(["Hard invariant 99: GRACE-lang.md says the parser MUST reject, and ROWS has no row for it"],
                             scoreboard.verify(root, self.advisory))


def ROWS_CODES(label: str) -> tuple[str, ...]:
    return scoreboard.ROWS[label][0]


if __name__ == "__main__":
    unittest.main(verbosity=1)

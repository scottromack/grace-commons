#!/usr/bin/env python3
"""Tests for the state totals in _data/stats.json (generate_graph.states_ledger_stats),
for the Status token a card counts as done (generate_graph.is_done), and for a
card's invariant count where a tombstone stands (generate_graph.invariant_count):
python3 tools/taxonomy/test_stats.py"""
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from generate_graph import invariant_count, is_done, models_of, states_ledger_stats  # noqa: E402

HEAD = "# date\tfile\trole\tengine\tstates\tcapped\tcommands\tholds\tsatisfiable\tcounterexamples\tvacuous\tverdict\n"


def tla(d, f, role, states, verdict="HOLDS", capped=0):
    return f"{d}\t{f}\t{role}\ttla\t{states}\t{capped}\t-\t-\t-\t-\t-\t{verdict}\n"


def als(d, f, role, commands, verdict="HOLDS"):
    return f"{d}\t{f}\t{role}\tals\t-\t-\t{commands}\t1\t1\t0\t0\t{verdict}\n"


def totals(text=None):
    with tempfile.TemporaryDirectory() as d:
        if text is not None:
            h = pathlib.Path(d) / "tools" / "harness"
            h.mkdir(parents=True)
            (h / "states.tsv").write_text(text, encoding="utf-8")
        return states_ledger_stats(d)


class StatesLedger(unittest.TestCase):
    def test_no_ledger_is_zero(self):
        self.assertEqual(totals(), {"states_models": 0, "states_twins": 0, "alloy_commands": 0,
                                    "models": 0, "twins": 0, "states_millions": "0.0"})

    def test_models_and_twins_apart_alloy_together(self):
        t = totals(HEAD + tla("2026-11-09", "a.tla", "model", 100) + tla("2026-11-09", "a-buggy.tla", "twin", 7)
                   + als("2026-11-09", "b.als", "model", 4) + als("2026-11-09", "b-buggy.als", "twin", 5))
        self.assertEqual(t, {"states_models": 100, "states_twins": 7, "alloy_commands": 9,
                             "models": 2, "twins": 0, "states_millions": "0.0"})   # a twin that HOLDS was not caught

    def test_a_file_counts_its_latest_line_only(self):
        t = totals(HEAD + tla("2026-11-08", "a.tla", "model", 100) + tla("2026-11-09", "a.tla", "model", 160))
        self.assertEqual(t["states_models"], 160)

    def test_a_latest_error_counts_nothing(self):
        t = totals(HEAD + tla("2026-11-08", "a.tla", "model", 100)
                   + tla("2026-11-09", "a.tla", "model", 200001, verdict="ERROR", capped=1))
        self.assertEqual(t["states_models"], 0)

    def test_a_path_that_takes_the_models_folder_keeps_the_totals(self):
        # The move to atoms/models/ rewrites each path in place: one line a file, the same totals.
        lines = [tla("2026-11-09", "atoms/a.tla", "model", 100), tla("2026-11-09", "atoms/a-buggy.tla", "twin", 7),
                 als("2026-11-09", "compositions/b.als", "model", 4)]
        moved = [l.replace("\tatoms/", "\tatoms/models/").replace("\tcompositions/", "\tcompositions/models/")
                 for l in lines]
        self.assertEqual(totals(HEAD + "".join(lines)), totals(HEAD + "".join(moved)))

    def test_models_that_hold_and_twins_caught(self):
        t = totals(HEAD + tla("2026-11-09", "a.tla", "model", 100) + tla("2026-11-09", "b.tla", "model", 5, verdict="ERROR")
                   + tla("2026-11-09", "a-buggy.tla", "twin", 7, verdict="CAUGHT")
                   + tla("2026-11-09", "b-buggy.tla", "twin", 7, verdict="HOLDS"))
        self.assertEqual((t["models"], t["twins"]), (1, 1))

    def test_a_file_counts_once_at_its_latest_verdict(self):
        t = totals(HEAD + tla("2026-11-08", "a.tla", "model", 100, verdict="COUNTEREXAMPLE")
                   + tla("2026-11-09", "a.tla", "model", 100))
        self.assertEqual(t["models"], 1)

    def test_states_millions_is_text_to_one_decimal_rounded_half_up(self):
        for states, want in ((28_868_653, "28.9"), (50_000, "0.1"), (49_999, "0.0"), (1_050_000, "1.1"),
                             (25_622_047 + 3_246_606, "28.9"), (100_000_000, "100.0")):
            t = totals(HEAD + tla("2026-11-09", "a.tla", "model", states))
            self.assertEqual(t["states_millions"], want, states)
            self.assertIsInstance(t["states_millions"], str)


class ModelsOf(unittest.TestCase):
    """A card's models are read in its folder's models folder (Scott, 2026-11-13,
    ruling 6), and a model file beside the spec is not the card's."""

    def card(self, files):
        with tempfile.TemporaryDirectory() as d:
            for rel in ["atoms/x.md", *files]:
                p = pathlib.Path(d) / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text("", encoding="utf-8")
            return models_of(pathlib.Path(d) / "atoms" / "x.md")

    def test_the_models_folder(self):
        self.assertEqual(self.card(["atoms/models/x.tla", "atoms/models/x.als", "atoms/models/x-buggy.tla",
                                    "atoms/models/x-buggy-y.als", "atoms/models/xy-buggy.tla"]),
                         {"tla": True, "als": True, "twins": 2})

    def test_beside_the_spec_is_not_read(self):
        self.assertEqual(self.card(["atoms/x.tla", "atoms/x-buggy.tla"]), {"tla": False, "als": False, "twins": 0})

    def test_none(self):
        self.assertEqual(self.card(["compositions/models/x.tla"]), {"tla": False, "als": False, "twins": 0})


class DoneToken(unittest.TestCase):
    def test_done_with_its_date_counts(self):
        self.assertTrue(is_done("done — 2026-11-13"))

    def test_todo_doing_and_none_do_not(self):
        for token in ("todo", "doing", None, ""):
            self.assertFalse(is_done(token), token)

    def test_the_old_word_does_not(self):
        self.assertFalse(is_done("grounded on Final Critique 4 — 2026-06-04 at 1719092"))


class InvariantCount(unittest.TestCase):
    """A tombstoned invariant is not counted, and its heading is: the count is
    the same whether the tombstones stand on the page or have moved to the
    history file (GRACE-lang Hard invariant 25, v0.71) and taken their fence."""

    HEAD = "- **Invariant 1 — A.**\n  ```\n  Invariant 1.1: x.\n  ```\n- **Invariant 2 — B.**\n"
    ON_PAGE = HEAD + "  ```\n  Deleted: Invariant 2.1. Invariant 1.1 owns it.\n  ```\n```\nDeleted: Invariant 3. Gone.\n```\n"
    MOVED = HEAD

    def test_the_count_is_the_same_in_either_place(self):
        self.assertEqual(invariant_count(self.ON_PAGE), 2)
        self.assertEqual(invariant_count(self.MOVED), 2)


if __name__ == "__main__":
    unittest.main()

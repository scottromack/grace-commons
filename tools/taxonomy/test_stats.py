#!/usr/bin/env python3
"""Tests for the state totals in _data/stats.json (generate_graph.states_ledger_stats):
python3 tools/taxonomy/test_stats.py"""
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from generate_graph import states_ledger_stats  # noqa: E402

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
        self.assertEqual(totals(), {"states_models": 0, "states_twins": 0, "alloy_commands": 0})

    def test_models_and_twins_apart_alloy_together(self):
        t = totals(HEAD + tla("2026-11-09", "a.tla", "model", 100) + tla("2026-11-09", "a-buggy.tla", "twin", 7)
                   + als("2026-11-09", "b.als", "model", 4) + als("2026-11-09", "b-buggy.als", "twin", 5))
        self.assertEqual(t, {"states_models": 100, "states_twins": 7, "alloy_commands": 9})

    def test_a_file_counts_its_latest_line_only(self):
        t = totals(HEAD + tla("2026-11-08", "a.tla", "model", 100) + tla("2026-11-09", "a.tla", "model", 160))
        self.assertEqual(t["states_models"], 160)

    def test_a_latest_error_counts_nothing(self):
        t = totals(HEAD + tla("2026-11-08", "a.tla", "model", 100)
                   + tla("2026-11-09", "a.tla", "model", 200001, verdict="ERROR", capped=1))
        self.assertEqual(t["states_models"], 0)


if __name__ == "__main__":
    unittest.main()

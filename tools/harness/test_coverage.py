#!/usr/bin/env python3
"""Tests for the coverage figure (tools/harness/coverage.py): python3 tools/harness/test_coverage.py"""
import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from coverage import count, summary, cells  # noqa: E402

MATRIX = """# Coverage matrix — `x`

| Spec invariant (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1 — one | yes | `checked` covered | `Inv1`. Broken by `x-buggy.tla`. |
| Invariant 2 — two | yes | **`checked`** covered | `Inv2`, no twin named. |
| Invariant 3 — three | no | `owed` out-of-scope | not modelled |
| Invariant 4 — four | no | `elsewhere` out-of-scope | Y's model, `Inv_Y` |
| Invariant 5 — five | no | `unstatable` out-of-scope | wiring |
| Invariant 6 — six | no | `retired` deleted | merged into 5 |
| Invariant 7 — seven | no | out-of-scope | no word |

| Twin | Check it breaks alone |
|---|---|
| `x-buggy.tla` | `Inv1` |
"""


def run(text):
    with tempfile.TemporaryDirectory() as d:
        (pathlib.Path(d) / "x.md").write_text(text, encoding="utf-8")
        (pathlib.Path(d) / "README.md").write_text("| a | Verdict |\n|---|---|\n| b | none |\n", encoding="utf-8")
        return count(d)


class Coverage(unittest.TestCase):
    def test_each_word_counted_and_retired_left_out(self):
        pages, _ = run(MATRIX)
        self.assertEqual(pages["x"], {"checked": 2, "elsewhere": 1, "owed": 1, "unstatable": 1, "retired": 1})
        self.assertEqual(summary(pages), "Of 5 rules on 1 matrices: 2 (40%) checked by a model that holds, "
                         "1 (20%) checked on another page, 1 (20%) owed, 1 (20%) cannot be stated")

    def test_a_row_with_no_word_and_a_checked_row_with_no_twin_are_problems(self):
        _, problems = run(MATRIX)
        self.assertEqual(problems, [("x", 6, "checked, and names no twin that breaks it"), ("x", 11, "no verdict word")])

    def test_tables_without_a_verdict_column_and_the_readme_are_not_rules(self):
        pages, problems = run(MATRIX.split("| Invariant 7")[0] + "\n| Twin | Check |\n|---|---|\n| `y-buggy.tla` | `Inv9` |\n")
        self.assertEqual(sum(pages["x"].values()), 6)
        self.assertEqual(len(problems), 1)

    def test_a_pipe_inside_a_code_span_does_not_split_a_cell(self):
        self.assertEqual(cells("| a | `x | y` | b |"), ["a", "`x | y`", "b"])


if __name__ == "__main__":
    unittest.main()

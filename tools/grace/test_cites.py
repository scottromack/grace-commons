#!/usr/bin/env python3
"""Tests for cites.py's reach: the term leg of `across()` and `--reach`.

    python3 tools/grace/test_cites.py

Each case builds a small corpus in a temporary git repository (one atom, one
composition that rests on it, one that does not), commits it, changes the atom,
and asks cites.py what the change reaches of each composition. A change reopens
what it reaches, never the page (Scott, 2026-11-03 16:40Z): a composition the
change reaches by no rule is reached by nothing, and `--reach` says `nothing`.
"""
from __future__ import annotations

import contextlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cites  # noqa: E402

ATOM = """# Alpha Atom

## Status

Term qualifiers: migrated.

Term seam: the boundary the host answers at.

Term edge: the far side of the seam.

```
Invariant 1: The atom MUST keep the record.
Operation 1: The atom MUST answer at the seam.
Operation 2: The atom MUST read the edge.
Operation 3: The atom MUST refuse a blank value.
```
"""

# rests on the atom by its term, by the possessive form
POSSESSIVE = """# Beta Comp

Term qualifiers: migrated.

```
Composes 1: The composition MUST call Alpha Atom's seam once.
Rule 1: The composition MUST keep its own record.
```
"""

# rests on the atom by a rule's label, by the cross-spec form
LABELLED = """# Delta Comp

Term qualifiers: migrated.

```
Composes 1: The composition MUST obey Alpha Atom Invariant 1.
Rule 1: The composition MUST keep its own record.
```
"""

# rests on the atom by a [Marker] link into it
LINKED = """# Epsilon Comp

Term qualifiers: migrated.

```
Composes 1: The composition MUST read the [seam](../atoms/alpha-atom.md#seam) once.
Rule 1: The composition MUST keep its own record.
```
"""

# names the atom and cites nothing of what changes
UNREACHED = """# Gamma Comp

Term qualifiers: migrated.

```
Composes 1: The composition MUST compose Alpha Atom and call it once.
Composes 2: The composition MUST cite Alpha Atom Operation 3 for the blank value.
Rule 1: The composition MUST keep its own record.
```
"""


def git(root: Path, *args: str) -> str:
    done = subprocess.run(
        ["git", "-c", "user.email=t@example.org", "-c", "user.name=t", "-c", "commit.gpgsign=false",
         "--no-optional-locks", "-C", str(root), *args],
        capture_output=True, text=True, check=True)
    return done.stdout.strip()


class Corpus:
    """A temporary repository holding the five specifications, committed once."""

    def __init__(self) -> None:
        self._dir = tempfile.TemporaryDirectory()
        self.root = Path(self._dir.name)
        git(self.root, "init", "-q")
        self.write("atoms/alpha-atom.md", ATOM)
        self.write("compositions/beta-comp.md", POSSESSIVE)
        self.write("compositions/delta-comp.md", LABELLED)
        self.write("compositions/epsilon-comp.md", LINKED)
        self.write("compositions/gamma-comp.md", UNREACHED)
        git(self.root, "add", ".")
        git(self.root, "commit", "-q", "-m", "base")
        self.base = git(self.root, "rev-parse", "HEAD")

    def write(self, rel: str, text: str) -> None:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def edit(self, rel: str, old: str, new: str) -> None:
        path = self.root / rel
        text = path.read_text(encoding="utf-8")
        assert old in text, old
        path.write_text(text.replace(old, new, 1), encoding="utf-8")

    def reach(self, rel: str) -> tuple[int, list[str]]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = cites.run(self.root, ["cites.py", "--reach", rel, "--changed", self.base])
        return code, out.getvalue().strip().split("\n")

    def close(self) -> None:
        self._dir.cleanup()


CONTRACT = """# Execution Contract

## Logic Confinement Principle

**Logic confinement 3: Explicit inputs only.** Time is injected, as Logic confinement 1 says.

**Logic confinement 1: Core is pure.** No IO.

### The Database contract

- **Conformance 1:** Every transition executes the four steps.
"""

# cites the contract by the cross-spec form
CONTRACT_CITER = """# Zeta Comp

Term qualifiers: migrated.

```
Rule 1: The composition MUST keep its own record, as Execution Contract Logic confinement 3 holds.
Rule 2: The composition MUST keep another record.
```
"""


class ContractTest(unittest.TestCase):
    """The Execution Contract's labels resolve as a pattern's do, and a citation
    of a label neither it nor the grammar carries is found."""

    def setUp(self) -> None:
        self.corpus = Corpus()
        self.addCleanup(self.corpus.close)
        self.corpus.write("execution-contract.md", CONTRACT)
        self.corpus.write("compositions/zeta-comp.md", CONTRACT_CITER)
        git(self.corpus.root, "add", ".")
        git(self.corpus.root, "commit", "-q", "-m", "contract")
        self.corpus.base = git(self.corpus.root, "rev-parse", "HEAD")

    def seed(self, label: str) -> tuple[int, str]:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = cites.run(self.corpus.root, ["cites.py", label])
        return code, out.getvalue()

    def test_the_contract_parses_its_bold_labels_and_list_items(self) -> None:
        spec = cites.parse(self.corpus.root / "execution-contract.md")
        self.assertEqual(set(spec.rules), {"Logic confinement 1", "Logic confinement 3", "Conformance 1"})
        self.assertTrue(spec.text_of["Logic confinement 3"].startswith("Explicit inputs only."))

    def test_a_contract_label_resolves_and_names_what_cites_it(self) -> None:
        code, out = self.seed("Logic confinement 3")
        self.assertEqual(code, 0)
        self.assertIn("zeta-comp.md", out)
        self.assertIn("cross-spec: Execution Contract Logic confinement 3", out)

    def test_a_contract_label_the_contract_lacks_names_no_rule(self) -> None:
        code, out = self.seed("Logic confinement 99")
        self.assertEqual(code, 2)
        self.assertIn("no rule or term named", out)

    def test_a_change_to_a_contract_rule_reaches_the_rule_that_cites_it(self) -> None:
        self.corpus.edit("execution-contract.md", "Explicit inputs only.", "Inputs are explicit.")
        code, lines = self.corpus.reach("compositions/zeta-comp.md")
        self.assertEqual(code, 0)
        self.assertEqual(lines, ["Rule 1"])

    def test_a_citation_of_a_missing_label_is_found(self) -> None:
        labels = cites.contract_labels(self.corpus.root)
        text = ("Execution Contract Logic confinement 3 and Execution Contract Logic confinement 99, "
                "Execution Contract Logic confinement 1 through 7, `Execution Contract Fence 5`, "
                "Execution Contract Conformance 1")
        self.assertEqual(cites.contract_citations(text, labels),
                         [("Execution Contract Logic confinement 99", "Logic confinement 99"),
                          ("Execution Contract Logic confinement 7", "Logic confinement 7")])

    def test_a_document_the_root_lacks_resolves_nothing(self) -> None:
        self.assertEqual(cites.contract_citations("GRACE-lang Hard invariant 28",
                                                  cites.contract_labels(self.corpus.root)), [])


class ReachTest(unittest.TestCase):
    def setUp(self) -> None:
        self.corpus = Corpus()
        self.addCleanup(self.corpus.close)

    def test_a_term_change_reaches_the_possessive_citation(self) -> None:
        self.corpus.edit("atoms/alpha-atom.md", "the boundary the host answers at", "the boundary the host injects at")
        code, labels = self.corpus.reach("compositions/beta-comp.md")
        self.assertEqual((code, labels), (0, ["Composes 1"]))

    def test_a_term_change_reaches_the_marker_link(self) -> None:
        self.corpus.edit("atoms/alpha-atom.md", "the boundary the host answers at", "the boundary the host injects at")
        code, labels = self.corpus.reach("compositions/epsilon-comp.md")
        self.assertEqual((code, labels), (0, ["Composes 1"]))

    def test_a_term_change_reaches_a_term_defined_over_it(self) -> None:
        # edge is defined over seam: a change to seam is a change to edge
        self.corpus.edit("atoms/alpha-atom.md", "the boundary the host answers at", "the boundary the host injects at")
        code, labels = self.corpus.reach("atoms/alpha-atom.md")
        self.assertEqual(code, 0)
        self.assertEqual(labels, ["Term seam", "Term edge", "Operation 1", "Operation 2"])

    def test_a_term_change_reaches_the_chain_as_another_spec_cites_it(self) -> None:
        self.corpus.edit("compositions/beta-comp.md", "Alpha Atom's seam", "Alpha Atom's edge")
        git(self.corpus.root, "commit", "-qam", "beta cites the edge")
        self.corpus.base = git(self.corpus.root, "rev-parse", "HEAD")
        self.corpus.edit("atoms/alpha-atom.md", "the boundary the host answers at", "the boundary the host injects at")
        code, labels = self.corpus.reach("compositions/beta-comp.md")
        self.assertEqual((code, labels), (0, ["Composes 1"]))

    def test_a_rule_change_reaches_the_label_citation(self) -> None:
        self.corpus.edit("atoms/alpha-atom.md", "MUST keep the record", "MUST keep the record whole")
        code, labels = self.corpus.reach("compositions/delta-comp.md")
        self.assertEqual((code, labels), (0, ["Composes 1"]))

    def test_the_spec_s_own_change_is_in_its_reach(self) -> None:
        self.corpus.edit("atoms/alpha-atom.md", "MUST keep the record", "MUST keep the record whole")
        code, labels = self.corpus.reach("atoms/alpha-atom.md")
        self.assertEqual((code, labels), (0, ["Invariant 1"]))

    def test_a_composition_the_change_reaches_by_no_rule_is_unreached(self) -> None:
        # Gamma names Alpha Atom and cites Operation 3; the change is to Invariant 1, the seam and the edge
        self.corpus.edit("atoms/alpha-atom.md", "MUST keep the record", "MUST keep the record whole")
        self.corpus.edit("atoms/alpha-atom.md", "the boundary the host answers at", "the boundary the host injects at")
        code, labels = self.corpus.reach("compositions/gamma-comp.md")
        self.assertEqual((code, labels), (1, ["nothing"]))

    def test_a_status_change_reaches_nothing(self) -> None:
        self.corpus.edit("atoms/alpha-atom.md", "## Status\n", "## Status\n\nstatus: grounded on Final Critique 3\n")
        for rel in ("compositions/beta-comp.md", "compositions/delta-comp.md", "compositions/epsilon-comp.md",
                    "compositions/gamma-comp.md", "atoms/alpha-atom.md"):
            self.assertEqual(self.corpus.reach(rel), (1, ["nothing"]), rel)

    def test_a_spec_the_tools_do_not_read_is_no_reach(self) -> None:
        self.corpus.write("compositions/zeta-comp.md", "# Zeta Comp\n\nno marker.\n")
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = cites.run(self.corpus.root, ["cites.py", "--reach", "compositions/zeta-comp.md", "--changed", self.corpus.base])
        self.assertEqual(code, 2)


class AcrossTest(unittest.TestCase):
    def test_across_reads_a_changed_term_as_the_possessive_and_the_link(self) -> None:
        corpus = Corpus()
        self.addCleanup(corpus.close)
        specs = cites.specs_with_rules(corpus.root, None)
        atom = next(s for s in specs if s.path.name == "alpha-atom.md")
        found = cites.across(specs, {atom.path: {"`seam`"}})
        self.assertEqual(sorted(found), ["Alpha Atom's seam"])
        self.assertEqual(sorted({site.split(": ")[0] for site in found["Alpha Atom's seam"]}),
                         ["beta-comp.md:6", "epsilon-comp.md:6"])

    def test_a_catalogue_term_is_no_citation(self) -> None:
        corpus = Corpus()
        self.addCleanup(corpus.close)
        specs = cites.specs_with_rules(corpus.root, None)
        atom = next(s for s in specs if s.path.name == "alpha-atom.md")
        self.assertEqual(cites.across(specs, {atom.path: {"`records`"}}), {})


class PluralTermTest(unittest.TestCase):
    """A term read in the plural is a use of the term (Privileged Access Provisioning
    Final Critique 10: Term terminal event and Action wiring 50 read the terminal chain
    actions, so a change to Term terminal chain action reached neither)."""

    def test_the_plural_of_a_term_is_a_use_of_it(self) -> None:
        use = cites._term_use("terminal chain action")
        self.assertTrue(use.search("reads the terminal chain actions of the chain"))
        self.assertTrue(use.search("the terminal chain action"))

    def test_a_term_ending_in_y_has_an_ies_plural(self) -> None:
        use = cites._term_use("boundary")
        self.assertTrue(use.search("two boundaries"))
        self.assertTrue(use.search("a boundary"))

    def test_a_longer_word_or_a_compound_is_no_use(self) -> None:
        use = cites._term_use("seam")
        self.assertFalse(use.search("seamless"))
        self.assertFalse(use.search("the seam-like edge"))
        self.assertFalse(cites._term_use("record").search("a recorded value"))

    def test_a_rule_that_reads_the_plural_rests_on_the_term(self) -> None:
        spec = cites.Spec(Path("x.md"), terms={"terminal chain action": (1, "the act"), "other": (2, "x")})
        _, terms = cites.uses("EVERY terminal chain actions list MUST name the chain.", spec, None, "")
        self.assertEqual(terms, {"terminal chain action"})
        _, terms = cites.uses("the terminal chain action alone", spec, None, "terminal chain action")
        self.assertEqual(terms, set())


if __name__ == "__main__":
    unittest.main(verbosity=1)

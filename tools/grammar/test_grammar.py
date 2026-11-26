#!/usr/bin/env python3
"""Tests for tools/grammar/grammar.py: the tokenizer and lexicon always; the parse when `gf` is found."""
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import grammar  # noqa: E402

ROOT = HERE.parents[1]
MONEY = ROOT / "library" / "atoms" / "money.md"


def gf_found() -> bool:
    gf, _ = grammar.gf_bin()
    return bool(shutil.which(gf)) or Path(gf).exists()


class Tokens(unittest.TestCase):
    def test_possessive_and_article(self):
        self.assertEqual(grammar.tokenize("The atom MUST identify a money by the money's currency."),
                         ["the", "atom", "MUST", "identify", "a", "money", "by", "the", "money", "'s", "currency"])

    def test_action_and_number(self):
        self.assertEqual(grammar.tokenize("[Add] MUST answer PER Execution Contract Logic confinement 9."),
                         ["[Add]", "MUST", "answer", "PER", "Execution", "Contract", "Logic", "confinement", "9"])


class Lexicon(unittest.TestCase):
    def test_words_come_from_the_page_not_its_rules(self):
        words, verbs = grammar.lexicon(MONEY, ROOT)
        self.assertIn("identify", verbs)
        self.assertIn("EXCEED", verbs)
        self.assertIn("moneys", words)          # an inflection of a Term word
        self.assertNotIn("payment", words)      # used by a Non-goal, declared by no Term line


@unittest.skipUnless(gf_found(), "gf not found")
class Parse(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.out = Path(tempfile.mkdtemp(prefix="grammar-test-"))
        cls.pgf = grammar.build(MONEY, ROOT, cls.out)

    def trees(self, text):
        return grammar.parse_all(self.pgf, [("x", grammar.tokenize(text))])["x"]["trees"]

    def test_one_tree(self):
        self.assertEqual(len(self.trees("IF the other money's amount EXCEEDS the money's amount THEN [Compare] MUST answer less.")), 1)

    def test_receipt(self):
        base = self.trees("IF the sum's size EXCEEDS the number cap THEN [Add] MUST answer over-cap.")
        spaced = self.trees("IF  the  sum's  size  EXCEEDS  the  number  cap  THEN  [Add]  MUST  answer  over-cap.")
        moved = self.trees("IF the sum's size PRECEDES the number cap THEN [Add] MUST answer over-cap.")
        self.assertEqual(spaced, base)
        self.assertNotEqual(moved, base)

    def test_undeclared_word_fails(self):
        self.assertEqual(self.trees("The atom MUST NOT take a payment."), [])


if __name__ == "__main__":
    unittest.main()

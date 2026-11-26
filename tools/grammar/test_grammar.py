#!/usr/bin/env python3
"""Tests for tools/grammar/grammar.py: the tokenizer and lexicon always; the parse when `gf` is found."""
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
    def test_sources_in_order(self):
        lex, verbs = grammar.lexicon(MONEY, ROOT, {"payment", "moneys", "the"})
        self.assertIn("identify", verbs)
        self.assertIn("EXCEED", verbs)
        self.assertEqual(lex["moneys"], "page")             # an inflection of a Term word
        if grammar.dicteng():
            self.assertEqual(lex["payment"], "DictEng")     # plain English, from the dictionary
        self.assertNotIn("payment", grammar.lexicon(MONEY, ROOT)[0])   # no rule asks for it, none comes

    def test_a_declared_word_keeps_its_source(self):
        lex, _ = grammar.lexicon(MONEY, ROOT, {"currency"})
        self.assertEqual(lex["currency"], "page")

    def test_swaps(self):
        toks = grammar.tokenize("IF the sum's size EXCEEDS the number cap THEN [Add] MUST answer over-cap.")
        names = [w for w, _ in grammar.swaps(toks, {"sum": "page", "size": "page", "rate": "page"})]
        self.assertIn("comparison: EXCEEDS → PRECEDES", names)
        self.assertIn("modal: MUST → MAY", names)
        self.assertEqual(sum(1 for n in names if n.startswith("term:")), 1)


@unittest.skipUnless(gf_found(), "gf not found")
class Parse(unittest.TestCase):
    TEXTS = ["IF the other money's amount EXCEEDS the money's amount THEN [Compare] MUST answer less.",
             "IF the sum's size EXCEEDS the number cap THEN [Add] MUST answer over-cap.",
             "IF the sum's size PRECEDES the number cap THEN [Add] MUST answer over-cap.",
             "The atom MUST NOT take a payment.", "The atom MUST NOT take a zorbleflax."]

    @classmethod
    def setUpClass(cls):
        cls.out = Path(tempfile.mkdtemp(prefix="grammar-test-"))
        need = {t for s in cls.TEXTS for t in grammar.tokenize(s)}
        cls.pgf = grammar.build(MONEY, ROOT, cls.out, need)

    def trees(self, text):
        return grammar.parse_many(self.pgf, [("x", grammar.tokenize(text))])["x"]["trees"]

    def test_one_tree(self):
        self.assertEqual(len(self.trees(self.TEXTS[0])), 1)

    def test_receipt(self):
        base = self.trees(self.TEXTS[1])
        self.assertEqual(self.trees(self.TEXTS[1].replace(" ", "  ")), base)
        self.assertNotEqual(self.trees(self.TEXTS[2]), base)

    def test_loop_two(self):
        tree = self.trees(self.TEXTS[1])[0]
        text = grammar.linearize_many(self.pgf, "GraceLexEng", {"x": tree})["x"]
        self.assertEqual(grammar.parse_many(self.pgf, [("x", text.split())])["x"]["trees"], [tree])

    def test_dictionary_word_parses_and_unknown_fails(self):
        if grammar.dicteng():
            self.assertEqual(len(self.trees(self.TEXTS[3])), 1)
        self.assertEqual(self.trees(self.TEXTS[4]), [])


if __name__ == "__main__":
    unittest.main()

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


    def test_edge_comma_is_a_separator(self):
        # Money Check 8.1: the comma after the act separates nothing (normalize.py drops it)
        self.assertEqual(grammar.tokenize("The check MUST find, for EVERY row, the sum."),
                         ["the", "check", "MUST", "find", "for", "EVERY", "row", ",", "the", "sum"])
        # a list comma between two words of one phrase stays in the tree
        self.assertIn(",", grammar.tokenize("The atom MUST keep the amount, the currency and the scale."))
        # a comma before a reserved token is an edge
        self.assertNotIn(",", grammar.tokenize("IF the cap EQUALS blank, THEN [Add] MUST answer over-cap."))

    def test_reserved_tokens_keep_their_case(self):
        # a reserved tail is never lowered into a phrase word (Casing 2, 3): the corpus run found BEFORE,
        # WITHIN and AFTER read as "before", "within", "after" inside an object
        toks = grammar.tokenize("A workflow MUST NOT record a change BEFORE the landing read.")
        self.assertIn("BEFORE", toks)
        self.assertEqual(toks[0], "a")

    def test_a_negative_sign_is_kept(self):
        # "EQUALS -1" and "EQUALS 1" are two meanings; the sign is a token, never dropped
        self.assertIn("-", grammar.tokenize("IF the day count EQUALS -1 THEN [Add] MUST answer late."))
        self.assertNotIn("-", grammar.lexicon(MONEY, ROOT, {"-"})[0])     # a sign, never a compound word

    def test_tail_order_stays(self):
        a = "subject=x|modal=MAY|act=declare|object=y|only_if=y EXCEEDS 0|timing=PER z"
        b = "subject=x|modal=MAY|act=declare|object=y|timing=PER z|only_if=y EXCEEDS 0"
        self.assertNotEqual(grammar.tree_fields(a), grammar.tree_fields(b))
        self.assertTrue(grammar.tail_order_only(grammar.tree_fields(a), grammar.tree_fields(b)))


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
             "The atom MUST NOT take a payment.", "The atom MUST NOT take a zorbleflax.",
             "The atom ought to take a payment."]

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

    def test_ought_is_no_modal(self):
        # GLM's S2: "ought" is filed to the page, never admitted as a modal
        self.assertEqual(self.trees(self.TEXTS[5]), [])


if __name__ == "__main__":
    unittest.main()

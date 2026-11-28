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
DURABLE = ROOT / "library" / "atoms" / "durable-intent.md"


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

    def test_an_attached_parenthesis_is_no_citation(self):
        # "invalid-request(step-4)" is an arm's payload; normalize.py takes a citation only after a space
        self.assertIn(grammar.ATTACHED, grammar.tokenize("[Refuse] MUST answer invalid-request(step-4)."))
        self.assertIn("(", grammar.tokenize("[Refuse] MUST answer invalid-request (Operation 4)."))

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

    def test_a_record_verb_is_one_word(self):
        # the grammar's own cures: "read back" gave two trees (Durable Intent Primitive policy 35);
        # the act is one word, as normalize.py's is, and "back" stands in the object
        _, verbs = grammar.lexicon(DURABLE, ROOT)
        self.assertIn("read", verbs)
        self.assertFalse([v for v in verbs if " " in v])

    def test_numerals_and_a_code_span(self):
        self.assertTrue({"four", "ten", "third"} <= set(grammar.FUNCTION_WORDS))
        lex, _ = grammar.lexicon(MONEY, ROOT, {"seventh", "`payment`"})
        self.assertEqual(lex["seventh"], "function words")
        self.assertEqual(lex["`payment`"], "code span")

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
             "The atom ought to take a payment.",
             # the grammar's own cures (2026-11-27), one text for each form admitted
             "IF no money EXISTS for the currency THEN [Add] MUST answer over-cap.",
             "WHEN the money's amount EXCEEDS the number cap:",
             "[Add] MUST answer over-cap ONLY AFTER the sum.",
             "[Add] MUST answer over-cap AFTER the sum.",
             "[Add] MUST answer over-cap WITHIN the number cap.",
             "[Add] MUST NOT answer over-cap BEFORE the sum.",
             "[Add] MAY answer over-cap ONLY UNDER the money's amount EXCEEDS the number cap.",
             "The atom IS AUTHORITATIVE FOR the money's amount.",
             "[Add] MUST answer over-cap (Identity 2).",
             "[Add] MUST answer over-cap (the sum).",
             "[Add] MUST answer over-cap(Identity 2).",
             "The atom MUST NOT take a `payment`.",
             "The atom MUST keep four amounts for a third currency.",
             # v0.76, the maintainer's ruling of 2026-11-27 (TEXTS[19] on)
             "IF no money EXISTS among the sums THEN [Add] MUST answer over-cap.",
             "The atom MUST keep a sum that DOES NOT EQUAL blank AND DOES NOT EXCEED the number cap.",
             "[Add] MUST answer over-cap PER Identity 2, Identity 3 AND Identity 4.",
             "[Add] and [Compare] MUST answer over-cap.",
             "The atom MUST keep every sum that could exceed the number cap.",
             "The atom MUST NOT keep a sum for the European Union.",
             "[Add] MUST answer `over-cap(sum)`.",
             "The atom MUST keep a sum that DOES NOT EQUAL blank AND a currency that DOES NOT EQUAL blank."]

    @classmethod
    def setUpClass(cls):
        cls.out = Path(tempfile.mkdtemp(prefix="grammar-test-"))
        toks = [grammar.tokenize(s) for s in cls.TEXTS]
        need = {t for ts in toks for t in ts}
        cls.pgf = grammar.build(MONEY, ROOT, cls.out, need, {t for ts in toks for t in grammar.paren_tokens(ts)})

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

    def norm(self, text):
        tree = self.trees(text)[0]
        return grammar.linearize_many(self.pgf, "GraceLexNorm", {"x": tree})["x"]

    def test_the_absence_form_with_for(self):
        # GRACE-lang section 6, Term absence form: "`no thing EXISTS`, with `for` and the identifier"
        self.assertEqual(len(self.trees(self.TEXTS[6])), 1)
        self.assertIn("CExistsFor", self.trees(self.TEXTS[6])[0])

    def test_a_when_block(self):
        # section 5, Term statement shape: "`WHEN condition:` followed by statements"
        self.assertEqual(len(self.trees(self.TEXTS[7])), 1)
        self.assertTrue(self.norm(self.TEXTS[7]).startswith("when="))

    def test_the_tails(self):
        # section 7, Term tail: ONLY AFTER, ONLY IF, WITHIN, PER, BEFORE; ONLY UNDER provisional (section 18)
        for t in self.TEXTS[8:13]:
            self.assertEqual(len(self.trees(t)), 1, t)
        # AFTER is sugar for ONLY AFTER (Timing 2): two trees of the text, one normalized form
        self.assertNotEqual(self.trees(self.TEXTS[8]), self.trees(self.TEXTS[9]))
        self.assertEqual(self.norm(self.TEXTS[8]), self.norm(self.TEXTS[9]))

    def test_authority(self):
        # section 5 and Authority 1: `subject IS AUTHORITATIVE FOR proposition`
        self.assertEqual(len(self.trees(self.TEXTS[13])), 1)

    def test_a_citation_carries_a_number(self):
        # normalize.py's CITED: a closing parenthetical after a space, carrying a number
        self.assertEqual(len(self.trees(self.TEXTS[14])), 1)
        self.assertEqual(self.trees(self.TEXTS[15]), [])
        self.assertEqual(self.trees(self.TEXTS[16]), [])

    def test_a_code_span_and_numerals(self):
        # Term rule symbol: "a code spelling such as a template sits in a code span"
        self.assertEqual(len(self.trees(self.TEXTS[17])), 1)
        self.assertEqual(len(self.trees(self.TEXTS[18])), 1)

    def test_v076_forms(self):
        # GRACE-lang v0.76: the absence form with another preposition (Term absence form); one subject's
        # predicates joined by AND and a tail's list of citations, each one obligation (Rule shape 13);
        # lower-case and joining subjects (Rule shape 12); could inside a phrase (Earned vocabulary 25);
        # a proper name the dictionary capitalises (Earned vocabulary 26); an arm's payload in a code span
        # (Rule shape 10)
        self.assertIn("CExistsPrep", self.trees(self.TEXTS[19])[0])
        self.assertIn("OCmpAnd", self.trees(self.TEXTS[20])[0])
        self.assertIn("TPerAnd", self.trees(self.TEXTS[21])[0])
        for t in self.TEXTS[19:26]:
            self.assertEqual(len(self.trees(t)), 1, t)
        # loop 2 on each new constructor
        for t in self.TEXTS[19:22]:
            tree = self.trees(t)[0]
            text = grammar.linearize_many(self.pgf, "GraceLexEng", {"x": tree})["x"]
            self.assertEqual(grammar.parse_many(self.pgf, [("x", text.split())])["x"]["trees"], [tree], t)
        # two subjects' comparisons in one object stay two comparisons, never one phrase (Earned vocabulary 24)
        self.assertEqual(self.trees(self.TEXTS[26]), [])

    def test_ought_is_no_modal(self):
        # GLM's S2: "ought" is filed to the page, never admitted as a modal
        self.assertEqual(self.trees(self.TEXTS[5]), [])


if __name__ == "__main__":
    unittest.main()

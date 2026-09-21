#!/usr/bin/env python3
"""GRACE lang surface checker — the mechanical slice of `GRACE-lang.md`.

Reads a spec's normative surface the way §2 and §17 of the grammar say a parser
must — a bare fenced block classified by its first line, `Term`
declarations — and reports what a form-reader can decide without semantics:
fence classification (Surface 18, Surface 19) and signature blocks (Surface 20), unlabelled lines (Hard invariant 1, Sugar 3), label uniqueness
and tombstone reuse (Hard invariant 25, Hard invariant 27), the rule form and the statement shapes (Rule shape 1, Rule shape 2,
Rule shape 6, Hard invariant 2, Hard invariant 3), WHEN blocks (WHEN block 3, Hard invariant 6), mixed AND/OR and OR outside a condition (Hard invariant 7,
Hard invariant 8), BEFORE and AFTER outside their admitted places (Hard invariant 9 through 11), the banned
words (Timing 10, Timing 11), arithmetic in a rule (Hard invariant 24), pronouns (Hard invariant 4), the copula after
a modal (Closed vocabulary 8, Closed vocabulary 14), the record verb after the modal against the declared
vocabulary (Closed vocabulary 8), a declared term nothing uses, and a cross-rule reference to a
label no rule carries (Hard invariant 12).

Standard library only. `python3 tools/grace/check.py [paths...]`; with no path
it reads GRACE-lang.md and every file under atoms/ and compositions/ that
declares itself migrated. Prints one finding per line, `path:line: [CODE] message`.
Non-gating by default: exits 0 whatever it finds; `--gate` exits 1 on any
finding that is not advisory (the W- codes).

What it does not do: resolve every identifier (Closed vocabulary 4), parse value sets against
conditions (Hard invariant 14), or normalize (§16). Those need the parser this is the
forerunner of.
"""
from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

# the vocabulary's categories, derived from the grammar rather than held here:
# check.py carried its own copy through v0.39 and recognized `cited` and
# `composing patterns` two versions before `Term category` did (council read
# 29). Deriving it means the grammar is the single authority (Authority 3) and
# the two cannot drift again.
_CATEGORY_LINE = re.compile(r"^Term category:(.+)$", re.M)

def vocabulary_categories(grammar_path=None):
    """The plural category names a Terms section may carry, from GRACE-lang.md."""
    p = grammar_path or os.path.join(os.path.dirname(__file__), "..", "..", "GRACE-lang.md")
    try:
        m = _CATEGORY_LINE.search(open(p, encoding="utf-8").read())
    except OSError:
        m = None
    if not m:
        raise SystemExit(
            "check.py: GRACE-lang.md carries no `Term category` line; the "
            "category set has no authority to derive from (Closed vocabulary 2)")
    # a value set: members separated by `|`, bare since v0.51 (a backtick quotes
    # literal text and never marks a name)
    names = [x.strip().strip("`") for x in m.group(1).strip().rstrip(".").split("|")]
    # a Terms line names its category in the plural; the value set names it singular
    plural = {"actor": "actors", "record": "records", "record verb": "record verbs",
              "value set": "value sets", "bound": "bounds", "cadence": "cadences",
              "term": "terms", "qualifier": "qualifiers", "cited": "cited",
              "composing pattern": "composing patterns"}
    out = set()
    for n in names:
        if n not in plural:
            raise SystemExit(
                f"check.py: GRACE-lang.md declares the category `{n}`, which this "
                "checker has no plural for; add it to the plural map")
        out.add(plural[n])
    return out

VOCABULARY_CATEGORIES = vocabulary_categories()


# The capital-letter tier is the grammar's (Casing 2, Casing 6): a parser reads an
# upper-case token as reserved before it looks anything up. Nothing checked the
# converse, so WHILE and WHERE (watched, never admitted) and EXIST (an inflection
# of EXISTS) sat in normative rules and both checkers passed them (council read
# 79). The reserved set is derived from the grammar's own declarations, like the
# category set above, so the checker holds no copy of its own.
_RESERVED_SOURCES = ("reserved token", "quantifier", "modal", "condition operator",
                     "tail", "reserved grammar verbs", "surface", "value sets")


def reserved_capitals(grammar_path=None):
    """(reserved, grammar-shaped) upper-case words, both derived from GRACE-lang.md.

    reserved: every upper-case word on the declarations that enumerate the
    reserved tokens (bare since v0.51; a code span still counts). grammar-shaped: the upper-case words of the
    provisional forms and of the watch list (§18) — forms the grammar has named
    and not admitted, so one in a rule is a finding and never a proper noun.
    """
    p = grammar_path or os.path.join(os.path.dirname(__file__), "..", "..", "GRACE-lang.md")
    g = open(p, encoding="utf-8").read()
    reserved: set[str] = set()
    for name in _RESERVED_SOURCES:
        m = re.search(r"^Term " + re.escape(name) + r":(.*)$", g, re.M)
        if not m:
            raise SystemExit(f"check.py: GRACE-lang.md carries no `Term {name}` line; "
                             "the reserved tokens have no authority to derive from (Casing 2)")
        reserved.update(re.findall(r"\b[A-Z]{2,}\b", m.group(1)))
    shaped: set[str] = set()
    for line in re.findall(r"^PROVISIONAL: (.*)$", g, re.M):
        shaped.update(re.findall(r"\b[A-Z]{2,}\b", line))
    watch = re.search(r"^During the corpus rewrite.*$", g, re.M)
    if watch:
        shaped.update(re.findall(r"`([A-Z]{2,})`", watch.group(0)))
    return reserved, shaped - reserved


RESERVED_CAPITALS, GRAMMAR_SHAPED = reserved_capitals()
CAPITAL_WORD = re.compile(r"\b[A-Z][A-Z0-9]+\b")


def unreserved_capitals(text: str) -> tuple[list[str], list[str]]:
    """(grammar-shaped, other) upper-case words in a rule that are not reserved.

    Grammar-shaped: a provisional or watched form, or an inflection of a reserved
    token (EXIST, EXCEEDING). Other: a proper noun written in capitals (an
    acronym, the language's name). Both gate: the maintainer ruled at council
    read 85 that a rule spells a proper noun out, with no declared exception.
    """
    shaped, other = [], []
    for w in CAPITAL_WORD.findall(re.sub(r"`[^`]*`", " ", text)):
        if w in RESERVED_CAPITALS:
            continue
        inflected = any(min(len(w), len(r)) >= 4 and (w.startswith(r) or r.startswith(w))
                        for r in RESERVED_CAPITALS)
        (shaped if (w in GRAMMAR_SHAPED or inflected) else other).append(w)
    return shaped, other


# a `>=` spelled as a two-arm disjunction: "<X> EXCEEDS <Y> OR <X> EQUALS <Y>",
# the same operand pair in both arms. The condition operator set carries EXCEEDS
# and EQUALS and nothing between them (`Term condition operator`). Counting this
# by hand mis-measured it twice: a loose "EXCEEDS ... OR ... EQUALS" match also
# catches "X EXCEEDS Y OR Y EQUALS none", which is two propositions and not a
# comparison at all (council read 31).
GE_DISJUNCTION = re.compile(
    r"(?P<x1>[A-Za-z_][\w'’ ]*?)\s+EXCEEDS\s+(?P<y1>[A-Za-z_][\w'’ ]*?)"
    r"\s+OR\s+(?P<x2>[A-Za-z_][\w'’ ]*?)\s+EQUALS\s+(?P<y2>[A-Za-z_][\w'’ ]*)")


def _ge_operand(s: str) -> str:
    s = re.sub(r"^(?:IF|WHEN|AND|OR)\s+", "", s.strip().rstrip("."))
    return re.sub(r"^(?:the|a|an)\s+", "", s)


def ge_disjunction(line: str) -> tuple[str, str] | None:
    """The (x, y) of a genuine `x >= y` spelled as a disjunction, else None."""
    for m in GE_DISJUNCTION.finditer(line):
        x1, y1 = _ge_operand(m.group("x1")), _ge_operand(m.group("y1"))
        x2, y2 = _ge_operand(m.group("x2")), _ge_operand(m.group("y2"))
        if x1 == x2 and y2[:len(y1)] == y1:
            return x1, y1
    return None


# A reservation rule -- "... MUST answer <outcome> ONLY IF <id> DOES NOT EQUAL
# blank" (written "<id> EXISTS" before v0.52) -- is only meaningful beside a rule
# routing a blank <id> somewhere. Without that partner the blank case has no legal
# answer at all: the reservation forbids the miss answer and every other arm is
# gated behind checks a blank id cannot reach. Five atoms carry the spelling; one
# carried it unpartnered (council read 36).
RESERVE_EXISTS = re.compile(
    r"MUST answer [a-z-]+ ONLY IF (?:the )?([a-z_]+) DOES NOT EQUAL blank\b")
BLANK_GUARD = re.compile(r"IF (?:the )?([a-z_]+) EQUALS blank THEN")


# One condition operator, one sense (GRACE-lang v0.52, Earned vocabulary 6
# through 12): a thing's absence is `no thing EXISTS`, a missing value is
# `EQUALS blank`, membership is `IS IN`, and `=` stays in value sets. Before
# v0.52 `step_id NOT EXISTS` (the caller sent nothing) and `the assignment_id
# NOT EXISTS` (no record carries the id) differed by an article (council read 99).
RETIRED_CONDITION = (
    (re.compile(r"\bNOT EXISTS\b"), "`NOT EXISTS`; a thing's absence is `no thing EXISTS` "
     "and a missing value is `EQUALS blank` (Earned vocabulary 6, Earned vocabulary 7)"),
    (re.compile(r"\bEXISTS in\b"), "`EXISTS in`; membership is `IS IN` (Earned vocabulary 9)"),
    (re.compile(r"(?<![!<>=])!="), "`!=`; write DOES NOT EQUAL (Earned vocabulary 12)"),
    (re.compile(r"\bNOT EXCEEDS\b"), "`NOT EXCEEDS`; write DOES NOT EXCEED (Earned vocabulary 17)"),
    (re.compile(r"\b(?:is|are) blank\b"), "`is blank`; a missing value is `EQUALS blank` "
     "(Earned vocabulary 7)"),
    (re.compile(r"(?:\b(?:IF|WHEN|AND|OR|ONLY IF)\s+|\bwhose\s+)(?:the |a |an )?[a-z][\w' -]*? stands (?:in|outside)\b"),
     "a state tested with *stands in*; a record's state is a value, `the record's state EQUALS member` "
     "(Earned vocabulary 15)"),
)
RULE_EQUALS = re.compile(r"(?<![!<>=])=(?!=)")
VALUE_EXISTS = re.compile(r"(?:^|\b(?:IF|WHEN|AND|OR|ONLY IF) )(?:(?:the|a|an|no|EVERY) )?([a-z_][a-z0-9_]*) EXISTS\b")


# The rule nouns (GRACE-lang v0.53): nouns every specification's rules share,
# declared once in the grammar, read from its `Term rule noun` line so the set
# has one owner. A specification writes no `Term` declaration for one, and
# writes each under its own name — *argument* was a second name for input
# (council read 100).
def rule_nouns(grammar_path=None) -> set[str]:
    p = grammar_path or os.path.join(os.path.dirname(__file__), "..", "..", "GRACE-lang.md")
    try:
        m = re.search(r"^Term rule noun:.*? — (.+)\.$", open(p, encoding="utf-8").read(), re.M)
    except OSError:
        return set()
    return {x.strip() for x in m.group(1).split(",")} if m else set()


RULE_NOUNS = rule_nouns()
# Symbols stay out of a rule's own text (GRACE-lang v0.56, Earned vocabulary 16):
# a section is "the section titled X", a map entry "k mapped to v", a call's
# answer "answering x", a record "carrying a, b and c", a set of codes "a and
# b", a range "steps 2 through 5"; a template such as `<kind>.intended` is a
# code spelling and sits in a code span (council read 103).
RULE_SYMBOL = re.compile(r"[§→{}|<>–/*]")
RETIRED_NOUNS = ((re.compile(r"\barguments?\b"), "argument", "input"),)


def bare_name_text(stmt: str, names: list[str]) -> str:
    """The statement with every declared name blanked: a name's own words are the
    name's, so *allocated after* is no watch word (council read 136)."""
    for n in names:
        if " " in n:
            stmt = stmt.replace(n, " ")
    return stmt


INSTANT_WORD = re.compile(r"\b(now|[a-z][a-z ]*? at|[a-z][a-z ]*? instant|instant|deadline|terminus)\b")
EXCEEDS_RX = re.compile(r"\b(?:DOES NOT EXCEED|EXCEEDS)\b")
PRECEDES_RX = re.compile(r"\b(?:DOES NOT PRECEDE|PRECEDES)\b")
LOWER_PRECEDE = re.compile(r"\b(precedes|precede)\b")


def operand_type(text: str) -> list[str]:
    """One operator, one operand type (Earned vocabulary 18, council read 146).

    EXCEEDS compares quantities and lengths; PRECEDES compares instants. Each
    comparison is read for the shape of the operand beside it, so a duration
    keeps EXCEEDS (`completion bound EXCEEDS lease spend`) and an instant takes
    PRECEDES (`now PRECEDES the resolved submitted at`)."""
    bare = CODE_SPAN.sub(" ", text)
    out = []
    for m in EXCEEDS_RX.finditer(bare):
        near = bare[max(0, m.start() - 70):m.start()] + " " + bare[m.end():m.end() + 45]
        if INSTANT_WORD.search(near) and "duration" not in near and "bound EXCEEDS" not in bare[max(0, m.start()-12):m.end()]:
            out.append(f"`{m.group(0)}` between instants; compare two instants with PRECEDES "
                       f"(Earned vocabulary 18)")
    for m in LOWER_PRECEDE.finditer(bare):
        out.append(f"`{m.group(0)}` in lower case; PRECEDES is a condition operator "
                   f"(Earned vocabulary 18)")
    return out


def condition_form(text: str, inputs: set[str], in_rule: bool) -> list[str]:
    """Why a rule or declaration leaves the condition operators, if it does."""
    bare = CODE_SPAN.sub(" ", text)
    out = [f"a retired form, {why}" for rx, why in RETIRED_CONDITION if rx.search(bare)]
    if in_rule and RULE_EQUALS.search(bare):
        out.append("`=` in a rule; a test is EQUALS and a write is `field set to value` "
                   "(Earned vocabulary 11, Earned vocabulary 12)")
    for m in VALUE_EXISTS.finditer(bare):
        if m.group(1) in inputs:
            out.append(f"`{m.group(1)}` is an input, a value, tested with EXISTS; "
                       f"write `{m.group(1)} EQUALS blank` (Earned vocabulary 8)")
    if in_rule:
        out.extend(operand_type(text))
    return out


def unpartnered_reservations(text: str) -> list[tuple[str, str]]:
    """(label, identifier) for each EXISTS-reservation with no blank-guard partner."""
    blanks = set(BLANK_GUARD.findall(text))
    out = []
    for m in re.finditer(r"^\s*([A-Z][A-Za-z ]*\d+(?:\.\d+)?): (.*)$", text, re.M):
        rm = RESERVE_EXISTS.search(m.group(2))
        if rm and rm.group(1) not in blanks:
            out.append((m.group(1), rm.group(1)))
    return out


SNAKE_WORD = re.compile(r"\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b")
LABEL = re.compile(r"^((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?):\s*(.*)$")
LABEL_PARTS = re.compile(r"^(?P<name>.+?)(?: step (?P<step>[\d½]+)\.(?P<sn>\d+)| (?P<major>\d+)\.(?P<minor>\d+)| (?P<num>\d+))(?P<letter>[a-z]?)$")
PREFIX = re.compile(r"^(WHY|NOTE|UX|PROVISIONAL):")
FENCE = re.compile(r"^(\s*)```(\w*)\s*$")
MIGRATED = re.compile(r"^Term qualifiers:[^\n]*\bmigrated\b", re.M)
TERM_DECL = re.compile(r"^\s*Term ([^:`]+?): (.*)$")
# The one declaration form (GRACE-lang Closed vocabulary 10, v0.45), read strictly:
# the name runs to the first colon, bare; one space; the definition ends with a period.
TERM_DECL_STRICT = re.compile(r"^\s*Term ([^:`\s](?:[^:`]*[^:`\s])?): \S.*\.$")
DECL_OPENER = re.compile(r"^\s*(Terms ›|Term\b)")
BOLD_BULLET_DECL = re.compile(r"^\s*- \*\*`?[a-z][a-z0-9_ -]*`?\*\* — ")
MODAL = re.compile(r"\b(MUST NOT|MUST|MAY)\b")
_LABEL_TEXT = r"((?:[A-Za-z_][\w'’-]*)(?: [A-Za-z_][\w'’-]*){0,4} [\d½]+(?:\.\d+)?[a-z]?)"
# A tombstone is its own line (GRACE-lang v0.46): `Deleted: Label. The owner, and why.`
TOMBSTONE = re.compile(r"^Deleted: " + _LABEL_TEXT + r"\. \S.*\.$")
# the retired shape, a NOTE whose text began with a label and the word deleted
LEGACY_TOMBSTONE = re.compile(r"^NOTE:\s*" + _LABEL_TEXT + r"\s+deleted\b")
# the last number of a range citation, `Operation 3 through 7` (Hard invariant 29)
RANGE_END = re.compile(r" through ([\d½]+(?:\.\d+)?[a-z]?)(?![\w.]\d)")
PRONOUN = re.compile(r"\b(it|its|itself|they|their|them|he|she|his|her)\b")
# The grammar's `pronoun` declaration also names this, that, these and those
# standing alone, and names this file as what enforces them — it did not.
# `that` is a relative in most rules and `this` a determiner, so only the two
# that are almost always pronominal are detected, advisory, pending a smarter
# rule (council read 24).
DEMONSTRATIVE = re.compile(r"\b(these|those)\b")
# Two detectors ported from Kimi's sweep parser (council read 24). A comparison
# written in English rather than through EXCEEDS, EQUALS, DOES NOT EQUAL, EXISTS or IS IN is
# one the normalizer cannot read; most route through an admitted operator, and
# the ones that cannot are the pressure §18 counts.
COMPARATOR = re.compile(r"\b(past|longer than|shorter than|more than|fewer than|greater than|less than|short of|at most|at least|no longer|no earlier|no later|advance past)\b", re.I)
# A modal outside the admitted three carries no obligation the parser can read.
SOFT_MODAL = re.compile(r"\b(can|could|would|should|might)\b")
# An action that rejects and also carries an unconditional effect rule says both
# things about a refused call: the prose spec relied on case-order ("if we got
# here, the guards passed") and Hard invariant 15 and Hard invariant 16 forbid
# inferring it. The cure is a declared admitted-call term as the effect's
# subject (council read 26).
ACTION_RULE = re.compile(r"^(?:IF .*? THEN )?\[([A-Z][A-Za-z ]+)\] (MUST(?: NOT)?|MAY) (\w+)")
# The condition operators are the whole set a condition may carry; an English
# comparison in an IF is a condition the normalizer cannot read (council read 26).
COND_ENGLISH = re.compile(r"^IF .*?\b(is not|is no|are not|does not|do not|is a|are a|is negative|is positive|is zero)\b.*? THEN ")
ARITH = re.compile(r"[+×−]|\s-\s")
MARKER = re.compile(r"\[([^\]\[]+)\]")
MD_LINK = re.compile(r"\[([^\]\[]+)\]\(([^)\s]*)\)")
STRIPPED_LINK = re.compile(r"(?<![\[\]\w`/])[A-Za-z][A-Za-z' -]*\((?:\.\./)*(?:atoms/|compositions/|\./)[a-z0-9-]+\.md(?:#[^)]*)?\)")
LINK_LINE = re.compile(r"(?m)^\[([^\]]+)\]:\s*\S")
CODE_SPAN = re.compile(r"`[^`]*`")
SIGNATURE = re.compile(r"^[a-z_][a-z0-9_]*\(")
# The signature form (GRACE-lang v0.48, Closed vocabulary 24): a header naming
# the inputs, an answers line, a refuses line where the action refuses.
_SIG_NAME = r"[a-z_][a-z0-9_]*"
SIG_HEAD = re.compile(r"^(" + _SIG_NAME + r")\(((?:optional )?" + _SIG_NAME +
                      r"(?:, (?:optional )?" + _SIG_NAME + r")*)?\)$")
_SIG_WORD = r"[a-z][a-z0-9_-]*"
_SIG_ARM = (_SIG_WORD + r"(?: " + _SIG_WORD + r")*" +
            r"(?:\((?:" + _SIG_WORD + r"(?: " + _SIG_WORD + r")*)(?:, " +
            _SIG_WORD + r"(?: " + _SIG_WORD + r")*)*\))?")
SIG_ARMS = re.compile(r"^" + _SIG_ARM + r"(?: \| " + _SIG_ARM + r")*$")
# a refusal is one word: two words with no `|` between them are two codes
# read as one (the class V-signature-alternation caught in the older form)
_SIG_CODE = _SIG_WORD + _SIG_ARM[_SIG_ARM.index("(?:\\(("):]
SIG_CODES = re.compile(r"^" + _SIG_CODE + r"(?: \| " + _SIG_CODE + r")*$")
SIG_RETIRED = (("→", "the arrow"), ("->", "the arrow"), ("?", "a trailing `?`"),
               ("{", "a braced record"), ("rejected(", "the `rejected(…)` wrapper"))


def signature_form(body: list[str]) -> list[tuple[int, str]]:
    """Where a signature block leaves the signature form, and why — offsets
    into `body`. Closed vocabulary 24 through 27."""
    out: list[tuple[int, str]] = []
    expect = "head"
    for off, raw in enumerate(body):
        why = next((w for tok, w in SIG_RETIRED if tok in raw), None)
        if why:
            out.append((off, f"{why}, which the signature form retired"))
            expect = "head"
            continue
        if not raw.strip():
            if expect == "answers":
                out.append((off, "a signature with no answers line"))
            expect = "head"
            continue
        if raw.startswith("  answers "):
            if expect != "answers":
                out.append((off, "an answers line with no signature above it"))
            elif not SIG_ARMS.match(raw[len("  answers "):]):
                out.append((off, "answers arms that are not names, or an arm holding an arm"))
            expect = "refuses"
            continue
        if raw.startswith("  refuses "):
            if expect != "refuses":
                out.append((off, "a refuses line that does not follow an answers line"))
            elif not SIG_CODES.match(raw[len("  refuses "):]):
                out.append((off, "refusals that are not one-word codes separated by `|`, or an arm holding an arm"))
            expect = "blank"
            continue
        if expect not in ("head",):
            out.append((off, "two signatures with no blank line between them"
                        if SIG_HEAD.match(raw) else "a line the signature form has no place for"))
            expect = "answers" if SIG_HEAD.match(raw) else "head"
            continue
        if not SIG_HEAD.match(raw):
            out.append((off, "a header that is not `name(input, optional input)` on one line"))
        expect = "answers"
    if expect == "answers":
        out.append((len(body) - 1, "a signature with no answers line"))
    return out


def example_call(lines: list[str], k: int) -> bool:
    """A bare fence opening with a call whose arguments carry values — `name:
    value` or a literal — is an example, the surface nothing (Surface 21)."""
    text = "\n".join(lines[k:k + 8])
    depth, args = 0, ""
    for ch in text[text.index("("):]:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                break
        args += ch
    return ":" in args or '"' in args
ADVISORY = {"W-or-word", "W-watch-word", "W-term-unused", "W-lowercase-after",
            "W-two-obligations", "W-demonstrative", "W-comparator", "W-modal",
            "W-unconditional-effect", "W-condition-operator", "W-duplicate-proposition",
            "D-decl-modal", "D-decl-selfref", "D-decl-unresolved",
            "K-check-bare", "S-action-unused", "E-not-exclusive"}
# D-tombstone-form gates: a tombstone in any other shape reserves nothing
# A declaration may carry arithmetic and comparison where a rule may not
# (Closed vocabulary 9, Closed vocabulary 11) — which is where complexity
# goes when a rule cannot hold it, and the one place nothing read it.
DECL_ARITH = re.compile(r"[−+×÷]|\bmax\(|\bmin\(")
DECL_TOKEN = re.compile(r"[a-z_][a-z0-9_]*")
DECL_SKIP = {"max", "min", "of", "the", "a", "an", "and", "or", "per", "less", "true", "false"}
# the reserved grammar verbs a modal may take: an ordering claim is a grammar
# claim, not a record verb the specification declares (council read 146)
RESERVED_VERBS = {"EXCEED", "PRECEDE"}


@dataclass
class Rule:
    line: int
    label: str
    text: str
    indent: int
    parent: str | None = None


@dataclass
class Finding:
    path: Path
    line: int
    code: str
    message: str


def _words(s: str) -> list[str]:
    s = s.replace("`", " ").lower()
    out = []
    for w in re.split(r"[\s/=—–(),.:;*-]+", s):
        w = w.strip("'’")
        if not w:
            continue
        if w.endswith("ies") and len(w) > 4:
            w = w[:-3] + "y"
        elif w.endswith("s") and len(w) > 3 and not w.endswith("ss"):
            w = w[:-1]
        out.append(w)
    return out


def _matches(word: str, heading_words: list[str]) -> bool:
    for h in heading_words:
        if word == h or (min(len(word), len(h)) >= 4 and (h.startswith(word) or word.startswith(h))):
            return True
    return False


def declared_verbs(text: str) -> set[str] | None:
    m = re.search(r"^\s*(?:Term record verbs|Record verbs):\s*(.*)$", text, re.M)
    if not m:
        return None
    return {v.strip().strip("`").rstrip(".") for v in m.group(1).split(",") if v.strip()}


def declared_terms(text: str) -> dict[str, int]:
    out: dict[str, int] = {}
    for i, line in enumerate(text.split("\n"), start=1):
        m = TERM_DECL.match(line)
        if m:
            out.setdefault(m.group(1), i)
    return out



# A code span quotes literal text and never marks a name (GRACE-lang v0.51,
# Surface 30). The names a spec declares, read without the backticks that used
# to mark them: its Term names, its signatures' names, the members either side
# of a `|` in a declaration, and the entries of its vocabulary lines.
_NAME_SHAPE = re.compile(r"[a-z][a-z0-9_]*(?:[ -][a-z0-9_]+)*|[A-Z]{2,}(?: [A-Z]{2,})*")
# record verbs are English verbs; a backticked `revoke` quotes an action's spelling
_LIST_CATEGORIES = {"actors", "records", "bounds", "cadences", "terms", "cited"}


def declared_names(text: str) -> set[str]:
    names = set(declared_terms(text))
    for line in text.split("\n"):
        sm = SIG_HEAD.match(line)
        if sm:
            names.add(sm.group(1))
            names.update(x.removeprefix("optional ") for x in (sm.group(2) or "").split(", ") if x)
        if line.startswith(("  answers ", "  refuses ")):
            body = line[len("  answers "):]
            names.update(a.strip() for a in re.sub(r"\([^)]*\)", " ", body).split("|"))
            for pay in re.findall(r"\(([^)]*)\)", body):
                names.update(x.strip() for x in pay.split(","))
        m = TERM_DECL.match(line)
        if not m:
            continue
        body = CODE_SPAN.sub(" ", m.group(2))
        for run in re.findall(r"[^|—;:(),.]+(?:\|[^|—;:(),.]+)+", body):
            names.update(x.strip() for x in run.split("|"))
        if m.group(1) in _LIST_CATEGORIES:
            names.update(x.strip() for x in re.split(r",|;| and ", body.split(" — ")[0].rstrip(".")))
    return {n for n in names if _NAME_SHAPE.fullmatch(n)}

def borrowed_names(path: Path, text: str) -> set[str]:
    """The names this specification uses and another declares — the sixth time
    the corpus has taught one reader that a declared name's words are the name's
    (council read 139), and the first where the declaration is elsewhere.

    Two paths make a borrowed name legitimate, and both are read here: the
    `Term cited:` line, whose run form closes each list with its owner
    (Closed vocabulary 16), and the specifications named on `Term constituents:`,
    read one level — a constituent's own constituents reach through its cited
    line rather than through this one."""
    names: set[str] = set()
    m = re.search(r"^Term cited:(.*)$", text, re.M)
    if m:
        body = CODE_SPAN.sub(" ", m.group(1))
        for run in re.split(r":\s*[A-Z][\w ]*?\.(?=\s|$)", body):
            names.update(x.strip() for x in re.split(r",|;| and ", run) if x.strip())
    m = re.search(r"^Term constituents:(.*)$", text, re.M)
    if m:
        for link in re.findall(r"\]\(([^)]+\.md)", m.group(1)):
            other = (path.parent / link).resolve()
            try:
                names |= declared_names(other.read_text(encoding="utf-8"))
            except OSError:
                continue
    return {n for n in names if _NAME_SHAPE.fullmatch(n)}


def scan(path: Path) -> list[Finding]:
    text = path.read_text(encoding="utf-8")
    blank_guarded = set(BLANK_GUARD.findall(text))
    lines = text.split("\n")
    findings: list[Finding] = []
    rules: list[Rule] = []
    labels: dict[str, int] = {}
    tombstones: dict[str, int] = {}
    exemplars: set[str] = set()
    signatures: list[tuple[int, str]] = []

    def add(line: int, code: str, msg: str) -> None:
        findings.append(Finding(path, line, code, msg))

    # D-wire-spelling: a fenced block that is not rule text is a wire surface —
    # a signature, an event schema, a record shape — and carries the code
    # spelling, never the term entry's English name (council read 138; the
    # defect it found had stood in one signature since `A signature has one
    # owner`, because nothing read a fenced block for English).
    projections: dict[str, str] = {}
    heading = None
    for ln in lines:
        m = re.match(r"^####\s+(.*?)\s*$", ln)
        if m:
            heading = m.group(1).strip()
            continue
        m = re.match(r"^\s*Projection:\s*(.*)$", ln)
        if m and heading:
            for tok in SNAKE_WORD.findall(m.group(1)):
                projections.setdefault(heading.strip("[]").lower(), tok)
    if projections:
        # a braced shape names a record's fields on the wire wherever it sits,
        # fenced or inline on a declaration line (council read 140)
        for off, ln in enumerate(lines, start=1):
            for shape in re.findall(r"\{[^}]*\}", CODE_SPAN.sub(" ", ln)):
                for english, wire in projections.items():
                    if " " in english and re.search(r"\b" + re.escape(english) + r"\b", shape.lower()):
                        add(off, "D-wire-spelling",
                            f"'{english}' inside a braced shape; write the projection `{wire}` "
                            f"(the wire is written where the wire belongs): {shape[:60]}")
        k = 0
        while k < len(lines):
            if not lines[k].lstrip().startswith("```"):
                k += 1
                continue
            j = k + 1
            while j < len(lines) and not lines[j].lstrip().startswith("```"):
                j += 1
            first = next((b for b in lines[k + 1:j] if b.strip()), "").strip()
            # A wire block names itself: a signature opens `name(input, …)`, a
            # record or event shape opens `{`. The Ledger and the rule blocks are
            # fenced too and are prose, where a term entry's name belongs.
            if re.match(r"^[a-z_]+\(", first) or first.startswith("{"):
                for off, body in enumerate(lines[k + 1:j], start=k + 2):
                    for english, wire in projections.items():
                        if " " in english and re.search(r"\b" + re.escape(english) + r"\b", body.lower()):
                            add(off, "D-wire-spelling",
                                f"'{english}' inside a wire block; write the projection `{wire}` "
                                f"(the wire is written where the wire belongs): {body.strip()[:60]}")
            k = j + 1

    # D-decl-form: every line that opens like a declaration is one, in the one form
    in_fence = False
    for k, ln in enumerate(lines, start=1):
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not DECL_OPENER.match(ln):
            continue
        if ln.lstrip().startswith("Terms ›"):
            add(k, "D-decl-form", "a declaration in the retired `Terms ›` form; write `Term name: definition.` (GRACE-lang v0.45)")
        elif not TERM_DECL_STRICT.match(ln):
            add(k, "D-decl-form", f"not the declaration form `Term name: definition.` — a bare name, one space after the colon, a closing period: {ln.strip()[:70]}")

    # D-condition-form on declarations: a declaration may carry a condition
    # (Term live, Term lapsed) and the value-set form's `=`, and nothing retired
    sig_inputs = {x.removeprefix("optional ") for ln in lines for sm in [SIG_HEAD.match(ln)]
                  if sm for x in (sm.group(2) or "").split(", ") if x}
    history = False
    for k, ln in enumerate(lines, start=1):
        if ln.startswith("## "):
            history = ln.startswith(("## Status", "## Ledger"))
        if history or not TERM_DECL.match(ln):
            continue
        for why in condition_form(ln, sig_inputs, False):
            add(k, "D-condition-form", f"{why}: {ln.strip()[:60]}")
        dm = TERM_DECL.match(ln)
        if path.name != "GRACE-lang.md" and dm.group(1).strip() in RULE_NOUNS:
            add(k, "D-rule-noun", f"`{dm.group(1).strip()}` is a rule noun the grammar declares; "
                f"a specification writes no declaration for one (Earned vocabulary 13)")
        for rx, old, new in RETIRED_NOUNS:
            if rx.search(CODE_SPAN.sub(" ", ln)):
                add(k, "D-rule-noun", f"*{old}* names the rule noun *{new}*; write {new} "
                    f"(Earned vocabulary 14): {ln.strip()[:60]}")

    # D-decl-form, the bold-bullet shape: `- **name** — definition` declared a
    # setting or a store before migration; a migrated spec declares it with
    # `Term name:` under a bare bullet heading (council read 107)
    in_fence = False
    for k, ln in enumerate(lines, start=1):
        if FENCE.match(ln):
            in_fence = not in_fence
            continue
        if not in_fence and BOLD_BULLET_DECL.match(ln):
            add(k, "D-decl-form", "a bold-bullet declaration; keep `- **name**` as the heading and "
                f"declare with `Term name: definition.` beneath it: {ln.strip()[:60]}")

    # D-code-span: a declared name is written bare (Surface 30)
    names_here = declared_names(text)
    in_fence = history = False
    for k, ln in enumerate(lines, start=1):
        if FENCE.match(ln):
            in_fence = not in_fence
            continue
        if ln.startswith("## "):
            history = ln.startswith(("## Status", "## Ledger"))
        if in_fence or history or ln.startswith(("#", "Projection:", "Wire:")) or re.match(r"^\[[^\]]+\]:", ln):
            continue
        for sm in re.finditer(r"(?<!`)`([^`\n]+)`(?!`)", ln):
            if sm.group(1) in names_here:
                add(k, "D-code-span", f"`{sm.group(1)}` is a name this spec declares; a code span "
                    f"quotes literal text, so write the name bare (Surface 30)")

    ctx = {"h2": "", "h3": "", "h4": "", "bullet": "", "italic": "", "inv": None, "step": None}

    def track(ln: str) -> None:
        hm = re.match(r"^(#{2,4}) (.*)$", ln)
        if hm:
            lvl = len(hm.group(1))
            if lvl == 2:
                ctx.update(h2=hm.group(2), h3="", h4="")
            elif lvl == 3:
                ctx.update(h3=hm.group(2), h4="")
            else:
                ctx["h4"] = hm.group(2)
            ctx.update(bullet="", italic="", inv=None, step=None)
            return
        im = re.match(r"^\s*- \*\*Invariant (\d+) —(.*)", ln)
        if im:
            ctx.update(inv=im.group(1), bullet="Invariant " + im.group(2), step=None)
            return
        bm = re.match(r"^- \*\*([^*]+)\*\*", ln)
        if bm and not bm.group(1).startswith("["):
            ctx.update(bullet=bm.group(1), italic="", inv=None, step=None)
            return
        sm = re.match(r"^\s*(\d+)\. \*\*", ln) or re.match(r"^\s*\*\*Step ([\d½]+)", ln)
        if sm:
            ctx["step"] = sm.group(1)
            return
        it = re.match(r"^\*([A-Z][^*]*?)\*", ln)
        if it:
            ctx["italic"] = it.group(1)

    i = 0
    n = len(lines)
    while i < n:
        m = FENCE.match(lines[i])
        if not m:
            track(lines[i])
            i += 1
            continue
        info = m.group(2)
        fence_indent = len(m.group(1))
        start = i + 1
        j = start
        while j < n and not (FENCE.match(lines[j]) and FENCE.match(lines[j]).group(2) == ""):
            j += 1
        block = lines[start:j]
        if info not in ("", "text"):
            i = j + 1  # another language's code is the surface nothing (Surface 21)
            continue
        if info == "text":
            add(i + 1, "D-fence-form", "a fence marked `text`; a GRACE lang block opens with a bare "
                "fence and its first line says what it is (Surface 28, GRACE-lang v0.49)")
        # Surface 18: classify by the first non-blank line
        first = next((b.strip() for b in block if b.strip()), "")
        if not first:
            add(start, "F-fence-empty", "empty fence")
        elif not (PREFIX.match(first) or LABEL.match(first) or first.startswith("Deleted:")):
            h = start + next(o for o, b in enumerate(block) if b.strip())  # the first line's index
            if SIGNATURE.match(first) and not example_call(lines, h):
                # Surface 20: a signature opens a signature block
                for off, why in signature_form(lines[h:j]):
                    add(h + off + 1, "D-signature-form", f"{why}: {lines[h + off].strip()[:60]}")
                for off, sig in enumerate(lines[h:j]):
                    if SIGNATURE.match(sig):
                        signatures.append((h + off, sig.split("(")[0]))
            elif any(LABEL.match(b.strip()) and not PREFIX.match(b.strip()) for b in block):
                # Surface 19: labelled rules under a first line that opens nothing
                add(start, "F-fence-first", "a fenced block carries a labelled rule under a first line "
                    f"that opens no normative block and no surface (Surface 19): {first[:80]}")
            # Surface 21: any other block is the surface nothing
        elif PREFIX.match(first):
            # Surface 22: the prefix covers the whole block — not normative; labels inside are exemplars
            labelled = 0
            for raw in block:
                lm = LABEL.match(raw.strip())
                if lm:
                    exemplars.add(lm.group(1))
                    labelled += 1
            # a tombstone in the retired NOTE shape reserves nothing: the grammar no
            # longer reads a NOTE as a deletion (v0.46)
            for off, raw in enumerate(block, start=start + 1):
                if LEGACY_TOMBSTONE.match(raw.strip()):
                    add(off, "D-tombstone-form",
                        "a tombstone in the retired `NOTE: … deleted` shape; write "
                        "`Deleted: Label. The owner, and why.` (GRACE-lang v0.46)")
        elif LABEL.match(first) or first.startswith("Deleted:"):
            stack: list[Rule] = []
            for k, raw in enumerate(block, start=start + 1):
                s = raw.strip()
                if not s:
                    continue
                indent = len(raw) - len(raw.lstrip()) - fence_indent
                if s.startswith("Deleted:"):
                    t = TOMBSTONE.match(s)
                    if not t:
                        add(k, "D-tombstone-form",
                            f"not the tombstone form `Deleted: Label. The owner, and why.`: {s[:70]}")
                        continue
                    lab = t.group(1)
                    if lab in tombstones:
                        add(k, "L-dup-tombstone", f"{lab} tombstoned twice")
                    tombstones[lab] = k
                    continue
                if PREFIX.match(s):
                    if LEGACY_TOMBSTONE.match(s):
                        add(k, "D-tombstone-form",
                            "a tombstone in the retired `NOTE: … deleted` shape; write "
                            "`Deleted: Label. The owner, and why.` (GRACE-lang v0.46)")
                    continue  # Surface 23: a later-line prefix covers that line alone
                lm = LABEL.match(s)
                if not lm:
                    add(k, "F-unlabelled", f"unprefixed line in a normative block is not a rule: {s[:80]}")
                    continue
                lab, body = lm.group(1), lm.group(2)
                parts = LABEL_PARTS.match(lab)
                if parts:
                    name = parts.group("name")
                    heading = " ".join(str(ctx[k] or "") for k in ("h2", "h3", "h4", "bullet", "italic"))
                    hw = _words(heading)
                    missing = [w for w in _words(name) if not _matches(w, hw)]
                    if missing:
                        add(k, "R-label-heading", f"{lab}: the label's name is not the heading it sits under ({', '.join(missing)}) (Rule shape 7)")
                    if any(re.fullmatch(r"[A-Z]{2,3}", w) and w != "WHEN" for w in name.split()):
                        add(k, "R-label-abbrev", f"{lab}: an abbreviation in a label (Rule shape 8)")
                    if parts.group("major") and name == "Invariant" and ctx["inv"] and parts.group("major") != ctx["inv"]:
                        add(k, "R-label-heading", f"{lab}: sits under Invariant {ctx['inv']} (Rule shape 7)")
                    if parts.group("step") and ctx["step"] and fence_indent > 0 and parts.group("step") != ctx["step"]:
                        add(k, "R-label-heading", f"{lab}: sits under step {ctx['step']} (Rule shape 7)")
                if lab in labels:
                    add(k, "L-dup-label", f"label {lab} already used at line {labels[lab]}")
                labels[lab] = k
                # WHEN children: indented under a WHEN parent, labelled parent + letter
                while stack and indent <= stack[-1].indent:
                    stack.pop()
                parent = stack[-1] if stack else None
                rule = Rule(k, lab, body, indent, parent.label if parent else None)
                rules.append(rule)
                if parent:
                    if not re.match(r"^" + re.escape(parent.label) + r"[a-z]$", lab):
                        add(k, "R-child-label", f"child of {parent.label} carries label {lab}")
                    if body.startswith("WHEN "):
                        add(k, "R-nested-when", f"{lab}: a WHEN block inside a WHEN block (Hard invariant 6)")
                if body.startswith("WHEN "):
                    stack.append(rule)
            # WHEN with no children
            for r in rules:
                if r.line >= start and r.text.startswith("WHEN ") and not any(x.parent == r.label for x in rules):
                    add(r.line, "R-when-empty", f"{r.label}: WHEN block with no child rule")
        i = j + 1

    # tombstone reuse (Hard invariant 25, Hard invariant 27)
    for lab, k in tombstones.items():
        if lab in labels:
            add(labels[lab], "L-tombstone-reuse", f"{lab} is tombstoned at line {k} and used as a rule (Hard invariant 27)")

    verbs = declared_verbs(text)
    # a declared name's own words are not verbs: *and hold reason* names a term,
    # not a second obligation (council read 135)
    multiword = sorted((n for n in (declared_names(text) | borrowed_names(path, text)) if " " in n),
                       key=len, reverse=True)
    link_lines = set(LINK_LINE.findall(text))
    for r in rules:
        body = CODE_SPAN.sub("QUOTED", r.text)  # a code span quotes text; never the rule's own tokens
        # a link names another specification, and a rule names one bare (Surface 29):
        # inside a fence a link does not render, so it reads as a marker
        for lk in MD_LINK.finditer(r.text):
            add(r.line, "F-bracket", f"{r.label}: '[{lk.group(1)}]({lk.group(2)})' is a link in a rule; "
                f"name the specification alone (Surface 29)")
        for lk in STRIPPED_LINK.finditer(CODE_SPAN.sub("", r.text)):
            add(r.line, "F-bracket", f"{r.label}: '{lk.group(0)}' is a link with its brackets stripped; "
                f"name the specification alone (Surface 29)")
        # a marker lands on the name's term entry through a link line (Surface 26)
        for mk in MARKER.findall(MD_LINK.sub("", body)):
            if re.match(r"^[A-Z][A-Za-z -]*[A-Za-z]$", mk) and mk not in link_lines:
                add(r.line, "F-bracket", f"{r.label}: '[{mk}]' lands on no term entry — no `[{mk}]:` "
                    f"link line in this spec (Surface 26)")
        if body.startswith("PROVISIONAL:"):
            continue  # Surface 14: no normative force; not shape-checked
        caps_shaped, caps_other = unreserved_capitals(r.text)
        if caps_shaped:
            add(r.line, "R-caps",
                f"{r.label}: {', '.join(caps_shaped)} in capitals is not a reserved token — "
                f"a watched or provisional form, or an inflection of one (Casing 2, Casing 6)")
        if caps_other:
            add(r.line, "R-caps",
                f"{r.label}: {', '.join(caps_other)} in capitals is not a reserved token — a proper "
                f"noun or acronym in a rule is spelled out, because Casing 6 reads the capital "
                f"tier as reserved (ruled at council read 85)")
        for why in condition_form(body, sig_inputs, True):
            add(r.line, "D-condition-form", f"{r.label}: {why}")
        sm = RULE_SYMBOL.search(CODE_SPAN.sub(" ", body))
        if sm:
            add(r.line, "D-rule-symbol", f"{r.label}: `{sm.group(0)}` in a rule's own text; write it in "
                f"words, or quote a code spelling in a code span (Earned vocabulary 16)")
        for rx, old, new in RETIRED_NOUNS:
            if rx.search(CODE_SPAN.sub(" ", body)):
                add(r.line, "D-rule-noun", f"{r.label}: *{old}* names the rule noun *{new}*; "
                    f"write {new} (Earned vocabulary 14)")
        if body.startswith("WHEN "):
            if not body.endswith(":"):
                add(r.line, "R-when-colon", f"{r.label}: WHEN condition must end with a colon")
            cond = body[5:].rstrip(":")
            if " AND " in cond and " OR " in cond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
            continue
        stmt = body
        cond = ""
        if body.startswith("IF "):
            im = re.match(r"^IF (.*?) THEN (.*)$", body)
            if not im:
                add(r.line, "R-if-then", f"{r.label}: IF without THEN")
                continue
            cond, stmt = im.groups()
            if " AND " in cond and " OR " in cond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
        if " IS AUTHORITATIVE FOR " in stmt:
            continue  # Authority 1 shape; carries no modal (outside Closed vocabulary 8)
        mm = MODAL.search(stmt)
        if not mm:
            add(r.line, "R-no-modal", f"{r.label}: no modal and no IS AUTHORITATIVE FOR — a definitional sentence is a declaration (Closed vocabulary 14): {stmt[:80]}")
            continue
        obligation = stmt
        tail = re.search(r"\bONLY IF\b(.*)$", stmt)
        if tail:
            obligation = stmt[: tail.start()]
            tcond = tail.group(1)
            if " AND " in tcond and " OR " in tcond:
                add(r.line, "V-mixed", f"{r.label}: AND and OR in one condition (Hard invariant 7)")
        if re.search(r"\bOR\b", obligation) and "EXACTLY ONE OF" not in obligation:
            add(r.line, "V-or-obligation", f"{r.label}: OR outside a condition (Hard invariant 8)")
        if re.search(r"\bor\b", obligation):
            add(r.line, "W-or-word", f"{r.label}: 'or' inside an obligation — an enumeration the parser cannot read (Earned vocabulary 3)")
        if re.search(r"\bMUST (?!NOT\b)[^.]*\bBEFORE\b", stmt) or re.search(r"\bMAY\b[^.]*\bBEFORE\b", stmt):
            add(r.line, "B-before", f"{r.label}: positive MUST/MAY … BEFORE (Timing 6, Hard invariant 11)")
        if re.search(r"\bAFTER\b", stmt) and not re.search(r"\bONLY AFTER\b", stmt):
            if re.search(r"\bMUST NOT\b", stmt):
                add(r.line, "B-after", f"{r.label}: AFTER under MUST NOT (Timing 4)")
            # under MUST / MAY it is the deterministic sugar (Timing 2, Timing 3)
        if re.search(r"\bAT LEAST\b|\bSTRICTLY\b", stmt):
            add(r.line, "B-banned", f"{r.label}: AT LEAST / STRICTLY (Timing 10, Timing 11)")
        if re.search(r"\bMUST EXCEED\b|\bMAY EXCEED\b", stmt):
            add(r.line, "B-exceed", f"{r.label}: ≥ is written MUST NOT EXCEED (Timing 9)")
        if ARITH.search(stmt) or ARITH.search(cond):
            add(r.line, "A-arith", f"{r.label}: arithmetic in a rule; name a term (Hard invariant 24, Closed vocabulary 9)")
        if PRONOUN.search(stmt) or PRONOUN.search(cond):
            add(r.line, "P-pronoun", f"{r.label}: pronoun in a rule (Hard invariant 4)")
        if re.search(r"\b(MUST NOT|MUST|MAY)\s+(be|is|are|been|being)\b", stmt):
            add(r.line, "C-copula", f"{r.label}: copula after the modal — no declared record verb (Closed vocabulary 8)")
        if COND_ENGLISH.match(body):
            add(r.line, "W-condition-operator",
                f"{r.label}: an English comparison in a condition — the operators are "
                f"EQUALS, DOES NOT EQUAL, EXISTS, IS IN, IS NOT IN, EXCEEDS, DOES NOT EXCEED (Earned vocabulary)")
        cm = COMPARATOR.search(stmt) or COMPARATOR.search(cond)
        if cm:
            add(r.line, "W-comparator",
                f"{r.label}: '{cm.group(1)}' is a comparison outside the condition "
                f"operators — route it through EXCEEDS or a declared term")
        rm = RESERVE_EXISTS.search(stmt)
        if rm and rm.group(1) not in blank_guarded:
            add(r.line, "V-unpartnered-reservation",
                f"{r.label}: reserves an answer to '{rm.group(1)} DOES NOT EQUAL blank' and no rule "
                f"routes a blank {rm.group(1)} — the blank case has no legal answer "
                f"(Hard invariant 16)")
        ge = ge_disjunction(r.text)
        if ge:
            add(r.line, "W-ge-disjunction",
                f"{r.label}: '{ge[0]} >= {ge[1]}' spelled as a two-arm disjunction — "
                f"write '{ge[1]} DOES NOT EXCEED {ge[0]}' (Earned vocabulary 17)")
        sm = SOFT_MODAL.search(stmt) or SOFT_MODAL.search(cond)
        if sm:
            add(r.line, "W-modal",
                f"{r.label}: '{sm.group(1)}' is not an admitted modal (MUST, MUST NOT, MAY)")
        if DEMONSTRATIVE.search(stmt) or DEMONSTRATIVE.search(cond):
            add(r.line, "W-demonstrative",
                f"{r.label}: a demonstrative standing alone (Hard invariant 4's `pronoun` set)")
        if verbs is not None:
            mm2 = MODAL.search(stmt)
            if mm2:
                tail = stmt[mm2.end():]
                for am in re.finditer(r"\band\s+(\w+)", tail):
                    rest = tail[am.start(1):]
                    if any(rest.startswith(n) for n in multiword):
                        continue
                    if am.group(1) in verbs:
                        add(r.line, "W-two-obligations",
                            f"{r.label}: a second declared record verb after 'and' — one "
                            f"obligation per sentence (Rule shape 3, Hard invariant 5)")
                        break
        watched = re.search(r"\b(until|while|unless|after|before)\b", bare_name_text(stmt, multiword))
        if watched:
            add(r.line, "W-watch-word", f"{r.label}: lower-case after/before/until/while/unless — an ordering or duration the tails do not carry (§18 watch list)")
        if verbs is not None:
            for vm in re.finditer(r"\b(MUST NOT|MUST|MAY)\s+(\S+)", stmt):
                v = vm.group(2).strip(",.;:")
                if v in RESERVED_VERBS or v.startswith("("):
                    continue
                if v not in verbs:
                    add(r.line, "C-verb", f"{r.label}: '{v}' after the modal is not a declared record verb (Closed vocabulary 8)")
        # a [Marker] that is not a term card — a bracket range read as a marker
        for mk in MARKER.findall(MD_LINK.sub("", stmt)):
            # a pattern name may carry a hyphen (Multi-Party Approval); a bracket
            # range read as a marker carries digits, commas or brackets and does
            # not (council read 32)
            if not re.match(r"^[A-Z][A-Za-z -]*[A-Za-z]$", mk):
                add(r.line, "F-bracket", f"{r.label}: '[{mk}]' in a rule reads as a term marker; write the range in a term")

    # cross-rule references to labels no rule carries (Hard invariant 12) — names used by this spec's labels only
    names: set[str] = set()
    groups: set[str] = set()
    for lab in list(labels) + list(tombstones):
        parts = LABEL_PARTS.match(lab)
        if not parts:
            continue
        names.add(parts.group("name"))
        if parts.group("major"):
            groups.add(f"{parts.group('name')} {parts.group('major')}")
        if parts.group("step"):
            groups.add(f"{parts.group('name')} step {parts.group('step')}")
    if names:
        name_re = re.compile(r"(?<![\w-])(" + "|".join(re.escape(x) for x in sorted(names, key=len, reverse=True)) +
                             r")( step [\d½]+(?:\.\d+[a-z]?)?| \d+(?:\.\d+)?[a-z]?)(?![\w.]\d)")
        seen: set[str] = set()
        for k, raw in enumerate(lines, start=1):
            if TERM_DECL.match(raw):
                continue
            for fm in name_re.finditer(raw):
                refs = [fm.group(1) + fm.group(2)]
                # a range citation names its last label too (Hard invariant 29)
                end = RANGE_END.match(raw, fm.end())
                if end:
                    step = " step " if fm.group(2).startswith(" step ") else " "
                    refs.append(fm.group(1) + step + end.group(1))
                before = raw[:fm.start()]
                if re.search(r"[A-Z][\w'’]*\s$", before) and fm.group(1) in ("Invariant", "Check"):
                    continue  # another spec's invariant or check, cited by the corpus form
                for ref in refs:
                    if ref in labels or ref in tombstones or ref in exemplars or ref in groups or ref in seen:
                        continue
                    seen.add(ref)
                    add(k, "X-ref", f"reference to {ref}, which no rule in this spec carries (Hard invariant 12)")

    # what a declaration carries: an obligation, or a name that resolves nowhere
    decls = declared_terms(text)
    # every name the spec declares anywhere: a `Term` name, a name inside a
    # vocabulary declaration (the records, bounds, cadences and value-set
    # lines), a signature block's action and argument names.
    CATEGORIES = VOCABULARY_CATEGORIES
    universe = set(decls)
    for name in decls:
        universe.update(DECL_TOKEN.findall(name))
    # a name a constituent owns is cited, never redeclared (Closed vocabulary
    # 15-17): a token the spec uses as a code span elsewhere is a name, and
    # this checker resolves no cross-spec registry
    for line in lines:
        if TERM_DECL.match(line):
            continue
        for span in re.findall(r"`([^`]+)`", line):
            if DECL_TOKEN.fullmatch(span):
                universe.add(span)
    # a declared name is written bare since v0.51, so every declaration's words
    # and every name-shaped word in the prose are names too
    in_fence = False
    for line in lines:
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        m = TERM_DECL.match(line)
        if m:
            universe.update(DECL_TOKEN.findall(m.group(2)))
        elif not in_fence:
            universe.update(t for t in DECL_TOKEN.findall(line) if "_" in t)
        sm = SIG_HEAD.match(line)
        if sm:
            universe.add(sm.group(1))
            universe.update(t for t in DECL_TOKEN.findall(sm.group(2) or "") if t != "optional")
        if line.startswith(("  answers ", "  refuses ")):
            universe.update(DECL_TOKEN.findall(line[len("  answers "):]))
    for name, k in decls.items():
        body = TERM_DECL.match(lines[k - 1]).group(2)
        bare = CODE_SPAN.sub(" ", body)
        # the grammar declares the modals as names (Term modal) and writes them
        # bare since v0.51, so in the grammar a modal in a definition is a name
        if MODAL.search(bare) and "modal" not in decls:
            add(k, "D-decl-modal",
                f"`Term {name}` carries a modal — a definition is not a rule "
                f"(Closed vocabulary 12, Closed vocabulary 14)")
        for span in re.findall(r"`([^`]+)`", body):
            if not DECL_ARITH.search(span):
                continue
            if re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", span):
                add(k, "D-decl-selfref", f"`Term {name}` computes over `{name}`")
                continue
            for ident in DECL_TOKEN.findall(span):
                # a datum this corpus would declare looks like a datum: prose
                # inside a code span, and a bare English word, are neither
                if ident in DECL_SKIP or "_" not in ident:
                    continue
                if ident not in universe:
                    add(k, "D-decl-unresolved",
                        f"`Term {name}` computes over `{ident}`, which this spec declares nowhere "
                        f"(Closed vocabulary 4)")

    # an action that rejects and also carries an unconditional effect rule
    rejects, effects = {}, {}
    for r in rules:
        am = ACTION_RULE.match(r.text)
        if not am:
            continue
        act, modal, verb = am.group(1), am.group(2), am.group(3)
        if verb == "answer" and r.text.startswith("IF"):
            rejects[act] = rejects.get(act, 0) + 1
        elif modal == "MUST" and verb != "answer" and not r.text.startswith("IF") \
                and " ONLY IF " not in r.text:
            effects.setdefault(act, []).append(r)
    for act, rs in effects.items():
        if rejects.get(act):
            for r in rs:
                add(r.line, "W-unconditional-effect",
                    f"{r.label}: [{act}] rejects elsewhere, so this effect also binds a "
                    f"refused call — condition it on an admitted-call term (Hard invariant 16)")

    # one proposition owned twice inside one spec (Authority 3, widened v0.38).
    # A token-set prefilter keeps this linear enough for a 2800-rule corpus:
    # two rules are compared only when they share a rare content word.
    _STOP = {"the","a","an","of","and","or","to","in","for","at","on","by","as",
             "must","not","may","every","this","that","one","two","its"}
    _bucket: dict[str, list] = {}
    for r in rules:
        # a declared name counts as one token, whatever its words: *retention
        # until* is a name, not a retention and an until (council read 136)
        text_one = r.text.lower()
        for n in multiword:
            text_one = text_one.replace(n, n.replace(" ", "_"))
        toks = [w for w in re.findall(r"[a-z_]{4,}", text_one) if w not in _STOP]
        if len(toks) < 3:
            continue
        fam = LABEL_PARTS.match(r.label)
        fam = fam.group("name") if fam else r.label
        key = frozenset(toks)
        for rare in sorted(toks)[:3]:
            for pk, pf, pl in _bucket.get(rare, []):
                if pf == fam:
                    continue
                inter = len(pk & key)
                if inter and inter / max(len(pk), len(key)) > 0.85:
                    add(r.line, "W-duplicate-proposition",
                        f"{r.label} restates {pl} — a spec pays for a proposition "
                        f"once (Authority 3)")
                    rare = None
                    break
            if rare is None:
                break
        for t in sorted(toks)[:3]:
            _bucket.setdefault(t, []).append((key, fam, r.label))

    # an EXACTLY ONE OF whose members are not exclusive: one member containing
    # another is an exclusive choice that does not exclude (council read 9, council read 13)
    for r in rules:
        m = re.search(r"EXACTLY ONE OF (.+?)(?:\.|$)", r.text)
        if not m:
            continue
        members = [x.strip().rstrip(".") for x in m.group(1).split(",") if x.strip()]
        if len(members) < 2:
            continue
        # a final alternative that swallows the others: "a, b, a combination of
        # those" is not an exclusive choice, it is a list with a catch-all (council read 17)
        if re.match(r"^(a combination|any combination|both|any of|some combination)\b", members[-1], re.I):
            add(r.line, "E-not-exclusive",
                f"{r.label}: EXACTLY ONE OF ending in a catch-all — "
                f"'{members[-1][:40]}' subsumes the alternatives before it (Earned vocabulary 4)")
            continue
        for i, a in enumerate(members):
            for j, b in enumerate(members):
                if i == j or not a or not b:
                    continue
                short, long = (a, b) if len(a) < len(b) else (b, a)
                if len(short) > 6 and re.search(r"(?<![\w-])" + re.escape(short) + r"(?![\w-])", long):
                    add(r.line, "E-not-exclusive",
                        f"{r.label}: EXACTLY ONE OF whose members are not exclusive — "
                        f"'{long[:48]}' contains '{short[:32]}' (Earned vocabulary 4)")
                    break
            else:
                continue
            break

    # an action the spec declares and no rule names (advisory): a signature
    # block is a declaration, and a declaration nothing uses is a loose end
    if signatures:
        named = set()
        for r in rules:
            for m in MARKER.finditer(r.text):
                named.add(m.group(1).strip().lower().replace(" ", "_"))
            for m in re.finditer(r"\b([a-z_][a-z0-9_]*)\b", r.text):
                named.add(m.group(1))
        for k, action in signatures:
            if action.strip() not in named:
                add(k, "S-action-unused",
                    f"`{action.strip()}` is declared in a signature block and no rule names it "
                    f"(Closed vocabulary 20)")

    # a value sets line restating a signature: the signature block is the
    # value set of the action's outcomes (Closed vocabulary 21), and a second
    # copy is a second owner that drifts (Authority 3) — close_pool's phantom
    # refusals, council read 98
    if signatures:
        declared = {a.strip() for _, a in signatures}
        for k, raw in enumerate(lines):
            if not raw.startswith("Term value sets:"):
                continue
            for m in re.finditer(r"(?<![\w`])([a-z_][a-z0-9_]*) answers ", raw):
                if m.group(1) in declared:
                    add(k + 1, "D-signature-form",
                        f"a value sets line restates `{m.group(1)}`'s signature; the signature "
                        f"block owns its outcomes (Closed vocabulary 21, Authority 3)")

    # a check that names no rule (advisory): the auditor is the last reader
    # nobody audits, and a check whose failure nobody can state passes forever
    if names:
        for label, line_no in [(r.label, r.line) for r in rules]:
            parts = LABEL_PARTS.match(label)
            if not parts or parts.group("name") not in ("Check", "External check"):
                continue
            text_of_rule = next((r.text for r in rules if r.label == label), "")
            if not name_re.search(text_of_rule):
                add(line_no, "K-check-bare",
                    f"{label} names no rule — a check whose failure nobody can state (council read 8)")

    # a vocabulary category listing one name twice: the template ships with a
    # repeating defect and every spec inherits it (council read 16)
    for name, k in declared_terms(text).items():
        if name not in {"record verbs", "terms"}:
            continue
        body = TERM_DECL.match(lines[k - 1]).group(2)
        seen_here: dict[str, int] = {}
        for piece in re.split(r"[;,]", CODE_SPAN.sub(" ", body)):
            w = piece.strip().strip(".").strip()
            if not w or " " in w and name == "record verbs":
                continue
            seen_here[w] = seen_here.get(w, 0) + 1
        dupes = sorted(w for w, n in seen_here.items() if n > 1 and w)
        if dupes:
            add(k, "V-dup-vocab",
                f"`Term {name}` lists {', '.join(dupes)} twice (Closed vocabulary 1)")

    # declared terms nothing uses (advisory)
    for name, k in declared_terms(text).items():
        if name in VOCABULARY_CATEGORIES:
            continue  # the vocabulary's own categories (Closed vocabulary 1, Closed vocabulary 2)
        pat = re.escape(name)
        # a declaration that mentions its own name is not a use of it
        elsewhere = "\n".join(x for j, x in enumerate(lines, start=1) if j != k)
        uses = len(re.findall(pat, elsewhere))
        if uses < 1:
            add(k, "W-term-unused", f"`Term {name}` is declared and used nowhere")
    return findings


def main(argv: list[str]) -> int:
    args = [a for a in argv[1:] if not a.startswith("--")]
    gate = "--gate" in argv
    root = Path(__file__).resolve().parents[2]
    if args:
        paths = [Path(a) for a in args]
    else:
        paths = [root / "GRACE-lang.md"]
        for d in ("atoms", "compositions"):
            for p in sorted((root / d).glob("*.md")):
                # a spec declares itself migrated; a stray fence is not a claim
                if MIGRATED.search(p.read_text(encoding="utf-8")):
                    paths.append(p)
    findings: list[Finding] = []
    for p in paths:
        if p.exists():
            findings += scan(p)
    findings.sort(key=lambda f: (str(f.path), f.line, f.code))
    for f in findings:
        try:
            rel = f.path.resolve().relative_to(root)
        except ValueError:
            rel = f.path
        tag = " (advisory)" if f.code in ADVISORY else ""
        print(f"{rel}:{f.line}: [{f.code}]{tag} {f.message}")
    gating = [f for f in findings if f.code not in ADVISORY]
    advisory = [f for f in findings if f.code in ADVISORY]
    print(f"\n— {len(paths)} file(s); {len(gating)} finding(s) + {len(advisory)} advisory.", file=sys.stderr)
    return 1 if (gate and gating) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

---
title: What the checker enforces
nav_order: 4
---

# What the checker enforces

GRACE-lang.md has 22 rules that say the parser MUST reject something: the checker gates 12 of them, gates 5 in part, and only counts 5. This page was generated on 2026-11-14 from the grammar and the checker's own codes; its date moves only when a row does. Nothing on it is hand-written.

Each row is one rule of the grammar, in its own words, the check that holds it, and one of three states:

- **gates** — a finding fails the public Lint run: `check.py --gate` runs in that workflow beside the linter, so a finding of a gating `check.py` code, or of a `lint.py` code, turns the run red.
- **gates in part** — one reading of the sentence gates, and another is read by nothing that gates; what slips through is listed under the table.
- **only counted** — the check is advisory or the normalizer's: it is read and counted, and no run fails on it. This is the list of what is still owed.

| Rule | The grammar says | Held by | State |
|---|---|---|---|
| Surface 19 | The parser MUST reject a fenced block that carries a labelled rule under a first line that opens no normative block and no surface. | `check.py` F-fence-first | gates |
| Hard invariant 1 | The parser MUST reject an unprefixed line in a normative block that does not parse. | `check.py` F-unlabelled, `check.py` F-fence-first | gates |
| Hard invariant 2 | The parser MUST reject a normative rule with no explicit subject. | `normalize.py` N-unlowered | only counted |
| Hard invariant 3 | The parser MUST reject a normative rule with no explicit modal where the statement shape requires one. | `check.py` R-no-modal | gates |
| Hard invariant 4 | The parser MUST reject a normative rule carrying a pronoun. | `check.py` P-pronoun, `check.py` W-demonstrative | gates in part |
| Hard invariant 5 | The parser MUST reject a normative sentence carrying two obligations. | `check.py` W-two-obligations | only counted |
| Hard invariant 6 | The parser MUST reject a nested WHEN block. | `check.py` R-nested-when | gates |
| Hard invariant 7 | The parser MUST reject a condition mixing `AND` and `OR`. | `check.py` V-mixed | gates |
| Hard invariant 8 | The parser MUST reject `OR` outside a condition or a term declaration. | `check.py` V-or-obligation | gates |
| Hard invariant 9 | The parser MUST reject `BEFORE` outside `MUST NOT`. | `check.py` B-before | gates in part |
| Hard invariant 10 | The parser MUST reject `AFTER` outside `ONLY AFTER` or the deterministic sugar. | `check.py` B-after | gates in part |
| Hard invariant 11 | The parser MUST reject a positive `MUST … BEFORE` ordering. | `check.py` B-before | gates in part |
| Hard invariant 13 | The parser MUST reject a cross-rule reference by ordinal. | `normalize.py` N-ordinal-ref | only counted |
| Hard invariant 14 | The parser MUST reject a value used with EQUALS or DOES NOT EQUAL that is not blank and belongs to no declared closed value set. | `normalize.py` N-value-set | only counted |
| Hard invariant 35 | The parser MUST reject an arithmetic operator in a definition outside the operator's own pair of parentheses. | `check.py` A-decl-arith | gates |
| Hard invariant 36 | The parser MUST reject a division outside a definition. | `check.py` A-arith, `check.py` D-rule-symbol, `check.py` A-decl-arith | gates in part |
| Hard invariant 37 | The parser MUST reject a division whose definition names no rounding. | `check.py` A-decl-arith | gates |
| Hard invariant 30 | The parser MUST reject a range citation whose last number does not follow the first number. | `lint.py` F-range-form | gates |
| Hard invariant 31 | The parser MUST reject a run of labels written in a form other than the range citation. | `lint.py` F-range-form | gates |
| Hard invariant 32 | The parser MUST reject `NOT EXISTS`. | `check.py` D-condition-form | gates |
| Hard invariant 34 | The parser MUST reject `NOT EXCEEDS`. | `check.py` D-condition-form | gates |
| Value set 2 | The parser MUST reject an undeclared value. | `normalize.py` N-value-set | only counted |

## What slips through

- **Hard invariant 4** — *it*, *its*, *itself*, *they*, *their*, *them*, *he*, *she*, *his* and *her* gate; *these* and *those* alone are only counted, and *this* and *that* are not read.
- **Hard invariant 9** — Only a `MUST` or `MAY` rule's `BEFORE` is read; a `BEFORE` under `IS AUTHORITATIVE FOR`, or in a condition, is not.
- **Hard invariant 10** — Only an `AFTER` under `MUST NOT` is read; an `AFTER` in a condition is not, and a lower-case one is only counted.
- **Hard invariant 11** — The pattern stops at a full stop, so a label or step number (`step 0.1a`) before the `BEFORE` hides it.
- **Hard invariant 36** — A `/` in a rule, and a division inside a parenthesized group, gate; a bare `÷` in a rule is read by nothing.

Nothing is gated and nothing is retired by this page: it is the list of what is owed.

The checks themselves are run by [Verify It Yourself](./verify.md); the grammar is [GRACE-lang](../how/GRACE-lang.md).

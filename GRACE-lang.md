# GRACE lang v0.67 — Minimal Earned Grammar

Grace lang is a controlled semantic metalanguage for domain specifications. Grace UX is abstracted microcopy and interaction behavior derived from verified logical state.

NOTE: self-classification — this document obeys itself: fences classify by first line (Surface 18), everything outside fences and `Term` lines carries nothing (Surface 3), and this document's own vocabulary is Section 13's.

---

### 1. Core Principles

```
Principle 1: The grammar MUST contain only forms earned by repeated use in real specifications.
Principle 2: The lock list MAY admit a form ONLY IF the form's concept recurs across specifications AND the concept satisfies contested.
Principle 3: The lock list MUST NOT admit a form on one occurrence.
Principle 4: The grammar MAY admit sugar.
Principle 5: The grammar MUST NOT admit inference.
Principle 6: Complexity MUST live in the number and arrangement of simple rules.
Principle 7: Complexity MUST NOT live in the grammar of one rule.
Principle 8: The maintainer MUST decide EVERY admission under Principle 2.
Principle 9: A specification MUST declare the specification's domain meaning.
Principle 10: A specification MUST NOT declare grammar meaning.
Principle 11: A writer MUST declare a meaning locally ONLY IF the domain forces the declaration.
Principle 12: The corpus MUST NOT carry a retired form outside a historical record.
Principle 13: A code span MAY name a retired form.
Principle 14: The maintainer MAY mark a retirement closed ONLY IF no use of the retired form EXISTS outside the historical records.
```

Term contested: the concept's free-prose expression drifted, was read two ways, OR produced a finding.

Term maintainer: the human in charge of the corpus; decides admission.

Term corpus: every file the repository tracks — the specifications, this document, the teaching pages, the agent instructions, the format guide, the generated views and the demos.

Term retired form: a notation a rule of this document forbids, or one the Changes section records as replaced.

Term retirement: the change that forbids a form, open from the version that records it until the maintainer marks it closed under Principle 14.

Term historical record: a dated entry on a page whose front matter names Project Log as its parent, a dated entry in the register in `governance.md`, a dated entry in a specification's Decisions section, or a dated entry in this document's Changes section; the undated text around such an entry is not one, and neither is an open Ledger line, which is live work.

WHY:
The test is the concept, not the token; recurrence alone admits noise (*Measure the form, not the word*, `pressure-testing.md`). The council advises and never admits; its process is `governance.md`'s, not the grammar's. *Notation is law*: a retired form survives nowhere a reader learns it, because a half-done retirement is itself the defect. Local specs declare domain meaning; a spec that restates a grammar-owned concept adds a second owner for something it does not own.

---

### 2. Surfaces

Term surface: normative | `WHY:` | `UX:` | `PROVISIONAL:` | `NOTE:` | nothing (a line outside every fenced block and outside a `Term` declaration).

```
Surface 1: EVERY line MUST belong to exactly one surface.
Surface 2: The parser MUST read an unprefixed line in a normative block as normative.
Surface 3: The parser MUST NOT read a line outside a normative block as normative.
Surface 4: EVERY normative line MUST parse.
Surface 5: A normative line MUST state `WHAT`.
Surface 6: WHY: MUST NOT create, satisfy or alter an obligation, an enumeration or a reverse-diff result.
Surface 7: A reader MUST NOT infer a normative line from WHY:.
Surface 8: A human or a language model MAY generate WHY: from a normative line.
Surface 9: A writer MAY regenerate or discard WHY: at any time.
Surface 10: UX: MUST NOT create behavior absent from every normative line.
Surface 11: UX: MUST NOT alter normative meaning.
Surface 12: A reader MUST NOT infer a normative line from UX:.
Surface 13: A writer MAY write UX: warm, explanatory or context-specific.
Surface 14: A provisional form MUST NOT carry normative force.
Surface 15: The parser MUST ignore WHY:, UX:, NOTE: and PROVISIONAL: lines.
Surface 16: A system MUST obey EVERY normative line.
Surface 17: A system MUST NOT obey WHY:, UX: or NOTE:.
Surface 18: The parser MUST classify a bare fence by the block's first line: a labelled rule opens a normative block; a tombstone opens a normative block; a surface prefix opens that surface; a signature opens a signature block.
Surface 19: The parser MUST reject a fenced block that carries a labelled rule under a first line that opens no normative block and no surface.
Surface 20: The parser MUST read a signature block as a declaration.
Surface 21: The parser MUST read EVERY other fenced block as the surface nothing.
Surface 22: A surface prefix on a block's first line MUST cover every line of the block.
Surface 23: A surface prefix on a later line of a normative block MUST cover that line alone.
Surface 24: The parser MUST read a line outside every fenced block and outside every declaration as the surface nothing.
Surface 25: The parser MUST read a term entry as the surface nothing.
Surface 26: The parser MUST resolve a bracket marker to the declaration the marker names.
Surface 27: A term entry MUST NOT carry an obligation.
Surface 28: A writer MUST write EVERY block the parser classifies in a bare fence.
Surface 29: A rule MUST name another specification by the specification's name alone.
Surface 30: A writer MUST NOT write a name the specification declares in a code span.
```

Term normative block: a fenced block of labelled rules, a `Term` declaration, or a signature block — a spec's whole normative surface (the entry *The normative surface* in `spec-format.md`).

Term code span: text between backticks outside a fence; it quotes literal text — a code spelling, an expression, a file name, a wire token on a `Projection:` line, a form quoted as a form — and never marks a name, which a reader knows by its declaration rather than by its type.

Term bare fence: a fenced block whose opening line carries no info string — the one fence kind a normative block, a surface block and a signature block take; a block's first line, not its fence, says which it is.

Term term entry: a Terms registry entry — a heading, prose and a `Kind` line — the reader's copy of a declaration (the entry *A term entry is the reader's copy* in `spec-format.md`).

Term bracket marker: `[Name]` in prose or in a rule, naming an action or a term the specification declares, and the link line that lands it on the name's term entry; a pointer to the declaration, never a second copy of the declaration. Another specification is named without brackets — a rule sits in a fence, where a link does not render, so `[Permissions](./permissions.md)` there reads as a bracket marker with nothing to resolve to.

Term signature block: a bare fence whose first line is a signature, in the signature form, one signature per action and one or more per block; each signature is the declaration of that action's outcomes, read as the value set the action's rules land on.

Term normative: unprefixed Strict Caveman (Section 20) inside a normative block, other than a tombstone.

Term run: one execution of a system.

Term conformance failure: a run that violates a rule.

Term obey: a system obeys a rule when every run of the system satisfies the rule's obligation under the rule's condition; a run that does not is a conformance failure, decided from records by the spec's acceptance checks (Generation acceptance: `spec-format.md`); an inequality rule (Timing 9) obliges the party that binds the terms; a rule whose subject is not an agent is a constraint on the writer.

Term MAY rule: a rule under MAY; a system satisfies a MAY rule vacuously, and a MAY rule obliges nothing.

```
NOTE: a fragment, not a rule — no label, no actor, no modal; the tail alone:
      close intent ONLY AFTER hold_bound
```

```
WHY:
The sweep waits for the longer of two possible holders, so an intent record is never closed mid-write by another invocation.
```

```
UX:
We are still checking whether this action completed.
Please do not submit it again yet.
```

```
PROVISIONAL:
open_invocations IS DERIVED FROM journal.
```

Term hold_bound: max(completion_bound, closure_latency + journal_write_bound).

NOTE: hold_bound is the example's term; a function such as max has no place in an arithmetic expression, so the arithmetic lives in the declaration, never in the rule (Closed vocabulary 9).

---

### 3. WHAT / WHY / HOW

NOTE: Normative = WHAT; WHY = WHY; UX = HOW. Only the normative line binds a system (Surface 16, Surface 17); WHY and UX are downstream and disposable.

---

### 4. Direction of Generation

```
Direction 1: A writer MAY generate WHY: from a normative line.
Direction 2: A writer MAY generate UX: from a normative line.
Direction 3: A writer MUST NOT generate a normative line from WHY:.
Direction 4: A writer MUST NOT generate a normative line from UX:.
Direction 5: A drafter MAY use fuzzy intent while drafting.
Direction 6: A written normative rule MUST stand alone and pass every check this grammar declares.
Direction 7: A writer MUST NOT keep fuzzy intent as a source of truth.
```

---

### 5. Core Rule Shape

Term statement shape: subject modal verb object | subject modal verb object tail | `IF condition THEN statement` | `WHEN condition:` followed by statements | quantifier subject modal verb object | `subject IS AUTHORITATIVE FOR proposition`.

Term object: a declared identifier, or an enumeration introduced by EXACTLY ONE OF naming the outcomes among which exactly one holds.

Term label: the name of the heading the rule sits under, in the heading's own words, singular, three words at most, then the rule's number under that name — `Principle 1`, `Non-goal 4`, retention_policy 2; under a heading that carries its own number, that number, a dot and the rule's number — `Invariant 2.3`, `record_action step 3.2`; a WHEN child adds a lower-case letter — `Take 2a`; unique within a spec.

Term rule form: `LABEL: statement` on one line, or `LABEL: WHEN condition:` followed by indented child rules each in rule form.

Term child: a rule inside a WHEN block.

```
Rule shape 1: EVERY rule MUST carry a label.
Rule shape 2: EVERY statement MUST match one statement shape.
Rule shape 3: A normative sentence MUST carry exactly one obligation.
Rule shape 4: A writer MUST write a copula enumeration as a value-set declaration.
Rule shape 5: A writer MUST NOT write a copula enumeration as a rule.
Rule shape 6: EVERY rule MUST match the rule form.
Rule shape 7: A label MUST name the heading the label sits under.
Rule shape 8: A label MUST NOT carry an abbreviation.
```

NOTE: a copula enumeration is *X is one of a, b, c*.

WHY:
A label is read by people before a parser: *Non-goal 4* says where to look, *NG4* says nothing. Never mint an acronym (`naming.md`).

#### Standard label families

Term standard label family: Identity (what identifies a record) | State (what the spec holds) | Operation (one action's rules) | Invariant (a property of every reachable state) | Check (an acceptance check) | External check (a check needing evidence the records do not carry) | Non-goal (what the spec does not do, and who owns it instead) | Composition note (an obligation on a composing pattern) | Composes (a constituent's role) | Capability requirement (what the deployment supplies) | Wiring decision (the decision a composition exists to make, and the wiring the decision rejects) | Audit arm (how a composition maps the audit substrate's rejection taxonomy at the composition's own boundary) | Reconciliation (the leg running outside every invocation whose output something awaits within a promised window) | Housekeeping (the leg running outside every invocation whose output nothing awaits) | Scope vocabulary (the scopes a composition defines for its Permissions instance, and which action each gates) | Verdict (how a verification read resolves the evidence it reads into its answer) | Retention asymmetry (how a spec answers where a record outlives the audit events that attest it).

```
Standard label 1: The grammar IS AUTHORITATIVE FOR the standard label families.
Standard label 2: A specification MUST NOT redeclare a standard label family.
Standard label 3: A label family outside the standard set MUST carry the meaning of the heading the family names.
Standard label 4: A label family three specifications name MUST stand as a promotion candidate.
Standard label 5: The lock list MUST NOT promote a label family two specifications name.
Standard label 6: The maintainer MUST decide EVERY promotion.
Standard label 7: A promotion MUST rest on a drift pass finding the candidate's specifications carrying one concept.
Standard label 8: A promotion MUST declare the promoted family's meaning EXACTLY ONE time.
Standard label 9: A promoted family MUST take the family's position PER the section titled Heading standard in `spec-format.md`.
Standard label 10: The grammar MUST NOT rank a standard label family beside the family's position.
Standard label 11: A specification MAY omit a standard label family ONLY IF the section titled Heading standard in `spec-format.md` does not require the family's heading.
Standard label 12: A specification carrying two standard label families MUST order the families PER the section titled Heading standard in `spec-format.md`.
```

NOTE: the promotion census is `tools/grace/cites.py --drift`'s, checked by `lint.py`'s `W-stale-census`; this NOTE carries no counts of its own, and standing as a candidate is not being promoted (Principle 8, restated by Standard label 6).

WHY:
Standard label 4 through 8 are the promotion path; the threshold is a count because the grammar carries no `≥`. Standard label 7 is the gate that matters: three names prove recurrence and nothing about meaning — the drift pass separates *the same word* from *the same concept*. Standard label 9 and 10 settle position from the dependence order a spec's sections already follow; Standard label 11 and 12 let an instrument read a spec's shape without a spec declaring it. A family carries meaning the rule's own words leave out, and declaring the families once here makes that meaning owned rather than conventional (Principle 9 through 11).

#### Casing tiers

Term reserved token: a modal, a quantifier, a condition operator, a tail, IF, THEN, WHEN, IS AUTHORITATIVE FOR, one of the reserved grammar verbs, a surface prefix, or a diff result — each declared elsewhere in this document and cited here (Closed vocabulary 15).

Term casing tier: upper case | title case | sentence case | lower case.

Term domain identifier: a record verb, a value-set member, a field name or an action name — a name the specification declares rather than the grammar.

```
Casing 1: The grammar IS AUTHORITATIVE FOR the casing tiers.
Casing 2: EVERY reserved token MUST carry upper case.
Casing 3: The parser MUST NOT read a lower-case token as a reserved token.
Casing 4: EVERY bracket marker MUST carry title case.
Casing 5: EVERY domain identifier MUST carry lower case.
Casing 6: The parser MUST read a token's tier from the token's case.
```

WHY:
The tiers were already in force and declared nowhere, which is why the cheap tier checks work at all: lower case is the tell. Casing 3 is the load-bearing one — a lower-case `and` is English and carries no operator, so prose stays legal and the drift becomes visible without a new prohibition. A family's casing is not this section's to set (Rule shape 7 owns it) but the tier set must contain sentence case, or Casing 6 has no tier for the corpus's commonest family casing; families named as compound identifiers are Casing 5 winning, not exceptions. Casing 6 is what the tiers buy: a parser classifies by shape before lookup. The census that admitted this and the drift numbers are `cites.py --drift`'s.

---

### 6. Earned Vocabulary

Term quantifier: EVERY | EXACTLY ONE | EXACTLY ONE OF (an exclusive choice among named outcomes).

Term modal: MUST | MUST NOT | MAY.

Term condition operator: EQUALS | DOES NOT EQUAL | EXISTS | IS IN | IS NOT IN | EXCEEDS | DOES NOT EXCEED | PRECEDES | DOES NOT PRECEDE | AND (flat) | OR (flat, inclusive).

Term blank: a value that is absent, empty, or carries only whitespace — a caller's input, a stored field or a deployment setting that holds nothing.

Term absence form: `no thing EXISTS`, with `for` and the identifier where one names the thing — the one way a condition says a record, an event or a condition is not there.

Term rule symbol: a character a rule's own text does not carry — the section sign, the arrow, a brace, the bar, an angle bracket, the en dash, the slash, the asterisk, save the slash and the asterisk as arithmetic operators inside an arithmetic expression; a section is *the section titled X*, a map entry *k mapped to v*, a call's answer *answering x*, a record *carrying a, b and c*, a range of steps *steps 2 through 5*, and a code spelling such as a template sits in a code span.

Term arithmetic operator: `+` | `-` | `*` | `/` — addition, subtraction, multiplication and division, with their usual meaning and precedence: `*` and `/` apply before `+` and `-`, and operators of one precedence apply from left to right.

Term operand: a declared field, a declared term or a number inside an arithmetic expression.

Term arithmetic expression: operands joined by arithmetic operators, a space on each side of every operator, inside one pair of parentheses in a rule, as in `balance set to (balance - input)`.

Term rule noun: a noun the rules of every specification share, declared once here — call, answer, write, input, field, instant, act, clock, instance, section.

Term call: one invocation of an action, carrying the inputs the caller supplied.

Term answer: what an action returns to a call — one arm of the action's signature.

Term write: one change a system makes to a database.

Term input: a value a call supplies to an action, named in the action's signature.

Term field: a named part of a record.

Term instant: a point in time, as the clock a specification reads gives it.

Term act: something an actor or a pattern does that its records account for — a commit, a suspension, a purge; the specification's own declarations say which.

Term clock: a source of instants — the deployment's, read at a specification's seam, or one an auditor supplies.

Term instance: one deployed copy of a pattern, or of a database a pattern is routed to.

Term section: a titled part of a document, cited as *the section titled X*.

```
Earned vocabulary 1: A condition MUST NOT mix `AND` and `OR`.
Earned vocabulary 2: A writer MUST route a mixed condition through a declared term.
Earned vocabulary 3: A rule MUST NOT carry `OR` in an obligation or between obligations.
Earned vocabulary 4: A writer MUST write an exclusive choice as `EXACTLY ONE OF`.
Earned vocabulary 5: A condition MUST NOT nest.
Earned vocabulary 6: A writer MUST write a thing's absence in the absence form.
Earned vocabulary 7: A writer MUST write a missing value as `value EQUALS blank`.
Earned vocabulary 8: A writer MUST NOT write EXISTS with a value as the subject.
Earned vocabulary 9: A writer MUST write membership in a set as `value IS IN set`.
Earned vocabulary 10: A writer MUST write a value outside a set as `value IS NOT IN set`.
Earned vocabulary 11: A writer MUST write a field a write sets as `field set to value`.
Earned vocabulary 12: A writer MUST NOT write `=` in a rule.
Earned vocabulary 13: A specification MUST NOT write a `Term` declaration for a rule noun.
Earned vocabulary 14: A writer MUST write a rule noun under the rule noun's own name.
Earned vocabulary 15: A writer MUST write a test of a record's state as a value test, `the record's state EQUALS member`.
Earned vocabulary 16: A writer MUST NOT write a rule symbol in a rule outside a code span and outside an arithmetic expression.
Earned vocabulary 17: A writer MUST write the negative of EXCEEDS as DOES NOT EXCEED.
Earned vocabulary 18: A writer MUST compare two instants with PRECEDES.
Earned vocabulary 19: A writer MUST write the negative of PRECEDES as DOES NOT PRECEDE.
Earned vocabulary 20: A writer MUST NOT compare two instants with EXCEEDS.
```

WHY:
One operator, one sense: EXISTS asks whether a thing is there, EQUALS blank whether a value is missing, IS IN whether a value belongs to a set. The operators are English words so a rule read aloud says what it means. `=` and `|` stay only where a value set is declared. The rule nouns are the grammar's for the reason blank is: every spec's rules lean on them, so a declaration in each spec would redeclare a constituent's term (Closed vocabulary 17); words a spec declares for itself stay the spec's. Renamed second senses (*argument*, State Machine's *instance*, Party Identity's *identifier*, Audit Trail's *tail*, bare *section* beside *critical section*) are history, in the Changes section.

---

### 7. Earned Tails

Term tail: `ONLY AFTER term` | `ONLY IF condition` | `WITHIN term` | `PER term` | `BEFORE term` (under MUST NOT only, Timing 5).

```
Tail 1: A reader MUST NOT infer beyond a tail's text.
```

WHY:
ONLY IF is admitted by Principle 2: the concept recurs, and the repair finding is the contested half. `ONLY UNDER` is provisional (Section 18): no controlled use, no finding.

```
NOTE:
/people MAY serve actor ONLY IF invite_actor EXISTS OR grant_permission EXISTS.
```

---

### 8. Timing and Bounds

```
Timing 1: A writer MUST write a positive lower-bound ordering as `actor MUST action ONLY AFTER term`.
Timing 2: The parser MUST normalize `actor MUST action AFTER term` to `actor MUST action ONLY AFTER term`.
Timing 3: The parser MUST normalize `actor MAY action AFTER term` to `actor MAY action ONLY AFTER term`.
Timing 4: A writer MUST NOT write `AFTER` under `MUST NOT`.
Timing 5: A writer MUST write a forbidden-before ordering as `actor MUST NOT action BEFORE term`.
Timing 6: A writer MUST NOT write positive `MUST … BEFORE`.
Timing 7: A writer MUST write a deadline as `IF measure EXCEEDS bound THEN actor MUST NOT action`.
Timing 8: A writer MUST write a completion window as `actor MUST action WITHIN bound`.
Timing 9: A writer MUST write ≥ as `term MUST NOT EXCEED term`.
Timing 10: A writer MUST NOT write `AT LEAST`.
Timing 11: A writer MUST NOT write `STRICTLY`.
Timing 12: A writer MUST write a strict lower bound as `actor MAY action ONLY IF term EXCEEDS term`.
Timing 13: A reader MUST NOT infer timing from rule order.
```

WHY:
`run_floor MUST NOT EXCEED run_bound` means `run_bound ≥ run_floor`. Timing 12 is no new form — a permission gated on a condition. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim; liveness goes through WITHIN.

---

### 9. WHEN Blocks

```
WHEN block 1: The parser MUST read EVERY child of a WHEN block as an independent rule.
WHEN block 2: A reader MUST NOT infer ordering among the children of a WHEN block.
WHEN block 3: A WHEN block MUST NOT nest.
```

```
NOTE:
WHEN condition:
    statement
    statement
    ...
```

---

### 10. Authority

```
Authority 1: A writer MUST write authority as `subject IS AUTHORITATIVE FOR proposition`.
Authority 2: A synonym MUST NOT carry authority semantics.
Authority 3: Two rules MUST NOT claim authority for one proposition.
Authority 4: The parser MUST treat two propositions as one proposition ONLY IF the propositions normalize identically (Reverse diff 3).
Authority 5: A citing spec MUST name the owner.
Authority 6: A citing spec MUST NOT restate the rule.
```

WHY:
No synonym carries authority semantics. Authority 3 reads *two rules*, covering both altitudes — a proposition owned twice across specs and one owned twice inside one, the common case. A spec pays for a proposition once; deleting the first copy breaks Hard invariant 16, which makes the rule mechanical. IS AUTHORITATIVE FOR is an introduced form, not a discovered one, and the grammar's one labelled exception to Principle 1.

---

### 11. Hard Invariants (parser-enforced)

```
Hard invariant 1: The parser MUST reject an unprefixed line in a normative block that does not parse.
Hard invariant 2: The parser MUST reject a normative rule with no explicit subject.
Hard invariant 3: The parser MUST reject a normative rule with no explicit modal where the statement shape requires one.
Hard invariant 4: The parser MUST reject a normative rule carrying a pronoun.
Hard invariant 5: The parser MUST reject a normative sentence carrying two obligations.
Hard invariant 6: The parser MUST reject a nested WHEN block.
Hard invariant 7: The parser MUST reject a condition mixing `AND` and `OR`.
Hard invariant 8: The parser MUST reject `OR` outside a condition or a term declaration.
Hard invariant 9: The parser MUST reject `BEFORE` outside `MUST NOT`.
Hard invariant 10: The parser MUST reject `AFTER` outside `ONLY AFTER` or the deterministic sugar.
Hard invariant 11: The parser MUST reject a positive `MUST … BEFORE` ordering.
Hard invariant 12: The parser MUST resolve a cross-rule reference by label.
Hard invariant 13: The parser MUST reject a cross-rule reference by ordinal.
Hard invariant 14: The parser MUST reject a value used with EQUALS or DOES NOT EQUAL that is not blank and belongs to no declared closed value set.
Hard invariant 15: The parser MUST NOT infer from rule order.
Hard invariant 16: The parser MUST NOT infer from the absence of a rule.
Hard invariant 17: The parser MUST NOT infer exclusivity among outcomes unless `EXACTLY ONE OF` states the exclusivity.
Hard invariant 18: The parser MUST normalize sugar without adding meaning.
Hard invariant 19: The parser MUST normalize EVERY sugar form to exactly one canonical form.
Hard invariant 20: The parser MUST NOT infer missing semantics.
Hard invariant 21: The parser MUST NOT give WHY: normative force.
Hard invariant 22: The parser MUST NOT give UX: normative force.
Hard invariant 23: The parser MUST NOT infer normative meaning from WHY: or UX:.
Hard invariant 24: The parser MUST reject arithmetic in a rule outside one pair of parentheses.
Hard invariant 25: The parser MUST reserve the label a tombstone carries.
Hard invariant 26: A writer MUST NOT renumber an invariant.
Hard invariant 27: A writer MUST NOT reuse a tombstoned label.
Hard invariant 28: A cross-spec reference in a normative block MUST name the spec before the label — `Lease Operation 2`, `Audit Trail Invariant 1.2`.
Hard invariant 29: The parser MUST read a range citation as a cross-rule reference to EVERY label of the cited family from the first number through the last number.
Hard invariant 30: The parser MUST reject a range citation whose last number does not follow the first number.
Hard invariant 31: The parser MUST reject a run of labels written in a form other than the range citation.
Hard invariant 32: The parser MUST reject `NOT EXISTS`.
Hard invariant 33: The parser MUST read `no thing EXISTS` as the thing's absence.
Hard invariant 34: The parser MUST reject `NOT EXCEEDS`.
```

Term pronoun: it | its | itself | they | their | them | he | she | his | her, and this, that, these, those standing alone — the set Hard invariant 4 rejects and `tools/grace/check.py` enforces; a relative whose, that or which opening a clause is not a pronoun.

Term tombstone: a line inside a normative block in the form `Deleted: Label. The owner, and why.` — the label, a period, one space, and a sentence ending with a period; it reserves the label (Hard invariant 25, Hard invariant 27), carries no obligation, and is recognized by that form alone.

Term range citation: a run of labels of one family written as the first label, the word through and the last number — `Operation 3 through 7`, `Invariant 2.1 through 2.4`, `reconcile step 5.2 through 5.4`; a cross-spec range names the spec first (Hard invariant 28); the family is written once and singular, the last number carries the first number's shape, and both ends are included.

WHY:
Section 11 is the parser's contract; the writer-facing rules that mirror it oblige a different actor, and the two are kept as two norms on purpose. A cross-reference survives a version because labels never move and never collide across specs. A range citation says one thing four spellings used to say; *through* includes both ends in plain English, so the range reads the way it resolves, and `tools/grace/cites.py` counts it.

---

### 12. Sugar Rule

```
Sugar 1: Sugar MAY shorten a rule.
Sugar 2: Sugar MUST NOT add information.
Sugar 3: A writer MUST NOT place a sentence that matches no admitted form and no deterministic sugar in a normative block.
Sugar 4: A rule MAY carry an arithmetic expression.
Sugar 5: An arithmetic expression MUST NOT nest.
Sugar 6: An arithmetic expression MUST NOT read a clock.
Sugar 7: An arithmetic expression MUST NOT carry a call.
Sugar 8: An arithmetic expression MUST NOT write.
Sugar 9: A writer MUST declare a quantity the domain names as a term.
Sugar 10: The parser MUST normalize EVERY arithmetic expression to an unnamed term.
```

NOTE: inline arithmetic is the grammar's one symbolic sugar: the parser reads each arithmetic expression as an unnamed term, so the sugar adds no meaning (Sugar 2, Hard invariant 18, Hard invariant 19). A quantity the domain names keeps its term, as Session's expiry deadline does (`issued_at + session_duration`); inline is for nameless intermediates.

```
NOTE: the sugar and its normalization.
NOTE: sweep MUST run AFTER examine_edge.
```

```
NOTE: sweep MUST run ONLY AFTER examine_edge.
```

```
NOTE: PER and a cadence, exercised once; the examples in this document borrow Recoverable Invocation's vocabulary and are exemplars, not citations — Hard invariant 28 does not reach a NOTE:.
NOTE: sweep MUST examine PER reconciliation_cadence.
```

---

### 13. Closed Vocabulary

```
Closed vocabulary 1: EVERY specification MUST declare the specification's own closed vocabulary.
Closed vocabulary 2: A vocabulary MUST carry EVERY category the specification uses, from the category value set.
Closed vocabulary 3: A vocabulary MUST declare a category with no member as empty.
Closed vocabulary 4: EVERY normative identifier MUST resolve to a declaration.
Closed vocabulary 5: The parser MUST NOT infer a term's type from the term's name.
Closed vocabulary 6: A specification MUST declare record verbs explicitly.
Closed vocabulary 7: A record MUST NOT acquire behavior from the record's noun.
Closed vocabulary 8: A rule carrying a modal MUST carry a declared record verb or a reserved grammar verb after the modal.
Closed vocabulary 9: A rule MUST name a term where the rule needs arithmetic that one pair of parentheses cannot carry.
Closed vocabulary 10: A writer MUST write a declaration in the declaration form.
Closed vocabulary 11: A definition MAY carry arithmetic, comparison operators, a value set, or a sentence saying what the name is.
Closed vocabulary 12: A writer MUST write a definitional sentence as a declaration.
Closed vocabulary 13: A writer MUST write a value set in the value-set form.
Closed vocabulary 14: A writer MUST NOT write a definitional sentence as a rule.
Closed vocabulary 15: A declaration MAY cite the declaration's owner instead of restating the definition.
Closed vocabulary 16: The parser MUST resolve a cited declaration against the owner's Terms registry, migrated or not.
Closed vocabulary 17: A specification MUST NOT redeclare a constituent's term.
Closed vocabulary 18: A specification MUST NOT declare `EXCEED` or `IS AUTHORITATIVE FOR` as record verbs.
Closed vocabulary 19: The parser MUST resolve an inflected form of a declared record verb to the declared form.
Closed vocabulary 20: A specification MUST declare EVERY action's outcomes in a signature block.
Closed vocabulary 21: The parser MUST read a signature block, together with the family answers of Closed vocabulary 30, as the value set of the action's outcomes.
Closed vocabulary 22: A rule MUST NOT land an outcome absent from the action's signature block and from the family answers of Closed vocabulary 30.
Closed vocabulary 23: The parser MUST NOT infer order from an answers line's arms.
Closed vocabulary 24: A writer MUST write a signature in the signature form.
Closed vocabulary 25: The parser MUST read the arms of an answers line as the action's answers.
Closed vocabulary 26: The parser MUST read the arms of a refuses line as the action's refusals.
Closed vocabulary 27: A writer MUST declare a record an action answers as a term.
Closed vocabulary 28: The parser MUST keep the order of a refuses line's arms.
Closed vocabulary 29: The parser MUST read a rule whose subject takes in several actions as binding each such action only where the action's signature block, together with the family answers of Closed vocabulary 30, carries the outcome the rule lands.
Closed vocabulary 30: The parser MUST read an action's outcomes as the action's signature block together with the answers the Execution Contract's families give EVERY action, Read 1's `state-unavailable` included, counting each family answer as written under Value set 3.
```

Term category: actor | record | record verb | value set | bound | cadence | term | qualifier | cited | composing pattern.

Term declaration form: `Term name: definition.` on one line — the name runs from `Term ` to the first colon and carries no colon and no backtick, one space follows the colon, and the definition ends with a period.

Term value-set form: member names separated by `|`.

Term signature form: three lines — `name(input, input, optional input)`; then an answers line, two spaces and answers and the arms; then, where the action refuses anything, a refuses line, two spaces and refuses and the arms, listed in the order the refusals answer (Execution Contract Refusal 1). An input is a declared name, and optional marks one the caller may omit. Arms are separated by `|`; an arm is a declared name, followed by the names it carries in parentheses where it carries any, and never holds another arm. A blank line separates two signatures.

Term name: a spec's name is the spec's file stem, case preserved; this document's is `GRACE-lang` (the title spaces it for reading).

Term definitional sentence: *X is Y*, *X counts Z*, *the key is (kind, act_key)* — a sentence with no modal.

Term reserved grammar verbs: EXCEED (in MUST NOT EXCEED), PRECEDE (in DOES NOT PRECEDE) and IS AUTHORITATIVE FOR carry grammar semantics; a specification never declares them as record verbs. Every other verb in a rule is a record verb the specification declares.

Term identifier: a subject, an object, a term name or a value in a rule; every identifier resolves to a declaration (Closed vocabulary 4).

Term actor: a declared identifier that may serve as a rule's subject.

Term agent: an actor that can perform a rule's verb — the grammar; the lock list; the parser; a specification; a citing spec; an owner; a system; a reader; a writer; a drafter; a human; a language model; the reverse diff; a maintainer; a party. A rule whose subject is an actor and not an agent constrains the writer (obey).

WHY:
A named expression has one owner, and a diff can match it by name. Closed vocabulary 8 is what rejects the passive — no declared record verb after the modal. A citation form lets a composition use a constituent's term without restating it.

```
NOTE:
record verb record_action: Audit Trail
```

#### This document's own vocabulary

Term actors: (every subject in this document, agent or not) the grammar; the lock list (Section 21); the parser; a specification (a spec); a rule; a statement; a sentence (a rule's text); a condition; a form; a sugar form; a term; a declaration; a WHEN block; a tail; a surface; a system; a reader; a writer; a drafter; a human; a language model; the reverse diff; the normalized form (the representation); fuzzy intent; a value set; a value; an enumeration; a synonym; a citing spec; an owner (the spec that declares a term); a registry (a spec's Terms section); `WHY:`; `UX:`; `NOTE:`; `PROVISIONAL:`; sugar; complexity; arithmetic; an arithmetic expression; a label; an obligation; a proposition; an invariant; a tombstone; an ordinal; a pronoun; a line; a fenced block; a party; a run; a maintainer; a child; a category; an actor; an agent; the corpus; a code span.

Term record verbs: decide, contain, admit, recur, satisfy, live, state, read, parse, create, alter, infer, generate, regenerate, discard, write, obey, ignore, carry, use, stand, pass, route, mix, nest, normalize, name, restate, resolve, cite, declare, acquire, redeclare, renumber, reuse, enumerate, reject, lower, report, treat, assume, keep, express, mark, shorten, add, accept, supply, earn, belong, cover, classify, claim, qualify, give, match, place, bind, reserve, compare, land, promote, rest, take, rank, omit, order.

Term qualifiers: ratified — accepted into Section 21 by Principle 2; migrated — rewritten in this language, declared by the spec's own qualifiers line as `migrated — rewritten in GRACE lang vN (date)`, which is how a tool tells a migrated spec from an unmigrated one without guessing from a fence.

Term records: empty.

Term bounds: empty.

Term cadences: empty.

Term terms: contested, hold_bound, run_floor and the bounds the examples compute over — completion_bound, closure_latency, journal_write_bound, borrowed from Recoverable Invocation and exemplars here, never citations (Hard invariant 28 does not reach an example) — and every other name declared in this document — a comprehension over the document's `Term` lines, determinate by construction.

Term value sets: surface; quantifier, modal, condition operator; tail; diff result — ADDED | REMOVED | CHANGED; category (declared once, at `Term category`; cited here by Closed vocabulary 15).

---

### 14. Closed Value Sets

```
Value set 1: A value set MUST enumerate every admitted value.
Value set 2: The parser MUST reject an undeclared value.
Value set 3: A value set MUST NOT carry an implicit other.
```

---

### 15. Canonical Examples

```
NOTE: exemplars in Recoverable Invocation's vocabulary, not citations; the labels are illustrative.
Canonical example 1:
IF commit EQUALS unknown THEN invocation MUST yield.

Canonical example 2:
EVERY writer MAY write outcome ONLY IF section_lease EXISTS.

Canonical example 3:
operator MUST NOT resolve BEFORE acquiring section.

Canonical example 4:
sweep MUST reconcile AFTER examine_edge.
```

```
NOTE: Canonical example 4 normalizes to `ONLY AFTER`.
Canonical example 5:
IF intent_age EXCEEDS retention_edge THEN sweep MUST NOT examine intent.

Canonical example 6:
run_floor MUST NOT EXCEED run_bound.
```

Term run_floor: `max(completion_bound, closure_latency + journal_write_bound) + closure_latency` — Recoverable Invocation's declaration, borrowed with the name.

---

### 16. Normalized Form

```
Normalized form 1: The parser MUST lower EVERY parsed rule to an explicit structural representation.
Normalized form 2: The representation MUST carry only information present in the normative source or added by a ratified deterministic sugar rewrite.
Normalized form 3: The representation MUST NOT carry information from WHY:, UX:, NOTE:, PROVISIONAL: or context.
```

---

### 17. Reverse Diff

```
Reverse diff 1: The reverse diff MUST compare normalized normative obligations.
Reverse diff 2: The reverse diff MUST report ADDED, REMOVED and CHANGED.
Reverse diff 3: The reverse diff MUST treat two forms that normalize identically as equivalent.
Reverse diff 4: The reverse diff MUST NOT assume equivalence otherwise.
Reverse diff 5: The reverse diff MUST NOT report a change to WHY: or UX:.
```

---

### 18. Candidate Forms

```
Candidate form 1: The parser MUST treat a form as provisional until the lock list admits the form.
Candidate form 2: A spec MUST state a degraded rule in admitted forms under IF or WHEN.
Candidate form 3: A spec MUST mark a `DEGRADES TO` pairing PROVISIONAL:.
```

```
PROVISIONAL: ONLY UNDER
PROVISIONAL: IS DERIVED FROM
PROVISIONAL: COMPOSES / BINDS
PROVISIONAL: positive MUST … BEFORE
PROVISIONAL: <strong rule> DEGRADES TO <weak rule>
PROVISIONAL: a code span inside a rule quotes text — the grammar's own meta-rules (Timing 1 through 12, Earned vocabulary 1 through 4, Hard invariant 7 through 11, Authority 1, Closed vocabulary 18) mention the tokens they govern
```

WHY:
`DEGRADES TO` is a pairing slot: the condition stays on the strong rule's ONLY IF, so the pairing adds no third rule and the reverse diff sees only the two rules. The signature block was admitted on recurrence across specs and a parse-error finding; the release-and-reject idiom was withdrawn the same day, and its withdrawal stands on Principle 2 — two sites in one specification are not recurrence. A claim of absence later found false was corrected in the Changes section rather than quietly repaired: a grammar that misreports its own corpus is the one document that cannot afford to.

#### Watch list: repeated cures, counted until stated once

NOTE: repeated cures are flagged (`NOTE: watch <name>` beside the strained rule) and counted here per specification until stated once; at five specifications the maintainer rules once whether the Execution Contract or this document states it. Departed names, their council reads and superseded counts: [the grammar's history](./GRACE-lang.hist.md). Flag first, count recurrence, admit nothing until the corpus forces it (Principle 1 through 3). A line's count is the specifications carrying its flag, or the count of the tool the line names; `lint.py`'s `W-stale-census` checks the label-family counts on every run.

- **host obligations**: what the host must bound — cap, deployment-supplied, or silence. Thirteen specifications: Actor Identity, Approval Step, Cart, Invitation, Legal Hold, Medication Order, Notification, Observation, Party Identity, Provisional Commitment, Selective Disclosure, State Machine and Tamper Evidence; the *host obligations* row in `open-questions.md` holds the question.
- **the state a refusal leaves**: a refused write binding record state read alone; the open question is whether refusal answers on a record in another state or none. Three: Consent (Operation 32), Invitation (Operation 37) and Provisional Commitment (Operation 30).
- **condition negation**: guards a plain negative cannot carry; the open question is one refusal answering in two rows of one precedence chain. Three: Approval Step, Audit Trail and State Machine.
- **applicability**: `WHERE`-shaped gating written with subject or relative clause. Two: Audit Trail and Recoverable Invocation.
- **persistent state**: `WHILE`-shaped duration written with a term or phrase. One: Audit Trail.
- **cardinality**: a need beyond EVERY, EXISTS, EXACTLY ONE and EXACTLY ONE OF. One: Audit Trail.
- **satisfaction**: what a violation of WITHIN is, compensate or nonconform. One: Audit Trail.
- **addressable sections**: a rule naming a section, where the grammar labels rules and nothing labels a section. One: Recoverable Invocation.
- **position scoping**: every rule of a family scoped by a condition on position. One: Recoverable Invocation.
- **negative capability**: an obligation to discard a reply already in hand. One: Recoverable Invocation.
- **rule inheritance**: one action's rules restated for another, where the grammar has no inheritance form. One: Recoverable Invocation.
- **event versus state**: where the distinction matters enough that declared terms alone become awkward. None flagged.
- **contradiction**: two rules normalizing to `X MUST a` and `X MUST NOT a` under identical conditions. None found.
- **the wire layer**: a term entry's `Projection:` line and the `Wire: pinned` field, with no naming convention of the layer's own. Fifty-three documents at council read 101; no finding against the layer itself yet.
- **the term entry grammar**: a term entry's fields drifting per document on the nothing surface. Nine at council read 12; the superset recurs in every migrated specification.
- **a term entry's kind**: `Kind: Field` carrying stored, derived and pinned values alike. Two: Cart and Retention Window.
- **the cited line**: the `Term cited:` line written in two shapes this document never states, runs of names each closed by the owner, or a document and what it supplies. Eighteen specifications: four write the first shape, sixteen the second, two both.
- **the frozen surface's edge**: which families a cross-spec citation freezes. None standing since council read 13.
- **the degenerate bound**: an inequality or bound whose two readings make different rules real. Five: Lease (two), Duplicate Prevention, Retention Window and Provenance.
- **the auditor's vocabulary**: the verbs a Generation acceptance section needs, richer than an atom's own rules use, with nothing owning the split. Not counted.
- **a label family recurring across specs outside the standard set**: a concept the corpus keeps declaring by heading: `Clock semantics` (24), `Clock dependence` (7), `Concurrency` (25), `String` (15), `Atomic writes` (4), `Indeterminate outcome` (10), `Expiry` (4), `Instance` (3), `Action wiring` (25), `Correction` (2), `Durability` (1), `Instance start` (2), `Primitive policy` (24), `Composition state` (24), `Verification caching` (2). The counts are `tools/grace/cites.py --drift`'s, and `lint.py`'s `W-stale-census` compares them with the corpus on every run.
- **the comparator written in English**: *past*, *longer than*, *more than* etc. in a rule (`check.py`'s `W-comparator`). Thirty-nine sites in nine specifications: Recoverable Invocation 19, Audit Trail 11, Consent 3, and one each in Lease, Message Preference, Notification, Permissions, Session and Subscription.
- **the unadmitted modal**: *can*, *could*, *would*, *should* inside a rule's subordinate clause (`check.py`'s `W-modal`). Nine sites in three specifications: Recoverable Invocation 6, Capability 2 and Audit Trail 1.
- **who gates a write**: two postures on one question with nothing declaring the fork — attribution on every write, or the identifier as the whole authorization. Two: Legal Hold requires attribution on every write, and Message Preference accepts the identifier as the whole authorization.
- **the modifier class**: a declared noun under an undeclared modifier, with nothing saying whether a modifier owes a declaration (`tools/grace/nouns.py`). 4,211 of 20,841 noun phrases at council read 105.
- **read-order polarity**: a history surface answering reads in no stated order. Two postures: every history surface answers a read in ascending order, and Invitation's `Operation 41` answers its matching invitations in no stated order.
- **the side-channel qualifier**: a value riding beside an outcome on its own channel, which may not fold into a reason, promote to an outcome or be carried by not-known. One: Audit Trail's `(compensation-window)`.
- **the modal with no temporal scope**: MUST saying *always* and *eventually* in one breath, so one labelled rule carries a safety claim and a liveness claim. One measured instance: Provisional Commitment's draft `Invariant 2.3`.
- **the window reading**: a two-member value set reading a deadline against now with the boundary instant on the lapsed side, declared by each specification for itself. Three: Provisional Commitment (`open` | `lapsed`), Invitation and Credential (`live` | `lapsed`); both halves of Principle 2 are satisfied.
- **the outcome that carries a value**: a signature arm carrying a value inside or beside the outcome, which Closed vocabulary 21 parses as one opaque token. Two: Invitation's `already-resolved(stored terminal)` and Audit Trail's `(compensation-window)`.
- **the wire surface**: the places a name keeps its code spelling, which no rule enumerates. Nine instances across four sweeps; a finding against the set itself is still missing.
- **the external answer that moves**: a verification reading a source the atom does not own, whose answer can change between two calls while the binding and consistency invariants were written as if it could not. Two: Actor Identity (Invariant 2.1, 3.1 and 7.1, Check 3.1 and 3.2) and Tamper Evidence (Invariant 3.1 and 7.1).
- **the host's state**: a rule keeping a verification from *the host's state* beside a verification set closed with *and nothing else* that takes in a value the host injects. Two: Actor Identity (Invariant 6.2) and Tamper Evidence (Invariant 4.2).
- **the lost answer**: an action whose answer never reaches its caller, so the caller cannot tell whether the call landed — an arm the Execution Contract's Error model does not name. Ten specifications: Approval Step, Audit Trail, Cart, Credential, Event Log, Execute Gated Workflow, Medication Order, Notification Fanout, Party Identity and Verified Repair.
- **the fresh holder value**: a composing pattern stating for itself that each take of a Lease carries a holder value no earlier take on the key carried, which Lease Identity 6 asks of every caller and Lease Composition note 5a makes the composing pattern's to own. Four: Audit Trail (Per-act critical section 1c, Concurrency 1f), Defensible Retention (Concurrency 11), Recoverable Invocation (Term operator run id, Term run id) and Resolve a Person's Data Rights (Concurrency 4).
- **the computation at the seam**: a rule deciding on a cryptographic computation, which the core may not run (Execution Contract Logic confinement 1), so each specification declares the value as computed at the seam and injected. Four: Actor Identity (Term cryptographic material), Idempotent Reservation (Term parameters digest), Reserve from Pool (Term parameters digest) and Tamper Evidence (Term cryptographic material).
- **the blank id**: a not-known rule held off a blank identifier, so a blank id answers its blank-input refusal ahead of not-known though the refuses line lists not-known first. Three: Legal Hold (Operation 13), Medication Order (Operation 12) and Party Identity (Operation 12).
- **the range's ends**: a read's range filter with nothing saying whether its ends lie inside it or how two filters combine, so one query answers two sets in two builds. Two: Event Log (Term query) and Legal Hold (Term query); the question stands open on Consent, Observation, Party Identity, Provenance and State Machine.
- **the instant left blank**: a caller's optional instant resolved from the injected now when the call leaves it blank, a rule each specification writes for itself. Three: Consent (Operation 21, Operation 38), Legal Hold (Operation 9, Operation 18a) and Medication Order (Operation 4).

---

### 19. Language Growth

```
NOTE:
real need
→ repeated use
→ stable wording
→ pressure testing
→ canonical form
→ parser support
→ normalized form
→ linter support
→ corpus sweep
→ gating
```

---

### 20. Strict Caveman

Term Strict Caveman: short sentences; one obligation per sentence; explicit subject, modal, action and object; explicit condition when needed; one canonical term for one meaning; no pronouns; no rhetorical dependency; no hidden implication.

```
Caveman 1: A writer MUST express complex behavior as more simple rules.
Caveman 2: A writer MUST NOT express complex behavior as a more complicated sentence.
```

---

### 21. What the grammar locks

Term locked forms: Strict Caveman normative prose; WHAT / WHY / HOW separation; `WHY:` and `UX:` with zero normative force; MUST / MUST NOT / MAY; EVERY / EXACTLY ONE / EXACTLY ONE OF; flat IF and flat WHEN; flat AND, flat OR, never both in one condition; OR only inside conditions and term declarations; EQUALS / DOES NOT EQUAL / EXISTS / the absence form / IS IN / IS NOT IN / EXCEEDS; blank; `=` and `|` only in a value set; ONLY AFTER / ONLY IF / WITHIN / PER; MUST NOT EXCEED for ≥, no AT LEAST, no STRICTLY; the strict lower bound as `MAY … ONLY IF … EXCEEDS …`; IS AUTHORITATIVE FOR (introduced, labelled); one site is one spec; forbidden-before (`MUST NOT … BEFORE`); deterministic AFTER sugar under MUST and MAY; positive `MUST … BEFORE` illegal; one obligation per sentence; labels named for their heading, never abbreviated; closed vocabulary including record verbs; the `Term` declaration form; the signature block as a declaration form, one line per action; the standard label families; the casing tiers; the term entry and the bracket marker as reader sugar; a declaration may cite its owner; arithmetic in term declarations, and in a rule only as an arithmetic expression, `+`, `-`, `*` and `/` inside one pair of parentheses, never nested; closed value sets; no pronouns, Section 13 rejects the passive; no inference; normalized representation; reverse diff over normalized rules; admission by Principle 2 — recurrence AND contested.

```
Lock 1: The parser MUST accept only the locked forms and the locked forms' deterministic sugar.
Lock 2: The lock list MUST NOT admit a form outside the locked forms except by Principle 2.
```

---

### 22. Core Rules

NOTE: recap only — every claim here is owned by a rule elsewhere; read the sections above. Strict Caveman grows slowly. Grace itself can grow enormously.

---

### 23. Changes

NOTE: the version history is archived — [the grammar's history](./GRACE-lang.hist.md) and git history (`git log -- GRACE-lang.md`, last commit before the relabel `e80fd21`); open retirements are recorded per Term retirement.

NOTE: End of GRACE-lang. We love you. 🖤

# GRACE lang v0.62 — Minimal Earned Grammar

## Grace lang is a controlled semantic metalanguage for domain specifications.

## NOTE: Grace UX is abstracted microcopy and interaction behavior derived from verified logical state.

Status: the current version and its history are §23; this line states nothing else.
Date: 2026-09-16

NOTE:
This document obeys itself. A fenced block is classified by its first line (Surface 18): a labelled rule or a tombstone opens a normative block, a surface prefix opens that surface, a signature opens a signature block, and any other block is the surface nothing — unless it carries a labelled rule, which is a parse error. Everything outside the fences and the `Term` lines carries nothing (Surface 3); `WHY:` and `NOTE:` label it for readers. The vocabulary the document's own rules use is declared in §13.

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
```

Term contested: the concept's free-prose expression drifted, was read two ways, OR produced a finding.

Term maintainer: the human in charge of the corpus; decides admission.

WHY:
The test is the concept, not the token: a token appears only after its form is admitted, so counting tokens is circular. Recurrence alone admits noise. Counts follow `pressure-testing.md` §*Measure the form, not the word*. Surface 5 owns *states WHAT*. The reviewers a draft is run past — the council — advise and never admit; who they are and how a read is cited is the corpus's internal process, kept out of the grammar (`governance.md` §*The language council*).

*Local specs declare domain meaning, not GRACE meaning* (Principle 9 through 11). Explicit never meant repeating a globally-known fact in every file: the grammar owns the label families, the categories, the outcome shapes and the timing concepts, and a spec that restates one of them has added a second owner for something it does not own. A spec declares the domain — the nouns, the verbs, the value sets, the signatures, and the local exception the domain forces. The substrate gets richer as the specs get smaller (council read 8).

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

Term normative block: a fenced block of labelled rules, a `Term` declaration, or a signature block — a spec's whole normative surface (`spec-format.md` §*The normative surface*).

Term code span: text between backticks outside a fence; it quotes literal text — a code spelling, an expression, a file name, a wire token on a `Projection:` line, a form quoted as a form — and never marks a name, which a reader knows by its declaration rather than by its type.

Term bare fence: a fenced block whose opening line carries no info string — the one fence kind a normative block, a surface block and a signature block take; a block's first line, not its fence, says which it is.

Term term entry: a Terms registry entry — a heading, prose and a `Kind` line — the reader's copy of a declaration (`spec-format.md` §*Terms*).

Term bracket marker: `[Name]` in prose or in a rule, naming an action or a term the specification declares, and the link line that lands it on the name's term entry; a pointer to the declaration, never a second copy of the declaration. Another specification is named without brackets — a rule sits in a fence, where a link does not render, so `[Permissions](./permissions.md)` there reads as a bracket marker with nothing to resolve to.

Term signature block: a bare fence whose first line is a signature, in the signature form, one signature per action and one or more per block; each signature is the declaration of that action's outcomes, read as the value set the action's rules land on.

Term normative: unprefixed Strict Caveman (§20) inside a normative block, other than a tombstone.

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

NOTE: hold_bound is the example's term; the arithmetic lives in the declaration, never in the rule (Hard invariant 24).

---

### 3. WHAT / WHY / HOW

```
NOTE:
Normative = WHAT
WHY       = WHY
UX        = HOW
```

WHY:
Only the normative line carries meaning the system must obey (Surface 16, Surface 17). WHY and UX are downstream and disposable.

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

```
NOTE:
Normative → WHY     (allowed)
Normative → UX      (allowed)

WHY  ↛ Normative    (forbidden)
UX   ↛ Normative    (forbidden)
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

NOTE:
The promotion census is `tools/grace/cites.py --drift`'s and §18's family clause is where it is written down; `lint.py`'s `W-stale-census` compares it against the corpus on every run (council read 33, council read 52). **This NOTE carries no counts of its own** — a first draft did, and a second hand-maintained census is the defect the census discipline exists to prevent, caught here by `W-stale-census` reporting one family twice (council read 58). Standing as a candidate is not being promoted; Principle 8 governs, and Standard label 6 restates it here because a promotion is an admission.

WHY:
Standard label 4 through 8 are the promotion path, and the threshold is stated as a count rather than as a comparison because the grammar carries no `≥`: three names a candidate, two forbids one, and the two rules together say what one inequality would (the open docket row on that operator is why). Standard label 7 is the gate that matters — a name reaching three specifications proves recurrence and proves nothing about meaning, and a family promoted while its three specs mean three things would put the grammar's authority behind a collision. The drift pass is what separates *the same word* from *the same concept* before the grammar owns the word.

Standard label 9 and Standard label 10 settle position without inventing a second ordering. A promoted family takes the place `spec-format.md` already gives it in the dependence order a spec's sections follow; there is no importance ranking, because a family's place in the tree is the only ranking the corpus has ever needed. Standard label 11 keeps presence optional, and Standard label 12 makes the order checkable wherever two families are present, which is the pair that lets an instrument read a spec's shape without a spec declaring it.

A family carries meaning the rule's own words leave out — *Non-goal 3: The host MUST admit waiters in arrival order* is a positive obligation, and the scope that makes it a non-goal lives in the label (council read 8). Declaring the families once here is what makes that meaning owned rather than conventional, and Principle 9 through 11 is why the declaration is here and not in every spec.


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
The tiers were already in force in every migrated document and declared nowhere, which is why the cheap instruments work at all: lower case is the tell. `W-or-word`, `W-watch-word` and `W-modal` each find a reserved concept written in the wrong tier, and they cost a regex because the right tier is upper case and nothing else is.

Casing 3 is the load-bearing one, and it is a reading rule rather than a prohibition. A lower-case `and` is English and carries no operator, so an object list — *the scope and the allocator_ref* — stays legal prose; a condition the writer meant as AND and wrote in lower case is simply not a condition, and the shape checks then report it as one that does not parse. Forbidding the word would break the prose; refusing to read it as an operator makes the drift visible without a new prohibition.

A label family's casing is not this section's to *set* — but the tier set must *contain* it, or Casing 6 has no tier to read for the corpus's commonest family casing and Value set 3's ban on an implicit other bites. sentence case is the fourth member for that reason, added at council read 27 after a three-member set shipped against a census that had already counted 104 sentence-case families. Which tier a family takes stays Rule shape 7's: it already says a label names the heading the label sits under, in the heading's own words, so the casing follows the heading and needs no second owner — which the census confirms: 104 of the 105 families named in words are sentence case, matching their headings. The 62 families named `event_to_attestation`, `seal_coverage`, `retention_policy` and the like are not exceptions to a tier, they are Casing 5 winning: the name *is* a declared term, the lower case is part of the identifier, and title-casing it would break the reference. A first draft of this section claimed an initial capital for label families and bracket markers together, which put Casing 4 and Casing 5 in conflict at those 62 sites; council read 25 applied the pressure and the census settled it.

Casing 6 is what the tiers buy: a parser classifies a token by shape before it looks anything up, so the closed vocabulary is consulted to resolve a name rather than to decide what kind of thing the name is. Closed vocabulary 18 already forbids declaring two specific reserved tokens as record verbs; the tiers generalize that from a list of two to a property of the case.

The census that admitted this: 471 lower-case reserved tokens inside normative rules across the migrated corpus — 277 of them in the two pilot compositions, 38 in this document. The drift is the contested half of Principle 2; the nineteen documents already obeying the tiers are the recurrence half (council read 24).

---

### 6. Earned Vocabulary

Term quantifier: EVERY | EXACTLY ONE | EXACTLY ONE OF (an exclusive choice among named outcomes).

Term modal: MUST | MUST NOT | MAY.

Term condition operator: EQUALS | DOES NOT EQUAL | EXISTS | IS IN | IS NOT IN | EXCEEDS | DOES NOT EXCEED | PRECEDES | DOES NOT PRECEDE | AND (flat) | OR (flat, inclusive).

Term blank: a value that is absent, empty, or carries only whitespace — a caller's input, a stored field or a deployment setting that holds nothing.

Term absence form: `no thing EXISTS`, with `for` and the identifier where one names the thing — the one way a condition says a record, an event or a condition is not there.

Term rule symbol: a character a rule's own text does not carry — the section sign, the arrow, a brace, the bar, an angle bracket, the en dash, the slash, the asterisk; a section is *the section titled X*, a map entry *k mapped to v*, a call's answer *answering x*, a record *carrying a, b and c*, a range of steps *steps 2 through 5*, and a code spelling such as a template sits in a code span.

Term rule noun: a noun the rules of every specification share, declared once here — call, answer, write, input, field, instant, act, clock, instance, section.

Term call: one invocation of an action, carrying the inputs the caller supplied.

Term answer: what an action returns to a call — one arm of the action's signature.

Term write: one change a system makes to a store.

Term input: a value a call supplies to an action, named in the action's signature.

Term field: a named part of a record.

Term instant: a point in time, as the clock a specification reads gives it.

Term act: something an actor or a pattern does that its records account for — a commit, a suspension, a purge; the specification's own declarations say which.

Term clock: a source of instants — the deployment's, read at a specification's seam, or one an auditor supplies.

Term instance: one deployed copy of a pattern, or of a store a pattern is routed to.

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
Earned vocabulary 16: A writer MUST NOT write a rule symbol in a rule outside a code span.
Earned vocabulary 17: A writer MUST write the negative of EXCEEDS as DOES NOT EXCEED.

Earned vocabulary 18: A writer MUST compare two instants with PRECEDES, and MUST NOT compare two instants with EXCEEDS.

Earned vocabulary 19: A writer MUST write the negative of PRECEDES as DOES NOT PRECEDE.
```

WHY:
One operator, one sense. EXISTS asks whether a thing is there — a stored record, an event, a condition — and nothing else; EQUALS blank asks whether a value is missing; IS IN asks whether a value belongs to a set, a record's state among them. Before v0.52 one operator carried all three and more, and `step_id NOT EXISTS` (the caller sent nothing) and `the assignment_id NOT EXISTS` (no record carries the id) differed by an article. The operators are English words so that a rule read aloud, by a person or by a screen reader, says what it means: `!=` comes out as *exclamation equals* or as nothing at all. `no` stays lower case — it is the English determiner, beside `a` and `an`, and EXISTS is the token. `=` and `|` stay only where a value set is declared (Term value-set form). A record's state is one of those values, so a condition tests it with EQUALS and IS IN like any other (Earned vocabulary 15); *stand* stays the verb of the write that moves it — `MUST stand the party in verified`.

The rule nouns are the grammar's for the reason blank is: every specification's rules say *call*, *answer*, *write*, *input*, *field* and *instant*, and almost none declared them, so a noun the rules leaned on hardest resolved to nothing. Earned vocabulary 14 is why *argument* is gone: it named the same thing as *input*, which the signature form already used. *Instance* and *section* joined at v0.60, each once its own second sense was gone: State Machine's running record became a workflow at council read 108, and the host-supplied lock became a critical section at council read 111. *Act* joined them at v0.58: eleven specifications say it in their rules, each for its own thing done, and four of them compose Audit Trail, whose rules say it too — so a declaration in each would have redeclared a constituent's term with another meaning (Closed vocabulary 17). *Clock* joined them at v0.59, the word *instant*'s own declaration already leaned on. *Composition* is not among them, and the reason is new: eleven specifications declare it of themselves, so taking the word would outlaw their declarations under Earned vocabulary 13. A word a specification declares for itself is the specification's. State Machine once declared an instance as one workflow while the other specifications meant one deployed copy of a pattern; State Machine's sense is *workflow* since council read 108, and *instance* waits to be measured in its one remaining sense before it is declared. Party Identity once declared *identifier* as every opaque name it assigns, the word this document declares for any name a rule uses; that sense is *assigned id* since council read 109. Audit Trail once declared *tail* as the highest sequence number a read returns, the word this document declares for ONLY AFTER, ONLY IF, WITHIN, PER and BEFORE; that sense is *tail position* since council read 110. *Section* is not a rule noun yet either. Eleven specifications also used it for a critical section, the host-supplied mutual exclusion, beside its sense of a titled part of a document; since council read 111 that sense is always written *critical section*, and bare *section* waits to be measured for its one declaration.

---

### 7. Earned Tails

Term tail: `ONLY AFTER term` | `ONLY IF condition` | `WITHIN term` | `PER term` | `BEFORE term` (under MUST NOT only, Timing 5).

```
Tail 1: A reader MUST NOT infer beyond a tail's text.
```

WHY:
ONLY IF is admitted by Principle 2: the concept recurs, and gate 12 F1's repair is the finding. `ONLY UNDER` is provisional (§18): no controlled use, no finding.

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
`run_floor MUST NOT EXCEED run_bound` means `run_bound ≥ run_floor`. Timing 12 is no new form — a permission gated on a condition; `instance MAY start ONLY IF compensation_window EXCEEDS worst_closure`. A prohibition past an instant is Timing 7, which is why Timing 4 admits no AFTER under MUST NOT. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim; liveness goes through WITHIN.

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
No synonym — `canonical`, `source of truth`, `primary` — carries authority semantics. Authority 3 reads *two rules* rather than *two specs*, which covers both altitudes: a proposition owned twice across two specs, and a proposition owned twice inside one. The second is the common case and was unowned until council read 26 counted it — 46 pairs in one atom, seven of them the same sentence under two labels (`State 1` and `Invariant 2.1`, `State 22` and `Non-goal 20`). A spec pays for a proposition once: deleting the second copy costs nothing, and deleting the first breaks Hard invariant 16, which is what makes the rule mechanical rather than a matter of taste. A site is one spec (`pressure-testing.md` §*One site is one spec*). IS AUTHORITATIVE FOR is an introduced form, not a discovered one: the concept is earned (three consecutive gates; DRY on responsibility depends on it), the phrasing was minted 2026-09-10 in Recoverable Invocation and propagated only after use. It is the grammar's one labelled exception to Principle 1.

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
Hard invariant 24: The parser MUST reject arithmetic in a rule.
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
§11 is the parser's contract; the writer-facing rules that mirror it (Rule shape 3, WHEN block 3, Earned vocabulary 1, Sugar 2, Timing 4, Timing 6) oblige a different actor, and the two are kept as two norms on purpose. A cross-reference survives a version because labels never move (Hard invariant 26, Hard invariant 27) and never collide across specs (Hard invariant 28): Recoverable Invocation's `Allowance 2` and this document's `Rule shape 2` are cited as `Recoverable Invocation Allowance 2` and `GRACE-lang Rule shape 2`.

A range citation says one thing four spellings used to say: `Operation 3–7` carried a dash no keyboard types, `Operation 3 through Operation 7` wrote the family twice and left room for the second to differ, `Operations 3–7` made the family two strings, and `Operation 3 to 7` does not say whether 7 is in. *Through* includes both ends in plain English, so the range reads the way it resolves (Hard invariant 29): a change to `Operation 5` reopens every text that cites `Operation 3 through 7`, which `tools/grace/cites.py` now counts. A range whose last number does not follow its first cites one label or none, and says neither (Hard invariant 30) — two specifications carried `Capability requirement 2–2` until the conversion found it.

---

### 12. Sugar Rule

```
Sugar 1: Sugar MAY shorten a rule.
Sugar 2: Sugar MUST NOT add information.
Sugar 3: A writer MUST NOT place a sentence that matches no admitted form and no deterministic sugar in a normative block.
```

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
Closed vocabulary 9: A rule MUST name a term where the rule needs arithmetic.
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
Closed vocabulary 21: The parser MUST read a signature block as the value set of the action's outcomes.
Closed vocabulary 22: A rule MUST NOT land an outcome absent from the action's signature block.
Closed vocabulary 23: The parser MUST NOT infer order from a signature block's arms.
Closed vocabulary 24: A writer MUST write a signature in the signature form.
Closed vocabulary 25: The parser MUST read the arms of an answers line as the action's answers.
Closed vocabulary 26: The parser MUST read the arms of a refuses line as the action's refusals.
Closed vocabulary 27: A writer MUST declare a record an action answers as a term.
```

Term category: actor | record | record verb | value set | bound | cadence | term | qualifier | cited | composing pattern.

Term declaration form: `Term name: definition.` on one line — the name runs from `Term ` to the first colon and carries no colon and no backtick, one space follows the colon, and the definition ends with a period.

Term value-set form: member names separated by `|`.

Term signature form: three lines — `name(input, input, optional input)`; then an answers line, two spaces and answers and the arms; then, where the action refuses anything, a refuses line, two spaces and refuses and the arms. An input is a declared name, and optional marks one the caller may omit. Arms are separated by `|`; an arm is a declared name, followed by the names it carries in parentheses where it carries any, and never holds another arm. A blank line separates two signatures.

Term name: a spec's name is the spec's file stem, case preserved; this document's is `GRACE-lang` (the title spaces it for reading).

Term definitional sentence: *X is Y*, *X counts Z*, *the key is (kind, act_key)* — a sentence with no modal.

Term reserved grammar verbs: EXCEED (in MUST NOT EXCEED), PRECEDE (in DOES NOT PRECEDE) and IS AUTHORITATIVE FOR carry grammar semantics; a specification never declares them as record verbs. Every other verb in a rule is a record verb the specification declares.

Term identifier: a subject, an object, a term name or a value in a rule; every identifier resolves to a declaration (Closed vocabulary 4).

Term actor: a declared identifier that may serve as a rule's subject.

Term agent: an actor that can perform a rule's verb — the grammar; the lock list; the parser; a specification; a citing spec; an owner; a system; a reader; a writer; a drafter; a human; a language model; the reverse diff; a maintainer; a party. A rule whose subject is an actor and not an agent constrains the writer (obey).

WHY:
A named expression has one owner, and a diff can match it by name. Closed vocabulary 8 is what rejects the passive — *The actor MUST be granted invite_actor* has no declared record verb after the modal — which is why no parser invariant restates the rule. A citation form lets a composition use a constituent's term without restating it.

```
NOTE:
record verb record_action: Audit Trail
```

#### This document's own vocabulary

Term actors: (every subject in this document, agent or not) the grammar; the lock list (§21); the parser; a specification (a spec); a rule; a statement; a sentence (a rule's text); a condition; a form; a sugar form; a term; a declaration; a WHEN block; a tail; a surface; a system; a reader; a writer; a drafter; a human; a language model; the reverse diff; the normalized form (the representation); fuzzy intent; a value set; a value; an enumeration; a synonym; a citing spec; an owner (the spec that declares a term); a registry (a spec's Terms section); `WHY:`; `UX:`; `NOTE:`; `PROVISIONAL:`; sugar; complexity; arithmetic; a label; an obligation; a proposition; an invariant; a tombstone; an ordinal; a pronoun; a line; a fenced block; a party; a run; a maintainer; a child; a category; an actor; an agent.

Term record verbs: decide, contain, admit, recur, satisfy, live, state, read, parse, create, alter, infer, generate, regenerate, discard, write, obey, ignore, carry, use, stand, pass, route, mix, nest, normalize, name, restate, resolve, cite, declare, acquire, redeclare, renumber, reuse, enumerate, reject, lower, report, treat, assume, keep, express, mark, shorten, add, accept, supply, earn, belong, cover, classify, claim, qualify, give, match, place, bind, reserve, compare, land, promote, rest, take, rank, omit, order.

Term qualifiers: ratified — accepted into §21 by Principle 2; migrated — rewritten in this language, declared by the spec's own qualifiers line as `migrated — rewritten in GRACE lang vN (date)`, which is how a tool tells a migrated spec from an unmigrated one without guessing from a fence.

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
`DEGRADES TO` is a pairing slot for a degraded guarantee: the condition stays on the strong rule's ONLY IF, the slot carries none, so the pairing adds no third rule — the reverse diff sees the strong rule and the weak rule, and the `PROVISIONAL:` pairing line is invisible to it (Surface 15). Recoverable Invocation uses it four times, states each weak rule under IF, and marks the pairing provisional — the contested history §1 requires. The signature block was admitted in v0.33 (Surface 20, Closed vocabulary 20 through 22) on twelve sites across two specs and a parse-error finding (council read 7); the release-and-reject idiom was withdrawn the same day — council read 7's splits were believed to have removed every site, and council read 24's sweep found two surviving in Recoverable Invocation's close step 3.7 and close step 3.8, where a modal joins a release to an outcome rather than to a second verb. The withdrawal stands on Principle 2 rather than on absence: two sites in one specification are not recurrence across specifications. The claim of absence was false and is corrected here rather than quietly repaired, because a grammar that misreports its own corpus is the one document that cannot afford to.

---

#### Watch list — pressure the rewrite may find, flagged and counted, not admitted

NOTE:
During the corpus rewrite, no grammar is added preemptively. A rewriter flags recurring pressure at the site, as `NOTE: watch <pressure>` beside the rule that strained, and recurrence is the count of flags across specs. Most of these are expected to collapse into declared domain terms rather than new grammar. Watched: persistent state (cases that want `WHILE`); applicability (cases that want `WHERE`, or feature-present gating); cardinality (needs beyond EVERY, EXISTS, EXACTLY ONE, EXACTLY ONE OF); condition negation (where DOES NOT EQUAL, the absence form, IS NOT IN and MUST NOT are not enough); event versus state (where the distinction matters enough that terms alone become awkward); contradiction (two rules normalizing to `X MUST a` and `X MUST NOT a` under identical conditions — nearly free to detect after normalization, and waiting for its finding); satisfaction (where obey is not enough: what a violation of WITHIN is, compensate or nonconform); addressable sections (a rule that names a section as subject or object — Recoverable Invocation's journal_fence 2, Allowance 2, Instance start 1, Which closing stands 1 and Invariant 2.6 make section titles the subjects of authority claims, and this document's value sets line once cited sections by ordinal; the grammar has labels for rules and nothing for sections; `execution-contract.md`'s rules carry labels since council read 124, and 220 specification citations name them, `Execution Contract Logic confinement 7`, while 253 cite a section by its title, which `lint.py`'s `X-section-title` resolves against the file's own headings since council read 126). Also watched, and counted at fifty-three: the wire layer (a term entry's `Projection:` line, named `Projects:` before v0.54 — the one place a lowering token is written down, on the nothing surface — joined by `Wire: pinned`, a second field Personal Todo alone carries; the line was counted in four documents when this entry was written and is in fifty-three at council read 101, the camelCase drift once counted here is gone, three tokens in Multi-Party Approval carry a capital (`M-of-N`), and the layer has no naming convention of its own. Recurrence is satisfied; a finding against the layer itself is not yet, so Principle 2's second half is open. Council read 9, council read 10). Also watched: the frozen surface's edge — a composition freezes an atom's *invariant* numbers by citing them, and the corpus has begun citing other families across specs (a non-goal by number, in Tamper Evidence's WHY before council read 13 removed it). Nothing says which families freeze, and `cites.py --into` counts citations without knowing which carry a contract (council read 13). Also watched, and counted at six: the total read — a query that refuses nothing, because a malformed input has a correct answer rather than an error (Duplicate Prevention's check, Lease's remaining, Actor Identity's verify, Tamper Evidence's verify, Subscription's two queries, which is the first to state the principle, and Invitation's read, which is the first to state it as a rule — `Operation 44: [Read] MUST NOT refuse a filter`). The enumeration and both counts are wrong: a mechanical pass over the migrated corpus returns 21 actions across 17 specs whose signature carries no rejection arm, Consent's `Operation 35` states it as a rule a day before Invitation's, and Permissions and Session state it and are listed nowhere. One shared semantic no spec owns; grammar territory under Principle 9 through 11, with the count moved to `open-questions.md` until a detector draws the class's boundary (council read 12, council read 48). Also watched, and counted at nine: the term entry grammar — `Kind`, `Member of`, `Field of`, `Parameter of`, `Role`, `Projection:`, and now `Wire: pinned`, drifting per document on the nothing surface, with a Field whose values are Members of a value set named by a term. The wire layer the list already counts is a subset of this; the superset recurs in every migrated spec and is contested by its own drift (council read 10, council read 11, council read 12). Also watched, and counted at eighteen: the cited line — the `Term cited:` line of the category Term category admits, which Closed vocabulary 15 and 16 govern, written in two shapes this document never states. Four specifications write runs of names each closed by the owner, `take, expires_at: Lease.`; sixteen cite a document and what it supplies, `` `execution-contract.md` §Logic confinement — the seam ``; two write both. `tools/grace/nouns.py` reads the first shape as declarations since council read 112, and nothing reads the second. A cited name is written bare in a rule, as Closed vocabulary 16 resolves it; Hard invariant 28 qualifies labels, not names (council read 113). Also watched, with a live specimen at last: addressable sections — Subscription's Subscription Id term entry cited a *Configuration* section no atom shape carries, and no instrument reads a section citation (council read 12). Also watched: the degenerate bound — an inequality or a bound whose two readings make different rules real (Lease's `less`, Duplicate Prevention's `window`, Retention Window's deleted Invariant 6.3 and its `degenerate duration`, Lease's arrival-term boundary, Provenance's `sequence_range` with no declared inclusivity): five instances, and the class wants a name before it wants a form (council read 11). Also watched: the auditor's vocabulary — the verbs a Generation acceptance section needs (find, reproduce, compute, reconstruct, confirm) are richer than the verbs an atom's own rules use, and nothing owns the split; the generation run is where an implementer becomes the auditor and this becomes the test language (council read 11). Also watched: a term entry's `Kind` carrying stored, derived and pinned alike — Retention Window's overshoot and active-overdue projections are `Kind: Field` beside stored fields, with only prose telling them apart; if the wire layer is admitted, `Kind` wants a projection member (council read 11). Also watched, and counted: a label family recurring across specs outside the standard set: `Clock semantics` (24), `Clock dependence` (7), `Concurrency` (39), `String` (16), `Atomic writes` (15), `Indeterminate outcome` (6), `Expiry` (4), `Instance` (3), `Action wiring` (25), `Correction` (2), `Durability` (2), `Instance start` (2), `Primitive policy` (23), `Composition state` (23), `Verification caching` (2). **The Housekeeping / Reconciliation pair is now standard on both sides, and §5 declares each meaning once (Standard label 8).** The boundary between them is the question the pair was cut on and is worth keeping where a reader meets the counts: *does anything await the leg's output?* A leg nothing awaits is Housekeeping — it may report, it may remove, it may not close anything a promise names, and it owes no closure bound. A leg something awaits is Reconciliation, and the promised window is owed because of it. A further leg joins one of the two by answering that question rather than by resembling a member, which is the mistake the pair's first cut made (council read 64), and the corpus has since used the question to overrule both a leg's inherited name and three sibling compositions (council read 70). A family used in twenty specs is a concept the corpus keeps re-declaring by heading; the standard set is where it would be declared once. These counts are `tools/grace/cites.py --drift`'s, and `lint.py`'s `W-stale-census` compares every one of them against the corpus on each run — they went stale on arrival three reads running while they were hand-copied, which is the same failure the category set had before `check.py` derived it (council read 30, council read 33). Counts so far: Recoverable Invocation flags none yet (the pilot predates the list); Audit Trail flags six — applicability, persistent state, event versus state, cardinality, condition negation, satisfaction; Lease flags none. Lease's two flags were raised by council read 8 and both dissolved the same day, neither into new grammar: temporal quantification (*at every instant*) was redundant once §5 declared what the Invariant family means, and the event in Operation 4's condition (*the arrival term elapses*) was a comparison the admitted operators already carry. A flag is a claim that the grammar is short a form, and a claim that survives a rewrite in admitted forms is the only kind that counts. Also watched, and counted at thirty-eight: the comparator written in English rather than through an admitted operator — *past*, *longer than*, *more than*, *short of*, *at most*, *advance past* — where EXCEEDS, DOES NOT EXCEED, EQUALS, DOES NOT EQUAL, EXISTS, IS IN and IS NOT IN are the whole set a condition may carry. Most route through an admitted operator or a declared term and are repairs rather than pressure; the residue that cannot is the class, and Recoverable Invocation's *block longer than the remaining lease*, at three sites, is the specimen that wants a term the grammar has no form for. Counted alongside it at ten: the unadmitted modal — *can*, *could*, *would*, *should* — every instance so far inside a subordinate clause where a declared term or an EXCEEDS would carry the claim. Both detectors were ported from the sweep parser council read 24 arrived with, which found them where this document's own checker had no rule (`tools/grace/check.py`, `W-comparator` and `W-modal`; twenty-seven of the thirty-eight sit in Recoverable Invocation, and the atoms migrated in v0.35 carry one to four each — the distribution dates the class to before the split discipline matured rather than to the grammar). The fault ontology left this list for the docket at council read 19, on a second instance that disagrees with the first. Still watched, at one instance: who gates a write — Legal Hold requires attribution on every write, Message Preference accepts the identifier as the whole authorization, two postures on one question with nothing declaring the fork (council read 18). Left this list at v0.57, where DOES NOT EXCEED gave both numeric sites the one-arm cure the temporal ones already had (council read 104), and counted at two across two specs before it: the `≥` comparison spelled as a two-arm disjunction — `IF x EXCEEDS y OR x EQUALS y THEN …`, the *same* operand pair in both arms — because the condition operator set carries EXCEEDS and EQUALS and nothing between them. The two are Audit Trail's `Invariant 3.1` (`sealed_through` against an event's `sequence_number`) and Recoverable Invocation's `reconcile step 5.1` (`intent_age` against `at_risk_threshold`). The count is two and not five: this entry said five for one version, because the hand census matched `X EXCEEDS Y OR Y EQUALS none`, which is two propositions and no comparison at all. `check.py`'s `W-ge-disjunction` now decides it by comparing both arms' operands, so the number stops depending on who is reading. The class also splits, and the split is the ruling's real input: a `≥` between *instants* has a one-arm cure — `IF b precedes a THEN` refuses exactly the values `a ≥ b` admits, which is how State Machine's `Operation 20` states its within-instance bound without a disjunction — while a `≥` between *numbers or ordinals* has none, because inverting it inverts the rule's polarity rather than its spelling. Both surviving sites are numeric. So the question is not whether the corpus wants an operator but whether two numeric sites earn one, with the temporal sites already cured (council read 29, council read 31). One further census settles the surface half of it: 24 term entries across 12 specs carry `≥` as reader shorthand, and all but one sit in specs whose rule surface carries no disjunction at all — the symbol is established practice on the nothing surface, where Surface 27 says a term entry carries no obligation, and all but absent from the surface that does. Whatever the ruling decides about the two numeric rules, it decides nothing about the 26. That number was hand-counted twice and wrong twice — once at 36 across a spec count of 30 that was really 19, because the counter read every `####` heading as a term entry and the adversarial-scenario headings are not — so `lint.py`'s `W-stale-census` now decides it, the same cure the family counts took one version earlier (council read 33, council read 34). Also watched, and measured by `tools/grace/nouns.py`: the modifier class — a declared noun under an undeclared modifier, *active*, *constituent*, *recorded* — 4,211 of 20,841 noun phrases at council read 105, a fifth, up from about 18% at council read 100; it is the quietest growing count the noun reader prints, and nothing yet says whether a modifier owes a declaration (council read 106). Absence-as-nonexistence left this list at v0.52: Term blank was declared word for word in twenty-five specs and defined by the operator it stood beside, and the grammar now declares it once (Earned vocabulary 7). Also watched, and counted at six: the query answering with data rather than a tag, which left this list for the docket at council read 14 and is recorded here only so the two counts agree. Also watched, at three postures: read-order polarity — every history surface in the corpus answers a read in ascending order and Soft Delete's answers in descending, because the two serve different questions (a history serves replay, a summary serves *what is the state now*). The ordering encodes the semantic and nothing declares the fork, which is the same shape as the temporal-lower-bound divergence on the docket (council read 34). Invitation is the third posture and the one that makes the fork undeclarable rather than merely undeclared: its `Operation 41` answers every matching invitation and states no order at all, so a caller paging the result gets whatever the store gives twice running (council read 39). Also watched, at one specimen: the create-on-write answer shape — Soft Delete's `Operation 6` forbids [Soft Delete] answering `not-known` at all, because an unknown id is that action's entry point rather than a miss, while [Restore] and [Purge] on the same store do answer it. Every other atom treats `not-known` as one meaning; this one splits it by whether the action creates or resolves, and the answer token set now carries call semantics rather than only outcomes (council read 34). Also watched, at one specimen: the side-channel qualifier — Audit Trail's `(compensation-window)` rides beside an outcome on its own channel, with rules saying it may not fold into a reason, may not promote to an outcome, and may not be carried by `not-known`. It is the WHY/UX surface discipline applied at the API layer, and no category owns the form (council read 29). Also watched, at one measured instance: the modal with no temporal scope — MUST says *always* and *eventually* in the same breath, so a rule can carry a safety claim and a liveness claim at once and no instrument separates them. Provisional Commitment's draft `Invariant 2.3` did, and the formal layer is what caught it: the model checks the safety half and drops the other silently, which makes the spec and its own `.tla` disagree about what one labelled rule means. That is the citation-aim class one layer down — a citation between a rule and a model that resolves and does not aim (council read 38). Also watched, and counted at three: the window reading — Provisional Commitment declares `open` | `lapsed`, Invitation `live` | `lapsed`, Credential `live` | `lapsed` again, all three in the same shape for the same comparison with the boundary instant on the lapsed side. None composes another, so none can cite another's declaration; it is the blank class one layer up, where the shared semantic is a two-member value set rather than a single reading. The third instance also carries the first variation: Credential's deadline is *optional*, so its `live` member covers both *no deadline* and *deadline not reached*, and the spec's own Decisions entry says why a third member would be a distinction no rule consumes. Three is recurrence, and the contested half arrived with it: Invitation's `live` requires a deadline and Credential's `live` admits an absent one, so the corpus now has one name carrying two predicates across two specs migrated a day apart — the same address for a different building, where `open` beside `live` was only two names for one shape. Both halves of Principle 2 are now satisfied for this class (council read 38, council read 40, council read 41). Also watched, and counted at two: the outcome that carries a value — Invitation's `already-resolved(stored terminal)`, where the refusal names which resolution stands and a bare `already-resolved` is declared non-conformant, beside Audit Trail's `(compensation-window)` riding on its own channel. The two differ in where the value sits — inside the outcome, or beside it — and agree on the thing the grammar has no form for: a signature block's arms are names, and `Closed vocabulary 21` reads the block as the value set of the action's outcomes, which leaves a parameterized arm parsing as one opaque token. Both specs then need rules to say what the payload must and must not carry, which is the tell that the form is doing work the grammar is not (council read 38). EXISTS carrying several senses left this list at v0.52, split into EXISTS, EQUALS blank and IS IN (Earned vocabulary 6 through 10; council read 41, council read 99). Also watched, and counted at nine: the wire surface — the places a name keeps its code spelling, which no rule enumerates and which four sweeps have discovered one collision at a time. A term entry's `Projection:` line and a specification's `formal:` provenance line; a code span, which Term code span already names; a signature block; a fenced event schema, which opens `{` (council read 138, found by a sweep rewriting four of Undo History's rows); a braced shape inline on a declaration line, the same surface standing somewhere else (council read 140); a dotted path or a call, `RetentionWindow.purge_eligible`, `data.entry_id`, `place_hold(…)`; the label position, which `Rule shape 7` ties to a heading and every citation freezes; and the parenthetical on a `Term bounds:` line, `audit horizon (audit_trail_retention_policy)`, where the name and its projection sit side by side (council read 144). Each was found by running into it, and the cure twice was to widen the *shape* of the test rather than add an entry to the list — a sweep keeps a fenced block unless it is certainly rule text, a gate fires only where the block is certainly wire. Nine instances across four sweeps is recurrence under Principle 2; what is missing is the other half, a finding against the set itself rather than against each member as it is met. The claim the grammar would make is one sentence — *these are the surfaces on which a name keeps its projection* — and until it makes it, every sweep rediscovers the list and the corpus learns it by damage (council read 143). The rule: flag first, count recurrence, admit nothing until the corpus forces it (Principle 1 through 3).

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

WHY:
One occurrence is never enough (Principle 3).

---

### 20. Strict Caveman

Term Strict Caveman: short sentences; one obligation per sentence; explicit subject, modal, action and object; explicit condition when needed; one canonical term for one meaning; no pronouns; no rhetorical dependency; no hidden implication.

```
Caveman 1: A writer MUST express complex behavior as more simple rules.
Caveman 2: A writer MUST NOT express complex behavior as a more complicated sentence.
```

---

### 21. What the grammar locks

Term locked forms: Strict Caveman normative prose; WHAT / WHY / HOW separation; `WHY:` and `UX:` with zero normative force; MUST / MUST NOT / MAY; EVERY / EXACTLY ONE / EXACTLY ONE OF; flat IF and flat WHEN; flat AND, flat OR, never both in one condition; OR only inside conditions and term declarations; EQUALS / DOES NOT EQUAL / EXISTS / the absence form / IS IN / IS NOT IN / EXCEEDS; blank; `=` and `|` only in a value set; ONLY AFTER / ONLY IF / WITHIN / PER; MUST NOT EXCEED for ≥, no AT LEAST, no STRICTLY; the strict lower bound as `MAY … ONLY IF … EXCEEDS …`; IS AUTHORITATIVE FOR (introduced, labelled); one site is one spec; forbidden-before (`MUST NOT … BEFORE`); deterministic AFTER sugar under MUST and MAY; positive `MUST … BEFORE` illegal; one obligation per sentence; labels named for their heading, never abbreviated; closed vocabulary including record verbs; the `Term` declaration form; the signature block as a declaration form, one line per action; the standard label families; the casing tiers; the term entry and the bracket marker as reader sugar; a declaration may cite its owner; arithmetic only in term declarations; closed value sets; no pronouns, §13 rejects the passive; no inference; normalized representation; reverse diff over normalized rules; admission by Principle 2 — recurrence AND contested.

```
Lock 1: The parser MUST accept only the locked forms and the locked forms' deterministic sugar.
Lock 2: The lock list MUST NOT admit a form outside the locked forms except by Principle 2.
```

---

### 22. Core Rules

NOTE: a recap; every claim below is owned by a rule elsewhere (Surface 5, Surface 6 through 17, Direction 1 through 4, Sugar 1 through 2, Hard invariant 16, Hard invariant 20, Caveman 1, Caveman 2). Normative states WHAT. WHY explains why. UX presents how. Sugar shortens syntax and creates no semantics. AI generates WHY or UX from the normative surface, never the reverse. Nothing unstated is true because a reader expects it (Hard invariant 16, Hard invariant 20). Nothing omitted is supplied by context. Nothing is normative unless the parser can name it (Surface 2, Surface 18). Complex systems may require many rules; every rule stays simple (Caveman 1, Caveman 2).

WHY:
Strict Caveman grows slowly. Grace itself can grow enormously.

---

### 23. Changes

NOTE:
v0.62 (2026-09-24): Scope vocabulary, Verdict and Retention asymmetry promoted to the standard label families — the maintainer's ruling on the three candidates Standard label 4 had named, and the first time three crossed together. The drift pass Standard label 7 requires found one concept in each. **Scope vocabulary**, in [Shared Todo](./compositions/shared-todo.md), [Privileged Access Provisioning](./compositions/privileged-access-provisioning.md) and [Multi-Party Approval](./compositions/multi-party-approval.md): the scopes the composition defines for its Permissions instance and the action each gates — Shared Todo maps eight actions to seven scopes, the other two define three scopes and name the one gate they refuse to add, the same concept stated from its two sides. **Verdict**, in [Chain of Custody](./compositions/chain-of-custody.md), [Forensic Recovery](./compositions/forensic-recovery.md) and [Immutable Transaction Ledger](./compositions/immutable-transaction-ledger.md): how a verification read resolves what it reads into its answer — the first two compose an overall verdict from named classes, the third a binding verdict and per-entry authenticity, each a total function over evidence the read gathered. **Retention asymmetry**, in those three, [Propagate Consent Revocation Downstream](./compositions/propagate-consent-revocation-downstream.md) and Multi-Party Approval: how the spec answers where a record — an accounting record, a consent record, a chain, a lifecycle entry — outlives the audit events that attest it, read as lawful destruction and never as an orphan or a gap. **Standard label 9's positions follow where the naming specs already file them**: every one places Scope vocabulary and Verdict last in Composition logic and Retention asymmetry under Edge cases, so the first two take the end of Composition logic's placed rows — Scope vocabulary first, by the table's interim alphabetical order — and Retention asymmetry an Edge cases row between Indeterminate outcome and String policy, by the same order. A placed heading precedes every unplaced one, so five specs that carried an unplaced heading ahead of the newly placed one are reordered, text unchanged. Council read 198.

NOTE:
v0.61 (2026-09-21): one operator, one operand type. EXCEEDS compared quantities, lengths *and* instants, which is the multitasking-token row's second member — EXISTS split at v0.52, and this is EXCEEDS. Instants now compare with PRECEDES, negated DOES NOT PRECEDE (Term condition operator, Earned vocabulary 18, Earned vocabulary 19); EXCEEDS keeps quantities and lengths and nothing else. The form is one word, not a phrase: the maintainer ruled against composing a pair where a single word serves, so there is no `IS AFTER` and no `IS BEFORE`, and the negative reuses the shape DOES NOT EXCEED already set. PRECEDE joins EXCEED as a reserved grammar verb, so an ordering invariant reads `A commitment's confirmed at MUST NOT PRECEDE the commitment's placed at`. No plural form is admitted: a comparison has one subject and one object, so PRECEDE after a modal is the only inflection a rule carries. The corpus had already earned it — 19 rule sites wrote *precedes* in lower case before the operator existed, which no instrument read, because W-comparator's word list never carried it. 20 instant comparisons moved off EXCEEDS, 11 lower-case uses were raised, and D-condition-form now reads the operand beside each comparison in both directions. FOLLOWS was refused on measurement rather than taste: *follow* and *follows* sit at 18 rule sites in three senses — temporal, ordering and conformance — and a word meaning three things makes a bad operator. Ruled by the maintainer. Council read 146.

v0.60 (2026-09-18): *instance* and *section* are rule nouns (Term rule noun, Term instance, Term section). Both waited on a rename. *Instance* meant one deployed copy of a pattern everywhere but State Machine, which called its running record an instance until council read 108; it is written 253 times in the rules of 31 of the 41 migrated specifications, and the nineteen declarations that carry the word — *store instance* in fourteen atoms, *event log instance*, *party retention instance* — qualify it rather than redeclare it. *Section* meant both a titled part of a document and the host-supplied lock until council read 111 named the lock a critical section; it is written 173 times in the rules of fourteen specifications, most of them the citation form *the section titled X* that council read 121 settled and `lint.py`'s `X-section-title` resolves. Neither is declared bare by any specification (council read 128).

NOTE:
v0.59 (2026-09-17): *clock* is a rule noun (Term rule noun, Term clock). It is written 122 times in the rules of 35 of the 41 migrated specifications, declared in none, and headed 102 unresolved noun phrases — most of them the deployment's clock obligations, *the clock's monotonicity*, *honesty*, *timezone handling*, *synchronization* and *skew*, restated as capability requirements in 25 specifications. Its spread is the spread of the first six rule nouns, which the maintainer's v0.53 ruling gives to the grammar, and Term instant already named it (council read 119).

NOTE:
v0.58 (2026-09-17): *act* is a rule noun (Term rule noun, Term act). The noun reader's next most common miss after *critical section* and *instance* was *act*, unresolved at 52 sites in six specifications and used 126 times in the rules of eleven — Recoverable Invocation 54, Audit Trail 27, Attributed Permissions Admin 16, Defensible Retention 13. Each means its own thing done: Recoverable Invocation's call of the bound act, Audit Trail's record action or cascade, Actor Suspension's suspension, Consent's processing act. Declared in each, the word would have taken four meanings inside one composition tree, since Actor Suspension, Customer Onboarding, Defensible Retention and Recoverable Invocation compose Audit Trail. The maintainer ruled it the grammar's, as the six rule nouns of v0.53 are: one sense, something done that a record accounts for, and each specification's own declarations say which (council read 117).

NOTE:
v0.57 (2026-09-17): EXCEEDS has an English negative, DOES NOT EXCEED (Earned vocabulary 17, Hard invariant 34). Four conditions spelled *at most* as `NOT EXCEEDS` — Capability's ttl, Medication Order's dose, Credential's expires_at, Session's session_duration — and three spelled *at least* as `x EXCEEDS y OR x EQUALS y`, which read 31 found had no one-arm cure between numbers; `y DOES NOT EXCEED x` is that cure, and Audit Trail's `Invariant 3.1`, Recoverable Invocation's `reconcile step 5.1` and its aged term take it. Retention Window's *the duration is not positive* and *the max_purge_delay is negative* read `DOES NOT EXCEED the zero duration` and `the zero duration EXCEEDS the max_purge_delay`. The maintainer kept EXCEEDS for instants as for quantities and lengths: it means *later or greater in the value's order* on any ordered value, as EQUALS means the same on any value, and an obligation needs it after a modal (`MUST NOT EXCEED`), where *is after* does not parse. `W-ge-disjunction` gates. Council read 104.

NOTE:
v0.56 (2026-09-16): symbols leave the rules. The maintainer's ruling at council read 99 kept `=` and `|` for value-set declarations alone, and 86 symbols still sat in rule text across eleven specifications, with eight more in this document's own rules: 25 `<kind>` templates, 23 section signs, 11 arrows, 7 brace pairs, 7 bars, 5 en dashes in step ranges, 4 slashes and 4 asterisks. Each became words — *the section titled Conformance in `execution-contract.md`*, *the event's event_id mapped to the attestation_id*, *answering attestation_id*, *carrying invocation_id and intent_event_id*, *recording-failure(step-2) and recording-failure(step-3)*, *steps 2 through 5* — or, where it is a code spelling, a code span (`<kind>.intended`, `audit.*`); this document's own rules name the lock list rather than §21. Term rule symbol, Earned vocabulary 16; `check.py`'s `D-rule-symbol` gates. Council read 103.

NOTE:
v0.55 (2026-09-16): a record's state is tested as a value. Conditions asked it two ways — `IF the session stands in active` and `IF the party's state EQUALS verified` — and the maintainer ruled the second: the state is a declared value set, so the test names it, `the session's status EQUALS active`, `the order's state IS IN the pre-dispensing states` (Earned vocabulary 15). 178 rule and declaration lines in twenty-nine specifications moved, the state named by each specification's own value set — status, state, pool state, hold state, unit state, chain state, retention state, lifecycle state. *Stand* stays the verb of the write that moves a state. `check.py`'s `D-condition-form` gates *stands in* and *stands outside* in a condition. Council read 102.

NOTE:
v0.54 (2026-09-16): a term entry's code-spelling line is `Projection:`, not `Projects:`. Every other label on a term entry names a thing — `Kind:`, `Role:`, `Wire:` — and `Projects:` was the one verb; the line holds the projection a name lowers to, and under the v0.53 ruling it is where the code spelling lives. 757 lines renamed in fifty-three specifications, migrated or not, with their aligned blocks re-padded, and the term registry's introduction in twenty-three; `term-adapter.mjs` reads the new label and writes `projections` into the derived manifest. Proposed by the maintainer. Council read 101.

NOTE:
v0.53 (2026-09-16): the rule nouns are the grammar's. Read by a part-of-speech tagger over 7,869 rules, 3,665 of 21,031 noun phrases resolved to no declared name, and the everyday nouns led: *call* undeclared in 32 of the 36 specifications that use it, *write* in 29 of 35, *instant* in 26 of 27, *field* in 25 of 25, *answer* in 24 of 29. call, answer, write, input, field and instant are now declared once here (Term rule noun), a specification writes no declaration for one (Earned vocabulary 13), and each is written under its own name (Earned vocabulary 14) — *argument*, a second name for *input*, is gone from 91 rules and declarations in twenty-one specifications, *opaque argument* with it. Unresolved noun phrases fall to 3,211. *Instance* waits: State Machine declares it as one workflow where the other specifications mean one deployed copy of a pattern. The maintainer ruled the spelling that comes next — English names in rules, derived word for word from the code spelling, which lives in `Projects:` — and it is not swept here. `check.py`'s `D-rule-noun` gates. Council read 100.

NOTE:
v0.52 (2026-09-16): one condition operator, one sense, in English words. EXISTS carried at least eight senses across 314 sites in forty-one specifications — a caller's argument (123), a stored record (72), an event or condition (31), membership in a set (30), a deployment setting (24), a stored field (17), a record's state (16) and a constituent's read (1) — and `step_id NOT EXISTS` and `the assignment_id NOT EXISTS` meant *the caller sent nothing* and *no record carries the id*, told apart by an article. Now EXISTS says a thing is there, and `no thing EXISTS` says it is not (the absence form; `NOT EXISTS` retired); a missing value is `EQUALS blank` (161 sites, `is blank` among the retired spellings), and blank is declared once here, where twenty-five specifications had declared it word for word and defined it by the operator beside it; membership is IS IN and IS NOT IN, a record's state among them. `=` and `!=` became EQUALS and DOES NOT EQUAL at 151 tests, and a write that sets a field says `field set to value` at 40 sites, so `=` and `|` stay only where a value set is declared. The maintainer ruled English over symbols: read aloud by a screen reader, `!=` is *exclamation equals* or nothing. Earned vocabulary 6 through 12, Hard invariant 32 and Hard invariant 33 added, Hard invariant 14 reworded; `check.py`'s `D-condition-form` gates. Council read 99.

NOTE:
v0.51 (2026-09-16): a backtick quotes literal text and never marks a name (Term code span, Surface 30). The declaration form lost its backticks at v0.45; the names a declaration lists — value-set members, fields, outcome codes, vocabulary entries, and in this document the reserved tokens and the standard label families — kept them, and so did the prose that mentioned them. 5,346 code spans unwrapped across this document and forty-one specifications; code spellings, expressions, file names, wire tokens and quoted forms keep theirs. The maintainer ruled the reach: every name the specification itself declares, snake and kebab spellings included. Formatted strictly: `check.py`'s `D-code-span` gates. Council read 92.

NOTE:
v0.50 (2026-09-16): brackets point only to actions and terms. A rule naming another specification carried a Markdown link, `[Permissions](./permissions.md)`, which renders nowhere inside a fence and reads there as a bracket marker Surface 26 cannot resolve; it now names the specification alone (Surface 29), as Hard invariant 28 already writes a cross-spec label. 218 links removed from 217 rules in twenty-nine specifications, each link's text the linked specification's own title. Formatted strictly: `check.py`'s `F-bracket` gates a link in a rule and a bracket marker that lands on no term entry. Council read 91.

NOTE:
v0.49 (2026-09-16): one fence kind. A block of rules was a fence marked `text`, a signature block a fence marked with nothing, and the two marks said nothing the first line did not already say — so the mark goes and the first line decides (Surface 18, Term bare fence). A block that carries a labelled rule under a first line that opens nothing is still rejected (Surface 19), which is what the `text` mark used to guard. 982 fences unmarked across the grammar, `spec-format.md` and forty-one specifications. Formatted strictly: `check.py`'s `D-fence-form` gates a fence still marked `text`. Council read 90.

NOTE:
v0.48 (2026-09-15): a signature is written in words — `name(inputs, optional input)`, an answers line, a refuses line (Term signature form, Closed vocabulary 24 through 27) — replacing the arrow, the trailing `?`, the braced or bracketed record and the `rejected(…)` wrapper. A record an action answers is a declared term, as an inner choice became one at council read 84. 171 signatures in 51 blocks across forty specifications; the wrapper also left 69 rules and 115 prose and example sites, where the outcome now stands by its own name. Admitted with the syntax table, formatted strictly: `check.py`'s `D-signature-form` gates. Council read 89.

NOTE:
v0.47 (2026-09-15): a run of labels is written one way, `Family N through M` (Term range citation, Hard invariant 29 through 31), replacing the dash, the repeated family, the plural family and *to*. 379 citations converted across sixty-two files; two degenerate ranges, `Capability requirement 2–2`, became the one label they cited. Admitted with the syntax table, formatted strictly: `lint.py`'s `F-range-form` gates every Markdown file in the repository. Council read 88.

NOTE:
v0.46 (2026-09-15): a tombstone is its own line, `Deleted: Label. The owner, and why.`, and no longer a `NOTE:` whose text happens to begin with a label and the word *deleted*. `NOTE:` now means one thing — this line binds nothing — where it had meant that and, in one shape, *reserve this label forever*; and because a tombstone is no surface prefix, `Surface 18` counts it with a labelled rule when it classifies a fence, so a tombstone written first no longer demotes the rules beneath it, the trap `F-prefix-first` caught twice. 297 tombstones converted, words kept. Council read 87.

NOTE:
v0.45 (2026-09-15): the declaration form is `Term name: definition.` — the name runs to the first colon, bare, and the definition ends with a period — replacing `Terms › `name`: definition.`, whose separator no keyboard carries and whose backticks gave a declared name a second job beside quoting literal text. Admitted with the syntax table, formatted strictly: a line that opens with `Term` or with the old separator and does not match the form is a gating finding (`check.py`'s `D-decl-form`). 1,649 declarations converted across the grammar and forty-one specifications; no definition changed. Council read 86.

NOTE:
v0.44 (2026-09-15): `Standard label 11` narrowed from *a specification MAY omit a standard label family* to omitting one only where `spec-format.md` §Heading standard does not require its heading, and `Standard label 9` and `Standard label 12` now cite that section, which replaced §Required sections as the owner of every heading's name, level, parent, order and requirement. The maintainer's rulings, made the same day: a spec carries every heading its shape requires and may skip the rest, and one order governs. `Standard label 11` and `spec-format.md` had given two answers on whether a standard family may be omitted — a blanket MAY here, required-with-an-escape there — and the narrowed rule is the one answer. The outlier v0.43 recorded is gone: Idempotent Reservation's Housekeeping now sits after Wiring decision, placed by the sweep `H-heading` drove to zero. Council read 80.

NOTE:
v0.43 (2026-09-15): Housekeeping promoted to the standard label families, closing the pair Reconciliation opened one version earlier. Three specifications name it and the drift pass Standard label 7 requires found one concept: each leg runs outside every invocation, owes no closure window, refuses to repair what it finds, and refuses a constituent's write. The apparent divergence is the declaration's own two poles — [Idempotent Reservation](./compositions/idempotent-reservation.md)'s leg **removes** where [Authenticated Actor](./compositions/authenticated-actor.md)'s and [Attributed Permissions Admin](./compositions/attributed-permissions-admin.md)'s **report** — which *it may report, it may remove* already admits, and the section each takes or refuses tracks whether the leg writes at all rather than what the family means. **Standard label 9's position is the pair's rather than the majority's:** two of the three place the family after Wiring decision, where Reconciliation already sits, and Idempotent Reservation places it second — an outlier that predates the pair's cut and is a conformance finding against that spec rather than a second position. Council read 71.

NOTE:
v0.42 (2026-09-15): Audit arm and Reconciliation promoted to the standard label families — the promotion path's second use, and the first time two families crossed on one migration. Four specifications name each, and the drift pass Standard label 7 requires found one concept in each across all four. Audit arm's concept is the mapping of the substrate's `record_action` taxonomy at the composing boundary: which arm is retryable, which arm arrives with the record already appended, which is a pageable deployment fault, and what the composition owes on each — stated by step in Login and Defensible Retention, by step *and* position in Customer Onboarding and Actor Suspension, which is the same concept with an export the first two did not need. Reconciliation's concept is the awaited leg, and all four members answer council read 64's axis the same way: each escalates against a **declared window** (Login's reconciliation window, Defensible Retention's and Customer Onboarding's compensation window, Actor Suspension's completion window), which is precisely what Housekeeping's two members owe none of. Standard label 9's position is derived rather than assigned: all four specifications already place Audit arm before `Action wiring` and Reconciliation after Wiring decision, so the promotion records the order the corpus had already agreed on. Council read 69.

NOTE:
v0.41 (2026-09-14): Wiring decision promoted to the standard label families — the promotion path's first use, and the first family the corpus has promoted at all. Seven specifications name it and the drift pass Standard label 7 requires found one concept across all seven, in one invariant shape: a rule naming the decision positively, and one or more rules forbidding the wiring the decision rejected. The argument that decided it is not the count. `spec-format.md` already **requires** *The load-bearing wiring decision* as a composition-shape section, so the family is a container the corpus already carries having its rule form named, and Standard label 9 gives it the position every one of the seven already sits in — promotion reconciles two documents that agreed, where declining would have left them drifting. Council read 64.

NOTE:
v0.40 (2026-09-12): cited and composing pattern added to the category value set. Both are categories in active use — cited in two compositions, `composing patterns` in one — and absent from the set that is supposed to enumerate the categories a vocabulary may carry, which Value set 3 forbids and Closed vocabulary 2 needs. `check.py` already carried both names in two hard-coded category sets, so the instrument recognized them before the grammar did; the checker now derives the set from this line instead of holding its own copy, so the two cannot drift again. Council read 29.

v0.39 (2026-09-12): sentence case added to the casing tier value set. The tiers shipped with three members against a census that counted 104 word-named label families in sentence case — a member in active use and absent from its own set, which Value set 3 forbids and Casing 6 needs. Council read 27.

NOTE:
v0.38 (2026-09-12): Authority 3 widened from *two specs* to *two rules*, so one proposition owned twice inside a single spec is a finding rather than a preference. Admitted on Principle 2's two halves — the shape recurs in every migrated spec, and the contested half is council read 26's count of 46 duplicate pairs in Capacity alone, seven of them verbatim under two labels. `tools/grace/check.py` reports `W-duplicate-proposition`. No form admitted or withdrawn; a scope widened.

NOTE:
v0.37 (2026-09-12): `card` renamed to term entry (Surface 25, Surface 27, §21). A rename only — no rule changed, no form admitted or withdrawn. *Card* named a presentation; the object is structured knowledge about a declared term — its definition, kind, relationships and projection token — and a Grace UI may render it as a card, a tooltip, a panel or nothing at all. Declared lower case, like every sibling term in this document's vocabulary (bracket marker, normative block, `text fence`, casing tier), because Casing 4's title case is the bracket marker's and a grammar term is not one. Council approved.

NOTE:
v0.36 (2026-09-12): the casing tiers declared (Casing 1 through 6) — upper case is reserved, an initial capital names a label family or a bracket marker, lower case is the specification's own. Already in force in nineteen documents and drifting at 471 sites inside normative rules, which is Principle 2's two halves. Council read 24.

NOTE:
v0.35 (2026-09-11): local specs declare domain meaning, not GRACE meaning (Principle 9 through 11); the standard label families declared once, here (Standard label 1 through 3); the signature block admitted with one line per action, and the `rejected(…)` wording it carried from Recoverable Invocation dropped; the term entry and the bracket marker read as the surface nothing, the `Terms ›` declaration the one owner (Surface 25 through 27). Council read 8.

NOTE:
v0.34 (2026-09-11): labels are words — the name of the heading a rule sits under, then a number (Rule shape 7, Rule shape 8); every label in this document, Recoverable Invocation, Audit Trail and Lease relabelled; a cross-spec reference names the spec before the label (Hard invariant 28). No form admitted or removed.

NOTE:
v0.27–v0.33, the council's reads and the labels before v0.34 are archived in git history (`git log -- GRACE-lang.md`, last commit before the relabel `e80fd21`).

NOTE: End of GRACE-lang. We love you. 🖤

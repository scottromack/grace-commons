# GRACE lang v0.35 — Minimal Earned Grammar

## Grace lang is a controlled semantic metalanguage for domain specifications.

## NOTE: Grace UX is abstracted microcopy and interaction behavior derived from verified logical state.

Status: the current version and its history are §23; this line states nothing else.
Date: 2026-09-11

NOTE:
This document obeys itself. A fenced block is classified by its first line (Surface 18): a labelled rule opens a normative block, a surface prefix opens that surface, anything else is a parse error. Everything outside the fences and the `Terms ›` lines carries nothing (Surface 3); `WHY:` and `NOTE:` label it for readers. The vocabulary the document's own rules use is declared in §13.

---

### 1. Core Principles

```text
Principle 1: The grammar MUST contain only forms earned by repeated use in real specifications.
Principle 2: §21 MAY admit a form ONLY IF the form's concept recurs across specifications AND the concept satisfies contested.
Principle 3: §21 MUST NOT admit a form on one occurrence.
Principle 4: The grammar MAY admit sugar.
Principle 5: The grammar MUST NOT admit inference.
Principle 6: Complexity MUST live in the number and arrangement of simple rules.
Principle 7: Complexity MUST NOT live in the grammar of one rule.
Principle 8: The maintainer MUST decide EVERY admission under Principle 2.
Principle 9: A specification MUST declare the specification's domain meaning.
Principle 10: A specification MUST NOT declare grammar meaning.
Principle 11: A writer MUST declare a meaning locally ONLY IF the domain forces the declaration.
```

Terms › `contested`: the concept's free-prose expression drifted, was read two ways, OR produced a finding.

Terms › `maintainer`: the human in charge of the corpus; decides admission.

WHY:
The test is the concept, not the token: a token appears only after its form is admitted, so counting tokens is circular. Recurrence alone admits noise. Counts follow `pressure-testing.md` §*Measure the form, not the word*. Surface 5 owns *states WHAT*. The reviewers a draft is run past — the council — advise and never admit; who they are and how a read is cited is the corpus's internal process, kept out of the grammar (`governance.md` §*The language council*).

*Local specs declare domain meaning, not GRACE meaning* (Principle 9–11). Explicit never meant repeating a globally-known fact in every file: the grammar owns the label families, the categories, the outcome shapes and the timing concepts, and a spec that restates one of them has added a second owner for something it does not own. A spec declares the domain — the nouns, the verbs, the value sets, the signatures, and the local exception the domain forces. The substrate gets richer as the specs get smaller (CR-8).

---

### 2. Surfaces

Terms › `surface`: `normative` | `WHY:` | `UX:` | `PROVISIONAL:` | `NOTE:` | `nothing` (a line outside every fenced block and outside a Terms › declaration).

```text
Surface 1: EVERY line MUST belong to exactly one surface.
Surface 2: The parser MUST read an unprefixed line in a normative block as normative.
Surface 3: The parser MUST NOT read a line outside a normative block as normative.
Surface 4: EVERY normative line MUST parse.
Surface 5: A normative line MUST state WHAT.
Surface 6: WHY: MUST NOT create, satisfy or alter an obligation, an enumeration or a reverse-diff result.
Surface 7: A reader MUST NOT infer normative GRACE from WHY:.
Surface 8: A human or AI MAY generate WHY: from normative GRACE.
Surface 9: A writer MAY regenerate or discard WHY: at any time.
Surface 10: UX: MUST NOT create behavior absent from normative GRACE.
Surface 11: UX: MUST NOT alter normative meaning.
Surface 12: A reader MUST NOT infer normative GRACE from UX:.
Surface 13: A writer MAY write UX: warm, explanatory or context-specific.
Surface 14: A provisional form MUST NOT carry normative force.
Surface 15: The parser MUST ignore WHY:, UX:, NOTE: and PROVISIONAL: lines.
Surface 16: A system MUST obey EVERY normative line.
Surface 17: A system MUST NOT obey WHY:, UX: or NOTE:.
Surface 18: The parser MUST classify a text fence by the block's first line: a labelled rule opens a normative block; a surface prefix opens that surface.
Surface 19: The parser MUST reject a text fence whose first line is neither a labelled rule nor a surface prefix.
Surface 20: The parser MUST read a signature block as a declaration.
Surface 21: The parser MUST read a fenced block that is neither a text fence nor a signature block as the surface nothing.
Surface 22: A surface prefix on a block's first line MUST cover every line of the block.
Surface 23: A surface prefix on a later line of a normative block MUST cover that line alone.
Surface 24: The parser MUST read a line outside every fenced block and outside a Terms › declaration as the surface nothing.
Surface 25: The parser MUST read a card as the surface nothing.
Surface 26: The parser MUST resolve a bracket marker to the declaration the marker names.
Surface 27: A card MUST NOT carry an obligation.
```

Terms › `normative block`: a fenced text block of labelled rules, a `Terms ›` declaration, or a signature block — a spec's whole normative surface (`spec-format.md` §*The normative surface*).

Terms › `text fence`: a fenced block whose info string is `text`.

Terms › `card`: a Terms registry entry — a heading, prose and a `Kind` line — the reader's copy of a declaration (`spec-format.md` §*Terms*).

Terms › `bracket marker`: `[Name]` in prose, and the link line that lands it on the name's card; a pointer to the declaration, never a second copy of the declaration.

Terms › `signature block`: a fenced block with no info string whose lines are signature lines — `name(args) →` followed by the action's arms — one line per action, one or more lines per block; each line is the declaration of that action's outcomes, read as the value set the action's rules land on.

Terms › `normative`: unprefixed Strict Caveman (§20) inside a normative block.

Terms › `run`: one execution of a system.

Terms › `conformance failure`: a run that violates a rule.

Terms › `obey`: a system obeys a rule when every run of the system satisfies the rule's obligation under the rule's condition; a run that does not is a conformance failure, decided from records by the spec's acceptance checks (Generation acceptance: `spec-format.md`); an inequality rule (Timing 9) obliges the party that binds the terms; a rule whose subject is not an agent is a constraint on the writer.

Terms › `MAY rule`: a rule under `MAY`; a system satisfies a `MAY` rule vacuously, and a `MAY` rule obliges nothing.

```text
NOTE: a fragment, not a rule — no label, no actor, no modal; the tail alone:
      close intent ONLY AFTER hold_bound
```
```text
WHY:
The sweep waits for the longer of two possible holders, so an intent record is never closed mid-write by another invocation.
```
```text
UX:
We are still checking whether this action completed.
Please do not submit it again yet.
```
```text
PROVISIONAL:
open_invocations IS DERIVED FROM journal.
```

Terms › `hold_bound`: max(completion_bound, closure_latency + journal_write_bound).

NOTE: `hold_bound` is the example's term; the arithmetic lives in the declaration, never in the rule (Hard invariant 24).

---

### 3. WHAT / WHY / HOW

```text
NOTE:
Normative = WHAT
WHY       = WHY
UX        = HOW
```

WHY:
Only the normative line carries meaning the system must obey (Surface 16, Surface 17). WHY and UX are downstream and disposable.

---

### 4. Direction of Generation

```text
Direction 1: A writer MAY generate WHY: from normative GRACE.
Direction 2: A writer MAY generate UX: from normative GRACE.
Direction 3: A writer MUST NOT generate normative GRACE from WHY:.
Direction 4: A writer MUST NOT generate normative GRACE from UX:.
Direction 5: A drafter MAY use fuzzy intent while drafting.
Direction 6: A written normative rule MUST stand alone and pass every GRACE check.
Direction 7: A writer MUST NOT keep fuzzy intent as a source of truth.
```

```text
NOTE:
Normative → WHY     (allowed)
Normative → UX      (allowed)

WHY  ↛ Normative    (forbidden)
UX   ↛ Normative    (forbidden)
```

---

### 5. Core Rule Shape

Terms › `statement shape`: `subject modal verb object` | `subject modal verb object tail` | `IF condition THEN statement` | `WHEN condition:` followed by statements | `quantifier subject modal verb object` | `subject IS AUTHORITATIVE FOR proposition`.

Terms › `object`: a declared identifier, or an enumeration introduced by `EXACTLY ONE OF` naming the outcomes among which exactly one holds.

Terms › `label`: the name of the heading the rule sits under, in the heading's own words, singular, three words at most, then the rule's number under that name — `Principle 1`, `Non-goal 4`, `retention_policy 2`; under a heading that carries its own number, that number, a dot and the rule's number — `Invariant 2.3`, `record_action step 3.2`; a WHEN child adds a lower-case letter — `Take 2a`; unique within a spec.

Terms › `rule form`: `LABEL: statement` on one line, or `LABEL: WHEN condition:` followed by indented child rules each in rule form.

Terms › `child`: a rule inside a WHEN block.

```text
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

Terms › `standard label family`: `Identity` (what identifies an instance) | `State` (what the spec holds) | `Operation` (one action's rules) | `Invariant` (a property of every reachable state) | `Check` (an acceptance check) | `External check` (a check needing evidence the records do not carry) | `Non-goal` (what the spec does not do, and who owns it instead) | `Composition note` (an obligation on a composing pattern) | `Composes` (a constituent's role) | `Capability requirement` (what the deployment supplies).

```text
Standard label 1: The grammar IS AUTHORITATIVE FOR the standard label families.
Standard label 2: A specification MUST NOT redeclare a standard label family.
Standard label 3: A label family outside the standard set MUST carry the meaning of the heading the family names.
```

WHY:
A family carries meaning the rule's own words leave out — *Non-goal 3: The host MUST admit waiters in arrival order* is a positive obligation, and the scope that makes it a non-goal lives in the label (CR-8). Declaring the families once here is what makes that meaning owned rather than conventional, and Principle 9–11 is why the declaration is here and not in every spec.

---

### 6. Earned Vocabulary

Terms › `quantifier`: `EVERY` | `EXACTLY ONE` | `EXACTLY ONE OF` (an exclusive choice among named outcomes).

Terms › `modal`: `MUST` | `MUST NOT` | `MAY`.

Terms › `condition operator`: `=` | `!=` | `EXISTS` | `NOT EXISTS` | `EXCEEDS` | `AND` (flat) | `OR` (flat, inclusive).

```text
Earned vocabulary 1: A condition MUST NOT mix `AND` and `OR`.
Earned vocabulary 2: A writer MUST route a mixed condition through a declared term.
Earned vocabulary 3: A rule MUST NOT carry `OR` in an obligation or between obligations.
Earned vocabulary 4: A writer MUST write an exclusive choice as `EXACTLY ONE OF`.
Earned vocabulary 5: A condition MUST NOT nest.
```

---

### 7. Earned Tails

Terms › `tail`: `ONLY AFTER term` | `ONLY IF condition` | `WITHIN term` | `PER term` | `BEFORE term` (under `MUST NOT` only, Timing 5).

```text
Tail 1: A reader MUST NOT infer beyond a tail's text.
```

WHY:
`ONLY IF` is admitted by Principle 2: the concept recurs, and gate 12 F1's repair is the finding. `ONLY UNDER` is provisional (§18): no controlled use, no finding.

```text
NOTE:
/people MAY serve actor ONLY IF invite_actor EXISTS OR grant_permission EXISTS.
```

---

### 8. Timing and Bounds

```text
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
`run_floor MUST NOT EXCEED run_bound` means `run_bound ≥ run_floor`. Timing 12 is no new form — a permission gated on a condition; `instance MAY start ONLY IF compensation_window EXCEEDS worst_closure`. A prohibition past an instant is Timing 7, which is why Timing 4 admits no `AFTER` under `MUST NOT`. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim; liveness goes through `WITHIN`.

---

### 9. WHEN Blocks

```text
WHEN block 1: The parser MUST read EVERY child of a WHEN block as an independent rule.
WHEN block 2: A reader MUST NOT infer ordering among the children of a WHEN block.
WHEN block 3: A WHEN block MUST NOT nest.
```

```text
NOTE:
WHEN condition:
    statement
    statement
    ...
```

---

### 10. Authority

```text
Authority 1: A writer MUST write authority as `subject IS AUTHORITATIVE FOR proposition`.
Authority 2: A synonym MUST NOT carry authority semantics.
Authority 3: Two specs MUST NOT claim authority for one proposition.
Authority 4: The parser MUST treat two propositions as one proposition ONLY IF the propositions normalize identically (Reverse diff 3).
Authority 5: A citing spec MUST name the owner.
Authority 6: A citing spec MUST NOT restate the rule.
```

WHY:
No synonym — `canonical`, `source of truth`, `primary` — carries authority semantics. A site is one spec (`pressure-testing.md` §*One site is one spec*). `IS AUTHORITATIVE FOR` is an introduced form, not a discovered one: the concept is earned (three consecutive gates; DRY on responsibility depends on it), the phrasing was minted 2026-09-10 in Recoverable Invocation and propagated only after use. It is the grammar's one labelled exception to Principle 1.

---

### 11. Hard Invariants (parser-enforced)

```text
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
Hard invariant 14: The parser MUST reject a value used with `=` or `!=` that belongs to no declared closed value set.
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
```

Terms › `pronoun`: `it` | `its` | `itself` | `they` | `their` | `them` | `he` | `she` | `his` | `her`, and `this`, `that`, `these`, `those` standing alone — the set Hard invariant 4 rejects and `tools/grace/check.py` enforces; a relative `whose`, `that` or `which` opening a clause is not a pronoun.

Terms › `tombstone`: a `NOTE:` line inside a normative block whose text begins with a label followed by the word `deleted`; recognized by that form alone (Hard invariant 25, Hard invariant 27).

WHY:
§11 is the parser's contract; the writer-facing rules that mirror it (Rule shape 3, WHEN block 3, Earned vocabulary 1, Sugar 2, Timing 4, Timing 6) oblige a different actor, and the two are kept as two norms on purpose. A cross-reference survives a version because labels never move (Hard invariant 26, Hard invariant 27) and never collide across specs (Hard invariant 28): Recoverable Invocation's `Allowance 2` and this document's `Rule shape 2` are cited as `Recoverable Invocation Allowance 2` and `GRACE-lang Rule shape 2`.

---

### 12. Sugar Rule

```text
Sugar 1: Sugar MAY shorten a rule.
Sugar 2: Sugar MUST NOT add information.
Sugar 3: A writer MUST NOT place a sentence that matches no admitted form and no deterministic sugar in a normative block.
```

```text
NOTE: the sugar and its normalization.
NOTE: sweep MUST run AFTER examine_edge.
```
```text
NOTE: sweep MUST run ONLY AFTER examine_edge.
```
```text
NOTE: PER and a cadence, exercised once; the examples in this document borrow Recoverable Invocation's vocabulary and are exemplars, not citations — Hard invariant 28 does not reach a NOTE:.
NOTE: sweep MUST examine PER reconciliation_cadence.
```

---

### 13. Closed Vocabulary

```text
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
```

Terms › `category`: `actor` | `record` | `record verb` | `value set` | `bound` | `cadence` | `term` | `qualifier`.

Terms › `declaration form`: `Terms › name: definition.` on one line, the name in backticks.

Terms › `value-set form`: member names separated by `|`.

Terms › `name`: a spec's name is the spec's file stem, case preserved; this document's is `GRACE-lang` (the title spaces it for reading).

Terms › `definitional sentence`: *X is Y*, *X counts Z*, *the key is (kind, act_key)* — a sentence with no modal.

Terms › `reserved grammar verbs`: `EXCEED` (in `MUST NOT EXCEED`) and `IS AUTHORITATIVE FOR` carry grammar semantics; a specification never declares them as record verbs. Every other verb in a rule is a record verb the specification declares.

Terms › `identifier`: a subject, an object, a term name or a value in a rule; every identifier resolves to a declaration (Closed vocabulary 4).

Terms › `actor`: a declared identifier that may serve as a rule's subject.

Terms › `agent`: an actor that can perform a rule's verb — the grammar; §21; the parser; a specification; a citing spec; an owner; a system; a reader; a writer; a drafter; a human; AI; the reverse diff; a maintainer; a party. A rule whose subject is an actor and not an agent constrains the writer (`obey`).

WHY:
A named expression has one owner, and a diff can match it by name. Closed vocabulary 8 is what rejects the passive — *The actor MUST be granted invite_actor* has no declared record verb after the modal — which is why no parser invariant restates the rule. A citation form lets a composition use a constituent's term without restating it.

```text
NOTE:
record verb record_action: Audit Trail
```

#### This document's own vocabulary

Terms › `actors`: (every subject in this document, agent or not) the grammar; §21 (the lock list); the parser; a specification (a spec); a rule; a statement; a sentence (a rule's text); a condition; a form; a sugar form; a term; a declaration; a WHEN block; a tail; a surface; a system; a reader; a writer; a drafter; a human; AI; the reverse diff; the normalized form (the representation); fuzzy intent; a value set; a value; an enumeration; a synonym; a citing spec; an owner (the spec that declares a term); a registry (a spec's Terms section); `WHY:`; `UX:`; `NOTE:`; `PROVISIONAL:`; sugar; complexity; arithmetic; a label; an obligation; a proposition; an invariant; a tombstone; an ordinal; a pronoun; a line; a fenced block; a party; a run; a maintainer; a child; a category; an actor; an agent.

Terms › `record verbs`: decide, contain, admit, recur, satisfy, live, state, read, parse, create, alter, infer, generate, regenerate, discard, write, obey, ignore, carry, use, stand, pass, route, mix, nest, normalize, name, restate, resolve, cite, declare, acquire, redeclare, renumber, reuse, enumerate, reject, lower, report, treat, assume, keep, express, mark, shorten, add, accept, supply, earn, belong, cover, classify, claim, qualify, give, match, place, bind, reserve, compare, land.

Terms › `qualifiers`: `ratified` — accepted into §21 by Principle 2; `migrated` — rewritten in this language, declared by the spec's own `qualifiers` line as `` `migrated` — rewritten in GRACE lang vN (date) ``, which is how a tool tells a migrated spec from an unmigrated one without guessing from a fence.

Terms › `records`: empty.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `terms`: `contested`, `hold_bound`, `run_floor` and the bounds the examples compute over — `completion_bound`, `closure_latency`, `journal_write_bound`, borrowed from Recoverable Invocation and exemplars here, never citations (Hard invariant 28 does not reach an example) — and every other name declared in this document — a comprehension over the document's `Terms ›` lines, determinate by construction.

Terms › `value sets`: `surface`; `quantifier`, `modal`, `condition operator`; `tail`; diff result — `ADDED` | `REMOVED` | `CHANGED`; `category` (declared once, at Terms › `category`; cited here by Closed vocabulary 15).

---

### 14. Closed Value Sets

```text
Value set 1: A value set MUST enumerate every admitted value.
Value set 2: The parser MUST reject an undeclared value.
Value set 3: A value set MUST NOT carry an implicit other.
```

---

### 15. Canonical Examples

```text
NOTE: exemplars in Recoverable Invocation's vocabulary, not citations; the labels are illustrative.
Canonical example 1:
IF commit = unknown THEN invocation MUST yield.

Canonical example 2:
EVERY writer MAY write outcome ONLY IF section_lease EXISTS.

Canonical example 3:
operator MUST NOT resolve BEFORE acquiring section.

Canonical example 4:
sweep MUST reconcile AFTER examine_edge.
```
```text
NOTE: Canonical example 4 normalizes to `ONLY AFTER`.
Canonical example 5:
IF intent_age EXCEEDS retention_edge THEN sweep MUST NOT examine intent.

Canonical example 6:
run_floor MUST NOT EXCEED run_bound.
```

Terms › `run_floor`: `max(completion_bound, closure_latency + journal_write_bound) + closure_latency` — Recoverable Invocation's declaration, borrowed with the name.

---

### 16. Normalized Form

```text
Normalized form 1: The parser MUST lower EVERY parsed rule to an explicit structural representation.
Normalized form 2: The representation MUST carry only information present in the normative source or added by a ratified deterministic sugar rewrite.
Normalized form 3: The representation MUST NOT carry information from WHY:, UX:, NOTE:, PROVISIONAL: or context.
```

---

### 17. Reverse Diff

```text
Reverse diff 1: The reverse diff MUST compare normalized normative obligations.
Reverse diff 2: The reverse diff MUST report ADDED, REMOVED and CHANGED.
Reverse diff 3: The reverse diff MUST treat two forms that normalize identically as equivalent.
Reverse diff 4: The reverse diff MUST NOT assume equivalence otherwise.
Reverse diff 5: The reverse diff MUST NOT report a change to WHY: or UX:.
```

---

### 18. Candidate Forms

```text
Candidate form 1: The parser MUST treat a form as provisional until §21 admits the form.
Candidate form 2: A spec MUST state a degraded rule in admitted forms under IF or WHEN.
Candidate form 3: A spec MUST mark a DEGRADES TO pairing PROVISIONAL:.
```

```text
PROVISIONAL: ONLY UNDER
PROVISIONAL: IS DERIVED FROM
PROVISIONAL: COMPOSES / BINDS
PROVISIONAL: positive MUST … BEFORE
PROVISIONAL: <strong rule> DEGRADES TO <weak rule>
PROVISIONAL: a code span inside a rule quotes text — the grammar's own meta-rules (Timing 1–12, Earned vocabulary 1–4, Hard invariant 7–11, Authority 1, Closed vocabulary 18) mention the tokens they govern
```

WHY:
`DEGRADES TO` is a pairing slot for a degraded guarantee: the condition stays on the strong rule's `ONLY IF`, the slot carries none, so the pairing adds no third rule — the reverse diff sees the strong rule and the weak rule, and the `PROVISIONAL:` pairing line is invisible to it (Surface 15). Recoverable Invocation uses it four times, states each weak rule under `IF`, and marks the pairing provisional — the contested history §1 requires. The signature block was admitted in v0.33 (Surface 20, Closed vocabulary 20–22) on twelve sites across two specs and a parse-error finding (CR-7); the release-and-reject idiom was withdrawn the same day — after CR-7's splits it has no site, and Principle 3 admits nothing on none.

---

#### Watch list — pressure the rewrite may find, flagged and counted, not admitted

NOTE:
During the corpus rewrite, no grammar is added preemptively. A rewriter flags recurring pressure at the site, as `NOTE: watch <pressure>` beside the rule that strained, and recurrence is the count of flags across specs. Most of these are expected to collapse into declared domain terms rather than new grammar. Watched: persistent state (cases that want `WHILE`); applicability (cases that want `WHERE`, or feature-present gating); cardinality (needs beyond `EVERY`, `EXISTS`, `EXACTLY ONE`, `EXACTLY ONE OF`); condition negation (where `!=`, `NOT EXISTS` and `MUST NOT` are not enough); event versus state (where the distinction matters enough that terms alone become awkward); contradiction (two rules normalizing to `X MUST a` and `X MUST NOT a` under identical conditions — nearly free to detect after normalization, and waiting for its finding); satisfaction (where `obey` is not enough: what a violation of `WITHIN` is, compensate or nonconform); addressable sections (a rule that names a section as subject or object — Recoverable Invocation's journal_fence 2, Allowance 2, Instance start 1, Which closing stands 1 and Invariant 2.6 make section titles the subjects of authority claims, and this document's `value sets` line once cited sections by ordinal; the grammar has labels for rules and nothing for sections). Also watched, and counted at two: the wire layer (a card's `Projects:` line — the one place a lowering token is written down, on the nothing surface, in Lease and Duplicate Prevention; a third document satisfies Principle 2 and the layer wants a declared form). Counts so far: Recoverable Invocation flags none yet (the pilot predates the list); Audit Trail flags six — applicability, persistent state, event versus state, cardinality, condition negation, satisfaction; Lease flags none. Lease's two flags were raised by CR-8 and both dissolved the same day, neither into new grammar: temporal quantification (*at every instant*) was redundant once §5 declared what the `Invariant` family means, and the event in Operation 4's condition (*the arrival term elapses*) was a comparison the admitted operators already carry. A flag is a claim that the grammar is short a form, and a claim that survives a rewrite in admitted forms is the only kind that counts. The rule: flag first, count recurrence, admit nothing until the corpus forces it (Principle 1–3).

---

### 19. Language Growth

```text
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

Terms › `Strict Caveman`: short sentences; one obligation per sentence; explicit subject, modal, action and object; explicit condition when needed; one canonical term for one meaning; no pronouns; no rhetorical dependency; no hidden implication.

```text
Caveman 1: A writer MUST express complex behavior as more simple rules.
Caveman 2: A writer MUST NOT express complex behavior as a more complicated sentence.
```

---

### 21. What the grammar locks

Terms › `locked forms`: Strict Caveman normative prose; WHAT / WHY / HOW separation; `WHY:` and `UX:` with zero normative force; `MUST` / `MUST NOT` / `MAY`; `EVERY` / `EXACTLY ONE` / `EXACTLY ONE OF`; flat `IF` and flat `WHEN`; flat `AND`, flat `OR`, never both in one condition; `OR` only inside conditions and term declarations; `=` / `!=` / `EXISTS` / `NOT EXISTS` / `EXCEEDS`; `ONLY AFTER` / `ONLY IF` / `WITHIN` / `PER`; `MUST NOT EXCEED` for ≥, no `AT LEAST`, no `STRICTLY`; the strict lower bound as `MAY … ONLY IF … EXCEEDS …`; `IS AUTHORITATIVE FOR` (introduced, labelled); one site is one spec; forbidden-before (`MUST NOT … BEFORE`); deterministic `AFTER` sugar under `MUST` and `MAY`; positive `MUST … BEFORE` illegal; one obligation per sentence; labels named for their heading, never abbreviated; closed vocabulary including record verbs; the `Terms ›` declaration form; the signature block as a declaration form, one line per action; the standard label families; the card and the bracket marker as reader sugar; a declaration may cite its owner; arithmetic only in term declarations; closed value sets; no pronouns, §13 rejects the passive; no inference; normalized representation; reverse diff over normalized rules; admission by Principle 2 — recurrence AND contested.

```text
Lock 1: The parser MUST accept only the locked forms and the locked forms' deterministic sugar.
Lock 2: §21 MUST NOT admit a form outside the locked forms except by Principle 2.
```

---

### 22. Core Rules

NOTE: a recap; every claim below is owned by a rule elsewhere (Surface 5, Surface 6–17, Direction 1–4, Sugar 1–2, Hard invariant 16, Hard invariant 20, Caveman 1, Caveman 2). Normative states WHAT. WHY explains why. UX presents how. Sugar shortens syntax and creates no semantics. AI generates WHY or UX from the normative surface, never the reverse. Nothing unstated is true because a reader expects it (Hard invariant 16, Hard invariant 20). Nothing omitted is supplied by context. Nothing is normative unless the parser can name it (Surface 2, Surface 18). Complex systems may require many rules; every rule stays simple (Caveman 1, Caveman 2).

WHY:
Strict Caveman grows slowly. Grace itself can grow enormously.

---

### 23. Changes

NOTE:
v0.35 (2026-09-11): local specs declare domain meaning, not GRACE meaning (Principle 9–11); the standard label families declared once, here (Standard label 1–3); the signature block admitted with one line per action, and the `rejected(…)` wording it carried from Recoverable Invocation dropped; the Terms card and the bracket marker read as the surface nothing, the `Terms ›` declaration the one owner (Surface 25–27). CR-8.

NOTE:
v0.34 (2026-09-11): labels are words — the name of the heading a rule sits under, then a number (Rule shape 7, Rule shape 8); every label in this document, Recoverable Invocation, Audit Trail and Lease relabelled; a cross-spec reference names the spec before the label (Hard invariant 28). No form admitted or removed.

NOTE:
v0.27–v0.33, the council's reads and the labels before v0.34 are archived in git history (`git log -- GRACE-lang.md`, last commit before the relabel `e80fd21`).

NOTE: End of GRACE-lang. We love you. 🖤

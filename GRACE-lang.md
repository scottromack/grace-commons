# GRACE lang v0.31 — Minimal Earned Grammar

## Grace lang is a controlled semantic metalanguage for domain specifications.

#### NOTE: Grace UX is abstracted microcopy and interaction behavior derived from verified logical state.

Status: the current version and its history are §23; this line states nothing else.
Date: 2026-09-11

NOTE:
This document obeys itself. A fenced block is classified by its first line (S17): a labelled rule opens a normative block, a surface prefix opens that surface, anything else is a parse error. Everything outside the fences and the `Terms ›` lines carries nothing (S2a); `WHY:` and `NOTE:` label it for readers. The vocabulary the document's own rules use is declared in §13.

---

### 1. Core Principles

```text
G1: The grammar MUST contain only forms earned by repeated use in real specifications.
G2: §21 MAY admit a form ONLY IF the form's concept recurs across specifications AND the concept satisfies contested.
G3: §21 MUST NOT admit a form on one occurrence.
G4: The grammar MAY admit sugar.
G5: The grammar MUST NOT admit inference.
G6: Complexity MUST live in the number and arrangement of simple rules.
G7: Complexity MUST NOT live in the grammar of one rule.
G8: The maintainer MUST decide EVERY admission under G2.
G9: The council MAY advise on admission.
G10: The council MUST NOT admit a form.
G11: The council MUST elect the council president.
G12: The council president MUST carry the council's advice to the maintainer.
```

Terms › `contested`: the concept's free-prose expression drifted, was read two ways, OR produced a finding.

Terms › `maintainer`: the human in charge of the corpus — president of all; decides admission.

Terms › `council`: the reviewers a draft is run past, headed by the council president; advisory; each read is cited in §23 the way a git commit is; members to date: Claude, Kimi, Gemini, GPT, GLM, Grok, Mistral.

Terms › `council president`: elected by the council (G11); heads the council's read and carries the council's advice to the maintainer (G12); currently Claude.

WHY:
The test is the concept, not the token: a token appears only after its form is admitted, so counting tokens is circular. Recurrence alone admits noise. Counts follow `pressure-testing.md` §*Measure the form, not the word*. S4 owns *states WHAT*; the former G8 was its mirror.

---

### 2. Surfaces

Terms › `surface`: `normative` | `WHY:` | `UX:` | `PROVISIONAL:` | `NOTE:` | `nothing` (a line outside every fenced block and outside a Terms › declaration).

```text
S1: EVERY line MUST belong to exactly one surface.
S2: The parser MUST read an unprefixed line in a normative block as normative.
S2a: The parser MUST NOT read a line outside a normative block as normative.
S3: EVERY normative line MUST parse.
S4: A normative line MUST state WHAT.
S5: WHY: MUST NOT create, satisfy or alter an obligation, an enumeration or a reverse-diff result.
S6: A reader MUST NOT infer normative GRACE from WHY:.
S7: A human or AI MAY generate WHY: from normative GRACE.
S8: A writer MAY regenerate or discard WHY: at any time.
S9: UX: MUST NOT create behavior absent from normative GRACE.
S10: UX: MUST NOT alter normative meaning.
S11: A reader MUST NOT infer normative GRACE from UX:.
S12: A writer MAY write UX: warm, explanatory or context-specific.
S13: A provisional form MUST NOT carry normative force.
S14: The parser MUST ignore WHY:, UX:, NOTE: and PROVISIONAL: lines.
S15: A system MUST obey EVERY normative line.
S16: A system MUST NOT obey WHY:, UX: or NOTE:.
S17: The parser MUST classify a fenced block by the block's first line: a labelled rule opens a normative block; a surface prefix opens that surface.
S17a: The parser MUST reject a fenced block whose first line is neither a labelled rule nor a surface prefix.
S18: A surface prefix on a block's first line MUST cover every line of the block.
S18a: A surface prefix on a later line of a normative block MUST cover that line alone.
S19: The parser MUST read a line outside every fenced block and outside a Terms › declaration as the surface nothing.
S20: A system satisfies a MAY rule vacuously; a MAY rule obliges nothing.
```

Terms › `normative block`: a fenced text block of labelled rules, or a `Terms ›` declaration — a spec's whole normative surface (`spec-format.md` §*The normative surface*).

Terms › `normative`: unprefixed Strict Caveman (§20) inside a normative block.

Terms › `run`: one execution of a system.

Terms › `conformance failure`: a run that violates a rule.

Terms › `obey`: a system obeys a rule when every run of the system satisfies the rule's obligation under the rule's condition; a run that does not is a conformance failure, decided from records by the spec's acceptance checks (Generation acceptance: `spec-format.md`); an inequality rule (B9) obliges the party that binds the terms.

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

NOTE: `hold_bound` is the example's term; the arithmetic lives in the declaration, never in the rule (I24).

---

### 3. WHAT / WHY / HOW

```text
NOTE:
Normative = WHAT
WHY       = WHY
UX        = HOW
```

WHY:
Only the normative line carries meaning the system must obey (S15, S16). WHY and UX are downstream and disposable.

---

### 4. Direction of Generation

```text
D1: A writer MAY generate WHY: from normative GRACE.
D2: A writer MAY generate UX: from normative GRACE.
D3: A writer MUST NOT generate normative GRACE from WHY:.
D4: A writer MUST NOT generate normative GRACE from UX:.
D5: A drafter MAY use fuzzy intent while drafting.
D6: A written normative rule MUST stand alone and pass every GRACE check.
D7: A writer MUST NOT keep fuzzy intent as a source of truth.
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

Terms › `label`: a letter family, a number, and an optional lower-case letter — `G1`, `A3a`, `I13a`; unique within a spec.

Terms › `rule form`: `LABEL: statement` on one line, or `LABEL: WHEN condition:` followed by indented child rules each in rule form.

Terms › `child`: a rule inside a WHEN block.

```text
R1: EVERY rule MUST carry a label.
R2: EVERY statement MUST match one statement shape.
R3: A normative sentence MUST carry exactly one obligation.
R4: A writer MUST write a copula enumeration as a value-set declaration.
R5: A writer MUST NOT write a copula enumeration as a rule.
R6: EVERY rule MUST match the rule form.
```

NOTE: a copula enumeration is *X is one of a, b, c*.

---

### 6. Earned Vocabulary

Terms › `quantifier`: `EVERY` | `EXACTLY ONE` | `EXACTLY ONE OF` (an exclusive choice among named outcomes).

Terms › `modal`: `MUST` | `MUST NOT` | `MAY`.

Terms › `condition operator`: `=` | `!=` | `EXISTS` | `NOT EXISTS` | `EXCEEDS` | `AND` (flat) | `OR` (flat, inclusive).

```text
V1: A condition MUST NOT mix AND and OR.
V2: A writer MUST route a mixed condition through a declared term.
V3: A rule MUST NOT carry OR in an obligation or between obligations.
V4: A writer MUST write an exclusive choice as EXACTLY ONE OF.
V5: A condition MUST NOT nest.
```

---

### 7. Earned Tails

Terms › `tail`: `ONLY AFTER term` | `ONLY IF condition` | `WITHIN term` | `PER term` | `BEFORE term` (under `MUST NOT` only, B5).

```text
T1: A reader MUST NOT infer beyond a tail's text.
```

WHY:
`ONLY IF` is admitted by G2: the concept recurs, and gate 12 F1's repair is the finding. `ONLY UNDER` is provisional (§18): no controlled use, no finding.

```text
NOTE:
/people MAY serve actor ONLY IF invite_actor EXISTS OR grant_permission EXISTS.
```

---

### 8. Timing and Bounds

```text
B1: A writer MUST write a positive lower-bound ordering as: actor MUST action ONLY AFTER term.
B2: The parser MUST normalize actor MUST action AFTER term to actor MUST action ONLY AFTER term.
B3: The parser MUST normalize actor MAY action AFTER term to actor MAY action ONLY AFTER term.
B4: A writer MUST NOT write AFTER under MUST NOT.
B5: A writer MUST write a forbidden-before ordering as: actor MUST NOT action BEFORE term.
B6: A writer MUST NOT write positive MUST … BEFORE.
B7: A writer MUST write a deadline as: IF measure EXCEEDS bound THEN actor MUST NOT action.
B8: A writer MUST write a completion window as: actor MUST action WITHIN bound.
B9: A writer MUST write ≥ as: term MUST NOT EXCEED term.
B10: A writer MUST NOT write AT LEAST.
B11: A writer MUST NOT write STRICTLY.
B12: A writer MUST write a strict lower bound as: actor MAY action ONLY IF term EXCEEDS term.
B13: A reader MUST NOT infer timing from rule order.
```

WHY:
`run_floor MUST NOT EXCEED run_bound` means `run_bound ≥ run_floor`. B12 is no new form — a permission gated on a condition; `instance MAY start ONLY IF compensation_window EXCEEDS worst_closure`. A prohibition past an instant is B7, which is why B4 admits no `AFTER` under `MUST NOT`. Positive `MUST … BEFORE` smuggles a liveness claim into an ordering claim; liveness goes through `WITHIN`.

---

### 9. WHEN Blocks

```text
W1: The parser MUST read EVERY child of a WHEN block as an independent rule.
W2: A reader MUST NOT infer ordering among the children of a WHEN block.
W3: A WHEN block MUST NOT nest.
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
A1: A writer MUST write authority as: subject IS AUTHORITATIVE FOR proposition.
A2: A synonym MUST NOT carry authority semantics.
A3: Two specs MUST NOT claim authority for one proposition.
A3a: The parser MUST treat two propositions as one proposition ONLY IF the propositions normalize identically (X3).
A4: A citing spec MUST name the owner.
A5: A citing spec MUST NOT restate the rule.
```

WHY:
No synonym — `canonical`, `source of truth`, `primary` — carries authority semantics. A site is one spec (`pressure-testing.md` §*One site is one spec*). `IS AUTHORITATIVE FOR` is an introduced form, not a discovered one: the concept is earned (three consecutive gates; DRY on responsibility depends on it), the phrasing was minted 2026-09-10 in Recoverable Invocation and propagated only after use. It is the grammar's one labelled exception to G1.

---

### 11. Hard Invariants (parser-enforced)

```text
I1: The parser MUST reject an unprefixed line in a normative block that does not parse.
I2: The parser MUST reject a normative rule with no explicit subject.
I3: The parser MUST reject a normative rule with no explicit modal where the statement shape requires one.
NOTE: I4 deleted in v0.28; §13 owns the rule.
I5: The parser MUST reject a normative rule carrying a pronoun.
I6: The parser MUST reject a normative sentence carrying two obligations.
I7: The parser MUST reject a nested WHEN block.
I8: The parser MUST reject a condition mixing AND and OR.
I9: The parser MUST reject OR outside a condition or a term declaration.
I10: The parser MUST reject BEFORE outside MUST NOT.
I11: The parser MUST reject AFTER outside ONLY AFTER or the deterministic sugar.
I12: The parser MUST reject a positive MUST-BEFORE ordering.
I13: The parser MUST resolve a cross-rule reference by label.
I13a: The parser MUST reject a cross-rule reference by ordinal.
I14: The parser MUST reject a value used with = or != that belongs to no declared closed value set.
I15: The parser MUST NOT infer from rule order.
I16: The parser MUST NOT infer from the absence of a rule.
I17: The parser MUST NOT infer exclusivity among outcomes unless EXACTLY ONE OF states the exclusivity.
I18: The parser MUST normalize sugar without adding meaning.
I19: The parser MUST normalize EVERY sugar form to exactly one canonical form.
I20: The parser MUST NOT infer missing semantics.
I21: The parser MUST NOT give WHY: normative force.
I22: The parser MUST NOT give UX: normative force.
I23: The parser MUST NOT infer normative meaning from WHY: or UX:.
I24: The parser MUST reject arithmetic in a rule.
I25: The parser MUST reserve the label a tombstone carries.
I26: A writer MUST NOT renumber an invariant.
I27: A writer MUST NOT reuse a tombstoned label.
I28: A cross-spec reference in a normative block MUST qualify the label with the spec's name, as spec::label.
```

Terms › `tombstone`: a `NOTE:` line inside a normative block whose text begins with a label followed by the word `deleted`; recognized by that form alone (I25, I27).

WHY:
§11 is the parser's contract; the writer-facing rules that mirror it (R3, W3, V1, U2, B4, B6) oblige a different actor, and the two are kept as two norms on purpose. A cross-reference survives a version because labels never move (I26, I27) and never collide across specs (I28): Recoverable Invocation's `R25` and this document's `R2` are `Recoverable Invocation::R25` and `GRACE-lang::R2`.

---

### 12. Sugar Rule

```text
U1: Sugar MAY shorten a rule.
U2: Sugar MUST NOT add information.
U3: A writer MUST NOT place a sentence that matches no admitted form and no deterministic sugar in a normative block.
```

```text
NOTE: the sugar and its normalization.
NOTE: sweep MUST run AFTER examine_edge.
```
```text
NOTE: sweep MUST run ONLY AFTER examine_edge.
```
```text
NOTE: PER and a cadence, exercised once; the examples in this document borrow Recoverable Invocation's vocabulary and are exemplars, not citations — I28 does not reach a NOTE:.
NOTE: sweep MUST examine PER reconciliation_cadence.
```

---

### 13. Closed Vocabulary

```text
C1: EVERY specification MUST declare the specification's own closed vocabulary.
C2: A vocabulary MUST carry EVERY category the specification uses, from the category value set.
C2a: A vocabulary MUST declare a category with no member as empty.
C3: EVERY normative identifier MUST resolve to a declaration.
C4: The parser MUST NOT infer a term's type from the term's name.
C5: A specification MUST declare record verbs explicitly.
C6: A record MUST NOT acquire behavior from the record's noun.
C7: A rule carrying a modal MUST carry a declared record verb or a reserved grammar verb after the modal.
C7a: The IS AUTHORITATIVE FOR shape carries no modal and is outside C7.
C8: A rule MUST name a term where the rule needs arithmetic.
C9: A writer MUST write a declaration in the declaration form.
C10: A definition MAY carry arithmetic, comparison operators, a value set, or a sentence saying what the name is.
C11: A writer MUST write a definitional sentence as a declaration.
C11a: A writer MUST write a value set in the value-set form.
C12: A writer MUST NOT write a definitional sentence as a rule.
C13: A declaration MAY cite the declaration's owner instead of restating the definition.
C14: The parser MUST resolve a cited declaration against the owner's Terms registry, migrated or not.
C15: A specification MUST NOT redeclare a constituent's term.
C16: A specification MUST NOT declare EXCEED or IS AUTHORITATIVE FOR as record verbs.
```

Terms › `category`: `actor` | `record` | `record verb` | `value set` | `bound` | `cadence` | `term` | `qualifier`.

Terms › `declaration form`: `Terms › name: definition.` on one line, the name in backticks.

Terms › `value-set form`: member names separated by `|`.

Terms › `name`: a spec's name is the spec's file stem; this document's is `GRACE-lang`.

Terms › `definitional sentence`: *X is Y*, *X counts Z*, *the key is (kind, act_key)* — a sentence with no modal.

Terms › `reserved grammar verbs`: `EXCEED` (in `MUST NOT EXCEED`) and `IS AUTHORITATIVE FOR` carry grammar semantics; a specification never declares them as record verbs. Every other verb in a rule is a record verb the specification declares.

Terms › `identifier`: a subject, an object, a term name or a value in a rule; every identifier resolves to a declaration (C3).

WHY:
A named expression has one owner, and a diff can match it by name. C7 is what rejects the passive — *The actor MUST be granted invite_actor* has no declared record verb after the modal — which is why the former I4 was a second owner and was deleted. A citation form lets a composition use a constituent's term without restating it.

```text
NOTE:
record verb record_action: Audit Trail
```

#### This document's own vocabulary

Terms › `actors`: the grammar; §21 (the lock list); the parser; a specification (a spec); a rule; a statement; a sentence (a rule's text); a condition; a form; a sugar form; a term; a declaration; a WHEN block; a tail; a surface; a system; a reader; a writer; a drafter; a human; AI; the reverse diff; the normalized form (the representation); fuzzy intent; a value set; a value; an enumeration; a synonym; a citing spec; an owner (the spec that declares a term); a registry (a spec's Terms section); `WHY:`; `UX:`; `NOTE:`; `PROVISIONAL:`; sugar; complexity; arithmetic; a label; an obligation; a proposition; an invariant; a tombstone; an ordinal; a pronoun; a line; a fenced block; a party; a run; a maintainer; a council; a child; a category.

Terms › `record verbs`: decide, advise, contain, admit, recur, satisfy, live, state, read, parse, create, alter, infer, generate, regenerate, discard, write, obey, ignore, carry, use, stand, pass, route, mix, nest, normalize, name, restate, resolve, cite, declare, acquire, redeclare, renumber, reuse, enumerate, reject, lower, report, treat, assume, keep, express, mark, shorten, add, accept, supply, earn, belong, cover, classify, claim, qualify, give, match, place, bind.

Terms › `qualifiers`: `ratified` — accepted into §21 by G2; `migrated` — rewritten in this language.

Terms › `records`: empty.

Terms › `bounds`: empty.

Terms › `cadences`: empty.

Terms › `terms`: `contested`, `hold_bound`, `run_floor` (the examples' terms), and every other name declared in this document.

Terms › `value sets`: surface (S1); quantifier, modal, condition operator (§6); tail (§7); diff result — `ADDED` | `REMOVED` | `CHANGED`; category — actor | record | record verb | value set | bound | cadence | term.

---

### 14. Closed Value Sets

```text
Z1: A value set MUST enumerate every admitted value.
Z2: The parser MUST reject an undeclared value.
Z3: A value set MUST NOT carry an implicit other.
```

---

### 15. Canonical Examples

```text
NOTE: exemplars in Recoverable Invocation's vocabulary, not citations; the labels are illustrative.
R20:
IF commit = unknown THEN invocation MUST yield.

R25:
EVERY writer MAY write outcome ONLY IF section_lease EXISTS.

R26:
operator MUST NOT resolve BEFORE acquiring section.

R27:
sweep MUST reconcile AFTER examine_edge.
```
```text
NOTE: R27 normalizes to `ONLY AFTER`.
R38:
IF intent_age EXCEEDS retention_edge THEN sweep MUST NOT examine intent.

R41:
run_floor MUST NOT EXCEED run_bound.
```

Terms › `run_floor`: 2 × closure_latency + journal_write_bound.

---

### 16. Normalized Form

```text
N1: The parser MUST lower EVERY parsed rule to an explicit structural representation.
N2: The representation MUST carry only information present in the normative source or added by a ratified deterministic sugar rewrite.
N3: The representation MUST NOT carry information from WHY:, UX:, NOTE:, PROVISIONAL: or context.
```

---

### 17. Reverse Diff

```text
X1: The reverse diff MUST compare normalized normative obligations.
X2: The reverse diff MUST report ADDED, REMOVED and CHANGED.
X3: The reverse diff MUST treat two forms that normalize identically as equivalent.
X4: The reverse diff MUST NOT assume equivalence otherwise.
X5: The reverse diff MUST NOT report a change to WHY: or UX:.
```

---

### 18. Candidate Forms

```text
P1: The parser MUST treat a form as provisional until §21 admits the form.
P2: A spec MUST state a degraded rule in admitted forms under IF or WHEN.
P3: A spec MUST mark a DEGRADES TO pairing PROVISIONAL:.
```

```text
PROVISIONAL: ONLY UNDER
PROVISIONAL: IS DERIVED FROM
PROVISIONAL: COMPOSES / BINDS
PROVISIONAL: positive MUST … BEFORE
PROVISIONAL: <strong rule> DEGRADES TO <weak rule>
PROVISIONAL: signature block — name(args) → result | rejected(code | …)
PROVISIONAL: "land release and rejected(code)" as sugar for two obligations
```

WHY:
`DEGRADES TO` is a pairing slot for a degraded guarantee: the condition stays on the strong rule's `ONLY IF`, the slot carries none, so the pairing adds no third rule — the reverse diff sees the strong rule and the weak rule, and the `PROVISIONAL:` pairing line is invisible to it (S14). Recoverable Invocation uses it four times, states each weak rule under `IF`, and marks the pairing provisional — the contested history §1 requires. The signature block is every action's contract in the corpus and has no declaration form here; the release-and-reject idiom recurs at every refusal site. Both wait on G2.

---

#### Watch list — pressure the rewrite may find, flagged and counted, not admitted

NOTE:
During the corpus rewrite, no grammar is added preemptively. A rewriter flags recurring pressure at the site, as `NOTE: watch <pressure>` beside the rule that strained, and recurrence is the count of flags across specs. Most of these are expected to collapse into declared domain terms rather than new grammar. Watched: persistent state (cases that want `WHILE`); applicability (cases that want `WHERE`, or feature-present gating); cardinality (needs beyond `EVERY`, `EXISTS`, `EXACTLY ONE`, `EXACTLY ONE OF`); condition negation (where `!=`, `NOT EXISTS` and `MUST NOT` are not enough); event versus state (where the distinction matters enough that terms alone become awkward); contradiction (two rules normalizing to `X MUST a` and `X MUST NOT a` under identical conditions — nearly free to detect after normalization, and waiting for its finding); satisfaction (where `obey` is not enough: what a violation of `WITHIN` is, compensate or nonconform). The rule: flag first, count recurrence, admit nothing until the corpus forces it (G1–G3).

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
One occurrence is never enough (G3).

---

### 20. Strict Caveman

Terms › `Strict Caveman`: short sentences; one obligation per sentence; explicit subject, modal, action and object; explicit condition when needed; one canonical term for one meaning; no pronouns; no rhetorical dependency; no hidden implication.

```text
K1: A writer MUST express complex behavior as more simple rules.
K2: A writer MUST NOT express complex behavior as a more complicated sentence.
```

---

### 21. What v0.29 Locks

Terms › `locked forms`: Strict Caveman normative prose; WHAT / WHY / HOW separation; `WHY:` and `UX:` with zero normative force; `MUST` / `MUST NOT` / `MAY`; `EVERY` / `EXACTLY ONE` / `EXACTLY ONE OF`; flat `IF` and flat `WHEN`; flat `AND`, flat `OR`, never both in one condition; `OR` only inside conditions and term declarations; `=` / `!=` / `EXISTS` / `NOT EXISTS` / `EXCEEDS`; `ONLY AFTER` / `ONLY IF` / `WITHIN` / `PER`; `MUST NOT EXCEED` for ≥, no `AT LEAST`, no `STRICTLY`; the strict lower bound as `MAY … ONLY IF … EXCEEDS …`; `IS AUTHORITATIVE FOR` (introduced, labelled); one site is one spec; forbidden-before (`MUST NOT … BEFORE`); deterministic `AFTER` sugar under `MUST` and `MAY`; positive `MUST … BEFORE` illegal; one obligation per sentence; closed vocabulary including record verbs; the `Terms ›` declaration form; a declaration may cite its owner; arithmetic only in term declarations; closed value sets; no pronouns, §13 rejects the passive; no inference; normalized representation; reverse diff over normalized rules; admission by G2 — recurrence AND contested.

```text
Q1: The parser MUST accept only the locked forms and their deterministic sugar.
Q2: §21 MUST NOT admit a form outside the locked forms except by G2.
```

---

### 22. Core Rules

NOTE: a recap; every claim below is owned by a rule elsewhere (G8, S5–S16, D1–D4, U1–U2, I16, I20, K1, K2). Normative states WHAT. WHY explains why. UX presents how. Sugar shortens syntax and creates no semantics. AI generates WHY or UX from the normative surface, never the reverse. Nothing unstated is true because a reader expects it (I16, I20). Nothing omitted is supplied by context. Nothing is normative unless the parser can name it (S2, S17). Complex systems may require many rules; every rule stays simple (K1, K2).

WHY:
Strict Caveman grows slowly. Grace itself can grow enormously.

---

### 23. Changes

NOTE:
v0.28 (2026-09-10), settled by the v0.27 review (git `d87af8b`): admission by concept and only where the prose has failed (G2); `ONLY IF` admitted, `ONLY UNDER` provisional, `IS AUTHORITATIVE FOR` labelled introduced; `OR` inside conditions and term declarations only, `AND` or `OR` never both, exclusive choice is `EXACTLY ONE OF`; `≥` written `MUST NOT EXCEED`; `DEGRADES TO` provisional; arithmetic only in term declarations; I4 deleted, §13 owns the rule; one site is one spec; a declaration may cite its owner. Clarified after the Recoverable Invocation rewrite and the council's read: the strict lower bound (B12), the declaration syntax and definitional sentences (C9–C12), the `AFTER` sugar under `MAY` and its absence under `MUST NOT` (B3, B4), the tombstone (I25, I26), the reserved grammar verbs (C16), and this document's own vocabulary.

NOTE:
v0.29 (2026-09-11): the normative surface fixed as fenced rule blocks plus `Terms ›` declarations (S2, S2a, I1, U3; `spec-format.md` §*The normative surface*); the document rewritten in the language it defines — every normative claim a labelled rule in an admitted form, every explanation under `WHY:`, every example and process note under `NOTE:`, the document's own vocabulary declared. No form admitted or removed. Labels: G §1, S §2, D §4, R §5, V §6, T §7, B §8, W §9, A §10, I §11, U §12, C §13, Z §14, N §16, X §17, P §18, K §20, Q §21.

NOTE:
v0.30 (2026-09-11), after the council's self-hosting read: copula enumerations are value-set declarations (R4; `surface`, `statement shape`, `object` declared); a fenced block is classified by its first line and a prefix covers the block (S17–S19); the tombstone has a syntax (I4 as a `NOTE:` line, I25, I27); §11 speaks with the parser as subject, so the writer-facing mirrors are distinct norms; labels are namespaced across specs (I28); `obey` and `identifier` declared; the reserved-verbs line reworded; A3 restated without a fronted quantifier and given an identity test (A3a); §22 is a recap, not a second owner; the self-vocabulary closed; `PER` exercised once. No form admitted or removed.

NOTE:
v0.31 (2026-09-11), after the council's read of v0.30: C7 carves out the reserved grammar verbs and puts the IS AUTHORITATIVE FOR shape outside its scope (C7a); the surface algebra closes — `nothing` joins the surface value set, S2 reads unprefixed lines only, S17a rejects, S18a covers a later-line prefix, S20 makes MAY vacuous; the sub-grammar is declared — `label`, `rule form`, `child`, `declaration form`, `value-set form`, `category`, `name`; C2 asks for the categories a spec uses and declares the empty ones; the tombstone is recognized by form alone; I28 is scoped to normative blocks and the examples are marked exemplars; `run`, `conformance failure`, `maintainer`, `council` declared; the maintainer — the human in charge, president of all — decides admission on council evidence, the council headed by an elected president, currently Claude (G8–G12); the status line derives from §23; the old G8 folded into S4. No form admitted or removed.

NOTE: End of GRACE lang ❤️

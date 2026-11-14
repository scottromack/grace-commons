---
title: Execution Contract — history
nav_exclude: true
search_exclude: true
---

# Execution Contract — history

The dated record of how the [Execution Contract](./execution-contract.md) got here, moved out of the contract on 2026-11-14 because a reader does not need it to use the contract today (unit `execution-contract.md: history and stale names go to the record`): the sentences that told a rule's history and the dated asides, each under the label of the rule it stood in; the paragraphs *One home for a shared obligation* and *Current status*; the section *A-stack reference implementation*, whole, with the page's other sentences naming A-stack, since the site names its reference implementation Beacon; the asides naming headings no pattern carries; and the six tombstones, Store 1 through 5 and History 1. Every piece below is byte for byte as the page carried it; the contract keeps every rule and its words, and everything smaller is in `git log -- execution-contract.md`.

## Moved from the contract

Under each heading of the page, the label of the rule or the paragraph each piece stood in, then the piece. A piece that was part of a sentence is given as it stood, the sentence on the page reading whole without it.

### The opening, above Core claim

- *the opening paragraph* (A-stack; the page now reads “Beacon — the reference implementation — is the worked instantiation of the contract, not the contract itself.”): A-stack — the reference implementation in Deno + PostgreSQL + JSX — is the worked instantiation of the contract, not the contract itself.

### Logic Confinement Principle

- *Logic confinement 3: Explicit inputs only.* (history): Nine specifications once tombstoned that rule to this label, each in the Final Critique that cured it.

- *Logic confinement 8: A mechanism computes at the seam.* (history): Four specifications once stated it for themselves, each declaring its value as computed at the seam and injected.

- *Logic confinement 9: Arithmetic is exact.* (history): Cart once stated it for itself, as its Capability requirement 4.

- *Logic confinement 10: A string's order is its code point order.* (history): Eight specifications once named a byte order over a string for themselves, and Credential's Final Critique 18 found that a byte order names no encoding: a UTF-8 build and a UTF-16 build order U+E000 and U+10000 apart.

- *Logic confinement 11: `now` is the clock reading at the call.* (history): Forty-one specifications once declared `now` for themselves, thirty-three of them saying this section declared it before any rule here did.

- *Logic confinement 12: An instant a call leaves blank is `now`.* (history): Seven specifications once resolved a blank instant to `now` for themselves, each by a rule or by a term for the resolved instant.

- *Logic confinement 13: A reference is canonicalized at the seam.* (history): Five specifications once stated it for themselves, each in the Final Critique that found a deployment canonicalizing as it wrote recording what another compared at the seam, and six more wrote it with no place.

- *Logic confinement 14: The seam, the transition and the business caller.* (history): Fourteen specifications once dropped a citation of the three words that resolved to nothing, each in the Final Critique that found it (GRACE-lang Closed vocabulary 16), keeping their own definitions.

- *Logic confinement 15: A setting with no default is required at start.* (history): Nine specifications once wrote the cure for themselves, refusing the start on a blank setting or writing the default that sets the setting, each where one build read the condition over the blank setting as failing and refused the start while another started and ran on the blank setting.

*One home for a shared obligation* (moved whole):

**One home for a shared obligation.** An obligation the deployment owes every specification is written once, here, and each specification cites it — Logic confinement 3's single clock reading was the first such obligation, Logic confinement 7's guarantees the second, Logic confinement 8's computation at the seam the third, Logic confinement 9's exact arithmetic the fourth, Logic confinement 10's string order the fifth, Logic confinement 11's `now` the sixth, Logic confinement 12's blank instant the seventh, Logic confinement 13's canonical form the eighth, Logic confinement 15's required setting the ninth, and Logic confinement 16's single supply of an allocated id the tenth, and Logic confinement 17's setting held from its start the eleventh. Twenty-five specifications once restated the clock's guarantees as sixty capability requirements.

*Current status* (moved whole):

**Current status.** The Beacon reference implementation satisfies Logic confinement 1, 2, 3 and 6 fully — against Logic confinement 3 as it stood when Beacon was built: Beacon reads the clock at Step 3, predating the 2026-07-12 placement revision (clock read at the top of Step 2, shared by G and T — see Pipeline). The injection principle holds in Beacon; the step-placement update rides the same projector build phase as Logic confinement 4 and 5. Logic confinement 4 (explicit construction / `createEvent` before `appendEvent`) and Logic confinement 5 (compiler-emitted invariant assertions) are targeted for the projector build phase — the gap is tracked as methodology debt #7 in the section titled Methodology debts in [`roadmap.md`](./roadmap.md) (the projector / verification-harness deliverable). The principle is stated here as a first-class commitment, not a retrospective description of the demo.

### The three primitives › State Machine (SM)

- *the paragraph on action return values (R)* (a heading no pattern carries): “; it is generated from the atom's Outputs section (action return specifications)”

### The execution pipeline

- *Clock and ID are injected, never called from within G or T.* (dated aside): *(Placement revised 2026-07-12: this section previously read the clock at the top of Step 3, after guards — which left temporal guards, e.g. Approval Step's reject-future-timestamp and resolved-value ordering bounds, with no legitimate clock access, since a pure G may not invoke a direct effect. Surfaced by the 2026-07-12 scheduled rescan of Approval Step and Party Identity.)*

### Atom compilation rules › Section-name classification

- *Compiling — atom shape: Operations* (a heading no pattern carries): “— what the prose shape carried as Inputs, Outputs, Decision points and Behavior, with the description and validation rules of Inputs among them”

- *Compiling — composition shape: Capability requirement* (a heading no pattern carries): “; titled Configuration before migration”

- *Compiling — composition shape: Primitive policy* (a heading no pattern carries): “; titled Primitive policies before migration”

- *Compiling — regulated overlay: Conformance checks* (a heading no pattern carries): “; titled Record checks in the prose shape”

- *Non-compiling (named): Wiring decision* (a heading no pattern carries): “; titled The load-bearing wiring decision before migration”

- *The section-name lint check* (dated aside): “(landed at council read 80)”

### Atom compilation rules › Regulated atoms

- *Generation acceptance 1: A check comparing a record with an earlier state reads its committed versions.* (history): Thirteen specifications once wrote such a check as an auditor's later read compared with an earlier one, and five Final Critiques pointed theirs at the committed versions, each after a round found a build with no earlier read to compare passing a deployment that broke the rule the check names.

### Composition model

- *the paragraph on orchestration state* (dated aside): “(adjudicated 2026-06-10)”

### Composition model › Composition state

- *the section's opening note* (dated aside): Adjudicated 2026-06-10, Refactor 1.

- *the section's opening paragraph* (a heading no pattern carries): “(titled `Application state` until the 2026-06-11 vocabulary sweep migrates each heading)”

- *Derived index 1: A missing entry is rebuilt before an action decides on it.* (history): Five specifications once ordered the rebuild first for themselves, each in the form `MUST NOT … BEFORE rebuilding`, in the Final Critique that found one build rebuilding the entry and deciding on its records while another decided on the miss.

*the paragraph on the inconsistency the section resolved* (moved whole):

This section resolves an inconsistency this document previously carried in three passages at once: the composition model's no-persistent-state rule, a wiring-layer example citing Idempotent Reservation's token-result cache approvingly, and a data-layer clause filing `token_results` under atoms with multiple record types while the A-stack section calls Idempotent Reservation the first composition. The rule above replaces all three readings: the cache is real, it is non-derivable, and it is therefore extraction-pending — not an atom's second record type, and not sanctioned composition records.

### Composition model › The atom interface contract

- *Atom interface 1: A composing pattern changes a constituent's records only through the constituent's declared actions.* (history): Nine atoms once wrote, as a composition note, that a composing pattern reading their records MUST NOT write to them, which forbade the call a composing action makes through the atom's own action after its read, so one build obeyed the note while another delivered the composer's wiring; six Final Critiques tombstoned the note, and the sweep that wrote this rule cut the other three.

### Composition model › Scheduled legs

- *Scheduled leg 1: The deployment supplies a scheduled leg's starter.* (history): Five specifications once supplied a starter for themselves, each a scheduler its own rules named, and Recoverable Invocation's Final Critique 24 found the page writing its cadence and no starter, so one build ran its sweep only at restart, or from a timer inside one process, while another kept the window.

### Composition model › Substrate composition invocation

- *the section's opening paragraph* (dated aside): *(Added 2026-06-10, Refactor 1.)*

- *Constituent failure 1: A constituent's storage-failure is the composing action's.* (history): Five Final Critiques cured a composition whose rewrite onto the Database contract had taken the old storage arm away, so that no rule landed a constituent's storage-failure, and fourteen rules on six compositions restated this one.

- *Constituent failure 2: A constituent's registry-unavailable is the composing action's.* (history): Five Final Critiques cured a composition that landed a constituent's registry-unavailable nowhere, so that one build answered a code the composing action's signature did not carry and another a refusal its caller reads as final: two landed it where they land the constituent's storage-failure, keeping a signature many composers map, and three passed it through.

- *Constituent failure 3: A constituent's state-unavailable is the composing action's.* (history): Seven specifications once landed it for themselves, each in the Final Critique that found no rule landing it, so that one build passed it through and another answered it as the composition's own code.

- *Constituent failure 4: A substrate's recording-failure lands whatever step it carries.* (history): Eight specifications once landed Audit Trail's recording-failure(step-4) for themselves, each in the Final Critique that found an Audit arm landing only the append step's recording failures, so that one build answered intent, another outcome and a third the step.

### UI projection contract

- *the paragraph after `UI = render(Q(state))`* (A-stack): In A-stack, `render` is a JSX component function: `(result: ProjectionResult) => JSX.Element`.

### The Database contract

- *Database 6: An atom's no-removal rules bind the atom's own actions.* (history): Nine atoms once said so for themselves, each in the Final Critique that cured it, by deleting a rule written with no actor or by moving a check to their external checks.

- *Database 7: Every call goes to the same database instance.* (history): Twelve atoms once said so for themselves. Eight wrote *route EVERY call to one database instance*, which a deployment splitting the calls across two instances also obeys while a read misses the records the other instance holds; four had their Final Critiques cure it to the same database instance, and this rule takes Selective Disclosure's words.

### The Database contract › A family for every action: Read

- *the family's opening paragraph* (history): Ten atoms once stated them for themselves, each in the Final Critique that cured it. Read 4 says of every call an action does not admit what Read 2 says of a call whose read failed; five atoms once held their effect rules to the calls an action admits, each in the Final Critique that cured it.

### The Database contract › A family for every action: Refusal

- *the family's opening paragraph* (history): Twenty-two specifications once stated an order for themselves: twelve as a declared term listing an action's refusal rules earliest first, beside a rule that the action evaluates no rule of the order before every earlier one has answered no refusal, each written by the Final Critique that cured a pair of refusals firing together on one call, and the rest as rules answering one refusal only where another does not apply. Five atoms once narrowed a rule banning a refusal to the ground the rule meant, each in the Final Critique that cured it; Refusal 1's second sentence now reads every such rule that way.

### The Database contract › A family for every read: Query

- *the family's opening paragraph* (history): Five specifications once stated a range's ends for themselves, four of them in the Final Critique that cured a query two builds answered with two sets, and seven left them unsaid.

### The Database contract › A family for every write: Input

- *the family's opening paragraph* (history): Six specifications once held a supplied input to its type by a rule of their own, each in the Final Critique that found one build refusing a value outside the type where another recorded it. Nineteen specifications once took one of three postures toward the bound on an input, a cap the specification declared, a cap the deployment had to supply, or none; Input 2 gives all nineteen one.

- *Input 3: An input with no declared type is a string.* (history): Nine specifications once declared such an input's type and named its refusal for themselves, each in the Final Critique that found nothing but a reader's inference holding the input to a type.

- *Input 4: An admitted call records the required inputs its record keeps.* (history): Nine specifications once recorded such inputs by Operation rules of their own, each in the Final Critique that found a build recording a value of its own choosing while obeying every rule (GRACE-lang Hard invariant 20).

### Error model

- *Error model 1: A lost answer is none of the three.* (history): Ten specifications once stated it for themselves, eight of them in an Indeterminate outcome family.

### Conformance

- *Conformance 9* (history): Twelve atoms once carried such a check among their external checks, each written by the Final Critique that cured it.

- *Conformance 9* (history): “, as nine specifications did as a Capability requirement and seventeen write it as a Composition note”

- *the paragraph after Conformance 9* (A-stack): The A-stack reference implementation is a conforming implementation. It is not the only conforming implementation.

## A-stack reference implementation

A-stack is the reference runtime. It is the minimal conforming implementation — the smallest stack that exercises the full contract against real atoms without introducing abstractions the contract does not require.

| Layer | Technology | Rule |
|---|---|---|
| Runtime | Deno | Permission-explicit; TypeScript-first; no build ceremony |
| UI | JSX → pure functions | `(props: ProjectionResult) => JSX.Element`; no framework lifecycle |
| Data | PostgreSQL | Explicit parameterized SQL or Drizzle query-builder mode only |
| State machines | TypeScript discriminated unions | One union type per S; one typed function per event in E |
| Pipeline | Explicit per-transition | Steps 1–4 written out explicitly; no framework interpolates them |

The first two A-stack examples, in dependency order: **Personal Todo** (simplest atom — four actions, no regulated sections, covers the full pipeline with the description policy as a PF normalization example) and **Idempotent Reservation** (first composition — demonstrates multi-write atomicity in `place_hold`, the exactly-once emergent invariant, and the *extraction-pending* `token_results` records that the section titled Composition state classifies).

## Deleted rules

The contract's tombstones, moved here from the page on 2026-11-14 (GRACE-lang Hard invariant 25 and Term tombstone, since v0.71): each in the page's order, under the heading it stood under there, written in the one tombstone form `Deleted: Label. The owner, and why.` in place of the page's bold `**Label: Deleted.** The owner, and why.`, the owner and why word for word. A tombstone carries no obligation, and each still reserves its label: no rule of the [Execution Contract](./execution-contract.md) may carry it again, and a pattern's citation of it still resolves (`tools/grace/cites.py`, `check.py`, `ir.py` and `tools/linter/lint.py` read the contract's labels from the page and from this section).

### The Database contract

```
Deleted: Store 1. Database 1 owns it.
Deleted: Store 2. Database 2 owns it.
Deleted: Store 3. Database 3 owns it.
Deleted: Store 4. Database 4 owns it.
Deleted: Store 5. Database 5 owns it.
```

### The Database contract › A particular family: Order

```
Deleted: History 1. Database 5 owns it: since 2026-10-20 basic history is kept for every specification, not only for those that cite it.
```

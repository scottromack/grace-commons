---
title: Contributing
nav_order: 1
parent: Community
has_toc: true
toc: true
---

# Contributing to Grace Commons

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>


Grace Commons is early but stable (as of mid-June 2026). The pattern library is being built. This is the right time to help establish the structure — before conventions calcify and before the easy decisions get made by default.

---

## What we need right now

**Pattern proposals.** If you recognize a business logic pattern that recurs across domains and belongs in a shared library, we want to know about it. A pattern proposal does not need to be complete — a name, a brief description, and one or two examples from different domains is enough to start.

**Domain expertise.** The patterns that matter most are the ones that appear in regulated industries with formal standards behind them — healthcare, finance, logistics, government. If you work in one of these domains and recognize the problem this library is trying to solve, your knowledge of what the standards actually say is directly valuable.

**Honest criticism.** The architectural philosophy is in `the-spec-layer.md`. If you think it is wrong in ways that matter, say so. The most useful response is the honest one.

---

## Atoms vs. compositions

Grace Commons distinguishes **atoms** from **compositions**.

The test: does the contribution's specification name another atom? If no, it's an atom — store it flat as `atoms/<name>.md`. If yes, it's a composition — file it under `compositions/`.

Atoms are freestanding: state, actions, and operational principles independent of every other atom. Personal Todo, Duplicate Prevention, Event Log.

Compositions wire two or more atoms together with composition logic. Audit Trail (Event Log + retention + tamper-evidence + actor identity), Shared Todo (Personal Todo + Permissions + Assignment), Idempotent Reservation (Provisional Commitment + Duplicate Prevention).

If you are not sure which side your contribution falls on, open an issue. The overhead of a conversation is lower than the overhead of placing it in the wrong folder.

---

## What an atom looks like

A pattern spec lives flat in `atoms/` as `atoms/<name>.md` — classification is derived from the composition graph, not a folder (see [`atoms/TAXONOMY.md`](./atoms/TAXONOMY.md)). It is a structured natural language document, not code — because plain English is the form that includes every reader at once: business stakeholders, auditors, engineers, AI systems, future contributors. Inherit anything good from any source (formal-methods notation, ISO/IEEE standards, BDD, decision tables, design-by-contract, ADR templates, requirements-engineering identifiers); the output form is consistent. At minimum the spec should define:

- **Name** — clear, domain-neutral where possible
- **Intent** — what business need does this pattern address
- **Structure** — the logical shape: inputs, outputs, invariants, states
- **Examples** — the same pattern appearing in at least two different domains
- **Edge cases** — what the pattern does not cover, or where it breaks down
- **Standards references** — where relevant, anchors to ISO, IEEE, domain standards

Atoms do not need to be complete to be submitted. An incomplete atom with honest gaps marked as open decisions is more useful than a polished one with hidden assumptions.

### Additional sections for regulated atoms

Atoms operating in regulated domains carry two further sections beyond the base shape. Both emerged as Pass 3 findings on the first regulated atom in the library ([Provisional Commitment](./atoms/provisional-commitment.md)) and have since stabilized as required conventions for any atom — or composition built on one — whose acceptance bar is set by an external evaluator rather than an internal user. The full convention — what each adversarial read must show, and how the records-alone bar is cleared — is owned by the section titled *Regulated-pattern conventions* in [`pressure-testing.md`](./pressure-testing.md), and the overlay's one Examples subsection sits in the shapes of [`spec-format.md`](./spec-format.md); what follows is a contributor's orientation.

- **Regulated adversarial scenarios** — an `Examples` subsection walking the three reads external evaluators actually perform: *regulator audit*, *disputed transaction / data-subject request*, and *breach investigation*. (Worked examples: Provisional Commitment; [Actor Identity](./atoms/actor-identity.md).) **Required** for atoms carrying the regulated overlay and for atoms whose examples invoke regulated domains.
- **Generation acceptance** — a standalone section naming what a derived implementation must produce, judged *from the records alone* — the regulator's question (*"can you prove no commitment was confirmed after its declared window?"*), not the developer's intuition. **Required of every migrated spec**, in one of two shapes — a section carrying checks, or a declared decline naming the pattern that owns the audit surface. The bar is set by an external evaluator (regulators, auditors, integration partners) where one exists; where none does, the section makes the atom's own invariants testable. Presence is mechanical and [`tools/linter/lint.py`](https://github.com/scottromack/grace-commons/blob/main/tools/linter/lint.py) enforces it; see the section titled *Generation acceptance* in [`pressure-testing.md`](./pressure-testing.md) for why silence stopped being an option.

Both conventions also apply to compositions that compose regulated atoms. [Idempotent Reservation](./compositions/idempotent-reservation.md) is the worked composition example carrying both.

For non-regulated primitives, the *adversarial scenarios* are optional and often over-specification — Personal Todo's would be contrived. Use judgment; the test is whether an external evaluator with no developer access would have a meaningfully different verification surface from the atom's existing structure. *Generation acceptance* is not in that trade: it is required of every migrated spec, because a composition resting checks on a constituent has to be able to discover the constituent's posture without inferring it from an absence.

---

## What a composition looks like

A composition spec lives directly in `compositions/` (no subdirectories). It declares the atoms it composes and the logic that wires them together. At minimum it should define:

- **Name** — describes the composed result
- **Composes** — the atoms it brings together, by name and link
- **Composition logic** — how the atoms are wired: which actions in one trigger which in another, what policy parameters each atom is configured with, how cross-atom invariants are maintained
- **Composition-level invariants** — invariants that emerge from composition and don't belong to any single constituent
- **Examples** — concrete scenarios showing the composition in action
- **Edge cases** — failure modes that arise from composition, including conflicts between constituent atoms

Compositions are where the architecture is exercised. A reader should be able to verify, from the file alone, that the named atoms could plausibly compose to produce the claimed behavior.

Compositions that compose regulated atoms follow the same *Regulated adversarial scenarios* and *Generation acceptance* conventions as their constituent atoms. The composition's adversarial scenarios exercise the *emergent* invariants — what the composition guarantees that no single constituent does — and the composition's Generation acceptance bar adds checks that span the constituents (e.g., the token-to-commitment mapping in Idempotent Reservation). See [Idempotent Reservation](./compositions/idempotent-reservation.md) for the worked example.

---

## Verification layers

A Grace Commons spec participates in three distinct verification layers. Each catches a different class of defect at a different point in a pattern's lifecycle. None substitutes for the others.

**Layer 1 — Structured English and decision constructs (specification time).** The spec itself is the first verification layer. Structured natural language with explicit invariants, named rejection reasons, defended-in-line architectural decisions, and complete action signatures catches the class of defect that comes from ambiguity and incompleteness — the underspecified edge case, the invariant that has no corresponding action, the rejection reason with no name. Decision tables and decision trees may be embedded inline wherever conditional logic is complex enough to benefit from structured presentation. These constructs are self-explanatory and require no prose commentary beyond what the surrounding spec provides — they are the one class of structured construct that can appear without a human-readable gloss alongside it.

**Layer 2 — Formal models (design time).** Alloy and TLA+ catch the class of defect that structured language cannot: unknown unknowns — structural properties or behavioral sequences that no reviewer thought to probe. A three-pass review catches what a careful reader notices; a formal model catches what nobody thought to ask. Alloy checks valid-state invariants via bounded exhaustive search; TLA+ checks operation-sequence properties via model checking. Both run at design time, before any implementation exists. The Alloy model for Attributed Permissions Admin found a missing invariant that sixteen prose-review findings missed. See *Formal-model artifacts* below for conventions.

**Layer 3 — Property-based and exhaustive tests (implementation time).** Once a spec is compiled to running code via the Execution Contract, the spec's invariants become checkable properties in a property-based testing framework (Hypothesis, fast-check, QuickCheck). The framework generates and exhausts the input space against the stated properties, verifying that the implementation satisfies every invariant the spec declares. This layer does not live in the spec library — Grace Commons defers implementations — but it belongs in the pipeline that derives implementations from specs. The verification harness is derived directly from the Generation acceptance bar and the composition-level invariants. This approach has been demonstrated in practice; it is not yet codified as a formal convention in this library.

These three layers are the full verification stack. The spec is canonical; the formal model checks it before implementation; the property tests verify the implementation against it. The governing principle is the *minimum-formalism principle* in `pressure-testing.md` (the section titled *The minimum-formalism principle*): plain English by default, formalism introduced only when irreducible complexity requires it, high-logic tooling always under the hood.

---

## Formal-model artifacts

This section moved to [`pressure-testing.md`](./pressure-testing.md#formal-model-artifacts), which owns its subject; follow the link.

---

## Three perspectives

Grace Commons needs three mindsets in the core review of every pattern, not in separate committees:

- **Rigor (academic perspective).** Pressure-tests the formal properties. Catches missing invariants, incomplete state transitions, hand-waved decision logic.
- **Clarity (design perspective).** Forces brutal readability. Catches jargon, hidden ambiguity, structural opacity to non-specialists.
- **Implementability (engineering perspective).** Proves the pattern can produce working code. Catches under-specified primitives, missing edge cases, and the *"this never happens in production"* assumption.

All three must touch every pattern before it is considered `grounded`. The classic failure mode in projects like this is one perspective dominating: papers nobody reads, beautiful designs nobody can build, pragmatic code that drifts from intent within a quarter.

**The hard rule:** *No pattern is accepted until a non-engineer can understand the summary and a working engineer can implement from it.* Both halves matter. A pattern that fails the first is too jargon-heavy; one that fails the second is too abstract.

The three perspectives complement the three-pass pressure-testing methodology described below. Perspectives are *who* reviews; passes are *what* they check. Both are needed.

---

## The quality bar

Every Grace Commons pattern — atom or composition — is reviewed through three passes, each catching a different class of gap:

- **Pass 1 — Structural completeness (GRID — the nine-checkpoint completeness framework: Intent, System, Friction, Flow, Decision, Feedback, State, Behavior, Proof).** Are all nine GRID nodes resolved with their references intact?
- **Pass 2 — Conceptual independence (EOS — *The Essence of Software*, Daniel Jackson's framework of freestanding, composable concepts).** Does the spec absorb any responsibility that belongs in a separate freestanding atom?
- **Pass 3 — Adversarial scrutiny (Linus mode — named for Linus Torvalds's blunt, unsparing code reviews).** Are there muddled identities, sloppy invariants, happy-path-only examples, or hidden load-bearing decisions?

Each pass catches a different class of gap; none substitutes for the others. One clean sweep of the three is not grounding. The full bar is a **3×3 baseline** — three rounds of the three passes, nine passes — followed by a **Final Critique**, an AI-conducted adversarial round run at Opus *Happy Torvalds X2* depth and repeated until foundational findings reach zero; every pattern also carries both formal models. See [`pressure-testing.md`](./pressure-testing.md) for the full methodology and [`atoms/personal-todo.md`](./atoms/personal-todo.md) for a worked example.

A pattern that has only survived part of that arc is *in process* — and that is a respectable state, provided the actual state is declared honestly per the status taxonomy (`unresolved`, `partially resolved`, `grounded (English) — formal layer pending`, `grounded`).

---

## What we are not looking for right now

- Code implementations
- Framework integrations
- Language bindings

Grace Commons is a specification library. The implementations come later, elsewhere. Formal-model artifacts (Alloy, TLA+) are not code in this sense — they are formal specifications, not implementations, and they are welcome per the *Formal-model artifacts* section above.

---

## Contribution lifecycle

A pattern moves through four states: **Proposal** (an issue describing the recurring pattern) → **Draft** (a first spec, almost certainly `unresolved` or `partially resolved`) → **Pressure-tested** (the 3×3 baseline run, gaps fixed or deferred) → **Grounded** (the Final Critique clean — foundational findings at zero; Ledger and Decisions current). The lifecycle is iterative; a `grounded` pattern can return to `partially resolved` if LIVE evidence later contradicts an invariant, or if a touch or scheduled rescan surfaces a finding.

---

## Workflow for adding a new pattern

This section moved to [`spec-format.md`](./spec-format.md#workflow-for-adding-a-new-pattern), which owns its subject; follow the link.

---

## Implementation-discovered findings

This section moved to [`pressure-testing.md`](./pressure-testing.md#implementation-discovered-findings), which owns its subject; follow the link.

---

## How to contribute

Open an issue or submit a pull request. If you are unsure whether something belongs, open an issue first and describe what you have in mind. The overhead of a conversation is lower than the overhead of a rejected PR.

---

*We are not inventors here. We are curators — connecting dots from brilliant but unfinished work across decades. If you recognize the problem, you are probably already a contributor.*

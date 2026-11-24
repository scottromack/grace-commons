---
title: Start Here
nav_order: 1
permalink: /
---

# Start Here

> {{ site.data.stats.patterns }} patterns ({{ site.data.stats.done }} done), a methodology, formal models, and a verification harness is a lot of surface to land on. This is the short path through it: four stops, about an hour of focused attention, and at the end you will know what this library is, whether its claims hold, and whether it matters to you. Resist the nav sidebar until stop four — it will still be there.

> Grace wants the commons, not your gold: what is yours stays yours. Read [Our IP pledge](./ip-pledge.md).

1. **Say** – You say what you need, in plain words.
2. **Draft** – Grace finds the pattern that fits, or drafts a new one.
3. **Review** – The council tests it until nothing breaks.
4. **Build** – You get the bundle. Build it yourself, or we do.

<!-- grace-map:start -->
## The map of Grace's parts

Every kind of part Grace is made of, the whole tree first, then each part once with its one real example. A part marked *(planned)* does not exist yet.

```
Grace
├─ Grammar              the controlled English every part is written in
├─ Sub-atomic           what every atom stands on: three primitives, a pipeline, the database contract
├─ Atoms                one idea each: its state, its actions, its rules
├─ Bonds                how atoms connect: key, owner key, link, range, guard, follow-up, priority
├─ Glue                 the few lines that belong to no atom or bond yet, each with a birth tag
├─ Data (planned)       typed tables the checkers read
├─ Outside-world contracts (planned)
└─ Apps                 atoms + bond instances + marked glue
   └─ Lean statements · proofs · codegen to two builds · generated tests (all planned)
```

- **Grammar** — the controlled English the specs are written in. Example: [GRACE-lang](./GRACE-lang.md). A formal grammar (GF) *(planned)*.
- **Sub-atomic** — the three primitives (state machine, pure function, direct effect), the four-step pipeline every action runs, and the database contract's families (Database, Order, Read, Refusal, Query, Input, Undo). Example: [Execution Contract](./execution-contract.md).
- **Atoms** — one freestanding idea with its state, its actions and its rules; today a model checks each one and a status says how far it is (`todo`, `doing`, `done`). Example: [Personal Todo](./atoms/personal-todo.md). A proof tag on each rule (proven, tested or assumed) *(planned)*.
- **Bonds** — the few kinds of connection between atoms, each stated once on one page, [Bonds](./bonds.md), so that no atom names another: an atom says what it needs and what it offers by kind, its fields typed by the words of [the declaration space](./declarations.md). Example: [Lease](./atoms/lease.md) offers a guard. Guard and key are written; owner key, link, range, follow-up and priority are written when a line lands on one *(planned)*.
- **Glue** — what is left that belongs to no atom or bond yet, kept at the end of an app's page, every line tagged bond candidate, atom candidate, data or dead; each leaves by promoting, demoting or dying. Example: the glue of [Recoverable Invocation as an app](./apps/recoverable-invocation/index.md).
- **Data** *(planned)* — typed tables the checkers read, outside the prose of atoms and glue; Medication Order's clinical tables are planned as the first.
- **Outside-world contracts** *(planned)* — what an app asks of a database or system that is not Grace's, such as the act probe in the glue of [Recoverable Invocation as an app](./apps/recoverable-invocation/index.md).
- **Apps** — atoms, bond instances and marked glue, wired for one job. Example: [Recoverable Invocation as an app](./apps/recoverable-invocation/index.md). The first whole app, the shared to-do list, *(planned)* will carry Lean statements that you review, proofs, code generated for two builds and generated tests. Not yet: `tools/lean`.
<!-- grace-map:end -->

Rather fill in one page? Here is the form.

```
# <Name>  (one word if you can)

What it is:        one sentence, in plain words
What it keeps:     the things it remembers
What people do:    each action, one line
Always true:       ...
When X happens:    ...
While X is so:     ...
Optional:          what a business may switch on or set
Never:             what must be impossible
Left to others:    what it does NOT do, and who does
Example:           one real scene, with real names and values
Source:            where the idea came from (MIT, a forum, a client)
```

The four stops below are the longer way in, for whoever wants it.

## In software as in life you need Grace

{% capture code_of_conduct %}{% include_relative CODE_OF_CONDUCT.md %}{% endcapture %}{% assign code_parts = code_of_conduct | split: "<!-- code:start -->" %}{% assign code_tail = code_parts[1] | split: "<!-- code:end -->" %}{{ code_tail[0] }}

---

## Stop 1 — Read one atom: [Event Log](./atoms/event-log.md) *(~10 minutes)*

An **atom** is a freestanding concept — one recurring piece of business behavior, specified completely, naming no other pattern. Event Log is the best first one: small enough to read in a sitting, load-bearing enough that half the library composes on top of it.

What to notice while you read:

- **The Summary is plain English.** A compliance officer can read it. That is a design rule, not an accident — every spec here is written for three audiences at once.
- **The Invariants are numbered and testable.** "Append-only," "total order," "no id reuse" — each is a property an implementation must produce *records* to prove, not a vibe.
- **Time and identity are injected, not grabbed.** The spec forbids the core logic from reading the clock or generating ids itself — that is what makes the behavior deterministic and checkable. (The rule is the Logic Confinement Principle; you will meet it again.)
- **What it refuses to do.** Retention, tamper-evidence, who-did-it attribution — all explicitly out of scope, each pointing at the pattern that owns it. The discipline of *not* absorbing responsibilities is most of what makes atoms composable.

## Stop 2 — Read one composition: [Audit Trail](./compositions/audit-trail.md) *(~15 minutes)*

A **composition** wires atoms together and is where the payoff lives. Audit Trail composes Event Log with Actor Identity, Tamper Evidence, and Retention Window — and produces guarantees *none of the four carries alone*.

What to notice:

- **The Composes section names constituents by reference.** Nothing is re-specified; the atoms remain unchanged. Compositions are wiring, not new primitives.
- **Emergent invariants.** Attribution coverage, cascade-on-purge, forensic completability — properties that only exist because of how the atoms are wired. This middle layer — guarantees that appear at composition time — is the library's most distinctive idea.
- **Generation acceptance.** The section listing what an external auditor must be able to verify *from the records alone*, with no access to source code. Hold that thought for stop three, because those sentences are about to become executable.

## Stop 3 — Run the evidence: [Verify It Yourself](./verify.md) *(~20 minutes hands-on, or 5 skimming)*

The auditor checks you just read are not aspirational prose — they are the literal source of a conformance validator, and this library's claims are built to be re-run by strangers. The verify page walks you through measuring an implementation (20/20, counted by a program, on twenty checks lifted on 2026-06-05; the patterns have moved since, and the verify page says by how much), watching five independent implementations on unrelated storage engines agree identically, injecting a real historical bug and watching the machinery catch and localize it, and running the formal models with their deliberately-sabotaged twins.

If you only have five minutes, read the *negative control* step and the *what each number means* section — the failure behavior is more persuasive than the passes.

## Stop 4 — Read the why: [The Spec Layer](./the-spec-layer.md) *(~25 minutes)*

Now the manifesto will read as a description of things you have touched rather than an ambition. The sections worth the closest read: **The Problem** (why software's truth is scattered across eight artifacts that silently disagree), **The Architecture** (why verbose structured English is the canonical form and code is derived), and **Bridges** (the litmus test every addition here must pass, which now lives on [The Method](./method.md#the-bridge-test)). You have already seen each principle operating — the three-tier Event Log spec, the emergent invariants, the validator.

---

## Where to go next — by who you are

- **Compliance, audit, or regulatory:** browse the regulated patterns from the [atoms catalog](./atoms/index.md) — start with Retention Window, Legal Hold, and the Defensible Retention composition; every regulated pattern carries auditor-facing scenarios and standards anchors (HIPAA, GDPR, SOX, FDA).
- **Engineer wondering how this becomes software:** the [Execution Contract](./execution-contract.md) — the deterministic compilation target: three primitives, a four-step pipeline, and the mapping from spec sections to runtime obligations. Then the live [demos](./demos.md) and their RECIPEs.
- **Formal methods background:** the section titled *Formal models* in [Pressure Testing](./pressure-testing.md) — the vote, the model-present bar, the buggy-twin vacuity guard, the coverage cross-check — then `tools/harness/` for the reproducible checker.
- **Thinking about contributing:** [Contributing](./contributing.md). The cheapest real contribution is reporting an ambiguity you found while reading — a finding routed through review is exactly how this library improves, and its first external issue produced a canonicalized methodology section.
- **Just want the state of things:** the [Roadmap](./roadmap.md) prints what exists, each pattern's state read from the pattern's own Status line, which is its source, and [Risks & Mitigations](./risks.md) is the library grading itself honestly — including the parts that are not done.
- **The big picture:** [Why Grace Commons](./why.md) — the argument in five minutes: why Grace exists and what it checks. Pair it with [Earning Source of Truth](./positioning.md) for where this sits in the lineage.

---
title: Start Here
nav_order: 1
permalink: /
---

# Start Here

> {{ site.data.stats.patterns }} patterns ({{ site.data.stats.grounded }} grounded), a methodology, formal models, and a verification harness is a lot of surface to land on. This is the short path through it: four stops, about an hour of focused attention, and at the end you will know what this library is, whether its claims hold, and whether it matters to you. Resist the nav sidebar until stop four — it will still be there.

> Grace wants the commons, not your gold: what is yours stays yours. Read [Our IP pledge](./ip-pledge.md).

## In software as in life you need Grace

1.  **Define your words.** Make sure you both mean the same thing. — [Glossary](./glossary.md); every spec's Terms
2.  **Be clear about who does what.** Name the owner, and the work stops falling through the cracks. — [Actor Identity](./atoms/actor-identity.md)
3.  **Keep boundaries.** Stay inside what was agreed, and nothing gets trampled. — [Logic confinement](./execution-contract.md#logic-confinement-principle)
4.  **Keep your promises.** Say what you'll do, then do it. — [Provisional Commitment](./atoms/provisional-commitment.md)
5.  **Ask first.** Don't act for someone without their okay. — [Consent](./atoms/consent.md)
6.  **Fail honestly.** Say when something didn't work. — [Recoverable Invocation](./compositions/recoverable-invocation.md)
7.  **Make it right.** When you cause harm, repair it. — [Compensable Workflow](./compositions/compensable-workflow.md), [Verified Repair](./compositions/verified-repair.md)
8.  **Remember what happened.** Keep the record straight, and don't rewrite it. — [Immutable Ledger](./compositions/immutable-ledger.md), [Audit Trail](./compositions/audit-trail.md)
9.  **Hearing it twice isn't doing it twice.** A repeated request gets the same answer, not a second action. — [Idempotent Reservation](./compositions/idempotent-reservation.md)
10. **Trust, then verify.** Give trust so things can move, and let your track record confirm it. — [Capability-Backed Sharing](./compositions/capability-backed-sharing.md), [Tamper Evidence](./atoms/tamper-evidence.md)
11. **Forgive.** When someone makes it right, let them back in. — [Actor Suspension](./compositions/actor-suspension.md)

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

The auditor checks you just read are not aspirational prose — they are the literal source of a conformance validator, and this library's claims are built to be re-run by strangers. The verify page walks you through measuring an implementation (20/20, counted by a program), watching five independent implementations on unrelated storage engines agree identically, injecting a real historical bug and watching the machinery catch and localize it, and running the formal models with their deliberately-sabotaged twins.

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
- **The big picture:** [Why Grace Commons](./why.md) — the vision page: what this is, what it is not, and where it is going. Pair it with [Earning Source of Truth](./positioning.md) for where this sits in the lineage.

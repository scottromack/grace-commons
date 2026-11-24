---
title: Party Identity — history
nav_exclude: true
search_exclude: true
---

# Party Identity — history

The dated record of how [Party Identity](./party-identity.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/party-identity.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-11-21 — The nine open lines close: an enrollment and a verification are attested too, every assigned id rides the length bound, the cited labels are named, and Check 8.1 folds into Check 1.1.** *Chose:* Composition note 4 has a composing Actor Identity attest the actor behind every admitted enroll, verify, suspend, reinstate and close, and Composition note 5 binds an attestation to every assigned id a writing action answers (the party id on an enroll, the verification id on a verify, the state change id on a transitioning action), External check 4 and Non-goal 16 saying the same (Scott's direction 120, rounds/open-line-choices-directions-2.md); Capability requirement 14 bounds every assigned id by the length bound (Term length bound), because Execution Contract Input 2 asks the bound of an id an input names, the party id alone, and Composition note 5 now carries the verification id and the state change id into an Actor Identity action reference, which that atom caps (Actor Identity Operation 37); a `Term cited:` line names the ten Execution Contract label groups (Database 1 through 7 and Query 1 through 4 each one) the page cites; Check 8.1 folded into Check 1.1, which now names State 1 beside Invariant 2.1; Composition note 1, 3 and 7 worded without the composers' identifiers (the activity opened to a party, the invited party accepts, the data subject); a NOTE says Invariant 1.1 owes no check (Execution Contract Database 6); the signature's `verify answer` arm written in the wire spelling, `verify_answer(verification_id, state_change_id)`, beside `party_id` and `state_change_id`. *Over:* English names inside the signature block (D-wire-spelling reads a signature as a wire surface, so the open line's "every arm a declared name" is met by one spelling for every arm, the code spelling); a cap on the party id alone. *Because:* Scott, 2026-11-19, a pattern marked done with errors pointed out in its text is embarrassing (rewrite.md, `<path> open lines`). Closed by what the corpus already did: 2026-11-04-b (the page's fence carries only Invariant 8.1 and 8.2 since the reorganisation) and 2026-11-04-h (spec-format's atom shape no longer asks for the blockquote or nav_order, 8c9896b3).

- **2026-09-13 — Insertion order is authoritative and a recorded instant is advisory, stated as its own rule family.** *Chose:* an `Ordering` family, with Ordering 4 and Ordering 5 forbidding a reading or a reconstruction from turning on an instant. *Over:* the prose's paragraph saying the same thing beside the state machine. *Because:* Operation 18's *most recent suspend* is the atom's central guarantee and it is decidable two ways, one of which is unsound — under clock skew a later event can carry an earlier instant, and two readers would then disagree about whether a party may be reinstated. A rule family is what makes the sound reading the one a generator implements.

- **2026-09-13 — Invariant 9 and Invariant 10 are tombstoned; Identity owns assigned id stability and uniqueness.** *Chose:* Identity 6 through 9 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3. Checked before removing: the corpus cites Party Identity Invariants 1, 4, 5 and 11 — from [Customer Onboarding](../compositions/customer-onboarding.md) and the coverage matrix — and cites neither 9 nor 10, so the tombstones break no citation.

- **2026-09-13 — The EOS strip test: no domain tag, no rename, and the coupling is in the attributes rather than the name.** *Chose:* leave the atom untagged and unrenamed, and record where the domain actually touches it. *Over:* a `domain:` tag, or a reframe of the kind [Observation](./observation.md) took. *Because:* the test asks whether stripping the domain leaves a freestanding neutral primitive, and here it does. Every invariant is neutral — records are never removed, a terminal absorbs, events are append-only and immutable, a standing rests on recorded evidence since the last revocation. None of them is derivable only from banking or healthcare; the same shape governs a licence, an accreditation, a calibration status. The *name* is already the stripped form: party is legal and commercial vocabulary rather than one industry's, which is why the atom is not called Customer Identity or Patient Identity. What is domain-flavoured is the enrollment attribute set — name, date of birth, document type, document reference — which is natural-person identity-document vocabulary, and the atom already treats two of the four as opaque strings it never interprets. The honest boundary is that this atom is a neutral standing-and-evidence primitive carrying one concrete attribute schema, and the question of whether that schema should be an opaque attribute bag belongs on the docket rather than in a rename.

- **2026-09-13 — no-passed-verification-since-suspend stays a purpose-built rejection arm.** *Chose:* the arm the prose already carried. *Over:* folding it into not-suspended or invalid-request, which is what the corpus's closed answer set usually pressures a rare condition into. *Because:* this one is not rare and not adjacent to anything — it is the atom's central guarantee failing, and a caller receiving it knows exactly what to do next, which is to record a check. It is worth naming as the corpus's counter-example: the docket row on answers charged to the nearest arm is about conditions that could not justify the cost of their own name, and this is what paying that cost looks like.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the party store supplied under Execution Contract Store 1 through 4 and Execution Contract Order 1 (Capability requirement 10), and the sixteen rules that restated them tombstoned to their owner — Capability requirement 5, Operation 38, Invariant 11.1 and Atomic writes 1, 3 and 4, an action's records committed whole in one transition, and Invariant 1.2, no partial party on storage-failure, to Store 1; Invariant 11.2, no record of a refused action on storage-failure, and Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 4, a write acknowledged only once it commits, to Store 3; Concurrency 1, the state checks and the state change as one operation, to Store 1 and Store 2; Capability requirement 3 and Concurrency 2 and 3, two party actions on one party serialized and the later answering from what the earlier committed, to Store 2; Ordering 1 and 2, the store instance appending each event in its own insertion order, to Order 1; rules 190 to 175. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Insertion order stays the atom's authority and a recorded instant advisory (Ordering 3 through 6): a fresh verification is a passed verification event that follows the most recent suspend, a position across a party's two event lists, and [Read] answers parties in insertion order, and the atom carries no sequence of its own to order either, so it cites Order 1, the first specification to. Every check that compares reads compares the auditor's own reads, or reconstructs from one read (Check 5.2), so it cites no History 1. A refused action leaving the party as the call found it and writing nothing stays the atom's own (Operation 41 through 43), as do the records it never removes or changes and the counts and lengths that never fall (Invariant 1.1, 1.3, 5.1, 6.1 through 6.3, 8.2); what the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a party action answering not-known, then its state rejections, [Reinstate]'s not-suspended ahead of no-passed-verification-since-suspend, then invalid-request on a field fault, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 10, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 17 (a state rejection only for a party id naming a party), Operation 19 (no-passed-verification-since-suspend only on a suspended party), Operation 20 (a field fault only once every state check passes) and Operation 40 (storage-failure behind every precondition), with Term state rejection, which only Operation 17 read; rules 175 to 171. Operation 12 stays the page's own: a blank party id answers invalid-request ahead of not-known, while every other field fault answers after the state checks, so invalid-request holds two places in the order and no fixed line can carry both; Refusal 1 reads a refusal Operation 12 keeps from a call as not applying to it. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — The length bound refuses on the writes alone; the scrub and the purge belong to composing patterns; a range's bounds are no forbidden input.** *Chose:* String 7 and String 8 refusing an over-long string input on [Enroll] and the party actions, and [Read] meeting no length refusal; Invariant 7.1 deleted to Non-goal 3, so the atom never changes an enrollment field and a composing erasure coordination scrubs the fields the custody fields leave; Invariant 1.3 deleted to Invariant 1.1 and Execution Contract Database 4, so the atom never removes a party record and a composed Retention Window destroys one only as its own page says; Check 6.1 through 6.3, which cannot tell either act from a violation from the party records alone, moved to External check 9 and External check 10; and Operation 59 deleted to the rules that stamp every recorded instant from now (Operation 6, Operation 24, Operation 34). *Over:* a length rule on every action, which [Read]'s signature cannot answer; an immutability with no actor and a party count that may never fall, which break at the first scrub and the first purge the page itself sends to composing patterns; and a rule against every caller-supplied instant, which forbids the range [Read] admits. *Because:* Final Critique 6 found each a divergence between conforming builds, two rules no build can both obey, or a check a conforming deployment fails, and the page's own earlier text held each cure: Final Critique 5 capped write inputs alone, held the enrollment fields immutable under the atom's action contract with the scrub a composing Erasure Coordination pattern's, kept party records permanent from the atom's perspective while Retention Window decides when destruction becomes permitted, and refused caller timestamps only for the instants the atom stamps, beside a timestamp range filter. What each action answers on a call the guards admit is unchanged, save that [Read] no longer measures a filter value against the length bound.

- **2026-10-22 — An admitted call, a composed scrub or purge, and the reach of a length refusal are stated once.** *Chose:* the five admitted terms (enroll, verify, suspend, reinstate, close) citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried; External check 9 and External check 10, a composing erasure coordination's scrub events and a composing Retention Window's purge records read beside the party records, deleted to Execution Contract Database 6, with the tombstones of Check 6.1 through 6.3, which named them, now naming the contract; String 7 written again as the page first had it, an over-long string input answering invalid-request on an action, and String 8, the per-action split this page's sixth Final Critique wrote, deleted to String 7 and GRACE-lang Closed vocabulary 29, under which the rule binds [Enroll] and the four party actions, whose signatures carry invalid-request, and not [Read], whose signature carries invalid-query alone; Database 6 and Read 4 cited on Capability requirement 10; rules 168 to 165. *Over:* the page stating for itself which calls its effect rules reach, that a scrub or purge another specification declares is answered outside the party records, and which actions the length refusal reaches. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the category reach among them; this page's sixth Final Critique had made them one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — No pattern scrubs an enrollment field; an erasure lands in the records the references name, and the party record leaves whole.** *Chose:* Composition note 8 widened from a composing Retention Window to every composing pattern, so no pattern scrubs an enrollment field; Composition note 9 and 10 and External check 3, which gave a composing erasure coordination pattern the scrub, tombstoned to it and to Non-goal 12; Term custody field, and the clauses in the Enrollment Instant and Enrolling Actor Reference entries that named it, deleted with it; the GDPR Article 17 line saying where an erasure lands, in the records the document reference and the evidence reference name, and that the party record leaves whole through Retention Window's purge once its retention allows (Execution Contract Database 4). *Over:* a declared scrub action on this atom, which would reverse Non-goal 12 and add a sixth write, and a field-level scrub that a pattern not composing this atom declares under Database 4 and 6. *Because:* the maintainer ruled on 2026-11-01 (rounds/escalations.md, 21:37Z, Party Identity (b)) that no pattern scrubs an enrollment field. Execution Contract Atom interface 1 lets a composing pattern change this atom's records only through its declared actions, and none of them changes an enrollment field (Operation 46, Non-goal 12), so the scrub the page gave a composing pattern had no conforming route, and Final Critique 8 and Final Critique 9 each found it. The corpus's model is that personal data leaves with the whole record, and Capacity Constraint Enforcement follows it at its own next round. What each action does and answers is unchanged.

- **2026-11-02 — The length bound has a default.** *Chose:* the length bound stated as 1,024 Unicode code points where a deployment declares none, the unit written as Unicode code points as Permissions, Credential and Provenance count theirs; String 7 and Capability requirement 14 stand, Capability requirement 7 turned to *declare*, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from a name and references to a free-text reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-11-04 — A declared bound never falls below an assigned party id.** *Chose:* Execution Contract Input 2's floor, cited by Capability requirement 7 and stated on no rule of this page: a deployment MUST NOT declare a cap that a value a record already holds EXCEEDS, so an override cannot leave an assigned party id refused by String 7; Capability requirement 14 binds the allocator and stands. *Over:* a rule of the page beside Capability requirement 7. *Because:* the maintainer ruled on 2026-11-04, on State Machine Final Critique 13, that the floor is stated once in Input 2 and no atom restates it; this page's full round is still owed, and a reader looks for the rule's place here.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Party Identity](./party-identity.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 17. Execution Contract Database 7 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 3 owns it.
Deleted: Capability requirement 5. Execution Contract Database 1 owns it.
Deleted: Capability requirement 6. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Deleted: Operation 28. Operation 37 owns it.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Deleted: Operation 39. Execution Contract Read 4 owns it.
Deleted: Operation 40. Execution Contract Refusal 1 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 58. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 59. Operation 6, Operation 24 and Operation 34 own it.
```

### Structure › Invariants › Invariant 1 — Party record permanence

```
  Deleted: Invariant 1.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 1.3. Invariant 1.1 and Execution Contract Database 4 own it.
```

### Structure › Invariants › Invariant 7 — Enrollment fields are immutable under the atom's actions

```
  Deleted: Invariant 7.1. Non-goal 3 owns it.
```

### Structure › Invariants › Invariant 8 — No transition is silent

```
  Deleted: Invariant 9. Identity 6 owns assigned id stability.
  Deleted: Invariant 10. Identity 7, Identity 8 and Identity 9 own assigned id uniqueness.
```

### Structure › Invariants › Invariant 11 — Action atomicity

```
  Deleted: Invariant 11.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 11.2. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Structure › Ordering

```
Deleted: Ordering 1. Execution Contract Order 1 owns it.
Deleted: Ordering 2. Execution Contract Order 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.2. Ordering 3 and Ordering 4 own it.
Deleted: Check 4.1. Check 5.1 owns it.
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
Deleted: Check 6.3. Execution Contract Database 6 owns it.
Deleted: Check 8.1. Check 1.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Non-goal 12 and Composition note 8 own it.
Deleted: External check 9. Execution Contract Database 6 owns it.
Deleted: External check 10. Execution Contract Database 6 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. String 7 and GRACE-lang Closed vocabulary 29 own it.
```

### Composition notes

```
Deleted: Composition note 9. Composition note 8 owns it.
Deleted: Composition note 10. Composition note 8 owns it.
```

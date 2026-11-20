---
title: Permissions — history
nav_exclude: true
search_exclude: true
---

# Permissions — history

The dated record of how [Permissions](./permissions.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/permissions.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the three actions as a signature block, the string policy as its own rule family, the ten invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan, and this atom completes [Shared Todo](../compositions/shared-todo.md)'s constituent set — Personal Todo, Assignment and Permissions all migrated, which makes that composition the one with no inherited term collision to resolve.

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every grant with its stored fields (Operation 26 through 29). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of grants", each with its fields — and the migration dropped it with the section, while Deprovisioning 2, Check 1.1, Attributed Permissions Admin and Actor Suspension all read the store through it. Restored as the prose had it, not widened: no filter, so a composing pattern filters in its own code. Found by the cold regeneration of the Attributed Permissions Admin demo (council read 228).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the grant store supplied under Execution Contract Store 1 through 4 (Capability requirement 4), and the seven rules that restated them tombstoned to their owner — Operation 8 and Invariant 10.3, no partial grant, to Store 1; Operation 12, the active-to-revoked move committed as one write, to Store 1 and Store 2; Revoke concurrency 1 and 2, two revokes of one grant never both succeeding and the later answering not-active, and External check 4, the deployment's evidence of that serialization, to Store 2; Operation 14, a refused revoke leaving the grant active, to Store 3; rules 111 to 105. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The grant set that never shrinks stays (Invariant 10.2), the atom's own surface that Check 5.1 reads, and so does the caller's reading of a refused revoke (Operation 15, Revoke persistence 1 through 4): it binds the caller, which no Store rule does. What the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers on every action, each writing action's refusals in one stated order; coverage is no ground for refusal; a deprovisioning is recorded only once no grant stands.** *Chose:* state-unavailable on all four actions where the read of the grant store fails, the Execution Contract's Step 1 failure (Operation 30, Term store read), [Check] and [Read] refusing nothing else and answering only on an answered read (Operation 16, Operation 18, Operation 19, Operation 26, Operation 29), the refusals of [Grant] and [Revoke] in one stated order, the store read first (Operation 31, Operation 32, Term grant refusal order, Term revoke refusal order), and Invariant 3.1, which said outside that order what Operation 10 says, deleted to it; [Grant] forbidden to refuse a call on the ground that an active grant already covers the pair, not to refuse a covered pair at all (Operation 6); a composing pattern recording a subject's deprovisioning only where no active grant exists for the subject (Deprovisioning 5); a check that finds permitted for a matched pair, Check 3.2 citing the rule it tests (Check 3.3, Operation 17); the composing patterns a deployment wired in read from the deployment's own declaration (External check 5). *Over:* [Check] and [Read] forbidden to refuse a store they cannot read; a ban on refusing a covered pair that the write refusal, a lowered string cap and the failed read each break; a sweep recorded complete while a grant issued during it, or one whose revoke never answered, stays active; conformance checks a build denying every pair clears; a check reading what the grant store does not carry. *Because:* Final Critique 5 found each a divergence between conforming builds, or a stated check a conforming build fails or a violating one passes, and the corpus already held three of the cures: Actor Identity's fifth round answers a failed store read on every action and reads the composing patterns from the deployment's declaration, and Retention Window's eighth answers each writing action's refusals in one stated order, the form the maintainer ruled for Verified Repair on 2026-10-19, and forbids a refusal on a stated ground (its Operation 18). Compositions affected: the pages that compose this atom route state-unavailable from all four actions, and record a deprovisioning only once no grant stands, when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 4, Execution Contract Read 1 through 3) and the four rules that restated it deleted to it: the atom-wide state-unavailable (Operation 30) to Read 1; [Check]'s and [Read]'s state-unavailable on a failed read alone (Operation 19, Operation 29) to Read 2 beside the rules that close each action's answers; and the grant refusal order (Operation 31), whose rules after the read all answer invalid-request, to Read 1; the read's condition off the rules it held to an answered read (Operation 16, Operation 18, Operation 26), the read off the revoke refusal order, Term database read deleted, and state-unavailable off every signature; rules 109 to 105. *Over:* the page stating for itself what every action answers when the grant records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made the cure the contract's Read family is written from. What [Check] answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Revoke]'s refuses line kept as the page wrote it, already in the order the revoke refusal order gave — not-known, not-active, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 4, Execution Contract Refusal 1); Operation 32, which evaluated the revoke refusal order, deleted to Refusal 1, and Term revoke refusal order deleted with it; rules 105 to 104. *Over:* the page stating for itself which of [Revoke]'s refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's fifth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 5, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, the checks NOTE's clause restating it removed, and the label cited on Capability requirement 4; Operation 6's ground clause retired, the rule written again as the page first had it, *[Grant] MUST NOT refuse a pair an active grant already covers*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so a blank reference still answers invalid-request; rules 104 to 103. *Over:* the page stating for itself that the wiring is an external check, and Operation 6 carrying the ground clause its fifth Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's fifth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 256 Unicode code points where a deployment declares none, and Capability requirement 5 turned from *supply* to *declare*, citing Execution Contract Input 2; String 6, String 7 and Capability requirement 6 stand. *Over:* a cap the deployment must supply before the atom can refuse an over-long string. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; both string inputs, a subject reference and an action scope, are identifiers, and 256 code points holds an email address (254) with room to spare.

- **2026-11-16 — A person holds a permission once.** *Chose:* at most one active grant over one pair (Identity 7, Invariant 11.1); [Grant] on a pair an active grant matches answers that grant's id and writes nothing (Operation 33, Operation 34); two concurrent [Grant] calls on one pair record one grant (Grant concurrency 1, by Execution Contract Database 2); Operation 6 and Grant concurrency 2 deleted; a revoked pair may be granted again, as a new grant. *Over:* the choice of 2026-09 that two grants over one pair are two independent facts, with Operation 6 (a covered pair is no ground for refusal) and Grant concurrency 2 (a composing pattern intending one authoritative grant guards a concurrent issue). *Because:* the maintainer ruled on 2026-11-16 ("we are not even talking about what different people do I am logged in as me and can add the same thing 10 times. it makes no sense"; "People with admin rights can set other peoples rights, People can only have one of each boolean"). The reason the old choice gave, that two administrators granting on two days is two facts, is the composing pattern's to keep: who granted and when is Actor Identity's attestation and Event Log's record, and the atom's own ledger already held the doubt open (2026-10-21-e, which this closes). A second administrator granting a held permission changes nothing in the grant records, and a revoke ends the access whole, which is what an administrative surface asked of the atom all along (the beacon demo's screen listed one person twelve times).

- **2026-11-19 — Grant concurrency 1 holds where no revoke falls between the two commits.** *Chose:* Grant concurrency 1 says the admitted concurrent [Grant] calls on an unheld pair, with no [Revoke] of the pair's grant between the calls' commits, record exactly one grant in all (the model's probes found two more gaps in the first wording: with three calls in flight the second and third record none, and two calls whose writes the database refuses record none, Operation 7); Operation 1, Operation 33, Operation 34 and Identity 7 stand as they are (105 rules before and after, no label added or deleted). *Over:* the rule as written on 2026-11-16, which read "two concurrent [Grant] calls on the pair MUST record EXACTLY ONE grant" whatever the calls between: where a [Revoke] of the first call's grant commits between the two calls' commits, the second call finds no active grant, Operation 1 has it record one, and two concurrent calls record two. *Because:* the formal layer's TLA+ model (unit `atoms/permissions.md formal layer`, 2026-11-19, page-findings row 41) reached that case on a build that followed the page; Operation 1 and Identity 7 say what a call on an unheld pair does, so the concurrency rule gives way to the case it was written for, two calls that both met the pair unheld and no revocation between their commits (Execution Contract Database 2).

- **2026-11-20 — The grant id's source and the alert's receiver are among what the deployment supplies, and the page cites the contract's labels.** *Chose:* Capability requirement 7, the deployment supplying at the seam, for each [Grant] call, a grant id no grant has carried PER Execution Contract Logic confinement 3 and 16 (Identity 2 stands); Capability requirement 8 and 9, the deployment declaring itself high-assurance and the receiver of Revoke persistence 4's alert, in the form Notification took; Revoke persistence 2 giving the caller the retry's count and interval; Operation 35, a call of permitted calling [Check], so the wire's name and the rules' name are tied on the normative surface; the seam, the transition and the business caller citing Execution Contract Logic confinement 14 by label. *Over:* a retry bound the atom fixes, an action renamed on the wire (every composing page calls permitted), or a section title the contract does not carry. *Because:* the atom cannot know how long a deployment's store stays down, so the bound is the caller's, as Notification's Deliver persistence 2 settled; the grant id is injected at the seam as every host-allocated id is, and the Capability requirement block is where the atom shape lists what a deployment supplies; the gloss on Term now is the form some forty atoms carry, left for the contract to admit (a held cure to Logic confinement 11).

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Permissions](./permissions.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Invariant 5.1 owns it.
```

### Structure › State

```
Deleted: State 6. Invariant 2.2 owns it.
Deleted: State 7. Invariant 10.1 owns durability.
Deleted: State 8. Non-goal 1 owns it.
Deleted: State 9. Non-goal 3 owns it.
Deleted: State 10. Non-goal 6 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Non-goal 17 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. Operation 33 and Operation 34 own what [Grant] answers and writes on a pair an active grant matches (Identity 7, Invariant 11.1).
Deleted: Operation 8. Execution Contract Database 1 owns it.
Deleted: Operation 12. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Operation 14. Execution Contract Database 3 owns it.
Deleted: Operation 19. Operation 16 and Execution Contract Read 2 own it.
Deleted: Operation 23. Capability requirement 1 owns it.
Deleted: Operation 24. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 29. Operation 26 and Execution Contract Read 2 own it.
Deleted: Operation 30. Execution Contract Read 1 owns it.
Deleted: Operation 31. Execution Contract Read 1 owns it: after the read, every refusal rule of [Grant] before the write answers invalid-request.
Deleted: Operation 32. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 2 — Status monotonicity

```
  Deleted: Invariant 2.1. State 1 owns it.
```

### Structure › Invariants › Invariant 3 — Revocation is terminal

```
  Deleted: Invariant 3.1. Operation 10 owns it.
```

### Structure › Invariants › Invariant 10 — Grant record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it (Execution Contract Database 6).
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 5. Execution Contract Conformance 9 owns it.
Deleted: External check 4. Execution Contract Database 2 owns it.
```

### Edge cases › Deprovisioning a subject

```
Deleted: Deprovisioning 1. Identity 8 owns one revoke reaching one grant.
```

### Edge cases › Grant concurrency and revoke concurrency

```
Deleted: Grant concurrency 2. Identity 7 owns it: the atom itself keeps one grant per pair, so no composing pattern guards a concurrent issue.
Deleted: Revoke concurrency 1. Execution Contract Database 2 owns it.
Deleted: Revoke concurrency 2. Execution Contract Database 2 owns it.
```

### Edge cases › Revoke persistence failure

```
Deleted: Revoke persistence 1. Operation 15 owns it.
```

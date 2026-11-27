---
title: Provisional Commitment — history
nav_exclude: true
search_exclude: true
---

# Provisional Commitment — history

The dated record of how [Provisional Commitment](./provisional-commitment.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/provisional-commitment.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-06-23 — Expiry stays a stored terminal reached by an explicit expire event; the derived-expiry refactor is withdrawn for this atom.** *Chose:* stored `Expired` with lapse instant, the window-not-elapsed rejection and confirm's window-elapsed guard restored. *Over:* the corpus-wide derive-expiry-at-read-time move applied two days earlier. *Because:* this atom's lapse has a side effect — expire releases the resource, and in a pool-backed composition returns a capacity slot — which Reserve from Pool and Idempotent Reservation call and map; derived expiry is for side-effect-free lapses only.
- **2026-11-20 — The critical section leaves the atom, and Lease owns exclusive standing over a resource for the span of a call.** *Chose:* Capability requirement 3, 4, 18, 19, 28, 31 and 32, Operation 42, the availability read span, the critical section bound and the registry-unavailable refusal removed; Capability requirement 16 keeps the verdict alone; Non-goal 29 and Non-goal 30 name Lease as the owner; the atom keeps its hold lifecycle, Capability requirement 17 and Concurrency 3. *Over:* keeping the rules and curing each finding in place. *Because:* the rules drew a foundational finding in Final Critique 9, 11, 14 and 15, four rounds on one mechanic, and the atom's job is the hold lifecycle; Scott's session decided it on 2026-11-20 (rounds/escalations.md 12:42Z, answering 05:32Z and 07:05Z), for the direction that recurring glue goes to the atom that owns it. What leaves with it: a build composing Lease ends the section at the lease's terminus, an instant, not at the later of the caller's return and the hold write's end; the stronger guarantee is Lease's to state, with its fences, and a deployment that wants the old liveness reads it there.

- **2026-09-13 — The window boundary is declared once, as a term, instead of being restated at four guard sites.** *Chose:* open and lapsed as a two-member window reading, with the boundary instant declared onto the lapsed side. *Over:* repeating `now < expires_at` and `now ≥ expires_at` in each guard, which is how the prose carried it. *Because:* the boundary is one proposition and a spec pays for a proposition once (GRACE-lang Authority 3); four copies are four chances for an edit to move three of them. It also routes the comparison out of the rules, which carry no arithmetic (GRACE-lang Hard invariant 24).

- **2026-09-13 — Invariant 4 and Invariant 9 are tombstoned; Identity owns id stability and id reuse.** *Chose:* Identity 4 and Identity 5 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3 — and Identity 5 is the stronger claim, since two commitments never share an id whether or not either has resolved.

- **2026-09-13 — The resource return is the registry's obligation, not the atom's.** *Chose:* Capability requirement 10 and Capability requirement 11. *Over:* an `Operation` obliging the atom to return the resource, which a draft of this migration carried. *Because:* the atom cannot see availability (Non-goal 11) and External check 1's own WHY says so, which made the rule either false or unfalsifiable — a MUST whose subject cannot evaluate it is decoration. The asymmetry was the tell: the negative half (*an admitted confirm MUST NOT return it*) was specifiable and the positive half was not.

- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is a non-goal.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone, with `Non-goal 25` naming the limit and `Capability requirement 12` where a deployment may close it. *Over:* a third rule reading *EXACTLY ONE resolving action MUST commit*. *Because:* its marginal content over the other two was liveness, which an atom that licenses lazy expiry cannot deliver — and the model says the same: `INVARIANT Safety` with no temporal property, and `Inv_SingleResolution` checking only that a written resolution matches the state. The spec claimed *exactly*; the model checked *at most*. GRACE's `MUST` has no temporal scope to tell them apart, which is now a docket row.

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every commitment with its stored fields (Operation 38 through 41). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — "the current set of [Held] commitments" and the terminal ones, each with its fields — and the migration dropped it with the section. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 230).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the commitment store supplied under Execution Contract Store 1 through 4 (Capability requirement 15), and the nine rules that restated them tombstoned to their owner — Operation 27, a resolving action's state change and recorded instant in one transition, Invariant 10.3, no partial commitment on storage-failure, and Atomic writes 1, 3 and 4, a transition committed whole inside the implementation's transactional boundary and no repair of a dangling one, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 6, a write acknowledged only once it commits, to Store 3; Concurrency 1, the state check and the state change of a resolving action as one operation, to Store 1 and Store 2; Concurrency 2, the losing resolving action answering not-held from what the winner committed, to Store 2; rules 162 to 154. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The registry's critical section over the availability read and the hold write stays the registry's (Capability requirement 3 through 5, Concurrency 3): the registry is the deployment's, outside the atom and its store, and its verdict reaches the transition at the seam, so no Store rule reaches it. A refused action leaving the commitment as the call found it stays the atom's own (Operation 30 through 32), as do the id and properties that never change (Identity 4, Invariant 5.1) and the atom's no-removal rules (State 11, Invariant 10.1, Invariant 10.2). The window reading is taken against the expiry instant each commitment carries, and ordering one commitment's transitions is the composing Event Log's (Non-goal 26), so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — [Place Hold] invalid-request ahead of resource-unavailable; a resolving action not-known ahead of not-held, and not-held ahead of a window rejection; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 15, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 6 (resource-unavailable only once every well-formedness check passes), Operation 16 (not-held only for an id naming a commitment), Operation 20 (a window rejection only on a held commitment) and Operation 29 (storage-failure behind every precondition), with Term well-formedness check, which only Operation 6 read; rules 154 to 150. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — A composed retention may purge what the atom never removes; a refusal leaves what it found; a refused re-hold records nothing.** *Chose:* Invariant 10.2 deleted to Invariant 10.1 and Execution Contract Database 4, so the atom never removes a commitment and a composed Retention Window destroys a terminal one only as its own page says (Composition note 5); Check 6.1 and Check 6.2, which cannot tell a purge from a removal from the commitment records alone, moved to External check 7, which reads the Retention Window's purge records beside two reads; Operation 32 deleted to Operation 30, so a refused resolving action leaves the commitment as the call found it, terminal or held, and a call naming no commitment leaves nothing; and Invariant 5.2 deleted to Operation 8, with Term re-hold, which only it read. *Over:* a commitment count that may never fall beside the retention the page sends to Retention Window; a refused resolving action left in held where the not-held refusal answers on a terminal commitment and the not-known refusal on none; and a re-hold obliged to produce a commitment where a refused [Place Hold] records none. *Because:* Final Critique 5 found each a reachable state that breaks a rule of the page or fails one of its checks, and the page's earlier text held each cure: Final Critique 4 kept the record indefinitely from the atom's perspective with retention, archival and purge left to composing patterns, left the commitment in Held only where the store write failed, and made a re-hold a new commitment with a new id. What each action answers on every call is unchanged.

- **2026-10-22 — An admitted call, a composed purge and the wiring are the Execution Contract's.** *Chose:* the four admitted terms (place hold, confirm, release, expire) citing Execution Contract Read 4 for what an action admits, in place of the commit clause this page's fifth Final Critique wrote into each; External check 7, a composing Retention Window's purge records read beside the commitment records, deleted to Execution Contract Database 6, with the tombstones of Check 6.1 and Check 6.2, which named it, now naming the contract; External check 6, the composing patterns read from the deployment's own wiring, deleted to Execution Contract Conformance 9; the three labels cited on Capability requirement 15; rules 146 to 144. *Over:* the page stating for itself which calls its effect rules reach, that a purge another specification declares is answered outside the commitment records, and that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect, the composed erasure and the wiring declaration among them; this page's fifth Final Critique had made the first two cures one specification at a time. What each action does and answers is unchanged.

- **2026-10-29 — The registry's verdict follows the commitment records.** *Chose:* Capability requirement 17 kept, so the registry refuses a resource a held commitment carries; Capability requirement 20, the registry never removing the resource from availability on a refused [Place Hold], so the registry's own record of a hold follows the commit of the hold write, a storage-failure included (closing open line 2026-10-21-b); Capability requirement 18 and Capability requirement 19, the registry bounding its critical section and never releasing it while a hold write in it is in flight, as Lease's holder never releases a grant with a call in flight, with Capability requirement 5, the release on the caller's death, deleted to them, since a registry cannot tell a dead caller from a paused one (Lease Invariant 3) and a paused caller's hold write landing after the release would stand two held commitments on one resource (closing 2026-10-28-a); Term hold write and Term hold write in flight, naming the database write Capability requirement 3's critical section covers, apart from the registry's own record; rules 145 to 147. *Over:* option (b) of the 2026-10-28 09:25Z escalation, availability wholly the registry's own (Non-goal 11, Non-goal 12), with Capability requirement 17 deleted and the Summary's promise rewritten as the registry's; and a declared bound with a fence carried to the database, Lease's shape, which would choose the registry's mechanism for it. *Because:* the maintainer ruled on 2026-10-29 that the registry's verdict follows the commitment records, a held commitment's resource is refused, and the open lines settle the same way, the registry's own record of a hold following the commit; Concurrency 3, Capability requirement 3, 10 and 11 and Reserve from Pool's wiring already read the registry so. Each new rule binds the registry, as Capability requirement 3 through 5 did: the atom still defines no availability and decides no hold-ability (Non-goal 11, Non-goal 12), and what each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 256 Unicode code points where a deployment declares none, Capability requirement 21 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; both string inputs, a resource and a requester, are opaque references, and 256 code points holds an email address (254) with room to spare.
- **2026-11-19 — The registry releases the critical section on the caller's return and not before it.** *Chose:* Capability requirement 28, the registry never releasing the critical section before the caller's return, beside Capability requirement 4 (release on the return) and Capability requirement 19 (not while a hold write is in flight), so the section ends when the caller has returned and no hold write stands, and no other event ends it; Term hold write in flight and the Registry Unavailable entry say who ends it (the database's commit or refusal for a write, the caller's return for a section) and that a write the database never resolves, or a caller that never returns, leaves every later [Place Hold] answering registry-unavailable, the "transient" replaced by what bounds the condition (closing open line 2026-11-05-a). *Over:* a registry that releases after a timeout under a fence, and a hold write bound after which the registry reads the write as refused. *Because:* the 2026-10-29 entry already decided that a registry cannot tell a dead caller from a paused one, and a paused caller's hold write landing after a release stands two held commitments on one resource; the Execution Contract's Database rules carry no fence that refuses such a write, and the label does not stop the database committing it later (Execution Contract Database 3), so a release before the return is no safer than the Capability requirement 5 it replaces; the posture is Lease's holder with a call in flight (Lease Composition note 5c), whose liveness a deployment supplies by resolving the write and returning the call.

- **2026-11-26 — The atom converted to the bond shape, batch 3 of the converter: the id is the commitment id, offered; the atom needs an actor id and a journal, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered. The minted id's word was a bare "id", and Bonds Key 17 asks the record's word before it, so "id" is "commitment id" in every rule, term, entry, signature and projection (`commitment_id`); "id material", the seam's word, stays. `Term offer key: key commitment id; carried by commitments; calls Read` and `Term need key: key actor id; pairs commitments` (Key 9, 10, 26), the commitment id declared (Key 18). Composition note 3's composing event log becomes the atom's own journal need (`Term need journal: records commitment events`) and Operation 43 appends one record for every admitted call, as Medication Order's Operation 88 does, Storage Failure naming the journal's refusal (Execution Contract Constituent failure 1); commitment events declared. The seven `MUST compose <pattern>` Non-goals (2, 4, 15, 17, 20, 28, 30) tombstoned to the Non-goal that states what the atom does not do; the named Composition notes, External check 2 through 4, Non-goal 26, the owners NOTE, Term composing pattern, the requester entry, a scenario and three sources say each job, not a pattern. Labelled rules 153 before, 146 after; 760 lines before, 800 after. *Over:* splitting by length (Scott, 2026-11-25 11:14 PM Central: "don't arbetrarly split at 800 lines"). *Because:* unit `atom: Provisional Commitment, converted` (batch 3, 2 of 5).

- **2026-11-26 — The registry's unread verdict has an arm, and the reclamation window bounds the lag of a commitment no storage-failure stands for (Final Critique 19: two readers each).** *Chose:* Operation 44 and the [Registry Unavailable] entry, so a [Place Hold] whose host could not read the registry's availability verdict answers registry-unavailable, listed after invalid-request and before resource-unavailable on the refuses line (Execution Contract Constituent failure 2 names the arm, as Retention Window's place under retention carries it); Term reclamation window and External check 5 naming the commitments no [Expire] call answering storage-failure EXISTS for, which is what Capability requirement 12 already bound, and Capability requirement 30 asking the next firing to call [Expire] where it asked to resolve, since a refused write fails the call again and no firing can then resolve it. *Over:* doubling the reclamation sum (GRID, EOS), which a second refused write breaks again, and deleting Capability requirement 12's condition (EOS). *Because:* the registry-unavailable removed on 2026-11-20 was Operation 42's, the critical section's bound with the section itself; the seam's unread verdict is a different arm that no rule left, and the lease pattern's critical section never read it. What each action answers on a read registry and a clean path is unchanged.

## Migration notes

- **2026-09-13 — Invariant 8, titled for the two instants it floors.** The family floors the two *resolution* instants and not lapse instant, whose floor is the stronger one Invariant 7.2 already carries — an expiry may not precede expiry instant, which by Invariant 6.1 exceeds placement instant. The family was titled *Transition instants* in a draft of the migration, which promised a floor on all three and delivered two (council read 38).
- **2026-09-13 — String 1 through 6, added in the migration.** The family was missing from a draft of the migration, and its absence was invisible rather than benign: Operation 1 and Operation 2 test caller-supplied strings against blank, so without String 5 and String 6 a whitespace-only resource had no declared reading at all and two implementations could disagree about whether it is a hold (council read 38). The reading of blank is shared, which is why the grammar owns it since GRACE-lang v0.52 rather than eleven specs repeating it word for word.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Provisional Commitment](./provisional-commitment.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 13. Execution Contract Database 7 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 3. Non-goal 30 owns it.
Deleted: Capability requirement 4. Non-goal 30 owns it.
Deleted: Capability requirement 5. Non-goal 30 owns it.
Deleted: Capability requirement 6. Execution Contract Database 3 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 13. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 14. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 18. Non-goal 30 owns it.
Deleted: Capability requirement 19. Non-goal 30 owns it.
Deleted: Capability requirement 28. Non-goal 30 owns it.
Deleted: Capability requirement 31. Non-goal 30 owns it.
Deleted: Capability requirement 32. Non-goal 30 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 6. Execution Contract Refusal 1 owns it.
Deleted: Operation 16. Execution Contract Refusal 1 owns it.
Deleted: Operation 20. Execution Contract Refusal 1 owns it.
Deleted: Operation 27. Execution Contract Database 1 owns it.
Deleted: Operation 28. Execution Contract Read 4 owns it.
Deleted: Operation 29. Execution Contract Refusal 1 owns it.
Deleted: Operation 32. Operation 30 owns it.
Deleted: Operation 36. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 37. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 42. Non-goal 30 owns it.
```

### Structure › Invariants › Invariant 3 — Terminal absorption

```
  Deleted: Invariant 4. Identity 4 owns id stability.
```

### Structure › Invariants › Invariant 5 — Property immutability

```
  Deleted: Invariant 5.2. Operation 8 owns it.
```

### Structure › Invariants › Invariant 8 — Resolution instants follow placement

```
  Deleted: Invariant 9. Identity 5 owns id reuse for every id, resolved or not.
```

### Structure › Invariants › Invariant 10 — Commitment record durability

```
  Deleted: Invariant 10.2. Invariant 10.1 and Execution Contract Database 4 own it.
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Database 6 owns it.
Deleted: Check 6.2. Execution Contract Database 6 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 6. Execution Contract Conformance 9 owns it.
Deleted: External check 7. Execution Contract Database 6 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
Deleted: String 6. GRACE-lang Term blank owns it: an absent value is blank.
```

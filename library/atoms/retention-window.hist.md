---
title: Retention Window — history
nav_exclude: true
search_exclude: true
---

# Retention Window — history

The dated record of how [Retention Window](./retention-window.idd) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/retention-window.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two actions as a signature block, the refusal order carried by each rule's own condition rather than by the order the rules sit in, the eleven invariant numbers frozen exactly as Audit Trail cites them, Generation acceptance moved ahead of Non-goals as `spec-format.md` requires, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan takes the atoms the migrated compositions already cite first — Audit Trail cites this atom's Invariants 1, 3, 7 and 11 (`tools/grace/cites.py --into retention-window`).

- **2026-09-26 — The read surface restored.** *Chose:* `read()` in the signature block, answering every retention with its stored fields and, while retained, purge eligible (Operation 29 through 33). *Over:* an atom with no declared read. *Because:* the prose spec declared its read surface in its Outputs section — the retained and purged sets, each retention with its fields, and purge eligibility derived at read time — and the migration dropped it with the section, while Operation 28, Customer Onboarding and Defensible Retention all read the store through it. Restored as the prose had it, not widened. Found beside the same loss in Permissions and Actor Identity, which the cold regeneration of the Attributed Permissions Admin demo surfaced (council read 228).

- **2026-10-03 — A composing pattern may own the destruction, and where none does the destruction is confirmed before the retention reads purged.** *Chose:* destruction ownership per instance, declared by the pattern as a capability requirement and fixed for the instance's life; an owner that destroys only what a purged retention names, records each confirmation and retries every standing record nothing withholds (Record divergence 4 through 6, Term standing record, Term withheld record, External check 4); and, where the instance destroys, the storage layer confirming before the write, a dead request once the purge has answered, and one path by which a record is destroyed, its instant recorded (Record divergence 1 through 2b, Capability requirement 4 through 7, External check 5). *Over:* the three rules that bound every instance to coordinate and confirm a destruction and gave neither an order nor a failure reading; and over making every purge the transition alone, which would have rewritten what purge means for Defensible Retention. *Because:* Audit Trail's cascade must write its destruction record after the transition and cannot have purge wait on a mechanism purge has no view of (its Capability requirement 9, Ledger line 2026-10-03-a there), and a fresh reader of the first round found the unordered rule admitted a retention reading purged over a standing record with nobody retrying. Compositions affected: Audit Trail takes the ownership; Defensible Retention keeps a purge that destroys.

- **2026-10-03 — Joint enforcement is one pattern's, on the purge call where purge destroys and on the destruction where a pattern owns it.** *Chose:* a destruction forbidden while a retained sibling is not yet eligible, a purge forbidden under the same condition where purge destroys, a deployment with two retentions over one record obliged to compose the pattern and to place and purge through it, the pattern serializing placement, sibling read, purge and destruction per record reference, one record's retentions in one instance, and a retried placement read as a second retention (Simultaneous retention 1a, 4, 4a, 5, 6, 6a, Capability requirement 10, 11, Non-goal 14, 15). *Over:* a rule that let a record be destroyed only if every retention over it was purge eligible, which a purged retention can never be. *Because:* three passes each reached a record destroyed under a live sibling by a different route — a bare deployment, a placement racing the sibling read, a second instance. Compositions affected: Defensible Retention serializes holds against the purge and not placements (its Ledger line 2026-10-03-a).

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the retention store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the five rules that restated them tombstoned to their owner — Operation 10 and Invariant 10.3, no partial retention, to Store 1; Concurrency 1, every state transition atomic per retention id, to Store 1 and Store 2; Concurrency 2 and 3, two purges of one retention serialized and the second answering on what the first committed, to Store 2; rules 158 to 154. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The destruction, its confirmation, a caller's retry and the serialization over one record reference stay as they were (Record divergence, Purge persistence, Simultaneous retention 6): each reaches past one action's write to the retention store. What the atom does for its domain is unchanged.

- **2026-10-20 — A failed read answers on every action, each writing action's refusals answer in one stated order, and a late confirmation breaks no rule.** *Chose:* state-unavailable on all three actions where the read of the retention store fails, the Execution Contract's Step 1 failure (Operation 34, Term store read), [Read] refusing nothing else and answering every retention only on an answered read (Operation 29, Operation 33); an unreadable policy registry answered by its own refusal, registry-unavailable, on [Place Under Retention]'s refuses line (Operation 24b, Operation 24c), and invalid-policy answered only on a registry the host read (Operation 8a); one stated order over the refusals of [Place Under Retention] and of [Purge], the store read first (Operation 35, Operation 36, Term placement refusal order, Term purge refusal order); Record divergence 2b deleted to Capability requirement 4a; the deployment retaining each destruction's recorded instant, not the destroyed record (Capability requirement 7); the auditor deriving purge eligible on the auditor's own clock (Check 3.2); both deadlines declared as State 6a rounds them. *Over:* a read forbidden to refuse a store it cannot read; a registry outage reported as the store's own failure, on no signature and beside invalid-policy; a storage layer forbidden a destruction whose confirmation it cannot know will arrive in time; an auditor's reproduction that the skewed clocks Clock semantics 3 allows make fail. *Because:* Final Critique 8 found each a divergence between conforming builds or a rule no conforming build could keep, and the corpus already held the cure for the first three: Actor Identity's fifth round answers a failed store read with state-unavailable on every action and an unreachable registry with its own refusal, and the maintainer's ruling of 2026-10-19 on Verified Repair answers each action's refusals in one stated order. Compositions affected: the pages that compose this atom route registry-unavailable and state-unavailable when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 12, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 34) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 33) to Read 2 beside Operation 29; the read's condition off Operation 29, the read off the placement and purge refusal orders, Term database read deleted, and state-unavailable off every signature; rules 156 to 154. *Over:* the page stating for itself what every action answers when the retention records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's eighth Final Critique had made one of the cures the contract's Read family is written from. An unreadable policy registry keeps its own refusal, registry-unavailable: the registry is read at the seam, not from the database. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Place Under Retention]'s refuses line listing its refusals in the order the placement refusal order gave them — invalid-request, registry-unavailable, policy-not-found, invalid-policy, then storage-failure, which answers only at the write — [Purge]'s kept as the page wrote it, already in the purge refusal order's order, and the order cited from the Execution Contract (Capability requirement 12, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 35 and Operation 36, which evaluated the two refusal orders, with Term placement refusal order and Term purge refusal order, and the pairs Operation 6a (policy-not-found only once every well-formedness check passes), Operation 8a (invalid-policy only once they pass and the host read the policy registry), Operation 24c (registry-unavailable only once they pass), Operation 9a and Operation 19a (storage-failure only where no other refusal applies); rules 154 to 147. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's eighth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — The wiring is read outside the records, and a ban on refusing names its ground, as the Execution Contract says.** *Chose:* External check 6, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract, and the label cited on Capability requirement 12; Operation 18's ground clause retired, the rule written as *[Purge] MUST NOT refuse a retention whose purge deadline has passed*, which Execution Contract Refusal 1's second sentence reads as naming the ground, so an unknown, purged or ineligible retention still answers its refusal; rules 147 to 146. *Over:* the page stating for itself that the wiring is an external check, and Operation 18 carrying the ground clause a Final Critique wrote. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the refusal ban among them; this page's Final Critiques had made both cures one specification at a time. What each action does and answers is unchanged.

- **2026-10-22 — The time resolution names the instant its multiples count from.** *Chose:* Term time resolution as the smallest span the deployment's clock and the database tell apart and the epoch its multiples are measured from, both the deployment's declaration (Capability requirement 5, read by External check 3) and fixed for the life of the instance, so every rounding State 4a, State 6a and Operation 13a make lands on one grid in every build; every open line flagged beside its rule; rules 146 to 148. *Over:* a span with no origin, on which one build counting whole resolutions from the Unix epoch and another from the database's own stamp different deadlines for one injected now and answer one [Purge] near a deadline differently. *Because:* Final Critique 9 found it, and the page's own declaration was the place for it: Capability requirement 5 already makes the deployment declare the time resolution. Smaller fixes rode with it, none changing what a rule means: Invariant 6.1, 6.2 and 8.1 and Check 2.1 compare instants with PRECEDES, Operation 8c writes IS NOT IN, and Term actors names the database; the five rules that carried two obligations carry one each, Capability requirement 7 and Record divergence 5 written as one *retain*, Capability requirement 13 split from Capability requirement 10 and Simultaneous retention 7 and 8 from Simultaneous retention 5, Operation 22 deleted to Operation 13 and Operation 21; SEC, FDA, DoD, IRS, NARA and CVV are spelled out; the invariants' closing paragraph calls a purge, not a destruction, what a purged retention shows was lawful. What each action does and answers is unchanged, except that the grid its roundings land on is now declared.

- **2026-10-22 — A destruction is read against every retention in place at it, at the time resolution.** *Chose:* External check 5 reading each destruction against the retentions in place at the destruction (Term retention in place at the destruction): those over the destroyed record whose retention instant the destruction instant, rounded up to the time resolution as State 4a rounds a retention instant, does not precede, so a placement and a destruction that round up to one multiple read as the placement first. *Over:* the selection by a retention instant preceding the destruction instant, which set an instant State 4a had rounded up against one read from the clock as it stood, so a destruction in the span after a placement fell outside the check and a deployment that destroyed a record within that span, years early, passed it; and over deleting State 4a, which would leave the database a retention instant finer than it tells apart. *Because:* Final Critique 10 found it, and the page's open line 2026-10-20-e had named the cure, comparing at the time resolution; within one multiple the records cannot order a placement and a destruction, so the check takes the reading that reports a destruction over the one that hides it, at the cost of reporting a destruction against a retention placed over the record after it inside that multiple. Smaller fixes rode with it: the Summary and the premature-purge example say a purge destroys the record or, where another pattern does the destroying, ends the retention, and the Summary fixes two dates per placement; Simultaneous retention 3 bars [Purge], not every action, from reading a sibling retention, so [Read] answers every retention as Operation 29 says; Composition note 3 is deleted to Simultaneous retention 5 and 6a, which say who owns joint enforcement and when; the four edge-case headings take their families' names; the Storage Failure entry says a retry settles a purge only where its write can commit. Open lines 2026-10-20-c, e, f and g and 2026-10-03-m are closed and 2026-10-20-d narrowed; rules 148 to 147. What each action does and answers is unchanged.

- **2026-10-22 — The flagged lines stand, and a destruction is still read against every retention in place at it.** *Chose:* the page as Final Critique 10 left it: External check 5 and Term retention in place at the destruction reading a placement that races a purge as Simultaneous retention 5 through 8 order the two, through the pattern that owns joint enforcement; the fourteen open lines kept as they stand, each flagged beside its rule; the Summary's *data-minimization rules* and *without anyone having to explain it* said in plain words; the rule count stays at 147. *Over:* the atom serializing a placement against a purge over one record reference, which would take joint enforcement from the composing pattern this page's 2026-10-03 entry on joint enforcement gave it to; and a Capability requirement or a refusal for each value the seam carries, for the range of the purge instant and for a colliding retention id, each deciding an open line's question on this page alone. *Because:* Final Critique 11's readers reported the flagged lines again, twenty-one of twenty-three foundational reports on twelve of the fourteen lines, and none stood on the method's test; the one report on Final Critique 10's cure found a race that Simultaneous retention 6 already serializes, and a placement and a destruction within one multiple of the time resolution read as the placement first, the cost the term states. What each action does and answers is unchanged.

- **2026-10-23 — The database holds every purge instant.** *Chose:* the deployment supplying a database that holds every purge instant [Purge] stamps, for the life of the instance (Capability requirement 14), and open line 2026-10-20-d closed with its flag; open line 2026-10-03-a, the destruction's place in the Execution Contract's pipeline, raised to foundational and escalated; rules 147 to 148. *Over:* a purge whose rounded instant lies past the instants the database holds, which passes its guard, has the storage layer destroy the record (Record divergence 1) and then cannot write (Operation 19), so the retention stays retained over a destroyed record for the life of the instance, every retry destroying nothing and failing again (Record divergence 2a), and, where a composing pattern owns the destruction, the record never becomes a standing record and can never be destroyed (Record divergence 4a). *Because:* Final Critique 11's blind second triage, run on 2026-10-23 by one cold reader given the round's reports, the method's test and the placement rule, placed it foundational, a reachable state with no owner, where the settle's own triage had sent it down as a state the Storage Failure entry names; settled against the text, it holds: Execution Contract Logic confinement 7 gives the deployment the clock's monotonicity, honesty, synchronization, skew and timezone, not its range, and Operation 8c already holds a placement's deadlines inside the instants the database holds. The same triage placed the destruction's place in the pipeline foundational, and that holds too: Conformance 3 keeps every persistent state mutation inside Step 3's database write, so a storage layer outside the database cannot destroy between the guard and the write as Record divergence 1 asks. Its cure is the Execution Contract's text, or a direction for the page that takes the destruction out of the instance, which Defensible Retention's purge rests on (the 2026-10-03 entry above), so it is escalated, and the page waits under Needs Scott.

- **2026-10-23 — The atom destroys nothing outside the database; a composing pattern owns every destruction there.** *Chose:* [Purge] doing only what the database does: where no composing pattern owns the destruction, it removes every version of the record its retention names in the write that stands the retention purged (Operation 13b, with Execution Contract Database 5 cited on Capability requirement 12), so the purged retention is the record of the destruction, and it destroys nothing outside the database (Non-goal 17), a deployment that keeps such a record outside the database composing a pattern that owns the destruction (Non-goal 18); the storage layer's rules deleted, each to the composing pattern that owns the destruction as Record divergence 4 through 6 describe it — Record divergence 1, the confirmation before the write, and 1a, the host's destruction only on a purge judged eligible; Record divergence 2, storage-failure on an unconfirmed destruction, and 2a, the confirmation of a record the layer holds no copy of; Capability requirement 4, the storage layer, and 4a, its dead request; Capability requirement 6, the one path for a destruction where the instance destroyed — with Record divergence 2b's tombstone, which named Capability requirement 4a, pointing at the same owner; Term storage layer, its case-table row and the breakdown for a layer that cannot make a record irrecoverable gone with them; External check 5 reading the purge's removal in place of Capability requirement 6; open line 2026-10-03-a closed as dissolved and 2026-10-20-b narrowed to what is still declared nowhere; rules 148 to 144. *Over:* the Execution Contract naming an external effect inside a transition, a destruction after the guard and before the write whose failure answers storage-failure, under which this page would not have changed. *Because:* the maintainer ruled on 2026-10-23, taking direction (b) of that day's escalation, that every destruction outside the database is owned by a composing pattern, never by the atom, with Execution Contract Conformance 1 and Conformance 3 standing as written; Final Critique 11's blind second triage had found Record divergence 1 placing the storage layer's destruction between the guard and the write, where those two leave it no step, and the ruling dissolves that line. What [Purge] guards, refuses and answers is unchanged. Compositions affected: Defensible Retention, whose purge destroyed through the storage layer, now owns its instance's destruction as Audit Trail owns its own (Record divergence 4), and makes it through a pattern it names as forthcoming.

- **2026-10-24 — A retention is never placed over a destroyed record, and a record reference names every version the purge removes.** *Chose:* the deployment never supplying a placement the record reference of a destroyed record (Capability requirement 15), so a retention placed after a destruction inside the destruction's multiple of the time resolution, which Term retention in place at the destruction counts since the records cannot order the two, is a breach External check 5 reports, now citing the rule, rather than a lawful history it reports as one; and the deployment supplying a record reference that names every version of the record in the database (Capability requirement 16), so the removal Operation 13b obliges reaches the record the retention names. Smaller cures rode with them: State 1 and Operation 28, each an invariant's proposition, deleted to Invariant 1.1 and Invariant 11.2, whose numbers Composition note 5 keeps, with Check 3.2 and the case table citing Invariant 11.2; Term destruction, Term confirmation and Term undestroyed declared, so the rules that turn on them resolve (open line 2026-10-20-b closed); the Summary in six plain sentences that say what one retention holds, and the Healthcare and Legal examples saying the placing pattern picks each record's policy (Composition note 4), which closes two clauses of open line 2026-10-03-i; open line 2026-10-03-f narrowed to the two pairs worded apart, 2026-10-03-g widened to the record references no check reads, and a new open line, 2026-10-24-a, for the declared terms with no term entry; rules 144 to 144. *Over:* reading the tie inside one multiple the other way, which would hide a destruction made in the span after a placement (the 2026-10-22 entry on the retentions in place at a destruction); and a seam input mapping a reference to the record's versions at each purge, where the record reference already names what is retained. *Because:* Final Critique 12's blind second triage placed both foundational, where the settle's own triage had rejected the first on the cost that 2026-10-22 entry accepted and sent the second down as an obligation of the host's; settled against the text, both hold: the specification counts the late placement without saying that a conforming deployment then fails External check 5, and Operation 13b, which the 2026-10-23 entry wrote, has the atom remove a record it holds only by an opaque reference that no rule makes reach the record. What [Purge] guards, refuses and answers is unchanged. The count held at two, so the page waits under Needs Scott.

- **2026-11-21 — Final Critique 14: a ban on refusing names its ground and Purge answers its own blank id; the duplicates and restatements the readers found are deleted.** *Chose:* Operation 18 naming retention-period-not-elapsed as the refusal it bars for a retention whose purge deadline has passed, where it named neither a refusal nor a ground and so, by Execution Contract Refusal 1, barred none; Operation 14 stating not-known for a retention id the records do not hold, a blank or malformed one among them, as Execution Contract Input 3 lets a specification state its own answer; a term entry for the Purge answer ok; Capability requirement 19 declaring the latest instant the database holds, which Operation 8c compares the deadlines with; Identity 3, Identity 9, Operation 17 and Non-goal 1 deleted, each owned by a rule that already states it (their tombstones below); Invariant 4.1 and Invariant 11.2 written as what a version carries and what a reader may not derive from, not as an act (Standard label 14); the deadline terms written in declared terms. *Over:* leaving Operation 18 a rule that binds nothing beside a case table and a Summary that say a late purge is not refused, and Operation 14 left to Input 3's default invalid-request. *Because:* an inert ban promises what no rule of the page keeps, and a blank or malformed id on the one terminal transition has two answers a build may take, invalid-request from Input 3 and not-known from Operation 14.

- **2026-11-26 — The atom converted to the bond shape, un-parked by Scott: it offers the retention id, read by [Read], and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key retention id; carried by retentions; calls Read` (Bonds Key 9, 10, 26), the retention id declared (Key 18); [Read] takes the retention id as a query axis and answers the one retention or none, so it is the existence read and no read is added. No need: the atom records no actor (Non-goal 10). The two `MUST compose <pattern>` Non-goals (11 and 15) tombstoned to the Non-goal that says what the atom does not do; the owners NOTE, the deployment NOTE, the regulated event log term and Composition note 2, two scenarios and one standards line say each job, not a pattern, and the composing-patterns NOTE is gone. The Ok entry stays. Labelled rules 134 before, 132 after; 835 lines before, 865 after. *Over:* the drafted actor id need, and a new single-id read (Read already takes the id). *Because:* unit `atom: Retention Window, converted` (Scott 2026-11-26 9:38 AM Central, "un park").

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Retention Window](./retention-window.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Invariant 9.1, Capability requirement 8 and Capability requirement 9 own it: the host supplies every retention id (Identity 2), and the atom has none of its own to reuse.
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it: a rule that its transition MUST NOT allocate an id restates it.
Deleted: Identity 9. Invariant 9.1 owns it: two retentions never share a retention id.
```

### Structure › State

```
Deleted: State 1. Invariant 1.1 owns it.
Deleted: State 7. Invariant 11.1 owns it.
Deleted: State 8. Invariant 3.2 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 4. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 4a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 6. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 6a. Execution Contract Refusal 1 owns it.
Deleted: Operation 8a. Execution Contract Refusal 1 owns it.
Deleted: Operation 9a. Execution Contract Refusal 1 owns it.
Deleted: Operation 10. Execution Contract Database 1 owns it.
Deleted: Operation 17. Execution Contract Read 4 owns it: a refused call writes nothing and answers its refusal.
Deleted: Operation 19a. Execution Contract Refusal 1 owns it.
Deleted: Operation 22. Operation 13 and Operation 21 own it: [Purge] judges against one injected now per call and stamps purge instant from the injected now.
Deleted: Operation 23. Capability requirement 1 owns it.
Deleted: Operation 24c. Execution Contract Refusal 1 owns it.
Deleted: Operation 25. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 28. Invariant 11.2 owns it.
Deleted: Operation 33. Operation 29 and Execution Contract Read 2 own it.
Deleted: Operation 34. Execution Contract Read 1 owns it.
Deleted: Operation 35. Execution Contract Refusal 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
```

### Structure › Invariants › Invariant 6 — Retention window monotonicity

```
  Deleted: Invariant 6.3. Operation 7 and Operation 7a own a duration that does not advance the deadline, and an invariant restating a precondition is a second owner.
```

### Structure › Invariants › Invariant 8 — Purge timestamp consistency

```
  Deleted: Invariant 8.2. Execution Contract Logic confinement 7 owns it.
```

### Structure › Invariants › Invariant 10 — Retention record durability

```
  Deleted: Invariant 10.3. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 1. External check 5 owns it: a retained retention over the record whose purge eligible was no at the destruction is a retention in place at the destruction whose retention deadline the destruction instant precedes.
Deleted: External check 6. Execution Contract Conformance 9 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Non-goal 13 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › Record divergence

```
Deleted: Record divergence 1. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 1a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2a. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
Deleted: Record divergence 2b. The composing pattern that owns the destruction owns it (Record divergence 4 through 6).
```

### Non-goals

```
Deleted: Non-goal 1. State 10 owns it: the atom holds no storage tier.
```

### Composition notes

```
Deleted: Composition note 3. Simultaneous retention 5 and Simultaneous retention 6a own it: a deployment that places two retentions over one record composes the pattern that owns joint enforcement, and a pattern that owns the destruction owns joint enforcement.
```

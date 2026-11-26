---
title: Consent — history
nav_exclude: true
search_exclude: true
---

# Consent — history

The dated record of how [Consent](./consent.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/consent.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-06-23 — Expiry is derived at check, with the stored `Expired` cache marked as a residual; now is not a signature parameter.** *Chose:* check evaluates expiry against the injected clock (or a caller-supplied `at_time?`, a query parameter, not the clock); the stored-Expired transition an implementation may write is a cache and is marked so. *Over:* threading now into grant / revoke, or treating stored `Expired` as the truth. *Because:* the execution contract injects the clock at the seam, and a stored flag that lags the clock is a cache, not a fact.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the ten invariant numbers and the seven acceptance-check numbers unchanged, the [Check] selection routed through a declared candidate record and the two comparisons through withdrawn and elapsed, the semantic/stored split kept as two rule families with the dated residual note carried over verbatim, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rejection priority [Revoke] carried as an arrow diagram is now carried by the guards — a blank consent id is refused before the store is consulted, the terminal answers are exclusive by Invariant 2.1, and the attribution and temporal checks are conditioned on the record standing in [Granted].

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the consent store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the six rules that restated them tombstoned to their owner — Invariant 8.3, no partial consent record left by a storage-failure, to Store 1; Operation 33, a write the store refused leaving the store as the call found it, to Store 3; Stored state 4, a lazy stored-state write on one consent record serialized, Concurrency 1, a state transition on one consent id serialized, and Concurrency 2 and 3, two concurrent revokes on one consent id answering revoked once and the later one already-revoked, to Store 2; rules 182 to 177. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A refused [Revoke] leaving the consent record in [Granted] stays the atom's own (Operation 32), as do two concurrent grants recording two consent records (Concurrency 4), the stored state as a cache of the derived state (Stored state 1 through 3, Invariant 2.2 and 6.3) and the atom's no-removal rules (Invariant 8.1 and 8.2). [Check]'s point-in-time answer reads the record's own grant, revocation and expiry instants, and [Read] orders by grant instant and consent id, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — [Revoke] answering invalid-request on a blank consent id ahead of not-known, then already-revoked or already-expired, with its attribution and instant faults held to a granted record; storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); Operation 14 (a [Grant] storage-failure only once every grant guard passes) and Operation 17 (not-known only for a consent id that is not blank), which only stated the order, deleted to Refusal 1, and Term grant guard, which only Operation 14 read, deleted with it; rules 172 to 170. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-21 — The state is derived on every answer and never written; withdrawal outranks expiry everywhere; a refused write leaves a granted record granted; an omitted instant resolves from now; a later write is the write's own instants.** *Chose:* the stored state's cache writes deleted — Stored state 1 to Expiry 5 and Execution Contract Database 4, Stored state 2 and Invariant 6.3 to Operation 36 and Operation 49 — with [Read] carrying the consent record's state on every record it answers (Invariant 2.2) and evaluating a state filter against it (Operation 64, Term state filter), so the stored field holds what [Grant] or [Revoke] last wrote and no answer reads it; Expiry 2 and Operation 42 held to a record that is not withdrawn, Invariant 6.1 deleted to Operation 42 and Invariant 6.2, and Check 5.1 held to a record carrying no revocation instant; Operation 32 held to the refused [Revoke] write; Operation 20, 21, 37 and 38 in the corpus's default form, the call's instant where it supplies one and now where it supplies none; Invariant 10.4 deleted to Invariant 10.1 and 10.3, and Check 8.1 to Check 8.2 through 8.4, which now say which later writes they cross; Term later write without its expiry clause. *Over:* a residual cache the 2026-06-23 entry kept and no conforming build can write — [Check] and [Read] are the contract's query surface and never write, and the Database contract runs no expiry — so the page obliged a write it forbade and an equality nothing could keep; a record revoked before its expiry obliged to stand, and to answer, both revoked and expired; a refused [Revoke] obliged to leave a revoked record in granted; a blank instant resolved from the call; a repeated check said to answer alike across a [Revoke] whose instant the at time does not precede; and the record a check answers from counted as a later write whenever its expiry falls after the at time. *Because:* Final Critique 6 found each a divergence between conforming builds or two rules no build can both obey, and the corpus already held each cure: Invitation and Session derive expiry at read time and carry the derived status on every read, the method's entry of 2026-10-08 deletes a broken rule to the rules that already hold its states, and Final Critique 5's own text had scoped the refused write, put withdrawal ahead of expiry, defaulted both instants to now and named only strictly-later writes. What the atom records is unchanged, and each answer is the one the page's other rules already gave.

- **2026-10-22 — A composed retention may dispose of what the atom never removes.** *Chose:* Invariant 8.2, the consent record count that never falls, written with no actor, deleted to Invariant 8.1 and Execution Contract Database 6, so the atom removes no consent record and a purge a composing Retention Window declares (Non-goal 19) is answered by that pattern's records, with Check 1.1 citing Invariant 8.1 alone and Database 6 cited on Capability requirement 5; open line 2026-10-06-a, which asked who guarantees persistence beside a composed retention bound, closed as dissolved by the maintainer's 2026-10-22 ruling: Database 6 says the atom's no-removal rule binds the atom's own actions; rules 170 to 169. *Over:* a count that never falls beside a non-goal sending the retention bound to a composing pattern, which read alone forbids that pattern's purge. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the composed erasure among them; the 06:36Z escalation named this rule among the composed erasure's uncured sites, and Message Preference's ninth Final Critique had made the same cure on its twin. What each action does and answers is unchanged.

- **2026-11-02 — The string cap has a default.** *Chose:* the string cap stated as 1,024 Unicode code points where a deployment declares none, Capability requirement 6 added, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references to a purpose and a revocation reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two; the opaque metadata payload is no string input and stays outside the cap, as the page left it; Operation 68 and Operation 69 hold an over-cap revoking actor or reason to a granted record, as Operation 22 and Operation 23 hold a blank one, so a withdrawn or elapsed record answers already-revoked or already-expired as it does for a blank one.

- **2026-11-26 — The atom converted to the bond shape, batch 2 of the converter: it mints and offers the consent id, needs an actor id, and names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; `Term offer key: key consent id; carried by consent records; calls Read` and `Term need key: key actor id; pairs consent records` (Bonds Key 9, 10, 26), the consent id declared (Key 18); the five `MUST compose <pattern>` Non-goals (2, 13, 17, 19, 21) tombstoned to the Non-goal that states what the atom does not do, the owners NOTE and the WHY naming each job, not a pattern. Labelled rules 164 before, 159 after; 826 lines before, 871 after. *Over:* splitting by length (Scott, 2026-11-25 11:14 PM Central: "don't arbetrarly split at 800 lines"); the converter names no split candidate. *Because:* unit `atom: Consent, converted` (batch 2, 2 of 5).

## Migration notes

- **2026-06-21 — Clearly-marked residual (execution/render-time refactor).** The *authoritative* expiry determination is **derived** at read time: [Check] and [Read] both compute the state from [Expiry Instant] and [Revocation Instant] against the evaluation instant, and [Check] is a pure query that never writes (Operation 36; there is no `expire` action — Expiry 5). The stored [State] field's [Expired] value is therefore a **materialized cache of the derived state, not the authority** — written for query convenience, and required by Invariant 2.2 to equal the derived state at the moment any result is returned. This stored write is the **residual** of this atom against the render-time target, which would carry no stored [Expired] write at all and derive the projection on every read, as Invitation does. It was *clearly marked in the spec* rather than removed: dropping the stored [State] field is a structural change beyond this refactor, the eager/lazy design was introduced deliberately (Final Critique 4, to resolve the semantic-versus-stored contradiction), and because the cache must equal the derived value at read time it cannot serve as a flag that lags the clock in any conforming implementation. A future re-pass may collapse the stored [State] field to a pure read-time projection; that is an open design point, not done in the refactor.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. The rule keeps the words it carried as Clock semantics 4; only the heading changed.
- **2026-09-15 — Clock semantics 5, 6 and 8, kept under Clock semantics.** Clock semantics 5, Clock semantics 6 and Clock semantics 8 stay under Clock semantics rather than under Clock dependence: each is one action's use of a reading Clock dependence 1 already permits, and a family rule does not enlarge because an action instantiates it (council read 75).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Consent](./consent.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 8. Execution Contract Logic confinement 10 owns it.
```

### Structure › State

```
Deleted: State 8. Expiry 1 and Invariant 2.1 own it.
Deleted: State 10. Invariant 1.2 and Invariant 9.1 own it.
Deleted: State 11. Invariant 3.1 owns it.
Deleted: State 12. Invariant 3.2 owns it.
Deleted: State 13. Non-goal 23 owns it.
Deleted: State 14. Non-goal 11 owns it.
Deleted: State 15. Non-goal 24 owns it.
Deleted: State 1. Invariant 2.1 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 7. Composition note 9 owns it.
```

### Structure › State › Stored state

```
Deleted: Stored state 1. Expiry 5 and Execution Contract Database 4 own it.
Deleted: Stored state 2. Operation 36 and Operation 49 own it.
Deleted: Stored state 4. Execution Contract Database 2 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. State 4, Operation 8 and Operation 9 own it.
Deleted: Operation 11. State 5 and State 16 own it.
Deleted: Operation 14. Execution Contract Refusal 1 owns it.
Deleted: Operation 17. Execution Contract Refusal 1 owns it.
Deleted: Operation 21. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 33. Execution Contract Database 3 owns it.
Deleted: Operation 38. Execution Contract Logic confinement 12 owns it.
Deleted: Operation 46. Term evaluation instant owns it: the evaluation instant is the resolved at time in [Check].
Deleted: Operation 53. Execution Contract Query 4 and Operation 47 own it.
Deleted: Operation 54. Instance 2, Operation 47 and Execution Contract Query 3 own it.
Deleted: Operation 60. Execution Contract Query 3 owns it.
Deleted: Operation 61. Capability requirement 1 owns it.
Deleted: Operation 62. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 63. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 6 — Expiry coherence

```
  Deleted: Invariant 6.1. Operation 42 and Invariant 6.2 own it.
  Deleted: Invariant 6.3. Operation 36 and Operation 49 own it.
```

### Structure › Invariants › Invariant 8 — Consent record durability

```
  Deleted: Invariant 8.2. Invariant 8.1 and Execution Contract Database 6 own it.
  Deleted: Invariant 8.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 9 — Revocation non-retroactivity

```
  Deleted: Invariant 9.2. Invariant 9.1 and Invariant 10.3 own it.
```

### Structure › Invariants › Invariant 10 — Point-in-time faithfulness

```
  Deleted: Invariant 10.4. Invariant 10.1 and Invariant 10.3 own it.
```

### Structure › Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.2. Invariant 2.2 and Stored state 3 own it.
Deleted: Check 6.1. Operation 18 and Invariant 3.1 own it.
Deleted: Check 6.2. Operation 19 and Invariant 3.2 own it.
Deleted: Check 6.3. Operation 32 owns it.
Deleted: Check 8.1. Check 8.2 through 8.4 own it.
```

### Edge cases › Clock dependence

```
Deleted: Clock dependence 1. Execution Contract Logic confinement 11 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 5. Operation 8 and Operation 9 own it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Execution Contract Logic confinement 11 owns it.
Deleted: Clock semantics 7. Operation 10 owns it: `now` is never supplied by the business caller, so a grant instant stamped from the injected now is never a caller-supplied instant.
Deleted: Clock semantics 6. Operation 24 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Composition notes

```
Deleted: Composition note 8. Execution Contract Atom interface 1 owns it.
```

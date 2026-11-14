---
title: Credential — history
nav_exclude: true
search_exclude: true
---

# Credential — history

The dated record of how [Credential](./credential.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/credential.md`.

## Decisions

Entries that record a round, a repair or an authoring choice rather than a turn the pattern took, and the two turns that gave the pair its own critical section, which the Store contract took over on 2026-10-19.

- **2026-09-29 — A holder's section ends only at its lease, and a write is judged at its commit.** *Chose:* the pair's critical section ends when its holder releases it or when the lease runs out, and for no other reason, and the store commits a write ONLY IF the writer still holds the section at the commit (Capability requirement 22, 23); the release of a section on a holder judged dead is deleted. *Over:* releasing the section on a belief that the holder had died, with the commit refused only for an overdue holder. *Because:* Final Critique 10 (a cold reader): a store cannot tell a dead caller from a slow one, so a holder judged dead and released could still commit — a second holder passes the check and commits, and the first holder's stale write lands beside it, two effective-active credentials for one pair, which is the breach Capability requirement 8 exists to prevent. The same round drew two lines the page had left open: a fault in a derivation or check function is the deployment's to answer (Non-goal 38), and the salt and the cost of guessing are the function's to supply and not the atom's to require (Non-goal 39).
- **2026-09-29 — The model re-derived against the grounded page.** *Chose:* per-credential deadlines, a call's one reading held from its start to its commit, the pair's section with a holder released as overdue, revoke outside the section, and a store that may begin holding one credential, checked at every settled reading; four twins, each removing one mechanism — the successor link, the section, the refusal of an overdue commit, Operation 65 — and each rejected. *Over:* the 2026-06-21 model, one deadline for every credential and one reading per step, which could not express a rotate on an early reading racing a register on a late one. *Because:* Operation 65 and Capability requirement 22 and 23 exist for exactly those races, and a twin that breaks Invariant 2.1 without each is what shows each is needed.
- **2026-09-29 — What a cold reader found the page never said.** *Chose:* a rotate that states its successor whole (Operation 58 through 64) and may carry the successor's own deadline, with the default a validity duration rather than an instant (Capability requirement 7), since a fixed default instant registers credentials born lapsed once it passes; [Rotate] under the pair's critical section beside [Register], refused when another credential is effective-active for the pair (Capability requirement 8, Operation 65), since a rotate on an early reading and a register on a late one otherwise both commit; a check function per type (Capability requirement 18), since *derive, then compare equal* cannot check a salted hash or a signature, and one-time-code seeds out of scope, since their verifier is not one-way; a type never rebound to another function (Capability requirement 19, 20), since the record carries its type and not its function; the three writes callable only after the composing pattern authenticates the caller, who is what revoked by reference names (Composition note 12 through 15); and a check or external check for each of the seven invariants no check named; and String 7 through 9 narrowed to String 7 and String 9, since [Rotate]'s only string input is the credential id, which an over-long value leaves naming no credential, so Operation 27 answers not-known first and String 8 could never fire. *Over:* the page as the 2026-09-13 rewrite left it and Final Critique 6 passed it. *Because:* Final Critique 7, a cold reader (Sonnet), whose findings a–h were each something a conforming implementation needs and the page did not state.
- **2026-09-29 — The forbidden marker gets its own name.** *Chose:* lapse instant, the instant a store would write when a credential starts to read lapsed, as what State 7 and Check 2.2 forbid. *Over:* *expiry instant*, the page's name for the deadline, which State 2 permits, Operation 12 and 13 record and Invariant 12.2 and Check 2.3 read — so State 7 forbade what four rules require and Check 2.2 failed every store holding a deadline. *Because:* the WHY always meant the `expired_at` column beside a status that stays active; the term it needed did not exist, and it borrowed the nearest one (Final Critique 6, GLM).
- **2026-09-28 — The length bound answers only where a signature can carry it.** *Chose:* String 7 through 9 name [Register], [Rotate] and [Revoke]. *Over:* *an action*, which obliged [Verify] and [Read] to answer an arm their signatures do not carry. *Because:* the rule and the signature block contradicted each other, and the two reads already answer an over-long input correctly without the arm.
- **2026-09-13 — Effective-active uniqueness is enforced by a critical section over the pair, not by a unique partial index.** *Chose:* Capability requirement 8 — the store runs the effective-active check and the register write for one pair as one critical section. *Over:* the store constraint the prose named, *a unique partial index on `(principal_ref, credential_type)` where `status = Active` and the credential is not past expiry instant*. *Because:* an index predicate cannot reference now, and the half of it that can — `where status = Active` — forbids exactly the case Operation 8 permits, a lapsed record standing in active beside its successor. The obligation the prose was reaching for is unchanged; only the mechanism is, and the formal twin built against the old reading is an open Ledger line rather than a silent inheritance.
- **2026-09-13 — Every bound, guard and lookup means effective-active, declared once.** *Chose:* window reading: live | lapsed, and effective-active credential as a credential standing in active that reads live. *Over:* restating *stored active and now < expiry instant* at the uniqueness guard, the verify lookup, the rotate precondition and the revoke precondition, which is how the prose carried it four times. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and this is the atom's single most misreadable claim — an implementation that reads the stored flag at any one of those four sites is the hazard `credential-buggy-toctou.tla` exists to catch.
- **2026-09-13 — live admits an absent deadline, which the corpus's other two window readings do not.** *Chose:* a two-member reading whose live member covers both *no deadline* and *deadline not yet reached*. *Over:* a three-member reading separating the unbounded case. *Because:* nothing in this atom treats an unbounded credential differently from one inside its window — every guard asks the same question and gets the same answer — so a third member would be a distinction no rule consumes. It is worth recording because [Provisional Commitment](./provisional-commitment.md) and [Invitation](./invitation.md) both declare a window reading over a *mandatory* deadline, and this is the first where the deadline is optional.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Credential](./credential.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 12. Execution Contract Database 7 owns it.
Deleted: Identity 13. Capability requirement 34 owns it.
Deleted: Identity 14. Capability requirement 35 owns it.
Deleted: Identity 15. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 4. Invariant 9.1 through 9.3 own it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 8. Execution Contract Database 2 owns it.
Deleted: Capability requirement 9. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 10. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 11. Execution Contract Database 3 owns it.
Deleted: Capability requirement 12. Execution Contract Database 1 owns it.
Deleted: Capability requirement 15. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 16. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 27 owns it.
Deleted: Clock semantics 7. Non-goal 28 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to lease.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 23. Execution Contract Database 2 owns it.
Deleted: Capability requirement 33. Execution Contract Database 7 owns it.
Deleted: Capability requirement 36. Execution Contract Database 7 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. Execution Contract Refusal 1 owns it.
Deleted: Operation 24. Capability requirement 40 owns it.
Deleted: Operation 30. Execution Contract Refusal 1 owns it.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Deleted: Operation 40. Execution Contract Database 1 owns it.
Deleted: Operation 44. Execution Contract Database 1 owns it.
Deleted: Operation 46. Execution Contract Refusal 1 owns it.
Deleted: Operation 47. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Deleted: Operation 48. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Deleted: Operation 49. Execution Contract Read 4 and Execution Contract Database 3 own it: a refused call writes nothing, and a write that did not commit leaves nothing.
Deleted: Operation 55. Operation 51 and Execution Contract Read 2 own it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 74. Execution Contract Read 1 owns it.
Deleted: Operation 75. Execution Contract Refusal 1 owns it.
Deleted: Operation 76. Execution Contract Refusal 1 owns it.
Deleted: Operation 77. Execution Contract Refusal 1 owns it.
Deleted: Operation 78. Execution Contract Input 1 owns it.
Deleted: Operation 79. Execution Contract Input 1 owns it.
```

### Structure › Invariants › Invariant 4 — Revocation is absorbing

```
  Deleted: Invariant 4.1. Invariant 3.1 owns it: a verify answers verified only against the effective-active credential, which a revoked credential is not.
```

### Structure › Invariants › Invariant 8 — Credential material is never persisted

```
  Deleted: Invariant 8.2. Capability requirement 5 owns the one-way derivation function.
```

### Structure › Invariants › Invariant 10 — Credential durability

```
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 11 — A lapse precludes verification

```
  Deleted: Invariant 11.1. Invariant 3.1 owns it: a verify answers verified only against the effective-active credential, which a lapsed credential is not.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 8.2. Check 8.1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 9. Execution Contract Database 1 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Read 4 and Execution Contract Database 1 own it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 3 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 3. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 4. Execution Contract Error model 1 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. Operation 27 owns it.
Deleted: String 10. Term empty material owns it: material is missing only where the material is absent or carries no character, and material of whitespace alone is material, which the derivation function normalizes.
```

### Composition notes

```
Deleted: Composition note 2. Non-goal 8 owns it.
```

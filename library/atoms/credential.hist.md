---
title: Credential — history
nav_exclude: true
search_exclude: true
---

# Credential — history

The dated record of how [Credential](./credential.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/credential.md`.

## Decisions

Entries that record a round, a repair or an authoring choice rather than a turn the pattern took, and the two turns that gave the pair its own critical section, which the Store contract took over on 2026-10-19.

- **2026-09-13 — Effective-active uniqueness is enforced by a critical section over the pair, not by a unique partial index.** *Chose:* Capability requirement 8 — the store runs the effective-active check and the register write for one pair as one critical section. *Over:* the store constraint the prose named, *a unique partial index on `(principal_ref, credential_type)` where `status = Active` and the credential is not past expiry instant*. *Because:* an index predicate cannot reference now, and the half of it that can — `where status = Active` — forbids exactly the case Operation 8 permits, a lapsed record standing in active beside its successor. The obligation the prose was reaching for is unchanged; only the mechanism is, and the formal twin built against the old reading is an open Ledger line rather than a silent inheritance.

- **2026-09-13 — Every bound, guard and lookup means effective-active, declared once.** *Chose:* window reading: live | lapsed, and effective-active credential as a credential standing in active that reads live. *Over:* restating *stored active and now < expiry instant* at the uniqueness guard, the verify lookup, the rotate precondition and the revoke precondition, which is how the prose carried it four times. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and this is the atom's single most misreadable claim — an implementation that reads the stored flag at any one of those four sites is the hazard `credential-buggy-toctou.tla` exists to catch.

- **2026-09-13 — live admits an absent deadline, which the corpus's other two window readings do not.** *Chose:* a two-member reading whose live member covers both *no deadline* and *deadline not yet reached*. *Over:* a three-member reading separating the unbounded case. *Because:* nothing in this atom treats an unbounded credential differently from one inside its window — every guard asks the same question and gets the same answer — so a third member would be a distinction no rule consumes. It is worth recording because [Provisional Commitment](./provisional-commitment.md) and [Invitation](./invitation.md) both declare a window reading over a *mandatory* deadline, and this is the first where the deadline is optional.

- **2026-09-28 — The length bound answers only where a signature can carry it.** *Chose:* String 7 through 9 name [Register], [Rotate] and [Revoke]. *Over:* *an action*, which obliged [Verify] and [Read] to answer an arm their signatures do not carry. *Because:* the rule and the signature block contradicted each other, and the two reads already answer an over-long input correctly without the arm.

- **2026-09-29 — A holder's section ends only at its lease, and a write is judged at its commit.** *Chose:* the pair's critical section ends when its holder releases it or when the lease runs out, and for no other reason, and the store commits a write ONLY IF the writer still holds the section at the commit (Capability requirement 22, 23); the release of a section on a holder judged dead is deleted. *Over:* releasing the section on a belief that the holder had died, with the commit refused only for an overdue holder. *Because:* Final Critique 10 (a cold reader): a store cannot tell a dead caller from a slow one, so a holder judged dead and released could still commit — a second holder passes the check and commits, and the first holder's stale write lands beside it, two effective-active credentials for one pair, which is the breach Capability requirement 8 exists to prevent. The same round drew two lines the page had left open: a fault in a derivation or check function is the deployment's to answer (Non-goal 38), and the salt and the cost of guessing are the function's to supply and not the atom's to require (Non-goal 39).

- **2026-09-29 — The model re-derived against the grounded page.** *Chose:* per-credential deadlines, a call's one reading held from its start to its commit, the pair's section with a holder released as overdue, revoke outside the section, and a store that may begin holding one credential, checked at every settled reading; four twins, each removing one mechanism — the successor link, the section, the refusal of an overdue commit, Operation 65 — and each rejected. *Over:* the 2026-06-21 model, one deadline for every credential and one reading per step, which could not express a rotate on an early reading racing a register on a late one. *Because:* Operation 65 and Capability requirement 22 and 23 exist for exactly those races, and a twin that breaks Invariant 2.1 without each is what shows each is needed.

- **2026-09-29 — What a cold reader found the page never said.** *Chose:* a rotate that states its successor whole (Operation 58 through 64) and may carry the successor's own deadline, with the default a validity duration rather than an instant (Capability requirement 7), since a fixed default instant registers credentials born lapsed once it passes; [Rotate] under the pair's critical section beside [Register], refused when another credential is effective-active for the pair (Capability requirement 8, Operation 65), since a rotate on an early reading and a register on a late one otherwise both commit; a check function per type (Capability requirement 18), since *derive, then compare equal* cannot check a salted hash or a signature, and one-time-code seeds out of scope, since their verifier is not one-way; a type never rebound to another function (Capability requirement 19, 20), since the record carries its type and not its function; the three writes callable only after the composing pattern authenticates the caller, who is what revoked by reference names (Composition note 12 through 15); and a check or external check for each of the seven invariants no check named; and String 7 through 9 narrowed to String 7 and String 9, since [Rotate]'s only string input is the credential id, which an over-long value leaves naming no credential, so Operation 27 answers not-known first and String 8 could never fire. *Over:* the page as the 2026-09-13 rewrite left it and Final Critique 6 passed it. *Because:* Final Critique 7, a cold reader (Sonnet), whose findings a–h were each something a conforming implementation needs and the page did not state.

- **2026-09-29 — The forbidden marker gets its own name.** *Chose:* lapse instant, the instant a store would write when a credential starts to read lapsed, as what State 7 and Check 2.2 forbid. *Over:* *expiry instant*, the page's name for the deadline, which State 2 permits, Operation 12 and 13 record and Invariant 12.2 and Check 2.3 read — so State 7 forbade what four rules require and Check 2.2 failed every store holding a deadline. *Because:* the WHY always meant the `expired_at` column beside a status that stays active; the term it needed did not exist, and it borrowed the nearest one (Final Critique 6, GLM).

- **2026-09-29 — The two functions a type declares, tied.** *Chose:* a check function that matches the material its type's derivation function derived the verifier from, normalizing as it does (Capability requirement 29, 30), confirmed by an External check on material the auditor supplies. *Over:* two independent declarations, under which an always-no-match check function satisfied every rule. *Because:* Final Critique 9 (a cold reader); the split was this page's own, made when Final Critique 7 separated checking from deriving. The same round scoped Invariant 2.1, 4.1 and 11.1 to the reading they hold at, moved Identity 12 through 15 to the deployment's family, and wrote down what a verified public key does not establish.

- **2026-09-29 — Authenticated as whom.** *Chose:* the authorized caller — authenticated as the principal the call names, admitted by an enrollment pattern's own proof for a principal holding no credential, or authorized over the principal by a composing Permissions decision — behind every credential write (Composition note 12 through 14), and [Read] exposed only to an authorized caller (Composition note 16). *Over:* *authenticating the caller*, which a caller authenticated as Alice satisfies while rotating Bob's credential, and which a principal's first registration cannot satisfy at all. *Because:* Final Critique 8 (a cold reader), and the binding half of the section titled *Authentication precedence* in `pressure-testing.md`. The same round moved lockout and multi-factor sequencing off Login, which disclaims both, onto the deployment.

- **2026-09-29 — Built cold: where the cryptography runs.** *Chose:* the derivation and check functions run at the seam, and the entropy a salted derivation consumes is supplied there (Capability requirement 24 through 26); the default validity may be declared unbounded, where the term said a deployment could declare none against Capability requirement 7's obligation to declare it; Operation 20 speaks of checking presented material, as Operation 21 through 23 do. *Over:* a registry *supplied* at the seam and silently *run* inside the transition, with no source for a salt. *Because:* the cold regeneration built a salted password and a public key, and Execution Contract Logic confinement 1 and 3 allow neither the cryptography nor the entropy inside a transition (council read 266).

- **2026-10-19 — The store's guarantees cited, not restated, the pair's critical section among them.** *Chose:* the credential store supplied under Execution Contract Store 1 through 4 (Capability requirement 37), and the twenty-one rules that restated them tombstoned to their owner — Operation 40 and 44, Capability requirement 12, Invariant 10.2, External check 9 and Atomic writes 1, 3 and 4, a transition's writes committed whole, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Atomic writes 5, a refused rotate leaving the prior credential active, to Operation 47 and Store 1; Capability requirement 11, a write acknowledged only once it commits, and Concurrency 4, [Verify] answering from a committed state, to Store 3; Concurrency 1, the standing check and the status change as one operation, to Store 1 and Store 2; Capability requirement 8, 17 and 23 and Concurrency 2 and 3, the pair's check and write run as one critical section held through the write, and a concurrent call answering from what the other committed, to Store 2, and with them the section's release and lease (Capability requirement 9, 21 and 22), since the atom names no section any more; rules 266 to 246. *Over:* the atom running its own critical section over the pair, with a lease the deployment declares, an overdue holder released and a write refused outside the section — the turns of 2026-09-13 and 2026-09-29, now in the history. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract: Store 2 reads the state an action's guards decide on — for [Register] and [Rotate], the pair's credentials — inside the transaction that writes the action's effects, which is what the section was for. The checks that compare an auditor's earlier read with a later one (Check 6.1, 7.1 through 7.3, 8.1 and 8.2) rest on the auditor's own reads, and the atom keeps a credential's history as separate records (Identity 6), so it cites neither History 1 nor Order 1. Operation 65 and the settled reading stay, since the rotate race they close comes from two readings of now; what the atom does for its domain is unchanged.

- **2026-10-21 — A failed read answers on every action, each write's refusals in one stated order; the ids the deployment supplies fit the string policy; verified is answered only against the effective-active credential.** *Chose:* state-unavailable on all five actions where the read of the credential store fails, the Execution Contract's Step 1 failure (Operation 74, Term store read), [Verify] and [Read] answering only on an answered read (Operation 18, Operation 55, Term proceeding verify, Term admitted read, Concurrency 5), and the refusals of [Register], [Rotate] and [Revoke] each in one stated order, the store read first and the page's standing checks ahead of the inputs (Operation 75 through 77, the three refusal order terms); id material never blank and never longer than the length bound (Capability requirement 38, 39); the settled reading as the one at which Invariant 2.1 and Check 1.1 judge a pair, where it had been the only one at which a pair's credentials are judged at all (Term settled reading); and Invariant 4.1 and 11.1 deleted to Invariant 3.1, which already answers verified only against the effective-active credential. *Over:* a verify whose read failed answered as no-active-credential, which a lockout counts as a failed verification; a blank id [Read] answers two ways, and an over-long one no [Revoke] can cancel; a term that forbade the pair check Operation 65 makes at the rotate's own reading; invariants that, read alone, forbid verifying a pair holding a revoked or lapsed credential beside its live one. *Because:* Final Critique 13, the council's first round on the page, found each a divergence between conforming builds or two rules no build could keep, all in text Final Critique 12 had read. The failed read takes the form Actor Identity's, Retention Window's, Tamper Evidence's and Permissions' rounds gave it, over Final Critique 12's refining class for it, and the two invariants go by the entry *A rule the page's lawful states break is first checked for a rule to delete it in favour of* in `pressure-testing.md`. Rules 246 to 250. Compositions affected: the pages that compose this atom route state-unavailable from all five actions when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 37, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 74) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 55) to Read 2 beside Operation 51; the read's condition off the rules and terms it held to an answered read (Operation 18, Concurrency 5, Term proceeding verify), and Term admitted read, which held only that condition, deleted, so its rules and checks name [Read] (Operation 51, Operation 52, Operation 69, Operation 73, Invariant 12.2, Check 2.3, Check 5.3, Check 5.4); the read off the register, rotate and revoke refusal orders, Term database read deleted, state-unavailable off every signature and off the Intent; rules 250 to 248. *Over:* the page stating for itself what every action answers when the credential records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's thirteenth Final Critique had made one of the cures the contract's Read family is written from, and Read 3 keeps what it said of [Verify]: a failed read is no failed verification. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each writing action's refuses line kept as the page wrote it, already in the order its refusal order gave — [Register] invalid-request, duplicate-active-credential; [Rotate] not-known, not-active, invalid-request; [Revoke] not-known, already-terminal, invalid-request; storage-failure last on each, answering only at the write — and the order cited from the Execution Contract (Capability requirement 37, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 75, Operation 76 and Operation 77, which evaluated the three refusal orders, with Term register refusal order, Term rotate refusal order and Term revoke refusal order, and the pairs Operation 7 (duplicate-active-credential only once every well-formedness check passes), Operation 30 (a standing rejection only for a credential id naming a credential), Operation 34 (invalid-request only once every standing check passes) and Operation 46 (storage-failure behind every precondition), with Term standing check, Term standing rejection and Term well-formedness check, which only those pairs read; rules 248 to 241. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's thirteenth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-22 — An admitted call and a ban's ground are the Execution Contract's.** *Chose:* the three admitted terms (register, rotate, revoke) citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried, and Read 4 cited on Capability requirement 37; Non-goal 37 kept as written and read by Execution Contract Refusal 1's second sentence, which the page already cites, so the ban names its ground, a rotate to the prior credential's material, and keeps [Rotate] from no refusal its line declares, an unknown or inactive credential and a blank input still answering theirs; the rule count stays at 241. *Over:* the page stating for itself which calls its effect rules reach; Non-goal 37 read alone, keeping [Rotate] from every refusal on such a call. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect and the refusal ban among them; the 12:03Z escalation named Non-goal 37 among the refusal ban's uncured sites. What each action does and answers is unchanged.

- **2026-11-02 — The length bound has a default.** *Chose:* the length bound stated as 1,024 Unicode code points where a deployment declares none; String 7, String 9 and Capability requirement 39 stand, Capability requirement 14 turned to *declare*, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from references and identifiers to a revocation reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-11-20 — The material bound has a default, and the page cites the contract's labels.** *Chose:* the material bound stated as 4,096 code points of the material as the call carries it where a deployment declares none for the credential type, Capability requirement 27 turned to *declare* PER Execution Contract Input 2; Capability requirement 24 cites Logic confinement 8, Capability requirement 35 cites Logic confinement 16 and gains External check 16, the seam, the transition and the clock reading cite Logic confinement 14 and 11 by label, and Capability requirement 30 owns a check's normalization of presented material of no kind the derivation function normalizes (a signature beside a public key). *Over:* a bound the deployment must supply, or a value waiting on the maintainer. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override, and Actor Identity and Tamper Evidence already state 4,096 code points for the cryptographic material they bound; the other lines were already decided by Logic confinement 8, 10, 14, 16 and 20 and the page's own Operation 58.

- **2026-11-25 — The atom reorganised into the tree order and bonded: a credential belongs to one actor id, and no pattern is named.** *Chose:* the tree order Task, List and Ordering stand in, every label kept and none renumbered, no rule added; the need `key actor id; pairs credentials`, the principal reference being the actor id of the principal the credential binds; checking presented material stays the atom's own rule, and opening a session after a good check is the app's sign-in glue (Composition note 1 tombstoned to Non-goal 5); Non-goal 2, 6, 10 and 21 tombstoned to the Non-goal that owns the declined job, and Non-goal 13, 28, 30 and 32, Composition note 4 through 11 and 18, External check 4, 5, 7 and 8 and Term authorized caller say the job without naming a pattern. *Over:* a credential bound to an opaque principal reference no atom offers, and a page naming eleven other patterns. *Because:* Scott's ruling of 2026-11-25 9:49 AM Central ("Go with your 'task'"), the unit `atom: Credential, bonded`.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Credential](./credential.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 12. Execution Contract Database 7 owns it.
Deleted: Identity 13. Capability requirement 34 owns it.
Deleted: Identity 14. Capability requirement 35 owns it.
Deleted: Identity 15. Execution Contract Database 7 owns it.
Deleted: Identity 11. Operation 4 owns it: a credential type naming no derivation function is refused at [Register].
```

### Structure › State

```
Deleted: State 4. Invariant 9.1 through 9.3 own it.
Deleted: State 15. Invariant 10.1 owns it.
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
Deleted: Capability requirement 38. Execution Contract Input 2 owns it: the host allocates an id that is not blank.
Deleted: Capability requirement 39. Execution Contract Input 2 owns it: the host allocates an id that does not exceed the cap of every input naming a record by its id.
```

### Structure › Operations

```
Deleted: Operation 7. Execution Contract Refusal 1 owns it.
Deleted: Operation 24. Capability requirement 40 owns it.
Deleted: Operation 30. Execution Contract Refusal 1 owns it.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Deleted: Operation 40. Execution Contract Database 1 owns it.
Deleted: Operation 44. Execution Contract Database 1 owns it.
Deleted: Operation 45. Execution Contract Read 4 owns it: a call whose write fails answers storage-failure.
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

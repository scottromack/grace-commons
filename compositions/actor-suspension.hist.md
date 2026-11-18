---
title: Actor Suspension — history
nav_exclude: true
search_exclude: true
---

# Actor Suspension — history

The dated record of how [Actor Suspension](./actor-suspension.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/actor-suspension.md`.

## Decisions

Entries that record a migration or an editorial rule rather than a turn the pattern took.

- **2026-08-29 — The cascade is completed, never undone: intent before any revoke, outcome after every one, a `Suspending` state between, and a bounded sweep as the composition.** *Chose:* an intent record under the operator's credential carrying the plan, written before the first irreversible revoke; every revocation standing once committed; a `Suspending` state the issuance gate treats as closed and [Suspension Report] shows with the open members; the outcome appended only after every revocation; a resume arm on [Suspend Actor]; a completion sweep bounded by the completion bound and the audit horizon, attested under a declared service identity behind a recovery-intent record, pre-checked by a seam-injected invocation identity; every substrate transcription carrying its step; the two stores classified; and the partial-failure-posture knob removed. *Over:* the grounded revision's one-transaction all-or-nothing cascade with rollback. *Because:* no constituent declares the rollback that posture rested on — a revoked grant, session or credential is terminal by its atom's own invariant and the audit append cannot be withdrawn — and the wiring that claimed it could leave a sealed outcome enumerating revocations the rollback had undone, a false record nothing can withdraw; and every revocation ran before the operator's credential was verified. The pattern was grounded before the durability-boundary and authentication-precedence rules existed; it returns to `partially resolved` until a fresh gate re-grounds it (the frozen rules — *Durability boundaries*, *Authentication precedence*, *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).

- **2026-08-30 — The resumer is verified before it revokes, absence is a miss, the intent's own appended arm is landed, every credential is enumerated, and liveness is arithmetic.** *Chose:* a resume-intent record under the resumer's credential before a resumed cascade touches a member, with the resumer, the resume event and the recovery marker on the outcome and the operator named on every outcome; an absent index key read as a miss and resolved through the trail's tail above a high-water mark the sweep advances, so a crash between the durable intent and the index write cannot let a second intent or a fresh grant through; the intent's own appended-but-refused arm read back and proceeded on as landed, the position rather than the step exported, and the invocation yielding the act at the outcome position instead of retrying beside the sweep; the per-actor critical section taken at the gate and declared, with a stalled invocation adopting a landed outcome under a lapsed lease; every effective-active credential across every type, planned and revoked as a set; the plan sized against the substrate's payload cap before the intent; the strict inequality over the bound, the cadence and the write latency against the window, checked at instance start; the clock offset allowance under every cross-seam comparison the checks make; and, on the closure check, the mark made the line — the trail answers above it, the index answers below it as a truth-bearing store. *Over:* a resume that revoked under the resumer's reference and verified nobody until the outcome; *absent is active* beside *rebuild on miss*; *nothing has committed* at a step whose arm arrives appended; *the actor's active credential*; a cadence-no-longer-than-window inequality; a bare recording failure on both sides of the commit; and a mark that silently turned absence below it back into an answer. *Because:* a revocation is irreversible and the principal it is attributed to must be the one whose credential was checked; a keyed index repairs only what it can observe missing; a second intent is a second plan the sweep pairs twice; Credential's effective-active bound is per pair, so one revocation leaves the other type authenticating; a window promise whose inequality omits the bound and the latency is breached on every orphan with the check passing; and a keyed read that enumerated the whole retained trail for every never-suspended actor would keep the miss rule total at a cost the issuance gate cannot pay, so the durability obligation is declared and its breach made a finding rather than a silent active (the frozen rules — *A compensator is exclusive*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, *Capability provenance*, *A derived index is trustworthy only where a miss is observable*, *A transcribed rejection arm keeps its payload*).

- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its store, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check counts. *Because:* every one of those figures had moved since it was written, so the clause asserting that nothing was weakened was itself stale — a number a tool can compute belongs to the tool, and the corpus has now lost the same wager often enough to write the prohibition down.

- **2026-09-15 — Rewritten in GRACE lang v0.41.** *Chose:* 133.6 KB of prose replaced by labelled rules across fifteen families, five invariant numbers unchanged, seven of nine Ledger lines closed by the rewrite. *Over:* a transliteration that would have carried the page's stale counts and its unclosable-member trap into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the two lines that stay open are the formal model's, which is a model change and not a language one.

- **2026-09-15 — An unclosable member is named, not owed.** *Chose:* a planned member a constituent answers `not-known` or invalid-request for joins the **unresolved members**, rides the outcome as its own field, and lets the act complete; *accounted* is the predicate the completeness check runs on — closed, already terminal, or named unresolved. *Over:* leaving such a member in the open members. *Because:* the sweep closes only still-active planned members, so a handle the constituent has lost could never be closed: the actor stayed `Suspending` forever and the every-planned-member-accounted check failed permanently against a cascade that had in fact done everything available to it. *Open* means a door this composition can still close; *unresolved* means a door whose handle the constituent lost, and conflating the two made a store inconsistency look like an unfinished suspension.

- **2026-09-15 — The credential arm carries its position, like the recording arm.** *Chose:* `invalid-credential(intent | outcome)` on [Suspend Actor]'s signature. *Over:* mapping a credential rotated mid-act onto `recording-failure(outcome)`. *Because:* the recording arm's outcome position tells a caller to resume, and a caller resuming on the credential that just refused resumes into the same refusal, forever. The positioned credential arm says the true thing instead — the revocations stand, this credential no longer attests, and the outcome is not this caller's to write — which routes the act to a resume under a different verified operator, or to the sweep (the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`).

- **2026-09-15 — The plan is built from stored status, and the report says when an enumeration has aged out.** *Chose:* the snapshot selects by the constituent's stored status, so a lapsed-but-stored-active session enters the plan and its revoke answers benignly by the constituent's own derivation; and [Suspension Report] answers a past-horizon suspension with the state, the instant, the operator and the binding, marking the enumeration unavailable-past-horizon. *Over:* enumerating by derived status, and answering an empty revoked set past the horizon. *Because:* the plan is the record of what the suspension set out to close, and a member dropped by derivation is a member the record never mentions; and an empty enumeration where the enumeration has merely aged out is a record saying nothing was closed — the exact class of false record this composition exists to prevent.

- **2026-10-20 — The store's guarantees cited, not restated, the per-actor critical section among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 47), and the fifty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — the composition's stores held at the constituents' durability (Capability requirement 39, External check 9), to Store 3, and an entry lost below the mark read as a durability breach (Composition state 30, 31, Check 3.3), to Store 3 and Store 4; the per-actor critical section the host supplied (Capability requirement 29) and every rule taking or holding it at the state gate, through the index write, across a cascade's revocations, at the sweep's pre-check and against a second sweep (Action wiring 1, 2, 3, 22, Reconciliation 10, 13, 14, 30, Concurrency 1 through 5, External check 7, 8), its release, its lease and its terminus, the bar on running without it, its loss or unavailability mid-call, the sweep's skip of a held actor and the report's exemption (Capability requirement 30 through 35, Action wiring 23, 24, 54, 69, Reconciliation 11, 12, Concurrency 9), and a call's pre-check and adoption of an outcome another writer landed (Action wiring 43, 44, 46, 47), to Store 2, the sweep keeping its own pre-check (Reconciliation 15 through 17); to Store 1, under which an action's intent, revocations and outcome commit together, a constituent's storage failure leaving open members, the revocation-failure answer and the suspending actor it left (Action wiring 33, 40, 41, 42), the re-query of a revoke whose answer was lost (Atomic writes 5 through 9), the bar on enlisting a revocation in a transaction (Wiring decision 4, Atomic writes 4), the sweep's young-intent edge (Reconciliation 5, 8, Check 6.9), and the read-back of a recording-failure at the retention step, a split Audit Trail's own rewrite removed (Audit arm 7, 9, 16); and to Store 1 and Store 3 the restart sweep and the dead-process rule (Capability requirement 44, Reconciliation 1, 24); with them revocation-failure leaves [Suspend Actor]'s signature, no kept rule answering it; rules 478 to 421. *Over:* a host critical section per actor, held from the state gate through the index write and leased to the suspension completion bound; a cascade left standing partial by a constituent's store failure, its open doors named for a resume or the sweep to close; and a sweep bounded below by the completion bound and run at every restart — the critical section and its lease are a turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: every revoke and every record this composition makes is a store write, so a constituent's store failure fails the whole act and nothing of it commits, Store 2 reads what a state gate or the sweep decides on inside the transaction that writes it, which is what the critical section was for, and no crash leaves half an act for the sweep to find. The intent before any revoke, the suspending state, the resume, the sweep, the completion window and the escalation stay on the refusals that still stop a cascade at its outcome; the indexes stay outside every action's transaction (Composition state 18), so the mark, the miss and the tail read stay; and the suspension completion bound stays in the closure floor (Capability requirement 23, 27). What the composition does for its domain is otherwise unchanged.

- **2026-11-04 — A recording or credential failure at the outcome is answered, not refused, so the revocations it follows stay committed.** *Chose:* [Suspend Actor] answering recording-failure and invalid-credential carrying outcome beside the suspension result, refusing only those carrying intent, so a call whose outcome Audit Trail refuses is admitted and its intent and revocations commit together (Execution Contract Database 1), the outcome owed to the sweep (Audit arm 15, 17, 20, 23, 24, 30, Term position). *Over:* the outcome arms on the refuses line, read as committed revocations while Execution Contract Read 4 has a refused call write nothing (open line 2026-10-26-c), and landing them carrying intent, which would undo revocations Action wiring 38 keeps. *Because:* the ruling of 2026-10-31 16:48Z answered the (b) shape for this page: keep, in the form Propagate Consent Revocation Downstream took for the same open line.

- **2026-11-18 — A composition action reads the clock once: Clock semantics 9 retires to Execution Contract Logic confinement 19.** *Chose:* Clock semantics 9 (the composition compares no constituent's stamp against a write) leaves its `Deleted:` tombstone naming Logic confinement 19 and the ruling, never renumbered or reused: a suspension's or a reinstatement's constituent calls read the call's one now. Citations found, by label: none on the page (`cites.py`: nothing rests on it); `actor-suspension.als`'s NOT CHECKED note cited Clock semantics 9 through 11 for Invariant 1.4's cross-seam order and now cites 10 and 11, a comment alone, the model otherwise unchanged; no twin or coverage row names it. Kept, each with its subject: Clock semantics 10 and 11, the Generation acceptance's standing rule for a cross-seam comparison, Capability requirement 38 and Term clock offset allowance, since a stamp this composition writes is still set against records other calls stamped, a resumed cascade and the sweep among them (Clock semantics 12; Execution Contract Logic confinement 7 and 18). Rules 1 fewer. *Over:* retiring Clock semantics 10 and 11 with it: a resume is a new call and reads a later clock, so two seams' stamps across calls still meet. *Because:* Scott, 2026-11-18 6:52 AM Central, "YYY" (rounds/escalations.md 2026-11-18 12:52Z, item 2, on the measure of 06:09Z): a composition action reads the clock once, and every constituent call it makes takes that reading as its now, from MIT's sync-engine (github.com/mit-sdg/sync-engine), which binds one instant per causal flow. The page takes a delta round.

## Ledger

The gate record the Ledger's `last gate:` line carried behind its latest until 2026-10-20:

- 2026-06-10 — Final Critique 4, fresh reader — clean

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Actor Suspension](./actor-suspension.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 30. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Composition state 31. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 29. Execution Contract Database 2 owns it.
Deleted: Capability requirement 30. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 32. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 33. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 34. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 35. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for a deployment to lack.
Deleted: Capability requirement 39. Execution Contract Database 3 owns it.
Deleted: Capability requirement 44. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Capability requirement 46. Execution Contract Logic confinement 7 owns it.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 7. Execution Contract Database 1 owns it.
Deleted: Audit arm 9. Execution Contract Database 1 owns it.
Deleted: Audit arm 16. Execution Contract Database 1 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Deleted: Action wiring 22. Execution Contract Database 2 owns it.
Deleted: Action wiring 23. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lose.
Deleted: Action wiring 24. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to find unavailable.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 35. Primitive policy 11 owns it: a credential Credential refuses as invalid-request still stands effective-active, so the act answers invalid-request and commits nothing (Invariant 1.3, Execution Contract Read 4).
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Reconciliation 17 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Reconciliation 17 and Execution Contract Database 2 own it.
Deleted: Action wiring 46. Reconciliation 16 and Execution Contract Database 2 own it.
Deleted: Action wiring 47. Reconciliation 15 and Execution Contract Database 2 own it.
Deleted: Action wiring 54. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Action wiring 69. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for [Suspension Report] to take.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Deleted: Reconciliation 10. Execution Contract Database 2 owns it.
Deleted: Reconciliation 11. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for another holder to hold.
Deleted: Reconciliation 12. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, so the sweep skips no candidate.
Deleted: Reconciliation 13. Execution Contract Database 2 owns it.
Deleted: Reconciliation 14. Execution Contract Database 2 owns it.
Deleted: Reconciliation 24. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 30. Execution Contract Database 2 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 3.3. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Check 6.9. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 7. Execution Contract Database 2 owns it.
Deleted: External check 8. Execution Contract Database 2 owns it.
Deleted: External check 9. Execution Contract Database 3 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Identity 16, Action wiring 48 and Action wiring 84 own it: intent instant, suspension instant and reinstatement instant are every timestamp this composition stamps, and each takes the injected now.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 8. Composes 31 owns it.
Deleted: Clock semantics 13. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 14. Non-goal 19 owns it.
Deleted: Clock semantics 9. Execution Contract Logic confinement 19 owns it: a composition action reads the clock once and every constituent call it makes takes that reading as its now, so a constituent's stamp the call wrote is the now its own writes carry (Scott, 2026-11-18 6:52 AM Central, "YYY", rounds/escalations.md 2026-11-18 12:52Z, item 2).
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no serialization obligation for [Suspension Report] to stand outside.
```

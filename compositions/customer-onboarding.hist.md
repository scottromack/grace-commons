---
title: Customer Onboarding — history
nav_exclude: true
search_exclude: true
---

# Customer Onboarding — history

The dated record of how [Customer Onboarding](./customer-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/customer-onboarding.md`.

## Decisions

Entries that record a migration or a regeneration rather than a turn the pattern took.

- **2026-08-26 — Invariant 4 is narrowed to the actor the composition authenticates.** *Chose:* the clearing actor, whose credential is verified, attests that fresh evidence naming the verifying actor was recorded before the reinstatement. *Over:* requiring `verifying_actor_ref == actor_ref`, or taking a second credential. *Because:* the first collapses a real separation of duties (an analyst gathers evidence, a manager clears the review) and the second is a signature change; the guarantee was narrowed to what the records can show.

- **2026-08-27 — The active-relationship retention is a renewed chain, not one placement.** *Chose:* the periodic path of [Trigger Monitoring Review] places a fresh active-relationship retention at every review, recorded as `customer-onboarding.retention-renewed`, with Configuration requiring the policy's duration to exceed the review interval. *Over:* a single placement at intake, or an active-case purge gate composed through Defensible Retention. *Because:* a Retention Window placement is fixed-duration and its policy immutable, so a single placement lawfully lapses under a relationship longer than its duration; a purge gate would protect the record but leave it under no retention obligation at all, and the composition exposes no purge surface to gate.

- **2026-08-29 — The reconciliation is a declared, bounded scan whose pre-check keys on the intent.** *Chose:* onboarding_completion_bound below and the audit horizon above; compensation window and reconciliation cadence declared; the pre-check traversal matched on intent event id rather than on "the same identifying payload". *Over:* a retry-until-lands with an undeclared cadence and a payload-resemblance pre-check. *Because:* the pre-check cannot see an invocation that has not written yet, so a re-emission inside the bound lands a second outcome for one act; and resemblance chooses where a key does not (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*).

- **2026-09-14 — Rewritten in GRACE lang v0.41.** *Chose:* 180.5 KB of prose replaced by labelled rules across fifteen families, eight invariant numbers unchanged, thirty-eight of thirty-nine Ledger lines closed by the rewrite. *Over:* a mechanical transliteration that would have carried the page's four internal contradictions into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the repairs are named in the entries above and in the commit that lands this.

- **2026-09-14 — The monitoring schedule and the open-trigger set are derived indexes, not extraction-pending state.** *Chose:* all four indexes classified as derived index, each with a named rebuild, a per-index definition of *miss*, and the same horizon bound; the proposed **Review Schedule** atom kept as `Non-goal 17` rather than as a classification. *Over:* keeping the schedule half flagged extraction-pending, or extending the flag to the open-trigger set for consistency. *Because:* the section titled Composition state in `execution-contract.md` asks one question — is every fact derivable from the constituents' stores through their declared reads — and the spec's own rebuild answered yes for both, in the same subsection that flagged one of them as non-derivable. Two sentences cannot both be the classification, and the Contract's test picks which. The extraction may still be worth making; it is a concept named for someone to own, not a debt riding this composition's classification. Closes the Ledger's `2026-08-26-k` (the flag asserted Pass 2 gates nobody ran) and `2026-08-29-l` (Gate 3 applied unevenly across four elements).

- **2026-09-14 — The external path admits `Unverified` and nothing else.** *Chose:* one guard and one parameterized refusal, [Party Not Admissible], naming the state found. *Over:* keeping the `party-closed` arm and adding a second arm for `Verified` and `Suspended`. *Because:* the prose guarded `Closed` alone, so a `Suspended` admit opened a case with an empty open-trigger set against a suspended party and a `Verified` admit passed the gate with no verification record of this composition's — a hole in the composition's own load-bearing guarantee, reachable from the ordinary external path. A second arm beside `party-closed` would have split one guard's answer across two codes; the fold gives the caller one code and the state it needs.

- **2026-09-14 — state-unavailable is mapped from the seam, not from a constituent arm.** *Chose:* an unanswered constituent read is the state-unavailable of the section titled Step 1 failure in `execution-contract.md`, and Party Identity's declared `invalid-query` arm maps to invalid-request as this composition's own defect. *Over:* continuing to map state-unavailable from Party Identity's `read`. *Because:* that atom's `read` declares two answers — the matching parties, or `invalid-query` — and neither is an unreadable store, so the mapping named a contract the constituent does not have. The gate's fail-closed behaviour is unchanged; what changed is where the page says it comes from.

- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* a clearance forbidden to drop a trigger its record does not name (Action wiring 106), where the rule had forbidden emptying the set — which every healthy clearance does; the external path's unanswered read answered state-unavailable (Action wiring 154), as the trigger and the gate already answer it; and position defined by what the rules use it for — whether a constituent write had committed — rather than by which record failed, which eleven rules contradicted, Action wiring 17 and 62 among them. *Over:* the 2026-09-14 rewrite's readings. *Because:* the prose said *never clear the set*, meaning never sweep it wholesale, and the rewrite made it a prohibition the page's own walkthrough breaks; and a read with no answer had no landing at initiation.

- **2026-10-20 — The store's guarantees cited, not restated, and an onboarding action's writes one transaction.** *Chose:* Capability requirement 45 citing Execution Contract Store 1 through 4 for the store the three constituents and the four indexes keep their records in; the rules restating what that store guarantees tombstoned to it — the per-party serialization of a state-changing action, a losing transition's answer, the one-invocation hold on a case's open-trigger set, the reconciliation's exclusion from a held case and from a second reconciliation, and the invalid-credential at an outcome, which the one transaction's read of the actor registry forecloses (Concurrency 1, 5, 7, 8, Reconciliation 26, Audit arm 8); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's run at every process restart and its lower edge, the owed post closure placement and the owed renewal a placement lost between its call and its record left, and the alert on a closed case carrying no post closure placement (Reconciliation 1, 4, 12, 13, 21); the arms for a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing (Audit arm 5, 6, 18); the invocation's own retry of an owed record, its yield and its hand-off (Audit arm 14 through 17); the in-invocation re-query of an indeterminate committing call, the escalation of an indeterminate enroll and the bar on retrying a committing call outside its invocation (Atomic writes 3 through 9, Action wiring 133); the outcome position a storage failure after a committed sibling call answered (Action wiring 18, 101, 126); the scoped retry inside [Clear Review] and a lost clearance's recovery (Action wiring 108 through 110); and the completing closure, whose earlier closure with no record is now only one whose record Audit Trail refused, which the reconciliation records (Action wiring 117, 118, Reconciliation 8). Rules 511 to 478. *Over:* intent, constituent writes and outcome committed one by one, ordered so that a crash between them left a state the composition could name — a committed act with no record, a closed party with no floor, a constituent call whose answer was lost — with a host that serialized each party's actions, an invocation that retried its own record up to the onboarding completion bound, and a reconciliation that waited out that bound, re-queried what the intent fixed, placed what a crash left owed and recorded or closed the rest. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. Party Identity, Retention Window and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an action's intent, constituent writes and outcome commit together. The census's question is decided by the ruling's second clause: the intents stay, since an intent is where the caller's credential is validated before any constituent write (Audit arm 1, Invariant 8.1, Check 8.1) and the intent of an attempt a constituent refuses is the evidence the page keeps for the reconciliation to close (Audit arm 7, Reconciliation 7). An Audit Trail refusal at an outcome record still leaves the act committed and its record owed (Audit arm 9, 10, 12), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the per-action answers that report it, the reconciliation's selection of open markers, its re-query on the values the intent fixed, its traversal, recovery intent and recovery outcome under the service identity, its compensation window and the closure floor that window must exceed, the alerts, the escalations and the checks that read an owed or recovered record (Action wiring 34, 65, 74, 78, 92, 93, 103, 128, Audit arm 13, 19, 22 through 25, Composes 16, 17, Reconciliation 3, 5 through 11, 14 through 20, 24, 27 through 31, Capability requirement 24, 26 through 29, 42, Invariant 2.4, 7.3, Atomic writes 10 through 12, Check 2.3, 7.6, 8.3 through 8.6); the onboarding completion bound stays with them, since the closure floor still reads it (Capability requirement 23, 27), and so does Action wiring 51, the trigger path's Audit arm 1, which an Audit Trail refusal of the trigger record still reaches. The four indexes stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, so their rebuild on a miss, their population after the landed record, a clearance's drop of exactly the triggers its record names, and [Close Party]'s not-active for a case whose closure an index has not yet recorded stay (Composition state 7, 9 through 14, 21, 35, Atomic writes 2, Action wiring 64, 75, 104 through 106, 119, 129 through 131, Check 6.3). A renewal Retention Window refuses keeps its answer and its advance, capped below the current placement's cover, so the next review renews the chain (Action wiring 71, 72, 76, Clock semantics 4); the owed renewal was the lost one's. The rebuilds and reproductions read the Event Log's insertion order (Invariant 3.3) and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 45, Execution Contract Read 1 through 3) and the four rules that restated it for a constituent read the host's I/O never completed deleted to it (Action wiring 41, Action wiring 139, Action wiring 141, Action wiring 154), Term unanswered read with them, and state-unavailable off the signatures of [Initiate Onboarding] and [Trigger Monitoring Review]; rules 478 to 474. *Over:* the page stating for itself what an action answers when a read it makes never answers. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once, and the mapping this page chose on 2026-09-14, an unanswered read answered state-unavailable from the seam, is what Read 1 now says for every specification. [Activity Permitted] keeps state-unavailable on its signature for a case of its own (Action wiring 140): a case entry whose party the database no longer answers for, an answered read the gate fails closed on, which no rule of the contract decides.

- **2026-11-10 — The model regenerated and the vocabulary switched with the composition of Recoverable Invocation.** *Chose:* `customer-onboarding.tla` re-derived over the split arc (one party, two adverse triggers, three invocations, the suspension, clearance and closure transactions with their re-reads, Recoverable Invocation's sweep and an operator as contracts, one outside write and the reconciliation), its counter retired and its one twin re-pointed, nine twins and seven reachability probes added; and the fifteen `customer-onboarding.*` event classes the page wrote before it bound its act kinds named as pre-switch records the rebuild reads as their counterparts (Composition state 52, Term pre-switch record, Term counterpart). *Over:* keeping the counter beside the new arc, which would have checked a coupling no action of the page performs any longer; and dropping the old classes from every rule, which would have left a case older than the switch unrebuildable inside its binding floor. *Because:* the turn itself is the 2026-11-10 entry of the page's Decisions; this records what it regenerated. The first run of the re-derived model found the clearance's in-flight race, cured on the page in the same unit (Action wiring 164, 165).

- **2026-11-10 — The waits retired: the five acting actions bind seven Recoverable Invocation act kinds.** *Chose:* (Scott, 2026-11-09 9:17 PM Central, "A", and 2026-11-10 7:15 AM Central, the wait ruling, "simple DRY"; the map rounds/co-ri-map-2026-11-10.md, its directions settled under A, 2026-11-10 7:55 AM Central) the five acting actions bind seven act kinds split by the call each waits on — customer-onboarding.enrollment keyed by the enrollment key under the minted-key deviation, customer-onboarding.admission, customer-onboarding.verification, customer-onboarding.adverse-trigger, customer-onboarding.periodic-review, customer-onboarding.clearance and customer-onboarding.closure keyed by the party id, since no constituent record carries the case id, every kind repeatable (A: act kinds split by the wait, G1, G2); what only the trail knows — the case id, the trigger id, the clearance's closed triggers, the closure's open triggers at close, the periodic review's prior placement and every next review due — rides the intent, the outcome carrying only what Party Identity and Retention Window re-derive, and the rebuilds read each closing beside its intent in intent order (G3, G9); the invocation's now injected into Party Identity's and Retention Window's seams as every kind's pairing datum, so the commitment window, the clock offset allowance and Reconciliation 29's bar go and a lost direct-path initiation is recovered through Party Identity's enrollment instant range (G4); the clearance one act, verify and reinstate in one transaction with one outcome, so review-cleared and party-reinstated fold into customer-onboarding.clearance.cleared, the half-clearance and its window, orphan and checks go, and a refused reinstate rolls the verify back (A: kinds split by the wait, G5); every suspend refusal pre-commit, already-suspended among them, closed through the refuse, the trigger records folded into the kind's refused record read by its code, and the caller answered already-suspended (A: codes change to Recoverable Invocation's, G6); an intent whose invocation died before its commit escalated for an operator (A, G7); five collisions the split exposes refused inside the commit by a re-read — already-onboarded and party-not-admissible at the admission, not-verified at the suspension, not-active at the renewal, triggers-changed at the clearance and the closure (A: a collision becomes a refusal, G8; Action wiring 159 through 169) — and the clearance's re-read refusing too while an adverse trigger intent of the case carries no closing, which the re-derived model found: without it a trigger whose intent the clearance named and whose suspend committed after it re-suspends a reinstated party with no open trigger left (Action wiring 165); quiescence restated as no open intent and no standing escalation, an escalated trigger kept open, and an operator's closing detected, not prevented, by Reconciliation 23, 25, 39 and the new 43 (A: detected, not prevented, with an alert, G10); a verification event, state change event or placement no intent carries a write-ownership finding, Composes 20's second writer given a detector (A: a record with no intent becomes a finding, G11); every acting action's caller-visible codes Recoverable Invocation's, storage-failure and registry-unavailable answered as the constituent's, [Initiate Onboarding]'s recording-failure(outcome) carrying the case id (A, G7, G12); the mayor's derivable calls taken as the map recommends: one completion bound re-anchored to Recoverable Invocation's span (G13); `application_actor_ref` renamed the recovery identity (G14); the Bank Secrecy Act alert kept as the page's own, on an open verification intent the sweep examines (G15); the multi-call commit, the in-transaction trail read and the pre-switch cut-over carried as open lines (G16, G8, G21); a new act section host (G17); the model re-derived over the split arc (G18). Capability requirement 24 through 27, 46, 47, Identity 10, 11, 13 through 17, every live Audit arm rule but 19, Action wiring 34, 50, 51, 62, 65, 74, 78, 91 through 94, 102, 103, 119a, 128, 148 through 152, Reconciliation 3, 6 through 11, 14 through 20, 24, 27 through 33, Invariant 2.4, 7.3, 8.1, Check 2.3, 4.4, 7.6, 8.1 through 8.6 and Atomic writes 1 tombstoned to what owns them; Composes 27 through 31, Composition state 51, 52, Capability requirement 48 through 55, Action wiring 155 through 172, Reconciliation 34 through 43, Check 9.6, 10.1, External check 12, 13, Non-goal 22 through 24 and Cross-record consistency 1 new; the closure table drafted. Rules 482 to 449 (84 tombstoned, 91 restated, 51 new). Open lines 2026-11-06-a and 2026-08-29-s dissolve with the rules and the model they named; 2026-11-04-a is carried, sharpened, and 2026-11-04-b carried; 2026-11-10-a through 2026-11-10-e are opened. *Over:* removing the wait by reversing 2026-10-20 at its other end, so that an Audit Trail refusal of any outcome fails the whole action, which every write here being a database write allows, but which would make Audit Trail's health a precondition of every suspension — a deterministic outcome refusal would leave a sanctions-matched party verified and passing the gate; one per-party act kind for every action, which would make a crashed act block the party's every action, a sanctions trigger included, until the sweep closed it; and keeping the page's own reconciliation beside Recoverable Invocation, which would have covered the intent-and-outcome pairing twice. *Because:* the waits were self-made: the 2026-10-20 decision kept an act committed when its outcome record was refused, and the page then built the open markers, the commitment window, the recovery intent and outcome, the compensation window, its cadence, run bound, closure floor and escalation reach to close them, which Recoverable Invocation owns; four of the seven foundational findings of Final Critique 3 through 5 sat in that machinery or in the audit-arm positions Recoverable Invocation's open, close and refuse own, and the one refuted report of Final Critique 5 too. It turns the 2026-08-29 entry (the bounded scan and its intent-keyed pre-check are Recoverable Invocation's) and the 2026-10-20 entry's "so what closes it stays", rule by rule. *Costs:* seven bindings, the instance's bounds and sweep, and a Lease host the page did not have, the database having serialized a party's actions; every acting action's caller-visible codes, already-suspended among them where a second adverse alert was answered recorded; the auditor-visible vocabulary, with the clearance one record and the trigger-on-suspended-party and trigger-voided records folded into a refused record; five re-reads inside the commits, and a clearance refused while an adverse trigger is in flight; operator work for an intent whose invocation died before its commit, which Database 1 had rolled back unseen; a rebuild that reads two vocabularies for a case older than the switch; Invariant 2.1, 4.2, 7.1, 7.2 and 7.5 fall from prevented to detected against an operator's resolve.

- **2026-11-11 — A refused renewal leaves the next review due where it stood.** *Chose:* the periodic review's next review due takes effect once its renewal outcome stands (Action wiring 76, Action wiring 76a, Term schedule-bearing record), as a verification's and a clearance's do. *Over:* advancing it whatever the renewal answered, the earlier wording. *Because:* the intent is written before the renewal and cannot know the cover the renewal will leave, so on a refused renewal, which moves no cover, the derived due could stand past the placement's cover, which Clock semantics 4 forbids; the cost is the scheduler firing the review again at its next pass (open line 2026-11-11-f).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Customer Onboarding](./customer-onboarding.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 46. Composition state 47 owns it: the entry of a closed case stands, since the composition never drops one.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 6. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 24. Recoverable Invocation Instance start 4 owns it: the closure window.
Deleted: Capability requirement 25. Recoverable Invocation sweep cadence 2 and Recoverable Invocation sweep cadence 3 own it.
Deleted: Capability requirement 26. Recoverable Invocation run bound owns it: the sweep's own, and the reconciliation runs inside it.
Deleted: Capability requirement 27. Recoverable Invocation Instance start 4 owns it: the worst closure against the closure window, the sweep's run counted in it.
Deleted: Capability requirement 32. Primitive policy 20 went with its cap: the trigger sets ride the intents in full, bounded by Audit Trail's payload cap (Capability requirement 31).
Deleted: Capability requirement 44. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 46. Recoverable Invocation Instance start 5 owns it: the retention floor.
Deleted: Capability requirement 47. Recoverable Invocation clock allowance owns it: the pairing datum is injected into every constituent's seam (Capability requirement 48), so no recovery comparison reads two clocks.
```

### Composition logic › Primitive policy

```
Deleted: Primitive policy 20. Recoverable Invocation Primitive policy 12 and Primitive policy 13 own it: an intent whose data exceeds Audit Trail's payload cap, the trigger sets in full included, refuses invalid-request at the open.
```

### Composition logic › Identity

```
Deleted: Identity 10. Recoverable Invocation Primitive policy 9 owns it.
Deleted: Identity 11. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Identity 13. Recoverable Invocation Primitive policy 11a owns it.
Deleted: Identity 14. Recoverable Invocation Primitive policy 5 and Recoverable Invocation Invariant 3.2 own it: a journal join pairs on the invocation id.
Deleted: Identity 15. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Identity 16. Recoverable Invocation Primitive policy 5 owns it: a journal join pairs on the invocation id and no other field.
Deleted: Identity 17. Recoverable Invocation journal 2 owns it: a trigger's intent is the adverse trigger kind's or the periodic review kind's own intended record.
```

### Composition logic › Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Action wiring 4 and Recoverable Invocation Invariant 1.1 own it for the intent of the seven act kinds.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 41 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 23 owns it.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Recoverable Invocation Invariant 4.1 owns it: an intent stands open until a closing names its invocation, and the sweep closes it.
Deleted: Audit arm 8. Execution Contract Database 2 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 42 owns it.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 29 through 31 own it: an outcome that does not land answers recording-failure(outcome).
Deleted: Audit arm 11. Recoverable Invocation Invariant 8.3 owns it: recording-failure(intent) is a committed nothing, and the caller may retry.
Deleted: Audit arm 12. Recoverable Invocation Invariant 8.4 owns it: recording-failure(outcome) is an act that may exist, whose record the sweep closes.
Deleted: Audit arm 13. Recoverable Invocation Invariant 8.4 owns it: the caller does not re-run an act whose invocation is unclosed.
Deleted: Audit arm 14. Execution Contract Database 1 owns it.
Deleted: Audit arm 15. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 16. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Audit arm 17. Execution Contract Database 1 owns it: an action's writes commit together, so no invocation retries an owed record.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Deleted: Audit arm 20. Recoverable Invocation Primitive policy 41 through 43 own it: an invalid-request at the intent is the caller's, at the outcome a hard alert.
Deleted: Audit arm 21. Recoverable Invocation Primitive policy 40 and Recoverable Invocation Primitive policy 42 own it: the hard alert.
Deleted: Audit arm 22. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome carries the recovery flag.
Deleted: Audit arm 23. Recoverable Invocation Invariant 5.2 owns it: a recovered outcome names the caller in the acting actor reference.
Deleted: Audit arm 24. Recoverable Invocation Primitive policy 20 through 22 and Recoverable Invocation Primitive policy 41 own it: an intent's invalid-request(step-4) is read back by invocation id, a found record proceeding with a hard alert and none answering invalid-request.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 43 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 154. Execution Contract Read 1 owns it.
Deleted: Action wiring 18. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it: a close that does not land answers recording-failure(outcome).
Deleted: Action wiring 41. Execution Contract Read 1 owns it.
Deleted: Action wiring 50. Recoverable Invocation Primitive policy 23 owns it: a trigger intent that does not land answers recording-failure(intent).
Deleted: Action wiring 51. Recoverable Invocation Invariant 1.1 and Recoverable Invocation Action wiring 4 own it: no commit is issued ahead of a landed intent.
Deleted: Action wiring 62. Recoverable Invocation's refuse owns it: a refusal record that does not land answers recording-failure(refusal, constituent_code), and the sweep records the attempt.
Deleted: Action wiring 65. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 74. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 78. Term renewal probe owns it: a renewal is recovered on the act key and the pairing datum.
Deleted: Action wiring 91. Action wiring 83 owns it: the next review due rides the clearance intent, and the clearance outcome carries none.
Deleted: Action wiring 92. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 93. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Deleted: Action wiring 94. Term clearance transaction owns it: the verify and the reinstate commit together, and no record stands between them (Recoverable Invocation Action wiring 6).
Deleted: Action wiring 101. Execution Contract Database 1 owns it.
Deleted: Action wiring 102. Action wiring 90 owns it: the clearance's one outcome carries the reinstate's state change id.
Deleted: Action wiring 103. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 108. Execution Contract Database 1 owns it.
Deleted: Action wiring 109. Execution Contract Database 1 owns it.
Deleted: Action wiring 110. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Action wiring 117. Recoverable Invocation reconcile step 3.2 and Execution Contract Database 1 own it.
Deleted: Action wiring 118. Execution Contract Database 1 owns it: a closure's close, floor and record commit together, so no invocation completes an earlier closure.
Deleted: Action wiring 119a. Recoverable Invocation open step 3.5 owns it: an earlier closure whose outcome has not landed is an open closure intent, so a second closure meets act-in-flight while the first is in flight, and the second's close answers already-closed once the first committed (Action wiring 119).
Deleted: Action wiring 126. Execution Contract Database 1 owns it.
Deleted: Action wiring 128. Recoverable Invocation Primitive policy 29 through 31 and Action wiring 157 own it.
Deleted: Action wiring 133. Execution Contract Database 1 owns it.
Deleted: Action wiring 139. Execution Contract Read 1 owns it.
Deleted: Action wiring 141. Execution Contract Read 1 and Execution Contract Read 2 own it.
Deleted: Action wiring 148. Action wiring 146 owns it.
Deleted: Action wiring 149. Action wiring 146 owns it.
Deleted: Action wiring 150. Action wiring 146 owns it.
Deleted: Action wiring 151. Action wiring 146 and Action wiring 90 own it: the clearance's one outcome carries the clearance instant, the reinstate's state change instant.
Deleted: Action wiring 152. Action wiring 146 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Reconciliation 3. Recoverable Invocation reconcile step 1.1 owns it: the sweep selects every open intent of the act kinds.
Deleted: Reconciliation 4. Execution Contract Database 1 owns it.
Deleted: Reconciliation 6. Recoverable Invocation reconcile step 3.1 and the act probes own it: the sweep runs the kind's act probe against Party Identity's and Retention Window's declared reads (Recoverable Invocation Sweep never 3).
Deleted: Reconciliation 7. Recoverable Invocation reconcile step 3.5 owns it: an intent whose invocation died before its commit is escalated, and an operator who finds the constituents quiet abandons it through the invocation resolve (Recoverable Invocation Invariant 4.9).
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 3.2 owns it: a committed probe answer is closed by the recovered outcome.
Deleted: Reconciliation 9. Recoverable Invocation Invariant 5.1 and Recoverable Invocation reconcile step 3.2a own it: the recovery intent before any recovered outcome.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 2.4 through 2.6 own it: the sweep re-reads the invocation's closings under the critical section before it writes.
Deleted: Reconciliation 11. Recoverable Invocation reconcile step 3.2a, Recoverable Invocation reconcile step 3.2b, Recoverable Invocation Invariant 5.2 and Recoverable Invocation service identity 3 own it: the sweep writes under the recovery identity.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it: neither the sweep nor the reconciliation calls a constituent's write.
Deleted: Reconciliation 15. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 16. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 17. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 18. Reconciliation 42 and Recoverable Invocation Sweep never 1 own it.
Deleted: Reconciliation 19. Recoverable Invocation Invariant 4.2 and Recoverable Invocation Instance start 4 own it: an open intent is closed within the closure window.
Deleted: Reconciliation 20. Recoverable Invocation reconcile step 3.5, Recoverable Invocation reconcile step 3.8 and Recoverable Invocation reconcile step 5.1 own it: an intent the sweep cannot close is escalated once and reported at risk.
Deleted: Reconciliation 21. Execution Contract Database 1 owns it.
Deleted: Reconciliation 24. Recoverable Invocation Invariant 4.1, Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.21 own it: a trigger intent carrying no closing stands open until the sweep closes or escalates it.
Deleted: Reconciliation 26. Execution Contract Database 2 owns it.
Deleted: Reconciliation 27. Term verification probe and Recoverable Invocation Invariant 3.3 own it: the probe pairs on the act key and the pairing datum by equality.
Deleted: Reconciliation 28. Term admission probe, Term renewal probe and Recoverable Invocation Invariant 3.3 own it.
Deleted: Reconciliation 29. Term enrollment probe and Recoverable Invocation Deviation 4b own it, reversed: the probe finds the minted party through Party Identity's enrollment instant range.
Deleted: Reconciliation 30. Recoverable Invocation reconcile step 3.5 and Recoverable Invocation reconcile step 3.8 own it: what the enrollment probe cannot decide is escalated.
Deleted: Reconciliation 31. Recoverable Invocation Invariant 3.2 and Recoverable Invocation act probe 3a own it.
Deleted: Reconciliation 32. Term reconciliation owns it: the reconciliation runs inside the sweep's run, which answers its tally to its starter alone.
Deleted: Reconciliation 33. Execution Contract Scheduled leg 1 owns it.
```

### Composition-level invariants

```
Deleted: Invariant 2.4. Recoverable Invocation Invariant 4.2 owns it: an open verification intent is closed within the closure window.
Deleted: Invariant 7.3. Term clearance transaction owns it: the verify and the reinstate commit together, so no clearance window stands for a verified party to carry a closed trigger inside.
Deleted: Invariant 8.1. Recoverable Invocation Invariant 1.1 owns it: no commit stands ahead of the intent the caller's credential attested.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Recoverable Invocation Check 3.1 owns it: an intent carrying no outcome is closed or escalated within the closure window.
Deleted: Check 4.4. Invariant 4.3 and Recoverable Invocation Check 1.1 own it: the clearance writes one intent, attested under the clearing actor, and one outcome naming it.
Deleted: Check 7.6. Term clearance transaction owns it: no clearance stands recorded beside a trigger it left open.
Deleted: Check 8.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 8.2. Recoverable Invocation Primitive policy 11 and Identity 9 own it: every record of an invocation carries the act key, and the intent the case id.
Deleted: Check 8.3. Recoverable Invocation Check 1.1 and Recoverable Invocation Invariant 5.2 own it: a recovered outcome is compared against the acting actor reference.
Deleted: Check 8.4. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Check 8.5. Recoverable Invocation Check 3.1 owns it.
Deleted: Check 8.6. Recoverable Invocation Check 6.1 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Recoverable Invocation Action wiring 4 owns it: the close follows the commit.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Action wiring 146 through 152 own it, one outcome at a time.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Action wiring 153 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 6. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 10. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 11. Non-goal 21 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Invariant 1.1 owns it: a skewed gate read answers permitted only where Party Identity's read reports the party verified, so the skew fails safe.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 7. Execution Contract Database 2 owns it.
Deleted: Concurrency 8. Execution Contract Database 2 owns it.
```

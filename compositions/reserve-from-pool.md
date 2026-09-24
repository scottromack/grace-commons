---
title: Reserve from Pool
parent: Conceptual Compositions
nav_order: 18
has_toc: true
toc: true
---

# Reserve from Pool

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Reserve from Pool is a composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: managing the full life of a reservation against a finite pool so that the pool's free count is always exactly right.

A request takes a provisional hold on one unit of a bounded pool; the hold is confirmed into a firm booking, cancelled, or allowed to time out; and at every instant the pool's `allocated` total equals the number of reservations still live against it.

It wires five constituents: Provisional Commitment (the per-reservation Held → Confirmed | Released | Expired state machine with its confirm-within-window guarantee), Capacity Constraint Enforcement (the bounded pool whose running total never exceeds its declared capacity), Duplicate Prevention (the retry guard that makes every reservation action safely repeatable), Event Log (the durable journal of every state change), and Actor Identity (the attestation — a record, checkable later, that the acting party presented a valid credential for this very act — that binds every act to a verifiable actor).

The composition's defining emergent guarantee (a property that appears only when atoms are combined — no single atom carries it) is **allocation coherence**: the pool's `allocated` count stays in exact lockstep with the set of reservations in a slot-holding state (Held or Confirmed). Three consequences follow. Confirmed reservations never exceed pool capacity — every [Reserve] gates on `Capacity Constraint.allocate`, which refuses past `capacity`. A cancelled or expired reservation returns its slot to the pool *exactly once* — the terminal transition, the pool `release` and the journal entry are ordered and reconciled against the pool's own count, so no slot is leaked (a cancellation whose unit is never returned) and none is double-released (a unit returned twice, driving the count below the truth). And no reservation is confirmed unless its hold is still live at confirmation time — Provisional Commitment's confirm-within-window guarantee, surfaced at the composition layer, prevents confirming a slot that has already lapsed and been returned.

Beyond coherence, the composition makes every reservation action idempotent under retry (safe to repeat — a retried call returns the first call's outcome instead of acting twice) (the Idempotent Reservation precursor's contract, extended over the pool-aware surface), and records every state change as a durable, attributed Event Log entry. Its most common uses are airline and hospitality booking, event ticketing, hospital bed and resource allocation, and warehouse and supply-chain inventory reservation. Any system that must guarantee, from the pool count alone, that it never oversells and never strands inventory across the reserve/confirm/cancel/expire arc is a candidate for this composition.

---

## Intent

Every system that reserves a unit of a finite resource faces the same arc, and it is the same whether the resource is an airline seat, a hotel room, a hospital bed, an event ticket, or a unit of warehouse inventory: a request encumbers one unit of a bounded pool provisionally; the encumbrance resolves into a firm booking, a cancellation, or a timed-out lapse; and the pool's free count must reflect, at every instant, exactly how many units are spoken for. Get the binding between the per-reservation lifecycle and the pool arithmetic wrong and the system either oversells (two reservations confirmed against one slot) or strands inventory (a cancelled reservation whose slot is never returned). The arc is constant; the failure modes are constant; and they live precisely at the seam between *the reservation* and *the pool*.

Neither Provisional Commitment nor Capacity Constraint Enforcement, alone, closes that seam. Provisional Commitment owns the per-reservation state machine — Held → Confirmed | Released | Expired, with the confirm-within-window guarantee (Invariant 7) that a hold cannot be confirmed after its window has elapsed — but it holds *one* resource per commitment and, by its own specification, *"does not opine on pool-level rules"*; it has no notion of a bounded pool or a running total. Capacity Constraint Enforcement owns the pool arithmetic — `allocated ≤ capacity` (Invariant 4) enforced by precondition on `allocate`, and `allocated ≥ 0` (Invariant 5) enforced on `release` — but units are *fungible* at its grain: it tracks a running count, not per-allocation identities, and by its own specification *"the composing pattern supplies the per-allocation identity; this atom owns only the pool's arithmetic."* Capacity Constraint even admits `release` against a Closed pool *expressly so that a composing pattern like Provisional Commitment can return slots when its holds reach terminal states* — naming the seam, and naming this composition as the thing that lives there, without filling it. The binding that keeps `allocated` in lockstep with the live-reservation set — allocate-on-hold, hold-the-slot-through-confirm, release-on-terminal — belongs to no single constituent. It belongs to the composition, and this composition is that binding.

This is a composition, not a new primitive. The five constituents are unchanged; the composition is the wiring that makes them coherent as a single reservation surface. It introduces emergent actions — [Reserve], [Confirm Reservation], [Cancel Reservation], [Expire Reservation] — that bind a Provisional Commitment to a Capacity Constraint pool slot, deduplicate retries through Duplicate Prevention, attribute every act through Actor Identity, and journal every state change through Event Log. The [Reserve] action, in particular, wraps a capacity gate (`Capacity Constraint.allocate`), a provisional hold (`Provisional Commitment.place_hold`), a duplicate check, and a journaled, attributed event into one named surface, so that taking a slot is one ordered, recorded act whose pool effect is bound to the reservation — not a `place_hold` whose pool consequences leak into whatever code remembers to decrement the counter.

What the composition is *not*: it is not the resource-availability oracle (whether a *specific* seat or room is bookable belongs to Provisional Commitment's registry, upstream of the pool count); it is not the overbooking-policy engine (a deployment that deliberately oversells by N sets the pool's `capacity` above the physical count — that is a capacity the deployment declares, not a composition behavior); it is not the pricing, waitlist, or fulfillment surface; and it is not the audit-substrate composition (it journals to Event Log and attributes via Actor Identity directly, the lighter pairing, rather than composing the full tamper-evident Audit Trail — a deployment needing seals composes Audit Trail as a peer). Each is named in Non-goals.

---

## Composes

- **[Provisional Commitment](../atoms/provisional-commitment.md)** — the per-reservation hold lifecycle: Held, then Confirmed, Released or Expired, with the confirm-within-window guarantee and terminal absorption.
- **[Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md)** — the bounded pool whose running total never exceeds its declared capacity and never falls below zero.
- **[Duplicate Prevention](../atoms/duplicate-prevention.md)** — the time-bounded guard that makes every reservation action safe to repeat.
- **[Event Log](../atoms/event-log.md)** — the durable, append-only, totally ordered journal of every reservation act.
- **[Actor Identity](../atoms/actor-identity.md)** — the attestation that binds every act to a verifiable actor, and the composition's only credential check.

```
Composes 1: EXACTLY ONE Provisional Commitment instance MUST serve the composition.
Composes 2: EXACTLY ONE Capacity Constraint Enforcement instance MUST serve the composition.
Composes 3: EXACTLY ONE Duplicate Prevention instance MUST serve the composition.
Composes 4: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 7: The composition MUST NOT change a constituent's spec.
Composes 8: The composition MUST make EVERY transition of the Provisional Commitment instance.
Composes 9: The composition MUST make EVERY allocate AND EVERY release against a pool the composition binds.
Composes 10: The composition MUST key a reservation by the reservation's commitment id.
Composes 11: The composition MUST configure the Duplicate Prevention instance with the idempotency window.
Composes 12: The composition MUST NOT verify a credential outside Actor Identity's attest.
Composes 13: The composition MUST read a pool's audit events through the pool event read.
Composes 14: The composition MUST NOT read a pool's audit events through Capacity Constraint Enforcement's query.
```

Term composition: this pattern's wiring of [Provisional Commitment](../atoms/provisional-commitment.md), [Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md), [Duplicate Prevention](../atoms/duplicate-prevention.md), [Event Log](../atoms/event-log.md) and [Actor Identity](../atoms/actor-identity.md) — the five actions, the reservation-to-pool binding, the token results map and the reconciliation.

Term constituents: [Provisional Commitment](../atoms/provisional-commitment.md), [Capacity Constraint Enforcement](../atoms/capacity-constraint-enforcement.md), [Duplicate Prevention](../atoms/duplicate-prevention.md), [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md).

Term reservation: a Provisional Commitment the composition holds against one pool slot.

Term reservation id: the commitment id Provisional Commitment's place hold answers for a reservation.

Term journal: the Event Log instance's events, in sequence order, as the composition and an auditor read them.

Term journal entry: one event the composition appends to the journal.

WHY:
**Provisional Commitment** owns the per-reservation state machine and its confirm-within-window guarantee, and by its own specification does not opine on pool-level rules: it holds one resource per commitment and has no notion of a bounded pool or a running total. A reservation *is* a Provisional Commitment (Composes 10), and the composition is the sole writer of its transitions (Composes 8): place hold from [Reserve], confirm from [Confirm Reservation], release from [Cancel Reservation] and expire from [Expire Reservation].

**Capacity Constraint Enforcement** owns the pool arithmetic — allocated never above capacity, never below zero — and units are *fungible* at its grain: it keeps a running count, not per-allocation identities, and says the composing pattern supplies the per-allocation identity. It admits release in every pool state, Closed included, expressly so a composing pattern can return slots as its holds reach terminal states; that admission is what makes slot return correct for a pool closed to new reservations while live holds unwind. The composition holds one pool per reservable resource class inside the one instance and is the sole caller of allocate and release against the pools it binds (Composes 9). **The pool's audit log is not reached through query** (Composes 13 and 14): the atom routes its audit log to direct inspection of the persisted record, so the read is declared as an instance capability the deployment supplies (Capability requirement 17 through 19). And the atom's serialization is **per call** — a exclusion spanning several calls is nothing the pool grants, so every multi-call exclusion on this page is the deployment's (Capability requirement 20 through 26).

**Duplicate Prevention** is the retry guard, configured with the idempotency window (Composes 11). Its declared failure modes are inherited as the deployment's obligations — a durable, available recorded set, a fail-closed check, and the cached answer and the record durable before the answer returns (Capability requirement 34 through 36) — which is the Idempotent Reservation precursor's mechanism carried onto the pool-aware surface and declared here in full rather than borrowed from that peer.

**Event Log** is the journal. Every state-changing action appends two entries — an intent entry before any constituent call that commits, and an outcome entry after — and the pairing is one-to-one only on the paths that commit: an invocation a constituent guard refuses leaves an intent unmatched, which records an authenticated attempt rather than a defect. Event Log's insertion order is the authoritative order of reservation events. Its durability across a crash is the deployment's, not the atom's — the atom specifies in-memory semantics and leaves persistence to the deployment — so every claim here that reads the journal after a crash rests on Capability requirement 12 through 14. Its payload-predicate query is likewise implementation policy, declared against Capability requirement 15.

**Actor Identity** is the composition's only credential check (Composes 12). Every state-changing action calls attest before any constituent call that commits, so an unverifiable credential refuses the act with nothing written; the answered attestation id rides every journal entry the act writes, so an auditor verifies the attribution from the records rather than trusting a narrated one. Two obligations ride with it — the actor registry's historical public material, and the attestation store's durability — both the deployment's by the atom's own declaration (Capability requirement 37 and 38).

The composition journals to Event Log and attests through Actor Identity directly — the lighter pairing — rather than composing the full [Audit Trail](./audit-trail.md) substrate; a deployment needing tamper-evident seals composes Audit Trail as a peer (Non-goal 4 and 5).

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the reservation-to-pool binding.
Composition state 2: The composition MUST key the reservation-to-pool binding by reservation id.
Composition state 3: A binding entry MUST carry the pool id AND the release marker.
Composition state 4: The composition MUST write a binding entry ONLY AFTER the reservation's reserve outcome entry lands.
Composition state 5: The composition MUST NOT write a binding entry for a compensated hold.
Composition state 6: The composition MUST NOT remove a binding entry.
Composition state 7: The composition MUST NOT change a binding entry's pool id.
Composition state 8: A pending release marker MUST carry the invocation's idempotency token AND attestation id.
Composition state 9: A released release marker MUST carry a release reading.
Composition state 10: The composition MUST rebuild a missing binding entry from the journal.
Composition state 11: The rebuild MUST take a binding entry's pool id from the reservation's reserve outcome entry.
Composition state 12: IF a slot-returning outcome entry names the reservation THEN the rebuild MUST set the release marker to released carrying the entry's release reading.
Composition state 13: IF no slot-returning outcome entry names the reservation AND a matching intent names the reservation THEN the rebuild MUST set the release marker to pending.
Composition state 14: IF no slot-returning outcome entry AND no matching intent names the reservation THEN the rebuild MUST set the release marker to none.
Composition state 15: The rebuild MUST leave standing a binding entry whose reserve outcome entry is an aged entry.
Composition state 16: The composition MUST store the token results map.
Composition state 17: The composition MUST key the token results map by idempotency token.
Composition state 18: A token results entry MUST carry an action type, a parameters digest AND a result.
Composition state 19: The composition MUST take the parameters digest from the seam.
Composition state 20: The parameters digest MUST NOT take the actor reference.
Composition state 21: The parameters digest MUST NOT take the credential.
Composition state 22: The composition MUST NOT evict a token results entry BEFORE Duplicate Prevention's check answers not-seen for the entry's token.
```

Term reservation-to-pool binding: the composition's map from a reservation id to the pool whose slot the reservation holds, and the slot's return — the binding the composition exists to keep.

Term binding entry: one reservation's entry in the reservation-to-pool binding.

Term release marker: none | pending | released — a binding entry's record of the slot's return: none owed, owed and in flight, or done; the released value is a [Slot Released].

Term release reading: the release event id | unknown — unknown where a return landed and no marker named the pool's release event.

Term compensated hold: a hold [Reserve] placed whose reserve outcome entry did not land, driven terminal and the hold's slot returned behind a compensation entry.

Term matching intent: a cancel intent naming a Released reservation, or an expire intent naming an Expired reservation — an intent whose action wrote the reservation's current state.

Term aged entry: a journal entry whose `recording instant + audit horizon` PRECEDES now — past which the entry's payload may be lawfully destroyed.

Term token results map: the composition's own map from an idempotency token to the answer recorded against the token.

Term action type: reserve | confirm_reservation | cancel_reservation | expire_reservation.

Term parameters digest: the collision-resistant digest of a call's business parameters, computed at the seam by the digest function and injected — a [Parameters Digest].

Term business parameter: the pool id, the resource, the requester and the duration at [Reserve]; the reservation id at a resolving action — the inputs that decide an answer.

WHY:
**The reservation-to-pool binding is the composition's reason to exist.** It is what makes a reservation's slot a recorded fact rather than an implicit consequence, and it is read by [Cancel Reservation] and [Expire Reservation] to know which pool to release against. *Relation:* reservation to pool, many to one, one entry per **completed** reservation — one whose reserve outcome entry landed — mandatory and never removed (Composition state 4 and 6), kept after the reservation resolves as the audit join from the reservation to its pool. **The Provisional Commitment store may hold commitments the binding never names, by design** (Composition state 5): a compensated hold holds no slot, and the binding is the record of slots held. A Released or Expired commitment with no binding entry is that compensation's signature (Check 3.6), never a lost entry.

**The release marker** is the composition's own record of a return that is owed, in flight or done: pending is written before the pool is touched, released after the pool answers (Action wiring 99 and Action wiring 109). No transaction spans the transition, the pool release and the journal entry — none of the three stores offers one — so the at-most-once return (Invariant 2) is carried by the marker together with the reconciliation, not by an atomic commit. A release reading of unknown is admitted because one crash leaves it: the release landed, the crash came before the marker, and the pool's fungible count cannot say which release event was this reservation's (Reconciliation 27).

**Contract classification: derived index, split three ways** (the section titled Composition state in `execution-contract.md`). Every fact the binding carries is journaled, so an entry is rebuilt on a miss (Composition state 10 through 14): the pool id from the reserve outcome entry, the marker from the slot-returning outcome entry where one names the reservation, and pending only where none does and a matching intent does — **outcome over intent, and per reservation, never per intent**. An intent naming a reservation another token already returned, or whose terminal state belongs to the other action, was refused at the action's transition and rebuilds nothing. Two halves are **truth-bearing**, held under the deployment's durability obligation (Capability requirement 30): a pending marker, which is the one record that a return was begun and not yet journaled and exists in no constituent — **extraction-pending** against a durable **Outbox** *(forthcoming)*; and an entry whose reserve outcome entry has aged past the audit horizon, since no constituent holds the pool id — Provisional Commitment records the reservation, not the pool — so there is no second source once the payload is purged, and those entries are **extraction-pending** against the **Erasure Tombstone** *(forthcoming)* the audit substrate names for the same class of fact (Composition state 15). A rebuild from the live journal repopulates the live half and leaves the purged half standing. Two claims spend this bound: Check 1.1's traversal, and the reconciliation's read, each of which reads a shorter journal past the horizon; Capability requirement 29 is what keeps both sound.

**The token results map carries truth no replay reproduces.** Duplicate Prevention answers *have I seen this identity* — membership, no payload — so *which answer was returned for this token* is reconstructible from no constituent store. The element is a not-yet-extracted atom under the section titled Composition state in `execution-contract.md`: **Classification: extraction-pending**, the proposed atom an *Idempotency Result Memo* (token to answer, write-once, window-governed eviction), opened as a roadmap proposal. Composition state 22 is the eviction order Idempotent Reservation's Invariant 7 carries, gated through the constituent's own window query rather than a second clock this layer keeps.

**The digest takes the business parameters and nothing else** (Composition state 19 through 21). A retry that must present freshly minted credential material still matches, and secret material never persists in digest form; a digest computed inside a transition would be cryptography improvised where the Logic Confinement Principle forbids it, so it is computed at the seam and injected.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the idempotency window.
Capability requirement 2: A deployment MUST declare a pool's capacity through Capacity Constraint Enforcement's declare pool.
Capability requirement 3: A deployment MUST declare the expiry sweep.
Capability requirement 4: A deployment MUST supply the service identity.
Capability requirement 5: A deployment MUST set the reservation completion bound.
Capability requirement 6: A deployment MUST set the compensation window.
Capability requirement 7: A deployment MUST set the reconciliation cadence.
Capability requirement 8: A deployment MUST disclose the recovery write latency.
Capability requirement 9: The composition MUST start ONLY IF the compensation window EXCEEDS the liveness sum.
Capability requirement 10: A deployment MUST set the outcome retry attempts.
Capability requirement 11: A deployment MUST set the recovery candidates cap.
Capability requirement 12: A deployment MUST hold the Event Log instance durable across a process crash.
Capability requirement 13: The Provisional Commitment store's durability MUST NOT EXCEED the journal's durability.
Capability requirement 14: The Capacity Constraint Enforcement store's durability MUST NOT EXCEED the journal's durability.
Capability requirement 15: The Event Log instance MUST answer a payload predicate on the idempotency token, the reservation id, the pool id AND the action.
Capability requirement 16: The composition MUST test a candidate set's membership in the composition's own code.
Capability requirement 17: A deployment MUST supply the pool event read.
Capability requirement 18: The pool event read MUST answer a pool's allocated AND the pool's audit log in one consistent read.
Capability requirement 19: The pool event read MUST address an audit event by the event id the call answered.
Capability requirement 20: The host MUST supply a token exclusion keyed by idempotency token.
Capability requirement 21: The host MUST supply a reservation exclusion keyed by reservation id.
Capability requirement 22: The host MUST supply a pool exclusion keyed by pool id.
Capability requirement 23: The host MUST release a exclusion on the holder's return.
Capability requirement 24: The host MUST release a exclusion on the holder's death.
Capability requirement 25: IF the host holds a exclusion as a lease THEN the host MUST set the lease length to the reservation completion bound.
Capability requirement 26: The composition MUST read a exclusion's expiry as the holding invocation's terminus.
Capability requirement 27: A deployment MUST set the token max length.
Capability requirement 28: A deployment MUST set the digest function.
Capability requirement 29: The retention floor MUST NOT EXCEED the audit horizon.
Capability requirement 30: The Provisional Commitment store's durability MUST NOT EXCEED the binding's durability.
Capability requirement 31: A deployment MUST set the digest function alike across EVERY instance sharing the token results map.
Capability requirement 32: A deployment MUST hold the token results map durable across a restart.
Capability requirement 33: A deployment MUST acknowledge a token results write ONLY AFTER the write is durable.
Capability requirement 34: A deployment MUST hold Duplicate Prevention's recorded set durable across a restart.
Capability requirement 35: A deployment MUST resolve Duplicate Prevention's check fail-closed.
Capability requirement 36: The composition MUST NOT answer BEFORE the token results entry AND Duplicate Prevention's record are durable.
Capability requirement 37: A deployment MUST retain the actor registry's historical public material.
Capability requirement 38: A deployment MUST hold Actor Identity's attestation store durable across a restart.
Capability requirement 39: The host MUST inject now at the composition's seam once per invocation.
Capability requirement 40: The composition MUST NOT read the clock inside a transition.
Capability requirement 41: The composition MUST stamp EVERY journal entry an invocation writes from the invocation's now.
Capability requirement 42: The composition MUST NOT compare the composition's now with a constituent's stamp.
Capability requirement 43: The composition MUST NOT mint an id inside a transition.
Capability requirement 44: The composition MUST NOT store a clock-derived flag.
Capability requirement 45: The composition MUST NOT derive a hold's deadline.
Capability requirement 46: The composition MUST order reservation events by the journal's sequence numbers.
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token — chosen to cover the slowest legitimate retry of the most critical action.

Term expiry sweep: eager | lazy — the deployment's strategy for calling [Expire Reservation] on a lapsed hold: a scheduled call at the hold's expiry instant, or a call on the hold's next observation.

Term service identity: the composition's own actor reference and credential, supplied by the deployment, that the reconciliation acts under — never the absent operator's.

Term reservation completion bound: the longest a state-changing invocation may take between the invocation's intent entry and outcome entry — the reconciliation's lower edge, and a exclusion's lease length.

Term compensation window: the duration within which an owed compensation or completion lands or is escalated as an unresolved finding.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every process start.

Term recovery write latency: the deployment's disclosed bound on one reconciliation write landing — a pool release and the recovery outcome entry after it.

Term liveness sum: `reservation completion bound + reconciliation cadence + recovery write latency`.

Term outcome retry attempts: the count of times an invocation re-attempts one transient write after the invocation's act committed, before the invocation yields the act to the reconciliation.

Term recovery candidates cap: the most ids a recovery outcome entry or compensation entry may name as candidates.

Term pool event read: the deployment-supplied consistent read of a pool's persisted record — the pool's allocated and audit log, an audit event addressable by the event id a call answered.

Term exclusion: a token exclusion | a reservation exclusion | a pool exclusion — a host-supplied mutual exclusion, the deployment's host_exclusion.

Term token exclusion: the exclusion keyed by idempotency token, held from Duplicate Prevention's check through Duplicate Prevention's record.

Term reservation exclusion: the exclusion keyed by reservation id, held from a resolving action's intent entry through the action's outcome entry, and by every late write and reconciliation completion.

Term pool exclusion: the exclusion keyed by pool id, held by [Reserve] from the intent entry through settling, by a slot-returning action from the pending marker through the outcome entry, and by the reconciliation from the pool event read through the reconciliation's last write for the pool.

Term token max length: the byte cap on an idempotency token, sized against the journal's payload cap.

Term digest function: the hash function and serialization convention computing the parameters digest.

Term audit horizon: the journal's retention horizon — where the journal is the Audit Trail substrate, the substrate's purge horizon.

Term retention floor: `longest reservation lifetime + coherence proof period`.

Term longest reservation lifetime: the longest a reservation stands from [Reserve] to a slot-returning outcome entry.

Term coherence proof period: the period over which allocation coherence must be provable from the journal.

Term seam: the composition's input and output boundary — the one place the host reads the clock and hands the reading to the composition, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**The liveness sum is strict** (Capability requirement 9). An orphan created at *t* is invisible to every reconciliation leg until *t* plus the completion bound, the next run is at most a cadence later, and the compensating release and the recovery entry land a write latency after that; *cadence no longer than the window* is satisfied by a deployment that breaches on every orphan. The three terms are checked at instance start, and a deployment failing the inequality refuses to start rather than starting to breach (the section titled *Liveness is arithmetic* in `pressure-testing.md`).

**The obligations the constituents decline are declared as the deployment's** (the section titled *Capability provenance* in `pressure-testing.md`). Event Log leaves persistence to the deployment, so the journal's survival — ordered at least as durable as the two stores whose commits its entries bracket — is Capability requirement 12 through 14; a journal less durable than the stores would show a committed hold with no intent behind it, which no leg can tell from an unauthenticated act. Event Log admits a payload predicate as implementation policy, so the query shape is Capability requirement 15, and membership in a candidate set is never asked of the instance: the read takes the entries by the declared predicate and filters the set in the composition's own code (Capability requirement 16). Capacity Constraint Enforcement routes its audit log to direct inspection, so the pool event read is Capability requirement 17 through 19: every outcome entry copies the pool event's opening and closing balances through it, and the reconciliation enumerates allocation events through it, or not at all.

**The three exclusions** are declared because Capacity Constraint Enforcement serializes each of its calls and nothing more, and sends a multi-call transaction to a Transaction composition. Per token, a concurrent retry never double-acts before the cache is populated; per reservation, a live invocation and a reconciliation completion never both write one reservation's return; per pool, the reconciliation's arithmetic never runs while an invocation is between the invocation's pool call and outcome entry. **A lease is exactly the completion bound** (Capability requirement 25): at least the bound, so a live invocation inside the bound is never pre-empted, and no more, so a stalled holder blocks the reconciliation for at most the bound, which the liveness sum's first term already counts. **Its expiry is the invocation's terminus** (Capability requirement 26): everything after belongs to the reconciliation. A deployment that supplies no exclusion has no reconciliation.

**The retention floor** (Capability requirement 29) and the binding's durability (Capability requirement 30) keep the two truth-bearing halves of the binding sound: the rebuild reads journal payloads, Check 1.1 is anchored in that traversal, and the reconciliation reads it too.

**Duplicate Prevention's and Actor Identity's declared failure modes are inherited, not assumed.** Duplicate Prevention calls a failed record a silent window miss, under which a retry re-delegates, and leaves the unavailable-store posture to the deployment; fail-closed is the only posture here, because refusing a retryable reservation is recoverable and taking a slot twice is not (Capability requirement 34 through 36; the landing is Action wiring 10). Actor Identity says its registry does not keep historical material and that its store's durability is the implementation's, so both are the deployment's (Capability requirement 37 and 38), and Check 6.1 is answerable only where both are met.

**One now per invocation, for this composition's own stamps** (Capability requirement 39 through 46). The clock enters at the seam and nowhere else, so no signature carries a now. It stamps the journal entries an invocation writes and serves nothing more: the composition adds no clock-bearing guard and derives no deadline. The hold window is Provisional Commitment's — computed once at place hold and stored, its window rejections pure functions of the stored deadline and the now injected at *that* constituent's seam — and a lapse is a *written* transition there, because it has a side effect: it returns the resource and, here, the slot. Each constituent call is its own invocation with its own seam reading, so the journaled stamp and the commitment's stamp are two readings, and under seam-to-seam skew a sweeper can meet window-not-elapsed on a hold this layer would judge lapsed; that is why expiry is delegated whole to the constituent and why order rests on the journal's sequence numbers, never on comparing stamps. The one marker the binding carries is the record of a committed fact, not a clock-derived projection (Capability requirement 44). Ids are minted at the constituents' seams — the reservation id at place hold, the pool id at declare pool, the event ids at allocate, release and append — and the parameters digest at this seam by the digest function (Capability requirement 43).

### Primitive policy

```
Primitive policy 1: IF the idempotency token EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the idempotency token EXCEEDS the token max length THEN the action MUST answer invalid-request.
Primitive policy 3: The composition MUST compare an idempotency token byte-exact.
Primitive policy 4: The composition MUST NOT normalize an idempotency token.
Primitive policy 5: IF the credential EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 6: The composition MUST NOT read the credential's content.
Primitive policy 7: The composition MUST validate EVERY field an action passes to a constituent PER the constituent's own field rules.
Primitive policy 8: IF the action's envelope EXCEEDS the payload cap THEN the action MUST answer invalid-request.
Primitive policy 9: An action MUST NOT record the action's intent entry BEFORE validating the action's inputs.
Primitive policy 10: An action refused under Primitive policy 1 through 8 MUST NOT write.
```

Term envelope: the largest journal entry an act can cause — the recovery outcome entry the reconciliation could land for the act, carrying the recovery candidates cap in ids and the call's own resource and requester.

WHY:
Primitive policy 7 pins the validation depth. Each constituent's own field rules — Provisional Commitment's for the resource, the requester and the duration, Capacity Constraint Enforcement's string rules for the actor reference it records on every allocation and release event — are run *before* the intent. A malformed tuple caught after [Reserve]'s allocate would have taken a slot and owed a compensation; caught before, it has taken nothing. The constituents' own invalid-request arms stay as the backstop, answered after the gate and settled against the token (Action wiring 50 and Action wiring 54); a refusal here writes nothing and settles nothing (Primitive policy 10), because a malformed call is not an act.

Primitive policy 8 sizes the largest record before the first one. Event Log's append declares an invalid-payload arm against the instance's payload cap, and the intent is not the largest entry an act can cause — the outcome is larger, the reconciliation's recovery entry larger still (the section titled *An outcome is sized before the intent* in `pressure-testing.md`). An invalid-payload after that sizing is a composition defect (Action wiring 31 and Action wiring 32).

Primitive policy 5 and 6 are the only check this layer makes on the credential — its shape. Actor Identity's attest reads the content, and its invalid-credential is a guard that fails before its own store write, so an unverifiable credential refuses the act with nothing written anywhere (Action wiring 22).

### Action wiring

```
reserve(pool_id, resource, requester, duration, actor_ref, credential, idempotency_token)
  answers reservation_id
  refuses invalid-request | invalid-credential | token-collision | not-known | pool-closed | pool-capacity-exceeded | resource-unavailable | recording-failure(position)

confirm_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-elapsed | recording-failure(position)

cancel_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-elapsed | recording-failure(position)

expire_reservation(reservation_id, actor_ref, credential, idempotency_token)
  answers ok
  refuses invalid-request | invalid-credential | token-collision | not-known | not-held | window-not-elapsed | recording-failure(position)

query_reservation(reservation_id)
  answers reservation reading
  refuses not-known
```

Term position: intent | outcome | inconsistency — the retry bit a recording-failure carries: nothing committed and the act may run again; an act under the token reached or may have reached the act's commit and must not run again; or the composition's own records disagree with a constituent's, which no retry cures.

Term stage: post-commit | post-release — where an outcome-position refusal from a resolving action stopped: the confirmation stands, or the slot is returned.

Term reservation reading: the reservation's state, the binding entry's pool id and the slot-held reading.

Term slot-held reading: true | false — whether the reservation holds a pool slot now.

```
Action wiring 1: EVERY state-changing action MUST take an idempotency token.
Action wiring 2: A state-changing action MUST NOT call Duplicate Prevention's check BEFORE taking the token exclusion.
Action wiring 3: A state-changing action MUST call Duplicate Prevention's record under the token exclusion.
Action wiring 4: A state-changing action MUST release EVERY exclusion the action holds on EVERY return.
Action wiring 5: IF Duplicate Prevention's check answers seen AND a matching token results entry EXISTS THEN the action MUST answer the entry's result.
Action wiring 6: IF a token results entry's action type DOES NOT EQUAL the call's action type THEN the action MUST answer token-collision.
Action wiring 7: IF a token results entry's parameters digest DOES NOT EQUAL the call's parameters digest THEN the action MUST answer token-collision.
Action wiring 8: A replay MUST NOT call a constituent.
Action wiring 9: A replay MUST NOT write a journal entry.
Action wiring 10: IF Duplicate Prevention's check answers seen AND no token results entry EXISTS for the token THEN the action MUST answer recording-failure carrying outcome.
Action wiring 11: The composition MUST NOT settle an answer for a seen token carrying no token results entry.
Action wiring 12: IF Duplicate Prevention's check answers not-seen THEN the action MUST read the journal for the token.
Action wiring 13: An action MUST NOT call Actor Identity's attest BEFORE reading the journal for a not-seen token.
Action wiring 14: IF the journal holds the action's outcome entry for the token AND the journaled digest EQUALS the call's parameters digest THEN the action MUST settle the outcome entry's result.
Action wiring 15: IF the journal holds an entry for the token whose action DOES NOT EQUAL the call's action OR whose journaled digest DOES NOT EQUAL the call's parameters digest THEN the action MUST answer token-collision.
Action wiring 16: IF the journal holds a compensation entry naming the token THEN [Reserve] MUST settle the compensation entry's recorded rejection.
Action wiring 17: [Reserve] MUST NOT write a binding entry from a compensation entry.
Action wiring 18: IF the journal holds a reserve outcome entry for the token AND no binding entry EXISTS for the entry's reservation id THEN [Reserve] MUST write the binding entry from the outcome entry.
Action wiring 19: IF the journal holds the action's intent entry for the token AND no resolving entry names the token THEN the action MUST settle recording-failure carrying outcome.
Action wiring 20: A state-changing action MUST call Actor Identity's attest with the action reference, the actor reference AND the credential.
Action wiring 21: A state-changing action MUST NOT call a constituent write BEFORE Actor Identity's attest answers the attestation id.
Action wiring 22: IF Actor Identity answers invalid-credential THEN the action MUST answer invalid-credential.
Action wiring 23: IF Actor Identity answers invalid-request THEN the action MUST answer invalid-request.
Action wiring 24: IF Actor Identity answers storage-failure THEN the action MUST answer recording-failure carrying intent.
Action wiring 25: The composition MUST NOT settle an attest refusal.
Action wiring 26: A state-changing action MUST record the action's intent entry ONLY AFTER Actor Identity answers the attestation id.
Action wiring 27: An intent entry MUST carry the action, the idempotency token, the attestation id, the actor reference, the now AND the action's business parameters.
Action wiring 28: A resolving action's intent entry MUST carry the binding entry's pool id.
Action wiring 29: IF Event Log answers storage-failure at an intent entry THEN the action MUST answer recording-failure carrying intent.
Action wiring 30: The composition MUST NOT settle a refused intent entry.
Action wiring 31: IF Event Log answers invalid-payload THEN the composition MUST answer recording-failure carrying the entry's position.
Action wiring 32: The deployment MUST alert on an invalid-payload as the composition's own defect.
Action wiring 33: [Reserve] MUST NOT record the intent entry BEFORE taking the pool exclusion.
Action wiring 34: A resolving action MUST NOT record the intent entry BEFORE taking the reservation exclusion.
Action wiring 35: An invocation MUST make a later write ONLY IF the invocation holds the invocation's exclusions.
Action wiring 36: An invocation that lost a exclusion MUST NOT write BEFORE taking the exclusion again.
Action wiring 37: An invocation taking a exclusion again MUST read the journal for the invocation's token under the exclusion.
Action wiring 38: IF the re-read finds a resolving entry for the token THEN the invocation MUST answer the resolving entry's result.
Action wiring 39: An invocation whose re-read finds a resolving entry MUST NOT call a constituent write.
Action wiring 40: An invocation's retries of one post-commit write MUST NOT EXCEED the outcome retry attempts.
Action wiring 41: An invocation that spent the outcome retry attempts MUST NOT write for the invocation's act.
Action wiring 42: A late outcome entry MUST carry the intent entry's attestation id AND the recovery flag.
Action wiring 43: A writer MUST NOT write a late outcome entry BEFORE reading the journal under the reservation exclusion for an outcome entry naming the token.
Action wiring 44: A writer MUST NOT write a late outcome entry for a token an outcome entry names.
Action wiring 45: An admitted reserve MUST call Capacity Constraint Enforcement's allocate with the pool id, a count of one AND the actor reference ONLY AFTER the intent entry lands.
Action wiring 46: IF Capacity Constraint Enforcement answers not-known for an allocate THEN [Reserve] MUST answer not-known.
Action wiring 47: IF Capacity Constraint Enforcement answers over-capacity THEN [Reserve] MUST answer pool-capacity-exceeded.
Action wiring 48: IF Capacity Constraint Enforcement answers suspended THEN [Reserve] MUST answer pool-closed.
Action wiring 49: IF Capacity Constraint Enforcement answers closed THEN [Reserve] MUST answer pool-closed.
Action wiring 50: IF Capacity Constraint Enforcement answers invalid-request for an allocate THEN [Reserve] MUST answer invalid-request.
Action wiring 51: IF Capacity Constraint Enforcement answers storage-failure for an allocate THEN [Reserve] MUST answer recording-failure carrying intent.
Action wiring 52: An admitted reserve MUST settle EVERY allocate refusal.
Action wiring 53: An admitted reserve MUST call Provisional Commitment's place hold with the resource, the requester AND the duration ONLY AFTER allocate answers the allocation event id.
Action wiring 54: IF Provisional Commitment answers invalid-request for a place hold THEN [Reserve] MUST answer invalid-request.
Action wiring 55: IF Provisional Commitment answers resource-unavailable THEN [Reserve] MUST answer resource-unavailable.
Action wiring 56: IF Provisional Commitment answers storage-failure for a place hold THEN [Reserve] MUST answer recording-failure carrying intent.
Action wiring 57: IF Provisional Commitment refuses a place hold THEN [Reserve] MUST call Capacity Constraint Enforcement's release with the pool id AND a count of one.
Action wiring 58: An admitted reserve MUST record a compensation entry ONLY AFTER the compensating release answers the release event id.
Action wiring 59: A compensation entry MUST carry the idempotency token, the pool id, the hold resolution, the allocation event id, the release event id, the reason, the attestation id AND the actor reference.
Action wiring 60: A compensation entry for a placed hold MUST carry the reservation id.
Action wiring 61: An admitted reserve MUST settle a place hold refusal ONLY AFTER the compensation entry lands.
Action wiring 62: An admitted reserve MUST record the reserve outcome entry ONLY AFTER place hold answers the reservation id.
Action wiring 63: A reserve outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the new state, the pool event balances, the allocation event id, the attestation id AND the actor reference.
Action wiring 64: An outcome entry citing a pool event MUST copy the pool event balances from the pool event through the pool event read.
Action wiring 65: IF Event Log refuses the reserve outcome entry THEN [Reserve] MUST settle recording-failure carrying outcome.
Action wiring 66: IF Event Log refuses the reserve outcome entry THEN [Reserve] MUST call Provisional Commitment's release for the hold.
Action wiring 67: IF Provisional Commitment answers window-elapsed to the hold compensation THEN [Reserve] MUST call Provisional Commitment's expire for the hold.
Action wiring 68: IF Provisional Commitment answers window-not-elapsed to the hold compensation THEN [Reserve] MUST call Provisional Commitment's release for the hold.
Action wiring 69: IF Provisional Commitment answers not-held to the hold compensation THEN [Reserve] MUST read the hold as terminal.
Action wiring 70: IF Provisional Commitment answers not-known to the hold compensation THEN [Reserve] MUST escalate an internal-consistency finding.
Action wiring 71: [Reserve] MUST NOT write for a hold compensation Provisional Commitment answered not-known.
Action wiring 72: An admitted reserve MUST call Capacity Constraint Enforcement's release for a hold compensation ONLY AFTER the hold stands terminal.
Action wiring 73: IF Capacity Constraint Enforcement answers over-release to a compensating release THEN [Reserve] MUST escalate a finding.
Action wiring 74: [Reserve] MUST NOT retry a compensating release Capacity Constraint Enforcement answered over-release.
Action wiring 75: IF Capacity Constraint Enforcement answers not-known OR invalid-request to a compensating release THEN [Reserve] MUST escalate a finding.
Action wiring 76: IF a compensation write answers storage-failure THEN [Reserve] MUST retry the write.
Action wiring 77: A compensation entry for a compensated hold MUST carry the hold resolution the hold compensation took.
Action wiring 78: An admitted reserve MUST write the binding entry carrying the pool id AND none as the release marker ONLY AFTER the reserve outcome entry lands.
Action wiring 79: An admitted reserve MUST settle the reservation id ONLY AFTER the binding entry lands.
Action wiring 80: IF a resolving action's reservation id names no binding entry THEN the action MUST answer not-known.
Action wiring 81: A resolving action MUST NOT write for a reservation id naming no binding entry.
Action wiring 82: IF Provisional Commitment answers not-known to a resolving action's transition THEN the action MUST answer recording-failure carrying inconsistency.
Action wiring 83: The composition MUST settle EVERY recording-failure carrying inconsistency.
Action wiring 84: The deployment MUST alert on a recording-failure carrying inconsistency as the composition's own defect.
Action wiring 85: IF Provisional Commitment answers not-held to a resolving action's transition THEN the action MUST answer not-held.
Action wiring 86: IF Provisional Commitment answers window-elapsed to a resolving action's transition THEN the action MUST answer window-elapsed.
Action wiring 87: IF Provisional Commitment answers window-not-elapsed to a resolving action's transition THEN the action MUST answer window-not-elapsed.
Action wiring 88: IF Provisional Commitment answers storage-failure to a resolving action's transition THEN the action MUST answer recording-failure carrying intent.
Action wiring 89: The composition MUST settle EVERY guard refusal of a resolving action's transition.
Action wiring 90: [Confirm Reservation] MUST call Provisional Commitment's confirm with the reservation id ONLY AFTER the intent entry lands.
Action wiring 91: [Confirm Reservation] MUST NOT call a Capacity Constraint Enforcement write.
Action wiring 92: [Confirm Reservation] MUST record the confirm outcome entry ONLY AFTER confirm answers ok.
Action wiring 93: A confirm outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the prior state, Confirmed as the new state, the witness balance, the attestation id AND the actor reference.
Action wiring 94: IF Event Log refuses the confirm outcome entry THEN [Confirm Reservation] MUST settle recording-failure carrying outcome AND post-commit as the stage.
Action wiring 95: The composition MUST NOT compensate a confirm.
Action wiring 96: [Confirm Reservation] MUST settle ok ONLY AFTER the confirm outcome entry lands.
Action wiring 97: [Cancel Reservation] MUST call Provisional Commitment's release with the reservation id ONLY AFTER the intent entry lands.
Action wiring 98: [Expire Reservation] MUST call Provisional Commitment's expire with the reservation id ONLY AFTER the intent entry lands.
Action wiring 99: A slot-returning action MUST write the release marker as pending ONLY AFTER the action's transition answers ok.
Action wiring 100: A slot-returning action MUST NOT write the pending marker BEFORE taking the pool exclusion.
Action wiring 101: IF the binding refuses the pending marker THEN the slot-returning action MUST settle recording-failure carrying outcome.
Action wiring 102: A slot-returning action MUST NOT call Capacity Constraint Enforcement's release BEFORE the pre-check.
Action wiring 103: IF the pre-check finds a slot-returning outcome entry naming the reservation THEN the slot-returning action MUST NOT call Capacity Constraint Enforcement's release.
Action wiring 104: IF the pre-check finds a slot-returning outcome entry AND the release marker EQUALS pending THEN the slot-returning action MUST set the release marker to released carrying the entry's release reading.
Action wiring 105: IF the pre-check finds a slot-returning outcome entry THEN the slot-returning action MUST settle ok.
Action wiring 106: A slot-returning action MUST call Capacity Constraint Enforcement's release with the pool id, a count of one AND the actor reference ONLY AFTER the pending marker lands.
Action wiring 107: IF Capacity Constraint Enforcement refuses a slot-returning action's release THEN the action MUST settle recording-failure carrying outcome.
Action wiring 108: A slot-returning action MUST NOT retry a refused pool release.
Action wiring 109: A slot-returning action MUST set the release marker to released carrying the release event id ONLY AFTER Capacity Constraint Enforcement's release answers the release event id.
Action wiring 110: A slot-returning action MUST record the action's outcome entry ONLY AFTER the released marker lands.
Action wiring 111: A slot-returning outcome entry MUST carry the idempotency token, the reservation id, the pool id, Held as the prior state, the terminal state, the pool event balances, the release event id, the attestation id AND the actor reference.
Action wiring 112: IF Event Log refuses the slot-returning outcome entry THEN the slot-returning action MUST settle recording-failure carrying outcome AND post-release as the stage.
Action wiring 113: A slot-returning action MUST settle ok ONLY AFTER the action's outcome entry lands.
Action wiring 114: [Query Reservation] MUST NOT take an idempotency token.
Action wiring 115: [Query Reservation] MUST NOT write.
Action wiring 116: IF the reservation id names no binding entry THEN [Query Reservation] MUST answer not-known.
Action wiring 117: [Query Reservation] MUST answer the reservation's state from Provisional Commitment, the binding entry's pool id AND the slot-held reading.
Action wiring 118: The slot-held reading MUST read true ONLY IF the reservation's state IS IN the slot-holding states AND the release marker EQUALS none.
```

Term state-changing action: [Reserve] | [Confirm Reservation] | [Cancel Reservation] | [Expire Reservation].

Term resolving action: [Confirm Reservation] | [Cancel Reservation] | [Expire Reservation].

Term slot-returning action: [Cancel Reservation] | [Expire Reservation].

Term settling: writing an answer to the token results map against the token, calling Duplicate Prevention's record, and answering the caller — the cache-the-failure rule, which settles a rejection exactly as an answer.

Term replay: a call answered from a matching token results entry.

Term matching token results entry: a token results entry whose action type AND parameters digest equal the call's.

Term action reference: `<action type>:<idempotency token>` — the per-invocation reference Actor Identity binds an attestation to; an [Action Reference].

Term journaled digest: the parameters digest the seam recomputes from an intent entry's business parameters.

Term intent entry: a reserve intent, a confirm intent, a cancel intent or an expire intent — the journal entry an action appends before any constituent call that commits.

Term outcome entry: a reserve outcome entry, a confirm outcome entry or a slot-returning outcome entry — the journal entry an action appends after the action's act commits.

Term slot-returning outcome entry: a cancel outcome entry or an expire outcome entry, in-line or carrying the recovery flag.

Term resolving entry: an outcome entry, a compensation entry or a recovery outcome entry naming a token.

Term late outcome entry: an outcome entry written after the invocation's own attempts, by the invocation or by the reconciliation.

Term recovery flag: recovery set to true — the field that tells a reader an entry written after the fact from one written in line.

Term recorded rejection: the reason an in-line compensation entry carries, or recording-failure carrying outcome for a compensation entry the reconciliation wrote.

Term hold resolution: none | released | expired — how a compensation left the hold: none placed, released while the hold's window stood open, or expired once the window lapsed.

Term hold compensation: [Reserve]'s drive of a placed hold to a terminal state after the reserve outcome entry did not land.

Term compensating release: the Capacity Constraint Enforcement release that returns a slot [Reserve] allocated and no reservation holds.

Term compensation write: a hold compensation call, a compensating release or a compensation entry.

Term later write: a write an invocation makes after the invocation's first write.

Term admitted reserve: a [Reserve] call whose attest answered the attestation id and whose reserve intent landed.

Term post-commit write: a write an invocation owes after the invocation's act committed — an outcome entry, a compensation write, a release marker.

Term pool event balances: the opening balance and closing balance of the pool event an outcome entry cites.

Term witness balance: one reading of the pool's allocated through Capacity Constraint Enforcement's query, carried as both balances on a confirm outcome entry — a witness that the slot stayed counted, never a chain link.

Term pre-check: a slot-returning action's read, under the reservation exclusion and the pool exclusion, of the release marker and of the journal for a slot-returning outcome entry naming the reservation.

Term pending marker: a release marker reading pending.

Term released marker: a release marker reading released.

Term terminal state: Released for [Cancel Reservation]; Expired for [Expire Reservation].

WHY:
**The idempotency shape** is the precursor's, declared here in full: validate the token, take the token exclusion, consult Duplicate Prevention's check, replay on a matching entry, otherwise delegate, then settle the answer — rejection or success, the cache-the-failure rule — and record the token. A replay is answered from the map and touches nothing else (Action wiring 8 and 9): it attests nothing and journals nothing, so **within the idempotency window the token is a bearer secret** — any caller presenting it gets the first call's answer — and the page says so rather than claiming a record of who retried (Non-goal 12 and 13). Invariant 8 is about commitment, and a replay commits nothing.

**Not-seen is not proof that nothing ran** (Action wiring 12 through 19). It proves the token was never recorded, and a crash between an outcome landing and the record leaves a completed act the constituent never heard of; a bare delegation would allocate and hold a second time for one token. So on not-seen the action reads the journal for the token first (the section titled *Recovery commits under a declared service identity* in `pressure-testing.md`, the re-entry tell): an outcome settles its result, a compensation settles its recorded rejection and populates no binding — a compensated hold holds no slot — and a bare intent settles recording-failure carrying outcome, because an earlier invocation under the token may hold a slot, this one cannot tell, and the reconciliation is the one writer that resolves it. Without the reconciliation settling those tokens in turn (Reconciliation 33), a deferred retry would defer forever. A seen token with no entry is the fail-closed landing (Action wiring 10 and 11): Duplicate Prevention remembers a token the composition does not — a durability breach, or an unavailable guard read as seen — and the outcome position is the safe direction, left unsettled so a later call decides afresh once the guard answers.

**Attest first, and per invocation** (Action wiring 20 through 25). The attestation opens every state-changing action before any constituent call that commits, and Actor Identity's invalid-credential fails before even its own store write, so an unverifiable credential refuses the act with nothing written anywhere — no attestation, no allocation, no hold, no settled answer. The action reference is `<action type>:<idempotency token>` rather than a bare kind token: Actor Identity's Invariant 2 binds a proof to the action reference recorded with it, so a reference shared by every reservation would make every attestation of that kind substitutable for every other. The token is required and per-invocation, so composing it mints nothing.

**The intent is the marker before the act** (Action wiring 26 through 32). An intent entry with no outcome names an invocation that committed nothing, committed and failed to journal, or died between — which is what the reconciliation reads, and what used to have to be inferred from constituent state alone. Every recording-failure carries the retry bit (the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): at intent, nothing committed and the refusal is not settled, so the same token retries the whole action; at outcome, an act reached or may have reached its commit, the refusal is settled, and the caller reads [Query Reservation] where it holds an id, otherwise waits for the reconciliation, whose resolution the same token then replays. Event Log calls its storage-failure definitive — *the event does not land* — and a journal that lands the append and still answers the failure has produced the bare intent Action wiring 19 finds on the same-token retry, so the two arms compose rather than conflict. **Inconsistency** is the third position (Action wiring 82 through 84): the composition knows the reservation id and Provisional Commitment does not, which no retry cures, so it is settled and alerted as the composition's own defect rather than passed off as a transient.

**The exclusions make every look-then-write exact** (Action wiring 33 through 44). An invocation that stalls between the intent and the pool call and wakes after the reconciliation resolved its token must not allocate on a token the reconciliation already settled; the exclusion is what stops it, and an invocation finding a exclusion lost takes it again and re-reads the journal for its own token under it, adopting a resolving entry rather than writing (*proceed as landed*). The invocation and the reconciliation are never both writers for one act (the section titled *A compensator is exclusive* in `pressure-testing.md`): the invocation retries a post-commit write at most the outcome retry attempts and then yields — one injected now serves an invocation, so its terminus is counted rather than timed.

**[Reserve] binds the capacity gate to the hold** (Action wiring 45 through 79): the slot is allocated only if the hold is taken, and the hold is taken only if a slot was available. A refused allocate is settled and places no hold; the intent it leaves stands behind no allocation event and explains no slot of divergence (Invariant 1.3). A refused place hold is answered only after the compensating release returns the slot and the compensation entry names it — appended after the release, since the release is a committed write on the pool's own append-only audit log and the entry an append, and neither can be withdrawn; a crash between them is the reconciliation's, resolved by arithmetic. That compensation is the only path where the composition returns a slot without a terminal transition, and it exists to keep allocation coherence across a partial [Reserve]. **A failed reserve outcome entry is compensated, not completed**: the allocated slot and the Held commitment have no journaled event and no binding, so every resolution action would answer not-known, and the hold compensation **branches on the window** — release while the window is open, expire once it has lapsed, since the constituent refuses release on a lapsed hold with window-elapsed, a rejection that never clears, and a release-only retry would spin forever. Its arms are partitioned, not looped: storage-failure retries, window-elapsed and window-not-elapsed switch branches, not-held means a concurrent path already resolved the hold, not-known and over-release are findings and never retried. The binding is written only after the outcome lands (audit-first), so a reservation never becomes resolvable without its reserve outcome entry. The pool event balances are copied from the pool's own allocation event, which Capacity Constraint Enforcement writes atomically with the running total — the before and after of *this* call, which two query reads around the call, a three-call exclusion the pool's per-call serialization does not cover, never were.

**[Confirm Reservation] keeps the slot** (Action wiring 90 through 96): Confirmed consumes the unit, allocated is unchanged, and no pool write is made. Its window-elapsed is the composition's *no confirmation of a lapsed hold* guarantee; the slot of the lapsed hold is the expiry sweep's to return. **The confirm pair is completed, never compensated**: confirm is irreversible, so a failed outcome entry after the transition committed leaves a Confirmed commitment whose journal still says Held; the refusal carries post-commit so the caller knows the confirmation stands, and the invocation owes the late outcome entry, then yields it to the reconciliation — the late entry carrying the intent's attestation id, since the proof was already made, and the recovery flag, so an auditor tells it from one written in line. The Provisional Commitment record answers directly whether the confirm committed, so no transaction is needed and none is claimed. The witness balance is one query read — a single call, atomic under the pool's own serialization — carried as a witness that the slot stayed counted, never as a chain link.

**[Cancel Reservation] and [Expire Reservation] return the slot in order, exactly once** (Action wiring 97 through 113): the transition, the pending marker, the pool release, the released marker, the outcome entry — none of it inside a transaction, since the transition is absorbing, the pool release an append on the pool's audit log and the entry an append (Wiring decision 4). A refused transition stops everything after it: not-held because the reservation already resolved, or window-elapsed because a lapsed hold is the expiry sweep's — and the intent it leaves is **the record of the attempt and of nothing more**, never compensated as a return that was begun (Composition state 13). A refused pool release is settled at outcome and never retried: on storage-failure the release may or may not have committed, the token cannot tell, and the reconciliation decides by the pool's own count. **What makes the return exactly-once is not a transaction — it is the marker plus the reconciliation**: a crash anywhere leaves a terminal record, possibly a pending marker, possibly a release event, and no outcome, and the reconciliation decides *whether* the release landed from the pool's allocated against the journaled live set, under the pool exclusion. The count is the second source the old one-atomic-commit requirement was standing in for, and, unlike that requirement, one the stores can supply.

### Wiring decision

```
Wiring decision 1: The composition MUST record the reservation holding a pool slot in the reservation-to-pool binding.
Wiring decision 2: The composition MUST NOT place a hold BEFORE allocating the hold's slot.
Wiring decision 3: The composition MUST NOT release a Confirmed reservation's slot.
Wiring decision 4: The composition MUST NOT enlist a constituent write in a host transaction.
Wiring decision 5: The composition MUST decide whether a slot return landed from the pool's allocated against the journal.
Wiring decision 6: The composition MUST release a slot ONLY IF a slot-returning transition OR a [Reserve] compensation owes the slot.
```

Term slot-holding state: Held | Confirmed — a reservation in either state counts against the pool's allocated.

Term slot-returning state: Released | Expired — the two constituent-terminal states that give the slot back.

Term constituent-terminal state: Confirmed | Released | Expired — Provisional Commitment's absorbing states; Confirmed among them keeps the slot.

WHY:
**Allocation coherence: the pool's allocated equals the reservations in a slot-holding state bound to the pool, at every instant of quiescence — so the pool never oversells and never strands a slot.**

**Two senses of *terminal*, named so every test here can say which it means.** Provisional Commitment's constituent-terminal states are all absorbing, and a reservation in any of them never transitions again. Only two are slot-returning: Released and Expired give the slot back, and **Confirmed keeps it** — a firm booking consumes the unit for as long as it stands. Every stranded-slot test on the page — Invariant 2, Check 3.1 through 3.7, the reconciliation, the leak forensics — is scoped to the slot-returning states. A Confirmed reservation with a release marker of none is the correct steady state, not a finding.

*Principle.* A reservation system must, from the pool count alone, never confirm more reservations than capacity and never lose a freed slot. Structurally the pool's running total and the live-reservation set must move together: a reservation enters the live set exactly when it takes a slot and leaves exactly when its slot is returned.

*Likely objection.* Capacity Constraint Enforcement already bounds allocated by capacity, and Provisional Commitment already owns the reservation state machine. Why not let the caller allocate on place hold and release on the terminal transition?

*Mechanism.* Neither constituent knows the other, and the seam between them is exactly where coherence breaks. The pool keeps a fungible count with no per-allocation identity, so it cannot know that *this* release corresponds to *that* lapsed hold, or refuse a slot released twice for one reservation. The commitment has per-reservation identity and no notion of a pool — its release and expire decrement nothing. A caller wiring the two by hand re-implements the binding at every call site, and the first site that releases a slot for a reservation already lapsed (double release, count below the truth), transitions a hold terminal without releasing (leak, count above the truth), or confirms a hold whose slot an expiry sweep already returned (oversell) breaks coherence silently. The composition owns the binding with its three-valued release marker (Wiring decision 1): [Reserve] allocates, then holds, with a compensating release if the hold fails (Wiring decision 2); [Confirm Reservation] keeps the slot (Wiring decision 3); [Cancel Reservation] and [Expire Reservation] resolve the commitment and then release the slot, in order, with the marker and the reconciliation making the release happen exactly once. **An earlier revision required the transition, the pool release and the journal entry to commit as one atomic trio, and no constituent could honor it** (Wiring decision 4): the transition is absorbing, the pool release an append on the pool's audit log and the entry an append, so a rollback of any of them was an undeclared capability, and an entry rolled back after it landed was a false record. The ambiguity the trio was meant to remove — a lost release against a lost record of one — is resolved by the second source the stores do supply, the pool's own allocated against the journal (Wiring decision 5). And the confirm-within-window guarantee — Provisional Commitment's, surfaced as window-elapsed — forecloses confirming a slot an expiry already returned.

*Result.* Allocation coherence is structural. An auditor, or the pool's own query, reads allocated and can trust it equals the live reservations against the pool. The three failure modes that define reservation bugs — oversell, leak, double release — are each foreclosed by a named mechanism: every [Reserve] gated on allocate, every slot-returning transition releasing exactly once, and the window guard. No other path releases a slot (Wiring decision 6).

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a journal entry other than an examinable entry.
Reconciliation 4: The reconciliation MUST NOT write for an aged entry.
Reconciliation 5: The reconciliation MUST attest EVERY write under the service identity.
Reconciliation 6: The reconciliation MUST attest with the recovery action reference.
Reconciliation 7: The reconciliation MUST NOT write BEFORE the reconciliation's recovery intent lands.
Reconciliation 8: A recovery intent MUST carry the pool id, the reservations AND the count the reconciliation is about to release.
Reconciliation 9: A recovery outcome entry MUST carry the recovery flag, the pairing intent's attestation id AND the service identity's actor reference.
Reconciliation 10: The reconciliation MUST NOT read a pool BEFORE taking the pool exclusion.
Reconciliation 11: The reconciliation MUST skip a pool whose pool exclusion the reconciliation cannot take.
Reconciliation 12: The reconciliation MUST read a pool's allocated AND audit log through the pool event read in one consistent read.
Reconciliation 13: The reconciliation MUST NOT count a reservation BEFORE taking the reservation exclusion.
Reconciliation 14: The reconciliation MUST NOT count a reservation whose reservation exclusion the reconciliation cannot take.
Reconciliation 15: The reconciliation MUST compute the expected count for EVERY pool the reconciliation examines.
Reconciliation 16: The reconciliation MUST key the open returns per reservation.
Reconciliation 17: The reconciliation MUST NOT count an intent other than a matching intent toward an open return.
Reconciliation 18: IF the unlanded return count DOES NOT EXCEED the open return count THEN the reconciliation MUST release the unlanded return count in slots.
Reconciliation 19: IF the unlanded return count EXCEEDS the open return count THEN the reconciliation MUST release one slot PER open return.
Reconciliation 20: IF the unlanded return count EXCEEDS the open return count THEN the reconciliation MUST report the excess as a coherence finding.
Reconciliation 21: IF the justified count EXCEEDS the pool's allocated THEN the reconciliation MUST report a double release.
Reconciliation 22: The reconciliation MUST NOT allocate to repair a double release.
Reconciliation 23: The reconciliation MUST record EXACTLY ONE recovery outcome entry PER open return.
Reconciliation 24: IF the open return count EXCEEDS one THEN EVERY recovery outcome entry for the pool MUST name the open returns as the release candidates.
Reconciliation 25: The reconciliation MUST pair an open return with the open return's earliest matching intent by sequence number.
Reconciliation 26: A recovery outcome entry MUST name the open return's other matching intents as the intent candidates.
Reconciliation 27: A recovery outcome entry for a return the reconciliation did not release MUST carry unknown as the release reading.
Reconciliation 28: IF a pool's open returns EXCEED the recovery candidates cap THEN the reconciliation MUST escalate the pool as an unresolved finding.
Reconciliation 29: The reconciliation MUST NOT write for a pool whose open returns EXCEED the recovery candidates cap.
Reconciliation 30: The reconciliation MUST drive EVERY orphan hold terminal PER Action wiring 66 through 72.
Reconciliation 31: The reconciliation MUST release one slot PER open partial ONLY AFTER the partial's orphan holds stand terminal.
Reconciliation 32: The reconciliation MUST record a compensation entry naming the pool's examinable open reserve intents as the intent candidates.
Reconciliation 33: The reconciliation MUST settle recording-failure carrying outcome for EVERY examinable reserve intent carrying no resolving entry whose token Duplicate Prevention's check answers not-seen.
Reconciliation 34: The reconciliation MUST NOT settle a deferred reserve token BEFORE compensating the pool's open partials.
Reconciliation 35: IF Duplicate Prevention's check answers not-seen for an examinable reserve outcome entry's token THEN the reconciliation MUST write the entry's missing binding entry.
Reconciliation 36: IF Duplicate Prevention's check answers not-seen for an examinable reserve outcome entry's token THEN the reconciliation MUST settle the entry's reservation id.
Reconciliation 37: IF an unjournaled confirmation stands THEN the reconciliation MUST record the confirmation's late outcome entry.
Reconciliation 38: The reconciliation MUST escalate EVERY overdue partial as an unresolved finding.
Reconciliation 39: The reconciliation MUST make EVERY write under the exclusion the write's pre-check read under.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a returned slot, a landed entry, a settled token or an escalation — an auditor awaits within the compensation window.

Term examinable entry: a journal entry whose `recording instant + reservation completion bound` PRECEDES now and that is not an aged entry.

Term recovery intent: the recovery_intended entry — the reconciliation's intent, naming the pool, the reservations and the count it is about to release.

Term recovery outcome entry: a slot-returning outcome entry the reconciliation writes, carrying the recovery flag.

Term recovery action reference: `recovery:<idempotency token>` — the action reference the reconciliation attests under, keyed by the original invocation's token.

Term bound slot-holding count: the count of a pool's bound reservations in a slot-holding state.

Term open partial: an allocation event of the pool that neither a reserve outcome entry nor a compensation entry names — an open [Reserve] partial, of any age.

Term open return: a reservation in a slot-returning state that no slot-returning outcome entry names and that a pending marker or a matching intent names — a return that may have landed and was never journaled.

Term open return count: the count of a pool's open returns.

Term expected count: `bound slot-holding count + open partial count + open return count`.

Term open partial count: the count of a pool's open partials.

Term justified count: `expected count − open return count`.

Term unlanded return count: `allocated − justified count` — the open returns whose release did not land.

Term release candidates: the open returns of one pool, named on every recovery outcome entry where more than one was open at once.

Term intent candidates: the matching intents of one open return beside the pairing intent, or the open reserve intents a compensation entry the reconciliation writes names.

Term orphan hold: a Held commitment named by no binding entry whose resource and requester equal an open partial's reserve intent's.

Term deferred reserve token: an examinable reserve intent's token carrying no resolving entry.

Term unjournaled confirmation: a confirm intent with no confirm outcome entry whose reservation Provisional Commitment shows Confirmed.

Term overdue partial: an open partial, an open return or an unjournaled confirmation whose first entry's `recording instant + compensation window` PRECEDES now.

WHY:
**The failure classes are not symmetric in their recoverability, so the obligations split.** The slot-returning pair is ordered and reconciled by the pool's own count; the [Reserve] seams are compensable and their compensations journaled; the confirm pair is completed by a late write. The reconciliation is what closes each when the invocation that owed it is gone.

**It runs between two edges and as the composition** (Reconciliation 1 through 9; the sections titled *A reconciliation is bounded at both ends* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below the completion bound an entry may belong to an invocation still between its writes — compensating a live [Reserve] returns a slot it is about to hold, and completing a live cancel releases twice. Past the audit horizon the entry's payload may be destroyed and the binding's purged half is truth-bearing: read, never repaired. Every write it makes is behind a recovery intent and attested under the service identity, with the original token in the action reference; it never attests as the absent operator, whose attestation id it carries instead.

**The pool leg decides by arithmetic** (Reconciliation 10 through 29). Under the pool exclusion — while the reconciliation holds it, no invocation is between its pool call and its outcome entry — one consistent read of the pool's allocated and audit log stands beside a journal read. The expected count adds the bound slot-holding reservations, the open partials of any age, and the open returns. **An open return is keyed per reservation, never per intent, and counted only under its own exclusion**: a reservation whose exclusion a live invocation holds is inside its bound and that invocation's to return, and an intent enters only as a matching intent where no slot-returning outcome names the reservation at all — a cancel refused not-held because another token already returned the slot, or window-elapsed because the sweep's expiry owns it, is not a return begun. The unlanded return count is exactly the number of open returns whose release did not land; the leg releases that many, the pool being fungible, **and never more than the open returns** — an excess is a coherence finding, reported, not released (Reconciliation 18 through 20). It lands exactly one recovery outcome entry per open return, naming the whole open set as release candidates where several were open at once, since which of several concurrent returns landed is not decidable from a fungible counter, and the record says so; a return that landed before the crash carries unknown as its release reading (Reconciliation 27), and the recovery entries' balances are no chain link (Check 7.1). A negative count — the pool holds fewer than the records justify — is a double release, reported and never repaired by allocating. Both candidate sets are bounded by the recovery candidates cap, so every recovery entry stays inside the envelope each action sized at validation; a pool whose open set exceeds it is escalated and left for the operator.

**The partial leg compensates, then settles** (Reconciliation 30 through 36). An open partial is found through the pool event read, since an intent alone names no allocation. Its orphan hold is the step Provisional Commitment's store still shows Held — the expiry sweep meets it as not-known, because it has no binding (Expiry sweep 2) — so the leg drives it terminal by the same window branch [Reserve] uses, then returns the slot, then journals the compensation naming the open reserve intents as candidates. Only then does it settle every deferred reserve token at outcome — the tokens Action wiring 19 defers to it — and it completes the record step for any reserve outcome whose record never landed.

**The confirm leg writes the owed entry** (Reconciliation 37): an unjournaled confirmation owes its late outcome entry, written under the reservation exclusion after a read for an existing outcome; an invocation still retrying holds that exclusion until it has spent its attempts, so the two never both write.

**One writer per act** (Reconciliation 39; the section titled *A compensator is exclusive* in `pressure-testing.md`). Two runs of a leg — at restart and on cadence, on one node or two — serialize on the same exclusions, a run that cannot take a pool's exclusion skips the pool until its next run, and every look-then-write is re-read under the exclusion, never before it. A partial not resolved within the compensation window escalates rather than staying an open retry.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Allocation coherence.**
  ```
  Invariant 1.1: At quiescence a pool's allocated MUST NOT EXCEED the pool's bound slot-holding count.
  Invariant 1.2: A pool's divergence MUST NOT EXCEED the pool's accounted divergence.
  Invariant 1.3: A reserve intent standing behind no allocation event MUST NOT enter a pool's accounted divergence.
  Invariant 1.4: EVERY open partial AND EVERY open return MUST close WITHIN the compensation window.
  Invariant 1.5: At quiescence a pool's bound slot-holding count MUST NOT EXCEED the pool's allocated.
  ```
  Term quiescence: a pool state in which no [Reserve] against the pool is in flight and no compensation is owed.

  Term divergence: `allocated − bound slot-holding count` for one pool.

  Term accounted divergence: `open partial count + open return count` for one pool.

  WHY: the safety half holds at quiescence and the liveness half says every divergence is a named window that closes. The equality is knowingly false inside exactly three windows the wiring declares: between [Reserve]'s allocate and place hold, where the slot is counted and no reservation exists; between place hold and the reserve outcome entry, where the reservation is Held but unbound; and while a compensation is owed after either seam failed. Each closes when the outcome or the compensation lands (Invariant 1.4), the reconciliation carrying the eventuality. **Every window is keyed on an allocation event of the pool's own audit log, never on an intent alone** (Invariant 1.3): an unmatched reserve intent behind which no allocation event stands — refused at the gate, or dead before it — holds zero slots, and a window keyed on it would excuse one slot of divergence for as long as the intent survives, which is forever. *Rests on* Capacity Constraint Enforcement's Invariant 4 and Invariant 5 under that atom's own host obligations — per-pool serialization of each call, overflow-safe arithmetic, crash-atomic multi-record writes — inherited as the deployment's; the pool's audit log read through the pool event read; the exclusions and the journal's durability (Capability requirement 12 through 26); Provisional Commitment's state exclusivity and terminal absorption; and the ordered slot-returning steps with the release marker and the reconciliation, which resolves every crash between the transition and the outcome entry from the pool's own count. This is the invariant the formal model checks (the Ledger's formal line).
- **Invariant 2 — Slot returned at most once.**
  ```
  Invariant 2.1: The composition MUST NOT commit two pool releases for one reservation.
  ```
  WHY: [Cancel Reservation] and [Expire Reservation] release only for a reservation transitioning out of Held, and Provisional Commitment's single resolution — exactly one terminal transition commits, even under race — and terminal absorption mean the slot-returning transition fires once. *Rests on* those two constituent invariants, the release marker — read by every pre-check and by the reconciliation, which never releases for a reservation the marker or the journal shows returned — and the reconciliation's arithmetic, which releases exactly the unlanded returns and never more, with **one writer per return**: the invocation until it spends the outcome retry attempts, the reconciliation after, both under the reservation exclusion, over a journal that survives the crash. The constituent's over-release fires only when the *whole pool* would over-drain, so it is a pool-level sanity arm; the marker and the reconciliation carry this invariant.
- **Invariant 3 — Confirmed reservations never exceed capacity.**
  ```
  Invariant 3.1: A pool's Confirmed reservations MUST NOT EXCEED the pool's capacity.
  ```
  WHY: every Confirmed reservation holds a slot counted in allocated (Invariant 1), and allocated never exceeds capacity (Capacity Constraint Enforcement's Invariant 4), so the Confirmed count is bounded by capacity. This is the *no-oversell* guarantee in the form a booking operator states it.
- **Invariant 4 — No confirmation of a lapsed hold.**
  ```
  Invariant 4.1: The composition MUST NOT confirm a reservation whose window reading EQUALS lapsed.
  Invariant 4.2: A lapsed hold MUST resolve ONLY through [Expire Reservation].
  ```
  WHY: [Confirm Reservation] relays Provisional Commitment's window-elapsed unchanged, which *rests on* the constituent's confirmation-within-the-window invariant. It is what prevents confirming a slot an expiry sweep already returned — the coherence guard at the confirm and expire race.
- **Invariant 5 — Idempotent reservation actions.**
  ```
  Invariant 5.1: Two calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 5.2: The composition MUST NOT call a constituent write twice for one idempotency token inside the idempotency window.
  Invariant 5.3: A call reusing an idempotency token across action types MUST answer token-collision.
  Invariant 5.4: The composition MUST make the idempotency claim ONLY IF the deployment declares Duplicate Prevention's store obligations AND the token exclusion.
  ```
  WHY: *rests on* this composition's own wiring and its wired constituent — the per-action shape, the token results map settling every answer, Duplicate Prevention's membership and single-recording invariants, and the token exclusion — all under Duplicate Prevention's inherited obligations, exactly as Invariant 1 is conditioned on the pool's. A window miss traceable to a violated obligation is a deployment finding against the obligation, not a disproof. Idempotent Reservation's Invariant 1 through 4 are the same claims over the narrower surface — cited as the shape's heritage, not as a dependency on a peer this spec does not wire. Idempotency is what makes the coherence guarantees hold *under retry*: a retried [Reserve] takes no second slot.
- **Invariant 6 — Every state change is attributed and journaled.**
  ```
  Invariant 6.1: EVERY committed state change MUST carry EXACTLY ONE outcome entry at quiescence.
  Invariant 6.2: An outcome entry MUST carry the attestation id the invocation's attest answered.
  Invariant 6.3: The sequence number of the intent entry carrying an outcome entry's attestation id MUST NOT EXCEED the outcome entry's sequence number.
  Invariant 6.4: A read-only query MUST NOT write a journal entry.
  ```
  WHY: an auditor reads an entry, takes its attestation id and calls Actor Identity's verify against it: the attribution is *witnessed*, not narrated. An invocation a constituent guard refused leaves its intent unmatched — the record of an attempt, not a gap. *Rests on* Event Log's append-only total order under the deployment's durability obligation, Actor Identity's attest and verify, the audit-first order at [Reserve], the ordered slot-returning steps, and the late outcome write on both pairs — the windows in which a committed change is journaled after the fact, closed by an entry carrying the recovery flag and the invocation's own attestation id, paired to its intent by the token and the attestation id both carry. The reservation lifecycle is reconstructable from the journal alone at quiescence.
- **Invariant 8 — Authentication precedes commitment.**
  ```
  Invariant 8.1: The composition MUST NOT reach a constituent call that commits BEFORE Actor Identity's attest answers the attestation id.
  Invariant 8.2: An attestation MUST bind the action reference of one invocation.
  Deleted: Invariant 7. Composes 5 owns it.
  ```
  WHY: the mechanism is the attest call that opens every state-changing action — before allocate and place hold at [Reserve], before confirm at [Confirm Reservation], before the terminal steps at [Cancel Reservation] and [Expire Reservation] — so a slot is never taken, confirmed, released or expired on an unverified actor's asserted authority. **What this does and does not establish:** a successful attestation establishes that material matching the actor's registered verifier was presented at that instant, and leaves a proof an auditor can verify again. It does *not* establish that the presenter *is* that actor — a stolen credential validates — that the presentation is bound to a channel or a session, or that it cannot be replayed, and it establishes nothing about *authorization* (Non-goal 10). *Rests on* Actor Identity's attest guard order and Event Log's append-only order. The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).

Allocation coherence with slot-returned-at-most-once gives the *no leak, no double release* property — the pool count is a faithful image of the live set. Never-exceed-capacity with no-confirmation-of-a-lapsed-hold gives the *no oversell* property across the confirm and expire race. Idempotency makes both hold under retry; attribution and journaling make the whole arc reconstructable from the records.

---

## Examples

### Walkthrough — event ticketing against a bounded pool

A venue sells a 2-seat VIP (very important person — premium) tier as a Capacity Constraint pool `pool_vip` with `capacity = 2`. The composition runs with a 5-minute idempotency window and an eager expiry sweep.

1. **Reserve (buyer A).** `reserve(pool_vip, resource="vip-tier", requester="buyer_a", duration=10m, actor_ref="checkout_svc", credential=<checkout_svc>, idempotency_token=tok_a1) → reservation_id = rsv_001`. Internally: `Capacity Constraint.allocate(pool_vip, 1, ...)` → `allocated: 0 → 1`; `Provisional Commitment.place_hold("vip-tier", "buyer_a", 10m)` → `rsv_001` (Held); Event Log records [Reserve]; `reservation_to_pool[rsv_001] = {pool_vip, release: none}`. `query(pool_vip).allocated = 1`.
2. **Reserve (buyer B).** `reserve(pool_vip, ..., requester="buyer_b", ..., idempotency_token=tok_b1) → rsv_002`. `allocated: 1 → 2`. The pool is now full.
3. **Reserve (buyer C) — capacity gate fires.** `reserve(pool_vip, ..., requester="buyer_c", ..., idempotency_token=tok_c1)` → `Capacity Constraint.allocate(pool_vip, 1, ...)` → `over-capacity` → `rejected(pool-capacity-exceeded)`. No hold is placed; `allocated` stays 2. Buyer C is not oversold. (Invariant 3.)
4. **Retry buyer A's reserve (network drop).** `reserve(pool_vip, ..., idempotency_token=tok_a1)` → `DuplicatePrevention.check(tok_a1) → seen`; cached `(reserve, digest_a, rsv_001)` replayed → returns `rsv_001`. No second `allocate`; `allocated` stays 2. (Invariant 5.)
5. **Confirm (buyer A).** `confirm_reservation(rsv_001, actor_ref="checkout_svc", credential=<…>, idempotency_token=tok_a2) → ok`. `Provisional Commitment.confirm(rsv_001)` → Confirmed (within window); the slot is *kept* — no pool `release`. `allocated` stays 2. (Confirmed consumes the unit.)
6. **Expiry (buyer B lets the hold lapse).** Ten minutes pass; the sweep fires `expire_reservation(rsv_002, actor_ref="sweeper", credential=<sweeper>, idempotency_token=tok_sweep_b) → ok`. `Provisional Commitment.expire(rsv_002)` → Expired; `Capacity Constraint.release(pool_vip, 1, ...)` → `allocated: 2 → 1`; `release = released(…)`; Event Log records [Expire Reservation]. The slot is returned exactly once. (Invariants 1, 2.)
7. **Reserve (buyer C, retry with a fresh token).** Now `reserve(pool_vip, ..., requester="buyer_c", idempotency_token=tok_c2)` → `allocate` → `allocated: 1 → 2` → `rsv_003` Held. Buyer C gets the slot buyer B let lapse. The pool count tracked the truth throughout.

### Cancellation returns the slot

Buyer A cancels before confirming (in a variant where rsv_001 is still Held): `cancel_reservation(rsv_001, ..., idempotency_token=tok_cancel_a) → ok`. `Provisional Commitment.release(rsv_001)` → Released; `Capacity Constraint.release(pool_vip, 1, ...)` → `allocated` decrements; `release = released(…)`. The slot returns to the pool in order with the cancellation. (Invariants 1, 2.)

### Partial-reserve compensation

A [Reserve] allocates a slot (`allocated: 1 → 2`) but `Provisional Commitment.place_hold` then returns resource-unavailable (the specific resource was taken between the capacity gate and the hold). The composition compensates: `Capacity Constraint.release(pool_vip, 1, ...)` → `allocated: 2 → 1`, returning the slot the unsuccessful reserve took, and returns `rejected(resource-unavailable)` to the caller (cached against the token). Coherence is preserved across the failed reserve — the slot is not leaked. (Action wiring 57 through 61.)

### Rejection path — confirming a lapsed hold

A buyer's checkout stalls; by the time `confirm_reservation(rsv_002, ...)` arrives, `rsv_002`'s 10-minute window has elapsed. `Provisional Commitment.confirm(rsv_002)` → window-elapsed → `rejected(window-elapsed)`. The reservation is not confirmed; its slot is the expiry sweeper's to return. The buyer must reserve afresh. (Invariant 4 — no confirmation of a lapsed hold; this is the confirm/expire race resolved in the pool's favor.)

### Regulated adversarial scenarios

**Regulator/operator audit — "prove you never oversold the pool."** An auditor reads the pool's `query(pool_id).allocated` and the Event Log and confirms that at no point did the count of Confirmed reservations exceed `capacity` (Invariant 3), and that `allocated` at every event equals the live-reservation set reconstructed from the Event Log (Invariant 1). The pool event balances on every in-line reservation entry — the opening and closing balances copied from the pool's own events, whose ids the entries cite — make the arithmetic chain replayable against the pool's audit log (Check 7.1); a state in which Confirmed reservations outnumber `capacity`, or `allocated` diverges from the live set, is a conformance failure. The auditor consults no source code — the pool count and the journal are sufficient.

**Disputed double-booking — two customers claim the same unit.** An investigator inspects the Event Log for the pool: every [Reserve] carries the allocation event id and the pool event balances; every terminal action carries the `release_event_id`. If two Confirmed reservations exist against a 1-capacity pool, either `capacity` was raised by an `adjust_capacity` (an overbooking choice the pool's audit log records) or coherence was violated — and the Event Log shows which. Idempotency (Invariant 5) forecloses the retry-induced double-reserve; the dispute resolves to a recorded `adjust_capacity`, a client token-discipline failure, or a genuine finding, each distinguishable from the records.

**Inventory-leak forensics — "free count is wrong; find the stranded slot."** An operator observes `allocated` higher than the visible live reservations. The investigator replays the Event Log: every [Reserve] (slot taken) must have either a matching terminal [Cancel Reservation]/[Expire Reservation] (slot returned, `release = released(…)`) or a live Held/Confirmed reservation — and every pool allocation with no [Reserve] entry at all must have its reserve_compensated entry (the journaled compensation of a partial reserve; an allocation with neither is the finding). A reservation in a **slot-returning** terminal state (Released or Expired — not Confirmed, which keeps its slot) whose return is unjournaled and whose pool count shows the slot still held is the stranded slot — a leak whose precise reservation and pool the records name; a Released or Expired record with no binding entry at all is a compensated step-7 reserve, named by its reserve_compensated entry, and holds nothing. Invariant 2 (slot returned at most once) and Invariant 6 (every change journaled) are what make the leak locatable rather than a mystery in an aggregate counter.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the reservation-to-pool binding and the token results map plus the Provisional Commitment, Capacity Constraint Enforcement, Duplicate Prevention, Event Log and Actor Identity instances, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST count a pool's slot-holding reservations by traversing the journal's reserve outcome entries for the pool (Invariant 1.1).
Check 1.2: An auditor MUST resolve EVERY traversed reservation id through the binding as a keyed lookup, rebuilding on a miss (Composition state 10).
Check 1.3: An auditor MUST NOT count binding entries in place of the traversal (Invariant 1.1).
Check 1.4: An auditor MUST report a divergence the rebuild closes as an index gap (Composition state 10).
Check 1.5: An auditor MUST report a divergence the accounted divergence explains as an open recovery obligation (Invariant 1.2).
Check 1.6: An auditor MUST report a divergence the accounted divergence does not explain as a coherence finding (Invariant 1.2).
Check 1.7: An auditor MUST NOT count a reserve intent standing behind no allocation event toward the accounted divergence (Invariant 1.3).
Check 2.1: An auditor MUST find a pool's Confirmed reservations not exceeding the pool's allocated at quiescence (Invariant 3.1).
Check 2.2: An auditor MUST take a pool's allocated not exceeding the pool's capacity from Capacity Constraint Enforcement's own acceptance (Composes 5).
Check 3.1: An auditor MUST NOT find two slot-returning outcome entries naming one reservation (Invariant 2.1).
Check 3.2: An auditor MUST find a landed return's release marker reading released carrying the outcome entry's release reading (Composition state 12).
Check 3.3: An auditor MUST read an open return as a return owed, not as a stranded slot (Reconciliation 16).
Check 3.4: An auditor MUST report an open return as a finding ONLY IF no recovery intent names the open return WITHIN the compensation window (Invariant 1.4).
Check 3.5: An auditor MUST report an overdue partial's slot as stranded ONLY IF the pool's allocated counts the slot (Invariant 2.1).
Check 3.6: An auditor MUST read a reservation in a slot-returning state named by no binding entry AND named by a compensation entry as a compensated hold (Composition state 5).
Check 3.7: An auditor MUST find a compensation entry naming EVERY allocation event that no reserve outcome entry names (Invariant 1.4).
Check 3.8: An auditor MUST NOT report a Confirmed reservation whose release marker reads none (Wiring decision 3).
Check 4.1: An auditor MUST read a Confirmed reservation's in-window admission from the Provisional Commitment record (Invariant 4.1).
Check 4.2: An auditor MUST NOT report a skew between a confirm outcome entry's now AND the hold's expiry instant (Capability requirement 42).
Check 5.1: An auditor MUST find EVERY idempotency token inside the idempotency window bound to one answer (Invariant 5.1).
Check 5.2: An auditor MUST find no two reservations sharing one idempotency token (Invariant 5.2).
Check 5.3: An auditor MUST report a window miss traceable to a violated obligation against the obligation (Invariant 5.4).
Check 6.1: An auditor MUST call Actor Identity's verify on EVERY outcome entry's attestation id (Invariant 6.2).
Check 6.2: An auditor MUST recompose the action reference from the entry's own action AND idempotency token (Invariant 8.2).
Check 6.3: An auditor MUST read verified against the recomposed action reference as the passing answer (Invariant 6.2).
Check 6.4: An auditor MUST re-run a verification answering a registry condition (Capability requirement 37).
Check 6.5: An auditor MUST report an attestation verifying against another action reference as a conformance failure (Invariant 8.2).
Check 6.6: An auditor MUST report an outcome entry carrying no attestation id as a conformance failure (Invariant 6.2).
Check 6.7: An auditor MUST report an attestation id Actor Identity answers not-known for as a conformance failure (Invariant 6.2).
Check 6.8: An auditor MUST find the intent entry carrying an outcome entry's attestation id earlier in sequence order than the outcome entry (Invariant 6.3).
Check 6.9: An auditor MUST NOT report an intent entry carrying no outcome entry as a failure (Invariant 6.1).
Check 7.1: An auditor MUST chain ONLY in-line outcome entries citing a pool event (Action wiring 64).
Check 7.2: An auditor MUST find EVERY chained entry's pool event balances equal to the cited pool event's (Action wiring 64).
```

NOTE: EVERY check names the rule the check tests.

Term registry condition: actor-unknown-in-registry | registry-unavailable — a verification answer that is the registry's state, not the composition's conformance.

WHY:
**Count from the journal, reconciled against the binding — never by counting the index** (Check 1.1 through 1.7). The binding is a derived index, and counting its entries is not a keyed lookup, so rebuild on a miss — which repairs a gap precisely because a lookup that finds nothing is observable — cannot fire. A lost entry would make the count come up short and report allocated as exceeding the reservations that justify it: **an allocation-coherence violation that is not there**, and the one remediation it invites — reconciling allocated down — would release genuinely held slots and over-allocate the pool. A check that misdiagnoses an index gap as a violation is worse than one that stays silent, because it recruits the auditor into the corruption — the trap [Audit Trail](./audit-trail.md) names from the other side. A divergence that survives the rebuild is a finding only where it survives the windows too, and the windows are keyed on the pool's allocation events: an allocation event no reserve outcome and no compensation names accounts for one slot while it stands, as does an open return; a reserve intent with no allocation event behind it accounts for **zero**. The traversal reads payloads, so past the audit horizon it degrades to whatever the index still holds — a bound to state, not a reason to count the index instead.

**No oversell is read without interleaving two logs** (Check 2.1 and 2.2). The journal and the pool's audit log share no order, and a check that replayed one against the other would have to invent one. At quiescence every Confirmed reservation is a bound slot-holding reservation, so the Confirmed count never exceeds allocated (Invariant 1.1), and allocated never exceeding capacity is the pool's own check over its own audit log, which walks each allocation event's snapshot against the capacity in effect at that index. The historical claim rests on the two, each read in its own order.

**Two senses of *terminal*** (Check 3.1 through 3.8). The pool keeps no per-allocation identity, so *at most once* is counted over the journal's slot-returning outcome entries, never over the pool's release events. A Confirmed reservation is constituent-terminal and holds its slot, so a check written over the constituent's terminal set would convict every confirmed booking. A Released or Expired commitment named by no binding entry is a compensated hold, named by its compensation entry, and holds nothing.

**Window admission is the constituent's, and the journal only corroborates** (Check 4.1 and 4.2). Provisional Commitment enforces confirmation within the window at the transition, so the check is a read of the commitment record. The journal's stamp against the expiry instant is two seams' readings, and a small skew between them is a clock artifact, not a finding.

**Attribution is witnessed, and its limit is stated** (Check 6.1 through 6.9). The two registry conditions are not composition failures: actor-unknown-in-registry is what a key rotation looks like where the registry keeps no historical material, registry-unavailable is an outage, and both are run again. An attestation verifying against a *different* action reference is the sharpest finding, because it is what a category-wide reference would produce. **The records order the attestation against the journal entries, not against the constituent commits**, which live in stores sharing no order with the journal — and the cross-seam stamp comparison that would supply one is forbidden (Capability requirement 42). An implementation that allocated, then attested, then wrote both entries would produce byte-identical records. What the checks witness is the per-invocation credential presentation; Invariant 8's order rests on the declared wiring, defended in line, not claimed from the records.

**The replay chain links only what the pool itself stamped** (Check 7.1 and 7.2). An in-line outcome entry citing a pool event carries that event's own balances. A confirm outcome entry carries a witness, not a link; a recovery outcome entry may carry unknown as its release reading, and where several returns were open at once its attribution among them is presumptive — so neither is chained.

### External checks

```
External check 1: An auditor needing whether a pool's capacity reflects the physical unit count MUST read the pool's declaration AND adjustment history (Capability requirement 2).
External check 2: An auditor needing the resource-availability determination confirmed MUST read Provisional Commitment's registry (Non-goal 1).
External check 3: An auditor needing the liveness sum confirmed MUST read the deployment's configuration over all three terms (Capability requirement 9).
External check 4: An auditor needing the exclusions confirmed MUST read the deployment's own host (Capability requirement 20).
External check 5: An auditor needing the journal's durability confirmed MUST read the deployment's own store configuration (Capability requirement 12).
External check 6: An auditor needing Duplicate Prevention's obligations confirmed MUST read the deployment's own configuration (Capability requirement 34).
External check 7: An auditor needing the actor registry's historical material confirmed MUST read the registry (Capability requirement 37).
External check 8: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 9: An auditor needing the idempotency window confirmed MUST read the deployment's own configuration (Capability requirement 1).
External check 10: An auditor needing the token max length confirmed MUST read the deployment's own configuration (Capability requirement 27).
External check 11: An auditor needing the digest function confirmed MUST read the deployment's own configuration (Capability requirement 28).
```

WHY:
External check 3 is confirmed over all three terms and never over the cadence alone (Capability requirement 9). The exclusions, the durabilities and the registry are operating facts, not records; an auditor who cleared the record checks and stopped would report guarantees for a deployment that declares none of the capabilities they rest on.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT decide whether a specific resource is bookable.
Non-goal 2: The composition MUST NOT model overbooking.
Non-goal 3: A deployment overbooking a pool MUST declare the pool's capacity above the physical unit count.
Non-goal 4: The composition MUST NOT seal a journal entry.
Non-goal 5: A deployment needing sealed reservation events MUST compose Audit Trail as a peer.
Non-goal 6: The composition MUST NOT schedule the expiry sweep.
Non-goal 7: The composition MUST NOT cancel a Confirmed reservation.
Non-goal 8: A deployment needing a Confirmed reservation undone MUST compose Reversal.
Non-goal 9: The composition MUST hold EXACTLY ONE slot per reservation.
Non-goal 10: The composition MUST NOT gate a reservation on authorization.
Non-goal 11: A deployment needing an authorized reservation MUST compose Permissions.
Non-goal 12: The composition MUST NOT record who replayed an idempotency token.
Non-goal 13: The composition MUST NOT authenticate a replay.
Non-goal 14: The composition MUST NOT journal a pre-attest refusal.
Non-goal 15: A deployment needing attempt-level visibility MUST compose Event Log around the call surface.
Non-goal 16: The composition MUST NOT own a downstream surface.
```

Term pre-attest refusal: a refusal answered ahead of the attestation — a malformed input, a token collision, a replay.

Term downstream surface: pricing, waitlisting or fulfilment of a reservation.

WHY:
**Two gates, independent** (Non-goal 1). Whether seat 14C or room 307 is bookable belongs to Provisional Commitment's registry, upstream of and distinct from the pool's *count*; a pool with free capacity can still refuse a [Reserve] for a specific unavailable resource, surfaced as resource-unavailable.

**Overbooking is a capacity choice** (Non-goal 2 and 3). An airline selling 110 seats against 100 declares the pool's capacity at 110; the composition enforces allocated against whatever capacity is declared and never itself admits allocated above it. How much to oversell, and what to do with the overflow at fulfilment, is upstream.

**No seal at this layer** (Non-goal 4 and 5). The journal is durable and attributed, not cryptographically sealed. A deployment whose reservation events are litigation-exposed composes [Audit Trail](./audit-trail.md) — Event Log, Actor Identity, Retention Window and Tamper Evidence — in place of the bare pairing; the wiring is identical, with record_action replacing the direct append. The lighter pairing is the default because reservation systems are high-throughput and most need no per-event seal.

**Un-booking is a separate lifecycle** (Non-goal 7 and 8). [Cancel Reservation] resolves a Held reservation; reversing a firm booking — a refund, a slot re-opened — is a Reversal pattern's, which produces a compensating action and, where the slot should re-open, a pool release.

**One slot per reservation** (Non-goal 9). A group booking of N units is a composing extension that allocates N and tracks N in the binding; the single unit is the primitive.

**Attestation is not authorization** (Non-goal 10 and 11): whether this actor was entitled to take or release a slot is not gated here.

**A replay is a bearer answer** (Non-goal 12 and 13). A replay commits nothing and writes nothing, so it records no retrier and checks no credential: within the window the token is a bearer secret, and a deployment treating it as a credential breaks it. Invariant 8 is about commitment and is untouched.

**Attempt visibility is partial, and the page says which part** (Non-goal 14 and 15). Every authenticated invocation writes an intent before the guards that refuse it, so a capacity refusal or a window-elapsed leaves a durable intent with no outcome beside it — what makes an authenticated attempt distinguishable from none, and what Check 6.9 reads. Two consequences are stated rather than discovered: a retrying caller against a full pool writes one permanent entry per attempt into a log this composition composes with no Retention Window; and refusals before the attestation — a malformed input, a token collision, a replay — append nothing, though a settled answer is replayable. A regulator asking how many over-capacity refusals a pool emitted in a window is answered by an Event Log composed around the call surface at the deployment's grain, recording against this page's named refusals — the same records-witness-successful-changes boundary Capacity Constraint Enforcement declares at its own layer.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A deployment MUST own the honesty AND the monotonicity of the injected now.
Clock semantics 2: A deployment needing a verifiable wall-time anchor MUST compose Trusted Timestamping.
Clock semantics 3: IF no Trusted Timestamping anchor EXISTS THEN the composition MUST read Event Log insertion order as authoritative.
```

WHY:
The hold window is not this composition's to keep: the expiry instant, the window rejections and the sweep's timing are inherited from Provisional Commitment's clock, evaluated at that constituent's seam, and not restated here as a competing rule (Capability requirement 45). What remains a deployment matter is clock *quality* — the honesty of the reading, its monotonicity, and the skew between this seam and the constituents'. The skew is why order never rests on comparing stamps. Where reservation timestamps have legal or settlement force, Trusted Timestamping supplies the verifiable anchor; absent it, insertion order is authoritative. The residual risk under seam injection is a deployment injecting a dishonest now, not an internal race.

### Concurrency

```
Concurrency 1: The composition MUST rest a race between two resolving actions on one reservation on Provisional Commitment's single resolution.
Concurrency 2: A resolving action whose transition answers not-held MUST NOT write the pending marker.
Concurrency 3: The composition MUST rest concurrent allocates against one pool on Capacity Constraint Enforcement's per-call serialization.
Concurrency 4: The composition MUST NOT serialize a single pool call of the composition's own.
```

WHY:
A [Cancel Reservation] racing an [Expire Reservation], or a [Confirm Reservation] racing the sweep, resolves under Provisional Commitment's single resolution: the first terminal transition wins, the second meets not-held, and only one pool release fires — the loser transitions nothing and reaches neither the pending marker nor the pool call, and a return the reconciliation already landed is adopted at the pre-check, never repeated. Concurrent allocates are serialized per call by the pool's own obligation, and the composition relies on it for the call. What the pool does not grant is a exclusion spanning several calls, so the three exclusions this page needs are the deployment's (Capability requirement 20 through 26): per token, per reservation and per pool, with the reconciliation taking the pool exclusion for its arithmetic and the reservation exclusion for each completion, so a reconciliation and a live invocation never act on one pool's count or one reservation's return at once.

### Expiry sweep

```
Expiry sweep 1: An expiry sweep MUST call [Expire Reservation] for a reservation whose window reading EQUALS lapsed.
Expiry sweep 2: An expiry sweep MUST read not-known from [Expire Reservation] as an orphan hold the reconciliation resolves.
Expiry sweep 3: An expiry sweep MUST NOT retry an [Expire Reservation] answering not-known.
Expiry sweep 4: A deployment needing a tight free count MUST declare the eager expiry sweep.
```

WHY:
The composition holds the binding and exposes [Expire Reservation], but it is not the scheduling engine (Non-goal 6). An external sweep reads holds whose expiry instant has passed — on a timer, or on the next observation — and calls the action. Until it fires, a lapsed hold is still Held and its slot still allocated, so allocated may transiently count it: the eager-versus-lazy gap inherited from Provisional Commitment, during which [Confirm Reservation]'s window-elapsed keeps the lapsed hold from being confirmed. **The sweep also meets holds it cannot expire** (Expiry sweep 2 and 3): an orphan hold [Reserve] placed and never journaled is Held in the store the sweep reads and has no binding entry, so [Expire Reservation] answers not-known. That answer is expected, not a fault; the reconciliation's partial leg is the branch that drives the hold terminal and returns the slot (Reconciliation 30 and 31).

---

## Composition notes

These are adjacent compositions, **not** constituents of this composition:

- **[Idempotent Reservation](./idempotent-reservation.md)** — the precursor: Provisional Commitment and Duplicate Prevention, the idempotency surface without pool arithmetic. This composition is its pool-aware superset; a deployment that needs retry-safe holds but no bounded pool uses Idempotent Reservation directly.
- **[Audit Trail](./audit-trail.md)** (substrate, peer) — a deployment whose reservation events require tamper-evident seals composes Audit Trail in place of the bare Event Log and Actor Identity pairing (Non-goal 4 and 5).
- **Reversal** *(forthcoming)* — produces a compensating action that un-books a Confirmed reservation and, where the slot should re-open, returns it to the pool. This composition deliberately excludes un-booking a firm reservation; Reversal is the composing pattern that adds it.
- **Trusted Timestamping** *(forthcoming)* — binds Event Log insertion order to verifiable wall-time where reservation or settlement timestamps have legal force.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four state-changing actions it exposes and the read-only query, the binding's release marker whose released value makes a slot return exactly once, the per-invocation action reference, the parameters digest it keys retries by, and its own pool refusals. Allocation coherence itself (Invariant 1) is a structural property, not a datum. The deployment settings keep their wire spellings in configuration — `idempotency_window`, `expiry_sweep`, `application_actor_ref`, `application_credential`, `reservation_completion_bound`, `compensation_window`, `reconciliation_cadence`, `recovery_write_latency`, `outcome_retry_attempts`, `recovery_candidates_cap`, `journal_durability`, `journal_query_shape`, `pool_event_read`, `host_exclusion`, `journal_retention_ordering`, `index_durability`, `token_max_length`, `digest_function` — and the two maps theirs in an implementation, `reservation_to_pool` and `token_results`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the transition; the reconciliation; a deployment; an auditor; a caller; an operator; an investigator; an invocation; an action; a state-changing action; a resolving action; a slot-returning action; a read-only query; a replay; a writer; an expiry sweep; the rebuild; a reservation; a hold; an orphan hold; a compensated hold; a pool; a slot; a binding entry; a token results entry; an intent entry; an outcome entry; a compensation entry; a recovery intent; a recovery outcome entry; a late outcome entry; the service identity.

Term records: the intent entries, outcome entries, compensation entries and reconciliation entries the composition appends to the journal — each an Event Log event carrying one action below — and the binding and token results entries.

Term record verbs: acknowledge, address, alert, allocate, answer, attest, authenticate, bind, call, cancel, carry, chain, change, close, commit, compare, compensate, compose, compute, configure, confirm, copy, count, decide, declare, derive, disclose, drive, enlist, enter, escalate, evict, examine, find, gate, hold, inherit, inject, journal, key, leave, make, mint, model, name, normalize, order, own, pair, place, re-run, reach, read, rebuild, recompose, record, release, remove, report, resolve, rest, retain, retry, run, schedule, seal, serialize, serve, set, settle, skip, stamp, start, store, supply, take, test, validate, verify, write.

Term value sets: action = reserve_intended | reserve | reserve_compensated | confirm_intended | confirm_reservation | cancel_intended | cancel_reservation | expire_intended | expire_reservation | recovery_intended. The rest are declared where the section that owns each declares it: release marker, release reading, action type, position, stage, hold resolution, slot-holding state, slot-returning state, constituent-terminal state, expiry sweep.

Term bounds: reservation completion bound (reservation_completion_bound), compensation window (compensation_window), audit horizon (journal_retention_ordering), token max length (token_max_length), recovery candidates cap (recovery_candidates_cap), outcome retry attempts (outcome_retry_attempts), idempotency window (idempotency_window).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, reservation, reservation id, journal, journal entry, reservation-to-pool binding, binding entry, release marker, release reading, compensated hold, matching intent, aged entry, token results map, action type, parameters digest, business parameter, idempotency window, expiry sweep, service identity, reservation completion bound, compensation window, reconciliation cadence, recovery write latency, liveness sum, outcome retry attempts, recovery candidates cap, pool event read, exclusion, token exclusion, reservation exclusion, pool exclusion, token max length, digest function, audit horizon, retention floor, longest reservation lifetime, coherence proof period, seam, now, envelope, position, stage, reservation reading, slot-held reading, state-changing action, resolving action, slot-returning action, settling, replay, matching token results entry, action reference, journaled digest, intent entry, outcome entry, slot-returning outcome entry, resolving entry, late outcome entry, recovery flag, recorded rejection, hold resolution, hold compensation, compensating release, compensation write, later write, admitted reserve, post-commit write, pool event balances, witness balance, pre-check, pending marker, released marker, terminal state, slot-holding state, slot-returning state, constituent-terminal state, reconciliation, examinable entry, recovery intent, recovery outcome entry, recovery action reference, bound slot-holding count, open partial, open return, open return count, expected count, open partial count, justified count, unlanded return count, release candidates, intent candidates, orphan hold, deferred reserve token, unjournaled confirmation, overdue partial, quiescence, divergence, accounted divergence, registry condition, pre-attest refusal, downstream surface, reserve intent, reserve outcome entry, compensation entry, confirm intent, confirm outcome entry, cancel intent, cancel outcome entry, expire intent, expire outcome entry.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Composition state in `execution-contract.md` — the derived-index, truth-bearing and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. commitment id, place hold, confirm, release, expire, resource, requester, duration, window reading, open, lapsed, Held, Confirmed, Released, Expired, not-held, window-elapsed, window-not-elapsed, resource-unavailable: Provisional Commitment. pool id, capacity, allocated, allocate, declare pool, query, audit log, audit event, allocation event, release event, allocation event id, release event id, opening balance, closing balance, over-capacity, over-release, suspended, closed: Capacity Constraint Enforcement. check, record, seen, not-seen: Duplicate Prevention. append, event id, sequence number, recording instant, payload cap, invalid-payload: Event Log. attest, verify, attestation id, actor reference, credential, actor registry, invalid-credential, actor-unknown-in-registry, registry-unavailable: Actor Identity.

Term composing patterns: [Idempotent Reservation](./idempotent-reservation.md); [Audit Trail](./audit-trail.md); Reversal *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Outbox *(forthcoming)*; Erasure Tombstone *(forthcoming)*; [Permissions](../atoms/permissions.md).

Term reserve intent: the reserve_intended entry.

Term reserve outcome entry: the reserve entry — the [Reserve] outcome.

Term compensation entry: the reserve_compensated entry — the record of a partial [Reserve]'s returned slot, written in line or by the reconciliation.

Term confirm intent: the confirm_intended entry.

Term confirm outcome entry: the confirm_reservation entry — the [Confirm Reservation] outcome.

Term cancel intent: the cancel_intended entry.

Term cancel outcome entry: the cancel_reservation entry — the [Cancel Reservation] outcome.

Term expire intent: the expire_intended entry.

Term expire outcome entry: the expire_reservation entry — the [Expire Reservation] outcome.

#### Reserve

The composition's core action: it takes one slot of a pool and opens a provisional hold bound to it — the capacity gate and the hold are bound, so the slot is allocated only if the hold is taken, with a compensating release if the hold fails (Action wiring 45 through 79). Answers the reservation id, [Pool Closed], [Pool Capacity Exceeded] or a relayed refusal. Idempotent under retry.

Kind: Operation

#### Confirm Reservation

The action that confirms a held reservation into a firm booking. **The slot is not released** — a Confirmed reservation keeps its unit, so allocated is unchanged. Answers window-elapsed for a lapsed hold, the *no confirmation of a lapsed hold* guarantee (Invariant 4).

Kind: Operation

#### Cancel Reservation

The action that cancels a held reservation and **returns its slot to the pool, in order, exactly once** — Provisional Commitment's release, the pending marker, the pool release, [Slot Released], the outcome entry — with the reconciliation resolving any crash between them by the pool's own count (Invariant 1 and 2).

Kind: Operation

#### Expire Reservation

The action an expiry sweep calls on a held reservation whose window has lapsed: it drives Provisional Commitment's expire and returns the slot in the same order and under the same exactly-once discipline as [Cancel Reservation], differing only in the transition and the window-not-elapsed guard.

Kind: Operation

#### Query Reservation

The read-only query answering a reservation's state, its pool and whether it holds a slot now (Action wiring 114 through 118). Writes no journal entry.

Kind: Operation

#### Slot Released

The released value of a binding entry's release marker, written when the pool release answers — after the pending value, written before the pool is touched. With the reconciliation's arithmetic it is what makes a slot return **at most once** (Invariant 2): the reconciliation never releases for a reservation the marker or the journal shows returned, and otherwise releases exactly the pool's unlanded returns.

Kind:       Field
Field of:   the binding entry
Role:       the slot-return-once guard
Projection: release

#### Action Reference

The per-invocation reference an attestation binds to: the action type and the idempotency token joined by a colon, `reserve:tok_a1`. Actor Identity verifies a proof against its recorded action reference, so a reference shared by every act of a kind would make every such attestation substitutable; this one binds the proof to one act, and an auditor recomposes it from the entry's own fields (Check 6.2).

Kind:       Field
Field of:   the attestation
Role:       the act the proof binds to
Projection: action_ref

#### Parameters Digest

The collision-resistant digest of a call's business parameters, computed at the seam by the digest function and injected — never the actor reference, never the credential, so a retry presenting freshly minted credential material still matches and no secret persists in digest form (Composition state 19 through 21).

Kind:       Field
Field of:   the token results entry
Role:       the retry key's parameter check
Projection: parameters_digest

#### Pool Closed

The composition's own refusal from [Reserve] when the pool is Closed or Suspended to new reservations. It maps Capacity Constraint Enforcement's closed and suspended allocate refusals to one code — a deliberate collapse that discards the retry-once-resumed signal suspended carries; a caller needing the distinction reads the pool's own query, and this boundary reports only that no new reservation is admitted now.

Kind:       Member
Member of:  the reserve refusal
Role:       Rejection
Projection: pool-closed

#### Pool Capacity Exceeded

The composition's own refusal from [Reserve] when the pool is full: Capacity Constraint Enforcement's allocate refuses past capacity. The observable form of the *no oversell* guarantee (Invariant 3) at the capacity gate.

Kind:       Member
Member of:  the reserve refusal
Role:       Rejection
Projection: pool-capacity-exceeded

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Reserve]: #reserve
[Confirm Reservation]: #confirm-reservation
[Cancel Reservation]: #cancel-reservation
[Expire Reservation]: #expire-reservation
[Query Reservation]: #query-reservation
[Slot Released]: #slot-released
[Action Reference]: #action-reference
[Parameters Digest]: #parameters-digest
[Pool Closed]: #pool-closed
[Pool Capacity Exceeded]: #pool-capacity-exceeded

---


## Standards references

- **ISO (International Organization for Standardization) 9001 §8.5.2 / §8.5.4 (identification, traceability, preservation of outputs)** — the reservation lifecycle's traceable per-unit arc inherits from Provisional Commitment.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 10 (logging and monitoring)** — the Event Log journal plus Actor Identity attribution on every reservation event produce the audit evidence for payment-adjacent holds (credit-limit and authorization holds are Provisional Commitments against a credit pool).
- **IATA (International Air Transport Association) Resolution 830a / NDC (New Distribution Capability — IATA's airline retailing standard) (airline reservation and distribution)** — seat-inventory holds against a bounded cabin are the canonical Reserve from Pool case: a pool per cabin class, a hold per booking, confirm/cancel/expire returning inventory.
- **Joint Commission care-coordination standards** — hospital bed and resource allocation as a bounded pool with attributed, journaled holds; the no-oversell guarantee is the patient-safety form of allocation coherence.
- **GS1 (the global supply-chain standards organization) / supply-chain inventory-reservation conventions** — warehouse unit reservation against available-to-promise pools; allocation coherence is the available-to-promise accuracy guarantee.
- **IETF (Internet Engineering Task Force) draft-ietf-httpapi-idempotency-key-header; ISO 20022 (the financial-industry messaging standard) message uniqueness** — the idempotency surface inherited from the Idempotent Reservation precursor.

The five constituents carry their own deep standards inheritance — see each constituent's Standards references.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — reserve-from-pool.tla + 1 twin verified 2026-06-04 over the retired atomic trio; re-derive over the ordered slot-returning pair and the pool reconciliation (2026-08-29-a)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 6 foundational corrected in-round, 6 refining and 1 rhetorical routed (5 refining and 3 rhetorical also corrected in-round; closure check's 4 residues corrected in-round); 2026-08-26 authentication-precedence gate — 3 foundational routed (all since closed), 4 foundational and 8 refining/rhetorical corrected in-round, 9 refining routed (3 since closed); Final Critique 8's 7 refining and 3 rhetorical also routed

open:
- 2026-08-29-a · refining · formal · the model verifies the retired atomic trio; re-derive over the ordered pair with the `release` marker and the pool reconciliation leg, the twin being the transactional wiring → extend the model
- 2026-08-30-l · refining · formal · the model has no invocation and sweep as two processes over one act with `outcome_retry_attempts` as the point one stops writing, no allocation-event keying of the windows, and no step-2 journal read on the retry → extend it (with 2026-08-29-a)
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/reserve-from-pool.md`.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty of twenty-two open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, the prose's *Cross-store consistency under partial failure* becoming the reconciliation it described; invariant numbers 1 through 6 and 8 unchanged, Invariant 7 tombstoned to Composes 5; the checks renumbered `Check 1.1` through `Check 7.2`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency` and `Expiry sweep` under the second; the host's mutual exclusion named an *exclusion*, since the grammar owns *section*; and the outcome entries' balances named for what Capacity Constraint Enforcement's events carry now, the opening and closing balance, where the prose still said *Allocated Before* and *Allocated After*. The lines' fixes: the replay declared a bearer answer that attests and journals nothing, since a replay commits nothing and Invariant 8 is about commitment (2026-08-26-e, 2026-08-30-e); Actor Identity's store durability inherited (2026-08-26-f); *bound cryptographically* replaced by Invariant 8's own mechanism-neutral words (2026-08-26-h); the fail-closed check landed as recording-failure carrying outcome, unsettled (2026-08-26-i); no oversell read at quiescence and from the pool's own acceptance, joining no two logs (2026-08-26-j); *attestation* glossed in the Summary (2026-08-26-k); an Action Reference term entry (2026-08-26-l); the digest's exclusion of the actor reference and the credential as rules (2026-08-26-o); validation pinned before the intent against each constituent's own field rules, uncached, the constituents' invalid-request settled after it (2026-08-26-r, 2026-08-30-f); the Terms preamble's count, the idempotency surface declared here rather than deferred, and the Customer Onboarding pointers removed (2026-08-26-t, u, v); the pool leg releasing never more than the open returns, an excess reported (2026-08-30-a); a release reading of unknown, rebuilt as such, and the recovery entries' balances outside the chain (2026-08-30-b); Provisional Commitment's not-known landed as a third position, inconsistency, settled and alerted (2026-08-30-g); the expiry sweep reading not-known as an orphan hold the reconciliation's partial leg resolves (2026-08-30-h); the seam glossed (2026-08-30-k). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The two formal lines stay open (2026-08-29-a, 2026-08-30-l). The rewrite also found the reconciliation's partial leg had no way to reach the orphan hold it was told to drive terminal — the hold is unjournaled — and gave it one: the Held commitments no binding names whose resource and requester match the open partial's intent (Reconciliation 30).
- **2026-08-30 — One writer per act, the windows keyed on the pool's own events, the retry reading the journal before it delegates, and the obligations the constituents decline declared as the deployment's.** *Chose:* a retry terminus, `outcome_retry_attempts`, after which every post-commit write is the sweep's, with the sweep's runs and the invocation serialized on the deployment's declared `host_exclusion` sections and every look-then-write pre-check re-read under them; the reconciliation's unjournaled-return set keyed per reservation — an intent enters only where no slot-returning outcome names the reservation and the terminal state is the one its action writes, outcome over intent on the rebuild — with one recovery entry per reservation and the rest as `intent_candidates`; Invariant 1's windows and check 1 keyed on allocation events of the pool's audit log, an unmatched `reserve_intended` explaining zero slots; [Reserve] step 2 reading the journal for its token on `not-seen` before it delegates — replay on an outcome, defer on a bare intent — and the sweep caching and recording the deferred tokens; `allocated_before` / `allocated_after` copied from the pool's own allocation or release event through `pool_event_read`, the three-call `query`-`allocate`-`query` section dropped; `journal_durability`, `journal_query_shape`, `pool_event_read` and `host_exclusion` declared as inherited obligations and instance capabilities; `recording-failure(intent | outcome)` and invalid-credential on every signature, the intent position uncached and the outcome position cached; the liveness inequality written out with `recovery_write_latency`; `journal_payload_cap` and `recovery_candidates_cap` sizing the largest record at step 1; and, from the closure check, `host_exclusion` as an instance capability with lease semantics — taken at the invocation's first write, exactly `reservation_completion_bound` long, its expiry the invocation's terminus, every later write made only under it — with the pool call of every action pre-checked under the sections and adopting a landed return or compensation (*proceed as landed*), the sweep taking a reservation's section before counting it, the three other actions reading the journal on `not-seen` as [Reserve] does, replay from a compensation populating no binding, and the tri-state `release` marker (`Projects: release`) written into every sentence that still spoke of a boolean or a trio. *Over:* "retry until it lands" beside a sweep starting at the bound; a leg that paired per reservation and wrote per intent; a divergence window keyed on an intent that had taken nothing; a `not-seen` treated as proof that nothing ran; a critical section, a durability and a query shape attributed to constituents whose own text declines them; a bare token on both sides of the commit; *cadence no longer than the window*; *foreclosed by construction*; a section named in no Configuration entry, with no lease and no terminus, under which a stalled invocation could wake between the sweep's pre-check and its append and release twice. *Because:* two compensators over one act land two outcomes and a second release; a refused cancel against a reservation another token returned is not a return begun; a refused intent never receives an outcome, so a window keyed on it never closes; a crash between the outcome and the `record` leaves a completed reservation the retry would duplicate; Capacity Constraint serializes each call and sends the rest to a Transaction composition, Event Log leaves persistence to the deployment, and a capability the constituent declines is the deployment's to declare or nobody's; a caller who cannot tell intent from outcome re-runs a committed act; and a section that is not a declared capability with a bound on its hold is either an undeclared dependency or an unbounded block on the sweep (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*Intents pair with outcomes*' third tell and §*Recovery commits under a declared service identity*'s re-entry tell; *Lawful destruction is answered before absence* and *A stamp from another seam never decides a write alone* were swept and found no shape here — no constituent answers `purged`, and no write rests on a cross-seam comparison).
- **2026-08-29 — The slot-returning pair is ordered and reconciled by the pool's count, not made atomic; the sweep is bounded and acts as the composition.** *Chose:* [Cancel Reservation] and [Expire Reservation] run transition → pending marker → pool release → `released(…)` marker → outcome entry, none inside a transaction; a pool reconciliation leg that, under the per-pool serialization, computes the pool's deficit from the journaled live set and releases exactly that many slots, naming candidates where several returns were open at once; every sweep leg bounded below by `reservation_completion_bound` and above by the journal horizon, run as a declared service identity behind recovery_intended; the [Reserve] compensation appended after its release rather than "in one host transaction"; the compensation's constituent arms partitioned; `journal_retention_ordering` and `index_durability` declared, the binding's purged half and the pending markers classified truth-bearing with their atoms named. *Over:* the terminal trio as "one atomic commit, a hard conformance requirement". *Because:* the transition is absorbing, the pool release is an append on the pool's own audit log, and the journal entry is an append — no store declares the rollback the trio required, and a journal entry rolled back after landing was a false record; the ambiguity the trio was meant to remove (a lost release versus a lost record of one) is resolved instead by the second source the stores do supply, the pool's own count against the journal (the frozen rules of 2026-08-29 — *Durability boundaries*, *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A derived index splits at the horizon*).
- **2026-08-27 — The confirm pair is completed by a late journal write, not made atomic and not compensated.** *Chose:* on a post-commit journal failure at [Confirm Reservation], return `recording-failure(post-commit)`, cache and record the token, and owe the outcome entry as a `recovery = true` write carrying the invocation's own attestation, detected from an unmatched confirm_intended against a Confirmed record. *Over:* extending the terminal trio's hard atomic-commit requirement to the pair. *Because:* the trio is atomic because a lost pool release and a lost record of one cannot be told apart; the confirm pair has no pool call and the constituent store answers the question directly, so a late write is safe and a transaction would buy nothing.
- **2026-08-25 — Invariant 5's at-most-once is conditioned on Duplicate Prevention's host obligations.** *Chose:* inherit the constituent's declared failure modes as named host obligations (durable, highly available recorded-set store; fail-closed `check`; `token_results` plus `record` durable before the result returns) and condition Invariant 5 and check 5 on them. *Over:* the unconditional at-most-once claim. *Because:* a silent window miss or a fail-open `check` lets a retried [Reserve] take a second slot, and an obligation-traceable miss is a deployment finding, not a coherence disproof.
- **2026-08-26 — Attribution is an `attest` call committed with the journal entry, keyed per invocation.** *Chose:* every state-changing action opens with `Actor Identity.attest(action_ref = "<action>:<idempotency_token>", …)` and carries the `attestation_id` on every journal schema; at the terminal trios the attestation stands outside and before the atomic trio. *Over:* attribution as prose ("attributed via Actor Identity") with a caller-supplied actor_ref. *Because:* the attribution guarantee was neither buildable nor witnessable as written, a shared `action_ref` would bind the proof to a category of act rather than the act, and an attestation inside the trio could not refuse the act it exists to gate.

NOTE: End of Reserve from Pool.

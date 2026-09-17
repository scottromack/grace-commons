---
title: Idempotent Reservation
parent: Conceptual Compositions
nav_order: 2
has_toc: true
toc: true
---

# Idempotent Reservation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Idempotent Reservation makes reservation actions safe to retry. It combines two simpler patterns: one that manages a held resource (Provisional Commitment — a resource held, then Confirmed, Released, or Expired) and one that spots repeated submissions within a set time window (Duplicate Prevention).

The problem it solves is everyday over unreliable networks: a client asks to hold a resource, the reply gets lost, the client retries — and without protection the retry creates a second, accidental hold.

The fix is a token the caller attaches to every action: if the same token has been seen within the window, the system returns the original result (same identifier, same outcome) instead of doing the action again.

The result is "exactly-once" behavior — the underlying reservation sees one real action no matter how many times it is retried, a token is locked to one specific operation (reusing it for something else is rejected), and so a single intended action can never become a double-hold. (Guarantees that appear only when patterns are combined are called emergent guarantees.)

This is the same mechanism every payment processor uses to stop a retried charge from billing twice, and it applies anywhere a duplicated action is a real defect — payments, hospital resource allocation, inventory reservation.

---

## Intent

Real reservation systems run over unreliable networks. A client submits [Place Hold]; the network drops the response before it arrives; the client retries. Without idempotency, the second call produces a *second* commitment — two distinct ids, two distinct audit trails, one unintended double-hold of the resource. The same hazard recurs for [Confirm], [Release], and [Expire]: a retry past Provisional Commitment's terminal-absorption boundary returns not-held, which the caller cannot distinguish from a *new* failure without out-of-band information.

This composition solves the problem at the composition layer rather than absorbing it into Provisional Commitment. The caller supplies an **idempotency_token** on every state-changing call. The composition checks the token against a [Duplicate Prevention](../atoms/duplicate-prevention.md) instance; if the token has been seen within the window (the configurable time period during which repeated tokens are detected and deduplicated), the composition returns the *original* response (the same commitment id, the same ok, the same rejection reason) without invoking [Provisional Commitment](../atoms/provisional-commitment.md) a second time — with one exception Invariant 2 states: a resolving action whose first invocation died before recording the constituent's answer is re-run, effect-free by the constituent's own single-resolution invariant. The constituent atoms are unchanged; the composition is the wiring.

This is the same composition that runs in every payment processor in production today — Stripe's `Idempotency-Key`, Adyen's idempotency header, ISO 20022's (the International Organization for Standardization standard for financial-messaging data) message uniqueness identifier, the IETF (Internet Engineering Task Force — the body that develops internet standards) draft idempotency-key spec. Different vocabularies; identical mechanic.

---

## Composes

- **[Provisional Commitment](../atoms/provisional-commitment.md)** — the hold lifecycle and the invariants every commitment satisfies.
- **[Duplicate Prevention](../atoms/duplicate-prevention.md)** — the time-bounded guard against a repeated token.

```
Composes 1: EXACTLY ONE Provisional Commitment instance MUST serve the composition.
Composes 2: EXACTLY ONE Duplicate Prevention instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST replace Provisional Commitment's own caller surface.
Composes 5: The composition MUST inherit a constituent's invariants PER the section titled Conformance in `execution-contract.md`.
Composes 6: The composition MUST answer a constituent's rejection unchanged.
Composes 7: The composition MUST call Duplicate Prevention's record EXACTLY ONE time per admitted first invocation.
Composes 8: The composition MUST configure the Duplicate Prevention instance with the idempotency window.
```

Term composition: this pattern's wiring of [Provisional Commitment](../atoms/provisional-commitment.md) and [Duplicate Prevention](../atoms/duplicate-prevention.md) — the token map, the four token-carrying actions and the eviction leg.

Term constituents: [Provisional Commitment](../atoms/provisional-commitment.md), [Duplicate Prevention](../atoms/duplicate-prevention.md).

WHY:
Composes 5 is one rule where the prose carried two. `Invariant 5` and `Invariant 6` each asserted a constituent's invariants hold over this composition's instance; [`execution-contract.md`](../execution-contract.md) §Conformance settles both by reference, so restating them was a citing spec restating a rule it cites (Authority 6, council read 53). What they carried beyond the blanket is Composes 6 — the relay of an unchanged constituent rejection, which no constituent guarantees about a caller — and Composes 7, the once-per-first-invocation `record` discipline, which is this composition's own call pattern and not a property of Duplicate Prevention.

Composes 4 is the enclosure every guarantee below rests on. A deployment exposing `ProvisionalCommitment.place_hold` beside [Place Hold] gives a caller a route that carries no token, and the exactly-once claim is a claim about the route through this composition alone.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a token results map.
Composition state 2: The composition MUST key the token results map by idempotency_token.
Composition state 3: An entry MUST carry an action type, a parameters digest, a result, a pending instant AND a completed instant.
Composition state 4: The composition MUST call Provisional Commitment ONLY AFTER writing the entry as pending.
Composition state 5: The composition MUST overwrite a pending entry in place with the constituent's answer.
Composition state 6: EXACTLY ONE invocation MUST write an entry per act.
Composition state 7: The composition MUST keep an entry's pending instant across the overwrite.
Composition state 8: The composition MUST NOT evict a pending entry whose invocation returned.
Composition state 9: The composition MUST take the parameters digest from the seam.
Composition state 10: The transition MUST NOT compute a parameters digest.
```

Term token results map: the composition's own map from an idempotency_token to a recorded outcome — a token results map; the element `execution-contract.md` §Composition state classifies extraction-pending.

Term action type: place_hold | confirm | release | expire.

Term parameters digest: the collision-resistant digest of a call's non-token parameters, computed at the seam by the configured digest function and injected — a [Parameters Digest].

Term pending entry: a token results entry carrying pending as the result — the record that an act may have happened.

Term complete entry: a token results entry carrying a recorded result and a completed instant.

WHY:
The map carries truth no replay reproduces. [Duplicate Prevention](../atoms/duplicate-prevention.md) answers *have I seen this identity* — membership, no payload — and does not act on a result, so *which result was returned for this token* is reconstructible from neither constituent store. Per `execution-contract.md` §Composition state that makes the element a not-yet-extracted atom, declared as recorded debt rather than normalized: **Classification: extraction-pending**, the proposed atom an *Idempotency Result Memo* (token → result, write-once, window-governed eviction), opened as a roadmap proposal. This is the corpus's first migrated composition carrying a non-derivable element, and the flag is what keeps the debt visible — an unflagged truth-bearing composition store is a conformance finding and a flagged one is scheduled debt.

Composition state 9 and Composition state 10 keep the digest out of core logic. A digest computed inside a transition is cryptography improvised where the Logic Confinement Principle forbids it; computed at the seam from parameters already present, it is an ordinary injected input.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the idempotency window.
Capability requirement 2: A deployment MUST set the token max length.
Capability requirement 3: A deployment MUST set the digest function.
Capability requirement 4: A deployment MUST set the digest function alike across EVERY instance sharing the token results map.
Capability requirement 5: The host MUST supply a critical section keyed by idempotency_token.
Capability requirement 6: The host MUST supply one critical section per token across EVERY instance sharing the token results map.
Capability requirement 7: The host MUST release a critical section on the holder's return.
Capability requirement 8: The host MUST release a critical section on the holder's death.
Capability requirement 9: A deployment MUST set the reservation completion bound.
Capability requirement 10: The reservation completion bound MUST NOT EXCEED the idempotency window.
Capability requirement 11: The composition MUST refuse to start for a reservation completion bound the idempotency window does not exceed.
Capability requirement 12: A deployment MUST hold the token results map durable across a restart.
Capability requirement 13: A deployment MUST hold an entry durable for the entry's durability term.
Capability requirement 14: A deployment MUST acknowledge a token results write ONLY AFTER the write is durable.
Capability requirement 15: A deployment MUST hold Duplicate Prevention's recorded set durable across a restart.
Capability requirement 16: A deployment MUST resolve Duplicate Prevention's check fail-closed.
Capability requirement 17: A deployment MUST declare whether the commitment store acknowledges atomically.
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token — an idempotency window.

Term durability term: the idempotency window and the reservation completion bound together, measured from an entry's pending instant — a durability term; the margin that keeps a lawfully recorded token off the seen-with-no-entry arm.

Term reservation completion bound: the longest an invocation may take between the invocation's first write and Duplicate Prevention's record — a reservation completion bound; also the critical section's lease length and the eviction leg's lower edge.

Term critical section: the host-supplied mutual exclusion keyed by idempotency_token; taken by every state-changing invocation before the invocation's first write.

WHY:
Capability requirement 5 is the one neither constituent grants. [Duplicate Prevention](../atoms/duplicate-prevention.md)'s `check` is read-only and its `record` is total; [Provisional Commitment](../atoms/provisional-commitment.md) serializes [Place Hold] per *resource* under its own host's guarantees, not per token. Without it the exactly-once claim is not made, which is why Invariant 8 names it as a condition rather than assuming it.

Capability requirement 15 and Capability requirement 16 are two obligations [Duplicate Prevention](../atoms/duplicate-prevention.md)'s own contract declines and this composition spends. The atom admits a volatile store and leaves the unavailable-store posture to the deployment; neither is available here, because fail-open would admit exactly the double Invariant 8 forbids. Fail-closed's cost is named rather than hidden: an unavailable store answers `seen`, and a token with no entry then lands outcome-unknown — a false rejection the caller retries under the same token.

Capability requirement 17 is the fork the composition cannot resolve. Where the deployment declares atomic acknowledgement, [Provisional Commitment](../atoms/provisional-commitment.md)'s storage-failure means what the atom says and is cached like any other rejection; where it cannot, the composition does not know whether the failed write landed and caches outcome-unknown in its place, never *nothing committed*.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank idempotency_token.
Primitive policy 2: The composition MUST answer invalid-request for an idempotency_token EXCEEDS the token max length.
Primitive policy 3: The composition MUST compare an idempotency_token byte-exact.
Primitive policy 4: The composition MUST NOT normalize an idempotency_token.
Primitive policy 5: The composition MUST NOT case-fold an idempotency_token.
Primitive policy 6: The composition MUST call Duplicate Prevention's check ONLY AFTER the idempotency_token clears the boundary predicate.
Primitive policy 7: The composition MUST NOT store an entry for a malformed idempotency_token.
```


WHY:
Primitive policy 7 is the first of the three things this composition does not cache, and the reason is the same each time: it did not act and holds no entry to cache against. A malformed token is not a token, so there is nothing to key an entry by.

Every other argument — resource, requester, duration, id — is [Provisional Commitment](../atoms/provisional-commitment.md)'s to validate, and its invalid-request flows through and is cached like any other constituent answer.

### Action wiring

```
place_hold(resource, requester, duration, idempotency_token)
  answers id
  refuses invalid-request | token-collision | resource-unavailable | storage-failure | outcome-unknown(candidates) | recording-failure(place hold position)

confirm(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure | outcome-unknown(candidates) | recording-failure(resolution position)

release(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure | outcome-unknown(candidates) | recording-failure(resolution position)

expire(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-not-elapsed | storage-failure | outcome-unknown(candidates) | recording-failure(resolution position)
```

Term place hold position: intent | `outcome(optional id)` — the record a [Place Hold] write lands: the intent, or the outcome carrying the id where one was issued.

Term resolution position: intent | `outcome(result)` — the record a resolving write lands: the intent, or the outcome carrying the result.

```
Action wiring 1: EVERY state-changing action MUST take an idempotency_token.
Action wiring 2: The composition MUST write ONLY AFTER taking the token's critical section.
Action wiring 3: The composition MUST read the token results map under the critical section.
Action wiring 4: The composition MUST call Duplicate Prevention's check under the critical section.
Action wiring 5: The composition MUST release a token's critical section on EVERY return.
Action wiring 6: The composition MUST NOT write on the strength of a pre-check the composition read under a lapsed critical section.
Action wiring 7: IF a complete entry's action type differs from the call's action type THEN the composition MUST answer token-collision.
Action wiring 8: IF a complete entry's parameters digest differs from the call's parameters digest THEN the composition MUST answer token-collision.
Action wiring 9: The composition MUST answer a matching complete entry's result.
Action wiring 10: The composition MUST NOT call a constituent for a matching complete entry.
Action wiring 11: IF Duplicate Prevention's check answers not-seen for a matching complete entry THEN the composition MUST call Duplicate Prevention's record.
Action wiring 12: The composition MUST evict a complete entry the idempotency window elapsed for AND Duplicate Prevention's check answers not-seen for.
Action wiring 13: The composition MUST write a pending entry for a fresh request.
Action wiring 14: IF the pending write fails THEN the composition MUST answer recording-failure naming the intent.
Deleted: Action wiring 15. Composition state 4 owns it.
Deleted: Action wiring 16. Composition state 5 owns it.
Action wiring 17: The composition MUST retry the result write WITHIN the reservation completion bound ONLY IF no result write EXISTS.
Action wiring 18: IF the reservation completion bound elapses THEN the composition MUST answer recording-failure naming the outcome.
Action wiring 19: A recording-failure naming the outcome MUST carry the constituent's answer.
Action wiring 20: The composition MUST call Duplicate Prevention's record ONLY AFTER the result lands.
Action wiring 21: The composition MUST answer Provisional Commitment's answer to the caller.
Action wiring 22: A read-only query MUST NOT take an idempotency_token.
Action wiring 23: A read-only query MUST NOT consult the token results map.
Action wiring 24: The composition MUST take an idempotency_token on EXACTLY ONE OF place_hold, confirm, release, expire.
```

Term fresh request: a call finding no entry AND Duplicate Prevention's check answering not-seen.

Term matching complete entry: a complete entry whose action type AND parameters digest equal the call's.

WHY:
Action wiring 2 through 6 are what make the look-then-write pre-check exact rather than racy. A second call carrying one token waits on the critical section and re-reads the map *under* it, so it finds the first call's entry instead of racing it; and a critical section found lost mid-invocation is the invocation's terminus, because a pre-check read under a lapsed critical section is a pre-check about a world that has moved.

Action wiring 11 is the repair for a `record` that did not land. A complete entry beside a `not-seen` token means the first invocation crashed between its result write and its `record`, or the `record` was silently missed; re-recording starts a fresh guard rather than extending one, which is [Duplicate Prevention](../atoms/duplicate-prevention.md)'s `Invariant 2`.

Action wiring 12 is how a fresh request is reached without waiting for the eviction leg. Past the window and with the guard gone, the entry is expired and the invocation evicts it in place and proceeds. An entry past the window whose token is still `seen` replays instead — the ordering Invariant 7 requires.

Action wiring 19 is the rule an earlier draft would have made a defect. A recording-failure at the outcome position reports a write that did not land, not an act that did not happen — the constituent may well have committed — so the answer carries the constituent's own answer, id included, and the caller must not re-run the act under a fresh token.

### Wiring decision

```
Wiring decision 1: The composition MUST record EVERY constituent answer against the token.
Wiring decision 2: The composition MUST record a constituent's rejection against the token.
Wiring decision 3: The composition MUST NOT record an answer for a malformed idempotency_token.
Wiring decision 4: The composition MUST NOT record an answer the composition returned on a seen token carrying no entry.
Wiring decision 5: The composition MUST NOT record a recording-failure as a result.
```

WHY:
Caching the failure is the non-obvious half. If a first [Place Hold] answers resource-unavailable and a retry were allowed to re-call the constituent, the retry might succeed — the resource may have freed in between — and the caller would observe two answers to what they meant as one operation. Caching the rejection preserves *same token, same result*; the caller decides whether to attempt the act again under a **fresh** token.

The three exclusions share one reason: the composition did not act, so it holds nothing to cache. A malformed token is not a token; a `seen` token with no entry means the composition recorded nothing and the next `check` may answer differently; and a recording-failure reports a write rather than an outcome — at the outcome position it leaves a pending entry behind, which is what a same-token retry lands.

### Housekeeping

```
Housekeeping 1: The eviction leg MUST examine a token's entry ONLY AFTER taking the token's critical section.
Housekeeping 2: The eviction leg MUST skip a token whose critical section the eviction leg cannot take.
Housekeeping 3: The eviction leg MUST NOT examine an entry younger than the reservation completion bound.
Housekeeping 4: The eviction leg MUST evict an entry ONLY IF Duplicate Prevention's check answers not-seen.
Housekeeping 5: The eviction leg MUST evict an entry ONLY IF the idempotency window elapsed since the entry's pending instant.
Housekeeping 6: The eviction leg MUST NOT evict a seen token's entry.
Housekeeping 7: The eviction leg MUST NOT repair an entry.
Housekeeping 8: The eviction leg MUST NOT call a constituent's write.
Housekeeping 9: The eviction leg MUST measure an instant against the composition's own seam reading.
```

Term eviction leg: the leg `Housekeeping 1` through `Housekeeping 9` state — this composition's own, over the token entries the leg evicts.

WHY:
The two edges are what make the leg safe. Housekeeping 3 is the lower edge — below the completion bound an invocation may still be in flight — and Housekeeping 5 is the upper, past which Invariant 7 already treats the token as fresh. Housekeeping 6 holds the ordering Invariant 7 requires: a token still under Duplicate Prevention's guard keeps its entry, or a replay would find the guard and not the answer.

Housekeeping 7 and Housekeeping 8 are why the leg owes no liveness bound. It evicts and does nothing else — repairs nothing, re-delegates nothing, promises no closure — so a stale entry is a leak rather than a defect, and the leg runs on whatever schedule the deployment picks.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Idempotent place hold within the window.**
  ```
  Invariant 1.1: Two place_hold calls carrying one idempotency_token AND one parameters digest MUST answer alike inside the idempotency window.
  ```
- **Invariant 2 — Idempotent state transitions within the window.**
  ```
  Invariant 2.1: Two resolving calls carrying one idempotency_token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 2.2: The composition MUST NOT call a constituent twice for one idempotency_token inside the idempotency window.
  Invariant 2.3: A resolving action's re-entry MUST rest on Provisional Commitment Invariant 2.
  ```
- **Invariant 3 — Token to commitment, one to one.**
  ```
  Invariant 3.1: An idempotency_token inside the idempotency window MUST NOT bind two commitment ids.
  ```
- **Invariant 4 — Token action binding.**
  ```
  Invariant 4.1: An idempotency_token MUST bind EXACTLY ONE action type.
  Invariant 4.2: An idempotency_token MUST bind EXACTLY ONE parameters digest.
  ```
- **Invariant 7 — Token expiry releases the binding.**
  ```
  Invariant 7.1: The eviction leg MUST evict an entry ONLY AFTER Duplicate Prevention's guard elapsed AND the idempotency window elapsed since the entry's pending instant.
  Invariant 7.2: A call carrying an evicted idempotency_token MUST stand as a fresh request.
  Deleted: Invariant 5. Composes 5 owns it.
  Deleted: Invariant 6. Composes 5 and Composes 7 own it.
  ```
  WHY: the two deleted invariants asserted each constituent's invariants hold over this composition's instance, which `execution-contract.md` §Conformance settles by reference (Authority 6). What they carried beyond the blanket is Composes 6 and Composes 7 — the unchanged relay of a constituent rejection, and the once-per-first-invocation `record` discipline, which is this composition's call pattern rather than a property of the atom.
- **Invariant 8 — Exactly-once effect within the window.**
  ```
  Invariant 8.1: The composition MUST make the exactly-once claim ONLY IF the deployment declares the critical section, the token results durability AND Duplicate Prevention's store obligations.
  Invariant 8.2: An admitted first invocation MUST reach Provisional Commitment EXACTLY ONE time inside the idempotency window.
  ```
  WHY: `Invariant 8.1` is the corpus's only invariant conditioned on declared deployment capabilities, and stating the condition is what keeps it honest. Without the per-token critical section, two concurrent calls carrying one token can both pass the pre-check and both delegate; without the durability, an entry can vanish and a token land on the *seen, no entry* arm; without fail-closed, an unavailable guard admits the double. The claim is real where the three are declared and absent where they are not, and `Capability requirement 5` through `Capability requirement 16` are where a deployment declares them.

---

## Examples

### Walkthrough

A client behind a flaky network reserves a hotel room. The composition is configured with a 10-minute idempotency window.

1. **First call:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → composition takes the token's critical section; `check(idem_x73a) → not-seen`, no entry; writes `token_results[idem_x73a] = (place_hold, digest_α, pending, pending_at, —)`; delegates to Provisional Commitment; receives `rm_b4c`. Overwrites the entry with `(place_hold, digest_α, rm_b4c, pending_at, completed_at)`, calls `DuplicatePrevention.record(idem_x73a)`, releases the critical section. Returns `rm_b4c` to the client. State: `rm_b4c` Held.
2. **Network drops the response. Client retries:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → `check(idem_x73a) → seen`; lookup matches; returns cached `rm_b4c`. *Provisional Commitment is not invoked.* No second commitment is created.
3. **Client retries twice more:** identical outcome. Provisional Commitment still sees only one [Place Hold].
4. **Two hours later, client confirms** with a fresh token: `confirm(rm_b4c, idem_y22)` → `check(idem_y22) → not-seen`; delegates to `ProvisionalCommitment.confirm(rm_b4c)` → ok. Records and returns ok. State: `rm_b4c` Confirmed.
5. **Client retries the confirm** (browser back button or replay): `confirm(rm_b4c, idem_y22)` → `check → seen`; returns cached ok. Crucially, the second call does *not* return not-held — which is what would happen if the retry hit Provisional Commitment directly, because `rm_b4c` has already moved Held → Confirmed. The idempotency cache hides the terminal-absorption rejection from the legitimate retry.
6. **Eleven minutes later, client retries the original [Place Hold]** with `idem_x73a`. The 10-minute window has elapsed; `idem_x73a` is no longer in `DuplicatePrevention.recorded` (eventual-expiry invariant). `check → not-seen`; once the eviction leg has run, `token_results[idem_x73a]` is gone and the call is a fresh request — and where it has not yet run (its timing is not promised), the complete-entry arm finds an entry past the window with a `not-seen` token, evicts it in place under the critical section, and proceeds identically. Either way the composition delegates afresh. Provisional Commitment receives [Place Hold] against `room_307`; the room is no longer hold-able because `rm_b4c` is in Confirmed; it returns resource-unavailable. The composition caches *that* rejection against the new occurrence of the token. The client sees resource-unavailable — accurately reflecting the current state of the resource, not the stale identity of an old token.

### Banking — credit-hold authorization with retry

A merchant POS submits a $250 authorization with an idempotency key (ISO 20022 BizMsgIdr or scheme-defined equivalent). The acquirer's network glitches; the POS retries within seconds. The composition guarantees the cardholder is charged once, not twice. This is exactly what every modern payment processor implements — Stripe's `Idempotency-Key` HTTP header on `POST /v1/charges` produces the same behavior. The composition's `Invariant 8 — Exactly-once effect within the window` is the contract Stripe documents to merchants.

### Healthcare — bed assignment with double-click

An emergency department coordinator clicks *Assign Bed* on the dashboard. The dashboard hangs; she clicks again. Two `place_hold(bed_307, patient_p41, 2h, ...)` requests arrive at the bed-management service within 800 milliseconds. The dashboard supplies a session-bound idempotency token on every action; both requests carry the same token. The composition accepts the first, returns the bed assignment id; the second hits the idempotency cache and returns the same id. One bed assigned to one patient. The unit's regulatory audit (Joint Commission care-coordination standards) sees one assignment record, not two.

### Retail — inventory reservation with mobile retry

A shopper on flaky mobile WiFi taps *Reserve* on a one-of-one luxury item. The app generates an idempotency token from the cart session id and the item sku, attaches it to the request, and retries on network failure with exponential backoff. The composition guarantees the shopper either reserves the item once and sees a successful reservation, or sees a single resource-unavailable rejection (someone else got there first) regardless of how many retries the network handler attempts — or, where the service died between reserving and recording, one of the two honest answers in place of a second reservation: `recording-failure(outcome(optional id))` carrying the reservation's id, or `outcome-unknown(candidates)` naming the hold it can see but cannot pair, which the app resolves before trying again under a fresh token. No phantom *two reservations* state.

### Airline — seat hold with session replay

A travel agency's booking system replays the previous hour's requests after a database failover. Every hold request carries the original idempotency token. The reservation system replays correctly: holds that were already produced return their original commitment ids; holds whose tokens have since expired produce fresh commitments only if their seats are still available. No seat is held twice. The composition's `Invariant 7 — Token expiry releases the binding` is the failure mode the agency's operations team must understand: tokens older than the window are treated as fresh requests.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts, beyond happy-path:

- **Regulator audit — "show me every double-charge."** An auditor filters the underlying Provisional Commitment instance's exported commitment sets — the atom exports the sets and each record's fields, not a query keyed by them, so the filter is the auditor's own — for commitments sharing a `(resource, requester, placed_at-near)` signature. The composition's `Invariant 3 — Token-to-commitment one-to-one within the window` guarantees the query returns the empty set within the window; outside the window the audit must distinguish *legitimate sequential holds* (separate logical operations with separate tokens) from *retry-induced doubles* (which the composition has structurally prevented). The auditor sees a structural guarantee, not a procedural promise.
- **Disputed transaction — "you charged me twice."** The investigator inspects the composition's `token_results` map (or its persistent journal). If two of the customer's submitted requests carried the *same* token, the composition's cache produced one commitment and replayed the response — there is no double-spend to dispute. If the customer's client generated *different* tokens for what they intended as the same operation, the composition correctly processed them as independent operations; the dispute belongs to the client's token-generation logic, not to the reservation system.
- **Replay attack — adversary captures and replays a token.** An adversary captures an in-flight request and replays it later within the window. The composition correctly returns the cached result. The replay produces no new state change — `Invariant 2 — Idempotent state transitions within the window`. Replays *outside* the window are treated as fresh requests; the adversary may succeed in placing a new commitment if the resource is available and they hold valid credentials, but that is an authentication / authorization failure (see [Actor Identity](../atoms/actor-identity.md)), not an idempotency failure.
- **Token reuse collision — caller accidentally reuses a token across two operations.** A developer reuses `idem_x73a` (originally used for `place_hold(room_307, ...)`) in a subsequent `confirm(rm_b4c, idem_x73a)` call. The composition checks: `DuplicatePrevention.check(idem_x73a) → seen`; looks up `token_results[idem_x73a]` and finds `action_type = place_hold`. Current call's `action_type = confirm` — mismatch. Returns token-collision. No state change occurs. The caller must use a fresh token for the confirm. Invariant 4 (*Token-action binding*) is the structural guarantee; [Token Collision] is its observable form.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the commitment store, the recorded set and the token results map, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY token results entry carrying one action type (Invariant 4.1).
Check 1.2: An auditor MUST find EVERY token results entry carrying one parameters digest (Invariant 4.2).
Check 2.1: An auditor MUST find no idempotency_token bound to two commitment ids inside the idempotency window (Invariant 3.1).
Check 3.1: An auditor MUST find EVERY complete entry carrying the result the constituent answered (Wiring decision 1).
Check 3.2: An auditor MUST find EVERY complete entry keeping the entry's pending instant (Composition state 7).
Check 4.1: An auditor MUST find no evicted entry whose token Duplicate Prevention's check answers seen for (Housekeeping 6).
Check 4.2: An auditor MUST find no evicted entry younger than the idempotency window (Housekeeping 5).
Check 5.1: An auditor MUST find EVERY recovered entry marked (Indeterminate outcome 8).
Check 5.2: An auditor MUST find EVERY outcome-unknown entry carrying the candidates (Indeterminate outcome 7).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the critical section confirmed MUST read the deployment's own host (Capability requirement 5).
External check 2: An auditor needing the token results durability confirmed MUST read the deployment's own store configuration (Capability requirement 12).
External check 3: An auditor needing Duplicate Prevention's fail-closed posture confirmed MUST read the deployment's own configuration (Capability requirement 16).
External check 4: An auditor needing the commitment store's atomicity confirmed MUST read the deployment's own declaration (Capability requirement 17).
External check 5: An auditor needing the exactly-once claim confirmed MUST read External check 1, External check 2 AND External check 3 (Invariant 8.1).
External check 6: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 7: An auditor needing the idempotency window confirmed MUST read the deployment's own configuration (Capability requirement 1).
External check 8: An auditor needing the token max length confirmed MUST read the deployment's own configuration (Capability requirement 2).
External check 9: An auditor needing the digest function confirmed MUST read the deployment's own configuration (Capability requirement 3).
```

WHY:
External check 7 through 9 are the three knobs an auditor cannot infer from the map. The window decides which entries should still be there, the max length and the digest function decide whether two callers' tokens are the same token at all, and a map read against the wrong three answers the wrong question without saying so.

WHY:
External check 5 is the one that makes `Invariant 8.1` auditable rather than decorative. The exactly-once claim is conditional on three declared capabilities and none of the three is a record — a critical section, a durability guarantee and a store posture are all operating facts. An auditor who cleared the record checks and stopped would report exactly-once for a deployment that declares none of them, which is the failure this split exists to prevent.

The record-versus-attempt line falls here as it does elsewhere: what *stands* — an entry, its digest, its result, its instants — clears from the map; what was *attempted* leaves nothing. A concurrent pair that both passed the pre-check writes one entry, not two, so the absence of the critical section shows up in the commitment store as a double rather than in the map as a defect, which is why External check 1 exists.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT guarantee exactly-once for an idempotency_token the idempotency window elapsed for.
Non-goal 2: The composition MUST NOT bound the idempotency window.
Non-goal 3: The composition MUST NOT mint an idempotency_token.
Non-goal 4: A caller MUST mint an idempotency_token.
Non-goal 5: The composition MUST NOT interpret an idempotency_token.
Non-goal 6: The composition MUST NOT claim atomicity across the token results map and the commitment store.
Non-goal 7: A deployment needing a multi-commitment transaction MUST compose a transaction pattern.
Non-goal 8: The composition MUST NOT resolve the candidates.
Non-goal 9: The composition MUST NOT record an authorization.
Non-goal 10: A deployment needing an authorized call MUST compose Permissions.
Non-goal 11: The composition MUST NOT record an act.
Non-goal 12: A deployment needing an act recorded MUST compose Audit Trail.
Non-goal 13: The composition MUST NOT promise a closure window for a stale entry.
```

WHY:
Non-goal 6 is the honest limit under the whole design. Two stores, no distributed transaction, so the composition orders its writes — intent first, result second, guard third — and recovers each reachable partial rather than preventing them. `Non-goal 7` names where a caller goes who needs more; the constituent's own edge case sends multi-commitment work to a transaction pattern and this composition does not pretend otherwise.

Non-goal 8 is the boundary with the operator. The composition names the candidates and stops: releasing a hold that was not meant, or adopting one that was, needs domain knowledge the mechanism does not have, and a composition that guessed would make a double out of an ambiguity.

Non-goal 13 follows from `Housekeeping 7`. The leg evicts and repairs nothing, so a stale entry is a leak — space, not correctness — and promising a closure window would be a liveness claim nothing here can keep.

---

## Edge cases

### Indeterminate outcome

```
Indeterminate outcome 1: A pending entry MUST stand as an act that may have happened.
Indeterminate outcome 2: The composition MUST NOT delegate again for a pending entry.
Indeterminate outcome 3: The composition MUST compute the candidates from Provisional Commitment's held commitments.
Indeterminate outcome 4: The composition MUST keep a held commitment whose resource AND requester equal the call's in the candidates.
Indeterminate outcome 5: IF the candidates EQUALS blank THEN the composition MUST proceed as a fresh request's delegation.
Indeterminate outcome 6: IF the candidates DOES NOT EQUAL blank THEN the composition MUST overwrite the pending entry with outcome-unknown naming the candidates.
Indeterminate outcome 7: An outcome-unknown answer MUST carry the candidates.
Indeterminate outcome 8: The composition MUST mark a recovered entry.
Indeterminate outcome 9: A resolving action MUST run again for a pending entry.
Indeterminate outcome 10: The composition MUST answer outcome-unknown for a seen token carrying no entry.
Indeterminate outcome 11: A caller MUST resolve the candidates.
Indeterminate outcome 12: A caller receiving a recording-failure naming the outcome MUST NOT run the act under a fresh idempotency_token.
```

Term candidates: the held commitments of the Provisional Commitment instance whose resource and requester equal a call's — a candidates set; the composition's own filter over a constituent read, never a constituent's answer.

Term resolving action: [Confirm] | [Release] | [Expire].

Term recovered entry: a token results entry a re-entry wrote rather than the entry's first invocation.

WHY:
Indeterminate outcome 2 is the composition's sharpest restraint. A pending entry found under the critical section means the invocation that wrote it returned or died between its pending write and its result write, and **whether Provisional Commitment committed for it is not re-derivable** — the constituent's record carries no token. So the composition does not guess by re-delegating; it names what it can see.

Indeterminate outcome 5 and Indeterminate outcome 9 are the two ways the indeterminacy resolves, and they differ by what the constituent guarantees. For [Place Hold], empty candidates mean the constituent holds nothing for these parameters, so the dead invocation never reached it and the act proceeds — exact wherever the hold's duration exceeds the time to the retry, and a hold already expired by then is the resource's history rather than a live double. For a resolving action there is nothing to compute: [Provisional Commitment](../atoms/provisional-commitment.md)'s single-resolution invariant makes a second call effect-free, so the re-run either commits the transition the caller intended or answers not-held, and exactly-once survives on the constituent's own contract.

Indeterminate outcome 10 is fail-closed's bill. Duplicate Prevention remembers a token the composition does not — a durability breach, or an unavailable store answering `seen` — and the composition cannot tell a lost entry from a fresh token. It does not re-delegate, records nothing, and a later call once `check` can answer is decided afresh.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own an idempotency_token's format.
Composition note 3: A deployment MUST own the disposition of the candidates.
Composition note 4: A deployment MUST own the eviction leg's schedule.
Composition note 5: A deployment MUST NOT expose a constituent's own caller surface beside the composition's.
```

WHY:
Composition note 5 is `Composes 4` restated as the deployment's obligation, and it is the one a deployment can breach silently. Every guarantee here is a guarantee about calls carrying a token; a route to `ProvisionalCommitment.place_hold` that carries none is a second door, and nothing in the composition's own records shows the door exists.

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the retry-safe action-wirings it exposes ([Place Hold], [Confirm], [Release], [Expire]), the [Idempotency Token] it introduces on every call, and the fields of the recorded outcome it caches ([Action Type], [Parameters Digest], [Result]) plus its own [Token Collision], [Outcome Unknown] and [Recording Failure] rejections. It carries one piece of own state — the `token_results` map (classified extraction-pending, the proposed *Idempotency Result Memo* atom) — left as a backticked store token rather than carded as a Type, so its Fields are carded against the plain-noun recorded outcome. References to the constituent atoms and their operations — Provisional Commitment's place_hold/confirm/release/expire, Duplicate Prevention's `check`/`record` — the inherited rejection tokens (resource-unavailable, not-known, not-held, window-elapsed, window-not-elapsed, storage-failure, invalid-request), the entry states and stamps (pending, `recovery`, `pending_at`, `completed_at`), and the deployment configuration knobs (`idempotency_window`, `token_max_length`, `digest_function`, `per_token_serialization`, `reservation_completion_bound`, `token_results_durability`, `duplicate_prevention_store`, `commitment_store_acknowledged_atomic`) all remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, token results map, action type, parameters digest, pending entry, complete entry, eviction leg, idempotency window, reservation completion bound, durability term, critical section, blank, fresh request, matching complete entry, candidates, resolving action, recovered entry, place hold position, resolution position.

Term record verbs: call, answer, take, read, write, store, key, carry, overwrite, keep, evict, examine, skip, measure, repair, validate, compare, normalize, case-fold, record, retry, release, delegate, compute, proceed, mark, resolve, rest, stand, bind, reach, find, name, own, discharge, inherit, change, replace, serve, compose, configure, declare, set, hold, acknowledge, supply, refuse, mint, interpret, claim, promise, expose, consult, start, elapse, exceed, land, run, make, guarantee, bound.

Term actors: the composition; the constituents; the host; the transition; a deployment; an auditor; a caller; an operator; an invocation; the eviction leg; an entry; a token; a commitment.

Term cited: `execution-contract.md` §Conformance — recursive conformance and the inherited guarantee. `execution-contract.md` §Composition state — the extraction-pending classification. `execution-contract.md` §Logic Confinement Principle — the seam, the transition and the mechanism-capability pattern. [Provisional Commitment](../atoms/provisional-commitment.md) `Invariant 2` — single resolution, which makes a resolving re-run effect-free. [Duplicate Prevention](../atoms/duplicate-prevention.md) `Invariant 2` — a record starts a guard rather than extending one.

#### Place Hold

The composition action that places a hold, made retry-safe: it validates the [Idempotency Token], and on a first call writes the pending intent against the token, then delegates to Provisional Commitment's place_hold and overwrites the intent with the outcome; a retry within the window replays the cached [Result] instead of delegating again. Returns the commitment id, or a cached / delegated rejection.

Kind: Operation

#### Confirm

The retry-safe confirm action — same token-check-then-delegate wiring as [Place Hold], delegating to Provisional Commitment's confirm. A within-window retry returns the cached ok, hiding the terminal-absorption not-held a direct retry would hit; a token bound to a different [Action Type] is rejected [Token Collision].

Kind: Operation

#### Release

The retry-safe release action — same wiring, delegating to Provisional Commitment's release. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

#### Expire

The retry-safe expire action — same wiring, delegating to Provisional Commitment's expire. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

#### Idempotency Token

The caller-supplied key attached to every state-changing call. The composition introduces it (Provisional Commitment's actions do not carry it); it keys the recorded outcome and is the identity recorded in Duplicate Prevention. Treated as opaque, compared byte-exact, and validated (non-empty, within `token_max_length`) before any constituent is consulted.

Kind:         Parameter
Parameter of: the state-changing actions ([Place Hold], [Confirm], [Release], [Expire])
Role:         the idempotency key (also the recorded-outcome key and the Duplicate Prevention identity)
Projection:   idempotency_token

#### Action Type

The recorded outcome's record of which logical operation the token was bound to — one of place_hold, confirm, release, expire. A retry whose action differs from the recorded one is rejected [Token Collision] (Invariant 4).

Kind:       Field
Field of:   the recorded outcome
Role:       the token's bound operation
Projection: action_type

#### Parameters Digest

The recorded outcome's collision-resistant digest of the non-token call parameters, computed at the composition's I/O seam and injected. A retry whose digest differs from the recorded one is rejected [Token Collision]; digest-function drift across replicas misclassifies legitimate retries.

Kind:       Field
Field of:   the recorded outcome
Role:       the token's bound parameters
Projection: parameters_digest

#### Result

The recorded outcome's copy of the original response — the produced id or ok, or the rejection reason — exactly as returned to the caller on the first call, or the `outcome-unknown(candidates)` the re-entry arm wrote in place of an answer nobody recorded. Every outcome is cached, success or rejection (the cache-the-failure rule).

Kind:       Field
Field of:   the recorded outcome
Role:       the replayed response
Projection: result

#### Token Collision

The composition's own rejection — returned when a token already in the window is reused for a different [Action Type] or with a different [Parameters Digest]. Its structural guarantee is Invariant 4 (token-action binding); no state change occurs.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: token-collision

#### Outcome Unknown

The composition's own rejection for a token whose earlier invocation may have acted and did not record its answer — a pending entry found under the token's critical section, or a token Duplicate Prevention remembers and `token_results` does not. For [Place Hold] it carries the candidate Held commitments matching the call's resource and requester, filtered composition-side from Provisional Commitment's exported set; the composition re-delegates nothing (the resolving actions re-run instead, effect-free by Provisional Commitment Invariant 2). Replayed for the token's window when written against a pending entry; uncached when no entry existed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: outcome-unknown

#### Recording Failure

The composition's own rejection for a write to `token_results` that did not land, carrying its position and, at the outcome position, the constituent's answer. intent: the pending entry failed — nothing is committed, and the whole action may be retried (a write that landed unacknowledged is found by the retry's pending arm, whose empty-candidates case proceeds as never delegated). `outcome(optional id)` for [Place Hold], `outcome(result)` for the resolving actions: the constituent has answered — the committed id where there is one, else its rejection or ok — and the [Result] could not be recorded by `reservation_completion_bound`; the act must not be re-run under a fresh token, and a same-token retry lands the pending arm.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: recording-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a term marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Place Hold]: #place-hold
[Confirm]: #confirm
[Release]: #release
[Expire]: #expire
[Idempotency Token]: #idempotency-token
[Action Type]: #action-type
[Parameters Digest]: #parameters-digest
[Result]: #result
[Token Collision]: #token-collision
[Outcome Unknown]: #outcome-unknown
[Recording Failure]: #recording-failure

---

## Standards references

This composition draws on:

- **IETF draft-ietf-httpapi-idempotency-key-header** — the HTTP idempotency-key convention; an industry-standard wire format for the idempotency_token.
- **ISO 20022 (financial messaging)** — `BizMsgIdr` and related message-uniqueness identifiers; the financial-industry standard for at-most-once message semantics.
- **HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) `Bundle.identifier`, `MessageHeader.id`** — healthcare-industry standard for at-most-once message processing.
- **Stripe Idempotency-Key, Adyen idempotency header, AWS request-ID** — de-facto industry conventions; this composition formalizes what they all implement.
- **PCI DSS Requirement 10 (logging and monitoring)** — composing with Event Log, the commitment record and the token-mapping together produce the audit-evidence PCI requires.

The two atoms it composes carry their own standards inheritance — Provisional Commitment (ISO 9001 — the International Organization for Standardization quality-management standard — §8.5.2 and §8.5.4; Basel III BCBS 238 — Basel Committee on Banking Supervision liquidity rules; Joint Commission; IATA — International Air Transport Association; PCI DSS; GDPR — EU General Data Protection Regulation — Art. 30; SOX — Sarbanes-Oxley Act — §404; HIPAA — Health Insurance Portability and Accountability Act — §164.312(b)) and Duplicate Prevention (IETF HTTP idempotency-key draft, payment-processor idempotency conventions, message-queue exactly-once-within-window literature).

It inherits from:

- **Stripe's idempotency design document** — the public formalization of *same key, same result* as the contract that makes retry-safe APIs practical.
- **Distributed-systems exactly-once-delivery literature** — Kafka's `enable.idempotence`, RabbitMQ's deduplication, the broader academic line on at-most-once messaging.
- **Pat Helland, *Idempotence is Not a Medical Condition*** — the seminal write-up on idempotency as an API-design discipline rather than an infrastructure trick.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the model has each invocation as one atomic step, with no `pending` intent, no per-token section with a lease terminus, and no eviction leg as a second process over one token; was verified — idempotent-reservation.tla + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open:
- 2026-08-30-a · refining · formal · the invocation is one atomic step — no `pending` intent, no per-token critical section with a lease terminus, no eviction leg as a second process over one token, no `outcome-unknown` arm; the twin's early-eviction hazard is now the leg's (iii) → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/idempotent-reservation.md`.

- **2026-08-30 — The intent is written before the act, the writer is one per token, and what cannot be re-derived is not re-run.** *Chose:* a pending entry written to `token_results` before Provisional Commitment is called, with a re-entry arm that — finding it under the token's critical section — names candidate holds for [Place Hold] and re-runs only the resolving actions, whose second call is effect-free by the constituent's single-resolution invariant; `per_token_serialization` declared as an instance capability requirement (released on return or death; a lease exactly `reservation_completion_bound` long whose expiry is the invocation's terminus) and taken by the eviction leg too, so the invocation and the leg never both write one token; the leg bounded at both edges — nothing younger than the bound, eviction only past the window and only for a `not-seen` token; `recording-failure(intent | outcome)` on every signature, the `outcome` position carrying the committed id, and Provisional Commitment's storage-failure, not-known and window-not-elapsed transcribed; Duplicate Prevention's disclaimed durability and its fail-open/fail-closed choice declared as `duplicate_prevention_store`, condition (c) of Invariant 8; `token_results` durability housed in Configuration; the claimed atomicity between the two stores replaced by write order, five reachable partials, and a recovery for each; and, from the closure check the same day, the complete-entry arm guarded by the window on the composition's own stamps (an expired `not-seen` entry evicted in place, so Invariant 7's fresh request does not wait on the leg), `pending_at` kept on the complete entry with `completed_at` beside it, the critical section declared shared across every instance sharing the store, `commitment_store_acknowledged_atomic` transcribing the constituent's own write obligation so that storage-failure is cached as definitive only where it is, and the pending arm's empty-candidates case proceeding as never delegated. *Over:* "persisted atomically with each successful action" as an implementation requirement, an eviction surface that read an in-flight invocation as evictable, a serialization the spec "assumed", and four signatures that told a caller nothing was committed when a commitment existed. *Because:* the constituent's record carries no token, so a crash between the act and its record leaves an outcome no retry can re-derive — and a retry that re-delegates is the double this composition exists to prevent; two writers over one token land two results; and a caller who cannot tell intent from `outcome` re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*A reconciliation is bounded at both ends* and §*Recovery commits under a declared service identity* of 2026-08-29).

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two invariants the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Eviction`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision` and `Indeterminate outcome` as the surfaces, the six surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Eviction` is the one family minted here and it is minted for a reason no other composition has had: the eviction leg is the only leg in the corpus that runs *outside* an invocation, with its own two edges and its own exclusion against the invocations it runs beside, and folding nine rules about a background sweep into `Composition state` would have buried the one surface a reader most needs to find. One spec, flagged, waiting on recurrence (Principle 1 through 3, council read 57's promotion path).
- **2026-09-14 — Two preservation claims are one citation, third instance.** *Chose:* `Composes 5`, with `Invariant 5` and `Invariant 6` tombstoned to it. *Over:* keeping them. *Because:* council read 53's ruling, now applied at its third seam. What they carried beyond the blanket survives as `Composes 6` (the unchanged relay of a constituent rejection, which no atom guarantees about a caller) and `Composes 7` (the once-per-first-invocation `record` discipline, which is this composition's call pattern rather than a property of [Duplicate Prevention](../atoms/duplicate-prevention.md)).
- **2026-09-14 — The extraction-pending element is carried as a rule surface, not softened.** *Chose:* to state the `token_results` map as nine `Composition state` rules with the classification named in the WHY, the proposed atom named, and `Capability requirement 12` through `Capability requirement 14` carrying its durability. *Over:* describing it in prose, as every other composition's state section does — because every other composition's state section had nothing to describe. *Because:* this is the corpus's first migrated composition carrying truth no replay of its constituents reproduces, and `execution-contract.md` §Composition state says an unflagged truth-bearing composition store is a conformance finding while a flagged one is scheduled debt. The flag is the whole difference, so it belongs on the rule surface where an instrument can find it rather than in a paragraph (council read 58).

- **2026-09-14 — `Eviction` re-cut as `Housekeeping`, joining the leg it was kept apart from.** *Chose:* the family renamed, with the nine rules and every citation of them moving with it. *Over:* keeping a one-spec family named for what this leg happens to do. *Because:* the entry above kept `Eviction` apart from [Authenticated Actor](./authenticated-actor.md)'s `Reconciliation` on *one evicts and one reports*, and the drift pass found that axis wrong — it predicts the liveness bound on two of four legs, and this leg is one of the two it misses, because it takes a critical section and writes to the composition's own store while owing nothing. What decides the bound across all four is whether anything **awaits** the leg's output. Nothing awaits an eviction and nothing awaits an orphan report, so the two are one family; [Login](./login.md)'s and [Defensible Retention](./defensible-retention.md)'s sweeps discharge a promise and are the other. `Housekeeping 7` and `Housekeeping 8` keep their reading unchanged — they are still why this leg owes no liveness bound, and now the family name says so too (council read 64).

NOTE: End of Idempotent Reservation.

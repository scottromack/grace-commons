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

This composition solves the problem at the composition layer rather than absorbing it into Provisional Commitment. The caller supplies an **idempotency token** on every state-changing call. The composition checks the token against a [Duplicate Prevention](../atoms/duplicate-prevention.md) instance; if the token has been seen within the window (the configurable time period during which repeated tokens are detected and deduplicated), the composition returns the *original* response (the same commitment id, the same ok, the same rejection reason) without invoking [Provisional Commitment](../atoms/provisional-commitment.md) a second time — with one exception Invariant 2 states: a resolving action whose token Duplicate Prevention reports seen while the composition holds no answer for it is re-run, effect-free by the constituent's own single-resolution invariant. The constituent atoms are unchanged; the composition is the wiring.

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
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST answer a constituent's rejection unchanged.
Composes 7: The composition MUST call Duplicate Prevention's record EXACTLY ONE time per admitted first invocation.
Composes 8: The composition MUST configure the Duplicate Prevention instance with the idempotency window.
```

Term composition: this pattern's wiring of [Provisional Commitment](../atoms/provisional-commitment.md) and [Duplicate Prevention](../atoms/duplicate-prevention.md) — the token map, the four token-carrying actions and the eviction leg.

Term constituents: [Provisional Commitment](../atoms/provisional-commitment.md), [Duplicate Prevention](../atoms/duplicate-prevention.md).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a token results map.
Composition state 2: The composition MUST key the token results map by idempotency token.
Composition state 3: An entry MUST carry an action type, a parameters digest, a result, a pending instant AND a completed instant.
Deleted: Composition state 4. Execution Contract Store 1 owns it.
Deleted: Composition state 5. Execution Contract Store 1 owns it.
Composition state 6: EXACTLY ONE invocation MUST write an entry per act.
Deleted: Composition state 7. Execution Contract Store 1 owns it: an action's writes commit together, and the composition names no overwrite to keep the pending instant across.
Composition state 9: The composition MUST take the parameters digest from the seam.
Composition state 10: The transition MUST NOT compute a parameters digest.
Deleted: Composition state 8. Housekeeping 5 owns it.
```

Term token results map: the composition's own map from an idempotency token to a recorded outcome — a token results map; the element the section titled Composition state in `execution-contract.md` classifies extraction-pending.

Term action type: place_hold | confirm | release | expire.

Term parameters digest: the collision-resistant digest of a call's non-token parameters, computed at the seam by the configured digest function and injected — a [Parameters Digest].

Term complete entry: a token results entry carrying a recorded result and a completed instant.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the token results map: extraction-pending, the proposed atom an *Idempotency Result Memo* (token → result, write-once, window-governed eviction), opened as a roadmap proposal (Composition state 1).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the idempotency window.
Capability requirement 2: A deployment MUST set the token max length.
Capability requirement 3: A deployment MUST set the digest function.
Capability requirement 4: A deployment MUST set the digest function alike across EVERY instance sharing the token results map.
Deleted: Capability requirement 5. Execution Contract Store 2 owns it.
Deleted: Capability requirement 6. Execution Contract Store 2 owns it.
Deleted: Capability requirement 7. Execution Contract Store 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 8. Execution Contract Store 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 9. Execution Contract Store 1 and Execution Contract Store 2 own it.
Deleted: Capability requirement 10. Execution Contract Store 1 and Execution Contract Store 2 own it: the composition names no reservation completion bound for the idempotency window to exceed.
Deleted: Capability requirement 11. Execution Contract Store 1 and Execution Contract Store 2 own it: the composition names no reservation completion bound for the idempotency window to exceed.
Deleted: Capability requirement 12. Execution Contract Store 3 owns it.
Deleted: Capability requirement 13. Execution Contract Store 3 and Execution Contract Store 4 own it.
Deleted: Capability requirement 14. Execution Contract Store 3 owns it.
Deleted: Capability requirement 15. Execution Contract Store 3 owns it.
Capability requirement 16: A deployment MUST resolve Duplicate Prevention's check fail-closed.
Deleted: Capability requirement 17. Execution Contract Store 3 owns it.
Capability requirement 18: The deployment MUST supply the store PER Execution Contract Store 1 through 4.
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token — an idempotency window.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank idempotency token.
Primitive policy 2: The composition MUST answer invalid-request for an idempotency token EXCEEDS the token max length.
Primitive policy 3: The composition MUST compare an idempotency token byte-exact.
Primitive policy 4: The composition MUST NOT normalize an idempotency token.
Primitive policy 5: The composition MUST NOT case-fold an idempotency token.
Primitive policy 6: The composition MUST call Duplicate Prevention's check ONLY AFTER the idempotency token clears the boundary predicate.
Primitive policy 7: The composition MUST NOT store an entry for a malformed idempotency token.
```

### Action wiring

```
place_hold(resource, requester, duration, idempotency_token)
  answers id
  refuses invalid-request | token-collision | resource-unavailable | storage-failure | outcome-unknown(candidates)

confirm(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure

release(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure

expire(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-not-elapsed | storage-failure
```

```
Action wiring 1: EVERY state-changing action MUST take an idempotency token.
Deleted: Action wiring 2. Execution Contract Store 2 owns it.
Deleted: Action wiring 3. Execution Contract Store 2 owns it.
Deleted: Action wiring 4. Execution Contract Store 2 owns it.
Deleted: Action wiring 5. Execution Contract Store 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Action wiring 6. Execution Contract Store 2 owns it: an action's reads of a token and the writes they decide are one transaction, and the composition names no critical section to lapse.
Action wiring 7: IF an entry's action type differs from the call's action type THEN the composition MUST answer token-collision.
Action wiring 8: IF an entry's parameters digest differs from the call's parameters digest THEN the composition MUST answer token-collision.
Action wiring 9: The composition MUST answer a matching complete entry's result.
Action wiring 10: The composition MUST NOT call a constituent for a matching complete entry.
Deleted: Action wiring 11. Execution Contract Store 1 owns it.
Action wiring 12: The composition MUST evict a complete entry the idempotency window elapsed for AND Duplicate Prevention's check answers not-seen for.
Deleted: Action wiring 13. Execution Contract Store 1 owns it.
Deleted: Action wiring 14. Execution Contract Store 1 owns it.
Deleted: Action wiring 15. Execution Contract Store 1 owns it.
Deleted: Action wiring 16. Execution Contract Store 1 owns it.
Deleted: Action wiring 17. Execution Contract Store 1 owns it.
Deleted: Action wiring 18. Execution Contract Store 1 owns it.
Deleted: Action wiring 19. Execution Contract Store 1 owns it: an action's writes commit together, so no recording failure names the outcome.
Deleted: Action wiring 20. Execution Contract Store 1 owns it.
Action wiring 21: The composition MUST answer Provisional Commitment's answer to the caller.
Action wiring 22: A read-only query MUST NOT take an idempotency token.
Action wiring 23: A read-only query MUST NOT consult the token results map.
Action wiring 24: The composition MUST take an idempotency token on EXACTLY ONE OF place_hold, confirm, release, expire.
Action wiring 25: The composition MUST call Duplicate Prevention's record for EVERY result that lands.
```

Term fresh request: a call finding no entry AND Duplicate Prevention's check answering not-seen.

Term matching complete entry: a complete entry whose action type AND parameters digest equal the call's.

### Wiring decision

```
Wiring decision 1: The composition MUST record EVERY constituent answer against the token.
Wiring decision 2: The composition MUST record a constituent's rejection against the token.
Wiring decision 3: The composition MUST NOT record an answer for a malformed idempotency token.
Wiring decision 4: The composition MUST NOT record a [Place Hold] answer the composition returned on a seen token carrying no entry.
Deleted: Wiring decision 5. Execution Contract Store 1 owns it: an action's writes commit together, so the composition answers no recording failure to record.
```

WHY:
Caching the failure is the non-obvious half. If a first [Place Hold] answers resource-unavailable and a retry were allowed to re-call the constituent, the retry might succeed — the resource may have freed in between — and the caller would observe two answers to what they meant as one operation. Caching the rejection preserves *same token, same result*; the caller decides whether to attempt the act again under a **fresh** token.

The two exclusions share one reason: the composition did not act, so it holds nothing to cache. A malformed token is not a token, and a `seen` token with no entry means the composition recorded nothing and the next `check` may answer differently.

### Housekeeping

```
Deleted: Housekeeping 1. Execution Contract Store 2 owns it.
Deleted: Housekeeping 2. Execution Contract Store 2 owns it: the eviction leg's reads of a token and the eviction they decide are one transaction, and the composition names no critical section for another holder to hold.
Deleted: Housekeeping 3. Execution Contract Store 1 owns it.
Housekeeping 4: The eviction leg MUST evict an entry ONLY IF Duplicate Prevention's check answers not-seen.
Housekeeping 5: The eviction leg MUST evict an entry ONLY IF the idempotency window elapsed since the entry's pending instant.
Housekeeping 6: The eviction leg MUST NOT evict a seen token's entry.
Housekeeping 7: The eviction leg MUST NOT repair an entry.
Housekeeping 8: The eviction leg MUST NOT call a constituent's write.
Housekeeping 9: The eviction leg MUST measure an instant against the composition's own seam reading.
```

Term eviction leg: the leg the Housekeeping rules state — this composition's own, over the token entries the leg evicts.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Idempotent place hold within the window.**
  ```
  Invariant 1.1: Two place_hold calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  ```
- **Invariant 2 — Idempotent state transitions within the window.**
  ```
  Invariant 2.1: Two resolving calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 2.2: The composition MUST NOT call a constituent twice for one idempotency token inside the idempotency window.
  Invariant 2.3: A resolving action's re-entry MUST rest on Provisional Commitment Invariant 2.
  ```
- **Invariant 3 — Token to commitment, one to one.**
  ```
  Invariant 3.1: An idempotency token inside the idempotency window MUST NOT bind two commitment ids.
  ```
- **Invariant 4 — Token action binding.**
  ```
  Invariant 4.1: An idempotency token MUST bind EXACTLY ONE action type.
  Invariant 4.2: An idempotency token MUST bind EXACTLY ONE parameters digest.
  ```
- **Invariant 7 — Token expiry releases the binding.**
  ```
  Invariant 7.1: The eviction leg MUST evict an entry ONLY AFTER Duplicate Prevention's guard elapsed AND the idempotency window elapsed since the entry's pending instant.
  Invariant 7.2: A call carrying an evicted idempotency token MUST stand as a fresh request.
  Deleted: Invariant 5. Composes 5 owns it.
  Deleted: Invariant 6. Composes 5 and Composes 7 own it.
  ```
- **Invariant 8 — Exactly-once effect within the window.**
  ```
  Invariant 8.1: The composition MUST make the exactly-once claim ONLY IF the deployment declares Duplicate Prevention's store obligations.
  Invariant 8.2: An admitted first invocation MUST reach Provisional Commitment EXACTLY ONE time inside the idempotency window.
  ```

---

## Examples

### Walkthrough

A client behind a flaky network reserves a hotel room. The composition is configured with a 10-minute idempotency window.

1. **First call:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → `check(idem_x73a) → not-seen`, no entry; delegates to Provisional Commitment; receives `rm_b4c`. Writes `token_results[idem_x73a] = (place_hold, digest_α, rm_b4c, pending_at, completed_at)` and calls `DuplicatePrevention.record(idem_x73a)`. Returns `rm_b4c` to the client. State: `rm_b4c` Held.
2. **Network drops the response. Client retries:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → `check(idem_x73a) → seen`; lookup matches; returns cached `rm_b4c`. *Provisional Commitment is not invoked.* No second commitment is created.
3. **Client retries twice more:** identical outcome. Provisional Commitment still sees only one [Place Hold].
4. **Two hours later, client confirms** with a fresh token: `confirm(rm_b4c, idem_y22)` → `check(idem_y22) → not-seen`; delegates to `ProvisionalCommitment.confirm(rm_b4c)` → ok. Records and returns ok. State: `rm_b4c` Confirmed.
5. **Client retries the confirm** (browser back button or replay): `confirm(rm_b4c, idem_y22)` → `check → seen`; returns cached ok. Crucially, the second call does *not* return not-held — which is what would happen if the retry hit Provisional Commitment directly, because `rm_b4c` has already moved Held → Confirmed. The idempotency cache hides the terminal-absorption rejection from the legitimate retry.
6. **Eleven minutes later, client retries the original [Place Hold]** with `idem_x73a`. The 10-minute window has elapsed; `idem_x73a` is no longer in `DuplicatePrevention.recorded` (eventual-expiry invariant). `check → not-seen`; once the eviction leg has run, `token_results[idem_x73a]` is gone and the call is a fresh request — and where it has not yet run (its timing is not promised), the complete-entry arm finds an entry past the window with a `not-seen` token, evicts it in place and proceeds identically. Either way the composition delegates afresh. Provisional Commitment receives [Place Hold] against `room_307`; the room is no longer hold-able because `rm_b4c` is in Confirmed; it returns resource-unavailable. The composition caches *that* rejection against the new occurrence of the token. The client sees resource-unavailable — accurately reflecting the current state of the resource, not the stale identity of an old token.

### Banking — credit-hold authorization with retry

A merchant POS submits a $250 authorization with an idempotency key (ISO 20022 BizMsgIdr or scheme-defined equivalent). The acquirer's network glitches; the POS retries within seconds. The composition guarantees the cardholder is charged once, not twice. This is exactly what every modern payment processor implements — Stripe's `Idempotency-Key` HTTP header on `POST /v1/charges` produces the same behavior. The composition's `Invariant 8 — Exactly-once effect within the window` is the contract Stripe documents to merchants.

### Healthcare — bed assignment with double-click

An emergency department coordinator clicks *Assign Bed* on the dashboard. The dashboard hangs; she clicks again. Two `place_hold(bed_307, patient_p41, 2h, ...)` requests arrive at the bed-management service within 800 milliseconds. The dashboard supplies a session-bound idempotency token on every action; both requests carry the same token. The composition accepts the first, returns the bed assignment id; the second hits the idempotency cache and returns the same id. One bed assigned to one patient. The unit's regulatory audit (Joint Commission care-coordination standards) sees one assignment record, not two.

### Retail — inventory reservation with mobile retry

A shopper on flaky mobile WiFi taps *Reserve* on a one-of-one luxury item. The app generates an idempotency token from the cart session id and the item sku, attaches it to the request, and retries on network failure with exponential backoff. The composition guarantees the shopper either reserves the item once and sees a successful reservation, or sees a single resource-unavailable rejection (someone else got there first) regardless of how many retries the network handler attempts — or, where the duplicate check fails closed on an unavailable store, `outcome-unknown(candidates)` naming the hold it can see but cannot pair, which the app resolves before trying again under a fresh token. No phantom *two reservations* state.

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
Check 2.1: An auditor MUST find no idempotency token bound to two commitment ids inside the idempotency window (Invariant 3.1).
Check 3.1: An auditor MUST find EVERY complete entry carrying the result the constituent answered (Wiring decision 1).
Deleted: Check 3.2. Execution Contract Store 1 owns it.
Check 4.1: An auditor MUST find no evicted entry whose token Duplicate Prevention's check answers seen for (Housekeeping 6).
Check 4.2: An auditor MUST find no evicted entry younger than the idempotency window (Housekeeping 5).
Check 5.1: An auditor MUST find EVERY recovered entry marked (Indeterminate outcome 8).
Deleted: Check 5.2. Execution Contract Store 1 owns it: an action's writes commit together, so no entry records outcome-unknown.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Store 2 owns it.
Deleted: External check 2. Execution Contract Store 3 owns it.
External check 3: An auditor needing Duplicate Prevention's fail-closed posture confirmed MUST read the deployment's own configuration (Capability requirement 16).
Deleted: External check 4. Execution Contract Store 3 owns it.
External check 5: An auditor needing the exactly-once claim confirmed MUST read External check 3 (Invariant 8.1).
External check 6: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 7: An auditor needing the idempotency window confirmed MUST read the deployment's own configuration (Capability requirement 1).
External check 8: An auditor needing the token max length confirmed MUST read the deployment's own configuration (Capability requirement 2).
External check 9: An auditor needing the digest function confirmed MUST read the deployment's own configuration (Capability requirement 3).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT guarantee exactly-once for an idempotency token the idempotency window elapsed for.
Non-goal 2: The composition MUST NOT bound the idempotency window.
Non-goal 3: The composition MUST NOT mint an idempotency token.
Non-goal 4: A caller MUST mint an idempotency token.
Non-goal 5: The composition MUST NOT interpret an idempotency token.
Deleted: Non-goal 6. Execution Contract Store 1 owns it.
Non-goal 7: A deployment needing a multi-commitment transaction MUST compose a transaction pattern.
Non-goal 8: The composition MUST NOT resolve the candidates.
Non-goal 9: The composition MUST NOT record an authorization.
Non-goal 10: A deployment needing an authorized call MUST compose Permissions.
Non-goal 11: The composition MUST NOT record an act.
Non-goal 12: A deployment needing an act recorded MUST compose Audit Trail.
Non-goal 13: The composition MUST NOT promise a closure window for a stale entry.
```

---

## Edge cases

### Indeterminate outcome

```
Deleted: Indeterminate outcome 1. Execution Contract Store 1 owns it.
Deleted: Indeterminate outcome 2. Execution Contract Store 1 owns it: an action's writes commit together, so no call finds a pending entry.
Indeterminate outcome 3: The composition MUST compute the candidates from Provisional Commitment's held commitments.
Indeterminate outcome 4: The composition MUST keep a held commitment whose resource AND requester equal the call's in the candidates.
Deleted: Indeterminate outcome 5. Execution Contract Store 1 owns it: an action's writes commit together, so no call finds a pending entry.
Deleted: Indeterminate outcome 6. Execution Contract Store 1 owns it: an action's writes commit together, so no call finds a pending entry.
Indeterminate outcome 7: An outcome-unknown answer MUST carry the candidates.
Indeterminate outcome 8: The composition MUST mark a recovered entry.
Deleted: Indeterminate outcome 9. Execution Contract Store 1 owns it: an action's writes commit together, so no call finds a pending entry.
Indeterminate outcome 10: The composition MUST answer outcome-unknown for a [Place Hold] carrying a seen token AND no entry.
Indeterminate outcome 11: A caller MUST resolve the candidates.
Deleted: Indeterminate outcome 12. Execution Contract Store 1 owns it: an action's writes commit together, so no caller receives a recording failure naming the outcome.
Indeterminate outcome 13: A resolving action MUST run again for a seen token carrying no entry.
Deleted: Indeterminate outcome 14. Execution Contract Store 3 owns it: the store acknowledges a write only once it commits, so no resolving action answers outcome-unknown.
```

Term candidates: for a [Place Hold], the held commitments of the Provisional Commitment instance whose resource and requester equal the call's — a candidates set; the composition's own filter over a constituent read, never a constituent's answer.

Term resolving action: [Confirm] | [Release] | [Expire].

Term recovered entry: a token results entry a re-entry wrote rather than the entry's first invocation.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own an idempotency token's format.
Composition note 3: A deployment MUST own the disposition of the candidates.
Composition note 4: A deployment MUST own the eviction leg's schedule.
Composition note 5: A deployment MUST NOT expose a constituent's own caller surface beside the composition's.
```

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the retry-safe action-wirings it exposes ([Place Hold], [Confirm], [Release], [Expire]), the [Idempotency Token] it introduces on every call, and the fields of the recorded outcome it caches ([Action Type], [Parameters Digest], [Result]) plus its own [Token Collision] and [Outcome Unknown] rejections. It carries one piece of own state — the `token_results` map (classified extraction-pending, the proposed *Idempotency Result Memo* atom) — left as a backticked store token rather than carded as a Type, so its Fields are carded against the plain-noun recorded outcome. References to the constituent atoms and their operations — Provisional Commitment's place_hold/confirm/release/expire, Duplicate Prevention's `check`/`record` — the inherited rejection tokens (resource-unavailable, not-known, not-held, window-elapsed, window-not-elapsed, storage-failure, invalid-request), the entry states and stamps (`recovery`, `pending_at`, `completed_at`), and the deployment configuration knobs (`idempotency_window`, `token_max_length`, `digest_function`, `duplicate_prevention_store`) all remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, token results map, action type, parameters digest, complete entry, eviction leg, idempotency window, blank, fresh request, matching complete entry, candidates, resolving action, recovered entry.

Term record verbs: call, answer, take, read, write, store, key, carry, keep, evict, measure, repair, validate, compare, normalize, case-fold, record, compute, mark, resolve, rest, stand, bind, reach, find, own, discharge, inherit, change, replace, serve, compose, configure, declare, set, supply, mint, interpret, promise, expose, consult, elapse, exceed, land, run, make, guarantee, bound.

Term actors: the composition; the constituents; the transition; a deployment; an auditor; a caller; an operator; an invocation; the eviction leg; an entry; a token; a commitment.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the extraction-pending classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam, the transition and the mechanism-capability pattern. [Provisional Commitment](../atoms/provisional-commitment.md) `Invariant 2` — single resolution, which makes a resolving re-run effect-free. [Duplicate Prevention](../atoms/duplicate-prevention.md) `Invariant 2` — a record starts a guard rather than extending one.

#### Place Hold

The composition action that places a hold, made retry-safe: it validates the [Idempotency Token], and on a first call delegates to Provisional Commitment's place_hold and records the outcome against the token; a retry within the window replays the cached [Result] instead of delegating again. Returns the commitment id, or a cached / delegated rejection.

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

The recorded outcome's copy of the original response — the produced id or ok, or the rejection reason — exactly as returned to the caller on the first call. Every outcome is cached, success or rejection (the cache-the-failure rule).

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

The composition's own rejection for a [Place Hold] whose token Duplicate Prevention reports seen and `token_results` holds no entry for. It carries the candidate Held commitments matching the call's resource and requester, filtered composition-side from Provisional Commitment's exported set; the composition re-delegates nothing (the resolving actions re-run instead, effect-free by Provisional Commitment Invariant 2). Uncached (Wiring decision 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: outcome-unknown

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

---

## Standards references

This composition draws on:

- **IETF draft-ietf-httpapi-idempotency-key-header** — the HTTP idempotency-key convention; an industry-standard wire format for the idempotency token.
- **ISO 20022 (financial messaging)** — `BizMsgIdr` and related message-uniqueness identifiers; the financial-industry standard for at-most-once message semantics.
- **HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) `Bundle.identifier`, `MessageHeader.id`** — healthcare-industry standard for at-most-once message processing.
- **Stripe Idempotency-Key, Adyen idempotency header, AWS request-ID** — de-facto industry conventions; this composition formalizes what they all implement.
- **PCI DSS Requirement 10 (logging and monitoring)** — composing with Event Log, the commitment record and the token-mapping together produce the audit-evidence PCI requires.

The two atoms it composes carry their own standards inheritance — Provisional Commitment (ISO 9001 — the International Organization for Standardization quality-management standard — section 8.5.2 and section 8.5.4; Basel III BCBS 238 — Basel Committee on Banking Supervision liquidity rules; Joint Commission; IATA — International Air Transport Association; PCI DSS; GDPR — EU General Data Protection Regulation — Art. 30; SOX — Sarbanes-Oxley Act — section 404; HIPAA — Health Insurance Portability and Accountability Act — section 164.312(b)) and Duplicate Prevention (IETF HTTP idempotency-key draft, payment-processor idempotency conventions, message-queue exactly-once-within-window literature).

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
- 2026-08-30-a · refining · formal · the model has no eviction leg as a second process over one token and no `outcome-unknown` arm; the twin's early-eviction hazard is now the leg's (iii) → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/idempotent-reservation.md`; the migration, the council read's collapse, where the classification is carried, the family placement and the regeneration that got it here are in [its history](./idempotent-reservation.hist.md).

- **2026-08-30 — The intent is written before the act, the writer is one per token, and what cannot be re-derived is not re-run.** *Chose:* a pending entry written to `token_results` before Provisional Commitment is called, with a re-entry arm that — finding it under the token's critical section — names candidate holds for [Place Hold] and re-runs only the resolving actions, whose second call is effect-free by the constituent's single-resolution invariant; `per_token_serialization` declared as an instance capability requirement (released on return or death; a lease exactly `reservation_completion_bound` long whose expiry is the invocation's terminus) and taken by the eviction leg too, so the invocation and the leg never both write one token; the leg bounded at both edges — nothing younger than the bound, eviction only past the window and only for a `not-seen` token; `recording-failure(intent | outcome)` on every signature, the `outcome` position carrying the committed id, and Provisional Commitment's storage-failure, not-known and window-not-elapsed transcribed; Duplicate Prevention's disclaimed durability and its fail-open/fail-closed choice declared as `duplicate_prevention_store`, condition (c) of Invariant 8; `token_results` durability housed in Configuration; the claimed atomicity between the two stores replaced by write order, five reachable partials, and a recovery for each; and, from the closure check the same day, the complete-entry arm guarded by the window on the composition's own stamps (an expired `not-seen` entry evicted in place, so Invariant 7's fresh request does not wait on the leg), `pending_at` kept on the complete entry with `completed_at` beside it, the critical section declared shared across every instance sharing the store, `commitment_store_acknowledged_atomic` transcribing the constituent's own write obligation so that storage-failure is cached as definitive only where it is, and the pending arm's empty-candidates case proceeding as never delegated. *Over:* "persisted atomically with each successful action" as an implementation requirement, an eviction surface that read an in-flight invocation as evictable, a serialization the spec "assumed", and four signatures that told a caller nothing was committed when a commitment existed. *Because:* the constituent's record carries no token, so a crash between the act and its record leaves an outcome no retry can re-derive — and a retry that re-delegates is the double this composition exists to prevent; two writers over one token land two results; and a caller who cannot tell intent from `outcome` re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md` and the section titled *Recovery commits under a declared service identity* in `pressure-testing.md` of 2026-08-29).

- **2026-10-20 — The store's guarantees cited, not restated, the pending intent and the per-token critical section among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 18), and the forty-four rules that restated it, or existed only for a store that could lose, split or forget a write, tombstoned to their owner — to Store 1, under which a state-changing action's entry, Provisional Commitment's write and Duplicate Prevention's record commit together: the pending entry written before the constituent call and overwritten after it, with the pending instant kept across the overwrite and its check (Composition state 4, 5, 7, Action wiring 13, Check 3.2), the recording failure at the intent, the result write's retry within the reservation completion bound, the recording failure at the outcome with the answer it carried, the caller's bar on a fresh token after it and the bar on recording one (Action wiring 14, 17 through 19, Indeterminate outcome 12, Wiring decision 5), the result written before the guard and the guard recorded again beside a complete entry (Action wiring 20, 11), the pending arm — an act that may have happened, no second delegation, empty candidates proceeding, the outcome-unknown overwrite, the resolving re-run — with the check of outcome-unknown entries (Indeterminate outcome 1, 2, 5, 6, 9, Check 5.2), the eviction leg's lower edge (Housekeeping 3) and the disclaimer of atomicity across the token results map and the commitment store (Non-goal 6); to Store 1 and Store 2, the reservation completion bound and the window's margin over it (Capability requirement 9 through 11); to Store 2, under which an action's reads of a token and the writes they decide are one transaction, the host's critical section per token with its supply, release, lapse and holding rules, the eviction leg's take and skip, and its external check (Capability requirement 5 through 8, Action wiring 2 through 6, Housekeeping 1, 2, External check 1); to Store 3, the durability across a restart of the token results map and of Duplicate Prevention's recorded set, the acknowledgement only after a write is durable, the commitment store's declared atomic acknowledgement and the external checks of the first and the last (Capability requirement 12, 14, 15, 17, External check 2, 4), with the resolving action's outcome-unknown, which only a commitment store that did not acknowledge atomically reached (Indeterminate outcome 14); and to Store 3 and Store 4, an entry kept for its durability term (Capability requirement 13). With them every signature loses recording-failure and the resolving actions lose outcome-unknown, Invariant 8.1 conditions the exactly-once claim on Duplicate Prevention's store obligations alone, and External check 5 reads External check 3 alone; rules 139 to 96. *Over:* a pending intent written to `token_results` before the act, a host-supplied critical section per token released on return or death with a lease as the invocation's terminus, a write order across two stores with a recovery for each reachable partial, and a re-entry arm naming candidates for an act no record could pair — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: the token results map, Provisional Commitment's commitment and Duplicate Prevention's recorded set are one store, so an action's entry, its act and its guard commit together or not at all, no reader sees a pending entry, and a storage failure anywhere in the action commits nothing and answers storage-failure. Store 2 reads the state an action's guards decide on inside the transaction that writes the action's effects, an absent entry included, so a second call carrying one token reads what the first committed and replays it; the maintainer ruled 2026-10-20 that it covers a guard decided across a lease check whose grant lives in the one store, the lease keeping its job only for an act outside the store, and nothing in an invocation is an act outside the store: the critical section kept a second call off the first one's writes, and every one of them is a store write — the entry, Provisional Commitment's commitment and Duplicate Prevention's record — while the registry's own section over the availability read stays Provisional Commitment's (its Capability requirement 3 through 5). The other calls a rule decided: the rewrite asks of every census line written before the ruling of 2026-10-20 02:03Z whether a kept answer still reaches the partial it served, and none does here, since Provisional Commitment's refusals write nothing and are recorded with the entry and the guard, and Duplicate Prevention's record never refuses; the arm for a token Duplicate Prevention reports seen with no entry stays (Indeterminate outcome 10, 13, Wiring decision 4), since Duplicate Prevention's fail-closed answer for an unavailable store still reaches it (Capability requirement 16), and with it the candidates, their carriage and the recovered entry's mark (Indeterminate outcome 3, 4, 7, 8, Check 5.1); the empty-candidates case belongs to the pending arm, as the turn of 2026-08-30 says, and goes with it; a code no kept rule answers leaves its signature; and no rule reads a record as it stood at a past commit or compares two commits, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is otherwise unchanged.

NOTE: End of Idempotent Reservation.

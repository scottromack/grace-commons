---
title: Idempotent Reservation
id: 22
audience: common
parent: Conceptual Compositions
nav_order: 2
has_toc: true
toc: true
---

# Idempotent Reservation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Idempotent Reservation makes reservation actions safe to retry. It combines two simpler patterns: one that manages a held resource (Provisional Commitment — a resource held, then Confirmed, Released, or Expired) and one that spots repeated submissions within a set time window (Duplicate Prevention).

The problem it solves is everyday over unreliable networks: a client asks to hold a resource, the reply gets lost, the client retries — and without protection the retry creates a second, accidental hold.

The fix is a token the caller attaches to every action: if the same token has been seen within the window, the system returns the original result (same identifier, same outcome) instead of doing the action again.

The result is "exactly-once" behavior — the underlying reservation sees one real action no matter how many times it is retried inside the window, a token is locked to one specific operation (reusing it for something else is rejected), and so a single intended action can never become a double-hold. (Guarantees that appear only when patterns are combined are called emergent guarantees.)

This is the mechanism payment processors use to stop a retried charge from billing twice, and it applies anywhere a duplicated action is a real defect — payments, hospital resource allocation, inventory reservation.

<details markdown="block">
<summary>WHY</summary>

Real reservation systems run over unreliable networks. A client submits [Place Hold]; the network drops the response before it arrives; the client retries. Without idempotency, the second call produces a *second* commitment — two distinct ids, two distinct audit trails, one unintended double-hold of the resource. The same hazard recurs for [Confirm], [Release], and [Expire]: a retry past Provisional Commitment's terminal-absorption boundary returns not-held, which the caller cannot distinguish from a *new* failure without out-of-band information.

This composition solves the problem at the composition layer rather than absorbing it into Provisional Commitment. The caller supplies an **idempotency token** on every state-changing call. The composition checks the token against a [Duplicate Prevention](../atoms/duplicate-prevention.md) instance; if the token has been seen within the window (the configurable time period during which repeated tokens are detected and deduplicated), the composition returns the *original* response (the same commitment id, the same ok, the same rejection reason) without invoking [Provisional Commitment](../atoms/provisional-commitment.md) a second time — with one exception Invariant 2 states: a resolving action whose token Duplicate Prevention reports seen while the composition holds no answer for it is re-run (Indeterminate outcome 13), effect-free where an earlier run committed, by the constituent's own single-resolution invariant. The constituent atoms are unchanged; the composition is the wiring.

This is the composition payment processors run in production today — Stripe's `Idempotency-Key`, Adyen's idempotency header, ISO 20022's (the International Organization for Standardization standard for financial-messaging data) message uniqueness identifier, the IETF (Internet Engineering Task Force — the body that develops internet standards) draft idempotency-key spec. Different vocabularies; identical mechanic.

</details>

### Composes

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

### Wiring decision

```
Wiring decision 1: The composition MUST record EVERY constituent answer to a call carrying an idempotency token against the token.
Wiring decision 2: The composition MUST record a constituent's rejection against the token.
Wiring decision 3: The composition MUST NOT record an answer for a malformed idempotency token.
Wiring decision 4: The composition MUST NOT record a [Place Hold] answer the composition returned on a seen token carrying no entry.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* One token, one result: the composition records against the token every answer a constituent gives, a rejection as much as a success, and every later call carrying the token inside the idempotency window receives that answer.

*Likely objection.* Caching the failure is the non-obvious half. If a first [Place Hold] answers resource-unavailable, a retry might succeed — the resource may have freed in between — and a registry-unavailable answer stops being true once the host can read the registry again.

*Mechanism that resolves it.* A retry allowed to re-call the constituent would show the caller two answers to what they meant as one operation, the double this composition exists to prevent, and the decision lives here because neither constituent can make it: Provisional Commitment's record carries no token, and Duplicate Prevention remembers an identity, not an answer. The caller decides whether to attempt the act again under a **fresh** token, and the new attempt doubles nothing, since a refused [Place Hold] records no commitment (Provisional Commitment Operation 31).

*Result.* *Same token, same result*, a rejection included. Three exclusions share one reason: the composition did not act, so it holds nothing to cache. A malformed token is not a token; a `seen` token with no entry means the composition recorded nothing and the next `check` may answer differently; and a storage failure commits nothing at all (Execution Contract Constituent failure 1).

</details>

## What it keeps

### Composition state

```
Composition state 1: The composition MUST store a token results map.
Composition state 2: The composition MUST key the token results map by idempotency token.
Composition state 3: An entry MUST carry an action type, a parameters digest, a result, a pending instant AND a recovery mark.
Composition state 6: EXACTLY ONE invocation MUST write an entry per act (Indeterminate outcome 13).
Composition state 9: The composition MUST take the parameters digest from the seam (Execution Contract Logic confinement 8).
```

Term token results map: the composition's own map from an idempotency token to a recorded outcome — a token results map; the element the section titled Composition state in `execution-contract.md` classifies extraction-pending.

Term token results entry: one idempotency token's recorded outcome — a [Token Results Entry].

#### Token Results Entry

One idempotency token's recorded outcome, carrying an action type, a parameters digest, a result, a pending instant and a recovery mark.

Kind: Type

Term action type: place_hold | confirm | release | expire.

#### Action Type

The recorded outcome's record of which logical operation the token was bound to — one of place_hold, confirm, release, expire. A retry whose action differs from the recorded one is rejected [Token Collision] (Invariant 4).

Kind:       Field
Field of:   Token Results Entry
Role:       the token's bound operation
Projection: action_type

Term recovery mark: recovered | first — recovered on the entry a re-entry writes (Indeterminate outcome 13), first on the entry a fresh request writes.

Term parameters digest: the collision-resistant digest of a call's non-token parameters, computed at the seam by the configured digest function — a [Parameters Digest].

#### Parameters Digest

The recorded outcome's collision-resistant digest of the non-token call parameters, computed at the composition's I/O seam and injected. A retry whose digest differs from the recorded one is rejected [Token Collision]; digest-function drift across replicas misclassifies legitimate retries.

Kind:       Field
Field of:   Token Results Entry
Role:       the token's bound parameters
Projection: parameters_digest

#### Result

The recorded outcome's copy of the original response — the produced id or ok, or the rejection reason — exactly as returned to the caller on the first call. Every constituent answer is cached, success or rejection (the cache-the-failure rule), save a storage failure, which commits nothing (Execution Contract Constituent failure 1).

Kind:       Field
Field of:   Token Results Entry
Role:       the replayed response
Projection: result

Term pending instant: the entry's stamp, the now its writing invocation read at the seam (Execution Contract Logic confinement 11) — the instant the idempotency window measures from; a recovered entry carries its re-entry's now (the walkthrough's `pending_at`).

Term window end: (pending instant + idempotency window) — the instant an entry's idempotency window elapses at; the window has elapsed for the entry at its window end and after it (Execution Contract Logic confinement 9).

Term complete entry: a token results entry carrying a recorded result — every entry, since an action's writes commit together (Execution Contract Database 1) and no entry is pending.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the token results map: extraction-pending, the proposed atom an *Idempotency Result Memo* (token → result, write-once, window-governed eviction), opened as a roadmap proposal (Composition state 1).

## What people do

### Every action

#### Idempotency Token

The caller-supplied key attached to every state-changing call. The composition introduces it (Provisional Commitment's actions do not carry it); it keys the recorded outcome and is the identity recorded in Duplicate Prevention. Treated as opaque, compared byte-exact, and validated (non-empty, within `token_max_length`) before any constituent is consulted.

Kind:         Parameter
Parameter of: the state-changing actions ([Place Hold], [Confirm], [Release], [Expire])
Role:         the idempotency key (also the recorded-outcome key and the Duplicate Prevention identity)
Projection:   idempotency_token

```
Action wiring 1: [Place Hold], [Confirm], [Release] AND [Expire] MUST take an idempotency token.
Action wiring 7: IF a live entry's action type differs from the call's action type THEN the composition MUST answer token-collision.
Action wiring 8: IF a live entry's parameters digest differs from the call's parameters digest THEN the composition MUST answer token-collision.
Action wiring 9: The composition MUST answer a matching complete entry's result.
Action wiring 10: The composition MUST NOT call a constituent for a matching complete entry.
Action wiring 12: The composition MUST evict a complete entry the idempotency window elapsed for AND Duplicate Prevention's check answers not-seen for.
Action wiring 21: The composition MUST answer Provisional Commitment's answer to the caller.
Action wiring 25: The composition MUST call Duplicate Prevention's record for EVERY result recorded against an idempotency token (Wiring decision 1).
Action wiring 27: IF Duplicate Prevention's check answers state-unavailable THEN the composition MUST resolve the check as seen (Capability requirement 16, Duplicate Prevention Non-goal 1, Execution Contract Constituent failure 3).
Action wiring 28: IF Duplicate Prevention's check answers state-unavailable THEN the composition MUST NOT answer state-unavailable for the check.
```

Term live entry: an entry the call finds and does not evict (Action wiring 12).

Term fresh request: a call finding no live entry AND Duplicate Prevention's check answering not-seen.

Term admitted first invocation: a fresh request the action admits — the invocation Composes 7 and Invariant 8.2 count; a re-entry (Indeterminate outcome 13) is not one.

Term matching complete entry: a live complete entry whose action type AND parameters digest equal the call's.

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

### Place Hold

The composition action that places a hold, made retry-safe: it validates the [Idempotency Token], and on a first call delegates to Provisional Commitment's place_hold and records the outcome against the token; a retry within the window replays the cached [Result] instead of delegating again. Returns the commitment id, or a cached / delegated rejection.

Kind: Operation

```
place_hold(resource, requester, duration, idempotency_token)
  answers id
  refuses invalid-request | token-collision | registry-unavailable | resource-unavailable | storage-failure | outcome-unknown(candidates)
```

### Confirm

The retry-safe confirm action — same token-check-then-delegate wiring as [Place Hold], delegating to Provisional Commitment's confirm. A within-window retry returns the cached ok, hiding the terminal-absorption not-held a direct retry would hit; a token bound to a different [Action Type] is rejected [Token Collision].

Kind: Operation

```
confirm(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure
```

### Release

The retry-safe release action — same wiring, delegating to Provisional Commitment's release. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

```
release(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-elapsed | storage-failure
```

### Expire

The retry-safe expire action — same wiring, delegating to Provisional Commitment's expire. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

```
expire(id, idempotency_token)
  answers ok
  refuses invalid-request | token-collision | not-known | not-held | window-not-elapsed | storage-failure
```

### Read

```
read()
  answers every commitment
```

```
Action wiring 22: A read-only query MUST NOT take an idempotency token.
Action wiring 23: A read-only query MUST NOT consult the token results map.
Action wiring 26: A read MUST answer every commitment Provisional Commitment's read answers.
```

## What is and what should never be (Invariants)

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Idempotent place hold within the window.**
  ```
  Invariant 1.1: Two place_hold calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  ```
- **Invariant 2 — Idempotent state transitions within the window.**
  ```
  Invariant 2.1: Two resolving calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 2.2: The composition MUST NOT call a constituent twice for one idempotency token inside the idempotency window, a resolving action's re-entry excepted (Indeterminate outcome 13).
  Invariant 2.3: A resolving action's re-entry MUST rest on Provisional Commitment Invariant 2.
  ```
- **Invariant 3 — Token to commitment, one to one.**
  ```
  Invariant 3.1: An idempotency token inside the idempotency window MUST NOT bind two commitment ids.
  ```
- **Invariant 4 — Token action binding.**
  ```
  Invariant 4.1: An idempotency token inside the idempotency window MUST bind EXACTLY ONE action type.
  Invariant 4.2: An idempotency token inside the idempotency window MUST bind EXACTLY ONE parameters digest.
  ```
- **Invariant 7 — Token expiry releases the binding.**
  ```
  Invariant 7.1: The eviction leg MUST evict an entry ONLY AFTER Duplicate Prevention's guard elapsed AND the idempotency window elapsed since the entry's pending instant.
  Invariant 7.2: A call carrying an evicted idempotency token MUST stand as a fresh request.
  ```
- **Invariant 8 — Exactly-once effect within the window.**
  ```
  Invariant 8.1: The composition MUST make the exactly-once claim ONLY IF the deployment supplies Duplicate Prevention's database PER Duplicate Prevention Capability requirement 2.
  Invariant 8.2: An admitted first invocation MUST reach Provisional Commitment EXACTLY ONE time inside the idempotency window.
  ```

## When something happens

### Housekeeping

```
Housekeeping 4: The eviction leg MUST evict an entry ONLY IF Duplicate Prevention's check answers not-seen.
Housekeeping 5: The eviction leg MUST evict an entry ONLY IF the idempotency window elapsed since the entry's pending instant.
Housekeeping 6: The eviction leg MUST NOT evict a seen token's entry.
Housekeeping 7: The eviction leg MUST NOT repair an entry.
Housekeeping 8: The eviction leg MUST NOT call a constituent's write.
Housekeeping 9: The eviction leg MUST measure an instant against the composition's own seam reading.
```

Term eviction leg: the leg the Housekeeping rules state — this composition's own, over the token entries the leg evicts.

### Indeterminate outcome

```
Indeterminate outcome 3: The composition MUST compute the candidates from Provisional Commitment's held commitments.
Indeterminate outcome 4: The composition MUST keep a held commitment whose resource AND requester equal the call's in the candidates.
Indeterminate outcome 7: An outcome-unknown answer MUST carry the candidates.
Indeterminate outcome 8: The composition MUST mark a recovered entry.
Indeterminate outcome 10: The composition MUST answer outcome-unknown for a [Place Hold] carrying a seen token AND no entry.
Indeterminate outcome 11: A caller MUST resolve the candidates.
Indeterminate outcome 13: A resolving action MUST run again for a seen token carrying no entry.
```

Term candidates: for a [Place Hold], the held commitments of the Provisional Commitment instance whose resource and requester equal the call's — a candidates set; the composition's own filter over a constituent read, never a constituent's answer. The set holds at most one commitment, since the registry refuses a resource a held commitment carries (Provisional Commitment Capability requirement 17, Operation 5).

Term resolving action: [Confirm] | [Release] | [Expire].

Term recovered entry: a token results entry a re-entry wrote rather than the entry's first invocation.

## While something is so

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank idempotency token.
Primitive policy 2: The composition MUST answer invalid-request for an idempotency token EXCEEDS the token max length.
Primitive policy 3: The composition MUST compare an idempotency token byte-exact.
Primitive policy 4: The composition MUST NOT normalize an idempotency token.
Primitive policy 5: The composition MUST NOT case-fold an idempotency token.
Primitive policy 6: The composition MUST call Duplicate Prevention's check ONLY AFTER the idempotency token clears the boundary predicate.
```

Term boundary predicate: the test an idempotency token clears before Duplicate Prevention's check — the token is not blank AND does not exceed the token max length (Primitive policy 1, Primitive policy 2).

## Optional

```
Capability requirement 1: A deployment MUST set the idempotency window PER Execution Contract Logic confinement 17.
Capability requirement 2: A deployment MAY declare the token max length PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 3: A deployment MUST set the digest function PER Execution Contract Logic confinement 17.
Capability requirement 4: A deployment MUST set the digest function alike for EVERY call of one instance.
Capability requirement 16: A deployment MUST resolve Duplicate Prevention's check fail-closed.
Capability requirement 18: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
Capability requirement 19: A deployment MUST set the idempotency window alike for EVERY call AND EVERY run of the eviction leg of one instance (Duplicate Prevention Operation 11).
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token, set by the deployment with no default to cover the slowest legitimate retry of the most critical action, and more than zero, as Duplicate Prevention's window duration is — an idempotency window.

Term token max length: the bound on an idempotency token's length in Unicode code points; 1,024 code points where a deployment declares none, the corpus's default for text — a default cap a deployment may override as Execution Contract Input 2 allows (Capability requirement 2).

Term digest function: the collision-resistant hash function and serialization convention computing the parameters digest at the seam, set by the deployment with no default.

## Left to others

```
Non-goal 1: The composition MUST NOT guarantee exactly-once for an idempotency token the idempotency window elapsed for.
Non-goal 2: The composition MUST NOT bound the idempotency window.
Non-goal 3: The composition MUST NOT mint an idempotency token.
Non-goal 4: A caller MUST mint an idempotency token.
Non-goal 5: The composition MUST NOT interpret an idempotency token.
Non-goal 7: A deployment needing a multi-commitment transaction MUST compose a transaction pattern.
Non-goal 8: The composition MUST NOT resolve the candidates.
Non-goal 9: The composition MUST NOT record an authorization.
Non-goal 10: A deployment needing an authorized call MUST compose Permissions.
Non-goal 11: The composition MUST NOT record an act.
Non-goal 12: A deployment needing an act recorded MUST compose Audit Trail.
Non-goal 13: The composition MUST NOT promise a closure window for a stale entry.
```

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own an idempotency token's format.
Composition note 3: A deployment MUST own the disposition of the candidates.
Composition note 4: A deployment MUST own the eviction leg's schedule.
Composition note 5: A deployment MUST NOT expose a constituent's own caller surface beside the composition's.
```

## Example

### Walkthrough

A client behind a flaky network reserves a hotel room. The composition is configured with a 10-minute idempotency window.

1. **First call:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → `check(idem_x73a) → not-seen`, no entry; delegates to Provisional Commitment; receives `rm_b4c`. Writes `token_results[idem_x73a] = (place_hold, digest_α, rm_b4c, pending_at, first)` and calls `DuplicatePrevention.record(idem_x73a)`. Returns `rm_b4c` to the client. State: `rm_b4c` Held.
2. **Network drops the response. Client retries:** `place_hold(room_307, guest_g91, 24h, idem_x73a)` → `check(idem_x73a) → seen`; lookup matches; returns cached `rm_b4c`. *Provisional Commitment is not invoked.* No second commitment is created.
3. **Client retries twice more:** identical outcome. Provisional Commitment still sees only one [Place Hold].
4. **Two hours later, client confirms** with a fresh token: `confirm(rm_b4c, idem_y22)` → `check(idem_y22) → not-seen`; delegates to `ProvisionalCommitment.confirm(rm_b4c)` → ok. Records and returns ok. State: `rm_b4c` Confirmed.
5. **Client retries the confirm** (browser back button or replay): `confirm(rm_b4c, idem_y22)` → `check → seen`; returns cached ok. Crucially, the second call does *not* return not-held — which is what would happen if the retry hit Provisional Commitment directly, because `rm_b4c` has already moved Held → Confirmed. The idempotency cache hides the terminal-absorption rejection from the legitimate retry.
6. **Eleven minutes later, client retries the original [Place Hold]** with `idem_x73a`. The 10-minute window has elapsed, and Duplicate Prevention's guard on `idem_x73a` with it: `check → not-seen`; once the eviction leg has run, `token_results[idem_x73a]` is gone and the call is a fresh request — and where it has not yet run (its timing is not promised), the complete-entry arm finds an entry past the window with a `not-seen` token, evicts it in place and proceeds identically. Either way the composition delegates afresh. Provisional Commitment receives [Place Hold] against `room_307`; the room is no longer hold-able because `rm_b4c` is in Confirmed; it returns resource-unavailable. The composition caches *that* rejection against the new occurrence of the token. The client sees resource-unavailable — accurately reflecting the current state of the resource, not the stale identity of an old token.

### Banking — credit-hold authorization with retry

A merchant POS (point-of-sale terminal) submits a $250 authorization with an idempotency key (ISO 20022 BizMsgIdr or scheme-defined equivalent). The acquirer's network glitches; the POS retries within seconds. The composition guarantees the authorization hold is placed once, not twice; the charge is a later resolving action under its own token. Stripe's `Idempotency-Key` HTTP header on `POST /v1/charges` returns the same result for a retried request; the composition's `Invariant 8 — Exactly-once effect within the window` states the exactly-once effect that behavior serves.

### Healthcare — bed assignment with double-click

An emergency department coordinator clicks *Assign Bed* on the dashboard. The dashboard hangs; she clicks again. Two `place_hold(bed_307, patient_p41, 2h, ...)` requests arrive at the bed-management service within 800 milliseconds. The dashboard supplies a session-bound idempotency token on every action; both requests carry the same token. The composition accepts the first, returns the bed assignment id; the second hits the idempotency cache and returns the same id. One bed assigned to one patient. The unit's regulatory audit (Joint Commission care-coordination standards) sees one assignment record, not two.

### Retail — inventory reservation with mobile retry

A shopper on flaky mobile WiFi taps *Reserve* on a one-of-one luxury item. The app generates an idempotency token from the cart session id and the item sku, attaches it to the request, and retries on network failure with exponential backoff. The composition guarantees the shopper either reserves the item once and sees a successful reservation, or sees a single resource-unavailable rejection (someone else got there first) regardless of how many retries the network handler attempts — or, where the duplicate check fails closed on an unavailable database, `outcome-unknown(candidates)` naming the holds it can see but cannot pair, which the app resolves before trying again under a fresh token. No phantom *two reservations* state.

### Airline — seat hold with session replay

A travel agency's booking system replays the previous hour's requests after a database failover. Every hold request carries the original idempotency token. The reservation system replays correctly: holds that were already produced return their original commitment ids; holds whose tokens have since expired produce fresh commitments only if their seats are still available. No seat is held twice. The composition's `Invariant 7 — Token expiry releases the binding` is the failure mode the agency's operations team must understand: tokens older than the window are treated as fresh requests.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts, beyond happy-path:

- **Regulator audit — "show me every double-charge."** An auditor reads the composition's read, which answers every commitment with its stored fields, and joins the token results map to it on the commitment id each [Place Hold] entry records; inside the window the join carries one commitment per token (`Invariant 3 — Token to commitment, one to one`). A filter over the commitments alone for a shared `(resource, requester, placed_at-near)` signature cannot tell *legitimate sequential holds* (separate logical operations with separate tokens) from *retry-induced doubles*, because a commitment record carries no token; the map separates them. Outside the window the map may still hold the token's entry until the eviction leg runs, and a call carrying the token stands as a fresh request (Invariant 7.2), so the join no longer reaches a retry and the guarantee ends with the window (Non-goal 1).
- **Disputed transaction — "you charged me twice."** The investigator inspects the composition's `token_results` map (or its persistent journal). If two of the customer's submitted requests carried the *same* token, the composition's cache produced one commitment and replayed the response — there is no double-spend to dispute. If the customer's client generated *different* tokens for what they intended as the same operation, the composition correctly processed them as independent operations; the dispute belongs to the client's token-generation logic, not to the reservation system.
- **Replay attack — adversary captures and replays a token.** An adversary captures an in-flight request and replays it later within the window. The composition correctly returns the cached result. The replay produces no new state change — `Invariant 2 — Idempotent state transitions within the window`. Replays *outside* the window are treated as fresh requests; the adversary may succeed in placing a new commitment if the resource is available and they hold valid credentials, but that is an authentication / authorization failure (see [Actor Identity](../atoms/actor-identity.md)), not an idempotency failure.
- **Token reuse collision — caller accidentally reuses a token across two operations.** A developer reuses `idem_x73a` (originally used for `place_hold(room_307, ...)`) in a subsequent `confirm(rm_b4c, idem_x73a)` call. The composition checks: `DuplicatePrevention.check(idem_x73a) → seen`; looks up `token_results[idem_x73a]` and finds `action_type = place_hold`. Current call's `action_type = confirm` — mismatch. Returns token-collision. No state change occurs. The caller must use a fresh token for the confirm. Invariant 4 (*Token action binding*) is the structural guarantee; [Token Collision] is its observable form.

## Source

This composition draws on:

- **IETF draft-ietf-httpapi-idempotency-key-header** — the HTTP idempotency-key convention; an industry-standard wire format for the idempotency token.
- **ISO 20022 (financial messaging)** — `BizMsgIdr` and related message-uniqueness identifiers; the financial-industry standard for at-most-once message semantics.
- **HL7 (Health Level Seven) FHIR (Fast Healthcare Interoperability Resources) `Bundle.identifier`, `MessageHeader.id`** — healthcare-industry standard for at-most-once message processing.
- **Stripe Idempotency-Key, Adyen idempotency header, AWS (Amazon Web Services) request-ID** — de-facto industry conventions; this composition formalizes what they all implement.
- **PCI DSS (Payment Card Industry Data Security Standard) Requirement 10 (logging and monitoring)** — a deployment that composes Event Log beside this composition (Event Log is no constituent of it) gets, from the commitment record and the token-mapping together, the audit-evidence PCI requires.

The two atoms it composes carry their own standards inheritance — Provisional Commitment (ISO 9001 — the International Organization for Standardization quality-management standard — section 8.5.2 and section 8.5.4; Basel III BCBS 238 — Basel Committee on Banking Supervision liquidity rules; Joint Commission; IATA — International Air Transport Association; PCI DSS; GDPR — EU General Data Protection Regulation — Art. 30; SOX — Sarbanes-Oxley Act — section 404; HIPAA — Health Insurance Portability and Accountability Act — section 164.312(b)) and Duplicate Prevention (IETF HTTP idempotency-key draft, payment-processor idempotency conventions, message-queue exactly-once-within-window literature).

It inherits from:

- **Stripe's idempotency design document** — the public formalization of *same key, same result* as the contract that makes retry-safe APIs practical.
- **Distributed-systems exactly-once-delivery literature** — Kafka's `enable.idempotence`, RabbitMQ's deduplication, the broader academic line on at-most-once messaging.
- **Pat Helland, *Idempotence is Not a Medical Condition*** — the seminal write-up on idempotency as an API-design discipline rather than an infrastructure trick.

## Proof

### Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the commitment records, the recorded set and the token results map.

#### Conformance checks

```
Check 1.1: An auditor MUST find no two committed versions of one idempotency token's entries carrying one pending instant AND two action types (Execution Contract Database 5) (Invariant 4.1).
Check 1.2: An auditor MUST find no two committed versions of one idempotency token's entries carrying one pending instant AND two parameters digests (Execution Contract Database 5) (Invariant 4.2).
Check 2.1: An auditor MUST find no idempotency token bound to two commitment ids inside the idempotency window (Invariant 3.1).
Check 3.1: An auditor MUST find EVERY complete entry carrying the result the constituent answered (Wiring decision 1).
Check 4.1: An auditor MUST find no evicted entry, read at the evicted entry's last version (Execution Contract Database 5), whose token Duplicate Prevention's check answered seen for at the commit that evicted the entry (Housekeeping 6).
Check 4.2: An auditor MUST find no evicted entry, read at the evicted entry's last version (Execution Contract Database 5), younger than the idempotency window (Housekeeping 5).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 3: An auditor needing Duplicate Prevention's fail-closed posture confirmed MUST read the deployment's own configuration (Capability requirement 16).
External check 5: An auditor needing the exactly-once claim confirmed MUST read the deployment's own database AND External check 3 (Invariant 8.1).
External check 6: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 7: An auditor needing the idempotency window confirmed MUST read the deployment's own configuration (Capability requirement 1, Capability requirement 19).
External check 8: An auditor needing the token max length confirmed MUST read the cap the instance holds PER Execution Contract Input 2 (Capability requirement 2).
External check 9: An auditor needing the digest function confirmed MUST read the deployment's own configuration (Capability requirement 3).
```

### Vocabulary

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the pattern — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](https://github.com/scottromack/grace-commons/blob/main/tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the retry-safe action-wirings it exposes ([Place Hold], [Confirm], [Release], [Expire]), the [Idempotency Token] it introduces on every call, and the fields of the recorded outcome it caches ([Action Type], [Parameters Digest], [Result]) plus its own [Token Collision] and [Outcome Unknown] rejections. It carries one piece of own state — the `token_results` map (classified extraction-pending, the proposed *Idempotency Result Memo* atom) — left as a backticked record token rather than carded as a Type, so its Fields are carded against the plain-noun recorded outcome. References to the constituent atoms and their operations — Provisional Commitment's place_hold/confirm/release/expire, Duplicate Prevention's `check`/`record` — the inherited rejection tokens (resource-unavailable, not-known, not-held, window-elapsed, window-not-elapsed, storage-failure, invalid-request), the entry's stamp and mark (`pending_at`, `recovery`), and the deployment configuration knobs (`idempotency_window`, `token_max_length`, `digest_function`) all remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, token results map, token results entry, action type, recovery mark, pending instant, parameters digest, complete entry, eviction leg, idempotency window, window end, token max length, digest function, boundary predicate, blank, live entry, fresh request, admitted first invocation, matching complete entry, candidates, resolving action, recovered entry.

Term record verbs: call, answer, take, read, write, store, key, carry, keep, evict, measure, repair, validate, compare, normalize, case-fold, record, compute, mark, resolve, rest, stand, bind, reach, find, own, discharge, inherit, change, replace, serve, compose, configure, declare, set, supply, mint, interpret, promise, expose, consult, elapse, exceed, land, run, make, guarantee, bound.

Term actors: the composition; the constituents; the transition; a deployment; an auditor; a caller; an operator; an invocation; a read-only query; the eviction leg; an entry; a token; a commitment.

Term records: token results entry — one idempotency token's recorded outcome, carrying an action type, a parameters digest, a result, a pending instant and a recovery mark.

Term value sets: action type, recovery mark and resolving action, each declared where the section that owns it declares it.

Term bounds: idempotency window (idempotency_window), token max length (token_max_length; 1,024 code points where a deployment declares none).

Term cadences: empty.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the extraction-pending classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam, the transition and the mechanism-capability pattern. [Provisional Commitment](../atoms/provisional-commitment.md) `Invariant 2` — single resolution, which makes a resolving re-run effect-free. [Duplicate Prevention](../atoms/duplicate-prevention.md) `Invariant 2` — a record starts a guard rather than extending one.

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
[Token Results Entry]: #token-results-entry

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — idempotent-reservation.tla + 13 twins, re-derived 2026-11-08 (it was verified 2026-06-03 over one effect counter and an unguarded early eviction): the token's entry with its action type, parameters digest and recovery mark; Duplicate Prevention's guard on its own clock and its outage, read fail-closed; the eviction leg as the second process beside the calls, and the five arms a call takes (token-collision, replay, fresh request, outcome-unknown, re-entry); Invariants 1.1, 2.1 to 2.3, 3.1, 4.1, 4.2, 7.1, 7.2 and 8.2 checked, with Check 4.1 and 4.2, Composes 7, Wiring decision 2 and Indeterminate outcome 3, 4, 7, 8, 10 and 13; one token and a place_hold and a release stand for the action types, the boundary predicate and Invariant 8.1 are not modelled; closes 2026-08-30-a; idempotent-reservation.als + 14 twins (the static data model, 2026-11-12: Invariant 1.1, 2.1, 2.2, 3.1, 4.1, 4.2 and 7.1, Composes 7, Composition state 6, Wiring decision 1, 3 and 4, Indeterminate outcome 4 and 8 and Action wiring 27 checked on every state the calls and the eviction leg can leave and every answer a call gives against what it read, over two tokens and all four action types, a cross-check with the TLA+ model but for Composition state 6 and Wiring decision 3; nothing testable in Alloy for Invariant 8.1 (a deployment condition no record holds); Invariant 2.3, 7.2 and 8.2 left to the TLA+ model (a re-run's effect, the arm a call takes and a count across the window are sequences); the model found that Invariant 2.1 as written does not hold where a confirm and a release of one commitment carry one token, since the commitment id is their only parameter and so their digest is one and Action wiring 7 answers the second token-collision where the first answered ok, so it is checked under one action type; and that the page reads Duplicate Prevention's check as able to answer state-unavailable while the call's own writes commit (Indeterminate outcome 8, 13; Action wiring 25), where its Decision of 2026-10-20 makes the map, the commitment and the recorded set one store); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12, 2026-11-08
last gate: 2026-11-23 — Final Critique 11, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at e057eb2c — foundational count 2 after the blind second triage, not clean, no sample (Linus's three foundational reports were placed refuted, refining and refining by the first triage; the blind second triage, an Opus 5.5 subagent, placed two of them foundational, which decide: Check 1.1 and Check 1.2 read "inside the idempotency window" over every committed version of a token's entries, a window the page anchors on no instant, so two auditors differed on a conforming run whose lazily evicted entry and the entry written over it both stood inside one span of the window's length, and the check as written could never fail, one entry per token standing in any version; and an idempotency window changed at a restart (Execution Contract Logic confinement 17) left Check 4.1 and Check 4.2 reading the window the current configuration holds, failing a conforming eviction after a lengthened window and passing a forbidden one after a shortened one; cured: Check 1.1 and Check 1.2 find no two committed versions of one token's entries carrying one pending instant and two action types or two parameters digests, and Capability requirement 19 holds the idempotency window alike for every call and every run of the eviction leg of one instance, as Capability requirement 4 holds the digest function, External check 7 citing it; the first report's invariant half and the digest function's change across a restart were refuted, by Composition state 2 with Action wiring 12 and by Capability requirement 4; the refining cures are Action wiring 27, which cites Duplicate Prevention Non-goal 1 as Execution Contract Constituent failure 3 asks and leaves its second obligation to Action wiring 28, and Composition state 6, which loses a clause Indeterminate outcome 13 already decides); 2026-11-23 — Final Critique 10, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at 33944be8 — foundational count 2, not clean, no sample (Linus's three foundational reports were placed foundational, refuted and foundational: Check 4.1 asked Duplicate Prevention about a token now and about an entry evicted then, so a token reused after the window failed a conforming deployment, and Invariant 4.1 and Invariant 4.2 bound a token to one action type and one parameters digest for its whole life where Action wiring 7 and 8, Non-goal 1 and the Token Collision entry read a live entry only, the checks over them naming no state that could fail; cured: Check 4.1 reads the check's answer at the commit that evicted the entry, Invariant 4.1 and 4.2 say inside the idempotency window as Invariant 1.1, 2.1 and 3.1 do, and Check 1.1 and 1.2 read every committed version of a token's entries inside the window; the third report, that the order of Duplicate Prevention's record against Provisional Commitment's call lets one token bind two commitment ids, was refuted by Execution Contract Database 1, which commits the entry, the constituent's write and the record together or not at all, so no order is observable; the refining cures are Composition state 6, which cites Indeterminate outcome 13 for the re-entry, Capability requirement 1 and 3, which cite Execution Contract Logic confinement 17, and Action wiring 27, which cites Execution Contract Constituent failure 3); 2026-11-20 — Final Critique 9, a delta round, frozen at 15e8c30f — foundational count 0 after the blind second triage, clean, no sample (Linus's one report claimed one foundational: External check 8's held cap against Execution Contract Input 2, refuted because the rule names the cap the instance holds and Logic confinement 17 fixes it, so an auditor reading the declaration is not following the rule); 2026-11-20 — Final Critique 8, a delta round, frozen at 5c0294d — foundational count 1 after the blind second triage (the first triage placed it refining), cured in the round, not clean, one sample (Linus's one report claimed three foundational: External check 8 names the deployment's configuration where Execution Contract Input 2 says the cap the instance holds is read from the instance, placed foundational by the blind second triage, Kind A, cured by one replacement after Event Log's External check 6; the other two refuted, Indeterminate outcome 11 because [Expire] is a caller's action (Term resolving action, Provisional Commitment Operation 19) and the candidates read's failure because Execution Contract Constituent failure 3 answers it; refining 2 refuted by the blind second triage, left); 2026-11-05 — Final Critique 7, a delta round, frozen at 63c13eb — foundational count 0, clean, one sample; 2026-11-04 — Final Critique 6, a full round, frozen at de92f1e — foundational count 3, cured, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./idempotent-reservation.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/idempotent-reservation.md`.

</details>

NOTE: End of Idempotent Reservation.

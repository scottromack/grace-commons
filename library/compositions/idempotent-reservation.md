---
title: Idempotent Reservation
id: 22
audience: common
nav_order: 2
---

# Idempotent Reservation

<details markdown="block">
<summary>Table of contents</summary>
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

This composition solves the problem at the composition layer rather than absorbing it into Provisional Commitment. The caller supplies an **idempotency token** on every state-changing call. The composition checks the token against a [Duplicate Prevention](../atoms/duplicate-prevention.idd) instance; if the token has been seen within the window (the configurable time period during which repeated tokens are detected and deduplicated), the composition returns the *original* response (the same commitment id, the same ok, the same rejection reason) without invoking [Provisional Commitment](../atoms/provisional-commitment.idd) a second time — with one exception Invariant 2 states: a resolving action whose token Duplicate Prevention reports seen while the composition holds no answer for it is re-run (Indeterminate outcome 13), effect-free where an earlier run committed, by the constituent's own single-resolution invariant. The constituent atoms are unchanged; the composition is the wiring.

This is the composition payment processors run in production today — Stripe's `Idempotency-Key`, Adyen's idempotency header, ISO 20022's (the International Organization for Standardization standard for financial-messaging data) message uniqueness identifier, the IETF (Internet Engineering Task Force — the body that develops internet standards) draft idempotency-key spec. Different vocabularies; identical mechanic.

</details>

### Composes

- **[Provisional Commitment](../atoms/provisional-commitment.idd)** — the hold lifecycle and the invariants every commitment satisfies.
- **[Duplicate Prevention](../atoms/duplicate-prevention.idd)** — the time-bounded guard against a repeated token.

```
Composes 1: EXACTLY ONE Provisional Commitment instance MUST serve the composition.
Composes 2: EXACTLY ONE Duplicate Prevention instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST replace Provisional Commitment's own caller surface.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST answer a constituent's rejection unchanged (Execution Contract Constituent failure 2), a check Action wiring 27 resolves excepted.
Composes 7: The composition MUST call Duplicate Prevention's record EXACTLY ONE time per admitted first invocation.
Composes 8: The composition MUST configure the Duplicate Prevention instance with the idempotency window.
```

Term composition: this pattern's wiring of [Provisional Commitment](../atoms/provisional-commitment.idd) and [Duplicate Prevention](../atoms/duplicate-prevention.idd) — the token results map, the four token-carrying actions and the eviction leg.

Term constituents: [Provisional Commitment](../atoms/provisional-commitment.idd), [Duplicate Prevention](../atoms/duplicate-prevention.idd).

### Wiring decision

```
Wiring decision 1: The composition MUST record EVERY Provisional Commitment answer to a call carrying an idempotency token against the token.
Wiring decision 2: The composition MUST record a constituent's rejection against the token, a refusal, an outcome the action's refuses line lists, excepted (Execution Contract Read 4, Execution Contract Read 7).
Wiring decision 3: The composition MUST NOT record an answer for a malformed idempotency token.
Wiring decision 4: The composition MUST NOT record a [Place Hold] answer the composition returned on a seen token carrying no entry.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* One token, one result: the composition records against the token every answer a constituent gives, a rejection as much as a success, and every later call carrying the token inside the idempotency window receives that answer.

*Likely objection.* Caching the failure is the non-obvious half. If a first [Place Hold] answers resource-unavailable, a retry might succeed — the resource may have freed in between.

*Mechanism that resolves it.* A retry allowed to re-call the constituent would show the caller two answers to what they meant as one operation, the double this composition exists to prevent, and the decision lives here because neither constituent can make it: Provisional Commitment's record carries no token, and Duplicate Prevention remembers an identity, not an answer. The caller decides whether to attempt the act again under a **fresh** token, and the new attempt doubles nothing, since a refused [Place Hold] records no commitment (Provisional Commitment Operation 31).

*Result.* *Same token, same result*, a rejection included. Three exclusions share one reason: the composition did not act, so it holds nothing to cache. A malformed token is not a token; a `seen` token with no entry means the composition recorded nothing and the next `check` may answer differently; and a refusal commits nothing at all, a constituent's storage failure among them (Execution Contract Constituent failure 1, Execution Contract Read 4). A rejection the composition caches is listed on its action's answers line and not on its refuses line, so the call is admitted and its record commits with it (Execution Contract Read 7).

</details>

## What it keeps

### Composition state

```
Composition state 1: The composition MUST store a token results map.
Composition state 2: The composition MUST key the token results map by idempotency token.
Composition state 3: An entry MUST carry an action type, a parameters digest, a result, a pending instant AND a recovery mark.
Composition state 6: EXACTLY ONE invocation MUST write an entry for EVERY act of one idempotency token (Indeterminate outcome 13).
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

Term parameters digest: the collision-resistant digest of a call's non-token parameters, a reference among them in the canonical form Execution Contract Logic confinement 13 gives it, computed at the seam by the configured digest function — a [Parameters Digest].

#### Parameters Digest

The recorded outcome's collision-resistant digest of the non-token call parameters, a reference among them in the canonical form Execution Contract Logic confinement 13 gives it, computed at the composition's I/O seam and injected. A retry whose digest differs from the recorded one is rejected [Token Collision]; digest-function drift across replicas misclassifies legitimate retries.

Kind:       Field
Field of:   Token Results Entry
Role:       the token's bound parameters
Projection: parameters_digest

#### Result

The recorded outcome's copy of the original response — the produced id or ok, or the rejection reason — exactly as returned to the caller on the first call. Every Provisional Commitment answer is cached, success or rejection (the cache-the-failure rule), save a refusal, which commits nothing (Execution Contract Read 4), a storage failure among them (Execution Contract Constituent failure 1).

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

#### Closure table

Every input an action takes and every answer a call of the four actions can meet — Duplicate Prevention's check and record, and Provisional Commitment's place hold, confirm, release, expire and read — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1, Execution Contract Constituent failure 3); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. A refusal writes nothing (Execution Contract Read 4); a rejection the composition caches is on its action's answers line, so the call is admitted and the record commits with it (Execution Contract Read 7).

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action | a blank idempotency token | invalid-request, no constituent called, nothing recorded | Primitive policy 1, Wiring decision 3 |
| every action | an idempotency token over the token max length | invalid-request, no constituent called, nothing recorded | Primitive policy 2, Wiring decision 3 |
| every action | an idempotency token | compared byte-exact, never normalized or case-folded | Primitive policy 3, 4, 5 |
| every action | the call's non-token parameters | digested at the seam | Composition state 9 |
| [Place Hold] | parameters Provisional Commitment refuses as invalid-request | invalid-request, nothing recorded | Composes 6, Wiring decision 2 |

**Duplicate Prevention's check**, at every call whose token clears the boundary predicate, ahead of any answer from an entry (Primitive policy 6, Action wiring 29).

| Answer | Lands | Owner |
|---|---|---|
| seen, a live entry | token-collision for a differing action type or parameters digest, otherwise the entry's result | Action wiring 7, 8, 9 |
| seen, no entry, [Place Hold] | outcome-unknown carrying the candidates, uncached | Indeterminate outcome 10, Wiring decision 4 |
| seen, no entry, a resolving action | the action runs again, its entry marked recovered | Indeterminate outcome 13, 8 |
| not-seen, an entry the window elapsed for | the entry evicted in place, the call a fresh request | Action wiring 12, Invariant 7.2 |
| not-seen, no entry | a fresh request: Provisional Commitment is called | Term fresh request |
| state-unavailable | resolved as seen, never answered | Action wiring 27, 28, Capability requirement 16, Execution Contract Constituent failure 3 |

**Duplicate Prevention's record**, once for an admitted first invocation, in the transaction that commits the entry (Composes 7, Action wiring 25).

| Answer | Lands | Owner |
|---|---|---|
| ok | the entry, the constituent's write and the record commit together | Execution Contract Database 1 |
| storage-failure | storage-failure, nothing commits | Execution Contract Constituent failure 1 |

**Provisional Commitment's place hold, confirm, release and expire**, for a fresh request or a re-entry.

| Answer | Lands | Owner |
|---|---|---|
| id, or ok | recorded against the token, answered | Wiring decision 1, Action wiring 21 |
| resource-unavailable, not-known, not-held, window-elapsed or window-not-elapsed | recorded against the token, answered | Wiring decision 2, Composes 6 |
| invalid-request, at a place hold | answered, nothing recorded | Composes 6, Wiring decision 2 |
| storage-failure | storage-failure, nothing commits | Execution Contract Constituent failure 1 |
| state-unavailable | state-unavailable, nothing commits | Execution Contract Constituent failure 3 |

**Provisional Commitment's read**, at a [Place Hold] whose token is seen and holds no entry, for the candidates.

| Answer | Lands | Owner |
|---|---|---|
| every commitment | the candidates the composition filters from it | Indeterminate outcome 3, 4, 7 |
| state-unavailable | state-unavailable, nothing recorded | Execution Contract Constituent failure 3 |

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
Action wiring 10: The composition MUST NOT call Provisional Commitment for a matching complete entry.
Action wiring 12: The composition MUST evict a complete entry the idempotency window elapsed for AND Duplicate Prevention's check answers not-seen for.
Action wiring 21: The composition MUST answer Provisional Commitment's answer to the caller.
Action wiring 25: The composition MUST call Duplicate Prevention's record for EVERY result recorded against an idempotency token (Wiring decision 1).
Action wiring 27: IF Duplicate Prevention's check answers state-unavailable THEN the composition MUST resolve the check as seen (Capability requirement 16, Duplicate Prevention Non-goal 1, Execution Contract Constituent failure 3).
Action wiring 28: IF Duplicate Prevention's check answers state-unavailable THEN the composition MUST NOT answer state-unavailable for the check.
Action wiring 29: The composition MUST answer from an entry ONLY AFTER Duplicate Prevention's check answers (Action wiring 7, Action wiring 8, Action wiring 9, Action wiring 12).
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
  answers id | resource-unavailable
  refuses invalid-request | token-collision | storage-failure | outcome-unknown(candidates)
```

### Confirm

The retry-safe confirm action — same token-check-then-delegate wiring as [Place Hold], delegating to Provisional Commitment's confirm. A within-window retry returns the cached ok, hiding the terminal-absorption not-held a direct retry would hit; a token bound to a different [Action Type] is rejected [Token Collision].

Kind: Operation

```
confirm(id, idempotency_token)
  answers ok | not-known | not-held | window-elapsed
  refuses invalid-request | token-collision | storage-failure
```

### Release

The retry-safe release action — same wiring, delegating to Provisional Commitment's release. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

```
release(id, idempotency_token)
  answers ok | not-known | not-held | window-elapsed
  refuses invalid-request | token-collision | storage-failure
```

### Expire

The retry-safe expire action — same wiring, delegating to Provisional Commitment's expire. A within-window retry returns the cached result; cross-action or cross-parameter reuse is rejected [Token Collision].

Kind: Operation

```
expire(id, idempotency_token)
  answers ok | not-known | not-held | window-not-elapsed
  refuses invalid-request | token-collision | storage-failure
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
  Invariant 1.1: Two place_hold calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window, an outcome-unknown answer excepted (Wiring decision 4).
  ```
- **Invariant 2 — Idempotent state transitions within the window.**
  ```
  Invariant 2.1: Two resolving calls carrying one idempotency token AND one parameters digest MUST answer alike inside the idempotency window.
  Invariant 2.2: The composition MUST NOT call Provisional Commitment twice for one idempotency token inside the idempotency window, a resolving action's re-entry excepted (Indeterminate outcome 13).
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
Capability requirement 4: A deployment MUST set EXACTLY ONE digest function for EVERY call of one instance.
Capability requirement 16: A deployment MUST resolve Duplicate Prevention's check fail-closed PER Action wiring 27.
Capability requirement 18: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
Capability requirement 19: A deployment MUST set EXACTLY ONE idempotency window for EVERY call AND EVERY run of the eviction leg of one instance (Duplicate Prevention Operation 11).
```

Term idempotency window: the duration the Duplicate Prevention instance guards a token, set by the deployment with no default, its aim (which no rule measures) the slowest legitimate retry of the most critical action, and more than zero, as Duplicate Prevention's window duration is — an idempotency window; the one duration measures the guard from Duplicate Prevention's record and an entry from its pending instant (Term window end), and a call acts on both (Action wiring 12, Invariant 7.1).

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
- **Replay attack — adversary captures and replays a token.** An adversary captures an in-flight request and replays it later within the window. The composition correctly returns the cached result. The replay produces no new state change — `Invariant 2 — Idempotent state transitions within the window`. Replays *outside* the window are treated as fresh requests; the adversary may succeed in placing a new commitment if the resource is available and they hold valid credentials, but that is an authentication / authorization failure (see [Actor Identity](../atoms/actor-identity.idd)), not an idempotency failure.
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
Check 1.1: An auditor MUST find no two committed versions of one idempotency token's entries carrying two action types AND pending instants each of which PRECEDES the other version's window end (Execution Contract Database 5, Execution Contract Generation acceptance 1) (Invariant 4.1).
Check 1.2: An auditor MUST find no two committed versions of one idempotency token's entries carrying two parameters digests AND pending instants each of which PRECEDES the other version's window end (Execution Contract Database 5, Execution Contract Generation acceptance 1) (Invariant 4.2).
Check 2.1: An auditor MUST find no idempotency token bound to two commitment ids inside the idempotency window (Invariant 3.1).
Check 3.1: An auditor MUST find EVERY complete entry whose result is an id naming a commitment Provisional Commitment's read answers (Wiring decision 1).
Check 4.1: An auditor MUST find no evicted entry, read at the evicted entry's last version (Execution Contract Database 5), whose token Duplicate Prevention's check, read on the state the commit that evicted the entry read (Execution Contract Database 2), answered seen for (Housekeeping 6, Action wiring 12).
Check 4.2: An auditor MUST find no evicted entry, read at the evicted entry's last version (Execution Contract Database 5), younger than the idempotency window at the now the commit that evicted the entry read (Execution Contract Logic confinement 11, Housekeeping 5, Action wiring 12).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 3: An auditor needing Duplicate Prevention's fail-closed posture confirmed MUST read the deployment's own configuration (Capability requirement 16).
External check 5: An auditor needing the exactly-once claim confirmed MUST read the deployment's own database AND External check 3 (Invariant 8.1).
External check 6: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 7: An auditor needing the idempotency window confirmed MUST read the window the instance holds PER Execution Contract Logic confinement 17 (Capability requirement 1, Capability requirement 19).
External check 8: An auditor needing the token max length confirmed MUST read the cap the instance holds PER Execution Contract Input 2 (Capability requirement 2).
External check 9: An auditor needing the digest function confirmed MUST read the digest function the instance holds PER Execution Contract Logic confinement 17 (Capability requirement 3).
External check 10: An auditor needing a complete entry's result other than an id confirmed MUST read the deployment's own account of the answer the constituent gave (Wiring decision 1).
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

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the extraction-pending classification. The section titled Logic Confinement Principle in `execution-contract.md` — the seam, the transition and the mechanism-capability pattern. [Provisional Commitment](../atoms/provisional-commitment.idd) `Invariant 2` — single resolution, which makes a resolving re-run effect-free. [Duplicate Prevention](../atoms/duplicate-prevention.idd) `Invariant 2` — a record starts a guard rather than extending one.

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

`done — 2026-11-23` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-23
formal: verified — idempotent-reservation.tla + 13 twins, re-derived 2026-11-08 (it was verified 2026-06-03 over one effect counter and an unguarded early eviction): the token's entry with its action type, parameters digest and recovery mark; Duplicate Prevention's guard on its own clock and its outage, read fail-closed; the eviction leg as the second process beside the calls, and the five arms a call takes (token-collision, replay, fresh request, outcome-unknown, re-entry); Invariants 1.1, 2.1 to 2.3, 3.1, 4.1, 4.2, 7.1, 7.2 and 8.2 checked, with Check 4.1 and 4.2, Composes 7, Wiring decision 2 and Indeterminate outcome 3, 4, 7, 8, 10 and 13; one token and a place_hold and a release stand for the action types, the boundary predicate and Invariant 8.1 are not modelled; closes 2026-08-30-a; idempotent-reservation.als + 14 twins (the static data model, 2026-11-12: Invariant 1.1, 2.1, 2.2, 3.1, 4.1, 4.2 and 7.1, Composes 7, Composition state 6, Wiring decision 1, 3 and 4, Indeterminate outcome 4 and 8 and Action wiring 27 checked on every state the calls and the eviction leg can leave and every answer a call gives against what it read, over two tokens and all four action types, a cross-check with the TLA+ model but for Composition state 6 and Wiring decision 3; nothing testable in Alloy for Invariant 8.1 (a deployment condition no record holds); Invariant 2.3, 7.2 and 8.2 left to the TLA+ model (a re-run's effect, the arm a call takes and a count across the window are sequences); the model found that Invariant 2.1 as written does not hold where a confirm and a release of one commitment carry one token, since the commitment id is their only parameter and so their digest is one and Action wiring 7 answers the second token-collision where the first answered ok, so it is checked under one action type; and that the page reads Duplicate Prevention's check as able to answer state-unavailable while the call's own writes commit (Indeterminate outcome 8, 13; Action wiring 25), where its Decision of 2026-10-20 makes the map, the commitment and the recorded set one store); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12, 2026-11-08
last gate: 2026-11-23 — Final Critique 14, a delta round, one reader (Linus opencode-go/glm-5.3-flash), frozen at 5561d417 — foundational count 0 after the blind second triage, clean, one sample (Linus's three foundational reports were refuted by both triages: two concurrent calls or re-entries on one token are serialized on the token's entry by Execution Contract Database 2, the later reading what the earlier committed and answering from it, so neither the registry's loser nor a second resolution's answer reaches the caller (Action wiring 9, Action wiring 10, Action wiring 29, Invariant 1.1, Invariant 2.1, Invariant 2.2), and Composition state 3 stands because a recovered entry is one a re-entry writes with its result (Term recovery mark, Composition state 6, Indeterminate outcome 10 and 13); the settle's own cures: the registry-unavailable answer leaves place_hold's signature, the closure table and the Likely objection, since Provisional Commitment's declared refuses line (invalid-request, resource-unavailable, storage-failure) never answers it and Execution Contract Constituent failure 2 reads where a constituent answers it (the method page's example naming Provisional Commitment's place hold is a held cure), Wiring decision 2 names the refusal as an outcome the action's refuses line lists, Check 4.2 judges the window at the now the evicting commit read, and Term idempotency window sets its sizing aim off as no rule's; refuted: Check 4.1's substance in Check 4.2 (the guard's own answer parts from the window where Duplicate Prevention is unavailable, Action wiring 27), a digest function changed across a restart (Capability requirement 3 and 4, Execution Contract Logic confinement 17), and the recovery protocol as Recoverable Invocation's job (a synchronous in-store call, no wait: pressure-testing.md's survey places the page one short of the floor); the round read the reach of Final Critique 13's cures (90 labels) by their diff); 2026-11-23 — Final Critique 13, a full round, three readers (GRID opencode-go/glm-5.3-flash, EOS opencode-go/qwen3.8-max, Linus opencode-go/minimax-m3), frozen at 2ebcc7df — foundational count 5, cured, not clean, no sample (GRID's two, EOS's three and Linus's three foundational reports were placed five foundational, one merged and two refining by the first triage, so no blind second triage ran: a recorded constituent rejection stood on its action's refuses line, which Execution Contract Read 4 erases and Read 7 moves to the answers line (EOS and Linus found it); Invariant 1.1 held two outcome-unknown answers to answer alike where Wiring decision 4 leaves them uncached with live candidates (GRID); Check 3.1 asked an auditor for the constituent's answer no record carries (EOS); Action wiring 10 and Invariant 2.2 forbade the check the eviction in place needs, and no rule ordered the check before an entry answers (Linus); and Check 4.1 read the check after the commit that evicted and re-recorded the token (Linus); cured: the four signatures list each cached rejection on the answers line, Wiring decision 2 excepts a refusal, Invariant 1.1 excepts outcome-unknown, Action wiring 10 and Invariant 2.2 name Provisional Commitment, Action wiring 29 answers from an entry only after the check answers, Check 3.1 reads an id and External check 10 reads the deployment's account of every other result, and Check 4.1 reads the state the evicting commit read; the digest's reference input and Wiring decision 1's constituent were placed refining and cured (Execution Contract Logic confinement 13 and the Result entry decide them); the refining cures are the closure table spec-format owes in a composition's next round, Composes 6 citing Execution Contract Constituent failure 2 with the resolved check excepted, Capability requirement 16 citing Action wiring 27, Check 4.2 citing Action wiring 12, the Term idempotency window naming both measures of the one duration (the guard from Duplicate Prevention's record, an entry from its pending instant), and the Term composition naming the token results map; the rest of the reports' refining and rhetorical findings were refuted by the tombstones in the history file, Execution Contract Database 1 and Database 2, Invariant 7.1, the Term idempotency window and Composes 5 with Execution Contract Conformance 8, or fall outside the page: Duplicate Prevention's Window Duration card and Execution Contract Constituent failure 2's naming of Provisional Commitment's place hold); 2026-11-23 — Final Critique 12, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at 6168e7f3 — foundational count 2, not clean, no sample (Linus's three foundational reports were placed refining, foundational and foundational by the first triage; the count is not zero, so no blind second triage ran: Check 1.1 and Check 1.2, cured last round to compare versions "carrying one pending instant", could not fail on the forbidden write, a second entry of one token written inside the window, since that entry carries its own invocation's instant, never the first's, so the pair was never compared and a tie of two clock readings alone made the check bite; and External check 7 sent the auditor to the deployment's configuration, which names a window the instance does not hold between a change and the next start (Execution Contract Logic confinement 17), where External check 8 already reads the cap the instance holds; cured: Check 1.1 and Check 1.2 compare versions whose pending instants each precede the other's window end, which anchors the pair on the window and not on a tie, and cite Generation acceptance 1; External check 7 reads the window the instance holds, and External check 9 the digest function, on the same footing; the first report, that Execution Contract Constituent failure 3 names Duplicate Prevention Operation 12 where the page cites Non-goal 1, was placed refining: Operation 12 was deleted to Non-goal 1 on 2026-11-20, so the page cites the rule that owns the response and Constituent failure 3's own citation is stale, a held cure to execution-contract.md; the refining cures are Capability requirement 19 and Capability requirement 4, which say EXACTLY ONE where they said alike, and Composition state 6, which says for EVERY act of one idempotency token; the rest of the reports' refining and rhetorical findings were refuted by Action wiring 12, Indeterminate outcome 10 and 13, and the page's own use of the answers seen and not-seen); 2026-11-23 — Final Critique 11, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at e057eb2c — foundational count 2 after the blind second triage, not clean, no sample (Linus's three foundational reports were placed refuted, refining and refining by the first triage; the blind second triage, an Opus 5.5 subagent, placed two of them foundational, which decide: Check 1.1 and Check 1.2 read "inside the idempotency window" over every committed version of a token's entries, a window the page anchors on no instant, so two auditors differed on a conforming run whose lazily evicted entry and the entry written over it both stood inside one span of the window's length, and the check as written could never fail, one entry per token standing in any version; and an idempotency window changed at a restart (Execution Contract Logic confinement 17) left Check 4.1 and Check 4.2 reading the window the current configuration holds, failing a conforming eviction after a lengthened window and passing a forbidden one after a shortened one; cured: Check 1.1 and Check 1.2 find no two committed versions of one token's entries carrying one pending instant and two action types or two parameters digests, and Capability requirement 19 holds the idempotency window alike for every call and every run of the eviction leg of one instance, as Capability requirement 4 holds the digest function, External check 7 citing it; the first report's invariant half and the digest function's change across a restart were refuted, by Composition state 2 with Action wiring 12 and by Capability requirement 4; the refining cures are Action wiring 27, which cites Duplicate Prevention Non-goal 1 as Execution Contract Constituent failure 3 asks and leaves its second obligation to Action wiring 28, and Composition state 6, which loses a clause Indeterminate outcome 13 already decides); 2026-11-23 — Final Critique 10, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at 33944be8 — foundational count 2, not clean, no sample (Linus's three foundational reports were placed foundational, refuted and foundational: Check 4.1 asked Duplicate Prevention about a token now and about an entry evicted then, so a token reused after the window failed a conforming deployment, and Invariant 4.1 and Invariant 4.2 bound a token to one action type and one parameters digest for its whole life where Action wiring 7 and 8, Non-goal 1 and the Token Collision entry read a live entry only, the checks over them naming no state that could fail; cured: Check 4.1 reads the check's answer at the commit that evicted the entry, Invariant 4.1 and 4.2 say inside the idempotency window as Invariant 1.1, 2.1 and 3.1 do, and Check 1.1 and 1.2 read every committed version of a token's entries inside the window; the third report, that the order of Duplicate Prevention's record against Provisional Commitment's call lets one token bind two commitment ids, was refuted by Execution Contract Database 1, which commits the entry, the constituent's write and the record together or not at all, so no order is observable; the refining cures are Composition state 6, which cites Indeterminate outcome 13 for the re-entry, Capability requirement 1 and 3, which cite Execution Contract Logic confinement 17, and Action wiring 27, which cites Execution Contract Constituent failure 3); 2026-11-20 — Final Critique 9, a delta round, frozen at 15e8c30f — foundational count 0 after the blind second triage, clean, no sample (Linus's one report claimed one foundational: External check 8's held cap against Execution Contract Input 2, refuted because the rule names the cap the instance holds and Logic confinement 17 fixes it, so an auditor reading the declaration is not following the rule); 2026-11-20 — Final Critique 8, a delta round, frozen at 5c0294d — foundational count 1 after the blind second triage (the first triage placed it refining), cured in the round, not clean, one sample (Linus's one report claimed three foundational: External check 8 names the deployment's configuration where Execution Contract Input 2 says the cap the instance holds is read from the instance, placed foundational by the blind second triage, Kind A, cured by one replacement after Event Log's External check 6; the other two refuted, Indeterminate outcome 11 because [Expire] is a caller's action (Term resolving action, Provisional Commitment Operation 19) and the candidates read's failure because Execution Contract Constituent failure 3 answers it; refining 2 refuted by the blind second triage, left); 2026-11-05 — Final Critique 7, a delta round, frozen at 63c13eb — foundational count 0, clean, one sample; 2026-11-04 — Final Critique 6, a full round, frozen at de92f1e — foundational count 3, cured, not clean, no sample

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

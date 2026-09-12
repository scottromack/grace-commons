---
title: Capability
parent: Atomic Concepts
has_toc: true
toc: true
---

# Capability

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Capability expresses bearer-token authorization: holding the token grants the right, no matter who holds it. Each capability ties a [Scope] — what it authorizes, opaque to the atom and interpreted by whatever uses it — to a redemption envelope: how many times it may be used, and until when. It is named by a cryptographically random [Capability Token] that doubles as the credential presented to redeem it, and nothing else is required to redeem.

No identity is asked for or recorded on the redemption side. That is the defining asymmetry: who created the capability is always recorded, who used it deliberately is not. The record reads *allocated by X, scope Y, redeemed N times* — never *redeemed by Z*.

A capability ends in one of three clearly separated ways, and the difference is load-bearing. It runs out of redemptions ([Redeemed]) or it is explicitly cancelled ([Revoked]) — each an end state written into the record. Or its window simply passes, in which case it is shown [Expired], a status worked out on the fly by comparing the clock to the deadline and never written down. The default is single-use.

This is the mechanism behind password-reset links, pre-signed file URLs, scoped API (Application Programming Interface) tokens, and OAuth (Open Authorization — the web's delegated-authorization framework) authorization codes. It deliberately does not decide when a capability should be issued, interpret the [Scope], or record what was done after redemption — and where redeeming must bind an identity, that is [Invitation](./invitation.md), not this atom.

---

## Intent

WHY:
Many authorization problems are not about *who is asking* but about *what is being presented*. A password-reset link grants the right to set a new password to whoever holds the link — the account owner who received it by email, a friend who was handed it, or an attacker who intercepted it. A pre-signed URL grants read access to anyone with the URL for its lifetime. In each case the authorization is embedded in the token, and the holder's identity is irrelevant by design.

[Permissions](./permissions.md) is the library's other authorization model and it is identity-keyed: a check gates on who is asking, matching an actor reference against a list. That is the right model when authorization is principal-bound. It is the wrong model for a bearer token — modelling a password-reset link as a permission grant would mean creating a principal for the recipient before the link is sent, which defeats the point of a bearer credential. The two primitives are structurally distinct and belong to separate atoms.

So this atom isolates the bearer-token primitive, and it is the library's expression of object-capability theory (OCAP — a security model in which unforgeable references carry their own authority, needing no separate access control list). [Allocate] creates a capability, records who created it and what it authorizes, and answers a token. [Redeem] accepts the token, checks that it is live and not exhausted, and answers the [Scope] — with no identity argument and no identity record. The asymmetry between allocator, always known, and redeemer, intentionally unknown, is structural rather than accidental, and it is this atom's primary contribution to a composing system's audit record.

Two disciplines carry the rest. The redemption counter is the only field that moves between allocation and a terminal write, so the authorization envelope is readable from one immutable record. And lapsing is derived, not written: there is no `expire` action, no `expired_at` column and no stored [Expired] status, so the stored state space stays three values and no flag can lag the clock it idealizes.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a capability by the capability_token.
Identity 2: The capability_token MUST serve as the bearer credential [Redeem] accepts.
Identity 3: The capability_token MUST serve as the bearer credential [Revoke] accepts.
Identity 4: The host MUST allocate a capability_token at the seam.
Identity 5: The transition MUST NOT allocate a capability_token.
Identity 6: The atom MUST NOT reuse a capability_token any retained capability carries.
Identity 7: The atom MUST NOT change a capability_token.
Identity 8: Two capabilities MUST NOT share a capability_token.
Identity 9: The deployment MUST draw a capability_token from a cryptographically secure random source.
Identity 10: The deployment MUST NOT draw a capability_token from the capability's public properties.
Identity 11: IF a write would reuse a capability_token THEN the store MUST refuse the write.
Identity 12: The atom MUST NOT interpret an allocator_ref.
Identity 13: The atom MUST NOT confirm an allocator_ref's authority.
```

Terms › `capability`: one bearer-token authorization with a redemption envelope — the record this atom holds.

Terms › `capability_token`: the opaque value naming one capability — a [Capability Token]; unguessable, host-allocated at the seam, and the capability [Redeem] and [Revoke] accept.

Terms › `allocator_ref`: the opaque reference naming the actor that created the capability — an [Allocator Ref].

Terms › `scope`: the opaque value describing what the capability authorizes — a [Scope]; stored at allocation, answered at redemption, never evaluated.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the capability_token's random material here.

Terms › `transition`: the atom's evaluation of one call against the capability store, as `execution-contract.md` §Logic confinement declares it.

WHY:
Identity 11 is the half of uniqueness that randomness cannot supply. Unguessability comes from the entropy source; *uniqueness* comes from the store refusing a colliding write, which is why Invariant 12.2 is a store obligation rather than a probabilistic hope (Identity 9, Identity 11, Invariant 12.1, Invariant 12.2).

### Operations

```
allocate(allocator_ref, scope, max_redemptions, ttl) → capability_token | rejected(invalid-request | storage-failure)
redeem(capability_token) → redeemed(scope, allocator_ref) | invalid(exhausted | expired | revoked | not-known)
revoke(capability_token, revoked_by_ref, reason) → revoked | rejected(invalid-request | already-terminal | not-known | storage-failure)
read(filter) → capability_records
```

```text
Operation 1: [Allocate] MUST record EXACTLY ONE capability per successful call.
Operation 2: [Allocate] MUST stand the capability in allocated.
Operation 3: [Allocate] MUST answer the capability_token.
Operation 4: IF allocator_ref NOT EXISTS THEN [Allocate] MUST answer invalid-request.
Operation 5: IF scope NOT EXISTS THEN [Allocate] MUST answer invalid-request.
Operation 6: IF max_redemptions NOT EXISTS THEN [Allocate] MUST apply the single-use default.
Operation 7: [Allocate] MUST accept a max_redemptions ONLY IF the max_redemptions EXCEEDS zero.
Operation 8: IF zero EXCEEDS max_redemptions THEN [Allocate] MUST answer invalid-request.
Operation 9: IF max_redemptions = zero THEN [Allocate] MUST answer invalid-request.
Operation 10: IF ttl NOT EXISTS THEN [Allocate] MUST apply the default capability ttl.
Operation 11: IF the default capability ttl NOT EXISTS THEN [Allocate] MUST answer invalid-request.
Operation 12: [Allocate] MUST accept a ttl ONLY IF the ttl EXCEEDS the zero duration.
Operation 13: IF the ttl NOT EXCEEDS the zero duration THEN [Allocate] MUST answer invalid-request.
Operation 14: [Allocate] MUST stamp allocated_at from the injected now.
Operation 15: [Allocate] MUST stamp expires_at from the expiry deadline.
Operation 16: [Allocate] MUST NOT recompute expires_at from a later clock reading.
Operation 17: [Allocate] MUST set remaining_redemptions to the max_redemptions.
Operation 18: IF the store refuses the write THEN [Allocate] MUST answer storage-failure.
Operation 19: [Redeem] MUST answer EXACTLY ONE OF redeemed, exhausted, expired, revoked, not-known.
Operation 20: [Redeem] MUST accept the capability_token as the whole call.
Operation 21: [Redeem] MUST NOT accept an identity argument.
Operation 22: [Redeem] MUST NOT record a redeemer's identity.
Operation 23: IF the capability_token names no capability THEN [Redeem] MUST answer not-known.
Operation 24: IF the capability stands in redeemed THEN [Redeem] MUST answer exhausted.
Operation 25: IF the capability stands in revoked THEN [Redeem] MUST answer revoked.
Operation 26: IF the capability is lapsed THEN [Redeem] MUST answer expired.
Operation 27: [Redeem] MUST answer expired ONLY IF the capability stands in allocated.
Operation 28: [Redeem] MUST answer redeemed ONLY IF the capability stands in allocated AND the capability is not lapsed.
Operation 29: [Redeem] MUST carry the scope and the allocator_ref in a redeemed answer.
Operation 30: A redeeming [Redeem] MUST lower remaining_redemptions by one.
Operation 31: A refused [Redeem] MUST NOT lower remaining_redemptions.
Operation 32: IF remaining_redemptions reaches zero THEN [Redeem] MUST stand the capability in redeemed.
Operation 33: IF remaining_redemptions reaches zero THEN [Redeem] MUST stamp redeemed_at from the injected now.
Operation 34: [Redeem] MUST commit the lowering and the exhausting move in one operation.
Operation 35: IF the capability_token names no capability THEN [Revoke] MUST answer not-known.
Operation 36: IF the capability stands in redeemed THEN [Revoke] MUST answer already-terminal.
Operation 37: IF the capability stands in revoked THEN [Revoke] MUST answer already-terminal.
Operation 38: IF the capability is lapsed THEN [Revoke] MUST answer already-terminal.
Operation 39: IF the capability is revocable AND revoked_by_ref NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 40: IF the capability is revocable AND reason NOT EXISTS THEN [Revoke] MUST answer invalid-request.
Operation 41: [Revoke] MUST stand the capability in revoked.
Operation 42: [Revoke] MUST stamp revoked_at from the injected now.
Operation 43: [Revoke] MUST record revoked_by_ref on the capability.
Operation 44: [Revoke] MUST record the reason as the revocation_reason.
Operation 45: [Revoke] MUST commit the status move and the three revocation fields in one operation.
Operation 46: [Revoke] MUST NOT lower remaining_redemptions.
Operation 47: [Revoke] MUST answer revoked.
Operation 48: IF the store refuses the write THEN [Revoke] MUST answer storage-failure.
Operation 49: A refused write MUST leave the store as the call found the store.
Operation 50: [Read] MUST answer EVERY capability the filter matches.
Operation 51: [Read] MUST carry the effective_status on EVERY answered capability.
Operation 52: [Read] MUST NOT write.
Operation 53: A liveness query MUST rest on the effective_status.
Operation 54: A liveness query MUST NOT rest on the stored status alone.
Operation 55: The host MUST read the clock at the seam.
Operation 56: The transition MUST NOT read a clock.
Operation 57: The business caller MUST NOT supply now.
Operation 58: The atom MUST NOT offer an expire action.
Operation 59: The atom MUST NOT offer a re-scope action.
Operation 60: The atom MUST NOT offer an extend action.
```

Terms › `uncommitted crash`: a crash inside [Redeem] whose lowering the store has not committed.

Terms › `committed crash`: a crash inside [Redeem] whose lowering the store has committed.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `max_redemptions`: the number of redemptions the capability permits — a [Max Redemptions]; set at allocation, never changed.

Terms › `single-use default`: a `max_redemptions` of one — what [Allocate] applies where the call supplies none.

Terms › `remaining_redemptions`: the redemptions the capability has left — a [Remaining Redemptions]; the one field that moves between allocation and a terminal write.

Terms › `ttl`: the validity duration a [Allocate] call asks for — a [TTL] (time-to-live); consumed to compute the expiry deadline, never stored under this name.

Terms › `default capability ttl`: the validity duration [Allocate] applies where the call supplies no `ttl`; deployment configuration, and its absence is a misconfiguration rather than an operating state.

Terms › `zero duration`: a duration of no length — the floor a `ttl` must exceed, which refuses zero and every negative value.

Terms › `zero`: the count of nothing — the floor a `max_redemptions` must exceed, and the value `remaining_redemptions` reaches at exhaustion.

Terms › `allocated_at`: the instant the capability was recorded — an [Allocated At].

Terms › `expiry deadline`: `allocated_at + ttl` — what [Allocate] stores as `expires_at`, computed once at allocation.

Terms › `expires_at`: the instant the capability's window closes — an [Expires At]; stamped at allocation, never changed, never absent.

Terms › `lapsed`: the capability stands in `allocated` and `now` is no earlier than the capability's `expires_at` — the condition the guards derive and never stamp.

Terms › `revocable`: the capability stands in `allocated` and the capability is not lapsed — what [Revoke] requires.

Terms › `effective_status`: `expired` where the capability is lapsed, and the stored status otherwise — an [Effective Status]; a pure projection over the capability and `now`, never stored.

Terms › `redeemed_at`: the instant the capability exhausted — a [Redeemed At].

Terms › `revoked_at`: the instant the capability was cancelled — a [Revoked At].

Terms › `revoked_by_ref`: the opaque reference naming the actor that cancelled the capability — a [Revoked By Ref].

Terms › `revocation_reason`: the stated ground for the cancellation — a [Revocation Reason], carried from the call's [Reason].

Terms › `reason`: the [Revoke] argument the capability keeps as `revocation_reason` — a [Reason].

Terms › `filter`: the selection a [Read] call scopes the answer by; consumed per call, never stored.

Terms › `liveness query`: any query for the capabilities still redeemable — the administrative surfaces, and the auditor's triage.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the store |
|---|---|---|---|
| [Allocate] | both references present, counts positive or defaulted, store accepts | the new `capability_token` | one record lands in [Allocated], the counter set to [Max Redemptions] (Operation 1, Operation 17) |
| [Allocate] | a blank reference, a non-positive count or duration, or no configured default | [Invalid Request] | none (Operation 4, Operation 5, Operation 8, Operation 9, Operation 11, Operation 13) |
| [Redeem] | token names nothing | `invalid(not-known)` | none (Operation 23) |
| [Redeem] | stored status is [Redeemed] | `invalid(exhausted)` | none (Operation 24) |
| [Redeem] | stored status is [Revoked] | `invalid(revoked)` | none (Operation 25) |
| [Redeem] | stored [Allocated], `now` has reached `expires_at` | `invalid(expired)` | **none** — derived, and the counter is untouched (Operation 26, Operation 31) |
| [Redeem] | stored [Allocated], window open, counter above one | `redeemed(scope, allocator_ref)` | the counter falls by one; status unchanged (Operation 30) |
| [Redeem] | stored [Allocated], window open, counter at one | `redeemed(scope, allocator_ref)` | the counter reaches zero and the status moves to [Redeemed], one operation (Operation 32–34) |
| [Revoke] | token names a revocable capability, attribution present | `revoked` | [Allocated] → [Revoked], three fields stamped, counter untouched (Operation 41–46) |
| [Revoke] | token names nothing | [Not Known] | none (Operation 35) |
| [Revoke] | stored status is [Redeemed] or [Revoked] | [Already Terminal] | none (Operation 36, Operation 37) |
| [Revoke] | stored [Allocated] past its deadline | [Already Terminal] | none — derived, nothing written (Operation 38) |
| [Revoke] | revocable, blank attribution | [Invalid Request] | none (Operation 39, Operation 40) |
| [Allocate], [Revoke] | store refuses | [Storage Failure] | none (Operation 18, Operation 48, Operation 49) |
| *a window lapses* | `now` reaches `expires_at` | nothing is called | **nothing written** — no status, no stamp, no counter move (Expiry 1–5) |
| [Read] | a filter | the matching capabilities, each carrying its `effective_status` | none (Operation 50, Operation 51) |

NOTE: watch the third write. This atom has three mutating actions — [Allocate], [Redeem] and [Revoke] — and the signature block gives a storage-failure arm to two of them. A redeeming [Redeem] lowers the counter and can move the status in the same operation, and the value set carries no outcome for that write failing. The case table above names the two writes that have the arm rather than *either write*, which is as far as a language rewrite may go: adding the arm is logic, and it is docketed (`open-questions.md` §*A mutating action with no write-failure outcome*). Council read 22.

WHY:
[Redeem] takes exactly one argument, and that is a commitment rather than an omission. Accepting a `redeemer_ref` would create the appearance of identity-keyed authorization while the actual check stayed bearer-keyed — a misleading interface that hides the authorization model from the composing system. So the signature makes the bearer semantics unambiguous, and a composing pattern that needs to record who redeemed keeps that in its own records (Operation 20–22, Invariant 3.1, Invariant 5.2).

Both time guards write nothing. A [Redeem] on a lapsed capability answers `invalid(expired)` and a [Revoke] on one answers [Already Terminal], each a pure derivation against the injected reading that leaves the record [Allocated] — no status, no timestamp, no counter move (Operation 26, Operation 38, Expiry 1–3). A lapsed capability already reads [Expired] and needs no withdrawal.

The rejection order on [Revoke] is carried by the guards: the three [Already Terminal] cases are exclusive of the revocable case by construction, and the attribution checks are conditioned on the capability being revocable — so a [Revoke] on a terminal capability with a blank reason answers [Already Terminal] and never [Invalid Request] (Operation 36–40).

Revocation forfeits the remaining redemptions without spending them, and so does a lapse. The counter is evidence of redemption history, not of remaining life, which is why neither path touches it (Operation 31, Operation 46).

### State

```text
State 1: EVERY capability MUST stand in EXACTLY ONE OF allocated, redeemed, revoked.
State 2: EVERY capability MUST carry capability_token, allocator_ref, scope, max_redemptions, remaining_redemptions, allocated_at, expires_at and status.
State 3: EVERY capability MUST carry an expires_at.
State 4: A redeemed capability MUST carry a redeemed_at.
State 5: A revoked capability MUST carry revoked_at, revoked_by_ref and revocation_reason.
State 6: An allocated capability MUST NOT carry a redeemed_at.
State 7: An allocated capability MUST NOT carry a revocation field.
State 8: A capability MUST NOT carry a stored expired status.
State 9: A capability MUST NOT carry an expiry timestamp beside expires_at.
State 10: A capability MUST NOT carry a redeemer's identity.
State 11: The atom MUST NOT offer a transition out of redeemed.
State 12: The atom MUST NOT offer a transition out of revoked.
State 13: The atom MUST NOT remove a capability from the store.
State 14: The atom MUST NOT evaluate a scope.
State 15: The atom MUST NOT hold an authorization policy.
```

Terms › `revocation field`: `revoked_at` | `revoked_by_ref` | `revocation_reason` — what [Revoke] writes and nothing else does.

Terms › `status`: `allocated` | `redeemed` | `revoked` — redeemable, exhausted, or cancelled. `expired` is not a value of it.

#### Expiry

```text
Expiry 1: A lapse MUST NOT write to the capability.
Expiry 2: A lapse MUST NOT fire a transition.
Expiry 3: A lapse MUST NOT lower remaining_redemptions.
Expiry 4: The atom MUST NOT stamp an expiry.
Expiry 5: The deployment MUST NOT schedule a lapse.
Expiry 6: The atom MUST derive a lapse from expires_at against now.
Expiry 7: [Read] MUST surface a lapse as the effective_status.
Expiry 8: [Redeem] MUST surface a lapse as expired.
Expiry 9: [Revoke] MUST surface a lapse as already-terminal.
```

WHY:
The boundary instant is on the dead side: `now` reaching `expires_at` reads [Expired], which matches the redemption guard requiring `now` short of it. The stored state space stays three values because lapsing needs no fourth, and nothing can lag the clock it idealizes (State 1, State 8, Expiry 6).

### Invariants

- **Invariant 1 — Allocation provenance immutability.**
  ```text
  Invariant 1.1: A recorded capability's capability_token, allocator_ref, scope, max_redemptions, allocated_at and expires_at MUST NOT change.
  ```
- **Invariant 2 — Redemption counter monotonic.**
  ```text
  Invariant 2.1: A capability's remaining_redemptions MUST NOT rise.
  Invariant 2.2: A capability's max_redemptions MUST NOT EXCEED the remaining_redemptions at allocation.
  Invariant 2.3: A capability's remaining_redemptions MUST NOT EXCEED the max_redemptions.
  Invariant 2.4: A redeeming [Redeem] MUST lower remaining_redemptions by one.
  Invariant 2.5: A capability's remaining_redemptions MUST NOT fall below zero.
  ```
- **Invariant 3 — Bearer redemption.**
  ```text
  Invariant 3.1: [Redeem] MUST accept the capability_token as the whole call.
  Invariant 3.2: [Redeem] MUST NOT accept an identity claim.
  Invariant 3.3: [Redeem] MUST NOT check an identity claim.
  Invariant 3.4: A capability MUST NOT carry a redeemer's identity.
  ```
- **Invariant 4 — Exhaustion atomicity.**
  ```text
  Invariant 4.1: [Redeem] MUST commit the lowering to zero and the move to redeemed in one operation.
  Invariant 4.2: Two concurrent [Redeem] calls on a capability whose remaining_redemptions stands at one MUST answer redeemed once.
  Invariant 4.3: The [Redeem] call the serialization places second MUST answer exhausted.
  Invariant 4.4: The successful [Redeem] calls on one capability MUST NOT EXCEED the max_redemptions.
  Invariant 4.5: An uncommitted crash MUST leave the capability as the call found the capability.
  Invariant 4.6: A committed crash MUST leave the lowering standing.
  Invariant 4.7: A partial write MUST NOT stand as an observable capability.
  ```
- **Invariant 5 — Audit asymmetry.**
  ```text
  Invariant 5.1: EVERY capability MUST carry the allocator_ref.
  Invariant 5.2: An auditor MUST NOT find a redeemer's identity in the capability store.
  Invariant 5.3: The atom MUST NOT infer a redeemer's identity.
  ```
- **Invariant 6 — Three structurally distinct terminal modes, two stored and one derived.**
  ```text
  Invariant 6.1: A redeemed capability MUST carry a redeemed_at AND a remaining_redemptions of zero.
  Invariant 6.2: A revoked capability MUST carry revoked_at, revoked_by_ref and revocation_reason.
  Invariant 6.3: A lapsed capability MUST NOT carry a redeemed_at.
  Invariant 6.4: A lapsed capability MUST NOT carry a revocation field.
  Invariant 6.5: An implementation MUST NOT merge two terminal modes.
  Invariant 6.6: A redeemed capability MUST NOT carry a revocation field.
  Invariant 6.7: A revoked capability MUST NOT carry a redeemed_at.
  ```
- **Invariant 7 — Stored terminal state absorbing.**
  ```text
  Invariant 7.1: A redeemed capability MUST NOT leave redeemed.
  Invariant 7.2: A revoked capability MUST NOT leave revoked.
  Invariant 7.3: A lapsed capability MUST NOT admit a write.
  Invariant 7.4: A lapsed capability MUST stand in allocated.
  ```
  WHY: the asymmetry is the point. Exhaustion and revocation are absorbing *stored* states; a lapse admits no write either, but its stored status stays [Allocated] because nothing was ever written to move it. That is what lets Invariant 6 and Invariant 7 range over writes alone (Invariant 13.1, Expiry 1).
- **Invariant 8 — Scope immutability.**
  ```text
  Invariant 8.1: A recorded scope MUST NOT change.
  Invariant 8.2: A deployment re-scoping an authorization MUST call [Allocate].
  ```
- **Invariant 9 — Revocation attribution completeness.**
  ```text
  Invariant 9.1: EVERY revoked capability MUST carry a revoked_at.
  Invariant 9.2: EVERY revoked capability's revoked_by_ref MUST carry a non-whitespace character.
  Invariant 9.3: EVERY revoked capability's revocation_reason MUST carry a non-whitespace character.
  ```
- **Invariant 10 — Every capability has a finite lifetime.**
  ```text
  Invariant 10.1: EVERY capability MUST carry an expires_at.
  Invariant 10.2: The atom MUST NOT record a capability carrying no expires_at.
  ```
- **Invariant 11 — Capability durability over this atom's own surface.**
  ```text
  Invariant 11.1: The atom MUST NOT offer a removal surface.
  Invariant 11.2: An action the atom offers MUST NOT reduce the capability count.
  Invariant 11.3: A storage-failure rejection MUST leave no partial capability in the store.
  ```
  WHY: the atom offers no deletion and does not forbid one either. A deployment purging terminal records under [Retention Window](./retention-window.md) is that pattern's declared act, and the consequence is named rather than hidden — a purged token answers [Not Known], which therefore covers *never allocated* and *allocated, terminal, since purged* alike (Non-goal 21, Non-goal 22).
- **Invariant 12 — Capability token uniqueness.**
  ```text
  Invariant 12.1: Two capabilities MUST NOT share a capability_token.
  Invariant 12.2: IF a write would reuse a capability_token THEN the store MUST refuse the write.
  Invariant 12.3: [Allocate] MUST NOT allocate a capability_token any capability carries.
  Invariant 12.4: Invariant 12.1 MUST range over the capabilities the store retains.
  ```
  WHY: uniqueness is store-enforced and not merely probabilistic, which is the difference between an invariant and a hope. The entropy source makes a collision vanishingly unlikely; Invariant 12.2 makes one impossible to commit, and a rejected collision surfaces as [Storage Failure]. Invariant 12.4 is the honest scope: a purge under a composed retention pattern takes records out of the store, so lifetime-uniqueness ranges over what the store still holds (Invariant 11.2).
- **Invariant 13 — Expiry is derived, never written.**
  ```text
  Invariant 13.1: A capability MUST NOT carry a stored expired status.
  Invariant 13.2: A capability MUST NOT carry an expiry timestamp beside expires_at.
  Invariant 13.3: A lapse MUST NOT write to the capability.
  Invariant 13.4: The effective_status MUST rest on expires_at and now alone.
  ```

Invariants 1 and 3 together give the *authorization envelope* property — a capability's full authorization is readable from one immutable record, and no identity check contaminates the bearer semantics. Invariants 2 and 4 give *redemption integrity* — the counter falls exactly once per redemption, even under concurrency, and the exhausting move is atomic. Invariants 5, 6 and 13 give *audit clarity* — the record always answers who allocated and what was authorized, never who redeemed; the two stored terminals are unambiguous; and the derived [Expired] is reproducible from the deadline and the read-time clock. Invariant 12 gives *lookup determinism* — [Redeem] resolves to one capability or none.

Two properties are entailed rather than stated, and the formal model ([`capability.als`](./capability.als), this spec's sibling) confirms both. A `remaining_redemptions` of zero is reachable only through the exhausting move, which atomically stands the capability in [Redeemed] — [Revoke] does not lower the counter and a lapse never writes — so a zero counter outside [Redeemed] is unreachable (Invariant 2.4, Invariant 4.1, Operation 46, Expiry 3). And a [Revoked] capability always carries a counter above zero, because [Revoke] requires a revocable capability and preserves the counter, and the stored terminals are absorbing (Invariant 7.1, Invariant 7.2, Operation 46).

---

## Examples

### Single-use password-reset link

An account-recovery service allocates a reset capability: `allocate(allocator_ref: recovery_svc_r01, scope: "reset-password::acct_a9931", max_redemptions: 1, ttl: 3600)` → `cap_tok_7f3a`, with the host injecting `now: 2026-09-01T09:00:00Z` and the token's random material at the seam. The record lands in [Allocated] with `remaining_redemptions: 1` and `expires_at: 10:00:00Z`. The service emails the link.

The user clicks it twelve minutes later. `redeem(cap_tok_7f3a)` → `redeemed(scope: "reset-password::acct_a9931", allocator_ref: recovery_svc_r01)`. The counter reaches zero and the status moves to [Redeemed] with `redeemed_at: 09:12:00Z`, in one operation. The reset page opens. **No redeemer identity is recorded** — the store cannot say whether the account owner clicked the link or somebody who intercepted the email did, and that is the model working as designed (Invariant 5.2).

A second click on the same link → `invalid(exhausted)` (Operation 24).

### Multi-use pre-signed read token

A document service allocates a five-use read token: `allocate(allocator_ref: share_svc_s02, scope: "read::document::doc_d448", max_redemptions: 5, ttl: 604800)` → `cap_tok_b81c`. Three fetches over the week each answer `redeemed(...)` and leave the counter at 2, with the status still [Allocated] (Operation 30).

The window closes with two redemptions unspent. **Nothing is called and nothing is written.** A [Read] now reports `effective_status: expired`; the counter still reads 2, because a lapse forfeits the remaining redemptions by derivation rather than by spending them (Expiry 3, Invariant 6.3). A fourth fetch answers `invalid(expired)`.

### Rejection paths

`allocate(allocator_ref: share_svc_s02, scope: "read::document::doc_d448", max_redemptions: 0, ttl: 3600)` → `rejected(invalid-request)`. A capability redeemable zero times authorizes nothing (Operation 9).

`revoke(cap_tok_7f3a, revoked_by_ref: admin_a01, reason: "incident")` against the exhausted reset token → `rejected(already-terminal)` (Operation 36). The same call against a capability whose window has merely closed answers the same way, by derivation, writing nothing (Operation 38) — which is the one place this atom and [Session](./session.md) part company on identical mechanics, and neither declares the fork.

`redeem(cap_tok_forged)` → `invalid(not-known)`. No record for the token — and after a composed retention purge, the same answer covers a capability that once existed (Invariant 12.4).

### Regulated adversarial scenarios

- **Regulator audit — who authorized a disclosure.** An auditor asks under what authority a document was released. The store yields the capability: `allocator_ref: share_svc_s02`, `scope: "read::document::doc_d448"`, `max_redemptions: 5`, `allocated_at`, `expires_at`. Invariant 1.1 is the answer — the envelope is immutable and readable from one record. What the store *cannot* answer is who fetched the document, and the auditor must be told that up front: attribution for the redemption side lives in the composing [Audit Trail](../compositions/audit-trail.md), never here (Invariant 5.2, Composition note 4).
- **Disputed reset — the account owner denies resetting.** The store shows `cap_tok_7f3a` allocated to `recovery_svc_r01` at `09:00`, redeemed at `09:12`, exhausted. It does not show who redeemed it, and no amount of reading will make it. That is the structural finding, not a gap: the capability is evidence that *someone holding the link* reset the password within the window, which is exactly what a bearer credential attests (Invariant 3.4, Invariant 5.3).
- **Breach triage — which capabilities are still redeemable.** Tokens appear in an exposed log. The investigator reads each record's `effective_status` against the investigation clock: which are live, which lapsed, which exhausted or revoked. Every live one is revoked with attribution. The lapsed ones **cannot** be revoked — they answer [Already Terminal] — so the attributed closure a [Session](./session.md) breach response can record is not available here, and the triage record has to lean on the [Audit Trail](../compositions/audit-trail.md) instead (Operation 38, Composition note 4).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the capability store and the read-time clock, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find EVERY capability's allocator_ref, scope, max_redemptions, allocated_at and expires_at present (Invariant 5.1, Invariant 10.1).
Check 2.1: An auditor MUST find no capability's remaining_redemptions below zero (Invariant 2.5).
Check 2.2: An auditor MUST find EVERY capability's remaining_redemptions no higher than the max_redemptions (Invariant 2.3).
Check 2.3: An auditor MUST find a remaining_redemptions of zero AND a redeemed_at on EVERY redeemed capability (Invariant 6.1).
Check 2.4: An auditor MUST find a remaining_redemptions above zero on EVERY allocated capability (Invariant 4.1).
Check 3.1: An auditor MUST find no redeemer identity in any capability field (Invariant 3.4, Invariant 5.2).
Check 4.1: An auditor MUST find no stored expired status on any capability (Invariant 13.1).
Check 4.2: An auditor MUST find no expiry timestamp beside expires_at (Invariant 13.2).
Check 4.3: An auditor MUST reproduce the effective_status from expires_at against the read-time clock (Invariant 13.4).
Check 5.1: An auditor MUST find no terminal field written by a lapse (Invariant 13.3, Invariant 6.3, Invariant 6.4).
Check 5.2: An auditor MUST find EVERY revoked capability's remaining_redemptions above zero (Invariant 7.2, Operation 46).
Check 6.1: An auditor MUST find a revoked_at, a revoked_by_ref and a revocation_reason on EVERY revoked capability (Invariant 9.1, Invariant 9.2, Invariant 9.3).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```text
External check 1: An auditor MUST read a refused [Redeem] from the composing [Audit Trail](../compositions/audit-trail.md) (Invariant 7.3).
External check 2: An auditor needing a redemption's attribution MUST read the attribution from the composing pattern's records (Invariant 5.2, Non-goal 6).
External check 3: An auditor needing a capability's field history MUST read the history from the composing [Audit Trail](../compositions/audit-trail.md) (Invariant 1.1).
```

WHY:
Two things this store cannot clear, named rather than assumed. A refused [Redeem] leaves no trace in the record — no counter move, no field — so whether anyone *attempted* a redemption after exhaustion, revocation or lapse is not auditable here and needs the composing journal (External check 1, Expiry 1). And the redeemer's identity is absent by construction, so an audit that needs it is asking the wrong store (External check 2, Invariant 5.2).

Check 4.3 asserts on the reproduced projection rather than on a stored field, because there is no stored field to assert on — an auditor who tested one would be testing a cache the atom refuses to keep.

## Non-goals

```text
Non-goal 1: The atom MUST NOT confirm an allocator_ref's authority.
Non-goal 2: A deployment gating allocation MUST compose [Permissions](./permissions.md).
Non-goal 3: The atom MUST NOT evaluate a scope.
Non-goal 4: A composing pattern MUST own the scope vocabulary.
Non-goal 5: The atom MUST NOT record a redeemer's identity.
Non-goal 6: A deployment needing redemption attribution MUST record the attribution outside the atom.
Non-goal 7: The atom MUST NOT deliver a capability_token.
Non-goal 8: The atom MUST NOT protect a capability_token in transit.
Non-goal 9: The atom MUST NOT narrow a scope for a third party.
Non-goal 10: A bearer delegating a narrowed authorization MUST call [Allocate].
Non-goal 11: The atom MUST NOT notify a bearer of a revocation.
Non-goal 12: The atom MUST NOT notify an allocator_ref of a revocation.
Non-goal 13: The atom MUST NOT gate a redemption on an identity.
Non-goal 14: A deployment needing identity-keyed authorization MUST compose [Permissions](./permissions.md).
Non-goal 15: The atom MUST NOT bind an identity at redemption.
Non-goal 16: A deployment needing an identity bound at redemption MUST compose [Invitation](./invitation.md).
Non-goal 17: The atom MUST NOT record a bearer's act beyond the redemption.
Non-goal 18: A deployment needing a post-redemption record MUST compose [Audit Trail](../compositions/audit-trail.md).
Non-goal 19: The atom MUST NOT seal a capability against modification.
Non-goal 20: A deployment needing court-admissible records MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 21: The atom MUST NOT purge a terminal capability.
Non-goal 22: The atom MUST NOT forbid a deployment purging a terminal capability.
Non-goal 23: The atom MUST NOT distinguish a purged capability_token from an unallocated capability_token.
Non-goal 24: The atom MUST NOT guarantee a replay bound beyond max_redemptions and expires_at.
Non-goal 25: The atom MUST NOT attest an allocator_ref.
Non-goal 26: The atom MUST NOT attest a revoked_by_ref.
Non-goal 27: A deployment needing an attested actor MUST compose [Actor Identity](./actor-identity.md).
```

WHY:
[Allocate] makes no policy judgement. It records a capability for whatever scope, count and duration arrive, and whether those values are appropriate — and whether the caller had any right to allocate for that scope — is a question the atom cannot answer and does not pretend to (Non-goal 1, Non-goal 2).

Three neighbours are deliberately not this atom. [Permissions](./permissions.md) gates on *who is asking* and is the right primitive when that matters; this one gates on *what is presented* (Non-goal 13, Non-goal 14). [Invitation](./invitation.md) also travels as a bearer token but its resolution *binds an identity* — a named `Declined` terminal, an accepting party identified at redemption — so an onboarding flow that ends in an identity binding belongs there (Non-goal 15, Non-goal 16). And delegation is not a surface here: a bearer narrowing an authorization for a third party is a fresh [Allocate] under a new allocator, which is a new allocation event with its own provenance rather than a chain this atom tracks (Non-goal 9, Non-goal 10).

The purge posture is the honest one rather than the tidy one. The atom deletes nothing and forbids nothing, so a deployment may purge terminal records under [Retention Window](./retention-window.md) — and the cost is stated: [Not Known] then covers both *never allocated* and *allocated, terminal, since purged*, and a deployment whose obligations require telling those apart must retain the records or their audit projection for the obligation's window (Non-goal 21–23, Invariant 12.4).

## Edge cases

### String policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a string input EXCEEDS the maximum length THEN the action MUST answer invalid-request.
String 8: The deployment MUST canonicalize an opaque reference.
```

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Byte-exactness means two `allocator_ref` values differing only in normalization form are two distinct allocators here, and the audit queries that range over the field inherit that — so canonicalization is the deployment's, before the call (String 1, String 8).

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's honesty.
Clock semantics 3: The deployment MUST own the clock's timezone handling.
Clock semantics 4: A guard MAY read now ONLY IF the guard derives a lapse.
Clock semantics 5: A guard MUST NOT read now to admit a caller-supplied instant.
Clock semantics 6: The atom MUST NOT reconcile two readers disagreeing across the deadline.
```

WHY:
This atom accepts no caller-supplied instant — the window arrives as a duration and every timestamp is the seam's reading — so the clock has exactly two jobs: stamping three immutable fields, and feeding the lapse derivation that three guards read (Clock semantics 4, Clock semantics 5). Two readers with skewed clocks near the deadline may briefly disagree on whether a record reads [Expired]; that is the read-time-derivation cost, bounded by the deployment's skew envelope, and harmless because no write is at stake (Clock semantics 6).

### Concurrency

```text
Concurrency 1: The implementation MUST serialize a write on one capability_token.
Concurrency 2: The implementation MUST make the counter read and the counter write one transition.
Concurrency 3: A store enforcing a compare-and-set on remaining_redemptions MAY discharge Concurrency 2.
```

WHY:
Operation 28 reads the counter and [Redeem] then writes it; two concurrent calls at a counter of one both read *redeemable* and both write, and Invariant 4.4 — the bound the atom exists to hold — is broken by the very sequence it forbids. The guard is check-then-act and the fix is the implementation's: one transition, or a compare-and-set in the store doing the same work (Concurrency 2, Concurrency 3).

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the scope's meaning.
Composition note 3: A composing pattern MUST own the authority to allocate for a scope.
Composition note 4: A composing pattern MUST own the redemption's attribution.
Composition note 5: A composing pattern MUST own the capability_token's delivery.
Composition note 6: A composing pattern MUST own the retention of the capability store.
Composition note 7: A composing pattern reading the capability store MUST NOT write to the capability store.
Composition note 8: A composing pattern MUST NOT record a redeemer's identity on a capability.
```

WHY:
[Capability-Backed Sharing](../compositions/capability-backed-sharing.md) is the composition this atom was extracted for, and the wiring is one hop: `redeem → redeemed(scope)` feeds a [Selective Disclosure](./selective-disclosure.md) `disclose` call. The two atoms say different things — this one says *the bearer of this token is authorized to see fields X, Y, Z of record R*, that one says *fields X, Y, Z of record R were disclosed on this date* — and the composition's emergent invariant is the asymmetry made visible: the audit record reads *disclosed by bearer of capability X, allocated by actor Y*, with the allocator identified and the redeemer structurally not (Composition note 4).

[Actor Identity](./actor-identity.md) attests the allocation, so the record reads *allocated by actor Y, attested* rather than merely *by allocator_ref Y*. [Audit Trail](../compositions/audit-trail.md) journals each allocation and each successful redemption, which is where the redemption side's attribution lives and the only place a refused redemption is visible at all (External check 1, External check 2). [Tamper Evidence](./tamper-evidence.md) hash-chains the store so allocation provenance cannot be rewritten. [Privileged Access Provisioning](../compositions/privileged-access-provisioning.md) calls [Allocate] when its approval chain closes, [Redeem] inside `exercise_access` once [Session](./session.md) validates, and [Revoke] through `revoke_access` — reading this store without writing to it (Composition note 7).

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a bearer; an allocator; an auditor; the store; a capability; a status; a lapse; a liveness query; a crash; a write; an action; a string input; an opaque reference; the capability count; the capability_token's random material.

Terms › `records`: `capability` — one bearer-token authorization, carrying `capability_token`, `allocator_ref`, `scope`, `max_redemptions`, `remaining_redemptions`, `allocated_at`, `expires_at`, `status` and, once terminal, `redeemed_at` or `revoked_at` with `revoked_by_ref` and `revocation_reason`.

Terms › `record verbs`: identify, serve, offer, supply, check, compare, allocate, reuse, change, carry, share, draw, refuse, interpret, confirm, apply, accept, record, stand, answer, stamp, recompute, set, lower, rise, fall, reach, commit, leave, derive, surface, write, fire, schedule, read, rest, remove, evaluate, hold, merge, admit, infer, reduce, range, find, reproduce, own, gate, bind, narrow, deliver, protect, notify, purge, forbid, distinguish, guarantee, seal, compose, trim, normalize, case-fold, exceed, canonicalize, reconcile, serialize, make, discharge, attest, declare, call.

Terms › `value sets`: allocate answers = capability_token | rejected(invalid-request | storage-failure). redeem answers = redeemed(scope, allocator_ref) | invalid(exhausted | expired | revoked | not-known). revoke answers = revoked | rejected(invalid-request | already-terminal | not-known | storage-failure). read answers = the matching capabilities, each carrying its `effective_status`. `status` = allocated | redeemed | revoked.

Terms › `bounds`: `default capability ttl` (the validity duration [Allocate] applies where the call supplies none); `single-use default` (the `max_redemptions` [Allocate] applies where the call supplies none); `zero duration` (the floor a ttl must exceed); `zero` (the floor a max_redemptions must exceed); `maximum length` (the deployment's cap per string input).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `capability`, `capability_token`, `allocator_ref`, `scope`, `seam`, `transition`, `now`, `business caller`, `max_redemptions`, `single-use default`, `remaining_redemptions`, `ttl`, `default capability ttl`, `zero duration`, `zero`, `allocated_at`, `expiry deadline`, `expires_at`, `lapsed`, `revocable`, `effective_status`, `redeemed_at`, `revoked_at`, `revoked_by_ref`, `revocation_reason`, `reason`, `filter`, `liveness query`, `status`, `revocation field`, `blank`, `maximum length`.

#### Allocate

The behavior an allocating actor invokes to create a new capability and receive its [Capability Token]. It records the [Allocator Ref], [Scope], [Max Redemptions], [Allocated At], and [Expires At] = [Allocated At] + [TTL], sets [Remaining Redemptions] = [Max Redemptions], enters the record in [Allocated], and returns the [Capability Token] (or a rejection). It makes no policy judgment about whether the allocation is appropriate.

Kind: Operation

#### Redeem

The behavior a bearer invokes to exercise a capability, presenting only the [Capability Token] — no identity argument. On a live capability it decrements [Remaining Redemptions] and returns `redeemed(scope, allocator_ref)`; the call that brings the counter to zero atomically transitions the record to [Redeemed]. It is not idempotent and records no redeemer identity. Its five outcomes (`redeemed`, `invalid(exhausted | expired | revoked | not-known)`) are all first-class.

Kind: Operation

#### Revoke

The behavior invoked to cancel a still-live capability, with attribution. Permitted only while stored [Status] = [Allocated] and [Now] < [Expires At]; it transitions the record to [Revoked] and stamps [Revoked At], [Revoked By Ref], and [Revocation Reason]. On a stored terminal or a lapsed window it returns [Already Terminal].

Kind: Operation

#### Read

The render-time behavior that returns the matching capability records, each carrying its derived [Effective Status]. It only reads; no record changes. It is the surface every liveness query applies, since a raw [Allocated] with [Expires At] in the past reads [Expired], not live.

Kind: Operation

#### Capability Token

The opaque, cryptographically random, immutable, system-generated value [Allocate] produces — both the record's identity and the bearer credential presented to [Redeem] and [Revoke]. It is the injected `id_t`; no two records share one, and it is not reused after a capability reaches a terminal state.

Kind:     Field
Field of: Capability
Projects: capability_token

#### Allocator Ref

The opaque reference to the actor or mechanism that allocated the capability — the one identity the record permanently carries (the audit asymmetry). Set on [Allocate], immutable thereafter. The atom does not validate that it is an active principal.

Kind:     Field
Field of: Capability
Projects: allocator_ref

#### Scope

The opaque value describing what the capability authorizes, returned to the bearer by [Redeem]. The atom stores and returns it but never interprets it; the composing pattern defines and reads scope values. Set on [Allocate], immutable thereafter.

Kind:     Field
Field of: Capability
Projects: scope

#### Max Redemptions

The total number of redemptions permitted, set on [Allocate] (or 1 if null — the single-use default). Immutable thereafter; [Remaining Redemptions] is initialised from it.

Kind:     Field
Field of: Capability
Projects: max_redemptions

#### Remaining Redemptions

The redemptions still available — the one mutable field between allocation and a stored terminal. Set to [Max Redemptions] on [Allocate], decremented by exactly 1 on each successful [Redeem], never increasing; reaching 0 is the exhaustion transition to [Redeemed].

Kind:     Field
Field of: Capability
Projects: remaining_redemptions

#### Allocated At

The wall-time [Allocate] was called, stamped from the injected [Now]. Immutable thereafter. [Expires At] is computed once as [Allocated At] + [TTL].

Kind:     Field
Field of: Capability
Projects: allocated_at

#### Expires At

The absolute expiry time, set on [Allocate] as [Allocated At] + [TTL]. Never null and never mutated. It is the sole stored input to the expiry derivation: a still-[Allocated] record reads [Expired] once [Now] ≥ [Expires At].

Kind:     Field
Field of: Capability
Projects: expires_at

#### Status

The stored status of a capability: [Allocated], [Redeemed], or [Revoked]. Set to [Allocated] on [Allocate]; transitions once to a stored terminal and never returns. The derived [Expired] is *not* a value of this field — it appears only in the [Effective Status] read projection.

Kind:     Field
Field of: Capability
Projects: status

#### Redeemed At

The wall-time the capability exhausted (its counter reached zero), stamped from the injected [Now]. Present only in [Redeemed]; null otherwise; immutable once set.

Kind:     Field
Field of: Capability
Projects: redeemed_at

#### Revoked At

The wall-time the capability was revoked, stamped from the injected [Now] on [Revoke]. Present only in [Revoked]; null otherwise; immutable once set.

Kind:     Field
Field of: Capability
Projects: revoked_at

#### Revoked By Ref

The opaque reference to the actor or mechanism that performed the revocation. Required at [Revoke]; null until revocation; immutable once set.

Kind:     Field
Field of: Capability
Projects: revoked_by_ref

#### Revocation Reason

The caller-supplied reason recorded for the revocation (from the [Reason] parameter). Required at [Revoke]; null until revocation; immutable once set.

Kind:     Field
Field of: Capability
Projects: revocation_reason

#### Effective Status

The status [Read] attaches to each returned record: [Expired] when [Status] = [Allocated] ∧ [Now] ≥ [Expires At], otherwise the stored [Status]. A pure projection over the record and the injected [Now] — derived at read time, never stored — and what makes [Redeem] return `invalid(expired)`. Every liveness query applies it.

Kind:     Field
Field of: Capability
Projects: effective_status

#### TTL

The validity duration [Allocate] consumes to compute [Expires At] ([Allocated At] + [TTL]). Supplied per call; if null, the deployment's default applies; zero or negative is rejected. It is never stored under its own name — only the computed [Expires At] is stored.

Kind:         Parameter
Parameter of: Allocate
Projects:     ttl

#### Reason

The caller-supplied reason string [Revoke] consumes, written into [Revocation Reason]. Required (non-null, non-empty); not stored under this name.

Kind:         Parameter
Parameter of: Revoke
Projects:     reason

#### Now

The current clock reading every action consumes — the pipeline's `clock_t`, injected at the I/O seam, never read inside a transition and never a signature parameter. It stamps the immutable write timestamps ([Allocated At], [Redeemed At], [Revoked At]) and drives the pure expiry derivation in guards and [Read] (no write).

Kind:         Parameter
Parameter of: Allocate
Projects:     now

#### Allocated

The single non-terminal stored state: the capability may be redeemed, with [Remaining Redemptions] > 0. A record enters [Allocated] on [Allocate] and leaves it only by a write — exhaustion to [Redeemed], revocation to [Revoked]. A still-[Allocated] record past [Expires At] reads [Expired] by derivation.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Redeemed

The stored terminal a capability reaches when its redemption counter hits zero (exhaustion). Carries [Redeemed At] and [Remaining Redemptions] = 0. Absorbing: no transition leaves it.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Revoked

The stored terminal a capability reaches when it is explicitly cancelled within its window. Carries [Revoked At], [Revoked By Ref], and [Revocation Reason]. Absorbing: no transition leaves it.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Expired

The derived terminal mode — never stored. A still-[Allocated] record whose window has lapsed ([Now] ≥ [Expires At]) reads [Expired] via the [Effective Status] projection; no field is written and the counter is never decremented by lapse.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Not Known

The outcome returned when the supplied [Capability Token] references no record — `invalid(not-known)` from [Redeem], a [Not Known] rejection from [Revoke]. A lookup miss; after external purge it also subsumes once-allocated-but-purged records.

Kind:      Member
Member of: the action outcome
Role:      Outcome
Projects:  not-known

#### Already Terminal

The refusal [Revoke] returns when the capability is not revocable — a stored terminal ([Redeemed] or [Revoked]) *or* a still-[Allocated] record whose window has lapsed (which reads [Expired]). A pure derivation that writes nothing.

Kind:      Member
Member of: the Revoke rejection
Role:      Outcome
Projects:  already-terminal

#### Invalid Request

The refusal [Allocate] or [Revoke] returns when an argument is malformed — a null/empty [Allocator Ref], [Scope], [Revoked By Ref], or [Reason], a non-positive [Max Redemptions] or [TTL], or an absent deployment default. A guard rejection before any store write; no record is created or changed.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Storage Failure

The refusal [Allocate] or [Revoke] returns when the store write fails after the preconditions pass. No partial record is written (for [Allocate]) or no state change is committed (for [Revoke]); a token-reuse write is also rejected here (Invariant 12). The caller must treat it as definitive.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Allocate]: #allocate
[Redeem]: #redeem
[Revoke]: #revoke
[Read]: #read
[Capability Token]: #capability-token
[Allocator Ref]: #allocator-ref
[Scope]: #scope
[Max Redemptions]: #max-redemptions
[Remaining Redemptions]: #remaining-redemptions
[Allocated At]: #allocated-at
[Expires At]: #expires-at
[Status]: #status
[Redeemed At]: #redeemed-at
[Revoked At]: #revoked-at
[Revoked By Ref]: #revoked-by-ref
[Revocation Reason]: #revocation-reason
[Effective Status]: #effective-status
[TTL]: #ttl
[Reason]: #reason
[Now]: #now
[Allocated]: #allocated
[Redeemed]: #redeemed
[Revoked]: #revoked
[Expired]: #expired
[Not Known]: #not-known
[Already Terminal]: #already-terminal
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure

## Standards references

- **Daniel Jackson, *Software Abstractions*** — `Capability [Resource]` is a concept in Jackson's concept catalog. The atom's `scope` field (what the capability authorizes), `allocate` and `redeem` actions, and the bearer-key semantics correspond directly to Jackson's formulation. Grace Commons expresses this concept in the atom format; the structural decisions are inherited from the concept catalog.
- **Mark Miller and the object-capability (OCAP) literature** — the formal theoretical grounding for bearer-key authorization. The principle *"an unforgeable reference to an object carries the authority to use that object"* is the foundation. Miller's work on capability-based security, including the E language and the Waterken server, establishes the invariants this atom formalizes.
- **Levy, H.M. (1984), *Capability-Based Computer Systems*** — the canonical reference for capability-based security systems. Levy establishes the three properties of capabilities: unforgeability, transferability, and access control by possession. The atom satisfies unforgeability (the `capability_token` — cryptographically random, opaque, system-generated) and access-control-by-possession (the bearer semantics of `redeem`); transferability and attenuation are deliberately outside the atom's surface — the atom neither prohibits, tracks, nor models token sharing or scope-narrowing delegation (see Edge cases — Capability chaining), so its claim on the OCAP literature is the bearer/unforgeability subset, not full conformance.
- **Birgisson, A., Politz, J.G., Erlingsson, Ú., Taly, A., Vrable, M., Lentczner, M. (2014), *Macaroons: Cookies with Contextual Caveats for Decentralized Authorization in the Cloud*** — Macaroons are a constrained Capability variant: a capability token that can be attenuated (scope narrowed) by adding caveats before being passed to a third party. The atom models the base Capability concept without macaroon-style attenuation; composing patterns that need contextual caveats may build on this atom.
- **RFC 6749 §1.4 (OAuth 2.0 — Access Tokens)** — OAuth 2.0 (the open authorization framework, version 2.0) access tokens are a widely deployed capability-adjacent pattern: a bearer token scoped to specific resources, with limited lifetime, that grants access without per-request identity verification. Cited with explicit caveats: OAuth 2.0 conflates bearer-token authorization with identity-bound flows (the authorization server authenticates the client; the token is identity-linked in practice even if the resource server checks only the token). This atom defines the pure OCAP surface — the token IS the authorization, with no identity linkage — which is a stricter and simpler model than OAuth 2.0 in full. Composing patterns that implement OAuth 2.0-compatible flows will compose this atom with identity-aware patterns.
- **GDPR Article 32 (Security of Processing)** — capability tokens are an access-control mechanism for regulated data disclosures. The `allocator_ref` and `scope` fields, immutably recorded and auditable from the capability store alone, satisfy the "appropriate technical measures" requirement for demonstrating that disclosures were authorized.
- **HIPAA (Health Insurance Portability and Accountability Act) §164.514(d) (Minimum Necessary Standard)** — the HIPAA requirement that disclosures be limited to the minimum necessary information. A capability's `scope` is the mechanism for encoding the minimum necessary field set; the composing Capability-Backed Sharing pattern is where the minimum-necessary constraint is enforced against the disclosure.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of separating bearer-key authorization (Capability) from identity-keyed authorization (Permissions) and from identity-binding onboarding (Invitation).
- **Eiffel's design-by-contract** — named rejection reasons; preconditions on `allocate` and `revoke`; first-class `redeem` outcomes.

---

## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: verified — capability.als + 1 twin, 2026-06-23
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/capability.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the thirteen invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared `lapsed` and `revocable` so no rule carries the comparison, the arithmetic in `allocated_at + ttl` moved into a declared `expiry deadline` (Hard invariant 24), the two things the store cannot clear promoted from prose caveats to `External check 1–2`, the two Alloy-confirmed entailments kept as prose beneath the invariants rather than given numbers they never had, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rewrite surfaced one cross-atom fork it does not resolve: a lapsed capability answers [Already Terminal] to [Revoke] while a lapsed [Session](./session.md) accepts one, same mechanic and opposite rulings, neither declaring the other — docketed rather than reconciled, because reconciling it is logic.

NOTE: End of Capability.

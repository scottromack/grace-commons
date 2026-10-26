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

Capability expresses bearer-token authorization: holding the token grants the right, no matter who holds it. Each capability ties a [Scope] — what it authorizes, opaque to the atom and interpreted by whatever uses it — to a redemption envelope: how many times it may be used, and until when. It is named by a cryptographically random [Capability Token] — a value drawn so that no one can guess it — that doubles as the credential presented to redeem it, and nothing else is required to redeem.

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

```
Identity 1: The atom MUST identify a capability by the capability token.
Identity 2: The capability token MUST serve as the bearer credential [Redeem] accepts.
Identity 3: The capability token MUST serve as the bearer credential [Revoke] accepts.
Identity 4: The host MUST allocate a capability token at the seam.
Identity 5: The transition MUST NOT allocate a capability token.
Identity 6: The atom MUST NOT reuse a capability token any retained capability carries.
Identity 7: The atom MUST NOT change a capability token.
Identity 8: Two capabilities MUST NOT share a capability token.
Identity 9: The deployment MUST draw a capability token from a cryptographically secure random source.
Identity 10: The deployment MUST NOT draw a capability token from the capability's public properties.
Identity 11: IF a write would reuse a capability token THEN the database MUST refuse the write.
Identity 12: The atom MUST NOT interpret an allocator reference.
Identity 13: The atom MUST NOT confirm an allocator reference's authority.
```

Term capability: one bearer-token authorization with a redemption envelope — the record this atom holds.

Term capability token: the opaque value naming one capability — a [Capability Token]; unguessable, host-allocated at the seam, and the capability [Redeem] and [Revoke] accept.

Term allocator reference: the opaque reference naming the actor that created the capability — an [Allocator Reference].

Term scope: the opaque value describing what the capability authorizes — a [Scope]; stored at allocation, answered at redemption, never evaluated.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the capability token's random material here.

Term transition: the atom's evaluation of one call against the capability records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

```
State 1: EVERY capability MUST stand in EXACTLY ONE OF allocated, redeemed, revoked.
State 2: EVERY capability MUST carry capability token, allocator reference, scope, max redemptions, remaining redemptions, allocation instant, expiry instant and status.
State 3: EVERY capability MUST carry an expiry instant.
State 4: A redeemed capability MUST carry a redemption instant.
State 5: A revoked capability MUST carry revocation instant, revoked by reference and revocation reason.
State 6: An allocated capability MUST NOT carry a redemption instant.
State 7: An allocated capability MUST NOT carry a revocation field.
State 8: A capability MUST NOT carry a stored expired status.
State 9: A capability MUST NOT carry an expiry timestamp beside expiry instant.
State 10: A capability MUST NOT carry a redeemer's identity.
State 11: The atom MUST NOT offer a transition out of redeemed.
State 12: The atom MUST NOT offer a transition out of revoked.
State 13: The atom MUST NOT remove a capability from the database.
State 14: The atom MUST NOT evaluate a scope.
State 15: The atom MUST NOT hold an authorization policy.
```

Term revocation field: revocation instant | revoked by reference | revocation reason — what [Revoke] writes and nothing else does.

Term status: allocated | redeemed | revoked — redeemable, exhausted, or cancelled. expired is not a value of it.

#### Expiry

```
Expiry 1: A lapse MUST NOT write to the capability.
Expiry 2: A lapse MUST NOT fire a transition.
Expiry 3: A lapse MUST NOT lower remaining redemptions.
Expiry 4: The atom MUST NOT stamp an expiry.
Expiry 5: The deployment MUST NOT schedule a lapse.
Expiry 6: The atom MUST derive a lapse from expiry instant against now.
Expiry 7: [Read] MUST surface a lapse as the effective status.
Deleted: Expiry 8. Operation 26 owns it.
Deleted: Expiry 9. Operation 38 owns it.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the capability records PER Execution Contract Database 1 through 4, Execution Contract Read 1 through 3 and Execution Contract Refusal 1.
Capability requirement 6: The deployment MAY configure a default capability ttl ONLY IF the default capability ttl EXCEEDS the zero duration.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Clock dependence 1 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 28 owns it.
```

### Operations

```
allocate(allocator_ref, scope, max_redemptions, ttl)
  answers capability_token
  refuses invalid-request | storage-failure

redeem(capability_token)
  answers redeemed(scope, allocator_ref) | invalid(redemption failure)
  refuses storage-failure

revoke(capability_token, revoked_by_ref, reason)
  answers revoked
  refuses not-known | already-terminal | invalid-request | storage-failure

read(filter)
  answers capability_records
```

Term redemption failure: exhausted | expired | revoked | not-known — the reasons [Redeem] gives for an invalid capability.

```
Operation 1: [Allocate] MUST record EXACTLY ONE capability per successful call.
Operation 2: [Allocate] MUST stand the capability in allocated.
Operation 3: [Allocate] MUST answer the capability token.
Operation 4: IF allocator reference EQUALS blank THEN [Allocate] MUST answer invalid-request.
Operation 5: IF scope EQUALS blank THEN [Allocate] MUST answer invalid-request.
Operation 6: IF max redemptions EQUALS blank THEN [Allocate] MUST apply the single-use default.
Operation 7: [Allocate] MUST accept a max redemptions ONLY IF the max redemptions EXCEEDS zero.
Operation 8: IF zero EXCEEDS max redemptions THEN [Allocate] MUST answer invalid-request.
Operation 9: IF max redemptions EQUALS zero THEN [Allocate] MUST answer invalid-request.
Operation 10: IF ttl EQUALS blank THEN [Allocate] MUST apply the default capability ttl.
Operation 11: IF the default capability ttl EQUALS blank THEN [Allocate] MUST answer invalid-request.
Operation 12: [Allocate] MUST accept a ttl ONLY IF the ttl EXCEEDS the zero duration.
Operation 13: IF ttl DOES NOT EQUAL blank AND the ttl DOES NOT EXCEED the zero duration THEN [Allocate] MUST answer invalid-request.
Operation 14: [Allocate] MUST stamp allocation instant from the injected now.
Operation 15: [Allocate] MUST stamp expiry instant from the expiry deadline.
Operation 16: [Allocate] MUST NOT recompute expiry instant from a later clock reading.
Operation 17: [Allocate] MUST set remaining redemptions to the max redemptions.
Operation 18: IF the database refuses the write THEN [Allocate] MUST answer storage-failure.
Operation 19: [Redeem] MUST answer EXACTLY ONE OF redeemed, exhausted, expired, revoked, not-known, storage-failure.
Operation 20: [Redeem] MUST accept the capability token as the whole call.
Operation 21: [Redeem] MUST NOT accept an identity input.
Operation 22: [Redeem] MUST NOT record a redeemer's identity.
Operation 23: IF the capability token names no capability THEN [Redeem] MUST answer not-known.
Operation 24: IF the capability's status EQUALS redeemed THEN [Redeem] MUST answer exhausted.
Operation 25: IF the capability's status EQUALS revoked THEN [Redeem] MUST answer revoked.
Operation 26: IF the capability is lapsed AND the capability's status EQUALS allocated THEN [Redeem] MUST answer expired.
Operation 27: [Redeem] MUST answer expired ONLY IF the capability's status EQUALS allocated.
Operation 28: [Redeem] MUST answer redeemed ONLY IF the capability's status EQUALS allocated AND the capability is not lapsed.
Operation 29: [Redeem] MUST carry the scope and the allocator reference in a redeemed answer.
Operation 30: A redeeming [Redeem] MUST lower remaining redemptions by one.
Operation 31: A refused [Redeem] MUST NOT lower remaining redemptions.
Operation 32: IF remaining redemptions reaches zero THEN [Redeem] MUST stand the capability in redeemed.
Operation 33: IF remaining redemptions reaches zero THEN [Redeem] MUST stamp redemption instant from the injected now.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Operation 35: IF the capability token names no capability THEN [Revoke] MUST answer not-known.
Operation 36: IF the capability's status EQUALS redeemed THEN [Revoke] MUST answer already-terminal.
Operation 37: IF the capability's status EQUALS revoked THEN [Revoke] MUST answer already-terminal.
Operation 38: IF the capability is lapsed THEN [Revoke] MUST answer already-terminal.
Operation 39: IF the capability is revocable AND revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 40: IF the capability is revocable AND reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 41: [Revoke] MUST stand the capability in revoked.
Operation 42: [Revoke] MUST stamp revocation instant from the injected now.
Operation 43: [Revoke] MUST record revoked by reference on the capability.
Operation 44: [Revoke] MUST record the reason as the revocation reason.
Deleted: Operation 45. Execution Contract Database 1 owns it.
Operation 46: [Revoke] MUST NOT lower remaining redemptions.
Operation 47: [Revoke] MUST answer revoked.
Operation 48: IF the database refuses the write THEN [Revoke] MUST answer storage-failure.
Deleted: Operation 49. Execution Contract Database 3 owns it.
Operation 50: [Read] MUST answer EVERY capability the filter matches.
Operation 51: [Read] MUST carry the effective status on EVERY answered capability.
Operation 52: [Read] MUST NOT write.
Operation 53: A liveness query MUST rest on the effective status.
Operation 54: A liveness query MUST NOT rest on the stored status alone.
Deleted: Operation 55. Capability requirement 1 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Operation 58: The atom MUST NOT offer an expire action.
Operation 59: The atom MUST NOT offer a re-scope action.
Operation 60: The atom MUST NOT offer an extend action.
Operation 61: IF max redemptions DOES NOT EQUAL blank AND max redemptions IS NOT IN the whole counts THEN [Allocate] MUST answer invalid-request.
Deleted: Operation 62. Execution Contract Read 1 owns it.
Operation 63: IF the database refuses the write THEN [Redeem] MUST answer storage-failure.
Deleted: Operation 64. Execution Contract Read 1 owns it: after the read, every refusal rule of [Allocate] answers invalid-request.
Operation 65: [Redeem] MUST NOT evaluate a rule of the redeem refusal order BEFORE EVERY earlier rule of the redeem refusal order has answered no refusal.
Deleted: Operation 66. Execution Contract Refusal 1 owns it.
```

NOTE: watch the untyped input (Operation 61).

Term now: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term max redemptions: the number of redemptions the capability permits — a [Max Redemptions]; a whole count, set at allocation, never changed.

Term single-use default: a max redemptions of one — what [Allocate] applies where the call supplies none.

Term remaining redemptions: the redemptions the capability has left — a [Remaining Redemptions]; the one field that moves between allocation and a terminal write.

Term ttl: the validity duration a [Allocate] call asks for — a [TTL] (time-to-live); consumed to compute the expiry deadline, never stored under this name.

Term default capability ttl: the validity duration [Allocate] applies where the call supplies no ttl; deployment configuration, and its absence is a misconfiguration rather than an operating state.

Term zero duration: a duration of no length — the floor a ttl must exceed, which refuses zero and every negative value.

Term zero: the count of nothing — the floor a max redemptions must exceed, and the value remaining redemptions reaches at exhaustion.

Term whole count: a whole number of zero or more, with no fractional part — what a supplied max redemptions must be.

Term allocation instant: the instant the capability was recorded — an [Allocation Instant].

Term expiry deadline: `allocated_at + ttl` — what [Allocate] stores as expiry instant, computed once at allocation.

Term expiry instant: the instant the capability's window closes — an [Expiry Instant]; stamped at allocation, never changed, never absent.

Term lapsed: the capability's status EQUALS allocated and now is no earlier than the capability's expiry instant — the condition the guards derive and never stamp.

Term revocable: the capability's status EQUALS allocated and the capability is not lapsed — what [Revoke] requires.

Term effective status: expired where the capability is lapsed, and the stored status otherwise — an [Effective Status]; a pure projection over the capability and now, never stored.

Term redemption instant: the instant the capability exhausted — a [Redemption Instant].

Term revocation instant: the instant the capability was cancelled — a [Revocation Instant].

Term revoked by reference: the opaque reference naming the actor that cancelled the capability — a [Revoked By Reference].

Term revocation reason: the stated ground for the cancellation — a [Revocation Reason], carried from the call's [Reason].

Term reason: the [Revoke] input the capability keeps as revocation reason — a [Reason].

Term filter: the selection a [Read] call scopes the answer by; consumed per call, never stored.

Term liveness query: any query for the capabilities still redeemable — the administrative surfaces, and the auditor's triage.

Term redeem refusal order: Operation 23 through 26 — [Redeem]'s refusal rules, earliest first; Operation 63 answers only at the write, which no refused call reaches.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Allocate] | both references present, counts positive or defaulted, database accepts | the new capability token | one record lands in [Allocated], the counter set to [Max Redemptions] (Operation 1, Operation 17) |
| [Allocate] | a blank or over-long reference, a count that is not a whole number above zero, a non-positive duration, or no configured default | [Invalid Request] | none (Operation 4, Operation 5, Operation 8, Operation 9, Operation 11, Operation 13, Operation 61, String 7) |
| [Redeem] | token names nothing | `invalid(not-known)` | none (Operation 23) |
| [Redeem] | stored status is [Redeemed] | `invalid(exhausted)` | none (Operation 24) |
| [Redeem] | stored status is [Revoked] | `invalid(revoked)` | none (Operation 25) |
| [Redeem] | stored [Allocated], now has reached expiry instant | `invalid(expired)` | **none** — derived, and the counter is untouched (Operation 26, Operation 31) |
| [Redeem] | stored [Allocated], window open, counter above one | `redeemed(scope, allocator_ref)` | the counter falls by one; status unchanged (Operation 30) |
| [Redeem] | stored [Allocated], window open, counter at one | `redeemed(scope, allocator_ref)` | the counter reaches zero and the status moves to [Redeemed] (Operation 32, Operation 33) |
| [Revoke] | token names a revocable capability, attribution present | revoked | [Allocated] → [Revoked], three fields stamped, counter untouched (Operation 41 through 44, Operation 46) |
| [Revoke] | token names nothing | [Not Known] | none (Operation 35) |
| [Revoke] | stored status is [Redeemed] or [Revoked] | [Already Terminal] | none (Operation 36, Operation 37) |
| [Revoke] | stored [Allocated] past its deadline | [Already Terminal] | none — derived, nothing written (Operation 38) |
| [Revoke] | revocable, blank or over-long attribution | [Invalid Request] | none (Operation 39, Operation 40, String 9, String 10) |
| [Allocate], [Redeem], [Revoke] | database refuses the write | [Storage Failure] | none (Operation 18, Operation 48, Operation 63) |
| *a window lapses* | now reaches expiry instant | nothing is called | **nothing written** — no status, no stamp, no counter move (Expiry 1 through 5) |
| [Read] | a filter | the matching capabilities, each carrying its effective status | none (Operation 50, Operation 51) |

### Invariants

- **Invariant 1 — Allocation provenance immutability.**
  ```
  Invariant 1.1: A recorded capability's capability token, allocator reference, scope, max redemptions, allocation instant and expiry instant MUST NOT change.
  ```
- **Invariant 2 — Redemption counter monotonic.**
  ```
  Invariant 2.1: A capability's remaining redemptions MUST NOT rise.
  Invariant 2.2: A capability's max redemptions MUST NOT EXCEED the remaining redemptions at allocation.
  Invariant 2.3: A capability's remaining redemptions MUST NOT EXCEED the max redemptions.
  Invariant 2.4: A redeeming [Redeem] MUST lower remaining redemptions by one.
  Invariant 2.5: A capability's remaining redemptions MUST NOT fall below zero.
  ```
- **Invariant 3 — Bearer redemption.**
  ```
  Invariant 3.1: [Redeem] MUST accept the capability token as the whole call.
  Invariant 3.2: [Redeem] MUST NOT accept an identity claim.
  Invariant 3.3: [Redeem] MUST NOT check an identity claim.
  Invariant 3.4: A capability MUST NOT carry a redeemer's identity.
  ```
- **Invariant 4 — Exhaustion atomicity.**
  ```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 2 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 2 owns it.
  Invariant 4.4: The successful [Redeem] calls on one capability MUST NOT EXCEED the max redemptions.
  Deleted: Invariant 4.5. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.6. Execution Contract Database 3 owns it.
  Deleted: Invariant 4.7. Execution Contract Database 1 owns it.
  ```
- **Invariant 5 — Audit asymmetry.**
  ```
  Invariant 5.1: EVERY capability MUST carry the allocator reference.
  Invariant 5.2: An auditor MUST NOT find a redeemer's identity in the capability records.
  Invariant 5.3: The atom MUST NOT infer a redeemer's identity.
  ```
- **Invariant 6 — Three structurally distinct terminal modes, two stored and one derived.**
  ```
  Invariant 6.1: A redeemed capability MUST carry a redemption instant AND a remaining redemptions of zero.
  Invariant 6.2: A revoked capability MUST carry revocation instant, revoked by reference and revocation reason.
  Invariant 6.3: A lapsed capability MUST NOT carry a redemption instant.
  Invariant 6.4: A lapsed capability MUST NOT carry a revocation field.
  Invariant 6.5: An implementation MUST NOT merge two terminal modes.
  Invariant 6.6: A redeemed capability MUST NOT carry a revocation field.
  Invariant 6.7: A revoked capability MUST NOT carry a redemption instant.
  ```
- **Invariant 7 — Stored terminal state absorbing.**
  ```
  Invariant 7.1: A redeemed capability MUST NOT leave redeemed.
  Invariant 7.2: A revoked capability MUST NOT leave revoked.
  Invariant 7.3: A lapsed capability MUST NOT admit a write.
  Invariant 7.4: A lapsed capability MUST stand in allocated.
  ```
- **Invariant 8 — Scope immutability.**
  ```
  Invariant 8.1: A recorded scope MUST NOT change.
  Invariant 8.2: A deployment re-scoping an authorization MUST call [Allocate].
  ```
- **Invariant 9 — Revocation attribution completeness.**
  ```
  Invariant 9.1: EVERY revoked capability MUST carry a revocation instant.
  Invariant 9.2: EVERY revoked capability's revoked by reference MUST stand non-blank.
  Invariant 9.3: EVERY revoked capability's revocation reason MUST stand non-blank.
  ```
- **Invariant 10 — Every capability has a finite lifetime.**
  ```
  Invariant 10.1: EVERY capability MUST carry an expiry instant.
  Invariant 10.2: The atom MUST NOT record a capability carrying no expiry instant.
  ```
- **Invariant 11 — Capability durability over this atom's own surface.**
  ```
  Invariant 11.1: The atom MUST NOT offer a removal surface.
  Invariant 11.2: An action the atom offers MUST NOT reduce the capability count.
  Deleted: Invariant 11.3. Execution Contract Database 1 owns it.
  ```
- **Invariant 12 — Capability token uniqueness.**
  ```
  Invariant 12.1: Two capabilities MUST NOT share a capability token.
  Invariant 12.2: IF a write would reuse a capability token THEN the database MUST refuse the write.
  Invariant 12.3: [Allocate] MUST NOT allocate a capability token any capability carries.
  Invariant 12.4: Invariant 12.1 MUST range over the capabilities the database retains.
  ```
- **Invariant 13 — Expiry is derived, never written.**
  ```
  Invariant 13.1: A capability MUST NOT carry a stored expired status.
  Invariant 13.2: A capability MUST NOT carry an expiry timestamp beside expiry instant.
  Invariant 13.3: A lapse MUST NOT write to the capability.
  Invariant 13.4: The effective status MUST rest on the stored status, the expiry instant and now.
  ```

Invariants 1 and 3 together give the *authorization envelope* property — a capability's full authorization is readable from one immutable record, and no identity check contaminates the bearer semantics. Invariants 2 and 4 give *redemption integrity* — the counter falls exactly once per redemption. Invariants 5, 6 and 13 give *audit clarity* — the record always answers who allocated and what was authorized, never who redeemed; the two stored terminals are unambiguous; and the derived [Expired] is reproducible from the deadline and the read-time clock. Invariant 12 gives *lookup determinism* — [Redeem] resolves to one capability or none.

Two properties are entailed rather than stated, and the formal model ([`capability.als`](./capability.als), this spec's sibling) confirms both. A remaining redemptions of zero is reachable only through the exhausting move, which stands the capability in [Redeemed] — [Revoke] does not lower the counter and a lapse never writes — so a zero counter outside [Redeemed] is unreachable (Invariant 2.4, Operation 32, Operation 46, Expiry 3). And a [Revoked] capability always carries a counter above zero, because [Revoke] requires a revocable capability and preserves the counter, and the stored terminals are absorbing (Invariant 7.1, Invariant 7.2, Operation 46).

---

## Examples

### Single-use password-reset link

An account-recovery service allocates a reset capability: `allocate(allocator_ref: recovery_svc_r01, scope: "reset-password::acct_a9931", max_redemptions: 1, ttl: 3600)` → `cap_tok_7f3a`, with the host injecting `now: 2026-09-01T09:00:00Z` and the token's random material at the seam. The record lands in [Allocated] with `remaining_redemptions: 1` and `expires_at: 10:00:00Z`. The service emails the link.

The user clicks it twelve minutes later. `redeem(cap_tok_7f3a)` → `redeemed(scope: "reset-password::acct_a9931", allocator_ref: recovery_svc_r01)`. The counter reaches zero and the status moves to [Redeemed] with `redeemed_at: 09:12:00Z`. The reset page opens. **No redeemer identity is recorded** — the database cannot say whether the account owner clicked the link or somebody who intercepted the email did, and that is the model working as designed (Invariant 5.2).

A second click on the same link → `invalid(exhausted)` (Operation 24).

### Multi-use pre-signed read token

A document service allocates a five-use read token: `allocate(allocator_ref: share_svc_s02, scope: "read::document::doc_d448", max_redemptions: 5, ttl: 604800)` → `cap_tok_b81c`. Three fetches over the week each answer `redeemed(...)` and leave the counter at 2, with the status still [Allocated] (Operation 30).

The window closes with two redemptions unspent. **Nothing is called and nothing is written.** A [Read] now reports `effective_status: expired`; the counter still reads 2, because a lapse forfeits the remaining redemptions by derivation rather than by spending them (Expiry 3, Invariant 6.3). A fourth fetch answers `invalid(expired)`.

### Rejection paths

`allocate(allocator_ref: share_svc_s02, scope: "read::document::doc_d448", max_redemptions: 0, ttl: 3600)` → invalid-request. A capability redeemable zero times authorizes nothing (Operation 9).

`revoke(cap_tok_7f3a, revoked_by_ref: admin_a01, reason: "incident")` against the exhausted reset token → already-terminal (Operation 36). The same call against a capability whose window has merely closed answers the same way, by derivation, writing nothing (Operation 38) — which is the one place this atom and [Session](./session.md) part company on identical mechanics, and neither declares the fork.

`redeem(cap_tok_forged)` → `invalid(not-known)`. No record for the token — and after a composed retention purge, the same answer covers a capability that once existed (Invariant 12.4).

`redeem(cap_tok_b81c)` whose write the database refuses → storage-failure, and the counter is not lowered (Operation 63, Operation 31).

### Regulated adversarial scenarios

- **Regulator audit — who authorized a disclosure.** An auditor asks under what authority a document was released. The database yields the capability: `allocator_ref: share_svc_s02`, `scope: "read::document::doc_d448"`, `max_redemptions: 5`, allocation instant, expiry instant. Invariant 1.1 is the answer — the envelope is immutable and readable from one record. What the database *cannot* answer is who fetched the document, and the auditor must be told that up front: attribution for the redemption side lives in the composing [Audit Trail](../compositions/audit-trail.md), never here (Invariant 5.2, Composition note 4).
- **Disputed reset — the account owner denies resetting.** The database shows `cap_tok_7f3a` allocated to `recovery_svc_r01` at `09:00`, redeemed at `09:12`, exhausted. It does not show who redeemed it, and no amount of reading will make it. That is the structural finding, not a gap: the capability is evidence that *someone holding the link* reset the password within the window, which is exactly what a bearer credential attests (Invariant 3.4, Invariant 5.3).
- **Breach triage — which capabilities are still redeemable.** Tokens appear in an exposed log. The investigator reads each record's effective status against the investigation clock: which are live, which lapsed, which exhausted or revoked. Every live one is revoked with attribution. The lapsed ones **cannot** be revoked — they answer [Already Terminal] — so the attributed closure a [Session](./session.md) breach response can record is not available here, and the triage record has to lean on the [Audit Trail](../compositions/audit-trail.md) instead (Operation 38, Composition note 4).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the capability records and the read-time clock.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY capability's allocator reference, scope, max redemptions, allocation instant and expiry instant present (Invariant 5.1, Invariant 10.1).
Check 2.1: An auditor MUST find no capability's remaining redemptions below zero (Invariant 2.5).
Check 2.2: An auditor MUST find EVERY capability's remaining redemptions no higher than the max redemptions (Invariant 2.3).
Check 2.3: An auditor MUST find a remaining redemptions of zero AND a redemption instant on EVERY redeemed capability (Invariant 6.1).
Check 2.4: An auditor MUST find a remaining redemptions above zero on EVERY allocated capability (Operation 32).
Check 3.1: An auditor MUST find no redeemer identity in any capability field (Invariant 3.4, Invariant 5.2).
Check 4.1: An auditor MUST find no stored expired status on any capability (Invariant 13.1).
Check 4.2: An auditor MUST find no expiry timestamp beside expiry instant (Invariant 13.2).
Check 4.3: An auditor MUST reproduce the effective status from the stored status and the expiry instant against the read-time clock (Invariant 13.4).
Check 5.1: An auditor MUST find no terminal field written by a lapse (Invariant 13.3, Invariant 6.3, Invariant 6.4).
Check 5.2: An auditor MUST find EVERY revoked capability's remaining redemptions above zero (Invariant 7.2, Operation 46).
Check 6.1: An auditor MUST find a revocation instant, a revoked by reference and a revocation reason on EVERY revoked capability (Invariant 9.1, Invariant 9.2, Invariant 9.3).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor MUST read a refused [Redeem] from the composing Audit Trail (Invariant 7.3).
External check 2: An auditor needing a redemption's attribution MUST read the attribution from the composing pattern's records (Invariant 5.2, Non-goal 6).
External check 3: An auditor needing a capability's field history MUST read the history from the composing Audit Trail (Invariant 1.1).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT confirm an allocator reference's authority.
Non-goal 2: A deployment gating allocation MUST compose Permissions.
Non-goal 3: The atom MUST NOT evaluate a scope.
Non-goal 4: A composing pattern MUST own the scope vocabulary.
Non-goal 5: The atom MUST NOT record a redeemer's identity.
Non-goal 6: A deployment needing redemption attribution MUST record the attribution outside the atom.
Non-goal 7: The atom MUST NOT deliver a capability token.
Non-goal 8: The atom MUST NOT protect a capability token in transit.
Non-goal 9: The atom MUST NOT narrow a scope for a third party.
Non-goal 10: A bearer delegating a narrowed authorization MUST call [Allocate].
Non-goal 11: The atom MUST NOT notify a bearer of a revocation.
Non-goal 12: The atom MUST NOT notify an allocator reference of a revocation.
Non-goal 13: The atom MUST NOT gate a redemption on an identity.
Non-goal 14: A deployment needing identity-keyed authorization MUST compose Permissions.
Non-goal 15: The atom MUST NOT bind an identity at redemption.
Non-goal 16: A deployment needing an identity bound at redemption MUST compose Invitation.
Non-goal 17: The atom MUST NOT record a bearer's act beyond the redemption.
Non-goal 18: A deployment needing a post-redemption record MUST compose Audit Trail.
Non-goal 19: The atom MUST NOT seal a capability against modification.
Non-goal 20: A deployment needing court-admissible records MUST compose Tamper Evidence.
Non-goal 21: The atom MUST NOT purge a terminal capability.
Non-goal 22: The atom MUST NOT forbid a deployment purging a terminal capability.
Non-goal 23: The atom MUST NOT distinguish a purged capability token from an unallocated capability token.
Non-goal 24: The atom MUST NOT guarantee a replay bound beyond max redemptions and expiry instant.
Non-goal 25: The atom MUST NOT attest an allocator reference.
Non-goal 26: The atom MUST NOT attest a revoked by reference.
Non-goal 27: A deployment needing an attested actor MUST compose Actor Identity.
Non-goal 28: The atom MUST NOT reconcile two readers disagreeing across the deadline.
```

NOTE: the owners — [Audit Trail](../compositions/audit-trail.md) (Non-goal 5, Non-goal 6); [Permissions](./permissions.md) (Non-goal 13, Non-goal 14); [Invitation](./invitation.md) (Non-goal 15, Non-goal 16); [Tamper Evidence](./tamper-evidence.md) (Non-goal 19, Non-goal 20); [Retention Window](./retention-window.md) (Non-goal 21, Non-goal 22); the deployment (Non-goal 23); [Actor Identity](./actor-identity.md) (Non-goal 25, Non-goal 27); Execution Contract Logic confinement 7 (Non-goal 28).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MAY read now ONLY IF the guard derives a lapse.
Clock dependence 2: A guard MUST NOT read now to admit a caller-supplied instant.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: the counter's read and write are one transaction, and the atom names no rule left for a compare-and-set to discharge.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a string input EXCEEDS the maximum length THEN [Allocate] MUST answer invalid-request.
String 8: The deployment MUST canonicalize an opaque reference.
String 9: IF the capability is revocable AND revoked by reference EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
String 10: IF the capability is revocable AND reason EXCEEDS the maximum length THEN [Revoke] MUST answer invalid-request.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the scope's meaning.
Composition note 3: A composing pattern MUST own the authority to allocate for a scope.
Composition note 4: A composing pattern MUST own the redemption's attribution.
Composition note 5: A composing pattern MUST own the capability token's delivery.
Composition note 6: A composing pattern MUST own the retention of the capability records.
Composition note 7: A composing pattern reading the capability records MUST NOT write to the capability records.
Composition note 8: A composing pattern MUST NOT record a redeemer's identity on a capability.
```

NOTE: composing patterns — [Capability-Backed Sharing](../compositions/capability-backed-sharing.md), [Privileged Access Provisioning](../compositions/privileged-access-provisioning.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a bearer; an allocator; an auditor; the database; a capability; a status; a lapse; a liveness query; a write; an action; a string input; an opaque reference; the capability count; the capability token's random material.

Term records: capability — one bearer-token authorization, carrying capability token, allocator reference, scope, max redemptions, remaining redemptions, allocation instant, expiry instant, status and, once terminal, redemption instant or revocation instant with revoked by reference and revocation reason.

Term record verbs: identify, serve, offer, supply, check, compare, allocate, reuse, change, carry, share, draw, refuse, interpret, confirm, apply, accept, record, stand, answer, stamp, recompute, set, lower, rise, fall, reach, leave, derive, surface, write, fire, schedule, read, rest, remove, evaluate, hold, merge, admit, infer, reduce, range, find, reproduce, own, gate, bind, narrow, deliver, protect, notify, purge, forbid, distinguish, guarantee, seal, compose, trim, normalize, case-fold, exceed, canonicalize, reconcile, attest, declare, call, configure.

Term value sets: status = allocated | redeemed | revoked.

Term bounds: default capability ttl (the validity duration [Allocate] applies where the call supplies none); single-use default (the max redemptions [Allocate] applies where the call supplies none); zero duration (the floor a ttl must exceed); zero (the floor a max redemptions must exceed); whole count (the whole numbers a supplied max redemptions is drawn from); maximum length (the deployment's cap per string input).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: capability, capability token, allocator reference, scope, seam, transition, now, business caller, max redemptions, single-use default, remaining redemptions, ttl, default capability ttl, zero duration, zero, whole count, allocation instant, expiry deadline, expiry instant, lapsed, revocable, effective status, redemption instant, revocation instant, revoked by reference, revocation reason, reason, filter, liveness query, redeem refusal order, status, revocation field, blank, maximum length, redemption failure.

#### Allocate

The behavior an allocating actor invokes to create a new capability and receive its [Capability Token]. It records the [Allocator Reference], [Scope], [Max Redemptions], [Allocation Instant], and [Expiry Instant] = [Allocation Instant] + [TTL], sets [Remaining Redemptions] = [Max Redemptions], enters the record in [Allocated], and returns the [Capability Token] (or a rejection). It makes no policy judgment about whether the allocation is appropriate.

Kind: Operation

#### Redeem

The behavior a bearer invokes to exercise a capability, presenting only the [Capability Token] — no identity argument. On a live capability it decrements [Remaining Redemptions] and returns `redeemed(scope, allocator_ref)`; the call that brings the counter to zero transitions the record to [Redeemed]. It is not idempotent and records no redeemer identity. Its five outcomes (redeemed, `invalid(exhausted | expired | revoked | not-known)`) are all first-class, and one refusal stands beside them: [Storage Failure] where the database refuses its write, which lowers nothing.

Kind: Operation

#### Revoke

The behavior invoked to cancel a still-live capability, with attribution. Permitted only while stored [Status] = [Allocated] and [Now] < [Expiry Instant]; it transitions the record to [Revoked] and stamps [Revocation Instant], [Revoked By Reference], and [Revocation Reason]. On a stored terminal or a lapsed window it returns [Already Terminal].

Kind: Operation

#### Read

The render-time behavior that returns the matching capability records, each carrying its derived [Effective Status]. It only reads; no record changes. It is the surface every liveness query applies, since a raw [Allocated] with [Expiry Instant] in the past reads [Expired], not live.

Kind: Operation

#### Capability Token

The opaque, cryptographically random, immutable, system-generated value [Allocate] produces — both the record's identity and the bearer credential presented to [Redeem] and [Revoke]. It is the injected `id_t`; no two records share one, and it is not reused after a capability reaches a terminal state.

Kind:       Field
Field of:   Capability
Projection: capability_token

#### Allocator Reference

The opaque reference to the actor or mechanism that allocated the capability — the one identity the record permanently carries (the audit asymmetry). Set on [Allocate], immutable thereafter. The atom does not validate that it is an active principal.

Kind:       Field
Field of:   Capability
Projection: allocator_ref

#### Scope

The opaque value describing what the capability authorizes, returned to the bearer by [Redeem]. The atom stores and returns it but never interprets it; the composing pattern defines and reads scope values. Set on [Allocate], immutable thereafter.

Kind:       Field
Field of:   Capability
Projection: scope

#### Max Redemptions

The total number of redemptions permitted, a whole number of one or more, set on [Allocate] (or 1 if null — the single-use default). Immutable thereafter; [Remaining Redemptions] is initialised from it.

Kind:       Field
Field of:   Capability
Projection: max_redemptions

#### Remaining Redemptions

The redemptions still available — the one mutable field between allocation and a stored terminal. Set to [Max Redemptions] on [Allocate], decremented by exactly 1 on each successful [Redeem], never increasing; reaching 0 is the exhaustion transition to [Redeemed].

Kind:       Field
Field of:   Capability
Projection: remaining_redemptions

#### Allocation Instant

The wall-time [Allocate] was called, stamped from the injected [Now]. Immutable thereafter. [Expiry Instant] is computed once as [Allocation Instant] + [TTL].

Kind:       Field
Field of:   Capability
Projection: allocated_at

#### Expiry Instant

The absolute expiry time, set on [Allocate] as [Allocation Instant] + [TTL]. Never null and never mutated. It is the sole stored input to the expiry derivation: a still-[Allocated] record reads [Expired] once [Now] ≥ [Expiry Instant].

Kind:       Field
Field of:   Capability
Projection: expires_at

#### Status

The stored status of a capability: [Allocated], [Redeemed], or [Revoked]. Set to [Allocated] on [Allocate]; transitions once to a stored terminal and never returns. The derived [Expired] is *not* a value of this field — it appears only in the [Effective Status] read projection.

Kind:       Field
Field of:   Capability
Projection: status

#### Redemption Instant

The wall-time the capability exhausted (its counter reached zero), stamped from the injected [Now]. Present only in [Redeemed]; null otherwise; immutable once set.

Kind:       Field
Field of:   Capability
Projection: redeemed_at

#### Revocation Instant

The wall-time the capability was revoked, stamped from the injected [Now] on [Revoke]. Present only in [Revoked]; null otherwise; immutable once set.

Kind:       Field
Field of:   Capability
Projection: revoked_at

#### Revoked By Reference

The opaque reference to the actor or mechanism that performed the revocation. Required at [Revoke]; null until revocation; immutable once set.

Kind:       Field
Field of:   Capability
Projection: revoked_by_ref

#### Revocation Reason

The caller-supplied reason recorded for the revocation (from the [Reason] parameter). Required at [Revoke]; null until revocation; immutable once set.

Kind:       Field
Field of:   Capability
Projection: revocation_reason

#### Effective Status

The status [Read] attaches to each returned record: [Expired] when [Status] = [Allocated] ∧ [Now] ≥ [Expiry Instant], otherwise the stored [Status]. A pure projection over the record and the injected [Now] — derived at read time, never stored — and what makes [Redeem] return `invalid(expired)`. Every liveness query applies it.

Kind:       Field
Field of:   Capability
Projection: effective_status

#### TTL

The validity duration [Allocate] consumes to compute [Expiry Instant] ([Allocation Instant] + [TTL]). Supplied per call; if null, the deployment's default applies; zero or negative is rejected. It is never stored under its own name — only the computed [Expiry Instant] is stored.

Kind:         Parameter
Parameter of: Allocate
Projection:   ttl

#### Reason

The caller-supplied reason string [Revoke] consumes, written into [Revocation Reason]. Required (non-null, non-empty); not stored under this name.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Now

The current clock reading every action consumes — the pipeline's `clock_t`, injected at the I/O seam, never read inside a transition and never a signature parameter. It stamps the immutable write timestamps ([Allocation Instant], [Redemption Instant], [Revocation Instant]) and drives the pure expiry derivation in guards and [Read] (no write).

Kind:         Parameter
Parameter of: Allocate
Projection:   now

#### Allocated

The single non-terminal stored state: the capability may be redeemed, with [Remaining Redemptions] > 0. A record enters [Allocated] on [Allocate] and leaves it only by a write — exhaustion to [Redeemed], revocation to [Revoked]. A still-[Allocated] record past [Expiry Instant] reads [Expired] by derivation.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Redeemed

The stored terminal a capability reaches when its redemption counter hits zero (exhaustion). Carries [Redemption Instant] and [Remaining Redemptions] = 0. Absorbing: no transition leaves it.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Revoked

The stored terminal a capability reaches when it is explicitly cancelled within its window. Carries [Revocation Instant], [Revoked By Reference], and [Revocation Reason]. Absorbing: no transition leaves it.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Expired

The derived terminal mode — never stored. A still-[Allocated] record whose window has lapsed ([Now] ≥ [Expiry Instant]) reads [Expired] via the [Effective Status] projection; no field is written and the counter is never decremented by lapse.

Kind:      Member
Member of: the capability status
Role:      Outcome

#### Not Known

The outcome returned when the supplied [Capability Token] references no record — `invalid(not-known)` from [Redeem], a [Not Known] rejection from [Revoke]. A lookup miss; after external purge it also subsumes once-allocated-but-purged records.

Kind:       Member
Member of:  the action outcome
Role:       Outcome
Projection: not-known

#### Already Terminal

The refusal [Revoke] returns when the capability is not revocable — a stored terminal ([Redeemed] or [Revoked]) *or* a still-[Allocated] record whose window has lapsed (which reads [Expired]). A pure derivation that writes nothing.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: already-terminal

#### Invalid Request

The refusal [Allocate] or [Revoke] returns when an argument is malformed — on [Allocate], a null, empty or over-long [Allocator Reference] or [Scope], a [Max Redemptions] that is not a whole number above zero, a non-positive [TTL], or an absent deployment default; on [Revoke], a null, empty or over-long [Revoked By Reference] or [Reason] on a revocable capability. A guard rejection before any database write; no record is created or changed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal [Allocate], [Redeem] or [Revoke] returns when the database write fails after the preconditions pass; a refused [Redeem] write lowers nothing. A token-reuse write is also rejected here (Invariant 12). The caller must treat it as definitive.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Allocate]: #allocate
[Redeem]: #redeem
[Revoke]: #revoke
[Read]: #read
[Capability Token]: #capability-token
[Allocator Reference]: #allocator-reference
[Scope]: #scope
[Max Redemptions]: #max-redemptions
[Remaining Redemptions]: #remaining-redemptions
[Allocation Instant]: #allocation-instant
[Expiry Instant]: #expiry-instant
[Status]: #status
[Redemption Instant]: #redemption-instant
[Revocation Instant]: #revocation-instant
[Revoked By Reference]: #revoked-by-reference
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

- **Daniel Jackson, *Software Abstractions*** — `Capability [Resource]` is a concept in Jackson's concept catalog. The atom's scope field (what the capability authorizes), allocate and redeem actions, and the bearer-key semantics correspond directly to Jackson's formulation. Grace Commons expresses this concept in the atom format; the structural decisions are inherited from the concept catalog.
- **Mark Miller and the object-capability (OCAP) literature** — the formal theoretical grounding for bearer-key authorization. The principle *"an unforgeable reference to an object carries the authority to use that object"* is the foundation. Miller's work on capability-based security, including the E language and the Waterken server, establishes the invariants this atom formalizes.
- **Levy, H.M. (1984), *Capability-Based Computer Systems*** — the canonical reference for capability-based security systems. Levy establishes the three properties of capabilities: unforgeability, transferability, and access control by possession. The atom satisfies unforgeability (the capability token — cryptographically random, opaque, system-generated) and access-control-by-possession (the bearer semantics of redeem); transferability and attenuation are deliberately outside the atom's surface — the atom neither prohibits, tracks, nor models token sharing or scope-narrowing delegation (see Edge cases — Capability chaining), so its claim on the OCAP literature is the bearer/unforgeability subset, not full conformance.
- **Birgisson, A., Politz, J.G., Erlingsson, Ú., Taly, A., Vrable, M., Lentczner, M. (2014), *Macaroons: Cookies with Contextual Caveats for Decentralized Authorization in the Cloud*** — Macaroons are a constrained Capability variant: a capability token that can be attenuated (scope narrowed) by adding caveats before being passed to a third party. The atom models the base Capability concept without macaroon-style attenuation; composing patterns that need contextual caveats may build on this atom.
- **RFC (Request for Comments — the Internet's numbered standards series) 6749 section 1.4 (OAuth 2.0 — Access Tokens)** — OAuth 2.0 (the open authorization framework, version 2.0) access tokens are a widely deployed capability-adjacent pattern: a bearer token scoped to specific resources, with limited lifetime, that grants access without per-request identity verification. Cited with explicit caveats: OAuth 2.0 conflates bearer-token authorization with identity-bound flows (the authorization server authenticates the client; the token is identity-linked in practice even if the resource server checks only the token). This atom defines the pure OCAP surface — the token IS the authorization, with no identity linkage — which is a stricter and simpler model than OAuth 2.0 in full. Composing patterns that implement OAuth 2.0-compatible flows will compose this atom with identity-aware patterns.
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 32 (Security of Processing)** — capability tokens are an access-control mechanism for regulated data disclosures. The allocator reference and scope fields, immutably recorded and provable from the capability records, satisfy the "appropriate technical measures" requirement for demonstrating that disclosures were authorized.
- **HIPAA (Health Insurance Portability and Accountability Act) section 164.514(d) (Minimum Necessary Standard)** — the HIPAA requirement that disclosures be limited to the minimum necessary information. A capability's scope is the mechanism for encoding the minimum necessary field set; the composing Capability-Backed Sharing pattern is where the minimum-necessary constraint is enforced against the disclosure.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of separating bearer-key authorization (Capability) from identity-keyed authorization (Permissions) and from identity-binding onboarding (Invitation).
- **Eiffel's design-by-contract** — named rejection reasons; preconditions on allocate and revoke; first-class redeem outcomes.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — capability.als + 1 twin, 2026-06-23
last gate: 2026-10-21 — Final Critique 6, the council's first round on the page and the first on its Store-contract rewrite (5b6092b), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at b7195f0); the round rests on three counted passes — foundational count 5 after triage (10 reports: 5 standing, merged into 4; 3 sent down; 2 rejected; 1 refining report raised), all Kind A: [Redeem]'s answers were closed against the failed read and the refused write the Execution Contract answers, and no action answered a failed read; a length refusal was obliged on [Redeem] and [Read], which refuse no length, and beside [Revoke]'s standing answers; the effective status rested on expiry instant and now alone, against Term effective status; a fractional max redemptions was admitted, which the first redeem lowers below zero; and the default capability ttl was unbounded, so one build refuses a defaulted call and another allocates a window already closed; 17 refining reports, 3 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-23 — Final Critique 5, fresh reader — clean

open:
- 2026-10-21-a · refining · Term filter; Operation 50; Operation 53; Operation 54 · which fields a filter names and how each matches are unstated, so a liveness query (Operation 53, Operation 54) has no declared read surface to rest on — one build filters on the effective status, another on stored fields — and the answer has no order → name the filter's fields, the effective status among them, and state an order or declare none
- 2026-10-21-b · refining · Now entry; Term now; Capability requirement 1 · the Now entry gives Parameter of: Allocate and Term now says the host hands now to the transition, while [Redeem], [Revoke] and [Read] consume now too (Expiry 6, Expiry 7, Operation 51), and the contract's query surface names only the database read → name every consumer, [Read]'s projection among them
- 2026-10-21-c · refining · Identity 9; Term capability token · Term capability token says unguessable and the Standards references claim unforgeability, and no rule bounds the token's entropy or length → a token entropy bound the deployment declares, as Session's
- 2026-10-21-d · refining · State 8; State 10; Identity 11; Identity 12; Identity 13; Non-goal 4; Invariant 2.2 · each carries a proposition another rule carries too (Invariant 13.1; Invariant 3.4; Invariant 12.2; Non-goal 1; Composition note 2), and Invariant 2.2 restates as a bound the equality Operation 17 sets at allocation → one owner each (GRACE-lang Authority 3), the coverage map following any Invariant 2 tombstone
- 2026-10-21-e · refining · Expired entry; Term value sets · the term entries name four member-of targets where Term value sets declares one, and the Expired entry makes expired a member of the capability status, which Term status and State 8 say it is not → declare each target, and place Expired with the effective status
- 2026-10-21-f · refining · External check 1; External check 3; Check 5.2 · External check 1 reads a refused [Redeem] from the composing Audit Trail, which no rule obliges to record a refusal, and cites Invariant 7.3, another proposition; External check 3 sends a field history to Audit Trail while Execution Contract Database 5 keeps every committed version readable and Capability requirement 5 cites Database 1 through 4; Check 5.2 cites Invariant 7.2 for a property the page entails from [Revoke]'s guard and Operation 46 → name what each check reads and cite the rules it tests
- 2026-10-21-h · refining · String 8; String 2 through 4 · String 8 obliges the deployment to canonicalize an opaque reference beside String 2 through 4, and names neither where it runs nor the canonical form → state both
- 2026-10-21-i · refining · Operation 19; Term redemption failure · Operation 19's list and Term redemption failure restate one outcome space → one owner
- 2026-10-21-j · refining · Rejection paths; Standards references · the Rejection paths aside says this atom and Session part company on identical mechanics and neither declares the fork, and names no fork; the GDPR entry says two recorded fields satisfy Article 32 → state the fork or drop the aside, and say the fields contribute toward Article 32
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/capability.md`; the migration that got it here is in [its history](./capability.hist.md).

- **2026-10-22 — The length refusal's split stays the page's own.** *Chose:* String 7, String 9 and String 10 kept as written, the category reach's flag removed: GRACE-lang Closed vocabulary 29 now reads a rule over several actions as binding each only where its signature carries the outcome, so [Redeem] and [Read] would meet no length refusal under one rule over every action, but the split also refuses on [Revoke] only an over-long revoked by reference or reason, and only on a revocable capability, as Operation 39 and Operation 40 refuse a blank one; one rule over every action would also refuse an over-long capability token on a revocable capability, which the page leaves to the token's own lookup. *Over:* String 7 written again as one rule over every action, the page's form before its sixth Final Critique. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the category reach among them, and that a page keeps its own rule where its domain differs. What each action does and answers is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Revoke]'s refuses line listing its refusals in the order the revoke refusal order gave them — not-known, already-terminal, invalid-request, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 5, Execution Contract Refusal 1); Operation 66, which evaluated the revoke refusal order, deleted to Refusal 1, and Term revoke refusal order deleted with it; rules 201 to 200. Operation 65 and Term redeem refusal order stay the page's own: they order the redemption failure [Redeem] answers inside invalid(redemption failure), an answer and no refusal, and Refusal 1 orders only a refuses line. *Over:* the page stating for itself which of [Revoke]'s refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's sixth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 5, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 62) to Read 1, and the allocate refusal order (Operation 64), whose rules after the read all answer invalid-request, to Read 1; state-unavailable off [Redeem]'s answers (Operation 19) and the read's condition off [Read]'s (Operation 50), the read off the redeem and revoke refusal orders, Term database read deleted, state-unavailable off every signature, and the failed read off the case table and the redeem example; rules 203 to 201. *Over:* the page stating for itself what every action answers when the capability records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's sixth Final Critique had made one of the cures the contract's Read family is written from. What each action answers on an answered read is unchanged, [Redeem]'s storage failure included.

- **2026-10-21 — A failed read and a refused write answer on every action, [Redeem] included; each writing action's refusals answer in one stated order; the effective status reads the stored status; the length cap refuses only the writes; a count is whole, and the default window positive.** *Chose:* state-unavailable on all four actions where the read of the capability records fails, the Execution Contract's Step 1 failure (Operation 62, Term database read), and storage-failure on [Redeem] where the database refuses its write, the contract's Step 3 failure (Operation 63), the arm the row titled *A mutating action with no write-failure outcome* in `open-questions.md` had parked; one refusal order for each writing action, the read first, since the pipeline reads at Step 1 before any guard (Operation 64 through 66), Expiry 8 and Expiry 9 deleted to Operation 26 and Operation 38, which the orders hold, and [Read]'s answer held to an answered read; Invariant 13.4 and Check 4.3 resting the effective status on the stored status, expiry instant and now, as Term effective status already did; String 7 naming [Allocate], and String 9 and String 10 refusing an over-long revoked by reference or reason only on a revocable capability, so [Redeem] and [Read], which refuse no length, meet none, and an over-long token names no capability; a supplied max redemptions held to the whole counts (Operation 61, Term whole count); the default capability ttl held above the zero duration (Capability requirement 6), and Operation 13's floor held to a supplied ttl. *Over:* a redeem whose refused write one build answers storage-failure, as the contract obliges, and another `invalid(exhausted)`; a failed read no signature names; a length refusal obliged on two actions whose signatures carry none; an invariant the page's own Term breaks on every revoked capability past its deadline; a fraction the first redeem lowers below zero; and a configured default of zero or less, which one build refuses and another allocates as a window already closed. *Because:* Final Critique 6 found each a divergence between conforming builds, or two rules no build can both obey, and the corpus already held each cure: Actor Identity's fifth round and the rounds after it answer the failed read on every action, Session's sixth round cured the effective status, the length cap and the default window on its twin mechanics, and Capacity Constraint Enforcement declares its whole counts. The write arm is the one cure the corpus leaves: the maintainer's Database contract, which the atom takes (Capability requirement 5), guarantees no write commits, so no host obligation could make the write unfailable. What the atom answers a well-formed call on a database that reads and writes is unchanged.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the capability store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the thirteen rules that restated them, or stood in for them, tombstoned to their owner — Operation 34 and Invariant 4.1, [Redeem]'s lowering and exhausting move committed in one operation, Operation 45, [Revoke]'s status move and its three revocation fields committed in one operation, Invariant 4.7, no partial write standing as an observable capability, and Invariant 11.3, no partial capability left by a storage-failure, to Store 1; Invariant 4.5, an uncommitted crash leaving the capability as the call found it, to Store 1 and Store 3; Invariant 4.6, a committed crash leaving the lowering standing, and Operation 49, a write the store refused leaving the store as the call found it, to Store 3; Concurrency 1, writes on one capability token serialized, Invariant 4.2 and 4.3, two concurrent redeems at one remaining redemption answering redeemed once and the later one exhausted, and Concurrency 3, a compare-and-set as a way to discharge Concurrency 2, to Store 2; Concurrency 2, the counter read and the counter write one transition, to Store 1 and Store 2; rules 208 to 196. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. The redemption bound stays the atom's own (Invariant 4.4), as do a refused [Redeem] lowering nothing (Operation 31), the store refusing a reused capability token (Identity 11, Invariant 12.2) and the atom's no-removal rules (State 13, Invariant 11.1 and 11.2); Check 2.4 now names Operation 32, the exhausting move whose effect it reads. The atom keeps no history of a capability's fields (External check 3 sends it to the composing Audit Trail) and orders nothing by commit, so it cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

NOTE: End of Capability.

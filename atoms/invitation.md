---
title: Invitation
parent: Atomic Concepts
has_toc: true
toc: true
---

# Invitation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Invitation tracks the life of an invitation issued to an outside party — a new employee, a customer, a collaborator, a patient. It answers *what is the state of this invitation, and who accepted it?*

An invitation is issued before the invitee has an identity in the system, which is what makes it useful: it is the bridge from outsider to registered participant. Each is identified by a random token the invitee presents to act on it, and each starts pending. It is resolved by a write to one of three recorded end states — accepted (recording, permanently, the identity that joined), declined (a deliberate refusal, recorded as its own outcome), or revoked (the inviter withdrew it). If the window simply passes, the invitation *reads* expired: a status computed from the deadline and the clock, never written.

Resolving exactly once is the guarantee. After a write resolves an invitation, any further write is told which resolution stands — and two people accepting at once means one wins and the other is told. A write against a lapsed invitation is told it expired, which is a different answer from any of the three resolutions.

The key moment is acceptance, where a concrete identity is bound to what may have begun as an invitation to an unknown party. Declined is what sets this apart from a plain bearer token: a refusal is a recorded human decision, distinct from never using the invitation at all. The credential setup, identity record and login that usually follow acceptance are separate patterns.

---

## Intent

Systems that admit external parties face one structural problem: the invitation must be issued before the invitee's system identity exists, yet acceptance is the moment that identity must be established. The invitation is the bridge, and it carries the whole arc — who invited whom, when, whether the invitee answered, and at acceptance which identity was bound.

This atom isolates that record from the machinery around it. It does not register the credential that follows acceptance ([Credential](./credential.md)), create the identity record the accepted invitee becomes ([Party Identity](./party-identity.md)), issue the session ([Session](./session.md)), or sequence those steps ([External Onboarding](../compositions/external-onboarding.md)). It answers one question, from the invitation record alone.

The declined terminal is what separates Invitation from [Capability](./capability.md) at the EOS Pass 2 boundary. Both use bearer-token transport, both are time-bounded, both can be revoked. The difference is that a refusal is a deliberate act by a named party and matters to the audit record independently of whether the token was ever presented — a capability's bearer either redeems it or does not, and the non-use is not an outcome the system records.

This is a freestanding atom in the EOS sense: its own state, its own four writes and one read, and its own operational principles — single-resolution, expiry-is-derived, opaque invitee at initiation, identity binding at acceptance.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify an invitation by the invitation_token.
Identity 2: The atom MUST assign the invitation_token from the token material the seam supplies.
Identity 3: The atom MUST NOT generate an invitation_token.
Identity 4: The atom MUST NOT change an invitation's invitation_token.
Identity 5: Two invitations MUST NOT share an invitation_token.
Identity 6: IF the store holds the invitation_token THEN [Initiate] MUST answer storage-failure.
Identity 7: The atom MUST NOT identify an invitation by a property.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that an inviter_ref names a known actor.
Identity 11: The atom MUST NOT confirm that an invitee_ref names a known actor.
Identity 12: The atom MUST NOT confirm that an accepting_identity_ref names a known identity.
Identity 13: The atom MUST NOT match an accepting_identity_ref against an invitee_ref.
Identity 14: The deployment MUST route EVERY call to one store instance.
```

Term invitation: the record this atom holds — one invitation issued by one inviter to join one context, resolved by at most one write.

Term invitation_token: the opaque value naming one invitation — an [Invitation Token]; assigned from the token material the seam supplies, and the bearer credential a holder presents.

Term property: inviter_ref | invitee_ref | context | initiated_at | expires_at — what an invitation carries from initiation that is not the invitation's identity.

Term reference: invitation_token, inviter_ref, invitee_ref, accepting_identity_ref OR revoked_by_ref — every opaque reference this atom records.

Term store instance: one named invitation store a call is routed to; invitation_token uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the token material here.

Term transition: the atom's evaluation of one call against the invitation store, as `execution-contract.md` §Logic confinement declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 5 and Identity 6 are a pair, and the pair is the point. An absolute uniqueness claim over a value drawn from a random source is not made true by the source being wide: 128 bits makes a collision fantastically unlikely and leaves the invariant logically false. Identity 6 is the cure [Capability](./capability.md) carries — the *store* refuses the colliding write, so a collision surfaces as an outcome the signature already names and uniqueness is enforced rather than hoped for. This atom is the second to carry it, and the docket row counting the atoms that do not is where the corpus-wide ruling sits.

Identity 10 through 13 are one posture stated four times because each is separately temptable. The atom holds references it was handed; it confirms none of them, and above all it does not check the accepting identity against the intended invitee. That last one is not an oversight — an invitation is very often addressed to an email that names no system identity at all, and the identity is created at acceptance. A deployment that does require the two to match enforces it above this atom (Non-goal 10).

### State

```
State 1: EVERY invitation MUST carry invitation_token, inviter_ref, context, initiated_at, expires_at and a status.
State 2: An invitation MAY carry an invitee_ref.
State 3: EVERY accepted invitation MUST carry accepting_identity_ref and accepted_at.
State 4: EVERY declined invitation MUST carry declined_at.
State 5: EVERY revoked invitation MUST carry revoked_by_ref, revocation_reason and revoked_at.
State 6: A pending invitation MUST NOT carry a resolution field.
State 7: The atom MUST NOT store expired as a status.
State 8: An invitation MUST NOT carry an expiry instant.
State 9: The atom MUST NOT record the ttl under the ttl's own name.
State 10: The atom MUST NOT offer a re-open surface.
State 11: The atom MUST NOT offer a window extension surface.
State 12: The atom MUST NOT offer an invitation removal surface.
State 13: The store instance's invitation count MUST NOT fall.
```

Term resolution field: accepting_identity_ref | accepted_at | declined_at | revoked_at | revoked_by_ref | revocation_reason — every field a resolving write records.

WHY:
State 7 and State 8 are the derived-expiry posture on the record surface, and they are two rules rather than one because an implementation can breach each without the other: a stored expired status, and an `expired_at` column beside a status that stays pending. Either one reintroduces the flag that lags the clock.

State 10 and State 11 are the surfaces a reader keeps expecting. A declined or lapsed invitation is not re-opened and a deadline is not moved — trying again is a fresh [Initiate] with a fresh token and its own audit entry, and the original stays in the store as history. Moving expires_at would retroactively change what a past read returned, which is the one thing a derived status cannot survive.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the token material at the seam.
Capability requirement 3: The deployment MUST supply token material drawn from a cryptographically random source.
Capability requirement 4: The deployment MUST declare the default ttl.
Capability requirement 5: The deployment MUST declare the ttl bounds.
Capability requirement 6: The store MUST refuse a write carrying an invitation_token the store holds.
Capability requirement 7: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 8: The deployment MUST canonicalize an opaque reference.
Capability requirement 9: The deployment MUST deliver the invitation_token to the invitee.
Capability requirement 10: The deployment MUST own the clock's skew.
Capability requirement 11: The deployment MUST own the clock's monotonicity.
Deleted: Clock semantics 4. Capability requirement 10 owns it.
Deleted: Clock semantics 1. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 2. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 3. `execution-contract.md` §Logic confinement owns it.
Deleted: Clock semantics 5. Capability requirement 11 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

WHY:
Capability requirement 3 is where the token's security actually lives. Nothing in this atom's rules can tell a random token from a sequential one — both are opaque values it stores and compares — and a guessable token makes every other guarantee here worthless, because an attacker who can produce a valid token accepts an invitation that was never sent to them. Capability requirement 6 is its partner and does the work Identity 6 states: the store, not the atom, is what makes uniqueness true.

Capability requirement 7 and Identity 6 are worth reading together, because the second borrows the first's answer. A token collision is refused by the store and surfaces as storage-failure, which is true about the outcome — nothing committed — and loose about the cause: a collision is a correct refusal of a well-formed call, not a store that failed, and the remedy differs (fresh token material, not the same write retried). Operation 5 does the same thing one row down, answering invalid-request when the deployment declared no default ttl — a configuration gap charged to the caller. Both are defensible and neither is precise, and the reason is the same in both places: the answer set is closed (Closed vocabulary 22), so a rare condition is routed to the nearest existing arm rather than earning one. The docket row counts that shape across the corpus rather than each spec deciding alone (council read 39).

WHY:
Non-goal 25 is the price of deriving the status, and it is worth naming rather than hiding. Two readers with slightly different clocks, reading the same invitation near its expires_at, can disagree about whether it is expired — and that is harmless *here* precisely because nothing is written: no record diverges, no resolution is recorded twice, and the next read from either reader settles it. The same disagreement around a stored flag would be two stores that no longer match.

### Operations

```
initiate(inviter_ref, optional invitee_ref, context, optional ttl)
  answers invitation_token
  refuses invalid-request | storage-failure

accept(invitation_token, accepting_identity_ref)
  answers accepted
  refuses not-known | already-resolved(stored terminal) | expired | invalid-request | storage-failure

decline(invitation_token)
  answers declined
  refuses not-known | already-resolved(stored terminal) | expired | storage-failure

revoke(invitation_token, revoked_by_ref, reason)
  answers revoked
  refuses not-known | already-resolved(stored terminal) | expired | invalid-request | storage-failure

read(filter)
  answers the matching invitations
```

```
Operation 1: IF inviter_ref EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 2: IF context EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 3: IF the ttl falls outside the ttl bounds THEN [Initiate] MUST answer invalid-request.
Operation 4: IF ttl EQUALS blank THEN [Initiate] MUST read the default ttl as the ttl.
Operation 5: IF the default ttl EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 6: [Initiate] MUST NOT answer invalid-request on an absent invitee_ref.
Operation 7: [Initiate] MUST NOT answer not-known.
Operation 8: An admitted initiate MUST assign a fresh invitation_token.
Operation 9: An admitted initiate MUST record inviter_ref and context.
Operation 10: An admitted initiate MUST record a supplied invitee_ref.
Operation 11: An admitted initiate MUST record now as initiated_at.
Operation 12: An admitted initiate MUST record the expiry bound as expires_at.
Operation 13: An admitted initiate MUST stand the invitation in pending.
Operation 14: An admitted initiate MUST answer the invitation_token.
Operation 15: IF the invitation_token names no invitation THEN a resolving write MUST answer not-known.
Operation 16: IF the invitation's status IS IN the stored terminals THEN a resolving write MUST answer already-resolved.
Operation 17: A resolving write answering already-resolved MUST name the invitation's status.
Operation 18: A resolving write MUST NOT name expired as a stored terminal.
Operation 19: A resolving write MUST answer already-resolved ONLY IF the invitation_token names an invitation.
Operation 20: IF the invitation reads lapsed THEN a resolving write MUST answer expired.
Operation 21: A resolving write MUST answer expired ONLY IF the invitation's status EQUALS pending.
Operation 22: A refused resolving write MUST NOT record a field.
Operation 23: IF accepting_identity_ref EQUALS blank THEN [Accept] MUST answer invalid-request.
Operation 24: IF revoked_by_ref EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 25: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 26: A resolving write MUST answer invalid-request ONLY IF EVERY status check passes.
Operation 27: [Decline] MUST NOT accept an acting reference.
Operation 28: An admitted accept MUST stand the invitation in accepted.
Operation 29: An admitted accept MUST record accepting_identity_ref and now as accepted_at.
Operation 30: An admitted decline MUST stand the invitation in declined.
Operation 31: An admitted decline MUST record now as declined_at.
Operation 32: An admitted revoke MUST stand the invitation in revoked.
Operation 33: An admitted revoke MUST record revoked_by_ref, reason as revocation_reason and now as revoked_at.
Operation 34: A resolving write MUST commit the status change and the recorded fields in one transition.
Operation 35: IF the store refuses the write THEN an action MUST answer storage-failure.
Operation 36: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 37: A refused action MUST leave the invitation as the call found the invitation.
Operation 38: A refused [Initiate] MUST NOT record an invitation.
Operation 39: A refused resolving write MUST leave the invitation in pending.
Operation 40: The atom MUST NOT offer an expire action.
Operation 41: An admitted read MUST answer EVERY matching invitation.
Operation 42: An admitted read MUST answer the effective status PER matching invitation.
Operation 43: [Read] MUST NOT record a field.
Operation 44: [Read] MUST NOT refuse a filter.
Deleted: Operation 45. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 46. `execution-contract.md` §Logic confinement owns it.
```

Term resolving write: [Accept] | [Decline] | [Revoke] — every write taking a pending invitation to a stored terminal.

Term stored terminal: accepted | declined | revoked.

Term status: pending | accepted | declined | revoked — the value an invitation stores.

Term status check: Operation 15, Operation 16 and Operation 20 — every check a resolving write makes on the invitation's own standing before reading the call's inputs.

Term ttl bounds: the deployment's admitted range for a ttl; every admitted value exceeds zero.

Term default ttl: the ttl the deployment declares for an [Initiate] carrying none.

Term expiry bound: initiated_at raised by the ttl — the value an admitted initiate records as expires_at.

Term window reading: live | lapsed — how a pending invitation's window reads against now.

Term live: the window reading of a pending invitation whose expires_at exceeds now.

Term lapsed: the window reading of a pending invitation whose expires_at does not exceed now; the boundary instant — expires_at equal to now — reads lapsed.

Term effective status: expired where the invitation reads lapsed, and the stored status otherwise — a projection over the invitation and now, never stored.

Term acting reference: accepting_identity_ref OR revoked_by_ref — the reference a write records for who acted.

Term admitted initiate: an [Initiate] call that passes every precondition and whose store write commits.

Term admitted accept: an [Accept] call that passes every precondition and whose store write commits.

Term admitted decline: a [Decline] call that passes every precondition and whose store write commits.

Term admitted revoke: a [Revoke] call that passes every precondition and whose store write commits.

Term admitted resolving write: an admitted accept, an admitted decline OR an admitted revoke.

Term admitted read: a [Read] call that answers.

WHY:
Operation 19, Operation 21, Operation 26 and Operation 36 are the rejection priority, written as guards rather than as an order — nothing may be inferred from rule order (GRACE-lang Timing 13). The effect is not-known before already-resolved before expired before invalid-request before storage-failure, and the placement of invalid-request *after* the status checks is deliberate: a caller who supplied a blank reason to revoke an already-accepted invitation learns that the invitation is accepted, which is the fact that ends the conversation, rather than being sent to fix an argument that would not have helped.

Operation 17 and Operation 18 are what make the refusal useful. `already-resolved(accepted)` says something different from `already-resolved(revoked)` — one means the seat is taken, the other means the inviter changed their mind — and a bare already-resolved throws that away. Operation 18 keeps expired out of the payload, because there is no stored [Expired] to name: a lapsed invitation is still standing in pending and gets the separate [Expired Rejection] instead (Operation 20). The two are one word in two value sets — a status a read computes, and a refusal a write receives — and conflating them would let a caller read *this was resolved as expired*, which never happens here.

Operation 40 is the whole of the derived-expiry posture stated as an absence, which is the one thing a reader cannot infer from silence (GRACE-lang Hard invariant 16). Nothing fires when an invitation lapses; there is no write to schedule, no flag to lag behind the clock, and `Invariant 12` is the property that follows.

Operation 44 makes [Read] a total read: a filter that matches nothing has a correct answer — no invitations — rather than an error. That shape now recurs in seven specs and no rule anywhere owns the reason, which is a watch entry rather than a claim.

Logic confinement is the Contract's (`execution-contract.md` §Logic confinement), and the now declaration cites it rather than restating it. The clock is consumed twice per call — by the window reading and by the write's stamps — and both read the one now the seam supplied.

### Invariants

- **Invariant 1 — Initiation immutability.**
  ```
  Invariant 1.1: An admitted resolving write MUST NOT change a property.
  Deleted: Invariant 1.2. State 6 and Operation 16 leave a resolving write no resolution field to find.
  ```
  WHY: a draft carried a second rule — *an admitted resolving write MUST NOT change a resolution field the write found* — and it could not bind. An admitted resolving write runs only on a pending invitation (Operation 16 refuses every other case), and a pending invitation carries no resolution field (State 6), so the set the rule quantified over is empty at every reachable state. Same class as the resource return [Provisional Commitment](./provisional-commitment.md) re-homed one atom earlier: a MUST that cannot be violated is decoration, and the cure is to find the rule that already makes it true rather than to keep a second copy that cannot fail (council read 39).
- **Invariant 2 — Single-resolution by write.**
  ```
  Invariant 2.1: An invitation MUST NOT reach two stored terminals.
  Invariant 2.2: An invitation MUST NOT carry two resolution instants.
  ```
  WHY: both rules are *at most one*, and the atom makes no claim that an invitation is ever resolved at all — a pending invitation whose window lapses is never written, and `Non-goal 24` says so. Concurrency 1 is the mechanism that delivers the at-most-one under racing writes.
- **Invariant 3 — Acceptance binds identity.**
  ```
  Invariant 3.1: EVERY accepted invitation MUST carry a non-blank accepting_identity_ref.
  Invariant 3.2: An admitted accept MUST commit accepting_identity_ref and accepted_at with the status change.
  Deleted: Invariant 4. Identity 13, State 2 and Operation 6 own the opaque invitee.
  ```
  WHY: the load-bearing one, and the reason this atom exists rather than folding into [Capability](./capability.md). An accepted invitation with no bound identity is an account that entered the system through a documented channel with nobody's name on it, which is exactly the record a regulator comes here to read.
- **Invariant 5 — The stored terminals are structurally distinct.**
  ```
  Invariant 5.1: Two stored terminals MUST NOT carry one resolution field pattern.
  ```
  WHY: the field pattern is what an auditor reads when the status column is not enough — an accepted invitation carries an identity and an instant, a declined one carries an instant alone, a revoked one carries an actor, a reason and an instant. Collapsing any two would make a refusal and a withdrawal the same event in the record, and they are not.
- **Invariant 6 — A refusal names what blocked it.**
  ```
  Invariant 6.1: EVERY already-resolved answer MUST name a stored terminal.
  Invariant 6.2: A lapsed invitation's resolving write MUST answer expired.
  ```
- **Invariant 7 — Expiry deadline immutability.**
  ```
  Invariant 7.1: The atom MUST NOT change an invitation's expires_at.
  ```
- **Invariant 8 — Revocation attribution completeness.**
  ```
  Invariant 8.1: EVERY revoked invitation MUST carry a non-blank revoked_by_ref.
  Invariant 8.2: EVERY revoked invitation MUST carry a non-blank revocation_reason.
  Invariant 8.3: EVERY revoked invitation MUST carry a revoked_at.
  ```
  WHY: withdrawal is the one resolution taken *against* the invitee rather than by them, so it is the one that must justify itself. An anonymous revocation, or one with a whitespace reason, defeats the record a dispute is settled from.
- **Invariant 9 — Every invitation has a finite lifetime.**
  ```
  Invariant 9.1: EVERY invitation MUST carry an expires_at.
  ```
  WHY: an invitation that never expires is not expressible here, and that is a design choice rather than a limitation. A bearer token with no deadline is a standing key; the deadline is what makes the outstanding set bounded and the derived status decidable.
- **Invariant 10 — Invitation durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove an invitation from the store.
  Invariant 10.2: A storage-failure rejection MUST leave no partial invitation in the store.
  ```
- **Invariant 11 — Token uniqueness is store-enforced.**
  ```
  Invariant 11.1: An invitation_token MUST resolve to EXACTLY ONE invitation.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when an invitation lapses.
  Invariant 12.2: An admitted read MUST compute the effective status from the invitation's expires_at and now.
  ```
  WHY: this atom is the corpus's worked reference for derived expiry, and the boundary it sits on is stated by its opposite. [Provisional Commitment](./provisional-commitment.md) stores its lapse as a terminal reached by an explicit write, because *its* lapse returns a resource and a pool slot — a side effect needs a write to hang on. An invitation's lapse releases nothing. Nothing happens when the window closes except that a reader computing the status gets a different answer, so nothing is written and there is no stored flag to drift from the clock.

---

## Examples

### New employee onboarding — accept

`initiate(admin_a7, none, "org:northwind", 7-days)` → `tok_inv_c41`, standing pending. The token reaches the new hire out of band. Three days in, `accept(tok_inv_c41, user_u114)` → accepted, binding `user_u114` permanently. The invitee_ref was absent at initiation because the hire had no system identity to name; the identity now recorded is the one that presented the token. [External Onboarding](../compositions/external-onboarding.md) proceeds from here to a party record, a credential and a session.

### Workspace collaboration — decline

`initiate(owner_w3, contractor_c9, "workspace:atlas", 14-days)` → `tok_inv_d58`. The contractor declines: `decline(tok_inv_d58)` → declined, stamping declined_at and nothing else. No identity is bound, because nobody joined. The record says a holder of the token saw the invitation and refused — which is a different fact from the window closing unanswered, and the reason declined is a terminal of its own.

### Revoked before use

`initiate(admin_a7, vendor_v2, "org:northwind", 30-days)` → `tok_inv_e5f`. The engagement falls through and `revoke(tok_inv_e5f, admin_a7, "engagement cancelled")` → revoked. A later `accept(tok_inv_e5f, user_u220)` answers `already-resolved(revoked)` — not merely *no*, but *withdrawn, and here is which resolution stands*.

### The window closes

`initiate(admin_a7, none, "org:northwind", 7-days)` → `tok_inv_f77`. Nobody answers. On the eighth day nothing has happened to the record: it still stands pending, carries no resolution field, and read returns it with an effective status of expired. An accept against it answers expired and writes nothing. The eventual difference between this invitation and `tok_inv_d58` above is the whole reason declined is a stored terminal.

### Rejection paths

`accept(tok_unknown, user_u1)` → not-known. `accept(tok_inv_c41, user_u1)` on the already-accepted invitation → `already-resolved(accepted)`. `accept(tok_inv_f77, user_u1)` on the lapsed one → expired. `revoke(tok_inv_c41, admin_a7, "  ")` → `already-resolved(accepted)`, not invalid-request: the status check runs first, and the fact that ends the conversation is that the invitation was accepted (Operation 26).

### Regulated adversarial scenarios

- **Regulator audit.** *Prove that every user who reached patient records joined through a documented invitation from an authorized administrator.* Filter the store to accepted invitations whose context names that system; each record carries the administrator who invited (inviter_ref), when the join committed (accepted_at) and the identity bound (accepting_identity_ref). Invariant 3.1 is what makes the last of those never empty, so every current participant traces to one invitation and one administrator.
- **Disputed onboarding.** *I never accepted an invitation — my account was made without me.* Filter by accepting_identity_ref; Invariant 2.1 means there is at most one resolved invitation bound to that identity, and it carries the instant the token was presented. Whether that person or someone holding their token made the call is outside this atom — the record says a bearer presented `tok_inv_e5f6g7` at that instant and supplied that identity, and the composing [Audit Trail](../compositions/audit-trail.md) carries the device, the address and the credential registered alongside.
- **Breach investigation.** Tokens for a high-security context were exposed in a log over a week. Filter by initiated_at in that window and read each effective status against the investigation clock: the accepted ones are cross-checked against known staff, the still-live ones are revoked at once, and the lapsed ones need nothing — no write ever fired against them and an accept would answer expired. Invariant 5.1 and Invariant 12.2 are what make that triage possible from the store and a clock alone.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the invitation store and the read-time clock alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find no invitation carrying two resolution instants (Invariant 2.2).
Check 1.2: An auditor MUST find EXACTLY ONE resolution instant on EVERY invitation whose status IS IN the stored terminals (State 3, State 4, State 5).
Check 1.3: An auditor MUST find no resolution field on a pending invitation (State 6).
Check 2.1: An auditor MUST find no invitation storing expired as a status (State 7).
Check 2.2: An auditor MUST find no invitation carrying an expiry instant (State 8).
Check 2.3: An auditor MUST reproduce an admitted read's effective status from the invitation's expires_at and a clock the auditor supplies (Invariant 12.2).
Check 3.1: An auditor MUST find a non-blank accepting_identity_ref on EVERY accepted invitation (Invariant 3.1).
Check 3.2: An auditor MUST find an accepted_at on EVERY accepted invitation (State 3).
Check 4.1: An auditor MUST find no two stored terminals carrying one resolution field pattern (Invariant 5.1).
Check 5.1: An auditor MUST find a non-blank revoked_by_ref on EVERY revoked invitation (Invariant 8.1).
Check 5.2: An auditor MUST find a non-blank revocation_reason on EVERY revoked invitation (Invariant 8.2).
Check 5.3: An auditor MUST find a revoked_at on EVERY revoked invitation (Invariant 8.3).
Check 6.1: An auditor MUST find an expires_at on EVERY invitation (Invariant 9.1).
Check 6.2: An auditor MUST find no invitation's expires_at changed across a re-read (Invariant 7.1).
Check 7.1: An auditor MUST find no invitation_token on two invitations (Identity 5, Invariant 11.1).
Check 7.2: An auditor MUST find a re-read invitation's properties unchanged across an admitted resolving write (Invariant 1.1).
Check 8.1: An auditor MUST find no invitation absent from a later read (Invariant 10.1).
Check 8.2: An auditor MUST find the store instance's invitation count no lower on a later read (State 13).
Check 9.1: An auditor MUST reconstruct EVERY invitation of one context from the store (State 1, State 13, Invariant 10.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing an already-resolved answer's payload confirmed MUST read the caller's record of the answer (Non-goal 22).
External check 2: A deployment needing an accepting_identity_ref matched to the invitee MUST read the composing pattern's own rule (Identity 13, Non-goal 10).
External check 3: A deployment needing the inviter's authority confirmed MUST read the composing policy layer (Non-goal 6).
External check 4: A deployment needing the token's delivery to the invitee confirmed MUST read the delivery channel (Non-goal 4).
External check 5: A deployment needing a declining actor identified MUST read the composing pattern's own record (Operation 27, Non-goal 12).
External check 6: A deployment needing the store confirmed free of a retroactive edit MUST read the composing Tamper Evidence (Non-goal 20).
External check 7: A deployment needing the accepting party's real-world identity confirmed MUST read the composing Party Identity proofing (Non-goal 18).
```

WHY:
External check 1 is the one a deployment can quietly lose. The already-resolved payload is an *answer*, not a record: nothing in the store says what a refused call was told, so an auditor asking *did this caller learn the invitation was revoked rather than merely unavailable* cannot get it from here. This is the corpus's lost-answer problem in its plainest form — the store is exactly what is missing the refusals — and the docket row is where it is owned.

External check 5 follows from Operation 27. [Decline] takes no acting reference, so the store records that a holder of the token refused and never who. That asymmetry against [Accept] is deliberate — acceptance creates a relationship the system must attribute, refusal closes one and creates nothing — but a deployment that does need the declining party named records it above this atom.

---

## Non-goals

```
Non-goal 1: The atom MUST NOT create an identity record for an accepted invitation.
Non-goal 2: A deployment needing an identity record MUST compose Party Identity.
Non-goal 3: The atom MUST NOT register a credential.
Non-goal 4: The atom MUST NOT deliver the invitation_token.
Non-goal 5: The atom MUST NOT issue a session.
Non-goal 6: The atom MUST NOT decide who may invite whom.
Non-goal 7: The atom MUST NOT decide what a context names.
Non-goal 8: The atom MUST NOT sequence the steps following an acceptance.
Non-goal 9: A deployment needing the onboarding arc sequenced MUST compose External Onboarding.
Non-goal 10: A deployment needing an accepting identity matched to an invitee MUST compose a matching rule.
Non-goal 11: The atom MUST NOT offer a second acceptance of one invitation.
Non-goal 12: The atom MUST NOT record who declined.
Non-goal 13: The atom MUST NOT record a transition history.
Non-goal 14: A deployment needing the full transition history MUST compose Event Log.
Non-goal 15: The atom MUST NOT bind an acting reference to an actor.
Non-goal 16: A deployment needing a non-repudiable acceptance MUST compose Actor Identity.
Non-goal 17: The atom MUST NOT verify an accepting party's real-world credentials.
Non-goal 18: A deployment needing identity proofing MUST compose Party Identity.
Non-goal 19: The atom MUST NOT detect a rewrite under the store.
Non-goal 20: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 21: The atom MUST NOT bound an invitation's retention.
Non-goal 22: The atom MUST NOT record an answer the atom gave.
Non-goal 23: The atom MUST NOT decide whether a token holder may pass the token on.
Non-goal 24: The atom MUST NOT guarantee that an invitation resolves.
Non-goal 25: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 26: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 11 and Non-goal 23 are one boundary from two sides, and it is the boundary that separates this atom from a team invite link. An invitation is single-use: whoever presents the token becomes the accepting identity, and the invitation is then resolved for everyone. A link many people may follow is a [Capability](./capability.md) with a redemption count, and each redemption of *that* triggers an [Initiate] here for one named invitee.

Non-goal 24 is the honest limit on single-resolution. Nothing here makes an invitation resolve; a token nobody presents leaves a pending record whose window closes and whose status thereafter reads expired forever, and that is the intended outcome rather than a stuck state.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: The implementation MUST commit a transition whole.
Atomic writes 2: The implementation MUST discard an uncommitted transition whole.
Atomic writes 3: The implementation MUST own the transactional boundary.
Atomic writes 4: The implementation MUST NOT repair a dangling transition.
```

### Concurrency

```
Concurrency 1: The implementation MUST commit the status check and the status change of a resolving write as one atomic operation.
Concurrency 2: A losing resolving write MUST answer already-resolved.
Concurrency 3: A losing resolving write MUST name the stored terminal the winner recorded.
```

WHY:
Concurrency 3 is the race the atom is most often asked to survive: two people accepting one invitation at the same instant. One commits, and the other is not merely refused — it is told `already-resolved(accepted)`, which lets a caller distinguish *someone else took this* from *this was withdrawn* without a second read.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: a reference, context OR reason — every caller-supplied string this atom accepts.


WHY:
Byte-exactness is sharper here than in most atoms because the invitation_token is a bearer credential: a lookup that trimmed or case-folded would make a family of near-miss tokens resolve to a real invitation, which is a guessing surface rather than a convenience. Canonicalization, where a deployment wants it, happens before the call (Capability requirement 8, Identity 9).

NOTE: watch host obligations — this atom sets no maximum length on a string input and does not oblige the deployment to set one, which is the *input-handling regime* docket row's silence posture.

---

## Composition notes

```
Composition note 1: A composing External Onboarding MUST create the party record ONLY AFTER an admitted accept.
Composition note 2: A composing External Onboarding MUST pass the accepting_identity_ref as the party record's reference.
Composition note 3: A composing Credential MUST register against the accepting_identity_ref.
Composition note 4: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 5: A composing Event Log MUST append an event on EVERY refused action.
Composition note 6: A composing Actor Identity MUST attest the actor behind an admitted accept.
Composition note 7: A composing Actor Identity MUST attest the actor behind an admitted initiate.
Composition note 8: A composing Tamper Evidence MUST cover EVERY reference the store holds.
Composition note 9: A composing Capability MUST call [Initiate] PER redemption.
```

WHY:
Composition note 1 is [External Onboarding](../compositions/external-onboarding.md)'s load-bearing emergent invariant seen from below — *invitation gates enrollment*: no party record exists that no accepted invitation preceded. This atom cannot state that as an invariant of its own, because it neither creates nor sees party records; it states the ordering the composition must honour and the composition owns the guarantee.

Composition note 9 is the Capability boundary made operational. A many-redemption link is a capability, and each redemption of it opens one single-use invitation here for one party — which is how a corpus keeps two atoms that look alike from collapsing into one that does both jobs badly.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the store; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a reader; an invitation; a pending invitation; an accepted invitation; a declined invitation; a revoked invitation; a lapsed invitation; an action; a resolving write; a losing resolving write; a refused action; a rejection; an answer; a token holder; an opaque reference; a string input; a filter; the store instance's invitation count.

Term records: invitation — one invitation issued by one inviter to join one context, carrying invitation_token, inviter_ref, context, initiated_at, expires_at, a status and, where supplied or set, invitee_ref, accepting_identity_ref, accepted_at, declined_at, revoked_by_ref, revocation_reason and revoked_at.

Term record verbs: identify, assign, generate, change, share, reuse, carry, stand, read, answer, record, leave, admit, offer, hold, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, deliver, acknowledge, canonicalize, declare, compose, remove, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, draw, verify, sequence, issue, detect, guarantee, take, store, own.

Term value sets: status = pending | accepted | declined | revoked. stored terminal = accepted | declined | revoked. window reading = live | lapsed. property = inviter_ref | invitee_ref | context | initiated_at | expires_at. resolution field = accepting_identity_ref | accepted_at | declined_at | revoked_at | revoked_by_ref | revocation_reason.

Term bounds: ttl bounds, default ttl, expiry bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: invitation, invitation_token, property, reference, store instance, seam, transition, now, resolving write, stored terminal, status, status check, ttl bounds, default ttl, expiry bound, window reading, live, lapsed, effective status, acting reference, admitted initiate, admitted accept, admitted decline, admitted revoke, admitted resolving write, admitted read, resolution field, resolution instant, string input, blank.

Term cited: `execution-contract.md` §Logic confinement — the seam and the transition.

Term composing pattern: [Party Identity](./party-identity.md), [Credential](./credential.md), [Session](./session.md), [Actor Identity](./actor-identity.md), [Event Log](./event-log.md), [Tamper Evidence](./tamper-evidence.md), [Capability](./capability.md), [External Onboarding](../compositions/external-onboarding.md).

Term resolution instant: accepted_at | declined_at | revoked_at.

#### Initiate

The behavior that records a new [Invitation] — assigning a fresh [Invitation Token] from the token material the seam supplies, setting [Inviter Ref], an optional [Invitee Ref], [Context], [Initiated At] and [Expires At], standing the record in [Pending], and answering the token. Rejected [Invalid Request] or [Storage Failure].

Kind: Operation

#### Accept

The resolving write that binds an identity to the invitation, standing it in [Accepted] and recording [Accepting Identity Ref] and [Accepted At]. Legal only while the invitation stands in [Pending] and reads live. Rejected [Not Known], [Already Resolved], [Expired], [Invalid Request] or [Storage Failure].

Kind: Operation

#### Decline

The resolving write that records a deliberate refusal, standing the invitation in [Declined] and stamping [Declined At]. Takes no acting reference: the refusal is recorded, the refuser is not. Legal only while the invitation stands in [Pending] and reads live.

Kind: Operation

#### Revoke

The resolving write by which the inviting side withdraws the invitation, standing it in [Revoked] and recording [Revoked By Ref], [Revocation Reason] and [Revoked At]. Legal only while the invitation stands in [Pending] and reads live; a lapsed invitation needs no withdrawal, since it already reads [Expired].

Kind: Operation

#### Read

The read-only query answering the matching [Invitation] records, each carrying its stored fields and its derived [Effective Status]. Refuses nothing — a filter matching no invitation has a correct answer rather than an error.

Kind: Operation

#### Invitation

The record this atom defines: one invitation, issued by one inviter to join one context, resolved by at most one write. Carries [Invitation Token], [Inviter Ref], an optional [Invitee Ref], [Context], [Initiated At], [Expires At], [Status], and the resolution fields of whichever write settled it.

Kind: Type
Projection: status

#### Invitation Token

The opaque, immutable identity of an [Invitation] and the bearer credential a holder presents. Assigned on [Initiate] from the token material the seam supplies, drawn from a cryptographically random source, and unique by the store's refusal of a colliding write rather than by probability.

Kind:       Field
Field of:   Invitation
Projection: invitation_token

#### Inviter Ref

The opaque reference naming who issued the invitation. Required, set on [Initiate], immutable thereafter. The atom does not confirm it names a known actor, nor that the actor was authorized to invite.

Kind:       Field
Field of:   Invitation
Projection: inviter_ref

#### Invitee Ref

The opaque reference naming the intended recipient. **Optional** — an invitation is very often addressed to someone with no system identity yet, which is the case this atom exists to serve. Never validated, and never matched against [Accepting Identity Ref].

Kind:       Field
Field of:   Invitation
Projection: invitee_ref

#### Context

The opaque descriptor of what the invitee is being invited to join — an organization, a workspace, a role. Required, immutable, and interpreted by the composing pattern rather than here.

Kind:       Field
Field of:   Invitation
Projection: context

#### Initiated At

The instant the invitation was issued, stamped from [Now] on [Initiate]. Immutable.

Kind:       Field
Field of:   Invitation
Projection: initiated_at

#### Expires At

The instant the window closes, recorded on [Initiate] as the expiry bound. Immutable, never absent, and the sole stored input the derived [Effective Status] needs.

Kind:       Field
Field of:   Invitation
Projection: expires_at

#### Status

The stored status of an [Invitation] — [Pending], [Accepted], [Declined] or [Revoked]. [Expired] is not a value of this field; it appears only in the derived [Effective Status].

Kind:       Field
Field of:   Invitation
Projection: status

#### Accepting Identity Ref

The identity bound at acceptance — the permanent record of who joined. Recorded on [Accept], never absent on an [Accepted] invitation, immutable once set.

Kind:       Field
Field of:   Invitation
Projection: accepting_identity_ref

#### Accepted At

The instant the acceptance committed, stamped from [Now] on [Accept]. Present only in [Accepted]; immutable once set.

Kind:       Field
Field of:   Invitation
Projection: accepted_at

#### Declined At

The instant the refusal was recorded, stamped from [Now] on [Decline]. Present only in [Declined]; immutable once set. It is the whole of what a decline records.

Kind:       Field
Field of:   Invitation
Projection: declined_at

#### Revoked At

The instant the withdrawal was recorded, stamped from [Now] on [Revoke]. Present only in [Revoked]; immutable once set.

Kind:       Field
Field of:   Invitation
Projection: revoked_at

#### Revoked By Ref

The opaque reference naming who withdrew the invitation. Required on [Revoke], never blank on a [Revoked] invitation.

Kind:       Field
Field of:   Invitation
Projection: revoked_by_ref

#### Revocation Reason

The caller-supplied [Reason] for the withdrawal. Required on [Revoke] and never blank, because withdrawal is the one resolution taken against the invitee rather than by them.

Kind:       Field
Field of:   Invitation
Projection: revocation_reason

#### Effective Status

The status a [Read] answers: [Expired] where the invitation reads lapsed, and the stored [Status] otherwise. A projection over the invitation and [Now] — computed at read time, never stored, and the only surface on which [Expired] appears.

Kind:       Field
Field of:   Invitation
Projection: effective_status

#### TTL

The window length supplied to [Initiate]. Optional — an absent one takes the deployment's declared default. It sizes the window and is not stored under its own name; [Initiated At] and [Expires At] are what persist.

Kind:         Parameter
Parameter of: Initiate
Projection:   ttl

#### Reason

The withdrawal reason supplied to [Revoke], recorded as [Revocation Reason]. Required and never blank.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it — never read inside the transition and never supplied by the business caller. Consumed twice per call: by the window reading and by the write's stamps, and by [Read]'s [Effective Status] projection.

Kind:         Parameter
Parameter of: Initiate
Projection:   now

#### Pending

The one non-terminal status: the invitation is issued and unresolved. Reads live or lapsed against [Now], and a lapsed pending invitation is what [Effective Status] answers as [Expired].

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Accepted

The stored terminal reached when an identity was bound. Carries [Accepting Identity Ref] and [Accepted At]. Absorbing.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Declined

The stored terminal reached when a token holder deliberately refused. Carries [Declined At] alone. Absorbing, and distinct from a window that simply closed — which is the distinction that justifies this atom beside [Capability](./capability.md).

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Revoked

The stored terminal reached when the inviting side withdrew the invitation. Carries [Revoked By Ref], [Revocation Reason] and [Revoked At]. Absorbing.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Expired

The derived status of a [Pending] invitation whose window has closed. Never stored, carried by no field, and reached by no write — it is the value [Effective Status] computes from [Expires At] and [Now]. The refusal a resolving write against such an invitation receives is [Expired Rejection]: the same word, a different value set, and the reason Operation 18 forbids it appearing as an already-resolved payload.

Kind:      Member
Member of: the effective status
Role:      Outcome

#### Invalid Request

The refusal returned when a required argument is blank, or a supplied [TTL] falls outside the ttl bounds, or no default ttl is declared. On a resolving write it is reached only after every status check passes.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal a resolving write returns when the supplied [Invitation Token] names no invitation. A lookup miss, distinct from a status or window rejection.

Kind:       Member
Member of:  the resolving-write rejection
Role:       Outcome
Projection: not-known

#### Already Resolved

The refusal a resolving write returns when the invitation already stands in a stored terminal, naming which one. A bare answer without the terminal is not conformant — `already-resolved(accepted)` and `already-resolved(revoked)` are different facts about why the call failed.

Kind:       Member
Member of:  the resolving-write rejection
Role:       Outcome
Projection: already-resolved

#### Expired Rejection

The refusal a resolving write returns when the invitation stands in [Pending] and reads lapsed. Nothing is written and the record is left [Pending]. Never spelled as an already-resolved payload, because there is no stored [Expired] to name.

Kind:       Member
Member of:  the resolving-write rejection
Role:       Outcome
Projection: expired

#### Storage Failure

The refusal any action returns when the store refuses the write after every precondition passes — including the store's refusal of a colliding [Invitation Token]. No invitation is recorded, or the invitation remains [Pending].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Initiate]: #initiate
[Accept]: #accept
[Decline]: #decline
[Revoke]: #revoke
[Read]: #read
[Invitation]: #invitation
[Invitation Token]: #invitation-token
[Inviter Ref]: #inviter-ref
[Invitee Ref]: #invitee-ref
[Context]: #context
[Initiated At]: #initiated-at
[Expires At]: #expires-at
[Status]: #status
[Accepting Identity Ref]: #accepting-identity-ref
[Accepted At]: #accepted-at
[Declined At]: #declined-at
[Revoked At]: #revoked-at
[Revoked By Ref]: #revoked-by-ref
[Revocation Reason]: #revocation-reason
[Effective Status]: #effective-status
[TTL]: #ttl
[Reason]: #reason
[Now]: #now
[Pending]: #pending
[Accepted]: #accepted
[Declined]: #declined
[Revoked]: #revoked
[Expired]: #expired
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Already Resolved]: #already-resolved
[Expired Rejection]: #expired-rejection
[Storage Failure]: #storage-failure

---

## Standards references

- **GDPR Articles 6 and 7 (lawful basis and consent)** — [Initiate] creates a processing record: the system now holds an [Invitee Ref] and will process data about the invitee if they accept. [Initiated At] and [Inviter Ref] are the processing-event record; [Accepting Identity Ref] bound at [Accept] is the record of the data subject's active engagement.
- **HIPAA §164.312(a)(1) (access control)** — invitation-based provisioning is a covered access-granting mechanism. [Inviter Ref] is the authorized administrator who granted access and [Accepting Identity Ref] is the identity that gained it.
- **SCIM 2.0 (RFC 7644)** — SCIM's `POST /Users` with an invite flow maps to the Invitation → [External Onboarding](../compositions/external-onboarding.md) arc. [Invitee Ref] corresponds to the external identity reference; [Accepting Identity Ref] to the provisioned user id.
- **SOC 2 CC6.2 (users registered and authorized before credentials are issued)** — the invitation record *is* the registration and authorization event. [Inviter Ref] is the authorizing party; [Accepted At] and [Accepting Identity Ref] are the registration.
- **NIST SP 800-63A (enrollment and identity proofing)** — the enrollment event maps to the Invitation → accept arc. This atom models the enrollment record; proofing is [Party Identity](./party-identity.md)'s (Non-goal 17, Non-goal 18).

Standards anchoring here is lighter than for [Credential](./credential.md), [Session](./session.md) or [Capability](./capability.md), and deliberately so: this atom earns its place on EOS Pass 2 conceptual independence rather than on regulatory surface — the declined terminal, single-resolution by write, and identity binding at acceptance are what make it a separate atom instead of a fold into Capability.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; separating an invitation's lifecycle record from the provisioning that follows acceptance.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: verified — invitation.tla + 2 twins, 2026-06-03
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/invitation.md`.

- **2026-09-13 — The window boundary is declared once as a window reading, in the same two-member shape [Provisional Commitment](./provisional-commitment.md) uses.** *Chose:* live | lapsed, with the boundary instant declared onto the lapsed side, cited by the three resolving-write guards and by the effective-status projection. *Over:* repeating the comparison at each guard, which is how the prose carried it. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and the arithmetic belongs in the declaration rather than in a rule (Hard invariant 24). The two atoms name the members differently — `open` there, live here — because the record differs; the *shape* being identical across two independent specs is a new instance of the absence-as-nonexistence class the grammar's watch list counts, and is flagged rather than unified, since nothing yet says a shared reading should have one owner.
- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is `Non-goal 24`.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone. *Over:* a rule reading *exactly one write resolves an invitation*. *Because:* an invitation nobody answers is never written and reads expired forever, which is the designed outcome and not a stuck state — so *at least one* would be false here rather than merely unenforceable. Same decomposition [Provisional Commitment](./provisional-commitment.md) took, reached from the opposite direction.
- **2026-09-13 — The family is resolving write, not `resolving action`, and the difference from [Provisional Commitment](./provisional-commitment.md) is meant.** *Chose:* resolving write — [Accept], [Decline], [Revoke]. *Over:* `resolving action`, which is the name the same concept carries one atom over. *Because:* this atom has a [Read], so *action* would include a surface that resolves nothing and writes nothing, and the whole of the derived-expiry posture is that reading and writing are different things here. Provisional Commitment has no read, so nothing there needs the narrower word. The names diverge because the records do; a reader crossing between them should not assume the drift is carelessness (council read 39).
- **2026-06-21 — Expiry is derived at read time, never stored; this atom is the corpus's worked reference for the move.** *Chose:* the stored `Expired` state, the `expired_at` field and the `expire` action are removed; `Expired` is a read-time projection over the immutable expires_at and the injected clock. *Over:* a stored terminal a scheduler or a lazy write has to reach. *Because:* an invitation's lapse is side-effect-free, so a status that can be inferred at read time should be, and a flag that lags the clock is the idealization pitfall the methodology names. [Provisional Commitment](./provisional-commitment.md)'s 2026-06-23 entry is the boundary from the other side: its lapse returns a resource, so its expiry stays a written transition.

NOTE: End of Invitation.

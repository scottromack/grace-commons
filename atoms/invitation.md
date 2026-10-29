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

An invitation is issued before the invitee has an identity in the system, which is what makes it useful: it is the bridge from outsider to registered participant. Each is identified by a random token the invitee presents to act on it, and each starts pending. It is resolved by a write to one of three recorded end states — accepted (recording the identity that joined, which the pattern never changes or deletes), declined (a deliberate refusal, recorded as its own outcome), or revoked (the inviter withdrew it). If the window simply passes, the invitation *reads* expired: a status computed from the deadline and the clock, never written.

Resolving exactly once is the guarantee. After a write resolves an invitation, any further write is told which resolution stands — and two people accepting at once means one wins and the other is told. A write against a lapsed invitation is told it expired, which is a different answer from any of the three resolutions.

The key moment is acceptance, where a concrete identity is bound to what may have begun as an invitation to an unknown party. Declined is what sets this apart from a plain bearer token (a code that works for whoever holds it): a refusal is a recorded human decision, distinct from never using the invitation at all. The credential setup, identity record and login that usually follow acceptance are separate patterns.

---

## Intent

Systems that admit external parties face one structural problem: the invitation must be issued before the invitee's system identity exists, yet acceptance is the moment that identity must be established. The invitation is the bridge, and it carries the whole arc — who invited whom, when, whether the invitee answered, and at acceptance which identity was bound.

This atom isolates that record from the machinery around it. It does not register the credential that follows acceptance ([Credential](./credential.md)), create the identity record the accepted invitee becomes ([Party Identity](./party-identity.md)), issue the session ([Session](./session.md)), or sequence those steps ([External Onboarding](../compositions/external-onboarding.md)). It answers one question, from the invitation record alone.

The declined terminal is what separates Invitation from [Capability](./capability.md) at the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) Pass 2 boundary. Both use bearer-token transport, both are time-bounded, both can be revoked. The difference is that a refusal is a deliberate act by a named party and matters to the audit record independently of whether the token was ever presented — a capability's bearer either redeems it or does not, and the non-use is not an outcome the system records.

This is a freestanding atom in the EOS sense: its own state, its own four writes and one read, and its own operational principles — single-resolution, expiry-is-derived, opaque invitee at initiation, identity binding at acceptance.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify an invitation by the invitation token.
Identity 2: The atom MUST assign the invitation token from the token material the seam supplies.
Identity 3: The atom MUST NOT generate an invitation token.
Identity 4: The atom MUST NOT change an invitation's invitation token.
Identity 5: Two invitations MUST NOT share an invitation token.
Identity 6: IF the database holds the invitation token THEN [Initiate] MUST answer storage-failure.
Identity 7: The atom MUST NOT identify an invitation by a property.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that an inviter reference names a known actor.
Identity 11: The atom MUST NOT confirm that an invitee reference names a known actor.
Identity 12: The atom MUST NOT confirm that an accepting identity reference names a known identity.
Identity 13: The atom MUST NOT match an accepting identity reference against an invitee reference.
Deleted: Identity 14. Execution Contract Database 7 owns it.
```

Term invitation: the record this atom holds — one invitation issued by one inviter to join one context, resolved by at most one write.

Term invitation token: the opaque value naming one invitation — an [Invitation Token]; assigned from the token material the seam supplies, and the bearer credential a holder presents.

Term property: inviter reference | invitee reference | context | initiation instant | expiry instant — what an invitation carries from initiation that is not the invitation's identity.

Term reference: invitation token, inviter reference, invitee reference, accepting identity reference OR revoked by reference — every opaque reference this atom records.

Term database instance: one named database a call is routed to; invitation token uniqueness ranges over one instance.

Term seam: the atom's I/O (input and output) boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the token material here.

Term transition: the atom's evaluation of one call against the invitation records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### State

```
State 1: EVERY invitation MUST carry invitation token, inviter reference, context, initiation instant, expiry instant and a status.
State 2: An invitation MAY carry an invitee reference.
State 3: EVERY accepted invitation MUST carry accepting identity reference and acceptance instant.
State 4: EVERY declined invitation MUST carry declination instant.
State 5: EVERY revoked invitation MUST carry revoked by reference, revocation reason and revocation instant.
State 6: A pending invitation MUST NOT carry a resolution field.
State 7: The atom MUST NOT store expired as a status.
Deleted: State 8. Invariant 12.1 owns it.
State 9: The atom MUST NOT record the ttl under the ttl's own name.
State 10: The atom MUST NOT offer a re-open surface.
State 11: The atom MUST NOT offer a window extension surface.
State 12: The atom MUST NOT offer an invitation removal surface.
State 13: The database instance's invitation count MUST NOT fall.
```

Term resolution field: accepting identity reference | acceptance instant | declination instant | revocation instant | revoked by reference | revocation reason — every field a resolving write records.

<details markdown="block">
<summary>WHY</summary>

State 7 and Invariant 12.1 are the derived-expiry posture, and they are two rules rather than one because an implementation can breach each without the other: a stored expired status, and an `expired_at` column written beside a status that stays pending.

</details>

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the token material at the seam.
Capability requirement 3: The deployment MUST supply token material drawn from a cryptographically random source.
Capability requirement 4: The deployment MUST declare the default ttl inside the ttl bounds.
Capability requirement 5: The deployment MUST declare the ttl bounds.
Capability requirement 6: The database MUST refuse a write carrying an invitation token the database holds.
Deleted: Capability requirement 7. Execution Contract Database 3 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 13 owns it.
Capability requirement 9: The deployment MUST deliver the invitation token to the invitee.
Capability requirement 12: The deployment MUST supply the invitation records PER Execution Contract Database 1 through 7, Execution Contract Read 4 and Execution Contract Refusal 1.
Deleted: Capability requirement 10. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 11. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

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
Operation 1: IF inviter reference EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 2: IF context EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 3: IF ttl DOES NOT EQUAL blank AND the ttl falls outside the ttl bounds THEN [Initiate] MUST answer invalid-request.
Operation 4: IF ttl EQUALS blank THEN [Initiate] MUST read the default ttl as the ttl.
Operation 5: IF the default ttl EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 6: [Initiate] MUST NOT answer invalid-request on an absent invitee reference.
Operation 7: [Initiate] MUST NOT answer not-known.
Operation 8: An admitted initiate MUST assign a fresh invitation token.
Operation 9: An admitted initiate MUST record inviter reference and context.
Operation 10: IF invitee reference DOES NOT EQUAL blank THEN an admitted initiate MUST record invitee reference.
Operation 11: An admitted initiate MUST record now as initiation instant.
Operation 12: An admitted initiate MUST record the expiry bound as expiry instant.
Operation 13: An admitted initiate MUST stand the invitation in pending.
Operation 14: An admitted initiate MUST answer the invitation token.
Operation 15: IF the invitation token names no invitation THEN a resolving write MUST answer not-known.
Operation 16: IF the invitation's status IS IN the stored terminals THEN a resolving write MUST answer already-resolved.
Operation 17: A resolving write answering already-resolved MUST name the invitation's status.
Operation 18: A resolving write MUST NOT name expired as a stored terminal.
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Operation 20: IF the invitation reads lapsed THEN a resolving write MUST answer expired.
Deleted: Operation 21. Execution Contract Refusal 1 owns it.
Operation 22: A refused resolving write MUST NOT record a field.
Operation 23: IF accepting identity reference EQUALS blank THEN [Accept] MUST answer invalid-request.
Operation 24: IF revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 25: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Deleted: Operation 26. Execution Contract Refusal 1 owns it.
Operation 27: [Decline] MUST NOT accept an acting reference.
Operation 28: An admitted accept MUST stand the invitation in accepted.
Operation 29: An admitted accept MUST record accepting identity reference and now as acceptance instant.
Operation 30: An admitted decline MUST stand the invitation in declined.
Operation 31: An admitted decline MUST record now as declination instant.
Operation 32: An admitted revoke MUST stand the invitation in revoked.
Operation 33: An admitted revoke MUST record revoked by reference, reason as revocation reason and now as revocation instant.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Operation 35: IF the database refuses the write THEN an action MUST answer storage-failure.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Operation 37: A refused action MUST leave the invitation as the call found the invitation.
Operation 38: A refused [Initiate] MUST NOT record an invitation.
Deleted: Operation 39. Operation 37 owns it.
Operation 40: The atom MUST NOT offer an expire action.
Operation 41: An admitted read MUST answer EVERY matching invitation.
Operation 42: An admitted read MUST answer the effective status PER matching invitation.
Operation 43: [Read] MUST NOT record a field.
Operation 44: [Read] MUST NOT refuse a filter.
Deleted: Operation 45. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 46. Execution Contract Logic confinement 3 owns it.
Operation 47: IF a filter names a field whose value EQUALS blank THEN [Read] MUST answer no invitation.
```

NOTE: watch the state a refusal leaves (Operation 37).

Term resolving write: [Accept] | [Decline] | [Revoke] — every write taking a pending invitation to a stored terminal.

Term stored terminal: accepted | declined | revoked.

Term status: pending | accepted | declined | revoked — the value an invitation stores.

Term status check: Operation 15, Operation 16 and Operation 20 — every check a resolving write makes on the invitation's own standing before reading the call's inputs.

Term ttl bounds: the deployment's admitted range for a ttl, the time to live an [Initiate] call supplies for the invitation's window; every admitted value exceeds zero.

Term default ttl: the ttl the deployment declares for an [Initiate] carrying none.

Term expiry bound: (initiation instant + ttl) — the value an admitted initiate records as expiry instant (Execution Contract Logic confinement 9).

Term window reading: live | lapsed — how a pending invitation's window reads against now.

Term live: the window reading of a pending invitation where now PRECEDES the invitation's expiry instant.

Term lapsed: the window reading of a pending invitation where now DOES NOT PRECEDE the invitation's expiry instant; the boundary instant — expiry instant equal to now — reads lapsed.

Term effective status: expired where the invitation reads lapsed, and the stored status otherwise — a projection over the invitation and now, never stored.

Term acting reference: accepting identity reference OR revoked by reference — the reference a write records for who acted.

Term admitted initiate: an [Initiate] call the action admits (Execution Contract Read 4).

Term admitted accept: an [Accept] call the action admits (Execution Contract Read 4).

Term admitted decline: a [Decline] call the action admits (Execution Contract Read 4).

Term admitted revoke: a [Revoke] call the action admits (Execution Contract Read 4).

Term admitted resolving write: an admitted accept, an admitted decline OR an admitted revoke.

Term admitted read: a [Read] call that answers.

Term filter: the selection a [Read] call scopes the answer by — a [Filter] naming invitation token, context, status, accepting identity reference, any combination of them OR no field; an invitation matches a filter when it carries EVERY value the filter names (String 1) and the filter names no other field, so a filter naming no field matches EVERY invitation; consumed per call, never stored.

NOTE: open 2026-10-22-a — [Read] answers the matching invitations in no stated order (Operation 41).

### Invariants

- **Invariant 1 — Initiation immutability.**
  ```
  Invariant 1.1: An admitted resolving write MUST NOT change a property.
  Deleted: Invariant 1.2. State 6 and Operation 16 leave a resolving write no resolution field to find.
  ```
- **Invariant 2 — Single-resolution by write.**
  ```
  Invariant 2.1: An invitation MUST NOT reach two stored terminals.
  Invariant 2.2: An invitation MUST NOT carry two resolution instants.
  ```
- **Invariant 3 — Acceptance binds identity.**
  ```
  Invariant 3.1: EVERY accepted invitation MUST carry a non-blank accepting identity reference.
  Deleted: Invariant 3.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4. Identity 13, State 2 and Operation 6 own the opaque invitee.
  ```
- **Invariant 5 — The stored terminals are structurally distinct.**
  ```
  Invariant 5.1: Two stored terminals MUST NOT carry one resolution field pattern.
  ```
- **Invariant 6 — A refusal names what blocked it.**
  ```
  Invariant 6.1: EVERY already-resolved answer MUST name a stored terminal.
  Invariant 6.2: A lapsed invitation's resolving write MUST answer expired.
  ```
- **Invariant 7 — Expiry deadline immutability.**
  ```
  Invariant 7.1: The atom MUST NOT change an invitation's expiry instant.
  ```
- **Invariant 8 — Revocation attribution completeness.**
  ```
  Invariant 8.1: EVERY revoked invitation MUST carry a non-blank revoked by reference.
  Invariant 8.2: EVERY revoked invitation MUST carry a non-blank revocation reason.
  Invariant 8.3: EVERY revoked invitation MUST carry a revocation instant.
  ```
- **Invariant 9 — Every invitation has a finite lifetime.**
  ```
  Invariant 9.1: EVERY invitation MUST carry an expiry instant.
  ```
- **Invariant 10 — Invitation durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove an invitation from the database.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  ```
- **Invariant 11 — Token uniqueness is database-enforced.**
  ```
  Invariant 11.1: An invitation token MUST resolve to EXACTLY ONE invitation.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when an invitation lapses.
  Invariant 12.2: An admitted read MUST compute the effective status from the invitation's expiry instant and now.
  ```

---

## Examples

### New employee onboarding — accept

`initiate(admin_a7, none, "org:northwind", 7-days)` → `tok_inv_c41`, standing pending. The token reaches the new hire out of band. Three days in, `accept(tok_inv_c41, user_u114)` → accepted, binding `user_u114`. The invitee reference was absent at initiation because the hire had no system identity to name; the identity now recorded is the one the call presenting the token supplied. [External Onboarding](../compositions/external-onboarding.md) proceeds from here to a party record, a credential and a session.

### Workspace collaboration — decline

`initiate(owner_w3, contractor_c9, "workspace:atlas", 14-days)` → `tok_inv_d58`. The contractor declines: `decline(tok_inv_d58)` → declined, stamping declination instant and nothing else. No identity is bound, because nobody joined. The record says a holder of the token saw the invitation and refused — which is a different fact from the window closing unanswered, and the reason declined is a terminal of its own.

### Revoked before use

`initiate(admin_a7, vendor_v2, "org:northwind", 30-days)` → `tok_inv_e5f`. The engagement falls through and `revoke(tok_inv_e5f, admin_a7, "engagement cancelled")` → revoked. A later `accept(tok_inv_e5f, user_u220)` answers `already-resolved(revoked)` — not merely *no*, but *withdrawn, and here is which resolution stands*.

### The window closes

`initiate(admin_a7, none, "org:northwind", 7-days)` → `tok_inv_f77`. Nobody answers. On the eighth day nothing has happened to the record: it still stands pending, carries no resolution field, and read returns it with an effective status of expired. An accept against it answers expired and writes nothing. The eventual difference between this invitation and `tok_inv_d58` above is the whole reason declined is a stored terminal.

### Rejection paths

`accept(tok_unknown, user_u1)` → not-known. `accept(tok_inv_c41, user_u1)` on the already-accepted invitation → `already-resolved(accepted)`. `accept(tok_inv_f77, user_u1)` on the lapsed one → expired. `revoke(tok_inv_c41, admin_a7, "  ")` → `already-resolved(accepted)`, not invalid-request: the status check runs first, and the fact that ends the conversation is that the invitation was accepted (Execution Contract Refusal 1).

### Regulated adversarial scenarios

- **Regulator audit.** *Prove that every user who reached patient records joined through a documented invitation from an authorized administrator.* Filter the database to accepted invitations whose context names that system; each record carries the administrator who invited (inviter reference), when the join committed (acceptance instant) and the identity bound (accepting identity reference). Invariant 3.1 is what makes the last of those never empty, so every current participant traces to one invitation and one administrator.
- **Disputed onboarding.** *I never accepted an invitation — my account was made without me.* Filter by accepting identity reference; the read answers every invitation accepted under that identity — Invariant 2.1 bounds each invitation to one resolution, and no rule bounds how many invitations one identity accepts — and each carries the instant its token was presented. Whether that person or someone holding their token made the call is outside this atom — the record says a bearer presented `tok_inv_e5f6g7` at that instant and supplied that identity, and the composing [Audit Trail](../compositions/audit-trail.md) carries the device, the address and the credential registered alongside.
- **Breach investigation.** Tokens for a high-security context were exposed in a log over a week. Filter by that context, keep the invitations whose initiation instant falls inside that week, and read each effective status against the investigation clock: the accepted ones are cross-checked against known staff, the still-live ones are revoked at once, and the lapsed ones need nothing — no write ever fired against them and an accept would answer expired. Invariant 5.1 and Invariant 12.2 are what make that triage possible from the database and a clock alone.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the invitation records, with their committed versions (Execution Contract Generation acceptance 1), and the read-time clock.

### Conformance checks

```
Check 1.1: An auditor MUST find no invitation carrying two resolution instants (Invariant 2.2).
Check 1.2: An auditor MUST find EXACTLY ONE resolution instant on EVERY invitation whose status IS IN the stored terminals (State 3 through 5).
Check 1.3: An auditor MUST find no resolution field on a pending invitation (State 6).
Check 2.1: An auditor MUST find no invitation storing expired as a status (State 7).
Deleted: Check 2.2. Invariant 12.1 owns it.
Check 2.3: An auditor MUST reproduce an admitted read's effective status from the invitation's expiry instant and a clock the auditor supplies (Invariant 12.2).
Check 3.1: An auditor MUST find a non-blank accepting identity reference on EVERY accepted invitation (Invariant 3.1).
Check 3.2: An auditor MUST find an acceptance instant on EVERY accepted invitation (State 3).
Check 4.1: An auditor MUST find no two stored terminals carrying one resolution field pattern (Invariant 5.1).
Check 5.1: An auditor MUST find a non-blank revoked by reference on EVERY revoked invitation (Invariant 8.1).
Check 5.2: An auditor MUST find a non-blank revocation reason on EVERY revoked invitation (Invariant 8.2).
Check 5.3: An auditor MUST find a revocation instant on EVERY revoked invitation (Invariant 8.3).
Check 6.1: An auditor MUST find an expiry instant on EVERY invitation (Invariant 9.1).
Check 6.2: An auditor MUST find EVERY invitation's expiry instant unchanged across EVERY committed version of the invitation (Invariant 7.1; Execution Contract Generation acceptance 1).
Check 7.1: An auditor MUST find no invitation token on two invitations (Identity 5, Invariant 11.1).
Check 7.2: An auditor MUST find EVERY invitation's properties unchanged across EVERY committed version of the invitation (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 8.1: An auditor MUST find an unfiltered read answering EVERY invitation with a committed version (State 13, Invariant 10.1; Execution Contract Generation acceptance 1).
Deleted: Check 8.2. Check 8.1 owns it.
Check 9.1: An auditor MUST reconstruct EVERY invitation of one context from the database (State 1, State 13, Invariant 10.1).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

### External checks

```
External check 1: A deployment needing an already-resolved answer's payload confirmed MUST read the caller's record of the answer (Non-goal 22).
External check 2: A deployment needing an accepting identity reference matched to the invitee MUST read the composing pattern's own rule (Identity 13, Non-goal 10).
External check 3: A deployment needing the inviter's authority confirmed MUST read the composing policy layer (Non-goal 6).
External check 4: A deployment needing the token's delivery to the invitee confirmed MUST read the delivery channel (Non-goal 4).
External check 5: A deployment needing a declining actor identified MUST read the composing pattern's own record (Operation 27, Non-goal 12).
External check 6: A deployment needing the database confirmed free of a retroactive edit MUST read the composing Tamper Evidence (Non-goal 20).
External check 7: A deployment needing the accepting party's real-world identity confirmed MUST read the composing Party Identity proofing (Non-goal 18).
```

---

## Non-goals

```
Non-goal 1: The atom MUST NOT create an identity record for an accepted invitation.
Non-goal 2: A deployment needing an identity record MUST compose Party Identity.
Non-goal 3: The atom MUST NOT register a credential.
Non-goal 4: The atom MUST NOT deliver the invitation token.
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
Non-goal 19: The atom MUST NOT detect a rewrite under the database.
Non-goal 20: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 21: The atom MUST NOT bound an invitation's retention.
Non-goal 22: The atom MUST NOT record an answer the atom gave.
Non-goal 23: The atom MUST NOT decide whether a token holder may pass the token on.
Non-goal 24: The atom MUST NOT guarantee that an invitation resolves.
Non-goal 25: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 26: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
Non-goal 27: The atom MUST NOT decide who may call an action.
Non-goal 28: A deployment needing a retention bound MUST compose Retention Window.
```

NOTE: the owners — [Capability](./capability.md) (Non-goal 11, Non-goal 23, Composition note 9); the composing pattern (Non-goal 12, External check 5).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

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

NOTE: watch host obligations — this atom sets no maximum length on a string input and does not oblige the deployment to set one, which is the *input-handling regime* docket row's silence posture.

---

## Composition notes

```
Composition note 1: A composing External Onboarding MUST create the party record ONLY AFTER an admitted accept.
Composition note 2: A composing External Onboarding MUST record the accepting identity reference beside the party record's id on the onboarding's completion record.
Composition note 3: A composing External Onboarding MUST register the credential against the party record the accepted invitation's onboarding enrolled.
Composition note 4: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 5: A composing Event Log MUST append an event on EVERY refused action.
Composition note 6: A composing Actor Identity MUST attest the actor behind an admitted accept.
Composition note 7: A composing Actor Identity MUST attest the actor behind an admitted initiate.
Composition note 8: A composing Tamper Evidence MUST cover EVERY reference the database holds.
Composition note 9: A composing Capability MUST call [Initiate] PER redemption.
```

NOTE: open 2026-10-22-c — whether a composing Actor Identity attests the actor behind an admitted revoke is not stated; Composition note 6 and Composition note 7 attest the actors behind an admitted accept and an admitted initiate.

NOTE: composing patterns — [External Onboarding](../compositions/external-onboarding.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the database; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a reader; an invitation; a pending invitation; an accepted invitation; a declined invitation; a revoked invitation; a lapsed invitation; an action; a resolving write; a refused action; an answer; a token holder; an opaque reference; a string input; a filter; the database instance's invitation count.

Term records: invitation — one invitation issued by one inviter to join one context, carrying invitation token, inviter reference, context, initiation instant, expiry instant, a status and, where supplied or set, invitee reference, accepting identity reference, acceptance instant, declination instant, revoked by reference, revocation reason and revocation instant.

Term record verbs: identify, assign, generate, change, share, reuse, carry, stand, read, answer, record, leave, admit, offer, hold, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, deliver, declare, compose, remove, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, draw, verify, sequence, issue, detect, guarantee, take, store.

Term value sets: status = pending | accepted | declined | revoked. effective status = pending | accepted | declined | revoked | expired. stored terminal = accepted | declined | revoked. window reading = live | lapsed. property = inviter reference | invitee reference | context | initiation instant | expiry instant. resolution field = accepting identity reference | acceptance instant | declination instant | revocation instant | revoked by reference | revocation reason.

Term bounds: ttl bounds, default ttl, expiry bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: invitation, invitation token, property, reference, database instance, seam, transition, now, resolving write, stored terminal, status, status check, ttl bounds, default ttl, expiry bound, window reading, live, lapsed, effective status, acting reference, admitted initiate, admitted accept, admitted decline, admitted revoke, admitted resolving write, admitted read, filter, resolution field, resolution instant, committed version, string input, blank.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Party Identity](./party-identity.md), [Credential](./credential.md), [Session](./session.md), [Actor Identity](./actor-identity.md), [Event Log](./event-log.md), [Tamper Evidence](./tamper-evidence.md), [Capability](./capability.md), [Retention Window](./retention-window.md), [External Onboarding](../compositions/external-onboarding.md).

Term resolution instant: acceptance instant | declination instant | revocation instant.

#### Initiate

The behavior that records a new [Invitation] — assigning a fresh [Invitation Token] from the token material the seam supplies, setting [Inviter Reference], an optional [Invitee Reference], [Context], [Initiation Instant] and [Expiry Instant], standing the record in [Pending], and answering the token. Rejected [Invalid Request] or [Storage Failure].

Kind: Operation

#### Accept

The resolving write that binds an identity to the invitation, standing it in [Accepted] and recording [Accepting Identity Reference] and [Acceptance Instant]. Legal only while the invitation stands in [Pending] and reads live. Rejected [Not Known], [Already Resolved], [Expired Rejection], [Invalid Request] or [Storage Failure].

Kind: Operation

#### Decline

The resolving write that records a deliberate refusal, standing the invitation in [Declined] and stamping [Declination Instant]. Takes no acting reference: the refusal is recorded, the refuser is not. Legal only while the invitation stands in [Pending] and reads live.

Kind: Operation

#### Revoke

The resolving write by which the inviting side withdraws the invitation, standing it in [Revoked] and recording [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Legal only while the invitation stands in [Pending] and reads live; a lapsed invitation needs no withdrawal, since it already reads [Expired].

Kind: Operation

#### Read

The read-only query answering the [Invitation] records a [Filter] matches, each carrying its stored fields and its derived [Effective Status]. Refuses nothing — a filter matching no invitation has a correct answer rather than an error.

Kind: Operation

#### Invitation

The record this atom defines: one invitation, issued by one inviter to join one context, resolved by at most one write. Carries [Invitation Token], [Inviter Reference], an optional [Invitee Reference], [Context], [Initiation Instant], [Expiry Instant], [Status], and the resolution fields of whichever write settled it.

Kind: Type
Projection: status

#### Invitation Token

The opaque, immutable identity of an [Invitation] and the bearer credential a holder presents. Assigned on [Initiate] from the token material the seam supplies, drawn from a cryptographically random source, and unique by the database's refusal of a colliding write rather than by probability.

Kind:       Field
Field of:   Invitation
Projection: invitation_token

#### Inviter Reference

The opaque reference naming who issued the invitation. Required, set on [Initiate], immutable thereafter. The atom does not confirm it names a known actor, nor that the actor was authorized to invite.

Kind:       Field
Field of:   Invitation
Projection: inviter_ref

#### Invitee Reference

The opaque reference naming the intended recipient. **Optional** — an invitation is very often addressed to someone with no system identity yet, which is the case this atom exists to serve. Never validated, and never matched against [Accepting Identity Reference].

Kind:       Field
Field of:   Invitation
Projection: invitee_ref

#### Context

The opaque descriptor of what the invitee is being invited to join — an organization, a workspace, a role. Required, immutable, and interpreted by the composing pattern rather than here.

Kind:       Field
Field of:   Invitation
Projection: context

#### Initiation Instant

The instant the invitation was issued, stamped from [Now] on [Initiate]. Immutable.

Kind:       Field
Field of:   Invitation
Projection: initiated_at

#### Expiry Instant

The instant the window closes, recorded on [Initiate] as the expiry bound. Immutable, never absent, and the sole stored input the derived [Effective Status] needs.

Kind:       Field
Field of:   Invitation
Projection: expires_at

#### Status

The stored status of an [Invitation] — [Pending], [Accepted], [Declined] or [Revoked]. [Expired] is not a value of this field; it appears only in the derived [Effective Status].

Kind:       Field
Field of:   Invitation
Projection: status

#### Accepting Identity Reference

The identity bound at acceptance — the record of who joined. Recorded on [Accept], never absent on an [Accepted] invitation, immutable once set.

Kind:       Field
Field of:   Invitation
Projection: accepting_identity_ref

#### Acceptance Instant

The instant the acceptance committed, stamped from [Now] on [Accept]. Present only in [Accepted]; immutable once set.

Kind:       Field
Field of:   Invitation
Projection: accepted_at

#### Declination Instant

The instant the refusal was recorded, stamped from [Now] on [Decline]. Present only in [Declined]; immutable once set. It is the whole of what a decline records.

Kind:       Field
Field of:   Invitation
Projection: declined_at

#### Revocation Instant

The instant the withdrawal was recorded, stamped from [Now] on [Revoke]. Present only in [Revoked]; immutable once set.

Kind:       Field
Field of:   Invitation
Projection: revoked_at

#### Revoked By Reference

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

The window length supplied to [Initiate]. Optional — an absent one takes the deployment's declared default. It sizes the window and is not stored under its own name; [Initiation Instant] and [Expiry Instant] are what persist.

Kind:         Parameter
Parameter of: Initiate
Projection:   ttl

#### Reason

The withdrawal reason supplied to [Revoke], recorded as [Revocation Reason]. Required and never blank.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller. Consumed by every action: by [Initiate]'s stamp, by a resolving write's window reading and stamp, and by [Read]'s [Effective Status] projection.

Kind:         Parameter
Parameter of: Initiate, Accept, Decline, Revoke and Read
Projection:   now

#### Filter

The selection a caller passes to [Read] to scope which invitation records are returned: any combination of an [Invitation Token], a [Context], a [Status] and an [Accepting Identity Reference], or none. An invitation matches when it carries every value the filter names, and a filter naming no field matches every invitation; a filter naming a blank value, or any other field, matches none. A status filter reads the stored [Status], never the derived [Effective Status], which [Read] answers on every match. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   filter

#### Pending

The one non-terminal status: the invitation is issued and unresolved. Reads live or lapsed against [Now], and a lapsed pending invitation is what [Effective Status] answers as [Expired].

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Accepted

The stored terminal reached when an identity was bound. Carries [Accepting Identity Reference] and [Acceptance Instant]. Absorbing.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Declined

The stored terminal reached when a token holder deliberately refused. Carries [Declination Instant] alone. Absorbing, and distinct from a window that simply closed — which is the distinction that justifies this atom beside [Capability](./capability.md).

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Revoked

The stored terminal reached when the inviting side withdrew the invitation. Carries [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Absorbing.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Expired

The derived status of a [Pending] invitation whose window has closed. Never stored, carried by no field, and reached by no write — it is the value [Effective Status] computes from [Expiry Instant] and [Now]. The refusal a resolving write against such an invitation receives is [Expired Rejection]: the same word, a different value set, and the reason Operation 18 forbids it appearing as an already-resolved payload.

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

The refusal any action returns when the database refuses the write after every precondition passes — including the database's refusal of a colliding [Invitation Token]. No invitation is recorded, or the invitation remains [Pending].

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
[Inviter Reference]: #inviter-reference
[Invitee Reference]: #invitee-reference
[Context]: #context
[Initiation Instant]: #initiation-instant
[Expiry Instant]: #expiry-instant
[Status]: #status
[Accepting Identity Reference]: #accepting-identity-reference
[Acceptance Instant]: #acceptance-instant
[Declination Instant]: #declination-instant
[Revocation Instant]: #revocation-instant
[Revoked By Reference]: #revoked-by-reference
[Revocation Reason]: #revocation-reason
[Effective Status]: #effective-status
[TTL]: #ttl
[Reason]: #reason
[Now]: #now
[Filter]: #filter
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

- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Articles 6 and 7 (lawful basis and consent)** — [Initiate] creates a processing record: the system now holds an [Invitee Reference] and will process data about the invitee if they accept. [Initiation Instant] and [Inviter Reference] are the processing-event record; [Accepting Identity Reference] bound at [Accept] is the record of the data subject's active engagement.
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(a)(1) (access control)** — invitation-based provisioning is a covered access-granting mechanism. [Inviter Reference] is the authorized administrator who granted access and [Accepting Identity Reference] is the identity that gained it.
- **SCIM 2.0 (System for Cross-domain Identity Management) RFC 7644 (RFC — Request for Comments, the Internet's numbered standards series)** — SCIM's `POST /Users` with an invite flow maps to the Invitation → [External Onboarding](../compositions/external-onboarding.md) arc. [Invitee Reference] corresponds to the external identity reference; [Accepting Identity Reference] to the provisioned user id.
- **SOC 2 (Service Organization Control 2 — an audit standard for service-provider security controls) CC6.2 (users registered and authorized before credentials are issued)** — the invitation record *is* the registration and authorization event. [Inviter Reference] is the authorizing party; [Acceptance Instant] and [Accepting Identity Reference] are the registration.
- **NIST (National Institute of Standards and Technology) SP (Special Publication) 800-63A (enrollment and identity proofing)** — the enrollment event maps to the Invitation → accept arc. This atom models the enrollment record; proofing is [Party Identity](./party-identity.md)'s (Non-goal 17, Non-goal 18).

Standards anchoring here is lighter than for [Credential](./credential.md), [Session](./session.md) or [Capability](./capability.md), and deliberately so: this atom earns its place on EOS Pass 2 conceptual independence rather than on regulatory surface — the declined terminal, single-resolution by write, and identity binding at acceptance are what make it a separate atom instead of a fold into Capability.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; separating an invitation's lifecycle record from the provisioning that follows acceptance.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — invitation.tla + 2 twins, 2026-06-03
last gate: 2026-10-28 — Final Critique 7 — foundational count 2, not clean, no sample

open:
- 2026-10-22-a · refining · [Read]; Operation 41 · [Read] answers the matching invitations in no stated order, so a caller paging the answer gets the database's (the Watch list's read-order polarity names this page's Operation 41 as one posture) → state an order, or declare none
- 2026-10-22-c · refining · Composition note 6; Composition note 7 · a composing Actor Identity attests the actor behind an admitted accept and behind an admitted initiate, and no note says whether it attests the actor behind an admitted revoke, which records a revoked by reference as an accept records an accepting identity reference → wire the revoke's attestation, or name the deployment as its owner
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/invitation.md`; the migration that got it here is in [its history](./invitation.hist.md).

- **2026-10-22 — An admitted call is the Execution Contract's.** *Chose:* the four admitted terms (initiate, accept, decline, revoke) citing Execution Contract Read 4 for what an action admits, in place of the commit clause each carried, so the admitted resolving write they make up reads as before; Read 4 cited on Capability requirement 12; the rule count stays at 156. *Over:* the page stating for itself which calls its effect rules reach. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the admitted effect among them, which seven atoms had written in one form, this page among them. What each action does and answers is unchanged.

- **2026-10-22 — A lapse is never written, so nothing forbids the deadline; a refused write leaves what it found; one identity may accept more than one invitation.** *Chose:* State 8 and Check 2.2 deleted to Invariant 12.1, under which the atom writes no field when an invitation lapses, with the State WHY naming State 7 and Invariant 12.1; Operation 39 deleted to Operation 37, a refused action leaving the invitation as the call found it; the Disputed onboarding scenario answering every invitation an identity accepted; Non-goal 27, the atom deciding no caller's authority; Operation 3 checking only a supplied ttl, and Capability requirement 4 obliging a default ttl inside the ttl bounds; Operation 10 recording an invitee reference only where one is not blank; the window readings compared with PRECEDES. *Over:* the noun-final pass's rename of `expires_at` to *expiry instant*, the noun State 8 and Check 2.2 had used for a recorded lapse, so that both forbade what State 1 and Check 6.1 require; a rule leaving every refused resolving write's invitation in pending, which an already-resolved refusal cannot; and a scenario reading Invariant 2.1, a bound on one invitation's terminals, as at most one resolved invitation per identity. *Because:* Final Critique 6 found each, and Final Critique 5's text decided the direction: no invitation record carries a stored expired status or an `expired_at` field, and no field is written when an invitation lapses; a refused write leaves the record as it stood; and its rules, like this page's, bound one invitation's resolution and not how many invitations one identity accepts, which its scenario misread the same way. Smaller fixes rode with it, none changing what a rule means: the Summary glosses a bearer token, and the Intent, Term ttl bounds and the Standards references their acronyms; Term invitation and the Invitation entry say resolved by at most one write again; Term value sets declares the effective status; the Now entry names every action that consumes now; Check 1.2 cites a range; and the New employee onboarding example says the record holds the identity the call supplied. Three questions no rule decides are open (2026-10-22-a through c). What each action answers on a well-formed call is unchanged; a blank ttl now reads the default without meeting the bounds check, and a whitespace-only invitee reference is no longer recorded.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each refuses line kept as the page wrote it, already in the page's order — a resolving write answering not-known, already-resolved, expired, then invalid-request once every status check passes, and storage-failure last, answering only at the write — and the order cited from the Execution Contract (Capability requirement 12, Execution Contract Refusal 1); the pairs that only stated it deleted to Refusal 1: Operation 19 (already-resolved only for a token naming an invitation), Operation 21 (expired only on a pending invitation), Operation 26 (invalid-request only once every status check passes) and Operation 36 (storage-failure behind every precondition); rules 162 to 158. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the invitation store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the eleven rules that restated them tombstoned to their owner — Operation 34 and Invariant 3.2, a resolving write's status change and recorded fields committed in one transition, Invariant 10.2, no partial invitation on storage-failure, and Atomic writes 1, 3 and 4, a transition committed whole inside the implementation's transactional boundary and no repair of a dangling one, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Capability requirement 7, a write acknowledged only once it commits, to Store 3; Concurrency 1, the status check and the status change of a resolving write as one operation, to Store 1 and Store 2; Concurrency 2 and 3, the losing resolving write answering already-resolved and naming the stored terminal the winner committed, to Store 2; rules 172 to 162. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. Single-resolution stays the atom's own (Invariant 2.1, Invariant 2.2, Operation 16, Operation 17), as do the store refusing a write carrying a token it holds (Capability requirement 6, Identity 6), a refused write recording nothing and leaving the invitation as the call found it (Operation 22, Operation 37 through 39), and the invitations the atom never removes and the count that never falls (State 13, Invariant 10.1). The effective status is a projection over the expiry instant each invitation carries and now (Invariant 12.2), every check that compares reads compares the auditor's own reads, and no rule orders two invitations' writes, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.
- **2026-09-13 — Single-resolution is stated as at-most-one, and the at-least-one half is `Non-goal 24`.** *Chose:* `Invariant 2.1` and `Invariant 2.2` alone. *Over:* a rule reading *exactly one write resolves an invitation*. *Because:* an invitation nobody answers is never written and reads expired forever, which is the designed outcome and not a stuck state — so *at least one* would be false here rather than merely unenforceable. Same decomposition [Provisional Commitment](./provisional-commitment.md) took, reached from the opposite direction.
- **2026-06-21 — Expiry is derived at read time, never stored; this atom is the corpus's worked reference for the move.** *Chose:* the stored `Expired` state, the `expired_at` field and the `expire` action are removed; `Expired` is a read-time projection over the immutable expiry instant and the injected clock. *Over:* a stored terminal a scheduler or a lazy write has to reach. *Because:* an invitation's lapse is side-effect-free, so a status that can be inferred at read time should be, and a flag that lags the clock is the idealization pitfall the methodology names. [Provisional Commitment](./provisional-commitment.md)'s 2026-06-23 entry is the boundary from the other side: its lapse returns a resource, so its expiry stays a written transition.

</details>

NOTE: End of Invitation.

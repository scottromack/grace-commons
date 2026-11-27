---
title: Invitation
id: 42
audience: common
---

# Invitation

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Invitation tracks the life of an invitation issued to an outside party — a new employee, a customer, a collaborator, a patient — before that party has an identity in the system, and answers *what is the state of this invitation, and who accepted it?* Each invitation is identified by a random token the invitee presents to act on it, and starts pending. The guarantee is that it resolves at most once, by one recorded change of state, a write, to one of three end states: accepted (recording the identity that joined, which the pattern never changes or deletes), declined (a deliberate refusal, recorded as its own outcome and distinct from never using the invitation) or revoked (the inviter withdrew it, or the list it is to ended). If the window simply passes, the invitation *reads* expired — a status computed from the deadline and the clock, never written. Any later write is told which resolution stands, or that the invitation expired, and of two people accepting at once one wins and the other is told. The credential setup, identity record and login that usually follow acceptance are separate patterns. An invitation is to one list, issued by one actor and accepted by one actor, each named by its actor id; that accepting grants access to the list is the app's glue line, not this atom's rule.

<details markdown="block">
<summary>WHY</summary>

Systems that admit external parties face one structural problem: the invitation must be issued before the invitee's system identity exists, yet acceptance is the moment that identity must be established. The invitation is the bridge, and it carries the whole arc — who invited whom, when, whether the invitee answered, and at acceptance which identity was bound.

This atom isolates that record from the machinery around it. It does not register the credential that follows acceptance, create the identity record the accepted invitee becomes, issue the session, or sequence those steps; each is another pattern's, which the app chooses. It answers one question, from the invitation record alone.

The declined terminal is what separates Invitation from a bearer capability at the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) Pass 2 boundary. Both use bearer-token transport (whoever holds the token can use it), both are time-bounded, both can be revoked. The difference is that the declined outcome is one the atom records — an instant stamped when a holder deliberately declined, distinct from a token never presented; who declined is the composing pattern's to record, not this atom's (Non-goal 12, External check 5). A capability's bearer either redeems it or does not, and the non-use is not an outcome the system records.

This is a freestanding atom in the EOS sense: its own state, its own five writes and one read, and its own operational principles — single-resolution, expiry-is-derived, opaque invitee at initiation, identity binding at acceptance.

</details>

## What it keeps

### The invitations

Term invitation: the record this atom holds — one invitation issued by one inviter to join one context, resolved by at most one write.

#### Invitation

The record this atom defines: one invitation, issued by one inviter to join one context, resolved by at most one write. Carries [Invitation Token], [Inviter Reference], an optional [Invitee Reference], [Context], [Initiation Instant], [Expiry Instant], [Status], and the resolution fields of whichever write settled it.

Kind: Type
Projection: status

```
Identity 1: The atom MUST identify an invitation by the token digest.
Identity 2: The atom MUST assign the token material the seam supplies as the invitation token, unchanged.
Identity 3: The atom MUST NOT generate an invitation token.
Identity 4: The atom MUST NOT change an invitation's token digest.
Identity 5: Two invitations MUST NOT share a token digest.
Identity 6: IF the database refuses an [Initiate] write for a token digest the database holds (Capability requirement 6) THEN [Initiate] MUST answer storage-failure.
Identity 7: The atom MUST NOT identify an invitation by a property.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference beyond the canonical form the seam gives the reference (Execution Contract Logic confinement 13).
Identity 10: The atom MUST NOT confirm that an inviter reference names a known actor.
Identity 11: The atom MUST NOT confirm that an invitee reference names a known actor.
Identity 12: The atom MUST NOT confirm that an accepting identity reference names a known identity.
Identity 13: The atom MUST NOT match an accepting identity reference against an invitee reference.
```

Term invitation token: the opaque value naming one invitation — an [Invitation Token]; assigned from the token material the seam supplies, and the bearer credential a holder presents; the record carries its token digest in its place (State 14).

#### Invitation Token

The opaque bearer credential a holder presents, naming one [Invitation] through its token digest; answered on [Initiate] and never stored (State 14). Assigned on [Initiate] from the token material the seam supplies, drawn from a cryptographically random source, and unique by the database's refusal of a colliding write rather than by probability.

Kind:       Field
Field of:   Invitation
Projection: invitation_token

Term token material: the random value the deployment draws from a cryptographically random source (Capability requirement 3) and supplies at the seam for one admitted initiate; the atom answers that value, unchanged, as the invitation token.

Term token digest: the digest of an invitation token, computed at the seam (Execution Contract Logic confinement 8); the record carries it in place of the token and every rule that keys, compares or refuses by the invitation token reads it, so no stored field and no answer of a read is the live bearer credential (Execution Contract Logic confinement 21).

Term property: inviter reference | invitee reference | context | initiation instant | expiry instant — what an invitation carries from initiation that is not the invitation's identity.

Term reference: invitation token, inviter reference, invitee reference, accepting identity reference OR revoked by reference — every opaque reference this atom records.

Term database instance: one named database a call is routed to; token digest uniqueness ranges over one instance.

#### Inviter Reference

The actor id naming who issued the invitation. Required, set on [Initiate], immutable thereafter. The atom does not confirm it names a known actor, nor that the actor was authorized to invite.

Kind:       Field
Field of:   Invitation
Projection: inviter_ref

#### Invitee Reference

The opaque reference naming the intended recipient. **Optional** — an invitation is very often addressed to someone with no system identity yet, which is the case this atom exists to serve. Never validated, and never matched against [Accepting Identity Reference].

Kind:       Field
Field of:   Invitation
Projection: invitee_ref

#### Context

The list id naming the list the invitee is being invited to join. Required, immutable, and read by the app rather than here.

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

Term status: pending | accepted | declined | revoked — the value an invitation stores.

Term stored terminal: accepted | declined | revoked.

#### Status

The stored status of an [Invitation] — [Pending], [Accepted], [Declined] or [Revoked]. [Expired] is not a value of this field; it appears only in the derived [Effective Status].

Kind:       Field
Field of:   Invitation
Projection: status

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

The stored terminal reached when a token holder deliberately refused. Carries [Declination Instant] and no other resolution field. Absorbing, and distinct from a window that simply closed — which is the distinction that justifies this atom beside a bearer capability.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Revoked

The stored terminal reached when the inviting side withdrew the invitation. Carries [Revocation Instant], with [Revoked By Reference] and [Revocation Reason] where [Revoke] reached it and neither where [Revoke List Invitations] reached it when the list ended. Absorbing.

Kind:      Member
Member of: the invitation status
Role:      Outcome

#### Accepting Identity Reference

The actor id bound at acceptance — the record of who joined. Recorded on [Accept], never absent on an [Accepted] invitation, immutable once set.

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

The instant the withdrawal was recorded, stamped from [Now] on [Revoke] or [Revoke List Invitations]. Present only in [Revoked]; immutable once set.

Kind:       Field
Field of:   Invitation
Projection: revoked_at

#### Revoked By Reference

The opaque reference naming who withdrew the invitation. Required on [Revoke], never blank on an invitation [Revoke] stood in [Revoked], and never recorded by [Revoke List Invitations], whose call names no actor.

Kind:       Field
Field of:   Invitation
Projection: revoked_by_ref

#### Revocation Reason

The caller-supplied [Reason] for the withdrawal. Required on [Revoke] and never blank, because withdrawal is the one resolution taken against the invitee rather than by them. Never recorded by [Revoke List Invitations], whose call carries no reason.

Kind:       Field
Field of:   Invitation
Projection: revocation_reason

Term resolution field: accepting identity reference | acceptance instant | declination instant | revocation instant | revoked by reference | revocation reason — every field a resolving write records.

Term resolution instant: acceptance instant | declination instant | revocation instant.

Term effective status: expired where a pending invitation reads lapsed, and the stored status otherwise — a projection over the invitation and now, never stored.

#### Effective Status

The status a [Read] answers: [Expired] where the invitation reads lapsed, and the stored [Status] otherwise. A projection over the invitation and [Now] — computed at read time, never stored, and the only surface on which [Expired] appears.

Kind:       Field
Field of:   Invitation
Projection: effective_status

#### Expired

The derived status of a [Pending] invitation whose window has closed. Never stored, carried by no field, and reached by no write — it is the value [Effective Status] computes from [Expiry Instant] and [Now]. The refusal a resolving write against such an invitation receives is [Expired Rejection]: the same word, a different value set, and the reason Operation 18 forbids it appearing as an already-resolved payload.

Kind:      Member
Member of: the effective status
Role:      Outcome

Term window reading: live | lapsed — how a pending invitation's window reads against now.

Term live: the window reading of a pending invitation where now PRECEDES the invitation's expiry instant.

Term lapsed: the window reading of a pending invitation where now DOES NOT PRECEDE the invitation's expiry instant; the boundary instant — expiry instant equal to now — reads lapsed.

```
State 1: EVERY invitation MUST carry token digest, inviter reference, context, initiation instant, expiry instant and a status.
State 2: An invitation MAY carry an invitee reference.
State 3: EVERY accepted invitation MUST carry accepting identity reference and acceptance instant.
State 4: EVERY declined invitation MUST carry declination instant.
State 5: EVERY invitation an admitted revoke stood in revoked MUST carry revoked by reference, revocation reason and revocation instant.
State 6: A pending invitation MUST NOT carry a resolution field.
State 7: The atom MUST NOT store expired as a status.
State 9: The atom MUST NOT record the ttl under the ttl's own name.
State 10: The atom MUST NOT offer a re-open surface.
State 11: The atom MUST NOT offer a window extension surface.
State 12: The atom MUST NOT offer an invitation removal surface.
State 14: The atom MUST NOT store the invitation token.
State 15: EVERY invitation [Revoke List Invitations] stood in revoked MUST carry revocation instant as the invitation's one resolution field.
```

<details markdown="block">
<summary>WHY</summary>

State 7 and Invariant 12.1 are the derived-expiry posture, and they are two rules rather than one because an implementation can breach each without the other: a stored expired status, and an `expired_at` column written beside a status that stays pending.

</details>

## What people do

### Every action

```
Operation 15: IF the token digest of the call names no invitation THEN a resolving write MUST answer not-known.
Operation 16: IF the invitation's status IS IN the stored terminals THEN a resolving write MUST answer already-resolved.
Operation 17: A resolving write answering already-resolved MUST name the invitation's status.
Operation 18: A resolving write MUST NOT name expired as a stored terminal.
Operation 20: IF the invitation reads lapsed THEN a resolving write MUST answer expired.
Operation 35: IF the database refuses the write THEN an action MUST answer storage-failure.
Operation 40: The atom MUST NOT offer an expire action.
Operation 52: [Initiate], [Accept], [Decline] AND [Revoke] MUST append one invitation events record through the atom's journal need for EVERY admitted call.
```

NOTE: watch the cap's refusal (Operation 49, Operation 50, Operation 51).

Term resolving write: [Accept] | [Decline] | [Revoke] — every write taking one pending invitation, named by its token, to a stored terminal.

Term status check: Operation 15, Operation 16 and Operation 20 — every check a resolving write makes on the invitation's own standing before reading any input of the call but the invitation token.

Term admitted resolving write: an admitted accept, an admitted decline OR an admitted revoke.

Term acting reference: accepting identity reference OR revoked by reference — the reference a write records for the actor the caller names, which the atom attests no more than it attests an invitee (Non-goal 15).

#### Invalid Request

The refusal returned when a required argument is blank, or a supplied [TTL] (time to live) is malformed or falls outside the ttl bounds, or no default ttl is declared, or a string input to an action that lists this refusal exceeds the string cap (Operation 49, Operation 50, Operation 51, Execution Contract Input 2). On a resolving write it is reached only after every status check passes (Execution Contract Refusal 1).

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

The refusal any action returns when the database refuses the write after every precondition passes — including the database's refusal of a colliding [Invitation Token] and the journal's refusal of the append of Operation 52 or Operation 59 (Execution Contract Constituent failure 1). No invitation is recorded, or the invitation, or each invitation [Revoke List Invitations] would revoke, remains [Pending].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Initiate

The behavior that records a new [Invitation] — assigning a fresh [Invitation Token] from the token material the seam supplies, setting [Inviter Reference], an optional [Invitee Reference], [Context], [Initiation Instant] and [Expiry Instant], standing the record in [Pending], and answering the token. Rejected [Invalid Request] or [Storage Failure].

Kind: Operation

```
initiate(inviter_ref, optional invitee_ref, context, optional ttl)
  answers invitation_token
  refuses invalid-request | storage-failure
```

```
Operation 1: IF inviter reference EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 2: IF context EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 3: IF ttl DOES NOT EQUAL blank AND the ttl IS NOT IN the ttl bounds THEN [Initiate] MUST answer invalid-request.
Operation 4: IF ttl EQUALS blank THEN [Initiate] MUST read the default ttl as the ttl.
Operation 5: IF the default ttl EQUALS blank THEN [Initiate] MUST answer invalid-request.
Operation 6: [Initiate] MUST NOT answer invalid-request on an absent invitee reference.
Operation 7: [Initiate] MUST NOT answer not-known.
Operation 8: An admitted initiate MUST assign a fresh invitation token, one whose token digest no invitation of the database instance holds (Identity 5).
Operation 9: An admitted initiate MUST record inviter reference and context.
Operation 10: IF invitee reference DOES NOT EQUAL blank THEN an admitted initiate MUST record invitee reference.
Operation 11: An admitted initiate MUST record now as initiation instant.
Operation 12: An admitted initiate MUST record the expiry bound as expiry instant.
Operation 13: An admitted initiate MUST stand the invitation in pending.
Operation 14: An admitted initiate MUST answer the invitation token.
Operation 48: IF a supplied ttl is malformed THEN [Initiate] MUST answer invalid-request (Execution Contract Input 1).
Operation 49: IF a string input EXCEEDS the string cap THEN [Initiate] MUST answer invalid-request (Execution Contract Input 2).
```

NOTE: watch the blank optional input (Operation 10).

NOTE: watch the untyped input (Operation 48, Term window length).

Term admitted initiate: an [Initiate] call the action admits (Execution Contract Read 4).

Term window length: a whole number of seconds — what a ttl, the default ttl and the ttl bounds carry.

Term expiry bound: (initiation instant + ttl) — the value an admitted initiate records as expiry instant (Execution Contract Logic confinement 9).

#### TTL

The window length supplied to [Initiate], a whole number of seconds. Optional — an absent one takes the deployment's declared default. It sizes the window and is not stored under its own name; [Initiation Instant] and [Expiry Instant] are what persist.

Kind:         Parameter
Parameter of: Initiate
Projection:   ttl

`initiate(admin_a7, none, "org:northwind", 604800)` commits `tok_inv_g20`, and the answer never reaches the caller, who cannot tell whether the call landed. The caller's retry is a second call, which the atom admits as it did the first and answers with a fresh token, `tok_inv_h31` (Operation 8). Two pending invitations now stand where the caller meant one, and nothing in the atom links them; what a caller does after a lost answer is the composing pattern's (Execution Contract Error model 1).

### Accept

The resolving write that binds an identity to the invitation, standing it in [Accepted] and recording [Accepting Identity Reference] and [Acceptance Instant]. Legal only while the invitation stands in [Pending] and reads live. Rejected [Not Known], [Already Resolved], [Expired Rejection], [Invalid Request] or [Storage Failure].

Kind: Operation

```
accept(invitation_token, accepting_identity_ref)
  answers accepted
  refuses not-known | already-resolved(stored terminal) | expired | invalid-request | storage-failure
```

```
Operation 23: IF accepting identity reference EQUALS blank THEN [Accept] MUST answer invalid-request.
Operation 28: An admitted accept MUST stand the invitation in accepted.
Operation 29: An admitted accept MUST record accepting identity reference and now as acceptance instant.
Operation 50: IF a string input EXCEEDS the string cap THEN [Accept] MUST answer invalid-request (Execution Contract Input 2).
```

Term admitted accept: an [Accept] call the action admits (Execution Contract Read 4).

`accept(tok_unknown, user_u1)` → not-known. `accept(tok_inv_c41, user_u1)` on the already-accepted invitation → `already-resolved(accepted)`. `accept(tok_inv_f77, user_u1)` on the lapsed one → expired. `revoke(tok_inv_c41, admin_a7, "  ")` → `already-resolved(accepted)`, not invalid-request: the status check runs first, and the fact that ends the conversation is that the invitation was accepted (Execution Contract Refusal 1).

### Decline

The resolving write that records a deliberate refusal, standing the invitation in [Declined] and stamping [Declination Instant]. Takes no acting reference: the refusal is recorded, the refuser is not. Legal only while the invitation stands in [Pending] and reads live.

Kind: Operation

```
decline(invitation_token)
  answers declined
  refuses not-known | already-resolved(stored terminal) | expired | storage-failure
```

```
Operation 27: [Decline] MUST NOT accept an acting reference.
Operation 30: An admitted decline MUST stand the invitation in declined.
Operation 31: An admitted decline MUST record now as declination instant.
```

Term admitted decline: a [Decline] call the action admits (Execution Contract Read 4).

### Revoke

The resolving write by which the inviting side withdraws the invitation, standing it in [Revoked] and recording [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Legal only while the invitation stands in [Pending] and reads live; a lapsed invitation needs no withdrawal, since it already reads [Expired].

Kind: Operation

```
revoke(invitation_token, revoked_by_ref, reason)
  answers revoked
  refuses not-known | already-resolved(stored terminal) | expired | invalid-request | storage-failure
```

```
Operation 24: IF revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 25: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 32: An admitted revoke MUST stand the invitation in revoked.
Operation 33: An admitted revoke MUST record revoked by reference, reason as revocation reason and now as revocation instant.
Operation 51: IF a string input EXCEEDS the string cap THEN [Revoke] MUST answer invalid-request (Execution Contract Input 2).
```

Term admitted revoke: a [Revoke] call the action admits (Execution Contract Read 4).

#### Reason

The withdrawal reason supplied to [Revoke], recorded as [Revocation Reason]. Required and never blank.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

### Revoke List Invitations

The write that withdraws every open invitation to one list when the list ends, as [Revoke] withdraws one: every pending invitation carrying the context that reads live stands in [Revoked], recording [Revocation Instant] alone; the action the list id need's on end names, which the app calls when an action the meeting offer's ends names ends the list (Needs). It takes the context alone and records no [Revoked By Reference] and no [Revocation Reason], since no actor's call reaches it and the atom attests none (Non-goal 15). A lapsed invitation already reads [Expired] and an invitation in a stored terminal stays as it stands. A context no pending invitation carries live is left as it is. Answers ok.

Kind: Operation

```
revoke_list_invitations(context)
  answers ok
  refuses storage-failure
```

```
Operation 53: [Revoke List Invitations] MUST stand in revoked EVERY pending invitation that carries the context AND reads live.
Operation 54: IF a pending invitation that carries the context reads live THEN [Revoke List Invitations] MUST record now as revocation instant on EVERY invitation the call stands in revoked.
Operation 55: [Revoke List Invitations] MUST NOT record a resolution field but revocation instant.
Operation 56: [Revoke List Invitations] MUST NOT write an invitation other than one Operation 53 stands in revoked.
Operation 57: [Revoke List Invitations] MUST answer ok.
Operation 58: IF no pending invitation that carries the context reads live THEN [Revoke List Invitations] MUST NOT write.
Operation 59: IF a pending invitation that carries the context reads live THEN [Revoke List Invitations] MUST append one invitation events record through the atom's journal need for EVERY invitation the call stands in revoked.
```

| Call | Case | Answer | Effect on the invitations |
|---|---|---|---|
| [Revoke List Invitations] | a pending invitation carrying the context reads live | ok (Operation 57) | each such invitation stands in [Revoked], carrying now as its revocation instant and no revoked by reference or revocation reason, and one invitation events record is appended for each (Operation 53, Operation 54, Operation 55, Operation 59); every other invitation is left as it is (Operation 56) |
| [Revoke List Invitations] | no pending invitation carrying the context reads live | ok (Operation 57) | none, no write (Operation 58) |
| [Revoke List Invitations] | a pending invitation carrying the context reads live, the database or the journal refuses the write | [Storage Failure] | none, each such invitation stays [Pending] (Execution Contract Read 4, Execution Contract Database 1, Execution Contract Constituent failure 1) |

### Read

The read-only query answering the [Invitation] records a [Filter] matches, each carrying its stored fields and its derived [Effective Status]. Refuses nothing — a filter matching no invitation has a correct answer rather than an error.

Kind: Operation

```
read(filter)
  answers the matching invitations
```

```
Operation 41: An admitted read MUST answer EVERY matching invitation.
Operation 42: An admitted read MUST answer the effective status PER matching invitation.
Operation 43: [Read] MUST NOT record a field.
Operation 44: [Read] MUST NOT refuse a filter.
```

Term admitted read: a [Read] call that answers.

Term filter: the selection a [Read] call scopes the answer by — a [Filter] naming invitation token (matched by its token digest), context, status, accepting identity reference, any combination of them OR no field; an invitation matches a filter when it carries EVERY value the filter names (String 1), a status matched against the invitation's stored status and never its effective status, and the filter names no other field; so a filter naming no field matches EVERY invitation, a filter naming any other field matches no invitation, and a malformed filter (Execution Contract Query 1) is answered by this match, a status other than pending, accepted, declined OR revoked matching no invitation; consumed per call, never stored.

#### Filter

The selection a caller passes to [Read] to scope which invitation records are returned: any combination of an [Invitation Token], a [Context], a [Status] and an [Accepting Identity Reference], or none. An invitation matches when it carries every value the filter names, and a filter naming no field matches every invitation; a filter naming a blank value, a status outside the four stored values, or any other field matches none. A status filter reads the stored [Status], never the derived [Effective Status], which [Read] answers on every match. A malformed filter is answered by the same match, since [Read] refuses nothing. Consumed per call; never stored.

Kind:         Parameter
Parameter of: Read
Projection:   filter

Term matching invitation: an invitation the read's filter matches (Term filter).

## What is and what should never be (Invariants)

- **Invariant 2 — Single-resolution by write.**
  ```
  Invariant 2.1: An invitation MUST NOT reach two stored terminals.
  Invariant 2.2: An invitation MUST NOT carry two resolution instants.
  ```
- **Invariant 3 — Acceptance binds identity.**
  ```
  Invariant 3.1: EVERY accepted invitation MUST carry a non-blank accepting identity reference.
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
- **Invariant 8 — Revocation attribution completeness.**
  ```
  Invariant 8.1: EVERY invitation an admitted revoke stood in revoked MUST carry a non-blank revoked by reference.
  Invariant 8.2: EVERY invitation an admitted revoke stood in revoked MUST carry a non-blank revocation reason.
  Invariant 8.3: EVERY revoked invitation MUST carry a revocation instant.
  ```
- **Invariant 9 — Every invitation has a finite lifetime.**
  ```
  Invariant 9.1: EVERY invitation MUST carry an expiry instant.
  ```
- **Invariant 11 — Token uniqueness is database-enforced.**
  ```
  Invariant 11.1: A token digest MUST resolve to EXACTLY ONE invitation.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when an invitation lapses.
  Invariant 12.2: An admitted read MUST compute the effective status from the invitation's status, the invitation's expiry instant and now (Execution Contract Logic confinement 20).
  ```
- **Invariant 1 — Initiation immutability.**
  ```
  Invariant 1.1: An admitted resolving write MUST NOT change a property.
  Invariant 1.3: [Revoke List Invitations] MUST NOT change a property.
  ```
- **Invariant 7 — Expiry deadline immutability.**
  ```
  Invariant 7.1: The atom MUST NOT change an invitation's expiry instant.
  ```
- **Invariant 10 — Invitation durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove an invitation from the database.
  ```

## When something happens

### Atomic writes

### Concurrency

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input, the canonical form the seam gives a reference excepted (Execution Contract Logic confinement 13).
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
```

Term string input: a reference, context OR reason — every caller-supplied string this atom accepts.

Term string cap: the bound on a string input's length in Unicode code points, counted PER Execution Contract Input 2; 1,024 code points where a deployment declares none; [Decline]'s one string input is the invitation token, so an over-cap token names no invitation and answers not-known (Operation 15, Execution Contract Refusal 1); [Revoke List Invitations]'s one string input is the context, which no invitation carries over the cap (Operation 49), so an over-cap context finds no invitation and answers ok, writing nothing (Operation 58).

NOTE: watch the cap's measure (Term string cap).

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the token material at the seam.
Capability requirement 3: The deployment MUST supply token material drawn from a cryptographically random source.
Capability requirement 4: The deployment MUST declare the default ttl inside the ttl bounds.
Capability requirement 5: The deployment MUST declare the ttl bounds.
Capability requirement 6: The database MUST refuse a write carrying a token digest the database holds.
Capability requirement 9: The deployment MUST deliver the invitation token to the invitee (Non-goal 4).
Capability requirement 12: The deployment MUST supply the invitation records PER Execution Contract Database 1 through 7, Execution Contract Read 4, Execution Contract Read 5 and Execution Contract Refusal 1.
Capability requirement 13: The deployment MAY declare the string cap PER Execution Contract Input 2.
Capability requirement 14: The deployment MUST supply the token digests at the seam (Execution Contract Logic confinement 8).
Capability requirement 15: The deployment MUST supply the token material unchanged as the canonical form of an invitation token (Execution Contract Logic confinement 13).
```

Term ttl bounds: the deployment's admitted range for a ttl — a window length, the time to live an [Initiate] call supplies for the invitation's window; each bound itself admitted, and every admitted value exceeds zero.

Term default ttl: the ttl the deployment declares for an [Initiate] carrying none.

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading, the token material and the token digests here.

Term transition: the atom's evaluation of one call against the invitation records.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it; the atom spends no clock allowance, since it compares a call's reading only with an instant an earlier call stamped from the deployment's one clock, whose agreement across nodes the deployment owns (Execution Contract Logic confinement 7 and Execution Contract Logic confinement 18).

NOTE: watch the seam citation (Term seam, Term transition).

#### Now

The wall-time reading the host takes at the seam and hands to the transition (Execution Contract Logic confinement 11) — never read inside the transition and never supplied by the business caller. Consumed by every action: by [Initiate]'s stamp, by a resolving write's and [Revoke List Invitations]' window reading and stamp, and by [Read]'s [Effective Status] projection.

Kind:         Parameter
Parameter of: Initiate, Accept, Decline, Revoke, Revoke List Invitations and Read
Projection:   now

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. That an accepted invitation grants the accepting actor access to the list is the app's glue line, and no rule of this atom.

Term need key: key list id; pairs invitations; on end Revoke List Invitations.

Term need key: key actor id; pairs inviters and accepters.

Term need journal: records invitation events; calls append; arms event_id.

## Left to others

```
Non-goal 1: The atom MUST NOT create an identity record for an accepted invitation.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom creates no identity record, and which pattern does is the app's choice.
Non-goal 3: The atom MUST NOT register a credential.
Non-goal 4: The atom MUST NOT deliver the invitation token.
Non-goal 5: The atom MUST NOT issue a session.
Non-goal 6: The atom MUST NOT decide who may invite whom.
Non-goal 7: The atom MUST NOT decide what a context names.
Non-goal 8: The atom MUST NOT sequence the steps following an acceptance.
Deleted: Non-goal 9. Non-goal 8 owns it: the atom sequences nothing after an acceptance, and which pattern does is the app's choice.
Non-goal 10: A deployment needing an accepting identity matched to an invitee MUST compose a matching rule.
Non-goal 11: The atom MUST NOT offer a second acceptance of one invitation.
Non-goal 12: The atom MUST NOT record who declined.
Non-goal 13: The atom MUST NOT record a transition history in the invitation record (Operation 52 appends each admitted write to the journal, not to the invitation record).
Non-goal 14: A deployment needing the full transition history MUST read the admitted write events the atom appends through the atom's journal need (Operation 52) and the refused action events a composing pattern appends (Composition note 5).
Non-goal 15: The atom MUST NOT bind an acting reference to an actor.
Deleted: Non-goal 16. Non-goal 15 owns it: the atom binds no acting reference to an actor, and which pattern attests one is the app's choice.
Non-goal 17: The atom MUST NOT verify an accepting party's real-world credentials.
Deleted: Non-goal 18. Non-goal 17 owns it: the atom verifies no real-world credential, and which pattern proofs one is the app's choice.
Non-goal 19: The atom MUST NOT detect a rewrite under the database.
Non-goal 20: A deployment needing a rewrite of the database detected MUST detect the rewrite outside the atom.
Non-goal 21: The atom MUST NOT bound an invitation's retention.
Non-goal 22: The atom MUST NOT record an answer the atom gave.
Non-goal 23: The atom MUST NOT decide whether a token holder may pass the token on.
Non-goal 24: The atom MUST NOT guarantee that an invitation resolves.
Non-goal 25: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 26: The atom MUST NOT supply a verifiable time anchor.
Non-goal 27: The atom MUST NOT decide who may call an action.
Non-goal 28: A deployment needing a retention bound MUST bound retention outside the atom.
Deleted: Non-goal 29. Non-goal 6 and Non-goal 27 own it: the atom decides no authority, and the app's permission gates the call.
Deleted: Non-goal 30. Non-goal 4 owns it: the atom delivers no token, and which pattern does is the app's choice.
Deleted: Non-goal 31. Non-goal 3 owns it: the atom registers no credential, and which pattern does is the app's choice.
Deleted: Non-goal 32. Non-goal 5 owns it: the atom issues no session, and which pattern does is the app's choice.
```

NOTE: the owners — patterns the app chooses, none of which the atom depends on: one that redeems bearer capabilities (Non-goal 11, Non-goal 23, Composition note 9), the app's permission (Non-goal 6, Non-goal 27, External check 3), one that delivers the token (Non-goal 4, Capability requirement 9, External check 4), one that registers a credential (Non-goal 3), one that issues a session (Non-goal 5), one that creates an identity record and proofs it (Non-goal 1, Non-goal 17, External check 7), one that attests an actor (Non-goal 15); the composing pattern (Non-goal 7, Non-goal 8, Non-goal 12, Composition note 5, External check 5); the deployment's own detection and retention bound (Non-goal 20, Non-goal 28, Composition note 8, External check 6); the caller's own record (Non-goal 22, External check 1); a matching rule the app writes (Non-goal 10); the deployment's clock guarantees, Execution Contract Logic confinement 7 (Non-goal 25, Non-goal 26); the inviter and the invitee, who alone resolve an invitation (Non-goal 24).

```
Composition note 1: A composing pattern that onboards a party MUST create the party record ONLY AFTER an admitted accept.
Composition note 2: A composing pattern that onboards a party MUST record the accepting identity reference beside the party record's id on the onboarding's completion record.
Composition note 3: A composing pattern that onboards a party MUST register the credential against the party record the accepted invitation's onboarding enrolled.
Deleted: Composition note 4. Operation 52 owns it: the atom appends one invitation events record for every admitted write, and none for a read.
Composition note 5: A composing pattern MUST append a refused action event on EVERY action this atom refused, the atom's own refused call writing nothing (Execution Contract Read 4, Read 7).
Composition note 6: A composing pattern that attests actions MUST attest the actor behind an admitted accept.
Composition note 7: A composing pattern that attests actions MUST attest the actor behind an admitted initiate.
Composition note 8: A deployment detecting a rewrite under Non-goal 20 MUST cover EVERY reference the database holds when the detection runs.
Composition note 9: A composing pattern that redeems bearer capabilities MUST call [Initiate] PER redemption.
Composition note 10: A composing pattern that attests actions MUST attest the actor behind an admitted revoke.
```

Term redemption: one admitted redeem of a composing pattern's bearer token — the act Composition note 9 binds.

Term composing pattern: whatever pattern an app composes beside this atom; this pattern names none.

NOTE: composing patterns — an app names the atoms it composes; this pattern names none.

## Example

### New employee onboarding — accept

`initiate(admin_a7, none, "org:northwind", 604800)` → `tok_inv_c41`, standing pending, its ttl seven days. The token reaches the new hire out of band. Three days in, `accept(tok_inv_c41, user_u114)` → accepted, binding `user_u114`. The invitee reference was absent at initiation because the hire had no system identity to name; the identity now recorded is the one the call presenting the token supplied. The app's onboarding proceeds from here to a party record, a credential and a session.

### Workspace collaboration — decline

`initiate(owner_w3, contractor_c9, "workspace:atlas", 1209600)` → `tok_inv_d58`, its ttl fourteen days. The contractor declines: `decline(tok_inv_d58)` → declined, stamping declination instant and nothing else. No identity is bound, because nobody joined. The record says a holder of the token saw the invitation and refused — which is a different fact from the window closing unanswered, and the reason declined is a terminal of its own.

### Revoked before use

`initiate(admin_a7, vendor_v2, "org:northwind", 2592000)` → `tok_inv_e5f`, its ttl thirty days. The engagement falls through and `revoke(tok_inv_e5f, admin_a7, "engagement cancelled")` → revoked. A later `accept(tok_inv_e5f, user_u220)` answers `already-resolved(revoked)` — not merely *no*, but *withdrawn, and here is which resolution stands*.

### The window closes

`initiate(admin_a7, none, "org:northwind", 604800)` → `tok_inv_f77`, its ttl seven days. Nobody answers. On the eighth day nothing has happened to the record: it still stands pending, carries no resolution field, and read returns it with an effective status of expired. An accept against it answers expired and writes nothing. The eventual difference between this invitation and `tok_inv_d58` above is the whole reason declined is a stored terminal.

### Regulated adversarial scenarios

- **Regulator audit.** *Prove that every user who reached patient records joined through a documented invitation from an authorized administrator.* Filter the database to accepted invitations whose context names that system; each record carries the administrator who invited (inviter reference), when the join committed (acceptance instant) and the identity bound (accepting identity reference). Invariant 3.1 is what makes the last of those never empty, so every accepted invitation names the identity bound, the inviter and the instant; that every join went through an invitation, and that the inviter was authorized, these records do not prove — the composing pattern owns the first (Non-goal 8) and the composing policy layer the second (External check 3).
- **Disputed onboarding.** *I never accepted an invitation — my account was made without me.* Filter by accepting identity reference; the read answers every invitation accepted under that identity — Invariant 2.1 bounds each invitation to one resolution, and no rule bounds how many invitations one identity accepts — and each carries the instant its token was presented. Whether that person or someone holding their token made the call is outside this atom — the record says a bearer presented the token whose digest the invitation carries at that instant and supplied that identity, and the device, the address and the credential registered alongside are an attestation's, outside this atom.
- **Breach investigation.** Tokens for a high-security context were exposed in a log over a week. Filter by that context, keep from that answer the invitations whose initiation instant falls inside that week, and read each effective status against the investigation clock: the accepted ones are cross-checked against known staff, the still-live ones are revoked at once, and the lapsed ones need nothing — no write ever fired against them and an accept would answer expired. Invariant 5.1 and Invariant 12.2 are what make that triage possible from the database and a clock alone.

## Source

- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Articles 6 and 7 (lawful basis and consent)** — [Initiate] creates a processing record: the system now holds an [Invitee Reference] and will process data about the invitee if they accept. [Initiation Instant] and [Inviter Reference] are the processing-event record; [Accepting Identity Reference] bound at [Accept] is the record of the data subject's active engagement.
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(a)(1) (access control)** — invitation-based provisioning is a covered access-granting mechanism. [Inviter Reference] names the administrator who granted access, whose authority the composing policy layer confirms (Non-goal 6, External check 3), and [Accepting Identity Reference] the identity that gained it.
- **SCIM 2.0 (System for Cross-domain Identity Management) RFC 7644 (RFC — Request for Comments, the Internet's numbered standards series)** — SCIM's `POST /Users` with an invite flow maps to the Invitation → onboarding arc. [Invitee Reference] corresponds to the external identity reference; [Accepting Identity Reference] to the provisioned user id.
- **SOC 2 (Service Organization Control 2 — an audit standard for service-provider security controls) CC6.2 (users registered and authorized before credentials are issued)** — the invitation record *is* the registration event, and the composing policy layer's record the authorization (External check 3). [Inviter Reference] names the party who invited; [Acceptance Instant] and [Accepting Identity Reference] are the registration.
- **NIST (National Institute of Standards and Technology) SP (Special Publication) 800-63A (enrollment and identity proofing)** — the enrollment event maps to the Invitation → accept arc. This atom models the enrollment record; proofing is another pattern's (Non-goal 17).

Standards anchoring here is lighter than for a credential, a session or a bearer capability, and deliberately so: this atom earns its place on EOS Pass 2 conceptual independence rather than on regulatory surface — the declined terminal, single-resolution by write, and identity binding at acceptance are what make it a separate atom instead of a fold into a bearer capability.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; separating an invitation's lifecycle record from the provisioning that follows acceptance.
- **Grace Commons regulated-atom conventions** — the adversarial scenarios and the acceptance section, from `pressure-testing.md`.

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the invitation records, with their committed versions (Execution Contract Generation acceptance 1), and the read-time clock.

#### Conformance checks

```
Check 1.1: An auditor MUST find no invitation carrying two resolution instants (Invariant 2.2).
Check 1.2: An auditor MUST find EXACTLY ONE resolution instant on EVERY invitation whose status IS IN the stored terminals (State 3 through 5, State 15).
Check 1.3: An auditor MUST find no resolution field on a pending invitation (State 6).
Check 2.1: An auditor MUST find no invitation storing expired as a status (State 7).
Check 2.3: An auditor MUST reproduce an admitted read's effective status from the invitation's status, the invitation's expiry instant and a clock reading the auditor supplies as that read's now (Invariant 12.2).
Check 3.1: An auditor MUST find a non-blank accepting identity reference on EVERY accepted invitation (Invariant 3.1).
Check 3.2: An auditor MUST find an acceptance instant on EVERY accepted invitation (State 3).
Check 4.1: An auditor MUST find no two stored terminals carrying one resolution field pattern (Invariant 5.1).
Check 5.1: An auditor MUST find a non-blank revoked by reference on EVERY revoked invitation carrying a revocation reason (Invariant 8.1, Operation 55).
Check 5.2: An auditor MUST find a non-blank revocation reason on EVERY revoked invitation carrying a revoked by reference (Invariant 8.2, Operation 55).
Check 5.3: An auditor MUST find a revocation instant on EVERY revoked invitation (Invariant 8.3).
Check 6.1: An auditor MUST find an expiry instant on EVERY invitation (Invariant 9.1).
Check 6.2: An auditor MUST find EVERY invitation's expiry instant unchanged across EVERY committed version of the invitation (Invariant 7.1; Execution Contract Generation acceptance 1).
Check 7.1: An auditor MUST find no token digest on two invitations (Identity 5, Invariant 11.1).
Check 7.2: An auditor MUST find EVERY invitation's properties unchanged across EVERY committed version of the invitation (Invariant 1.1, Invariant 1.3; Execution Contract Generation acceptance 1).
Check 8.1: An auditor MUST find an unfiltered read answering EVERY invitation with a committed version (Invariant 10.1; Execution Contract Database 6, Execution Contract Generation acceptance 1).
Check 9.1: An auditor MUST reconstruct EVERY invitation of one context from the database (State 1, Invariant 10.1; Execution Contract Database 6).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing an already-resolved answer's payload confirmed MUST read the caller's record of the answer (Non-goal 22).
External check 2: A deployment needing an accepting identity reference matched to the invitee MUST read the composing pattern's own rule (Identity 13, Non-goal 10).
External check 3: A deployment needing the inviter's authority confirmed MUST read the app's permission (Non-goal 6, Non-goal 27).
External check 4: A deployment needing the token's delivery to the invitee confirmed MUST read the delivery the app composes (Non-goal 4).
External check 5: A deployment needing a declining actor identified MUST read the composing pattern's own record (Operation 27, Non-goal 12).
External check 6: A deployment needing the database confirmed free of a retroactive edit MUST read the detection of Non-goal 20.
External check 7: A deployment needing the accepting party's real-world identity confirmed MUST read the composing pattern's proofing (Non-goal 17).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the deployment; the database; the seam; the transition; a composing pattern; a caller; an auditor; a regulator; an investigator; a reader; an invitation; a pending invitation; an accepted invitation; a declined invitation; a revoked invitation; a lapsed invitation; an action; a resolving write; a refused action; an answer; a token holder; an opaque reference; a string input; a filter; the database instance's invitation count.

Term records: invitation — one invitation issued by one inviter to join one list, carrying token digest, inviter reference (an actor id), context (a list id), initiation instant, expiry instant, a status and, where supplied or set, invitee reference, accepting identity reference, acceptance instant, declination instant, revoked by reference, revocation reason and revocation instant.

Term record verbs: identify, assign, generate, change, share, reuse, carry, stand, read, answer, record, leave, admit, offer, hold, refuse, write, find, resolve, name, compare, normalize, confirm, match, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, deliver, declare, compose, remove, bind, decide, define, bound, reach, accept, trim, case-fold, compute, reproduce, reconstruct, draw, verify, sequence, issue, detect, guarantee, take, store.

Term value sets: status = pending | accepted | declined | revoked. effective status = pending | accepted | declined | revoked | expired. stored terminal = accepted | declined | revoked. window reading = live | lapsed. property = inviter reference | invitee reference | context | initiation instant | expiry instant. resolution field = accepting identity reference | acceptance instant | declination instant | revocation instant | revoked by reference | revocation reason.

Term bounds: ttl bounds, default ttl, expiry bound, string cap.

Term cadences: empty.

Term matching invitation: an invitation the read's filter matches (Term filter).

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: invitation, invitation token, token material, token digest, property, reference, database instance, seam, transition, now, resolving write, stored terminal, status, status check, ttl bounds, default ttl, window length, expiry bound, window reading, live, lapsed, effective status, acting reference, admitted initiate, admitted accept, admitted decline, admitted revoke, admitted resolving write, admitted read, filter, resolution field, resolution instant, committed version, string input, blank, string cap.

Term cited: list id, actor id, invitation events: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Initiate]: #initiate
[Accept]: #accept
[Decline]: #decline
[Revoke]: #revoke
[Revoke List Invitations]: #revoke-list-invitations
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

## Status

`done — 2026-11-26` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-26
formal: verified — invitation.tla + 4 twins (2026-06-03); invitation.als + 13 twins (the static data model, 2026-11-11: State 3, 4 and 6 and Invariant 2.2, 3.1, 5.1, 6.1, 6.2, 8.1, 8.2, 8.3, 9.1 and 11.1 checked on every record an admitted [Initiate], [Accept], [Decline] or [Revoke] leaves and on every answer a resolving write gives over such records, Invariant 11.1 resting on the database's refusal of a held token (Capability requirement 6); nothing testable in Alloy for Invariant 1, 7 and 10 or for 2.1: each compares an invitation with a later version of it, which a single state cannot show, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 1 and 7 (across steps); owed rows: Invariant 1; Invariant 7, 2026-11-11; model redraw deferred to Lean: invitation.als and invitation.tla, Operation 53 through 59, State 15, Invariant 1.3, 2026-11-26
last gate: 2026-11-26 — Final Critique 18, a delta round (the reach of the diff since 45e3af35, 10 labels and the one range of changed text at the Invalid Request description), one reader (Linus opencode-go/mimo-v2.6-pro, after inception/mercury-3 answered nothing; GRID and EOS not run), frozen at f6b08fd4 — foundational count 0 after the blind second triage, clean, one sample (Linus's three foundational reports and four refining, none foundational by either triage. Its first, that the Invalid Request description's "a string input exceeds the string cap" obliges invalid-request where Term string cap answers not-known at [Decline] and ok at [Revoke List Invitations], is refining: neither action lists invalid-request on its refuses line, so no conforming build answers it there, and the description is scoped by the Operations that do oblige it (Operation 49, Operation 50, Operation 51), cured as wording; Linus's replacement half-restated Execution Contract Input 2's own-answer clause, which the Repeats rule refutes. Its second, that an over-cap context padded with spaces canonicalizes to a stored context, is refuted: a context is no reference, so Execution Contract Logic confinement 13 never canonicalizes it and String 1 to String 4 compare it byte-exactly. Its third, that Operation 3's "falls outside the ttl bounds" is no admitted form, is a form breach with one reading (Term ttl bounds is an admitted range, each bound itself admitted), cured by Earned vocabulary 10's "IS NOT IN". The four refining lines placed no defect: Operation 5 is the page's own answer for a blank default ttl (Logic confinement 15 keeps it), Term status check defines every status check, both actions answer an over-cap token not-known (Refusal 1, not-known listed first on [Accept]), and a Term carrying an answer is the corpus's form (Closed vocabulary 11). The checker's seventeen hits placed none: the fifteen case-row hits as Final Critique 17 placed them, and TTL and CC6 stand glossed at their first use, which the checker's gloss test misses); 2026-11-26 — Final Critique 17, a delta round (the reach of the diff since f5f4ab98, 47 labels and 12 ranges of changed text), one reader (Linus opencode-go/beam-free, after opencode-go's other models answered nothing, Claude Sonnet was at its paced ceiling and the free models were spent; GRID and EOS not run), frozen at 45e3af35 — foundational count 1, cured, not clean, no sample (Linus's one foundational, that Term string cap counted the cap "on the value as the call carries it" alone while Execution Contract Input 2 counts it on that value and again on the value as the seam leaves it, so a build reading the Term alone admits a value whose canonical form is over the cap and a build reading both refuses it, cured as wording by citing Input 2 in place of restating its measure (Linus's own replacement restated the rule, which the Repeats rule refutes); the checker's one true hit of seventeen cured with it, TTL glossed at its first use; its fifteen case-row hits placed no defect, since each refusal has its rule and no rule asks a case table of an action, and its CC6 hit placed none, since CC6.2 stands glossed at its first use); 2026-11-25 — Final Critique 16, a delta round (the reach of the diff since 9104a811, 4 labels), one reader (Linus opencode-go/beam-free, after opencode/beam-free was refused "Free usage exceeded"; GRID and EOS not run), frozen at f5f4ab98 — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational, that Storage Failure names only [Pending] as the residual state while a [Revoke] admitted against an [Accepted] invitation would leave [Accepted], refuted by both triages: [Revoke], like [Accept] and [Decline], is legal only while the invitation stands [Pending] and reads live, and Operation 16 answers already-resolved on a stored terminal before any write or append, so every admitted write acts on a [Pending] invitation and the two residual states are the whole set; the blind second triage's one refining finding, that Non-goal 13's "MUST NOT record a transition history" contradicted Operation 52 and Non-goal 14, which have the atom append every admitted write as the history, cured as wording: the history Non-goal 13 refuses is the invitation's own, the journal holds the appended events); 2026-11-25 — Final Critique 15, a delta round (diff base 1f757b57, 185 labels reached and every changed line), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 9104a811 — foundational count 1, cured, not clean, no sample (Linus counted none and three refining; the blind second triage placed Composition note 4's "EVERY admitted action" foundational, since it binds the atom to append on a Read that Operation 43 and the Execution Contract's read actions leave writing nothing, so a build appending on Read and one appending on the four writes leave different journals and give different Read answers when the journal fails; cured by Operation 52, which names the four writes, the Composition note tombstoned to it, Non-goal 14 pointing at it, and the Storage Failure entry naming the journal's refusal (Execution Contract Constituent failure 1); the cites to the deleted Non-goal 30 cured as wording; the two `Term need key` lines refuted as the form bonds.md writes; the blind triage's one added hardening, that a deployment canonicalizing the token under Logic confinement 13 would break the digest, cured by Capability requirement 15); 2026-11-24 — Final Critique 14, a delta round (the reach of the diff since 097687f5, 4 rules), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 1f757b5 — foundational count 0 after the blind second triage, clean, one sample (Linus's report counted none and two refining: Composition note 5's scope and Composition note 8's time of reading, both cured as wording, the first now reading the actions this atom refused, the second the references held when the detection runs; the blind second triage placed all six of his findings below foundational, found Composition note 5 wanting Read 7's citation, cured, and placed a reading of Composition note 8 as a ceiling on what detection covers refuted, since Non-goal 20 requires the rewrite detected whole and External check 6 reads that detection); 2026-11-24 — Final Critique 13, a delta round (the reach of the diff since 369b7bb, 11 rules), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 097687f5 — foundational count 1, cured, not clean, no sample (Linus's first foundational, that Composition note 5 bound the atom to append a refused action event while Execution Contract Read 4 says a refused call writes nothing, stands: the composing pattern appends it, as the page said before the journal unit, and the need records the admitted event alone; his second, that Non-goal 20 names no owner, was placed refining: its subject is the deployment, cured by Composition note 8 saying so and the owners NOTE listing the deployment); 2026-11-20 — Final Critique 12, a delta round, frozen at 369b7bb — foundational count 0 after the blind second triage, clean, one sample (Linus's one report (nemotron-3.5-super-vl-free) claimed one foundational, that [Initiate] with a blank ttl has no defined transition: refuted by both triages, Operation 4 reading the default ttl as a blank ttl and Operation 5 answering invalid-request where no default is declared, so no two builds differ; the reach held Operation 3 and 12 and not 4 and 5, and its cure would have contradicted Operation 4); 2026-11-20 — Final Critique 11, a full round, frozen at d474077 — foundational count 1, cured, not clean, no sample; 2026-11-04 — Final Critique 10, a delta round, frozen at cd9d6f3 — foundational count 0, clean, one sample; 2026-11-03 — Final Critique 9 (delta) — foundational count 3, cured, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./invitation.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/invitation.md`.

</details>

NOTE: End of Invitation.

---
title: Credential
id: 37
audience: common
has_toc: true
toc: true
---

# Credential

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Credential answers one question: *does this presented material belong to this principal, for this kind of credential?* A principal is whatever entity is being authenticated — a user, a service account, a system actor.

It works through records that bind a principal to a **verifier**: an artifact derived from the secret material — a hashed password, a public key — from which no matching material can be produced, and which lets the system check a later presentation without ever keeping the original secret. The raw material is used at registration and at each check, then discarded. Only the verifier persists.

Each record stands in one open status, active, or in one of two permanent stored ends: rotated (replaced by a newer credential) or revoked (deliberately cancelled, with when, why and whom the caller named recorded). A credential also *expires* — but expiry is not a stored status. When the deadline passes, a still-active record is simply shown expired, computed at read time from the deadline and the clock, never written.

One principal reference holds at most one *effective-active* credential of a given type, where effective-active means stored active **and** before its deadline. That bound is judged at any moment from the latest registration for the principal and type on. A call whose clock reads earlier than a newer registration can still find an older credential live beside it. It holds across spellings because the deployment canonicalizes references — rewriting spellings that differ only in letter case, surrounding spaces or Unicode form (the several byte sequences the Unicode character standard allows for one character) to one — and declares no two credential types that differ only that way. A lapsed record no longer occupies that slot, so a fresh registration is permitted beside it. Rotation is clean: the successor is a new record and the predecessor moves to rotated carrying a link forward, so the whole chain of replacements is walkable.

This is the mechanism behind password login, public-key authentication (safe against a captured answer being sent again only when a composing pattern issues a fresh challenge each time), programming-interface tokens (secrets a program presents to a service in place of a person) and hardware keys. Proving who the principal is in the first place, sequencing multiple factors, keeping someone logged in, and deciding what they may do are each a separate pattern. A credential belongs to one actor: its principal reference is the actor id of the principal it binds, and checking presented material against the credential is this atom's own rule, while opening a session after a good check is the app's sign-in glue.

<details markdown="block">
<summary>WHY</summary>

Authenticated systems require an actor to prove identity before acting with consequence — moving funds, prescribing medication, signing a contract, reaching a protected record. The proof is a credential: something the actor knows, something the actor has, or something the actor is. What is constant across all three is the *binding* — the association between a specific principal and specific material, established at registration and queryable at verification.

This atom isolates that binding. It does not implement login flows, sessions, identity proofing, multi-factor orchestration or authorization. The answer it gives is binary — verified, or a named reason it was not — and it is answerable from stored records, the presented material, the deployment's check function and a clock, without the system's runtime state and without the calling actor's testimony.

This is a freestanding atom in the EOS (Essence of Software, Daniel Jackson's concept design) sense: its own state, its own three writes and two reads, and its own operational principles — verifiers are stored and material is not, rotation produces a new record, a stored terminal is absorbing, and expiry is derived.

</details>

## What it keeps

### The credentials

Term credential: the record this atom holds — one principal's binding to one verifier, for one credential type.

#### Credential

The record this atom defines: one principal's binding to one verifier for one credential type. Carries [Credential Id], [Principal Reference], [Credential Type], [Verifier], [Registration Instant], [Status], an optional [Expiry Instant], and the terminal fields of whichever write ended it.

Kind: Type
Projection: status

```
Identity 1: The atom MUST identify a credential by the credential id.
Identity 2: The atom MUST assign the id material the seam supplies as the credential id.
Identity 3: The atom MUST NOT generate a credential id.
Identity 4: The atom MUST NOT change a credential's credential id.
Identity 5: Two credentials MUST NOT share a credential id.
Identity 6: The atom MUST NOT identify a credential by the pair.
Identity 7: The atom MUST compare a reference byte-exactly.
Identity 8: The atom MUST NOT normalize a reference.
Identity 9: The atom MUST NOT confirm that a principal reference names a known principal.
Identity 10: The atom MUST NOT confirm that a revoked by reference names a known actor.
```

Term credential id: the opaque value naming one credential — a [Credential Id]; the id material the seam supplies, assigned as it stands (Identity 2).

#### Credential Id

The opaque, immutable identity of a [Credential], assigned on the [Register] or [Rotate] that records it, as the id material the seam supplies. Never reused, and never the pair — two credentials for one pair are a rotation predecessor and its successor, or a lapsed credential and a later registration, each standing on its own.

Kind:       Field
Field of:   Credential
Projection: credential_id

Term fresh credential id: a credential id naming no credential of the database instance, the id material the seam supplies assigned as the credential id (Capability requirement 34, 35).

Term id material: the value the deployment supplies at the seam, which the atom assigns as a credential id (Identity 2, Capability requirement 2).

Term pair: principal reference and credential type together — the key the effective-active bound ranges over.

Term property: principal reference | credential type | verifier | registration instant | expiry instant — what a credential carries from registration and never changes.

Term reference: credential id, principal reference, revoked by reference OR successor credential id — every opaque reference this atom records.

Term database instance: one named database a call is routed to.

#### Principal Reference

The actor id naming whose credential this is, the principal the credential binds (Needs). Set on [Register], immutable. The atom does not confirm it names a known or proofed party; that is left to others (Non-goal 1).

Kind:       Field
Field of:   Credential
Projection: principal_ref

#### Credential Type

The label naming the kind of credential — such as `password`, `public-key`, `api-token` or `fido2` (a hardware authenticator of the second authentication standard of the FIDO — Fast Identity Online — Alliance, see Standards references). Half of the pair the effective-active bound ranges over, and the selector for the derivation function; a type naming no registered function is refused.

Kind:       Field
Field of:   Credential
Projection: credential_type

Term verifier: the artifact a derivation function produces from credential material — what this atom stores in place of the material.

#### Verifier

The artifact a one-way derivation function produces from [Credential Material] — a hash, an encoded public key. The only thing this atom stores in place of the secret, and never answered by [Read].

Kind:       Field
Field of:   Credential
Projection: verifier

Term derivation function: the deployment's function from material to a verifier, declared for one credential type; the verifier alone produces no material the type's check function matches.

Term derivation registry: the deployment's declared map from a credential type to a derivation function and a check function; supplied at the seam.

Term check function: the deployment's function, declared for one credential type beside its derivation function, answering whether presented material matches a recorded verifier.

Term secret verifier: a verifier whose disclosure helps a caller produce matching material — a password hash, a token hash; a public key is not one.

Term constant time: a check's duration that the recorded verifier does not change — one presented material takes as long against any verifier.

Term status: active | rotated | revoked — the value a credential stores.

Term stored terminal: rotated | revoked.

#### Status

The stored status of a [Credential] — [Active], [Rotated] or [Revoked]. [Expired] is not a value of this field; it appears only in the derived [Effective Status].

Kind:       Field
Field of:   Credential
Projection: status

#### Active

The one non-terminal status. An active credential reads live or lapsed against [Now]; only a live one is effective-active, and only an effective-active one can be verified against, rotated or revoked.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Rotated

The stored terminal reached when a [Rotate] recorded a successor. Carries [Rotation Instant] and [Successor Credential Id]. Absorbing.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Revoked

The stored terminal reached when the credential was deliberately cancelled. Carries [Revocation Instant], [Revoked By Reference] and [Revocation Reason]. Absorbing.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Expired

The derived status of an [Active] credential whose deadline has passed. Never stored, carried by no field, reached by no write — the value [Effective Status] computes from [Expiry Instant] and [Now]. A credential reading [Expired] no longer occupies its pair's effective-active slot, which is why a fresh [Register] succeeds beside it.

Kind:      Member
Member of: the effective status
Role:      Outcome

#### Registration Instant

The instant the credential was recorded, stamped from [Now] on [Register], or on the [Rotate] that recorded the credential as a successor. Immutable.

Kind:       Field
Field of:   Credential
Projection: registered_at

#### Expiry Instant

The optional instant the window closes, recorded on [Register] or on a [Rotate]'s successor from the caller's value or now plus the deployment's default validity. Immutable. Absent means no deadline, and a credential with no deadline reads live forever. With the stored status, the only stored input the derived [Effective Status] needs.

Kind:       Field
Field of:   Credential
Projection: expires_at

#### Rotation Instant

The instant the replacement committed, stamped from [Now] on [Rotate]. Present only in [Rotated]; written once and never rewritten.

Kind:       Field
Field of:   Credential
Projection: rotated_at

#### Successor Credential Id

The [Credential Id] of the credential that replaced this one. Present only in [Rotated]; written once, because a re-link would silently rewrite the chain an auditor walks.

Kind:       Field
Field of:   Credential
Projection: successor_credential_id

#### Revocation Instant

The instant the revocation committed, stamped from [Now] on [Revoke]. Present only in [Revoked]; written once.

Kind:       Field
Field of:   Credential
Projection: revoked_at

#### Revoked By Reference

The opaque reference naming who revoked the credential. Required on [Revoke] and never blank on a [Revoked] credential.

Kind:       Field
Field of:   Credential
Projection: revoked_by_ref

#### Revocation Reason

The caller-supplied [Reason] for the revocation. Required and never blank — a revocation nobody can explain is a finding rather than a record.

Kind:       Field
Field of:   Credential
Projection: revocation_reason

Term terminal field: rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason — every field a transitioning write records.

Term effective status: expired where the credential reads lapsed, and the stored status otherwise — a projection over the credential and now, never stored.

#### Effective Status

The status a [Read] answers: [Expired] where the credential reads lapsed, and the stored [Status] otherwise. A projection over the credential and [Now] — computed at read time, never stored, and the only surface on which [Expired] appears.

Kind:       Field
Field of:   Credential
Projection: effective_status

Term window reading: live | lapsed — how an active credential's window reads against now.

Term live: the window reading of an active credential whose expiry instant EQUALS blank, OR now PRECEDES expiry instant.

Term lapsed: the window reading of an active credential whose expiry instant DOES NOT EQUAL blank and now DOES NOT PRECEDE expiry instant; the boundary instant — expiry instant equal to now — reads lapsed.

Term effective-active credential: a credential whose status EQUALS active that reads live.

Term lapsed credential: a credential whose status EQUALS active that reads lapsed.

Term settled reading: a reading of now that no registration instant of the pair follows — the only reading at which Invariant 2.1 and Check 1.1 judge a pair's credentials together; an earlier reading judges the pair's credentials as the call finds them, a credential whose registration instant follows that reading among them (Operation 65).

```
State 1: EVERY credential MUST carry credential id, principal reference, credential type, verifier, registration instant and a status.
State 2: A credential MAY carry an expiry instant.
State 3: EVERY rotated credential MUST carry rotation instant and successor credential id.
State 5: An active credential MUST NOT carry a terminal field.
State 6: The atom MUST NOT store expired as a status.
State 7: A credential MUST NOT carry a lapse instant.
State 8: The atom MUST NOT expose a verifier.
State 9: A credential MUST NOT carry credential material beyond the verifier.
State 10: A credential MUST NOT carry presented material.
State 11: The atom MUST NOT offer a reactivate surface.
State 12: The atom MUST NOT offer a window extension surface.
State 13: The atom MUST NOT offer a credential removal surface.
State 14: The atom MUST NOT offer a verifier migration surface.
```

Term lapse instant: an instant a database writes when a credential starts to read lapsed, beside a status that stays active — the materialized lapse; never stored here, because lapse is read, not written.

## What people do

### Every action

```
Operation 27: IF the credential id names no credential THEN a transitioning write MUST answer not-known.
Operation 50: The atom MUST NOT offer an expire action.
```

Term transitioning write: [Rotate] | [Revoke] — every call that would take an effective-active credential to a stored terminal, including a refused one.

#### Invalid Request

The refusal returned when a required string input is blank, the material is absent or of size zero, a [Credential Type] names no derivation function, a supplied [Expiry Instant] is no instant or does not exceed [Now], the derivation function refuses the material, or — on [Register] and [Revoke] only — a string input exceeds the length bound. On a transitioning write it is listed after not-known and the standing refusals, so it answers only once none of them applies.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal a transitioning write returns when the supplied [Credential Id] names no credential. Listed ahead of [Not Active] and [Already Terminal] on the refuses lines, so a caller reading either refusal knows the id resolved.

Kind:       Member
Member of:  the transitioning-write rejection
Role:       Outcome
Projection: not-known

#### Storage Failure

The refusal any action returns when the database refuses the write after every precondition passes. No credential is recorded, or the credential remains as the call found it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Register

The behavior that records a new [Credential] — deriving the [Verifier] from [Credential Material] through the [Credential Type]'s derivation function, discarding the material, assigning a fresh [Credential Id], standing the record in [Active], and answering the id. Refused [Invalid Request], [Duplicate Active Credential] or [Storage Failure].

Kind: Operation

```
register(principal_ref, credential_material, credential_type, optional expires_at)
  answers credential_id
  refuses invalid-request | duplicate-active-credential | storage-failure
```

```
Operation 1: IF principal reference EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 2: IF credential material IS IN the empty materials THEN [Register] MUST answer invalid-request.
Operation 3: IF credential type EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 4: IF the credential type names no derivation function THEN [Register] MUST answer invalid-request.
Operation 5: IF now DOES NOT PRECEDE a supplied expiry instant THEN [Register] MUST answer invalid-request.
Operation 6: IF an effective-active credential EXISTS for the pair THEN [Register] MUST answer duplicate-active-credential.
Operation 8: A lapsed credential MUST NOT block a register for the credential's pair.
Operation 9: An admitted register MUST assign a fresh credential id.
Operation 10: An admitted register MUST record principal reference and credential type.
Operation 11: An admitted register MUST record the derived verifier.
Operation 12: An admitted register MUST record a supplied expiry instant.
Operation 13: IF expiry instant EQUALS blank AND the default validity DOES NOT EQUAL unbounded THEN an admitted register MUST record the default expiry.
Operation 14: An admitted register MUST record now as registration instant.
Operation 15: An admitted register MUST stand the credential in active.
Operation 16: An admitted register MUST answer the credential id.
Operation 17: [Register] MUST NOT retain credential material beyond the verifier.
Operation 66: IF the derivation function refuses the credential material THEN [Register] MUST answer invalid-request.
Operation 71: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted register MUST record no expiry instant.
Operation 80: IF a supplied expiry instant is malformed THEN [Register] MUST answer invalid-request (Execution Contract Input 1).
```

Term admitted register: a [Register] call the action admits (Execution Contract Read 4).

Term credential material: credential_material — the material [Register] derives the verifier from.

#### Credential Material

The raw input the principal supplies to [Register]: a secret for a secret-derived type, a public key for a public-key type. Consumed to derive the [Verifier] and then discarded — never stored in a field, a log or a temporary record beyond the verifier itself, and a public key's verifier is its canonical encoding, which is why State 9 says *beyond the verifier*.

Kind:         Parameter
Parameter of: Register
Projection:   credential_material

#### Duplicate Active Credential

The refusal [Register] returns when the pair already holds an effective-active credential. The caller's move is [Rotate], not a second registration. A lapsed credential does not produce this.

Kind:       Member
Member of:  the Register rejection
Role:       Outcome
Projection: duplicate-active-credential

`register(user_u91, "x", "password")` on a pair that already holds an effective-active credential → duplicate-active-credential; the caller rotates instead. `register(user_u91, "x", "Password ")` → invalid-request, because no derivation function is registered for that type — which is also what stops a byte-exact key from quietly admitting a second effective-active credential under a near-duplicate name. `register(user_u92, "z", "password")` whose database write fails → storage-failure, and no record exists (Execution Contract Database 3).

### Verify

The read-only behavior that answers whether [Presented Material] matches the [Verifier] of the pair's latest-registered effective-active credential, as the type's check function decides. Answers verified, or failed-verification naming [Material Mismatch] or [No Active Credential]. Writes nothing, counts nothing, and does not say *why* no effective-active credential exists; a reference or credential type over the length bound names no pair, so it answers [No Active Credential] too (String 11).

Kind: Operation

```
verify(principal_ref, credential_type, presented_material)
  answers verified | failed-verification(verification failure)
```

Term verification failure: material-mismatch | no-active-credential — the reasons [Verify] gives for a failed verification.

```
Operation 18: IF no effective-active credential EXISTS for the pair THEN [Verify] MUST answer no-active-credential.
Operation 19: [Verify] MUST NOT distinguish the reason no effective-active credential EXISTS for the pair.
Operation 20: [Verify] MUST NOT check presented material BEFORE the window reading.
Operation 21: A proceeding verify MUST check the presented material against the recorded verifier PER the credential type's check function.
Operation 22: IF the check function answers no match THEN [Verify] MUST answer material-mismatch.
Operation 23: IF the check function answers a match THEN [Verify] MUST answer verified.
Operation 25: [Verify] MUST NOT retain presented material.
Operation 26: [Verify] MUST NOT record a field.
Operation 68: IF the check function refuses the presented material THEN [Verify] MUST answer material-mismatch.
Operation 70: A proceeding verify MUST check against the credential carrying the latest registration instant among the pair's credentials effective-active at the verify's reading, and, where two such credentials share that instant, against the one whose credential id comes first in ascending order (Execution Contract Logic confinement 10).
```

NOTE: watch cardinality (Operation 70).

Term proceeding verify: a [Verify] call whose pair carries an effective-active credential.

Term presented material: presented_material — the material [Verify] checks against the recorded verifier.

#### Presented Material

The raw material the principal supplies to [Verify]: a secret for a secret-derived type, a signed challenge for a public-key type, an assertion for a `fido2` type. Checked against the stored [Verifier] through the credential type's check function, then discarded. Never stored.

Kind:         Parameter
Parameter of: Verify
Projection:   presented_material

#### Material Mismatch

The [Verify] answer when an effective-active credential exists for the pair and the type's check function answers no match or refuses the presented material. A first-class result of a query, not a rejection.

Kind:       Member
Member of:  the failed-verification reason
Role:       Outcome
Projection: material-mismatch

#### No Active Credential

The [Verify] answer when the pair has no effective-active credential — because none was registered, because every record is a stored terminal, or because the only active one reads lapsed. The three are deliberately one answer: distinguishing them would let a caller learn whether a pair ever held a credential, or lost it by revocation or lapse, which a caller of [Verify] is not owed (material-mismatch already says the pair holds an effective-active credential, Operation 22).

Kind:       Member
Member of:  the failed-verification reason
Role:       Outcome
Projection: no-active-credential

### Rotate

The transitioning write that replaces a credential — recording a successor in [Active] for the same pair — a fresh [Credential Id], a [Verifier] derived from the new credential material, its own registration instant and [Expiry Instant] — standing the prior credential in [Rotated], and stamping [Rotation Instant] and [Successor Credential Id] on it. Legal only against an effective-active credential with no other effective-active credential beside it for the pair; otherwise [Not Active].

Kind: Operation

```
rotate(credential_id, new_credential_material, optional expires_at)
  answers new_credential_id
  refuses not-known | not-active | invalid-request | storage-failure
```

```
Operation 28: IF no effective-active credential EXISTS for the credential id THEN [Rotate] MUST answer not-active.
Operation 31: IF new credential material IS IN the empty materials THEN [Rotate] MUST answer invalid-request.
Operation 35: An admitted rotate MUST record a successor credential carrying the prior credential's pair.
Operation 36: An admitted rotate MUST stand the successor credential in active.
Operation 37: An admitted rotate MUST stand the prior credential in rotated.
Operation 38: An admitted rotate MUST record now as the prior credential's rotation instant.
Operation 39: An admitted rotate MUST record the successor's credential id as the prior credential's successor credential id.
Operation 41: An admitted rotate MUST answer the successor's credential id.
Operation 58: An admitted rotate MUST assign the successor a fresh credential id.
Operation 59: An admitted rotate MUST record the successor's derived verifier.
Operation 60: An admitted rotate MUST record now as the successor's registration instant.
Operation 61: An admitted rotate MUST record a supplied expiry instant on the successor.
Operation 62: IF expiry instant EQUALS blank AND the default validity DOES NOT EQUAL unbounded THEN an admitted rotate MUST record the default expiry on the successor.
Operation 63: IF now DOES NOT PRECEDE a supplied expiry instant THEN [Rotate] MUST answer invalid-request.
Operation 64: [Rotate] MUST NOT retain new credential material beyond the successor's verifier.
Operation 65: IF a credential beside the credential id is effective-active for the pair THEN [Rotate] MUST answer not-active.
Operation 67: IF the derivation function refuses the new credential material THEN [Rotate] MUST answer invalid-request.
Operation 72: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted rotate MUST record no expiry instant on the successor.
Operation 81: IF a supplied expiry instant is malformed THEN [Rotate] MUST answer invalid-request (Execution Contract Input 1).
```

Term admitted rotate: a [Rotate] call the action admits (Execution Contract Read 4).

Term new credential material: new_credential_material — the material [Rotate] installs in place of the old.

#### Not Active

The refusal [Rotate] returns, after [Not Known] is ruled out, when the credential is not effective-active — either a stored terminal, or standing in [Active] and reading lapsed — or when the credential is effective-active and another credential beside it for the pair is too (Operation 65). Three mechanisms, one answer.

Kind:       Member
Member of:  the Rotate rejection
Role:       Outcome
Projection: not-active

`rotate(cred_unknown, "x")` → not-known. `rotate(cred_c11, "y")` on a reading before 2026-07-01, beside a `register(svc_s03, "z", "api-token")` that took its reading after 2026-07-01 and committed first → not-active: the register found `cred_c11` lapsed and was admitted. The rotate, reading `cred_c11` live, finds the register's credential effective-active beside it (Operation 65).

### Revoke

The transitioning write that cancels a credential, standing it in [Revoked] and recording [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Legal only against an effective-active credential; otherwise [Already Terminal].

Kind: Operation

```
revoke(credential_id, revoked_by_ref, reason)
  answers revoked
  refuses not-known | already-terminal | invalid-request | storage-failure
```

```
Operation 29: IF no effective-active credential EXISTS for the credential id THEN [Revoke] MUST answer already-terminal.
Operation 32: IF revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 33: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 42: An admitted revoke MUST stand the credential in revoked.
Operation 43: An admitted revoke MUST record revoked by reference, reason as revocation reason and now as revocation instant.
Operation 82: An admitted revoke MUST answer revoked.
```

Term admitted revoke: a [Revoke] call the action admits (Execution Contract Read 4).

Term reason: reason — the cause [Revoke] records as the revocation reason.

#### Reason

The revocation reason supplied to [Revoke], recorded as [Revocation Reason]. Required and never blank.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Already Terminal

The refusal [Revoke] returns when the credential is not effective-active. The symmetric counterpart to [Not Active], and it shares that answer's two mechanisms — a stored terminal excludes by what it stores, a lapsed credential by what the clock says.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: already-terminal

`revoke(cred_c07, admin_a01, "  ")` on the already-rotated record → already-terminal, not invalid-request: [Revoke]'s refuses line lists already-terminal first (Execution Contract Refusal 1).

### Read

The read-only query answering the [Credential] records that match a [Filter], each carrying its stored fields — never the [Verifier] — and its derived [Effective Status].

Kind: Operation

```
read(filter)
  answers the matching credentials
```

```
Operation 51: [Read] MUST answer EVERY matching credential.
Operation 52: [Read] MUST answer the effective status PER matching credential.
Operation 53: [Read] MUST NOT answer a verifier.
Operation 54: [Read] MUST NOT record a field.
Operation 69: [Read] MUST order the answer by registration instant, earliest first, and two credentials sharing a registration instant by credential id ascending (Execution Contract Logic confinement 10).
Operation 73: IF a filter names a field whose value EQUALS blank THEN [Read] MUST answer no credential.
Operation 83: IF a filter names a field whose value EXCEEDS the length bound THEN [Read] MUST answer no credential (Execution Contract Query 5).
```

NOTE: watch read-order polarity (Operation 69).

Term filter: principal reference, credential type, credential id, OR any combination of them; a credential matches a filter when it carries EVERY value the filter names and the filter names no other field, so a filter naming no field matches EVERY credential.

#### Filter

The matching criteria supplied to [Read]: a principal reference, a credential type, a credential id, or any combination of them. A credential matches when it carries every value the filter names and the filter names no other field, so a filter naming no field matches every credential. A filter naming a blank value or a value over the length bound matches none (Operation 73, Operation 83).

Kind:         Parameter
Parameter of: Read
Projection:   filter

## What is and what should never be (Invariants)

- **Invariant 2 — Effective-active uniqueness.**
  ```
  Invariant 2.1: Two credentials effective-active at a settled reading MUST NOT share a pair.
  ```
- **Invariant 3 — Sole-holder verification.**
  ```
  Invariant 3.1: [Verify] MUST answer verified ONLY IF the presented material matches the verifier of the credential a proceeding verify checks against PER the check function.
  ```
- **Invariant 4 — Revocation is absorbing.** Invariant 5.1 holds it: revoked is a stored terminal.
- **Invariant 7 — The rotation chain is walkable.**
  ```
  Invariant 7.1: EVERY rotated credential's successor credential id MUST name a credential.
  Invariant 7.2: EVERY rotated credential's successor MUST carry the rotated credential's pair.
  ```
- **Invariant 9 — The revocation record is complete.**
  ```
  Invariant 9.1: EVERY revoked credential MUST carry a non-blank revoked by reference.
  Invariant 9.2: EVERY revoked credential MUST carry a non-blank revocation reason.
  Invariant 9.3: EVERY revoked credential MUST carry a revocation instant.
  ```
- **Invariant 11 — A lapse precludes verification.** Invariant 3.1 holds it: a lapsed credential is not the credential a proceeding verify checks against.
- **Invariant 1 — Registration immutability.**
  ```
  Invariant 1.1: A transitioning write MUST NOT change a property.
  Invariant 1.2: A transitioning write MUST NOT change a terminal field the write found.
  ```
- **Invariant 5 — A stored terminal is absorbing.**
  ```
  Invariant 5.1: A credential whose status IS IN the stored terminals MUST NOT leave the stored terminal.
  ```
- **Invariant 6 — Rotation does not mutate.**
  ```
  Invariant 6.1: An admitted rotate MUST NOT change the prior credential's verifier.
  Invariant 6.2: An admitted rotate MUST NOT change a field of the prior credential beside status, rotation instant and successor credential id.
  ```
- **Invariant 8 — Credential material is never persisted.**
  ```
  Invariant 8.1: The atom MUST NOT answer credential material.
  ```
- **Invariant 10 — Credential durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a credential from the database.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when a credential lapses.
  Invariant 12.2: [Read] MUST compute the effective status from the credential and now.
  ```

## When something happens

### Atomic writes

No rule is owed here: Execution Contract Database 1 and Read 4 own every write's atomicity and a refused call's silence.

### Concurrency

```
Concurrency 5: IF a verify's read PRECEDES a transitioning write's commit THEN the verify MAY answer verified.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer to a credential write MUST NOT retry the credential write BEFORE the caller reads the database (Execution Contract Error model 1).
```

### What undoes a write

A [Register] is undone by a [Revoke], which stands the credential in revoked for good, or by a [Rotate], which stands it in rotated beside a successor. A [Rotate] and a [Revoke] are not undone by this atom: a stored terminal is absorbing (Invariant 5.1) and no reactivate surface exists (State 11), so the caller registers or rotates afresh and the earlier record stays as it was (Execution Contract Undo 4).

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN [Register] MUST answer invalid-request.
String 9: IF a string input EXCEEDS the length bound THEN [Revoke] MUST answer invalid-request.
String 11: IF a string input EXCEEDS the length bound THEN [Verify] MUST answer no-active-credential (Execution Contract Input 2).
```

Term string input: a reference, credential type OR reason — every caller-supplied string this atom accepts beside material.

Term length bound: the maximum length of a string input in Unicode code points; 1,024 code points where a deployment declares none.

Term material bound: the maximum size of one credential type's material, in the measure the deployment declares with the bound; where a deployment declares none for the type, 4,096 units, a unit being a code point of material the call carries as a string and a byte of material the call carries as bytes, summed over the parts of material the call carries as parts (Capability requirement 27).

Term empty material: material that is absent OR of size zero in the measure of the material bound — the material [Register] and [Rotate] refuse as missing (Operation 2, Operation 31); material of whitespace alone is not empty material, since the derivation function owns material's normalization (Capability requirement 28).

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST supply the derivation registry at the seam.
Capability requirement 4: The deployment MUST declare a derivation function PER credential type the deployment serves.
Capability requirement 5: The deployment MUST declare a derivation function whose verifier alone produces no material the check function matches.
Capability requirement 6: The deployment MUST NOT declare two credential types differing only by a foldable difference.
Capability requirement 7: The deployment MUST declare the default validity.
Capability requirement 13: The deployment MUST canonicalize an opaque reference, rewriting every spelling that differs by a foldable difference to one (Execution Contract Logic confinement 13).
Capability requirement 14: The deployment MAY declare the length bound PER Execution Contract Input 2.
Capability requirement 18: The deployment MUST declare a check function PER credential type the deployment serves.
Capability requirement 19: The deployment MUST NOT change the derivation function declared for a credential type a credential carries.
Capability requirement 20: The deployment MUST NOT change the check function declared for a credential type a credential carries.
Capability requirement 24: The deployment MUST supply at the seam the entropy a derivation function consumes (Execution Contract Logic confinement 8).
Capability requirement 25: The host MUST run a derivation function at the seam (Execution Contract Logic confinement 8).
Capability requirement 26: The host MUST run a check function at the seam against the verifier of the credential a proceeding verify checks against (Execution Contract Logic confinement 8).
Capability requirement 27: The deployment MAY declare a material bound and the bound's measure PER credential type PER Execution Contract Input 2.
Capability requirement 28: The derivation function MUST own credential material's normalization.
Capability requirement 29: The deployment MUST declare a check function that matches the material the credential type's derivation function derived the verifier from.
Capability requirement 30: The check function MUST normalize presented material as the credential type's derivation function normalizes credential material of the same kind, and MUST own the normalization of presented material of no such kind.
Capability requirement 31: IF material EXCEEDS the material bound THEN the derivation function MUST refuse the material.
Capability requirement 32: IF presented material EXCEEDS the material bound THEN the check function MUST refuse the presented material.
Capability requirement 34: The deployment MUST supply id material naming no credential of the database instance.
Capability requirement 35: The deployment MUST NOT supply the same id material to two calls (Execution Contract Logic confinement 16).
Capability requirement 37: The deployment MUST supply the credential records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1 and Execution Contract Input 1.
Capability requirement 40: The deployment MUST declare a check function that checks a secret verifier in constant time.
Capability requirement 41: The deployment MUST NOT remove a credential type a credential carries from the derivation registry.
Capability requirement 42: The deployment MUST supply id material in the spelling the deployment's reference canonicalization produces.
```

NOTE: watch the id the host supplies to two calls (Capability requirement 35).

Term seam: the atom's I/O (input and output) boundary as Execution Contract Logic confinement 14 declares it; the host injects the clock reading, the id material, the entropy and the derivation registry here, and runs the registry's derivation and check functions here, injecting each result (Execution Contract Logic confinement 3, 8).

Term transition: the atom's evaluation of one call against the credential records, as Execution Contract Logic confinement 14 declares it.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as Execution Contract Logic confinement 11 declares it — never read inside the transition and never supplied by the business caller. Consumed by the window reading, by a write's stamps, and by [Read]'s [Effective Status] projection.

Kind:         Parameter
Parameter of: Register, Verify, Rotate, Revoke and Read
Projection:   now

Term foldable difference: a difference between two strings that trimming, case-folding OR Unicode normalization would remove.

Term default validity: the duration the deployment declares for a [Register] or [Rotate] carrying no expiry instant, which EXCEEDS zero OR EQUALS unbounded; the credential records the default expiry, and a deployment declaring it unbounded leaves the expiry instant absent.

Term default expiry: (now + default validity) — the expiry instant an admitted register or rotate records when the call supplies none and the default validity DOES NOT EQUAL unbounded (Execution Contract Logic confinement 9).

## Needs

The bond this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets it is the app's choice. Checking presented material is this atom's own rule; who may register, rotate, revoke or read a credential is the app's, gated before the call (Composition note 12 through 16).

Term need key: key actor id; pairs credentials.

## Left to others

```
Non-goal 1: The atom MUST NOT confirm that a principal reference names a proofed party.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom confirms no proofed party, and which pattern proofs one is the app's choice.
Non-goal 3: The atom MUST NOT sequence two credential checks.
Non-goal 4: A deployment needing multi-factor sequencing MUST own the sequencing above this atom.
Non-goal 5: The atom MUST NOT issue a session.
Deleted: Non-goal 6. Non-goal 5 owns it: the atom issues no session, and opening one after a verified answer is the app's sign-in glue.
Non-goal 7: The atom MUST NOT count a failed verify.
Non-goal 8: A deployment needing lockout MUST own the lockout above this atom.
Non-goal 9: The atom MUST NOT decide what a verified principal may do.
Deleted: Non-goal 10. Non-goal 9 owns it: the atom decides nothing a verified principal may do, and which pattern decides is the app's choice.
Non-goal 11: The atom MUST NOT offer a credential recovery flow.
Non-goal 12: The atom MUST NOT bind one credential to two principals.
Non-goal 13: The atom MUST NOT offer bearer delegation.
Non-goal 14: The atom MUST NOT enumerate the admitted credential types.
Non-goal 15: The atom MUST NOT constrain credential material's strength.
Non-goal 16: A deployment needing a material strength floor MUST declare the floor in the derivation function.
Non-goal 17: The atom MUST NOT migrate a verifier to a new derivation function.
Non-goal 18: The atom MUST NOT recover credential material from a verifier.
Non-goal 19: The atom MUST NOT reinterpret a verified answer the atom gave.
Non-goal 20: The atom MUST NOT detect a rewrite under the database.
Deleted: Non-goal 21. Non-goal 20 owns it: the atom detects no rewrite under the database, and which pattern does is the app's choice.
Non-goal 22: The atom MUST NOT bound a credential's retention.
Non-goal 23: The atom MUST NOT decide whether a verifier is special-category data under Article 9 of the European Union's General Data Protection Regulation.
Non-goal 24: The atom MUST NOT record a transition history.
Non-goal 25: The atom MUST NOT record an answer the atom gave.
Non-goal 26: The atom MUST NOT guarantee that a credential reaches a stored terminal.
Non-goal 27: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 28: The atom MUST NOT supply a verifiable time anchor.
Non-goal 29: The atom MUST NOT issue a challenge.
Non-goal 30: A deployment needing a challenge-response check MUST bind the challenge into the presented material above this atom.
Non-goal 31: The atom MUST NOT confirm that a verified signed challenge is fresh.
Non-goal 32: The atom MUST NOT purge a credential.
Non-goal 33: The atom MUST NOT bound the size of a read's answer.
Non-goal 34: The atom MUST NOT confirm that a registering caller holds a public key's private key.
Non-goal 35: A deployment needing proof of possession MUST confirm the proof at the composing enrollment pattern.
Non-goal 36: The atom MUST NOT confirm what a verified signed message was signed for.
Non-goal 37: The atom MUST NOT refuse a rotate to the prior credential's material.
Non-goal 38: The atom MUST NOT define an answer to a fault in a function the derivation registry declares.
Non-goal 39: The atom MUST NOT bound the cost of guessing a verifier.
```

NOTE: the owners — a pattern that discloses a compromise (Non-goal 19, Composition note 11); Execution Contract Logic confinement 7 (Non-goal 27); the deployment (Non-goal 11, Non-goal 14, Non-goal 17, Non-goal 23, Non-goal 26, Non-goal 37, Composition note 17); the host (Non-goal 38); the derivation function (Non-goal 18, Non-goal 39, External check 14); patterns the app chooses: one that proofs a party (Non-goal 1), issues a session (Non-goal 5), decides what a principal may do (Non-goal 9), delegates by bearer token (Non-goal 13), keeps an event log (Non-goal 24, Non-goal 25), detects a rewrite (Non-goal 20), bounds retention (Non-goal 22), supplies a verifiable time anchor (Non-goal 28), issues and spends challenges (Non-goal 29, Non-goal 31, Non-goal 36) and purges lawfully (Non-goal 32); the composing pattern that exposes [Read] (Non-goal 33, Composition note 16).

```
Deleted: Composition note 1. The app's sign-in glue owns it: a session opens after a verified answer, and the atom issues none (Non-goal 5).
Deleted: Composition note 3. The app's glue owns it: what a revoked credential ends beyond itself is the app's to call.
Composition note 4: A composing pattern that enrolls a party MUST call [Register] ONLY AFTER the party's record EXISTS.
Composition note 5: A composing pattern that keeps an event log MUST append an event on EVERY admitted action.
Composition note 6: A composing pattern that keeps an event log MUST append an event on EVERY refused action.
Composition note 7: A composing pattern that keeps an event log MUST append an event on EVERY verify answer.
Composition note 8: A composing pattern that attests actions MUST attest the principal behind a verified answer.
Composition note 9: A composing pattern that makes records tamper-evident MUST cover EVERY credential the database holds.
Composition note 10: A composing pattern that makes records tamper-evident MUST NOT expose a verifier.
Composition note 11: A composing pattern that discloses a compromise MUST record a new credential rather than change a credential.
Composition note 12: A composing pattern MUST call [Register] ONLY AFTER authenticating an authorized caller.
Composition note 13: A composing pattern MUST call [Rotate] ONLY AFTER authenticating an authorized caller.
Composition note 14: A composing pattern MUST call [Revoke] ONLY AFTER authenticating an authorized caller.
Composition note 15: A composing pattern MUST pass the authenticated caller as revoked by reference.
Composition note 16: A composing pattern MUST expose [Read] ONLY AFTER authorizing the caller.
Composition note 17: A deployment refusing reused secret material MUST call [Rotate] ONLY AFTER a verify of the new material against the pair answers material-mismatch.
Composition note 18: A composing pattern that purges by retention MUST purge a rotation chain whole.
```

Term authorized caller: a caller authenticated as the principal the call names — for [Rotate] and [Revoke], which name a credential id, the principal that credential carries; for a principal holding no effective-active credential, a lapsed credential's principal among them, a caller authenticated by a composing enrollment pattern's own proof, as an invitation's; OR a caller authenticated as an actor a composing permission decision authorizes over that principal, with the decision's subject bound to that authenticated actor.

Term credential write: [Register] | [Rotate] | [Revoke].

NOTE: composing patterns — an app names the atoms it composes; this pattern names none.

## Example

### Password authentication — registration and verification

`register(user_u91, "correct horse battery staple", "password")` → `cred_c01`, standing active with no deadline on a deployment declaring the default validity unbounded (Operation 71). The material is derived to a verifier and discarded; nothing in the database holds it. Later, `verify(user_u91, "password", "correct horse battery staple")` → verified. `verify(user_u91, "password", "hunter2")` → `failed-verification(material-mismatch)`.

### Programming-interface token — rotation

`register(svc_s03, <token>, "api-token", 2026-04-01)` → `cred_c07`. On a quarterly policy the service rotates before the deadline: `rotate(cred_c07, <new token>, 2026-07-01)` → `cred_c11`. `cred_c11` stands active with its own verifier, registration instant and deadline, and `cred_c07` stands rotated carrying rotation instant and `successor_credential_id: cred_c11`. An auditor walks `cred_c07 → cred_c11` and reads how long each credential served, from its registration instant to its rotation instant.

### The deadline passes

`cred_c11` carries `expires_at: 2026-07-01`. At 2026-07-01 exactly it already reads lapsed — the boundary instant is on the lapsed side. On 2026-07-02 nothing has happened to the record: it still stands active, carries no terminal field, and read returns it with an effective status of expired. verify against the pair answers no-active-credential; `rotate(cred_c11, …)` answers not-active; `revoke(cred_c11, …)` answers already-terminal — each by reading, each writing nothing. And because `cred_c11` no longer occupies the slot, `register(svc_s03, <material>, "api-token", 2026-10-01)` succeeds as `cred_c15`, leaving two records standing active for the pair, exactly one of them effective-active.

### Public key — a signed challenge

`register(svc_s04, <Ed25519 public key>, "public-key")` → `cred_c20`; the verifier is the key's canonical encoding (Ed25519 is an elliptic-curve signature scheme). A composing pattern issues a challenge and the holder signs it: `verify(svc_s04, "public-key", {challenge, signature})` → verified. The same signature presented again also answers verified — this atom does not know the challenge was used (Non-goal 31, 36) — which is why a deployment composes a challenge pattern that refuses a spent one.

### Revocation after exposure

Tokens for `svc_s03` turn up in a log file. `revoke(cred_c15, admin_a01, "log-exposure-2026-09-12")` → revoked, stamping revocation instant, revoked by reference and revocation reason. A later auditor reading only the database knows when, why and whom the caller named, without asking anyone; that the named actor was the caller is the composing pattern's to show (Composition note 15).

### Regulated adversarial scenarios

- **Regulator audit.** *Was the service account's programming-interface credential rotated inside the ninety-day window?* Filter the database to the pair and order by registration instant; each rotated record carries rotation instant and a link forward. Invariant 7.1 and Invariant 7.2 are what make each link sound rather than merely plausible — every rotated record's link names a credential, and no link leaves the pair.
- **Disputed transaction.** *I did not log in from that address.* The composing sign-in records name the credential used; these records show that credential's standing and registration instant. Invariant 3.1 is the structural rebuttal: if verified was answered, the presented material matched the recorded verifier. Whether the caller was the principal or someone holding their secret is a separate investigation, and this atom's records bound its window.
- **Breach investigation.** A batch of tokens may have been exposed. Filter to the pair, read each effective status against the investigation clock, and revoke what is still effective-active. Invariant 9.1 through 9.3 are what make the resulting record's answer to *when, why, and whom the caller named* provable; that the named actor was the authenticated caller is the composing pattern's to prove (Composition note 15, External check 10).

## Source

- **NIST SP 800-63B-4 (the US National Institute of Standards and Technology's Special Publication 800-63B, authentication and authenticator management, revision 4)** — the primary standard here. Authenticator assurance levels, stored verifiers rather than raw secrets (the salt supplied at the seam when the function consumes one, Capability requirement 24, and the cost the derivation function's own, neither of which the atom requires, Non-goal 39), and rotation and revocation requirements correspond directly to this atom's rules. The correspondence is to 800-63B's *verifier storage and lifecycle* half specifically; the *authenticator strength* half — minimum length, breached-password screening, entropy floors — is not enforceable here and lives in the derivation function (Non-goal 15, Non-goal 16). Identity proofing is 800-63A's and is deliberately not cited: that is [Party Identity](./party-identity.md)'s.
- **FIDO2 (the FIDO Alliance's second authentication standard) / WebAuthn (W3C — the World Wide Web Consortium — Web Authentication Level 2)** — for phishing-resistant hardware authenticators. A `fido2` [Credential Type] takes the attestation object as [Credential Material]; the [Verifier] is the public key extracted from it, and [Verify] checks a presented assertion against it through the type's check function; the challenge the assertion signs is a composing pattern's (Non-goal 30).
- **RFC 7519 (the Internet Engineering Task Force's Request for Comments 7519, JSON Web Token, JSON being JavaScript Object Notation)** — an `api-token` [Credential Type] stores a hash of the raw token as its [Verifier]. The atom does not interpret token claims; that is the composing pattern's.
- **OpenID Connect (OIDC) Core 1.0** — the OIDC login flow ends in a verification this atom answers, and the verification event itself is a composing event log's (Composition note 7).
- **PCI DSS (the Payment Card Industry Data Security Standard) Requirement 8 (identify and authenticate access)** — the atom satisfies the structural requirements: one effective-active credential per pair, rotation producing a new record, revocation recorded with the attribution the caller supplies. The rotation period is not enforced here: the default validity (Capability requirement 7) is a default that a supplied expiry overrides, so the atom bounds no credential's lifetime and a deployment needing a maximum age enforces it in the pattern that schedules its rotations. Complexity rules and the lockout threshold are likewise the deployment's (Non-goal 8, Non-goal 16).
- **ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 27001:2022 Annex A controls 5.17 (authentication information) and 8.5 (secure authentication)** — the registration, rotation and revocation lifecycle corresponds to the authentication-information controls there; the 2013 edition's A.9.4 is the superseded numbering.
- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 32 (security of processing)** — State 9, State 10 and the one-way verifier discipline contribute to the technical measures Article 32 requires. A deployment storing a biometric verifier assesses Article 9 separately (Non-goal 23).
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (person or entity authentication)** — the verified answer is the structural mechanism for this requirement.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing identity proofing, sessions, authorization and multi-factor orchestration as separate atoms rather than absorbing them here.
- **NIST 800-132 (password-based key derivation)** — the reference for which derivation functions satisfy the one-way property Capability requirement 5 requires.

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the credential records, with their committed versions (Execution Contract Generation acceptance 1), and a read-time clock.

#### Conformance checks

```
Check 1.1: An auditor MUST find no two effective-active credentials sharing a pair, at a settled reading the auditor supplies (Invariant 2.1, Operation 65).
Check 1.2: An auditor MUST read effective-active from the window reading and NOT from the stored status (Operation 8, Invariant 2.1).
Check 2.1: An auditor MUST find no credential storing expired as a status (State 6).
Check 2.2: An auditor MUST find no credential carrying a lapse instant (State 7, Invariant 12.1).
Check 2.3: An auditor MUST reproduce a [Read] answer's effective status from the credential and a clock the auditor supplies (Invariant 12.2).
Check 3.1: An auditor MUST find a successor credential id naming a credential on EVERY rotated credential (Invariant 7.1).
Check 3.2: An auditor MUST find EVERY rotated credential's successor carrying the rotated credential's pair (Invariant 7.2).
Check 3.3: An auditor MUST find a rotation instant on EVERY rotated credential (State 3).
Check 4.1: An auditor MUST find a non-blank revoked by reference on EVERY revoked credential (Invariant 9.1).
Check 4.2: An auditor MUST find a non-blank revocation reason on EVERY revoked credential (Invariant 9.2).
Check 4.3: An auditor MUST find a revocation instant on EVERY revoked credential (Invariant 9.3).
Check 5.1: An auditor MUST find no credential material beyond the verifier in a credential (State 9).
Check 5.2: An auditor MUST find no presented material in a credential (State 10).
Check 5.3: An auditor MUST find no verifier in a [Read] answer (Operation 53, State 8).
Check 5.4: An auditor MUST find no credential material in a [Read] answer (Invariant 8.1).
Check 6.1: An auditor MUST find no credential leaving a stored terminal across two committed versions of the credential (Invariant 5.1; Execution Contract Generation acceptance 1).
Check 6.2: An auditor MUST find no terminal field on an active credential (State 5).
Check 7.1: An auditor MUST find EVERY credential's properties unchanged across EVERY committed version of the credential (Invariant 1.1, Invariant 6.1; Execution Contract Generation acceptance 1).
Check 7.2: An auditor MUST find EVERY terminal field a credential carries unchanged across EVERY committed version of the credential carrying the field (Invariant 1.2; Execution Contract Generation acceptance 1).
Check 7.3: An auditor MUST find EVERY rotated credential's fields beside status, rotation instant and successor credential id unchanged across EVERY committed version of the credential (Invariant 6.2; Execution Contract Generation acceptance 1).
Check 8.1: An auditor MUST find an unfiltered read answering EVERY credential with a committed version (Invariant 10.1; Execution Contract Generation acceptance 1).
Check 9.1: An auditor MUST reconstruct EVERY credential of one pair from the database (State 1, Invariant 10.1).
Check 10.1: An auditor MUST find no two credentials sharing a credential id (Identity 5).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: A deployment needing credential material confirmed absent from a log MUST read the deployment's own logging (State 9, State 10).
External check 2: A deployment needing a check confirmed constant-time over a secret verifier MUST read the implementation (Capability requirement 40).
External check 3: A deployment needing a verifier confirmed unable to produce matching material MUST read the derivation registry (Capability requirement 5).
External check 4: A deployment needing a verify answer observed MUST read the composing pattern's event log (Non-goal 25).
External check 5: A deployment needing a principal reference bound to a real party MUST read the composing pattern's identity proofing (Non-goal 1).
External check 6: A deployment needing a failed verify counted MUST read the deployment's own lockout surface (Non-goal 8).
External check 7: A deployment needing the database confirmed free of a retroactive edit MUST read the composing pattern's tamper evidence (Non-goal 20).
External check 8: A deployment needing a verified answer confirmed against the credential's standing MUST read the composing pattern's event log of verify events beside the database (Invariant 3.1).
External check 10: A deployment needing a revoked by reference confirmed as the authenticated caller MUST read the composing pattern's authentication (Composition note 15).
External check 11: A deployment needing a credential write confirmed to an authorized caller MUST read the composing pattern's authentication (Composition note 12 through 14).
External check 12: A deployment needing [Read] confirmed to an authorized caller MUST read the composing pattern's authorization (Composition note 16).
External check 13: A deployment needing a check function confirmed to match the credential type's derivation function MUST check material against the verifier derived from the material (Capability requirement 29, 30).
External check 14: A deployment needing a verifier salted and costly to guess confirmed MUST read the derivation registry (Non-goal 39).
External check 15: A deployment needing one effective-active credential per principal confirmed across spellings MUST read the deployment's own reference canonicalization and credential type declarations (Capability requirement 6, Capability requirement 13).
External check 16: A deployment needing each id material confirmed supplied to one call MUST read the deployment's own id allocation (Capability requirement 35).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the deployment; the host; the implementation; the database; the seam; the transition; a composing pattern; a caller; a principal; an auditor; a regulator; an investigator; a reader; a credential; an active credential; an effective-active credential; a lapsed credential; a rotated credential; a revoked credential; a successor credential; a prior credential; an action; a transitioning write; a refused action; a rejection; an answer; a derivation function; an opaque reference; a string input; a filter.

Term records: credential — one principal's binding to one verifier for one credential type, carrying credential id, principal reference, credential type, verifier, registration instant, a status and, where supplied or set, expiry instant, rotation instant, successor credential id, revocation instant, revoked by reference and revocation reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, commit, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, canonicalize, declare, compose, remove, bind, decide, define, bound, reach, accept, retain, trim, case-fold, compute, reproduce, reconstruct, verify, issue, detect, guarantee, take, derive, expose, store, own, persist, enumerate, distinguish, select, walk, mutate, serialize, rotate, revoke, block, invalidate, migrate, recover, reinterpret, constrain, count, sequence, run, rebind, check, order, lower, retry, authorize, purge, evaluate.

Term value sets: status = active | rotated | revoked. effective status = active | rotated | revoked | expired. verification failure = material-mismatch | no-active-credential. stored terminal = rotated | revoked. window reading = live | lapsed. property = principal reference | credential type | verifier | registration instant | expiry instant. terminal field = rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason.

Term bounds: default validity, length bound, material bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: credential, credential id, lapse instant, pair, property, reference, database instance, seam, transition, now, transitioning write, stored terminal, status, window reading, live, lapsed, effective-active credential, lapsed credential, proceeding verify, effective status, verifier, derivation function, derivation registry, foldable difference, length bound, material bound, default validity, check function, filter, fresh credential id, authorized caller, credential write, secret verifier, constant time, settled reading, terminal field, admitted register, admitted rotate, admitted revoke, string input, verification failure, default expiry, empty material, id material, committed version.

Term cited: Execution Contract Logic confinement 14 — the seam and the transition. actor id: Declarations.

Term composing pattern: whatever pattern an app composes beside this atom; this pattern names none.

Term credential types: credential_types — the credential kinds a deployment declares.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Register]: #register
[Verify]: #verify
[Rotate]: #rotate
[Revoke]: #revoke
[Read]: #read
[Credential]: #credential
[Credential Id]: #credential-id
[Principal Reference]: #principal-reference
[Credential Type]: #credential-type
[Verifier]: #verifier
[Status]: #status
[Registration Instant]: #registration-instant
[Expiry Instant]: #expiry-instant
[Rotation Instant]: #rotation-instant
[Successor Credential Id]: #successor-credential-id
[Revocation Instant]: #revocation-instant
[Revoked By Reference]: #revoked-by-reference
[Revocation Reason]: #revocation-reason
[Effective Status]: #effective-status
[Credential Material]: #credential-material
[Presented Material]: #presented-material
[Filter]: #filter
[Reason]: #reason
[Now]: #now
[Active]: #active
[Rotated]: #rotated
[Revoked]: #revoked
[Expired]: #expired
[Material Mismatch]: #material-mismatch
[No Active Credential]: #no-active-credential
[Invalid Request]: #invalid-request
[Duplicate Active Credential]: #duplicate-active-credential
[Not Known]: #not-known
[Not Active]: #not-active
[Already Terminal]: #already-terminal
[Storage Failure]: #storage-failure

---

## Status

`done — 2026-11-25` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-25
formal: verified — credential.tla + 6 twins (2026-09-29); credential.als + 13 twins (the static data model, 2026-11-11: Invariant 3.1, 5.1, 7.1, 7.2, 9.1, 9.2, 9.3, State 3, 5, 9 and Identity 5 checked on every record an admitted [Register], [Rotate] or [Revoke] leaves and on every answer [Verify] gives over such records, Invariant 3.1 checking the cases of the deleted 4.1 and 11.1, Invariant 5.1 read off one record, Invariant 7.1 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1, 6 and 10 or for 5.1 across versions: each compares a credential with a later version of it, which a single state cannot show, and Invariant 2.1 rests on the order of the calls that wrote the pair's records, so they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes TLA+ checks of Invariant 1 and 6 (across steps); owed rows: Invariant 1; Invariant 6, 2026-11-11
last gate: 2026-11-25 — Final Critique 25 (delta), one reader (Linus opencode/beam-free), frozen at 4b89d32b — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim, Invariant 12.2 and Check 2.3 computing the effective status from expiry instant and now alone, placed refining by both triages since Term effective status and Operation 52 already answer the stored status of a terminal credential, so no conforming build answers expired for one; cured by naming the credential among the inputs in both rules and in the Expiry Instant entry, and the finder's restatement of the Term in the rule was not applied; refining decided with no edit: Operation 70's tie-break (cured foundational in Final Critique 24), Operation 29's already-terminal for a lapsed credential (the Already Terminal entry and the lapsed example say it) and Invariant 1.2 as a stated guard; 2026-11-25 — Final Critique 24 (delta), one reader (Linus opencode/beam-free), frozen at 78805e2a — foundational count 2, cured, not clean, no sample; 2026-11-20 — Final Critique 23, three readers (GRID opencode/beam-free, EOS anthropic/claude-sonnet-5-5, Linus opencode/minimax-m3), frozen at 91c6335e — foundational count 3, cured, not clean, no sample; 2026-11-02 — Final Critique 22 (delta) — foundational count 0, clean, one sample; 2026-10-29 — Final Critique 21, frozen at cf02362 — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./credential.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/credential.md`.

</details>

NOTE: End of Credential.

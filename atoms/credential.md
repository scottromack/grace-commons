---
title: Credential
parent: Atomic Concepts
has_toc: true
toc: true
---

# Credential

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Credential answers one question: *does this presented material belong to this principal, for this kind of credential?* A principal is whatever entity is being authenticated — a user, a service account, a system actor.

It works through records that bind a principal to a **verifier**: an artifact derived from the secret material — a hashed password, a public key — from which no matching material can be produced, and which lets the system check a later presentation without ever keeping the original secret. The raw material is used at registration and at each check, then discarded. Only the verifier persists.

Each record stands in one open status, active, or in one of two permanent stored ends: rotated (replaced by a newer credential) or revoked (deliberately cancelled, with when, why and whom the caller named recorded). A credential also *expires* — but expiry is not a stored status. When the deadline passes, a still-active record is simply shown expired, computed at read time from the deadline and the clock, never written.

One principal reference holds at most one *effective-active* credential of a given type at a time — as the deployment canonicalizes references and declares types (Capability requirement 6, Capability requirement 13) — where effective-active means stored active **and** not past its deadline. A lapsed record no longer occupies that slot, so a fresh registration is permitted beside it. Rotation is clean: the successor is a new record and the predecessor moves to rotated carrying a link forward, so the whole chain of replacements is walkable.

This is the mechanism behind password login, public-key authentication (safe against a captured answer being sent again only when a composing pattern issues a fresh challenge each time), programming-interface tokens (secrets a program presents to a service in place of a person) and hardware keys. Proving who the principal is in the first place, sequencing multiple factors, keeping someone logged in, and deciding what they may do are each a separate pattern.

---

## Intent

Authenticated systems require an actor to prove identity before acting with consequence — moving funds, prescribing medication, signing a contract, reaching a protected record. The proof is a credential: something the actor knows, something the actor has, or something the actor is. What is constant across all three is the *binding* — the association between a specific principal and specific material, established at registration and queryable at verification.

This atom isolates that binding. It does not implement login flows, sessions, identity proofing, multi-factor orchestration or authorization. The answer it gives is binary — verified, or a named reason it was not — and it is answerable from stored records, the presented material, the deployment's check function and a clock, without the system's runtime state and without the calling actor's testimony.

This is a freestanding atom in the EOS (Essence of Software, Daniel Jackson's concept design) sense: its own state, its own three writes and two reads, and its own operational principles — verifiers are stored and material is not, rotation produces a new record, a stored terminal is absorbing, and expiry is derived.

---

## Structure

### Identity model

```
Identity 1: The atom MUST identify a credential by the credential id.
Identity 2: The atom MUST assign the credential id from the id material the seam supplies.
Identity 3: The atom MUST NOT generate a credential id.
Identity 4: The atom MUST NOT change a credential's credential id.
Identity 5: Two credentials MUST NOT share a credential id.
Identity 6: The atom MUST NOT identify a credential by the pair.
Identity 7: The atom MUST compare a reference byte-exactly.
Identity 8: The atom MUST NOT normalize a reference.
Identity 9: The atom MUST NOT confirm that a principal reference names a known principal.
Identity 10: The atom MUST NOT confirm that a revoked by reference names a known actor.
Identity 11: The atom MUST confirm that a credential type names a derivation function in the derivation registry.
Deleted: Identity 12. Capability requirement 33 owns it.
Deleted: Identity 13. Capability requirement 34 owns it.
Deleted: Identity 14. Capability requirement 35 owns it.
Deleted: Identity 15. Capability requirement 36 owns it.
```

Term credential: the record this atom holds — one principal's binding to one verifier, for one credential type.

Term fresh credential id: a credential id naming no credential of the database instance, assigned from the id material the seam supplies (Capability requirement 34, 35).

Term credential id: the opaque value naming one credential — a [Credential Id]; assigned from the id material the seam supplies.

Term pair: principal reference and credential type together — the key the effective-active bound ranges over.

Term property: principal reference | credential type | verifier | registration instant | expiry instant — what a credential carries from registration and never changes.

Term reference: credential id, principal reference, revoked by reference OR successor credential id — every opaque reference this atom records.

Term database instance: one named database a call is routed to; credential id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the id material, the entropy and the derivation registry here, and runs the registry's derivation and check functions here, since both are cryptography (Execution Contract Logic confinement 1, 3).

Term transition: the atom's evaluation of one call against the credential records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

### State

```
State 1: EVERY credential MUST carry credential id, principal reference, credential type, verifier, registration instant and a status.
State 2: A credential MAY carry an expiry instant.
State 3: EVERY rotated credential MUST carry rotation instant and successor credential id.
State 4: EVERY revoked credential MUST carry revocation instant, revoked by reference and revocation reason.
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
State 15: The atom MUST NOT lower the database instance's credential count.
```

Term lapse instant: an instant a database writes when a credential starts to read lapsed, beside a status that stays active — the materialized lapse; never stored here, because lapse is read, not written.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST supply the derivation registry at the seam.
Capability requirement 4: The deployment MUST declare a derivation function PER credential type the deployment serves.
Capability requirement 5: The deployment MUST declare a derivation function whose verifier alone produces no material the check function matches.
Capability requirement 6: The deployment MUST NOT declare two credential types differing only by a foldable difference.
Capability requirement 7: The deployment MUST declare the default validity.
Deleted: Capability requirement 8. Execution Contract Database 2 owns it.
Deleted: Capability requirement 9. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 10. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 11. Execution Contract Database 3 owns it.
Deleted: Capability requirement 12. Execution Contract Database 1 owns it.
Capability requirement 13: The deployment MUST canonicalize an opaque reference, rewriting every spelling that differs by a foldable difference to one.
Capability requirement 14: The deployment MUST declare the length bound in Unicode code points.
Deleted: Capability requirement 15. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 16. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 27 owns it.
Deleted: Clock semantics 7. Non-goal 28 owns it.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it.
Capability requirement 18: The deployment MUST declare a check function PER credential type the deployment serves.
Capability requirement 19: The deployment MUST NOT change the derivation function declared for a credential type a credential carries.
Capability requirement 20: The deployment MUST NOT change the check function declared for a credential type a credential carries.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to lease.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: the pair's check and write are one transaction, and the atom names no section to release.
Deleted: Capability requirement 23. Execution Contract Database 2 owns it.
Capability requirement 24: The deployment MUST supply at the seam the entropy a derivation function consumes.
Capability requirement 25: The host MUST run a derivation function at the seam.
Capability requirement 26: The host MUST run a check function at the seam against the verifier of the effective-active credential the transition read.
Capability requirement 27: The deployment MUST declare a material bound PER credential type.
Capability requirement 28: The derivation function MUST own credential material's normalization.
Capability requirement 29: The deployment MUST declare a check function that matches the material the credential type's derivation function derived the verifier from.
Capability requirement 30: The check function MUST normalize presented material as the credential type's derivation function normalizes credential material.
Capability requirement 31: The derivation function MUST refuse material the material bound EXCEEDS.
Capability requirement 32: The check function MUST refuse presented material the material bound EXCEEDS.
Capability requirement 33: The deployment MUST route EVERY call naming one pair to the same database instance.
Capability requirement 34: The deployment MUST supply id material naming no credential of the database instance.
Capability requirement 35: The deployment MUST NOT supply the same id material to two calls.
Capability requirement 36: The deployment MUST route EVERY call naming a credential id to the database instance that assigned the credential id.
Capability requirement 37: The deployment MUST supply the credential records PER Execution Contract Database 1 through 4, Execution Contract Read 1 through 3 and Execution Contract Refusal 1.
Capability requirement 38: The deployment MUST NOT supply blank id material.
Capability requirement 39: The credential id assigned from the id material MUST NOT EXCEED the length bound.
```

### Operations

```
register(principal_ref, credential_material, credential_type, optional expires_at)
  answers credential_id
  refuses invalid-request | duplicate-active-credential | storage-failure

verify(principal_ref, credential_type, presented_material)
  answers verified | failed-verification(verification failure)

rotate(credential_id, new_credential_material, optional expires_at)
  answers new_credential_id
  refuses not-known | not-active | invalid-request | storage-failure

revoke(credential_id, revoked_by_ref, reason)
  answers revoked
  refuses not-known | already-terminal | invalid-request | storage-failure

read(filter)
  answers the matching credentials
```

Term verification failure: material-mismatch | no-active-credential — the reasons [Verify] gives for a failed verification.

```
Operation 1: IF principal reference EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 2: IF credential material EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 3: IF credential type EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 4: IF the credential type names no derivation function THEN [Register] MUST answer invalid-request.
Operation 5: IF now DOES NOT PRECEDE a supplied expiry instant THEN [Register] MUST answer invalid-request.
Operation 6: IF an effective-active credential EXISTS for the pair THEN [Register] MUST answer duplicate-active-credential.
Deleted: Operation 7. Execution Contract Refusal 1 owns it.
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
Operation 18: IF no effective-active credential EXISTS for the pair THEN [Verify] MUST answer no-active-credential.
Operation 19: [Verify] MUST NOT distinguish the reason no effective-active credential EXISTS for the pair.
Operation 20: [Verify] MUST NOT check presented material BEFORE the window reading.
Operation 21: A proceeding verify MUST check the presented material against the recorded verifier PER the credential type's check function.
Operation 22: IF the check function answers no match THEN [Verify] MUST answer material-mismatch.
Operation 23: IF the check function answers a match THEN [Verify] MUST answer verified.
Operation 24: A proceeding verify MUST check a secret verifier in constant time.
Operation 25: [Verify] MUST NOT retain presented material.
Operation 26: [Verify] MUST NOT record a field.
Operation 27: IF the credential id names no credential THEN a transitioning write MUST answer not-known.
Operation 28: IF no effective-active credential EXISTS for the credential id THEN [Rotate] MUST answer not-active.
Operation 29: IF no effective-active credential EXISTS for the credential id THEN [Revoke] MUST answer already-terminal.
Deleted: Operation 30. Execution Contract Refusal 1 owns it.
Operation 31: IF new credential material EQUALS blank THEN [Rotate] MUST answer invalid-request.
Operation 32: IF revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 33: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Deleted: Operation 34. Execution Contract Refusal 1 owns it.
Operation 35: An admitted rotate MUST record a successor credential carrying the prior credential's pair.
Operation 36: An admitted rotate MUST stand the successor credential in active.
Operation 37: An admitted rotate MUST stand the prior credential in rotated.
Operation 38: An admitted rotate MUST record now as the prior credential's rotation instant.
Operation 39: An admitted rotate MUST record the successor's credential id as the prior credential's successor credential id.
Deleted: Operation 40. Execution Contract Database 1 owns it.
Operation 41: An admitted rotate MUST answer the successor's credential id.
Operation 42: An admitted revoke MUST stand the credential in revoked.
Operation 43: An admitted revoke MUST record revoked by reference, reason as revocation reason and now as revocation instant.
Deleted: Operation 44. Execution Contract Database 1 owns it.
Operation 45: IF the database refuses the write THEN an action MUST answer storage-failure.
Deleted: Operation 46. Execution Contract Refusal 1 owns it.
Operation 47: A refused action MUST leave the credential as the call found the credential.
Operation 48: A refused [Register] MUST NOT record a credential.
Operation 49: A refused [Rotate] MUST NOT record a successor credential.
Operation 50: The atom MUST NOT offer an expire action.
Operation 51: [Read] MUST answer EVERY matching credential.
Operation 52: [Read] MUST answer the effective status PER matching credential.
Operation 53: [Read] MUST NOT answer a verifier.
Operation 54: [Read] MUST NOT record a field.
Deleted: Operation 55. Operation 51 and Execution Contract Read 2 own it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Operation 58: An admitted rotate MUST assign the successor a fresh credential id.
Operation 59: An admitted rotate MUST record the successor's derived verifier.
Operation 60: An admitted rotate MUST record now as the successor's registration instant.
Operation 61: An admitted rotate MUST record a supplied expiry instant on the successor.
Operation 62: IF expiry instant EQUALS blank AND the default validity DOES NOT EQUAL unbounded THEN an admitted rotate MUST record the default expiry on the successor.
Operation 63: IF now DOES NOT PRECEDE a supplied expiry instant THEN [Rotate] MUST answer invalid-request.
Operation 64: [Rotate] MUST NOT retain new credential material beyond the successor's verifier.
Operation 65: IF a credential beside the credential id is effective-active for the pair THEN [Rotate] MUST answer not-active.
Operation 66: IF the derivation function refuses the credential material THEN [Register] MUST answer invalid-request.
Operation 67: IF the derivation function refuses the new credential material THEN [Rotate] MUST answer invalid-request.
Operation 68: IF the check function refuses the presented material THEN [Verify] MUST answer material-mismatch.
Operation 69: [Read] MUST order the answer by registration instant, then by credential id.
Operation 70: IF two credentials of the pair are effective-active at the verify's reading THEN a proceeding verify MUST check against the one carrying the later registration instant.
Operation 71: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted register MUST record no expiry instant.
Operation 72: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted rotate MUST record no expiry instant on the successor.
Operation 73: IF a filter names a field whose value EQUALS blank THEN [Read] MUST answer no credential.
Deleted: Operation 74. Execution Contract Read 1 owns it.
Deleted: Operation 75. Execution Contract Refusal 1 owns it.
Deleted: Operation 76. Execution Contract Refusal 1 owns it.
Deleted: Operation 77. Execution Contract Refusal 1 owns it.
```

Term transitioning write: [Rotate] | [Revoke] — every call that would take an effective-active credential to a stored terminal, including a refused one.

Term stored terminal: rotated | revoked.

Term status: active | rotated | revoked — the value a credential stores.

Term window reading: live | lapsed — how an active credential's window reads against now.

Term live: the window reading of an active credential whose expiry instant EQUALS blank, OR that now PRECEDES.

Term lapsed: the window reading of an active credential whose expiry instant DOES NOT EQUAL blank and that now DOES NOT PRECEDE; the boundary instant — expiry instant equal to now — reads lapsed.

Term secret verifier: a verifier whose disclosure helps a caller produce matching material — a password hash, a token hash; a public key is not one.

Term settled reading: a reading of now that no registration instant of the pair follows — the only reading at which Invariant 2.1 and Check 1.1 judge a pair's credentials together; an earlier reading judges the pair's credentials as the call finds them.

Term effective-active credential: a credential whose status EQUALS active that reads live — what every bound, guard and lookup in this atom means by *the active credential*.

Term lapsed credential: a credential whose status EQUALS active that reads lapsed.

Term proceeding verify: a [Verify] call whose pair carries an effective-active credential.

Term effective status: expired where the credential reads lapsed, and the stored status otherwise — a projection over the credential and now, never stored.

Term verifier: the artifact a derivation function produces from credential material — what this atom stores in place of the material.

Term derivation function: the deployment's function from material to a verifier, declared for one credential type; the verifier alone produces no material the type's check function matches.

Term derivation registry: the deployment's declared map from a credential type to a derivation function and a check function; supplied at the seam.

Term foldable difference: a difference between two strings that trimming, case-folding OR Unicode normalization would remove.

Term default validity: the duration the deployment declares for a [Register] or [Rotate] carrying no expiry instant, which EXCEEDS zero OR EQUALS unbounded; the credential records now plus it, and a deployment declaring it unbounded leaves the expiry instant absent.

Term default expiry: now plus the default validity — the expiry instant an admitted register or rotate records when the call supplies none and the default validity DOES NOT EQUAL unbounded.

Term check function: the deployment's function, declared for one credential type beside its derivation function, answering whether presented material matches a recorded verifier.

Term filter: principal reference, credential type, credential id, OR any combination of them; a credential matches a filter when it carries EVERY value the filter names, so a filter naming no field matches EVERY credential.

Term terminal field: rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason — every field a transitioning write records.

Term admitted register: a [Register] call that passes every precondition and whose database write commits.

Term admitted rotate: a [Rotate] call that passes every precondition and whose database writes commit.

Term admitted revoke: a [Revoke] call that passes every precondition and whose database write commits.

### Invariants

- **Invariant 1 — Registration immutability.**
  ```
  Invariant 1.1: A transitioning write MUST NOT change a property.
  Invariant 1.2: A transitioning write MUST NOT change a terminal field the write found.
  ```
- **Invariant 2 — Effective-active uniqueness.**
  ```
  Invariant 2.1: Two credentials effective-active at a settled reading MUST NOT share a pair.
  ```
- **Invariant 3 — Sole-holder verification.**
  ```
  Invariant 3.1: [Verify] MUST answer verified ONLY IF the presented material matches the verifier of the effective-active credential of the pair the call names PER the check function.
  ```
- **Invariant 4 — Revocation is absorbing.**
  ```
  Deleted: Invariant 4.1. Invariant 3.1 owns it: a verify answers verified only against the effective-active credential, which a revoked credential is not.
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
- **Invariant 7 — The rotation chain is walkable.**
  ```
  Invariant 7.1: EVERY rotated credential's successor credential id MUST name a credential.
  Invariant 7.2: EVERY rotated credential's successor MUST carry the rotated credential's pair.
  ```
- **Invariant 8 — Credential material is never persisted.**
  ```
  Invariant 8.1: The atom MUST NOT answer credential material.
  Deleted: Invariant 8.2. Capability requirement 5 owns the one-way derivation function.
  ```
- **Invariant 9 — The revocation record is complete.**
  ```
  Invariant 9.1: EVERY revoked credential MUST carry a non-blank revoked by reference.
  Invariant 9.2: EVERY revoked credential MUST carry a non-blank revocation reason.
  Invariant 9.3: EVERY revoked credential MUST carry a revocation instant.
  ```
- **Invariant 10 — Credential durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a credential from the database.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  ```
- **Invariant 11 — A lapse precludes verification.**
  ```
  Deleted: Invariant 11.1. Invariant 3.1 owns it: a verify answers verified only against the effective-active credential, which a lapsed credential is not.
  ```
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when a credential lapses.
  Invariant 12.2: [Read] MUST compute the effective status from the credential's expiry instant and now.
  ```

---

## Examples

### Password authentication — registration and verification

`register(user_u91, "correct horse battery staple", "password")` → `cred_c01`, standing active with no deadline. The material is derived to a verifier and discarded; nothing in the database holds it. Later, `verify(user_u91, "password", "correct horse battery staple")` → verified. `verify(user_u91, "password", "hunter2")` → `failed-verification(material-mismatch)`.

### Programming-interface token — rotation

`register(svc_s03, <token>, "api-token", 2026-04-01)` → `cred_c07`. On a quarterly policy the service rotates before the deadline: `rotate(cred_c07, <new token>, 2026-07-01)` → `cred_c11`. `cred_c11` stands active with its own verifier, registration instant and deadline, and `cred_c07` stands rotated carrying rotation instant and `successor_credential_id: cred_c11`. An auditor walks `cred_c07 → cred_c11` and reads the gap between each registration and its predecessor's rotation.

### The deadline passes

`cred_c11` carries `expires_at: 2026-07-01`. At 2026-07-01 exactly it already reads lapsed — the boundary instant is on the lapsed side. On 2026-07-02 nothing has happened to the record: it still stands active, carries no terminal field, and read returns it with an effective status of expired. verify against the pair answers no-active-credential; `rotate(cred_c11, …)` answers not-active; `revoke(cred_c11, …)` answers already-terminal — each by reading, each writing nothing. And because `cred_c11` no longer occupies the slot, `register(svc_s03, <material>, "api-token", …)` succeeds, leaving two records standing active for the pair, exactly one of them effective-active.

### Public key — a signed challenge

`register(svc_s04, <Ed25519 public key>, "public-key")` → `cred_c20`; the verifier is the key's canonical encoding (Ed25519 is an elliptic-curve signature scheme). A composing pattern issues a challenge and the holder signs it: `verify(svc_s04, "public-key", {challenge, signature})` → verified. The same signature presented again also answers verified — this atom does not know the challenge was used (Non-goal 31, 36) — which is why a deployment composes a challenge pattern that refuses a spent one.

### Revocation after exposure

Tokens for `svc_s03` turn up in a log file. `revoke(cred_c11, admin_a01, "log-exposure-2026-09-12")` → revoked, stamping revocation instant, revoked by reference and revocation reason. A later auditor reading only the database knows when, why and whom the caller named, without asking anyone; that the named actor was the caller is the composing pattern's to show (Composition note 15).

### Rejection paths

`register(user_u91, "x", "password")` on a pair that already holds an effective-active credential → duplicate-active-credential; the caller rotates instead. `register(user_u91, "x", "Password ")` → invalid-request, because no derivation function is registered for that type — which is also what stops a byte-exact key from quietly admitting a second effective-active credential under a near-duplicate name. `rotate(cred_unknown, "x")` → not-known. `rotate(cred_c11, "y")` on a reading before 2026-07-01, beside a `register(svc_s03, "z", "api-token")` that took its reading after 2026-07-01 and committed first → not-active: the register found `cred_c11` lapsed and was admitted, and the rotate, reading `cred_c11` live, finds the register's credential effective-active beside it (Operation 65). `register(user_u92, "z", "password")` whose database write fails → storage-failure, and no record exists (Operation 48). `revoke(cred_c07, admin_a01, "  ")` on the already-rotated record → already-terminal, not invalid-request: [Revoke]'s refuses line lists already-terminal first (Execution Contract Refusal 1).

### Regulated adversarial scenarios

- **Regulator audit.** *Was the service account's programming-interface credential rotated inside the ninety-day window?* Filter the database to the pair and order by registration instant; each rotated record carries rotation instant and a link forward. Invariant 7.1 and Invariant 7.2 are what make the chain complete rather than merely plausible — no rotation is omitted, and no link leaves the pair.
- **Disputed transaction.** *I did not log in from that address.* The composing [Login](../compositions/login.md) records name the credential used; these records show that credential's standing and registration instant. Invariant 3.1 is the structural rebuttal: if verified was answered, the presented material matched the recorded verifier. Whether the caller was the principal or someone holding their secret is a separate investigation, and this atom's records bound its window.
- **Breach investigation.** A batch of tokens may have been exposed. Filter to the pair, read each effective status against the investigation clock, and revoke what is still effective-active. Invariant 9.1 through 9.3 are what make the resulting record's answer to *when, why, and whom the caller named* provable; that the named actor was the authenticated caller is the composing pattern's to prove (Composition note 15, External check 10).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the credential records and a read-time clock.

### Conformance checks

```
Check 1.1: An auditor MUST find no two effective-active credentials sharing a pair, at a settled reading the auditor supplies (Invariant 2.1, Operation 65).
Check 1.2: An auditor MUST read effective-active from the window reading and NOT from the stored status (Operation 8, Invariant 2.1).
Check 2.1: An auditor MUST find no credential storing expired as a status (State 6).
Check 2.2: An auditor MUST find no credential carrying a lapse instant (State 7, Invariant 12.1).
Check 2.3: An auditor MUST reproduce a [Read] answer's effective status from the credential's expiry instant and a clock the auditor supplies (Invariant 12.2).
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
Check 6.1: An auditor MUST find no credential whose status IS NOT IN the stored terminals on a later read of a credential a prior read found in that stored terminal (Invariant 5.1).
Check 6.2: An auditor MUST find no terminal field on an active credential (State 5).
Check 7.1: An auditor MUST find a re-read credential's properties unchanged across an admitted rotate (Invariant 1.1, Invariant 6.1).
Check 7.2: An auditor MUST find a re-read credential's terminal fields unchanged across a later write (Invariant 1.2).
Check 7.3: An auditor MUST find a rotated credential's fields beside status, rotation instant and successor credential id unchanged across the rotate (Invariant 6.2).
Check 8.1: An auditor MUST find no credential absent from a later read, beside the credentials a composing Retention Window's purge record names (Invariant 10.1, State 15).
Check 8.2: An auditor MUST find the database instance's credential count no lower on a later read, beside the credentials a composing Retention Window's purge record names (State 15).
Check 9.1: An auditor MUST reconstruct EVERY credential of one pair from the database (State 1, State 15, Invariant 10.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing credential material confirmed absent from a log MUST read the deployment's own logging (State 9, State 10).
External check 2: A deployment needing a check confirmed constant-time over a secret verifier MUST read the implementation (Operation 24).
External check 3: A deployment needing a verifier confirmed unable to produce matching material MUST read the derivation registry (Capability requirement 5).
External check 4: A deployment needing a verify answer observed MUST read the composing Event Log (Non-goal 25).
External check 5: A deployment needing a principal reference bound to a real party MUST read the composing Party Identity (Non-goal 1).
External check 6: A deployment needing a failed verify counted MUST read the deployment's own lockout surface (Non-goal 8).
External check 7: A deployment needing the database confirmed free of a retroactive edit MUST read the composing Tamper Evidence (Non-goal 21).
External check 8: A deployment needing a verified answer confirmed against the credential's standing MUST read the composing Event Log's verify events beside the database (Invariant 3.1).
Deleted: External check 9. Execution Contract Database 1 owns it.
External check 10: A deployment needing a revoked by reference confirmed as the authenticated caller MUST read the composing pattern's authentication (Composition note 15).
External check 11: A deployment needing a credential write confirmed to an authorized caller MUST read the composing pattern's authentication (Composition note 12, Composition note 13, Composition note 14).
External check 12: A deployment needing [Read] confirmed to an authorized caller MUST read the composing pattern's authorization (Composition note 16).
External check 13: A deployment needing a check function confirmed to match the credential type's derivation function MUST check material against the verifier derived from the material (Capability requirement 29, 30).
External check 14: A deployment needing a verifier salted and costly to guess confirmed MUST read the derivation registry (Non-goal 39).
External check 15: A deployment needing one effective-active credential per principal confirmed across spellings MUST read the deployment's own reference canonicalization and credential type declarations (Capability requirement 6, Capability requirement 13).
```

---

## Non-goals

```
Non-goal 1: The atom MUST NOT confirm that a principal reference names a proofed party.
Non-goal 2: A deployment needing identity proofing MUST compose Party Identity.
Non-goal 3: The atom MUST NOT sequence two credential checks.
Non-goal 4: A deployment needing multi-factor sequencing MUST own the sequencing above this atom.
Non-goal 5: The atom MUST NOT issue a session.
Non-goal 6: A deployment needing a persisted verification MUST compose Session.
Non-goal 7: The atom MUST NOT count a failed verify.
Non-goal 8: A deployment needing lockout MUST own the lockout above this atom.
Non-goal 9: The atom MUST NOT decide what a verified principal may do.
Non-goal 10: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 11: The atom MUST NOT offer a credential recovery flow.
Non-goal 12: The atom MUST NOT bind one credential to two principals.
Non-goal 13: A deployment needing bearer delegation MUST compose Capability.
Non-goal 14: The atom MUST NOT enumerate the admitted credential types.
Non-goal 15: The atom MUST NOT constrain credential material's strength.
Non-goal 16: A deployment needing a material strength floor MUST declare the floor in the derivation function.
Non-goal 17: The atom MUST NOT migrate a verifier to a new derivation function.
Non-goal 18: The atom MUST NOT recover credential material from a verifier.
Non-goal 19: The atom MUST NOT reinterpret a verified answer the atom gave.
Non-goal 20: The atom MUST NOT detect a rewrite under the database.
Non-goal 21: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 22: The atom MUST NOT bound a credential's retention.
Non-goal 23: The atom MUST NOT decide whether a verifier is special-category data under Article 9 of the European Union's General Data Protection Regulation.
Non-goal 24: The atom MUST NOT record a transition history.
Non-goal 25: The atom MUST NOT record an answer the atom gave.
Non-goal 26: The atom MUST NOT guarantee that a credential reaches a stored terminal.
Non-goal 27: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 28: A deployment needing a verifiable time anchor MUST compose a forthcoming trusted timestamping pattern.
Non-goal 29: The atom MUST NOT issue a challenge.
Non-goal 30: A deployment needing a challenge-response check MUST bind the challenge into the presented material at a forthcoming challenge pattern.
Non-goal 31: The atom MUST NOT confirm that a verified signed challenge is fresh.
Non-goal 32: A deployment needing a credential lawfully erased MUST compose Retention Window.
Non-goal 33: The atom MUST NOT bound the size of a read's answer.
Non-goal 34: The atom MUST NOT confirm that a registering caller holds a public key's private key.
Non-goal 35: A deployment needing proof of possession MUST confirm the proof at the composing enrollment pattern.
Non-goal 36: The atom MUST NOT confirm what a verified signed message was signed for.
Non-goal 37: The atom MUST NOT refuse a rotate to the prior credential's material.
Non-goal 38: The atom MUST NOT define an answer to a fault in a function the derivation registry declares.
Non-goal 39: The atom MUST NOT bound the cost of guessing a verifier.
```

NOTE: the owners — a compromise disclosure pattern *(forthcoming)* (Non-goal 19, Composition note 11); Execution Contract Logic confinement 7 (Non-goal 27); the deployment (Non-goal 37, Composition note 17); the host (Non-goal 38); the derivation function (Non-goal 39, External check 14).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Operation 47 and Execution Contract Database 1 own it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 3 owns it.
Concurrency 5: IF a verify's read PRECEDES a transitioning write's commit THEN the verify MAY answer verified.
```

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer to a credential write MUST NOT retry the credential write BEFORE the caller reads the database.
Indeterminate outcome 2: A caller MUST NOT read a transport fault as a storage-failure.
Indeterminate outcome 3: A caller retrying a landed [Register] MUST read duplicate-active-credential as the first call's landing.
Indeterminate outcome 4: A caller retrying a landed [Rotate] MUST read not-active as the first call's landing.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN [Register] MUST answer invalid-request.
Deleted: String 8. Operation 27 owns it.
String 9: IF a string input EXCEEDS the length bound THEN [Revoke] MUST answer invalid-request.
String 10: The atom MUST read material as blank ONLY IF the material is absent OR empty.
```

Term string input: a reference, credential type OR reason — every caller-supplied string this atom accepts beside material.

Term length bound: the maximum length the deployment declares for a string input.

---

## Composition notes

```
Composition note 1: A composing Login MUST issue a session ONLY AFTER a verified answer.
Deleted: Composition note 2. Non-goal 8 owns it.
Composition note 3: A deployment revoking a credential Login composes MUST call Login's revoke sessions for credential.
Composition note 4: A composing External Onboarding MUST call [Register] ONLY AFTER a party record EXISTS.
Composition note 5: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 6: A composing Event Log MUST append an event on EVERY refused action.
Composition note 7: A composing Event Log MUST append an event on EVERY verify answer.
Composition note 8: A composing Actor Identity MUST attest the principal behind a verified answer.
Composition note 9: A composing Tamper Evidence MUST cover EVERY credential the database holds.
Composition note 10: A composing Tamper Evidence MUST NOT expose a verifier.
Composition note 11: A composing forthcoming compromise disclosure pattern MUST record a new credential rather than change a credential.
Composition note 12: A composing pattern MUST call [Register] ONLY AFTER authenticating an authorized caller.
Composition note 13: A composing pattern MUST call [Rotate] ONLY AFTER authenticating an authorized caller.
Composition note 14: A composing pattern MUST call [Revoke] ONLY AFTER authenticating an authorized caller.
Composition note 15: A composing pattern MUST pass the authenticated caller as revoked by reference.
Composition note 16: A composing pattern MUST expose [Read] ONLY AFTER authorizing the caller.
Composition note 17: A deployment refusing reused secret material MUST call [Rotate] ONLY AFTER a verify of the new material against the pair answers material-mismatch.
Composition note 18: A composing Retention Window MUST purge a pair's rotation chain whole.
```

Term authorized caller: a caller authenticated as the principal the call names — for [Rotate] and [Revoke], which name a credential id, the principal that credential carries; for a principal holding no effective-active credential, a caller authenticated by a composing enrollment pattern's own proof, as External Onboarding's invitation; OR a caller authenticated as an actor a composing Permissions decision authorizes over that principal, with the decision's subject bound to that authenticated actor (Permissions Composition note 3).

Term credential write: [Register] | [Rotate] | [Revoke].

NOTE: composing patterns — [Login](../compositions/login.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the host; the implementation; the database; the seam; the transition; a composing pattern; a caller; a principal; an auditor; a regulator; an investigator; a reader; a credential; an active credential; an effective-active credential; a lapsed credential; a rotated credential; a revoked credential; a successor credential; a prior credential; an action; a transitioning write; a refused action; a rejection; an answer; a derivation function; an opaque reference; a string input; a filter; the database instance's credential count.

Term records: credential — one principal's binding to one verifier for one credential type, carrying credential id, principal reference, credential type, verifier, registration instant, a status and, where supplied or set, expiry instant, rotation instant, successor credential id, revocation instant, revoked by reference and revocation reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, commit, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, canonicalize, declare, compose, remove, bind, decide, define, bound, reach, accept, retain, trim, case-fold, compute, reproduce, reconstruct, verify, issue, detect, guarantee, take, derive, expose, store, own, persist, enumerate, distinguish, select, walk, mutate, serialize, rotate, revoke, block, invalidate, migrate, recover, reinterpret, constrain, count, sequence, run, rebind, check, order, lower, retry, authorize, purge, evaluate.

Term value sets: status = active | rotated | revoked. stored terminal = rotated | revoked. window reading = live | lapsed. property = principal reference | credential type | verifier | registration instant | expiry instant. terminal field = rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason.

Term bounds: default validity, length bound, material bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: credential, credential id, lapse instant, pair, property, reference, database instance, seam, transition, now, transitioning write, stored terminal, status, window reading, live, lapsed, effective-active credential, lapsed credential, proceeding verify, effective status, verifier, derivation function, derivation registry, foldable difference, length bound, default validity, check function, filter, fresh credential id, authorized caller, credential write, secret verifier, settled reading, terminal field, admitted register, admitted rotate, admitted revoke, string input, blank, verification failure, default expiry.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Party Identity](./party-identity.md), [Session](./session.md), [Permissions](./permissions.md), [Actor Identity](./actor-identity.md), [Capability](./capability.md), [Event Log](./event-log.md), [Tamper Evidence](./tamper-evidence.md), [Login](../compositions/login.md), [External Onboarding](../compositions/external-onboarding.md), a compromise disclosure pattern *(forthcoming)*, a trusted timestamping pattern *(forthcoming)*, a challenge pattern *(forthcoming)*, [Retention Window](./retention-window.md).

Term credential types: credential_types — the credential kinds a deployment declares.

Term new credential material: new_credential_material — the material [Rotate] installs in place of the old.

#### Register

The behavior that records a new [Credential] — deriving the [Verifier] from [Credential Material] through the [Credential Type]'s derivation function, discarding the material, assigning a fresh [Credential Id], standing the record in [Active], and answering the id. Refused [Invalid Request], [Duplicate Active Credential] or [Storage Failure].

Kind: Operation

#### Verify

The read-only behavior that answers whether [Presented Material] matches the [Verifier] of the pair's effective-active credential, as the type's check function decides. Answers verified, or failed-verification naming [Material Mismatch] or [No Active Credential]. Writes nothing, counts nothing, and does not say *why* no effective-active credential exists.

Kind: Operation

#### Rotate

The transitioning write that replaces a credential — recording a successor in [Active] for the same pair — a fresh [Credential Id], a [Verifier] derived from the new credential material, its own registration instant and [Expiry Instant] — standing the prior credential in [Rotated], and stamping [Rotation Instant] and [Successor Credential Id] on it. Legal only against an effective-active credential with no other effective-active credential beside it for the pair; otherwise [Not Active].

Kind: Operation

#### Revoke

The transitioning write that cancels a credential, standing it in [Revoked] and recording [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Legal only against an effective-active credential; otherwise [Already Terminal].

Kind: Operation

#### Read

The read-only query answering the matching [Credential] records, each carrying its stored fields — never the [Verifier] — and its derived [Effective Status].

Kind: Operation

#### Credential

The record this atom defines: one principal's binding to one verifier for one credential type. Carries [Credential Id], [Principal Reference], [Credential Type], [Verifier], [Registration Instant], [Status], an optional [Expiry Instant], and the terminal fields of whichever write ended it.

Kind: Type
Projection: status

#### Credential Id

The opaque, immutable identity of a [Credential], assigned on [Register] from the id material the seam supplies. Never reused, and never the pair — two credentials for one pair are a rotation predecessor and its successor, each standing on its own.

Kind:       Field
Field of:   Credential
Projection: credential_id

#### Principal Reference

The opaque reference naming whose credential this is. Set on [Register], immutable. The atom does not confirm it names a known or proofed party — that is [Party Identity](./party-identity.md)'s.

Kind:       Field
Field of:   Credential
Projection: principal_ref

#### Credential Type

The label naming the kind of credential — `password`, `public-key`, `api-token`, `fido2` (a hardware authenticator of the FIDO Alliance's second authentication standard, see Standards references). Half of the pair the effective-active bound ranges over, and the selector for the derivation function; a type naming no registered function is refused.

Kind:       Field
Field of:   Credential
Projection: credential_type

#### Verifier

The artifact a one-way derivation function produces from [Credential Material] — a hash, an encoded public key. The only thing this atom stores in place of the secret, and never answered by [Read].

Kind:       Field
Field of:   Credential
Projection: verifier

#### Status

The stored status of a [Credential] — [Active], [Rotated] or [Revoked]. [Expired] is not a value of this field; it appears only in the derived [Effective Status].

Kind:       Field
Field of:   Credential
Projection: status

#### Registration Instant

The instant the credential was recorded, stamped from [Now] on [Register]. Immutable.

Kind:       Field
Field of:   Credential
Projection: registered_at

#### Expiry Instant

The optional instant the window closes, recorded on [Register] or on a [Rotate]'s successor from the caller's value or now plus the deployment's default validity. Immutable. Absent means no deadline, and a credential with no deadline reads live forever. The sole stored input the derived [Effective Status] needs.

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

#### Effective Status

The status a [Read] answers: [Expired] where the credential reads lapsed, and the stored [Status] otherwise. A projection over the credential and [Now] — computed at read time, never stored, and the only surface on which [Expired] appears.

Kind:       Field
Field of:   Credential
Projection: effective_status

#### Credential Material

The raw input the principal supplies to [Register]: a secret for a secret-derived type, a public key for a public-key type. Consumed to derive the [Verifier] and then discarded — never stored in a field, a log or a temporary record beyond the verifier itself, and a public key's verifier is its canonical encoding, which is why State 9 says *beyond the verifier*.

Kind:         Parameter
Parameter of: Register
Projection:   credential_material

#### Presented Material

The raw material the principal supplies to [Verify]: a secret for a secret-derived type, a signed challenge for a public-key type, an assertion for a `fido2` type. Checked against the stored [Verifier] through the credential type's check function, then discarded. Never stored.

Kind:         Parameter
Parameter of: Verify
Projection:   presented_material

#### Reason

The revocation reason supplied to [Revoke], recorded as [Revocation Reason]. Required and never blank.

Kind:         Parameter
Parameter of: Revoke
Projection:   reason

#### Now

The wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it — never read inside the transition and never supplied by the business caller. Consumed by the window reading, by a write's stamps, and by [Read]'s [Effective Status] projection.

Kind:         Parameter
Parameter of: Register, Verify, Rotate, Revoke and Read
Projection:   now

#### Active

The one non-terminal status. An active credential reads live or lapsed against [Now]; only a live one is effective-active, and only an effective-active one can be verified against, rotated or revoked.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Rotated

The stored terminal reached when a successor was registered. Carries [Rotation Instant] and [Successor Credential Id]. Absorbing.

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

#### Material Mismatch

The [Verify] answer when an effective-active credential exists for the pair and the type's check function answers no match or refuses the presented material. A first-class result of a query, not a rejection.

Kind:       Member
Member of:  the failed-verification reason
Role:       Outcome
Projection: material-mismatch

#### No Active Credential

The [Verify] answer when the pair has no effective-active credential — because none was registered, because every record is a stored terminal, or because the only active one reads lapsed. The three are deliberately one answer: distinguishing them would let a caller enumerate which principals hold which credential types.

Kind:       Member
Member of:  the failed-verification reason
Role:       Outcome
Projection: no-active-credential

#### Invalid Request

The refusal returned when a required argument is blank, a [Credential Type] names no derivation function, a supplied [Expiry Instant] does not exceed [Now], the derivation function refuses the material, or — on [Register] and [Revoke] only — a string input exceeds the deployment's length bound. On a transitioning write it is listed after not-known and the standing refusals, so it answers only once none of them applies.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Duplicate Active Credential

The refusal [Register] returns when the pair already holds an effective-active credential. The caller's move is [Rotate], not a second registration. A lapsed credential does not produce this.

Kind:       Member
Member of:  the Register rejection
Role:       Outcome
Projection: duplicate-active-credential

#### Not Known

The refusal a transitioning write returns when the supplied [Credential Id] names no credential. Listed ahead of [Not Active] and [Already Terminal] on the refuses lines, so a caller reading either knows the id resolved.

Kind:       Member
Member of:  the transitioning-write rejection
Role:       Outcome
Projection: not-known

#### Not Active

The refusal [Rotate] returns, after [Not Known] is ruled out, when the credential is not effective-active — either a stored terminal, or standing in [Active] and reading lapsed — or when the credential is effective-active and another credential beside it for the pair is too (Operation 65). Three mechanisms, one answer.

Kind:       Member
Member of:  the Rotate rejection
Role:       Outcome
Projection: not-active

#### Already Terminal

The refusal [Revoke] returns when the credential is not effective-active. The symmetric counterpart to [Not Active], and it shares that answer's two mechanisms — a stored terminal excludes by what it stores, a lapsed credential by what the clock says.

Kind:       Member
Member of:  the Revoke rejection
Role:       Outcome
Projection: already-terminal

#### Storage Failure

The refusal any action returns when the database refuses the write after every precondition passes. No credential is recorded, or the credential remains as the call found it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

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

## Standards references

- **NIST SP 800-63B-4 (the US National Institute of Standards and Technology's Special Publication 800-63B, authentication and authenticator management, revision 4)** — the primary standard here. Authenticator assurance levels, stored verifiers rather than raw secrets (the salt supplied at the seam when the function consumes one, Capability requirement 24, and the cost the derivation function's own, neither of which the atom requires, Non-goal 39), and rotation and revocation requirements correspond directly to this atom's rules. The correspondence is to 800-63B's *verifier storage and lifecycle* half specifically; the *authenticator strength* half — minimum length, breached-password screening, entropy floors — is not enforceable here and lives in the derivation function (Non-goal 15, Non-goal 16). Identity proofing is 800-63A's and is deliberately not cited: that is [Party Identity](./party-identity.md)'s.
- **FIDO2 (the FIDO Alliance's second authentication standard) / WebAuthn (W3C — the World Wide Web Consortium — Web Authentication Level 2)** — for phishing-resistant hardware authenticators. A `fido2` [Credential Type] takes the attestation object as [Credential Material]; the [Verifier] is the public key extracted from it, and [Verify] checks a presented assertion against it through the type's check function; the challenge the assertion signs is a composing pattern's (Non-goal 30).
- **RFC 7519 (the Internet Engineering Task Force's Request for Comments 7519, JSON Web Token, JSON being JavaScript Object Notation)** — an `api-token` [Credential Type] stores a hash of the raw token as its [Verifier]. The atom does not interpret token claims; that is the composing pattern's.
- **OpenID Connect (OIDC) Core 1.0** — the OIDC login flow ends in a verification this atom answers, and the verification event itself is a composing Event Log's (Composition note 7); [Login](../compositions/login.md) is the Grace Commons expression of the authorization-code flow.
- **PCI DSS (the Payment Card Industry Data Security Standard) Requirement 8 (identify and authenticate access)** — the atom satisfies the structural requirements: one effective-active credential per pair, rotation producing a new record, revocation recorded with the attribution the caller supplies. The rotation period is not enforced here: the default validity (Capability requirement 7) is a default that a supplied expiry overrides, so the atom bounds no credential's lifetime and a deployment needing a maximum age enforces it in the pattern that schedules its rotations. Complexity rules and the lockout threshold are likewise the deployment's (Non-goal 8, Non-goal 16).
- **ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 27001:2022 Annex A controls 5.17 (authentication information) and 8.5 (secure authentication)** — the registration, rotation and revocation lifecycle corresponds to the authentication-information controls there; the 2013 edition's A.9.4 is the superseded numbering.
- **GDPR (EU General Data Protection Regulation) Article 32 (security of processing)** — State 9, State 10 and the one-way verifier discipline contribute to the technical measures Article 32 requires. A deployment storing a biometric verifier assesses Article 9 separately (Non-goal 23).
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (person or entity authentication)** — the verified answer is the structural mechanism for this requirement.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing identity proofing, sessions, authorization and multi-factor orchestration as separate atoms rather than absorbing them here.
- **NIST 800-132 (password-based key derivation)** — the reference for which derivation functions satisfy the one-way property Capability requirement 5 requires.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — credential.tla + 4 twins, 2026-09-29
last gate: 2026-10-21 — Final Critique 13, the council's first round on the page and the first on its Store-contract rewrite (690d84c), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus MiMo V2.6 Flash), each handed only the round's reading set, three passes on one text (frozen at 8d5a150); the round rests on three counted passes — foundational count 5 after triage (11 reports, 4 sent down to refining, 3 rejected; 1 refining report raised), all Kind A: a failed read of the credential store had no answer the page allowed, [Verify] and [Read] closing their answers and no signature naming state-unavailable; Term settled reading made the settled reading the only one at which a pair's credentials are judged together, while Operation 65 and Operation 70 judge them at the call's own reading; blank id material could stand a credential whose blank id Operation 51 and Operation 73 answer two ways; id material longer than the length bound left an effective-active credential that [Revoke] refuses as invalid-request; and Invariant 4.1 and 11.1, read alone, forbade the verified Operation 23 obliges to a verify that reads a revoked or lapsed credential beside the effective-active one; 17 refining reports, 7 rhetorical reports; not clean; every foundational finding cured in place; 2026-09-29 — Final Critique 12, cold reader — 0 foundational, 12 refining (routed open)

open:
- 2026-10-21-a · refining · Capability requirement 27, 31, 32; Term bounds · the material bound has no measure and no Term declaration, and Capability requirement 31 and 32 read 'material the material bound EXCEEDS', the bound as the subject; a declared function carries its own measure, so no two builds of one deployment differ, but no single unit serves every type (bytes leave a string material's encoding open, code points measure no binary material) → declare the measure with the bound per credential type, and write Capability requirement 31 and 32 in Timing 7's form
- 2026-10-21-b · refining · Term seam, transition, now; Term cited · each cites the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them → cite what declares each, as Event Log's 2026-10-20-c and Permissions' 2026-10-21-f ask of the same four sentences
- 2026-10-21-c · refining · Capability requirement 26; Operation 21, 24 · the host runs the check function at the seam against the verifier the transition selects, and the pipeline in `execution-contract.md` gives that run no step between the guard's read and its decision → a seam step for the check, on the contract, beside 2026-09-29-d's Operation 24 clause
- 2026-10-21-d · refining · State 4; Invariant 9.1 through 9.3 · State 4 and Invariant 9.3 carry one proposition, a revoked credential's revocation instant, and State 4 overlaps Invariant 9.1 and 9.2 (GRACE-lang Authority 3) → one owner for each field a revoked credential carries
- 2026-10-21-e · refining · Check 6.1; Invariant 5.1 · Check 6.1's double negative is hard to read and misses a move from one stored terminal to the other, which Invariant 5.1 forbids; an inversion must keep out a credential a composing Retention Window purged, as Check 8.1 does → restate Check 6.1 as the stored terminal found again, purged credentials excepted
- 2026-10-21-f · refining · Term value sets · the effective status, expired or the stored status, has no value set → declare it beside status
- 2026-09-29-e · refining · Final Critique 12 · routed open, non-blocking: precondition and blank used as terms with no entry; the NIST verifier-storage claim against Non-goal 39 and Capability requirement 5; a read naming neither a pair nor an id has no routing across database instances; a type withdrawn from the registry leaves verify and rotate with no answer; a public key's check normalizes nothing the page names; the Summary's at-most-one claim unscoped to a settled reading; the regulator scenario's no rotation is omitted overclaims Invariant 7; Operation 69's direction and collation; a lapse reopens a principal reference to any enrollment proof, unstated; one snapshot for verify's window reading, selection and check, unpinned → one refining pass
- 2026-09-29-d · refining · Final Critique 11 · routed open, non-blocking: Operation 24 binds the host's check and sits among the transition's rules; Invariant 7 declares no acyclicity or single predecessor; no External check reaches Capability requirement 33, 35 or 36; Identity 5 global against a per-instance database term, and Capability requirement 13's opaque reference reaching credential ids; the NIST line's verifier-storage claim beside Non-goal 39; fido2 and canonicalizes before their glosses; Operation 69's tie order unexplained; Example 1's deadline assumes an unbounded default; Indeterminate outcome 3 and 4 read another caller's landing as the first call's; the Revocation after exposure example revokes on 2026-09-12 a credential that lapsed on 2026-07-01, which answers already-terminal; the Clock semantics tombstones inside the Capability requirement block → one refining pass, gated with the rest
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/credential.md`; the rounds, the repairs and the critical section that got it here are in [its history](./credential.hist.md).

- **2026-09-29 — The two functions a type declares, tied.** *Chose:* a check function that matches the material its type's derivation function derived the verifier from, normalizing as it does (Capability requirement 29, 30), confirmed by an External check on material the auditor supplies. *Over:* two independent declarations, under which an always-no-match check function satisfied every rule. *Because:* Final Critique 9 (a cold reader); the split was this page's own, made when Final Critique 7 separated checking from deriving. The same round scoped Invariant 2.1, 4.1 and 11.1 to the reading they hold at, moved Identity 12 through 15 to the deployment's family, and wrote down what a verified public key does not establish.
- **2026-09-29 — Authenticated as whom.** *Chose:* the authorized caller — authenticated as the principal the call names, admitted by an enrollment pattern's own proof for a principal holding no credential, or authorized over the principal by a composing Permissions decision — behind every credential write (Composition note 12 through 14), and [Read] exposed only to an authorized caller (Composition note 16). *Over:* *authenticating the caller*, which a caller authenticated as Alice satisfies while rotating Bob's credential, and which a principal's first registration cannot satisfy at all. *Because:* Final Critique 8 (a cold reader), and the binding half of the section titled *Authentication precedence* in `pressure-testing.md`. The same round moved lockout and multi-factor sequencing off Login, which disclaims both, onto the deployment.
- **2026-09-29 — Built cold: where the cryptography runs.** *Chose:* the derivation and check functions run at the seam, and the entropy a salted derivation consumes is supplied there (Capability requirement 24 through 26); the default validity may be declared unbounded, where the term said a deployment could declare none against Capability requirement 7's obligation to declare it; Operation 20 speaks of checking presented material, as Operation 21 through 23 do. *Over:* a registry *supplied* at the seam and silently *run* inside the transition, with no source for a salt. *Because:* the cold regeneration built a salted password and a public key, and Execution Contract Logic confinement 1 and 3 allow neither the cryptography nor the entropy inside a transition (council read 266).
- **2026-10-19 — The store's guarantees cited, not restated, the pair's critical section among them.** *Chose:* the credential store supplied under Execution Contract Store 1 through 4 (Capability requirement 37), and the twenty-one rules that restated them tombstoned to their owner — Operation 40 and 44, Capability requirement 12, Invariant 10.2, External check 9 and Atomic writes 1, 3 and 4, a transition's writes committed whole, to Store 1; Atomic writes 2, an uncommitted transition discarded whole, to Store 1 and Store 3; Atomic writes 5, a refused rotate leaving the prior credential active, to Operation 47 and Store 1; Capability requirement 11, a write acknowledged only once it commits, and Concurrency 4, [Verify] answering from a committed state, to Store 3; Concurrency 1, the standing check and the status change as one operation, to Store 1 and Store 2; Capability requirement 8, 17 and 23 and Concurrency 2 and 3, the pair's check and write run as one critical section held through the write, and a concurrent call answering from what the other committed, to Store 2, and with them the section's release and lease (Capability requirement 9, 21 and 22), since the atom names no section any more; rules 266 to 246. *Over:* the atom running its own critical section over the pair, with a lease the deployment declares, an overdue holder released and a write refused outside the section — the turns of 2026-09-13 and 2026-09-29, now in the history. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract: Store 2 reads the state an action's guards decide on — for [Register] and [Rotate], the pair's credentials — inside the transaction that writes the action's effects, which is what the section was for. The checks that compare an auditor's earlier read with a later one (Check 6.1, 7.1 through 7.3, 8.1 and 8.2) rest on the auditor's own reads, and the atom keeps a credential's history as separate records (Identity 6), so it cites neither History 1 nor Order 1. Operation 65 and the settled reading stay, since the rotate race they close comes from two readings of now; what the atom does for its domain is unchanged.
- **2026-10-21 — A failed read answers on every action, each write's refusals in one stated order; the ids the deployment supplies fit the string policy; verified is answered only against the effective-active credential.** *Chose:* state-unavailable on all five actions where the read of the credential store fails, the Execution Contract's Step 1 failure (Operation 74, Term store read), [Verify] and [Read] answering only on an answered read (Operation 18, Operation 55, Term proceeding verify, Term admitted read, Concurrency 5), and the refusals of [Register], [Rotate] and [Revoke] each in one stated order, the store read first and the page's standing checks ahead of the inputs (Operation 75 through 77, the three refusal order terms); id material never blank and never longer than the length bound (Capability requirement 38, 39); the settled reading as the one at which Invariant 2.1 and Check 1.1 judge a pair, where it had been the only one at which a pair's credentials are judged at all (Term settled reading); and Invariant 4.1 and 11.1 deleted to Invariant 3.1, which already answers verified only against the effective-active credential. *Over:* a verify whose read failed answered as no-active-credential, which a lockout counts as a failed verification; a blank id [Read] answers two ways, and an over-long one no [Revoke] can cancel; a term that forbade the pair check Operation 65 makes at the rotate's own reading; invariants that, read alone, forbid verifying a pair holding a revoked or lapsed credential beside its live one. *Because:* Final Critique 13, the council's first round on the page, found each a divergence between conforming builds or two rules no build could keep, all in text Final Critique 12 had read. The failed read takes the form Actor Identity's, Retention Window's, Tamper Evidence's and Permissions' rounds gave it, over Final Critique 12's refining class for it, and the two invariants go by the entry *A rule the page's lawful states break is first checked for a rule to delete it in favour of* in `pressure-testing.md`. Rules 246 to 250. Compositions affected: the pages that compose this atom route state-unavailable from all five actions when their rounds read them.

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 37, Execution Contract Read 1 through 3) and the two rules that restated it deleted to it: the atom-wide state-unavailable (Operation 74) to Read 1, and [Read]'s state-unavailable on a failed read alone (Operation 55) to Read 2 beside Operation 51; the read's condition off the rules and terms it held to an answered read (Operation 18, Concurrency 5, Term proceeding verify), and Term admitted read, which held only that condition, deleted, so its rules and checks name [Read] (Operation 51, Operation 52, Operation 69, Operation 73, Invariant 12.2, Check 2.3, Check 5.3, Check 5.4); the read off the register, rotate and revoke refusal orders, Term database read deleted, state-unavailable off every signature and off the Intent; rules 250 to 248. *Over:* the page stating for itself what every action answers when the credential records cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's thirteenth Final Critique had made one of the cures the contract's Read family is written from, and Read 3 keeps what it said of [Verify]: a failed read is no failed verification. What each action answers on an answered read is unchanged.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* each writing action's refuses line kept as the page wrote it, already in the order its refusal order gave — [Register] invalid-request, duplicate-active-credential; [Rotate] not-known, not-active, invalid-request; [Revoke] not-known, already-terminal, invalid-request; storage-failure last on each, answering only at the write — and the order cited from the Execution Contract (Capability requirement 37, Execution Contract Refusal 1); the rules that only stated it deleted to Refusal 1: Operation 75, Operation 76 and Operation 77, which evaluated the three refusal orders, with Term register refusal order, Term rotate refusal order and Term revoke refusal order, and the pairs Operation 7 (duplicate-active-credential only once every well-formedness check passes), Operation 30 (a standing rejection only for a credential id naming a credential), Operation 34 (invalid-request only once every standing check passes) and Operation 46 (storage-failure behind every precondition), with Term standing check, Term standing rejection and Term well-formedness check, which only those pairs read; rules 248 to 241. *Over:* the page stating for itself which of an action's refusals answers when several apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers; this page's thirteenth Final Critique had made the cure one specification at a time. What each action answers on every call is unchanged.

NOTE: End of Credential.

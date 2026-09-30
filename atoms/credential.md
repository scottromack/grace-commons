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

Term fresh credential id: a credential id naming no credential of the store instance, assigned from the id material the seam supplies (Capability requirement 34, 35).

Term credential id: the opaque value naming one credential — a [Credential Id]; assigned from the id material the seam supplies.

Term pair: principal reference and credential type together — the key the effective-active bound ranges over.

Term property: principal reference | credential type | verifier | registration instant | expiry instant — what a credential carries from registration and never changes.

Term reference: credential id, principal reference, revoked by reference OR successor credential id — every opaque reference this atom records.

Term store instance: one named credential store a call is routed to; credential id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the id material, the entropy and the derivation registry here, and runs the registry's derivation and check functions here, since both are cryptography (Execution Contract Logic confinement 1, 3).

Term transition: the atom's evaluation of one call against the credential store, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 6 is the one that earns the opaque id. Keying a credential by its pair would fold the whole rotation history into one mutable record, and the chain a PCI DSS (Payment Card Industry Data Security Standard) auditor walks — *was this rotated inside ninety days* — would become a field that was overwritten rather than a sequence of records that each stand. Separate records with separate ids are what make Invariant 7.1 reconstructable.

Identity 11 is this atom's one departure from the corpus's usual *confirm nothing* posture, and the departure is deliberate. principal reference and revoked by reference stay opaque, but credential type is not a name the atom merely records — it selects the derivation function that produces the verifier, so a type naming no function has no way to produce one.

Identity 11 also narrows the near-duplicate a byte-exact key otherwise admits — `password` and `Password ` are two types here, and a principal holding one effective-active credential under each breaches nothing Invariant 2.1 can see. It does not *close* it: a deployment free to register both variants against one derivation function re-opens the hole through the registry, which Identity 11 then waves through. Capability requirement 6 is the half that closes it, and it is the deployment's because the registry is. The reference has the same two halves: the pair is byte-exact, so two spellings of one principal reference are two pairs, and the one-credential-per-principal claim holds only where Capability requirement 13 folds them to one before they reach the atom. Neither half is the atom's to see, which is why External check 15 sends the reader to the deployment.

Capability requirement 34 and 35 together carry Identity 5, and they are the deployment's, so they sit with its other obligations; Identity 12 through 15, where they first landed, are tombstoned to them. Capability requirement 34 shuts out an id the store already holds; Capability requirement 35 shuts out one id handed to two calls before either commits, which two calls on different pairs — so under different critical sections — can otherwise do, and which the store's contents cannot show.

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
State 15: The atom MUST NOT lower the store instance's credential count.
```

Term lapse instant: an instant a store writes when a credential starts to read lapsed, beside a status that stays active — the materialized lapse; never stored here, because lapse is read, not written.

WHY:
State 9 and State 10 bound the record; Operation 17 and Operation 25 bound the action, and the two are different claims. A store that holds no plaintext password still fails this atom's purpose if the material was written to a log on its way in, which is what *retain* forbids and *carry* does not reach. Neither leaves evidence in the store, which is why External check 1 exists at all — this is the atom's foundational security commitment and the one no conformance check can clear.

State 6 and State 7 are the derived-expiry posture on the record surface, two rules because an implementation can breach each without the other: a stored expired status, and a lapse instant beside a status that stays active. The expiry instant is the deadline and is carried (State 2); what State 7 forbids is the record of having passed it.

State 14 names an absence a deployment eventually wants. A credential records no function of its own, only its type, so a type's functions are neither rebound to another function nor withdrawn once a credential carries it (Capability requirement 19, 20): a deployment upgrading its derivation function declares a new credential type, and moving a principal onto it is a register under that type. Migrating an existing verifier is not an action here, because a migration would have to read material this atom has already discarded (Non-goal 18).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST supply the derivation registry at the seam.
Capability requirement 4: The deployment MUST declare a derivation function PER credential type the deployment serves.
Capability requirement 5: The deployment MUST declare a derivation function whose verifier alone produces no material the check function matches.
Capability requirement 6: The deployment MUST NOT declare two credential types differing only by a foldable difference.
Capability requirement 7: The deployment MUST declare the default validity.
Capability requirement 8: The store MUST run the effective-active check and the write of [Register] AND [Rotate] for one pair as one critical section.
Capability requirement 9: The store MUST release the critical section on the caller's return.
Deleted: Capability requirement 10. Capability requirement 22 owns it, since a holder judged dead may only be slow.
Capability requirement 11: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 12: The store MUST commit an admitted rotate's two writes together.
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
Capability requirement 17: IF the caller writes THEN the store MUST release the critical section on the caller's return ONLY AFTER the store answers the write.
Capability requirement 18: The deployment MUST declare a check function PER credential type the deployment serves.
Capability requirement 19: The deployment MUST NOT change the derivation function declared for a credential type a credential carries.
Capability requirement 20: The deployment MUST NOT change the check function declared for a credential type a credential carries.
Capability requirement 21: The deployment MUST declare the critical section's lease.
Capability requirement 22: The store MUST release the critical section of an overdue holder.
Capability requirement 23: The store MUST commit a write ONLY IF the writer still holds the pair's critical section at the commit.
Capability requirement 24: The deployment MUST supply at the seam the entropy a derivation function consumes.
Capability requirement 25: The host MUST run a derivation function at the seam.
Capability requirement 26: The host MUST run a check function at the seam against the verifier of the effective-active credential the transition read.
Capability requirement 27: The deployment MUST declare a material bound PER credential type.
Capability requirement 28: The derivation function MUST own credential material's normalization.
Capability requirement 29: The deployment MUST declare a check function that matches the material the credential type's derivation function derived the verifier from.
Capability requirement 30: The check function MUST normalize presented material as the credential type's derivation function normalizes credential material.
Capability requirement 31: The derivation function MUST refuse material the material bound EXCEEDS.
Capability requirement 32: The check function MUST refuse presented material the material bound EXCEEDS.
Capability requirement 33: The deployment MUST route EVERY call naming one pair to the same store instance.
Capability requirement 34: The deployment MUST supply id material naming no credential of the store instance.
Capability requirement 35: The deployment MUST NOT supply the same id material to two calls.
Capability requirement 36: The deployment MUST route EVERY call naming a credential id to the store instance that assigned the credential id.
```

WHY:
Capability requirement 8 names a critical section rather than a store constraint because the constraint that suggests itself cannot work. *A unique partial index on the pair where status is active and the credential is not past its deadline* needs an index predicate that references now, which no index can. The clock-free half of that index, `where status = active`, forbids exactly the case Operation 8 permits: a lapsed record standing in active beside its successor. So the index is either unimplementable or wrong, and the obligation it was reaching for is a critical section over the pair — the same shape [Provisional Commitment](./provisional-commitment.md)'s registry carries. [Rotate] runs under the same section: a rotate admitted on a reading before the prior credential's deadline and a register admitted on a reading after it would otherwise both commit, leaving the pair two effective-active credentials, and Operation 65 is what the section lets [Rotate] check.

Capability requirement 21 through 23 are the stalled holder. Release on return (Capability requirement 9) leaves a holder alive and stuck, blocking the pair, and the lease bounds it. Release on the caller's death is not a rule, because a store cannot tell a dead caller from a slow one: a holder released on that belief while its write is still in flight lets a second holder pass the check and commit, and the first write then lands beside it, leaving the pair two effective-active credentials. So the lease is the only end a holder does not choose, and Capability requirement 23 judges a write at its commit: a write from a holder whose section has ended is refused as storage-failure, so a write never lands outside the section that checked it. A store that is one transaction with the section does this by construction, since a dead caller's write dies with the caller. Capability requirement 17 keeps the section through a returning caller's write; the lease is the only other end it has.

Capability requirement 24 through 26 are Execution Contract Logic confinement 1 and 3 applied to a salted hash. Deriving a verifier and checking material are cryptography, which no transition performs, and a salted derivation consumes entropy, which no transition draws; the host runs both functions at the seam and supplies the salt there, as it supplies the id material, and the transition records what they answer. The order is fixed by what each needs: derivation needs the call's material and the credential type — for a rotate, read from the prior credential, whose type never changes (Invariant 1.1) and which never leaves the store (Invariant 10.1), so the read stands; an unknown id derives nothing and the transition answers not-known (Operation 27) — so it runs before the transition and outside the pair's critical section, and its refusal reaches the guards as Operation 66 and 67; the check needs the effective-active credential's verifier, so the host takes the window reading from the pair the transition read and from the clock reading of the same invocation — the reading the guards take — runs the check against the credential that reading selects, and hands the result to the guards, which answer from it. Operation 20 orders that: the window reading precedes the check, so no check is run against a credential the reading excluded and no answer rests on one. The host does this at the seam ahead of the guards, and draws a salt there too, where the Contract draws entropy at the top of Step 3; the placement is this atom's, recorded in the Decisions entry *Built cold: where the cryptography runs*, because Operation 66 through 68 are guards over what the functions answer.

Capability requirement 29 and 30 tie the two functions a type declares. Without them a check function that answered no match to everything would satisfy every rule on this page, since Operation 23 and Invariant 3.1 range over whatever the function says; no record can show the pair agrees, because the material that would prove it is never kept, so External check 13 runs the pair on material the auditor supplies. Capability requirement 31 and 32 put the material bound ahead of the cost: an over-long input is refused before any hashing, as invalid-request on a write and material-mismatch on a verify (Operation 66 through 68).

Capability requirement 18 is what lets one verify serve every type. A salted hash is checked by re-deriving under the salt the verifier carries, a public key by checking a signature against it; neither is *derive, then compare equal*, and a check function is what each type declares for it. A type whose check needs the secret back — a one-time-code seed — cannot be served here, because Capability requirement 5 makes the verifier one-way.

Capability requirement 14 is the delegated cap. This atom declares no maximum length for a string input and obliges the deployment to declare one, which is one of the postures the *input-handling regime* docket row counts; the material is exempt, and its bound and its normalization are the derivation function's (Capability requirement 27, 28, 31, 32), since only the function knows what its material is — two presentations of one password in different Unicode forms match or fail as the function decides.

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
Operation 7: [Register] MUST answer duplicate-active-credential ONLY IF EVERY well-formedness check passes.
Operation 8: A lapsed credential MUST NOT block a register for the credential's pair.
Operation 9: An admitted register MUST assign a fresh credential id.
Operation 10: An admitted register MUST record principal reference and credential type.
Operation 11: An admitted register MUST record the derived verifier.
Operation 12: An admitted register MUST record a supplied expiry instant.
Operation 13: IF expiry instant EQUALS blank AND the default validity DOES NOT EQUAL unbounded THEN an admitted register MUST record now plus the default validity.
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
Operation 30: A transitioning write MUST answer a standing rejection ONLY IF the credential id names a credential.
Operation 31: IF new credential material EQUALS blank THEN [Rotate] MUST answer invalid-request.
Operation 32: IF revoked by reference EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 33: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 34: A transitioning write MUST answer invalid-request ONLY IF EVERY standing check passes.
Operation 35: An admitted rotate MUST record a successor credential carrying the prior credential's pair.
Operation 36: An admitted rotate MUST stand the successor credential in active.
Operation 37: An admitted rotate MUST stand the prior credential in rotated.
Operation 38: An admitted rotate MUST record now as the prior credential's rotation instant.
Operation 39: An admitted rotate MUST record the successor's credential id as the prior credential's successor credential id.
Operation 40: An admitted rotate MUST commit the successor credential and the prior credential's change in one transition.
Operation 41: An admitted rotate MUST answer the successor's credential id.
Operation 42: An admitted revoke MUST stand the credential in revoked.
Operation 43: An admitted revoke MUST record revoked by reference, reason as revocation reason and now as revocation instant.
Operation 44: A transitioning write MUST commit the status change and the recorded fields in one transition.
Operation 45: IF the store refuses the write THEN an action MUST answer storage-failure.
Operation 46: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 47: A refused action MUST leave the credential as the call found the credential.
Operation 48: A refused [Register] MUST NOT record a credential.
Operation 49: A refused [Rotate] MUST NOT record a successor credential.
Operation 50: The atom MUST NOT offer an expire action.
Operation 51: An admitted read MUST answer EVERY matching credential.
Operation 52: An admitted read MUST answer the effective status PER matching credential.
Operation 53: [Read] MUST NOT answer a verifier.
Operation 54: [Read] MUST NOT record a field.
Operation 55: [Read] MUST NOT refuse a filter.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Execution Contract Logic confinement 3 owns it.
Operation 58: An admitted rotate MUST assign the successor a fresh credential id.
Operation 59: An admitted rotate MUST record the successor's derived verifier.
Operation 60: An admitted rotate MUST record now as the successor's registration instant.
Operation 61: An admitted rotate MUST record a supplied expiry instant on the successor.
Operation 62: IF expiry instant EQUALS blank AND the default validity DOES NOT EQUAL unbounded THEN an admitted rotate MUST record now plus the default validity on the successor.
Operation 63: IF now DOES NOT PRECEDE a supplied expiry instant THEN [Rotate] MUST answer invalid-request.
Operation 64: [Rotate] MUST NOT retain new credential material beyond the successor's verifier.
Operation 65: IF a credential beside the credential id is effective-active for the pair THEN [Rotate] MUST answer not-active.
Operation 66: IF the derivation function refuses the credential material THEN [Register] MUST answer invalid-request.
Operation 67: IF the derivation function refuses the new credential material THEN [Rotate] MUST answer invalid-request.
Operation 68: IF the check function refuses the presented material THEN [Verify] MUST answer material-mismatch.
Operation 69: An admitted read MUST order the answer by registration instant, then by credential id.
Operation 70: IF two credentials of the pair are effective-active at the verify's reading THEN a proceeding verify MUST check against the one carrying the later registration instant.
Operation 71: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted register MUST record no expiry instant.
Operation 72: IF expiry instant EQUALS blank AND the default validity EQUALS unbounded THEN an admitted rotate MUST record no expiry instant on the successor.
Operation 73: IF a filter names a field whose value EQUALS blank THEN an admitted read MUST answer no credential.
```

Term transitioning write: [Rotate] | [Revoke] — every call that would take an effective-active credential to a stored terminal, including a refused one.

Term stored terminal: rotated | revoked.

Term status: active | rotated | revoked — the value a credential stores.

Term standing check: Operation 27, Operation 28, Operation 29 and Operation 65 — every check a transitioning write makes on standing, the credential's own or, for [Rotate], the pair's, before reading the call's inputs.

Term standing rejection: not-active | already-terminal.

Term well-formedness check: Operation 1, Operation 2, Operation 3, Operation 4, Operation 5, Operation 66 and String 7 — every check [Register] makes on the call's own inputs.

Term window reading: live | lapsed — how an active credential's window reads against now.

Term live: the window reading of an active credential whose expiry instant EQUALS blank, OR that now PRECEDES.

Term lapsed: the window reading of an active credential whose expiry instant DOES NOT EQUAL blank and that now DOES NOT PRECEDE; the boundary instant — expiry instant equal to now — reads lapsed.

Term secret verifier: a verifier whose disclosure helps a caller produce matching material — a password hash, a token hash; a public key is not one.

Term settled reading: a reading of now that no registration instant of the pair follows — the only reading at which a pair's credentials are judged together; an earlier reading can see a credential registered after it as live beside its predecessor.

Term effective-active credential: a credential whose status EQUALS active that reads live — what every bound, guard and lookup in this atom means by *the active credential*.

Term lapsed credential: a credential whose status EQUALS active that reads lapsed.

Term proceeding verify: a [Verify] call whose pair carries an effective-active credential.

Term effective status: expired where the credential reads lapsed, and the stored status otherwise — a projection over the credential and now, never stored.

Term verifier: the artifact a derivation function produces from credential material — what this atom stores in place of the material.

Term derivation function: the deployment's function from material to a verifier, declared for one credential type; the verifier alone produces no material the type's check function matches.

Term derivation registry: the deployment's declared map from a credential type to a derivation function and a check function; supplied at the seam.

Term foldable difference: a difference between two strings that trimming, case-folding OR Unicode normalization would remove.

Term default validity: the duration the deployment declares for a [Register] or [Rotate] carrying no expiry instant, which EXCEEDS zero OR EQUALS unbounded; the credential records now plus it, and a deployment declaring it unbounded leaves the expiry instant absent.

Term check function: the deployment's function, declared for one credential type beside its derivation function, answering whether presented material matches a recorded verifier.

Term lease: the longest the deployment lets one holder keep a pair's critical section.

Term overdue holder: a holder that has kept a pair's critical section longer than the lease.

Term filter: principal reference, credential type, credential id, OR any combination of them; a filter naming no field matches EVERY credential.

Term terminal field: rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason — every field a transitioning write records.

Term admitted register: a [Register] call that passes every precondition and whose store write commits.

Term admitted rotate: a [Rotate] call that passes every precondition and whose store writes commit.

Term admitted revoke: a [Revoke] call that passes every precondition and whose store write commits.

Term admitted read: a [Read] call that answers.

WHY:
Operation 7, Operation 30, Operation 34 and Operation 46 are the rejection priority, written as guards rather than as an order (GRACE-lang Timing 13). For a transitioning write the effect is not-known before the standing rejection — Operation 65 among them — before invalid-request (Operation 31 through 33, 63 and 67, and String 9) before storage-failure; for [Register] it is invalid-request (the well-formedness checks, String 7 among them) before duplicate-active-credential before storage-failure.

Operation 8 is the atom's load-bearing subtlety. Every bound and guard here means *effective-active*, never the bare stored status, so a pair may hold a lapsed record standing in active beside a freshly registered successor without breaching Invariant 2.1. An implementation that reads the stored flag instead of the reading is the time-of-check hazard `credential-buggy-toctou.tla` reintroduces.

Operation 19 is a security posture rather than an economy. *No effective-active credential* covers three distinct facts — never registered, every record terminal, the only active record lapsed — and folding them is deliberate: distinguishing them at the verify surface would tell a caller a principal's credential history. It does not hide whether a pair holds an effective-active credential — material-mismatch answers exactly when one exists — and a surface that must hide that too folds both failures into one answer at the composing layer. A composing administrative surface reads the store directly.

Operation 20 is a check-ordering rule and it carries the whole of Invariant 11.1. The window reading is evaluated before any check of presented material, so verified cannot be answered in the interval between a deadline passing and any housekeeping — there is no housekeeping write to race.

Operation 24 names an obligation no record can evidence. A short-circuiting comparison leaks the stored verifier one byte at a time to a caller who can measure the answer, and nothing in the store shows whether the implementation did it; External check 2 is where an auditor goes instead. The rule protects a secret verifier; a public key is not one, and its check leaks nothing a caller does not hold. Nor does it hide which answer is coming: a no-active-credential answer skips the check and returns faster than a material-mismatch, but the answers themselves already tell the two apart (Operation 19's WHY), so timing adds nothing the answer does not say.

Logic confinement is the Contract's (the section titled Logic Confinement Principle in `execution-contract.md`), and the now declaration cites it rather than restating it. The clock is consumed twice per call — by the window reading and by the write's stamps — and both read the one now the seam supplied.

### Invariants

- **Invariant 1 — Registration immutability.**
  ```
  Invariant 1.1: A transitioning write MUST NOT change a property.
  Invariant 1.2: A transitioning write MUST NOT change a terminal field the write found.
  ```
  WHY: Invariant 1.2 is write-once stated as a rule, and unlike its counterpart in [Invitation](./invitation.md) it can bind: a rotated credential carries successor credential id, and a later write that re-linked it would silently rewrite the chain Invariant 7.1 reconstructs. The rule has a reachable violation because this atom's stored terminals carry fields and a second write against them is expressible; nothing here prevents that write except this rule.
- **Invariant 2 — Effective-active uniqueness.**
  ```
  Invariant 2.1: Two credentials effective-active at a settled reading MUST NOT share a pair.
  ```
  WHY: the bound ranges over the reading, not the stored status, which is why a pair may carry a lapsed active record beside its successor (Operation 8) and still satisfy it. Two mechanisms keep it: [Rotate] commits both writes together (Operation 40), so the pair is never doubly effective-active mid-transition; and [Register]'s and [Rotate]'s checks and writes run under one critical section per pair (Capability requirement 8), so neither two registrations nor a registration and a rotation can both pass the check.
- **Invariant 3 — Sole-holder verification.**
  ```
  Invariant 3.1: [Verify] MUST answer verified ONLY IF the presented material matches the verifier of the effective-active credential of the pair the call names PER the check function.
  ```
- **Invariant 4 — Revocation is absorbing.**
  ```
  Invariant 4.1: A verify reading a revoked credential MUST NOT answer verified.
  ```
- **Invariant 5 — A stored terminal is absorbing.**
  ```
  Invariant 5.1: A credential whose status IS IN the stored terminals MUST NOT leave the stored terminal.
  ```
  WHY: a lapsed credential draws the same two rejections a stored terminal does — not-active from [Rotate], already-terminal from [Revoke] — and for a different reason, which is worth saying because the shared answers invite a reader to assume a shared mechanism. A stored terminal is excluded by what it stores; a lapsed credential is excluded by what the clock says, stands in active still, and is owned by Invariant 11.1 and Invariant 12.1 rather than here.
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
  WHY: the one-way property is the deployment's to supply and not a property of any reachable state, so it belongs to the deployment's family, not this one — an `Invariant` is a property of every reachable state (GRACE-lang Standard label 1) and a deployment's obligation is a `Capability requirement`.
- **Invariant 9 — The revocation record is complete.**
  ```
  Invariant 9.1: EVERY revoked credential MUST carry a non-blank revoked by reference.
  Invariant 9.2: EVERY revoked credential MUST carry a non-blank revocation reason.
  Invariant 9.3: EVERY revoked credential MUST carry a revocation instant.
  ```
- **Invariant 10 — Credential durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a credential from the store.
  Invariant 10.2: A storage-failure rejection MUST leave no partial credential in the store.
  ```
- **Invariant 11 — A lapse precludes verification.**
  ```
  Invariant 11.1: A verify reading a lapsed credential MUST NOT answer verified.
  ```
  WHY: the expiry analogue of Invariant 4.1, and the difference is the whole of this atom's render-time form. Revocation excludes by a write; a lapse excludes by a reading, and the mechanism is Operation 20's check ordering rather than any stored flag. Because a pair holds at most one effective-active credential (Invariant 2.1), once that one lapses no verified is possible for the pair until a fresh register.
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when a credential lapses.
  Invariant 12.2: An admitted read MUST compute the effective status from the credential's expiry instant and now.
  ```


WHY:
Invariant 2.1 and Invariant 3.1 together give the *authentication integrity* property — a verify is answered by exactly one credential per pair, only for material matching it, and only while it is effective-active; whose hands the material was in is the composing pattern's to establish (Composition note 12). Invariants 4, 5, 11 and 12 give *terminal finality*: the system cannot be raced into verifying against a revoked, rotated or lapsed credential, and expiry achieves it with no stored flag to revert. Invariants 6 and 7 give *rotation auditability* — how a principal's credential evolved is reconstructable without source code or runbooks.

---

## Examples

### Password authentication — registration and verification

`register(user_u91, "correct horse battery staple", "password")` → `cred_c01`, standing active with no deadline. The material is derived to a verifier and discarded; nothing in the store holds it. Later, `verify(user_u91, "password", "correct horse battery staple")` → verified. `verify(user_u91, "password", "hunter2")` → `failed-verification(material-mismatch)`.

### API token — rotation

`register(svc_s03, <token>, "api-token", 2026-04-01)` → `cred_c07`. On a ninety-day policy the service rotates before the deadline: `rotate(cred_c07, <new token>, 2026-07-01)` → `cred_c11`. Two writes commit together — `cred_c11` stands active with its own verifier, registration instant and deadline, and `cred_c07` stands rotated carrying rotation instant and `successor_credential_id: cred_c11`. An auditor walks `cred_c07 → cred_c11` and reads the gap between each registration and its predecessor's rotation.

### The deadline passes

`cred_c11` carries `expires_at: 2026-07-01`. At 2026-07-01 exactly it already reads lapsed — the boundary instant is on the lapsed side. On 2026-07-02 nothing has happened to the record: it still stands active, carries no terminal field, and read returns it with an effective status of expired. verify against the pair answers no-active-credential; `rotate(cred_c11, …)` answers not-active; `revoke(cred_c11, …)` answers already-terminal — each by reading, each writing nothing. And because `cred_c11` no longer occupies the slot, `register(svc_s03, <material>, "api-token", …)` succeeds, leaving two records standing active for the pair, exactly one of them effective-active.

### Public key — a signed challenge

`register(svc_s04, <Ed25519 public key>, "public-key")` → `cred_c20`; the verifier is the key's canonical encoding (Ed25519 is an elliptic-curve signature scheme). A composing pattern issues a challenge and the holder signs it: `verify(svc_s04, "public-key", {challenge, signature})` → verified. The same signature presented again also answers verified — this atom does not know the challenge was used (Non-goal 31, 36) — which is why a deployment composes a challenge pattern that refuses a spent one.

### Revocation after exposure

Tokens for `svc_s03` turn up in a log file. `revoke(cred_c11, admin_a01, "log-exposure-2026-09-12")` → revoked, stamping revocation instant, revoked by reference and revocation reason. A later auditor reading only the store knows when, why and whom the caller named, without asking anyone; that the named actor was the caller is the composing pattern's to show (Composition note 15).

### Rejection paths

`register(user_u91, "x", "password")` on a pair that already holds an effective-active credential → duplicate-active-credential; the caller rotates instead. `register(user_u91, "x", "Password ")` → invalid-request, because no derivation function is registered for that type — which is also what stops a byte-exact key from quietly admitting a second effective-active credential under a near-duplicate name. `rotate(cred_unknown, "x")` → not-known. `rotate(cred_c11, "y")` on a reading before 2026-07-01, beside a `register(svc_s03, "z", "api-token")` that took its reading after 2026-07-01 and committed first → not-active: the register found `cred_c11` lapsed and was admitted, and the rotate, reading `cred_c11` live, finds the register's credential effective-active beside it (Operation 65). `register(user_u92, "z", "password")` whose store write fails → storage-failure, and no record exists (Operation 48). `revoke(cred_c07, admin_a01, "  ")` on the already-rotated record → already-terminal, not invalid-request: the standing check runs first (Operation 34).

### Regulated adversarial scenarios

- **Regulator audit.** *Was the service account's API credential rotated inside the ninety-day window?* Filter the store to the pair and order by registration instant; each rotated record carries rotation instant and a link forward. Invariant 7.1 and Invariant 7.2 are what make the chain complete rather than merely plausible — no rotation is omitted, and no link leaves the pair.
- **Disputed transaction.** *I did not log in from that address.* The composing [Login](../compositions/login.md) records name the credential used; this store shows that credential's standing and registration instant. Invariant 3.1 is the structural rebuttal: if verified was answered, the presented material matched the recorded verifier. Whether the caller was the principal or someone holding their secret is a separate investigation, and this atom's records bound its window.
- **Breach investigation.** A batch of tokens may have been exposed. Filter to the pair, read each effective status against the investigation clock, and revoke what is still effective-active. Invariant 9.1 through 9.3 are what make the resulting record answer *when, why, and whom the caller named* from the store alone; that the named actor was the authenticated caller is the composing pattern's to prove (Composition note 15, External check 10).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the credential store and a read-time clock alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find no two effective-active credentials sharing a pair, at a settled reading the auditor supplies (Invariant 2.1, Capability requirement 8, Operation 65).
Check 1.2: An auditor MUST read effective-active from the window reading and NOT from the stored status (Operation 8, Invariant 2.1).
Check 2.1: An auditor MUST find no credential storing expired as a status (State 6).
Check 2.2: An auditor MUST find no credential carrying a lapse instant (State 7, Invariant 12.1).
Check 2.3: An auditor MUST reproduce an admitted read's effective status from the credential's expiry instant and a clock the auditor supplies (Invariant 12.2).
Check 3.1: An auditor MUST find a successor credential id naming a credential on EVERY rotated credential (Invariant 7.1).
Check 3.2: An auditor MUST find EVERY rotated credential's successor carrying the rotated credential's pair (Invariant 7.2).
Check 3.3: An auditor MUST find a rotation instant on EVERY rotated credential (State 3).
Check 4.1: An auditor MUST find a non-blank revoked by reference on EVERY revoked credential (Invariant 9.1).
Check 4.2: An auditor MUST find a non-blank revocation reason on EVERY revoked credential (Invariant 9.2).
Check 4.3: An auditor MUST find a revocation instant on EVERY revoked credential (Invariant 9.3).
Check 5.1: An auditor MUST find no credential material beyond the verifier in a credential (State 9).
Check 5.2: An auditor MUST find no presented material in a credential (State 10).
Check 5.3: An auditor MUST find no verifier in an admitted read's answer (Operation 53, State 8).
Check 5.4: An auditor MUST find no credential material in an admitted read's answer (Invariant 8.1).
Check 6.1: An auditor MUST find no credential whose status IS NOT IN the stored terminals on a later read of a credential a prior read found in that stored terminal (Invariant 5.1).
Check 6.2: An auditor MUST find no terminal field on an active credential (State 5).
Check 7.1: An auditor MUST find a re-read credential's properties unchanged across an admitted rotate (Invariant 1.1, Invariant 6.1).
Check 7.2: An auditor MUST find a re-read credential's terminal fields unchanged across a later write (Invariant 1.2).
Check 7.3: An auditor MUST find a rotated credential's fields beside status, rotation instant and successor credential id unchanged across the rotate (Invariant 6.2).
Check 8.1: An auditor MUST find no credential absent from a later read, beside the credentials a composing Retention Window's purge record names (Invariant 10.1, State 15).
Check 8.2: An auditor MUST find the store instance's credential count no lower on a later read, beside the credentials a composing Retention Window's purge record names (State 15).
Check 9.1: An auditor MUST reconstruct EVERY credential of one pair from the store (State 1, State 15, Invariant 10.1).
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
External check 7: A deployment needing the store confirmed free of a retroactive edit MUST read the composing Tamper Evidence (Non-goal 21).
External check 8: A deployment needing a verified answer confirmed against the credential's standing MUST read the composing Event Log's verify events beside the store (Invariant 3.1, Invariant 4.1, Invariant 11.1).
External check 9: A deployment needing a storage-failure confirmed to leave no partial credential MUST read the implementation's transactional boundary (Invariant 10.2).
External check 10: A deployment needing a revoked by reference confirmed as the authenticated caller MUST read the composing pattern's authentication (Composition note 15).
External check 11: A deployment needing a credential write confirmed to an authorized caller MUST read the composing pattern's authentication (Composition note 12, Composition note 13, Composition note 14).
External check 12: A deployment needing [Read] confirmed to an authorized caller MUST read the composing pattern's authorization (Composition note 16).
External check 13: A deployment needing a check function confirmed to match the credential type's derivation function MUST check material against the verifier derived from the material (Capability requirement 29, 30).
External check 14: A deployment needing a verifier salted and costly to guess confirmed MUST read the derivation registry (Non-goal 39).
External check 15: A deployment needing one effective-active credential per principal confirmed across spellings MUST read the deployment's own reference canonicalization and credential type declarations (Capability requirement 6, Capability requirement 13).
```

WHY:
External check 1 and External check 2 are this atom's two blindest spots and the only two whose breach is invisible in every conformance check above. A store that never held material still fails the atom's purpose if the deployment logged the material on its way in, and a verifier compared byte by byte with an early exit leaks itself to anyone who can time the answer. Neither leaves a record, so neither can be a Check; stating them as External checks is the difference between a gap and a disclosed boundary.

External check 4 is the lost-answer family. verified and failed-verification are answers and nothing else — [Verify] writes no field (Operation 26) — so the store cannot say how often a principal authenticated or failed to. That is deliberate (Non-goal 25; the failure count a lockout needs is Non-goal 8's) and it means the authentication history lives in whatever composes this atom, never here — which is also why Invariant 3.1, 4.1 and 11.1, each a claim about a verify answer, clear only there (External check 8).

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
Non-goal 20: The atom MUST NOT detect a rewrite under the store.
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

WHY:
Non-goal 15 and Non-goal 16 are the boundary NIST (US National Institute of Standards and Technology) SP 800-63B is usually read as crossing. This atom satisfies 800-63B's *verifier storage and lifecycle* requirements and enforces none of its *authenticator strength* requirements — no minimum length, no breached-password screening, no entropy floor — because each of those is a property of the material rather than of the binding, and the derivation function is where a deployment discharges them.

Non-goal 19 is the compromise case and the reason the store is append-only in spirit as well as in rule. A credential later found to have been compromised before it was revoked does not cause any record here to change; a composing pattern writes *new* records that reframe the prior answers as untrustworthy. The store stays immutable and the meaning of its records changes by composition.

Non-goal 29 through 31, 34 and 36 are what a public key's verified answer does not say: that the signed message was fresh, that it was signed for this purpose, or that the registering caller held the private key. A signature made for another purpose verifies here; binding the challenge to its purpose and its moment is the forthcoming challenge pattern's, and proof of possession at registration is the enrollment pattern's (Non-goal 35). Until one is composed, public-key authentication here is replayable, and the Summary says so.

Non-goal 37 is the reuse a strength floor cannot see: the derivation function never meets a prior verifier, so it cannot refuse the old material coming back. A deployment that must refuse a secret's return to the pair's current credential verifies the new material against the pair before rotating (Composition note 17). That reaches no further: an older rotated credential is not checked, and a public-key or fido2 type presents a signature rather than the new key while the verifier that would let a caller compare keys is never exposed (State 8, Operation 53).

Non-goal 22 and Non-goal 32 put erasure where retention law puts it. This atom never removes a credential and says so (State 13, 15; Invariant 10.1); a lawful erasure is a composing Retention Window's purge, which records what it removed, runs on the store under the Retention Window's own surface rather than one this atom offers, and takes a pair's rotation chain whole (Composition note 18), so no surviving link names a purged credential; Check 8 reads the count beside that record rather than against it.

Non-goal 38 leaves a function's fault with the host. It is not a guard failure, an effect failure of the store or an invariant violation, the three classes of the Execution Contract's Error model, and the host's own failure reaches the caller before any write. What the atom keeps is Invariant 3.1: a verify that gets no result from its check function cannot answer verified.

Non-goal 39 is what Capability requirement 5 does not say. It asks the verifier to be one-way, not to resist guessing: a verifier made by an unsalted fast hash satisfies it, and offline guessing of a weak secret is what a salt and a cost slow down, and the salt is one means of that cost. Both are the derivation function's to supply, as Non-goal 15 and Non-goal 16 leave material strength to it, and the deployment's to confirm (External check 14).

Non-goal 26 is the honest limit on the stored terminals. A credential nobody rotates or revokes stays standing in active forever, reading expired once its deadline passes — and if it carries no deadline it reads active forever. Nothing here makes that end.

Non-goal 27 is the price of the derivation and it is cheaper here than it looks. Two readers with skewed clocks can disagree near a deadline about whether a credential reads expired — and nothing is written either way, no record diverges, and the disagreement is about a projection, not about state. The exposure is the skew itself: a reader whose clock runs slow can answer verified after the deadline by another's. Bounding that skew is the Contract's (Execution Contract Logic confinement 7), not this atom's.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: The implementation MUST commit a transition whole.
Atomic writes 2: The implementation MUST discard an uncommitted transition whole.
Atomic writes 3: The implementation MUST own the transactional boundary.
Atomic writes 4: The implementation MUST NOT repair a dangling transition.
Atomic writes 5: A refused rotate MUST leave the prior credential in active.
```

WHY:
Atomic writes 5 is the half of rotation a partial write breaks. Two records change and a crash between them leaves either a successor nobody points at or a predecessor pointing at nothing; the second is the one that breaks Invariant 7.1, and Operation 40 is what forbids it.

### Concurrency

```
Concurrency 1: The implementation MUST commit the standing check and the status change of a transitioning write as one atomic operation.
Concurrency 2: A transitioning write finding the credential a concurrent write already moved MUST answer a standing rejection.
Concurrency 3: A [Register] finding an effective-active credential a concurrent register committed for the pair MUST answer duplicate-active-credential.
Concurrency 4: The store MUST answer [Verify]'s read from a committed state.
Concurrency 5: IF a verify's read PRECEDES a transitioning write's commit THEN the verify MAY answer verified.
```

WHY:
Concurrency 5 is the window Invariant 4.1 and 11.1 are read across. A verify answers for the state it read; a revoke or rotate committing after that read changes the next answer, not this one. Closing the window would put [Verify] under the pair's critical section, a lock on every login for a race a composing pattern can close itself by re-verifying after a revoke or rotate it initiated.

### Indeterminate outcome

```
Indeterminate outcome 1: A caller receiving no answer to a credential write MUST NOT retry the credential write BEFORE the caller reads the store.
Indeterminate outcome 2: A caller MUST NOT read a transport fault as a storage-failure.
Indeterminate outcome 3: A caller retrying a landed [Register] MUST read duplicate-active-credential as the first call's landing.
Indeterminate outcome 4: A caller retrying a landed [Rotate] MUST read not-active as the first call's landing.
```

WHY:
A lost acknowledgement leaves the caller holding no id: a retried register answers duplicate-active-credential and a retried rotate not-active, each true and neither carrying the id the first call assigned. Reading the store by the pair (Operation 69) is how the caller recovers it, which is why Indeterminate outcome 1 puts the read before the retry.

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


WHY:
String 7 and String 9 name the two actions whose string inputs can exceed the bound. [Rotate]'s only string input is the credential id, and an over-long one names no credential, so Operation 27 answers not-known first. [Verify] and [Read] carry none, and need none: no credential is stored under an over-long reference or type, so a verify naming one answers no-active-credential and a read filtering on one matches nothing.

String 10 is the material's counterpart to String 5 and String 6. Material is whatever the derivation function normalizes (Capability requirement 28), so a whitespace-only password is material and only an absent or empty one is blank; an instant is blank when absent, having no whitespace form.

Byte-exactness bites hardest on credential type, because that string is half the key Invariant 2.1 ranges over: under a folding comparison `password` and `Password ` would be one type, and under a byte-exact one they are two, so a principal could hold two effective-active credentials that no invariant catches. Identity 11 is what closes it — a type naming no derivation function is refused, so the near-duplicate never reaches the store. Material is exempt from the length bound only insofar as a derivation function declares its own (Capability requirement 14).

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
Composition note 9: A composing Tamper Evidence MUST cover EVERY credential the store holds.
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

WHY:
Composition note 3 is [Login](../compositions/login.md)'s cascade seen from below, and Login's own Composition note 3 gives the call to the deployment, which is why this note does too; and this atom cannot state it as an invariant of its own: it neither issues nor sees sessions, so a revoked credential leaving a live session behind is a fact only the composition can be held to. The note states the obligation and the composition owns the guarantee — the same shape [Invitation](./invitation.md)'s *invitation gates enrollment* takes.

Composition note 7 is separate from Composition note 5 and Composition note 6 on purpose. A verify is neither admitted nor refused in this atom's vocabulary — both of its answers are first-class results of a query that wrote nothing — so a log wired only to admitted and refused actions would carry every registration and no authentication at all, which is the opposite of what an authentication audit wants.

Composition note 12 through 15 are the section titled *Authentication precedence* in `pressure-testing.md` applied to this atom's writes, and the binding half is the authorized caller: authenticated *as* the principal, or authorized over the principal, never merely authenticated as someone. A principal's first credential has nothing to authenticate against, which is why the term names an enrollment pattern's own proof, and why a deployment offering open self-registration declares it as its enrollment pattern rather than skipping the note. Composition note 16 closes the history [Verify] folds: Operation 19 hides why no effective-active credential exists, and [Read] answers exactly that, so a caller reaching [Read] unauthorized undoes the fold. Revoked by reference is the caller's word, and Identity 10 forbids checking it here; a record that says *by whom* proves only whom the caller named until the composing pattern binds the name to the authenticated caller.

Composition note 10 is the one an integrity pattern gets wrong by doing its job. A hash chain that covers the verifier is correct; one that *publishes* the covered value to make the chain checkable has exported the thing this atom exists to keep (State 8).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the store; the seam; the transition; a composing pattern; a caller; a principal; an auditor; a regulator; an investigator; a reader; a credential; an active credential; an effective-active credential; a lapsed credential; a rotated credential; a revoked credential; a successor credential; a prior credential; an action; a transitioning write; a refused action; a refused rotate; a rejection; an answer; a derivation function; an opaque reference; a string input; a filter; the store instance's credential count.

Term records: credential — one principal's binding to one verifier for one credential type, carrying credential id, principal reference, credential type, verifier, registration instant, a status and, where supplied or set, expiry instant, rotation instant, successor credential id, revocation instant, revoked by reference and revocation reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, acknowledge, canonicalize, declare, compose, remove, bind, decide, define, bound, reach, accept, retain, trim, case-fold, compute, reproduce, reconstruct, verify, issue, detect, guarantee, take, derive, expose, store, own, persist, enumerate, distinguish, select, walk, mutate, serialize, rotate, revoke, block, invalidate, migrate, recover, reinterpret, constrain, count, sequence, release, run, rebind, check, order, lower, retry, authorize, purge.

Term value sets: status = active | rotated | revoked. stored terminal = rotated | revoked. standing rejection = not-active | already-terminal. window reading = live | lapsed. property = principal reference | credential type | verifier | registration instant | expiry instant. terminal field = rotation instant | successor credential id | revocation instant | revoked by reference | revocation reason.

Term bounds: default validity, length bound, lease, material bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: credential, credential id, lapse instant, pair, property, reference, store instance, seam, transition, now, transitioning write, stored terminal, status, standing check, standing rejection, well-formedness check, window reading, live, lapsed, effective-active credential, lapsed credential, proceeding verify, effective status, verifier, derivation function, derivation registry, foldable difference, length bound, default validity, check function, filter, fresh credential id, lease, authorized caller, credential write, secret verifier, settled reading, overdue holder, terminal field, admitted register, admitted rotate, admitted revoke, admitted read, string input, blank, verification failure.

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

The transitioning write that replaces a credential — recording a successor in [Active] for the same pair — a fresh [Credential Id], a [Verifier] derived from the new credential material, its own registration instant and [Expiry Instant] — standing the prior credential in [Rotated], and stamping [Rotation Instant] and [Successor Credential Id] on it. Both writes commit together. Legal only against an effective-active credential with no other effective-active credential beside it for the pair; otherwise [Not Active].

Kind: Operation

#### Revoke

The transitioning write that cancels a credential, standing it in [Revoked] and recording [Revoked By Reference], [Revocation Reason] and [Revocation Instant]. Legal only against an effective-active credential; otherwise [Already Terminal].

Kind: Operation

#### Read

The read-only query answering the matching [Credential] records, each carrying its stored fields — never the [Verifier] — and its derived [Effective Status]. Refuses nothing.

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

The raw secret the principal supplies to [Verify]. Checked against the stored [Verifier] through the credential type's check function, then discarded. Never stored.

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

The refusal returned when a required argument is blank, a [Credential Type] names no derivation function, a supplied [Expiry Instant] does not exceed [Now], the derivation function refuses the material, or — on [Register] and [Revoke] only — a string input exceeds the deployment's length bound. On a transitioning write it is reached only after every standing check passes.

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

The refusal a transitioning write returns when the supplied [Credential Id] names no credential. Reached before either standing rejection, so a caller reading [Not Active] or [Already Terminal] knows the id resolved.

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

The refusal any action returns when the store refuses the write after every precondition passes. No credential is recorded, or the credential remains as the call found it.

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

- **NIST SP 800-63B-4 (authentication and authenticator management, revision 4)** — the primary standard here. Authenticator assurance levels, stored verifiers rather than raw secrets (the salt supplied at the seam when the function consumes one, Capability requirement 24, and the cost the derivation function's own, neither of which the atom requires, Non-goal 39), and rotation and revocation requirements correspond directly to this atom's rules. The correspondence is to 800-63B's *verifier storage and lifecycle* half specifically; the *authenticator strength* half — minimum length, breached-password screening, entropy floors — is not enforceable here and lives in the derivation function (Non-goal 15, Non-goal 16). Identity proofing is 800-63A's and is deliberately not cited: that is [Party Identity](./party-identity.md)'s.
- **FIDO2 (the FIDO Alliance's second authentication standard) / WebAuthn (W3C — the World Wide Web Consortium — Web Authentication Level 2)** — for phishing-resistant hardware authenticators. A `fido2` [Credential Type] takes the attestation object as [Credential Material]; the [Verifier] is the public key extracted from it, and [Verify] checks a presented assertion against it through the type's check function; the challenge the assertion signs is a composing pattern's (Non-goal 30).
- **RFC 7519 (JSON Web Token)** — an `api-token` [Credential Type] stores a hash of the raw token as its [Verifier]. The atom does not interpret token claims; that is the composing pattern's.
- **OpenID Connect (OIDC) Core 1.0** — the OIDC login flow ends in a verification this atom answers, and the verification event itself is a composing Event Log's (Composition note 7); [Login](../compositions/login.md) is the Grace Commons expression of the authorization-code flow.
- **PCI DSS Requirement 8 (identify and authenticate access)** — the atom satisfies the structural requirements: one effective-active credential per pair, rotation producing a new record, revocation recorded with the attribution the caller supplies. The rotation period is not enforced here: the default validity (Capability requirement 7) is a default that a supplied expiry overrides, so the atom bounds no credential's lifetime and a deployment needing a maximum age enforces it in the pattern that schedules its rotations. Complexity rules and the lockout threshold are likewise the deployment's (Non-goal 8, Non-goal 16).
- **ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 27001:2022 Annex A controls 5.17 (authentication information) and 8.5 (secure authentication)** — the registration, rotation and revocation lifecycle corresponds to the authentication-information controls there; the 2013 edition's A.9.4 is the superseded numbering.
- **GDPR (EU General Data Protection Regulation) Article 32 (security of processing)** — State 9, State 10 and the one-way verifier discipline contribute to the technical measures Article 32 requires. A deployment storing a biometric verifier assesses Article 9 separately (Non-goal 23).
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (person or entity authentication)** — the verified answer is the structural mechanism for this requirement.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing identity proofing, sessions, authorization and multi-factor orchestration as separate atoms rather than absorbing them here.
- **NIST 800-132 (password-based key derivation)** — the reference for which derivation functions satisfy the one-way property Capability requirement 5 requires.

---

## Status

`grounded on Final Critique 12 — 2026-09-29` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 12 — 2026-09-29
formal: verified — credential.tla + 4 twins, 2026-09-29
last gate: 2026-09-29 — Final Critique 12, cold reader — 0 foundational, 12 refining (routed open)

open:
- 2026-09-29-e · refining · Final Critique 12 · routed open, non-blocking: precondition, material bound and blank used as terms with no entry; the NIST verifier-storage claim against Non-goal 39 and Capability requirement 5; Capability requirement 35's WHY narrowing id non-reuse to before a commit, which a purge would reopen; a read naming neither a pair nor an id has no routing across store instances; a type withdrawn from the registry leaves verify and rotate with no answer; a store read failure has no arm on verify or read; a public key's check normalizes nothing the page names; the Summary's at-most-one claim unscoped to a settled reading; the regulator scenario's no rotation is omitted overclaims Invariant 7; Operation 69's direction and collation; a lapse reopens a principal reference to any enrollment proof, unstated; one snapshot for verify's window reading, selection and check, unpinned → one refining pass
- 2026-09-29-d · refining · Final Critique 11 · routed open, non-blocking: Invariant 1.2's WHY claims a reachable violation Operation 28 and 29 already refuse; Operation 24 binds the host's check and sits among the transition's rules; Capability requirement 21 through 23 restate a lease beside the draft Lease atom, and overdue has no time base; Invariant 7 declares no acyclicity or single predecessor; no External check reaches Capability requirement 33, 35 or 36; Identity 5 global against a per-instance store term, and Capability requirement 13's opaque reference reaching credential ids; the NIST line's verifier-storage claim beside Non-goal 39; fido2 and canonicalizes before their glosses; Operation 69's tie order unexplained; Example 1's deadline assumes an unbounded default; Indeterminate outcome 3 and 4 read another caller's landing as the first call's; the Revocation after exposure example revokes on 2026-09-12 a credential that lapsed on 2026-07-01, which answers already-terminal; the Clock semantics tombstones inside the Capability requirement block → one refining pass, gated with the rest
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/credential.md`.

- **2026-09-29 — A holder's section ends only at its lease, and a write is judged at its commit.** *Chose:* the pair's critical section ends when its holder releases it or when the lease runs out, and for no other reason, and the store commits a write ONLY IF the writer still holds the section at the commit (Capability requirement 22, 23); the release of a section on a holder judged dead is deleted. *Over:* releasing the section on a belief that the holder had died, with the commit refused only for an overdue holder. *Because:* Final Critique 10 (a cold reader): a store cannot tell a dead caller from a slow one, so a holder judged dead and released could still commit — a second holder passes the check and commits, and the first holder's stale write lands beside it, two effective-active credentials for one pair, which is the breach Capability requirement 8 exists to prevent. The same round drew two lines the page had left open: a fault in a derivation or check function is the deployment's to answer (Non-goal 38), and the salt and the cost of guessing are the function's to supply and not the atom's to require (Non-goal 39).
- **2026-09-29 — The model re-derived against the grounded page.** *Chose:* per-credential deadlines, a call's one reading held from its start to its commit, the pair's section with a holder released as overdue, revoke outside the section, and a store that may begin holding one credential, checked at every settled reading; four twins, each removing one mechanism — the successor link, the section, the refusal of an overdue commit, Operation 65 — and each rejected. *Over:* the 2026-06-21 model, one deadline for every credential and one reading per step, which could not express a rotate on an early reading racing a register on a late one. *Because:* Operation 65 and Capability requirement 22 and 23 exist for exactly those races, and a twin that breaks Invariant 2.1 without each is what shows each is needed.
- **2026-09-29 — The two functions a type declares, tied.** *Chose:* a check function that matches the material its type's derivation function derived the verifier from, normalizing as it does (Capability requirement 29, 30), confirmed by an External check on material the auditor supplies. *Over:* two independent declarations, under which an always-no-match check function satisfied every rule. *Because:* Final Critique 9 (a cold reader); the split was this page's own, made when Final Critique 7 separated checking from deriving. The same round scoped Invariant 2.1, 4.1 and 11.1 to the reading they hold at, moved Identity 12 through 15 to the deployment's family, and wrote down what a verified public key does not establish.
- **2026-09-29 — Authenticated as whom.** *Chose:* the authorized caller — authenticated as the principal the call names, admitted by an enrollment pattern's own proof for a principal holding no credential, or authorized over the principal by a composing Permissions decision — behind every credential write (Composition note 12 through 14), and [Read] exposed only to an authorized caller (Composition note 16). *Over:* *authenticating the caller*, which a caller authenticated as Alice satisfies while rotating Bob's credential, and which a principal's first registration cannot satisfy at all. *Because:* Final Critique 8 (a cold reader), and the binding half of the section titled *Authentication precedence* in `pressure-testing.md`. The same round moved lockout and multi-factor sequencing off Login, which disclaims both, onto the deployment.
- **2026-09-29 — Built cold: where the cryptography runs.** *Chose:* the derivation and check functions run at the seam, and the entropy a salted derivation consumes is supplied there (Capability requirement 24 through 26); the default validity may be declared unbounded, where the term said a deployment could declare none against Capability requirement 7's obligation to declare it; Operation 20 speaks of checking presented material, as Operation 21 through 23 do. *Over:* a registry *supplied* at the seam and silently *run* inside the transition, with no source for a salt. *Because:* the cold regeneration built a salted password and a public key, and Execution Contract Logic confinement 1 and 3 allow neither the cryptography nor the entropy inside a transition (council read 266).
- **2026-09-29 — What a cold reader found the page never said.** *Chose:* a rotate that states its successor whole (Operation 58 through 64) and may carry the successor's own deadline, with the default a validity duration rather than an instant (Capability requirement 7), since a fixed default instant registers credentials born lapsed once it passes; [Rotate] under the pair's critical section beside [Register], refused when another credential is effective-active for the pair (Capability requirement 8, Operation 65), since a rotate on an early reading and a register on a late one otherwise both commit; a check function per type (Capability requirement 18), since *derive, then compare equal* cannot check a salted hash or a signature, and one-time-code seeds out of scope, since their verifier is not one-way; a type never rebound to another function (Capability requirement 19, 20), since the record carries its type and not its function; the three writes callable only after the composing pattern authenticates the caller, who is what revoked by reference names (Composition note 12 through 15); and a check or external check for each of the seven invariants no check named; and String 7 through 9 narrowed to String 7 and String 9, since [Rotate]'s only string input is the credential id, which an over-long value leaves naming no credential, so Operation 27 answers not-known first and String 8 could never fire. *Over:* the page as the 2026-09-13 rewrite left it and Final Critique 6 passed it. *Because:* Final Critique 7, a cold reader (Sonnet), whose findings a–h were each something a conforming implementation needs and the page did not state.
- **2026-09-29 — The forbidden marker gets its own name.** *Chose:* lapse instant, the instant a store would write when a credential starts to read lapsed, as what State 7 and Check 2.2 forbid. *Over:* *expiry instant*, the page's name for the deadline, which State 2 permits, Operation 12 and 13 record and Invariant 12.2 and Check 2.3 read — so State 7 forbade what four rules require and Check 2.2 failed every store holding a deadline. *Because:* the WHY always meant the `expired_at` column beside a status that stays active; the term it needed did not exist, and it borrowed the nearest one (Final Critique 6, GLM).
- **2026-09-28 — The length bound answers only where a signature can carry it.** *Chose:* String 7 through 9 name [Register], [Rotate] and [Revoke]. *Over:* *an action*, which obliged [Verify] and [Read] to answer an arm their signatures do not carry. *Because:* the rule and the signature block contradicted each other, and the two reads already answer an over-long input correctly without the arm.
- **2026-09-13 — Effective-active uniqueness is enforced by a critical section over the pair, not by a unique partial index.** *Chose:* Capability requirement 8 — the store runs the effective-active check and the register write for one pair as one critical section. *Over:* the store constraint the prose named, *a unique partial index on `(principal_ref, credential_type)` where `status = Active` and the credential is not past expiry instant*. *Because:* an index predicate cannot reference now, and the half of it that can — `where status = Active` — forbids exactly the case Operation 8 permits, a lapsed record standing in active beside its successor. The obligation the prose was reaching for is unchanged; only the mechanism is, and the formal twin built against the old reading is an open Ledger line rather than a silent inheritance.
- **2026-09-13 — Every bound, guard and lookup means effective-active, declared once.** *Chose:* window reading: live | lapsed, and effective-active credential as a credential standing in active that reads live. *Over:* restating *stored active and now < expiry instant* at the uniqueness guard, the verify lookup, the rotate precondition and the revoke precondition, which is how the prose carried it four times. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and this is the atom's single most misreadable claim — an implementation that reads the stored flag at any one of those four sites is the hazard `credential-buggy-toctou.tla` exists to catch.
- **2026-09-13 — live admits an absent deadline, which the corpus's other two window readings do not.** *Chose:* a two-member reading whose live member covers both *no deadline* and *deadline not yet reached*. *Over:* a three-member reading separating the unbounded case. *Because:* nothing in this atom treats an unbounded credential differently from one inside its window — every guard asks the same question and gets the same answer — so a third member would be a distinction no rule consumes. It is worth recording because [Provisional Commitment](./provisional-commitment.md) and [Invitation](./invitation.md) both declare a window reading over a *mandatory* deadline, and this is the first where the deadline is optional.

NOTE: End of Credential.

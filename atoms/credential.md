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

It works through records that bind a principal to a **verifier**: an artifact derived one-way from the secret material — a hashed password, a public key — that lets the system check a later presentation without ever keeping the original secret. The raw material is used at registration and at each check, then discarded. Only the verifier persists.

Each record stands in one live status, active, or in one of two permanent stored ends: rotated (replaced by a newer credential) or revoked (deliberately cancelled, with who, when and why recorded). A credential also *expires* — but expiry is not a stored status. When the deadline passes, a still-active record is simply shown expired, computed at read time from the deadline and the clock, never written.

One principal holds at most one *effective-active* credential of a given type at a time, where effective-active means stored active **and** not past its deadline. A lapsed record no longer occupies that slot, so a fresh registration is permitted beside it. Rotation is clean: the successor is a new record and the predecessor moves to rotated carrying a link forward, so the whole chain of replacements is walkable.

This is the mechanism behind password login, public-key authentication, one-time codes, API tokens and hardware keys. Proving who the principal is in the first place, sequencing multiple factors, keeping someone logged in, and deciding what they may do are each a separate pattern.

---

## Intent

Authenticated systems require an actor to prove identity before acting with consequence — moving funds, prescribing medication, signing a contract, reaching a protected record. The proof is a credential: something the actor knows, something the actor has, or something the actor is, bound to a signing key. What is constant across all three is the *binding* — the association between a specific principal and specific material, established at registration and queryable at verification.

This atom isolates that binding. It does not implement login flows, sessions, identity proofing, multi-factor orchestration or authorization. The answer it gives is binary — verified, or a named reason it was not — and it is answerable from stored records and a clock, without the system's runtime state and without the calling actor's testimony.

This is a freestanding atom in the EOS sense: its own state, its own four writes and one read, and its own operational principles — verifiers are stored and material is not, rotation produces a new record, a stored terminal is absorbing, and expiry is derived.

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
Identity 9: The atom MUST NOT confirm that a principal ref names a known principal.
Identity 10: The atom MUST NOT confirm that a revoked by ref names a known actor.
Identity 11: The atom MUST confirm that a credential type names a derivation function in the derivation registry.
Identity 12: The deployment MUST route EVERY call to one store instance.
```

Term credential: the record this atom holds — one principal's binding to one verifier, for one credential type.

Term credential id: the opaque value naming one credential — a [Credential Id]; assigned from the id material the seam supplies.

Term pair: principal ref and credential type together — the key the effective-active bound ranges over.

Term property: principal ref | credential type | verifier | registered at | expires at — what a credential carries from registration and never changes.

Term reference: credential id, principal ref, revoked by ref OR successor credential id — every opaque reference this atom records.

Term store instance: one named credential store a call is routed to; credential id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the id material and the derivation registry here.

Term transition: the atom's evaluation of one call against the credential store, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

WHY:
Identity 6 is the one that earns the opaque id. Keying a credential by its pair would fold the whole rotation history into one mutable record, and the chain a PCI auditor walks — *was this rotated inside ninety days* — would become a field that was overwritten rather than a sequence of records that each stand. Separate records with separate ids are what make Invariant 7.1 reconstructable.

Identity 11 is this atom's one departure from the corpus's usual *confirm nothing* posture, and the departure is deliberate. principal ref and revoked by ref stay opaque, but credential type is not a name the atom merely records — it selects the derivation function that produces the verifier, so a type naming no function has no way to produce one.

Identity 11 also narrows the near-duplicate a byte-exact key otherwise admits — `password` and `Password ` are two types here, and a principal holding one effective-active credential under each breaches nothing Invariant 2.1 can see. It does not *close* it, and an earlier draft of this WHY claimed it did: a deployment free to register both variants against one derivation function re-opens the hole through the registry, which Identity 11 then waves through. Capability requirement 6 is the half that closes it, and it is the deployment's because the registry is (council read 41).

### State

```
State 1: EVERY credential MUST carry credential id, principal ref, credential type, verifier, registered at and a status.
State 2: A credential MAY carry an expires at.
State 3: EVERY rotated credential MUST carry rotated at and successor credential id.
State 4: EVERY revoked credential MUST carry revoked at, revoked by ref and revocation reason.
State 5: An active credential MUST NOT carry a terminal field.
State 6: The atom MUST NOT store expired as a status.
State 7: A credential MUST NOT carry an expiry instant.
State 8: The atom MUST NOT expose a verifier.
State 9: A credential MUST NOT carry credential material.
State 10: A credential MUST NOT carry presented material.
State 11: The atom MUST NOT offer a reactivate surface.
State 12: The atom MUST NOT offer a window extension surface.
State 13: The atom MUST NOT offer a credential removal surface.
State 14: The atom MUST NOT offer a verifier migration surface.
State 15: The store instance's credential count MUST NOT fall.
```

WHY:
State 9 and State 10 bound the record; Operation 17 and Operation 25 bound the action, and the two are different claims. A store that holds no plaintext password still fails this atom's purpose if the material was written to a log on its way in, which is what *retain* forbids and *carry* does not reach. Neither leaves evidence in the store, which is why External check 1 exists at all — this is the atom's foundational security commitment and the one no conformance check can clear.

State 6 and State 7 are the derived-expiry posture on the record surface, two rules because an implementation can breach each without the other: a stored expired status, and an `expired_at` column beside a status that stays active.

State 14 names an absence a deployment eventually wants. When a deployment upgrades its derivation function, existing verifiers stay valid under the function they were made with; migrating them is a deployment operation, not an action here, because a migration would have to read material this atom has already discarded (Non-goal 18).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the id material at the seam.
Capability requirement 3: The deployment MUST supply the derivation registry at the seam.
Capability requirement 4: The deployment MUST declare a derivation function PER credential type the deployment serves.
Capability requirement 5: The deployment MUST declare a one-way derivation function.
Capability requirement 6: The deployment MUST NOT declare two credential types differing only by a foldable difference.
Capability requirement 7: The deployment MUST declare the default expires at.
Capability requirement 8: The store MUST run the effective-active check and the register write for one pair as one critical section.
Capability requirement 9: The store MUST release the critical section on the caller's return.
Capability requirement 10: The store MUST release the critical section on the caller's death.
Capability requirement 11: The store MUST acknowledge a write ONLY IF the write commits.
Capability requirement 12: The store MUST commit an admitted rotate's two writes together.
Capability requirement 13: The deployment MUST canonicalize an opaque reference.
Capability requirement 14: The deployment MUST declare the length bound.
Deleted: Capability requirement 15. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 16. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 27 owns it.
Deleted: Clock semantics 7. Non-goal 28 owns it.
```

WHY:
Capability requirement 8 is a correction, and the correction is worth stating because the prose it replaces named a mechanism that cannot work. A draft of this atom asked the store to enforce effective-active uniqueness with *a unique partial index on the pair where status is active and the credential is not past its deadline* — and no index predicate can reference now. The clock-free half of that index, `where status = active`, forbids exactly the case Operation 8 permits: a lapsed record standing in active beside its successor. So the index is either unimplementable or wrong, and the obligation it was reaching for is a critical section over the pair — the same shape [Provisional Commitment](./provisional-commitment.md)'s registry carries. The obligation is unchanged; only the mechanism illustration is gone, and it is recorded in the Ledger rather than quietly dropped.

Capability requirement 14 is the delegated cap. This atom declares no maximum length for a string input and obliges the deployment to declare one, which is one of the postures the *input-handling regime* docket row counts; the material is exempt only insofar as a derivation function states its own bounds.

WHY:
Non-goal 27 is the price of the derivation and it is cheaper here than it looks. Two readers with skewed clocks can disagree near a deadline about whether a credential reads expired — and no verified is answered for a lapsed credential under *either* reader's clock, no record diverges, and nothing is written. The disagreement is about a projection, not about state.

### Operations

```
register(principal_ref, credential_material, credential_type, optional expires_at)
  answers credential_id
  refuses invalid-request | duplicate-active-credential | storage-failure

verify(principal_ref, credential_type, presented_material)
  answers verified | failed-verification(verification failure)

rotate(credential_id, new_credential_material)
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
Operation 1: IF principal ref EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 2: IF credential material EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 3: IF credential type EQUALS blank THEN [Register] MUST answer invalid-request.
Operation 4: IF the credential type names no derivation function THEN [Register] MUST answer invalid-request.
Operation 5: IF now DOES NOT PRECEDE a supplied expires at THEN [Register] MUST answer invalid-request.
Operation 6: IF an effective-active credential EXISTS for the pair THEN [Register] MUST answer duplicate-active-credential.
Operation 7: [Register] MUST answer duplicate-active-credential ONLY IF EVERY well-formedness check passes.
Operation 8: A lapsed credential MUST NOT block a register for the credential's pair.
Operation 9: An admitted register MUST assign a fresh credential id.
Operation 10: An admitted register MUST record principal ref and credential type.
Operation 11: An admitted register MUST record the derived verifier.
Operation 12: An admitted register MUST record a supplied expires at.
Operation 13: IF expires at EQUALS blank THEN an admitted register MUST record the default expires at.
Operation 14: An admitted register MUST record now as registered at.
Operation 15: An admitted register MUST stand the credential in active.
Operation 16: An admitted register MUST answer the credential id.
Operation 17: [Register] MUST NOT retain credential material.
Operation 18: IF no effective-active credential EXISTS for the pair THEN [Verify] MUST answer no-active-credential.
Operation 19: [Verify] MUST NOT distinguish the reason no effective-active credential EXISTS for the pair.
Operation 20: [Verify] MUST NOT compare a verifier BEFORE the window reading.
Operation 21: A proceeding verify MUST derive the presented verifier PER the credential's derivation function.
Operation 22: IF the presented verifier differs from the recorded verifier THEN [Verify] MUST answer material-mismatch.
Operation 23: IF the presented verifier matches the recorded verifier THEN [Verify] MUST answer verified.
Operation 24: A proceeding verify MUST compare a verifier in constant time.
Operation 25: [Verify] MUST NOT retain presented material.
Operation 26: [Verify] MUST NOT record a field.
Operation 27: IF the credential id names no credential THEN a transitioning write MUST answer not-known.
Operation 28: IF no effective-active credential EXISTS for the credential id THEN [Rotate] MUST answer not-active.
Operation 29: IF no effective-active credential EXISTS for the credential id THEN [Revoke] MUST answer already-terminal.
Operation 30: A transitioning write MUST answer a standing rejection ONLY IF the credential id names a credential.
Operation 31: IF new credential material EQUALS blank THEN [Rotate] MUST answer invalid-request.
Operation 32: IF revoked by ref EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 33: IF reason EQUALS blank THEN [Revoke] MUST answer invalid-request.
Operation 34: A transitioning write MUST answer invalid-request ONLY IF EVERY standing check passes.
Operation 35: An admitted rotate MUST record a successor credential carrying the prior credential's pair.
Operation 36: An admitted rotate MUST stand the successor credential in active.
Operation 37: An admitted rotate MUST stand the prior credential in rotated.
Operation 38: An admitted rotate MUST record now as the prior credential's rotated at.
Operation 39: An admitted rotate MUST record the successor's credential id as the prior credential's successor credential id.
Operation 40: An admitted rotate MUST commit the successor credential and the prior credential's change in one transition.
Operation 41: An admitted rotate MUST answer the successor's credential id.
Operation 42: An admitted revoke MUST stand the credential in revoked.
Operation 43: An admitted revoke MUST record revoked by ref, reason as revocation reason and now as revoked at.
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
```

Term transitioning write: [Rotate] | [Revoke] — every call that would take an effective-active credential to a stored terminal, including a refused one.

Term stored terminal: rotated | revoked.

Term status: active | rotated | revoked — the value a credential stores.

Term standing check: Operation 27, Operation 28 and Operation 29 — every check a transitioning write makes on the credential's own standing before reading the call's inputs.

Term standing rejection: not-active | already-terminal.

Term well-formedness check: Operation 1, Operation 2, Operation 3, Operation 4 and Operation 5 — every check [Register] makes on the call's own inputs.

Term window reading: live | lapsed — how an active credential's window reads against now.

Term live: the window reading of an active credential whose expires at EQUALS blank, OR whose expires at exceeds now.

Term lapsed: the window reading of an active credential whose expires at DOES NOT EQUAL blank and does not exceed now; the boundary instant — expires at equal to now — reads lapsed.

Term effective-active credential: a credential whose status EQUALS active that reads live — what every bound, guard and lookup in this atom means by *the active credential*.

Term lapsed credential: a credential whose status EQUALS active that reads lapsed.

Term proceeding verify: a [Verify] call whose pair carries an effective-active credential.

Term effective status: expired where the credential reads lapsed, and the stored status otherwise — a projection over the credential and now, never stored.

Term verifier: the artifact a derivation function produces from credential material — what this atom stores in place of the material.

Term derivation function: the deployment's one-way function from material to a verifier, declared for one credential type.

Term derivation registry: the deployment's declared map from a credential type to a derivation function; supplied at the seam.

Term foldable difference: a difference between two strings that trimming, case-folding OR Unicode normalization would remove.

Term default expires at: the expires at the deployment declares for a [Register] carrying none; a deployment declaring no deadline leaves the credential's expires at absent.

Term terminal field: rotated at | successor credential id | revoked at | revoked by ref | revocation reason — every field a transitioning write records.

Term admitted register: a [Register] call that passes every precondition and whose store write commits.

Term admitted rotate: a [Rotate] call that passes every precondition and whose store writes commit.

Term admitted revoke: a [Revoke] call that passes every precondition and whose store write commits.

Term admitted read: a [Read] call that answers.

WHY:
Operation 7, Operation 30, Operation 34 and Operation 46 are the rejection priority, written as guards rather than as an order (GRACE-lang Timing 13). For a transitioning write the effect is not-known before the standing rejection before invalid-request before storage-failure; for [Register] it is invalid-request before duplicate-active-credential before storage-failure.

Operation 8 is the atom's load-bearing subtlety and the easiest rule to implement wrong. Every bound and guard here means *effective-active*, never the bare stored status, so a pair may hold a lapsed record standing in active beside a freshly registered successor without breaching Invariant 2.1. An implementation that reads the stored flag instead of the reading is the time-of-check hazard `credential-buggy-toctou.tla` reintroduces.

Operation 19 is a security posture rather than an economy. *No effective-active credential* covers three distinct facts — never registered, every record terminal, the only active record lapsed — and folding them is deliberate: distinguishing them at the verify surface lets a caller enumerate which principals hold which credential types, which is exactly the reconnaissance an unauthenticated surface must not offer. A composing administrative surface reads the store directly.

Operation 20 is a check-ordering rule and it carries the whole of Invariant 11.1. The window reading is evaluated before any verifier comparison, so verified cannot be answered in the interval between a deadline passing and any housekeeping — there is no housekeeping write to race.

Operation 24 names an obligation no record can evidence. A short-circuiting comparison leaks the stored verifier one byte at a time to a caller who can measure the answer, and nothing in the store shows whether the implementation did it; External check 2 is where an auditor goes instead.

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
  Invariant 2.1: Two effective-active credentials MUST NOT share a pair.
  ```
  WHY: the bound ranges over the reading, not the stored status, which is why a pair may carry a lapsed active record beside its successor (Operation 8) and still satisfy it. Two mechanisms keep it: [Rotate] commits both writes together (Operation 40), so the pair is never doubly effective-active mid-transition; and [Register]'s check and write run under one critical section (Capability requirement 8), so two concurrent registrations for one pair cannot both pass the check.
- **Invariant 3 — Sole-holder verification.**
  ```
  Invariant 3.1: [Verify] MUST answer verified ONLY IF the presented verifier matches an effective-active credential's verifier.
  ```
- **Invariant 4 — Revocation is absorbing.**
  ```
  Invariant 4.1: A revoked credential MUST NOT answer verified.
  ```
- **Invariant 5 — A stored terminal is absorbing.**
  ```
  Invariant 5.1: A credential whose status IS IN the stored terminals MUST NOT leave the stored terminal.
  ```
  WHY: a lapsed credential draws the same two rejections a stored terminal does — not-active from [Rotate], already-terminal from [Revoke] — and for a different reason, which is worth saying because the shared answers invite a reader to assume a shared mechanism. A stored terminal is excluded by what it stores; a lapsed credential is excluded by what the clock says, stands in active still, and is owned by Invariant 11.1 and Invariant 12.1 rather than here.
- **Invariant 6 — Rotation does not mutate.**
  ```
  Invariant 6.1: An admitted rotate MUST NOT change the prior credential's verifier.
  Invariant 6.2: An admitted rotate MUST NOT change a field of the prior credential beside status, rotated at and successor credential id.
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
  WHY: the one-way property is the deployment's to supply and not a property of any reachable state, so it sat in the wrong family — an `Invariant` is a property of every reachable state (GRACE-lang Standard label 1) and a deployment's obligation is a `Capability requirement`. Same fact, moved to the family that owns its kind (council read 41).
- **Invariant 9 — Revocation attribution is complete.**
  ```
  Invariant 9.1: EVERY revoked credential MUST carry a non-blank revoked by ref.
  Invariant 9.2: EVERY revoked credential MUST carry a non-blank revocation reason.
  Invariant 9.3: EVERY revoked credential MUST carry a revoked at.
  ```
- **Invariant 10 — Credential durability.**
  ```
  Invariant 10.1: The atom MUST NOT remove a credential from the store.
  Invariant 10.2: A storage-failure rejection MUST leave no partial credential in the store.
  ```
- **Invariant 11 — A lapse precludes verification.**
  ```
  Invariant 11.1: A lapsed credential MUST NOT answer verified.
  ```
  WHY: the expiry analogue of Invariant 4.1, and the difference is the whole of this atom's render-time form. Revocation excludes by a write; a lapse excludes by a reading, and the mechanism is Operation 20's check ordering rather than any stored flag. Because a pair holds at most one effective-active credential (Invariant 2.1), once that one lapses no verified is possible for the pair until a fresh register.
- **Invariant 12 — Expiry is derived, never written.**
  ```
  Invariant 12.1: The atom MUST NOT write a field when a credential lapses.
  Invariant 12.2: An admitted read MUST compute the effective status from the credential's expires at and now.
  ```

Term resolution instant: rotated at | revoked at.

WHY:
Invariant 2.1 and Invariant 3.1 together give the *authentication integrity* property — a principal's verify is answered by exactly the credential they registered, only them, and only while it is effective-active. Invariants 4, 5, 11 and 12 give *terminal finality*: the system cannot be raced into verifying against a revoked, rotated or lapsed credential, and expiry achieves it with no stored flag to revert. Invariants 6 and 7 give *rotation auditability* — how a principal's credential evolved is reconstructable without source code or runbooks.

---

## Examples

### Password authentication — registration and verification

`register(user_u91, "correct horse battery staple", "password")` → `cred_c01`, standing active with no deadline. The material is derived to a verifier and discarded; nothing in the store holds it. Later, `verify(user_u91, "password", "correct horse battery staple")` → verified. `verify(user_u91, "password", "hunter2")` → `failed-verification(material-mismatch)`.

### Public-key authentication — rotation

`register(svc_s03, <attestation>, "api-token", 2026-04-01)` → `cred_c07`. On a ninety-day policy the service rotates: `rotate(cred_c07, <new material>)` → `cred_c11`. Two writes commit together — `cred_c11` stands active, and `cred_c07` stands rotated carrying rotated at and `successor_credential_id: cred_c11`. An auditor walks `cred_c02 → cred_c07 → cred_c11` and reads the gap between each registration and its predecessor's rotation.

### The deadline passes

`cred_c11` carries `expires_at: 2026-07-01`. On 2026-07-02 nothing has happened to the record: it still stands active, carries no terminal field, and read returns it with an effective status of expired. verify against the pair answers no-active-credential; `rotate(cred_c11, …)` answers not-active; `revoke(cred_c11, …)` answers already-terminal — each by reading, each writing nothing. And because `cred_c11` no longer occupies the slot, `register(svc_s03, <material>, "api-token", …)` succeeds, leaving two records standing active for the pair, exactly one of them effective-active.

### Revocation after exposure

Tokens for `svc_s03` turn up in a log file. `revoke(cred_c11, admin_a01, "log-exposure-2026-09-12")` → revoked, stamping revoked at, revoked by ref and revocation reason. A later auditor reading only the store knows when, by whom and why, without asking anyone.

### Rejection paths

`register(user_u91, "x", "password")` on a pair that already holds an effective-active credential → duplicate-active-credential; the caller rotates instead. `register(user_u91, "x", "Password ")` → invalid-request, because no derivation function is registered for that type — which is also what stops a byte-exact key from quietly admitting a second effective-active credential under a near-duplicate name. `rotate(cred_unknown, "x")` → not-known. `revoke(cred_c07, admin_a01, "  ")` on the already-rotated record → already-terminal, not invalid-request: the standing check runs first (Operation 34).

### Regulated adversarial scenarios

- **Regulator audit.** *Was the service account's API credential rotated inside the ninety-day window?* Filter the store to the pair and order by registered at; each rotated record carries rotated at and a link forward. Invariant 7.1 and Invariant 7.2 are what make the chain complete rather than merely plausible — no rotation is omitted, and no link leaves the pair.
- **Disputed transaction.** *I did not log in from that address.* The composing [Login](../compositions/login.md) records name the credential used; this store shows that credential's standing and registration instant. Invariant 3.1 is the structural rebuttal: if verified was answered, the presented material derived to the recorded verifier. Whether the caller was the principal or someone holding their secret is a separate investigation, and this atom's records bound its window.
- **Breach investigation.** A batch of tokens may have been exposed. Filter to the pair, read each effective status against the investigation clock, and revoke what is still effective-active. Invariant 9.1 through 9.3 are what make the resulting record answer *when, by whom, why* from the store alone.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the credential store and a read-time clock alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find no two effective-active credentials sharing a pair, against a clock the auditor supplies (Invariant 2.1).
Check 1.2: An auditor MUST read effective-active from the window reading and NOT from the stored status (Operation 8, Invariant 2.1).
Check 2.1: An auditor MUST find no credential storing expired as a status (State 6).
Check 2.2: An auditor MUST find no credential carrying an expiry instant (State 7).
Check 2.3: An auditor MUST reproduce an admitted read's effective status from the credential's expires at and a clock the auditor supplies (Invariant 12.2).
Check 3.1: An auditor MUST find a successor credential id naming a credential on EVERY rotated credential (Invariant 7.1).
Check 3.2: An auditor MUST find EVERY rotated credential's successor carrying the rotated credential's pair (Invariant 7.2).
Check 3.3: An auditor MUST find a rotated at on EVERY rotated credential (State 3).
Check 4.1: An auditor MUST find a non-blank revoked by ref on EVERY revoked credential (Invariant 9.1).
Check 4.2: An auditor MUST find a non-blank revocation reason on EVERY revoked credential (Invariant 9.2).
Check 4.3: An auditor MUST find a revoked at on EVERY revoked credential (Invariant 9.3).
Check 5.1: An auditor MUST find no credential material in a credential (State 9).
Check 5.2: An auditor MUST find no presented material in a credential (State 10).
Check 5.3: An auditor MUST find no verifier in an admitted read's answer (Operation 53, State 8).
Check 6.1: An auditor MUST find no credential whose status IS NOT IN the stored terminals on a later read of a credential a prior read found in that stored terminal (Invariant 5.1).
Check 6.2: An auditor MUST find no terminal field on an active credential (State 5).
Check 7.1: An auditor MUST find a re-read credential's properties unchanged across an admitted rotate (Invariant 1.1, Invariant 6.1).
Check 7.2: An auditor MUST find a re-read credential's terminal fields unchanged across a later write (Invariant 1.2).
Check 8.1: An auditor MUST find no credential absent from a later read (Invariant 10.1).
Check 8.2: An auditor MUST find the store instance's credential count no lower on a later read (State 15).
Check 9.1: An auditor MUST reconstruct EVERY credential of one pair from the store (State 1, State 15, Invariant 10.1).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing credential material confirmed absent from a log MUST read the deployment's own logging (State 9, State 10).
External check 2: A deployment needing a verifier comparison confirmed constant-time MUST read the implementation (Operation 24).
External check 3: A deployment needing a derivation function confirmed one-way MUST read the derivation registry (Capability requirement 5).
External check 4: A deployment needing a verify answer observed MUST read the composing Event Log (Non-goal 25).
External check 5: A deployment needing a principal ref bound to a real party MUST read the composing Party Identity (Non-goal 1).
External check 6: A deployment needing a failed verify counted MUST read the composing Login (Non-goal 8).
External check 7: A deployment needing the store confirmed free of a retroactive edit MUST read the composing Tamper Evidence (Non-goal 21).
```

WHY:
External check 1 and External check 2 are this atom's two blindest spots and the only two whose breach is invisible in every conformance check above. A store that never held material still fails the atom's purpose if the deployment logged the material on its way in, and a verifier compared byte by byte with an early exit leaks itself to anyone who can time the answer. Neither leaves a record, so neither can be a Check; stating them as External checks is the difference between a gap and a disclosed boundary.

External check 4 is the lost-answer family. verified and failed-verification are answers and nothing else — [Verify] writes no field (Operation 26) — so the store cannot say how often a principal authenticated or failed to. That is deliberate (Non-goal 8) and it means the authentication history lives in whatever composes this atom, never here.

---

## Non-goals

```
Non-goal 1: The atom MUST NOT confirm that a principal ref names a proofed party.
Non-goal 2: A deployment needing identity proofing MUST compose Party Identity.
Non-goal 3: The atom MUST NOT sequence two credential checks.
Non-goal 4: A deployment needing multi-factor sequencing MUST compose Login.
Non-goal 5: The atom MUST NOT issue a session.
Non-goal 6: A deployment needing a persisted verification MUST compose Session.
Non-goal 7: The atom MUST NOT count a failed verify.
Non-goal 8: A deployment needing lockout MUST compose Login.
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
Non-goal 23: The atom MUST NOT decide whether a verifier is special-category data.
Non-goal 24: The atom MUST NOT record a transition history.
Non-goal 25: The atom MUST NOT record an answer the atom gave.
Non-goal 26: The atom MUST NOT guarantee that a credential reaches a stored terminal.
Non-goal 27: The atom MUST NOT bound two readers' effective status agreement.
Non-goal 28: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 15 and Non-goal 16 are the boundary NIST SP 800-63B is usually read as crossing. This atom satisfies 800-63B's *verifier storage and lifecycle* requirements and enforces none of its *authenticator strength* requirements — no minimum length, no breached-password screening, no entropy floor — because each of those is a property of the material rather than of the binding, and the derivation function is where a deployment discharges them.

Non-goal 19 is the compromise case and the reason the store is append-only in spirit as well as in rule. A credential later found to have been compromised before it was revoked does not cause any record here to change; a composing pattern writes *new* records that reframe the prior answers as untrustworthy. The store stays immutable and the meaning of its records changes by composition.

Non-goal 26 is the honest limit on the stored terminals. A credential nobody rotates or revokes stays standing in active forever, reading expired once its deadline passes — and if it carries no deadline it reads active forever. Nothing here makes that end.

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
Concurrency 2: A losing transitioning write MUST answer a standing rejection.
Concurrency 3: A losing [Register] racing on one pair MUST answer duplicate-active-credential.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: IF a string input EXCEEDS the length bound THEN an action MUST answer invalid-request.
```

Term string input: a reference, credential type OR reason — every caller-supplied string this atom accepts beside material.

Term length bound: the maximum length the deployment declares for a string input.


WHY:
Byte-exactness bites hardest on credential type, because that string is half the key Invariant 2.1 ranges over: under a folding comparison `password` and `Password ` would be one type, and under a byte-exact one they are two, so a principal could hold two effective-active credentials that no invariant catches. Identity 11 is what closes it — a type naming no derivation function is refused, so the near-duplicate never reaches the store. Material is exempt from the length bound only insofar as a derivation function declares its own (Capability requirement 14).

---

## Composition notes

```
Composition note 1: A composing Login MUST issue a session ONLY AFTER a verified answer.
Composition note 2: A composing Login MUST own the lockout policy.
Composition note 3: A composing Login MUST invalidate EVERY session derived from a revoked credential.
Composition note 4: A composing External Onboarding MUST call [Register] ONLY AFTER a party record EXISTS.
Composition note 5: A composing Event Log MUST append an event on EVERY admitted action.
Composition note 6: A composing Event Log MUST append an event on EVERY refused action.
Composition note 7: A composing Event Log MUST append an event on EVERY verify answer.
Composition note 8: A composing Actor Identity MUST attest the principal behind a verified answer.
Composition note 9: A composing Tamper Evidence MUST cover EVERY credential the store holds.
Composition note 10: A composing Tamper Evidence MUST NOT expose a verifier.
Composition note 11: A composing compromise disclosure pattern MUST record a new credential rather than change a credential.
```

WHY:
Composition note 3 is [Login](../compositions/login.md)'s cascade invariant seen from below, and this atom cannot state it as an invariant of its own: it neither issues nor sees sessions, so a revoked credential leaving a live session behind is a fact only the composition can be held to. The note states the obligation and the composition owns the guarantee — the same shape [Invitation](./invitation.md)'s *invitation gates enrollment* takes.

Composition note 7 is separate from Composition note 5 and Composition note 6 on purpose. A verify is neither admitted nor refused in this atom's vocabulary — both of its answers are first-class results of a query that wrote nothing — so a log wired only to admitted and refused actions would carry every registration and no authentication at all, which is the opposite of what an authentication audit wants.

Composition note 10 is the one an integrity pattern gets wrong by doing its job. A hash chain that covers the verifier is correct; one that *publishes* the covered value to make the chain checkable has exported the thing this atom exists to keep (State 8).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the deployment; the implementation; the store; the seam; the transition; a composing pattern; a caller; a principal; an auditor; a regulator; an investigator; a reader; a credential; an active credential; an effective-active credential; a lapsed credential; a rotated credential; a revoked credential; a successor credential; a prior credential; an action; a transitioning write; a losing transitioning write; a losing [Register]; a refused action; a refused rotate; a rejection; an answer; a derivation function; an opaque reference; a string input; a filter; the store instance's credential count.

Term records: credential — one principal's binding to one verifier for one credential type, carrying credential id, principal ref, credential type, verifier, registered at, a status and, where supplied or set, expires at, rotated at, successor credential id, revoked at, revoked by ref and revocation reason.

Term record verbs: identify, assign, generate, change, share, carry, stand, read, answer, record, leave, admit, offer, hold, commit, discard, repair, refuse, write, find, resolve, name, compare, normalize, confirm, match, differ, route, append, register, create, pass, attest, cover, call, fall, precede, sample, consume, supply, acknowledge, canonicalize, declare, compose, remove, bind, decide, define, bound, reach, accept, retain, trim, case-fold, compute, reproduce, reconstruct, verify, issue, detect, guarantee, take, derive, expose, store, own, persist, enumerate, distinguish, select, walk, mutate, serialize, rotate, revoke, block, invalidate, migrate, recover, reinterpret, constrain, count, sequence, release, run.

Term value sets: status = active | rotated | revoked. stored terminal = rotated | revoked. standing rejection = not-active | already-terminal. window reading = live | lapsed. property = principal ref | credential type | verifier | registered at | expires at. terminal field = rotated at | successor credential id | revoked at | revoked by ref | revocation reason.

Term bounds: default expires at, length bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: credential, credential id, pair, property, reference, store instance, seam, transition, now, transitioning write, stored terminal, status, standing check, standing rejection, well-formedness check, window reading, live, lapsed, effective-active credential, lapsed credential, proceeding verify, effective status, verifier, derivation function, derivation registry, foldable difference, length bound, default expires at, terminal field, resolution instant, admitted register, admitted rotate, admitted revoke, admitted read, string input, blank, verification failure.

Term cited: the section titled Logic Confinement Principle in `execution-contract.md` — the seam and the transition.

Term composing pattern: [Party Identity](./party-identity.md), [Session](./session.md), [Permissions](./permissions.md), [Actor Identity](./actor-identity.md), [Capability](./capability.md), [Event Log](./event-log.md), [Tamper Evidence](./tamper-evidence.md), [Login](../compositions/login.md), [External Onboarding](../compositions/external-onboarding.md), a compromise disclosure pattern.

Term credential types: credential_types — the credential kinds a deployment declares.

Term new credential material: new_credential_material — the material [Rotate] installs in place of the old.

#### Register

The behavior that records a new [Credential] — deriving the [Verifier] from [Credential Material] through the [Credential Type]'s derivation function, discarding the material, assigning a fresh [Credential Id], standing the record in [Active], and answering the id. Refused [Invalid Request], [Duplicate Active Credential] or [Storage Failure].

Kind: Operation

#### Verify

The read-only behavior that answers whether [Presented Material] derives to the [Verifier] of the pair's effective-active credential. Answers verified, or failed-verification naming [Material Mismatch] or [No Active Credential]. Writes nothing, counts nothing, and does not say *why* no effective-active credential exists.

Kind: Operation

#### Rotate

The transitioning write that replaces a credential — recording a successor in [Active] for the same pair, standing the prior credential in [Rotated], and stamping [Rotated At] and [Successor Credential Id] on it. Both writes commit together. Legal only against an effective-active credential; otherwise [Not Active].

Kind: Operation

#### Revoke

The transitioning write that cancels a credential, standing it in [Revoked] and recording [Revoked By Ref], [Revocation Reason] and [Revoked At]. Legal only against an effective-active credential; otherwise [Already Terminal].

Kind: Operation

#### Read

The read-only query answering the matching [Credential] records, each carrying its stored fields — never the [Verifier] — and its derived [Effective Status]. Refuses nothing.

Kind: Operation

#### Credential

The record this atom defines: one principal's binding to one verifier for one credential type. Carries [Credential Id], [Principal Ref], [Credential Type], [Verifier], [Registered At], [Status], an optional [Expires At], and the terminal fields of whichever write ended it.

Kind: Type
Projection: status

#### Credential Id

The opaque, immutable identity of a [Credential], assigned on [Register] from the id material the seam supplies. Never reused, and never the pair — two credentials for one pair are a rotation predecessor and its successor, each standing on its own.

Kind:       Field
Field of:   Credential
Projection: credential_id

#### Principal Ref

The opaque reference naming whose credential this is. Set on [Register], immutable. The atom does not confirm it names a known or proofed party — that is [Party Identity](./party-identity.md)'s.

Kind:       Field
Field of:   Credential
Projection: principal_ref

#### Credential Type

The label naming the kind of credential — `password`, `totp-secret`, `public-key`, `api-token`, `fido2`. Half of the pair the effective-active bound ranges over, and the selector for the derivation function; a type naming no registered function is refused.

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

#### Registered At

The instant the credential was recorded, stamped from [Now] on [Register]. Immutable.

Kind:       Field
Field of:   Credential
Projection: registered_at

#### Expires At

The optional instant the window closes, recorded on [Register] from the caller's value or the deployment's default. Immutable. Absent means no deadline, and a credential with no deadline reads live forever. The sole stored input the derived [Effective Status] needs.

Kind:       Field
Field of:   Credential
Projection: expires_at

#### Rotated At

The instant the replacement committed, stamped from [Now] on [Rotate]. Present only in [Rotated]; written once and never rewritten.

Kind:       Field
Field of:   Credential
Projection: rotated_at

#### Successor Credential Id

The [Credential Id] of the credential that replaced this one. Present only in [Rotated]; written once, because a re-link would silently rewrite the chain an auditor walks.

Kind:       Field
Field of:   Credential
Projection: successor_credential_id

#### Revoked At

The instant the revocation committed, stamped from [Now] on [Revoke]. Present only in [Revoked]; written once.

Kind:       Field
Field of:   Credential
Projection: revoked_at

#### Revoked By Ref

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

The raw secret the principal supplies to [Register]. Consumed to derive the [Verifier] and then discarded — never stored in a field, a log or a temporary record.

Kind:         Parameter
Parameter of: Register
Projection:   credential_material

#### Presented Material

The raw secret the principal supplies to [Verify]. Derived and compared against the stored [Verifier], then discarded. Never stored.

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
Parameter of: Register
Projection:   now

#### Active

The one non-terminal status. An active credential reads live or lapsed against [Now]; only a live one is effective-active, and only an effective-active one can be verified against, rotated or revoked.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Rotated

The stored terminal reached when a successor was registered. Carries [Rotated At] and [Successor Credential Id]. Absorbing.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Revoked

The stored terminal reached when the credential was deliberately cancelled. Carries [Revoked At], [Revoked By Ref] and [Revocation Reason]. Absorbing.

Kind:      Member
Member of: the credential status
Role:      Outcome

#### Expired

The derived status of an [Active] credential whose deadline has passed. Never stored, carried by no field, reached by no write — the value [Effective Status] computes from [Expires At] and [Now]. A credential reading [Expired] no longer occupies its pair's effective-active slot, which is why a fresh [Register] succeeds beside it.

Kind:      Member
Member of: the effective status
Role:      Outcome

#### Material Mismatch

The [Verify] answer when an effective-active credential exists for the pair and the presented material derives to a different verifier. A first-class result of a query, not a rejection.

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

The refusal returned when a required argument is blank, a [Credential Type] names no derivation function, a supplied [Expires At] does not exceed [Now], or a string input exceeds the deployment's length bound. On a transitioning write it is reached only after every standing check passes.

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

The refusal [Rotate] returns, after [Not Known] is ruled out, when the credential is not effective-active — either a stored terminal, or standing in [Active] and reading lapsed. Two mechanisms, one answer.

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
[Principal Ref]: #principal-ref
[Credential Type]: #credential-type
[Verifier]: #verifier
[Status]: #status
[Registered At]: #registered-at
[Expires At]: #expires-at
[Rotated At]: #rotated-at
[Successor Credential Id]: #successor-credential-id
[Revoked At]: #revoked-at
[Revoked By Ref]: #revoked-by-ref
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

- **NIST SP 800-63B (authentication and lifecycle management)** — the primary standard here. Authenticator assurance levels, verifier-storage requirements (stored verifiers, never raw secrets), and rotation and revocation requirements correspond directly to this atom's rules. The correspondence is to 800-63B's *verifier storage and lifecycle* half specifically; the *authenticator strength* half — minimum length, breached-password screening, entropy floors — is not enforceable here and lives in the derivation function (Non-goal 15, Non-goal 16). Identity proofing is 800-63A's and is deliberately not cited: that is [Party Identity](./party-identity.md)'s.
- **FIDO2 / WebAuthn (W3C Web Authentication Level 2)** — for phishing-resistant hardware authenticators. A `fido2` [Credential Type] takes the attestation object as [Credential Material]; the [Verifier] is the public key extracted from it, and [Verify] checks a presented assertion against it.
- **RFC 7519 (JSON Web Token)** — an `api-token` [Credential Type] stores a hash of the raw token as its [Verifier]. The atom does not interpret token claims; that is the composing pattern's.
- **OpenID Connect Core 1.0** — the OIDC login flow produces the verification event this atom models; [Login](../compositions/login.md) is the Grace Commons expression of the authorization-code flow.
- **PCI DSS Requirement 8 (identify and authenticate access)** — the atom satisfies the structural requirements: one effective-active credential per pair, rotation producing a new record, revocation recorded with attribution. The configuration knobs — rotation period, complexity rules, lockout threshold — are the deployment's (Non-goal 8, Non-goal 16).
- **ISO/IEC 27001 §A.9.4 (system and application access control)** — the registration, rotation and revocation lifecycle corresponds to the credential-management controls there.
- **GDPR Article 32 (security of processing)** — State 9, State 10 and the one-way verifier discipline contribute to the technical measures Article 32 requires. A deployment storing a biometric verifier assesses Article 9 separately (Non-goal 23).
- **HIPAA §164.312(d) (person or entity authentication)** — the verified answer is the structural mechanism for this requirement.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture, and the discipline of composing identity proofing, sessions, authorization and multi-factor orchestration as separate atoms rather than absorbing them here.
- **NIST 800-132 (password-based key derivation)** — the reference for which derivation functions satisfy the one-way property Invariant 8.2 requires.

---

## Status

`grounded on Final Critique 5 — 2026-06-23` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 5 — 2026-06-23
formal: verified — credential.tla + 2 twins, 2026-06-04
last gate: 2026-06-23 — Final Critique 5, fresh reader — clean

open:
- 2026-09-13-a · refining · Capability requirement 8 / formal · the prose named a store constraint that cannot be built — a unique partial index whose predicate would have to reference `now`, whose clock-free half forbids the lapsed-beside-successor case Operation 8 permits; the obligation is unchanged and is now a critical section over the pair, but `credential-buggy-toctou.tla` was built against the index reading → re-check the twin against the critical section reading
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/credential.md`.

- **2026-09-13 — Effective-active uniqueness is enforced by a critical section over the pair, not by a unique partial index.** *Chose:* Capability requirement 8 — the store runs the effective-active check and the register write for one pair as one critical section. *Over:* the store constraint the prose named, *a unique partial index on `(principal_ref, credential_type)` where `status = Active` and the credential is not past expires at*. *Because:* an index predicate cannot reference now, and the half of it that can — `where status = Active` — forbids exactly the case Operation 8 permits, a lapsed record standing in active beside its successor. The obligation the prose was reaching for is unchanged; only the mechanism is, and the formal twin built against the old reading is an open Ledger line rather than a silent inheritance.
- **2026-09-13 — Every bound, guard and lookup means effective-active, declared once.** *Chose:* window reading: live | lapsed, and effective-active credential as a credential standing in active that reads live. *Over:* restating *stored active and now < expires at* at the uniqueness guard, the verify lookup, the rotate precondition and the revoke precondition, which is how the prose carried it four times. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and this is the atom's single most misreadable claim — an implementation that reads the stored flag at any one of those four sites is the hazard `credential-buggy-toctou.tla` exists to catch.
- **2026-09-13 — live admits an absent deadline, which the corpus's other two window readings do not.** *Chose:* a two-member reading whose live member covers both *no deadline* and *deadline not yet reached*. *Over:* a three-member reading separating the unbounded case. *Because:* nothing in this atom treats an unbounded credential differently from one inside its window — every guard asks the same question and gets the same answer — so a third member would be a distinction no rule consumes. It is worth recording because [Provisional Commitment](./provisional-commitment.md) and [Invitation](./invitation.md) both declare a window reading over a *mandatory* deadline, and this is the first where the deadline is optional.

NOTE: End of Credential.

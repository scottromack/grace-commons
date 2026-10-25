---
title: Authenticated Actor
parent: Conceptual Compositions
nav_order: 21
has_toc: true
toc: true
---

# Authenticated Actor

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Authenticated Actor is a composition — a specification that wires two freestanding patterns together — that ties a principal's *login* to their *signature*. One pattern, Credential, checks that a presented secret belongs to a principal (the login). The other, Actor Identity, produces an attestation: a permanent, checkable record that a specific actor authorized a specific action (the signature). On their own, neither pattern knows about the other, which leaves three questions unanswered when the same person has both — and this composition answers all three.

First and most important: if you revoke someone's login, can they still produce new signatures? Here the answer is no. The composition checks, every time an actor goes to sign, that their login credential is still active, and the check and the recording of the signature are one indivisible step, so a revocation either comes first and the check refuses, or comes after the signature is recorded. The record of every signature names the credential the check saw. Crucially, signatures made *before* the revocation stay valid — they were properly authorized at the time, and erasing them would be wrong — so the cascade only closes the door going forward; it never rewrites the past.

Second: the login secret and the signing key are kept as two separate things; the composition never uses one as the other (a password hash is not a signing key). Third: the login identity and the signing identity are locked together as one principal, so any signature can always be traced back to the person who logged in.

The composition's defining emergent guarantee — a property that appears only when the two patterns are combined, belonging to neither alone — is that revocation cascade: a revoked login closes the signing surface. Its most common uses are regulated systems where the same person both logs in and signs actions of consequence: a clinician authenticating and then electronically signing a controlled-substance prescription, a bank officer logging in and attesting a wire approval, a developer authenticating and signing a release commit at a regulated software vendor. Any system where revoking someone's access must also stop them from producing new signed authorizations — and where an auditor must be able to trace each signature to the authenticated identity behind it — is a candidate for this composition.

---

## Intent

Two freestanding atoms answer two adjacent but distinct questions about a principal. **Credential** answers *"did the right material arrive — does this presented secret match what was registered for this principal?"* and produces a momentary `verified` signal. **Actor Identity** answers *"can a future verifier confirm this actor authorized this specific action?"* and produces a durable, non-repudiable attestation. Each is correctly specified without naming the other (Credential's specification names no other atom; Actor Identity's `verify` validates a proof against the actor registry's public material, not against any credential record). Yet the moment both exist for the *same* principal, three concepts arise that belong to neither atom alone — concepts that were surfaced not by a thought experiment but by a real implementation. The Attributed Permissions Admin demo conflated a single secret to serve as both the login credential and the attestation signing key (the section titled Cross-atom identity surface aliasing in `demos/attributed-permissions-admin/CORNERS.md`), and in doing so exposed three questions the library could not answer: does revoking a login revoke the ability to sign? must the two secret surfaces be distinct? and are the principal reference and actor reference namespaces bound to one principal or free to diverge? This composition is the structure that answers them.

The first and load-bearing concept is the **revocation cascade**, and it is the outbound-authority counterpart to Login's session cascade. Login makes a revoked credential's *sessions* die: revoking a credential and calling `revoke_sessions_for_credential` walks the derived-session set and terminates each. Authenticated Actor makes a revoked credential's *attestation surface* die: once the principal's authentication credential is revoked, the composition refuses to produce new attestations for the bound actor. The asymmetry between the two cascades is itself load-bearing. A session is mutable, live state with an active set to walk; the cascade is an enumeration-and-revoke. An attestation is an *immutable, point-in-time record* — there is no active-attestation set to retract, and retracting one would be wrong: a validly-authorized attestation made before revocation must remain valid (Actor Identity's non-repudiation contract is conditional on credential integrity *at attestation time*, not perpetually). The only coherent cascade for an immutable record surface is *forward closure*: the composition stops producing new attestations the instant the gating credential leaves `Active`. That forward closure is the emergent guarantee this composition owns.

The second concept is **secret-surface separation**. The authentication credential's stored form is a *verifier* — a one-way artifact (a salted password hash, an encoded public key) from which the original secret cannot be recovered (Credential Invariant 8) and which Credential never exposes in any output (Credential's Outputs and Feedback sections — the stored verifier is not an output field). An attestation key is a *signing* surface — material that produces a verifiable proof of authorship. A password hash is not a signing key; the surfaces are structurally different, and conflating them (as the demo did, for demo simplicity) is an architectural error, not a conforming shortcut. The composition forecloses the cross-routing half of this structurally — [Attest As Actor] takes a distinct attestation credential and never reads or re-purposes the Credential verifier (which is, by Credential Invariant 8, not even available to read) — and names the distinct-provisioning half as a deployment obligation, because no records check can prove that two opaque secrets are cryptographically distinct.

The third concept is **namespace binding**. Attestations are attributed to actor reference; sessions and credentials are keyed on principal reference. If the two namespaces are allowed to diverge, an audit record attributed to one identity surface cannot be reconciled to the session or credential record on the other — a forensic reconstruction problem. The composition binds the two namespaces bijectively: each authenticated actor is one `(principal_ref, actor_ref)` pair, recorded at registration and immutable thereafter, so an attestation's actor reference always resolves to exactly one authenticated principal reference and vice versa.

This is a composition, not a new primitive. Credential and Actor Identity are unchanged; Authenticated Actor is the wiring that makes them coherent for a single principal. It introduces emergent actions — [Register Authenticated Actor], [Attest As Actor], and the read-only [Verify Actor Attestation] — that belong to no single constituent and exist only because the two atoms are wired together. What it is *not*: it is not the credential-revocation surface (the identity-management surface calls `Credential.revoke`; this composition provides the downstream gate, exactly as Login provides the downstream session cascade without initiating the revocation); it is not the actor registry that provisions the attestation key's public material (an Actor Registry / Identity Provisioning concept Actor Identity already defers to); it is not an authorization surface deciding what the authenticated actor may *do* (Permissions); and it is not a session manager (Login). Each is named in Edge cases.

---

## Composes

- **[Credential](../atoms/credential.md)** — the authentication surface, and the constituent the gate reads.
- **[Actor Identity](../atoms/actor-identity.md)** — the attestation surface.

```
Composes 1: EXACTLY ONE Credential instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 5: The composition MUST NOT call Credential's verify at the gate.
Composes 6: The composition MUST NOT call Credential's rotate.
Composes 7: The composition MUST NOT call Credential's revoke.
Composes 8: The composition MUST NOT register an actor reference in the actor registry.
Composes 9: The composition MUST key the gate on the principal reference AND the credential type.
Composes 10: The composition MUST NOT key the gate on a credential id.
```

Term composition: this pattern's wiring of [Credential](../atoms/credential.md) and [Actor Identity](../atoms/actor-identity.md) — the namespace binding, the cascade gate and the three actions below.

Term constituents: [Credential](../atoms/credential.md), [Actor Identity](../atoms/actor-identity.md).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a principal binding map.
Composition state 2: The composition MUST store the strict inverse of the principal binding map.
Deleted: Composition state 3. Execution Contract Database 1 owns it.
Composition state 4: The composition MUST hold the principal binding map's key unique.
Composition state 5: The composition MUST hold the inverse map's key unique.
Composition state 6: The composition MUST NOT change a binding.
Composition state 7: The composition MUST store an attest log.
Composition state 8: The composition MUST append an attest log entry per [Attest As Actor] call.
Composition state 9: The composition MUST NOT change an attest log entry.
Composition state 10: EXACTLY ONE writer MUST write an attest log entry.
Composition state 11: The composition MUST NOT store a constituent's record.
```

Term principal binding: the composition's own map from a principal reference to the bound actor reference, the gating credential type, the initial credential id and the bound instant — a principal binding; one half of the bijection.

Term attest log: the composition's own append-only record of every [Attest As Actor] call, refused calls included — an attest log.

Term bijection: the principal binding and the inverse together, unique on both keys — what neither constituent provides.

**Contract classification: extraction-pending, two elements** (the section titled Composition state in [`execution-contract.md`](../execution-contract.md)). The extraction rule is unconditional — *composition state that carries truth not reconstructible from constituent records is a not-yet-extracted atom* — and it reaches both, because [Credential](../atoms/credential.md) keys on principal reference, [Actor Identity](../atoms/actor-identity.md) keys on actor reference, and neither relates the two.

- The **bijection** is one element, not two — two directions of one truth, with a uniqueness constraint per side. Proposed atom: a **Namespace Binding** — immutable, bijective, unique on both keys, no lifecycle beyond *bound*. Any pattern joining constituents that key on different opaque namespaces needs it.
- The **attest log** is the second, and its atom is named as a question because the corpus is split: [Login](./login.md) holds a sibling `login_event_log`, and [Notification Fanout](./notification-fanout.md) routes the identical concept *out* to [Event Log](../atoms/event-log.md). Three compositions, two answers. Proposed atom: an **Attempt Log** *if* the divergence from Event Log is real, and nothing at all if it is Event Log wired with a composition-supplied entry schema.

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the attest surface separation.
Capability requirement 2: A deployment MUST set the gating credential type default.
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 7. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 8. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it.
Capability requirement 10: The deployment MUST declare the clock offset allowance.
Deleted: Capability requirement 11. Execution Contract Database 1 and Execution Contract Database 2 own it: the composition names no completion bound or cadence for a deployment to leave unset.
Capability requirement 12: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term attest surface separation: the deployment's declaration that the attestation key material is provisioned distinct from the authentication credential material — an attest surface separation; the declaring source for Invariant 2's distinct-provisioning half.

Term clock offset allowance: clock offset allowance — the declared bound on disagreement between this composition's seam, Credential's and Actor Identity's — a clock offset allowance.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank principal reference.
Primitive policy 2: The composition MUST answer invalid-request for a blank actor reference.
Primitive policy 3: The composition MUST answer invalid-request for a blank credential material.
Primitive policy 4: The composition MUST answer invalid-request for a blank credential type the caller supplies.
Primitive policy 5: The composition MUST answer invalid-request for a blank action reference.
Primitive policy 6: The composition MUST answer invalid-request for a blank attest credential.
Primitive policy 7: The composition MUST answer invalid-request for an expiry instant the clock reading DOES NOT PRECEDE.
Primitive policy 8: The composition MUST compare an opaque input byte-exact.
Primitive policy 9: The composition MUST NOT normalize an opaque input.
Primitive policy 10: The composition MUST NOT case-fold an opaque input.
Primitive policy 11: The composition MUST NOT interpret an action reference.
Primitive policy 12: The composition MUST NOT confirm an actor reference in the actor registry.
```


Term opaque input: principal reference | actor reference | credential type | action reference | attestation id.

### Action wiring

```
register_authenticated_actor(principal_ref, actor_ref, credential_material, optional credential_type, optional expires_at)
  answers registration result
  refuses invalid-request | invalid-credential(existing) | namespace-conflict(conflict position) | storage-failure(storage position)

attest_as_actor(principal_ref, action_ref, attest_credential)
  answers attestation_id
  refuses invalid-request | not-bound | credential-not-active | invalid-attest-credential | attest-failed(attest position)

verify_actor_attestation(attestation_id)
  answers attestation verification result
```

Term registration result: credential id, actor reference and bound_at — what register_authenticated_actor answers.

Term attestation verification result: result, an optional actor reference and an optional principal reference — what verify_actor_attestation answers.

Term conflict position: guard — where a namespace conflict is found: at the guard.

Term storage position: credential | binding — the write that failed: the credential or the binding.

Term attest position: attestation | log — where an attest failed: at the attestation or at the log write.

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Action wiring 2: An admitted registration MUST answer namespace-conflict naming the guard for a principal reference the principal binding carries.
Action wiring 3: An admitted registration MUST answer namespace-conflict naming the guard for an actor reference the inverse map carries.
Action wiring 4: An admitted registration MUST call Credential's register ONLY AFTER the guard clears.
Action wiring 5: IF Credential's register answers duplicate-active-credential THEN an admitted registration MUST call Credential's verify with the supplied credential material.
Action wiring 6: IF Credential's verify answers failed-verification THEN an admitted registration MUST answer invalid-credential naming the existing credential.
Action wiring 7: IF Credential's verify answers verified THEN an admitted registration MUST bind the existing credential's credential id.
Action wiring 8: The composition MUST NOT answer duplicate-active-credential.
Action wiring 9: IF Credential's register answers a credential id THEN an admitted registration MUST write the binding ONLY AFTER Credential's register commits.
Deleted: Action wiring 10. Execution Contract Database 2 owns it.
Action wiring 11: IF the binding write fails THEN an admitted registration MUST answer storage-failure naming the binding.
Deleted: Action wiring 12. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 13. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Action wiring 14: An admitted attestation MUST resolve the actor reference from the principal binding.
Action wiring 15: IF the principal binding carries no principal reference THEN an admitted attestation MUST answer not-bound.
Deleted: Action wiring 16. Execution Contract Database 2 owns it.
Action wiring 17: An admitted attestation MUST read Credential's effective status for the principal reference AND the bound credential type.
Action wiring 18: IF no effective-active credential EXISTS THEN an admitted attestation MUST answer credential-not-active.
Action wiring 19: An admitted attestation MUST call Actor Identity's attest ONLY AFTER the gate read answers effective-active.
Action wiring 20: An admitted attestation MUST call Actor Identity's attest with the bound actor reference.
Action wiring 21: An admitted attestation MUST NOT call Actor Identity's attest with a caller-supplied actor reference.
Action wiring 22: An admitted attestation MUST call Actor Identity's attest with the caller's attest credential.
Action wiring 23: An admitted attestation MUST NOT call Actor Identity's attest with the credential material.
Action wiring 24: An admitted attestation passing the gate MUST append an attest log entry carrying the gate's credential id.
Action wiring 25: IF a success entry's append fails THEN an admitted attestation MUST answer attest-failed naming the log.
Action wiring 26: [Verify Actor Attestation] MUST call Actor Identity's verify with the attestation id.
Action wiring 27: [Verify Actor Attestation] MUST resolve a known attestation's actor reference through the inverse map.
Action wiring 28: [Verify Actor Attestation] MUST NOT write.
Action wiring 29: The composition MUST take a principal reference, an actor reference AND a credential material on register_authenticated_actor.
Action wiring 30: An admitted registration MUST pass the gating credential type default for an absent credential type.
Action wiring 31: IF Credential's register answers invalid-request THEN an admitted registration MUST answer invalid-request.
Action wiring 32: IF Credential's register answers storage-failure THEN an admitted registration MUST answer storage-failure naming the credential.
Deleted: Action wiring 33. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Action wiring 34: IF the gate read finds no effective-active credential THEN the attest log entry MUST carry the observed status AND the most recent credential record's credential id.
Action wiring 35: IF a refused call's append fails THEN the composition MUST answer attest-failed naming the log.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
```

Term admitted registration: a [Register Authenticated Actor] call whose inputs cleared the boundary predicate.

Term admitted attestation: an [Attest As Actor] call whose inputs cleared the boundary predicate.

Term effective-active: Credential's derived status projection reading active — stored active AND the credential's expiry instant not reached, evaluated by Credential against the clock reading at Credential's own seam.

### Wiring decision

```
Wiring decision 1: The composition MUST gate an attestation on the gating credential's effective-active status.
Deleted: Wiring decision 2. Execution Contract Database 2 owns it.
Deleted: Wiring decision 3. Execution Contract Database 2 owns it.
Wiring decision 4: The composition MUST NOT close an attestation Actor Identity already recorded.
Wiring decision 5: The composition MUST NOT ask Actor Identity to refuse a revoked principal's attestation.
```

### Housekeeping

```
Deleted: Housekeeping 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Housekeeping 2. Execution Contract Database 1 owns it.
Deleted: Housekeeping 3. Execution Contract Database 1 owns it.
Deleted: Housekeeping 4. Execution Contract Database 1 owns it.
Deleted: Housekeeping 5. Execution Contract Database 1 owns it.
Deleted: Housekeeping 6. Execution Contract Database 1 owns it.
Deleted: Housekeeping 7. Execution Contract Database 1 owns it.
```

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Revocation cascade, attest-surface closure.**
  ```
  Invariant 1.1: The composition MUST NOT produce an attestation for a principal reference carrying no effective-active gating credential at the gate read.
  Deleted: Invariant 1.2. Action wiring 19 and Execution Contract Database 2 own it.
  Invariant 1.3: A revoked gating credential MUST close the principal's attest surface for EVERY later call.
  ```
- **Invariant 2 — Secret-surface separation.**
  ```
  Invariant 2.1: The composition MUST NOT pass the credential material to Actor Identity's attest.
  Invariant 2.2: The composition MUST NOT pass Credential's verifier to Actor Identity's attest.
  Invariant 2.3: A deployment MUST provision the attest credential distinct from the credential material.
  ```
- **Invariant 3 — Namespace binding.**
  ```
  Invariant 3.1: EVERY bound principal reference MUST carry EXACTLY ONE actor reference.
  Invariant 3.2: EVERY bound actor reference MUST carry EXACTLY ONE principal reference.
  Invariant 3.3: The principal binding AND the inverse map MUST agree.
  ```
- **Invariant 4 — Attestation traceability.**
  ```
  Invariant 4.1: EVERY [Attest As Actor] call not answering attest-failed naming the log MUST append EXACTLY ONE attest log entry.
  Invariant 4.2: An [Attest As Actor] call answering attest-failed naming the log MUST NOT append an attest log entry.
  Invariant 4.3: EVERY success entry MUST carry the attestation id AND the gate's credential id.
  Deleted: Invariant 5. Composes 4 owns it.
  ```

---

## Examples

### Walkthrough — register, attest, then revoke-and-fail, end to end

A regulated software vendor authenticates developers and requires every release commit to be signed. It deploys Authenticated Actor with `gating_credential_type_default = "fido2"` and `attest_surface_separation = enforced`.

1. **Registration.** The identity-management surface registers developer `dev_smith`: `register_authenticated_actor(principal_ref = "dev_smith", actor_ref = "actor_smith", credential_material = <fido2-attestation-object>, credential_type = "fido2")`. The namespace-conflict guard passes (neither namespace is bound); `Credential.register` returns `credential_id = "cred_s01"`; `principal_to_actor["dev_smith"] = {actor_ref: "actor_smith", credential_type: "fido2", credential_id: "cred_s01", bound_at}` and `actor_to_principal["actor_smith"] = "dev_smith"` are written. Returns `{credential_id: "cred_s01", actor_ref: "actor_smith", bound_at}`.

2. **Attestation while Active.** The developer signs a release commit with their **separate hardware signing key**: `attest_as_actor(principal_ref = "dev_smith", action_ref = "commit_c44a", attest_credential = <hardware-signing-key>)`. Step 2 resolves `actor_smith`. Step 3 reads Credential's `read(filter)` surface: an effective-Active `fido2` credential, `cred_s01`, exists for `("dev_smith", "fido2")` → gate open. Step 4 calls `Actor Identity.attest("commit_c44a", "actor_smith", <hardware-signing-key>) → attestation_id = "att_a17"`. Step 5 logs `success` with `credential_id: "cred_s01"`. Returns `att_a17`. The continuous-integration system later calls `verify_actor_attestation("att_a17") → {result: verified, actor_ref: "actor_smith", principal_ref: "dev_smith"}` before merging — the signature verifies *and* resolves to the authenticated developer.

3. **Revocation closes the surface.** Security determines `cred_s01` was compromised. The identity-management surface calls `Credential.revoke("cred_s01", revoked_by_ref = "security_team", reason = "key-compromise")` — `cred_s01` is now `Revoked` (Credential Invariant 4). No call into Authenticated Actor is required to "cascade": the next attestation attempt is refused structurally. `attest_as_actor("dev_smith", "commit_c45b", <hardware-signing-key>)` → step 3 reads the credential records, finds **no effective-Active credential** for `("dev_smith", "fido2")` → appends `attest_log {outcome: credential-not-active(Revoked), credential_id: "cred_s01"}`; returns credential-not-active. The revoked login can no longer sign (Invariant 1). The earlier `att_a17` remains `verified` — it was validly authorized before revocation (Actor Identity Invariant 8).

### Domain example — rotation keeps the surface open

The same developer's hardware authenticator is replaced under the 12-month rotation policy. The identity-management surface calls `Credential.rotate("cred_s01", <new-fido2-object>) → "cred_s02"` (`cred_s01` → `Rotated`, `cred_s02` → `Active`, same `("dev_smith", "fido2")` pair — Credential Invariants 2 and 6). No rebinding is needed: `attest_as_actor("dev_smith", "commit_c46c", <hardware-signing-key>)` → step 3 finds an `Active` credential for the pair (the rotation successor) → gate open → attestation produced. The gate keys on the `(principal_ref, credential_type)` pair, not the fixed credential id, precisely so that a *rotation* (the actor is still legitimate) keeps the surface open while a *revocation* (the actor's authority is withdrawn) closes it. This is the load-bearing distinction between Credential Invariant 6 (rotation non-mutation, new `Active` successor) and Invariant 4 (revocation absorbing, no `Active` successor).

### Rejection path — namespace conflict and unbound attest

- **Namespace conflict.** A second registration reuses an already-bound actor: `register_authenticated_actor("dev_jones", "actor_smith", <material>, "fido2")` → step 2 finds `actor_smith` already in `actor_to_principal` → `namespace-conflict(guard)`; no credential is registered, no binding written. Had two registrations for `actor_smith` under two different principals run concurrently, the later would read the maps again once the earlier committed, find `actor_smith` bound and answer `namespace-conflict(guard)`, registering no credential. The bijection (Invariant 3) is preserved: `actor_smith` stays bound to exactly `dev_smith`.
- **Attest for an unbound principal.** `attest_as_actor("dev_unknown", "action_x", <key>)` for a principal never registered through the composition → step 2 finds no binding → `attest_log {outcome: not-bound}`; not-bound. This is distinct from credential-not-active: the principal was never an authenticated actor at all.
- **Invalid attestation credential.** `attest_as_actor("dev_smith", "commit_c47d", <wrong-signing-key>)` while the credential is `Active` → gate open, but `Actor Identity.attest` returns invalid-credential (the signing material does not validate against the registry's public material for `actor_smith`) → `attest_log {outcome: invalid-attest-credential}`; invalid-attest-credential. The gate (authentication still valid) and the attest check (signing key valid) are independent surfaces — secret-surface separation in action (Invariant 2).

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "prove this signed action was authorized by a principal whose login was valid at signing time, and trace the signature to that login."** An auditor examines attestation `att_a17`. `verify_actor_attestation("att_a17")` returns `{verified, actor_ref: "actor_smith", principal_ref: "dev_smith"}` — the proof verifies (Actor Identity Invariants 2 and 3) *and* resolves to the authenticated principal via the namespace binding (Invariant 3). The auditor reads the credential records for `("dev_smith", "fido2")` — `cred_s01`, the record the `success` entry's credential id names — and confirms it was effective-Active at `att_a17.attested_at`: its `revoked_at` lies later than that by more than clock offset allowance (Credential's clock and Actor Identity's are two seams, so the comparison narrows under the allowance rather than deciding on its own). The attest-log entry for `att_a17` corroborates the timeline (Invariant 4). Every claim is provable from the composition's records plus the two constituent records. The structural guarantee that a *revoked* login could not have produced a *new* signature after revocation is Invariant 1.

**Disputed signature — the principal claims they did not authorize an action.** `dev_smith` disputes `commit_c44a`. The investigator calls `verify_actor_attestation("att_a17")`: `verified` binds `actor_smith` to `commit_c44a` at `attested_at` (Actor Identity Invariant 8). The namespace binding resolves `actor_smith` to `dev_smith` (Invariant 3). The dispute cannot be sustained without claiming credential compromise — which is exactly the boundary Actor Identity Invariant 8 names (non-repudiation conditional on credential integrity), routed to a Compromise Disclosure composing pattern. The investigator additionally confirms, from the credential records and by the entry's credential id, that `cred_s01` was effective-Active at signing time within clock offset allowance, so the signature was produced through a valid login surface — Invariant 1's gate was satisfied at the time.

**Breach investigation — "during the compromise window, was any new signature produced after we revoked the credential?"** A security team revoked `cred_s01` at `T_revoke` and asks whether the attacker produced signatures afterward. They query the `attest_log` for `dev_smith` entries whose `attempted_at` is later than `T_revoke + clock_offset_allowance` (`T_revoke` is `cred_s01.revoked_at`, Credential's stamp; `attempted_at` is the composition's — two seams): every such entry shows `outcome: credential-not-active(Revoked)`, `credential_id: "cred_s01"`, and a null attestation id — the gate refused them (Invariant 1). A `success` entry in that region would be the smoking gun, and Invariant 1 forecloses it: every gate read after the revoke committed finds no effective-Active record. Entries inside the allowance window around `T_revoke` are the region the records cannot order across seams. A `success` entry naming `cred_s01` whose attestation's `attested_at` lies later than `T_revoke + clock_offset_allowance` is the conformance failure check 2 reads, since its gate read could not have preceded the revoke. Every attestation in the Actor Identity records for `actor_smith` therefore carries an `attested_at` at or before `T_revoke + clock_offset_allowance`; the forward-closure boundary is the revocation, and the `attest_log` makes every refused post-revocation attempt provable.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the credential records, the attestation records, the binding maps and the attest log.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY bound principal reference carrying one actor reference (Invariant 3.1).
Check 1.2: An auditor MUST find EVERY bound actor reference carrying one principal reference (Invariant 3.2).
Check 1.3: An auditor MUST find the principal binding AND the inverse map agreeing (Invariant 3.3).
Check 2.1: An auditor MUST find EVERY success entry carrying the credential id the gate read (Invariant 4.3).
Check 2.2: An auditor MUST read a success entry whose attestation instant follows the gate credential's revoked instant beyond the clock offset allowance as an Invariant 1.1 violation.
Deleted: Check 2.3. Execution Contract Database 2 owns it.
Check 3.1: An auditor MUST find EVERY [Attest As Actor] call carrying one attest log entry (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY credential-not-active entry carrying the observed status (Action wiring 34).
Deleted: Check 4.1. Execution Contract Database 1 owns it.
Check 5.1: An auditor MUST find no attest log entry changed (Composition state 9).
Deleted: Check 6.1. Execution Contract Database 1 owns it.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the two secret surfaces confirmed distinct MUST read the deployment's own provisioning (Invariant 2.3).
Deleted: External check 2. Execution Contract Database 2 owns it.
External check 3: An auditor needing an actor reference confirmed in the actor registry MUST read the actor registry (Composes 8).
External check 4: An auditor needing a verification read recorded MUST read a composed access log (Non-goal 12).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 4).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT confirm the two secret surfaces cryptographically distinct.
Non-goal 2: The composition MUST NOT confirm an actor reference provisioned in the actor registry.
Non-goal 3: The composition MUST NOT invalidate an attestation for a credential later found compromised.
Non-goal 4: The composition MUST NOT compose Audit Trail.
Non-goal 5: The composition MUST NOT revoke a credential.
Non-goal 6: The composition MUST NOT rotate a credential.
Non-goal 7: The composition MUST NOT close an attestation already recorded.
Non-goal 8: The composition MUST NOT register an actor reference.
Non-goal 9: The composition MUST NOT authorize an action.
Non-goal 10: A deployment needing an authorized action MUST compose Permissions.
Non-goal 11: The composition MUST NOT rebind a bound principal reference.
Non-goal 12: The composition MUST NOT record a verification read.
Non-goal 13: The composition MUST NOT resolve an attestation carrying an actor reference the inverse map does not carry.
Deleted: Non-goal 14. Execution Contract Database 1 owns it.
```

NOTE: the owners — the attestation records themselves, as the tamper-evident external-auditor surface (Non-goal 4).

---

## Edge cases

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so a revoke of the credential a gate read commits before the read or after the attestation.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue to bound.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
```

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Deleted: Composition note 2. Invariant 2.3 owns it.
Composition note 3: A deployment MUST own an actor reference's provisioning in the actor registry.
Composition note 4: A deployment MUST own a credential's revocation AND rotation.
Deleted: Composition note 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
Deleted: Composition note 6. Execution Contract Database 1 owns it: a registration's credential and binding commit together, so the composition reports no orphaned credential.
```

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projection** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the three emergent actions it exposes ([Register Authenticated Actor], [Attest As Actor], [Verify Actor Attestation]) — none belonging to a single constituent — the attest-log fields those actions record ([Outcome], [Observed Status]), and its own rejections ([Namespace Conflict], [Invalid Credential], [Not Bound], [Credential Not Active], [Invalid Attest Credential], [Attest Failed]). Its emergent state — the namespace-binding maps (`principal_to_actor`, `actor_to_principal`) and the `attest_log` — is a composition-introduced surface no constituent provides, left as backticked record tokens rather than carded. References to the constituent atoms and their operations — Credential's `register` / `rotate` / `revoke`, Actor Identity's `attest` / `verify` — the relayed tokens (principal reference, actor reference, action reference, credential material, attest credential, credential type, credential id, attestation id), the credential states (`Active` / `Revoked` / `Expired` / `Rotated`), and the inherited rejections (invalid-request, storage-failure — exported at this boundary with its position, `storage-failure(credential | binding)`; `duplicate-active-credential` is consumed by step 3's re-entry arm and not exported) remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: composition, constituents, principal binding, attest log, bijection, attest surface separation, clock offset allowance, blank, opaque input, admitted registration, admitted attestation, effective-active, conflict position, storage position, attest position, registration result, attestation verification result.

Term record verbs: call, answer, read, write, append, store, key, hold, take, resolve, bind, register, revoke, rotate, gate, precede, close, produce, provision, pass, agree, carry, change, refuse, set, declare, own, compose, inherit, confirm, interpret, normalize, case-fold, compare, authorize, invalidate, rebind, find, serve, supply, ask, record.

Term actors: the composition; the constituents; a deployment; an auditor; a caller; a principal; an actor; an invocation; an attestation; a credential.

Term cited: Execution Contract Conformance 8 — recursive conformance and the inherited guarantee. The section titled Composition state in `execution-contract.md` — the extraction-pending classification. The section titled Capability provenance in `pressure-testing.md` — the declared-source discipline.

Term attest credential: attest_credential — the signing material the caller presents for Actor Identity's attest; never the credential material.

#### Register Authenticated Actor

The composition's intake action: it binds an actor reference to a principal reference (behind the namespace-conflict guard) and registers the principal's authentication credential through `Credential.register` — two ordered writes, credential then binding, the strict-inverse binding maps written as the second. Returns `{credential_id, actor_ref, bound_at}`, or [Namespace Conflict], [Invalid Credential], or an inherited Credential rejection (invalid-request, `storage-failure(credential | binding)`); Credential's `duplicate-active-credential` is the re-entry arm that binds an existing effective-Active credential once `Credential.verify` proves the presenter holds it.

Kind: Operation

#### Attest As Actor

The composition's load-bearing emergent action: it produces a non-repudiable attestation for the bound actor **only if** the principal's gating credential is currently `Active` — the revocation cascade, enforced as a forward gate read immediately before the attestation write (Invariant 1). Returns the attestation id, or [Not Bound] (principal never bound), [Credential Not Active] (the gate is closed), [Invalid Attest Credential] (signing key invalid), or [Attest Failed] — positioned attestation or log (nothing committed). Every call appends exactly one [Outcome] to the `attest_log`, except the log landings.

Kind: Operation

#### Verify Actor Attestation

The composition's read-only query: a pass-through to `Actor Identity.verify` that additionally resolves the verified attestation's actor reference back to its bound principal reference. Returns an attestation verification result; changes no state.

Kind: Operation

#### Namespace Conflict

The composition's own rejection from [Register Authenticated Actor] — returned when the principal reference or the actor reference is already bound, enforcing the principal ⇔ actor bijection at the boundary (Invariant 3). Positioned: guard (step 2 — nothing is written).

Kind:       Member
Member of:  the register rejection
Role:       Rejection
Projection: namespace-conflict

#### Invalid Credential

The composition's own rejection from [Register Authenticated Actor]'s re-entry arm — returned when the pair already holds an effective-Active credential and `Credential.verify` does not return `verified` for the presented credential material: the presenter has not proved possession of the existing credential, so nothing is adopted and nothing is written. Carries existing to say which credential the verification ran against.

Kind:       Member
Member of:  the register rejection
Role:       Rejection
Projection: invalid-credential

#### Not Bound

The composition's own rejection from [Attest As Actor] — returned when the principal reference was never bound through the composition. Structurally distinct from [Credential Not Active]: *never an authenticated actor*, versus *bound but no longer authenticated*.

Kind:       Member
Member of:  the attest rejection
Role:       Rejection
Projection: not-bound

#### Credential Not Active

The composition's load-bearing rejection from [Attest As Actor] — the revocation cascade's observable form: returned when no `Active` credential exists for the bound `(principal_ref, credential_type)` pair (revoked, expired, or rotated without a current successor). Carries the [Observed Status] of the most-recent credential record.

Kind:       Member
Member of:  the attest rejection
Role:       Rejection
Projection: credential-not-active

#### Invalid Attest Credential

The composition's own rejection from [Attest As Actor] — the mapping of `Actor Identity.attest`'s invalid-credential: the presented signing material did not validate against the actor registry's public material for the bound actor reference. Independent of the authentication gate (secret-surface separation, Invariant 2).

Kind:       Member
Member of:  the attest rejection
Role:       Rejection
Projection: invalid-attest-credential

#### Attest Failed

The composition's own rejection from [Attest As Actor], positioned. attestation: the mapping of `Actor Identity.attest`'s storage-failure — nothing was recorded, the whole action may be retried. log: the `attest_log` append failed — nothing was recorded.

Kind:       Member
Member of:  the attest rejection
Role:       Rejection
Projection: attest-failed

#### Outcome

The attest-log entry's classification of an [Attest As Actor] call: `success`, or one of the named rejection reasons ([Not Bound], [Credential Not Active], [Invalid Attest Credential], [Attest Failed] at its attestation position only, invalid-request). Every call appends exactly one entry except the log landings of [Attest Failed] (Invariant 4); the log is the composition's provable audit surface.

Kind:       Field
Field of:   the attest-log entry
Role:       the attempt classification
Projection: outcome

#### Observed Status

The credential status the attest gate observed when it refused a call — the most-recent credential record's status for the `(principal_ref, credential_type)` pair (`Revoked` | `Expired` | `Rotated`), the absence of any `Active` credential being what closed the gate. Carried inside the [Credential Not Active] outcome for post-hoc forensics.

Kind:       Field
Field of:   the attest-log entry
Role:       the gate-closing credential status
Projection: observed_status

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a term marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Register Authenticated Actor]: #register-authenticated-actor
[Attest As Actor]: #attest-as-actor
[Verify Actor Attestation]: #verify-actor-attestation
[Namespace Conflict]: #namespace-conflict
[Invalid Credential]: #invalid-credential
[Not Bound]: #not-bound
[Credential Not Active]: #credential-not-active
[Invalid Attest Credential]: #invalid-attest-credential
[Attest Failed]: #attest-failed
[Outcome]: #outcome
[Observed Status]: #observed-status

---

## Standards references

Authenticated Actor is the structural form of the requirement that authentication and non-repudiable attestation be bound under one principal, with revocation of the former closing the latter. Its primary anchors:

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B section 5.2 (Authenticator Lifecycle — Binding, Revocation, and Reauthentication)** — the requirement that a revoked authenticator can no longer be used to establish authority. The revocation cascade (Invariant 1) is the structural form: a revoked authentication credential closes the actor's attestation surface, so authority to sign flows from a currently-valid authenticator.
- **NIST SP 800-57 Part 1 (Recommendation for Key Management — General)** — key-usage separation: a key used for one purpose (authentication) should not serve another (signing/attestation). Secret-surface separation (Invariant 2) is the composition-level expression of the key-separation principle.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.6 (management of authentication factors and their binding to individual accounts)** — authentication factors must be bound to a specific identity and managed through their lifecycle; the namespace binding (Invariant 3) and the revocation cascade (Invariant 1) are the structural mechanisms for the bind-and-revoke lifecycle of a payment-system actor.
- **FIPS 140-3 (Federal Information Processing Standard — Security Requirements for Cryptographic Modules)** — the standard for the cryptographic modules that hold and operate signing keys; the distinct-key-surface obligation (Invariant 2, externally-clearable) is where a deployment's FIPS 140-3-validated module provisioning is the cleared evidence that the attestation key is genuinely separate material.

Authenticated Actor inherits the broader standards compliance of its constituents:

- Through **Credential**: NIST SP 800-63B (authenticator and verifier requirements — stored verifiers, not raw secrets), FIDO2 / WebAuthn (phishing-resistant authenticator binding), PCI DSS Requirement 8, ISO/IEC 27001 clause A.9.4 (system and application access control), GDPR (EU General Data Protection Regulation) Article 32 (security of processing — the verifier-not-material discipline). The revocation-absorbing and terminal-absorbing invariants the cascade rests on are Credential's.
- Through **Actor Identity**: NIST SP 800-63-3 (identity and authenticator assurance), eIDAS Regulation (EU 910/2014 — qualified electronic signatures), FIPS 186-5 (Digital Signature Standard), 21 CFR (US Code of Federal Regulations) Part 11 (FDA electronic records and signatures — uniquely attributable, repudiation-resistant signatures), DEA EPCS (US Drug Enforcement Administration — Electronic Prescriptions for Controlled Substances; 21 CFR section 1311 — two-factor cryptographic attestation for controlled-substance prescriptions), HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(d) (person or entity authentication), SOX (Sarbanes-Oxley Act) section 302/section 404 (officer certifications and internal-control evidence). The non-repudiation contract the cascade preserves forward is Actor Identity's.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the model treats check-and-attest as one atomic step and cannot exhibit an externally-issued revoke as a second process over the per-principal section (the declared residue), the section's lease terminus, the step-5 log arm after a committed attestation, or the two-principal race the maps' uniqueness constraint decides at step 4; was verified — authenticated-actor.tla + 1 twin, 2026-06-10
last gate: 2026-06-10 — Final Critique 4, fresh reader — clean

open:
- 2026-08-30-a · refining · formal · the model has no possession-verified re-entry arm → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/authenticated-actor.md`; the migration, the council read's collapse, the family placement and the regeneration that got it here are in [its history](./authenticated-actor.hist.md).

- **2026-08-30 — The gate runs under the composition's own critical section and names its residue; the orphan re-enters instead of dying; every exported code carries its position.** *Chose:* `principal_section` declared as an instance capability requirement with lease semantics, under which the status read and the attestation write run, with an externally-issued `Credential.revoke` stated as **not** serialized and the one-attestation residue it can produce declared, bounded by `attest_completion_bound`, and made findable by a credential id on every `attest_log` entry; a composition-introduced storage-level uniqueness constraint on both binding maps re-checked at step 4; a re-entry arm on `duplicate-active-credential` that binds the existing effective-Active credential only after `Credential.verify` proves the presenter holds it (`invalid-credential(existing)` otherwise), so a re-invocation after a binding-position failure reaches the step that failed without becoming a way to claim another principal's credential; `orphan-credential(credential_id)` for the post-commit guard re-run; the lease measured from the critical section take as one interval with each completion bound; check 2 sizing the residue on the attestation's `attested_at` against `revoked_at` within `clock_offset_allowance + attest_completion_bound`; a report-only orphaned-credential leg on `reconciliation_cadence` and at restart, filtered by unbound credential id and gating pair, bounded below by `registration_completion_bound`, declared horizon-less, promising no closure window, and carried as check 6; `storage-failure(credential | binding)`, `namespace-conflict(guard | binding)`, and `attest-failed(attestation | log(attestation_id))` on the signatures; clock offset allowance on every cross-seam comparison, with check 2 reporting candidates inside the window. *Over:* a "record lock `Credential.revoke` must acquire" attributed to Credential Invariant 2, which declares a uniqueness constraint and no lock; a re-entry arm that adopted an existing credential on the presenter's say-so; a namespace guard offered as a serialization; an orphan "surfaced as a finding" by no leg and repaired by no action; a bare token on both sides of the credential commit and no arm at all after the attestation commit; a breach example that ordered two seams' stamps as if they were one clock. *Because:* an invariant is only as sound as the capability it rests on, and a lock nobody declared is ambient authority; a re-invocation that dies at `duplicate-active-credential` cannot repair the failure it was retried for; a caller who cannot tell credential from binding registers twice; a binding nobody proved possession for is an authority-bearing transition resting on an unauthenticated principal; and a stamp from another seam narrows a decision, never makes one (the frozen rules of 2026-08-30 — *Capability provenance*, *A composition's own rejection arm carries the retry bit*, *A stamp from another seam never decides a write alone*, *A compensator is exclusive* — with *A reconciliation is bounded at both ends* and *Recovery commits under a declared service identity*, frozen 2026-08-29, and the section titled *Authentication precedence* in `pressure-testing.md`, frozen 2026-08-27).

- **2026-10-20 — The store's guarantees cited, not restated, the per-principal critical section and its declared residue among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the forty rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which a registration's credential and binding commit together and an attestation commits with its attest log entry: the maps' one transaction and the bar on wrapping the credential write and the binding write in one (Composition state 3, Non-goal 14), the report-only orphaned-credential leg with its cadence, its check and the note obliging a deployment to act on its report (Housekeeping 1 through 7, the first with Store 3; Capability requirement 9, Check 6.1, Composition note 6), and the check finding every attestation older than the attest completion bound carrying its entry (Check 4.1); to Store 1 and Store 2, the two completion bounds and the refusal to start without them (Capability requirement 7, 8, 11); and to Store 2, under which an action's guard reads and the writes they decide are one transaction: the host's critical section keyed by principal reference, with its supply, release, lease and holding rules and its external check (Capability requirement 3 through 6, Action wiring 1, 16, Wiring decision 2, 3, Concurrency 1, External check 2), the binding write's uniqueness refusal and the lapsed section's re-take with its re-run guard's landings (Action wiring 10, 12, 13, 33, 36, 37), the gate read preceding the attestation write inside the held section (Invariant 1.2, with Action wiring 19), and the declared revoke residue with its bound, its check, the routes a deployment had to close it and the gate read after a revoke (Concurrency 2 through 6, Check 2.3, Composition note 5); with them [Register Authenticated Actor]'s signature loses orphan-credential and the conflict position its binding value, a failed success entry answers attest-failed naming the log without a committed attestation's id (Action wiring 25), and Check 2.2 reads a violation beyond the clock offset allowance alone; rules 146 to 107. *Over:* a host-supplied critical section with lease semantics under which the gate read and the attestation write ran, a declared one-attestation residue for a revoke landing inside it, and a credential committed apart from its binding, with positioned arms and a report-only leg for the orphan — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Credential's records, the binding maps, Actor Identity's attestations and the attest log are one store, so a registration's credential and binding commit together or not at all, and an attestation commits with its entry. Store 2 reads the state an action's guards decide on inside the transaction that writes the action's effects, so the gate's read of the gating credential is in the attesting transaction and a revoke of that credential commits before the read or after the attestation, as the maintainer ruled 2026-10-20 for a guard decided across a lease check whose grant lives in the one store; the composition still never calls Credential's revoke (Composes 7). The other calls a rule decided: the rewrite's rule that machinery existing only because a store could lose, split, edit or forget a write goes takes the orphaned-credential leg, which the page gave the split's orphan alone (Non-goal 14), though its pair filter would also have reported a credential registered for the pair outside the composition, the kind Action wiring 5 through 7 adopt; the same rule keeps Action wiring 11, a storage failure's only landing and no machinery, now with nothing committed; Action wiring 9 stays as the only rule obliging the binding write, the register's commit being its nested Step 3 inside the registration's one transaction (pipelines nest whole: the section titled Substrate composition invocation in `execution-contract.md`); and Check 5.1 rests on the auditor's own reads rather than on an entry's earlier versions, so Store 5 is not cited. What the composition does for its domain is otherwise unchanged.

NOTE: End of Authenticated Actor.

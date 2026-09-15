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

First and most important: if you revoke someone's login, can they still produce new signatures? Here the answer is no. The composition checks, every time an actor goes to sign, that their login credential is still active, and it makes that check immediately before it records the signature, inside a per-principal critical section the deployment supplies, so no two signing attempts can race each other past the check. A revocation issued elsewhere in the instant between the check and the signature is the one residue the composition declares rather than hides: the record of every signature names the credential the check saw, so an auditor can find any signature that landed inside that instant. Crucially, signatures made *before* the revocation stay valid — they were properly authorized at the time, and erasing them would be wrong — so the cascade only closes the door going forward; it never rewrites the past.

Second: the login secret and the signing key are kept as two separate things; the composition never uses one as the other (a password hash is not a signing key). Third: the login identity and the signing identity are locked together as one principal, so any signature can always be traced back to the person who logged in.

The composition's defining emergent guarantee — a property that appears only when the two patterns are combined, belonging to neither alone — is that revocation cascade: a revoked login closes the signing surface. Its most common uses are regulated systems where the same person both logs in and signs actions of consequence: a clinician authenticating and then electronically signing a controlled-substance prescription, a bank officer logging in and attesting a wire approval, a developer authenticating and signing a release commit at a regulated software vendor. Any system where revoking someone's access must also stop them from producing new signed authorizations — and where an auditor must be able to trace each signature to the authenticated identity behind it — is a candidate for this composition.

---

## Intent

Two freestanding atoms answer two adjacent but distinct questions about a principal. **Credential** answers *"did the right material arrive — does this presented secret match what was registered for this principal?"* and produces a momentary `verified` signal. **Actor Identity** answers *"can a future verifier confirm this actor authorized this specific action?"* and produces a durable, non-repudiable attestation. Each is correctly specified without naming the other (Credential's specification names no other atom; Actor Identity's `verify` validates a proof against the actor registry's public material, not against any credential record). Yet the moment both exist for the *same* principal, three concepts arise that belong to neither atom alone — concepts that were surfaced not by a thought experiment but by a real implementation. The Attributed Permissions Admin demo conflated a single secret to serve as both the login credential and the attestation signing key (`demos/attributed-permissions-admin/CORNERS.md` §Cross-atom identity surface aliasing), and in doing so exposed three questions the library could not answer: does revoking a login revoke the ability to sign? must the two secret surfaces be distinct? and are the `principal_ref` and `actor_ref` namespaces bound to one principal or free to diverge? This composition is the structure that answers them.

The first and load-bearing concept is the **revocation cascade**, and it is the outbound-authority counterpart to Login's session cascade. Login makes a revoked credential's *sessions* die: revoking a credential and calling `revoke_sessions_for_credential` walks the derived-session set and terminates each. Authenticated Actor makes a revoked credential's *attestation surface* die: once the principal's authentication credential is revoked, the composition refuses to produce new attestations for the bound actor. The asymmetry between the two cascades is itself load-bearing. A session is mutable, live state with an active set to walk; the cascade is an enumeration-and-revoke. An attestation is an *immutable, point-in-time record* — there is no active-attestation set to retract, and retracting one would be wrong: a validly-authorized attestation made before revocation must remain valid (Actor Identity's non-repudiation contract is conditional on credential integrity *at attestation time*, not perpetually). The only coherent cascade for an immutable record surface is *forward closure*: the composition stops producing new attestations the instant the gating credential leaves `Active`. That forward closure is the emergent guarantee this composition owns.

The second concept is **secret-surface separation**. The authentication credential's stored form is a *verifier* — a one-way artifact (a salted password hash, an encoded public key) from which the original secret cannot be recovered (Credential Invariant 8) and which Credential never exposes in any output (Credential's Outputs and Feedback sections — the stored verifier is not an output field). An attestation key is a *signing* surface — material that produces a verifiable proof of authorship. A password hash is not a signing key; the surfaces are structurally different, and conflating them (as the demo did, for demo simplicity) is an architectural error, not a conforming shortcut. The composition forecloses the cross-routing half of this structurally — [Attest As Actor] takes a distinct attestation credential and never reads or re-purposes the Credential verifier (which is, by Credential Invariant 8, not even available to read) — and names the distinct-provisioning half as a deployment obligation, because no records check can prove that two opaque secrets are cryptographically distinct.

The third concept is **namespace binding**. Attestations are attributed to `actor_ref`; sessions and credentials are keyed on `principal_ref`. If the two namespaces are allowed to diverge, an audit record attributed to one identity surface cannot be reconciled to the session or credential record on the other — a forensic reconstruction problem. The composition binds the two namespaces bijectively: each authenticated actor is one `(principal_ref, actor_ref)` pair, recorded at registration and immutable thereafter, so an attestation's `actor_ref` always resolves to exactly one authenticated `principal_ref` and vice versa.

This is a composition, not a new primitive. Credential and Actor Identity are unchanged; Authenticated Actor is the wiring that makes them coherent for a single principal. It introduces emergent actions — [Register Authenticated Actor], [Attest As Actor], and the read-only [Verify Actor Attestation] — that belong to no single constituent and exist only because the two atoms are wired together. What it is *not*: it is not the credential-revocation surface (the identity-management surface calls `Credential.revoke`; this composition provides the downstream gate, exactly as Login provides the downstream session cascade without initiating the revocation); it is not the actor registry that provisions the attestation key's public material (an Actor Registry / Identity Provisioning concept Actor Identity already defers to); it is not an authorization surface deciding what the authenticated actor may *do* (Permissions); and it is not a session manager (Login). Each is named in Edge cases.

---

## Composes

```text
Composes 1: EXACTLY ONE Credential instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 4: The composition MUST inherit a constituent's invariants PER `execution-contract.md` §Conformance.
Composes 5: The composition MUST NOT call Credential's verify at the gate.
Composes 6: The composition MUST NOT call Credential's rotate.
Composes 7: The composition MUST NOT call Credential's revoke.
Composes 8: The composition MUST NOT register an actor_ref in the actor registry.
Composes 9: The composition MUST key the gate on the principal_ref AND the credential_type.
Composes 10: The composition MUST NOT key the gate on a credential_id.
```

Term composition: this pattern's wiring of credential(../atoms/credential.md) and actor identity(../atoms/actor-identity.md) — the namespace binding, the cascade gate and the three actions below.

Term constituents: credential(../atoms/credential.md), actor identity(../atoms/actor-identity.md).

WHY:
Composes 5 is the decision that makes the gate affordable. Calling `Credential.verify` at every attestation would require re-presenting the login secret on every signature; the gate instead reads Credential's declared `read` surface for the pair's effective-status projection, exactly as login(./login.md)'s own step 3 reads the store directly.

Composes 9 and Composes 10 are why a rotation keeps the surface open and a revocation closes it. Keying on the pair means a rotation's successor credential answers the gate (Credential Invariant 6); keying on a fixed `credential_id` would have closed the surface on every rotation, which is the identity-management surface's business and not this composition's.

Composes 4 is council read 53's ruling at its fourth seam, and the cheapest of the four: the deleted `Invariant 5 — Constituent invariants preserved` covered **both** constituents in one rule where the other three compositions spent one per atom, so one tombstone closes it. What survives the collapse is Composes 5 through 10 — the refusals and the gate's key — none of which either atom guarantees about a caller.

The document had also half-found the shape on its own. Every emergent invariant carries a `Rests on:` clause naming the constituent guarantees it leans on, which is provenance done properly at the invariant level; the blanket was the one place that discipline lapsed into a restatement.

---

## Composition logic

### Composition state

```text
Composition state 1: The composition MUST store a principal binding map.
Composition state 2: The composition MUST store the strict inverse of the principal binding map.
Composition state 3: The composition MUST write the principal binding map AND the inverse under one transaction.
Composition state 4: The composition MUST hold the principal binding map's key unique.
Composition state 5: The composition MUST hold the inverse map's key unique.
Composition state 6: The composition MUST NOT change a binding.
Composition state 7: The composition MUST store an attest log.
Composition state 8: The composition MUST append an attest log entry per [Attest As Actor] call.
Composition state 9: The composition MUST NOT change an attest log entry.
Composition state 10: EXACTLY ONE writer MUST write an attest log entry.
Composition state 11: The composition MUST NOT store a constituent's record.
```

Term principal binding: the composition's own map from a `principal_ref` to the bound `actor_ref`, the gating `credential_type`, the initial `credential_id` and the bound instant — a principal binding; one half of the bijection.

Term attest log: the composition's own append-only record of every [Attest As Actor] call, refused calls included — an attest log.

Term bijection: the principal binding and the inverse together, unique on both keys — what neither constituent provides.

**Contract classification: extraction-pending, two elements** ([`execution-contract.md`](../execution-contract.md) §Composition state). The extraction rule is unconditional — *composition state that carries truth not reconstructible from constituent stores is a not-yet-extracted atom* — and it reaches both, because credential(../atoms/credential.md) keys on `principal_ref`, actor identity(../atoms/actor-identity.md) keys on `actor_ref`, and neither relates the two.

- The **bijection** is one element, not two — two directions of one truth, with a uniqueness constraint per side. Proposed atom: a **Namespace Binding** — immutable, bijective, unique on both keys, no lifecycle beyond *bound*. Any pattern joining constituents that key on different opaque namespaces needs it.
- The **attest log** is the second, and its atom is named as a question because the corpus is split: login(./login.md) holds a sibling `login_event_log`, and notification fanout(./notification-fanout.md) routes the identical concept *out* to event log(../atoms/event-log.md). Three compositions, two answers. Proposed atom: an **Attempt Log** *if* the divergence from Event Log is real, and nothing at all if it is Event Log wired with a composition-supplied entry schema.

WHY:
Naming a proposal is what the rule asks for and is not the extraction: *the flag is what keeps the debt visible — an unflagged truth-bearing composition store is a conformance finding; a flagged one is recorded debt riding the extraction's schedule.* Both are opened as roadmap proposals.

Composition state 3 through 5 are why the bijection holds under concurrency. The guard at registration is a look; the *write* is what makes it true against a registration of the same `actor_ref` under a different principal, which one principal's section does not exclude. credential(../atoms/credential.md)'s own constraint is per `(principal_ref, credential_type)` and says nothing about `actor_ref` — the bijection's uniqueness is this composition's, declared here.

Composition state 10 is what keeps the admitted gap honest. No leg writes the attest log, so an entry has exactly one writer and a missing entry is a finding rather than a race.

### Capability requirement

```text
Capability requirement 1: A deployment MUST declare the attest surface separation.
Capability requirement 2: A deployment MUST set the gating credential type default.
Capability requirement 3: The host MUST supply a critical section keyed by principal_ref.
Capability requirement 4: The host MUST release a section on the holder's return.
Capability requirement 5: The host MUST release a section on the holder's death.
Capability requirement 6: The host MUST hold a section's lease exactly the holding action's completion bound.
Capability requirement 7: A deployment MUST set the registration completion bound.
Capability requirement 8: A deployment MUST set the attest completion bound.
Capability requirement 9: A deployment MUST set the reconciliation cadence.
Capability requirement 10: The deployment MUST declare the clock offset allowance.
Capability requirement 11: The composition MUST refuse to start for a bound the deployment did not set.
```

Term attest surface separation: the deployment's declaration that the attestation key material is provisioned distinct from the authentication credential material — an attest surface separation; the declaring source for Invariant 2's distinct-provisioning half.

Term section: the host-supplied mutual exclusion keyed by `principal_ref` — a section; taken by [Attest As Actor] at the gate and by [Register Authenticated Actor] at the guard, held through the last write.

Term clock offset allowance: `clock_offset_allowance` — the declared bound on disagreement between this composition's seam, Credential's and Actor Identity's — a clock offset allowance.

WHY:
Capability requirement 3 is the one neither constituent grants. credential(../atoms/credential.md) serializes its own writes per record and its uniqueness constraint is a storage constraint on `register`, not a lock a composer can hold; actor identity(../atoms/actor-identity.md) serializes nothing across calls. A section spanning a call into each is the deployment's, and a deployment supplying none has no conforming gate.

Capability requirement 6 is the lease's two-sided exactness. No shorter than the holding action's bound, or a conforming invocation is evicted mid-section; no longer, or a stalled-but-alive holder blocks the principal's other invocations past the bound. The expiry is the invocation's terminus: a lapsed holder makes no further write until it re-takes the section and re-runs the pre-check that precedes the write.

Capability requirement 10 exists because this composition's records carry **three** clocks — its own seam, Credential's, and Actor Identity's. Every comparison across two of them narrows to candidates and never decides, and no write here rests on a cross-seam comparison: the gate is a status read, not a timestamp comparison.

### Primitive policy

```text
Primitive policy 1: The composition MUST answer invalid-request for a blank principal_ref.
Primitive policy 2: The composition MUST answer invalid-request for a blank actor_ref.
Primitive policy 3: The composition MUST answer invalid-request for a blank credential_material.
Primitive policy 4: The composition MUST answer invalid-request for a blank credential_type.
Primitive policy 5: The composition MUST answer invalid-request for a blank action_ref.
Primitive policy 6: The composition MUST answer invalid-request for a blank attest_credential.
Primitive policy 7: The composition MUST answer invalid-request for an expires_at the clock reading does not precede.
Primitive policy 8: The composition MUST compare an opaque argument byte-exact.
Primitive policy 9: The composition MUST NOT normalize an opaque argument.
Primitive policy 10: The composition MUST NOT case-fold an opaque argument.
Primitive policy 11: The composition MUST NOT interpret an action_ref.
Primitive policy 12: The composition MUST NOT confirm an actor_ref in the actor registry.
```

Term blank: a value that is absent, empty, or carries only whitespace — what the boundary predicate refuses; a blank argument NOT EXISTS.

Term opaque argument: `principal_ref` | `actor_ref` | `credential_type` | `action_ref` | `attestation_id`.

WHY:
Primitive policy 12 is a refusal to duplicate a constituent's judgment. actor identity(../atoms/actor-identity.md)'s `attest` and `verify` surface a registry-unknown `actor_ref` through their own outcomes, so a composition-layer existence check would be a second opinion with no store behind it.

Primitive policy 8 through 10 inherit credential(../atoms/credential.md)'s opaque-`principal_ref` discipline rather than inventing one. A deployment wanting normalization wires it at the calling layer, before the composition is invoked.

### Action wiring

```
register_authenticated_actor(principal_ref, actor_ref, credential_material, credential_type?, expires_at?) →
    {credential_id, actor_ref, bound_at}
  | rejected(
      invalid-request | invalid-credential(existing)
    | namespace-conflict(conflict position)
    | storage-failure(storage position)
    | orphan-credential(credential_id)
    )

attest_as_actor(principal_ref, action_ref, attest_credential) →
    attestation_id
  | rejected(
      invalid-request | not-bound | credential-not-active
    | invalid-attest-credential
    | attest-failed(attest position)
    )

verify_actor_attestation(attestation_id) → {result, actor_ref?, principal_ref?}
```

Term conflict position: `guard` | `binding` — where a namespace conflict is found: at the guard or at the binding write.

Term storage position: `credential` | `binding` — the write that failed: the credential or the binding.

Term attest position: `attestation` | `log(attestation_id)` — where an attest failed: at the attestation, or at the log write carrying the attestation_id.

```text
Action wiring 1: An admitted registration MUST run the guard ONLY AFTER taking the principal's section.
Action wiring 2: An admitted registration MUST answer namespace-conflict naming the guard for a principal_ref the principal binding carries.
Action wiring 3: An admitted registration MUST answer namespace-conflict naming the guard for an actor_ref the inverse map carries.
Action wiring 4: An admitted registration MUST call Credential's register ONLY AFTER the guard clears.
Action wiring 5: IF Credential's register answers duplicate-active-credential THEN an admitted registration MUST call Credential's verify with the supplied credential_material.
Action wiring 6: IF Credential's verify answers failed-verification THEN an admitted registration MUST answer invalid-credential naming the existing credential.
Action wiring 7: IF Credential's verify answers verified THEN an admitted registration MUST bind the existing credential's credential_id.
Action wiring 8: The composition MUST NOT answer duplicate-active-credential.
Action wiring 9: An admitted registration MUST write the binding ONLY AFTER Credential's register commits.
Action wiring 10: IF the binding write refuses THEN an admitted registration MUST answer namespace-conflict naming the binding.
Action wiring 11: IF the binding write fails THEN an admitted registration MUST answer storage-failure naming the binding.
Action wiring 12: An admitted registration whose section lapsed MUST write ONLY AFTER taking the section again AND running the guard again.
Action wiring 13: A re-run guard finding the principal_ref bound MUST answer orphan-credential naming the registered credential_id.
Action wiring 14: An admitted attestation MUST resolve the actor_ref from the principal binding.
Action wiring 15: IF the principal binding carries no principal_ref THEN an admitted attestation MUST answer not-bound.
Action wiring 16: An admitted attestation MUST read the gate ONLY AFTER taking the principal's section.
Action wiring 17: An admitted attestation MUST read Credential's effective status for the principal_ref AND the credential_type.
Action wiring 18: IF no effective-active credential EXISTS THEN an admitted attestation MUST answer credential-not-active.
Action wiring 19: An admitted attestation MUST call Actor Identity's attest ONLY AFTER the gate read answers effective-active.
Action wiring 20: An admitted attestation MUST call Actor Identity's attest with the bound actor_ref.
Action wiring 21: An admitted attestation MUST NOT call Actor Identity's attest with a caller-supplied actor_ref.
Action wiring 22: An admitted attestation MUST call Actor Identity's attest with the caller's attest_credential.
Action wiring 23: An admitted attestation MUST NOT call Actor Identity's attest with the credential_material.
Action wiring 24: An admitted attestation MUST append an attest log entry carrying the gate's credential_id.
Action wiring 25: IF the append fails THEN an admitted attestation MUST answer attest-failed naming the log AND the attestation_id.
Action wiring 26: [Verify Actor Attestation] MUST call Actor Identity's verify with the attestation_id.
Action wiring 27: [Verify Actor Attestation] MUST resolve the verified attestation's actor_ref through the inverse map.
Action wiring 28: [Verify Actor Attestation] MUST NOT write.
Action wiring 29: The composition MUST take a principal_ref, an actor_ref AND a credential_material on register_authenticated_actor.
```

Term admitted registration: a [Register Authenticated Actor] call whose arguments cleared the boundary predicate.

Term admitted attestation: an [Attest As Actor] call whose arguments cleared the boundary predicate.

Term effective-active: Credential's derived status projection reading active — stored active AND the credential's expiry instant not reached, evaluated by Credential against the clock reading at Credential's own seam.

WHY:
Action wiring 5 through 8 are the re-entry arm, and possession is what makes it safe. A binding is an authority-bearing transition — it makes the presenter the principal every signature under `actor_ref` resolves to — so it may not rest on the caller's word that the existing credential is theirs. The arm calls `Credential.verify` against the existing record, and only a verified presenter reaches the binding step. That is also why the bare `duplicate-active-credential` is never exported: every landing of it is this arm, which is what lets a re-invocation after a binding-position failure reach the step that failed instead of dying at the one before it.

Action wiring 10 through 13 carry the retry bit in the rejection's own position. `guard` and `credential` mean nothing committed and the whole action may be retried; `binding` means the credential **exists** and a retry re-enters through the arm rather than registering a second one; `orphan-credential` means another invocation bound this principal while the section lapsed, so the caller does not re-run at all and the named credential is the reconciliation leg's to surface.

Action wiring 25 is the same discipline one action over. `attestation` means nothing committed; `log` means the attestation committed and carries its id, so the caller holds a valid attestation and must not re-run — a re-run would produce a second, equally valid one, because actor identity(../atoms/actor-identity.md) records a fresh attestation per call and nothing keys one to the invocation that produced it.

### Wiring decision

```text
Wiring decision 1: The composition MUST gate an attestation on the gating credential's effective-active status.
Wiring decision 2: The composition MUST read the gate under the principal's section.
Wiring decision 3: The composition MUST write the attestation under the section the gate read held.
Wiring decision 4: The composition MUST NOT close an attestation Actor Identity already recorded.
Wiring decision 5: The composition MUST NOT ask Actor Identity to refuse a revoked principal's attestation.
```

WHY:
The cascade is forward closure, and the two refusals are why it has to live here. actor identity(../atoms/actor-identity.md) validates an attestation credential against the actor registry's public material and has no knowledge of credential(../atoms/credential.md) at all — it structurally cannot see a revocation, so the gate cannot live inside it (Wiring decision 5). And a revoke-the-set cascade of the kind login(./login.md) runs over sessions has nothing to revoke: an attestation is an immutable record of a past act, not a live grant, so closing the surface forward is the only cascade available (Wiring decision 4).

### Housekeeping

```text
Housekeeping 1: The orphaned-credential leg MUST run at an instance's start.
Housekeeping 2: The orphaned-credential leg MUST run every reconciliation cadence.
Housekeeping 3: The orphaned-credential leg MUST NOT write.
Housekeeping 4: The orphaned-credential leg MUST NOT take a section.
Housekeeping 5: The orphaned-credential leg MUST NOT examine a credential younger than the registration completion bound AND the clock offset allowance.
Housekeeping 6: The orphaned-credential leg MUST report a credential the principal binding binds to no entry.
Housekeeping 7: The orphaned-credential leg MUST NOT promise a closure window.
```

WHY:
The leg reports and does not repair, and every other rule follows from that. Because it writes nothing and holds nothing, two runs at once — a restart beside the cadence, or two nodes — produce at worst two reports of one credential and never two acts (Housekeeping 3, Housekeeping 4). Because it reports rather than closes, no liveness inequality is owed (Housekeeping 7): the report lands as a finding on the deployment's compliance surface, where the identity-management surface acts on it under its own identity.

Housekeeping 5 is the age edge. A credential younger than the registration bound plus the clock offset allowance is a registration in flight, not an orphan, and a leg that reported it would be filing against a correct invocation mid-section.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent. Each carries the constituent guarantees it rests on rather than restating them as invariants of its own.

- **Invariant 1 — Revocation cascade, attest-surface closure.**
  ```text
  Invariant 1.1: The composition MUST NOT produce an attestation for a principal_ref carrying no effective-active gating credential at the gate read.
  Invariant 1.2: The gate read MUST precede the attestation write inside one held section.
  Invariant 1.3: A revoked gating credential MUST close the principal's attest surface for EVERY later call.
  ```
  WHY: rests on credential(../atoms/credential.md)'s revocation-absorbing terminal, which is what makes *every later call* true rather than merely likely, and on actor identity(../atoms/actor-identity.md)'s attestation immutability, which is what makes closure forward-only. The one declared residue is Concurrency 3.
- **Invariant 2 — Secret-surface separation.**
  ```text
  Invariant 2.1: The composition MUST NOT pass the credential_material to Actor Identity's attest.
  Invariant 2.2: The composition MUST NOT pass Credential's verifier to Actor Identity's attest.
  Invariant 2.3: A deployment MUST provision the attest credential distinct from the credential_material.
  ```
  WHY: the composition forecloses cross-routing structurally and the deployment attests the provisioning. Whether the two opaque secrets are *cryptographically* distinct cannot be read from any record here, which is why Invariant 2.3 is a deployment obligation and External check 1 is where it clears.
- **Invariant 3 — Namespace binding.**
  ```text
  Invariant 3.1: EVERY bound principal_ref MUST carry EXACTLY ONE actor_ref.
  Invariant 3.2: EVERY bound actor_ref MUST carry EXACTLY ONE principal_ref.
  Invariant 3.3: The principal binding AND the inverse map MUST agree.
  ```
  WHY: the guard looks and the constraint decides. Invariant 3.3's failure is evidence of a failed atomic write rather than a race, because Composition state 3 puts both directions in one transaction.
- **Invariant 4 — Attestation traceability.**
  ```text
  Invariant 4.1: EVERY [Attest As Actor] call MUST append EXACTLY ONE attest log entry.
  Invariant 4.2: An admitted attestation answering attest-failed naming the log MUST NOT append an attest log entry.
  Invariant 4.3: EVERY success entry MUST carry the attestation_id AND the gate's credential_id.
  Deleted: Invariant 5. Composes 4 owns it.
  ```
  WHY: Invariant 4.2 is the one admitted gap and it is admitted rather than hidden — the attestation committed and the entry did not, so the call answers with the attestation's id and Check 4 surfaces the unlogged attestation once it is older than the attest completion bound. The deleted invariant asserted both constituents' invariants hold over this composition's instances, which `execution-contract.md` §Conformance settles by reference (Authority 6, council read 53). It is the fourth such collapse and the cheapest: one rule covering two atoms, where the other three compositions spent one rule per atom. What it carried beyond the blanket is Composes 5 through 10.

---

## Examples

### Walkthrough — register, attest, then revoke-and-fail, end to end

A regulated software vendor authenticates developers and requires every release commit to be signed. It deploys Authenticated Actor with `gating_credential_type_default = "fido2"` and `attest_surface_separation = enforced`.

1. **Registration.** The identity-management surface registers developer `dev_smith`: `register_authenticated_actor(principal_ref = "dev_smith", actor_ref = "actor_smith", credential_material = <fido2-attestation-object>, credential_type = "fido2")`. The namespace-conflict guard passes (neither namespace is bound); `Credential.register` returns `credential_id = "cred_s01"`; `principal_to_actor["dev_smith"] = {actor_ref: "actor_smith", credential_type: "fido2", credential_id: "cred_s01", bound_at}` and `actor_to_principal["actor_smith"] = "dev_smith"` are written atomically. Returns `{credential_id: "cred_s01", actor_ref: "actor_smith", bound_at}`.

2. **Attestation while Active.** The developer signs a release commit with their **separate hardware signing key**: `attest_as_actor(principal_ref = "dev_smith", action_ref = "commit_c44a", attest_credential = <hardware-signing-key>)`. Step 2 resolves `actor_smith`. Step 3 takes `dev_smith`'s section and reads Credential's `read(filter)` surface: an effective-Active `fido2` credential, `cred_s01`, exists for `("dev_smith", "fido2")` → gate open. Step 4 calls `Actor Identity.attest("commit_c44a", "actor_smith", <hardware-signing-key>) → attestation_id = "att_a17"`. Step 5 logs `success` with `credential_id: "cred_s01"` and releases the section. Returns `att_a17`. The continuous-integration system later calls `verify_actor_attestation("att_a17") → {result: verified, actor_ref: "actor_smith", principal_ref: "dev_smith"}` before merging — the signature verifies *and* resolves to the authenticated developer.

3. **Revocation closes the surface.** Security determines `cred_s01` was compromised. The identity-management surface calls `Credential.revoke("cred_s01", revoked_by_ref = "security_team", reason = "key-compromise")` — `cred_s01` is now `Revoked` (Credential Invariant 4). No call into Authenticated Actor is required to "cascade": the next attestation attempt is refused structurally. `attest_as_actor("dev_smith", "commit_c45b", <hardware-signing-key>)` → step 3 reads the credential store under the section, finds **no effective-Active credential** for `("dev_smith", "fido2")` → appends `attest_log {outcome: credential-not-active(Revoked), credential_id: "cred_s01"}`; returns `rejected(credential-not-active)`. The revoked login can no longer sign (Invariant 1). The earlier `att_a17` remains `verified` — it was validly authorized before revocation (Actor Identity Invariant 8).

### Domain example — rotation keeps the surface open

The same developer's hardware authenticator is replaced under the 12-month rotation policy. The identity-management surface calls `Credential.rotate("cred_s01", <new-fido2-object>) → "cred_s02"` (`cred_s01` → `Rotated`, `cred_s02` → `Active`, same `("dev_smith", "fido2")` pair — Credential Invariants 2 and 6). No rebinding is needed: `attest_as_actor("dev_smith", "commit_c46c", <hardware-signing-key>)` → step 3 finds an `Active` credential for the pair (the rotation successor) → gate open → attestation produced. The gate keys on the `(principal_ref, credential_type)` pair, not the fixed `credential_id`, precisely so that a *rotation* (the actor is still legitimate) keeps the surface open while a *revocation* (the actor's authority is withdrawn) closes it. This is the load-bearing distinction between Credential Invariant 6 (rotation non-mutation, new `Active` successor) and Invariant 4 (revocation absorbing, no `Active` successor).

### Rejection path — namespace conflict and unbound attest

- **Namespace conflict.** A second registration reuses an already-bound actor: `register_authenticated_actor("dev_jones", "actor_smith", <material>, "fido2")` → step 2 finds `actor_smith` already in `actor_to_principal` → `rejected(namespace-conflict(guard))`; no credential is registered, no binding written. Had two registrations for `actor_smith` under two different principals passed step 2 concurrently — two sections, one per principal — both would register a credential and the maps' uniqueness constraint would refuse the second binding at step 4 → `rejected(namespace-conflict(binding))`; that principal's credential is an orphan until a re-invocation with an unbound `actor_ref` adopts it through step 3's arm. The bijection (Invariant 3) is preserved: `actor_smith` stays bound to exactly `dev_smith`.
- **Attest for an unbound principal.** `attest_as_actor("dev_unknown", "action_x", <key>)` for a principal never registered through the composition → step 2 finds no binding → `attest_log {outcome: not-bound}`; `rejected(not-bound)`. This is distinct from `credential-not-active`: the principal was never an authenticated actor at all.
- **Invalid attestation credential.** `attest_as_actor("dev_smith", "commit_c47d", <wrong-signing-key>)` while the credential is `Active` → gate open, but `Actor Identity.attest` returns `invalid-credential` (the signing material does not validate against the registry's public material for `actor_smith`) → `attest_log {outcome: invalid-attest-credential}`; `rejected(invalid-attest-credential)`. The gate (authentication still valid) and the attest check (signing key valid) are independent surfaces — secret-surface separation in action (Invariant 2).

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "prove this signed action was authorized by a principal whose login was valid at signing time, and trace the signature to that login."** An auditor examines attestation `att_a17`. `verify_actor_attestation("att_a17")` returns `{verified, actor_ref: "actor_smith", principal_ref: "dev_smith"}` — the proof verifies (Actor Identity Invariants 2 and 3) *and* resolves to the authenticated principal via the namespace binding (Invariant 3). The auditor reads the credential store for `("dev_smith", "fido2")` — `cred_s01`, the record the `success` entry's `credential_id` names — and confirms it was effective-Active at `att_a17.attested_at`: its `revoked_at` lies later than that by more than `clock_offset_allowance` (Credential's clock and Actor Identity's are two seams, so the comparison narrows under the allowance rather than deciding on its own). The attest-log entry for `att_a17` corroborates the timeline (Invariant 4). Every claim is answered from the composition's records plus the two constituent stores — no developer narration. The structural guarantee that a *revoked* login could not have produced a *new* signature after revocation is Invariant 1.

**Disputed signature — the principal claims they did not authorize an action.** `dev_smith` disputes `commit_c44a`. The investigator calls `verify_actor_attestation("att_a17")`: `verified` binds `actor_smith` to `commit_c44a` at `attested_at` (Actor Identity Invariant 8). The namespace binding resolves `actor_smith` to `dev_smith` (Invariant 3). The dispute cannot be sustained without claiming credential compromise — which is exactly the boundary Actor Identity Invariant 8 names (non-repudiation conditional on credential integrity), routed to a Compromise Disclosure composing pattern. The investigator additionally confirms, from the credential store and by the entry's `credential_id`, that `cred_s01` was effective-Active at signing time within `clock_offset_allowance`, so the signature was produced through a valid login surface — Invariant 1's gate was satisfied at the time.

**Breach investigation — "during the compromise window, was any new signature produced after we revoked the credential?"** A security team revoked `cred_s01` at `T_revoke` and asks whether the attacker produced signatures afterward. They query the `attest_log` for `dev_smith` entries whose `attempted_at` is later than `T_revoke + clock_offset_allowance` (`T_revoke` is `cred_s01.revoked_at`, Credential's stamp; `attempted_at` is the composition's — two seams): every such entry shows `outcome: credential-not-active(Revoked)`, `credential_id: "cred_s01"`, and a null `attestation_id` — the gate refused them (Invariant 1). A `success` entry in that region would be the smoking gun, and Invariant 1 forecloses it: every gate read after the revoke committed finds no effective-Active record. Entries inside the allowance window around `T_revoke` are the region the records cannot order across seams. The residue is sized on the attestation itself: a `success` entry naming `cred_s01` whose attestation's `attested_at` lies between `T_revoke − clock_offset_allowance` and `T_revoke + clock_offset_allowance + attest_completion_bound` is the **declared residue** — an attestation the gate read as valid and a revoke that landed inside the same held section — reported by check 2 as a candidate, not as a conformance failure; one whose `attested_at` lies later than that upper edge is the conformance failure, since its gate read could not have preceded the revoke. Every attestation in the Actor Identity store for `actor_smith` therefore carries an `attested_at` at or before `T_revoke + clock_offset_allowance + attest_completion_bound`; the forward-closure boundary is the revocation, the residue window is declared and sized, and the `attest_log` is the records-alone evidence of every refused post-revocation attempt.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the credential store, the attestation store, the binding maps and the attest log, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find EVERY bound principal_ref carrying one actor_ref (Invariant 3.1).
Check 1.2: An auditor MUST find EVERY bound actor_ref carrying one principal_ref (Invariant 3.2).
Check 1.3: An auditor MUST find the principal binding AND the inverse map agreeing (Invariant 3.3).
Check 2.1: An auditor MUST find EVERY success entry carrying the credential_id the gate read (Invariant 4.3).
Check 2.2: An auditor MUST read a success entry whose attestation instant follows the gate credential's revoked instant beyond the clock offset allowance AND the attest completion bound as an Invariant 1.1 violation.
Check 2.3: An auditor MUST read a success entry inside that window as the declared residue (Concurrency 3).
Check 3.1: An auditor MUST find EVERY [Attest As Actor] call carrying one attest log entry (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY credential-not-active entry carrying the observed status (Composition state 8).
Check 4.1: An auditor MUST find EVERY attestation older than the attest completion bound AND the clock offset allowance carrying an attest log entry (Invariant 4.2).
Check 5.1: An auditor MUST find no attest log entry changed (Composition state 9).
Check 6.1: An auditor MUST find EVERY registered credential older than the registration completion bound AND the clock offset allowance bound in the principal binding (Housekeeping 6).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```text
External check 1: An auditor needing the two secret surfaces confirmed distinct MUST read the deployment's own provisioning (Invariant 2.3).
External check 2: An auditor needing the section confirmed MUST read the deployment's own host (Capability requirement 3).
External check 3: An auditor needing an actor_ref confirmed in the actor registry MUST read the actor registry (Composes 8).
External check 4: An auditor needing a verification read recorded MUST read a composed access log (Non-goal 12).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 4).
```

WHY:
Check 2.2 and Check 2.3 are the residue made auditable, and the pair matters more than either alone. The two instants come from two seams — the attestation's from actor identity(../atoms/actor-identity.md), the revocation's from credential(../atoms/credential.md) — so a comparison inside the allowance plus the bound decides nothing and narrows to the residue Concurrency 3 declares; outside it, the gate let through what it should have closed. An auditor with only one of the two rules would either file against every conforming deployment or against none.

External check 1 is the one a deployment can fail while every record looks correct. The composition never routes Credential material into `attest`, which is structural and checkable from the wiring; whether the deployment *provisioned* two genuinely distinct secrets is not in any store here, and a deployment declaring anything other than enforced separation forfeits Invariant 2 while leaving the attest log unchanged.

---

## Non-goals

```text
Non-goal 1: The composition MUST NOT confirm the two secret surfaces cryptographically distinct.
Non-goal 2: The composition MUST NOT confirm an actor_ref provisioned in the actor registry.
Non-goal 3: The composition MUST NOT invalidate an attestation for a credential later found compromised.
Non-goal 4: The composition MUST NOT compose audit trail(./audit-trail.md).
Non-goal 5: The composition MUST NOT revoke a credential.
Non-goal 6: The composition MUST NOT rotate a credential.
Non-goal 7: The composition MUST NOT close an attestation already recorded.
Non-goal 8: The composition MUST NOT register an actor_ref.
Non-goal 9: The composition MUST NOT authorize an action.
Non-goal 10: A deployment needing an authorized action MUST compose permissions(../atoms/permissions.md).
Non-goal 11: The composition MUST NOT rebind a bound principal_ref.
Non-goal 12: The composition MUST NOT record a verification read.
Non-goal 13: The composition MUST NOT resolve an attestation carrying an actor_ref the inverse map does not carry.
Non-goal 14: The composition MUST NOT wrap the credential write AND the binding write in one transaction.
```

WHY:
Non-goal 3 and Non-goal 7 are the cascade's shape stated as refusals. An attestation is an immutable record that a bound actor signed something at an instant when its credential was effective-active; a credential later found compromised changes what that record *means* to an investigator and changes nothing about the record. Forward closure is the only cascade an immutable record admits.

Non-goal 4 is a deliberate omission with a substitute named: the attestations **are** the regulated record here, and the tamper-evident external-auditor surface is the attestation store itself rather than a separate substrate. That is the one place this composition diverges from login(./login.md)'s shape, which pairs its own log with an Audit Trail.

Non-goal 14 is why the orphan exists at all. Two stores, no distributed transaction, so the writes are ordered — the credential first, irreversibly, then the binding — and the reachable partial is a registered credential bound to nothing. The retry bit in the rejection's position is what lets a re-invocation reach the step that failed, and the reconciliation leg is what surfaces the ones that never came back.

---

## Edge cases

### Concurrency

```text
Concurrency 1: The section MUST serialize the composition's invocations for one principal_ref.
Concurrency 2: The section MUST NOT serialize Credential's revoke.
Concurrency 3: A revoke committing between the gate read and the attestation write MUST stand as the declared residue.
Concurrency 4: The residue MUST NOT EXCEED the attest completion bound in duration.
Concurrency 5: A gate read following a revoke MUST find no effective-active credential.
Concurrency 6: A deployment needing the residue closed MUST route a revoke through a surface taking the principal's section.
```

WHY:
The residue is named rather than cured, and both halves of that are deliberate. An externally-issued `Credential.revoke` contends on nothing of this composition's, so a revoke landing after the gate read and before the attestation write produces an attestation under a credential the gate observed effective-active — bounded in duration by the section, and closed for every later call by revocation's absorbing terminal (Concurrency 5). What finds it afterwards is the pair of stamps from two seams: the attestation's instant against the record's revoked instant, inside the clock offset allowance and the completion bound, which is what Check 2 reads.

Concurrency 6 is the deployment's way out and is named as an option rather than folded in, because this composition does not revoke credentials (Composes 7) and a cut that reached into the identity-management surface to take a lock would be claiming an action it declines to own. A check-then-attest with **no** section is the time-of-check-to-time-of-use hazard the buggy twin demonstrates, which is a different thing entirely.

---

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Deleted: Composition note 2. Invariant 2.3 owns it.
Composition note 3: A deployment MUST own an actor_ref's provisioning in the actor registry.
Composition note 4: A deployment MUST own a credential's revocation AND rotation.
Composition note 5: A deployment needing the cascade residue closed MUST revoke a gating credential ONLY AFTER taking the principal's section.
Composition note 6: A deployment MUST act on the orphaned-credential leg's report.
```

WHY:
Composition note 5 is the deployment's one route to a residue-free cascade and it stays a note rather than a rule of this composition, because taking a section before a revoke means reaching into the identity-management surface — an action `Composes 7` declines to own. Naming the route is what a composition can do about a gap it will not close itself.

---

## Terms

The canonical concepts this spec refers to. Each `term` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projects** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the three emergent actions it exposes ([Register Authenticated Actor], [Attest As Actor], [Verify Actor Attestation]) — none belonging to a single constituent — the attest-log fields those actions record ([Outcome], [Observed Status]), and its own rejections ([Namespace Conflict], [Invalid Credential], [Orphan Credential], [Not Bound], [Credential Not Active], [Invalid Attest Credential], [Attest Failed]). Its emergent state — the namespace-binding maps (`principal_to_actor`, `actor_to_principal`) and the `attest_log` — is a composition-introduced surface no constituent provides, left as backticked store tokens rather than carded. References to the constituent atoms and their operations — Credential's `register` / `rotate` / `revoke`, Actor Identity's `attest` / `verify` — the relayed tokens (`principal_ref`, `actor_ref`, `action_ref`, `credential_material`, `attest_credential`, `credential_type`, `credential_id`, `attestation_id`), the credential states (`Active` / `Revoked` / `Expired` / `Rotated`), and the inherited rejections (`invalid-request`, `storage-failure` — exported at this boundary with its position, `storage-failure(credential | binding)`; `duplicate-active-credential` is consumed by step 3's re-entry arm and not exported) remain qualified/backticked, not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term qualifiers: `migrated` — rewritten in GRACE lang v0.40 (2026-09-14).

Term terms: `composition`, `constituents`, `principal binding`, `attest log`, `bijection`, `attest surface separation`, `section`, `clock offset allowance`, `blank`, `opaque argument`, `admitted registration`, `admitted attestation`, `effective-active`, `conflict position`, `storage position`, `attest position`.

Term record verbs: call, answer, read, write, append, store, key, hold, take, release, serialize, resolve, bind, register, revoke, rotate, gate, precede, close, produce, provision, pass, agree, carry, stand, change, report, examine, promise, run, refuse, set, declare, own, act, compose, inherit, confirm, interpret, normalize, case-fold, compare, authorize, invalidate, rebind, wrap, find, serve, supply, ask, route, record.

Term actors: the composition; the constituents; the host; a deployment; an auditor; a caller; a principal; an actor; the orphaned-credential leg; an invocation; an attestation; a credential.

Term cited: `execution-contract.md` §Conformance — recursive conformance and the inherited guarantee. `execution-contract.md` §Composition state — the extraction-pending classification. `pressure-testing.md` §Capability provenance — the declared-source discipline every invariant's rests-on clause follows.

#### Register Authenticated Actor

The composition's intake action: it binds an `actor_ref` to a `principal_ref` (behind the namespace-conflict guard) and registers the principal's authentication credential through `Credential.register` — two ordered writes, credential then binding, the strict-inverse binding maps written atomically as the second. Returns `{credential_id, actor_ref, bound_at}`, or [Namespace Conflict], [Invalid Credential], [Orphan Credential], or an inherited Credential rejection (`invalid-request`, `storage-failure(credential | binding)`); Credential's `duplicate-active-credential` is the re-entry arm that binds an existing effective-Active credential once `Credential.verify` proves the presenter holds it.

Kind: Operation

#### Attest As Actor

The composition's load-bearing emergent action: it produces a non-repudiable attestation for the bound actor **only if** the principal's gating credential is currently `Active` — the revocation cascade, enforced as a forward gate read under `principal_section` immediately before the attestation write (Invariant 1). Returns the `attestation_id`, or [Not Bound] (principal never bound), [Credential Not Active] (the gate is closed), [Invalid Attest Credential] (signing key invalid), or [Attest Failed] — positioned `attestation` (nothing committed) or `log(attestation_id)` (the attestation committed, the entry did not). Every call appends exactly one [Outcome] to the `attest_log`, except the `log` landing, which check 4 surfaces.

Kind: Operation

#### Verify Actor Attestation

The composition's read-only query: a pass-through to `Actor Identity.verify` that additionally resolves the verified attestation's `actor_ref` back to its bound `principal_ref`. Returns `{result, actor_ref?, principal_ref?}`; changes no state.

Kind: Operation

#### Namespace Conflict

The composition's own rejection from [Register Authenticated Actor] — returned when the `principal_ref` or the `actor_ref` is already bound, enforcing the principal ⇔ actor bijection at the boundary (Invariant 3). Positioned: `guard` (step 2 — nothing is written) or `binding` (step 4 — the maps' uniqueness constraint refused the write after the credential was registered; the credential exists, unbound, and a re-invocation with an unbound `actor_ref` adopts it).

Kind:      Member
Member of: the register rejection
Role:      Rejection
Projects:  namespace-conflict

#### Invalid Credential

The composition's own rejection from [Register Authenticated Actor]'s re-entry arm — returned when the pair already holds an effective-Active credential and `Credential.verify` does not return `verified` for the presented `credential_material`: the presenter has not proved possession of the existing credential, so nothing is adopted and nothing is written. Carries `existing` to say which credential the verification ran against.

Kind:      Member
Member of: the register rejection
Role:      Rejection
Projects:  invalid-credential

#### Orphan Credential

The composition's own rejection from [Register Authenticated Actor] — returned, post-commit, when the section lease lapsed after the credential was registered and the re-run guard finds `principal_ref` bound by another invocation. Carries the `credential_id` this invocation registered: it is bound in no `principal_to_actor` entry (unless the winning binding adopted it), it is the orphaned-credential leg's to surface, and the caller does not re-run the action.

Kind:      Member
Member of: the register rejection
Role:      Rejection
Projects:  orphan-credential

#### Not Bound

The composition's own rejection from [Attest As Actor] — returned when the `principal_ref` was never bound through the composition. Structurally distinct from [Credential Not Active]: *never an authenticated actor*, versus *bound but no longer authenticated*.

Kind:      Member
Member of: the attest rejection
Role:      Rejection
Projects:  not-bound

#### Credential Not Active

The composition's load-bearing rejection from [Attest As Actor] — the revocation cascade's observable form: returned when no `Active` credential exists for the bound `(principal_ref, credential_type)` pair (revoked, expired, or rotated without a current successor). Carries the [Observed Status] of the most-recent credential record.

Kind:      Member
Member of: the attest rejection
Role:      Rejection
Projects:  credential-not-active

#### Invalid Attest Credential

The composition's own rejection from [Attest As Actor] — the mapping of `Actor Identity.attest`'s `invalid-credential`: the presented signing material did not validate against the actor registry's public material for the bound `actor_ref`. Independent of the authentication gate (secret-surface separation, Invariant 2).

Kind:      Member
Member of: the attest rejection
Role:      Rejection
Projects:  invalid-attest-credential

#### Attest Failed

The composition's own rejection from [Attest As Actor], positioned. `attestation`: the mapping of `Actor Identity.attest`'s `storage-failure` — nothing was recorded, the whole action may be retried. `log(attestation_id)`: the attestation was recorded and the `attest_log` append failed — the caller holds the committed id and must not re-run the action; check 4 surfaces the unlogged attestation.

Kind:      Member
Member of: the attest rejection
Role:      Rejection
Projects:  attest-failed

#### Outcome

The attest-log entry's classification of an [Attest As Actor] call: `success`, or one of the named rejection reasons ([Not Bound], [Credential Not Active], [Invalid Attest Credential], [Attest Failed] at its `attestation` position only, `invalid-request`). Every call appends exactly one entry except the `log` landing of [Attest Failed], which is the one call that commits an attestation and writes no entry (Invariant 4); the log is the composition's records-alone audit surface.

Kind:      Field
Field of:  the attest-log entry
Role:      the attempt classification
Projects:  outcome

#### Observed Status

The credential status the attest gate observed when it refused a call — the most-recent credential record's status for the `(principal_ref, credential_type)` pair (`Revoked` | `Expired` | `Rotated`), the absence of any `Active` credential being what closed the gate. Carried inside the [Credential Not Active] outcome for post-hoc forensics.

Kind:      Field
Field of:  the attest-log entry
Role:      the gate-closing credential status
Projects:  observed_status

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a term marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Register Authenticated Actor]: #register-authenticated-actor
[Attest As Actor]: #attest-as-actor
[Verify Actor Attestation]: #verify-actor-attestation
[Namespace Conflict]: #namespace-conflict
[Invalid Credential]: #invalid-credential
[Orphan Credential]: #orphan-credential
[Not Bound]: #not-bound
[Credential Not Active]: #credential-not-active
[Invalid Attest Credential]: #invalid-attest-credential
[Attest Failed]: #attest-failed
[Outcome]: #outcome
[Observed Status]: #observed-status

---

## Standards references

Authenticated Actor is the structural form of the requirement that authentication and non-repudiable attestation be bound under one principal, with revocation of the former closing the latter. Its primary anchors:

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-63B §5.2 (Authenticator Lifecycle — Binding, Revocation, and Reauthentication)** — the requirement that a revoked authenticator can no longer be used to establish authority. The revocation cascade (Invariant 1) is the structural form: a revoked authentication credential closes the actor's attestation surface, so authority to sign flows from a currently-valid authenticator.
- **NIST SP 800-57 Part 1 (Recommendation for Key Management — General)** — key-usage separation: a key used for one purpose (authentication) should not serve another (signing/attestation). Secret-surface separation (Invariant 2) is the composition-level expression of the key-separation principle.
- **PCI DSS (Payment Card Industry Data Security Standard — the card networks' mandatory security rules for cardholder data) Requirement 8.6 (management of authentication factors and their binding to individual accounts)** — authentication factors must be bound to a specific identity and managed through their lifecycle; the namespace binding (Invariant 3) and the revocation cascade (Invariant 1) are the structural mechanisms for the bind-and-revoke lifecycle of a payment-system actor.
- **FIPS 140-3 (Federal Information Processing Standard — Security Requirements for Cryptographic Modules)** — the standard for the cryptographic modules that hold and operate signing keys; the distinct-key-surface obligation (Invariant 2, externally-clearable) is where a deployment's FIPS 140-3-validated module provisioning is the cleared evidence that the attestation key is genuinely separate material.

Authenticated Actor inherits the broader standards compliance of its constituents:

- Through **Credential**: NIST SP 800-63B (authenticator and verifier requirements — stored verifiers, not raw secrets), FIDO2 / WebAuthn (phishing-resistant authenticator binding), PCI DSS Requirement 8, ISO/IEC 27001 §A.9.4 (system and application access control), GDPR (EU General Data Protection Regulation) Article 32 (security of processing — the verifier-not-material discipline). The revocation-absorbing and terminal-absorbing invariants the cascade rests on are Credential's.
- Through **Actor Identity**: NIST SP 800-63-3 (identity and authenticator assurance), eIDAS Regulation (EU 910/2014 — qualified electronic signatures), FIPS 186-5 (Digital Signature Standard), 21 CFR (US Code of Federal Regulations) Part 11 (FDA electronic records and signatures — uniquely attributable, repudiation-resistant signatures), DEA EPCS (US Drug Enforcement Administration — Electronic Prescriptions for Controlled Substances; 21 CFR §1311 — two-factor cryptographic attestation for controlled-substance prescriptions), HIPAA (US Health Insurance Portability and Accountability Act) §164.312(d) (person or entity authentication), SOX (Sarbanes-Oxley Act) §302/§404 (officer certifications and internal-control evidence). The non-repudiation contract the cascade preserves forward is Actor Identity's.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the model treats check-and-attest as one atomic step and cannot exhibit an externally-issued revoke as a second process over the per-principal section (the declared residue), the section's lease terminus, the step-5 log arm after a committed attestation, or the two-principal race the maps' uniqueness constraint decides at step 4; was verified — authenticated-actor.tla + 1 twin, 2026-06-10
last gate: 2026-06-10 — Final Critique 4, fresh reader — clean

open:
- 2026-08-30-a · refining · formal · the model has no external-revoke process over `principal_section`, no lease terminus, no post-commit `attest-failed(log)` arm, no step-4 uniqueness race, and no possession-verified re-entry arm → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/authenticated-actor.md`.

- **2026-08-30 — The gate runs under the composition's own section and names its residue; the orphan re-enters instead of dying; every exported code carries its position.** *Chose:* `principal_section` declared as an instance capability requirement with lease semantics, under which the status read and the attestation write run, with an externally-issued `Credential.revoke` stated as **not** serialized and the one-attestation residue it can produce declared, bounded by `attest_completion_bound`, and made findable by a `credential_id` on every `attest_log` entry; a composition-introduced storage-level uniqueness constraint on both binding maps re-checked at step 4; a re-entry arm on `duplicate-active-credential` that binds the existing effective-Active credential only after `Credential.verify` proves the presenter holds it (`invalid-credential(existing)` otherwise), so a re-invocation after a `binding`-position failure reaches the step that failed without becoming a way to claim another principal's credential; `orphan-credential(credential_id)` for the post-commit guard re-run; the lease measured from the section take as one interval with each completion bound; check 2 sizing the residue on the attestation's `attested_at` against `revoked_at` within `clock_offset_allowance + attest_completion_bound`; a report-only orphaned-credential leg on `reconciliation_cadence` and at restart, filtered by unbound `credential_id` and gating pair, bounded below by `registration_completion_bound`, declared horizon-less, promising no closure window, and carried as check 6; `storage-failure(credential | binding)`, `namespace-conflict(guard | binding)`, and `attest-failed(attestation | log(attestation_id))` on the signatures; `clock_offset_allowance` on every cross-seam comparison, with check 2 reporting candidates inside the window. *Over:* a "record lock `Credential.revoke` must acquire" attributed to Credential Invariant 2, which declares a uniqueness constraint and no lock; a re-entry arm that adopted an existing credential on the presenter's say-so; a namespace guard offered as a serialization; an orphan "surfaced as a finding" by no leg and repaired by no action; a bare token on both sides of the credential commit and no arm at all after the attestation commit; a breach example that ordered two seams' stamps as if they were one clock. *Because:* an invariant is only as sound as the capability it rests on, and a lock nobody declared is ambient authority; a re-invocation that dies at `duplicate-active-credential` cannot repair the failure it was retried for; a caller who cannot tell `credential` from `binding` registers twice; a binding nobody proved possession for is an authority-bearing transition resting on an unauthenticated principal; and a stamp from another seam narrows a decision, never makes one (the frozen rules of 2026-08-30 — *Capability provenance*, *A composition's own rejection arm carries the retry bit*, *A stamp from another seam never decides a write alone*, *A compensator is exclusive* — with *A reconciliation is bounded at both ends* and *Recovery commits under a declared service identity*, frozen 2026-08-29, and §*Authentication precedence*, frozen 2026-08-27).

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except one invariant the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision`, `Concurrency` and `Reconciliation` as the surfaces, the four surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Reconciliation` is the one family minted, for the orphaned-credential leg — a second instance of the shape idempotent reservation(./idempotent-reservation.md) minted `Eviction` for, a leg running outside an invocation, and the two are deliberately **not** merged: one evicts and one reports, one takes a section and one refuses to, and calling them one family would bury the difference that decides whether either owes a liveness bound. Two names at one spec each, both flagged, both waiting (council read 61).
- **2026-09-14 — The fourth preservation-claim collapse, and the cheapest.** *Chose:* `Composes 4`, with `Invariant 5 — Constituent invariants preserved` tombstoned to it. *Over:* keeping it. *Because:* council read 53's ruling at its fourth seam. This spec spent **one** rule covering both constituents where the other three spent one per atom, so one tombstone closes what took two or three elsewhere — and the reason is visible in the document: every other invariant carries a `Rests on:` clause naming the constituent guarantees it leans on, which is provenance done properly at the invariant level. The blanket was the single place that discipline lapsed into a restatement. What it carried beyond the blanket survives as `Composes 5` through `Composes 10`: the refusals (no verify at the gate, no rotate, no revoke, no registry write) and the gate's key, none of which either atom guarantees about a caller.
- **2026-09-14 — Both extraction-pending elements were classified before the rewrite began.** *Chose:* to declare the classification against the prose spec at council read 59 and carry it into the rules here unchanged. *Over:* discovering it during the migration, which is when every other composition's state question surfaced. *Because:* the classification does not depend on the language — `execution-contract.md` §Composition state turns on whether the truth is reconstructible from constituent stores, which is a fact about the wiring — and settling it first made the `Composition state` family write itself. That order is worth keeping: classify, then migrate.

- **2026-09-14 — `Reconciliation` re-cut as `Housekeeping`, on a discriminator the first cut got wrong.** *Chose:* the family renamed, with the seven rules and every citation of them moving with it. *Over:* keeping the name and letting `Reconciliation` reach three specs. *Because:* the entry above split this leg from idempotent reservation(./idempotent-reservation.md)'s on *one evicts and one reports*, and the drift pass `GRACE-lang.md` Standard label 7 requires found that axis predicts the liveness bound on **two of four** legs — this leg reports and owes none, Eviction takes a section and writes and owes none, and the verb decides neither. What survives every member is whether anything **awaits** the leg's output: login(./login.md)'s and defensible retention(./defensible-retention.md)'s sweeps discharge a promise inside a declared window and owe a bound; this leg and idempotent reservation's evict or report with nobody waiting and owe none. Two families of two, cut on the guarantee rather than on the verb (council read 64).

NOTE: End of Authenticated Actor.

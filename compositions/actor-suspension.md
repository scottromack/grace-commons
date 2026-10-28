---
title: Actor Suspension
parent: Conceptual Compositions
nav_order: 13
has_toc: true
toc: true
---

# Actor Suspension

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Actor Suspension is a regulated composition — a specification that wires several freestanding patterns together — that does one job thoroughly: when you need to cut off an actor (a departing employee, a hacked account, a contractor who is done), it closes *every* door at once and leaves proof.

The problem it solves is the classic security gap where someone's access is pulled in one place but not another — their login is disabled but a permission grant still works, or their role is removed but an open session keeps going. The composition makes that gap visible and short-lived by treating suspension as one ordered, completed act: it records what it is about to close, finds every active permission grant the actor holds and every active login session they have, revokes each of them, marks the actor as suspended, and writes one tamper-proof audit record that lists every grant and session it revoked.

If the act stops after its revocations are made, because the audit record that closes it is refused, nothing is undone — a revoked grant or session cannot be un-revoked — but nothing is hidden either: the actor is marked as *suspending*, the record shows exactly which doors are still open, and a mandated completion sweep closes them within a declared window. A half-suspended actor is dangerous only when everyone wrongly believes they are locked out, and this composition never lets the records say that. Optionally it also revokes every login credential the actor holds — a password and a hardware key are two, and closing one would leave the other working — so they cannot sign back in.

Actor Suspension is the exact mirror of the Login pattern: Login wires up *check the credential, then start a session* on the way in; this wires up *suspend the actor, then revoke every grant and every session* on the way out. The composition's defining emergent guarantee — a property that exists only when the patterns are combined — is that single multi-surface revocation: after a successful suspension the actor provably holds zero active grants and zero active sessions, and the audit record names every one that was revoked. Its common uses are exactly the moments compliance regimes care about most: offboarding a terminated employee, responding to a compromised account, and ending a third party's access. Any system that must deactivate an actor across several access surfaces at once — and make it provable that nothing was missed — is a candidate for this composition.

---

## Intent

Every system that distinguishes actors eventually has to *un*-distinguish one. An employee leaves; a credential is found in a paste dump; a contractor's engagement ends; an account shows the signature of a takeover. The obligation that follows is deceptively simple to state and notoriously easy to botch: cut off *every* way that actor can still act, now, and be able to prove afterward that you did. The botch is always the same shape — access is revoked on one surface and not another. The session cookie is invalidated but the API (Application Programming Interface) token's permission grant is still active; the role is removed but a long-lived session keeps working; the login credential is disabled but a service grant the actor still holds quietly authorizes a scheduled job. Each gap is a half-open door, and a half-suspended actor is more dangerous than an un-suspended one, because the system and its operators believe the actor is locked out.

This is the friction the composition exists to resolve, and naming it precisely keeps the composition honest: **Actor Suspension is not an account-deactivation feature; it is a multi-surface de-authorization, completed rather than undone, whose completeness is provable.** An actor's ability to act is spread across two independent authorization surfaces that no single atom relates: **Permissions** holds the grants that say *what the actor may do*, and **Session** holds the live authenticated channels that say *the actor is currently acting*. Revoking one without the other leaves a door open. Worse, each surface has its own multiplicity — an actor may hold many grants, issued at different times by different grantors, and many sessions, one per device — so closure on each surface is itself an enumerate-then-revoke-each operation, exactly the mass-revocation pattern Permissions names as the composing system's responsibility and Session supports through its principal reference-queryable records. The structure that snapshots both surfaces, revokes every member of both, sets the actor's suspension state, and seals the whole act as one attributed, tamper-evident record belongs to no single constituent. It belongs to the composition, and this composition is that structure.

Actor Suspension is Login's mirror image, and the symmetry is load-bearing. Login is the *inbound* wiring — `Credential.verify → Session.issue` — with the emergent cascade that revoking a credential terminates the derived sessions. This is the *outbound* wiring — suspend, then revoke every grant and every session — with the emergent guarantee that suspension closes all surfaces at once. Login's cascade walks an active-session set under a snapshot and tolerates partial completion, because partial revocation beats none. This composition makes a stronger choice, and the difference is deliberate: a suspension that half-completes leaves an ambiguous security state, so this composition never leaves one *ambiguous*. What it promises is **completion**: the intent is recorded before anything is revoked, every revocation that commits stands, an actor whose cascade stopped is visibly `Suspending` with the open doors named, and a mandated sweep closes them within a declared window. The same time-of-check-to-time-of-use (TOCTOU) race Login surfaced recurs here and is resolved the same way: a grant or session the cascade targets that another process already revoked is found already-terminal and counted, not re-revoked.

This is a composition, not a new primitive. Actor Identity, Permissions, Session and Audit Trail are unchanged; the composition is the wiring that makes them coherent as one suspension surface. It introduces emergent actions — [Suspend Actor], the read-only [Suspension Report] and the thin [Reinstate Actor] — and a state machine the constituents do not carry: the actor's **Active → Suspending → Suspended** lifecycle. Actor Identity is the attestation atom, with a single attested state and no actor lifecycle of its own, deferring actor registration, deactivation and suspension to a forthcoming Actor Registry pattern; the suspension lifecycle is therefore a composition-introduced surface this composition owns, not a state read from any constituent.

What the composition is *not*: it is not the issuance surface — it revokes grants and sessions and never issues them, so it cannot by itself prevent a *new* grant or session being created for a suspended actor after the cascade's snapshot; it is not the actor registry that provisions actor identities; it is not an authorization-policy engine deciding *whether* an actor should be suspended, which is wired ahead of [Suspend Actor] at the administrative layer; and it does not restore access on reinstatement — [Reinstate Actor] lifts the suspension state and never un-revokes a terminal grant or session. Each is named explicitly in Non-goals.

---

## Composes

- **[Permissions](../atoms/permissions.md)** — the grant surface, enumerated and revoked.
- **[Session](../atoms/session.md)** — the live-channel surface, enumerated and revoked.
- **[Credential](../atoms/credential.md)** *(optional)* — the re-authentication surface, enumerated and revoked where composed.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every record is written through.

```
Composes 1: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 2: EXACTLY ONE Session instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: EXACTLY ONE Credential instance MUST serve the composition ONLY IF the credential arm stands composed.
Composes 5: The composition MUST NOT change a constituent's spec.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 8: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 9: The composition MUST reach Actor Identity through Audit Trail.
Composes 10: The composition MUST reach a constituent through the constituent's declared surface.
Composes 11: The composition MUST NOT read a constituent's records beside the constituent's declared read.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST enumerate a grant through Permissions' declared read.
Composes 16: The composition MUST enumerate a session through Session's declared read.
Composes 17: The composition MUST enumerate a credential through Credential's declared read.
Composes 18: The composition MUST revoke a grant through Permissions' revoke.
Composes 19: The composition MUST revoke a session through Session's revoke.
Composes 20: The composition MUST revoke a credential through Credential's revoke.
Composes 21: The composition MUST NOT call Permissions' grant.
Composes 22: The composition MUST NOT call Session's issue.
Composes 23: The composition MUST NOT change an attestation.
Composes 24: The composition MUST NOT reverse a constituent's revocation.
Composes 25: The composition MUST attest an invocation's audit record under the calling operator's credential.
Composes 26: The composition MUST attest a resumed cascade's constituent revocation under the resumer.
Composes 27: The composition MUST attest the sweep's audit record under the service identity.
Composes 28: The composition MUST NOT attest the sweep's audit record under a calling operator's credential.
Composes 29: The composition MUST enumerate a credential PER credential type.
Composes 30: The composition MUST NOT enumerate one credential PER principal.
Composes 31: The composition MUST NOT supply the substrate's own recording stamp.
```

Term composition: this pattern's wiring of [Permissions](../atoms/permissions.md), [Session](../atoms/session.md), [Credential](../atoms/credential.md) and the [Audit Trail](./audit-trail.md) substrate — the three actions, the actor lifecycle, the two indexes, the mark and the sweep.

Term constituents: [Permissions](../atoms/permissions.md), [Session](../atoms/session.md), [Audit Trail](./audit-trail.md), and — where the credential arm stands composed — [Credential](../atoms/credential.md).

Term credential arm: revoke_credential_on_suspend standing true with a Credential instance wired — the arm under which the cascade also closes the re-authentication surface.

Term service identity: application_actor_ref and application_credential — the composition's own registered actor and credential, and the attested emitter of every record the sweep writes and the named revoker of every revocation the sweep makes.

Term operator: suspended by ref — the principal a [Suspend Actor] call names as performing the suspension, and the principal whose credential the call carries.

Term resumer: the suspended by ref of a [Suspend Actor] call that finds the actor suspending — the principal whose credential the resume record verifies and whom the resumed cascade's constituent revocations name.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a suspension-state index.
Composition state 2: The composition MUST store a high-water mark.
Composition state 3: The composition MUST store a suspension log.
Composition state 4: The suspension-state index MUST carry the actor's lifecycle state PER suspended actor.
Composition state 5: A suspended actor's lifecycle state MUST stand as EXACTLY ONE OF active, suspending, suspended.
Composition state 6: A suspending entry MUST carry the cascade's invocation id, intent event id, operator AND reason.
Composition state 7: A suspended entry MUST carry the outcome's event id as suspension event id.
Composition state 8: The composition MUST classify the suspension-state index above the mark as derived index.
Composition state 9: The composition MUST classify the suspension-state index below the mark as truth-bearing.
Composition state 10: The composition MUST classify an aged-out entry as extraction-pending.
Composition state 11: The composition MUST name the actor registry as the extraction-pending element's proposed atom.
Composition state 12: The composition MUST classify the high-water mark as derived index.
Composition state 13: The composition MUST classify a mirrored log entry inside the audit horizon as derived index.
Composition state 14: The composition MUST classify an aged-out log entry as truth-bearing.
Composition state 15: The composition MUST classify a refusal log entry as extraction-pending.
Composition state 16: The composition MUST name the failed-attempt log as the refusal entries' proposed atom.
Composition state 17: A log entry MUST stand as EXACTLY ONE OF a mirrored log entry, a refusal log entry.
Composition state 18: An index MUST NOT stand inside an action's atomicity surface.
Composition state 19: An index MUST NOT claim cross-constituent transactional consistency.
Composition state 20: An absent suspension-state key MUST stand as a miss.
Composition state 21: An absent suspension-state key MUST NOT stand as active.
Composition state 22: A suspension-state entry the trail contradicts MUST stand as a miss.
Composition state 23: A reader MUST resolve a miss by the tail read.
Composition state 24: A reader MUST NOT resolve a miss by an enumeration of the index.
Composition state 25: The tail read MUST select an event above the mark.
Composition state 26: The tail read MUST NOT select an event below the mark.
Composition state 27: A reader MUST take the trail's answer ONLY IF the trail's answer stands later in the log than the entry's event.
Composition state 28: A reader MUST write the entry the tail read resolved.
Composition state 29: An absent suspension-state key carrying no suspension intent above the mark MUST stand as active.
Composition state 54: A reader MUST read the tail read's events PER Composition state 33 through 35.
Composition state 55: A writer MUST NOT write a suspension-state entry over an entry whose event stands later in the log than the writer's event.
Deleted: Composition state 30. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Composition state 31. Execution Contract Database 3 and Execution Contract Database 4 own it.
Composition state 32: The rebuild MUST select the composition's own events over an open-ended sequence range.
Composition state 33: The rebuild MUST read a suspension intended event carrying no outcome under the intent's invocation id as suspending.
Composition state 34: The rebuild MUST read a suspended event as suspended.
Composition state 35: The rebuild MUST read a reinstated event standing later in the log than both as active.
Composition state 36: The rebuild MUST NOT read a resume intended event as a lifecycle state.
Composition state 37: The rebuild MUST NOT read a recovery intended event as a lifecycle state.
Composition state 38: The rebuild MUST stand additive.
Composition state 39: The rebuild MUST NOT drop an entry the rebuild reads no event for.
Composition state 40: The rebuild MUST NOT read an aged-out event's payload.
Composition state 41: The composition MUST populate an index ONLY AFTER the index's backing record.
Composition state 42: EXACTLY ONE lifecycle state MUST stand PER actor.
Composition state 43: An open cascade MUST name EXACTLY ONE actor.
Composition state 44: An actor MUST NOT carry two open cascades.
Composition state 45: The composition MUST NOT store an enumerated active set.
Composition state 46: The composition MUST derive an enumerated active set at the snapshot.
Composition state 47: An intent MUST carry the enumerated active set as the plan.
Composition state 48: An outcome MUST carry the revoked set.
Composition state 49: The composition MUST NOT read the plan as the revoked set.
Composition state 50: The composition MUST NOT read the revoked set as the plan.
Composition state 51: A planned member absent from the revoked set MUST stand as an owed closure.
Composition state 52: A revoked set member absent from the plan MUST stand as a conformance failure.
Composition state 53: The composition MUST NOT duplicate a constituent's records.
```

NOTE: open 2026-10-26-a — Composition state 9 classifies the index below the mark as truth-bearing, which the section titled Composition state in `execution-contract.md` gives no element short of extraction-pending, while a miss below the mark is not observable (Composition state 26, 29); which class the window takes is open.

Term suspension-state index: actor_suspension_state — the composition's index from an actor reference to the actor's lifecycle state and the record that put the actor there; the surface the issuance gate reads and [Suspension Report] answers from.

Term high-water mark: index_high_water — the log position through which the sweep has reconciled the suspension-state index with the trail; every intent at or below it carries an index entry or an outcome naming the intent's invocation id.

Term suspension log: suspension_log — the composition's append-only record of every [Suspend Actor] and [Reinstate Actor] call, whether the call transitioned, stood as a no-op, or refused.

Term mirrored log entry: a suspension log entry an audit event of this composition carries the same act for — a suspended, a reinstated, or an outcome recording failure, each with the entry's intent behind it.

Term refusal log entry: a suspension log entry no audit event carries — an already-suspended, an already-active, an invalid-request, an intent recording failure, or a refusal that stopped before the intent.

Term tail read: the substrate's open-ended sequence range read from the high-water mark, filtered in the composition's own code to the composition's action_ref values naming one actor.

Term audit horizon: the age past which the audit instance has destroyed an event's payload, set by the instance's audit_trail_retention_policy.

Term aged-out event: an event whose age exceeds the audit horizon.

Term aged-out entry: a suspension-state entry every one of whose lifecycle-bearing events stands aged out.

Term aged-out log entry: a mirrored log entry whose audit event stands aged out.

Term aged-out actor: an actor every one of whose lifecycle-bearing events stands aged out.

Term aged-out outcome: an outcome whose payload the audit instance has destroyed.

Term aged-out open cascade: an open cascade whose intent stands aged out.

Term post-snapshot member: a grant, a session, OR a credential a constituent registered later than the snapshot.

Term rebuild: the composition's named regeneration of the suspension-state index — select the composition's own events over an open-ended sequence range and take each actor's latest lifecycle-bearing event.

Term miss: an index read the composition answers by the tail read rather than by the stored entry.

Term plan: the enumerated active set an intent carries — planned_grants, planned_sessions and planned_credentials.

Term revoked set: the members an outcome names closed — [Revoked Grants], [Revoked Sessions] and revoked_credentials.

Term open cascade: an intent carrying no outcome under the intent's own invocation id.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one invocation id at the seam PER state-changing invocation.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Capability requirement 4: The transition MUST NOT mint an invocation id.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Capability requirement 6: The composition MUST NOT accept an invocation id as an input.
Capability requirement 7: The composition MUST NOT mint a grant id.
Capability requirement 8: The composition MUST NOT mint a session token.
Capability requirement 9: The composition MUST NOT mint a credential id.
Capability requirement 10: The composition MUST NOT mint an event id.
Capability requirement 11: The composition MUST NOT generate cryptographic material.
Capability requirement 12: A deployment MUST declare the unified actor namespace.
Capability requirement 13: A deployment MUST NOT diverge the grant subject namespace from the actor namespace.
Capability requirement 14: A deployment MUST NOT diverge the session principal namespace from the actor namespace.
Capability requirement 15: A deployment MUST NOT diverge the credential principal namespace from the actor namespace.
Capability requirement 16: A deployment MUST declare the credential arm.
Capability requirement 17: A deployment MUST close the re-authentication surface outside the composition ONLY IF the credential arm stands uncomposed.
Capability requirement 18: A deployment MUST configure the audit instance with an audit retention policy.
Capability requirement 19: The composition MUST NOT configure the audit instance's retention policy PER call.
Capability requirement 20: The access retention floor MUST NOT EXCEED the audit horizon.
Capability requirement 21: A deployment MUST provision the service identity as a registered actor.
Capability requirement 22: A deployment MUST rotate the service identity's credential.
Capability requirement 23: A deployment MUST set the suspension completion bound.
Capability requirement 24: A deployment MUST set the completion window.
Capability requirement 25: A deployment MUST set the reconciliation cadence.
Capability requirement 26: A deployment MUST disclose the outcome write latency.
Capability requirement 27: A deployment MAY start an instance ONLY IF the completion window EXCEEDS the closure floor.
Capability requirement 28: A deployment MUST NOT start an instance carrying an undeclared suspension completion bound.
Deleted: Capability requirement 29. Execution Contract Database 2 owns it.
Deleted: Capability requirement 30. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 32. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 33. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 34. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Capability requirement 35. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for a deployment to lack.
Capability requirement 36: A deployment MUST set the planned set cap.
Capability requirement 37: The maximal outcome MUST NOT EXCEED the audit instance's payload cap.
Capability requirement 38: The deployment MUST declare the clock offset allowance.
Deleted: Capability requirement 39. Execution Contract Database 3 owns it.
Capability requirement 40: A deployment MUST gate an issuance on the suspension-state index.
Capability requirement 41: A deployment MUST refuse an issuance for a suspending actor.
Capability requirement 42: A deployment MUST refuse an issuance for a suspended actor.
Capability requirement 43: The composition MUST NOT gate an issuance.
Deleted: Capability requirement 44. Execution Contract Database 1 and Execution Contract Database 3 own it.
Capability requirement 45: A deployment MUST run the sweep PER reconciliation cadence.
Capability requirement 47: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
Deleted: Capability requirement 46. Execution Contract Logic confinement 7 owns it.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one invocation id here.
Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term unified actor namespace: unified_actor_namespace — the deployment's declaration that the actor reference this composition suspends is the same identity value under which the actor holds grants as subject reference, sessions as principal reference and credentials as Credential's own principal reference.

Term suspension completion bound: suspension_completion_bound — the deployment's declared maximum duration between an invocation's intent and the invocation's outcome, read against the seam-injected now the intent carries.

Term completion window: completion_window — the deployment's declared duration within which a suspending actor reaches suspended or escalates as an unresolved compliance finding.

Term closure floor: `((suspension_completion_bound + reconciliation_cadence) + outcome_write_latency)` — the longest interval in which the sweep can close an open cascade.

Term access retention floor: the longest retention obligation standing over the access a suspension closed — what audit_trail_retention_policy must outlast, so the proof the access was lawfully closed outlives the access.

Term planned set cap: planned_set_cap — the most members one suspension may plan.

Term maximal outcome: the largest record the act can write — the sweep's compensating outcome carrying a full planned set's revoked set, the unresolved members, the recovery marker, the operator, the plan-unavailable marker, the intent event id and the invocation id.

Term clock offset allowance: clock offset allowance — the declared envelope within which a stamp this composition wrote at its seam may be compared with a stamp a constituent wrote at its own.

### Primitive policy

```
Primitive policy 1: An action MUST call a constituent ONLY AFTER the boundary predicate.
Primitive policy 2: The boundary predicate MUST refuse a blank actor reference.
Primitive policy 3: The boundary predicate MUST refuse a blank operator reference.
Primitive policy 4: The boundary predicate MUST refuse a blank credential.
Primitive policy 5: The boundary predicate MUST refuse a blank reason.
Primitive policy 6: The composition MUST NOT normalize an opaque input.
Primitive policy 7: The composition MUST NOT fold an opaque input's case.
Primitive policy 8: The composition MUST NOT trim an opaque input.
Primitive policy 9: The composition MUST compare an opaque input by byte identity.
Primitive policy 10: An action MUST answer invalid-request for a boundary predicate refusal.
Primitive policy 11: The composition MUST propagate a constituent's invalid-request as invalid-request.
Primitive policy 12: The composition MUST carry the operator's reason into a constituent revocation.
Primitive policy 13: A resumed cascade's constituent revocation MUST carry the resume prefix AND the intent event id AND the operator's reason.
Primitive policy 14: A swept cascade's constituent revocation MUST carry the completion prefix AND the intent event id AND the operator's reason.
Primitive policy 15: The composition MUST NOT persist a credential.
Primitive policy 16: The composition MUST NOT inspect a credential.
Primitive policy 17: The composition MUST size the plan ONLY AFTER the snapshot.
Primitive policy 18: The composition MUST record an intent ONLY AFTER the plan sizing.
Primitive policy 19: IF the plan's member count EXCEEDS the planned set cap THEN [Suspend Actor] MUST answer invalid-request.
Primitive policy 20: The composition MUST alert on a plan exceeding the planned set cap.
Primitive policy 21: The composition MUST NOT digest the revoked set.
Primitive policy 22: The composition MUST carry the revoked set on an outcome in full.
```

NOTE: open 2026-10-26-b — the resume and completion prefixes and the intent event id lengthen the reason a resume or the sweep sends (Primitive policy 13, 14) past the one the boundary predicate admitted, so a constituent's length bound can refuse a resumed or swept revoke the fresh one passed, and the cascade stays suspending to its escalation.


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: actor reference | suspended by ref | reinstating actor ref | credential | grant id | session token | credential id.

Term operator reference: suspended by ref | reinstating actor ref.

Term resume prefix: `"suspension-resume:"` — what a resumed cascade's constituent reason opens with, so the constituent's own record traces to the plan.

Term completion prefix: `"suspension-completion:"` — what a swept cascade's constituent reason opens with.

### Identity

```
Identity 1: A state-changing invocation MUST carry an invocation id.
Identity 2: The seam MUST allocate an invocation id.
Identity 3: An invocation id MUST stand immutable.
Identity 4: The composition MUST NOT reuse an invocation id.
Identity 5: An intent MUST carry the invocation id.
Identity 6: An outcome MUST carry the intent's invocation id.
Identity 7: A resume intent MUST carry the cascade's invocation id.
Identity 8: A resume intent MUST carry the resuming call's own invocation id as resume invocation id.
Identity 9: A recovery intent MUST carry the cascade's invocation id.
Identity 10: The composition MUST pair an outcome to a cascade by the invocation id.
Identity 11: The composition MUST NOT pair an outcome to a cascade by a payload resemblance.
Identity 12: The composition MUST NOT pair an outcome to a cascade by the actor reference.
Identity 13: A resumed cascade MUST NOT record a second suspension intent.
Identity 14: A swept cascade MUST NOT record a second suspension intent.
Identity 15: EXACTLY ONE outcome MUST stand PER invocation id.
Identity 16: An intent MUST carry the injected now as intent instant.
Identity 17: An intent MUST carry the plan.
Identity 18: An intent MUST NOT carry a constituent-minted id the invocation has not read.
Identity 19: A suspension log entry MUST carry the invocation id.
Identity 20: A suspension-state entry MUST carry the invocation id.
```

Term invocation id: the id the seam allocates for one state-changing invocation; an intent and the outcome paired to it carry the same one (Identity 1 through 10).

Term resume invocation id: the resuming call's own invocation id, carried by a resume intent beside the cascade's (Identity 8).

Term intent instant: the instant an intent records (Identity 16).

Term intent event id: the event id the substrate answers for a cascade's intent (Composition state 6).

Term suspension event id: the event id the substrate answers for a suspended outcome (Composition state 7).

Term suspension instant: the instant a suspended outcome records (Action wiring 48).

Term reinstatement instant: the instant a reinstated outcome records (Action wiring 84).

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — `actor.suspension_intended` | `actor.resume_intended` | `actor.recovery_intended`.

Term outcome: the record_action call naming what an invocation did — `actor.suspended` | `actor.reinstated`.

Term committing call: `Permissions.revoke` | `Session.revoke` | `Credential.revoke` — a constituent call that writes outside the audit instance, and is irreversible once it commits.

### Audit arm

```
Audit arm 1: An invocation MUST make a committing call ONLY AFTER the invocation's landed intent.
Audit arm 2: An intent MUST verify the credential of the principal the invocation's revocations name.
Audit arm 3: IF Audit Trail answers invalid-credential at an intent THEN the action MUST answer invalid-credential carrying intent.
Audit arm 4: IF Audit Trail answers invalid-credential at an intent THEN the invocation MUST NOT make a committing call.
Audit arm 5: IF Audit Trail answers recording-failure at an intent THEN the action MUST answer recording-failure carrying intent.
NOTE: watch the retention step's recording failure (Audit arm 5).
Audit arm 6: IF Audit Trail answers recording-failure at an intent THEN the invocation MUST NOT make a committing call.
Deleted: Audit arm 7. Execution Contract Database 1 owns it.
Audit arm 8: IF the read-back finds the intent THEN the invocation MUST proceed on the intent as landed.
Deleted: Audit arm 9. Execution Contract Database 1 owns it.
Audit arm 10: IF Audit Trail answers invalid-request(step-4) at an intent THEN the invocation MUST read the intent back.
Audit arm 11: The composition MUST alert on a retention step answer.
Audit arm 12: The composition MUST NOT record a second intent for a read-back that found the intent.
Audit arm 13: The read-back MUST select an event by the tail read.
Audit arm 14: The read-back MUST select an event carrying the invocation's invocation id.
Audit arm 15: IF Audit Trail answers invalid-credential at an outcome THEN the action MUST answer invalid-credential carrying outcome.
Deleted: Audit arm 16. Execution Contract Database 1 owns it.
Audit arm 17: IF Audit Trail answers recording-failure at an outcome THEN the action MUST answer recording-failure carrying outcome.
NOTE: watch the retention step's recording failure (Audit arm 17).
Audit arm 18: IF Audit Trail answers invalid-request(step-4) at an outcome THEN the invocation MUST read the outcome back.
Audit arm 19: A caller MUST read an arm carrying intent as a committed nothing.
Audit arm 20: A caller MUST read an arm carrying outcome as a committed revocation.
Audit arm 21: A caller MUST NOT restart a cascade answering an arm carrying outcome.
Audit arm 22: A caller MAY resume an action answering an arm carrying outcome.
Audit arm 23: An invocation MUST NOT retry an owed outcome.
Audit arm 24: The sweep MUST own an owed outcome.
Audit arm 25: The composition MUST NOT retry an intent the read-back found.
Audit arm 26: The composition MUST read an invalid-request answer as a deployment fault.
Audit arm 27: The composition MUST NOT read an invalid-request answer as a transient fault.
Audit arm 28: The composition MUST alert on an owed outcome.
Audit arm 29: IF Audit Trail answers invalid-request carrying a step below step-4 at an intent THEN the action MUST answer recording-failure carrying intent.
Audit arm 30: IF Audit Trail answers invalid-request carrying a step below step-4 at an outcome THEN the action MUST answer recording-failure carrying outcome.
Audit arm 31: The composition MUST NOT retry an invalid-request answer carrying a step above step-2.
```

NOTE: open 2026-10-26-c — Audit arm 17 lands a recording failure at the outcome as recording-failure carrying outcome, which Audit arm 20 reads as a committed revocation, while an act whose write failed commits nothing (Execution Contract Database 1); the reading waits on whether a refused outcome leaves an act's other writes committed.

NOTE: open 2026-10-26-d — an act's attests read the registry inside its one transaction (Execution Contract Database 2), so a credential its intent verified cannot be rotated before its outcome's attest, and Audit arm 15's outcome position, with the example of a credential rotated mid-act, is unreachable.

Term landed intent: an intent the substrate has appended and attested, whatever the substrate then answered.

Term retention step: the substrate step whose invalid-request leaves the event appended and attested with only its retention placement failed — step-4 of Audit Trail's record_action.

Term read-back: the tail read filtered to an event of the invocation's own class carrying the invocation's invocation id, taken to decide whether a refused record_action left the event in the log.

Term owed outcome: an outcome this composition must write for a cascade whose revocations have committed and the substrate has not appended.

### Action wiring

```
suspend_actor(actor_ref, suspended_by_ref, credential, reason)
  answers suspension result
  refuses invalid-request | invalid-credential(position) | already-suspended | recording-failure(position)

suspension_report(actor_ref)
  answers suspension record
  refuses invalid-request

reinstate_actor(actor_ref, reinstated_by_ref, credential, reason)
  answers reinstatement result
  refuses invalid-request | invalid-credential | already-active(not-suspended state) | recording-failure
```

Term suspension result: suspended, revoked_grants, revoked_sessions, revoked_credentials, unresolved_members, event id and an optional resumed_by — what suspend_actor answers.

Term suspension record: state, an optional intent event id, an optional open_members, an optional suspension instant, an optional suspended by ref, an optional reason, an optional revoked_grants, an optional revoked_sessions, an optional revoked_credentials, an optional unresolved_members, an optional enumeration_availability and an optional suspension event id — what suspension_report answers.

Term reinstatement result: reinstated and event id — what reinstate_actor answers.

Term position: intent | outcome — the record a write lands: the intent or the outcome.

Term not-suspended state: active | suspending — the actor states a reinstatement refuses.

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Deleted: Action wiring 2. Execution Contract Database 2 owns it.
Deleted: Action wiring 3. Execution Contract Database 2 owns it.
Action wiring 4: The composition MUST run the tail read at the state gate.
Action wiring 5: IF the actor's lifecycle state EQUALS suspended THEN [Suspend Actor] MUST answer already-suspended.
Action wiring 6: IF the actor's lifecycle state EQUALS suspended THEN [Suspend Actor] MUST NOT revoke a member.
Action wiring 7: IF the actor's lifecycle state EQUALS suspended THEN [Suspend Actor] MUST NOT record an intent.
Action wiring 8: IF the actor's lifecycle state EQUALS suspending THEN [Suspend Actor] MUST resume the open cascade.
Action wiring 9: IF the actor's lifecycle state EQUALS active THEN [Suspend Actor] MUST open a fresh cascade.
Action wiring 10: A fresh cascade MUST snapshot the actor's grants through Permissions' declared read.
Action wiring 11: A fresh cascade MUST snapshot the actor's sessions through Session's declared read.
Action wiring 12: A fresh cascade MUST snapshot the actor's credentials through Credential's declared read ONLY IF the credential arm stands composed.
Action wiring 13: The snapshot MUST select a grant standing stored active.
Action wiring 14: The snapshot MUST select a session standing stored active.
Action wiring 15: The snapshot MUST NOT select a session by the session's derived status.
Action wiring 16: The snapshot MUST select a credential standing effective active.
Action wiring 17: The snapshot MUST select a credential PER credential type.
Action wiring 18: An empty snapshot MUST stand as a valid plan.
Action wiring 19: A fresh cascade MUST record a suspension intent carrying the plan.
Action wiring 20: A fresh cascade MUST write the suspending entry ONLY AFTER the landed intent.
Action wiring 21: A cascade MUST call the member's constituent revoke PER planned member standing open.
Deleted: Action wiring 22. Execution Contract Database 2 owns it.
Deleted: Action wiring 23. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to lose.
Deleted: Action wiring 24. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to find unavailable.
Action wiring 25: IF Permissions answers ok THEN the cascade MUST add the grant to the revoked set.
Action wiring 26: IF Permissions answers not-active THEN the cascade MUST add the grant to the revoked set.
Action wiring 27: IF Session answers revoked THEN the cascade MUST add the session to the revoked set.
Action wiring 28: IF Session answers already-terminal THEN the cascade MUST add the session to the revoked set.
Action wiring 29: IF Credential answers revoked THEN the cascade MUST add the credential to the revoked set.
Action wiring 30: IF Credential answers already-terminal THEN the cascade MUST add the credential to the revoked set.
Action wiring 31: A cascade MUST read a benign terminal answer as a closure.
Action wiring 32: A cascade MUST NOT read a benign terminal answer as a refusal.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Action wiring 34: IF a constituent answers not-known THEN the cascade MUST add the member to the unresolved members.
Deleted: Action wiring 35. Primitive policy 11 owns it: a credential Credential refuses as invalid-request still stands effective-active, so the act answers invalid-request and commits nothing (Invariant 1.3, Execution Contract Read 4).
Action wiring 36: A cascade MUST NOT add an unresolved member to the open members.
Action wiring 37: A non-benign refusal MUST NOT abort a cascade.
Action wiring 90: IF a constituent answers storage-failure THEN [Suspend Actor] MUST answer recording-failure carrying intent (Execution Contract Constituent failure 1).
Action wiring 38: A cascade MUST NOT reverse a committed revocation.
Action wiring 39: The composition MUST alert on an unresolved member.
Deleted: Action wiring 40. Execution Contract Database 1 owns it.
Deleted: Action wiring 41. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 1 owns it.
Deleted: Action wiring 43. Reconciliation 17 and Execution Contract Database 2 own it.
Deleted: Action wiring 44. Reconciliation 17 and Execution Contract Database 2 own it.
Action wiring 45: A cascade MUST record a suspended outcome ONLY AFTER the closed plan.
Deleted: Action wiring 46. Reconciliation 16 and Execution Contract Database 2 own it.
Deleted: Action wiring 47. Reconciliation 15 and Execution Contract Database 2 own it.
Action wiring 48: A suspended outcome MUST carry the invocation id, the intent event id, the suspended actor, the operator, the revoked set, the unresolved members, the reason AND the injected now as suspension instant.
Action wiring 49: A resumed cascade's outcome MUST carry the resumer, the resume event's id AND the recovery marker.
Action wiring 50: A swept cascade's outcome MUST carry the recovery marker.
Action wiring 51: A clean cascade's outcome MUST NOT carry the recovery marker.
Action wiring 52: A cascade MUST write the suspended entry ONLY AFTER the landed outcome.
Action wiring 53: The composition MUST append a suspension log entry PER [Suspend Actor] call.
Deleted: Action wiring 54. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section to release.
Action wiring 55: An admitted suspension MUST answer the revoked set, the unresolved members AND the outcome's event id.
Action wiring 56: A resume MUST compute the open members as the plan less the members the constituents show closed.
Action wiring 57: A resume MUST read a planned member by the member's own handle.
Action wiring 58: A resume MUST record a resume intent ONLY AFTER the open members.
Action wiring 59: A resume MUST revoke a member ONLY AFTER the landed resume intent.
Action wiring 60: A resume intent MUST carry the cascade's invocation id, the resume invocation's id, the intent event id, the suspended actor, the resumer, the open members AND the intent's reason.
Action wiring 61: A resume MUST NOT record a suspension intent.
Action wiring 62: A resumed cascade's constituent revocation MUST name the resumer as the revoker.
Action wiring 63: A resume MUST continue the cascade under the intent's invocation id.
Action wiring 64: The composition MUST read the suspension-state index at [Suspension Report].
Action wiring 65: The composition MUST run the tail read at [Suspension Report].
Action wiring 66: [Suspension Report] MUST NOT transition a lifecycle state.
Action wiring 67: [Suspension Report] MUST NOT write a constituent's records.
Action wiring 68: [Suspension Report] MUST NOT record an audit event.
Deleted: Action wiring 69. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for [Suspension Report] to take.
Action wiring 70: IF the actor's lifecycle state EQUALS active THEN [Suspension Report] MUST answer active.
Action wiring 71: IF the actor's lifecycle state EQUALS suspending THEN [Suspension Report] MUST answer the state, the intent event id, the operator, the reason AND the open members.
Action wiring 72: A suspending answer's open members MUST derive from the plan against the constituents' declared reads.
Action wiring 91: IF the intent stands aged out THEN a suspending answer's open members MUST derive from the actor's active members.
Action wiring 92: IF the intent stands aged out THEN a suspending answer MUST carry the enumeration availability as unavailable.
Action wiring 73: IF the actor's lifecycle state EQUALS suspended THEN [Suspension Report] MUST answer the state, the suspension instant, the operator, the reason, the suspension event id AND the revoked set.
Action wiring 74: The composition MUST read the revoked set from the outcome the suspension event id names at [Suspension Report].
Action wiring 75: IF the outcome stands aged out THEN [Suspension Report] MUST answer the enumeration availability as unavailable.
Action wiring 76: IF the outcome stands aged out THEN [Suspension Report] MUST NOT answer an empty revoked set.
Action wiring 77: IF the outcome stands aged out THEN [Suspension Report] MUST answer the state, the suspension instant, the operator AND the suspension event id from the suspension-state index.
Action wiring 78: The composition MUST read the suspension-state index at [Reinstate Actor].
Action wiring 79: The composition MUST run the tail read at [Reinstate Actor].
Action wiring 80: IF the actor's lifecycle state EQUALS active THEN [Reinstate Actor] MUST answer already-active carrying active.
Action wiring 81: IF the actor's lifecycle state EQUALS suspending THEN [Reinstate Actor] MUST answer already-active carrying suspending.
Action wiring 82: IF the actor's lifecycle state EQUALS suspending THEN [Reinstate Actor] MUST NOT record a reinstated outcome.
Action wiring 83: IF the actor's lifecycle state EQUALS suspended THEN [Reinstate Actor] MUST record a reinstated outcome.
Action wiring 84: A reinstated outcome MUST carry the invocation id, the reinstated actor, the reason AND the injected now as reinstatement instant.
Action wiring 85: An admitted reinstatement MUST write the active entry ONLY AFTER the landed reinstated outcome.
Action wiring 86: [Reinstate Actor] MUST NOT reverse a revocation.
Action wiring 87: [Reinstate Actor] MUST NOT issue a grant.
Action wiring 88: [Reinstate Actor] MUST NOT issue a session.
Action wiring 89: An admitted reinstatement MUST answer the reinstated outcome's event id.
```

Term stored active: the status a constituent's own record carries, before any derivation the constituent applies at read time.

Term effective active: Credential's derived active status, cited rather than restated — [Credential](../atoms/credential.md)'s own reading of a credential that has neither been revoked nor lapsed.

Term snapshot: the enumerated active set a fresh cascade reads from the constituents at one instant, which becomes the plan.

Term fresh cascade: a [Suspend Actor] call against an active actor — the call that records a suspension intent.

Term resume: a [Suspend Actor] call against a suspending actor — the call that records a resume intent and continues the open cascade.

Term cascade: a fresh cascade, a resume, OR the sweep's completion of an open cascade.

Term benign terminal answer: not-active from Permissions' revoke, OR already-terminal from Session's revoke or Credential's revoke — the answer naming a member another act already closed.

Term non-benign refusal: not-known from a constituent's revoke — the one refusal that leaves the act standing, since a constituent's storage-failure fails the whole act (Execution Contract Database 1, Action wiring 90) and its invalid-request answers as Primitive policy 11 says.

Term open members: the planned members a cascade left unclosed and a later cascade may still close.

Term unresolved members: the planned members no cascade can close, because the constituent no longer knows the member; the outcome names them in [Unresolved Members].

Term closed plan: a plan every member of which stands closed or unresolved.

Term recovery marker: cascade_recovery — the marker an outcome carries when a resume or the sweep completed the cascade, so a reader tells a completed act from a clean one.

Term enumeration availability: what [Suspension Report] answers where the audit instance has lawfully destroyed the record an enumeration derives from, a suspended actor's outcome or a suspending actor's intent — available | unavailable-past-horizon.

### Wiring decision

```
Wiring decision 1: The composition MUST close every authorization surface under one act.
Wiring decision 2: The composition MUST NOT reverse a cascade.
Wiring decision 3: The composition MUST complete a stopped cascade.
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
Wiring decision 5: The composition MUST NOT claim a rollback.
Wiring decision 6: The composition MUST open a fresh cascade ONLY IF the actor's lifecycle state EQUALS active.
Wiring decision 7: The composition MUST NOT open a second cascade for one actor.
Wiring decision 8: An outcome MUST carry the revoked set in full.
Wiring decision 9: The composition MUST NOT read a constituent's own revocation record as the act.
Wiring decision 10: The composition MUST NOT push the cascade into a constituent.
```

<details markdown="block">
<summary>WHY</summary>

*Principle:* an actor's ability to act is spread across two independent surfaces, each with its own multiplicity, so closing the actor out means closing both completely — and a partial close is dangerous exactly when it is invisible. *Likely objection:* why not let an administrator call `Permissions.revoke` per grant and `Session.revoke` per session directly, rather than wrapping them in one composition action? *Mechanism that resolves it:* independent revocation has no completeness guarantee and no record of incompleteness — an administrator who revokes the grants and forgets a session, or whose session step fails midway, leaves a half-open actor and nothing saying the closure was partial. This composition snapshots both surfaces, records the plan under a verified credential, revokes every enumerated member, and seals what it closed. *Result:* after a successful call the actor provably holds none of the planned access — the completeness no single constituent provides.

*Principle:* the suspension must be idempotent and its completeness must be provable. *Likely objection:* does recording the whole revoked set not duplicate what the constituent records already show, each revoked grant and session carrying its own revocation record? *Mechanism that resolves it:* the per-constituent records show *that* each member was revoked; only the composition knows they were revoked *as one act* and which set constituted the actor's access at suspension time — which is Wiring decision 9. The state gate makes the cascade start exactly once: a second call sees `Suspended` and refuses, or sees `Suspending` and resumes under the same intent. The plan is the second record the auditor reads, and the pair is what makes *complete* checkable rather than asserted: a member the plan named that the outcome accounts for nowhere is an owed closure. *Result:* the suspension is idempotent, its completeness is provable, and it rests on the substrate's seal, so a later attempt to shrink the recorded set to hide a missed surface breaks it.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The composition MUST run the sweep PER reconciliation cadence.
Reconciliation 3: The sweep's candidates MUST stand as the suspending entries taken with the open intents above the mark.
Reconciliation 4: The sweep MUST index every event the sweep reads above the mark.
Deleted: Reconciliation 5. Execution Contract Database 1 owns it.
Reconciliation 6: The sweep MUST advance the mark to the top of the range the sweep read.
Reconciliation 7: The sweep MUST hold the mark below an event the sweep did not index.
Deleted: Reconciliation 8. Execution Contract Database 1 owns it.
Reconciliation 9: The sweep MUST NOT read an aged-out intent's plan.
Deleted: Reconciliation 10. Execution Contract Database 2 owns it.
Deleted: Reconciliation 11. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no critical section for another holder to hold.
Deleted: Reconciliation 12. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, so the sweep skips no candidate.
Deleted: Reconciliation 13. Execution Contract Database 2 owns it.
Deleted: Reconciliation 14. Execution Contract Database 2 owns it.
Reconciliation 15: IF the pre-check finds an outcome THEN the sweep MUST NOT record an outcome.
Reconciliation 16: IF the pre-check finds an outcome THEN the sweep MUST write the suspended entry.
Reconciliation 17: IF the pre-check finds no outcome THEN the sweep MUST record a recovery intent ONLY AFTER the pre-check.
Reconciliation 18: The sweep MUST revoke a member ONLY AFTER the landed recovery intent.
Reconciliation 19: A recovery intent MUST carry the cascade's invocation id, the intent event id, the suspended actor AND the members the sweep opens.
Reconciliation 20: The sweep MUST attest a record under the service identity.
Reconciliation 21: The sweep MUST name the service identity as the revoker.
Reconciliation 22: The sweep MUST name the operator on the outcome.
Reconciliation 23: The sweep MUST derive the revoked set from the plan AND the constituents' declared reads.
Deleted: Reconciliation 24. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 25: IF the intent stands aged out THEN a cascade MUST snapshot the actor's active members.
Reconciliation 26: IF the intent stands aged out THEN a cascade's outcome MUST carry the plan-unavailable marker.
Reconciliation 27: The sweep MUST NOT close an unresolved member.
Reconciliation 28: The sweep MUST close an open cascade WITHIN the completion window.
Reconciliation 29: The sweep MUST escalate an open cascade outside the completion window.
Deleted: Reconciliation 30. Execution Contract Database 2 owns it.
Reconciliation 31: The sweep MUST answer nothing to a caller.
Reconciliation 32: A caller MUST NOT invoke the sweep.
```

Term sweep: the completion leg the Reconciliation rules state — this composition's own, over its open cascades.

Term pre-check: the read of the trail for an outcome already carrying a cascade's invocation id, taken before any outcome is appended.

Term plan-unavailable marker: plan_unavailable — the marker a cascade's outcome carries when the intent aged out and the cascade completed from the constituents rather than from a plan it could read.

---

## Composition-level invariants

```
Invariant 1.1: A suspended actor MUST hold no stored-active grant from the plan.
Invariant 1.2: A suspended actor MUST hold no stored-active session from the plan.
Invariant 1.3: A suspended actor MUST hold no effective-active credential from the plan ONLY IF the credential arm stands composed.
Invariant 1.4: An outcome MUST stand later in the log than every revocation the outcome names.
Invariant 1.5: A stopped cascade's actor MUST stand suspending.
Invariant 1.6: A stopped cascade's actor MUST NOT stand active.
Invariant 1.7: A stopped cascade's actor MUST NOT stand suspended.
Invariant 1.8: A suspending actor MUST reach suspended WITHIN the completion window.
Invariant 1.9: A suspending actor outside the completion window MUST stand as an escalated finding.
Invariant 1.10: EXACTLY ONE writer MUST close one cascade.
Invariant 1.11: The composition MUST NOT claim a stopped cascade leaves the actor unchanged.
Invariant 1.12: The composition MUST NOT claim coverage of a post-snapshot member.
Invariant 2.1: An admitted suspension MUST produce EXACTLY ONE suspended outcome.
Invariant 2.2: A suspended outcome MUST name every revoked grant.
Invariant 2.3: A suspended outcome MUST name every revoked session.
Invariant 2.4: A suspended outcome MUST name every revoked credential ONLY IF the credential arm stands composed.
Invariant 2.5: A suspended outcome MUST name every unresolved member.
Invariant 2.6: A suspended outcome MUST stand under a seal PER Audit Trail's seal cadence.
Invariant 2.7: A suspended outcome MUST name the outcome's intent.
Invariant 2.8: EVERY planned member MUST stand accounted.
Invariant 2.9: EVERY revoked set member MUST stand in the plan.
Invariant 3.1: A [Suspend Actor] call against a suspended actor MUST change no lifecycle state.
Invariant 3.2: A [Suspend Actor] call against a suspended actor MUST NOT revoke a member.
Invariant 3.3: A [Suspend Actor] call against a suspending actor MUST resume the open cascade.
Invariant 3.4: A lifecycle state MUST stand monotonic on the suspend edge.
Invariant 3.5: The composition MUST reverse a lifecycle state ONLY through [Reinstate Actor].
Invariant 3.6: A cascade MUST count a benign terminal member toward the closure.
Invariant 4.1: EVERY Permissions invariant MUST hold over the grant records.
Invariant 4.2: EVERY Session invariant MUST hold over the session records.
Invariant 4.3: EVERY Actor Identity invariant MUST hold over the attestation records.
Invariant 4.4: EVERY Audit Trail invariant MUST hold over the audit instance.
Invariant 4.5: EVERY Credential invariant MUST hold over the credential records ONLY IF the credential arm stands composed.
Invariant 4.6: The composition MUST NOT weaken a constituent invariant.
Invariant 4.7: The composition MUST NOT count a constituent's invariants.
Invariant 5.1: The composition MUST NOT commit a revocation under an unvalidated credential.
Invariant 5.2: A revocation's named revoker MUST stand validated by a record in the trail.
Invariant 5.3: A fresh cascade MUST validate the operator's credential at the suspension intent.
Invariant 5.4: A resume MUST validate the resumer's credential at the resume intent.
Invariant 5.5: The sweep MUST validate the service identity's credential at the recovery intent.
Invariant 5.6: An admitted reinstatement MUST validate the credential at the reinstated outcome.
Invariant 5.7: A credential validation MUST NOT establish the presenter's identity.
Invariant 5.8: A credential validation MUST NOT establish a channel binding.
Invariant 5.9: A credential validation MUST NOT establish an authorization.
```

Term admitted suspension: a [Suspend Actor] call whose boundary predicate passed, whose actor's lifecycle state DOES NOT EQUAL suspended, and whose intent landed.

Term admitted reinstatement: a [Reinstate Actor] call whose boundary predicate passed and whose actor's lifecycle state EQUALS suspended.

Term accounted cascade: an open cascade standing suspending with the open members named, closed within the completion window, OR named by an escalated finding.

Term accounted member: a planned member standing in the revoked set, standing in the unresolved members, OR standing terminal in the constituent's records before the outcome.

Term escalated finding: an open cascade the composition has raised to the deployment as unresolved, past the point where the sweep's own closure was owed.

---

## Examples

### Walkthrough — offboarding a departing employee, end to end

A bank deploys the composition over its access surfaces with the actor namespace unified through Authenticated Actor, `completion_window = 15m`, `suspension_completion_bound = 5m`, `reconciliation_cadence = 5m` and `outcome_write_latency = 30s` — five plus five plus a half is strictly under fifteen, so the instance-start check passes — `planned_set_cap = 500`, the credential arm composed, and the substrate holding a seven-year audit policy.

1. **Trigger.** An employee resigns; the human-resources offboarding workflow calls `suspend_actor(actor_ref = "emp_4821", suspended_by_ref = "hr_offboard_svc", credential = <svc-cred>, reason = "employment-ended-2026-06-10")`.
2. **State gate.** The index entry for `emp_4821` is absent, and the tail read above the mark finds no suspension intent → active → a fresh cascade.
3. **Snapshot and sizing.** Permissions yields three stored-active grants (`g_finread`, `g_wireinit`, `g_reports`); Session yields two stored-active sessions (`tok_laptop`, `tok_phone`); Credential yields two effective-active credentials across two types — a password `cred_pw` and a hardware key `cred_key`. Seven members, under the cap.
4. **Intent.** `actor.suspension_intended` lands under `<svc-cred>` carrying the plan and the invocation's id — the service credential is verified *here*, before anything is revoked (Invariant 5.3) — and the suspending entry is written after it.
5. **Cascade.** Three `Permissions.revoke` calls answer `ok`; two `Session.revoke` calls answer `revoked`; two `Credential.revoke` calls answer `revoked`. Had only the password been revoked, the hardware key would still authenticate — which is why the enumeration is per type.
6. **Outcome.** `actor.suspended` lands carrying the invocation's id, the intent's id, the operator, the full revoked set, an empty unresolved set and the reason; the suspended entry is written after it.
7. **Result.** The call answers the revoked set and the event id. `emp_4821` holds none of the planned access: `Permissions.permitted` answers denied, `Session.validate` answers invalid, and neither credential re-authenticates.

### Domain example — compromised account, a cascade that stops and is completed

A security team suspends a compromised account: `suspend_actor("svc_8830", "soc_analyst_k", <cred>, "credential-in-paste-dump")`. The snapshot finds five grants and one long-lived session; the intent lands with that plan and all six revocations commit. Then the outcome's record_action is refused: the audit instance's Event Log was wired with a payload cap below the substrate's own, a deployment fault, so its append answers invalid-payload, the substrate answers invalid-request carrying step-3, and the call answers `recording-failure(outcome)`. **Nothing is undone:** the six committed revocations are terminal and stand, and the log records the failure — its [Outcome] an outcome recording failure. The account is closed and the record of it is owed: [Suspension Report] answers suspending, and the issuance gate refuses new access.

The deployment rewires the cap and the Security Operations Center (SOC) retries. The state gate finds suspending, so this is a **resume**: `actor.resume_intended` lands under the analyst's credential — the analyst is verified here, not the original service actor — and `actor.suspended` lands with resumed_by, the resume event's id and the recovery marker. Had nobody retried, the sweep would have done the same within the window under the service identity behind an `actor.recovery_intended` record. Either way the outcome says the cascade was completed and by whom.

### Rejection path — already suspended, and the benign race

- **Already suspended.** A retry of the offboarding call finds `Suspended` at the gate → already-suspended: no second cascade, no second revoke, no second outcome.
- **Benign time-of-check-to-time-of-use race.** While the cascade runs, the employee's laptop fires its own logout. The cascade's `Session.revoke(tok_laptop)` then answers already-terminal — the session is terminal, which *is* the cascade's goal — so the member is counted in the revoked set and the cascade does not abort.
- **A lapsed session in the plan.** `tok_phone` lapsed an hour before the suspension: it is stored-active, so it enters the plan, and Session's revoke accepts a lapsed session like any other whose status is active, standing it revoked and answering revoked, so it is counted in the revoked set. Enumerating by derived status instead would have dropped it from the plan, and the record of what the suspension set out to close would have been quietly short by one.

### Failure path — a member the database no longer knows

A planned grant answers `not-known` — a database inconsistency, since Permissions never deletes. The member joins the **unresolved** members rather than the open ones: no later cascade can close a handle the constituent has lost, and leaving it open would hold the actor in `Suspending` forever while the acceptance check demanded a closure nobody could make. The cascade finishes its remaining members, the outcome lands naming the unresolved member, the actor reaches `Suspended`, and the composition raises the inconsistency as a finding. An auditor reads the member as accounted for — named, not closed — which is the true state of it.

### Failure path — a credential rotated mid-act

An operator's credential is rotated between the intent and the outcome. The outcome write answers invalid-credential, and the call answers `invalid-credential(outcome)`: the revocations **stand**, this credential no longer attests, and the outcome is not this caller's to write. The caller does not re-run — a re-run under the same rotated credential would refuse again, which is the loop the un-positioned arm used to invite. A resume under a different verified operator closes it, and the sweep closes it otherwise.

### Failure path — the intent appended and the call still failed

The intent's record_action answers invalid-request naming the substrate's retention step: the event is appended and attested — so the credential *was* verified — and the call still failed. The invocation reads the trail back for an intent carrying its own invocation id, finds it, and proceeds on it as landed with a hard alert on the retention configuration. It does **not** re-record: a second intent would be a second plan for one actor, which the sweep would pair twice and complete twice.

### Regulated adversarial scenarios

**Regulator audit — prove this terminated employee's access was fully and promptly removed.** A Sarbanes-Oxley (SOX) auditor examines `emp_4821`. [Suspension Report] answers suspended with the instant, the operator and the enumerated revoked set. The auditor reads the sealed outcome event, confirms through `AuditTrail.verify_record` that the enumeration was not altered, and for each named member confirms the constituent's own records show it revoked at suspension time — both credentials included, so no type re-authenticates. Invariant 1 is the structural answer and the examiner consults no source code.

**Disputed action — this employee could not have done that; we suspended them.** An action attributed to `emp_4821` post-dates the suspension. The investigator reads the outcome: every planned member was closed before it was appended. If the action used a session, `Session.validate` answers invalid with a revocation instant at suspension time; if it used a grant, `Permissions.permitted` answers denied. The only way the action can post-date the suspension is access *issued after the snapshot* — which the issuance records show, and which is the named snapshot-scoped gap rather than a defect here.

**Breach investigation — was any suspended actor's access incompletely closed during the incident?** The investigator walks the outcome events in the window and, for each, cross-checks that every named member is terminal in its constituent's records and that no stored-active member for that actor exists outside the accounted set as of the suspension instant. A half-closed actor is a `Suspending` one and the investigator reads it directly — the plan against the constituents and, once completed, the recovery marker on the outcome: the honest record of a surface that did not close on the first pass and of when it did. Because the enumeration sits in the sealed payload, shrinking it to hide a missed surface breaks the seal.

---

## Generation acceptance

A derived implementation is *acceptable* — in the regulator-acceptance sense — when every check below is provable to an external auditor given the composition's indexes plus the Permissions, Session, Credential and Audit Trail records. Every selection is made composition-side over the declared open-ended sequence range, never by asking the substrate for a payload predicate it does not serve. **A standing rule for every cross-seam comparison:** where a check compares a stamp this composition wrote at its seam with one a constituent wrote at its own, it runs under the clock offset allowance, and a member falling inside the allowance is reported *inconclusive by skew*, never as a pass and never as a failure.

### Conformance checks

```
Check 1.1: An auditor MUST find no stored-active planned grant PER suspended actor (Invariant 1.1).
Check 1.2: An auditor MUST find no stored-active planned session PER suspended actor (Invariant 1.2).
Check 1.3: An auditor MUST find no effective-active planned credential PER suspended actor (Invariant 1.3).
Check 1.4: An auditor MUST read a post-snapshot member as outside the plan (Invariant 1.12).
Check 1.5: An auditor MUST read a suspended actor carrying a stored-active planned member as a conformance failure (Invariant 1.1).
Check 1.6: An auditor MUST take an aged-out actor's lifecycle state from the suspension-state index (Composition state 10).
Check 2.1: An auditor MUST find EXACTLY ONE suspended outcome PER suspension event id (Invariant 2.1).
Check 2.2: An auditor MUST confirm Audit Trail's verify_record answers verified for the outcome (Invariant 2.6).
Check 2.3: An auditor MUST find the outcome's intent earlier in the log under the same invocation id (Invariant 2.7).
Check 2.4: An auditor MUST compare the outcome's revoked set against the intent's plan PER member (Invariant 2.8).
Check 2.5: An auditor MUST read a planned member the outcome names unresolved as accounted (Invariant 2.5).
Check 2.6: An auditor MUST read a planned member the outcome accounts for nowhere as an owed closure (Invariant 2.8).
Check 2.7: An auditor MUST read a revoked set member the plan does not name as a conformance failure (Invariant 2.9).
Check 2.8: An auditor MUST find a revoked record PER revoked set member (Invariant 2.2).
Check 2.9: An auditor MUST read a failed-verification carrying purged as a lawful destruction (Composition state 14).
Check 2.10: An auditor MUST read an aged-out outcome's enumeration as unavailable (Composition state 14).
Check 2.11: An auditor MUST NOT read an aged-out outcome's enumeration as a conformance failure (Composition state 14).
Check 3.1: An auditor MUST find no second suspension intent PER cascade (Identity 13).
Check 3.2: An auditor MUST compare the suspension-state index against the rebuild (Composition state 32).
Deleted: Check 3.3. Execution Contract Database 3 and Execution Contract Database 4 own it.
Check 3.4: An auditor MUST find a lifecycle transition bound to a landed record PER transition (Composition state 41).
Check 3.5: An auditor MUST read a suspension log refusal entry as evidence of a refusal (Composition state 15).
Check 3.6: An auditor MUST NOT read a suspension log refusal entry as evidence of an act (Composition state 15).
Check 3.7: An auditor MUST find an already-suspended log entry carrying no second outcome PER repeated suspension (Invariant 3.1).
Check 4.1: An auditor MUST find a non-empty reason PER suspended outcome (Primitive policy 5).
Check 4.2: An auditor MUST confirm a suspended outcome's named operator matches the intent's attested actor (Reconciliation 22).
Check 4.3: An auditor MUST confirm a clean outcome's attesting actor matches the intent's attested actor (Invariant 5.3).
Check 4.4: An auditor MUST find a resume intent attested under the resumer earlier in the log PER resumed outcome (Invariant 5.4).
Check 4.5: An auditor MUST find a recovery intent attested under the service identity earlier in the log PER swept outcome (Invariant 5.5).
Check 4.6: An auditor MUST confirm a revoked record's named revoker matches the writer that closed the member (Invariant 5.2).
Check 4.7: An auditor MUST read an outcome attested outside the operator, the resumer AND the service identity as a conformance failure (Invariant 5.2).
Check 4.8: An auditor MUST confirm a resumed revocation's reason carries the resume prefix AND the intent event id (Primitive policy 13).
Check 4.9: An auditor MUST confirm a swept revocation's reason carries the completion prefix AND the intent event id (Primitive policy 14).
Check 5.1: An auditor MUST clear Permissions' conformance checks over the grant records (Invariant 4.1).
Check 5.2: An auditor MUST clear Session's conformance checks over the session records (Invariant 4.2).
Check 5.3: An auditor MUST clear Actor Identity's conformance checks over the attestation records (Invariant 4.3).
Check 5.4: An auditor MUST clear Audit Trail's conformance checks over the audit instance (Invariant 4.4).
Check 5.5: An auditor MUST clear Credential's conformance checks over the credential records (Invariant 4.5).
Check 5.6: An auditor MUST NOT count a constituent's conformance checks (Invariant 4.7).
Check 6.1: An auditor MUST find the record that verified a revoker earlier in the log than every revocation the revoker made (Invariant 5.2).
Check 6.2: An auditor MUST find EXACTLY ONE suspended outcome PER invocation id (Invariant 1.10).
Check 6.3: An auditor MUST read a second outcome under one invocation id as a second writer (Invariant 1.10).
Check 6.4: An auditor MUST confirm the completion window, the suspension completion bound, the reconciliation cadence AND the outcome write latency stand declared (Capability requirement 24).
Check 6.5: An auditor MUST confirm the completion window EXCEEDS the closure floor (Capability requirement 27).
Check 6.6: An auditor MUST NOT confirm the closure floor's terms severally (Capability requirement 27).
Check 6.7: An auditor MUST find an accounted cascade PER open cascade (Invariant 1.8).
Check 6.8: An auditor MUST read an open cascade standing outside an accounted cascade as a conformance failure (Invariant 1.8).
Deleted: Check 6.9. Execution Contract Database 1 owns it.
Check 6.10: An auditor MUST take an aged-out open cascade from the suspension-state index (Reconciliation 9).
```

### External checks

```
External check 1: The deployment MUST establish that the grant subject namespace coincides with the actor namespace (Capability requirement 13).
External check 2: The deployment MUST establish that the session principal namespace coincides with the actor namespace (Capability requirement 14).
External check 3: The deployment MUST establish that the credential principal namespace coincides with the actor namespace (Capability requirement 15).
External check 4: The deployment MUST establish that the issuance layer gates on the suspension-state index (Capability requirement 40).
External check 5: The deployment MUST establish the operator's authorization to suspend the actor (Invariant 5.9).
External check 6: The deployment MUST establish that the re-authentication surface stands closed ONLY IF the credential arm stands uncomposed (Capability requirement 17).
Deleted: External check 7. Execution Contract Database 2 owns it.
Deleted: External check 8. Execution Contract Database 2 owns it.
Deleted: External check 9. Execution Contract Database 3 owns it.
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT issue a grant.
Non-goal 2: The composition MUST NOT issue a session.
Non-goal 3: The composition MUST NOT issue a credential.
Non-goal 4: The composition MUST NOT provision an actor identity.
Non-goal 5: The composition MUST NOT decide whether an actor warrants suspension.
Non-goal 6: The composition MUST NOT gate the operator's authorization.
Non-goal 7: The composition MUST NOT restore a revoked grant.
Non-goal 8: The composition MUST NOT restore a revoked session.
Non-goal 9: The composition MUST NOT restore a revoked credential.
Non-goal 10: The composition MUST NOT deactivate an attestation registry entry.
Non-goal 11: The composition MUST NOT own the actor lifecycle as an atom.
Non-goal 12: The composition MUST NOT own a refusal record as an atom.
Non-goal 13: The composition MUST NOT verify the actor namespace's unification.
Non-goal 14: The composition MUST NOT index the audit log by a payload field.
Non-goal 15: The composition MUST NOT anchor a timestamp to wall time.
Non-goal 16: The composition MUST NOT log a read of a suspension report.
Non-goal 17: The composition MUST NOT deduplicate a retried call.
Non-goal 18: The composition MUST NOT revoke a member set through one constituent call.
Non-goal 19: The composition MUST NOT detect a dishonest clock reading.
```

NOTE: the owners — the issuance layer (Non-goal 1 through 3, Capability requirement 40, External check 4; Non-goal 7 through 9); a composing Permissions layer scoped to suspension authority (Non-goal 6, External check 5); Actor Registry *(forthcoming)*, or [Authenticated Actor](./authenticated-actor.md)'s own cascade (Non-goal 10); Actor Registry *(forthcoming)* (Non-goal 11, Composition state 11); Failed-Attempt Log *(forthcoming)* (Non-goal 12, Composition state 16); the deployment (Non-goal 17).

---

## Edge cases

### Atomic writes

```
Atomic writes 1: An invocation MUST record an outcome ONLY AFTER the invocation's committing calls.
Atomic writes 2: An invocation MUST populate an index ONLY AFTER the invocation's landed record.
Atomic writes 3: The composition MUST NOT reverse a committed constituent write.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
Deleted: Atomic writes 8. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
Atomic writes 10: The composition MUST surface an orphan.
Atomic writes 11: A deployment MUST treat an orphan as an alerting condition.
Atomic writes 12: The composition MUST NOT repair an orphan by fabrication.
```

Term orphan: a committed revocation carrying an owed outcome, or an open cascade carrying no record of why it stopped.

### Clock semantics

```
Clock semantics 6: A reader MUST read the substrate's insertion order as the authoritative order.
Deleted: Clock semantics 2. Identity 16, Action wiring 48 and Action wiring 84 own it: intent instant, suspension instant and reinstatement instant are every timestamp this composition stamps, and each takes the injected now.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 3 owns it.
Clock semantics 7: A reader MUST read a stamp this composition wrote as advisory.
Deleted: Clock semantics 8. Composes 31 owns it.
Clock semantics 9: The composition MUST NOT compare a constituent's stamp against a write.
Clock semantics 10: A check comparing two seams' stamps MUST run under the clock offset allowance.
Clock semantics 11: A check comparing two seams' stamps MUST answer inconclusive inside the clock offset allowance.
Clock semantics 12: The sweep MUST compare an intent's stamp against the sweep's own clock reading.
Deleted: Clock semantics 13. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 14. Non-goal 19 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Concurrency 6: A cascade MUST count a concurrent terminal transition as a closure.
Concurrency 7: The composition MUST NOT abort a cascade on a concurrent terminal transition.
Concurrency 8: A concurrent issuance MUST stand outside the plan.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: an action's reads of an actor's state and the writes they decide are one transaction, and the composition names no serialization obligation for [Suspension Report] to stand outside.
```

---

## Composition notes

These are adjacent patterns, **not** constituents of Actor Suspension:

- **[Login](./login.md)** — the inbound mirror. Login wires `Credential.verify → Session.issue`; this composition wires the outbound close. The symmetry is load-bearing and the difference is deliberate: Login's cascade is best-effort because partial revocation beats none, and this composition's is completed because a half-closed actor is dangerous exactly when it is invisible.
- **[Authenticated Actor](./authenticated-actor.md)** — the pattern that establishes the `principal_ref ↔ actor_ref` binding this composition's enumeration depends on. A deployment satisfies the unified actor namespace through it or by convention; either way the coincidence is External check 1 through 3.
- **Actor Registry** *(forthcoming)* — the atom Actor Identity names as the home of actor registration, deactivation and suspension. The lifecycle this composition introduces is extraction-pending against it (Composition state 10).
- **Failed-Attempt Log** *(forthcoming)* — the pattern the substrate names for attempted-but-not-committed actions. The suspension log's refusal entries are extraction-pending against it (Composition state 15).
- **Multi-Party Approval** — the gate a deployment wires ahead of [Suspend Actor] where a suspension is high-stakes enough to need more than one authorizer. This composition decides nothing about *whether* to suspend (Non-goal 5).

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind**, the Type it is a **Member of** or **Field of**, the Operation it is a **Parameter of**, its **Role** where the domain assigns one, and one **Projection** line — the concept's single canonical lowering token. Everything else about casing is derived from that token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. The composition's own concepts are the three actions it exposes, the enumerations its outcome carries, the suspension log's classification, and its own rejections. The actor lifecycle states are left uncarded because *active* is pervasively overloaded with the constituents' own grant and session statuses; the emergent records, the `actor.*` event classes, the constituent calls and their answers, the relayed tokens and the deployment knobs stay backticked as wire values.

### Vocabulary

Term actors: the composition; a deployment; the host; the seam; the transition; the sweep; a caller; an auditor; a reader; a writer; an implementation; an invocation; an action; a call; a cascade; a fresh cascade; a resume; a stopped cascade; a clean cascade; a resumed cascade; a swept cascade; an open cascade; an intent; a resume intent; a recovery intent; an outcome; a suspended outcome; a reinstated outcome; a record; a landed record; a landed intent; an owed outcome; a read-back; a pre-check; the tail read; the rebuild; an index; the suspension-state index; the high-water mark; the suspension log; a log entry; a mirrored log entry; a refusal log entry; an actor; a suspended actor; a suspending actor; an active actor; a lifecycle state; the state gate; an operator; a resumer; the service identity; a principal; a credential; a credential validation; a revoker; a member; a planned member; an unresolved member; an accounted member; a grant; a session; a plan; a revoked set; a snapshot; a closed plan; a constituent; a committing call; a benign terminal answer; a non-benign refusal; an orphan; an escalated finding; a miss; an aged-out event; the audit horizon; the completion window; the closure floor; the suspension completion bound; the access retention floor; the planned set cap; the maximal outcome; the clock offset allowance; the unified actor namespace; the credential arm; an issuance; an activity; Permissions; Session; Credential; Actor Identity; Audit Trail; Event Log; the audit instance; a surface; a timestamp; insertion order; a clock reading; a payload field.

Term record verbs: serve, change, inherit, read, hold, reach, call, select, query, attest, own, place, admit, drive, know, push, store, classify, carry, stand, claim, populate, name, alert, drop, take, rebuild, recognize, supply, mint, generate, accept, configure, set, provision, rotate, disclose, start, run, fire, resolve, reconcile, refuse, normalize, fold, trim, compare, judge, propagate, cap, truncate, allocate, reuse, pair, make, retry, leave, record, answer, substitute, add, complete, clear, empty, write, advance, repoint, renew, cross, find, confirm, reproduce, establish, match, escalate, close, emit, expose, validate, commit, detect, inject, stamp, derive, deduplicate, model, schedule, adjudicate, purge, unwind, gate, index, anchor, surface, treat, sweep, spend, enroll, verify, suspend, reinstate, belong, elapse, invoke, duplicate, block, govern, identify, decide, reverse, destroy, revoke, snapshot, size, yield, count, abort, log, prove, weaken, lapse, deactivate, restore, issue, terminate, enumerate, declare, diverge, persist, inspect, digest, proceed, open, continue, append, compute, transition, produce, sample, repair, resume, restart.

Term records: empty.

Term bounds: suspension completion bound (suspension_completion_bound), completion window (completion_window), outcome write latency (outcome_write_latency), closure floor, audit horizon (audit_trail_retention_policy), access retention floor, planned set cap (planned_set_cap), clock offset allowance, maximal outcome.

Term cadences: reconciliation cadence, seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.41 (2026-09-15).

Term value sets: lifecycle state = active | suspending | suspended. intent = actor.suspension_intended | actor.resume_intended | actor.recovery_intended. outcome = actor.suspended | actor.reinstated. enumeration availability = available | unavailable-past-horizon. already-active reason = active | suspending. benign terminal answer = not-active | already-terminal.

Term terms: composition, constituents, credential arm, service identity, operator, resumer, suspension-state index, high-water mark, suspension log, mirrored log entry, refusal log entry, tail read, audit horizon, aged-out event, rebuild, miss, aged-out entry, aged-out log entry, aged-out actor, aged-out outcome, aged-out open cascade, post-snapshot member, admitted suspension, admitted reinstatement, plan, revoked set, open cascade, seam, transition, unified actor namespace, suspension completion bound, completion window, closure floor, access retention floor, planned set cap, maximal outcome, clock offset allowance, blank, boundary predicate, opaque input, operator reference, resume prefix, completion prefix, intent, outcome, committing call, landed intent, retention step, read-back, owed outcome, stored active, effective active, snapshot, fresh cascade, resume, cascade, benign terminal answer, non-benign refusal, open members, unresolved members, closed plan, recovery marker, enumeration availability, sweep, pre-check, plan-unavailable marker, accounted cascade, accounted member, escalated finding, orphan, position, not-suspended state, suspension result, suspension record, reinstatement result, invocation id, resume invocation id, intent instant, intent event id, suspension event id, suspension instant, reinstatement instant.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. [Credential](../atoms/credential.md) — the effective-active reading and the per-pair bound. verify_record, event id: Audit Trail.

Term composing patterns: Actor Registry *(forthcoming)*; Failed-Attempt Log *(forthcoming)*; Reverse Index *(forthcoming)*; Trusted Timestamping *(forthcoming)*; [Login](./login.md); [Authenticated Actor](./authenticated-actor.md); [Multi-Party Approval](./multi-party-approval.md); [Permissions](../atoms/permissions.md).

#### Suspend Actor

The composition's load-bearing emergent action: it snapshots every stored-active grant and session the actor holds — and, where the credential arm stands composed, every effective-active credential across every type — sizes the plan against the cap, records the plan under the operator's verified credential, revokes each member, seals the complete revoked set into one attributed event, and moves the actor from active through suspending to suspended. Against an already-suspended actor it is a no-op; against a suspending one it **resumes** the open cascade under its own attested resume record. Neither constituent carries this multi-surface cascade, and neither could: neither can see the other's surface.

Kind: Operation

#### Suspension Report

The composition's read-only query: resolves the actor's lifecycle state under the miss rule and answers *active*, or *suspending* with the open members re-derived from the plan against the live constituents, or *suspended* with the instant, the operator, the reason and the enumerated revoked set read from the sealed outcome. Past the audit horizon the enumeration is reported unavailable rather than empty. Changes no lifecycle state and records no audit event; this is the surface the issuance layer gates new access on.

Kind: Operation

#### Reinstate Actor

The composition's thin lifecycle reversal: moves a suspended actor back to active and records an attributed reinstatement. It does **not** restore any revoked grant, session or credential — those are terminal in their constituents — so re-authorizing a reinstated actor means issuing fresh access through the issuance layer. A suspending actor is refused: its cascade is completed first, then lifted.

Kind: Operation

#### Revoked Grants

The set of grant handles the cascade closed, carried in the sealed outcome's payload (Invariant 2.2). Its completeness — every planned grant accounted for, no surface omitted — is what makes the suspension provable from one tamper-evident record.

Kind:       Field
Field of:   the suspension outcome
Role:       the revoked grant enumeration
Projection: revoked_grants

#### Revoked Sessions

The set of session handles the cascade closed, carried in the sealed outcome's payload (Invariant 2.3). Together with [Revoked Grants] and, where the credential arm stands composed, the revoked credentials, it is the complete sealed record of everything the suspension closed.

Kind:       Field
Field of:   the suspension outcome
Role:       the revoked session enumeration
Projection: revoked_sessions

#### Unresolved Members

The set of planned members no cascade can close, because the constituent no longer knows the handle. Carried on the outcome (Invariant 2.5) so the act can complete honestly: such a member is **accounted for by being named**, not by being closed, and the sweep does not chase it. Without this field a single lost handle held the actor in suspending forever while the completeness check demanded a closure nobody could make.

Kind:       Field
Field of:   the suspension outcome
Role:       the unclosable-member enumeration
Projection: unresolved_members

#### Outcome

The suspension log entry's classification of a [Suspend Actor] or [Reinstate Actor] call: suspended, reinstated, [Already Suspended], [Already Active], a positioned recording failure, a positioned credential failure, or an invalid request. The composition's own query surface alongside the tamper-evident trail; its refusal entries are evidence of refusals and never of acts.

Kind:       Field
Field of:   the suspension-log entry
Role:       the call classification
Projection: outcome

#### Already Suspended

The composition's idempotence refusal from [Suspend Actor], answered when the actor is already suspended: no second cascade, no second revocation, no second outcome. The state gate is what fires the cascade exactly once, on the active-to-suspending edge.

Kind:       Member
Member of:  the suspend rejection
Role:       Rejection
Projection: already-suspended

#### Already Active

The composition's no-op refusal from [Reinstate Actor], parameterized by what it found: active means there is nothing to lift, suspending means the actor's cascade is completed first and then lifted. The parameter is the caller's next action, which is why the arm carries one — the prose described the distinction while the signature declared no payload to switch on.

Kind:       Member
Member of:  the reinstate rejection
Role:       Rejection
Projection: already-active

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Suspend Actor]: #suspend-actor
[Suspension Report]: #suspension-report
[Reinstate Actor]: #reinstate-actor
[Revoked Grants]: #revoked-grants
[Revoked Sessions]: #revoked-sessions
[Unresolved Members]: #unresolved-members
[Outcome]: #outcome
[Already Suspended]: #already-suspended
[Already Active]: #already-active

---

## Standards references

Actor Suspension is the structural form of the prompt-and-provable-removal-of-access requirement every access-control regime imposes at offboarding, deprovisioning and incident response. Its primary anchors:

- **NIST (National Institute of Standards and Technology — the US federal standards body) SP 800-53 Rev. 5, AC-2(3) (Account Management — Disable Accounts)** and **AC-6(5) (Least Privilege — Privileged Accounts)** — AC-2(3) requires disabling accounts on termination, when they pose significant risk, or when they are no longer required; AC-6(5) requires privileged access be removed when no longer authorized. [Suspend Actor]'s complete multi-surface revocation (Invariant 1) is the operational form of *disable the account across every surface it can act through*, and the sealed enumeration (Invariant 2) makes it provable that the control was applied.
- **SOX (Sarbanes-Oxley Act) section 404 (Internal Control over Financial Reporting)** — segregation of duties and access removal on role change are section 404 controls; the enumerated, attributed, tamper-evident outcome is the evidence that a departing or reassigned actor's access to financial systems was removed promptly and completely.
- **HIPAA (the US Health Insurance Portability and Accountability Act) section 164.308(a)(3)(ii)(C) (Termination Procedures)** — the administrative safeguard requiring procedures for terminating access to electronic protected health information when a workforce member's employment ends. This composition is the structural realization.
- **PCI DSS (the Payment Card Industry Data Security Standard — the card networks' mandatory rules for cardholder data) Requirement 8.1.3** — access for terminated users must be revoked immediately and completely. The ordered, completed revocation — plan recorded, every revocation standing, the remainder closed within a declared window — and the sealed enumeration are the structural form of *immediately and completely, provably*.
- **ISO/IEC 27001 clause A.9.2.6 (Removal or Adjustment of Access Rights)** — the International Organization for Standardization / International Electrotechnical Commission control requiring access rights be removed on termination or adjusted on change. The enumerate-and-revoke-each-surface cascade is the operational control; the report and the sealed outcome are the audit evidence.

Actor Suspension inherits the broader standards compliance of its constituents:

- Through **Permissions**: NIST SP 800-53 AC-2/AC-3/AC-6, NIST SP 800-207 (Zero Trust), ISO/IEC 27001 clause A.9, HIPAA section 164.312(a)(1), SOX section 404, PCI DSS Requirement 7 — the grant-revocation surface the cascade drives.
- Through **Session**: NIST SP 800-63B section 7 (Session Management), OWASP ASVS (the Open Worldwide Application Security Project's Application Security Verification Standard) V3, HIPAA section 164.312(a)(2)(iii) — the session-revocation surface.
- Through the **Audit Trail substrate**, and transitively Event Log, Actor Identity, Tamper Evidence and Retention Window: SOX section 404 and section 802, HIPAA section 164.312(b) and section 164.530(j), PCI DSS Requirement 10, 21 CFR (Title 21 of the US Code of Federal Regulations) Part 11, SEC (the US Securities and Exchange Commission) Rule 17a-4, ISO/IEC 27001 clause A.12.4, GDPR (the EU General Data Protection Regulation) Articles 30 and 32 — the attributed, retained, tamper-evident record the suspension lands on.
- Through the optional **Credential**: NIST SP 800-63B (authenticator revocation), PCI DSS Requirement 8 — the re-authentication door the credential arm closes.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — actor-suspension.tla + 5 twins + 9 probes, 2026-10-27
last gate: 2026-10-26 — Final Critique 6 — foundational count 3, not clean, no sample

open:
- 2026-08-30-i · refining · formal · actor-suspension.tla models no credential check and no attribution, so no model checks that each revocation names a writer its own intent verified (Invariant 5.1 through 5.5) → model the attests a fresh cascade, a resume and the sweep make
- 2026-10-26-a · refining · Composition state 9 · the index below the mark is classified truth-bearing, neither a derived index nor extraction-pending under the Execution Contract's Composition state section, while a miss below the mark is not observable (Composition state 26, 29) → classify the window: extraction-pending against the actor registry (Composition state 11), or derived with its below-mark reading anchored in the trail
- 2026-10-26-b · refining · Primitive policy 13, 14 · the prefixes and the intent event id lengthen a resumed or swept revoke's reason past the reason the boundary predicate admitted, so a constituent's length bound can refuse it and leave the cascade suspending to its escalation → bound the reason at the boundary with room for a prefix and an intent event id, or oblige the deployment's bounds to admit it
- 2026-10-26-c · foundational · Audit arm 17, Audit arm 20 · a recording failure at the outcome lands as recording-failure carrying outcome, read as committed revocations, while under Execution Contract Database 1 an act whose write failed commits nothing → land it carrying intent, or keep it, once the maintainer reads whether a refused outcome leaves an act's other writes committed (Multi-Party Approval 2026-10-26-d)
- 2026-10-26-d · refining · Audit arm 15, the signature, the example of a credential rotated mid-act · invalid-credential's outcome position is unreachable under Execution Contract Database 2 → retire it, a turn of the 2026-09-15 Decision
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/actor-suspension.md`; the migration and the editorial rule that got it here are in [its history](./actor-suspension.hist.md).

- **2026-08-29 — The cascade is completed, never undone: intent before any revoke, outcome after every one, a `Suspending` state between, and a bounded sweep as the composition.** *Chose:* an intent record under the operator's credential carrying the plan, written before the first irreversible revoke; every revocation standing once committed; a `Suspending` state the issuance gate treats as closed and [Suspension Report] shows with the open members; the outcome appended only after every revocation; a resume arm on [Suspend Actor]; a completion sweep bounded by the completion bound and the audit horizon, attested under a declared service identity behind a recovery-intent record, pre-checked by a seam-injected invocation identity; every substrate transcription carrying its step; the two stores classified; and the partial-failure-posture knob removed. *Over:* the grounded revision's one-transaction all-or-nothing cascade with rollback. *Because:* no constituent declares the rollback that posture rested on — a revoked grant, session or credential is terminal by its atom's own invariant and the audit append cannot be withdrawn — and the wiring that claimed it could leave a sealed outcome enumerating revocations the rollback had undone, a false record nothing can withdraw; and every revocation ran before the operator's credential was verified. The pattern was grounded before the durability-boundary and authentication-precedence rules existed; it returns to `partially resolved` until a fresh gate re-grounds it (the frozen rules — *Durability boundaries*, *Authentication precedence*, *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*, *A derived index splits at the horizon*).
- **2026-08-30 — The resumer is verified before it revokes, absence is a miss, the intent's own appended arm is landed, every credential is enumerated, and liveness is arithmetic.** *Chose:* a resume-intent record under the resumer's credential before a resumed cascade touches a member, with the resumer, the resume event and the recovery marker on the outcome and the operator named on every outcome; an absent index key read as a miss and resolved through the trail's tail above a high-water mark the sweep advances, so a crash between the durable intent and the index write cannot let a second intent or a fresh grant through; the intent's own appended-but-refused arm read back and proceeded on as landed, the position rather than the step exported, and the invocation yielding the act at the outcome position instead of retrying beside the sweep; the per-actor critical section taken at the gate and declared, with a stalled invocation adopting a landed outcome under a lapsed lease; every effective-active credential across every type, planned and revoked as a set; the plan sized against the substrate's payload cap before the intent; the strict inequality over the bound, the cadence and the write latency against the window, checked at instance start; the clock offset allowance under every cross-seam comparison the checks make; and, on the closure check, the mark made the line — the trail answers above it, the index answers below it as a truth-bearing store. *Over:* a resume that revoked under the resumer's reference and verified nobody until the outcome; *absent is active* beside *rebuild on miss*; *nothing has committed* at a step whose arm arrives appended; *the actor's active credential*; a cadence-no-longer-than-window inequality; a bare recording failure on both sides of the commit; and a mark that silently turned absence below it back into an answer. *Because:* a revocation is irreversible and the principal it is attributed to must be the one whose credential was checked; a keyed index repairs only what it can observe missing; a second intent is a second plan the sweep pairs twice; Credential's effective-active bound is per pair, so one revocation leaves the other type authenticating; a window promise whose inequality omits the bound and the latency is breached on every orphan with the check passing; and a keyed read that enumerated the whole retained trail for every never-suspended actor would keep the miss rule total at a cost the issuance gate cannot pay, so the durability obligation is declared and its breach made a finding rather than a silent active (the frozen rules — *A compensator is exclusive*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, *Capability provenance*, *A derived index is trustworthy only where a miss is observable*, *A transcribed rejection arm keeps its payload*).
- **2026-09-15 — An unclosable member is named, not owed.** *Chose:* a planned member a constituent answers `not-known` or invalid-request for joins the **unresolved members**, rides the outcome as its own field, and lets the act complete; *accounted* is the predicate the completeness check runs on — closed, already terminal, or named unresolved. *Over:* leaving such a member in the open members. *Because:* the sweep closes only still-active planned members, so a handle the constituent has lost could never be closed: the actor stayed `Suspending` forever and the every-planned-member-accounted check failed permanently against a cascade that had in fact done everything available to it. *Open* means a door this composition can still close; *unresolved* means a door whose handle the constituent lost, and conflating the two made a store inconsistency look like an unfinished suspension.
- **2026-09-15 — The credential arm carries its position, like the recording arm.** *Chose:* `invalid-credential(intent | outcome)` on [Suspend Actor]'s signature. *Over:* mapping a credential rotated mid-act onto `recording-failure(outcome)`. *Because:* the recording arm's outcome position tells a caller to resume, and a caller resuming on the credential that just refused resumes into the same refusal, forever. The positioned credential arm says the true thing instead — the revocations stand, this credential no longer attests, and the outcome is not this caller's to write — which routes the act to a resume under a different verified operator, or to the sweep (the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`).
- **2026-09-15 — The plan is built from stored status, and the report says when an enumeration has aged out.** *Chose:* the snapshot selects by the constituent's stored status, so a lapsed-but-stored-active session enters the plan and its revoke answers benignly by the constituent's own derivation; and [Suspension Report] answers a past-horizon suspension with the state, the instant, the operator and the binding, marking the enumeration unavailable-past-horizon. *Over:* enumerating by derived status, and answering an empty revoked set past the horizon. *Because:* the plan is the record of what the suspension set out to close, and a member dropped by derivation is a member the record never mentions; and an empty enumeration where the enumeration has merely aged out is a record saying nothing was closed — the exact class of false record this composition exists to prevent.
- **2026-10-20 — The store's guarantees cited, not restated, the per-actor critical section among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 47), and the fifty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — the composition's stores held at the constituents' durability (Capability requirement 39, External check 9), to Store 3, and an entry lost below the mark read as a durability breach (Composition state 30, 31, Check 3.3), to Store 3 and Store 4; the per-actor critical section the host supplied (Capability requirement 29) and every rule taking or holding it at the state gate, through the index write, across a cascade's revocations, at the sweep's pre-check and against a second sweep (Action wiring 1, 2, 3, 22, Reconciliation 10, 13, 14, 30, Concurrency 1 through 5, External check 7, 8), its release, its lease and its terminus, the bar on running without it, its loss or unavailability mid-call, the sweep's skip of a held actor and the report's exemption (Capability requirement 30 through 35, Action wiring 23, 24, 54, 69, Reconciliation 11, 12, Concurrency 9), and a call's pre-check and adoption of an outcome another writer landed (Action wiring 43, 44, 46, 47), to Store 2, the sweep keeping its own pre-check (Reconciliation 15 through 17); to Store 1, under which an action's intent, revocations and outcome commit together, a constituent's storage failure leaving open members, the revocation-failure answer and the suspending actor it left (Action wiring 33, 40, 41, 42), the re-query of a revoke whose answer was lost (Atomic writes 5 through 9), the bar on enlisting a revocation in a transaction (Wiring decision 4, Atomic writes 4), the sweep's young-intent edge (Reconciliation 5, 8, Check 6.9), and the read-back of a recording-failure at the retention step, a split Audit Trail's own rewrite removed (Audit arm 7, 9, 16); and to Store 1 and Store 3 the restart sweep and the dead-process rule (Capability requirement 44, Reconciliation 1, 24); with them revocation-failure leaves [Suspend Actor]'s signature, no kept rule answering it; rules 478 to 421. *Over:* a host critical section per actor, held from the state gate through the index write and leased to the suspension completion bound; a cascade left standing partial by a constituent's store failure, its open doors named for a resume or the sweep to close; and a sweep bounded below by the completion bound and run at every restart — the critical section and its lease are a turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: every revoke and every record this composition makes is a store write, so a constituent's store failure fails the whole act and nothing of it commits, Store 2 reads what a state gate or the sweep decides on inside the transaction that writes it, which is what the critical section was for, and no crash leaves half an act for the sweep to find. The intent before any revoke, the suspending state, the resume, the sweep, the completion window and the escalation stay on the refusals that still stop a cascade at its outcome; the indexes stay outside every action's transaction (Composition state 18), so the mark, the miss and the tail read stay; and the suspension completion bound stays in the closure floor (Capability requirement 23, 27). What the composition does for its domain is otherwise unchanged.

</details>

NOTE: End of Actor Suspension.

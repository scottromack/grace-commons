---
title: External Onboarding
parent: Conceptual Compositions
nav_order: 15
has_toc: true
toc: true
---

# External Onboarding

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

External Onboarding is the full arc of admitting an external entity to a system — invitation issued by an authenticated, attributed actor, accepted by the invitee (establishing the single identity binding), Party Identity enrolled in Unverified state, credential registered, every step attested in the Audit Trail.

The load-bearing emergent invariant is invitation-gates-enrollment: no Party Identity is created via this composition unless an Invitation's Accepted transition precedes it, and the Audit Trail completion record names the specific invitation, the accepting identity, the party record, and the credential in one tamper-evident entry.

Without the composition, any of these steps can occur independently, in any order, without a documented chain; the composition is what makes the chain mandatory and auditable.

**Composes:** [Invitation](../atoms/invitation.md) · [Credential](../atoms/credential.md) · [Party Identity](../atoms/party-identity.md) · [Audit Trail](./audit-trail.md)

---

## Intent

Every system that admits external parties — customers, collaborators, patients, counterparties — faces the same structural challenge: the invitation must be issued before the invitee exists in the system, yet the moment of acceptance is the moment at which the system must durably record who joined, establish their identity record, and register the credential they will use to authenticate. Those three obligations — serializing concurrent acceptance attempts, creating the party record, registering the credential — belong to different atoms. The question of what must happen when they meet, in what order, with what audit record binding the whole arc together, belongs to no single atom. It belongs to the composition.

External Onboarding wires the four constituent atoms into a single enforced onboarding boundary. The [Invite] action establishes the documented intent: an authenticated actor initiates an invitation, creating an audit-anchored record of who invited whom and to what context. Whether that actor was *permitted* to invite is not this composition's gate — its attempt record authenticates and attributes, and authorization is the above-composition obligation Non-goal 1 and Non-goal 2 name. The [Onboard] action is the composition's load-bearing center: it calls `Invitation.accept` first — establishing the single-resolution serialization point — then `Party Identity.enroll`, then `Credential.register`, recording the full arc in the Audit Trail as a single named event that links invitation token, accepting identity reference, party record, and credential. The [Decline] and [Revoke] actions close the invitation on the other terminal paths, each attested in the Audit Trail.

The emergent invariant is invitation-gates-enrollment: no Party Identity is enrolled and no Credential registered via this composition unless an Invitation's `Accepted` transition precedes them — in the same onboarding call, or, on the resume arm, in the stopped arc that call re-enters. The Invitation atom's single-resolution invariant (at most one write to one of three stored terminal states per invitation — a lapsed invitation is shown `Expired` by derivation, never written — the transition atomic under concurrent attempts) is the mechanism that makes the gate hold under concurrent onboarding attempts for the same invitation — exactly one [Onboard] call clears the gate; all others receive `already-resolved(Accepted)` and create no constituent records — their attempt event is their only trace — unless they are the same acceptor re-entering a stopped arc past the bound, which is the resume arm, one resumer per token.

The second emergent property is the identity binding at accept, not at initiate. The accepting_identity_ref passed to `Invitation.accept` — a caller-supplied external reference identifying who is accepting, such as an email address or an external identity handle — is recorded permanently in the Invitation record at the moment of acceptance. The `party_id` produced by the downstream `Party Identity.enroll` call is then linked to that accepting_identity_ref in the Audit Trail completion record. The tracing path — from any enrolled Party Identity back to the specific Invitation that authorized its creation — runs through the Audit Trail: the completion event carries both the invitation_token and the `party_id`, making the chain reconstructable from records alone.

---

## Composes

- **[Invitation](../atoms/invitation.md)** — the invitation lifecycle and the single-resolution gate.
- **[Credential](../atoms/credential.md)** — the binding between the enrolled party and the party's authentication material.
- **[Party Identity](../atoms/party-identity.md)** — the identity record the arc enrolls in the unverified state.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every attempt and every outcome is recorded through.

```
Composes 1: EXACTLY ONE Invitation instance MUST serve the composition.
Composes 2: EXACTLY ONE Credential instance MUST serve the composition.
Composes 3: EXACTLY ONE Party Identity instance MUST serve the composition.
Composes 4: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 5: The composition MUST NOT change a constituent's spec.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 8: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 9: A deployment MUST route EVERY initiate, accept, decline AND revoke on the Invitation instance through the composition's four actions.
Composes 10: The composition MUST NOT claim an invitation a caller resolved outside the composition's four actions.
Composes 11: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 12: The composition MUST select an event in the composition's own code.
Composes 13: The composition MUST NOT query the substrate by a payload predicate.
Composes 14: The composition MUST attest EVERY audit record under the calling actor's credential.
Composes 15: The composition MUST NOT declare a service identity.
Composes 16: The composition MUST NOT make a constituent write outside a caller-authenticated invocation.
```

Term composition: this pattern's wiring of [Invitation](../atoms/invitation.md), [Credential](../atoms/credential.md), [Party Identity](../atoms/party-identity.md) and the [Audit Trail](./audit-trail.md) substrate — the four actions, the credential gate and the resume arm.

Term constituents: [Invitation](../atoms/invitation.md), [Credential](../atoms/credential.md), [Party Identity](../atoms/party-identity.md), [Audit Trail](./audit-trail.md).

Term substrate: the Audit Trail instance serving the composition.

Term trail: the substrate's events, in sequence order, as the composition and an auditor read them.

WHY:
Composes 1 and Composes 9 are one posture from two sides. The composition keeps one dedicated Invitation instance and the deployment routes every lifecycle action on it through [Invite], [Onboard], [Decline] and [Revoke]; a direct call to the atom, or an invitation managed on another instance or by a sibling pattern, sits outside this composition's audit claims (Composes 10). That is the membership test the store-quantified acceptance checks assume — without it a lawfully-elsewhere invitation would be condemned as a recording failure. Credential and Party Identity are shared surfaces by design: `Credential.rotate` and downstream verification run outside this composition, and no check quantifies over their stores in the store-to-records direction.

What Invitation's gate serializes, and what it does not. The single-resolution invariant serializes the one write to accepted — under concurrent accept calls exactly one commits and every other receives already-resolved carrying accepted — and nothing after it, so two re-entries of an accepted arc are two callers the atom answers identically and cannot tell apart. A lapsed invitation is *shown* expired by the atom's read-time derivation and never written, and a write attempted on one is refused with the distinct expired token, never already-resolved. The resume arm's own serialization is therefore this composition's obligation (Capability requirement 13), attributed to no constituent.

Composes 7 and Composes 8 name the substrate relation: [Audit Trail](./audit-trail.md) is a composition, so Event Log, Actor Identity, Retention Window and Tamper Evidence are reached *through* it. Composes 11 through 13 declare the read exactly — the substrate declares a sequence-range enumeration, not a payload lookup, so every payload-keyed retrieval on this page is enumerate-and-filter in the composition's or the auditor's own code, the same move the substrate uses for its own rebuilds.

Composes 14 through 16 are why the composition declares no service identity: every constituent write is made inside a caller-authenticated invocation, the resume arm included, which is a re-invocation by an authenticated caller rather than a sweep.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store composition state.
Composition state 2: Audit Trail IS AUTHORITATIVE FOR the tracing from a party to the invitation behind the party's enrollment.
Composition state 3: The composition MUST NOT store a correlation index over the trail.
Composition state 4: The composition MUST read a completion record's party id, credential id AND invitation token from the completion record's own data.
```

Term completion relation: the relation a completion record declares — one invitation token to one completion record at most, and one completion record to exactly one invitation token, one accepting identity reference, one party id and one credential id; mandatory on the completion record's side, optional on the invitation's, since an invitation may stay pending, lapse, or be declined or revoked.

WHY:
**Contract classification: conforming, no stored composition state** (the section titled Composition state in `execution-contract.md`). There is no composition-owned index or map: the Audit Trail is already the tamper-evident, attributable, retention-bounded record the regulated scenarios require, and a separate map would duplicate that record under weaker integrity guarantees. The Audit Trail is the map.

The tracing runs through the completion record: it carries the invitation token, the accepting identity reference, the party id and the credential id in its data, so an investigator asking *what invitation authorized the creation of party P?* enumerates the trail, filters for the completion record naming P, and reads the token from the event's data. Term completion relation is the relation's cardinality and modality declared; Invariant 4.4 and Invariant 4.5 are the two halves an auditor checks.

### Capability requirement

```
Capability requirement 1: A deployment MUST supply now at the composition's seam.
Capability requirement 2: The composition MUST take EXACTLY ONE now PER invocation.
Capability requirement 3: The composition MUST NOT take now as an input.
Capability requirement 4: The composition MUST NOT mint an id.
Capability requirement 5: A deployment MUST set the onboarding completion bound.
Capability requirement 6: The slowest conforming invocation MUST NOT EXCEED the onboarding completion bound.
Capability requirement 7: A deployment MUST set the clock offset allowance.
Capability requirement 8: The seam skew MUST NOT EXCEED the clock offset allowance.
Capability requirement 9: A deployment MUST configure the Audit Trail instance with the audit horizon.
Capability requirement 10: The longest resume gap MUST NOT EXCEED the audit horizon.
Capability requirement 11: A deployment MUST declare the minted-id width bounds.
Capability requirement 12: The minted-id width bounds MUST agree with the widths the wired constituents allocate.
Capability requirement 13: The host MUST supply a critical section keyed by invitation token.
Capability requirement 14: The host MUST exclude a second holder of one invitation token's critical section across EVERY node the composition runs on.
Capability requirement 15: The host MUST release a critical section on the holder's return.
Capability requirement 16: The host MUST release a critical section on the holder's death.
Capability requirement 17: The widened bound MUST NOT EXCEED the lease length.
Capability requirement 18: IF the onboarding completion bound EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 19: IF the clock offset allowance EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 20: IF the critical section EQUALS blank THEN the composition MUST refuse to start.
```

Term onboarding completion bound: the deployment's declared maximum for an [Onboard] or [Invite] invocation between the invocation's first constituent write and the invocation's last record — from Invitation's accept committing to the completion or interruption record landing, and from Invitation's initiate committing to the initiated record landing.

Term clock offset allowance: the deployment's declared bound on the difference between this composition's seam clock and the clocks at Invitation's, Party Identity's, Credential's and the substrate's seams.

Term widened bound: `onboarding completion bound + clock offset allowance` — the age past which an arc may be read as stopped.

Term audit horizon: the horizon of the retention policy the wired Audit Trail instance places every onboarding event under — the upper edge of the resume arm and of every trail-walking check.

Term minted-id width bounds: the maximum widths the wired constituents allocate for an invitation token, a party id, a credential id and an event id.

Term critical section: the host-supplied mutual exclusion keyed by invitation token, which an arc holds from the arc's first read or from Invitation's accept committing, through the arc's return.

Term lease length: the duration the host holds a critical section implemented as a lease.

Term slowest conforming invocation: the longest a conforming [Onboard] or [Invite] invocation takes between the invocation's first constituent write and the invocation's last record.

Term seam skew: the difference between this composition's seam clock and a constituent's seam clock.

Term longest resume gap: the longest interval a deployment allows between an acceptance and the acceptance's resumption.

WHY:
**Clock and ids, stated once.** Now — the reading every bound is read against — is injected at this composition's seam, one reading per invocation, never an input of any action and never read inside a step. Every other stamp the composition compares against — an invitation's acceptance instant, a party's enrollment instant, a credential's registration instant, an event's recording instant — is written by a constituent from the constituent's *own* seam, and the composition compares its reading with theirs only under the clock offset allowance (Clock semantics 1). Ids are minted at the constituents' seams; this composition mints none.

**Two readers spend the completion bound.** The acceptance checks examine only arcs older than the widened bound, a younger one being possibly in flight and inconclusive (Standing rule 7); and the resume arm reads an acceptance older than the widened bound as an arc that stopped, and a younger one as an arc still running, which it refuses. A bound shorter than the slowest conforming invocation makes both readers wrong in the unsafe direction — a running arc read as stopped is resumed beside itself — which is what Capability requirement 6 forbids. A skew wider than the allowance is outside the resume arm's duplicate-freedom claim exactly as a short bound is (Invariant 1.3); Check 7.1 through 7.3 are where either shows.

**The audit horizon is the upper edge.** Past it the arc's events are lawfully destroyed, their payloads unreadable, and the survivors — the undeletable Invitation, Party Identity and Credential records and the attestation fields the purge preserves — are truth-bearing evidence an auditor reports on, never an arc a caller re-runs (Resume 4). An acceptance older than the horizon cannot be resumed through this composition at all, which is why the horizon must outlast the longest gap a deployment allows before resuming (Capability requirement 10).

**The minted-id width bounds** let a payload carrying ids that do not exist yet be sized before anything commits — the substrate's own attestation id width move (Primitive policy 6).

**The critical section** is the one serialization neither the gate nor any constituent supplies. Invitation serializes the write to accepted and nothing after it; no constituent here declares a lease; and the resume arm is a look-then-write compensator — it reads the trail and the Party Identity store and then enrolls, registers and records — so two resumers with one acceptor, both past the bound, would each find no party and each enroll one. The critical section is what makes the resume arm's reads decisive: every pre-check is read under it, never before it, and a stalled original still holding it is refused rather than raced. Where the host implements it as a lease, the lease is at least the widened bound long (Capability requirement 17), and its **expiry is the invocation's terminus** — an invocation whose lease expired has yielded the arc, and the widened bound is exactly the point past which a resumer may hold it (Action wiring 12 through 14; the section titled *A compensator is exclusive* in `pressure-testing.md`). This composition runs no scan, so no liveness inequality gains a hold term; what the lease bounds is how long a stalled-but-alive holder can keep a resumer out. A deployment whose critical section can be lost while its holder lives, or that does not span its nodes, has the second writer Check 7.1 through 7.3 exist to report, and that is a conformance failure there, not a tolerated residue.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank required input.
Primitive policy 2: IF an actor reference EXCEEDS the reference length cap THEN the composition MUST answer invalid-request.
Primitive policy 3: The composition MUST validate EVERY field an action passes to a constituent PER the constituent's own field rules.
Primitive policy 4: An action MUST NOT record the action's attempt record BEFORE validating the action's inputs.
Primitive policy 5: IF the data of an event the action will emit EXCEEDS the payload cap THEN the composition MUST answer invalid-request.
Primitive policy 6: The composition MUST size a minted id the payload will carry at the id's minted-id width bound.
Primitive policy 7: IF the call carries a resume choice THEN [Onboard] MUST read the invitation through Invitation's read.
Primitive policy 8: [Onboard] MUST NOT record the accept attempt BEFORE reading the invitation for a call carrying a resume choice.
Primitive policy 9: IF the call carries a resume choice AND the invitation's status EQUALS pending THEN [Onboard] MUST answer invalid-request.
Primitive policy 10: An action refused under Primitive policy 1 through 9 MUST NOT write.
```

Term required input: for [Invite] the inviter reference, the context and the actor credential; for [Onboard] the invitation token, the accepting identity reference, the name, the date of birth, the document type, the document reference, the credential type, the credential material, the enrolling actor reference and the actor credential; for [Decline] the invitation token, the service actor reference and the actor credential; for [Revoke] the invitation token, the revoked by reference, the revocation reason and the actor credential.

Term actor reference: the inviter reference, the enrolling actor reference, the service actor reference or the revoked by reference — the reference an action attests under.

Term actor credential: the calling actor's Actor Identity credential, which the attempt record's attestation verifies.

Term credential material: the authentication material a [Onboard] call passes to Credential's register — raw, never hashed by this composition.

Term resume party id: the party id an administrator chose from an onboarding-indeterminate refusal's party candidates, supplied on the [Onboard] that resumes the arc.

Term resume credential id: the credential id an administrator chose from an onboarding-indeterminate refusal's credential candidates, supplied on the [Onboard] that resumes the arc.

Term resume choice: a resume party id | a resume credential id — the id an administrator supplies from an onboarding-indeterminate refusal.

Term service actor reference: the system service account a [Decline] attests under.

WHY:
Primitive policy 2 adopts the substrate's own caller-input rule at this layer, so the substrate's invalid-request cannot fire on a reference this layer already passed. Primitive policy 5 and Primitive policy 6 size every event the action will emit — on the fresh arc and the resume arm alike, the largest being the interruption record with its party id, stage and reason — within the payload cap, with ids that do not exist yet sized at their declared widths. Under these rules the *caller-input* source of the substrate's invalid-request is foreclosed for validated inputs; the arm itself is never unreachable, because the substrate has two sources no caller validation touches (Audit arm 8).

Primitive policy 3 and Primitive policy 4 pin the validation depth: each constituent's field rules — Invitation's ttl bounds, Party Identity's enrollment-field rules, Credential's registration rules — are run *before* the gate. A typo caught after Invitation's accept has permanently consumed the invitation; caught before, it has consumed nothing. The constituents' own invalid-request arms stay as the backstop (Action wiring 21, Action wiring 28 and Action wiring 31).

Primitive policy 7 through 9 refuse a resume choice on an invitation still stored pending, with nothing written: a pending invitation names no arc the call could resume, so the value is malformed. Any other stored status falls through to the gate, which lands its own answer, and Resume 22 and Resume 44 validate the value against the candidates.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an attempt record THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an attempt record THEN the action MUST answer storage-failure carrying intent.
Audit arm 3: IF Audit Trail answers invalid-request at an attempt record THEN the action MUST answer storage-failure carrying intent.
Audit arm 4: A refused attempt record MUST stop the action.
Audit arm 5: IF Audit Trail answers recording-failure carrying a pre-append step at a post-write record THEN the action MUST answer storage-failure carrying outcome.
Audit arm 6: IF Audit Trail answers recording-failure carrying the retention step at a post-write record THEN the action MUST proceed as landed.
Audit arm 7: The composition MUST NOT retry a post-write record Audit Trail answered with the retention step.
Audit arm 8: IF Audit Trail answers invalid-request at a post-write record THEN the composition MUST read the record back.
Audit arm 9: The read-back MUST run from the sequence number of the invocation's own attempt record to the open end.
Audit arm 10: The read-back MUST match the post-write record by action reference AND invitation token.
Audit arm 11: IF the read-back finds the post-write record THEN the action MUST proceed as landed.
Audit arm 12: IF the read-back finds no post-write record THEN the action MUST answer storage-failure carrying outcome.
Audit arm 13: IF Audit Trail answers invalid-credential at a post-write record THEN the action MUST answer invalid-credential.
Audit arm 14: IF Invitation answers storage-failure THEN the action MUST answer storage-failure carrying intent.
Audit arm 15: IF Party Identity answers storage-failure THEN [Onboard] MUST answer storage-failure carrying outcome.
Audit arm 16: IF Credential answers storage-failure THEN [Onboard] MUST answer storage-failure carrying outcome.
Audit arm 17: A caller MUST read storage-failure carrying intent as a committed nothing.
Audit arm 18: A caller MUST read storage-failure carrying outcome as a committed invitation write.
Audit arm 19: The deployment MUST alert on an invalid-request from Audit Trail as a deployment fault.
Audit arm 20: The deployment MUST alert on a post-write record carrying the retention step as an unretained event.
```

Term attempt record: the record an action writes first — the initiate attempt, the accept attempt, the decline attempt or the revoke attempt; the Actor Identity attestation the substrate makes inside the record *is* the credential gate.

Term post-write record: a record an action writes after a constituent write commits — the initiated record, the acceptance record, the interruption record, the completion record, the decline record or the revoke record.

Term pre-append step: a recording-failure step naming a step at or before the substrate's append — the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — the event is appended and attested, and only the event's retention failed.

Term read-back: the composition's enumerate-and-filter read of the trail for a post-write record whose landing the substrate's answer did not say.

Term position: intent | outcome — where a storage-failure sat: intent, no constituent has committed anything and the whole action may be retried as written; outcome, the action's Invitation write has committed, and a retry re-enters the action rather than repeating it.

WHY:
The substrate answers one taxonomy — invalid-credential, invalid-request, recording-failure carrying the step — and this composition maps it **by the call's position relative to the constituent write**, not uniformly. The step is load-bearing: at a pre-append step the event is not in the log; at the retention step the event exists and only its placement failed, the substrate's Invariant 2 liveness arm owns that unretained event, and a retry from here would append a second one (Audit arm 7).

At an attempt record nothing has committed, so every arm is a clean pre-state refusal. An attempt event that stands after the retention step is harmless: attempt records are the record of a try, not per-invitation signatures (Check 6.4), so a retried attempt lands a second one and nothing is owed.

At a post-write record a constituent write exists, so no arm can refuse the act, only report it. **The substrate's invalid-request has three sources the token does not distinguish** (Audit arm 8): a caps disagreement between the declared minted-id width bounds and the wired instance, at the substrate's first or third step — nothing appended; Actor Identity's own invalid-request at the substrate's second step — nothing appended; and the substrate's retention-configuration fault, Retention Window's invalid-policy or policy-not-found, which Audit Trail routes onto this arm at its fourth step — **the event is appended**. So the composition reads the record back, from the sequence number of the invocation's own attempt record — which the invocation holds, since the substrate answered the attempt's event id, and which the substrate's read record surfaces — to the open end: the post-write record, if it landed, lies after the attempt, and nothing before the attempt can be it. invalid-credential at a post-write record is a rotation race — the same credential attested at the attempt moments earlier — and takes the pre-append landing's gap, answered as invalid-credential so the caller learns the true cause.

Audit arm 17 and Audit arm 18 export the position across the caller boundary, because the caller is the one who retries and cannot see the steps (the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent — the whole action may be retried as written; outcome — the action's Invitation write has committed, and a retry re-enters it, as already-resolved on [Decline] and [Revoke], as the resume arm on [Onboard] once the widened bound has elapsed, and as a fresh invitation on [Invite], the committed pending one lapsing unreachable. The relayed constituent storage-failures take the position by the same test: Invitation's, refused with nothing written, is intent; Party Identity's and Credential's, refused after the acceptance committed, are outcome. Audit arm 19 and Audit arm 20 name the surface every alert lands on — the deployment's alerting surface, the substrate's compliance alert.

### Action wiring

```
invite(inviter_ref, optional invitee_ref, context, optional ttl, actor_credential)
  answers invitation_token
  refuses invalid-request | invalid-credential | storage-failure(position)

onboard(invitation_token, accepting_identity_ref, name, date_of_birth, document_type, document_ref, credential_type, credential_material, optional expires_at, enrolling_actor_ref, actor_credential, optional resume_party_id, optional resume_credential_id)
  answers onboarding result
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | onboarding-indeterminate(candidates) | duplicate-active-credential | storage-failure(position)

decline(invitation_token, service_actor_ref, actor_credential)
  answers declined
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | storage-failure(position)

revoke(invitation_token, revoked_by_ref, reason, actor_credential)
  answers revoked
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | storage-failure(position)
```

Term onboarding result: the party id and the credential id an [Onboard] answers.

Term invitation refusal: the Invitation refusal a gate call met — already-resolved carrying the stored terminal, not-known or expired.

Term candidates: party candidates | credential candidates — the ids an onboarding-indeterminate refusal carries.

```
Action wiring 1: An action MUST NOT call a constituent BEFORE the action's attempt record lands.
Action wiring 2: The composition MUST NOT verify a credential outside an attempt record.
Action wiring 3: A validated invite MUST record an initiate attempt carrying the invitee reference, the context AND the ttl.
Action wiring 4: An admitted invite MUST call Invitation's initiate with the inviter reference, the invitee reference, the context AND the ttl.
Action wiring 5: IF Invitation answers invalid-request for an initiate THEN [Invite] MUST answer invalid-request.
Action wiring 6: An admitted invite MUST record an initiated record carrying the invitation token, the invitee reference, the context AND the ttl ONLY AFTER Invitation's initiate answers the invitation token.
Action wiring 7: A landed invite MUST answer the invitation token.
Action wiring 8: A validated onboard MUST record an accept attempt carrying the invitation token, the accepting identity reference, the document type AND the document reference.
Action wiring 9: An admitted onboard MUST call Invitation's accept with the invitation token AND the accepting identity reference.
Action wiring 10: IF Invitation answers accepted THEN [Onboard] MUST take the critical section for the invitation token.
Action wiring 11: IF the host refuses the critical section to a fresh arc THEN [Onboard] MUST answer storage-failure carrying outcome.
Action wiring 12: An arc MUST write ONLY IF the arc holds the critical section.
Action wiring 13: An arc whose critical section expired MUST NOT write.
Action wiring 14: An arc that lost the critical section MUST NOT write BEFORE taking the critical section again.
Action wiring 15: A fresh arc taking the critical section again MUST establish the arc's stage PER the stage reading.
Action wiring 16: IF the stage reading finds a completion record for the invitation token THEN a fresh arc taking the critical section again MUST answer the completion record's party id AND credential id.
Action wiring 17: IF Invitation answers expired THEN [Onboard] MUST answer invitation-invalid carrying expired.
Action wiring 18: IF Invitation answers not-known THEN [Onboard] MUST answer invitation-invalid carrying not-known.
Action wiring 19: IF Invitation answers already-resolved AND the stored terminal DOES NOT EQUAL accepted THEN [Onboard] MUST answer invitation-invalid carrying already-resolved AND the stored terminal.
Action wiring 20: IF Invitation answers already-resolved AND the stored terminal EQUALS accepted THEN [Onboard] MUST read the invitation through Invitation's read.
Action wiring 21: IF Invitation answers invalid-request for an accept THEN [Onboard] MUST answer invalid-request.
Action wiring 22: IF a resumable acceptance EXISTS for the invitation token THEN [Onboard] MUST take the resume arm.
Action wiring 23: IF the stored terminal EQUALS accepted AND no resumable acceptance EXISTS for the invitation token THEN [Onboard] MUST answer invitation-invalid carrying already-resolved AND accepted.
Action wiring 24: A refused gate call MUST NOT write beyond the accept attempt.
Action wiring 25: A fresh arc MUST record an acceptance record carrying the invitation token, the accepting identity reference, the document type AND the document reference.
Action wiring 26: A fresh arc MUST call Party Identity's enroll with the name, the date of birth, the document type, the document reference AND the enrolling actor reference ONLY AFTER the acceptance record lands.
Action wiring 27: IF Party Identity refuses an enroll THEN the arc MUST record an interruption record carrying the invitation token, the accepting identity reference, party-enrollment as the stage AND the refusal as the reason.
Action wiring 28: IF Party Identity answers invalid-request for an enroll THEN [Onboard] MUST answer invalid-request.
Action wiring 29: An arc MUST call Credential's register with the arc's party id as the principal reference, the credential material, the credential type AND the expiry instant ONLY AFTER the arc's party stands.
Action wiring 30: IF Credential refuses a register on a fresh arc THEN the arc MUST record an interruption record carrying the invitation token, the accepting identity reference, the party id, credential-registration as the stage AND the refusal as the reason.
Action wiring 31: IF Credential answers invalid-request for a register THEN [Onboard] MUST answer invalid-request.
Action wiring 32: IF Credential answers duplicate-active-credential on a fresh arc THEN [Onboard] MUST answer duplicate-active-credential.
Action wiring 33: IF Credential answers duplicate-active-credential on the resume arm THEN the resume arm MUST establish the arc's credential PER Resume 39 through 47.
Deleted: Action wiring 34. Resume 41 and Resume 45 own it, because the arc continues with the credential the arc registered, never the credential standing active.
Action wiring 35: A resume arm reading the arc's credential back MUST discard the call's credential material.
Action wiring 36: An interruption record's refusal MUST NOT change the arc's answer.
Action wiring 37: An arc MUST record a completion record carrying the invitation token, the accepting identity reference, the party id AND the credential id ONLY AFTER the arc's credential stands.
Action wiring 38: A completing arc MUST answer the party id AND the credential id.
Action wiring 39: An arc MUST release the critical section on EVERY return.
Action wiring 40: A validated decline MUST record a decline attempt carrying the invitation token under the service actor reference.
Action wiring 41: An admitted decline MUST call Invitation's decline with the invitation token.
Action wiring 42: IF Invitation answers expired for a decline THEN [Decline] MUST answer invitation-invalid carrying expired.
Action wiring 43: IF Invitation answers already-resolved for a decline THEN [Decline] MUST answer invitation-invalid carrying already-resolved AND the stored terminal.
Action wiring 44: IF Invitation answers not-known for a decline THEN [Decline] MUST answer invitation-invalid carrying not-known.
Action wiring 45: An admitted decline MUST record a decline record carrying the invitation token ONLY AFTER Invitation's decline answers declined.
Action wiring 46: A landed decline MUST answer declined.
Action wiring 47: The composition MUST NOT record a decliner's identity.
Action wiring 48: A validated revoke MUST record a revoke attempt carrying the invitation token AND the revocation reason under the revoked by reference.
Action wiring 49: An admitted revoke MUST call Invitation's revoke with the invitation token, the revoked by reference AND the revocation reason.
Action wiring 50: IF Invitation answers expired for a revoke THEN [Revoke] MUST answer invitation-invalid carrying expired.
Action wiring 51: IF Invitation answers already-resolved for a revoke THEN [Revoke] MUST answer invitation-invalid carrying already-resolved AND the stored terminal.
Action wiring 52: IF Invitation answers not-known for a revoke THEN [Revoke] MUST answer invitation-invalid carrying not-known.
Action wiring 53: IF Invitation answers invalid-request for a revoke THEN [Revoke] MUST answer invalid-request.
Action wiring 54: An admitted revoke MUST record a revoke record carrying the invitation token AND the revocation reason ONLY AFTER Invitation's revoke answers revoked.
Action wiring 55: A landed revoke MUST answer revoked.
```

Term validated invite: an [Invite] call whose inputs clear Primitive policy.

Term admitted invite: a validated invite whose initiate attempt lands.

Term landed invite: an admitted invite whose initiated record landed or proceeds as landed.

Term validated onboard: an [Onboard] call whose inputs clear Primitive policy.

Term admitted onboard: a validated onboard whose accept attempt lands.

Term arc: one onboarding of one invitation token from the acceptance to the completion record — a fresh arc, or the stopped arc the resume arm re-enters.

Term fresh arc: an admitted onboard whose accept Invitation answered accepted.

Term resumable acceptance: an accepted invitation carrying the call's accepting identity reference whose `acceptance instant + widened bound` PRECEDES now.

Term stage reading: the resume arm's establishment of an arc's stage and party from the trail and the Party Identity store, Resume 4 through 23.

Term completing arc: an arc whose completion record lands or proceeds as landed.

Term validated decline: a [Decline] call whose inputs clear Primitive policy.

Term admitted decline: a validated decline whose decline attempt lands.

Term landed decline: an admitted decline whose decline record landed or proceeds as landed.

Term validated revoke: a [Revoke] call whose inputs clear Primitive policy.

Term admitted revoke: a validated revoke whose revoke attempt lands.

Term landed revoke: an admitted revoke whose revoke record landed or proceeds as landed.

Term revocation reason: the reason a [Revoke] call carries, passed to Invitation's revoke and recorded on the revoke record.

WHY:
**One gate discipline for all four actions** (Action wiring 1 and 2). Every state-changing action opens with an attempt record whose Actor Identity attestation, made inside the substrate's own declared surface, *is* the credential gate: an invalid-credential there stops the action before any Invitation write, and the attempt itself is auditable. The substrate exposes no dry-run credential check, and none is needed — the attest is the check. An attempt refused at the gate lands no event; auditing *those* is the forthcoming Failed-Attempt Log's (Non-goal 11). The action's outcome is then recorded by the action's own post-write record.

**[Invite].** The initiated record follows the constituent's success, which is the only point the token exists to be recorded, and carrying the token is what makes the records-alone token correlation in the forensics walk executable. Where that record is absent the token was **not answered to the caller** (Audit arm 5): no caller holds the bearer token, so through this composition the invitation cannot be accepted and lapses at its expiry instant, and the inviter retries with a fresh [Invite]; the gap is Check 6.2's signature. An initiate attempt with no following initiated record marks a failed or interrupted initiate, uncorrelatable to a token by construction, since no token was minted.

**[Onboard] — the load-bearing center.** The step order is fixed: accept attempt, Invitation's accept, the acceptance record, Party Identity's enroll, Credential's register, the completion record, the answer — and Wiring decision 1 through 3 are why it cannot be reordered. The acceptance record carries the document type and the document reference, so a dead arc's party is found by what the arc recorded, not by what a resumer types (Resume 12 through 14). If the gate refuses — the invitation already resolved by a write, lapsed (the atom's derived-expiry refusal, nothing written), or unknown — the call fails before any enrollment: no party enrolled, no credential registered, no identity bound. **One exception, declared** (Action wiring 22): already-resolved carrying accepted where the stored accepting identity reference equals the one supplied and the acceptance is older than the widened bound is not a refusal but the **resume arm** — the caller re-entering an arc that stopped after its gate cleared. A younger acceptance is in flight and is refused (Action wiring 23), and so, at Resume 4, is one whose events may have lawfully aged out.

After the gate the arc runs under the critical section (Action wiring 10 through 16). An invocation that finds its section lost — the host's lease expired, which is its terminus — has yielded the arc; it takes the section again and runs the stage reading as a resume of its own arc before any further write, with one adoption: a completion record for the token is the outcome this caller asked for, reached under another writer, and is answered as its own (Action wiring 16).

**Partial failure after the gate.** An interruption record names the stage at which the sequence stopped. Credential's three refusals are relayed under their own names (Action wiring 31, Action wiring 32 and Audit arm 16) — a caller fault, a state conflict and an infrastructure fault are three different things and are not collapsed. If the interruption record itself fails, the original refusal is still answered (Action wiring 36); the resulting gap — an acceptance record with no later completion or interruption record — is Check 5.2's signature. **duplicate-active-credential reads two ways, by arm** (Action wiring 32 through 35): on the resume arm it is the expected signal that an earlier invocation of the arc registered the credential before it died, and the arm establishes that credential (Resume 39 through 47) rather than taking whichever credential stands active now; the material presented on the resume is discarded, which the resume's answer makes visible, since the credential id answered is the earlier one.

**[Decline].** Invitation's decline records no decliner identity, and neither does this composition (Action wiring 47): the decline record is attested under the service account, and a deployment needing to know who declined records that above the composition, in its own record (Non-goal 5).

**[Revoke].** The revoked by reference attests the revocation, and the revocation reason travels to the constituent and onto the record.

### Wiring decision

```
Wiring decision 1: The composition MUST call Party Identity's enroll ONLY AFTER Invitation's accept answers accepted for the arc.
Wiring decision 2: The composition MUST call Credential's register ONLY AFTER Party Identity's enroll answers the arc's party id.
Wiring decision 3: The composition MUST NOT accept an invitation token a second time.
Wiring decision 4: The composition MUST pass the call's accepting identity reference to Invitation's accept.
Wiring decision 5: A deployment MUST NOT complete an arc's constituent steps outside the composition.
```

WHY:
The principle: no party is enrolled and no credential registered through this composition unless an invitation's accepted transition precedes them — in the same call, or, on the resume arm, in the stopped arc the call re-enters. Invitation's single-resolution invariant is the mechanism that makes the gate hold under concurrent attempts: exactly one [Onboard] clears it, and every other receives already-resolved carrying accepted and creates no constituent record — the accept attempt is its only trace.

The likely objection: *why not let an operator finish a stopped arc by hand — enroll the party, register the credential — rather than build a resume arm?* Because manual completion leaves the party with no completion record, which is the regulator-audit scenario's own failure produced by the recovery. And *why not simply accept again?* Because the gate is single-resolution: the arc it opens can be completed only by re-entering it (Wiring decision 3).

The mechanism: the step order is fixed (Wiring decision 1 and 2); the identity binding is made at accept, with the accepting identity reference the caller supplies at acceptance, not the one the inviter guessed at initiation (Wiring decision 4); and a stopped arc is re-entered by the resume arm, never re-accepted and never finished outside the composition (Wiring decision 5).

The result: invitation-gates-enrollment (Invariant 1) and credential-follows-party (Invariant 3) fall out of the wiring, and the completion record binds the whole arc in one tamper-evident entry (Invariant 5). The constituent atoms are unchanged; the guarantee lives in the order the composition calls them in.

### Resume

```
Resume 1: The resume arm MUST read ONLY AFTER taking the critical section for the invitation token.
Resume 2: IF the host refuses the critical section THEN the resume arm MUST answer storage-failure carrying intent.
Resume 3: A resume arm answering a refusal MUST release the critical section.
Resume 4: IF an aged acceptance EXISTS for the invitation token THEN the resume arm MUST answer invitation-invalid carrying already-resolved AND accepted.
Resume 5: The resume arm MUST NOT read the trail BEFORE ruling out an aged acceptance.
Resume 6: The resume arm MUST read the invitation token's events in sequence order.
Resume 7: IF a completion record EXISTS for the invitation token THEN the resume arm MUST answer invitation-invalid carrying already-resolved AND accepted.
Resume 8: IF a young resume record EXISTS for the invitation token THEN the resume arm MUST answer invitation-invalid carrying already-resolved AND accepted.
Resume 9: IF a dead resume record EXISTS for the invitation token THEN the resume arm MUST read the stage as unrecorded.
Resume 10: IF no dead resume record EXISTS AND an interruption record EXISTS for the invitation token THEN the resume arm MUST read the stage AND the party id from the token's latest interruption record.
Resume 11: IF no acceptance record EXISTS for the invitation token THEN the resume arm MUST read the stage as acceptance-unrecorded.
Resume 12: IF an acceptance record EXISTS AND no interruption record EXISTS for the invitation token THEN the resume arm MUST read the stage as unrecorded.
Resume 13: The resume arm MUST take the arc's recorded documents from the token's acceptance record.
Resume 14: IF no acceptance record EXISTS for the invitation token THEN the resume arm MUST take the arc's recorded documents from the token's accept attempts carrying the call's accepting identity reference.
Resume 15: IF the call's document pair IS NOT IN the arc's recorded documents THEN the resume arm MUST answer invalid-request.
Resume 16: IF the stage EQUALS unrecorded AND no party id stands for the arc THEN the resume arm MUST read Party Identity over the arc's window union.
Resume 17: The resume arm MUST keep a party in the party candidates ONLY IF the party's document pair IS IN the arc's recorded documents AND the party's enrolling actor reference IS IN the arc's actor set.
Resume 18: The resume arm MUST NOT filter the party candidates by the resuming call's enrolling actor reference.
Resume 19: The resume arm MUST NOT filter the party candidates by the party's state.
Resume 20: IF the party reading EQUALS sole AND the call carries no resume party id THEN the resume arm MUST continue with the party candidate as the arc's party.
Resume 21: IF the party reading EQUALS several AND the call carries no resume party id THEN the resume arm MUST answer onboarding-indeterminate carrying the party candidates.
Resume 22: IF the resume party id IS NOT IN the party candidates THEN the resume arm MUST answer invalid-request.
Resume 23: IF the resume party id IS IN the party candidates THEN the resume arm MUST continue with the resume party id as the arc's party.
Resume 24: The composition MUST NOT choose among the party candidates.
Resume 25: IF Party Identity answers invalid-query THEN the resume arm MUST answer invalid-request.
Resume 26: The deployment MUST alert on an invalid-query from Party Identity as the composition's own defect.
Resume 27: The resume arm MUST NOT make a constituent write BEFORE the resume record lands.
Resume 28: The resume arm MUST record a resume record carrying the invitation token, the accepting identity reference, the document type, the document reference, the resumed stage AND the arc's party id where one stands.
Resume 29: IF Audit Trail answers recording-failure carrying a pre-append step at the resume record THEN the resume arm MUST answer storage-failure carrying intent.
Resume 30: IF the stage EQUALS acceptance-unrecorded THEN the resume arm MUST record the acceptance record from the Invitation record.
Resume 31: IF no party id stands for the arc THEN the resume arm MUST call Party Identity's enroll PER Action wiring 26 through 28.
Resume 32: IF a party id stands for the arc THEN the resume arm MUST NOT call Party Identity's enroll.
Resume 33: A resume record MUST pair with the first outcome record following the resume record in sequence order.
Resume 34: IF Audit Trail answers recording-failure carrying the retention step at the resume record THEN the resume arm MUST proceed as landed.
Resume 35: IF Audit Trail answers invalid-credential at the resume record THEN the resume arm MUST answer invalid-credential.
Resume 36: IF Audit Trail answers invalid-request at the resume record THEN the resume arm MUST read the resume record back PER Audit arm 9 through 10.
Resume 37: IF the read-back finds no resume record THEN the resume arm MUST answer storage-failure carrying intent.
Resume 38: A resume arm taking the critical section again MUST run the stage reading again from Resume 4.
Resume 39: The resume arm MUST read EVERY credential carrying the arc's party id as principal reference AND the call's credential type through Credential's read, in any status.
Resume 40: The resume arm MUST keep a credential in the credential candidates ONLY IF the credential IS IN the chain roots AND the credential's registration instant IS IN the arc's window union.
Resume 41: IF the credential reading EQUALS sole AND the call carries no resume credential id THEN the resume arm MUST continue with the credential candidate as the arc's credential.
Resume 42: IF the credential reading EQUALS none THEN the resume arm MUST answer onboarding-indeterminate carrying the credential candidates.
Resume 43: IF the credential reading EQUALS several AND the call carries no resume credential id THEN the resume arm MUST answer onboarding-indeterminate carrying the credential candidates.
Resume 44: IF the resume credential id IS NOT IN the credential candidates THEN the resume arm MUST answer invalid-request.
Resume 45: IF the resume credential id IS IN the credential candidates THEN the resume arm MUST continue with the resume credential id as the arc's credential.
Resume 46: The composition MUST NOT choose among the credential candidates.
Resume 47: A resume arm answering onboarding-indeterminate carrying the credential candidates MUST record an interruption record carrying the invitation token, the accepting identity reference, the party id, credential-registration as the stage AND onboarding-indeterminate as the reason.
```

Term resume arm: the [Onboard] path a resumable acceptance takes — a caller-authenticated re-entry of an arc that stopped after the arc's gate cleared, one resumer per token under the critical section.

Term aged acceptance: an accepted invitation whose `acceptance instant + audit horizon − clock offset allowance` PRECEDES now — an arc whose events may have been lawfully destroyed.

Term outcome record: a completion record or an interruption record.

Term young resume record: the token's latest resume record, followed by no completion record and no interruption record, whose `recording instant + widened bound` DOES NOT PRECEDE now — a resume in flight, or one that died inside the bound, which the records cannot tell apart.

Term dead resume record: the token's latest resume record, followed by no completion record and no interruption record, whose `recording instant + widened bound` PRECEDES now.

Term stage: acceptance-unrecorded | unrecorded | party-enrollment | credential-registration — where the resume arm finds the arc stopped: the acceptance record never landed; the acceptance landed and nothing after it says where the arc stopped; or the stage an interruption record names.

Term arc's recorded documents: the document type and document reference pair on the token's acceptance record, or, where that record is absent, the pairs on the token's accept attempts carrying the call's accepting identity reference — a set, a superset in the safe direction.

Term document pair: a document type with the document reference beside it.

Term arc's window union: one window per anchor — the anchors being the invitation's acceptance instant and the recording instant of every resume record for the token — each from `anchor − clock offset allowance` to `anchor + widened bound`, both ends included; one read from the earliest lower edge to the latest upper edge is a superset of the union and serves.

Term arc's actor set: the actor references of the token's acceptance record and resume records and, where the acceptance record is absent, of the token's accept attempts.

Term party candidates: the party ids the resume arm's party read keeps, when more than one party matches the arc.

Term party reading: none | sole | several — how many parties the resume arm's party read keeps.

Term chain roots: the credentials Resume 39's read answers whose credential id no credential the read answers carries as successor credential id — the credentials a register created, never a rotate.

Term credential candidates: the credential ids the resume arm's credential read keeps under Resume 40.

Term credential reading: none | sole | several — how many credentials the resume arm's credential read keeps.

WHY:
**Why the arm exists.** The gate is single-resolution, so the arc it opens can be completed only by re-entering it, never by accepting again. The resume arm establishes from the records where the arc stopped and **re-runs** the remaining steps under the caller's own identity — it never re-emits a record it cannot re-derive, and it never enrolls beside a party the arc already created without saying so.

**One resumer per token** (Resume 1 through 3). The gate that admitted the resumer has already fired, so two resumers with one acceptor, both past the bound, are two callers no constituent can tell apart, and every pre-check below is a look-then-write both would pass. The whole arm therefore runs under the critical section; every read is made under it, never before it, and a stalled original still holding it is refused, not raced, until its lease expires (the section titled *A compensator is exclusive* in `pressure-testing.md`).

**Bound the arc, then read the stage** (Resume 4 through 12). The upper edge comes first: past the audit horizon a completion record whose payload the purge has made unreadable is not absent — it is purged — and a leg that read it as absent would complete the arc a second time (the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md`). A completion record means the arc finished and a second caller with the same acceptor is not a resumer. A young resume record draws the same refusal a young acceptance draws, for the same reason. A dead one makes the stage unrecorded whatever the earlier records say — the dead resume may have enrolled a party before it wrote anything more — so the party read runs with its recording instant among the anchors.

**Find the party the trail does not name** (Resume 16 through 26). Party Identity's own contract calls its enrollment-instant range *advisory wall-time metadata — under clock skew its result set is best-effort*, so the widened range is a **narrowing** read and what decides is the exact-field filter run composition-side over it (the section titled *A stamp from another seam never decides a write alone* in `pressure-testing.md`). The filter matches the arc's recorded documents — the values the trail recorded, never the resumer's inputs, which Resume 15 has already required to match them — and the arc's actor set, not the resumer's own reference (Resume 18): the arc may have been begun by one actor and be finished by another, an administrator completing what a service account began, and a filter on the resumer would find nothing and enroll again. The accept attempts widen the actor set where the acceptance record is absent, a superset that can only widen the party candidates toward onboarding-indeterminate, never narrow them toward a silent second enrollment. The party candidates are **not** filtered by state (Resume 19): a party the arc enrolled and someone has since closed is still the arc's party, and excluding it would enroll a second one; the administrator choosing among party candidates sees the state and decides. Where several parties are, by their fields, the same person enrolled twice inside one arc, the composition does not choose (Resume 24); an administrator does, and re-invokes with a resume party id. Party Identity's invalid-query is reachable only from a query this composition built, so it is the composition's own defect, answered as invalid-request and alerted (Resume 25 and 26).

**Record the resumption before any constituent commit** (Resume 27 through 29). The resume record is the plan: the stage the records established, the arc's recorded documents re-recorded so a later resume matches against a record that survives even if the acceptance record never landed, and the party the resume continues with. It commits nothing, so a pre-append failure there — and an invalid-request whose read-back finds no record — is intent, not outcome, and the resume is retried whole; the retention step proceeds as landed, as a post-write record's does (Resume 34 through 37). A resume arm that loses the critical section runs the stage reading again before any further write (Resume 38).

**Re-run from the stage** (Resume 30 through 33). An absent acceptance record is re-derivable in full from the Invitation record — the token and the accepting identity reference — so writing it now is re-derivation, not fabrication. The completion record the resume writes is the arc's completion, attested by the resumer (Composes 14); the resume record before it is what tells a reader the arc was completed by a re-entry rather than in one pass. Under the critical section a resume record pairs exactly with the first completion or interruption record after it (Resume 33), because one writer per token at a time is what the section supplies.

**Find the credential the arc registered** (Resume 39 through 47). A duplicate-active-credential on the resume arm says that a credential of the call's type stands active for the arc's party, not that the arc registered it. The active credential may be the successor of a rotation made since, or a registration an external writer made under the same principal reference, and between the refusal and the read it may have lapsed or been revoked; a completion record naming it would say the composition registered what the composition never registered (Invariant 3.1). So the arm reads the party's credentials of the type in every status and keeps the chain roots — the records a register created, never a rotate — whose registration instant falls inside the arc's window union: a rotation chain is walked back to its root, and a root outside every window is not the arc's. The registration instant is a stamp from another seam, so the window only narrows, and what decides is the exact fields — the principal reference, the credential type and the successor links (the section titled *A stamp from another seam never decides a write alone* in `pressure-testing.md`). One root is the arc's credential. None, or several — a foreign registration inside the arc's window, or two registrations the arc's own invocations made — is refused with onboarding-indeterminate, as the party read refuses (Resume 21), and an administrator chooses with a resume credential id or clears the principal reference's namespace; the composition does not choose (Resume 46). The refusal lands an interruption record naming the party and the credential-registration stage (Resume 47), so the administrator's re-invocation resumes at that stage and is not refused as a young resume. Check 2.1 through 2.3 stand as written: the auditor walks forward from the credential the arc registered.

## Composition-level invariants

These emerge from the composition; none belongs to a single constituent. Each names the constituent guarantees and the wiring it rests on.

- **Invariant 1 — Invitation gates enrollment.**
  ```
  Invariant 1.1: EVERY enroll the composition makes MUST follow an accepted invitation carrying the arc's accepting identity reference.
  Invariant 1.2: A resumed arc MUST NOT enroll a party beside the arc's party.
  Invariant 1.3: The composition MUST make the duplicate-freedom claim ONLY IF the deployment declares the clock offset allowance AND the critical section.
  ```
  WHY: the acceptance is established in the same call — Invitation's accept answering accepted — or, on the resume arm, by the constituent's own record read after already-resolved carrying accepted. The party read, widened by the allowance and decided on exact fields, with the onboarding-indeterminate refusal where it cannot decide, is what keeps a dead arc's party from being enrolled a second time; the critical section, one resumer per token, is what keeps two live resumers from enrolling once each. Check 7.1 through 7.3 are where a breach of either shows. Rests on Invitation's single-resolution invariant, Wiring decision 1, Resume 16 through 24 and Capability requirement 13 through 17.
- **Invariant 2 — Identity binding at accept, linked by the completion record.**
  ```
  Invariant 2.1: EVERY completion record MUST carry the accepting identity reference the arc's acceptance bound.
  Invariant 2.2: The composition MUST NOT take an accepting identity reference from an [Invite] call.
  ```
  WHY: the binding itself is Invitation's — its accept records the accepting identity reference permanently, at acceptance, and the inviter commits to no identity at initiation. What the composition adds is the linkage: the party enrollment produces is tied to that reference on the completion record, so the path from any enrolled party back to the invitation that authorized it runs through the trail. Rests on Wiring decision 4 and Action wiring 37.
- **Invariant 3 — Credential follows party.**
  ```
  Invariant 3.1: EVERY credential the composition registers MUST name the arc's party id as the credential's principal reference.
  ```
  WHY: the arc's party is the one the same call enrolled, or, on the resume arm, the one the stage reading establishes from the records. A credential registered through this composition always has a party record as its subject. Rests on Wiring decision 2 and Action wiring 29.
- **Invariant 4 — Audit coverage as safety plus detectability.**
  ```
  Invariant 4.1: EVERY accepted, declined AND revoked write through the composition MUST stand as a covered transition.
  Invariant 4.2: EVERY invitation the composition initiates MUST stand as a covered initiation.
  Invariant 4.3: The composition MUST make the coverage claim ONLY IF the arc lies inside the audit horizon.
  Invariant 4.4: An invitation token MUST NOT carry two completion records.
  Invariant 4.5: A party id MUST NOT appear on the completion records of two invitation tokens.
  ```
  Term covered transition: a terminal invitation write whose record exists, or whose absent record is a gap signature Check 5.1 through 5.3 or Check 6.1 enumerates.

  Term covered initiation: an invitation whose initiated record exists, or whose absent record is Check 6.2's gap signature.

  WHY: the claim is not that a recording step cannot fail — each action's arms admit it — but that no terminal transition through this composition is *silently* invisible: the absent record is itself detectable evidence. A call clearing the gate produces the accept attempt and the acceptance record and, on success, the completion record; on partial failure an interruption record names the stage where that record itself could land; a resumed arc also carries the resume record that preceded its re-run. Past the audit horizon an arc whose events were lawfully purged reads as destruction — the substrate's Retention Window record in its purged state — never as a recording failure. A second completion or a second party for one token is a second writer, which the critical section forecloses and Check 7.1 through 7.3 report. Rests on Audit arm 1 through 13, Action wiring 36 and Capability requirement 13 through 17.
- **Invariant 5 — The completion record names the full arc.**
  ```
  Invariant 5.1: EVERY completion record MUST carry the invitation token, the accepting identity reference, the party id AND the credential id.
  ```
  WHY: from this single record an investigator traverses the full arc — the Invitation record by token, the party record by party id, the credential record by credential id — with no correlation index; each lookup is keyed by the event's own fields. The traversal holds inside the audit horizon; past it, the purged completion payload is lawfully unreadable, and the surviving attestation fields plus the undeletable constituent records are the post-horizon evidence. Rests on Composition state 2 and 4 and Action wiring 37.

---

## Examples

### New employee onboarding — happy path

An HR (human resources) administrator invites a new hire who does not yet have a system identity:

```
invite(
  inviter_ref:         "hr_admin_h01",
  invitee_ref:         null,
  context:             "org::acme::dept::engineering",
  ttl:                 604800,
  actor_credential:    <hr_admin_h01's credential>
) → invitation_token: "tok_inv_g7h2k1"
```

Internally: Audit Trail records `invitation.initiate-attempt` (the credential gate clears). Invitation creates the record in `Pending` with `expires_at = now + 7 days`. Audit Trail records `invitation.initiated` carrying `tok_inv_g7h2k1`. The HR system emails the new hire a link embedding the token.

On their first day, the new hire presents the token via the onboarding portal. The portal calls:

```
onboard(
  invitation_token:         "tok_inv_g7h2k1",
  accepting_identity_ref:   "newhire@acme.com",
  name:                     "Amara Osei",
  date_of_birth:            "1990-05-12",
  document_type:            "passport",
  document_ref:             "doc_p_a01",
  credential_type:          "password",
  credential_material:      <the raw password>,
  expires_at:               null,
  enrolling_actor_ref:      "system_onboarding_svc",
  actor_credential:         <service account credential>
) → {party_id: "party_4421", credential_id: "cred_7791"}
```

Internally: Audit Trail records `onboarding.accept-attempt` (the service account's credential gate clears). `Invitation.accept("tok_inv_g7h2k1", "newhire@acme.com") → accepted`. Audit Trail records `onboarding.invitation-accepted`. `Party Identity.enroll(...)` → `party_4421`. `Credential.register(principal_ref="party_4421", credential_material=<the raw password>, credential_type="password")` → `cred_7791`. Audit Trail records `onboarding.completed: {tok_inv_g7h2k1, newhire@acme.com, party_4421, cred_7791}`.

The party is in `Unverified` state. The HR team proceeds to the Customer Onboarding verification workflow to drive the `Party Identity.verify` call that produces the `Verified` transition.

### Concurrent acceptance attempt — the same acceptor, still in flight

A duplicate browser tab submits the same acceptance while the first call is still running:

```
onboard(
  invitation_token:       "tok_inv_g7h2k1",
  accepting_identity_ref: "newhire@acme.com",
  ...
) → rejected(invitation-invalid(already-resolved(Accepted)))
```

Internally: the accept attempt lands, the record of the try; then `Invitation.accept("tok_inv_g7h2k1", "newhire@acme.com")` answers already-resolved carrying accepted. The composition reads the invitation and finds the same acceptor, but an acceptance younger than the widened bound — an arc still in flight, whose own invocation holds the critical section — so it refuses (Action wiring 23). No party is enrolled and no credential registered; the attempt event is the only trace. This is the race worth showing, because the same acceptor is the one the resume arm would admit once the bound has passed; a *different* acceptor is refused the same way at any age, by Invitation's single-resolution invariant alone.

### Invitation revoked before use

An administrator discovers an invitation should not have been issued:

```
revoke(
  invitation_token: "tok_inv_c2d8e3",
  revoked_by_ref:   "admin_a01",
  reason:           "contractor-engagement-cancelled",
  actor_credential: <admin_a01's credential>
) → revoked
```

Any subsequent [Onboard] attempt with `tok_inv_c2d8e3` returns `rejected(invitation-invalid(already-resolved(Revoked)))`.

### Invitation declined

```
decline(
  invitation_token:   "tok_inv_p4q9r2",
  service_actor_ref:  "system_onboarding_svc",
  actor_credential:   <service credential>
) → declined
```

---

### Regulated adversarial scenarios

**Regulator audit.** A HIPAA compliance officer asks: *"Can you prove that every user who currently has access to the system was admitted via a documented invitation from an identified, authenticated internal actor — and that the actor was permitted to admit them?"* The auditor queries the Audit Trail for all `onboarding.completed` events. Each event carries `{invitation_token, accepting_identity_ref, party_id, credential_id}`. For each `party_id` in the system with an active credential, the auditor confirms a corresponding `onboarding.completed` event exists in the Audit Trail (Invariant 4) — walking the active credential's rotation chain back through predecessor records to the `credential_id` the event names, since the credential registered at onboarding has usually been rotated since (Generation acceptance check 2). The Invitation record for each invitation_token names the inviter_ref — the actor whose credential the `invitation.initiate-attempt` record verified. Invariant 1 (invitation gates enrollment) is the structural guarantee: the `onboarding.completed` event is only produced if `Invitation.accept` succeeded, and the Invitation record names who *issued* the access, authenticated and attributed. The second half of the regulator's question — whether that actor was *permitted* to — is answered from the composed Permissions instance's records for `invitations:initiate` at the invitation's `initiated_at`, not from this composition's, which never checks it (Edge cases — *Inviter and revoker authorization*). Both halves are answerable from records alone; they are two records, not one.

**Disputed onboarding.** A former employee claims: *"My account was created without my knowledge — I never accepted an invitation."* The investigator queries the Audit Trail for `onboarding.completed` events whose `party_id` matches the former employee's record. The event is found. The Invitation record for the invitation_token in that event shows inviter_ref (who sent it), accepting_identity_ref (the external reference supplied at acceptance time), and `accepted_at` (when the acceptance was committed). Invariant 2 (identity binding at accept) is the structural guarantee: the accepting_identity_ref was supplied by the caller at `Invitation.accept` time, not pre-populated by the inviting actor. Whether the former employee personally presented the token or whether someone else held the token and supplied the reference is outside the composition's scope — the composition records that a bearer of `tok_inv_g7h2k1` presented the invitation and supplied `accepting_identity_ref: "newhire@acme.com"`. Further investigation of who actually controlled that email address at that moment belongs to Party Identity's identity proofing concept (Customer Onboarding) or a breach forensics investigation.

**Breach forensics.** An investigator determines that an onboarding service account's credential was compromised during a window. The question is: were any fraudulent onboardings performed using the compromised credential? The investigator joins by token, not by the completion's actor: the `onboarding.completed` event's `actor_ref` is the resumer's where an arc was resumed, so a completion attested by an uncompromised administrator can still belong to an arc the compromised account began. The investigator queries the Audit Trail for `onboarding.accept-attempt` and `onboarding.invitation-accepted` events whose `actor_ref` matches the compromised service account within the compromise window, takes their invitation_tokens, and joins each to the token's `onboarding.completed` event. Each such event names `{invitation_token, accepting_identity_ref, party_id, credential_id}`. The investigator cross-references: do the invitation_token values correspond to invitations issued by authenticated inviting actors — and, against the composed Permissions instance's records, by actors permitted to invite at the time? The `invitation.initiated` event for each token names the inviter_ref, and its actor_credential attestation is independently verifiable — this is the record that carries the token, which is what makes the correlation executable from the trail alone. Any `onboarding.completed` event whose token has no `invitation.initiated` event through the composition, or whose inviter's attestation fails, is a candidate fraudulent onboarding. Invariant 4 (full Audit Trail coverage) and Invariant 5 (completion record names the full arc) together make this forensic reconstruction possible from records alone.

---

## Generation acceptance

An implementation of External Onboarding is accepted if an external auditor can clear the conformance checks below from the Audit Trail and the constituent records alone, without recourse to source code, runbooks or developer narration, reading under the standing rules; the external checks name the deployment facts no record carries.

### Conformance checks

```
Check 1.1: An auditor MUST find the invitation token of EVERY completion record naming an invitation whose status EQUALS accepted (Invariant 1.1).
Check 1.2: An auditor MUST find the acceptance instant preceding the completion record's recording instant PER the clock offset allowance (Invariant 1.1).
Check 1.3: An auditor MUST find the completion record's accepting identity reference equal to the invitation's (Invariant 2.1).
Check 2.1: An auditor MUST find the credential id of EVERY completion record naming a credential, in any status, whose principal reference equals the completion record's party id (Invariant 3.1).
Check 2.2: An auditor MUST find EVERY link of a rotated credential's successor chain carrying the same principal reference (Invariant 3.1).
Check 2.3: An auditor MUST NOT require the registered credential to stand active (Invariant 3.1).
Check 3.1: An auditor MUST find no registration instant preceding the party's enrollment instant for a completion record's credential PER the clock offset allowance (Wiring decision 2).
Check 4.1: An auditor MUST find no acceptance record for an invitation whose status DOES NOT EQUAL accepted (Invariant 1.1).
Check 4.2: An auditor MUST find no completion record without an acceptance record for the invitation token (Invariant 1.1).
Check 5.1: An auditor MUST enumerate EVERY accepted invitation carrying no acceptance record (Invariant 4.1).
Check 5.2: An auditor MUST enumerate EVERY acceptance record followed by no completion record AND no interruption record for the invitation token (Invariant 4.1).
Check 5.3: An auditor MUST enumerate EVERY interruption record followed by no completion record for the invitation token (Invariant 4.1).
Check 5.4: An auditor MUST NOT read a resume record as closing a gap signature (Resume 33).
Check 6.1: An auditor MUST find a decline record for EVERY declined invitation AND a revoke record for EVERY revoked invitation (Invariant 4.1).
Check 6.2: An auditor MUST find an initiated record carrying the invitation token for EVERY invitation (Invariant 4.2).
Check 6.3: An auditor MUST find EVERY initiated record naming an invitation that exists (Invariant 4.2).
Check 6.4: An auditor MUST NOT read an initiate attempt as a per-invitation signature (Action wiring 3).
Check 7.1: An auditor MUST find no invitation token carrying two completion records (Invariant 4.4).
Check 7.2: An auditor MUST find one party id across a token's completion record, credential-registration interruption records AND resume records (Invariant 1.2).
Check 7.3: An auditor MUST find no party id on the completion records of two invitation tokens (Invariant 4.5).
Check 7.4: An auditor MUST report a second writer as a conformance failure (Invariant 1.3).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the onboarding completion bound confirmed MUST read the deployment's own configuration (Capability requirement 5).
External check 2: An auditor needing the clock offset allowance confirmed MUST read the deployment's own configuration (Capability requirement 7).
External check 3: An auditor needing the audit horizon confirmed MUST read the Audit Trail instance's retention policy (Capability requirement 9).
External check 4: An auditor needing the minted-id width bounds confirmed MUST read the deployment's own declaration (Capability requirement 11).
External check 5: An auditor needing the critical section's cross-node exclusion confirmed MUST read the deployment's own host (Capability requirement 14).
External check 6: An auditor needing the lease length confirmed MUST read the deployment's own host (Capability requirement 17).
External check 7: An auditor needing the routing obligation confirmed MUST read the deployment's own wiring (Composes 9).
External check 8: An auditor needing an actor reference's authorization confirmed MUST read the composed Permissions instance's records (Non-goal 2).
External check 9: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 6).
```

### Standing rules

```
Standing rule 1: An auditor MUST read a payload-keyed query as an enumerate-and-filter over the substrate's sequence-range read.
Standing rule 2: An auditor MUST compare two seams' stamps PER the clock offset allowance.
Standing rule 3: An auditor MUST read a discrepancy inside the clock offset allowance as inconclusive.
Standing rule 4: An auditor MUST quantify an Invitation-store check over the dedicated Invitation instance alone.
Standing rule 5: An auditor MUST quantify a trail-walking check over the arcs inside the horizon.
Standing rule 6: An auditor MUST read a purged event as lawful destruction.
Standing rule 7: An auditor MUST read a record younger than the widened bound as inconclusive.
Standing rule 8: An auditor MUST join records on the invitation token.
Standing rule 9: An auditor MUST NOT pair an attempt record with an outcome.
```

Term arcs inside the horizon: the invitations whose `acceptance instant + audit horizon − clock offset allowance` — or, for an invitation never accepted, whose `initiation instant + audit horizon − clock offset allowance` DOES NOT PRECEDE the auditor's now — the membership test for an Invitation record under Standing rule 5.

WHY:
Standing rule 6 is the substrate's honest-representation invariant read from the auditor's side: a purged event's Retention Window record in its purged state is the evidence, never a gap signature, and past the horizon the surviving evidence is the attestation's own action reference, actor reference and attestation instant — which the substrate's purge preserves — plus the undeletable constituent records.

Standing rule 7 is the lower edge. Check 5.1 through 6.3 compare a constituent's committed state against records this composition writes later in the same invocation, so an invocation still running reads as a signature; each examines only what is older than the widened bound — the edge the resume arm reads under, widened by the same allowance because the stamps are the constituents'.

Standing rule 8 is exact because the invitation token is a per-invocation key on every post-gate path: Invitation's single resolution lets at most one accept, one decline and one revoke commit per token. The initiate attempt, written before a token exists, carries no per-invocation key by construction and no check pairs it; the other attempts carry the token, and the resume arm reads accept attempts only as a superset source of actors and documents (Standing rule 9).

Check 2.1 through 2.3 establish the binding, not activeness. Credential's rotate moves the prior record to rotated and mints a successor, and revoke retires it; neither unbinds the onboarding the completion record records, and a check that required the registered credential to be active would fail a conforming implementation at its first rotation. So the auditor walks the successor chain to the head and confirms every link names the same party.

Check 7.1 through 7.4 test the condition Invariant 1.3 states from the records: two completions for one token, two parties across one token's records, or one party completed under two tokens is the critical section breached or a skew wider than the allowance carrying a dead arc's party outside the party read's window — a conformance failure, never a tolerated residue.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT authorize an actor reference.
Non-goal 2: A deployment needing an authorized actor reference MUST compose Permissions over the invitation initiate AND invitation revoke scopes.
Non-goal 3: The composition MUST NOT claim that an authorized actor issued an invitation.
Non-goal 4: The composition MUST NOT verify a party.
Non-goal 5: A deployment needing a decliner's identity MUST record the identity above the composition.
Non-goal 6: A deployment needing a verified party MUST compose Customer Onboarding.
Non-goal 7: The composition MUST NOT rotate a credential.
Non-goal 8: The composition MUST NOT check the accepting identity reference against the invitee reference.
Non-goal 9: A deployment needing the accepting identity proven against the invitee reference MUST enforce the proof above the composition.
Non-goal 10: The composition MUST NOT record a refused attempt.
Non-goal 11: A deployment needing refused attempts recorded MUST compose Failed-Attempt Log.
Non-goal 12: The composition MUST NOT index the trail by payload.
Non-goal 13: A deployment needing an indexed payload lookup MUST compose Reverse Index.
```

WHY:
Non-goal 1 through 3 are the gate's limit, stated because a claim made and neither wired nor disclaimed is the worst of three states. The gate **authenticates and attributes; it does not authorize.** The attempt record on [Invite] and [Revoke] verifies the presented credential and attributes the act to the inviter or the revoker, so no invitation or revocation is made on an unverified claim — but nothing in the wiring asks whether that actor was *permitted* to, and no constituent here holds that answer: Invitation takes the inviter reference as opaque, and Audit Trail attests, it does not gate. The authorization gate is a declared above-composition obligation — a [Permissions](../atoms/permissions.md) instance over the invitation initiate and invitation revoke scopes, checked by the caller before [Invite] and [Revoke] or by a wrapping composition such as Session-Gated Authorization or Attributed Permissions Admin, whose records are where *was the inviter authorized?* is answered. Every claim on this page that an invitation was issued by an actor is to be read as *issued by an authenticated, attributed actor*. Gating on a scope would make Permissions a constituent and this composition the owner of an authorization vocabulary it has no other use for.

Non-goal 4 and Non-goal 6 — this composition enrolls the party unverified. The transition to verified is Customer Onboarding's, which calls `Party Identity.verify`; downstream regulated activity that requires a verified party checks the party's state itself.

Non-goal 7 — a principal rotates a credential with `Credential.rotate` directly, outside this composition's surface, and rotation does not disturb the arc's record — the completion record names the credential as registered, and Check 2.2 reaches the current head by the successor chain.

Non-goal 8 and Non-goal 9 — where the inviter supplied an invitee reference — a known email address, say — and the accepting identity reference supplied at [Onboard] differs, the composition neither detects nor blocks the mismatch; Invitation does not relate the two. A deployment requiring proof of control of the invitee reference enforces it before calling [Onboard].

Non-goal 10 through 13 name the two forthcoming patterns this page leans on without composing: the **Failed-Attempt Log** *(forthcoming)* for attempts refused at the gate, which land no event, and the **Reverse Index** *(forthcoming)* for a payload lookup over the trail, which nothing here depends on.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST widen a comparison against another seam's stamp by the clock offset allowance on both sides.
Clock semantics 2: The composition MUST read a widened comparison toward an arc still running.
Clock semantics 3: The composition MUST read a widened horizon comparison toward refusing.
```

WHY:
Wherever this composition compares a reading of its own against a stamp another seam wrote — the gate's resumable acceptance, the resume arm's aged acceptance and young resume record, the party read's window, every cross-store acceptance check — the comparison runs under the allowance, widened symmetrically, and **narrows** a decision rather than making one (the section titled *A stamp from another seam never decides a write alone* in `pressure-testing.md`). The grammar's operators pin the edges the prose left open: PRECEDES is strict, so an acceptance exactly at the widened bound is still running and an event exactly at the horizon edge is still inside it, and the party read's windows include both ends by declaration.

### Concurrency

```
Concurrency 1: Two fresh accepts of one invitation token MUST resolve through Invitation's single resolution.
Concurrency 2: Two resumers of one invitation token MUST resolve through the critical section.
Concurrency 3: A resumer MUST NOT race a holder whose lease has not expired.
```

WHY:
Two callers present one token at once: Invitation's accept is atomic under concurrent attempts, exactly one succeeds, and the loser is refused before any enrollment — Invitation's single-resolution invariant working as the composition's concurrency control. The race the gate cannot see is between two **resumers** — one acceptor, both past the bound — because the gate has already fired for both and answers both alike; that race is closed by the critical section the resume arm runs under and by the young-resume refusal (Resume 8), and a breach of the section is what Check 7.1 through 7.3 report.

### Credential collision on a fresh arc

On a fresh arc the party id was minted at the enroll of this very call, so no earlier registration under it through this composition is possible; duplicate-active-credential there can only be a principal reference collision — an external writer registering credentials under the same principal-reference namespace as this composition's party ids, which the shared-surface posture of Credential admits and this composition cannot see. The composition records the interruption and answers duplicate-active-credential — a state conflict, not an infrastructure failure. The enrolled party exists unverified without a credential of this composition's issuing; administrator review decides whose credential holds the namespace, and the arc is completed by resumption once it is resolved.

### Partial failure

If Invitation's accept succeeds and a later step fails — the acceptance record, Party Identity's enroll, Credential's register or the completion record — the invitation is permanently accepted and cannot be accepted again. It **can be resumed**: a later [Onboard] with the same token and the same accepting identity reference, past the widened bound and inside the audit horizon, takes the resume arm, one resumer per token, establishes the stage from the trail and, where the trail is silent, from the Party Identity store over every window the arc's records anchor, and re-runs the remaining steps under the caller's own authenticated identity behind a resume record. The caller need not be the actor who began the arc. What the resume does **not** do is guess: where the store shows more than one party enrolled by the arc's actors under the arc's recorded documents inside the arc's windows, it refuses with onboarding-indeterminate and an administrator chooses. Manual completion outside the composition is not the recovery (Wiring decision 5); a deployment that performs it produces a party with no completion record — the regulator-audit scenario's failure, by its own hand. Check 5.1 through 5.3 surface the arcs awaiting resumption.

---

## Composition notes

**Relationship to Customer Onboarding.** External Onboarding admits a party to the system in `Unverified` state. Customer Onboarding drives the identity verification workflow that transitions the party to `Verified`. The two compositions address adjacent points in the regulated identity lifecycle: External Onboarding is the admission gate; Customer Onboarding is the verification gate. A deployment requiring `Verified` status before granting access to regulated functionality places Customer Onboarding downstream of this composition in the onboarding pipeline.

**Relationship to Login.** External Onboarding registers the credential. Login uses that credential: `login(principal_ref, credential_type, presented_material, ...)` calls `Credential.verify`, and on success issues a Session. After a successful [Onboard], the principal can immediately call `login` using the registered credential_type and their credential material. The two compositions are adjacent lifecycle boundaries: External Onboarding creates the credential record; Login produces the authenticated session.

**Relationship to Session-Gated Authorization.** Once the onboarded principal has an active session (from Login), runtime authorization queries flow through Session-Gated Authorization: `check_permitted(session_token, action_scope)` gates every permission check on session validity. External Onboarding is the entry point; Session-Gated Authorization is the access-time gate.

**Relationship to Attributed Permissions Admin.** Once onboarded, the principal appears as a subject in Permissions. An authorized actor calls `Attributed Permissions Admin.grant(subject_ref=party_id, action_scope, ...)` to grant the newly onboarded party access to specific scopes. The `party_id` produced by External Onboarding becomes the `subject_ref` in Permissions grants.

**Forthcoming-link resolution.** The Invitation atom's *Composition notes* listed "External Onboarding *(not started)*" as a forthcoming composition. That link is now live. Invitation's `Composition note 2` and `Composition note 3` once asked this composition to pass the accepting identity reference *as the party record's reference* and to register the credential *against the accepting identity reference*; Party Identity mints the party id at its own seam and takes no such input, and the credential is registered against that party id (Invariant 3.1), so this composition links the accepting identity reference to the party on the completion record instead (Invariant 2.1), and Invitation's two notes now say so.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes and the four composition-introduced Audit Trail events that record the arc. It owns no cross-atom state — the Audit Trail *is* the map — so no store carries a term entry. The deployment settings keep their wire spellings in configuration — `onboarding_completion_bound`, `clock_offset_allowance`, `audit_trail_retention_policy`, `per_token_serialization` — and the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; a deployment; an auditor; a caller; an administrator; an investigator; an invocation; an action; an arc; a fresh arc; a resumed arc; the resume arm; a resumer; a completing arc; an attempt record; a post-write record; the read-back; an admitted invite; a landed invite; an admitted onboard; an admitted decline; a landed decline; an admitted revoke; a landed revoke; a refused gate call; an initiate attempt; an initiated record; an accept attempt; an acceptance record; an interruption record; a completion record; a resume record; a decline attempt; a decline record; a revoke attempt; a revoke record; an invitation; a party; a credential; an enroll; the slowest conforming invocation; the seam skew; the longest resume gap; the widened bound; the lease length; the minted-id width bounds.

Term records: the attempt records and post-write records the composition writes through the substrate — each an Audit Trail event carrying one event type below.

Term record verbs: serve, change, inherit, read, hold, route, claim, select, query, attest, declare, make, store, supply, take, mint, set, configure, agree, exclude, release, refuse, answer, validate, record, size, write, stop, proceed, retry, run, match, alert, call, verify, establish, continue, discard, accept, pass, complete, keep, filter, choose, pair, follow, enroll, carry, name, stand, appear, find, require, enumerate, report, compare, quantify, join, authorize, compose, rotate, check, enforce, index, widen, resolve, race.

Term value sets: event type = invitation.initiate-attempt | invitation.initiated | onboarding.accept-attempt | onboarding.invitation-accepted | onboarding.interrupted | onboarding.completed | onboarding.resume-intended | invitation.decline-attempt | invitation.declined | invitation.revoke-attempt | invitation.revoked. The rest are declared where the section that owns each declares it: position, stage, candidate reading.

Term bounds: onboarding completion bound (onboarding_completion_bound), clock offset allowance (clock_offset_allowance), audit horizon (audit_trail_retention_policy), widened bound, minted-id width bounds, lease length.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, substrate, trail, completion relation, onboarding completion bound, clock offset allowance, widened bound, audit horizon, minted-id width bounds, critical section, lease length, slowest conforming invocation, seam skew, longest resume gap, required input, actor reference, actor credential, credential material, resume party id, resume credential id, resume choice, service actor reference, attempt record, post-write record, pre-append step, retention step, read-back, position, onboarding result, invitation refusal, candidates, validated invite, admitted invite, landed invite, validated onboard, admitted onboard, arc, fresh arc, resumable acceptance, stage reading, completing arc, validated decline, admitted decline, landed decline, validated revoke, admitted revoke, landed revoke, revocation reason, resume arm, aged acceptance, outcome record, young resume record, dead resume record, stage, arc's recorded documents, document pair, arc's window union, arc's actor set, party candidates, party reading, chain roots, credential candidates, credential reading, covered transition, covered initiation, arcs inside the horizon, initiate attempt, initiated record, accept attempt, acceptance record, interruption record, completion record, resume record, decline attempt, decline record, revoke attempt, revoke record.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the conforming, no-stored-state classification. record_action, read_record, proceed as landed, compliance alert, reference length cap, payload cap, recording instant, event id, action reference: Audit Trail. invitation token, accepting identity reference, acceptance instant, initiation instant, expiry bound, stored terminal, status, inviter reference, invitee reference, context, revoked by reference, ttl bounds: Invitation. party id, enrollment instant, enrolling actor reference, document type, document reference, name, date of birth: Party Identity. credential id, credential type, principal reference, registration instant, expiry instant: Credential.

Term composing patterns: Failed-Attempt Log *(forthcoming)*; Reverse Index *(forthcoming)*; [Permissions](../atoms/permissions.md); [Customer Onboarding](./customer-onboarding.md).

Term initiate attempt: the invitation.initiate-attempt event — [Invite]'s attempt record.

Term initiated record: the invitation.initiated event — [Invite]'s post-write record, carrying the invitation token.

Term accept attempt: the onboarding.accept-attempt event — [Onboard]'s attempt record.

Term acceptance record: the onboarding.invitation-accepted event — an [Onboarding Invitation Accepted].

Term interruption record: the onboarding.interrupted event — an [Onboarding Interrupted].

Term completion record: the onboarding.completed event — an [Onboarding Completed].

Term resume record: the onboarding.resume-intended event — an [Onboarding Resume Intended].

Term decline attempt: the invitation.decline-attempt event — [Decline]'s attempt record.

Term decline record: the invitation.declined event — [Decline]'s post-write record.

Term revoke attempt: the invitation.revoke-attempt event — [Revoke]'s attempt record.

Term revoke record: the invitation.revoked event — [Revoke]'s post-write record.

#### Invite

The composition action that initiates an invitation from an authenticated, attributed actor to an external party — the initiate attempt first, whose attestation is the credential check, then Invitation's initiate, then the initiated record carrying the token — answering the invitation token the inviter delivers out of band (Action wiring 3 through 7).

Kind: Operation

#### Onboard

The composition's load-bearing action: accept an invitation and, in one fixed sequence gated by Invitation's accept, enroll the invitee as an unverified party and register the party's credential — recording the [Onboarding Invitation Accepted], then the [Onboarding Completed], or the [Onboarding Interrupted] on a failure past the gate. A stopped arc is re-entered through the resume arm — one resumer per token under the critical section, bounded below by the widened bound and above by the audit horizon — never re-accepted (Action wiring 8 through 39, Resume 1 through 38). No enrollment occurs unless the gate clears (Invariant 1).

Kind: Operation

#### Decline

The composition action that records an invitee's deliberate refusal of an invitation through Invitation's decline and attests it under the system service account (Action wiring 40 through 47).

Kind: Operation

#### Revoke

The composition action that withdraws a pending invitation before the invitee acts, through Invitation's revoke, attributing the revocation to the revoking actor (Action wiring 48 through 55).

Kind: Operation

#### Onboarding Invitation Accepted

The Audit Trail event [Onboard] records when Invitation's accept clears the gate — carrying the invitation token, the accepting identity reference, and the document type and document reference the arc enrolls under, which a resume matches the Party Identity store against. An accepted invitation with no such event is Check 5.1's gap signature.

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.invitation-accepted

#### Onboarding Completed

The Audit Trail event [Onboard] records on a completed arc — naming the invitation, the accepting identity, the party record and the credential in one tamper-evident entry. The records-alone answer to *what invitation authorized this party's creation?* (Invariant 5.1).

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.completed

#### Onboarding Interrupted

The Audit Trail event [Onboard] writes when a step past the gate fails — Party Identity's enroll or Credential's register — naming the stage and the reason, so a partial onboarding is detectable and resumable rather than silent (Action wiring 27 and 30).

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.interrupted

#### Onboarding Resume Intended

The Audit Trail event the resume arm writes before it re-runs a stopped arc — naming the stage the records established and the party the resume continues with, if one — so a completion reached by re-entry is distinguishable from one reached in a single pass, and a resume that itself died is visible as a plan without an outcome: the next resume reads it as a stage unrecorded and, while it is younger than the widened bound, as a resume in flight (Resume 8, Resume 9 and Resume 28).

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.resume-intended

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Invite]: #invite
[Onboard]: #onboard
[Decline]: #decline
[Revoke]: #revoke
[Onboarding Invitation Accepted]: #onboarding-invitation-accepted
[Onboarding Completed]: #onboarding-completed
[Onboarding Interrupted]: #onboarding-interrupted
[Onboarding Resume Intended]: #onboarding-resume-intended

---

## Standards references

*Anchors: GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Articles 6–7 (lawful basis for processing at invitation and acceptance time); HIPAA (US Health Insurance Portability and Accountability Act) §164.312(a)(1) (access control — invitation-based provisioning as a covered access-granting event) + §164.312(d) (person or entity authentication — credential registration at onboarding); SOC 2 (Service Organization Control 2 — an audit standard for service-provider security controls) CC6.2 (prior to issuing system credentials, new internal and external users are registered and authorized); NIST (National Institute of Standards and Technology) SP (Special Publication) 800-63A (identity enrollment and identity proofing — the enrollment arc); SCIM 2.0 (System for Cross-domain Identity Management) RFC 7644 (RFC — Request for Comments, the IETF’s, Internet Engineering Task Force’s, numbered standards series — the invite-then-provision flow); FATF (Financial Action Task Force — the international anti-money-laundering standard-setter) Recommendations 10–12 (customer due diligence at onboarding — Party Identity in Unverified state is the enrollment record the regulator requires; verification belongs to Customer Onboarding).*

**GDPR Articles 6–7** require a lawful basis for processing personal data. The [Invite] action creates the first processing record: the system holds invitee_ref and processes data about the invitee from that moment. The [Onboard] action creates the accepting_identity_ref binding and the Party Identity enrollment — the data subject's active engagement with the system. The Audit Trail records both as the GDPR Article 5(2) accountability records.

**SOC 2 CC6.2** requires that prior to issuing system credentials, new users are registered and authorized. The composition supplies the *registration* half and the *ordering* structurally: `Party Identity.enroll` (registration) precedes `Credential.register` (credential issuance), and both are preceded by `Invitation.accept` — and the invitation itself by [Invite], whose initiated record attributes it to an authenticated inviting actor. The *authorization* half — that the inviting actor was permitted to admit this user — is not something this composition checks or records: its gate verifies the inviter's credential and attributes the act, and whether the inviter held the authority is the composed Permissions instance's record (Non-goal 1 and Non-goal 2). A CC6.2 claim rests on both records together, and a deployment that wires no authorization gate above [Invite] has the ordering and the attribution but not the authorization.

**NIST SP 800-63A** defines the enrollment event at which an applicant registers with an identity system. The [Onboard] action is that enrollment event. The composition does not perform identity proofing (the transition from Unverified to Verified in Party Identity) — that belongs to Customer Onboarding. The composition records the enrollment inputs (name, date_of_birth, document_type, document_ref) and the enrolling actor, satisfying 800-63A's enrollment record requirements.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: external-onboarding.tla, no twin, verified 2026-06-03 over a single-pass arc with no resume; re-derive over two resumers and a stalled original as processes over one token, the per-token section as the point past which only one can write (2026-08-29-a, 2026-08-30-p)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 6 foundational corrected in-round, 13 refining and 3 rhetorical routed (2 refining since closed), 5 foundational closure residue corrected in a second pass; 2026-08-26 — Final Critique 7, fresh reader — 6 foundational (all since closed), 10 refining, 3 rhetorical

open:
- 2026-08-29-a · refining · formal · `external-onboarding.tla` predates the resume arm and the step-split landings → extend the model with the resume path, its in-flight bound, and the step-4 proceed arm
- 2026-08-30-p · refining · formal · the model has one resumer, no per-token section, and no stalled original; the second writer is unrepresentable → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/external-onboarding.md`.

- **2026-09-23 — The resume arm completes with the credential the arc registered, never the credential standing active.** *Chose:* on duplicate-active-credential the resume arm reads the party's credentials of the call's type in every status, keeps the chain roots registered inside the arc's window union, continues with a sole root, and refuses none or several with onboarding-indeterminate carrying the credential candidates, behind an interruption record, with a resume credential id for the administrator's choice (Resume 39 through 47). *Over:* naming the head — the credential standing active — and widening Check 2 to accept any link of the head's chain. *Because:* the head can be a rotation successor or a foreign registration, so a completion record naming the head records what the composition did not do, against Invariant 3.1; walking back keeps Check 2.1 through 2.3 true as written. The maintainer's ruling on 2026-08-30-d.
- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-one of twenty-four open Ledger lines closed by the rules that now own them, and nothing else changed but what each line asked for.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and a `Resume` family for the resume arm as the surfaces; invariant numbers 1 through 5 unchanged; the seven prose checks kept as `Check 1.1` through `Check 7.4`, grouped by their old numbers, with the standing rules as a `Standing rule` family; `Non-goals` and `Edge cases` split; Standards renamed Standards references and moved to its place. The lines' own fixes, taken as the ledger prescribed them: the validation depth pinned pre-gate against each constituent's field rules (2026-08-26-f, Primitive policy 3 and 4); the decliner's identity declared unrecorded (2026-08-26-e, Action wiring 47, Non-goal 5); Invariant 2 re-scoped to the completion record's linkage (2026-08-26-i); the substrate's third invalid-request source named, Actor Identity's arm at the substrate's second step, and the read-back floored at the invocation's own attempt record (2026-08-30-c, Audit arm 8 through 12); Party Identity's invalid-query landed as the composition's own defect (2026-08-30-e, Resume 25 and 26); the candidates declared unfiltered by state, since a closed party the arc enrolled is still the arc's party (2026-08-30-k, Resume 19); every alert named onto the deployment's alerting surface (2026-08-30-l); the relation's cardinality and modality declared (2026-08-30-h); the comparisons' edges pinned by the operators (2026-08-30-f); an operational membership test for the horizon (2026-08-30-g); *rests on* in every invariant's WHY (2026-08-30-i); the examples' credential call matched to the atom's raw-material model and the concurrent example changed to the same-acceptor race (2026-08-26-k, 2026-08-30-o); acronyms glossed and the SOC 2 attribution corrected (2026-08-26-j, 2026-08-30-j, 2026-08-30-m); and the mismatch with Invitation's `Composition note 2` and `Composition note 3` noted here and corrected there (2026-08-30-n). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Three stay open: the resume arm's credential read-back (2026-08-30-d), which wants a design choice between walking predecessors and naming the head, and the two formal lines.
- **2026-08-30 — One resumer per token, the arc bounded at both edges, the dead resume's party found by the arc's actors, the skew declared, the position on the code.** *Chose:* a deployment-supplied `per_token_serialization` the resume arm holds from R1's first read to its return and the fresh arc takes at step 3's `accepted` arm and holds to its return, with stated lease semantics — released on return or death, a lease at least the widened bound long whose expiry is the invocation's terminus, every write after the first made only under the section, and an invocation that lost it re-taking it and re-running R1–R2 as a resume of its own arc before writing again — so two resumers never both enroll and a stalled original is refused until its lease expires; the arc's document_type and document_ref recorded on `onboarding.accept-attempt`, `onboarding.invitation-accepted`, and `onboarding.resume-intended`, R2 matching the store against the recorded pair and a resumer whose inputs differ refused; R4 taking the post-write landings with `step-4` proceeding as landed; with R1 refusing a successor-less `onboarding.resume-intended` younger than the bound and check 7 condemning two completions or two parties per token; an upper edge on the resume arm — `accepted_at` older than `audit_trail_retention_policy`'s horizon is refused, since a purged completion is not an absent one; R1 reading a dead resume's `onboarding.resume-intended` as *stage unrecorded* and R2 reading the union of windows anchored at `accepted_at` and at every resume-intended's `recorded_at`; R2 filtering on the arc's actor set from the trail rather than the resumer's identity; a `clock_offset_allowance` widening every cross-seam comparison — step 3's bound, R1's edges, R2's window, the standing rule — with Invariant 1's duplicate-freedom made conditional on it; resume_party_id on a `Pending` invitation refused at step 1 by a read before the gate; and `storage-failure(intent | outcome)` on all four signatures, the relayed constituent tokens taking the position by the same test. *Over:* a resume arm whose only gate had already fired for every resumer; a section claimed in Configuration that no fresh-arc step took, with no release, expiry, or re-take rule; a party matched on documents the resumer typed; a leg with a lower edge and no upper one; a stage read from `onboarding.interrupted` alone and a window anchored at `accepted_at` alone; "equal this invocation's" against "re-run under the caller's own identity"; a write decision on a read the constituent calls best-effort; a declared rejection no step evaluates; and a bare token on both sides of the commit. *Because:* the gate serializes the one write to `Accepted` and nothing after it, so two re-entries are two writers the atom cannot tell apart; a section with no terminus lets a stalled holder block the arc forever and a lost one lets its holder write between a resumer's pre-check and its append; and a filter on the resumer's inputs finds a different person's party or none; a lawfully destroyed completion read as absent completes the arc twice; a resume that enrolled and died leaves its party outside every window the original arc anchors; an administrator finishing a service account's arc is the recovery the edge case names, and a filter on the resumer finds nothing; a stamp another seam wrote can differ from this one's by a sign the bound does not have; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A reconciliation is bounded at both ends*, §*Recovery commits under a declared service identity*, and §*Lawful destruction is answered before absence*; *Liveness is arithmetic* and *An outcome is sized before the intent* were swept and found no shape here beyond naming the resume payloads in step 1's sizing).
- **2026-08-29 — The gate can be re-entered but never re-accepted, and the substrate's arm keeps its step.** *Chose:* a resume arm on [Onboard] — same acceptor, acceptance older than a declared `onboarding_completion_bound`, stage established from the trail and then from the Party Identity store, candidates named where the store cannot decide, an `onboarding.resume-intended` record before any commit, then the remaining steps re-run under the caller's own identity; and every `record_action` transcription carrying `recording-failure(step)`, with the `step-4` arm proceeding as landed and invalid-request read back rather than declared unreachable. *Over:* administrator completion of the constituent steps outside the composition, and a single bare `recording-failure` landing. *Because:* manual completion leaves the party with no completion record, which is the regulator-audit scenario's own failure produced by the recovery; and the substrate's step-4 arm means the event is already appended, so a bare token turned the retry into a duplicate-event generator (the frozen rules of 2026-08-29 — *Recovery commits under a declared service identity* and *A transcribed rejection arm keeps its payload*).
- **2026-08-27 — The gate authenticates and attributes; authorization is declared above the composition.** *Chose:* a named edge case declaring a composed Permissions instance over `invitations:initiate` / `invitations:revoke` as the deployment's authorization gate, with every "authorized actor" claim on the page downgraded to authenticated-and-attributed and the SOC 2 CC6.2 paragraph re-scoped to the registration and ordering halves. *Over:* wiring Permissions as a fifth constituent and gating [Invite] and [Revoke] on a scope. *Because:* the claim was made and neither wired nor disclaimed, which is the worst of the three states; absorbing the gate would make this composition the owner of an authorization vocabulary it has no other use for, while declaring it names the record a regulator's authorization question is answered from.
- **2026-08-26 — The attempt record is the credential gate on all four actions.** *Chose:* every state-changing action opens with a `record_action` attempt event whose Actor Identity attestation, made inside the substrate's declared surface, is the credential check; an attempt refused at the gate lands no event. *Over:* a dry-run mode the substrate does not declare, or reaching Actor Identity directly, which is a transitive constituent. *Because:* the check must live on a surface the composition actually consumes, and the attempt is then auditable for free.
- **2026-08-26 — Invariant 4 is safety plus detectability, not totality.** *Chose:* the arc's completeness is claimed over named gap signatures that checks 5 and 6 enumerate. *Over:* the unconditional statement over paths that admit invisible terminal transitions. *Because:* the composition is stateless by design and carries no marker discipline, so detectability through records is the recovery posture it can honestly offer.

NOTE: End of External Onboarding.

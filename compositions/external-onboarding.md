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

External Onboarding is the full arc of admitting an external entity to a system — invitation issued by an authenticated, attributed actor, accepted by the invitee (establishing the single identity binding), Party Identity enrolled in Unverified state (a party record that exists while nobody has yet checked who the party is), credential registered, every step attested in the Audit Trail (an append-only log of who did what and when, each entry vouched for by the acting caller's credential).

The guarantee the composition adds is invitation-gates-enrollment: no Party Identity is created via this composition unless an Invitation's Accepted transition precedes it, and the Audit Trail completion record names the specific invitation, the accepting identity, the party record, and the credential in one tamper-evident entry (an entry whose later alteration would show).

Without the composition, any of these steps can occur independently, in any order, without a documented chain; the composition is what makes the chain mandatory and auditable.

**Composes:** [Invitation](../atoms/invitation.md) · [Credential](../atoms/credential.md) · [Party Identity](../atoms/party-identity.md) · [Audit Trail](./audit-trail.md)

---

## Intent

Every system that admits external parties — customers, collaborators, patients, counterparties — faces the same structural challenge: the invitation must be issued before the invitee exists in the system, yet the moment of acceptance is the moment at which the system must durably record who joined, establish their identity record, and register the credential they will use to authenticate. Those three obligations — serializing concurrent acceptance attempts, creating the party record, registering the credential — belong to different atoms. The question of what must happen when they meet, in what order, with what audit record binding the whole arc together, belongs to no single atom. It belongs to the composition.

External Onboarding wires the four constituent atoms into a single enforced onboarding boundary. The [Invite] action establishes the documented intent: an authenticated actor initiates an invitation, creating a record in the Audit Trail of who invited whom and to what context. Whether that actor was *permitted* to invite is not this composition's gate — its attempt record authenticates and attributes, and authorization is the above-composition obligation Non-goal 1 and Non-goal 2 name. The [Onboard] action is the composition's load-bearing center: it calls `Invitation.accept` first — establishing the single-resolution serialization point — then `Party Identity.enroll`, then `Credential.register`, recording the full arc in the Audit Trail as a single named event that links invitation token, accepting identity reference, party record, and credential. The three calls are one database transaction, and [Onboard] follows Recoverable Invocation around it: an intent record before the transaction, the named event as its outcome, and a refusal record where any call refuses, so the attempt survives a refusal. The [Decline] and [Revoke] actions close the invitation on the other terminal paths, each attested in the Audit Trail.

The emergent invariant is invitation-gates-enrollment: no Party Identity is enrolled and no Credential registered via this composition unless an Invitation's `Accepted` transition precedes them — in the same onboarding call. The Invitation atom's single-resolution invariant (at most one write to one of three stored terminal states per invitation — a lapsed invitation is shown `Expired` by derivation, never written — the transition atomic under concurrent attempts) is the mechanism that makes the gate hold under concurrent onboarding attempts for the same invitation — exactly one [Onboard] call clears the gate; all others receive `already-resolved(Accepted)` and create no constituent records — their intent record and the refusal record that closes it are their only trace. A call that arrives while the first is in flight, or whose first call stopped and left an open intent, is held off by Recoverable Invocation's act key, the invitation token: it answers act-in-flight, or act-landed once the act has closed, and never re-runs the arc.

The second emergent property is the identity binding at accept, not at initiate. The accepting_identity_ref passed to `Invitation.accept` — a caller-supplied external reference identifying who is accepting, such as an email address or an external identity handle — is recorded permanently in the Invitation record at the moment of acceptance. The `party_id` produced by the downstream `Party Identity.enroll` call is then linked to that accepting_identity_ref in the Audit Trail completion record. The tracing path — from any enrolled Party Identity back to the specific Invitation that authorized its creation — runs through the Audit Trail: the completion event carries both the invitation_token and the `party_id`, making the chain provable.

---

## Composes

- **[Invitation](../atoms/invitation.md)** — the invitation lifecycle and the single-resolution gate.
- **[Credential](../atoms/credential.md)** — the binding between the enrolled party and the party's authentication material.
- **[Party Identity](../atoms/party-identity.md)** — the identity record the arc enrolls in the unverified state.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every attempt and every outcome is recorded through.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol [Onboard] follows around its arc: an intent before it, an outcome after it, the act's critical section over both, and a sweep that closes what an invocation left open. Bound once, for the act kind, on an instance that writes to this composition's Audit Trail instance. The bindings are the onboarding binding below; this page restates none of the protocol.

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
Composes 17: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 18: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 19: The composition MUST bind the act kind PER the onboarding binding.
Composes 20: The composition MUST NOT bind [Invite], [Decline] or [Revoke] as an act kind.
Composes 21: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
```

Term composition: this pattern's wiring of [Invitation](../atoms/invitation.md), [Credential](../atoms/credential.md), [Party Identity](../atoms/party-identity.md), the [Audit Trail](./audit-trail.md) substrate and [Recoverable Invocation](./recoverable-invocation.md) — the four actions, the credential gate and the onboarding binding.

Term constituents: [Invitation](../atoms/invitation.md), [Credential](../atoms/credential.md), [Party Identity](../atoms/party-identity.md), [Audit Trail](./audit-trail.md), [Recoverable Invocation](./recoverable-invocation.md).

Term substrate: the Audit Trail instance serving the composition.

Term trail: the substrate's events, in sequence order, as the composition and an auditor read them.

Term act kind: onboarding — the one act kind this composition binds on its Recoverable Invocation instance: an [Onboard] arc's three constituent writes.

Term onboarding binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the invitation token. commit — the onboarding transaction, read through the commit partition. pairing datum — none. repeatable — no. act probe — the onboarding probe. invocation completion bound — the onboarding completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with onboarding.intended, the one outcome onboarding.completed, and onboarding.refused. retention period — the audit horizon. settling period — the deployment's settling period. service identity — none (Composes 15 and 16). outcome envelope — sized from the minted-id width bounds (Primitive policy 6).

Term act key: the invitation token, known before the invocation open. Two onboardings of one token are one act attempted twice, repeatable being no: a second call takes the act's critical section in turn and meets act-landed once the first has closed with an outcome (a refusal, an abandonment or an escalation holds none, so the arc runs again, Recoverable Invocation open step 3.9), or its commit is refused by Invitation's single resolution (Recoverable Invocation repeatable 2).

Term onboarding transaction: Invitation's accept, Party Identity's enroll and Credential's register, called in that order and committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for (Composition notes, *Recoverable Invocation's commit is one call*).

Term commit partition: committed where the onboarding transaction commits and answers the party id and the credential id; pre-commit where any of its calls refuses — Invitation's expired, not-known, already-resolved or invalid-request, Party Identity's or Credential's invalid-request, Credential's duplicate-active-credential, or a constituent's storage-failure — the transaction then rolling back every write it made (Execution Contract Database 1) and the invitation staying as the call found it; unknown where the transaction answers a code none of the constituents declares, and where its reply has not arrived when the commit round trip has elapsed since the call's issue (Recoverable Invocation commit 6, commit 7).

NOTE: open 2026-11-10-b — the probe's party and credential sets have no cardinality cap.

Term onboarding probe: the read that answers whether an open intent's onboarding committed. Invitation's read by the intent's token answers not-committed where the invitation is pending, declined, revoked or accepted by another accepting identity reference; where it is accepted by the intent's accepting identity reference the probe answers undecidable carrying the party ids the composition selects, in its own code, from the parties Party Identity's read answers for a query carrying no filter (Execution Contract Query 4), each party selected by the intent's document type, the intent's document reference AND the intent's enrolling actor reference, in any state, and the credential ids Credential's read finds registered for those parties under the intent's credential type that no other credential found names as its successor, either set possibly empty; it answers unavailable where any of the reads is refused or gives no answer (Recoverable Invocation act probe 4), a rejected query surfaced on the compliance surface. The probe never answers committed: Party Identity and Credential keep no value of the call to pair on (Recoverable Invocation pairing datum 6a), so the operator decides.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST NOT store composition state.
Composition state 2: Audit Trail IS AUTHORITATIVE FOR the tracing from a party to the invitation behind the party's enrollment.
Composition state 3: The composition MUST NOT store a correlation index over the trail.
Composition state 4: The composition MUST read a completion record's party id, credential id AND invitation token from the completion record's own data.
Composition state 5: The composition MUST NOT store a record of the Recoverable Invocation instance.
```

Term completion relation: the relation a completion record declares — one invitation token to one completion record at most, and one completion record to exactly one invitation token, one accepting identity reference, one party id and one credential id; mandatory on the completion record's side, optional on the invitation's, since an invitation may stay pending, lapse, or be declined or revoked.

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
Deleted: Capability requirement 10. Recoverable Invocation Instance start 4 and Instance start 5 own it: the closure window and the retention period bound how long an intent stays open before the sweep reports it, and the resume arm whose gap this bounded retired (Scott, 2026-11-09 9:17 PM Central, option A).
Capability requirement 11: A deployment MUST declare the minted-id width bounds.
Capability requirement 12: The minted-id width bounds MUST agree with the widths the wired constituents allocate.
Deleted: Capability requirement 13. Execution Contract Database 2 owns it.
Deleted: Capability requirement 14. Execution Contract Database 2 owns it.
Deleted: Capability requirement 15. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 16. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 17. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to lease.
Capability requirement 18: IF the onboarding completion bound EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 19: IF the clock offset allowance EQUALS blank THEN the composition MUST refuse to start.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section for a deployment to leave blank.
Capability requirement 21: The deployment MUST supply the database PER Execution Contract Database 1 through 4, Execution Contract Database 7 AND Execution Contract Refusal 1.
Capability requirement 22: IF the minted-id width bounds EQUALS blank THEN the composition MUST refuse to start.
Deleted: Capability requirement 23. Recoverable Invocation Instance start 5 owns it: the audit horizon, the act kind's retention period, exceeds the retention floor.
Deleted: Capability requirement 24. Recoverable Invocation Instance start 4 owns it: the resume arm and its longest gap retired.
Deleted: Capability requirement 25. The foreign party read the max purge delay protected retired with the resume arm; Check 7.3 detects a party on two tokens' completion records inside the horizon (Invariant 4.5).
Deleted: Capability requirement 26. Capability requirement 25 retired; no max purge delay remains to leave blank.
Capability requirement 27: The host MUST inject the invocation id, the run id AND the operator run id at the composition's seam.
Capability requirement 28: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 29: A deployment MUST disclose the commit round trip, the probe round trip, the reconciliation run bound AND the settling period.
Capability requirement 30: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 31: A deployment MUST NOT remove an Invitation, Party Identity or Credential record BEFORE the audit horizon has run past the record's onboarding outcome (Recoverable Invocation Binding 9).
NOTE: open 2026-11-10-c — the removal bound is silent for a record of an invitation no onboarding was attempted for.
```

Term onboarding completion bound: the deployment's declared maximum for an [Onboard] invocation — the act kind's invocation completion bound: the longest an [Onboard] takes from the invocation open's take of the critical section to the invocation close's last write, the constituent round trip included.

Term clock offset allowance: the deployment's declared bound on the difference between any two of the clocks at this composition's seam and at Invitation's, Party Identity's, Credential's, the substrate's and the act section host's seams — Recoverable Invocation's clock allowance, one allowance set to cover the widest pair.

Term audit horizon: the horizon of the retention policy the wired Audit Trail instance places every onboarding event under — the act kind's retention period, and the upper edge of every trail-walking check.

Term minted-id width bounds: the maximum widths the wired constituents allocate for an invitation token, a party id, a credential id and an event id.

Term slowest conforming invocation: the longest a conforming [Onboard] takes between the invocation open's take of the critical section and the invocation close's last write.

Term seam skew: the largest difference between any two of this composition's seam clock and the constituents' seam clocks.

Term commit round trip: the deployment's disclosed bound on one onboarding transaction, from issue to reply.

Term probe round trip: the deployment's disclosed bound on one onboarding probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated onboarding through the invocation resolve (Recoverable Invocation Term settling period).

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance.

Term invocation id: the fresh id the host injects at the seam per [Onboard], carried by every record the invocation writes (Recoverable Invocation Term invocation id).

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank required input.
Primitive policy 2: IF an actor reference EXCEEDS the reference length cap THEN the composition MUST answer invalid-request.
Primitive policy 3: The composition MUST answer invalid-request for EVERY field an action passes to a constituent that the constituent's own field rules refuse.
Primitive policy 4: An action MUST NOT record the action's attempt record BEFORE validating the action's inputs.
Primitive policy 5: IF the data of an event the action will emit EXCEEDS the payload cap THEN the composition MUST answer invalid-request.
Primitive policy 6: The composition MUST size an id a constituent minted, where the payload carries the id, at the id's minted-id width bound.
Deleted: Primitive policy 7. The resume choice retired with the resume arm: [Onboard] takes no resume party id and no resume credential id, and always runs the onboarding transaction (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Primitive policy 8. Primitive policy 7 retired; [Onboard] records no accept attempt, and its intent follows validation (Recoverable Invocation Action wiring 4).
Deleted: Primitive policy 9. Primitive policy 7 retired; the call carries no resume choice.
Primitive policy 10: An action refused under Primitive policy 1 through 6 MUST NOT write.
```

Term required input: for [Invite] the inviter reference, the context and the actor credential; for [Onboard] the invitation token, the accepting identity reference, the name, the date of birth, the document type, the document reference, the credential type, the credential material, the enrolling actor reference and the actor credential; for [Decline] the invitation token, the service actor reference and the actor credential; for [Revoke] the invitation token, the revoked by reference, the revocation reason and the actor credential.

Term actor reference: the inviter reference, the enrolling actor reference, the service actor reference or the revoked by reference — the reference an action attests under.

Term actor credential: the calling actor's credential, which the attempt record's attestation verifies (Audit Trail reaches Actor Identity, the attestation's owner).

Term credential material: the authentication material a [Onboard] call passes to Credential's register — raw, never hashed by this composition.

Term call's expiry instant: the expires_at an [Onboard] call supplies, passed unchanged to Credential's register as the credential's expiry instant, and blank where the call supplies none.

Term service actor reference: the system service account a [Decline] attests under.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an attempt record THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an attempt record THEN the action MUST answer storage-failure carrying intent.
Audit arm 3: IF Audit Trail answers invalid-request carrying a step below step-3 at an attempt record THEN the action MUST answer storage-failure carrying intent.
Audit arm 4: A refused attempt record MUST stop the action.
Audit arm 5: IF Audit Trail answers recording-failure at a post-write record THEN the action MUST answer storage-failure carrying intent (Execution Contract Constituent failure 1).
Deleted: Audit arm 6. Execution Contract Database 1 owns it.
Deleted: Audit arm 7. Execution Contract Database 1 owns it.
Audit arm 8: IF Audit Trail answers invalid-request(step-4) at a post-write record THEN the composition MUST read the record back.
Audit arm 9: The landing read MUST run from the sequence number of the invocation's own attempt record to the open end.
Audit arm 10: The landing read MUST match the post-write record by action reference AND invitation token.
Audit arm 11: IF the landing read finds the post-write record THEN the action MUST proceed as landed.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
Audit arm 13: IF Audit Trail answers invalid-credential at a post-write record THEN the action MUST answer invalid-credential.
Audit arm 14: IF Invitation answers storage-failure THEN the action MUST answer storage-failure carrying intent (Execution Contract Constituent failure 1).
Deleted: Audit arm 15. Recoverable Invocation commit 3 owns it: Party Identity's storage-failure is a pre-commit arm of the onboarding transaction, answered as its own code.
Deleted: Audit arm 16. Recoverable Invocation commit 3 owns it: Credential's storage-failure is a pre-commit arm of the onboarding transaction, answered as its own code.
Audit arm 17: A caller MUST read storage-failure carrying intent as a committed nothing.
Deleted: Audit arm 18. No action answers storage-failure carrying outcome: Audit arm 5, 22 and 25 carry intent, and [Onboard]'s outcome-position failure is Recoverable Invocation's recording-failure(outcome).
Audit arm 19: The deployment MUST alert on an invalid-request from Audit Trail as a deployment fault.
Deleted: Audit arm 20. Execution Contract Database 1 owns it.
Audit arm 21: IF Audit Trail answers invalid-request carrying a step above step-2 at an attempt record THEN the action MUST answer storage-failure carrying attempt-evidence.
Audit arm 22: IF Audit Trail answers invalid-request carrying a step below step-4 at a post-write record THEN the action MUST answer storage-failure carrying intent (Execution Contract Read 4).
Audit arm 23: A caller MUST read storage-failure carrying attempt-evidence as a committed attestation AND no constituent write.
Audit arm 24: A caller MUST NOT retry a call that answered storage-failure carrying attempt-evidence as written.
Audit arm 25: IF the landing read finds no post-write record THEN the action MUST answer storage-failure carrying intent (Execution Contract Read 4).
Audit arm 26: [Onboard] MUST answer PER Recoverable Invocation's Action wiring table, AND the Audit arm's rules MUST NOT answer for [Onboard], whose records Recoverable Invocation writes.
```

Term attempt record: the record an action writes first — the initiate attempt, the decline attempt or the revoke attempt; and, for [Onboard], the intent record the invocation open writes (Recoverable Invocation open step 4.3). The attestation the substrate makes inside the record *is* the credential gate.

Term post-write record: a record an action writes after a constituent write commits — the initiated record, the decline record or the revoke record; [Onboard]'s completion record is the invocation close's outcome, and its refusal record the invocation refuse's, both Recoverable Invocation's.

Term retention step: the step naming the substrate's retention placement on an invalid-request — step-4; the event is appended and attested.

Term invalid-request step: step-1 | step-2 | step-3 | step-4, in that order, so below and above compare by the number — the step of Audit Trail's record action that landed the refusal; step-4 is the retention step, and at step-1 through step-3 the event is not in the log.

Term landing read: the composition's enumerate-and-filter read of the trail for a post-write record whose landing the substrate's answer did not say.

Term position: intent | attempt-evidence — where a storage-failure sat: intent, no constituent has committed anything (on the post-write path the action's writes are rolled back, Execution Contract Database 1 and Audit arm 5) and the whole action may be retried as written; attempt-evidence, the substrate refused the attempt record at step-3 or step-4, so its attestation stands committed and no constituent has written (Audit Trail record action step 7.11 and 7.13). [Onboard]'s recording-failure carries Recoverable Invocation's own positions (intent, outcome, refusal), not this term's.

### Action wiring

```
invite(inviter_ref, optional invitee_ref, context, optional ttl, actor_credential)
  answers invitation_token
  refuses invalid-request | invalid-credential | storage-failure(position)

onboard(invitation_token, accepting_identity_ref, name, date_of_birth, document_type, document_ref, credential_type, credential_material, optional expires_at, enrolling_actor_ref, actor_credential)
  answers onboarding result
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | duplicate-active-credential | storage-failure | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | already-accounted(closing_event_id) | recording-failure(intent) | recording-failure(outcome, invocation_id) | recording-failure(refusal, constituent_code)

decline(invitation_token, service_actor_ref, actor_credential)
  answers declined
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | storage-failure(position)

revoke(invitation_token, revoked_by_ref, reason, actor_credential)
  answers revoked
  refuses invalid-request | invalid-credential | invitation-invalid(invitation refusal) | storage-failure(position)
```

Term onboarding result: the party id and the credential id an [Onboard] answers once its onboarding transaction commits and its completion record lands. duplicate-active-credential refuses beside it: the transaction rolls back, the invitation stays pending, and the invocation refuse keeps the attempt as a refusal record (Action wiring 32, Action wiring 58).

Term invitation refusal: the Invitation refusal a gate call met — already-resolved carrying the stored terminal, not-known or expired.

```
Action wiring 1: An action MUST NOT call a constituent BEFORE the action's attempt record lands.
Action wiring 2: The composition MUST NOT verify a credential outside an attempt record.
Action wiring 3: A validated invite MUST record an initiate attempt carrying the invitee reference, the context AND the ttl, blank where the call supplies none.
Action wiring 4: An admitted invite MUST call Invitation's initiate with the inviter reference, the invitee reference, the context AND the ttl.
Action wiring 5: IF Invitation answers invalid-request for an initiate THEN [Invite] MUST answer invalid-request.
Action wiring 6: An admitted invite MUST record an initiated record carrying the invitation token, the invitee reference, the context AND the ttl, blank where the call supplies none, ONLY AFTER Invitation's initiate answers the invitation token.
Action wiring 7: A landed invite MUST answer the invitation token.
Deleted: Action wiring 8. Recoverable Invocation open step 4.3 owns it: the invocation open records the intent carrying the intent data (Action wiring 56 and 57), and the intent is the attempt record.
Action wiring 9: An admitted onboard MUST call Invitation's accept with the invitation token AND the accepting identity reference as the onboarding transaction's first call.
Deleted: Action wiring 10. Execution Contract Database 1 owns it.
Deleted: Action wiring 11. Execution Contract Database 1 owns it: a fresh arc's writes commit together, and the composition names no critical section for the host to refuse.
Deleted: Action wiring 12. Execution Contract Database 2 owns it.
Deleted: Action wiring 13. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no lease to expire.
Deleted: Action wiring 14. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to lose.
Deleted: Action wiring 15. Execution Contract Database 1 owns it: a fresh arc's writes commit together, so no resumer re-enters an arc a fresh arc is still running.
Deleted: Action wiring 16. Execution Contract Database 1 owns it: a fresh arc's writes commit together, so no resumer re-enters an arc a fresh arc is still running.
Action wiring 17: IF Invitation answers expired THEN [Onboard] MUST answer invitation-invalid carrying expired.
Action wiring 18: IF Invitation answers not-known THEN [Onboard] MUST answer invitation-invalid carrying not-known.
Action wiring 19: IF Invitation answers already-resolved AND the stored terminal DOES NOT EQUAL accepted THEN [Onboard] MUST answer invitation-invalid carrying already-resolved AND the stored terminal.
Action wiring 20: IF Invitation answers already-resolved AND the stored terminal EQUALS accepted THEN [Onboard] MUST answer invitation-invalid carrying already-resolved AND accepted.
Action wiring 21: IF Invitation answers invalid-request for an accept THEN [Onboard] MUST answer invalid-request.
Deleted: Action wiring 22. Recoverable Invocation owns it, and retires it: no resumable acceptance is read, and an open intent is closed by the invocation resolve (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Action wiring 23. Action wiring 20 owns it: the stored terminal accepted answers invitation-invalid carrying already-resolved AND accepted, whatever the acceptor.
Action wiring 24: A refused onboarding transaction MUST write nothing beyond the intent record AND the refusal record.
Deleted: Action wiring 25. Recoverable Invocation Action wiring 6 owns it: an adopter writes to the journal for the act only through the invocation open, the invocation close and the invocation refuse, so no acceptance record is written; the intent carries the document pair (Action wiring 57).
Action wiring 26: An onboarding transaction MUST call Party Identity's enroll with the name, the date of birth, the document type, the document reference AND the enrolling actor reference ONLY AFTER Invitation's accept answers accepted.
Deleted: Action wiring 27. Execution Contract Constituent failure 1 and Read 4 own it: a Party Identity refusal fails the whole call, so no interruption record commits for it.
Action wiring 28: IF Party Identity answers invalid-request for an enroll THEN [Onboard] MUST answer invalid-request.
Action wiring 29: An onboarding transaction MUST call Credential's register with the party id Party Identity's enroll answered as the principal reference, the credential material, the credential type AND the call's expiry instant, passed unchanged (blank where the call supplies none), ONLY AFTER Party Identity's enroll answers the party id.
Deleted: Action wiring 30. Unreachable: duplicate-active-credential refuses the onboarding transaction and rolls it back (Action wiring 32), so no interruption record is written; the interruption record retired with the resume arm.
Action wiring 31: IF Credential answers invalid-request for a register THEN [Onboard] MUST answer invalid-request.
Action wiring 32: IF Credential answers duplicate-active-credential THEN [Onboard] MUST answer duplicate-active-credential, the onboarding transaction having rolled back.
Deleted: Action wiring 33. The resume arm retired; an open intent is closed by the invocation resolve (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Action wiring 34. Resume 41 and Resume 45 own it, because the arc continues with the credential the arc registered, never the credential standing active.
Deleted: Action wiring 35. The resume arm retired; no call reads an arc's credential back.
Deleted: Action wiring 36. No interruption record is written (Action wiring 30).
Action wiring 37: [Onboard] MUST close a committed onboarding transaction through the invocation close naming onboarding.completed AND carrying the invitation token, the accepting identity reference, the party id AND the credential id (Recoverable Invocation commit 4).
Action wiring 38: A completing arc MUST answer the party id AND the credential id.
Deleted: Action wiring 39. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
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
Action wiring 56: A validated onboard MUST call the invocation open with the act kind, the invitation token as the act key, the enrolling actor reference, the actor credential AND the intent data (Recoverable Invocation Action wiring 4).
Action wiring 57: The intent data MUST carry the invitation token, the accepting identity reference, the document type, the document reference AND the credential type.
Action wiring 58: [Onboard] MUST close a pre-commit arm through the invocation refuse AND answer the constituent's code (Recoverable Invocation commit 2, commit 3).
Action wiring 59: IF the invocation open answers act-landed THEN [Onboard] MUST answer invitation-invalid carrying already-resolved AND accepted.
Action wiring 60: IF a call of the onboarding transaction answers an arm of the unknown partition THEN [Onboard] MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 61: IF Credential answers duplicate-active-credential THEN the onboarding transaction MUST commit no write.
```

Term validated invite: an [Invite] call whose inputs clear Primitive policy.

Term admitted invite: a validated invite whose initiate attempt lands.

Term landed invite: an admitted invite whose initiated record landed or proceeds as landed.

Term validated onboard: an [Onboard] call whose inputs clear Primitive policy.

Term admitted onboard: a validated onboard whose intent lands.

Term arc: one [Onboard] invocation of one invitation token — its intent, its onboarding transaction, and the completion record or the refusal record that closes them.

Term completing arc: an arc whose onboarding transaction commits and whose the invocation close lands.

Term validated decline: a [Decline] call whose inputs clear Primitive policy.

Term admitted decline: a validated decline whose decline attempt lands.

Term landed decline: an admitted decline whose decline record landed or proceeds as landed.

Term validated revoke: a [Revoke] call whose inputs clear Primitive policy.

Term admitted revoke: a validated revoke whose revoke attempt lands.

Term landed revoke: an admitted revoke whose revoke record landed or proceeds as landed.

Term revocation reason: the reason a [Revoke] call carries, passed to Invitation's revoke and recorded on the revoke record.

#### Closure table

Every input an action takes and every answer a call of the four actions can meet — Invitation's initiate, accept, decline and revoke, Party Identity's enroll, Credential's register, Audit Trail's record_action, and Recoverable Invocation's open, the invocation close, the invocation refuse and the invocation yield around [Onboard]'s commit — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1, Execution Contract Constituent failure 3); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. Each action is one transaction (Execution Contract Database 1), except that [Onboard]'s intent is committed ahead of it by the invocation open (Execution Contract Database 3) and that an attempt record Audit Trail commits at step-3 or step-4 stays committed beside the refused action (Audit arm 21, Term position). The sweep's the invocation reconcile, the operator's the invocation resolve and the invocation read are not called around the commit, and Recoverable Invocation's own closure table lands them.

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action | a blank required input | invalid-request, nothing written | Primitive policy 1, 10 |
| every action | an actor reference over the reference length cap | invalid-request, nothing written | Primitive policy 2, 10 |
| every action | a field a constituent's own rules refuse | invalid-request, nothing written | Primitive policy 3, 10 |
| every action | the data of an event the action will emit over the payload cap | invalid-request, nothing written | Primitive policy 5, 10 |
| onboard | the intent data or the largest outcome over the substrate's payload cap | invalid-request, nothing written | Primitive policy 5, 6; Recoverable Invocation open step 1.4 |

**Audit Trail's record_action at an attempt record**, at [Invite], [Decline] and [Revoke]; [Onboard]'s intent is the invocation open's and is landed below.

| Answer | Lands | Owner |
|---|---|---|
| event id | the attempt record landed; the action goes on to its constituent call | Action wiring 1 |
| invalid-credential | invalid-credential, nothing written | Audit arm 1 |
| recording-failure | storage-failure carrying intent, nothing written | Audit arm 2, Execution Contract Constituent failure 4 |
| invalid-request below step-3 | storage-failure carrying intent, nothing written | Audit arm 3 |
| invalid-request at step-3 or step-4 | storage-failure carrying attempt-evidence, the attestation committed | Audit arm 21, 23, 24 |
| state-unavailable | state-unavailable, nothing written | Execution Contract Constituent failure 3 |
| no answer | no answer, nothing concluded about the record | Execution Contract Error model 1 |

**Audit Trail's record_action at a post-write record**, at [Invite], [Decline] and [Revoke].

| Answer | Lands | Owner |
|---|---|---|
| event id | the record landed; the action answers | Action wiring 7, 46, 55 |
| invalid-credential | invalid-credential | Audit arm 13 |
| recording-failure | storage-failure carrying intent, the action's writes rolled back | Audit arm 5, Execution Contract Constituent failure 1 |
| invalid-request at step-4 | the record read back; found, the action proceeds as landed; not found, storage-failure carrying intent | Audit arm 8, 9, 10, 11, 25 |
| invalid-request below step-4 | storage-failure carrying intent | Audit arm 22 |
| no answer | no answer, nothing concluded about the record or the action's writes | Execution Contract Error model 1 |
| state-unavailable | state-unavailable, the action's writes rolled back | Execution Contract Constituent failure 3 |

**Invitation's initiate**, at [Invite], after the attempt record.

| Answer | Lands | Owner |
|---|---|---|
| the invitation token | the initiated record, then the token answered | Action wiring 6, 7 |
| invalid-request | invalid-request | Action wiring 5 |
| storage-failure | storage-failure carrying intent | Audit arm 14 |
| state-unavailable | state-unavailable | Execution Contract Constituent failure 3 |

**Invitation's decline and revoke**, at [Decline] and [Revoke], after the attempt record.

| Answer | Lands | Owner |
|---|---|---|
| declined, revoked | the decline or revoke record, then the answer | Action wiring 45, 46, 54, 55 |
| expired, already-resolved, not-known | invitation-invalid carrying the refusal and, for already-resolved, the stored terminal | Action wiring 42, 43, 44, 50, 51, 52 |
| invalid-request (revoke) | invalid-request | Action wiring 53 |
| storage-failure | storage-failure carrying intent | Audit arm 14 |
| state-unavailable | state-unavailable | Execution Contract Constituent failure 3 |

**Recoverable Invocation's open**, at [Onboard], after validation.

| Answer | Lands | Owner |
|---|---|---|
| the invocation pair | the onboarding transaction issued | Action wiring 56, Recoverable Invocation Action wiring 4 |
| invalid-credential | invalid-credential, nothing written | Recoverable Invocation Action wiring table |
| invalid-request | invalid-request, nothing written | Recoverable Invocation Action wiring table |
| act-in-flight(invocation_id) | act-in-flight, nothing written | Recoverable Invocation Action wiring table, open step 3.5 |
| act-landed | invitation-invalid carrying already-resolved AND accepted | Action wiring 59 |
| section-unavailable | section-unavailable, nothing written | Recoverable Invocation Action wiring table |
| journal-unavailable | journal-unavailable, nothing written; never read as not-known | Recoverable Invocation Action wiring table, Recoverable Invocation Action wiring 3 |
| recording-failure(intent) | recording-failure(intent), nothing committed | Recoverable Invocation Action wiring table |
| recording-failure(outcome) | recording-failure(outcome), the intent left open for the sweep | Recoverable Invocation Action wiring table |

**The onboarding transaction**, at [Onboard] after the invocation open returns.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Invitation's accept | accepted | Party Identity's enroll | Action wiring 26 |
| Invitation's accept | expired, not-known | pre-commit: the invocation refuse, then invitation-invalid carrying the code | Action wiring 17, 18, 58 |
| Invitation's accept | already-resolved, a terminal other than accepted | pre-commit: the invocation refuse, then invitation-invalid carrying already-resolved AND the terminal | Action wiring 19, 58 |
| Invitation's accept | already-resolved, accepted | pre-commit: the invocation refuse, then invitation-invalid carrying already-resolved AND accepted | Action wiring 20, 58 |
| Invitation's accept | invalid-request | pre-commit: the invocation refuse, then invalid-request | Action wiring 21, 58 |
| Party Identity's enroll | the party id | Credential's register | Action wiring 29 |
| Party Identity's enroll | invalid-request | pre-commit: the invocation refuse, then invalid-request | Action wiring 28, 58 |
| Credential's register | the credential id | committed: the invocation close naming onboarding.completed | Action wiring 37 |
| Credential's register | duplicate-active-credential | pre-commit, the transaction rolled back: the invocation refuse, then duplicate-active-credential | Action wiring 32, 58, 61 |
| Credential's register | invalid-request | pre-commit: the invocation refuse, then invalid-request | Action wiring 31, 58 |
| any of the three | storage-failure | pre-commit: the invocation refuse, then storage-failure | Recoverable Invocation commit 3, Execution Contract Constituent failure 1 |
| any of the three | state-unavailable | pre-commit: the invocation refuse, then state-unavailable | Execution Contract Constituent failure 3, Recoverable Invocation commit 2, commit 3 |
| any of the three | a code no constituent declares | unknown: the invocation yield, then recording-failure(outcome) | Recoverable Invocation commit 7, Action wiring 60 |
| the transaction | no answer within the commit round trip | unknown: the invocation yield, then recording-failure(outcome) | Recoverable Invocation commit 6, Action wiring 60 |

**Recoverable Invocation's close, the invocation refuse and the invocation yield**, at [Onboard] after the transaction.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the invocation close | landed | the party id and the credential id answered | Action wiring 37, 38 |
| the invocation close | recording-failure(outcome) | recording-failure(outcome), the committed arc's record the operator's invocation resolve's, the composition naming no service identity (Composes 15); never re-run | Recoverable Invocation Action wiring table |
| the invocation refuse | landed | the constituent's code answered | Action wiring 58 |
| the invocation refuse | already-accounted(closing_event_id) | already-accounted | Recoverable Invocation Action wiring table |
| the invocation refuse | recording-failure(refusal, constituent_code) | recording-failure(refusal, constituent_code); never re-run | Recoverable Invocation Action wiring table |
| the invocation yield | any | recording-failure(outcome) | Recoverable Invocation commit 8, Action wiring 60 |

### Wiring decision

```
Wiring decision 1: The composition MUST call Party Identity's enroll ONLY AFTER Invitation's accept answers accepted for the arc.
Wiring decision 2: The composition MUST call Credential's register ONLY AFTER Party Identity's enroll answers the arc's party id.
Wiring decision 3: The composition MUST NOT accept an invitation token a second time.
Wiring decision 4: The composition MUST pass the call's accepting identity reference to Invitation's accept.
Wiring decision 5: A deployment MUST NOT complete an arc's constituent steps outside the composition.
Wiring decision 6: A deployment MUST close an open onboarding intent through Recoverable Invocation's the invocation resolve AND through no constituent call.
```

<details markdown="block">
<summary>WHY</summary>

The principle: no party is enrolled and no credential registered through this composition unless an invitation's accepted transition precedes them — in the same call. Invitation's single-resolution invariant is the mechanism that makes the gate hold under concurrent attempts: exactly one [Onboard] clears it, and every other receives already-resolved carrying accepted and creates no constituent record — its intent record and the refusal record that closes it are its only trace.

The likely objection: *why not let a second call finish a stopped onboarding, or an operator finish it by hand — enroll the party, register the credential?* Because the onboarding is one act, and Recoverable Invocation never re-runs an act whose record is open: the three writes commit together or not at all (Execution Contract Database 1), so a stop leaves either nothing, or a committed arc whose completion record is owed, and the owed record is closed by an operator who reads the onboarding probe's candidates and names the outcome through the invocation resolve. Manual completion outside the composition leaves the party with no completion record, which is the regulator-audit scenario's own failure produced by the recovery. And *why not simply accept again?* Because the gate is single-resolution (Wiring decision 3).

The mechanism: the step order is fixed (Wiring decision 1 and 2); the identity binding is made at accept, with the accepting identity reference the caller supplies at acceptance, not the one the inviter guessed at initiation (Wiring decision 4); and a stopped onboarding is closed through the invocation resolve, never re-accepted and never finished outside the composition (Wiring decision 5 and 6).

The result: invitation-gates-enrollment (Invariant 1) and credential-follows-party (Invariant 3) fall out of the wiring, and the completion record binds the whole arc in one tamper-evident entry (Invariant 5). The constituent atoms are unchanged; the guarantee lives in the order the composition calls them in.

</details>

### Resume

The resume arm retired (Scott, 2026-11-09 9:17 PM Central, option A): an onboarding is one Recoverable Invocation act, a credential collision is a pre-commit refusal, and a stopped onboarding is an open intent the operator closes through the invocation resolve. Every rule keeps its tombstone, naming what owns it.

```
Deleted: Resume 1. Execution Contract Database 2 owns it.
Deleted: Resume 2. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section for the host to refuse.
Deleted: Resume 3. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Resume 4. Recoverable Invocation Invariant 7.2 and reconcile step 1.2 own it: an intent past its horizon edge is no longer read, and a second call is refused by Invitation's single resolution through the invocation refuse (Action wiring 20).
Deleted: Resume 5. Recoverable Invocation Invariant 7.3 owns it: a purged intent is excluded before any read.
Deleted: Resume 6. Recoverable Invocation open step 3 owns it: the invocation open reads the act key's records in sequence order.
Deleted: Resume 7. Recoverable Invocation open step 3.9 owns it: the invocation open answers act-landed, which [Onboard] answers as invitation-invalid carrying already-resolved AND accepted (Action wiring 59).
Deleted: Resume 8. Recoverable Invocation open step 3.5 owns it: a young open intent answers act-in-flight.
Deleted: Resume 9. Recoverable Invocation open step 3.8 owns it: an aged open intent never blocks the invocation open, the sweep surfaces it and the operator closes it through the invocation resolve.
Deleted: Resume 10. Unreachable: an onboarding's writes commit together (Execution Contract Database 1), so no stage stops between them; the stage and the interruption record retired with the resume arm.
Deleted: Resume 11. Unreachable: Recoverable Invocation Action wiring 6 admits no adopter write to the journal beyond the invocation open, the invocation close and the invocation refuse, so no acceptance record is written or missing.
Deleted: Resume 12. Resume 11 owns it, as unreachable.
Deleted: Resume 13. Recoverable Invocation Primitive policy 9 owns it: the intent data carries the document pair (Action wiring 57).
Deleted: Resume 14. Resume 11 owns it, as unreachable: the intent is the arc's one record of the documents.
Deleted: Resume 15. Unreachable: no call resumes an arc, and the operator's disposition replaces it.
Deleted: Resume 16. Term onboarding probe owns it: the probe reads Party Identity with a query carrying no filter and selects the parties by the intent's document pair and enrolling actor reference.
Deleted: Resume 17. Term onboarding probe owns it, without the foreign party exclusion: a party on another token's records is found by Check 7.3, not excluded by the read (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 18. Term onboarding probe owns it: the probe selects the parties by the intent's enrolling actor reference, the original caller's.
Deleted: Resume 19. Term onboarding probe owns it: the probe reads a party in any state.
Deleted: Resume 20. Recoverable Invocation act probe 6a owns it: the probe never answers committed with pairing datum none, so a sole candidate is undecidable and the operator decides.
Deleted: Resume 21. Recoverable Invocation reconcile step 3.8 owns it: several candidates are undecidable and escalated.
Deleted: Resume 22. Recoverable Invocation resolve 1 owns it: the operator's disposition names the outcome, and the chosen party is detected against the candidates by Check 7.3, not prevented (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 22a. Resume 22 owns it.
Deleted: Resume 22b. Unreachable: no acceptance record exists.
Deleted: Resume 22c. Unreachable: no acceptance record exists.
Deleted: Resume 23. Resume 22 owns it.
Deleted: Resume 24. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Resume 25. Recoverable Invocation act probe 4 owns it: a read rejection answers unavailable.
Deleted: Resume 26. Recoverable Invocation act probe 4 owns it: the rejected query reaches the compliance surface.
Deleted: Resume 27. Execution Contract Database 1 owns it.
Deleted: Resume 28. Recoverable Invocation open step 4.3 owns it: every [Onboard] writes its own intent.
Deleted: Resume 29. Recoverable Invocation Primitive policy 23 owns it: recording-failure(intent).
Deleted: Resume 30. Unreachable: no acceptance record is written (Action wiring 25).
Deleted: Resume 30a. Resume 30 owns it, as unreachable.
Deleted: Resume 31. Recoverable Invocation reconcile step 3.7 owns it: the sweep never re-runs an act, and Party Identity's enroll runs only inside the onboarding transaction.
Deleted: Resume 32. Resume 31 owns it.
Deleted: Resume 33. Recoverable Invocation Primitive policy 4 and Invariant 3.1 own it: an outcome pairs with its intent by invocation id.
Deleted: Resume 34. Execution Contract Database 1 owns it.
Deleted: Resume 35. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Resume 36. Recoverable Invocation Primitive policy 20 owns it.
Deleted: Resume 37. Execution Contract Database 1 owns it.
Deleted: Resume 38. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no critical section to take again.
Deleted: Resume 39. Term onboarding probe owns it: the probe reads the party's credentials of the intent's type; duplicate-active-credential is a pre-commit refusal now (Action wiring 32).
Deleted: Resume 40. Term onboarding probe owns it.
Deleted: Resume 41. Recoverable Invocation act probe 6a owns it: a sole credential candidate is undecidable.
Deleted: Resume 42. Recoverable Invocation reconcile step 3.8 owns it: the next action is the operator's the invocation resolve disposition (outcome, abandoned or escalated).
Deleted: Resume 43. Recoverable Invocation reconcile step 3.8 owns it.
Deleted: Resume 44. Resume 22 owns it.
Deleted: Resume 45. Resume 22 owns it.
Deleted: Resume 46. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Resume 47. Recoverable Invocation reconcile step 3.8a owns it; under service identity none the case reaches the compliance surface (Recoverable Invocation service identity 1b).
Deleted: Resume 48. Recoverable Invocation Primitive policy 41 owns it: invalid-request.
Deleted: Resume 49. Recoverable Invocation Primitive policy 41 and 43 own it.
Deleted: Resume 50. Recoverable Invocation Primitive policy 22 owns it.
Deleted: Resume 51. Resume 17 owns it: the foreign party read retired (Scott, 2026-11-09 9:17 PM Central, option A).
Deleted: Resume 52. Unreachable: an accepted invitation with no party cannot commit; the onboarding transaction is atomic (Execution Contract Database 1).
```

---

## Composition-level invariants

These emerge from the composition; none belongs to a single constituent.

- **Invariant 1 — Invitation gates enrollment.**
  ```
  Invariant 1.1: EVERY enroll the composition makes MUST follow an accepted invitation carrying the arc's accepting identity reference.
  Deleted: Invariant 1.2. Recoverable Invocation reconcile step 3.7 owns it: no arc is resumed, the sweep never re-runs an act, and the invocation resolve calls no constituent.
  Deleted: Invariant 1.3. Invitation's single resolution owns it, whatever the clock: exactly one accept answers accepted for one token; and Recoverable Invocation's critical section keeps a second call off the act while the first runs.
  ```

- **Invariant 2 — Identity binding at accept, linked by the completion record.**
  ```
  Invariant 2.1: EVERY completion record MUST carry the accepting identity reference the arc's acceptance bound.
  Invariant 2.2: The composition MUST NOT take an accepting identity reference from an [Invite] call.
  ```
- **Invariant 3 — Credential follows party.**
  ```
  Invariant 3.1: EVERY credential the composition registers MUST name the arc's party id as the credential's principal reference.
  ```
- **Invariant 4 — Audit coverage as safety plus detectability.**
  ```
  Invariant 4.1: EVERY accepted, declined AND revoked write through the composition MUST stand as a covered transition.
  Invariant 4.2: EVERY invitation the composition initiates MUST stand as a covered initiation.
  Invariant 4.3: The composition MUST make the coverage claim ONLY IF the arc lies inside the audit horizon.
  Invariant 4.4: An invitation token MUST NOT carry two completion records.
  Invariant 4.5: A party id MUST NOT appear on the completion records of two invitation tokens, except on an outcome an administrator names through the invocation resolve (Invariant 4.6).
  Invariant 4.6: The composition MUST make the claim of Invariant 4.5 as detectable through Check 7.3 AND MUST NOT make the claim as prevented for an outcome an administrator names through the invocation resolve.
  ```
  Term covered transition: a terminal invitation write whose record exists — for accepted, the intent and its completion record — or whose absent record is a gap signature Check 5.1, Check 5.2 or Check 6.1 enumerates.

  Term covered initiation: an invitation whose initiated record exists, or whose absent record is Check 6.2's gap signature.

- **Invariant 5 — The completion record names the full arc.**
  ```
  Invariant 5.1: EVERY completion record MUST carry the invitation token, the accepting identity reference, the party id AND the credential id.
  ```

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

Internally: the invocation open records `onboarding.intended` carrying the token, the accepting identity reference, the document pair and the credential type (the service account's credential gate clears). Then, in one transaction, `Invitation.accept("tok_inv_g7h2k1", "newhire@acme.com") → accepted`, `Party Identity.enroll(...)` → `party_4421`, and `Credential.register(principal_ref="party_4421", credential_material=<the raw password>, credential_type="password")` → `cred_7791`. the invocation close records `onboarding.completed: {tok_inv_g7h2k1, newhire@acme.com, party_4421, cred_7791}`.

The party is in `Unverified` state. The HR team proceeds to the Customer Onboarding verification workflow to drive the `Party Identity.verify` call that produces the `Verified` transition.

### Concurrent acceptance attempt — the same acceptor, still in flight

A duplicate browser tab submits the same acceptance while the first call is still running:

```
onboard(
  invitation_token:       "tok_inv_g7h2k1",
  accepting_identity_ref: "newhire@acme.com",
  ...
) → rejected(act-in-flight(invocation_id))
```

Internally: the invocation open takes the act's critical section, keyed by the invitation token, and finds the first call's intent open and younger than the examine edge, so it answers act-in-flight carrying the first call's invocation id and writes nothing (Recoverable Invocation open step 3.5). Once the first call has closed, a second call meets act-landed, which [Onboard] answers as `invitation-invalid(already-resolved(accepted))` (Action wiring 59); a different acceptor, or any call after the first intent passed its horizon, is refused by Invitation's single resolution through the invocation refuse the same way (Action wiring 20, 58). No party is enrolled and no credential registered; the call's own trace is nothing, or its intent and its refusal record.

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

Any subsequent [Onboard] attempt with `tok_inv_c2d8e3` returns `rejected(invitation-invalid(already-resolved(revoked)))`.

### Invitation declined

```
decline(
  invitation_token:   "tok_inv_p4q9r2",
  service_actor_ref:  "system_onboarding_svc",
  actor_credential:   <service credential>
) → declined
```

### A lost reply — an open intent an operator closes

An [Onboard] call's reply is lost after it issued the onboarding transaction; the caller reads recording-failure(outcome) and does not re-run the call:

```
onboard(
  invitation_token:       "tok_inv_g7h2k1",
  accepting_identity_ref: "newhire@acme.com",
  ...
) → recording-failure(outcome, invocation_id)
```

Internally: the invocation open landed the intent; the transaction's reply did not arrive within the commit round trip, so the arm is unknown (Recoverable Invocation commit 6) and [Onboard] called the invocation yield (Action wiring 60). The intent stays open. Once it is past the examine edge the sweep runs the onboarding probe: the invitation is accepted by the intent's accepting identity reference, the composition selects `party_4421` from the parties Party Identity's read answers, enrolled under the intent's document pair, and Credential's read finds `cred_7791` registered for it, so the probe answers undecidable carrying both (Term onboarding probe), and the sweep surfaces the intent on the compliance surface, the composition naming no service identity (Recoverable Invocation service identity 1b). An administrator reads the candidates and closes the intent through the invocation resolve, naming `onboarding.completed` carrying `{tok_inv_g7h2k1, newhire@acme.com, party_4421, cred_7791}`. The composition chooses nothing (Recoverable Invocation reconcile step 3.11), and Check 7.3 finds a party the administrator names that another token's completion record already names.

### Credential collision — a refusal that leaves the invitation pending

The call is the happy path's. Internally: the invocation open lands the intent; `Invitation.accept` answers accepted and `Party Identity.enroll` answers `party_4421`; `Credential.register(principal_ref="party_4421", ...)` answers duplicate-active-credential, because an external writer registered under that principal reference first (Edge cases — *Credential collision*):

```
onboard(
  invitation_token:       "tok_inv_g7h2k1",
  accepting_identity_ref: "newhire@acme.com",
  ...
) → duplicate-active-credential
```

The transaction rolls back: the accept and the enroll are undone and the invitation stays pending (Action wiring 61, Execution Contract Database 1). [Onboard] closes the arm through the invocation refuse, which records `onboarding.refused` naming the code, and refuses with duplicate-active-credential (Action wiring 32, 58). The attempt survives as the intent and the refusal record; an administrator settles whose credential holds the namespace, and a fresh call onboards the invitation.

---

### Regulated adversarial scenarios

**Regulator audit.** A HIPAA (US Health Insurance Portability and Accountability Act) compliance officer asks: *"Can you prove that every user who currently has access to the system was admitted via a documented invitation from an identified, authenticated internal actor — and that the actor was permitted to admit them?"* The auditor queries the Audit Trail for all `onboarding.completed` events. Each event carries `{invitation_token, accepting_identity_ref, party_id, credential_id}`. For each `party_id` in the system with an active credential, the auditor confirms a corresponding `onboarding.completed` event exists in the Audit Trail (Invariant 4) — walking the active credential's rotation chain back through predecessor records to the `credential_id` the event names, since the credential registered at onboarding has usually been rotated since (Generation acceptance check 2). The Invitation record for each invitation_token names the inviter_ref — the actor whose credential the `invitation.initiate-attempt` record verified. Invariant 1 (invitation gates enrollment) is the structural guarantee: the `onboarding.completed` event is only produced if `Invitation.accept` succeeded, and the Invitation record names who *issued* the access, authenticated and attributed. The second half of the regulator's question — whether that actor was *permitted* to — is answered from the composed Permissions instance's records for `invitations:initiate` at the invitation's `initiated_at`, not from this composition's, which never checks it (Edge cases — *Inviter and revoker authorization*). Both halves are provable; they are two records, not one.

**Disputed onboarding.** A former employee claims: *"My account was created without my knowledge — I never accepted an invitation."* The investigator queries the Audit Trail for `onboarding.completed` events whose `party_id` matches the former employee's record. The event is found. The Invitation record for the invitation_token in that event shows inviter_ref (who sent it), accepting_identity_ref (the external reference supplied at acceptance time), and `accepted_at` (when the acceptance was committed). Invariant 2 (identity binding at accept) is the structural guarantee: the accepting_identity_ref was supplied by the caller at `Invitation.accept` time, not pre-populated by the inviting actor. Whether the former employee personally presented the token or whether someone else held the token and supplied the reference is outside the composition's scope — the composition records that a bearer of `tok_inv_g7h2k1` presented the invitation and supplied `accepting_identity_ref: "newhire@acme.com"`. Further investigation of who actually controlled that email address at that moment belongs to Party Identity's identity proofing concept (Customer Onboarding) or a breach forensics investigation.

**Breach forensics.** An investigator determines that an onboarding service account's credential was compromised during a window. The question is: were any fraudulent onboardings performed using the compromised credential? The investigator joins by token, not by the completion's actor: the `onboarding.completed` event's `actor_ref` is the administrator's where an administrator closed the intent through the invocation resolve, so a completion attested by an uncompromised administrator can still belong to an arc the compromised account began. The investigator queries the Audit Trail for `onboarding.intended` events whose `actor_ref` matches the compromised service account within the compromise window, takes their invitation_tokens, and joins each to the token's `onboarding.completed` event. Each such event names `{invitation_token, accepting_identity_ref, party_id, credential_id}`. The investigator cross-references: do the invitation_token values correspond to invitations issued by authenticated inviting actors — and, against the composed Permissions instance's records, by actors permitted to invite at the time? The `invitation.initiated` event for each token names the inviter_ref, and its actor_credential attestation is independently verifiable — this is the record that carries the token, which is what makes the correlation executable from the trail alone. Any `onboarding.completed` event whose token has no `invitation.initiated` event through the composition, or whose inviter's attestation fails, is a candidate fraudulent onboarding. Invariant 4 (full Audit Trail coverage) and Invariant 5 (completion record names the full arc) together make this forensic reconstruction provable.

---

## Generation acceptance

An implementation of External Onboarding is accepted if the conformance checks below are provable to an external auditor from the Audit Trail and the constituent records, reading under the standing rules; the external checks name the deployment facts no record carries.

### Conformance checks

```
Check 1.1: An auditor MUST find the invitation token of EVERY completion record naming an invitation whose status EQUALS accepted (Invariant 1.1).
Check 1.2: An auditor MUST find the acceptance instant preceding the completion record's recording instant PER the clock offset allowance (Invariant 1.1).
Check 1.3: An auditor MUST find the completion record's accepting identity reference equal to the invitation's (Invariant 2.1).
Check 2.1: An auditor MUST find the credential id of EVERY completion record naming a credential, in any status, whose principal reference equals the completion record's party id (Invariant 3.1).
Check 2.2: An auditor MUST find EVERY link of a rotated credential's successor chain carrying the same principal reference (Invariant 3.1).
Check 2.3: An auditor MUST NOT require the registered credential to stand active (Invariant 3.1).
Check 3.1: An auditor MUST find no registration instant preceding the party's enrollment instant for a completion record's credential PER the clock offset allowance (Wiring decision 2).
Check 4.1: An auditor MUST find no completion record for an invitation whose status DOES NOT EQUAL accepted (Invariant 1.1).
Check 4.2: An auditor MUST find no completion record without an intent record for the invitation token (Invariant 1.1).
Check 5.1: An auditor MUST enumerate EVERY accepted invitation carrying no completion record AND no intent record for the invitation token (Invariant 4.1).
Check 5.2: An auditor MUST enumerate EVERY intent record followed by no completion record AND no refusal record for the invitation token, which Recoverable Invocation's checks read against the closure window (Invariant 4.1).
Deleted: Check 5.3. Unreachable: no interruption record is written (Action wiring 30).
Deleted: Check 5.4. Unreachable: no resume record is written (Resume 33).
Check 6.1: An auditor MUST find a decline record for EVERY declined invitation AND a revoke record for EVERY revoked invitation (Invariant 4.1).
Check 6.2: An auditor MUST find an initiated record carrying the invitation token for EVERY invitation (Invariant 4.2).
Check 6.3: An auditor MUST find EVERY initiated record naming an invitation that exists (Invariant 4.2).
Check 6.4: An auditor MUST NOT read an initiate attempt as a per-invitation signature (Action wiring 3).
Check 7.1: An auditor MUST find no invitation token carrying two completion records (Invariant 4.4).
Deleted: Check 7.2. Unreachable: no interruption record or resume record is written, and a completion record's party id is the one the operator or the transaction names once (Check 7.3).
Check 7.3: An auditor MUST find no party id on the completion records of two invitation tokens (Invariant 4.5).
Deleted: Check 7.4. External check 10 owns it, because no record carries a second writer.
Check 8.1: An auditor MUST read Recoverable Invocation's checks over the act kind's records as this composition's own (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the onboarding completion bound confirmed MUST read the deployment's own configuration (Capability requirement 5).
External check 2: An auditor needing the clock offset allowance confirmed MUST read the deployment's own configuration (Capability requirement 7).
External check 3: An auditor needing the audit horizon confirmed MUST read the Audit Trail instance's retention policy (Capability requirement 9).
External check 4: An auditor needing the minted-id width bounds confirmed MUST read the deployment's own declaration (Capability requirement 11).
Deleted: External check 5. Execution Contract Database 2 owns it.
Deleted: External check 6. Execution Contract Database 2 owns it.
External check 7: An auditor needing the routing obligation confirmed MUST read the deployment's own wiring (Composes 9).
External check 8: An auditor needing an actor reference's authorization confirmed MUST read the composed Permissions instance's records (Non-goal 2).
External check 9: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 6).
External check 10: An auditor needing a second writer ruled out MUST read the deployment's own wiring (Wiring decision 5).
Deleted: External check 11. The longest resume gap retired with the resume arm (Capability requirement 24).
External check 12: An auditor needing the commit round trip, the probe round trip, the reconciliation run bound AND the settling period confirmed MUST read the deployment's own declaration (Capability requirement 29).
External check 13: An auditor needing the retention of the Invitation, Party Identity AND Credential records confirmed MUST read the deployment's own configuration (Capability requirement 31).
```

### Standing rules

```
Standing rule 1: An auditor MUST read a payload-keyed query as an enumerate-and-filter over the substrate's sequence-range read.
Standing rule 2: An auditor MUST compare two seams' stamps PER the clock offset allowance.
Standing rule 3: An auditor MUST read a discrepancy inside the clock offset allowance as inconclusive.
Standing rule 4: An auditor MUST quantify an Invitation-record check over the dedicated Invitation instance alone.
Standing rule 5: An auditor MUST quantify a trail-walking check over the arcs inside the horizon.
Standing rule 6: An auditor MUST read a purged event as lawful destruction.
Deleted: Standing rule 7. Execution Contract Database 1 owns it.
Standing rule 8: An auditor MUST join the Audit Trail's records and the Invitation's record on the invitation token, and the party and credential records on the party id (Check 2.2, Check 7.3).
Standing rule 9: An auditor MUST NOT pair an attempt record with an outcome, an intent record paired with the intent record's outcome by invocation id excepted (Recoverable Invocation Primitive policy 5).
```

Term arcs inside the horizon: the invitations whose `((acceptance instant + audit horizon) - clock offset allowance)` DOES NOT PRECEDE the auditor's now — or, for an invitation never accepted, whose `((initiation instant + audit horizon) - clock offset allowance)` DOES NOT PRECEDE the auditor's now — the membership test for an Invitation record under Standing rule 5.

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
Non-goal 10: The composition MUST NOT record an attempt the credential gate refused.
Non-goal 11: A deployment needing refused attempts recorded MUST compose Failed-Attempt Log.
Non-goal 12: The composition MUST NOT index the trail by payload.
Non-goal 13: A deployment needing an indexed payload lookup MUST compose Reverse Index.
Non-goal 14: The composition MUST NOT complete a stopped onboarding.
Non-goal 15: A deployment needing a stopped onboarding closed MUST call Recoverable Invocation's the invocation resolve.
Non-goal 16: The composition MUST NOT choose among the candidates the onboarding probe answers.
Non-goal 17: The composition MUST NOT exclude from the onboarding probe's candidates a party another invitation token's records name.
```

NOTE: the owners — a [Permissions](../atoms/permissions.md) instance over the invitation initiate and invitation revoke scopes, checked by the caller before [Invite] and [Revoke] or by a wrapping composition such as [Session-Gated Authorization](./session-gated-authorization.md) or [Attributed Permissions Admin](./attributed-permissions-admin.md) (Non-goal 1 through 3, External check 8); a principal calling [Credential](../atoms/credential.md)'s rotate directly (Non-goal 7).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST take the clock offset allowance at the reading of a cross-seam comparison (Recoverable Invocation Allowance 4).
Deleted: Clock semantics 2. Recoverable Invocation Allowance 4 and Allowance 6 own it: in-flight and aged are read at the reading, and an edge excludes a record from a pass.
Deleted: Clock semantics 3. Recoverable Invocation Invariant 7 owns it: the horizon edge is read toward not reading.
```

### Concurrency

```
Concurrency 1: Two fresh accepts of one invitation token MUST resolve through Invitation's single resolution.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an arc's reads and the writes they decide are one transaction, and the composition names no holder for a resumer to race.
Concurrency 4: Two [Onboard] calls of one invitation token in flight MUST resolve through the act's critical section, the second answering act-in-flight (Recoverable Invocation open step 3.5).
```

### Credential collision

Party Identity's enroll in the same transaction minted the party id of this very call, so no earlier registration under it through this composition is possible; duplicate-active-credential there can only be a principal reference collision — an external writer registering a credential of the call's credential type under the same principal-reference namespace as this composition's party ids, which the shared-surface posture of Credential admits and this composition cannot see. The onboarding transaction rolls back (Action wiring 61): the accept, the enroll and every write of the call are undone, the invitation stays pending, and the invocation refuse records the attempt and the code; [Onboard] refuses with duplicate-active-credential, a state conflict, not an infrastructure failure. Administrator review decides whose credential holds the namespace, and the invitation is onboarded by a fresh call once it is settled.

### Partial failure

A Party Identity or Credential refusal inside the onboarding transaction, or an Audit Trail refusal of the completion record's own write, never leaves a partial arc committed by the transaction: a refusal of any of its three calls rolls the transaction back, the invocation refuse closes the arm, and the caller reads the constituent's own code (Action wiring 58, Execution Contract Database 1); the intent and the refusal record alone stay (Execution Contract Database 3). What can remain is Recoverable Invocation's: an intent whose outcome is owed after a lost reply or a failed the invocation close, which the sweep reports and an administrator closes through the invocation resolve, and a refusal record that did not land. The onboarding probe answers undecidable for a committed arc and the composition chooses nothing (Non-goal 16).

---

## Composition notes

**Relationship to Customer Onboarding.** External Onboarding admits a party to the system in `Unverified` state. Customer Onboarding drives the identity verification workflow that transitions the party to `Verified`. The two compositions address adjacent points in the regulated identity lifecycle: External Onboarding is the admission gate; Customer Onboarding is the verification gate. A deployment requiring `Verified` status before granting access to regulated functionality places Customer Onboarding downstream of this composition in the onboarding pipeline.

**Relationship to Login.** External Onboarding registers the credential. Login uses that credential: `login(principal_ref, credential_type, presented_material, ...)` calls `Credential.verify`, and on success issues a Session. After a successful [Onboard], the principal can immediately call `login` using the registered credential_type and their credential material. The two compositions are adjacent lifecycle boundaries: External Onboarding creates the credential record; Login produces the authenticated session.

**Relationship to Session-Gated Authorization.** Once the onboarded principal has an active session (from Login), runtime authorization queries flow through Session-Gated Authorization: `check_permitted(session_token, action_scope)` gates every permission check on session validity. External Onboarding is the entry point; Session-Gated Authorization is the access-time gate.

**Relationship to Attributed Permissions Admin.** Once onboarded, the principal appears as a subject in Permissions. An authorized actor calls `Attributed Permissions Admin.grant(subject_ref=party_id, action_scope, ...)` to grant the newly onboarded party access to specific scopes. The `party_id` produced by External Onboarding becomes the `subject_ref` in Permissions grants.

**Recoverable Invocation.** [Onboard] follows [Recoverable Invocation](./recoverable-invocation.md) around its arc (Composes 17 through 19): an intent before the onboarding transaction, the completion record as its outcome, a refusal record where a call refuses, the act's critical section over them, and a sweep and an operator's the invocation resolve for what an invocation left open. The page binds the act kind once (Term onboarding binding) and restates none of the protocol. [Invite], [Decline] and [Revoke] are not bound, since each is one constituent write and one record under the credential gate (Composes 20).

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; this page's is three calls in one database transaction (Term onboarding transaction), whose partition belongs to the transaction, Invitation's accepted being rolled back when Credential refuses. Recoverable Invocation's closed list of deviations has no entry for it, and the page treats the transaction as the commit and records the mismatch as an open line (Recoverable Invocation Deviation 2).

**Forthcoming-link resolution.** The Invitation atom's *Composition notes* listed "External Onboarding *(not started)*" as a forthcoming composition. That link is now live. Invitation's `Composition note 2` and `Composition note 3` once asked this composition to pass the accepting identity reference *as the party record's reference* and to register the credential *against the accepting identity reference*; Party Identity mints the party id at its own seam and takes no such input, and the credential is registered against that party id (Invariant 3.1), so this composition links the accepting identity reference to the party on the completion record instead (Invariant 2.1), and Invitation's two notes now say so.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes and the nine Audit Trail events it declares (Term value sets), the records of which the entries below name. It owns no cross-atom state — the Audit Trail *is* the map — so no records of its own carry a term entry. The deployment settings keep their wire spellings in configuration — `onboarding_completion_bound`, `clock_offset_allowance`, `audit_trail_retention_policy` — and the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; a deployment; an auditor; a caller; an administrator; an investigator; an invocation; an action; an arc; a completing arc; an attempt record; a post-write record; the landing read; an admitted invite; a landed invite; an admitted onboard; an admitted decline; a landed decline; an admitted revoke; a landed revoke; an initiate attempt; an initiated record; a completion record; an operator; a refusal record; an intent record; a decline attempt; a decline record; a revoke attempt; a revoke record; an invitation; a party; a credential; an enroll; the slowest conforming invocation; the seam skew.

Term records: the attempt records and post-write records the composition writes through the substrate — each an Audit Trail event carrying one event type below.

Term record verbs: serve, change, inherit, read, hold, route, claim, select, query, attest, declare, make, store, supply, take, mint, set, configure, agree, refuse, answer, validate, record, size, write, stop, proceed, run, match, alert, call, verify, establish, continue, discard, accept, pass, complete, keep, filter, choose, pair, follow, enroll, carry, name, stand, appear, find, require, enumerate, report, compare, quantify, join, authorize, compose, rotate, check, enforce, index, widen, resolve, retry, bind, inject, disclose, remove, close, commit, exclude.

Term value sets: event type = invitation.initiate-attempt | invitation.initiated | onboarding.intended | onboarding.completed | onboarding.refused | invitation.decline-attempt | invitation.declined | invitation.revoke-attempt | invitation.revoked. The rest are declared where the section that owns each declares it: position. Recoverable Invocation derives onboarding.recovery_intended, onboarding.abandoned and onboarding.escalated from the vocabulary (Recoverable Invocation journal 3).

Term bounds: onboarding completion bound (onboarding_completion_bound), clock offset allowance (clock_offset_allowance), audit horizon (audit_trail_retention_policy), minted-id width bounds, settling period, probe round trip, commit round trip.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, substrate, trail, completion relation, onboarding completion bound, clock offset allowance, audit horizon, minted-id width bounds, slowest conforming invocation, seam skew, refusal record, intent record, invocation id, reconciliation run bound, settling period, probe round trip, commit round trip, onboarding probe, commit partition, onboarding transaction, act key, onboarding binding, act kind, required input, actor reference, actor credential, credential material, call's expiry instant, service actor reference, attempt record, post-write record, retention step, landing read, position, onboarding result, invitation refusal, validated invite, admitted invite, landed invite, validated onboard, admitted onboard, arc, completing arc, validated decline, admitted decline, landed decline, validated revoke, admitted revoke, landed revoke, revocation reason, covered transition, covered initiation, arcs inside the horizon, initiate attempt, initiated record, completion record, decline attempt, decline record, revoke attempt, revoke record.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the conforming, no-stored-state classification. record_action, read_record, proceed as landed, compliance alert, reference length cap, payload cap, recording instant, event id, action reference: Audit Trail. invitation token, accepting identity reference, acceptance instant, initiation instant, expiry bound, stored terminal, status, inviter reference, invitee reference, context, revoked by reference, ttl bounds: Invitation. party id, enrollment instant, enrolling actor reference, document type, document reference, name, date of birth: Party Identity. credential id, credential type, principal reference, registration instant, expiry instant: Credential.

Term composing patterns: Failed-Attempt Log *(forthcoming)*; Reverse Index *(forthcoming)*; [Permissions](../atoms/permissions.md); [Customer Onboarding](./customer-onboarding.md).

Term initiate attempt: the invitation.initiate-attempt event — [Invite]'s attempt record.

Term initiated record: the invitation.initiated event — [Invite]'s post-write record, carrying the invitation token.

Term intent record: the onboarding.intended event — [Onboard]'s attempt record, written by the invocation open before the onboarding transaction.

Term completion record: the onboarding.completed event — an [Onboarding Completed].

Term refusal record: the onboarding.refused event — [Onboard]'s record of a pre-commit refusal, written by the invocation refuse, naming the constituent's code.

Term decline attempt: the invitation.decline-attempt event — [Decline]'s attempt record.

Term decline record: the invitation.declined event — [Decline]'s post-write record.

Term revoke attempt: the invitation.revoke-attempt event — [Revoke]'s attempt record.

Term revoke record: the invitation.revoked event — [Revoke]'s post-write record.

#### Invite

The composition action that initiates an invitation from an authenticated, attributed actor to an external party — the initiate attempt first, whose attestation is the credential check, then Invitation's initiate, then the initiated record carrying the token — answering the invitation token the inviter delivers out of band (Action wiring 3 through 7).

Kind: Operation

#### Onboard

The composition's load-bearing action: accept an invitation and, in one fixed sequence gated by Invitation's accept, enroll the invitee as an unverified party and register the party's credential, the three calls one transaction — following Recoverable Invocation around it, so that the [Onboarding Intended] precedes it, and the [Onboarding Completed] follows a commit or the [Onboarding Refused] a refusal (Action wiring 9, Action wiring 17 through 21, Action wiring 26 through 32, Action wiring 37 through 38, Action wiring 56 through 61). A stopped onboarding is never resumed: an open intent is closed by the operator's the invocation resolve, and the invitation is never re-accepted. No enrollment occurs unless the gate clears (Invariant 1).

Kind: Operation

#### Decline

The composition action that records an invitee's deliberate refusal of an invitation through Invitation's decline and attests it under the system service account (Action wiring 40 through 47).

Kind: Operation

#### Revoke

The composition action that withdraws a pending invitation before the invitee acts, through Invitation's revoke, attributing the revocation to the revoking actor (Action wiring 48 through 55).

Kind: Operation

#### Onboarding Intended

The Audit Trail event the invocation open records before the onboarding transaction — carrying the invitation token, the accepting identity reference, the document type and document reference, and the credential type — the record Recoverable Invocation's sweep and an operator read to close an onboarding that stopped. An accepted invitation with neither this event nor a completion record is Check 5.1's gap signature.

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.intended

#### Onboarding Completed

The Audit Trail event the invocation close records on a committed arc — naming the invitation, the accepting identity, the party record and the credential in one tamper-evident entry. The provable answer to *what invitation authorized this party's creation?* (Invariant 5.1).

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.completed

#### Onboarding Refused

The Audit Trail event the invocation refuse records when the onboarding transaction refuses before it commits — naming the constituent's code, so the attempt survives the refusal that rolled the transaction back (Action wiring 58).

Kind:       Member
Member of:  the onboarding event
Role:       Audit event
Projection: onboarding.refused

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Invite]: #invite
[Onboard]: #onboard
[Decline]: #decline
[Revoke]: #revoke
[Onboarding Intended]: #onboarding-intended
[Onboarding Completed]: #onboarding-completed
[Onboarding Refused]: #onboarding-refused

---

## Standards references

*Anchors: GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Articles 6–7 (lawful basis for processing at invitation and acceptance time); HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(a)(1) (access control — invitation-based provisioning as a covered access-granting event) + section 164.312(d) (person or entity authentication — credential registration at onboarding); SOC 2 (Service Organization Control 2 — an audit standard for service-provider security controls) CC6.2 (prior to issuing system credentials, new internal and external users are registered and authorized); NIST (National Institute of Standards and Technology) SP (Special Publication) 800-63A (identity enrollment and identity proofing — the enrollment arc); SCIM 2.0 (System for Cross-domain Identity Management) RFC 7644 (RFC — Request for Comments, the IETF’s, Internet Engineering Task Force’s, numbered standards series — the invite-then-provision flow); FATF (Financial Action Task Force — the international anti-money-laundering standard-setter) Recommendations 10–12 (customer due diligence at onboarding — Party Identity in Unverified state is the enrollment record the regulator requires; verification belongs to Customer Onboarding).*

**GDPR Articles 6–7** require a lawful basis for processing personal data. The [Invite] action creates the first processing record: the system holds invitee_ref and processes data about the invitee from that moment. The [Onboard] action creates the accepting_identity_ref binding and the Party Identity enrollment — the data subject's active engagement with the system. The Audit Trail records both as the GDPR Article 5(2) accountability records.

**SOC 2 CC6.2** requires that prior to issuing system credentials, new users are registered and authorized. The composition supplies the *registration* half and the *ordering* structurally: `Party Identity.enroll` (registration) precedes `Credential.register` (credential issuance), and both are preceded by `Invitation.accept` — and the invitation itself by [Invite], whose initiated record attributes it to an authenticated inviting actor. The *authorization* half — that the inviting actor was permitted to admit this user — is not something this composition checks or records: its gate verifies the inviter's credential and attributes the act, and whether the inviter held the authority is the composed Permissions instance's record (Non-goal 1 and Non-goal 2). A CC6.2 claim rests on both records together, and a deployment that wires no authorization gate above [Invite] has the ordering and the attribution but not the authorization.

**NIST SP 800-63A** defines the enrollment event at which an applicant registers with an identity system. The [Onboard] action is that enrollment event. The composition does not perform identity proofing (the transition from Unverified to Verified in Party Identity) — that belongs to Customer Onboarding. The composition records the enrollment inputs (name, date_of_birth, document_type, document_ref) and the enrolling actor, satisfying 800-63A's enrollment record requirements.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — vote yes: the invitation gate, single resolution, the whole arc (a refusal, a credential collision included, leaves the invitation pending), credential follows party, an intent before every completion, and audit coverage; re-derived 2026-11-10 over what is this page's own, against Recoverable Invocation's contracts, which that page's model proves, in place of external-onboarding.tla of 2026-06-03 over a single-pass arc with no resume: external-onboarding.tla + 10 twins (-buggy-gate, -partial, -nointent, -resolvewild, -enrollfree, -orphanparty, -credfree, -nocred, -badstatus, -ghostaudit), each of the 12 checks of Safety caught by at least one twin alone; not modeled: the onboarding probe, the purge of an old completion record and an operator's choice among candidates, which the page states as detected, not prevented (Invariant 4.6, Check 7.3), and Recoverable Invocation's protocol itself (its own model); TLC, 2,243 states, 2026-11-10
last gate: 2026-11-10 — Final Critique 18, full, frozen at 4e49308 — foundational count 1 (of 9 claimed across the three passes, 6 distinct: the onboarding probe read Party Identity by the intent's document pair and enrolling actor reference, axes Party Identity's declared read refuses (Query axes, Invalid Query), so every probe answered unavailable or a build matched the parties itself, found by all three passes and cured by Term onboarding probe reading with a query carrying no filter (Execution Contract Query 4) and selecting the parties in the composition's own code; 4 refuted on rules the page cites or the Opus call decided — Action wiring 59 reading a refusal or an abandonment as an outcome, claimed by two passes (Recoverable Invocation open step 3.9, Term closing record and journal 4: only an outcome record lands act-landed), the attempt-evidence arms against the one-transaction preamble (Term position, Audit arm 21, 23 and 24), the post-write record's no answer (the preamble and Execution Contract Error model 1), and Invariant 4.5 against Invariant 4.6 and Non-goal 17; 1 is an open line already recorded, Audit Trail's 2026-10-05-a; the refining cured or recorded as open lines 2026-11-10-b and 2026-11-10-c), cured, not clean, no sample; 2026-11-09 — Final Critique 17, full, frozen at 4c094e9 — foundational count 3 (of 11 claimed across the three passes: Resume 28 obliged a resume record on a call that answered onboarding-indeterminate carrying the party candidates, so the administrator's follow-up carrying the chosen party met Resume 8's young resume record, and Resume 28 now excepts that answer; the audit horizon's two readings, open line 2026-11-09-d, cured by Term aging margin carrying the max purge delay, Term max purge delay and Capability requirement 25 and 26; the collision credential kept as the sole chain root, open line 2026-11-08-d, cured by Resume 40 excluding a credential registered before the party's enrollment per the clock offset allowance; 4 refuted on rules the page cites or the Opus call decided — the two resumers' race and the bound's anchor on Execution Contract Database 1 and Database 2, the fresh-arc intent answers on Constituent failure 1, Database 1 and Read 4, the interruption record's refused write on Term onboarding result, Action wiring 36 and Read 7; 3 are open lines already recorded, 2026-11-06-a, 2026-11-05-a and Audit Trail's 2026-10-05-a; the 1 claimed on Primitive policy 3 and the refining cured or recorded as open lines 2026-11-09-e through 2026-11-09-j), cured, not clean, no sample; 2026-11-09 — Final Critique 16, delta, frozen at 3632caa — foundational count 1 (Linus claimed 1: Resume 42 answered onboarding-indeterminate on a credential reading of none while Resume 44 answered invalid-request on the same call when it carried a resume credential id, two answers obliged on one input, so Resume 42 now carries the exclusion the party arm's Resume 52 already has; the 4 refining claimed: one refuted on pressure-testing.md *A cure is re-read by its diff*, which sets the reach as the rules that rest on a change and not the rules a changed rule cites, one cured by Resume 30a, which keeps the stage the stage reading established across Resume 30's acceptance record, one refuted on Term fresh arc and Term resumable acceptance, under which an acceptance record never stands on a pending invitation, and one cured by Term aging margin citing Capability requirement 8, which already bounds the skew; the 1 rhetorical cut), cured, not clean, no sample; 2026-11-09 — Final Critique 15, delta, frozen at 0e67739 — foundational count 0 on the counted pass and 2 beyond it, both cured (Linus claimed 0 and one refining, Resume 22b's two obligations, split into 22b and 22c; the formal layer's outside read broke Invariant 4.5 through the purge margin of open line 2026-11-08-b: another token's records purged at the audit horizon while Term aged acceptance still aged an arc one allowance early and the window union still reached the party, so the foreign party record filter was blind to it, cured by Term aging margin, two allowances, and Term aged acceptance reading its own instant; and the settle's own, Retention Window purging at the retention deadline against a strict aged test, which let an arc's own records be purged while it was not aged and its resume complete it twice, the same cure by Clock semantics 3; the blind second triage placed the outside read refining and Linus's declined Check 3.1 question, open line 2026-11-08-d, foundational, and the settle held the first foundational on the page's own reading of a purged completion as present, Decision 2026-08-30, and left the second the recorded line; open line 2026-11-08-b closed, 2026-11-09-d opened), cured, not clean, no sample; 2026-11-09 — Final Critique 14, delta, frozen at 28f1b6f — foundational count 2 (Linus claimed 3: Audit arm 22 and 25 answered outcome on a fresh arc where Execution Contract Constituent failure 1, Database 1 and Read 4 refuse the whole call, so the arms answer intent outside the resume arm, Audit arm 5 with them, decided by the Opus call; Resume 22 and 23 tested a resume party id against a candidate set read only at the stage unrecorded, so Resume 22 and 23 now read the stage and Resume 22a and 22b give the other stages; one refuted on a rule the page cites, Audit arm 24 on the attempt-evidence retry, and the 2 refining claimed are refuted on Database 1 and routed to tooling, with open lines 2026-11-09-a and 2026-11-09-c closed), cured, not clean, no sample; 2026-11-09 — Final Critique 13, delta, frozen at e590409 — foundational count 0 (Linus claimed 3, all refuted on rules the page cites — Database 1, Constituent failure 1 and Partial failure on the acceptance record a fresh-arc Party Identity or Credential refusal rolls back with the accept; Action wiring 26, 29 and 30 with Resume 39 and 47 on an interruption record or a credential reading before the acceptance record or the party; and three refining refuted, with Resume 10 given the acceptance clause as a tidy-up, Resume 22's stage open as line 2026-11-09-c and the acceptance half of line 2026-11-09-a closed), clean, one sample, the blind second triage agreeing; 2026-11-09 — Final Critique 12, delta, frozen at 1b9ea24 — foundational count 1 (Linus claimed 4: Term party candidates restricted the party read to a several reading where Resume 17, 20, 22 and 23 read it on a sole one; three refuted on rules the page cites — Database 2 and Concurrency 3 on two resumers, Constituent failure 1, Database 1 and Read 4 on the fresh-arc intent answers, and open line 2026-11-05-a with the Credential collision edge case on the empty credential candidates), cured, not clean, no sample; 2026-11-09 — Final Critique 11, full, frozen at d7264ab — foundational count 3 (of 10 claimed across the three passes and the formal layer's counterexample before the freeze, which no reader reported: Resume 30 sourced the resumed acceptance record's document pair from a record that carries none, found by two passes; Term onboarding result promised an interruption record to every onboarding-indeterminate answer where Resume 21 owes none; and the clock offset allowance bounded each seam against the composition's clock only, so two constituents' stamps could differ by twice the allowance and the resume window missed the arc's own party, Invariant 1.2 failing; 4 refuted on rules the page cites — Database 1 and 2, Read 4, Constituent failure 1, Action wiring 36 — and 3 are open lines already recorded, 2026-11-06-a, 2026-11-08-d and Audit Trail's 2026-10-05-a), all cured, not clean, no sample; 2026-11-09 — Final Critique 10, delta, frozen at d6ee726 — foundational count 0 (Linus claimed 4: three refuted on rules the page cites — Database 1 and 2, Constituent failure 1 and Read 4, Resume 14 on the accepting identity reference — and one refining, the Term stage gloss reconciled to Resume 9 through 12), clean, one sample, the blind second triage agreeing; 2026-11-09 — Final Critique 9, delta, frozen at 266bfb7 — foundational count 1 (Linus claimed 2: one stands, narrowed by the Opus call to Audit arm 15 and 16 answering outcome on a fresh arc where Constituent failure 1 and Read 4 roll the accept back, against Term position (outcome); the other repeats open line 2026-11-08-a and is refining), cured, not clean, no sample; 2026-11-08 — Final Critique 8, delta, frozen at d805eac — foundational count 2 (Linus claimed 3: one stands, the Term candidates payload-cap gap; two are open lines already recorded, refined or refuted on the rules; and one the blind second triage found that no reader reported, the attempt a refusal erases in [Onboard]'s signature), both cured, not clean, no sample; 2026-11-08 — Final Critique 7, full, frozen at 28a3a20 — foundational count 2 (of 13 claimed, one of them the formal layer's counterexample before the freeze; 7 refuted on rules the page holds or the constituent declares, 4 refining), both cured, not clean, no sample; 2026-11-06 — Final Critique 6, delta, frozen at 47b6606 — foundational count 0 (the 1 claimed refuted on rules the page holds), clean, one sample; 2026-11-05 — Final Critique 5, delta, frozen at b1ae778 — foundational count 2 (of 3 claimed, 1 refuted on rules the page holds), all cured, not clean, no sample; 2026-11-04 — Final Critique 4, full, frozen at 25a720e — foundational count 5 (of 8 claimed, 3 refuted on rules the page holds), all cured, not clean, no sample; 2026-08-30 — third gate, fresh reader, under the frozen rules — 6 foundational corrected in-round, 13 refining and 3 rhetorical routed (2 refining since closed), 5 foundational closure residue corrected in a second pass

open:
- 2026-11-09-j · refining · Capability requirement 1; Action wiring 3, 6, 37, 56 · now is used in rules without a citation to Execution Contract Logic confinement 11, and no rule passes the event type as Audit Trail's action_ref → cite the first and name the second in the Audit arm
- 2026-11-10-b · refining · Term onboarding probe · the probe's party and credential sets are outcome fields with no cardinality cap, so many parties sharing one document pair and enrolling actor reference could carry the answer past a bound no rule names → decide the cap with Recoverable Invocation's surfaces for candidates, or declare the sets bounded by Party Identity's own bounds
- 2026-11-10-c · refining · Capability requirement 31 · the removal bound reaches the record's onboarding outcome, and a record of an invitation no onboarding was attempted for (declined, revoked, lapsed) carries none, so the rule is silent on when such a record may go → decide whether it goes on its own retention or on the audit horizon alone
- 2026-11-10-a · refining · Composition notes; Term onboarding transaction · Recoverable Invocation's bound commit is one constituent call and this page's is three in one database transaction, a case Recoverable Invocation's closed deviation list does not name (Recoverable Invocation Deviation 2) → carry to Recoverable Invocation's next revision as evidence, or declare it there
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/external-onboarding.md`; the migration and the earlier gate record that got it here are in [its history](./external-onboarding.hist.md).

- **2026-11-10 — The resume arm retired: an onboarding is one Recoverable Invocation act.** *Chose:* (Scott, 2026-11-09 8:46 PM and 9:17 PM Central, "Reuse the Recoverable Invocation pattern", then "A") [Onboard] binds one act kind, onboarding, keyed by the invitation token, with the transaction of accept, enroll and register as its bound commit; a credential collision is a pre-commit refusal that rolls the transaction back and leaves the invitation pending, the invocation refuse keeping the attempt; Resume 4 through 52 tombstoned to what owns them; a stopped onboarding is an open intent the operator closes through the invocation resolve; no service identity (Composes 15 and 16 stand), so Recoverable Invocation's closure is provisional here; [Invite], [Decline] and [Revoke] stay unbound; the acceptance, interruption and resume records retired; the foreign-party exclusion and the check of an operator's chosen party against the candidates retired, so Invariant 4.5 is detected through Check 7.3, not prevented. *Over:* keeping the committed collision and the resume arm, wrapped in Recoverable Invocation, which would have covered about 15 of its 49 rules and left the rest, where eleven of the last twelve foundational findings sat, the page's own. *Because:* Recoverable Invocation never re-runs an act (its reconcile step 3.7 and Non-goal 4), so it cannot finish a stopped arc, and the stopped arc existed only because the page made the collision an answer. *Costs:* a Lease host, the instance's bounds and a sweep; every caller-visible code of [Onboard] changes (act-in-flight, recording-failure in place of storage-failure(position), duplicate-active-credential a refusal); Party Identity and Credential keep no pairing datum, so every open intent goes to an operator, a sole candidate included.
- **2026-10-20 — The store's guarantees cited, not restated, the per-token critical section among them.** *Chose:* Capability requirement 21 citing Execution Contract Store 1 through 4 for the store the four constituents keep their records in; the rules restating what that store guarantees tombstoned to it — the host's critical section keyed by invitation token, with its supply, its exclusion across nodes, the fresh arc's take at the accept, every write under it, its release, its lease, its expiry, its loss and re-take, the refusals when the host withheld it and the bar on starting without it (Capability requirement 13 through 17, 20, Action wiring 10 through 16, 39, Resume 1 through 3, 38, Concurrency 2, 3, External check 5, 6); and the machinery that existed only because a split write or an invocation seen between its writes could leave a partial: the substrate's recording-failure at the retention step read as an appended event — proceeded as landed, never retried, alerted as unretained (Audit arm 6, 7, 20, Resume 34) — which Audit Trail's own rewrite made commit nothing, a read-back of an invalid-request at step-4 that finds no record (Audit arm 12, Resume 37), since that refusal leaves the event appended inside the one transaction, the bar on a constituent write before the resume record lands (Resume 27), and the auditor's reading of a record younger than the widened bound as inconclusive (Standing rule 7). Invariant 1.3 makes the duplicate-freedom claim on the clock offset allowance alone. Rules 249 to 220. *Over:* an onboarding whose accept, records, enrollment and registration committed one by one, a fresh arc and every resumer holding a host's per-token critical section — taken at the accept or before the resume arm's first read, held to the return, released on return or death, leased for at least the widened bound, its expiry the invocation's terminus — so that a resumer past the bound enrolled beside neither a stalled original nor a second resumer. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, and that Store 2 covers a guard decided across a lease check, since the lease's grant lives in the one store. Invitation, Party Identity, Credential and Audit Trail each supply their store under Store 1 through 4, and no action here makes an act outside the store, so an onboarding's writes commit together, no resumer re-enters an arc a fresh arc is still running, and the critical section only held two arcs' reads and writes apart, which Store 2 now serializes: a later resumer reads what the earlier one committed and decides again (Resume 7, 8). An Audit Trail refusal at a post-write record on the resume arm — its recording-failure, its invalid-request below step-4, or a landing read that finds no record — still leaves the invitation write an earlier onboarding committed and its record owed (Audit arm 5, 18, 22, 25), and so does a Party Identity or Credential storage failure on the resume arm (Audit arm 15, 16); outside the resume arm each refuses the whole call, its Invitation write with it, since Audit Trail's record action step 7.11 keeps only its own attestation and event (Execution Contract Constituent failure 1, Read 4). So the census's question is decided by that reading, not escalated: the read for the credential the arc registered (Action wiring 33, 35, Resume 39 through 47) is still reached by a foreign registration under the arc's party, and it stays; so do the stages, the young and dead resume records, the party read over the arc's window union with its candidates, the resume record and the acceptance record re-derived from the Invitation record (Resume 8 through 26, 28 through 33, 36), the read-back of an invalid-request at step-4 (Audit arm 8 through 11), and the interruption record's refusal that leaves the arc's answer standing (Action wiring 36). The resume arm reads the Event Log's own sequence (Resume 6, 33) and Credential keeps its rotations as records of its own (Check 2.2), so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-09-23 — The resume arm completes with the credential the arc registered, never the credential standing active.** *Chose:* on duplicate-active-credential the resume arm reads the party's credentials of the call's type in every status, keeps the chain roots registered inside the arc's window union, continues with a sole root, and refuses none or several with onboarding-indeterminate carrying the credential candidates, behind an interruption record, with a resume credential id for the administrator's choice (Resume 39 through 47). *Over:* naming the head — the credential standing active — and widening Check 2 to accept any link of the head's chain. *Because:* the head can be a rotation successor or a foreign registration, so a completion record naming the head records what the composition did not do, against Invariant 3.1; walking back keeps Check 2.1 through 2.3 true as written. The maintainer's ruling on 2026-08-30-d.
- **2026-08-30 — One resumer per token, the arc bounded at both edges, the dead resume's party found by the arc's actors, the skew declared, the position on the code.** *Chose:* a deployment-supplied `per_token_serialization` the resume arm holds from R1's first read to its return and the fresh arc takes at step 3's `accepted` arm and holds to its return, with stated lease semantics — released on return or death, a lease at least the widened bound long whose expiry is the invocation's terminus, every write after the first made only under the section, and an invocation that lost it re-taking it and re-running R1–R2 as a resume of its own arc before writing again — so two resumers never both enroll and a stalled original is refused until its lease expires; the arc's document_type and document_ref recorded on `onboarding.accept-attempt`, `onboarding.invitation-accepted`, and `onboarding.resume-intended`, R2 matching the store against the recorded pair and a resumer whose inputs differ refused; R4 taking the post-write landings with step-4 proceeding as landed; with R1 refusing a successor-less `onboarding.resume-intended` younger than the bound and check 7 condemning two completions or two parties per token; an upper edge on the resume arm — `accepted_at` older than `audit_trail_retention_policy`'s horizon is refused, since a purged completion is not an absent one; R1 reading a dead resume's `onboarding.resume-intended` as *stage unrecorded* and R2 reading the union of windows anchored at `accepted_at` and at every resume-intended's `recorded_at`; R2 filtering on the arc's actor set from the trail rather than the resumer's identity; a `clock_offset_allowance` widening every cross-seam comparison — step 3's bound, R1's edges, R2's window, the standing rule — with Invariant 1's duplicate-freedom made conditional on it; resume_party_id on a `Pending` invitation refused at step 1 by a read before the gate; and `storage-failure(intent | outcome)` on all four signatures, the relayed constituent tokens taking the position by the same test. *Over:* a resume arm whose only gate had already fired for every resumer; a section claimed in Configuration that no fresh-arc step took, with no release, expiry, or re-take rule; a party matched on documents the resumer typed; a leg with a lower edge and no upper one; a stage read from `onboarding.interrupted` alone and a window anchored at `accepted_at` alone; "equal this invocation's" against "re-run under the caller's own identity"; a write decision on a read the constituent calls best-effort; a declared rejection no step evaluates; and a bare token on both sides of the commit. *Because:* the gate serializes the one write to `Accepted` and nothing after it, so two re-entries are two writers the atom cannot tell apart; a section with no terminus lets a stalled holder block the arc forever and a lost one lets its holder write between a resumer's pre-check and its append; and a filter on the resumer's inputs finds a different person's party or none; a lawfully destroyed completion read as absent completes the arc twice; a resume that enrolled and died leaves its party outside every window the original arc anchors; an administrator finishing a service account's arc is the recovery the edge case names, and a filter on the resumer finds nothing; a stamp another seam wrote can differ from this one's by a sign the bound does not have; and a caller who cannot tell intent from outcome re-runs a committed act (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen with its tells for uses — with §*A reconciliation is bounded at both ends*, §*Recovery commits under a declared service identity*, and §*Lawful destruction is answered before absence*; *Liveness is arithmetic* and *An outcome is sized before the intent* were swept and found no shape here beyond naming the resume payloads in step 1's sizing).
- **2026-08-29 — The gate can be re-entered but never re-accepted, and the substrate's arm keeps its step.** *Chose:* a resume arm on [Onboard] — same acceptor, acceptance older than a declared `onboarding_completion_bound`, stage established from the trail and then from the Party Identity store, candidates named where the store cannot decide, an `onboarding.resume-intended` record before any commit, then the remaining steps re-run under the caller's own identity; and every `record_action` transcription carrying `recording-failure(step)`, with the step-4 arm proceeding as landed and invalid-request read back rather than declared unreachable. *Over:* administrator completion of the constituent steps outside the composition, and a single bare recording-failure landing. *Because:* manual completion leaves the party with no completion record, which is the regulator-audit scenario's own failure produced by the recovery; and the substrate's step-4 arm means the event is already appended, so a bare token turned the retry into a duplicate-event generator (the frozen rules of 2026-08-29 — *Recovery commits under a declared service identity* and *A transcribed rejection arm keeps its payload*).
- **2026-08-27 — The gate authenticates and attributes; authorization is declared above the composition.** *Chose:* a named edge case declaring a composed Permissions instance over `invitations:initiate` / `invitations:revoke` as the deployment's authorization gate, with every "authorized actor" claim on the page downgraded to authenticated-and-attributed and the SOC 2 CC6.2 paragraph re-scoped to the registration and ordering halves. *Over:* wiring Permissions as a fifth constituent and gating [Invite] and [Revoke] on a scope. *Because:* the claim was made and neither wired nor disclaimed, which is the worst of the three states; absorbing the gate would make this composition the owner of an authorization vocabulary it has no other use for, while declaring it names the record a regulator's authorization question is answered from.
- **2026-08-26 — The attempt record is the credential gate on all four actions.** *Chose:* every state-changing action opens with a `record_action` attempt event whose Actor Identity attestation, made inside the substrate's declared surface, is the credential check; an attempt refused at the gate lands no event. *Over:* a dry-run mode the substrate does not declare, or reaching Actor Identity directly, which is a transitive constituent. *Because:* the check must live on a surface the composition actually consumes, and the attempt is then auditable for free.
- **2026-08-26 — Invariant 4 is safety plus detectability, not totality.** *Chose:* the arc's completeness is claimed over named gap signatures that checks 5 and 6 enumerate. *Over:* the unconditional statement over paths that admit invisible terminal transitions. *Because:* the composition is stateless by design and carries no marker discipline, so detectability through records is the recovery posture it can honestly offer.

- **2026-09-27 — A dead resume without an acceptance record resumes at acceptance-unrecorded.** *Chose:* Resume 9 reads the stage as unrecorded only where an acceptance record exists. *Over:* Resume 9 and Resume 11 both firing on one arc. *Because:* a resume that dies after its resume record lands and before the acceptance record Resume 30 writes leaves a dead resume record and no acceptance record, and the two rules then named two stages; the arc still owes its acceptance record, which only acceptance-unrecorded writes. Found by the cold regeneration of the demo (council read 240).

</details>

NOTE: End of External Onboarding.

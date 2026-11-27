---
title: Privileged Access Provisioning
id: 23
audience: common
nav_order: 9
---

# Privileged Access Provisioning

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>


## Summary

Privileged Access Provisioning governs the full life of a request for elevated access — to financial controls, patient records, production credentials, and the like — where the access must be approved by more than one party and must be time-limited rather than standing.

A request is submitted under a named requestor, must clear a mandatory multi-party approval chain, and only then results in a time-limited, scoped access token being issued; every time that access is actually used, the presenting principal's session is checked for validity first, and the record of the use names that principal.

It combines six patterns: the multi-party approval gate, credential authentication, time-limited sessions, caller authorization (Permissions), the access token itself (a Capability — a bearer token good for a bounded time and scope), and the tamper-evident audit record spanning the whole arc.

The central guarantees, which appear only when the patterns are combined, are that no access token can exist without an approved chain behind it (so an auditor can confirm every token traces back to real approvals), that access cannot be used under an expired or revoked session, and that the entire recorded arc — request, approvals, provisioning, each use, and revocation — sits in one audit trail, reached through the request's event ids; expiry is derived from the token's own deadline and writes nothing. Modeling the access as a time-limited token rather than a standing permission is deliberate: privileged access is temporary authorization, not indefinite access.

This is the worked example of approval-gated provisioning behind privileged access management, break-glass access, and time-boxed administrative escalation.

---

## Intent

Privileged access — access to financial controls, patient records, production credentials, source-of-truth databases, cryptographic key material — differs from ordinary access in two ways. First, the grant itself must be authorized by more than one party: a single administrator who can self-approve elevated access to any resource is a control failure under every regulated framework from SOX (the Sarbanes-Oxley Act — US corporate financial-reporting law) to HIPAA (the Health Insurance Portability and Accountability Act — US healthcare-data privacy law) to PCI DSS (the Payment Card Industry Data Security Standard). Second, the access must be time-limited and scoped: indefinite standing access to privileged resources is the most common finding in security audits, because standing access that outlives the business need is indistinguishable from residual access that was never intended.

The six constituents address neither property alone. [Multi-Party Approval](./multi-party-approval.md) enforces the approval gate but does not produce the access artifact. [Capability](../atoms/capability.md) produces the time-limited scoped access token but knows nothing about whether an approval chain cleared. [Session](../atoms/session.md) validates the authenticated channel but does not gate any downstream action. [Credential](../atoms/credential.md) authenticates the principal but does not know what they are requesting access to. [Permissions](../atoms/permissions.md) authorizes who may ask but neither approves nor provisions. [Audit Trail](./audit-trail.md) records the arc and decides none of its approvals. The composition is the layer that wires these concepts into a single, enforceable arc: no Capability is issued without an Approved chain; no access exercise succeeds without an active Session; the full arc is recorded in one tamper-evident Audit Trail.

The load-bearing design decision is that privileged access is modeled as a Capability token rather than a Permissions grant. Permissions grants are persistent until revoked and identity-keyed — they say "this actor may perform this action, indefinitely." Capability tokens are time-bounded, scoped, and bearer-keyed — they say "whoever holds this token may exercise this specific access once (or N times), until this date." Privileged access is temporary authorization, not standing access. The bearer-key property of Capability is a feature here: the access token can be handed off to an automated system or a break-glass process without requiring the executing agent to carry the principal's identity. The Capability's own audit record names the allocator (the composition, acting on behalf of the approved request) and the requestor (via the request record); it intentionally does not name the redeemer — the atom's declared audit asymmetry. What re-binds identity at exercise time is this composition's session gate: `Session.validate`'s declared return hands back the session's `principal_ref`, and the exercise record names it. The asymmetry the composition defends is therefore precise: the *token* never knows its bearer; the *exercise record* names the authenticated principal of the session it was exercised under — which is the identity regulated audit actually needs, supplied by the constituent's declared surface rather than by subverting the token.

This composition is the library's worked example of approval-gated provisioning — the pattern that recurs in privileged access management (PAM — the discipline of controlling and auditing elevated accounts), break-glass access, time-boxed administrative escalation, and regulated change-control access in financial, healthcare, and government systems.

---

## Composes

- **[Multi-Party Approval](./multi-party-approval.md)** — the approval-gate substrate: one chain per request, its quorum and its decisions.
- **[Credential](../atoms/credential.md)** — the authentication check on the requestor and on every approver, read-only.
- **[Session](../atoms/session.md)** — the time-limited authenticated channel every exercise is gated on, read-only.
- **[Permissions](../atoms/permissions.md)** — the authorization gate for request intake, revocation and reads, read-only.
- **[Capability](../atoms/capability.md)** — the provisioned access token: time-limited, scoped, bearer-keyed.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate the whole arc is recorded in.

```
Composes 1: EXACTLY ONE Multi-Party Approval instance MUST serve the composition.
Composes 2: EXACTLY ONE Credential instance MUST serve the composition.
Composes 3: EXACTLY ONE Session instance MUST serve the composition.
Composes 4: EXACTLY ONE Permissions instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: EXACTLY ONE Capability instance MUST serve the composition.
Composes 7: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 8: The composition MUST NOT change a constituent's spec.
Composes 9: The composition MUST read Multi-Party Approval AND Audit Trail as substrates PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 10: The Multi-Party Approval instance MUST record through the composition's Audit Trail instance.
Composes 11: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 12: The Capability instance MUST serve the composition alone.
Composes 13: The composition MUST initiate a request's chain carrying the request id as the subject reference.
Composes 14: The composition MUST initiate a request's chain carrying the request's access scope as the scope.
Composes 15: The composition MUST NOT call a Credential write.
Composes 16: The composition MUST NOT call a Session write.
Composes 17: The composition MUST NOT call a Permissions write.
Composes 18: The composition MUST call Permissions' permitted for requests initiate, requests revoke AND requests read.
Composes 19: The composition MUST call Multi-Party Approval's read chain as the service identity.
Composes 20: A deployment MUST grant EVERY requestor chains initiate AND chains withdraw in the approval substrate's Permissions.
Composes 21: A deployment MUST grant the service identity chains read in the approval substrate's Permissions.
```

Term composition: this pattern's wiring of [Multi-Party Approval](./multi-party-approval.md), [Credential](../atoms/credential.md), [Session](../atoms/session.md), [Permissions](../atoms/permissions.md), [Capability](../atoms/capability.md) and [Audit Trail](./audit-trail.md) — the seven actions, the provisioning cascade, the six derived indexes and the recovery discipline.

Term constituents: [Multi-Party Approval](./multi-party-approval.md), [Credential](../atoms/credential.md), [Session](../atoms/session.md), [Permissions](../atoms/permissions.md), [Capability](../atoms/capability.md), [Audit Trail](./audit-trail.md).

Term approval substrate: the Multi-Party Approval instance serving the composition.

Term audit substrate: the Audit Trail instance serving the composition.

Term trail: the audit substrate's events, in sequence order, as the composition and an auditor read them.

Term chains initiate: the approval substrate's scope admitting initiate_chain.

Term chains withdraw: the approval substrate's scope admitting withdraw_chain.

Term chains read: the approval substrate's scope admitting read_chain.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a request record per request.
Composition state 2: A request record MUST carry the request id, the requestor reference, the resource reference, the access scope, the justification, the requested instant, the expiry instant, the chain id, the request state AND the audit pending list.
Composition state 3: A request record MUST NOT carry a denial reason.
Composition state 4: The composition MUST NOT change a request record's identity fields.
Composition state 5: The composition MUST NOT change a chain id a request record carries.
Composition state 6: The composition MUST change a request state PER the request progression.
Composition state 7: The composition MUST NOT change a request state that IS IN the terminal request states.
Composition state 8: The composition MUST NOT delete a request record AND MUST classify a request record whose shape-bearing event is an aged event as extraction-pending against Erasure Tombstone.
Composition state 9: EVERY audit event the composition records MUST carry the invocation id AND, where the audit event is not a failed exercise event for a token resolving to no request, the request id.
Composition state 10: A failed exercise event for a token resolving to no request MUST carry blank as the request id.
Composition state 11: A shape-bearing event MUST carry the request shape.
Composition state 12: A state-transition event MUST carry the resulting request state.
Composition state 13: IF a denial reason stands THEN a state-transition event MUST carry the denial reason.
Composition state 14: The composition MUST NOT write bearer material into an audit event.
Composition state 16: The rebuild MUST take a request's identity fields from the request's shape-bearing event.
Composition state 17: The rebuild MUST take a request's state from the request's latest state-transition event.
Composition state 18: The rebuild, EVERY invariant, EVERY check, the pre-check of Reconciliation 4 AND the request-to-events map MUST read a recovery record as the event the recovery record names.
Composition state 19: The composition MUST resolve a request's chain from the request record's chain id.
Composition state 20: The composition MUST store the request-to-chain map as an index over the request records' chain ids.
Composition state 21: The composition MUST store the request-to-capability map.
Composition state 22: The composition MUST store the capability-to-request map.
Composition state 23: The composition MUST rebuild the capability maps from Capability's read by parsing each record's composed scope.
Composition state 24: The composition MUST store the session access log as an index over the exercise events AND the failed exercise events, AND MUST write a session access entry in the transaction that records the entry's event (Execution Contract Database 1).
Composition state 25: A session access entry MUST carry the request id, the session principal reference, the exercised instant AND the result.
Composition state 26: The composition MUST store the request-to-events map.
Composition state 27: The composition MUST add an event id to the request-to-events map in the transaction that records the event (Execution Contract Database 1), ONLY AFTER Audit Trail's record action answers the event id AND the event carries a request id other than blank.

Composition state 28: The request-to-events map MUST NOT key an event carrying blank as the request id.
Composition state 29: The composition MUST NOT rebuild an index entry from an aged event.
Composition state 30: The composition MUST leave standing an index entry whose event is an aged event AND MUST classify the index entry as extraction-pending against Erasure Tombstone.
Composition state 31: A pending entry other than an evaluation entry MUST carry the action reference AND the invocation id of the record the pending entry owes, AND, once the act the entry records resolves, the event data of that record.
Composition state 32: The composition MUST close a pending entry ONLY AFTER the pending entry's closing occasion.
Composition state 35: A request carrying a chain id MUST name EXACTLY ONE chain.
Composition state 36: EVERY chain in the approval substrate MUST belong to EXACTLY ONE request.
Composition state 37: A request MUST NOT acquire two capability tokens.
```

Term request record: the composition's record of one access request.

Term request id: the request's identifier — the invocation id of the [Request Access] that opened the request.

Term request state: Pending | Approved | Provisioned | Denied | Withdrawn | Revoked | ProvisioningFailed.

Term request progression: Pending to Approved, Denied or Withdrawn; Approved to Provisioned or ProvisioningFailed; Provisioned to Revoked — Approved being the in-cascade transient.

Term open request state: Pending | Approved.

Term terminal request state: Denied | Withdrawn | Revoked | ProvisioningFailed.

Term refused state: Denied | ProvisioningFailed.

Term identity field: the request id, the requestor reference, the resource reference, the access scope, the justification, the requested instant, the expiry instant and, once written, the chain id.

Term request shape: the requestor reference, the resource reference, the access scope, the justification, the requested instant, the expiry instant, the chain id, the approver set and the quorum rule.

Term shape-bearing event: a request event, or an initiation-failed withdrawal event — the events that carry a request's whole shape.

Term state-transition event: a provisioning event, a denial event, a withdrawal event, a revocation event or a provisioning-failure event.

Term latest state-transition event: the request's state-transition event carrying the state furthest along the request progression, whatever the order in which the request's events were recorded or a recovery record landed.

Term denial reason: the reason a denial event or a provisioning-failure event carries for the refused state.

Term withdrawal reason: the reason the chain evaluation's withdrawal event carries — the terminal event's reason, blank where the terminal event's read answers not-known or state-unavailable or its reason is destroyed (Action wiring 130), or where the chain's event ids name no terminal event (Action wiring 122).

Term requested instant: the now an admitted request stamps when it opens (Capability requirement 25).

Term access scope: the part of the resource a requestor names and the capability authorizes, carried on the request and parsed back out of the composed scope.

Term justification: the requestor's stated reason for the access, carried on the request and read by no rule.

Term terminal event: the chain's event whose action reference IS IN the terminal chain actions AND whose record carries a terminal summary OR IS a purged event — a trailing decision's outcome and a decision's outcome short of the chain's end carry the same action reference and no summary, so neither is the terminal event while its payload stands; past the audit horizon the summary is destroyed with the payload, and a purged event under a terminal chain action is read as the terminal event with its reason destroyed (Action wiring 51, Reconciliation 40).

Term event envelope: the bytes the audit substrate adds around the data the composition supplies.

Term bearer material: a capability token | a session token — material whose holder can exercise what it names.

Term request-to-chain map: the composition's map from a request id to the request's chain id.

Term request-to-capability map: the composition's map from a request id to the request's capability token.

Term capability-to-request map: the composition's map from a capability token to the request id the token's composed scope names.

Term session access log: the per-request record of every [Exercise Access] that reached Capability's redeem.

Term session access entry: one entry of the session access log.

Term transactional index writes: a session access entry write | a request-to-events map write — the index writes that commit with their event (Composition state 24 and 27).

Term request-to-events map: the composition's map from a request id to the event ids recorded for the request, in the trail's sequence order — the declared request-to-audit traversal.

Term audit pending list: a request record's list of pending entries, empty by default.

Term pending entry: an open record owed on a request — an initiation entry, an exercise entry, an evaluation entry, a denial-reason entry, a withdrawal-reason entry, or the owed record of a committed act.

Term closing occasion: the landing of the record a pending entry owes — for an evaluation entry, of the chain evaluation's writes (Action wiring 117) — or, for a denial-reason entry or a withdrawal-reason entry alone, Audit Trail's read record answering not-known for the chain's terminal event or the denial-reason leg finding the terminal event's reason destroyed (Reconciliation 40 and Reconciliation 44).

Term aged event: an event whose `(recording instant + audit horizon)` PRECEDES now — past which the event's payload may be lawfully destroyed.

Term quiescence: a state in which no invocation is in flight and no pending entry is open.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — inside the audit horizon, derived indexes: the request records over the trail (Composition state 16 through 18), the request-to-chain map over the request records' chain ids (Composition state 20), the request-to-capability and capability-to-request maps over the Capability instance's composed scopes (Composition state 23), the session access log over the exercise events and the failed exercise events (Composition state 24) and the request-to-events map over the events' request ids (Composition state 26); past the horizon, truth-bearing, extraction-pending against [Erasure Tombstone](../atoms/erasure-tombstone.md): the request records (Composition state 8, Capability requirement 13), the session access log and the request-to-events map (Composition state 24, 27, 30, Capability requirement 35 and 36); the audit pending list: extraction-pending against [Owed Record](../atoms/owed-record.md) (Composition state 31). The session access log and the request-to-events map depart from the section's second and third obligations in the one respect, named here once: each is written with its event, in the event's transaction (Composition state 24 and 27), where the section leaves a derived index outside its action's atomicity, so that an entry is complete before its event ages and is rebuilt from the events only where it is lost (Check 5.1).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the default ttl.
Capability requirement 2: IF the default ttl IS IN the refused ttls THEN the composition MUST refuse to start.
Capability requirement 3: A deployment MUST set the max redemptions default.
Capability requirement 4: [Request Access] MUST NOT take a redemption count.
Capability requirement 5: A deployment MUST set the credential type.
Capability requirement 6: The composition MUST pass the credential type to EVERY Credential verify the composition calls.
Capability requirement 7: A deployment MUST set the credential check on request.
Capability requirement 8: A deployment MUST set the approver set minimum.
Capability requirement 9: The composition MUST configure the approval substrate with the approver set minimum.
Capability requirement 10: The retention floor MUST NOT EXCEED the audit horizon.
Capability requirement 13: A deployment MUST NOT purge a request record.
Capability requirement 14: A deployment MUST NOT purge a record of the Capability instance.
Capability requirement 15: A deployment MUST declare the composed-scope encoding.
Capability requirement 16: The composition MUST parse a composed scope back to the request id, the resource reference AND the access scope the composed scope serialized.
Capability requirement 17: A deployment MUST supply the service identity.
Capability requirement 18: A deployment MUST register a caller's credential material in the Credential records AND the audit substrate's actor registry alike.
Capability requirement 19: A deployment MUST set the reference caps.
Capability requirement 23: The host MUST inject now at the composition's seam once per invocation.
Capability requirement 24: The composition MUST NOT read the clock inside a transition.
Capability requirement 25: An admitted request MUST stamp the requested instant as now AND compute the expiry instant from that same now.
Capability requirement 26: The provisioning cascade MUST compute the remaining ttl from the stored expiry instant AND the invocation's now.
Capability requirement 27: The composition MUST NOT store a clock-derived flag.
Capability requirement 29: The host MUST inject one invocation id per state-changing invocation.
Capability requirement 30: An admitted request MUST take the invocation id as the request id.
Capability requirement 31: The composition MUST NOT mint an id inside a transition.
Capability requirement 32: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
Capability requirement 33: IF the credential type, the composed-scope encoding, the reference caps, the longest token lifetime, the provisioning proof period OR the service identity EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 34: A deployment MUST set the longest token lifetime AND the provisioning proof period.
Capability requirement 35: A deployment MUST NOT purge a session access entry.
Capability requirement 36: A deployment MUST NOT purge a request-to-events map entry.
```

NOTE: watch the unset setting (Capability requirement 33).

Term default ttl: the time-to-live — the validity duration — a request carries where the requestor supplies none.

Term max redemptions default: the redemption count every allocate passes; 1, a single exercise, where the deployment declares none.

Term credential type: the one Credential type every verify here names — a smart-card deployment names its card type, a password deployment its password type.

Term credential check on request: true | false — whether [Request Access] verifies the requestor's credential; true where the deployment declares none.

Term approver set minimum: the smallest approver set a chain may carry; 2 where the deployment declares none.

Term audit horizon: the retention horizon of the policy the audit substrate is configured with.

Term retention floor: `(longest token lifetime + provisioning proof period)`.

Term longest token lifetime: the longest time-to-live the deployment sets for a token (Capability requirement 34).

Term provisioning proof period: the period over which the deployment must prove approval-gated provisioning from the trail.

Term refused ttls: the ttls that DO NOT EXCEED zero OR EXCEED the longest token lifetime.

Term composed scope: the byte-exact, self-delimiting serialization of the request id, the resource reference and the access scope, in that order, that the composition writes into Capability's opaque scope.

Term service identity: the composition's own actor reference and credential, supplied by the deployment, that attributes every event with no human origin and makes every chain read.

Term reference caps: the length caps on the actor reference, the requestor reference, the resource reference, the access scope and each approver reference, derived from every surface the values must fit.

Term seam: the composition's input and output boundary — the one place the host reads the clock and injects the reading and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term invocation id: the fresh id the host injects at the seam for each state-changing invocation, carried on every event and pending entry the invocation writes.

Term remaining ttl: `(expiry instant - now)`, rounded down to a whole number of seconds, the time-to-live the cascade passes to allocate.

Term request ttl: the ttl the requestor supplies, or the default ttl where the requestor supplies none.

Term expiry instant: `(requested instant + request ttl)`, the deadline an admitted request stamps from its one now.

### Primitive policy

```
Primitive policy 1: IF an actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the resource reference EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 3: IF the access scope EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 4: IF a reference EXCEEDS the reference's cap THEN the action MUST answer invalid-request.
Primitive policy 5: The composition MUST validate a request's approver set AND quorum rule PER the approval substrate's own chain-shape rules.
Primitive policy 6: IF the constructed event data EXCEEDS the payload budget THEN the action MUST answer invalid-request.
Primitive policy 7: IF a supplied ttl IS IN the refused ttls THEN [Request Access] MUST answer invalid-request.
Primitive policy 8: IF the justification EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 9: IF a required reason EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 10: An action refused under Primitive policy 1 through 9 MUST NOT write.
Primitive policy 11: The composition MUST compare an identifier byte-exact.
Primitive policy 12: The composition MUST NOT normalize a string input.
Primitive policy 13: The composition MUST NOT read a credential's content.
Primitive policy 14: The composition MUST NOT write a credential into an audit event.
```

Term payload budget: the audit substrate's payload cap less the event envelope.

### Action wiring

```
request_access(requestor_ref, credential, resource_ref, access_scope, justification, approver_set, quorum_rule, optional ttl)
  answers request_id
  refuses invalid-request | permission-denied | invalid-credential | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | storage-failure | state-unavailable | already-assigned | already-accounted(closing_event_id) | recording-failure(position, optional request_id)

approve_step(actor_ref, credential, request_id, step_id, optional reason)
  answers approved
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | chain-state-changed | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(position)

reject_step(actor_ref, credential, request_id, step_id, reason)
  answers rejected_outcome
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | chain-state-changed | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(position)

withdraw_request(actor_ref, credential, request_id, reason)
  answers withdrawn
  refuses invalid-request | invalid-credential | not-known | not-pending | unauthorized | permission-denied | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(position)

exercise_access(session_token, capability_token)
  answers exercised
  refuses session-invalid(validation failure) | capability-invalid(exercise failure)

revoke_access(actor_ref, credential, request_id, reason)
  answers revoked
  refuses invalid-request | invalid-credential | permission-denied | not-known | not-provisioned | recording-failure(intent)

read_request(actor_ref, query)
  answers request results
  refuses permission-denied | invalid-query
```

Term validation failure: expired | revoked | not-known — Session's reasons for an invalid session.

Term exercise failure: exhausted | expired | revoked | not-known | recording-failure — Capability's redemption failure, or an exercise entry the database refused; a failed exercise event carries every one but recording-failure, which [Exercise Access] answers (Action wiring 84) and records on no event.

Term request results: the requests a query matches, each carrying the request record's fields, the chain's state, the token's effective status and the request's event ids, in declared order.

Term read query: the filters [Read Request] admits, in any combination — request id, requestor reference, resource reference and request state — and malformed where it filters on another key, where a filter carries a blank value, or where the request state filter names no request state (Action wiring 106).

Term chain state: Pending | Approved | Rejected | Withdrawn — Multi-Party Approval's own states of a chain, read through read chain; the words Pending, Approved and Withdrawn name a chain's state here and a request's state in the request state, two states of two records that a read never takes for each other.

Term unavailable: the chain's state a request result carries where read chain refused (Action wiring 109), the one value beside the chain states.

Term initiation refusal: invalid-request | invalid-credential | permission-denied | act-in-flight | section-unavailable | journal-unavailable | storage-failure | state-unavailable | already-assigned | recording-failure carrying intent | recording-failure carrying refusal — the refusals of initiate chain after which no chain stands, each answered before a commit or without one.

Term mapped refusal: the refusal [Request Access] answers for the initiation refusal that closed the request (Action wiring 22 through 25 and Action wiring 123), carried as the initiation-failed withdrawal event's reason.

```
Action wiring 1: A credentialed action MUST call Credential's verify with the actor reference, the credential type AND the credential.
Action wiring 2: A credentialed action MUST NOT resolve the request BEFORE Credential's verify answers verified.
Action wiring 3: IF Credential's verify answers failed-verification THEN the action MUST answer invalid-credential.
Action wiring 5: IF a credentialed action's request id names no request record THEN the action MUST answer not-known.
Action wiring 6: IF the action's load-bearing act answers the act's success THEN the action MUST answer the action's success.
Action wiring 7: IF Audit Trail refuses the record following a committed load-bearing act THEN the action MUST open a pending entry carrying the record.
Action wiring 8: The composition MUST write an index entry ONLY AFTER the record the index entry derives from lands.
Action wiring 9: A failed index write that IS NOT IN the transactional index writes MUST NOT change an action's answer.
Action wiring 10: A validated request MUST call Permissions' permitted with the requestor reference AND requests initiate.
Action wiring 11: IF Permissions answers denied THEN the action MUST answer permission-denied.
Action wiring 12: IF the credential check on request EQUALS true THEN [Request Access] MUST call Credential's verify with the requestor reference, the credential type AND the credential.
Action wiring 13: An admitted request MUST write the request record carrying Pending AND an initiation entry.
Action wiring 15: IF the database refuses the request record THEN [Request Access] MUST answer recording-failure carrying intent.
Action wiring 16: An admitted request MUST call Multi-Party Approval's initiate chain with the requestor reference, the credential, the request id, the access scope, the approver set AND the quorum rule.
Action wiring 17: IF initiate chain answers the chain id OR recording-failure carrying outcome THEN [Request Access] MUST write the chain id onto the request record.
Action wiring 18: IF initiate chain answers the chain id OR recording-failure carrying outcome THEN [Request Access] MUST complete the initiation entry's payload with the chain id.
Action wiring 19: IF initiate chain answers an initiation refusal THEN [Request Access] MUST record an initiation-failed withdrawal event carrying the request shape AND the mapped refusal as the reason.
Action wiring 20: IF initiate chain answers an initiation refusal THEN [Request Access] MUST set the request state to Withdrawn.
Action wiring 21: IF initiate chain answers an initiation refusal THEN [Request Access] MUST close the initiation entry ONLY AFTER the initiation-failed withdrawal event lands.
Action wiring 22: IF initiate chain answers invalid-request THEN [Request Access] MUST answer invalid-request.
Action wiring 23: IF initiate chain answers invalid-credential THEN [Request Access] MUST answer invalid-credential.
Action wiring 24: IF initiate chain answers permission-denied THEN [Request Access] MUST answer permission-denied.
Action wiring 25: IF initiate chain answers recording-failure THEN [Request Access] MUST answer recording-failure carrying the position unchanged.
Action wiring 123: IF initiate chain answers act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable OR already-assigned THEN [Request Access] MUST answer the substrate's refusal.
Action wiring 124: IF initiate chain answers recording-failure carrying outcome THEN [Request Access] MUST answer recording-failure carrying outcome AND the request id.
Action wiring 125: IF initiate chain answers already-accounted THEN [Request Access] MUST leave the initiation entry open, MUST NOT set the request state AND MUST answer already-accounted carrying the closing event id.
Action wiring 126: A requestor whose [Request Access] answer is lost MUST call [Request Access] again ONLY AFTER reading the requestor's requests through [Read Request] filtered on the requestor reference AND the resource reference (Execution Contract Error model 1).
Action wiring 26: The deployment MUST alert on a substrate permission-denied as a wiring fault.
Action wiring 27: An admitted request MUST record the request event ONLY AFTER initiate chain answers the chain id.
Action wiring 28: IF the request event lands THEN [Request Access] MUST close the initiation entry.
Action wiring 29: IF Audit Trail refuses the request event THEN [Request Access] MUST leave the initiation entry open.
Action wiring 31: IF the request's chain id EQUALS blank THEN a decision action MUST answer not-pending.
Action wiring 32: [Approve Step] MUST call Multi-Party Approval's approve step with the actor reference, the credential, the chain id, the step id AND the reason.
Action wiring 33: [Reject Step] MUST call Multi-Party Approval's reject step with the actor reference, the credential, the chain id, the step id AND the reason.
Action wiring 34: IF the approval substrate answers invalid-request, not-known, not-pending, unauthorized OR chain-state-changed to a decision THEN the decision action MUST answer the substrate's refusal.
Action wiring 35: IF the approval substrate answers invalid-credential to a decision THEN the decision action MUST answer invalid-credential.
Action wiring 36: IF the approval substrate answers recording-failure to a decision THEN the decision action MUST answer recording-failure carrying the position unchanged.
Action wiring 37: IF the approval substrate answers recording-failure carrying outcome to a decision THEN the decision action MUST open an evaluation entry.
Action wiring 127: IF the approval substrate answers act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable, already-accounted OR recording-failure carrying refusal to a decision THEN the decision action MUST answer the substrate's refusal.
Action wiring 38: IF the approval substrate answers not-pending OR chain-state-changed to a decision THEN the decision action MUST run the chain evaluation.
Action wiring 39: A decision action MUST record a decision event carrying the request id, the chain id, the step id, the decision AND the reason ONLY AFTER the approval substrate answers the decision.
Action wiring 40: A decision action MUST run the chain evaluation ONLY AFTER the approval substrate answers the decision.
Action wiring 41: A decision action MUST answer the decision ONLY AFTER the approval substrate answers the decision.
Action wiring 43: The chain evaluation MUST read the chain through Multi-Party Approval's read chain with a query on the chain id.
Action wiring 44: IF read chain answers permission-denied, invalid-query, state-unavailable OR an empty result THEN the chain evaluation MUST open an evaluation entry ONLY IF the chain evaluation is not the retry of an open evaluation entry.
Action wiring 45: The deployment MUST alert on a read chain refusal inside the chain evaluation as a wiring fault.
Action wiring 46: A read chain refusal MUST NOT change the decision action's answer.
Action wiring 47: IF the chain's state EQUALS Approved AND the provisioning conjunction holds THEN the chain evaluation MUST set the request state to Approved.
Action wiring 48: IF the chain's state EQUALS Approved AND the provisioning conjunction holds THEN the chain evaluation MUST fire the provisioning cascade.
Action wiring 49: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST read the chain's terminal event.
Action wiring 50: The chain evaluation MUST find the chain's terminal event by reading the chain's event ids in the trail's sequence order from the first to the first terminal event, the terminal event being the first by sequence number, as Multi-Party Approval Composition state 31 binds.
Action wiring 51: IF Audit Trail's read record answers not-known OR state-unavailable OR the terminal event's reason is destroyed OR the chain's event ids name no terminal event THEN the chain evaluation MUST take blank as the denial reason.
Action wiring 52: IF the denial reason EQUALS blank THEN the chain evaluation MUST open a denial-reason entry ONLY IF the request carries no open denial-reason entry.
Action wiring 53: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST record a denial event carrying Denied AND the denial reason under the service identity.
Action wiring 54: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST set the request state to Denied.
Action wiring 55: IF the chain's state EQUALS Withdrawn AND the request state EQUALS Pending AND the chain's event ids name a terminal event THEN the chain evaluation MUST record a withdrawal event carrying Withdrawn AND the withdrawal reason under the service identity.
Action wiring 56: IF the chain's state EQUALS Withdrawn AND the request state EQUALS Pending THEN the chain evaluation MUST set the request state to Withdrawn.
Action wiring 57: IF the chain's state EQUALS Pending THEN the chain evaluation MUST NOT write.
Action wiring 58: IF the request state IS IN the terminal request states THEN the chain evaluation MUST NOT write.
Action wiring 59: IF the request's requestor reference DOES NOT EQUAL the actor reference THEN [Withdraw Request] MUST answer unauthorized.
Action wiring 60: IF the request state DOES NOT EQUAL Pending THEN [Withdraw Request] MUST answer not-pending.
Action wiring 61: IF the request's chain id EQUALS blank THEN [Withdraw Request] MUST answer not-pending.
Action wiring 62: [Withdraw Request] MUST NOT call Permissions' permitted.
Action wiring 63: An admitted withdrawal MUST call Multi-Party Approval's withdraw chain with the actor reference, the credential, the chain id AND the reason.
Action wiring 64: IF withdraw chain answers not-pending THEN [Withdraw Request] MUST run the chain evaluation.
Action wiring 65: IF withdraw chain answers not-pending THEN [Withdraw Request] MUST answer not-pending.
Action wiring 66: IF withdraw chain answers permission-denied THEN [Withdraw Request] MUST answer permission-denied.
Action wiring 67: IF withdraw chain answers unauthorized OR not-known THEN [Withdraw Request] MUST answer the substrate's refusal.
Action wiring 68: IF withdraw chain answers unauthorized OR not-known THEN the deployment MUST alert on the answer as a conformance fault.
Action wiring 69: IF withdraw chain answers invalid-credential THEN [Withdraw Request] MUST answer invalid-credential.
Action wiring 70: IF withdraw chain answers invalid-request THEN [Withdraw Request] MUST answer invalid-request.
Action wiring 71: IF withdraw chain answers recording-failure THEN [Withdraw Request] MUST answer recording-failure carrying the position unchanged.
Action wiring 128: IF withdraw chain answers act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable OR already-accounted THEN [Withdraw Request] MUST answer the substrate's refusal.
Action wiring 129: IF withdraw chain answers act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable, already-accounted OR recording-failure carrying refusal THEN [Withdraw Request] MUST NOT write.
Action wiring 72: An admitted withdrawal MUST record a withdrawal event carrying Withdrawn AND the reason ONLY AFTER withdraw chain answers withdrawn.
Action wiring 73: An admitted withdrawal MUST set the request state to Withdrawn ONLY AFTER withdraw chain answers withdrawn.
Action wiring 74: An admitted withdrawal MUST answer withdrawn ONLY AFTER withdraw chain answers withdrawn.
Action wiring 75: [Exercise Access] MUST NOT call a Capability action BEFORE Session's validate answers valid.
Action wiring 76: IF Session's validate answers invalid THEN [Exercise Access] MUST answer session-invalid carrying the validation failure.
Action wiring 77: IF Session's validate answers invalid THEN [Exercise Access] MUST NOT write.
Action wiring 78: A validated exercise MUST resolve the token's request through Capability's read filtered on the capability token.
Action wiring 79: IF Capability's read finds no record for the token OR the record's composed scope parses to no request THEN [Exercise Access] MUST NOT call Capability's redeem.
Action wiring 80: IF Capability's read finds no record for the token OR the record's composed scope parses to no request THEN [Exercise Access] MUST answer capability-invalid carrying not-known.
Action wiring 81: IF Capability's read finds no record for the token OR the record's composed scope parses to no request THEN [Exercise Access] MUST record a failed exercise event carrying blank as the request id.
Action wiring 82: A resolved exercise MUST open an exercise entry carrying the session principal reference AND the exercised instant.
Action wiring 84: IF the database refuses the exercise entry THEN [Exercise Access] MUST answer capability-invalid carrying recording-failure.
Action wiring 85: A resolved exercise MUST call Capability's redeem.
Action wiring 86: IF Capability's redeem answers redeemed THEN [Exercise Access] MUST mark the exercise entry redeemed.
Action wiring 87: IF Capability's redeem answers redeemed THEN [Exercise Access] MUST answer exercised.
Action wiring 88: IF Capability's redeem answers invalid THEN [Exercise Access] MUST answer capability-invalid carrying the redemption failure.
Action wiring 89: A resolved exercise MUST record an exercise event carrying the request id, the session principal reference, the exercised instant AND redeemed under the service identity ONLY AFTER Capability's redeem answers redeemed.
Action wiring 90: A resolved exercise MUST record a failed exercise event carrying the request id, the session principal reference, the exercised instant AND the redemption failure under the service identity ONLY AFTER Capability's redeem answers invalid.
Action wiring 91: IF the exercise's record lands THEN [Exercise Access] MUST close the exercise entry.
Action wiring 92: IF Audit Trail refuses the exercise's record THEN [Exercise Access] MUST leave the exercise entry open.
Action wiring 93: The deployment MUST alert on a redemption answering an allocator reference other than the service identity as a conformance fault.
Action wiring 94: The composition MUST NOT gate an exercise on the request state.
Action wiring 95: A verified revocation MUST call Permissions' permitted with the actor reference AND requests revoke.
Action wiring 96: IF the request state DOES NOT EQUAL Provisioned THEN [Revoke Access] MUST answer not-provisioned.
Action wiring 97: An admitted revocation MUST call Capability's revoke with the request's capability token, the actor reference AND the reason.
Action wiring 98: IF Capability's revoke answers not-known OR invalid-request THEN [Revoke Access] MUST answer recording-failure.
Action wiring 99: IF Capability's revoke answers not-known OR invalid-request THEN the deployment MUST alert on the answer as a conformance fault.
Action wiring 100: IF Capability's revoke answers storage-failure THEN [Revoke Access] MUST answer recording-failure (Execution Contract Constituent failure 1).
Action wiring 101: IF Capability's revoke answers revoked OR already-terminal THEN [Revoke Access] MUST record a revocation event carrying Revoked AND the reason.
Action wiring 102: IF Capability's revoke answers revoked OR already-terminal THEN [Revoke Access] MUST set the request state to Revoked.
Action wiring 103: IF Capability's revoke answers revoked OR already-terminal THEN [Revoke Access] MUST answer revoked.
Action wiring 104: The composition MUST call Permissions' permitted with the actor reference AND requests read for EVERY [Read Request].
Action wiring 105: [Read Request] MUST NOT write.
Action wiring 106: IF a query carries an undeclared filter key, a blank filter value OR an undeclared request state THEN [Read Request] MUST answer invalid-query.
Action wiring 107: A request result MUST carry the request record's fields, the chain's state, the capability's effective status AND the request's event ids.
Action wiring 108: [Read Request] MUST NOT call read chain for a request whose chain id EQUALS blank.
Action wiring 109: IF read chain refuses for a request result THEN the result MUST carry unavailable as the chain's state.
Action wiring 110: IF Capability's read finds no record for a request THEN the result MUST carry no effective status.
Action wiring 111: A request result MUST NOT carry bearer material.
Action wiring 112: A permitted read MUST order the results by requested instant, ties by request id, ascending.
Action wiring 113: IF an owed record's actor credential is in hand THEN the invocation MUST retry the owed record under the actor's credential.
Action wiring 114: IF Permissions' permitted answers denied THEN [Revoke Access] MUST answer permission-denied.
Action wiring 115: IF Permissions' permitted answers denied THEN [Read Request] MUST answer permission-denied.
Action wiring 116: IF the approval substrate answers invalid-credential, act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable, already-accounted, recording-failure carrying intent OR recording-failure carrying refusal to a decision THEN the decision action MUST NOT write.
Action wiring 117: IF read chain answers the chain THEN the chain evaluation MUST close the request's open evaluation entries ONLY AFTER the chain evaluation's writes land.
Action wiring 118: IF Capability's redeem answers invalid THEN [Exercise Access] MUST complete the exercise entry with the redemption failure.
Action wiring 119: IF Audit Trail refuses the failed exercise event carrying blank as the request id THEN [Exercise Access] MUST answer capability-invalid carrying not-known (Execution Contract Constituent failure 1).
Action wiring 120: IF Audit Trail refuses the failed exercise event carrying blank as the request id THEN [Exercise Access] MUST NOT open a pending entry.
Action wiring 121: A resolved exercise MUST take the exercised instant from the invocation's now.
Action wiring 122: IF the chain's state EQUALS Withdrawn AND the request state EQUALS Pending AND the chain's event ids name no terminal event THEN the chain evaluation MUST record a withdrawal event carrying Withdrawn AND blank as the withdrawal reason under the service identity.
Action wiring 130: IF Audit Trail's read record answers not-known OR state-unavailable OR the terminal event's reason is destroyed THEN the chain evaluation MUST take blank as the withdrawal reason.
Action wiring 131: IF the withdrawal reason EQUALS blank THEN the chain evaluation MUST open a withdrawal-reason entry ONLY IF the request carries no open withdrawal-reason entry.
```

Term credentialed action: [Approve Step] | [Reject Step] | [Withdraw Request] | [Revoke Access].

Term decision action: [Approve Step] | [Reject Step].

Term load-bearing act: the constituent write an action exists for — initiate_chain at [Request Access], the decision at a decision action, withdraw_chain at [Withdraw Request], redeem at [Exercise Access], Capability's revoke at [Revoke Access].

Term validated request: a [Request Access] call whose inputs cleared Primitive policy.

Term admitted withdrawal: a [Withdraw Request] whose caller verified, matched the requestor, and met a Pending request carrying a chain id.

Term validated exercise: an [Exercise Access] whose session validate answered valid.

Term verified revocation: a [Revoke Access] whose caller's credential verified.

Term admitted revocation: a verified revocation whose caller Permissions permitted, against a Provisioned request.

Term permitted read: a [Read Request] whose caller Permissions permitted and whose query is well-formed.

Term admitted request: a [Request Access] call whose inputs, permission check and credential check passed.

Term initiation entry: the pending entry [Request Access] writes with the request record, carrying the request event's payload less the chain id until initiate_chain answers, and owing the request event where the request record carries the chain id (Action wiring 17), and otherwise the initiation-failed withdrawal event (Action wiring 19).

Term evaluation entry: the pending entry recording a chain evaluation owed after a committed decision, carrying the request id AND the invocation id; its retry is the chain evaluation.

Term denial-reason entry: the pending entry recording a denial event that landed with a blank denial reason.

Term withdrawal-reason entry: the pending entry recording a withdrawal event that landed with a blank withdrawal reason.

Term exercise entry: the pending entry a resolved exercise writes in the exercise's one transaction (Execution Contract Database 1), carrying the exercise's payload; marked redeemed where redeem answers redeemed (Action wiring 86) and completed with the redemption failure where redeem answers invalid (Action wiring 118), so an open exercise entry carries one or the other.

Term resolved exercise: an [Exercise Access] whose session validated and whose token Capability's read found with a composed scope that parses to a request.

Term chain evaluation: the read of a request's chain and the transition, record and cascade the chain's state calls for.

Term provisioning conjunction: the request state IS IN the open request states, no token in the Capability instance parses to the request, and no pending entry owing a provisioning-failure event is open.

Term terminal chain action: chain.approval.approved | chain.rejection.rejected | chain.step_withdrawal.withdrawn | chain.withdrawal.withdrawn — the action references a terminating act's outcome carries (Multi-Party Approval Composition state 6); the record among them carrying the terminal summary is the terminal event, its reason the terminal summary's rule reason or withdrawal reason.

Term requests initiate: the scope admitting [Request Access] — a [Requests Initiate].

Term requests revoke: the scope admitting [Revoke Access] — a [Requests Revoke].

Term requests read: the scope admitting [Read Request] — a [Requests Read].

#### Closure table

Every input an action takes and every answer a call of the seven actions can meet — Credential's verify, Permissions' permitted, Multi-Party Approval's initiate chain, approve step, reject step, withdraw chain and read chain, Audit Trail's record action and read record, Session's validate, and Capability's allocate, redeem, revoke and read — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1, Execution Contract Constituent failure 3); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here, and the caller's next call is the requestor's own (Action wiring 126) or the reconciliation's (Reconciliation 1 and 2). The reconciliation's legs make the calls below again and land each answer as its action does, leaving an entry whose call fails open for the next run (Reconciliation 2). [Request Access] writes its request record and initiation entry before it calls initiate chain (Action wiring 13 and 16), so it departs from the default of Execution Contract Constituent failure 1 and 3, under which a constituent's storage-failure or state-unavailable commits nothing: it lands each as an initiation refusal (Action wiring 19 through 21 and 123).

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action | a blank actor reference | invalid-request, nothing written | Primitive policy 1, 10 |
| [Request Access] | a blank resource reference, access scope or justification | invalid-request, nothing written | Primitive policy 2, 3, 8, 10 |
| every action | a blank required reason | invalid-request, nothing written | Primitive policy 9, 10 |
| every action | a reference over its cap | invalid-request, nothing written | Primitive policy 4, 10 |
| [Request Access] | an approver set or quorum rule the approval substrate's chain-shape rules refuse | invalid-request, nothing written | Primitive policy 5, 10 |
| every action | the data of an event the action will emit over the payload budget | invalid-request, nothing written | Primitive policy 6, 10 |
| [Request Access] | a supplied ttl in the refused ttls | invalid-request, nothing written | Primitive policy 7, 10 |
| every action | an identifier or a string input | compared byte-exact, never normalized, no credential read or written into an event | Primitive policy 11 through 14 |
| [Read Request] | an undeclared filter key, a blank filter value or an undeclared request state | invalid-query | Action wiring 106 |
| a credentialed action | a request id naming no request record | not-known | Action wiring 5 |
| [Approve Step], [Reject Step], [Withdraw Request] | a request whose chain id is blank | not-pending | Action wiring 31, 61 |
| [Withdraw Request] | a caller who is not the request's requestor, or a request not Pending | unauthorized, not-pending | Action wiring 59, 60 |
| [Revoke Access] | a request not Provisioned | not-provisioned | Action wiring 96 |

**Credential's verify**, at [Request Access] where the credential check on request is true, and at every credentialed action.

| Answer | Lands | Owner |
|---|---|---|
| verified | the request resolved and the action goes on | Action wiring 1, 2, 12 |
| failed-verification | invalid-credential, nothing written | Action wiring 3, Primitive policy 13 |
| state-unavailable | state-unavailable, nothing written | Execution Contract Constituent failure 3 |

**Permissions' permitted**, at [Request Access], [Revoke Access] and [Read Request]; no decision action and no [Withdraw Request] calls it, the substrate's own scopes deciding there (Wiring decision 5, Action wiring 62).

| Answer | Lands | Owner |
|---|---|---|
| permitted | the action goes on | Action wiring 10, 95, 104 |
| denied | permission-denied, nothing written | Action wiring 11, 114, 115 |
| state-unavailable | state-unavailable, nothing written | Execution Contract Constituent failure 3 |

**Multi-Party Approval's initiate chain**, at [Request Access], after the request record and the initiation entry are written.

| Answer | Lands | Owner |
|---|---|---|
| the chain id | the chain id on the request record and the initiation entry, then the request event | Action wiring 16, 17, 18, 27 |
| recording-failure carrying outcome | the chain id on the record and the entry as above; recording-failure carrying outcome and the request id answered | Action wiring 17, 18, 25, 124 |
| invalid-request, invalid-credential, permission-denied | the request Withdrawn by an initiation-failed withdrawal event naming the refusal, the same answered | Action wiring 19 through 24 |
| recording-failure carrying intent | the request Withdrawn by an initiation-failed withdrawal event, recording-failure carrying intent answered | Action wiring 19 through 21, 25 |
| recording-failure carrying refusal | the request Withdrawn by an initiation-failed withdrawal event, recording-failure carrying refusal answered | Action wiring 19 through 21, 25 |
| act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable, already-assigned | the request Withdrawn by an initiation-failed withdrawal event naming the refusal, the same answered | Action wiring 19 through 21, 123 |
| already-accounted | the request left Pending with no chain id, the initiation entry left open, already-accounted answered; the initiation leg finds the chain or closes the request | Action wiring 125, Reconciliation 30 through 37 |
| permission-denied of a substrate scope | answered as above, and the deployment alerts | Action wiring 24, 26 |

**Multi-Party Approval's approve step and reject step**, at a decision action.

| Answer | Lands | Owner |
|---|---|---|
| approved, rejected_outcome | the decision event, then the chain evaluation, then the answer | Action wiring 39, 40, 41 |
| invalid-request, not-known, unauthorized | the substrate's refusal answered | Action wiring 34 |
| not-pending, chain-state-changed | the chain evaluation, then the substrate's refusal answered | Action wiring 34, 38 |
| invalid-credential | invalid-credential, nothing written | Action wiring 35, 116 |
| recording-failure carrying outcome | an evaluation entry opened, recording-failure carrying outcome answered | Action wiring 36, 37 |
| recording-failure carrying intent | recording-failure carrying intent, nothing written | Action wiring 36, 116 |
| recording-failure carrying refusal, act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable | the substrate's refusal answered, nothing written | Action wiring 127, 116 |
| already-accounted | already-accounted answered, nothing written; the step decision the substrate holds is landed by the terminal-chain leg | Action wiring 127, 116, Reconciliation 23 |

**Multi-Party Approval's withdraw chain**, at [Withdraw Request].

| Answer | Lands | Owner |
|---|---|---|
| withdrawn | the withdrawal event, the request Withdrawn, withdrawn answered | Action wiring 72, 73, 74 |
| not-pending | the chain evaluation, then not-pending answered | Action wiring 64, 65 |
| permission-denied | permission-denied | Action wiring 66 |
| unauthorized, not-known | the substrate's refusal answered, and the deployment alerts | Action wiring 67, 68 |
| invalid-credential, invalid-request | the same answered | Action wiring 69, 70 |
| recording-failure | recording-failure carrying the position unchanged | Action wiring 71 |
| act-in-flight, section-unavailable, journal-unavailable, storage-failure, state-unavailable, already-accounted | the substrate's refusal answered, nothing written; an already-accounted withdrawal is landed by the terminal-chain leg | Action wiring 128, 129, Reconciliation 22 |

**Multi-Party Approval's read chain**, at the chain evaluation and at [Read Request].

| Answer | Lands | Owner |
|---|---|---|
| the chain | the chain's state taken, the evaluation's transition, record and cascade | Action wiring 43, 47 through 58, 117 |
| permission-denied, invalid-query, state-unavailable, an empty result | at the chain evaluation, an evaluation entry opened where the evaluation is not a retry, the decision action's answer unchanged, the deployment alerts | Action wiring 44, 45, 46 |
| permission-denied, invalid-query | at [Read Request], unavailable as the chain's state; no call for a blank chain id | Action wiring 108, 109 |
| state-unavailable | at [Read Request], state-unavailable | Execution Contract Constituent failure 3 |

**Audit Trail's read record**, at the chain evaluation's terminal event and at the reconciliation's pre-check.

| Answer | Lands | Owner |
|---|---|---|
| the record with its reason | the reason taken | Action wiring 51, 55, 130 |
| the record, its reason destroyed | blank taken as the denial reason or the withdrawal reason, an entry opened | Action wiring 51, 52, 130, 131 |
| not-known | the same; at the denial-reason leg the entry closed | Action wiring 51, 130, Reconciliation 40, 44 |
| the pre-check's read of the trail for the record's action reference and invocation id | the event found: the entry closed and nothing emitted; none found: the record emitted | Reconciliation 4, 5, 6 |
| state-unavailable | blank taken as the reason and an entry opened at the chain evaluation; the entry left open at the denial-reason leg, for the next run | Action wiring 51, 130, 131, Reconciliation 2 |

**Audit Trail's record action**, at every event the composition records.

| Answer | Lands | Owner |
|---|---|---|
| the event id | the index entries written after it, in its transaction, and the pending entry closed | Action wiring 8, 28, 91, Composition state 24, 27 |
| invalid-credential, invalid-request, recording-failure | a pending entry carrying the record opened or left open, the action's answer unchanged | Action wiring 7, 29, 92 |
| the same for a failed exercise event carrying a blank request id | capability-invalid carrying not-known, no pending entry | Action wiring 119, 120 |
| an index write that fails outside the transactional index writes | the answer unchanged | Action wiring 9 |

**Session's validate**, at [Exercise Access].

| Answer | Lands | Owner |
|---|---|---|
| valid | the token resolved through Capability's read | Action wiring 75, 78, Invariant 3.1 |
| invalid (expired, revoked or not-known) | session-invalid naming the reason, nothing written | Action wiring 76, 77, Non-goal 14 |
| state-unavailable | state-unavailable, nothing written | Execution Contract Constituent failure 3 |

**Capability's read**, at [Exercise Access] and at [Read Request].

| Answer | Lands | Owner |
|---|---|---|
| a record whose composed scope parses to a request | the exercise resolved, or the effective status carried | Action wiring 78, 82, 107 |
| no record, or a composed scope that parses to no request | capability-invalid carrying not-known and a failed exercise event with a blank request id, redeem never called; at [Read Request] no effective status | Action wiring 79, 80, 81, 110 |
| state-unavailable | state-unavailable | Execution Contract Constituent failure 3 |

**Capability's redeem**, at [Exercise Access], after the exercise entry is written.

| Answer | Lands | Owner |
|---|---|---|
| redeemed | the entry marked redeemed, the exercise event recorded, exercised answered | Action wiring 85, 86, 87, 89, 91 |
| invalid (exhausted, expired, revoked or not-known) | the entry completed with the redemption failure, the failed exercise event recorded, capability-invalid answered | Action wiring 88, 90, 118, 91 |
| storage-failure | storage-failure, nothing committed | Execution Contract Constituent failure 1 |
| the database refusing the exercise entry | capability-invalid carrying recording-failure | Action wiring 84 |

**Capability's allocate**, at the provisioning cascade.

| Answer | Lands | Owner |
|---|---|---|
| the capability token | the provisioning event, the request Provisioned, the token delivered, the two maps written | Provisioning cascade 8 through 14 |
| invalid-request | a provisioning-failure event, the request ProvisioningFailed, the reason ttl-elapsed or the relayed refusal | Provisioning cascade 3 through 7 |
| storage-failure | nothing written | Provisioning cascade 15 |

**Capability's revoke**, at [Revoke Access].

| Answer | Lands | Owner |
|---|---|---|
| revoked, already-terminal | the revocation event, the request Revoked, revoked answered | Action wiring 101, 102, 103 |
| not-known, invalid-request | recording-failure, and the deployment alerts | Action wiring 98, 99 |
| storage-failure | recording-failure | Action wiring 100 |

**The database**, for every write the action itself makes.

| Answer | Lands | Owner |
|---|---|---|
| the request record or its initiation entry refused | recording-failure carrying intent, nothing written | Action wiring 15 |
| a read that fails | state-unavailable, ahead of every refusal the read would have decided | Execution Contract Read 1 |
| any other write refused | storage-failure, nothing written | Execution Contract Read 4 |

### Wiring decision

```
Wiring decision 1: The composition MUST provision privileged access as a Capability token.
Wiring decision 2: The composition MUST NOT provision privileged access as a Permissions grant.
Wiring decision 3: The composition MUST NOT call Capability's allocate outside the provisioning cascade.
Wiring decision 4: The composition MUST NOT expose a provisioning action.
Wiring decision 5: The composition MUST NOT call Permissions' permitted on a deciding actor.
Wiring decision 6: The composition MUST NOT check a bearer's identity at redemption.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* Privileged access is temporary authorization: what the regulators' findings condemn is standing access that outlives its business need. An artifact that expires structurally — a token with an immutable deadline, refused by its own atom after lapse with nothing written — makes the time bound a property of the record rather than a clean-up job someone must remember.

*Likely objection.* A grant flipped on approval is simpler — identity-keyed, revocable, queryable, and already composed here for the request gates. Why a bearer token and a second gate at exercise time?

*Mechanism.* A grant stands until someone revokes it — exactly the failure mode; its revocation is an act someone must perform, where the token's expiry is a derivation nobody can forget (Wiring decision 1 and 2). **The bearer property is load-bearing, not incidental** (Wiring decision 6): break-glass and automated executors exercise access without carrying the requestor's identity, and the identity regulated audit needs at exercise time is re-bound by this composition's session gate — Session's validate first, its principal in the exercise record — not by the token. The token never knows its bearer; the exercise record names the session's authenticated principal at the moment of presentation. And the cascade is the only allocation path (Wiring decision 3 and 4): allocate is called at exactly one step, fired only by a chain the substrate reports Approved, with the binding written into the token's own immutable scope; an implementation offering a provisioning path outside the cascade violates Invariant 1. **Approvers are authorized by the approver set, not by a grant** (Wiring decision 5): the substrate refuses any decision from an actor outside the step's approver set, and a Permissions check here would enforce one rule through two mechanisms with two failure modes.

*Result.* Every provisioned access traces, provably, to a documented, quorum-satisfied approval; every exercise is session-gated and principal-attributed; a token's expiry needs no janitor; and a leaked trail grants nothing, because no audit event carries the bearer material.

</details>

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST retry EVERY open pending entry on EVERY run.
Reconciliation 4: The reconciliation MUST NOT emit a record BEFORE reading the trail for an event carrying the record's action reference AND invocation id.
Reconciliation 5: IF the pre-check finds the event THEN the reconciliation MUST close the entry.
Reconciliation 6: IF the pre-check finds the event THEN the reconciliation MUST NOT emit the record.
Reconciliation 10: The reconciliation MUST NOT write for an aged event.
Reconciliation 11: The reconciliation MUST attest EVERY write under the service identity.
Reconciliation 12: A leg MUST NOT commit constituent state BEFORE the leg's recovery intent lands.
Reconciliation 13: A leg MUST NOT record a state-transition event BEFORE the leg's recovery intent lands.
Reconciliation 14: A recovery intent MUST carry the invocation id, the request id, the leg AND the plan.
Reconciliation 15: A recovery record MUST carry the owed record's action reference, the owed record's data AND the owed record's invocation id.
Reconciliation 16: The reconciliation MUST NOT take a recovery record's data from a composition index.
Reconciliation 21: The approval leg MUST run the chain evaluation for EVERY request in an open request state whose chain's state EQUALS Approved.
Reconciliation 22: IF the request state IS IN the open request states AND the chain's state IS IN the refusing chain states THEN the terminal-chain leg MUST run the chain evaluation.
Reconciliation 23: The terminal-chain leg MUST land a recovery record for EVERY step decision in the events of EVERY chain, whatever the chain's state, that no decision event names.
Reconciliation 24: The redemption leg MUST land a recovery record for the exercise event of EVERY exercise entry marked redeemed.
Reconciliation 29: The redemption leg MUST land a recovery record for the failed exercise event of EVERY open exercise entry carrying a redemption failure.
Reconciliation 30: IF the request record carries no chain id THEN the initiation leg MUST read the approval substrate for a chain whose subject reference EQUALS the request id.
Reconciliation 32: IF the request carries an open initiation entry AND the request record carries the chain id THEN the initiation leg MUST land a recovery record for the request event.
Reconciliation 33: IF the initiation leg finds no chain THEN the initiation leg MUST record an initiation-failed withdrawal event carrying the request shape AND initiation-failed as the reason.
Reconciliation 35: IF the initiation leg finds the chain AND the request record carries no chain id AND the request state EQUALS Withdrawn THEN the initiation leg MUST land a recovery record for the initiation-failed withdrawal event carrying initiation-failed as the reason.
Reconciliation 36: IF the initiation leg finds the chain AND the request record carries no chain id AND the request state EQUALS Withdrawn THEN the initiation leg MUST report the live chain as a finding.
Reconciliation 37: IF the initiation leg finds the chain AND the request record carries no chain id AND the request state EQUALS Withdrawn THEN the initiation leg MUST NOT land a request event.
Reconciliation 38: The denial-reason leg MUST read the chain's terminal event for EVERY open denial-reason entry.
Reconciliation 39: IF the read answers the terminal event's reason THEN the denial-reason leg MUST land a recovery record for the denial event carrying the reason.
Reconciliation 40: IF Audit Trail's read record answers not-known OR the terminal event's reason is destroyed THEN the denial-reason leg MUST close the denial-reason entry.
Reconciliation 41: The denial-reason leg MUST NOT record a second denial event.
Reconciliation 42: The denial-reason leg MUST read the chain's terminal event for EVERY open withdrawal-reason entry.
Reconciliation 43: IF the read answers the terminal event's reason THEN the denial-reason leg MUST land a recovery record for the withdrawal event carrying the reason.
Reconciliation 44: IF Audit Trail's read record answers not-known OR the terminal event's reason is destroyed THEN the denial-reason leg MUST close the withdrawal-reason entry.
Reconciliation 45: The denial-reason leg MUST NOT record a second withdrawal event.
```

Term reconciliation: the leg this composition runs outside every invocation whose output — a landed record, a finished provisioning, a closed request — a requestor or an auditor awaits: the approval leg, the terminal-chain leg, the redemption leg, the initiation leg and the denial-reason leg, which serves the withdrawal-reason entries as it does the denial-reason entries (Reconciliation 42 through 45), at every start and on every retry; the terminal-chain leg runs the chain evaluation for a Rejected or Withdrawn chain (Reconciliation 22) and lands the decision events owed on a chain in any state (Reconciliation 23).

Term recovery intent: the access_recovery_intended event — the reconciliation's record that the act following it was occasioned by the reconciliation and not by a direct call.

Term recovery record: the access_audit_recovery event — the composition's record standing in for an owed record whose actor is absent.

Term refusing chain state: Rejected | Withdrawn.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define requests initiate, requests revoke AND requests read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT define a withdraw scope.
```

### Provisioning cascade

```
Provisioning cascade 2: The provisioning cascade MUST call Capability's allocate with the service identity, the composed scope, the max redemptions default AND the remaining ttl.
Provisioning cascade 3: IF Capability's allocate answers invalid-request THEN the provisioning cascade MUST open a pending entry carrying the provisioning-failure event.
Provisioning cascade 4: IF Capability's allocate answers invalid-request THEN the provisioning cascade MUST record a provisioning-failure event carrying ProvisioningFailed AND the denial reason under the service identity.
Provisioning cascade 5: IF Capability's allocate answers invalid-request THEN the provisioning cascade MUST set the request state to ProvisioningFailed.
Provisioning cascade 6: IF Capability's allocate answers invalid-request AND the remaining ttl DOES NOT EXCEED zero THEN the denial reason MUST read ttl-elapsed.
Provisioning cascade 7: IF Capability's allocate answers invalid-request for another cause THEN the denial reason MUST carry the relayed refusal.
Provisioning cascade 8: The provisioning cascade MUST record a provisioning event carrying the request id, the requestor reference, the resource reference, the access scope, the max redemptions, the expiry instant AND Provisioned ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 9: A provisioning event MUST NOT carry the capability token.
Provisioning cascade 10: The provisioning cascade MUST set the request state to Provisioned ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 11: The provisioning cascade MUST deliver the capability token to the requestor through the delivery channel ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 12: The composition MUST NOT carry the capability token on a surface other than the delivery channel, the request-to-capability map AND the capability-to-request map.
Provisioning cascade 13: IF Audit Trail refuses the provisioning event THEN the provisioning cascade MUST open a pending entry carrying the provisioning event.
Provisioning cascade 14: The provisioning cascade MUST write the request-to-capability entry AND the capability-to-request entry ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 15: IF Capability's allocate answers storage-failure THEN the provisioning cascade MUST NOT write (Execution Contract Constituent failure 1).
```

Term provisioning cascade: the internal leg the chain evaluation fires on an Approved chain — allocate, record, deliver; no caller invokes it.

Term delivery channel: the deployment's channel carrying a provisioned token to the requestor — the only surface the raw token crosses beside the two capability maps.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Approval gates provisioning (within the audit horizon).**
  ```
  Invariant 1.1: EVERY token in the Capability instance MUST parse to a request whose chain's state EQUALS Approved.
  Invariant 1.2: The composition MUST fire the provisioning cascade ONLY IF the approval substrate reports the chain Approved.
  ```
- **Invariant 2 — Request and capability, one to at most one.**
  ```
  Invariant 2.1: A request MUST NOT acquire two capability tokens across the lifetime of the system.
  Invariant 2.2: The composition MUST NOT fire the provisioning cascade for a request the provisioning conjunction fails for.
  ```
- **Invariant 3 — Session-gated exercise.**
  ```
  Invariant 3.1: EVERY exercise event MUST follow a Session validate answering valid in the same invocation.
  Invariant 3.2: An exercise event MUST carry the principal reference the invocation's validate answered as the session principal reference.
  ```
- **Invariant 4 — Cascading revocation (conditional on the wired session-issuance surface).**
  ```
  Invariant 4.1: IF the deployment wires a credential-to-session revocation cascade THEN an exercise under a session derived from a revoked credential MUST answer session-invalid.
  ```
- **Invariant 5 — Audit-arc completeness (at quiescence, within the audit horizon).**
  ```
  Invariant 5.1: EVERY request MUST carry a shape-bearing event at quiescence.
  Invariant 5.2: EVERY request record MUST carry the state the request's latest state-transition event carries at quiescence.
  Invariant 5.3: EVERY consumed redemption MUST carry an exercise event at quiescence.
  Invariant 5.4: EVERY redemption failure a resolved exercise reached MUST carry a failed exercise event at quiescence.
  ```
- **Invariant 6 — Approver-credential completeness (through this composition's surface).**
  ```
  Invariant 6.1: EVERY decision a decision action routes MUST follow a Credential verify answering verified for the deciding actor.
  ```
- **Invariant 7 — Denial completeness (at quiescence, within the audit horizon).**
  ```
  Invariant 7.1: EVERY Denied request MUST carry a denial event at quiescence.
  Invariant 7.2: EVERY Denied request MUST name a chain whose state EQUALS Rejected.
  Invariant 7.3: EVERY ProvisioningFailed request MUST carry a provisioning-failure event carrying the relayed reason at quiescence.
  ```
- **Invariant 8 — Immutable request identity.**
  ```
  Invariant 8.1: The composition MUST NOT change a request's identity fields once written.
  Invariant 8.2: A request state MUST NOT return to Pending from a terminal request state.
  ```
- **Invariant 9 — Single audit instance (deployment-declared; verified in two halves).**
  ```
  Invariant 9.1: EVERY event the request-to-events map names MUST resolve in the one audit substrate.
  ```
- **Invariant 10 — Exercise-record durability (inherited, not parallel).**
  ```
  Invariant 10.1: The composition MUST NOT change an exercise event.
  Invariant 10.2: The composition MUST NOT change a failed exercise event.
  ```

---

## Examples

### Happy path — privileged database access under two-approver gate

An engineer requests read access to a production database for incident investigation:

`request_access(requestor_ref: eng_u42, credential: <eng_u42's presented material>, resource_ref: db::prod::incidents, access_scope: "read", justification: "INC-2891 investigation — prod log correlation", approver_set: [mgr_u10, sec_u03], quorum_rule: all-of-N, ttl: 3600) → request_id: req_p7h3k2`

Each approver now holds an Active Assignment for the request's step in Multi-Party Approval's in-tray. The security lead approves first:

`approve_step(actor_ref: sec_u03, credential: <sec_u03's presented material>, request_id: req_p7h3k2, step_id: step_s1, reason: "INC-2891 confirmed active")`

The chain is still Pending (one of two). The manager approves:

`approve_step(actor_ref: mgr_u10, credential: <mgr_u10's presented material>, request_id: req_p7h3k2, step_id: step_s2, reason: "authorized")`

The chain reaches `Approved`. The provisioning cascade fires: `Capability.allocate(allocator_ref: svc_pap, scope: <composed: req_p7h3k2, db::prod::incidents, "read">, max_redemptions: 1, ttl: 3387)` → `capability_token: cap_9f2d1e` — the ttl is the **remaining** lifetime, `expires_at − now`: 213 seconds of the requested 3600 elapsed while the two approvals were gathered, and the token's window ends where the request's does, since Capability's allocate takes the cascade's one reading as its now (Capability requirement 26, Execution Contract Logic confinement 19). The access_provisioned event records the request, never the token. The request transitions to `Provisioned`; the engineer receives `cap_9f2d1e` through the delivery channel.

The engineer authenticates (via Login, out of scope here) and acquires `session_token: sess_a4b7c1`. They exercise the access:

`exercise_access(session_token: sess_a4b7c1, capability_token: cap_9f2d1e) → exercised`

Session validates as `valid(principal_ref: eng_u42, expires_at: …)`. The Capability redeems — `redeemed(scope, allocator_ref: svc_pap)`, the composed scope parsing back to `req_p7h3k2` — and its remaining-redemptions counter decrements 1 → 0, moving the stored status to `Redeemed` (terminal). The Audit Trail records access_exercised with `{request_id: req_p7h3k2, session_principal_ref: eng_u42, exercised_at, result: redeemed}`; `session_access_log` derives the entry from that event.

### Rejection path — first approver rejects; quorum unachievable

A request under all-of-N quorum over two approvers receives a rejection from the first approver:

`reject_step(actor_ref: sec_u03, credential: <sec_u03's presented material>, request_id: req_q5m8n1, step_id: step_s1, reason: "requestor does not have business need for this scope")`

Under all-of-N, one rejection makes quorum unachievable. Multi-Party Approval transitions the chain to `Rejected`. The chain evaluation after [Reject Step] detects this and transitions the request to `Denied`, recording `denial_reason`. The Audit Trail records access_denied. No Capability is ever allocated. Any subsequent [Exercise Access] attempt with a made-up token returns `rejected(capability-invalid(not-known))` — no token was ever issued for this request, so there is nothing in the dedicated Capability instance to present.

### Rejection path — session invalid at exercise time

An engineer was provisioned access (Capability token issued after approval). Before they can exercise it, an administrator revokes their Credential (employment terminated):

`Credential.revoke(credential_id: cred_e42, revoked_by_ref: hr_admin, reason: "employment-terminated")`

The Login composition detects this and invalidates all Sessions derived from `cred_e42`, including `sess_a4b7c1`. The Session record transitions to `Revoked`.

The engineer (or an attacker with their token) attempts:

`exercise_access(session_token: sess_a4b7c1, capability_token: cap_9f2d1e) → rejected(session-invalid(revoked))`

`Session.validate(sess_a4b7c1)` returns `invalid(revoked)`. The Capability is never presented. The Capability token `cap_9f2d1e` remains stored `Allocated` — unconsumed and revocable — until [Revoke Access] revokes it or its deadline passes and the atom derives it Expired. No audit event is recorded for this attempt (the session gate refused before anything attributable happened — the **Failed-Attempt Log** *(forthcoming)* pattern owns pre-authentication attempt auditing).

### Rejection path — forged token under a valid session

The gate's rejecting arm, fired: an insider with a perfectly valid session guesses at a token that was never provisioned:

`exercise_access(session_token: sess_k9r2m4, capability_token: cap_FORGED) → rejected(capability-invalid(not-known))`

Session validates as `valid(principal_ref: user_u77, …)` — the session gate passes. Capability's read finds no record for `cap_FORGED` — the dedicated instance never allocated it, so it traces to no approval and grants nothing — and [Exercise Access] never calls redeem (Action wiring 79), answering `capability-invalid(not-known)` (Action wiring 80). The attempt is recorded — access_exercise_failed with `{request_id: blank, session_principal_ref: user_u77, reason: not-known}` (the declared blank-request exception; the forged material itself is never written) — so the auditor sees *who*, under a real session, presented a token the system never issued. The approval gate is visible here in its refusing mode: no chain, no token, no access, and a named principal attached to the attempt.

### Regulated adversarial scenarios

Four scenarios the composition must survive in regulated contexts:

**Regulator audit — SOX section 404 privileged access control.** An external auditor asks *"can you prove that no one accessed the production financial database with elevated privileges without documented, multi-party authorization?"* The walk uses the declared surfaces, not payload-field queries the substrate does not offer: `read_request({resource_ref: db::prod::financials})` returns every request ever opened against the resource, each carrying its state and its `request_to_events` ids. For each `Provisioned` request the auditor takes the event ids into the substrate — access_provisioned, then every access_exercised — and traces the approval side through `request_to_chain` to the chain's own step records, recomputing the quorum outcome from those step records. Invariant 1 closes the other direction: enumerating the dedicated Capability instance and parsing each composed scope proves every token that exists traces to an `Approved` chain — no orphan tokens, no single-approver grants. The records alone carry the evidence section 404 asks for.

**Disputed access — former employee denies using privileged token.** A security investigation reveals the production credentials database was queried at `2026-11-14T03:22:00Z`. A former employee claims they did not access it. The investigator runs `read_request({resource_ref: db::prod::credentials})`, finds `req_r9s4t1` provisioned that night, and reads its events: the access_exercised event at `03:22:11Z` carries `session_principal_ref: user_u88` — the identity `Session.validate` returned at the moment of exercise, recorded in the event itself rather than recovered by a later cross-reference. The approval chain for `req_r9s4t1` shows the same principal as requestor_ref, with both approvals attested at `02:58Z`. Invariant 3 guarantees the session gate passed in the same call; the Session records corroborate a session issued to `user_u88` at `03:15Z`. The denial cannot be sustained against the structural record; a credential-compromise reinterpretation is the **Compromise Disclosure** *(forthcoming)* pattern's business, never a mutation of this trail.

**HIPAA break-glass access trace — clinical PHI access audit.** A compliance officer must demonstrate to an OCR (Office for Civil Rights) auditor that a nurse's emergency break-glass access to a patient record on `2026-09-12` was authorized and documented. `read_request({resource_ref: ehr::patient::p4471})` returns `req_h8k3n2`; its events show the arc in order: `access_requested` (justification: "INC-4418 cardiac event — emergency PHI (Protected Health Information) access required"), the chain's two approval decisions (charge nurse + attending physician, all-of-N over two, credentials verified at decision time — Invariant 6), access_provisioned, and one access_exercised at `02:44Z` carrying `session_principal_ref: nurse_n21`. The full arc is present in the one Audit Trail instance (Invariant 9's provable half); The records alone carry the access-audit evidence HIPAA section 164.312(b) asks for.

**Breach investigation — approval gate bypassed?** A security team finds an access_exercised event at `2026-12-01T18:44Z` against a high-security vault and asks whether the approval gate was bypassed. The event's request_id leads to `req_v2w5x8`: state `Provisioned`, chain `Approved`, two decision records, quorum recomputation clean. Then the systemic half: enumerate the dedicated Capability instance and parse every composed scope. A token whose scope parses to no request, to a request whose chain is not `Approved`, or that fails to parse at all is evidence of out-of-band allocation. All tokens accounting for themselves is the structural no-bypass answer; Invariant 1 makes the check deterministic.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the composition's state plus the constituent records — the approval substrate's chain and audit records, the dedicated Capability instance, the Session and Credential records. The bar splits in two, because two different things are asked: what the records answer, and what needs evidence the records cannot hold.

### Conformance checks

```
Check 1.1: An auditor MUST enumerate the Capability instance AND parse EVERY record's composed scope to the record's request (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY parsed request's chain Approved, recomputing the quorum under the substrate's own rule (Invariant 1.1).
Check 1.3: An auditor MUST report a bypass token as a provisioning bypass (Invariant 1.1).
Check 1.4: IF a token's request events are aged events THEN an auditor MUST read the request's Provisioned state AND the surviving provisioning attestation in place of the chain records (Capability requirement 10).
Check 2.1: An auditor MUST find, for EVERY exercise event, a Session record of the named principal live across the exercised instant (Invariant 3.1).
Check 2.2: IF Check 2.1 finds no live span of the named principal's Session records across an exercise event THEN an auditor MUST report a discrepancy that DOES NOT EXCEED the clock allowance as inconclusive (Invariant 3.1, Execution Contract Logic confinement 18).
Check 3.1: An auditor MUST find the deciding actor's credential Active across EVERY decision event's recorded instant (Invariant 6.1).
Check 3.2: IF Check 3.1 finds no Active span of the deciding actor's credential across a decision event THEN an auditor MUST report a discrepancy that DOES NOT EXCEED the clock allowance as inconclusive (Invariant 6.1, Execution Contract Logic confinement 18).
Check 4.1: An auditor MUST find a denial event AND a Rejected chain for EVERY Denied request inside the horizon (Invariant 7.1).
Check 4.2: IF a ProvisioningFailed request carries no open pending entry THEN an auditor MUST find the request's provisioning-failure event (Invariant 7.3).
Check 5.1: An auditor MUST rebuild EVERY in-horizon index entry by the element's declared rebuild AND reproduce EVERY traversal answer (Composition state 16).
Check 5.2: An auditor MUST report an in-horizon index entry the rebuild cannot reproduce as a conformance failure (Composition state 29).
Check 5.3: An auditor MUST find EVERY index entry for an aged event present (Composition state 30).
Check 5.4: An auditor MUST find no bearer material in an audit event (Composition state 14).
Check 5.5: An auditor MUST find no bearer material in a request result (Action wiring 111).
Check 6.1: An auditor MUST reconstruct a request's arc from the request's events through the request-to-events map (Invariant 5.1).
Check 6.2: An auditor MUST verify EVERY event of the arc through Audit Trail's read record AND verify record (Invariant 10.1).
Check 6.3: An auditor MUST read a request carrying an open pending entry as a surfaced recovery window (Invariant 5.1).
Check 6.4: An auditor MUST report a consumed redemption carrying no exercise event AND no open pending entry as a finding (Invariant 5.3).
Check 6.5: An auditor MUST report a recovery record whose data disagrees with the constituent records as a finding (Reconciliation 16).
Check 6.6: An auditor MUST report a request carrying no shape-bearing event AND no open pending entry as a finding (Invariant 5.1).
Check 6.7: An auditor MUST report a redemption failure a resolved exercise reached carrying no failed exercise event AND no open pending entry as a finding (Invariant 5.4).
```

NOTE: EVERY check names the rule the check tests.

Term bypass token: a token whose composed scope parses to no request, to a request whose chain is not Approved, or not at all.

Term discrepancy: the length of time an instant a check tests lies outside the span the check reads, measured to the span's nearest edge — for Check 2.1, from the exercise event's exercised instant to the nearest edge of any live span of the named principal's Session records, and for Check 3.1, from the decision event's recorded instant to the nearest edge of any Active span of the deciding actor's Credential records.

Term clock allowance: Execution Contract Logic confinement 18's setting, spent here between the clock of this composition's call and the clock of another call that stamped a constituent's record, as a Session record's issue and revocation and a Credential record's are stamped; none is spent inside one call (Execution Contract Logic confinement 19).

### External checks

```
External check 1: An auditor needing the arc confirmed un-fragmented MUST read the deployment's declaration AND wiring (Invariant 9.1).
External check 2: An auditor needing the composed-scope encoding confirmed MUST read the deployment's declaration AND conformance tests (Capability requirement 15).
External check 3: An auditor needing the delivery channel confirmed MUST read the deployment's operational security evidence (Provisioning cascade 12).
External check 4: An auditor needing the service identity's custody confirmed MUST read the deployment's issuance, rotation AND retirement records (Capability requirement 17).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT own a chain's quorum rules.
Non-goal 2: The composition MUST NOT issue a session.
Non-goal 3: A deployment without Login MUST satisfy the session gate through an equivalent issuance surface.
Non-goal 4: The composition MUST NOT own the delivery channel's mechanism.
Non-goal 5: The composition MUST NOT define who may request access to what.
Non-goal 6: The composition MUST NOT revoke a capability on a credential revocation.
Non-goal 7: A deployment needing a token revoked on a credential revocation MUST wire a listener calling [Revoke Access].
Non-goal 8: The composition MUST NOT renew a request.
Non-goal 9: The composition MUST NOT reuse a ProvisioningFailed request's chain.
Non-goal 10: The composition MUST NOT offer a third-party withdrawal.
Non-goal 11: A deployment MUST notify the requestor of a ProvisioningFailed request.
Non-goal 12: The composition MUST NOT make [Exercise Access] idempotent.
Non-goal 13: A deployment automating exercise MUST supply the deployment's own at-most-once delivery.
Non-goal 14: The composition MUST NOT record a failed session gate.
Non-goal 15: The composition MUST NOT hide a request's existence from an authenticated caller.
Non-goal 16: The composition MUST NOT seal a composition index.
Non-goal 17: The composition MUST NOT refuse an approver set naming the requestor reference.
Non-goal 18: IF the delivery channel fails to carry the capability token to the requestor THEN the deployment MUST call [Revoke Access] for the request.
```

NOTE: watch the segregation policy (Non-goal 17).

NOTE: the owners — the deployment (Non-goal 4 through 7); an Idempotency Result Memo (Non-goal 12); a Failed-Attempt Log *(forthcoming)* (Non-goal 14); the deployment's calling layer (Non-goal 15); the deployment's segregation policy (Non-goal 17); the deployment's delivery failure (Non-goal 18).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A deployment MUST own the honesty AND the monotonicity of the injected now.
Clock semantics 2: A deployment needing a verifiable wall-time anchor MUST compose Trusted Timestamping.
```

### Concurrency

### Expiry

```
Expiry 1: The composition MUST NOT write a capability's expiry.
Expiry 2: A lapsed capability MUST leave the request state Provisioned.
Expiry 3: The composition MUST NOT gate a decision on the request's expiry instant.
Expiry 4: A deployment wanting stale Pending requests withdrawn MUST call [Withdraw Request] from the deployment's own scheduler.
```

### Multi-use capabilities

```
Multi-use capabilities 1: The composition MUST record EVERY exercise of a multi-use token as the exercise's own event.
Multi-use capabilities 2: The composition MUST NOT change the request state on a token's exhaustion.
```

---

## Composition notes

- **[Login](./login.md)** — the upstream composition that issues Sessions. This composition depends on Sessions being issued by Login (Credential.verify → Session.issue → session_token returned to principal). Without Login or an equivalent session-issuance surface, [Exercise Access] always returns `session-invalid(not-known)`. Login is a peer composition, not a constituent; the two share the same Session and Credential atoms but own distinct composition-level surfaces.

- **[Session-Gated Authorization](./session-gated-authorization.md)** — a peer composition that gates permission checks on session validity. Privileged Access Provisioning gates Capability redemption on session validity; Session-Gated Authorization gates Permissions.permitted checks. The two are structurally parallel: both call `Session.validate` before a downstream action, neither managing Session issuance. A deployment that wires both ensures that session validity is checked consistently at every protected surface — Capability redemption and Permissions evaluation alike.

- **[External Onboarding](./external-onboarding.md)** — in regulated deployments where privileged users are external contractors or auditors rather than internal employees, External Onboarding (Invitation → Party Identity → Credential registration) is the upstream surface that establishes the requestor's Credential. A [Request Access] call with an unregistered requestor_ref fails the credential check at intake (Action wiring 12). External Onboarding establishes the Credential that this composition verifies.

- **[Capability-Backed Sharing](./capability-backed-sharing.md)** — a peer composition that uses Capability for resource disclosure rather than privileged access. The two compositions share the Capability atom but wire it to different upstream gates: Capability-Backed Sharing gates on Selective Disclosure policy; this composition gates on Multi-Party Approval. The structural similarity — approve first, allocate Capability second, record in Audit Trail third — is the pattern the library names as approval-gated capability provisioning.

- **Tamper Evidence — already applied where the truth lives, and not applicable where it does not.** Everything evidentiary in this composition's arc is already tamper-evidence-covered or immutably constituent-held: the request, approval, provisioning, exercise, and revocation events are ordinary audit events under the substrate's Tamper Evidence sealing, and the token binding is a field of the Capability's own immutable record. The composition's maps are derived indexes — rebuildable caches carrying no truth of their own — so there is nothing there *to* seal, and sealing them would certify a cache, not a fact. A deployment is not offered a "seal the `request_store`" surface, and deliberately: Tamper Evidence commits to a record set presented at seal time, which is meaningless over state that includes a still-transitioning field; the evidentiary surface for legal proceedings is the sealed event trail, reached through `request_to_events`.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the pattern. The composition's own concepts are the seven actions it exposes, the three request scopes it defines for its Permissions instance, and its own refusals. Approval gates provisioning, session-gated exercise and single-trail arc completeness are structural properties, not data. The deployment settings keep their wire spellings in configuration — `default_ttl`, `max_redemptions_default`, `credential_type`, `credential_check_on_request`, `approver_set_minimum`, `audit_trail_retention_policy`, `store_durability`, `application_actor_ref`, `application_credential` — and the six elements theirs in an implementation, `request_store`, `request_to_chain`, `request_to_capability`, `capability_to_request`, `session_access_log`, `request_to_events`, with the recovery list as `audit_pending`; the pattern names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the approval substrate; the audit substrate; the host; the transition; the reconciliation; the provisioning cascade; the chain evaluation; the rebuild; a deployment; an auditor; a caller; a requestor; an approver; a deciding actor; a bearer; an investigator; an invocation; an action; a credentialed action; a decision action; an admitted request; a resolved exercise; a leg; the approval leg; the terminal-chain leg; the redemption leg; the initiation leg; the denial-reason leg; a request; a request record; a chain; a token; a session; a pending entry; an index entry; a session access entry; the service identity; the delivery channel.

Term records: the audit events the composition records through the audit substrate — each an Audit Trail event carrying one action reference below — the request records, and the index entries.

Term record verbs: acquire, add, alert, answer, attest, belong, call, carry, change, check, classify, close, commit, compare, complete, compose, compute, configure, declare, define, delete, deliver, emit, enumerate, expose, find, fire, follow, gate, grant, hide, hold, inherit, initiate, inject, issue, key, land, leave, make, mark, mint, name, normalize, notify, offer, open, order, own, pair, parse, pass, provision, purge, read, rebuild, reconstruct, record, refuse, register, renew, report, resolve, retry, return, reuse, revoke, run, satisfy, seal, serve, set, stamp, store, supply, take, validate, verify, wire, write.

Term value sets: action reference = access_requested | approval_step_decided | access_provisioned | access_denied | access_request_withdrawn | access_provisioning_failed | access_exercised | access_exercise_failed | access_revoked | access_recovery_intended | access_audit_recovery. The rest are declared where the section that owns each declares it: request state, open request state, terminal request state, refused state, refusing chain state, credential check on request, validation failure, exercise failure, terminal chain action, bearer material.

Term bounds: audit horizon (audit_trail_retention_policy), default ttl (default_ttl), max redemptions default (max_redemptions_default), approver set minimum (approver_set_minimum), reference caps, payload budget.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, approval substrate, audit substrate, trail, chains initiate, chains withdraw, chains read, request record, request id, request state, request progression, open request state, terminal request state, refused state, identity field, request shape, shape-bearing event, state-transition event, latest state-transition event, denial reason, requested instant, access scope, justification, terminal event, event envelope, bearer material, request-to-chain map, request-to-capability map, capability-to-request map, session access log, session access entry, transactional index writes, request-to-events map, audit pending list, pending entry, closing occasion, aged event, quiescence, default ttl, max redemptions default, credential type, credential check on request, approver set minimum, audit horizon, retention floor, longest token lifetime, provisioning proof period, refused ttls, composed scope, service identity, reference caps, seam, now, invocation id, remaining ttl, request ttl, expiry instant, payload budget, validation failure, exercise failure, request results, credentialed action, decision action, load-bearing act, validated request, admitted withdrawal, validated exercise, verified revocation, admitted revocation, permitted read, admitted request, initiation entry, evaluation entry, denial-reason entry, exercise entry, resolved exercise, chain evaluation, provisioning conjunction, terminal chain action, requests initiate, requests revoke, requests read, reconciliation, recovery intent, recovery record, refusing chain state, provisioning cascade, delivery channel, bypass token, clock allowance, request event, decision event, provisioning event, denial event, withdrawal event, initiation-failed withdrawal event, provisioning-failure event, exercise event, failed exercise event, revocation event, read query, unavailable, mapped refusal, recording failure.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Database 1 — an index write and its event commit together. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index, truth-bearing and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. initiate chain, approve step, reject step, withdraw chain, read chain, chain id, step id, subject reference, approver set, quorum rule, terminal summary, chain_resolved, chain_withdrawn, Approved, Rejected, Withdrawn, Pending, not-pending, unauthorized, position: Multi-Party Approval. record action, read record, purged, verify record, event id, payload cap, actor registry, invalid-credential, recording-failure: Audit Trail. verify, failed-verification, verified, Active: Credential. validate, valid, invalid, session token, principal reference: Session. permitted, denied: Permissions. allocate, redeem, revoke, read, capability token, scope, max redemptions, remaining redemptions, ttl, allocator reference, redeemed, effective status, redemption failure, exhausted, expired, revoked, already-terminal, Redeemed, Expired: Capability.

Term composing patterns: [Login](./login.md); [Session-Gated Authorization](./session-gated-authorization.md); [External Onboarding](./external-onboarding.md); [Capability-Backed Sharing](./capability-backed-sharing.md); Failed-Attempt Log *(forthcoming)*; [Owed Record](../atoms/owed-record.md); [Erasure Tombstone](../atoms/erasure-tombstone.md); Trusted Timestamping *(forthcoming)*; Compromise Disclosure *(forthcoming)*.

Term request event: the access_requested event — a request's shape-bearing opening record.

Term decision event: the approval_step_decided event — a decision keyed by request.

Term provisioning event: the access_provisioned event.

Term denial event: the access_denied event.

Term withdrawal event: the access_request_withdrawn event.

Term initiation-failed withdrawal event: a withdrawal event carrying the request shape and, as the reason, the mapped refusal where initiate chain refused (Action wiring 19) or initiation-failed where the initiation leg found the request record carrying no chain id (Reconciliation 33 and 35) — the only shape-bearing event a request closed with no chain id carries.

Term provisioning-failure event: the access_provisioning_failed event.

Term exercise event: the access_exercised event.

Term failed exercise event: the access_exercise_failed event.

Term revocation event: the access_revoked event.

#### Request Access

The intake action: submit a privileged-access request under a named requestor, gate it on [Requests Initiate] and — where configured — the requestor's credential, write the request, open its approval chain, and record the request event (Action wiring 10 through 13 and Action wiring 15 through 29). Answers the request id; the request is Pending. Refuses [Permission Denied] where Permissions answers denied (Action wiring 11) and [Invalid Credential] where Credential's verify answers failed-verification (Action wiring 3) and [Recording Failure] where the database refuses the request record (Action wiring 15), and relays the approval substrate's initiation refusals (Action wiring 22 through 25 and Action wiring 123 through 125); a [Recording Failure] carrying outcome carries the request id (Action wiring 124).

Kind: Operation

#### Approve Step

The wrapper over Multi-Party Approval's step approval: verify the approver's credential, route the decision, record it keyed by request, and run the chain evaluation — which fires the provisioning cascade when the chain reaches Approved, the only path to a provisioned token (Action wiring 31 through 41 and Action wiring 43 through 58).

Kind: Operation

#### Reject Step

The wrapper over Multi-Party Approval's step rejection: [Approve Step]'s wiring with a required reason; the chain evaluation lands the request Denied when the chain reaches Rejected.

Kind: Operation

#### Withdraw Request

The requestor's withdrawal of their own Pending request and its chain — structurally only the requestor's, since the chain admits withdrawal solely from its initiator (Action wiring 59 through 74). The requestor's chains withdraw grant in the approval substrate is the permission surface.

Kind: Operation

#### Exercise Access

The session-gated use of a provisioned token: validate the session *first* — a non-valid session is [Session Invalid] before the token is touched — then resolve the token, write the exercise entry, redeem, and record every attempt that reached the atom, each naming the principal reference the invocation's validate answered (Action wiring 75 through 82 and Action wiring 84 through 94). Not idempotent: each live presentation consumes a redemption, and a consumed redemption is always answered exercised.

Kind: Operation

#### Revoke Access

The revocation of a provisioned token, gated by [Requests Revoke]; the request moves to Revoked, a token already terminal (redeemed, expired or revoked) included (Action wiring 101 through 103). Answers [Not Provisioned] for a request not Provisioned (Action wiring 95 through 103).

Kind: Operation

#### Read Request

The read-only query over request records, gated by [Requests Read]: each result carries the request's fields and pending list, the chain's state, the token's derived effective status and the request's event ids — never bearer material — in declared order. Records no event and takes no credential (Action wiring 104 through 112).

Kind: Operation

#### Requests Initiate

The scope admitting [Request Access].

Kind:       Member
Member of:  the request scope vocabulary
Role:       Scope
Projection: requests:initiate

#### Requests Revoke

The scope admitting [Revoke Access] on any provisioned request.

Kind:       Member
Member of:  the request scope vocabulary
Role:       Scope
Projection: requests:revoke

#### Requests Read

The scope admitting queries over request records and their chain, token and audit events.

Kind:       Member
Member of:  the request scope vocabulary
Role:       Scope
Projection: requests:read

#### Not Provisioned

The [Revoke Access] refusal for a request not Provisioned — there is no live token to revoke.

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: not-provisioned

#### Session Invalid

The [Exercise Access] gate refusal, carrying Session's own reason — expired, revoked or not-known — answered when validate is not valid, *before* the token is presented. The structural form of the cascading-revocation invariant (Invariant 4).

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: session-invalid

#### Permission Denied

The refusal when the actor lacks the request scope an action checks — at [Request Access], [Revoke Access] or [Read Request] — and, relayed, when the approval substrate's own chain scopes refuse at [Request Access] or [Withdraw Request], the double gate the deployment wires, surfaced under this code so the caller learns the true cause.

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: permission-denied

#### Recording Failure

The composition's rejection for a write the database refused or a constituent's recording failure relayed, carrying its position — intent, nothing committed and the action retryable in whole; outcome, the act committed and its record owed (Recoverable Invocation Invariant 8.3 and Recoverable Invocation Invariant 8.4, which Multi-Party Approval's acting actions follow). The composition's own refusal carries intent (Action wiring 15, Action wiring 98 and Action wiring 100); the approval substrate's carries its position unchanged (Action wiring 25, Action wiring 36 and Action wiring 71), and at [Request Access] a position of outcome carries the request id (Action wiring 124).

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: recording-failure

#### Invalid Credential

The refusal when Credential's verify answers failed-verification — material-mismatch or no-active-credential — for a requestor or an approver, or when the approval substrate's attest refuses the credential; the enforcement behind approver-credential completeness (Invariant 6).

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: invalid-credential

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Request Access]: #request-access
[Approve Step]: #approve-step
[Reject Step]: #reject-step
[Withdraw Request]: #withdraw-request
[Exercise Access]: #exercise-access
[Revoke Access]: #revoke-access
[Read Request]: #read-request
[Requests Initiate]: #requests-initiate
[Requests Revoke]: #requests-revoke
[Requests Read]: #requests-read
[Not Provisioned]: #not-provisioned
[Session Invalid]: #session-invalid
[Permission Denied]: #permission-denied
[Invalid Credential]: #invalid-credential
[Recording Failure]: #recording-failure

---


## Standards references

- **SOX section 404 (Management Assessment of Internal Controls)** — privileged access to financial systems requires documented, multi-party authorization. This composition's approval-gates-provisioning invariant and its Audit Trail arc are the structural implementation of the section 404 access-control evidence requirement. Every access_exercised event traces to a documented, approved request with named approvers.

- **HIPAA section 164.312(a)(1) (Access Control)** — covered entities must implement technical policies and procedures for electronic information systems that allow access only to authorized users. The composition's multi-party approval gate is the authorization policy; the Credential.verify checks at both request and approval time ensure the actors in the arc are authenticated; the Session.validate check ensures the principal is currently authenticated at exercise time.

- **HIPAA section 164.312(b) (Audit Controls)** — covered entities must implement mechanisms that record and examine activity in information systems that contain or use electronic protected health information. The Audit Trail holds the request, each approval decision, the provisioning and every exercise with the session principal, and read_request walks them by request id.

- **PCI DSS Requirements 7 and 8 (Restrict Access and Identify Users)** — Requirement 7 mandates that access to system components and cardholder data is restricted to only those individuals whose job requires such access. Requirement 8 mandates that all users are assigned a unique ID before access is allowed. This composition enforces both: the approval chain documents the business need; the requestor_ref and the Session record establish the unique user identity.

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-53 AC-2 (Account Management) and AC-6 (Least Privilege)** — AC-2 requires that privileged user accounts are authorized by senior officials and reviewed regularly. AC-6 requires that privileged access is limited to the minimum required. This composition models the authorization record (AC-2) and the time-limited, scoped Capability (AC-6's minimum-necessary principle expressed as a token with explicit TTL — time-to-live, a validity duration — and scope).

- **NIST SP 800-53 AC-17 (Remote Access)** — in deployments where privileged access is exercised remotely, the session-gated exercise check enforces that remote access is only permitted under an authenticated session. The Audit Trail records the session's authenticated `principal_ref` and the `exercised_at` stamp for every remote access exercise — never the session token, which is bearer material and appears on no record surface — satisfying the remote-access audit requirement without the trail granting what it records.

- **ISO/IEC 27001 clause A.9.2.3 (Management of Privileged Access Rights)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard requires that the allocation and use of privileged access rights is controlled and restricted. This composition directly implements that control: allocation is gated by approval; use is gated by session validity; both are recorded in a tamper-evident log.

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — privileged-access-provisioning.tla + 13 twins (2026-11-22: the reconciliation's sweep over the request event and the exercise event, each landed, refused or landed with its answer lost, the pending entries owing them and the trail's originals, recovery intents and recovery records, checked as SweepPreCheckNoDuplicate (Reconciliation 4 through 6), SweepAttestedByService (Reconciliation 11), SweepNoAgedWrite (Reconciliation 10), RecoveryRecordNamesOwed (Reconciliation 15) and RecoveryRecordFollowsIntent (Reconciliation 12 through 14), broken by privileged-access-provisioning-buggy-sweep-no-precheck.tla, privileged-access-provisioning-buggy-sweep-unattested.tla, privileged-access-provisioning-buggy-sweep-aged-write.tla, privileged-access-provisioning-buggy-sweep-fresh-invocation.tla and privileged-access-provisioning-buggy-sweep-no-recovery-intent.tla; the evaluation entry and Reconciliation 16 not modeled; the model found that an entry whose owed record is aged has no closing occasion, since Reconciliation 2 retries it on every run, Reconciliation 10 bars the write and Composition state 32 closes it only once its record lands, so the request never reaches quiescence, and that Reconciliation 10's aged event is undefined for an owed record that never landed, which carries no recording instant); privileged-access-provisioning.als + 10 twins (the static data model, 2026-11-12: Invariant 3.2, 6.1, 7.1, 7.3, 8.1, 10.1 and 10.2, with 3.1 and 7.2 cross-checking the TLA+ model, checked on every state of the request records, the trail's events, each an original or a recovery record read as the event it names, and the open and closed pending entries the request, decision, chain evaluation and cascade, exercise and reconciliation writes leave; the model found that Invariant 7.1 holds only where Audit Trail lands the denial event of a chain evaluation that follows no committed load-bearing act (the terminal-chain leg, Reconciliation 22, or Withdraw Request's not-pending arm, Action wiring 64), since Action wiring 54 sets Denied and Action wiring 7 opens an entry only after a committed act, unless Action wiring 8 holds the request state until its event lands, which leaves the quiescence of Invariant 7.1 and 7.3 qualifying nothing; and that Action wiring 81 gives the failed exercise event of a token resolving to no request no session principal and no exercised instant, which the forged-token example and Composition state 24 and 25 carry); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12, 2026-11-22: owed rows: Liveness; 2a: Liveness — owed: a PROPERTY under TLC; the file's FairnessSpec already states the fairness (weak fairness on the withdraw and revoke steps), the header names it; twin: a model that never delivers the cascade, 2026-06-03
last gate: 2026-11-19 — Final Critique 13, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at e3af1687 — foundational count 0 after the blind second triage, clean, one sample; Linus's one report claimed 1 foundational and 1 refining: the foundational is the open line 2026-11-18-a re-found, read with a measure the page does not hold (it takes the discrepancy of Check 2.2 and Check 3.2 for the time between two calls' stamps, a Session issued and revoked hours apart, where Check 2.1 and Check 3.1 ask whether the event's instant falls within the record's live or Active span and the discrepancy is how far it lies outside, a gap the clock allowance of Term clock allowance spends between the clocks of two calls), placed refining by both triages, and its cure (compare same-action stamps against the allowance and distinct-action stamps against a declared elapsed-time bound) refused: it spends the allowance only where Execution Contract Logic confinement 19 says none is spent, takes it from the distinct calls Logic confinement 18 and the Term name, and adds a setting no rule needs, so the line stands, extended; the refining (Check 2.2 and Check 3.2 share a body) placed rhetorical and declined, since each check names the one invariant it tests; Multi-Party Approval changed since the diff base and is unreached by the page's rules; 2026-11-18 — Final Critique 12 — delta, frozen at 7495618 — foundational count 1 after the blind second triage, not clean, no sample (Check 2.2 and Check 3.2 left a discrepancy exactly equal to the operating skew unowned; cured by DOES NOT EXCEED the clock allowance, the term renamed to the owner's name and cited to Execution Contract Logic confinement 18)

open:
- 2026-11-21-a · refining · Reconciliation 2, Reconciliation 10, Composition state 32, Term aged event · a pending entry whose owed record is an aged event has no way to close: Reconciliation 2 retries it on every run, Reconciliation 10 bars the write, and Composition state 32 closes it only once its record lands, so the request never reaches quiescence and Invariant 5 and Invariant 7 hold vacuously for it; Term aged event reads a recording instant an owed record that never landed does not have → close the entry as lapsed, writing nothing, once the owed record would be an aged event counted from the instant the entry was opened (asked of Scott, rounds/escalations.md; found by the model of 2026-11-21)
- 2026-11-21-b · refining · Reconciliation 4, Reconciliation 12 through 15 · after a crash between a leg's recovery intent and its recovery record the page does not say whether the next run lands a second recovery intent, and Reconciliation 4's pre-check read on the intent would find it and close the entry without landing the record → the leg reads the trail for its own recovery intent and lands the recovery record under the one it finds (asked of Scott, rounds/escalations.md; found by the model of 2026-11-21)
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./privileged-access-provisioning.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/privileged-access-provisioning.md`.

</details>

NOTE: End of Privileged Access Provisioning.

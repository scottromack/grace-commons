---
title: Privileged Access Provisioning
parent: Conceptual Compositions
nav_order: 9
has_toc: true
toc: true
---

# Privileged Access Provisioning

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Privileged Access Provisioning governs the full life of a request for elevated access — to financial controls, patient records, production credentials, and the like — where the access must be approved by more than one party and must be time-limited rather than standing.

A request is submitted under a named requestor, must clear a mandatory multi-party approval chain, and only then results in a time-limited, scoped access token being issued; every time that access is actually used, the presenting principal's session is checked for validity first, and the record of the use names that principal.

It combines six patterns: the multi-party approval gate, credential authentication, time-limited sessions, caller authorization (Permissions), the access token itself (a Capability — a bearer token good for a bounded time and scope), and the tamper-evident audit record spanning the whole arc.

The central guarantees, which appear only when the patterns are combined, are that no access token can exist without an approved chain behind it (so an auditor can confirm every token traces back to real approvals), that access cannot be used under an expired or revoked session, and that the entire recorded arc — request, approvals, provisioning, each use, and revocation — sits in one audit record with no gaps and nothing to cross-correlate; expiry is derived from the token's own deadline and writes nothing. Modeling the access as a time-limited token rather than a standing permission is deliberate: privileged access is temporary authorization, not indefinite access.

This is the worked example of approval-gated provisioning behind privileged access management, break-glass access, and time-boxed administrative escalation.

---

## Intent

Privileged access — access to financial controls, patient records, production credentials, source-of-truth databases, cryptographic key material — differs from ordinary access in two ways. First, the grant itself must be authorized by more than one party: a single administrator who can self-approve elevated access to any resource is a control failure under every regulated framework from SOX (the Sarbanes-Oxley Act — US corporate financial-reporting law) to HIPAA (the Health Insurance Portability and Accountability Act — US healthcare-data privacy law) to PCI DSS (the Payment Card Industry Data Security Standard). Second, the access must be time-limited and scoped: indefinite standing access to privileged resources is the most common finding in security audits, because standing access that outlives the business need is indistinguishable from residual access that was never intended.

The six constituents address neither property alone. [Multi-Party Approval](./multi-party-approval.md) enforces the approval gate but does not produce the access artifact. [Capability](../atoms/capability.md) produces the time-limited scoped access token but knows nothing about whether an approval chain cleared. [Session](../atoms/session.md) validates the authenticated channel but does not gate any downstream action. [Credential](../atoms/credential.md) authenticates the principal but does not know what they are requesting access to. [Permissions](../atoms/permissions.md) authorizes who may ask but neither approves nor provisions. [Audit Trail](./audit-trail.md) records everything and decides nothing. The composition is the layer that wires these concepts into a single, enforceable arc: no Capability is issued without an Approved chain; no access exercise succeeds without an active Session; the full arc is recorded in one tamper-evident Audit Trail.

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

WHY:
**Multi-Party Approval** is the approval gate, read as a substrate (Composes 9). One chain per request: the chain's subject reference *is* the request id and its scope the request's access scope (Composes 13 and 14). The substrate's chain actions — initiate_chain, approve_step, reject_step, withdraw_chain — are passed through this composition's surface, which adds the credential check and the request-level record around each, and the caller's credential passes through to the substrate's own signatures, which require it. **Two Permissions gates stand in the arc by construction, and the deployment wires both** (Composes 20 and 21): this composition's own request scopes on its instance, and the substrate's chain scopes on the substrate's. A requestor needs chains withdraw as well as chains initiate because withdrawal is the substrate's initiator-only act, so the only lawful withdrawer *is* the requestor; the service identity needs chains read because every chain read here is made as the composition (Composes 19). The approval substrate records through the same Audit Trail instance this composition does — one instance for the full arc (Composes 10).

**Credential** is the authentication check on the requestor before intake and on each approver before a decision is routed — the latter so an approver revoked between the chain's initiation and the decision cannot decide. It is queried read-only; register, rotate and revoke belong to Login or the identity-management surface (Composes 15).

**Session** is the channel every exercise is gated on, first. When the session is valid, the atom's own answer hands the composition the session's principal reference, which the exercise record names — the identity at exercise time is the session's declared answer, never a reach inside the atom. Sessions are issued by [Login](./login.md), a peer; the cascade from a credential's revocation to its sessions is Login's, and Invariant 4 is conditioned on it being wired (Composes 16).

**Permissions** authorizes who may ask: requests initiate at [Request Access], requests revoke at [Revoke Access], requests read at [Read Request] (Composes 18). [Withdraw Request] carries no composition-layer check — it is structurally the requestor's own act, mirroring the substrate's initiator-only withdrawal — and approvers are authorized by the chain's approver set, not by a grant (Wiring decision 5). The policy of who holds which scope is the deployment's (Composes 17).

**Capability** is the provisioned token, in an instance dedicated to this composition (Composes 12) — which is what lets a redemption resolve provenance: any token that instance knows was allocated by this composition's cascade. The atom declares its scope opaque, interpreted by whatever uses it, and this composition is the interpreter: the request id, resource reference and access scope ride the token's own immutable scope as the composed scope (Capability requirement 15 and 16), so the request-to-token binding is the constituent's record, not composition truth. **There is no expire action and no expiry write anywhere**: a lapsed token is *shown* expired by the atom's derived effective status and refuses redemption; nothing writes an expiry. The atom records no redeemer — its declared audit asymmetry — and the exercise record here names the session's principal instead.

**Audit Trail** is the regulated-audit substrate, consumed at its declared contract (Composes 9 and 11). Its record_action refusal carries the step, read wherever a record follows a committed act, since at the substrate's fourth step the event is already appended and a retry would double it; the recovery discipline's pre-check is what makes a retry safe. Event Log, Actor Identity, Retention Window and Tamper Evidence are reached through it and held nowhere else here. One instance carries the five recorded stages of the arc — request, decisions, provisioning, each exercise, revocation; expiry is derived and writes nothing.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a request record per request.
Composition state 2: A request record MUST carry the request id, the requestor reference, the resource reference, the access scope, the justification, the requested instant, the expiry instant, the chain id, the request state AND the audit pending list.
Composition state 3: A request record MUST carry a denial reason ONLY IF the request state IS IN the refused states.
Composition state 4: The composition MUST NOT change a request record's identity fields.
Composition state 5: The composition MUST NOT change a chain id a request record carries.
Composition state 6: The composition MUST change a request state PER the request progression.
Composition state 7: The composition MUST NOT change a request state that IS IN the terminal request states.
Composition state 8: The composition MUST NOT delete a request record.
Composition state 9: EVERY audit event the composition records MUST carry the request id AND the invocation id.
Composition state 10: A failed exercise event for a token resolving to no request MUST carry blank as the request id.
Composition state 11: A shape-bearing event MUST carry the request shape.
Composition state 12: A state-transition event MUST carry the resulting request state.
Composition state 13: IF a denial reason stands THEN a state-transition event MUST carry the denial reason.
Composition state 14: The composition MUST NOT write bearer material into an audit event.
Composition state 15: The composition MUST rebuild a missing request record from the trail.
Composition state 16: The rebuild MUST take a request's identity fields from the request's shape-bearing event.
Composition state 17: The rebuild MUST take a request's state from the request's latest state-transition event.
Composition state 18: The rebuild MUST read a recovery record as the event the recovery record names.
Composition state 19: The composition MUST resolve a request's chain from the request record's chain id.
Composition state 20: The composition MUST store the request-to-chain map as an index over the request records' chain ids.
Composition state 21: The composition MUST store the request-to-capability map.
Composition state 22: The composition MUST store the capability-to-request map.
Composition state 23: The composition MUST rebuild the capability maps from Capability's read by parsing each record's composed scope.
Composition state 24: The composition MUST store the session access log as an index over the exercise events AND the failed exercise events.
Composition state 25: A session access entry MUST carry the request id, the session principal reference, the exercised instant AND the result.
Composition state 26: The composition MUST store the request-to-events map.
Composition state 27: The composition MUST add an event id to the request-to-events map ONLY AFTER Audit Trail's record action answers the event id.
Composition state 28: The request-to-events map MUST NOT key an event carrying blank as the request id.
Composition state 29: The composition MUST NOT rebuild an index entry from an aged event.
Composition state 30: The composition MUST leave standing an index entry whose event is an aged event.
Composition state 31: A pending entry MUST carry the action reference, the event data AND the invocation id of the record the pending entry owes.
Composition state 32: The composition MUST close a pending entry ONLY AFTER the pending entry's record lands.
Composition state 33: The composition MUST open a pending entry under the per-request exclusion.
Composition state 34: The composition MUST close a pending entry under the per-request exclusion.
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

Term bearer material: a capability token | a session token — material whose holder can exercise what it names.

Term request-to-chain map: the composition's map from a request id to the request's chain id.

Term request-to-capability map: the composition's map from a request id to the request's capability token.

Term capability-to-request map: the composition's map from a capability token to the request id the token's composed scope names.

Term session access log: the per-request record of every [Exercise Access] that reached Capability's redeem.

Term session access entry: one entry of the session access log.

Term request-to-events map: the composition's map from a request id to the event ids recorded for the request, in recording order — the declared request-to-audit traversal.

Term audit pending list: a request record's list of pending entries, empty by default.

Term pending entry: an open record owed on a request — an initiation entry, an exercise entry, an evaluation entry, a denial-reason entry, or the owed record of a committed act.

Term aged event: an event whose `recording instant + audit horizon` PRECEDES now — past which the event's payload may be lawfully destroyed.

Term quiescence: a state in which no invocation is in flight and no pending entry is open.

WHY:
**The request store and five maps, and what each is.** Every element is a derived index inside the audit horizon, and two classes of state here are truth-bearing and named as such rather than folded into that sentence (the section titled Composition state in `execution-contract.md`). The truth the elements accelerate lives in the constituent stores and the trail: the composition records its request-level truth *as audit events through the substrate's record_action* — the Contract's record-by-composing-Event-Log rule, the same discharge Multi-Party Approval makes one layer down — and the token binding in the Capability record's own immutable scope.

**The payload requirement is what makes the rebuilds total** (Composition state 9 through 14). Every event carries the request id and the seam-injected invocation id of the invocation that emitted it — the second is what lets the recovery discipline's pre-check tell an event that landed from one that is owed, exactly, rather than by matching payload fields. The one declared exception is a failed exercise for a token that resolves to no request: no request exists, and the attempt is evidence about the presenter. A shape-bearing event carries the whole request shape, and **the initiation-failed withdrawal event is one**, because it is the only event a request closed before its chain existed will ever have; a rebuild that read identity from the request event alone dropped those requests. **No event carries bearer material**: the token binding is read from the Capability store and the exercise identity is the session's principal — the alternative would be audit data, readable under requests read, that grants the very access it records.

**Request store.** Derived index outside the recovery window: enumerate the trail by the declared sequence-range read, filter in the composition's own code to this composition's action references, take identity from the shape-bearing event and state from the latest transition (Composition state 15 through 18); a recovery record stands in for the original it names. Bounded by the audit horizon: past it a purged payload is unreadable, so the classification splits by retention state — **truth-bearing** beyond, where the record is the only surviving copy of the request's identity, and the never-delete rule (Composition state 8, Capability requirement 13) is the durability obligation that makes it one. The progression is forward only; Provisioned is not terminal — it advances to Revoked — and later lapse or exhaustion of the token is the constituent's own record, never a request-state write.

**Request-to-chain map — over the record's own chain id first, the event second** (Composition state 19 and 20). The record carries the binding from the instant initiate_chain answers, so the actions resolve a chain from the record and the map is acceleration over that field; that is what lets a decision or a withdrawal find a live chain before the request event lands. **A second source appears to exist, and whether it is one is a deployment fact to check rather than assume**: the approval substrate's chain store is keyed by subject reference, which *is* the request id — but that chain store is itself a derived index over audit events, so where the two compositions share one Audit Trail instance they share one horizon, and the fallback is erased by the same purge. **A constituent whose state is a derived index over the same substrate is not an independent source**, and treating it as one would be the more dangerous mistake, since it reads as coverage.

**Capability maps** — derived indexes over the Capability instance's declared read: enumerate the dedicated instance and parse each composed scope (Composition state 23). The binding lives in the constituent's immutable record, so both maps are pure acceleration; the raw token is a field of the constituent's store and of these internal maps, and of no caller-facing surface.

**Session access log** — a derived index over the exercise events and failed exercise events, not a second event stream: an append-only attributed log is what the substrate exists to provide. Within the horizon its durability is the substrate's own; past it the entries are truth-bearing under the same never-delete obligation.

**Request-to-events map** — the declared traversal an auditor walks from a request to the events that prove its arc, which [Read Request] surfaces and Check 6.1 uses. Rebuilt by the same enumerate-and-filter, keyed by each event's request id, and bounded by the horizon: a purge destroys the request id and the action reference with the rest of the payload, leaving the event id and sequence number, so entries for purged events are not rebuildable. There is no second source by construction — without the map the question is a payload-field query the substrate routes to Reverse Index, which is the reason the map exists.

**The audit pending list is the truth-bearing window** (Composition state 31 through 34). A request inside a recovery window — its constituent write committed and its event not yet landed, or its record written ahead of its constituent write — is invisible to the rebuilds for exactly that window, and the durability obligation covers **the pending event's payload, not only the record's own fields**: an exercise's session principal reference and exercised instant exist in no constituent store, and without them a restart could not construct the record it owes. Open entries are **extraction-pending** against a durable **Outbox** *(forthcoming)* owning records owed for committed acts. The list is multi-entry because windows overlap — a failed provisioning record then a failed exercise record in one outage, or two exercises of a multi-use token — and a single slot could not carry the second owed record.

**Three relations** (Composition state 35 through 37). Request to chain: one to one over requests that reached a chain — a request closed inside its initiation window is Withdrawn with a blank chain id and carved out by that state; the request record commits first and the chain follows, so the one directional window is a request briefly chain-less inside its open initiation entry, and an orphan chain is unreachable by construction. Request to capability: one to zero or one, at most one ever; re-access is a new request. Request to audit events: one to many, at least one shape-bearing event per request, every event naming an existing request except the one declared null-request exception. The inverse directions are read through the derived indexes; a lost index entry is a rebuild trigger, never a relation violation.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the default ttl.
Capability requirement 2: IF the default ttl DOES NOT EXCEED zero THEN the composition MUST refuse to start.
Capability requirement 3: A deployment MUST set the max redemptions default.
Capability requirement 4: [Request Access] MUST NOT take a redemption count.
Capability requirement 5: A deployment MUST set the credential type.
Capability requirement 6: The composition MUST pass the credential type to EVERY Credential verify the composition calls.
Capability requirement 7: A deployment MUST set the credential check on request.
Capability requirement 8: A deployment MUST set the approver set minimum.
Capability requirement 9: The composition MUST configure the approval substrate with the approver set minimum.
Capability requirement 10: The retention floor MUST NOT EXCEED the audit horizon.
Capability requirement 11: A deployment MUST set the recording completion bound.
Capability requirement 12: The Capability instance's durability MUST NOT EXCEED the request store's durability.
Capability requirement 13: A deployment MUST NOT purge a request record.
Capability requirement 14: A deployment MUST NOT purge a record of the Capability instance.
Capability requirement 15: A deployment MUST declare the composed-scope encoding.
Capability requirement 16: The composition MUST parse a composed scope back to the request id, the resource reference AND the access scope the composed scope serialized.
Capability requirement 17: A deployment MUST supply the service identity.
Capability requirement 18: A deployment MUST register a caller's credential material in the Credential store AND the audit substrate's actor registry alike.
Capability requirement 19: A deployment MUST set the reference caps.
Capability requirement 20: The host MUST supply a per-request exclusion keyed by request id.
Capability requirement 21: The host MUST release the per-request exclusion on the holder's return.
Capability requirement 22: The host MUST release the per-request exclusion on the holder's death.
Capability requirement 23: The host MUST inject now at the composition's seam once per invocation.
Capability requirement 24: The composition MUST NOT read the clock inside a transition.
Capability requirement 25: An admitted request MUST stamp the requested instant AND compute the expiry instant from one now.
Capability requirement 26: The provisioning cascade MUST compute the remaining ttl from the stored expiry instant AND the invocation's now.
Capability requirement 27: The composition MUST NOT store a clock-derived flag.
Capability requirement 28: The composition MUST NOT compare the composition's now with a constituent's stamp.
Capability requirement 29: The host MUST inject one invocation id per state-changing invocation.
Capability requirement 30: An admitted request MUST take the invocation id as the request id.
Capability requirement 31: The composition MUST NOT mint an id inside a transition.
```

Term default ttl: the time-to-live — the validity duration — a request carries where the requestor supplies none.

Term max redemptions default: the redemption count every allocate passes; 1, a single exercise, where the deployment declares none.

Term credential type: the one Credential type every verify here names — a smart-card deployment names its card type, a password deployment its password type.

Term credential check on request: true | false — whether [Request Access] verifies the requestor's credential; true where the deployment declares none.

Term approver set minimum: the smallest approver set a chain may carry; 2 where the deployment declares none.

Term audit horizon: the retention horizon of the policy the audit substrate is configured with.

Term retention floor: `longest token lifetime + provisioning proof period`.

Term longest token lifetime: the longest time-to-live the deployment admits for a token.

Term provisioning proof period: the period over which the deployment must prove approval-gated provisioning from the trail.

Term recording completion bound: the longest an invocation may take between a committed act and the record that records the act — the redemption leg's lower edge.

Term composed scope: the byte-exact, self-delimiting serialization of the request id, the resource reference and the access scope, in that order, that the composition writes into Capability's opaque scope.

Term service identity: the composition's own actor reference and credential, supplied by the deployment, that attributes every event with no human origin and makes every chain read.

Term reference caps: the length caps on the resource reference, the access scope and each approver reference, derived from every surface the values must fit.

Term per-request exclusion: the host-supplied mutual exclusion keyed by request id.

Term seam: the composition's input and output boundary — the one place the host reads the clock and injects the reading and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

Term invocation id: the fresh id the host injects at the seam for each state-changing invocation, carried on every event and pending entry the invocation writes.

Term remaining ttl: `expiry instant − now`, the time-to-live the cascade passes to allocate.

WHY:
**The redemption count is configuration, not caller input** (Capability requirement 3 and 4): a requestor cannot ask for a multi-use token, and a deployment permitting multi-use privileged access — break-glass, time-boxed windows — raises the value for the instance, which the provisioning event records (Provisioning cascade 8). **The approver set minimum defaults to 2** (Capability requirement 8 and 9): a deployment that wants single-approver privileged access says so, and the chain records it.

**The retention floor is an ordering** (Capability requirement 10): request and Capability records are never deleted while the events binding a token to its approval are purged at the horizon, so the horizon must outlast the longest token plus the proof period. Past it a token is verifiable only to the depth its surviving attestation carries — the provisioning event's action reference, actor and attested instant survive through the destruction record, the payload naming the request does not — which is why Invariant 1, 5, 7 and 9 and Check 1.1, 4.1, 5.1 and 6.1 are stated over the horizon.

**The recording completion bound** (Capability requirement 11) is the lower edge of the one reconciliation leg that runs outside the per-request exclusion's hold: [Exercise Access]'s record write runs after the hold is released, so an entry marked redeemed younger than the bound may belong to an invocation still about to write. The legs that run wholly inside the hold need no bound — a live invocation holds the exclusion and a dead one has released it. A bound shorter than the slowest conforming invocation makes the leg unsafe in the direction that writes.

**Durability is an ordering, and nothing here is ever purged** (Capability requirement 12 through 14). The Capability atom lets a deployment purge terminal records under a retention policy, and this composition's dedicated instance is declared exempt: a purged token record would leave a Provisioned request whose binding parses to nothing, which Check 1.1 would read as a bypass.

**The composed-scope encoding is declared once** (Capability requirement 15 and 16): any unambiguous encoding qualifies, and the declaration is what makes a parse of a serialization mechanical.

**One credential feeds two registries** (Capability requirement 18). A caller's credential is presented to Credential's verify and passed to the substrates' record_action, whose attest checks the actor registry. That one material satisfies both is a deployment fact, now declared rather than assumed; a deployment whose two registries disagree gets a verified caller whose record refuses.

**One now per invocation, for this composition's own stamps and arithmetic** (Capability requirement 23 through 31). One reading serves the requested instant and the expiry instant, so their difference is exactly the requested ttl. It does not extend into the constituents: each constituent call has its own seam, so Session's validity and Capability's lapse are judged against *their* readings. The cascade's remaining ttl is measured here and consumed at Capability's seam, so **the token's deadline is Capability's reading plus the remaining ttl, and it ends within the seam skew of the request's expiry instant, not on it** — a token cannot be handed an absolute expiry, since allocate takes a duration. The composition stores the deadline, never an *expired* flag. The seam injects one invocation id per state-changing invocation, and at [Request Access] that id *is* the request id — one identifier, two names.

### Primitive policy

```
Primitive policy 1: IF an actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the resource reference EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 3: IF the access scope EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 4: IF a reference EXCEEDS the reference's cap THEN the action MUST answer invalid-request.
Primitive policy 5: The composition MUST validate a request's approver set AND quorum rule PER the approval substrate's own chain-shape rules.
Primitive policy 6: IF the constructed event data EXCEEDS the payload budget THEN the action MUST answer invalid-request.
Primitive policy 7: IF a supplied ttl DOES NOT EXCEED zero THEN [Request Access] MUST answer invalid-request.
Primitive policy 8: IF the justification EQUALS blank THEN [Request Access] MUST answer invalid-request.
Primitive policy 9: IF a required reason EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 10: An action refused under Primitive policy 1 through 9 MUST NOT write.
Primitive policy 11: The composition MUST compare an identifier byte-exact.
Primitive policy 12: The composition MUST NOT normalize a string input.
Primitive policy 13: The composition MUST NOT read a credential's content.
Primitive policy 14: The composition MUST NOT write a credential into an audit event.
```

Term payload budget: the audit substrate's payload cap less the event envelope.

WHY:
Primitive policy 5 closes 2026-08-27-h and 2026-08-28-d. The chain shape — the approver set's size against the minimum, its uniqueness where the substrate requires it, each approver reference against its cap, the quorum rule against the allowed set — is the approval substrate's to enforce and is run here *before* the request record is written. A shape error caught at initiate_chain would come after the durable pre-write and leave a permanent Withdrawn record for a caller's typo; caught at intake, it leaves nothing.

Primitive policy 4 and 6 size every value against every surface it must fit: the audit payload (the references travel whole in the request event), the Capability instance's own scope cap less the request id and separator envelope (so a length refusal at the cascade is foreclosed at intake rather than surfacing as a mischaracterized ProvisioningFailed), and the substrate's chain-shape caps. Because every capped value is sized, the check covers the **full constructed event data**, which is what makes record_action's invalid-request unreachable where the wiring says so. The request scopes are composition-fixed vocabulary, never caller input.

Primitive policy 13 and 14: the credential is consumed by Credential's verify and by the substrates' record_action, which attest it inside the substrate; it is never inspected, stored or recorded here, and it is required on every credentialed action because the substrates' signatures require it and nothing else can supply a human caller's credential.

### Action wiring

```
request_access(requestor_ref, credential, resource_ref, access_scope, justification, approver_set, quorum_rule, optional ttl)
  answers request_id
  refuses invalid-request | permission-denied | credential-invalid | recording-failure

approve_step(actor_ref, credential, request_id, step_id, optional reason)
  answers approved
  refuses invalid-request | not-known | not-pending | unauthorized | credential-invalid | recording-failure

reject_step(actor_ref, credential, request_id, step_id, reason)
  answers rejected_outcome
  refuses invalid-request | not-known | not-pending | unauthorized | credential-invalid | recording-failure

withdraw_request(actor_ref, credential, request_id, reason)
  answers withdrawn
  refuses invalid-request | not-known | not-pending | unauthorized | permission-denied | credential-invalid | recording-failure

exercise_access(session_token, capability_token)
  answers exercised
  refuses session-invalid(validation failure) | capability-invalid(exercise failure)

revoke_access(actor_ref, credential, request_id, reason)
  answers revoked
  refuses invalid-request | not-known | not-provisioned | credential-invalid | permission-denied | recording-failure

read_request(actor_ref, query)
  answers request results
  refuses permission-denied | invalid-query
```

Term validation failure: expired | revoked | not-known — Session's reasons for an invalid session.

Term exercise failure: exhausted | expired | revoked | not-known | recording-failure — Capability's redemption failure, or an exercise entry the store refused.

Term request results: the requests a query matches, each carrying the request record's fields, the chain's state, the token's effective status and the request's event ids, in declared order.

```
Action wiring 1: A credentialed action MUST call Credential's verify with the actor reference, the credential type AND the credential.
Action wiring 2: A credentialed action MUST NOT resolve the request BEFORE Credential's verify answers verified.
Action wiring 3: IF Credential's verify answers failed-verification THEN the action MUST answer credential-invalid.
Action wiring 4: A credentialed action MUST NOT answer not-known BEFORE rebuilding the request record.
Action wiring 5: IF a credentialed action's request id names no request record THEN the action MUST answer not-known.
Action wiring 6: IF the action's load-bearing act committed THEN the action MUST answer the action's success.
Action wiring 7: IF Audit Trail refuses the record following a committed load-bearing act THEN the action MUST open a pending entry carrying the record.
Action wiring 8: The composition MUST write an index entry ONLY AFTER the record the index entry derives from lands.
Action wiring 9: A failed index write MUST NOT change an action's answer.
Action wiring 10: A validated request MUST call Permissions' permitted with the requestor reference AND requests initiate.
Action wiring 11: IF Permissions answers denied THEN the action MUST answer permission-denied.
Action wiring 12: IF the credential check on request EQUALS true THEN [Request Access] MUST call Credential's verify with the requestor reference, the credential type AND the credential.
Action wiring 13: An admitted request MUST write the request record carrying Pending AND an initiation entry.
Action wiring 14: An admitted request MUST NOT call Multi-Party Approval's initiate chain BEFORE the request record lands.
Action wiring 15: IF the request store refuses the request record THEN [Request Access] MUST answer recording-failure.
Action wiring 16: An admitted request MUST call Multi-Party Approval's initiate chain with the requestor reference, the credential, the request id, the access scope, the approver set AND the quorum rule.
Action wiring 17: IF initiate chain answers the chain id THEN [Request Access] MUST write the chain id onto the request record under the per-request exclusion.
Action wiring 18: IF initiate chain answers the chain id THEN [Request Access] MUST complete the initiation entry's payload with the chain id.
Action wiring 19: IF initiate chain refuses THEN [Request Access] MUST record an initiation-failed withdrawal event carrying the request shape AND the mapped refusal as the reason.
Action wiring 20: IF initiate chain refuses THEN [Request Access] MUST set the request state to Withdrawn.
Action wiring 21: IF initiate chain refuses THEN [Request Access] MUST close the initiation entry.
Action wiring 22: IF initiate chain answers invalid-request THEN [Request Access] MUST answer invalid-request.
Action wiring 23: IF initiate chain answers invalid-credential THEN [Request Access] MUST answer credential-invalid.
Action wiring 24: IF initiate chain answers permission-denied THEN [Request Access] MUST answer permission-denied.
Action wiring 25: IF initiate chain answers recording-failure THEN [Request Access] MUST answer recording-failure.
Action wiring 26: The deployment MUST alert on a substrate permission-denied as a wiring fault.
Action wiring 27: An admitted request MUST record the request event ONLY AFTER the chain id lands on the request record.
Action wiring 28: IF the request event lands THEN [Request Access] MUST close the initiation entry.
Action wiring 29: IF Audit Trail refuses the request event THEN [Request Access] MUST leave the initiation entry open.
Action wiring 30: [Request Access] MUST answer the request id ONLY AFTER the chain id lands on the request record.
Action wiring 31: IF the request's chain id EQUALS blank THEN a decision action MUST answer not-pending.
Action wiring 32: [Approve Step] MUST call Multi-Party Approval's approve step with the actor reference, the credential, the chain id, the step id AND the reason.
Action wiring 33: [Reject Step] MUST call Multi-Party Approval's reject step with the actor reference, the credential, the chain id, the step id AND the reason.
Action wiring 34: IF the approval substrate answers invalid-request, not-known, not-pending OR unauthorized to a decision THEN the decision action MUST answer the substrate's refusal.
Action wiring 35: IF the approval substrate answers invalid-credential to a decision THEN the decision action MUST answer credential-invalid.
Action wiring 36: IF the approval substrate answers recording-failure to a decision THEN the decision action MUST answer recording-failure.
Action wiring 37: IF the approval substrate answers invalid-credential OR recording-failure to a decision THEN the decision action MUST open an evaluation entry.
Action wiring 38: IF the approval substrate answers not-pending to a decision THEN the decision action MUST run the chain evaluation.
Action wiring 39: A decision action MUST record a decision event carrying the request id, the chain id, the step id, the decision AND the reason ONLY AFTER the approval substrate answers the decision.
Action wiring 40: A decision action MUST run the chain evaluation ONLY AFTER the approval substrate answers the decision.
Action wiring 41: A decision action MUST answer the decision ONLY AFTER the approval substrate answers the decision.
Action wiring 42: The chain evaluation MUST run under the per-request exclusion.
Action wiring 43: The chain evaluation MUST read the chain through Multi-Party Approval's read chain with a query on the chain id.
Action wiring 44: IF read chain answers permission-denied OR invalid-query OR an empty result THEN the chain evaluation MUST open an evaluation entry.
Action wiring 45: The deployment MUST alert on a read chain refusal inside the chain evaluation as a wiring fault.
Action wiring 46: A read chain refusal MUST NOT change the decision action's answer.
Action wiring 47: IF the chain's state EQUALS Approved AND the provisioning conjunction holds THEN the chain evaluation MUST set the request state to Approved.
Action wiring 48: IF the chain's state EQUALS Approved AND the provisioning conjunction holds THEN the chain evaluation MUST fire the provisioning cascade.
Action wiring 49: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST read the chain's terminal event.
Action wiring 50: The chain evaluation MUST find the chain's terminal event by reading the chain's event ids from the tail to the first event whose action reference IS IN the terminal chain actions.
Action wiring 51: IF Audit Trail's read record answers not-known OR the terminal event's reason is destroyed THEN the chain evaluation MUST take blank as the denial reason.
Action wiring 52: IF the denial reason EQUALS blank THEN the chain evaluation MUST open a denial-reason entry.
Action wiring 53: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST record a denial event carrying Denied AND the denial reason under the service identity.
Action wiring 54: IF the chain's state EQUALS Rejected AND the request state EQUALS Pending THEN the chain evaluation MUST set the request state to Denied.
Action wiring 55: IF the chain's state EQUALS Withdrawn AND the request state EQUALS Pending THEN the chain evaluation MUST record a withdrawal event carrying Withdrawn AND the terminal event's reason under the service identity.
Action wiring 56: IF the chain's state EQUALS Withdrawn AND the request state EQUALS Pending THEN the chain evaluation MUST set the request state to Withdrawn.
Action wiring 57: IF the chain's state EQUALS Pending THEN the chain evaluation MUST NOT write.
Action wiring 58: IF the request state IS IN the terminal request states THEN the chain evaluation MUST NOT write.
Action wiring 59: IF the request's requestor reference DOES NOT EQUAL the actor reference THEN [Withdraw Request] MUST answer unauthorized.
Action wiring 60: IF the request state DOES NOT EQUAL Pending THEN [Withdraw Request] MUST answer not-pending.
Action wiring 61: IF the request's chain id EQUALS blank THEN [Withdraw Request] MUST answer not-pending.
Action wiring 62: [Withdraw Request] MUST NOT call Permissions' permitted.
Action wiring 63: An admitted withdrawal MUST call Multi-Party Approval's withdraw chain with the actor reference, the credential, the chain id AND the reason under the per-request exclusion.
Action wiring 64: IF withdraw chain answers not-pending THEN [Withdraw Request] MUST run the chain evaluation.
Action wiring 65: IF withdraw chain answers not-pending THEN [Withdraw Request] MUST answer not-pending.
Action wiring 66: IF withdraw chain answers permission-denied THEN [Withdraw Request] MUST answer permission-denied.
Action wiring 67: IF withdraw chain answers unauthorized OR not-known THEN [Withdraw Request] MUST answer recording-failure.
Action wiring 68: IF withdraw chain answers unauthorized OR not-known THEN the deployment MUST alert on the answer as a conformance fault.
Action wiring 69: IF withdraw chain answers invalid-credential THEN [Withdraw Request] MUST answer credential-invalid.
Action wiring 70: IF withdraw chain answers invalid-request THEN [Withdraw Request] MUST answer invalid-request.
Action wiring 71: IF withdraw chain answers recording-failure THEN [Withdraw Request] MUST answer recording-failure.
Action wiring 72: An admitted withdrawal MUST record a withdrawal event carrying Withdrawn AND the reason ONLY AFTER withdraw chain answers withdrawn.
Action wiring 73: An admitted withdrawal MUST set the request state to Withdrawn ONLY AFTER withdraw chain answers withdrawn.
Action wiring 74: An admitted withdrawal MUST answer withdrawn ONLY AFTER withdraw chain answers withdrawn.
Action wiring 75: [Exercise Access] MUST NOT call a Capability action BEFORE Session's validate answers valid.
Action wiring 76: IF Session's validate answers invalid THEN [Exercise Access] MUST answer session-invalid carrying the validation failure.
Action wiring 77: IF Session's validate answers invalid THEN [Exercise Access] MUST NOT write.
Action wiring 78: A validated exercise MUST resolve the token's request through Capability's read filtered on the capability token.
Action wiring 79: IF Capability's read finds no record for the token THEN [Exercise Access] MUST NOT call Capability's redeem.
Action wiring 80: IF Capability's read finds no record for the token THEN [Exercise Access] MUST answer capability-invalid carrying not-known.
Action wiring 81: IF Capability's read finds no record for the token THEN [Exercise Access] MUST record a failed exercise event carrying blank as the request id.
Action wiring 82: A resolved exercise MUST open an exercise entry carrying the session principal reference AND the exercised instant.
Action wiring 83: A resolved exercise MUST NOT call Capability's redeem BEFORE the exercise entry lands.
Action wiring 84: IF the request store refuses the exercise entry THEN [Exercise Access] MUST answer capability-invalid carrying recording-failure.
Action wiring 85: A resolved exercise MUST call Capability's redeem under the per-request exclusion the exercise entry was opened under.
Action wiring 86: IF Capability's redeem answers redeemed THEN [Exercise Access] MUST mark the exercise entry redeemed under the same per-request exclusion.
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
Action wiring 100: IF Capability's revoke answers storage-failure THEN [Revoke Access] MUST answer recording-failure.
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

Term initiation entry: the pending entry [Request Access] writes with the request record, carrying the request event's payload less the chain id until initiate_chain answers.

Term evaluation entry: the pending entry recording a chain evaluation owed after a committed decision.

Term denial-reason entry: the pending entry recording a denial event that landed with a blank denial reason.

Term exercise entry: the pending entry an exercise writes before redeem, carrying the exercise's payload; marked redeemed once a use is consumed.

Term resolved exercise: an [Exercise Access] whose session validated and whose token Capability's read found.

Term chain evaluation: the read of a request's chain and the transition, record and cascade the chain's state calls for.

Term provisioning conjunction: the request state IS IN the open request states, no token in the Capability instance parses to the request, and no pending entry owing a provisioning-failure event is open.

Term terminal chain action: chain_resolved | chain_withdrawn — the substrate's records of a chain reaching a terminal state.

Term requests initiate: the scope admitting [Request Access] — a [Requests Initiate].

Term requests revoke: the scope admitting [Revoke Access] — a [Requests Revoke].

Term requests read: the scope admitting [Read Request] — a [Requests Read].

WHY:
**Two standing rules govern every action** (Action wiring 6 through 9). *Truth order*: the constituent act commits first, the audit event carrying the resulting state records second, and the maps are derived-index writes outside the atomicity surface — a failed map write is a rebuild trigger, never a failure arm. *Committed acts are never answered as failures*: where a record fails after the load-bearing act committed, the action answers its success, the request carries an open pending entry, and the record catches up — the alternative teaches callers to retry acts that already happened, which for a redemption would consume a second use.

**Credential first, then the request** (Action wiring 1 through 5). A credential that fails verify is [Credential Invalid]; a missing request scope is [Permission Denied]. A credentialed action verifies the caller before it resolves anything, so not-known, not-pending and not-provisioned are answered only to an authenticated caller, and [Withdraw Request] answers unauthorized before it reads the request's state (Action wiring 59 and 60): the existence and state oracle an unauthenticated caller had is closed, and what an authenticated caller learns is the residual stated in Non-goal 15. **Credential's verify and the substrate's attest are two checks against two registries** — Credential's store and the actor registry — which is why both run (Capability requirement 18); and an approver revoked between initiation and decision fails verify and cannot decide. The chain remains in flight and the revoked approver's step stays pending; the chain can be withdrawn and initiated again with a replacement approver.

**[Request Access] writes the request before the chain** (Action wiring 13 through 30). The pre-write keeps the chain from ever being an orphan: a crash after the chain commits would otherwise leave a live Pending chain with active approver Assignments whose subject resolves to nothing — invisible to every rebuild and withdrawable by no one, since withdrawal is initiator-only. The record is truth-bearing for exactly this window, the initiation entry holding the request event's payload. From the instant initiate_chain answers, the chain id is written onto the record, so a live approver resolving the chain from the record finds it even if the request event never lands. A refused initiate_chain **closes** the pre-written record rather than discarding it — the record is immutable and the store forward-only — with an initiation-failed withdrawal event carrying the whole request shape, since it is the only event that request will ever have. A substrate permission-denied means the requestor holds requests initiate and lacks chains initiate: a wiring fault to alert on, surfaced honestly either way. The request event's own failure leaves the initiation entry open and the request id answered — the chain is live and approvers hold in-tray items, so failing the caller would orphan it.

**A decision is committed the moment the substrate answers it** (Action wiring 31 through 41). The decision event is this composition's record keyed by request id, which is what puts the decision in the request's traversal; the substrate's own step event is keyed by chain. A not-pending from the substrate still runs the evaluation — a chain already terminal against a Pending request is a decision whose invocation died between its substrate commit and its evaluation, and the retry is what completes it. A substrate invalid-credential or recording-failure over what may be a committed decision opens an evaluation entry, so the reconciliation's legs run the evaluation the refused call skipped (Action wiring 37) — the third path to approval-without-token the prose left open.

**The chain evaluation** (Action wiring 42 through 58) runs under the per-request exclusion, which is what makes its guard a decision rather than a race. **The provisioning conjunction is the guard, not the request state alone**: the Approved transient maps to no event, so a request store lost and rebuilt between an allocation and its provisioning event shows Pending, and a guard trusting the state would allocate a second token for one request — the defect the token-existence conjunct forecloses. A read_chain refusal is a wiring or conformance fault, never this caller's answer: the decision committed, so the action alerts, opens an evaluation entry, and answers the decision. **The chain record does not carry a terminal reason**: it lives in the chain's terminal event, found by walking the chain's event ids from the tail to the first chain_resolved or chain_withdrawn — the tail can be a trailing step event, not the terminal one. A read that answers not-known, or a payload past the horizon, lands the denial with a blank reason and a denial-reason entry: the denial is a fact the chain has established, and withholding the transition because its *narration* could not be fetched would trade a missing field for a stuck request. A chain found Withdrawn under a Pending request was withdrawn by a concurrent [Withdraw Request] that had not finished recording; the evaluation records the withdrawal as the composition, the withdrawing human not being present in this invocation, and it is idempotent with the concurrent path under the exclusion. Rejected under an Approved request is unreachable — the chain is terminal-stable — and has no arm.

**Withdrawal is the requestor's own act** (Action wiring 59 through 74): the chain admits withdrawal only from its initiator, who is the requestor by construction, so no non-requestor path exists to promise, and no composition-layer Permissions check runs — the substrate's chains withdraw gate is the permission surface. A not-pending from the substrate means the chain reached a terminal concurrently; the evaluation runs here and now, **and where the chain was Approved it can fire the cascade and deliver a token inside a call that answers not-pending** — the caller's withdrawal lost the race to a real outcome, and [Read Request] tells the caller which one.

**[Exercise Access] gates on the session, then writes the intent, then redeems** (Action wiring 75 through 94). Session first: a session that does not validate refuses the exercise before the Capability is touched, and nothing is recorded — the substrate cannot attribute an event to a session that does not validate, and a **Failed-Attempt Log** *(forthcoming)* owns pre-authentication attempt auditing. The token resolves through Capability's read filtered on the token, not through the capability-to-request map with rebuild on miss, which was a full enumeration per forged presentation; a token the read cannot find was never allocated here, so redeem is not called and the attempt is recorded with no request. For a resolved token, the exercise entry is written before redeem and the exclusion held through redeem's answer and the mark, so at most one unmarked exercise entry is open per request — which is what makes the redemption leg decidable. A redemption is committed and irreversible, and every path from it answers exercised; a dead token answered invalid is an auditable event, its failed exercise record carrying who presented it. **An exercise is not gated on the request state** (Action wiring 94): in the window between an allocation and its provisioning event, a delivered token is lawful access, and its exercise event may precede the provisioning event in the trail; the arc reads the allocation from the Capability record, and refusing the access because the *record* of its grant was late would refuse what was lawfully granted.

**[Revoke Access]** (Action wiring 95 through 103): already-terminal means the token is already dead — exhausted, lapsed or revoked by another path — and the request-level revocation record still serves the audit, so the action proceeds. A not-known after a rebuild is a conformance fault: the Capability store lacks a token its own scope parse produced.

**[Read Request] is a pure projection** (Action wiring 104 through 112): no state change, no event, no credential, and no existence-hiding fork — a deployment wanting that posture builds it in its calling layer. A chain-less request has no chain to read, and a chain read that refuses leaves the result standing with its chain state unavailable rather than failing the whole query. A lapsed token honestly reads Expired through Capability's derived effective status.

### Wiring decision

```
Wiring decision 1: The composition MUST provision privileged access as a Capability token.
Wiring decision 2: The composition MUST NOT provision privileged access as a Permissions grant.
Wiring decision 3: The composition MUST NOT call Capability's allocate outside the provisioning cascade.
Wiring decision 4: The composition MUST NOT expose a provisioning action.
Wiring decision 5: The composition MUST NOT call Permissions' permitted on a deciding actor.
Wiring decision 6: The composition MUST NOT check a bearer's identity at redemption.
```

WHY:
**Privileged access is provisioned as a Capability token, allocated only by the approval-gated cascade — never as a Permissions grant flipped on approval.**

*Principle.* Privileged access is temporary authorization: what the regulators' findings condemn is standing access that outlives its business need. An artifact that expires structurally — a token with an immutable deadline, refused by its own atom after lapse with nothing written — makes the time bound a property of the record rather than a clean-up job someone must remember.

*Likely objection.* A grant flipped on approval is simpler — identity-keyed, revocable, queryable, and already composed here for the request gates. Why a bearer token and a second gate at exercise time?

*Mechanism.* A grant stands until someone revokes it — exactly the failure mode; its revocation is an act someone must perform, where the token's expiry is a derivation nobody can forget (Wiring decision 1 and 2). **The bearer property is load-bearing, not incidental** (Wiring decision 6): break-glass and automated executors exercise access without carrying the requestor's identity, and the identity regulated audit needs at exercise time is re-bound by this composition's session gate — Session's validate first, its principal in the exercise record — not by the token. The token never knows its bearer; the exercise record names the session's authenticated principal at the moment of presentation. And the cascade is the only allocation path (Wiring decision 3 and 4): allocate is called at exactly one step, fired only by a chain the substrate reports Approved, with the binding written into the token's own immutable scope; an implementation offering a provisioning path outside the cascade violates Invariant 1. **Approvers are authorized by the approver set, not by a grant** (Wiring decision 5): the substrate refuses any decision from an actor outside the step's approver set, and a Permissions check here would enforce one rule through two mechanisms with two failure modes.

*Result.* Every provisioned access traces to a documented, quorum-satisfied approval, recomputable from records; every exercise is session-gated and principal-attributed; expiry needs no janitor; and a leaked trail grants nothing, because no record carries the bearer material.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST retry EVERY open pending entry on EVERY run.
Reconciliation 3: The reconciliation MUST run EVERY leg under the per-request exclusion.
Reconciliation 4: The reconciliation MUST NOT emit a record BEFORE reading the trail for an event carrying the record's action reference AND invocation id.
Reconciliation 5: IF the pre-check finds the event THEN the reconciliation MUST close the entry.
Reconciliation 6: IF the pre-check finds the event THEN the reconciliation MUST NOT emit the record.
Reconciliation 7: IF an entry carries no invocation id THEN the reconciliation MUST pair the entry by the entry's request id, action reference, exercised instant AND session principal reference.
Reconciliation 8: IF the pairing count EXCEEDS one THEN the reconciliation MUST NOT emit the record.
Reconciliation 9: The redemption leg MUST NOT examine an exercise entry younger than the recording completion bound.
Reconciliation 10: The reconciliation MUST NOT write for an aged event.
Reconciliation 11: The reconciliation MUST attest EVERY write under the service identity.
Reconciliation 12: A leg MUST NOT commit constituent state BEFORE the leg's recovery intent lands.
Reconciliation 13: A leg MUST NOT record a state-transition event BEFORE the leg's recovery intent lands.
Reconciliation 14: A recovery intent MUST carry the invocation id, the request id, the leg AND the plan.
Reconciliation 15: A recovery record MUST carry the owed record's action reference, the owed record's data AND the owed record's invocation id.
Reconciliation 16: The reconciliation MUST NOT take a recovery record's data from a composition index.
Reconciliation 17: The token leg MUST parse the composed scope of EVERY record in the Capability instance.
Reconciliation 18: IF a token's request state IS NOT IN the provisioned states THEN the token leg MUST record the token's provisioning event.
Reconciliation 19: IF a token's request state IS NOT IN the provisioned states THEN the token leg MUST set the request state to Provisioned.
Reconciliation 20: The token leg MUST NOT call Capability's allocate.
Reconciliation 21: The approval leg MUST run the chain evaluation for EVERY request in an open request state whose chain's state EQUALS Approved.
Reconciliation 22: IF the request state IS IN the open request states AND the chain's state IS IN the refusing chain states THEN the terminal-chain leg MUST run the chain evaluation.
Reconciliation 23: The terminal-chain leg MUST land a recovery record for EVERY step decision in the chain's events that no decision event names.
Reconciliation 24: The redemption leg MUST land a recovery record for the exercise event of EVERY exercise entry marked redeemed.
Reconciliation 25: IF the redemption gap EQUALS one THEN the redemption leg MUST mark the unmarked exercise entry redeemed.
Reconciliation 26: IF the redemption gap EQUALS one THEN the redemption leg MUST land a recovery record for the unmarked exercise entry's exercise event.
Reconciliation 27: IF the redemption gap EQUALS zero THEN the redemption leg MUST clear the unmarked exercise entry.
Reconciliation 28: IF the redemption gap IS NOT IN the settled gaps THEN the redemption leg MUST report a conformance finding.
Reconciliation 29: The redemption leg MUST land a recovery record for the failed exercise event of EVERY open exercise entry carrying a redemption failure.
Reconciliation 30: IF the request record carries no chain id THEN the initiation leg MUST read the approval substrate for a chain whose subject reference EQUALS the request id.
Reconciliation 31: IF the initiation leg finds the chain AND the request state EQUALS Pending THEN the initiation leg MUST write the chain id onto the request record.
Reconciliation 32: IF the initiation leg finds the chain AND the request state EQUALS Pending THEN the initiation leg MUST land a recovery record for the request event.
Reconciliation 33: IF the initiation leg finds no chain THEN the initiation leg MUST record an initiation-failed withdrawal event carrying the request shape.
Reconciliation 34: IF the initiation leg finds no chain THEN the initiation leg MUST set the request state to Withdrawn.
Reconciliation 35: IF the initiation leg finds the chain AND the request state EQUALS Withdrawn THEN the initiation leg MUST close the initiation entry.
Reconciliation 36: IF the initiation leg finds the chain AND the request state EQUALS Withdrawn THEN the initiation leg MUST report the live chain as a finding.
Reconciliation 37: IF the initiation leg finds the chain AND the request state EQUALS Withdrawn THEN the initiation leg MUST NOT land a request event.
Reconciliation 38: The denial-reason leg MUST read the chain's terminal event for EVERY open denial-reason entry.
Reconciliation 39: IF the read answers the terminal event's reason THEN the denial-reason leg MUST land a recovery record for the denial event carrying the reason.
Reconciliation 40: IF Audit Trail's read record answers not-known OR the terminal event's reason is destroyed THEN the denial-reason leg MUST close the denial-reason entry.
Reconciliation 41: The denial-reason leg MUST NOT record a second denial event.
```

Term reconciliation: the leg this composition runs outside every invocation whose output — a landed record, a finished provisioning, a closed request — a requestor or an auditor awaits: the token leg, the approval leg, the terminal-chain leg, the redemption leg, the initiation leg and the denial-reason leg, at every start and on every retry.

Term recovery intent: the access_recovery_intended event — the reconciliation's record that the act following it was occasioned by the reconciliation and not by a direct call.

Term recovery record: the access_audit_recovery event — the composition's record standing in for an owed record whose actor is absent.

Term pairing count: the count of events pairing with an entry by the entry's payload fields.

Term provisioned state: Provisioned | Revoked.

Term refusing chain state: Rejected | Withdrawn.

Term consumed count: `max redemptions − remaining redemptions` for one token, read through Capability's read.

Term exercised count: the request's exercise events plus the request's exercise entries marked redeemed.

Term redemption gap: `consumed count − exercised count`.

Term settled gap: zero | one.

WHY:
**The compensation story is completion, not undo, and it is one reconciliation with a leg per window.** Each crash window has a reachable detector, and none relies on a later decision call — under all-of-N every step is terminal the moment the chain resolves Approved, and no later call reaches the evaluation; a Rejected chain can leave trailing Pending steps, but no call on them re-runs the request's evaluation either.

**The token leg** (Reconciliation 17 through 20) finds a token whose request never reached Provisioned — a crash between the allocation and the provisioning event. Nothing needs revoking: the chain was Approved, so the allocation is lawful, and the leg *finishes*. It is the check the breach-forensics scenario runs from outside, used from inside as the detector.

**The approval leg** (Reconciliation 21) finds a request non-terminal against an Approved chain with no token — a crash before the allocation, or before the evaluation transitioned the request at all — and runs the live evaluation, so the cascade fires on the same provisioning conjunction, so the re-fire is single; a request whose allocation failed and whose record is still pending carries the open provisioning-failure entry the conjunction excludes.

**The terminal-chain leg** (Reconciliation 22 and 23) catches a decision whose invocation died between its substrate commit and its evaluation: no entry opened there, because the decision action opens one only on a *returned* failure, and without the leg such a request sat Pending forever against a chain that had already refused it. It also lands the dead decision's missing decision event, its data read from the substrate's own step event.

**The redemption leg** (Reconciliation 24 through 29) counts. Several exercise entries may stand on one request — those marked redeemed, each a committed use whose record is owed, and at most one unmarked, because the exercise holds the exclusion from the entry through redeem and the mark. Every marked entry's record is owed regardless of the count. The unmarked one is attributed by the redemption gap against the Capability record's own counter: one means its redemption committed and the mark was lost with the crash; zero means the crash preceded the redemption and nothing is owed; anything else is a finding. Failed presentations consumed nothing and are not in the count, but their records are owed all the same.

**The initiation leg** (Reconciliation 30 through 37) probes the substrate for every open initiation entry — by the stored chain id, or, where the crash preceded that write, by a read on the subject reference under the service identity's chains read. A chain found means the initiation committed, and the request event lands; no chain means the initiation died before the substrate write, and the request closes Withdrawn — nothing was promised, the caller never received the id. **A chain found under a request already Withdrawn** (2026-08-27-p) is the substrate's recording-failure arm: initiate_chain may commit the chain and still answer the failure, [Request Access] closed the request, and the crash came before the entry closed. The leg closes the entry and lands no request event — the request's whole record is its withdrawal — and reports the live chain: its approvers hold in-tray items, but provisioning can never fire, since the request is terminal.

**The denial-reason leg** (Reconciliation 38 through 41) retries the one thing a blank-reason denial is missing. A reason read at last lands as a recovery record for the denial event carrying it, which the rebuild reads as the denial; a reason the horizon has destroyed is final, and the entry closes. It never records a second denial event.

**Four rules govern every leg, stated once.** *(1) Pre-check before emitting* (Reconciliation 4 through 8): every leg detects on rebuilt state and **the absence of the event**, never on an index alone; record_action is not idempotent, so a leg trusting a stale index re-emitted duplicates. The pairing is by invocation id, which is exact; an entry predating the field pairs by its payload and lands nothing while more than one event matches. *(2) The lower edge* (Reconciliation 9 and 10): only the redemption leg runs over a window that opens outside the exclusion's hold; every leg's upper edge is the audit horizon, past which an absent event is destruction and the request record's truth-bearing half is the answer. *(3) As the composition, behind a recovery intent* (Reconciliation 11 through 15): the original actor is not present, so every write is attested under the service identity, every commit or transition the leg makes is preceded by a recovery intent naming what it is about to do, and a recovery record stands in for the original it names. *(4) Re-derive, never remember* (Reconciliation 16): what a recovery record carries comes from the entry's payload, the constituent stores or the substrate's own events — never from an index — and where the entry's payload is the only source, a lost entry is a finding, not something the leg reconstructs.

The reconciliation declares no window of its own and no cadence knob: it runs at every start and retries every open entry until each closes, and the open state is never silent — [Read Request] surfaces the audit pending list, and the auditor's closure procedure is Check 6.1 through 6.4.

### Scope vocabulary

```
Scope vocabulary 1: The composition MUST define requests initiate, requests revoke AND requests read for the Permissions instance.
Scope vocabulary 2: The composition MUST NOT define a withdraw scope.
```

WHY:
There is deliberately no withdraw scope (Scope vocabulary 2): [Withdraw Request] is the requestor's own act, and a third-party grant would promise a path the substrate refuses (Non-goal 10).

### Provisioning cascade

```
Provisioning cascade 1: The provisioning cascade MUST run under the per-request exclusion.
Provisioning cascade 2: The provisioning cascade MUST call Capability's allocate with the service identity, the composed scope, the max redemptions default AND the remaining ttl.
Provisioning cascade 3: IF Capability's allocate refuses THEN the provisioning cascade MUST open a pending entry carrying the provisioning-failure event.
Provisioning cascade 4: IF Capability's allocate refuses THEN the provisioning cascade MUST record a provisioning-failure event carrying ProvisioningFailed AND the denial reason under the service identity.
Provisioning cascade 5: IF Capability's allocate refuses THEN the provisioning cascade MUST set the request state to ProvisioningFailed.
Provisioning cascade 6: IF Capability's allocate answers invalid-request AND the remaining ttl DOES NOT EXCEED zero THEN the denial reason MUST read ttl-elapsed.
Provisioning cascade 7: IF Capability's allocate refuses for another cause THEN the denial reason MUST carry the relayed refusal.
Provisioning cascade 8: The provisioning cascade MUST record a provisioning event carrying the request id, the requestor reference, the resource reference, the access scope, the max redemptions, the expiry instant AND Provisioned ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 9: A provisioning event MUST NOT carry the capability token.
Provisioning cascade 10: The provisioning cascade MUST set the request state to Provisioned ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 11: The provisioning cascade MUST deliver the capability token to the requestor through the delivery channel ONLY AFTER Capability's allocate answers the capability token.
Provisioning cascade 12: The composition MUST NOT carry the capability token on a surface other than the delivery channel.
```

Term provisioning cascade: the internal leg the chain evaluation fires on an Approved chain — allocate, record, deliver; no caller invokes it.

Term delivery channel: the deployment's channel carrying a provisioned token to the requestor — the only surface the raw token crosses.

WHY:
The cascade's expiry guard is structural rather than clock-branched (Provisioning cascade 6): a request approved after its expiry instant yields a non-positive remaining ttl, which Capability's own validation refuses, and the request lands ProvisioningFailed with ttl-elapsed. In both refusal arms the decision action's caller still receives the decision — the decision committed; the failure is the request's, surfaced in its state and the deployment's alerts. A failed provisioning event after a committed allocation opens its entry and the token is still delivered, because the access lawfully exists (Action wiring 7). The provisioning event carries the max redemptions and the expiry instant (Provisioning cascade 8), so the record reflects the configuration it was allocated under; it never carries the token.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Approval gates provisioning (within the audit horizon).**
  ```
  Invariant 1.1: EVERY token in the Capability instance MUST parse to a request whose chain's state EQUALS Approved.
  Invariant 1.2: The composition MUST fire the provisioning cascade ONLY IF the approval substrate reports the chain Approved.
  ```
  WHY: recomputable by any reader from the chain and step records under the substrate's own quorum determinism **while those records' payloads survive**; past the horizon the token's request record, its Provisioned state and the surviving provisioning attestation are the evidence, and a token older than the horizon is a horizon finding against the deployment's ordering (Capability requirement 10), not a bypass. A token whose scope names an un-Approved chain, parses to no request, or does not parse is evidence of a provisioning bypass — a critical control failure. *Rests on* the cascade's sole-path construction (Wiring decision 3 and 4), the evaluation's guard, the composed scope, and the substrate's quorum determinism.
- **Invariant 2 — Request and capability, one to at most one.**
  ```
  Invariant 2.1: A request MUST NOT acquire two capability tokens across the lifetime of the system.
  Invariant 2.2: The composition MUST NOT fire the provisioning cascade for a request the provisioning conjunction fails for.
  ```
  WHY: re-access requires a new request and a new chain. The defense is named, not assumed: the evaluation is serialized per request (Action wiring 42), so two decisions cannot both observe Pending and both fire; the guard is the provisioning conjunction, not the request state alone, since the Approved transient rebuilds to Pending; and the crash window between the allocation and its record is the token leg's, which finishes and never allocates again (Reconciliation 20).
- **Invariant 3 — Session-gated exercise.**
  ```
  Invariant 3.1: EVERY exercise event MUST follow a Session validate answering valid in the same invocation.
  Invariant 3.2: An exercise event MUST carry the principal reference the invocation's validate answered as the session principal reference.
  ```
  WHY: no token is redeemed through this composition's surface without the session gate passing first (Action wiring 75).
- **Invariant 4 — Cascading revocation (conditional on the wired session-issuance surface).**
  ```
  Invariant 4.1: IF the deployment wires a credential-to-session revocation cascade THEN an exercise under a session derived from a revoked credential MUST answer session-invalid.
  ```
  WHY: where the deployment wires Login, or an issuance surface honouring the same cascade, revoking a principal's credential closes the exercise surface end to end with no action on the request or the token: Credential's revoke makes the credential terminal, Login's peer action revoking the sessions derived from it moves each to a terminal state, and the next exercise meets session-invalid at the gate, before the token is presented. **The condition is honest, not decorative**: Login is a peer, not a constituent, and a deployment issuing sessions through a surface with no such cascade does not get this invariant — the gate still refuses whatever the Session store calls terminal, but nothing here makes the credential's revocation *reach* the sessions. The chain spans Credential, Login's cascade, Session and this composition's gate, and is expressible at no single layer. A deployment wanting the *token* dead at once wires [Revoke Access] to a listener (Non-goal 7).
- **Invariant 5 — Audit-arc completeness (at quiescence, within the audit horizon).**
  ```
  Invariant 5.1: EVERY request MUST carry a shape-bearing event at quiescence.
  Invariant 5.2: EVERY request record MUST carry the state the request's latest state-transition event carries at quiescence.
  Invariant 5.3: EVERY consumed redemption MUST carry an exercise event at quiescence.
  Invariant 5.4: EVERY redemption failure a resolved exercise reached MUST carry a failed exercise event at quiescence.
  ```
  WHY: a recovery record stands in for the event it names. One exception is declared: a failed presentation of a token that resolves to no request, whose record failed, has no request to carry an entry — the loss bounded to never-allocated material presented during an audit outage, which consumed and granted nothing. The session access log agrees with the exercise events by construction, being a derived index over them. Inside a recovery window the gap is open but never silent: the entry is set, [Read Request] surfaces it, and the reconciliation closes it. An auditor reconstructs the full arc from the trail alone, through the request-to-events map.
- **Invariant 6 — Approver-credential completeness (through this composition's surface).**
  ```
  Invariant 6.1: EVERY decision a decision action routes MUST follow a Credential verify answering verified for the deciding actor.
  ```
  WHY: no decision this composition routed is attributed to an actor whose credential did not verify at decision time. The qualifier is the honest scope: a decision written into the substrate around this composition is the substrate's business.
- **Invariant 7 — Denial completeness (at quiescence, within the audit horizon).**
  ```
  Invariant 7.1: EVERY Denied request MUST carry a denial event at quiescence.
  Invariant 7.2: EVERY Denied request MUST name a chain whose state EQUALS Rejected.
  Invariant 7.3: EVERY ProvisioningFailed request MUST carry a provisioning-failure event carrying the relayed reason at quiescence.
  ```
  WHY: a denial event's reason may be blank — the landing for a terminal event that could not be read (Action wiring 51) — and the denial-reason entry is what tells it from one never recorded; the reason is not a field of the chain record, so it is subject to that read's availability and, past the horizon, to the payload's. An auditor determines from the records alone which requests were refused, by which quorum failure or provisioning fault, and when.
- **Invariant 8 — Immutable request identity.**
  ```
  Invariant 8.1: The composition MUST NOT change a request's identity fields once written.
  Invariant 8.2: A request state MUST NOT return to Pending from a terminal request state.
  ```
  WHY: the identity fields include the chain id once written (Composition state 4 and 5). Approved is the declared in-cascade transient; the audit pending list is a list of windows, each opened once and closed once, and is not a state.
- **Invariant 9 — Single audit instance (deployment-declared; verified in two halves).**
  ```
  Invariant 9.1: EVERY event the request-to-events map names MUST resolve in the one audit substrate.
  ```
  WHY: one instance receives the whole arc — the approval substrate's chain events and this composition's request, provisioning, exercise and revocation events. The records-alone half, within the horizon, is this rule and Check 6.1's reconstruction against that instance alone. The topology half — that no second instance receives a fork of these events — is not provable from any one instance's records and is External check 1.
- **Invariant 10 — Exercise-record durability (inherited, not parallel).**
  ```
  Invariant 10.1: The composition MUST NOT change an exercise event.
  Invariant 10.2: The composition MUST NOT change a failed exercise event.
  ```
  WHY: the exercise history is substrate truth under the substrate's own append-only, retention-governed, tamper-evident guarantees, and the session access log is a derived index over it — never modified, because its sources never are. A failed exercise carrying revoked is durable evidence that someone presented a revoked token under a valid session, auditable from the substrate alone.

---

## Examples

### Happy path — privileged database access under two-approver gate

An engineer requests read access to a production database for incident investigation:

`request_access(requestor_ref: eng_u42, credential: <eng_u42's presented material>, resource_ref: db::prod::incidents, access_scope: "read", justification: "INC-2891 investigation — prod log correlation", approver_set: [mgr_u10, sec_u03], quorum_rule: all-of-N, ttl: 3600) → request_id: req_p7h3k2`

Each approver now holds an Active Assignment for the request's step in Multi-Party Approval's in-tray. The security lead approves first:

`approve_step(actor_ref: sec_u03, credential: <sec_u03's presented material>, request_id: req_p7h3k2, step_id: step_s1, reason: "INC-2891 confirmed active")`

The chain is still Pending (one of two). The manager approves:

`approve_step(actor_ref: mgr_u10, credential: <mgr_u10's presented material>, request_id: req_p7h3k2, step_id: step_s2, reason: "authorized")`

The chain reaches `Approved`. The provisioning cascade fires: `Capability.allocate(allocator_ref: svc_pap, scope: <composed: req_p7h3k2, db::prod::incidents, "read">, max_redemptions: 1, ttl: 3387)` → `capability_token: cap_9f2d1e` — the ttl is the **remaining** lifetime, `expires_at − now`: 213 seconds of the requested 3600 elapsed while the two approvals were gathered, and the token's window ends where the request's does, within the skew between this composition's seam and Capability's (Capability requirement 26). The access_provisioned event records the request, never the token. The request transitions to `Provisioned`; the engineer receives `cap_9f2d1e` through the delivery channel.

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

Session validates as `valid(principal_ref: user_u77, …)` — the session gate passes. `Capability.redeem(cap_FORGED)` returns `invalid(not-known)`: the dedicated instance never allocated it, so it traces to no approval and grants nothing. The attempt is recorded — access_exercise_failed with `{request_id: null, session_principal_ref: user_u77, reason: not-known}` (the declared null-request exception; the forged material itself is never written) — so the auditor sees *who*, under a real session, presented a token the system never issued. The approval gate is visible here in its refusing mode: no chain, no token, no access, and a named principal attached to the attempt.

### Regulated adversarial scenarios

Four scenarios the composition must survive in regulated contexts:

**Regulator audit — SOX §404 privileged access control.** An external auditor asks *"can you prove that no one accessed the production financial database with elevated privileges without documented, multi-party authorization?"* The walk uses the declared surfaces, not payload-field queries the substrate does not offer: `read_request({resource_ref: db::prod::financials})` returns every request ever opened against the resource, each carrying its state and its `request_to_events` ids. For each `Provisioned` request the auditor takes the event ids into the substrate — access_provisioned, then every access_exercised — and traces the approval side through `request_to_chain` to the chain's own step records, recomputing the quorum outcome under the substrate's Invariant 2. Invariant 1 closes the other direction: enumerating the dedicated Capability instance and parsing each composed scope proves every token that exists traces to an `Approved` chain — no orphan tokens, no single-approver grants. SOX §404 is satisfied from the records alone.

**Disputed access — former employee denies using privileged token.** A security investigation reveals the production credentials database was queried at `2026-11-14T03:22:00Z`. A former employee claims they did not access it. The investigator runs `read_request({resource_ref: db::prod::credentials})`, finds `req_r9s4t1` provisioned that night, and reads its events: the access_exercised event at `03:22:11Z` carries `session_principal_ref: user_u88` — the identity `Session.validate` returned at the moment of exercise, recorded in the event itself rather than recovered by a later cross-reference. The approval chain for `req_r9s4t1` shows the same principal as requestor_ref, with both approvals attested at `02:58Z`. Invariant 3 guarantees the session gate passed in the same call; the Session store corroborates a session issued to `user_u88` at `03:15Z`. The denial cannot be sustained against the structural record; a credential-compromise reinterpretation is the **Compromise Disclosure** *(forthcoming)* pattern's business, never a mutation of this trail.

**HIPAA break-glass access trace — clinical PHI access audit.** A compliance officer must demonstrate to an OCR (Office for Civil Rights) auditor that a nurse's emergency break-glass access to a patient record on `2026-09-12` was authorized and documented. `read_request({resource_ref: ehr::patient::p4471})` returns `req_h8k3n2`; its events show the arc in order: `access_requested` (justification: "INC-4418 cardiac event — emergency PHI (Protected Health Information) access required"), the chain's two approval decisions (charge nurse + attending physician, all-of-N over two, credentials verified at decision time — Invariant 6), access_provisioned, and one access_exercised at `02:44Z` carrying `session_principal_ref: nurse_n21`. The full arc is present in the one Audit Trail instance (Invariant 9's records-alone half); HIPAA §164.312(b)'s access-audit requirement is satisfied from the records alone.

**Breach investigation — approval gate bypassed?** A security team finds an access_exercised event at `2026-12-01T18:44Z` against a high-security vault and asks whether the approval gate was bypassed. The event's request_id leads to `req_v2w5x8`: state `Provisioned`, chain `Approved`, two decision records, quorum recomputation clean. Then the systemic half — the same check the recovery discipline runs from inside: enumerate the dedicated Capability instance and parse every composed scope. A token whose scope parses to no request, to a request whose chain is not `Approved`, or that fails to parse at all is evidence of out-of-band allocation. All tokens accounting for themselves is the structural no-bypass answer; Invariant 1 makes the check deterministic.

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the composition's state plus the constituent stores — the approval substrate's chain and audit records, the dedicated Capability instance, the Session and Credential stores — can clear the checks below without recourse to source code, runbooks or developer narration. The bar splits in two, because two different things are asked: what the records answer, and what needs evidence the records cannot hold.

### Conformance checks

```
Check 1.1: An auditor MUST enumerate the Capability instance AND parse EVERY record's composed scope to the record's request (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY parsed request's chain Approved, recomputing the quorum under the substrate's own rule (Invariant 1.1).
Check 1.3: An auditor MUST report a bypass token as a provisioning bypass (Invariant 1.1).
Check 1.4: IF a token's request events are aged events THEN an auditor MUST read the request's Provisioned state AND the surviving provisioning attestation in place of the chain records (Capability requirement 10).
Check 2.1: An auditor MUST find, for EVERY exercise event, a Session record of the named principal live across the exercised instant (Invariant 3.1).
Check 2.2: An auditor MUST report a discrepancy narrower than the operating skew as inconclusive (Capability requirement 28).
Check 3.1: An auditor MUST find the deciding actor's credential Active across EVERY decision event's recorded instant (Invariant 6.1).
Check 3.2: An auditor MUST report a discrepancy narrower than the operating skew as inconclusive (Capability requirement 28).
Check 4.1: An auditor MUST find a denial event AND a Rejected chain for EVERY Denied request inside the horizon (Invariant 7.1).
Check 4.2: IF a ProvisioningFailed request carries no open pending entry THEN an auditor MUST find the request's provisioning-failure event (Invariant 7.3).
Check 5.1: An auditor MUST rebuild EVERY in-horizon index entry by the element's declared rebuild AND reproduce EVERY traversal answer (Composition state 15).
Check 5.2: An auditor MUST report an in-horizon index entry the rebuild cannot reproduce as a conformance failure (Composition state 29).
Check 5.3: An auditor MUST find EVERY index entry for an aged event present (Composition state 30).
Check 5.4: An auditor MUST find no bearer material in an audit event (Composition state 14).
Check 5.5: An auditor MUST find no bearer material in a request result (Action wiring 111).
Check 6.1: An auditor MUST reconstruct a request's arc from the request's events through the request-to-events map (Invariant 5.1).
Check 6.2: An auditor MUST verify EVERY event of the arc through Audit Trail's read record AND verify record (Invariant 10.1).
Check 6.3: An auditor MUST read a request carrying an open pending entry as a surfaced recovery window (Invariant 5.1).
Check 6.4: An auditor MUST report a committed act carrying no event AND no open pending entry as a finding (Invariant 5.3).
Check 6.5: An auditor MUST report a recovery record whose data disagrees with the constituent stores as a finding (Reconciliation 16).
```

NOTE: EVERY check names the rule the check tests.

Term bypass token: a token whose composed scope parses to no request, to a request whose chain is not Approved, or not at all.

Term operating skew: the deployment's declared bound on the difference between the composition's seam and a constituent's.

WHY:
**Walk the tokens, not the requests** (Check 1.1 through 1.4). Enumerating the Capability instance is what catches out-of-band allocation; a walk over the requests would never meet a token no request names.

**Two stamps from two seams prove nothing about a shared instant** (Check 2.1 through 3.2). The session gate ran at Session's seam and the credential check at Credential's, which is the enforcement; these checks audit the evidence trail of that enforcement, condemning violations wider than the operating skew and reading boundary-width discrepancies as inconclusive (Edge cases, *Clock semantics*). **The exercise check is existential** (Check 2.1, 2026-08-28-m): an exercise event names the session's principal, not the session, since the session token is bearer material and validate answers no other session identifier — so what the records can establish is that *some* session of that principal was live at the exercise, and the check says so rather than claiming the exercise's own session.

**The index rebuild is the conformance test for the classification** (Check 5.1 through 5.5). An in-horizon entry that cannot be rebuilt is carrying truth it should not; an entry for purged events is the declared truth-bearing half, and the test there is that it is *present*. A raw capability token or session token on a record surface is a finding in itself.

**The recovery state is read honestly** (Check 6.1 through 6.5): an open entry is a surfaced window, not a finding; the finding is a committed act with **no** event *and* **no** open entry — a gap the reconciliation should have caught — or a recovery record whose data disagrees with the constituent stores.

### External checks

```
External check 1: An auditor needing the arc confirmed un-fragmented MUST read the deployment's declaration AND wiring (Invariant 9.1).
External check 2: An auditor needing the composed-scope encoding confirmed MUST read the deployment's declaration AND conformance tests (Capability requirement 15).
External check 3: An auditor needing the delivery channel confirmed MUST read the deployment's operational security evidence (Provisioning cascade 12).
External check 4: An auditor needing the service identity's custody confirmed MUST read the deployment's issuance, rotation AND retirement records (Capability requirement 17).
External check 5: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
```

WHY:
A wrong scope encoder surfaces as parse failures, which the records show; a *different-but-parseable* encoding needs the declaration to condemn (External check 2). The raw token lawfully crosses exactly one surface, and whether the channel exposed it more widely is outside these records (External check 3). The service identity's forgery surface is bounded by Invariant 1's recomputability — a forged provisioning event names a request whose chain the step records show un-Approved — but custody itself is the deployment's discipline (External check 4).

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
```

WHY:
**The approval chain belongs to Multi-Party Approval** (Non-goal 1): the quorum rules, the trailing-decision behaviour, the substrate's own partial-failure recovery and its cascading withdrawal are the substrate's. **Session issuance is Login's** (Non-goal 2 and 3): this composition validates sessions and issues none; without Login or an equivalent issuance surface, every exercise answers session-invalid carrying not-known. **Delivery is the deployment's** (Non-goal 4): push, a secure store, a response payload — the composition hands the token to the channel and owns nothing past it. **Authorization policy is the deployment's** (Non-goal 5): the composition checks requests initiate; which principals hold it for which resources is the Permissions store's grants.

**A credential's revocation does not revoke the token** (Non-goal 6 and 7). It invalidates the sessions — where Login's cascade is wired — which blocks every exercise at the session gate, but the token itself stays allocated until it lapses or [Revoke Access] runs. A deployment wanting the token dead at once wires a listener on the credential-revocation events that calls [Revoke Access], which exists precisely for that.

**Re-access is a new request** (Non-goal 8 and 9): no renew and no re-provision. A request that failed to provision is terminal though its chain stays Approved — the approvers' decisions are durable and valid — and the requestor asks again with a fresh justification and a fresh chain. The cascade fires inside an approver's call, where the requestor is absent, so **telling the requestor is the deployment's obligation** (Non-goal 11): wire the provisioning-failure event to a notification, and alert on its accumulation, which means a capacity or configuration problem.

**Third-party withdrawal is deliberately absent** (Non-goal 10). An earlier draft promised a scope holder the power to withdraw any request; the promise was empty, since the substrate's withdrawal is initiator-only and every non-requestor call died unauthorized. The administrative needs it appeared to serve have honest homes: a Pending request an organization must stop is refused through the approval surface itself — an approver rejects a step, and an unreachable quorum lands the request Denied, an attributed decision of record, which is what an administrative stop *is*; a provisioned request is closed by [Revoke Access]; and a requestor who left mid-flight leaves a chain that never resolves, withdrawable by no one but harmless — provisioning never fires without quorum. A deployment for which none suffice is asking for a substrate-level administrative withdrawal, a Multi-Party Approval matter.

**An exercise is deliberately not idempotent** (Non-goal 12 and 13). Each call presenting a live token consumes one redemption — the Capability's contract and the point of a bounded-use token. A replay-safe exercise would need a result memo this composition has no truth store to hold — the shape the Contract routes to an Idempotency Result Memo. What the composition guarantees instead: exercised is answered **exactly when a redemption was consumed**, record failure included, so a caller that treats any exercised as final and never blindly retries a timeout without reading [Read Request] cannot double-spend by mistake.

**A failed session gate is not recorded here** (Non-goal 14): nothing attributable happened, and a **Failed-Attempt Log** *(forthcoming)* owns pre-authentication attempt auditing.

**The residual existence oracle is declared** (Non-goal 15, 2026-08-28-j). With the credential checked first, only an authenticated caller learns whether a request id exists or what state it is in — through not-known, not-pending or not-provisioned. A deployment needing that hidden too builds it in its calling layer.

**Nothing here is sealed but the trail** (Non-goal 16). Everything evidentiary is already tamper-evidence-covered — the events under the substrate's sealing — or immutably constituent-held — the token binding in the Capability record. The indexes are rebuildable caches; sealing one would certify a cache, not a fact, over state that includes a field still transitioning. The evidentiary surface for legal proceedings is the sealed event trail, reached through the request-to-events map.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A deployment MUST own the honesty AND the monotonicity of the injected now.
Clock semantics 2: A deployment needing a verifiable wall-time anchor MUST compose Trusted Timestamping.
```

WHY:
Skew between this composition's seam and Session's or Capability's can shift an exercise across a lapse at the margin. The gate itself ran against Session's own seam, which is the enforcement, and nothing load-bearing rests on a cross-seam comparison; Check 2.1 through 3.2 read the recorded stamps against the constituent records within the operating skew. Where privileged-access timestamps carry legal or forensic force, a **Trusted Timestamping** *(forthcoming)* pattern supplies the verifiable anchor; the residual risk under injection is a deployment injecting a dishonest now.

### Concurrency

```
Concurrency 1: An admitted revocation MUST set the request state under the per-request exclusion.
Concurrency 2: [Read Request] MUST NOT take the per-request exclusion.
Concurrency 3: An exercise MUST NOT hold the per-request exclusion across the exercise's record write.
```

WHY:
One exclusion per request serializes everything that reads the request state and acts on it: the chain evaluation and the cascade, [Withdraw Request]'s chain call and its evaluation, [Revoke Access]'s transition, every pending entry's open and close, and every reconciliation leg. The substrate's own per-chain mutex covers its side and cannot cover this layer's request-state read. [Exercise Access] takes it from the exercise entry's open through redeem's answer and the mark, and again to close the entry: the atom's counter would serialize the redemption on its own, and what the composition serializes is the pairing of one open entry with one redemption, so the redemption leg has at most one entry to attribute a counter step to. The cost is that two exercises of a multi-use token on one request serialize on the redeem — not on the whole action, the session check and the record write running outside the hold — which a break-glass deployment accepts for a decidable audit (Concurrency 3). [Read Request] is a pure projection, outside every obligation.

### Expiry

```
Expiry 1: The composition MUST NOT write a capability's expiry.
Expiry 2: A lapsed capability MUST leave the request state Provisioned.
Expiry 3: The composition MUST NOT gate a decision on the request's expiry instant.
Expiry 4: A deployment wanting stale requests withdrawn MUST call [Withdraw Request] from the deployment's own scheduler.
```

WHY:
**A token's expiry is derived, never written — here or in the atom** (Expiry 1 and 2). When a Provisioned request's deadline passes without exercise, nothing transitions anywhere: the atom has no expire action and shows a lapsed record expired through its derived effective status, and the request stays Provisioned, because Provisioned names what this composition did, not whether the token is live. A later exercise answers capability-invalid carrying expired from the atom's own derivation, and [Read Request] shows the honest pair — request Provisioned, token Expired. There is no scheduler to run and no write for one to perform.

**A request's expiry is guarded at the one place access could arise** (Expiry 3 and 4): the cascade's remaining ttl, whose non-positive value Capability refuses (Provisioning cascade 6). Decisions on an expired request are not clock-gated — they are decisions of record either way — and the expiry bites at provisioning, the only step that could mint access. A deployment wanting stale requests withdrawn wires a scheduler calling [Withdraw Request] past a business deadline — an ordinary, attributed withdrawal, the shape the substrate's own no-deadline non-goal prescribes.

### Multi-use capabilities

```
Multi-use capabilities 1: The composition MUST record EVERY exercise of a multi-use token as the exercise's own event.
Multi-use capabilities 2: The composition MUST NOT change the request state on a token's exhaustion.
```

WHY:
The max redemptions default is 1, and a deployment raises it for break-glass or time-boxed access. Each exercise is its own event and its own session access entry; the Capability's remaining redemptions fall on each redeem and the token is exhausted at zero, its stored status Redeemed; the request stays Provisioned until revocation. An auditor reading both stores recovers the full usage picture.

---

## Composition notes

- **[Login](./login.md)** — the upstream composition that issues Sessions. This composition depends on Sessions being issued by Login (Credential.verify → Session.issue → session_token returned to principal). Without Login or an equivalent session-issuance surface, [Exercise Access] always returns `session-invalid(not-known)`. Login is a peer composition, not a constituent; the two share the same Session and Credential atoms but own distinct composition-level surfaces.

- **[Session-Gated Authorization](./session-gated-authorization.md)** — a peer composition that gates permission checks on session validity. Privileged Access Provisioning gates Capability redemption on session validity; Session-Gated Authorization gates Permissions.permitted checks. The two are structurally parallel: both call `Session.validate` before a downstream action, neither managing Session issuance. A deployment that wires both ensures that session validity is checked consistently at every protected surface — Capability redemption and Permissions evaluation alike.

- **[External Onboarding](./external-onboarding.md)** — in regulated deployments where privileged users are external contractors or auditors rather than internal employees, External Onboarding (Invitation → Party Identity → Credential registration) is the upstream surface that establishes the requestor's Credential. A [Request Access] call with an unregistered requestor_ref fails the credential check at intake (Action wiring 12). External Onboarding establishes the Credential that this composition verifies.

- **[Capability-Backed Sharing](./capability-backed-sharing.md)** — a peer composition that uses Capability for resource disclosure rather than privileged access. The two compositions share the Capability atom but wire it to different upstream gates: Capability-Backed Sharing gates on Selective Disclosure policy; this composition gates on Multi-Party Approval. The structural similarity — approve first, allocate Capability second, record in Audit Trail third — is the pattern the library names as approval-gated capability provisioning.

- **Tamper Evidence — already applied where the truth lives, and not applicable where it does not.** Everything evidentiary in this composition's arc is already tamper-evidence-covered or immutably constituent-held: the request, approval, provisioning, exercise, and revocation events are ordinary audit events under the substrate's Tamper Evidence sealing, and the token binding is a field of the Capability's own immutable record. The composition's maps are derived indexes — rebuildable caches carrying no truth of their own — so there is nothing there *to* seal, and sealing them would certify a cache, not a fact. A deployment is not offered a "seal the `request_store`" surface, and deliberately: Tamper Evidence commits to a record set presented at seal time, which is meaningless over state that includes a still-transitioning field; the evidentiary surface for legal proceedings is the sealed event trail, reached through `request_to_events`.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the seven actions it exposes, the three request scopes it defines for its Permissions instance, and its own refusals. Approval gates provisioning, session-gated exercise and single-trail arc completeness are structural properties, not data. The deployment settings keep their wire spellings in configuration — `default_ttl`, `max_redemptions_default`, `credential_type`, `credential_check_on_request`, `approver_set_minimum`, `audit_trail_retention_policy`, `recording_completion_bound`, `store_durability`, `application_actor_ref`, `application_credential` — and the six elements theirs in an implementation, `request_store`, `request_to_chain`, `request_to_capability`, `capability_to_request`, `session_access_log`, `request_to_events`, with the recovery list as `audit_pending`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the approval substrate; the audit substrate; the host; the transition; the reconciliation; the provisioning cascade; the chain evaluation; the rebuild; a deployment; an auditor; a caller; a requestor; an approver; a deciding actor; a bearer; an investigator; an invocation; an action; a credentialed action; a decision action; an admitted request; a resolved exercise; a leg; the token leg; the approval leg; the terminal-chain leg; the redemption leg; the initiation leg; the denial-reason leg; a request; a request record; a chain; a token; a session; a pending entry; an index entry; a session access entry; the service identity; the delivery channel.

Term records: the audit events the composition records through the audit substrate — each an Audit Trail event carrying one action reference below — the request records, and the index entries.

Term record verbs: acquire, add, alert, answer, attest, belong, call, carry, change, check, clear, close, commit, compare, complete, compose, compute, configure, declare, define, delete, deliver, emit, enumerate, examine, expose, find, fire, follow, gate, grant, hide, hold, inherit, initiate, inject, issue, key, land, leave, make, mark, mint, name, normalize, notify, offer, open, order, own, pair, parse, pass, provision, purge, read, rebuild, reconstruct, record, refuse, register, release, renew, report, resolve, retry, return, reuse, revoke, run, satisfy, seal, serve, set, stamp, store, supply, take, validate, verify, wire, write.

Term value sets: action reference = access_requested | approval_step_decided | access_provisioned | access_denied | access_request_withdrawn | access_provisioning_failed | access_exercised | access_exercise_failed | access_revoked | access_recovery_intended | access_audit_recovery. The rest are declared where the section that owns each declares it: request state, open request state, terminal request state, refused state, provisioned state, refusing chain state, credential check on request, validation failure, exercise failure, settled gap, terminal chain action, bearer material.

Term bounds: audit horizon (audit_trail_retention_policy), recording completion bound (recording_completion_bound), default ttl (default_ttl), max redemptions default (max_redemptions_default), approver set minimum (approver_set_minimum), reference caps, payload budget.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, approval substrate, audit substrate, trail, chains initiate, chains withdraw, chains read, request record, request id, request state, request progression, open request state, terminal request state, refused state, identity field, request shape, shape-bearing event, state-transition event, bearer material, request-to-chain map, request-to-capability map, capability-to-request map, session access log, session access entry, request-to-events map, audit pending list, pending entry, aged event, quiescence, default ttl, max redemptions default, credential type, credential check on request, approver set minimum, audit horizon, retention floor, longest token lifetime, provisioning proof period, recording completion bound, composed scope, service identity, reference caps, per-request exclusion, seam, now, invocation id, remaining ttl, payload budget, validation failure, exercise failure, request results, credentialed action, decision action, load-bearing act, validated request, admitted withdrawal, validated exercise, verified revocation, admitted revocation, permitted read, admitted request, initiation entry, evaluation entry, denial-reason entry, exercise entry, resolved exercise, chain evaluation, provisioning conjunction, terminal chain action, requests initiate, requests revoke, requests read, reconciliation, recovery intent, recovery record, pairing count, provisioned state, refusing chain state, consumed count, exercised count, redemption gap, settled gap, provisioning cascade, delivery channel, bypass token, operating skew, request event, decision event, provisioning event, denial event, withdrawal event, initiation-failed withdrawal event, provisioning-failure event, exercise event, failed exercise event, revocation event.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index, truth-bearing and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. initiate chain, approve step, reject step, withdraw chain, read chain, chain id, step id, subject reference, approver set, quorum rule, chain_resolved, chain_withdrawn, Approved, Rejected, Withdrawn, Pending, not-pending, unauthorized: Multi-Party Approval. record action, read record, verify record, event id, payload cap, actor registry, invalid-credential, recording-failure: Audit Trail. verify, failed-verification, verified, Active: Credential. validate, valid, invalid, session token, principal reference: Session. permitted, denied: Permissions. allocate, redeem, revoke, read, capability token, scope, max redemptions, remaining redemptions, ttl, allocator reference, redeemed, effective status, redemption failure, exhausted, expired, revoked, already-terminal, Redeemed, Expired: Capability.

Term composing patterns: [Login](./login.md); [Session-Gated Authorization](./session-gated-authorization.md); [External Onboarding](./external-onboarding.md); [Capability-Backed Sharing](./capability-backed-sharing.md); Failed-Attempt Log *(forthcoming)*; Outbox *(forthcoming)*; Trusted Timestamping *(forthcoming)*; Compromise Disclosure *(forthcoming)*.

Term request event: the access_requested event — a request's shape-bearing opening record.

Term decision event: the approval_step_decided event — a decision keyed by request.

Term provisioning event: the access_provisioned event.

Term denial event: the access_denied event.

Term withdrawal event: the access_request_withdrawn event.

Term initiation-failed withdrawal event: a withdrawal event carrying initiation-failed as the reason and the request shape — the only event a request closed before its chain existed carries.

Term provisioning-failure event: the access_provisioning_failed event.

Term exercise event: the access_exercised event.

Term failed exercise event: the access_exercise_failed event.

Term revocation event: the access_revoked event.

#### Request Access

The intake action: submit a privileged-access request under a named requestor, gate it on [Requests Initiate] and — where configured — the requestor's credential, write the request before anything else, open its approval chain, and record the request event (Action wiring 10 through 30). Answers the request id; the request is Pending.

Kind: Operation

#### Approve Step

The wrapper over Multi-Party Approval's step approval: verify the approver's credential, route the decision, record it keyed by request, and run the chain evaluation — which fires the provisioning cascade when the chain reaches Approved, the only path to a provisioned token (Action wiring 31 through 58).

Kind: Operation

#### Reject Step

The wrapper over Multi-Party Approval's step rejection: [Approve Step]'s wiring with a required reason; the chain evaluation lands the request Denied when the chain reaches Rejected.

Kind: Operation

#### Withdraw Request

The requestor's withdrawal of their own Pending request and its chain — structurally only the requestor's, since the chain admits withdrawal solely from its initiator (Action wiring 59 through 74). The requestor's chains withdraw grant in the approval substrate is the permission surface.

Kind: Operation

#### Exercise Access

The session-gated use of a provisioned token: validate the session *first* — a non-valid session is [Session Invalid] before the token is touched — then resolve the token, write the exercise entry, redeem, and record every attempt that reached the atom, each naming the session's principal (Action wiring 75 through 94). Not idempotent: each live presentation consumes a redemption, and a consumed redemption is always answered exercised.

Kind: Operation

#### Revoke Access

The revocation of a provisioned token, gated by [Requests Revoke]; the request moves to Revoked. Answers [Not Provisioned] for a request not Provisioned (Action wiring 95 through 103).

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

#### Credential Invalid

The refusal when Credential's verify answers failed-verification — material-mismatch or no-active-credential — for a requestor or an approver, or when the approval substrate's attest refuses the credential; the enforcement behind approver-credential completeness (Invariant 6).

Kind:       Member
Member of:  the composition's refusals
Role:       Rejection
Projection: credential-invalid

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
[Credential Invalid]: #credential-invalid

---


## Standards references

- **SOX §404 (Management Assessment of Internal Controls)** — privileged access to financial systems requires documented, multi-party authorization. This composition's approval-gates-provisioning invariant and its Audit Trail arc are the structural implementation of the §404 access-control evidence requirement. Every access_exercised event traces to a documented, approved request with named approvers.

- **HIPAA §164.312(a)(1) (Access Control)** — covered entities must implement technical policies and procedures for electronic information systems that allow access only to authorized users. The composition's multi-party approval gate is the authorization policy; the Credential.verify checks at both request and approval time ensure the actors in the arc are authenticated; the Session.validate check ensures the principal is currently authenticated at exercise time.

- **PCI DSS Requirements 7 and 8 (Restrict Access and Identify Users)** — Requirement 7 mandates that access to system components and cardholder data is restricted to only those individuals whose job requires such access. Requirement 8 mandates that all users are assigned a unique ID before access is allowed. This composition enforces both: the approval chain documents the business need; the requestor_ref and the Session record establish the unique user identity.

- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-53 AC-2 (Account Management) and AC-6 (Least Privilege)** — AC-2 requires that privileged user accounts are authorized by senior officials and reviewed regularly. AC-6 requires that privileged access is limited to the minimum required. This composition models the authorization record (AC-2) and the time-limited, scoped Capability (AC-6's minimum-necessary principle expressed as a token with explicit TTL — time-to-live, a validity duration — and scope).

- **NIST SP 800-53 AC-17 (Remote Access)** — in deployments where privileged access is exercised remotely, the session-gated exercise check enforces that remote access is only permitted under an authenticated session. The Audit Trail records the session's authenticated `principal_ref` and the `exercised_at` stamp for every remote access exercise — never the session token, which is bearer material and appears on no record surface — satisfying the remote-access audit requirement without the trail granting what it records.

- **ISO/IEC 27001 §A.9.2.3 (Management of Privileged Access Rights)** — the International Organization for Standardization / International Electrotechnical Commission information-security standard requires that the allocation and use of privileged access rights is controlled and restricted. This composition directly implements that control: allocation is gated by approval; use is gated by session validity; both are recorded in a tamper-evident log.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — privileged-access-provisioning.tla, no twin, 2026-06-03
last gate: 2026-08-28 — second gate after closure, fresh reader — 5 foundational (all since closed), 19 refining, 5 rhetorical

open:
- 2026-08-29-a · refining · formal · the model's sweep carries no pre-check, no identity, no recovery record, and no age bound → extend the model with the four sweep rules
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/privileged-access-provisioning.md`.

- **2026-09-23 — Rewritten in GRACE lang v0.61; forty-four of forty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with `Provisioning cascade` and `Scope vocabulary` kept as the page's own; the prose's Behavior section distributed to the rules that own each claim; invariant numbers 1 through 10 unchanged; the checks renumbered `Check 1.1` through `Check 6.5`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency`, `Expiry` and `Multi-use capabilities` under the second. The choices the lines left open, made by standing rules: the credential checked before the request is resolved, closing the unauthenticated existence oracle and declaring the authenticated residual (2026-08-28-j); the exercise ordered before its provisioning event declared lawful rather than gated, since a delivered token is lawful access (2026-08-28-h); the session check stated existentially, since the record names the principal and no session identifier (2026-08-28-m); the decision event and the credential check kept, with what each adds stated — the request-keyed record and the second registry (2026-08-28-n); the one-credential-two-registries assumption declared (2026-08-28-a); the blank-reason denial's entry closed by a recovery record carrying the reason, or by the horizon (2026-08-28-c); a chain found under a request already Withdrawn closed and reported, not recorded (2026-08-27-p); the substrate's refusals over a possibly committed decision routed to an evaluation entry (2026-08-26-b); a read_chain refusal inside the evaluation answered with the decision and an evaluation entry (2026-08-26-a); the token's deadline restated as Capability's reading plus the remaining ttl, since allocate takes a duration (2026-08-27-j). The rest took their prescribed fixes — the terminal-event walk from the tail, read_record's real arms, the chain shape validated at intake, the token resolved by Capability's read on the token with redeem not called on a miss, the credential second in every signature, the third Permissions call site, the cascading-revocation qualifier carried, Provisioned advancing to Revoked, the provisioning event carrying the redemption count and the expiry instant, the chain-less skip, the counts, the examples' quorum vocabulary, material and Assignment attribution. *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The model line stays open (2026-08-29-a).
- **2026-08-25 — Every Composition-state element is a derived index over the substrate audit log and the Capability instance's composed scope.** *Chose:* no bearer material on any record surface, every index rebuildable from the trail and the token's scope, a named recovery discipline. *Over:* composition-owned stores carrying request and access truth of their own. *Because:* the records-alone control claim — every privileged token traces to an approved request — is only as strong as the evidence that outlives the composition's own state.
- **2026-08-28 — The live provisioning guard is the sweep's detector, and every crash window around the evaluation has a leg.** *Chose:* [Approve Step] step 5 fires the cascade on the same conjunction the sweep's second leg tests (non-terminal ∧ no token for the request ∧ no open provisioning-failed entry), a not-pending from the substrate still runs the evaluation, a terminal-chain leg closes a request whose decision died before evaluating, exercise entries are marked `redeemed` inside the hold, and a failed evaluation opens an entry and still returns approved. *Over:* a guard on the request-state read, and a reconciliation that compared the redemption counter against events alone. *Because:* the `Approved` transient rebuilds to `Pending`, so the state read alone allocated a second token after a crash; the reconciliation read two open entries — a shape the page admitted — as a conformance finding; and a decision that died between commit and evaluation left its request `Pending` forever.
- **2026-08-29 — The sweep pre-checks the trail, is bounded where it runs outside the hold, writes as the composition behind a recovery record, and the truth-bearing state is named.** *Chose:* every sweep leg detects on rebuilt state and the absence of the event, paired by a seam-injected `invocation_id` on every event and entry; the redemption-reconciliation leg examines no entry younger than a declared `recording_completion_bound`; every sweep write is attested under the service identity behind an access_recovery_intended record; the open `audit_pending` payloads are declared truth-bearing, extraction-pending against Outbox, and the store's never-delete rule and the dedicated Capability instance's purge exemption are declared as `store_durability`. *Over:* legs that detected on an index and re-ran a non-idempotent `record_action`, an exercise leg with no lower edge over a window the serialization does not cover, and "all six elements are derived indexes" over state the page itself called truth-bearing. *Because:* a stale index with the event already landed re-emitted duplicates; an entry marked `redeemed` seconds ago belongs to an invocation about to write; a compensation the absent actor did not make cannot be attested as theirs; and a record owed for a committed act that exists in no constituent is not a cache (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A derived index splits at the horizon*).
- **2026-08-26 — The `requests:withdraw` scope and third-party withdrawal are dropped.** *Chose:* remove the scope, its term entry and registry entry, and name the administrative alternatives. *Over:* keeping a promise the wiring could not honor. *Because:* the substrate's chain withdrawal is initiator-only and the composition actor is not the initiator, so no honest wiring existed for the path.

NOTE: End of Privileged Access Provisioning.

---
title: Capability-Backed Sharing
parent: Conceptual Compositions
nav_order: 23
has_toc: true
toc: true
---

# Capability-Backed Sharing

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Capability-Backed Sharing is a regulated composition — a specification that wires several freestanding patterns together — that solves a problem that looks impossible at first: how to share data using a "bearer token" (a link or token where simply holding it grants access, no login required) while still keeping the strict disclosure records that privacy laws demand. The apparent contradiction is that bearer tokens deliberately don't check who's using them, but regulators want to know who's accountable for every disclosure.

This composition's insight is that the accountable party isn't the person who *used* the token — it's the person who *issued* it. So it records, with a cryptographic attestation that lasts as long as the audit record is kept, who authorized the share (the allocator), to whom they authorized it, what data, under what legal authority, and for how long — captured at the moment of issuance when that person is present to sign for it. When the token is later redeemed, the disclosure is logged against that authorizer, and the person who actually presented the token is — by design — never named, because the bearer model never asked.

The composition's defining emergent guarantee is exactly this audit-subject asymmetry: the record always answers "who authorized this disclosure?" and never answers "who redeemed it?". Its second guarantee is about how that record and its tamper-evident seal are written: they are written in one transaction, so a seal you find always has a real disclosure behind it, and where the audit trail refuses the seal, the one gap that remains — a disclosure whose seal has not yet landed — is always visible, and is repaired, or escalated once its intent has aged past the audit horizon.

Its common uses are exactly the places bearer sharing and regulated audit collide: a hospital sharing a scoped slice of a patient record with a referred specialist via a time-limited link (the minimum-necessary fields, logged against the authorizing clinician), a bank issuing a pre-signed link to disclose a customer's transaction subset to an auditor, or a controller sharing specific personal-data fields with a processor under a consent record. Any system that must share data by token *and* make it provable who authorized each disclosure — without being able to (or wanting to) name who consumed it — is a candidate for this composition.

---

## Intent

Two correct designs appear to contradict each other, and reconciling them is the friction this composition exists to resolve. The **object-capability (OCAP — a security model in which an unforgeable reference to a resource carries its own authority)** model says: a bearer token *is* the authorization; whoever holds it may act, and asking *who* is holding it defeats the purpose — a password-reset link, a pre-signed download URL, a scoped API (Application Programming Interface) token all work precisely because no per-redemption identity check happens. The **regulated-disclosure** model says the opposite: every disclosure of a data subject's information must be *accountable* — a regulator asking "who authorized this disclosure, and under what authority?" must get a provable answer. A naive reading concludes you cannot have both: either you check identity at the point of access (and lose bearer semantics) or you don't (and lose accountability). This composition shows the reading is wrong, and naming *why* is the composition's contribution.

The resolution is an **asymmetry of audit subjects**. Accountability does not require naming the *redeemer*; it requires naming the *authorizing party* — and those are two different actors at two different moments. The authorizing party is the **allocator**: the data controller (or their delegate) who decided that a specific subset of a subject's data may be shared, with a named intended recipient, under a named legal authority, for a bounded number of redemptions, for a bounded time. That decision happens at *allocation*, when the allocator is present and can be cryptographically attested under their own credential. The *redeemer* is whoever later presents the token — and by the bearer-token design, their identity is neither checked nor recorded. This composition's audit record therefore reads "**disclosed under authority of allocator X, who authorized this share at time T**," never "redeemed by Z." The allocator is fully accountable (Capability records the allocator immutably and only the allocator — Capability Invariants 1 and 5; this composition additionally attests the allocator at allocation); the redeemer is structurally unnamed (Capability performs no identity check at redemption — Capability Invariant 3). Regulated audit is satisfied by the allocator's accountability; bearer semantics are preserved by the redeemer's anonymity. Neither model is broken.

This reframe carries a precise consequence for what the disclosure record names as **recipient**. The bearer who actually presents the token is unknowable by design; what the record names is the **intended recipient the allocator declared at allocation time**. The disclosure was *authorized to go to* recipient R; whether the actual bearer was R, R's delegate, or a party who obtained the token improperly is exactly the question bearer semantics make unanswerable — and the records are honest about that boundary (it is the forensic limit Capability's own disputed-disclosure scenario names). The composition records who *authorized* the disclosure and to *whom it was authorized*, not who *consumed* it.

No single constituent resolves this. Capability is the bearer-token primitive — it records the allocator, authorizes by possession, and refuses to record a redeemer — but it does not record *that a disclosure occurred*, does not carry the legal authority for the disclosure, and is not tamper-evident. Selective Disclosure is the disclosure-accounting record — to whom, what scope, under what authority, when — but it does not gate access, does not carry a redemption envelope (how many times, until when), and its append-only immutability is by specification, not cryptographically sealed. Audit Trail is the tamper-evident, attributed, retained substrate — but it knows nothing about bearer tokens or disclosure scope. The structure that allocates a bearer token whose scope *is* an authorized disclosure, performs the disclosure on redemption, records it accountably to the allocator while naming no redeemer, and seals the whole thing belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Capability, Selective Disclosure, and Audit Trail are unchanged; this composition is the wiring that makes them coherent as one accountable-bearer-sharing surface. It introduces emergent actions — [Authorize Sharing] (allocate the capability and attest the allocator's authorization), [Redeem And Disclose] (the load-bearing surface: redeem by possession, then record the disclosure and seal it), [Revoke Sharing], and read-only queries — that belong to no single constituent. What it is *not*: it is not an identity-keyed access control surface (that is Permissions — this composition is bearer-keyed by design); it is not the disclosure-delivery mechanism (it records *that* and *to whom authorized* a disclosure occurred; retrieving, redacting, and transmitting the bytes is the host's job, exactly as Selective Disclosure records without performing); it is not the adjudicator of whether the declared authority is legally valid (that legitimacy is an externally-clearable check, as in Selective Disclosure and Resolve a Person's Data Rights); and it does not — cannot — identify the redeemer (the bearer-key design forecloses it). Each is named in Non-goals.

---

## Composes

- **[Capability](../atoms/capability.md)** — the bearer-token primitive and the source of the audit asymmetry.
- **[Selective Disclosure](../atoms/selective-disclosure.md)** — the disclosure-accounting record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every authorization, disclosure and revocation is sealed through.

```
Composes 1: EXACTLY ONE Capability instance MUST serve the composition.
Composes 2: EXACTLY ONE Selective Disclosure instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 7: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 8: The Capability instance MUST serve the composition alone.
Composes 9: The Capability instance MUST answer Capability's read for a filter on one capability token.
Composes 10: The Capability instance MUST answer Capability's read for a filter on an allocator reference.
Composes 11: The composition MUST make [Redeem And Disclose] the only disclosure surface over the Selective Disclosure instance.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
```

Term composition: this pattern's wiring of [Capability](../atoms/capability.md), [Selective Disclosure](../atoms/selective-disclosure.md) and the [Audit Trail](./audit-trail.md) substrate — the five actions, the two indexes, the sharing scope grammar and the reconciliation.

Term constituents: [Capability](../atoms/capability.md), [Selective Disclosure](../atoms/selective-disclosure.md), [Audit Trail](./audit-trail.md).

Term substrate: the Audit Trail instance serving the composition.

Term trail: the substrate's events, in sequence order, as the composition and an auditor read them.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the capability-to-sharing index.
Composition state 2: The composition MUST key the capability-to-sharing index by capability token.
Composition state 3: A capability-to-sharing entry MUST carry the allocator reference, the subject reference, the intended recipient, the disclosed scope, the authority, the authorization event id AND the allocation reading.
Composition state 4: The composition MUST write a capability-to-sharing entry ONLY AFTER the authorization event lands.
Composition state 5: The composition MUST NOT change a capability-to-sharing entry.
Composition state 6: The composition MUST rebuild a missing capability-to-sharing entry from the authorization events.
Composition state 7: The composition MUST NOT rebuild the authorization event id of an aged event.
NOTE: open 2026-10-27-b — Composition state 3, 6 and 7 cannot all hold for an entry rebuilt after its authorization event aged: the entry carries the authorization event id, a missing entry is rebuilt, and an aged event's id is not.
Composition state 8: The composition MUST store the disclosure-to-redemption index.
Composition state 9: The composition MUST key the disclosure-to-redemption index by disclosure id.
Composition state 10: A disclosure-to-redemption entry MUST carry the capability token, the allocator reference, the intent event id, the invocation id, the seal marker AND the disclosure reading.
Deleted: Composition state 11. Execution Contract Database 1 owns it.
Composition state 12: The composition MUST write a disclosure-to-redemption entry carrying pending as the seal marker.
Composition state 13: The composition MUST set the seal marker to the disclosure event's id ONLY AFTER the disclosure event lands.
Composition state 14: The composition MUST NOT carry a redeemer identity in either index.
Deleted: Composition state 15. Execution Contract Database 3 owns it.
Composition state 16: The composition MUST rebuild a sealed disclosure-to-redemption entry from the disclosure events.
```

Term capability-to-sharing index: the composition's map from a capability token to the share it authorizes — the authorization-provenance index.

Term disclosure-to-redemption index: the composition's map from a disclosure id to the capability, the allocator and the intent behind the disclosure.

Term seal marker: pending | the disclosure event's id — pending while a committed disclosure's seal has not landed.

Term pending marker: a disclosure-to-redemption entry whose seal marker EQUALS pending.

Term allocation reading: the invocation's now at [Authorize Sharing], stamped on the authorization event and the index entry.

Term disclosure reading: the invocation's now at [Redeem And Disclose], stamped on the disclosure intent, the pending marker and the disclosure event — a reading of this composition's seam, never claimed equal to the disclosure record's own disclosure instant.

Term intended recipient: the recipient the allocator declared in the sharing descriptor — the party the share was authorized to go to, never the bearer who presents the token — an [Intended Recipient].

Term disclosed scope: the field subset a capability authorizes for disclosure, parsed from the capability's immutable scope by the sharing scope grammar — a [Disclosed Scope].

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the capability-to-sharing index: derived index over the authorization events (Composition state 6), its authorization event id not rebuilt past the audit horizon (Composition state 7); a disclosure-to-redemption entry: extraction-pending against Outbox *(forthcoming)* while it is a pending marker, derived index over the disclosure events once sealed (Composition state 16), and extraction-pending against Erasure Tombstone *(forthcoming)* past the audit horizon (Capability requirement 5).

---
### Capability requirement

```
Capability requirement 1: A deployment MUST declare the sharing scope grammar.
Capability requirement 2: A deployment MUST provision the service identity as a registered actor.
Capability requirement 3: A deployment MUST rotate the service identity's credential.
Capability requirement 4: A deployment MUST configure the Audit Trail instance with the audit horizon.
Capability requirement 5: The longest disclosure-accounting obligation MUST NOT EXCEED the audit horizon.
Capability requirement 6: A deployment MUST set the default max redemptions.
Capability requirement 7: A deployment MUST set the compensation window.
Capability requirement 8: A deployment MUST set the reconciliation cadence.
Capability requirement 9: The reconciliation cadence MUST NOT EXCEED the compensation window.
Deleted: Capability requirement 10. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Capability requirement 12: IF the compensation window EQUALS blank THEN the composition MUST refuse to start.
Deleted: Capability requirement 13. Execution Contract Database 1 owns it: the composition names no redemption completion bound for a deployment to leave blank.
Capability requirement 14: A deployment MUST supply now AND the invocation id at the composition's seam.
Capability requirement 15: The composition MUST take EXACTLY ONE now PER invocation.
Capability requirement 16: The composition MUST NOT pass now to a constituent.
Capability requirement 17: The composition MUST NOT mint an id.
Capability requirement 18: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term sharing scope grammar: the deployment-declared grammar that encodes a sharing descriptor as a capability scope and parses a capability scope back into the sharing descriptor — one grammar, read in both directions.

Term sharing descriptor: the subject reference, the intended recipient, the disclosed scope and the authority — what a capability's scope means to this composition.

Term service identity: the composition's own registered actor and credential, application_actor_ref and application_credential — the attesting actor of every event made when no caller-authenticated actor is present.

Term audit horizon: the horizon of the retention policy the wired Audit Trail instance places every sharing event under.

Term longest disclosure-accounting obligation: the longest a regulation in force obliges an accounting of the disclosed data to survive — six years under the HIPAA (US Health Insurance Portability and Accountability Act) accounting of disclosures, the typical floor.

Term default max redemptions: the max redemptions [Authorize Sharing] passes to Capability's allocate where the call supplies none.

Term compensation window: the deployment-declared duration within which a committed-but-unsealed disclosure, or an allocated capability with no authorization event, must be compensated or escalated.

Term reconciliation cadence: the interval at which the reconciliation runs.

Term invocation id: the id the seam injects for one invocation, carried on the invocation's intent and outcome.

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank allocator reference.
Primitive policy 2: The composition MUST answer invalid-request for a blank credential.
Primitive policy 3: [Authorize Sharing] MUST answer invalid-request for an out-of-bounds envelope.
Primitive policy 4: [Revoke Sharing] MUST answer invalid-request for a blank revocation input.
Primitive policy 5: [Authorize Sharing] MUST answer invalid-sharing-descriptor for a descriptor the sharing scope grammar does not parse.
Primitive policy 6: [Authorize Sharing] MUST answer invalid-sharing-descriptor for a descriptor carrying a blank required descriptor field.
Primitive policy 7: The sharing scope grammar MUST parse the encoding of a sharing descriptor back into the same sharing descriptor.
Primitive policy 8: IF the descriptor's authority type IS NOT IN the authority types THEN [Authorize Sharing] MUST answer unknown-authority-type.
Primitive policy 9: IF the encoded descriptor EXCEEDS the descriptor cap THEN [Authorize Sharing] MUST answer invalid-sharing-descriptor.
Primitive policy 10: The composition MUST compare a capability token byte-exact.
Primitive policy 11: The composition MUST NOT normalize a capability token.
Primitive policy 12: The composition MUST NOT accept a redeemer credential.
Primitive policy 13: The composition MUST NOT persist a credential.
Primitive policy 14: A refusal under Primitive policy 1 through 9 MUST NOT write.
```

Term out-of-bounds envelope: a supplied max redemptions or a supplied ttl outside Capability's own bounds.

Term revocation input: the capability token, the revoked by reference and the revocation reason.

Term required descriptor field: the subject reference, the intended recipient, the disclosed scope and the authority reference.

Term descriptor cap: the largest encoded descriptor whose events fit the substrate's payload cap — the substrate's payload cap less the largest event's fixed fields, so the caller's text is refused as the caller's fault before the substrate can refuse it as a deployment's.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent record THEN the action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure at an intent record THEN the action MUST answer recording-failure carrying intent.
NOTE: watch the retention step's recording failure (Audit arm 2).
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Audit arm 4: IF the landing read finds the record THEN the composition MUST proceed as landed.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Audit arm 6: IF Audit Trail answers invalid-request carrying a step below step-3 at an intent record THEN the action MUST answer invalid-request.
Audit arm 7: The composition MUST NOT retry an invalid-request answer.
Audit arm 8: IF Audit Trail answers recording-failure at an outcome record THEN the action MUST answer recording-failure carrying outcome AND the orphan reference.
NOTE: watch the retention step's recording failure (Audit arm 8).
NOTE: open 2026-10-27-d — a recording failure at a refusal event or an unfulfilled event lands as outcome with an orphan reference naming a disclosure id neither carries, and a refusal event follows a redemption that consumed nothing.
Deleted: Audit arm 9. Execution Contract Database 2 owns it.
Audit arm 10: IF Audit Trail answers invalid-credential at a service-attested record THEN the action MUST answer invalid-credential.
Audit arm 11: The composition MUST NOT retry a service-attested record Audit Trail answered with invalid-credential.
Audit arm 12: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 13: A caller MUST read recording-failure carrying outcome as a committed act.
Audit arm 14: A caller MUST NOT re-run an action answering recording-failure carrying outcome.
Audit arm 15: The landing read MUST match the record by the invocation's intent event id.
Audit arm 16: The deployment MUST alert on an invalid-request from Audit Trail as a deployment fault.
Audit arm 17: The deployment MUST alert on a service-attested invalid-credential as a deployment fault.
Deleted: Audit arm 18. Execution Contract Database 1 owns it.
Audit arm 19: IF Audit Trail answers invalid-request(step-3) at an intent record THEN the action MUST answer recording-failure carrying intent.
Audit arm 20: IF Audit Trail answers invalid-request carrying a step below step-4 at an outcome record THEN the action MUST answer recording-failure carrying outcome AND the orphan reference.
Audit arm 21: IF Audit Trail answers invalid-request(step-4) at a record THEN the composition MUST read the record's event id back.
```

Term intent record: the record an action writes before the action's committing constituent call — the authorization intent, the disclosure intent or the revocation intent.

Term outcome record: the record an action writes after the action's committing constituent call — the authorization event, the disclosure event, the refusal event, the unfulfilled event or the revocation event.

Term position: intent | outcome — where a recording-failure sat: intent, nothing committed and the whole action may be retried; outcome, the domain write — an allocation, a consumed use and the use's disclosure, a revocation — exists, and a re-run would commit a second one.

Term orphan reference: the capability token an outcome-position refusal at [Authorize Sharing] or [Revoke Sharing] names, or the disclosure id one at [Redeem And Disclose] names — the committed act the missing record was to seal.

Term human-attested outcome record: the authorization event or the revocation event — attested under the calling actor's credential.

Term service-attested record: the disclosure intent, the disclosure event, the refusal event, the unfulfilled event or any reconciliation record — attested under the service identity.

### Action wiring

```
authorize_sharing(allocator_ref, credential, sharing_descriptor, optional max_redemptions, optional ttl)
  answers authorization result
  refuses invalid-request | invalid-credential | invalid-sharing-descriptor | unknown-authority-type | storage-failure | recording-failure(position, orphan reference)

redeem_and_disclose(capability_token)
  answers disclosure result | invalid(redemption failure)
  refuses not-authorized-sharing | redemption-unfulfilled | invalid-credential | invalid-request | storage-failure | recording-failure(position, orphan reference)

revoke_sharing(capability_token, revoked_by_ref, credential, reason)
  answers revocation result
  refuses invalid-request | invalid-credential | already-terminal | not-known | storage-failure | recording-failure(position, orphan reference)

sharing_disclosures(subject_ref)
  answers disclosure history
  refuses invalid-query

authorization_provenance(capability_token)
  answers provenance | not-known
```

Term authorization result: the capability token and the authorization event's id an [Authorize Sharing] answers.

Term disclosure result: the disclosure id, the disclosure event's id, the disclosed scope and the allocator reference a [Redeem And Disclose] answers.

Term revocation result: revoked and the revocation event's id a [Revoke Sharing] answers.

Term disclosure history: a subject's disclosure records, each joined to the allocator reference that authorized the disclosure — what [Sharing Disclosures] answers.

Term provenance: a capability-to-sharing entry's allocator reference, sharing descriptor and authorization event id — what [Authorization Provenance] answers.

```
Action wiring 1: [Authorize Sharing] MUST NOT call Capability's allocate BEFORE the authorization intent lands.
Action wiring 2: A validated authorization MUST record an authorization intent carrying the sharing descriptor, the effective max redemptions, the effective ttl AND the allocation reading under the allocator's credential.
Action wiring 3: The authorization intent MUST NOT carry a capability token.
Action wiring 4: An admitted authorization MUST call Capability's allocate with the allocator reference, the encoded sharing descriptor as the scope, the effective max redemptions AND the effective ttl.
Action wiring 5: IF Capability answers invalid-request for an allocate THEN [Authorize Sharing] MUST answer invalid-request.
Deleted: Action wiring 6. Execution Contract Constituent failure 1 owns it.
Action wiring 7: A refused allocate MUST NOT write beyond the authorization intent.
Action wiring 8: An allocating authorization MUST record an authorization event carrying the intent event id, the capability token, the sharing descriptor, the effective max redemptions, the effective ttl AND the allocation reading under the allocator's credential ONLY AFTER Capability's allocate answers the capability token.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Action wiring 10: The composition MUST NOT attest an authorization event under an actor other than the allocator.
Action wiring 11: An attested authorization MUST answer the capability token AND the authorization event's id.
Action wiring 12: [Redeem And Disclose] MUST NOT call Capability's redeem BEFORE resolving the sharing descriptor.
Action wiring 13: The composition MUST read a presented token's capability record through Capability's read filtered to the capability token.
Action wiring 14: IF no capability record EXISTS for the capability token THEN [Redeem And Disclose] MUST answer invalid carrying not-known.
Action wiring 15: IF an unparsed scope EXISTS for the capability token THEN [Redeem And Disclose] MUST answer not-authorized-sharing.
Action wiring 16: The deployment MUST alert on an unparsed scope as a conformance fault.
Action wiring 17: [Redeem And Disclose] MUST NOT refuse a token as unattested BEFORE rebuilding the token's capability-to-sharing entry.
Action wiring 18: [Redeem And Disclose] MUST answer not-authorized-sharing for an unattested token.
Action wiring 19: IF a diverged entry EXISTS for the capability token THEN [Redeem And Disclose] MUST rebuild the capability-to-sharing entry.
Action wiring 20: [Redeem And Disclose] MUST answer not-authorized-sharing for an irreconcilable token.
Action wiring 21: The deployment MUST alert on an irreconcilable token as a conformance fault.
Action wiring 22: A refusal under Action wiring 14 through 21 MUST NOT write.
Action wiring 23: An admitted redemption MUST record a disclosure intent carrying the invocation id, the capability token, the allocator reference, the sharing descriptor, the authorization event id AND the disclosure reading under the service identity.
Action wiring 24: The composition MUST NOT read a disclosure intent as an authentication record.
Action wiring 25: An admitted redemption MUST call Capability's redeem with the capability token ONLY AFTER the disclosure intent lands.
Action wiring 26: IF Capability answers invalid THEN [Redeem And Disclose] MUST answer invalid carrying the redemption failure.
Deleted: Action wiring 54. Execution Contract Constituent failure 1 owns it.
Action wiring 27: IF Capability answers invalid THEN the admitted redemption MUST record a refusal event carrying the intent event id, the capability token AND the redemption failure.
Action wiring 28: The deployment MUST alert on a diverged redemption as a conformance fault.
Action wiring 29: A consuming redemption MUST call Selective Disclosure's record with the subject reference, the intended recipient as the recipient, the disclosed scope as the scope AND the authority.
Action wiring 30: A consuming redemption MUST NOT pass a disclosure instant to Selective Disclosure's record.
Action wiring 31: IF Selective Disclosure answers invalid-request OR unknown-authority-type THEN the consuming redemption MUST record an unfulfilled event carrying the intent event id, the capability token, the allocator reference AND the refusal as the reason.
Action wiring 32: IF Selective Disclosure answers invalid-request OR unknown-authority-type THEN [Redeem And Disclose] MUST answer redemption-unfulfilled.
Deleted: Action wiring 55. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Action wiring 34: The composition MUST NOT record a disclosure event for an unfulfilled redemption.
Action wiring 35: The deployment MUST alert on a foreclosed disclosure refusal as a conformance fault.
Action wiring 36: A disclosing redemption MUST record a disclosure event carrying the intent event id, the invocation id, the disclosure id, the capability token, the allocator reference, the sharing descriptor, the authorization event id AND the disclosure reading under the service identity ONLY AFTER Selective Disclosure's record answers the disclosure id.
Deleted: Action wiring 37. Execution Contract Database 1 owns it.
Action wiring 38: A sealed redemption MUST answer the disclosure id, the disclosure event's id, the disclosed scope AND the allocator reference.
Action wiring 39: [Revoke Sharing] MUST NOT call Capability's revoke BEFORE the revocation intent lands.
Action wiring 40: A validated revocation MUST record a revocation intent carrying the capability token, the revocation reason AND the revocation reading under the revoker's credential.
Action wiring 41: An admitted revocation MUST call Capability's revoke with the capability token, the revoked by reference AND the revocation reason.
Action wiring 42: IF Capability answers already-terminal for a revoke THEN [Revoke Sharing] MUST answer already-terminal.
Action wiring 43: IF Capability answers not-known for a revoke THEN [Revoke Sharing] MUST answer not-known.
Deleted: Action wiring 44. Execution Contract Constituent failure 1 owns it.
Action wiring 45: IF Capability answers invalid-request for a revoke THEN [Revoke Sharing] MUST answer invalid-request.
Action wiring 46: A revoking revocation MUST record a revocation event carrying the intent event id, the capability token, the revocation reason AND the revocation reading under the revoker's credential ONLY AFTER Capability's revoke answers revoked.
Action wiring 47: A landed revocation MUST answer revoked AND the revocation event's id.
Action wiring 48: [Revoke Sharing] MUST NOT refuse a token the capability-to-sharing index does not carry.
Action wiring 49: [Sharing Disclosures] MUST answer Selective Disclosure's read for the subject reference, each disclosure record joined to the record's disclosure-to-redemption entry.
Action wiring 50: IF Selective Disclosure answers invalid-query THEN [Sharing Disclosures] MUST answer invalid-query.
Action wiring 51: [Authorization Provenance] MUST answer the capability-to-sharing entry for the capability token.
Action wiring 52: IF no capability-to-sharing entry EXISTS for the capability token THEN [Authorization Provenance] MUST answer not-known.
Action wiring 56: [Authorization Provenance] MUST NOT answer not-known BEFORE rebuilding the capability token's capability-to-sharing entry.
NOTE: watch the miss read before its rebuild (Action wiring 56).
Action wiring 53: A read-only query MUST NOT record an event.
```

Term validated authorization: an [Authorize Sharing] call whose inputs and descriptor clear Primitive policy.

Term admitted authorization: a validated authorization whose authorization intent lands.

Term allocating authorization: an admitted authorization Capability's allocate answered with a capability token.

Term attested authorization: an allocating authorization whose authorization event landed or proceeds as landed.

Term effective max redemptions: the call's max redemptions, or the default max redemptions where the call supplies none.

Term effective ttl: the call's ttl, or Capability's default capability ttl where the call supplies none.

Term unparsed scope: a capability scope the sharing scope grammar does not parse.

Term unattested token: a capability token carrying no capability-to-sharing entry after the entry's rebuild.

Term diverged entry: a capability-to-sharing entry whose sharing descriptor or allocator reference differs from the ones the capability record carries.

Term irreconcilable token: a capability token whose capability-to-sharing entry still diverges from the capability record after the entry's rebuild.

Term admitted redemption: a [Redeem And Disclose] call whose sharing descriptor resolved and whose disclosure intent lands.

Term diverged redemption: a redemption whose answered scope or allocator reference differs from the ones Action wiring 13 resolved.

Term consuming redemption: an admitted redemption Capability's redeem answered redeemed — one use consumed, irreversibly.

Term foreclosed disclosure refusal: invalid-request | unknown-authority-type — the Selective Disclosure refusals a descriptor that cleared Primitive policy cannot reach.

Term disclosing redemption: a consuming redemption Selective Disclosure's record answered with a disclosure id.

Term sealed redemption: a disclosing redemption whose disclosure event landed or proceeds as landed.

Term validated revocation: a [Revoke Sharing] call whose inputs clear Primitive policy.

Term admitted revocation: a validated revocation whose revocation intent lands.

Term revoking revocation: an admitted revocation Capability's revoke answered revoked.

Term landed revocation: a revoking revocation whose revocation event landed or proceeds as landed.

Term revocation reading: the invocation's now at [Revoke Sharing], stamped on the revocation intent and the revocation event.

### Wiring decision

```
Wiring decision 1: The composition MUST attach a disclosure's accountability to the allocator's authorization.
Wiring decision 2: The composition MUST NOT attach a disclosure's accountability to the bearer.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Deleted: Wiring decision 4. Execution Contract Database 1 owns it.
Wiring decision 5: The composition MUST NOT fabricate a disclosure record for a consumed use.
```

<details markdown="block">
<summary>WHY</summary>

*Principle:* regulated disclosure requires a named, non-repudiable *authorizing* party, not a named *consumer*; bearer-token sharing requires the consumer be anonymous. Both are satisfied at once by attaching accountability to the allocator. *Likely objection:* doesn't accountable disclosure mean recording who received the data? *Mechanism:* the regulator's question is *who authorized this disclosure, and under what authority?* — and that is the allocator and the authority, both recorded: the allocator at allocation under the allocator's own credential, the authority in the capability's scope and the disclosure record, and the disclosure attributed to the allocator in the disclosure event. The redeemer's identity is *structurally* unavailable — Capability's redeem accepts none and records none — so this composition records what it can prove and is honest about what bearer semantics make unprovable. *Result:* the disclosure is accountable to the allocator and the redeemer is never named — the asymmetry no constituent provides alone.

</details>

### Reconciliation

```
Deleted: Reconciliation 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Deleted: Reconciliation 3. Execution Contract Database 1 owns it.
Reconciliation 4: The reconciliation MUST attest EVERY write the reconciliation makes under the service identity.
Reconciliation 5: The reconciliation MUST NOT write a compensating event BEFORE the reconciliation's recovery intent lands.
Reconciliation 6: The reconciliation MUST record a recovery intent carrying the invocation id, the direction, the capability token, the disclosure id where one stands AND the intent reference.
Reconciliation 7: A compensating event MUST carry the recovery flag, the intent reference AND the capability token.
Reconciliation 8: The reconciliation MUST re-derive a compensating event from the pending marker, the intent event AND the constituent records.
Reconciliation 9: IF a pending marker's disclosure intent IS NOT IN the aged events AND no disclosure event EXISTS for the pending marker's disclosure id THEN the reconciliation MUST seal the pending marker by recording the marker's disclosure event.
Reconciliation 10: A compensating disclosure event MUST carry the pending marker's disclosure id, the pending marker's allocator reference AND the disclosure intent's sharing descriptor.
Reconciliation 11: The reconciliation MUST read a disclosure intent carrying no outcome record as a candidate.
Reconciliation 12: The reconciliation MUST NOT seal from a disclosure intent.
Reconciliation 13: The reconciliation MUST record one unfulfilled event PER unit of a capability's remainder.
Reconciliation 14: A reconciliation's unfulfilled event MUST name the capability's unmatched disclosure intents as the candidates.
Reconciliation 15: The reconciliation MUST record an abandonment event for EVERY unmatched disclosure intent the remainder does not account for.
Reconciliation 16: The reconciliation MUST NOT seal from a remainder.
Reconciliation 17: The reconciliation MUST read an authorization intent's candidates as the capabilities the intent's actor allocated inside the pairing window carrying no authorization event.
Reconciliation 18: IF a candidate capability of an authorization intent IS NOT IN the settled capabilities THEN the reconciliation MUST revoke the candidate capability under the service identity.
NOTE: open 2026-10-27-c — the reconciliation's revoke names no revoked by reference and no revocation reason, and Capability refuses a blank one (Capability Operation 39, Operation 40).
Reconciliation 19: IF the candidate reading EQUALS several THEN the reconciliation MUST name the candidates on the finding.
Reconciliation 20: IF a capability's status EQUALS revoked AND no revocation event names the capability token THEN the reconciliation MUST record a compensating revocation event.
Reconciliation 21: A compensating revocation event MUST carry the capability record's revoked by reference as the revoked by reference.
Reconciliation 22: The reconciliation MUST NOT record a revocation event for a capability token another revocation event names.
Reconciliation 23: The reconciliation MUST escalate EVERY overdue partial as a compliance finding.
Reconciliation 24: The reconciliation MUST escalate a pending marker whose disclosure intent is an aged event.
Reconciliation 25: The reconciliation MUST NOT seal a pending marker whose disclosure intent is an aged event.
Reconciliation 26: The reconciliation MUST NOT compensate a substrate partial.
NOTE: open 2026-08-29-r — the formal model's compensation carries no service identity, no recovery intent and no age bound (Reconciliation 4, Reconciliation 6, Reconciliation 24, Reconciliation 25).
```

Term reconciliation: the leg this composition runs outside every action, each run an invocation of its own, whose output — a sealed disclosure, a landed partial or an escalation — an auditor awaits within the compensation window.

Term recovery intent: the sharing.recovery_intended event — the reconciliation's intent record, naming the partial the reconciliation detected and what the reconciliation is about to append.

Term direction: what a recovery intent says the reconciliation is about to do — append a compensating event or an abandonment event, or revoke a candidate capability.

Term intent reference: the original intent's event id, or the candidate intents where attribution among concurrent intents is presumptive.

Term recovery flag: cascade_recovery set to true — the payload field that tells a reader a compensating event from a clean one.

Term consumed count: `(max redemptions - remaining redemptions)` for one capability, read through Capability's read.

Term remainder: `(((consumed count - disclosure events) - pending markers) - unfulfilled events)` for one capability — the consumed uses left unlanded.

Term pairing window: from an authorization intent's recording instant to the end of the compensation window measured from the same instant.

Term candidate reading: none | sole | several — how many capabilities an authorization intent's pairing names.

Term partial: an allocated capability with no authorization event, a pending marker, a remainder, or an unmatched intent.

Term overdue partial: a partial whose first record's `(recording instant + compensation window)` PRECEDES now.

Term aged event: an event whose `(recording instant + audit horizon)` PRECEDES now — past which the event's payload may be lawfully destroyed.

Term substrate partial: the orphan attestation a substrate failure at the substrate's append leaves, or the unretained event a failure at the substrate's retention placement leaves — the substrate's own reconciliation's.

---
## Composition-level invariants

These emerge from the composition; none belongs to a single constituent.

- **Invariant 1 — Audit-subject asymmetry.**
  ```
  Invariant 1.1: EVERY capability-backed disclosure's records MUST name the allocator as the authorizing party.
  Invariant 1.2: The composition MUST NOT record a redeemer identity in any record.
  Invariant 1.3: EVERY disclosure record the composition produces MUST carry the capability's intended recipient as the recipient.
  NOTE: open 2026-10-27-a — Selective Disclosure's Term recipient is the party the data reached, and the composition records the intended recipient, whom a bearer's redemption need not reach.
  Invariant 1.4: The composition MUST make the allocator-named claim ONLY IF the disclosure's events lie inside the audit horizon.
  ```
- **Invariant 2 — Disclosure-accountability binding.**
  ```
  Invariant 2.1: EVERY disclosure event MUST name a disclosure record in the Selective Disclosure records.
  Invariant 2.2: A disclosure record MUST NOT carry two disclosure events.
  Invariant 2.3: EVERY committed disclosure whose disclosure event has not landed MUST stand as a pending marker.
  Invariant 2.4: The composition MUST seal EVERY pending marker whose disclosure intent IS NOT IN the aged events WITHIN the compensation window.
  Invariant 2.5: The composition MUST make the binding claim ONLY IF the deployment declares the compensation window AND the reconciliation cadence.
  ```
- **Invariant 3 — Allocation-authorization binding.**
  ```
  Invariant 3.1: EVERY authorization event MUST name a capability token in the Capability records.
  Invariant 3.2: EVERY capability-to-sharing entry MUST name EXACTLY ONE authorization event.
  Invariant 3.3: EVERY authorization event MUST carry the allocator's own attestation.
  Invariant 3.4: EVERY allocated capability MUST stand settled WITHIN the compensation window.
  ```
  Term settled capability: a capability carrying an authorization event, a capability the reconciliation or a revoker revoked, or a lapsed capability.

- **Invariant 4 — Scope-bounded disclosure.**
  ```
  Invariant 4.1: EVERY disclosure record the composition produces MUST carry the capability's disclosed scope as the scope.
  Invariant 4.2: The disclosure events naming a capability token MUST NOT EXCEED the capability's consumed count.
  ```
- **Invariant 6 — Authentication precedes commitment at the actions that name an actor.**
  ```
  Invariant 6.1: EVERY allocation the composition makes MUST follow a validation of the allocator's credential.
  Invariant 6.2: EVERY revocation the composition makes MUST follow a validation of the revoker's credential.
  Deleted: Invariant 5. Composes 5 owns it.
  ```

---

## Examples

### Walkthrough — a clinician shares a scoped patient record with a referred specialist, end to end

A hospital deploys this composition with `sharing_scope_grammar` encoding `subject::recipient::fields::authority`, the substrate's `audit_trail_retention_policy = hipaa_6_year`, and a provisioned service identity.

1. **Authorization.** A treating clinician refers a patient to a specialist and authorizes a one-time, 24-hour share of the minimum-necessary fields: `authorize_sharing(allocator_ref = "dr_chen", credential = <chen-cred>, sharing_descriptor = {subject: "patient-7842", recipient: "dr-okafor-cardiology", fields: "cardiology-summary", authority: {type: consent, reference: "consent-8821"}}, max_redemptions: 1, ttl: 86400)`. This composition parses the descriptor, then — **before allocating anything** — records the intent: `AuditTrail.record_action(sharing.authorization_intended, actor_ref = "dr_chen", <chen-cred>, data = {subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821, max_redemptions: 1, ttl: 86400, intended_at})` → `ev_auth_int_01`. That write is where Dr. Chen's credential is checked against the actor registry; had it not validated, the call would have returned `rejected(invalid-credential)` with no capability minted (Invariant 6). Only then `Capability.allocate(...)` returns `capability_token = tok_share_x1`, and `AuditTrail.record_action(sharing.authorized, actor_ref = "dr_chen", <chen-cred>, data = {intent_event_id: ev_auth_int_01, tok_share_x1, subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821, …})` → `ev_auth_01` — **attested under Dr. Chen's credential** (Invariant 3). `capability_to_sharing[tok_share_x1]` is populated. Returns `{tok_share_x1, ev_auth_01}`. The hospital emails the specialist a link embedding `tok_share_x1`.
2. **Redemption and disclosure.** The specialist's system opens the link within the day: `redeem_and_disclose(tok_share_x1)` — **no identity is presented**. This composition resolves the descriptor, records its intent, redeems, records the disclosure, and seals, in that order. **Descriptor:** `Capability.read({tok_share_x1})` → the scope parses to patient-7842 / dr-okafor-cardiology / cardiology-summary / consent-8821; `capability_to_sharing` supplies `ev_auth_01`. **Intent:** `AuditTrail.record_action(sharing.disclosure_intended, actor_ref = <service identity>, data = {tok_share_x1, allocator_ref: "dr_chen", subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, …})` → `ev_disc_int_01` — naming no bearer. **Redemption:** `Capability.redeem(tok_share_x1) → redeemed(scope, allocator_ref = "dr_chen")`; the capability exhausts (single-use → `Redeemed`), irreversibly. **Domain mutation:** `SelectiveDisclosure.record(subject: "patient-7842", recipient: "dr-okafor-cardiology", scope: "cardiology-summary", authority: {consent, consent-8821})` → `disc_01`, with `disclosure_to_redemption[disc_01]` written pending in the same transaction. **Outcome:** `AuditTrail.record_action(sharing.disclosed, actor_ref = <service identity>, data = {disc_01, tok_share_x1, allocator_ref: "dr_chen", subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821})` → `ev_disc_01` — **attributed to the service identity, naming Dr. Chen as the authorizing allocator, naming no redeemer**; `disclosure_to_redemption[disc_01]`'s pending is replaced by `ev_disc_01`. Returns `{disc_01, ev_disc_01, "cardiology-summary", "dr_chen"}`. The hospital then transmits the cardiology-summary fields to the specialist.
3. **The audit answer.** `sharing_disclosures("patient-7842")` returns `disc_01`: disclosed `cardiology-summary` to `dr-okafor-cardiology`, under consent `consent-8821`, **authorized by `dr_chen`** (Invariant 1). `authorization_provenance(tok_share_x1)` confirms Dr. Chen authorized it, and `ev_auth_01`'s `intent_event_id` resolves to `ev_auth_int_01` — which makes it provable that Dr. Chen was authenticated *before* the capability existed (Check 5.1). There is no field anywhere recording *who* at the specialist's office actually opened the link — by design.

### Domain example — a multi-use pre-signed disclosure to an auditor

A bank authorizes, under SOX (the US Sarbanes-Oxley Act) section 404, a 10-redemption, 7-day capability for an external auditor to pull a customer's transaction subset: `authorize_sharing("compliance_officer_m", <cred>, {subject: "acct-0187", recipient: "audit-firm-AF3", fields: "transactions:2024", authority: {type: regulatory, reference: "SOX §404"}}, max_redemptions: 10, ttl: 604800)`. Over the week the auditor's tooling redeems the token nine times from various systems; each [Redeem And Disclose] records a distinct Selective Disclosure record bound to its own sealed [Sharing Disclosed] event, every one attributed to `compliance_officer_m` as the allocator and **none recording which of the auditor's systems redeemed it**. The `remaining_redemptions` counter (Capability) decrements 10→1; the regulated-audit record shows nine accountable disclosures under one authorization. The audit-subject asymmetry holds across every redemption.

### Rejection path — spent, lapsed, cancelled, foreign, and unrecorded tokens

- **Exhausted / expired / revoked.** A bearer redeems a single-use token a second time: `redeem_and_disclose(tok_share_x1) → invalid(exhausted)`; **nothing is disclosed** (Capability returned `invalid(exhausted)` at step 3, and the intent is closed by a `sharing.disclosure_refused` record naming it). A token presented after its TTL → `invalid(expired)`; after [Revoke Sharing] → `invalid(revoked)`. These are first-class outcomes, not rejections — the bearer presented a token that no longer authorizes a disclosure, and no disclosure record is created (the no-disclosure-unrecorded direction holds: no disclosure occurred, so none is recorded).
- **Unattested capability.** A token allocated by [Authorize Sharing] whose [Sharing Authorized] attestation never landed is redeemed: step 1 finds no `capability_to_sharing` entry after rebuild → `rejected(not-authorized-sharing)` **before `redeem` is called**, so nothing is consumed and nothing is disclosed. The Capability instance is exclusive to this composition (*Composes*), so there is no foreign token to refuse: a token the instance does not know is `invalid(not-known)`, and a scope that does not parse is a conformance fault, not another composition's share.
- **Early revocation closes the window.** The referral is withdrawn before the specialist opens the link, so the hospital's privacy officer cancels a *still-live* token — `tok_share_x2`, allocated to the same specialist and never redeemed: `revoke_sharing(tok_share_x2, "privacy_officer_hosp", <cred>, "referral-withdrawn")` first records a [Sharing Revocation Intended] event → `ev_rev_int_01` (where the revoker's credential is verified — a live sharing is never cancelled on an unverified claim), then transitions the capability to `Revoked` via `Capability.revoke`, then records a [Sharing Revoked] event carrying `intent_event_id: ev_rev_int_01` under the revoker's credential; subsequent redemptions return `invalid(revoked)`.
- **Revoking a token that is already spent.** The same officer, a day late, tries to cancel `tok_share_x1`, which the specialist already redeemed: the [Sharing Revocation Intended] event is written (the officer is a real actor and their credential validates), then `Capability.revoke` refuses already-terminal — Capability's redeemed state is absorbing — so the call returns `rejected(already-terminal)` and **no** [Sharing Revoked] event is written. That leaves an intent event with no outcome event — the third case of the revocation triage (Check 5.4): a capability record exists and is not in the revoked state (it is terminal by *redemption*), so nothing committed and nothing is owed. Nothing about the earlier disclosure is altered.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "who authorized this disclosure of subject DS-99's data, and under what authority?"** A GDPR (EU General Data Protection Regulation) Data Protection Authority examines a disclosure. `sharing_disclosures("DS-99")` returns the disclosure record with its `authority` (`{type, reference}`) and the **authorizing allocator_ref**; `AuditTrail.verify_record`, presented with the bound [Sharing Disclosed] event's original payload, confirms it was not altered (Check 2.3 — an event still in the unsealed tail is read as unsealed, not failed) (Invariant 2, resting on the substrate's Tamper Evidence), and the [Sharing Authorized] event — **attested under the allocator's own credential** (Invariant 3) — is the non-repudiable proof that the named allocator authorized the share. The auditor's question is answered by the allocator and the authority, both recorded; the auditor does *not* ask "who redeemed it," and Invariant 1 makes clear the records structurally cannot and do not answer that — which is the correct, honest boundary for bearer-token sharing, not a gap.

**Disputed disclosure — "I never received that data."** A named intended recipient claims they never received the data. The records show capability `tok_share_x1` was authorized for disclosure *to* `dr-okafor-cardiology` (the [Sharing Authorized] event, attested by Dr. Chen) and that a redemption-disclosure occurred ([Sharing Disclosed], bound to `disc_01`). What the records **cannot** establish is whether `dr-okafor-cardiology` — versus a party who obtained the forwarded or intercepted token — actually presented it: bearer semantics make the redeemer unknowable (Capability Invariant 3/5, surfaced as Invariant 1). The records bound the forensic window precisely — *this share was authorized to this recipient, by this allocator, and a bearer redeemed it at this time* — without resolving redeemer identity, which is exactly Capability's own disputed-disclosure boundary. Whether the recipient's denial is accurate (the token was taken before redemption) or not is a question the bearer design deliberately leaves open; the composition is honest that it does.

**Breach investigation — "during the incident window, was any disclosure made under a capability that should have been revoked, or any sealed event altered?"** An investigator walks the [Sharing Disclosed] events in the window (reached through the substrate Audit Trail in Event Log insertion order), and for each, cross-reads the bound Selective Disclosure record and the capability's state. A disclosure under a capability whose `sharing.revoked` event predates it would be the smoking gun — but Invariant 2's binding plus Capability's terminal-absorbing revocation (a `Revoked` capability returns `invalid(revoked)` and discloses nothing) forecloses it: no [Sharing Disclosed] event exists for a redemption that occurred after revocation. Because each disclosure's descriptor is part of the sealed event payload, an attempt to silently widen a disclosed scope (to exfiltrate beyond what was authorized) breaks the seal (Invariant 4 + Tamper Evidence). The forensic window is bounded by the substrate's seal cadence; the newest disclosures in the unsealed tail carry per-event immutability and become seal-verifiable at the next cadence.

---

## Generation acceptance

A derived implementation is acceptable when the conformance checks below are provable to an external auditor given the two indexes and the Capability, Selective Disclosure and Audit Trail records; the external checks name what no record carries.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY disclosure event naming an allocator reference (Invariant 1.1).
Check 1.2: An auditor MUST find no redeemer identity in any sharing record (Invariant 1.2).
Check 1.3: An auditor MUST find EVERY disclosure record's recipient equal to the intended recipient the capability's authorization event names (Invariant 1.3).
Check 1.4: An auditor MUST find EVERY disclosure record's authority equal to the authority the disclosure event names (Invariant 1.1).
Check 2.1: An auditor MUST find EVERY disclosure event's disclosure id naming a disclosure record in the Selective Disclosure records (Invariant 2.1).
Check 2.2: An auditor MUST find no disclosure record carrying two disclosure events (Invariant 2.2).
Check 2.3: An auditor MUST verify a disclosure event PER Audit Trail's verify record contract, presenting the event's original payload (Invariant 2.1).
Deleted: Check 2.4. Check 2.3 owns it.
Check 2.5: An auditor MUST find EVERY disclosure record no disclosure event names standing as a pending marker (Invariant 2.3).
NOTE: watch the check over a derived index (Check 2.5).
Check 3.1: An auditor MUST enumerate EVERY authorization intent AND resolve the intent's authorization event AND the intent's candidate capabilities (Invariant 3.4).
Check 3.2: An auditor MUST find EXACTLY ONE authorization event PER capability-to-sharing entry (Invariant 3.2).
Check 3.3: An auditor MUST find EVERY authorization event attested under the allocator reference the entry carries (Invariant 3.3).
Check 3.4: An auditor MUST find EVERY disclosure event's capability token resolving to an authorization event (Invariant 3.2).
Deleted: Check 3.5. Check 3.1 owns it.
Check 4.1: An auditor MUST find EVERY disclosure record's scope equal to the disclosed scope the capability's authorization event names (Invariant 4.1).
Check 4.2: An auditor MUST find the disclosure events naming a capability token not exceeding the capability's consumed count (Invariant 4.2).
Check 4.3: An auditor MUST find, at quiescence, EVERY capability's remainder EQUALS zero (Reconciliation 13).
Check 5.1: An auditor MUST find EVERY human-attested outcome record preceded in trail order by the intent record the outcome's intent event id names (Invariant 6.1).
Check 5.2: An auditor MUST find a human-attested outcome record AND the outcome's intent record carrying one acting actor (Invariant 6.2).
Deleted: Check 5.3. Check 5.1 owns it.
Check 5.4: An auditor MUST classify a revocation intent carrying no outcome record PER the revocation triage (Reconciliation 20).
Deleted: Check 5.5. Action wiring 24 owns it.
Check 6.1: An auditor MUST find no pending marker older than the compensation window standing unsealed AND unescalated (Invariant 2.4).
Check 6.2: An auditor MUST find no disclosure event sealed from a remainder (Reconciliation 16).
Check 6.3: An auditor MUST find EVERY compensating disclosure event carrying the pending marker's disclosure id, the pending marker's allocator reference AND the disclosure intent's sharing descriptor (Reconciliation 10).
Check 6.4: An auditor MUST find no allocated capability older than the compensation window standing unsettled AND unescalated (Invariant 3.4).
Deleted: Check 6.5. Reconciliation 23 owns it.
Deleted: Check 6.6. Execution Contract Database 1 owns it.
Deleted: Check 6.7. Reconciliation 25 owns it.
```

Term sharing record: a capability record, a disclosure record, an audit event or an index entry.

Term revocation triage: four cases for a revocation intent with no outcome — the capability revoked and no revocation event names the token, owing a compensating event; the capability revoked and another invocation's revocation event names the token, owing nothing; the capability present and not revoked, owing nothing; no capability record for the token, owing nothing.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the redeemer's identity MUST read an identity-keyed access model's records (Non-goal 1).
External check 2: An auditor needing the declared authority confirmed as legally valid MUST read the authority's own records (Non-goal 4).
External check 3: An auditor needing the delivered bytes confirmed against the disclosed scope MUST read the host's delivery records (Non-goal 3).
External check 4: An auditor needing the allocator's permission to share confirmed MUST read the composed Permissions instance's records (Non-goal 5).
External check 5: An auditor needing the compensation window AND the reconciliation cadence confirmed MUST read the deployment's own configuration (Capability requirement 7).
Deleted: External check 6. Execution Contract Database 3 owns it.
External check 7: An auditor needing the Capability instance's exclusivity confirmed MUST read the deployment's own wiring (Composes 8).
External check 8: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT identify a redeemer.
Non-goal 2: A deployment needing to know who accessed the data MUST compose an identity-keyed access model.
Non-goal 3: The composition MUST NOT deliver the disclosed data.
Non-goal 4: The composition MUST NOT adjudicate an authority's legal validity.
Non-goal 5: The composition MUST NOT authorize an allocator.
Non-goal 6: A deployment needing an authorized allocator MUST compose Permissions ahead of [Authorize Sharing].
Non-goal 7: The composition MUST NOT record a read of the sharing history.
Non-goal 8: The composition MUST NOT deliver a capability token.
```

NOTE: the owners — [Permissions](../atoms/permissions.md) and [Session](../atoms/session.md), an identity-keyed access model (Non-goal 1, Non-goal 2, External check 1); [Permissions](../atoms/permissions.md) (Non-goal 5, Non-goal 6, External check 4); a composing access-log pattern (Non-goal 7); the deployment (Non-goal 8).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
```

### Clock semantics

```
Clock semantics 1: The composition MUST order a sharing event by the substrate's sequence number alone.
Clock semantics 2: The composition MUST NOT compare a composition reading against the substrate's recording instant.
Clock semantics 3: The composition MUST NOT compare the disclosure reading against the disclosure record's disclosure instant.
```

Term composition reading: an allocation reading, a disclosure reading or a revocation reading.

Term authority's own records: the Consent records, the Legal Hold records or the deployment's legal analysis — whichever the authority type names.

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

### Multi-use capabilities

A capability allowing more than one redemption produces one disclosure record and one disclosure event per redemption, each bound independently (Invariant 2 holds per redemption), all attributed to the same allocator (Invariant 1), all under the same authorized scope (Invariant 4). The redemption envelope bounds the count; the asymmetry holds across every redemption.

### Substrate partials

The substrate has durable partials of its own — an orphan attestation where its append failed after its attestation committed, and an unretained event where its retention placement failed after its append. They are Audit Trail's, found and closed by its own reconciliation, and this composition's leg does not compensate them (Reconciliation 26). What this composition sees of them is the step on the refusal: an invalid-request at the substrate's retention step means the event is in the log and is read back as landed (Audit arm 21 and Audit arm 4).

---
## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the five actions it exposes, the audit events it records, the two descriptor fields it interprets from a capability's scope, and its own refusals. The audit-subject asymmetry itself is a structural guarantee (Invariant 1), not a datum — there is no redeemer field to carry an entry. The deployment settings keep their wire spellings in configuration — `sharing_scope_grammar`, `application_actor_ref`, `application_credential`, `audit_trail_retention_policy`, `default_capability_ttl`, `default_max_redemptions`, `compensation_window`, `reconciliation_cadence` — and the two indexes theirs in an implementation, `capability_to_sharing` and `disclosure_to_redemption`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the substrate; the host; the reconciliation; a deployment; an auditor; a caller; an allocator; a revoker; a bearer; an operator; an invocation; an action; a read-only query; an intent record; an outcome record; a validated authorization; an admitted authorization; an allocating authorization; an attested authorization; an admitted redemption; a consuming redemption; a disclosing redemption; a sealed redemption; a validated revocation; an admitted revocation; a revoking revocation; a landed revocation; a refused allocate; a refusal; the landing read; an authorization intent; an authorization event; a disclosure intent; a disclosure event; a refusal event; an unfulfilled event; a revocation intent; a revocation event; a recovery intent; an abandonment event; a compensating event; a compensating disclosure event; a compensating revocation event; a pending marker; a partial; an overdue partial; a capability; a capability record; a disclosure record; a capability-to-sharing entry; a disclosure-to-redemption entry; the capability-to-sharing index; the disclosure-to-redemption index; the sharing scope grammar; the service identity; the longest disclosure-accounting obligation; the reconciliation cadence.

Term records: the intent records, outcome records and reconciliation records the composition writes through the substrate — each an Audit Trail event carrying one event type below — and the two index entries.

Term record verbs: serve, change, inherit, read, hold, answer, make, select, query, store, key, carry, write, rebuild, set, declare, provision, rotate, configure, refuse, supply, take, pass, mint, validate, parse, compare, normalize, accept, persist, proceed, retry, re-run, match, alert, call, record, attest, attach, fabricate, run, re-derive, seal, name, revoke, escalate, compensate, follow, stand, reach, find, verify, enumerate, anchor, join, classify, measure, identify, compose, deliver, adjudicate, authorize, order, resolve.

Term value sets: event type = sharing.authorization_intended | sharing.authorized | sharing.disclosure_intended | sharing.disclosed | sharing.disclosure_refused | sharing.redemption_unfulfilled | sharing.revocation_intended | sharing.revoked | sharing.recovery_intended | sharing.intent_abandoned. The rest are declared where the section that owns each declares it: seal marker, position, foreclosed disclosure refusal, candidate reading.

Term bounds: compensation window (compensation_window), audit horizon (audit_trail_retention_policy), descriptor cap, default max redemptions (default_max_redemptions).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, substrate, trail, capability-to-sharing index, disclosure-to-redemption index, seal marker, pending marker, allocation reading, disclosure reading, intended recipient, disclosed scope, sharing scope grammar, sharing descriptor, service identity, audit horizon, longest disclosure-accounting obligation, default max redemptions, compensation window, reconciliation cadence, invocation id, out-of-bounds envelope, revocation input, required descriptor field, descriptor cap, intent record, outcome record, position, orphan reference, human-attested outcome record, service-attested record, authorization result, disclosure result, revocation result, disclosure history, provenance, validated authorization, admitted authorization, allocating authorization, attested authorization, effective max redemptions, effective ttl, unparsed scope, unattested token, diverged entry, irreconcilable token, admitted redemption, diverged redemption, consuming redemption, foreclosed disclosure refusal, disclosing redemption, sealed redemption, validated revocation, admitted revocation, revoking revocation, landed revocation, revocation reading, reconciliation, recovery intent, direction, intent reference, recovery flag, consumed count, remainder, pairing window, candidate reading, partial, overdue partial, aged event, substrate partial, settled capability, sharing record, revocation triage, composition reading, authority's own records, authorization intent, authorization event, disclosure intent, disclosure event, refusal event, unfulfilled event, revocation intent, revocation event, abandonment event, compensating event, redeemer identity, conformance fault, allocation, revocation, consumed use.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's, which Term aged event and Term overdue partial rely on when they read the substrate's recording instant against now. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index, truth-bearing and extraction-pending classifications. record_action, verify_record, proceed as landed, compliance alert, payload cap, recording instant, event id, action reference: Audit Trail. capability token, allocator reference, scope, max redemptions, remaining redemptions, ttl, default capability ttl, expiry instant, status, lapsed, revoked by reference, revocation reason, redemption failure, filter, now: Capability. disclosure record, disclosure id, subject reference, recipient, authority, authority type, authority types, authority reference, disclosure instant: Selective Disclosure.

Term composing patterns: Outbox *(forthcoming)*; Erasure Tombstone *(forthcoming)*; Trusted Timestamping *(forthcoming)*; [Permissions](../atoms/permissions.md); [Session](../atoms/session.md).

Term authorization intent: the sharing.authorization_intended event — a [Sharing Authorization Intended].

Term authorization event: the sharing.authorized event — a [Sharing Authorized].

Term disclosure intent: the sharing.disclosure_intended event — a [Sharing Disclosure Intended].

Term disclosure event: the sharing.disclosed event — a [Sharing Disclosed].

Term refusal event: the sharing.disclosure_refused event — the record that closes a disclosure intent whose redemption Capability refused.

Term unfulfilled event: the sharing.redemption_unfulfilled event — the record of a consumed use whose disclosure did not commit.

Term revocation intent: the sharing.revocation_intended event — a [Sharing Revocation Intended].

Term revocation event: the sharing.revoked event — a [Sharing Revoked].

Term abandonment event: the sharing.intent_abandoned event — the reconciliation's record closing a disclosure intent that consumed nothing.

Term compensating event: an outcome record the reconciliation writes for a committed act whose own invocation did not record the outcome.

Term redeemer identity: any value naming who presented a capability token — the one datum this composition never records.

Term conformance fault: a state the page's own declarations foreclose, reached anyway — alerted, never a caller's fault.

Term allocation: one capability Capability's allocate committed.

Term revocation: one capability Capability's revoke committed to the revoked status.

Term consumed use: one redemption Capability's redeem answered redeemed.

#### Authorize Sharing

The allocation-with-attestation action: it parses the sharing descriptor by the sharing scope grammar, records the authorization intent under the allocator's credential — where the credential is verified — allocates a bearer capability whose scope *is* the authorized disclosure, and records the [Sharing Authorized] event under the allocator's own credential: intent, allocation, attestation, index, in that order (Action wiring 1 through 8, Action wiring 10, Action wiring 11, Invariant 3). Answers the authorization result, or [Invalid Sharing Descriptor] for a descriptor the grammar does not parse, leaves a required descriptor field blank or exceeds the descriptor cap (Primitive policy 5, 6 and 9).

Kind: Operation

#### Redeem And Disclose

The load-bearing emergent action: it resolves the descriptor, records the disclosure intent, redeems the capability **by possession alone**, commits a disclosure record with its pending marker, and seals the [Sharing Disclosed] event, in one transaction (Action wiring 12 through 32, Action wiring 34 through 36, Action wiring 38, Invariant 2). Answers the disclosure result, or the constituent's invalid carrying the redemption failure for a spent, lapsed, cancelled or unknown token, [Not Authorized Sharing] for a token this composition did not attest, redemption-unfulfilled when the use was consumed and Selective Disclosure refused the record, or storage-failure when a write fails and nothing commits. Records the allocator, never the redeemer (Invariant 1).

Kind: Operation

#### Revoke Sharing

The revocation action: it records a [Sharing Revocation Intended] event — where the revoker's credential is verified — closes the sharing capability early through Capability's revoke, and records a [Sharing Revoked] event under the revoker's credential (Action wiring 39 through 48). Later redemptions of the token answer invalid carrying revoked and disclose nothing.

Kind: Operation

#### Sharing Disclosures

The read-only query answering a subject's disclosure records joined to their authorizing allocator — never a redeemer (Action wiring 49 and 50). Records no event.

Kind: Operation

#### Authorization Provenance

The read-only query answering who authorized a given share, from the capability-to-sharing index (Action wiring 51, 52 and 56). Records no event.

Kind: Operation

#### Sharing Authorized

The Audit Trail event recorded at [Authorize Sharing], **attested under the allocator's own credential** — the allocator's non-repudiable commitment that they authorized this share (Invariant 3.3). The authorization half of the audit-subject asymmetry.

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (allocator-attested)
Projection: sharing.authorized

#### Sharing Disclosed

The Audit Trail event recorded at each [Redeem And Disclose] once Selective Disclosure records the disclosure, **attested under the service identity** — the allocator is absent and the bearer has no credential; it names the allocator reference and carries **no redeemer identity** (Invariant 1). The disclosure half of the asymmetry.

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (service-attested)
Projection: sharing.disclosed

#### Sharing Authorization Intended

The Audit Trail event [Authorize Sharing] records **before** it allocates, under the allocator's credential — what makes it provable that authentication preceded the allocation (Invariant 6.1). It deliberately carries **no capability token**, none existing when it is written; one with no [Sharing Authorized] event names an invocation that committed nothing, or the orphan the reconciliation pairs it to.

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, allocator-attested)
Projection: sharing.authorization_intended

#### Sharing Disclosure Intended

The Audit Trail event [Redeem And Disclose] records **before** the redemption, under the service identity, carrying no redeemer identity. **A recovery marker, not an authentication record** (Action wiring 24): it is trail-resident, so a consumed use whose disclosure or seal did not land can be reconciled from the trail rather than from this composition's derived state, and it carries no disclosure id, so no seal is ever built from it alone (Reconciliation 12).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, service-attested)
Projection: sharing.disclosure_intended

#### Sharing Revocation Intended

The Audit Trail event [Revoke Sharing] records **before** Capability's revoke, naming the token it is about to cancel, under the revoker's credential — a live sharing is never cancelled on an unverified claim (Invariant 6.2). Because it names the token, one with no [Sharing Revoked] event is classified directly against that capability's state (Check 5.4).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, revoker-attested)
Projection: sharing.revocation_intended

#### Sharing Revoked

The Audit Trail event recorded at [Revoke Sharing] after the capability is revoked, **attested under the revoker's own credential** and carrying the intent event id of its [Sharing Revocation Intended] event; a compensating one is attested under the service identity and carries the capability record's revoked by reference, the revoker's or, where the reconciliation revoked, the service identity's (Reconciliation 21).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (revoker-attested)
Projection: sharing.revoked

#### Intended Recipient

The sharing descriptor's **allocator-declared intended recipient** — the party the share was authorized to go to, recorded as the recipient of every disclosure. Deliberately *not* the bearer who presents the token, who is unknowable by design (Invariant 1.3).

Kind:       Field
Field of:   the sharing descriptor
Role:       the allocator-declared intended recipient
Projection: recipient

#### Disclosed Scope

The field subset the capability authorizes for disclosure — the minimum-necessary set — parsed from the capability's immutable scope by the sharing scope grammar. Every disclosure's scope equals it exactly (Invariant 4.1).

Kind:       Field
Field of:   the sharing descriptor
Role:       the authorized field subset
Projection: disclosed_scope

#### Invalid Sharing Descriptor

The composition's own refusal from [Authorize Sharing] for a descriptor the grammar does not parse, one leaving a required field blank, or one too long for the payload the events must carry (Primitive policy 5, 6 and 9). The share is refused before a capability is allocated.

Kind:       Member
Member of:  the authorize-sharing refusal
Role:       Rejection
Projection: invalid-sharing-descriptor

#### Not Authorized Sharing

The composition's own refusal from [Redeem And Disclose] for a token this composition cannot stand behind — an unparsed scope, an unattested token, or an irreconcilable one — refused before the redemption is touched, so no use is consumed and nothing is disclosed (Action wiring 15 through 22).

Kind:       Member
Member of:  the redeem refusal
Role:       Rejection
Projection: not-authorized-sharing

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Authorize Sharing]: #authorize-sharing
[Redeem And Disclose]: #redeem-and-disclose
[Revoke Sharing]: #revoke-sharing
[Sharing Disclosures]: #sharing-disclosures
[Authorization Provenance]: #authorization-provenance
[Sharing Authorized]: #sharing-authorized
[Sharing Disclosed]: #sharing-disclosed
[Sharing Disclosure Intended]: #sharing-disclosure-intended
[Sharing Authorization Intended]: #sharing-authorization-intended
[Sharing Revocation Intended]: #sharing-revocation-intended
[Sharing Revoked]: #sharing-revoked
[Intended Recipient]: #intended-recipient
[Disclosed Scope]: #disclosed-scope
[Invalid Sharing Descriptor]: #invalid-sharing-descriptor
[Not Authorized Sharing]: #not-authorized-sharing

---

## Standards references

Capability-Backed Sharing is the structural form of accountable bearer-token data sharing: share by possession, prove who authorized each disclosure. Its primary anchors:

- **GDPR (EU General Data Protection Regulation) Article 32 (Security of Processing)** — requires appropriate technical measures ensuring the confidentiality, integrity, and accountability of personal-data processing, including disclosures. This composition's allocation provenance (the immutable, attested allocator_ref), the sealed disclosure-accountability binding, and the bounded redemption envelope are the technical measures that make a bearer-token disclosure accountable; the [Sharing Authorized] / [Sharing Disclosed] records make the measure provable. (Article 30's records-of-processing and Article 15(1)(c)'s recipient-disclosure obligations are inherited through Selective Disclosure.)
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.514(d) (Minimum Necessary Standard)** — disclosures of protected health information must be limited to the minimum necessary. The capability's immutable `scope` encodes the minimum-necessary field subset, and Invariant 4 (scope-bounded disclosure) is the structural enforcement that the disclosure does not exceed it; the accounting-of-disclosures obligation (section 164.528) is inherited through Selective Disclosure and the substrate's six-year retention.
- **Object-capability (OCAP) model** — the foundational theory that an unforgeable reference carries its own authority and the holder's identity is irrelevant at use time (Dennis & Van Horn; Mark Miller's capability-security work; Levy, *Capability-Based Computer Systems*). This composition is the library's worked example of OCAP composed with regulated audit: it preserves the OCAP bearer semantics (no identity at redemption) intact while attaching accountability to the allocator — demonstrating that OCAP and regulated disclosure audit are compatible, the composition's thesis.

Capability-Backed Sharing inherits the broader standards compliance of its constituents:

- Through **Capability**: the OCAP literature (Jackson's *Software Abstractions* `Capability [Resource]` concept, Miller, Levy, Birgisson et al.'s Macaroons), RFC (Request for Comments) 6749 section 1.4 (OAuth 2.0 access tokens — the bearer-token-adjacent pattern), GDPR Article 32, HIPAA section 164.514(d).
- Through **Selective Disclosure**: GDPR Article 15(1)(c) and Article 30 (recipient disclosure and records of processing), HIPAA section 164.528 (accounting of disclosures), SEC (US Securities and Exchange Commission) Rule 17a-4 — the disclosure-accounting layer.
- Through the **Audit Trail substrate** (and transitively Event Log, Actor Identity, Tamper Evidence, Retention Window): SOX (Sarbanes-Oxley Act) section 404/section 802, HIPAA section 164.312(b)/section 164.530(j), PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR (US Code of Federal Regulations) Part 11, SEC Rule 17a-4, ISO/IEC 27001 clause A.12.4, GDPR Articles 30 and 32 — the attributed, retained, tamper-evident record the sharing events land on.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — capability-backed-sharing.tla + 2 twins, 2026-08-27
last gate: 2026-10-27 — Final Critique 7 — foundational count 5, not clean, no sample

open:
- 2026-08-29-r · refining · formal · the model's compensation carries no identity, no recovery record, and no age bound; the twins predate the scan's horizon edge → extend the model with the service-identity compensation behind `sharing.recovery_intended` and the scan's horizon edge
- 2026-10-27-a · refining · Invariant 1.3 · Selective Disclosure's Term recipient is the party the data reached (its term entry: the party the data was disclosed to), and the composition records the intended recipient, whom a bearer's redemption need not reach → Selective Disclosure decides what its recipient carries, which this page may not change (Composes 4)
- 2026-10-27-b · foundational · Composition state 3, 6, 7 · an entry rebuilt after its authorization event aged must carry the authorization event id (3), must be rebuilt (6), and may not take the id from the aged event (7) → decide whether such an entry is rebuilt without the id, narrowing Composition state 3 and Invariant 3.2, or not rebuilt, narrowing Composition state 6 and with it Action wiring 17 and 56
- 2026-10-27-c · refining · Reconciliation 18 · the reconciliation's revoke names no revoked by reference and no revocation reason, and Capability refuses a blank one (Capability Operation 39, 40) → name both
- 2026-10-27-d · foundational · Audit arm 8 · a recording failure at a refusal event or an unfulfilled event lands as recording-failure carrying outcome AND the orphan reference, which names a disclosure id neither path has, and a refusal event follows a redemption that consumed nothing → name each path's position and reference; waits on the maintainer's question whether a refused outcome leaves the act's other writes committed (rounds/escalations.md, Multi-Party Approval, 2026-10-26)
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/capability-backed-sharing.md`; the migration that got it here is in [its history](./capability-backed-sharing.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated, and a sharing action's writes one transaction.** *Chose:* Capability requirement 18 citing Execution Contract Store 1 through 4 for the store the three constituents and the two indexes keep their records in; the rules restating what that store guarantees tombstoned to it (Composition state 11, 15, External check 6, Atomic writes 1, Concurrency 1, 2); the four that kept the Audit Trail append and Capability's redeem out of the action's transaction, or denied that its writes commit together, which Store 1 as ruled contradicts (Wiring decision 3, 4, Atomic writes 2, 3); and the machinery that existed only because a crash, a split write or an invocation seen between its writes could leave a partial: the reconciliation's run at every process start, its lower edge and the auditor's inconclusive reading below it, the redemption completion bound with the slowest conforming invocation it bounds and the refusal to start without it, the in-invocation retries of the authorization, unfulfilled and disclosure events, the read-back of a recording-failure at the substrate's retention step, which Audit Trail's own rewrite made commit nothing, and an invalid-credential at a human-attested outcome, which the one transaction's read of the actor registry forecloses (Reconciliation 1, 3, Check 6.6, Capability requirement 10, 11, 13, Action wiring 9, 33, 37, Audit arm 3, 5, 18, 9). Rules 236 to 214. *Over:* an Audit Trail append and a Capability redeem no host transaction could enlist, so that each action was ordered across durability boundaries, the disclosure committed first and sealed second, with a process-start run, an in-flight edge and in-invocation retries against what a crash between the writes left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal. The redeem and the append are store writes, Capability and Audit Trail each supplying theirs under Store 1 through 4, so a sharing action's intent, constituent writes and outcome commit together, and the wiring decision's second half, the ordering, goes. An Audit Trail refusal at an outcome record still leaves the act committed and its record owed (Audit arm 13, 20), as Audit Trail's own refusals leave their evidence (Audit Trail record action step 7.11), so what closes it stays: the pending marker, the disclosure intent a compensating seal is built from, the pairing of authorization intents, the three-direction reconciliation, its window and its escalation. The capability-to-sharing index stays a derived index outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps it, so its rebuild-on-miss, the refusal of a token the rebuild finds no entry for and revocation ungated by the index stay; the sealed disclosure-to-redemption entry keeps its named rebuild (Composition state 16), the derivation obligation 1 of that section asks of a derived index. Under Store 1 a Selective Disclosure storage failure fails the whole redemption, so the unfulfilled path answers only a refusal the descriptor's validation forecloses (Action wiring 31, 32), and the disclosure event follows Selective Disclosure's answer inside the one transaction (Action wiring 36). Sharing events are ordered by the substrate's sequence numbers and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-08-29 — The scan is bounded at both edges, writes as the composition behind a recovery record, and an attestation nobody can re-derive is not re-emitted.** *Chose:* a declared `redemption_completion_bound` below which no direction of the scan examines anything, with the audit horizon above (a marker still pending there is escalated, never sealed); every scan write attested under the service identity behind a `sharing.recovery_intended` record, the revoker carried as `revoked_by` on a compensated [Sharing Revoked]; an unattested capability recovered by attestation only inside the invocation that holds the allocator's credential and by revocation once it is gone; every intent-record transcription carrying `recording-failure(step)` and [Revoke Sharing]'s outcome arms enumerated; `index_durability` declared and the two window knobs moved into Configuration; and a stale duplicate step 3 of [Redeem And Disclose] — the pre-repair wiring, which still described the decrement rolling back with a transaction — deleted. *Over:* an unbounded scan under an unnamed identity, and "retry the attestation" as a crash recovery. *Because:* an unbounded scan seals beside the seal an in-flight invocation is about to append and lands redemption-unfulfilled for a use whose disclosure is about to commit; a compensation the absent actor did not make cannot be attested as theirs; and an attestation under the allocator's credential is precisely the thing no one else can produce (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).
- **2026-08-29 — The redemption is irreversible, the intent precedes it, and the third partial is landed rather than sealed.** *Chose:* [Redeem And Disclose] resolves the descriptor by the instance's declared token read, records intent, then redeems, then commits the disclosure with its marker, then seals; a consumed use with no disclosure is redemption-unfulfilled, never a fabricated seal; the pending marker is truth-bearing under a durability obligation and the only source a seal is written from; the Capability instance is exclusive; the `(step)` payload governs every retry. *Over:* a decrement described as rolling back with the transaction, a reconciliation that sealed every counter shortfall, a shared instance with a "foreign token" reading, and step-less retries. *Because:* Capability declares no enlistment or undo, so the rollback was attributed to a capability the atom does not have; sealing a shortfall appended seals for disclosures that never happened; a shared instance consumed foreign tokens on refusal and convicted them in the counter checks; and a step-less retry duplicated outcome events after a retention-arm failure.
- **2026-08-27 — The disclosure is durable intent, then a transactional domain mutation, then a durable outcome — never one atomic set.** *Chose:* [Redeem And Disclose] writes a `[Sharing Authorization Intended]` event, commits the Selective Disclosure record with a pending marker in its own transaction, then appends the `[Sharing Disclosed]` outcome; Invariants 2 and 3 are stated as ordering plus reachable partials plus recovery. *Over:* the original claim that the record, the event and the index commit "together or not at all" under a host transaction. *Because:* an Audit Trail append cannot be enlisted or withdrawn, so a host transaction aborting after the append left the trail asserting a disclosure the store denied — a real design defect, not editorial debt. The rule generalizes: never include an independently durable append in a host transaction's atomic set.

</details>

NOTE: End of Capability-Backed Sharing.

---
title: Capability-Backed Sharing
id: 15
audience: common
nav_order: 23
---

# Capability-Backed Sharing

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## Summary

Capability-Backed Sharing is a regulated composition — a specification that wires several freestanding patterns together — that solves a problem that looks impossible at first: how to share data using a "bearer token" (a link or token where simply holding it grants access, no login required) while still keeping the strict disclosure records that privacy laws demand. The apparent contradiction is that bearer tokens deliberately don't check who's using them, but regulators want to know who's accountable for every disclosure.

This composition's insight is that the accountable party isn't the person who *used* the token — it's the person who *issued* it. So it records, with a cryptographic attestation that lasts as long as the audit record is kept, who authorized the share (the allocator), to whom they authorized it, what data, under what legal authority, and for how long — never longer than the record of that authorization is kept (the ttl cap), so a token allocated under the cap does not outlive it — captured at the moment of issuance when that person is present to sign for it. When the token is later redeemed, the disclosure is logged against that authorizer, and the person who actually presented the token is — by design — never named, because the bearer model never asked.

The composition's defining emergent guarantee is exactly this audit-subject asymmetry: the record always answers "who authorized this disclosure?" and never answers "who redeemed it?". Its second guarantee is about how that record and its tamper-evident seal (a cryptographic proof that the record has not been altered) are written: the disclosure record and the use it consumes are written in one transaction, so a seal written by the action or by its recovery always has a real disclosure behind it, and where the audit trail refuses the seal, the one gap that remains — a disclosure whose seal has not yet landed — is always visible as an open intent, and is repaired by [Durable Intent](../atoms/durable-intent.idd)'s sweep, or escalated to an operator, within its closure window.

Its common uses are exactly the places bearer sharing and regulated audit collide: a hospital sharing a scoped slice of a patient record with a referred specialist via a time-limited link (the minimum-necessary fields, logged against the authorizing clinician), a bank issuing a pre-signed link to disclose a customer's transaction subset to an auditor, or a controller sharing specific personal-data fields with a processor under a consent record. Any system that must share data by token *and* make it provable who authorized each disclosure — without being able to (or wanting to) name who consumed it — is a candidate for this composition.

---

## Intent

Two correct designs appear to contradict each other, and reconciling them is the friction this composition exists to resolve. The **object-capability (OCAP — a security model in which an unforgeable reference to a resource carries its own authority)** model says: a bearer token *is* the authorization; whoever holds it may act, and asking *who* is holding it defeats the purpose — a password-reset link, a pre-signed download URL, a scoped API (Application Programming Interface) token all work precisely because no per-redemption identity check happens. The **regulated-disclosure** model says the opposite: every disclosure of a data subject's information must be *accountable* — a regulator asking "who authorized this disclosure, and under what authority?" must get a provable answer. A naive reading concludes you cannot have both: either you check identity at the point of access (and lose bearer semantics) or you don't (and lose accountability). This composition shows the reading is wrong, and naming *why* is the composition's contribution.

The resolution is an **asymmetry of audit subjects**. Accountability does not require naming the *redeemer*; it requires naming the *authorizing party* — and those are two different actors at two different moments. The authorizing party is the **allocator**: the data controller (or their delegate) who decided that a specific subset of a subject's data may be shared, with a named addressee, under a named legal authority, for a bounded number of redemptions, for a bounded time. That decision happens at *allocation*, when the allocator is present and can be cryptographically attested under their own credential. The *redeemer* is whoever later presents the token — and by the bearer-token design, their identity is neither checked nor recorded. This composition's audit record therefore reads "**disclosed under authority of allocator X, who authorized this share at time T**," never "redeemed by Z." The allocator is fully accountable (Capability records the allocator immutably and only the allocator — Capability Invariants 1 and 5; this composition additionally attests the allocator at allocation); the redeemer is structurally unnamed (Capability performs no identity check at redemption — Capability Invariant 3). Regulated audit is satisfied by the allocator's accountability; bearer semantics are preserved by the redeemer's anonymity. Neither model is broken.

This reframe carries a precise consequence for what the disclosure record names as **recipient**. The bearer who actually presents the token is unknowable by design; what the record names is the **addressee the allocator declared at allocation time**. The disclosure was *authorized to go to* recipient R; whether the actual bearer was R, R's delegate, or a party who obtained the token improperly is exactly the question bearer semantics make unanswerable — and the records are honest about that boundary (it is the forensic limit Capability's own disputed-disclosure scenario names). The composition records who *authorized* the disclosure and to *whom it was authorized*, not who *consumed* it.

No single constituent resolves this. Capability is the bearer-token primitive — it records the allocator, authorizes by possession, and refuses to record a redeemer — but it does not record *that a disclosure occurred*, does not carry the legal authority for the disclosure, and is not tamper-evident. Selective Disclosure is the disclosure-accounting record — to whom, what scope, under what authority, when — but it does not gate access, does not carry a redemption envelope (how many times, until when), and its append-only immutability is by specification, not cryptographically sealed. Audit Trail is the tamper-evident, attributed, retained substrate — but it knows nothing about bearer tokens or disclosure scope. The structure that allocates a bearer token whose scope *is* an authorized disclosure, performs the disclosure on redemption, records it accountably to the allocator while naming no redeemer, and seals the whole thing belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Capability, Selective Disclosure, Audit Trail and Recoverable Invocation are unchanged; this composition is the wiring that makes them coherent as one accountable-bearer-sharing surface. It introduces emergent actions — [Authorize Sharing] (allocate the capability and attest the allocator's authorization), [Redeem And Disclose] (the load-bearing surface: redeem by possession, then record the disclosure and seal it), [Revoke Sharing], and read-only queries — that belong to no single constituent. What it is *not*: it is not an identity-keyed access control surface (that is Permissions — this composition is bearer-keyed by design); it is not the disclosure-delivery mechanism (it records *that* and *to whom authorized* a disclosure occurred; retrieving, redacting, and transmitting the bytes is the host's job, exactly as Selective Disclosure records without performing); it is not the adjudicator of whether the declared authority is legally valid (that legitimacy is an externally-clearable check, as in Selective Disclosure and Resolve a Person's Data Rights); and it does not — cannot — identify the redeemer (the bearer-key design forecloses it). Each is named in Non-goals.

---

## Composes

- **[Capability](../atoms/capability.idd)** — the bearer-token primitive and the source of the audit asymmetry.
- **[Selective Disclosure](../atoms/selective-disclosure.idd)** — the disclosure-accounting record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every authorization, disclosure and revocation is sealed through.
- **[Durable Intent](../atoms/durable-intent.idd)** — the protocol the three acting actions follow around their constituent writes: an intent before the write, an outcome after it, and a sweep that closes the record of a write whose outcome never landed; this pattern restates none of it. The protocol's bindings and the instance's start are [Recoverable Invocation](../apps/recoverable-invocation/index.md)'s.
- **[Sweep](../atoms/sweep.idd)** — the clean-up run of the same protocol: it closes what an invocation left open, from what the adopter's database can say; this pattern restates none of it.
- **[Escalation](../atoms/escalation.idd)** — the operator's closing and the findings of the same protocol; this pattern restates none of it.

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
Composes 12: The composition MUST read the substrate's events through the Event Log instance Audit Trail carries, by an open-ended sequence range, as a declared direct invocation PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST NOT record a second disclosure record for a consumed use (Selective Disclosure Composition note 7).
Composes 16: EXACTLY ONE Durable Intent instance MUST serve the composition.
Composes 17: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 18: The composition MUST bind the act kinds PER the sharing bindings.
Composes 19: The composition MUST NOT bind an action other than a sharing action as an act kind.
Composes 20: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
Composes 21: EXACTLY ONE Sweep instance MUST serve the composition.
Composes 22: EXACTLY ONE Escalation instance MUST serve the composition.
```

Term composition: this pattern's wiring of [Capability](../atoms/capability.idd), [Selective Disclosure](../atoms/selective-disclosure.idd), the [Audit Trail](./audit-trail.md) substrate and [Durable Intent](../atoms/durable-intent.idd), [Sweep](../atoms/sweep.idd) and [Escalation](../atoms/escalation.idd) — the five actions, the two indexes, the sharing scope grammar, the sharing bindings and the write-ownership leg.

Term constituents: [Capability](../atoms/capability.idd), [Selective Disclosure](../atoms/selective-disclosure.idd), [Audit Trail](./audit-trail.md), [Durable Intent](../atoms/durable-intent.idd), [Sweep](../atoms/sweep.idd) and [Escalation](../atoms/escalation.idd).

Term transitive atoms: [Event Log](../atoms/event-log.idd), [Actor Identity](../atoms/actor-identity.idd), [Retention Window](../atoms/retention-window.idd) and [Tamper Evidence](../atoms/tamper-evidence.idd), reached through Audit Trail, and [Lease](../atoms/lease.idd), reached through Recoverable Invocation.

Term substrate: the Audit Trail instance serving the composition.

Term trail: the substrate's events, in sequence order, as the composition and an auditor read them.

Term sharing action: [Authorize Sharing], [Redeem And Disclose] or [Revoke Sharing].

Term act kind: sharing.authorize, sharing.disclosure or sharing.revocation — the three act kinds this composition binds on its Recoverable Invocation instance, one per sharing action, each with its own commit, outcome reference and probe.

Term sharing bindings: each act kind's bindings, under the name Recoverable Invocation gives each. For sharing.authorize: act key — the authorization key; commit — Capability's allocate; journal events — sharing.authorize.intended, the one outcome sharing.authorize.authorized, sharing.authorize.refused; act probe — the authorization probe; actor at the open and the close — the allocator. For sharing.disclosure: act key — the disclosure key; commit — the disclosure transaction; journal events — sharing.disclosure.intended, the one outcome sharing.disclosure.disclosed, sharing.disclosure.refused; act probe — the disclosure probe; actor at the open and the close — the redemption identity. For sharing.revocation: act key — the token digest; commit — Capability's revoke; journal events — sharing.revocation.intended, the one outcome sharing.revocation.revoked, sharing.revocation.refused; act probe — the revocation probe; actor at the open and the close — the revoker. For all three: pairing datum — the invocation's now, which the host injects into Capability's seam and Selective Disclosure's seam and the composition passes to Selective Disclosure's record as disclosed_at, so that the allocation instant, the revocation instant or the disclosure instant equals it (Capability requirement 22); repeatable — yes; invocation completion bound — the authorization, the redemption or the revocation completion bound; commit round trip and probe round trip — the deployment's disclosed bounds; journal — the composition's Audit Trail instance; retention period — the audit horizon; settling period — the deployment's settling period; service identity — the recovery identity; outcome envelope — sized from the descriptor cap and the minted widths (Term descriptor cap).

Term token digest: the digest of a capability token, computed at the seam (Execution Contract Logic confinement 8); every intent, event, index entry and alert of the composition carries it in place of the token, and every rule that keys, compares or names a capability token of one of them reads it, so no record of the composition is the live bearer credential (Execution Contract Logic confinement 21). The deployment answers the same digest beside every capability record a read of Capability answers (Capability requirement 36), so Recoverable Invocation act probe 8 holds for the revocation kind's key. [Authorize Sharing] answers the token itself to the caller who holds it (Action wiring 11), and Capability's own record keeps it (Capability Identity 1).

Term authorization key: the allocator reference and the encoded sharing descriptor, in that order. The capability token is minted by the allocate, so it is not known at the open — the minted-key deviation (Recoverable Invocation Deviation 4), declared here in full, by the same deviation Immutable Ledger's act key makes. Capability never refuses a second allocate of one scope, so two authorizations of one key are two acts, repeatable being yes.

Term disclosure key: the subject reference, the addressee, the disclosed scope and the authority the sharing descriptor carries, in that order — the same key Immutable Ledger's act uses, written out here. The disclosure id is minted by the disclosure transaction, which is the minted-key deviation (Recoverable Invocation Deviation 4); the capability token does not key the act, since the disclosure record does not carry it (Recoverable Invocation act probe 8). Two redemptions of one share carry one key and take the critical section in turn, a second bearer meeting act-in-flight while the first stands open; two redemptions of one key that both commit are two acts, repeatable being yes. The key names no token and no allocator, so two tokens of one descriptor, whatever their allocators, carry one key: a redemption of either meets act-in-flight while an intent of the other stands open, and meets none once the sweep has escalated that intent, an escalation closing it (Durable Intent Term open invocations). The hold is the accepted fail-closed behavior for as long as it lasts: one share's redemptions stay in turn while one redemption's invocation is open, and keying the act by the token would leave the pending entry's key without a record that carries every field (Recoverable Invocation act probe 8).

Term disclosure transaction: Capability's redeem of the capability token, then, on redeemed, Selective Disclosure's record and the pending disclosure-to-redemption entry, committed together or not at all (Execution Contract Database 1) — the one commit Recoverable Invocation's bound commit stands for for sharing.disclosure (Composition notes).

Term commit partition: committed where the commit answers its record — the allocate a capability token, the disclosure transaction a disclosure id, the revoke revoked; pre-commit where Capability refuses the write — an allocate's invalid-request, a redeem's invalid carrying the redemption failure, which consumes nothing (Capability Operation 31), a revoke's not-known, already-terminal or invalid-request — where Selective Disclosure refuses the record inside the disclosure transaction, which then commits nothing (Action wiring 31), where a constituent answers storage-failure (Execution Contract Constituent failure 1), where the pending entry's write fails, the disclosure transaction then committing nothing and answering storage-failure (Execution Contract Database 1, Read 4), or where the database answers state-unavailable (Execution Contract Constituent failure 3); unknown where a call answers a code its constituent does not declare, or where its reply has not arrived when the commit round trip has elapsed since the call's issue (Recoverable Invocation commit 6, commit 7).

Term authorization probe: the read that answers whether an open authorization intent's capability committed. Capability's read filtered to the intent's allocator reference, kept in the composition's code to the capabilities whose scope equals the intent's encoded sharing descriptor and whose allocation instant equals the intent's pairing datum. Exactly one answers committed carrying the token digest, the allocator reference, the sharing descriptor parsed back, the max redemptions, the ttl the expiry instant and the allocation instant give, and the allocation instant; none answers not-committed; more than one answers undecidable carrying them; a read refused or unanswered answers unavailable (Recoverable Invocation act probe 2 through 4; Deviation 4b).

Term disclosure probe: the read that answers whether an open disclosure intent's disclosure committed. Selective Disclosure's read filtered to the intent's subject reference, addressee and the intent's pairing datum as the disclosure instant range, kept in the composition's code to a record whose scope and authority equal the intent's — the filter Immutable Ledger's disclosure probe applies, written out here. Exactly one answers committed carrying the disclosure id, the subject reference, the recipient, the scope, the authority and the disclosure instant, with the token digest and the allocator reference the pending disclosure-to-redemption entry the disclosure transaction wrote for the disclosure id names (Composition state 12); none answers not-committed; more than one answers undecidable carrying them; either read refused (invalid-query) or unanswered answers unavailable (Recoverable Invocation act probe 4), and an invalid-query is surfaced on the finding surface.

Term revocation probe: the read that answers whether an open revocation intent's revoke committed. Capability's read naming no field, kept in the composition's code to the capability whose token digest equals the intent's (Capability requirement 36): a capability standing revoked whose revocation instant equals the intent's pairing datum and whose revoked by reference and revocation reason equal the intent's answers committed carrying the token digest, the revoked by reference, the revocation reason and the revocation instant; a capability not revoked, revoked at another instant, or revoked at the intent's pairing datum with a revoked by reference or a revocation reason different from the intent's, answers not-committed; a read refused or unanswered answers unavailable.

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the capability-to-sharing index.
Composition state 2: The composition MUST key the capability-to-sharing index by the token digest.
Composition state 3: A capability-to-sharing entry MUST carry the allocator reference, the subject reference, the addressee, the disclosed scope, the authority, the authorization event id AND the allocation reading.
Composition state 4: The composition MUST write a capability-to-sharing entry ONLY AFTER the authorization event lands.
Composition state 5: IF no diverged entry EXISTS for the capability token THEN the composition MUST NOT change the token's capability-to-sharing entry.
Composition state 6: IF no capability-to-sharing entry EXISTS for a capability token AND the token's authorization event IS NOT IN the aged events THEN the composition MUST rebuild the capability-to-sharing entry from the authorization events carrying no recovery flag.
Composition state 7: IF a capability token's authorization event IS IN the aged events THEN the composition MUST NOT rebuild the token's capability-to-sharing entry.
Composition state 8: The composition MUST store the disclosure-to-redemption index.
Composition state 9: The composition MUST key the disclosure-to-redemption index by disclosure id.
Composition state 10: A disclosure-to-redemption entry MUST carry the token digest, the allocator reference, the intent event id, the invocation id, the seal marker AND the disclosure reading.
Composition state 12: The composition MUST write a disclosure-to-redemption entry carrying pending as the seal marker inside the disclosure transaction.
Composition state 13: The composition MUST set the seal marker to the disclosure event's id ONLY AFTER the disclosure event lands.
Composition state 14: The composition MUST NOT carry a redeemer identity in either index.
Composition state 16: The composition MUST rebuild a sealed disclosure-to-redemption entry from the disclosure events, the ones carrying the recovery flag included.
Composition state 17: IF the disclosure-to-redemption rebuild finds a disclosure event naming no disclosure record OR two disclosure events naming one disclosure id THEN the composition MUST alert the finding surface carrying the disclosure id.
Composition state 18: IF the capability-to-sharing rebuild finds two authorization events carrying one capability token THEN the composition MUST alert the finding surface carrying the token digest AND the rebuild MUST bind the first authorization event carrying no recovery flag by sequence number, none where every such event carries the recovery flag.
Composition state 19: IF the disclosure-to-redemption rebuild finds two disclosure events naming one disclosure id THEN the rebuild MUST bind the first by sequence number.
Composition state 20: The composition MUST NOT store a record of the Recoverable Invocation instance.
Composition state 21: IF a capability token's authorization event IS IN the aged events THEN the composition MUST answer the token as carrying no capability-to-sharing entry.
Composition state 23: IF an action reads a disclosure-to-redemption entry that EQUALS a pending marker AND a disclosure event names the disclosure id the entry is keyed by THEN the action MUST decide ONLY AFTER the action rebuilds the entry from the disclosure events (Composition state 16, Execution Contract Derived index 1).
Composition state 22: IF no disclosure-to-redemption entry EXISTS for a disclosure id AND no disclosure event names the disclosure id AND a sharing.disclosure intent carries the disclosure record naming the disclosure id THEN the composition MUST rebuild the entry from the record AND that intent, the entry carrying pending as the seal marker.
```

Term capability-to-sharing index: the composition's map from a capability token to the share it authorizes — the authorization-provenance index.

Term disclosure-to-redemption index: the composition's map from a disclosure id to the capability, the allocator and the intent behind the disclosure.

Term seal marker: pending | the disclosure event's id — pending while a committed disclosure's seal has not landed.

Term pending marker: a disclosure-to-redemption entry whose seal marker EQUALS pending.

Term allocation reading: the invocation's now at [Authorize Sharing] — the authorization intent's pairing datum, which the capability's allocation instant equals (Execution Contract Logic confinement 19); stamped on the authorization event and the index entry.

Term disclosure reading: the invocation's now at [Redeem And Disclose] — the disclosure intent's pairing datum, passed to Selective Disclosure's record as disclosed_at, so that the disclosure record's disclosure instant equals it (Action wiring 29, Execution Contract Logic confinement 19); stamped on the pending marker and the disclosure event.

Term addressee: the recipient the allocator declared in the sharing descriptor — who the share was sent to, never the bearer who presents the token, and not Selective Disclosure's Term recipient, the party the data reached — an [Addressee].

Term disclosed scope: the field subset a capability authorizes for disclosure, parsed from the capability's immutable scope by the sharing scope grammar — a [Disclosed Scope].

Term seal alert: the alert Composition state 17 raises — an operator's disclosure outcome naming no disclosure record, or a second for one.

Term duplicate-authorization alert: the alert Composition state 18 raises — an operator's authorization outcome naming a token another authorization event names.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the capability-to-sharing index: derived index over the authorization events carrying no recovery flag (Composition state 6), unrebuildable past the audit horizon, its entry neither rebuilt (Composition state 7) nor read (Composition state 21), so [Authorization Provenance] answers not-known for the token (Action wiring 52) and a redemption answers not-authorized-sharing (Action wiring 18); a redemption reads the index only for a token Capability answers allocated (Action wiring 65, 66), and the ttl cap ends such a token's life before its authorization event ages (Term ttl cap) for the audit horizon and clock offset allowance the token was allocated under, which Execution Contract Logic confinement 17 holds only until the next start, so it meets the unrebuildable entry for a token allocated before the cap with a longer ttl, or after a restart shortened either setting; a disclosure-to-redemption entry: derived index over the disclosure intent and the disclosure record while it is a pending marker (Composition state 22), every field it carries standing in the intent's payload or the record, derived index over the disclosure events once sealed (Composition state 16), and extraction-pending against [Erasure Tombstone](../atoms/erasure-tombstone.idd) past the audit horizon (Capability requirement 5). Recoverable Invocation's maps and findings register are that instance's state, reached through the instance (Composition state 20).

---
### Capability requirement

```
Capability requirement 1: A deployment MUST declare the sharing scope grammar.
Capability requirement 2: A deployment MUST provision the redemption identity as a registered actor whose actor reference DOES NOT EXCEED the reference length cap (Durable Intent Primitive policy 8).
Capability requirement 3: A deployment MUST rotate the redemption identity's credential.
Capability requirement 4: A deployment MUST configure the Audit Trail instance with the audit horizon.
Capability requirement 5: The longest disclosure-accounting obligation MUST NOT EXCEED the audit horizon.
Capability requirement 6: A deployment MUST set the default max redemptions.
Capability requirement 14: The host MUST inject now, the invocation id, the run id AND the operator run id at the seam once PER invocation.
Capability requirement 15: The composition MUST take EXACTLY ONE now PER invocation.
Capability requirement 17: The composition MUST NOT mint an id.
Capability requirement 18: The deployment MUST supply the database PER Execution Contract Database 1 through 4, AND the act section PER Execution Contract Database 7 AND Execution Contract Refusal 1 (Recoverable Invocation Capability requirement 12).
Capability requirement 22: The host MUST inject the invocation's now into Capability's seam AND Selective Disclosure's seam for the commit of a sharing action AND for the read of Action wiring 13 PER Execution Contract Logic confinement 19.
Capability requirement 23: The host MUST NOT inject an equal now into two invocations of the instance, whatever the act key and whatever node each runs on, since the host cannot read an act key at the seam.
Capability requirement 24: IF a required setting EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 25: A deployment MUST set the authorization completion bound, the redemption completion bound AND the revocation completion bound.
Capability requirement 26: A deployment MUST provision the recovery identity as a registered actor other than the redemption identity, whose actor reference DOES NOT EXCEED the reference length cap (Durable Intent Primitive policy 8).
Capability requirement 27: A deployment MUST rotate the recovery identity's credential.
Capability requirement 28: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 29: A deployment MUST disclose the commit round trip, the probe round trip AND the settling period.
Capability requirement 30: A deployment MUST set the instance's bounds PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 31: A deployment MUST NOT remove a constituent record BEFORE the audit horizon destroys the payload of the record's outcome (Recoverable Invocation Binding 9).
Capability requirement 32: A deployment MUST set the intent candidates cap.
Capability requirement 33: IF the default capability ttl EXCEEDS the ttl cap THEN the composition MUST refuse to start.
Capability requirement 34: The host MUST inject the now of the sweep run Reconciliation 2 pairs at the reconciliation's seam once PER reconciliation run.
Capability requirement 35: The host MUST inject the token digest of EVERY capability token a call presents AND of EVERY capability token Capability's allocate mints, PER Execution Contract Logic confinement 8 AND Execution Contract Logic confinement 21.
Capability requirement 36: The deployment MUST answer, beside every capability a read of Capability answers, the token digest of the capability's token.
Capability requirement 37: A deployment MUST set the cut-over instant.
Capability requirement 38: A deployment MUST declare the fixed-field bound.
```

Term sharing scope grammar: the deployment-declared grammar that encodes a sharing descriptor as a capability scope and parses a capability scope back into the sharing descriptor — one grammar, read in both directions.

Term sharing descriptor: the subject reference, the addressee, the disclosed scope and the authority — what a capability's scope means to this composition.

Term redemption identity: the composition's own registered actor and credential, application_actor_ref and application_credential — the actor reference and credential [Redeem And Disclose] passes to the invocation open, under which the disclosure intent, its outcome and its refusal record are attested, the bearer presenting none.

Term recovery identity: a deployment-provisioned actor reference and credential, recovery_identity — the service identity of the three act kinds, under which Recoverable Invocation's sweep attests every write it makes for them (Recoverable Invocation service identity 3), never the redemption identity, since the invocation open refuses an actor reference naming a kind's service identity.

Term audit horizon: Audit Trail's Term retention period of the retention policy the wired Audit Trail instance places a sharing event under, a duration counted from the event's recording instant — the earliest instant Audit Trail's record_destruction may destroy the event's payload; this page's own term, and not Audit Trail's Term audit horizon, which runs to the latest purge deadline.

Term longest disclosure-accounting obligation: the longest a regulation in force obliges an accounting of the disclosed data to survive — six years under the HIPAA (US Health Insurance Portability and Accountability Act) accounting of disclosures, the typical floor.

Term default max redemptions: the max redemptions [Authorize Sharing] passes to Capability's allocate where the call supplies none — a whole number of one or more, inside Capability's own bounds.

Term ttl cap: `(audit horizon - (2 * clock offset allowance))` — the longest effective ttl the composition allocates, so that no live token outlives the record of its authorization. A capability allocated at its allocation instant lapses at its expiry instant (Capability Term lapsed), and its authorization event becomes an aged event at its recording instant plus the audit horizon less one clock offset allowance (Term aged event). The authorization event the allocating call's close writes carries that call's one injected reading, the allocation instant itself (Execution Contract Logic confinement 19), and a recovered event takes the reading of the later call that wrote it, so the stamp is no earlier than the allocation instant less one clock offset allowance; the cap spends that allowance and the aged event's, and an expiry instant no later than `((allocation instant + audit horizon) - (2 * clock offset allowance))` comes no later than the aged event's instant. Both Capability's lapse and Term aged event hold from the instant they reach, so a ttl equal to the cap is sound: the token lapses no later than the instant its authorization event ages. The cap takes no run bound: no reading of the sweep or of the reconciliation compares against a token's expiry instant or its authorization event.

Term authorization completion bound: the deployment's declared maximum for an [Authorize Sharing] invocation — sharing.authorize's invocation completion bound: the longest it takes from the invocation open's take of the critical section to the invocation close's last write (the invocation yield's return where the commit answers an unknown arm), Capability's round trip included.

Term redemption completion bound: sharing.disclosure's invocation completion bound, read as Term authorization completion bound reads, the disclosure transaction's round trip included.

Term revocation completion bound: sharing.revocation's invocation completion bound, read as Term authorization completion bound reads, Capability's revoke round trip included.

Term required setting: the sharing scope grammar, the audit horizon, the default max redemptions, the default capability ttl, the three completion bounds, the intent candidates cap, the commit round trip, the probe round trip, the settling period, the redemption identity, the recovery identity, the cut-over instant and the fixed-field bound.

Term fixed-field bound: the deployment's declared maximum, counted as the substrate counts a payload, of the fixed fields of the largest event this composition records — what the substrate adds to an event's payload.

Term cut-over instant: the instant the composition bound its act kinds on the instance — a capability, a revocation or a disclosure record whose instant PRECEDES it was written before any intent of this protocol existed and carries the earlier vocabulary and no intent, so the reconciliation reads none of them (Term aged record, Reconciliation 30).

Term constituent record: a capability record or a disclosure record.

Term reconciliation run bound: Recoverable Invocation's run bound on this composition's instance, inside which the write-ownership leg runs.

Term intent candidates cap: Recoverable Invocation's intent candidates cap on this composition's instance — the most database candidates an escalation names.

Term clock offset allowance: the deployment's one clock allowance (Execution Contract Logic confinement 18), which Recoverable Invocation names its clock allowance on this composition's instance and every comparison of this page spends.

Term invocation id: the fresh id the host injects at the seam per sharing action, carried by every record the invocation writes (Durable Intent Term invocation id).

Term commit round trip: the deployment's disclosed bound on one commit, from issue to reply — Capability's allocate, the disclosure transaction, or Capability's revoke.

Term probe round trip: the deployment's disclosed bound on one act probe, from issue to answer.

Term settling period: the time the deployment declares for an operator to settle an escalated act through the invocation resolve (Recoverable Invocation Term settling period).

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank allocator reference.
Primitive policy 2: The composition MUST answer invalid-request for a blank credential.
Primitive policy 3: [Authorize Sharing] MUST answer invalid-request for an out-of-bounds envelope.
Primitive policy 4: [Revoke Sharing] MUST answer invalid-request for a blank revocation input.
Primitive policy 5: [Authorize Sharing] MUST answer invalid-sharing-descriptor for a descriptor whose encoding the sharing scope grammar does not parse back into the same sharing descriptor (Primitive policy 7).
Primitive policy 6: [Authorize Sharing] MUST answer invalid-sharing-descriptor for a descriptor carrying a blank required descriptor field.
Primitive policy 7: The sharing scope grammar MUST parse the encoding of a sharing descriptor back into the same sharing descriptor.
Primitive policy 8: IF the descriptor's authority type IS NOT IN the authority types THEN [Authorize Sharing] MUST answer unknown-authority-type.
Primitive policy 9: IF the encoded descriptor EXCEEDS the descriptor cap OR a required descriptor field EXCEEDS Selective Disclosure's string cap THEN [Authorize Sharing] MUST answer invalid-sharing-descriptor.
Primitive policy 10: The composition MUST compare a capability token byte-exact.
Primitive policy 11: The composition MUST NOT normalize a capability token.
Primitive policy 12: The composition MUST NOT accept a redeemer credential.
Primitive policy 13: The composition MUST NOT persist a credential.
Primitive policy 14: A refusal under Primitive policy 1 through 9 MUST NOT write.
Primitive policy 15: IF the authorization key EXCEEDS the reference length cap AND the allocator reference DOES NOT EXCEED the reference length cap THEN [Authorize Sharing] MUST answer invalid-sharing-descriptor.
Primitive policy 16: IF the allocator reference [Authorize Sharing] takes, OR the revoked by reference OR the capability token [Revoke Sharing] takes, EXCEEDS the reference length cap THEN the action taking the reference MUST answer invalid-request (Durable Intent Primitive policy 1, Durable Intent Primitive policy 8).
Primitive policy 17: IF the disclosure key the descriptor gives EXCEEDS the reference length cap AND the allocator reference DOES NOT EXCEED the reference length cap THEN [Authorize Sharing] MUST answer invalid-sharing-descriptor.
Primitive policy 18: A refusal under Primitive policy 15 through 17 MUST NOT write.
```

Term out-of-bounds envelope: a supplied max redemptions or a supplied ttl outside Capability's own bounds, or a supplied ttl that EXCEEDS the ttl cap.

Term revocation input: the capability token, the revoked by reference and the revocation reason.

Term required descriptor field: the subject reference, the addressee, the disclosed scope and the authority reference.

Term descriptor cap: the largest encoded descriptor that Capability admits as a scope and whose events fit the substrate's payload cap — the lesser of the maximum length Capability's deployment sets for a string input (Capability String 6, Capability String 7) and the substrate's payload cap less the fixed-field bound, so the caller's text is refused as the caller's fault before Capability or the substrate can refuse it as a deployment's.

NOTE: a redemption's disclosure key is the descriptor's, fixed at the allocation, so Primitive policy 17 refuses an over-cap one at [Authorize Sharing] and no redemption meets it.

### Audit arm

```
Audit arm 17: The deployment MUST alert on an invalid-credential at a record written under the redemption identity as a deployment fault.
```

Term intent record: a sharing action's record before its constituent commit — the sharing.authorize.intended, sharing.disclosure.intended or sharing.revocation.intended record the invocation open writes, the one that verifies the actor's credential (Durable Intent Primitive policy 19); carrying the invocation's parameters other than the credential, the pairing datum, and no constituent-minted id.

Term outcome record: the sharing.authorize.authorized, sharing.disclosure.disclosed or sharing.revocation.revoked record — one the invocation close wrote, one Recoverable Invocation's sweep recovered under the recovery identity, or one an operator wrote through the invocation resolve.

Term refusal record: the sharing.authorize.refused, sharing.disclosure.refused or sharing.revocation.refused record the invocation refuse writes for a pre-commit arm, carrying the constituent's code (Durable Intent refuse step 3.1).

Term position: intent | outcome | refusal — Recoverable Invocation's (Durable Intent Primitive policy 19 through 31): where a recording-failure of a sharing action sat.

Term recovery flag: Recoverable Invocation's recovery set to true — carried by an outcome its sweep wrote under the recovery identity or an operator wrote through the invocation resolve, and by no other (Durable Intent Term recovery).

Term human-attested record: a record of [Authorize Sharing] or [Revoke Sharing] the invocation writes — attested under the allocator's or the revoker's credential.

Term service-attested record: a record of [Redeem And Disclose] the invocation writes, attested under the redemption identity, or a record the sweep writes, attested under the recovery identity.

### Action wiring

```
authorize_sharing(allocator_ref, credential, sharing_descriptor, optional max_redemptions, optional ttl)
  answers authorization result | recording-failure(outcome)
  refuses invalid-request | invalid-credential | invalid-sharing-descriptor | unknown-authority-type | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

redeem_and_disclose(capability_token)
  answers disclosure result | recording-failure(outcome)
  refuses invalid(redemption failure) | not-authorized-sharing | invalid-request | unknown-authority-type | invalid-credential | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

revoke_sharing(capability_token, revoked_by_ref, credential, reason)
  answers revocation result | recording-failure(outcome)
  refuses invalid-request | invalid-credential | already-terminal | not-known | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | recording-failure(intent) | storage-failure | state-unavailable | already-accounted(closing_event_id) | recording-failure(refusal, constituent_code)

sharing_disclosures(subject_ref)
  answers disclosure history
  refuses invalid-query

authorization_provenance(capability_token)
  answers provenance | not-known
```

Term authorization result: the capability token and the authorization event's id an [Authorize Sharing] answers.

Term disclosure result: the disclosure id, the disclosure event's id, the disclosed scope and the allocator reference a [Redeem And Disclose] answers.

Term revocation result: revoked and the revocation event's id a [Revoke Sharing] answers.

Term disclosure history: a subject's disclosure records, each claimable disclosure's record joined to the allocator reference that authorized the disclosure and every other record carried with no allocator named — what [Sharing Disclosures] answers.

Term provenance: a capability-to-sharing entry's allocator reference, sharing descriptor and authorization event id — what [Authorization Provenance] answers.

```
Action wiring 2: A validated authorization MUST call the invocation open with the act kind sharing.authorize, the authorization key as the act key, the allocator reference as the actor reference, the credential AND the intent data carrying the sharing descriptor, the effective max redemptions, the effective ttl AND the allocation reading as the pairing datum (Durable Intent Action wiring 4).
Action wiring 4: An admitted authorization MUST call Capability's allocate with the allocator reference, the encoded sharing descriptor as the scope, the effective max redemptions AND the effective ttl.
Action wiring 5: IF Capability answers invalid-request OR storage-failure for an allocate, OR the database answers state-unavailable, THEN [Authorize Sharing] MUST close the pre-commit arm through the invocation refuse AND answer that code (Recoverable Invocation commit 2, commit 3).
Action wiring 8: [Authorize Sharing] MUST close an allocate that answered the capability token through the invocation close naming sharing.authorize.authorized, the outcome carrying the token digest, the sharing descriptor, the effective max redemptions, the effective ttl AND the allocation reading (Recoverable Invocation commit 4).
Action wiring 10: The composition MUST NOT attest an authorization event carrying no recovery flag under an actor other than the allocator.
Action wiring 11: An attested authorization MUST answer the capability token AND the authorization event's id.
Action wiring 12: [Redeem And Disclose] MUST NOT call Capability's redeem BEFORE resolving the sharing descriptor.
Action wiring 13: The composition MUST read a presented token's capability record through Capability's read filtered to the capability token.
Action wiring 14: IF no capability record EXISTS for the capability token THEN [Redeem And Disclose] MUST answer invalid carrying not-known.
Action wiring 15: IF an unparsed scope EXISTS for the capability token AND the capability token IS NOT IN the spent tokens THEN [Redeem And Disclose] MUST answer not-authorized-sharing.
Action wiring 16: The composition MUST alert the finding surface on an unparsed scope of a capability token that IS NOT IN the spent tokens as a conformance fault.
Action wiring 17: IF the capability token's authorization event IS NOT IN the aged events THEN [Redeem And Disclose] MUST NOT refuse a token as unattested BEFORE rebuilding the token's capability-to-sharing entry.
Action wiring 18: [Redeem And Disclose] MUST answer not-authorized-sharing for an unattested token.
Action wiring 19: IF a diverged entry EXISTS for the capability token AND the token's authorization event IS NOT IN the aged events THEN [Redeem And Disclose] MUST rebuild the capability-to-sharing entry.
Action wiring 20: [Redeem And Disclose] MUST answer not-authorized-sharing for an irreconcilable token.
Action wiring 21: The composition MUST alert the finding surface on an irreconcilable token as a conformance fault.
Action wiring 22: A refusal under Action wiring 14 through 21 MUST NOT write, the alerts of Action wiring 16 and Action wiring 21 and the rebuild of an index entry (Execution Contract Derived index 1) excepted.
Action wiring 23: A resolved redemption MUST call the invocation open with the act kind sharing.disclosure, the disclosure key as the act key, the redemption identity as the actor reference AND the credential, AND the intent data carrying the token digest, the allocator reference, the sharing descriptor, the authorization event id AND the disclosure reading as the pairing datum.
Action wiring 24: The composition MUST NOT read a disclosure intent as an authentication record.
Action wiring 26: IF Capability answers invalid for the redeem THEN [Redeem And Disclose] MUST close the pre-commit arm through the invocation refuse AND answer invalid carrying the redemption failure (Recoverable Invocation commit 2, commit 3).
Action wiring 28: The composition MUST alert the finding surface on a diverged redemption as a conformance fault.
Action wiring 29: A consuming redemption MUST call Selective Disclosure's record with the subject reference, the addressee as the recipient, the disclosed scope Action wiring 13 resolved as the scope, the authority AND the disclosure reading as disclosed_at, inside the disclosure transaction; the reading is the invocation's injected now, so the call never leaves the instant blank (Execution Contract Logic confinement 12) and Selective Disclosure's own answer to a blank instant is not met here.
Action wiring 31: IF Selective Disclosure answers invalid-request OR unknown-authority-type THEN the disclosure transaction MUST commit no write AND [Redeem And Disclose] MUST close the pre-commit arm through the invocation refuse.
Action wiring 32: IF Selective Disclosure answers invalid-request OR unknown-authority-type THEN [Redeem And Disclose] MUST answer that code (Recoverable Invocation commit 3).
Action wiring 35: The composition MUST alert the finding surface on a foreclosed disclosure refusal as a conformance fault.
Action wiring 36: [Redeem And Disclose] MUST close a disclosure transaction that answered the disclosure id through the invocation close naming sharing.disclosure.disclosed, the outcome carrying the disclosure id, the token digest, the allocator reference, the sharing descriptor AND the disclosure reading (Recoverable Invocation commit 4, Durable Intent close 5).
Action wiring 38: A sealed redemption MUST answer the disclosure id, the disclosure event's id, the disclosed scope AND the allocator reference.
Action wiring 40: A validated revocation MUST call the invocation open with the act kind sharing.revocation, the token digest as the act key, the revoked by reference as the actor reference, the credential AND the intent data carrying the token digest, the revoked by reference, the revocation reason AND the revocation reading as the pairing datum.
Action wiring 41: An admitted revocation MUST call Capability's revoke with the capability token, the revoked by reference AND the revocation reason.
Action wiring 42: IF Capability answers already-terminal for a revoke THEN [Revoke Sharing] MUST close the pre-commit arm through the invocation refuse AND answer already-terminal.
Action wiring 43: IF Capability answers not-known for a revoke THEN [Revoke Sharing] MUST close the pre-commit arm through the invocation refuse AND answer not-known.
Action wiring 45: IF Capability answers invalid-request OR storage-failure for a revoke, OR the database answers state-unavailable, THEN [Revoke Sharing] MUST close the pre-commit arm through the invocation refuse AND answer that code.
Action wiring 46: [Revoke Sharing] MUST close a revoke that answered revoked through the invocation close naming sharing.revocation.revoked, the outcome carrying the token digest, the revoked by reference, the revocation reason AND the revocation reading (Recoverable Invocation commit 4).
Action wiring 47: A landed revocation MUST answer revoked AND the revocation event's id.
Action wiring 48: [Revoke Sharing] MUST NOT refuse a capability token as absent from the capability-to-sharing index.
Action wiring 49: [Sharing Disclosures] MUST answer Selective Disclosure's read for the subject reference, each disclosure record whose disclosure IS IN the claimable disclosures joined to the record's disclosure-to-redemption entry AND every other disclosure record carried with no allocator named (Execution Contract Derived index 1).
Action wiring 50: IF Selective Disclosure answers invalid-query THEN [Sharing Disclosures] MUST answer invalid-query.
Action wiring 51: [Authorization Provenance] MUST answer the capability-to-sharing entry for the capability token, a token Composition state 21 answers as carrying no entry excepted.
Action wiring 52: IF no capability-to-sharing entry EXISTS for the capability token OR the capability token's authorization event IS IN the aged events THEN [Authorization Provenance] MUST answer not-known.
Action wiring 56: IF the capability token's authorization event IS NOT IN the aged events THEN [Authorization Provenance] MUST NOT answer not-known BEFORE rebuilding the capability token's capability-to-sharing entry.
NOTE: watch the miss read before its rebuild (Action wiring 56).
Action wiring 57: IF the capability token's authorization event IS NOT IN the aged events THEN [Authorization Provenance] MUST NOT answer a diverged entry BEFORE rebuilding the capability token's capability-to-sharing entry.
Action wiring 58: [Authorization Provenance] MUST answer not-known for an irreconcilable token.
Action wiring 53: A read-only query MUST NOT record an event.
Action wiring 59: IF Capability's redeem answers redeemed THEN the disclosure transaction MUST call Selective Disclosure's record AND write the pending disclosure-to-redemption entry.
Action wiring 60: IF a call of a sharing action's commit answers an arm of the unknown partition THEN the sharing action MUST call the invocation yield AND answer recording-failure(outcome) (Recoverable Invocation commit 8).
Action wiring 61: IF the invocation open, refuse OR close answers a code of Recoverable Invocation's Action wiring table THEN the sharing action MUST answer that code.
Action wiring 62: IF a read the action makes answers state-unavailable THEN the action MUST answer state-unavailable PER Execution Contract Read 1.
Action wiring 63: IF Capability's redeem answers redeemed THEN the composition MUST compare the scope AND the allocator reference the redeem answers with the ones Action wiring 13 resolved.
Action wiring 64: IF Capability answers storage-failure for a redeem, OR Selective Disclosure answers storage-failure for the record, OR the write of the pending disclosure-to-redemption entry answers storage-failure, OR the database answers state-unavailable, THEN the disclosure transaction MUST commit no write AND [Redeem And Disclose] MUST close the pre-commit arm through the invocation refuse AND answer that code (Recoverable Invocation commit 2, commit 3).
Action wiring 65: [Redeem And Disclose] MUST answer invalid carrying the spent token's redemption failure for a spent token.
Action wiring 66: IF no capability record EXISTS for the capability token OR the capability token IS IN the spent tokens THEN [Redeem And Disclose] MUST NOT read the capability-to-sharing index.
Action wiring 67: A refusal under Action wiring 65 MUST NOT write.
Action wiring 68: A sealed redemption MUST set the pending marker's seal marker to the disclosure event's id (Composition state 13).
```

Term validated authorization: an [Authorize Sharing] call whose inputs and descriptor clear Primitive policy.

Term admitted authorization: a validated authorization whose invocation open landed the authorization intent.

Term allocating authorization: an admitted authorization Capability's allocate answered with a capability token.

Term attested authorization: an allocating authorization whose invocation close landed its authorization event.

Term effective max redemptions: the call's max redemptions, or the default max redemptions where the call supplies none.

Term effective ttl: the call's ttl, or Capability's default capability ttl where the call supplies none — no longer than the ttl cap either way (Primitive policy 3, Capability requirement 33).

Term unparsed scope: a capability scope the sharing scope grammar does not parse.

Term unattested token: a capability token carrying no capability-to-sharing entry after the entry's rebuild — a token whose authorization events each carry the recovery flag, and a token whose authorization event is an aged event, included.

Term spent token: a capability token whose capability Capability's read answers in an effective status other than allocated — expired, redeemed or revoked, whose redemption failure is expired, exhausted or revoked in that order (Capability Term effective status). Under the ttl cap every token whose authorization event has aged is a spent token.

Term diverged entry: a capability-to-sharing entry whose sharing descriptor or allocator reference differs from the ones the capability record carries.

Term irreconcilable token: a capability token whose capability-to-sharing entry still diverges from the capability record after the entry's rebuild.

Term resolved redemption: a [Redeem And Disclose] call whose sharing descriptor resolved and which Action wiring 14 through 21 and Action wiring 65 did not refuse.

Term admitted redemption: a resolved redemption whose invocation open landed the disclosure intent.

Term diverged redemption: a redemption whose answered scope or allocator reference differs from the ones Action wiring 13 resolved.

Term consuming redemption: an admitted redemption Capability's redeem answered redeemed — one use consumed, inside the disclosure transaction.

Term foreclosed disclosure refusal: invalid-request | unknown-authority-type — the Selective Disclosure refusals a descriptor that cleared Primitive policy cannot reach.

Term disclosing redemption: a consuming redemption whose disclosure transaction committed with a disclosure id.

Term sealed redemption: a disclosing redemption whose invocation close landed its disclosure event.

Term validated revocation: a [Revoke Sharing] call whose inputs clear Primitive policy.

Term admitted revocation: a validated revocation whose invocation open landed the revocation intent.

Term revoking revocation: an admitted revocation Capability's revoke answered revoked.

Term landed revocation: a revoking revocation whose invocation close landed its revocation event.

Term revocation reading: the invocation's now at [Revoke Sharing] — the revocation intent's pairing datum, which the capability's revocation instant equals (Execution Contract Logic confinement 19); stamped on the revocation event.

#### Closure table

Every input an action takes, and every answer a call of the five actions and of the leg can meet — Capability's allocate, redeem, revoke and read, Selective Disclosure's record and read, the substrate's event read, and Recoverable Invocation's open, close, refuse and yield — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. The three sharing actions are Recoverable Invocation's: the intent commits at the open, ahead of the constituent write (Execution Contract Constituent failure 1), the commit is Capability's allocate, the disclosure transaction or Capability's revoke, and the outcome lands at the close, so open, commit and close are three commits and not one transaction (Durable Intent Non-goal 1); an act whose outcome never lands is the sweep's, closed within its closure window (Recoverable Invocation reconcile). The read-only queries write nothing (Action wiring 53), and the two indexes stay outside every action's transaction but the pending entry's write (Composition state 12). A refusal writes nothing, except that a pre-commit arm of a sharing action keeps the authenticated attempt in a refusal record (Recoverable Invocation commit 3).

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| a sharing action | a blank allocator reference or credential | invalid-request, nothing written | Primitive policy 1, 2, 14 |
| [Authorize Sharing] | an out-of-bounds envelope, a supplied ttl over the ttl cap included | invalid-request, nothing written | Primitive policy 3, 14, Term ttl cap |
| [Authorize Sharing] | a descriptor whose encoding the grammar does not parse back into the same descriptor, carrying a blank required field, over the descriptor cap or a field over Selective Disclosure's string cap | invalid-sharing-descriptor, nothing written | Primitive policy 5, 6, 7, 9, 14 |
| [Authorize Sharing] | a descriptor whose authorization key or disclosure key exceeds the reference length cap | invalid-sharing-descriptor, nothing written | Primitive policy 15, 17, 18 |
| [Authorize Sharing] | an authority type outside the authority types | unknown-authority-type, nothing written | Primitive policy 8, 14 |
| [Revoke Sharing] | a blank revocation input | invalid-request, nothing written | Primitive policy 4, 14 |
| [Authorize Sharing], [Revoke Sharing] | an allocator reference, revoked by reference or token over the reference length cap | invalid-request, nothing written | Primitive policy 16, 18 |
| a sharing action | inputs whose outcome would exceed the substrate's payload cap | invalid-request at the open, nothing written | Durable Intent Primitive policy 12, 13 |
| every action | a capability token | compared byte-exact, never normalized | Primitive policy 10, 11 |
| [Redeem And Disclose] | a redeemer credential | none is taken | Primitive policy 12 |
| [Redeem And Disclose] | a blank or over-long capability token | invalid carrying not-known, nothing written: Capability's read answers no capability for it | Action wiring 14, 22, Capability Operation 68 |

**Capability: the resolution read**, at [Redeem And Disclose], ahead of the open, the invocation's now injected at Capability's seam (Action wiring 12, 13, Capability requirement 22).

| Answer | Lands | Owner |
|---|---|---|
| no capability record | invalid carrying not-known, the index unread, nothing written | Action wiring 14, 22, 66 |
| an effective status of expired, redeemed or revoked: a spent token | invalid carrying expired, exhausted or revoked, the index unread, nothing written | Action wiring 65, 66, 67, Term spent token |
| a scope the grammar does not parse | not-authorized-sharing, alerted, nothing written | Action wiring 15, 16, 22 |
| a token the index does not attest after its rebuild, its authorization events recovered included and a token whose authorization event is an aged event | not-authorized-sharing, nothing written | Action wiring 17, 18, 22, Composition state 6, 21, Term unattested token |
| an irreconcilable token | not-authorized-sharing, alerted, nothing written | Action wiring 19 through 22 |
| an attested token whose entry agrees | the resolved redemption, then the open | Action wiring 23 |
| state-unavailable | passed through unchanged, nothing written | Action wiring 62, Execution Contract Read 1 |
| no answer | no answer to give | Execution Contract Error model 1 |

**Recoverable Invocation: the open, the close, the refuse and the yield**, at the three sharing actions.

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the open | an intent event id | the commit | Action wiring 2, 23, 40, Term admitted authorization, Term admitted redemption, Term admitted revocation |
| the open | invalid-credential, invalid-request, act-in-flight, section-unavailable, journal-unavailable, recording-failure(intent) | the same code, nothing committed; an invalid-credential under the redemption identity alerted | Action wiring 61, Audit arm 17, Durable Intent Action wiring table |
| the open | recording-failure(outcome) | recording-failure(outcome), the intent standing open, the commit never issued and the record the sweep's; never re-run | Action wiring 61, Durable Intent Action wiring table |
| the open | act-landed | never: every kind is repeatable | Recoverable Invocation repeatable 1, Term sharing bindings |
| the close | an event id | the index entry or the seal marker, and the result | Action wiring 8, 11, 36, 38, 46, 47, Composition state 4, 13 |
| the close | recording-failure(outcome) | recording-failure(outcome), the act committed and its record the sweep's; no token or disclosure id answered | Action wiring 61, Recoverable Invocation commit 4 |
| the refuse | an event id | the constituent's own code, the attempt recorded | Action wiring 5, 26, 31, 32, 42, 43, 45 |
| the refuse | already-accounted or recording-failure(refusal, constituent_code) | that code; the sweep records the attempt where the refusal did not land | Action wiring 61, Durable Intent Action wiring table |
| the yield | its return | recording-failure(outcome), the act possibly committed and its record the sweep's | Action wiring 60 |

**The constituents inside a commit.** A state-unavailable or a storage-failure from any of these calls is a pre-commit arm (Execution Contract Constituent failure 1, 3) closed through the refuse, and a call with no answer, or with an answer its constituent does not declare, is the unknown partition, closed through the yield (Action wiring 60, Term commit partition). The other answers:

| Call | Answer | Lands | Owner |
|---|---|---|---|
| allocate | a capability token | the close | Action wiring 8, Term allocating authorization |
| allocate | invalid-request | invalid-request, refused | Action wiring 5 |
| redeem, in the disclosure transaction | redeemed | Selective Disclosure's record and the pending entry, an answer that differs from the resolution alerted | Action wiring 28, 29, 59, 63, Composition state 12 |
| redeem, in the disclosure transaction | storage-failure | storage-failure, the transaction committing no write, refused | Action wiring 64 |
| redeem | invalid carrying exhausted, expired, revoked or not-known — the capability changed since the resolution read answered it allocated, a revocation landing between them | invalid carrying the redemption failure, nothing consumed, refused | Action wiring 26, Capability Operation 31 |
| record, in the disclosure transaction | a disclosure id | the transaction commits, then the close | Action wiring 36, Term disclosing redemption |
| record | invalid-request or unknown-authority-type | the same code, the transaction committing no write, nothing consumed, refused and alerted | Action wiring 31, 32, 35 |
| record | storage-failure | storage-failure, the transaction committing no write, nothing consumed, refused | Action wiring 64 |
| revoke | revoked | the close | Action wiring 46, Term revoking revocation |
| revoke | already-terminal, not-known or invalid-request | the same code, refused | Action wiring 42, 43, 45 |

**The read-only queries.**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Selective Disclosure's read, at [Sharing Disclosures] | the subject's records | the disclosure history, each claimable disclosure joined to its entry and the rest carried with no allocator named | Action wiring 49 |
| Selective Disclosure's read | invalid-query | invalid-query | Action wiring 50 |
| the capability-to-sharing index, at [Authorization Provenance] | an entry, after the rebuild its miss or divergence triggers | the provenance | Action wiring 51, 56, 57 |
| the index | no entry after the rebuild, or an irreconcilable token | not-known | Action wiring 52, 58 |

**The composition's own records.** A capability-to-sharing entry is written after its authorization event lands, outside the action's transaction (Composition state 4): a write of one that fails or never answers is a rebuild trigger, not data loss (the section titled Composition state in `execution-contract.md`; Composition state 6), and an authorization outcome the sweep or an operator wrote binds no entry. The pending disclosure-to-redemption entry commits inside the disclosure transaction (Composition state 12); its seal marker is set after the disclosure event lands, and an outcome the sweep or an operator wrote seals it through the rebuild (Composition state 16).

**The leg.** It answers no caller, and decides only on an answered read (Reconciliation 36): a capability read, a disclosure read or a log read that fails or gives no answer decides nothing, and the record is examined again at the next run (Reconciliation 2). It opens findings and alerts; it writes no outcome, which is the sweep's under the recovery identity.

### Wiring decision

```
Wiring decision 1: The composition MUST attach a disclosure's accountability to the allocator's authorization.
Wiring decision 2: The composition MUST NOT attach a disclosure's accountability to the bearer.
Wiring decision 5: The composition MUST NOT fabricate a disclosure record for a consumed use.
```

<details markdown="block">
<summary>WHY</summary>

*Principle:* regulated disclosure requires a named, non-repudiable *authorizing* party, not a named *consumer*; bearer-token sharing requires the consumer be anonymous. Both are satisfied at once by attaching accountability to the allocator. *Likely objection:* doesn't accountable disclosure mean recording who received the data? *Mechanism:* the regulator's question is *who authorized this disclosure, and under what authority?* — and that is the allocator and the authority, both recorded: the allocator at allocation under the allocator's own credential, the authority in the capability's scope and the disclosure record, and the disclosure attributed to the allocator in the disclosure event. The redeemer's identity is *structurally* unavailable — Capability's redeem accepts none and records none — so this composition records what it can prove and is honest about what bearer semantics make unprovable. A disclosure whose seal failed is closed by Recoverable Invocation's sweep, attested as recovered, and still names the allocator, read back from the capability. *Result:* the disclosure is accountable to the allocator and the redeemer is never named — the asymmetry no constituent provides alone.

</details>

### Reconciliation

```
Reconciliation 2: The reconciliation MUST start ONE run PER run of Recoverable Invocation's sweep.
Reconciliation 29: The reconciliation MUST NOT examine a young record.
Reconciliation 30: The reconciliation MUST NOT examine an aged record.
Reconciliation 31: The reconciliation MUST read EVERY capability through Capability's read naming no field, AND EVERY disclosure record through Selective Disclosure's read by the disclosure instant range Reconciliation 29 and Reconciliation 30 admit, kept in the composition's code to the records Reconciliation 29 and Reconciliation 30 admit, against the intents.
Reconciliation 32: IF a capability Reconciliation 29 and Reconciliation 30 admit IS NOT a carried capability THEN the reconciliation MUST open a write-ownership finding for the token digest.
Reconciliation 33: IF a revoked capability Reconciliation 29 and Reconciliation 30 admit IS NOT a carried revocation THEN the reconciliation MUST open a write-ownership finding for the token digest.
Reconciliation 34: IF a disclosure record Reconciliation 29 and Reconciliation 30 admit IS NOT a carried disclosure record THEN the reconciliation MUST open a write-ownership finding for the disclosure id.
Reconciliation 35: The reconciliation MUST alert the finding surface carrying the carried record, the token digest in place of the capability token, for EVERY false closing Reconciliation 29 and Reconciliation 30 admit.
Reconciliation 36: The reconciliation MUST decide ONLY on an answered read.
Reconciliation 37: The reconciliation MUST read the now of the sweep run Reconciliation 2 starts the reconciliation's run with (Durable Intent Primitive policy 18) AND MUST NOT take a clock reading of the reconciliation's own.
NOTE: watch the sweep's run reading (Reconciliation 37).
Reconciliation 38: The reconciliation MUST take the enumeration of Reconciliation 31 once PER run, at the run's start.
```

Term reconciliation: the leg the composition runs outside every invocation, beside Recoverable Invocation's sweep — the reading of the capability and disclosure records against the intents, whose output, a write-ownership finding or a false-closing alert, an auditor awaits at the sweep cadence and within no window of its own.

Term carried capability: a capability an authorization intent carries — an intent of sharing.authorize whose act key carries the capability's allocator reference and scope and whose pairing datum EQUALS the capability's allocation instant.

Term carried revocation: a revoked capability a revocation intent carries — an intent of sharing.revocation whose act key is the token digest of the capability and whose pairing datum EQUALS the capability's revocation instant.

Term carried disclosure record: a disclosure record a disclosure intent carries — an intent of sharing.disclosure whose act key carries the record's subject reference, recipient, scope and authority and whose pairing datum EQUALS the record's disclosure instant.

Term carrying intent: the intent that makes a record a carried capability, a carried revocation or a carried disclosure record — one at most, an equal now never reaching two invocations of one act key (Capability requirement 23).

Term young record: a capability, a revocation or a disclosure record whose instant — the allocation instant, the revocation instant or the disclosure instant — stands within the examine window end of the act kind it names, measured back from the sweep's now: a record whose invocation the sweep may still be closing (Recoverable Invocation Term examine window end). The span from the instant to the sweep's now is less than the examine window end for a young record, and a record at exactly that span is not young, as Recoverable Invocation's Term in-flight reads its edge against now, so Reconciliation 29 and Reconciliation 30 leave no record unexamined at equality.

Term aged record: a capability, a revocation or a disclosure record whose instant PRECEDES the cut-over instant, or for which the sweep's now DOES NOT PRECEDE `(((instant + audit horizon) - (2 * clock offset allowance)) - reconciliation run bound)`, the instant read as Term young record reads it — a record whose intent the audit horizon may have destroyed, which the reconciliation would read as no intent. The edge is Recoverable Invocation's Term horizon edge taken at the earliest recording instant the record's instant admits, one clock offset allowance before it, so a record is aged no sooner than that edge reads its intent.

Term write-ownership finding: a finding that a capability, a revocation or a disclosure record is not carried — a write against Capability or Selective Disclosure outside the composition's surface (Composes 8, Composes 11).

Term false closing: a carried capability, carried revocation or carried disclosure record whose carrying intent an abandonment or a refusal closed — an act that committed, read as one that did not.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this pattern's alerts are written beside that register and are no part of it (Escalation findings 6).

Term consumed count: `(max redemptions - remaining redemptions)` for one capability, read through Capability's read.

Term aged event: an event for which now DOES NOT PRECEDE `((recording instant + audit horizon) - clock offset allowance)` — past which the event's payload may be lawfully destroyed, the allowance taken at the reading as Term aged record takes it.

Term token's authorization event: the one authorization event naming a capability token that the capability-to-sharing rebuild binds (Composition state 18) — the first by sequence number that carries no recovery flag, and where every authorization event naming the token carries the recovery flag, the first by sequence number, whose age Composition state 7 and 21 read though the rebuild binds none; an authorization event whose payload the substrate has destroyed IS IN the aged events, the substrate destroying no payload before the audit horizon has elapsed from the event's recording instant (Audit Trail's record_destruction), and the event that a capability token's capability-to-sharing entry names by its authorization event id (Composition state 3) stays the token's authorization event once the substrate destroys its payload, though the rebuild binds it no longer, Audit Trail's read_record answering it by that id; a token that no authorization event and no capability-to-sharing entry names has none, and none IS NOT IN the aged events. Where a token carries a second authorization event, that event's age decides nothing: Composition state 6, 7 and 21, Action wiring 17, 19, 56 and 57, Invariant 4.2 and Check 7.3 each read the age of this one event, so an aged first event and a young second event answer as the token's authorization event IS IN the aged events, and the entry is neither rebuilt nor read.

Term substrate partial: the orphan attestation a substrate failure at the substrate's append leaves, or the unretained event a failure at the substrate's retention placement leaves — the substrate's own reconciliation's.

---
## Composition-level invariants

These emerge from the composition; none belongs to a single constituent.

- **Invariant 1 — Audit-subject asymmetry.**
  ```
  Invariant 1.1: EVERY claimable disclosure MUST carry records naming the allocator as the authorizing party (Invariant 1.4).
  Invariant 1.2: The composition MUST NOT record a redeemer identity in any record.
  Invariant 1.3: EVERY disclosure record the composition produces MUST carry the capability's addressee as the recipient. A bearer's redemption may reach a recipient other than the addressee: Selective Disclosure's Term recipient stays the party the data reached, and the addressee is who the share was sent to.
  Invariant 1.4: The composition MUST make the allocator-named claim ONLY IF the disclosure IS IN the claimable disclosures.
  ```
- **Invariant 2 — Disclosure-accountability binding.**
  ```
  Invariant 2.1: EVERY disclosure event MUST name a disclosure record in the Selective Disclosure records.
  Invariant 2.2: A disclosure record MUST NOT carry two disclosure events.
  Invariant 2.3: EVERY committed disclosure whose disclosure event has not landed MUST stand as a pending marker AND a carrying intent that stands open or escalated, a false closing excepted (Check 2.5).
  NOTE: the invocation resolve does not check an operator's outcome against Selective Disclosure (Escalation resolve 28, Escalation resolve 31), so Invariant 2.1, Invariant 2.2 and Invariant 4.2 are detected, not prevented, for an operator's closing: the seal alert (Composition state 17), Check 2.1, Check 2.2 and Check 4.2 find it.
  ```
- **Invariant 3 — Allocation-authorization binding.**
  ```
  Invariant 3.1: EVERY authorization event MUST name a capability token in the Capability records.
  Invariant 3.2: EVERY capability-to-sharing entry MUST name EXACTLY ONE authorization event.
  Invariant 3.3: EVERY authorization event carrying no recovery flag MUST carry the allocator's own attestation.
  Invariant 3.5: A disclosure MUST commit ONLY under a capability token whose capability-to-sharing entry names an authorization event carrying no recovery flag.
  NOTE: the invocation resolve does not check an operator's outcome against Capability (Escalation resolve 28, Escalation resolve 31), so Invariant 3.1 and Invariant 3.2 are detected, not prevented, for an operator's closing: the duplicate-authorization alert (Composition state 18) and Check 3.2 find it, and an operator's outcome carries the recovery flag, so it binds no entry (Composition state 6).
  ```

- **Invariant 4 — Scope-bounded disclosure.**
  ```
  Invariant 4.1: EVERY disclosure record the composition produces MUST carry the capability's disclosed scope as the scope.
  Invariant 4.2: The disclosure events naming a capability token whose authorization event IS NOT IN the aged events MUST NOT EXCEED the capability's consumed count.
  ```
Term claimable disclosure: a capability-backed disclosure whose disclosure event, where one has landed, is not an aged event, and whose authorization event, while no disclosure event has landed, is not an aged event — the events the allocator-named claim reads: the disclosure event naming the allocator, where one has landed, and until one does the authorization event attesting the allocator's authorization. The accounting obligation runs from the disclosure (Capability requirement 5), so a landed disclosure event, which carries the allocator reference (Action wiring 36), answers the claim after its authorization event has aged, and the claim ends only when the disclosure event ages. A disclosure is claimable when it is made: a redemption whose token's authorization event has aged finds no capability-to-sharing entry and discloses nothing (Composition state 21, Action wiring 18), and the ttl cap leaves that state only to a token allocated before the cap, ending every other token's life first (Term ttl cap, Action wiring 65, 66). It stays claimable until its disclosure event ages, or, while none has landed, until its authorization event ages. A claim a recovered disclosure event makes, written by the sweep after the authorization event has aged, is the claim of the disclosure made at its disclosure reading, which was claimable then (Term disclosure reading).

Term allocator-named claim: the naming of the allocator reference as a disclosure's authorizing party, in a record, an event or an answer — what Invariant 1.1 requires of a claimable disclosure, Invariant 1.4 bounds to the claimable disclosures and Check 1.5 audits.

---

## Examples

### Walkthrough — a clinician shares a scoped patient record with a referred specialist, end to end

A hospital deploys this composition with `sharing_scope_grammar` encoding `subject::recipient::fields::authority`, the substrate's `audit_trail_retention_policy = hipaa_6_year`, a provisioned redemption identity, a provisioned `recovery_identity`, and the Recoverable Invocation instance's bounds.

1. **Authorization.** A treating clinician refers a patient to a specialist and authorizes a one-time, 24-hour share of the minimum-necessary fields: `authorize_sharing(allocator_ref = "dr_chen", credential = <chen-cred>, sharing_descriptor = {subject: "patient-7842", recipient: "dr-okafor-cardiology", fields: "cardiology-summary", authority: {type: consent, reference: "consent-8821"}}, max_redemptions: 1, ttl: 86400)`. This composition parses the descriptor, then — **before allocating anything** — Recoverable Invocation's open records the intent: `sharing.authorize.intended` under `actor_ref = "dr_chen"`, `<chen-cred>`, carrying `{subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821, max_redemptions: 1, ttl: 86400}` and the invocation's now as its pairing datum → `ev_auth_int_01`. That write is where Dr. Chen's credential is checked against the actor registry; had it not validated, the call would have returned `rejected(invalid-credential)` with no capability minted (Durable Intent Invariant 1.1). Only then `Capability.allocate(...)`, the same now injected at its seam, returns `capability_token = tok_share_x1`, and the invocation close records `sharing.authorize.authorized` under Dr. Chen's credential, carrying `{digest(tok_share_x1), subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821, …}` and the intent's event id → `ev_auth_01` — **attested under Dr. Chen's credential** (Invariant 3). `capability_to_sharing[digest(tok_share_x1)]` is populated. Returns `{tok_share_x1, ev_auth_01}`. The hospital emails the specialist a link embedding `tok_share_x1`. Had Dr. Chen asked for a ttl longer than the ttl cap — the six-year horizon less twice the clock offset allowance — the call would have answered `rejected(invalid-request)` before anything was written (Primitive policy 3), so no share outlives the record of its authorization.
2. **Redemption and disclosure.** The specialist's system opens the link within the day: `redeem_and_disclose(tok_share_x1)` — **no identity is presented**. This composition resolves the descriptor, opens its invocation, commits the disclosure transaction, and closes, in that order. **Descriptor:** `Capability.read({tok_share_x1})` → the scope parses to patient-7842 / dr-okafor-cardiology / cardiology-summary / consent-8821; `capability_to_sharing` supplies `ev_auth_01`. **Intent:** the open records `sharing.disclosure.intended` under the redemption identity, carrying `{digest(tok_share_x1), allocator_ref: "dr_chen", subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, …}` and its pairing datum → `ev_disc_int_01` — naming no bearer. **The disclosure transaction:** `Capability.redeem(tok_share_x1) → redeemed(scope, allocator_ref = "dr_chen")`, and the capability exhausts (single-use → `Redeemed`); `SelectiveDisclosure.record(subject: "patient-7842", recipient: "dr-okafor-cardiology", scope: "cardiology-summary", authority: {consent, consent-8821}, disclosed_at = the pairing datum)` → `disc_01`, with `disclosure_to_redemption[disc_01]` written pending in the same transaction. **Outcome:** the close records `sharing.disclosure.disclosed` under the redemption identity, carrying `{disc_01, digest(tok_share_x1), allocator_ref: "dr_chen", subject: patient-7842, recipient: dr-okafor-cardiology, fields: cardiology-summary, authority: consent/consent-8821}` → `ev_disc_01` — **naming Dr. Chen as the authorizing allocator, naming no redeemer**; `disclosure_to_redemption[disc_01]`'s pending is replaced by `ev_disc_01`. Returns `{disc_01, ev_disc_01, "cardiology-summary", "dr_chen"}`. The hospital then transmits the cardiology-summary fields to the specialist.
3. **The audit answer.** `sharing_disclosures("patient-7842")` returns `disc_01`: disclosed `cardiology-summary` to `dr-okafor-cardiology`, under consent `consent-8821`, **authorized by `dr_chen`** (Invariant 1). `authorization_provenance(tok_share_x1)` confirms Dr. Chen authorized it, and `ev_auth_01`'s intent event id resolves to `ev_auth_int_01` — which makes it provable that Dr. Chen was authenticated *before* the capability existed (Durable Intent Check 1.1). There is no field anywhere recording *who* at the specialist's office actually opened the link — by design.

### Domain example — a multi-use pre-signed disclosure to an auditor

A bank authorizes, under SOX (the US Sarbanes-Oxley Act) section 404, a 10-redemption, 7-day capability for an external auditor to pull a customer's transaction subset: `authorize_sharing("compliance_officer_m", <cred>, {subject: "acct-0187", recipient: "audit-firm-AF3", fields: "transactions:2024", authority: {type: regulatory, reference: "SOX §404"}}, max_redemptions: 10, ttl: 604800)`. Over the week the auditor's tooling redeems the token nine times from various systems; each [Redeem And Disclose] records a distinct Selective Disclosure record bound to its own sealed [Sharing Disclosed] event, every one attributed to `compliance_officer_m` as the allocator and **none recording which of the auditor's systems redeemed it**. Two of the auditor's systems that present the token at the same moment meet one disclosure key: the second is answered act-in-flight and retries once the first has closed. The `remaining_redemptions` counter (Capability) decrements 10→1; the regulated-audit record shows nine accountable disclosures under one authorization. The audit-subject asymmetry holds across every redemption.

### Rejection path — spent, lapsed, cancelled, foreign, and unrecorded tokens

- **Exhausted / expired / revoked.** A bearer redeems a single-use token a second time: `redeem_and_disclose(tok_share_x1) → rejected(invalid(exhausted))`; **nothing is disclosed**. Capability's read answers the token's effective status as redeemed, so the composition answers Capability's own redemption failure without reading the capability-to-sharing index or opening an invocation, and nothing is written (Action wiring 65 through 67). A token presented after its TTL → `invalid(expired)`; after [Revoke Sharing] → `invalid(revoked)` — years later too, after the audit horizon has destroyed the authorization event, since the ttl cap ended the token's life first and a revoked token never reads live again. Where a revocation lands between the read and the redemption, the intent has already landed: Capability's redeem refuses on a pre-commit arm and consumes nothing, and the invocation refuse closes the intent with a `sharing.disclosure.refused` record carrying revoked (Action wiring 26). The bearer presented a token that no longer authorizes a disclosure, and no disclosure record is created (the no-disclosure-unrecorded direction holds: no disclosure occurred, so none is recorded).
- **Unattested capability.** A token whose [Sharing Authorized] attestation never landed under the allocator's credential is redeemed — its invocation's close failed and the sweep later recovered the outcome under the recovery identity, or no outcome exists at all: step 1 finds no `capability_to_sharing` entry after rebuild, since the rebuild binds no outcome carrying the recovery flag → `rejected(not-authorized-sharing)` **before `redeem` is called**, so nothing is consumed and nothing is disclosed, and the token lapses at its ttl. The allocator was told `recording-failure(outcome)` and never held the token. The Capability instance is exclusive to this composition (*Composes*), so there is no foreign token to refuse: a token the instance does not know is `invalid(not-known)`, and a scope that does not parse is a conformance fault, not another composition's share.
- **Early revocation closes the window.** The referral is withdrawn before the specialist opens the link, so the hospital's privacy officer cancels a *still-live* token — `tok_share_x2`, allocated to the same specialist and never redeemed: `revoke_sharing(tok_share_x2, "privacy_officer_hosp", <cred>, "referral-withdrawn")` first records a [Sharing Revocation Intended] event → `ev_rev_int_01` (where the revoker's credential is verified — a live sharing is never cancelled on an unverified claim), then transitions the capability to `Revoked` via `Capability.revoke`, its revocation instant the intent's pairing datum, then records a [Sharing Revoked] event carrying the intent's event id under the revoker's credential; subsequent redemptions return `invalid(revoked)`.
- **Revoking a token that is already spent.** The same officer, a day late, tries to cancel `tok_share_x1`, which the specialist already redeemed: the [Sharing Revocation Intended] event is written (the officer is a real actor and their credential validates), then `Capability.revoke` refuses already-terminal — Capability's redeemed state is absorbing — a pre-commit arm, so the invocation refuse closes the intent with a `sharing.revocation.refused` record carrying already-terminal, the call returns rejected(already-terminal), and **no** [Sharing Revoked] event is written. Nothing about the earlier disclosure is altered.

### Failure path — a disclosure whose seal is lost, recovered

The specialist's system redeems `tok_share_x3`. The open lands `sharing.disclosure.intended` under the redemption identity carrying the invocation's now as its pairing datum; the disclosure transaction redeems and records `disc_07`, its disclosure instant the same now, with its pending entry. The close's write of `sharing.disclosure.disclosed` answers recording-failure carrying step-3 — the Event Log append answered nothing, its reply lost — and the read-back by invocation id finds nothing, so the call returns `recording-failure(outcome)`, which carries no disclosure id: the host does not deliver the bytes, and the bearer must not re-run, a re-run meeting act-in-flight while the intent stands open. Recovery is Recoverable Invocation's: once the intent ages past its examine edge, the sweep runs the disclosure probe — Selective Disclosure's read for patient and recipient at the intent's pairing datum, kept to the intent's scope and authority — finds `disc_07`, reads the allocator from the pending entry the disclosure transaction wrote for `disc_07` (Term disclosure probe), writes `sharing.disclosure.recovery_intended`, and lands `sharing.disclosure.disclosed` under `recovery_identity` with `recovery = true`, the redemption identity as the acting actor reference, and the allocator named (had the lost append landed after all, the sweep's re-read would have found it and written nothing). The rebuild seals `disc_07`'s pending entry from the recovered event (Composition state 16), and [Sharing Disclosures] answers it, authorized by its allocator; the recovery flag stands on the disclosure event, where the auditor reads it.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "who authorized this disclosure of subject DS-99's data, and under what authority?"** A GDPR (EU General Data Protection Regulation) Data Protection Authority examines a disclosure. `sharing_disclosures("DS-99")` returns the disclosure record with its `authority` (`{type, reference}`) and the **authorizing allocator_ref**; `AuditTrail.verify_record`, presented with the original event payload Audit Trail names for the bound [Sharing Disclosed] event, confirms it was not altered (Check 2.3 — an event still in the unsealed tail is answered as Audit Trail's verify record answers it) (Invariant 2, resting on the substrate's Tamper Evidence), and the [Sharing Authorized] event — **attested under the allocator's own credential** (Invariant 3) — is the non-repudiable proof that the named allocator authorized the share. The auditor's question is answered by the allocator and the authority, both recorded; the auditor does *not* ask "who redeemed it," and Invariant 1 makes clear the records structurally cannot and do not answer that — which is the correct, honest boundary for bearer-token sharing, not a gap.

**Disputed disclosure — "I never received that data."** A named addressee claims they never received the data. The records show capability `tok_share_x1` was authorized for disclosure *to* `dr-okafor-cardiology` (the [Sharing Authorized] event, attested by Dr. Chen) and that a redemption-disclosure occurred ([Sharing Disclosed], bound to `disc_01`). What the records **cannot** establish is whether `dr-okafor-cardiology` — versus a party who obtained the forwarded or intercepted token — actually presented it: bearer semantics make the redeemer unknowable (Capability Invariant 3/5, surfaced as Invariant 1). The records bound the forensic window precisely — *this share was authorized to this recipient, by this allocator, and a bearer redeemed it at this time* — without resolving redeemer identity, which is exactly Capability's own disputed-disclosure boundary. Whether the recipient's denial is accurate (the token was taken before redemption) or not is a question the bearer design deliberately leaves open; the composition is honest that it does.

**Breach investigation — "during the incident window, was any disclosure made under a capability that should have been revoked, or any sealed event altered?"** An investigator walks the [Sharing Disclosed] events in the window (reached through the substrate Audit Trail in Event Log insertion order), and for each, cross-reads the bound Selective Disclosure record and the capability's state. A disclosure record whose disclosure instant falls after its capability's revocation instant would be the smoking gun — but Invariant 2's binding plus Capability's terminal-absorbing revocation (a `Revoked` capability returns `invalid(revoked)` and discloses nothing) forecloses it: no [Sharing Disclosed] event exists for a redemption that occurred after revocation. Because each disclosure's descriptor is part of the sealed event payload, an attempt to silently widen a disclosed scope (to exfiltrate beyond what was authorized) breaks the seal (Invariant 4 + Tamper Evidence). A disclosure record or a revocation written against the constituents outside this composition's surface carries no intent and is a write-ownership finding (Reconciliation 32 through 34). The forensic window is bounded by the substrate's seal cadence; the newest disclosures in the unsealed tail carry per-event immutability and become seal-verifiable at the next cadence.

---

## Generation acceptance

A derived implementation is acceptable when the conformance checks below are provable to an external auditor given the two indexes and the Capability, Selective Disclosure and Audit Trail records; the external checks name what no record carries.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY claimable disclosure whose disclosure event has landed with the disclosure event naming an allocator reference (Invariant 1.1).
Check 1.2: An auditor MUST find no redeemer identity in any sharing record (Invariant 1.2).
Check 1.3: An auditor MUST find EVERY disclosure record's recipient equal to the addressee the capability's authorization event names (Invariant 1.3).
Check 1.4: An auditor MUST find EVERY disclosure record's authority type and authority reference equal to the authority type and the authority reference the sharing descriptor of the disclosure event, or of the carrying intent where no disclosure event has landed, names (Action wiring 29).
Check 1.5: An auditor MUST find the allocator-named claim made ONLY for a disclosure claimable at the disclosure reading the disclosure carries (Invariant 1.4).
Check 1.6: An auditor MUST find EVERY claimable disclosure whose disclosure event has not landed with a pending marker AND a carrying intent that stands open or escalated, each naming the allocator reference (Invariant 1.1, Invariant 2.3).
Check 2.1: An auditor MUST find EVERY disclosure event's disclosure id naming a disclosure record in the Selective Disclosure records (Invariant 2.1).
Check 2.2: An auditor MUST find no disclosure record carrying two disclosure events (Invariant 2.2).
Check 2.3: An auditor MUST verify a disclosure event PER Audit Trail's verify record contract, presenting the original event payload Audit Trail's term of that name gives for the event (Invariant 2.1).
Check 2.5: An auditor MUST resolve EVERY disclosure record no disclosure event names that is neither a young record nor an aged record to EXACTLY ONE OF a carried disclosure record whose carrying intent stands open, a carried disclosure record whose carrying intent stands escalated, a false closing, a write-ownership finding, by comparing the Selective Disclosure records with the Audit Trail's disclosure events and intents (Invariant 2.3, Reconciliation 34, Reconciliation 35).
NOTE: watch the check over a derived index (Check 2.5).
Check 3.2: An auditor MUST find EXACTLY ONE authorization event PER capability-to-sharing entry (Invariant 3.2).
Check 3.3: An auditor MUST find EVERY authorization event carrying no recovery flag attested under the allocator reference the entry carries (Invariant 3.3).
Check 3.4: An auditor MUST find EVERY disclosure event's token digest, the digest the event's intent carries, resolving to an authorization event carrying no recovery flag (Invariant 3.5).
Check 3.6: An auditor MUST find EVERY authorization event naming a capability token in the Capability records (Invariant 3.1).
Check 4.1: An auditor MUST find EVERY disclosure record's scope equal to the disclosed scope the capability's authorization event names (Invariant 4.1).
Check 4.2: An auditor MUST find the disclosure events naming a capability token not exceeding the capability's consumed count (Invariant 4.2).
Check 7.1: An auditor MUST resolve EVERY capability that is neither a young record nor an aged record AND that no sharing.authorize.authorized event names to EXACTLY ONE OF a carried capability whose carrying intent stands open, a carried capability whose carrying intent stands escalated, a false closing, a write-ownership finding (Reconciliation 32, Reconciliation 35).
Check 7.2: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 5).
Check 7.3: IF a capability token's authorization event IS IN the aged events THEN an auditor MUST NOT find the token failing Check 1.3, Check 1.4, Check 1.5, Check 3.2 through 3.4, Check 3.6, Check 4.1 AND Check 4.2 (Capability requirement 31, Invariant 4.2).
Check 7.4: An auditor MUST resolve EVERY revoked capability that is neither a young record nor an aged record AND that no sharing.revocation.revoked event names to EXACTLY ONE OF a carried revocation whose carrying intent stands open, a carried revocation whose carrying intent stands escalated, a false closing, a write-ownership finding (Reconciliation 33, Reconciliation 35).
```

Term sharing record: a capability record, a disclosure record, an audit event or an index entry.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the redeemer's identity MUST read an identity-keyed access model's records (Non-goal 1).
External check 2: An auditor needing the declared authority confirmed as legally valid MUST read the authority's own records (Non-goal 4).
External check 3: An auditor needing the delivered bytes confirmed against the disclosed scope MUST read the host's delivery records (Non-goal 3).
External check 4: An auditor needing the allocator's permission to share confirmed MUST read the composed Permissions instance's records (Non-goal 5).
External check 5: An auditor needing the closure window, the sweep cadence, the run bound AND the three completion bounds confirmed MUST clear Recoverable Invocation Check 4.1 AND Recoverable Invocation External check 3 over the instance (Capability requirement 25, Capability requirement 30).
External check 7: An auditor needing the exclusivity of the Capability instance AND the Selective Disclosure instance confirmed MUST read the deployment's own wiring (Composes 8 and Composes 11).
External check 8: An auditor needing a constituent's own guarantee confirmed MUST read the constituent's own acceptance (Composes 5).
External check 9: An auditor needing the obligation of Capability requirement 22 AND Capability requirement 23 confirmed MUST clear the obligation from external evidence (Recoverable Invocation External check 12).
External check 10: An auditor needing the obligation of Reconciliation 2 AND Capability requirement 34 confirmed MUST clear the obligation from the deployment's declaration of the starters (Sweep External check 11).
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
Non-goal 9: The composition MUST NOT describe the three commits of a sharing action as atomic (Durable Intent Non-goal 1).
Non-goal 10: The composition MUST NOT own a re-entry arm beyond Capability's own already-terminal refusal (Durable Intent Non-goal 4).
Non-goal 11: A deployment needing a constituent record's removal ordered against the audit horizon MUST compose Defensible Retention (Capability requirement 5, Capability requirement 31).
```

NOTE: the owners — [Permissions](../atoms/permissions.idd) and [Session](../atoms/session.idd), an identity-keyed access model (Non-goal 1, Non-goal 2, External check 1); [Permissions](../atoms/permissions.idd) (Non-goal 5, Non-goal 6, External check 4); a composing access-log pattern (Non-goal 7); the deployment (Non-goal 8); [Defensible Retention](./defensible-retention.md) (Non-goal 11, Capability requirement 5, Capability requirement 31).

---

## Edge cases

### Atomic writes

### Clock semantics

```
Clock semantics 1: The composition MUST order a sharing event by the substrate's sequence number alone.
```

Term composition reading: an allocation reading, a disclosure reading or a revocation reading.

Term authority's own records: the Consent records, the Legal Hold records or the deployment's legal analysis — whichever the authority type names.

### Concurrency

### Cross-record consistency under partial failure

```
Cross-record consistency 1: IF a sharing action's commit commits AND the invocation's close does not land THEN the record MUST carry an open intent, closed by the sweep within the closure window.
```

This is Recoverable Invocation's Cross-record consistency for the three act kinds, which the sweep closes: the capability, the revocation or the disclosure record is carried, its carrying intent open until the sweep's committed probe writes the outcome, and the records are honest throughout — a redemption reads the capability's state from Capability, and a disclosure's pending entry stands from its transaction. The records an action keeps as evidence of a refused call — its intent and its refusal record — stay committed (Recoverable Invocation commit 3).

### Multi-use capabilities

A capability allowing more than one redemption produces one disclosure record and one disclosure event per redemption, each bound independently (Invariant 2 holds per redemption), all attributed to the same allocator (Invariant 1), all under the same authorized scope (Invariant 4). The redemption envelope bounds the count; the asymmetry holds across every redemption. Its redemptions share one disclosure key, so they take the critical section in turn: a redemption presented while another of the share stands open answers act-in-flight (Term disclosure key).

### Substrate partials

The substrate has durable partials of its own — an orphan attestation where its append failed after its attestation committed, and an unretained event where its retention placement failed after its append. They are Audit Trail's, found and closed by its own reconciliation, and this composition's leg writes no event, so it compensates none of them (Composes 6). What this composition sees of them is the step on the refusal: an invalid-request at the substrate's retention step means the event is in the log and is read back as landed (Durable Intent Primitive policy 27, Durable Intent Primitive policy 28).

---

## Composition notes

**Recoverable Invocation.** The three acting actions follow [Durable Intent](../atoms/durable-intent.idd) around their constituent writes (Composes 16 through 20): an intent before the commit, the one outcome as the close, a refusal record where Capability or Selective Disclosure refuses, the act's critical section over them, and a sweep and an operator's invocation resolve for what an invocation left open. The pattern binds the three act kinds once (Term sharing bindings) and restates none of the protocol. [Sharing Disclosures] and [Authorization Provenance] are not bound (Composes 19): each writes nothing, so nothing outlives the invocation.

**A recovered authorization does not authorize.** The authorization event is the allocator's attestation, the thing no one else can produce. An authorization outcome the sweep recovered, or an operator wrote, carries the recovery flag and the recovery identity's or the operator's attestation, so the capability-to-sharing index does not bind it (Composition state 6) and the token stays unattested: refused not-authorized-sharing ahead of the redeem, and lapsing at its ttl. The allocator, told recording-failure(outcome), never held the token.

**Recoverable Invocation's commit is one call.** Recoverable Invocation's bound commit is one constituent call whose arms the constituent partitions; the disclosure transaction is two constituent calls and an index write in one database transaction (Term disclosure transaction), whose partition belongs to the transaction. Recoverable Invocation's closed list of deviations has no entry for it, and the pattern treats the transaction as the commit and records the mismatch here, as evidence for Recoverable Invocation's next revision, which is the record Recoverable Invocation Deviation 2 asks of an adopter first, as Chain of Custody and Propagate Consent Revocation Downstream do. One more reading is carried to Recoverable Invocation's next revision as evidence, not as a finding against this pattern: its Term pairing datum reads a seam-injected now as passed into the commit, while Capability's allocate and revoke take no instant and the host injects it at Capability's seam (Capability requirement 22).

---
## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the pattern. The composition's own concepts are the five actions it exposes, the audit events it records, the two descriptor fields it interprets from a capability's scope, and its own refusals. The audit-subject asymmetry itself is a structural guarantee (Invariant 1), not a datum — there is no redeemer field to carry an entry. The deployment settings keep their wire spellings in configuration — `sharing_scope_grammar`, `application_actor_ref`, `application_credential`, `recovery_identity`, `audit_trail_retention_policy`, `default_capability_ttl`, `default_max_redemptions`, `authorization_completion_bound`, `redemption_completion_bound`, `revocation_completion_bound`, and the Recoverable Invocation instance's own settings under the names that pattern gives them — and the two indexes theirs in an implementation, `capability_to_sharing` and `disclosure_to_redemption`; the pattern names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the substrate; the host; the reconciliation; Recoverable Invocation's sweep; a deployment; an auditor; a caller; an allocator; a revoker; a bearer; an operator; an invocation; an action; a sharing action; a read-only query; an intent record; an outcome record; a refusal record; a validated authorization; an admitted authorization; an allocating authorization; an attested authorization; a resolved redemption; an admitted redemption; a consuming redemption; a disclosing redemption; a sealed redemption; a validated revocation; an admitted revocation; a revoking revocation; a landed revocation; a refusal; an authorization intent; an authorization event; a disclosure intent; a disclosure event; a revocation intent; a revocation event; a pending marker; a capability; a capability record; a disclosure record; a capability-to-sharing entry; a disclosure-to-redemption entry; the capability-to-sharing index; the disclosure-to-redemption index; the sharing scope grammar; the redemption identity; the recovery identity; the longest disclosure-accounting obligation.

Term records: the intent records, outcome records and refusal records Recoverable Invocation writes for the three sharing actions through the substrate — each an Audit Trail event carrying one event type below, with the recovery intents, abandonments and escalations Recoverable Invocation derives from the three kinds — the capability and disclosure records the sharing actions write, and the two index entries.

Term record verbs: serve, change, inherit, read, hold, answer, make, select, query, store, key, carry, write, rebuild, set, declare, provision, rotate, configure, refuse, supply, take, pass, mint, validate, parse, compare, normalize, accept, persist, retry, re-run, match, alert, call, record, attest, attach, fabricate, run, re-derive, seal, name, revoke, escalate, compensate, follow, stand, reach, find, verify, enumerate, anchor, join, classify, measure, identify, compose, deliver, adjudicate, authorize, order, resolve, land, bind, close, commit, open, inject, disclose, examine, decide, describe, own, remove, start, clear, yield.

Term value sets: event type = sharing.authorize.intended | sharing.authorize.authorized | sharing.authorize.refused | sharing.disclosure.intended | sharing.disclosure.disclosed | sharing.disclosure.refused | sharing.revocation.intended | sharing.revocation.revoked | sharing.revocation.refused, with the references Recoverable Invocation derives under each kind. finding = write-ownership. The rest are declared where the section that owns each declares it: act kind, seal marker, position, foreclosed disclosure refusal.

Term bounds: audit horizon (audit_trail_retention_policy), authorization completion bound (authorization_completion_bound), redemption completion bound (redemption_completion_bound), revocation completion bound (revocation_completion_bound), reconciliation run bound (Recoverable Invocation's run bound), clock offset allowance (Recoverable Invocation's clock allowance), intent candidates cap (Recoverable Invocation's intent candidates cap), commit round trip, probe round trip, settling period, descriptor cap, fixed-field bound, default max redemptions (default_max_redemptions), ttl cap.

Term cadences: Recoverable Invocation's sweep cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, transitive atoms, substrate, trail, sharing action, act kind, sharing bindings, authorization key, token digest, cut-over instant, disclosure key, disclosure transaction, commit partition, authorization probe, disclosure probe, revocation probe, capability-to-sharing index, disclosure-to-redemption index, seal marker, pending marker, allocation reading, disclosure reading, addressee, disclosed scope, seal alert, duplicate-authorization alert, sharing scope grammar, sharing descriptor, redemption identity, recovery identity, audit horizon, longest disclosure-accounting obligation, default max redemptions, ttl cap, authorization completion bound, redemption completion bound, revocation completion bound, required setting, constituent record, reconciliation run bound, intent candidates cap, clock offset allowance, invocation id, commit round trip, probe round trip, settling period, out-of-bounds envelope, revocation input, required descriptor field, descriptor cap, intent record, outcome record, refusal record, position, recovery flag, human-attested record, service-attested record, authorization result, disclosure result, revocation result, disclosure history, provenance, validated authorization, admitted authorization, allocating authorization, attested authorization, effective max redemptions, effective ttl, unparsed scope, unattested token, spent token, diverged entry, irreconcilable token, resolved redemption, admitted redemption, diverged redemption, consuming redemption, foreclosed disclosure refusal, disclosing redemption, sealed redemption, validated revocation, admitted revocation, revoking revocation, landed revocation, revocation reading, reconciliation, carried capability, carried revocation, carried disclosure record, carrying intent, young record, aged record, write-ownership finding, false closing, finding surface, consumed count, aged event, substrate partial, claimable disclosure, allocator-named claim, sharing record, composition reading, authority's own records, authorization intent, authorization event, disclosure intent, disclosure event, revocation intent, revocation event, redeemer identity, conformance fault, allocation, revocation, consumed use.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's, which Term aged event, Term young record and Term aged record rely on when they read an instant against now. Execution Contract Read 1 — a failed read answers state-unavailable. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, record_destruction, verify_record, compliance alert, recording-failure: Audit Trail. sequence number, payload cap, recording instant, event id: Event Log, the instance Audit Trail carries, read as Composes 12 declares it, a direct invocation the section titled Substrate composition invocation in `execution-contract.md` permits. action reference, invalid-credential, invalid-request: Actor Identity, reached through Audit Trail. capability token, allocator reference, scope, max redemptions, remaining redemptions, ttl, default capability ttl, allocation instant, expiry instant, revocation instant, status, effective status, lapsed, revoked by reference, revocation reason, redemption failure, filter, already-terminal, not-known, storage-failure, now: Capability. disclosure record, disclosure id, subject reference, recipient, authority, authority type, authority types, authority reference, disclosure instant, disclosed_at, string cap, unknown-authority-type, invalid-query: Selective Disclosure. open, close, refuse, yield, resolve, sweep, act key, pairing datum, act probe, commit, repeatable, journal, service identity, outcome envelope, invocation completion bound, closure window, sweep cadence, run bound, clock allowance, examine window end, reference length cap, act-in-flight, section-unavailable, journal-unavailable, already-accounted, act-landed, recovery, acting actor reference, resolving actor, act section, compliance surface, run id, operator run id: Recoverable Invocation. Lease: reached through Recoverable Invocation.

Term composing patterns: [Erasure Tombstone](../atoms/erasure-tombstone.idd); Trusted Timestamping *(forthcoming)*; [Permissions](../atoms/permissions.idd); [Session](../atoms/session.idd); [Immutable Ledger](./immutable-ledger.md).

Term authorization intent: the sharing.authorize.intended event — a [Sharing Authorization Intended].

Term authorization event: the sharing.authorize.authorized event — a [Sharing Authorized].

Term disclosure intent: the sharing.disclosure.intended event — a [Sharing Disclosure Intended].

Term disclosure event: the sharing.disclosure.disclosed event — a [Sharing Disclosed].

Term revocation intent: the sharing.revocation.intended event — a [Sharing Revocation Intended].

Term revocation event: the sharing.revocation.revoked event — a [Sharing Revoked].

Term redeemer identity: any value naming who presented a capability token — the one datum this composition never records.

Term conformance fault: a state the pattern's own declarations foreclose, reached anyway — alerted, never a caller's fault.

Term allocation: one capability Capability's allocate committed.

Term revocation: one capability Capability's revoke committed to the revoked status.

Term consumed use: one redemption Capability's redeem answered redeemed.

#### Authorize Sharing

The allocation-with-attestation action: it parses the sharing descriptor by the sharing scope grammar, opens its invocation with the authorization intent under the allocator's credential — where the credential is verified — allocates a bearer capability whose scope *is* the authorized disclosure, and closes with the [Sharing Authorized] event under the allocator's own credential: intent, allocation, attestation, index, in that order (Action wiring 2 through 11, Invariant 3). Answers the authorization result, or [Invalid Sharing Descriptor] for a descriptor the grammar does not parse, leaves a required descriptor field blank, exceeds the descriptor cap, carries a field over Selective Disclosure's string cap or gives a key over the reference length cap (Primitive policy 5, 6, 9, 15 and 17), or recording-failure(outcome), carrying no token, where the attestation did not land.

Kind: Operation

#### Redeem And Disclose

The load-bearing emergent action: it resolves the descriptor, opens its invocation with the disclosure intent, redeems the capability **by possession alone** and commits a disclosure record with its pending marker in one transaction, and closes with the [Sharing Disclosed] event (Action wiring 12 through 32, Action wiring 35, 36, 38, 59, 65 through 67, Invariant 2). Answers the disclosure result, or the constituent's invalid carrying the redemption failure for a spent, lapsed, cancelled or unknown token — ahead of the open where Capability's read already answers it so, [Not Authorized Sharing] for a token this composition did not attest, Selective Disclosure's own code where it refused the record and nothing was consumed, storage-failure when a write fails and nothing commits, or recording-failure(outcome), carrying no disclosure id, where the seal did not land. Records the allocator, never the redeemer (Invariant 1).

Kind: Operation

#### Revoke Sharing

The revocation action: it opens its invocation with a [Sharing Revocation Intended] event — where the revoker's credential is verified — closes the sharing capability early through Capability's revoke, and closes with a [Sharing Revoked] event under the revoker's credential (Action wiring 40 through 48). Later redemptions of the token answer invalid carrying revoked and disclose nothing.

Kind: Operation

#### Sharing Disclosures

The read-only query answering a subject's disclosure records, each claimable disclosure's record joined to its authorizing allocator and every other record carried with no allocator named — never a redeemer (Action wiring 49 and 50). Records no event.

Kind: Operation

#### Authorization Provenance

The read-only query answering who authorized a given share, from the capability-to-sharing index (Action wiring 51, 52 and 56 through 58). Records no event.

Kind: Operation

#### Sharing Authorized

The Audit Trail event the invocation close records at [Authorize Sharing], **attested under the allocator's own credential** — the allocator's non-repudiable commitment that they authorized this share (Invariant 3.3). The authorization half of the audit-subject asymmetry. One the sweep recovers or an operator writes carries the recovery flag and authorizes nothing (Composition state 6).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (allocator-attested)
Projection: sharing.authorize.authorized

#### Sharing Disclosed

The Audit Trail event the invocation close records at each [Redeem And Disclose] once the disclosure transaction commits, **attested under the redemption identity** — the allocator is absent and the bearer has no credential; it names the allocator reference and carries **no redeemer identity** (Invariant 1). The disclosure half of the asymmetry. One the sweep recovers is attested under the recovery identity, carries the recovery flag, and names the allocator Capability's read answers.

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (service-attested)
Projection: sharing.disclosure.disclosed

#### Sharing Authorization Intended

The Audit Trail event the invocation open records for [Authorize Sharing] **before** it allocates, under the allocator's credential — what makes it provable that authentication preceded the allocation (Durable Intent Invariant 1.1). It deliberately carries **no capability token**, none existing when it is written; one with no [Sharing Authorized] event stands open for the sweep, which closes it from the capability its pairing datum finds or escalates it.

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, allocator-attested)
Projection: sharing.authorize.intended

#### Sharing Disclosure Intended

The Audit Trail event the invocation open records for [Redeem And Disclose] **before** the disclosure transaction, under the redemption identity, carrying no redeemer identity. **Recoverable Invocation's intent, not an authentication record** (Action wiring 24): it is trail-resident, so a disclosure whose seal did not land is closed from the trail and the disclosure record its pairing datum finds rather than from this composition's derived state, and it carries no disclosure id, so no seal is built from it alone (Recoverable Invocation act probe 6).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, service-attested)
Projection: sharing.disclosure.intended

#### Sharing Revocation Intended

The Audit Trail event the invocation open records for [Revoke Sharing] **before** Capability's revoke, naming the token it is about to cancel, under the revoker's credential — a live sharing is never cancelled on an unverified claim (Durable Intent Invariant 1.1). Because it names the token and carries its pairing datum, one with no [Sharing Revoked] event is closed by the revocation probe against that capability's state (Term revocation probe).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (intent, revoker-attested)
Projection: sharing.revocation.intended

#### Sharing Revoked

The Audit Trail event the invocation close records at [Revoke Sharing] after the capability is revoked, **attested under the revoker's own credential** and carrying the intent event id of its [Sharing Revocation Intended] event; one the sweep recovers is attested under the recovery identity, carries the recovery flag, and carries the capability record's revoked by reference (Term revocation probe).

Kind:       Member
Member of:  the sharing event kinds
Role:       Audit event kind (revoker-attested)
Projection: sharing.revocation.revoked

#### Addressee

The sharing descriptor's **allocator-declared addressee** — who the share was sent to, recorded as the recipient of every disclosure. Deliberately *not* the bearer who presents the token, who is unknowable by design (Invariant 1.3).

Kind:       Field
Field of:   the sharing descriptor
Role:       the allocator-declared addressee
Projection: recipient

#### Disclosed Scope

The field subset the capability authorizes for disclosure — the minimum-necessary set — parsed from the capability's immutable scope by the sharing scope grammar. Every disclosure's scope equals it exactly (Invariant 4.1).

Kind:       Field
Field of:   the sharing descriptor
Role:       the authorized field subset
Projection: disclosed_scope

#### Invalid Sharing Descriptor

The composition's own refusal from [Authorize Sharing] for a descriptor the grammar does not parse, one leaving a required field blank, one too long for the payload the events must carry, one carrying a field over Selective Disclosure's string cap, or one whose keys exceed Recoverable Invocation's reference length cap (Primitive policy 5, 6, 9, 15 and 17). The share is refused before a capability is allocated.

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
[Addressee]: #addressee
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
- Through the **Audit Trail substrate** (and transitively Event Log, Actor Identity, Tamper Evidence, Retention Window): SOX (Sarbanes-Oxley Act) section 404/section 802, HIPAA section 164.312(b)/section 164.530(j), PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR (US Code of Federal Regulations) Part 11, SEC Rule 17a-4, ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 27001 clause A.12.4, GDPR Articles 30 and 32 — the attributed, retained, tamper-evident record the sharing events land on.

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — capability-backed-sharing.tla + 15 twins + 9 reachability probes, re-derived 2026-11-10 over the split arc (each sharing action an open, a commit and a close; [Redeem And Disclose]'s resolution read and the capability-to-sharing index's rule ahead of the open, its commit the disclosure transaction), against Recoverable Invocation's contracts (the sweep's closing by this page's authorization, disclosure and revocation probes, the escalation, an operator's resolve unchecked against the constituents), with an allocation, a revocation or a disclosure record written outside every invocation, the write-ownership leg and the two rebuilds' alerts, and extended 2026-11-10 for the ttl cap (the effective ttl, supplied or default, against the audit horizon, the authorization event's recording instant stamped within one clock offset allowance of the reading, and the index read for a live token alone); one model under TLC, 170,229 states (two tokens, one use each, three invocations, one outside write, an audit horizon of 3 and an allowance of 1, the default ttl at the cap); Invariant 2.1, 2.3, 3.1, 3.3, 3.5, 4.2, the probes' pairing datum (Capability requirement 22, 23), the write-ownership finding (Reconciliation 32 through 34), the false-closing alert (Reconciliation 35), the seal alert and the duplicate-authorization alert (Composition state 17, 18), the ttl cap (Term ttl cap, Primitive policy 3, Capability requirement 33: a supplied ttl past the horizon, a default past it, the cap with one allowance) and the spent token refused ahead of the index (Action wiring 65, 66), each broken by a twin alone; the allocation half the 2026-08-27 model left out is in it; Invariant 2.4, 2.5, 3.4, 6.1 and 6.2 inherited from Recoverable Invocation (Invariant 4.2, Instance start 4 through 8, Invariant 1.1); not modelled: Recoverable Invocation's mechanism and the clock's passage (a lapse, the young and aged records, the closure window, the sweep cadence, an event aging past the audit horizon, so Composition state 7 and 21 and [Authorization Provenance]), the fields (Invariant 1.1, 1.3, 1.4, 4.1), validation ahead of the open but the ttl cap, the spent token and the unattested token; capability-backed-sharing.als + 14 twins (the static data model, 2026-11-11: Invariant 1.1 through 1.4, 2.1 through 2.3, 3.1 through 3.3, 3.5 and 4.1 checked on every state of the Capability and Selective Disclosure records, the trail and the two indexes the writers can leave and on what [Sharing Disclosures] answers at its now, 2.1 through 2.3, 3.1, 3.2 and 3.5 a cross-check with the TLA+ model, an operator's closing out of 1.1, 2.1, 2.2, 3.1 and 3.2 as there; nothing testable in Alloy for Invariant 4.2 (the consumed count is Capability's counter, moved by each redeem: across steps, the TLA+ model's); the model found that an operator's disclosure outcome, checked for its outcome reference alone, may name no allocator or another for a claimable disclosure, and no NOTE, alert or check covers Invariant 1.1 for an operator's closing); coverage 2026-11-10, 2026-11-11; owed rows: the token digest (Term token digest, Capability requirement 35 and 36, Action wiring 8, 23, 36, 40 and 46, Reconciliation 32 and 33, Check 3.4; the models' tokens stand for it and no twin breaks it); the equality edge of Term young record (Reconciliation 29 and 30); the cut-over instant (Capability requirement 37, Term aged record); Term claimable disclosure's recovered disclosure event, Check 1.5 and Check 7.3, 2026-11-20; and, since Final Critique 23 (2026-11-21), the alerts' token digest (Composition state 18, Reconciliation 35), Invariant 2.3 over an escalated intent, the disclosure probe's token digest and Action wiring 36's outcome (Recoverable Invocation close 5), Action wiring 64 and Term commit partition's pending-entry arm, Action wiring 68 and Composition state 23, and Term audit horizon as the retention period (the ttl cap and Term aged event over it), 2026-11-21
last gate: 2026-11-21 — Final Critique 23, a full round, frozen at cf98d700 — foundational count 5, cured, not clean, no sample; 2026-11-19 — Final Critique 22, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at 35ae3026 — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed 1 foundational, 0 refining, 0 rhetorical: Capability requirement 34 and Reconciliation 37 cannot both be obeyed because Logic confinement 19 has a sweep take a reading of its own, so the sweep's now is ephemeral and nothing carries it durably to the reconciliation's seam. Refuted by both triages: Reconciliation 2 starts the reconciliation's run per run of the sweep, Recoverable Invocation Primitive policy 18 has the sweep read now once per run at its own seam, and the host that holds that reading injects it at the leg's seam in the same run (Capability requirement 34), so no reading crosses a recovery; Logic confinement 19's re-driven-call sentence says a sweep does not inherit the reading of the call it recovers, not that its own is unavailable to the leg it starts, and the cure's durable sweep-run field would oblige Recoverable Invocation to change a record it owns and restates the host's injection (Logic confinement 3, 8 and 14); no change to the page's rules

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./capability-backed-sharing.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/capability-backed-sharing.md`.

</details>

NOTE: End of Capability-Backed Sharing.

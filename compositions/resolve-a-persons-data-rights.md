---
title: Resolve a Person's Data Rights
parent: Conceptual Compositions
nav_order: 20
has_toc: true
toc: true
---

# Resolve a Person's Data Rights

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Resolve a Person's Data Rights is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: when a person exercises their legal right to see or to delete the personal data an organization holds about them, the organization must work out, for *every* record, what to do — and prove afterward that it did the lawful thing, using only the records it kept. The difficulty is that the request collides with other rules: some records are under a legal hold that forbids deletion, some must be kept for a legally mandated period, and some were collected under a consent that may since have been withdrawn. This composition resolves this one record at a time. It assigns every record in the person's data a single **disposition** — a recorded verdict — and the set of allowed verdicts is fixed: for an access request, a record is [Included] (handed over) or [Withheld] with a stated reason (it implicates a third party, or a legal exemption applies); for an erasure request, a record is [Erased], or [Retained] with a stated reason (a legal hold blocks deletion, a retention period has not elapsed, or another lawful basis still applies) — and a record whose fate or basis could not be settled is an [Anomaly], carrying its reason, rather than silently either.

It wires three constituents. Selective Disclosure is the running log of every time the person's data was shared and with whom — read to answer the access right's "who has my data been disclosed to?" and written to record the act of responding to the request itself. Defensible Retention is the substrate (a composition this one is built on, used through its declared surface) that supplies the deletion gate: its built-in rule that "a record under an active legal hold cannot be purged" *is* the structural answer to the erasure-versus-preservation collision, and through it this composition reaches Legal Hold, Retention Window, and the tamper-evident Audit Trail without maintaining duplicates. Consent is consulted as a read-only oracle (a source asked for an answer and never written to) — this composition asks it "was consent the basis for processing this, and is that consent still in force?" to decide whether erasure is actually due, but this composition never changes a consent record.

The composition's defining emergent guarantee (a property that appears only when the atoms are combined — no single atom carries it) has two halves. **No-silent-omission:** every record in the person's enumerated data universe carries exactly one disposition, so nothing is quietly left out of a response — the completeness an auditor checks. **Binding bijection** (a one-to-one binding, with nothing unmatched on either side): a fulfillment binds the complete set of dispositions, the record of the disclosure to the requester, and the sealed Audit Trail event — so there is never a fulfilled request whose disposition record is missing or incomplete. The sealed event is written last and cannot be withdrawn once written, so an event always has its disclosure behind it; the reverse gap is reachable, always surfaced, and compensated (Invariant 1). This composition enforces the structural gate (an active hold blocks erasure) and records each disposition with an auditable reason; it does not rule on the legal fine print of whether a particular exemption truly applies — that is named as counsel's and a composing pattern's job, not absorbed here.

 Its most common uses are GDPR (the EU General Data Protection Regulation) Article 15 access and Article 17 erasure fulfillment, CCPA/CPRA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) consumer access and deletion requests, and HIPAA (the US Health Insurance Portability and Accountability Act) section 164.524 access to a designated record set. Any system that must answer a data subject's access or deletion request *and* prove, from records alone, that every record was dispositioned and that legal holds and retention obligations were honored throughout, is a candidate for this composition.

---

## Intent

Every system that holds personal data must, on demand, answer a data subject exercising a statutory right — and the hard part is not the happy path of handing over or deleting data, it is the *conflict* the request surfaces. A right-of-access request (GDPR — the EU General Data Protection Regulation — Article 15) says *show me everything you hold about me*. A right-of-erasure request (GDPR Article 17, the "right to be forgotten") says *delete it*. But the same records are often subject to a **legal hold** that forbids destruction (litigation is anticipated, a regulator is investigating), to a **retention obligation** that mandates keeping them for a statutory period, and to a web of **consent** decisions that determine whether the data could lawfully be processed at all. These claims do not merely coexist; on a single record they actively contradict one another. *Delete this* and *you may not delete this* cannot both be honored. The system must choose, per record, and — this is the regulated bar — it must be able to prove afterward that the choice it made was the lawful one, from the records alone, without a developer in the room to narrate what the code did.

This is the friction this composition exists to resolve, and naming it precisely is what keeps the composition honest: **This composition is not a "rights system"; it is a conflict-resolution system over competing truth claims about a record universe.** Four claims collide on the subject's records — *access* (Article 15: show everything), *erasure* (Article 17: remove, or justify non-removal), *legal hold and retention* (via Defensible Retention: you cannot remove this, regardless of the clock), and *consent* (the lawful-basis question: are you allowed to act at all?). The resolution surface is a **per-record disposition** — a single recorded, attributed verdict for every record in the subject's enumerated universe — plus a **no-silent-omission** completeness guarantee that no record escapes the enumeration without a disposition. A DSAR (Data Subject Access Request — the umbrella term for a subject exercising any of these rights) is fulfilled not when data is handed over or deleted, but when *every* in-scope record carries a disposition an auditor can read and defend.

No single constituent resolves the collision. Selective Disclosure records *that* a disclosure occurred — to whom, what scope, under what authority — but it does not enumerate a subject's record universe, does not perform or block erasure, and does not know what a legal hold is. Defensible Retention owns exactly the erasure-versus-preservation gate: its hold-blocks-purge invariant is the structural rule that *delete this* yields to *you may not delete this*, and its Retention Window leg supplies the *kept-for-a-statutory-period* exemption — but Defensible Retention knows nothing of access requests, disclosure accounting, or consent as a lawful basis. Consent owns the grant/revoke/expire lifecycle and the point-in-time `check` that answers *was there a lawful basis?* — but it is, by its own specification, not an enforcement surface and not an orchestrator. The structure that enumerates the universe, resolves each record's competing claims into one disposition, records every response-disclosure, and seals the whole fulfillment as one accountable act belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Selective Disclosure, Defensible Retention, and Consent are unchanged; this composition is the wiring that makes them coherent as a single rights-fulfillment surface. It introduces emergent actions — [Receive Request], [Fulfill Access Request], [Fulfill Erasure Request], and the read-only [Disposition Report] — that belong to no single constituent and exist only because the three are wired together. The erasure action in particular **wraps Defensible Retention's `purge_record` gate**: the same hold-blocks-purge decision Defensible Retention already makes becomes, at this composition's layer, the mapping from a gate outcome to a recorded per-record disposition (`ok` → erased, `under-legal-hold` → `retained(legal-hold)`, `not-eligible` → `retained(retention-obligation)`), with this composition adding only the consent-basis branch (Article 17(1)(b) — *was consent the only basis, and is it gone?*) and the enumeration-and-completeness structure that makes the answer cover the whole universe rather than one record at a time.

A load-bearing scoping decision follows from the reframe. The composition's **spine is Access (Article 15) and Erasure (Article 17) only** — the two rights whose claims most sharply collide and whose fulfillment most needs the per-record disposition surface. The other rights in the Article 15–20 family (rectification under Article 16, restriction under Article 18, portability under Article 20, objection under Article 21) are lighter variants of the same fulfillment surface or are named composing concepts; modeling each as a first-class lifecycle would inflate the composition without exercising a structurally new claim-collision. They are named in Non-goals, not absorbed.

What the composition is *not*: it is not the identity-verification surface that confirms the requester actually is the subject (or their authorized representative) — that is a Party Identity / Actor Identity composing concept, named not absorbed; it is not the legal adjudicator that decides whether a given Article 17(3) exemption genuinely applies (an Erasure Coordination composing concept, and ultimately counsel's call) — this composition records the asserted disposition and its reason, and routes the legitimacy question to an externally-clearable check; it is not the data-extraction or redaction engine that assembles the access payload (the host's obligation, signalled by the included dispositions); it is not the deletion engine for records outside the library's stores (a host obligation named in the completeness boundary); and it is not a statutory-deadline clock that computes or enforces the one-month fulfillment window under Article 12(3) (this composition records `received_at` and `fulfilled_at` as the records-alone source; whether the deadline was met is an externally-clearable or composing concept). Each is named explicitly in Non-goals.

---

## Composes

- **[Selective Disclosure](../atoms/selective-disclosure.md)** — the disclosure-accounting surface, used in both directions: read for the subject's recipients, written for the response to the requester.
- **[Defensible Retention](./defensible-retention.md)** — the regulated retention-governance composition, used as a substrate: the erasure gate, and the Legal Hold, Retention Window and Audit Trail instances reached through it.
- **[Consent](../atoms/consent.md)** — a read-only authority oracle: was consent the basis for processing a record, and is that consent still in force.

```
Composes 1: EXACTLY ONE Selective Disclosure instance MUST serve the composition.
Composes 2: EXACTLY ONE Defensible Retention instance MUST serve the composition.
Composes 3: EXACTLY ONE Consent instance MUST serve the composition.
Composes 4: The composition MUST reach a transitive pattern ONLY through Defensible Retention.
Composes 5: The composition MUST NOT compose an instance of a transitive pattern.
Composes 6: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 7: The composition MUST NOT change a constituent's spec.
Composes 8: The composition MUST record the composition's own events through the audit write on the Audit Trail instance Defensible Retention carries.
Composes 9: The composition MUST call Selective Disclosure ONLY through the disclosure write AND the disclosure read.
Composes 10: The composition MUST enumerate a subject's records ONLY through the universe enumeration.
Composes 11: The composition MUST NOT own a constituent's store.
Composes 12: The composition MUST read the trail ONLY through the trail read.
Composes 13: The composition MUST select a trail event in the composition's own code.
Composes 14: The composition MUST read a retention ONLY through the retention read.
```

Term composition: this pattern's wiring of [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md) and [Consent](../atoms/consent.md) — the intake, the two fulfillment siblings, the report, the two indexes and the reconciliation.

Term constituents: [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md), [Consent](../atoms/consent.md).

Term transitive pattern: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) or [Audit Trail](./audit-trail.md), reached through Defensible Retention, and [Event Log](../atoms/event-log.md), reached through Audit Trail.

Term audit write: Audit Trail's record_action on the Audit Trail instance Defensible Retention carries.

Term trail: the events of the Audit Trail instance Defensible Retention carries — this composition's own and the substrate's, in one log.

Term trail read: Event Log's read by an open-ended sequence range, on the Event Log instance Audit Trail carries, reached the way Defensible Retention reaches the same log (Defensible Retention Composes 12 through 14).

Term retention read: Retention Window's read on the business retention instance Defensible Retention carries — every retention with the retention's record reference, retention state, retention deadline and, where the retention stands purged, purge instant.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term universe enumeration: the composition-introduced surface that enumerates a subject's in-scope records over the record source registry — the Defensible Retention-managed records being the registered records a source answers a retention id for — each with its record reference, its source and its creation instant — the eventual home of a Completeness Model atom *(forthcoming)*.

WHY:
**Selective Disclosure is used in both directions.** *Read*, an access fulfillment answers GDPR (the EU General Data Protection Regulation) Article 15(1)(c) — *the recipients to whom the personal data have been disclosed* — from the records alone. *Write*, every fulfillment records its response to the requester as one disclosure, so the release of the subject's own data back to them is itself an accountable, immutable disclosure event. This settles, in favour of recording, the deployment-policy question Selective Disclosure Non-goal 20 leaves open: a regulated rights-fulfillment surface records its own responses.

**Defensible Retention is a substrate, named the way an atom is named** (Composes 4 and 5; the section titled Compositions of compositions in `spec-format.md`). It is the erasure path: every record an erasure would destroy is gated through its purge, whose answers map onto this composition's erasure dispositions (Disposition 20 through 46). Through it the composition inherits the hold-blocks-purge gate (Defensible Retention Invariant 1), the retention-not-elapsed refusal, and the tamper-evident, attributed Audit Trail on which the composition records its own events (Composes 8) — the substrate-composition pattern Multi-Party Approval established: Audit Trail's own declared record_action and its Invariant 1, reached through the named substrate, not an ambient reach-through. One substrate instance; no duplicate Legal Hold, Retention Window or Audit Trail at this layer.

**Three reaches into the substrate's instances are declared, and there is no fourth** (Composes 8 and 12 through 14; the section titled Substrate composition invocation in `execution-contract.md`). The audit write records this composition's events. The trail read is how the composition finds them again — a request's state, an open intent, a fulfilled event already landed — and it is the read the substrate itself declares over the same log: an open-ended sequence range, with every selection made in this composition's own code, as the substrate's own composer reads it. The retention read is the store's own answer to *does this retention id cover this record, and is the record gone*: a pairing confirmed there is confirmed for every retention, elapsed or not, and a retention that reads purged is a destruction the store itself attests. Each is a constituent's own declared surface on the instance the substrate carries; none reads a store beside its declared read.

**Consent is an oracle, never written** (Invariant 7). The erasure path asks it whether consent was the basis for a record and whether that consent is still in force — the Article 17(1)(b) determination. A subject who withdraws consent does so through [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); this composition reads the state that produces.

**The universe enumeration is composition-introduced** (Composes 10; the section titled *Capability provenance* in `pressure-testing.md`). No constituent enumerates a subject's record universe with a verdict per record — Selective Disclosure enumerates disclosures, Consent consents, Defensible Retention retentions. Its eventual home is a Completeness Model atom, *accountable enumeration of a record universe with per-record disposition*, framed as a shared primitive this composition and Customer Onboarding both exercise and this composition merely exposes — the same discipline by which Immutable Transaction Ledger seeded a Subset Proof atom rather than owning subset verification. Until it lands, the surface is bounded by the record source registry (Capability requirement 1).

The Selective Disclosure and Consent stores are owned by their instances, the Legal Hold, Retention Window and Audit Trail stores by the substrate; the composition indexes across them and owns none (Composes 11). It reads the disclosure store through the atom's read and adds to it through the atom's record and through nothing else, which is the reading of Selective Disclosure Composition note 9 that the atom's own account of this composition bears out.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the request index.
Composition state 2: The composition MUST key the request index by request id.
Composition state 3: A request entry MUST carry the subject reference, the right type, the requester, the regulatory reference AND the received instant.
Composition state 4: The composition MUST write a request entry ONLY AFTER the intake event lands.
Composition state 5: The composition MUST NOT change a request entry.
Composition state 6: The composition MUST store the fulfillment index.
Composition state 7: The composition MUST key the fulfillment index by request id.
Composition state 8: A fulfillment entry MUST carry the right type, the fulfilled instant, the dispositions, the response disclosure id AND the fulfillment event id.
Composition state 9: The composition MUST write a fulfillment entry ONLY AFTER the fulfilled event lands.
Composition state 10: A fulfillment entry MUST carry the dispositions the fulfilled event carries.
Composition state 11: The composition MUST NOT change a fulfillment entry.
Composition state 12: The composition MUST classify a live entry as a derived index.
Composition state 13: The composition MUST rebuild a missing live entry from the entry's event.
Composition state 14: The composition MUST classify an aged entry as extraction-pending against Erasure Tombstone.
Composition state 15: The composition MUST derive a request's state from the request's events, the fulfillment index AND the request-scoped disclosures.
Composition state 16: IF a fulfillment entry EXISTS for the request THEN the request's state MUST carry Fulfilled.
Composition state 17: IF an open intent EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 18: The composition MUST NOT store a subject's enumerated universe.
Composition state 19: IF a fulfilled event carrying the request id EXISTS THEN the request's state MUST carry Fulfilled.
Composition state 20: The composition MUST NOT answer not-known BEFORE rebuilding the request index.
Composition state 21: The composition MUST read a fulfilled event carrying no fulfillment entry as a rebuild trigger.
Composition state 22: IF the state read fails THEN the action MUST answer state-unavailable.
Composition state 23: An action answering state-unavailable MUST NOT record an event.
Composition state 24: IF an unbound disclosure EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 25: An index write that fails MUST NOT change an action's answer.
```

Term request id: the opaque id the host injects at [Receive Request]'s seam — never reused.

Term request index: the composition's map from a request id to the request's intake — `request_to_subject` in an implementation.

Term request entry: one request id's subject reference, right type, requester, regulatory reference and received instant.

Term fulfillment index: the composition's map from a request id to the request's fulfillment — `request_to_fulfillment` in an implementation; the queryable mirror of the sealed fulfilled event.

Term fulfillment entry: one request id's right type, fulfilled instant, [Dispositions], response disclosure id and fulfillment event id.

Term live entry: an index entry whose event's payload the audit horizon has not reached.

Term aged entry: an index entry whose event's payload the audit horizon has destroyed.

Term request's events: the composition's events carrying one request id, selected over the trail read.

Term unbound disclosure: a request-scoped disclosure carrying the request id of a request that carries no fulfilled event and no fulfillment entry.

Term state read: the reads a fulfillment or [Disposition Report] derives the request's state from — the request's events, the disclosure read of the request's subject reference, and the rebuild of a missing index entry. The state read fails where one of them fails and no fulfillment entry already settles the state as Fulfilled.

Term intake event: the dsar.received event.

Term intent: the access intent or the erasure intent.

Term aged event: an event whose age — the injected now less the event's recording instant — is no less than the audit horizon less twice the clock offset allowance — an event the audit instance may already have destroyed, or a later neighbour of it. Two allowances, because the substrate places an event's retention on one clock after the log stamped the event on another, and judges the purge on the first against a now this composition reads on a third.

Term open intent: an intent, no aged event, whose invocation id no abandonment carries, of a request carrying no fulfilled event and no fulfillment entry.

Term fulfilled event: the dsar.access_fulfilled or dsar.erasure_fulfilled event.

Term abandonment: the dsar.intent_abandoned event — carrying the invocation id of the intent it closes, returning the request to Received.

Term request state: Received | Committing | Fulfilled — derived, never stored: Fulfilled where Composition state 16 or Composition state 19 holds, Committing where Composition state 17 or Composition state 24 holds, and Received everywhere else. An open intent and an unbound disclosure are each defined over a request carrying no fulfilled event and no fulfillment entry, so no request reads two.

WHY:
**Two indexes, one sealed truth** (Composition state 1 through 11). The request index is the intake's provenance — *that* a request was received, for which subject, of which type, from whom, under which regulation, and when — the records-alone source for the statutory clock and the join from a request id back to its subject. The fulfillment index is the binding backbone: the complete [Dispositions] over the enumerated universe, the response disclosure and the fulfilled event. The fulfilled event carries the complete disposition set in its payload, so the index is the queryable mirror of a sealed event, never an independent store an edit could silently diverge from (Composition state 10). Both are written once, after the event they mirror lands, and never changed; Fulfilled is terminal.

**Classification** (Composition state 12 through 14; the section titled Composition state in `execution-contract.md`). A live entry rebuilds from its event and is a derived index — on a miss, and by the reconciliation for a fulfilled event whose entry was never written (Reconciliation 25), so an entry exists well before its event can age. The deployment keeps both indexes for the life of the instance (Capability requirement 50), because of what an entry becomes next. Past the audit horizon the substrate's purge destroys the event's payload, and the entry is then the only carrier of what was decided — extraction-pending, its eventual home the same Erasure Tombstone *(forthcoming)* that carries Audit Trail's purged pairs. For a fulfilled erasure that is load-bearing rather than tidy: the entry may be the only surviving description of records that no longer exist.

**The request state is derived from the trail, and the index only mirrors it** (Composition state 15 through 21). Received is an intake and nothing open after it; Committing is an open intent — a fulfillment in flight, or one that died after its intent; Fulfilled is a fulfilled event, or past the horizon the entry that outlived it. The three do not overlap: an intent is open only while its request carries no fulfillment entry, no fulfilled event carries its invocation id and the horizon is not near it, so a fulfilled request whose event the substrate has destroyed ahead of its intent does not read Committing, and no leg seals it again. And a request that wrote a response disclosure does not fall back to Received because its intent aged out unclosed: the disclosure never ages, and while it is bound to no fulfilled event and no entry the request reads Committing (Composition state 24), so no later fulfillment writes a second one. A fulfilled event whose entry was never written — the process died between the two — still reads Fulfilled, because the event is read and the entry is rebuilt from it; were Fulfilled read off the entry alone, that request would read Received and be fulfilled a second time. An index miss is likewise never an absent request: the index is rebuilt from the intake events before not-known is answered. And a trail that cannot be read is never a request with nothing on it: the action answers state-unavailable and writes nothing, where falling back on the index alone would read a Committing request as Received (Composition state 22 and 23). **Committing is the state an earlier draft lacked**, and its absence let a re-invocation re-run a fulfillment: a request whose fulfillment failed after its response disclosure or its purges had committed read as Received, the caller retried on the page's own advice, and the retry wrote a second permanent disclosure, a second sealed event racing the first's compensation, and dispositioned already-erased records as registry anomalies. A Committing request is refused by both siblings (Action wiring 6) and closed only by the reconciliation or by the invocation's own abandonment.

**An intent is open or closed by the invocation id** (Term open intent; the section titled *Intents pair with outcomes by an invocation identity the seam injects* in `pressure-testing.md`). A request can carry several intents over its life — one abandoned, then one that seals — and the fulfilled event or the abandonment that closes an intent carries that intent's own invocation id, so which record answers for which intent is never read off the request id or the order of the log.

**The universe is not stored** (Composition state 18): it is computed at fulfillment by the universe enumeration, and the fulfillment entry's [Dispositions] *is* the durable, records-alone snapshot of it as it stood at the enumeration instant.

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the record source registry.
Capability requirement 2: EVERY registered source MUST expose a subject-scoped enumeration answering the record reference, the source, the creation instant AND the route PER record.
Capability requirement 3: EVERY registered source MUST expose the declared basis PER record.
Capability requirement 4: EVERY registered source MUST expose the host determinations PER record.
Capability requirement 5: EVERY route MUST carry EXACTLY ONE OF a retention id, the host delete.
Capability requirement 6: The host delete MUST verify the presented credential at the host's own boundary.
Capability requirement 7: The universe enumeration MUST NOT enumerate an accounting store.
Capability requirement 8: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 9: A deployment MUST set an audit retention policy whose horizon EXCEEDS the longest retention obligation a registered record carries.
Capability requirement 10: The Defensible Retention instance MUST run strict as the hold check mode.
Capability requirement 11: The composition MUST NOT claim the hold guarantee over a Defensible Retention instance running advisory.
Capability requirement 12: A deployment MUST provision the service identity.
Capability requirement 13: The composition MUST attest EVERY audit write the composition makes outside a caller's invocation under the service identity.
Deleted: Capability requirement 14. Capability requirement 37 owns it.
Deleted: Capability requirement 15. Capability requirement 37 owns it.
Capability requirement 16: A deployment MUST set the compensation window.
Capability requirement 17: A deployment MUST set the fulfillment completion bound.
Capability requirement 18: A deployment MUST set the reconciliation cadence.
Deleted: Capability requirement 19. Capability requirement 39 owns it.
Capability requirement 20: A deployment MUST declare the clock offset allowance.
Capability requirement 21: The host MUST inject now at the seam once per invocation.
Capability requirement 22: The host MUST inject a request id that names no other request at [Receive Request]'s seam.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 24: The composition MUST NOT pass now to a constituent.
Capability requirement 25: The host MUST inject one invocation id that names no other invocation at the seam PER state-changing invocation.
Capability requirement 26: The composition MUST NOT take an invocation id as an input.
Capability requirement 27: A deployment MUST supply a Lease host PER Lease Capability requirement 1, 2, 4, 5, 7 and 11.
Capability requirement 28: A deployment MUST set the call pause bound.
Capability requirement 29: A deployment MUST set the section term.
Capability requirement 30: A deployment MUST set the section read bound.
Capability requirement 31: The section work bound MUST include twice the call pause bound (Lease Sizing 4).
Capability requirement 32: A deployment MAY start an instance ONLY IF the section term EXCEEDS the section work bound (Lease Sizing 4a).
Capability requirement 33: A deployment MAY start an instance ONLY IF the section work bound EXCEEDS the record start floor (Lease Sizing 9).
Capability requirement 34: The section term MUST NOT EXCEED the fulfillment completion bound.
Capability requirement 35: A deployment MUST disclose the planned call latency.
Capability requirement 36: A deployment MUST supply a Selective Disclosure instance, a Defensible Retention instance, a host delete AND an audit instance bound by Lease Capability requirement 8 and 10 for EVERY call the composition issues under the request section.
Capability requirement 37: A deployment MUST supply the alerting surface.
Capability requirement 38: A deployment MUST supply the scheduler.
Capability requirement 39: A deployment MAY start an instance ONLY IF the compensation window EXCEEDS the closure floor.
Capability requirement 40: A deployment MUST set the text cap.
Capability requirement 41: A deployment MUST route EVERY disclosure write carrying a request scope through the composition alone.
Capability requirement 42: A deployment MUST route EVERY audit write carrying a composition action reference through the composition alone.
Capability requirement 43: The scheduler MUST survive the loss of one process.
Capability requirement 44: EVERY registered record MUST carry a record reference no other registered record carries.
Capability requirement 45: A deployment MUST disclose the audit write latency PER Defensible Retention Capability requirement 22.
Capability requirement 46: The host MUST inject now at the seam once PER leg.
Capability requirement 47: EVERY registered source MUST answer a retention id for a record a retention of the business retention instance covers.
Capability requirement 48: A deployment MAY start an instance ONLY IF the audit horizon EXCEEDS the alert floor.
Capability requirement 49: A deployment MUST set an audit retention policy that answers one policy for EVERY composition action reference.
Capability requirement 50: A deployment MUST persist the request index AND the fulfillment index for the life of the instance.
Capability requirement 51: EVERY registered source MUST answer EVERY source text within the text cap.
Capability requirement 52: A deployment MUST NOT serve two instances of the composition by one Defensible Retention instance.
Capability requirement 53: A deployment MUST NOT serve two instances of the composition by one Selective Disclosure instance.
Capability requirement 54: A deployment MUST NOT change the audit retention policy for the life of the instance.
```

Term record source registry: the deployment-declared list of the business-record sources over which the no-silent-omission guarantee holds, with the per-record surfaces each exposes.

Term creation instant: a record's creation time in its source, stamped by the source's own clock.

Term declared basis: the lawful ground a registered record names for its processing — consent carrying a purpose, a non-consent ground such as legal-obligation, contract or vital-interests, or none.

Term host determinations: the host's per-record Article 15(4) third-party-confidentiality and legal-exemption determinations, consumed by the access dispositions.

Term host delete: the registry-declared delete surface of a host-managed record — `delete(record_ref, actor_ref, credential)` answering deleted carrying the attestation reference, refusing invalid-credential, not-known, retained carrying the basis, or delete-failed.

Term route: how a registered record is erased, answered by the record's source in the enumeration itself — a retention id, the gated path, or the host delete. A source that answers a record with no route has failed to enumerate (Action wiring 12).

Term host-managed record: a registered record whose route carries the host delete — erased through the host delete, never through Defensible Retention's gate.

Term accounting store: the Selective Disclosure store or the Consent store — the composition's accounting of the subject, read as response content and never enumerated.

Term audit horizon: the horizon of the one policy the audit retention policy answers for this composition's action references (Capability requirement 49), on the Audit Trail instance Defensible Retention carries.

Term hold guarantee: Defensible Retention Invariant 1 read over the records this composition's fulfillments purge — no record an active hold covers at the gate is destroyed through a fulfillment.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` in configuration.

Term compensation window: the duration within which the reconciliation closes an open intent or alerts on the intent.

Term fulfillment completion bound: the longest a fulfillment may run from its intent to its fulfilled event — the reconciliation's lower edge.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every process start.

Term clock offset allowance: the deployment's declared envelope between two clocks' readings of one moment (Execution Contract Logic confinement 7) — the value Defensible Retention reads under the same name — allowed here wherever a reading of now is set against a registered source's creation instant, a constituent's stamp or another invocation's reading of now.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the request id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

Term invocation id: the id the host injects at the seam for one state-changing invocation — a [Receive Request] call or a fulfillment. Every record the invocation writes carries the id, and a record the reconciliation writes carries the id of the intent the record closes.

Term request section: the [Lease](../atoms/lease.md) this composition takes on a request id — the key is the request id under this instance's own namespace on the host (Concurrency 5) and the holder value is minted fresh for each take — under which one fulfillment or one leg over the request runs, from its first read of the request's state to its last call.

Term call pause bound: this composition's value of Lease's call pause bound — the longest time from the decision to issue one call to the moment the call has taken effect or failed. It bounds a lease call and the disclosure write, and never a whole audit write or a whole planned call (Lease Capability requirement 7).

Term section term: the duration every take of the request section asks for (Lease Composition note 5d).

Term section read bound: section_read_bound — the deployment's declared longest time a fulfillment or a leg spends, from a take's answer, on the reads it makes before its first write: the state read, the enumeration and the disposition reads, the retention read among them.

Term section work bound: `section_read_bound + audit_write_latency + 2 * call_pause_bound + plan_floor` — the reads, the intent with its own reading, and one planned call with the bind after it, so a term that exceeds the bound admits the intent, one planned call, the disclosure write and the fulfilled event. A further planned call the grant no longer admits leaves its record unsettled, so no fulfillment's work outruns the grant.

Term planned call latency: the deployment's disclosed longest time from issuing a planned call to the landing of the call's last write, an abandoned call's included, and to the answer of the retention read a not-known obliges. The unit's bound of a planned call under the request section (Lease Composition note 8a); a planned call that has not answered within it answers no answer.

Term record start floor: `audit_write_latency + 2 * call_pause_bound` — the remaining term an audit write needs to land inside the grant, the audit write latency being the unit's bound of an audit write (Lease Composition note 8a). A floor admits a call whose reading of Lease's remaining answers a remaining term exceeding the floor (Lease Sizing 5).

Term bind floor: `record_start_floor + 3 * call_pause_bound` — the remaining term the disclosure write and the fulfilled event after it need: the write within one pause of its reading, landing within another, and the event's own reading a third. The floor stands above the write margin, so a reading it admits is a live reading (Lease Sizing 2).

Term plan floor: `planned_call_latency + 2 * call_pause_bound + bind_floor` — the remaining term below which a fulfillment makes no further planned call, so that the bind still has the bind floor once the planned call has landed.

Term lease reading: live | expired — what a reading of Lease's remaining says of the grant, as Lease declares the two (Lease Sizing 2, Lease Sizing 2a, Lease Sizing 7).

Term closure floor: `fulfillment_completion_bound + 2 * clock_offset_allowance + reconciliation_cadence + section_term` — the longest interval in which a run that takes the request section closes an open intent: the intent's age at the lower edge, read at a seam that may stand an allowance either side of the intent's, one cadence to the next run, and the leg's own grant.

Term alert floor: `2 * compensation_window + 2 * reconciliation_cadence + 5 * clock_offset_allowance` — the age by which a run has met an overdue intent, the deployment has had a window to answer the alert, and a run has followed the answer, while the intent is still no aged event: the window, one cadence to the run that alerts, a second window for the alert to be answered in, a second cadence to the run that follows the answer, and five allowances — two where a leg reads overdue against an instant another seam stamped, the allowance in the test and the offset between the two seams, and three where a later leg reads aged against the log's stamp, the two the aged test gives up and the offset between that leg's seam and the log's.

Term source text: a string a registered source or the host delete supplies and a reason carries whole — a purpose, a non-consent ground, a determination's reference, a host's basis or an attestation reference.

Term text cap: text_cap — the deployment's declared maximum size of one source text.

Term reason bound: the size of the largest reason a disposition can carry — its ids, its answers and its instants at the deployment's longest, EVERY source text at the text cap, and the hold ids at Defensible Retention's hold ids cap. No reason is truncated.

Term alerting surface: the deployment's surface on which the composition and the deployment alert.

Term scheduler: the deployment's facility that runs the reconciliation at every process start and at the reconciliation cadence.

WHY:
**The registry is the load-bearing host obligation** (Capability requirement 1 through 7). The universe is the subject's records under the Defensible Retention substrate plus the host business-record stores the registry names, and the registry is the declaring source for every host-supplied capability a disposition rests on: the enumeration with each record's creation instant (which lets an access re-check drop records created after the fulfilment); the declared basis the erasure's other-lawful-basis branch reads; the access determinations; and, for erasure, a retention id — the gated path — or the host delete, whose contract is declared so every arm has a landing. A record reference names one registered record and no other (Capability requirement 44): a disposition, a retention reading and a plan are each keyed by the reference alone, and two sources answering one reference for two records would have one record's destruction read as the other's. The host delete verifies the credential at its own boundary, as Defensible Retention does at its, because it is independently callable (Capability requirement 6). A record a retention covers is answered with its retention id and never with the host delete (Capability requirement 47): a registry that sent such a record to the host delete would destroy it past the gate, hold or no hold. The route is part of the enumeration's own answer, so a source that cannot say it has not enumerated, and a host-managed record is planned only where the retention read, already in hand, shows no retention over it (Disposition 14 and 18). Declaring these here is what keeps every disposition capability-provenance-clean: its authority traces to declared configuration, not to an ambient *the host knows*. No-silent-omission is a guarantee over the *declared* universe; whether the registry names every store holding the subject's data, and whether each host determination is legally correct, are the host's to clear (External check 1 and 2).

**The accounting stores are response content, not universe** (Capability requirement 7). Their records are append-only and never removable (Selective Disclosure Invariant 6; Consent Invariant 8), expose no declared basis, no retention id and no delete surface — so no erasure branch could resolve one — and they are the composition's accounting of the subject rather than the subject's business records. They answer the recipients and consent-history limbs of an access response, and under erasure they are retained as a class (Accounting stores 1).

**Retention is the substrate's, and it outlives the erasure** (Capability requirement 8 and 9; 2026-08-26-o). record_action takes no per-call retention, so the composition's events land under the instance's policy. The proof that a record was lawfully erased must outlive the record — for FRCP (the US Federal Rules of Civil Procedure) Rule 37(e) spoliation defence above all — so the horizon exceeds the longest retention obligation any registered record carries, an obligation with an owner and a check (Check 8.2) where the prose had a *should*. **And it is one horizon** (Capability requirement 49). The substrate lets a deployment choose a policy by action reference, actor or payload; were an intent kept longer than the fulfilled event that closed it, the intent would outlive its own closing record, read open, and be compensated a second time. One policy for every event this composition records is what lets *aged* be one test, on an event's age alone. It is one for the life of the instance too (Capability requirement 54): an edge read from a period the older events were not placed under is wrong for every one of them.

**One instance of the composition for each instance it writes** (Capability requirement 52, Capability requirement 53). Two instances over one Defensible Retention instance share one trail and take request sections the other does not see, so each reconciliation would read the other's intents as its own; two over one Selective Disclosure instance would each find the other's request-scoped disclosures.

**Strict mode is required** (Capability requirement 10 and 11). The erasure gate is mode-conditional in the substrate: under advisory, a held record is purged with a hold override and the purge answers ok. A deployment running an advisory substrate has a rights composition that erases held records and says so in the substrate's own record, and the hold guarantee does not hold there; Check 3.1 tests the assumption on every destruction record it reads.

**The service identity and the alerting surface** (Capability requirement 12, 13 and 37). Every audit write outside a human invocation — the reconciliation's recovery intents, its compensating events and its abandonments — is attested under the composition's own registered identity, the service-identity discipline Multi-Party Approval established. What a person must act on — an open intent the window did not close, a fulfilled event carrying an anomaly, a deployment fault — is raised on the alerting surface the deployment supplies. An earlier revision recorded each of these as a finding event with an opening and a closing; the closing had no writer, the opening had one per run, and everything a finding said was already in the records it was derived from — the open intent, the recovery intent, the compensation flag, the anomaly in the sealed set. The records stay the evidence; the alert is the signal.

**The window is arithmetic** (Capability requirement 16 through 18 and 39; the section titled *Liveness is arithmetic* in `pressure-testing.md`). Invariant 1's liveness half is a claim about the window and is unstatable without it — *eventually* is not auditable. An open intent is invisible to the reconciliation until the fulfillment completion bound and the allowance have elapsed; the next run is at most a cadence later; the leg that takes the request section closes the intent inside its own grant. *Cadence no longer than the window* — the form this page carried before — is satisfied by a deployment that breaches the window on every orphan, so the terms are named, the comparison is strict, and an instance whose numbers do not satisfy it does not start. A run that finds the section held leaves the intent to the next run, and an intent the window did not close is alerted on (Reconciliation 22). The alert floor is inside the audit horizon (Capability requirement 48), so a run meets an overdue intent, and alerts on it, a full window and a cadence before the intent can read as aged — the alert has the window it is owed to be answered in, and a run follows the answer. A regulated deployment under litigation exposure sets the window against the FRCP spoliation clock; the composition prescribes no default, because the right value is a legal determination and a silent default would look like one having been made.

**The clock, and the two ids** (Capability requirement 20 through 26; Execution Contract Logic confinement 3 and 7). One now and one invocation id are injected per invocation, and at intake one request id; the now stamps every instant the invocation writes — the received instant, the intended instant, the fulfilled instant — so an invocation's intended and fulfilled instants are equal by construction and the Event Log sequence orders them. The now is never handed to a constituent: each stamps its own at its own seam, bound to this one by ids and never claimed equal, and Consent's check is asked with no at time, so the oracle judges a consent on its own clock alone and no reading of this seam's decides an erasure. Wherever a reading of now is set against an instant another clock stamped — a source's creation instant in the access re-check, another invocation's intended instant at the reconciliation's lower edge, a recording instant at the upper one — the comparison runs under the declared allowance (2026-08-29-j).

**The request section's host and its sizes** (Capability requirement 27 through 36; Lease Composition note 1). Two fulfillments of one request, a fulfillment and the reconciliation, and two runs of the reconciliation each look at the request's events and then write, and nothing a look-then-write protects survives a second writer between the look and the write. So every fulfillment and every leg over a request runs under one [Lease](../atoms/lease.md) on the request id, and the atom's sizing rules are this composition's own obligations (Concurrency 3 through 22). What the deployment supplies is the host and the numbers. The call pause bound is the premise the section rests on: a call issued on a live reading lands inside the grant only if no call stalls longer than the declared value. The section term exceeds the work bound, which is computed from the reads, the intent, one planned call and the bind, so that a fulfillment is always admitted that far, and it stays inside the fulfillment completion bound so that an invocation the reconciliation is old enough to examine has ordinarily stopped writing; one that has not still holds the section, and the leg leaves it. Of Lease's own requirements on a deployment, the host's are passed down by number (Capability requirement 27), and the two that bind whoever answers a holder's write bind the stores this composition writes under the section (Capability requirement 36). The one Lease requirement no party here meets whole is that a refused write was not applied: the substrate's step-3 refusal may hide an append still to land (Concurrency 20), and Defensible Retention's purge may answer storage-failure over a record its storage layer already destroyed (Defensible Retention Atomic writes 9). Each is read here as what it is.

**One surface for what the reconciliation pairs** (Capability requirement 41 and 42). The reconciliation closes an open intent by what it finds: a disclosure whose scope carries the request id, a fulfilled event carrying it. A disclosure written under a request scope by another caller, or an event written under one of this composition's action references by another caller, would be paired as this composition's own. The section serializes the writers that take it; these two rules are for the writer that takes nothing.

### Primitive policy

```
Primitive policy 1: IF the subject reference EQUALS blank THEN [Receive Request] MUST answer invalid-request.
Primitive policy 2: IF the requester EQUALS blank THEN [Receive Request] MUST answer invalid-request.
Primitive policy 3: IF the regulatory reference EQUALS blank THEN [Receive Request] MUST answer invalid-request.
Primitive policy 4: IF the right type IS NOT IN access and erasure THEN [Receive Request] MUST answer invalid-request.
Primitive policy 5: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 6: An action refused under Primitive policy 1 through 5 MUST NOT write.
Primitive policy 7: The composition MUST compare a request id, a subject reference, a record reference AND a retention id byte-exact.
Primitive policy 8: The composition MUST NOT normalize a caller string.
Primitive policy 9: The composition MUST NOT inspect a credential.
Primitive policy 10: The composition MUST pass the subject reference to Selective Disclosure AND Consent unchanged.
Primitive policy 11: The composition MUST pass the actor reference AND the credential to EVERY audit write, Defensible Retention purge AND host delete of the invocation.
Primitive policy 12: An enumerated fulfillment MUST NOT record the intent BEFORE sizing the largest record against the payload cap.
Primitive policy 13: IF the largest record EXCEEDS the payload cap THEN the fulfillment MUST answer invalid-request.
```

Term subject reference: the opaque reference to the data subject whose records are the universe.

Term right type: access | erasure — GDPR Article 15 or Article 17.

Term requester: the party who submitted the request — the subject, or an authorized representative; named as the recipient of the response disclosure.

Term regulatory reference: the regulation a request is filed under — "GDPR Article 15", "CCPA section 1798.105" — carried as the response disclosure's authority.

Term actor reference: the operator running an action — actor_ref.

Term credential: the operator's opaque credential material, validated by the substrate inside the audit write.

Term record reference: the opaque byte-identity of a record in the enumerated universe — the unit a disposition is recorded against.

Term retention id: the opaque Defensible Retention handle of a record under Defensible Retention retention — the input its purge takes.

Term caller string: a subject reference, a requester, a regulatory reference, an actor reference or a record reference.

Term largest record: the larger of a fulfillment's intent and the compensating fulfilled event the reconciliation would record for the fulfillment, each sized whole — every field the record carries, every id at the deployment's longest — with every disposition's reason at the reason bound.

WHY:
Every string-typed input is validated here or by a constituent, and nothing is case-folded, trimmed or normalized (Primitive policy 7 and 8); a deployment wanting normalization wires it at the calling layer. **The right type is two values by design** (Primitive policy 4): the spine is Access and Erasure, the two rights whose claims most sharply collide, and the lighter Article 16 through 21 rights are composing concepts, not further right types (Non-goal 6). **The regulatory reference is the request's own** (Primitive policy 3; 2026-08-29-g): a deployment answering both GDPR and CCPA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) requests cites the regulation each request was filed under on its response disclosure, where a hard-coded GDPR citation made the CCPA example false. The composition does not validate that the subject exists anywhere, or that the requester is the subject or a representative (Non-goal 1), or that the operator is authorized (Non-goal 2). The credential is opaque here; the substrate validates it inside the audit write, reached before any irreversible effect (Invariant 8), and the same actor and credential run every nested act of the invocation, so the substrate's destruction record and this composition's fulfilled event attribute a destruction to one actor (Primitive policy 11).

**The largest record is sized before the first one is written** (Primitive policy 12 and 13; Capability requirement 40 and 51; the section titled *An outcome is sized before the intent* in `pressure-testing.md`). A disposition set grows with the subject's universe, and the recipients and consent limbs with the subject's history; none has a cap a caller controls. An earlier revision let a set too large for the substrate's payload cap be carried as a digest and a count. Nothing that reads a set can read a digest: a compensation rebuilt from an intent carrying one has no dispositions to seal, and the sealed event would no longer be the complete set the binding claims. So the fulfillment is refused before its intent, with nothing written, when the largest record it could come to write — the intent, or the compensating event the reconciliation would write for it, whichever is larger — does not fit. The reasons are what make that size knowable in advance: a reason is settled after the intent, from a host's basis or a gate's hold ids, so each is sized at its bound — the ids and answers it always carries, and every string a source supplies at a declared cap the source is obliged to keep. Nothing in a reason is truncated: a reason cut to fit would lose the retention id or the purpose that makes it an authority (Invariant 4.1). A source text over the cap is a surface that failed, and lands as one — a basis or a determination unread, a host delete outside its contract. The refusal is invalid-request, the deployment's own fault and alerted on (Audit arm 19): the remedy is a payload cap sized to the deployment's largest subject, and the request stays Received until it is.

### Audit arm

```
Audit arm 1: The composition MUST read a recording-failure carrying step-4 as a landed record.
Audit arm 2: The composition MUST read an invalid-request carrying step-4 as a landed record.
Deleted: Audit arm 3. Audit arm 1 owns it.
Deleted: Audit arm 4. Audit arm 21 owns it.
Deleted: Audit arm 5. Audit arm 1 owns it.
Audit arm 6: IF Audit Trail answers invalid-credential at a pre-effect record THEN the action MUST answer invalid-credential.
Audit arm 7: IF Audit Trail answers recording-failure carrying a step below step-4 OR no answer at a pre-effect record THEN the action MUST answer recording-failure carrying intent.
Deleted: Audit arm 8. Audit arm 2 owns it.
Deleted: Audit arm 9. Audit arm 21 owns it.
Deleted: Audit arm 10. Action wiring 29 owns it.
Deleted: Audit arm 11. Audit arm 21 owns it.
Deleted: Audit arm 12. Audit arm 1 owns it.
Deleted: Audit arm 13. Audit arm 21 owns it.
Deleted: Audit arm 14. Concurrency 18 owns it.
Audit arm 15: The composition MUST read a closing record Audit Trail refuses on a credential as an owed record.
Audit arm 16: A caller MUST read recording-failure carrying intent as no disclosure AND no destruction made by the call.
Audit arm 17: A caller MUST read recording-failure carrying outcome as an irreversible act possibly committed.
Audit arm 18: The deployment MUST alert on a landed record carrying no retention.
Audit arm 19: The deployment MUST alert on an invalid-request a fulfillment answers.
Audit arm 20: IF Audit Trail answers invalid-request carrying a step below step-4 at a pre-effect record THEN the action MUST answer invalid-request.
Audit arm 21: A writer MUST NOT issue an audit write a second time.
Audit arm 22: The composition MUST read a recording-failure carrying a step below step-4 as an owed record.
Audit arm 23: The composition MUST read an audit write that answers no answer as an owed record.
Audit arm 24: The composition MUST read an invalid-request carrying a step below step-4 as an owed record.
Audit arm 25: A recording-failure [Receive Request] answers MUST carry the request id.
Audit arm 26: A caller MUST read a recording-failure from [Receive Request] as a request possibly Received under the carried request id.
Audit arm 27: The deployment MUST alert on an invalid-credential Audit Trail answers to a reconciliation record.
```

Term writer: one invocation, or one leg — what issues an audit write once. A record a leg left owed is the next leg's to issue.

Term pre-effect record: the intake event, the access intent or the erasure intent — a record written before any irreversible act.

Term position: intent | outcome — where a recording-failure sat: intent, no disclosure and no destruction committed; outcome, a permanent disclosure or a destruction possibly committed.

Term compensation flag: cascade_recovery set to true on a fulfilled event that landed through compensation rather than in the original invocation.

WHY:
The substrate's taxonomy maps **by what is in the log when it answers**, and the step says which (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). [Audit Trail](./audit-trail.md)'s record_action attests at step 2, appends at step 3 and places retention at step 4, so a refusal carrying step-4 — a recording-failure or an invalid-request — means the event is appended and attested, and the refusal carries the event's id (Audit arm 1 and 2). The composition proceeds as landed and the unretained event is the substrate's own reconciliation's (Audit arm 18). Below step-4 nothing is known to be appended, and the record is owed (Audit arm 22 through 24).

**No audit write is issued twice** (Audit arm 21). An earlier revision let the invocation retry a refused fulfilled event after reading the trail for one already landed, and called step-2 and step-3 alike *pre-append*. Step 3 is not: the substrate lands a store's refusal and an append that never answered on one token, and an append that never answered may still land — after the read that looked for it. A retry there puts two fulfilled events under one request, which the sealed trail then protects. So an owed record is never the invocation's to write again. An owed pre-effect record is answered as intent, with nothing irreversible done (Audit arm 7); an owed fulfilled event is the reconciliation's, which looks for it again under the request section once the first call can no longer land (Concurrency 20, Reconciliation 17).

**Before the irreversible act, every arm is a clean refusal** (Audit arm 6, 7 and 20): invalid-credential is the caller's; an owed record is answered as intent; invalid-request below step-4, with nothing appended, is a deployment fault, since a second call would re-send the identical payload. The intake's own invalid-credential answers as itself (2026-08-26-f, 2026-08-29-b). **An intake answered as a failure can still stand** (Audit arm 25 and 26): its event, appended late, is a Received request the caller was told had failed. The refusal carries the request id so the caller can read the report for it rather than learn of the request from an auditor.

**After it, no arm can refuse the act, only report it** (Audit arm 15 and 17; Action wiring 29). The fulfilled event follows a permanent disclosure, and on the erasure path committed destructions. Whatever the substrate answers there — a recording-failure, an invalid-request, or an invalid-credential because the operator's registration changed between the writes — the event is owed, the caller hears outcome, and the reconciliation records it under the service identity with the operator named and the compensation flag set (Reconciliation 12).

**The position rides the exported code** (Audit arm 16 and 17; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent tells the caller the call made no disclosure and no destruction; outcome tells the caller one may have been made. Either way, where the intent landed the request is the reconciliation's to close, and a retry meets compensation-pending until it has: an access is abandoned back to Received, and an erasure that had planned a destruction is completed with every planned record unsettled, since the leg cannot know no call was made (Reconciliation 13).

### Action wiring

```
receive_request(subject_ref, right_type, requester, regulatory_reference, actor_ref, credential)
  answers intake result
  refuses invalid-request | invalid-credential | recording-failure(position, request_id)

fulfill_access_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | compensation-pending | wrong-right-type | incomplete-enumeration | section-unavailable | state-unavailable | invalid-credential | invalid-request | recording-failure(position)

fulfill_erasure_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | compensation-pending | wrong-right-type | incomplete-enumeration | section-unavailable | state-unavailable | invalid-credential | invalid-request | recording-failure(position)

disposition_report(request_id)
  answers report
  refuses not-known | state-unavailable
```

Term intake result: the request id and the received instant.

Term fulfillment result: the request id, the [Dispositions], the response disclosure id and the fulfilled event's id.

Term report: the request state, the right type and the received instant, and for a Fulfilled request the [Dispositions], the response disclosure id and the fulfilled instant.

```
Action wiring 1: A validated intake MUST take the request id from the seam.
Action wiring 2: A validated intake MUST record the intake event carrying the request id, the invocation id, the subject reference, the right type, the requester, the regulatory reference AND now as the received instant.
Action wiring 3: A landed intake MUST write the request entry AND answer the intake result.
Action wiring 4: IF no request entry EXISTS for the request id THEN a fulfillment MUST answer not-known.
Action wiring 5: IF the request's state EQUALS Fulfilled THEN a fulfillment MUST answer already-fulfilled.
Action wiring 6: IF the request's state EQUALS Committing THEN a fulfillment MUST answer compensation-pending.
Action wiring 7: A fulfillment MUST NOT check the right type BEFORE checking the request's state.
Action wiring 8: IF the request's state EQUALS Received AND the right type DOES NOT EQUAL access THEN [Fulfill Access Request] MUST answer wrong-right-type.
Action wiring 9: IF the request's state EQUALS Received AND the right type DOES NOT EQUAL erasure THEN [Fulfill Erasure Request] MUST answer wrong-right-type.
Action wiring 10: A refusal under Action wiring 4 through 9 MUST NOT record an event.
Action wiring 11: An admitted fulfillment MUST enumerate the subject's universe through the universe enumeration.
Action wiring 12: IF a registered source fails to enumerate THEN the fulfillment MUST answer incomplete-enumeration.
Action wiring 13: A fulfillment answering incomplete-enumeration MUST NOT record an event.
Action wiring 14: An enumerated fulfillment MUST disposition EVERY enumerated record PER Disposition 1 through 47.
Action wiring 15: An enumerated access MUST read the disclosure read AND Consent's read for the subject.
Action wiring 16: An enumerated access MUST record the access intent carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read AND now as the intended instant.
Action wiring 17: The composition MUST NOT call the disclosure write BEFORE the fulfillment's intent lands.
Action wiring 18: An intended access MUST call the disclosure write with the subject reference, the requester as the recipient, the access scope AND the response authority.
Action wiring 19: IF a refused disclosure write EXISTS for an intended fulfillment AND no possibly destroyed record EXISTS for the fulfillment THEN the fulfillment MUST record an abandonment carrying the request id AND the intent's invocation id.
Action wiring 20: IF no possibly committed act EXISTS for an unsealed fulfillment AND no disclosure fault EXISTS for the fulfillment THEN the fulfillment MUST answer recording-failure carrying intent.
Action wiring 21: IF no possibly committed act EXISTS for an unsealed fulfillment AND a disclosure fault EXISTS for the fulfillment THEN the fulfillment MUST answer invalid-request.
Action wiring 22: A disclosed access MUST record the access fulfilled event carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read, the response disclosure id AND now as the fulfilled instant.
Action wiring 23: An enumerated erasure MUST NOT call a destroying surface BEFORE the erasure intent lands.
Action wiring 24: An enumerated erasure MUST record the erasure intent carrying the request id, the invocation id, the subject reference, the requester, the provisional dispositions, the universe cardinality, the purge plan, the host delete plan AND now as the intended instant.
Action wiring 25: An intended erasure MUST call Defensible Retention's purge PER pair of the purge plan with the retention id, the actor reference AND the credential.
Action wiring 26: An intended erasure MUST call the host delete PER record of the host delete plan with the record reference, the actor reference AND the credential.
Action wiring 27: An intended erasure MUST settle each planned record's disposition from the planned call's answer.
Action wiring 28: An executed erasure MUST call the disclosure write with the subject reference, the requester as the recipient, the erasure scope AND the response authority.
Action wiring 29: IF a possibly committed act EXISTS for an unsealed fulfillment THEN the fulfillment MUST answer recording-failure carrying outcome.
Deleted: Action wiring 30. Action wiring 19 owns it.
Action wiring 31: A disclosed erasure MUST record the erasure fulfilled event carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the response disclosure id AND now as the fulfilled instant.
Deleted: Action wiring 32. Primitive policy 13 owns it.
Action wiring 33: A landed fulfillment MUST write the fulfillment entry AND answer the fulfillment result.
Action wiring 34: IF no request entry EXISTS for the request id THEN [Disposition Report] MUST answer not-known.
Action wiring 35: [Disposition Report] MUST answer the report.
Action wiring 36: [Disposition Report] MUST NOT record an audit event.
Action wiring 37: IF the disclosure read OR Consent's read fails for an enumerated access THEN [Fulfill Access Request] MUST answer incomplete-enumeration.
Action wiring 38: IF the retention read fails for an enumerated erasure THEN [Fulfill Erasure Request] MUST answer incomplete-enumeration.
Action wiring 39: A fulfillment MUST NOT record an abandonment over a disclosure write that answered no answer.
```

Term validated intake: a [Receive Request] call whose inputs cleared Primitive policy.

Term landed intake: a validated intake whose intake event landed.

Term fulfillment: a [Fulfill Access Request] or [Fulfill Erasure Request] call whose inputs cleared Primitive policy.

Term admitted fulfillment: a fulfillment Action wiring 4 through 9 did not refuse.

Term enumerated fulfillment: an admitted fulfillment whose enumeration answered every registered source.

Term enumerated access: an enumerated fulfillment of [Fulfill Access Request].

Term enumerated erasure: an enumerated fulfillment of [Fulfill Erasure Request].

Term universe cardinality: the count of records the enumeration answered.

Term recipients read: the disclosure ids the disclosure read answered for the subject — the Article 15(1)(c) limb.

Term consents read: the consent ids Consent's read answered for the subject — the consent-history limb.

Term access intent: the dsar.access_fulfillment_intended event.

Term intended fulfillment: an intended access or an intended erasure.

Term intended access: an enumerated access whose access intent landed.

Term access scope: dsar:access:designated-record-set: followed by the request id.

Term request scope: an access scope or an erasure scope.

Term response authority: the authority of a response disclosure — regulatory as the authority type and the request's regulatory reference as the authority reference.

Term disclosure fault: invalid-request | unknown-authority-type — the disclosure write's refusals that are deployment faults.

Term refused disclosure write: a disclosure write that answered storage-failure or a disclosure fault — a refusal Selective Disclosure applies nothing under (Selective Disclosure Operation 16).

Term disclosed access: an intended access whose disclosure write answered the response disclosure id.

Term erasure intent: the dsar.erasure_execution_intended event.

Term provisional dispositions: the dispositions Disposition 1 through 19, 39 and 40 resolve before any planned call runs.

Term purge plan: the confirmed retention id and record reference pairs bound for Defensible Retention's purge, in the order the calls are made.

Term host delete plan: the record references bound for the host delete, in the order the calls are made, after the purge plan's.

Term destroying surface: Defensible Retention's purge or the host delete.

Term planned call: a call of a destroying surface the plans name — Defensible Retention's purge for a purge plan pair, the host delete for a host delete plan record.

Term planned record: a record the purge plan or the host delete plan names.

Term intended erasure: an enumerated erasure whose erasure intent landed.

Term executed erasure: an intended erasure whose every planned record carries a settled disposition — from a planned call's answer, or unsettled where the grant admitted no call (Disposition 45).

Term possibly destroyed record: a planned record whose disposition carries erased or unsettled.

Term possibly committed act: a disclosure write that answered a disclosure id or no answer, or a possibly destroyed record.

Term erasure scope: dsar:erasure:outcome: followed by the request id.

Term disclosed erasure: an executed erasure whose disclosure write answered the response disclosure id.

Term landed fulfillment: a disclosed access or a disclosed erasure whose fulfilled event landed.

Term unsealed fulfillment: an intended fulfillment that returns with no landed fulfilled event — refused at its disclosure write, yielded, or owed its fulfilled event.

WHY:
**Two siblings over one core** (Action wiring 11 through 33). Both enumerate, disposition every record, write an intent, bind the response disclosure, and seal last; they differ in their disposition vocabulary and their downstream effect — access determines and discloses, erasure determines and, for erased records, destroys. They stay two actions rather than one parametrized fulfillment because an irreversible destruction and a pure disclosure behind one flag would hide the load-bearing fork a reader must see at the signature; the shared machinery lives once, in these rules and the invariants, so the siblings duplicate no logic.

**Terminality before type, and Committing refused** (Action wiring 4 through 10). Against a Fulfilled request the sibling answers already-fulfilled before it reaches the right type, so wrong-right-type is exercised only by a request not yet fulfilled. A Committing request is refused compensation-pending: a fulfillment of it died after its intent, and re-running it would duplicate a permanent disclosure or re-plan erased records; the caller reads [Disposition Report] for the outcome. A fulfillment still in flight holds the request section, and a second caller hears section-unavailable instead (Concurrency 6). Every one of these is judged on the request's events as they stand under the section (Concurrency 7).

**Completeness is all-or-nothing before the intent** (Action wiring 11 through 13, 37 and 38): a source that fails to enumerate refuses the fulfillment with nothing written, because a partial universe fulfilled as if whole is the silent omission the composition exists to forbid. The same answer covers the three whole-subject reads a fulfillment makes before its intent — the recipients and the consent history an access seals, and the retention read an erasure confirms every pairing against — since a set sealed without one of them is as partial as a universe missing a source. An enumeration that finds no records is a valid fulfillment with an empty set — the meaningful *we hold no records about you* — distinct from [Incomplete Enumeration].

**The intent carries the whole disposition set** (Action wiring 16 and 24). If the fulfilled event fails or the process dies between the writes, the set exists nowhere else, and re-enumerating is no lawful substitute: a disposition set is a point-in-time verdict, and a compensating event must say what was decided then. On the erasure path the intent carries the plan **and, separately, the provisional disposition for every record** — the plan names only what an irreversible act was about to touch, so a compensation rebuilt from it alone would omit exactly the retained and anomalous records no downstream event attests, reintroducing the silent omission through the recovery path. The intent is also the authentication (Invariant 8), the recovery marker, and on the erasure path the **nesting link**: this composition and Defensible Retention share one trail, so without the plan a reader could not tell a purge occasioned by an authorized rights fulfillment from a direct call that bypassed the rights process (Check 6.3). Authentication is not inherited across that boundary: the substrate's purge is independently callable and re-verifies the same credential at its own intent, which is the direct-call path's whole defence; the plan records provenance, not authority.

**The recipients and consent limbs are sealed as ids, not a digest** (Action wiring 15, 16 and 22; 2026-08-26-m). A digest of a read over an append-only store diverges by construction — every later disclosure, the response disclosure itself included, changes it — so a digest could never be recomputed. The ids read are immutable and each resolves, so the sealed limb is performable: a host that drops a recipient from the export leaves an id the export does not answer.

**A fulfillment that does not seal says which side of the irreversible it stopped on** (Action wiring 19 through 21, 29 and 39; 2026-08-26-p, 2026-08-29-c). Three things can stop one after its intent: its disclosure write is refused, its grant of the request section runs out (Concurrency 18), or its fulfilled event is owed. What the caller hears turns on one question — is there anything that may be permanent? A disclosure that was recorded, a disclosure write that never answered and may yet land, a record erased, a record whose planned call did not settle it: any one is a possibly committed act, the answer is outcome, the intent stays open and the reconciliation closes it. Where there is none, nothing irreversible happened: the answer is intent, or invalid-request where the disclosure write's own refusal was the deployment's fault. A disclosure write Selective Disclosure refused applied nothing, so where nothing may have been destroyed either the invocation closes its own intent with an abandonment and the request returns to Received. It never abandons over a write that did not answer: an abandonment beside a disclosure that then lands would leave a permanent disclosure bound to nothing, and a second one written by the retry. **The scope carries the request id** (Action wiring 18 and 28), and that is load-bearing: it is the only join the reconciliation has from a disclosure to a fulfilled event that never landed.

**The access payload is the host's** (Action wiring 22): the composition records *what was decided and disclosed*; assembling, redacting and transmitting the export bytes for the included records is the host's obligation, signalled by the included dispositions (Non-goal 7).

### Wiring decision

```
Wiring decision 1: A fulfillment MUST disposition EVERY record of the subject's enumerated universe.
Wiring decision 2: The composition MUST bind the dispositions, the response disclosure AND the fulfilled event as one fulfillment.
Wiring decision 3: The composition MUST NOT record a fulfilled event BEFORE the response disclosure lands.
Wiring decision 4: The composition MUST read an erasure's preservation dispositions off Defensible Retention's purge.
Wiring decision 5: The composition MUST NOT evaluate a hold.
```

WHY:
**Half 1 — every in-scope record carries exactly one disposition, and the fulfillment binds the complete set into one accountable act.**

*Principle.* A rights response an auditor can trust needs two facts inseparable: that *every* record in the subject's universe was accounted for, none silently dropped, and that the account is itself immutable, attributed and tamper-evident.

*Likely objection.* Why not let each constituent answer for its own records and union the answers?

*Mechanism.* No constituent enumerates the *universe*, and a union of per-constituent answers has no completeness guarantee — a record in a host store no constituent governs is simply absent, and absence is invisible to a reader who sees only what *was* returned. The composition computes the universe once over the declared registry, dispositions every record (Wiring decision 1), and binds the set, the response disclosure and the sealed event as one fulfillment (Wiring decision 2), sealed last (Wiring decision 3) so no event exists without its record; the one reachable gap in the other direction is surfaced and compensated rather than claimed away (Invariant 1).

*Result.* An auditor reads one fulfillment and sees a verdict for every record the declared universe contains — no-silent-omission — non-repudiable and tamper-evident, which no constituent provides alone.

**Half 2 — the erasure gate is Defensible Retention's hold-blocks-purge decision, wrapped, not re-derived.**

*Principle.* *Delete this* and *you may not delete this* cannot both hold; the resolution must be structural and records-checkable, not a runtime check a well-meaning operator can talk past.

*Likely objection.* Doesn't a rights-fulfillment system need its own hold and retention logic?

*Mechanism.* No — re-deriving hold checking would duplicate exactly the gate Defensible Retention already owns and proves (its Invariant 1), and its purge is irreversible and self-audits each destruction. The composition maps the gate's answers onto dispositions (Wiring decision 4 and 5; Disposition 20 through 46), inheriting its structural guarantee and its retention exemption for free, and adds the one concept the substrate does not carry — the Article 17(1)(b) question of whether another lawful basis means erasure was never due, read-only and ahead of any purge (Disposition 7 through 12).

*Result.* Every preservation disposition traces to a records-checkable Defensible Retention outcome, and the composition stays a thin conflict-resolution-and-accounting layer over a proven substrate rather than a re-implementation of it.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a young intent.
Reconciliation 4: The reconciliation MUST NOT examine an aged event.
Reconciliation 5: The reconciliation MUST attest EVERY audit write the reconciliation makes under the service identity.
Deleted: Reconciliation 6. Check 1.4 owns it.
Deleted: Reconciliation 7. Reconciliation 22 owns it.
Reconciliation 8: The reconciliation MUST pair a request-scoped disclosure to the open intent carrying the disclosure's request id.
Reconciliation 9: The reconciliation MUST NOT close an open erasure intent BEFORE taking the retention reading of EVERY purge plan pair.
Reconciliation 10: The reconciliation MUST NOT record a fulfilled event BEFORE the reconciliation's recovery intent lands.
Reconciliation 11: A recovery intent MUST carry the request id, the open intent's invocation id AND the case.
Reconciliation 12: IF a request-scoped disclosure carries the open intent's request id THEN the reconciliation MUST record the fulfilled event the intent's fulfillment owed, from the intent's own fields, carrying the compensation flag, the operator AND the intent's invocation id.
Reconciliation 13: IF no request-scoped disclosure carries the open intent's request id AND a planned record EXISTS for the intent THEN the reconciliation MUST call the disclosure write PER Action wiring 28.
Reconciliation 14: A compensating fulfilled event MUST carry anomaly carrying unsettled AND the intent's reason for EVERY planned record outside the destroyed planned records.
Reconciliation 15: IF no request-scoped disclosure carries the open intent's request id AND no planned record EXISTS for the intent THEN the reconciliation MUST record an abandonment carrying the request id AND the intent's invocation id.
Reconciliation 16: A compensating fulfilled event MUST carry the intent's disposition for EVERY record outside the plans.
Reconciliation 17: The reconciliation MUST NOT close an open intent BEFORE taking the request section over the intent's request id.
Reconciliation 18: The reconciliation MUST write the fulfillment entry ONLY AFTER the compensating fulfilled event lands.
Deleted: Reconciliation 19. Defensible Retention Reconciliation 11 owns it.
Deleted: Reconciliation 20. Defensible Retention Action wiring 70 owns it.
Deleted: Reconciliation 21. Defensible Retention Reconciliation 11 owns it.
Reconciliation 22: The reconciliation MUST alert on an overdue intent.
Reconciliation 23: The reconciliation MUST read the request's events AND the disclosure read of the intent's subject reference again under the request section.
Reconciliation 24: IF a purge plan pair's retention reading EQUALS purged THEN a compensating fulfilled event MUST carry the pair's record erased carrying the retention id, the purge instant AND the intent's reason.
Reconciliation 25: The reconciliation MUST write the index entry of EVERY intake event AND EVERY fulfilled event carrying none.
Reconciliation 26: IF Lease's try_take answers held OR no answer THEN the reconciliation MUST leave the open intent to the next run.
Reconciliation 27: IF a read a leg makes fails THEN the reconciliation MUST leave the open intent to the next run.
Reconciliation 28: IF the request section admits no call a leg owes OR a call a leg issues refuses THEN the reconciliation MUST leave the leg's remaining work to the next run.
Reconciliation 29: The reconciliation MUST NOT call the disclosure write BEFORE the reconciliation's recovery intent lands.
Reconciliation 30: The reconciliation MUST take the readings of Reconciliation 9 under the request section.
Reconciliation 31: A compensating fulfilled event MUST carry the paired disclosure's id as the response disclosure id AND the leg's now as the fulfilled instant.
Reconciliation 32: A compensating access fulfilled event MUST carry the recipients read AND the consents read the access intent carries.
Reconciliation 33: The reconciliation MUST NOT take the request section over a request id BEFORE alerting on EVERY overdue intent of the request id.
Reconciliation 34: IF the trail read a run enumerates the open intents from fails THEN the reconciliation MUST alert.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a compensated, completed or abandoned fulfillment, or an alert — an auditor awaits within the compensation window.

Term leg: the reconciliation's handling of one open intent, under one grant of the request section.

Term young intent: an open intent whose intended instant stands within the fulfillment completion bound, taken with the clock offset allowance, of the injected now.

Term overdue intent: an open intent whose intended instant stands older than the compensation window, taken with the clock offset allowance, of the injected now — an intent the window did not close.

Term request-scoped disclosure: a Selective Disclosure record whose scope is a request scope — selected in the composition's own code, byte-exact on the scope, from the disclosure read of the subject reference, since Selective Disclosure offers no filter by scope.

Term recovery intent: the dsar.recovery_intended event — the reconciliation's intent record, naming the request, the intent it resolves and the case. An abandonment takes none.

Term case: compensate | complete | abandon — the closure Reconciliation 12, 13 or 15 makes.

Term compensating fulfilled event: a fulfilled event the reconciliation records, carrying the compensation flag.

Term destruction record: Defensible Retention's record_purged outcome, a recovered one included.

Term destroyed planned record: a purge plan pair whose retention reading EQUALS purged. A host delete plan record is never one: no declared surface says a host-managed record is gone, so a leg seals it unsettled.

Term binding orphan: a request-scoped disclosure that no fulfilled event's response disclosure id names, written under an intent that is no aged event — this composition's own orphan.

WHY:
**Why the reconciliation is mandatory.** A fulfillment can stop after its intent by a *return* — the action answers and the caller knows — and by a *crash*, where nothing returns. Only the first surfaces itself; the second is what Invariant 1's second safety half is about, and this leg is the whole of what makes it true. It is **Reconciliation, not Housekeeping**: an auditor awaits its output within the compensation window.

**Bounded at both ends, and exclusive** (Reconciliation 3 through 5, 17, 23 and 26; the sections titled *A reconciliation is bounded at both ends*, *A compensator is exclusive* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below: a Committing request younger than the bound may belong to an invocation about to seal, and the edge keeps the leg off work that young; the intent's instant and the leg's now are two readings, so the edge carries the allowance. Above: past the audit horizon an event's payload may be destroyed, and the substrate destroys events one at a time in no promised order, so a fulfilled event can be gone while the intent it closed is still readable. An aged event is therefore never an open intent and never examined — its request reads Fulfilled where the fulfillment entry outlived the event, and a response disclosure whose fulfilled event aged out is lawful destruction, never an orphan. Neither edge is what the single outcome rests on. That is the request section: the invocation writes only while its own grant admits the call, the leg closes nothing before it holds the same section and has read the request's events and the disclosure store again under it, and two runs of the leg — restart and cadence, two nodes — meet the same section and the second reads what the first wrote. An invocation still holding the section is left to the next run. Every audit write is attested under the service identity, and every closure that seals or discloses is preceded by a recovery intent, so the trail shows the act was occasioned by the leg and not by a direct call.

**Pairing is exact by construction** (Reconciliation 8): a fulfillment reads the request's state under the section and is refused while an intent stands open, so a request carries at most one open intent; an abandonment is recorded only where no disclosure was written; and a disclosure's scope carries the request id. So a request-scoped disclosure with no fulfilled event behind it pairs to the one open intent for its request, and an abandoned intent beside an open one is closed history.

**Each open intent is closed by what could have committed, and sealed from the stores** (Reconciliation 9, 12 through 16, 24 and 30). A disclosure exists → compensate, sealing the intent's dispositions. No disclosure, and the intent planned a destruction → complete, writing the disclosure and then, under the service identity, the event. No disclosure and nothing planned — an access, or an erasure with empty plans → abandon, and the request returns to Received. An earlier draft compensated every unmatched intent, which for the third case wrote a sealed event with no disclosure behind it — the reverse orphan Invariant 1's safety half forbids, produced by the recovery path itself. **An intent that planned a destruction is never abandoned by the leg**, even where no planned record reads destroyed: a purge that answered storage-failure leaves its retention retained over a record the storage layer may already have destroyed (Defensible Retention Atomic writes 9), which no store this composition reads can show, and an abandonment there would return the request to Received with a record gone and no disposition anywhere — the state Committing exists to prevent. So the leg seals what it can read and calls the rest unsettled, and the invocation, which heard its own calls' answers, is the only writer that abandons over a plan (Action wiring 19). **What the dead invocation knew and did not record, the leg does not remember.** The answers its planned calls gave died with it; what survives is the stores' own state, so the leg seals exactly that: a planned retention the retention read answers purged is erased, on the store's own instant; every other planned record — a host-managed one always, since the host's attestation died with the invocation and nothing declared says the record is gone — is unsettled, an anomaly, because a gate that refused it and a call that never reached it leave the same stores behind. The dispositions the intent settled before any planned call are sealed as the intent carries them, which is why the intent carries them (Reconciliation 16). The leg's readings are final for the invocation it repairs: that invocation's calls were issued inside its grant, the leg holds the section after it, and nothing the dead invocation started can still land.

**The substrate's own orphan is the substrate's** (the tombstones of Reconciliation 19 through 21). A record Defensible Retention destroyed whose destruction record is still owed is recovered, and alerted on, by Defensible Retention's own reconciliation (Defensible Retention Reconciliation 11, Defensible Retention Action wiring 70). This composition inherits that guarantee and does not police it a second time (Composes 6): an erased disposition whose destruction record is owed names the retention, and the record arrives under the substrate's own window.

**An intent the window did not close is alerted on** (Reconciliation 22): a leg that keeps leaving its work to the next run is indistinguishable, from the records, from an orphan nobody is working on. The alert rests on the run's enumeration and comes ahead of the take (Reconciliation 33), so a held section or a leg's failed read delays the closing and never the alert; and a run that cannot enumerate at all alerts on that (Reconciliation 34), since an intent it cannot see is one it cannot escalate.

### Disposition

```
Disposition 1: EVERY enumerated record MUST carry EXACTLY ONE disposition.
Disposition 2: A disposition MUST carry the record reference, the source, the verdict AND the reason.
Disposition 3: IF a record's determination reading EQUALS third-party-confidentiality THEN the record MUST carry withheld carrying third-party-confidentiality.
Disposition 4: IF a record's determination reading EQUALS legal-exemption THEN the record MUST carry withheld carrying legal-exemption.
Disposition 5: IF a record's determination reading EQUALS failed THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 6: IF a record's determination reading EQUALS no-bar THEN the record MUST carry included.
Disposition 7: IF a record's basis reading EQUALS ground THEN the record MUST carry retained carrying other-lawful-basis AND the ground.
Disposition 8: The composition MUST read a declared non-consent ground as in force as the registry declares.
Disposition 9: IF a record's declared basis names consent THEN the composition MUST call Consent's check with the subject reference AND the purpose.
Disposition 10: IF a record's basis reading EQUALS granted THEN the record MUST carry retained carrying other-lawful-basis AND the purpose.
Disposition 11: IF a record's basis reading EQUALS not-known THEN the record MUST carry anomaly carrying consent-basis-not-known.
Disposition 12: IF a record's basis reading EQUALS withdrawn THEN the record's reason MUST carry the check's answer AND the purpose.
Disposition 13: The composition MUST take the retention reading of EVERY erasure-due record.
Disposition 14: IF an erasure-due record's retention reading EQUALS mis-paired THEN the record MUST carry anomaly carrying mis-paired.
Disposition 15: IF an erasure-due record's retention reading EQUALS absent THEN the record MUST carry anomaly carrying unknown-retention.
Disposition 16: The composition MUST NOT plan a settled record.
Disposition 17: The composition MUST add an erasure-due record whose retention reading EQUALS retained to the purge plan.
Disposition 18: The composition MUST add an erasure-due host-managed record whose retention reading EQUALS clear to the host delete plan.
Disposition 19: A planned record's provisional disposition MUST carry planned.
Disposition 20: IF a planned record's purge reading EQUALS destroyed THEN the record MUST carry erased carrying the retention id.
Disposition 21: IF a planned record's purge reading EQUALS held THEN the record MUST carry retained carrying legal-hold, the hold ids AND the count.
Disposition 22: IF a planned record's purge reading EQUALS obliged THEN the record MUST carry retained carrying retention-obligation AND the retention id.
Deleted: Disposition 23. Disposition 22 owns it.
Deleted: Disposition 24. Disposition 42 owns it.
Deleted: Disposition 25. Disposition 42 owns it.
Deleted: Disposition 26. Disposition 20 owns it.
Deleted: Disposition 27. Disposition 41 owns it.
Deleted: Disposition 28. Disposition 43 owns it.
Deleted: Disposition 29. Disposition 42 owns it.
Deleted: Disposition 30. Disposition 43 owns it.
Deleted: Disposition 31. Disposition 44 owns it.
Disposition 32: IF the host delete answers deleted THEN the record MUST carry erased carrying the attestation reference.
Disposition 33: IF the host delete answers retained THEN the record MUST carry retained carrying other-lawful-basis AND the host's basis.
Disposition 34: IF the host delete answers not-known THEN the record MUST carry anomaly carrying host-record-not-found.
Disposition 35: IF the host delete answers delete-failed OR invalid-credential THEN the record MUST carry anomaly carrying unsettled.
Disposition 36: IF the host delete answers outside the host delete's contract THEN the record MUST carry anomaly carrying unsettled.
Deleted: Disposition 37. Disposition 47 owns it.
Disposition 38: The composition MUST read a fulfillment carrying an anomaly as Fulfilled.
Disposition 39: IF an erasure-due record's retention reading EQUALS purged THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 40: IF a record's basis reading EQUALS unread THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 41: IF a purge's first answer IS IN the retry answers AND the plan floor admits a further planned call THEN the composition MUST re-invoke the purge once.
Disposition 42: IF a planned record's purge reading EQUALS unsettled THEN the record MUST carry anomaly carrying unsettled.
Disposition 43: IF a planned record's purge reading EQUALS gone THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 44: IF a planned record's purge reading EQUALS unknown THEN the record MUST carry anomaly carrying unknown-retention.
Disposition 45: IF the plan floor admits no further planned call THEN EVERY planned record no planned call settled MUST carry anomaly carrying unsettled.
Disposition 46: A disposition a planned call's answer settles MUST carry the answer in the reason.
Disposition 47: The deployment MUST alert on a fulfilled event carrying an anomaly.
```

Term disposition: a record's verdict — [Included] or [Withheld] for access; [Erased], [Retained] or [Anomaly] for erasure, [Anomaly] for access too.

Term verdict: included | withheld | erased | retained | anomaly.

Term withdrawn answer: revoked | expired — Article 17(1)(b)'s consent withdrawn, or lapsed.

Term determination reading: failed | third-party-confidentiality | legal-exemption | no-bar — what the host determinations say of a record of an access, exactly one of the four and the first that holds in this order: failed where the surface fails for the record or answers a source text over the text cap; third-party-confidentiality where the determinations name that bar, alone or beside a legal exemption; legal-exemption where the determinations name a legal exemption and no third-party confidentiality; no-bar everywhere else.

Term basis reading: unread | ground | granted | not-known | withdrawn | none — what a record's declared basis and Consent's check say of a record of an erasure, exactly one of the six: unread where the declared basis fails or carries a source text over the text cap, or names consent and Consent's check answers no answer; ground where the declared basis names a non-consent ground; granted, not-known or withdrawn where the declared basis names consent and Consent's check answers granted, not-known or a withdrawn answer; none where the record declares no basis.

Term erasure-due record: an enumerated record of an erasure whose basis reading EQUALS withdrawn or none — a record no basis preserves and no failed read holds back.

Term retention reading: unread | clear | absent | mis-paired | purged | retained — what the retention read says of a registered record and the record's route, exactly one of the six and the first that holds in this order: unread where the read gave no answer; for a host-managed record, mis-paired where the read answers a retention over the record reference, and clear where the read answers none; for a record whose route carries a retention id, absent where the read answers no retention carrying the id; mis-paired where the read pairs the id with another record reference; purged where the record stands as a destroyed record in Defensible Retention's own sense — the read answers a purged retention over the record reference, the named retention or a sibling; and retained everywhere else.

Term settled record: a record Disposition 7, 10, 11, 14, 15, 39 or 40 dispositions before any planned call — every record of an erasure that Disposition 17 and Disposition 18 add to no plan.

Term planned: the provisional marker of a record in the purge plan or the host delete plan, settled by the planned call's answer.

Term retry answers: section-unavailable | hold-check-unavailable | storage-failure | recording-failure carrying intent | recording-failure carrying gate — the purge answers under which the call reports no destruction and a later call can answer otherwise. The intent and gate positions are Defensible Retention's own, of its purge's records, and not this composition's position.

Term unsettling answers: the retry answers | invalid-credential | invalid-request | no answer — the purge answers that leave a record's fate unsaid.

Term purge's first answer: the answer of the one call Action wiring 25 makes for a purge plan pair.

Term purge's last answer: the re-invoked purge's answer where the composition re-invoked the purge, and the purge's first answer everywhere else.

Term purge reading: destroyed | gone | unsettled | held | obliged | unknown — what the answers of a purge plan pair's calls say of the pair's record, exactly one of the six and the first that holds in this order: destroyed where the last answer EQUALS ok or recording-failure carrying outcome; gone where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS purged; unsettled where the first answer or the last EQUALS storage-failure or no answer, where the last answer is any other unsettling answer, or where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS unread; held where the last answer EQUALS under-legal-hold; obliged where the last answer EQUALS not-eligible or under-active-retention; unknown everywhere else — a not-known the store does not bear out. Every answer of Defensible Retention's purge falls under one of the six, so Disposition 20 through 22 and 42 through 44 settle a called record once.

Term outside the host delete's contract: said of a host delete that answers no answer, an answer that is no arm of the host delete's contract, or an arm carrying a source text over the text cap.

WHY:
**Access fails closed** (Disposition 3 through 6; 2026-08-26-h). A record is included only when the host's determinations answer no bar; a determination surface that fails yields an anomaly, never an included record released on an error, where the prose's *otherwise included* failed open on exactly the path the erasure ladder fails closed.

**The erasure precedence is in the readings, not in the order of the rules** (Disposition 7 through 18, 39 and 40). A record's basis reading is one value, so exactly one basis rule fires; only a record whose basis is withdrawn or absent is erasure-due, and only an erasure-due record is tested against the store and planned. So the verdict is deterministic, the recorded reason is the strongest applicable claim, and a record another basis preserves is never read as erased because its retention happens to be gone. The access ladder is one reading the same way (Disposition 3 through 6): a record under both bars is withheld for third-party confidentiality, and a surface that fails is failed whatever else it said. **Other lawful basis comes first and is read-only**, because a purge is irreversible and a record another basis preserves must never be probed by destroying it. A declared non-consent ground is read as in force as the registry declares it — the composition has no oracle for it, and whether it truly justifies retention is the host's to clear (Disposition 8; External check 2; 2026-08-29-k). A consent basis goes to the Consent oracle, and every answer lands: granted preserves; revoked or expired — the Article 17(1)(b) *consent withdrawn* — falls through to the gate **carrying the check's answer and the purpose**, so an erasure that rested on a withdrawn consent leaves a records-alone trace of the determination that let it proceed (Disposition 12; 2026-08-26-n); not-known is a registry and Consent disagreement, never silently defaulted either way; and a basis or an oracle that cannot be read is an anomaly, never a record erased on an error. The reason names the purpose and not a consent id, because the oracle's check answers a verdict and no id; the answer recorded is the disposition's basis, and a withdrawal or a grant after it does not reach back (Concurrency 2). The precedence is a recording convention, not a legal ranking: a record under both a hold and another basis is retained for the other basis, and the hold stays observable in the substrate's own stores.

**The pairing is confirmed in the store, for every retention** (Disposition 13 through 17 and 39; 2026-08-26-r, 2026-08-29-e). A registry that names the wrong retention id for a record would have the gate destroy one record while this composition recorded another as erased. The retention read answers every retention with the record it covers, so a mis-pairing is caught before any plan is written, whether or not the retention has elapsed — where an earlier revision confirmed against the purge-eligible listing, which names only what is already destroyable, and planned the rest on the registry's word. A retention the store does not know is an anomaly, and so is a record sent to the host delete that the store shows under a retention: the gate is the only way such a record is destroyed (Invariant 3.2). A retention the store answers purged covers a record already destroyed — by another request, or by the retention schedule — and the record is erased on the store's own instant, with nothing left to plan.

**Every gate answer lands, and each lands by what the pair's answers say together about the record** (Disposition 20 through 22 and 41 through 46; Term purge reading; 2026-08-29-d). *Destroyed*: ok, and recording-failure carrying outcome, where the record is gone and the substrate's destruction record is owed to its own reconciliation. *Preserved by an obligation*: under-legal-hold, with the hold ids and their true count; not-eligible and under-active-retention, both the Article 17(3)(b) ground — the named retention still running, or a sibling over the same record — with the answer kept in the reason so a reader knows which. *Gone before the call*: not-known, which the gate answers for a retention over a record already destroyed and for a retention it cannot find; the retention read says which, and only a record the store answers destroyed is recorded erased. The substrate tells a caller to read a not-known on a re-invoked purge as a committed destruction (Defensible Retention Action wiring 73); this composition asks the store instead, which says so itself wherever it is so, and answers otherwise for a live retention the gate's own index has lost. *Unsaid*: every other answer. Five of them a later call can answer differently — another act holds the record's own section, the hold store could not be read, the storage layer did not confirm, the gate's own intent or its gate record did not land — so the purge is called once more, which the substrate's contract makes destruction-safe and, for storage-failure, obliges (Defensible Retention Action wiring 82). If the second answer is still unsaid, or the answer was the caller's credential or the call's own shape, or no answer came, the record is unsettled: an anomaly that names the answer. **A storage-failure does not say the record survived, and no later answer takes that back** (Defensible Retention Atomic writes 9): the retention stands retained and the record may be gone, which the gate cannot see. So a pair that ever answered storage-failure, or never answered, is unsettled unless a later answer or the store says the record is destroyed — a hold placed between the two calls makes the second call answer under-legal-hold over a record that may no longer exist, and sealing that as retained would lose the one thing the first answer said. An unsettled record is counted as possibly destroyed wherever the composition asks whether anything irreversible happened. The host delete's arms land the same way.

**A plan the grant cannot finish is finished as unsettled** (Disposition 45; Concurrency 13). A planned call is made only while the request section's grant has room for the call and for the bind after it. Where it does not, the records not yet reached are unsettled, and the fulfillment still discloses and seals inside its grant — a complete set with honest anomalies, rather than a destruction made on a grant another writer may already hold.

**The anomaly is admitted, and a fulfillment carrying one is Fulfilled** (Disposition 38 and 47; 2026-08-26-g, 2026-08-29-h). An anomaly is the honest verdict where a record's fate or basis could not be settled — never silently erased or retained. It is a member of the vocabulary, sealed with its reason and alerted on, and the request is Fulfilled all the same: fulfillment is a point-in-time account of the universe as it stood (Snapshot 1), and the remedy for the record is the deployment's and a fresh request, not a request held open indefinitely over a record the substrate or the host must settle first.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent. Each invariant's *Rests on* is its capability-provenance record (the section titled *Capability provenance* in `pressure-testing.md`).

- **Invariant 1 — Binding bijection.**
  ```
  Invariant 1.1: A fulfilled event MUST NOT exist without the fulfillment's response disclosure AND complete dispositions.
  Invariant 1.2: EVERY Fulfilled request MUST carry EXACTLY ONE fulfilled event.
  Invariant 1.3: EVERY fulfilled event MUST name EXACTLY ONE Fulfilled request.
  Invariant 1.4: EVERY binding orphan MUST carry an open intent under the orphan's request id.
  Invariant 1.5: EVERY intent outside the aged events MUST carry EXACTLY ONE closing record at quiescence.
  Invariant 1.6: EVERY fulfilled event landed through compensation MUST carry the compensation flag.
  ```
  WHY: the binding is a Fulfilled request's complete [Dispositions], its response disclosure and its fulfilled event. **The commit is not atomic across all three**: the event is appended through a substrate that declares an appended event cannot be withdrawn and offers no synchronous rollback, so no transaction spans the disclosure and the event. The honest claim splits, and the write order makes the split favourable (Wiring decision 3). **Safety, by construction** (Invariant 1.1): the event is the last write, so an auditor may read any fulfilled event as a completed fulfillment without qualification — the direction the regulator's question runs. **Safety, one event** (Invariant 1.2 and 1.3): a request is sealed once. The invocation writes its event only while its grant of the request section admits the write and never twice; the reconciliation writes one only under the same section, after reading the request's events again; so a fulfilled event that never answered and the compensation written for it cannot both stand. **Safety, no orphan without its marker** (Invariant 1.4): the reverse partial — a disclosure whose event never landed — is reachable and durable, and never silent: the intent that preceded it is still open, the request reads Committing to every caller and every report, and an abandonment is never written beside a disclosure. **Liveness** (Invariant 1.5 and 1.6): every intent is closed once — sealed by its own invocation, compensated, completed or abandoned by the reconciliation — the closure floor is strictly inside the declared window, an intent the window did not close is alerted on (Reconciliation 22), and a recovered fulfillment is distinguishable from a clean one. *At quiescence* is not doing the window's work here: the window is Capability requirement 39's inequality, and the one intent the claim does not reach is one the audit horizon reached unclosed, which the reconciliation no longer examines (Reconciliation 4). **On the erasure path the purges precede the binding and are irreversible**, so erased records without a binding are reachable — not a counterexample to the bijection, which is a claim about the binding, but the open intent the reconciliation completes, exactly as Defensible Retention's own invariants hold modulo its substrate's partial-attestation contract. *Rests on* Selective Disclosure Invariant 1 and 6 (record immutability, append-only durability) and its Operation 16 (a refused record applies nothing); Audit Trail Invariant 1 and its append-only contract — the declared source of the split itself — reached through the substrate; the write order (Action wiring 22 and 31); the request section (Concurrency 1 through 22) and the Lease host behind it (Capability requirement 27 and 36); the request-carrying scope, the reconciliation's join key (Action wiring 18 and 28), and the one surface that writes it (Capability requirement 41 and 42); the disposition set in both intents (Action wiring 16 and 24), without which the liveness half names a repair with no material; the service identity and the alerting surface (Capability requirement 12, 13 and 37); and the declared window (Capability requirement 16 through 18 and 39).
- **Invariant 2 — No-silent-omission.**
  ```
  Invariant 2.1: EVERY Fulfilled request's dispositions MUST carry EXACTLY ONE disposition PER record of the enumerated universe.
  Invariant 2.2: A fulfillment whose enumeration failed MUST NOT produce a fulfilled event.
  ```
  WHY: the totality claim the formal model checks beside the binding. A partial universe is never recorded as if complete. *Rests on* the universe enumeration bounded by the record source registry (Composes 10, Capability requirement 1), and the all-or-nothing guard (Action wiring 12 and 13). The guarantee holds over the *declared* universe; whether the registry names every store holding the subject's data is externally clearable (External check 1) — stated rather than overclaimed.
- **Invariant 3 — Erasure validity.**
  ```
  Invariant 3.1: A disposition MUST carry erased ONLY IF destruction evidence EXISTS for the disposition's record.
  Invariant 3.2: The composition MUST NOT call the host delete for a record whose retention reading DOES NOT EQUAL clear.
  ```
  Term destruction evidence: for a record whose route carries a retention id, a purge of the record's retention that answered ok or recording-failure carrying outcome, or a retention reading that EQUALS purged; for a host-managed record, a host delete that answered deleted.

  WHY: the composition re-derives no hold checking — it calls the host delete only for a record the retention read shows under no retention, so a record the store shows under a retention when the plan is made is destroyed only by asking the gate (Invariant 3.2), and it records erased only on the gate's own word or the store's (Invariant 3.1). So every gated erasure is a destruction Defensible Retention admitted, and under the required strict mode (Capability requirement 10) that is a destruction no active hold and no unelapsed retention covered at the gate — the hold guarantee, which is Defensible Retention Invariant 1 and Invariant 9 inherited under Composes 6 and not a second claim made here. The earlier form of this invariant said a held record is never dispositioned erased, which a record destroyed last year and held this year makes false while nothing wrong has happened: a hold placed after a destruction is a post-destruction hold in the substrate's own terms, and the erased disposition is the truth. The hold guarantee reaches Defensible Retention-managed records only, because the structural guarantee *is* the substrate's gate; a host-managed record bypasses it (Host-managed records 1), and what Invariant 3.1 says of one is only that its erased verdict rests on the host's own word. *Rests on* Defensible Retention's declared purge and its Invariant 1 (hold-blocks-purge), whose under-legal-hold, not-eligible and under-active-retention refusals are the source of the three preservation dispositions (Disposition 21 and 22; 2026-08-29-d), and Retention Window's read on the instance the substrate carries (Composes 14).
- **Invariant 4 — Disposition groundedness.**
  ```
  Invariant 4.1: EVERY disposition's reason MUST name the authority the disposition rests on.
  ```
  WHY: no verdict is a bare claim. A gated erased names its retention, and the purge's answer or the store's purge instant; its destruction record is the substrate's, found by the retention id. A retained for a hold names the hold ids the strict-mode refusal answered, which the gate record carries too; a retained for a retention obligation names the retention and the answer — the substrate writes no record for not-eligible or under-active-retention, both refused before its intent, so the authority is the Retention Window record itself, read through the substrate; a retained for another basis names the purpose and the check's answer, or the declared ground; an erased that fell through a withdrawn consent names that purpose and answer too (Disposition 12); an access verdict names the host's determination; a host-managed verdict names the host's attestation or basis; an anomaly names what could not be read or the answer that left the record unsettled. *Rests on* Defensible Retention's purge, Retention Window's read, Consent's check and read, and the registry's declared surfaces. The host-managed and host-determined branches are host-attested rather than records-checkable, so their legitimacy is externally clearable (External check 2).
- **Invariant 5 — Every response disclosure recorded.**
  ```
  Invariant 5.1: EVERY Fulfilled request MUST carry EXACTLY ONE response disclosure.
  ```
  WHY: the release of the subject's data, or of the erasure outcome, back to the requester is itself an accountable, immutable disclosure. *Rests on* the disclosure write and Selective Disclosure Invariant 1 and 6, and Invariant 1's binding.
- **Invariant 6 — Fulfillment terminality.**
  ```
  Invariant 6.1: A Fulfilled request MUST NOT leave Fulfilled.
  Invariant 6.2: A fulfillment of a Fulfilled request MUST NOT record an event.
  ```
  WHY: a request moves Received → Committing → Fulfilled, Committing entered by an intent and left by the fulfilled event or by an abandonment back to Received; Fulfilled is terminal, so no second disposition set, no second disclosure, no second event. *Rests on* the request's state read from the trail under the request section (Composition state 19, Concurrency 7), the write-once fulfillment index (Composition state 9 and 11) and the already-fulfilled guard (Action wiring 5); the request-lifecycle analog of Consent's terminal absorption.
- **Invariant 7 — Consent non-mutation.**
  ```
  Invariant 7.1: The composition MUST NOT call a Consent write.
  Invariant 7.2: The composition MUST call Consent ONLY through check AND read.
  ```
  WHY: this is what keeps Consent a freestanding authority oracle rather than state this composition co-owns; were the composition to mutate consent, it and Propagate Consent Revocation Downstream would both own consent state — the ambiguity the read-only discipline forecloses, and the reason the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) cut names Consent a decision-input oracle. Check 7.1 and 7.2 read it from the records, and External check 6 from the code (2026-08-26-l). *Rests on* Consent's declared check and read, neither of which writes (Consent Operation 36, Consent Operation 49).
- **Invariant 8 — Authentication precedes destruction, disclosure and commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call the disclosure write BEFORE Audit Trail validates the caller's credential at the fulfillment's intent.
  Invariant 8.2: The composition MUST NOT call a destroying surface BEFORE Audit Trail validates the caller's credential at the erasure intent.
  Deleted: Invariant 9. Composes 6 owns it.
  ```
  WHY: three acts are irreversible and all three are covered — the permanent response disclosure, the purges the erasure occasions through Defensible Retention, and the host deletes, which sit outside the substrate entirely and are the act most easily left uncovered. The erasure's resolution is read-only in its entirety precisely so the whole universe is resolved before any of it is executed. **Authentication is not inherited across the substrate boundary**, and this invariant does not claim it is: each layer authenticates for itself, and what the plan adds is provenance. **What it does not establish**: a validation shows matching material was presented at that instant — not that the presenter *is* the actor, not a channel binding, not replay resistance; nothing about the operator's authorization (Non-goal 2), and nothing whatever about the **requester's** identity (Non-goal 1) — an authenticated operator fulfilling a forged request is exactly as harmful as before. *Rests on* the audit write and the Actor Identity attestation reached through the substrate; Check 6.1 and 6.2 test the order from the records. The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).

The binding and no-silent-omission give *accountable completeness*; erasure validity and groundedness give *defensible resolution*; the recorded response makes the fulfillment itself an accountable disclosure; terminality and consent non-mutation close the lifecycle and hold the oracle boundary; authentication before the act makes the attribution exact.

---

## Examples

### Walkthrough — GDPR Article 15 access request, end to end

A SaaS (Software-as-a-Service) company deploys this composition over its customer data. Its `record_source_registry` names two subject-scoped business sources: the CRM (Customer Relationship Management) store and the support-ticket store; the Selective Disclosure and Consent stores are read as response content, not enumerated as universe.

1. **Intake.** A user submits an access request through the privacy portal. The DSAR officer calls `receive_request(subject_ref = "user-5521", right_type = "access", requester = "user-5521 (verified via privacy portal)", regulatory_reference = "GDPR Article 15", actor_ref = "dsr_officer_k", credential = <cred>)` → `{request_id = "dsar-3001", received_at = "2026-06-08T09:00:00Z"}`. The substrate Audit Trail records `dsar.received`; the request is **Received**.

2. **Fulfillment.** The officer calls `fulfill_access_request("dsar-3001", "dsr_officer_k", <cred>)`. The composition:
  - **Enumerates** `user-5521`'s in-scope universe over the registry → five records: `r1` (profile, CRM), `r2` (an open support ticket), `r3` (a support ticket that quotes a *second* customer's account details), `r4` (a billing dispute record flagged by the host as attorney-client privileged), `r5` (the marketing-preferences record in the CRM). Both sources enumerate successfully — no [Incomplete Enumeration]. The recipients limb is read from the Selective Disclosure store (two prior disclosures) and the consent-history limb from the Consent store, each bound into the sealed event as the ids read.
  - **Dispositions** each record (read-only determinations): `r1 → included`; `r2 → included`; `r3 → withheld(third-party-confidentiality)` (Article 15(4) — releasing it would expose the second customer's data), reason carrying the host's `15(4)` determination reference; `r4 → withheld(legal-exemption)`, reason carrying the privilege citation; `r5 → included`. It also reads `SelectiveDisclosure.read({subject_ref: "user-5521"})` → two prior third-party disclosures (an analytics vendor, a payment processor), which become the Article 15(1)(c) *recipients* portion of the response.
  - **Records the intent, then binds the fulfillment (disclosure next, sealed event last):** the whole run holds the request section on `dsar-3001`; `dsar.access_fulfillment_intended` lands carrying `inv-71`, the five dispositions and the ids read; then `SelectiveDisclosure.record(subject_ref = "user-5521", recipient = "user-5521 (verified via privacy portal)", scope = "dsar:access:designated-record-set:dsar-3001", authority = {type: regulatory, reference: "GDPR Article 15"})` → `disc-9001`; then `AuditTrail.record_action(action_ref = dsar.access_fulfilled, actor_ref = "dsr_officer_k", <cred>, data = {request_id: "dsar-3001", invocation_id: "inv-71", dispositions: <the complete five-record set, summary: 3 included / 2 withheld>, universe_cardinality: 5, recipients: <the two disclosure ids read>, consents: <the consent ids read>, response_disclosure_id: "disc-9001", fulfilled_at})` → `ev-7001`; then `request_to_fulfillment["dsar-3001"] = {access, fulfilled_at, dispositions (all five), response_disclosure_id: "disc-9001", fulfillment_event_id: "ev-7001"}`. The request is now **Fulfilled**.
  - Returns the five dispositions, `disc-9001`, and `ev-7001`.

3. **The auditor reads the outcome.** `disposition_report("dsar-3001")` returns one verdict for each of the five enumerated records — Invariant 2 (no-silent-omission): nothing was quietly dropped, and the two withheld records carry a stated reason rather than vanishing from the response. The host then assembles and transmits the actual export for the three included records (the export bytes are the host's job; this composition recorded *what was decided and disclosed*).

### Walkthrough — GDPR Article 17 erasure request, the hold gate firing

A bank deploys this composition over its customer records; the Defensible Retention substrate runs `hold_check_mode = strict` (the required posture under litigation exposure). A customer requests erasure.

1. **Intake.** `receive_request(subject_ref = "cust-8830", right_type = "erasure", requester = "cust-8830", regulatory_reference = "GDPR Article 17", actor_ref = "dsr_officer_m", credential = <cred>)` → `{request_id = "dsar-4002", received_at}`. `dsar.received` recorded; **Received**.

2. **Fulfillment.** `fulfill_erasure_request("dsar-4002", "dsr_officer_m", <cred>)`. Under the request section on `dsar-4002`, the composition **enumerates** four in-scope records, confirms each retention id against the retention read, resolves each record by the disposition precedence, and records `dsar.erasure_execution_intended` — carrying every provisional disposition and the purge plan `{ret-r1, ret-r2, ret-r3}` — before the first purge:
  - `r1` — a marketing profile under Defensible Retention retention `ret-r1` (retention elapsed, no hold), declared basis `consent(marketing:email)`. Other-lawful-basis probe: `Consent.check("cust-8830", "marketing:email")` → revoked → erasure is due. `purge_record(ret-r1, "dsr_officer_m", <cred>)` → `ok` → **erased**. (Defensible Retention records its own `record_purged` event with `hold_check_result: empty`.)
  - `r2` — a transaction record under `ret-r2`, covered by an Active litigation hold. Other-lawful-basis: none. `purge_record(ret-r2, …)` → `under-legal-hold` → **`retained(legal-hold)`** (Article 17(3)(e)), reason carrying the blocking `hold_id`. **The hold gate fires** — this is the collision this composition exists to resolve, read directly off Defensible Retention's gate. (Defensible Retention records a `purge_blocked_by_hold` event.)
  - `r3` — a Customer Due Diligence identity record under `ret-r3`, a 5-year retention obligation not yet elapsed. Other-lawful-basis: none asserted. `purge_record(ret-r3, …)` → `not-eligible` → **`retained(retention-obligation)`** (Article 17(3)(b)).
  - `r4` — a fraud-monitoring record whose declared basis is `legal-obligation` (AML — Anti-Money-Laundering — monitoring), a non-consent lawful ground still in force. Other-lawful-basis probe matches first → **`retained(other-lawful-basis)`** (Article 17(1)(b) — a ground for processing persists); **no `purge_record` call is made** for `r4`.
  - **Binds the fulfillment (disclosure first, sealed event last):** `SelectiveDisclosure.record(subject_ref = "cust-8830", recipient = "cust-8830", scope = "dsar:erasure:outcome:dsar-4002", authority = {type: regulatory, reference: "GDPR Article 17"})` → `disc-9002`; then `AuditTrail.record_action(action_ref = dsar.erasure_fulfilled, …, data = {request_id: "dsar-4002", invocation_id: "inv-88", dispositions: <the complete four-record set, summary: 1 erased / 3 retained>, response_disclosure_id: "disc-9002", fulfilled_at})` → `ev-7002`; then `request_to_fulfillment["dsar-4002"]` is populated. **Fulfilled.**

3. **The outcome is defensible from the records.** `disposition_report("dsar-4002")` shows all four records dispositioned (Invariant 2): one erased, three retained with three *different* reasons, each traceable (Invariant 4) — `r2` and `r3` to their Defensible Retention `purge_record` outcomes, `r4` to the host-declared AML basis, `r1`'s erasure to a `record_purged` event whose `hold_check_result: empty` proves the gate passed. No held or retention-bound record was erased (Invariant 3). The customer is told, in the response disclosure, exactly what was deleted and what was kept and why.

### Rejection path — re-fulfillment, wrong right type, incomplete enumeration

- **Already fulfilled (terminal).** A retry: `fulfill_erasure_request("dsar-4002", …)` → `rejected(already-fulfilled)`. No second purge, no second disclosure, no second event — `r1` is not erased twice (it is already gone); the single fulfillment from the first call stands (Invariant 6).
- **Wrong right type.** For a *Received, not-yet-fulfilled* erasure request — say `dsar-4003`, intake recorded but no fulfillment yet — `fulfill_access_request("dsar-4003", …)` → `rejected(wrong-right-type)`; the access sibling refuses to fulfill an erasure request. Nothing is recorded. (Against an *already-fulfilled* request the state check answers [Already Fulfilled] *before* the right type is read (Action wiring 7) — terminality dominates wrong-right-type — so the wrong-right-type path is exercised only by a still-Received request.)
- **Incomplete enumeration (the no-silent-omission guard).** During an access fulfillment, one registered source — the support-ticket store — is unreachable. The enumeration cannot be completed over the declared universe → `rejected(incomplete-enumeration)`. **No disposition is recorded, no response-disclosure is written, the request stays Received.** A partial universe is never fulfilled as if whole — the exact silent omission the composition forbids. The officer retries once the store recovers.

### Rejection path — erasure write fails after the purges commit (the orphan)

An erasure fulfillment purges `r1` (`ok`, erased), records its response disclosure `disc-9002`, and then the `dsar.erasure_fulfilled` audit write answers `recording-failure(step-3)` — the append did not answer. The composition answers `recording-failure(outcome)` and does not write the event again: an append that did not answer may still land, and a second write would seal the request twice. It does not release the request section either; the grant runs to its instant. The result is an **orphan**: `r1` is irreversibly erased (its Defensible Retention `record_purged` event exists) and `disc-9002` is permanent, but no `dsar.erasure_fulfilled` event is known to exist. The erasure intent is still open, so `disposition_report("dsar-4002")` reads **Committing** and a retried [Fulfill Erasure Request] answers compensation-pending.

The reconciliation closes it. Once the intent is older than the fulfillment completion bound and the allowance, a run takes the request section on `dsar-4002` and reads the request's events again. If the first append landed after all, there is a fulfilled event carrying the intent's invocation id and nothing is open. If it did not, the run finds `disc-9002` under the request's scope, records `dsar.recovery_intended` (case compensate), and records the fulfilled event under the service identity with `cascade_recovery = true`, the operator named, and the intent's dispositions corrected from the stores: `ret-r1` reads purged, so `r1` is erased on the store's own purge instant; `ret-r2` and `ret-r3` read retained, and the answers the dead write path had for them — under-legal-hold, not-eligible — are not remembered, so both are sealed **unsettled**, an anomaly the deployment is alerted on; `r4`, settled before any purge, is sealed as the intent carries it. Exactly one fulfilled event stands either way. An intent the window did not close is alerted on.

### Rejection path — a record another act holds, and a gate that cannot say

- **Section unavailable at the gate.** During an erasure, `purge_record(ret-r5, …)` answers section-unavailable: counsel's `place_hold` over the same record is in flight inside Defensible Retention. Nothing was destroyed. The composition calls the purge once more; the hold has landed, the gate fires, and the purge answers `under-legal-hold` → **`retained(legal-hold)`** carrying the hold id and the count.
- **A record another request destroyed.** Two erasure requests for one subject race on `r6`. The second request's `purge_record(ret-r6, …)` answers not-known; the retention read answers `ret-r6` purged, so `r6` is **erased** in the second request's set too, carrying the retention id and the store's purge instant — never a registry anomaly.
- **Storage failure.** `purge_record(ret-r7, …)` answers storage-failure, and again on the one further call the substrate obliges. The retention stands retained and the record may or may not be gone (Defensible Retention Atomic writes 9), so `r7` is sealed **unsettled** — not retained — and the deployment is alerted.
- **A plan the grant cannot finish.** A subject with several hundred gated records is erased under one grant of the request section. When the remaining term falls to the plan floor, the composition makes no further purge: the records not yet reached are sealed **unsettled**, the response is disclosed and the event sealed inside the grant, and a fresh request takes up the remainder.
- **The request is busy.** A second operator calls `fulfill_erasure_request("dsar-4002", …)` while the first is mid-plan → section-unavailable, with nothing read and nothing written.

### CCPA/CPRA — consumer deletion request

A California consumer submits a deletion request under the CCPA (California Consumer Privacy Act), as amended by the CPRA (California Privacy Rights Act). The erasure path runs unchanged; CCPA section 1798.105(d)'s retained-purpose exceptions (completing a transaction, detecting security incidents, complying with a legal obligation) map onto the same `retained(...)` dispositions the GDPR Article 17(3) exemptions do — a record kept to satisfy a legal obligation is `retained(retention-obligation)` via the Defensible Retention gate, a record kept under a non-consent basis is `retained(other-lawful-basis)`. The response disclosure carries `authority = {type: regulatory, reference: "CCPA §1798.105"}` — the regulatory reference the request was received under. The cross-domain structural identity is the point: the disposition surface is regulation-agnostic; only the cited authority on the response and the host's exemption determinations change.

### HIPAA section 164.524 — access to a designated record set

A patient requests access to their records under HIPAA section 164.524 (a covered entity must provide access to protected health information in a *designated record set*). The access path runs; section 164.524(a)(1) grounds for denial — psychotherapy notes, information compiled for legal proceedings — map onto `withheld(legal-exemption)` dispositions with the citation as the reason. The Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty here as the HIPAA section 164.528 accounting-of-disclosures surface. The same per-record disposition structure serves both regimes.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "prove every record in the subject's universe was dispositioned, and that no held or retention-bound record was erased."** A DPA (Data Protection Authority — a national GDPR regulator) examines a fulfilled erasure request. It calls `disposition_report(request_id)`: by Invariant 2 (no-silent-omission), every enumerated record carries exactly one disposition — there is no record the response silently dropped. For every erased disposition, the auditor cross-reads the Defensible Retention substrate's `record_purged` event and confirms `hold_check_result: empty` (Invariant 3, resting on Defensible Retention Invariant 1 — hold-blocks-purge). For every `retained(legal-hold)` / `retained(retention-obligation)`, it confirms the then-Active hold or the unelapsed retention via Defensible Retention's stores. `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition set was not altered after the fact. The examiner consults no source code or runbooks; every claim is verified from the records by virtue of Invariants 2, 3, and 4.

**Disputed erasure — the data subject challenges a retention.** A subject's representative challenges: *"you claim you could not delete record `r2` — prove a hold actually existed."* The system presents the `retained(legal-hold)` disposition with its reason (the blocking `hold_id`) and, via the Defensible Retention substrate, `LegalHold.read({record_ref: r2})` — the Active hold with `placed_by`, `hold_reason`, `placed_at`, and `case_ref`, all immutable by Legal Hold's Invariant 1. `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition was not fabricated or back-filled. The challenge cannot be sustained without claiming the entire hold store was fabricated, at which point the Tamper Evidence seal (via the Defensible Retention substrate) is the structural rebuttal — the same rebuttal chain Defensible Retention's own disputed-destruction scenario establishes, with this composition adding the disposition binding (Invariant 4) that ties the retention claim to a specific recorded hold. The symmetric challenge — *"you erased a record you should have kept"* — is answered by the `dsar.erasure_fulfilled` event plus the Defensible Retention `record_purged` event whose `hold_check_result: empty` proves the gate passed at purge time.

**Breach or incident investigation — "during the compromise window, was any held record erased under cover of a DSAR?"** An investigator suspects an attacker used forged erasure requests to destroy records under legal hold. They query `dsar.erasure_fulfilled` events in the window (reached through the substrate Audit Trail in Event Log insertion order) and, for each erased disposition, cross-read the corresponding Defensible Retention `record_purged` event's `hold_check_result`. A held record showing erased would be the smoking gun — but Invariant 3 forecloses it structurally: the Defensible Retention gate would have returned `under-legal-hold` and yielded `retained(legal-hold)`, never erased. Because the disposition set is part of the hashed `dsar.erasure_fulfilled` payload, an attempt to *silently shrink* the set (to hide an improperly-erased record) breaks the seal — the same append-only, sealed-log rebuttal Propagate Consent Revocation Downstream and Immutable Transaction Ledger rely on. The forensic window is bounded by the substrate's seal cadence; the newest fulfillments in the unsealed tail carry per-event immutability but become seal-verifiable only at the next cadence.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the two indexes plus the Selective Disclosure, Consent and Defensible Retention substrate stores, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE fulfilled event carrying the request id of EVERY fulfillment entry (Invariant 1.2).
Check 1.2: An auditor MUST find EVERY fulfillment entry's response disclosure id resolving to a Selective Disclosure record (Invariant 1.1).
Check 1.3: An auditor MUST find EVERY fulfilled event's request id carried by a fulfillment entry (Invariant 1.3).
Check 1.4: An auditor MUST read EVERY request-scoped disclosure against the fulfilled events (Invariant 1.4).
Check 2.1: An auditor MUST find EVERY disposition's verdict IS IN the right type's vocabulary (Disposition 1).
Check 2.2: An auditor MUST find no record reference twice in one disposition set (Invariant 2.1).
Check 2.3: An auditor MUST find each disposition set's cardinality matching the fulfilled event's universe cardinality (Invariant 2.1).
Check 2.4: An auditor MUST re-enumerate an access fulfillment's universe AND find EVERY record whose creation instant PRECEDES the enumeration instant in the disposition set (Invariant 2.1).
Check 2.5: An auditor MUST read a re-enumerated record whose creation instant falls within the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 2.6: An auditor MUST NOT re-enumerate an erasure fulfillment's universe (Invariant 2.1).
Check 2.7: An auditor MUST read a re-enumerated record as outside the fulfillment's universe where the enumeration instant PRECEDES the registration of the record's source in the host's data inventory (Completeness boundary 1, External check 1).
Check 3.1: An auditor MUST find EVERY gated erased disposition's destruction record carrying an empty hold check result AND no hold override (Capability requirement 10).
Check 3.2: An auditor MUST find EVERY retained legal-hold disposition's gate record naming a hold active at the gate record's position (Invariant 4.1).
Check 3.3: An auditor MUST find a retention over the record of EVERY retained retention-obligation disposition whose retention deadline DOES NOT PRECEDE the enumeration instant (Disposition 22).
Check 3.4: An auditor MUST read a retention deadline within twice the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 3.5: An auditor MUST find destruction evidence for EVERY erased disposition (Invariant 3.1).
Check 4.1: An auditor MUST find EVERY disposition's reason naming a recoverable authority (Invariant 4.1).
Check 5.1: An auditor MUST find EVERY response disclosure naming the requester as the recipient, the request's regulatory reference as the authority AND the request id in the scope (Invariant 5.1).
Check 5.2: An auditor MUST find EXACTLY ONE request-scoped disclosure carrying the request id of EVERY Fulfilled request (Invariant 5.1).
Check 6.1: An auditor MUST find EVERY access fulfilled event preceded by an access intent carrying the event's request id AND invocation id (Invariant 8.1).
Check 6.2: An auditor MUST find EVERY erasure fulfilled event preceded by an erasure intent carrying the event's request id AND invocation id (Invariant 8.2).
Check 6.3: An auditor MUST attribute EVERY purge intent of Defensible Retention to the nearest preceding purge plan that names the purge's retention id AND whose plan span holds the purge intent (Action wiring 24).
Check 6.4: An auditor MUST report a purge intent Check 6.3 attributes to no purge plan as a direct purge (Action wiring 24).
Check 6.5: An auditor MUST report an attribution to a plan whose fulfillment carries no fulfilled event as presumptive (Action wiring 24).
Check 6.6: An auditor MUST compare an event carrying a recovery marker by the operator the event's payload names (Primitive policy 11).
Check 6.7: An auditor MUST find EVERY abandonment carrying the invocation id of an earlier intent that no fulfilled event carries (Invariant 1.5).
Check 6.8: An auditor MUST find EVERY binding orphan's request id carried by an open intent (Invariant 1.4).
Check 6.9: An auditor MUST find no intent of a request later in the log than the request's fulfilled event (Invariant 6.2).
Check 7.1: An auditor MUST find no consent record whose granting actor EQUALS the service identity (Invariant 7.1).
Check 7.2: An auditor MUST find no consent record whose revoking actor EQUALS the service identity (Invariant 7.1).
Check 8.1: An auditor MUST find a closing record for EVERY intent older than the compensation window, taken with the clock offset allowance (Invariant 1.5).
Check 8.2: An auditor MUST find the audit horizon exceeding the longest retention obligation a registered record carries (Capability requirement 9).
Check 8.3: An auditor MUST find EVERY compensating fulfilled event carrying, for EVERY record outside the plans, the disposition of the intent the event closes (Reconciliation 16).
Check 8.4: An auditor MUST find the compensation window exceeding the closure floor AND the audit horizon exceeding the alert floor (Capability requirement 39, Capability requirement 48).
Check 8.5: An auditor MUST read a check over an event the audit horizon destroyed as unknown (Reconciliation 4).
Check 8.6: An auditor MUST find EVERY fulfilled event AND EVERY intent within the payload cap AND EVERY source text within the text cap (Primitive policy 13, Capability requirement 51).
Check 9.1: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 6).
Check 9.2: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 6).
Check 9.3: An auditor MUST clear Defensible Retention's Generation acceptance over the substrate (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

Term gated erased disposition: an erased disposition whose record carried a retention id.

Term recovery marker: Defensible Retention's recovery flag on its re-emitted destruction record, or this composition's compensation flag on a fulfilled event.

Term closing record: the fulfilled event or the abandonment carrying an intent's invocation id.

Term plan span: the stretch of the log from an intent carrying a purge plan to the intent's closing record — open-ended while the intent carries none. A purge made under a plan falls inside the plan's span; a purge later in the log than the closing record is no planned call of that fulfillment, whatever retention it names.

Term enumeration instant: the intended instant of the intent a fulfilled event closes — the now under which the universe was enumerated and every verdict made; equal to the fulfilled instant except on a compensating fulfilled event.

WHY:
**The binding runs in three directions, and the orphan lives in the third** (Check 1.1 through 1.4): every fulfillment entry has its one event and resolving disclosure — whether the event verifies is Audit Trail's own acceptance, which reads an unsealed tail and a partly purged seal range for what they are (Composes 6); every fulfilled event names an entry; and every request-scoped disclosure is read against the fulfilled events — one with none is an orphan, not necessarily a failure, since Invariant 1 admits it; a failure only where no open intent stands behind it (Check 6.8), or where its intent outlived the window unclosed (Check 8.1).

**Completeness is right-type-specific** (Check 2.1 through 2.6), because re-enumeration is valid only where nothing was destroyed. For access, re-enumerate over the same registry, drop records created after the enumeration instant, and every remaining record must be in the set — with a record inside the clock offset allowance of that instant read as inconclusive, since its creation instant is the source's clock and the enumeration instant the seam's (2026-08-29-j). For erasure the erased records no longer exist, so re-enumeration would convict every erasure; completeness rests on the sealed set and its cardinality, and each gated erased disposition is cross-read against its destruction record.

**Erasure validity reads the substrate's own records** (Check 3.1 through 3.3). A destruction record carrying a hold override behind an erased disposition means the substrate ran advisory — a conformance failure against the required mode, and a record erased over a hold. A retention obligation is checked against the Retention Window record, because the substrate writes no record for not-eligible or under-active-retention; an earlier form of this check looked for one and failed every conforming implementation. The retention it looks for is any retention over the record — the named one, or the sibling behind an under-active-retention — and a deadline within two allowances of the enumeration instant is inconclusive, since the gate judged it at its own seam, later than the instant the fulfillment stamped (Check 3.3 and 3.4). Every erased disposition, gated or host-managed, compensated or clean, has destruction evidence behind it (Check 3.5).

**Authentication and nesting** (Check 6.1 through 6.6). The earlier intent is the records-alone proof the operator was authenticated before the permanent disclosure and before the first destruction. **The nesting check is the one a regulator asks for**: every substrate purge intent is attributed to the nearest preceding plan naming its retention, exact where that plan's fulfillment completed and presumptive where it did not — an abandoned plan followed by a genuine direct call reads as nested — and one no plan names is a direct purge, lawful on its own for ordinary retention-schedule destruction but the set an auditor must isolate. Plans name *attempted* destructions, so a hold-blocked record is planned again by every later request; *nearest preceding* is well-defined because destruction is at-most-once. **The two recovery markers are distinct** — the substrate's on its re-emitted destruction record, this composition's on a compensated fulfilled event — and a comparison of attesting actors would convict every recovered act, so the operator is read from the payload.

**Consent non-mutation from the records** (Check 7.1 and 7.2): the service identity acts only for this composition, so a consent record granted or revoked under it is a mutation this composition made.

**The compensation must carry the complete set** (Check 8.3): a compensating event whose set is smaller than its intent's is the silent omission reintroduced by the recovery path, and every other check here reads the sealed event and would find it internally consistent. The window is checked as the inequality that makes it meetable — the completion bound, two allowances, a cadence and a grant, strictly inside it — and not as one knob (Check 8.4). Past the audit horizon an intent, an event or a destruction record is lawfully gone, and a check that would read it reads unknown rather than failed (Check 8.5).

**The constituents' own bars are cited, not counted** (Check 9.1 through 9.3; 2026-08-26-k): a count copied from another page goes stale on that page's next change.

### External checks

```
External check 1: An auditor needing the registry's completeness confirmed MUST read the host's data inventory (Capability requirement 1).
External check 2: An auditor needing a host-asserted determination's legitimacy confirmed MUST read the legal analysis behind the determination (Invariant 4.1).
External check 3: An auditor needing the requester's identity confirmed MUST read the identity verification wired ahead of [Receive Request] (Non-goal 1).
External check 4: An auditor needing the operator's authorization confirmed MUST read the deployment's Permissions records (Non-goal 2).
External check 5: An auditor needing the statutory deadline confirmed MUST compute the deadline from the received instant AND the fulfilled instant (Non-goal 3).
External check 6: An auditor needing consent non-mutation confirmed beyond the records MUST read the generated code's Consent calls (Invariant 7.2).
External check 7: An auditor needing every hold-bearing record placed under Defensible Retention confirmed MUST read the host's hold inventory (Host-managed records 1).
External check 8: An auditor needing an alert confirmed MUST read the deployment's alerting surface (Reconciliation 22).
External check 9: An auditor needing the call pause bound confirmed MUST read the deployment's measured call latencies (Capability requirement 28).
External check 10: An auditor needing the survival of a record sealed unsettled confirmed MUST read the deployment's destruction record (Defensible Retention External check 8).
External check 11: An auditor needing the request section's discipline confirmed MUST clear Lease Check 7.1 through 7.5 over the request section's holder (Concurrency 8 through 24).
```

WHY:
These are the composition's named audit gaps, each routed to the evidence that owns it. The registry's completeness is the load-bearing one: no-silent-omission is complete over the declared universe, and a store the registry omits is invisible by construction (Completeness boundary 1). The legitimacy of an Article 15(4) withholding, a claimed privilege or a claimed non-consent basis is legal analysis — an Erasure Coordination concept and ultimately counsel's — which the composition makes auditable by recording and sealing the asserted determination (Non-goal 4). The deadline is a computation over the recorded instants and the regulation: GDPR Article 12(3)'s one month, extendable to three, or the CCPA's 45 days.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT verify a requester's identity.
Non-goal 2: The composition MUST NOT gate an action on the operator's authorization.
Non-goal 3: The composition MUST NOT compute a statutory deadline.
Non-goal 4: The composition MUST NOT adjudicate an exemption's legal validity.
Non-goal 5: The composition MUST NOT gate [Disposition Report] on the reader.
Non-goal 6: The composition MUST NOT serve a right type outside access and erasure.
Non-goal 7: The composition MUST NOT assemble the access payload.
Non-goal 8: A deployment exposing [Disposition Report] MUST gate the report on the reader's authorization.
```

WHY:
**The requester's identity is a composing concept** (Non-goal 1). The composition records the asserted requester and names it the disclosure recipient; it does not verify that the requester *is* the subject or a duly authorized representative — a parent for a minor, an executor, a law firm under power of attorney. Releasing a subject's data to an impostor, or erasing it on a forged request, is the catastrophic DSAR (Data Subject Access Request) failure, and its prevention is identity verification — a [Party Identity](../atoms/party-identity.md) / [Actor Identity](../atoms/actor-identity.md) concept wired *ahead* of [Receive Request].

**The operator's authorization is a composing concept** (Non-goal 2). The operator is attributed cryptographically through the substrate, so an auditor can always answer *who* ran a fulfillment; whether they were *permitted* to is a [Permissions](../atoms/permissions.md) instance's, scoped to DSAR-fulfillment authority — exactly as Defensible Retention leaves hold-placement authorization to a composing Permissions pattern. Keeping Permissions out of the cut is deliberate: it would make this a four-constituent composition to gate something every administrative action shares.

**The statutory deadline is not enforced here** (Non-goal 3). The received and fulfilled instants are the records-alone source; a clock that derives a due date, surfaces overdue requests and escalates is a separate concept — a Regulatory Deadline pattern *(forthcoming)* or a host dashboard reading these instants.

**Erasure Coordination is the legal adjudicator; this composition records, it does not rule** (Non-goal 4). The composition enforces the structural gate and records the asserted disposition with its reason; whether an Article 17(3) exemption genuinely applies, whether a claimed basis genuinely justifies retention, or whether an Article 15(4) third-party interest genuinely outweighs access, is counsel's call and an Erasure Coordination concept *(forthcoming)*. What the composition contributes is auditability: a later legal review starts from a complete, sealed account of what was decided and why.

**The report is not low-sensitivity, and its gate is the deployment's** (Non-goal 5 and 8). [Disposition Report] takes only a request id and records nothing. It exposes the existence and hold ids of legal holds over a subject — litigation intelligence — the privilege citations behind a withholding, the bases behind every retention, and for a fulfilled erasure possibly the only surviving description of records that no longer exist. So the deployment gates it behind authorization that confirms the reader is the subject, a duly authorized representative, or a permitted auditor, and may add an access log over the reads, mirroring Immutable Transaction Ledger's verification-query reads; an opaque request id is not access control. The composition's own audited surface is the fulfillment, not queries against it.

**The lighter rights are composing concepts** (Non-goal 6). Rectification (Article 16) is an amendment whose accountability is an Audit Trail-recorded concept, not a per-record claim collision; restriction (Article 18) is a processing-suppression flag nearer Propagate Consent Revocation Downstream's gate; portability (Article 20) is an export format over the same included set access already dispositions; objection (Article 21) is a lawful-basis re-evaluation that feeds the same other-lawful-basis branch erasure consults. Each is a lighter variant of, or a feeder into, the surface this composition provides.

**The access payload is the host's** (Non-goal 7): gathering, redacting within an included record, and delivering the export in a portable format — exactly as Selective Disclosure records *that* a disclosure occurred without performing it.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of the composition's events.
Clock semantics 2: The composition MUST NOT reconcile a skew between the seam's clock AND a constituent's clock.
```

WHY:
The received, intended and fulfilled instants are stamped from the one now injected at this composition's own seam (Capability requirement 21 through 24) — best-effort wall-time annotations, while the Event Log sequence, reached through the substrate, is the authoritative order. Skew across seams is the deployment's, under Execution Contract Logic confinement 7; every comparison of two instants this page itself makes across clocks runs under the declared clock offset allowance, and none of them decides a write alone — the request section does (Reconciliation 17). Where DSAR instants carry legal force — proving a request was fulfilled within the statutory window — a Trusted Timestamping pattern (RFC — Request for Comments — 3161, the Internet standard for trusted time-stamping) provides the verifiable anchor.

### Concurrency

```
Concurrency 1: The composition MUST hold the request section over EVERY fulfillment AND EVERY leg of one request id.
Concurrency 2: The composition MUST read the Consent answer a disposition was recorded under as that disposition's basis.
Concurrency 3: The composition MUST take the request section by Lease's try_take carrying the section term as duration.
Concurrency 4: The composition MUST mint a fresh holder value PER take (Lease Identity 6).
Concurrency 5: The composition MUST namespace the request section's key apart from EVERY other key on the Lease host (Lease Composition note 4).
Concurrency 6: IF Lease's try_take answers held OR no answer THEN a fulfillment MUST answer section-unavailable.
Concurrency 7: A fulfillment MUST NOT read the request's state BEFORE taking the request section.
Concurrency 8: The composition MUST take one reading of Lease's remaining PER disclosure write.
Concurrency 9: The composition MUST call the disclosure write ONLY IF the bind floor admits the write (Lease Sizing 3).
Concurrency 10: The composition MUST call the disclosure write WITHIN the call pause bound of asking for the write's reading (Lease Sizing 3a).
Concurrency 11: The composition MUST take one reading of Lease's remaining PER audit write AND PER planned call under the request section (Lease Sizing 5b).
Concurrency 12: The composition MUST issue an audit write under the request section ONLY IF the record start floor admits the write (Lease Sizing 5).
Concurrency 13: The composition MUST make a planned call ONLY IF the plan floor admits the call (Lease Sizing 5).
Concurrency 14: The composition MUST issue an audit write AND a planned call WITHIN the call pause bound of asking for the call's reading.
Concurrency 15: IF a lease call answers no answer THEN the composition MUST read the lease reading as expired for the rest of the grant (Lease Sizing 7).
Concurrency 16: The composition MUST NOT issue a second time, under one grant, a call that answered no answer (Lease Sizing 8).
Concurrency 17: IF the record start floor admits no call of the intent THEN the fulfillment MUST answer section-unavailable.
Concurrency 18: A yielded fulfillment MUST NOT issue a call.
Concurrency 19: IF a call in flight EXISTS under the grant THEN the composition MUST NOT release the request section (Lease Composition note 5c).
Concurrency 20: IF an audit write under the request section answers recording-failure carrying step-3 THEN the composition MUST NOT release the request section.
Concurrency 21: The composition MUST NOT issue a call under a grant the composition released (Lease Composition note 5f).
Concurrency 22: A fulfillment whose EVERY call answered MUST release the request section, a call Concurrency 20 covers excepted.
Concurrency 23: The reconciliation MUST issue EVERY call of a leg PER Concurrency 8 through 21.
Concurrency 24: A leg whose EVERY call answered MUST release the request section, a call Concurrency 20 covers excepted.
```

Term yielded fulfillment: an intended fulfillment whose grant of the request section admits no call the fulfillment still owes — the lease reading expired, or the remaining term at or below the floor of the next call. Past the yield the fulfillment issues nothing more, and the open intent is the reconciliation's. A yielded fulfillment is no longer an intended, executed or disclosed one, and an enumerated fulfillment whose grant admits no call of the intent is no longer an enumerated one: the rules that oblige those to call bind a fulfillment only while a floor admits the call.

Term call in flight: a call issued under a grant that has not answered. A call that answered no answer stays in flight to the grant's end, since a call that never answered may still land.

WHY:
**One request, one writer at a time** (Concurrency 1 and 3 through 7; the section titled *A compensator is exclusive* in `pressure-testing.md`). A fulfillment reads the request's state and then writes an intent; a leg reads the request's events and the disclosure store and then writes a closure. Each is a look and then a write, and a second writer between the two makes the look false: two fulfillments both read Received and both disclose, two runs of the leg both find no fulfilled event and both seal one, a leg compensates a fulfillment that is about to seal. An earlier revision said the fulfillments of one request *serialize* and named nothing that serialized them, and gave the invocation a terminus — stop at the completion bound — that it could not observe, since an invocation reads the clock once. Both are closed by one [Lease](../atoms/lease.md) on the request id. A second caller that finds the section held hears section-unavailable and retries; by then the first has sealed and the answer is already-fulfilled, or it died after its intent and the answer is compensation-pending until the leg closes it.

**The lease alone keeps a slow holder off a request the next holder has taken**, because no write here carries a fence, so the atom's sizing rules are this composition's own obligations (Lease Composition note 8). The disclosure write is one write: issued on a live reading and within the call pause bound of asking for that reading, so the write lands inside the grant (Concurrency 8 through 10). An audit write and a planned call are each a unit of work, bounded by the audit write latency and the planned call latency, started only while the grant has that long and the write margin left (Concurrency 11 through 14); a unit here is one call, so there is no later write of a unit to withhold (Lease Sizing 5a). A lease call that never answers leaves the grant unreadable, and the holder treats it as lost (Concurrency 15 and 16). A call that never answered may still land, so the section is not released over it and the grant runs to its instant (Concurrency 19); the substrate's step-3 refusal is the same case under another name, since the append behind it may not have answered, and it is held the same way (Concurrency 20). The atom's rules for a share of a budget have no subject here — a take asks for the whole section term (Lease Sizing 6, Lease Sizing 6a).

**A grant that runs out is a yield, and what the caller hears depends on what is behind it** (Concurrency 17 and 18). Before the intent, nothing was written and the answer is section-unavailable. After it, the fulfillment stops where it stands — it starts no further call on a grant another writer may already hold — and answers intent or outcome by whether anything possibly permanent was done (Action wiring 20 and 29). The plan floor keeps the common case from reaching a yield at all: a planned call is not started unless the bind still fits after it (Disposition 45).

**Two requests for the same subject do not serialize here, and two erasures may race on one record.** The record's own section, inside Defensible Retention, orders them: the loser's purge answers section-unavailable while the winner's is in flight and not-known once the record is gone, and the retention read then lands the record erased on the store's own instant (Disposition 41 and 43; 2026-08-29-f) — never a registry anomaly. A withdrawal landing after an erasure's Consent read does not reach back into a disposition already bound (Concurrency 2); the subject's remedy is a new request, per the snapshot rule.

### Accounting stores

```
Accounting stores 1: An erasure fulfillment MUST retain the accounting stores as a class.
Accounting stores 2: The composition MUST NOT disposition an accounting store's record.
```

WHY:
The Selective Disclosure and Consent stores hold the composition's *accounting* of the subject — who was told what, and what the subject agreed to — and both are append-only by their atoms' invariants. An erasure neither dispositions their records nor erases them: they are retained as a class under Article 17(3)(b) and (e) and the record-keeping obligations of Article 30 and HIPAA (the US Health Insurance Portability and Accountability Act) section 164.528, a basis stated once, here, rather than manufactured per record for records no branch could resolve. Their contents reach the requester as response content.

### Completeness boundary

```
Completeness boundary 1: The composition MUST claim no-silent-omission ONLY over the declared universe.
```

WHY:
A store the registry omits is invisible — its records neither enumerated nor dispositioned, and their absence undetectable, since nothing enumerates what it was never told about. The composition does not guarantee it found *all* of a subject's data across an enterprise; it guarantees it dispositioned every record in the *declared* universe, completely, and bound that set into one sealed act. A deployment that under-declares the registry produces fulfillments that are internally complete and globally partial; closing that is the host's data-mapping discipline (External check 1).

### Host-managed records

```
Host-managed records 1: The composition MUST NOT claim the hold guarantee over a host-managed record.
Host-managed records 2: A deployment needing the hold guarantee over a record MUST place the record under Defensible Retention retention.
```

WHY:
A host-managed record is erased through the host delete, never through the substrate's gate, so a record under a preservation hold registered only in a host store — never placed in Defensible Retention's Legal Hold instance — could be host-erased with no gate firing. The composition evaluates no hold itself (Wiring decision 5), and the gate that does is reached only through a retention, so it cannot close this from inside; a host-managed erased is a host-attested outcome, not a records-alone-provable one (External check 7).

### Snapshot

```
Snapshot 1: A fulfilled event MUST NOT carry a disposition for a record outside the fulfillment's enumeration.
```

WHY:
The disposition set is the universe as enumerated at the enumeration instant — the fulfillment's own now, which a compensating event keeps from the intent it closes while stamping its own fulfilled instant. A record created later — a new ticket, a new transaction — is not retroactively dispositioned by the closed request; a subject wanting it addressed submits a new request. A request answers the state at the time it was answered, as Consent's most-recent-grant semantics and Selective Disclosure's point-in-time history do.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes — the intake ([Receive Request]), the two fulfillment siblings ([Fulfill Access Request], [Fulfill Erasure Request]) and the read-only [Disposition Report]; the [Dispositions] set carrying a verdict for every enumerated record; the closed verdict vocabulary ([Included], [Withheld], [Erased], [Retained], [Anomaly]); and its own fulfillment refusals ([Wrong Right Type], [Already Fulfilled], [Incomplete Enumeration]). No-silent-omission and the binding bijection are structural properties, not data. The deployment settings keep their wire spellings in configuration — `record_source_registry`, `audit_trail_retention_policy`, `application_actor_ref`, `application_credential`, `compensation_window`, `fulfillment_completion_bound`, `reconciliation_cadence`, `clock_offset_allowance`, `call_pause_bound`, `section_term`, `section_read_bound`, `planned_call_latency`, `text_cap` — and the two indexes theirs in an implementation, `request_to_subject` and `request_to_fulfillment`; the page names each in English where it declares it. Defensible Retention's purge taxonomy is cited whole — ok and the rest of its declared refusals — rather than listed in part. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; the scheduler; a deployment; a regulated deployment; an auditor; a caller; a requester; a subject; an operator; a reader; an invocation; a leg; a fulfillment; a validated intake; a landed intake; an admitted fulfillment; an enumerated fulfillment; an intended fulfillment; an enumerated access; an intended access; a disclosed access; an enumerated erasure; an intended erasure; an executed erasure; a disclosed erasure; a landed fulfillment; an unsealed fulfillment; a yielded fulfillment.

Term records: the intake events, intents, fulfilled events, abandonments and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference below — the response disclosures it records through the disclosure write, and the two indexes' entries.

Term record verbs: add, adjudicate, alert, answer, assemble, attest, attribute, bind, call, carry, change, check, claim, classify, clear, close, compare, compensate, compose, compute, confirm, correct, cover, declare, derive, destroy, disclose, disposition, enumerate, escalate, evaluate, examine, exist, expose, find, gate, hold, include, inherit, inject, inspect, issue, key, land, leave, make, match, mint, name, namespace, normalize, open, own, pair, pass, persist, place, plan, proceed, produce, provision, re-enumerate, re-invoke, reach, read, rebuild, reconcile, record, release, report, resolve, retain, retry, route, run, select, serialize, serve, set, settle, size, stamp, start, store, supply, survive, take, verify, write, yield.

Term value sets: action reference = dsar.received | dsar.access_fulfillment_intended | dsar.erasure_execution_intended | dsar.access_fulfilled | dsar.erasure_fulfilled | dsar.intent_abandoned | dsar.recovery_intended. withheld reason = third-party-confidentiality | legal-exemption. retained reason = legal-hold | retention-obligation | other-lawful-basis. anomaly reason = determination-unavailable | consent-basis-not-known | mis-paired | unknown-retention | host-record-not-found | unsettled. The rest are declared where the section that owns each declares it: right type, request state, verdict, position, case, withdrawn answer, determination reading, basis reading, retention reading, retry answers, unsettling answers, purge reading, lease reading, disclosure fault.

Term bounds: compensation window (compensation_window), fulfillment completion bound (fulfillment_completion_bound), clock offset allowance (clock_offset_allowance), audit horizon (audit_trail_retention_policy), call pause bound (call_pause_bound), section term (section_term), section read bound (section_read_bound), planned call latency (planned_call_latency), text cap (text_cap), and the bounds and floors computed from them — section work bound, record start floor, bind floor, plan floor, closure floor, alert floor, reason bound.

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive pattern, audit write, trail, trail read, retention read, disclosure write, disclosure read, universe enumeration, request id, request index, request entry, fulfillment index, fulfillment entry, live entry, aged entry, request's events, unbound disclosure, state read, intake event, intent, aged event, open intent, fulfilled event, abandonment, plan span, request state, record source registry, creation instant, declared basis, host determinations, host delete, route, host-managed record, accounting store, audit horizon, hold guarantee, service identity, compensation window, fulfillment completion bound, reconciliation cadence, clock offset allowance, seam, now, invocation id, request section, call pause bound, section term, section read bound, section work bound, planned call latency, record start floor, bind floor, plan floor, lease reading, closure floor, alert floor, source text, text cap, reason bound, alerting surface, scheduler, subject reference, right type, requester, regulatory reference, actor reference, credential, record reference, retention id, caller string, largest record, writer, pre-effect record, position, compensation flag, intake result, fulfillment result, report, validated intake, landed intake, fulfillment, admitted fulfillment, enumerated fulfillment, enumerated access, enumerated erasure, universe cardinality, recipients read, consents read, access intent, intended fulfillment, intended access, access scope, request scope, response authority, disclosure fault, refused disclosure write, disclosed access, erasure intent, provisional dispositions, purge plan, host delete plan, destroying surface, planned call, planned record, intended erasure, executed erasure, possibly destroyed record, possibly committed act, erasure scope, disclosed erasure, landed fulfillment, unsealed fulfillment, reconciliation, leg, young intent, overdue intent, request-scoped disclosure, recovery intent, case, compensating fulfilled event, destruction record, destroyed planned record, binding orphan, disposition, verdict, withdrawn answer, determination reading, basis reading, erasure-due record, retention reading, settled record, planned, retry answers, unsettling answers, purge's first answer, purge's last answer, purge reading, outside the host delete's contract, destruction evidence, gated erased disposition, recovery marker, closing record, enumeration instant, yielded fulfillment, call in flight.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the substrate. record, read, disclosure id, scope, authority, recipient, invalid-request, unknown-authority-type, storage-failure: Selective Disclosure. check, read, grant, revoke, consent id, purpose, granted, revoked, expired, not-known, granting actor, revoking actor: Consent. purge_record, ok, not-known, not-eligible, under-active-retention, under-legal-hold, hold-check-unavailable, section-unavailable, storage-failure, gate, hold ids, count, hold check mode, strict, advisory, hold check result, hold override, gate record, record_purged, purge_intended, business retention instance, landed record, owed record, audit write latency: Defensible Retention. record_action, verify_record, payload cap, step-2, step-3, step-4, invalid-credential, recording-failure, Erasure Tombstone: Audit Trail. read, retention state, retained, purged, retention deadline, purge instant: Retention Window. read, sequence, recording instant: Event Log. try_take, remaining, release, held, remaining term, holder value, grant, key, write margin, no answer: Lease.

Term composing patterns: [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Multi-Party Approval](./multi-party-approval.md); [Immutable Transaction Ledger](./immutable-transaction-ledger.md); [Customer Onboarding](./customer-onboarding.md); [Party Identity](../atoms/party-identity.md); [Actor Identity](../atoms/actor-identity.md); [Permissions](../atoms/permissions.md).

#### Receive Request

The composition's intake action: record that a data subject rights request (access or erasure) was received — stamping the moment that starts the statutory clock — and audit it (`dsar.received`). Returns `{request_id, received_at}`; the request is now Received.

Kind: Operation

#### Fulfill Access Request

The fulfillment sibling that resolves a received access request into a complete [Dispositions] set — each enumerated record [Included] or [Withheld] with a stated reason — assembles the Article 15(1)(c) recipients answer from Selective Disclosure, discloses the response to the requester, and seals the whole set into one `dsar.access_fulfilled` event. Read-only over the records (no record is mutated).

Kind: Operation

#### Fulfill Erasure Request

The fulfillment sibling that resolves a received erasure request into a complete [Dispositions] set — each record [Erased] or [Retained] with a stated reason — irreversibly purging exactly the records no claim preserves by wrapping Defensible Retention's `purge_record` gate, then sealing the outcome into one `dsar.erasure_fulfilled` event. Kept distinct from the access sibling because its irreversible-purge effect is a load-bearing behavioral fork.

Kind: Operation

#### Disposition Report

The read-only surface a subject, auditor, or regulator uses to read a request's outcome: Received (intake only), Committing (a fulfillment in flight or awaiting the reconciliation) or Fulfilled (the complete per-record [Dispositions] with response-disclosure and fulfilled-at). Produces no audit event — it changes no state.

Kind: Operation

#### Dispositions

The complete set of per-record verdicts `{record_ref, source, disposition, reason}` covering the *entire* enumerated in-scope universe for a request — the no-silent-omission surface an auditor reads to confirm every record was accounted for. Bound into the sealed fulfillment event, so a later silent edit breaks the seal (Invariants 1, 2, 4).

Kind:       Field
Field of:   the fulfillment record
Role:       the complete per-record verdict set
Projection: dispositions

#### Included

The access disposition for a record handed over to the requester — no third-party-confidentiality implication and no legal exemption applied.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: included

#### Withheld

The access disposition for a record *not* handed over, carrying a stated reason — third-party-confidentiality (Article 15(4)) or legal-exemption — so the omission is recorded and attributed, never silent.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: withheld

#### Erased

The erasure disposition for a record destroyed — through Defensible Retention's `purge_record`, by an earlier act the retention store attests, or by the host delete of a host-managed record — recorded only on destruction evidence (Invariant 3.1). Irreversible by the time the fulfillment binds.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: erased

#### Retained

The erasure disposition for a record *preserved rather than destroyed*, carrying the strongest applicable reason — `legal-hold` (Article 17(3)(e)), retention-obligation (Article 17(3)(b)), or other-lawful-basis (Article 17(1)(b), including a consent still in force) — read off Defensible Retention's gate outcome or the upstream Consent oracle.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: retained

#### Anomaly

The disposition for a record whose fate or basis could not be settled — a failed determination, a consent basis the Consent store does not know, a mis-paired or unknown retention, or a planned record its call did not settle: a gate or host answer that leaves the record's fate unsaid, or a call the fulfillment never made — carrying its reason and alerted on, never silently read as erased or retained. Terminal for the fulfillment; the remedy is the deployment's and a fresh request.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: anomaly

#### Wrong Right Type

The fulfillment rejection when a request's stored right_type does not match the sibling invoked — an erasure request sent to [Fulfill Access Request], or vice versa.

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: wrong-right-type

#### Already Fulfilled

The fulfillment rejection when the request already carries a fulfilled event — Fulfilled is terminal (Invariant 6), so a request is fulfilled exactly once.

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: already-fulfilled

#### Incomplete Enumeration

The fulfillment rejection when a read the fulfillment must complete before its intent fails — a declared record source's enumeration, the disclosure read or Consent's read of an access, the retention read of an erasure. Completeness is all-or-nothing before the intent, so a partial universe records nothing rather than being fulfilled as if whole (the silent omission the composition exists to forbid).

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: incomplete-enumeration

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Receive Request]: #receive-request
[Fulfill Access Request]: #fulfill-access-request
[Fulfill Erasure Request]: #fulfill-erasure-request
[Disposition Report]: #disposition-report
[Dispositions]: #dispositions
[Included]: #included
[Withheld]: #withheld
[Erased]: #erased
[Retained]: #retained
[Anomaly]: #anomaly
[Wrong Right Type]: #wrong-right-type
[Already Fulfilled]: #already-fulfilled
[Incomplete Enumeration]: #incomplete-enumeration


## Standards references

This composition is the structural form of the resolve-a-persons-data-rights requirement: enumerate a subject's record universe, resolve each record's competing claims into one accountable disposition, and prove the resolution from the records alone. Its primary anchors:

- **GDPR (EU General Data Protection Regulation) Article 15 (Right of access by the data subject)** — the subject may obtain confirmation of processing, a copy of the data, and *the recipients or categories of recipient to whom the personal data have been disclosed* (Article 15(1)(c)). This composition's access path produces the per-record included / `withheld(...)` disposition set, and the Selective Disclosure read answers the recipients limb from the records alone.
- **GDPR Article 15(4)** — the right to obtain a copy *shall not adversely affect the rights and freedoms of others*. The `withheld(third-party-confidentiality)` disposition is the structural form of this limit; this composition records the assertion, and its legitimacy is the externally-clearable check.
- **GDPR Article 17 (Right to erasure / "right to be forgotten")** — Article 17(1) names the grounds that trigger erasure, including 17(1)(b) (consent withdrawn and no other lawful ground — the Consent-oracle branch). Article 17(3) names the exemptions: 17(3)(b) (compliance with a legal obligation / retention — `retained(retention-obligation)` via the Defensible Retention Retention Window leg) and 17(3)(e) (establishment, exercise, or defence of legal claims — `retained(legal-hold)` via the Defensible Retention hold-blocks-purge gate). This composition's erasure path is the structural resolution of Article 17 against its own 17(3) exemptions.
- **GDPR Article 12(3)** — fulfillment within one month of receipt. This composition records `received_at` and `fulfilled_at` as the records-alone source; deadline computation is a composing/externally-clearable concept.
- **GDPR Articles 16, 18, 20, 21 (rectification, restriction, portability, objection)** — named composing concepts (Non-goal 6), lighter variants of or feeders into the fulfillment surface rather than additional spines.
- **CCPA / CPRA (California Consumer Privacy Act, as amended by the California Privacy Rights Act)** — section 1798.100 (right to access / know) maps to the access path; section 1798.105 (right to delete) maps to the erasure path, with section 1798.105(d)'s retained-purpose exceptions mapping onto the same `retained(...)` dispositions as the GDPR Article 17(3) exemptions. The cross-domain identity — one disposition surface, regulation-agnostic — is the composition's thesis.
- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.524 (Access of individuals to protected health information)** — access to a designated record set; section 164.524(a)(1) grounds for denial map to `withheld(legal-exemption)`.
- **HIPAA section 164.526 (Amendment of protected health information)** — the rectification analog, a named composing concept (Article 16 family).
- **HIPAA section 164.528 (Accounting of disclosures)** — the Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty as the section 164.528 accounting surface.

This composition inherits the broader standards compliance of its constituents:

- Through **Defensible Retention** (and transitively Legal Hold, Retention Window, and the Audit Trail substrate with its Event Log, Actor Identity, Tamper Evidence, and Retention Window): FRCP (US Federal Rules of Civil Procedure) Rule 37(e) litigation-hold preservation, SOX (Sarbanes-Oxley Act) section 802, SEC (US Securities and Exchange Commission) Rule 17a-4, HIPAA section 164.530(j), GDPR Article 17's interaction with retention obligations, and the full Audit Trail standards inheritance (HIPAA section 164.312(b) audit controls, ISO/IEC (International Organization for Standardization and International Electrotechnical Commission) 27001 clause A.12.4, GDPR Articles 30 and 32). This composition's erasure gate *is* Defensible Retention's hold-blocks-purge gate, so these are inherited at the gate, not re-anchored.
- Through **Selective Disclosure**: GDPR Article 15(1)(c) and Article 30, HIPAA section 164.528, and SEC Rule 17a-4 at the disclosure-accounting layer — the surface that records each fulfillment response and answers the recipients limb of access.
- Through **Consent**: GDPR Article 6(1)(a) and Article 7 (consent as a lawful basis and its withdrawal), Article 17(1)(b) (the withdrawn-consent erasure trigger this composition's other-lawful-basis branch consults), CCPA/CPRA opt-out, and HIPAA section 164.508 authorization — read as the authority oracle, never mutated.

---

## Status

`grounded on Final Critique 10 — 2026-10-05` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 10 — 2026-10-05
formal: verified — resolve-a-persons-data-rights.tla + 9 twins + 3 probes (one erasure against two legs of the reconciliation, under the request section: 90,837 states, holding at a term of 6 within 9 ticks), resolve-a-persons-data-rights-access.tla + 1 probe (a fulfillment with nothing planned against the same two legs: 9,436 states, holding at a term of 7 within 9 ticks) and resolve-a-persons-data-rights-admission.tla + 1 twin + 1 probe (two fulfillments of one request: 49,460 states, holding at a term of 7 within 8 ticks), re-derived from the page as it stands, 2026-10-05
last gate: 2026-10-05 — Final Critique 10, fresh reader, three passes on one text — 0 foundational, 41 refining reports, 14 rhetorical reports

open:
- 2026-10-05-a · refining · Term yielded fulfillment; Term unsealed fulfillment; Action wiring 16, 22, 24 through 26, 28, 31 · a yielded fulfillment is said to be no longer an intended one and an unsealed one is defined as an intended one that yielded, and the stage rules oblige calls the floors forbid → one stage vocabulary that says which rules bind a yield
- 2026-10-05-b · refining · Term section work bound; Term plan floor; Term closure floor; Capability requirement 32, 34, 39 · the work bound is one call pause short where the read bound runs from the take's answer and the grant from its effect, and the closure floor counts neither a run's time over its other open intents, nor the delay from the seam's now to the take, nor a run that finds the section held; the worst case is a planned record sealed unsettled or an early alert → recount, by enumeration
- 2026-10-05-c · refining · Disposition 41, 45; Reconciliation 13 through 15 · Defensible Retention Action wiring 82 obliges a retry of a purge that answered storage-failure, made here once where the plan floor admits it and never by a leg; an immediate retry after the substrate's own step-3 refusal meets its unreleased record section; and the unretried purge has no named receiver beyond the alert → name the receiver
- 2026-10-05-d · refining · Reconciliation 13, 14; Audit arm 16 · an erasure whose invocation died after its intent is completed with every planned record unsettled, a permanent disclosure after the caller heard intent, where the substrate's purge intents and gate records on the shared trail could show that no call was made or that a hold refused one → re-derive from the trail what the trail shows
- 2026-10-05-e · refining · Primitive policy 5, 13; Audit arm 19, 20; Action wiring 21, 38; Concurrency 17 · invalid-request lands a caller's blank input and three deployment faults, before an intent and after one, a blank request id has no policy, and two refusals that write nothing can both hold with no order → one code per meaning
- 2026-10-05-f · refining · Term reason bound; Term largest record; Capability requirement 40, 51 · the ids' longest length is no declared setting, the text cap's unit is unstated, and Audit Trail's payload cap defaults to none → declare each
- 2026-10-05-g · refining · Composition state 14, 25; Capability requirement 50; Reconciliation 25 · an aged entry is a whole verdict set kept for the life of the instance with no retention, seal or owner beyond the forthcoming Erasure Tombstone, and an index write that fails raises no alert → an owner; an alert
- 2026-10-05-h · refining · Accounting stores 1, 2; Selective Disclosure Composition note 3 through 6; Consent Composition note 6 · the seal and the retention of the accounting stores, the attestation of a disclosure's writer and the legitimacy of the response authority are neither met nor declined with a named receiver → state each
- 2026-10-05-i · refining · Check 3.1 through 3.4, 8.5; Capability requirement 9, 49; Term aged event · four checks re-derive what Defensible Retention's own checks own, and the one-policy rule and the unknown reading reach this composition's action references and not the substrate's records the checks read → cite; widen
- 2026-10-05-j · refining · Invariant 1.2, 1.3, 1.6, 2.2, 3.2, 5.1, 6.1; Term Already Fulfilled · three invariants lack the past-horizon qualifier Invariant 1.5 carries, and four are named by no check → qualify; a check each
- 2026-10-05-k · refining · Disposition 32, 33, 36, 39, 43; Reconciliation 24; Term basis reading · the purge instant is unnamed where a sibling and the named retention were purged apart, an enumerated record that reads purged is sealed erased with no alert, an over-cap host answer fits two arms, the retention read a not-known obliges is stated in a term alone, and the basis reading lacks the first-that-holds order → state each
- 2026-10-05-l · refining · Concurrency 4, 10, 14; Capability requirement 21, 25, 46; Term planned call latency · the holder value's source and a leg's own id are undeclared, a no-answer is timed on a span no rule gives an invocation a clock for, and nothing bounds the seam's now to the take → declare the span clock; inject the ids
- 2026-10-05-m · refining · Reconciliation 8, 10, 11, 29; Term case · the disclosure pairs on the request id where the method names the invocation id, the recovery intent's multiplicity is unstated, and abandon is a case no recovery intent carries → state each
- 2026-10-05-n · refining · Check 7.1, 7.2; Capability requirement 12; Disposition 9 · the service identity's distinctness from the substrate's, which shares its configuration names, is unstated; the two checks read actor fields Consent does not attest; and a consent judged on Consent's clock alone leaves the auditor no instant to ask again as of → state; an external check
- 2026-10-05-o · refining · Wiring decision 1, 3; Action wiring 14; Disposition 1; Invariant 1.1, 2.1, 7.1, 7.2; Capability requirement 8, 13, 33; Reconciliation 5, 18; Composition state 9 · one proposition under two rules in six places, and two requirements that hold by construction → tombstone the second owner
- 2026-10-05-p · refining · Audit arm; Reconciliation; Concurrency 3 through 24 · the intent and outcome pairing, the audit arms, the leg and the request section are the invocation protocol Recoverable Invocation is drafted to own, restated here a third time after Audit Trail and Defensible Retention → extract when that composition grounds; own round
- 2026-10-05-q · rhetorical · Summary; Examples; Terms; Composition-level invariants · sealed, compensated and tamper-evident are unglossed in the Summary; the walkthrough payloads omit fields the rules require and nothing walks the host delete, the invocation's own abandonment or state-unavailable; four refusals have no term entry; Retained says strongest reason where the page says recording convention; the examples write rejected where the rules say answers; the Invariant 9 tombstone sits in Invariant 8's block → rewrite on the next load-bearing touch
- 2026-10-05-r · refining · Capability requirement 34, 41, 42, 49, 50, 52 through 54; Reconciliation 10, 29 · no check and no external check reads them → a check each, or name them external
- 2026-10-05-s · refining · Check 2.4, 2.6, 2.7; Capability requirement 1 · the registry is not obliged to carry a source's registration instant, a record that became the subject's after the enumeration instant convicts a conforming access, the comparison crosses clocks with no allowance, and an erasure's universe is never re-enumerated → oblige the instant; an inconclusive reading
- 2026-10-05-t · refining · Check 1.3, 3.1, 6.1, 8.1; Term compensation window · a fulfilled event awaiting its entry and a destruction record owed to the substrate's sweep convict in passing, Check 6.1 never reads the disclosure's instant, and Check 8.1 demands a closing record where the Term accepts an alert → a pending reading; one meaning
- 2026-10-05-u · refining · Term aged event; Capability requirement 46; Reconciliation 4, 25, 33, 34 · age is judged once on a leg's now and the trail is read up to a take and a read bound later, so an abandonment may age out between and be written again; the run that classifies and alerts has no now of its own; and an aged fulfilled event still readable and carrying no entry is both to be written and not examined → Defensible Retention's stand-in; a run's now; except the index write
- 2026-10-05-v · refining · Term purge plan; Disposition 41, 45; Reconciliation 28 · the plan's call order and the moment of the one re-invoke are unpinned, so two implementations destroy different records where the grant cuts the plan, and a leg's disclosure write that answers no answer has no arm → pin; add the arm
- 2026-10-05-w · refining · Term purge reading; Disposition 41 · the reading of not-known and the single retry depart from Defensible Retention Action wiring 73 and 82 in a Term and a WHY alone → a declared deviation
- 2026-10-05-x · refining · Disposition 3, 4, 6; Invariant 4.1; Check 4.1 · no rule puts the determination's reference in an access reason, which the invariant and the check require → add it
- 2026-10-05-y · refining · Term alert floor; Capability requirement 48 · the floor counts on an answer inside the window that no requirement obliges of the deployment → state it
- 2026-10-05-z · rhetorical · Term fulfillment; Term reconciliation; Term leg; the reason value sets · fulfillment names the call and the bound triple, reconciliation is defined as the leg and run is undeclared, and three reasons each cover two causes → one name each
- 2026-10-06-a · refining · Term alert floor; Capability requirement 48, 49; Reconciliation 34 · the floor counts no time for a run's enumeration, which nothing bounds, so an intent can age while a run is still reading toward it; and Defensible Retention now sets one policy over every event of the shared audit instance and keeps its action references to itself, which this page states for its own references alone → that page's enumeration bound; cite Defensible Retention Capability requirement 57 and 64; found by that page's Final Critique 13 and swept here ahead of this page's confirming round
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/resolve-a-persons-data-rights.md`.

- **2026-10-05 — The closing round: one instance for each store it writes, the alert ahead of the take, and a floor that leaves the alert its window.** *Chose:* no two instances of the composition over one Defensible Retention instance or one Selective Disclosure instance (Capability requirement 52, 53); the audit retention policy unchanged for the life of the instance (Capability requirement 54); the overdue alert raised from the run's enumeration ahead of any take, and a run that cannot enumerate alerting on that (Reconciliation 33, 34); an alert floor of two windows, two cadences and five allowances, so the alert has a window to be answered in and a run follows the answer (Term alert floor); a purge attributed to a plan only inside the plan's span (Check 6.3, 6.4, Term plan span); a re-enumerated record of a source registered later read as outside the universe (Check 2.7); verification left to Audit Trail's own acceptance (Check 1.1). *Over:* two reconciliations each reading the other's intents on one trail, an alert a held section could postpone until the intent aged, a floor that alerted and aged within the same minute, an attribution with no upper edge, and a check that convicted an access for a source that did not yet exist. *Because:* Defensible Retention's re-grounding the same day found the instance sharing, the alert under the section and the horizon read from a changed policy on its own page, and each stood here too (the batch rule — reference first, then swept, one closing round); the rest is what that round's nine reader runs found on the way to one clean text. Not swept: Defensible Retention's stand-in, which closes a race a leg's own duration opens at the horizon — here the worst it leaves is a second abandonment of an intent truly abandoned, a safe state, routed as line 2026-10-05-u.
- **2026-10-05 — One request, one writer at a time; a leg seals what the stores show; a gate's answers are read together; findings became alerts.** *Chose:* the request section, a Lease on the request id, over every fulfillment and every leg, an invocation id on every record, and no audit write issued twice; the request's state read from the trail, the durable fulfillment entry and the response disclosure, which never ages; the reconciliation closing an intent by what could have committed — compensate, complete, and abandon only where nothing was planned — and sealing from the stores, remembering nothing; every answer of the gate, the stores and the host read through a declared reading that takes exactly one value, a storage-failure never taken back by a later refusal; every pairing confirmed against Retention Window's own read, a host-managed record's included; the largest record sized whole before the intent, with no digest and no truncation; one audit retention policy for every event the composition records; alerts on a declared surface where finding events had no closer. Each decided by a standing rule: *make all things mean one thing* (the readings, one horizon, section-unavailable as the substrate means it); *as simple as possible without losing fidelity* (alerts for findings, a universe the cap cannot carry refused rather than digested, an unreadable trail answered state-unavailable); *generalize nothing* (Consent asked with no at time, so no reading of this seam's decides an erasure). *Over:* a serialization nothing held, a terminus an invocation that reads the clock once could not observe, a retry after a step-3 refusal, a precedence stated in a WHY, a pairing confirmed against a listing of what is already destroyable, a leg that abandoned a destruction no store shows, and a digest no compensation could seal. *Because:* Defensible Retention's re-grounding moved its purge's answers and what its storage-failure means, and the gate that followed showed every look-then-write on this page resting on a second writer not arriving.
- **2026-09-24 — Rewritten in GRACE lang v0.61; thirty-three of thirty-four open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict ladder as its own `Disposition` family; invariant numbers 1 through 8 unchanged, Invariant 9 tombstoned to Composes 6; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and six Edge cases families. Choices the page left open, each decided by a standing rule: the anomaly admitted as a fifth verdict with a finding, terminal for the fulfillment (2026-08-26-g — *as simple as possible without losing fidelity*: a request held open over a record the substrate or the host must settle first answers nothing sooner); access failing closed to an anomaly on a determination error (2026-08-26-h — the same rule the erasure ladder already kept); the recipients and consent limbs sealed as the ids read rather than a digest that diverges by construction (2026-08-26-m); invalid-credential answered as itself at intake (2026-08-26-f, 2026-08-29-b — *make all things mean one thing*); the regulatory reference taken per request (2026-08-29-g — fidelity, since one deployment answers GDPR and CCPA requests alike); the gate's answers mapped by Defensible Retention's own positioned taxonomy, with one destruction-safe re-invocation for the three answers that say nothing about the record (2026-08-26-i, 2026-08-26-j); and an unconfirmable pairing recorded as such in the reason rather than reached through the Retention Window (2026-08-26-r, 2026-08-29-e — *generalize nothing*). One defect found in the pass and fixed in it: the retention-step arm at a pre-effect record was unlanded, so an appended intent answered as retryable left the caller's retry refused compensation-pending. *Over:* the prose's step lists, a closed vocabulary with a fifth member used outside it, and a seal no one could recompute. *Because:* the rules state each landing once and the fork between the siblings once; the formal line stays open because the model, not the page, is what it owes.
- **2026-08-26 — The erasure intent record carries a `purge_plan`, and authentication is not inherited across the substrate boundary.** *Chose:* the plan names the retentions a rights fulfillment will attempt, so a purge occasioned by an authorized fulfillment is distinguishable in the shared Audit Trail from a direct call that bypassed the rights process; Defensible Retention verifies the same credential independently at its own boundary. *Over:* treating the outer authentication as covering the nested purges. *Because:* the substrate's surface is independently callable, so what the plan records is provenance, not authority.
- **2026-08-29 — The scan is bounded at both edges and records its intent before it seals or writes.** *Chose:* `fulfillment_completion_bound` below and the audit horizon above for the reconciliation scan; a `dsar.recovery_intended` record before direction 2's cases (i) and (ii); the pairing stated as exact by the Committing gate. *Over:* a scan on `reconciliation_cadence` alone. *Because:* a Committing request seconds old belongs to an invocation about to seal, and case (ii) would write a second response-disclosure beside the one it is about to bind; a seal the scan writes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).
- **2026-08-29 — The accounting stores leave the universe, a request can be Committing, and the scan compensates only what reached the bind.** *Chose:* the Selective Disclosure and Consent stores are response content retained as a class, not dispositioned records; a Committing state (intent with no closing event) that both fulfillment actions refuse with compensation-pending; scan step 2 resolved by whether a response-disclosure exists (compensate), records were destroyed (complete), or nothing committed (abandon); `purge_record`'s shared tokens disambiguated by one destruction-safe re-invocation; `retained(retention-obligation)` grounded in the Retention Window record; findings recorded as `dsar.finding_opened` / `dsar.finding_closed` events under a declared service identity. *Over:* a universe the branches could not disposition, a two-state lifecycle, unconditional compensation, categorical token readings, an event the substrate never emits, and a dashboard nothing declared. *Because:* the page's own walkthroughs violated Invariant 2; a retry after a post-commit failure re-ran the fulfillment; the recovery path produced the reverse orphan the safety half forbids; and check 4 failed every conforming implementation.
- **2026-08-27 — Invariant 1 is safety plus liveness, in three arms.** *Chose:* no `dsar.*_fulfilled` event without its response-disclosure and complete disposition set (earned by write order); no unsurfaced orphan; every orphan compensated within a declared window and distinguishable via `cascade_recovery = true`. *Over:* "commits together or not at all" across a write the substrate cannot withdraw. *Because:* the order was right from the first draft and the claim was merely unprovable — the restatement says what the order earns and nothing more.

NOTE: End of Resolve a Person's Data Rights.

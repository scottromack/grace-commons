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

 Its most common uses are GDPR (the EU General Data Protection Regulation) Article 15 access and Article 17 erasure fulfillment, CCPA/CPRA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) consumer access and deletion requests, and HIPAA (the US Health Insurance Portability and Accountability Act) section 164.524 access to a designated record set. Any system that must answer a data subject's access or deletion request *and* make it provable that every record was dispositioned and that legal holds and retention obligations were honored throughout, is a candidate for this composition.

---

## Intent

Every system that holds personal data must, on demand, answer a data subject exercising a statutory right — and the hard part is not the happy path of handing over or deleting data, it is the *conflict* the request surfaces. A right-of-access request (GDPR — the EU General Data Protection Regulation — Article 15) says *show me everything you hold about me*. A right-of-erasure request (GDPR Article 17, the "right to be forgotten") says *delete it*. But the same records are often subject to a **legal hold** that forbids destruction (litigation is anticipated, a regulator is investigating), to a **retention obligation** that mandates keeping them for a statutory period, and to a web of **consent** decisions that determine whether the data could lawfully be processed at all. These claims do not merely coexist; on a single record they actively contradict one another. *Delete this* and *you may not delete this* cannot both be honored. The system must choose, per record, and — this is the regulated bar — the lawfulness of the choice it made must be provable afterward.

This is the friction this composition exists to resolve, and naming it precisely is what keeps the composition honest: **This composition is not a "rights system"; it is a conflict-resolution system over competing truth claims about a record universe.** Four claims collide on the subject's records — *access* (Article 15: show everything), *erasure* (Article 17: remove, or justify non-removal), *legal hold and retention* (via Defensible Retention: you cannot remove this, regardless of the clock), and *consent* (the lawful-basis question: are you allowed to act at all?). The resolution surface is a **per-record disposition** — a single recorded, attributed verdict for every record in the subject's enumerated universe — plus a **no-silent-omission** completeness guarantee that no record escapes the enumeration without a disposition. A DSAR (Data Subject Access Request — the umbrella term for a subject exercising any of these rights) is fulfilled not when data is handed over or deleted, but when *every* in-scope record carries a disposition an auditor can read and defend.

No single constituent resolves the collision. Selective Disclosure records *that* a disclosure occurred — to whom, what scope, under what authority — but it does not enumerate a subject's record universe, does not perform or block erasure, and does not know what a legal hold is. Defensible Retention owns exactly the erasure-versus-preservation gate: its hold-blocks-purge invariant is the structural rule that *delete this* yields to *you may not delete this*, and its Retention Window leg supplies the *kept-for-a-statutory-period* exemption — but Defensible Retention knows nothing of access requests, disclosure accounting, or consent as a lawful basis. Consent owns the grant/revoke/expire lifecycle and the point-in-time `check` that answers *was there a lawful basis?* — but it is, by its own specification, not an enforcement surface and not an orchestrator. The structure that enumerates the universe, resolves each record's competing claims into one disposition, records every response-disclosure, and seals the whole fulfillment as one accountable act belongs to no single constituent. It belongs to the composition, and this composition is that structure.

This is a composition, not a new primitive. Selective Disclosure, Defensible Retention, and Consent are unchanged; this composition is the wiring that makes them coherent as a single rights-fulfillment surface. It introduces emergent actions — [Receive Request], [Fulfill Access Request], [Fulfill Erasure Request], and the read-only [Disposition Report] — that belong to no single constituent and exist only because the three are wired together. The erasure action in particular **wraps Defensible Retention's `purge_record` gate**: the same hold-blocks-purge decision Defensible Retention already makes becomes, at this composition's layer, the mapping from a gate outcome to a recorded per-record disposition (`ok` → erased, `under-legal-hold` → `retained(legal-hold)`, `not-eligible` → `retained(retention-obligation)`), with this composition adding only the consent-basis branch (Article 17(1)(b) — *was consent the only basis, and is it gone?*) and the enumeration-and-completeness structure that makes the answer cover the whole universe rather than one record at a time.

A load-bearing scoping decision follows from the reframe. The composition's **spine is Access (Article 15) and Erasure (Article 17) only** — the two rights whose claims most sharply collide and whose fulfillment most needs the per-record disposition surface. The other rights in the Article 15–20 family (rectification under Article 16, restriction under Article 18, portability under Article 20, objection under Article 21) are lighter variants of the same fulfillment surface or are named composing concepts; modeling each as a first-class lifecycle would inflate the composition without exercising a structurally new claim-collision. They are named in Non-goals, not absorbed.

What the composition is *not*: it is not the identity-verification surface that confirms the requester actually is the subject (or their authorized representative) — that is a Party Identity / Actor Identity composing concept, named not absorbed; it is not the legal adjudicator that decides whether a given Article 17(3) exemption genuinely applies (an Erasure Coordination composing concept, and ultimately counsel's call) — this composition records the asserted disposition and its reason, and routes the legitimacy question to an externally-clearable check; it is not the data-extraction or redaction engine that assembles the access payload (the host's obligation, signalled by the included dispositions); it is not the deletion engine for records outside the library's database (a host obligation named in the completeness boundary); and it is not a statutory-deadline clock that computes or enforces the one-month fulfillment window under Article 12(3) (this composition records `received_at` and `fulfilled_at`, each provable; whether the deadline was met is an externally-clearable or composing concept). Each is named explicitly in Non-goals.

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
Composes 11: The composition MUST NOT own a constituent's records.
Composes 12: The composition MUST read the trail ONLY through the trail read.
Composes 13: The composition MUST select a trail event in the composition's own code.
Composes 14: The composition MUST read a retention ONLY through the retention read.
```

Term composition: this pattern's wiring of [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md) and [Consent](../atoms/consent.md) — the intake, the two fulfillment siblings, the report, the two indexes and the reconciliation.

Term constituents: [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md), [Consent](../atoms/consent.md).

Term transitive pattern: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) or [Audit Trail](./audit-trail.md), reached through Defensible Retention, and [Event Log](../atoms/event-log.md), reached through Audit Trail.

Term audit write: Audit Trail's record_action on the Audit Trail instance Defensible Retention carries.

Term trail: the events of the Audit Trail instance Defensible Retention carries — this composition's own and the substrate's, in one log.

Term recording instant: Event Log's recording instant — the instant the log stamps an event with at its append.

Term trail read: Event Log's read by an open-ended sequence range, on the Event Log instance Audit Trail carries, reached the way Defensible Retention reaches the same log (Defensible Retention Composes 12 through 14).

Term retention read: Retention Window's read on the business retention instance Defensible Retention carries — every retention with the retention's record reference, retention state, retention deadline and, where the retention stands purged, purge instant.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term universe enumeration: the composition-introduced surface that enumerates a subject's in-scope records over the record source registry — the Defensible Retention-managed records being the registered records a source answers a retention id for — each with its record reference, its source and its creation instant — the eventual home of a Completeness Model atom *(forthcoming)*.

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the request index.
Composition state 2: The composition MUST key the request index by request id.
Composition state 3: A request entry MUST carry the subject reference, the right type, the requester, the regulatory reference AND the received instant.
Composition state 4: The composition MUST write a request entry ONLY AFTER the intake event lands.
Composition state 5: The composition MUST NOT change a request entry, the stall mark of Reconciliation 38 excepted.
Composition state 6: The composition MUST store the fulfillment index.
Composition state 7: The composition MUST key the fulfillment index by request id.
Composition state 8: A fulfillment entry MUST carry the right type, the fulfilled instant, the dispositions, the response disclosure id AND the fulfillment event id.
Composition state 9: The composition MUST write a fulfillment entry ONLY AFTER the fulfilled event lands.
Composition state 10: A fulfillment entry MUST carry the dispositions the fulfilled event carries.
Composition state 11: The composition MUST NOT change a fulfillment entry.
Composition state 12: The composition MUST classify a live entry as a derived index, the entry's stall mark excepted.
Composition state 13: The composition MUST rebuild a missing live entry from the entry's event.
Composition state 14: The composition MUST classify an aged entry as extraction-pending against Erasure Tombstone.
Composition state 15: The composition MUST derive a request's state from the request's events, the request entry, the fulfillment index AND the request-scoped disclosures.
Composition state 16: IF a fulfillment entry EXISTS for the request THEN the request's state MUST carry Fulfilled.
Composition state 17: IF an open intent EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 18: The composition MUST NOT store a subject's enumerated universe.
Composition state 19: IF a fulfilled event carrying the request id EXISTS THEN the request's state MUST carry Fulfilled.
Composition state 20: The composition MUST NOT answer not-known BEFORE rebuilding the request index.
Composition state 21: The composition MUST read a fulfilled event carrying no fulfillment entry as a rebuild trigger.
Composition state 22: IF the state read fails THEN the action MUST answer state-unavailable.
Deleted: Composition state 23. Execution Contract Read 3 owns it.
Composition state 24: IF an unbound disclosure EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 25: An index write that fails MUST NOT change an action's answer.
Composition state 26: IF a stall mark EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 27: The composition MUST classify a stall mark as extraction-pending against Outbox.
Composition state 28: The composition MUST NOT clear a stall mark.
```

Term request id: the opaque id the host injects at [Receive Request]'s seam — never reused.

Term request index: the composition's map from a request id to the request's intake — `request_to_subject` in an implementation.

Term request entry: one request id's subject reference, right type, requester, regulatory reference and received instant — and the stall mark, where a run wrote one.

Term fulfillment index: the composition's map from a request id to the request's fulfillment — `request_to_fulfillment` in an implementation; the queryable mirror of the sealed fulfilled event.

Term fulfillment entry: one request id's right type, fulfilled instant, [Dispositions], response disclosure id and fulfillment event id.

Term live entry: an index entry whose event's payload the audit horizon has not reached.

Term aged entry: an index entry whose event's payload the audit horizon has destroyed.

Term request's events: the composition's events carrying one request id, selected over the trail read.

Term unbound disclosure: a request-scoped disclosure carrying the request id of a request that carries no fulfilled event and no fulfillment entry.

Term stall mark: a request entry's record of the invocation id of an intent carrying a planned record that a run read as overdue (Reconciliation 38), on a request that carries no fulfilled event and no fulfillment entry. A run writes it, to the one value, each time it reads the intent as overdue, and it does not lapse as the intent ages: past the audit horizon it is the one carrier of a destruction that was planned and never sealed.

Term state read: the reads a fulfillment or [Disposition Report] derives the request's state from — the request's events, the request entry, the disclosure read of the request's subject reference, and the rebuild of a missing index entry. The state read fails where one of them fails and neither a fulfillment entry nor a fulfilled event already read settles the state as Fulfilled.

Term intake event: the dsar.received event.

Term intent: the access intent or the erasure intent.

Term aged event: an event whose age — the injected now less the event's recording instant — is no less than the audit horizon less twice the clock offset allowance — an event the audit instance may already have destroyed, or a later neighbour of it. Two allowances, because the substrate places an event's retention on one clock after the log stamped the event on another, and judges the purge on the first against a now this composition reads on a third. No clock decides the edge alone: an intent short of the edge whose closing record the audit instance has already destroyed carries a stand-in and is no open intent (Term stand-in).

Term destroyed event: an event whose payload the audit instance has destroyed. The log still answers the event's sequence number and recording instant, as Defensible Retention reads on the same log.

Term stand-in: a destroyed event that may be the missing half of an intent and its closing record. For an intent that carries no closing record it is a destroyed event later in the log. For a closing record that carries no intent it is a destroyed event earlier in the log whose recording instant stands within the fulfillment completion bound, taken with the clock offset allowance, of the record's own — an invocation writes its closing record within the bound or yields — and, where the service identity attested the closing record, any destroyed event earlier in the log, since a leg closes an intent of any age short of the horizon. The request id and the invocation id went with the payload, so the trail cannot say whose record it was; a pairing with a stand-in reads unknown and never open, orphaned or failed.

Term quiescence: the state in which no fulfillment holds a request section, no open intent stands younger than the compensation window, and the reconciliation has no open intent left to work. An invariant stated at quiescence is owed by then and not at every instant before it.

Term open intent: an intent, no aged event, carrying no stand-in, whose invocation id no abandonment carries, of a request carrying no fulfilled event and no fulfillment entry.

Term fulfilled event: the dsar.access_fulfilled or dsar.erasure_fulfilled event.

Term abandonment: the dsar.intent_abandoned event — carrying the invocation id of the intent it closes, returning the request to Received.

Term request state: Received | Committing | Fulfilled — derived, never stored: Fulfilled where Composition state 16 or Composition state 19 holds, Committing where Composition state 17, Composition state 24 or Composition state 26 holds, and Received everywhere else. An open intent, an unbound disclosure and a stall mark are each defined over a request carrying no fulfilled event and no fulfillment entry, so no request reads two.

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the record source registry.
Capability requirement 2: EVERY registered source MUST expose a subject-scoped enumeration answering the record reference, the source, the creation instant AND the route PER record.
Capability requirement 3: EVERY registered source MUST expose the declared basis PER record.
Capability requirement 4: EVERY registered source MUST expose the host determinations PER record.
Capability requirement 5: EVERY route MUST carry EXACTLY ONE OF a retention id, the host delete.
Capability requirement 6: The host delete MUST verify the presented credential at the host's own boundary.
Capability requirement 7: The universe enumeration MUST NOT enumerate accounting records.
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
Capability requirement 49: A deployment MUST set an audit retention policy that answers one policy for EVERY event of the audit instance (Defensible Retention Capability requirement 57).
Deleted: Capability requirement 50. Execution Contract Database 3 and Execution Contract Database 4 own it.
Capability requirement 51: EVERY registered source MUST answer EVERY source text within the text cap.
Capability requirement 52: A deployment MUST NOT serve two instances of the composition by one Defensible Retention instance.
Capability requirement 53: A deployment MUST NOT serve two instances of the composition by one Selective Disclosure instance.
Capability requirement 54: A deployment MUST NOT change the audit retention policy for the life of the instance.
Capability requirement 55: The host MUST inject now at the seam once PER run.
Capability requirement 56: A deployment MUST declare the enumeration bound.
Capability requirement 57: A deployment MUST NOT admit another writer of a composition action reference on the audit instance.
Capability requirement 58: A deployment MUST NOT provision the service identity for a use outside the composition.
Capability requirement 59: A deployment MUST declare the id cap.
Capability requirement 60: A deployment MUST NOT place a retention bound on a record of the Selective Disclosure instance.
Capability requirement 61: A deployment MUST NOT place a retention bound on a record of the Consent instance.
Capability requirement 62: A deployment MUST answer EVERY alert WITHIN the compensation window of the alert.
Capability requirement 63: The alerting surface MUST retain EVERY alert AND the id the alert names for the audit horizon.
Capability requirement 64: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Read 1 through 3.
```

Term record source registry: the deployment-declared list of the business-record sources over which the no-silent-omission guarantee holds, with the per-record surfaces each exposes.

Term creation instant: the instant a record became one of the subject's in its source — its creation there, or a later linking of it to the subject — stamped by the source's own clock.

Term declared basis: the lawful ground a registered record names for its processing — consent carrying a purpose, a non-consent ground such as legal-obligation, contract or vital-interests, or none.

Term host determinations: the host's per-record Article 15(4) third-party-confidentiality and legal-exemption determinations, consumed by the access dispositions.

Term host delete: the registry-declared delete surface of a host-managed record — `delete(record_ref, actor_ref, credential)` answering deleted carrying the attestation reference, refusing invalid-credential, not-known, retained carrying the basis, or delete-failed.

Term route: how a registered record is erased, answered by the record's source in the enumeration itself — a retention id, the gated path, or the host delete. A source that answers a record with no route has failed to enumerate (Action wiring 12).

Term host-managed record: a registered record whose route carries the host delete — erased through the host delete, never through Defensible Retention's gate.

Term accounting records: the Selective Disclosure records or the Consent records — the composition's accounting of the subject, read as response content and never enumerated.

Term audit horizon: the horizon of the one policy the audit retention policy answers for every event of the audit instance (Capability requirement 49) — the Audit Trail instance Defensible Retention carries.

Term hold guarantee: Defensible Retention Invariant 1 read over the records this composition's fulfillments purge — no record an active hold covers at the gate is destroyed through a fulfillment.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` in configuration.

Term compensation window: the duration within which the reconciliation is to close an open intent. An intent the window did not close is alerted on by the alert bound.

Term fulfillment completion bound: the longest a fulfillment may run from its intent's recording instant to its fulfilled event — the reconciliation's lower edge. The intent lands under the grant, and the grant's term does not exceed the bound (Capability requirement 34).

Term reconciliation cadence: the interval from the start of one run of the reconciliation to the start of the next, beside the run at every process start. A run still working its legs holds back no later run: two runs may work at once, and the request section keeps them off one request.

Term clock offset allowance: the deployment's declared envelope between two clocks' readings of one moment (Execution Contract Logic confinement 7) — the value Defensible Retention reads under the same name — allowed here wherever a reading of now is set against a registered source's creation instant, a constituent's stamp or another invocation's reading of now.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the request id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam — once per invocation, once per run and once per leg. Young, overdue and aged are each judged on the now of the invocation, the run or the leg that makes the read.

Term invocation id: the id the host injects at the seam for one state-changing invocation — a [Receive Request] call or a fulfillment. Every record the invocation writes carries the id, and a record the reconciliation writes carries the id of the intent the record closes.

Term request section: the [Lease](../atoms/lease.md) this composition takes on a request id — the key is the request id under this instance's own namespace on the host (Concurrency 5) and the holder value is minted fresh for each take — under which one fulfillment or one leg over the request runs, from its first read of the request's state to its last call.

Term call pause bound: this composition's value of Lease's call pause bound — the longest time from the decision to issue one call to the moment the call has taken effect or failed. It bounds a lease call and the disclosure write, and never a whole audit write or a whole planned call (Lease Capability requirement 7).

Term section term: the duration every take of the request section asks for (Lease Composition note 5d).

Term section read bound: section_read_bound — the deployment's declared longest time a fulfillment or a leg spends, from a take's answer, on the reads it makes before its first write: the state read, the enumeration and the disposition reads, the retention read among them. The trail and the retention records grow, so holding the bound is the deployment's.

Term section work bound: `(((section_read_bound + audit_write_latency) + (3 * call_pause_bound)) + plan_floor)` — the take's own answer, the reads, the intent with its own reading, and the first planned call's reading, with the plan floor left after it, so a term that exceeds the bound admits the intent, one planned call, the disclosure write and the fulfilled event. A further planned call the grant no longer admits leaves its record unsettled, so no fulfillment's work outruns the grant.

Term planned call latency: the deployment's disclosed longest time from issuing a planned call to the landing of the call's last write, an abandoned call's included, and to the answer of the retention read a not-known obliges. The unit's bound of a planned call under the request section (Lease Composition note 8a); a planned call that has not answered within it answers no answer.

Term record start floor: `(audit_write_latency + (2 * call_pause_bound))` — the remaining term an audit write needs to land inside the grant, the audit write latency being the unit's bound of an audit write (Lease Composition note 8a). A floor admits a call whose reading of Lease's remaining answers a remaining term exceeding the floor (Lease Sizing 5).

Term bind floor: `(record_start_floor + (3 * call_pause_bound))` — the remaining term the disclosure write and the fulfilled event after it need: the write within one pause of its reading, landing within another, and the event's own reading a third. The floor stands above the write margin, so a reading it admits is a live reading (Lease Sizing 2).

Term plan floor: `((planned_call_latency + (3 * call_pause_bound)) + bind_floor)` — the remaining term below which a fulfillment makes no further planned call, so that the bind still has the bind floor once the planned call has landed, the next plan reading has refused, and the bind's own reading has answered.

Term lease reading: live | expired — what a reading of Lease's remaining says of the grant, as Lease declares the two (Lease Sizing 2, Lease Sizing 2a, Lease Sizing 7).

Term closure floor: `(((((fulfillment_completion_bound + (2 * clock_offset_allowance)) + reconciliation_cadence) + enumeration_bound) + call_pause_bound) + section_term)` — the longest interval in which a run that takes the request section closes an open intent: the intent's age at the lower edge, read at a seam that may stand an allowance either side of the log's; one cadence to the next run; that run's enumeration and its alerts; the leg's take; and the leg's own grant. The floor is the first leg's: each leg a run works ahead of an intent's own adds a grant, which no floor counts, so a backlog is alerted on before it is closed.

Term alert floor: `((((2 * compensation_window) + (2 * reconciliation_cadence)) + (2 * enumeration_bound)) + (5 * clock_offset_allowance))` — the age by which a run has alerted on an overdue intent, the deployment has had a window to answer the alert, and the run that follows the answer has read the intent, while the intent is still no aged event. The terms in order: the window; a cadence to the run that reads the intent overdue, and that run's enumeration; a second window for the alert to be answered in; a second cadence and a second enumeration for the run that follows the answer; and five allowances — two where a run reads overdue against the log's stamp, the allowance in the test and the offset between the run's seam and the log's, and three where a later reading finds the intent aged against the log's stamp, the two the aged test gives up and the offset between that seam and the log's. The floor promises that much and nothing of the closing: a run works its legs one grant after another, and an intent a leg reaches only once it has aged is left as Reconciliation 4 leaves it — its request still Committing where the intent planned a destruction or its fulfillment wrote a disclosure (Composition state 24 and 26). A deployment that means every intent to close sets the horizon above the floor by the grants its backlog needs. The second window is the deployment's to use (Capability requirement 62).

Term enumeration bound: enumeration_bound — the deployment's declared longest time from a run's start to the end of the run's enumeration of the trail, of its alerts on the overdue intents and of the index entries and stall marks it writes (Reconciliation 33, Reconciliation 36, Reconciliation 38). The trail grows, so holding the bound is the deployment's. A run that dies or overruns before its enumeration ends is alerted on by the scheduler (Reconciliation 40); the alert bound, the entry bound and the alert floor count the runs that end theirs, and no lost run.

Term alert bound: `(((compensation_window + reconciliation_cadence) + enumeration_bound) + (3 * clock_offset_allowance))` — the age, counted from the intent's recording instant, by which an intent no record closed has been alerted on, as an auditor reads it: the window; a cadence to the run that reads the intent overdue, and that run's enumeration; and three allowances, the one in the overdue test, the offset between that run's seam and the log's, and the offset between the auditor's seam and the log's.

Term entry bound: `((reconciliation_cadence + enumeration_bound) + clock_offset_allowance)` — the age by which a run has read a fulfilled event carrying no fulfillment entry and written the entry, as an auditor reads it: a cadence to the next run, that run's enumeration with the entry written ahead of its first take (Reconciliation 36), and the offset between the auditor's seam and the log's.

Term source text: a string a registered source or the host delete supplies and a reason carries whole — a purpose, a non-consent ground, a determination's reference, a host's basis or an attestation reference.

Term text cap: text_cap — the deployment's declared maximum size of one source text.

Term id cap: id_cap — the deployment's declared longest id a record carries: a request id, an invocation id, a retention id, a hold id, a disclosure id or an event id.

Term reason bound: the size of the largest reason a disposition can carry — its ids at the id cap, its answers and its instants at their longest, EVERY source text at the text cap, and the hold ids at Defensible Retention's hold ids cap. No reason is truncated.

Term alerting surface: the deployment's surface on which the composition and the deployment alert. An alert names what it rests on — an intent's invocation id, an event's id, a request id or a run — and the surface keeps it for the audit horizon (Capability requirement 63), so an auditor reads an alert as a record, with its instant. An alert is answered when what it names no longer holds: the intent closed, the entry or the mark written, a later run's enumeration ended.

Term scheduler: the deployment's facility that runs the reconciliation at every process start and at the reconciliation cadence.

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
Primitive policy 14: A fulfillment Primitive policy 13 refuses MUST NOT record an event.
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

Term largest record: the larger of a fulfillment's intent and the compensating fulfilled event the reconciliation would record for the fulfillment, each sized whole — every field the record carries, every id at the id cap — with every disposition's reason at the reason bound.

### Audit arm

```
Deleted: Audit arm 1. Execution Contract Database 1 owns it.
Audit arm 2: The composition MUST read an invalid-request carrying step-4 as a landed record.
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Audit arm 21 owns it.
Deleted: Audit arm 5. Execution Contract Database 1 owns it.
Audit arm 6: IF Audit Trail answers invalid-credential at a pre-effect record THEN the action MUST answer invalid-credential.
Audit arm 7: IF Audit Trail answers recording-failure carrying a step below step-4 OR no answer at a pre-effect record THEN the action MUST answer recording-failure carrying intent.
Deleted: Audit arm 8. Audit arm 2 owns it.
Deleted: Audit arm 9. Audit arm 21 owns it.
Deleted: Audit arm 10. Action wiring 29 owns it.
Deleted: Audit arm 11. Audit arm 21 owns it.
Deleted: Audit arm 12. Execution Contract Database 1 owns it.
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
Action wiring 4: IF the rebuild of Composition state 20 answers no request entry for the request id THEN a fulfillment MUST answer not-known.
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
Action wiring 34: IF the rebuild of Composition state 20 answers no request entry for the request id THEN [Disposition Report] MUST answer not-known.
Action wiring 35: IF the state read answers the request's state THEN [Disposition Report] MUST answer the report.
Action wiring 36: [Disposition Report] MUST NOT record an audit event.
Action wiring 37: IF the disclosure read OR Consent's read fails for an enumerated access THEN [Fulfill Access Request] MUST answer incomplete-enumeration.
Action wiring 38: IF the retention read of Action wiring 41 fails THEN [Fulfill Erasure Request] MUST answer incomplete-enumeration.
Action wiring 39: A fulfillment MUST NOT record an abandonment over a disclosure write that answered no answer.
Action wiring 40: An intended erasure MUST make the planned calls in the purge plan's order AND the host delete plan's order.
Action wiring 41: An enumerated erasure MUST read the retention read.
Action wiring 42: IF a planned purge answers not-known THEN the fulfillment MUST read the retention read.
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

Term purge plan: the confirmed retention id and record reference pairs bound for Defensible Retention's purge, ordered by record reference, rising (Execution Contract Logic confinement 10) — the order the calls are made in.

Term host delete plan: the record references bound for the host delete, ordered by record reference, rising (Execution Contract Logic confinement 10) — the order the calls are made in, after the purge plan's.

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

Term unsealed fulfillment: a fulfillment whose intent landed and that returns with no landed fulfilled event — refused at its disclosure write, yielded, or owed its fulfilled event.

### Wiring decision

```
Wiring decision 1: A fulfillment MUST disposition EVERY record of the subject's enumerated universe.
Wiring decision 2: The composition MUST bind the dispositions, the response disclosure AND the fulfilled event as one fulfillment.
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Wiring decision 4: The composition MUST read an erasure's preservation dispositions off Defensible Retention's purge.
Wiring decision 5: The composition MUST NOT evaluate a hold.
```

WHY:
*Principle.* A rights response an auditor can trust needs two facts inseparable: that *every* record in the subject's universe was accounted for, none silently dropped, and that the account is itself immutable, attributed and tamper-evident.

*Likely objection.* Why not let each constituent answer for its own records and union the answers?

*Mechanism.* No constituent enumerates the *universe*, and a union of per-constituent answers has no completeness guarantee — a record in a host database no constituent governs is simply absent, and absence is invisible to a reader who sees only what *was* returned. The composition computes the universe once over the declared registry, dispositions every record (Wiring decision 1), and binds the set, the response disclosure and the sealed event as one fulfillment (Wiring decision 2); the one reachable gap, a response disclosure with no sealed event behind it, is surfaced and compensated rather than claimed away (Invariant 1).

*Result.* An auditor reads one fulfillment and sees a verdict for every record the declared universe contains — no-silent-omission — non-repudiable and tamper-evident, which no constituent provides alone.

*Principle.* *Delete this* and *you may not delete this* cannot both hold; the resolution must be structural and records-checkable, not a runtime check a well-meaning operator can talk past.

*Likely objection.* Doesn't a rights-fulfillment system need its own hold and retention logic?

*Mechanism.* No — re-deriving hold checking would duplicate exactly the gate Defensible Retention already owns and proves (its Invariant 1), and its purge is irreversible and self-audits each destruction. The composition maps the gate's answers onto dispositions (Wiring decision 4 and 5; Disposition 20 through 46), inheriting its structural guarantee and its retention exemption for free, and adds the one concept the substrate does not carry — the Article 17(1)(b) question of whether another lawful basis means erasure was never due, read-only and ahead of any purge (Disposition 7 through 12).

*Result.* Every preservation disposition traces to a records-checkable Defensible Retention outcome, and the composition stays a thin conflict-resolution-and-accounting layer over a proven substrate rather than a re-implementation of it.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a young intent.
Reconciliation 4: The reconciliation MUST NOT examine an aged event, the index write of Reconciliation 25 excepted.
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
Reconciliation 18: IF the reconciliation records a compensating fulfilled event THEN the reconciliation MUST write the fulfillment entry ONLY AFTER the compensating fulfilled event lands.
Deleted: Reconciliation 19. Defensible Retention Reconciliation 11 owns it.
Deleted: Reconciliation 20. Defensible Retention Action wiring 70 owns it.
Deleted: Reconciliation 21. Defensible Retention Reconciliation 11 owns it.
Reconciliation 22: The reconciliation MUST alert on an overdue intent.
Reconciliation 23: The reconciliation MUST read the request's events AND the disclosure read of the intent's subject reference again under the request section.
Reconciliation 24: IF a purge plan pair's retention reading EQUALS purged THEN a compensating fulfilled event MUST carry the pair's record erased carrying the retention id, the purge instant AND the intent's reason.
Reconciliation 25: The reconciliation MUST write the index entry of EVERY intake event AND EVERY fulfilled event carrying none.
Reconciliation 26: IF Lease's try_take answers held OR no answer THEN the reconciliation MUST leave the open intent to the next run.
Reconciliation 27: IF a read a leg makes fails THEN the reconciliation MUST leave the open intent to the next run.
Reconciliation 28: IF the request section admits no call a leg owes OR a call a leg issues refuses OR a call a leg issues answers no answer THEN the reconciliation MUST leave the leg's remaining work to the next run.
Reconciliation 29: The reconciliation MUST NOT call the disclosure write BEFORE the reconciliation's recovery intent lands.
Reconciliation 30: The reconciliation MUST take the readings of Reconciliation 9 under the request section.
Reconciliation 31: A compensating fulfilled event MUST carry the paired disclosure's id as the response disclosure id, the leg's now as the fulfilled instant AND the intent's intended instant as the enumeration instant.
Reconciliation 32: A compensating access fulfilled event MUST carry the recipients read AND the consents read the access intent carries.
Reconciliation 33: A run MUST NOT take a request section BEFORE alerting on EVERY overdue intent the run's enumeration answers.
Reconciliation 34: IF the trail read a run enumerates the open intents from fails THEN the reconciliation MUST alert.
Reconciliation 35: IF the index write of Reconciliation 25 fails THEN the reconciliation MUST alert.
Reconciliation 36: A run MUST NOT take a request section BEFORE writing the index entry of EVERY intake event AND EVERY fulfilled event the run's enumeration answers carrying none, a write Reconciliation 35 alerts on excepted.
Reconciliation 37: The scheduler MUST NOT hold the start of a run for a run still working.
Reconciliation 38: A run MUST NOT take a request section BEFORE writing the stall mark of EVERY overdue intent carrying a planned record the run's enumeration answers, a write Reconciliation 39 alerts on excepted.
Reconciliation 39: IF the write of a stall mark fails THEN the reconciliation MUST alert.
Reconciliation 40: IF a run fails to end the run's enumeration WITHIN the enumeration bound THEN the scheduler MUST alert.
Reconciliation 41: A run MUST record the end of the run's enumeration on the alerting surface.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a compensated, completed or abandoned fulfillment — an auditor awaits within the compensation window, and whose alert on what the window did not close an auditor awaits by the alert bound.

Term leg: the reconciliation's handling of one open intent, under one grant of the request section.

Term young intent: an open intent whose recording instant stands within the fulfillment completion bound, taken with the clock offset allowance, of the injected now.

Term overdue intent: an open intent whose recording instant stands older than the compensation window, taken with the clock offset allowance, of the injected now — an intent the window did not close.

Term request-scoped disclosure: a Selective Disclosure record whose scope is a request scope — selected in the composition's own code, byte-exact on the scope, from the disclosure read of the subject reference, since Selective Disclosure offers no filter by scope.

Term recovery intent: the dsar.recovery_intended event — the reconciliation's intent record, naming the request, the intent it resolves and the case. An abandonment takes none.

Term case: compensate | complete — the closure Reconciliation 12 or Reconciliation 13 makes. The abandonment of Reconciliation 15 takes no recovery intent and so no case.

Term compensating fulfilled event: a fulfilled event the reconciliation records, carrying the compensation flag.

Term destruction record: Defensible Retention's record_purged outcome, a recovered one included.

Term destroyed planned record: a purge plan pair whose retention reading EQUALS purged. A host delete plan record is never one: no declared surface says a host-managed record is gone, so a leg seals it unsettled.

Term binding orphan: a request-scoped disclosure that no fulfilled event's response disclosure id names, written under an intent that is no aged event and carries no stand-in — this composition's own orphan.

### Disposition

```
Disposition 1: EVERY enumerated record MUST carry EXACTLY ONE disposition.
Disposition 2: A disposition MUST carry the record reference, the source, the verdict AND the reason.
Disposition 3: IF a record's determination reading EQUALS third-party-confidentiality THEN the record MUST carry withheld carrying third-party-confidentiality AND the determination's reference.
Disposition 4: IF a record's determination reading EQUALS legal-exemption THEN the record MUST carry withheld carrying legal-exemption AND the determination's reference.
Disposition 5: IF a record's determination reading EQUALS failed THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 6: IF a record's determination reading EQUALS no-bar THEN the record MUST carry included carrying no-bar.
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
Disposition 33: IF the host delete answers retained AND the host's basis DOES NOT EXCEED the text cap THEN the record MUST carry retained carrying other-lawful-basis AND the host's basis.
Disposition 34: IF the host delete answers not-known THEN the record MUST carry anomaly carrying host-record-not-found.
Disposition 35: IF the host delete answers delete-failed OR invalid-credential THEN the record MUST carry anomaly carrying unsettled.
Disposition 36: IF the host delete answers outside the host delete's contract THEN the record MUST carry anomaly carrying unsettled.
Deleted: Disposition 37. Disposition 47 owns it.
Disposition 38: The composition MUST read a fulfillment carrying an anomaly as Fulfilled.
Disposition 39: IF an erasure-due record's retention reading EQUALS purged THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 40: IF a record's basis reading EQUALS unread THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 41: IF a purge's first answer IS IN the retry answers AND the plan floor admits a further planned call THEN the composition MUST re-invoke the purge once, ahead of the next planned call.
Disposition 42: IF a planned record's purge reading EQUALS unsettled THEN the record MUST carry anomaly carrying unsettled.
Disposition 43: IF a planned record's purge reading EQUALS gone THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 44: IF a planned record's purge reading EQUALS unknown THEN the record MUST carry anomaly carrying unknown-retention.
Disposition 45: IF the plan floor admits no further planned call THEN EVERY planned record no planned call settled MUST carry anomaly carrying unsettled.
Disposition 46: A disposition a planned call's answer settles MUST carry the answer in the reason.
Disposition 47: The deployment MUST alert on a fulfilled event carrying an anomaly.
Disposition 48: A deployment MUST settle EVERY record carrying unsettled in a fulfilled event.
```

Term disposition: a record's verdict — [Included] or [Withheld] for access; [Erased], [Retained] or [Anomaly] for erasure, [Anomaly] for access too.

Term verdict: included | withheld | erased | retained | anomaly.

Term withdrawn answer: revoked | expired — Article 17(1)(b)'s consent withdrawn, or lapsed.

Term determination reading: failed | third-party-confidentiality | legal-exemption | no-bar — what the host determinations say of a record of an access, exactly one of the four and the first that holds in this order: failed where the surface fails for the record or answers a source text over the text cap; third-party-confidentiality where the determinations name that bar, alone or beside a legal exemption; legal-exemption where the determinations name a legal exemption and no third-party confidentiality; no-bar everywhere else.

Term basis reading: unread | ground | granted | not-known | withdrawn | none — what a record's declared basis and Consent's check say of a record of an erasure, exactly one of the six and the first that holds in this order: unread where the declared basis fails or carries a source text over the text cap, or names consent and Consent's check answers no answer; ground where the declared basis names a non-consent ground; granted, not-known or withdrawn where the declared basis names consent and Consent's check answers granted, not-known or a withdrawn answer; none where the record declares no basis.

Term erasure-due record: an enumerated record of an erasure whose basis reading EQUALS withdrawn or none — a record no basis preserves and no failed read holds back.

Term retention reading: unread | clear | absent | mis-paired | purged | retained — what the retention read says of a registered record and the record's route, exactly one of the six and the first that holds in this order: unread where the read gave no answer; for a host-managed record, mis-paired where the read answers a retention over the record reference, and clear where the read answers none; for a record whose route carries a retention id, absent where the read answers no retention carrying the id; mis-paired where the read pairs the id with another record reference; purged where the record stands as a destroyed record in Defensible Retention's own sense — the read answers a purged retention over the record reference, the named retention or a sibling; and retained everywhere else. An erased disposition sealed on a purged reading carries the retention id and the purge instant of the retention the reading rests on — the named retention's where the database answers it purged, and otherwise those of the purged sibling whose retention id stands lowest, bytewise; the substrate's destruction record of the record names that id among its purged retention ids, marked purged or pending.

Term settled record: a record Disposition 7, 10, 11, 14, 15, 39 or 40 dispositions before any planned call — every record of an erasure that Disposition 17 and Disposition 18 add to no plan.

Term planned: the provisional marker of a record in the purge plan or the host delete plan, settled by the planned call's answer.

Term retry answers: section-unavailable | hold-check-unavailable | storage-failure | recording-failure carrying intent | recording-failure carrying gate — the purge answers under which the call reports no destruction and a later call can answer otherwise. The intent and gate positions are Defensible Retention's own, of its purge's records, and not this composition's position.

Term unsettling answers: the retry answers | invalid-credential | invalid-request | no answer — the purge answers that leave a record's fate unsaid.

Term purge's first answer: the answer of the one call Action wiring 25 makes for a purge plan pair.

Term purge's last answer: the re-invoked purge's answer where the composition re-invoked the purge, and the purge's first answer everywhere else.

Term purge reading: destroyed | gone | unsettled | held | obliged | unknown — what the answers of a purge plan pair's calls say of the pair's record, exactly one of the six and the first that holds in this order: destroyed where the last answer EQUALS ok or recording-failure carrying outcome; gone where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS purged; unsettled where the first answer or the last EQUALS storage-failure or no answer, where the last answer is any other unsettling answer, or where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS unread; held where the last answer EQUALS under-legal-hold; obliged where the last answer EQUALS not-eligible or under-active-retention; unknown everywhere else — a not-known the database does not bear out. Every answer of Defensible Retention's purge falls under one of the six, so Disposition 20 through 22 and 42 through 44 settle a called record once.

Term outside the host delete's contract: said of a host delete that answers no answer, an answer that is no arm of the host delete's contract, or an arm carrying a source text over the text cap.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Binding bijection.**
  ```
  Invariant 1.1: A fulfilled event MUST NOT exist without the fulfillment's response disclosure AND complete dispositions.
  Invariant 1.2: EVERY Fulfilled request MUST carry EXACTLY ONE fulfilled event, a request whose fulfilled event stands as an aged event excepted.
  Invariant 1.3: EVERY fulfilled event MUST name EXACTLY ONE Fulfilled request.
  Invariant 1.4: EVERY binding orphan MUST carry an open intent under the orphan's request id.
  Invariant 1.5: EVERY intent outside the aged events MUST carry EXACTLY ONE closing record at quiescence, an intent carrying a stand-in excepted.
  Invariant 1.6: EVERY fulfilled event landed through compensation MUST carry the compensation flag.
  ```
- **Invariant 2 — No-silent-omission.**
  ```
  Invariant 2.1: EVERY Fulfilled request's dispositions MUST carry EXACTLY ONE disposition PER record of the enumerated universe.
  Invariant 2.2: A fulfillment whose enumeration failed MUST NOT produce a fulfilled event.
  ```
- **Invariant 3 — Erasure validity.**
  ```
  Invariant 3.1: A disposition MUST carry erased ONLY IF destruction evidence EXISTS for the disposition's record.
  Invariant 3.2: The composition MUST NOT call the host delete for a record whose retention reading DOES NOT EQUAL clear.
  ```
  Term destruction evidence: for a record whose route carries a retention id, a purge of the record's retention that answered ok or recording-failure carrying outcome, or a retention reading that EQUALS purged; for a host-managed record, a host delete that answered deleted.

- **Invariant 4 — Disposition groundedness.**
  ```
  Invariant 4.1: EVERY disposition's reason MUST name the authority the disposition rests on.
  ```
- **Invariant 5 — Every response disclosure recorded.**
  ```
  Invariant 5.1: EVERY Fulfilled request MUST carry EXACTLY ONE response disclosure.
  ```
- **Invariant 6 — Fulfillment terminality.**
  ```
  Invariant 6.1: A Fulfilled request MUST NOT leave Fulfilled.
  Invariant 6.2: A fulfillment of a Fulfilled request MUST NOT record an event.
  ```
- **Invariant 7 — Consent non-mutation.**
  ```
  Invariant 7.1: The composition MUST NOT call a Consent write.
  Invariant 7.2: The composition MUST call Consent ONLY through check AND read.
  ```
- **Invariant 8 — Authentication precedes destruction, disclosure and commitment.**
  ```
  Invariant 8.1: The composition MUST NOT call the disclosure write BEFORE Audit Trail validates the caller's credential at the fulfillment's intent.
  Invariant 8.2: The composition MUST NOT call a destroying surface BEFORE Audit Trail validates the caller's credential at the erasure intent.
  Deleted: Invariant 9. Composes 6 owns it.
  ```

The binding and no-silent-omission give *accountable completeness*; erasure validity and groundedness give *defensible resolution*; the recorded response makes the fulfillment itself an accountable disclosure; terminality and consent non-mutation close the lifecycle and hold the oracle boundary; authentication before the act makes the attribution exact.

---

## Examples

### Walkthrough — GDPR Article 15 access request, end to end

A SaaS (Software-as-a-Service) company deploys this composition over its customer data. Its `record_source_registry` names two subject-scoped business sources: the CRM (Customer Relationship Management) records and the support-ticket records; the Selective Disclosure and Consent records are read as response content, not enumerated as universe.

1. **Intake.** A user submits an access request through the privacy portal. The DSAR officer calls `receive_request(subject_ref = "user-5521", right_type = "access", requester = "user-5521 (verified via privacy portal)", regulatory_reference = "GDPR Article 15", actor_ref = "dsr_officer_k", credential = <cred>)` → `{request_id = "dsar-3001", received_at = "2026-06-08T09:00:00Z"}`. The substrate Audit Trail records `dsar.received`; the request is **Received**.

2. **Fulfillment.** The officer calls `fulfill_access_request("dsar-3001", "dsr_officer_k", <cred>)`. The composition:
  - **Enumerates** `user-5521`'s in-scope universe over the registry → five records: `r1` (profile, CRM), `r2` (an open support ticket), `r3` (a support ticket that quotes a *second* customer's account details), `r4` (a billing dispute record flagged by the host as attorney-client privileged), `r5` (the marketing-preferences record in the CRM). Both sources enumerate successfully — no [Incomplete Enumeration]. The recipients limb is read from the Selective Disclosure records (two prior disclosures) and the consent-history limb from the Consent records, each bound into the sealed event as the ids read.
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

3. **The outcome is provably defensible.** `disposition_report("dsar-4002")` shows all four records dispositioned (Invariant 2): one erased, three retained with three *different* reasons, each traceable (Invariant 4) — `r2` and `r3` to their Defensible Retention `purge_record` outcomes, `r4` to the host-declared AML basis, `r1`'s erasure to a `record_purged` event whose `hold_check_result: empty` proves the gate passed. No held or retention-bound record was erased (Invariant 3). The customer is told, in the response disclosure, exactly what was deleted and what was kept and why.

### Rejection path — re-fulfillment, wrong right type, incomplete enumeration

- **Already fulfilled (terminal).** A retry: `fulfill_erasure_request("dsar-4002", …)` → `rejected(already-fulfilled)`. No second purge, no second disclosure, no second event — `r1` is not erased twice (it is already gone); the single fulfillment from the first call stands (Invariant 6).
- **Wrong right type.** For a *Received, not-yet-fulfilled* erasure request — say `dsar-4003`, intake recorded but no fulfillment yet — `fulfill_access_request("dsar-4003", …)` → `rejected(wrong-right-type)`; the access sibling refuses to fulfill an erasure request. Nothing is recorded. (Against an *already-fulfilled* request the state check answers [Already Fulfilled] *before* the right type is read (Action wiring 7) — terminality dominates wrong-right-type — so the wrong-right-type path is exercised only by a still-Received request.)
- **Incomplete enumeration (the no-silent-omission guard).** During an access fulfillment, one registered source — the support-ticket records — is unreachable. The enumeration cannot be completed over the declared universe → `rejected(incomplete-enumeration)`. **No disposition is recorded, no response-disclosure is written, the request stays Received.** A partial universe is never fulfilled as if whole — the exact silent omission the composition forbids. The officer retries once the database recovers.

### Rejection path — erasure write fails after the purges commit (the orphan)

An erasure fulfillment purges `r1` (`ok`, erased), records its response disclosure `disc-9002`, and then the `dsar.erasure_fulfilled` audit write answers `recording-failure(step-3)` — the append did not answer. The composition answers `recording-failure(outcome)` and does not write the event again: an append that did not answer may still land, and a second write would seal the request twice. The result is an **orphan**: `r1` is irreversibly erased (its Defensible Retention `record_purged` event exists) and `disc-9002` is permanent, but no `dsar.erasure_fulfilled` event is known to exist. The erasure intent is still open, so `disposition_report("dsar-4002")` reads **Committing** and a retried [Fulfill Erasure Request] answers compensation-pending.

The reconciliation closes it. Once the intent is older than the fulfillment completion bound and the allowance, a run takes the request section on `dsar-4002` and reads the request's events again. If the first append landed after all, there is a fulfilled event carrying the intent's invocation id and nothing is open. If it did not, the run finds `disc-9002` under the request's scope, records `dsar.recovery_intended` (case compensate), and records the fulfilled event under the service identity with `cascade_recovery = true`, the operator named, and the intent's dispositions corrected from the records: `ret-r1` reads purged, so `r1` is erased on the database's own purge instant; `ret-r2` and `ret-r3` read retained, and the answers the dead write path had for them — under-legal-hold, not-eligible — are not remembered, so both are sealed **unsettled**, an anomaly the deployment is alerted on; `r4`, settled before any purge, is sealed as the intent carries it. Exactly one fulfilled event stands either way. An intent the window did not close is alerted on.

### Rejection path — a record another act holds, and a gate that cannot say

- **Section unavailable at the gate.** During an erasure, `purge_record(ret-r5, …)` answers section-unavailable: counsel's `place_hold` over the same record is in flight inside Defensible Retention. Nothing was destroyed. The composition calls the purge once more; the hold has landed, the gate fires, and the purge answers `under-legal-hold` → **`retained(legal-hold)`** carrying the hold id and the count.
- **A record another request destroyed.** Two erasure requests for one subject race on `r6`. The second request's `purge_record(ret-r6, …)` answers not-known; the retention read answers `ret-r6` purged, so `r6` is **erased** in the second request's set too, carrying the retention id and the database's purge instant — never a registry anomaly.
- **Storage failure.** `purge_record(ret-r7, …)` answers storage-failure, and again on the one further call the substrate obliges. The retention stands retained and the record may or may not be gone (Defensible Retention Atomic writes 9), so `r7` is sealed **unsettled** — not retained — and the deployment is alerted.
- **A plan the grant cannot finish.** A subject with several hundred gated records is erased under one grant of the request section. When the remaining term falls to the plan floor, the composition makes no further purge: the records not yet reached are sealed **unsettled**, the response is disclosed and the event sealed inside the grant, and a fresh request takes up the remainder — where the grant reaches it. A plan runs in one order, and a record that answers held or obliged is planned again by every later request and stands where it stood; sizing the section term to the largest plan a subject can carry is the deployment's.
- **The request is busy.** A second operator calls `fulfill_erasure_request("dsar-4002", …)` while the first is mid-plan → section-unavailable, with nothing read and nothing written.

### CCPA/CPRA — consumer deletion request

A California consumer submits a deletion request under the CCPA (California Consumer Privacy Act), as amended by the CPRA (California Privacy Rights Act). The erasure path runs unchanged; CCPA section 1798.105(d)'s retained-purpose exceptions (completing a transaction, detecting security incidents, complying with a legal obligation) map onto the same `retained(...)` dispositions the GDPR Article 17(3) exemptions do — a record kept to satisfy a legal obligation is `retained(retention-obligation)` via the Defensible Retention gate, a record kept under a non-consent basis is `retained(other-lawful-basis)`. The response disclosure carries `authority = {type: regulatory, reference: "CCPA §1798.105"}` — the regulatory reference the request was received under. The cross-domain structural identity is the point: the disposition surface is regulation-agnostic; only the cited authority on the response and the host's exemption determinations change.

### HIPAA section 164.524 — access to a designated record set

A patient requests access to their records under HIPAA section 164.524 (a covered entity must provide access to protected health information in a *designated record set*). The access path runs; section 164.524(a)(1) grounds for denial — psychotherapy notes, information compiled for legal proceedings — map onto `withheld(legal-exemption)` dispositions with the citation as the reason. The Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty here as the HIPAA section 164.528 accounting-of-disclosures surface. The same per-record disposition structure serves both regimes.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "prove every record in the subject's universe was dispositioned, and that no held or retention-bound record was erased."** A DPA (Data Protection Authority — a national GDPR regulator) examines a fulfilled erasure request. It calls `disposition_report(request_id)`: by Invariant 2 (no-silent-omission), every enumerated record carries exactly one disposition — there is no record the response silently dropped. For every gated erased disposition, the auditor cross-reads the Defensible Retention substrate's `record_purged` event and confirms `hold_check_result: empty` (Invariant 3, resting on Defensible Retention Invariant 1 — hold-blocks-purge), or reads the record as still owed under the substrate's own marker (Check 3.6); a host-managed erased is the host's attested outcome and carries no gate record (Host-managed records 1). For every `retained(legal-hold)` / `retained(retention-obligation)`, it confirms the then-Active hold or the unelapsed retention via Defensible Retention's records. `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition set was not altered after the fact. Every claim is provable, by virtue of Invariants 2, 3, and 4.

**Disputed erasure — the data subject challenges a retention.** A subject's representative challenges: *"you claim you could not delete record `r2` — prove a hold actually existed."* The system presents the `retained(legal-hold)` disposition with its reason (the blocking `hold_id`) and, via the Defensible Retention substrate, `LegalHold.read({record_ref: r2})` — the Active hold with `placed_by`, `hold_reason`, `placed_at`, and `case_ref`, all immutable by Legal Hold's Invariant 1. `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition was not fabricated or back-filled. The challenge cannot be sustained without claiming the entire hold records were fabricated, at which point the Tamper Evidence seal (via the Defensible Retention substrate) is the structural rebuttal — the same rebuttal chain Defensible Retention's own disputed-destruction scenario establishes, with this composition adding the disposition binding (Invariant 4) that ties the retention claim to a specific recorded hold. The symmetric challenge — *"you erased a record you should have kept"* — is answered by the `dsar.erasure_fulfilled` event plus the Defensible Retention `record_purged` event whose `hold_check_result: empty` proves the gate passed at purge time.

**Breach or incident investigation — "during the compromise window, was any held record erased under cover of a DSAR?"** An investigator suspects an attacker used forged erasure requests to destroy records under legal hold. They query `dsar.erasure_fulfilled` events in the window (reached through the substrate Audit Trail in Event Log insertion order) and, for each gated erased disposition, cross-read the corresponding Defensible Retention `record_purged` event's `hold_check_result`. A held record showing erased would be the smoking gun — but for a record under a Defensible Retention retention Invariant 3 forecloses it structurally: the gate would have returned `under-legal-hold` and yielded `retained(legal-hold)`, never erased. A host-managed record passes no gate, and a hold over one is outside the guarantee (Host-managed records 1). Because the disposition set is part of the hashed `dsar.erasure_fulfilled` payload, an attempt to *silently shrink* the set (to hide an improperly-erased record) breaks the seal — the same append-only, sealed-log rebuttal Propagate Consent Revocation Downstream and Immutable Transaction Ledger rely on. The forensic window is bounded by the substrate's seal cadence; the newest fulfillments in the unsealed tail carry per-event immutability but become seal-verifiable only at the next cadence.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the two indexes plus the Selective Disclosure, Consent and Defensible Retention substrate's records.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE fulfilled event carrying the request id of EVERY fulfillment entry (Invariant 1.2).
Check 1.2: An auditor MUST find EVERY fulfillment entry's response disclosure id resolving to a Selective Disclosure record (Invariant 1.1).
Check 1.3: An auditor MUST find the request id of EVERY fulfilled event older than the entry bound carried by a fulfillment entry, an event Check 1.6 covers excepted (Invariant 1.3).
Check 1.4: An auditor MUST read EVERY request-scoped disclosure against the fulfilled events (Invariant 1.4).
Check 1.5: An auditor MUST read a fulfilled event carrying no fulfillment entry within the entry bound of the event's recording instant as an open obligation (Reconciliation 25).
Check 1.6: An auditor MUST read a fulfilled event carrying no fulfillment entry that the deployment's alerting surface carries an alert for as an open obligation (Reconciliation 35).
Check 2.1: An auditor MUST find EVERY disposition's verdict IS IN the right type's vocabulary (Disposition 1).
Check 2.2: An auditor MUST find no record reference twice in one disposition set (Invariant 2.1).
Check 2.3: An auditor MUST find each disposition set's cardinality matching the fulfilled event's universe cardinality (Invariant 2.1).
Check 2.4: An auditor MUST re-enumerate an access fulfillment's universe AND find EVERY record whose creation instant PRECEDES the enumeration instant in the disposition set (Invariant 2.1).
Check 2.5: An auditor MUST read a re-enumerated record whose creation instant falls within the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 2.6: An auditor MUST NOT re-enumerate an erasure fulfillment's universe (Invariant 2.1).
Check 2.7: An auditor MUST read a re-enumerated record as outside the fulfillment's universe where the enumeration instant PRECEDES the registration of the record's source in the host's data inventory (Completeness boundary 1, External check 1).
Check 3.1: An auditor MUST find EVERY gated erased disposition's destruction record carrying an empty hold check result AND no hold override, a disposition Check 3.6 covers excepted (Capability requirement 10).
Check 3.2: An auditor MUST find EVERY retained legal-hold disposition's gate record naming a hold active at the gate record's position (Invariant 4.1).
Check 3.3: An auditor MUST find a retention over the record of EVERY retained retention-obligation disposition whose retention deadline DOES NOT PRECEDE the enumeration instant (Disposition 22).
Check 3.4: An auditor MUST read a retention deadline within twice the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 3.5: An auditor MUST find destruction evidence for EVERY erased disposition (Invariant 3.1).
Check 3.6: An auditor MUST read a gated erased disposition whose destruction record Defensible Retention still owes under an open marker as an open obligation (Defensible Retention Check 5.9).
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
Check 8.1: An auditor MUST find a closing record for EVERY intent older than the alert bound, an intent Check 8.7 covers excepted (Invariant 1.5).
Check 8.2: An auditor MUST find the audit horizon exceeding the longest retention obligation a registered record carries (Capability requirement 9).
Check 8.3: An auditor MUST find EVERY compensating fulfilled event carrying, for EVERY record outside the plans, the disposition of the intent the event closes (Reconciliation 16).
Check 8.4: An auditor MUST find the compensation window exceeding the closure floor AND the audit horizon exceeding the alert floor (Capability requirement 39, Capability requirement 48).
Check 8.5: An auditor MUST read a check over a horizon event as unknown (Reconciliation 4).
Check 8.6: An auditor MUST find EVERY fulfilled event AND EVERY intent within the payload cap AND EVERY source text within the text cap (Primitive policy 13, Capability requirement 51).
Check 8.7: An auditor MUST read an overdue intent the deployment's alerting surface carries an alert for as an open obligation (Reconciliation 22).
Check 8.8: An auditor MUST read an intent carrying no closing record within the alert bound of the intent's recording instant as an open obligation (Reconciliation 22).
Check 8.9: An auditor MUST find a stall mark for EVERY intent older than the alert bound that carries a planned record AND no closing record, an intent Check 8.10 covers excepted (Reconciliation 38).
Check 8.10: An auditor MUST read an intent carrying no stall mark that the deployment's alerting surface carries an alert for the mark's write as an open obligation (Reconciliation 39).
Check 8.11: An auditor MUST read a closing record carrying no intent AND a stand-in as unknown for Check 6.1, Check 6.2 AND Check 6.7 (Reconciliation 4).
Check 8.12: An auditor MUST read an intent carrying no closing record AND a stand-in as unknown for Check 8.1 AND Check 8.9 (Reconciliation 4).
Check 8.13: IF a lost run EXISTS THEN an auditor MUST read a finding of Check 1.3, Check 8.1 AND Check 8.9 as an open obligation (Reconciliation 34, Reconciliation 40).
Check 8.14: An auditor MUST find no lost run older than the compensation window (Capability requirement 62).
Check 9.1: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 6).
Check 9.2: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 6).
Check 9.3: An auditor MUST clear Defensible Retention's Generation acceptance over the substrate (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

Term gated erased disposition: an erased disposition whose record carried a retention id.

Term recovery marker: Defensible Retention's recovery flag on its re-emitted destruction record, or this composition's compensation flag on a fulfilled event.

Term closing record: the fulfilled event or the abandonment carrying an intent's invocation id.

Term lost run: a run the alerting surface carries an alert for — a failed trail read (Reconciliation 34) or an unended enumeration (Reconciliation 40) — with no later run's enumeration end recorded there (Reconciliation 41). Its age runs from the alert's instant. A run that ends its enumeration after it has alerted on, written and marked what the lost run did not, so the findings the lost run excused are that run's to clear.

Term horizon event: an event whose age on the auditor's now is no less than the audit horizon less three clock offset allowances — an event a run may have read as an aged event and left, or one the audit instance has destroyed. Three allowances: the two of the aged test, and the offset between the auditor's seam and the run's.

Term plan span: the stretch of the log from an intent carrying a purge plan to the intent's closing record and on past it by the planned call latency, read on recording instants — open-ended while the intent carries none. A purge made under a plan falls inside the plan's span: a planned call is issued ahead of the closing record and its last write lands within the planned call latency of its issue, a write that answered no answer included. A purge later in the log than the span is no planned call of that fulfillment, whatever retention it names.

Term enumeration instant: the intended instant of the intent a fulfilled event closes — the now under which the universe was enumerated and every verdict made; equal to the fulfilled instant except on a compensating fulfilled event, which carries it as a field of its own (Reconciliation 31) and so keeps it where the intent is destroyed ahead of the event.

WHY:
A purge intent's attribution (Check 6.3) is to a plan that named the retention, and no proof of which invocation called: where two requests plan one retention id inside overlapping spans, or another caller purges inside an open span, the nearer plan is credited and may not be the caller's. The purge intent's own actor and invocation id say who called, and reading them against the plan's operator is the auditor's next step.

For a closing record the service identity attested the unknown reading of Check 8.11 does not come back once the log is older than the horizon; what the trail still shows beside a compensating event is the leg's own recovery intent, naming the intent it resolved (Reconciliation 11). A destruction record or a gate record destroyed ahead of the fulfilled event that rests on it is a horizon event too: the disposition's purge instant, or the event's enumeration instant, says how old the missing record is, and at that age Check 3.1 and Check 3.2 read unknown (Check 8.5).

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
External check 10: An auditor needing the survival of a gated record sealed unsettled confirmed MUST read the deployment's destruction record (Defensible Retention External check 8).
External check 11: An auditor needing the request section's discipline confirmed MUST clear Lease Check 7.1 through 7.5 over the request section's holder (Concurrency 8 through 19, Concurrency 21 through 24).
```

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

NOTE: the owners — [Permissions](../atoms/permissions.md) (Non-goal 2, External check 4); a Regulatory Deadline pattern *(forthcoming)* or a host dashboard (Non-goal 3, External check 5).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of the composition's events.
Clock semantics 2: The composition MUST NOT reconcile a skew between the seam's clock AND a constituent's clock.
```

### Concurrency

```
Concurrency 1: The composition MUST hold the request section over EVERY fulfillment AND EVERY leg of one request id.
Concurrency 2: The composition MUST read the Consent answer a disposition was recorded under as that disposition's basis.
Concurrency 3: The composition MUST take the request section by Lease's try_take carrying the section term as duration.
Concurrency 4: The composition MUST mint a fresh holder value PER take (Lease Identity 6).
NOTE: watch the fresh holder value (Concurrency 4).
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
Concurrency 18: A yielded fulfillment MUST NOT issue a call, the release of Concurrency 22 excepted.
Concurrency 19: IF a call in flight EXISTS under the grant THEN the composition MUST NOT release the request section (Lease Composition note 5c).
Deleted: Concurrency 20. Execution Contract Database 2 owns it: an audit write's lease check and append are one transaction, so no append lands beside another holder's closing.
Concurrency 21: The composition MUST NOT issue a call under a grant the composition released (Lease Composition note 5f).
Concurrency 22: A fulfillment whose EVERY call answered MUST release the request section.
Concurrency 23: The reconciliation MUST issue EVERY call of a leg PER Concurrency 8 through 19 and Concurrency 21.
Concurrency 24: A leg whose EVERY call answered MUST release the request section.
```

Term yielded fulfillment: an intended fulfillment whose grant of the request section admits no call the fulfillment still owes — the lease reading expired, or the remaining term at or below the floor of the next call. Past the yield the fulfillment issues nothing more, and the open intent is the reconciliation's. A yielded fulfillment is no longer an intended, executed or disclosed one, and an enumerated fulfillment whose grant admits no call of the intent is no longer an enumerated one: the rules that oblige those to call bind a fulfillment only while a floor admits the call.

Term call in flight: a planned call issued under a grant that has not answered — never a call to a database, whose write lands under the holder's grant or not at all (Capability requirement 64). A planned call that answered no answer stays in flight to the grant's end, since a planned call that never answered may still land.

### Accounting stores

```
Accounting stores 1: An erasure fulfillment MUST retain the accounting records as a class.
Accounting stores 2: The composition MUST NOT disposition an accounting record.
```

### Completeness boundary

```
Completeness boundary 1: The composition MUST claim no-silent-omission ONLY over the declared universe.
```

### Host-managed records

```
Host-managed records 1: The composition MUST NOT claim the hold guarantee over a host-managed record.
Host-managed records 2: A deployment needing the hold guarantee over a record MUST place the record under Defensible Retention retention.
Host-managed records 3: The composition MUST NOT claim the hold guarantee for a fulfillment over a record placed under retention later than the fulfillment's retention read.
```

WHY:
A retention and a hold placed later than a fulfillment's retention read and ahead of the host delete — a window of at most one section term — do not stop that fulfillment's host delete, which passes no gate. The window is the deployment's: it places a host-managed record under retention with no erasure of the record's subject in flight, or it accepts that a fulfillment already past its read completes.

### Snapshot

```
Snapshot 1: A fulfilled event MUST NOT carry a disposition for a record outside the fulfillment's enumeration.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes — the intake ([Receive Request]), the two fulfillment siblings ([Fulfill Access Request], [Fulfill Erasure Request]) and the read-only [Disposition Report]; the [Dispositions] set carrying a verdict for every enumerated record; the closed verdict vocabulary ([Included], [Withheld], [Erased], [Retained], [Anomaly]); and its own fulfillment refusals ([Wrong Right Type], [Already Fulfilled], [Incomplete Enumeration]). No-silent-omission and the binding bijection are structural properties, not data. The deployment settings keep their wire spellings in configuration — `record_source_registry`, `audit_trail_retention_policy`, `application_actor_ref`, `application_credential`, `compensation_window`, `fulfillment_completion_bound`, `reconciliation_cadence`, `clock_offset_allowance`, `call_pause_bound`, `section_term`, `section_read_bound`, `planned_call_latency`, `text_cap`, `enumeration_bound`, `id_cap` — and the two indexes theirs in an implementation, `request_to_subject` and `request_to_fulfillment`; the page names each in English where it declares it. Defensible Retention's purge taxonomy is cited whole — ok and the rest of its declared refusals — rather than listed in part. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; the scheduler; a deployment; a regulated deployment; an auditor; a caller; a requester; a subject; an operator; a reader; an invocation; a leg; a fulfillment; a validated intake; a landed intake; an admitted fulfillment; an enumerated fulfillment; an intended fulfillment; an enumerated access; an intended access; a disclosed access; an enumerated erasure; an intended erasure; an executed erasure; a disclosed erasure; a landed fulfillment; an unsealed fulfillment; a yielded fulfillment.

Term records: the intake events, intents, fulfilled events, abandonments and recovery intents the composition records through the audit write — each an Event Log event carrying one action reference below — the response disclosures it records through the disclosure write, and the two indexes' entries.

Term record verbs: add, adjudicate, admit, alert, answer, assemble, attest, attribute, bind, call, carry, change, check, claim, classify, clear, close, compare, compensate, compose, compute, confirm, correct, cover, declare, derive, destroy, disclose, disposition, enumerate, escalate, evaluate, examine, exist, expose, find, gate, hold, include, inherit, inject, inspect, issue, key, land, leave, make, match, mint, name, namespace, normalize, open, own, pair, pass, place, plan, proceed, produce, provision, re-enumerate, re-invoke, reach, read, rebuild, reconcile, record, release, report, resolve, retain, retry, route, run, select, serialize, serve, set, settle, size, stamp, start, store, supply, survive, take, verify, write, yield.

Term value sets: action reference = dsar.received | dsar.access_fulfillment_intended | dsar.erasure_execution_intended | dsar.access_fulfilled | dsar.erasure_fulfilled | dsar.intent_abandoned | dsar.recovery_intended. withheld reason = third-party-confidentiality | legal-exemption. retained reason = legal-hold | retention-obligation | other-lawful-basis. anomaly reason = determination-unavailable | consent-basis-not-known | mis-paired | unknown-retention | host-record-not-found | unsettled. The rest are declared where the section that owns each declares it: right type, request state, verdict, position, case, withdrawn answer, determination reading, basis reading, retention reading, retry answers, unsettling answers, purge reading, lease reading, disclosure fault.

Term bounds: compensation window (compensation_window), fulfillment completion bound (fulfillment_completion_bound), clock offset allowance (clock_offset_allowance), audit horizon (audit_trail_retention_policy), call pause bound (call_pause_bound), section term (section_term), section read bound (section_read_bound), planned call latency (planned_call_latency), text cap (text_cap), enumeration bound (enumeration_bound), id cap (id_cap), and the bounds and floors computed from them — section work bound, record start floor, bind floor, plan floor, closure floor, alert floor, alert bound, entry bound, reason bound.

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive pattern, audit write, trail, trail read, recording instant, retention read, disclosure write, disclosure read, universe enumeration, request id, request index, request entry, fulfillment index, fulfillment entry, live entry, aged entry, request's events, unbound disclosure, stall mark, state read, intake event, intent, aged event, destroyed event, stand-in, quiescence, open intent, fulfilled event, abandonment, plan span, request state, record source registry, creation instant, declared basis, host determinations, host delete, route, host-managed record, accounting records, audit horizon, hold guarantee, service identity, compensation window, fulfillment completion bound, reconciliation cadence, clock offset allowance, seam, now, invocation id, request section, call pause bound, section term, section read bound, section work bound, planned call latency, record start floor, bind floor, plan floor, lease reading, closure floor, alert floor, enumeration bound, alert bound, entry bound, id cap, source text, text cap, reason bound, alerting surface, scheduler, subject reference, right type, requester, regulatory reference, actor reference, credential, record reference, retention id, caller string, largest record, writer, pre-effect record, position, compensation flag, intake result, fulfillment result, report, validated intake, landed intake, fulfillment, admitted fulfillment, enumerated fulfillment, enumerated access, enumerated erasure, universe cardinality, recipients read, consents read, access intent, intended fulfillment, intended access, access scope, request scope, response authority, disclosure fault, refused disclosure write, disclosed access, erasure intent, provisional dispositions, purge plan, host delete plan, destroying surface, planned call, planned record, intended erasure, executed erasure, possibly destroyed record, possibly committed act, erasure scope, disclosed erasure, landed fulfillment, unsealed fulfillment, reconciliation, leg, young intent, overdue intent, request-scoped disclosure, recovery intent, case, compensating fulfilled event, destruction record, destroyed planned record, binding orphan, disposition, verdict, withdrawn answer, determination reading, basis reading, erasure-due record, retention reading, settled record, planned, retry answers, unsettling answers, purge's first answer, purge's last answer, purge reading, outside the host delete's contract, destruction evidence, gated erased disposition, recovery marker, closing record, lost run, horizon event, enumeration instant, yielded fulfillment, call in flight.

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

The erasure disposition for a record destroyed — through Defensible Retention's `purge_record`, by an earlier act the retention records attest, or by the host delete of a host-managed record — recorded only on destruction evidence (Invariant 3.1). Irreversible by the time the fulfillment binds.

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

The disposition for a record whose fate or basis could not be settled — a failed determination, a consent basis the Consent records do not know, a mis-paired or unknown retention, or a planned record its call did not settle: a gate or host answer that leaves the record's fate unsaid, or a call the fulfillment never made — carrying its reason and alerted on, never silently read as erased or retained. Terminal for the fulfillment; the remedy is the deployment's and a fresh request.

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

This composition is the structural form of the resolve-a-persons-data-rights requirement: enumerate a subject's record universe, resolve each record's competing claims into one accountable disposition, and make the resolution provable. Its primary anchors:

- **GDPR (EU General Data Protection Regulation) Article 15 (Right of access by the data subject)** — the subject may obtain confirmation of processing, a copy of the data, and *the recipients or categories of recipient to whom the personal data have been disclosed* (Article 15(1)(c)). This composition's access path produces the per-record included / `withheld(...)` disposition set, and the Selective Disclosure read answers the recipients limb provably.
- **GDPR Article 15(4)** — the right to obtain a copy *shall not adversely affect the rights and freedoms of others*. The `withheld(third-party-confidentiality)` disposition is the structural form of this limit; this composition records the assertion, and its legitimacy is the externally-clearable check.
- **GDPR Article 17 (Right to erasure / "right to be forgotten")** — Article 17(1) names the grounds that trigger erasure, including 17(1)(b) (consent withdrawn and no other lawful ground — the Consent-oracle branch). Article 17(3) names the exemptions: 17(3)(b) (compliance with a legal obligation / retention — `retained(retention-obligation)` via the Defensible Retention Retention Window leg) and 17(3)(e) (establishment, exercise, or defence of legal claims — `retained(legal-hold)` via the Defensible Retention hold-blocks-purge gate). This composition's erasure path is the structural resolution of Article 17 against its own 17(3) exemptions.
- **GDPR Article 12(3)** — fulfillment within one month of receipt. This composition records `received_at` and `fulfilled_at`, each provable; deadline computation is a composing/externally-clearable concept.
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

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — resolve-a-persons-data-rights.tla + 9 twins + 3 probes (one erasure against two legs of the reconciliation, under the request section: 162,645 states, holding at a term of 6 within 9 ticks), resolve-a-persons-data-rights-access.tla + 1 probe (a fulfillment with nothing planned against the same two legs: 17,796 states, holding at a term of 6 within 9 ticks) and resolve-a-persons-data-rights-admission.tla + 1 twin + 1 probe (two fulfillments of one request: 56,552 states, holding at a term of 6 within 8 ticks), re-derived from the page as it stands, 2026-10-21
last gate: 2026-10-07 — one Linus pass by a fresh reader on the text after the Ledger's drain — 1 foundational, cured in the pass, 5 refining reports, 3 rhetorical reports; not clean: the round stopped at one pass, and the text as it stands is unread.

open:
- 2026-10-05-c · refining · Disposition 41, 45; Reconciliation 13 through 15 · the one retry of a purge that answered storage-failure, made straight after the substrate's own step-3 refusal, meets its unreleased record section, and a leg never retries; the receiver of what is still owed is now named (Disposition 48) → order the retry
- 2026-10-05-d · refining · Reconciliation 13, 14; Audit arm 16 · an erasure whose invocation died after its intent is completed with every planned record unsettled, a permanent disclosure after the caller heard intent, where the substrate's purge intents and gate records on the shared trail could show that no call was made or that a hold refused one → re-derive from the trail what the trail shows
- 2026-10-05-e · refining · Primitive policy 5, 13; Audit arm 19, 20; Action wiring 21 · invalid-request lands a caller's blank input and three deployment faults, before an intent and after one, with no position; and a blank request id has no policy and reaches a take on a blank key → one code per meaning; a policy
- 2026-10-05-f · refining · Term text cap; Capability requirement 40, 51; Term largest record · the text cap's unit is unstated, Audit Trail's payload cap defaults to none, and the largest record does not name Audit Trail's serialized envelope, which differs for a compensating event attested under the service identity → declare each
- 2026-10-05-g · refining · Composition state 14, 27; Capability requirement 50 · an aged entry is a whole verdict set, and a stall mark a planned destruction's only carrier, each kept for the life of the instance with no retention, seal or owner beyond a forthcoming pattern → an owner
- 2026-10-05-h · refining · Accounting stores 1, 2; Selective Disclosure Composition note 3 through 6; Consent Composition note 6 · the seal of the accounting records, the attestation of a disclosure's writer and the legitimacy of the response authority are neither met nor declined with a named receiver; their retention is now forbidden a bound (Capability requirement 60, 61) → state each
- 2026-10-05-i · refining · Check 3.1 through 3.4, 8.5; Capability requirement 9 · four checks re-derive what Defensible Retention's own checks own, and the horizon reading of a destruction record or a gate record destroyed ahead of its fulfilled event is stated in a WHY under Check 8.5 and by no check of its own → cite; a check
- 2026-10-05-j · refining · Invariant 1.3, 1.6, 2.2, 3.2, 5.1, 6.1; Term Already Fulfilled · invariants beside Invariant 1.2 and 1.5 lack the past-horizon qualifier, and Invariant 1.6 and 3.2 among others are named by no check → qualify; a check each
- 2026-10-05-k · refining · Disposition 7, 39; Term retention reading · an enumerated record that reads purged is sealed erased with no alert, one whose basis reads a ground is sealed retained though destroyed, and a host-managed record under a purged retention reads mis-paired → state each
- 2026-10-05-l · refining · Concurrency 4, 10, 14; Capability requirement 25; Term planned call latency · the holder value's source and a leg's own id are undeclared, and a no-answer is timed on a span no rule gives an invocation a clock for → declare the span clock; inject the ids
- 2026-10-05-m · refining · Reconciliation 8, 12, 13, 15 · the disclosure pairs on the request id where the method names the invocation id, and the three closures oblige on any open intent, kept to the leg's own by the order of its reads alone → state each
- 2026-10-05-n · refining · Check 7.1, 7.2; Disposition 9, 40 · the two checks read actor fields Consent does not attest; a consent judged on Consent's clock alone leaves the auditor no instant to ask again as of; and a Consent check that gives no answer seals an anomaly on erasure where the same outage refuses an access ahead of its intent → state; an external check
- 2026-10-05-o · refining · Wiring decision 1, 3; Action wiring 14; Disposition 1; Invariant 1.1, 2.1, 7.1, 7.2; Capability requirement 8, 13, 33; Reconciliation 5, 18; Composition state 9 · one proposition under two rules in six places, and two requirements that hold by construction → tombstone the second owner
- 2026-10-05-p · refining · Audit arm; Reconciliation; Concurrency 3 through 24 · the intent and outcome pairing, the audit arms, the leg and the request section are the invocation protocol Recoverable Invocation is drafted to own, restated here a third time after Audit Trail and Defensible Retention → extract when that composition grounds; own round
- 2026-10-05-q · rhetorical · Summary; Examples; Terms; Composition-level invariants · sealed, compensated and tamper-evident are unglossed in the Summary; the walkthrough payloads omit fields the rules require and nothing walks the host delete, the invocation's own abandonment or state-unavailable; four refusals have no term entry; the examples write rejected where the rules say answers; the Invariant 9 tombstone sits in Invariant 8's block → rewrite on the next load-bearing touch
- 2026-10-05-r · refining · Capability requirement 34, 41, 42, 49, 50, 52 through 61, 63; Reconciliation 10, 11, 29, 37, 41; Composition state 28; Host-managed records 3; Disposition 48 · no check and no external check reads them → a check each, or name them external
- 2026-10-05-s · refining · Check 2.4, 2.6, 2.7; Capability requirement 1 · the registry is not obliged to carry a source's registration instant, an erasure that omits a surviving record is tested nowhere, and Check 2.6's stated reason is not the one Check 2.4's direction gives → oblige the instant; restate the reason
- 2026-10-05-z · rhetorical · Term fulfillment; Term reconciliation; Term leg; the reason value sets · fulfillment names the call and the bound triple, reconciliation is defined as the leg and run is undeclared, and three reasons each cover two causes → one name each
- 2026-10-06-b · refining · Invariant 3.2; Disposition 18, 35; Host-managed records 3; External check 10 · a host delete rests on a retention reading up to a section term old; the window is stated and is the deployment's, and a reading taken again ahead of each host delete would shorten it to a call; and no external check names the evidence for a host-managed record sealed unsettled → the second reading; name the evidence
- 2026-10-06-c · refining · Check 6.3, 6.4; Term plan span · the attribution's limit is stated — the nearer plan is credited and may not be the caller's — and no check compares a purge intent's actor and invocation id with the plan's → the comparison as a check
- 2026-10-06-e · refining · Term stand-in; Term destroyed event; Check 8.11 · for a closing record the service identity attested the unknown reading does not come back, which the page states, where the record's own enumeration instant could bound it; a stand-in is any destroyed event, so an unreadable payload short of the horizon closes every earlier unmarked intent; and the Term cites Defensible Retention for a reading Audit Trail's erasure mechanism grants → bound by the enumeration instant; filter by age; cite the grantor
- 2026-10-06-f · refining · Audit arm 24, 26; External check 5 · a caller told recording-failure carrying intent has no bound past which the report's not-known is final; a leg re-issues an event refused invalid-request at step-3, which Audit Trail record action step 7.13 forbids; and the statutory deadline is computed from seam instants a stalled host stamps early, with the log's recording instant unnamed → state each
- 2026-10-06-g · refining · Term retention read; Term record start floor; Term plan floor; Reconciliation 9, 30 · the retention read is whole-database and is made again inside the planned call latency for each not-known; a leg's retention readings are not pinned ahead of its first write; and the two latencies run from the call's issue where Lease's unit runs from the reading, leaving one pause of margin where the Terms say two → a filtered read; pin; one origin
- 2026-10-06-h · refining · Term purge plan; Disposition 17, 45; Concurrency 7; Reconciliation 26 · a record that answers held or obliged stands first in every later plan, so a subject with enough of them never reaches the rest, which the page names as the deployment's sizing; and a caller retrying compensation-pending takes the section ahead of its read and can keep a leg answered held, with the alert the only cover → order the plan by what a call can still settle; read ahead of the take
- 2026-10-06-i · refining · Term aged event; Reconciliation 12 · aged is judged on each seam's own now, so a fulfillment can read an unclosed intent as aged and admit where a later leg on a slower clock reads it open and pairs it to the new disclosure — reachable only past an alert left unanswered to the horizon → one reading
- 2026-10-06-j · rhetorical · Capability requirement 31, 33; Check 1.1, 2.1; Summary; Examples · two requirements hold by the Terms' own formulas and one cites Lease Sizing 9 for a comparison Lease makes against the write margin; Check 1.1 leans on Check 8.5 for its aged exception and Check 2.1 read to the letter catches an intent's provisional marker; the Summary runs past the format's length and carries no blockquote; the disputed-erasure example reads Legal Hold through the substrate, a reach Composes says does not exist; and spec-format's edge-case headings for cross-record consistency and identity are absent → rewrite on the next load-bearing touch
- 2026-10-06-k · refining · Disposition 34, 43; Term reason bound; Check 6.1, 6.2 · a second request racing on a host-managed record lands host-record-not-found where the gated twin lands erased; the reason bound sizes an access set as if every reason carried hold ids at the cap; and the two checks order the intent against the fulfilled event alone, so a disclosure or a host delete issued ahead of its intent passes → state or leave; read the disclosure's own instant
- 2026-10-06-l · refining · the rounds of 2026-10-06 and 2026-10-07; 2026-10-05-p · seventeen foundational findings in fourteen passes, twelve of them in the intent and outcome pairing, the reconciliation's edges, bounds and runs and the horizon — the protocol line 2026-10-05-p names, which Defensible Retention carries too. After fifteen Ledger lines were cured or stated in the body the next pass returned half the refining reports and one foundational finding, in a check written that morning for the same protocol → bind this page to Recoverable Invocation and delete what it then cites; the three passes after
- 2026-10-07-a · rhetorical · Term enumeration instant; Capability requirement 33 · the intended instant is called the now under which the universe was enumerated, where it is the reading ahead of the take and stale by any stall; and the requirement holds by the floors' own formulas → rewrite on the next load-bearing touch
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/resolve-a-persons-data-rights.md`; the rounds and the migration that got it here are in [its history](./resolve-a-persons-data-rights.hist.md).

- **2026-10-21 — A state-unavailable answer writes nothing, as the Execution Contract says; the state read keeps its own failure.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 64, Execution Contract Read 1 through 3) and the rule that restated Read 3 deleted to it (Composition state 23: an action answering state-unavailable records no event); rules 369 to 368. *Over:* the page stating for itself that a state-unavailable answer records nothing. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once. Composition state 22 stays, the page's own answer: its state read fails only where no fulfillment entry or fulfilled event already read settles the request as Fulfilled (Term state read), where Read 1 alone would answer state-unavailable for any failed read; and a failed disclosure or Consent read of an enumerated access still answers incomplete-enumeration (Action wiring 37), a constituent's answer this composition renames.
- **2026-10-21 — The store's guarantees cited, not restated, and a store write's lease check and its commit one transaction; the compensation kept for what Audit Trail still refuses.** *Chose:* Capability requirement 64 citing Execution Contract Store 1 through 4 for the store the constituents and the two indexes keep their records in; to Store 3 and Store 4, the indexes kept for the life of the instance (Capability requirement 50); to Store 1, under which an action's writes commit together, its constituents' included, the order that put the fulfilled event after the response disclosure, which the event's own obligations already rest on (Wiring decision 3), and the reading of Audit Trail's recording-failure carrying step-4 as a landed record, an answer Audit Trail's rewrite left committing nothing or with its reply lost (Audit arm 1, with the tombstones of Audit arm 3, 5 and 12 that named it); to Store 2, under which a store write's lease check and its commit are one transaction, the request section held over an audit write that answered a step-3 refusal (Concurrency 20), so the section is held over a planned call in flight alone and released once every call has answered (Term call in flight, Concurrency 22 through 24, External check 11). Kept against the census: the request index and the fulfillment index stay derived indexes outside every action's transaction, as obligation 2 of the section titled Composition state in `execution-contract.md` keeps them, each entry written after its event, rebuilt on a miss and backfilled by the reconciliation (Composition state 4, 9, 13, 20, 21, 25, Reconciliation 18, 25, 35, 36, Check 1.5, 1.6); the binding orphan and its compensation, since Audit Trail's refusal of a fulfilled event — an invalid-request below step-4, a reply lost, an invalid-credential after the operator's registration changed — still leaves the response disclosure committed and the event owed (Composition state 24, Reconciliation 8, 12, 32, Invariant 1.4, Check 6.8); and the abandonment of an intent with nothing planned, which a disclosure write that never answered, or a grant spent after the intent, still leaves (Reconciliation 15). The erasure keeps its intent, its outcome, its reconciliation with both edges and the request section with its sizes: Defensible Retention's purge and the host delete are acts outside the store, and the lease keeps its job for them. Rules 372 to 369. *Over:* a disclosure and a fulfilled event no transaction could span, ordered so the event came last — the turn of 2026-08-27, below — and a section held past every answer over an append that might land after its holder's grant. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal, and that Store 2 covers a guard decided across a lease check, the lease keeping its job for the act outside the store. An access, an erasure with empty plans, an erasure's disclosure and fulfilled event, and a leg's recovery intent, disclosure and event are each the store writes of one action, so no crash leaves half of them; what still reaches a half is a refusal the page keeps as evidence. A request's events are ordered by Event Log's own sequence numbers (Clock semantics 1), and no rule reads a record as it stood at a past commit, so the composition cites neither Store 5 nor Order 1. What the composition does for its domain is unchanged.
- **2026-10-07 — What the Ledger carried as owned is now said in the body, and a run records that it ended.** *Chose:* fifteen open Ledger lines cured or stated where a reader meets them — the answer to an alert as a requirement of the deployment and the alert as a kept record (Capability requirement 62, 63); a stall mark never cleared (Composition state 28); the read a not-known obliges as a rule, and the two departures from Defensible Retention's caller rules declared as such (Action wiring 42); an included disposition carrying no-bar; the basis reading in first-that-holds order; one order of refusals ahead of the intent; the limits of the nesting attribution, of a recovered close's pairing and of the host delete's window stated as limits — and a run recording the end of its enumeration on the alerting surface, so an auditor can tell a lost run from the run that followed it (Reconciliation 41, Term lost run, Check 8.13, 8.14). *Over:* ownership arguments filed in a Ledger the cold reader is forbidden, where each cost a pass to find again, and a check that asked an auditor which run was latest with no record to tell by. *Because:* the one pass run after the drain returned half the refining reports of the passes before it, and its one foundational finding sat in the run-alert check written that morning. Twelve of seventeen findings across fourteen passes are in the recovery protocol this page restates; the page stays `partially resolved`, and the next move is to bind it to Recoverable Invocation and delete what it then cites, with the three passes after.
- **2026-10-05 — One request, one writer at a time; a leg seals what the stores show; a gate's answers are read together; findings became alerts.** *Chose:* the request section, a Lease on the request id, over every fulfillment and every leg, an invocation id on every record, and no audit write issued twice; the request's state read from the trail, the durable fulfillment entry and the response disclosure, which never ages; the reconciliation closing an intent by what could have committed — compensate, complete, and abandon only where nothing was planned — and sealing from the stores, remembering nothing; every answer of the gate, the stores and the host read through a declared reading that takes exactly one value, a storage-failure never taken back by a later refusal; every pairing confirmed against Retention Window's own read, a host-managed record's included; the largest record sized whole before the intent, with no digest and no truncation; one audit retention policy for every event the composition records; alerts on a declared surface where finding events had no closer. Each decided by a standing rule: *make all things mean one thing* (the readings, one horizon, section-unavailable as the substrate means it); *as simple as possible without losing fidelity* (alerts for findings, a universe the cap cannot carry refused rather than digested, an unreadable trail answered state-unavailable); *generalize nothing* (Consent asked with no at time, so no reading of this seam's decides an erasure). *Over:* a serialization nothing held, a terminus an invocation that reads the clock once could not observe, a retry after a step-3 refusal, a precedence stated in a WHY, a pairing confirmed against a listing of what is already destroyable, a leg that abandoned a destruction no store shows, and a digest no compensation could seal. *Because:* Defensible Retention's re-grounding moved its purge's answers and what its storage-failure means, and the gate that followed showed every look-then-write on this page resting on a second writer not arriving.
- **2026-08-26 — The erasure intent record carries a `purge_plan`, and authentication is not inherited across the substrate boundary.** *Chose:* the plan names the retentions a rights fulfillment will attempt, so a purge occasioned by an authorized fulfillment is distinguishable in the shared Audit Trail from a direct call that bypassed the rights process; Defensible Retention verifies the same credential independently at its own boundary. *Over:* treating the outer authentication as covering the nested purges. *Because:* the substrate's surface is independently callable, so what the plan records is provenance, not authority.
- **2026-08-29 — The scan is bounded at both edges and records its intent before it seals or writes.** *Chose:* `fulfillment_completion_bound` below and the audit horizon above for the reconciliation scan; a `dsar.recovery_intended` record before direction 2's cases (i) and (ii); the pairing stated as exact by the Committing gate. *Over:* a scan on `reconciliation_cadence` alone. *Because:* a Committing request seconds old belongs to an invocation about to seal, and case (ii) would write a second response-disclosure beside the one it is about to bind; a seal the scan writes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).
- **2026-08-29 — The accounting stores leave the universe, a request can be Committing, and the scan compensates only what reached the bind.** *Chose:* the Selective Disclosure and Consent stores are response content retained as a class, not dispositioned records; a Committing state (intent with no closing event) that both fulfillment actions refuse with compensation-pending; scan step 2 resolved by whether a response-disclosure exists (compensate), records were destroyed (complete), or nothing committed (abandon); `purge_record`'s shared tokens disambiguated by one destruction-safe re-invocation; `retained(retention-obligation)` grounded in the Retention Window record; findings recorded as `dsar.finding_opened` / `dsar.finding_closed` events under a declared service identity. *Over:* a universe the branches could not disposition, a two-state lifecycle, unconditional compensation, categorical token readings, an event the substrate never emits, and a dashboard nothing declared. *Because:* the page's own walkthroughs violated Invariant 2; a retry after a post-commit failure re-ran the fulfillment; the recovery path produced the reverse orphan the safety half forbids; and check 4 failed every conforming implementation.
- **2026-08-27 — Invariant 1 is safety plus liveness, in three arms.** *Chose:* no `dsar.*_fulfilled` event without its response-disclosure and complete disposition set (earned by write order); no unsurfaced orphan; every orphan compensated within a declared window and distinguishable via `cascade_recovery = true`. *Over:* "commits together or not at all" across a write the substrate cannot withdraw. *Because:* the order was right from the first draft and the claim was merely unprovable — the restatement says what the order earns and nothing more.

NOTE: End of Resolve a Person's Data Rights.

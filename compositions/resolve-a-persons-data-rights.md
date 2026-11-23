---
title: Resolve a Person's Data Rights
id: 7
audience: common
parent: Conceptual Compositions
nav_order: 20
has_toc: true
toc: true
---

# Resolve a Person's Data Rights

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Resolve a Person's Data Rights is a regulated composition (a spec that wires two or more freestanding, self-contained pattern specs together) that answers a person who exercises their legal right to see, or to delete, the personal data an organization holds about them, and lets the organization prove afterward that it did the lawful thing using only the records it kept. The hard part is that the request collides with other rules, since a record may be under a legal hold that forbids deletion, may have to be kept for a legally required period, or may have been collected under a consent since withdrawn, so the composition gives every record in the person's data exactly one recorded verdict, called a disposition: handed over, or withheld with a reason, for an access request, and erased, retained with a reason, or flagged as an anomaly (a record whose fate could not be settled) for an erasure request. It wires four constituents: Selective Disclosure (the running log of every time the person's data was shared and with whom, read to answer who has had it and written to record the response itself), Defensible Retention (the substrate that refuses to destroy a record under a legal hold, which is the structural answer to erasure against preservation, and through which the composition reaches the tamper-evident Audit Trail, a log whose entries are sealed so that any later change shows), Consent (a read-only source asked whether consent was the basis for processing a record and is still in force), and Recoverable Invocation (the open, commit and close protocol an erasure follows, so an erasure that stops partway is closed and sealed on a later call). The guarantee that appears only when they are combined has two halves: nothing is silently omitted, because every record in the person's enumerated data carries one disposition, and the dispositions, the record of the disclosure to the requester and the sealed Audit Trail event are bound together, so no fulfilled request lacks its dispositions and no disclosure stands without its sealed event. The composition enforces the structural hold gate and records each reason, and leaves to counsel and to composing patterns the legal question whether an exemption truly applies. It serves GDPR (the EU General Data Protection Regulation) Article 15 access and Article 17 erasure fulfillment, CCPA/CPRA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) access and deletion requests, and HIPAA (the US Health Insurance Portability and Accountability Act) section 164.524 access to a designated record set.

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
- **[Recoverable Invocation](./recoverable-invocation.md)** — the open, commit and close protocol around [Fulfill Erasure Request]'s planned calls, which no store transaction can enclose: the host delete and Defensible Retention's purge answer outside the composition's own store.

```
Composes 1: EXACTLY ONE Selective Disclosure instance MUST serve the composition.
Composes 2: EXACTLY ONE Defensible Retention instance MUST serve the composition.
Composes 3: EXACTLY ONE Consent instance MUST serve the composition.
Composes 4: The composition MUST reach a transitive pattern other than Lease ONLY on an instance Defensible Retention carries, through Defensible Retention's purge, the audit write, the trail read AND the retention read, AND MUST reach Lease ONLY through Recoverable Invocation.
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
Composes 15: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 16: The Recoverable Invocation instance MUST write to the Audit Trail instance Defensible Retention carries.
Composes 17: The composition MUST bind the act kind PER the erasure binding.
Composes 18: The composition MUST NOT bind [Receive Request], [Fulfill Access Request] AND [Disposition Report] as an act kind.
Composes 19: The composition MUST NOT hold an instance of Lease, which Recoverable Invocation reaches.
```

Term composition: this pattern's wiring of [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md), [Consent](../atoms/consent.md) and [Recoverable Invocation](./recoverable-invocation.md) — the intake, the two fulfillment siblings, the report, the two indexes and the reconciliation.

Term constituents: [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md), [Consent](../atoms/consent.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive pattern: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) or [Audit Trail](./audit-trail.md), reached through Defensible Retention, [Lease](../atoms/lease.md), reached through Recoverable Invocation, and [Event Log](../atoms/event-log.md), reached through Audit Trail.

Term audit write: Audit Trail's record_action on the Audit Trail instance Defensible Retention carries.

Term trail: the events of the Audit Trail instance Defensible Retention carries — this composition's own and the substrate's, in one log.

Term recording instant: Event Log's recording instant — the instant the log stamps on an event at its append.

Term trail read: Event Log's read by an open-ended sequence range, on the Event Log instance Audit Trail carries, reached the way Defensible Retention reaches the same log (Defensible Retention Composes 12 through 14).

Term retention read: Retention Window's read on the business retention instance Defensible Retention carries — every retention with the retention's record reference, retention state, retention deadline and, where the retention stands purged, purge instant.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term source enumeration: the subject-scoped read a registered source exposes, answering the record reference, the source, the creation instant and the route of each of a subject's records (Capability requirement 2); the universe enumeration reads one for every registered source and fails where one fails (Action wiring 12).

Term universe enumeration: the composition-introduced surface that enumerates a subject's in-scope records over the record source registry — the Defensible Retention-managed records being the registered records a source answers a retention id for — each with its record reference, its source and its creation instant — the eventual home of a Completeness Model atom *(forthcoming)*.

Term act kind: erasure execution — `dsar.erasure_execution`, the one act kind this composition binds on its Recoverable Invocation instance: an erasure's planned calls, the purge of each purge plan pair and the host delete of each host delete plan record.

Term erasure binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the request id. repeatable — no. commit — the execution commit, read through the commit partition. pairing datum — the intent's own now, the purge instant of a purge this act made. act probe — the erasure probe, which departs from Recoverable Invocation act probe 8 (the Composition notes). invocation completion bound — the deployment's, from the critical section's take to the close's last write. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the Audit Trail instance Defensible Retention carries, with dsar.erasure_execution.intended, the one outcome dsar.erasure_execution.executed, and dsar.erasure_execution.refused. retention period — the audit horizon. settling period — the deployment's settling period. service identity — the composition's service identity. outcome envelope — the plan's retention ids and record references, at the id cap, and one instant each.

Term act key: the request id [Receive Request] injects at its seam, known before the invocation open. Two executions of one request are one act attempted twice, repeatable being no: a second call takes the act's critical section in turn and meets act-landed once the first has closed with an outcome (a refusal, an abandonment or an escalation holds none, Recoverable Invocation open step 3.9), and the execution commit's own guard read refuses a request a fulfilled event already names (Recoverable Invocation repeatable 2).

Term execution commit: the erasure's planned calls in plan order, under one invocation, each answer landing its record's disposition — in order, a guard read of the request's fulfilled events and fulfillment entry that refuses already-fulfilled where one stands; the retention re-read of each host delete plan record; then Defensible Retention's purge for each purge plan pair and the host delete for each host delete plan record, up to the plan cap.

Term commit partition: pre-commit where the guard read answers already-fulfilled or state-unavailable (Execution Contract Constituent failure 3), or the retention read of Action wiring 53 fails or answers no answer (Action wiring 56), each before any planned call; committed where the planned calls ran, each answer landing a disposition and a no answer landing unsettled (Term purge reading); unknown where the execution commit has not returned when the commit round trip has elapsed since its issue (Recoverable Invocation commit 6, commit 7).

Term erasure probe: the read that answers whether an open intent's erasure committed: the retention read for every purge plan pair and the trail's Defensible Retention gate records for the plan's retention ids within the plan span (Composes 12, Composes 13). It answers committed, carrying the request id and the one pair read purged under the intent's now with its retention id and purge instant, where the host delete plan is empty and exactly one pair reads purged under it and every other reads retained or purged under another instant; not-committed where no pair reads purged under it, no gate record names a pair within the plan span and the host delete plan is empty; undecidable, carrying the planned record references the stores do not tie to this act, where any host delete plan record stands, two or more pairs read purged under it, or no pair reads purged under it while a gate record names a pair within the plan span; unavailable where a read refuses or the store is out (Recoverable Invocation act probe 4).

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
Composition state 10: A fulfillment entry MUST carry the dispositions the fulfilled event carries.
Composition state 11: The composition MUST NOT change a fulfillment entry.
Composition state 12: The composition MUST classify a live entry as a derived index.
Composition state 13: The composition MUST rebuild a missing live entry from the entry's event.
Composition state 14: The composition MUST classify an aged entry as extraction-pending against Erasure Tombstone.
Composition state 15: The composition MUST derive a request's state from the request's events, the request entry, the fulfillment index, the request-scoped disclosures AND the act kind's records, read through Recoverable Invocation's read of an invocation (Recoverable Invocation Non-goal 4).
Composition state 16: IF a fulfillment entry EXISTS for the request THEN the request's state MUST carry Fulfilled.
Composition state 17: IF an intent of the act kind EXISTS for the request AND no standing closing of the intent EXISTS THEN the request's state MUST carry Committing.
Composition state 18: The composition MUST NOT store a subject's enumerated universe.
Composition state 19: IF a fulfilled event carrying the request id EXISTS THEN the request's state MUST carry Fulfilled.
Composition state 20: The composition MUST NOT answer not-known BEFORE rebuilding the request index.
Composition state 21: The composition MUST read a fulfilled event carrying no fulfillment entry as a rebuild trigger.
Composition state 22: IF the state read fails, the read of an invocation's journal-unavailable answer included, THEN the action MUST answer state-unavailable AND MUST NOT answer not-known (Recoverable Invocation Action wiring 3).
Composition state 25: An index write that fails MUST NOT change an action's answer.
Composition state 26: IF a stall mark EXISTS for the request AND no fulfillment entry EXISTS for the request AND no fulfilled event carrying the request id EXISTS THEN the request's state MUST carry Committing.
Composition state 27: The composition MUST classify a stall mark as extraction-pending against Owed Record.
Composition state 28: The composition MUST NOT clear a stall mark.
Composition state 29: The composition MUST NOT store a record of the Recoverable Invocation instance.
Composition state 30: IF an intent of the act kind EXISTS for the request AND the standing closing of the intent is `.escalated` THEN the request's state MUST carry Committing.
Composition state 31: IF an intent of the act kind EXISTS for the request AND the standing closing of the intent is `.executed` AND no fulfilled event names the request THEN the request's state MUST carry Committing.
Composition state 32: The composition MUST retain an aged entry AND a stall mark until the extraction Composition state 14 AND Composition state 27 name lands (Execution Contract Composition state).
Composition state 33: The composition MUST store the stall mark in the stall index, keyed by request id, apart from the request entry AND the fulfillment entry.
```

Term request id: the opaque id the host injects at [Receive Request]'s seam — never reused.

Term request index: the composition's map from a request id to the request's intake — `request_to_subject` in an implementation.

Term request entry: one request id's subject reference, right type, requester, regulatory reference and received instant.

Term fulfillment index: the composition's map from a request id to the request's fulfillment — `request_to_fulfillment` in an implementation; the queryable mirror of the sealed fulfilled event.

Term fulfillment entry: one request id's right type, fulfilled instant, [Dispositions], response disclosure id and fulfillment event id.

Term live entry: an index entry whose event's payload the audit horizon has not reached.

Term aged entry: an index entry whose event's payload the audit horizon has destroyed.

Term request's events: the composition's events carrying one request id, selected over the trail read.

Term stall index: the composition's map from a request id to the request's stall mark, kept apart from the request index and no derived index: no event carries a stall, so nothing rebuilds it, and the rebuild of a missing request entry (Composition state 13) neither writes nor drops a mark.

Term stall mark: the stall index's record, keyed by the request id, of the invocation id of an intent of the act kind that a run read as open past Recoverable Invocation's at-risk threshold (Reconciliation 38, restated as the index leg), on a request that carries no fulfilled event and no fulfillment entry. A run writes it, to the one value, each time it reads the intent as open past that threshold, and it does not lapse as the intent ages: past the audit horizon it is the one carrier of a destruction that was planned and never sealed.

Term state read: the reads a fulfillment or [Disposition Report] derives the request's state from — the request's events, the request entry, the disclosure read of the request's subject reference, and the rebuild of a missing index entry. The state read fails where one of them fails and neither a fulfillment entry nor a fulfilled event already read settles the state as Fulfilled.

Term intake event: the dsar.received event.

Term intent: the access intent, or the act kind's dsar.erasure_execution.intended record.

Term fulfilled event: the dsar.access_fulfilled or dsar.erasure_fulfilled event.

Term request state: Received | Committing | Fulfilled — derived, never stored: Fulfilled where Composition state 16 or Composition state 19 holds, Committing where Composition state 17, Composition state 26, Composition state 30 or Composition state 31 holds, and Received everywhere else. The act kind's intent and a stall mark are each defined over a request carrying no fulfilled event and no fulfillment entry, so no request reads two.

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the record source registry, carrying the registration instant in the host's data inventory of EVERY registered source.
Capability requirement 2: EVERY registered source MUST expose the source enumeration answering the record reference, the source, the creation instant AND the route PER record.
Capability requirement 3: EVERY registered source MUST expose the declared basis PER record.
Capability requirement 4: EVERY registered source MUST expose the host determinations PER record.
Capability requirement 5: EVERY route MUST carry EXACTLY ONE OF a retention id, the host delete.
Capability requirement 6: The host delete MUST verify the presented credential at the host's own boundary.
Capability requirement 7: The universe enumeration MUST NOT enumerate accounting records.
Capability requirement 9: A deployment MUST set an audit retention policy whose horizon EXCEEDS the longest retention obligation a registered record carries.
Capability requirement 10: The Defensible Retention instance MUST run strict as the hold check mode.
Capability requirement 11: The composition MUST NOT claim the hold guarantee over a Defensible Retention instance running advisory.
Capability requirement 12: A deployment MUST provision the service identity, the service identity of Recoverable Invocation's binding for the act kind.
Capability requirement 20: A deployment MUST declare the clock offset allowance on the Recoverable Invocation instance (Execution Contract Logic confinement 18).
Capability requirement 21: The host MUST inject now at the seam once per invocation.
Capability requirement 22: The host MUST inject a request id that DOES NOT EQUAL blank AND names no other request at [Receive Request]'s seam.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 25: The host MUST inject one invocation id that names no other invocation at the seam PER state-changing invocation, the act kind's invocation id being Recoverable Invocation's.
Capability requirement 26: The composition MUST NOT take an invocation id as an input.
Capability requirement 27: A deployment MUST supply the act section Recoverable Invocation takes (Recoverable Invocation Capability requirement 11).
Capability requirement 35: A deployment MUST disclose the planned call latency.
Capability requirement 37: A deployment MUST supply the alerting surface.
Capability requirement 41: A deployment MUST route EVERY disclosure write carrying a request scope through the composition alone.
Capability requirement 42: A deployment MUST route EVERY audit write carrying a composition action reference through the composition alone.
Capability requirement 44: EVERY registered record MUST carry a record reference no other registered record carries.
Capability requirement 45: A deployment MUST disclose the audit write latency PER Defensible Retention Capability requirement 22 AND PER Recoverable Invocation's journal write bound.
Capability requirement 47: EVERY registered source MUST answer a retention id for a record a retention of the business retention instance covers.
Capability requirement 49: A deployment MUST set an audit retention policy that answers one policy for EVERY event of the audit instance (Defensible Retention Capability requirement 57).
Capability requirement 51: EVERY registered source MUST answer EVERY source text within the text cap.
Capability requirement 52: A deployment MUST NOT serve two instances of the composition by one Defensible Retention instance.
Capability requirement 53: A deployment MUST NOT serve two instances of the composition by one Selective Disclosure instance.
Capability requirement 54: A deployment MUST NOT change the audit retention policy for the life of the instance.
Capability requirement 57: A deployment MUST NOT admit another writer of a composition action reference on the audit instance.
Capability requirement 59: A deployment MUST declare the id cap.
Capability requirement 60: A deployment MUST place EVERY record of the Selective Disclosure instance under the retention of the Defensible Retention instance (Selective Disclosure Composition note 6).
Capability requirement 61: A deployment MUST place EVERY record of the Consent instance under the retention of the Defensible Retention instance (Consent Composition note 6).
Capability requirement 63: The alerting surface MUST retain EVERY alert AND the id the alert names for the audit horizon.
Capability requirement 64: The deployment MUST supply the database PER Execution Contract Database 1 through 4, Execution Contract Database 7, Execution Contract Read 1 through 3 AND Execution Contract Refusal 1.
Capability requirement 65: EVERY string the composition forwards to a constituent MUST NOT EXCEED the string cap the deployment declares for the constituent (Selective Disclosure Capability requirement 8, Consent Capability requirement 6).
Capability requirement 66: A deployment MUST disclose the commit round trip, the probe round trip, the run bound, the read bound, the closure latency, the settling period, the intent candidates cap AND the read cap PER Recoverable Invocation Instance start 4 through 8.
Capability requirement 67: A deployment MUST NOT admit two invocations of one request id carrying one now at Retention Window's time resolution (Recoverable Invocation pairing datum 4).
Capability requirement 68: A deployment MUST NOT destroy a Retention Window record a purge plan names BEFORE the audit horizon has run past the act's outcome (Recoverable Invocation Binding 9).
Capability requirement 69: A deployment MUST declare the plan cap, the largest number of planned calls one execution commit makes.
Capability requirement 71: A deployment MUST answer EVERY alert of Reconciliation 35 WITHIN the audit horizon less the entry bound of the recording instant of the fulfilled event the alert names.
Capability requirement 70: A deployment MUST set the payload cap of the audit instance PER Audit Trail payload cap 1 (Defensible Retention Capability requirement 75).
```

Term record source registry: the deployment-declared list of the business-record sources over which the no-silent-omission guarantee holds, with the per-record surfaces each exposes.

Term creation instant: the instant a record became one of the subject's in its source — its creation there, or a later linking of it to the subject — stamped by the source's own clock.

Term declared basis: the lawful ground a registered record names for its processing — consent carrying a purpose, a non-consent ground such as legal-obligation, contract or vital-interests, or none.

Term host determinations: the host's per-record Article 15(4) third-party-confidentiality and legal-exemption determinations, consumed by the access dispositions.

Term host delete: the registry-declared delete surface of a host-managed record — `delete(record_ref, actor_ref, credential)` answering deleted carrying the attestation reference, refusing invalid-credential, not-known, retained carrying the basis, or delete-failed.

Term route: how a registered record is erased, answered by the record's source in the enumeration itself — a retention id or the host delete (Capability requirement 5). A source that answers a record with no route has failed to enumerate (Action wiring 12).

Term host-managed record: a registered record whose route carries the host delete — erased through the host delete, never through Defensible Retention's gate.

Term accounting records: the Selective Disclosure records or the Consent records — the composition's accounting of the subject, read as response content and never enumerated.

Term audit retention policy: the retention policy of the Audit Trail instance Defensible Retention carries — the one policy the instance answers for every event it holds (Capability requirement 49, Defensible Retention Capability requirement 57), `audit_trail_retention_policy` in configuration.

Term audit horizon: the horizon of the one policy the audit retention policy answers for every event of the audit instance (Capability requirement 49) — the Audit Trail instance Defensible Retention carries.

Term hold guarantee: Defensible Retention Invariant 1 read over the records this composition's fulfillments purge — no record an active hold covers at the gate is destroyed through a fulfillment.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` in configuration — which is Recoverable Invocation's service identity for the act kind (Capability requirement 12).

Term clock offset allowance: the deployment's declared envelope between two clocks' readings of one moment (Execution Contract Logic confinement 7) — the value Defensible Retention reads under the same name — declared on the Recoverable Invocation instance (Capability requirement 20) and allowed here wherever a reading of now is set against a registered source's creation instant, a constituent's stamp or another invocation's reading of now.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the request id and the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it; Recoverable Invocation's run takes one reading of its own (Recoverable Invocation Primitive policy 18), and an intent's age against Recoverable Invocation's at-risk threshold is judged on the now of the run that makes the read.

Term invocation id: the id the host injects at the seam for one state-changing invocation — a [Receive Request] call or a fulfillment; for the act kind it is Recoverable Invocation's invocation id (Recoverable Invocation Term invocation id). Every record the invocation writes carries the id, and a record Recoverable Invocation's sweep writes carries the id of the intent the record closes.

Term planned call latency: the deployment's disclosed longest time from issuing a planned call to the landing of the call's last write, an abandoned call's included, and to the answer of the retention read a not-known obliges, from the call's issue, the origin Recoverable Invocation's commit round trip takes (Recoverable Invocation commit 6). It is the commit's unit and the plan span's (Check 6.3); a planned call that has not answered within it answers no answer.

Term entry bound: `((sweep_cadence + run_bound) + clock_offset_allowance)` — the age by which a Recoverable Invocation run has read a fulfilled event carrying no fulfillment entry and the index leg has written the entry, as an auditor reads it: a cadence to the next run, that run's bound, and the offset between the auditor's seam and the log's.

Term source text: a string a registered source or the host delete supplies and a reason carries whole — a purpose, a non-consent ground, a determination's reference, a host's basis or an attestation reference.

Term text cap: text_cap — the maximum size of one source text, counted in code points as Selective Disclosure's string cap counts them (Selective Disclosure Term string cap); 1,024 code points where a deployment declares none (Execution Contract Input 2). The largest record is sized in bytes (Term largest record).

Term id cap: id_cap — the deployment's declared longest id a record carries: a request id, an invocation id, a retention id, a hold id, a disclosure id or an event id.

Term reason bound: the size of the largest reason a disposition can carry — its ids at the id cap, its answers and its instants at their longest, EVERY source text at the text cap, each at its longest encoding, and, for an erasure disposition alone, the hold ids at Defensible Retention's hold ids cap. No reason is truncated.

Term alerting surface: the deployment's surface on which the composition and the deployment alert. An alert names what it rests on — an intent's invocation id, an event's id, a request id or a run — and the surface keeps it for the audit horizon (Capability requirement 63), so an auditor reads an alert as a record, with its instant. An alert is answered when what it names no longer holds: the intent closed, the entry or the mark written, a later run's end.

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
Primitive policy 15: IF the request id EQUALS blank THEN a fulfillment AND [Disposition Report] MUST answer not-known AND MUST NOT write.
```

Term invalid-request: the one refusal of an input or a configuration no retry cures, committing nothing in every case (Execution Contract Database 1): a blank input other than the request id or a right type outside access and erasure (Primitive policy 1 through 5), a largest record over the payload cap (Primitive policy 13), a plan over the plan cap (Action wiring 54), a disclosure fault (Action wiring 21, Action wiring 21a) and Audit Trail's refusal below step-4 (Audit arm 20, Action wiring 21a). A caller's fault and a deployment's differ in who repairs it, not in what the call did, so one code carries both and the deployment alerts on each a fulfillment answers (Audit arm 19). [Fulfill Erasure Request]'s carries the side of the commit it lands on (Action wiring 21a, Action wiring 21b; Recoverable Invocation Action wiring 1).

Term subject reference: the opaque reference to the data subject whose records are the universe.

Term right type: access | erasure — GDPR Article 15 or Article 17.

Term requester: the party who submitted the request — the subject, or an authorized representative; named as the recipient of the response disclosure.

Term regulatory reference: the regulation a request is filed under — "GDPR Article 15", "CCPA section 1798.105" — carried as the response disclosure's authority.

Term actor reference: the operator running an action — actor_ref.

Term credential: the operator's opaque credential material, validated by the substrate inside the audit write.

Term record reference: the opaque byte-identity of a record in the enumerated universe — the unit a disposition is recorded against.

Term retention id: the opaque Defensible Retention handle of a record under Defensible Retention retention — the input its purge takes.

Term caller string: a subject reference, a requester, a regulatory reference, an actor reference or a record reference.

Term largest record: the larger of a fulfillment's intent and the executed outcome or fulfilled event the fulfillment closes with, each sized whole in bytes of the serialized envelope Audit Trail measures (Audit Trail payload cap 2) — every field the record carries, every id at the id cap — with every disposition's reason at the reason bound.

### Audit arm

```
Audit arm 2: The composition MUST read an invalid-request carrying step-4 as a landed record.
Audit arm 6: IF Audit Trail answers invalid-credential at a pre-effect record THEN the action MUST answer invalid-credential.
Audit arm 7: IF Audit Trail answers recording-failure carrying a step below step-4 OR no answer at a pre-effect record THEN the action MUST answer recording-failure carrying intent (Recoverable Invocation Term position), nothing having committed (Execution Contract Database 1).
Audit arm 18: The deployment MUST alert on a landed record carrying no retention.
Audit arm 19: The deployment MUST alert on an invalid-request a fulfillment answers.
Audit arm 20: IF Audit Trail answers invalid-request carrying a step below step-4 at a pre-effect record THEN the action MUST answer invalid-request.
Audit arm 21: A writer MUST NOT issue the same audit write a second time.
Audit arm 25: A recording-failure [Receive Request] answers MUST carry the request id.
Audit arm 26: A caller MUST read a recording-failure from [Receive Request] as a request possibly Received under the carried request id, AND MUST read [Disposition Report]'s not-known of the carried request id as final only once the audit write latency has elapsed since the call (Capability requirement 45).
Audit arm 28: The deployment MUST alert on a record whose route names a retention id no retention carries, a record read as purged on a sibling retention included.
```

Term writer: one invocation — what issues each audit write once. For the act kind the close follows Recoverable Invocation Primitive policy 29 and 33.

Term pre-effect record: the intake event or the access intent — a record the composition writes before any irreversible act. The act kind's intent is the one Recoverable Invocation's open writes and is no pre-effect record of this composition.



### Action wiring

```
receive_request(subject_ref, right_type, requester, regulatory_reference, actor_ref, credential)
  answers intake result
  refuses invalid-request | invalid-credential | recording-failure(position, request_id)

fulfill_access_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | wrong-right-type | incomplete-enumeration | state-unavailable | invalid-credential | invalid-request | recording-failure(intent)

fulfill_erasure_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | compensation-pending | act-in-flight(invocation_id) | journal-unavailable | wrong-right-type | incomplete-enumeration | section-unavailable | state-unavailable | invalid-credential | invalid-request(position) | recording-failure(position)

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
Action wiring 6: IF the request's state EQUALS Committing AND an intent of the act kind stands open THEN [Fulfill Erasure Request] MUST answer act-in-flight carrying the invocation id (Recoverable Invocation Action wiring 4).
Action wiring 7: A fulfillment MUST NOT check the right type BEFORE checking the request's state.
Action wiring 8: IF the request's state IS IN Received and Committing AND the right type DOES NOT EQUAL access THEN [Fulfill Access Request] MUST answer wrong-right-type.
Action wiring 9: IF the request's state EQUALS Received AND the right type DOES NOT EQUAL erasure THEN [Fulfill Erasure Request] MUST answer wrong-right-type.
Action wiring 10: A refusal under Action wiring 4 through 9 MUST NOT record an event.
Action wiring 11: An admitted fulfillment MUST enumerate the subject's universe through the universe enumeration.
Action wiring 12: IF a registered source fails to enumerate OR answers no answer to the enumeration THEN the fulfillment MUST answer incomplete-enumeration.
Action wiring 13: A fulfillment answering incomplete-enumeration MUST NOT record an event.
Action wiring 15: An enumerated access MUST read the disclosure read AND Consent's read for the subject.
Action wiring 16: An enumerated access MUST record the access intent carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read AND now as the intended instant.
Action wiring 17: The composition MUST NOT call the disclosure write BEFORE the fulfillment's intent lands.
Action wiring 18: An intended access MUST call the disclosure write with the subject reference, the requester as the recipient, the access scope AND the response authority.
Action wiring 21: IF a disclosure fault EXISTS for an access THEN [Fulfill Access Request] MUST answer invalid-request, nothing having committed (Execution Contract Database 1).
Action wiring 21a: IF a disclosure fault EXISTS for an erasure's disclosure write (Action wiring 28, Action wiring 52) OR Audit Trail answers invalid-request carrying a step below step-4 at an erasure's fulfilled event (Action wiring 31) THEN [Fulfill Erasure Request] MUST answer invalid-request carrying outcome, the transaction of the close or the bind committing nothing (Execution Contract Database 1) and the act left executed, the act's intent open where the close faulted and closed where the bind did.
Action wiring 21b: An invalid-request [Fulfill Erasure Request] answers other than Action wiring 21a's MUST carry intent.
Action wiring 22: A disclosed access MUST record the access fulfilled event carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read, the response disclosure id AND now as the fulfilled instant.
Action wiring 24: An enumerated erasure MUST open the act kind, the intent carrying the request id, the invocation id, the subject reference, the requester, the provisional dispositions, the universe cardinality, the purge plan, the host delete plan AND now as the intended instant AND the pairing datum.
Action wiring 25: An intended erasure MUST call Defensible Retention's purge PER pair of the purge plan with the retention id, the actor reference AND the credential.
Action wiring 26: An intended erasure MUST call the host delete PER record of the host delete plan with the record reference, the actor reference AND the credential.
Action wiring 27: An intended erasure MUST settle each planned record's disposition from the planned call's answer.
Action wiring 28: An executed erasure MUST call the disclosure write with the subject reference, the requester as the recipient, the erasure scope AND the response authority, in the transaction the close commits in.
Action wiring 31: A disclosed erasure MUST record the erasure fulfilled event carrying the request id, the invocation id, the subject reference, the requester, the dispositions, the universe cardinality, the response disclosure id, the closing event id of the act AND now as the fulfilled instant.
Action wiring 33: A landed fulfillment MUST write the fulfillment entry AND answer the fulfillment result.
Action wiring 34: IF the rebuild of Composition state 20 answers no request entry for the request id THEN [Disposition Report] MUST answer not-known.
Action wiring 35: IF the state read answers the request's state THEN [Disposition Report] MUST answer the report.
Action wiring 36: [Disposition Report] MUST NOT record an audit event.
Action wiring 37: IF the disclosure read OR Consent's read fails, answers invalid-query OR answers no answer for an enumerated access, a failure the state read answered state-unavailable (Composition state 22) excepted, THEN [Fulfill Access Request] MUST answer incomplete-enumeration.
Action wiring 38: IF the retention read of Action wiring 41 fails OR answers no answer THEN [Fulfill Erasure Request] MUST answer incomplete-enumeration.
Action wiring 40: An intended erasure MUST make the planned calls in the purge plan's order AND the host delete plan's order.
Action wiring 41: An enumerated erasure MUST read the retention read.
Action wiring 42: IF a planned purge answers not-known THEN the fulfillment MUST read the retention read filtered by the record reference (Retention Window Operation 37).
Action wiring 43: IF the request's state EQUALS Committing AND no intent of the act kind stands open AND the standing closing of the act kind's intent is `.escalated` THEN [Fulfill Erasure Request] MUST answer compensation-pending.
Action wiring 44: IF the request's state EQUALS Committing AND no intent of the act kind stands open AND the standing closing of the act kind's intent is `.executed` AND no fulfilled event names the request THEN [Fulfill Erasure Request] MUST run the re-entry bind.
Action wiring 45: An enumerated erasure MUST NOT issue the execution commit BEFORE the open of the act kind returns.
Action wiring 46: IF the execution commit answers committed THEN the action MUST write the disclosure, the erasure fulfilled event AND the executed outcome in one transaction.
Action wiring 47: IF the execution commit answers pre-commit THEN the action MUST refuse the act AND answer the constituent's code (Recoverable Invocation commit 2).
Action wiring 48: IF the execution commit answers unknown THEN the action MUST yield the act AND answer recording-failure carrying outcome.
Action wiring 49: The re-entry bind MUST seal EVERY record outside the plans with the disposition of the intent.
Action wiring 50: The re-entry bind MUST seal a purge plan pair the standing closing shows purged as erased with the pair's retention id AND purge instant, the data of an operator's closing being detected and not validated (Recoverable Invocation Check 6.1).
Action wiring 51: The re-entry bind MUST seal EVERY other planned record anomaly carrying unsettled, a host delete plan record included.
Action wiring 52: The re-entry bind MUST write the disclosure, the erasure fulfilled event AND the fulfillment entry in one transaction under the caller's credential.
Action wiring 53: The execution commit MUST NOT make the first planned call BEFORE the retention read of EVERY host delete plan record.
Action wiring 54: IF the purge plan AND the host delete plan together EXCEED the plan cap THEN [Fulfill Erasure Request] MUST answer invalid-request, nothing written.
Action wiring 55: An enumerated erasure MUST issue the execution commit WITHIN Recoverable Invocation's pause bound of the open's return (Recoverable Invocation commit 15).
Action wiring 56: IF the retention read of Action wiring 53 fails OR answers no answer THEN the execution commit MUST make no planned call AND MUST answer pre-commit carrying incomplete-enumeration.
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

Term erasure intent: the dsar.erasure_execution.intended record.

Term provisional dispositions: the dispositions Disposition 1 through 19, 39 and 40 resolve before any planned call runs.

Term purge plan: the confirmed retention id and record reference pairs bound for Defensible Retention's purge, ordered by record reference, rising (Execution Contract Logic confinement 10) — the order the calls are made in.

Term host delete plan: the record references bound for the host delete, ordered by record reference, rising (Execution Contract Logic confinement 10) — the order the calls are made in, after the purge plan's.

Term destroying surface: Defensible Retention's purge or the host delete.

Term planned call: a call of a destroying surface the plans name — Defensible Retention's purge for a purge plan pair, the host delete for a host delete plan record.

Term planned record: a record the purge plan or the host delete plan names.

Term intended erasure: an enumerated erasure whose open returned the act's invocation id.

Term executed erasure: an intended erasure whose every planned record carries a settled disposition — from a planned call's answer, or unsettled where the plan cap admitted no call (Disposition 45).

Term erasure scope: dsar:erasure:outcome: followed by the request id.

Term disclosed erasure: an executed erasure whose disclosure write answered the response disclosure id.

Term re-entry bind: the caller's own call that seals an erasure whose act closed `.executed` with no fulfilled event: a store-only transaction under the caller's credential, writing the disclosure, the fulfilled event and the entry (Action wiring 44, 49 through 52).

Term plan cap: the deployment's declared bound (Capability requirement 69) on the planned calls one execution commit makes; it admits a further planned call while fewer planned calls than the cap have been made.

Term landed fulfillment: a disclosed access or a disclosed erasure whose fulfilled event landed.

#### Closure table

Every input an action takes and every answer a call of the four actions can meet — Audit Trail's record_action, Selective Disclosure's record and read, Consent's read, Defensible Retention's purge and retention read, the host delete, and Recoverable Invocation's open, the invocation close, the invocation refuse and the invocation yield around [Fulfill Erasure Request]'s execution commit — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1, Execution Contract Constituent failure 3); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here. [Receive Request] and [Fulfill Access Request] are each one transaction, and every refusal of either commits nothing (Execution Contract Database 1, Execution Contract Read 4), except that an attempt record Audit Trail commits at step-4 stays committed beside the refused action (Audit arm 2). [Fulfill Erasure Request]'s intent is committed ahead of its planned calls by the invocation open (Execution Contract Database 3), and its planned calls answer outside the store. [Disposition Report] is a read. The sweep's the invocation reconcile, the operator's the invocation resolve and the invocation read are not called around the commit, and Recoverable Invocation's own closure table lands them.

**Inputs.**

| Action | Input | Lands | Owner |
|---|---|---|---|
| every action | a blank required input other than the request id, or a right type outside access and erasure | invalid-request, nothing written, carrying intent for [Fulfill Erasure Request] | Primitive policy 1 through 6, Action wiring 21b |
| a fulfillment, [Disposition Report] | a blank request id | not-known, nothing written | Primitive policy 15 |
| [Fulfill Erasure Request] | a purge plan and a host delete plan together over the plan cap | invalid-request carrying intent, nothing written | Action wiring 54, Action wiring 21b |
| a fulfillment | the largest record over the payload cap | invalid-request, nothing written, carrying intent for [Fulfill Erasure Request] | Primitive policy 12 through 14, Action wiring 21b |

**Audit Trail's record_action** (the intake event, the access intent and both fulfilled events).

| Answer | Lands | Owner |
|---|---|---|
| event id | the record landed; the action goes on | Action wiring 3, 16, 22, 31 |
| invalid-credential | invalid-credential, nothing written | Audit arm 6 |
| recording-failure, or no answer | recording-failure carrying intent, nothing committed | Audit arm 7, Execution Contract Database 1 |
| invalid-request at step-4 | the record read as landed | Audit arm 2 |
| invalid-request below step-4 | invalid-request, nothing written; at an erasure's fulfilled event, invalid-request carrying outcome, nothing committed | Audit arm 20, Action wiring 21a |
| state-unavailable | state-unavailable, nothing written | Execution Contract Constituent failure 3 |

**Selective Disclosure's record** (the response disclosure of an access, and of an erasure's bind).

| Answer | Lands | Owner |
|---|---|---|
| a disclosure id | the disclosure written; the action goes on to its fulfilled event | Action wiring 18, 28 |
| invalid-request, unknown-authority-type | invalid-request, nothing committed, carrying outcome for an erasure | Action wiring 21, Action wiring 21a |
| storage-failure, or no answer | the transaction aborts, recording-failure carrying intent for an access; an erasure's close lands recording-failure carrying outcome | Audit arm 7, Execution Contract Database 1, Action wiring 46 |

**The disclosure read, Consent's read and the retention read.**

| Answer | Lands | Owner |
|---|---|---|
| a failure, invalid-query or no answer | incomplete-enumeration | Action wiring 37, 38 |
| Consent's check of a record's basis (an erasure): a failure, state-unavailable or no answer | the record anomaly carrying determination-unavailable | Disposition 40 |
| the retention re-read of a host delete plan record, inside the execution commit: a failure or no answer | pre-commit, the act refused, incomplete-enumeration answered | Action wiring 56 |
| a failed state read | state-unavailable | Composition state 22 |

**Defensible Retention's purge** (a purge plan pair, inside the execution commit).

| Answer | Lands | Owner |
|---|---|---|
| ok | erased carrying the retention id | Disposition 20 |
| not-known, then the retention read purged | erased carrying the retention id and the purge instant | Action wiring 42, Disposition 43 |
| held | retained carrying legal-hold | Disposition 21 |
| obliged | retained carrying retention-obligation | Disposition 22 |
| no answer, or unsettled | anomaly carrying unsettled | Disposition 42 |
| unknown | anomaly carrying unknown-retention | Disposition 44 |

**The host delete** (a host delete plan record, inside the execution commit).

| Answer | Lands | Owner |
|---|---|---|
| deleted | erased carrying the attestation reference | Disposition 32 |
| retained | retained carrying other-lawful-basis | Disposition 33 |
| not-known | anomaly carrying host-record-not-found | Disposition 34 |
| delete-failed, invalid-credential, an answer outside its contract, or no answer | anomaly carrying unsettled | Disposition 35, 36 |

**Recoverable Invocation's open, close, refuse and yield** (around the execution commit).

| Answer | Lands | Owner |
|---|---|---|
| the open's invocation id | the intent committed; the execution commit follows | Action wiring 24, 45 |
| act-in-flight | act-in-flight carrying the invocation id | Action wiring 6 |
| act-landed | the re-entry bind, or already-fulfilled | Action wiring 44 |
| invalid-credential, invalid-request, section-unavailable, journal-unavailable, recording-failure | the same code, the open having committed nothing | Recoverable Invocation Action wiring 4 |
| the execution commit answers committed | the disclosure, the fulfilled event and the executed outcome in one transaction | Action wiring 46 |
| the execution commit answers pre-commit | the act refused, the constituent's code answered | Action wiring 47 |
| the execution commit answers unknown | the act yielded, recording-failure carrying outcome | Action wiring 48 |
| the close's recording-failure | recording-failure carrying outcome, the act the sweep's | Action wiring 46 |

### Wiring decision

```
Wiring decision 2: The composition MUST bind the dispositions, the response disclosure AND the fulfilled event as one landed fulfillment.
Wiring decision 4: The composition MUST read an erasure's preservation dispositions off Defensible Retention's purge.
Wiring decision 5: The composition MUST NOT evaluate a hold.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* A rights response an auditor can trust needs two facts inseparable: that *every* record in the subject's universe was accounted for, none silently dropped, and that the account is itself immutable, attributed and tamper-evident.

*Likely objection.* Why not let each constituent answer for its own records and union the answers?

*Mechanism.* No constituent enumerates the *universe*, and a union of per-constituent answers has no completeness guarantee — a record in a host database no constituent governs is simply absent, and absence is invisible to a reader who sees only what *was* returned. The composition computes the universe once over the declared registry, dispositions every record (Disposition 1), and binds the set, the response disclosure and the sealed event as one fulfillment (Wiring decision 2); a response disclosure with no sealed event behind it cannot stand, since the disclosure and the sealed event commit together (Invariant 1).

*Result.* An auditor reads one fulfillment and sees a verdict for every record the declared universe contains — no-silent-omission — non-repudiable and tamper-evident, which no constituent provides alone.

*Principle.* *Delete this* and *you may not delete this* cannot both hold; the resolution must be structural and records-checkable, not a runtime check a well-meaning operator can talk past.

*Likely objection.* Doesn't a rights-fulfillment system need its own hold and retention logic?

*Mechanism.* No — re-deriving hold checking would duplicate exactly the gate Defensible Retention already owns and proves (its Invariant 1), and its purge is irreversible and self-audits each destruction. The composition maps the gate's answers onto dispositions (Wiring decision 4 and 5; Disposition 20 through 46), inheriting its structural guarantee and its retention exemption for free, and adds the one concept the substrate does not carry — the Article 17(1)(b) question of whether another lawful basis means erasure was never due, read-only and ahead of any purge (Disposition 7 through 12).

*Result.* Every preservation disposition traces to a records-checkable Defensible Retention outcome, and the composition stays a thin conflict-resolution-and-accounting layer over a proven substrate rather than a re-implementation of it.

</details>

### Reconciliation

```
Reconciliation 25: The index leg MUST write the index entry of EVERY intake event AND EVERY fulfilled event carrying none, once per Recoverable Invocation run, on the run's now (Execution Contract Scheduled leg 2).
Reconciliation 34: IF the trail read the index leg's run enumerates from fails THEN the index leg MUST alert.
Reconciliation 35: IF the index write of Reconciliation 25 fails THEN the reconciliation MUST alert.
Reconciliation 36: The index leg MUST write the index entry of EVERY intake event AND EVERY fulfilled event the run's enumeration answers carrying none WITHIN the run, a write Reconciliation 35 alerts on excepted.
Reconciliation 38: The index leg MUST write the stall mark of EVERY intent of the act kind that stands open past Recoverable Invocation's at-risk threshold, the request carrying no fulfilled event, a write Reconciliation 39 alerts on excepted.
Reconciliation 39: IF the write of a stall mark fails THEN the reconciliation MUST alert.
Reconciliation 40: IF the index leg fails to end WITHIN Recoverable Invocation's run bound THEN the deployment MUST alert.
Reconciliation 41: A run MUST record the end of the run's enumeration on the alerting surface.
Reconciliation 42: The index leg MUST write the stall mark of EVERY intent of the act kind whose standing closing is escalated, the request carrying no fulfilled event, a write Reconciliation 39 alerts on excepted.
```

Term reconciliation: the index leg the composition runs once per Recoverable Invocation run (Execution Contract Scheduled leg 2), paired with Recoverable Invocation's sweep: it writes the index entries and the stall marks and alerts on what it cannot write; the sweep, not the leg, closes or escalates an intent.

Term request-scoped disclosure: a Selective Disclosure record whose scope is a request scope — selected in the composition's own code, byte-exact on the scope, from the disclosure read of the subject reference, since Selective Disclosure offers no filter by scope.

Term destruction record: Defensible Retention's record_purged outcome.

Term destroyed planned record: a purge plan pair whose retention reading EQUALS purged. A host delete plan record is never one: no declared surface says a host-managed record is gone, so the re-entry bind seals it unsettled, and a second request racing on a host-managed record another request deleted lands host-record-not-found (Disposition 34) where the gated twin lands erased (Disposition 43).

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
Disposition 9: IF a record's declared basis names consent THEN the composition MUST call Consent's check with the subject reference AND the purpose the declared basis carries.
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
Disposition 32: IF the host delete answers deleted THEN the record MUST carry erased carrying the attestation reference.
Disposition 33: IF the host delete answers retained AND the host's basis DOES NOT EXCEED the text cap AND the host's basis DOES NOT EQUAL blank THEN the record MUST carry retained carrying other-lawful-basis AND the host's basis.
Disposition 34: IF the host delete answers not-known THEN the record MUST carry anomaly carrying host-record-not-found.
Disposition 35: IF the host delete answers delete-failed OR invalid-credential THEN the record MUST carry anomaly carrying unsettled.
Disposition 36: IF the host delete answers outside the host delete's contract THEN the record MUST carry anomaly carrying unsettled.
Disposition 38: The composition MUST read a fulfillment carrying an anomaly as Fulfilled.
Disposition 39: IF an erasure-due record's retention reading EQUALS purged THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 40: IF a record's basis reading EQUALS unread THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 41: IF a purge's first answer IS IN the retry answers AND the plan cap admits a further planned call THEN the composition MUST re-invoke the purge once, straight away and ahead of the next planned call, without waiting for the substrate's section term, which the invocation completion bound does not admit (Term erasure binding); a retry that meets a retry answer is the purge's last answer and is not repeated (Term purge reading).
Disposition 42: IF a planned record's purge reading EQUALS unsettled THEN the record MUST carry anomaly carrying unsettled.
Disposition 43: IF a planned record's purge reading EQUALS gone THEN the record MUST carry erased carrying the retention id AND the purge instant.
Disposition 44: IF a planned record's purge reading EQUALS unknown THEN the record MUST carry anomaly carrying unknown-retention.
Disposition 45: IF the plan cap admits no further planned call THEN EVERY planned record no planned call settled MUST carry anomaly carrying unsettled.
Disposition 46: A disposition a planned call's answer settles MUST carry the answer in the reason.
Disposition 47: The deployment MUST alert on a fulfilled event carrying an anomaly.
Disposition 48: A deployment MUST settle EVERY record carrying unsettled in a fulfilled event.
Disposition 49: IF a record's basis reading IS IN ground AND granted THEN the composition MUST NOT take the record's retention reading.
```

Term disposition: a record's verdict — [Included] or [Withheld] for access; [Erased], [Retained] or [Anomaly] for erasure, [Anomaly] for access too.

Term verdict: included | withheld | erased | retained | anomaly. The planned of Disposition 19 is the provisional marker of a planned record and no verdict: a planned call's answer settles it (Action wiring 27), the plan cap's lack of a call or the re-entry bind seals it unsettled (Disposition 45, Action wiring 51), and no fulfilled event carries it.

Term anomaly reason: the one meaning each anomaly reason names, the cause the answer it carries gives (Disposition 46). determination-unavailable: a read that should have settled the record answered nothing (Disposition 5, Disposition 40). consent-basis-not-known: Consent's check does not know the subject and purpose (Disposition 11). mis-paired: the retention read and the registry disagree on the pairing of record and retention (Disposition 14). unknown-retention: the retention the record names is not borne out by the database (Disposition 15, Disposition 44). host-record-not-found: the host delete answers not-known (Disposition 34). unsettled: a planned call's fate is unsaid, or the plan cap admitted no call (Disposition 35, 36, 42, 45).

Term withdrawn answer: revoked | expired — Article 17(1)(b)'s consent withdrawn, or lapsed.

Term determination reading: failed | third-party-confidentiality | legal-exemption | no-bar — what the host determinations say of a record of an access, exactly one of the four and the first that holds in this order: failed where the surface fails for the record, answers no answer or answers a source text over the text cap or equal to blank; third-party-confidentiality where the determinations name that bar, alone or beside a legal exemption; legal-exemption where the determinations name a legal exemption and no third-party confidentiality; no-bar everywhere else.

Term basis reading: unread | ground | granted | not-known | withdrawn | none — what a record's declared basis and Consent's check say of a record of an erasure, an unread one sealing anomaly and destroying nothing where an access answers incomplete-enumeration to a failed Consent read (Action wiring 37), since an access reads Consent whole as response content and an erasure judges one record by its check, exactly one of the six and the first that holds in this order: unread where the declared basis fails or carries a source text over the text cap, or names consent and Consent's check fails, answers state-unavailable (Execution Contract Read 1) or answers no answer; ground where the declared basis names a non-consent ground; granted, not-known or withdrawn where the declared basis names consent and Consent's check answers granted, not-known or a withdrawn answer; none where the record declares no basis.

Term erasure-due record: an enumerated record of an erasure whose basis reading EQUALS withdrawn or none — a record no basis preserves and no failed read holds back.

Term retention reading: unread | clear | absent | mis-paired | purged | retained — what the retention read says of a registered record and the record's route, exactly one of the six and the first that holds in this order: unread where the read gave no answer; for a host-managed record, mis-paired where the read answers a retention over the record reference, and clear where the read answers none; for a record whose route carries a retention id, mis-paired where the read pairs the id with another record reference; purged where the record stands as a destroyed record in Defensible Retention's own sense — the read answers a purged retention over the record reference, the named retention or a sibling, a named id no retention carries included; absent where the read answers no retention carrying the id and no purged retention covers the record reference; and retained everywhere else. A host-managed record whose reference a purged retention covers reads mis-paired and is sealed anomaly (Disposition 14), and a record sealed erased on a purged reading is no anomaly and raises no anomaly alert (Disposition 47), the registry fault of Audit arm 28 apart; a record a basis preserves takes no reading (Disposition 49), so one that stands destroyed is sealed retained on its basis. An erased disposition sealed on a purged reading carries the retention id and the purge instant of the retention the reading rests on — the named retention's where the database answers it purged, and otherwise those of the purged sibling whose retention id stands lowest, bytewise; the substrate's destruction record of the record names that id among its purged retention ids, each marked purged (Defensible Retention's sibling disposition value set holds purged alone).

Term settled record: a record Disposition 7, 10, 11, 14, 15, 39 or 40 dispositions before any planned call — every record of an erasure that Disposition 17 and Disposition 18 add to no plan.

Term planned: the provisional marker of a record in the purge plan or the host delete plan, settled by the planned call's answer.

Term retry answers: section-unavailable | hold-check-unavailable | storage-failure | state-unavailable | recording-failure carrying intent | recording-failure carrying gate | recording-failure carrying outcome — the purge answers under which the call reports no destruction and a later call can answer otherwise. The intent, gate and outcome positions are Defensible Retention's own, of its purge's records, and not this composition's position. state-unavailable is the failed read of Execution Contract Read 1 (Execution Contract Constituent failure 3); Defensible Retention lands each read its purge makes as storage-failure or recording-failure carrying outcome (Defensible Retention Action wiring 98, 99 and 109), so a conforming purge never answers it, and one that does is read beside storage-failure: a failed read says nothing of the record.

Term unsettling answers: the retry answers | invalid-credential | invalid-request | no answer — the purge answers that leave a record's fate unsaid.

Term purge's first answer: the answer of the one call Action wiring 25 makes for a purge plan pair.

Term purge's last answer: the re-invoked purge's answer where the composition re-invoked the purge, and the purge's first answer everywhere else.

Term purge reading: destroyed | gone | unsettled | held | obliged | unknown — what the answers of a purge plan pair's calls say of the pair's record, exactly one of the six and the first that holds in this order: destroyed where the last answer EQUALS ok; gone where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS purged; unsettled where the first answer or the last EQUALS storage-failure or no answer, where the last answer is any other unsettling answer, or where the last answer EQUALS not-known and the retention reading taken after the answer EQUALS unread; held where the last answer EQUALS under-legal-hold; obliged where the last answer EQUALS not-eligible or under-active-retention; unknown everywhere else — a not-known the database does not bear out. Every answer of Defensible Retention's purge falls under one of the six, so Disposition 20 through 22 and 42 through 44 settle a called record once.

Term outside the host delete's contract: said of a host delete that answers no answer, an answer that is no arm of the host delete's contract, or an arm carrying a source text over the text cap or equal to blank. Such an answer says nothing the composition can rest on, not even that the record survives under the arm it names, a retained carrying a basis over the text cap included: Disposition 36 seals the record unsettled and Disposition 47 alerts.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Binding bijection.**
  ```
  Invariant 1.1: A fulfilled event MUST NOT exist without the fulfillment's response disclosure AND complete dispositions.
  Invariant 1.2: EVERY Fulfilled request MUST carry EXACTLY ONE fulfilled event, a request whose fulfilled event's payload the audit instance has destroyed excepted.
  Invariant 1.3: EVERY fulfilled event MUST name EXACTLY ONE Fulfilled request.
  Invariant 1.4: EXACTLY ONE fulfilled event MUST name EVERY request-scoped disclosure.
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
  Term destruction evidence: for a record whose route carries a retention id, a purge of the record's retention that answered ok, or a retention reading that EQUALS purged; for a host-managed record, a host delete that answered deleted.

- **Invariant 4 — Disposition groundedness.**
  ```
  Invariant 4.1: EVERY disposition's reason MUST name the authority the disposition rests on, an anomaly disposition excepted.
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
  Invariant 8.1: The composition MUST NOT write the disclosure under a credential Audit Trail did not validate (Execution Contract Database 1).
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
  - **Records the intent, then binds the fulfillment (disclosure next, sealed event last):** one transaction on `dsar-3001`: `dsar.access_fulfillment_intended` lands carrying `inv-71`, the five dispositions and the ids read; then `SelectiveDisclosure.record(subject_ref = "user-5521", recipient = "user-5521 (verified via privacy portal)", scope = "dsar:access:designated-record-set:dsar-3001", authority = {type: regulatory, reference: "GDPR Article 15"})` → `disc-9001`; then `AuditTrail.record_action(action_ref = dsar.access_fulfilled, actor_ref = "dsr_officer_k", <cred>, data = {request_id: "dsar-3001", invocation_id: "inv-71", subject_ref: "user-5521", requester: "user-5521 (verified via privacy portal)", dispositions: <the complete five-record set, summary: 3 included / 2 withheld>, universe_cardinality: 5, recipients: <the two disclosure ids read>, consents: <the consent ids read>, response_disclosure_id: "disc-9001", fulfilled_at})` → `ev-7001`; then `request_to_fulfillment["dsar-3001"] = {access, fulfilled_at, dispositions (all five), response_disclosure_id: "disc-9001", fulfillment_event_id: "ev-7001"}`. The request is now **Fulfilled**.
  - Returns the five dispositions, `disc-9001`, and `ev-7001`.

3. **The auditor reads the outcome.** `disposition_report("dsar-3001")` returns one verdict for each of the five enumerated records — Invariant 2 (no-silent-omission): nothing was quietly dropped, and the two withheld records carry a stated reason rather than vanishing from the response. The host then assembles and transmits the actual export for the three included records (the export bytes are the host's job; this composition recorded *what was decided and disclosed*).

### Walkthrough — GDPR Article 17 erasure request, the hold gate firing

A bank deploys this composition over its customer records; the Defensible Retention substrate runs `hold_check_mode = strict` (the required posture under litigation exposure). A customer requests erasure.

1. **Intake.** `receive_request(subject_ref = "cust-8830", right_type = "erasure", requester = "cust-8830", regulatory_reference = "GDPR Article 17", actor_ref = "dsr_officer_m", credential = <cred>)` → `{request_id = "dsar-4002", received_at}`. `dsar.received` recorded; **Received**.

2. **Fulfillment.** `fulfill_erasure_request("dsar-4002", "dsr_officer_m", <cred>)`. The composition **enumerates** four in-scope records, confirms each retention id against the retention read, resolves each record by the disposition precedence, and opens the act (`dsar.erasure_execution.intended`, taking Recoverable Invocation's critical section on `dsar-4002`) — carrying every provisional disposition and the purge plan `{ret-r1, ret-r2, ret-r3}` — before the first purge:
  - `r1` — a marketing profile under Defensible Retention retention `ret-r1` (retention elapsed, no hold), declared basis `consent(marketing:email)`. Other-lawful-basis probe: `Consent.check("cust-8830", "marketing:email")` → revoked → erasure is due. `purge_record(ret-r1, "dsr_officer_m", <cred>)` → `ok` → **erased**. (Defensible Retention records its own `record_purged` event with `hold_check_result: empty`.)
  - `r2` — a transaction record under `ret-r2`, covered by an Active litigation hold. Other-lawful-basis: none. `purge_record(ret-r2, …)` → `under-legal-hold` → **`retained(legal-hold)`** (Article 17(3)(e)), reason carrying the blocking `hold_id`. **The hold gate fires** — this is the collision this composition exists to resolve, read directly off Defensible Retention's gate. (Defensible Retention records a `purge_blocked_by_hold` event.)
  - `r3` — a Customer Due Diligence identity record under `ret-r3`, a 5-year retention obligation not yet elapsed. Other-lawful-basis: none asserted. `purge_record(ret-r3, …)` → `not-eligible` → **`retained(retention-obligation)`** (Article 17(3)(b)).
  - `r4` — a fraud-monitoring record whose declared basis is `legal-obligation` (AML — Anti-Money-Laundering — monitoring), a non-consent lawful ground still in force. Other-lawful-basis probe matches first → **`retained(other-lawful-basis)`** (Article 17(1)(b) — a ground for processing persists); **no `purge_record` call is made** for `r4`.
  - **Binds the fulfillment (disclosure first, sealed event last):** `SelectiveDisclosure.record(subject_ref = "cust-8830", recipient = "cust-8830", scope = "dsar:erasure:outcome:dsar-4002", authority = {type: regulatory, reference: "GDPR Article 17"})` → `disc-9002`; then `AuditTrail.record_action(action_ref = dsar.erasure_fulfilled, …, data = {request_id: "dsar-4002", invocation_id: "inv-88", subject_ref: "cust-8830", requester: "cust-8830", dispositions: <the complete four-record set, summary: 1 erased / 3 retained>, universe_cardinality: 4, response_disclosure_id: "disc-9002", closing_event_id: <the act's executed closing>, fulfilled_at})` → `ev-7002`; then `request_to_fulfillment["dsar-4002"]` is populated. **Fulfilled.**

3. **The outcome is provably defensible.** `disposition_report("dsar-4002")` shows all four records dispositioned (Invariant 2): one erased, three retained with three *different* reasons, each traceable (Invariant 4) — `r2` and `r3` to their Defensible Retention `purge_record` outcomes, `r4` to the host-declared AML basis, `r1`'s erasure to a `record_purged` event whose `hold_check_result: empty` proves the gate passed. No held or retention-bound record was erased (Invariant 3). The customer is told, in the response disclosure, exactly what was deleted and what was kept and why.

### Rejection path — re-fulfillment, wrong right type, incomplete enumeration

- **Already fulfilled (terminal).** A retry: `fulfill_erasure_request("dsar-4002", …)` → already-fulfilled. No second purge, no second disclosure, no second event — `r1` is not erased twice (it is already gone); the single fulfillment from the first call stands (Invariant 6).
- **Wrong right type.** For a *Received, not-yet-fulfilled* erasure request — say `dsar-4003`, intake recorded but no fulfillment yet — `fulfill_access_request("dsar-4003", …)` → wrong-right-type; the access sibling refuses to fulfill an erasure request. Nothing is recorded. (Against an *already-fulfilled* request the state check answers [Already Fulfilled] *before* the right type is read (Action wiring 7) — terminality dominates wrong-right-type — so the wrong-right-type path is exercised only by a request still Received or Committing, an erasure request whose act is open.)
- **Incomplete enumeration (the no-silent-omission guard).** During an access fulfillment, one registered source — the support-ticket records — is unreachable. The enumeration cannot be completed over the declared universe → incomplete-enumeration. **No disposition is recorded, no response-disclosure is written, the request stays Received.** A partial universe is never fulfilled as if whole — the exact silent omission the composition forbids. The officer retries once the database recovers.
- **The other refusals.** A request id no index carries, or a blank one, answers [Not Known]; a request whose act stands open answers [Act In Flight] carrying the invocation id; a request whose act closed escalated and awaits an operator answers [Compensation Pending]; a state read that fails answers [State Unavailable]. Each records nothing (Action wiring 10).
- **A host-managed record.** `r8`, held by the host and not by Defensible Retention, enters the host delete plan only where its retention reading is clear. The host delete answering deleted seals it **erased** carrying the attestation reference, and answering delete-failed seals it **anomaly(unsettled)** with the deployment alerted (Disposition 32, Disposition 35, Disposition 47).

### Rejection path — the reply is lost after the purges commit (the orphan)

An erasure fulfillment opens the act, and its execution commit purges `r1` (`ok`, erased) and `r2` and `r3` are read retained; then the reply is lost, or the process dies before the close lands. The act stands open, so `disposition_report("dsar-4002")` reads **Committing** and a retried [Fulfill Erasure Request] answers act-in-flight(inv-88). Nothing is compensated by the page and no sweep writes for it.

Recoverable Invocation's sweep closes it. Its erasure probe reads the retention of every pair in the purge plan: exactly one pair, `ret-r1`, reads purged under the intent's now and the other two read retained, so the act is committed and Recoverable Invocation closes it `dsar.erasure_execution.executed` under the service identity. The caller's next call, [Fulfill Erasure Request] on `dsar-4002`, binds: it finds the standing `.executed` closing with no fulfilled event, seals `r1` erased on the database's own purge instant, seals `r2` and `r3` **unsettled** (the answers the lost reply had for them, under-legal-hold and not-eligible, are not remembered), writes the disclosure and the fulfilled event in one transaction and answers. Exactly one fulfilled event stands. Where the plan held a host-managed record, or two pairs read purged, the probe answers undecidable and the act is escalated to an operator, who closes it; the caller then reads compensation-pending until the operator has, and the bind seals the host-managed record **unsettled** whatever the operator's data say.

### Rejection path — a record another act holds, and a gate that cannot say

- **Section unavailable at the gate.** During an erasure, `purge_record(ret-r5, …)` answers section-unavailable: counsel's `place_hold` over the same record is in flight inside Defensible Retention. Nothing was destroyed. The composition calls the purge once more; the hold has landed, the gate fires, and the purge answers `under-legal-hold` → **`retained(legal-hold)`** carrying the hold id and the count.
- **A record another request destroyed.** Two erasure requests for one subject race on `r6`. The second request's `purge_record(ret-r6, …)` answers not-known; the retention read answers `ret-r6` purged, so `r6` is **erased** in the second request's set too, carrying the retention id and the database's purge instant — never a registry anomaly.
- **Storage failure.** `purge_record(ret-r7, …)` answers storage-failure, and again on the one further call the substrate obliges. The retention stands retained and the record may or may not be gone (Defensible Retention Atomic writes 9), so `r7` is sealed **unsettled** — not retained — and the deployment is alerted.
- **A plan the cap cannot finish.** A purge plan and host delete plan together over the plan cap are refused invalid-request carrying intent, nothing written (Action wiring 54); a plan within the cap can still run out of calls, a re-invoked purge counting against the cap (Disposition 41). When the cap admits no further planned call, the composition makes no further purge: the records not yet reached are sealed **unsettled**, the response is disclosed and the event sealed in the close's transaction, and a fresh request takes up the remainder. A plan runs in one order, and a record that answers held or obliged is planned again by every later request and stands where it stood; sizing the plan cap to the largest plan a subject can carry is the deployment's.
- **The request is busy.** A second operator calls `fulfill_erasure_request("dsar-4002", …)` while the first is mid-plan → act-in-flight(inv-88), with nothing written.

### CCPA/CPRA — consumer deletion request

A California consumer submits a deletion request under the CCPA (California Consumer Privacy Act), as amended by the CPRA (California Privacy Rights Act). The erasure path runs unchanged; CCPA section 1798.105(d)'s retained-purpose exceptions (completing a transaction, detecting security incidents, complying with a legal obligation) map onto the same `retained(...)` dispositions the GDPR Article 17(3) exemptions do — a record kept to satisfy a legal obligation is `retained(retention-obligation)` via the Defensible Retention gate, a record kept under a non-consent basis is `retained(other-lawful-basis)`. The response disclosure carries `authority = {type: regulatory, reference: "CCPA §1798.105"}` — the regulatory reference the request was received under. The cross-domain structural identity is the point: the disposition surface is regulation-agnostic; only the cited authority on the response and the host's exemption determinations change.

### HIPAA section 164.524 — access to a designated record set

A patient requests access to their records under HIPAA section 164.524 (a covered entity must provide access to protected health information in a *designated record set*). The access path runs; section 164.524(a)(1) grounds for denial — psychotherapy notes, information compiled for legal proceedings — map onto `withheld(legal-exemption)` dispositions with the citation as the reason. The Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty here as the HIPAA section 164.528 accounting-of-disclosures surface. The same per-record disposition structure serves both regimes.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts.

**Regulator audit — "prove every record in the subject's universe was dispositioned, and that no held or retention-bound record was erased."** A DPA (Data Protection Authority — a national GDPR regulator) examines a fulfilled erasure request. It calls `disposition_report(request_id)`: by Invariant 2 (no-silent-omission), every enumerated record carries exactly one disposition — there is no record the response silently dropped. For every gated erased disposition, the auditor cross-reads the Defensible Retention substrate's `record_purged` event and confirms `hold_check_result: empty` (Invariant 3, resting on Defensible Retention Invariant 1 — hold-blocks-purge); a host-managed erased is the host's attested outcome and carries no gate record (Host-managed records 1). For every `retained(legal-hold)` / `retained(retention-obligation)`, it confirms the then-Active hold or the unelapsed retention via Defensible Retention's records. `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition set was not altered after the fact. Every claim is provable, by virtue of Invariants 2, 3, and 4.

**Disputed erasure — the data subject challenges a retention.** A subject's representative challenges: *"you claim you could not delete record `r2` — prove a hold actually existed."* The system presents the `retained(legal-hold)` disposition with its reason (the blocking `hold_id`) and, via the Defensible Retention substrate, the hold placed outcome Defensible Retention recorded for that hold id (Defensible Retention Check 2.1) — the Active hold's placing actor, reason and placement instant, standing on Legal Hold's immutable hold record (Legal Hold Invariant 1). `AuditTrail.verify_record` on the `dsar.erasure_fulfilled` event confirms the disposition was not fabricated or back-filled. The challenge cannot be sustained without claiming the entire hold records were fabricated, at which point the Tamper Evidence seal (via the Defensible Retention substrate) is the structural rebuttal — the same rebuttal chain Defensible Retention's own disputed-destruction scenario establishes, with this composition adding the disposition binding (Invariant 4) that ties the retention claim to a specific recorded hold. The symmetric challenge — *"you erased a record you should have kept"* — is answered by the `dsar.erasure_fulfilled` event plus the Defensible Retention `record_purged` event whose `hold_check_result: empty` proves the gate passed at purge time.

**Breach or incident investigation — "during the compromise window, was any held record erased under cover of a DSAR?"** An investigator suspects an attacker used forged erasure requests to destroy records under legal hold. They query `dsar.erasure_fulfilled` events in the window (reached through the substrate Audit Trail in Event Log insertion order) and, for each gated erased disposition, cross-read the corresponding Defensible Retention `record_purged` event's `hold_check_result`. A held record showing erased would be the smoking gun — but for a record under a Defensible Retention retention Invariant 3 forecloses it structurally: the gate would have returned `under-legal-hold` and yielded `retained(legal-hold)`, never erased. A host-managed record passes no gate, and a hold over one is outside the guarantee (Host-managed records 1). Because the disposition set is part of the hashed `dsar.erasure_fulfilled` payload, an attempt to *silently shrink* the set (to hide an improperly-erased record) breaks the seal — the same append-only, sealed-log rebuttal Propagate Consent Revocation Downstream and Immutable Ledger rely on. The forensic window is bounded by the substrate's seal cadence; the newest fulfillments in the unsealed tail carry per-event immutability but become seal-verifiable only at the next cadence.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the two indexes plus the Selective Disclosure, Consent and Defensible Retention substrate's records.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE fulfilled event carrying the request id of EVERY fulfillment entry, an entry whose fulfilled event's payload the audit instance has destroyed excepted (Invariant 1.2, Invariant 6.1).
Check 1.2: An auditor MUST find EVERY fulfillment entry's response disclosure id resolving to a Selective Disclosure record (Invariant 1.1).
Check 1.3: An auditor MUST find the request id of EVERY fulfilled event older than the entry bound carried by a fulfillment entry, an event Check 1.6 covers excepted (Invariant 1.3).
Check 1.4: An auditor MUST report a request-scoped disclosure no fulfilled event names as a write outside the composition (Capability requirement 41, Invariant 1.4).
Check 1.5: An auditor MUST read a fulfilled event carrying no fulfillment entry within the entry bound of the event's recording instant as an open obligation (Reconciliation 25, Reconciliation 36).
Check 1.6: An auditor MUST read a fulfilled event carrying no fulfillment entry that the deployment's alerting surface carries an alert for as an open obligation (Reconciliation 35).
Check 1.7: An auditor MUST find EVERY alert of Reconciliation 35 answered by a fulfillment entry written before the fulfilled event the alert names reached the audit horizon less the entry bound (Capability requirement 71, Invariant 6.1).
Check 2.1: An auditor MUST find EVERY disposition's verdict a fulfilled event carries IS IN the right type's vocabulary (Disposition 1).
Check 2.2: An auditor MUST find no record reference twice in one disposition set (Invariant 2.1).
Check 2.3: An auditor MUST find each disposition set's cardinality matching the fulfilled event's universe cardinality (Invariant 2.1).
Check 2.4: An auditor MUST re-enumerate an access fulfillment's universe from the host's data inventory (External check 1) AND find EVERY record whose creation instant PRECEDES the enumeration instant in the disposition set (Invariant 2.1, Invariant 2.2).
Check 2.5: An auditor MUST read a re-enumerated record whose creation instant falls within the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 2.6: An auditor MUST re-enumerate an erasure fulfillment's universe from the host's data inventory (External check 1) AND find EVERY surviving record whose creation instant PRECEDES the enumeration instant in the disposition set, a record the erasure destroyed being read by Check 3.5 (Invariant 2.1).
Check 2.7: An auditor MUST read a re-enumerated record as outside the fulfillment's universe where the enumeration instant PRECEDES the registration of the record's source in the host's data inventory (Completeness boundary 1, External check 1).
Check 3.1: An auditor MUST clear Defensible Retention Check 1.1 AND Defensible Retention Check 1.2 over EVERY gated erased disposition's destruction record (Capability requirement 10).
Check 3.2: An auditor MUST clear Defensible Retention Check 1.5 AND Defensible Retention Check 1.6 over EVERY retained legal-hold disposition's gate record (Invariant 4.1).
Check 3.3: An auditor MUST find a retention over the record of EVERY retained retention-obligation disposition whose retention deadline DOES NOT PRECEDE the enumeration instant (Disposition 22).
Check 3.4: An auditor MUST read a retention deadline within twice the clock offset allowance of the enumeration instant as inconclusive (Capability requirement 20).
Check 3.5: An auditor MUST find destruction evidence for EVERY erased disposition (Invariant 3.1).
Check 3.7: An auditor MUST find no retention of the business retention instance over the reference of a host-managed record the erasure intent names in the host delete plan, a retention placed before the intended instant of the intent (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY non-anomaly disposition's reason naming a recoverable authority (Invariant 4.1).
Check 5.1: An auditor MUST find EVERY response disclosure naming the requester as the recipient, the request's regulatory reference as the authority AND the request id in the scope (Invariant 5.1).
Check 5.2: An auditor MUST find EXACTLY ONE request-scoped disclosure carrying the request id of EVERY Fulfilled request (Invariant 5.1).
Check 6.1: An auditor MUST find EVERY access fulfilled event preceded by an access intent carrying the event's request id AND invocation id (Invariant 8.1).
Check 6.2: An auditor MUST find EVERY erasure fulfilled event preceded by an erasure intent carrying the event's request id AND invocation id, a fulfilled event naming the act's standing closing excepted (Recoverable Invocation Invariant 1.1).
Check 6.3: An auditor MUST attribute EVERY purge intent of Defensible Retention to the nearest preceding purge plan that names the purge's retention id AND whose plan span holds the purge intent (Action wiring 24).
Check 6.4: An auditor MUST report a purge intent Check 6.3 attributes to no purge plan as a direct purge (Action wiring 24).
Check 6.5: An auditor MUST report an attribution to a plan whose fulfillment carries no fulfilled event as presumptive (Action wiring 24).
Check 6.10: An auditor MUST find EVERY response disclosure whose own recorded instant DOES NOT PRECEDE the instant of the intent of the fulfillment the disclosure answers (Action wiring 17).
Check 6.11: An auditor MUST find the actor reference of EVERY purge intent Check 6.3 attributes to a plan EQUAL to the actor reference of the plan's intent, AND MUST report one that differs as a purge by another caller inside the plan's span (Action wiring 25).
Check 6.9: An auditor MUST find no intent of a request later in the log than the request's fulfilled event (Invariant 6.2).
Check 7.1: An auditor MUST find no consent record whose granting actor EQUALS the service identity (Invariant 7.1).
Check 7.2: An auditor MUST find no consent record whose revoking actor EQUALS the service identity (Invariant 7.1).
Check 8.2: An auditor MUST find the audit horizon exceeding the longest retention obligation a registered record carries (Capability requirement 9).
Check 8.3: An auditor MUST find EVERY fulfilled event of a re-entry bind carrying, for EVERY record outside the plans, the disposition of the intent the event closes (Action wiring 49).
Check 8.5: An auditor MUST read a check over a horizon event as unknown (Recoverable Invocation Invariant 7.3).
Check 8.6: An auditor MUST find EVERY fulfilled event AND EVERY intent within the payload cap AND EVERY source text within the text cap (Primitive policy 13, Capability requirement 51).
Check 8.9: An auditor MUST find a stall mark for EVERY intent of the act kind that stands open past Recoverable Invocation's at-risk threshold, an intent Check 8.10 covers excepted (Reconciliation 38).
Check 8.10: An auditor MUST read an intent carrying no stall mark that the deployment's alerting surface carries an alert for the mark's write as an open obligation (Reconciliation 39).
Check 8.13: IF a lost run EXISTS THEN an auditor MUST read a finding of Check 1.3 AND Check 8.9 as an open obligation (Reconciliation 34, Reconciliation 40).
Check 8.14: An auditor MUST find no lost run older than Recoverable Invocation's run interval (Reconciliation 40, Reconciliation 41, Term lost run).
Check 9.1: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 6).
Check 9.2: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 6).
Check 9.3: An auditor MUST clear Defensible Retention's Generation acceptance over the substrate (Composes 6).
Check 9.4: An auditor MUST clear Recoverable Invocation's Generation acceptance over the Recoverable Invocation instance (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

NOTE: Check 7.1 and Check 7.2 read the actor fields Consent records and does not attest; External check 6 confirms beyond them.

Term gated erased disposition: an erased disposition whose record carried a retention id.

Term closing record: the standing closing of an intent of the act kind (Recoverable Invocation Term closing record), or the fulfilled event carrying an access intent's invocation id.

Term lost run: a run the alerting surface carries an alert for — a failed trail read (Reconciliation 34) or an unended enumeration (Reconciliation 40) — with no later run's enumeration end recorded there (Reconciliation 41). Its age runs from the alert's instant, against Recoverable Invocation's run interval. A run that ends its enumeration after it has alerted on, written and marked what the lost run did not, so the findings the lost run excused are that run's to clear.

Term horizon event: an event whose age on the auditor's now is no less than the audit horizon less three clock offset allowances — an event the audit instance may have destroyed. Three allowances, for the offsets among the log's clock, the retention's and the auditor's seam.

Term plan span: the stretch of the log from an intent of the act kind carrying a purge plan to the intent's closing record and on past it by the planned call latency, read on recording instants — open-ended while the intent carries none. A purge made under a plan falls inside the plan's span: a planned call is issued ahead of the closing record and its last write lands within the planned call latency of its issue, a write that answered no answer included. A purge later in the log than the span is no planned call of that fulfillment, whatever retention it names.

Term enumeration instant: the intended instant of the intent a fulfilled event closes — the invocation's one reading of now at the seam (Capability requirement 21), taken ahead of the open's take, so every verdict was made no earlier than it and the universe may have been enumerated later by any stall of the call, which the clock offset allowance of Check 2.5 and Check 3.4 does not bound; equal to the fulfilled instant except on the fulfilled event of a re-entry bind, which carries it as a field of its own (Action wiring 31) and so keeps it where the intent is destroyed ahead of the event.

<details markdown="block">
<summary>WHY</summary>

A purge intent's attribution (Check 6.3) is to a plan that named the retention, and no proof of which invocation called: where two requests plan one retention id inside overlapping spans, or another caller purges inside an open span, the nearer plan is credited and may not be the caller's. The purge intent's own actor says who called, and Check 6.11 reads it against the plan's: the purge carries its own invocation id, so the plan's operator is the one thing the two share.

For a closing record the service identity attested the unknown reading of Check 8.11 does not come back once the log is older than the horizon; what the trail still shows beside a compensating event is the leg's own recovery intent, naming the intent it resolved (Reconciliation 11). A destruction record or a gate record destroyed ahead of the fulfilled event that rests on it is a horizon event too: the disposition's purge instant, or the event's enumeration instant, says how old the missing record is, and at that age Check 3.1 and Check 3.2 read unknown (Check 8.5).

</details>

### External checks

```
External check 1: An auditor needing the registry's completeness confirmed MUST read the host's data inventory (Capability requirement 1).
External check 2: An auditor needing a host-asserted determination's legitimacy confirmed MUST read the legal analysis behind the determination (Invariant 4.1).
External check 3: An auditor needing the requester's identity confirmed MUST read the identity verification wired ahead of [Receive Request] (Non-goal 1).
External check 4: An auditor needing the operator's authorization confirmed MUST read the deployment's Permissions records (Non-goal 2).
External check 5: An auditor needing the statutory deadline confirmed MUST compute the deadline from the recording instants of the intake event AND the fulfilled event, a seam instant being a stalled host's early stamp (Term recording instant, Non-goal 3).
External check 6: An auditor needing consent non-mutation confirmed beyond the records MUST read the generated code's Consent calls (Invariant 7.2).
External check 7: An auditor needing every hold-bearing record placed under Defensible Retention confirmed MUST read the host's hold inventory (Host-managed records 1).
External check 8: An auditor needing an alert confirmed MUST read the deployment's alerting surface (Reconciliation 38, Audit arm 18).
External check 10: An auditor needing the fate of a gated record sealed unsettled under a record purged outcome confirmed MUST read the deployment's own destruction records (Defensible Retention External check 8).
External check 12: An auditor needing the pairing datum's resolution confirmed MUST clear Recoverable Invocation External check 12 (Capability requirement 67).
External check 13: An auditor needing a repeated erasure's refusal confirmed MUST clear Recoverable Invocation External check 9 (Recoverable Invocation repeatable 2).
External check 14: An auditor needing the fate of a host-managed record sealed unsettled confirmed MUST read the host's own record of the delete (Disposition 35, Disposition 36).
External check 15: An auditor needing the deployment's topology confirmed MUST read the deployment's configuration AND the deployment's change record: one instance of the composition per Defensible Retention instance AND per Selective Disclosure instance, no other writer of a composition action reference, an audit retention policy unchanged for the life of the instance, the accounting records under Defensible Retention's retention, AND the alerts kept for the audit horizon (Capability requirement 42, 49, 52, 53, 54, 57, 60, 61, 63).
External check 16: An auditor needing a stall mark never cleared, a host-managed record's retention placed no later than the fulfillment's retention read, AND EVERY record sealed unsettled settled confirmed MUST read the generated code's index writes, the host's retention placements AND the deployment's settlement record (Composition state 28, Host-managed records 3, Disposition 48).
External check 17: An auditor needing a consent answer a disposition rests on confirmed MUST read Consent's check again as of the enumeration instant (Concurrency 2, Disposition 9).
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
Non-goal 9: The composition MUST NOT own the tamper seal over the Selective Disclosure records; a deployment needing the seal MUST supply the seal (Selective Disclosure Composition note 5).
Non-goal 10: The composition MUST NOT own the propagation of a consent withdrawal; a deployment needing propagation MUST compose Propagate Consent Revocation Downstream (Consent Composition note 4).
Non-goal 11: The composition MUST NOT claim the open, the execution commit AND the close atomic (Recoverable Invocation Non-goal 1).
Non-goal 12: The composition MUST NOT own the legitimacy of an authority reference; the response authority is the request's regulatory reference, kept opaque (Selective Disclosure Composition note 4).
Non-goal 13: The composition MUST NOT gate a processing act (Consent Composition note 3).
Non-goal 14: The composition MUST NOT own the purpose taxonomy; a purpose is passed unchanged (Primitive policy 10, Consent Composition note 5).
Non-goal 15: The composition MUST NOT plan the purge by what a planned call can still settle; the plan keeps record reference order, and sizing the plan cap to the largest plan a subject can carry is the deployment's (Capability requirement 69).
```

NOTE: the owners — [Permissions](../atoms/permissions.md) (Non-goal 2, External check 4); a Regulatory Deadline pattern *(forthcoming)* or a host dashboard (Non-goal 3, External check 5); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) (Non-goal 10); the deployment (Non-goal 9, Non-goal 12 through 14); [Defensible Retention](./defensible-retention.md) (the retention of the disclosure and consent records, Capability requirement 60 and 61).

NOTE: watch the adopter's policy note (Non-goal 9, Non-goal 10).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of the composition's events.
```

### Concurrency

```
Concurrency 2: The composition MUST read the Consent answer a disposition was recorded under as that disposition's basis.
```

### Accounting stores

```
Accounting stores 1: An erasure fulfillment MUST retain the accounting records as a class.
Accounting stores 2: The composition MUST NOT disposition an accounting record.
```

### Completeness boundary

```
Completeness boundary 1: The composition MUST claim no-silent-omission ONLY over the declared universe.
```

### Cross-record consistency under partial failure

```
Cross-record consistency 1: IF an erasure's planned calls commit AND the act's close does not land THEN the record MUST carry an open intent, closed by Recoverable Invocation's sweep or an operator AND sealed by the re-entry bind.
```

This is Recoverable Invocation's Cross-record consistency for the one act kind: destructions committed, the intent open and no response written. The records an erasure keeps as evidence of a refused call, its intent and its refusal record, stay committed (Recoverable Invocation commit 3).

### Host-managed records

```
Host-managed records 1: The composition MUST NOT claim the hold guarantee over a host-managed record.
Host-managed records 2: A deployment needing the hold guarantee over a record MUST place the record under Defensible Retention retention.
Host-managed records 3: The composition MUST NOT claim the hold guarantee for a fulfillment over a record placed under retention later than the fulfillment's retention read.
```

<details markdown="block">
<summary>WHY</summary>

A retention and a hold placed later than a fulfillment's retention read and ahead of the host delete — a window from the execution commit's retention re-read (Action wiring 53) to the host delete — do not stop that fulfillment's host delete, which passes no gate. The window is the deployment's: it places a host-managed record under retention with no erasure of the record's subject in flight, or it accepts that a fulfillment already past its read completes.

</details>

### Snapshot

```
Snapshot 1: A fulfilled event MUST NOT carry a disposition for a record outside the fulfillment's enumeration.
```

---

## Composition notes

**Selective Disclosure's and Consent's composition notes, each met or declined.** Selective Disclosure's note 2 (the authorization of a call) is declined by Non-goal 2; note 3 (the attestation binding the recording actor) is met, the audit write binding the actor of every fulfillment (Primitive policy 11) beside the response disclosure the same invocation writes (Action wiring 18 and 28); note 4 (the legitimacy of an authority reference) is declined by Non-goal 12; note 5 (the tamper seal) is declined by Non-goal 9; note 6 (the retention of the disclosure records) is Defensible Retention's (Capability requirement 60); note 7 (at-most-once recording) is met by one response disclosure per request (Invariant 1.4, Invariant 5.1); note 8 does not apply, the composition leaving Selective Disclosure's own surface to its other callers (Capability requirement 41). Consent's note 1 (the deployment declares its composing patterns) is the deployment's; note 2 is met, Consent's check made ahead of any planned call (Disposition 9, Action wiring 24); note 3 (the suppression of a processing act) is declined by Non-goal 13; note 4 (the propagation of a withdrawal) is declined by Non-goal 10; note 5 (the purpose taxonomy) is declined by Non-goal 14; note 6 (the retention of the consent records) is Defensible Retention's (Capability requirement 61); note 7 (the authority to grant for a data subject) is declined, the composition writing no consent (Invariant 7.1); note 9 is met, the composition polling no consent record.

**Recoverable Invocation's commit is one call.** The execution commit makes several planned calls under one invocation, and a conforming implementation of the protocol can answer for it only once, at its end. A planned call that answers no answer lands its record unsettled and the partition stays committed (Term commit partition); the partition is unknown, and the act yielded, only where the commit itself has not returned within the commit round trip, and nothing finer is carried (Recoverable Invocation commit 6 and 7). Recorded as evidence for Recoverable Invocation's next revision (Recoverable Invocation Deviation 2).

**Recoverable Invocation's probe counts one record.** The erasure probe can certify a committed act only where exactly one pair reads purged under the pairing datum and the host delete plan is empty (Recoverable Invocation act probe 2, 3a and 7); an erasure with two or more destructions, or any host delete, is undecidable and escalates to an operator, where the leg this page had sealed such an erasure itself. Recorded as evidence for Recoverable Invocation's next revision (Recoverable Invocation Deviation 2).

**Recoverable Invocation's probe matches a record that carries no field of the act key.** The erasure probe matches the retention record the retention read answers, which carries the retention's record reference, retention state, retention deadline and purge instant and not the request id, so the erasure probe answers committed on the intent's purge plan and the pairing datum alone, where Recoverable Invocation act probe 8 lets a probe answer committed only where the matching record carries every field of act key; the committed answer carries the request id and the one pair read purged, and the act kind's one outcome action stands for the outcome action reference (Term erasure binding). Capability requirement 67 holds one request id to one reading of the pairing datum and says nothing of two request ids whose plans name one retention, so two such requests executing at one reading are told apart by no record. Recorded as evidence for Recoverable Invocation's next revision (Recoverable Invocation Deviation 2).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the pattern. The composition's own concepts are the four actions it exposes — the intake ([Receive Request]), the two fulfillment siblings ([Fulfill Access Request], [Fulfill Erasure Request]) and the read-only [Disposition Report]; the [Dispositions] set carrying a verdict for every enumerated record; the closed verdict vocabulary ([Included], [Withheld], [Erased], [Retained], [Anomaly]); and its own fulfillment refusals ([Wrong Right Type], [Already Fulfilled], [Incomplete Enumeration]). No-silent-omission and the binding bijection are structural properties, not data. The deployment settings keep their wire spellings in configuration — `record_source_registry`, `audit_trail_retention_policy`, `application_actor_ref`, `application_credential`, `compensation_window`, `fulfillment_completion_bound`, `reconciliation_cadence`, `clock_offset_allowance`, `call_pause_bound`, `section_term`, `section_read_bound`, `planned_call_latency`, `text_cap`, `enumeration_bound`, `id_cap` — and the two indexes theirs in an implementation, `request_to_subject` and `request_to_fulfillment`; the pattern names each in English where it declares it. Defensible Retention's purge taxonomy is cited whole — ok and the rest of its declared refusals — rather than listed in part. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the index leg; a deployment; a regulated deployment; an auditor; a caller; a requester; a subject; an operator; a reader; an invocation; a fulfillment; a validated intake; a landed intake; an admitted fulfillment; an enumerated fulfillment; an intended fulfillment; an enumerated access; an intended access; a disclosed access; an enumerated erasure; an intended erasure; an executed erasure; a disclosed erasure; a landed fulfillment.

Term records: the intake events, access intents, fulfilled events and the act kind's records the composition records through the audit write — each an Event Log event carrying one action reference below — the response disclosures it records through the disclosure write, and the two indexes' entries.

Term record verbs: refuse, seal, add, adjudicate, admit, alert, answer, assemble, attest, attribute, bind, call, carry, change, check, claim, classify, clear, close, compare, compensate, compose, compute, confirm, correct, cover, declare, derive, destroy, disclose, disposition, enumerate, escalate, evaluate, examine, exist, expose, find, gate, hold, include, inherit, inject, inspect, issue, key, land, leave, make, match, mint, name, namespace, normalize, open, own, pair, pass, place, plan, proceed, produce, provision, re-enumerate, re-invoke, reach, read, rebuild, reconcile, record, release, report, resolve, retain, retry, route, run, select, serialize, serve, set, settle, size, stamp, start, store, supply, survive, take, verify, write, yield.

Term value sets: action reference = dsar.received | dsar.access_fulfillment_intended | dsar.access_fulfilled | dsar.erasure_fulfilled | dsar.erasure_execution.intended | dsar.erasure_execution.executed | dsar.erasure_execution.refused | dsar.erasure_execution.recovery_intended | dsar.erasure_execution.abandoned | dsar.erasure_execution.escalated. withheld reason = third-party-confidentiality | legal-exemption. retained reason = legal-hold | retention-obligation | other-lawful-basis. anomaly reason = determination-unavailable | consent-basis-not-known | mis-paired | unknown-retention | host-record-not-found | unsettled. position = intent | outcome — the record a failed write would have landed (Recoverable Invocation Term position): intent for the intake event, the access and an erasure's open, which commit nothing (Audit arm 7, Action wiring 21b), outcome for an erasure's close (Action wiring 46, Action wiring 48). The rest are declared where the section that owns each declares it: right type, request state, verdict, withdrawn answer, determination reading, basis reading, retention reading, retry answers, unsettling answers, purge reading, lease reading, disclosure fault.

Term bounds: clock offset allowance (clock_offset_allowance), audit horizon (audit_trail_retention_policy), planned call latency (planned_call_latency), plan cap (plan_cap), text cap (text_cap), id cap (id_cap), and the bounds computed from them — entry bound, reason bound; Recoverable Invocation's instance bounds carry the names it gives them (Capability requirement 66).

Term cadences: sweep cadence (Recoverable Invocation's sweep cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive pattern, audit write, trail, trail read, recording instant, retention read, disclosure write, disclosure read, source enumeration, universe enumeration, request id, request index, request entry, fulfillment index, fulfillment entry, live entry, aged entry, request's events, stall index, stall mark, state read, intake event, intent, fulfilled event, plan span, request state, record source registry, creation instant, declared basis, host determinations, host delete, route, host-managed record, accounting records, audit retention policy, audit horizon, hold guarantee, service identity, clock offset allowance, seam, now, invocation id, planned call latency, entry bound, id cap, source text, text cap, reason bound, alerting surface, invalid-request, subject reference, right type, requester, regulatory reference, actor reference, credential, record reference, retention id, caller string, largest record, writer, pre-effect record, intake result, fulfillment result, report, validated intake, landed intake, fulfillment, admitted fulfillment, enumerated fulfillment, enumerated access, enumerated erasure, universe cardinality, recipients read, consents read, access intent, intended fulfillment, intended access, access scope, request scope, response authority, disclosure fault, refused disclosure write, disclosed access, erasure intent, provisional dispositions, purge plan, host delete plan, destroying surface, planned call, planned record, intended erasure, executed erasure, erasure scope, disclosed erasure, landed fulfillment, reconciliation, request-scoped disclosure, destruction record, destroyed planned record, disposition, verdict, anomaly reason, withdrawn answer, determination reading, basis reading, erasure-due record, retention reading, settled record, planned, retry answers, unsettling answers, purge's first answer, purge's last answer, purge reading, outside the host delete's contract, destruction evidence, gated erased disposition, closing record, lost run, horizon event, enumeration instant, act kind, erasure binding, act key, execution commit, commit partition, erasure probe, re-entry bind, plan cap.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the substrate. record, read, disclosure id, scope, authority, recipient, invalid-request, unknown-authority-type, storage-failure: Selective Disclosure. check, read, grant, revoke, consent id, purpose, granted, revoked, expired, not-known, granting actor, revoking actor: Consent. purge_record, ok, not-known, not-eligible, under-active-retention, under-legal-hold, hold-check-unavailable, section-unavailable, storage-failure, gate, hold ids, count, hold check mode, strict, advisory, hold check result, hold override, gate record, record_purged, purge_intended, business retention instance, landed record, owed record, audit write latency: Defensible Retention. record_action, verify_record, payload cap, step-2, step-3, step-4, invalid-credential, recording-failure, Erasure Tombstone: Audit Trail. read, retention state, retained, purged, retention deadline, purge instant: Retention Window. read, sequence, recording instant: Event Log. open, close, refuse, yield, act-in-flight, act-landed, journal-unavailable, invocation id, closing, escalated, executed, critical section, pause bound: Recoverable Invocation.

Term composing patterns: [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Multi-Party Approval](./multi-party-approval.md); [Immutable Ledger](./immutable-ledger.md); [Customer Onboarding](./customer-onboarding.md); [Party Identity](../atoms/party-identity.md); [Actor Identity](../atoms/actor-identity.md); [Permissions](../atoms/permissions.md).

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

The read-only surface a subject, auditor, or regulator uses to read a request's outcome: Received (intake only), Committing (a fulfillment in flight or awaiting Recoverable Invocation's closing or the next call) or Fulfilled (the complete per-record [Dispositions] with response-disclosure and fulfilled-at). Produces no audit event — it changes no state.

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

#### Not Known

The fulfillment and report rejection when no request carries the request id: the rebuilt index answers no request entry (Action wiring 4, Action wiring 34), or the id is blank (Primitive policy 15). Nothing is recorded.

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: not-known

#### Compensation Pending

The [Fulfill Erasure Request] rejection when the request's act closed escalated and no operator has closed it: the destructions it made are unsettled until an operator closes the act (Action wiring 43).

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: compensation-pending

#### Act In Flight

The [Fulfill Erasure Request] rejection, carrying the invocation id, when an intent of the request's act kind stands open: another call's execution commit may be mid-plan (Action wiring 6).

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: act-in-flight

#### State Unavailable

The fulfillment and report rejection when the state read fails: no state is answered and nothing is written, so a request is never read as unknown for want of a read (Composition state 22).

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: state-unavailable

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
[Not Known]: #not-known
[Compensation Pending]: #compensation-pending
[Act In Flight]: #act-in-flight
[State Unavailable]: #state-unavailable


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

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — re-derived for the unit `composes Recoverable Invocation` over Recoverable Invocation's contracts, which that page's model proves (the erasure one act kind; the access and the intake one transaction each under Execution Contract Database 1, so the access model and its probe retired, and the request section's and the legs' twins with the rules they checked): resolve-a-persons-data-rights.tla + 9 twins (-buggy-retry, -buggy-coverage, -buggy-abandon, -buggy-unsettled, -buggy-taint, -buggy-evidence, -buggy-orphan, -buggy-probe-erased, -buggy-bind-split) + 3 probes (-probe-recover, -probe-late, -probe-gap), two erasure calls, the sweep's erasure probe, an operator and a late purge over the commit partition and the re-entry bind, TLC, 8,757 states; resolve-a-persons-data-rights-admission.tla, the same module with three calls, + -admission-buggy-order + probe -admission-probe-again, 62,648 states; Inv_OneSeal, Inv_NoOrphanEvent, Inv_OneDisclosure, Inv_NoOrphanDisclosure (Invariant 1.4, in every state), Inv_Accounted (the invocation refuse only on the pre-commit arm), Inv_Evidence (the sweep's .executed included), Inv_Truth and Inv_Cover, each broken by a twin; Inv_OneClose and Inv_OneOpen retired to Recoverable Invocation's model; resolve-a-persons-data-rights.als + 14 twins (the static data model of 2026-11-12, re-derived with the act kind's refused, executed, escalated and abandoned closings and the re-entry bind, its legs and compensation flag gone: Invariant 1.1 through 1.4, 2.1, 2.2, 3.1 over the fulfilled events and the .executed closings, 3.2, 4.1, 5.1, 6.2, 7.1, 7.2, 8.1 and A_Accounted, each broken by a twin; 1.5, 1.6 and 8.2 retired to Recoverable Invocation's; nothing testable in Alloy for 6.1; re-derived again 2026-11-22 for Scott's rulings, the retention reading read off the retention read's answers: A_Disposition_39, a record whose named retention id no retention carries beside a purged sibling sealed erased on the sibling's retention id, never anomaly unknown-retention, with Audit arm 28's one alert, broken by -buggy-absent-first; Non-goal 15 unstatable, no model carrying the plan's order or cap); the models found, cured in the same unit (2026-11-22): Term erasure probe's four answers left a reachable state none named (no pair purged under the intent's now, a gate record naming one, the host delete plan empty), now undecidable; Action wiring 6, 43 and 44 fired together on a request with one act open beside another's .executed closing, now ordered (an open act answers act-in-flight first); the Composition note on the commit read a planned call's no answer as unknown where Term commit partition reads it committed, now agreeing; Action wiring 50 seals erased from an operator's outcome data, now said to be detected and not validated (Recoverable Invocation Check 6.1); and still open, Invariant 4.1's no-bar authority (2026-11-12) and Term retention reading's "raises no alert (Disposition 47)" beside Audit arm 28's alert on a record read purged on a sibling (2026-11-22); 2026-11-22
last gate: 2026-11-23 — Final Critique 8, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at ad4682fd — foundational count 1 after the blind second triage, cured, not clean, no sample (Linus's two foundational findings, both on Action wiring 21b, were refuted by both triages: "carrying intent" is the position of the refusal, declared in Term value sets as the record a failed write would have landed and used so by Audit arm 7, not an intent record that must exist, so a refusal before the open carries the intent position and writes nothing; the blind second triage found one more: Audit arm 20 binds only at a pre-effect record, the intake event or the access intent, and the act kind's intent is none, so the row landing an invalid-request below step-4 "nothing written" at an erasure's fulfilled event, written after the execution commit, had no owning rule and Action wiring 21b would have given it the intent position where Recoverable Invocation Invariant 8 and Recoverable Invocation Primitive policy 42 hold the outcome position, cured by naming it in Action wiring 21a with the closure row and Term invalid-request; the settle's own cures: Term value sets names an erasure's open among the intent position's cases, the closure rows for a blank input and the payload cap write the position beside the plan cap row's, the disclosure row ends its phrase, the plan-cap example no longer describes a plan over the cap that Action wiring 54 refuses, and Term invalid-request's blank input excepts the request id Primitive policy 15 answers not-known; the report's seven refining findings were refuted, Primitive policy 5's subject by Closed vocabulary 29, and of its three rhetorical ones one was cured); the round read the reach of Final Critique 7's cures (24 labels) by their diff; 2026-11-22 — Final Critique 7, a delta round, one reader (Linus beam-free), frozen at 7c3b5d0a — foundational count 4 after the blind second triage, cured, not clean, no sample (Linus's report claimed 3 foundational and the first triage placed none: Composition state 26 stood on a mark that Composition state 28 and Composition state 32 keep after the re-entry bind writes the fulfilled event, so a fulfilled request read Committing beside Fulfilled, Term request state's "so no request reads two" holding at the mark's write and no longer after it, which the blind second triage placed foundational and the first refining, cured with the condition Composition state 31 carries; the report's Action wiring 4 finding was refuted by Action wiring 5, which answers already-fulfilled for a Fulfilled request and which the finder's cure would have contradicted, and its Capability requirement 71 finding by Recoverable Invocation Instance start 4 and 5, which hold the retention period, the audit horizon here, over the retention floor, the closure window and the worst closure, itself over the entry bound; the blind second triage found three more: Action wiring 8 bounded wrong-right-type to a Received request, so [Fulfill Access Request] was admitted on an erasure request whose act is open, cured to Received and Committing; Term erasure probe answered none of its four for a pair purged under another instant beside the one the act purged, which Recoverable Invocation act probe 2 and act probe 3 decide as committed, cured; and Action wiring 21a, Final Critique 6's own cure, landed invalid-request after the commit with no position where Recoverable Invocation Action wiring 1 and Invariant 8.1 ask one of a code landing on both sides, cured with the position in the signature, Action wiring 21a and the new Action wiring 21b, and the rule's phrase on the act's intent corrected for the re-entry bind); the round read the reach of Final Critique 6's cures (353 labels) by their diff; 2026-11-22 — Final Critique 6, a full round of three fresh passes, frozen at ae2025d6 — foundational count 2, cured, not clean, no sample (GRID's report, glm-5.3-flash, filed both, EOS and Linus none: the erasure probe's committed answer matches a retention record that carries no field of the act key, which Recoverable Invocation act probe 8 asks of a committed answer, a departure the page had not recorded, cured as the page's two other departures are, a Composition note recording it under Recoverable Invocation Deviation 2 and Term erasure binding naming it; Term stall mark keyed the mark to the completion bound where Reconciliation 38 and Check 8.9 key it to the at-risk threshold, so a mark no rule clears (Composition state 28) could stand on an intent the sweep closed between the two bounds and hold the request at Committing, cured to the threshold, the finder's Received answer for an open intent being refuted by Composition state 17; refining cured: Audit arm 21 reads the same write, Action wiring 21a lands an erasure's disclosure fault as the closure table already did, the page declares position and drops the undeclared young and overdue, Check 8.5 and Check 8.14 cite the rules that own them; refuted: Disposition 49's retained seal on a record already destroyed, which Term retention reading states as the decision; the pass's own lapse line on pressure-testing.md was no lapse, the reading set carrying Pass 1 to Pass 3 and What DONE means for every reader); 2026-11-22 — Scott's answers of 2026-11-22 12:39 PM Central applied (not a round): a purged sibling retention outranks an unregistered named retention id in Term retention reading (one alert, Audit arm 28), and the plan keeps record reference order with the sizing the deployment's (Non-goal 15); open lines 2026-11-18-a and 2026-10-06-h closed; the next round is a full round; 2026-11-22 — composes Recoverable Invocation (not a round): the erasure binds one act kind on a Recoverable Invocation instance and the access and intake stay one transaction each; 90 rules tombstoned to Recoverable Invocation and Execution Contract Database 1, about 25 restated, 12 new; the next round is a full round; 13 open lines closed, 15 narrowed; — Final Critique 5, a delta round, one reader (Linus beam-free), frozen at e74a1c0d — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed 2 foundational and none held (both refuted: Concurrency 10 and Concurrency 14 bound a reading of Lease's remaining, taken only after the request's state read answered, since Concurrency 7 and Composition state 22 put a failed state read ahead of every enumeration, intent and write, and Execution Contract Read 2 and Read 4 hold a rule on what an action writes to a call whose read answered and which the action admits; the cures would restate them); the blind second triage's press found one refining beside them, opened: the state-unavailable of a failed read as an answer of Defensible Retention's purge (2026-11-19-a); refining already open: Capability requirement 31's arithmetic (2026-11-18-c); the round read the reach of Final Critique 4's cures and Defensible Retention Capability requirement 75 by their diff; 2026-11-18 — Final Critique 4, a delta round, one reader (Linus minimax-m3), frozen at d474e88 — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus's report claimed 2 foundational, placed refining by both triages: the order of absent and purged in Term retention reading (every build reads the explicit order one way, and whether a destroyed record outranks an unregistered id is a decision no rule makes: the open line 2026-11-18-a) and Concurrency 10's interval (refuted: Concurrency 9 and Term bind floor already hold the ask-to-effect interval to two call pause bounds, and Linus's old text misquoted the page); the blind second triage's press found one foundational beside them, the settle's own, cured: Term purge reading and Term destruction evidence read Defensible Retention's recording-failure carrying outcome as a destruction, where Defensible Retention Action wiring 84 and Defensible Retention Action wiring 99 commit nothing and answer it (Defensible Retention Atomic writes 5, Defensible Retention Action wiring 112), so an erased disposition could be sealed on a purge that destroyed nothing and Check 3.1 would find no destruction; the answer is now a retry answer; refining opened: the pending mark (2026-11-18-b), Capability requirement 31's arithmetic (2026-11-18-c), Check 6.6's missing finding (2026-11-18-d); refuted or no edit: Check 8.4 (Execution Contract Logic confinement 17), Reconciliation 14, the alert floor's second window, External check 9, three rhetorical; 2026-11-18 — Final Critique 3, a delta round, frozen at b1ad0d6 — foundational count 0 after the blind second triage, clean, no sample (Linus's one report claimed none: the hold check result's "empty" is Defensible Retention's own value, so the proposed `EQUALS blank` would pass a destruction record carrying no result at all and both triages placed it refuted; External check 10's citation was written in the cited rule's own words and its number made plural, the first triage placing that refining and the second refuted; the settle's own cures, where Defensible Retention's recovery retired to Database 1 left three places on this page naming it: Term destruction record's "a recovered one included", Term recovery marker's Defensible Retention arm and the Regulator audit example's pointer to the retired Check 3.6); the round read the reach of Defensible Retention's retirement of its recovery (b1ad0d66), Check 3.1 and External check 10, by their diff; 2026-11-05 — Final Critique 2, a delta round, frozen at 776c44e — foundational count 0, clean, no sample; 2026-11-04 — Final Critique 1, a full round of three fresh passes over the page and its three constituents — 9 foundational after merging, cured in the settle, 3 reports refuted on the page's own text; not clean: the cures are unread, and the next round is a delta round.

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./resolve-a-persons-data-rights.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/resolve-a-persons-data-rights.md`.

</details>

NOTE: End of Resolve a Person's Data Rights.

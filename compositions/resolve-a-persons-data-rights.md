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

Resolve a Person's Data Rights is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem none of its constituents solves alone: when a person exercises their legal right to see or to delete the personal data an organization holds about them, the organization must work out, for *every* record, what to do — and prove afterward that it did the lawful thing, using only the records it kept. The difficulty is that the request collides with other rules: some records are under a legal hold that forbids deletion, some must be kept for a legally mandated period, and some were collected under a consent that may since have been withdrawn. This composition resolves this one record at a time. It assigns every record in the person's data a single **disposition** — a recorded verdict — and the set of allowed verdicts is fixed: for an access request, a record is [Included] (handed over) or [Withheld] with a stated reason (it implicates a third party, or a legal exemption applies); for an erasure request, a record is [Erased], or [Retained] with a stated reason (a legal hold blocks deletion, a retention period has not elapsed, or another lawful basis still applies) — and a record whose fate or basis could not be settled is an [Anomaly], carrying a finding, rather than silently either.

It wires three constituents. Selective Disclosure is the running log of every time the person's data was shared and with whom — read to answer the access right's "who has my data been disclosed to?" and written to record the act of responding to the request itself. Defensible Retention is the substrate that supplies the deletion gate: its built-in rule that "a record under an active legal hold cannot be purged" *is* the structural answer to the erasure-versus-preservation collision, and through it this composition reaches Legal Hold, Retention Window, and the tamper-evident Audit Trail without maintaining duplicates. Consent is consulted as a read-only oracle — this composition asks it "was consent the basis for processing this, and is that consent still in force?" to decide whether erasure is actually due, but this composition never changes a consent record.

The composition's defining emergent guarantee (a property that appears only when the atoms are combined — no single atom carries it) has two halves. **No-silent-omission:** every record in the person's enumerated data universe carries exactly one disposition, so nothing is quietly left out of a response — the completeness an auditor checks. **Binding bijection:** a fulfillment binds the complete set of dispositions, the record of the disclosure to the requester, and the sealed Audit Trail event — so there is never a fulfilled request whose disposition record is missing or incomplete. The sealed event is written last and cannot be withdrawn once written, so an event always has its disclosure behind it; the reverse gap is reachable, always surfaced, and compensated (Invariant 1). This composition enforces the structural gate (an active hold blocks erasure) and records each disposition with an auditable reason; it does not rule on the legal fine print of whether a particular exemption truly applies — that is named as counsel's and a composing pattern's job, not absorbed here.

 Its most common uses are GDPR (the EU General Data Protection Regulation) Article 15 access and Article 17 erasure fulfillment, CCPA/CPRA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) consumer access and deletion requests, and HIPAA (the US Health Insurance Portability and Accountability Act) §164.524 access to a designated record set. Any system that must answer a data subject's access or deletion request *and* prove, from records alone, that every record was dispositioned and that legal holds and retention obligations were honored throughout, is a candidate for this composition.

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
```

Term composition: this pattern's wiring of [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md) and [Consent](../atoms/consent.md) — the intake, the two fulfillment siblings, the report, the two indexes and the reconciliation.

Term constituents: [Selective Disclosure](../atoms/selective-disclosure.md), [Defensible Retention](./defensible-retention.md), [Consent](../atoms/consent.md).

Term transitive pattern: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) or [Audit Trail](./audit-trail.md), reached through Defensible Retention.

Term audit write: Audit Trail's record_action on the Audit Trail instance Defensible Retention carries.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term universe enumeration: the composition-introduced surface that enumerates a subject's in-scope records over the record source registry and the Defensible Retention-managed records, each with its record reference, its source and its creation instant — the eventual home of a Completeness Model atom *(forthcoming)*.

WHY:
**Selective Disclosure is used in both directions.** *Read*, an access fulfillment answers GDPR (the EU General Data Protection Regulation) Article 15(1)(c) — *the recipients to whom the personal data have been disclosed* — from the records alone. *Write*, every fulfillment records its response to the requester as one disclosure, so the release of the subject's own data back to them is itself an accountable, immutable disclosure event. This settles, in favour of recording, the deployment-policy question Selective Disclosure's *Disclosures to the subject themselves* edge case leaves open: a regulated rights-fulfillment surface records its own responses.

**Defensible Retention is a substrate, named the way an atom is named** (Composes 4 and 5; the section titled Compositions of compositions in `spec-format.md`). It is the erasure path: every record an erasure would destroy is gated through its purge, whose outcomes map onto this composition's erasure dispositions (Disposition 20 through 31). Through it the composition inherits the hold-blocks-purge gate (Defensible Retention Invariant 1), the retention-not-elapsed refusal, and the tamper-evident, attributed Audit Trail on which the composition records its own events (Composes 8) — the substrate-composition pattern Multi-Party Approval established: Audit Trail's own declared record_action and its Invariant 1, reached through the named substrate, not an ambient reach-through. One substrate instance; no duplicate Legal Hold, Retention Window or Audit Trail at this layer.

**Consent is an oracle, never written** (Invariant 7). The erasure path asks it whether consent was the basis for a record and whether that consent is still in force — the Article 17(1)(b) determination. A subject who withdraws consent does so through [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); this composition reads the state that produces.

**The universe enumeration is composition-introduced** (Composes 10; the section titled *Capability provenance* in `pressure-testing.md`). No constituent enumerates a subject's record universe with a verdict per record — Selective Disclosure enumerates disclosures, Consent consents, Defensible Retention retentions. Its eventual home is a Completeness Model atom, *accountable enumeration of a record universe with per-record disposition*, framed as a shared primitive this composition and Customer Onboarding both exercise and this composition merely exposes — the same discipline by which Immutable Transaction Ledger seeded a Subset Proof atom rather than owning subset verification. Until it lands, the surface is bounded by the record source registry (Capability requirement 1).

The Selective Disclosure and Consent stores are owned by their instances, the Legal Hold, Retention Window and Audit Trail stores by the substrate; the composition indexes across them and owns none (Composes 11).

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
Composition state 15: The composition MUST derive a request's state from the fulfillment index AND the trail.
Composition state 16: IF a fulfillment entry EXISTS for the request THEN the request's state MUST carry Fulfilled.
Composition state 17: IF an open intent EXISTS for the request THEN the request's state MUST carry Committing.
Composition state 18: The composition MUST NOT store a subject's enumerated universe.
```

Term request id: the opaque id the host injects at [Receive Request]'s seam — never reused.

Term request index: the composition's map from a request id to the request's intake — `request_to_subject` in an implementation.

Term request entry: one request id's subject reference, right type, requester, regulatory reference and received instant.

Term fulfillment index: the composition's map from a request id to the request's fulfillment — `request_to_fulfillment` in an implementation; the queryable mirror of the sealed fulfilled event.

Term fulfillment entry: one request id's right type, fulfilled instant, [Dispositions], response disclosure id and fulfillment event id.

Term live entry: an index entry whose event's payload the audit horizon has not reached.

Term aged entry: an index entry whose event's payload the audit horizon has destroyed.

Term intake event: the dsar.received event.

Term intent: the access intent or the erasure intent.

Term open intent: an intent for the request that no fulfilled event and no abandonment names.

Term fulfilled event: the dsar.access_fulfilled or dsar.erasure_fulfilled event.

Term abandonment: the dsar.intent_abandoned event — naming the intent it closes, returning the request to Received.

Term request state: Received | Committing | Fulfilled — derived, never stored.

WHY:
**Two indexes, one sealed truth** (Composition state 1 through 11). The request index is the intake's provenance — *that* a request was received, for which subject, of which type, from whom, under which regulation, and when — the records-alone source for the statutory clock and the join from a request id back to its subject. The fulfillment index is the binding backbone: the complete [Dispositions] over the enumerated universe, the response disclosure and the fulfilled event. The fulfilled event carries the complete disposition set in its payload, so the index is the queryable mirror of a sealed event, never an independent store an edit could silently diverge from (Composition state 10). Both are written once, after the event they mirror lands, and never changed; Fulfilled is terminal.

**Classification** (Composition state 12 through 14; the section titled Composition state in `execution-contract.md`). A live entry rebuilds from its event and is a derived index. Past the audit horizon the substrate's purge destroys the event's payload, and the entry is then the only carrier of what was decided — extraction-pending, its eventual home the same Erasure Tombstone *(forthcoming)* that carries Audit Trail's purged pairs. For a fulfilled erasure that is load-bearing rather than tidy: the entry may be the only surviving description of records that no longer exist.

**The request state is derived from the trail** (Composition state 15 through 17). Received is an intake and nothing after it; Committing is an open intent — a fulfillment in flight, or one that died after its intent; Fulfilled is a fulfillment entry. **Committing is the state an earlier draft lacked**, and its absence let a re-invocation re-run a fulfillment: a request whose fulfillment failed after its response disclosure or its purges had committed read as Received, the caller retried on the page's own advice, and the retry wrote a second permanent disclosure, a second sealed event racing the first's compensation, and dispositioned already-erased records as registry anomalies. A Committing request is refused by both siblings (Action wiring 6) and closed only by the reconciliation or by the invocation's own abandonment.

**The universe is not stored** (Composition state 18): it is computed at fulfillment by the universe enumeration, and the fulfillment entry's [Dispositions] *is* the durable, records-alone snapshot of it as it stood at the fulfilled instant.

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the record source registry.
Capability requirement 2: EVERY registered source MUST expose a subject-scoped enumeration answering the record reference, the source AND the creation instant PER record.
Capability requirement 3: EVERY registered source MUST expose the declared basis PER record.
Capability requirement 4: EVERY registered source MUST expose the host determinations PER record.
Capability requirement 5: EVERY registered record MUST carry EXACTLY ONE OF a retention id, the host delete.
Capability requirement 6: The host delete MUST verify the presented credential at the host's own boundary.
Capability requirement 7: The universe enumeration MUST NOT enumerate an accounting store.
Capability requirement 8: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 9: A deployment MUST set an audit retention policy whose horizon EXCEEDS the longest retention obligation a registered record carries.
Capability requirement 10: The Defensible Retention instance MUST run strict as the hold check mode.
Capability requirement 11: The composition MUST NOT claim Invariant 3 over a Defensible Retention instance running advisory.
Capability requirement 12: A deployment MUST provision the service identity.
Capability requirement 13: The composition MUST attest EVERY write the composition makes outside a caller's invocation under the service identity.
Capability requirement 14: The composition MUST record EVERY finding as a finding opened event.
Capability requirement 15: The composition MUST close a finding ONLY by a finding closed event naming the finding.
Capability requirement 16: A deployment MUST set the compensation window.
Capability requirement 17: A deployment MUST set the fulfillment completion bound.
Capability requirement 18: A deployment MUST set the reconciliation cadence.
Capability requirement 19: The reconciliation cadence MUST NOT EXCEED the compensation window.
Capability requirement 20: A deployment MUST declare the clock tolerance between a registered source's clock AND the seam's clock.
Capability requirement 21: The host MUST inject now at the seam once per invocation.
Capability requirement 22: The host MUST inject the request id at [Receive Request]'s seam.
Capability requirement 23: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 24: The composition MUST NOT pass now to a constituent.
```

Term record source registry: the deployment-declared list of the business-record sources over which the no-silent-omission guarantee holds, with the per-record surfaces each exposes.

Term creation instant: a record's creation time in its source, stamped by the source's own clock.

Term declared basis: the lawful ground a registered record names for its processing — consent carrying a purpose, or a non-consent ground such as legal-obligation, contract or vital-interests.

Term host determinations: the host's per-record Article 15(4) third-party-confidentiality and legal-exemption determinations, consumed by the access dispositions.

Term host delete: the registry-declared delete surface of a host-managed record — `delete(record_ref, actor_ref, credential)` answering deleted carrying the attestation reference, refusing not-known, retained carrying the basis, or delete-failed.

Term host-managed record: a registered record carrying no retention id — erased through the host delete, never through Defensible Retention's gate.

Term accounting store: the Selective Disclosure store or the Consent store — the composition's accounting of the subject, read as response content and never enumerated.

Term audit horizon: the audit retention policy's horizon on the Audit Trail instance Defensible Retention carries.

Term service identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` in configuration.

Term finding opened event: the dsar.finding_opened event — carrying the request id, the finding kind, the record references and the opened instant.

Term finding closed event: the dsar.finding_closed event — naming the finding it closes.

Term finding kind: binding-orphan | layer1-destroyed-unrecorded | anomaly | overdue.

Term compensation window: the duration within which an orphaned fulfillment is compensated or escalated.

Term fulfillment completion bound: the longest a fulfillment may run from its intent to its fulfilled event — the invocation's terminus and the reconciliation's lower edge.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every process start.

Term clock tolerance: the declared skew bound between a registered source's creation instants and the seam's now.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the request id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**The registry is the load-bearing host obligation** (Capability requirement 1 through 7). The universe is the subject's records under the Defensible Retention substrate plus the host business-record stores the registry names, and the registry is the declaring source for every host-supplied capability a disposition rests on: the enumeration with each record's creation instant (which lets an access re-check drop records created after the fulfilment); the declared basis the erasure's other-lawful-basis branch reads; the access determinations; and, for erasure, a retention id — the gated path — or the host delete, whose contract is declared so every arm has a landing. The host delete verifies the credential at its own boundary, as Defensible Retention does at its, because it is independently callable (Capability requirement 6). Declaring these here is what keeps every disposition capability-provenance-clean: its authority traces to declared configuration, not to an ambient *the host knows*. No-silent-omission is a guarantee over the *declared* universe; whether the registry names every store holding the subject's data, and whether each host determination is legally correct, are the host's to clear (External check 1 and 2).

**The accounting stores are response content, not universe** (Capability requirement 7). Their records are append-only and never removable (Selective Disclosure Invariant 6; Consent Invariant 8), expose no declared basis, no retention id and no delete surface — so no erasure branch could resolve one — and they are the composition's accounting of the subject rather than the subject's business records. They answer the recipients and consent-history limbs of an access response, and under erasure they are retained as a class (Accounting stores 1).

**Retention is the substrate's, and it outlives the erasure** (Capability requirement 8 and 9; 2026-08-26-o). record_action takes no per-call retention, so the composition's events land under the instance's policy. The proof that a record was lawfully erased must outlive the record — for FRCP (the US Federal Rules of Civil Procedure) Rule 37(e) spoliation defence above all — so the horizon exceeds the longest retention obligation any registered record carries, an obligation with an owner and a check (Check 8.2) where the prose had a *should*.

**Strict mode is required** (Capability requirement 10 and 11). The erasure gate is mode-conditional in the substrate: under advisory, a held record is purged with a hold override and the purge answers ok. A deployment running an advisory substrate has a rights composition that erases held records and says so in the substrate's own record, and Invariant 3 does not hold there; Check 3.1 tests the assumption on every destruction record it reads.

**The service identity and the findings surface** (Capability requirement 12 through 15). Every write outside a human invocation — the reconciliation's compensations, the response disclosure it completes, abandonments and findings — is attested under the composition's own registered identity, the service-identity discipline Multi-Party Approval established. Every *surfaced to the compliance dashboard* on this page is a finding opened event on the trail, closed by a finding closed event, so a finding's lifecycle — opened, compensated within the window, escalated — is records-alone and the dashboard is a projection over it.

**The window, the bound and the cadence** (Capability requirement 16 through 19). Invariant 1's liveness half is a claim about the window and is unstatable without it — *eventually* is not auditable. The bound is the reconciliation's lower edge: a Committing request younger than it may belong to an invocation about to seal, or to disclose, or still destroying. The cadence bounds detection and the window bounds repair, so a cadence longer than the window makes the window unmeetable by construction. A regulated deployment under litigation exposure sets the window against the FRCP spoliation clock; the composition prescribes no default, because the right value is a legal determination and a silent default would look like one having been made.

**The clock** (Capability requirement 20 through 24; Execution Contract Logic confinement 7). One now and, at intake, one request id are injected per invocation; the now stamps every instant the invocation writes — the received instant, the intended instant, the fulfilled instant — so an invocation's intended and fulfilled instants are equal by construction and the Event Log sequence orders them. It is never handed to a constituent: each stamps its own at its own seam, bound to this one by ids and never claimed equal. The one comparison across clocks — a source's creation instant against the fulfilled instant, in the access re-check — runs under the declared tolerance (2026-08-29-j).

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
```

Term subject reference: the opaque reference to the data subject whose records are the universe.

Term right type: access | erasure — GDPR Article 15 or Article 17.

Term requester: the party who submitted the request — the subject, or an authorized representative; named as the recipient of the response disclosure.

Term regulatory reference: the regulation a request is filed under — "GDPR Article 15", "CCPA §1798.105" — carried as the response disclosure's authority.

Term actor reference: the operator running an action — actor_ref.

Term credential: the operator's opaque credential material, validated by the substrate inside the audit write.

Term record reference: the opaque byte-identity of a record in the enumerated universe — the unit a disposition is recorded against.

Term retention id: the opaque Defensible Retention handle of a record under Defensible Retention retention — the input its purge takes.

Term caller string: a subject reference, a requester, a regulatory reference, an actor reference or a record reference.

WHY:
Every string-typed input is validated here or by a constituent, and nothing is case-folded, trimmed or normalized (Primitive policy 7 and 8); a deployment wanting normalization wires it at the calling layer. **The right type is two values by design** (Primitive policy 4): the spine is Access and Erasure, the two rights whose claims most sharply collide, and the lighter Article 16 through 21 rights are composing concepts, not further right types (Non-goal 6). **The regulatory reference is the request's own** (Primitive policy 3; 2026-08-29-g): a deployment answering both GDPR and CCPA (the California Consumer Privacy Act, as amended by the California Privacy Rights Act) requests cites the regulation each request was filed under on its response disclosure, where a hard-coded GDPR citation made the CCPA example false. The composition does not validate that the subject exists anywhere, or that the requester is the subject or a representative (Non-goal 1), or that the operator is authorized (Non-goal 2). The credential is opaque here; the substrate validates it inside the audit write, reached before any irreversible effect (Invariant 8), and the same actor and credential run every nested act of the invocation, so the substrate's destruction record and this composition's fulfilled event attribute a destruction to one actor (Primitive policy 11).

### Audit arm

```
Audit arm 1: IF Audit Trail answers recording-failure carrying the retention step at a record THEN the composition MUST read the record back.
Audit arm 2: IF Audit Trail answers invalid-request at a record THEN the composition MUST read the record back.
Audit arm 3: IF the read-back finds the record THEN the composition MUST proceed as landed.
Audit arm 4: The composition MUST NOT retry a record the read-back finds.
Audit arm 5: The read-back MUST match a record by the request id AND the record's action reference.
Audit arm 6: IF Audit Trail answers invalid-credential at a pre-effect record THEN the action MUST answer invalid-credential.
Audit arm 7: IF Audit Trail answers recording-failure carrying a pre-append step at a pre-effect record THEN the action MUST answer recording-failure carrying intent.
Audit arm 8: IF the read-back finds no pre-effect record after an invalid-request THEN the action MUST answer invalid-request.
Audit arm 9: The composition MUST NOT retry an invalid-request answer.
Audit arm 10: IF Audit Trail refuses a fulfilled event THEN the fulfillment MUST answer recording-failure carrying outcome.
Audit arm 11: The invocation MUST NOT retry a fulfilled event BEFORE reading the trail for a fulfilled event carrying the request id.
Audit arm 12: IF the read finds a fulfilled event carrying the request id THEN the invocation MUST proceed as landed.
Audit arm 13: The invocation MAY retry a fulfilled event refused with a pre-append step WITHIN the fulfillment completion bound.
Audit arm 14: A spent invocation MUST NOT write.
Audit arm 15: IF Audit Trail answers invalid-credential at a fulfilled event THEN the reconciliation MUST land the fulfilled event under the service identity carrying the compensation flag AND the operator.
Audit arm 16: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 17: A caller MUST read recording-failure carrying outcome as a committed irreversible act.
Audit arm 18: The deployment MUST alert on a record read back as landed carrying no retention.
Audit arm 19: The deployment MUST alert on an invalid-request from Audit Trail as a deployment fault.
```

Term pre-effect record: the intake event, the access intent or the erasure intent — a record written before any irreversible act.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term position: intent | outcome — where a recording-failure sat: intent, nothing irreversible committed; outcome, a permanent disclosure or a destruction exists.

Term spent invocation: an invocation whose `intended instant + fulfillment completion bound` PRECEDES now.

Term compensation flag: cascade_recovery set to true on a fulfilled event that landed through compensation rather than in the original invocation.

WHY:
The substrate's taxonomy maps **by the record's position relative to the irreversible act**, and every action places one record before it (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). **The retention step means the event is in the log** (Audit arm 1 through 5): the substrate places retention after it appends, so a failure there is an appended, attested event, and the composition reads it back and proceeds. This arm was unlanded before this rewrite at the pre-effect records, and the omission was not cosmetic: an intent appended under a retention-step failure and answered as a retryable refusal left an open intent, so the caller's retry met the request Committing and was refused compensation-pending for a fulfillment that had done nothing. The substrate's invalid-request has the same two faces — its retention-configuration source appends, its cap source does not — and the read-back tells them apart.

**Before the irreversible act, every arm is a clean refusal** (Audit arm 6 through 9): invalid-credential is the caller's; a pre-append step is the one retryable arm; invalid-request with nothing appended is a deployment fault, never retried, since a retry re-sends the identical payload. The intake's own invalid-credential answers as itself, which is what the uniform rule said and the intake's step and signature did not (2026-08-26-f, 2026-08-29-b).

**After it, no arm can refuse the act, only report it** (Audit arm 10 through 15). The fulfilled event follows a permanent disclosure, and on the erasure path committed destructions. A retry is preceded by a read for a fulfilled event already carrying the request id, because an append that landed and was not acknowledged, retried blind, mints two fulfilled events for one request (2026-08-29-i). The invocation retries only inside its bound, and past it the event is the reconciliation's alone — one writer (the section titled *A compensator is exclusive* in `pressure-testing.md`). An invalid-credential there is the operator's registration changing between the writes; the reconciliation re-emits under the service identity with the operator named and the compensation flag set.

**The position rides the exported code** (Audit arm 16 and 17; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent tells the caller nothing irreversible happened; outcome tells the caller a disclosure or a destruction exists, and a retry meets compensation-pending until the reconciliation closes the request.

### Action wiring

```
receive_request(subject_ref, right_type, requester, regulatory_reference, actor_ref, credential)
  answers intake result
  refuses invalid-request | invalid-credential | recording-failure(position)

fulfill_access_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | compensation-pending | wrong-right-type | incomplete-enumeration | invalid-credential | invalid-request | recording-failure(position)

fulfill_erasure_request(request_id, actor_ref, credential)
  answers fulfillment result
  refuses not-known | already-fulfilled | compensation-pending | wrong-right-type | incomplete-enumeration | invalid-credential | invalid-request | recording-failure(position)

disposition_report(request_id)
  answers report
  refuses not-known
```

Term intake result: the request id and the received instant.

Term fulfillment result: the request id, the [Dispositions], the response disclosure id and the fulfilled event's id.

Term report: the request state, the right type and the received instant, and for a Fulfilled request the [Dispositions], the response disclosure id and the fulfilled instant.

```
Action wiring 1: A validated intake MUST take the request id from the seam.
Action wiring 2: A validated intake MUST record the intake event carrying the request id, the subject reference, the right type, the requester, the regulatory reference AND now as the received instant.
Action wiring 3: A landed intake MUST write the request entry AND answer the intake result.
Action wiring 4: IF no request entry EXISTS for the request id THEN a fulfillment MUST answer not-known.
Action wiring 5: IF the request's state EQUALS Fulfilled THEN a fulfillment MUST answer already-fulfilled.
Action wiring 6: IF the request's state EQUALS Committing THEN a fulfillment MUST answer compensation-pending.
Action wiring 7: A fulfillment MUST NOT check the right type BEFORE checking the request's state.
Action wiring 8: IF the right type DOES NOT EQUAL access THEN [Fulfill Access Request] MUST answer wrong-right-type.
Action wiring 9: IF the right type DOES NOT EQUAL erasure THEN [Fulfill Erasure Request] MUST answer wrong-right-type.
Action wiring 10: A refusal under Action wiring 4 through 9 MUST NOT write.
Action wiring 11: An admitted fulfillment MUST enumerate the subject's universe through the universe enumeration.
Action wiring 12: IF a registered source fails to enumerate THEN the fulfillment MUST answer incomplete-enumeration.
Action wiring 13: A fulfillment answering incomplete-enumeration MUST NOT write.
Action wiring 14: An enumerated fulfillment MUST disposition EVERY enumerated record PER Disposition 1 through 38.
Action wiring 15: An enumerated access MUST read the disclosure read AND Consent's read for the subject.
Action wiring 16: An enumerated access MUST record the access intent carrying the request id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read AND now as the intended instant.
Action wiring 17: The composition MUST NOT call the disclosure write BEFORE the fulfillment's intent lands.
Action wiring 18: An intended access MUST call the disclosure write with the subject reference, the requester as the recipient, the access scope AND the regulatory reference as the authority.
Action wiring 19: IF the disclosure write refuses an intended access THEN the fulfillment MUST record an abandonment naming the access intent.
Action wiring 20: IF the disclosure write answers storage-failure to an intended access THEN [Fulfill Access Request] MUST answer recording-failure carrying intent.
Action wiring 21: IF the disclosure write answers a disclosure fault THEN the fulfillment MUST answer invalid-request.
Action wiring 22: A disclosed access MUST record the access fulfilled event carrying the request id, the subject reference, the requester, the dispositions, the universe cardinality, the recipients read, the consents read, the response disclosure id AND now as the fulfilled instant.
Action wiring 23: An enumerated erasure MUST NOT call a destroying surface BEFORE the erasure intent lands.
Action wiring 24: An enumerated erasure MUST record the erasure intent carrying the request id, the subject reference, the provisional dispositions, the universe cardinality, the purge plan, the host delete plan AND now as the intended instant.
Action wiring 25: An intended erasure MUST call Defensible Retention's purge PER pair of the purge plan with the retention id, the actor reference AND the credential.
Action wiring 26: An intended erasure MUST call the host delete PER record of the host delete plan with the record reference, the actor reference AND the credential.
Action wiring 27: An intended erasure MUST settle each planned record's disposition from the planned call's answer.
Action wiring 28: An executed erasure MUST call the disclosure write with the subject reference, the requester as the recipient, the erasure scope AND the regulatory reference as the authority.
Action wiring 29: IF the disclosure write refuses an executed erasure AND an erased disposition EXISTS THEN [Fulfill Erasure Request] MUST answer recording-failure carrying outcome.
Action wiring 30: IF the disclosure write refuses an executed erasure AND no erased disposition EXISTS THEN the fulfillment MUST record an abandonment naming the erasure intent.
Action wiring 31: A disclosed erasure MUST record the erasure fulfilled event carrying the request id, the subject reference, the requester, the dispositions, the universe cardinality, the response disclosure id AND now as the fulfilled instant.
Action wiring 32: IF a disposition set EXCEEDS Audit Trail's payload cap THEN the record MUST carry the disposition digest AND the universe cardinality.
Action wiring 33: A landed fulfillment MUST write the fulfillment entry AND answer the fulfillment result.
Action wiring 34: IF no request entry EXISTS for the request id THEN [Disposition Report] MUST answer not-known.
Action wiring 35: [Disposition Report] MUST answer the report.
Action wiring 36: [Disposition Report] MUST NOT record an audit event.
```

Term validated intake: a [Receive Request] call whose inputs cleared Primitive policy.

Term landed intake: a validated intake whose intake event landed.

Term fulfillment: a [Fulfill Access Request] or [Fulfill Erasure Request] call.

Term admitted fulfillment: a fulfillment Action wiring 4 through 9 did not refuse.

Term enumerated fulfillment: an admitted fulfillment whose enumeration answered every registered source.

Term enumerated access: an enumerated fulfillment of [Fulfill Access Request].

Term enumerated erasure: an enumerated fulfillment of [Fulfill Erasure Request].

Term universe cardinality: the count of records the enumeration answered.

Term recipients read: the disclosure ids the disclosure read answered for the subject — the Article 15(1)(c) limb.

Term consents read: the consent ids Consent's read answered for the subject — the consent-history limb.

Term access intent: the dsar.access_fulfillment_intended event.

Term intended access: an enumerated access whose access intent landed.

Term access scope: dsar:access:designated-record-set: followed by the request id.

Term disclosure fault: invalid-request | unknown-authority-type — the disclosure write's refusals that are deployment faults.

Term disclosed access: an intended access whose disclosure write answered the response disclosure id.

Term erasure intent: the dsar.erasure_execution_intended event.

Term provisional dispositions: the dispositions Disposition 1 through 19 resolve before any planned call runs.

Term purge plan: the confirmed retention id and record reference pairs bound for Defensible Retention's purge.

Term host delete plan: the record references bound for the host delete.

Term destroying surface: Defensible Retention's purge or the host delete.

Term intended erasure: an enumerated erasure whose erasure intent landed.

Term executed erasure: an intended erasure whose every planned call answered.

Term erasure scope: dsar:erasure:outcome: followed by the request id.

Term disclosed erasure: an executed erasure whose disclosure write answered the response disclosure id.

Term landed fulfillment: a disclosed access or a disclosed erasure whose fulfilled event landed.

WHY:
**Two siblings over one core** (Action wiring 11 through 33). Both enumerate, disposition every record, write an intent, bind the response disclosure, and seal last; they differ in their disposition vocabulary and their downstream effect — access determines and discloses, erasure determines and, for erased records, destroys. They stay two actions rather than one parametrized fulfillment because an irreversible destruction and a pure disclosure behind one flag would hide the load-bearing fork a reader must see at the signature; the shared machinery lives once, in these rules and the invariants, so the siblings duplicate no logic.

**Terminality before type, and Committing refused** (Action wiring 4 through 10). Against a Fulfilled request the sibling answers already-fulfilled before it reaches the right type, so wrong-right-type is exercised only by a request not yet fulfilled. A Committing request is refused compensation-pending: a fulfillment of it is in flight or died after its intent, and re-running it would duplicate a permanent disclosure or re-plan erased records; the caller reads [Disposition Report] for the outcome.

**Completeness is all-or-nothing at the enumeration** (Action wiring 11 through 13): a source that fails to enumerate refuses the fulfillment with nothing written, because a partial universe fulfilled as if whole is the silent omission the composition exists to forbid. An enumeration that finds no records is a valid fulfillment with an empty set — the meaningful *we hold no records about you* — distinct from [Incomplete Enumeration].

**The intent carries the whole disposition set** (Action wiring 16 and 24). If the fulfilled event fails or the process dies between the writes, the set exists nowhere else, and re-enumerating is no lawful substitute: a disposition set is a point-in-time verdict, and a compensating event must say what was decided then. On the erasure path the intent carries the plan **and, separately, the provisional disposition for every record** — the plan names only what an irreversible act was about to touch, so a compensation rebuilt from it alone would omit exactly the retained and anomalous records no downstream event attests, reintroducing the silent omission through the recovery path. The intent is also the authentication (Invariant 8), the recovery marker, and on the erasure path the **nesting link**: this composition and Defensible Retention share one trail, so without the plan a reader could not tell a purge occasioned by an authorized rights fulfillment from a direct call that bypassed the rights process (Check 6.3). Authentication is not inherited across that boundary: the substrate's purge is independently callable and re-verifies the same credential at its own intent, which is the direct-call path's whole defence; the plan records provenance, not authority.

**The recipients and consent limbs are sealed as ids, not a digest** (Action wiring 15, 16 and 22; 2026-08-26-m). A digest of a read over an append-only store diverges by construction — every later disclosure, the response disclosure itself included, changes it — so a digest could never be recomputed. The ids read are immutable and each resolves, so the sealed limb is performable: a host that drops a recipient from the export leaves an id the export does not answer.

**The disclosure write's own refusals have landings** (Action wiring 19 through 21 and 28 through 30; 2026-08-26-p, 2026-08-29-c). On the access path nothing irreversible has happened when it refuses, so the invocation closes its own intent with an abandonment — the request returns to Received and a storage-failure is genuinely retryable — and answers; its faults are the deployment's. On the erasure path it refuses after execution: where a destruction exists the answer is outcome and the reconciliation completes the binding; where none does, the invocation abandons as on the access path. **The scope carries the request id** (Action wiring 18 and 28), and that is load-bearing: it is the only join the reconciliation has from a disclosure to a fulfilled event that never landed.

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

*Mechanism.* No — re-deriving hold checking would duplicate exactly the gate Defensible Retention already owns and proves (its Invariant 1), and its purge is irreversible and self-audits each destruction. The composition maps the gate's outcomes onto dispositions (Wiring decision 4 and 5; Disposition 20 through 31), inheriting its structural guarantee and its retention exemption for free, and adds the one concept the substrate does not carry — the Article 17(1)(b) question of whether another lawful basis means erasure was never due, read-only and ahead of any purge (Disposition 7 through 12).

*Result.* Every preservation disposition traces to a records-checkable Defensible Retention outcome, and the composition stays a thin conflict-resolution-and-accounting layer over a proven substrate rather than a re-implementation of it.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a young intent.
Reconciliation 4: The reconciliation MUST NOT write for an aged intent.
Reconciliation 5: The reconciliation MUST attest EVERY write the reconciliation makes under the service identity.
Reconciliation 6: The reconciliation MUST read EVERY request-scoped disclosure against the fulfilled events.
Reconciliation 7: IF no fulfilled event carries a request-scoped disclosure's request id THEN the reconciliation MUST open a binding-orphan finding.
Reconciliation 8: The reconciliation MUST pair a request-scoped disclosure to the request's open intent.
Reconciliation 9: The reconciliation MUST NOT resolve an open intent on the erasure path BEFORE diffing the purge plan against the destruction records AND the host delete plan against the host attestations.
Reconciliation 10: The reconciliation MUST NOT record a fulfilled event BEFORE the reconciliation's recovery intent lands.
Reconciliation 11: A recovery intent MUST carry the request id, the intent event id AND the case.
Reconciliation 12: IF a request-scoped disclosure carries the open intent's request id THEN the reconciliation MUST record the fulfilled event from the intent's dispositions carrying the compensation flag AND the operator.
Reconciliation 13: IF no request-scoped disclosure carries the open intent's request id AND a planned destruction landed THEN the reconciliation MUST record the response disclosure AND then the fulfilled event carrying the compensation flag AND the operator.
Reconciliation 14: IF the reconciliation completes an erasure THEN a planned record the fulfillment never reached MUST carry anomaly carrying not-attempted.
Reconciliation 15: IF no request-scoped disclosure carries the open intent's request id AND no planned destruction landed THEN the reconciliation MUST record an abandonment naming the intent.
Reconciliation 16: The reconciliation MUST correct the intent's dispositions against the diff.
Reconciliation 17: The reconciliation MUST NOT record a fulfilled event BEFORE reading the trail for a fulfilled event carrying the request id.
Reconciliation 18: The reconciliation MUST write the fulfillment entry ONLY AFTER the compensating fulfilled event lands.
Reconciliation 19: The reconciliation MUST read EVERY destruction record against the erasure fulfilled events AND the purge plans.
Reconciliation 20: IF a destroyed record carries no destruction record THEN the reconciliation MUST open a layer1-destroyed-unrecorded finding.
Reconciliation 21: The reconciliation MUST NOT compensate a Layer-1 orphan with a fulfilled event.
Reconciliation 22: The reconciliation MUST escalate EVERY overdue orphan as an overdue finding.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a compensated, completed or abandoned fulfillment, or an escalation — an auditor awaits within the compensation window.

Term young intent: an open intent whose `intended instant + fulfillment completion bound` DOES NOT PRECEDE now.

Term aged intent: an open intent whose `recording instant + audit horizon` PRECEDES now.

Term request-scoped disclosure: a Selective Disclosure record whose scope is an access scope or an erasure scope.

Term recovery intent: the dsar.recovery_intended event — the reconciliation's intent record, naming the request, the intent it resolves and the case.

Term case: compensate | complete | abandon — the closure Reconciliation 12, 13 or 15 makes.

Term destruction record: Defensible Retention's record_purged outcome.

Term planned destruction: a purge plan pair carrying a destruction record, or a host delete plan record carrying a host attestation.

Term Layer-1 orphan: a record Defensible Retention destroyed whose destruction record is still owed — the substrate's own orphan, owned by its own reconciliation.

Term binding orphan: a request-scoped disclosure carrying no fulfilled event — this composition's own orphan.

Term overdue orphan: an orphan whose first record's `recording instant + compensation window` PRECEDES now.

WHY:
**Why the reconciliation is mandatory.** Both orphan layers are reachable by a *return* — the action answers outcome and the orphan is surfaced — and by a *crash*, where nothing returns. Only the first surfaces itself; the second is what Invariant 1's second safety half is about, and this leg is the whole of what makes it true. It is **Reconciliation, not Housekeeping**: an auditor awaits its output within the compensation window.

**Bounded at both ends, as the composition** (Reconciliation 3 through 5 and 10 through 11; the sections titled *A reconciliation is bounded at both ends* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below: a Committing request younger than the bound may belong to an invocation about to seal, and a compensation fired at it would seal beside it, or write a second response disclosure beside the one the invocation is about to bind. Above: past the audit horizon the intent is destroyed, and a response disclosure whose fulfilled event aged out is lawful destruction, never an orphan. Every write is attested under the service identity, and every closure that seals or discloses is preceded by a recovery intent, so the trail shows the act was occasioned by the leg and not by a direct call.

**Pairing is exact by construction** (Reconciliation 8): the Committing gate admits at most one open intent per request, and a disclosure's scope carries the request id, so a disclosure pairs to the one open intent for its request; an abandoned intent beside an open one is closed history.

**Three directions.** *Disclosures against fulfilled events* (Reconciliation 6 and 7) finds the binding orphan — the shape the crash leaves, and the reason the request id is in the scope at all. *Open intents against outcomes* (Reconciliation 9 and 12 through 18) resolves each by what committed, the diff always first: a disclosure exists → compensate, sealing the intent's dispositions; no disclosure but a destruction landed → complete, writing the disclosure under the service identity and then the event, with each planned record the fulfillment never reached marked not-attempted; nothing committed → abandon. An earlier draft compensated every unmatched intent, which for the third case wrote a sealed event with no disclosure behind it — the reverse orphan Invariant 1's safety half forbids, produced by the recovery path itself. The event is always preceded by a read for one already carrying the request id (Reconciliation 17). *Destruction records against fulfilled events* (Reconciliation 19 through 21) finds the Layer-1 orphan, which the composition surfaces and cannot repair — a composition-level event does not supply the substrate's missing destruction record — and routes to Defensible Retention's own reconciliation, the FRCP-grade alerting condition the substrate names.

**The plan makes the gap reconstructible, and the intent makes it compensable.** The plan diff settles the *destruction* remainder — which records were destroyed and which were not reached; the record a compensation writes must be the **complete disposition set** over the whole universe, retained and anomalous records included, which is why the intent carries it and Reconciliation 16 corrects it against the diff. An orphan not compensated within the window escalates (Reconciliation 22): a retry loop with no bound is indistinguishable, from the records, from an orphan nobody is working on.

### Disposition

```
Disposition 1: EVERY enumerated record MUST carry EXACTLY ONE disposition.
Disposition 2: A disposition MUST carry the record reference, the source, the verdict AND the reason.
Disposition 3: IF the host determinations name third-party confidentiality for a record THEN the record MUST carry withheld carrying third-party-confidentiality.
Disposition 4: IF the host determinations name a legal exemption for a record THEN the record MUST carry withheld carrying legal-exemption.
Disposition 5: IF the host determinations fail for a record THEN the record MUST carry anomaly carrying determination-unavailable.
Disposition 6: IF the host determinations answer no bar for a record THEN the record MUST carry included.
Disposition 7: IF a record's declared basis names a non-consent ground THEN the record MUST carry retained carrying other-lawful-basis AND the ground.
Disposition 8: The composition MUST read a declared non-consent ground as in force as the registry declares.
Disposition 9: IF a record's declared basis names consent THEN the composition MUST call Consent's check with the subject reference AND the purpose.
Disposition 10: IF Consent's check answers granted THEN the record MUST carry retained carrying other-lawful-basis AND the consent id.
Disposition 11: IF Consent's check answers not-known THEN the record MUST carry anomaly carrying consent-basis-not-known.
Disposition 12: IF Consent's check answers a withdrawn answer THEN the record's reason MUST carry the check's answer AND the consent id.
Disposition 13: The composition MUST confirm a record's retention id against Defensible Retention's purge eligible answer.
Disposition 14: IF the purge eligible answer pairs the retention id with another record reference THEN the record MUST carry anomaly carrying mis-paired.
Disposition 15: IF the retention id IS NOT IN the purge eligible answer THEN the record's reason MUST carry unconfirmed-pairing.
Disposition 16: The composition MUST NOT plan a settled record.
Disposition 17: The composition MUST add an unsettled record carrying a retention id to the purge plan.
Disposition 18: The composition MUST add an unsettled host-managed record to the host delete plan.
Disposition 19: A planned record's provisional disposition MUST carry planned.
Disposition 20: IF the purge answers ok THEN the record MUST carry erased.
Disposition 21: IF the purge answers under-legal-hold THEN the record MUST carry retained carrying legal-hold AND the hold ids.
Disposition 22: IF the purge answers not-eligible THEN the record MUST carry retained carrying retention-obligation AND the retention id.
Disposition 23: IF the purge answers under-active-retention THEN the record MUST carry retained carrying retention-obligation AND the sibling retention.
Disposition 24: IF the purge answers hold-check-unavailable THEN the record MUST carry anomaly carrying hold-check-unavailable.
Disposition 25: IF the purge answers storage-failure THEN the record MUST carry anomaly carrying purge-storage-failure.
Disposition 26: IF the purge answers recording-failure carrying outcome THEN the record MUST carry erased carrying the owed destruction record.
Disposition 27: IF the purge answers an indeterminate answer THEN the composition MUST re-invoke the purge once.
Disposition 28: IF the re-invoked purge answers not-known THEN the record MUST carry erased.
Disposition 29: IF the re-invoked purge answers an indeterminate answer THEN the record MUST carry anomaly carrying gate-indeterminate.
Disposition 30: IF the first purge answers not-known AND a destruction record EXISTS for the retention id THEN the record MUST carry erased carrying the destruction record.
Disposition 31: IF the first purge answers not-known AND no destruction record EXISTS for the retention id THEN the record MUST carry anomaly carrying unknown-retention.
Disposition 32: IF the host delete answers deleted THEN the record MUST carry erased carrying the attestation reference.
Disposition 33: IF the host delete answers retained THEN the record MUST carry retained carrying other-lawful-basis AND the host's basis.
Disposition 34: IF the host delete answers not-known THEN the record MUST carry anomaly carrying host-record-not-found.
Disposition 35: IF the host delete answers delete-failed THEN the record MUST carry anomaly carrying host-delete-failed.
Disposition 36: IF the host delete answers outside the host delete's contract THEN the record MUST carry anomaly carrying host-delete-indeterminate.
Disposition 37: EVERY anomaly MUST carry a finding opened event naming the record.
Disposition 38: The composition MUST read a fulfillment carrying an anomaly as Fulfilled.
```

Term disposition: a record's verdict — [Included] or [Withheld] for access; [Erased], [Retained] or [Anomaly] for erasure, [Anomaly] for access too.

Term verdict: included | withheld | erased | retained | anomaly.

Term withdrawn answer: revoked | expired — Article 17(1)(b)'s consent withdrawn, or lapsed.

Term settled record: a record Disposition 7, 10, 11 or 14 dispositions before any planned call.

Term unsettled record: an erasure record no settled disposition covers.

Term indeterminate answer: recording-failure carrying intent | invalid-credential | invalid-request — a purge answer that on its own says nothing about the record's fate.

Term sibling retention: the retention id of the other retention still covering the record.

Term planned: the provisional marker of a record in the purge plan or the host delete plan, settled by the planned call's answer.

WHY:
**Access fails closed** (Disposition 3 through 6; 2026-08-26-h). A record is included only when the host's determinations answer no bar; a determination surface that fails yields an anomaly, never an included record released on an error, where the prose's *otherwise included* failed open on exactly the path the erasure ladder fails closed.

**The erasure precedence, first match wins** (Disposition 7 through 12), so the verdict is deterministic and the recorded reason is the strongest applicable claim. **Other lawful basis comes first and is read-only**, because a purge is irreversible and a record another basis preserves must never be probed by destroying it. A declared non-consent ground is read as in force as the registry declares it — the composition has no oracle for it, and whether it truly justifies retention is the host's to clear (Disposition 8; External check 2; 2026-08-29-k). A consent basis goes to the Consent oracle, and all four answers land: granted preserves; revoked or expired — the Article 17(1)(b) *consent withdrawn* — falls through to the gate **carrying the check's answer and the consent id**, so an erasure that rested on a withdrawn consent leaves a records-alone trace of the determination that let it proceed (Disposition 12; 2026-08-26-n); not-known is a registry and Consent disagreement, never silently defaulted either way. The precedence is a recording convention, not a legal ranking: a record under both a hold and another basis is retained for the other basis, and the hold stays observable in the substrate's own stores.

**The pairing is confirmed where it can destroy** (Disposition 13 through 17; 2026-08-26-r, 2026-08-29-e). Defensible Retention's purge-eligible answer lists every elapsed retention with its record — exactly the retentions a purge can destroy — so a mis-pairing there is caught before it destroys the wrong record while recording erased against the named one. A retention it does not list is in its window, and the gate will refuse it; its disposition is then recorded on the registry's word, and the reason says so rather than claiming a confirmation that did not happen.

**Every gate answer lands, and the precedence among them is the substrate's own step order** (Disposition 20 through 31; 2026-08-29-d). The substrate evaluates the sibling set before the hold and eligibility after it, so a held record with a live sibling answers under-active-retention and is retained for its retention obligation — the same Article 17(3)(b) ground reached through the sibling. A storage-failure left the record intact (Defensible Retention's Atomic writes 8); recording-failure carrying outcome means the record is destroyed and the substrate's destruction record is owed to its own reconciliation. **The three indeterminate answers say nothing about the record's fate on their own**, so the purge is re-invoked once, which the substrate's contract makes destruction-safe: its own wiring reads a not-known on a re-invoked purge as a committed destruction. A first not-known is cross-read against the destruction records (Disposition 30 and 31; 2026-08-29-f): a record another request lawfully destroyed between this one's enumeration and its purge is erased — gone — and the reason names the destruction that erased it, never a registry anomaly. The host delete's four arms, and anything outside them, land the same way.

**The anomaly is admitted, and a fulfillment carrying one is Fulfilled** (Disposition 37 and 38; 2026-08-26-g, 2026-08-29-h). An anomaly is the honest verdict where a record's fate or basis could not be settled — never silently erased or retained. It is a member of the vocabulary with a finding attached, and the request is Fulfilled all the same: fulfillment is a point-in-time account of the universe as it stood (Snapshot 1), and the remedy for the record is the finding's resolution and a fresh request, not a request held open indefinitely over a record the substrate or the host must settle first.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent. Each invariant's *Rests on* is its capability-provenance record (the section titled *Capability provenance* in `pressure-testing.md`).

- **Invariant 1 — Binding bijection.**
  ```
  Invariant 1.1: A fulfilled event MUST NOT exist without the fulfillment's response disclosure AND complete dispositions.
  Invariant 1.2: EVERY Fulfilled request MUST carry EXACTLY ONE fulfilled event.
  Invariant 1.3: EVERY fulfilled event MUST name EXACTLY ONE Fulfilled request.
  Invariant 1.4: The composition MUST NOT leave a binding orphan unsurfaced.
  Invariant 1.5: EVERY binding orphan MUST carry a fulfilled event WITHIN the compensation window of the orphan's disclosure.
  Invariant 1.6: EVERY fulfilled event landed through compensation MUST carry the compensation flag.
  ```
  WHY: the binding is a Fulfilled request's complete [Dispositions], its response disclosure and its fulfilled event. **The commit is not atomic across all three**: the event is appended through a substrate that declares an appended event cannot be withdrawn and offers no synchronous rollback, so no transaction spans the disclosure and the event. The honest claim splits, and the write order makes the split favourable (Wiring decision 3). **Safety, by construction** (Invariant 1.1): the event is the last write, so an auditor may read any fulfilled event as a completed fulfillment without qualification — the direction the regulator's question runs. **Safety, no unsurfaced orphan** (Invariant 1.4): the reverse partial — a disclosure whose event never landed — is reachable and durable, and never silent: a returning failure surfaces it in the answer, a crash is caught by the reconciliation. **Liveness** (Invariant 1.5 and 1.6): every orphan is bound within the declared window, and a recovered fulfillment is distinguishable from a clean one. **On the erasure path the purges precede the binding and are irreversible**, so erased records without a binding are reachable — not a counterexample to the bijection, which is a claim about the binding, but the named orphan the Reconciliation governs, exactly as Defensible Retention's own invariants hold modulo its substrate's partial-attestation contract. The model verifies the safety half unconditionally, admits the surfaced orphan as a reachable, durable state, verifies that compensation resolves it and that a recovered binding is distinguishable, and scopes out the inherited purge orphan. *Rests on* Selective Disclosure Invariant 1 and 6 (record immutability, append-only durability); Audit Trail Invariant 1 and its append-only contract — the declared source of the split itself — reached through the substrate; the write order (Action wiring 22 and 31); the request-carrying scope, the reconciliation's join key (Action wiring 18 and 28); the disposition set in both intents (Action wiring 16 and 24), without which the liveness half names a repair with no material; the findings surface and the service identity (Capability requirement 12 through 15); and the declared window and cadence (Capability requirement 16 through 19).
- **Invariant 2 — No-silent-omission.**
  ```
  Invariant 2.1: EVERY Fulfilled request's dispositions MUST carry EXACTLY ONE disposition PER record of the enumerated universe.
  Invariant 2.2: A fulfillment whose enumeration failed MUST NOT produce a fulfilled event.
  ```
  WHY: the totality claim the formal model checks beside the binding. A partial universe is never recorded as if complete. *Rests on* the universe enumeration bounded by the record source registry (Composes 10, Capability requirement 1), and the all-or-nothing guard (Action wiring 12 and 13). The guarantee holds over the *declared* universe; whether the registry names every store holding the subject's data is externally clearable (External check 1) — stated rather than overclaimed.
- **Invariant 3 — Erasure validity.**
  ```
  Invariant 3.1: IF the hold check mode EQUALS strict AND an active hold covers a Defensible Retention-managed record THEN a fulfillment MUST NOT disposition the record erased.
  Invariant 3.2: IF the hold check mode EQUALS strict AND an unelapsed retention covers a Defensible Retention-managed record THEN a fulfillment MUST NOT disposition the record erased.
  ```
  WHY: the composition re-derives no hold checking — the disposition is read directly off the gate. The invariant is scoped to Defensible Retention-managed records because the structural guarantee *is* the substrate's gate; a host-managed record bypasses it (Host-managed records 1). *Rests on* Defensible Retention Invariant 1 (hold-blocks-purge) and its declared purge, whose under-legal-hold, not-eligible and under-active-retention refusals are the source of the three preservation dispositions (Disposition 21 through 23; 2026-08-29-d).
- **Invariant 4 — Disposition groundedness.**
  ```
  Invariant 4.1: EVERY disposition's reason MUST name the authority the disposition rests on.
  ```
  WHY: no verdict is a bare claim. A gated erased names its destruction record; a retained for a hold names the gate record the strict-mode refusal wrote; a retained for a retention obligation names the retention — the substrate writes no record for not-eligible or under-active-retention, both refused before its intent, so the authority is the Retention Window record itself, read through the substrate; a retained for another basis names the consent id and the check's answer, or the declared ground; an erased that fell through a withdrawn consent names that consent too (Disposition 12); an access verdict names the host's determination; a host-managed verdict names the host's attestation or basis; an anomaly names its finding. *Rests on* Defensible Retention's purge, Consent's check and read, and the registry's declared surfaces. The host-managed and host-determined branches are host-attested rather than records-checkable, so their legitimacy is externally clearable (External check 2).
- **Invariant 5 — Every response disclosure recorded.**
  ```
  Invariant 5.1: EVERY Fulfilled request MUST carry EXACTLY ONE response disclosure.
  ```
  WHY: the release of the subject's data, or of the erasure outcome, back to the requester is itself an accountable, immutable disclosure. *Rests on* the disclosure write and Selective Disclosure Invariant 1 and 6, and Invariant 1's binding.
- **Invariant 6 — Fulfillment terminality.**
  ```
  Invariant 6.1: A Fulfilled request MUST NOT leave Fulfilled.
  Invariant 6.2: A fulfillment of a Fulfilled request MUST NOT write.
  ```
  WHY: a request moves Received → Committing → Fulfilled, Committing entered by an intent and left by the fulfilled event or by an abandonment back to Received; Fulfilled is terminal, so no second disposition set, no second disclosure, no second event. *Rests on* the write-once fulfillment index (Composition state 9 and 11) and the already-fulfilled guard (Action wiring 5); the request-lifecycle analog of Consent's terminal absorption.
- **Invariant 7 — Consent non-mutation.**
  ```
  Invariant 7.1: The composition MUST NOT call a Consent write.
  Invariant 7.2: The composition MUST call Consent ONLY through check AND read.
  ```
  WHY: this is what keeps Consent a freestanding authority oracle rather than state this composition co-owns; were the composition to mutate consent, it and Propagate Consent Revocation Downstream would both own consent state — the ambiguity the read-only discipline forecloses, and the reason the EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) cut names Consent a decision-input oracle. Check 7.1 and 7.2 read it from the records, and External check 6 from the code (2026-08-26-l).
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
  - **Binds the fulfillment (disclosure first, sealed event last):** `SelectiveDisclosure.record(subject_ref = "user-5521", recipient = "user-5521 (verified via privacy portal)", scope = "dsar:access:designated-record-set:dsar-3001", authority = {type: regulatory, reference: "GDPR Article 15"})` → `disc-9001`; then `AuditTrail.record_action(action_ref = dsar.access_fulfilled, actor_ref = "dsr_officer_k", <cred>, data = {request_id: "dsar-3001", dispositions: <the complete five-record set, summary: 3 included / 2 withheld>, universe_cardinality: 5, recipients: <the two disclosure ids read>, consents: <the consent ids read>, response_disclosure_id: "disc-9001", fulfilled_at})` → `ev-7001`; then `request_to_fulfillment["dsar-3001"] = {access, fulfilled_at, dispositions (all five), response_disclosure_id: "disc-9001", fulfillment_event_id: "ev-7001"}`. The request is now **Fulfilled**.
  - Returns the five dispositions, `disc-9001`, and `ev-7001`.

3. **The auditor reads the outcome.** `disposition_report("dsar-3001")` returns one verdict for each of the five enumerated records — Invariant 2 (no-silent-omission): nothing was quietly dropped, and the two withheld records carry a stated reason rather than vanishing from the response. The host then assembles and transmits the actual export for the three included records (the export bytes are the host's job; this composition recorded *what was decided and disclosed*).

### Walkthrough — GDPR Article 17 erasure request, the hold gate firing

A bank deploys this composition over its customer records; the Defensible Retention substrate runs `hold_check_mode = strict` (the required posture under litigation exposure). A customer requests erasure.

1. **Intake.** `receive_request(subject_ref = "cust-8830", right_type = "erasure", requester = "cust-8830", regulatory_reference = "GDPR Article 17", actor_ref = "dsr_officer_m", credential = <cred>)` → `{request_id = "dsar-4002", received_at}`. `dsar.received` recorded; **Received**.

2. **Fulfillment.** `fulfill_erasure_request("dsar-4002", "dsr_officer_m", <cred>)`. The composition **enumerates** four in-scope records and resolves each by the disposition precedence:
  - `r1` — a marketing profile under Defensible Retention retention `ret-r1` (retention elapsed, no hold), declared basis `consent(marketing:email)`. Other-lawful-basis probe: `Consent.check("cust-8830", "marketing:email")` → revoked, and no other basis is declared → erasure is due. `purge_record(ret-r1, "dsr_officer_m", <cred>)` → `ok` → **erased**. (Defensible Retention records its own `record_purged` event with `hold_check_result: empty`.)
  - `r2` — a transaction record under `ret-r2`, covered by an Active litigation hold. Other-lawful-basis: none. `purge_record(ret-r2, …)` → `under-legal-hold` → **`retained(legal-hold)`** (Article 17(3)(e)), reason carrying the blocking `hold_id`. **The hold gate fires** — this is the collision this composition exists to resolve, read directly off Defensible Retention's gate. (Defensible Retention records a `purge_blocked_by_hold` event.)
  - `r3` — a Customer Due Diligence identity record under `ret-r3`, a 5-year retention obligation not yet elapsed. Other-lawful-basis: none asserted. `purge_record(ret-r3, …)` → `not-eligible` → **`retained(retention-obligation)`** (Article 17(3)(b)).
  - `r4` — a fraud-monitoring record whose declared basis is `legal-obligation` (AML — Anti-Money-Laundering — monitoring), a non-consent lawful ground still in force. Other-lawful-basis probe matches first → **`retained(other-lawful-basis)`** (Article 17(1)(b) — a ground for processing persists); **no `purge_record` call is made** for `r4`.
  - **Binds the fulfillment (disclosure first, sealed event last):** `SelectiveDisclosure.record(subject_ref = "cust-8830", recipient = "cust-8830", scope = "dsar:erasure:outcome:dsar-4002", authority = {type: regulatory, reference: "GDPR Article 17"})` → `disc-9002`; then `AuditTrail.record_action(action_ref = dsar.erasure_fulfilled, …, data = {request_id: "dsar-4002", dispositions: <the complete four-record set, summary: 1 erased / 3 retained>, response_disclosure_id: "disc-9002", fulfilled_at})` → `ev-7002`; then `request_to_fulfillment["dsar-4002"]` is populated. **Fulfilled.**

3. **The outcome is defensible from the records.** `disposition_report("dsar-4002")` shows all four records dispositioned (Invariant 2): one erased, three retained with three *different* reasons, each traceable (Invariant 4) — `r2` and `r3` to their Defensible Retention `purge_record` outcomes, `r4` to the host-declared AML basis, `r1`'s erasure to a `record_purged` event whose `hold_check_result: empty` proves the gate passed. No held or retention-bound record was erased (Invariant 3). The customer is told, in the response disclosure, exactly what was deleted and what was kept and why.

### Rejection path — re-fulfillment, wrong right type, incomplete enumeration

- **Already fulfilled (terminal).** A retry: `fulfill_erasure_request("dsar-4002", …)` → `rejected(already-fulfilled)`. No second purge, no second disclosure, no second event — `r1` is not erased twice (it is already gone); the single fulfillment from the first call stands (Invariant 6).
- **Wrong right type.** For a *Received, not-yet-fulfilled* erasure request — say `dsar-4003`, intake recorded but no fulfillment yet — `fulfill_access_request("dsar-4003", …)` → `rejected(wrong-right-type)`; the access sibling refuses to fulfill an erasure request. Nothing is recorded. (Against an *already-fulfilled* request the step-1 precedence returns [Already Fulfilled] *before* it reaches the right_type check — terminality dominates wrong-right-type — so the wrong-right-type path is exercised only by a still-Received request.)
- **Incomplete enumeration (the no-silent-omission guard).** During an access fulfillment, one registered source — the support-ticket store — is unreachable. The enumeration cannot be completed over the declared universe → `rejected(incomplete-enumeration)`. **No disposition is recorded, no response-disclosure is written, the request stays Received.** A partial universe is never fulfilled as if whole — the exact silent omission the composition forbids. The officer retries once the store recovers.

### Rejection path — erasure write fails after the purges commit (the orphan)

An erasure fulfillment purges `r1` (step 5 → `ok`, erased) and then, at step 6, the `dsar.erasure_fulfilled` Audit Trail write returns recording-failure (the seal mechanism is briefly unreachable). The composition returns `rejected(recording-failure(outcome))`. The result is an **orphan**: `r1` is irreversibly erased (its Defensible Retention `record_purged` event exists) but `request_to_fulfillment["dsar-4002"]` has no binding and no `dsar.erasure_fulfilled` event. This is the composition's most consequential irreversibility gap, inherited from Defensible Retention's own irreversible-purge contract; the *Cross-store consistency under partial failure* edge case governs compensation (retry the fulfillment-event write until it lands; surface the orphan to the compliance dashboard; the recovered event carries `cascade_recovery = true`). The TLA+ (Temporal Logic of Actions — a formal specification language for concurrent systems) model and its buggy twins make mechanical what is and is not safe here: this state — a partial — is **reachable in the correct model**, deliberately, and is safe because it is surfaced and the compensation is enabled from it. What the twins show is unsafe is the *silent* partial: a twin that reaches the same split with nothing surfacing it and nothing retrying the audit write turns the orphan into a dead end, and that is the state the restated Invariant 1 forbids. The write order is what keeps the reverse orphan — an event with no disclosure behind it — unreachable by any action at all. The model checks it; see the Ledger's `formal:` line.

### CCPA/CPRA — consumer deletion request

A California consumer submits a deletion request under the CCPA (California Consumer Privacy Act), as amended by the CPRA (California Privacy Rights Act). The erasure path runs unchanged; CCPA §1798.105(d)'s retained-purpose exceptions (completing a transaction, detecting security incidents, complying with a legal obligation) map onto the same `retained(...)` dispositions the GDPR Article 17(3) exemptions do — a record kept to satisfy a legal obligation is `retained(retention-obligation)` via the Defensible Retention gate, a record kept under a non-consent basis is `retained(other-lawful-basis)`. The response disclosure carries `authority = {type: regulatory, reference: "CCPA §1798.105"}` — the regulatory reference the request was received under. The cross-domain structural identity is the point: the disposition surface is regulation-agnostic; only the cited authority on the response and the host's exemption determinations change.

### HIPAA §164.524 — access to a designated record set

A patient requests access to their records under HIPAA §164.524 (a covered entity must provide access to protected health information in a *designated record set*). The access path runs; §164.524(a)(1) grounds for denial — psychotherapy notes, information compiled for legal proceedings — map onto `withheld(legal-exemption)` dispositions with the citation as the reason. The Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty here as the HIPAA §164.528 accounting-of-disclosures surface. The same per-record disposition structure serves both regimes.

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
Check 1.1: An auditor MUST find EXACTLY ONE verified fulfilled event carrying the request id of EVERY fulfillment entry (Invariant 1.2).
Check 1.2: An auditor MUST find EVERY fulfillment entry's response disclosure id resolving to a Selective Disclosure record (Invariant 1.1).
Check 1.3: An auditor MUST find EVERY fulfilled event's request id carried by a fulfillment entry (Invariant 1.3).
Check 1.4: An auditor MUST read EVERY request-scoped disclosure against the fulfilled events (Reconciliation 6).
Check 2.1: An auditor MUST find EVERY disposition's verdict IS IN the right type's vocabulary (Disposition 1).
Check 2.2: An auditor MUST find no record reference twice in one disposition set (Invariant 2.1).
Check 2.3: An auditor MUST find each disposition set's cardinality matching the fulfilled event's universe cardinality (Invariant 2.1).
Check 2.4: An auditor MUST re-enumerate an access fulfillment's universe AND find EVERY record whose creation instant PRECEDES the fulfilled instant in the disposition set (Invariant 2.1).
Check 2.5: An auditor MUST read a re-enumerated record whose creation instant falls within the clock tolerance of the fulfilled instant as inconclusive (Capability requirement 20).
Check 2.6: An auditor MUST NOT re-enumerate an erasure fulfillment's universe (Invariant 2.1).
Check 3.1: An auditor MUST find EVERY gated erased disposition's destruction record carrying an empty hold check result AND no hold override (Invariant 3.1).
Check 3.2: An auditor MUST find EVERY retained legal-hold disposition's gate record naming a hold active at the gate record's position (Invariant 3.1).
Check 3.3: An auditor MUST find EVERY retained retention-obligation disposition's retention unelapsed at the fulfilled instant (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY disposition's reason naming a recoverable authority (Invariant 4.1).
Check 5.1: An auditor MUST find EVERY response disclosure naming the requester as the recipient, the request's regulatory reference as the authority AND the request id in the scope (Invariant 5.1).
Check 6.1: An auditor MUST find EVERY access fulfilled event preceded by an access intent under the same request id (Invariant 8.1).
Check 6.2: An auditor MUST find EVERY erasure fulfilled event carrying an erased disposition preceded by an erasure intent under the same request id (Invariant 8.2).
Check 6.3: An auditor MUST attribute EVERY purge intent of Defensible Retention to the nearest preceding purge plan naming the purge's retention id (Action wiring 24).
Check 6.4: An auditor MUST report a purge intent no preceding purge plan names as a direct purge (Action wiring 24).
Check 6.5: An auditor MUST report an attribution to a plan whose fulfillment carries no fulfilled event as presumptive (Action wiring 24).
Check 6.6: An auditor MUST compare an event carrying a recovery marker by the operator the event's payload names (Primitive policy 11).
Check 7.1: An auditor MUST find no consent record whose granting actor EQUALS the service identity (Invariant 7.1).
Check 7.2: An auditor MUST find no consent record whose revoking actor EQUALS the service identity (Invariant 7.1).
Check 8.1: IF a binding orphan carries no open finding THEN an auditor MUST find the orphan's compensating fulfilled event WITHIN the compensation window (Invariant 1.5).
Check 8.2: An auditor MUST find the audit horizon exceeding the longest retention obligation a registered record carries (Capability requirement 9).
Check 8.3: An auditor MUST find EVERY compensating fulfilled event's dispositions matching the preceding intent's dispositions corrected against the plan diff (Reconciliation 16).
Check 8.4: An auditor MUST find the reconciliation cadence AND the compensation window declared (Capability requirement 19).
Check 9.1: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 6).
Check 9.2: An auditor MUST clear Consent's Generation acceptance over the Consent instance (Composes 6).
Check 9.3: An auditor MUST clear Defensible Retention's Generation acceptance over the substrate (Composes 6).
```

NOTE: EVERY check names the rule the check tests.

Term gated erased disposition: an erased disposition whose record carried a retention id.

Term recovery marker: Defensible Retention's recovery flag on its re-emitted destruction record, or this composition's compensation flag on a fulfilled event.

WHY:
**The binding runs in three directions, and the orphan lives in the third** (Check 1.1 through 1.4): every fulfillment entry has its one verified event and resolving disclosure; every fulfilled event names an entry; and every request-scoped disclosure is read against the fulfilled events — one with none is an orphan, not necessarily a failure, since Invariant 1 admits it; a failure only if unsurfaced or uncompensated (Check 8.1).

**Completeness is right-type-specific** (Check 2.1 through 2.6), because re-enumeration is valid only where nothing was destroyed. For access, re-enumerate over the same registry, drop records created after the fulfilled instant, and every remaining record must be in the set — with a record inside the clock tolerance of the fulfilled instant read as inconclusive, since its creation instant is the source's clock and the fulfilled instant the seam's (2026-08-29-j). For erasure the erased records no longer exist, so re-enumeration would convict every erasure; completeness rests on the sealed set and its cardinality, and each gated erased disposition is cross-read against its destruction record.

**Erasure validity reads the substrate's own records** (Check 3.1 through 3.3). A destruction record carrying a hold override behind an erased disposition means the substrate ran advisory — a conformance failure against the required mode, and a record erased over a hold. A retention obligation is checked against the Retention Window record, because the substrate writes no record for not-eligible or under-active-retention; an earlier form of this check looked for one and failed every conforming implementation.

**Authentication and nesting** (Check 6.1 through 6.6). The earlier intent is the records-alone proof the operator was authenticated before the permanent disclosure and before the first destruction. **The nesting check is the one a regulator asks for**: every substrate purge intent is attributed to the nearest preceding plan naming its retention, exact where that plan's fulfillment completed and presumptive where it did not — an abandoned plan followed by a genuine direct call reads as nested — and one no plan names is a direct purge, lawful on its own for ordinary retention-schedule destruction but the set an auditor must isolate. Plans name *attempted* destructions, so a hold-blocked record is planned again by every later request; *nearest preceding* is well-defined because destruction is at-most-once. **The two recovery markers are distinct** — the substrate's on its re-emitted destruction record, this composition's on a compensated fulfilled event — and a comparison of attesting actors would convict every recovered act, so the operator is read from the payload.

**Consent non-mutation from the records** (Check 7.1 and 7.2): the service identity acts only for this composition, so a consent record granted or revoked under it is a mutation this composition made.

**The compensation must carry the complete set** (Check 8.3): a compensating event whose set is smaller than its intent's is the silent omission reintroduced by the recovery path, and every other check here reads the sealed event and would find it internally consistent. An undeclared window makes the liveness half unfalsifiable and a cadence longer than the window makes it unmeetable — either way visible from the configuration alone (Check 8.4).

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
The received, intended and fulfilled instants are stamped from the one now injected at this composition's own seam (Capability requirement 21 through 24) — best-effort wall-time annotations, while the Event Log sequence, reached through the substrate, is the authoritative order. Skew across seams is the deployment's, under Execution Contract Logic confinement 7; the one comparison the checks make across clocks runs under the declared tolerance. Where DSAR instants carry legal force — proving a request was fulfilled within the statutory window — a Trusted Timestamping pattern (RFC 3161 — the Internet standard for trusted time-stamping) provides the verifiable anchor.

### Concurrency

```
Concurrency 1: The composition MUST serialize the fulfillments of one request id.
Concurrency 2: The composition MUST read the Consent answer a disposition was recorded under as that disposition's basis.
```

WHY:
Two concurrent fulfillments of one request serialize on the request id: the first moves it to Committing, the second meets compensation-pending, and once the first seals, already-fulfilled — exactly as Defensible Retention serializes its hold check and purge on a record. **Two requests for the same subject do not serialize, and two erasures may race on one record**: the loser's purge answers not-known, and the cross-read lands the record erased, naming the other request's destruction (Disposition 30; 2026-08-29-f) — never a registry anomaly. A withdrawal landing after an erasure's Consent read does not reach back into a disposition already bound (Concurrency 2); the subject's remedy is a new request, per the snapshot rule.

### Accounting stores

```
Accounting stores 1: An erasure fulfillment MUST retain the accounting stores as a class.
Accounting stores 2: The composition MUST NOT disposition an accounting store's record.
```

WHY:
The Selective Disclosure and Consent stores hold the composition's *accounting* of the subject — who was told what, and what the subject agreed to — and both are append-only by their atoms' invariants. An erasure neither dispositions their records nor erases them: they are retained as a class under Article 17(3)(b) and (e) and the record-keeping obligations of Article 30 and HIPAA (the US Health Insurance Portability and Accountability Act) §164.528, a basis stated once, here, rather than manufactured per record for records no branch could resolve. Their contents reach the requester as response content.

### Completeness boundary

```
Completeness boundary 1: The composition MUST claim no-silent-omission ONLY over the declared universe.
```

WHY:
A store the registry omits is invisible — its records neither enumerated nor dispositioned, and their absence undetectable, since nothing enumerates what it was never told about. The composition does not guarantee it found *all* of a subject's data across an enterprise; it guarantees it dispositioned every record in the *declared* universe, completely, and bound that set into one sealed act. A deployment that under-declares the registry produces fulfillments that are internally complete and globally partial; closing that is the host's data-mapping discipline (External check 1).

### Host-managed records

```
Host-managed records 1: The composition MUST NOT claim Invariant 3 over a host-managed record.
Host-managed records 2: A deployment needing the hold guarantee over a record MUST place the record under Defensible Retention retention.
```

WHY:
A host-managed record is erased through the host delete, never through the substrate's gate, so a record under a preservation hold registered only in a host store — never placed in Defensible Retention's Legal Hold instance — could be host-erased with no gate firing. The composition has no hold oracle for records outside the substrate and cannot close this from inside; a host-managed erased is a host-attested outcome, not a records-alone-provable one (External check 7).

### Snapshot

```
Snapshot 1: A Fulfilled request MUST NOT cover a record whose creation instant DOES NOT PRECEDE the request's fulfilled instant.
```

WHY:
The disposition set is the universe as enumerated at the fulfilled instant. A record created later — a new ticket, a new transaction — is not retroactively dispositioned by the closed request; a subject wanting it addressed submits a new request. A request answers the state at the time it was answered, as Consent's most-recent-grant semantics and Selective Disclosure's point-in-time history do.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes — the intake ([Receive Request]), the two fulfillment siblings ([Fulfill Access Request], [Fulfill Erasure Request]) and the read-only [Disposition Report]; the [Dispositions] set carrying a verdict for every enumerated record; the closed verdict vocabulary ([Included], [Withheld], [Erased], [Retained], [Anomaly]); and its own fulfillment refusals ([Wrong Right Type], [Already Fulfilled], [Incomplete Enumeration]). No-silent-omission and the binding bijection are structural properties, not data. The deployment settings keep their wire spellings in configuration — `record_source_registry`, `audit_trail_retention_policy`, `application_actor_ref`, `application_credential`, `compensation_window`, `fulfillment_completion_bound`, `reconciliation_cadence`, `clock_tolerance` — and the two indexes theirs in an implementation, `request_to_subject` and `request_to_fulfillment`; the page names each in English where it declares it. Defensible Retention's purge taxonomy is cited whole — ok and the rest of its declared refusals — rather than listed in part. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a requester; a subject; an operator; a reader; an invocation; a fulfillment; a validated intake; a landed intake; an admitted fulfillment; an enumerated fulfillment; an enumerated access; an intended access; a disclosed access; an enumerated erasure; an intended erasure; an executed erasure; a disclosed erasure; a landed fulfillment.

Term records: the intake events, intents, fulfilled events, abandonments, recovery intents and finding events the composition records through the audit write — each an Event Log event carrying one action reference below — the response disclosures it records through the disclosure write, and the two indexes' entries.

Term record verbs: add, adjudicate, alert, answer, assemble, attest, attribute, bind, call, carry, change, check, claim, classify, clear, close, compare, compensate, compose, compute, confirm, correct, cover, declare, derive, disposition, enumerate, escalate, evaluate, examine, exist, expose, find, gate, inherit, inject, inspect, key, land, leave, match, name, normalize, open, own, pair, pass, place, plan, proceed, produce, provision, re-enumerate, re-invoke, reach, read, rebuild, reconcile, record, report, resolve, retain, retry, run, serialize, serve, set, settle, stamp, store, take, verify, write.

Term value sets: action reference = dsar.received | dsar.access_fulfillment_intended | dsar.erasure_execution_intended | dsar.access_fulfilled | dsar.erasure_fulfilled | dsar.intent_abandoned | dsar.recovery_intended | dsar.finding_opened | dsar.finding_closed. withheld reason = third-party-confidentiality | legal-exemption. retained reason = legal-hold | retention-obligation | other-lawful-basis. anomaly reason = determination-unavailable | consent-basis-not-known | mis-paired | hold-check-unavailable | purge-storage-failure | gate-indeterminate | unknown-retention | host-record-not-found | host-delete-failed | host-delete-indeterminate | not-attempted. The rest are declared where the section that owns each declares it: right type, request state, verdict, position, case, finding kind, withdrawn answer, indeterminate answer, disclosure fault.

Term bounds: compensation window (compensation_window), fulfillment completion bound (fulfillment_completion_bound), clock tolerance (clock_tolerance), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive pattern, audit write, disclosure write, disclosure read, universe enumeration, request id, request index, request entry, fulfillment index, fulfillment entry, live entry, aged entry, intake event, intent, open intent, fulfilled event, abandonment, request state, record source registry, creation instant, declared basis, host determinations, host delete, host-managed record, accounting store, audit horizon, service identity, finding opened event, finding closed event, finding kind, compensation window, fulfillment completion bound, reconciliation cadence, clock tolerance, seam, now, subject reference, right type, requester, regulatory reference, actor reference, credential, record reference, retention id, caller string, pre-effect record, pre-append step, retention step, position, spent invocation, compensation flag, intake result, fulfillment result, report, validated intake, landed intake, fulfillment, admitted fulfillment, enumerated fulfillment, enumerated access, enumerated erasure, universe cardinality, recipients read, consents read, access intent, intended access, access scope, disclosure fault, disclosed access, erasure intent, provisional dispositions, purge plan, host delete plan, destroying surface, intended erasure, executed erasure, erasure scope, disclosed erasure, landed fulfillment, reconciliation, young intent, aged intent, request-scoped disclosure, recovery intent, case, destruction record, planned destruction, Layer-1 orphan, binding orphan, overdue orphan, disposition, verdict, withdrawn answer, settled record, unsettled record, indeterminate answer, sibling retention, planned, gated erased disposition, recovery marker.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the substrate. record, read, disclosure id, scope, authority, recipient, invalid-request, unknown-authority-type, storage-failure: Selective Disclosure. check, read, grant, revoke, consent id, purpose, granted, revoked, expired, not-known, granting actor, revoking actor: Consent. purge_record, purge_eligible, ok, not-eligible, under-active-retention, under-legal-hold, hold-check-unavailable, hold ids, hold check mode, strict, advisory, hold check result, hold override, gate record, record_purged, purge_intended: Defensible Retention. record_action, verify_record, payload cap, step-2, step-3, step-4, invalid-credential, recording-failure, Erasure Tombstone: Audit Trail.

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

The access disposition for a record *not* handed over, carrying a stated reason — `third-party-confidentiality` (Article 15(4)) or legal-exemption — so the omission is recorded and attributed, never silent.

Kind:       Member
Member of:  the record disposition
Role:       Disposition
Projection: withheld

#### Erased

The erasure disposition for a record actually destroyed — either through Defensible Retention's `purge_record` returning `ok`, or via a host-owned delete for a host-managed record. Irreversible by the time the fulfillment binds.

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

The disposition for a record whose fate or basis could not be settled — a failed determination, a consent basis the Consent store does not know, a mis-paired or unknown retention, an unavailable hold check, an indeterminate gate or host answer, or a planned record the fulfillment never reached — carrying its reason and an open finding, never silently read as erased or retained. Terminal for the fulfillment; the remedy is the finding's resolution and a fresh request.

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

The fulfillment rejection when the request is already in `request_to_fulfillment` — Fulfilled is terminal (Invariant 6), so a request is fulfilled exactly once.

Kind:       Member
Member of:  the fulfillment rejection
Role:       Rejection
Projection: already-fulfilled

#### Incomplete Enumeration

The fulfillment rejection when any declared record source fails to enumerate — completeness is all-or-nothing at the enumeration boundary, so a partial universe records nothing rather than being fulfilled as if whole (the silent omission the composition exists to forbid).

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
- **GDPR Articles 16, 18, 20, 21 (rectification, restriction, portability, objection)** — named composing concepts (Edge cases — *The lighter Article 15–20 rights*), lighter variants of or feeders into the fulfillment surface rather than additional spines.
- **CCPA / CPRA (California Consumer Privacy Act, as amended by the California Privacy Rights Act)** — §1798.100 (right to access / know) maps to the access path; §1798.105 (right to delete) maps to the erasure path, with §1798.105(d)'s retained-purpose exceptions mapping onto the same `retained(...)` dispositions as the GDPR Article 17(3) exemptions. The cross-domain identity — one disposition surface, regulation-agnostic — is the composition's thesis.
- **HIPAA (US Health Insurance Portability and Accountability Act) §164.524 (Access of individuals to protected health information)** — access to a designated record set; §164.524(a)(1) grounds for denial map to `withheld(legal-exemption)`.
- **HIPAA §164.526 (Amendment of protected health information)** — the rectification analog, a named composing concept (Article 16 family).
- **HIPAA §164.528 (Accounting of disclosures)** — the Selective Disclosure read that answers GDPR Article 15(1)(c) does double duty as the §164.528 accounting surface.

This composition inherits the broader standards compliance of its constituents:

- Through **Defensible Retention** (and transitively Legal Hold, Retention Window, and the Audit Trail substrate with its Event Log, Actor Identity, Tamper Evidence, and Retention Window): FRCP (US Federal Rules of Civil Procedure) Rule 37(e) litigation-hold preservation, SOX (Sarbanes-Oxley Act) §802, SEC (US Securities and Exchange Commission) Rule 17a-4, HIPAA §164.530(j), GDPR Article 17's interaction with retention obligations, and the full Audit Trail standards inheritance (HIPAA §164.312(b) audit controls, ISO/IEC 27001 §A.12.4, GDPR Articles 30 and 32). This composition's erasure gate *is* Defensible Retention's hold-blocks-purge gate, so these are inherited at the gate, not re-anchored.
- Through **Selective Disclosure**: GDPR Article 15(1)(c) and Article 30, HIPAA §164.528, and SEC Rule 17a-4 at the disclosure-accounting layer — the surface that records each fulfillment response and answers the recipients limb of access.
- Through **Consent**: GDPR Article 6(1)(a) and Article 7 (consent as a lawful basis and its withdrawal), Article 17(1)(b) (the withdrawn-consent erasure trigger this composition's other-lawful-basis branch consults), CCPA/CPRA opt-out, and HIPAA §164.508 authorization — read as the authority oracle, never mutated.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — resolve-a-persons-data-rights.tla + 2 twins, 2026-08-27
last gate: 2026-08-29 — second gate after closure, fresh reader — 6 foundational (all since closed), 15 refining (4 since closed), 5 rhetorical (1 since closed)

open:
- 2026-08-29-r · refining · formal · the model's scan carries no lower edge and no recovery record → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/resolve-a-persons-data-rights.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.61; thirty-three of thirty-four open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement whole — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict ladder as its own `Disposition` family; invariant numbers 1 through 8 unchanged, Invariant 9 tombstoned to Composes 6; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and six Edge cases families. Choices the page left open, each decided by a standing rule: the anomaly admitted as a fifth verdict with a finding, terminal for the fulfillment (2026-08-26-g — *as simple as possible without losing fidelity*: a request held open over a record the substrate or the host must settle first answers nothing sooner); access failing closed to an anomaly on a determination error (2026-08-26-h — the same rule the erasure ladder already kept); the recipients and consent limbs sealed as the ids read rather than a digest that diverges by construction (2026-08-26-m); invalid-credential answered as itself at intake (2026-08-26-f, 2026-08-29-b — *make all things mean one thing*); the regulatory reference taken per request (2026-08-29-g — fidelity, since one deployment answers GDPR and CCPA requests alike); the gate's answers mapped by Defensible Retention's own positioned taxonomy, with one destruction-safe re-invocation for the three answers that say nothing about the record (2026-08-26-i, 2026-08-26-j); and an unconfirmable pairing recorded as such in the reason rather than reached through the Retention Window (2026-08-26-r, 2026-08-29-e — *generalize nothing*). One defect found in the pass and fixed in it: the retention-step arm at a pre-effect record was unlanded, so an appended intent answered as retryable left the caller's retry refused compensation-pending. *Over:* the prose's step lists, a closed vocabulary with a fifth member used outside it, and a seal no one could recompute. *Because:* the rules state each landing once and the fork between the siblings once; the formal line stays open because the model, not the page, is what it owes.
- **2026-08-26 — The erasure intent record carries a `purge_plan`, and authentication is not inherited across the substrate boundary.** *Chose:* the plan names the retentions a rights fulfillment will attempt, so a purge occasioned by an authorized fulfillment is distinguishable in the shared Audit Trail from a direct call that bypassed the rights process; Defensible Retention verifies the same credential independently at its own boundary. *Over:* treating the outer authentication as covering the nested purges. *Because:* the substrate's surface is independently callable, so what the plan records is provenance, not authority.
- **2026-08-29 — The scan is bounded at both edges and records its intent before it seals or writes.** *Chose:* `fulfillment_completion_bound` below and the audit horizon above for the reconciliation scan; a `dsar.recovery_intended` record before direction 2's cases (i) and (ii); the pairing stated as exact by the Committing gate. *Over:* a scan on `reconciliation_cadence` alone. *Because:* a Committing request seconds old belongs to an invocation about to seal, and case (ii) would write a second response-disclosure beside the one it is about to bind; a seal the scan writes with no record of its own is indistinguishable from a direct call (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*).
- **2026-08-29 — The accounting stores leave the universe, a request can be Committing, and the scan compensates only what reached the bind.** *Chose:* the Selective Disclosure and Consent stores are response content retained as a class, not dispositioned records; a Committing state (intent with no closing event) that both fulfillment actions refuse with compensation-pending; scan step 2 resolved by whether a response-disclosure exists (compensate), records were destroyed (complete), or nothing committed (abandon); `purge_record`'s shared tokens disambiguated by one destruction-safe re-invocation; `retained(retention-obligation)` grounded in the Retention Window record; findings recorded as `dsar.finding_opened` / `dsar.finding_closed` events under a declared service identity. *Over:* a universe the branches could not disposition, a two-state lifecycle, unconditional compensation, categorical token readings, an event the substrate never emits, and a dashboard nothing declared. *Because:* the page's own walkthroughs violated Invariant 2; a retry after a post-commit failure re-ran the fulfillment; the recovery path produced the reverse orphan the safety half forbids; and check 4 failed every conforming implementation.
- **2026-08-27 — Invariant 1 is safety plus liveness, in three arms.** *Chose:* no `dsar.*_fulfilled` event without its response-disclosure and complete disposition set (earned by write order); no unsurfaced orphan; every orphan compensated within a declared window and distinguishable via `cascade_recovery = true`. *Over:* "commits together or not at all" across a write the substrate cannot withdraw. *Because:* the order was right from the first draft and the claim was merely unprovable — the restatement says what the order earns and nothing more.

NOTE: End of Resolve a Person's Data Rights.

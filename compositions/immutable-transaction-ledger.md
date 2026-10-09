---
title: Immutable Transaction Ledger with Selective Disclosure
parent: Conceptual Compositions
nav_order: 19
has_toc: true
toc: true
---

# Immutable Transaction Ledger with Selective Disclosure

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Immutable Transaction Ledger with Selective Disclosure is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem no single atom solves alone: keeping a tamper-evident, attributed, append-only ledger of transactions *and* being able to hand a regulator, counterparty, or data subject a verifiable slice of it — proving that slice is genuine and was part of the ledger, recording that the disclosure happened and under what authority, and revealing nothing about the rest. It wires three constituents: Recoverable Invocation (the protocol its one irreversible write follows — intent, act, outcome, and a sweep that finishes the accounting of a dead invocation), the Audit Trail substrate (the immutable, attributed, tamper-evident, retention-governed ledger, assembled from Event Log, Actor Identity, Tamper Evidence, and Retention Window) and Selective Disclosure (the durable, append-only accounting of every disclosure — recipient, scope, authority, time).

The composition's two defining emergent guarantees are **disclosure-accountability binding bijection** — every [Disclose Subset] writes exactly one Selective Disclosure record *and* exactly one Audit Trail ledger event recording that the disclosure happened — preceded by an intent event that records the attempt and is where the discloser's credential is checked — three writes in a fixed order, intent then accounting record then outcome, never atomic, with any partial failure closed by Recoverable Invocation's sweep or escalated with a record — so the act of disclosing is itself an immutable, attributed, sealed ledger entry and no disclosure ever lacks its ledger proof silently or permanently — and **verifiable partial disclosure** — any disclosed subset can be independently verified by its recipient as authentic and derived from the ledger, while the undisclosed remainder stays undisclosed and its integrity uncompromised. The first is a structural binding between the two stores; the second is a behavioral obligation on the ledger's tamper-evidence, realized (not defined) by mechanisms such as Merkle inclusion proofs (a path of sibling hashes from one entry to a hash tree's root), cryptographic accumulators (a constant-size commitment with a per-member witness), or signed disclosure packages.

This composition's most common uses are broker-dealer transaction records under SEC (the US Securities and Exchange Commission) Rule 17a-4, accounting-of-disclosures under HIPAA (the US Health Insurance Portability and Accountability Act) section 164.528, regulatory submissions under 21 CFR (the US Code of Federal Regulations) Part 11, and data-subject disclosure accounting under GDPR (the EU General Data Protection Regulation) Article 15. Any system that must keep an immutable, attributed ledger and prove a *subset* of it to an outside party — without exposing the rest and without being able to deny that the disclosure occurred — is a candidate for this composition.

---

## Intent

Every domain that keeps a record of consequential transactions faces the same paired requirement. First, the record must be a **trustworthy ledger**: append-only and totally ordered (no entry inserted out of sequence or quietly back-dated), attributed (every entry tied to a verified actor), tamper-evident (any after-the-fact rewrite detectable from the records alone), and retention-governed (kept for its regulatory lifetime, lawfully destroyable with a defensible record). Second, the record must be **selectively shareable with accountability**: a regulator, counterparty, auditor, or data subject is shown a *subset* of the ledger — a single trade, one patient's billing disclosures, the records pertaining to one matter — and that act of sharing must itself be recorded (to whom, what scope, under what authority, when), while the disclosed subset can be independently verified as genuine and the undisclosed remainder is neither revealed nor weakened.

No single atom satisfies both. The Audit Trail substrate supplies the first: it is the immutable, attributed, tamper-evident, retention-governed ledger, assembled from Event Log (append-only total order), Actor Identity (attribution), Tamper Evidence (sealing), and Retention Window (lifetime). Selective Disclosure supplies the accountability half of the second: a durable, append-only record of every disclosure — recipient, scope, authority, timestamp. But neither provides the full surface until they are wired together. Audit Trail does not know what a *disclosure* is or that disclosing a subset of its own events is itself an auditable event. Selective Disclosure does not perform disclosures, does not seal anything, and — by its own Invariant 5 (no-disclosure-unrecorded) — cannot enforce from inside that every disclosure was in fact recorded; it names that as an integration obligation for a composing pattern to close. The wiring is this composition.

The cross-domain structural identity is the composition's thesis. Under SEC Rule 17a-4 a broker-dealer must keep transaction records in a non-rewritable, non-erasable form and produce them, or a defined subset, on demand for an examiner. Under HIPAA section 164.528 a covered entity must give an individual an accounting of disclosures of their protected health information — what was disclosed, to whom, when, and why — drawn from its records alone. Under 21 CFR Part 11 an electronic record submitted to a regulator must be attributable, contemporaneous, and tamper-evident, with disclosures to the agency themselves recorded. Under GDPR Article 15 a data subject may demand to know what data was disclosed and to which recipients. The structural form is identical across all four: one immutable attributed ledger, and an accountable, independently verifiable mechanism for disclosing a subset of it. One grounded composition satisfies all four.

This is a composition, not a new primitive. The Audit Trail substrate (with its constituent atoms Event Log, Actor Identity, Retention Window, and Tamper Evidence, reached transitively) and Selective Disclosure are unchanged. The composition is the wiring that makes them coherent as a single immutable-ledger-with-accountable-disclosure surface. It introduces emergent actions — [Record Entry], [Disclose Subset], [Verify Disclosure], [Verify Ledger], and a read passthrough — that belong to no single constituent and exist only because the two are wired together. [Disclose Subset] in particular belongs to neither: Selective Disclosure records *that* a disclosure happened but does not seal a verifiable subset of a ledger; Audit Trail seals events but does not know a disclosure is occurring or that it must be accounted. The composition is the layer that answers: *was this subset genuinely part of the ledger, was its disclosure recorded and authorized, and did showing it compromise nothing else?*

What the composition is *not*: it is not a redaction or transmission engine (Selective Disclosure's boundary holds — the composition records and proves disclosure; it does not fetch, redact, or route the underlying payloads); it is not the authorization layer that decides *whether* a disclosure is permitted (that is Consent / Permissions, named as a composing peer); it is not the legal-hold suspension layer over the ledger's retention (Legal Hold / Defensible Retention); it is not an at-most-once append guarantee under retry (Idempotent Reservation / Duplicate Prevention, named as an optional enrichment); and it is not the clock-authority layer (inherited from Audit Trail). Each is named explicitly in Non-goals.

---

## Composes

- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate that *is* the immutable transaction ledger: every entry, every disclosure intent and every disclosure outcome is an attributed, sealed, retention-governed Audit Trail event.
- **[Selective Disclosure](../atoms/selective-disclosure.md)** — the disclosure-accountability surface: the durable, append-only record of every disclosure — recipient, scope, authority, instant.
- **[Recoverable Invocation](./recoverable-invocation.md)** — the protocol [Disclose Subset] follows around its one irreversible write, the accounting record: an intent before it, an outcome after it, the act's critical section over both, and a sweep that closes what a dead invocation left open. Bound once, for the act kind, on an instance that writes to this composition's Audit Trail instance. The bindings are the disclosure binding below; this page restates none of the protocol.

```
Composes 1: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 2: EXACTLY ONE Selective Disclosure instance MUST serve the composition.
Composes 3: The composition MUST reach a transitive atom ONLY through the constituent that composes the atom.
Composes 4: The composition MUST NOT compose an instance of a transitive atom.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST select the ledger events through the ledger enumeration.
Composes 8: The composition MUST read an event by id ONLY through the record read.
Deleted: Composes 9. Recoverable Invocation Action wiring 4 owns it: an adopter's action runs validate, open, commit, close.
Composes 10: A deployment MUST NOT record an event under the ledger namespace outside the composition.
Composes 11: A deployment MUST NOT call the disclosure write outside the composition.
Composes 12: EXACTLY ONE Recoverable Invocation instance MUST serve the composition.
Composes 13: The Recoverable Invocation instance MUST write to the composition's Audit Trail instance.
Composes 14: The composition MUST bind the act kind PER the disclosure binding.
Composes 15: The composition MUST declare the minted key deviation for the act kind.
```

Term composition: this pattern's wiring of [Audit Trail](./audit-trail.md), [Selective Disclosure](../atoms/selective-disclosure.md) and [Recoverable Invocation](./recoverable-invocation.md) — the entry, the disclosure, the two verifications, the reissue, the binding index and the reconciliation.

Term constituents: [Audit Trail](./audit-trail.md), [Selective Disclosure](../atoms/selective-disclosure.md), [Recoverable Invocation](./recoverable-invocation.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail; and [Lease](../atoms/lease.md), reached through Recoverable Invocation.

Term ledger enumeration: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term ledger namespace: the action references ledger.entry, ledger.disclosure.intended, ledger.disclosure.disclosed, ledger.disclosure.refused, ledger.disclosure.recovery_intended, ledger.disclosure.abandoned and ledger.disclosure.escalated on the composition's Audit Trail instance.

Term act kind: ledger.disclosure — the one act kind this composition binds on its Recoverable Invocation instance: a disclosure's accounting write.

Term disclosure binding: the act kind's bindings, each under the name Recoverable Invocation gives it. act key — the act key below. commit — the disclosure write, read through the commit partition. commit fence — none. pairing datum — the disclosure instant. repeatable — yes. probe — the disclosure probe. completion bound — the disclosure completion bound. commit round trip and probe round trip — the deployment's disclosed bounds. journal — the composition's Audit Trail instance, with ledger.disclosure.intended, the one outcome ledger.disclosure.disclosed, and ledger.disclosure.refused. retention period — the ledger retention policy's. service identity — the recovery identity. outcome envelope — the maximal envelope. retry terminus — lease.

Term act key: a disclosure's subject reference, recipient, scope and authority, in that order. The disclosure id is minted by the commit and cannot key the act ahead of it, which is the minted key deviation (Recoverable Invocation Deviation 4). Two disclosures carrying all four alike are one key, and take the critical section in turn. A caller told act-in-flight finds the named invocation's closing by its id through the read passthrough's sequence-range query before calling again: a call made once that invocation has closed is a second disclosure, the kind being repeatable. The key is serialized as five byte strings — subject reference, recipient, scope, authority type, authority reference — each behind a four-byte length, and that serialization's length is what Primitive policy 14 compares with the reference length cap.

Term commit partition: committed where the disclosure write answers a disclosure id; pre-commit where it answers invalid-request, unknown-authority-type or storage-failure, each of which Selective Disclosure states leaves the store as the call found it (Selective Disclosure Operation 16, Selective Disclosure Operation 17); unknown where it gives no answer or any other.

Term disclosure probe: the disclosure read filtered by the act key's subject reference and recipient and by the intent's disclosure instant as a range of that one instant, kept in the composition's own code to the records carrying the act key's scope and authority — answering committed carrying ledger.disclosure.disclosed and the record's own fields where exactly one record matches, not-committed where none does, undecidable carrying the matching records' disclosure ids where more than one does, and unavailable where the read refuses or gives no answer. A read on the sweep's node that lags a committed record answers not-committed, Selective Disclosure declaring no read-your-writes; with no commit fence the sweep then escalates and never abandons, and an operator settles the act.

WHY:
**Audit Trail is the ledger.** A transaction entry *is* an Audit Trail event: append-only and totally ordered by Event Log, attributed by Actor Identity, sealed by Tamper Evidence at the cadence, placed under retention by Retention Window — all four reached through the substrate and never instanced here (Composes 3 and 4; the section titled Compositions of compositions in `spec-format.md`). **A disclosure records twice**: an intent before the accounting write and an outcome after it, a real addition to ledger volume and retention footprint, stated where the wiring is introduced.

**The disclosure's protocol is Recoverable Invocation's** (Composes 12 through 15). This page names the protocol and binds it. The binding says what only this composition knows: what the act is, which store commits it, how a dead invocation's record is found there, and under what identity the sweep finishes the accounting. **The key is the disclosure's own parameters** (Term act key): the disclosure id does not exist until the commit, so the act is keyed by subject, recipient, scope and authority, serialized on that key, and found again in the store by every field of the key and the one reading the invocation passed to the accounting write. **Every answer of the accounting write is placed** (Term commit partition): the atom's three refusals leave nothing behind and are recorded as refusals; a reply that never came is neither, and the invocation yields. **No commit fence**: Selective Disclosure's record takes no deadline, so the sweep never writes that a disclosure did not happen — it escalates what the store does not show (Recoverable Invocation commit 14).

**Selective Disclosure is the accounting of record, and it extracted three concepts to stay freestanding.** Its own non-goals send the recording actor's binding to Actor Identity, rewrite detection to Tamper Evidence and the retention bound to Retention Window (2026-08-30-p), and its Invariant 5 — no disclosure unrecorded — is an obligation it states and cannot enforce from inside. This composition is where all three re-converge: the substrate seals the outcome event, whose payload mirrors the accounting record's fields, and governs its lifetime; and by making [Disclose Subset] the only disclosure surface that always records, the composition closes Invariant 5 for disclosures routed through it (Invariant 4).

**The ledger enumeration is declared, not assumed** (Composes 7 and 8; 2026-08-30-u). The index rebuild, both orphan enumerations, the read-backs and the checks select by action reference and payload field, and the substrate serves no such read: Event Log's read answers a declared query shape and routes payload-field lookup to a Reverse Index pattern *(forthcoming)*, and Audit Trail passes that read through unchanged and absorbs nothing more. So the route is the pass-through range read with the selection in composition code; a deployment composing Reverse Index may accelerate it.

**The namespace and the write surface are reserved** (Composes 10 and 11; 2026-08-26-e). A record written to Selective Disclosure by a direct call, or an event written under the ledger's action references by another writer, would enumerate as an orphan indistinguishable from a conformance failure. Reserving both — as the substrate reserves its own namespace — makes such a write a deployment's conformance failure, and the reconciliation reports it as one: a record no intent pairs is a write-ownership finding, never compensated (Reconciliation 14).

Adjacent, **not** constituents: [Consent](../atoms/consent.md) and [Permissions](../atoms/permissions.md) (whether a disclosure is permitted); [Defensible Retention](./defensible-retention.md) (hold-blocks-purge over the ledger); [Idempotent Reservation](./idempotent-reservation.md) (at-most-once append); [Chain of Custody](./chain-of-custody.md) (custody of an artifact an entry references).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the binding index.
Composition state 2: The composition MUST key the binding index by disclosure id.
Composition state 3: A binding MUST carry the outcome event id of the disclosure's outcome event.
Composition state 4: The composition MUST write a binding ONLY AFTER the disclosure's outcome event lands.
Composition state 5: The composition MUST NOT change a purged binding.
Composition state 6: The composition MUST classify a live binding as a derived index.
Composition state 7: The composition MUST rebuild the live bindings PER the binding rebuild.
Composition state 8: The composition MUST classify a purged binding as extraction-pending against Erasure Tombstone.
Composition state 9: A rebuild MUST NOT remove a purged binding.
Composition state 10: The deployment MUST persist the binding index PER the index durability.
Composition state 11: An intent's disclosed entry ids MUST NOT EQUAL blank.
Composition state 12: The count of ledger entries one intent names MUST NOT EXCEED the disclosed entries cap.
Composition state 13: An intent MUST NOT name an event outside the ledger entries.
Composition state 14: The composition MUST NOT store a ledger entry outside Audit Trail.
Composition state 15: The composition MUST NOT duplicate a constituent's store.
Composition state 16: The composition MUST read a disclosure's disclosed set from the intent the disclosure's outcome event names.
Composition state 17: The composition MUST classify a write-ownership finding as extraction-pending against Condition Register.
Composition state 18: The binding rebuild MUST bind a disclosure id to the live outcome event of the lowest sequence number carrying the disclosure id, a disclosure id a purged binding names excepted.
```

Term disclosure id: the opaque id Selective Disclosure's record answers for a disclosure record, taken from the id injected at that atom's own seam — new to this composition at the commit.

Term binding index: the composition's map from a disclosure id to the outcome event that recorded the disclosure in the ledger — `disclosure_to_event` in an implementation.

Term binding: one disclosure id with its outcome event id.

Term ledger entry: a ledger.entry event — a transaction.

Term ledger event: an Event Log event on the composition's Audit Trail instance carrying an action reference of the ledger namespace.

Term outcome event: a ledger.disclosure.disclosed record — carrying the disclosure id and the accounting record's other fields, and naming the disclosure's intent by intent event id as every record of the act kind does.

Term intent: the ledger.disclosure.intended record — written by the invocation open ahead of the accounting write, carrying the intent data.

Term disclosed set: the disclosed entry ids a disclosure's intent carries — the one place the set is recorded, reached from the outcome event through the intent event id.

Term live binding: a binding whose outcome event's payload the audit horizon has not reached.

Term purged binding: a binding whose outcome event's payload the audit horizon has destroyed.

Term binding rebuild: the ledger enumeration kept to the outcome events, read as disclosure id against event id and bound by Composition state 18.

WHY:
**The binding fact lives in the substrate** — every outcome event carries the disclosure id — so a live binding carries no truth of its own: read-path acceleration, outside the two truth-bearing writes (the accounting record and the outcome event), its population evidence that they committed and its loss a rebuild trigger, with no consistency claim; the authoritative check is always the substrate read (the section titled Composition state in `execution-contract.md`).

**The classification splits at the horizon, and the purged half is truth-bearing** (Composition state 8 through 10; the section titled *A derived index splits at the horizon* in `pressure-testing.md`). A lawful purge destroys the outcome event's payload whole, the disclosure id with it, and the substrate's destruction record keeps the event id and the attestation id and declares it carries no payload field — so past the horizon the key survives in no constituent, only here. That half is extraction-pending against Erasure Tombstone *(forthcoming)*, and until it lands the obligation is the deployment's: the index store as durable as the accounting store whose records it keys. **The fact was captured before it was presumed**: the reconciliation runs the full rebuild as a write every cycle, and the instance's start conditions keep two cadences inside the compensation window and the window inside the retention period (Recoverable Invocation Instance start 4, Recoverable Invocation Instance start 5), and the horizon exceeds a cadence, two runs of the reconciliation and the time an outcome takes to become readable (Capability requirement 32, Capability requirement 33), so an event lives through at least one rebuild before any purge can reach it. A never-written entry is foreclosed but for an outage that outlasts the horizon — of the ledger's own enumeration, or of the index's store against every write a rebuild makes, each alerted by the run that met it (Reconciliation 30, Reconciliation 31) — and a missing entry past the horizon is honestly a loss. A rebuild never touches a purged binding (Composition state 9): it repopulates the live half and leaves the rest standing.

**The disclosure-to-entry relation, declared** (Composition state 11 through 13; 2026-08-30-j). Each disclosure's intent names one or more ledger entries, at most the cap, and only ledger entries — never an outcome event — so the relation is acyclic by construction: a disclosure discloses transactions, and the fact of a prior disclosure is shown by reading the accounting store, never by disclosing a disclosure event. The ledger keeps no entry store of its own (Composition state 14): an entry *is* an Audit Trail event id, and the substrate is the membership oracle.

**The set has one home** (Composition state 16). A recovered outcome carries only what the accounting store re-derives (Recoverable Invocation Invariant 5.3), and the store does not hold the entry ids, so an outcome that carried the set would come in two shapes — with it where the invocation lived, without it where the sweep finished the accounting. The intent carries it for every disclosure, sealed and retained under the same policy, and every outcome names its intent. The intent is recorded first and, its retention placed as it lands, reaches its horizon first: between the two deadlines a live outcome's set reads unverifiable carrying purged-horizon (Check 5.7) — a compensation window at most where the invocation or the sweep landed the outcome, longer where an operator's settling closing did. That gap is accepted as the price of one home. An intent whose retention the substrate placed late outlives its outcome instead, and the purged verdict answers for the disclosure while the intent is still readable (Verdict 3 ahead of Verdict 4).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the ledger retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: A regulated deployment MUST set a ledger retention policy encoding the regime's minimum retention.
Capability requirement 4: A deployment MUST set the seal cadence on the Audit Trail instance.
Capability requirement 5: The composition MUST NOT override the seal cadence.
Capability requirement 6: A deployment MUST set the disclosure completion bound.
Deleted: Capability requirement 7. Recoverable Invocation close step 3.5 owns it: a retry ends at the lease, not at a count.
Deleted: Capability requirement 8. Recoverable Invocation Instance start 4 owns it: the cadence is the instance's.
Deleted: Capability requirement 9. Recoverable Invocation journal write bound 1 owns it.
Capability requirement 10: A deployment MUST set the disclosed entries cap.
Deleted: Capability requirement 11. Recoverable Invocation Instance start 5 owns it.
Deleted: Capability requirement 12. Recoverable Invocation act section 1 owns it, keyed by the act key.
Deleted: Capability requirement 13. Recoverable Invocation close step 4.2 owns it.
Deleted: Capability requirement 14. Recoverable Invocation act section 2 owns it, and reverses it: a host never frees the section on a holder's death.
Deleted: Capability requirement 15. Recoverable Invocation open step 2.1 owns it.
Deleted: Capability requirement 16. Recoverable Invocation act section 10 owns it.
Deleted: Capability requirement 17. Recoverable Invocation Capability requirement 11 owns it.
Capability requirement 18: A deployment MUST provision the recovery identity.
Capability requirement 19: A deployment MUST declare the index durability.
Capability requirement 20: The index durability MUST NOT fall below the accounting store's durability.
Capability requirement 21: A deployment MUST declare the partial disclosure capability.
Capability requirement 22: The wired Audit Trail instance MUST expose the ledger enumeration.
Capability requirement 23: The host MUST inject now AND the invocation id at the seam once per invocation.
Capability requirement 24: The composition MUST stamp a ledger entry's payload instant from the invocation's now.
Capability requirement 25: The host MUST inject the invocation's now into Selective Disclosure's seam.
Capability requirement 26: The host MUST inject the reconciliation's now at the reconciliation's own seam.
Capability requirement 27: A deployment MUST disclose the commit round trip, the probe round trip, the reconciliation run bound AND the settling period.
Capability requirement 28: The host MUST NOT inject an equal now into two invocations of one act key on any node of the instance.
Capability requirement 29: An operator MUST NOT leave an unsettled escalation whose intent's horizon edge PRECEDES now.
Capability requirement 30: A deployment MUST persist EVERY write-ownership finding for the audit horizon.
Capability requirement 31: A deployment MAY set the audit horizon ONLY IF the audit horizon EXCEEDS the act kind's window end added to Recoverable Invocation's run bound and the settling period.
Capability requirement 32: A reconciliation run MUST NOT EXCEED the reconciliation run bound.
Capability requirement 33: A deployment MAY set the audit horizon ONLY IF the audit horizon EXCEEDS the reconciliation cadence added to twice the reconciliation run bound, the clock offset allowance and Recoverable Invocation's journal write bound.
Capability requirement 34: A deployment MUST NOT disclose the entries to the disclosure's recipient BEFORE an outcome event carrying the disclosure id lands.
```

Term ledger retention policy: the policy reference configured on the composition's single Audit Trail instance, governing every ledger event — `ledger_retention_policy`.

Term audit horizon: the ledger retention policy's horizon — a duration; a record's edge is its instant plus it.

Term seal cadence: Audit Trail's per-event | interval-based | on-demand setting.

Term disclosure completion bound: the act kind's completion bound — the longest a [Disclose Subset] takes from the invocation open's take of the critical section to the invocation close's last write, the accounting write included.

Term commit round trip: the deployment's disclosed bound on one disclosure write, from issue to reply; a disclosure write unanswered past it gives no answer (Action wiring 51).

Term reconciliation cadence: Recoverable Invocation's reconciliation cadence on the composition's instance — the interval the sweep runs at, and this composition's reconciliation beside it.

Term probe round trip: the deployment's disclosed bound on one disclosure probe, from issue to answer.

Term disclosed entries cap: the most entries one disclosure may name — `disclosed_entry_ids_cap`.

Term recovery identity: the act kind's service identity — the composition's registered actor reference and credential, `application_actor_ref` and `application_credential`, under which the sweep attests every record it writes.

Term index durability: the durability the deployment owes the binding index, stated as an ordering against the accounting store's.

Term accounting store: the Selective Disclosure store.

Term partial disclosure capability: the deployment's declared boolean that the Tamper Evidence mechanism inside the substrate can produce, for a named subset, a verification artifact an independent party checks against the ledger seal without the undisclosed entries — `tamper_evidence_supports_partial_disclosure`.

Term invocation id: the fresh id the host injects at the seam per state-changing invocation, carried by every record the invocation writes.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**Retention and cadence are the substrate's** (Capability requirement 1 through 5): SEC (the US Securities and Exchange Commission) Rule 17a-4's six-year floor, the first two years accessible; HIPAA (the US Health Insurance Portability and Accountability Act) section 164.528's six-year accounting window. For a ledger whose subsets will be disclosed, per-event or tight interval cadence is recommended, because **an unsealed entry cannot yet anchor a partial-disclosure proof**: the unsealed tail is the window in which a freshly appended entry is not independently verifiable, and a bundle marks such an entry unverifiable rather than proving it (Verdict 9; 2026-08-30-e).

**The protocol's settings are the protocol's** (the tombstones of Capability requirement 7 through 17). The critical section and its lease, the cadence, the journal write bound and the start conditions that make the closure window meetable are Recoverable Invocation's — set on the instance, checked at its start for the act kind. This page declares what is the act kind's own: the completion bound, the two round trips, the recovery identity and the cap (Capability requirement 6, 10, 18 and 27).

**The cap sizes the largest record** (Capability requirement 10; the section titled *An outcome is sized before the intent* in `pressure-testing.md`): *non-empty* is a lower bound, and a caller can reach any upper bound the configuration does not state. The intent carries the set, and the invocation open sizes it with the kind's largest record against the maximal envelope ahead of any write (Recoverable Invocation open step 1.3).

**The recovery identity** (Capability requirement 18) is the act kind's service identity: it attests every record the sweep writes — the recovery intent, the recovered outcome, the escalation — because the discloser's credential is not in hand, and the discloser rides in the sealed payload as the acting actor reference, never as the attester (Recoverable Invocation Invariant 5.2). **The index durability** (Capability requirement 19 and 20) is owed against *loss*, not capture: capture is the every-cycle rebuild, so a binding the auditor finds missing for a purged event was written and lost.

**The partial disclosure capability is a behavioural obligation, never a mechanism** (Capability requirement 21). No Tamper Evidence or Audit Trail action produces or checks a subset proof — the atom verifies whole record sets — so the surface consuming it, the verification bundle and [Verify Disclosure], is composition-introduced (Degraded bundle 1 for its absence). Realizations include Merkle inclusion proofs (a path of sibling hashes from one leaf to a hash tree's root) and cryptographic accumulators (a constant-size commitment with a membership witness per element); the composition requires the capability and names none.

**One clock authority, and one reading per key** (Capability requirement 23 through 26 and 28; Execution Contract Logic confinement 7). The invocation's one reading is the disclosure instant: it rides the intent data and is passed to Selective Disclosure as the accounting record's instant, and that equality is what the disclosure probe matches by — the pairing datum. Two invocations of one act key are serialized by the critical section and must not be given equal readings, on one node or two (Capability requirement 28; Recoverable Invocation pairing datum 4): where both commit, the probe finds two records and the sweep can only escalate, and where the second dies ahead of its commit, the probe finds the first's record alone and would recover the second onto it. Selective Disclosure's not-in-future guard compares the passed instant against its own seam's reading, so that seam is given the invocation's own reading and the guard meets two equal instants (Capability requirement 25); the reconciliation's reading comes from the same authority at its own seam.

### Primitive policy

```
Primitive policy 1: IF the transaction data EQUALS blank THEN [Record Entry] MUST answer invalid-request.
Primitive policy 2: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 3: IF the disclosed entry ids EQUALS blank THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 4: IF the count of disclosed entry ids EXCEEDS the disclosed entries cap THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 5: IF the subject reference, the recipient, the scope, the authority type OR the authority reference EQUALS blank THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 6: IF a disclosed entry id names no ledger entry through the record read THEN [Disclose Subset] MUST answer unknown-entry naming EVERY such id.
Deleted: Primitive policy 7. Recoverable Invocation open step 1.4 owns it, sizing against the maximal envelope.
Primitive policy 8: An action refused under Primitive policy MUST NOT write.
Primitive policy 9: [Disclose Subset] MUST NOT call the invocation open BEFORE Primitive policy 2 through 6, 14, 16 and 19 pass.
Primitive policy 10: The composition MUST compare an event id, a disclosure id AND an invocation id byte-exact.
Primitive policy 11: The composition MUST NOT normalize a caller string.
Primitive policy 12: The composition MUST NOT inspect a credential.
Primitive policy 13: The composition MUST NOT interpret the transaction data.
Primitive policy 14: IF the act key OR the actor reference EXCEEDS the reference length cap THEN [Disclose Subset] MUST answer invalid-request.
Deleted: Primitive policy 15. Primitive policy 8 owns it.
Primitive policy 16: IF the record read answers no answer at the membership check THEN [Disclose Subset] MUST answer journal-unavailable.
Deleted: Primitive policy 17. Primitive policy 8 owns it.
Primitive policy 18: IF the actor reference names the recovery identity THEN [Record Entry] MUST answer invalid-request.
Primitive policy 19: IF the record read answers attribution not-recoverable at the membership check THEN [Disclose Subset] MUST answer journal-unavailable.
Primitive policy 20: [Disclose Subset] MUST answer the first refusal in the order Primitive policy 2, 3, 4, 5, 14, 16, 19, 6.
Primitive policy 21: IF the disclosure id EQUALS blank THEN the action MUST answer not-known.
```

Term membership check: Primitive policy 6's reading of EVERY disclosed entry id through the record read.

Term transaction data: the opaque payload of a ledger entry, schema the host's.

Term actor reference: the acting party of a ledger write or a disclosure — actor_ref.

Term disclosed entry ids: the set of ledger entry ids a disclosure names — the machine-checkable subset.

Term subject reference: the opaque reference to the subject a disclosed subset pertains to — asserted by the discloser.

Term recipient: the party receiving a disclosure.

Term scope: the human- and regulator-facing descriptor of what was disclosed.

Term authority: Selective Disclosure's structured authority — a type of consent, legal-hold or regulatory, with a reference.

Term maximal envelope: the act kind's outcome envelope — the largest outcome payload the kind writes: every field at its minted width, and the act key, the actor reference and each caller string the outcome carries at the reference length cap, serialized as the substrate sizes it. The intent, which alone carries the disclosed entry ids, is sized beside it by the invocation open (Recoverable Invocation Primitive policy 12).

Term caller string: a subject reference, a recipient, a scope, an authority reference or an actor reference.

WHY:
**Blank is refused with the constituent's own rule, before the intent** (Primitive policy 1 through 5; 2026-08-30-c). Selective Disclosure refuses a blank subject, recipient, scope, authority type or authority reference — whitespace-only included — so a composition that accepted whitespace would reach the constituent's refusal *after* its intent had landed. The prose's *whitespace-only accepted* is withdrawn; the grammar's blank is one reading for both layers.

**Membership reads the substrate** (Primitive policy 6; 2026-08-30-s). Every disclosed id resolves through the record read to a ledger entry — a transaction, never an outcome event and never an unknown id — and the refusal names *every* failing id, since a set has no first element. The composition keeps no entry store; the substrate is the oracle. An entry the substrate reports purged still resolves to a ledger entry by its surviving attestation, and is disclosed with its proof marked unverifiable in the bundle rather than refused (Verdict 10; 2026-08-30-d), the same answer a purge landing between the check and the bundle gives. Where a purge has destroyed the payload and the pair that keeps the attribution is not yet written, the read answers attribution not-recoverable: the id is then neither shown a ledger entry nor shown not to be one, and the call answers journal-unavailable as it does for a read that gave no answer (Primitive policy 19; Audit Trail read record step 4.4d). One call gives one refusal, the first in a fixed order, with a read that concluded nothing ahead of the verdict it would have fed (Primitive policy 20). Membership answers ahead of the credential, which the intent write verifies; it tells a caller nothing the read passthrough does not, and who may read the ledger is the deployment's (Non-goal 1).

**The largest record is sized by the protocol, and the key is capped here** (Primitive policy 14 and 15; Recoverable Invocation open step 1.3). The invocation open sizes the intent data and the kind's largest record against the maximal envelope before it takes the critical section, so what passes there passes at the intent, at the outcome and on the sweep's recovered outcome alike. What the open cannot do is cap what this page hands it: the act key is four caller strings, and the protocol requires it, and the actor reference, under the substrate's reference length cap ahead of the open.

**Opaque and byte-exact** (Primitive policy 10 through 13): nothing is case-folded, trimmed or normalized; the bijection's predicate — the outcome's disclosure id against the accounting store — compares bytes. The authority is recorded and made auditable, never validated (Non-goal 1).

### Audit arm

```
Deleted: Audit arm 1. Recoverable Invocation Primitive policy 19 owns it.
Deleted: Audit arm 2. Recoverable Invocation Primitive policy 41 owns it.
Deleted: Audit arm 3. Recoverable Invocation Primitive policy 23 owns it.
Deleted: Audit arm 4. Recoverable Invocation Primitive policy 43 owns it.
Deleted: Audit arm 5. Recoverable Invocation Primitive policy 27 owns it.
Deleted: Audit arm 6. Recoverable Invocation Primitive policy 27 owns it.
Deleted: Audit arm 7. Recoverable Invocation Primitive policy 35 owns it, reading back by invocation id.
Deleted: Audit arm 8. Recoverable Invocation Primitive policy 28 owns it.
Deleted: Audit arm 9. Recoverable Invocation Primitive policy 28 owns it, as the hard alert.
Deleted: Audit arm 10. Recoverable Invocation Primitive policy 29 owns it.
Deleted: Audit arm 11. Recoverable Invocation Primitive policy 29 owns it: the retry ends at the terminus.
Deleted: Audit arm 12. Recoverable Invocation Primitive policy 30 owns it.
Deleted: Audit arm 13. Recoverable Invocation Primitive policy 31 owns it.
Audit arm 14: IF Audit Trail answers recording-failure carrying the retention step at a ledger entry THEN [Record Entry] MUST answer the event id the refusal carries.
Audit arm 15: IF Audit Trail answers invalid-request(step-4) at a ledger entry THEN [Record Entry] MUST answer the event id the refusal carries.
Audit arm 16: An entry read-back MUST match the ledger entry carrying the invocation id.
Audit arm 17: IF the entry read-back finds the entry THEN [Record Entry] MUST answer the entry id.
Audit arm 18: IF Audit Trail answers invalid-request carrying a step below step-4 at a ledger entry THEN [Record Entry] MUST answer invalid-request.
Audit arm 19: IF Audit Trail answers recording-failure carrying a pre-append step at a ledger entry THEN [Record Entry] MUST answer recording-failure.
Audit arm 20: IF Audit Trail answers invalid-credential at a ledger entry THEN [Record Entry] MUST answer invalid-credential.
Audit arm 21: An entry read-back MUST read the ledger enumeration from sequence one.
Deleted: Audit arm 22. Recoverable Invocation Invariant 8.3 owns it.
Deleted: Audit arm 23. Recoverable Invocation Invariant 8.4 owns it.
Deleted: Audit arm 24. Recoverable Invocation Primitive policy 20 owns it, and Recoverable Invocation Primitive policy 21a proceeds where the read-back finds the intent.
Deleted: Audit arm 25. Recoverable Invocation Primitive policy 42 owns it.
Audit arm 26: IF [Record Entry] answers an entry id under Audit arm 14, Audit arm 15 OR Audit arm 17 THEN [Record Entry] MUST alert the finding surface carrying the entry id.
Audit arm 27: IF the entry read-back answers no answer THEN [Record Entry] MUST answer entry-unconfirmed carrying the invocation id.
Audit arm 28: IF the entry read-back finds no entry THEN [Record Entry] MUST answer entry-unconfirmed carrying the invocation id.
Audit arm 29: IF Audit Trail answers no answer at a ledger entry THEN [Record Entry] MUST answer entry-unconfirmed carrying the invocation id.
Audit arm 30: IF Audit Trail answers recording-failure carrying the append step at a ledger entry THEN [Record Entry] MUST read the entry back.
```

Term pre-append step: the recording-failure step naming the step before the substrate's append — step-2; the event is not in the log.

Term append step: the recording-failure step naming the substrate's append — step-3; the append was refused or gave no answer, and the event may be in the log (Audit Trail record action step 3.7).

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term invalid-request step: step-1 | step-2 | step-3 | step-4 — the step of Audit Trail's record action that landed the refusal; step-4 is the retention step, and at step-1 through step-3 the event is not in the log.

Term position: intent | outcome | refusal — the position a recording-failure of [Disclose Subset] carries, as Recoverable Invocation exports it: intent, nothing committed and the whole action may be retried; outcome, the accounting record may exist and its ledger record is the sweep's, so the action is never re-run — the code carries the invocation id, and the caller finds that invocation's outcome event by it through the read passthrough's sequence-range query, disclosing the entries only once the event lands (Capability requirement 34); refusal, the accounting write was refused, the refusal record did not land, and the code carries the atom's refusal beside it.

WHY:
**Mapped by position relative to the truth-bearing write, and by step** (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). The substrate attests at its step 2, appends at step 3 and places retention at step 4: the pre-append step means the event is not in the log, the retention step means it is, and a retry from there would append a second one. The append step is in between: the substrate lands it for an append that was refused and for one that gave no answer and may yet land, with nothing on the code to tell them apart, so [Record Entry] reads back there as it does at the retention step and answers the entry id or entry-unconfirmed, never a bare failure a caller would retry (Audit arm 30). Its invalid-request has the same two faces by another route — its retention-configuration faults arrive at step-4 with the event appended, its cap source at step-1 or step-3 and Actor Identity's refusal at step-2 with nothing — so the step decides, never a bare token, and step-4 alone is read back.

**The disclosure's arms are the protocol's** (the tombstones of Audit arm 1 through 13 and 22 through 25). Every arm of the intent write, the outcome write and the refusal write is mapped by position in Recoverable Invocation Primitive policy 19 through 43, and [Disclose Subset] exports the codes that page's table gives an adopter and none of its own for the protocol's sake (Recoverable Invocation Action wiring 2); the invocation id rides recording-failure carrying outcome for the caller's sake, the payload that page has the adopter declare (Recoverable Invocation Invariant 8.2).

**[Record Entry] has one write, and it is the load-bearing one** (Audit arm 14 through 20). Its retention step and invalid-request(step-4) mean the entry *is* in the ledger, and a refusal would send the caller back to append it again — [Record Entry] is not idempotent — so both answer the entry id the refusal carries, with an alert (Audit arm 26). invalid-request at step-1 through step-3 leaves no entry, so the refusal is clean; the caller repairs the input and calls again, an unchanged call repeating the refusal and, at step-3, leaving an orphan attestation each time (Audit Trail record action step 7.13). recording-failure has that one position, before the append, and is exported bare; the other position has its own code. Where the entry is or may be appended and its id cannot be had — the read-back gets no answer or finds nothing, or the substrate's reply to the write never came — [Record Entry] answers entry-unconfirmed carrying the invocation id, which is never a reason to call again: a second call appends a second transaction, and the first, where it landed, is found by that id (Audit arm 27 through 29). The read-back of an append-step failure does not wait out the journal write bound: a miss answers entry-unconfirmed, and the caller's own read by the id once that bound has passed decides (Term entry-unconfirmed).

**The position rides the exported code** (Recoverable Invocation Invariant 8; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent means retry the whole action; outcome means the accounting record may exist and its ledger record is the sweep's to land, and re-invoking would create a second accounting record.

### Action wiring

```
record_entry(transaction_data, actor_ref, credential)
  answers entry id
  refuses invalid-credential | invalid-request | recording-failure | entry-unconfirmed(invocation_id)

disclose_subset(disclosed_entry_ids, subject_ref, recipient, scope, authority, actor_ref, credential)
  answers disclosure result
  refuses invalid-credential | invalid-request | unknown-entry | unknown-authority-type | storage-failure | act-in-flight(invocation_id) | section-unavailable | journal-unavailable | already-accounted(closing_event_id) | recording-failure(intent) | recording-failure(outcome, invocation_id) | recording-failure(refusal, constituent_code)

verify_disclosure(disclosed_entries, verification_bundle, ledger_seal_reference)
  answers disclosure proof

verify_ledger(disclosure_id, original_event_payloads)
  answers accountability proof
  refuses not-known | journal-unavailable | store-unavailable | index-unavailable

reissue_bundle(disclosure_id)
  answers verification bundle
  refuses not-known | journal-unavailable | index-unavailable

read(query)
  answers results
  refuses invalid-query
```

Term entry id: the event id of a ledger entry.

Term disclosure result: the disclosure id, the outcome event id and the [Verification Bundle].

Term disclosed entries: the entries a recipient holds — each its entry id and payload — never the whole ledger.

Term ledger seal reference: the published seal the Tamper Evidence mechanism anchors to.

Term disclosure proof: per presented entry its entry id and authenticity, the [Confidentiality Preserved] assertion, and the overall verdict — disclosure-verified | disclosure-unverified carrying the reasons.

Term original event payloads: the caller's map from an audit-log sequence number to the byte-exact payload Event Log holds at that position.

Term accountability proof: the disclosure id and the binding verdict, and with them — under bound, the outcome event id, the attestation verification and the retention state the record read answers for that event; under binding-purged, the indexed event id, failed-verification carrying purged and Purged; under binding-duplicate, the event ids; under binding-escalated, the cause; under binding-gap, the state of the record's invocation where one exists (Verdict 15), which tells an invocation still inside its window from a failure.

Term results: what the routed constituent read answers.

Term entry-unconfirmed: [Record Entry]'s refusal where the entry is or may be in the ledger and its id could not be read — never re-run; the entry, where it exists, carries the invocation id the refusal names, and the caller finds it by that id through the read passthrough's sequence-range query. Absence by that id is final once Recoverable Invocation's journal write bound has passed since the refusal — the longest a record action on this instance can still land after its issue, which precedes the refusal.

Term store-unavailable: [Verify Ledger]'s refusal where the accounting store gave no answer — nothing is concluded about the disclosure.

Term attestation verification: what the substrate's verify_record answers for the outcome event's covering range, or what Action wiring 35, Action wiring 67 and Verdict 7 put in its place.

Term retention state: Retained | Purged | unresolved, as the record read answers it for an event.

Term bundle construction: building the verification bundle over the disclosed set through the verification routine.

Term verification routine: the partial-disclosure mechanism's prover and verifier, which the partial disclosure capability declares.

Term degraded bundle: the bundle a mechanism without the partial disclosure capability produces — a whole-ledger seal with no inclusion structure (Degraded bundle 1).

Term index-unavailable: [Verify Ledger]'s and [Reissue Bundle]'s refusal where no live outcome answers for the disclosure and the binding index gave no answer — nothing is concluded, a purged disclosure and a gap being told apart by the index alone.

Term no answer: a read or a write that returns neither its answer nor a refusal, a read that answers unavailable, or a read that answers not-known for an id the substrate itself gave — of a constituent, as Audit Trail declares it, and of the binding index's own store, whose refusal is read as no answer too.

Term invocation pair: the invocation id and the intent event id the invocation open answered.

```
Action wiring 1: A validated entry MUST record the ledger entry carrying the invocation id, the transaction data AND now as the payload instant under the actor's credential.
Action wiring 2: A landed entry MUST answer the entry id.
Action wiring 3: A validated disclosure MUST call the invocation open with the act kind, the act key, the actor reference, the credential AND the intent data.
Deleted: Action wiring 4. Recoverable Invocation Primitive policy 10 owns it.
Deleted: Action wiring 5. Recoverable Invocation Invariant 1.1 owns it.
Action wiring 6: An admitted disclosure MUST call the disclosure write with the subject reference, the recipient, the scope, the authority AND now as the disclosure instant.
Deleted: Action wiring 7. Recoverable Invocation commit 3 owns it: a pre-commit arm answers the constituent's own code, storage-failure included.
Deleted: Action wiring 8. Recoverable Invocation commit 3 owns it.
Deleted: Action wiring 9. Recoverable Invocation commit 2 owns it, and reverses it: a refused commit is closed by a refusal record.
Deleted: Action wiring 10. Recoverable Invocation open step 2.1 owns it, taking the section ahead of the intent.
Deleted: Action wiring 11. Recoverable Invocation act section 10 owns it, and reverses it: an invocation whose lease expired never takes the section again.
Deleted: Action wiring 12. Recoverable Invocation close step 2.1 owns it.
Deleted: Action wiring 13. Recoverable Invocation close step 2.2 owns it.
Deleted: Action wiring 14. Recoverable Invocation act section 10 owns it.
Deleted: Action wiring 15. Recoverable Invocation close step 3.1 owns it.
Action wiring 16: A landed disclosure MUST write the binding.
Action wiring 17: A landed disclosure MUST construct the verification bundle over the disclosed set.
Action wiring 18: IF the bundle construction fails THEN the landed disclosure MUST carry unavailable carrying the reason as the verification bundle.
Deleted: Action wiring 19. Recoverable Invocation Invariant 3.5 owns it: a sweep that cannot pair closes nothing, so no outcome carries an unresolved set.
Action wiring 20: A landed disclosure MUST answer the disclosure result.
Deleted: Action wiring 21. Recoverable Invocation yield 3 owns it: no adopter touches the section.
Action wiring 22: IF no outcome event carries the disclosure id AND no purged binding names the disclosure id THEN [Reissue Bundle] MUST answer not-known.
Action wiring 23: A found reissue MUST construct the verification bundle over the disclosed set.
Action wiring 24: [Verify Disclosure] MUST check EVERY presented entry against the verification bundle AND the ledger seal reference.
Action wiring 25: [Verify Disclosure] MUST NOT read an undisclosed entry.
Action wiring 26: [Verify Disclosure] MUST NOT refuse a call.
Action wiring 27: [Verify Disclosure] MUST NOT read the binding index.
Action wiring 28: IF the accounting store carries no record for the disclosure id THEN [Verify Ledger] MUST answer not-known.
Action wiring 29: A found ledger verification MUST resolve the binding through the ledger enumeration kept to the outcome events carrying the disclosure id.
Action wiring 30: A found ledger verification MUST NOT rest a verdict on the binding index alone.
Deleted: Action wiring 31. Action wiring 29 owns it: the enumeration runs on a hit and on a miss alike.
Deleted: Action wiring 32. Action wiring 29 owns it, and reverses it: the purged verdict's first clause needs the enumeration a purged hit was denied.
Action wiring 33: A bound ledger verification MUST read the outcome event's covering range through the record read.
Action wiring 34: IF the record read answers partially-purged coverage THEN the bound ledger verification MUST call the verification with the covering range's members the original event payloads carry.
Action wiring 35: IF a member of a whole covering range IS NOT IN the original event payloads THEN the attestation verification MUST carry payload-not-supplied AND the missing sequence numbers.
Action wiring 36: IF EVERY member of the covering range IS IN the original event payloads THEN the bound ledger verification MUST call the verification with the covering range's payloads in ascending sequence order.
Action wiring 37: IF the record read names no covering range THEN the presentation MUST carry the outcome event's own payload from the original event payloads.
Action wiring 38: The bound ledger verification MUST carry the verification's outcome AND reason unchanged as the attestation verification.
Action wiring 39: The bound ledger verification MUST carry the verification's compensation-window qualifier beside the attestation verification.
Action wiring 40: The read passthrough MUST route an accounting query to the disclosure read.
Action wiring 41: The read passthrough MUST route a sequence-range query AND a wall-time-range query to Event Log's read through Audit Trail.
Action wiring 42: The read passthrough MUST route an event-id query to the record read.
Action wiring 43: IF the query conforms to no routed shape THEN the read passthrough MUST answer invalid-query.
Action wiring 44: IF the routed read answers invalid-query THEN the read passthrough MUST answer invalid-query.
Action wiring 45: A read-only action MUST NOT record an audit event.
Deleted: Action wiring 46. Recoverable Invocation Primitive policy 4 owns it, and Action wiring 1 for a ledger entry.
Action wiring 47: IF the invocation open refuses THEN [Disclose Subset] MUST answer the invocation open's refusal.
Action wiring 48: IF the disclosure write answers a disclosure refusal THEN [Disclose Subset] MUST call the invocation refusal with the act kind, the act key, the invocation pair, the caller's actor reference AND credential, AND the disclosure refusal as the reason AND as the constituent code.
Action wiring 49: IF the invocation refusal answers THEN [Disclose Subset] MUST answer the disclosure refusal.
Action wiring 50: IF the invocation refusal refuses THEN [Disclose Subset] MUST answer the invocation refusal's own refusal.
Action wiring 51: IF the disclosure write's answer falls in the unknown partition THEN [Disclose Subset] MUST call the invocation yield carrying answered for an undeclared code AND lost for no answer.
Action wiring 52: A yielded disclosure MUST answer recording-failure carrying outcome.
Action wiring 53: An accounted disclosure MUST call the invocation close with the act kind, the act key, the invocation pair, the caller's actor reference AND credential, ledger.disclosure.disclosed as the outcome action reference AND the outcome data.
Action wiring 54: IF the invocation close refuses THEN [Disclose Subset] MUST answer recording-failure carrying outcome.
Action wiring 55: IF the record read answers Purged for the intent a found reissue's outcome event names THEN the found reissue MUST answer unavailable carrying entry-set-purged as the verification bundle.
Action wiring 56: IF the invocation read answers journal-unavailable THEN [Verify Ledger] MUST answer journal-unavailable.
Action wiring 57: IF the record read, the ledger enumeration OR the verification answers no answer THEN [Verify Ledger] MUST answer journal-unavailable.
Action wiring 58: IF the disclosure read answers no answer THEN [Verify Ledger] MUST answer store-unavailable.
Action wiring 59: IF the record read OR the ledger enumeration answers no answer THEN [Reissue Bundle] MUST answer journal-unavailable.
Action wiring 60: The read passthrough MUST answer a routed read's no answer unchanged.
Action wiring 61: An admitted disclosure MUST call the disclosure write WITHIN Recoverable Invocation's call pause bound of the invocation open's answer (Recoverable Invocation commit 14c).
Action wiring 62: IF no outcome event carries the disclosure id AND a purged binding names the disclosure id THEN [Reissue Bundle] MUST answer unavailable carrying entry-set-purged as the verification bundle.
Action wiring 63: IF the bundle construction fails at a found reissue THEN [Reissue Bundle] MUST answer unavailable carrying the reason as the verification bundle.
Action wiring 64: IF no live outcome event carries the disclosure id AND the binding index gives no answer THEN [Verify Ledger] MUST answer index-unavailable.
Action wiring 65: IF no outcome event carries the disclosure id AND the binding index gives no answer THEN [Reissue Bundle] MUST answer index-unavailable.
Action wiring 66: IF the binding's write gives no answer at a landed disclosure THEN the landed disclosure MUST answer the disclosure result.
Action wiring 67: IF the record read names no covering range AND the outcome event's sequence number IS NOT IN the original event payloads THEN the attestation verification MUST carry payload-not-supplied.
Action wiring 68: EVERY recording-failure [Disclose Subset] answers carrying outcome MUST carry the invocation id.
Action wiring 69: [Verify Ledger] MUST answer the first refusal in the order Action wiring 58, 28, 56, 57, 64.
Action wiring 70: [Reissue Bundle] MUST answer the first refusal in the order Action wiring 59, 65, 22.
```

Term validated entry: a [Record Entry] call whose inputs cleared Primitive policy.

Term landed entry: a validated entry whose ledger entry landed.

Term validated disclosure: a [Disclose Subset] call whose inputs, membership and caps cleared Primitive policy.

Term admitted disclosure: a validated disclosure whose invocation open answered.

Term invocation open: Recoverable Invocation's open — taking the act's critical section and writing the intent.

Term invocation close: Recoverable Invocation's close — writing the outcome, or adopting one another writer landed, and releasing the critical section.

Term invocation refusal: Recoverable Invocation's refuse — closing an intent whose commit a pre-commit arm refused.

Term invocation yield: Recoverable Invocation's yield — nothing written, the intent left to the sweep, and the critical section released or left to end at its instant as that page's yield decides.

Term invocation read: Recoverable Invocation's read_invocation on the act kind, an act key and an invocation id — answering the invocation's state as that page reads which closing stands.

Term sweep: Recoverable Invocation's reconcile on the composition's instance, run at every restart and every reconciliation cadence.

Term intent data: what a validated disclosure passes the invocation open — the disclosed entry ids, the subject reference, the recipient, the scope, the authority and now as the disclosure instant. It carries nothing a constituent mints.

Term outcome data: what an accounted disclosure passes the invocation close — the disclosure id, the subject reference, the recipient, the scope, the authority and the disclosure instant: the accounting record's own fields, so an invocation's outcome and a recovered one carry the same.

Term disclosure refusal: invalid-request | unknown-authority-type | storage-failure — Selective Disclosure's refusals of the disclosure write, the commit partition's pre-commit arms, each relayed by name once its refusal is recorded.

Term accounted disclosure: an admitted disclosure whose disclosure write answered the disclosure id.

Term yielded disclosure: an admitted disclosure whose disclosure write's answer fell in the unknown partition.

Term landed disclosure: an accounted disclosure whose invocation close answered — with its own outcome, or with one another writer landed and the close adopted.

Term disclosure instant: the now an admitted disclosure carries in its intent data and passes to the disclosure write — disclosed_at: the accounted time of disclosure, which is the admission's instant and precedes the transmission (Capability requirement 34), and the act kind's pairing datum. A disclosure found late, made outside the composition, is never recorded here at its own date (Composes 11).

Term payload instant: the now a ledger entry's payload carries — the payload's recorded_at, distinct from Event Log's own recording instant for the append.

Term found reissue: a [Reissue Bundle] call whose disclosure id an outcome event carries.

Term found ledger verification: a [Verify Ledger] call whose disclosure id the accounting store carries.

Term bound ledger verification: a found ledger verification whose binding verdict carries bound.

Term covering range: the sequence range the record read names for an event's covering seal.

Term whole covering range: a covering range the record read does not answer partially-purged coverage for.

Term read passthrough: the composition's read — routed to the constituent whose declared query shape the query conforms to.

Term read-only action: [Verify Disclosure], [Verify Ledger], [Reissue Bundle] or the read passthrough.

WHY:
**[Record Entry] is one write, and it needs no intent** (Action wiring 1 and 2; Invariant 6): its single audit write *is* the load-bearing write and the credential-verifying call, so nothing commits on an unverified claim.

**[Disclose Subset] is validate, open, commit, close** (Action wiring 3, 6 and 47 through 54; Recoverable Invocation Action wiring 4; 2026-08-26-k). The open takes the act's critical section and writes the intent — where the discloser's credential is verified, so a permanent, non-removable accounting record naming a recipient, a scope and an asserted authority is never committed on an unverified say-so. The commit is the accounting write, which takes the invocation's reading as its instant; the intent data carries the same reading, and that equality is how the probe finds the record of an invocation that died. The close writes the outcome, whose data mirrors the accounting record's fields **because the seal covers exactly what the payload carries**: Selective Disclosure's immutability is the atom's specification-level guarantee, not records-alone verifiable, and a field not mirrored under seal keeps only the weaker guarantee. What each step does on each arm — the pre-check, the adoption of an outcome another writer landed, the retry and its terminus, the release — is Recoverable Invocation's and is not restated here.

**Each answer of the accounting write has one route** (Action wiring 48 through 54; Term commit partition). A refusal the atom states applied nothing is recorded as a refusal and answered under its own name. An answer that says nothing — a lost reply, or a code the atom's contract does not declare — yields, and the caller hears recording-failure carrying outcome, because the record may exist and its ledger record is then the sweep's. A disclosure id closes. The close and the refusal are handed what the open answered and what the caller passed, unchanged — the pair, the actor reference, the credential — and the accounting write goes out behind the open's answer inside one call pause, because the open's last reading is what admits it (Action wiring 48, 53 and 61; Recoverable Invocation close 1, Recoverable Invocation Primitive policy 17, Recoverable Invocation open step 5.4).

**A read that gives no answer concludes nothing** (Primitive policy 16; Action wiring 57 through 60). An unanswered record read is not an unknown entry, an unanswered accounting store is not a disclosure never made, an unanswered enumeration is not a gap, and an unanswered index is not the absence of a purged binding (Action wiring 64, Action wiring 65): each action says which store it could not read and writes nothing. The cheapest implementation reads a failed read as empty, and every false verdict on this page would follow from it.

**The bundle is a projection, reissuable, and its failure is not a refusal** (Action wiring 17, 18, 20, 22, 23 and 55; 2026-08-30-f). No constituent action produces a subset proof — Tamper Evidence verifies whole record sets, Audit Trail single whole events — so the composition constructs it by invoking the configured mechanism's inclusion-proof capability over seal material the substrate already committed: the mechanism-capability residual the section titled Substrate composition invocation in `execution-contract.md` permits, with a Subset Proof atom *(forthcoming)* its retirement path. Both truth-bearing writes have committed by then, so a construction failure answers success with the bundle unavailable — a refusal would tell the caller the disclosure was not recorded — and **[Reissue Bundle] declares the recovery path** the prose left to the deployment: the bundle is a pure projection over the seal material and the disclosed set the sealed intent records, so it is re-derivable for as long as the intent is. A disclosure whose intent the horizon destroyed ahead of its outcome determines no set, and no bundle may be proved over a set no sealed record asserts (Action wiring 55).

**[Verify Disclosure] is total and recipient-side** (Action wiring 24 through 27): a check a recipient runs on material already held, so every outcome is a verdict, never a refusal, and it reads no undisclosed entry and not the index — the accountability side is [Verify Ledger]'s.

A recorded disclosure whose invocation is still open or stands escalated has no outcome event, so [Reissue Bundle] answers not-known for it and [Verify Ledger] is the action that answers its state (Action wiring 22, Verdict 4, Verdict 15). A purge landing between the enumeration and the covering-range read gives bound beside failed-verification carrying purged — a lawful pair: the binding stood when it was read, and the destruction is reported as such.

**[Verify Ledger] reads the substrate, lawful destruction first** (Action wiring 28 through 39; the section titled *Lawful destruction is answered before absence* in `pressure-testing.md`). The verdict is counted from the enumeration on every call: a hit cannot show a second live outcome, and a purged hit cannot show that no live outcome has been written since. What the index supplies is the one thing the substrate no longer can — the event a destroyed payload once named (Action wiring 29 and 30; Verdict 1 through 3). **The presentation is keyed by position because a seal commits to a range**: under interval cadence the range spans entries, intents and whatever else the instance records, so an id-keyed map would answer a record-set mismatch on every intact ledger. Partially-purged coverage is answered before membership; an event the record read names no range for — in the unsealed tail, under either tail mode — is presented as itself, and the substrate's own answer is relayed, strict or lenient (2026-08-30-b); the compensation-window qualifier rides beside the verification, never inside it.

**The read passthrough routes by shape, and its refusal has two sources** (Action wiring 40 through 44; 2026-08-30-i): a query that conforms to no routed shape — an action-reference-shaped query among them, which the substrate routes to Reverse Index — and a constituent read's own invalid-query, relayed.

**A ledger entry carries its writer's invocation id** (Action wiring 1; 2026-08-30-l), so a read-back after an indeterminate arm is exact. A disclosure's records carry theirs by the protocol, which pairs every journal join on it (Recoverable Invocation Primitive policy 4, Recoverable Invocation Primitive policy 5).

### Wiring decision

```
Deleted: Wiring decision 1. Invariant 1.3 owns it: no disclosure id under two live outcome events at quiescence, a purged and an escalated disclosure carrying none beside it.
Wiring decision 2: The composition MUST NOT claim an atomic set spanning the accounting record AND the outcome event.
Wiring decision 3: The composition MUST NOT expose a disclosure surface other than [Disclose Subset].
Wiring decision 4: The composition MUST NOT require a particular proof mechanism.
```

WHY:
**Half 1 — the binding.** *Every [Disclose Subset] writes, in a fixed order and never atomically, an intent where the discloser is authenticated, a Selective Disclosure record — the accounting record of record — and an outcome event — the immutable, attributed, sealed, retained proof the disclosure occurred — and any partial failure between the last two is surfaced and compensated by one writer.* The settled state is one live outcome per accounting record: while an invocation is open, and while an escalated closing stands, a disclosure has its accounting record and no outcome event yet, and Capability requirement 29 ends the second interval as the sweep ends the first; past the horizon the binding stands where the outcome stood (Invariant 1.3, Invariant 1.6). A disclosure reaches its recipient only after its outcome event lands — the call's answer says so, or the read passthrough finds it by the invocation id once the sweep has recovered it — so an invocation closed as abandoned leaves nothing transmitted and nothing to record (Capability requirement 34).

*Principle.* Disclosure accounting an outside party can trust needs two facts inseparable: that the disclosure was recorded with its authority, and that the record of it is itself immutable, attributed and tamper-evident.

*Likely objection.* Why not let Selective Disclosure carry it alone?

*Mechanism.* Selective Disclosure extracted tamper evidence, retention and the recording actor's binding in its own EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) pass, and states its no-disclosure-unrecorded invariant as an obligation it cannot self-enforce. The composition is where they re-converge: the substrate supplies attribution, seal and retention in one surface, and making [Disclose Subset] the only disclosure surface that always writes both records closes the obligation for everything routed through it (Wiring decision 3). The accounting record is irreversible and no transaction spans the two stores (Wiring decision 2), so the one partial the order leaves is the orphan Recoverable Invocation's sweep closes.

*Result.* A disclosure-accounting record that is itself non-repudiable and tamper-evident, which neither constituent provides alone.

**Half 2 — partial verifiability as a capability, not a mechanism.**

*Principle.* The point of disclosing a subset is to prove that slice genuine without exposing the rest.

*Likely objection.* Doesn't this force a Merkle tree — bake a mechanism into the specification?

*Mechanism.* No, deliberately (Wiring decision 4). Tamper Evidence is itself mechanism-neutral — hash chains, Merkle trees and external anchoring are interchangeable realizations — so for this composition to demand Merkle would contradict its own constituent and raise one realization into the ontology. The obligation is behavioural: the substrate's tamper evidence can produce, for a named subset, an artifact an independent party checks against the ledger seal without the undisclosed entries. A deployment whose mechanism cannot is not non-conforming; its bundle degrades to whole-ledger verification and says so (Degraded bundle 1).

*Result.* The essential capability is specified; the mechanism is the deployment's — the line the library holds between *what must be true* and *how it is achieved*.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: EVERY reconciliation run the ledger enumeration answers MUST write the binding rebuild into the binding index.
Reconciliation 4: The reconciliation MUST NOT examine a young record.
Deleted: Reconciliation 5. Recoverable Invocation Invariant 7.2 owns it.
Reconciliation 6: The reconciliation MUST read EVERY accounting record Reconciliation 4 admits against the outcome events.
Reconciliation 7: The reconciliation MUST read EVERY outcome event against a read of the accounting store the ledger enumeration PRECEDES.
Deleted: Reconciliation 8. Recoverable Invocation reconcile step 2.1 owns it.
Deleted: Reconciliation 9. Recoverable Invocation reconcile step 2.3 owns it.
Deleted: Reconciliation 10. Recoverable Invocation reconcile step 2.5 owns it.
Deleted: Reconciliation 11. Recoverable Invocation Invariant 3.3 owns it, through the disclosure probe.
Deleted: Reconciliation 12. Recoverable Invocation reconcile step 3.8 owns it.
Deleted: Reconciliation 13. Recoverable Invocation reconcile step 3.10 owns it.
Reconciliation 14: IF no intent carries an orphan record's act key AND disclosure instant THEN the reconciliation MUST open a write-ownership finding for the record.
Deleted: Reconciliation 15. Recoverable Invocation reconcile step 3.11 owns it.
Deleted: Reconciliation 16. Recoverable Invocation Invariant 5.1 owns it.
Deleted: Reconciliation 17. Recoverable Invocation reconcile step 3.2 owns it.
Deleted: Reconciliation 18. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Reconciliation 19. Recoverable Invocation Invariant 5.2 owns it.
Deleted: Reconciliation 20. Recoverable Invocation Invariant 5.3 owns it, and narrows it: a recovered outcome carries what the store re-derives and nothing of the intent's.
Deleted: Reconciliation 21. Recoverable Invocation Invariant 3.5 owns it.
Deleted: Reconciliation 22. Recoverable Invocation reconcile step 3.20 owns it.
Deleted: Reconciliation 23. Recoverable Invocation reconcile step 3.20 owns it.
Deleted: Reconciliation 24. Recoverable Invocation reconcile step 3.17 owns it.
Deleted: Reconciliation 25. Reconciliation 3 owns it.
Deleted: Reconciliation 26. Recoverable Invocation reconcile step 5.1 owns it.
Reconciliation 27: The reconciliation MUST NOT record an audit event.
Reconciliation 28: A reconciliation run the ledger enumeration gives no answer MUST NOT write the binding rebuild.
Reconciliation 29: A reconciliation run a read gives no answer MUST NOT open a write-ownership finding.
Reconciliation 30: A reconciliation run a read gives no answer MUST alert the finding surface carrying the read.
Reconciliation 31: A reconciliation run whose binding rebuild's write gives no answer MUST alert the finding surface.
Reconciliation 32: IF an outcome event's disclosure id IS NOT IN the accounting store read of Reconciliation 7 THEN the reconciliation MUST alert the finding surface carrying the outcome event id.
Reconciliation 33: IF an orphan record's invocation is closed by an abandonment OR a refusal THEN the reconciliation MUST alert the finding surface carrying the disclosure id.
Reconciliation 34: A reconciliation run MUST NOT read the ledger enumeration BEFORE reading the accounting store.
```

Term reconciliation: the leg the composition runs outside every invocation, beside the sweep — the binding rebuild, and the reading of the accounting store against the ledger, whose output, a write-ownership finding, an auditor awaits.

Term young record: an accounting record whose disclosure instant stands within the act kind's window end of the reconciliation's now — a record whose invocation the sweep may still be closing. The edge is read from the disclosure instant; a record whose intent landed later than the edge allows is read with that intent already visible (Reconciliation 34), so the edge decides no finding.

Term aged record: an accounting record whose `disclosure instant + audit horizon` PRECEDES the reconciliation's now. A record written outside the composition with an instant already past the horizon is aged on arrival and never examined; Check 1.2 is where it shows, as a conformance failure (Composes 11).

Term orphan record: an accounting record no outcome event names and no binding names, neither young nor aged.

Term write-ownership finding: the reconciliation's report of an orphan record no intent carries — the record's disclosure id and the run that first met the record; one per record, deduplicated on the disclosure id so two runs that meet the record write one, standing for as long as the record is an orphan, on the finding surface.

Term finding surface: the deployment's compliance surface — the surface Recoverable Invocation's instance writes its register to. A write-ownership finding and this page's alerts are written beside that register and are no part of it (Recoverable Invocation findings 6); an auditor reads them there (External check 1).

Term settling closing: an outcome or an abandonment an operator writes through Recoverable Invocation's resolve, naming an escalated closing in supersedes — an outcome where the accounting record exists, an abandonment where the operator's probe shows none. An escalation whose cause is outcome-unrecordable is settled by an outcome once the deployment has repaired what refused the write, an abandonment there being false.

Term unsettled escalation: an escalated closing of the act kind no settling closing names.

Term reconciliation run bound: the bound a deployment declares on one reconciliation run, from its start to its last write, over the largest ledger the deployment sizes for.

Term settling period: the time a deployment declares for an operator to settle an escalation, the longest outage of the journal or the accounting store the deployment sizes for included — charged to the audit horizon, since the protocol's own start condition leaves an escalation little more than a completion bound ahead of its intent's horizon edge, which stands an allowance and a run bound short of the horizon (Capability requirement 31; Recoverable Invocation Term horizon edge).

Term discloser: the original caller of a [Disclose Subset] — the actor a recovered outcome carries as its acting actor reference.

Term recovered outcome: an outcome event the sweep or an operator wrote, carrying recovery and the discloser as the acting actor reference.

Term escalated closing: the standing closing of an invocation the invocation read answers as escalated — a ledger.disclosure.escalated record, carrying its cause.

Term record's invocation: the invocation whose intent carries an accounting record's act key and disclosure instant, found through the ledger enumeration kept to the intents.

WHY:
**What is left of the reconciliation.** Closing a disclosure whose invocation died — the pre-check under the critical section, the probe, the recovery intent, the recovered outcome under the recovery identity, the escalation where the store cannot say — is the sweep's. Two things remain this composition's own, because no other page has both stores in view.

**Rebuild first, every run** (Reconciliation 1 through 3): the full binding rebuild is written into the index each run, so the half that becomes truth-bearing at the purge is captured within one cycle of every outcome's landing — before any purge can reach it. An invocation's own index write is not enough: a crashed invocation never reaches it, and a recovered outcome is written by a sweep that knows nothing of the index.

**The accounting store is read against the ledger** (Reconciliation 4, 6, 7 and 14). The sweep starts from intents, so a record written to Selective Disclosure by a direct call — no intent, no invocation — is invisible to it. This leg starts from the records. One that no outcome names, past the window in which the sweep closes an open invocation and short of the horizon, either has an intent of its act key at its exact instant or has none. With one, it is that invocation's — open or escalated — and Recoverable Invocation's own surfaces carry it; an invocation closed as refused or abandoned over a record that exists is a false closing, which the gap verdict reports and every run alerts until an operator's outcome supersedes an abandoned closing (Verdict 5, Check 1.2, Reconciliation 33; Recoverable Invocation resolve 16) — a refused one, which only a store that wrote while refusing leaves, alerts for as long as it stands. The run reads the store before the ledger, so every record it reads has its intent already visible, an intent landing before its commit (Reconciliation 34); an outcome is checked against a second read of the store, issued after the enumeration, so a disclosure landing mid-run alerts nothing (Reconciliation 7, Reconciliation 32). The leg finds that intent by its own enumeration and not by the protocol's read by act key, which answers only the most recent invocations on a key and offers no cursor (Recoverable Invocation read invocation 2); many disclosures share a key here, and a keyed read past the cap is that page's to add. With none it is a write-ownership finding against Composes 11, never compensated (2026-08-26-e, 2026-08-30-g). The leg writes nothing to the ledger (Reconciliation 27). A record whose outcome the horizon has destroyed is still named by its binding and is no orphan, so the place of the aged edge against the substrate's clock decides no finding; and a run one of whose reads got no answer has not read the stores against each other — it opens no finding and says which read failed. The rebuild reads the ledger alone and is withheld only where the ledger gave no answer, so an outage of the accounting store never keeps an outcome from its binding (Reconciliation 28 through 30).

### Verdict

```
Verdict 1: IF EXACTLY ONE live outcome event carries the disclosure id THEN the binding verdict MUST carry bound.
Verdict 2: IF the count of live outcome events carrying the disclosure id EXCEEDS one THEN the binding verdict MUST carry binding-duplicate naming the event ids.
Verdict 3: IF no live outcome event carries the disclosure id AND the binding index names an event the record read answers Purged THEN the binding verdict MUST carry binding-purged.
Verdict 4: IF no live outcome event carries the disclosure id AND no purged binding names the disclosure id AND an escalated closing stands for the record's invocation THEN the binding verdict MUST carry binding-escalated carrying the cause.
Verdict 5: IF no live outcome event carries the disclosure id AND no purged binding names the disclosure id AND no escalated closing stands for the record's invocation THEN the binding verdict MUST carry binding-gap.
Deleted: Verdict 6. Recoverable Invocation Which closing stands 2 owns it: an outcome supersedes an escalation it names.
Verdict 7: IF the binding verdict carries binding-purged THEN the attestation verification MUST carry failed-verification carrying purged.
Verdict 8: An entry's authenticity MUST carry EXACTLY ONE OF authentic, altered, not-in-ledger, unverifiable carrying the reason.
Verdict 9: IF a disclosed entry sits in the unsealed tail at the bundle's construction THEN the bundle MUST mark the entry unverifiable carrying unsealed.
Verdict 10: IF a disclosed entry's event carries Purged at the bundle's construction THEN the bundle MUST mark the entry unverifiable carrying entry-purged.
Verdict 11: IF the verification bundle OR the ledger seal reference is malformed THEN EVERY presented entry MUST carry unverifiable carrying bundle-malformed.
Verdict 12: IF no entry is presented THEN the overall verdict MUST carry disclosure-unverified carrying no-entries-presented.
Verdict 13: The overall verdict MUST carry disclosure-verified ONLY IF EVERY presented entry carries authentic AND confidentiality preserved EQUALS true.
Verdict 14: [Verify Disclosure] MUST carry the verification routine's own report as confidentiality preserved.
Verdict 15: IF no live outcome event carries the disclosure id AND no purged binding names the disclosure id AND the record's invocation EXISTS THEN a found ledger verification MUST read the state of the record's invocation through the invocation read carrying the invocation id.
```

Term binding verdict: [Bound] | [Binding Duplicate] | [Binding Purged] | [Binding Escalated] | [Binding Gap].

Term live outcome event: an outcome event no other closing supersedes, whose retention the record read answers Retained or unresolved in its compensation window.

WHY:
**Every binding case lands, and there are five** (Verdict 1 through 5, 7 and 15; 2026-08-30-a, 2026-08-30-n). Two live outcomes for one disclosure id is a second writer, foreclosed by the one-writer rule and reported with both ids rather than resolved by choosing one. The purged case is decidable from the records only because **this composition** kept the key, in the one store that keys it after the payload is gone; an index entry lost past the horizon leaves it indistinguishable from a gap and is reported as one — a finding against the index durability, and honestly one of *loss*. An escalated closing is the sweep's record that it could not write the outcome — the store answered more than one candidate, the store did not show the act, or the substrate refused the record outright — and the verdict carries its cause; an operator's outcome through Recoverable Invocation's resolve supersedes it, and the verdict is then bound (Verdict 4 and 15). The state is read through the protocol's own read, which owns which closing stands; a journal that cannot be read answers as itself and never as a gap (Action wiring 56; Recoverable Invocation Action wiring 3). An escalation is an interval and not an end: an operator supersedes it with an outcome, or with an abandonment where the store holds no record, before the intent reaches its horizon edge (Capability requirement 29), because past that edge the intent that ties the record to its invocation is destroyed, the protocol refuses the resolution (Recoverable Invocation resolve 12), and nothing this page keeps would tell the record from a gap. A record with no invocation, or one the invocation read answers not-known for, has no closing standing and is the gap. An invocation held open past its window by an outage of the journal or the accounting store is exempt on that page for as long as the outage, and is no failure here either (Check 1.2). binding-gap is never a steady state under a conforming implementation: an invocation still inside its window, or a conformance failure.

**Every entry an unsealed or purged ledger cannot prove is marked, not proved** (Verdict 9 and 10; 2026-08-26-i, 2026-08-30-d, 2026-08-30-e): an entry in the unsealed tail cannot yet anchor a proof, and one whose payload is lawfully destroyed can no longer be checked — the bundle says which, per entry, and the disclosure's accounting stands. **[Verify Disclosure] answers with a verdict, never a refusal** (Verdict 11 through 13): a malformed bundle or seal reference is an unverified disclosure, and zero presented entries is never a vacuous success. **Confidentiality is self-reported** (Verdict 14): computed by the routine over the bundle the discloser produced and not recomputable from these records; its trust rests on the deployment's security review of the mechanism's zero-knowledge-of-complement construction (External check 6). A recipient independently confirms *authenticity* against the published seal; *confidentiality* is an assurance about the audited mechanism.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs the Audit Trail substrate and Selective Disclosure together.

- **Invariant 1 — Disclosure-accountability binding bijection.**
  ```
  Deleted: Invariant 1.1. Recoverable Invocation Invariant 4.1 owns it.
  Deleted: Invariant 1.2. Recoverable Invocation Invariant 4.2 owns it.
  Invariant 1.3: Two live outcome events MUST NOT carry one disclosure id at quiescence.
  Invariant 1.4: EVERY outcome event MUST carry a disclosure id the accounting store carries.
  Deleted: Invariant 1.5. Recoverable Invocation Invariant 5.2 owns it.
  Invariant 1.6: IF an accounting record's outcome event carries Purged THEN the binding index MUST keep the record's binding.
  ```

  WHY: a one-to-one binding between the accounting records this composition produced and the outcome events — *produced* meaning opened: a record whose act key and instant an intent carries, a record none carries being a write-ownership finding against Composes 11 (2026-08-26-e, 2026-08-30-g). The two truth-bearing writes are ordered, never atomic, and the accounting record is irreversible, so the orphan is reachable and durable until closed. **What this page states is the bijection's shape** (Invariant 1.3, 1.4 and 1.6): no disclosure id under two live outcomes, no outcome naming a record the store lacks, and the binding kept past the purge. The first reaches exactly as far as the protocol's one-writer invariant: where the substrate declares no journal fence, a paused writer's late append beside another writer's closing is left standing, reported, and resolved by an operator's superseding record (Recoverable Invocation Invariant 2.4, Recoverable Invocation journal fence none 1), and until then [Verify Ledger] answers binding-duplicate with both ids. Two live outcomes under two invocation ids is another thing: no late append makes it, only a pairing the probe's key forbids, and it stands as a conformance failure no action repairs. This page counts every outcome no closing supersedes, where the protocol names one closing among unsuperseded ones as standing; the two agree but for an escalation beside a later outcome nothing supersedes, which reads bound here — the outcome exists and carries the disclosure id — and escalated there, until an operator's closing names both (Recoverable Invocation resolve 9a). **That the shape is reached** — every dead invocation's record closed by an outcome or an escalation, inside a declared window, by exactly one writer, with a recovered outcome distinguishable from an invocation's own — is Recoverable Invocation's Invariant 2, 4 and 5, proved once in that page's model for every adopter and no longer argued here. **Retention horizon** (Invariant 1.6): accounting records are never removable, so when an outcome event is lawfully purged the record survives it — not an orphan and not a gap, answered as binding-purged through the key this composition kept; past the horizon the bijection reads *every record bound to exactly one outcome event or to that event's honest-destruction record*. This composition's own model is pending re-derivation over what remains its own: the binding index and the reading of two stores (2026-08-29-a, 2026-08-30-m). *Rests on* Selective Disclosure Invariant 1 and 6, Audit Trail Invariant 1, 3 and 8, Recoverable Invocation Invariant 2 through 5 and 7, and the reconciliation.
- **Invariant 2 — Verifiable partial disclosure.**
  ```
  Invariant 2.1: IF the partial disclosure capability EQUALS true THEN a party holding the disclosed entries, the verification bundle AND the ledger seal reference MUST verify EVERY sealed disclosed entry's authenticity.
  Invariant 2.2: IF the partial disclosure capability EQUALS true THEN the verification bundle MUST NOT reveal an undisclosed entry.
  Invariant 2.3: IF the partial disclosure capability EQUALS false THEN the verification bundle MUST declare the degradation.
  ```
  WHY: a conditional invariant, the antecedent inside the statement, because partial verifiability is a present-or-absent capability of the configured mechanism. **Qualified by the unsealed tail** (2026-08-26-i): an entry not yet sealed at disclosure cannot anchor a proof, and the bundle marks it unverifiable (Verdict 9) — Invariant 2.1 speaks of sealed entries. The confidentiality half is self-reported and cleared externally (External check 6). *Rests on* Audit Trail Invariant 3 (integrity coverage, modulo the unsealed tail) and Audit Trail Invariant 7 (the verifier presents the records), the declared capability, and the composition-introduced subset-proof surface.
- **Invariant 3 — Immutable, attributed, retention-governed ledger.**
  ```
  Invariant 3.1: EVERY ledger event MUST carry an attestation AND a position in the Event Log sequence.
  Invariant 3.2: The composition MUST NOT change a ledger event.
  Invariant 3.3: The composition MUST NOT reorder a ledger event.
  Invariant 3.4: EVERY ledger event MUST carry a retention record at quiescence of the substrate's compensation (Audit Trail Invariant 2).
  ```
  WHY: every entry, intent and outcome is append-only and totally ordered, attributed, sealed under the cadence, and placed under retention at write time with honest cascade on purge. *Rests on* Audit Trail Invariant 1 through 4, 6 and 8, holding transitively over the four atoms.
- **Invariant 4 — No disclosure unrecorded, structurally closed.**
  ```
  Invariant 4.1: A disclosure through the composition MUST NOT answer success BEFORE the accounting record AND the outcome event land.
  ```
  WHY: Selective Disclosure's Invariant 5, which the atom can only state, is enforced here for disclosures routed through the composition; one performed outside it is a system conformance failure against the atom's invariant and outside this composition's claim (Composes 11). *Rests on* Invariant 1 and Wiring decision 3.
- **Invariant 6 — Authentication precedes commitment.**
  ```
  Deleted: Invariant 6.1. Recoverable Invocation Invariant 1.1 owns it.
  Deleted: Invariant 5. Composes 5 owns it.
  ```
  WHY: the protocol's first invariant, for every adopter: the intent stands before the one irreversible write, so a permanent accounting record is never created on an unverified actor's asserted authority, and invalid-credential is a pre-state refusal with nothing in either store (Recoverable Invocation Invariant 1). [Record Entry] needs no second mechanism: its one write is the credential-verifying and the load-bearing call alike. **What it does not establish**: a validation shows matching material was presented at that instant — not that the presenter *is* the actor, not a channel binding, not replay resistance — **and nothing whatever about the other three references a disclosure carries**: the subject, whose correspondence is the host's assertion; the recipient, never authenticated here — [Verify Disclosure] being runnable *by* a recipient is a capability statement, not an identity claim; and the authority's holder. *Rests on* the audit write and the Actor Identity attestation reached through it; Recoverable Invocation Check 1.1 tests the order from the records. The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).

The binding and no-disclosure-unrecorded give *accountable disclosure*; verifiable partial disclosure gives *the slice is provably genuine and the rest stays hidden*; the immutable ledger underlies both; authentication before commitment makes the accounting exact.

---

## Examples

### Walkthrough — broker-dealer trade-confirmation ledger under SEC Rule 17a-4

A registered broker-dealer deploys this composition as the trade-confirmation ledger for one trading desk. Configuration: `ledger_retention_policy = sec_17a4_6yr` (encoding the six-year floor with the first two years immediately accessible), `seal_cadence = per-event` (each entry independently verifiable the moment it lands, so any subset disclosed later carries a valid partial proof), `tamper_evidence_supports_partial_disclosure = true` (the substrate's Tamper Evidence mechanism — a per-ledger Merkle tree — can produce an inclusion proof for any named subset). The payloads below are abbreviated: every event also carries the invocation id.

1. **Three trades are recorded.** For each executed trade, the desk calls `record_entry(transaction_data = {symbol, qty, price, counterparty, …}, actor_ref = "trader-d12", credential = <trader_cred>)`. The composition calls `AuditTrail.record_action(action_ref = ledger.entry, actor_ref = "trader-d12", <trader_cred>, data = {transaction_data, recorded_at})` three times → `{entry_id = "ev_5001"}`, `{entry_id = "ev_5002"}`, `{entry_id = "ev_5003"}`. Each entry is now an immutable, attributed, per-event-sealed, retained ledger event. No disclosure has occurred, so `disclosure_to_event` is empty.

2. **An examiner requests one trade.** A FINRA (Financial Industry Regulatory Authority) examiner requests the confirmation for the single trade recorded at `ev_5002` — and only that trade; the desk's other positions are outside the examiner's scope. The compliance officer calls:

   ```
   disclose_subset(
     disclosed_entry_ids = {"ev_5002"},
     subject_ref = "account-7731",
     recipient = "FINRA-exam-2026-Q2",
     scope = "trade-confirmation:single-trade:ev_5002",
     authority = { type: "regulatory", reference: "SEC Rule 17a-4(b)(4) — examiner production" },
     actor_ref = "compliance-c4",
     credential = <compliance_cred>
   )
   → { disclosure_id = "disc-2210", event_id = "ev_5005", verification_bundle = <Merkle inclusion proof for ev_5002> }
   ```

   The open goes first: `RecoverableInvocation.open(kind = ledger.disclosure, act_key = ("account-7731", "FINRA-exam-2026-Q2", scope, authority), actor_ref = "compliance-c4", <compliance_cred>, intent_data = {disclosed_entry_ids: {"ev_5002"}, subject_ref: "account-7731", recipient, scope, authority.type, authority.reference, disclosed_at})` takes the act's critical section and writes `ledger.disclosure.intended` → `{invocation_id, intent_event_id: "ev_5004"}`. That write is where `compliance-c4`'s credential is validated, so nothing has been written to either store if it does not — the permanent disclosure-accounting record below is never created on an unverified claim. Then the commit: `SelectiveDisclosure.record(...)` → `disc-2210`. Then the close: `RecoverableInvocation.close(kind, act_key, invocation_id, intent_event_id = "ev_5004", actor_ref, <compliance_cred>, outcome_action_ref = ledger.disclosure.disclosed, outcome_data = {disclosure_id: "disc-2210", subject_ref: "account-7731", recipient, scope, authority.type, authority.reference, disclosed_at})` → `{outcome_event_id: "ev_5005", landed_by: invocation}`; then `disclosure_to_event["disc-2210"] = "ev_5005"`. The outcome names its intent, which is what lets an auditor confirm from the records alone that the disclosing actor was authenticated before the disclosure existed, and where the disclosed set is read. The act of disclosing is now itself an immutable, attributed, sealed ledger entry. The verification_bundle is the Tamper Evidence inclusion proof for `ev_5002` against the published ledger seal — and for `ev_5002` *only*.

3. **The examiner independently verifies the disclosed trade.** The examiner holds the disclosed entry payload (the `ev_5002` confirmation), the verification_bundle, and the broker-dealer's published ledger_seal_reference (the Merkle root, anchored to an RFC 3161 (the Internet standard for trusted time-stamping) Time-Stamp Authority (TSA) — a trusted third party that signs proofs of when data existed). The examiner — *without any access to `ev_5001` or `ev_5003`* — runs `verify_disclosure(disclosed_entries = [ev_5002 payload], verification_bundle, ledger_seal_reference)`:

   - `entries`: `[{entry_id: "ev_5002", authenticity: authentic}]` — the inclusion proof checks against the root, so the disclosed trade is a genuine, unaltered ledger entry.
   - `confidentiality_preserved = true` — the inclusion proof reveals sibling hashes but not the contents, count, or position of `ev_5001` / `ev_5003`.
   - `overall_verdict = disclosure-verified`.

   The examiner trusts the trade without trusting the broker-dealer and without seeing the rest of the book. This is Invariant 2 (verifiable partial disclosure) in operation.

4. **A compliance auditor verifies the accountability side.** Separately, an internal auditor with access to the composition's stores asks: *was this disclosure recorded and attributed?* The auditor calls `verify_ledger(disclosure_id = "disc-2210", original_event_payloads)`:

   - `binding = bound` — the `ledger.disclosure.disclosed` event `ev_5005` carries `data.disclosure_id = "disc-2210"`, confirmed by the substrate read (Invariant 1); the enumeration found that event and no other, and the `disclosure_to_event` index names the same one.
   - `attestation_verification = verified` — `read_record("ev_5005")` names its position and covering range, the auditor's original_event_payloads supplies every payload in that range keyed by `sequence_number`, and `AuditTrail.verify_record("ev_5005", <the range's payloads>)` confirms the disclosing officer's credential and the seal over the disclosure event.
   - `retention_state = Retained`.

   The two verification surfaces answer two different questions: [Verify Disclosure] (anyone holding the bundle) proves the *subset is genuine*; [Verify Ledger] (an auditor with the stores) proves the *disclosure was accounted*. Neither constituent answers either alone.

### Healthcare — accounting of disclosures under HIPAA section 164.528

A covered entity keeps each patient's billing-disclosure ledger in this composition. Every time PHI (Protected Health Information) is disclosed to a payer, a public-health authority, or a business associate, the entity calls [Disclose Subset] naming the disclosed billing entries, the recipient, and the authority (`{ type: regulatory, reference: "HIPAA §164.512(b)" }` for public-health reporting; `{ type: consent, reference: "<consent-id>" }` for patient-authorized sharing). When the patient exercises their section 164.528 right to an accounting of disclosures, the entity calls read against the Selective Disclosure store filtered by `subject_ref = <patient>`: the result is every disclosure — date, recipient, scope, authority — drawn from the records alone. Because each disclosure is also a `ledger.disclosure.disclosed` event (Invariant 1), the accounting is itself immutable, attributed, and tamper-evident — a property section 164.528's accounting obligation needs but the plain Selective Disclosure atom cannot supply alone.

### Clinical-trial submission ledger under 21 CFR Part 11

A sponsor records each electronic submission to a regulator as a [Record Entry] in a 21 CFR Part 11 submission ledger (attributable, contemporaneous, original, accurate — ALCOA — satisfied by the Audit Trail substrate). When the sponsor discloses a defined subset of the submission record to an inspector or an IRB (Institutional Review Board), [Disclose Subset] produces both the accountable disclosure record and the partial-disclosure proof for exactly the disclosed documents, leaving the remainder of the submission sealed and unrevealed. The inspector verifies the disclosed subset against the published seal; the sponsor's disclosure log answers *what was shown, to whom, under what authority* from the records alone.

### Rejection path — empty or unknown subset

A caller attempts to disclose with no entries: `disclose_subset(disclosed_entry_ids = {}, …)` → `rejected(invalid-request)` at validation (Primitive policy 3); nothing is written to either store. A caller names an entry id that is not a ledger transaction entry — a fabricated id, or the `event_id` of a `ledger.disclosure.disclosed` event rather than a `ledger.entry` event: `disclose_subset(disclosed_entry_ids = {"ev_5005"}, …)` → `rejected(unknown-entry)` naming `ev_5005` (it is a disclosure event, not a transaction entry); nothing is written. The membership test (every id resolves to a `ledger.entry` event) runs *before* the irreversible Selective Disclosure write, so an invalid subset never produces a disclosure-accounting record.

### Rejection path — ledger write fails after the disclosure record commits (the orphan)

The compliance officer calls [Disclose Subset] with a valid subset. The open lands the intent and the commit succeeds: `SelectiveDisclosure.record(...)` → `disc-2211` is durably written (Selective Disclosure records are immutable once committed). The close fails: its pre-check under the act's critical section finds no closing for the invocation, and `AuditTrail.record_action(ledger.disclosure.disclosed, …)` returns `recording-failure(step-2)` (the actor registry is briefly unreachable) on each attempt until the lease no longer admits a write. The composition returns `rejected(recording-failure(outcome, inv-9c4))` — the position telling the officer the accounting record exists and the action must not be re-run, and the invocation by which the officer finds its outcome once the sweep lands it. The result, once the record is no longer young, is an **orphan**: a Selective Disclosure record (`disc-2211`) with no `ledger.disclosure.disclosed` record (and consequently no `disclosure_to_event` entry — the missing record is the orphan's defining lack; the index merely reflects it). Its intent stands open, and Recoverable Invocation's sweep closes it: once the intent is past its examine edge, a run takes the same critical section, probes the accounting store for the act key at the intent's instant, finds `disc-2211`, and writes `ledger.disclosure.recovery_intended` and then the outcome under the recovery identity, `recovery = true`, the officer carried as the acting actor reference. The next reconciliation run writes the binding. Had the store answered two records for that key and instant, the sweep would have chosen neither and written `ledger.disclosure.escalated` naming both, and [Verify Ledger] would answer `binding-escalated` until an operator resolved it.

### Retention horizon — a disclosure event reaches its lawful end

Years later, the `ev_5005` disclosure event from the walkthrough reaches the end of `ledger_retention_policy` and is lawfully purged (Audit Trail cascade-on-purge): its payload — `data.disclosure_id` included — is unreadable, and the substrate's destruction record keeps only `(ev_5005, a_5005)`, off which `action_ref = ledger.disclosure.disclosed` and the discloser still read. The Selective Disclosure record `disc-2210` survives — its store is not governed by that policy — and so does the composition's own index entry `disclosure_to_event[disc-2210] = ev_5005`, the purged half that is truth-bearing under the durability obligation (Composition state). An auditor later calls `verify_ledger("disc-2210", …)`: the rebuild read finds no live `ledger.disclosure.disclosed` event, the index entry resolves `ev_5005` to a `Purged` retention record and a destruction record whose attestation names `ledger.disclosure.disclosed`, and the action returns `binding = binding-purged`, `attestation_verification = failed-verification(purged)`, `retention_state = Purged` — honest destruction, distinguishable from a `binding-gap`, exactly Invariant 1's retention-horizon arm. Nothing is surfaced as a finding; nothing is wrong.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit — "produce the accounting of disclosures, and prove each is genuine" (HIPAA section 164.528 / SEC Rule 17a-4).**

A regulator queries the disclosure-accounting surface for a subject (a patient under section 164.528, an account under 17a-4). The system calls read against the Selective Disclosure store filtered by subject_ref, returning every disclosure — date, recipient, scope, authority. For any disclosure the regulator wishes to verify, the system calls `verify_ledger(disclosure_id, original_event_payloads)`:

- `binding = bound`: by Invariant 1 (binding bijection), every disclosure record produced by the composition has exactly one corresponding `ledger.disclosure.disclosed` event. A disclosure cannot appear in the accounting without its immutable, attributed, sealed ledger event.
- `attestation_verification = verified`: by Invariant 3 (immutable, attributed, retention-governed ledger), the disclosure event is attributed to the disclosing actor's verified credential and covered by a seal.
- `retention_state = Retained` (or `Purged` with an honest retention record for lawfully expired entries).

The accounting and its proof come from the records alone. Invariants 1, 3, and 4 are the structural basis; no developer narration is required.

**Disputed transaction / data-subject request — "prove this disclosed trade subset is authentic without revealing my other trades" (GDPR Article 15).**

A data subject (or a counterparty) was shown a subset of the ledger and challenges it: either (a) the disclosed entries were not genuine ledger entries, or (b) showing them exposed or compromised the undisclosed remainder. The recipient — holding only the disclosed entries, the verification_bundle, and the published ledger_seal_reference — runs [Verify Disclosure]:

- Claim (a): per-entry `authenticity = authentic`, resting on Invariant 2 and Audit Trail Invariant 3 (integrity coverage). The inclusion proof checks each disclosed entry against the published seal; an altered or fabricated entry returns altered or not-in-ledger. The recipient verifies authenticity *without trusting the discloser* — the proof is self-contained against the seal (conditional on the seal-publication obligation: the recipient's ledger_seal_reference must be independently obtained, or the proof is self-contained against whatever ledger the discloser handed them — see the externally-clearable checks).
- Claim (b): `confidentiality_preserved = true`, resting on Invariant 2's zero-knowledge-of-complement obligation. The bundle reveals nothing about the count, content, or position of the undisclosed entries beyond what the published seal inherently commits to. The GDPR Article 15 right to one's own disclosed data is satisfied *without* a parallel breach of every other data subject whose entries share the ledger.

The disputed claim has no structural basis on the authenticity axis: claim (a) is checkable by the challenger themselves against the published seal (Invariant 2, authenticity half). Claim (b) — confidentiality of the remainder — rests on the audited mechanism's zero-knowledge-of-complement property: `confidentiality_preserved` is self-reported, and its independent assurance is the deployment's security review of the mechanism (the externally-clearable check), not a verdict the challenger recomputes. The spec does not overclaim claim (b) as recipient-recomputable.

**Breach or incident investigation — "is every disclosure accounted, and is any disclosure orphaned?"**

An incident responder suspects that a disclosure occurred without being recorded, or that a disclosure record was tampered with. The responder runs the binding-bijection audit (Invariant 1) across the two stores:

- For every Selective Disclosure record produced by the composition, confirm a `ledger.disclosure.disclosed` event exists whose `data.disclosure_id` points back (the authoritative substrate read; `disclosure_to_event` accelerates it as a derived index). A disclosure record with no such event is an **orphan** — the partial-failure signature, whose intent Recoverable Invocation's sweep closes inside the act kind's compensation window, by a recovered outcome or by an escalation an operator resolves; an orphan found here past that window with no closing on its invocation is a conformance failure, not a transient, and one with no intent at all is a write-ownership finding. A recovered binding is distinguishable by its `recovery` field and its attester.
- For every `ledger.disclosure.disclosed` event, confirm its `data.disclosure_id` resolves to a Selective Disclosure record. A `ledger.disclosure.disclosed` event naming a disclosure_id absent from the disclosure store is the inverse orphan.
- For the disclosure events themselves, walk the Audit Trail seal store in `sealed_at` order (inherited from the substrate's breach-forensics scenario): the most recent seal that verifies end-to-end and the first that returns `failed-verification(seal-proof-invalid)` bound the forensic window during which a disclosure event may have been tampered with.

The binding bijection is what makes "every disclosure is accounted" a checkable property rather than a hope; the orphan is exactly the reachable bad state the formal model rejects.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the binding index, the Selective Disclosure store and the Audit Trail substrate stores, can clear the checks below without recourse to source code, runbooks or developer narration. Every enumeration of ledger events below runs through the ledger enumeration, never through a query the substrate routes to Reverse Index.

### Conformance checks

```
Check 1.1: An auditor MUST read EVERY accounting record against the outcome events (Reconciliation 6).
Check 1.2: An auditor MUST resolve EVERY accounting record carrying no live outcome event, a young record excepted, to EXACTLY ONE OF binding-purged, binding-escalated, an open invocation inside the act kind's compensation window, an open invocation Recoverable Invocation Check 3.3 exempts, a write-ownership finding, a conformance failure (Reconciliation 14).
Check 1.3: An auditor MUST read a young record as inconclusive (Reconciliation 4).
Deleted: Check 1.9. Check 1.2 owns it: an escalation left past its intent's horizon reads as the gap, and a second check of the same records overlapped the first.
Check 1.4: An auditor MUST find EVERY outcome event's disclosure id carried by the accounting store (Invariant 1.4).
Check 1.5: An auditor MUST find no disclosure id two live outcome events carry at quiescence (Invariant 1.3).
Deleted: Check 1.6. Recoverable Invocation Check 2.5 owns it.
Deleted: Check 1.7. Recoverable Invocation Check 2.5 owns it.
Deleted: Check 1.8. Recoverable Invocation Check 4.1 owns it.
Check 2.1: IF the partial disclosure capability EQUALS true THEN an auditor MUST find [Verify Disclosure] answering authentic for EVERY sealed disclosed entry a presented bundle covers (Invariant 2.1).
Check 2.2: IF the partial disclosure capability EQUALS false THEN an auditor MUST find the bundle declaring the degradation (Invariant 2.3).
Check 3.1: An auditor MUST find EVERY ledger event attested AND placed in the Event Log sequence (Invariant 3.1).
Check 3.2: An auditor MUST find a passing verification for EVERY ledger event whose covering range the auditor presents (Invariant 3.1).
Check 3.3: An auditor MUST find EVERY ledger event under a retention record, an event unresolved in the event's compensation window excepted (Invariant 3.4).
Check 4.1: An auditor MUST find [Disclose Subset] the composition's only disclosure surface (Wiring decision 3).
Deleted: Check 5.1. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.2. Recoverable Invocation Primitive policy 5 owns it.
Deleted: Check 5.3. Recoverable Invocation Check 1.1 owns it.
Deleted: Check 5.4. Recoverable Invocation Check 3.1 owns it: an aged intent carries a closing inside the window.
Deleted: Check 5.5. Recoverable Invocation Check 1.4 owns it.
Check 5.6: An auditor MUST read a disclosure's disclosed set from the intent the outcome event names (Composition state 16).
Check 5.7: IF the record read answers Purged for an outcome event's intent THEN an auditor MUST read the disclosed set as unverifiable carrying purged-horizon (Composition state 16).
Check 6.1: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 6.2: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 5).
Check 6.3: An auditor MUST clear Recoverable Invocation's Generation acceptance over the act kind (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged | unverifiable carrying partially-purged-coverage — the last being what the substrate answers for every Retained member of a range one member of which the horizon has destroyed.

WHY:
**Every accounting record is read, and the unpaired one is named** (Check 1.1 and 1.2; 2026-08-30-g). The prose quantified over *every record produced by this composition*, which no field declares; every record is enumerated instead, and one with no live outcome resolves to exactly one class — the purged verdict, an escalated closing, an invocation still open inside its window, a write-ownership finding for a record no intent carries, or a conformance failure. **The enumeration starts past the window** (Check 1.3): inside it the record's invocation may still be the sweep's to close, and whether it closed on time is the protocol's check.

**What the protocol's checks now carry** (the tombstones of Check 1.6 through 1.8 and 5.1 through 5.5; Check 6.3). That every outcome follows an intent of the same invocation attested under the discloser, that the join is the invocation id and nothing weaker, that a recovered outcome is told from an invocation's own by its shape, that an aged intent carries a closing inside the window, that a purged intent reads purged and never absent, and that the instance's numbers meet its start conditions — each is Recoverable Invocation's, a check of its Generation acceptance or, for the join, its Primitive policy 5, cleared over the act kind and cited, not counted. **What stays here is the set** (Check 5.6 and 5.7): the disclosed entry ids are read from the intent, and since the intent and the outcome are placed under retention by their own writes under one policy, a purge landing between their retention deadlines destroys the intent while the outcome is still live — the set is then unverifiable, never a finding. Invariant 1.6 and Invariant 4.1 carry no check: a purged outcome's disclosure id survives only in the binding index, so no record outside it can show the index has lost one, and Invariant 4.1 speaks of an answer, which no record keeps.

**The constituents' own bars are cited, not counted** (Check 6.1 through 6.3; 2026-08-26-f): a count copied from another page goes stale on that page's next change, and this one had.

### External checks

```
External check 1: An auditor needing a write-ownership finding's surfacing confirmed MUST read the deployment's finding surface AND reconciliation schedule (Reconciliation 14).
External check 2: An auditor needing an asserted authority's validity confirmed MUST read the authority's own pattern (Non-goal 1).
External check 3: An auditor needing a disclosure's permission confirmed MUST read the deployment's Consent AND Permissions records (Non-goal 1).
External check 4: An auditor needing the transaction data's accuracy confirmed MUST read the host's source of the transaction (Primitive policy 13).
External check 5: An auditor needing the disclosed entries' correspondence to the subject confirmed MUST read the host's subject tagging (Non-goal 6).
External check 6: An auditor needing the partial disclosure capability AND complement confidentiality confirmed MUST read the deployment's security review of the mechanism (Invariant 2.2).
External check 7: An auditor needing the ledger seal reference's singularity AND the verifier's independence confirmed MUST read the deployment's seal publication (Invariant 2.1).
```

WHY:
The records prove an orphan exists and that a recovery happened; whether a record no intent carries was surfaced is the finding surface's, operational (External check 1), and the surfacing of an open or escalated invocation is Recoverable Invocation's own external check. The authority is recorded and made auditable, never adjudicated. **The subject's correspondence is the host's assertion** (External check 5): the transaction data is opaque, so nothing here connects an entry to the subject a disclosure is filed under, and under HIPAA section 164.528 entries of patient A disclosed under another subject escape A's accounting with no records-alone detection. **Split view** (External check 7): a discloser who keeps a forked side-ledger and hands the recipient the fork's root passes every check *against that fork*; protection is the seal-publication discipline — a time-stamping authority, a regulator filing, a public anchor — and the bundle format must be standard enough that a verifier can be built without the discloser's code.

---

## Non-goals

```
Non-goal 1: The composition MUST NOT decide whether a disclosure is permitted.
Non-goal 2: The composition MUST NOT perform payload handling.
Non-goal 3: The composition MUST NOT guarantee at-most-once append.
Non-goal 4: A deployment needing at-most-once append MUST compose Idempotent Reservation over [Record Entry].
Non-goal 5: The composition MUST NOT suspend a purge of the ledger.
Non-goal 6: The composition MUST NOT validate a disclosed entry's correspondence to the subject reference.
Non-goal 7: The composition MUST NOT record an audit event for a query.
Non-goal 8: The composition MUST NOT disclose an outcome event as a subset.
Non-goal 9: The composition MUST NOT track an artifact's custody.
Non-goal 10: The composition MUST NOT adjudicate an erasure request against a retention obligation.
```

Term payload handling: retrieving, redacting or transmitting a disclosed payload.

Term accounting-horizon cover: a ledger retention policy aligned to the accounting horizon.

Term accounting horizon: the horizon a regime sets for an accounting of disclosures — HIPAA section 164.528's six years, for one.

WHY:
**Authorization is a peer's** (Non-goal 1): whether this actor may disclose this subset to this recipient on this basis is [Consent](../atoms/consent.md) and [Permissions](../atoms/permissions.md), run before [Disclose Subset]; the authority field records the asserted basis and makes it immutable and attributable. **Selective Disclosure's boundary holds** (Non-goal 2): the composition records *that* a subset was disclosed and proves it genuine, and the payloads travel by whatever transmission the deployment uses; the bundle is a tamper-evidence artifact, not a delivery channel.

**At-most-once append is an enrichment** (Non-goal 3 and 4): two [Record Entry] calls with identical transaction data are two entries, the same non-idempotency Event Log and Selective Disclosure carry; a deployment where a retried entry must not double-append a trade composes [Idempotent Reservation](./idempotent-reservation.md) or [Duplicate Prevention](../atoms/duplicate-prevention.md) keyed on a caller token. **Holds and erasure are siblings'** (Non-goal 5 and 10): [Defensible Retention](./defensible-retention.md) composes the hold-blocks-purge gate over the ledger's retention; a GDPR (the EU General Data Protection Regulation) Article 17 request colliding with a retention obligation is Erasure Coordination's, inherited from Audit Trail Non-goal 6.

**Queries are not audited here** (Non-goal 7): who requested a proof or read the disclosure log is an access-logging wrapper's; the ledger surface is committed entries and committed disclosures. **A subset is always transactions** (Non-goal 8): showing an auditor the fact of a prior disclosure is a read of the accounting store, never a disclosure of an outcome event. **Custody is an enrichment** (Non-goal 9): an entry referencing a tracked artifact — a bearer instrument, a physical certificate — pairs with a [Chain of Custody](./chain-of-custody.md) chain for that artifact.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: The composition MUST read the Event Log sequence as the order of the ledger.
Clock semantics 2: The composition MUST NOT compare a payload instant with Event Log's recording instant.
```

WHY:
A ledger entry's payload instant is the composition's own reading, host-injected at its seam, one per invocation (Capability requirement 23 and 24); Event Log stamps its own recording instant at its own seam. They are two readings of two clocks, never compared (2026-08-30-r). A disclosure's records carry no reading of the composition's but the disclosure instant, which is a parameter of the accounting write and the pairing datum the probe matches by equality (Recoverable Invocation Composes 1). Every comparison of a seam's reading against a stamp — the sweep's two edges, the age of an open intent — is Recoverable Invocation's, under its clock offset allowance. The reconciliation's own two edges compare its reading with a disclosure instant, exclude and decide nothing: a young record is left to the sweep, and an aged one to the purged verdict, which the binding and not the edge establishes (Term orphan record). Selective Disclosure's not-in-future guard compares the passed instant against its own seam's reading, which is the invocation's own (Capability requirement 25), so the guard meets two equal instants and refuses no conforming call; a host that injects another reading meets the refusal at the accounting write with nothing written, and the refusal is recorded — never after the record. The seal cadence and the purge comparison run on the substrate's clock, inherited. Where ledger instants carry legal force, a Trusted Timestamping pattern (RFC 3161 — the Internet Engineering Task Force's standard for trusted time-stamping) provides the anchor, and the seal's anchored instant already bounds the breach window.

### Concurrency

```
Concurrency 1: The composition MUST NOT serialize two disclosures carrying distinct act keys.
Concurrency 2: A verification bundle MUST name the ledger seal the bundle anchors to.
```

WHY:
Distinct disclosures — even over overlapping entry sets — do not conflict: each has its own disclosure id, accounting record, outcome, binding and bundle, and the bijection is per-disclosure local. Two disclosures carrying the same subject, recipient, scope and authority share an act key and take the critical section in turn, the second hearing act-in-flight while the first is open — and where the first's invocation died, until the sweep closes it, inside the act kind's compensation window, which is the binding's cost to a caller who repeats a disclosure, as the refusal of four fields too long for one key is its cost to a caller with a long scope (Primitive policy 14); disclosures under distinct act keys never wait on one another. An entry appended between two disclosures' bundle constructions may move the seal, so two bundles over one subset can anchor to different seal points — each valid against the seal it names, and the recipient verifies against the seal reference paired with the bundle (Concurrency 2). A lawful purge can land between membership and bundle construction; the disclosure stands and the bundle marks the entry (Verdict 10).

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST NOT bound the accounting store's retention.
Retention asymmetry 2: A deployment whose accounting horizon is regulated MUST declare an accounting-horizon cover.
```

WHY:
Selective Disclosure records are never removable (its Invariant 6), so left alone the accounting store keeps forever while the outcome events purge at the ledger horizon — the mismatch Invariant 1.6 makes lawful and distinguishable. A deployment under HIPAA section 164.528's six-year accounting window or GDPR Article 30 aligns the ledger's policy to it and leaves the accounting store unbounded (Retention asymmetry 1): a record removed ahead of its outcome would leave a live outcome naming nothing, and the verdicts that read the store would answer absence for a disclosure the ledger still proves.

### Degraded bundle

```
Degraded bundle 1: IF the partial disclosure capability EQUALS false THEN [Disclose Subset] MUST record the accounting record AND the outcome event.
Degraded bundle 2: IF [Verify Disclosure] receives a degraded bundle without the whole ledger THEN EVERY presented entry MUST carry unverifiable carrying whole-ledger-required.
Degraded bundle 3: IF [Verify Disclosure] receives a degraded bundle THEN confidentiality preserved MUST carry false.
Degraded bundle 4: IF [Verify Disclosure] receives a degraded bundle THEN the overall verdict MUST carry disclosure-unverified carrying degraded-bundle.
```

WHY:
Where the mechanism cannot prove a named subset — a single whole-ledger hash with no inclusion structure — the accounting is unaffected and the binding holds, but a recipient can verify only by verifying the whole seal, which needs the whole ledger and breaks the confidentiality half. The composition does not weaken the guarantee silently: the degraded path's verdicts are pinned, and a verifier that waves a degraded bundle through as verified is non-conforming.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its actions — [Record Entry], [Disclose Subset], [Verify Disclosure], [Verify Ledger] and [Reissue Bundle]; the [Verification Bundle] and the [Confidentiality Preserved] assertion; the binding verdicts ([Bound], [Binding Duplicate], [Binding Purged], [Binding Escalated], [Binding Gap]); the authenticity verdicts ([Authentic], [Altered], [Not In Ledger]); and its own refusal, [Unknown Entry]. The binding bijection and verifiable partial disclosure are structural properties, not data. The deployment settings keep their wire spellings in configuration — `ledger_retention_policy`, `seal_cadence`, `disclosure_completion_bound`, `commit_round_trip`, `probe_round_trip`, `disclosed_entry_ids_cap`, `application_actor_ref`, `application_credential`, `index_durability`, `tamper_evidence_supports_partial_disclosure` — and the binding index its own in an implementation, `disclosure_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; the sweep; an operator; a deployment; a regulated deployment; an auditor; a caller; a discloser; a recipient; an invocation; a validated entry; a landed entry; a validated disclosure; an admitted disclosure; an accounted disclosure; a yielded disclosure; a landed disclosure; a found reissue; a found ledger verification; a bound ledger verification; a read-only action.

Term records: the ledger entries the composition records through the audit write; the intents, outcome events, refusals, recovery intents and escalations Recoverable Invocation writes for the act kind — each an Event Log event carrying one action reference below; the accounting records the composition writes through the disclosure write; and the binding index's entries.

Term record verbs: EQUAL, adjudicate, adopt, alert, answer, append, attest, bind, bound, call, carry, change, check, claim, classify, clear, compare, compensate, compose, construct, decide, declare, disclose, duplicate, examine, expose, fall, find, guarantee, inherit, inject, inspect, interpret, join, keep, key, leave, mark, match, name, normalize, open, override, pair, pass, perform, persist, pre-check, proceed, provision, re-derive, re-read, reach, read, rebuild, record, refuse, release, remove, reorder, require, resolve, rest, retry, reveal, route, run, select, serialize, serve, set, stamp, start, store, supersede, supply, suspend, take, track, validate, verify, write.

Term value sets: action reference = ledger.entry | ledger.disclosure.intended | ledger.disclosure.disclosed | ledger.disclosure.refused | ledger.disclosure.recovery_intended | ledger.disclosure.abandoned | ledger.disclosure.escalated. authenticity = authentic | altered | not-in-ledger | unverifiable. unverifiable reason = unsealed | entry-purged | bundle-malformed | whole-ledger-required. attestation verification reason = purged | payload-not-supplied | partially-purged-coverage | the substrate's own. bundle unavailable reason = entry-set-purged | the construction's own. disclosed set unverifiable reason = purged-horizon. overall verdict reason = no-entries-presented | degraded-bundle | an entry's own. The rest are declared where the section that owns each declares it: position, binding verdict, disclosure refusal.

Term bounds: disclosure completion bound (disclosure_completion_bound), commit round trip (commit_round_trip), probe round trip (probe_round_trip), disclosed entries cap (disclosed_entry_ids_cap), audit horizon (ledger_retention_policy), reconciliation run bound (reconciliation_run_bound), settling period (settling_period).

Term cadences: seal cadence (seal_cadence); the reconciliation cadence is Recoverable Invocation's.

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: accounting horizon, attestation verification, retention state, bundle construction, verification routine, degraded bundle, index-unavailable, no answer, ledger event, reconciliation run bound, whole covering range, settling period, membership check, entry-unconfirmed, store-unavailable, invocation pair, append step, write-ownership finding, finding surface, settling closing, unsettled escalation, composition, constituents, transitive atoms, ledger enumeration, record read, audit write, verification, disclosure write, disclosure read, ledger namespace, act kind, disclosure binding, act key, commit partition, disclosure probe, disclosure id, binding index, binding, ledger entry, outcome event, intent, disclosed set, live binding, purged binding, binding rebuild, ledger retention policy, audit horizon, seal cadence, disclosure completion bound, commit round trip, reconciliation cadence, probe round trip, disclosed entries cap, recovery identity, index durability, accounting store, partial disclosure capability, invocation id, seam, now, transaction data, actor reference, disclosed entry ids, subject reference, recipient, scope, authority, maximal envelope, caller string, pre-append step, retention step, invalid-request step, position, entry id, disclosure result, disclosed entries, ledger seal reference, disclosure proof, original event payloads, accountability proof, results, validated entry, landed entry, validated disclosure, admitted disclosure, invocation open, invocation close, invocation refusal, invocation yield, invocation read, sweep, intent data, outcome data, disclosure refusal, accounted disclosure, yielded disclosure, landed disclosure, disclosure instant, payload instant, found reissue, found ledger verification, bound ledger verification, covering range, read passthrough, read-only action, reconciliation, young record, aged record, orphan record, discloser, recovered outcome, escalated closing, record's invocation, binding verdict, live outcome event, passing verification, payload handling, accounting-horizon cover.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Substrate composition invocation in `execution-contract.md` — the mechanism-capability residual and the multi-instance topology. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, verify_record, payload cap, sealed through, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unverifiable, purged, partially-purged coverage, compensation-window, Retained, Purged, Erasure Tombstone: Audit Trail. reference length cap: Audit Trail. record, read, disclosure id, subject reference, recipient, scope, authority, invalid-request, unknown-authority-type, storage-failure, invalid-query: Selective Disclosure. open, close, refuse, yield, read_invocation, reconcile, resolve, critical section, completion bound, compensation window, window end, service identity, outcome envelope, pairing datum, commit fence, retry terminus, recovery, acting actor reference, intent event id, cause, act-in-flight, section-unavailable, journal-unavailable, already-accounted, clock offset allowance, call pause bound, horizon edge, quiescence, supersedes, outcome action reference, constituent code, reply, run bound, journal write bound: Recoverable Invocation. read, invalid-query: Event Log. verify, seal: Tamper Evidence.

Term composing patterns: [Consent](../atoms/consent.md); [Permissions](../atoms/permissions.md); [Defensible Retention](./defensible-retention.md); [Idempotent Reservation](./idempotent-reservation.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Chain of Custody](./chain-of-custody.md).

#### Record Entry

The composition action that appends one transaction to the ledger — a single `AuditTrail.record_action` (`ledger.entry`) producing an immutable, attributed, sealed, retained event. Returns the `entry_id` (the Audit Trail `event_id`).

Kind: Operation

#### Disclose Subset

The composition's defining action: record that a named subset of ledger entries was disclosed to a recipient under an authority, and produce the [Verification Bundle] by which the recipient can independently verify that subset. Three records in order, never atomically, under Recoverable Invocation's protocol: the intent that authenticates the discloser, then the Selective Disclosure record and the immutable `ledger.disclosure.disclosed` record — the two truth-bearing writes the binding bijection pairs (Invariant 1).

Kind: Operation

#### Verify Disclosure

The recipient-side emergent verification: given the disclosed entries, the [Verification Bundle], and the published ledger-seal reference, check each entry's authenticity ([Authentic] / [Altered] / [Not In Ledger] / unverifiable) and whether the undisclosed remainder stayed hidden ([Confidentiality Preserved]) — *without* access to the undisclosed contents. Total: always returns a `disclosure-proof`, never a rejection.

Kind: Operation

#### Verify Ledger

The accountability-side verification, run by an auditor with access to the composition's stores: given a disclosure_id, resolve whether the disclosure is bound to exactly one immutable, attributed, sealed, retained ledger event — [Bound], [Binding Duplicate] (a second writer — a finding), [Binding Purged] (lawfully destroyed at its retention end), [Binding Escalated] (the sweep could not write the outcome and said why), or [Binding Gap] (a finding). Returns an `accountability-proof`.

Kind: Operation

#### Reissue Bundle

The read-only action that re-derives the [Verification Bundle] for a committed disclosure from the seal material and the disclosed set its sealed intent records — the recovery path for a bundle whose construction failed or was lost. A disclosure whose intent is purged yields the bundle unavailable, never one built from a set no sealed record asserts.

Kind: Operation

#### Verification Bundle

The composition-introduced subset-proof artifact [Disclose Subset] produces and [Verify Disclosure] checks — an independently verifiable proof that each disclosed entry is a genuine, unaltered ledger entry covered by the seal, without exposing the undisclosed remainder. No constituent produces it (Tamper Evidence verifies whole record-sets); it is emergent here, pending a forthcoming Subset Proof atom. Realized as Merkle inclusion proofs, an accumulator witness, or a signed package — the composition requires the capability, not any form.

Kind: Type
Role: the independently-checkable subset proof

#### Confidentiality Preserved

The `disclosure-proof` field asserting that the [Verification Bundle] and disclosed entries reveal nothing about the count, content, or position of undisclosed entries beyond what the seal reference inherently publishes — the structural "the remainder stays undisclosed." Self-reported by the verification routine, its trustworthiness resting on a security review of the mechanism's zero-knowledge-of-complement construction (an externally-clearable check), not on recomputation from the records.

Kind:       Field
Field of:   the disclosure proof
Role:       the remainder-stays-hidden assertion
Projection: confidentiality_preserved

#### Bound

The [Verify Ledger] binding verdict when the disclosure resolves to exactly one live, immutable, attributed, sealed ledger event whose `data.disclosure_id` matches — the bijection holds within the retention lifetime.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: bound

#### Binding Duplicate

The [Verify Ledger] binding verdict when more than one live `ledger.disclosure.disclosed` event names the disclosure — a second writer the one-writer rule forecloses, reported with every event id rather than resolved by choosing one.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-duplicate

#### Binding Purged

The [Verify Ledger] binding verdict when no live `ledger.disclosure.disclosed` event names the disclosure but the composition's own index still binds it to an `event_id` whose `Purged` retention record attests the event's honest destruction at its retention end (Invariant 1's retention-horizon arm) — lawful and distinguishable from a gap, not a finding.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-purged

#### Binding Gap

The [Verify Ledger] binding verdict when no ledger event and no honest-destruction record name the disclosure — a recorded disclosure with no ledger event. Never a steady state under a conforming implementation (Invariant 1's liveness arm); a high-priority finding.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-gap

#### Binding Escalated

The [Verify Ledger] binding verdict when no live ledger event names the disclosure but a `ledger.disclosure.escalated` record stands as the closing of the record's invocation: the sweep found the act and could not write its outcome — more than one candidate in the store, a store that did not show the act when probed, or an outcome the substrate refuses outright — and recorded the cause. A finding with a lawful standing state, superseded by [Bound] when an operator's outcome names it.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-escalated

#### Authentic

The [Verify Disclosure] per-entry authenticity verdict: the entry is a genuine, unaltered ledger entry covered by the seal.

Kind:       Member
Member of:  the per-entry authenticity
Role:       Authenticity verdict
Projection: authentic

#### Altered

The [Verify Disclosure] per-entry authenticity verdict: the entry does not match what the seal committed to.

Kind:       Member
Member of:  the per-entry authenticity
Role:       Authenticity verdict
Projection: altered

#### Not In Ledger

The [Verify Disclosure] per-entry authenticity verdict: the [Verification Bundle] does not place the entry under the seal.

Kind:       Member
Member of:  the per-entry authenticity
Role:       Authenticity verdict
Projection: not-in-ledger

#### Unknown Entry

The [Disclose Subset] rejection when a named subset id resolves through the record read to no `ledger.entry` transaction — an unknown id, or any other event, a `ledger.disclosure.disclosed` outcome included — naming every failing id, deterministically.

Kind:       Member
Member of:  the disclose-subset rejection
Role:       Rejection
Projection: unknown-entry

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Record Entry]: #record-entry
[Disclose Subset]: #disclose-subset
[Verify Disclosure]: #verify-disclosure
[Verify Ledger]: #verify-ledger
[Reissue Bundle]: #reissue-bundle
[Verification Bundle]: #verification-bundle
[Confidentiality Preserved]: #confidentiality-preserved
[Bound]: #bound
[Binding Duplicate]: #binding-duplicate
[Binding Purged]: #binding-purged
[Binding Gap]: #binding-gap
[Binding Escalated]: #binding-escalated
[Authentic]: #authentic
[Altered]: #altered
[Not In Ledger]: #not-in-ledger
[Unknown Entry]: #unknown-entry

## Standards references

This composition is the structural form of the immutable-ledger-with-accountable-disclosure requirement across its canonical domains:

- **SEC (US Securities and Exchange Commission) Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — requires broker-dealer transaction records to be preserved in a non-rewriteable, non-erasable form and produced, in whole or as a defined subset, on demand for an examiner. The Audit Trail substrate's Tamper Evidence (Invariant 3) satisfies the non-rewriteable/non-erasable standard; [Disclose Subset] + [Verify Disclosure] (Invariant 2) is the structural form of producing a verifiable *subset* to an examiner without exposing the rest of the book; the configured `ledger_retention_policy` satisfies the six-year (first-two-years-accessible) lifetime requirement.

- **HIPAA (US Health Insurance Portability and Accountability Act) section 164.528 (Accounting of disclosures of protected health information)** — requires a covered entity to give an individual an accounting of disclosures of their PHI: date, recipient, scope, and purpose, drawn from the records alone. The Selective Disclosure store answers the accounting query (read by subject_ref); the binding bijection (Invariant 1) makes each accounted disclosure itself immutable, attributed, and tamper-evident — the property section 164.528 needs but plain disclosure accounting cannot supply alone.

- **21 CFR (US Code of Federal Regulations) Part 11 (Electronic records and electronic signatures)** — requires electronic records submitted to a regulator to be attributable, contemporaneous, original, and accurate (ALCOA), with disclosures to the agency themselves recorded. The four-atom Audit Trail stack supplies ALCOA over every ledger entry; [Disclose Subset] records each disclosure to the agency as an attributed, sealed `ledger.disclosure.disclosed` event.

- **GDPR (EU General Data Protection Regulation) Article 15 (Right of access by the data subject)** — a data subject may demand to know what data was disclosed and to which recipients. The Selective Disclosure store is the source for the recipients-and-scope answer; [Verify Disclosure] additionally lets the subject independently confirm a disclosed subset is genuine *without* the controller exposing every other subject's entries on the shared ledger (Invariant 2's confidentiality half).

- **W3C Verifiable Credentials Data Model and the selective-disclosure / BBS+ (a pairing-based signature scheme supporting selective disclosure of signed messages) proof literature** — the standards surface for cryptographically proving a *subset* of a set of claims authentic while withholding the remainder. This composition's verification_bundle and [Verify Disclosure] are the composition-layer form of this capability; the W3C (the World Wide Web Consortium) VC (Verifiable Credentials) selective-disclosure mechanisms (and accumulator / Merkle-inclusion-proof constructions) are *typical realizations* of Invariant 2's behavioral obligation, named in rationale only — this composition requires the capability, not any particular proof system, exactly as Tamper Evidence is mechanism-neutral.

This composition inherits the broader standards compliance of its constituents:

- Through **Audit Trail** (and its transitive atoms Event Log, Actor Identity, Tamper Evidence, Retention Window): SOX (Sarbanes-Oxley Act) section 802 record retention, HIPAA section 164.312(b) audit controls, PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR Part 11 electronic records, ISO/IEC (International Organization for Standardization / International Electrotechnical Commission) 27001 clause A.12.4 logging and monitoring, GDPR Articles 30 and 32, and the full Audit Trail standards inheritance. Deployments composing this composition receive these as the substrate's contribution; they are framed as inherited, not as this composition's own primary anchors.

- Through **Selective Disclosure**: GDPR Article 15(1)(c) and Article 30, HIPAA section 164.528, and SEC Rule 17a-4 at the disclosure-accounting layer. This composition lifts these to the immutable-and-independently-verifiable form those standards actually require but that Selective Disclosure alone — which records that a disclosure occurred but seals nothing — cannot satisfy.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation against the one-writer protocol of 2026-08-30; was verified — immutable-transaction-ledger.tla + 1 twin, 2026-06-10
last gate: 2026-10-08 — the fourth round on frozen text, the body at sha1 37f0620c and Recoverable Invocation's at 29b0cdb6, three passes with no cure between them — 3, 2 and 2 foundational, six distinct, five on this page and one on that one; conceptual independence returned none, the builder's reading two, one of them the first pass's as well; 31 refining and 14 rhetorical. **Not clean, and flat at the old end:** three of the six sit in the last two rounds' cures and three in older text — the older tail four, three, four, three over four rounds. Cured after the third pass: transmission keyed to the outcome event and not the call's answer, so a recovered disclosure can reach its recipient (Capability requirement 34, Term position); every read of a reconciliation run, the binding index's included (Reconciliation 29, 30); entry-unconfirmed's finality on the protocol's journal write bound, from the refusal (Term entry-unconfirmed); outcomes read against a store read the enumeration precedes, so a disclosure landing mid-run alerts nothing (Reconciliation 7, 32); equal readings of now forbidden per act key on any node, not one reading reused (Capability requirement 28). Of the pre-freeze statements, none came back foundational; three came back as stale neighbours — a WHY, a Term — of the rules they changed; 2026-10-08 — the third round on frozen text, the body at sha1 de00ddc0 and Recoverable Invocation's at f4a91352, three passes with no cure between them — 4, 5 and 4 foundational, nine distinct, eight on this page and one on that one; conceptual independence returned two this time, the builder's reading beside it three; 36 refining and 16 rhetorical. **Not clean, and not converging: 9, then 3, then 9.** Three of the nine sit in rules the two rounds before wrote — two horizons priced without the run bound or the allowance (Capability requirement 31, 33) and a wiring decision that claimed one live outcome where a purged or escalated disclosure has none, now tombstoned to Invariant 1.3. Two are hardening lines routed from this Ledger and promoted by readers who could not see them — the accounting store's own retention, now struck, and the range read's unavailable arm, now read as no answer. The rest are older: an abandonment over a record that exists, which no run reported (Reconciliation 33); a run that read the ledger ahead of the store and accused a conforming write (Reconciliation 34); a disclosure transmitted ahead of its recording (Capability requirement 34); and, on the protocol, a corroboration check failed by a store that removes its records first (its Binding 9). Before the text was frozen, eight routed lines that readers kept finding were stated in the body or cured, and none of the eight came back as foundational; 2026-10-07 — the second round on frozen text, the body at sha1 f42b7c05 and Recoverable Invocation's at 00d866ff, three passes with no cure between them — 1, 1 and 2 foundational, three distinct, one cured on this page and two on that one; conceptual independence returned zero again, the builder's reading beside it one; 47 refining and 18 rhetorical, the defects among them cured and the rest routed below. **Not clean.** 87 tombstones sampled, none failed. The three: the binding index's own read and write had no failure arm, so a purged disclosure read as a gap while the index was out (Action wiring 64 through 66, Reconciliation 31); the protocol's open named no release where its intent write was refused; the sweep's upper edge took no account of the age of a run's one reading, so a closing purged inside a run was closed again. None of the three sits in a rule written in the last two units; 2026-10-07 — the first round on frozen text, three passes with no cure between them, the body at sha1 f2448123 and Recoverable Invocation's at 63ecdaf2 — 5, 3 and 2 foundational, nine distinct, six cured on this page and three on that one; conceptual independence returned zero, the builder's reading run beside it three; 46 refining and 15 rhetorical, the defects among them cured and the rest routed below. **Not clean.** The nine: a purged entry whose attribution the substrate cannot yet show had no answer at the membership check; a ledger entry answered ahead of its retention record failed the page's own invariant; the claim that every outcome is bound before its purge rested on no bound for the run that binds it; a verification that gave no answer had no arm; a binding could neither change nor stay under a duplicate; a yield could not tell an answered commit from a lost one; an expired invocation at a refusal was obliged two codes; two refusals on one call had no order; an intent whose retention was placed late outlived its closing and failed the auditor's checks; 2026-10-07 — earlier the same day, a search and not a round: three passes over the bound pair, one each and each cured in the pass that found it: structural completeness, conceptual independence with the builder's reading beside it, and the adversarial pass — 3, 5 and 6 foundational, 14 in all, ten cured on this page and four on Recoverable Invocation; 38 refining and 12 rhetorical, 7 rejected on triage, 8 routed below and the rest cured. **Not clean, and the text as cured has been read by no pass.** 65 tombstones sampled, none failed. The fourteen: an escalation with no verdict once its intent is purged; a false write-ownership finding at the horizon; no failure arm on this page's own reads; no action that ends a binding duplicate; a step-3 failure read as not appended; an escalation nobody is shown; a ledger verification that could not count what its verdicts count; a reissue answering not-known for a purged disclosure; an outage-held invocation read as a failure; refused callers standing ahead of the sweep's take; a lease spend one pause short; a rebuild withheld by the wrong store's outage; partially-purged coverage obliged two answers and failed a check; ledger entries written under the recovery identity; 2026-08-30 — third gate, fresh reader, under the frozen rules — 5 foundational corrected in-round, 12 refining and 7 rhetorical routed (2 refining and 2 rhetorical closed in-round, the second by the closure check; 1 refining a duplicate of 2026-08-26-f; 1 further refining line on the formal model added; the closure check's 2 refining corrected in-round); 2026-08-26 — authentication-precedence gate, fresh reader — 3 foundational (all pre-existing; all since closed), 7 refining, 1 rhetorical

open:
- 2026-08-29-a · refining · formal · the model predates the binding: its compensation, its one-step outcome and its absent sweep are Recoverable Invocation's protocol now, proved in that page's model, and what is this page's own — the binding index written every run, the disclosure probe's four answers, the reading of two stores for a record no intent carries — is in no model → re-derive over those, against that page's contracts
- 2026-10-08-j · refining · the whole page, with Recoverable Invocation as a constituent · pre-registered 2026-10-08, before the treatment it governs: four rounds on frozen text left an older tail of 4, 3, 4 and 3 foundational, flat; the treatment drains every open line on both pages whose fix is in the text, kind A cured and the rest stated in the body, leaving the lines that wait on a model, an atom or a fenced deployment, and sweeps every sentence that restates a changed rule; one confirming round follows — three passes on one frozen text under round four's briefs, their line ranges moved to that text — and counts the distinct foundational findings, on either page, that survive triage and sit in a rule or Term unchanged since fda238b, the commit before round four's; three or more and `partially resolved` stands as this page's resting state, recorded here as measured non-convergence with the five counts as its reason; fewer and rounds continue toward grounding → run the round, count by this line, and record the outcome
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/immutable-transaction-ledger.md`.

- **2026-10-08 — The treatment before the confirming round: the guard given the invocation's reading, the outcome position its invocation, and the deciding count fixed in advance.** *Chose:* Selective Disclosure's seam injected with the invocation's own reading, so the not-in-future guard meets equal instants (Capability requirement 25); the invocation id carried on recording-failure carrying outcome, so a caller finds its own outcome and not a record of its key (Action wiring 68); the stopping rule in the Ledger ahead of the drain (2026-10-08-j). *Over:* one clock authority across two seams, which a read on two nodes inside the allowance still refused as the caller's fault; the accounting query by key, which an earlier disclosure of the same key can answer. *Because:* four rounds left the older tail flat at four, three, four and three, and a drain is worth running only if the round after it is counted by a rule written before it.
- **2026-10-08 — The fourth round on frozen text: a disclosure reaches its recipient once its outcome event lands.** *Chose:* Capability requirement 34 keyed to the outcome event, which the call's answer shows or [Verify Ledger] answering bound shows once the sweep has recovered the disclosure; the disclosure instant stated as the admission's, ahead of the transmission. *Over:* the call's answer alone, which strands every recovered disclosure; and Selective Disclosure's own order, transmission first, which leaves an abandoned invocation's transmitted data unaccounted with no re-run lawful. *Because:* a yielded disclosure ends recovered or abandoned, each order lost one of the two, and the outcome event is where both end.
- **2026-10-08 — The third round on frozen text: nine, eight here, and two cures by deletion.** *Chose:* Wiring decision 1 tombstoned to Invariant 1.3, which already said what was true of it; the accounting-horizon cover reduced to the ledger's own policy, the accounting store never bounded; both horizon conditions written in the strict form and priced with the run bound, the allowance and the settling period; an alert for a false closing and a fixed read order for the reconciliation; transmission only after the recording call answers. *Over:* qualifying the wiring decision's claim with every state that broke it. *Because:* the round found three defects in the two rounds' own cures, and where a rule was broken by the states the page calls lawful the rule that held them already existed.
- **2026-10-07 — The second round on frozen text: three foundational, one here.** *Chose:* a refusal of its own for an index that gave no answer, since the index alone tells a purged disclosure from a gap (Action wiring 64 through 66; Reconciliation 31); the accountability proof's contents stated per verdict; a run's alert for an outcome the accounting store does not carry (Reconciliation 32). *Over:* widening store-unavailable to mean two stores. *Because:* the round's first and third passes each reached the same unowned read from different sides, and it had sat in this Ledger as a hardening line since the round before — a routed line a cold reader cannot see is found again, and promoted.
- **2026-10-07 — The first round on frozen text: nine foundational, cured after the third pass reported.** *Chose:* a binding that only a purge makes immutable, so a rebuild may move a live one to the lower sequence (Composition state 5); a retention record owed at the substrate's quiescence and not at the append (Invariant 3.4, Check 3.3); a bound on the reconciliation run and a horizon that exceeds a cadence and two runs (Capability requirement 32, 33); one refusal per call in a fixed order, with a read that concluded nothing ahead of the verdict it would have fed (Primitive policy 19 through 21); the escalated verdict behind the purged one (Verdict 4), and Check 1.9 tombstoned to Check 1.2, which already read the same records. *Over:* a second check for the unsettled escalation, written the unit before and found to overlap the first and to fail a conforming deployment whose records were placed late. *Because:* three passes that read one text returned 5, 3 and 2, and two of the nine were in rules a day old.
- **2026-10-07 — The bound pair's first three passes: fourteen foundational findings, each cured where it was found.** *Chose:* an operator's obligation to settle every escalation before its intent's horizon edge, with a settling period charged to retention, over a second index of escalated closings (Capability requirement 29 and 31); an orphan defined against the binding as well as the outcome, so no clock decides a finding (Term orphan record); a failure arm for every read this page makes, each naming the store that gave no answer, and for [Record Entry] a code that is never retried where the entry may be in the ledger — the substrate's step-3 failure included, since that page lands it for an append that may yet land (Primitive policy 16; Audit arm 26 through 30; Action wiring 57 through 60; Reconciliation 28 through 30); a ledger verification that counts from the enumeration on every call, the index supplying only what a destroyed payload once named (Action wiring 29; Action wiring 31 and 32 tombstoned); a reissue that answers a purged disclosure as purged (Action wiring 62); the recovery identity refused as a ledger entry's actor (Primitive policy 18). *Over:* reading a failed read as empty, the index as a verdict, and an escalation as an end state. *Because:* three cold passes over this page with the protocol as its constituent returned 3, 5 and 6 — and the adversarial pass found two defects in rules the first two passes' cures had written, which is why the cured text is owed a round of its own.
- **2026-10-07 — Bound to Recoverable Invocation as its pilot adopter: validate, open, commit, close; seventy-five rules deleted to tombstones that name their new owner.** *Chose:* the act kind ledger.disclosure on one Recoverable Invocation instance writing to this composition's Audit Trail instance (Composes 12 through 15); the act keyed by subject reference, recipient, scope and authority under the minted key deviation, the accounting write partitioned as Selective Disclosure states its arms, no commit fence, the disclosure instant as the pairing datum, the accounting store's read as the probe, the recovery identity as the service identity (Term disclosure binding); [Disclose Subset] as four calls with one route for each answer of the accounting write (Action wiring 3, 6, 47 through 54); the disclosed set recorded in the intent alone, since a recovered outcome carries only what the store re-derives (Composition state 16); the unbindable marker replaced by the protocol's escalation, read as binding-escalated through the protocol's own read (Verdict 4, 15); a reconciliation reduced to the binding rebuild and the reading of the accounting store for a record no intent carries (Reconciliation 1 through 4, 6, 7, 14, 27). *Over:* this page's own intent, outcome, per-disclosure exclusion, counted retry, rejection arms and compensating scan — the protocol other compositions also carry in their own words. *Because:* the roadmap names this page the pilot, with the deletion measured here before any other page is swept. Measured: 241 live rules to 190 — 75 deleted, 24 added — and the rules' own text 22% smaller; the page 3.8% larger, since every deleted rule leaves a tombstone and the binding is new prose; which is the roadmap's own reading, that owners fall where bytes may not. Four deleted rules said other than their new owner does, and the owner stands: a host freed the exclusion on a holder's death, where the protocol's model rejects that host (Recoverable Invocation act section 2); an invocation whose lease expired took the exclusion again, where it now never does (Recoverable Invocation act section 10); a refused accounting write left its intent standing with nothing after it, where a refusal record now closes it (Recoverable Invocation commit 2); and an intent appended behind a step-4 refusal was left standing, where it is now read back and the disclosure proceeds (Recoverable Invocation Primitive policy 20). One claim narrowed: no disclosure id under two live outcomes holds at quiescence, as far as the protocol's one-writer invariant reaches without a journal fence (Invariant 1.3). No pass has read the bound text; the page stays `partially resolved`.
- **2026-09-24 — Rewritten in GRACE lang v0.61; twenty-three of twenty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-disclosure section renamed the disclosure exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the binding and authenticity verdicts as their own `Verdict` family; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: *produced by this composition* defined as *paired by the reconciliation's predicate*, with the ledger namespace and the disclosure write reserved to the composition and an unpaired record a write-ownership finding (2026-08-26-e, 2026-08-30-g); a declared [Reissue Bundle] rather than a dropped claim (2026-08-30-f — *as simple as possible without losing fidelity*: the prose leaned on a recovery path no surface declared); an entry unsealed or purged at bundle construction marked in the bundle per entry rather than refused (2026-08-26-i, 2026-08-30-d, -e — *make all things mean one thing*: the purge-between-check-and-bundle race already answered this way); blank refused with Selective Disclosure's own rule at step one (2026-08-30-c); binding-duplicate named as a fifth verdict (2026-08-30-a); and the constituent bars cited rather than counted (2026-08-26-f). *Over:* the prose's step lists, a lettered case list that skipped a letter, and a recovery path the page promised and the surface lacked. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.
- **2026-08-30 — One writer per disclosure, the purged answer first, the outcome sized before the intent, the clock at the composition's seam, the position on the code.** *Chose:* [Disclose Subset] step 4 pre-checks under the per-disclosure_id section the scan also takes and adopts an existing `ledger.disclosed` as its own outcome, with an in-invocation retry counted by `outcome_retry_attempts` and the scan the only writer thereafter; the scan runs `disclosure_to_event`'s full rebuild as a write every cycle, under a declared `reconciliation_cadence` and the inequality `disclosure_completion_bound + reconciliation_cadence + outcome_write_latency <` the shortest retention period, so the index's purged half is captured before any purge can reach its event and a lost entry is honestly a loss; step 1 sizes the maximal outcome-and-compensation envelope against `payload_cap` before the intent, with `disclosed_entry_ids_cap` and `intent_candidates_cap` bounding the two set-valued fields; now declared host-injected at this composition's seam, one reading per invocation, with the pass-through to Selective Disclosure making the pairing equality by construction and the constituent's not-in-future guard named as the one cross-seam comparison; `recording-failure(intent | outcome)` on the [Disclose Subset] signature; [Verify Ledger] branching on retention state at its index hit and on coverage status at its presentation before any composition-side membership check; and — from the closure check — the per-disclosure_id section declared as the `disclosure_section` instance capability with lease semantics (taken at step 3's return, released on return or death, a lease exactly `disclosure_completion_bound` long whose expiry is the invocation's terminus, re-taken before any pre-check and never permitting an append past the bound), the bound restated seam-to-step-4, an adopted `entry_set_unresolved` event yielding `verification_bundle = unavailable(entry-set-unresolved)`, and every remaining "atomically" replaced by the ordered three-write sequence the protocol actually runs. *Over:* a bare append at step 4 beside a scan that starts at the bound; a truth-bearing half written only by a step an invocation may never reach; "foreclosed by construction" argued about the intent while the outcome and the compensation grow without a cap; a clock attributed to a substrate that exposes none; two dispositions on one token at the caller boundary; a payload-not-supplied verdict for a payload the substrate destroyed; a critical section attributed to the host in no Configuration entry, with no release or expiry bound; and a page that said *atomically* about a sequence its own edge case calls irreversible-then-compensated. *Because:* two compensators over one act land two outcomes the seal then protects; a truth-bearing index that presumes the fact was captured is a finding-generator against a durability obligation nobody breached; an unbounded set is an input, not a construction; a reading mislocated to a constituent mislocates every stamp the composition writes; a caller who cannot tell intent from outcome re-runs a committed disclosure; lawful destruction is not omission; a section nobody declared has no lease, and a lease no bound governs blocks the leg forever; and a bundle over a set no sealed record determines proves a set the composition never recorded (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*A derived index splits at the horizon*'s truth-bearing half).
- **2026-08-29 — The scan is bounded and writes as the composition, the substrate's step decides the landing, and the seal is verified over its range.** *Chose:* a declared `disclosure_completion_bound` below which the orphan enumeration examines nothing, with the ledger horizon as its upper edge; every scan write attested under a declared recovery identity behind a `ledger.recovery_intended` record, the orphan paired to its intent by the reading step 3 now passes explicitly as `disclosed_at` (candidates named where undecidable, and an undetermined entry set omitted rather than asserted); a seam-injected invocation_id on every event payload so an indeterminate substrate arm is read back exactly; every transcription carrying `recording-failure(step)`, with step-4 and `invalid-request(step-4)` proceeding as landed at both actions; and [Verify Ledger]'s presentation keyed by `sequence_number` over the covering range `read_record` names. *Over:* an unbounded scan under an undeclared identity, a bare token that sent [Record Entry]'s caller back to append a second entry, and a one-payload presentation that returns a mismatch on every intact ledger under interval cadence. *Because:* an unbounded scan compensates in-flight disclosures beside their own outcome events and re-manufactures lawfully purged ones; a compensation the discloser did not make cannot be attested as theirs; the substrate's step-4 arm means the event exists; and a seal commits to a range (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A seal presentation is keyed by log position*).
- **2026-08-27 — The purged binding's key lives in the composition, and the unbindable orphan gets a terminal verdict.** *Chose:* `disclosure_to_event`'s purged half is truth-bearing under a durability obligation (extraction-pending against the Erasure Tombstone atom), and a deterministic invalid-request on the outcome write lands as a `ledger.disclosure_unbindable` marker read back as `binding-unbindable`. *Over:* configuring the substrate to carry `data.disclosure_id` on its destruction record, and retrying the unbindable orphan indefinitely under the recovery identity. *Because:* the substrate declares its destruction record carries no payload field, so the earlier obligation pinned a capability on a surface that disclaims it; and re-attestation changes only the credential, so an orphan the payload or policy refuses had no lawful terminal state until one was declared.
- **2026-06-10 — Invariant 1 is safety plus liveness, and the model checks the compensated arm.** *Chose:* state the disclosure-accountability binding as "no unsurfaced orphan" (safety) and "every orphan is eventually bound or surfaced" (liveness), and re-derive the model over the two truth-bearing sub-writes so the reachable orphan is in scope. *Over:* the original model's idealization, which committed the sub-writes as one atomic action. *Because:* Selective Disclosure writes first and irreversibly and no synchronous rollback exists, so the orphan is reachable by design and an invariant that assumed it away verified nothing.

NOTE: End of Immutable Transaction Ledger with Selective Disclosure.

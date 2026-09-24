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

Immutable Transaction Ledger with Selective Disclosure is a regulated composition (a spec that wires two or more atoms — freestanding, self-contained pattern specs — together) that solves a problem no single atom solves alone: keeping a tamper-evident, attributed, append-only ledger of transactions *and* being able to hand a regulator, counterparty, or data subject a verifiable slice of it — proving that slice is genuine and was part of the ledger, recording that the disclosure happened and under what authority, and revealing nothing about the rest. It wires two constituents: the Audit Trail substrate (the immutable, attributed, tamper-evident, retention-governed ledger, assembled from Event Log, Actor Identity, Tamper Evidence, and Retention Window) and Selective Disclosure (the durable, append-only accounting of every disclosure — recipient, scope, authority, time).

The composition's two defining emergent guarantees are **disclosure-accountability binding bijection** — every [Disclose Subset] writes exactly one Selective Disclosure record *and* exactly one Audit Trail ledger event recording that the disclosure happened — preceded by an intent event that records the attempt and is where the discloser's credential is checked — three writes in a fixed order, intent then accounting record then outcome, never atomic, with any partial failure surfaced and compensated until the pair is restored — so the act of disclosing is itself an immutable, attributed, sealed ledger entry and no disclosure ever lacks its ledger proof silently or permanently — and **verifiable partial disclosure** — any disclosed subset can be independently verified by its recipient as authentic and derived from the ledger, while the undisclosed remainder stays undisclosed and its integrity uncompromised. The first is a structural binding between the two stores; the second is a behavioral obligation on the ledger's tamper-evidence, realized (not defined) by mechanisms such as Merkle inclusion proofs (a path of sibling hashes from one entry to a hash tree's root), cryptographic accumulators (a constant-size commitment with a per-member witness), or signed disclosure packages.

This composition's most common uses are broker-dealer transaction records under SEC (the US Securities and Exchange Commission) Rule 17a-4, accounting-of-disclosures under HIPAA (the US Health Insurance Portability and Accountability Act) §164.528, regulatory submissions under 21 CFR (the US Code of Federal Regulations) Part 11, and data-subject disclosure accounting under GDPR (the EU General Data Protection Regulation) Article 15. Any system that must keep an immutable, attributed ledger and prove a *subset* of it to an outside party — without exposing the rest and without being able to deny that the disclosure occurred — is a candidate for this composition.

---

## Intent

Every domain that keeps a record of consequential transactions faces the same paired requirement. First, the record must be a **trustworthy ledger**: append-only and totally ordered (no entry inserted out of sequence or quietly back-dated), attributed (every entry tied to a verified actor), tamper-evident (any after-the-fact rewrite detectable from the records alone), and retention-governed (kept for its regulatory lifetime, lawfully destroyable with a defensible record). Second, the record must be **selectively shareable with accountability**: a regulator, counterparty, auditor, or data subject is shown a *subset* of the ledger — a single trade, one patient's billing disclosures, the records pertaining to one matter — and that act of sharing must itself be recorded (to whom, what scope, under what authority, when), while the disclosed subset can be independently verified as genuine and the undisclosed remainder is neither revealed nor weakened.

No single atom satisfies both. The Audit Trail substrate supplies the first: it is the immutable, attributed, tamper-evident, retention-governed ledger, assembled from Event Log (append-only total order), Actor Identity (attribution), Tamper Evidence (sealing), and Retention Window (lifetime). Selective Disclosure supplies the accountability half of the second: a durable, append-only record of every disclosure — recipient, scope, authority, timestamp. But neither provides the full surface until they are wired together. Audit Trail does not know what a *disclosure* is or that disclosing a subset of its own events is itself an auditable event. Selective Disclosure does not perform disclosures, does not seal anything, and — by its own Invariant 5 (no-disclosure-unrecorded) — cannot enforce from inside that every disclosure was in fact recorded; it names that as an integration obligation for a composing pattern to close. The wiring is this composition.

The cross-domain structural identity is the composition's thesis. Under SEC Rule 17a-4 a broker-dealer must keep transaction records in a non-rewritable, non-erasable form and produce them, or a defined subset, on demand for an examiner. Under HIPAA §164.528 a covered entity must give an individual an accounting of disclosures of their protected health information — what was disclosed, to whom, when, and why — drawn from its records alone. Under 21 CFR Part 11 an electronic record submitted to a regulator must be attributable, contemporaneous, and tamper-evident, with disclosures to the agency themselves recorded. Under GDPR Article 15 a data subject may demand to know what data was disclosed and to which recipients. The structural form is identical across all four: one immutable attributed ledger, and an accountable, independently verifiable mechanism for disclosing a subset of it. One grounded composition satisfies all four.

This is a composition, not a new primitive. The Audit Trail substrate (with its constituent atoms Event Log, Actor Identity, Retention Window, and Tamper Evidence, reached transitively) and Selective Disclosure are unchanged. The composition is the wiring that makes them coherent as a single immutable-ledger-with-accountable-disclosure surface. It introduces emergent actions — [Record Entry], [Disclose Subset], [Verify Disclosure], [Verify Ledger], and a read passthrough — that belong to no single constituent and exist only because the two are wired together. [Disclose Subset] in particular belongs to neither: Selective Disclosure records *that* a disclosure happened but does not seal a verifiable subset of a ledger; Audit Trail seals events but does not know a disclosure is occurring or that it must be accounted. The composition is the layer that answers: *was this subset genuinely part of the ledger, was its disclosure recorded and authorized, and did showing it compromise nothing else?*

What the composition is *not*: it is not a redaction or transmission engine (Selective Disclosure's boundary holds — the composition records and proves disclosure; it does not fetch, redact, or route the underlying payloads); it is not the authorization layer that decides *whether* a disclosure is permitted (that is Consent / Permissions, named as a composing peer); it is not the legal-hold suspension layer over the ledger's retention (Legal Hold / Defensible Retention); it is not an at-most-once append guarantee under retry (Idempotent Reservation / Duplicate Prevention, named as an optional enrichment); and it is not the clock-authority layer (inherited from Audit Trail). Each is named explicitly in Non-goals.

---

## Composes

- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate that *is* the immutable transaction ledger: every entry, every disclosure intent and every disclosure outcome is an attributed, sealed, retention-governed Audit Trail event.
- **[Selective Disclosure](../atoms/selective-disclosure.md)** — the disclosure-accountability surface: the durable, append-only record of every disclosure — recipient, scope, authority, instant.

```
Composes 1: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 2: EXACTLY ONE Selective Disclosure instance MUST serve the composition.
Composes 3: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 4: The composition MUST NOT compose an instance of a transitive atom.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST select the ledger events through the ledger enumeration.
Composes 8: The composition MUST read an event by id ONLY through the record read.
Composes 9: The composition MUST record two audit writes PER disclosure.
Composes 10: A deployment MUST NOT record an event under the ledger namespace outside the composition.
Composes 11: A deployment MUST NOT call the disclosure write outside the composition.
```

Term composition: this pattern's wiring of [Audit Trail](./audit-trail.md) and [Selective Disclosure](../atoms/selective-disclosure.md) — the entry, the disclosure, the two verifications, the reissue, the binding index and the reconciliation.

Term constituents: [Audit Trail](./audit-trail.md), [Selective Disclosure](../atoms/selective-disclosure.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Tamper Evidence](../atoms/tamper-evidence.md) and [Retention Window](../atoms/retention-window.md), reached through Audit Trail.

Term ledger enumeration: Event Log's read by sequence-number range, from one with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

Term disclosure write: Selective Disclosure's record.

Term disclosure read: Selective Disclosure's read.

Term ledger namespace: the action references ledger.entry, ledger.disclose_intended, ledger.disclosed, ledger.recovery_intended and ledger.disclosure_unbindable on the composition's Audit Trail instance.

WHY:
**Audit Trail is the ledger.** A transaction entry *is* an Audit Trail event: append-only and totally ordered by Event Log, attributed by Actor Identity, sealed by Tamper Evidence at the cadence, placed under retention by Retention Window — all four reached through the substrate and never instanced here (Composes 3 and 4; the section titled Compositions of compositions in `spec-format.md`). **A disclosure records twice** (Composes 9): an intent before the accounting write and an outcome after it, a real addition to ledger volume and retention footprint, stated where the wiring is introduced.

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
Composition state 5: The composition MUST NOT change a binding.
Composition state 6: The composition MUST classify a live binding as a derived index.
Composition state 7: The composition MUST rebuild the live bindings PER the binding rebuild.
Composition state 8: The composition MUST classify a purged binding as extraction-pending against Erasure Tombstone.
Composition state 9: A rebuild MUST NOT remove a purged binding.
Composition state 10: The deployment MUST persist the binding index PER the index durability.
Composition state 11: An outcome event's disclosed entry ids MUST NOT EQUAL blank.
Composition state 12: The count of ledger entries one outcome event names MUST NOT EXCEED the disclosed entries cap.
Composition state 13: An outcome event MUST NOT name an event outside the ledger entries.
Composition state 14: The composition MUST NOT store a ledger entry outside Audit Trail.
Composition state 15: The composition MUST NOT duplicate a constituent's store.
```

Term disclosure id: the opaque id Selective Disclosure mints for a disclosure record.

Term binding index: the composition's map from a disclosure id to the outcome event that recorded the disclosure in the ledger — `disclosure_to_event` in an implementation.

Term binding: one disclosure id with its outcome event id.

Term ledger entry: a ledger.entry event — a transaction.

Term outcome event: a ledger.disclosed event — carrying the disclosure id and the disclosed entry ids.

Term live binding: a binding whose outcome event's payload the audit horizon has not reached.

Term purged binding: a binding whose outcome event's payload the audit horizon has destroyed.

Term binding rebuild: the ledger enumeration kept to the outcome events, each recorded as its payload's disclosure id against its event id.

WHY:
**The binding fact lives in the substrate** — every outcome event carries the disclosure id — so a live binding carries no truth of its own: read-path acceleration, outside the two truth-bearing writes (the accounting record and the outcome event), its population evidence that they committed and its loss a rebuild trigger, with no consistency claim; the authoritative check is always the substrate read (the section titled Composition state in `execution-contract.md`).

**The classification splits at the horizon, and the purged half is truth-bearing** (Composition state 8 through 10; the section titled *A derived index splits at the horizon* in `pressure-testing.md`). A lawful purge destroys the outcome event's payload whole, the disclosure id with it, and the substrate's destruction record keeps the event id and the attestation id and declares it carries no payload field — so past the horizon the key survives in no constituent, only here. That half is extraction-pending against Erasure Tombstone *(forthcoming)*, and until it lands the obligation is the deployment's: the index store as durable as the accounting store whose records it keys. **The fact was captured before it was presumed**: the reconciliation runs the full rebuild as a write every cycle, and the cadence inequality keeps every cycle shorter than the shortest retention period, so an event lives through at least one rebuild before any purge can reach it (Capability requirement 11) — a never-written entry is foreclosed, and a missing one past the horizon is honestly a loss. A rebuild never touches a purged binding (Composition state 9): it repopulates the live half and leaves the rest standing.

**The disclosure-to-entry relation, declared** (Composition state 11 through 13; 2026-08-30-j). Each outcome event names one or more ledger entries, at most the cap, and only ledger entries — never another outcome event — so the relation is acyclic by construction: a disclosure discloses transactions, and the fact of a prior disclosure is shown by reading the accounting store, never by disclosing a disclosure event. The ledger keeps no entry store of its own (Composition state 14): an entry *is* an Audit Trail event id, and the substrate is the membership oracle.

### Capability requirement

```
Capability requirement 1: A deployment MUST set the ledger retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: A regulated deployment MUST set a ledger retention policy encoding the regime's minimum retention.
Capability requirement 4: A deployment MUST set the seal cadence on the Audit Trail instance.
Capability requirement 5: The composition MUST NOT override the seal cadence.
Capability requirement 6: A deployment MUST set the disclosure completion bound.
Capability requirement 7: A deployment MUST set the outcome retry attempts.
Capability requirement 8: A deployment MUST set the reconciliation cadence.
Capability requirement 9: A deployment MUST disclose the outcome write latency.
Capability requirement 10: A deployment MUST set the disclosed entries cap AND the intent candidates cap.
Capability requirement 11: The composition MUST start ONLY IF the shortest retention period EXCEEDS the liveness sum.
Capability requirement 12: The host MUST supply the disclosure exclusion keyed by disclosure id.
Capability requirement 13: The host MUST release the disclosure exclusion on the holder's return.
Capability requirement 14: The host MUST release the disclosure exclusion on the holder's death.
Capability requirement 15: IF the host holds the disclosure exclusion as a lease THEN the host MUST set the lease length to the disclosure completion bound.
Capability requirement 16: The composition MUST read a lease's expiry as the holder's terminus.
Capability requirement 17: IF the host supplies no disclosure exclusion THEN [Disclose Subset] MUST NOT run.
Capability requirement 18: A deployment MUST provision the recovery identity.
Capability requirement 19: A deployment MUST declare the index durability.
Capability requirement 20: The index durability MUST NOT fall below the accounting store's durability.
Capability requirement 21: A deployment MUST declare the partial disclosure capability.
Capability requirement 22: The wired Audit Trail instance MUST expose the ledger enumeration.
Capability requirement 23: The host MUST inject now AND the invocation id at the seam once per invocation.
Capability requirement 24: The composition MUST stamp EVERY instant one invocation writes from the invocation's now.
Capability requirement 25: The host MUST inject now into Selective Disclosure's seam from the composition's clock authority.
Capability requirement 26: The host MUST inject the reconciliation's now AND invocation id at the reconciliation's own seam.
```

Term ledger retention policy: the policy reference configured on the composition's single Audit Trail instance, governing every ledger event — `ledger_retention_policy`.

Term audit horizon: the ledger retention policy's horizon.

Term shortest retention period: the shortest period the ledger retention policy can assign.

Term seal cadence: Audit Trail's per-event | interval-based | on-demand setting.

Term disclosure completion bound: the longest a [Disclose Subset] may run from its seam reading to its outcome, retries included — the reconciliation's lower edge, the lease length and the invocation's timed terminus.

Term outcome retry attempts: how many times an invocation re-attempts a refused outcome before it yields the orphan — the counted terminus.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every restart.

Term outcome write latency: the deployment's disclosed bound on one audit write landing.

Term liveness sum: `disclosure completion bound + reconciliation cadence + outcome write latency`.

Term disclosed entries cap: the most entries one disclosure may name — `disclosed_entry_ids_cap`.

Term intent candidates cap: the most intent candidates one compensating event may name.

Term disclosure exclusion: the host-supplied mutual exclusion on a disclosure id under which an invocation runs from the accounting write's answer through its outcome, and the reconciliation runs every write for the record — `disclosure_section` in configuration.

Term recovery identity: the composition's registered actor reference and credential — `application_actor_ref` and `application_credential` — under which the reconciliation attests every write it makes.

Term index durability: the durability the deployment owes the binding index, stated as an ordering against the accounting store's.

Term accounting store: the Selective Disclosure store.

Term partial disclosure capability: the deployment's declared boolean that the Tamper Evidence mechanism inside the substrate can produce, for a named subset, a verification artifact an independent party checks against the ledger seal without the undisclosed entries — `tamper_evidence_supports_partial_disclosure`.

Term invocation id: the fresh id the host injects at the seam per state-changing invocation or reconciliation run, carried by every event the composition writes.

Term seam: the composition's input and output boundary — the one place the host reads the clock and mints the invocation id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**Retention and cadence are the substrate's** (Capability requirement 1 through 5): SEC (the US Securities and Exchange Commission) Rule 17a-4's six-year floor, the first two years accessible; HIPAA (the US Health Insurance Portability and Accountability Act) §164.528's six-year accounting window. For a ledger whose subsets will be disclosed, per-event or tight interval cadence is recommended, because **an unsealed entry cannot yet anchor a partial-disclosure proof**: the unsealed tail is the window in which a freshly appended entry is not independently verifiable, and a bundle marks such an entry unverifiable rather than proving it (Verdict 9; 2026-08-30-e).

**The bound, the count and the exclusion are one terminus** (Capability requirement 6, 7 and 12 through 17; the section titled *A compensator is exclusive* in `pressure-testing.md`). The bound runs from the invocation's seam reading — passed through as the accounting record's instant — to its outcome, retries included; it is the reconciliation's lower edge, since a younger record may belong to an invocation still between its writes. The invocation cannot time itself, so its retries are counted; its timed terminus is the lease's expiry at the bound, whichever comes first. The exclusion spans calls of two constituents — a ledger read and a ledger write, beside a reconciliation reading the accounting store — and neither declares one, so it is the host's, named here (the section titled *Capability provenance* in `pressure-testing.md`). **No write after the accounting write is made except under it**, and a deployment that cannot supply it cannot run [Disclose Subset] conformingly: there is no degraded mode, because the one-writer rule is what the bijection's *exactly one* rests on. A bound shorter than a conforming invocation is not unsafe in the direction that writes — the invocation adopts the reconciliation's event rather than appending beside it — but it costs attribution: the record is then bound under the recovery identity.

**The horizon inequality** (Capability requirement 8, 9 and 11; the section titled *Liveness is arithmetic* in `pressure-testing.md`). Every outcome event lives at least one full reconciliation cycle before any purge can reach it, which is what makes the every-cycle rebuild a guarantee that the purged half was captured, and makes an orphan bindable before its own intent event purges. An orphan created at *t* is surfaced by `t + bound + cadence` and bound a latency after. *Cadence no longer than the horizon* is satisfied by a deployment that breaches on every orphan; the strict inequality is checked at start.

**The two caps size the largest record, not the intent** (Capability requirement 10; the section titled *An outcome is sized before the intent* in `pressure-testing.md`): *non-empty* is a lower bound, and a caller can reach any upper bound the configuration does not state; the outcome's set and the compensation's candidates are both bounded so step one's sizing of the maximal envelope is true.

**The recovery identity** (Capability requirement 18) attests every reconciliation write — the recovery intent, the compensating outcome and the unbindable marker — because the discloser's credential is not in hand; the discloser rides in the compensating event's sealed payload as the discloser, never as its attester. **The index durability** (Capability requirement 19 and 20) is owed against *loss*, not capture: capture is the every-cycle rebuild, so a binding the auditor finds missing for a purged event was written and lost.

**The partial disclosure capability is a behavioural obligation, never a mechanism** (Capability requirement 21). No Tamper Evidence or Audit Trail action produces or checks a subset proof — the atom verifies whole record sets — so the surface consuming it, the verification bundle and [Verify Disclosure], is composition-introduced (Degraded bundle 1 for its absence). Realizations include Merkle inclusion proofs (a path of sibling hashes from one leaf to a hash tree's root) and cryptographic accumulators (a constant-size commitment with a membership witness per element); the composition requires the capability and names none.

**One clock authority** (Capability requirement 23 through 26; Execution Contract Logic confinement 7). The invocation's one reading stamps its intent's payload instant, is passed to Selective Disclosure as the accounting record's instant, and stamps the outcome — equality by construction, which is what lets the reconciliation pair a record to its intent exactly. Selective Disclosure's not-in-future guard compares the passed instant against its own seam's reading, so both seams are injected from one authority; the reconciliation's reading comes from the same authority at its own seam.

### Primitive policy

```
Primitive policy 1: IF the transaction data EQUALS blank THEN [Record Entry] MUST answer invalid-request.
Primitive policy 2: IF the actor reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 3: IF the disclosed entry ids EQUALS blank THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 4: IF the count of disclosed entry ids EXCEEDS the disclosed entries cap THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 5: IF the subject reference, the recipient OR the scope EQUALS blank THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 6: IF a disclosed entry id names no ledger entry through the record read THEN [Disclose Subset] MUST answer unknown-entry naming EVERY such id.
Primitive policy 7: IF the maximal envelope EXCEEDS Audit Trail's payload cap THEN [Disclose Subset] MUST answer invalid-request.
Primitive policy 8: An action refused under Primitive policy 1 through 7 MUST NOT write.
Primitive policy 9: [Disclose Subset] MUST NOT record the intent BEFORE Primitive policy 1 through 7 pass.
Primitive policy 10: The composition MUST compare an event id, a disclosure id AND an invocation id byte-exact.
Primitive policy 11: The composition MUST NOT normalize a caller string.
Primitive policy 12: The composition MUST NOT inspect a credential.
Primitive policy 13: The composition MUST NOT interpret the transaction data.
```

Term transaction data: the opaque payload of a ledger entry, schema the host's.

Term actor reference: the acting party of a ledger write or a disclosure — actor_ref.

Term disclosed entry ids: the set of ledger entry ids a disclosure names — the machine-checkable subset.

Term subject reference: the opaque reference to the subject a disclosed subset pertains to — asserted by the discloser.

Term recipient: the party receiving a disclosure.

Term scope: the human- and regulator-facing descriptor of what was disclosed.

Term authority: Selective Disclosure's structured authority — a type of consent, legal-hold or regulatory, with a reference.

Term maximal envelope: the largest outcome or compensating event the disclosure could write — the outcome payload with the disclosed entry ids and every field at its minted width, plus the compensation's discloser, recovery flag, unresolved-set marker and intent candidates at the cap — serialized as the substrate sizes it.

Term caller string: a subject reference, a recipient, a scope, an authority reference or an actor reference.

WHY:
**Blank is refused with the constituent's own rule, before the intent** (Primitive policy 1 through 5; 2026-08-30-c). Selective Disclosure refuses a blank subject, recipient, scope or authority — whitespace-only included — so a composition that accepted whitespace would reach the constituent's refusal *after* its intent had landed. The prose's *whitespace-only accepted* is withdrawn; the grammar's blank is one reading for both layers.

**Membership reads the substrate** (Primitive policy 6; 2026-08-30-s). Every disclosed id resolves through the record read to a ledger entry — a transaction, never an outcome event and never an unknown id — and the refusal names *every* failing id, since a set has no first element. The composition keeps no entry store; the substrate is the oracle. An entry the substrate reports purged still resolves to a ledger entry by its surviving attestation, and is disclosed with its proof marked unverifiable in the bundle rather than refused (Verdict 10; 2026-08-30-d), the same answer a purge landing between the check and the bundle gives.

**Size the largest record, not the intent** (Primitive policy 7). The intent is a strict subset of the maximal envelope — the outcome adds the intent's id, the disclosure id and the instant, and a compensation adds more — so what passes here passes at the intent, at the outcome and on the reconciliation's compensating write alike; sizing the intent alone would let a set through that the outcome cannot land, over an accounting record that cannot be rolled back.

**Opaque and byte-exact** (Primitive policy 10 through 13): nothing is case-folded, trimmed or normalized; the bijection's predicate — the outcome's disclosure id against the accounting store — compares bytes. The authority is recorded and made auditable, never validated (Non-goal 1).

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent THEN [Disclose Subset] MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers invalid-request at an intent THEN [Disclose Subset] MUST answer invalid-request.
Audit arm 3: IF Audit Trail answers recording-failure at an intent THEN [Disclose Subset] MUST answer recording-failure carrying intent.
Audit arm 4: The composition MUST NOT retry an invalid-request answer.
Audit arm 5: IF Audit Trail answers recording-failure carrying the retention step at an outcome THEN the invocation MUST read the outcome back.
Audit arm 6: IF Audit Trail answers invalid-request at an outcome THEN the invocation MUST read the outcome back.
Audit arm 7: An outcome read-back MUST match the outcome event carrying the disclosure id.
Audit arm 8: IF the read-back finds the outcome THEN the invocation MUST proceed as landed.
Audit arm 9: The deployment MUST alert on an outcome read back as landed.
Audit arm 10: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome THEN the invocation MUST retry the outcome under the disclosure exclusion.
Audit arm 11: An invocation's retries of one outcome MUST NOT EXCEED the outcome retry attempts.
Audit arm 12: IF no outcome lands THEN [Disclose Subset] MUST answer recording-failure carrying outcome.
Audit arm 13: IF Audit Trail answers invalid-credential at an outcome THEN [Disclose Subset] MUST answer recording-failure carrying outcome.
Audit arm 14: IF Audit Trail answers recording-failure carrying the retention step at a ledger entry THEN [Record Entry] MUST read the entry back.
Audit arm 15: IF Audit Trail answers invalid-request at a ledger entry THEN [Record Entry] MUST read the entry back.
Audit arm 16: An entry read-back MUST match the ledger entry carrying the invocation id.
Audit arm 17: IF the entry read-back finds the entry THEN [Record Entry] MUST answer the entry id.
Audit arm 18: IF the entry read-back finds no entry THEN [Record Entry] MUST answer invalid-request.
Audit arm 19: IF Audit Trail answers recording-failure carrying a pre-append step at a ledger entry THEN [Record Entry] MUST answer recording-failure.
Audit arm 20: IF Audit Trail answers invalid-credential at a ledger entry THEN [Record Entry] MUST answer invalid-credential.
Audit arm 21: A read-back MUST read the ledger enumeration from sequence one.
Audit arm 22: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 23: A caller MUST read recording-failure carrying outcome as a committed disclosure record.
```

Term intent: the ledger.disclose_intended event — [Disclose Subset]'s record before its accounting write, carrying the invocation's parameters and no constituent-minted id.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested.

Term position: intent | outcome — where a recording-failure sat: intent, nothing truth-bearing committed and the whole action may be retried; outcome, the accounting record committed and its ledger event is owed.

WHY:
**Mapped by position relative to the truth-bearing write, and by step** (the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). The substrate attests at its step 2, appends at step 3 and places retention at step 4: a pre-append step means the event is not in the log, the retention step means it is, and a retry from here would append a second one. Its invalid-request has the same two faces by another route — its retention-configuration faults arrive with the event appended, its cap source with nothing — so the read-back decides, never the token.

**At the intent nothing truth-bearing has committed** (Audit arm 1 through 4): invalid-credential is the caller's, refused with nothing in either store; invalid-request a deployment fault, never retried, its retention source leaving the intent standing with no outcome — residue Check 5.4 triages; a recording-failure the one retryable arm. **At the outcome the accounting record is immutable** (Audit arm 5 through 13): no arm can refuse the act, only report it; the retention step and the retention-source invalid-request are found by the read-back and proceed as landed, keyed on the disclosure id — which the reconciliation's compensating event carries too, so the read-back finds either writer's event. invalid-credential there survives only as a mid-flight revocation or expiry, since the same credential validated moments earlier at the intent.

**[Record Entry] has one write, and it is the load-bearing one** (Audit arm 14 through 20). Its retention step and retention-source invalid-request mean the entry *is* in the ledger, and a refusal would send the caller back to append it again — [Record Entry] is not idempotent — so both read back by the invocation id and answer the entry id with an alert. Its single token has one position, so it exports the bare token lawfully.

**The position rides the exported code** (Audit arm 22 and 23; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent means retry the whole action; outcome means the disclosure record exists and its ledger event is the reconciliation's to land, and re-invoking would create a second disclosure record.

### Action wiring

```
record_entry(transaction_data, actor_ref, credential)
  answers entry id
  refuses invalid-credential | invalid-request | recording-failure

disclose_subset(disclosed_entry_ids, subject_ref, recipient, scope, authority, actor_ref, credential)
  answers disclosure result
  refuses invalid-credential | invalid-request | unknown-entry | unknown-authority-type | recording-failure(position)

verify_disclosure(disclosed_entries, verification_bundle, ledger_seal_reference)
  answers disclosure proof

verify_ledger(disclosure_id, original_event_payloads)
  answers accountability proof
  refuses not-known

reissue_bundle(disclosure_id)
  answers verification bundle
  refuses not-known

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

Term accountability proof: the disclosure id, the outcome event id, the binding verdict, the attestation verification and the retention state.

Term results: what the routed constituent read answers.

```
Action wiring 1: A validated entry MUST record the ledger entry carrying the invocation id, the transaction data AND now as the payload instant under the actor's credential.
Action wiring 2: A landed entry MUST answer the entry id.
Action wiring 3: A validated disclosure MUST record the intent carrying the invocation id, the disclosed entry ids, the subject reference, the recipient, the scope, the authority AND now as the payload instant.
Action wiring 4: An intent MUST NOT carry a constituent-minted id.
Action wiring 5: The composition MUST NOT call the disclosure write BEFORE the disclosure's intent lands.
Action wiring 6: An admitted disclosure MUST call the disclosure write with the subject reference, the recipient, the scope, the authority AND now as the disclosure instant.
Action wiring 7: IF the disclosure write answers storage-failure THEN [Disclose Subset] MUST answer recording-failure carrying intent.
Action wiring 8: IF the disclosure write answers a disclosure refusal THEN [Disclose Subset] MUST answer the disclosure refusal.
Action wiring 9: A refused disclosure write MUST NOT write beyond the intent.
Action wiring 10: An accounted disclosure MUST take the disclosure exclusion on the disclosure id.
Action wiring 11: IF the invocation's lease expired THEN the invocation MUST NOT re-read BEFORE re-taking the disclosure exclusion.
Action wiring 12: An accounted disclosure MUST NOT append an outcome BEFORE re-reading the ledger enumeration for an outcome carrying the disclosure id under the disclosure exclusion.
Action wiring 13: IF the re-read finds an outcome carrying the disclosure id THEN the invocation MUST adopt the outcome as the invocation's own.
Action wiring 14: An invocation whose lease expired MUST NOT append an outcome.
Action wiring 15: An accounted disclosure MUST record the outcome carrying the invocation id, the intent event id, the disclosure id, the disclosed entry ids, the subject reference, the recipient, the scope, the authority, the disclosure instant AND now as the payload instant under the discloser's credential.
Action wiring 16: A landed disclosure MUST write the binding.
Action wiring 17: A landed disclosure MUST construct the verification bundle over the disclosed entry ids the outcome event carries.
Action wiring 18: IF the bundle construction fails THEN the landed disclosure MUST carry unavailable carrying the reason as the verification bundle.
Action wiring 19: IF the adopted outcome carries the unresolved-set marker THEN the landed disclosure MUST carry unavailable carrying entry-set-unresolved as the verification bundle.
Action wiring 20: A landed disclosure MUST answer the disclosure result.
Action wiring 21: An invocation MUST release the disclosure exclusion at EVERY answer.
Action wiring 22: IF no outcome event carries the disclosure id THEN [Reissue Bundle] MUST answer not-known.
Action wiring 23: A found reissue MUST construct the verification bundle over the disclosed entry ids the outcome event carries.
Action wiring 24: [Verify Disclosure] MUST check EVERY presented entry against the verification bundle AND the ledger seal reference.
Action wiring 25: [Verify Disclosure] MUST NOT read an undisclosed entry.
Action wiring 26: [Verify Disclosure] MUST NOT refuse a call.
Action wiring 27: [Verify Disclosure] MUST NOT read the binding index.
Action wiring 28: IF the accounting store carries no record for the disclosure id THEN [Verify Ledger] MUST answer not-known.
Action wiring 29: A found ledger verification MUST resolve the binding through the substrate read.
Action wiring 30: A found ledger verification MUST NOT rest a verdict on the binding index alone.
Action wiring 31: IF the binding index misses the disclosure id THEN the found ledger verification MUST run the binding rebuild's read.
Action wiring 32: IF the record read answers Purged for the indexed event THEN the found ledger verification MUST NOT run the binding rebuild's read.
Action wiring 33: A bound ledger verification MUST read the outcome event's covering range through the record read.
Action wiring 34: IF the record read answers partially-purged coverage THEN the bound ledger verification MUST call the verification with the covering range's members the original event payloads carry.
Action wiring 35: IF a member of the covering range IS NOT IN the original event payloads THEN the attestation verification MUST carry payload-not-supplied AND the missing sequence numbers.
Action wiring 36: IF EVERY member of the covering range IS IN the original event payloads THEN the bound ledger verification MUST call the verification with the covering range's payloads in ascending sequence order.
Action wiring 37: IF the record read names no covering range THEN the presentation MUST carry the outcome event's own payload.
Action wiring 38: The bound ledger verification MUST carry the verification's outcome AND reason unchanged as the attestation verification.
Action wiring 39: The bound ledger verification MUST carry the verification's compensation-window qualifier beside the attestation verification.
Action wiring 40: The read passthrough MUST route an accounting query to the disclosure read.
Action wiring 41: The read passthrough MUST route a sequence-range query AND a wall-time-range query to Event Log's read through Audit Trail.
Action wiring 42: The read passthrough MUST route an event-id query to the record read.
Action wiring 43: IF the query conforms to no routed shape THEN the read passthrough MUST answer invalid-query.
Action wiring 44: IF the routed read answers invalid-query THEN the read passthrough MUST answer invalid-query.
Action wiring 45: A read-only action MUST NOT record an audit event.
Action wiring 46: The composition MUST carry the writing invocation's invocation id on EVERY event the composition records.
```

Term validated entry: a [Record Entry] call whose inputs cleared Primitive policy.

Term landed entry: a validated entry whose ledger entry landed.

Term validated disclosure: a [Disclose Subset] call whose inputs, membership and envelope cleared Primitive policy.

Term admitted disclosure: a validated disclosure whose intent landed.

Term disclosure refusal: invalid-request | unknown-authority-type — Selective Disclosure's refusals of the disclosure write, relayed by name.

Term accounted disclosure: an admitted disclosure whose disclosure write answered the disclosure id.

Term landed disclosure: an accounted disclosure whose outcome landed or was adopted.

Term disclosure instant: the now an admitted disclosure passes to the disclosure write — disclosed_at — and the outcome carries: the accounted time of disclosure.

Term payload instant: the now an event's payload carries — the payload's recorded_at, distinct from Event Log's own recording instant for the append.

Term found reissue: a [Reissue Bundle] call whose disclosure id an outcome event carries.

Term found ledger verification: a [Verify Ledger] call whose disclosure id the accounting store carries.

Term bound ledger verification: a found ledger verification whose binding verdict carries bound.

Term covering range: the sequence range the record read names for an event's covering seal.

Term read passthrough: the composition's read — routed to the constituent whose declared query shape the query conforms to.

Term read-only action: [Verify Disclosure], [Verify Ledger], [Reissue Bundle] or the read passthrough.

WHY:
**[Record Entry] is one write, and it needs no intent** (Action wiring 1 and 2; Invariant 6): its single audit write *is* the load-bearing write and the credential-verifying call, so nothing commits on an unverified claim.

**[Disclose Subset] writes three records in order, never atomically** (Action wiring 3 through 21; 2026-08-26-k). The intent first — where the discloser's credential is verified, so a permanent, non-removable accounting record naming a recipient, a scope and an asserted authority is never committed on an unverified say-so — carrying the invocation's parameters and no constituent-minted id, since the disclosure id is the key the index and both orphan enumerations read and an intent carrying one would be a rebuild hazard. Then the accounting write, which takes the invocation's reading as its instant, so the accounting record, the outcome and the intent share one reading — the key the reconciliation pairs by. Then, under the disclosure exclusion, the outcome, whose payload mirrors the accounting record's full field set **because the seal covers exactly what the payload carries**: Selective Disclosure's immutability is the atom's specification-level guarantee, not records-alone verifiable, and a field not mirrored under seal keeps only the weaker guarantee. **The outcome is pre-checked under the exclusion and an existing one adopted** (Action wiring 10 through 14; the section titled *A compensator is exclusive* in `pressure-testing.md`): the reconciliation compensated the record while the invocation stalled, or an acknowledgment was lost, and a second outcome for one disclosure id is the duplicate the bijection forbids and the seal would then protect.

**The bundle is a projection, reissuable, and its failure is not a refusal** (Action wiring 17 through 23; 2026-08-30-f). No constituent action produces a subset proof — Tamper Evidence verifies whole record sets, Audit Trail single whole events — so the composition constructs it by invoking the configured mechanism's inclusion-proof capability over seal material the substrate already committed: the mechanism-capability residual the section titled Substrate composition invocation in `execution-contract.md` permits, with a Subset Proof atom *(forthcoming)* its retirement path. Both truth-bearing writes have committed by then, so a construction failure answers success with the bundle unavailable — a refusal would tell the caller the disclosure was not recorded — and **[Reissue Bundle] declares the recovery path** the prose left to the deployment: the bundle is a pure projection over the seal material and the entry set the sealed outcome records, so it is re-derivable at any time. An outcome that omits the set — a compensation whose candidates disagreed — determines none, and no bundle may be proved over a set no sealed record asserts.

**[Verify Disclosure] is total and recipient-side** (Action wiring 24 through 27): a check a recipient runs on material already held, so every outcome is a verdict, never a refusal, and it reads no undisclosed entry and not the index — the accountability side is [Verify Ledger]'s.

**[Verify Ledger] reads the substrate, lawful destruction first** (Action wiring 28 through 39; the section titled *Lawful destruction is answered before absence* in `pressure-testing.md`). The index only accelerates; a hit whose event is purged goes to the purged verdict without the rebuild read, since the payload a match would need was lawfully destroyed. **The presentation is keyed by position because a seal commits to a range**: under interval cadence the range spans entries, intents and whatever else the instance records, so an id-keyed map would answer a record-set mismatch on every intact ledger. Partially-purged coverage is answered before membership; an event the record read names no range for — in the unsealed tail, under either tail mode — is presented as itself, and the substrate's own answer is relayed, strict or lenient (2026-08-30-b); the compensation-window qualifier rides beside the verification, never inside it.

**The read passthrough routes by shape, and its refusal has two sources** (Action wiring 40 through 44; 2026-08-30-i): a query that conforms to no routed shape — an action-reference-shaped query among them, which the substrate routes to Reverse Index — and a constituent read's own invalid-query, relayed.

**Every event carries its writer's invocation id** (Action wiring 46; 2026-08-30-l) — the entry, the intent and the outcome carry the invocation's, and the reconciliation's recovery intent, compensating outcome and unbindable marker carry the run's — so a read-back after an indeterminate arm is exact and the reconciliation tells one invocation's records from a repeat with identical parameters. It is not the intent-to-outcome key: that stays the intent event id, substrate-minted and sealed.

### Wiring decision

```
Wiring decision 1: EVERY disclosure MUST carry EXACTLY ONE accounting record AND EXACTLY ONE outcome event.
Wiring decision 2: The composition MUST NOT claim an atomic set spanning the accounting record AND the outcome event.
Wiring decision 3: The composition MUST NOT expose a disclosure surface other than [Disclose Subset].
Wiring decision 4: The composition MUST NOT require a particular proof mechanism.
```

WHY:
**Half 1 — the binding.** *Every [Disclose Subset] writes, in a fixed order and never atomically, an intent where the discloser is authenticated, a Selective Disclosure record — the accounting record of record — and an outcome event — the immutable, attributed, sealed, retained proof the disclosure occurred — and any partial failure between the last two is surfaced and compensated by one writer.*

*Principle.* Disclosure accounting an outside party can trust needs two facts inseparable: that the disclosure was recorded with its authority, and that the record of it is itself immutable, attributed and tamper-evident.

*Likely objection.* Why not let Selective Disclosure carry it alone?

*Mechanism.* Selective Disclosure extracted tamper evidence, retention and the recording actor's binding in its own EOS (Essence of Software — Daniel Jackson's framework for freestanding, composable concepts) pass, and states its no-disclosure-unrecorded invariant as an obligation it cannot self-enforce. The composition is where they re-converge: the substrate supplies attribution, seal and retention in one surface, and making [Disclose Subset] the only disclosure surface that always writes both records closes the obligation for everything routed through it (Wiring decision 1 and 3). The accounting record is irreversible and no transaction spans the two stores (Wiring decision 2), so the one partial the order leaves is the orphan the Reconciliation binds.

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
Reconciliation 3: EVERY reconciliation run MUST write the binding rebuild into the binding index ahead of any compensation.
Reconciliation 4: The reconciliation MUST NOT examine a young record.
Reconciliation 5: The reconciliation MUST NOT compensate an aged record.
Reconciliation 6: The reconciliation MUST read EVERY accounting record against the outcome events.
Reconciliation 7: The reconciliation MUST read EVERY outcome event against the accounting store.
Reconciliation 8: The reconciliation MUST NOT pre-check a record BEFORE taking the record's disclosure exclusion.
Reconciliation 9: IF another holder holds the disclosure exclusion THEN the reconciliation MUST leave the record to the reconciliation's next run.
Reconciliation 10: The reconciliation MUST NOT compensate a record an outcome event already names.
Reconciliation 11: The reconciliation MUST pair an orphan record to the unmatched intents carrying the record's subject reference, recipient, scope AND authority whose payload instant EQUALS the record's disclosure instant.
Reconciliation 12: IF the candidate count EXCEEDS one THEN the compensating event MUST carry the intent candidates.
Reconciliation 13: IF the candidate count EXCEEDS the intent candidates cap THEN the reconciliation MUST open an unresolved finding for the record.
Reconciliation 14: IF the candidate count EQUALS zero THEN the reconciliation MUST open a write-ownership finding for the record.
Reconciliation 15: The reconciliation MUST NOT compensate an unpairable record.
Reconciliation 16: The reconciliation MUST NOT record a compensating event BEFORE the reconciliation's recovery intent lands.
Reconciliation 17: A recovery intent MUST carry the invocation id, the disclosure id AND the intent reference.
Reconciliation 18: The reconciliation MUST attest EVERY write the reconciliation makes under the recovery identity.
Reconciliation 19: A compensating event MUST carry the recovery flag, the discloser AND the intent reference.
Reconciliation 20: The reconciliation MUST re-derive a compensating event from the accounting record AND the paired intent.
Reconciliation 21: IF the candidates' disclosed entry ids differ THEN the compensating event MUST carry the unresolved-set marker AND no disclosed entry ids.
Reconciliation 22: IF Audit Trail answers invalid-request with nothing appended at a compensating event THEN the reconciliation MUST record the unbindable marker.
Reconciliation 23: An unbindable marker MUST carry the disclosure id, the intent reference AND the substrate's refusal.
Reconciliation 24: The reconciliation MUST retry a compensating event refused with a pre-append step at the reconciliation's next run.
Reconciliation 25: The reconciliation MUST write the binding ONLY AFTER the compensating event lands.
Reconciliation 26: The reconciliation MUST open a binding-orphan finding for EVERY orphan record.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a bound orphan, a terminal unbindable verdict or a finding — an auditor awaits within the reconciliation's surfacing bound.

Term young record: an accounting record whose `disclosure instant + disclosure completion bound` DOES NOT PRECEDE the reconciliation's now.

Term aged record: an accounting record whose `disclosure instant + audit horizon` PRECEDES the reconciliation's now.

Term orphan record: an accounting record no outcome event names, neither young nor aged.

Term unmatched intent: an intent no outcome event names by intent event id or among its intent candidates.

Term candidate count: how many unmatched intents Reconciliation 11 pairs to one orphan record.

Term unpairable record: an orphan record whose candidate count EQUALS zero or EXCEEDS the intent candidates cap.

Term intent candidates: the paired intents where more than one pairs — intent_event_candidates.

Term intent reference: the intent event id where one intent pairs, or the intent candidates.

Term recovery intent: the ledger.recovery_intended event.

Term compensating event: an outcome event the reconciliation records under the recovery identity.

Term recovery flag: cascade_recovery set to true on a compensating event.

Term discloser: the original discloser's actor reference, carried in a compensating event's sealed payload — disclosed_by.

Term unresolved-set marker: entry_set_unresolved set to true on a compensating event whose candidates carried different entry sets.

Term unbindable marker: the ledger.disclosure_unbindable event — the terminal record of an orphan whose outcome the substrate refuses deterministically.

WHY:
**Why the reconciliation is mandatory.** A partial failure that *returns* surfaces the orphan in the answer; a crash between the accounting write and the outcome returns nothing, and only this leg finds it. It is **Reconciliation, not Housekeeping**: an auditor awaits its output, bounded at `disclosure instant + bound + cadence`.

**Rebuild first, every run** (Reconciliation 3): the full binding rebuild is written into the index each run, so the half that becomes truth-bearing at the purge is captured within one cycle of every event's landing — before any purge can reach it, under the horizon inequality. The prose rested that half on the invocation's own index write, which a crashed invocation never reaches.

**Bounded at both ends, exclusive, as the composition** (Reconciliation 4 through 10 and 16 through 19; the sections titled *A reconciliation is bounded at both ends*, *A compensator is exclusive* and *Recovery commits under a declared service identity* in `pressure-testing.md`). Below the bound a record may belong to an invocation between its writes; past the horizon a record with no live event is the purged verdict or an index-loss finding, and appending a fresh outcome for it would manufacture the record the purge lawfully removed. The leg takes the exclusion before its pre-check and never races a holder; two runs, restart and cadence, serialize on the same exclusion. Every write is under the recovery identity behind a recovery intent, the discloser preserved in the sealed payload — the recovery identity attests the *recording*, the payload preserves who *disclosed*.

**It pairs by the records** (Reconciliation 11 through 15 and 20 through 21; the section titled *Intents pair with outcomes* in `pressure-testing.md`). The invocation passed one reading as the accounting record's instant and stamped it on its intent, so the pair is the unmatched intent carrying the record's fields at that exact instant. Several — the clock's resolution admitting two identical disclosures in one reading — are named, never chosen, up to the cap; **none is a record written by a direct constituent call outside the composition** — a write-ownership finding, never compensated (2026-08-26-e, 2026-08-30-g). What the compensating event carries is re-derived, and where the candidates disagree on the entry set it omits the set, because a set no record determines is not one this composition may assert under seal; such a disclosure is bound and its bundle cannot be reissued. **One intent per invocation, carried through compensation unchanged**: a fresh one would make the recovery identity the authenticated principal for a disclosure the discloser made.

**The deterministic arm gets a terminal verdict** (Reconciliation 22 and 23). A payload the configured cap refuses — the one residual step one's sizing leaves, a configured cap disagreeing with the wired Event Log's — cannot land by repetition and no re-attestation touches a payload, so the leg records a small, bounded unbindable marker and stops; once the cap is corrected a later outcome supersedes it (Verdict 6). The retention-source invalid-request never gets here: the pre-check finds the event already appended.

### Verdict

```
Verdict 1: IF EXACTLY ONE live outcome event carries the disclosure id THEN the binding verdict MUST carry bound.
Verdict 2: IF the count of live outcome events carrying the disclosure id EXCEEDS one THEN the binding verdict MUST carry binding-duplicate naming the event ids.
Verdict 3: IF no live outcome event carries the disclosure id AND the binding index names an event the record read answers Purged THEN the binding verdict MUST carry binding-purged.
Verdict 4: IF no live outcome event carries the disclosure id AND an unbindable marker names the disclosure id THEN the binding verdict MUST carry binding-unbindable carrying the substrate's refusal.
Verdict 5: IF no live outcome event, no purged binding AND no unbindable marker names the disclosure id THEN the binding verdict MUST carry binding-gap.
Verdict 6: A live outcome event MUST supersede an unbindable marker.
Verdict 7: IF the binding verdict carries binding-purged THEN the attestation verification MUST carry unverifiable carrying purged.
Verdict 8: An entry's authenticity MUST carry EXACTLY ONE OF authentic, altered, not-in-ledger, unverifiable carrying the reason.
Verdict 9: IF a disclosed entry sits in the unsealed tail at the bundle's construction THEN the bundle MUST mark the entry unverifiable carrying unsealed.
Verdict 10: IF a disclosed entry's event carries Purged at the bundle's construction THEN the bundle MUST mark the entry unverifiable carrying entry-purged.
Verdict 11: IF the verification bundle OR the ledger seal reference is malformed THEN EVERY presented entry MUST carry unverifiable carrying bundle-malformed.
Verdict 12: IF no entry is presented THEN the overall verdict MUST carry disclosure-unverified carrying no-entries-presented.
Verdict 13: The overall verdict MUST carry disclosure-verified ONLY IF EVERY presented entry carries authentic AND confidentiality preserved EQUALS true.
Verdict 14: [Verify Disclosure] MUST carry the verification routine's own report as confidentiality preserved.
```

Term binding verdict: [Bound] | [Binding Duplicate] | [Binding Purged] | [Binding Unbindable] | [Binding Gap].

Term live outcome event: an outcome event whose retention the record read answers Retained or unresolved in its compensation window.

WHY:
**Every binding case lands, and there are five** (Verdict 1 through 7; 2026-08-30-a, 2026-08-30-n). Two live outcomes for one disclosure id is a second writer, foreclosed by the one-writer rule and reported with both ids rather than resolved by choosing one. The purged case is decidable from the records only because **this composition** kept the key, in the one store that keys it after the payload is gone; an index entry lost past the horizon leaves it indistinguishable from a gap and is reported as one — a finding against the index durability, and honestly one of *loss*. binding-gap is never a steady state under a conforming implementation: an orphan observed during compensation, already surfaced, or a conformance failure.

**Every entry an unsealed or purged ledger cannot prove is marked, not proved** (Verdict 9 and 10; 2026-08-26-i, 2026-08-30-d, 2026-08-30-e): an entry in the unsealed tail cannot yet anchor a proof, and one whose payload is lawfully destroyed can no longer be checked — the bundle says which, per entry, and the disclosure's accounting stands. **[Verify Disclosure] answers with a verdict, never a refusal** (Verdict 11 through 13): a malformed bundle or seal reference is an unverified disclosure, and zero presented entries is never a vacuous success. **Confidentiality is self-reported** (Verdict 14): computed by the routine over the bundle the discloser produced and not recomputable from these records; its trust rests on the deployment's security review of the mechanism's zero-knowledge-of-complement construction (External check 6). A recipient independently confirms *authenticity* against the published seal; *confidentiality* is an assurance about the audited mechanism.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs the Audit Trail substrate and Selective Disclosure together.

- **Invariant 1 — Disclosure-accountability binding bijection.**
  ```
  Invariant 1.1: IF an orphan record's surfacing bound PRECEDES now THEN the composition MUST NOT leave the orphan record unsurfaced.
  Invariant 1.2: EVERY pairable orphan record MUST reach a terminal binding.
  Invariant 1.3: Two live outcome events MUST NOT carry one disclosure id.
  Invariant 1.4: EVERY outcome event MUST carry a disclosure id the accounting store carries.
  Invariant 1.5: EVERY compensating event MUST carry the recovery flag.
  Invariant 1.6: IF an accounting record's outcome event carries Purged THEN the binding index MUST keep the record's binding.
  ```
  Term surfacing bound: `disclosure instant + disclosure completion bound + reconciliation cadence`.

  Term terminal binding: an outcome event naming the record, or an unbindable marker naming the record.

  Term pairable orphan record: an orphan record that is not unpairable.

  WHY: a one-to-one binding between the accounting records this composition produced and the outcome events — *produced* meaning paired: a record an intent pairs by the reconciliation's predicate, a record none pairs being a write-ownership finding against Composes 11 (2026-08-26-e, 2026-08-30-g). The two truth-bearing writes are ordered, never atomic, and the accounting record is irreversible, so the orphan is reachable and durable until compensated. **Safety** (Invariant 1.1): the records answer at every instant whether an orphan exists, and its surfacing is bounded — a returning failure surfaces it in the answer, a crash by the next reconciliation run past the bound. **Liveness** (Invariant 1.2): *Orphan(d) ↝ Bound(d) ∨ Unbindable(d)* under weak fairness — the invocation's counted retries, then the reconciliation's runs, never both; the transient arm by retry, the mid-flight revocation by re-attestation under the recovery identity, the payload refusal by the terminal marker. Recovered bindings stay distinguishable (Invariant 1.5). **Retention horizon** (Invariant 1.6): accounting records are never removable, so when an outcome event is lawfully purged the record survives it — not an orphan and not a gap, answered as binding-purged through the key this composition kept; past the horizon the bijection reads *every record bound to exactly one outcome event or to that event's honest-destruction record*. The model covers the clean sequence and the compensated partial and mirrors Audit Trail Invariant 4; its re-derivation over the reconciliation and the invocation's counted terminus is open (2026-08-29-a, 2026-08-30-m). *Rests on* Selective Disclosure Invariant 1 and 6, Audit Trail Invariant 1, 3 and 8, the reconciliation, and the horizon inequality.
- **Invariant 2 — Verifiable partial disclosure.**
  ```
  Invariant 2.1: IF the partial disclosure capability EQUALS true THEN a party holding the disclosed entries, the verification bundle AND the ledger seal reference MUST verify EVERY sealed disclosed entry's authenticity.
  Invariant 2.2: IF the partial disclosure capability EQUALS true THEN the verification bundle MUST NOT reveal an undisclosed entry.
  Invariant 2.3: IF the partial disclosure capability EQUALS false THEN the verification bundle MUST declare the degradation.
  ```
  WHY: a conditional invariant, the antecedent inside the statement, because partial verifiability is a present-or-absent capability of the configured mechanism. **Qualified by the unsealed tail** (2026-08-26-i): an entry not yet sealed at disclosure cannot anchor a proof, and the bundle marks it unverifiable (Verdict 9) — Invariant 2.1 speaks of sealed entries. The confidentiality half is self-reported and cleared externally (External check 6). *Rests on* Audit Trail Invariant 3 (integrity coverage, modulo the unsealed tail) and Audit Trail Invariant 7 (the verifier presents the records), the declared capability, and the composition-introduced subset-proof surface.
- **Invariant 3 — Immutable, attributed, retention-governed ledger.**
  ```
  Invariant 3.1: EVERY ledger event MUST carry an attestation, a retention record AND a position in the Event Log sequence.
  Invariant 3.2: The composition MUST NOT change a ledger event.
  Invariant 3.3: The composition MUST NOT reorder a ledger event.
  ```
  WHY: every entry, intent and outcome is append-only and totally ordered, attributed, sealed under the cadence, and placed under retention at write time with honest cascade on purge. *Rests on* Audit Trail Invariant 1 through 4, 6 and 8, holding transitively over the four atoms.
- **Invariant 4 — No disclosure unrecorded, structurally closed.**
  ```
  Invariant 4.1: A disclosure through the composition MUST NOT answer success BEFORE the accounting record AND the outcome event land.
  ```
  WHY: Selective Disclosure's Invariant 5, which the atom can only state, is enforced here for disclosures routed through the composition; one performed outside it is a system conformance failure against the atom's invariant and outside this composition's claim (Composes 11). *Rests on* Invariant 1 and Wiring decision 3.
- **Invariant 6 — Authentication precedes commitment.**
  ```
  Invariant 6.1: The composition MUST NOT call the disclosure write BEFORE Audit Trail validates the discloser's credential at the intent.
  Deleted: Invariant 5. Composes 5 owns it.
  ```
  WHY: the intent stands before the one irreversible write — Selective Disclosure records are never removable — so a permanent accounting record is never created on an unverified actor's asserted authority, and invalid-credential is a pre-state refusal with nothing in either store. [Record Entry] needs no second mechanism: its one write is the credential-verifying and the load-bearing call alike. **What it does not establish**: a validation shows matching material was presented at that instant — not that the presenter *is* the actor, not a channel binding, not replay resistance — **and nothing whatever about the other three references a disclosure carries**: the subject, whose correspondence is the host's assertion; the recipient, never authenticated here — [Verify Disclosure] being runnable *by* a recipient is a capability statement, not an identity claim; and the authority's holder. *Rests on* the audit write and the Actor Identity attestation reached through it; Check 5.1 tests the order from the records. The deleted invariant asserted each constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).

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

   The intent record goes first: `AuditTrail.record_action(action_ref = ledger.disclose_intended, actor_ref = "compliance-c4", <compliance_cred>, data = {disclosed_entry_ids: {"ev_5002"}, subject_ref: "account-7731", recipient, scope, authority.type, authority.reference, recorded_at})` → `ev_5004`. That call is where `compliance-c4`'s credential is validated, so nothing has been written to either store if it does not — the permanent disclosure-accounting record below is never created on an unverified claim. Then the binding fires: `SelectiveDisclosure.record(...)` → `disc-2210`; then `AuditTrail.record_action(action_ref = ledger.disclosed, actor_ref = "compliance-c4", <compliance_cred>, data = {intent_event_id: "ev_5004", disclosure_id: "disc-2210", disclosed_entry_ids: {"ev_5002"}, subject_ref: "account-7731", recipient, scope, authority.type, authority.reference, disclosed_at, recorded_at})` → `ev_5005`; then `disclosure_to_event["disc-2210"] = "ev_5005"`. The outcome event names its intent event, which is what lets an auditor confirm from the records alone that the disclosing actor was authenticated before the disclosure existed. The act of disclosing is now itself an immutable, attributed, sealed ledger entry. The verification_bundle is the Tamper Evidence inclusion proof for `ev_5002` against the published ledger seal — and for `ev_5002` *only*.

3. **The examiner independently verifies the disclosed trade.** The examiner holds the disclosed entry payload (the `ev_5002` confirmation), the verification_bundle, and the broker-dealer's published ledger_seal_reference (the Merkle root, anchored to an RFC 3161 (the Internet standard for trusted time-stamping) Time-Stamp Authority (TSA) — a trusted third party that signs proofs of when data existed). The examiner — *without any access to `ev_5001` or `ev_5003`* — runs `verify_disclosure(disclosed_entries = [ev_5002 payload], verification_bundle, ledger_seal_reference)`:

   - `entries`: `[{entry_id: "ev_5002", authenticity: authentic}]` — the inclusion proof checks against the root, so the disclosed trade is a genuine, unaltered ledger entry.
   - `confidentiality_preserved = true` — the inclusion proof reveals sibling hashes but not the contents, count, or position of `ev_5001` / `ev_5003`.
   - `overall_verdict = disclosure-verified`.

   The examiner trusts the trade without trusting the broker-dealer and without seeing the rest of the book. This is Invariant 2 (verifiable partial disclosure) in operation.

4. **A compliance auditor verifies the accountability side.** Separately, an internal auditor with access to the composition's stores asks: *was this disclosure recorded and attributed?* The auditor calls `verify_ledger(disclosure_id = "disc-2210", original_event_payloads)`:

   - `binding = bound` — the `ledger.disclosed` event `ev_5005` carries `data.disclosure_id = "disc-2210"`, confirmed by the substrate read (Invariant 1); the `disclosure_to_event` index supplied the accelerating hit.
   - `attestation_verification = verified` — `read_record("ev_5005")` names its position and covering range, the auditor's original_event_payloads supplies every payload in that range keyed by `sequence_number`, and `AuditTrail.verify_record("ev_5005", <the range's payloads>)` confirms the disclosing officer's credential and the seal over the disclosure event.
   - `retention_state = Retained`.

   The two verification surfaces answer two different questions: [Verify Disclosure] (anyone holding the bundle) proves the *subset is genuine*; [Verify Ledger] (an auditor with the stores) proves the *disclosure was accounted*. Neither constituent answers either alone.

### Healthcare — accounting of disclosures under HIPAA §164.528

A covered entity keeps each patient's billing-disclosure ledger in this composition. Every time PHI (Protected Health Information) is disclosed to a payer, a public-health authority, or a business associate, the entity calls [Disclose Subset] naming the disclosed billing entries, the recipient, and the authority (`{ type: regulatory, reference: "HIPAA §164.512(b)" }` for public-health reporting; `{ type: consent, reference: "<consent-id>" }` for patient-authorized sharing). When the patient exercises their §164.528 right to an accounting of disclosures, the entity calls read against the Selective Disclosure store filtered by `subject_ref = <patient>`: the result is every disclosure — date, recipient, scope, authority — drawn from the records alone. Because each disclosure is also a `ledger.disclosed` event (Invariant 1), the accounting is itself immutable, attributed, and tamper-evident — a property §164.528's accounting obligation needs but the plain Selective Disclosure atom cannot supply alone.

### Clinical-trial submission ledger under 21 CFR Part 11

A sponsor records each electronic submission to a regulator as a [Record Entry] in a 21 CFR Part 11 submission ledger (attributable, contemporaneous, original, accurate — ALCOA — satisfied by the Audit Trail substrate). When the sponsor discloses a defined subset of the submission record to an inspector or an IRB (Institutional Review Board), [Disclose Subset] produces both the accountable disclosure record and the partial-disclosure proof for exactly the disclosed documents, leaving the remainder of the submission sealed and unrevealed. The inspector verifies the disclosed subset against the published seal; the sponsor's disclosure log answers *what was shown, to whom, under what authority* from the records alone.

### Rejection path — empty or unknown subset

A caller attempts to disclose with no entries: `disclose_subset(disclosed_entry_ids = {}, …)` → `rejected(invalid-request)` at step 1; nothing is written to either store. A caller names an entry id that is not a ledger transaction entry — a fabricated id, or the `event_id` of a `ledger.disclosed` event rather than a `ledger.entry` event: `disclose_subset(disclosed_entry_ids = {"ev_5005"}, …)` → `rejected(unknown-entry)` naming `ev_5005` (it is a disclosure event, not a transaction entry); nothing is written. The membership test (every id resolves to a `ledger.entry` event) runs *before* the irreversible Selective Disclosure write, so an invalid subset never produces a disclosure-accounting record.

### Rejection path — ledger write fails after the disclosure record commits (the orphan)

The compliance officer calls [Disclose Subset] with a valid subset. Step 3 succeeds: `SelectiveDisclosure.record(...)` → `disc-2211` is durably written (Selective Disclosure records are immutable once committed). Step 4 fails: the pre-check under the per-disclosure_id exclusion finds no `ledger.disclosed` event naming `disc-2211`, and `AuditTrail.record_action(ledger.disclosed, …)` returns `recording-failure(step-3)` (the log's store is briefly unreachable) on the first attempt and on each of the `outcome_retry_attempts` re-attempts. The composition returns `rejected(recording-failure(outcome))` — the position telling the officer the disclosure record exists and the action must not be re-run — and yields the orphan to the scan. The result is an **orphan**: a Selective Disclosure record (`disc-2211`) with no `ledger.disclosed` event (and consequently no `disclosure_to_event` entry — the missing event is the orphan's defining lack; the index merely reflects it). This is exactly the orphan Invariant 1's safety arm requires to be surfaced (never silent) and its liveness arm requires to be eventually bound; the *Cross-store consistency under partial failure* edge case governs its compensation (the scan retries the audit write under the recovery identity once the record is older than `disclosure_completion_bound`, one cycle at a time until it lands; surfaces the orphan to the compliance dashboard as a high-priority finding; marks the recovered event `cascade_recovery = true`). The TLA+ (Temporal Logic of Actions — a formal specification language for concurrent and distributed systems) model covers this compensated path mechanically, and its buggy twin demonstrates that the same sequence *without* surfacing and compensation is reachably unsafe — see the Ledger's `formal:` line and the commit that landed the model.

### Retention horizon — a disclosure event reaches its lawful end

Years later, the `ev_5005` disclosure event from the walkthrough reaches the end of `ledger_retention_policy` and is lawfully purged (Audit Trail cascade-on-purge): its payload — `data.disclosure_id` included — is unreadable, and the substrate's destruction record keeps only `(ev_5005, a_5005)`, off which `action_ref = ledger.disclosed` and the discloser still read. The Selective Disclosure record `disc-2210` survives — its store is not governed by that policy — and so does the composition's own index entry `disclosure_to_event[disc-2210] = ev_5005`, the purged half that is truth-bearing under the durability obligation (Composition state). An auditor later calls `verify_ledger("disc-2210", …)`: the rebuild read finds no live `ledger.disclosed` event, the index entry resolves `ev_5005` to a `Purged` retention record and a destruction record whose attestation names `ledger.disclosed`, and the action returns `binding = binding-purged`, `attestation_verification = unverifiable(purged)`, `retention_state = Purged` — honest destruction, distinguishable from a `binding-gap`, exactly Invariant 1's retention-horizon arm. Nothing is surfaced as a finding; nothing is wrong.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit — "produce the accounting of disclosures, and prove each is genuine" (HIPAA §164.528 / SEC Rule 17a-4).**

A regulator queries the disclosure-accounting surface for a subject (a patient under §164.528, an account under 17a-4). The system calls read against the Selective Disclosure store filtered by subject_ref, returning every disclosure — date, recipient, scope, authority. For any disclosure the regulator wishes to verify, the system calls `verify_ledger(disclosure_id, original_event_payloads)`:

- `binding = bound`: by Invariant 1 (binding bijection), every disclosure record produced by the composition has exactly one corresponding `ledger.disclosed` event. A disclosure cannot appear in the accounting without its immutable, attributed, sealed ledger event.
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

- For every Selective Disclosure record produced by the composition, confirm a `ledger.disclosed` event exists whose `data.disclosure_id` points back (the authoritative substrate read; `disclosure_to_event` accelerates it as a derived index). A disclosure record with no such event is an **orphan** — the partial-failure signature, which Invariant 1's safety arm guarantees is already surfaced as a high-priority finding (a recorded disclosure whose immutable ledger proof is missing); an orphan found here that was *not* surfaced is a conformance failure, not a transient. A recovered binding is distinguishable by its `cascade_recovery` marker.
- For every `ledger.disclosed` event, confirm its `data.disclosure_id` resolves to a Selective Disclosure record. A `ledger.disclosed` event naming a disclosure_id absent from the disclosure store is the inverse orphan.
- For the disclosure events themselves, walk the Audit Trail seal store in `sealed_at` order (inherited from the substrate's breach-forensics scenario): the most recent seal that verifies end-to-end and the first that returns `failed-verification(seal-proof-invalid)` bound the forensic window during which a disclosure event may have been tampered with.

The binding bijection is what makes "every disclosure is accounted" a checkable property rather than a hope; the orphan is exactly the reachable bad state the formal model rejects.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the binding index, the Selective Disclosure store and the Audit Trail substrate stores, can clear the checks below without recourse to source code, runbooks or developer narration. Every enumeration of ledger events below runs through the ledger enumeration, never through a query the substrate routes to Reverse Index.

### Conformance checks

```
Check 1.1: An auditor MUST read EVERY accounting record against the outcome events (Invariant 1.2).
Check 1.2: An auditor MUST resolve EVERY accounting record carrying no live outcome event to EXACTLY ONE OF binding-purged, binding-unbindable, an orphan under compensation, a write-ownership finding, a conformance failure (Invariant 1.2).
Check 1.3: An auditor MUST read an accounting record younger than the disclosure completion bound as inconclusive (Reconciliation 4).
Check 1.4: An auditor MUST find EVERY outcome event's disclosure id carried by the accounting store (Invariant 1.4).
Check 1.5: An auditor MUST find no disclosure id two live outcome events carry (Invariant 1.3).
Check 1.6: An auditor MUST find EVERY outcome event attested under the recovery identity carrying the recovery flag (Invariant 1.5).
Check 1.7: An auditor MUST find no outcome event attested under a discloser carrying the recovery flag (Invariant 1.5).
Check 1.8: An auditor MUST find the shortest retention period exceeding the liveness sum (Capability requirement 11).
Check 2.1: An auditor MUST find [Verify Disclosure] answering authentic for EVERY sealed disclosed entry a presented bundle covers (Invariant 2.1).
Check 2.2: IF the partial disclosure capability EQUALS false THEN an auditor MUST find the bundle declaring the degradation (Invariant 2.3).
Check 3.1: An auditor MUST find EVERY ledger event attested, placed in the Event Log sequence AND under a retention record (Invariant 3.1).
Check 3.2: An auditor MUST find a passing verification for EVERY ledger event whose covering range the auditor presents (Invariant 3.1).
Check 4.1: An auditor MUST find [Disclose Subset] the composition's only disclosure surface (Invariant 4.1).
Check 5.1: An auditor MUST resolve EVERY outcome event's intent event id to an intent that PRECEDES the outcome in the Event Log AND carries the same parameters (Invariant 6.1).
Check 5.2: An auditor MUST NOT join an outcome to an intent by any key weaker than the intent event id (Invariant 6.1).
Check 5.3: IF an outcome event carries the recovery flag THEN an auditor MUST compare the intent's actor with the discloser the payload carries (Invariant 6.1).
Check 5.4: An auditor MUST NOT read an intent carrying no outcome as a conformance failure (Reconciliation 11).
Check 5.5: IF an outcome event's intent event id resolves to no event THEN an auditor MUST read the precedence as unverifiable carrying purged-horizon (Invariant 6.1).
Check 6.1: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
Check 6.2: An auditor MUST clear Selective Disclosure's Generation acceptance over the Selective Disclosure instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged.

WHY:
**Every accounting record is read, and the unpaired one is named** (Check 1.1 and 1.2; 2026-08-30-g). The prose quantified over *every record produced by this composition*, which no field declares; every record is enumerated instead, and one with no live outcome resolves to exactly one class — the purged verdict, the unbindable marker, an orphan under compensation, a write-ownership finding for a record no intent pairs, or a conformance failure. **The enumeration runs between the reconciliation's edges** (Check 1.3). Whether a detected orphan was *surfaced* and is under compensation is not clearable from these stores (External check 1). The recovery flag and the attesting identity agree in both directions (Check 1.6 and 1.7).

**The join is the intent event id and nothing weaker** (Check 5.1 through 5.5). [Disclose Subset] is repeatable with identical parameters — that is what a disclosure accounting records — so a join over the subject, recipient, scope or actor would let one stale intent satisfy the check for any number of later disclosures, and a join through the index would rest on evictable state. A compensated outcome compares the intent's actor with the discloser its payload preserves, never its attesting recovery identity, against each candidate where it names several. **An intent with no outcome is not a failure**; the accounting store says which case it is. **Horizon, and one window inside it**: the purge destroys the intent event id past the horizon, and — since the intent and the outcome are placed under retention by their own writes under one policy — a purge landing between their retention deadlines destroys the intent while the outcome is still live; either way an unresolvable intent is unverifiable, never a finding.

**The constituents' own bars are cited, not counted** (Check 6.1 and 6.2; 2026-08-26-f): a count copied from another page goes stale on that page's next change, and this one had.

### External checks

```
External check 1: An auditor needing the orphan-surfacing discipline confirmed MUST read the deployment's finding surface AND reconciliation schedule (Invariant 1.1).
External check 2: An auditor needing an asserted authority's validity confirmed MUST read the authority's own pattern (Non-goal 1).
External check 3: An auditor needing a disclosure's permission confirmed MUST read the deployment's Consent AND Permissions records (Non-goal 1).
External check 4: An auditor needing the transaction data's accuracy confirmed MUST read the host's source of the transaction (Primitive policy 13).
External check 5: An auditor needing the disclosed entries' correspondence to the subject confirmed MUST read the host's subject tagging (Non-goal 6).
External check 6: An auditor needing the partial disclosure capability AND complement confidentiality confirmed MUST read the deployment's security review of the mechanism (Invariant 2.2).
External check 7: An auditor needing the ledger seal reference's singularity AND the verifier's independence confirmed MUST read the deployment's seal publication (Invariant 2.1).
```

WHY:
The records prove an orphan exists and that a recovery happened; whether an open one is surfaced and under active retry is the finding surface's, operational (External check 1). The authority is recorded and made auditable, never adjudicated. **The subject's correspondence is the host's assertion** (External check 5): the transaction data is opaque, so nothing here connects an entry to the subject a disclosure is filed under, and under HIPAA §164.528 entries of patient A disclosed under another subject escape A's accounting with no records-alone detection. **Split view** (External check 7): a discloser who keeps a forked side-ledger and hands the recipient the fork's root passes every check *against that fork*; protection is the seal-publication discipline — a time-stamping authority, a regulator filing, a public anchor — and the bundle format must be standard enough that a verifier can be built without the discloser's code.

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

Term accounting-horizon cover: a ledger retention policy aligned to the accounting horizon, a Retention Window instance over the accounting store, or both.

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
The payload instant is the composition's own reading, host-injected at its seam, one per invocation (Capability requirement 23 through 26); Event Log stamps its own recording instant at its own seam. They are two readings of two clocks, never compared (2026-08-30-r). The payload instant serves every stamp the invocation writes, so the reconciliation's pairing equality is by construction; the reconciliation's own lower-edge comparison is two readings of this composition's clock authority, kept monotone and shared across the nodes that run invocations and runs. Selective Disclosure's not-in-future guard compares the passed instant against its own seam's reading; where the deployment does not inject both from one authority, the guard refuses at the accounting write with nothing written and the intent standing — never after the record. The seal cadence and the purge comparison run on the substrate's clock, inherited. Where ledger instants carry legal force, a Trusted Timestamping pattern (RFC 3161 — the Internet Engineering Task Force's standard for trusted time-stamping) provides the anchor, and the seal's anchored instant already bounds the breach window.

### Concurrency

```
Concurrency 1: The composition MUST NOT serialize two disclosures carrying distinct disclosure ids.
Concurrency 2: A verification bundle MUST name the ledger seal the bundle anchors to.
```

WHY:
Distinct disclosures — even over overlapping entry sets — do not conflict: each has its own disclosure id, accounting record, outcome, binding and bundle, and the bijection is per-disclosure local. Implementations serialize each single store write and the per-disclosure exclusion, never across calls. An entry appended between two disclosures' bundle constructions may move the seal, so two bundles over one subset can anchor to different seal points — each valid against the seal it names, and the recipient verifies against the seal reference paired with the bundle (Concurrency 2). A lawful purge can land between membership and bundle construction; the disclosure stands and the bundle marks the entry (Verdict 10).

### Degraded bundle

```
Degraded bundle 1: IF the partial disclosure capability EQUALS false THEN [Disclose Subset] MUST record the accounting record AND the outcome event.
Degraded bundle 2: IF [Verify Disclosure] receives a degraded bundle without the whole ledger THEN EVERY presented entry MUST carry unverifiable carrying whole-ledger-required.
Degraded bundle 3: IF [Verify Disclosure] receives a degraded bundle THEN confidentiality preserved MUST carry false.
Degraded bundle 4: IF [Verify Disclosure] receives a degraded bundle THEN the overall verdict MUST carry disclosure-unverified carrying degraded-bundle.
```

WHY:
Where the mechanism cannot prove a named subset — a single whole-ledger hash with no inclusion structure — the accounting is unaffected and the binding holds, but a recipient can verify only by verifying the whole seal, which needs the whole ledger and breaks the confidentiality half. The composition does not weaken the guarantee silently: the degraded path's verdicts are pinned, and a verifier that waves a degraded bundle through as verified is non-conforming.

### Retention asymmetry

```
Retention asymmetry 1: The composition MUST NOT bound the accounting store's retention.
Retention asymmetry 2: A deployment whose accounting horizon is regulated MUST declare an accounting-horizon cover.
```

WHY:
Selective Disclosure records are never removable (its Invariant 6), so left alone the accounting store keeps forever while the outcome events purge at the ledger horizon — the mismatch Invariant 1.6 makes lawful and distinguishable. A deployment under HIPAA §164.528's six-year accounting window or GDPR Article 30 aligns the policies, or declares a second Retention Window instance over the accounting store — a declared multi-instance topology per the section titled Substrate composition invocation in `execution-contract.md`, not a silent duplicate. A disclosed entry that is itself later purged makes a subsequent [Verify Disclosure] unverifiable for that entry — honest destruction surfacing at the verification boundary, not a tamper finding; the disclosure proof is contemporaneous evidence, not a perpetual oracle over a record the policy authorized destroying, and [Verify Ledger] still proves the disclosure occurred.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are its actions — [Record Entry], [Disclose Subset], [Verify Disclosure], [Verify Ledger] and [Reissue Bundle]; the [Verification Bundle] and the [Confidentiality Preserved] assertion; the binding verdicts ([Bound], [Binding Duplicate], [Binding Purged], [Binding Unbindable], [Binding Gap]); the authenticity verdicts ([Authentic], [Altered], [Not In Ledger]); and its own refusal, [Unknown Entry]. The binding bijection and verifiable partial disclosure are structural properties, not data. The deployment settings keep their wire spellings in configuration — `ledger_retention_policy`, `seal_cadence`, `disclosure_completion_bound`, `outcome_retry_attempts`, `reconciliation_cadence`, `outcome_write_latency`, `disclosed_entry_ids_cap`, `intent_candidates_cap`, `disclosure_section`, `application_actor_ref`, `application_credential`, `index_durability`, `tamper_evidence_supports_partial_disclosure` — and the binding index its own in an implementation, `disclosure_to_event`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; a discloser; a recipient; an invocation; a holder; a validated entry; a landed entry; a validated disclosure; an admitted disclosure; an accounted disclosure; a landed disclosure; a found reissue; a found ledger verification; a bound ledger verification; a read-only action.

Term records: the ledger entries, intents, outcome events, recovery intents and unbindable markers the composition records through the audit write — each an Event Log event carrying one action reference below — the accounting records it writes through the disclosure write, and the binding index's entries.

Term record verbs: EQUAL, adjudicate, adopt, alert, answer, append, attest, bound, call, carry, change, check, claim, classify, clear, compare, compensate, compose, construct, decide, declare, disclose, duplicate, examine, expose, fall, find, guarantee, inherit, inject, inspect, interpret, join, keep, key, leave, mark, match, name, normalize, open, override, pair, pass, perform, persist, pre-check, proceed, provision, re-derive, re-read, reach, read, rebuild, record, refuse, release, remove, reorder, require, resolve, rest, retry, reveal, route, run, select, serialize, serve, set, stamp, start, store, supersede, supply, suspend, take, track, validate, verify, write.

Term value sets: action reference = ledger.entry | ledger.disclose_intended | ledger.disclosed | ledger.recovery_intended | ledger.disclosure_unbindable. authenticity = authentic | altered | not-in-ledger | unverifiable. unverifiable reason = unsealed | entry-purged | bundle-malformed | whole-ledger-required. The rest are declared where the section that owns each declares it: position, binding verdict, disclosure refusal, finding.

Term bounds: disclosure completion bound (disclosure_completion_bound), outcome retry attempts (outcome_retry_attempts), outcome write latency (outcome_write_latency), disclosed entries cap (disclosed_entry_ids_cap), intent candidates cap (intent_candidates_cap), audit horizon (ledger_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence), seal cadence (seal_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, ledger enumeration, record read, audit write, verification, disclosure write, disclosure read, ledger namespace, disclosure id, binding index, binding, ledger entry, outcome event, live binding, purged binding, binding rebuild, ledger retention policy, audit horizon, shortest retention period, seal cadence, disclosure completion bound, outcome retry attempts, reconciliation cadence, outcome write latency, liveness sum, disclosed entries cap, intent candidates cap, disclosure exclusion, recovery identity, index durability, accounting store, partial disclosure capability, invocation id, seam, now, transaction data, actor reference, disclosed entry ids, subject reference, recipient, scope, authority, maximal envelope, caller string, intent, pre-append step, retention step, position, entry id, disclosure result, disclosed entries, ledger seal reference, disclosure proof, original event payloads, accountability proof, results, validated entry, landed entry, validated disclosure, admitted disclosure, disclosure refusal, accounted disclosure, landed disclosure, disclosure instant, payload instant, found reissue, found ledger verification, bound ledger verification, covering range, read passthrough, read-only action, reconciliation, young record, aged record, orphan record, unmatched intent, candidate count, unpairable record, intent candidates, intent reference, recovery intent, compensating event, recovery flag, discloser, unresolved-set marker, unbindable marker, binding verdict, live outcome event, surfacing bound, terminal binding, pairable orphan record, passing verification, payload handling, accounting-horizon cover.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Substrate composition invocation in `execution-contract.md` — the mechanism-capability residual and the multi-instance topology. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. record_action, read_record, verify_record, payload cap, sealed through, unsealed tail, step-2, step-3, step-4, invalid-credential, invalid-request, recording-failure, verified, failed-verification, unverifiable, purged, partially-purged coverage, compensation-window, Retained, Purged, Erasure Tombstone: Audit Trail. record, read, disclosure id, subject reference, recipient, scope, authority, invalid-request, unknown-authority-type, storage-failure, invalid-query: Selective Disclosure. read, invalid-query: Event Log. verify, seal: Tamper Evidence.

Term composing patterns: [Consent](../atoms/consent.md); [Permissions](../atoms/permissions.md); [Defensible Retention](./defensible-retention.md); [Idempotent Reservation](./idempotent-reservation.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Chain of Custody](./chain-of-custody.md).

#### Record Entry

The composition action that appends one transaction to the ledger — a single `AuditTrail.record_action` (`ledger.entry`) producing an immutable, attributed, sealed, retained event. Returns the `entry_id` (the Audit Trail `event_id`).

Kind: Operation

#### Disclose Subset

The composition's defining action: record that a named subset of ledger entries was disclosed to a recipient under an authority, and produce the [Verification Bundle] by which the recipient can independently verify that subset. Writes three records in order, never atomically: the intent record that authenticates the discloser, then the Selective Disclosure record and the immutable `ledger.disclosed` event — the two truth-bearing writes the binding bijection lands and compensates until restored (Invariant 1).

Kind: Operation

#### Verify Disclosure

The recipient-side emergent verification: given the disclosed entries, the [Verification Bundle], and the published ledger-seal reference, check each entry's authenticity ([Authentic] / [Altered] / [Not In Ledger] / unverifiable) and whether the undisclosed remainder stayed hidden ([Confidentiality Preserved]) — *without* access to the undisclosed contents. Total: always returns a `disclosure-proof`, never a rejection.

Kind: Operation

#### Verify Ledger

The accountability-side verification, run by an auditor with access to the composition's stores: given a disclosure_id, resolve whether the disclosure is bound to exactly one immutable, attributed, sealed, retained ledger event — [Bound], [Binding Duplicate] (a second writer — a finding), [Binding Purged] (lawfully destroyed at its retention end), [Binding Unbindable] (a terminal deployment-configuration finding), or [Binding Gap] (a finding). Returns an `accountability-proof`.

Kind: Operation

#### Reissue Bundle

The read-only action that re-derives the [Verification Bundle] for a committed disclosure from the seal material and the entry set its sealed `ledger.disclosed` event records — the recovery path for a bundle whose construction failed or was lost. An event carrying no entry set yields the bundle unavailable, never one built from a set no sealed record asserts.

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

The [Verify Ledger] binding verdict when more than one live `ledger.disclosed` event names the disclosure — a second writer the one-writer rule forecloses, reported with every event id rather than resolved by choosing one.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-duplicate

#### Binding Purged

The [Verify Ledger] binding verdict when no live `ledger.disclosed` event names the disclosure but the composition's own index still binds it to an `event_id` whose `Purged` retention record attests the event's honest destruction at its retention end (Invariant 1's retention-horizon arm) — lawful and distinguishable from a gap, not a finding.

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

#### Binding Unbindable

The [Verify Ledger] binding verdict when no ledger event names the disclosure but a `ledger.disclosure_unbindable` marker does: the outcome write was refused deterministically for a reason no re-attestation cures (a payload the configured cap rejects), so the disclosure is accounted and attested but its ledger event could not land — a deployment-configuration finding with a lawful terminal state, superseded by [Bound] if the event later lands.

Kind:       Member
Member of:  the accountability binding
Role:       Binding verdict
Projection: binding-unbindable

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

The [Disclose Subset] rejection when a named subset id resolves through the record read to no `ledger.entry` transaction — an unknown id, or any other event, a `ledger.disclosed` outcome included — naming every failing id, deterministically.

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
[Binding Unbindable]: #binding-unbindable
[Authentic]: #authentic
[Altered]: #altered
[Not In Ledger]: #not-in-ledger
[Unknown Entry]: #unknown-entry


## Standards references

This composition is the structural form of the immutable-ledger-with-accountable-disclosure requirement across its canonical domains:

- **SEC (US Securities and Exchange Commission) Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — requires broker-dealer transaction records to be preserved in a non-rewriteable, non-erasable form and produced, in whole or as a defined subset, on demand for an examiner. The Audit Trail substrate's Tamper Evidence (Invariant 3) satisfies the non-rewriteable/non-erasable standard; [Disclose Subset] + [Verify Disclosure] (Invariant 2) is the structural form of producing a verifiable *subset* to an examiner without exposing the rest of the book; the configured `ledger_retention_policy` satisfies the six-year (first-two-years-accessible) lifetime requirement.

- **HIPAA (US Health Insurance Portability and Accountability Act) §164.528 (Accounting of disclosures of protected health information)** — requires a covered entity to give an individual an accounting of disclosures of their PHI: date, recipient, scope, and purpose, drawn from the records alone. The Selective Disclosure store answers the accounting query (read by subject_ref); the binding bijection (Invariant 1) makes each accounted disclosure itself immutable, attributed, and tamper-evident — the property §164.528 needs but plain disclosure accounting cannot supply alone.

- **21 CFR (US Code of Federal Regulations) Part 11 (Electronic records and electronic signatures)** — requires electronic records submitted to a regulator to be attributable, contemporaneous, original, and accurate (ALCOA), with disclosures to the agency themselves recorded. The four-atom Audit Trail stack supplies ALCOA over every ledger entry; [Disclose Subset] records each disclosure to the agency as an attributed, sealed `ledger.disclosed` event.

- **GDPR (EU General Data Protection Regulation) Article 15 (Right of access by the data subject)** — a data subject may demand to know what data was disclosed and to which recipients. The Selective Disclosure store is the source for the recipients-and-scope answer; [Verify Disclosure] additionally lets the subject independently confirm a disclosed subset is genuine *without* the controller exposing every other subject's entries on the shared ledger (Invariant 2's confidentiality half).

- **W3C Verifiable Credentials Data Model and the selective-disclosure / BBS+ (a pairing-based signature scheme supporting selective disclosure of signed messages) proof literature** — the standards surface for cryptographically proving a *subset* of a set of claims authentic while withholding the remainder. This composition's verification_bundle and [Verify Disclosure] are the composition-layer form of this capability; the W3C (the World Wide Web Consortium) VC (Verifiable Credentials) selective-disclosure mechanisms (and accumulator / Merkle-inclusion-proof constructions) are *typical realizations* of Invariant 2's behavioral obligation, named in rationale only — this composition requires the capability, not any particular proof system, exactly as Tamper Evidence is mechanism-neutral.

This composition inherits the broader standards compliance of its constituents:

- Through **Audit Trail** (and its transitive atoms Event Log, Actor Identity, Tamper Evidence, Retention Window): SOX (Sarbanes-Oxley Act) §802 record retention, HIPAA §164.312(b) audit controls, PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR Part 11 electronic records, ISO/IEC (International Electrotechnical Commission) 27001 §A.12.4 logging and monitoring, GDPR Articles 30 and 32, and the full Audit Trail standards inheritance. Deployments composing this composition receive these as the substrate's contribution; they are framed as inherited, not as this composition's own primary anchors.

- Through **Selective Disclosure**: GDPR Article 15(1)(c) and Article 30, HIPAA §164.528, and SEC Rule 17a-4 at the disclosure-accounting layer. This composition lifts these to the immutable-and-independently-verifiable form those standards actually require but that Selective Disclosure alone — which records that a disclosure occurred but seals nothing — cannot satisfy.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation against the one-writer protocol of 2026-08-30; was verified — immutable-transaction-ledger.tla + 1 twin, 2026-06-10
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 5 foundational corrected in-round, 12 refining and 7 rhetorical routed (2 refining and 2 rhetorical closed in-round, the second by the closure check; 1 refining a duplicate of 2026-08-26-f; 1 further refining line on the formal model added; the closure check's 2 refining corrected in-round); 2026-08-26 — authentication-precedence gate, fresh reader — 3 foundational (all pre-existing; all since closed), 7 refining, 1 rhetorical

open:
- 2026-08-29-a · refining · formal · the model's compensation action carries no identity, no recovery record, and no age bound; the twin predates the scan's two edges → extend the model with the recovery-identity compensation behind `ledger.recovery_intended` and the bounded scan
- 2026-08-30-m · refining · formal · the model commits the invocation's outcome as one atomic step and has no scan process, so the second writer, the counted terminus, the every-cycle rebuild and the step-1 sizing are not exhibited → extend it (with 2026-08-29-a)
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/immutable-transaction-ledger.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.61; twenty-three of twenty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the per-disclosure section renamed the disclosure exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the binding and authenticity verdicts as their own `Verdict` family; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and four Edge cases families. Choices the page left open, each decided by a standing rule: *produced by this composition* defined as *paired by the reconciliation's predicate*, with the ledger namespace and the disclosure write reserved to the composition and an unpaired record a write-ownership finding (2026-08-26-e, 2026-08-30-g); a declared [Reissue Bundle] rather than a dropped claim (2026-08-30-f — *as simple as possible without losing fidelity*: the prose leaned on a recovery path no surface declared); an entry unsealed or purged at bundle construction marked in the bundle per entry rather than refused (2026-08-26-i, 2026-08-30-d, -e — *make all things mean one thing*: the purge-between-check-and-bundle race already answered this way); blank refused with Selective Disclosure's own rule at step one (2026-08-30-c); binding-duplicate named as a fifth verdict (2026-08-30-a); and the constituent bars cited rather than counted (2026-08-26-f). *Over:* the prose's step lists, a lettered case list that skipped a letter, and a recovery path the page promised and the surface lacked. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.
- **2026-08-30 — One writer per disclosure, the purged answer first, the outcome sized before the intent, the clock at the composition's seam, the position on the code.** *Chose:* [Disclose Subset] step 4 pre-checks under the per-disclosure_id section the scan also takes and adopts an existing `ledger.disclosed` as its own outcome, with an in-invocation retry counted by `outcome_retry_attempts` and the scan the only writer thereafter; the scan runs `disclosure_to_event`'s full rebuild as a write every cycle, under a declared `reconciliation_cadence` and the inequality `disclosure_completion_bound + reconciliation_cadence + outcome_write_latency <` the shortest retention period, so the index's purged half is captured before any purge can reach its event and a lost entry is honestly a loss; step 1 sizes the maximal outcome-and-compensation envelope against `payload_cap` before the intent, with `disclosed_entry_ids_cap` and `intent_candidates_cap` bounding the two set-valued fields; now declared host-injected at this composition's seam, one reading per invocation, with the pass-through to Selective Disclosure making the pairing equality by construction and the constituent's not-in-future guard named as the one cross-seam comparison; `recording-failure(intent | outcome)` on the [Disclose Subset] signature; [Verify Ledger] branching on retention state at its index hit and on coverage status at its presentation before any composition-side membership check; and — from the closure check — the per-disclosure_id section declared as the `disclosure_section` instance capability with lease semantics (taken at step 3's return, released on return or death, a lease exactly `disclosure_completion_bound` long whose expiry is the invocation's terminus, re-taken before any pre-check and never permitting an append past the bound), the bound restated seam-to-step-4, an adopted `entry_set_unresolved` event yielding `verification_bundle = unavailable(entry-set-unresolved)`, and every remaining "atomically" replaced by the ordered three-write sequence the protocol actually runs. *Over:* a bare append at step 4 beside a scan that starts at the bound; a truth-bearing half written only by a step an invocation may never reach; "foreclosed by construction" argued about the intent while the outcome and the compensation grow without a cap; a clock attributed to a substrate that exposes none; two dispositions on one token at the caller boundary; a payload-not-supplied verdict for a payload the substrate destroyed; a critical section attributed to the host in no Configuration entry, with no release or expiry bound; and a page that said *atomically* about a sequence its own edge case calls irreversible-then-compensated. *Because:* two compensators over one act land two outcomes the seal then protects; a truth-bearing index that presumes the fact was captured is a finding-generator against a durability obligation nobody breached; an unbounded set is an input, not a construction; a reading mislocated to a constituent mislocates every stamp the composition writes; a caller who cannot tell intent from outcome re-runs a committed disclosure; lawful destruction is not omission; a section nobody declared has no lease, and a lease no bound governs blocks the leg forever; and a bundle over a set no sealed record determines proves a set the composition never recorded (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*A derived index splits at the horizon*'s truth-bearing half).
- **2026-08-29 — The scan is bounded and writes as the composition, the substrate's step decides the landing, and the seal is verified over its range.** *Chose:* a declared `disclosure_completion_bound` below which the orphan enumeration examines nothing, with the ledger horizon as its upper edge; every scan write attested under a declared recovery identity behind a `ledger.recovery_intended` record, the orphan paired to its intent by the reading step 3 now passes explicitly as `disclosed_at` (candidates named where undecidable, and an undetermined entry set omitted rather than asserted); a seam-injected `invocation_id` on every event payload so an indeterminate substrate arm is read back exactly; every transcription carrying `recording-failure(step)`, with `step-4` and the retention-source invalid-request proceeding as landed at both actions; and [Verify Ledger]'s presentation keyed by `sequence_number` over the covering range `read_record` names. *Over:* an unbounded scan under an undeclared identity, a bare token that sent [Record Entry]'s caller back to append a second entry, and a one-payload presentation that returns a mismatch on every intact ledger under interval cadence. *Because:* an unbounded scan compensates in-flight disclosures beside their own outcome events and re-manufactures lawfully purged ones; a compensation the discloser did not make cannot be attested as theirs; the substrate's step-4 arm means the event exists; and a seal commits to a range (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Recovery commits under a declared service identity*, *Intents pair with outcomes*, *A transcribed rejection arm keeps its payload*, *A seal presentation is keyed by log position*).
- **2026-08-27 — The purged binding's key lives in the composition, and the unbindable orphan gets a terminal verdict.** *Chose:* `disclosure_to_event`'s purged half is truth-bearing under a durability obligation (extraction-pending against the Erasure Tombstone atom), and a deterministic invalid-request on the outcome write lands as a `ledger.disclosure_unbindable` marker read back as `binding-unbindable`. *Over:* configuring the substrate to carry `data.disclosure_id` on its destruction record, and retrying the unbindable orphan indefinitely under the recovery identity. *Because:* the substrate declares its destruction record carries no payload field, so the earlier obligation pinned a capability on a surface that disclaims it; and re-attestation changes only the credential, so an orphan the payload or policy refuses had no lawful terminal state until one was declared.
- **2026-06-10 — Invariant 1 is safety plus liveness, and the model checks the compensated arm.** *Chose:* state the disclosure-accountability binding as "no unsurfaced orphan" (safety) and "every orphan is eventually bound or surfaced" (liveness), and re-derive the model over the two truth-bearing sub-writes so the reachable orphan is in scope. *Over:* the original model's idealization, which committed the sub-writes as one atomic action. *Because:* Selective Disclosure writes first and irreversibly and no synchronous rollback exists, so the orphan is reachable by design and an invariant that assumed it away verified nothing.

NOTE: End of Immutable Transaction Ledger with Selective Disclosure.

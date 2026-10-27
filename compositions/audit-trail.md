---
title: Audit Trail
parent: Conceptual Compositions
nav_order: 3
has_toc: true
toc: true
---

# Audit Trail

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Audit Trail answers, all at once, the four questions a regulator or investigator asks about any consequential action: what happened, who authorized it, has the record been altered, and was it kept long enough? It is a composition — a pattern built by wiring simpler patterns together, adding no new building block of its own — and it wires four of them into one record that can be searched: an add-only event log (what happened), cryptographic attribution tying each event to the person or system that performed it (who), tamper-evident sealing that makes any after-the-fact change detectable (has it been altered), and a retention policy that fixes how long records are kept (kept long enough). None of the four answers the whole question alone; wired together, each successful recording logs, attributes and places its event under retention at once, the event is then sealed on the schedule the organization running it sets, and a question about any event it recorded gets a definite answer that tells a lawfully destroyed record from a missing one.

None of the four patterns ever deletes a record of its own, which is what makes them trustworthy, so the end of a record's life is not a deletion: the composition records the lawful end of the retention period, marks on the seal that covers the record exactly which of the records the seal protects were destroyed, and hands the destruction of the stored content to the method of destruction the organization running it has declared. What survives is the proof that the record existed and was destroyed lawfully, which is what the regulator asks for.

Audit requirements for financial controls, healthcare access, cardholder data and broker-dealers rest on this structure, and other patterns in the library build on it for their own audit records.

---

## Intent

WHY:
Every regulated system carries the same obligation: when the auditor arrives, the system must answer four questions about any action of consequence — what happened, who authorized it, has the record been altered, and was the retention obligation honored — for any record, on demand, over the regulatory horizon. Each question maps onto one of four atoms. Event Log records the fact and does not bind it to an actor; Actor Identity binds the actor and does not commit to the record's integrity; Retention Window bounds the lifetime and does not detect rewriting; Tamper Evidence detects rewriting and does not name the actor. Stacked, they answer in one structure: an [Audit Record]. The four atoms are unchanged; the composition is the wiring — one consolidated audit surface rather than four record sets the auditor correlates by hand. The construction is the one every audit-grade system in production runs: signed events appended to an immutable log, sealed on a cadence against a tamper-evident structure, governed by a retention policy with a structural no-early-purge guarantee.

---

## Composes

- **[Event Log](../atoms/event-log.md)** — the append-only, totally-ordered sequence the *what happened* answer is read from. The composition's one instance is the audit log.
- **[Actor Identity](../atoms/actor-identity.md)** — the verifiable attribution the *who authorized it* answer is read from. The one instance keeps the attestation records.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime the *was the retention honored* answer is read from. The one instance, configured with the host's regulatory policy or a policy selector, keeps the retention records.
- **[Tamper Evidence](../atoms/tamper-evidence.md)** — the integrity proof the *has the record been altered* answer is read from. The one instance keeps the seal records, sealing ranges of the audit log on a configured cadence.

```
Composes 1: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 4: EXACTLY ONE Tamper Evidence instance MUST serve the composition.
Composes 4a: EVERY one of those four instances MUST serve this composition alone, so that no record another composition or a direct caller wrote enters an enumeration the composition reads.
Composes 5: The composition MUST call ActorIdentity.attest at [Record Action] step 2 alone.
Composes 6: The composition MUST call ActorIdentity.verify at [Verify Record] step 3 alone.
Composes 7: The composition MUST read an attestation's surviving fields through Actor Identity's declared read.
Composes 8: The composition MUST NOT delete an attestation.
Composes 9: The composition MUST call RetentionWindow.place_under_retention at [Record Action] step 4 and at the third half's compensating placement alone.
Composes 9a: The composition MUST NOT place a retention over an event a retention already stands over.
Composes 10: The composition MUST call RetentionWindow.purge at [Purge Event] step 1 alone.
Composes 11: [Purge Eligible] MUST read eligibility through Retention Window's declared read.
Composes 12: The composition MUST NOT evaluate an eligibility clock.
Composes 13: The composition MUST call TamperEvidence.seal from [Seal Now] alone.
Composes 14: The composition MUST call TamperEvidence.verify at [Verify Record] step 5 alone.
Composes 15: The composition MUST NOT write an entry into the seal records other than through TamperEvidence.seal.
Composes 16: The composition MUST NOT dispose of a seal.
Composes 17: The composition MUST NOT seal a range some seal covers.
```

Term audit log: the composition's Event Log instance.

Term attestation records: the records of the composition's Actor Identity instance.

Term retention records: the records of the composition's Retention Window instance.

Term seal records: the records of the composition's Tamper Evidence instance.

Term surviving fields: an attestation's attestation id, action reference, actor reference and attestation instant — Actor Identity's five-field record less the proof.

---

## Composition logic

### Composition state

Ten elements, each carrying the Contract classification of the section titled Composition state in [`execution-contract.md`](../execution-contract.md). Four are wholly derived indexes — event to retention, event to sequence, sealed through, the uncovered mark. Four split — event to attestation is derived for an event no destruction record names and extraction-pending for one a destruction record names; seal coverage is derived over ranges and carries one extraction-pending per-entry set; compensated attestations and reported beyond horizon are derived for a member taken from an event no destruction record names and extraction-pending for one a destruction record carries. Two are wholly extraction-pending — erasure outcomes, against Erasure Tombstone *(forthcoming)*, and the outage record, against Condition Register *(forthcoming)*.

Term derived index: an element regenerated from the constituent records by the element's rebuild procedure.

Term extraction-pending: an element carrying truth no constituent's records replay, classified against a named proposed atom.

Term rebuild-on-miss: a read of a derived index that runs the element's rebuild procedure on a missing entry and concludes nothing from the miss itself.

Term retention state: the state of the event's retention record — `Retained` | `Purged`; absent where no retention record exists.

Term live: an event whose retention state DOES NOT EQUAL `Purged`.

Term purged: an event whose retention state EQUALS `Purged`.

```
Composition state 1: EVERY derived index MUST sit outside every action's atomicity surface.
Composition state 2: A reader MUST consult a derived index with rebuild-on-miss.
Composition state 3: The composition MUST treat a lost derived-index entry as a rebuild trigger.
Composition state 4: The composition MUST NOT treat a lost derived-index entry as data loss.
Composition state 5: A derived index MUST NOT claim cross-constituent transactional consistency.
Composition state 6: The composition MUST NOT modify an inserted entry of an insert-only map.
Composition state 7: The composition MUST NOT remove an inserted member of a closed-state marker.
```

Term insert-only map: event to attestation, event to retention, event to sequence, and the ranges of seal coverage; a purged events set is written by the cascade and is not part of the range.

Term closed-state marker: compensated attestations and reported beyond horizon.

- **event to attestation**
  Term event to attestation: map from event id to the attestation id Actor Identity produced at record time; the auditor's traversal from an event to its attribution. The classification splits by whether the event's destruction record exists, because the rebuild's source does not survive the cascade's step 3 and the destruction record is written before it.
  ```
  event to attestation 1: [Record Action] step 5 MUST populate event to attestation with the event's event id mapped to the attestation id.
  event to attestation 2: WHEN no destruction record EXISTS for the event:
      event to attestation 2a: The composition MUST classify the entry as derived index.
      event to attestation 2b: The rebuild MUST take, for EVERY event the full enumeration returns whose data IS NOT unreadable, the event's event id as the key and the payload's attestation id as the value.
  event to attestation 3: WHEN a destruction record EXISTS for the event:
      event to attestation 3a: The composition MUST classify the entry as extraction-pending against Erasure Tombstone.
      event to attestation 3b: The destruction record MUST carry the pair (event id, attestation id).
  Deleted: event to attestation 3c. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
  ```
- **event to retention**
  Term event to retention: map from event id to the retention id Retention Window produced at record time; the policy the event is held under.
  ```
  event to retention 1: [Record Action] step 5 MUST populate event to retention with the event's event id mapped to the retention id.
  event to retention 2: The composition MUST classify event to retention as derived index.
  event to retention 3: The rebuild MUST enumerate the retention records and re-key each retention record by the record's record reference.
  ```
- **event to sequence**
  Term event to sequence: map from event id to the sequence number Event Log assigned at append; the index that makes id-addressed reads possible.
  ```
  event to sequence 1: [Record Action] step 5 MUST populate event to sequence with the event's event id mapped to the sequence number.
  event to sequence 2: The composition MUST classify event to sequence as derived index.
  event to sequence 3: The rebuild MUST re-key EVERY event the full enumeration returns by the event's own event id.
  event to sequence 4: [Read Record], [Verify Record] and [Purge Event] MUST resolve a caller-supplied event id through event to sequence.
  event to sequence 5: An id-addressed action MUST read the event by EventLog.read over the singleton range at the resolved sequence number.
  event to sequence 6: The composition MUST NOT ask EventLog.read to select on event id.
  event to sequence 7: The composition MUST NOT ask EventLog.read for a payload predicate.
  ```
- **seal coverage**
  Term seal coverage: for each evidence id in the seal records, the contiguous sequence-number range the seal commits to as [Seal Now] cut it, plus a per-entry purged events set the cascade writes; what tells the verifier which record set to present.
  ```
  seal coverage 1: [Seal Now] MUST populate seal coverage with the evidence id mapped to the sealed slice.
  seal coverage 2: The composition MUST classify the ranges of seal coverage as derived index.
  seal coverage 3: The rebuild of the ranges MUST enumerate the seal records and read each evidence record's record set reference.
  seal coverage 4: The rebuild of the ranges MUST NOT issue EventLog.read.
  seal coverage 5: A coverage range MUST key on sequence number.
  seal coverage 6: A coverage range MUST NOT key on event id.
  seal coverage 7: Two coverage ranges MUST NOT overlap.
  seal coverage 8: A coverage range MUST NOT carry a hole.
  seal coverage 9: The composition MUST classify purged events as extraction-pending against Erasure Tombstone.
  seal coverage 10: The cascade MUST record the records-purged fact at event granularity.
  seal coverage 11: The cascade MUST NOT flag a whole seal coverage entry as purged.
  Deleted: seal coverage 12. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
  seal coverage 13: The slice reference MUST encode the slice's first and last sequence number.
  seal coverage 14: The slice reference MUST carry the count of events the slice holds.
  ```
  Term purged events: the set of sequence number values within one seal's range that a cascade's destruction record has added (purge event step 2.2), each added before the cascade delegates the destruction of the event's content (purge event step 2.4).

  Term covering seal: the evidence id whose seal coverage range contains the event's sequence number.

- **erasure outcomes**
  Term erasure outcomes: for each event over which [Purge Event] step 3 has issued its delegation, the outcome the configured erasure mechanism reported: destroyed or `destruction-failed(reason)`.
  ```
  erasure outcomes 1: The cascade MUST record the mechanism's reported outcome in erasure outcomes for EVERY delegation [Purge Event] step 3 issues.
  erasure outcomes 2: erasure outcomes MUST address an outcome per event id.
  erasure outcomes 3: The composition MUST classify erasure outcomes as extraction-pending against Erasure Tombstone.
  erasure outcomes 4: The outcome record MUST land under the event id alone AND MUST NOT rewrite the covering seal's purged events.
  Deleted: erasure outcomes 5. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
  erasure outcomes 6: A destruction-failed record MUST NOT close an entry.
  ```
  Term closed entry: an erasure outcomes entry among whose records a destroyed outcome exists.

  Term open entry: an erasure outcomes entry that is not a closed entry; open for re-driving.

- **sealed through**
  ```
  sealed through 1: The composition MUST classify sealed through as derived index.
  sealed through 2: The rebuild MUST compute sealed through from the rebuilt ranges of seal coverage.
  ```
  Term sealed through: the maximum sequence number over all seal coverage ranges; zero for empty seal records.

  Term unsealed tail: the events whose sequence number EXCEEDS sealed through.
- **uncovered mark**
  Term uncovered mark: set | clear | unknown — one record per instance, kept apart from the sealing lock's grant, which [Seal Now] sets before its seal call (seal now 4) with its holder value and clears once the coverage entry has landed, by a compare under [Seal Now]'s live lease (seal now 15, 22, 23), and leaves set where that lease expires before the clear or the seal call or the coverage write gives no answer (seal now 19, 24). The one fact it carries, whether a seal may stand in the seal records without its coverage entry, is regenerated from the seal records: a set or unknown mark sends the next [Seal Now] to rebuild the ranges from the seal records before it reads sealed through, and that rebuild lets it clear the mark (seal now 13, 16).
  ```
  uncovered mark 1: The composition MUST classify the uncovered mark as derived index.
  uncovered mark 2: The rebuild MUST leave the uncovered mark unknown (Concurrency 1b, seal now 13, seal now 16).
  ```
- **compensated attestations**
  Term compensated attestations: the set of attestation id values for which an `audit.compensation` event has been recorded; the closed-state marker for orphan reconciliation.
  ```
  compensated attestations 1: The composition MUST classify a member taken from an audit.compensation event no destruction record names as derived index.
  compensated attestations 1a: The composition MUST classify a member taken from the destruction record of a purged audit.compensation event as extraction-pending against Erasure Tombstone.
  compensated attestations 2: The rebuild MUST keep, from the full enumeration, EVERY event no destruction record names whose action reference EQUALS audit.compensation AND whose payload subject EQUALS attestation, and take the attestation id each payload names.
  compensated attestations 2a: The rebuild MUST take the attestation id from EVERY destruction record whose action reference EQUALS audit.compensation AND whose subject EQUALS attestation.
  compensated attestations 3: The rebuild MUST filter on the subject-kind discriminator.
  compensated attestations 4: The rebuild MUST filter in composition code.
  compensated attestations 5: A deployment composing Reverse Index MAY filter through Reverse Index as an instance optimization.
  Deleted: compensated attestations 6. compensated attestations 2 owns it.
  ```
  Term reconciled: an orphan whose attestation id is a member of compensated attestations.

- **reported beyond horizon**
  Term reported beyond horizon: the set of attestation id values for which the scan's second half has recorded a *beyond the horizon* finding; the closed-state marker for that report.
  ```
  reported beyond horizon 1: The composition MUST classify a member taken from a beyond-horizon report no destruction record names as derived index.
  reported beyond horizon 1a: The composition MUST classify a member taken from the destruction record of a purged beyond-horizon report as extraction-pending against Erasure Tombstone.
  reported beyond horizon 2: The rebuild MUST keep, from the full enumeration, EVERY event no destruction record names whose action reference EQUALS audit.reconciliation AND whose payload subject EQUALS attestation AND whose payload disposition EQUALS beyond-horizon, and take the attestation id each names.
  reported beyond horizon 2a: The rebuild MUST take the attestation id from EVERY destruction record whose action reference EQUALS audit.reconciliation AND whose subject EQUALS attestation AND whose disposition EQUALS beyond-horizon.
  Deleted: reported beyond horizon 3. reported beyond horizon 2 owns it.
  ```
- **outage record**
  Term outage record: for each dependency outage, the dependency, the outage's start instant and end instant and the rule that joined its failures (Composition-level invariant 1d, 1f); for each suspended entry, the instant of each run that landed the entry under-legal-hold and of the hold-free run after it (Composition-level invariant 1h) — what an auditor reads a late closure against.
  ```
  outage record 1: The composition MUST classify the outage record as extraction-pending against Condition Register.
  outage record 2: The deployment MUST NOT modify an entry of the outage record once written.
  Deleted: outage record 3. Execution Contract Database 3 and Execution Contract Database 4 own it.
  ```

### Capability requirement

```
Deleted: Capability requirement 1. Event Log Invariant 5.1 owns it: under Event Log's Term query a sequence-number range carrying no upper end holds its lower end and everything above it, so every conforming Event Log instance answers the open-upper-bound read.
Capability requirement 2: The deployment MUST alert on invalid-query from a composition-built query as a deployment fault.
Capability requirement 3: The composition MUST NOT surface invalid-query from a composition-built query as an outcome of any action.
Capability requirement 3a: The composition MUST land an invalid-query from a composition-built query where a failed read of that query lands.
Deleted: Capability requirement 4. Execution Contract Database 3 owns it.
Deleted: Capability requirement 4a. Execution Contract Database 3 owns it.
Capability requirement 5: The deployment MUST supply record set match at TamperEvidence's seam from the presented record set and the evidence's record set reference.
Capability requirement 6: The deployment MUST judge record set match against the record set reference the seal committed to.
Capability requirement 6a: IF the presented record set's count of events DOES NOT EQUAL the count the slice reference carries THEN the deployment MUST answer record set match no.
Capability requirement 6b: The deployment MUST NOT answer record set match no on a ground other than Capability requirement 6a.
Capability requirement 7: WHEN Legal Hold EQUALS composed:
    Capability requirement 7a: The deployment MUST serialize a hold placement over an event id with the per-act critical section keyed by that event id.
    Capability requirement 7b: The deployment MUST read hold from the Legal Hold database instance wired to this instance.
    Capability requirement 7c: A hold placement MUST hold the critical section as a lease of purge completion bound.
    Capability requirement 7d: A hold placement MUST NOT issue a write after the lease has expired.
    Capability requirement 7e: A hold placement that finds the critical section held MUST wait for the lease's instant or the holder's release.
    Deleted: Capability requirement 7f. Execution Contract Database 2 owns it: a hold placement's re-read, lease check and write are one transaction, and a hold placement makes no abandoned call for Per-act critical section 2a to bind.
    Capability requirement 7g: The deployment MUST place a hold over an event id of this instance through a hold placement alone.
    Capability requirement 7h: A deployment whose regime orders the preservation of audit records MUST set Legal Hold to composed.
Capability requirement 8: The deployment MUST supply content readable at the seam of EventLog.read and of Actor Identity's declared read, for EVERY event and EVERY attestation the read answers.
Capability requirement 9: The deployment MUST wire a Retention Window instance whose purge is the state transition alone, the composition owning the destruction (Boundary one 2, Retention Window Record divergence 4).
Capability requirement 10: The deployment MUST supply, at TamperEvidence.verify's seam, the cryptographic material of the mechanism that cut the seal.
Capability requirement 10a: The deployment MUST record, for EVERY evidence id, the mechanism that cut the seal, for the life of the seal record.
Capability requirement 11: The deployment MUST supply at start the retention period of the resolved policy for an audit.compensation reference and for an audit.reconciliation reference.
Capability requirement 12: The deployment MUST supply the alerting surface on which EVERY compliance alert and EVERY deployment fault is surfaced.
Capability requirement 13: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

Term Legal Hold: composed | absent — whether the deployment composes the [Legal Hold](../atoms/legal-hold.md) pattern over this instance; a knob, set by Capability requirement 7h. *Default:* absent.

Term hold placement: the deployment's own call of Legal Hold's place over an event id of this instance, made under the per-act critical section as Capability requirement 7 states it — a deployment facility, as the scan scheduler is, and no action of this composition (Non-goal 15).

Term open-upper-bound read: `EventLog.read` over a sequence-number range beginning at a given sequence number with no upper bound.

Term record set match: yes | no — the host's answer, at Tamper Evidence's seam, to whether the record set [Verify Record] step 5 re-presents is the record set the evidence's record set reference names, judged by the count of events the slice reference carries (Capability requirement 6a, 6b), so that a presentation of that count answers yes whatever its content and TamperEvidence.verify judges the content; Tamper Evidence cannot judge it (its Capability requirement 5, Operation 22b), and a no surfaces as `failed-verification(seal-record-set-mismatch)` (verify record step 5.2).

Term content readable: yes | no — the host's answer, at the seam of Event Log's read and of Actor Identity's read, to whether a returned event's data field, or a returned attestation's proof, can be read; neither atom's read declares it (Event Log State 2, Actor Identity Operation 28), and a conforming erasure mechanism is the one thing that turns it to no (erasure mechanism 6a, 6b, 6c).

Term unreadable: a data field or a proof for which content readable EQUALS no.

Term retention period: the duration a policy carries, resolved from the policy reference at the seam as the wired Retention Window instance resolves it for its placement (Retention Window State 5); the policy reference itself is opaque.

Term full enumeration: the open-upper-bound read beginning at sequence 1.

Term composition-built query: the open-upper-bound read, the singleton range read of event to sequence 5, and the hold read of purge event 5c — queries the composition builds from its own indexes and from an event id a constituent already knows, which no unvalidated caller input reaches.

WHY:
Twenty-one knobs — Legal Hold among them, declared with the capability it switches (Capability requirement 7, 7h) — and five instance capability requirements: the per-act critical section, here, the sealing lock (Concurrency 1), the scan scheduler (reconciliation cadence 6), for an interval-based cadence the cadence driver (seal cadence 4) and, where Legal Hold is composed, the hold placement (Capability requirement 7). Each knob carries a type, a default and a setting rule; every default of *none* is deployment-required, and the section titled *Instance start* is the one owner of what an instance refuses to start without. A constituent's own capability requirements bind the deployment that wires its instance, and a requirement above restates one only where it adds to it, as Capability requirement 5 and 10 do at Tamper Evidence's seam (Execution Contract Conformance 8).

- **retention policy**
  Term retention policy: a Retention Window policy reference, or a policy selector `(action_ref, actor_ref, data) → policy_ref` for content-derived rules. *Default:* none.
  ```
  retention policy 1: The deployment MUST set retention policy to the reconciled policy for the record class.
  retention policy 2: [Record Action] step 4 MUST place the retention under the resolved policy.
  retention policy 3: EXACTLY ONE retention record MUST govern an audit event and the event's attestation.
  retention policy 4: The composition MUST NOT hold an attestation meta-retention policy.
  retention policy 5: The composition MUST retain a seal indefinitely.
  retention policy 6: The deployment MUST set retention policy so that retention policy's answer for an audit.compensation reference and for an audit.reconciliation reference does not vary with the payload.
  retention policy 7: A change to retention policy for an audit.compensation or an audit.reconciliation reference MUST NOT take effect BEFORE Instance start 21 and Instance start 22 have passed against the change.
  ```
  Term reconciled policy: the longest applicable retention across every regulation in force, the strictest data-minimization posture, and any conflicting destruction rules reconciled — produced by a Policy Reconciliation pattern *(forthcoming)*.

  Term resolved policy: retention policy where the knob is a policy reference; the policy reference the selector returns where the knob is a selector.

- **seal cadence**
  Term seal cadence: `per-event` | interval-based | on-demand; an interval-based cadence carries an events arm (every N events), a time arm (every T seconds), or both. *Default:* none.
  ```
  seal cadence 1: The deployment MUST set seal cadence from the forensic window the deployment's regime tolerates.
  seal cadence 2: A deployment whose auditor requires a bounded per-event tampering window MUST set per-event.
  seal cadence 3: A per-event seal that failed at step 6 MUST stand as the alert of record action step 6.5 until a later [Record Action], [Purge Event] or [Seal Now] seals the event.
  NOTE: open 2026-10-25-b — under per-event cadence a failed step-6 seal on a log that then goes quiet stands until a later action seals the event, and no rule obliges one (seal cadence 3, record action step 6.6).
  seal cadence 4: IF seal cadence EQUALS interval-based THEN the deployment MUST supply a cadence driver that fires on the time arm and the events arm, survives the loss of any one process, and fires at start and at restart.
  seal cadence 5: The events arm MUST count the log tail less sealed through.
  ```
  Term cadence driver: the host facility that calls [Seal Now] per an interval-based seal cadence.

  Term time arm: the every-T-seconds arm of an interval-based seal cadence.

- **seal mechanism**
  Term seal mechanism: a Tamper Evidence mechanism reference: hash chain, Merkle tree, RFC 3161-anchored timestamp (RFC 3161, Request for Comments 3161: the Internet Engineering Task Force's Time-Stamp Protocol). *Default:* none.
  ```
  seal mechanism 1: The deployment MUST select a mechanism sound for the full audit horizon.
  seal mechanism 2: A deployment requiring the forensic-window bound of Check 4 MUST select a chained mechanism.
  seal mechanism 3: The deployment MUST set seal mechanism to the mechanism the wired Tamper Evidence instance runs.
  seal mechanism 4: The deployment MUST alert on a disagreement between seal mechanism and the wired instance's mechanism as a deployment fault.
  seal mechanism 5: The mechanism's seal-time rendering MUST match the verify-time presentation.
  seal mechanism 6: The deployment MUST declare the agreement of seal mechanism 5.
  ```
  Term chained mechanism: a mechanism under which each seal commits to its predecessor.

  Term verify-time presentation: the payloads of every event in the covering seal's range, byte-exact, in ascending sequence number order — no re-serialization, key reordering or encoding fixup.

- **mechanism credential**
  Term mechanism credential: opaque credential material passed to `TamperEvidence.seal` on every seal, whatever the cadence: a signing key for a keyed mechanism, a TSA (Time-Stamp Authority — a trusted third party that signs proofs of when data existed) client credential for an anchored one. *Default:* empty (unkeyed).
  ```
  mechanism credential 1: The composition MUST pass mechanism credential to TamperEvidence.seal on every seal.
  mechanism credential 2: The composition MUST pass mechanism credential through unchanged.
  mechanism credential 3: The composition MUST NOT inspect mechanism credential.
  mechanism credential 4: The composition MUST NOT log mechanism credential.
  mechanism credential 5: IF mechanism class DOES NOT EQUAL unkeyed THEN the deployment MUST set mechanism credential.
  mechanism credential 6: IF mechanism class EQUALS unkeyed THEN the deployment MUST NOT set mechanism credential.
  mechanism credential 7: A deployment requiring non-repudiation of the seal MUST set a credential whose nature supplies non-repudiation.
  mechanism credential 8: IF mechanism credential EQUALS blank THEN the composition MUST pass an empty credential.
  ```
  Term mechanism class: unkeyed | keyed | anchored.

- **unsealed tail mode**
  Term unsealed tail mode: strict | lenient: what [Verify Record] returns for an event in the unsealed tail. *Default:* strict.
  ```
  unsealed tail mode 1: A deployment MAY set lenient ONLY IF independently trusted substrate EXISTS AND standing false negative EXISTS.
  unsealed tail mode 2: A regulated deployment MUST NOT set lenient.
  NOTE: watch applicability — the source's setting rules read *where X, do Y*; the applicability is carried in the subject here (unsealed tail mode 2, seal mechanism 2, reference length cap 3, mechanism credential 7).
  unsealed tail mode 3: IF unsealed tail mode EQUALS blank THEN the instance MUST take strict.
  ```
  Term independently trusted substrate: a log substrate trusted apart from this composition's seals — WORM (write once, read many) storage, an external replica.

  Term standing false negative: the strict unsealed tail mode answering `failed-verification(unsealed)` for the whole of a coarse cadence interval.

- **erasure mechanism**
  Term erasure mechanism: a reference to the deployment's composed content-destruction mechanism, invoked at [Purge Event] step 3. *Default:* none.
  ```
  erasure mechanism 1: The deployment MUST wire an erasure mechanism that shreds.
  erasure mechanism 2: The deployment MUST NOT wire a tombstone-by-mutation mechanism.
  erasure mechanism 3: The erasure mechanism MUST destroy the readability of the whole of Event Log's data field.
  erasure mechanism 4: The erasure mechanism MUST destroy the readability of the attestation's proof.
  erasure mechanism 5: The erasure mechanism MUST NOT rewrite a stored field.
  erasure mechanism 6: The erasure mechanism MUST leave the attestation's surviving fields readable.
  erasure mechanism 6a: The erasure mechanism MUST leave Event Log's read returning EVERY event, the data field unreadable where destroyed.
  erasure mechanism 6b: The erasure mechanism MUST leave Actor Identity's read answering the surviving fields, the proof unreadable where destroyed.
  erasure mechanism 6c: The erasure mechanism MUST NOT leave an event's data field unreadable unless the erasure mechanism destroyed the data field.
  erasure mechanism 7: The erasure mechanism MUST report EXACTLY ONE OF destroyed, destruction-failed(reason) for EVERY event the mechanism is asked about.
  erasure mechanism 7a: IF the content the mechanism is asked about has already been destroyed THEN the mechanism MUST report destroyed.
  erasure mechanism 8: The erasure mechanism MUST name the event id in EVERY outcome.
  erasure mechanism 9: The deployment MUST evidence the mechanism's class to the auditor outside the records.
  erasure mechanism 10: The erasure mechanism MUST report destroyed for EVERY event a cascade delegates WITHIN compensation window of the finding's creation.
  NOTE: watch satisfaction (erasure mechanism 10).
  ```
  Term tombstone-by-mutation: overwriting, blanking or truncating a stored field in place.

  Term Event Log's data field: the whole constructed object `{action_ref, actor_ref, attestation_id, data}` [Record Action] step 3 appends; the caller-supplied data is one member inside it.

- **compensation window**
  Term compensation window: the duration within which the liveness arms of Invariants 1, 2 and 8 close: an orphan attestation, an unretained event or a half-completed cascade is surfaced and reconciled inside it. *Default:* none.
  ```
  compensation window 1: The deployment MUST set compensation window from the tightest reconciliation deadline the deployment's regime imposes.
  compensation window 2: The composition MUST measure compensation window from the finding's creation.
  compensation window 3: The composition MUST NOT measure compensation window from the finding's detection.
  compensation window 4: An auditor MUST read the quiescence condition of Check 2 from compensation window.
  ```
  Term finding's creation: the orphan attestation's attestation instant; the unretained event's recording instant; the half-completed cascade's purge instant.

- **reconciliation cadence**
  Term reconciliation cadence: how often the reconciliation scan runs, measured from one run's start to the next's. *Default:* the time arm of seal cadence where that cadence carries one; none otherwise.
  ```
  reconciliation cadence 1: The reconciliation scan MUST run PER reconciliation cadence.
  reconciliation cadence 1a: A run MUST start no later than reconciliation cadence after the previous run's start.
  reconciliation cadence 2: The reconciliation scan MUST run at restart.
  reconciliation cadence 3: IF time arm EQUALS blank THEN the deployment MUST set reconciliation cadence.
  reconciliation cadence 4: IF time arm DOES NOT EQUAL blank AND reconciliation cadence EQUALS blank THEN the instance MUST take the time arm as reconciliation cadence.
  reconciliation cadence 5: reconciliation cadence MUST govern all three halves of the scan.
  reconciliation cadence 6: The scan scheduler MUST start the next run no later than reconciliation cadence after the previous run's start WHEN the process that ran the previous run has died.
  ```
  Term scan scheduler: the host facility that starts scan runs and survives the loss of any one process serving the instance.
- **reconciliation operator**
  Term reconciliation operator: an actor reference: the deployment's maintenance actor authorized to record under the reserved `audit.*` namespace; the discriminator [Record Action] step 1's namespace gate turns on. *Default:* none.
  ```
  reconciliation operator 1: The deployment MUST provision reconciliation operator as an actor in the wired attestation records with usable credential material.
  reconciliation operator 2: [Record Action] step 1 MUST decide the reconciliation path by actor reference EQUALS reconciliation operator, byte-identity.
  ```
- **reconciliation operator credential**
  Term reconciliation operator credential: opaque credential material for the actor reconciliation operator names. *Default:* none.
  ```
  reconciliation operator credential 1: The scan MUST hand reconciliation operator credential to ActorIdentity.attest on EVERY reconciliation-path write.
  reconciliation operator credential 2: The composition MUST NOT inspect reconciliation operator credential.
  reconciliation operator credential 3: The composition MUST NOT log reconciliation operator credential.
  reconciliation operator credential 4: The composition MUST NOT write reconciliation operator credential into a payload.
  ```
- **payload cap**
  Term payload cap: the byte ceiling [Record Action] step 1 checks the full constructed payload against. *Default:* none.
  ```
  payload cap 1: The deployment MUST set payload cap to the wired Event Log instance's own configured cap.
  payload cap 2: [Record Action] step 1 MUST measure the serialized envelope against payload cap.
  payload cap 3: [Record Action] step 1 MUST NOT measure the sum of the members' own lengths.
  payload cap 4: The deployment MUST alert on invalid-payload at [Record Action] step 3 as a deployment fault.
  ```
  Term serialized envelope: the byte length of Event Log's data field exactly as handed to `EventLog.append`, in the encoding the wired instance sizes it in, framing and field names included.

- **reference length cap**
  Term reference length cap: a byte length, applied independently to action reference and actor reference at [Record Action] step 1. *Default:* 1 KB (kilobyte) each.
  ```
  reference length cap 1: [Record Action] step 1 MUST apply reference length cap to action reference and to actor reference independently.
  reference length cap 2: reference length cap MUST NOT EXCEED reference headroom.
  reference length cap 3: A deployment MAY raise reference length cap above 1 kilobyte ONLY IF a genuine reference scheme EXCEEDS 1 kilobyte.
  reference length cap 4: IF reference length cap EQUALS blank THEN the instance MUST take 1 kilobyte.
  ```
  Term reference headroom: `((payload_cap - attestation_id_width) - the largest data the deployment intends to accept)`.

- **attestation id width**
  Term attestation id width: the width of the attestation id the configured Actor Identity instance allocates. *Default:* none.
  ```
  attestation id width 1: The deployment MUST set attestation id width to the maximum width the wired Actor Identity instance allocates.
  attestation id width 2: [Record Action] step 1 MUST size the payload with attestation id width.
  ```
- **record action completion bound**
  Term record action completion bound: the longest a [Record Action] may take between its first write (step 2's attestation, stamped attestation instant at Actor Identity's seam) and its last (step 5's index writes). *Default:* none.
  ```
  record action completion bound 1: The deployment MUST set record action completion bound from the observed worst-case latency of [Record Action] steps 2 through 5 with headroom, constituent round-trips included.
  record action completion bound 2: The deployment MUST include in record action completion bound twice the call pause bound (Lease Sizing 4).
  ```
- **purge completion bound**
  Term purge completion bound: the longest a [Purge Event] may take between taking the per-act critical section and step 3's outcome record, step 0 included. *Default:* none.
  ```
  purge completion bound 1: The deployment MUST set purge completion bound from the observed worst-case latency of [Purge Event] steps 0 through 3 with headroom, the erasure mechanism's round-trip included.
  purge completion bound 2: The deployment MUST include in purge completion bound twice the call pause bound (Lease Sizing 4).
  ```
- **seal completion bound**
  Term seal completion bound: the longest a [Seal Now] may take between taking the sealing lock and the coverage entry of seal now 5, the mechanism's round-trip included. *Default:* none.
  ```
  seal completion bound 1: The deployment MUST set seal completion bound from the observed worst-case latency of a [Seal Now] over a slice of slice cap events, from taking the sealing lock to the coverage entry of seal now 5, with headroom, the rebuild of seal now 13 and the clear of seal now 23 included.
  seal completion bound 2: The deployment MUST include in seal completion bound twice the call pause bound (Lease Sizing 4).
  ```
- **slice cap**
  Term slice cap: the most events one seal covers. *Default:* none.
  ```
  slice cap 1: The deployment MUST set slice cap to a count of events one [Seal Now] seals inside seal completion bound.
  slice cap 2: The count of events one slice holds MUST NOT EXCEED slice cap.
  ```
- **call pause bound**
  Term call pause bound: this composition's value of [Lease](../atoms/lease.md)'s call pause bound: the longest time from a holder's decision to issue one call — a lease take, a lease check, a write to a constituent, a delegation to the erasure mechanism, never a whole [Record Action] — to the moment the call has taken effect or failed. *Default:* none.
  ```
  call pause bound 1: The deployment MUST set call pause bound from the observed worst-case latency of a host or constituent call with headroom.
  call pause bound 2: The deployment MUST declare EVERY completion bound as exceeding twice call pause bound.
  ```
- **compensation closure latency**
  Term compensation closure latency: the deployment's disclosed bound on one whole closure landing, from the moment a scan run starts to the moment the closure's last record has landed, the run's enumeration before it reaches the act included. *Default:* none.
  ```
  compensation closure latency 1: The deployment MUST declare compensation closure latency as the bound on one whole closure.
  compensation closure latency 2: The deployment MUST include in compensation closure latency the call pause bound.
  compensation closure latency 3: The deployment MUST include in compensation closure latency EVERY enumeration a run performs before the run reaches an act.
  compensation closure latency 4: The deployment MUST include in compensation closure latency one record action completion bound for the probe of Invariant 1.10.
  ```
  Term whole closure: for the second and third halves, the `audit.reconciliation` intent, the compensating act and the `audit.compensation` record — three writes, each an attest-append-place across three constituents' records or a retention placement; for the first half, a re-driven cascade, the erasure mechanism's round-trip included.

- **clock offset allowance**
  Term clock offset allowance: the most the composition's seam clock and any constituent's seam clock may differ. *Default:* none.
  ```
  clock offset allowance 1: The deployment MUST set clock offset allowance from the deployment's clock discipline.
  clock offset allowance 2: The scan MUST widen EVERY comparison of now with a constituent-stamped time by clock offset allowance.
  clock offset allowance 3: The scan MUST NOT decide a write by a cross-seam comparison alone.
  clock offset allowance 4: A cross-seam comparison MUST exclude a record from the pass and nothing more.
  ```
- **Per-act critical section** — an instance capability requirement, not a knob: a per-key mutual exclusion the host supplies, keyed by an act's id — the attestation id [Record Action] step 2 returns for a record action, the event id for a cascade. *Default:* none.
  ```
  Per-act critical section 1: The host MUST supply the per-key critical section as a Lease keyed by the act's id.
  Per-act critical section 1a: The host MUST namespace a critical section's key by the act's kind.
  Per-act critical section 1b: The host MUST share the critical section across EVERY process serving the instance.
  Per-act critical section 1c: A holder MUST present a holder value minted fresh for EVERY attempt.
  NOTE: watch the fresh holder value (Per-act critical section 1c).
  Per-act critical section 1d: The composition MUST bind Lease Sizing 1 through 9, with call pause bound as the atom's call pause bound and EVERY completion bound, the scan leg's budget and the half's work bound as the atom's work bounds.
  Per-act critical section 2: The host MUST release the critical section ONLY on the holder's release or at the lease's instant.
  Per-act critical section 2a: A holder that abandoned a call MUST NOT release the critical section BEFORE the lease's instant.
  Per-act critical section 2b: A holder MUST release the critical section on return WHEN the holder abandoned no call.
  Per-act critical section 3: The host MUST NOT release the critical section on a belief that the holder has died.
  Per-act critical section 4: The host MUST end the critical section at the lease's instant WHEN the holder has not returned.
  Per-act critical section 5: A leg that finds an act's critical section held MUST skip the act for the rest of the run.
  Per-act critical section 6: A leg MUST NOT block on a held critical section.
  Per-act critical section 7: IF no held critical section EXISTS THEN the cascade MUST NOT issue a later truth-bearing write.
  NOTE: watch condition negation — *not holding the critical section* is written as a minted term that no instance EXISTS of (Per-act critical section 7, Per-act critical section 8, Invariant 6.3).
  Per-act critical section 8: IF no held critical section EXISTS THEN the cascade MUST NOT land a later truth-bearing write.
  Per-act critical section 9: The host MUST hold a cascade's critical section as a lease:
      Per-act critical section 9a: The host MUST set the lease to the act's completion bound.
      Per-act critical section 9b: IF lease EQUALS expired THEN the invocation MUST NOT issue a truth-bearing write.
  Deleted: Per-act critical section 9c. Execution Contract Database 1 owns it.
  Deleted: Per-act critical section 10. Lease Invariant 3.2 owns it.
  Deleted: Per-act critical section 10a. Lease Invariant 3.2 owns it.
  Deleted: Per-act critical section 10b. Lease Invariant 3.2 owns it.
  Deleted: Per-act critical section 10c. Lease Invariant 3.2 owns it.
  Deleted: Per-act critical section 10d. Lease Invariant 3.2 owns it.
  Deleted: Per-act critical section 10e. Lease Invariant 3.2 owns it.
  Per-act critical section 11: A writer without the critical section MUST NOT read a pre-check BEFORE re-taking the critical section.
  Per-act critical section 12: A writer MUST re-read the pre-check under the re-taken critical section.
Per-act critical section 13: The host MUST hold a scan leg's critical section as a lease:
    Per-act critical section 13a: The host MUST set a scan leg's lease to compensation closure latency less the time the run has spent before the take, measured at the scan's own seam, less call pause bound (Lease Sizing 6).
    Per-act critical section 13b: IF a leg's lease EQUALS expired THEN the leg MUST NOT issue a further write.
    Per-act critical section 13c: A leg whose lease EQUALS expired MUST skip the act for the rest of the run.
    Per-act critical section 13d: IF that remainder DOES NOT EXCEED the half's work bound THEN the leg MUST NOT take the critical section AND MUST skip the act for the rest of the run.
    Per-act critical section 13e: A skip under 13d, a leg stopped by an expired lease under 13b or a run in which an enumeration took longer than measured enumeration MUST surface a compliance alert as a deployment fault AND the deployment MUST re-declare compensation closure latency AND the instance MUST re-run Instance start 16, 18, 19 and 28.
    Deleted: Per-act critical section 13f. Execution Contract Database 2 owns it: a leg's re-read, lease check and write are one transaction, and the composition names no margin for a [Record Action] to start on.
    Deleted: Per-act critical section 13h. Execution Contract Database 2 owns it.
    Deleted: Per-act critical section 13g. Execution Contract Database 2 owns it: a leg's re-read, lease check and write are one transaction, and the composition names no start for a leg to decline.
    Per-act critical section 13i: IF a re-run of Instance start 16, 18, 19 or 28 fails on a running instance THEN the deployment MUST surface a compliance alert as a deployment fault until a re-declaration passes the failed check AND the instance MUST go on accepting [Record Action].
Per-act critical section 14: A [Purge Event] re-driven by the first half MUST NOT take a second critical section for an event id the first half holds.
Per-act critical section 15: A cascade and a scan leg MUST take the critical section by Lease's try_take, a [Purge Event] re-driven by the first half excepted (Per-act critical section 14).
Per-act critical section 15a: A hold placement MUST take the critical section by Lease's take, waiting no longer than the atom's arrival term.
Per-act critical section 15b: IF a hold placement's take answers unavailable OR no answer THEN the placement MUST NOT write AND MUST report not placed to the placement's caller.
Per-act critical section 15c: The composition MUST declare compensation closure latency as the longest duration of a take on a per-act critical section AND seal completion bound as the longest on the sealing lock (Lease Composition note 5d).
Per-act critical section 16: IF a `take`, `try_take`, `remaining` or `release` on a lease this composition takes — the per-act critical section, the sealing lock — answers no answer THEN the holder MUST treat the lease as expired for the rest of the grant (Lease Sizing 7).
Per-act critical section 17: A holder MUST NOT re-issue, within the holder's lease, a call that answered no answer (Lease Sizing 8).
  ```
  Term act's completion bound: purge completion bound for a cascade.

  Term act's kind: a cascade or a record action — the kind Per-act critical section 1a namespaces a key by. A cascade's key is the event id, taken by [Purge Event] (purge event step 0.6), by the first half for the cascade it re-drives (First half 6, Per-act critical section 14) and by a hold placement (Capability requirement 7a); a record action's key is the attestation id [Record Action] step 2 returns, taken by the second half for an orphan (Second half 9) and by the third half for an unretained event (Third half 5).

  Term lease: live or expired as [Lease](../atoms/lease.md) Sizing 2 reads it, a remaining that answers none or no answer included.

  Term abandoned call: a delegation to the erasure mechanism that the holder issued and stopped waiting for without an answer, whose destruction may still take effect inside the lease — never a call to a database, whose write lands under the holder's lease or not at all (Capability requirement 13).

  Term no answer: as [Lease](../atoms/lease.md) declares it: a call with neither answer nor refusal inside call pause bound, or, for a blocking take, inside the longest duration declared for the key and call pause bound (Per-act critical section 15c); the lost answer of Execution Contract Error model 1, whose caller cannot tell whether the call landed.

  Term work bound: closure floor plus one measured enumeration for the second half — the one enumeration under the section of Second half 17 — and two for the third half, the audit-log enumeration that reads narrated and the retention-record enumeration of a true miss in event to retention (Third half 6); purge completion bound for the first half.

  Term holder: the party the critical section is held by; a cascade, a hold placement, a scan half, or a [Seal Now]; its bound is purge completion bound for a cascade and for a hold placement, and compensation closure latency less the run's elapsed time at the take and call pause bound for a scan leg.

  Term held critical section: the act's critical section with the invocation as holder, or, for a [Purge Event] re-driven by the first half, with the first half as holder (Per-act critical section 14).

  Term later truth-bearing write: a truth-bearing write after the invocation's first write.

  Term truth-bearing write: a write to a constituent's records — steps 2–4 of a record action, steps 1–3 of a cascade; the index writes of step 5 are not truth-bearing.

  Term pre-check: the read a writer makes under the critical section before writing — compensated attestations, reported beyond horizon, narrated, event to retention, the destruction record, a destroyed outcome in erasure outcomes, or the first half's predicate.

### Primitive policy

The composition takes four caller-supplied inputs at [Record Action], one at each id-addressed surface, and one more at [Verify Record]. Each is validated at this layer or by a named constituent; nothing is normalized anywhere.

```
Primitive policy 1: action reference MUST stand non-blank.
Primitive policy 2: actor reference MUST stand non-blank.
Primitive policy 3: [Record Action] step 1 MUST validate action reference and actor reference at this layer.
Primitive policy 4: [Record Action] MUST NOT call a constituent BEFORE step 1 completes.
Primitive policy 5: [Record Action] step 1 MUST land invalid-request(step-1) for a malformed reference, with nothing recorded.
Primitive policy 6: The composition MUST NOT normalize any input.
Primitive policy 7: The composition MUST compare references by byte-identity.
Primitive policy 8: [Record Action] step 1 MUST land invalid-request(step-1) for an action reference whose bytes begin with the prefix audit. from a caller whose actor reference DOES NOT EQUAL reconciliation operator, with nothing recorded.
Primitive policy 9: The reconciliation path MAY record under the reserved namespace ONLY IF the action reference EQUALS audit.compensation OR the action reference EQUALS audit.reconciliation.
Primitive policy 9a: [Record Action] step 1 MUST land invalid-request(step-1) for an action reference in the reserved namespace that DOES NOT EQUAL audit.compensation AND DOES NOT EQUAL audit.reconciliation, with nothing recorded.
Primitive policy 10: The composition MUST consume credential through ActorIdentity.attest alone.
Primitive policy 11: The composition MUST NOT inspect credential.
Primitive policy 12: The composition MUST NOT store credential.
Primitive policy 13: The composition MUST NOT write credential into a payload.
Primitive policy 14: The composition MUST NOT write credential into a log line.
Primitive policy 15: The composition MUST NOT apply a length cap to credential.
Primitive policy 16: The composition MUST NOT read inside a caller's data.
Primitive policy 17: A policy selector MAY inspect data at [Record Action] step 4's policy resolution and at the third half's.
Primitive policy 18: The composition MUST NOT retain what the selector reads.
Primitive policy 19: The composition MUST NOT log what the selector reads.
Primitive policy 20: The composition MAY read inside a payload's data member ONLY IF the payload's action reference EQUALS audit.compensation OR the payload's action reference EQUALS audit.reconciliation.
Primitive policy 21: [Record Action] step 1 MUST measure the serialized envelope of the full constructed payload against payload cap, sized with attestation id width.
Primitive policy 22: [Record Action] step 1 MUST land invalid-request(step-1) for an oversize payload, with nothing recorded.
Primitive policy 23: An empty data MUST count as valid.
Primitive policy 24: An unknown event id MUST yield not-known from the addressed action.
Primitive policy 25: The composition MUST pass original event payload through to TamperEvidence.verify unchanged.
Primitive policy 26: original event payload MUST match the verify-time presentation.
Primitive policy 27: The caller MUST present a non-empty original event payload.
Primitive policy 28: The composition MUST NOT canonicalize original event payload.
```

Term malformed reference: an action reference or actor reference that EQUALS blank OR whose length EXCEEDS reference length cap.

Term full constructed payload: Event Log's data field — `{action_ref, actor_ref, attestation_id, data}` — the exact object [Record Action] step 3 hands to `EventLog.append`.

Term reserved namespace: every action reference whose bytes begin with `audit.`; `Audit.` is a different reference and is not reserved.

Term reconciliation path: the scan's own writes — `audit.reconciliation` and `audit.compensation` records — identified by actor reference EQUALS reconciliation operator.

### Action wiring

One *record* action wraps all four constituents; *seal*, *read*, *verify* and *purge* actions run over the composed surface; the consolidated per-event join is [Read Record]. Each step names every rejection its constituent call declares and where the rejection lands at this composition's boundary; the enumeration is exhaustive, because silent rejection-code drift is a Pass 1 reference-graph finding. A constituent's state-unavailable, which a failed read of the database answers on no signature, passes through unchanged wherever no rule here lands it (Execution Contract Read 1 through 3). A call that never answers is the lost answer of Execution Contract Error model 1; the closure table below names where each call's answers, its lost answer among them, land.

```
Action wiring 1: The composition MUST pass a query by sequence-number range through to EventLog.read unchanged.
Action wiring 2: The composition MUST pass a query by wall-time range through to EventLog.read unchanged.
Action wiring 3: The composition MUST NOT serve a query by payload field.
Action wiring 4: A deployment needing a query by payload field MUST compose Reverse Index over the audit log and join the results through [Read Record] one event id at a time.
Action wiring 5: The composition MUST pass the answer and the refusal of a passed-through EventLog.read through unchanged, invalid-query included.
Action wiring 6: The composition MUST return EVERY payload of a passed-through EventLog.read byte-exact as appended.
```

#### Closure table

Every input an action takes, and every answer a call of the six actions and of the scan's three halves can meet — a constituent's action or read, a read or write of this composition's own records, a lease, the erasure mechanism, an action of this composition called inside another — with where the call lands it and the rule that owns the landing. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here (Term no answer). The enumeration is exhaustive: an answer a constituent adds is a row this table lacks, and a cell no rule owns is a finding against the page.

**Inputs.** [Seal Now] and [Purge Eligible] take none.

| Action | Input | Lands | Owner |
|---|---|---|---|
| [Record Action] | an action reference or actor reference that is blank or longer than reference length cap | invalid-request(step-1), nothing recorded | Primitive policy 1, 2, 5; record action step 1.1, 1.3; reference length cap 1 |
| [Record Action] | an action reference in the reserved namespace from an actor reference other than reconciliation operator | invalid-request(step-1), nothing recorded | Primitive policy 8 |
| [Record Action] | an action reference in the reserved namespace other than audit.compensation and audit.reconciliation | invalid-request(step-1), nothing recorded | Primitive policy 9a |
| [Record Action] | a full constructed payload whose serialized envelope exceeds payload cap | invalid-request(step-1), nothing recorded | Primitive policy 21, 22 |
| [Record Action] | from reconciliation operator, an audit.compensation or audit.reconciliation payload with no subject-kind discriminator or no id for the subject | invalid-request(step-1), nothing recorded | record action step 1.4a, 1.4b |
| [Record Action] | empty data, or a payload of any shape outside the reserved namespace | admitted, nothing inside it read but by a policy selector | Primitive policy 16, 17, 23; record action step 1.5 |
| [Record Action] | credential | consumed by ActorIdentity.attest alone, never inspected, capped, stored, written into a payload or logged | Primitive policy 10 through 15 |
| [Read Record], [Verify Record], [Purge Event] | an event id no constituent knows | not-known | Primitive policy 24; read record step 3.1; verify record step 2.2; purge event 1 |
| [Verify Record] | an original event payload whose count of events differs from the count the slice reference carries: an empty one, or the event's own payload where the range is wider | failed-verification(seal-record-set-mismatch), where step 5 runs | Primitive policy 26, 27; Capability requirement 6a; verify record step 5.2 |

**[Record Action]: steps 2 to 4.** The writes of these steps commit together (Execution Contract Database 1): a call that is refused or gives no answer commits nothing but the evidence a non-storage refusal keeps (record action step 7.11), and a [Record Action] whose own commit gives no answer has none to give, its caller unable to tell whether the call landed (Execution Contract Error model 1).

| Answer | ActorIdentity.attest, step 2 | EventLog.append, step 3 | RetentionWindow.place_under_retention, step 4 |
|---|---|---|---|
| its id | the append (record action step 2.1) | the placement (record action step 3.1) | the indexes (record action step 4.3) |
| invalid-credential | passed through unchanged, nothing recorded (record action step 2.2, 2.5; Failed attribution 2) | — | — |
| invalid-request | invalid-request(step-2), nothing recorded (record action step 2.3, 2.5, 7.10) | — | invalid-request(step-4) carrying the attestation id and the event id, both kept and surfaced (record action step 4.5, 7.11, 7.12, 7.16) |
| invalid-payload | — | invalid-request(step-3) carrying the attestation id, kept and surfaced, a deployment fault (record action step 3.4, 7.11, 7.12, 7.15; payload cap 4) | — |
| invalid-policy, policy-not-found | — | — | invalid-request(step-4), both ids kept, a deployment fault (record action step 4.6, 4.7, 7.11, 7.16) |
| registry-unavailable | recording-failure(step-2), nothing committed (record action step 2.14) | — | recording-failure(step-4), nothing committed (record action step 4.10) |
| storage-failure | recording-failure(step-2), nothing committed (record action step 2.4, 7.14) | recording-failure(step-3), nothing committed (record action step 3.3) | recording-failure(step-4), nothing committed (record action step 4.8) |
| state-unavailable | passed through unchanged, nothing written (Execution Contract Read 1 through 3) | the same | the same |
| no answer | recording-failure(step-2), nothing committed (record action step 2.13) | recording-failure(step-3), nothing committed (record action step 3.7) | recording-failure(step-4), nothing committed (record action step 4.9) |

Every recording-failure carries its step (record action 1). A caller other than the scan does not retry an invalid-request(step-3) or an invalid-request(step-4), which would commit a second attestation (record action step 7.13); the scan's own course is in its tables below.

**[Record Action]: steps 5 and 6.**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the read-back | the event carrying the returned event id | its sequence number into event to sequence, beside event to attestation and event to retention | record action step 5.1 through 5.4 |
| the read-back | no event carrying it | the rebuild of event to sequence, no sequence number guessed | record action step 5.5, 5.6 |
| the read-back, the rebuild or an index write | a refusal, a failed read, an invalid-query or no answer | a rebuild trigger, never [Recording Failure]: the event id is returned; an invalid-query a deployment fault besides | record action step 5.9, 5.10, 7.1; Capability requirement 2, 3a |
| [Seal Now], under per-event cadence | evidence id | the event id returned | record action step 6.1, 7.1 |
| [Seal Now] | [Nothing To Seal] | the event id returned, no alert | record action step 6.4, 6.5 |
| [Seal Now] | any other answer | the event id returned; an alert carrying the cause, standing until a later action seals the event; the next firing retries | record action step 6.4 through 6.6; seal cadence 3 |

**[Seal Now].** [Seal Now] answers every call it makes, so its callers (the cadence driver, [Record Action] step 6 and [Purge Event] step 0) always meet an answer; after a rejection the next firing cuts the slice again (seal now 11).

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the take of the sealing lock | its answers | the lease tables below | Concurrency 1g |
| the read of the uncovered mark and of the ranges index | set or unknown, or the index absent | the ranges rebuilt from the seal records before sealed through is read | seal now 13 |
| | clear, the index present | sealed through read from the ranges, never from a process cache | seal now 17, 18 |
| the rebuild's read of the seal records | every evidence | each evidence's record set reference read into the ranges, the audit log unread | seal coverage 3, 4 |
| the read of sealed through | sealed through | the open-upper-bound read from the next sequence number | seal now 1, 17 |
| the open-upper-bound read | events | the slice: at most slice cap events, through the tail position | seal now 1, 1a; Term slice; Term tail position |
| | no event | [Nothing To Seal] | seal now 3 |
| the set of the uncovered mark | set, carrying the holder value | the seal call | seal now 4, 15, 22 |
| | refused | [Recording Failure] | seal now 8 |
| TamperEvidence.seal | evidence id | the coverage entry, sealed through advanced | seal now 5 |
| | mechanism-failure(reason) | [Mechanism Failure] carrying the reason | seal now 6 |
| | invalid-request | passed through unchanged | seal now 7 |
| | storage-failure | [Recording Failure] | seal now 8 |
| | state-unavailable | passed through unchanged | Execution Contract Read 1 through 3 |
| | no answer | [Recording Failure], the mark left set, so a seal that landed is found by the next taker's rebuild | seal now 13, 24 |
| the coverage write | written | the mark cleared, the evidence id returned | seal now 16, 23 |
| | refused | [Recording Failure] | seal now 14 |
| | no answer | [Recording Failure], the mark left set, so a coverage write that landed, sealed through with it, is found by the next taker's rebuild | seal now 9, 10, 13, 24 |
| the clear of the uncovered mark | any answer | the evidence id: sealed through has advanced, so no rejection is open, and a mark left set or unknown sends the next taker to the rebuild | seal now 9, 13, 16, 23 |
| a read before the seal call | a failed read | state-unavailable, no seal cut | Execution Contract Read 1 through 3 |
| | an invalid-query, at the open-upper-bound read | the same, a deployment fault | Capability requirement 2, 3, 3a |
| a call before the seal call | no answer, where no row above names its arm | [Recording Failure], no further write | seal now 28 |

After every rejection but one whose coverage write gave no answer, sealed through does not move and no coverage entry is written (seal now 9, 10, 24); once its coverage write has answered written, [Seal Now] answers its evidence id though its lease expires or its clear is refused, the mark left set for the next taker's rebuild (seal now 8, 13, 20); and the mark is cleared only where the seal call wrote no evidence (seal now 16).

**[Read Record], [Verify Record] and [Purge Eligible]: what the reads answer.**

| Action | What the reads answer | Lands | Owner |
|---|---|---|---|
| [Read Record] | no retention record and no log entry | not-known | read record step 3.1 |
| [Read Record] | a log entry and no retention record | the audit record, retention status unresolved (compensation window), no retention fabricated | read record step 5.1, 5.2 |
| [Read Record] | a Retained retention over readable data | the audit record, with its coverage status and the covering seal's full range | read record step 4.1 through 4.3 |
| [Read Record] | a Retained retention over unreadable data | the retention read again: Purged, answered as a purged event; still Retained, no answer, an outage of Event Log | read record step 4.5 through 4.7 |
| [Read Record] | a Purged retention and a destruction record | the who, the what and the when through the pair from the attestation records, and no data | read record step 4.4a, 4.4b, 4.4c |
| [Read Record] | a Purged retention and no destruction record | the same through event to attestation's entry | read record step 4.4c, 4.4g |
| [Read Record], [Verify Record], [Purge Event] | a retention record and no log entry | unreachable: a retention is placed only over an appended event, in the append's transaction or after it; where a deployment fault leaves one, the deployment alerts | Composes 4a, 9; Execution Contract Database 1; read record step 3.3 |
| [Verify Record] | a Purged retention | failed-verification(purged), with no attestation call | verify record step 1.2, 1.3 |
| [Verify Record] | no retention record and no log entry | not-known, without the qualifier | verify record step 2.2; verify record 4 |
| [Verify Record] | a log entry and no retention record | step 3, the outcome carrying the qualifier | verify record step 2.3, 7.2 |
| [Verify Record] | partly-purged coverage | unverifiable(partially-purged-coverage), with no seal call | verify record step 4.2, 4.3 |
| [Verify Record] | no covering seal, unsealed tail mode strict | failed-verification(unsealed) | verify record step 4.4 |
| [Verify Record] | no covering seal, unsealed tail mode lenient | coverage satisfied, with no seal call | verify record step 4.5a, 4.5b |
| [Verify Record] | a Purged retention at the re-read before a failed-verification or an unverifiable returns | failed-verification(purged) | verify record 5, 6 |
| [Purge Eligible] | every retention | each eligible one mapped to its event id, no refusal, no hold filter | purge eligible 1, 2, 5, 6 |

**[Verify Record]: the two verifications.** Record set match no, the host's answer at Tamper Evidence's seam, comes back as Tamper Evidence's record-set-mismatch (Capability requirement 5, 6, 6a, 6b).

| Answer | ActorIdentity.verify, step 3 | TamperEvidence.verify, step 5 |
|---|---|---|
| verified | step 4 (verify record step 3.8) | step 6, then verified where no finding stands (verify record step 7.1) |
| failed-verification carrying registry-unavailable | step 6: unverifiable(attestation-registry-unavailable), steps 4 and 5 not run (verify record step 3.3, 3.7, 6.1) | — |
| failed-verification carrying mechanism-verification-unavailable | — | step 6: unverifiable(seal-mechanism-verification-unavailable) (verify record step 5.3, 6.2) |
| failed-verification carrying any other reason | failed-verification with the reason prefixed attestation-, steps 4 to 6 not run (verify record step 3.2, 3.5, 3.6) | failed-verification with the reason prefixed seal- (verify record step 5.2) |
| not-known | failed-verification(attestation-not-known) (verify record step 3.4) | failed-verification(seal-not-known) (verify record step 5.4) |
| state-unavailable | passed through unchanged (Execution Contract Read 1 through 3) | the same |
| no answer | no answer to give, never not-known or unverifiable (Execution Contract Error model 1) | the same |

**The read surfaces: a read that fails or never answers.**

| Action | A failed read | An invalid-query | No answer |
|---|---|---|---|
| [Read Record] | state-unavailable, never not-known (Execution Contract Read 1 through 3) | the same, a deployment fault (Capability requirement 2, 3a) | no answer to give, never not-known (Execution Contract Error model 1) |
| [Verify Record] | state-unavailable (Execution Contract Read 1 through 3) | the same, a deployment fault (Capability requirement 2, 3a) | no answer to give, never not-known or unverifiable (Execution Contract Error model 1) |
| [Purge Eligible] | state-unavailable (Execution Contract Read 1 through 3) | — | no answer to give, never an empty list (Execution Contract Error model 1) |

**[Purge Event].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the try-take of the critical section keyed by event id | its answers | the lease tables below | purge event step 0.6; Per-act critical section 15 |
| the resolve through event to sequence | no retention record and no log entry | not-known, no step 0.2 | purge event 1; purge event step 0.1a |
| | a sequence number | the hold read where Legal Hold is composed, then step 0 | purge event step 0.1; purge event 5c |
| | a failed read or an invalid-query | state-unavailable, nothing written | Execution Contract Read 1 through 3; Capability requirement 3a |
| | no answer | cascade-failure(seal), never not-known | purge event step 0.11 |
| the hold read, where Legal Hold is composed | a hold over the event | under-legal-hold, no cascade step | purge event 5b, 5d |
| | no hold | step 0 | purge event 5c |
| | no holds returned: a failed read, an invalid-query or no answer | cascade-failure(hold), no cascade step | purge event 5e |
| the read of sealed through | the sequence number not past it | step 0½, no [Seal Now] | purge event step 0.5 |
| | past it | [Seal Now] | purge event step 0.2 |
| [Seal Now] | evidence id, a covering seal existing for the event | step 0½ | purge event step 0.3, 0.12 |
| | evidence id, no covering seal for the event | cascade-failure(seal), the event left on [Purge Eligible]'s list | purge event step 0.12; purge event 3c |
| | [Nothing To Seal] | the covering seal resolved again, and where none exists, cascade-failure(seal) | purge event step 0.8, 0.9 |
| | any other answer | cascade-failure(seal) | purge event step 0.4 |
| the read of event to retention, step 0½ | a retention record | step 1 | purge event step 0½.1 |
| | none, a log entry standing | retention-unresolved, no cascade step, step 0's seal standing | purge event step 0½.2 through 0½.4 |
| | a failed read | state-unavailable, step 0's seal standing | Execution Contract Read 1 through 3 |
| | no answer | cascade-failure(step-1), never retention-unresolved or not-known | purge event step 0½.6 |
| RetentionWindow.purge, step 1 | ok | step 2 | purge event step 1.1 |
| | not-retained | step 2, the cascade resumed | purge event step 1.4 |
| | retention-period-not-elapsed | [Not Eligible], nothing written | purge event step 1.2 |
| | not-known | passed through unchanged | purge event step 1.3 |
| | storage-failure | cascade-failure(step-1), the retention as found | purge event step 1.5; purge event 3a |
| | state-unavailable | passed through unchanged, nothing written | Execution Contract Read 1 through 3 |
| | no answer | cascade-failure(step-1); a purge that landed leaves a Purged retention the first half re-drives | purge event step 1.6; purge event 3a; First half 3, 5 |
| the read of the destruction record, step 2 | a destruction record | adopted as landed: step 3 | purge event step 2.6, 2.7 |
| | none | the destruction record, carrying the pair | purge event step 2.1 through 2.3 |
| the destruction record's write | written | step 3 | purge event step 2.4 |
| | refused | cascade-failure(step-2) | purge event step 2.5 |
| | no answer | cascade-failure(step-2) | purge event step 2.8 |
| the read of erasure outcomes, step 3 | a destroyed outcome | no delegation: the cascade complete, ok | purge event step 3.12; Term completed cascade |
| | none | the delegation | purge event step 3.1, 3.11 |
| the delegation to the erasure mechanism | destroyed | the outcome recorded | purge event step 3.4; erasure outcomes 1 |
| | destruction-failed(reason) | the outcome recorded, cascade-failure(step-3) | purge event step 3.4, 3.5; erasure outcomes 1, 6 |
| | no answer | an abandoned call: no outcome to record, cascade-failure(step-3), the lease kept to its instant | purge event step 3.7; Per-act critical section 2a |
| the outcome record's write | written | ok, the cascade complete | purge event step 3.4, 4.1; Term completed cascade |
| | refused or no answer | cascade-failure(step-3) | purge event step 3.7 |
| a read at step 2 or step 3 | a failed read or an invalid-query | the step's cascade-failure, its write not issued | purge event step 2.5, 3.6; Capability requirement 3a |
| | no answer | the step's cascade-failure, no further write | purge event 8 |

A cascade-failure(step-2) or cascade-failure(step-3) over an incomplete cascade leaves an open entry the scan re-drives and the deployment surfaces (purge event 4a, 4b), and one a repeat lands over a completed cascade, its read at step 2 or step 3 failing or giving no answer, leaves the cascade complete (purge event step 2.5, 3.6; purge event 8); a cascade-failure(seal), (hold), (step-1) or (in-flight) leaves the retention as found, a step-1 purge that landed without an answer excepted, and on [Purge Eligible]'s list while Retained (purge event 3a, 3b, 3c, 3d, 3e).

**The scan's three halves: what the reads answer.**

| Half | What the reads answer | Lands | Owner |
|---|---|---|---|
| first | a Purged retention younger than purge edge | not examined | First half 2 |
| first | a Purged retention carrying its sequence number in purged events, the pair and a destroyed outcome | left alone | First half 3 |
| first | one of the three missing, at the read under the critical section keyed by event id as well | the cascade re-driven through [Purge Event] | First half 3, 5 through 7 |
| second | an attestation in neither enumeration of the binding set | an orphan | Second half 1, 2, 14, 15 |
| second | under the critical section keyed by its attestation id, the orphan compensated, reported beyond horizon or narrated | no second write of that kind | Second half 8, 10, 17; Compensation 10, 11 |
| second | an orphan past horizon, uncompensated and unreported | the beyond-horizon report, and no compensation | Second half 4 through 7 |
| second | an orphan inside horizon and uncompensated | the intent, then the compensation | Compensation 1, 3, 4, 9; Second half 9, 11, 13 |
| second | an event whose data is unreadable and that no destruction record names | no compensation in the run, a compliance alert, an outage of Event Log | Second half 18; Term dependency outage |
| third | an event whose event to retention entry is missing after the rebuild | a true miss: the critical section keyed by the payload's attestation id | Third half 1 through 3, 5 |
| third | a retention, at the re-read under the critical section | no placement | Third half 6; Invariant 2.3 |
| third | a true miss, at the re-read | the intent, the placement under the resolved policy, then the compensation | Third half 7 through 10, 15 |
| third | an owed narration | its repair recorded, the retention confirmed under the critical section first | Third half 12, 13 |
| third | an intent past the horizon | no finding | Third half 14 |
| third | a true miss whose data is unreadable | no attestation id to key a critical section by, so no write; an outage of Event Log | Third half 5; Reconciliation 6; Term dependency outage |
| every half | a failed read, an invalid-query or no answer | nothing decided or written for the acts that read would have decided, which the next run reads again | Execution Contract Read 2, Execution Contract Error model 1; Capability requirement 3a; Reconciliation 7; reconciliation cadence 1 |
| every half | failed reads or no answers standing longer than call pause bound | a dependency outage: the liveness arms suspended, every outstanding finding surfaced, the outage recorded | Term dependency outage; Composition-level invariant 1 |

**The scan: a reconciliation-path [Record Action]**, by position. The run's first goes alone, and none starts after it until it has returned, so a first that gives no answer starts no other in the run (Invariant 1.10, 1.11).

| [Record Action] answers | the intent | the compensation | the beyond-horizon report |
|---|---|---|---|
| event id | the act the intent announces (Compensation 3; Third half 8) | the finding reconciled (Second half 13; Third half 10) | the orphan reported (Second half 6, 8) |
| invalid-credential | a deployment fault, no retry in the run (Compensation 17) | the same | the same |
| invalid-request(step-1) or invalid-request(step-2) | nothing committed, a deployment fault, retried on the next run (Compensation 14, 15) | the same | the same |
| invalid-request(step-3) or invalid-request(step-4) | its evidence kept, a deployment fault, no retry in the run, retried on the next run, and no further reconciliation-path [Record Action] in the run (Compensation 13 through 15; Invariant 1.12) | the same | the same |
| recording-failure(step) | nothing committed, no retry in the run, retried on the next run, an alert where it stands across two runs (Third half 11; Compensation 15, 16) | the same | the same |
| state-unavailable | as a recording-failure (Compensation 18) | the same | the same |
| no answer | not issued again under the lease, and no act started on it (Per-act critical section 17; Compensation 3; Third half 8); the next run reads narrated before it records again (Compensation 10, 11) | not issued again under the lease; the next run reads compensated attestations, or confirms the retention, before it records again (Per-act critical section 17; Second half 9, 10; Third half 13) | not issued again under the lease; the next run reads reported beyond horizon before it reports again (Per-act critical section 17; Second half 7, 8) |

**The scan: the third half's placement.**

| RetentionWindow.place_under_retention answers | Lands | Owner |
|---|---|---|
| retention id | the compensation | Third half 9 |
| invalid-policy, policy-not-found | no retry in the run, a deployment fault; no compensation, the finding left to the next run | Third half 9, 16, 17; Invariant 2.2 |
| any other refusal, or state-unavailable | no retry in the run; no compensation, the finding left to the next run | Third half 9, 16; Invariant 2.2 |
| no answer | not issued again under the lease; the next run confirms the retention under the critical section before it records the compensation | Per-act critical section 17; Third half 6, 12, 13 |

**The scan: the first half's re-drive.**

| [Purge Event] answers | Lands | Owner |
|---|---|---|
| ok | the entry closed | First half 5; Term completed cascade |
| under-legal-hold | the entry left open and uncounted, re-driven on the first run after the hold is released, its window counted from the first hold-free run | First half 9 through 11; Composition-level invariant 1e, 1h, 1i |
| a cascade-failure other than in-flight, or state-unavailable | the entry left open, re-driven on every run and surfaced | First half 8; Boundary one 4, 6; purge event 4a, 4b |
| not-known, not-eligible, retention-unresolved, cascade-failure(in-flight) | unreachable: the event is logged under a Purged retention, its purge answers not-retained, and the re-drive runs under the half's own critical section | Composes 9; purge event step 1.4; Per-act critical section 14 |

**Leases: the take.** A leg takes no critical section where its remainder does not exceed the half's work bound: the act is skipped and the deployment alerted (Per-act critical section 13d, 13e). A re-driven [Purge Event] takes none of its own (Per-act critical section 14).

| take answers | [Seal Now]: take, the sealing lock | [Purge Event]: try_take, keyed by event id | a leg: try_take, keyed by the act's id |
|---|---|---|---|
| granted | the read of the uncovered mark (seal now 13, 17) | the resolve of step 0.1 (purge event step 0.6) | the half's predicate read again under the critical section (First half 7; Second half 9, 17; Third half 6) |
| unavailable, or held | [Recording Failure] (seal now 20) | cascade-failure(in-flight), nothing written, the retention as found (purge event step 0.7; purge event 3d, 3e) | the act skipped for the rest of the run, with no wait (Per-act critical section 5, 6) |
| no answer | the lease expired for the grant: [Recording Failure], no write (Per-act critical section 16; seal now 19, 20) | cascade-failure(in-flight) (purge event step 0.10) | the act skipped for the rest of the run (Per-act critical section 13c, 16) |

**Leases: the remaining reading** behind a write.

| remaining answers | [Seal Now] | [Purge Event] | a leg |
|---|---|---|---|
| live | the write (seal now 19) | the step's write (Per-act critical section 9b) | the write (Per-act critical section 13b) |
| expired, none, or no answer (Term lease; Per-act critical section 16) | no further write and [Recording Failure], or, once the coverage write has answered written, the evidence id with the mark left set; a deployment fault and the bound declared anew (seal now 9, 19, 20, 25 through 27) | before step 1 commits, no step 1 and cascade-failure(step-1); after it, no further write and cascade-failure naming the first step not completed, which the scan re-drives (purge event 7a, 7b, 7c, 7d) | no further write, the act skipped for the rest of the run, a deployment fault (Per-act critical section 13b, 13c, 13e) |

**Leases: the release.** Every release leaves the holder's answer as it stands: no rule here refuses on a release's answer (Execution Contract Refusal 1), and once its coverage write has answered written [Seal Now] has no rejection open (seal now 8, 9, 20). A release that gives no answer reads the grant expired and is not issued again (Per-act critical section 16, 17). A holder releases on return (Per-act critical section 2b; seal now 21), save a cascade, or a first half re-driving one, whose delegation gave no answer: it keeps the lease to its instant (Per-act critical section 2a).

---

#### Record Action contract

```
record_action(action_ref, actor_ref, credential, data)
  answers event_id
  refuses invalid-credential | invalid-request(step, committed_ids) | recording-failure(step)
```

Term committed ids: committed_ids — the ids of the writes an invalid-request refusal leaves committed, so a caller can read the partial state back rather than search for it: none at step-1 and step-2, the step-2 attestation id at step-3, and the step-2 attestation id and the step-3 event id at step-4 (record action step 7.10, 7.11, 7.15, 7.16).

Validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal.

```
record action 1: The recording-failure arm MUST carry the step that refused.
```

Steps:

1. **Validate the primitives at this layer, before any constituent is called.**
   ```
   record action step 1.1: [Record Action] step 1 MUST validate action reference and actor reference per Primitive policy 1 through 5, Primitive policy 8 and Primitive policy 9a.
   record action step 1.2: [Record Action] step 1 MUST size the full constructed payload per Primitive policy 21 and Primitive policy 22.
   record action step 1.3: A step-1 refusal MUST record nothing.
   record action step 1.4: WHEN actor reference EQUALS reconciliation operator:
       record action step 1.4a: [Record Action] step 1 MUST land invalid-request(step-1) for a payload written in the reserved namespace carrying no subject-kind discriminator.
       record action step 1.4b: [Record Action] step 1 MUST land invalid-request(step-1) for a payload written in the reserved namespace carrying no id for the subject.
   record action step 1.5: [Record Action] step 1 MUST NOT validate the shape of a payload written outside the reserved namespace.
   ```
   Term subject-kind discriminator: the payload field subject = attestation | event; with subject set to attestation the payload carries the orphan's attestation id, with subject set to event the event id of the unretained event whose retention the third half places.

2. **Attest.**
   ```
   record action step 2.1: [Record Action] step 2 MUST call ActorIdentity.attest(action reference, actor reference, credential), answering attestation id.
   record action step 2.2: [Record Action] step 2 MUST pass invalid-credential through unchanged.
   record action step 2.3: [Record Action] step 2 MUST land invalid-request as invalid-request(step-2).
   record action step 2.4: [Record Action] step 2 MUST land storage-failure as [Recording Failure].
   record action step 2.5: A step-2 refusal MUST record nothing further.
   Deleted: record action step 2.6. Execution Contract Database 1 owns it.
   Deleted: record action step 2.7. Execution Contract Database 1 owns it.
   Deleted: record action step 2.8. Execution Contract Database 1 owns it: a [Record Action]'s writes commit together, and the composition names no section for it to release.
   Deleted: record action step 2.9. Execution Contract Database 1 owns it.
   Deleted: record action step 2.10. Execution Contract Database 1 owns it.
   record action step 2.13: IF the attest call answers no answer THEN [Record Action] MUST land recording-failure(step-2).
   Deleted: record action step 2.11. Execution Contract Database 1 owns it.
   Deleted: record action step 2.12. Execution Contract Database 1 owns it.
   record action step 2.14: [Record Action] step 2 MUST land registry-unavailable as [Recording Failure].
   NOTE: watch the registry outage (record action step 2.14).
   ```
3. **Append.**
   ```
   record action step 3.1: [Record Action] step 3 MUST call EventLog.append with the full constructed payload, answering event id.
   record action step 3.2: The composition MUST NOT supply recording instant.
   record action step 3.3: [Record Action] step 3 MUST land storage-failure as [Recording Failure].
   record action step 3.4: [Record Action] step 3 MUST land invalid-payload as invalid-request(step-3).
   Deleted: record action step 3.5. Execution Contract Database 1 owns it.
   Deleted: record action step 3.6. Execution Contract Database 1 owns it.
   record action step 3.7: IF the append answers no answer THEN [Record Action] step 3 MUST land recording-failure(step-3).
   ```
4. **Place under retention.**
   ```
   Deleted: record action step 4.1. Execution Contract Database 1 owns it.
   Deleted: record action step 4.2. Execution Contract Database 1 owns it.
   record action step 4.3: [Record Action] step 4 MUST call RetentionWindow.place_under_retention(event id, resolved policy) with record reference set to event id, answering retention id.
   Deleted: record action step 4.4. Execution Contract Database 1 owns it.
   record action step 4.5: [Record Action] step 4 MUST land invalid-request as invalid-request(step-4).
   record action step 4.6: [Record Action] step 4 MUST land invalid-policy and policy-not-found as invalid-request(step-4).
   record action step 4.7: The deployment MUST alert on invalid-policy and policy-not-found as a deployment fault.
   record action step 4.8: [Record Action] step 4 MUST land storage-failure as [Recording Failure].
   record action step 4.9: IF the placement answers no answer THEN [Record Action] step 4 MUST land recording-failure(step-4).
   record action step 4.10: [Record Action] step 4 MUST land registry-unavailable as [Recording Failure].
   NOTE: watch the registry outage (record action step 4.10).
   ```
5. **Record the indexes.**
   ```
   record action step 5.1: [Record Action] step 5 MUST record event to attestation, event to retention and event to sequence for the event.
   record action step 5.2: [Record Action] step 5 MUST take sequence number from the read-back.
   record action step 5.3: The read-back MUST run from the high-water mark plus one with no upper bound.
   record action step 5.4: The read-back MUST match the returned event id by equality.
   record action step 5.5: IF the read-back returns no event carrying the event id THEN [Record Action] step 5 MUST fall back to the rebuild of event to sequence.
   record action step 5.6: [Record Action] step 5 MUST NOT guess a sequence number.
   Deleted: record action step 5.7. record action step 5.2 owns it: Event Log's append answers event id alone, so the read-back is the one source of sequence number.
   record action step 5.8: The composition MUST NOT depend on the append result surfacing sequence number.
   record action step 5.9: The composition MUST treat a step-5 failure as a rebuild trigger.
   record action step 5.10: A step-5 failure MUST NOT land [Recording Failure].
   ```
   Term read-back: the open-upper-bound read over the new unsealed tail through `EventLog.read`.

   Term high-water mark: the greater of sealed through and the highest sequence number this instance has itself recorded into event to sequence.

6. **Seal under per-event cadence.**
   ```
   record action step 6.1: IF seal cadence EQUALS per-event THEN [Record Action] step 6 MUST seal through [Seal Now].
   record action step 6.2: IF seal cadence DOES NOT EQUAL per-event THEN [Record Action] step 6 MUST defer sealing to the next cadence firing.
   record action step 6.3: A cadence firing MUST seal the slice.
   record action step 6.4: A seal failure at step 6 MUST NOT reject [Record Action].
   record action step 6.5: The deployment MUST alert on a step-6 seal failure other than [Nothing To Seal] with the cause.
   record action step 6.6: The next cadence firing MUST retry the seal.
   ```
7. **Return.**
   ```
   record action step 7.1: [Record Action] step 7 MUST return event id.
   Deleted: record action step 7.2. record action step 3.3 and Execution Contract Database 1 own it.
   Deleted: record action step 7.3. record action step 4.8 and Execution Contract Database 1 own it.
   Deleted: record action step 7.4. Execution Contract Database 1 and Execution Contract Database 3 own it.
   Deleted: record action step 7.17. Execution Contract Database 1 owns it.
   record action step 7.15: An invalid-request(step-3) refusal MUST carry the step-2 attestation id.
   record action step 7.16: An invalid-request(step-4) refusal MUST carry the step-2 attestation id and the step-3 event id.
   record action step 7.5: [Record Action] MUST NOT land a non-storage refusal of steps 3 through 4 as [Recording Failure].
   Deleted: record action step 7.6. Execution Contract Database 1 owns it.
   Deleted: record action step 7.6a. Execution Contract Database 1 owns it.
   Deleted: record action step 7.6b. Execution Contract Database 1 owns it.
   Deleted: record action step 7.6c. Execution Contract Database 1 owns it: a [Record Action]'s writes commit together, and the composition names no section for it to release.
   Deleted: record action step 7.7. Execution Contract Database 1 owns it.
   record action step 7.8: The invocation MUST NOT write a compensation for the partial state the invocation left.
   record action step 7.9: An invalid-request refusal MUST carry the step that landed the refusal: step-1, step-2, step-3 or step-4.
   record action step 7.10: An invalid-request(step-1) or invalid-request(step-2) refusal MUST leave nothing committed.
   record action step 7.11: An invalid-request(step-3) refusal MUST leave the step-2 attestation committed, and an invalid-request(step-4) refusal MUST leave the step-2 attestation and the step-3 event committed.
   NOTE: the refusal's evidence — what step 7.11 keeps is written in the refusal's own transaction, a domain choice by the maintainer's ruling of 2026-10-20 (Decisions) and the declared partial-failure surface the section titled *Substrate composition invocation* in `execution-contract.md` names for this action; the section titled *The pipeline applies to composition actions* in `execution-contract.md` states the multi-write obligation without it.
   record action step 7.12: An invalid-request(step-3) or invalid-request(step-4) refusal MUST surface the partial state the invocation left.
   record action step 7.13: A caller other than the scan MUST NOT retry [Record Action] on an invalid-request(step-3) or invalid-request(step-4) refusal.
   record action step 7.14: IF storage-failure EXISTS at step 2 THEN [Record Action] MUST return recording-failure(step-2) (Execution Contract Constituent failure 1).
   ```
   Term non-storage refusal: invalid-payload at step 3; invalid-request, invalid-policy or policy-not-found at step 4 — the refusals that keep the partial state of record action step 7.11; registry-unavailable, an outage, is none (record action step 2.14, 4.10).

---

#### Seal Now contract

```
seal_now()
  answers evidence_id
  refuses nothing-to-seal | mechanism-failure(reason) | invalid-request | recording-failure
```

Under interval or on-demand cadence, seals the current unsealed tail; [Record Action] step 6 and [Purge Event] step 0 reach it too.

```
seal now 1: [Seal Now] MUST read the tail position by the open-upper-bound read beginning at the slice's first sequence number.
seal now 1a: The count of events [Seal Now] takes from the read MUST NOT EXCEED slice cap.
seal now 2: [Seal Now] MUST NOT read next sequence number.
seal now 3: IF the open-upper-bound read returns no event THEN [Seal Now] MUST land [Nothing To Seal].
seal now 4: [Seal Now] MUST call TamperEvidence.seal(slice reference, mechanism credential) over the slice.
seal now 5: [Seal Now] MUST record the seal coverage entry for evidence id as the slice and advance sealed through to the tail position.
seal now 6: [Seal Now] MUST land mechanism-failure(reason) as [Mechanism Failure] carrying the reason unchanged.
seal now 7: [Seal Now] MUST pass invalid-request through unchanged.
seal now 8: [Seal Now] MUST land storage-failure as [Recording Failure], a [Seal Now] whose coverage entry of seal now 5 has landed excepted (seal now 9).
seal now 9: IF [Seal Now] rejects THEN sealed through MUST NOT advance, a [Seal Now] whose coverage write gave no answer excepted (seal now 24; Execution Contract Error model 1).
seal now 10: IF [Seal Now] rejects THEN [Seal Now] MUST NOT write a seal coverage entry, a [Seal Now] whose coverage write gave no answer excepted (seal now 24; Execution Contract Error model 1).
seal now 11: IF [Seal Now] rejects THEN the next cadence firing MUST recompute the slice and seal what is not covered.
seal now 12: The composition MUST NOT expose a re-sealing surface.
seal now 13: IF the uncovered mark IS set OR IS unknown OR the ranges index IS absent at the take THEN [Seal Now] MUST NOT read sealed through BEFORE rebuilding the ranges of seal coverage from the seal records.
seal now 14: IF the coverage write of seal now 5 fails after the seal call of seal now 4 returned THEN [Seal Now] MUST land storage-failure as [Recording Failure].
seal now 15: [Seal Now] MUST NOT issue the seal call of seal now 4 BEFORE setting the uncovered mark.
seal now 16: [Seal Now] MUST clear the uncovered mark ONLY IF the coverage entry of seal now 5 has landed OR the seal call of seal now 4 has answered a rejection that wrote no evidence OR the rebuild of seal now 13 has completed.
seal now 17: [Seal Now] MUST read sealed through from the seal coverage ranges under the sealing lock.
seal now 18: [Seal Now] MUST NOT read sealed through from a process-local cache.
seal now 19: IF the sealing lock's lease EQUALS expired THEN [Seal Now] MUST NOT issue a further write.
seal now 20: IF the sealing lock's lease EQUALS expired OR the take answers unavailable THEN [Seal Now] MUST land [Recording Failure], a [Seal Now] whose coverage entry of seal now 5 has landed excepted (seal now 9).
seal now 21: [Seal Now] MUST release the sealing lock on return.
seal now 22: [Seal Now] MUST set the uncovered mark carrying [Seal Now]'s own holder value.
seal now 23: [Seal Now] MUST clear the uncovered mark ONLY by a compare against the holder value the mark carried when [Seal Now] last read the mark under [Seal Now]'s live lease — [Seal Now]'s own once [Seal Now] has set the mark (seal now 15, 22), the value found at the rebuild — AND MUST issue the compare ONLY IF [Seal Now]'s lease EQUALS live.
seal now 24: IF the seal call or the coverage write answers no answer THEN [Seal Now] MUST land [Recording Failure] AND MUST leave the uncovered mark set.
seal now 25: A [Seal Now] stopped by an expired lease under seal now 19 MUST surface a compliance alert as a deployment fault.
seal now 26: IF a [Seal Now] is stopped under seal now 19 THEN the deployment MUST declare seal completion bound anew.
seal now 27: IF seal completion bound is declared anew THEN the instance MUST run Instance start 23 and Instance start 25 against the new bound.
seal now 28: IF a call [Seal Now] issues BEFORE the seal call of seal now 4 answers no answer AND no rule above names the arm THEN [Seal Now] MUST land [Recording Failure] AND MUST issue no further write.
```

Term slice: the sequence-number range from `(sealed_through + 1)` to the tail position, inclusive.

Term tail position: the highest sequence number among the first slice cap events the open-upper-bound read beginning at `(sealed_through + 1)` returns; an empty result of that read means the unsealed tail is empty.

---

#### Read Record contract

```
read_record(event_id)
  answers audit_record | not-known
```

The consolidated read surface: a pure projection, the surface Invariant 6 rests on and the one [Audit Record] is produced by.

```
read record 1: [Read Record] MUST NOT change state.
read record 2: [Read Record] MUST NOT produce an audit event.
read record 3: [Read Record] MUST NOT carry a permissions layer at this composition.
read record 4: [Read Record] MUST NOT verify.
Deleted: read record 5. Execution Contract Error model 1 owns it: a constituent read whose answer never arrives leaves [Read Record] no answer to give, and none to read as not-known.
```

Steps:

1. **Read the retention record.**
   ```
   read record step 1.1: [Read Record] step 1 MUST read the retention record through event to retention.
   ```
2. **Read the event.**
   ```
   read record step 2.1: [Read Record] step 2 MUST read the event per event to sequence 4 and event to sequence 5.
   ```
3. **Decide not-known.**
   ```
   read record step 3.1: IF no retention record EXISTS AND no log entry EXISTS THEN [Read Record] step 3 MUST land not-known.
   read record step 3.2: [Read Record] MUST NOT land not-known for an event id with a log entry.
   read record step 3.3: The deployment MUST alert on a retention record whose event id resolves to no log entry as a deployment fault.
   ```
4. **Assemble the [Audit Record].**
   ```
   read record step 4.1: IF the event's data IS NOT unreadable under a Retained retention THEN [Read Record] step 4 MUST assemble and return the audit record.
   read record step 4.2: IF the event's data IS NOT unreadable under a Retained retention THEN [Read Record] step 4 MUST report coverage status per event.
   read record step 4.3: IF the event's data IS NOT unreadable under a Retained retention THEN [Read Record] step 4 MUST return the covering seal's full range.
   read record step 4.4: WHEN retention state EQUALS Purged:
       read record step 4.4a: IF a destruction record EXISTS for the event THEN [Read Record] step 4 MUST read action reference, actor reference and attestation instant from the attestation records through the pair alone.
       read record step 4.4b: [Read Record] step 4 MUST NOT read the who, the what and the when from the event payload.
       read record step 4.4c: [Read Record] step 4 MUST return no data.
       read record step 4.4g: IF no destruction record EXISTS for the event THEN [Read Record] step 4 MUST read action reference, actor reference and attestation instant from the attestation records through event to attestation's entry for the event.
   Deleted: read record step 4.4d. Execution Contract Database 1 owns it.
   Deleted: read record step 4.4e. Execution Contract Database 1 owns it.
   Deleted: read record step 4.4f. Execution Contract Database 1 owns it.
   read record step 4.5: IF retention state EQUALS Retained AND the event's data IS unreadable THEN [Read Record] step 4 MUST NOT return BEFORE re-reading the retention.
   read record step 4.6: IF the retention state EQUALS Purged at the re-read THEN [Read Record] step 4 MUST answer as for step 4.4.
   read record step 4.7: IF the retention state EQUALS Retained at the re-read THEN [Read Record] step 4 MUST answer no answer, the unreadable payload standing as an outage of Event Log (Term dependency outage).
   ```
   Term audit record: the join of the event's action reference, actor reference, sequence number, recording instant and, for a live event, data (read record step 4.4c); the attestation id from event to attestation; the retention record's retention id, policy reference, state, retention deadline, purge deadline and purge instant where set; and the coverage status.

   Term coverage status: covered (the covering evidence id with the seal's full sequence-number range, sealing instant, and anchoring instant where the mechanism anchors) | unsealed tail (sequence number EXCEEDS sealed through) | records-purged (the event's own sequence number is a member of the covering seal's purged events) | partially purged (the event's sequence number is not a member while another member's is).

   Term destruction record: the covering seal's purged events with the event's sequence number added, and the pair, written at [Purge Event] step 2 in one durable write, carrying as well, for an `audit.compensation` or `audit.reconciliation` event, the action reference and the subject, id and disposition its payload carried (purge event step 2.3a); the erasure outcome is no part of it (erasure outcomes 2, erasure outcomes 4).

   Term pair: the destruction record's `(event_id, attestation_id)`, captured at [Purge Event] step 2.

   Term who / what / when: the attestation's actor reference, action reference and attestation instant.

5. **Orphan window.**
   ```
   read record step 5.1: IF a log entry EXISTS AND no retention record EXISTS THEN [Read Record] step 5 MUST return the audit record with retention status unresolved (compensation window).
   read record step 5.2: [Read Record] step 5 MUST NOT fabricate a retention.
   NOTE: open 2026-10-25-c — over unreadable data, step 5.1 returns an audit record whose action reference, actor reference and attestation id sit in that unreadable data field, where step 4.7 answers a Retained retention over unreadable data no answer (read record step 5.1, read record step 4.7, Invariant 6.1).
   ```
6. **No verification** (read record 4). [Read Record] presents; [Verify Record] proves. The split is forced by Invariant 7 — verification needs the original payload re-presented, and a read surface that fetched it internally would destroy the asymmetry the composition exists to surface.

---

#### Verify Record contract

```
verify_record(event_id, original_event_payload)
  answers outcome | not-known
```

outcome is `verified` | `failed-verification(reason)` | `unverifiable(reason)`, each of which may additionally carry the qualifier `(compensation-window)`.

```
verify record 1: The qualifier (compensation-window) MUST ride a separate channel beside the outcome.
NOTE: watch the side-channel qualifier (verify record 1).
verify record 2: The composition MUST NOT fold the qualifier into a reason.
verify record 3: The composition MUST NOT promote the qualifier to an outcome.
verify record 4: not-known MUST NOT carry the qualifier.
verify record 5: IF the outcome is failed-verification or unverifiable THEN [Verify Record] MUST NOT return BEFORE re-reading the retention through event to retention.
verify record 6: IF the retention state EQUALS Purged at the re-read THEN [Verify Record] MUST land failed-verification(purged).
Deleted: verify record 7. Execution Contract Error model 1 owns it: a constituent read whose answer never arrives leaves [Verify Record] no answer to give, and none to read as not-known or as unverifiable.
```

Steps:

1. **Retention state first.**
   ```
   verify record step 1.1: [Verify Record] step 1 MUST read the retention record through event to retention.
   verify record step 1.2: IF retention state EQUALS Purged THEN [Verify Record] step 1 MUST land failed-verification(purged).
   verify record step 1.3: [Verify Record] MUST NOT run step 3 for a purged event.
   ```
2. **Log presence.**
   ```
   verify record step 2.1: [Verify Record] step 2 MUST read the event per event to sequence 4 and event to sequence 5.
   verify record step 2.2: IF no retention record EXISTS AND no log entry EXISTS THEN [Verify Record] step 2 MUST land not-known.
   verify record step 2.3: IF a log entry EXISTS AND no retention record EXISTS THEN [Verify Record] MUST proceed to step 3 and carry the qualifier on the outcome.
   ```
3. **Attestation.**
   ```
   verify record step 3.1: [Verify Record] step 3 MUST call ActorIdentity.verify on event to attestation's entry for the event id.
   verify record step 3.2: [Verify Record] step 3 MUST land a failed-verification(reason) whose reason DOES NOT EQUAL registry-unavailable with the reason prefixed attestation-.
   verify record step 3.3: [Verify Record] step 3 MUST route registry-unavailable to step 6.
   verify record step 3.4: [Verify Record] step 3 MUST land Actor Identity's not-known as failed-verification(attestation-not-known).
   verify record step 3.5: IF step 3 lands failed-verification AND the retention state DOES NOT EQUAL Purged at the re-read THEN [Verify Record] MUST return the step-3 outcome.
   verify record step 3.6: IF step 3 lands failed-verification THEN [Verify Record] MUST NOT run steps 4, 5 and 6.
   verify record step 3.7: IF step 3 routes registry-unavailable THEN [Verify Record] MUST NOT run steps 4 and 5.
   verify record step 3.8: [Verify Record] MAY run steps 4 and 5 ONLY IF step 3 landed verified.
   ```
4. **Locate the covering seal.**
   ```
   verify record step 4.1: [Verify Record] step 4 MUST locate the covering seal.
   verify record step 4.2: IF partly-purged coverage EXISTS THEN [Verify Record] step 4 MUST land unverifiable(partially-purged-coverage).
   verify record step 4.3: IF partly-purged coverage EXISTS THEN [Verify Record] MUST NOT run step 5.
   verify record step 4.4: IF no covering seal EXISTS AND unsealed tail mode EQUALS strict THEN [Verify Record] step 4 MUST land failed-verification(unsealed).
   verify record step 4.5: WHEN no covering seal EXISTS AND unsealed tail mode EQUALS lenient:
       verify record step 4.5a: [Verify Record] step 4 MUST treat coverage as satisfied.
       verify record step 4.5b: [Verify Record] MUST skip step 5 and proceed to step 6.
   ```
   Term partly-purged coverage: a covering seal whose purged events is non-empty and does not contain the event's own sequence number.

5. **Seal.**
   ```
   verify record step 5.1: [Verify Record] step 5 MUST call TamperEvidence.verify(evidence id, original event payload).
   verify record step 5.2: [Verify Record] step 5 MUST land a failed-verification(reason) whose reason DOES NOT EQUAL mechanism-verification-unavailable with the reason prefixed seal-.
   verify record step 5.3: [Verify Record] step 5 MUST route mechanism-verification-unavailable to step 6.
   verify record step 5.4: [Verify Record] step 5 MUST land Tamper Evidence's not-known as failed-verification(seal-not-known).
   NOTE: open 2026-10-03-t — the seal is checked against the caller's presentation and the attestation link is taken from the stored payload, and no step compares the two (verify record step 3.1, verify record step 5.1).
   ```
6. **Availability arm.**
   ```
   verify record step 6.1: [Verify Record] step 6 MUST land unverifiable(attestation-registry-unavailable) for registry-unavailable.
   verify record step 6.2: [Verify Record] step 6 MUST land unverifiable(seal-mechanism-verification-unavailable) for mechanism-verification-unavailable.
   ```
7. **Verified.**
   Term standing finding: a `failed-verification(reason)` or `unverifiable(reason)` outcome one of steps 1–6 landed.
   ```
   verify record step 7.1: IF no standing finding EXISTS THEN [Verify Record] step 7 MUST land verified.
   verify record step 7.2: IF step 2 established the compensation window THEN the returned outcome MUST carry the qualifier.
   ```

---

#### Purge Eligible contract

```
purge_eligible()
  answers list of event_ids
```

```
purge eligible 1: [Purge Eligible] MUST read eligibility through Retention Window's declared read.
purge eligible 2: [Purge Eligible] MUST map each eligible retention id to the event id through the retention record's record reference.
purge eligible 3: [Purge Eligible] MUST NOT re-derive eligibility.
purge eligible 4: [Purge Eligible] MUST NOT share the projection's now reading with a later RetentionWindow.purge.
purge eligible 5: [Purge Eligible] MUST NOT reject.
purge eligible 6: [Purge Eligible] MUST NOT filter by legal hold.
Deleted: purge eligible 7. Execution Contract Error model 1 owns it: a declared read of Retention Window whose answer never arrives leaves [Purge Eligible] no answer to give, and none to read as an empty list.
purge eligible 8: The deployment MUST call [Purge Event] for EVERY event [Purge Eligible] answers.
purge eligible 9: IF a Retained retention's purge deadline PRECEDES now AND no hold EXISTS over the event THEN the deployment MUST surface a compliance alert.
```

NOTE: open 2026-10-24-a — [Purge Eligible] answers every eligible event id at once, with no bound and no paging (purge eligible 1, purge eligible 2).

Term purge sweep: the deployment's calls of [Purge Event] over the events [Purge Eligible] answers (purge eligible 8) — the sweep a refusal that changed nothing leaves the event to (purge event 3c).

---

#### Purge Event contract

```
purge_event(event_id)
  answers ok
  refuses not-known | not-eligible | retention-unresolved | cascade-failure(step) | under-legal-hold
```

For any event whose retention has elapsed, the composition coordinates a cascade across the four constituents' records. The arms: not-known for an id no constituent knows; [Not Eligible] when Retention Window refuses because the period has not elapsed; [Retention Unresolved] when the id resolves to a log entry but to no retention record; [Cascade Failure] carrying the step; and, where a Legal Hold is composed, [Under Legal Hold].

```
purge event 1: IF no retention record EXISTS AND no log entry EXISTS THEN [Purge Event] MUST land not-known.
purge event 2: [Cascade Failure] MUST carry EXACTLY ONE OF seal, hold, step-1, step-2, step-3, in-flight.
purge event 3: WHEN cascade-failure EQUALS seal OR cascade-failure EQUALS hold OR cascade-failure EQUALS step-1:
    purge event 3a: The cascade MUST leave the retention as the cascade found the retention, Retained for a first run, a step-1 call that answered no answer and committed under the cascade's lease excepted (Capability requirement 13).
    purge event 3b: The cascade MUST NOT write a destruction record or an erasure outcome.
    purge event 3c: [Purge Eligible] MUST re-offer the event for as long as the retention EQUALS Retained.
purge event 3d: IF cascade-failure EQUALS in-flight THEN the cascade MUST write nothing.
purge event 3e: IF cascade-failure EQUALS in-flight THEN the cascade MUST leave the retention as found.
purge event 4: WHEN cascade-failure EQUALS step-2 OR cascade-failure EQUALS step-3:
    purge event 4a: The reconciliation scan MUST re-drive the entry.
    purge event 4b: The deployment MUST surface an open entry not under a hold as a compliance alert.
    NOTE: watch persistent state — the source says *until the scan closes it*; the duration is carried by the term open entry (purge event 4b), by *for the rest of the run* (Per-act critical section 5) and by *through the outage* (Composition-level invariant 1b).
purge event 5: WHEN Legal Hold EQUALS composed:
    purge event 5a: [Purge Event] MUST carry the under-legal-hold arm.
    purge event 5b: IF hold EXISTS THEN [Purge Event] MUST land under-legal-hold with no further cascade step executed.
    purge event 5c: [Purge Event] MUST read hold under the held critical section AFTER step 0.1a and BEFORE step 0.2.
    purge event 5d: IF a re-drive lands under-legal-hold THEN the retention, the destruction record and the content MUST stand as found.
    purge event 5e: IF the hold read does not return the holds THEN [Purge Event] MUST land cascade-failure(hold) with no cascade step executed.
purge event 6: IF Legal Hold DOES NOT EQUAL composed THEN [Purge Event] MUST NOT carry the under-legal-hold arm.
purge event 7: WHEN mid-cascade expiry EXISTS:
    purge event 7a: [Purge Event] MUST NOT issue a further write.
    purge event 7b: [Purge Event] MUST return cascade-failure(step) naming the first step not completed.
    purge event 7c: The reconciliation scan MUST re-drive the cascade.
purge event 7d: IF the lease expires BEFORE step 1 commits THEN [Purge Event] MUST NOT issue step 1 AND MUST land cascade-failure(step-1).
purge event 8: IF a read [Purge Event] issues at step 0, step 0½, step 2 or step 3 answers no answer AND no rule above names the arm THEN [Purge Event] MUST land cascade-failure naming the step AND MUST issue no further write, step 0 naming `seal`, step 0½ naming `step-1`, step 2 naming `step-2` and step 3 naming `step-3`.
```

Term hold: a Legal Hold preservation order whose hold state EQUALS active and whose record reference EQUALS the event id, read from the Legal Hold database instance wired to this instance.

Term mid-cascade expiry: the lease expiring after step 1 has committed and before step 3's outcome record has landed.

Term cascade-failure(step-3): a delegation not issued, an outcome not recorded, or a reported `destruction-failed(reason)` — three failures that, over an incomplete cascade, leave one record, retention *Purged* with no destroyed outcome: the content readable where no delegation was issued or the mechanism reported destruction-failed, and already destroyed where the mechanism destroyed and the outcome was not recorded; over a completed cascade, a repeat whose step 3 cannot read the destroyed outcome lands it too, its delegation not issued (purge event step 3.6, purge event 8), and the cascade stays complete.

Steps:

0. **Seal before purge.**
   ```
   purge event step 0.1: [Purge Event] step 0 MUST resolve event to sequence for the event id.
   purge event step 0.1a: IF purge event 1's condition EXISTS at step 0.1 THEN [Purge Event] MUST land not-known AND MUST NOT run step 0.2.
   purge event step 0.2: IF the event's sequence number EXCEEDS sealed through THEN [Purge Event] step 0 MUST invoke [Seal Now].
   purge event step 0.3: [Purge Event] MUST NOT run step 1 BEFORE the covering seal exists.
   purge event step 0.4: IF [Seal Now] rejects other than with [Nothing To Seal] THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.5: IF the event's sequence number DOES NOT EXCEED sealed through THEN [Purge Event] step 0 MUST NOT invoke [Seal Now].
   purge event step 0.6: [Purge Event] MUST NOT run step 0 BEFORE taking the per-act critical section keyed by event id, a [Purge Event] re-driven by the first half excepted (Per-act critical section 14).
   purge event step 0.7: IF another holder holds the critical section THEN [Purge Event] MUST land cascade-failure(in-flight), a [Purge Event] re-driven by the first half excepted (Per-act critical section 14).
   purge event step 0.8: IF [Seal Now] lands [Nothing To Seal] THEN [Purge Event] step 0 MUST re-resolve the covering seal and proceed ONLY IF one EXISTS.
   purge event step 0.10: IF the take at step 0.6 answers no answer THEN [Purge Event] MUST land cascade-failure(in-flight).
   purge event step 0.9: IF no covering seal EXISTS after [Nothing To Seal] THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.12: IF [Seal Now] answers AND no covering seal EXISTS for the event THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.11: IF the read at step 0.1 answers no answer THEN [Purge Event] MUST land cascade-failure(seal) AND MUST NOT land not-known.
   ```
   An event more than slice cap events past sealed through is reached one slice a call: [Seal Now] seals at most slice cap events (seal now 1a), so the purge lands cascade-failure(seal) (purge event step 0.12) and stays on [Purge Eligible]'s list (purge event 3c) until a slice covers it, a wait the unsealed tail's depth sets and the deployment watches (Unsealed tail 1).

   **Step 0½ — retention must be resolved before the cascade proper begins.**
   ```
   purge event step 0½.1: [Purge Event] MUST NOT run step 0½ BEFORE step 0.
   purge event step 0½.2: IF a log entry EXISTS AND no retention record EXISTS THEN [Purge Event] step 0½ MUST land retention-unresolved.
   purge event step 0½.3: A retention-unresolved refusal MUST run no cascade step.
   purge event step 0½.4: A retention-unresolved refusal MUST leave step 0's seal standing.
   purge event step 0½.5: The composition MUST NOT invent a retention in order to expire an event.
   purge event step 0½.6: IF the read of event to retention at step 0½ answers no answer THEN [Purge Event] step 0½ MUST land cascade-failure(step-1) AND MUST NOT land retention-unresolved AND MUST NOT land not-known.
   ```
1. **Purge the retention.**
   ```
   purge event step 1.1: [Purge Event] step 1 MUST call RetentionWindow.purge(retention id).
   purge event step 1.2: [Purge Event] step 1 MUST land retention-period-not-elapsed as [Not Eligible].
   purge event step 1.3: [Purge Event] step 1 MUST pass not-known through unchanged.
   purge event step 1.4: IF step 1 lands not-retained THEN the cascade MUST resume from step 2.
   purge event step 1.5: [Purge Event] step 1 MUST land storage-failure as cascade-failure(step-1).
   purge event step 1.6: IF the purge answers no answer THEN [Purge Event] step 1 MUST land cascade-failure(step-1).
   ```
2. **Write the destruction record, before anything is destroyed.**
   ```
   purge event step 2.1: [Purge Event] step 2 MUST write the destruction record in one durable write, a step 2 that reads a destruction record excepted (purge event step 2.7).
   purge event step 2.2: The destruction record MUST add the event's sequence number to the covering seal's purged events.
   purge event step 2.3: The destruction record MUST carry the pair, read from event to attestation with rebuild-on-miss.
   purge event step 2.3a: IF the event's action reference EQUALS audit.compensation OR the event's action reference EQUALS audit.reconciliation THEN the destruction record MUST carry the action reference, the payload's subject-kind discriminator, the id the subject names and the payload's disposition where the payload carries one.
   purge event step 2.4: [Purge Event] MUST NOT issue the delegation BEFORE the destruction record has landed.
   purge event step 2.5: A step-2 failure MUST land cascade-failure(step-2).
   purge event step 2.8: IF the destruction record's write answers no answer THEN [Purge Event] step 2 MUST land cascade-failure(step-2).
   purge event step 2.6: [Purge Event] step 2 MUST NOT write BEFORE reading the destruction record under the held critical section.
   purge event step 2.7: IF a destruction record EXISTS THEN [Purge Event] step 2 MUST adopt the record as landed.
   ```
3. **Delegate the destruction.**
   ```
   purge event step 3.1: [Purge Event] step 3 MUST delegate destruction to erasure mechanism, a step 3 that reads a destroyed outcome excepted (purge event step 3.12).
   purge event step 3.2: The cascade MUST NOT destroy content.
   purge event step 3.3: The delegation MUST name the whole of Event Log's data field and the attestation's proof, and nothing else.
   purge event step 3.4: [Purge Event] step 3 MUST record the mechanism's outcome in erasure outcomes.
   purge event step 3.5: IF outcome EQUALS destruction-failed THEN [Purge Event] step 3 MUST land cascade-failure(step-3).
   purge event step 3.6: A delegation not issued MUST land cascade-failure(step-3), a step 3 that reads a destroyed outcome excepted (purge event step 3.12).
   purge event step 3.7: An outcome not recorded MUST land cascade-failure(step-3).
   purge event step 3.8: The cascade MUST NOT record a destroyed outcome the mechanism did not report.
   purge event step 3.9: The composition MUST NOT repair a partly-purged seal.
   purge event step 3.10: A partly-purged seal MUST remain the one seal over the seal's range.
   purge event step 3.11: [Purge Event] step 3 MUST NOT issue the delegation BEFORE reading erasure outcomes under the held critical section.
   purge event step 3.12: IF a destroyed outcome EXISTS THEN [Purge Event] step 3 MUST NOT issue the delegation.
   ```
4. **What survives a completed cascade.**
   ```
   purge event step 4.1: A completed cascade MUST leave standing the retention record in Purged with purge instant, the seal record with the event's sequence number in purged events, the destruction record's pair, the destroyed outcome in erasure outcomes, and the attestation's surviving fields.
   purge event step 4.2: The delegation MUST cover the event and the attestation in one cascade under one retention id.
   ```
   Term completed cascade: a cascade whose step 3 recorded a destroyed outcome.

### Wiring decision

*The cascade-on-purge rule.*

The composition's load-bearing wiring decision: when an event's retention elapses, the composition first ensures the event is covered by a seal (purge event step 0.1 through 0.5), then purges the one record it is permitted to purge — the Retention Window record (purge event step 1.1) — writes a destruction record adding the event's sequence number to the covering seal's purged events set and capturing the event's `(event_id, attestation_id)` binding before it is destroyed (purge event step 2.1 through 2.4), and delegates the shred of Event Log's data field and the attestation's proof to the deployment's erasure mechanism (purge event step 3.1 through 3.4). It coordinates the cascade and records the outcome; it destroys nothing itself (purge event step 3.2), disposes of no seal (Composes 16), and re-seals nothing (seal now 12).

WHY:
*Principle.* When a regulated record reaches the end of its lifetime, the records of all four constituents must reach a coherent end state together: no retained event without attribution or integrity coverage, and no destroyed event leaving a dangling attestation or a live content claim on a seal. Coordinating that across four constituents' records is work no constituent can do — each knows only its own record — so it belongs at the composition layer, with the honest record of what the coordination achieved.

*Likely objection.* Why not have the composition delete the content directly? It knows which event, which attestation and which seal are involved, and a cascade that ends in a delegation looks like one that does not finish.

*Mechanism that resolves it.* Two of the four constituents forbid it in their own invariant text, and a composition that overrode them would be silently substituting weaker atoms. Event Log declares only append and read, holds Invariant 1 (append-only), and routes true deletion to a composing pattern in its *Erasure where law requires it* edge case. Actor Identity's Invariant 9 states that an attestation is never deleted by the atom, and its Composition note 4 gives an attestation's retention to the composing pattern. So the destruction surface is named where the atoms say it belongs — an Erasure Tombstone *(forthcoming)* composing pattern, or a shred at the storage layer, declared per deployment — and this composition wires the coordination around it.

*Result.* Four constituent invariants hold verbatim over their instances — Event Log's 1 and 2, Actor Identity's 9 and 1 — which is what makes Invariant 5 a literal claim; a lawfully destroyed event still answers `failed-verification(purged)` from its *Purged* record, still leaves a seal whose purged events names it, and still distinguishes lawful destruction from a missing record (Invariant 8).

#### Boundary one — only mechanisms that shred conform

The class boundary's home; erasure mechanism 1 through 9, [Purge Event] step 3, Invariant 5 and the [Purge Event] term entry cite it.

```
Boundary one 1: [Purge Event] MUST NOT write the destruction record BEFORE step 1's transition has committed.
Boundary one 2: The composition MUST NOT condition RetentionWindow.purge's outcome on the erasure mechanism's answer.
Boundary one 3: The composition MUST record a divergence between a Purged retention and readable content.
Boundary one 4: The composition MUST surface a divergence as a compliance alert.
Boundary one 5: IF purge age EXCEEDS audit edge THEN an auditor MUST read a divergence as a residual finding against the erasure mechanism.
Boundary one 6: The first half MUST re-drive a divergence on EVERY run.
```

Term divergence: a retention in *Purged* over content still readable — `cascade-failure(step-3)`; a destruction-failed outcome in erasure outcomes.

#### Boundary two — the composition disposes of no seal and writes no replacement

```
Boundary two 1: EVERY seal MUST remain the only seal over the seal's range.
Boundary two 2: IF seal disposal EXISTS THEN the deployment MUST compose Erasure Tombstone for the seal-disposal surface and the coverage bookkeeping.
Boundary two 3: IF re-sealing EXISTS THEN the deployment MUST compose Seal Lifecycle.
Boundary two 4: The composition MUST NOT carry a which-seal-is-current fact.
```

Term seal disposal: a jurisdiction's requirement to dispose of a seal — a commitment over erased personal data treated as residual personal data.

Term re-sealing: a deployment's requirement to write a second seal over a range some seal covers — a partly-purged seal's survivors made verifiable again, or a seal rotated onto a sound mechanism ahead of a deprecation.

### Reconciliation

The scan is this composition's reconciliation leg: each finding closes within the compensation window (Reconciliation 4) and the scan writes the compensating records, so something awaits its output.

#### The reconciliation scan — three halves

The composition's three liveness arms fail in three structurally different ways — a cascade that stopped partway, an attestation nothing points at, and an event nothing bounds — and each needs its own detector, predicate and compensating write. A scan that ran only the first two would carry the third state forever, because no other surface looks for it.

```
Reconciliation 1: The reconciliation scan MUST run a first half over Purged retentions, a second half over the attestation records, and a third half over the audit log.
Reconciliation 1b: A leg MUST NOT wait on the probe of Invariant 1.10 BEFORE taking the leg's critical section.
Reconciliation 1a: A leg MUST NOT wait for another leg's closure BEFORE the leg starts, within a half or across halves, the probe of Invariant 1.10 excepted.
Deleted: Reconciliation scan 1. Reconciliation 1 owns it.
Deleted: Reconciliation scan 2. Reconciliation 2 owns it.
Deleted: Reconciliation scan 3. Reconciliation 3 owns it.
Deleted: Reconciliation scan 4. Reconciliation 4 owns it.
Deleted: Reconciliation scan 5. Reconciliation 5 owns it.
Deleted: Reconciliation scan 6. Reconciliation 6 owns it.
Deleted: Reconciliation scan 7. Reconciliation 7 owns it.
Reconciliation 2: The scan MUST surface EVERY unreconciled finding as a compliance alert.
Reconciliation 3: The scan MUST NOT carry an unreconciled finding silently.
Reconciliation 4: The scan MUST close EVERY finding WITHIN compensation window of the finding's creation.
NOTE: watch satisfaction — what a run that misses WITHIN is (Reconciliation 4, Invariant 1.4, Invariant 2.2) is decided by Composition-level invariant 1 for an outage and by Check 2 otherwise; the language says nothing.
Reconciliation 5: The scan MUST read now once per run at the scan's own seam.
Reconciliation 5b: The scan MUST NOT start a run's enumeration BEFORE taking that run's reading of Reconciliation 5.
Reconciliation 5a: A leg MUST read now at the leg's take, solely to size the leg's lease under Per-act critical section 13a.
Reconciliation 6: The scan MUST NOT write BEFORE taking the per-act critical section for the act.
Reconciliation 7: EVERY half MUST decide a write by the half's own predicate, read under the critical section.
```

Term leg: one scan half's handling of one act, from its examination to its closure.

Term record edge: `(record_action_completion_bound + clock_offset_allowance)`.

Term purge edge: `(purge_completion_bound + clock_offset_allowance)`.

Term horizon: the lesser of the retention periods retention policy gives an `audit.compensation` event and an `audit.reconciliation` event.

Term purge age: `(now - purged_at)`.

Term attestation age: `(now - attested_at)`.

Term event age: `(now - recorded_at)`.

The second half's lower edge, and the third half's for an unretained event, is the commit of the [Record Action] that wrote the record, not an age: its writes commit together (Execution Contract Database 1), so no leg reads a record action still in flight, and an attestation with no event, or an event with no retention, is the evidence a refused call left (record action step 7.11).

*First half — the half-completed cascade.*

```
First half 1: The first half MUST enumerate Purged retentions.
First half 2: IF purge edge EXCEEDS purge age THEN the first half MUST NOT examine the retention.
First half 3: The first half MUST test EVERY examined retention for a purged events membership, a pair in the destruction record, and a destroyed outcome in erasure outcomes.
First half 4: The first half MUST test for a destroyed outcome.
First half 5: The first half MUST re-drive a retention failing First half 3 through [Purge Event].
First half 6: The first half MUST NOT re-read the predicate BEFORE taking the critical section keyed by event id.
First half 7: The first half MUST NOT write BEFORE re-reading the predicate under the critical section.
First half 8: The first half MUST re-drive EVERY examined open entry on EVERY run.
First half 9: IF a re-drive lands under-legal-hold THEN the first half MUST leave the entry open and MUST NOT count the entry against compensation window.
First half 10: The first half MUST re-drive an entry left open under a hold on the first run after the hold is released.
First half 11: IF a hold over an open entry is released THEN the first half MUST count the entry's compensation window from the instant of the first run that reads no active hold over the event, AND MUST NOT count the window from a release instant the Legal Hold records carry, which a caller may have supplied and backdated (Legal Hold Operation 39, Operation 41).
First half 12: The first half MUST take as upper edge the retention policy of the audit instance the first half reads, under which the Purged retention (Retention Window Invariant 10.1), the seal record (retention policy 5), the destruction record and the erasure outcome (Execution Contract Database 3, Execution Contract Database 4) stand indefinitely.
```

NOTE: open 2026-08-30-d — a divergence whose erasure mechanism only ever answers destruction-failed, breaking erasure mechanism 10, is re-driven on every run (Boundary one 6, First half 8) and has no terminus; past the audit edge it is a residual finding against the mechanism (Check 5.15).

Term suspended entry: an open entry a run landed under-legal-hold, from that run until a later run reads no active hold over the event — the entry First half 9 leaves uncounted and Composition-level invariant 1e restarts.

*Second half — the orphan-attestation predicate.*

```
Second half 1: The second half MUST build the binding set.
Second half 2: The second half MUST treat an attestation absent from the binding set as an orphan.
Deleted: Second half 3. Execution Contract Database 1 owns it.
Second half 4: IF attestation age EXCEEDS horizon AND the orphan's attestation id IS NOT IN compensated attestations AND the orphan's attestation id IS NOT IN reported beyond horizon THEN the second half MUST report the orphan as beyond the horizon.
Second half 5: IF attestation age EXCEEDS horizon THEN the second half MUST NOT write a compensation.
Second half 6: A beyond-horizon report MUST carry subject set to attestation, the attestation id and disposition set to beyond-horizon, as an audit.reconciliation record.
Second half 7: The second half MUST NOT report BEFORE reading reported beyond horizon under the critical section.
Second half 8: The second half MUST NOT report an orphan whose attestation id is a member of reported beyond horizon.
Second half 9: The second half MUST NOT write a compensation BEFORE reading compensated attestations under the critical section keyed by the orphan's attestation id.
Second half 10: The second half MUST NOT write a compensation for a reconciled orphan.
Second half 11: The second half MUST hold the critical section through the compensating write.
Second half 12: A writer other than the scan MUST NOT write an orphan's compensation.
Second half 13: IF attestation age DOES NOT EXCEED horizon THEN the second half MUST write EXACTLY ONE compensation per orphan, a duplicate of Durability 5 excepted.
Deleted: Second half 16. Execution Contract Database 1 owns it.
Second half 17: The second half MUST serve the marker reads of Second half 4 and Second half 9 and the narrated read of Compensation 10 from ONE enumeration read under the critical section.
Second half 14: The second half MUST take an attestation id from an event payload the full enumeration reads, whatever the event's retention state.
Second half 15: The second half MUST read the destruction records AFTER the full enumeration.
Second half 18: IF the full enumeration returns an event whose data is unreadable AND no destruction record names the event THEN the second half MUST write no compensation in the run AND MUST surface a compliance alert.
```

Term binding set: the union of the attestation id values carried in every event payload the full enumeration reads, whatever the event's retention state, and the attestation id values in destruction records.

Term orphan: an attestation in the database whose attestation id is in neither enumeration of the binding set.

*Third half — the unretained-event predicate.*

```
Third half 1: The third half MUST enumerate the audit log by the full enumeration.
Third half 2: The third half MUST test EVERY returned event against event to retention with rebuild-on-miss.
Third half 3: The third half MUST NOT conclude a missing retention BEFORE rebuilding event to retention.
Deleted: Third half 4. Execution Contract Database 1 owns it.
Third half 5: The third half MUST take the critical section keyed by the event's payload attestation id for a true miss.
Third half 6: The third half MUST NOT place BEFORE re-reading event to retention under the critical section.
Third half 7: The third half MUST hold the critical section through the placement.
Third half 8: The third half MUST NOT place BEFORE the audit.reconciliation intent has landed.
Third half 9: The third half MUST NOT write the audit.compensation record BEFORE the placement has landed.
Third half 10: The audit.compensation record MUST carry subject set to event and the event id.
Third half 11: The scan MUST NOT retry within a run a reconciliation-path [Record Action] refused with recording-failure.
Third half 12: The third half MUST treat an owed narration as a repair to record.
Third half 13: The next run MUST NOT record an owed compensation BEFORE confirming under the critical section that the retention exists.
Third half 14: The third half MUST NOT treat an intent past the horizon as a finding.
Third half 15: The third half MUST place the retention under the policy resolved from the event's payload by the resolution [Record Action] step 4 uses.
Third half 16: IF the placement is refused OR answers state-unavailable THEN the third half MUST NOT retry within the run.
Third half 17: The deployment MUST alert on invalid-policy and policy-not-found from the third half's placement as a deployment fault.
```

Term true miss: a miss of event to retention that survives the rebuild.

Term owed narration: an `audit.reconciliation` intent whose subject is set to event, carrying no disposition, older than record edge, inside the horizon, whose subject has no matching `audit.compensation` record — both read composition-side out of the full enumeration filtered on the two reserved references.

The compensating placement takes no policy of its own: the event is in the log with the action reference, actor reference and data a selector reads, so the third half resolves the policy exactly as step 4 would have (Third half 15, Primitive policy 17), and a knob that is a policy reference gives the same one. Retention Window starts the clock at placement, so an event the scan places late is retained for the retention period from the placement, over-retained by the scan's delay, which the compensation window bounds (Retention Window State 4).

*Where the compensation lands — the composition is its own event log.*

```
Compensation 1: The scan's second half and third half MUST record EVERY finding as an audit.reconciliation event through [Record Action].
Compensation 2: The scan MUST record one audit.reconciliation record per finding, the beyond-horizon report of Second half 6 excepted (Compensation 11).
Compensation 3: The scan MUST NOT write a compensating act BEFORE the finding's audit.reconciliation record has landed.
Compensation 4: The scan MUST record EVERY compensating write as an audit.compensation event through [Record Action].
Compensation 5: The scan MUST supply actor reference set to reconciliation operator and credential set to reconciliation operator credential at EVERY reconciliation-path [Record Action].
Compensation 6: The composition MUST NOT grow composition records for the reconciliation history.
Compensation 7: The composition MUST NOT add an action for the reconciliation path.
Compensation 8: The composition MUST place a reconciliation-path event under retention policy like any other event.
Compensation 9: A finding's audit.reconciliation record MUST carry subject and the id the subject names.
Compensation 10: The scan MUST NOT record a finding's audit.reconciliation record BEFORE reading narrated under the critical section.
Compensation 11: IF the finding is narrated THEN the scan MUST NOT record a second audit.reconciliation record for the finding, the beyond-horizon report of Second half 6 over an orphan whose only record is the orphan's intent excepted.
Compensation 12: The first half MUST NOT record an audit.reconciliation event.
Compensation 13: The scan MUST NOT retry within a run a reconciliation-path [Record Action] refused with invalid-request(step-3) or invalid-request(step-4).
Compensation 14: The deployment MUST alert on an invalid-request refusal of a reconciliation-path [Record Action] as a deployment fault.
Compensation 15: The scan MUST retry a finding whose reconciliation-path [Record Action] was refused with invalid-request or recording-failure on the next run.
Compensation 16: The deployment MUST alert on a reconciliation-path recording-failure standing across two runs.
Compensation 17: IF a reconciliation-path [Record Action] is refused with invalid-credential THEN the scan MUST alert as a deployment fault AND MUST NOT retry within the run.
Compensation 18: The scan MUST treat a reconciliation-path [Record Action] that answers state-unavailable as refused with recording-failure.
```

Term intent: a finding's `audit.reconciliation` record, which the scan lands before the act it announces (Compensation 3).

Term narrated: a finding whose subject and id an `audit.reconciliation` record live in the log names, read composition-side out of the full enumeration filtered on the reserved reference.

### Instance start

```
Instance start 1: IF retention policy EQUALS blank THEN the instance MUST NOT start.
Instance start 2: IF seal cadence EQUALS blank THEN the instance MUST NOT start.
Instance start 3: IF seal mechanism EQUALS blank THEN the instance MUST NOT start.
Instance start 4: IF erasure mechanism EQUALS blank THEN the instance MUST NOT start.
Instance start 5: IF compensation window EQUALS blank THEN the instance MUST NOT start.
Instance start 6: IF reconciliation cadence EQUALS blank AND time arm EQUALS blank THEN the instance MUST NOT start.
Instance start 7: IF reconciliation operator EQUALS blank THEN the instance MUST NOT start.
Instance start 8: IF reconciliation operator credential EQUALS blank THEN the instance MUST NOT start.
Instance start 9: IF payload cap EQUALS blank THEN the instance MUST NOT start.
Instance start 10: IF attestation id width EQUALS blank THEN the instance MUST NOT start.
Instance start 11: IF record action completion bound EQUALS blank THEN the instance MUST NOT start.
Instance start 12: IF purge completion bound EQUALS blank THEN the instance MUST NOT start.
Instance start 13: IF compensation closure latency EQUALS blank THEN the instance MUST NOT start.
Instance start 14: IF clock offset allowance EQUALS blank THEN the instance MUST NOT start.
Instance start 15: IF no per-act critical section EXISTS THEN the instance MUST NOT start.
Instance start 16: The instance MAY start ONLY IF compensation window EXCEEDS closure sum.
Instance start 17: The instance MUST read EVERY term of closure sum at start.
Instance start 18: The instance MAY start ONLY IF compensation closure latency EXCEEDS closure spend.
Instance start 19: The instance MAY start ONLY IF compensation closure latency EXCEEDS re-drive spend.
Instance start 20: IF seal completion bound EQUALS blank THEN the instance MUST NOT start.
Instance start 21: The instance MUST resolve horizon at start from retention policy for an audit.compensation event AND for an audit.reconciliation event by action reference and actor reference alone (retention policy 6), and take the lesser of the two retention periods the deployment supplies (Capability requirement 11).
Instance start 22: The instance MAY start ONLY IF horizon EXCEEDS compensation window.
Instance start 23: The instance MAY start ONLY IF purge completion bound EXCEEDS twice seal completion bound.
Instance start 24: IF call pause bound EQUALS blank THEN the instance MUST NOT start.
Instance start 25: The instance MAY start ONLY IF EVERY completion bound EXCEEDS twice call pause bound (Lease Sizing 9).
Instance start 26: IF no scan scheduler EXISTS THEN the instance MUST NOT start.
Instance start 27: IF no sealing lock EXISTS THEN the instance MUST NOT start.
Instance start 28: The instance MUST run one enumeration of the audit log followed by one read of the destruction records, one of the attestation records and one of the retention records at start.
Instance start 29: IF seal cadence EQUALS interval-based AND no cadence driver EXISTS THEN the instance MUST NOT start.
Instance start 30: IF slice cap EQUALS blank THEN the instance MUST NOT start.
Instance start 31: IF Legal Hold EQUALS composed AND no Legal Hold database instance is wired to this instance THEN the instance MUST NOT start.
Instance start 32: IF Legal Hold EQUALS composed AND no hold placement EXISTS THEN the instance MUST NOT start.
```

Term closure sum: `((max((2 * record_action_completion_bound), purge_completion_bound) + (2 * clock_offset_allowance)) + (2 * (reconciliation_cadence + compensation_closure_latency)))`, plus `(purge_completion_bound + reconciliation_cadence)` WHERE Legal Hold EQUALS composed — one hold placement that holds an open entry's critical section when a first-half leg comes for it, placed or not: its lease (Capability requirement 7c) and the run it displaces (Per-act critical section 5).

Term completion bound: record action completion bound, purge completion bound and seal completion bound.

Term closure floor: `((4 * record_action_completion_bound) + (8 * call_pause_bound))`, plus `(6 * seal_completion_bound)` WHERE seal cadence EQUALS per-event, each of the three [Record Action] calls on the closure — the probe's and the two nested — sealing at step 6 before it returns (record action step 6.1), a seal priced at twice its bound as Instance start 23 prices it — the whole closure of the second and third halves is the probe's wait of Invariant 1.10, the intent, the placement under its live test and the compensation, each call carrying its pause.

Term closure spend: `((closure_floor + call_pause_bound) + (4 * measured_enumeration))` — what one closure of the second or third half spends of compensation closure latency: the call pause of the take (Per-act critical section 13a), up to two measured enumerations before the take — the second half's binding set and attestation records, the third half's audit-log pass and the rebuild of event to retention that makes a miss a true miss (Third half 3) — and the work bound's own, up to two under the lease.

Term re-drive spend: `((purge_completion_bound + call_pause_bound) + measured_enumeration)` — what one re-drive of the first half spends of compensation closure latency: the retention-record enumeration before the take (First half 1), the call pause of the take, and the cascade.

Term measured enumeration: the longest of one enumeration of the audit log followed by one read of the destruction records (Second half 15), one enumeration of the attestation records and one of the retention records, each run once at start (Instance start 28).

---

## Composition-level invariants

These invariants emerge from the composition; none belongs to a single constituent atom. Each carries a *Rests on:* line naming the wiring that establishes it and the constituent invariants it stands on. Per the section titled Structural-relation invariant templates in [`spec-format.md`](../spec-format.md), the composition's three structural relations are: event ↔ attestation, one-to-one, mandatory on both sides at quiescence (Invariant 1, in the orphan-freedom template's safety-plus-liveness form); event ↔ retention, one-to-one, mandatory on both sides at quiescence, the retention governing the event's attestation jointly (Invariant 2); seal → events, one-to-many, optional on the event side while the event is in the unsealed tail and mandatory once sequence number ≤ sealed through (Invariant 3) — a composed Seal Lifecycle *(forthcoming)* would make it many-to-one and own the *which seal is current* bookkeeping that reading requires. The inverse directions are read through the derived indexes; a lost index entry is a rebuild trigger, never a relation violation.

```
Composition-level invariant 1: WHEN dependency outage EXISTS:
    Composition-level invariant 1a: The liveness arms of Invariants 1, 2 and 8 MUST suspend for the outage.
    Composition-level invariant 1b: EVERY outstanding finding MUST stay surfaced through the outage.
    Composition-level invariant 1c: A finding's compensation window MUST run to the later of the window's own end and closure sum counted from the latest end among the dependency outages whose start PRECEDES the window's end as the window then stood, AND MUST NOT carry the window's end past the horizon counted from the finding's creation (Second half 4, Second half 5).
    Composition-level invariant 1d: The deployment MUST record the start instant and the end instant of every dependency outage in the outage record, AND the rule by which the deployment joins intermittent failures into one outage.
    Composition-level invariant 1f: The deployment MUST NOT record as one dependency outage two failures of a dependency between which a run's calls to that dependency all answered.
Composition-level invariant 1e: IF a run has landed an open cascade entry under-legal-hold (First half 9) AND a later run reads no active hold over the event THEN the entry's compensation window MUST restart at that later run's instant (First half 11).
Composition-level invariant 1h: IF a run has landed an open cascade entry under-legal-hold AND a later run reads no active hold over the event THEN the deployment MUST record the instant of EVERY run that landed the entry under-legal-hold and the instant of the later run, in the outage record.
Composition-level invariant 1i: IF a run has landed an open cascade entry under-legal-hold AND a later run reads no active hold over the event THEN an entry no run landed under-legal-hold MUST NOT restart.
Deleted: Composition-level invariant 1g. Execution Contract Database 3 and Execution Contract Database 4 own it.
```

Term dependency outage: a dependency whose calls answer no answer, state-unavailable or storage-failure over an interval longer than call pause bound — a constituent's records, the actor registry, the policy registry, the Legal Hold records, the erasure mechanism or the lease host. A standing unreadable payload no destruction record names (Second half 18) reads as an outage of Event Log, from the first run that met it to the first run that does not; the deployment owns clearing it by restoring the destruction record or, for an event no cascade reached, the content's readability.

Term compliance alert: a finding surfaced on the deployment's alerting surface, never silently carried.

Term quiescence: for an act, no [Record Action] in flight for it, its compensation window, run on under Composition-level invariant 1c and restarted under Composition-level invariant 1e, elapsed, the act not a suspended entry, constituent records reachable.

Term recorded through [Record Action]: the quantifier of Invariants 1, 2 and 8 — this composition declares exactly one way in, and an event written around it is not one these invariants cover (Non-goal 2).

- **Invariant 1 — Attribution coverage (safety + liveness at quiescence).**
  ```
  Invariant 1.1: An action of this composition MUST NOT leave an event in the audit log with the event's attestation side unbound and unsurfaced.
  Invariant 1.2: [Record Action] MUST NOT append BEFORE attesting.
  Invariant 1.3: EVERY appended event MUST carry a committed attestation id inside the event's own payload.
  Invariant 1.4: The scan MUST surface and reconcile EVERY orphan WITHIN compensation window of the orphan's attestation instant.
  Invariant 1.5: WHEN quiescence EXISTS:
      Invariant 1.5a: For EVERY event id recorded through [Record Action], event to attestation's entry MUST reference a recorded attestation carrying a readable action reference and actor reference.
      Invariant 1.5b: IF an attestation id IS NOT IN the binding set AND IS NOT IN compensated attestations AND IS NOT IN reported beyond horizon THEN the scan MUST report the attestation as an orphan.
  Invariant 1.6: WHEN retention state DOES NOT EQUAL Purged:
      Invariant 1.6a: The attestation's action reference and actor reference MUST match the event payload's, byte for byte.
  Invariant 1.7: WHEN retention state EQUALS Purged:
      Invariant 1.7a: The attestation the pair names MUST exist with readable surviving fields.
      Invariant 1.7b: An auditor MUST evaluate Invariant 1.5a against the attestation records' surviving fields alone.
      Invariant 1.7c: An auditor MUST NOT read the who, the what and the when from the destruction record.
  Invariant 1.8: A new orphan a compensating write leaves MUST count as a new finding with the new orphan's own attestation instant.
  Invariant 1.9: The scan's next run MUST retry EVERY orphan not yet reconciled.
  Invariant 1.10: A run MUST issue the run's first reconciliation-path [Record Action] alone.
  Invariant 1.11: A run MUST NOT start a further reconciliation-path [Record Action] BEFORE the first has returned.
  Invariant 1.12: IF a refusal of a reconciliation-path [Record Action] of the run left committed state, an attested orphan or an unretained event, THEN the run MUST NOT start a further reconciliation-path [Record Action].
  ```
  *Rests on:* [Record Action] steps 2, 3 and 5; the liveness arm on [Record Action] itself — the compensating record is written through it under `audit.compensation` and the finding under `audit.reconciliation` (Compensation 1 through 5), with the observable closure on compensated attestations pre-checked under the per-attestation id critical section (Second half 9, Concurrency 9); Actor Identity Invariants 1 (attestation immutability), 2 (action binding), 3 (actor binding) and 9 (attestation durability — why the closure needs a marker at all, since the orphan it forecloses deleting is permanent); Event Log Invariants 1 (append-only) and 2 (event immutability).

- **Invariant 2 — Retention coverage (safety + liveness at quiescence).**
  ```
  Invariant 2.1: A successful [Record Action] MUST NOT return an event id with no retention record.
  Invariant 2.2: The scan MUST reconcile EVERY unretained event WITHIN compensation window of the event's recording instant by placing the missing retention.
  Invariant 2.3: The reconciliation path MAY place a retention ONLY IF true miss EXISTS for the event id.
  Invariant 2.4: WHEN quiescence EXISTS:
      Invariant 2.4a: For EVERY event id recorded through [Record Action], event to retention's entry MUST reference EXACTLY ONE recorded retention of either retention state.
  ```
  *Rests on:* [Record Action] steps 3, 4 and 5; the liveness arm on [Record Action] itself (Compensation 1 through 5); the composition's own event to retention pre-check under the per-act critical section (Third half 2, Third half 3, Third half 5 through 7), which supplies the idempotence Retention Window's place_under_retention nowhere declares; the third half as the arm's detector (Third half 1); [Purge Event] step 0½ as the arm that keeps the cascade out of the window (purge event step 0½.2); Retention Window Invariants 1 (membership exclusivity), 5 (record reference and policy reference immutability), place_under_retention's fresh retention id per call (which makes the pre-check necessary) and 10 (retention record durability); Event Log Invariant 1.

- **Invariant 3 — Integrity coverage (modulo unsealed tail).**
  ```
  Invariant 3.1: IF the event's sequence number DOES NOT EXCEED sealed through THEN EXACTLY ONE seal MUST cover the event.
  Invariant 3.2: A purged event MUST remain covered by the covering seal.
  ```
  *Rests on:* [Seal Now] (and [Record Action] step 6 under per-event cadence), with [Purge Event] step 0 keeping it true of every purged event by construction; Tamper Evidence Invariants 1 (evidence immutability), 3 (record-set binding) and 9 (seal record durability, why a seal outlives the records it committed to); Event Log Invariants 3 (total order) and 4 (sequence-number monotonicity), without which a contiguous range is not a well-defined cover.

- **Invariant 4 — Cascade coordination on purge.**
  ```
  Invariant 4.1: A [Purge Event] MUST leave the four constituents' records in the coherent end state: the event covered, the retention in Purged with purge instant, the sequence number in purged events with the pair captured, and the destruction delegated with the outcome recorded.
  Invariant 4.2: The cascade MUST commit the steps in the declared order.
  Invariant 4.3: The composition MUST NOT claim an atomic set spanning the retention transition and the delegated destruction.
  Invariant 4.4: An auditor MUST clear the delegated destruction's completion outside the records.
  Invariant 4.5: EVERY member of a covering seal's purged events MUST name an event whose retention state EQUALS Purged.
  ```
  *Rests on:* [Purge Event] steps 0–4, defended by the cascade-on-purge rule; Retention Window Invariants 3 (terminal absorption), 7 (no early purge) and 8 (purge timestamp consistency); Tamper Evidence Invariant 1; Event Log Invariant 1 and Actor Identity Invariant 9, which are what make the delegation necessary rather than optional.

- **Invariant 5 — Constituent invariants preserved, or discharged by the destruction record.**
  ```
  Invariant 5.1: EVERY invariant of the four constituent atoms MUST hold over the atom's instance for EVERY event whose retention state DOES NOT EQUAL Purged.
  Invariant 5.4: For a Purged event, AND for a live event whose covering seal is partly purged, an auditor MUST read a constituent invariant that needs a readable proof or a re-presented record set as discharged by the destruction record.
  Invariant 5.2: The composition MUST NOT remove a log entry.
  Invariant 5.3: The composition MUST NOT rewrite a stored field of a constituent record.
  ```
  *Rests on:* the whole action wiring — every constituent call this composition makes is a declared surface of that constituent, and no step reaches around one; the cascade-on-purge rule is where the claim would otherwise break; Composes 13, Composes 15 and Composes 16 for the seal records.

- **Invariant 6 — Forensic completability.**
  ```
  Invariant 6.1: For EVERY event id, IF every constituent read answers AND the event's data IS NOT unreadable under a Retained retention (read record step 4.7) THEN [Read Record] MUST return EXACTLY ONE OF the audit record, not-known.
  Invariant 6.2: For EVERY event id, IF every constituent read answers THEN [Verify Record] MUST return EXACTLY ONE OF verified, failed-verification(reason), unverifiable(reason), not-known.
  Invariant 6.3: IF no verification surface outage EXISTS THEN [Verify Record] MUST answer deterministically over a fixed record set.
  ```
  Term verification surface outage: the actor registry or the seal mechanism unreachable.

  *Rests on:* [Read Record] and [Verify Record]; for a purged event the *who / what / when* half of the join on the pair captured at [Purge Event] step 2 and the surviving fields it names (read record step 4.4), the only route left once Event Log's data field is unreadable; Actor Identity Invariants 1 and 9 (without which the record would not still be there to read), 6 (self-containment) and 7 (verification consistency under fixed registry state); Tamper Evidence Invariants 4 (verification self-containment given the originating records) and 7 (verification consistency under a fixed record set); Invariant 1 through 3 above for the completeness of what is joined.

- **Invariant 7 — Verification asymmetry preserved.**
  ```
  Invariant 7.1: [Verify Record] MUST require the original record set re-presented.
  Invariant 7.2: [Verify Record] MUST NOT require the actor's credential beyond the registry's public material.
  Invariant 7.3: The composition MUST NOT fetch the covering record set internally for verification.
  ```
  *Rests on:* [Verify Record] steps 3 and 5; [Read Record] step 4, which supplies the covering range (read record step 4.3); Primitive policy 25 through 28, which fix both shapes; Tamper Evidence Invariants 3 (record-set binding) and 4; Actor Identity Invariant 6.

- **Invariant 8 — Honest representation of destruction (at quiescence).**
  ```
  Invariant 8.1: WHEN quiescence EXISTS:
      Invariant 8.1a: EVERY event the composition recorded MUST stand in EXACTLY ONE OF retained, lawfully destroyed, held.
  Invariant 8.2: A retained event MUST carry a retention record in Retained.
  Invariant 8.2a: A held event MUST carry a retention record in Purged and a hold.
  Invariant 8.2b: [Read Record] and [Verify Record] MUST answer a held event as a purged event.
  Invariant 8.3: A lawfully destroyed event MUST carry a retention record in Purged with purge instant, the sequence number in the covering seal's purged events, the pair in the destruction record, and a destroyed outcome in erasure outcomes.
  Invariant 8.4: [Verify Record] MUST NOT read purged off the absence of content.
  Invariant 8.5: The composition MUST reserve not-known for an event id no constituent has heard of.
  ```
  Term event standing: retained | lawfully destroyed | held — held is a Purged retention whose cascade a hold has left open; its content is readable unless a delegation destroyed it and the outcome was not recorded (Term cascade-failure(step-3)).

  NOTE: open 2026-08-30-d — a cascade whose erasure mechanism only ever answers destruction-failed, breaking erasure mechanism 10, stands at quiescence in none of Invariant 8.1a's three standings; past the audit edge it is a residual finding against the mechanism (Check 5.15).

  *Rests on:* [Purge Event] steps 0, 1, 2 and 4 and [Verify Record] steps 1–2; [Read Record] step 5 and [Verify Record] step 2 for the compensation-window reading (read record step 5.1, verify record step 2.3); the liveness arm — that the compensation-window state is bounded and closes — on [Record Action], through which the scan records its findings and the compensating placement (Compensation 1 through 5), and, for a cascade, on the erasure mechanism reporting destroyed inside the compensation window (erasure mechanism 10); Retention Window Invariants 1 (membership exclusivity), 3 (terminal absorption) and 10 (retention record durability); Tamper Evidence Invariant 1; Invariant 2 above for the window it is conditioned on and Invariant 4 for the coordination that produces the surviving records.

Attribution coverage and retention coverage together give the complete-record property; integrity coverage modulo unsealed tail names the cadence trade-off honestly; cascade coordination on purge prevents dangling state across the four constituents' records without pretending to a destruction surface two constituents forbid; honest representation of destruction is what distinguishes a *complete* audit trail from a *suspicious* one.

---

## Examples

### Walkthrough

A regulated bank deploys the composition as the canonical audit trail for its core ledger: `retention_policy = sox_7_year` (seven years, then a max purge delay of 60 days); `seal_cadence = every 1000 events or 60 seconds, whichever first`; `slice_cap = 5000 events`; `seal_mechanism = SHA-256 hash chain, newest link anchored synchronously at seal time to an RFC 3161 TSA`, linked across seals (SHA-256: Secure Hash Algorithm, 256-bit — a standard cryptographic hash function); `erasure_mechanism = per-event content-key shredding at the storage layer`; `compensation_window = 24 hours`; `record_action_completion_bound = 30 seconds`; `purge_completion_bound = 5 minutes`; `seal_completion_bound = 2 minutes`; `compensation_closure_latency = 6 minutes` (a run's enumeration included; the start-time measurement came to 40 seconds); `call_pause_bound = 2 seconds`; `clock_offset_allowance = 2 seconds`; `reconciliation_cadence = 60 seconds` (the derived default — the time arm of its interval cadence; the thousand-event arm is not a duration); `payload_cap = 64 KB`, matching the wired Event Log instance. Instance start 16 holds with room to spare: closure sum is max(2 * 30 seconds, 5 minutes) + 2 * 2 seconds + 2 * (60 seconds + 6 minutes), 19 minutes 4 seconds, against 24 hours; Instance start 18 and 19 hold because 6 minutes exceeds both closure spend, 298 seconds (4 * 30 seconds plus 8 * 2 seconds, the 2-second call pause bound and four times the 40-second measured enumeration — two before the take, two under the lease) and re-drive spend, 342 seconds (5 minutes, the call pause bound and one measured enumeration), and Instance start 25 holds because 4 seconds is below every completion bound.

1. **A wire-transfer authorization arrives.** `record_action(wire_w91, supervisor_s12, supervisor_credential, {amount: 50000, counterparty: ...})`. Actor Identity → `attestation_a44`; Event Log → `event_e9301`; Retention Window → `retention_r9301` with `retention_until = 2033-05-10`; the event lands in the unsealed tail. Returns `event_e9301`.
2. **The cadence fires.** The thousand-event arm trips first: [Seal Now] runs over the slice `[8302 .. 9301]`, whose last member is `e9301`. The chain's newest link is anchored to the TSA synchronously, within the seal call — which is what entitles the record to carry anchoring instant at all; batched anchoring after the fact is a separate External Anchoring pattern — and `evidence_s127` is recorded with `anchored_at = 2026-05-10T14:33:00Z`. The seal coverage entry for `s127` is `[8302 .. 9301]`; sealed through advances to 9301.
3. **Six years later, a SOX (Sarbanes-Oxley Act) section 404 audit.** *Show me the supervisor authorization on wire w91, and prove it hasn't been altered.* `read_record(e9301)` returns the [Audit Record] in one shot: action `wire_w91`, actor `supervisor_s12`, attestation `a44`, retention `r9301` in *Retained*, and coverage `s127` over `[8302 .. 9301]` — the instruction for the next call. This deployment runs interval cadence, so the auditor pulls all thousand payloads for that range — through Event Log's range read where the log is online, from the archive otherwise — and calls `verify_record(e9301, payloads_8302_through_9301)`. Retention reads *Retained* (no purged short-circuit), the event is present, the attestation verifies against `s12`'s public material, `s127` is the covering seal, the presented range passes through to `TamperEvidence.verify`. Returns `verified`. Under a per-event cadence the same call would carry `e9301`'s single payload; the argument is the same argument, only its extent moves.
4. **Seven years and one month later.** [Purge Eligible] runs nightly and `e9301` is on the list. `purge_event(e9301)`: step 0 is a no-op — `9301 ≤ sealed_through`, so `s127` covers it. `RetentionWindow.purge(r9301)` moves the retention to *Purged* with `purged_at = 2033-06-14`; `9301` joins `s127`'s purged events — just that one number, since the other 999 members are under their own retentions — and the same write captures the pair `(e9301, a44)` before anything is destroyed. Destruction of Event Log's data field for `e9301` and of `a44`'s proof goes to the erasure mechanism, which shreds both and reports destroyed; the cascade completes. Had it reported `destruction-failed(...)`, the cascade would have rejected `cascade-failure(step-3)` and the 60-second scan would have re-driven the entry each cycle until a destroyed outcome landed, `r9301` standing as a surfaced alert meanwhile. The Event Log entry's and the attestation's stored fields are byte-for-byte what they were; the key is gone, so the payload and the proof no longer read, while `a44`'s action reference, actor reference and attestation instant still do. `verify_record(e9301, ...)` now returns `failed-verification(purged)`, read off `r9301` before any `ActorIdentity.verify` call. No re-seal follows: `s127` stays the one seal over `[8302 .. 9301]`, and its 999 survivors answer `unverifiable(partially-purged-coverage)` for the rest of their retained lifetimes — unknown, not bad. A bank that could not accept that composes Seal Lifecycle *(forthcoming)*, at the cost of a mechanism round-trip per purge and a pattern to wire.
5. **A subsequent regulator inquiry.** *What happened to wire w91?* The retention records hold `r9301` in *Purged* with purge instant inside the lawful window; the seal records retain `s127` indefinitely, now carrying `9301` in purged events and still the cover for its other members; the attestation records retain `a44` with its surviving fields readable. `read_record(e9301)` sees *Purged*, takes `(e9301, a44)` out of the destruction record, and reads the *who / what / when* off `a44` — so the answer is not merely *something was destroyed* but *`supervisor_s12`'s authorization of `wire_w91`, attested at that moment, was destroyed lawfully on 2033-06-14*.

### Walkthrough — rejection paths

**Orphan attestation — attest succeeds, append is refused.** `record_action(wire_w92, supervisor_s12, supervisor_credential, {amount: 75000, ...})`.

1. Step 1 passes: both references are far inside the 1 KB cap and the full constructed payload is about 2 KB against the 64 KB cap. Nothing is recorded yet.
2. Step 2: `ActorIdentity.attest(...)` → `attestation_a45`.
3. Step 3: `EventLog.append({...})` — the wired Event Log instance was reconfigured to a 1 KB cap and refuses invalid-payload, payload cap and the instance's cap disagreeing (payload cap 4). `event_e9302` does not exist and never will.
4. The composition returns `invalid-request(step-3)` carrying `a45`, the refusal keeping `a45` committed as the evidence of the attempt; it writes nothing further and yields. On its next run the scan takes the critical section on `a45`, records an `audit.reconciliation` finding naming it, then a compensating record naming `a45` as unbound — through [Record Action] under `audit.compensation`, attributed to the bank's operator identity, raised as a high-priority compliance finding. The scan found `a45` by the binding-set test — in the attestation records, in no live payload, in no destruction record — and, finding it absent from compensated attestations, wrote the one compensation; the next scan leaves it alone.
5. The caller does not retry the refusal, which would commit a second attestation; the deployment restores the cap. `a45` remains in the database forever as a surfaced, reconciled orphan — the honest record of what happened rather than a defect to be hidden.

Had data been 80 KB, the rejection would have arrived at step 1 as invalid-request(step-1) with nothing recorded — no attestation to orphan; that is why the size check sits where it does.

**not-eligible — a purge attempted before the window elapses.** In 2030 a records-management job misconfigured with a five-year policy calls `purge_event(e9301)`.

1. The composition resolves `r9301` and calls `RetentionWindow.purge(r9301)`.
2. Retention Window evaluates its no-early-purge guard against its own now: `2030-06-14 < 2033-05-10`. It refuses with retention-period-not-elapsed, writing nothing (Retention Window Invariant 7).
3. The composition returns not-eligible. No cascade step runs: nothing joins `s127`'s purged events, no delegation is issued, `r9301` stays *Retained*, and `verify_record(e9301, ...)` still returns `verified`.
4. The gate is structural: the composition does not evaluate eligibility itself, and the atom's guard is a precondition on its own state.

### Selected rejection and outcome runs

Selected, not exhaustive; each makes a distinction the composition is built on legible.

**`unverifiable(attestation-registry-unavailable)`.** During the same audit, `verify_record(e9308, payloads_9302_through_10301)`: retention *Retained*, log entry present, `ActorIdentity.verify(a51)` — and the registry is unreachable behind a network partition. Step 3 does not prefix registry-unavailable; it routes it to step 6, which returns `unverifiable(attestation-registry-unavailable)`. Steps 4 and 5 do not run, so no integrity claim is made either way. The auditor records the outage, not a finding, and retries when the registry returns.

**A lenient-mode verify in the unsealed tail.** A second deployment — an internal operations trail over a WORM substrate, `seal_cadence = every 6 hours`, `unsealed_tail_mode = lenient` — records `e440` at 09:12 and verifies it at 09:20. `read_record(e440)` reports *unsealed tail* (`440 > sealed_through = 431`). `verify_record(e440, e440_payload)`: retention *Retained*, log entry present, attestation verifies; step 4 finds no covering seal and, under lenient, treats coverage as satisfied, skips step 5, finds no availability failure at step 6, and returns `verified` at step 7. The same call against the bank's strict instance returns `failed-verification(unsealed)` — same records, different declared posture, visible in Configuration.

**invalid-credential — rejected before anything is written.** A terminated supervisor's smart card: `record_action(wire_w95, supervisor_s12, revoked_credential, {...})`. Step 1 passes; step 2's attest refuses invalid-credential; the composition propagates it and stops. No attestation, no event, no retention, no seal attempt, no orphan. The log carries no trace of the attempt — the scope line of Failed attribution 1; a deployment that must audit the attempt composes a Failed-Attempt Log *(forthcoming)*.

### Regulated deployments

*Banking — SOX section 404.* Every action against the general ledger is recorded with the controller's attested approval, retained 7 years per SOX section 802, sealed in a hash-chained log anchored to a qualified TSA; the external auditor walks the trail without privileged database access, and [Verify Record] over each in-scope action is what *adequate internal controls* operationally means.

*Healthcare — HIPAA (US Health Insurance Portability and Accountability Act) section 164.312(b).* Every read, write or amendment of protected health information is recorded with the clinician's attestation, retained for the longer of HIPAA's 6-year baseline or state law, sealed in a per-patient Merkle tree; a section 164.524 access request and a breach investigation walk the same trail.

*Payments — PCI DSS (Payment Card Industry Data Security Standard) Requirement 10.* Every access to cardholder data, every export, every key-management operation is recorded with the operator's attestation, retained per Requirement 3.1, chained by HMAC (Hash-based Message Authentication Code) per 10.5; the annual QSA (Qualified Security Assessor — an auditor the card industry certifies) assessment runs [Verify Record] over the year's high-risk actions.

*Pharmaceutical — 21 CFR (Code of Federal Regulations — the codification of US federal agency rules) Part 11.* Every change to an electronic batch record is recorded with the operator's qualified electronic signature, retained per the predicate rule, sealed in a hash chain; an FDA (US Food and Drug Administration) inspection produces the verified history of any batch, and the ALCOA properties (attributable, legible, contemporaneous, original, accurate) are the composition's emergent property.

*Communications — SEC (US Securities and Exchange Commission) Rule 17a-4.* Every business communication at a registered broker-dealer is recorded with the originator's attestation, retained 3–7 years with the first two immediately accessible (composing a Storage Tier *(forthcoming)*), Merkle-tree sealed; a FINRA (Financial Industry Regulatory Authority) examination and a litigation discovery walk the same trail. WORM storage is one mechanism the composition can be realized over; the composition names the structural form.

### Regulated adversarial scenarios

**Regulator audit — "show me the complete, verifiable history of action X over the retention horizon."** *Every event referencing action X* is a query by payload field, so the enumeration is a composed Reverse Index *(forthcoming)*, not a passthrough (Action wiring 3, Action wiring 4); a sequence-number or wall-time window would pass straight through. From there the composition answers per event: `verified` for each retained event, the *Purged* retention record for each destroyed one. Invariants 1, 2, 3 and 8 make the answer provable.

**Disputed action — "I didn't do that."** The investigator retrieves the event and calls [Verify Record]. If `verified`, the attestation binds the named actor to the named action at attestation instant (Actor Identity's non-repudiation contract, through Invariant 5); the actor cannot plausibly deny it without claiming credential compromise, which a Compromise Disclosure pattern *(forthcoming)* handles by new records, never by mutating the trail.

**Breach forensics — "when was the trail compromised?"** The responder walks every seal in sealing instant order — one seal per range, never a replacement — running [Verify Record] against representative events in each range. The most recent seal that returns `verified` end-to-end and the next that returns `failed-verification(seal-proof-invalid)` bound the forensic window, provided the mechanism is chained across seals (seal mechanism 2); under independent per-range seals a failed seal narrows the tampering only to its own range, and the responder gets a set of compromised ranges rather than a window — which of the two the mechanism is, the deployment declares, since mechanism opacity hides it (Tamper Evidence Invariant 8). An `unverifiable(...)` result bounds nothing: under the availability reasons the responder retries; under partially-purged-coverage the responder steps over the seal to the nearest presentable one, which widens the window rather than falsifying it. Where seals carry anchoring instant from a TSA outside the adversary's reach, the upper bound on the time of tampering is independently established.

---

## Generation acceptance

A derived implementation of Audit Trail is acceptable — in the regulator-acceptance sense — when the checks below are provable to an external auditor given the composition's emergent state plus the four constituent records. The first list is what the composition's own records answer; the second is what arises around the composition and needs evidence the composition does not hold.

### Conformance checks

```
Check 1.1: An auditor MUST obtain, from one [Read Record] call on any event id, the joined audit record — what, who, integrity and retention.
Check 1.2: An auditor MUST confirm that not-known is returned only for an event id no constituent knows.
Check 1.3: An auditor MUST confirm that an invalid-request refusal of [Record Action] carries the refusal's step and that the step names the state the refusal left.
Check 2.1: An auditor MUST verify all eight composition-level invariants over the record set.
Check 2.2: An auditor MUST verify Invariants 1 and 2 at quiescence, reading the quiescence condition from compensation window.
Check 2.3: An auditor MUST enumerate the log against the attestation records and the retention records.
Check 2.4: IF attestation age EXCEEDS audit edge THEN an auditor MUST read an unreconciled orphan as a residual finding.
Check 2.5: IF event age EXCEEDS audit edge THEN an auditor MUST read an unreconciled unretained event as a residual finding.
Check 2.6: IF audit edge EXCEEDS a finding's age THEN an auditor MUST NOT read the finding as a residual finding.
Check 2.7: IF attestation age EXCEEDS horizon THEN an auditor MUST read the orphan against the scan's beyond-horizon audit.reconciliation findings.
Check 2.8: An auditor MUST NOT read a purged compensation of a standing orphan as a violation.
Check 2.9: An auditor MUST run the retention side of the enumeration as the mirror of the third half: the full enumeration, the per-event test of event to retention with rebuild-on-miss first, and a true miss past the window read as a finding.
Check 2.10: An auditor MUST build the binding set and take EVERY attestation in neither enumeration as an orphan.
Check 2.11: An auditor MUST read an orphan in compensated attestations as reconciled and the orphan's audit.compensation event as the proof.
Check 2.12: An auditor MUST read an orphan not in compensated attestations, past audit edge, as the residual finding.
Check 2.13: IF compensation window EQUALS blank THEN an instance MUST fail Check 2.
Check 2.14: An auditor MUST read the attestation id of an event payload in any retention state, and the destruction records after the full enumeration.
Check 3.1: An auditor MUST verify all seven Event Log invariants over the audit log instance.
Check 3.2: An auditor MUST read a violation of Event Log Invariant 7 as a clock finding.
Check 3.3: An auditor MUST verify Actor Identity's, Retention Window's and Tamper Evidence's Generation-acceptance bars over the respective instances for EVERY event whose retention state DOES NOT EQUAL Purged, reading a bar clause that needs a re-presented record set as discharged for a live member of a partly-purged seal (Invariant 5.4).
Check 4.1: An auditor MUST bound the forensic window of any detected tampering by the latest verified seal and the first failed seal, with the seal stamps.
Check 4.2: An auditor MUST walk EVERY entry in the seal records.
Check 4.3: An auditor MUST step over a seal answering unverifiable(partially-purged-coverage) to the nearest presentable seal.
Check 4.4: An auditor MUST read the mechanism's chaining posture from the deployment's declaration.
Check 5.1: An auditor MUST confirm, for EVERY purged event that is not held and whose cascade is quiescent, that failed-verification(purged) is backed by the records of Check 5.2 through 5.8.
Check 5.2: An auditor MUST confirm the retention record in Purged.
Check 5.3: An auditor MUST confirm the event's own sequence number in the covering seal's purged events.
Check 5.4: An auditor MUST read a purged event with no covering entry as a conformance failure.
Check 5.5: An auditor MUST confirm the pair in the destruction record.
Check 5.6: An auditor MUST confirm the attestation the pair names exists with readable surviving fields.
Check 5.7: An auditor MUST read a mechanism that destroyed more than the data field and the proof as non-conforming.
Check 5.8: An auditor MUST confirm a destroyed outcome recorded for the event in erasure outcomes.
Check 5.9: An auditor MUST NOT read a destruction-failed record as completion.
Check 5.10: An auditor MUST confirm the live members of a partly-purged seal answer unverifiable(partially-purged-coverage).
Check 5.11: An auditor MUST read an instance answering verified for a live member of a partly-purged seal as composing Seal Lifecycle, audited against that pattern's bar.
Check 5.12: An auditor MUST confirm an event with no retention record inside compensation window carries retention status unresolved (compensation window).
Check 5.13: An auditor MUST confirm [Purge Event] over an event with no retention record inside compensation window returns retention-unresolved.
Check 5.14: An auditor MUST read a member of a covering seal's purged events whose retention state EQUALS Retained as a conformance failure (Invariant 4.5).
Check 5.15: IF purge age EXCEEDS audit edge THEN an auditor MUST read a divergence as a residual finding against the deployment's erasure mechanism (Boundary one 5, erasure mechanism 10).
Check 6.1: An auditor MUST confirm that verification could not be performed surfaces as unverifiable(reason) and never as failed-verification(reason), for attestation-registry-unavailable, seal-mechanism-verification-unavailable and partially-purged-coverage.
Check 7.1: An auditor MUST discard event to retention, event to sequence, sealed through, the uncovered mark, seal coverage's ranges, compensated attestations and reported beyond horizon, run the rebuild procedures against the constituent records and the destruction records, and reproduce EVERY traversal answer.
Check 7.2: An auditor MUST discard event to sequence first.
Check 7.3: An auditor MUST confirm EVERY member of compensated attestations came from an event carrying an `audit.*` action reference whose actor reference EQUALS reconciliation operator, read from the event's payload where no destruction record names the event and from the attestation the destruction record's pair names where one does.
Check 7.4: An auditor MUST regenerate event to attestation's entry for EVERY live event from the event's payload.
Check 7.5: An auditor MUST confirm event to attestation's entry for EVERY purged event that is not held and whose cascade is quiescent is present in the destruction record.
Check 7.6: An auditor MUST read a purged event that is not held and whose cascade is quiescent, with no destruction-record pair, as a conformance failure.
Check 7.7: An auditor MUST confirm the scan's binding set and event to attestation's two halves agree.
Check 7.8: An auditor MUST NOT expect a rebuild of an extraction-pending fact.
Check 8.1: An auditor MUST identify the composing patterns active in the deployment and the patterns' configuration.
Check 8.2: An auditor MUST NOT run Check 1 through 7 BEFORE identifying Reverse Index, Legal Hold, Erasure Tombstone composed for seal disposal, and Seal Lifecycle.
```

Term audit edge: `(compensation_window + clock_offset_allowance)`, counted from the finding's creation or the hold-free run of Composition-level invariant 1e as Composition-level invariant 1h records it, or `(closure_sum + clock_offset_allowance)` counted from the end of the last overlapping dependency outage where that is later (Composition-level invariant 1c), never past the horizon counted from the finding's creation (Composition-level invariant 1c), a suspended entry having none — the auditor's own reading compared to a constituent's stamp only under the allowance.

Term residual finding: an unreconciled finding older than the audit edge — the conformance failure Check 2 reports, and Check 5.15 for a divergence.

Term seal stamps: sealing instant, and anchoring instant where the mechanism anchors.

Term extraction-pending fact: purged events, the entries of event to attestation a destruction record carries, and erasure outcomes.

### External checks

```
External check 1: An auditor MUST clear from external evidence that the erasure mechanism was authorized to destroy, shreds, and completed each destruction.
External check 2: An auditor MUST clear from external evidence that the actor registry retained the registry's historical public material across key rotation.
External check 3: An auditor MUST clear from external evidence that the seal mechanism is cryptographically sound for the audit horizon.
External check 4: An auditor MUST clear from external evidence that the mechanism's seal-time rendering agrees with the verify-time presentation.
External check 5: An auditor MUST clear from external evidence that the clock was monotonic and unmanipulated over the audit horizon.
External check 6: An auditor MUST clear from external evidence that the configured retention policy was the correct one for the record class.
Deleted: External check 7. Execution Contract Database 3 owns it.
External check 8: An auditor MUST clear from the deployment's own matching logic that record set match judges the presented record set against the reference the seal committed to.
External check 9: IF Legal Hold EQUALS composed THEN an auditor MUST clear from the deployment's own concurrency control that a hold placement over an event id and a cascade on that event id serialize, the placement a bounded holder of the section, and that no hold over an event id of this instance is placed outside the hold placement (Capability requirement 7a, 7b, 7c, 7d, 7e, 7f, 7g).
External check 10: An auditor MUST clear from the deployment's own lock that the sealing lock is a lease held under a fresh holder value, and that the sealing lock is shared by every process serving the instance, is a lease of seal completion bound, and that the uncovered mark is carried across a restart and past the lease's expiry, stored apart from the grant (Concurrency 1a, Concurrency 1b, Concurrency 1h, Concurrency 1c).
External check 11: An auditor MUST clear from the deployment's own lock that the per-act critical section is a lease of the act's completion bound for a cascade and a hold placement and of compensation closure latency less the run's elapsed time at the take and call pause bound for a scan leg, shared by every process serving the instance, keyed by the act's id namespaced by the act's kind, held under a holder value minted fresh for each attempt, and not released early by an abandoned call (Per-act critical section 1, 1a, 1b, 1c, 2a, 9a, 13a, 13d), and that no scan leg's start waits on another leg's closure (Reconciliation 1a).
Deleted: External check 12. Execution Contract Database 2 owns it.
External check 13: An auditor MUST clear from the outage record that every dependency outage's start instant and end instant is recorded with the rule that joins intermittent failures (Composition-level invariant 1d, 1f), that the instant of each run that landed an entry under-legal-hold and of the hold-free run after that run is recorded (Composition-level invariant 1h), that the scan scheduler starts the next run after the loss of a process (reconciliation cadence 6), that the purge sweep calls [Purge Event] over the eligible list (purge eligible 8), that an interval-based cadence driver survives that loss and fires at start and restart (seal cadence 4), and that the call pause bound is not exceeded by the worst call the clients make (call pause bound 1).
External check 14: An auditor MUST clear from the deployment's own read path that content readable answers no for content the erasure mechanism destroyed and for no other content (Capability requirement 8, erasure mechanism 6c).
External check 15: An auditor MUST clear from the deployment's own record which mechanism cut EVERY seal in the seal records (Capability requirement 10a).
External check 16: An auditor MUST clear from the deployment's own policy source that the two retention periods supplied at start are the durations the wired Retention Window instance applies (Capability requirement 11).
External check 17: An auditor MUST clear from the deployment's own wiring that EVERY one of the four constituent instances is dedicated to this composition, and that the wired Retention Window instance's purge is the state transition alone (Composes 4a, Capability requirement 9).
External check 18: An auditor MUST clear from the deployment's own alerting surface that EVERY alert a rule of this composition obliges, a compliance alert and a deployment fault alike, is surfaced there (Capability requirement 12).
```

Term external evidence: evidence outside the records — the mechanism's documentation and configuration, the registry's retention policy, cryptographic review, time-service logs, the deployment's regulations.

### Generator's contract

```
Generator's contract 1: An implementation derived from this composition MUST produce records and a runtime surface that clear Check 1 through 8.
Generator's contract 2: An implementation derived from this composition MUST make External check 1 through 6 and External check 8 through 18 askable, naming the external evidence each needs.
```

---

## Non-goals

```
Non-goal 1: The composition MUST specify one instance.
Non-goal 2: The composition MUST NOT provide a path for a pre-attestation legacy event.
Non-goal 3: A Legacy Import pattern MUST NOT write into the audit log around [Record Action].
Non-goal 4: A Legacy Import pattern MUST take EXACTLY ONE OF attesting each imported record under a declared import identity through [Record Action], separate unattested records the auditor reads as explicitly unattributed history.
Non-goal 5: The composition MUST NOT invalidate an attestation retroactively.
Non-goal 6: The composition MUST NOT adjudicate an erasure request against a retention obligation.
Non-goal 7: The composition MUST NOT declare a seal-record retention owner.
Non-goal 8: The composition MUST NOT rotate a seal onto a new mechanism.
Non-goal 9: seal mechanism MUST govern seals cut from the time of setting on.
Non-goal 10: The composition MUST NOT treat a storage tier differently at [Verify Record].
Non-goal 11: The composition MUST NOT place a retention on, or destroy, an attestation that has no event.
Non-goal 12: The composition MUST NOT bound the population the composition's scan enumerates; the deployment bounds the population by rotating the audit instance (Non-goal 1) before measured enumeration outgrows Instance start 16, 18 and 19, and a failing re-run of those checks raises the alert of Per-act critical section 13i.
Deleted: Non-goal 13. slice cap 2 owns it.
Non-goal 14: The composition MUST NOT bound the seal records the rebuild of seal now 13 enumerates; the deployment bounds the seal records by rotating the audit instance (Non-goal 1).
Non-goal 15: The composition MUST NOT place a hold; the deployment owns the hold placement and the placement's gate (Capability requirement 7).
```

An orphan attestation, one step 3 never bound to an event, is the one record this composition cannot retire: it has no log entry to cascade through and Composes 9 forbids placing it, so its proof and its action and actor references stay readable for the life of the attestation records, and it stands in the reconciled set rather than in a lifetime. Its retirement joins what Erasure Tombstone *(forthcoming)* owns; until then the lifetime the Summary claims is the lifetime of every event.

NOTE: the owners — the deployment and an Audit Federation pattern *(forthcoming)* (Non-goal 1); Compromise Disclosure *(forthcoming)* (Non-goal 5); Erasure Coordination *(forthcoming)* (Non-goal 6); Storage Tier *(forthcoming)* (Non-goal 10); a Failed-Attempt Log *(forthcoming)* (Failed attribution 1, Failed attribution 2).

### Failed attribution attempts

```
Failed attribution 1: The composition MUST NOT record a [Record Action] rejected at step 1.
Failed attribution 2: The composition MUST NOT record a [Record Action] rejected at step 2.
```

Where the composition breaks down: when the four constituent records share an adversary with write access to all of them and external anchoring is absent; when the host cannot supply a stable, reproducibly-addressable record set at verify time; when the retention policy and the integrity-coverage cadence are mismatched — events purged before their covering seal is verified against them; when the actor registry's historical public material is not retained and old attestations begin failing under a new key.

### Legal hold suspension of purge

Where the composed hold lands is [Purge Event], not [Purge Eligible] (purge event 5, purge eligible 6), read under the cascade's own critical section after the not-known test and before the seal (purge event 5c) with hold placement serialized against that section (Capability requirement 7a): a hold placed before the read stops the cascade with nothing written, and a hold placed after the section is released finds the cascade finished or left open at step 2 or 3, so there is no placement between a step-1 commit and the step-3 delegation to race it. A cascade left open by a failure at step 2 or 3 and re-driven after a hold is placed stands *Purged* under the hold, lawfully, until release, its content readable unless step 3 destroyed it and the outcome was not recorded; the first half neither alerts on it nor counts it against compensation window (First half 9, First half 10), and Invariant 8 reads it as *held*, a third standing, not a divergence (Invariant 8.1a, Invariant 8.2a), while a hold over a completed purge changes no standing; [Defensible Retention](./defensible-retention.md) already wires the gate over a business record set, and over this instance the placement is the deployment's own facility, which this composition gates and does not perform (Term hold placement, Non-goal 15). A deployment wanting a hold-filtered worklist asks the composed Legal Hold pattern.

## Edge cases

### Concurrency

Four serialization obligations (Concurrency 1, 2, 8 and 9), all implementation-owned, and one rule that forbids a lock.

```
Concurrency 1: The implementation MUST serialize the read-seal-advance sequence per instance across [Seal Now], the cadence-fired seal and [Purge Event] step 0.
Concurrency 1a: EVERY process serving the instance MUST share the sealing lock.
Concurrency 1b: IF the implementation does not carry the uncovered mark across EVERY process serving the instance and across a restart THEN the implementation MUST leave the mark unknown.
Concurrency 1h: The implementation MUST store the uncovered mark apart from the lock's grant, outliving the lease.
Concurrency 1c: The implementation MUST hold the sealing lock as a Lease of seal completion bound.
Concurrency 1d: The implementation MUST NOT take the sealing lock outside [Seal Now].
Concurrency 1g: [Seal Now] MUST take the sealing lock by Lease's take, waiting no longer than the atom's arrival term.
Deleted: Concurrency 1e. Execution Contract Database 2 owns it: [Seal Now]'s re-read, lock check and seal are one transaction, and [Seal Now] makes no abandoned call for the sealing lock to be kept through.
Concurrency 1f: A [Seal Now] MUST present a holder value minted fresh for EVERY attempt.
NOTE: watch the fresh holder value (Concurrency 1f).
Concurrency 2: The implementation MUST serialize the cascade per event id.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 3a. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no serialization to hold.
Deleted: Concurrency 3b. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no serialization to take.
Deleted: Concurrency 3d. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no serialization to take.
Deleted: Concurrency 3c. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no serialization whose lease can expire.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no rule left for a serialization to discharge.
Deleted: Concurrency 5. Execution Contract Database 2 owns it: the destruction-record write reads the purged events it adds to inside its own transaction, and the composition names no rule left for an atomic set-add to discharge.
NOTE: watch cardinality — the pressure at Second half 12 (one writer) and Compensation 2 (one record per finding).
Deleted: Concurrency 6. Execution Contract Database 1 owns it: a [Record Action]'s writes commit together, and the composition names no section for it to run under.
Deleted: Concurrency 7. Execution Contract Database 1 owns it: a [Record Action]'s writes commit together, and the composition names no section for steps 1 and 2 to run outside.
Concurrency 8: [Record Action] step 6 MUST take the per-instance sealing lock of Concurrency 1 through [Seal Now] alone.
Concurrency 9: The scan MUST serialize an orphan's compensation per attestation id.
Concurrency 10: [Read Record], [Verify Record] and [Purge Eligible] MUST NOT take a serialization lock.
```

Term sealing lock: the lease of Concurrency 1c that serializes the read-seal-advance sequence per instance.

Term probe: a run's first reconciliation-path [Record Action], issued alone (Invariant 1.10).

### Clock source for cadence and purge

```
Clock source 1: The composition MUST NOT read now other than for the seal cadence timer, the scan's once-per-run reading, and a scan leg's reading at the leg's take to size the leg's lease (Per-act critical section 13a).
Deleted: Clock source 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock source 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock source 4. Execution Contract Logic confinement 7 owns it.
```

Term invocation: a [Record Action] or a [Purge Event] between the invocation's first write and the invocation's return.

### Cross-store consistency under failure

```
Cross-store 1: The composition MUST require ordered writes plus compensation for a sequence of un-withdrawable writes.
Cross-store 2: The composition MUST NOT require a rollback of a committed constituent write.
Cross-store 3: The implementation MUST own how the implementation's own process survives the gap between two commits.
```

### Durability across crashes

The obligation follows the classification, not the element list.

```
Durability 1: The composition MUST treat a crash that records the event and loses a derived-index entry as a rebuild trigger.
Durability 2: The reconciliation path MUST NOT read a lost event to retention entry as absent.
Durability 3: An id-addressed action MUST NOT treat an event to sequence miss as not-known.
Durability 4: A short rebuild of a closed-state marker MUST NOT produce a false record.
Durability 5: A short rebuild of a closed-state marker MAY produce a duplicate record.
Deleted: Durability 6. Execution Contract Database 1, Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Durability 7. Execution Contract Database 1 owns it.
Deleted: Durability 8. Execution Contract Database 3 owns it.
```

### Partial attestation on step failure

The state, the surfacing and the closure are owned where they happen: the invocation surfaces the orphan in `invalid-request(step-3)` and writes no compensation (record action step 7.12, record action step 7.8); the scan is the one writer of the compensating record (Second half 12), finds the orphan by the binding set (Second half 1, Second half 2), and pre-checks compensated attestations (Second half 9); reconciled has the observable form the term reconciled names; the compensating record is an audit event (Compensation 4). High-assurance deployments treat any orphan in none of the binding set, compensated attestations and reported beyond horizon, past the window, as a gap in the audit surface and alert.

### Verification of the unsealed tail

```
Unsealed tail 1: The deployment MUST monitor the unsealed tail's depth and age against seal cadence.
Unsealed tail 2: The deployment MUST read a [Mechanism Failure] with a preconditions reason as a standing misconfiguration.
Unsealed tail 3: The deployment MUST read a [Seal Now] invalid-request as a standing defect.
```

---

## Composition notes

NOTE: composing patterns — [Actor Suspension](./actor-suspension.md), [Capability-Backed Sharing](./capability-backed-sharing.md), [Chain of Custody](./chain-of-custody.md), [Customer Onboarding](./customer-onboarding.md), [Defensible Retention](./defensible-retention.md), [Execute Gated Workflow](./execute-gated-workflow.md), [External Onboarding](./external-onboarding.md), [Immutable Transaction Ledger with Selective Disclosure](./immutable-transaction-ledger.md), [Login](./login.md), [Multi-Party Approval](./multi-party-approval.md), [Privileged Access Provisioning](./privileged-access-provisioning.md), [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md), [Recoverable Invocation](./recoverable-invocation.md), [Verified Repair](./verified-repair.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind** — Type, Operation, Member, Field or Parameter — with the Type it is a Member of, its Role, and one **Projection** line for every pinned or wire Member, the single canonical lowering token every target casing is derived from by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs). This is a composition, so its concepts are the composed action-wirings, the consolidated read, the derived read over eligible events, the [Audit Record], and its own outcomes and rejections. Backticked rather than carded, because they are reasons or qualifiers under inherited tokens rather than outcomes of their own: `unsealed` and purged under `failed-verification(...)`, partially-purged-coverage under `unverifiable(...)`, the `(compensation-window)` qualifier, and the reserved references `audit.compensation` and `audit.reconciliation`. The erasure mechanism's two outcome values belong to the deployment-declared mechanism and stay uncarded on the same terms as the constituent tokens; the derived indexes store no truth the constituent records do not, and the three extraction-pending facts will be carded on Erasure Tombstone's own page when it lands. Constituent operations, inherited outcome tokens, constituent id tokens, the twenty-one knobs and the per-act critical section stay backticked. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the deployment; the host; the implementation; the instance; the invocation; a [Record Action] step (also: the step); a cadence firing; the reconciliation scan (also: the scan, a scan run) and its first half, second half and third half (also: a leg, the reconciliation path); the cascade; the holder; a reader; a writer; a caller; the verifier; an auditor; an action of this composition; an id-addressed action; a read path; the rebuild; the read-back; the erasure mechanism; a policy selector; a regulated deployment; an implementation derived from this composition; a Legacy Import pattern; the next run; the next cadence firing; a constituent — Event Log, Actor Identity, Retention Window, Tamper Evidence — and the audit log, the attestation records, the retention records and the seal records; a derived index; an element; a coverage range; a seal; an attestation; an event; a retention record; the destruction record; the outcome record; a finding; a divergence; an entry.

Term composing patterns: (named, never constituents) Erasure Tombstone, Seal Lifecycle, Reverse Index, Legal Hold, Defensible Retention, Legacy Import, Policy Reconciliation, Mechanism Registry, Storage Tier, Trusted Timestamping, Compromise Disclosure, Erasure Coordination, Failed-Attempt Log, Schema Evolution, Audit Federation, Condition Register, External Anchoring.

Term records: the audit event (Event Log's data field); the attestation; the retention record; the seal (evidence record); the destruction record; the `audit.reconciliation` record; the `audit.compensation` record; the beyond-horizon report; the outcome record; the [Audit Record]; the derived indexes — event to attestation, event to retention, event to sequence, seal coverage, sealed through, compensated attestations, reported beyond horizon; erasure outcomes.

Term record verbs: serve, call, read, delete, evaluate, write, dispose, seal, expose, alert, surface, retry, sit, consult, treat, claim, modify, remove, populate, classify, take, re-key, resolve, ask, key, overlap, carry, flag, record, address, land, close, compute, keep, filter, cover, set, place, hold, retain, select, declare, pass, inspect, log, wire, rewrite, leave, report, name, evidence, measure, run, govern, provision, decide, hand, apply, size, widen, exclude, supply, release, skip, block, issue, implement, re-read, start, contain, validate, normalize, compare, consume, store, count, yield, present, canonicalize, return, adopt, guess, fall, depend, defer, invoke, advance, re-seal, change, produce, verify, assemble, fabricate, ride, fold, promote, route, proceed, locate, map, re-derive, share, reject, re-offer, re-drive, invent, resume, add, destroy, repair, remain, conclude, grow, suspend, stay, append, match, exist, condition, reconcile, commit, bound, answer, fetch, reserve, stand, obtain, confirm, enumerate, build, fail, walk, step, discard, regenerate, expect, identify, clear, specify, provide, invalidate, adjudicate, rotate, serialize, require, own, monitor, examine, test, delegate, compose, reference, raise, make, encode, judge, wait, include, namespace, bind, end, re-declare, re-run, go, re-issue, recompute, re-resolve, restart, shred.

Term cited: append, read, event id, sequence number, recording instant, data, next sequence number, invalid-query, invalid-payload, storage-failure: Event Log. attest, verify, attestation id, action reference, actor reference, attestation instant, proof, invalid-credential, invalid-request, not-known, registry-unavailable: Actor Identity. place_under_retention, purge, purge eligible, retention id, policy reference, record reference, retention deadline, purge deadline, purge instant, retention-period-not-elapsed, not-retained, invalid-policy, policy-not-found, registry-unavailable: Retention Window. seal, evidence id, record set reference, sealing instant, anchoring instant, `mechanism-failure(reason)`, mechanism-verification-unavailable, seal-record-set-mismatch, seal-proof-invalid: Tamper Evidence.

Term value sets: retention_state = Retained | Purged. seal cadence = per-event | interval-based | on-demand. unsealed tail mode = strict | lenient. mechanism class = unkeyed | keyed | anchored. erasure outcome = destroyed | destruction-failed(reason). coverage status = covered | unsealed tail | records-purged | partially purged. verify outcome = verified | failed-verification(reason) | unverifiable(reason). unverifiable reasons = attestation-registry-unavailable | seal-mechanism-verification-unavailable | partially-purged-coverage. composition-introduced failed-verification reasons = unsealed | purged | attestation-not-known | seal-not-known, plus the constituents' reasons prefixed `attestation-` and `seal-`, registry-unavailable and mechanism-verification-unavailable excepted (verify record step 3.2, 5.2). subject = attestation | event. disposition = beyond-horizon. cascade-failure step = seal | hold | step-1 | step-2 | step-3 | in-flight. recording-failure step = step-2 | step-3 | step-4. invalid-request step = step-1 | step-2 | step-3 | step-4. classification = derived index | extraction-pending.  lease = live | expired. `Legal Hold` = composed | absent. retention status on the audit record = the retention record's state | unresolved (compensation window). attribution on the audit record = the surviving fields. reserved references = audit.compensation | audit.reconciliation. event standing = retained | lawfully destroyed | held.

Term bounds: call pause bound, compensation window, record action completion bound, purge completion bound, seal completion bound, compensation closure latency, clock offset allowance, payload cap, reference length cap, slice cap, attestation id width.

Term cadences: seal cadence, reconciliation cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); `(compensation-window)` — carried beside a [Verify Record] outcome on a separate channel.

Term terms: (each declared where it is used) audit log, attestation records, retention records, seal records, surviving fields, open-upper-bound read, full enumeration, derived index, extraction-pending, rebuild-on-miss, retention state, live, purged, purged events, covering seal, closed entry, sealed through, unsealed tail, reconciled, resolved policy, time arm, chained mechanism, verify-time presentation, mechanism class, independently trusted substrate, standing false negative, tombstone-by-mutation, `Event Log's data field`, `finding's creation`, serialized envelope, reference headroom, whole closure, `act's completion bound`, `act's kind`, lease, holder, pre-check, closure sum, full constructed payload, reserved namespace, reconciliation path, committed ids, subject-kind discriminator, read-back, high-water mark, non-storage refusal, slice, tail position, audit record, coverage status, pair, partly-purged coverage, `Legal Hold`, hold, mid-cascade expiry, `cascade-failure(step-3)`, completed cascade, divergence, record edge, purge edge, horizon, purge age, attestation age, event age, binding set, orphan, true miss, owed narration, narrated, intent, quiescence, `recorded through [Record Action]`, audit edge, composition-built query, insert-only map, closed-state marker, reconciled policy, held critical section, truth-bearing write, `who / what / when`, seal disposal, re-sealing, dependency outage, compliance alert, verification surface outage, event standing, residual finding, seal stamps, extraction-pending fact, invocation, later write, malformed reference, standing finding, open entry, external evidence, sealing lock, uncovered mark, probe, cadence driver, no answer, call pause bound, closure floor, measured enumeration, work bound, closure spend, re-drive spend, suspended entry, content readable, unreadable, retention period, purge sweep, outage record; and now, the seam-injected reading (Clock source 1; the section titled Logic Confinement Principle in `execution-contract.md`).

Term original event payload: original_event_payload — the record set [Verify Record] re-presents to Tamper Evidence: the verify-time presentation of the covering seal's range as [Read Record] reported it, which is the event's own payload as appended where the range is the one event, and never the event's payload alone where the range is wider (Primitive policy 26).

Term slice reference: slice_ref — the reference naming the slice a seal covers.

#### Record Action

The composition's core action: validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal over the slice the firing cuts. Returns the new event id; invalid-credential before anything is recorded; invalid-request carrying the step and the committed ids — nothing recorded at step-1 or step-2, the attestation committed at step-3 and the event too at step-4; [Recording Failure] carrying the step where a database refused or a registry could not be read. A seal failure at step 6 does not reject the call.

Kind: Operation

#### Seal Now

The action that seals the current unsealed tail — under interval or on-demand cadence, from [Record Action] step 6 under per-event cadence, and from [Purge Event] step 0 — over the slice, where the tail position is the highest sequence number the open-upper-bound read returns; records the coverage and advances sealed through. Cuts new coverage only. Returns the evidence id, [Nothing To Seal], [Mechanism Failure] with the mechanism's reason, invalid-request, or [Recording Failure]; under each rejection the events stay in the unsealed tail, save where a coverage write that gave no answer landed, and the next firing retries.

Kind: Operation

#### Read Record

The consolidated read: resolves the event id through event to sequence, joins the event, its attestation reference, its retention record and its coverage status into one [Audit Record], or returns not-known. For a purged event reads the *who / what / when* from the attestation record through the pair, or, before the cascade has written its destruction record, through event to attestation's entry. Returning the covering range is what tells a [Verify Record] caller what to present. A pure projection; it presents, [Verify Record] proves.

Kind: Operation

#### Verify Record

The four-way verification query: retention state first, then log presence, then the attestation, then the covering seal. Returns `verified`, a prefixed `failed-verification(reason)` (including purged), [Unverifiable], or not-known; any of the first three may carry `(compensation-window)` on a separate channel. The record set re-presented is always the payloads of the covering seal's range.

Kind: Operation

#### Purge Eligible

The derived read returning the event id values eligible for the cascade: delegates to Retention Window's read-time purge eligible projection and maps each retention to its event; evaluates no clock, has no rejection arm. Distinct from `RetentionWindow.purge_eligible`, the constituent projection over retention id values.

Kind: Operation

#### Purge Event

The action that coordinates the cascade for a retention-elapsed event: seals the event if it is in the unsealed tail, requires the retention to be resolved, purges the retention record, writes the destruction record, and delegates the shred of Event Log's data field and the attestation's proof to the erasure mechanism, branching on the reported outcome. Destroys nothing itself, disposes of no seal, re-seals nothing. Returns ok, not-known, [Not Eligible], [Retention Unresolved], [Cascade Failure] carrying the step, or — where a Legal Hold is composed — [Under Legal Hold].

Kind: Operation

#### Audit Record

The composition's emergent output, produced by [Read Record]: the single consolidated structure the four atoms together present for one event — the event bound to its attestation, its retention and its seal coverage. No constituent presents it alone.

Kind: Type

#### Recording Failure

The composition's rejection for *a database refused the write*, a registry a constituent reads at its seam could not be read, or a call gave no answer, carrying the step from [Record Action] only: on any constituent storage-failure, registry-unavailable or no answer, nothing committed; from [Seal Now], bare, when the seal records would not persist a computed proof or its coverage entry, when the sealing lock is not taken or its lease expires before the coverage entry has landed, or when a call it issues before the clear of the uncovered mark gives no answer (seal now 20, 24, 28). The surface that failed is a database, a registry or a lease, not a mechanism.

Kind:       Member
Member of:  the record-action and seal rejections
Role:       Rejection
Projection: recording-failure

#### Nothing To Seal

The composition's rejection from [Seal Now] when the unsealed tail is empty.

Kind:       Member
Member of:  the seal rejection
Role:       Rejection
Projection: nothing-to-seal

#### Mechanism Failure

The composition's rejection from [Seal Now] when the mechanism could not compute a proof, carrying the constituent's `(reason)` unchanged: a transient outage or a standing preconditions failure, told apart by the reason. Not a malformed request (invalid-request) and not a database refusal ([Recording Failure]). No coverage entry is written and sealed through does not move.

Kind:       Member
Member of:  the seal rejection
Role:       Rejection
Projection: mechanism-failure

#### Cascade Failure

The composition's rejection from [Purge Event] when a database or the seal mechanism refuses mid-cascade, carrying the step: hold, when the hold read answers nothing (the gate fails closed, since the step after it is irreversible), leaving nothing changed; in-flight, when the event's critical section is held by another holder, writes nothing and leaves whatever the holder is doing to it; seal and step-1 leave nothing changed and the event on [Purge Eligible]'s list; step-2 and step-3 leave the retention *Purged* over an incomplete cascade, invisible to [Purge Eligible] and re-driven by the reconciliation scan, and leave a completed cascade complete where a repeat's read at step 2 or step 3 fails or gives no answer. On a lease host, the cascade's terminus after step 1.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: cascade-failure

#### Not Eligible

The composition's rejection from [Purge Event] when the retention has not elapsed and Retention Window's no-early-purge gate refuses the cascade.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: not-eligible

#### Retention Unresolved

The composition's rejection from [Purge Event] step 0½ when the event id resolves to a log entry but to no retention record — the compensation-window state of Invariant 2's liveness arm. Nothing to purge; the remedy is the reconciliation path. Distinct from not-known and from [Not Eligible].

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: retention-unresolved

#### Under Legal Hold

The conditional rejection from [Purge Event], present exactly when the deployment composes a [Legal Hold](../atoms/legal-hold.md) pattern: a preservation order intercepts the cascade before its first step, so no step runs.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-legal-hold

#### Unverifiable

The composition's [Verify Record] outcome for *verification could not be performed*: two availability reasons, retried when the surface returns, and partially-purged-coverage, standing for the rest of the event's retained lifetime. Nothing is known to be wrong with the record.

Kind:       Member
Member of:  the verify-record outcome
Role:       Outcome
Projection: unverifiable

[Record Action]: #record-action
[Seal Now]: #seal-now
[Read Record]: #read-record
[Verify Record]: #verify-record
[Purge Eligible]: #purge-eligible
[Purge Event]: #purge-event
[Audit Record]: #audit-record
[Recording Failure]: #recording-failure
[Nothing To Seal]: #nothing-to-seal
[Mechanism Failure]: #mechanism-failure
[Cascade Failure]: #cascade-failure
[Not Eligible]: #not-eligible
[Retention Unresolved]: #retention-unresolved
[Under Legal Hold]: #under-legal-hold
[Unverifiable]: #unverifiable

---

## Standards references

The composition is the structural form of what every major audit regime requires: SOX section 404 (internal control over financial reporting) and section 802 (records retention); HIPAA section 164.312(b) (audit controls) and section 164.530(j) (documentation retention); PCI DSS Requirement 10 — 10.2, 10.3, 10.5, 10.7; 21 CFR Part 11 (ALCOA and ALCOA+); SEC Rule 17a-4 and FINRA Rule 4511 (composing with Storage Tier); ISO/IEC 27001 (the information-security standard of the International Organization for Standardization and the International Electrotechnical Commission) clause A.12.4.1–4 (the clock-synchronization control via Trusted Timestamping); GDPR (General Data Protection Regulation — the European Union's data-protection law) Articles 30 and 32; eIDAS (the European Union's Regulation 910/2014 on electronic identification, authentication and trust services) qualified preservation, with anchoring instant from a qualified TSA as the time anchor, what that time proves belonging to Trusted Timestamping *(forthcoming)* (Tamper Evidence Non-goal 9); DoD 5015.02-STD (the US Department of Defense's design criteria for electronic records management software); NIST SP 800-92 (Special Publication 800-92 of the National Institute of Standards and Technology — the US federal standards body); Basel III BCBS 239 (the Basel Committee on Banking Supervision's principles for risk data aggregation and reporting). A GDPR Article 17 erasure request that collides with a retention obligation is a composed Erasure Coordination pattern's decision, not this composition's (Non-goal 6). The four atoms carry their own standards inheritance. It inherits from Daniel Jackson, *The Essence of Software* — a composition is the wiring of freestanding concepts, not a new primitive; from the audit-grade systems literature — COSO (the Committee of Sponsoring Organizations of the Treadway Commission's internal-control framework), COBIT (Control Objectives for Information and Related Technologies) and SOC 2 (Service Organization Control 2 — an audit standard for service-provider security controls) name attribution, integrity, retention and event recording as the four pillars the frameworks assume but never specify; and from Schneier and Kelsey 1999, *Secure Audit Logs to Support Computer Forensics*, the original formal framing of cryptographically protected audit logs.

---

## Status

`grounded on Final Critique 48 — 2026-10-25` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 48 — 2026-10-25
formal: verified — audit-trail.tla + 2 twins (cascade; scan first half) and audit-trail-record.tla + 3 twins (record action, one step under Execution Contract Store 1; scan second and third halves; re-derived 2026-10-20) and audit-trail-binding.tla + 2 twins (binding-set predicate against an in-flight cascade), re-derived against the fresh-reader gates of rounds 9 to 18, and audit-trail-hold.tla + 5 twins + 3 probes (a hold placed over an open cascade entry, released and re-driven; 43,688 states within 15 ticks), derived from the page as it stands; the closure arithmetic — a leg's lease against its work (Instance start 18, 19, Per-act critical section 13a, 13b, 13d) and a finding's closure against closure sum with one dead run and one hold placement (Instance start 16) — enumerated by tools/harness/audit-trail-closure.py + 5 twins over 5,184 leg tuples and 5,184 schedule tuples at conforming constants, which no model reaches; the other cures of rounds 19 to 26 are carried on the NOT MODELED lists, not re-derived; models and enumerator last run 2026-10-24
last gate: 2026-10-25 — Final Critique 48 — foundational count 0, clean, one sample

open:
- 2026-10-03-d · refining · Second half 18; Term dependency outage · content lost with no cascade and not restorable leaves the second half writing no compensation with nothing to end it → a standing for content lost without record; contract-shaped, own round
- 2026-10-03-g · refining · seal coverage 2; Composition state 3; Durability 8 · the coverage ranges are a derived index whose loss is a rebuild trigger and a durable entry at once → one classification, the split stated as event to attestation's is
- 2026-10-03-h · refining · purge event step 1.3; purge event 1; Invariant 8.5 · Retention Window's not-known passes through as this composition's for an event with a log entry → land it on the cascade-failure arm
- 2026-10-03-i · refining · seal now 8, 14, 20, 24, 28; Term Recording Failure · a bare recording-failure lands for a database refusal, for lock contention, for a call before the seal call that gives no answer and on both sides of the seal commit → carry the cause or the position
- 2026-10-03-l · refining · seal coverage 3; seal now 13; Non-goal 14 · the rebuild enumerates the whole seal records, which the deployment bounds by rotation → a rebuild that reads only the seals past the last durable coverage entry; own round
- 2026-10-03-t · refining · verify record step 3.1, 5.1; Invariant 1.6a · [Verify Record] takes the attestation link from the stored payload and checks the seal against the caller's presentation, and no step compares the two, so verified can stand over a stored entry altered after sealing where the presentation came from an archive → take the link and the references from the presented member at the event's position and compare them to the stored event
- 2026-10-04-a · refining · Per-act critical section 9a; record action completion bound 2; purge completion bound 2 · the lease is set to the act's completion bound, and Lease Sizing 4a lets a holder take for unfenced work only a duration that exceeds the work's bound; at equality a holder at the worst-case latency reads its own lease expired and refuses its last write → set the lease above the bound by the host's time resolution
- 2026-10-04-c · refining · Term no answer; purge event 8; Term dependency outage; the closure table · no answer is sized by call pause bound and applied to reads that enumerate for as long as measured enumeration, so a rebuild-on-miss reads as an outage → name the read's bound
- 2026-10-04-e · refining · Term whole closure; Term records · three writes stated for a second half that makes two; Term records lists the derived indexes without the uncovered mark and omits the outage record → correct both
- 2026-10-04-g · refining · Compensation 15 against Compensation 11 and Second half 10; First half 8 against Per-act critical section 5 and 13d · two rules bind one state with no precedence stated → state it
- 2026-10-04-h · refining · Check 7.3; Term reconciliation operator · the check reads the current operator, so a rotation fails the records the earlier operator wrote → check against the operator the record was written under
- 2026-10-04-i · refining · reference length cap 2; Term reference headroom · the headroom does not close for two references and the payload's framing → count both
- 2026-10-04-k · refining · Capability requirement 7; Instance start 31 · the hold gate's read does not match the Legal Hold database name the atom has a composing pattern match (Legal Hold Instance 5 through 7) → cite the atom's rule at the gate
- 2026-10-04-l · refining · erasure outcomes 1; Capability requirement 9 · the outcome record carries no destruction instant, which Retention Window asks of the party that owns the destruction (its Capability requirement 7, External check 5) → carry the instant, or cite the record that does
- 2026-10-04-m · refining · Composes 5 through 10 · every constituent call has a call-site rule except EventLog.append → add it
- 2026-10-04-n · refining · Concurrency 1, 1a; the instance capability list · the owner of the sealing lock, and of a seal's retention, is stated three ways → one statement each
- 2026-10-04-o · refining · seal cadence 4; Term cadence driver · the driver's events arm needs sealed through and no rule gives the driver the read → name the read
- 2026-10-04-p · refining · Capability requirement 7; Non-goal 15 · the hold-gate wiring is an extraction candidate, the Hold-Aware Audit Retention pattern Defensible Retention names as a non-goal → own round
- 2026-10-04-q · rhetorical · the body · process history (a lang version), labels out of order (13h before 13g, 2.13 before 2.11, 0.10 before 0.9) → rewrite on the next load-bearing touch
- 2026-08-30-d · refining · Invariant 8 liveness; the scan's first half · a delegation whose outcome record was never written is re-driven "until a `destroyed` outcome lands" against content the mechanism may only ever answer `destruction-failed` for → an *abandoned* record under the operator identity after a declared bound, the arm degrading to *surfaced* (the already-destroyed case closed by erasure mechanism 7a on 2026-10-01; a mechanism that only ever answers `destruction-failed` breaks erasure mechanism 10 since 2026-10-24, so what remains is the terminus its divergence lacks); contract-shaped — ripples to every composer that transcribes Invariant 8's unconditional lawfully-destroyed-versus-missing distinction, own round
- 2026-10-05-a · refining · the signature block; Term open-upper-bound read; Composes · a composing layer's read by sequence range has no entry on this composition's surface and is reached through Event Log's read by implication, and what that read answers for a destroyed event is unstated → declare the read; reported by Defensible Retention's and Resolve a Person's Data Rights' gates
- 2026-10-05-b · refining · retention policy 6; purge event · no order is stated for destroying an intent against its outcome, and nothing binds the period of co-tenant events on one instance → state the order, or that there is none; reported by the same gates
- 2026-10-24-a · refining · purge eligible 1, purge eligible 2; the [Purge Eligible] signature · [Purge Eligible] answers every eligible event id at once, with no bound and no paging, through Retention Window's read of every retention → a bound, or a paged or keyed read, decided with Retention Window's 2026-10-05-a (its read has no key) and in Actor Identity's 2026-10-20-f form
- 2026-10-25-b · refining · seal cadence 3; record action step 6.6; Unsealed tail 1 · under per-event cadence a step-6 seal that failed on a log that then goes quiet stands until a later [Record Action], [Purge Event] or [Seal Now] seals the event, and no rule obliges one, so under strict the event answers failed-verification(unsealed) for as long as the deployment calls none → decide whether per-event owes a retry driver, as seal cadence 4 owes interval-based one, or the standing alert and Unsealed tail 1's watch are the design (the 2026-10-01 entry withdrew the scan's per-run [Seal Now])
- 2026-10-25-c · refining · read record step 5.1; read record step 4.7; Invariant 6.1; Term audit record · a log entry with no retention record over unreadable data, a deployment fault the scan surfaces (Second half 18; Term dependency outage), has step 5.1 return an audit record whose action reference, actor reference and attestation id sit in that unreadable data field (Term full constructed payload), its event to attestation entry one the refused [Record Action] never wrote and the rebuild cannot take from an unreadable payload (event to attestation 1, 2b), where step 4.7 answers a Retained retention over unreadable data no answer → decide whether the compensation-window read withholds its record as an outage, as step 4.7 does, widening Invariant 6.1's carve-out, or returns a record of what can still be read, declared in Term audit record
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/audit-trail.md`; the rounds, the sweep and the migration that got it here, and the turns later turns superseded, are in [its history](./audit-trail.hist.md).

- **2026-10-25 — A closure table owns every call's answer, refusal, failed read and lost answer.** *Chose:* under the maintainer's ruling of 2026-10-25 01:24Z, direction (b) of the 2026-10-24 20:01Z escalation, a closure table in Action wiring, in Recoverable Invocation's form, mapping every input of the six actions and every answer a call of the actions and of the scan's three halves can meet (a constituent's action or read, the composition's own records, a lease, the erasure mechanism, a nested action) to where the call lands it and the rule that owns the landing; the per-call rules the contract sweep made restatements retired to Execution Contract Error model 1, the three that only kept a constituent read's lost answer from being read as no record or as unverifiable (read record 5, verify record 7, purge eligible 7); and the cells no rule owned cured: the operator's other reserved references (Primitive policy 9a), an invalid-query from a composition-built query (Capability requirement 3a), the two reasons [Verify Record] routes to step 6, which step 3 and step 5 also prefixed (verify record step 3.2, 5.2), a failed read and the policy registry among a dependency's outages (Term dependency outage), every refusal of the third half's placement (Third half 16), the scan's intent and report under one attempt a run (Third half 11), and a state-unavailable at the scan's record action (Compensation 18). Seal now 28, and every rule that turns a lost answer into a declared refusal, stay as the page's own course, which Error model 1 leaves to the composing pattern. Open lines 2026-10-03-e and 2026-10-03-q dissolved, 2026-10-04-f cured; no model changed; rules 754 to 754. *Over:* the arms found one round at a time. *Because:* the counts since the rewrite onto the Database contract rose and held (Final Critique 38 to 40: 0, 2, 2), each round finding an arm no rule landed; the table checks the arms once on the page, and the page's plateau count starts again from its next round.
- **2026-10-23 — Grounded on Final Critique 38.** *Chose:* the page grounded on one sample, its foundational count zero on the settle's triage and again on the blind second triage, of thirteen foundational reports (four sent down, one of them onto open line 2026-08-30-d, now flagged after the first half's rules; nine rejected); the Summary brought to six sentences, the length the composition shape in `spec-format.md` asks of it, saying in plain words what a composition is where it had left *composition*, *primitive* and *substrate* undefined; every acronym spelled out at its first use, which narrows open line 2026-10-04-q to the process history and the labels out of order; Clock source 4 deleted to Execution Contract Logic confinement 7, which owns the clock's monotonicity for every specification and says a specification cites it and does not restate it; uncovered mark 2 stating the mark's rebuild, as every other derived index's entry states its own (Concurrency 1b, seal now 13, seal now 16); Term intent declaring the word six rules and terms already use for a finding's `audit.reconciliation` record; open line 2026-10-23-a holding the declared terms that carry no term entry; rules 749 to 749. *Over:* another round on a text two triages found no foundational defect in. *Because:* the section titled *What "grounded" means* in `pressure-testing.md` grounds a page whose final round counts zero foundational findings, with the formal-layer vote cast and its models verifying (re-run at this settle: nineteen models, every main holding and every twin and probe caught; the closure enumerator holding and its five twins breaching) and every open line refining or rhetorical, and a page grounded on one clean round owes its second round as its first scheduled rescan (*A clean round is a sample*). Retention Window and Tamper Evidence, two of its constituents, stand under questions for the maintainer, and a cure either answer brings to them reopens this page. What the composition does and answers is unchanged.
- **2026-10-21 — The erasure mechanism shreds, and the regulator's answer is provable.** *Chose:* *shred* (`glossary.md`: destroy the keys that decrypt a record's content, so the content cannot be recovered while every stored version stays as written) in place of the page's own Term shredding-class, deleted with its place on the terms line: erasure mechanism 1, under which the deployment wires an erasure mechanism that shreds, and External check 1, under which an auditor clears that it shreds, with *shred* among the record verbs; by wording alone, Boundary one's heading, the cascade-on-purge paragraph and its WHY, the bank example and the [Purge Event] term entry; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) in the regulator-audit example and the acceptance bar; rules 749 to 749. The knob keeps its name, erasure mechanism, and the bank example's configuration value keeps its code spelling. *Over:* a shredding class declared on this page alone, holding the meaning the glossary now holds once. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood, and Execution Contract Database 5 says a shred is not an erasure; the wording of erasure mechanism 1 and External check 1 changed and no obligation did.
- **2026-10-20 — A holder's lease check and its store write are one transaction, and an abandoned call is the erasure delegation alone.** *Chose:* under the maintainer's ruling of 2026-10-20 14:26Z — Execution Contract Store 2 covers a guard decided across a lease check, the re-read, the lease check and the write being one transaction because the lease's grant lives in the one store — no store write lands beside a closing another holder committed after taking the section, so the rules that kept one from doing so go to Store 2: a leg's [Record Action] landing inside the leg's lease, with the start margin and the declined start that secured it (Per-act critical section 13f, 13g, 13h, Term start margin); the audit of the no-late-landing premise (External check 12); and the abandoned-call rule of a hold placement and of a [Seal Now] (Capability requirement 7f, Concurrency 1e), whose calls are store writes. Term abandoned call is now a delegation to the erasure mechanism, an act outside the store whose destruction can still take effect after a release, so Per-act critical section 2a keeps a cascade's lease, and a re-driving first half's, to its instant for that call alone. Rules 755 to 749. *Over:* a store write two calls behind the check that admitted it, sized, margined and audited so that it landed inside the lease. *Because:* the lease keeps its job for the act outside the store and for nothing a transaction already decides: every lease check (Per-act critical section 9b, 13b, Capability requirement 7d, seal now 19), every section held across a leg's several actions, the sealing lock, the leases' durations and the closure arithmetic stand, the closure floor's formula unchanged. What the composition does for its domain is unchanged.
- **2026-10-20 — The store's guarantees cited, not restated, the record action's critical section among them.** *Chose:* Capability requirement 13 citing Execution Contract Store 1 through 4 for the store the four instances and the composition's own records live in; the rules restating what the store guarantees tombstoned to it (Capability requirement 4, 4a, External check 7, Durability 6, 7, 8, event to attestation 3c, seal coverage 12, erasure outcomes 5, outage record 3, Composition-level invariant 1g, Concurrency 3), with the serialization Concurrency 3 was discharged under and its two discharges (Concurrency 3a, 3b, 3c, 3d, 4, 5); and the machinery that existed only because a [Record Action]'s writes could split or be seen in flight — the record action's own critical section, outlived test and pre-checks, mid-record expiry, the partial state a storage failure at step 3 or step 4 left, the record edge the second and third halves examined below, the second half's binding-set re-read under the section, and [Read Record]'s answer for a Purged retention with no pair (record action step 2.6, 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 3.5, 3.6, 4.1, 4.2, 4.4, 7.2, 7.3, 7.4, 7.6, 7.7, 7.17, Per-act critical section 9c, Concurrency 6, 7, Second half 3, 16, Third half 4, read record step 4.4d, 4.4e, 4.4f). Rules 802 to 755. *Over:* the per-act critical section [Record Action] took from its first write, the 2026-08-30 turn's, which kept a leg off an attestation whose append was still to come. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal: so no leg meets a [Record Action] in flight, a recording-failure leaves nothing committed, and the refusals at step 3 and step 4 still leave their evidence (record action step 7.11), which the second and third halves, the compensation path, its reserved namespace, the closed-state markers, the horizon and the compensation window still close. The cascade's delegation is an act outside the store, so its critical section, the destruction record ahead of it, erasure outcomes and the first half's re-drive stay; the derived indexes stay outside every action's transaction, as `execution-contract.md`'s *Composition state* obligation 2 keeps them, so rebuild-on-miss and the uncovered mark stay. Event Log's sequence numbers order the log and the scan's checks compare its own reads, so the composition cites neither History 1 nor Order 1; what it does for its domain is unchanged.
- **2026-10-04 — The gated hold placement is the deployment's, and Legal Hold is a knob.** *Chose:* the hold placement a declared deployment facility with a term, a rule that no hold over this instance is placed outside it, a named non-goal, and two start refusals where it or its store is missing (Term hold placement, Capability requirement 7g, Non-goal 15, Instance start 31, 32); Legal Hold a knob with a default of absent and a setting rule (Term Legal Hold, Capability requirement 7h). *Over:* a seventh action on this composition, which would have to attest and record a placement Defensible Retention already attests; and an arm on Legal Hold's place, an atom that knows no lease. *Because:* the rule of 2026-10-02 lets an ownership finding close on a capability requirement that states the behaviour and its owner, the placement's rules already bound a party the page did not name, and the scan scheduler, the cadence driver and the erasure mechanism are owned the same way. Closes Ledger lines 2026-10-03-p and v.
- **2026-10-03 — Two ownership findings of round 24 are accepted here: the horizon's periods are supplied, and the purge has a driver.** *Chose:* the deployment supplying at start the retention period of the policy each reserved reference resolves to, the period a declared term and audited against the policy source (Capability requirement 11, Term retention period, Instance start 21, External check 16); the deployment calling [Purge Event] over the eligible list and alerting on a retention still Retained past its purge deadline, the sweep a declared term (purge eligible 8, purge eligible 9, Term purge sweep, External check 13). *Over:* a period read off a policy reference Retention Window declares opaque; a purge cadence as a twentieth knob with a start refusal; and leaving the sweep to the three WHYs that leaned on it. *Because:* Retention Window resolves a policy's duration at the seam and stores a purge deadline on every retention, so both cures use what the atom already declares, and neither adds a knob; the atom observes a late purge and never refuses one, which leaves the driving and the alert to whoever composes it. Closes Ledger lines 2026-10-03-j and k.
- **2026-10-03 — Three ownership findings of round 23 are accepted where this spec is the owner.** *Chose:* content readable as a declared answer the deployment supplies at Event Log's read and Actor Identity's read, with unreadable defined on it and an external check (Capability requirement 8, Term content readable, Term unreadable, External check 14); the Retention Window instance wired declared as one whose purge is the transition alone (Capability requirement 9); the mechanism that cut each seal recorded by the deployment and supplied at verify (Capability requirement 10, 10a, External check 15). *Over:* leaving unreadable to each host's reading of the erasure mechanism, where a host that returns the stored bytes fires none of the rules that test it; a Mechanism Registry pattern for a fact the seam already carries; and declining the atom's rule in a WHY alone. *Because:* each follows the form record set match already has here — a capability the deployment supplies at a constituent's seam, a term, and a check — and Tamper Evidence already has the host supply the cryptographic material (its Operation 22). Closes Ledger lines 2026-10-03-b and c. Line 2026-10-03-a stays open, narrowed: Retention Window has not yet accepted a composing pattern that owns the destruction, and accepting it is a load-bearing touch on a grounded atom.
- **2026-10-02 — The hold over an open entry is modelled: a suspended entry is a term, and closure sum budgets one hold placement.** *Chose:* Term suspended entry — an open entry a run landed under-legal-hold, until a later run reads no active hold — read by quiescence and by the audit edge, so the checks scoped to a quiescent cascade wait for the hold-free run (Term suspended entry, Term quiescence, Term audit edge); closure sum gaining `purge_completion_bound + reconciliation_cadence` WHERE Legal Hold EQUALS composed, one hold placement's lease and the run it displaces (Term closure sum, Instance start 17); `audit-trail-hold.tla` with five twins and three probes, and the enumerator's schedule carrying the placement. *Over:* a window counted from the entry's creation the moment the hold is released, before any run has read it free; a restart for every entry a placement touched, which Composition-level invariant 1i refuses; and a closure sum that budgets a dead run alone. *Because:* the model reaches an entry between its hold's release and the next run, open, not held and past its window, which Check 5.1 read as a conformance failure on a conforming instance — the residue of the finding four rounds reported; and a hold placement takes the entry's section by a waiting take while a leg skips a held section, so one placement costs the entry a run, and with the budgeted dead run the entry outlived closure sum on 2,508 of 2,592 composed tuples. With the part added none does, at zero slack, so it is the least that holds. The model also confirms what the page already said: a placement serialized by the section and a leg that writes nothing on an expired lease keep content from destruction under a hold, and a window restarted from the store's release instant, which a caller may backdate, breaches. Outside the budget, and unchanged: two hold placements over one entry inside one window.
- **2026-10-02 — The closure arithmetic is enumerated, and the third half's rebuild before the take is counted.** *Chose:* Instance start 18 and 19 reading two named terms, closure spend and re-drive spend, with closure spend counting four measured enumerations — two before the take, two under the lease (Term closure spend, Term re-drive spend, compensation closure latency 3, Per-act critical section 13e, walkthrough recomputed to 294 seconds); an enumerator, `tools/harness/audit-trail-closure.py`, that reads the page's own formulas and walks each leg's timeline over the tuples Instance start admits. *Over:* three enumerations, which hold only where a run's enumerations before the take run concurrently, a premise no rule states; a rule requiring that concurrency; and arithmetic written into the two rules. *Because:* a true miss is found during the audit-log pass and made true by the rebuild of event to retention (Third half 3), so a third-half take can follow two enumerations, and at the least closure latency the old check admitted, that leg's lease did not exceed its work bound on 720 of 5,184 tuples and the leg skipped every run under Per-act critical section 13d; four holds on every tuple under both orderings. The enumerator also settles what four rounds of readers recomputed by hand: closure floor is the least that holds (three record action bounds breach), and closure sum holds with one dead run budgeted and breaches without its second run term. GRACE lang Hard invariant 24 puts arithmetic in a term declaration, never in a rule. Not changed: Instance start 23 and 25, Per-act critical section 13a and 13f and External check 11 still carry their arithmetic in the rule.

- **2026-10-01 — The per-act critical section is a Lease on every host, and the sealing lock is one too.** *Chose:* the per-act critical section held as a [Lease](../atoms/lease.md) on every host, the host never freeing it on a belief the holder died (Per-act critical section 1, 3, 4); the death-detected kind, its timeout rules and its start check and external check withdrawn; the sealing lock a lease of a declared seal completion bound, sealed through read from the coverage ranges under it and never from a process cache (Concurrency 1c, seal completion bound, seal now 17, seal now 18); a held event answered as purged on both read surfaces (Invariant 8.2b). *Over:* a host that frees a section when it believes its holder died, a mark the next taker is told about by a death nobody can observe, and a held event left without a read answer. *Because:* the Lease atom forbids ending a grant on a belief of death (Lease Invariant 3.1, Lease Invariant 3.2), the page re-derived lease semantics in prose and had admitted the one host the atom rejects; a seventh fresh reader's gate found the double placement that host allows, and that the seal lock's mark could not see an in-flight seal. This supersedes the death-detected rules of the 2026-10-01 decisions above and the 2026-08-30 reconciliation decision's death-detected host. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — The sealing lock's holder stops writing at expiry, the horizon is checked at start, and the erasure mechanism leaves the read surfaces answering.** *Chose:* [Seal Now] issuing no write once the sealing lock's lease has expired and landing [Recording Failure] (seal now 19, seal now 20); the instance refusing to start unless horizon exceeds compensation window (Instance start 21, Instance start 22); the erasure mechanism leaving Event Log's read returning every event and Actor Identity's read answering the surviving fields (erasure mechanism 6a, erasure mechanism 6b). *Over:* a sealing lock that frees without gating its holder's writes, a horizon nobody checks against the window, and a read tolerance the binding set silently assumed. *Because:* an eighth fresh reader's gate found a stalled holder could seal over a slice the next taker had covered, a policy selector could give audit events a retention shorter than the window and leave every orphan reported and none compensated, and a decrypt-on-read log could omit shredded entries and kill the binding set. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — A holder that abandoned a call keeps its lease to expiry, the per-act lease is audited, and a hold placement is a bounded holder.** *Chose:* a holder that abandoned a constituent call releasing nothing before the lease's instant, for the per-act section and the sealing lock (Per-act critical section 2a, Concurrency 1e); the sealing lock taken by [Seal Now] alone (Concurrency 1d, Concurrency 8); the per-act lease shared by every process and audited by an external check (Per-act critical section 1b, External check 11); a hold placement holding the section as a lease of purge completion bound, issuing no write after expiry and waiting rather than racing (Capability requirement 7c, 7d, 7e); the hold read made after the not-known test and counted a composition-built query (purge event 5c). *Over:* releasing on return whatever the holder abandoned, a lock whose conformance nothing checked, and a hold read keyed on an id nobody had validated. *Because:* two fresh readers of the ninth round, reading in parallel through different lenses, found five gaps between them; `audit-trail-abandon.tla` reaches the early-release state and its twin rejects it. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — An abandoned call is any call to any store, a run's enumeration is inside closure latency, and the lease's length and premise are audited.** *Chose:* the abandoned-call rule covering a call to any store or mechanism, the erasure delegation and the Legal Hold store included, with the host releasing only on the holder's release or at the instant (Per-act critical section 2, 2a, 2b, Capability requirement 7f); the rules that bar a later write after expiry scoped to truth-bearing writes, so a record action past step 4 completes its indexes and its per-event seal (Per-act critical section 7, 8, 9c); compensation closure latency counted from a run's start, its enumeration included, with a run starting within one cadence of the last start (compensation closure latency 3, reconciliation cadence 1a), the frozen liveness inequality keeping its three terms; the holder value minted fresh for each attempt (Per-act critical section 1c); the lease's length, the holder and the no-late-landing premise audited (External check 11, External check 12). *Over:* a release rule that fired on any return, a closure latency that began at the take, and a lease whose length and premise nothing checked. *Because:* the tenth round's two readers found, between them, a held event destroyed by a delegation abandoned inside the old lease, two rules that could not both hold on a record action past step 4, an orphan reached after a long enumeration while every start check passed, a fixed-TTL lock service that passed every external check, and a holder value that let a stalled run read the next run's lease as its own. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — A run ends at the first refusal that left an orphan, the serialization is a lease, and an unreadable hold fails closed.** *Chose:* the scan ending a run at the first reconciliation-path refusal that left an attested orphan (Invariant 1.10), so a standing outage mints one orphan per run and not a tree of them; the serialization discharging Concurrency 3 a Lease of purge completion bound under the abandoned-call and fresh-holder rules (Concurrency 3a, External check 10); [Seal Now] presenting a fresh holder value per attempt (Concurrency 1f); the uncovered mark stored apart from the lock's grant so it outlives the lease (Concurrency 1h); a hold read that does not return the holds landing `cascade-failure(hold)` with no step executed (purge event 5e); [Read Record] re-reading retention when the data is unreadable under *Retained* (read record step 4.5, 4.6); purge event step 0.5 restated on sealed through so it states the same condition as 0.2. *Over:* a retry ceiling per run, a hold read that proceeds on silence, and a lock whose mark dies with its lease. *Because:* each of those left a reachable state with no terminus or a destruction under a hold nobody read; the Lease atom's grant-ends-only-at-release-or-instant rule and the frozen *a stamp from another seam never decides a write alone* decide the first three, and fail-closed is the only arm that cannot destroy what an order forbids.
- **2026-10-01 — The pair's source is keyed on the destruction record, the coverage entry is durable, the outlived test measures at one seam, and a leg's lease counts the run's elapsed time.** *Chose:* event to attestation split on whether the destruction record exists, not on the retention's state, so an entry lost between step 1 and step 2 is rebuilt from the still-readable payload (event to attestation 2, 3); Durability 8 on the coverage entry, since sealed through is the maximum of a derived index whose latest entry is not an observable miss; the outlived test measuring from the invocation's own reading taken before the attest call, two readings at one seam with no allowance and never reading the age low (record action step 2.12, Term outlived, Clock source 1); the first half running first and the circuit break ending only the second and third halves (Reconciliation 1a, Invariant 1.10); a scan leg's lease sized as compensation closure latency less the run's elapsed time at the take, a leg whose remainder does not exceed its work bound skipping the act (Per-act critical section 13a, 13d, Reconciliation 5a); original event payload named as the record set re-presented, the covering range's presentation; [Seal Now] releasing the sealing lock on return; Instance start 6 conditional on the time arm; step 2.9 refusing only a section another holder holds. *Over:* reading the attestation instant through Actor Identity's whole-store read on every call, a rebuild that enumerates the seal store at every take, a fifth closure-sum term for enumeration, and a verify argument that is one event's payload with the range fetched by the composition. *Because:* each was a rule resting on a source the page never named or on an origin two readers placed differently; the Lease atom's rule against a caller subtracting across two seams, and the frozen *a derived index is trustworthy only where a miss is observable*, decide them. Left as they stand and rated: the destruction-failed terminus (Ledger line 2026-08-30-d), and the no-late-landing premise, which stays an audited External check 12 as decided on 2026-10-01.
- **2026-10-01 — Scan legs run concurrently, the erasure mechanism is idempotent over destroyed content, each holder names its lease call, a silent lease host reads as expired, and an outage extends the window.** *Chose:* no scan leg's start waiting on another leg's closure, within a half or across halves, so a backlog of re-drives never eats a later leg's lease, with a skip under the remainder rule surfacing as a deployment-fault alert (Reconciliation 1a, Per-act critical section 13d, 13e); the circuit break reworded to stop only the starting of compensating records (Invariant 1.10); a mechanism asked about already-destroyed content reporting destroyed (erasure mechanism 7a); `try_take` for a record action, a cascade and a scan leg, `take` with a declared arrival term for a hold placement and [Seal Now] (Per-act critical section 15, 15a, Concurrency 1g); a lease call that returns nothing read as expired and a take with no answer at step 2.6 landing as mid-record expiry (Per-act critical section 16); the pause between a reading and the take it sizes counted inside each completion bound; Instance start 23 relating the purge bound to the seal bound; a store outage extending a finding's window, the outage interval recorded, quiescence read per act, Check 2.12 reading the extended window (Composition-level invariant 1c, 1d). *Over:* ordering the halves serially, a per-run cap on re-drives as a new knob, an abandoned-record terminus for the already-destroyed case, and a pause of the window clock with no record. *Because:* a serial run cannot meet a window it does not budget, a cap is a tuning knob the corpus has no number for, and the already-destroyed answer is the only one under which the page's own *permanently unclosable* state cannot arise; the Lease atom's two-ways-to-end rule and the frozen *a derived index is trustworthy only where a miss is observable* decide the rest. Ledger line 2026-08-30-d keeps only a mechanism that always answers destruction-failed.
- **2026-10-01 — A call pause bound is a knob, a run's first compensating record goes alone, an outage restarts the window over every dependency, and the scan has a scheduler.** *Chose:* a nineteenth knob, call pause bound, that every completion bound exceeds and includes, Term lease reading *expired* unless the host's remaining term exceeds it, the outlived test and the leg's lease sizing each subtracting it, so a write on a live lease lands inside it and a grant ends inside the bound it was counted from (call pause bound 1, 2, Term lease, Term outlived, Per-act critical section 13a, Instance start 18, 24, 25); a run issuing its first reconciliation-path [Record Action] alone and starting no other until it has returned success or after a refusal that left an orphan, the probe counted inside closure latency (Invariant 1.10, 1.11, 1.12, compensation closure latency 4, Reconciliation 1a); a store outage covering every dependency a leg or a cascade calls and restarting the finding's window at the later of its creation and the outage's end, with Check 2.4, 2.5 and 2.12 reading the audit edge from that restart (Composition-level invariant 1c, Term audit edge, External check 13); the lease-host-silence rule over every lease the composition takes, a hold placement's and the Concurrency 3 serialization's call kind and refusal arm (Per-act critical section 15a, 15b, 16, Concurrency 3b, 3d); a scan scheduler and a sealing lock each gated at Instance start (reconciliation cadence 6, Instance start 26, 27); an upper edge for the first half at horizon (First half 12, Boundary one 6); a re-declaration obligation when a leg's remainder falls short (Per-act critical section 13e); the scan's reading taken before its enumeration (Reconciliation 5, 5b); invalid-credential on the operator alerted (Compensation 17). *Over:* a closure-sum pause term, a cap on concurrent legs, a pause of the window clock, and leaving the pause as an unnamed ingredient of each bound. *Because:* three readers in three rounds recomputed the closure sum and found the pause between a reading and its take uncounted, and a named knob is the one form a start check can read; concurrent legs and a run's circuit break contradicted each other until the first record goes alone; a restart gives the closure sum its full arithmetic after an outage where an extension did not. Left as recorded: the no-late-landing premise stays audited (External check 12) with the margin now in the page's own seam, the verify presentation's shape (decided 2026-09-30), and Ledger lines 2026-08-30-b and 2026-08-30-d.
- **2026-10-01 — The first half's upper edge is the audit instance's retention, the mark is cleared by its own holder, skew counts twice, and a start check reads a measured enumeration.** *Chose:* the first half's upper edge stated as the retention policy of the audit instance it reads, which keeps everything the half reads indefinitely, and the horizon cut withdrawn (First half 12, Boundary one 6); the uncovered mark set and cleared by compare against the holder's own value on a live lease, the clear inside the seal completion bound (seal now 22, 23); the actor registry among the outage dependencies, an outage defined by calls failing past the call pause bound, the restart limited to an outage that began before the window elapsed, a no-answer attest landing `recording-failure(step-2)` and a no-answer cascade take landing `cascade-failure(in-flight)` (Term store outage, Composition-level invariant 1c, record action step 2.13, purge event step 0.10); the closure sum's skew term doubled, since the scan's reading may run an allowance behind and the widening adds it again, the walkthrough's sum recomputed to 19 minutes 4 seconds; a leg starting a [Record Action] only above that action's bound plus the call pause bound (Per-act critical section 13f); the closure floor four record action bounds, the placement and the probe included, and Instance start 18 and 19 reading a measurement taken at start (Term closure floor, Term measured enumeration, Instance start 18, 19, 28); the scan calling [Seal Now] every run under per-event cadence (seal cadence 3); the knob and check counts propagated. *Over:* a horizon cut that strands a held or outage-delayed entry, a clear any holder may issue, a declared enumeration knob, and leaving per-event retry to the next record action. *Because:* the frozen *every leg names both edges* is met by naming the upper edge the audit instance's retention gives, which for the first half is none; a stale holder's clear reopens the two-seals state the mark exists to prevent; a start check can read a measurement where it cannot read a declaration that grows; an idle per-event trail has no timer, and the scan already has a scheduler (reconciliation cadence 6). Not changed: the registry's behaviour under attest is the Actor Identity atom's silence, not this page's; the verify presentation's shape stands as decided.
- **2026-10-01 — A refusal carries the committed ids, the lease margin is two calls, the per-event retry is an alert and the interval cadence has a driver.** *Chose:* `invalid-request(step-3)`, `invalid-request(step-4)`, `recording-failure(step-3)` and `recording-failure(step-4)` carrying the committed attestation id and event id as an additive payload, so no composer that transcribes the arm token breaks (record action step 7.15, 7.16), which closes Ledger line 2026-08-30-b; Term lease reading live only above twice the call pause bound, the check's answer and the write being two calls, with the completion-bound check, the leg's start margin and the closure floor carrying it (Term lease, call pause bound 2, Instance start 25, Per-act critical section 13f, Term closure floor); a leg taking its section before it waits on the probe (Reconciliation 1b); a failed per-event seal standing as the step-6 alert until a later record, purge or [Seal Now] seals it, withdrawing the scan's per-run [Seal Now] of the previous entry (seal cadence 3); a cadence driver for an interval-based cadence that survives a process loss, fires at start and counts the events arm as the log tail less sealed through, gated at Instance start (seal cadence 4, 5, Instance start 29); Durability 6 holding the pair, the membership and the outcomes for the life of the seal record; overlapping outages read by the latest end (Composition-level invariant 1c); *no answer* defined for any call; the sealing lock, the uncovered mark and the probe given Terms. *Over:* the scan driving a per-event seal each run, which put a seal's time and failure in the closure the scan budgets; routing the step-3 and step-4 payload as a corpus sweep, since the payload is additive; and a margin of one call. *Because:* every seal call the scan adds is up to twice the seal bound inside a lease sized without it; an additive carrier needs no composer to change while leaving a retry able to find what the first attempt committed; and a check followed by a write is two calls under the page's own definition of the knob. Left as decided: the no-late-landing premise (External check 12), the verify presentation's shape, and Ledger line 2026-08-30-d.
- **2026-10-01 — A leg's in-lease reads are inside its work bound, every constituent call has a no-answer arm, an orphan attestation is a non-goal, and the horizon is the lesser of two.** *Chose:* the second and third halves' work bound counting the binding-set re-read and the narrated read as two further measured enumerations, the start check reading three, the measurement covering the retention store too, and a start declined under 13f taking the 13d consequence — alert, re-declare, re-run Instance start 16, 18, 19 and 28 — and skipping the act (Term work bound, Term measured enumeration, Instance start 18, 28, Per-act critical section 13e, 13g); a call that answers no answer landing the step's own arm and never re-issued inside the lease (record action step 3.7, 4.9, purge event step 1.6, 2.8, seal now 24, Per-act critical section 17), a caller not retrying `recording-failure(step-4)` (record action step 7.17); the mark cleared against the value the taker last read under its live lease (seal now 23); an attestation no event binds stated as a non-goal — no retention placed, none destroyed, its retirement left to Erasure Tombstone *(forthcoming)* — and the Summary's lifetime claim narrowed to events (Non-goal 11); horizon the lesser of the retention periods of `audit.compensation` and `audit.reconciliation` events (Instance start 21, Term horizon); the cadence driver counted among the capability requirements and audited (External check 13); Second half 13 and Durability 5 reconciled; the Per-act rules put in order. *Over:* a work bound that stops at the writes, a no-answer arm only for attest, placing a retention on the orphan attestation, which Composes 9 forbids and which has no event to cascade through, and one horizon read from the compensation event alone. *Because:* a re-read that runs under the section is time the lease spends, and a rule the leg cannot meet must say what it does instead; a call whose answer never came may still land, so repeating it can bind two events to one attestation; the corpus's own rule is that a record this page cannot retire is named as such and handed to the pattern that will. Not changed: the compare-and-clear's stale-mark cost on an idle firing, the horizon comparison's allowance widening, and the acronym glosses, all refining.
- **2026-10-01 — The leg's reads are one enumeration, the read surfaces answer no answer rather than not-known, and the nested record action sits inside the leg's lease.** *Chose:* the binding-set re-read, the marker reads and the narrated read served from ONE enumeration read under the section (Second half 17), the work bound counting one measured enumeration under the lease and the start check two in all — one before the take, one under it — which replaces the three of the previous entry; the measured enumeration taken as the audit log followed by the destruction-record read, the order Second half 15 forces, against the attestation store and the retention store (Term measured enumeration, Instance start 18, 28); the walkthrough recomputed to 214 seconds; a [Record Action] a leg starts completing its writes inside its bound and the leg's lease (Per-act critical section 13h); [Read Record], [Verify Record] and [Purge Eligible] answering no answer, never not-known, an unverifiable or an empty list, when a constituent read answers none, and Invariant 6.1 holding while the reads answer (read record 5, verify record 7, purge eligible 7, Invariant 6.1). *Over:* three enumerations in the lease, an `unavailable` arm on each read surface, which adds a token every composer would transcribe, and a nested lease for the leg's record action. *Because:* the closed-state markers are derived from the same log pass, so one read serves them all; a read surface that cannot see a store has no true answer to give, and the call-level no answer is the one already used for every other call; the premise that a record action completes inside its bound makes the leg's lease the outer fence without a second lease. Not changed: Ledger line 2026-08-30-d, the horizon comparison's widening and the acronym glosses.
- **2026-09-30 — The binding set reads payloads by readability, not retention state, and reads destruction records second.** *Chose:* the first enumeration takes the attestation id from every payload the full enumeration reads, whatever the retention state, and the destruction records are read after it (Second half 14, Second half 15); record set match is declared a deployment requirement with its own external check (Capability requirement 5, Capability requirement 6, External check 8). *Over:* keying the first enumeration on live, and leaving Tamper Evidence's host obligation to the atom's own page. *Because:* a fresh reader found that between [Purge Event] steps 1 and 2 a retention reads *Purged* over a readable payload with no destruction record yet, so the old keying held the attestation in neither enumeration and the scan compensated a lawfully held attestation; `audit-trail-binding.tla` reaches it and both twins (retention-keyed, records-first) fail it. The same reader found the record set match obligation declared nowhere on the page. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-09-30 — invalid-request carries the step, as recording-failure does.** *Chose:* record_action refuses `invalid-request(step)`, step-1 through step-4, and a caller is told not to retry on step-3 or step-4 (record action step 7.9 through 7.13); every composer that transcribes the arm reads the step. *Over:* a bare token, and a second refusal code. *Because:* the bare token landed at steps 1–2 with nothing committed and at steps 3–4 after the attestation and the event committed, so a caller told *invalid-request* could retry a committed act and mint a second attestation; the frozen rule that a composition's own rejection arm carries the retry bit, and the precedent `recording-failure(step)` already set, decide it. The cold gate of 2026-09-30 found it; closes the 2026-08-30-a ledger line.
- **2026-09-27 — A finding is narrated once, and the cascade's re-drive reads what already landed.** *Chose:* a finding's intent carries its subject and id, and the scan reads *narrated* under the critical section before writing one (Compensation 9 through 11); the pre-check names the destruction record and a destroyed outcome, the reads *proceed as landed* already named. *Over:* leaving the next run to re-detect the finding and narrate it again, and a pre-check list that left a re-driven cascade free to rewrite its destruction record or re-delegate a completed destruction. *Because:* the cold regeneration of 2026-09-27 wrote two intents for one orphan and two for one unretained event whenever the repair failed after its intent landed, against one record per finding (Compensation 2).
- **2026-08-30 — The reconciliation is one writer per act, bounded at both edges, and the scan writes its intent before its repair.** *Chose:* a per-act critical section keyed by the act's id (attestation id for a record action, event id for a cascade), declared as an instance capability requirement with lease semantics, held by the invocation from its first write and taken by every scan half before its pre-check; two completion bounds (record action completion bound, purge completion bound) below which no half examines anything and at which the invocation yields; a horizon at which the second half reports rather than re-compensates, once, behind a reported beyond horizon marker; compensation closure latency and clock offset allowance declared, the window measured from the finding's creation, the three-term inequality checked at start; the scan reading its own now once per run; `audit.reconciliation` written one record per finding before the act it announces, under a declared reconciliation operator credential; the scan as the sole writer of an orphan's compensation. *Over:* a third half whose placement raced the invocation's own step 4 under no shared key; halves with no lower edge, compensating attestations and events whose [Record Action] was still between two steps; a window measured from detection and an inequality with one term; a findings record of unbounded size and unstated position. *Because:* two writers over one act land two records the seal protects forever, a leg with no lower edge reads work in flight as an orphan and corrects it, and a liveness promise is arithmetic or it is nothing (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *An outcome is sized before the intent*, and *Capability provenance*; with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md` and the section titled *Recovery commits under a declared service identity* in `pressure-testing.md`). The four contract-shaped sites — invalid-request's position, `recording-failure(step-4)`'s event id, the Event Log durability obligation, Invariant 8's abandoned terminus — are routed as open lines rather than fixed, because every composer transcribes them. *Round 2, same day:* the inequality gained its skew term and its closure latency (the whole closure, intent through compensation, or a cascade round-trip); the per-act critical section gained its non-lease branch — a leg skips a held act and never blocks, a host that cannot detect death must lease, and the non-lease terminus is *proceed as landed* behind step 4's pre-check; the lease terminus is confined to steps 2–4 inclusive, an invocation past step 4 completing its index writes; the beyond-horizon report and the recording-half detector both gained the horizon; and every *all succeed or none* sentence over un-withdrawable writes was restated as ordered writes plus compensation. The five *until a destroyed outcome lands* loops are bounded by open line 2026-08-30-d rather than given a terminus here.
- **2026-08-24 — Seal supersession is extracted to a forthcoming Seal Lifecycle composing pattern, not absorbed.** *Chose:* remove the Reseal action, `superseded_by`, `reseal_on_purge` and every current-seal qualification from the canonical composition; name Seal Lifecycle as owner of re-sealing partly purged seals, mechanism rotation, and supersession bookkeeping. *Over:* keeping the mechanism added at Final Critique 6. *Because:* which seal is current over a range two seals cover is new truth no constituent store carries and no rebuild replays — it clears the extraction gates, and it had spread through three invariants, three checks and four cards.

NOTE: End of Audit Trail.

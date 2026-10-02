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

Audit Trail answers, all at once, the four questions a regulator or investigator asks about any consequential action: what happened, who authorized it, has the record been altered, and was it kept long enough?

It does this by wiring four simpler patterns into one queryable record: an add-only event log (what happened), cryptographic attribution tying each event to the actor who performed it (who), tamper-evident sealing that makes any after-the-fact change detectable (has it been altered), and a retention policy that fixes how long records are kept (kept long enough). None of the four answers the full question alone; stacked, they produce a record that is observable, attributable, tamper-evident, and lifetime-bounded for every event, and the stack adds guarantees none has alone: every event is logged, attributed, retention-tracked, and sealed at once, and a query on any kept event returns a definite answer that tells a lawfully destroyed record from a missing one.

None of the four patterns deletes a record of its own, which is what makes them trustworthy. So the end of a record's life is not a deletion: the composition records the lawful end of the retention period, marks on the covering seal exactly which of the records it commits to were destroyed, and hands the destruction of the stored content to whatever erasure mechanism the deployment has declared. What survives is the proof that the record existed and was destroyed lawfully — which is what the regulator asks for.

This is the canonical audit substrate — a composition, not a new primitive — behind financial-controls, healthcare-access, cardholder-data, and broker-dealer audit requirements, and other compositions build on it.

---

## Intent

WHY:
Every regulated system carries the same obligation: when the auditor arrives, the system must answer four questions about any action of consequence — what happened, who authorized it, has the record been altered, and was the retention obligation honored — for any record, on demand, over the regulatory horizon. Each question maps onto one of four atoms. Event Log records the fact and does not bind it to an actor; Actor Identity binds the actor and does not commit to the record's integrity; Retention Window bounds the lifetime and does not detect rewriting; Tamper Evidence detects rewriting and does not name the actor. Stacked, they answer in one structure: an [Audit Record]. The four atoms are unchanged; the composition is the wiring — one consolidated audit surface rather than four record stores the auditor correlates by hand. The construction is the one every audit-grade system in production runs: signed events appended to an immutable log, sealed on a cadence against a tamper-evident structure, governed by a retention policy with a structural no-early-purge guarantee.

---

## Composes

- **[Event Log](../atoms/event-log.md)** — the append-only, totally-ordered sequence the *what happened* answer is read from. The composition's one instance is the audit log.
- **[Actor Identity](../atoms/actor-identity.md)** — the verifiable attribution the *who authorized it* answer is read from. The one instance is the attestation store.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime the *was the retention honored* answer is read from. The one instance is the retention store, configured with the host's regulatory policy or a policy selector.
- **[Tamper Evidence](../atoms/tamper-evidence.md)** — the integrity proof the *has the record been altered* answer is read from. The one instance is the seal store, sealing ranges of the audit log on a configured cadence.

```
Composes 1: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 4: EXACTLY ONE Tamper Evidence instance MUST serve the composition.
Composes 4a: EVERY one of those four instances MUST be dedicated to this composition, so that no record another composition or a direct caller wrote enters an enumeration the composition reads.
Composes 5: The composition MUST call ActorIdentity.attest at [Record Action] step 2 alone.
Composes 6: The composition MUST call ActorIdentity.verify at [Verify Record] step 3 alone.
Composes 7: The composition MUST read an attestation's surviving fields through Actor Identity's declared read.
Composes 8: The composition MUST NOT delete an attestation.
Composes 9: The composition MUST call RetentionWindow.place_under_retention at [Record Action] step 4 and at the third half's compensating placement alone.
Composes 10: The composition MUST call RetentionWindow.purge at [Purge Event] step 1 alone.
Composes 11: [Purge Eligible] MUST read eligibility through Retention Window's declared read.
Composes 12: The composition MUST NOT evaluate an eligibility clock.
Composes 13: The composition MUST call TamperEvidence.seal from [Seal Now] alone.
Composes 14: The composition MUST call TamperEvidence.verify at [Verify Record] step 5 alone.
Composes 15: The composition MUST NOT write an entry into the seal store other than through TamperEvidence.seal.
Composes 16: The composition MUST NOT dispose of a seal.
Composes 17: The composition MUST NOT seal a range some seal covers.
```

Term audit log: the composition's Event Log instance.

Term attestation store: the composition's Actor Identity instance.

Term retention store: the composition's Retention Window instance.

Term seal store: the composition's Tamper Evidence instance.

Term surviving fields: an attestation's attestation id, action reference, actor reference and attestation instant — Actor Identity's five-field record less the proof.

---

## Composition logic

### Composition state

Eight elements, each carrying the Contract classification of the section titled Composition state in [`execution-contract.md`](../execution-contract.md). Five are wholly derived indexes — event to retention, event to sequence, sealed through, compensated attestations, reported beyond horizon. Two split — event to attestation is derived for live events and extraction-pending for purged ones; seal coverage is derived over ranges and carries one extraction-pending per-entry set. One is wholly extraction-pending — erasure outcomes.

Term derived index: an element regenerated from the constituent stores by the element's rebuild procedure.

Term extraction-pending: an element carrying truth no constituent store replays, classified against a named proposed atom.

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

WHY:
An index entry is evidence that the truth-bearing writes committed, never a peer write the compensation protocol has to handle. Both sides of every derived mapping are immutable constituent content, so each rebuild is total over what the constituent stores still hold.

- **event to attestation**
  Term event to attestation: map from event id to the attestation id Actor Identity produced at record time; the auditor's traversal from an event to its attribution. The classification splits by whether the event's destruction record exists, because the rebuild's source does not survive the cascade's step 3 and the destruction record is written before it.
  ```
  event to attestation 1: [Record Action] step 5 MUST populate event to attestation with the event's event id mapped to the attestation id.
  event to attestation 2: WHEN no destruction record EXISTS for the event:
      event to attestation 2a: The composition MUST classify the entry as derived index.
      event to attestation 2b: The rebuild MUST take, for EVERY event the full enumeration returns, the event's event id as the key and the payload's attestation id as the value.
  event to attestation 3: WHEN a destruction record EXISTS for the event:
      event to attestation 3a: The composition MUST classify the entry as extraction-pending against Erasure Tombstone.
      event to attestation 3b: The destruction record MUST carry the pair (event id, attestation id).
      event to attestation 3c: The pair MUST carry the durability obligation of Durability 6.
  ```
  WHY: [Record Action] step 3 writes attestation id into the appended payload, so the live binding is immutable Event Log content. The cascade destroys the payload's recoverability, so for a purged event the binding is destroyed with the thing that carried it, and only a record written before the delegation can carry it ([Purge Event] step 2). The split is keyed on that record and not on the retention's state, because step 1 moves the retention to *Purged* before step 2 captures the pair: an entry lost in that window is rebuilt from the payload, which stays readable until step 3 and step 3 does not run before the record has landed (purge event step 2.4).
- **event to retention**
  Term event to retention: map from event id to the retention id Retention Window produced at record time; the policy the event is held under.
  ```
  event to retention 1: [Record Action] step 5 MUST populate event to retention with the event's event id mapped to the retention id.
  event to retention 2: The composition MUST classify event to retention as derived index.
  event to retention 3: The rebuild MUST enumerate the retention store and re-key each retention record by the record's record reference.
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
  WHY: Event Log declares no read-by-id surface — read takes a sequence-number range, a wall-time range or a payload predicate, and routes lookup by payload field to a Reverse Index pattern *(forthcoming)*. Event Log's State 2 declares that every returned event carries its event id, sequence number, recording instant and data, so both sides of the map are immutable Event Log content and the rebuild is total; the relation event id ↔ sequence number is one-to-one and mandatory on both sides at quiescence (Event Log Invariants 2, 3 and 6), and a lost entry is a rebuild trigger, never a relation violation.
- **seal coverage**
  Term seal coverage: for each evidence id in the seal store, the contiguous sequence-number range the seal commits to as [Seal Now] cut it, plus a per-entry purged events set the cascade writes; what tells the verifier which record set to present.
  ```
  seal coverage 1: [Seal Now] MUST populate seal coverage with the evidence id mapped to the sealed slice.
  seal coverage 2: The composition MUST classify the ranges of seal coverage as derived index.
  seal coverage 3: The rebuild of the ranges MUST enumerate the seal store and read each evidence record's record set reference.
  seal coverage 4: The rebuild of the ranges MUST NOT issue EventLog.read.
  seal coverage 5: A coverage range MUST key on sequence number.
  seal coverage 6: A coverage range MUST NOT key on event id.
  seal coverage 7: Two coverage ranges MUST NOT overlap.
  seal coverage 8: A coverage range MUST NOT carry a hole.
  seal coverage 9: The composition MUST classify purged events as extraction-pending against Erasure Tombstone.
  seal coverage 10: The cascade MUST record the records-purged fact at event granularity.
  seal coverage 11: The cascade MUST NOT flag a whole seal coverage entry as purged.
  seal coverage 12: purged events MUST carry the durability obligation of Durability 6.
  seal coverage 13: The slice reference MUST encode the slice's first and last sequence number.
  ```
  Term purged events: the set of sequence number values within one seal's range whose content the cascade has had destroyed.

  Term covering seal: the evidence id whose seal coverage range contains the event's sequence number.

  WHY: event id carries no ordering, so a range of ids is not an interval. Nothing but [Seal Now] writes a coverage entry, and a crash or a refused write between its seal and its coverage entry leaves one evidence record with no entry, the one partial state: [Seal Now] rebuilds the ranges from the seal store before it reads sealed through when the sealing lock's uncovered mark stands (seal now 13), which regenerates the entry from the slice reference (seal coverage 13) and keeps sealed through from lagging the store. The mark is set before the seal and cleared only once the coverage entry has landed or the seal is known to have written nothing (seal now 15, seal now 16), so a holder whose lease ran out, a refused coverage write and a holder that stalled past its lease all leave it set for whichever process takes the lock next, and by then every seal the stalled holder issued has landed (Concurrency 1c, seal completion bound 2); the store is enumerated once per such event where the mark is carried and once per firing where the deployment leaves it unknown (Concurrency 1b), and so the next firing cuts past the evidence and a hole or an overlap is not a state a firing reaches. A seal covering a thousand events is very often partly purged and partly live — a policy selector gives two events in one range two retention periods — and a whole-entry flag would report a live event as destroyed. No constituent store says *this member was later destroyed*, so no rebuild regenerates the set.
- **erasure outcomes**
  Term erasure outcomes: for each event over which [Purge Event] step 3 has issued its delegation, the outcome the configured erasure mechanism reported: destroyed or `destruction-failed(reason)`.
  ```
  erasure outcomes 1: The cascade MUST record the mechanism's reported outcome in erasure outcomes for EVERY delegation [Purge Event] step 3 issues.
  erasure outcomes 2: erasure outcomes MUST address an outcome per event id.
  erasure outcomes 3: The composition MUST classify erasure outcomes as extraction-pending against Erasure Tombstone.
  erasure outcomes 4: The outcome record MUST land on the event's destruction record.
  erasure outcomes 5: erasure outcomes MUST carry the durability obligation of Durability 6.
  erasure outcomes 6: A destruction-failed record MUST NOT close an entry.
  ```
  Term closed entry: an erasure outcomes entry among whose records a destroyed outcome exists.

  Term open entry: an erasure outcomes entry that is not a closed entry; open for re-driving.

  WHY: no constituent witnessed the mechanism's report. A lost outcome is not re-derivable from any store, so the mechanism answers it again: a re-delegation over already-destroyed content reports destroyed (erasure mechanism 7a), which closes the entry. Four surfaces read the element: First half 3, purge event step 4.1, Invariant 8.3 and Check 5.8.
- **sealed through**
  ```
  sealed through 1: The composition MUST classify sealed through as derived index.
  sealed through 2: The rebuild MUST compute sealed through from the rebuilt ranges of seal coverage.
  ```
  Term sealed through: the maximum sequence number over all seal coverage ranges; zero for an empty seal store.

  Term unsealed tail: the events whose sequence number EXCEEDS sealed through.
- **compensated attestations**
  Term compensated attestations: the set of attestation id values for which an `audit.compensation` event has been recorded; the closed-state marker for orphan reconciliation.
  ```
  compensated attestations 1: The composition MUST classify compensated attestations as derived index.
  compensated attestations 2: The rebuild MUST keep, from the full enumeration, EVERY event whose action reference EQUALS audit.compensation AND whose payload subject EQUALS attestation, and take the attestation id each payload names.
  compensated attestations 3: The rebuild MUST filter on the subject-kind discriminator.
  compensated attestations 4: The rebuild MUST filter in composition code.
  compensated attestations 5: A deployment composing Reverse Index MAY filter through Reverse Index as an instance optimization.
  compensated attestations 6: The rebuild MUST cover the audit.compensation events live in the log.
  ```
  Term reconciled: an orphan whose attestation id is a member of compensated attestations.

  WHY: the orphan never goes away — Actor Identity Invariant 9 forecloses deletion — so the store cannot carry the closure; the marker does. Without the subject filter a rebuild would read an event id where it expected an attestation id. Compensation events are themselves purged in time, so the rebuilt set covers the compensations still live (compensated attestations 6); the residual — a second compensation for an orphan compensated a retention period earlier — is a duplicate, never a false record. The rebuild is trustworthy because the reserved namespace (Primitive policy 8) means the set is read from records only the composition's own reconciliation path could have written.
- **reported beyond horizon**
  Term reported beyond horizon: the set of attestation id values for which the scan's second half has recorded a *beyond the horizon* finding; the closed-state marker for that report.
  ```
  reported beyond horizon 1: The composition MUST classify reported beyond horizon as derived index.
  reported beyond horizon 2: The rebuild MUST keep, from the full enumeration, EVERY event whose action reference EQUALS audit.reconciliation AND whose payload subject EQUALS attestation AND whose payload disposition EQUALS beyond-horizon, and take the attestation id each names.
  reported beyond horizon 3: The rebuild MUST cover the audit.reconciliation events live in the log.
  ```
  WHY: the orphan is permanent, so without the marker the report would be written every cadence; with it, an orphan past the horizon is reported at most once per retention period of the report itself — an orphan the attestation store still holds when its report's own retention ends is reported again, because the marker lasts exactly as long as the report — and a short rebuild produces a duplicate report, never a false one.

### Capability requirement

```
Capability requirement 1: The wired Event Log instance MUST expose the open-upper-bound read.
Capability requirement 2: The deployment MUST alert on invalid-query from a composition-built query as a deployment fault.
Capability requirement 3: The composition MUST NOT surface invalid-query from a composition-built query as an outcome of any action.
Capability requirement 4: The deployment MUST persist the wired Event Log instance across a process restart, next sequence number included.
Capability requirement 5: The deployment MUST supply record set match at TamperEvidence's seam from the presented record set and the evidence's record set reference.
Capability requirement 6: The deployment MUST judge record set match against the record set reference the seal committed to.
Capability requirement 7: WHEN Legal Hold EQUALS composed:
    Capability requirement 7a: The deployment MUST serialize a hold placement over an event id with the per-act critical section keyed by that event id.
    Capability requirement 7b: The deployment MUST read hold from the Legal Hold store instance wired to this instance.
    Capability requirement 7c: A hold placement MUST hold the critical section as a lease of purge completion bound.
    Capability requirement 7d: A hold placement MUST NOT issue a write after the lease has expired.
    Capability requirement 7e: A hold placement that finds the critical section held MUST wait for the lease's instant or the holder's release.
    Capability requirement 7f: A hold placement MUST be a holder for Per-act critical section 2a.
```

Term open-upper-bound read: `EventLog.read` over a sequence-number range beginning at a given sequence number with no upper bound.

Term record set match: yes | no — the host's answer, at Tamper Evidence's seam, to whether the record set [Verify Record] step 5 re-presents is the record set the evidence's record set reference names; Tamper Evidence cannot judge it (its Operation 22a, Operation 22b), and a no surfaces as `failed-verification(seal-record-set-mismatch)` (verify record step 5.2).

Term full enumeration: the open-upper-bound read beginning at sequence 1.

Term composition-built query: the open-upper-bound read, the singleton range read of event to sequence 5, and the hold read of purge event 5c — queries the composition builds from its own indexes and from an event id a constituent already knows, which no unvalidated caller input reaches.

WHY:
Eleven procedures issue the read and none has a substitute — [Seal Now]'s head read, [Record Action] step 5's read-back, the rebuilds of event to sequence, event to attestation's live entries, compensated attestations and reported beyond horizon, the scan's binding set and third half, the scan's narrated and owed narration reads, and the auditor's own enumeration at Check 2 — and the last is why the requirement is a deployment obligation: an instance that cannot serve it cannot be audited for orphan-freedom at all. No caller input reaches any of these queries (Capability requirement 3). Event Log disclaims persistence across a restart and requires a composing pattern to declare it (its Durability 2 and Durability 4); every rebuild, the binding set and [Read Record] step 3's unreachable-by-construction cell rest on the log surviving one, and a volatile log reads every attestation as an orphan (Capability requirement 4, External check 7).

Nineteen knobs and four instance capability requirements — the per-act critical section, here, the sealing lock (Concurrency 1), the scan scheduler (reconciliation cadence 6) and, for an interval-based cadence, the cadence driver (seal cadence 4). Each knob carries a type, a default and a setting rule; every default of *none* is deployment-required, and the section titled *Instance start* is the one owner of what an instance refuses to start without.

- **retention policy**
  Term retention policy: a Retention Window policy reference, or a policy selector `(action_ref, actor_ref, data) → policy_ref` for content-derived rules. *Default:* none.
  ```
  retention policy 1: The deployment MUST set retention policy to the reconciled policy for the record class.
  retention policy 2: [Record Action] step 4 MUST place the retention under the resolved policy.
  retention policy 3: EXACTLY ONE retention record MUST govern an audit event and the event's attestation.
  retention policy 4: The composition MUST NOT hold an attestation meta-retention policy.
  retention policy 5: The composition MUST retain a seal indefinitely.
  ```
  Term reconciled policy: the longest applicable retention across every regulation in force, the strictest data-minimization posture, and any conflicting destruction rules reconciled — produced by a Policy Reconciliation pattern *(forthcoming)*.

  Term resolved policy: retention policy where the knob is a policy reference; the policy reference the selector returns where the knob is a selector.

  WHY: a retention period is a legal obligation, and a composition that picked one would assert a legal conclusion it cannot make; a Policy Reconciliation pattern *(forthcoming)* produces the reconciled value across every regulation in force. The attestation's lifetime rides the event's retention and the two are destroyed in one cascade, so the *Composes* declaration of one Retention Window instance is literally accurate.
- **seal cadence**
  Term seal cadence: `per-event` | interval-based | on-demand; an interval-based cadence carries an events arm (every N events), a time arm (every T seconds), or both. *Default:* none.
  ```
  seal cadence 1: The deployment MUST set seal cadence from the forensic window the deployment's regime tolerates.
  seal cadence 2: A deployment whose auditor requires a bounded per-event tampering window MUST set per-event.
  seal cadence 3: A per-event seal that failed at step 6 MUST stand as the alert of record action step 6.5 until a later [Record Action], [Purge Event] or [Seal Now] seals it.
  seal cadence 4: WHERE seal cadence EQUALS interval-based the deployment MUST supply a cadence driver that fires on the time arm and the events arm, survives the loss of any one process, and fires at start and at restart.
  seal cadence 5: The events arm MUST count the log tail less sealed through.
  ```
  Term cadence driver: the host facility that calls [Seal Now] per an interval-based seal cadence.

  Term time arm: the every-T-seconds arm of an interval-based seal cadence.

  WHY: the cadence bounds the forensic window for any detected tampering; tighter cadence narrows the window at the cost of seal-store growth and verify-time work, and a coarse cadence strands more live seal-mates at every purge (Edge cases).
- **seal mechanism**
  Term seal mechanism: a Tamper Evidence mechanism reference: hash chain, Merkle tree, RFC 3161-anchored timestamp. *Default:* none.
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

  WHY: Tamper Evidence is mechanism-neutral (its Invariant 8) and records the choice outside itself, so the knob declares the wired choice and configures nothing; every disagreement but a refused credential is invisible by opacity, which is why seal mechanism 5 is audited outside the records (External check 4). Nothing in the seal store says which rendering a seal committed to, so a mechanism that hashed a different order or a re-serialized form would fail every conforming presentation with nothing in the trail saying why; Tamper Evidence's Non-goal 11 and Non-goal 12 route the agreement to the host, and this composition is the host.
- **mechanism credential**
  Term mechanism credential: opaque credential material passed to `TamperEvidence.seal` on every seal, whatever the cadence: a signing key for a keyed mechanism, a TSA client credential for an anchored one. *Default:* empty (unkeyed).
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

  WHY: a bare hash chain needs no credential and Tamper Evidence permits an empty one, so the precondition check lives in the constituent, not here. Non-repudiation depends on the credential, not on this composition's surface.
- **unsealed tail mode**
  Term unsealed tail mode: strict | lenient: what [Verify Record] returns for an event in the unsealed tail. *Default:* strict.
  ```
  unsealed tail mode 1: A deployment MAY set lenient ONLY IF independently trusted substrate EXISTS AND standing false negative EXISTS.
  unsealed tail mode 2: A regulated deployment MUST NOT set lenient.
  NOTE: watch applicability — the source's setting rules read *where X, do Y*; the applicability is carried in the subject here (unsealed tail mode 2, seal mechanism 2, reference length cap 3, mechanism credential 7).
  unsealed tail mode 3: IF unsealed tail mode EQUALS blank THEN the instance MUST take strict.
  ```
  Term independently trusted substrate: a log substrate trusted apart from this composition's seals — WORM storage, an external replica.

  Term standing false negative: the strict unsealed tail mode answering `failed-verification(unsealed)` for the whole of a coarse cadence interval.

  WHY: strict is the fail-closed value — integrity is unverified until a seal covers the event, and defaulting the other way would let a deployment report unverified events as `verified` by omission. Regulated deployments keep strict.
- **erasure mechanism**
  Term erasure mechanism: a reference to the deployment's composed content-destruction mechanism, invoked at [Purge Event] step 3. *Default:* none.
  ```
  erasure mechanism 1: The deployment MUST wire a shredding-class erasure mechanism.
  erasure mechanism 2: The deployment MUST NOT wire a tombstone-by-mutation mechanism.
  erasure mechanism 3: The erasure mechanism MUST destroy the readability of the whole of Event Log's data field.
  erasure mechanism 4: The erasure mechanism MUST destroy the readability of the attestation's proof.
  erasure mechanism 5: The erasure mechanism MUST NOT rewrite a stored field.
  erasure mechanism 6: The erasure mechanism MUST leave the attestation's surviving fields readable.
  erasure mechanism 6a: The erasure mechanism MUST leave Event Log's read returning EVERY event, the data field unreadable where destroyed.
  erasure mechanism 6b: The erasure mechanism MUST leave Actor Identity's read answering the surviving fields, the proof unreadable where destroyed.
  erasure mechanism 7: The erasure mechanism MUST report EXACTLY ONE OF destroyed, destruction-failed(reason) for EVERY event the mechanism is asked about.
  erasure mechanism 7a: IF the content the mechanism is asked about has already been destroyed THEN the mechanism MUST report destroyed.
  erasure mechanism 8: The erasure mechanism MUST name the event id in EVERY outcome.
  erasure mechanism 9: The deployment MUST evidence the mechanism's class to the auditor outside the records.
  ```
  Term shredding-class: a mechanism that destroys recoverability — the key material under which the content was stored — and never a stored byte.

  Term tombstone-by-mutation: overwriting, blanking or truncating a stored field in place.

  Term Event Log's data field: the whole constructed object `{action_ref, actor_ref, attestation_id, data}` [Record Action] step 3 appends; the caller-supplied data is one member inside it.

  WHY: the name data does double duty. The mechanism takes the outer object, so the payload's copies of action reference, actor reference and attestation id go with it, which is why the purged-event answers read the attestation store; the *who / what / when* outlives the purge, the payload and the binding's verifiability do not. There is no safe default: defaulting to *no destruction* would leave *Purged* over readable content, the gap Invariant 8 forecloses. A mechanism that only reported *I was called* would make success undecidable (erasure mechanism 7), and an outcome not traceable to its event could close nothing (erasure mechanism 8). The class boundary is argued at Boundary one.
- **compensation window**
  Term compensation window: the duration within which the liveness arms of Invariants 1, 2 and 8 close: an orphan attestation, an unretained event or a half-completed cascade is surfaced and reconciled inside it. *Default:* none.
  ```
  compensation window 1: The deployment MUST set compensation window from the tightest reconciliation deadline the deployment's regime imposes.
  compensation window 2: The composition MUST measure compensation window from the finding's creation.
  compensation window 3: The composition MUST NOT measure compensation window from the finding's detection.
  compensation window 4: An auditor MUST read the quiescence condition of Check 2 from compensation window.
  ```
  Term finding's creation: the orphan attestation's attestation instant; the unretained event's recording instant; the half-completed cascade's purge instant.

  WHY: the window is the deployment's declared tolerance for a surfaced finding standing open — a regulatory judgment about its own regime. An orphan created at `t` is invisible to the scan until `t + bound + 2 * allowance` — its reading may run an allowance behind the stamp and the widening adds the allowance again — the next run is at most one cadence later, a record action's lease begins at its take, up to one bound after the attestation, and runs one bound, so an orphan whose invocation died holding the section stays hidden from a leg for up to two bounds after the attestation (the first term of the closure sum doubles the record action's bound); a run that dies holding the section strands it until its lease runs out — one latency — and the run after it is one cadence later still, and the closure lands one latency after that (Instance start 16); the scan is budgeted for one dead run, not for a run that dies every time; a cadence no longer than the window is satisfied by a deployment that breaches on every orphan.
- **reconciliation cadence**
  Term reconciliation cadence: how often the reconciliation scan runs, measured from one run's start to the next's. *Default:* the time arm of seal cadence where that cadence carries one; none otherwise.
  ```
  reconciliation cadence 1: The reconciliation scan MUST run PER reconciliation cadence.
  reconciliation cadence 1a: A run MUST start no later than reconciliation cadence after the previous run's start.
  reconciliation cadence 2: The reconciliation scan MUST run at restart.
  reconciliation cadence 3: IF time arm EQUALS blank THEN the deployment MUST set reconciliation cadence.
  reconciliation cadence 4: IF time arm DOES NOT EQUAL blank AND reconciliation cadence EQUALS blank THEN the instance MUST take the time arm as reconciliation cadence.
  reconciliation cadence 5: reconciliation cadence MUST govern all three halves of the scan.
  reconciliation cadence 6: The scan scheduler MUST start the next run no later than reconciliation cadence after the previous run's start WHEN the process that ran it has died.
  ```
  Term scan scheduler: the host facility that starts scan runs and survives the loss of any one process serving the instance.
  WHY: an events-only cadence yields no duration — a rate in appends says nothing about how long a finding may stand, and a quiet write period would stretch the interval without bound while the window kept running — so events-only, per-event and on-demand cadences are deployment-required. The time arm is the safe derived default because it is the rate at which the deployment has already declared it wants the audit surface brought up to date. A deployment tightens the cadence where purge volume would otherwise leave many unreconciled entries per sweep.
- **reconciliation operator**
  Term reconciliation operator: an actor reference: the deployment's maintenance actor authorized to record under the reserved `audit.*` namespace; the discriminator [Record Action] step 1's namespace gate turns on. *Default:* none.
  ```
  reconciliation operator 1: The deployment MUST provision reconciliation operator as an actor in the wired attestation store with usable credential material.
  reconciliation operator 2: [Record Action] step 1 MUST decide the reconciliation path by actor reference EQUALS reconciliation operator, byte-identity.
  ```
  WHY: without a declared discriminator the gate is undecidable — *external caller* names no observable property of a call — so an implementer could refuse `audit.*` from everyone (the liveness arms never close) or accept it from everyone (the closure marker is forgeable). Knowing the operator's actor reference admits a caller past step 1 only; step 2's attest still demands the credential, so an `audit.*` event cannot exist in the log unless attested under the operator identity (Check 7).
- **reconciliation operator credential**
  Term reconciliation operator credential: opaque credential material for the actor reconciliation operator names. *Default:* none.
  ```
  reconciliation operator credential 1: The scan MUST hand reconciliation operator credential to ActorIdentity.attest on EVERY reconciliation-path write.
  reconciliation operator credential 2: The composition MUST NOT inspect reconciliation operator credential.
  reconciliation operator credential 3: The composition MUST NOT log reconciliation operator credential.
  reconciliation operator credential 4: The composition MUST NOT write reconciliation operator credential into a payload.
  ```
  WHY: an actor reference without credential material in hand is an identity the scan cannot attest under; storage and rotation are Credential management's business.
- **payload cap**
  Term payload cap: the byte ceiling [Record Action] step 1 checks the full constructed payload against. *Default:* none.
  ```
  payload cap 1: The deployment MUST set payload cap to the wired Event Log instance's own configured cap.
  payload cap 2: [Record Action] step 1 MUST measure the serialized envelope against payload cap.
  payload cap 3: [Record Action] step 1 MUST NOT measure the sum of the members' own lengths.
  payload cap 4: The deployment MUST alert on invalid-payload at [Record Action] step 3 as a deployment fault.
  ```
  Term serialized envelope: the byte length of Event Log's data field exactly as handed to `EventLog.append`, in the encoding the wired instance sizes it in, framing and field names included.

  WHY: the cap is per-instance configuration the wired instance may have changed from the atom's 64 KB default, so the composition can neither derive nor assume one. Summing the members under-counts by the serialization's structure, and under-counting is the direction that strands a committed attestation. Reaching invalid-payload at step 3 after step 1 passed means the two caps disagree.
- **reference length cap**
  Term reference length cap: a byte length, applied independently to action reference and actor reference at [Record Action] step 1. *Default:* 1 KB each.
  ```
  reference length cap 1: [Record Action] step 1 MUST apply reference length cap to action reference and to actor reference independently.
  reference length cap 2: reference length cap MUST NOT EXCEED reference headroom.
  reference length cap 3: A deployment MAY raise reference length cap above 1 kilobyte ONLY IF a genuine reference scheme EXCEEDS 1 kilobyte.
  reference length cap 4: IF reference length cap EQUALS blank THEN the instance MUST take 1 kilobyte.
  ```
  Term reference headroom: `payload_cap − attestation_id_width − the largest data the deployment intends to accept`.

  WHY: a ceiling, not a semantic choice: it exists so a caller cannot push the constructed payload past the cap through the reference fields alone. A deployment lowers it where it wants the rejection to arrive at the reference, and raises it only where a genuine scheme exceeds 1 KB.
- **attestation id width**
  Term attestation id width: the width of the attestation id the configured Actor Identity instance allocates. *Default:* none.
  ```
  attestation id width 1: The deployment MUST set attestation id width to the maximum width the wired Actor Identity instance allocates.
  attestation id width 2: [Record Action] step 1 MUST size the payload with attestation id width.
  ```
  WHY: Actor Identity declares the id opaque, host-allocated and of no fixed width. An under-declared width makes step 1's check optimistic and reopens the path where an oversized payload strands a committed attestation.
- **record action completion bound**
  Term record action completion bound: the longest a [Record Action] may take between its first committed write (step 2's attestation, stamped attestation instant at Actor Identity's seam) and its last (step 5's index writes). *Default:* none.
  ```
  record action completion bound 1: The deployment MUST set record action completion bound from the observed worst-case latency of [Record Action] steps 2 through 5 with headroom, constituent round-trips included.
  record action completion bound 2: The deployment MUST include in record action completion bound the call pause bound.
  ```
  WHY: a write issued inside the bound must also have landed inside it, and no constituent write carries a fence, so the bound is the only thing that makes a lease check sufficient: the pause between checking the lease and issuing the write is part of the latency the bound must cover (record action completion bound 2, purge completion bound 2). The bound does three jobs, each stated where it happens: the lower edge of the scan's second and third halves (record edge), the per-act lease length for a record action (Per-act critical section 9a), and the invocation's terminus (record action step 7.6).
- **purge completion bound**
  Term purge completion bound: the longest a [Purge Event] may take between taking the per-act critical section and step 3's outcome record, step 0 included. *Default:* none.
  ```
  purge completion bound 1: The deployment MUST set purge completion bound from the observed worst-case latency of [Purge Event] steps 0 through 3 with headroom, the erasure mechanism's round-trip and the wait of Concurrency 3b included.
  purge completion bound 2: The deployment MUST include in purge completion bound the call pause bound.
  ```
  WHY: the lower edge of the scan's first half (purge edge), the lease length for a cascade's critical section, and the cascade's terminus, on the record action's terms. The lease begins at taking the section, never after step 1 stamps purge instant, so a lease has run out before purge age reaches purge edge.
- **seal completion bound**
  Term seal completion bound: the longest a [Seal Now] may take between taking the sealing lock and step 5's coverage entry, the mechanism's round-trip included. *Default:* none.
  ```
  seal completion bound 1: The deployment MUST set seal completion bound from the observed worst-case latency of [Seal Now] steps 1 through 5 with headroom, the rebuild of seal now 13 and the clear of seal now 23 included.
  seal completion bound 2: The deployment MUST include in seal completion bound the call pause bound.
  ```
  WHY: the sealing lock is a lease of this length (Concurrency 1c), so a seal the holder issued inside the lease has landed when the lease has run out, and the next taker's rebuild sees every seal that will ever exist over the slice it is about to cut. The holder checks the lease before each write and issues none once it has expired (seal now 19), as a record action and a cascade do (Per-act critical section 9b); a holder that stalls before its seal and wakes after the next taker has sealed and covered writes nothing, and the next taker's rebuild finds nothing of the stalled holder's to cover.
- **call pause bound**
  Term call pause bound: the longest time from a holder's decision to issue one call — a lease take, a lease check, a write to a constituent, a delegation to the erasure mechanism, never a whole [Record Action] — to the moment the call has taken effect or failed. *Default:* none.
  ```
  call pause bound 1: The deployment MUST set call pause bound from the observed worst-case latency of a host or constituent call with headroom.
  call pause bound 2: The deployment MUST declare EVERY completion bound as exceeding twice call pause bound.
  ```
  WHY: the lease is the only fence, and no constituent write carries one, so the margin is spent in the composition's own seam: Term lease reads *expired* unless the host's remaining term exceeds twice this bound, the check's answer and the write being two calls, so a write issued on a live lease lands inside it; the sizing reading subtracts it, so a grant that lands up to this long after the reading ends no later than the bound the reading was counted from; the outlived test subtracts it, so a take issued on a passing test lands inside the bound. A deployment whose calls stall longer than the declared value breaches a premise External check 12 audits, not an arithmetic the page leaves open.
- **compensation closure latency**
  Term compensation closure latency: the deployment's disclosed bound on one whole closure landing, from the moment a scan run starts to the moment the closure's last record has landed, the run's enumeration before it reaches the act included. *Default:* none.
  ```
  compensation closure latency 1: The deployment MUST declare compensation closure latency as the bound on one whole closure.
  compensation closure latency 2: The deployment MUST include in compensation closure latency the call pause bound.
  compensation closure latency 3: The deployment MUST include in compensation closure latency the longest enumeration a run performs before it reaches an act.
  compensation closure latency 4: The deployment MUST include in compensation closure latency one record action completion bound for the probe of Invariant 1.10.
  ```
  Term whole closure: for the second and third halves, the `audit.reconciliation` intent, the compensating act and the `audit.compensation` record — three writes, each an attest-append-place across three stores or a retention placement; for the first half, a re-driven cascade, the erasure mechanism's round-trip included.

  WHY: declared rather than observed so that the start check can read it; the fourth term of the inequality.
- **clock offset allowance**
  Term clock offset allowance: the most the composition's seam clock and any constituent's seam clock may differ. *Default:* none.
  ```
  clock offset allowance 1: The deployment MUST set clock offset allowance from the deployment's clock discipline.
  clock offset allowance 2: The scan MUST widen EVERY comparison of now with a constituent-stamped time by clock offset allowance.
  clock offset allowance 3: The scan MUST NOT decide a write by a cross-seam comparison alone.
  clock offset allowance 4: A cross-seam comparison MUST exclude a record from the pass and nothing more.
  ```
  WHY: the scan reads now once per run at its own seam and compares it to attestation instant (Actor Identity), recording instant (Event Log) and purge instant (Retention Window), each written at another seam; every such comparison widens the completion bound by the allowance, and the write is decided by the half's own predicate read under the critical section.
- **Per-act critical section** — an instance capability requirement, not a knob: a per-key mutual exclusion the host supplies, keyed by an act's id — the attestation id [Record Action] step 2 returns for a record action, the event id for a cascade. *Default:* none.
  ```
  Per-act critical section 1: The host MUST supply the per-key critical section as a [Lease](../atoms/lease.md) keyed by the act's id.
  Per-act critical section 1a: The host MUST namespace a critical section's key by the act's kind.
  Per-act critical section 1b: The host MUST share the critical section across EVERY process serving the instance.
  Per-act critical section 1c: A holder MUST present a holder value minted fresh for EACH attempt.
  Per-act critical section 2: The host MUST release the critical section ONLY on the holder's release or at the lease's instant.
  Per-act critical section 2a: A holder that abandoned a call MUST NOT release the critical section BEFORE the lease's instant.
  Per-act critical section 2b: A holder MUST release the critical section on return WHEN the holder abandoned no call.
  Per-act critical section 3: The host MUST NOT release the critical section on a belief that the holder has died.
  Per-act critical section 4: The host MUST end the critical section at the lease's instant WHEN the holder has not returned.
  Per-act critical section 5: A leg that finds an act's critical section held MUST skip the act for the rest of the run.
  Per-act critical section 6: A leg MUST NOT block on a held critical section.
  Per-act critical section 7: IF no held critical section EXISTS THEN the invocation MUST NOT issue a later truth-bearing write.
  NOTE: watch condition negation — *not holding the critical section* is written as a minted term that no instance EXISTS of (Per-act critical section 7, Per-act critical section 8, Invariant 6.3).
  Per-act critical section 8: IF no held critical section EXISTS THEN the invocation MUST NOT land a later truth-bearing write.
  Per-act critical section 9: The host MUST hold a record action's and a cascade's critical section as a lease:
      Per-act critical section 9a: The host MUST set the lease to the act's completion bound.
      Per-act critical section 9b: IF lease EQUALS expired THEN the invocation MUST NOT issue a truth-bearing write.
      Per-act critical section 9c: An invocation whose truth-bearing writes have all landed MUST complete the invocation's index writes, MUST call [Seal Now] WHERE seal cadence EQUALS per-event, and MUST return success.
  Deleted: Per-act critical section 10. Lease Invariant 3.2 owns it.
  Per-act critical section 11: A writer without the critical section MUST NOT read a pre-check BEFORE re-taking the critical section.
  Per-act critical section 12: A writer MUST re-read the pre-check under the re-taken critical section.
Per-act critical section 13: The host MUST hold a scan leg's critical section as a lease:
    Per-act critical section 13a: The host MUST set a scan leg's lease to compensation closure latency less the time the run has spent before the take, measured at the scan's own seam, less call pause bound.
    Per-act critical section 13b: IF a leg's lease EQUALS expired THEN the leg MUST NOT issue a further write.
    Per-act critical section 13c: A leg whose lease EQUALS expired MUST skip the act for the rest of the run.
    Per-act critical section 13d: IF that remainder DOES NOT EXCEED the half's work bound THEN the leg MUST NOT take the critical section AND MUST skip the act for the rest of the run.
    Per-act critical section 13e: A skip under 13d or a start declined under 13f MUST surface a compliance alert as a deployment fault AND the deployment MUST re-declare compensation closure latency AND the instance MUST re-run Instance start 16, 18, 19 and 28.
    Per-act critical section 13f: A leg MUST NOT start a [Record Action] WHILE the lease's remaining term DOES NOT EXCEED record action completion bound plus twice call pause bound.
    Per-act critical section 13h: A [Record Action] a leg starts MUST complete its truth-bearing writes WITHIN record action completion bound, inside the leg's lease.
    Per-act critical section 13g: A leg that declines a start under 13f MUST skip the act for the rest of the run.
Per-act critical section 14: A [Purge Event] re-driven by the first half MUST NOT take a second critical section for an event id the first half holds.
Per-act critical section 15: A record action, a cascade and a scan leg MUST take the critical section by [Try Take](../atoms/lease.md).
Per-act critical section 15a: A hold placement MUST take the critical section by [Take](../atoms/lease.md), waiting no longer than the atom's arrival term.
Per-act critical section 15b: IF a hold placement's take answers unavailable OR no answer THEN the placement MUST NOT write AND MUST be reported to its caller as not placed.
Per-act critical section 16: IF a `take`, `try_take` or `remaining` on a lease this composition takes — the per-act critical section, the sealing lock, the serialization of Concurrency 3a — answers no answer THEN the holder MUST treat the lease as expired.
Per-act critical section 17: A holder MUST NOT re-issue, within its lease, a call that answered no answer.
  ```
  Term act's completion bound: record action completion bound for a record action; purge completion bound for a cascade.

  Term lease: live WHEN the host's remaining term EXCEEDS twice call pause bound — a check's answer and the write it guards are two calls; expired otherwise, a remaining that answers none or no answer included.

  Term abandoned call: a call the holder issued to any store or mechanism, constituent or not — the erasure mechanism and the Legal Hold store included — and stopped waiting for without an answer, whose write may still land inside the lease.

  Term no answer: a call that returns neither its answers nor a refusal within call pause bound.

  Term work bound: closure floor plus one measured enumeration for the second and third halves — the one enumeration under the section of Second half 17; purge completion bound for the first half.

  Term holder: the party the critical section is held by; a record action's invocation, a cascade, a hold placement, a scan half, or a [Seal Now]; its bound is record action completion bound for an invocation of [Record Action], purge completion bound for a cascade and for a hold placement, and compensation closure latency less the run's elapsed time at the take and call pause bound for a scan leg.

  Term held critical section: the act's critical section with the invocation as holder.

  Term later truth-bearing write: a truth-bearing write after the invocation's first write.

  Term truth-bearing write: a write to a constituent store — steps 2–4 of a record action, steps 1–3 of a cascade; the index writes of step 5 are not truth-bearing.

  Term pre-check: the read a writer makes under the critical section before writing — compensated attestations together with the binding set, reported beyond horizon, narrated, event to retention, the destruction record, a destroyed outcome in erasure outcomes, or the first half's predicate.

  WHY: one-writer-per-act rests on the critical section. A held critical section is a live invocation inside its bound, and the age edge already keeps a leg off work that young, so a leg skips rather than waits. A record action's key is the attestation id because no event id exists before step 3, and a critical section that began there would leave the append outside it. The lease therefore begins after the attestation commits, and a stall between the two is the pre-check's (record action step 3.5). A scan leg holds the section for the whole closure and for no longer than compensation closure latency, so a leg that overruns stops writing rather than racing the run that took the section after it (Per-act critical section 13). The critical section is a lease on every host because nothing in a distributed system observes a holder's death: a host that freed the section on a belief the holder had died would hand it to a second writer while the dead holder's last write was still in flight, and that write would land over the second writer's (Lease Invariant 3.1, Lease Invariant 3.2; the Lease atom's own edge case). Expiry is the terminus (record action step 7.6, purge event 7), and a write issued inside the bound lands inside it, which is why each bound includes the pause between a lease check and its write (record action completion bound 2, purge completion bound 2, compensation closure latency 2); the premise protects a second writer only if the lease stands until the instant, so a holder that abandoned a call, to a constituent, to the erasure mechanism or to the Legal Hold store alike, keeps the section to expiry and releases nothing on return (Per-act critical section 2a, Per-act critical section 2b), and the delegation of step 3 or a hold placement's own write cannot land after the section has passed to the other: released at the return, the section would hand the act to the next run while the abandoned placement was still in flight, the next run would read a miss and place, and the abandoned write would land too (Invariant 2.4a), and the same for a seal over one slice (Concurrency 1e, Invariant 3.1), which `audit-trail-abandon.tla` reaches and its twin rejects. A constituent call the host aborts is the host's matter: the atoms' storage-failure answers are definitive, and the premise above covers a write the host abandons, so an append that lands after its step told the caller *orphan* finds its attestation bound and the scan never compensates it, and the caller's retry records a second attestation and a second event, two honest records of two attempts (Actor Identity Identity 9). The same holds at [Purge Event] step 1: a `purge` the host abandons may still turn the retention to *Purged* after the step landed cascade-failure(step-1), and the first half finds a Purged retention with no destruction record and re-drives it (First half 3).

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

WHY:
Byte-identity is what makes Invariant 1's action reference-match check mechanical; Actor Identity applies the same non-empty minimum at attest, and validating here first makes the rejection clean rather than post-attestation. The namespace is reserved because two composition-owned surfaces read inside payloads written under it — compensated attestations' rebuild and, through it, Invariant 1's closure — and a caller able to write under it could close a finding the composition never compensated; the reservation makes those records evidence rather than assertion. The one payload the composition reads inside is one it wrote itself under a reference it owns (Primitive policy 20), so a caller's data stays opaque throughout, with the selector seam as the named exception (Primitive policy 17). credential never enters the payload, so it cannot contribute to the cap check. Empty data is Event Log's rule — rejecting meaningless events is the composing pattern's job — and a richer payload schema is a Schema Evolution pattern *(forthcoming)*. event id carries no ordering (Event Log's Identity model), which is why coverage ranges over sequence number and an id-addressed read goes through event to sequence. An empty presentation surfaces from Tamper Evidence as `failed-verification(seal-record-set-mismatch)`, never as the composition's own not-known; a layer that quietly canonicalized the presentation would manufacture agreement the seal never certified. Deployments wanting normalization wire it at the calling layer.

### Action wiring

One *record* action wraps all four constituents; *seal*, *read*, *verify* and *purge* actions run over the composed surface; the consolidated per-event join is [Read Record]. Each step names every rejection its constituent call can return and where the rejection lands at this composition's boundary; the enumeration is exhaustive, because silent rejection-code drift is a Pass 1 reference-graph finding.

```
Action wiring 1: The composition MUST pass a query by sequence-number range through to EventLog.read unchanged.
Action wiring 2: The composition MUST pass a query by wall-time range through to EventLog.read unchanged.
Action wiring 3: The composition MUST NOT serve a query by payload field.
Action wiring 4: A deployment needing a query by payload field MUST compose Reverse Index over the audit log and join the results through [Read Record] one event id at a time.
```

WHY:
Both range shapes are declared query shapes on Event Log's read. Every event referencing action X, every event by actor Y, every event carrying a business id inside data — Event Log's Non-goal 8 routes these to a reverse-index pattern, and this composition does not absorb it. The one payload-field lookup this composition owns — event id to sequence number — it owns because it maintains event to sequence for exactly that purpose.

---

#### Record Action contract

```
record_action(action_ref, actor_ref, credential, data)
  answers event_id
  refuses invalid-credential | invalid-request(step) | recording-failure(step)
```

A refusal at step-3 or step-4 carries the committed ids, so a caller can read the partial state back rather than search for it: the attestation id from step-3 on, and the event id at step-4 (record action step 7.15, 7.16).

Validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal.

```
record action 1: The recording-failure arm MUST carry the step that refused.
```

WHY: a bare token would satisfy the projection while defeating the three surfaces that read the step off the outcome — step 7's operator diagnosis, Invariant 1's surfaced-orphan requirement, and the rejection walkthrough.

Steps:

1. **Validate the primitives at this layer, before any constituent is called.**
   ```
   record action step 1.1: [Record Action] step 1 MUST validate action reference and actor reference per Primitive policy 1 through 5 and Primitive policy 8.
   record action step 1.2: [Record Action] step 1 MUST size the full constructed payload per Primitive policy 21 and Primitive policy 22.
   record action step 1.3: A step-1 refusal MUST record nothing.
   record action step 1.4: WHEN actor reference EQUALS reconciliation operator:
       record action step 1.4a: [Record Action] step 1 MUST land invalid-request(step-1) for an audit.compensation payload carrying no subject-kind discriminator.
       record action step 1.4b: [Record Action] step 1 MUST land invalid-request(step-1) for an audit.compensation payload carrying no id for the subject.
   record action step 1.5: [Record Action] step 1 MUST NOT validate the shape of a payload written outside the reserved namespace.
   ```
   Term subject-kind discriminator: the payload field subject = attestation | event; with subject set to attestation the payload carries the orphan's attestation id, with subject set to event the event id whose retention was placed.

   WHY: the size check sits ahead of step 2 so an oversized payload can never strand a committed, immutable attestation. The namespace check has an external side — any call whose actor reference is not the operator's, there being no other marker of origin — and an internal side, record action step 1.4's payload requirement; a caller supplying the operator's actor reference without the credential passes here and is refused at step 2 with nothing recorded. This is the one place the composition validates a payload's shape, and only of payloads it wrote itself.
2. **Attest.**
   ```
   record action step 2.1: [Record Action] step 2 MUST call ActorIdentity.attest(action reference, actor reference, credential), answering attestation id.
   record action step 2.2: [Record Action] step 2 MUST pass invalid-credential through unchanged.
   record action step 2.3: [Record Action] step 2 MUST land invalid-request as invalid-request(step-2).
   record action step 2.4: [Record Action] step 2 MUST land storage-failure as [Recording Failure].
   record action step 2.5: A step-2 refusal MUST record nothing further.
   record action step 2.6: [Record Action] MUST take the per-act critical section on the attestation id step 2 returned.
   record action step 2.7: [Record Action] MUST hold the critical section through step 5.
   record action step 2.8: [Record Action] MUST release the critical section on return, subject to Per-act critical section 2a.
   record action step 2.9: IF the critical section is held by another holder THEN [Record Action] MUST NOT append.
   record action step 2.10: IF the invocation has outlived record action completion bound at step 2.6 THEN [Record Action] MUST NOT take the critical section.
   record action step 2.13: IF the attest call answers no answer THEN [Record Action] MUST land recording-failure(step-2).
   record action step 2.11: IF the invocation has outlived record action completion bound at step 2.6 THEN [Record Action] MUST NOT append.
   record action step 2.12: [Record Action] MUST read now at its own seam BEFORE calling ActorIdentity.attest, and the outlived test of step 2.10 and step 2.11 MUST measure from that reading.
   ```
   WHY: in all three refusal arms no attestation exists — Actor Identity's storage-failure guarantees no partial record; a call the host abandons and that lands anyway stands as an orphan the second half closes. The key is the act's own, minted at its first write.
3. **Append.**
   ```
   record action step 3.1: [Record Action] step 3 MUST call EventLog.append with the full constructed payload, answering event id.
   record action step 3.2: The composition MUST NOT supply recording instant.
   record action step 3.3: [Record Action] step 3 MUST land storage-failure as [Recording Failure].
   record action step 3.4: [Record Action] step 3 MUST land invalid-payload as invalid-request(step-3).
   record action step 3.5: [Record Action] step 3 MUST NOT append BEFORE reading compensated attestations under the held critical section.
   record action step 3.6: IF the attestation id IS IN compensated attestations THEN [Record Action] step 3 MUST NOT append.
   record action step 3.7: IF the append answers no answer THEN [Record Action] step 3 MUST land recording-failure(step-3).
   ```
   WHY: Event Log stamps recording instant at its own seam from the host-injected clock, and that stamp is the audit event's timestamp wherever it is read back; a business event-time lives inside the opaque data. invalid-payload is reachable — data is caller-supplied and Event Log enforces a cap — which is why step 1 sizes first; reaching the arm after step 1 passed means payload cap and the wired instance's cap disagree, a deployment fault (payload cap 4), not a caller rejection.
4. **Place under retention.**
   ```
   record action step 4.1: [Record Action] step 4 MUST NOT place a retention BEFORE re-reading event to retention for the event id under the critical section.
   record action step 4.2: IF a retention for the event id EXISTS THEN [Record Action] step 4 MUST adopt the retention as landed and continue to step 5.
   record action step 4.3: [Record Action] step 4 MUST call RetentionWindow.place_under_retention(event id, resolved policy) with record reference set to event id, answering retention id.
   record action step 4.4: IF lease EQUALS expired THEN [Record Action] step 4 MUST NOT place.
   record action step 4.5: [Record Action] step 4 MUST land invalid-request as invalid-request(step-4).
   record action step 4.6: [Record Action] step 4 MUST land invalid-policy and policy-not-found as invalid-request(step-4).
   record action step 4.7: The deployment MUST alert on invalid-policy and policy-not-found as a deployment fault.
   record action step 4.8: [Record Action] step 4 MUST land storage-failure as [Recording Failure].
   record action step 4.9: IF the placement answers no answer THEN [Record Action] step 4 MUST land recording-failure(step-4).
   ```
   WHY: the third half takes the same critical section — on the event's payload attestation id — before it pre-checks event to retention and places, and examines no event younger than record edge, so this placement and the leg's are never both made for one event (Concurrency 6, Third half 4). Where the lease has expired before this step issues, the event is the third half's from here on and a later placement is the leg's. The policy reference came from Configuration, not the caller, so invalid-policy and policy-not-found are deployment faults surfaced on the caller's arm.
5. **Record the indexes.**
   ```
   record action step 5.1: [Record Action] step 5 MUST record event to attestation, event to retention and event to sequence for the event.
   record action step 5.2: [Record Action] step 5 MUST take sequence number from the read-back.
   record action step 5.3: The read-back MUST run from the high-water mark to the open end.
   record action step 5.4: The read-back MUST match the returned event id by equality.
   record action step 5.5: IF the read-back returns no event carrying the event id THEN [Record Action] step 5 MUST fall back to the rebuild of event to sequence.
   record action step 5.6: [Record Action] step 5 MUST NOT guess a sequence number.
   record action step 5.7: An implementation whose append result surfaces sequence number MAY take the value from the append result and skip the read-back.
   record action step 5.8: The composition MUST NOT depend on the append result surfacing sequence number.
   record action step 5.9: The composition MUST treat a step-5 failure as a rebuild trigger.
   record action step 5.10: A step-5 failure MUST NOT land [Recording Failure].
   ```
   Term read-back: the open-upper-bound read over the new unsealed tail through `EventLog.read`.

   Term high-water mark: the greater of sealed through and the highest sequence number this instance has itself recorded into event to sequence.

   WHY: concurrent record actions interleave, so the event may sit behind several others by the time the read issues; the open upper bound keeps that from being a miss, and a stale mark or a lagging replica falls back to the total rebuild rather than a wrong number. The read-back uses only Event Log's declared Q surface; no Event Log invariant obliges an instance to surface the value at the append seam.
6. **Seal under per-event cadence.**
   ```
   record action step 6.1: IF seal cadence EQUALS per-event THEN [Record Action] step 6 MUST seal through [Seal Now].
   record action step 6.2: IF seal cadence DOES NOT EQUAL per-event THEN [Record Action] step 6 MUST defer sealing to the next cadence firing.
   record action step 6.3: A cadence firing MUST seal the slice.
   record action step 6.4: A seal failure at step 6 MUST NOT reject [Record Action].
   record action step 6.5: The deployment MUST alert on a step-6 seal failure other than [Nothing To Seal] with the cause.
   record action step 6.6: The next cadence firing MUST retry the seal.
   ```
   WHY: the firing seals the unsealed tail it finds — typically the singleton range holding the new event, wider whenever a prior firing's seal failed — not the event that triggered it. The load-bearing writes have committed, the event remains in the unsealed tail Invariant 3 already states the coverage claim modulo, and rejecting the call would misdescribe a record that exists and is attributed.
7. **Return.**
   ```
   record action step 7.1: [Record Action] step 7 MUST return event id.
   record action step 7.2: IF step-3 storage failure EXISTS THEN [Record Action] MUST return recording-failure(step-3).
   NOTE: watch event versus state — *step 3 refusing after step 2 committed* is an event, written as a minted term's EXISTS (record action step 7.2, record action step 7.3); *[Seal Now] rejects* is written as a bare condition (seal now 9 through 11, purge event step 0.4).
   record action step 7.3: IF step-4 storage failure EXISTS THEN [Record Action] MUST return recording-failure(step-4).
   record action step 7.4: A recording-failure outcome MUST surface the partial state the invocation left.
   record action step 7.17: A caller other than the scan MUST NOT retry [Record Action] on a recording-failure(step-4) outcome.
   record action step 7.15: A recording-failure(step-3) outcome and an invalid-request(step-3) refusal MUST carry the step-2 attestation id.
   record action step 7.16: A recording-failure(step-4) outcome and an invalid-request(step-4) refusal MUST carry the step-2 attestation id and the step-3 event id.
   record action step 7.5: [Record Action] MUST NOT land a non-storage refusal of steps 3 through 4 as [Recording Failure].
   record action step 7.6: WHEN mid-record expiry EXISTS:
       record action step 7.6a: [Record Action] MUST NOT issue a further constituent write.
       record action step 7.6b: [Record Action] MUST return recording-failure(step) naming the first step not completed.
       record action step 7.6c: [Record Action] MUST release the critical section, subject to Per-act critical section 2a.
   record action step 7.7: An invocation past step 4 at the bound MUST complete step 5 and return event id.
   record action step 7.8: The invocation MUST NOT write a compensation for the partial state the invocation left.
   record action step 7.9: An invalid-request refusal MUST carry the step that landed it: step-1, step-2, step-3 or step-4.
   record action step 7.10: An invalid-request(step-1) or invalid-request(step-2) refusal MUST leave nothing committed.
   record action step 7.11: An invalid-request(step-3) refusal MUST leave the step-2 attestation committed, and an invalid-request(step-4) refusal MUST leave the step-2 attestation and the step-3 event committed.
   record action step 7.12: An invalid-request(step-3) or invalid-request(step-4) refusal MUST surface the partial state the invocation left.
   record action step 7.13: A caller other than the scan MUST NOT retry [Record Action] on an invalid-request(step-3) or invalid-request(step-4) refusal.
   record action step 7.14: IF storage-failure EXISTS at step 2 THEN [Record Action] MUST return recording-failure(step-2).
   ```
   Term step-3 storage failure: `EventLog.append` answering storage-failure with step 2's attestation committed.

   Term step-4 storage failure: `RetentionWindow.place_under_retention` answering storage-failure with step 3's append committed.

   Term mid-record expiry: the lease expiring while the invocation is between step 2 and step 4 inclusive, no store having refused; also record action step 2.9, record action step 2.11 or record action step 3.6 refusing the append, or the take at step 2.6 answering no answer.

   Term outlived: the invocation's own reading of now, taken before step 2.1's call, older than record action completion bound less call pause bound at the take; two readings at one seam, so no clock offset allowance enters, and the reading precedes the attestation instant so the test never reads the age low.

   Term non-storage refusal: invalid-payload at step 3; invalid-request, invalid-policy or policy-not-found at step 4.

   WHY: step 3 failing after step 2 leaves an orphan attestation, closed by Invariant 1's liveness arm and found by the binding-set half; step 4 failing after step 3 leaves an unretained event, closed by Invariant 2's arm and found by the third half. The two are not interchangeable, and which one the operator is looking at is read off the step. record action step 7.5's refusals leave the same partial state but are input or deployment faults, and collapsing them into recording-failure would misname the cause; they land invalid-request carrying the step, because one bare token landing at steps 1 and 2 with nothing committed and at steps 3 and 4 after the attestation committed would tell a caller the act can be retried when a retry commits a second attestation (record action step 7.9 through 7.13). record action step 7.6b names step-3 or step-4, never `step-5`; a later success is the leg's.

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
seal now 2: [Seal Now] MUST NOT read next sequence number.
seal now 3: IF the open-upper-bound read returns no event THEN [Seal Now] MUST land [Nothing To Seal].
seal now 4: [Seal Now] MUST call TamperEvidence.seal(slice reference, mechanism credential) over the slice.
seal now 5: [Seal Now] MUST record the seal coverage entry for evidence id as the slice and advance sealed through to the tail position.
seal now 6: [Seal Now] MUST land mechanism-failure(reason) as [Mechanism Failure] carrying the reason unchanged.
seal now 7: [Seal Now] MUST pass invalid-request through unchanged.
seal now 8: [Seal Now] MUST land storage-failure as [Recording Failure].
seal now 9: IF [Seal Now] rejects THEN sealed through MUST NOT advance.
seal now 10: IF [Seal Now] rejects THEN [Seal Now] MUST NOT write a seal coverage entry.
seal now 11: IF [Seal Now] rejects THEN the next cadence firing MUST recompute the slice and seal what is not covered.
seal now 12: The composition MUST NOT expose a re-sealing surface.
seal now 13: IF the sealing lock's uncovered mark IS set OR IS unknown OR the ranges index IS absent at the take THEN [Seal Now] MUST rebuild the ranges of seal coverage from the seal store BEFORE reading sealed through.
seal now 14: IF the coverage write at step 5 fails after step 4 returned THEN [Seal Now] MUST land storage-failure as [Recording Failure].
seal now 15: [Seal Now] MUST set the sealing lock's uncovered mark BEFORE step 4.
seal now 16: [Seal Now] MUST clear the uncovered mark ONLY AFTER step 5's coverage entry has landed, OR step 4 has answered a rejection that wrote no evidence, OR the rebuild of seal now 13 has completed.
seal now 17: [Seal Now] MUST read sealed through from the seal coverage ranges under the sealing lock.
seal now 18: [Seal Now] MUST NOT read sealed through from a process-local cache.
seal now 19: IF the sealing lock's lease EQUALS expired THEN [Seal Now] MUST NOT issue a further write.
seal now 20: IF the sealing lock's lease EQUALS expired OR the take answers unavailable THEN [Seal Now] MUST land [Recording Failure].
seal now 21: [Seal Now] MUST release the sealing lock on return, subject to Concurrency 1e.
seal now 22: [Seal Now] MUST set the uncovered mark carrying its own holder value.
seal now 23: [Seal Now] MUST clear the uncovered mark ONLY by a compare against the holder value the mark carried when it last read the mark under its live lease — its own after step 15, the value it found when it rebuilt — issued WHILE its lease EQUALS live.
seal now 24: IF the seal call or the coverage write answers no answer THEN [Seal Now] MUST land [Recording Failure] AND MUST leave the uncovered mark set.
```

Term slice: the sequence-number range from `sealed_through + 1` to the tail position, inclusive.

Term tail position: the highest sequence number the open-upper-bound read beginning at `sealed_through + 1` returns; an empty result of that read means the unsealed tail is empty.

WHY:
The obvious alternative, *the log's next sequence number minus one*, reads an internal state field the atom exposes on no declared surface: it counts allocations rather than successful appends (Event Log's storage-failure gap), and Event Log's Invariant 5 was re-scoped off it for that reason. The three failure arms name three different things an operator has to fix. `mechanism-failure(reason)` carries two worlds on one arm — transient outage (signing hardware down, TSA unreachable, HSM session lost), which the next firing may clear, and standing misconfiguration (keying material that fails the running mechanism's preconditions), which every firing reproduces until Configuration changes — and the reason is what tells them apart. invalid-request is reserved by that atom for a blank record-set reference or a credential absent entirely; neither comes from a caller, so the arm means a defect in the composition's own construction or a plumbing fault, standing rather than transient, a page for a human. recording-failure means the mechanism computed a proof and the seal store refused to persist it, with the evidence either not persisted or persisted without its coverage entry, which the next rebuild regenerates (seal now 13). Under every arm the events stay in the unsealed tail and unsealed tail mode governs what [Verify Record] says about them; an unsealed tail that stops draining is an operational alarm. Re-sealing a partly-purged seal's survivors and rotating a seal onto a fresh mechanism belong to Seal Lifecycle *(forthcoming)*, with the supersession bookkeeping both require.

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
read record 5: IF a constituent read answers no answer THEN [Read Record] MUST answer no answer AND MUST NOT answer not-known.
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
   WHY: invalid-query is unreachable by construction — the composition builds the query from its own index over a value Event Log itself assigned — so an implementation that observes it has a defective index, a deployment fault to alert on; that is why read_record carries a not-known arm and no rejection arm.
3. **Decide not-known.**
   ```
   read record step 3.1: IF no retention record EXISTS AND no log entry EXISTS THEN [Read Record] step 3 MUST land not-known.
   read record step 3.2: [Read Record] MUST NOT land not-known for an event id with a log entry.
   read record step 3.3: The deployment MUST alert on a retention record whose event id resolves to no log entry as a deployment fault.
   ```
   WHY: the conjunction is the definition of a fabricated id — no constituent has heard of it. The fourth cell of the two-by-two, a retention over a log-absent id, is unreachable by construction: step 4 places a retention only after step 3's append committed, a committed event never leaves the log, and the cascade transitions a retention without removing the entry. [Verify Record] step 2 and [Purge Event]'s not-known arm read the same two-by-two.
4. **Assemble the [Audit Record].**
   ```
   read record step 4.1: [Read Record] step 4 MUST assemble and return the audit record.
   read record step 4.2: [Read Record] step 4 MUST report coverage status per event.
   read record step 4.3: [Read Record] step 4 MUST return the covering seal's full range.
   read record step 4.4: WHEN retention state EQUALS Purged:
       read record step 4.4a: [Read Record] step 4 MUST read action reference, actor reference and attestation instant from the attestation store through the pair.
       read record step 4.4b: [Read Record] step 4 MUST NOT read the who, the what and the when from the event payload.
       read record step 4.4c: [Read Record] step 4 MUST return no data.
       read record step 4.4d: IF no pair EXISTS THEN [Read Record] step 4 MUST return the audit record with attribution not-recoverable, the retention record in Purged with purge instant, the coverage status, sequence number and recording instant.
       read record step 4.4e: IF no pair EXISTS THEN [Read Record] step 4 MUST NOT land not-known.
   read record step 4.5: IF retention state EQUALS Retained AND the event's data IS unreadable THEN [Read Record] step 4 MUST re-read the retention BEFORE returning.
   read record step 4.6: IF the retention state EQUALS Purged at the re-read THEN [Read Record] step 4 MUST answer as for step 4.4.
   ```
   Term audit record: the join of the event's action reference, actor reference, sequence number, recording instant and data where the content is still present; the attestation id from event to attestation; the retention record's retention id, policy reference, state, retention deadline, purge deadline and purge instant where set; and the coverage status.

   Term coverage status: covered (the covering evidence id with the seal's full sequence-number range, sealing instant, and anchoring instant where the mechanism anchors) | unsealed tail (sequence number EXCEEDS sealed through) | records-purged (the event's own sequence number is a member of the covering seal's purged events) | partially purged (the event's sequence number is not a member while another member's is).

   Term pair: the destruction record's `(event_id, attestation_id)`, captured at [Purge Event] step 2.

   Term who / what / when: the attestation's actor reference, action reference and attestation instant.

   WHY: returning the range is what makes [Verify Record]'s asymmetry usable (Invariant 7): the composition tells the caller what to present, and presenting exactly that is the whole of the caller's obligation. partially purged is the honest signal that [Verify Record] answers `unverifiable(partially-purged-coverage)`, standing, since there is no re-sealing surface. For a purged event the surviving carrier is the pair, and Actor Identity's State 3 — each attestation carries its own attestation id among its fields — make an enumeration re-keyed on that id an id-addressed lookup built from nothing the atom does not declare, the mirror of event to sequence's argument, landing differently because Event Log's read takes a query. read record step 4.4d is the conformance failure Check 7.6 names for an event that is not held, reported on the record: lawful destruction is never reported as absence; a held event, whose cascade a hold left open and whose pair may not have landed, answers as purged on both surfaces (Invariant 8.2b) because the surfaces read the retention record, not the content, and the hold preserves the content in the stores, where reading it is the Legal Hold deployment's own surface. For a live event both sources carry the same action reference and actor reference, and reading either is correct.
5. **Orphan window.**
   ```
   read record step 5.1: IF a log entry EXISTS AND no retention record EXISTS THEN [Read Record] step 5 MUST return the audit record with retention status unresolved (compensation window).
   read record step 5.2: [Read Record] step 5 MUST NOT fabricate a retention.
   ```
   WHY: the event is real and the log proves it; the retention side has not landed yet and reconciliation owes it. The status is a surfaced compliance finding, not a steady state (Invariant 8).
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
verify record 2: The composition MUST NOT fold the qualifier into a reason.
verify record 3: The composition MUST NOT promote the qualifier to an outcome.
verify record 4: not-known MUST NOT carry the qualifier.
verify record 5: IF the outcome is failed-verification or unverifiable THEN [Verify Record] MUST re-read the retention through event to retention BEFORE returning.
verify record 6: IF the retention state EQUALS Purged at the re-read THEN [Verify Record] MUST land failed-verification(purged).
verify record 7: IF a constituent read answers no answer THEN [Verify Record] MUST answer no answer AND MUST NOT answer not-known AND MUST NOT answer unverifiable.
```

WHY: step 2 can establish that the event is inside Invariant 2's compensation window, and that fact is orthogonal to every integrity finding the remaining steps produce, so all three combinations are reachable and meaningful — `verified (compensation-window)`, `failed-verification(seal-proof-invalid) (compensation-window)`, `unverifiable(attestation-registry-unavailable) (compensation-window)`. Folding it into a reason would accuse a record with nothing wrong with its integrity; promoting it would suppress the integrity answer the caller asked for. not-known presupposes no log entry, so it never carries the qualifier.

Steps:

1. **Retention state first.**
   ```
   verify record step 1.1: [Verify Record] step 1 MUST read the retention record through event to retention.
   verify record step 1.2: IF retention state EQUALS Purged THEN [Verify Record] step 1 MUST land failed-verification(purged).
   verify record step 1.3: [Verify Record] MUST NOT run step 3 for a purged event.
   ```
   WHY: under a shredding-class mechanism the log entry is still there, so not-known was never the risk; what the cascade destroys is the payload and the proof, and every downstream check is payload-dependent — step 3 would re-check a proof the cascade destroyed and could only answer a non-`verified` arm. Reading the retention first answers out of the record the composition still has, and keeps it from reporting its own lawful destruction as an attestation failure. The read is a check before the acts, and a cascade can shred the proof between it and step 3 or step 5, so the attestation would answer a non-`verified` arm for a record lawfully destroyed a moment ago: the re-read before returning a non-verified outcome closes it without a lock (verify record 5, verify record 6, Concurrency 10).
2. **Log presence.**
   ```
   verify record step 2.1: [Verify Record] step 2 MUST read the event per event to sequence 4 and event to sequence 5.
   verify record step 2.2: IF no retention record EXISTS AND no log entry EXISTS THEN [Verify Record] step 2 MUST land not-known.
   verify record step 2.3: IF a log entry EXISTS AND no retention record EXISTS THEN [Verify Record] MUST proceed to step 3 and carry the qualifier on the outcome.
   ```
   WHY: an event in the compensation window is verifiable but not yet retention-covered, and reporting the two facts separately is the honest form; [Read Record] step 5 surfaces the same finding as `unresolved (compensation window)`.
3. **Attestation.**
   ```
   verify record step 3.1: [Verify Record] step 3 MUST call ActorIdentity.verify on event to attestation's entry for the event id.
   verify record step 3.2: [Verify Record] step 3 MUST land a failed-verification(reason) with the reason prefixed attestation-.
   verify record step 3.3: [Verify Record] step 3 MUST route registry-unavailable to step 6.
   verify record step 3.4: [Verify Record] step 3 MUST land Actor Identity's not-known as failed-verification(attestation-not-known).
   verify record step 3.5: IF step 3 lands failed-verification THEN [Verify Record] MUST return the step-3 outcome.
   verify record step 3.6: IF step 3 lands failed-verification THEN [Verify Record] MUST NOT run steps 4, 5 and 6.
   verify record step 3.7: IF step 3 routes registry-unavailable THEN [Verify Record] MUST NOT run steps 4 and 5.
   verify record step 3.8: [Verify Record] MAY run steps 4 and 5 ONLY IF step 3 landed verified.
   ```
   WHY: registry-unavailable is a reason under Actor Identity's `failed-verification(...)` arm and is re-levelled, because *the registry was unreachable* is not a finding about the record; Actor Identity's not-known is an arm — the attestation id does not resolve — and the event exists, so it is a broken link inside a known record, never the composition's own not-known. A record whose attribution has failed gains nothing from a subordinate finding against its seal; where verification could not be performed at all, no integrity claim is made either way, which is what makes step 6's answer *unknown* rather than *bad*.
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

   WHY: Invariant 3 guarantees at most one covering seal. Under partly-purged coverage the record set cannot be re-presented, and nothing is known to be wrong with the event, so `failed-verification(seal-record-set-mismatch)` would be the composition manufacturing a finding out of its own lawful work; the answer stands for the rest of those events' retained lifetimes, and the remedy is Seal Lifecycle *(forthcoming)*. The lenient path reaches `verified` on the attestation check plus Event Log's per-event immutability, which is what the deployment declared.
5. **Seal.**
   ```
   verify record step 5.1: [Verify Record] step 5 MUST call TamperEvidence.verify(evidence id, original event payload).
   verify record step 5.2: [Verify Record] step 5 MUST land a failed-verification(reason) with the reason prefixed seal-.
   verify record step 5.3: [Verify Record] step 5 MUST route mechanism-verification-unavailable to step 6.
   verify record step 5.4: [Verify Record] step 5 MUST land Tamper Evidence's not-known as failed-verification(seal-not-known).
   ```
   WHY: the verifier presents what the covering seal commits to (Primitive policy 26): under per-event cadence typically this one event's payload; under interval-based or on-demand cadence the payloads of the seal's whole range, obtained through Event Log's range read over the range [Read Record] reported. An absent, short or wrong presentation surfaces as `failed-verification(seal-record-set-mismatch)` from Tamper Evidence.
6. **Availability arm.**
   ```
   verify record step 6.1: [Verify Record] step 6 MUST land unverifiable(attestation-registry-unavailable) for registry-unavailable.
   verify record step 6.2: [Verify Record] step 6 MUST land unverifiable(seal-mechanism-verification-unavailable) for mechanism-verification-unavailable.
   ```
   WHY: a transient outage is *verification could not be performed*, emphatically not *this record failed*; retrying when the surface returns is the correct response. Step 4's partially-purged-coverage is the third reason on this arm and the one that is not transient; all three share the arm because they are the same kind of answer.
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
purge eligible 7: IF Retention Window's declared read answers no answer THEN [Purge Eligible] MUST answer no answer AND MUST NOT answer an empty list.
```

WHY:
Eligibility is derived at read time and never stored (Retention Window Invariant 11), so the eligibility clock is that instance's injected now, one reading per call. The projection and the purge are two readings at two moments — Retention Window's Invariant 8 single-reading discipline is scoped within its own Purge action — and the gap is harmless because eligibility is monotone in now: an event on the list cannot become ineligible before the cascade reaches it, and the residual disagreement is the benign one Retention Window's *Clock semantics* edge case names. The composition's own now governs seal cadence and the scan's edges, nothing else. A pure projection over the retention store with no caller input has nothing to refuse. The list means *retention has elapsed*, which is true of a held record; a hold is refused at [Purge Event]'s gate, not filtered ahead of it.

---

#### Purge Event contract

```
purge_event(event_id)
  answers ok
  refuses not-known | not-eligible | retention-unresolved | cascade-failure(step) | under-legal-hold
```

For any event whose retention has elapsed, the composition coordinates a cascade across the four stores. The arms: not-known for an id no constituent knows; [Not Eligible] when Retention Window refuses because the period has not elapsed; [Retention Unresolved] when the id resolves to a log entry but to no retention record; [Cascade Failure] carrying the step; and, where a Legal Hold is composed, [Under Legal Hold].

```
purge event 1: IF no retention record EXISTS AND no log entry EXISTS THEN [Purge Event] MUST land not-known.
purge event 2: [Cascade Failure] MUST carry EXACTLY ONE OF seal, hold, step-1, step-2, step-3, in-flight.
purge event 3: WHEN cascade-failure EQUALS seal OR cascade-failure EQUALS hold OR cascade-failure EQUALS step-1:
    purge event 3a: The cascade MUST leave the retention in Retained, an abandoned step-1 call that lands within the lease excepted (Per-act critical section 2a).
    purge event 3b: The cascade MUST NOT write a destruction record or an erasure outcome.
    purge event 3c: [Purge Eligible] MUST re-offer the event WHILE the retention EQUALS Retained.
purge event 3d: WHEN cascade-failure EQUALS in-flight:
    purge event 3d1: The cascade MUST write nothing.
    purge event 3d2: The cascade MUST leave the retention as found.
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

Term Legal Hold: composed | absent — whether the deployment composes the [Legal Hold](../atoms/legal-hold.md) pattern over this instance.

Term hold: a Legal Hold preservation order whose hold state EQUALS active and whose record reference EQUALS the event id, read from the Legal Hold store instance wired to this instance.

Term mid-cascade expiry: the lease expiring after step 1 has committed and before step 3's outcome record has landed.

Term cascade-failure(step-3): a delegation not issued, an outcome not recorded, or a reported `destruction-failed(reason)` — three failures leaving one world, retention *Purged* over readable content.

WHY:
a step-0 read that answers no answer lands `seal`, step 0 being the seal step, and a step-0½ read lands `step-1`, the step before which nothing has changed, so the sweep re-offers either (purge event step 0.11, purge event step 0½.6); seal is named separately from step-1 because the surface that refused is the seal mechanism or seal store, and the remedy is [Seal Now]'s three-way diagnosis rather than a retention retry; under both, nothing changed anywhere and the ordinary sweep re-offers the event. step-2 and step-3 are the dangerous half: the record says the content was lawfully destroyed while the evidence is missing or the content is still readable, and the state is invisible to [Purge Eligible], whose projection is false for a *Purged* retention — so the sweep never re-offers it and the reconciliation scan is the retry trigger, at restart and on reconciliation cadence, the entry standing as a surfaced alert bounded by compensation window. Absorbing either into a bare ok would hide the gap this composition exists to make unhideable; collapsing the two would tell an operator to retry when the retry path is a scan, or to run a scan when a retry would do. † The hold arm is conditional because a composition that declared it unconditionally would promise a hold check it does not perform; [Legal Hold](../atoms/legal-hold.md) owns the gate and this composition names where it lands — a preservation order, so a partial cascade under a hold would be the exact destruction the order forbids.

Steps:

0. **Seal before purge.**
   ```
   purge event step 0.1: [Purge Event] step 0 MUST resolve event to sequence for the event id.
   purge event step 0.1a: IF purge event 1's condition EXISTS at step 0.1 THEN [Purge Event] MUST land not-known BEFORE step 0.2.
   purge event step 0.2: IF the event's sequence number EXCEEDS sealed through THEN [Purge Event] step 0 MUST invoke [Seal Now].
   purge event step 0.3: [Purge Event] MUST NOT run step 1 BEFORE the covering seal exists.
   purge event step 0.4: IF [Seal Now] rejects other than with [Nothing To Seal] THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.5: IF the event's sequence number DOES NOT EXCEED sealed through THEN [Purge Event] step 0 MUST NOT invoke [Seal Now].
   purge event step 0.6: [Purge Event] MUST take the per-act critical section keyed by event id BEFORE step 0.
   purge event step 0.7: IF another holder holds the critical section THEN [Purge Event] MUST land cascade-failure(in-flight).
   purge event step 0.8: IF [Seal Now] lands [Nothing To Seal] THEN [Purge Event] step 0 MUST re-resolve the covering seal and proceed ONLY IF one EXISTS.
   purge event step 0.10: IF the take at step 0.6 answers no answer THEN [Purge Event] MUST land cascade-failure(in-flight).
   purge event step 0.9: IF no covering seal EXISTS after [Nothing To Seal] THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.11: IF the read at step 0.1 answers no answer THEN [Purge Event] MUST land cascade-failure(seal) AND MUST NOT land not-known.
   ```
   WHY: step 2's destruction record lives on a covering seal coverage entry, and an event with no covering entry has nowhere to record that it was destroyed — the cascade would move the retention to *Purged* and then produce `cascade-failure(step-2)` by construction on every purge in the unsealed tail. Under per-event cadence the step is almost always a no-op, reachable only where the record-time seal failed and the unsealed tail has not drained.

   **Step 0½ — retention must be resolved before the cascade proper begins.**
   ```
   purge event step 0½.1: [Purge Event] MUST NOT run step 0½ BEFORE step 0.
   purge event step 0½.2: IF a log entry EXISTS AND no retention record EXISTS THEN [Purge Event] step 0½ MUST land retention-unresolved.
   purge event step 0½.3: A retention-unresolved refusal MUST run no cascade step.
   purge event step 0½.4: A retention-unresolved refusal MUST leave step 0's seal standing.
   purge event step 0½.5: The composition MUST NOT invent a retention in order to expire an event.
   purge event step 0½.6: IF the read of event to retention at step 0½ answers no answer THEN [Purge Event] step 0½ MUST land cascade-failure(step-1) AND MUST NOT land retention-unresolved AND MUST NOT land not-known.
   ```
   WHY: a half-step because it is a second precondition, not a store-touching step. `RetentionWindow.purge` takes a retention id and there is none; the remedy is the third half's placement, after which the event is purgeable, or not, on the same terms as every other. An event that step 0 sealed out of the unsealed tail is in a state the composition wanted regardless. The check sits after step 0 because step 0's resolution is what establishes that a log entry exists — the antecedent that distinguishes retention-unresolved from not-known.
1. **Purge the retention.**
   ```
   purge event step 1.1: [Purge Event] step 1 MUST call RetentionWindow.purge(retention id).
   purge event step 1.2: [Purge Event] step 1 MUST land retention-period-not-elapsed as [Not Eligible].
   purge event step 1.3: [Purge Event] step 1 MUST pass not-known through unchanged.
   purge event step 1.4: IF step 1 lands not-retained THEN the cascade MUST resume from step 2.
   purge event step 1.5: [Purge Event] step 1 MUST land storage-failure as cascade-failure(step-1).
   purge event step 1.6: IF the purge answers no answer THEN [Purge Event] step 1 MUST land cascade-failure(step-1).
   ```
   WHY: the one constituent with a purge surface, and even it deletes no record — purge is a state transition, the record survives in *Purged* with purge instant, and that surviving record is the evidence the destruction was lawful. purge event step 1.4 is what makes a re-driven or retried cascade idempotent.
2. **Write the destruction record, before anything is destroyed.**
   ```
   purge event step 2.1: [Purge Event] step 2 MUST write the destruction record in one durable write.
   purge event step 2.2: The destruction record MUST add the event's sequence number to the covering seal's purged events.
   purge event step 2.3: The destruction record MUST carry the pair, read from event to attestation with rebuild-on-miss.
   purge event step 2.4: [Purge Event] MUST NOT issue the delegation BEFORE the destruction record has landed.
   purge event step 2.5: A step-2 failure MUST land cascade-failure(step-2).
   purge event step 2.8: IF the destruction record's write answers no answer THEN [Purge Event] step 2 MUST land cascade-failure(step-2).
   purge event step 2.6: [Purge Event] step 2 MUST read the destruction record under the held critical section BEFORE writing.
   purge event step 2.7: IF a destruction record EXISTS THEN [Purge Event] step 2 MUST adopt the record as landed.
   ```
   WHY: the binding lives inside the payload and step 3 destroys the payload's recoverability, so a cascade that captured the pair after the delegation would read a binding that no longer exists; capturing it here keeps the traversal *purged event → the attestation destroyed with it* possible at all. Both facts are extraction-pending truth against Erasure Tombstone, and this write is the part of the cascade carrying a durability obligation (Durability 6). The seal record itself is retained indefinitely as evidence that the records existed and were sealed before they were destroyed.
3. **Delegate the destruction.**
   ```
   purge event step 3.1: [Purge Event] step 3 MUST delegate destruction to erasure mechanism.
   purge event step 3.2: The cascade MUST NOT destroy content.
   purge event step 3.3: The delegation MUST name the whole of Event Log's data field and the attestation's proof, and nothing else.
   purge event step 3.4: [Purge Event] step 3 MUST record the mechanism's outcome in erasure outcomes.
   purge event step 3.5: IF outcome EQUALS destruction-failed THEN [Purge Event] step 3 MUST land cascade-failure(step-3).
   purge event step 3.6: A delegation not issued MUST land cascade-failure(step-3).
   purge event step 3.7: An outcome not recorded MUST land cascade-failure(step-3).
   purge event step 3.8: The cascade MUST NOT record a destroyed outcome the mechanism did not report.
   purge event step 3.9: The composition MUST NOT repair a partly-purged seal.
   purge event step 3.10: A partly-purged seal MUST remain the one seal over the seal's range.
   purge event step 3.11: [Purge Event] step 3 MUST read erasure outcomes under the held critical section BEFORE issuing the delegation.
   purge event step 3.12: IF a destroyed outcome EXISTS THEN [Purge Event] step 3 MUST NOT issue the delegation.
   ```
   WHY: what is destroyed is exact, and the exactness is the point — the surviving fields stay readable, so the *who / what / when* outlives the purge, read through the pair from here on. In the execution contract's vocabulary this step is a mechanism-capability invocation (the section titled Substrate composition invocation in [`execution-contract.md`](../execution-contract.md)): the capability is declared, the consuming surface is composition-introduced, the invocation is logic-confinement-clean, and the construct carries a named exit — Erasure Tombstone *(forthcoming)*. Swallowing a negative outcome would produce the state Invariant 8 forecloses with the composition's own records agreeing; the scan re-drives a destruction-failed entry every cycle until destroyed lands, the loop whose terminus Ledger line 2026-08-30-d names. The survivors verify as `unverifiable(partially-purged-coverage)` from here on.
4. **What survives a completed cascade.**
   ```
   purge event step 4.1: A completed cascade MUST leave standing the retention record in Purged with purge instant, the seal record with the event's sequence number in purged events, the destruction record's pair, the destroyed outcome in erasure outcomes, and the attestation's surviving fields.
   purge event step 4.2: The delegation MUST cover the event and the attestation in one cascade under one retention id.
   ```
   Term completed cascade: a cascade whose step 3 recorded a destroyed outcome.

   WHY: the retention record proves the destruction was lawful; the seal record proves a record set existed and which members were destroyed; the pair is the traversal the payload can no longer supply; the outcome record proves the delegation completed, which is what the scan tests; the surviving fields are the *who / what / when*. Once Erasure Tombstone lands, the tombstone naming what was destroyed and under whose authority joins the set.

### Wiring decision

*The cascade-on-purge rule.*

The composition's load-bearing wiring decision: when an event's retention elapses, the composition first ensures the event is covered by a seal (purge event step 0.1 through 0.5), then purges the one record it is permitted to purge — the Retention Window record (purge event step 1.1) — writes a destruction record adding the event's sequence number to the covering seal's purged events set and capturing the event's `(event_id, attestation_id)` binding before it is destroyed (purge event step 2.1 through 2.4), and delegates destruction of Event Log's data field and the attestation's proof to the deployment's shredding-class erasure mechanism (purge event step 3.1 through 3.4). It coordinates the cascade and records the outcome; it destroys nothing itself (purge event step 3.2), disposes of no seal (Composes 16), and re-seals nothing (seal now 12).

WHY:
*Principle.* When a regulated record reaches the end of its lifetime, all four stores must reach a coherent end state together: no retained event without attribution or integrity coverage, and no destroyed event leaving a dangling attestation or a live content claim on a seal. Coordinating that across four independent stores is work no constituent can do — each knows only its own record — so it belongs at the composition layer, with the honest record of what the coordination achieved.

*Likely objection.* Why not have the composition delete the content directly? It knows which event, which attestation and which seal are involved, and a cascade that ends in a delegation looks like one that does not finish.

*Mechanism that resolves it.* Two of the four constituents forbid it in their own invariant text, and a composition that overrode them would be silently substituting weaker atoms. Event Log declares only append and read, holds Invariant 1 (append-only), and routes true deletion to a composing pattern in its *Erasure where law requires it* edge case. Actor Identity's Invariant 9 states that an attestation is never deleted by the atom, and its Composition note 4 gives an attestation's retention to the composing pattern. So the destruction surface is named where the atoms say it belongs — an Erasure Tombstone *(forthcoming)* composing pattern, or cryptographic shredding at the storage layer, declared per deployment — and this composition wires the coordination around it.

*Result.* Four constituent invariants hold verbatim over their instances — Event Log's 1 and 2, Actor Identity's 9 and 1 — which is what makes Invariant 5 a literal claim; a lawfully destroyed event still answers `failed-verification(purged)` from its *Purged* record, still leaves a seal whose purged events names it, and still distinguishes lawful destruction from a missing record (Invariant 8).

#### Boundary one — only shredding-class mechanisms conform

The class boundary's home; erasure mechanism 1 through 9, [Purge Event] step 3, Invariant 5 and the [Purge Event] term entry cite it.

```
Boundary one 1: [Purge Event] MUST NOT write the destruction record BEFORE step 1's transition has committed.
Boundary one 2: The composition MUST NOT condition RetentionWindow.purge's outcome on the erasure mechanism's answer.
Boundary one 3: The composition MUST record a divergence between a Purged retention and readable content.
Boundary one 4: The composition MUST surface a divergence as a compliance alert.
Boundary one 5: The composition MUST bound a divergence by compensation window.
Boundary one 6: The first half MUST re-drive a divergence on EVERY run.
```

Term divergence: a retention in *Purged* over content still readable — `cascade-failure(step-3)`; a destruction-failed outcome in erasure outcomes.

WHY:
A conforming mechanism destroys the key material under which the content was stored and leaves every stored field as written, which is why Event Log Invariant 2 and Actor Identity Invariant 1 — immutability claims over stored fields, neither claiming readability — survive the cascade verbatim; tombstone-by-mutation breaks exactly those two (erasure mechanism 2). Erasure Tombstone records destruction as a new write-once record and never mutates the record it describes. One constituent prescription is declined by name: Retention Window's *Divergence between the retention and the record* edge case (Record divergence 2) has purge return storage-failure when destruction cannot be confirmed. This composition cannot take it — the destruction record must be written after the transition and before the delegation (Boundary one 1, purge event step 2.4), and the destruction is performed by a mechanism `RetentionWindow.purge` has no view of — so the divergence is recorded, surfaced, bounded and re-driven rather than prevented (Boundary one 3 through 6), the trade that buys the durable pre-destruction record. The terminus of Boundary one 6's loop is the open question Ledger line 2026-08-30-d names.

#### Boundary two — the composition disposes of no seal and writes no replacement

```
Boundary two 1: EVERY seal MUST remain the only seal over the seal's range.
Boundary two 2: IF seal disposal EXISTS THEN the deployment MUST compose Erasure Tombstone for the seal-disposal surface and the coverage bookkeeping.
Boundary two 3: IF re-sealing EXISTS THEN the deployment MUST compose Seal Lifecycle.
Boundary two 4: The composition MUST NOT carry a which-seal-is-current fact.
```

Term seal disposal: a jurisdiction's requirement to dispose of a seal — a commitment over erased personal data treated as residual personal data.

Term re-sealing: a deployment's requirement to write a second seal over a range some seal covers — a partly-purged seal's survivors made verifiable again, or a seal rotated onto a sound mechanism ahead of a deprecation.

WHY:
A seal is a proof, not a copy, and its indefinite retention (retention policy 5) keeps Invariant 3 and Tamper Evidence's Invariant 9 unconditionally true: a seal that survives its records is the evidence that they existed. Tamper Evidence's *retention coupling* edge case suggests purging a seal over a destroyed record set; this composition takes the reading Tamper Evidence's Invariant 9 supports, and a jurisdiction that treats a commitment over erased data as residual data composes Erasure Tombstone, which then owns which events lose their cover. The cost of no replacement seal is named on the same terms: survivors answer `unverifiable(partially-purged-coverage)` for their retained lifetimes, and a seal cannot be rotated ahead of a deprecation — the remedy Tamper Evidence's Invariant 2 prescribes. Both need a *which seal is current* fact, new truth no constituent carries and no rebuild replays (Tamper Evidence's *Concurrent seals* edge case (Concurrent seal 2) takes no view on supersession), so absorbing it would hold unclassifiable truth for a concept not yet specified.

### Reconciliation

The scan is this composition's reconciliation leg: each finding closes within the compensation window (Reconciliation 4) and the scan writes the compensating records, so something awaits its output. It sat inside the wiring decision, under a label family of its own, until the heading standard gave the leg its address (council read 83).

#### The reconciliation scan — three halves

The composition's three liveness arms fail in three structurally different ways — a cascade that stopped partway, an attestation nothing points at, and an event nothing bounds — and each needs its own detector, predicate and compensating write. A scan that ran only the first two would carry the third state forever, because no other surface looks for it.

```
Reconciliation 1: The reconciliation scan MUST run a first half over Purged retentions, a second half over the attestation store, and a third half over the audit log.
Reconciliation 1b: A leg MUST take its critical section BEFORE it waits on the probe of Invariant 1.10.
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
Reconciliation 5: The scan MUST read now once per run at the scan's own seam, BEFORE the run's enumeration.
Reconciliation 5a: A leg MUST read now at its take, solely to size its lease under Per-act critical section 13a.
Reconciliation 6: The scan MUST NOT write BEFORE taking the per-act critical section for the act.
Reconciliation 7: EVERY half MUST decide a write by the half's own predicate, read under the critical section.
```

Term leg: one scan half's handling of one act, from its examination to its closure.

Term record edge: `record_action_completion_bound + clock_offset_allowance`.

Term purge edge: `purge_completion_bound + clock_offset_allowance`.

Term horizon: the lesser of the retention periods retention policy gives an `audit.compensation` event and an `audit.reconciliation` event.

Term purge age: `now − purged_at`.

Term attestation age: `now − attested_at`.

Term event age: `now − recorded_at`.

WHY:
The halves share a trigger (reconciliation cadence 1, reconciliation cadence 2), a surfacing discipline (Reconciliation 2, Reconciliation 3), a deadline measured from the finding's creation (compensation window 2, Reconciliation 4), and two edges. Below, each half examines nothing younger than its completion bound widened by the allowance, because each stamp was written at a constituent's seam and the scan's now is read once at its own (Reconciliation 5, clock offset allowance 2); the comparison only excludes a record from the pass (clock offset allowance 4). Above, the horizon is the point past which the compensation event a half would look for has been lawfully purged, and there the half reports rather than repairs.

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
First half 11: IF a hold over an open entry is released THEN the first half MUST count the entry's compensation window from the instant of the first run that reads no active hold over the event, AND MUST NOT count it from a release instant the Legal Hold store carries, which a caller may have supplied and backdated (Legal Hold Operation 39, Operation 41).
First half 12: The first half's upper edge MUST be the retention policy of the audit instance it reads, which retains the Purged retention, the seal record, the destruction record and the erasure outcome indefinitely.
```

WHY: a crash between the cascade's steps is reachable, and the state is invisible to [Purge Eligible], whose projection is false for a *Purged* retention — the retry can never be driven from the eligible list. A cascade still inside its bound is in flight, not half-completed (First half 2). Presence of an outcome record is not the test (First half 4): an entry carrying destruction-failed is a retention saying *lawfully destroyed* over readable content, and a predicate that accepted any outcome would close it on the evidence of its own failure. Two scan runs, or a run and a cascade short of its bound, never both drive one entry (First half 6, First half 7).

*Second half — the orphan-attestation predicate.*

```
Second half 1: The second half MUST build the binding set.
Second half 2: The second half MUST treat an attestation absent from the binding set as an orphan.
Second half 3: IF record edge EXCEEDS attestation age THEN the second half MUST NOT examine the attestation.
Second half 4: IF attestation age EXCEEDS horizon AND the orphan's attestation id IS NOT IN compensated attestations THEN the second half MUST report the orphan as beyond the horizon.
Second half 5: IF attestation age EXCEEDS horizon THEN the second half MUST NOT write a compensation.
Second half 6: A beyond-horizon report MUST carry subject set to attestation, the attestation id and disposition set to beyond-horizon, as an audit.reconciliation record.
Second half 7: The second half MUST NOT report BEFORE reading reported beyond horizon under the critical section.
Second half 8: The second half MUST NOT report an orphan whose attestation id is a member of reported beyond horizon.
Second half 9: The second half MUST NOT write a compensation BEFORE reading compensated attestations under the critical section keyed by the orphan's attestation id.
Second half 10: The second half MUST NOT write a compensation for a reconciled orphan.
Second half 11: The second half MUST hold the critical section through the compensating write.
Second half 12: A writer other than the scan MUST NOT write an orphan's compensation.
Second half 13: The second half MUST write EXACTLY ONE compensation per orphan, a duplicate of Durability 5 excepted.
Second half 16: The second half MUST NOT write a compensation BEFORE re-reading the binding set for the orphan's attestation id under the critical section.
Second half 17: The binding-set re-read of Second half 16, the marker reads of Second half 4 and Second half 9 and the narrated read of Compensation 10 MUST be served from ONE enumeration read under the critical section.
Second half 14: The second half MUST take an attestation id from an event payload the full enumeration reads WHATEVER the event's retention state.
Second half 15: The second half MUST read the destruction records AFTER the full enumeration.
```

Term binding set: the union of the attestation id values carried in every event payload the full enumeration reads, whatever the event's retention state, and the attestation id values in destruction records.

Term orphan: an attestation in the store whose attestation id is in neither enumeration of the binding set.

WHY: *an attestation with no event* is not a fact any single store holds, so the set needs both enumerations: the first alone would report every lawfully purged event's attestation as an orphan the day its payload was shredded, the second alone would see nothing but purges — Check 7's live/purged split read in the other direction. An attestation younger than record edge may be a [Record Action] between steps 2 and 3, and a compensation for it would be a false record the seal then protects (Second half 3). Past the horizon the compensation, had it been written, has been purged out of the rebuild, so the half reports once (Second half 4 through 7). The orphan is permanent, so without Second half 9 a scan would compensate it every cadence forever; the pair under the critical section is what makes it a decision rather than a race (Concurrency 9). The invocation writes no compensation (record action step 7.8), and a stalled invocation that wakes after the scan compensated its orphan finds the attestation id in compensated attestations under the critical section it takes at step 2.6, and appends nothing (record action step 3.5, record action step 3.6). Retention state is the wrong key for the first enumeration, and the order of the two reads matters (Second half 14, Second half 15): [Purge Event] step 1 turns the retention to *Purged* before step 2 writes the destruction record, and the payload stays readable until step 3's delegation, so an enumeration that took only events whose retention DOES NOT EQUAL `Purged` would hold the attestation of an event inside that window in neither enumeration and compensate a lawfully held attestation, a false record the seal then protects; and a scan that read the destruction records first could meet a cascade that completed between the two reads, the record landed after the first read and the payload shredded before the second. The destruction record always lands before the destruction (Boundary one 1, purge event step 2.4), so a payload unreadable at the first read has its record at the second. The age filter does not cover this: the attestation of an event purged years after it was recorded is long past record edge. Nor does it cover the ordinary race: a lease host's invocation may hold the section until its completion bound after the attest, so a leg can read the binding set, find the attestation absent, wait out the invocation's section, and then take it free, past the invocation's append; the pre-check of compensated attestations alone passes, so the leg re-reads the binding set under the section it now holds (Second half 16, Reconciliation 7).

*Third half — the unretained-event predicate.*

```
Third half 1: The third half MUST enumerate the audit log by the full enumeration.
Third half 2: The third half MUST test EVERY returned event against event to retention with rebuild-on-miss.
Third half 3: The third half MUST NOT conclude a missing retention BEFORE rebuilding event to retention.
Third half 4: IF record edge EXCEEDS event age THEN the third half MUST NOT examine the event.
Third half 5: The third half MUST take the critical section keyed by the event's payload attestation id for a true miss.
Third half 6: The third half MUST NOT place BEFORE re-reading event to retention under the critical section.
Third half 7: The third half MUST hold the critical section through the placement.
Third half 8: The third half MUST NOT place BEFORE the audit.reconciliation intent has landed.
Third half 9: The third half MUST NOT write the audit.compensation record BEFORE the placement has landed.
Third half 10: The audit.compensation record MUST carry subject set to event and the event id.
Third half 11: The scan MUST NOT retry a compensating [Record Action] refused with recording-failure within a run.
Third half 12: The third half MUST treat an owed narration as a repair to record.
Third half 13: The next run MUST NOT record an owed compensation BEFORE confirming under the critical section that the retention exists.
Third half 14: The third half MUST NOT treat an intent past the horizon as a finding.
Third half 15: The third half MUST place the retention under the policy resolved from the event's payload by the resolution [Record Action] step 4 uses.
Third half 16: IF the placement is refused with invalid-policy OR policy-not-found THEN the third half MUST NOT retry within the run.
Third half 17: The deployment MUST alert on invalid-policy and policy-not-found from the third half's placement as a deployment fault.
```

Term true miss: a miss of event to retention that survives the rebuild.

Term owed narration: an `audit.reconciliation` intent whose subject is set to event, carrying no disposition, older than record edge, inside the horizon, whose subject has no matching `audit.compensation` record — both read composition-side out of the full enumeration filtered on the two reserved references.

The compensating placement takes no policy of its own: the event is in the log with the action reference, actor reference and data a selector reads, so the third half resolves the policy exactly as step 4 would have (Third half 15, Primitive policy 17), and a knob that is a policy reference gives the same one. Retention Window starts the clock at placement, so an event the scan places late is retained for the retention period from the placement, over-retained by the scan's delay, which the compensation window bounds (Retention Window State 4).

WHY: the state step 4 leaves when it fails after step 3 is durable and invisible to every other surface — [Purge Eligible] enumerates retentions, the first half *Purged* retentions, the second half attestations, and an unretained event's attestation is perfectly bound. A scan that read a lost index entry as *no retention exists* would place a second retention over an event that already had one, which Retention Window's place_under_retention records as new (it answers a fresh retention id per call) and which falsifies Invariant 2's *exactly one* (Third half 3). Intent before act lets the trail show the repair was the scan's; placement before compensation keeps the compensation truthful (Third half 8, Third half 9). A crash between the two leaves the gap closed but unrecorded, and the intent record is its detector (Third half 12, Third half 13) — what can be delayed is the narration, never a false closure and never an unclosed gap. Check 2's retention side is this half run from outside.

*Where the compensation lands — the composition is its own event log.*

```
Compensation 1: The scan's second half and third half MUST record EVERY finding as an audit.reconciliation event through [Record Action].
Compensation 2: The scan MUST record one audit.reconciliation record per finding.
Compensation 3: The scan MUST NOT write a compensating act BEFORE the finding's audit.reconciliation record has landed.
Compensation 4: The scan MUST record EVERY compensating write as an audit.compensation event through [Record Action].
Compensation 5: The scan MUST supply actor reference set to reconciliation operator and credential set to reconciliation operator credential at EVERY reconciliation-path [Record Action].
Compensation 6: The composition MUST NOT grow a second store for the reconciliation history.
Compensation 7: The composition MUST NOT add an action for the reconciliation path.
Compensation 8: The composition MUST place a reconciliation-path event under retention policy like any other event.
Compensation 9: A finding's audit.reconciliation record MUST carry subject and the id the subject names.
Compensation 10: The scan MUST NOT record a finding's audit.reconciliation record BEFORE reading narrated under the critical section.
Compensation 11: IF the finding is narrated THEN the scan MUST NOT record a second audit.reconciliation record for the finding, EXCEPT the beyond-horizon report of Second half 6 over an orphan whose only record is its intent.
Compensation 12: The first half MUST NOT record an audit.reconciliation event.
Compensation 13: The scan MUST NOT retry within a run a reconciliation-path [Record Action] refused with invalid-request(step-3) or invalid-request(step-4).
Compensation 14: The deployment MUST alert on an invalid-request refusal of a reconciliation-path [Record Action] as a deployment fault.
Compensation 15: The scan MUST retry a finding whose reconciliation-path [Record Action] was refused with invalid-request or recording-failure on the NEXT run.
Compensation 16: The deployment MUST alert on a reconciliation-path recording-failure standing across two runs.
Compensation 17: IF a reconciliation-path [Record Action] is refused with invalid-credential THEN the scan MUST alert as a deployment fault AND MUST NOT retry within the run.
```

Term narrated: a finding whose subject and id an `audit.reconciliation` record live in the log names, read composition-side out of the full enumeration filtered on the reserved reference.

WHY:
The findings and the compensating writes are audit events — attested, sequenced, retention-governed and sealed like the events they are about — so *what did this system do about the gap it found?* has a first-class answer from the same traversal. One record per finding keeps any findings set inside payload cap. A repair can fail after its intent landed — the compensating write refused, the placement refused — and the next run meets the same finding; reading the intent first keeps it one record, and the repair proceeds under the intent already there (Compensation 3, Compensation 10, Compensation 11). The first half writes no intent: the destruction record [Purge Event] step 2 writes before anything is destroyed is the cascade's own durable intent, its re-drive adopts what landed, and an intent from the first half would read as an owed narration to the third half (Third half 12), which would write a compensation for a placement the scan never made (Compensation 12). An intent and its compensation pair by subject and id, not by invocation id: one record per finding (Compensation 2) leaves nothing else to pair. A refusal of invalid-request(step-3) or invalid-request(step-4) is a deployment fault that mints one orphan attestation per attempt, so the scan alerts, finishes the run, and retries the finding on the next run rather than inside this one (Compensation 13 through 15, Invariant 1.9, Invariant 1.10); a recording-failure past step 2 mints the same orphan per attempt, so it takes the same terminus, one attempt per finding per run, and the count of orphans a standing fault mints is at most one per run, alerted on at the second, because the run issues its first reconciliation-path record alone and starts no other after a refusal that left an orphan (Invariant 1.10 through 1.12): without that stop every refused attempt would mint an orphan the next run retries and fails the same way, and the population would double each run while the outage stands (Third half 11, Compensation 16). The reserved namespace (Primitive policy 8, Primitive policy 9) is the difference between a marker that is evidence of a compensation and one that is anybody's claim. The scan is an ordinary caller of [Record Action] (Compensation 5); `execution-contract.md` has a composition record a multi-step sequence by composing Event Log, never by growing a second store, and this composition *is* an Event Log composition (Compensation 6, Compensation 7).


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
Instance start 17: The instance MUST read closure sum's four terms at start.
Instance start 18: The instance MAY start ONLY IF compensation closure latency EXCEEDS closure floor plus call pause bound plus twice measured enumeration.
Instance start 19: The instance MAY start ONLY IF compensation closure latency EXCEEDS purge completion bound plus call pause bound plus measured enumeration.
Instance start 20: IF seal completion bound EQUALS blank THEN the instance MUST NOT start.
Instance start 21: The instance MUST resolve horizon at start from retention policy for an audit.compensation event AND for an audit.reconciliation event, and take the lesser.
Instance start 22: The instance MAY start ONLY IF horizon EXCEEDS compensation window.
Instance start 23: The instance MAY start ONLY IF purge completion bound EXCEEDS twice seal completion bound.
Instance start 24: IF call pause bound EQUALS blank THEN the instance MUST NOT start.
Instance start 25: The instance MAY start ONLY IF EVERY completion bound EXCEEDS twice call pause bound.
Instance start 26: IF no scan scheduler EXISTS THEN the instance MUST NOT start.
Instance start 27: IF no sealing lock EXISTS THEN the instance MUST NOT start.
Instance start 28: The instance MUST run one enumeration of the audit log followed by one read of the destruction records, one of the attestation store and one of the retention store at start.
Instance start 29: IF seal cadence EQUALS interval-based AND no cadence driver EXISTS THEN the instance MUST NOT start.
```

Term closure sum: `max(2 * record_action_completion_bound, purge_completion_bound) + 2 * clock_offset_allowance + 2 * (reconciliation_cadence + compensation_closure_latency)`.

Term completion bound: record action completion bound, purge completion bound and seal completion bound.

Term closure floor: `4 * record_action_completion_bound + 6 * call_pause_bound`, plus `6 * seal_completion_bound` WHERE seal cadence EQUALS per-event, each of the three [Record Action] calls on the closure — the probe's and the two nested — sealing at step 6 before it returns (Per-act critical section 9c), a seal priced at twice its bound as Instance start 23 prices it — the whole closure of the second and third halves is the placement and two [Record Action] calls, the intent and the compensation, with the probe's wait of Invariant 1.10 ahead of them, and each of the two [Record Action] starts of Per-act critical section 13f and the placement's live test carrying its two-call margin.

Term measured enumeration: the longest of one enumeration of the audit log followed by one read of the destruction records (Second half 15), one enumeration of the attestation store and one of the retention store, each run once at start (Instance start 28).

WHY:
Instance start 6 applies where reconciliation cadence 3 leaves the cadence unset — an events-only, per-event or on-demand seal cadence with no time arm. Instance start 16 is strict: equality lands the closure at the window's edge after a latency the check did not count, and a window the scan cannot close inside is not a tolerance but a standing violation declared in advance. The refusal is the same one every mis-set deployment-required knob gets.

---

## Composition-level invariants

These invariants emerge from the composition; none belongs to a single constituent atom. Each carries a *Rests on:* line naming the wiring that establishes it and the constituent invariants it stands on. Per the section titled Structural-relation invariant templates in [`spec-format.md`](../spec-format.md), the composition's three structural relations are: event ↔ attestation, one-to-one, mandatory on both sides at quiescence (Invariant 1, in the orphan-freedom template's safety-plus-liveness form); event ↔ retention, one-to-one, mandatory on both sides at quiescence, the retention governing the event's attestation jointly (Invariant 2); seal → events, one-to-many, optional on the event side while the event is in the unsealed tail and mandatory once sequence number ≤ sealed through (Invariant 3) — a composed Seal Lifecycle *(forthcoming)* would make it many-to-one and own the *which seal is current* bookkeeping that reading requires. The inverse directions are read through the derived indexes; a lost index entry is a rebuild trigger, never a relation violation.

```
Composition-level invariant 1: WHEN store outage EXISTS:
    Composition-level invariant 1a: The liveness arms of Invariants 1, 2 and 8 MUST suspend for the outage.
    Composition-level invariant 1b: EVERY outstanding finding MUST stay surfaced through the outage.
    Composition-level invariant 1c: A finding's compensation window MUST restart at the latest of the finding's creation, the latest end among the store outages that began BEFORE the window, as it then stood, elapsed, and, where a hold covered the finding, the instant of the first run that read no active hold over its event (First half 11).
    Composition-level invariant 1d: The deployment MUST record the start instant and the end instant of every store outage on its operational record.
```

Term store outage: a dependency whose calls answer no answer or storage-failure over an interval longer than call pause bound — a constituent store, the actor registry, the Legal Hold store, the erasure mechanism or the lease host.

Term compliance alert: a finding surfaced on the deployment's alerting surface, never silently carried.

Term quiescence: for an act, no [Record Action] in flight for it, its compensation window, restarted under Composition-level invariant 1c, elapsed, constituent stores reachable.

Term recorded through [Record Action]: the quantifier of Invariants 1, 2 and 8 — this composition declares exactly one way in, and an event written around it is not one these invariants cover (Non-goal 2).

WHY: reconciliation is itself a [Record Action] against the attestation, log and retention stores, and the pre-check reads the retention store, so a store that cannot be reached suspends the window's closure rather than falsifying the claim.

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
      Invariant 1.7b: An auditor MUST evaluate Invariant 1.5a against the attestation store's surviving fields alone.
      Invariant 1.7c: An auditor MUST NOT read the who, the what and the when from the destruction record.
  Invariant 1.8: A new orphan a compensating write leaves MUST count as a new finding with the new orphan's own attestation instant.
  Invariant 1.9: The scan's next run MUST retry EVERY orphan not yet reconciled.
  Invariant 1.10: A run MUST issue its first reconciliation-path [Record Action] ALONE.
  Invariant 1.11: A run MUST NOT start a further reconciliation-path [Record Action] BEFORE the first has returned success.
  Invariant 1.12: A run MUST NOT start a further reconciliation-path [Record Action] AFTER a refusal that left an attested orphan.
  ```
  *Rests on:* [Record Action] steps 2, 3 and 5; the liveness arm on [Record Action] itself — the compensating record is written through it under `audit.compensation` and the finding under `audit.reconciliation` (Compensation 1 through 5), with the observable closure on compensated attestations pre-checked under the per-attestation id critical section (Second half 9, Concurrency 9); Actor Identity Invariants 1 (attestation immutability), 2 (action binding), 3 (actor binding) and 9 (attestation durability — why the closure needs a marker at all, since the orphan it forecloses deleting is permanent); Event Log Invariants 1 (append-only) and 2 (event immutability).

  WHY: the reverse partial is reachable and durable, since synchronous rollback is unavailable, so the honest claim is a surfaced transient under compensation, never a quiet inconsistency. *Reconciled* is membership in compensated attestations because nothing about the attestation itself ever changes to say *dealt with*; the marker is not forgeable (Primitive policy 8, reconciliation operator 2, Check 7). A compensation is an ordinary [Record Action] and can itself fail at step 3, leaving a new orphan; the chain terminates the way retries terminate, each orphan bounded from its own creation, no link unsurfaced (Invariant 1.8). The clause compares differently by retention state because the cascade destroys one side of the comparison and not the other. The legs run concurrently (Reconciliation 1a), so one cascade's re-drive, however long, never holds a later act's leg behind it; the one place a leg waits is the probe: the run's first reconciliation-path record goes alone, and the others start only once it has returned success, so a standing refusal mints one orphan per run and not one per leg (Invariant 1.10 through 1.12). The first half's legs write no record (Compensation 12), so the probe never holds a re-drive.

- **Invariant 2 — Retention coverage (safety + liveness at quiescence).**
  ```
  Invariant 2.1: A successful [Record Action] MUST NOT return an event id with no retention record.
  Invariant 2.2: The scan MUST reconcile EVERY unretained event WITHIN compensation window of the event's recording instant by placing the missing retention.
  Invariant 2.3: The reconciliation path MAY place a retention ONLY IF true miss EXISTS for the event id.
  Invariant 2.4: WHEN quiescence EXISTS:
      Invariant 2.4a: For EVERY event id recorded through [Record Action], event to retention's entry MUST reference EXACTLY ONE recorded retention of either retention state.
  ```
  *Rests on:* [Record Action] steps 3, 4 and 5; the liveness arm on [Record Action] itself (Compensation 1 through 5); the composition's own event to retention pre-check under the per-act critical section and below record edge (Third half 2 through 7, Concurrency 6), which supplies the idempotence Retention Window's place_under_retention nowhere declares; the third half as the arm's detector (Third half 1); [Purge Event] step 0½ as the arm that keeps the cascade out of the window (purge event step 0½.2); Retention Window Invariants 1 (membership exclusivity), 5 (record reference and policy reference immutability), place_under_retention's fresh retention id per call (which makes the pre-check necessary) and 10 (retention store durability); Event Log Invariant 1.

  WHY: a failure between step 3 and step 4 is reachable because an appended event cannot be withdrawn; it is surfaced as `recording-failure(step-4)` and reconciled by placing the missing retention. Retention Window's place_under_retention answers a fresh retention id per call and declares nothing about a repeat over the same record reference, so it is nowhere idempotent on record reference, and a path that re-placed on every pass would accumulate retentions governing one event — falsifying *exactly one* in the direction the atom cannot refuse. Without the third half this arm would have a compensation and no detector.

- **Invariant 3 — Integrity coverage (modulo unsealed tail).**
  ```
  Invariant 3.1: IF the event's sequence number DOES NOT EXCEED sealed through THEN EXACTLY ONE seal MUST cover the event.
  Invariant 3.2: A purged event MUST remain covered by the covering seal.
  ```
  *Rests on:* [Seal Now] (and [Record Action] step 6 under per-event cadence), with [Purge Event] step 0 keeping it true of every purged event by construction; Tamper Evidence Invariants 1 (evidence immutability), 3 (record-set binding) and 9 (seal store durability, why a seal outlives the records it committed to); Event Log Invariants 3 (total order) and 4 (sequence-number monotonicity), without which a contiguous range is not a well-defined cover.

  WHY: the claim is exact because there is exactly one way a coverage entry gets written — [Seal Now] cuts the slice and advances sealed through past it, so slices are contiguous, disjoint and strictly advancing (seal coverage 7, seal coverage 8). *At most one* follows from disjointness and *at least one* from the bound; the claim is over seals, full stop, with no second class of seal to quantify around. What a purged event loses is verifiability, not coverage, and [Verify Record] reports that honestly. The claim is unconditional rather than modulo a seal lifetime because seals are retained indefinitely (retention policy 5); Erasure Tombstone composed for seal disposal and Seal Lifecycle composed for re-sealing would each put it modulo their own bookkeeping, and both are named and out of scope. The unsealed tail is a bounded gap the cadence shrinks and unsealed tail mode names what a verifier makes of it.

- **Invariant 4 — Cascade coordination on purge.**
  ```
  Invariant 4.1: A [Purge Event] MUST leave the four stores in the coherent end state: the event covered, the retention in Purged with purge instant, the sequence number in purged events with the pair captured, and the destruction delegated with the outcome recorded.
  Invariant 4.2: The cascade MUST commit the steps in the declared order.
  Invariant 4.3: The composition MUST NOT claim an atomic set spanning the retention transition and the delegated destruction.
  Invariant 4.4: An auditor MUST clear the delegated destruction's completion outside the records.
  ```
  *Rests on:* [Purge Event] steps 0–4, defended by the cascade-on-purge rule; Retention Window Invariants 3 (terminal absorption), 7 (no early purge) and 8 (purge timestamp consistency); Tamper Evidence Invariant 1; Event Log Invariant 1 and Actor Identity Invariant 9, which are what make the delegation necessary rather than optional.

  WHY: the invariant is over the coordination, not over a destruction this composition performs: no retained event is left without attestation or integrity coverage, and no purged event leaves a dangling attestation reference or a live seal content claim. The retention transition and the delegated destruction are each un-withdrawable, so no atomic set spans them (the section titled *Durability boundaries* in `pressure-testing.md`); the coordination is ordered writes plus compensation — a partial state surfaces as `cascade-failure(step)` and the scan re-drives it — and a destruction-failed outcome leaves the coordination incomplete, re-driven each cycle until it completes (Boundary one 6).

- **Invariant 5 — Constituent invariants preserved.**
  ```
  Invariant 5.1: EVERY invariant of the four constituent atoms MUST hold over the atom's instance for EVERY event whose retention state DOES NOT EQUAL Purged.
  Invariant 5.4: For a Purged event, AND for a live event whose covering seal is partly purged, an auditor MUST read a constituent invariant that needs a readable proof or a re-presented record set as discharged by the destruction record.
  Invariant 5.2: The composition MUST NOT remove a log entry.
  Invariant 5.3: The composition MUST NOT rewrite a stored field of a constituent record.
  ```
  *Rests on:* the whole action wiring — every constituent call this composition makes is a declared surface of that constituent, and no step reaches around one; the cascade-on-purge rule is where the claim would otherwise break; Composes 13, Composes 15 and Composes 16 for the seal store.

  WHY: one sentence carries the whole of what makes it literal, argued at Boundary one: the cascade delegates destruction to a shredding-class mechanism that destroys recoverability while leaving every stored field as written. Granting it, the four invariants the cascade could threaten hold verbatim — Event Log 1 (no entry removed), Event Log 2 (no stored field rewritten; shredding destroys the key, not the bytes), Actor Identity 9 (no attestation deleted), Actor Identity 1 (no attestation field rewritten). The composition's only writes into the seal store are `TamperEvidence.seal` calls from [Seal Now]: new evidence records, none mutated (Tamper Evidence Invariant 1), none deleted (Tamper Evidence Invariant 9). The four are the ones that claim no readable content; the ones that need it — Actor Identity Invariants 2, 3 and 6 over a proof, Tamper Evidence Invariants 3 and 4 over a re-presented record set — cannot hold over destroyed content for any shredding-class mechanism, so the sentence reads over the events not yet purged and a purged event stands on the destruction record, the pair and the retention record instead (Invariant 5.4, [Verify Record] step 1).

- **Invariant 6 — Forensic completability.**
  ```
  Invariant 6.1: For EVERY event id, WHILE every constituent read answers, [Read Record] MUST return EXACTLY ONE OF the audit record, not-known.
  Invariant 6.2: For EVERY event id, [Verify Record] MUST return EXACTLY ONE OF verified, failed-verification(reason), unverifiable(reason), not-known.
  Invariant 6.3: IF no verification surface outage EXISTS THEN [Verify Record] MUST answer deterministically over a fixed record set.
  ```
  Term verification surface outage: the actor registry or the seal mechanism unreachable.

  *Rests on:* [Read Record] and [Verify Record]; for a purged event the *who / what / when* half of the join on the pair captured at [Purge Event] step 2 and the surviving fields it names (read record step 4.4), the only route left once Event Log's data field is unreadable; Actor Identity Invariants 1 and 9 (without which the record would not still be there to read), 6 (self-containment) and 7 (verification consistency under fixed registry state); Tamper Evidence Invariants 4 (verification self-containment given the originating records) and 7 (verification consistency under a fixed record set); Invariant 1 through 3 above for the completeness of what is joined.

  WHY: an investigator reconstructs the full history from records alone. The hedge *where content is still present* is the cascade's, not a softening: completability is a claim about the record set, not the content. The availability condition is the reason the [Unverifiable] arm exists — when the registry or the mechanism cannot be reached the honest answer is that verification could not be performed — and determinism is claimed over the outcomes reachable with the surfaces up. The first three outcomes may carry the `(compensation-window)` qualifier on the separate channel.

- **Invariant 7 — Verification asymmetry preserved.**
  ```
  Invariant 7.1: [Verify Record] MUST require the original record set re-presented.
  Invariant 7.2: [Verify Record] MUST NOT require the actor's credential beyond the registry's public material.
  Invariant 7.3: The composition MUST NOT fetch the covering record set internally for verification.
  ```
  *Rests on:* [Verify Record] steps 3 and 5; [Read Record] step 4, which supplies the covering range (read record step 4.3); Primitive policy 25 through 28, which fix both shapes; Tamper Evidence Invariants 3 (record-set binding) and 4; Actor Identity Invariant 6.

  WHY: the asymmetry inherits Tamper Evidence's verification self-containment given the originating records and Actor Identity's verification self-containment, and it surfaces at the caller boundary — which is why [Read Record] does not verify (read record 4): a read surface that fetched the payload internally would hide exactly this asymmetry. The asymmetry extends to cadence rather than being narrowed by it: the verifier presents what the covering seal commits to (Primitive policy 26), and only its extent moves; what the composition owes in exchange is knowing which record set that is, discharged through [Read Record]'s returned range.

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
  Term event standing: retained | lawfully destroyed | held — held is a Purged retention whose cascade a hold has left open over readable content.

  *Rests on:* [Purge Event] steps 0, 1, 2 and 4 and [Verify Record] steps 1–2; [Read Record] step 5 and [Verify Record] step 2 for the compensation-window reading (read record step 5.1, verify record step 2.3); the liveness arm — that the compensation-window state is bounded and closes — on [Record Action], through which the scan records its findings and the compensating placement (Compensation 1 through 5); Retention Window Invariants 1 (membership exclusivity), 3 (terminal absorption) and 10 (retention store durability); Tamper Evidence Invariant 1; Invariant 2 above for the window it is conditioned on and Invariant 4 for the coordination that produces the surviving records.

  WHY: *missing without record* does not occur through this composition. The fourth record is why the foreclosed state stays foreclosed, and the mechanism is the scan: a destruction-failed delegation leaves *Purged* over readable content, and First half 4's predicate re-drives it every cycle — foreclosed because the scan retries, not because failure was assumed away. Every purged event has a covering entry by construction (purge event step 0.3). Without the quiescence qualifier this invariant would contradict Invariant 2's liveness arm; inside the window the event is verifiable but not yet retention-covered, a bounded finding, not a third steady state. Reading purged off the record rather than off the absence of content is what makes the distinction survive every conforming erasure mechanism.

Attribution coverage and retention coverage together give the complete-record property; integrity coverage modulo unsealed tail names the cadence trade-off honestly; cascade coordination on purge prevents dangling state across the four stores without pretending to a destruction surface two constituents forbid; honest representation of destruction is what distinguishes a *complete* audit trail from a *suspicious* one.

---

## Examples

### Walkthrough

A regulated bank deploys the composition as the canonical audit trail for its core ledger: `retention_policy = sox_7_year`; `seal_cadence = every 1000 events or 60 seconds, whichever first`; `seal_mechanism = SHA-256 hash chain, newest link anchored synchronously at seal time to an RFC 3161 TSA`, linked across seals; `erasure_mechanism = per-event content-key shredding at the storage layer`; `compensation_window = 24 hours`; `record_action_completion_bound = 30 seconds`; `purge_completion_bound = 5 minutes`; `seal_completion_bound = 2 minutes`; `compensation_closure_latency = 6 minutes` (a run's enumeration included; the start-time measurement came to 40 seconds); `call_pause_bound = 2 seconds`; `clock_offset_allowance = 2 seconds`; `reconciliation_cadence = 60 seconds` (the derived default — the time arm of its interval cadence; the thousand-event arm is not a duration); `payload_cap = 64 KB`, matching the wired Event Log instance. Instance start 16 holds with room to spare: closure sum is max(2 * 30 seconds, 5 minutes) + 2 * 2 seconds + 2 * (60 seconds + 6 minutes), 19 minutes 4 seconds, against 24 hours; Instance start 18 and 19 hold because 6 minutes exceeds both 214 seconds (4 * 30 seconds plus 6 * 2 seconds, the 2-second call pause bound and twice the 40-second measured enumeration — one before the take, one under the lease) and 342 seconds (5 minutes plus the same two), and Instance start 25 holds because 4 seconds is below every completion bound.

1. **A wire-transfer authorization arrives.** `record_action(wire_w91, supervisor_s12, supervisor_credential, {amount: 50000, counterparty: ...})`. Actor Identity → `attestation_a44`; Event Log → `event_e9301`; Retention Window → `retention_r9301` with `retention_until = 2033-05-10`; the event lands in the unsealed tail. Returns `event_e9301`.
2. **The cadence fires.** The thousand-event arm trips first: [Seal Now] runs over the slice `[8302 .. 9301]`, whose last member is `e9301`. The chain's newest link is anchored to the TSA synchronously, within the seal call — which is what entitles the record to carry anchoring instant at all; batched anchoring after the fact is a separate External Anchoring pattern — and `evidence_s127` is recorded with `anchored_at = 2026-05-10T14:33:00Z`. The seal coverage entry for `s127` is `[8302 .. 9301]`; sealed through advances to 9301.
3. **Six years later, a SOX section 404 audit.** *Show me the supervisor authorization on wire w91, and prove it hasn't been altered.* `read_record(e9301)` returns the [Audit Record] in one shot: action `wire_w91`, actor `supervisor_s12`, attestation `a44`, retention `r9301` in *Retained*, and coverage `s127` over `[8302 .. 9301]` — the instruction for the next call. This deployment runs interval cadence, so the auditor pulls all thousand payloads for that range — through Event Log's range read where the log is online, from the archive otherwise — and calls `verify_record(e9301, payloads_8302_through_9301)`. Retention reads *Retained* (no purged short-circuit), the event is present, the attestation verifies against `s12`'s public material, `s127` is the covering seal, the presented range passes through to `TamperEvidence.verify`. Returns `verified`. Under a per-event cadence the same call would carry `e9301`'s single payload; the argument is the same argument, only its extent moves.
4. **Seven years and one month later.** [Purge Eligible] runs nightly and `e9301` is on the list. `purge_event(e9301)`: step 0 is a no-op — `9301 ≤ sealed_through`, so `s127` covers it. `RetentionWindow.purge(r9301)` moves the retention to *Purged* with `purged_at = 2033-06-14`; `9301` joins `s127`'s purged events — just that one number, since the other 999 members are under their own retentions — and the same write captures the pair `(e9301, a44)` before anything is destroyed. Destruction of Event Log's data field for `e9301` and of `a44`'s proof goes to the content-key shredder, which reports destroyed; the cascade completes. Had it reported `destruction-failed(...)`, the cascade would have rejected `cascade-failure(step-3)` and the 60-second scan would have re-driven the entry each cycle until a destroyed outcome landed, `r9301` standing as a surfaced alert meanwhile. The Event Log entry's and the attestation's stored fields are byte-for-byte what they were; the key is gone, so the payload and the proof no longer read, while `a44`'s action reference, actor reference and attestation instant still do. `verify_record(e9301, ...)` now returns `failed-verification(purged)`, read off `r9301` before any `ActorIdentity.verify` call. No re-seal follows: `s127` stays the one seal over `[8302 .. 9301]`, and its 999 survivors answer `unverifiable(partially-purged-coverage)` for the rest of their retained lifetimes — unknown, not bad. A bank that could not accept that composes Seal Lifecycle *(forthcoming)*, at the cost of a mechanism round-trip per purge and a pattern to wire.
5. **A subsequent regulator inquiry.** *What happened to wire w91?* The retention store holds `r9301` in *Purged* with purge instant inside the lawful window; the seal store retains `s127` indefinitely, now carrying `9301` in purged events and still the cover for its other members; the attestation store retains `a44` with its surviving fields readable. `read_record(e9301)` sees *Purged*, takes `(e9301, a44)` out of the destruction record, and reads the *who / what / when* off `a44` — so the answer is not merely *something was destroyed* but *`supervisor_s12`'s authorization of `wire_w91`, attested at that moment, was destroyed lawfully on 2033-06-14*.

### Walkthrough — rejection paths

**Orphan attestation — attest succeeds, append fails.** `record_action(wire_w92, supervisor_s12, supervisor_credential, {amount: 75000, ...})`.

1. Step 1 passes: both references are far inside the 1 KB cap and the full constructed payload is about 2 KB against the 64 KB cap. Nothing is recorded yet.
2. Step 2: `ActorIdentity.attest(...)` → `attestation_a45`, committed and immutable.
3. Step 3: `EventLog.append({...})` — the store is mid-failover and returns storage-failure. Per Event Log's contract that is definitive: `event_e9302` does not exist and never will.
4. The composition returns `recording-failure(step-3)` and, in the same outcome, surfaces `a45` as an orphan; it writes nothing further, releases its critical section on `a45`, and yields. Once `a45`'s attestation instant is older than 30 + 2 seconds, the scan takes the critical section on `a45`, records an `audit.reconciliation` finding naming it, then a compensating record naming `a45` as unbound — through [Record Action] under `audit.compensation`, attributed to the bank's operator identity, raised as a high-priority compliance finding. The scan found `a45` by the binding-set test — in the attestation store, in no live payload, in no destruction record — and, finding it absent from compensated attestations, wrote the one compensation; the next scan leaves it alone.
5. The caller retries after the store recovers and gets a fresh `attestation_a46` and `event_e9303`. `a45` remains in the store forever as a surfaced, reconciled orphan — the honest record of what happened rather than a defect to be hidden.

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

*Healthcare — HIPAA section 164.312(b).* Every read, write or amendment of protected health information is recorded with the clinician's attestation, retained for the longer of HIPAA's 6-year baseline or state law, sealed in a per-patient Merkle tree; a section 164.524 access request and a breach investigation walk the same trail.

*Payments — PCI DSS Requirement 10.* Every access to cardholder data, every export, every key-management operation is recorded with the operator's attestation, retained per Requirement 3.1, HMAC-chained per 10.5; the annual QSA assessment runs [Verify Record] over the year's high-risk actions.

*Pharmaceutical — 21 CFR Part 11.* Every change to an electronic batch record is recorded with the operator's qualified electronic signature, retained per the predicate rule, sealed in a hash chain; an FDA inspection produces the verified history of any batch, and the ALCOA properties are the composition's emergent property.

*Communications — SEC Rule 17a-4.* Every business communication at a registered broker-dealer is recorded with the originator's attestation, retained 3–7 years with the first two immediately accessible (composing a Storage Tier *(forthcoming)*), Merkle-tree sealed; a FINRA examination and a litigation discovery walk the same trail. WORM storage is one mechanism the composition can be realized over; the composition names the structural form.

### Regulated adversarial scenarios

**Regulator audit — "show me the complete, verifiable history of action X over the retention horizon."** *Every event referencing action X* is a query by payload field, so the enumeration is a composed Reverse Index *(forthcoming)*, not a passthrough (Action wiring 3, Action wiring 4); a sequence-number or wall-time window would pass straight through. From there the composition answers per event: `verified` for each retained event, the *Purged* retention record for each destroyed one. Invariants 1, 2, 3 and 8 are the structural answer, from the records, without source code or runbooks.

**Disputed action — "I didn't do that."** The investigator retrieves the event and calls [Verify Record]. If `verified`, the attestation binds the named actor to the named action at attestation instant (Actor Identity's non-repudiation contract, through Invariant 5); the actor cannot plausibly deny it without claiming credential compromise, which a Compromise Disclosure pattern *(forthcoming)* handles by new records, never by mutating the trail.

**Breach forensics — "when was the trail compromised?"** The responder walks every seal in sealing instant order — one seal per range, never a replacement — running [Verify Record] against representative events in each range. The most recent seal that returns `verified` end-to-end and the next that returns `failed-verification(seal-proof-invalid)` bound the forensic window, provided the mechanism is chained across seals (seal mechanism 2); under independent per-range seals a failed seal narrows the tampering only to its own range, and the responder gets a set of compromised ranges rather than a window — which of the two the mechanism is, the deployment declares, since mechanism opacity hides it (Tamper Evidence Invariant 8). An `unverifiable(...)` result bounds nothing: under the availability reasons the responder retries; under partially-purged-coverage the responder steps over the seal to the nearest presentable one, which widens the window rather than falsifying it. Where seals carry anchoring instant from a TSA outside the adversary's reach, the upper bound on the time of tampering is independently established.

---

## Generation acceptance

A derived implementation of Audit Trail is acceptable — in the regulator-acceptance sense — when an external auditor, given the composition's emergent state plus the four constituent stores, can clear the checks below without recourse to source code, runbooks or developer narration. The first list is what the composition's own records answer; the second is what arises around the composition and needs evidence the composition does not hold.

### Conformance checks

```
Check 1.1: An auditor MUST obtain, from one [Read Record] call on any event id, the joined audit record — what, who, integrity and retention.
Check 1.2: An auditor MUST confirm that not-known is returned only for an event id no constituent knows.
Check 1.3: An auditor MUST confirm that an invalid-request refusal of [Record Action] carries its step and that the step names the state the refusal left.
Check 2.1: An auditor MUST verify all eight composition-level invariants over the record set.
Check 2.2: An auditor MUST verify Invariants 1 and 2 at quiescence, reading the quiescence condition from compensation window.
Check 2.3: An auditor MUST enumerate the log against the attestation store and the retention store.
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
Check 4.2: An auditor MUST walk EVERY entry in the seal store.
Check 4.3: An auditor MUST step over a seal answering unverifiable(partially-purged-coverage) to the nearest presentable seal.
Check 4.4: An auditor MUST read the mechanism's chaining posture from the deployment's declaration.
Check 5.1: An auditor MUST confirm, for EVERY purged event that is not held, that failed-verification(purged) is backed by the records of Check 5.2 through 5.8.
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
Check 6.1: An auditor MUST confirm that verification could not be performed surfaces as unverifiable(reason) and never as failed-verification(reason), for attestation-registry-unavailable, seal-mechanism-verification-unavailable and partially-purged-coverage.
Check 7.1: An auditor MUST discard event to retention, event to sequence, sealed through, seal coverage's ranges, compensated attestations and reported beyond horizon, run the rebuild procedures against the constituent stores, and reproduce EVERY traversal answer.
Check 7.2: An auditor MUST discard event to sequence first.
Check 7.3: An auditor MUST confirm EVERY member of compensated attestations came from an event carrying an `audit.*` action reference whose payload actor reference EQUALS reconciliation operator.
Check 7.4: An auditor MUST regenerate event to attestation's entry for EVERY live event from the event's payload.
Check 7.5: An auditor MUST confirm event to attestation's entry for EVERY purged event that is not held is present in the destruction record.
Check 7.6: An auditor MUST read a purged event that is not held, with no destruction-record pair, as a conformance failure.
Check 7.7: An auditor MUST confirm the scan's binding set and event to attestation's two halves agree.
Check 7.8: An auditor MUST NOT expect a rebuild of an extraction-pending fact.
Check 8.1: An auditor MUST identify the composing patterns active in the deployment and the patterns' configuration.
Check 8.2: An auditor MUST NOT run Check 1 through 7 BEFORE identifying Reverse Index, Legal Hold, Erasure Tombstone composed for seal disposal, and Seal Lifecycle.
```

Term audit edge: `compensation_window + clock_offset_allowance`, counted from the finding's creation or the end of the last overlapping store outage (Composition-level invariant 1c) — the auditor's own reading compared to a constituent's stamp only under the allowance.

Term residual finding: an unreconciled finding older than the audit edge — the conformance failure Check 2 reports.

Term seal stamps: sealing instant, and anchoring instant where the mechanism anchors.

Term extraction-pending fact: purged events, event to attestation's purged entries, and erasure outcomes.

WHY:
Check 2 reads quiescence off a declared number, not the spec's confidence; its retention side is the third half run from outside (Check 2.9), and its orphan side is audited against a marker because Actor Identity Invariant 9 makes *no orphans remain* unreachable — what a conforming instance reaches is *every orphan compensated* (Check 2.10 through 2.12). Event Log carries no acceptance bar, so its seven invariants are verified directly (Check 3). Check 4 clears as a window only under a chained mechanism, which opacity keeps out of the records (Check 4.4). Check 5 reads records, not the absence of content, and mere presence of an outcome record would clear the state Invariant 8 forbids (Check 5.9). Check 6's third reason is the sharpest, because the composition's own cascade created the condition. Check 7.3 is what makes compensated attestations unforgeable; the three extraction-pending facts are verified by Check 5 instead (Check 7.8). Check 8's full list: Legal Hold, Defensible Retention, and *(forthcoming)* Trusted Timestamping, Storage Tier, Compromise Disclosure, Erasure Coordination, Policy Reconciliation, Mechanism Registry, Reverse Index, Legacy Import, Failed-Attempt Log, Schema Evolution, Erasure Tombstone, Seal Lifecycle, and the declared erasure mechanism; the four Check 8.2 names change what the other checks mean.

### External checks

```
External check 1: An auditor MUST clear from external evidence that the erasure mechanism was authorized to destroy, is shredding-class, and completed each destruction.
External check 2: An auditor MUST clear from external evidence that the actor registry retained the registry's historical public material across key rotation.
External check 3: An auditor MUST clear from external evidence that the seal mechanism is cryptographically sound for the audit horizon.
External check 4: An auditor MUST clear from external evidence that the mechanism's seal-time rendering agrees with the verify-time presentation.
External check 5: An auditor MUST clear from external evidence that the clock was monotonic and unmanipulated over the audit horizon.
External check 6: An auditor MUST clear from external evidence that the configured retention policy was the correct one for the record class.
External check 7: An auditor MUST clear from the deployment's own store that the audit log instance, next sequence number included, survives a process restart.
External check 8: An auditor MUST clear from the deployment's own matching logic that record set match judges the presented record set against the reference the seal committed to.
External check 9: WHEN Legal Hold EQUALS composed, an auditor MUST clear from the deployment's own concurrency control that a hold placement over an event id and a cascade on that event id serialize, the placement a bounded holder of the section (Capability requirement 7a, 7b, 7c, 7d, 7e, 7f).
External check 10: An auditor MUST clear from the deployment's own lock that the sealing lock, and the serialization that discharges Concurrency 3 where it is not an atomic set-add, are leases held under a fresh holder value and not released early by an abandoned call, and that the sealing lock is shared by every process serving the instance, is a lease of seal completion bound and carries the uncovered mark across a restart and past the lease's expiry, stored apart from the grant (Concurrency 1a, Concurrency 1b, Concurrency 1b1, Concurrency 1c).
External check 11: An auditor MUST clear from the deployment's own lock that the per-act critical section is a lease of the act's completion bound for a record action, a cascade and a hold placement and of compensation closure latency less the run's elapsed time at the take and call pause bound for a scan leg, shared by every process serving the instance, keyed by the act's id namespaced by the act's kind, held under a holder value minted fresh for each attempt, and not released early by an abandoned call (Per-act critical section 1, 1a, 1b, 1c, 2a, 9a, 13a, 13d), and that no scan leg's start waits on another leg's closure (Reconciliation 1a).
External check 12: An auditor MUST clear from the deployment's own constituent clients that no write a holder issued lands after the lease it issued under, abandoned calls and queued retries included (record action completion bound 2, purge completion bound 2, compensation closure latency 2, seal completion bound 2).
External check 13: An auditor MUST clear from the deployment's own operational record that every store outage's start instant and end instant is recorded (Composition-level invariant 1d), that the scan scheduler starts the next run after the loss of a process (reconciliation cadence 6), that an interval-based cadence driver survives it and fires at start and restart (seal cadence 4), and that the call pause bound is not exceeded by the worst call the clients make (call pause bound 1).
```

Term external evidence: evidence outside the records — the mechanism's documentation and configuration, the registry's retention policy, cryptographic review, time-service logs, the deployment's regulations.

WHY:
The records show a changed stored field against the immutability invariants and cannot show that the key really went away — the direct cost of the delegation, part of which migrates to the traversal list once Erasure Tombstone lands (External check 1). A registry that drops superseded material fails old attestations for a reason that has nothing to do with the trail (External check 2). A rendering mismatch surfaces as `failed-verification(seal-proof-invalid)`, indistinguishable from tampering — the worst ambiguity for the one answer this composition exists to give (External check 4). A host whose record set match answers no over a faithful presentation reports tampering against an untouched record as `seal-record-set-mismatch`, and one that answers yes over a wrong set leaves the verdict to the proof check, which reports `seal-proof-invalid`, so the two reasons diverge between hosts exactly where the reason is the answer (External check 8). Every stamp is only as truthful as the injected clock (External check 5). Code generated from this composition must clear the eight traversal checks and make the thirteen external questions askable, naming the evidence each needs.

### Generator's contract

```
Generator's contract 1: An implementation derived from this composition MUST produce records and a runtime surface that clear Check 1 through 8.
Generator's contract 2: An implementation derived from this composition MUST make External check 1 through 13 askable, naming the external evidence each needs.
```

---

## Non-goals

```
Non-goal 1: The composition MUST specify one instance.
Non-goal 2: The composition MUST NOT provide a path for a pre-attestation legacy event.
Non-goal 3: A Legacy Import pattern MUST NOT write into the audit log around [Record Action].
Non-goal 4: A Legacy Import pattern MUST take EXACTLY ONE OF attesting each imported record under a declared import identity through [Record Action], a separate unattested store the auditor reads as explicitly unattributed history.
Non-goal 5: The composition MUST NOT invalidate an attestation retroactively.
Non-goal 6: The composition MUST NOT adjudicate an erasure request against a retention obligation.
Non-goal 7: The composition MUST NOT declare a seal-store retention owner.
Non-goal 8: The composition MUST NOT rotate a seal onto a new mechanism.
Non-goal 9: seal mechanism MUST govern seals cut from the time of setting on.
Non-goal 10: The composition MUST NOT treat a storage tier differently at [Verify Record].
Non-goal 11: The composition MUST NOT place a retention on, or destroy, an attestation that has no event.
```

An orphan attestation, one step 3 never bound to an event, is the one record this composition cannot retire: it has no log entry to cascade through and Composes 9 forbids placing it, so its proof and its action and actor references stay readable for the life of the attestation store, and it stands in the reconciled set rather than in a lifetime. Its retirement joins what Erasure Tombstone *(forthcoming)* owns; until then the lifetime the Summary claims is the lifetime of every event.

WHY: multi-instance configuration and federation are the deployment layer's — an Audit Federation pattern *(forthcoming)* composes naturally (Non-goal 1). An import identity binds the importer, not the original actor; whether the attribution gap is acceptable is a legal question about the imported body (Non-goal 2 through 4). Attestations made during a compromise window verify but should be reinterpreted by new records — Compromise Disclosure *(forthcoming)* (Non-goal 5). A GDPR Article 17 request colliding with a retention obligation is Erasure Coordination's *(forthcoming)* decision, with counsel in the loop (Non-goal 6). A coarse cadence has a second cost that arrives years later: the more live seal-mates each purge strands. Seals already written stay under the mechanism that produced them (Non-goal 8, Non-goal 9). Storage Tier *(forthcoming)* owns the active-to-cold transition (Non-goal 10).

### Failed attribution attempts

```
Failed attribution 1: The composition MUST NOT record a [Record Action] rejected at step 1.
Failed attribution 2: The composition MUST NOT record a [Record Action] rejected at step 2.
```

WHY: the audit surface is committed actions, not attempted ones; a Failed-Attempt Log *(forthcoming)* records the rejected attempt for deployments where an insider retrying with forged credentials is itself auditable.

Where the composition breaks down: when the four constituent stores share an adversary with write access to all of them and external anchoring is absent; when the host cannot supply a stable, reproducibly-addressable record set at verify time; when the retention policy and the integrity-coverage cadence are mismatched — events purged before their covering seal is verified against them; when the actor registry's historical public material is not retained and old attestations begin failing under a new key.

### Legal hold suspension of purge

Where the composed hold lands is [Purge Event], not [Purge Eligible] (purge event 5, purge eligible 6), read under the cascade's own critical section after the not-known test and before the seal (purge event 5c) with hold placement serialized against that section (Capability requirement 7a): a hold placed before the read stops the cascade with nothing written, and a hold placed after the section is released finds the cascade finished or left open at step 2 or 3, so there is no placement between a step-1 commit and the step-3 delegation to race it. A cascade left open by a failure at step 2 or 3 and re-driven after a hold is placed stands *Purged* over readable content under the hold, lawfully, until release; the first half neither alerts on it nor counts it against compensation window (First half 9, First half 10), and Invariant 8 reads it as *held*, a third standing, not a divergence (Invariant 8.1a, Invariant 8.2a), while a hold over a completed purge changes no standing; [Defensible Retention](./defensible-retention.md) already wires the gate over a business record set. A deployment wanting a hold-filtered worklist asks the composed Legal Hold pattern.

## Edge cases

### Concurrency

Six serialization obligations (Concurrency 1, 2, 3, 6, 8 and 9), all implementation-owned, and two rules that forbid a lock.

```
Concurrency 1: The implementation MUST serialize the read-seal-advance sequence per instance across [Seal Now], the cadence-fired seal and [Purge Event] step 0.
Concurrency 1a: The sealing lock MUST be shared by EVERY process serving the instance.
Concurrency 1b: The sealing lock MUST carry the uncovered mark across EVERY process serving the instance and across a restart, OR leave the mark unknown.
Concurrency 1b1: The uncovered mark MUST be stored apart from the lock's grant, outliving the lease.
Concurrency 1c: The sealing lock MUST be a [Lease](../atoms/lease.md) of seal completion bound.
Concurrency 1d: The sealing lock MUST be taken by [Seal Now] alone.
Concurrency 1g: [Seal Now] MUST take the sealing lock by [Take](../atoms/lease.md), waiting no longer than the atom's arrival term.
Concurrency 1e: A [Seal Now] that abandoned a call MUST NOT release the sealing lock BEFORE the lease's instant.
Concurrency 1f: A [Seal Now] MUST present a holder value minted fresh for EACH attempt.
Concurrency 2: The implementation MUST serialize the cascade per event id.
Concurrency 3: The implementation MUST protect the destruction-record write against a lost membership.
Concurrency 3a: A serialization that discharges Concurrency 3 MUST be a [Lease](../atoms/lease.md) of purge completion bound held under Per-act critical section 1c and Per-act critical section 2a.
Concurrency 3b: The serialization of Concurrency 3a MUST be taken by [Take](../atoms/lease.md), its wait inside purge completion bound, AND IF the take answers unavailable OR no answer THEN the cascade MUST land cascade-failure(step-2) with no write.
Concurrency 3c: IF the serialization's lease EQUALS expired THEN the cascade MUST NOT write the destruction record AND MUST land cascade-failure(step-2) with no write, whatever the lease of the cascade's own critical section or a leg's reads.
Concurrency 4: A serialization keyed by evidence id MAY discharge Concurrency 3.
Concurrency 5: An atomic set-add MAY discharge Concurrency 3.
NOTE: watch cardinality — an inclusive *either discharges it* has no form; written as one obligation and two MAY rules (Concurrency 3 through 5). The same pressure at Second half 12 (one writer) and Compensation 2 (one record per finding).
Concurrency 6: [Record Action] steps 3 through 5 MUST run under the per-act critical section keyed by the attestation id step 2 returned.
Concurrency 7: [Record Action] steps 1 through 2 MUST NOT require composition-level serialization.
Concurrency 8: [Record Action] step 6 MUST take the per-instance sealing lock of Concurrency 1 through [Seal Now] alone.
Concurrency 9: The scan MUST serialize an orphan's compensation per attestation id.
Concurrency 10: [Read Record], [Verify Record] and [Purge Eligible] MUST NOT take a serialization lock.
```

Term sealing lock: the lease of Concurrency 1c that serializes the read-seal-advance sequence per instance.

Term uncovered mark: the record the sealing lock carries, set by [Seal Now] before step 4 with its holder value and cleared once the coverage entry has landed (seal now 15, 22, 23).

Term probe: a run's first reconciliation-path [Record Action], issued alone (Invariant 1.10).

WHY: two sealings reading the same sealed through would produce two evidence id values over one range, violating Invariant 3, and Tamper Evidence will not stop them — one seal per record set per cadence is the composing pattern's job (Concurrency 1). The cascade and its second step contend on different resources: the cascade on event id — the per-act critical section for a cascade, its lease purge completion bound long — while the step-2 write contends on the covering seal's entry, shared by every member of the range, where a read-modify-write under the race silently loses a membership no rebuild brings back; the per-event id lock alone is the natural mistake (Concurrency 2, Concurrency 3). The record action's critical section exists from the act's first write, which a per-event id key could not; step 6 is the read-seal-advance sequence Concurrency 1 governs (Concurrency 6). An orphan has no event id to lock; unserialized, a restart scan and a cadence scan both read *absent* and both record — duplicates are not false, but they make *once, or looping?* a question answered by reading timestamps (Concurrency 9).

### Clock source for cadence and purge

```
Clock source 1: The composition MUST NOT read now other than for the seal cadence timer, the scan's once-per-run reading, a scan leg's reading at its take to size its lease (Per-act critical section 13a), and the outlived check's two readings at record action step 2.12 and step 2.10.
Deleted: Clock source 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock source 3. Execution Contract Logic confinement 3 owns it.
Clock source 4: The deployment MUST supply a monotonically non-decreasing clock.
```

Term invocation: a [Record Action] or a [Purge Event] between the invocation's first write and the invocation's return.

WHY: the orchestration transition is a pure function of injected now (the section titled Logic Confinement Principle in `execution-contract.md`). An invocation's terminus at the completion bound is the expiry of a lease the host times. Purge eligibility is not evaluated here (purge eligible 1 through 4). Clock skew across nodes can cause non-deterministic eligibility and inconsistent cadence firing; the deployer configures the source — system clock, GPS-disciplined, NTP-synchronized cluster — and owns monotonicity, or composes a Trusted Timestamping pattern *(forthcoming)* whose anchored time serves as the authoritative source.

### Cross-store consistency under failure

```
Cross-store 1: The composition MUST require ordered writes plus compensation for a sequence of un-withdrawable writes.
Cross-store 2: The composition MUST NOT require a rollback of a committed constituent write.
Cross-store 3: The implementation MUST own how the implementation's own process survives the gap between two commits.
```

WHY: if `EventLog.append` succeeds and place_under_retention fails, the composition is in a state Invariant 2's safety arm forbids at quiescence, and append-only forecloses withdrawing the event; the attestation and the append are each un-withdrawable, so *all succeed or none* is not a state the constituents can offer (the section titled *Durability boundaries* in `pressure-testing.md`). The failure is surfaced as `recording-failure(step)`, recorded as a compliance finding, and reconciled within compensation window; the finding and the compensating write are audit events through [Record Action] (Compensation 1 through 8), never an operational log. The scan's three predicates are all stated (the first, second and third halves); the cascade's own half-completed state needs the first half because it is invisible to [Purge Eligible].

### Durability across crashes

The obligation follows the classification, not the element list.

```
Durability 1: The composition MUST treat a crash that records the event and loses a derived-index entry as a rebuild trigger.
Durability 2: The reconciliation path MUST NOT read a lost event to retention entry as absent.
Durability 3: An id-addressed action MUST NOT treat an event to sequence miss as not-known.
Durability 4: A short rebuild of a closed-state marker MUST NOT produce a false record.
Durability 5: A short rebuild of a closed-state marker MAY produce a duplicate record.
Durability 6: The deployment MUST persist purged events membership, the pair and erasure outcomes with the cascade's write, for the life of the seal record (retention policy 5).
Durability 7: The implementation MUST own the transactional boundary for the truth-bearing writes.
Durability 8: The deployment MUST persist each coverage entry of seal coverage's ranges with [Seal Now]'s step 5 write.
```

WHY: event to retention's rebuild-on-miss is load-bearing because Invariant 2's placement pre-checks it (Durability 2); event to sequence's is the hottest, because every id-addressed action resolves through it (Durability 3). compensated attestations is safe in the direction that matters — nothing enters the set except a compensation that was recorded (Durability 4). The membership and the pair are unreproducible because the cascade destroys the payload the rebuild would read; erasure outcomes because a lost outcome is not re-derivable from any store (erasure mechanism 7a answers it again) (Durability 6). event to attestation is a discardable index for a live event and durable truth for a purged one, and an implementation that treats the map uniformly gets one half wrong. Until Erasure Tombstone lands, the deployment owns persisting all three. The coverage ranges are rebuildable from the seal store, but sealed through is their maximum, and a lost latest entry is not a miss anyone observes: the next slice would start inside a covered range and cut a second seal over it (Invariant 3.1), so the rebuild covers a crash gap (seal now 13) and the entry's survival once written is Durability 8's.

### Partial attestation on step failure

The state, the surfacing and the closure are owned where they happen: the invocation surfaces the orphan in `recording-failure(step-3)` and writes no compensation (record action step 7.2, record action step 7.8); the scan is the one writer of the compensating record (Second half 12), finds the orphan by the binding set (Second half 1, Second half 2), examines nothing younger than record edge (Second half 3), and pre-checks compensated attestations (Second half 9); reconciled has the observable form the term reconciled names; the compensating record is an audit event (Compensation 4). High-assurance deployments treat any orphan in none of the binding set, compensated attestations and reported beyond horizon, past the window, as a gap in the audit surface and alert.

### Verification of the unsealed tail

```
Unsealed tail 1: The deployment MUST monitor the unsealed tail's depth and age against seal cadence.
Unsealed tail 2: The deployment MUST read a [Mechanism Failure] with a preconditions reason as a standing misconfiguration.
Unsealed tail 3: The deployment MUST read a [Seal Now] invalid-request as a standing defect.
```

WHY: two things put an event in the unsealed tail — the cadence has not fired, or a seal attempt failed — and an unsealed tail that stops draining is an operational alarm, not a silent gap. [Nothing To Seal] is not an alarm. An outage reason is transient and the next firing may clear it; a preconditions reason (wrong-shape keying material, which Tamper Evidence routes here rather than to invalid-request) reproduces every firing until Configuration changes; [Recording Failure] means the store refused and the next firing re-seals the same slice. A preconditions reason or invalid-request is a page for a human, not something to wait out.

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind** — Type, Operation, Member, Field or Parameter — with the Type it is a Member of, its Role, and one **Projection** line for every pinned or wire Member, the single canonical lowering token every target casing is derived from by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs). This is a composition, so its concepts are the composed action-wirings, the consolidated read, the derived read over eligible events, the [Audit Record], and its own outcomes and rejections. Backticked rather than carded, because they are reasons or qualifiers under inherited tokens rather than outcomes of their own: `unsealed` and purged under `failed-verification(...)`, partially-purged-coverage under `unverifiable(...)`, the `(compensation-window)` qualifier, and the reserved references `audit.compensation` and `audit.reconciliation`. The erasure mechanism's two outcome values belong to the deployment-declared mechanism and stay uncarded on the same terms as the constituent tokens; the derived indexes store no truth the constituent stores do not, and the three extraction-pending facts will be carded on Erasure Tombstone's own page when it lands. Constituent operations, inherited outcome tokens, constituent id tokens, the nineteen knobs and the per-act critical section stay backticked. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the deployment; the host; the implementation; the instance; the invocation; a [Record Action] step (also: the step); a cadence firing; the reconciliation scan (also: the scan, a scan run) and its first half, second half and third half (also: a leg, the reconciliation path); the cascade; the holder; a reader; a writer; a caller; the verifier; an auditor; an action of this composition; an id-addressed action; a read path; the rebuild; the read-back; the erasure mechanism; a policy selector; a regulated deployment; an implementation derived from this composition; a Legacy Import pattern; the next run; the next cadence firing; a constituent — Event Log, Actor Identity, Retention Window, Tamper Evidence — and the audit log, the attestation store, the retention store and the seal store; a derived index; an element; a coverage range; a seal; an attestation; an event; a retention record; the destruction record; the outcome record; a finding; a divergence; an entry.

Term composing patterns: (named, never constituents) Erasure Tombstone, Seal Lifecycle, Reverse Index, Legal Hold, Defensible Retention, Legacy Import, Policy Reconciliation, Mechanism Registry, Storage Tier, Trusted Timestamping, Compromise Disclosure, Erasure Coordination, Failed-Attempt Log, Schema Evolution, Audit Federation.

Term records: the audit event (Event Log's data field); the attestation; the retention record; the seal (evidence record); the destruction record; the `audit.reconciliation` record; the `audit.compensation` record; the beyond-horizon report; the outcome record; the [Audit Record]; the derived indexes — event to attestation, event to retention, event to sequence, seal coverage, sealed through, compensated attestations, reported beyond horizon; erasure outcomes.

Term record verbs: serve, call, read, delete, evaluate, write, dispose, seal, expose, alert, surface, retry, sit, consult, treat, claim, modify, remove, populate, classify, take, re-key, resolve, ask, key, overlap, carry, flag, record, address, land, close, compute, keep, filter, cover, set, place, hold, retain, select, declare, pass, inspect, log, wire, rewrite, leave, report, name, evidence, measure, run, govern, provision, decide, hand, apply, size, widen, exclude, supply, release, skip, block, issue, implement, complete, re-read, start, contain, validate, normalize, compare, consume, store, count, yield, present, canonicalize, return, adopt, guess, fall, depend, defer, invoke, advance, re-seal, change, produce, verify, assemble, fabricate, ride, fold, promote, route, proceed, locate, map, re-derive, share, reject, re-offer, re-drive, invent, resume, add, destroy, repair, remain, conclude, grow, suspend, stay, append, match, exist, condition, reconcile, commit, bound, answer, fetch, reserve, stand, obtain, confirm, enumerate, build, fail, walk, step, discard, regenerate, expect, identify, clear, specify, provide, invalidate, adjudicate, rotate, serialize, require, protect, persist, own, monitor, examine, test, delegate, compose, reference, raise, make, discharge.

Term cited: append, read, event id, sequence number, recording instant, data, next sequence number, invalid-query, invalid-payload, storage-failure: Event Log. attest, verify, attestation id, action reference, actor reference, attestation instant, proof, invalid-credential, invalid-request, not-known, registry-unavailable: Actor Identity. place_under_retention, purge, purge eligible, retention id, policy reference, record reference, retention deadline, purge deadline, purge instant, retention-period-not-elapsed, not-retained, invalid-policy, policy-not-found: Retention Window. seal, evidence id, record set reference, sealing instant, anchoring instant, `mechanism-failure(reason)`, mechanism-verification-unavailable, seal-record-set-mismatch, seal-proof-invalid: Tamper Evidence.

Term value sets: retention_state = Retained | Purged. seal cadence = per-event | interval-based | on-demand. unsealed tail mode = strict | lenient. mechanism class = unkeyed | keyed | anchored. erasure outcome = destroyed | destruction-failed(reason). coverage status = covered | unsealed tail | records-purged | partially purged. verify outcome = verified | failed-verification(reason) | unverifiable(reason). unverifiable reasons = attestation-registry-unavailable | seal-mechanism-verification-unavailable | partially-purged-coverage. composition-introduced failed-verification reasons = unsealed | purged | attestation-not-known | seal-not-known, plus the constituents' reasons prefixed `attestation-` and `seal-`. subject = attestation | event. disposition = beyond-horizon. cascade-failure step = seal | hold | step-1 | step-2 | step-3 | in-flight. recording-failure step = step-2 | step-3 | step-4. invalid-request step = step-1 | step-2 | step-3 | step-4. classification = derived index | extraction-pending.  lease = live | expired. `Legal Hold` = composed | absent. retention status on the audit record = the retention record's state | unresolved (compensation window). attribution on the audit record = the surviving fields | not-recoverable. reserved references = audit.compensation | audit.reconciliation. event standing = retained | lawfully destroyed | held.

Term bounds: call pause bound, compensation window, record action completion bound, purge completion bound, seal completion bound, compensation closure latency, clock offset allowance, payload cap, reference length cap, attestation id width.

Term cadences: seal cadence, reconciliation cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); `(compensation-window)` — carried beside a [Verify Record] outcome on a separate channel.

Term terms: (each declared where it is used) audit log, attestation store, retention store, seal store, surviving fields, open-upper-bound read, full enumeration, derived index, extraction-pending, rebuild-on-miss, retention state, live, purged, purged events, covering seal, closed entry, sealed through, unsealed tail, reconciled, resolved policy, time arm, chained mechanism, verify-time presentation, mechanism class, independently trusted substrate, standing false negative, shredding-class, tombstone-by-mutation, `Event Log's data field`, `finding's creation`, serialized envelope, reference headroom, whole closure, `act's completion bound`, lease, holder, pre-check, closure sum, full constructed payload, reserved namespace, reconciliation path, subject-kind discriminator, read-back, high-water mark, mid-record expiry, non-storage refusal, slice, tail position, audit record, coverage status, pair, partly-purged coverage, `Legal Hold`, hold, mid-cascade expiry, `cascade-failure(step-3)`, completed cascade, divergence, record edge, purge edge, horizon, purge age, attestation age, event age, binding set, orphan, true miss, owed narration, narrated, quiescence, `recorded through [Record Action]`, audit edge, composition-built query, insert-only map, closed-state marker, reconciled policy, held critical section, truth-bearing write, `who / what / when`, seal disposal, re-sealing, store outage, compliance alert, verification surface outage, event standing, residual finding, seal stamps, extraction-pending fact, invocation, later write, malformed reference, step-3 storage failure, step-4 storage failure, standing finding, open entry, external evidence, sealing lock, uncovered mark, probe, cadence driver, no answer, call pause bound, closure floor, measured enumeration, work bound; and now, the seam-injected reading (Clock source 1; the section titled Logic Confinement Principle in `execution-contract.md`).

Term original event payload: original_event_payload — the record set [Verify Record] re-presents to Tamper Evidence: the verify-time presentation of the covering seal's range as [Read Record] reported it, which is the event's own payload as appended where the range is the one event, and never the event's payload alone where the range is wider (Primitive policy 26).

Term slice reference: slice_ref — the reference naming the slice a seal covers.

#### Record Action

The composition's core action: validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal over the slice the firing cuts. Returns the new event id; invalid-credential before anything is recorded; invalid-request carrying the step — nothing recorded at step-1 or step-2, the attestation committed at step-3 and the event too at step-4; [Recording Failure] carrying the step where a store refused after the attestation, or where the lease's terminus fell between steps 2 and 4 — an orphan attestation at step-3, an unretained event at step-4, found by different halves of the scan. A seal failure at step 6 does not reject the call.

Kind: Operation

#### Seal Now

The action that seals the current unsealed tail — under interval or on-demand cadence, from [Record Action] step 6 under per-event cadence, and from [Purge Event] step 0 — over the slice, where the tail position is the highest sequence number the open-upper-bound read returns; records the coverage and advances sealed through. Cuts new coverage only. Returns the evidence id, [Nothing To Seal], [Mechanism Failure] with the mechanism's reason, invalid-request, or [Recording Failure]; under all of them the events stay in the unsealed tail and the next firing retries.

Kind: Operation

#### Read Record

The consolidated read: resolves the event id through event to sequence, joins the event, its attestation reference, its retention record and its coverage status into one [Audit Record], or returns not-known. For a purged event reads the *who / what / when* from the attestation record through the pair. Returning the covering range is what tells a [Verify Record] caller what to present. A pure projection; it presents, [Verify Record] proves.

Kind: Operation

#### Verify Record

The four-way verification query: retention state first, then log presence, then the attestation, then the covering seal. Returns `verified`, a prefixed `failed-verification(reason)` (including purged), [Unverifiable], or not-known; any of the first three may carry `(compensation-window)` on a separate channel. The record set re-presented is always the payloads of the covering seal's range.

Kind: Operation

#### Purge Eligible

The derived read returning the event id values eligible for the cascade: delegates to Retention Window's read-time purge eligible projection and maps each retention to its event; evaluates no clock, has no rejection arm. Distinct from `RetentionWindow.purge_eligible`, the constituent projection over retention id values.

Kind: Operation

#### Purge Event

The action that coordinates the cascade for a retention-elapsed event: seals the event if it is in the unsealed tail, requires the retention to be resolved, purges the retention record, writes the destruction record, and delegates destruction of Event Log's data field and the attestation's proof to the shredding-class erasure mechanism, branching on the reported outcome. Destroys nothing itself, disposes of no seal, re-seals nothing. Returns ok, not-known, [Not Eligible], [Retention Unresolved], [Cascade Failure] carrying the step, or — where a Legal Hold is composed — [Under Legal Hold].

Kind: Operation

#### Audit Record

The composition's emergent output, produced by [Read Record]: the single consolidated structure the four atoms together present for one event — the event bound to its attestation, its retention and its seal coverage. No constituent presents it alone.

Kind: Type

#### Recording Failure

The composition's rejection for *a store refused the write*, carrying the step from [Record Action] only: on any constituent storage-failure — nothing committed at step 2, a partial state after the attestation at step 3 or 4 — and as the lease's terminus between steps 2 and 4; from [Seal Now], bare, when the seal store would not persist a computed proof or its coverage entry. The surface that failed is a store, not a mechanism.

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

The composition's rejection from [Seal Now] when the mechanism could not compute a proof, carrying the constituent's `(reason)` unchanged: a transient outage or a standing preconditions failure, told apart by the reason. Not a malformed request (invalid-request) and not a store refusal ([Recording Failure]). No coverage entry is written and sealed through does not move.

Kind:       Member
Member of:  the seal rejection
Role:       Rejection
Projection: mechanism-failure

#### Cascade Failure

The composition's rejection from [Purge Event] when a store or the seal mechanism refuses mid-cascade, carrying the step: hold, when the hold read answers nothing (the gate fails closed, since the step after it is irreversible), leaving nothing changed; in-flight, when the event's critical section is held by another holder, writes nothing and leaves whatever the holder is doing to it; seal and step-1 leave nothing changed and the event on [Purge Eligible]'s list; step-2 and step-3 leave the retention *Purged* over an incomplete cascade, invisible to [Purge Eligible] and re-driven by the reconciliation scan. On a lease host, the cascade's terminus after step 1.

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

The composition is the structural form of what every major audit regime requires: SOX section 404 (internal control over financial reporting) and section 802 (records retention); HIPAA section 164.312(b) (audit controls) and section 164.530(j) (documentation retention); PCI DSS Requirement 10 — 10.2, 10.3, 10.5, 10.7; 21 CFR Part 11 (ALCOA and ALCOA+); SEC Rule 17a-4 and FINRA Rule 4511 (composing with Storage Tier); ISO/IEC 27001 clause A.12.4.1–4 (the clock-synchronization control via Trusted Timestamping); GDPR Articles 30 and 32; eIDAS (EU 910/2014) qualified preservation, with anchoring instant from a qualified TSA as the time anchor; DoD 5015.02-STD; NIST SP 800-92; Basel III BCBS 239. The four atoms carry their own standards inheritance. It inherits from Daniel Jackson, *The Essence of Software* — a composition is the wiring of freestanding concepts, not a new primitive; from the audit-grade systems literature — COSO, COBIT and SOC 2 name attribution, integrity, retention and event recording as the four pillars the frameworks assume but never specify; and from Schneier and Kelsey 1999, *Secure Audit Logs to Support Computer Forensics*, the original formal framing of cryptographically protected audit logs.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — audit-trail.tla + 2 twins (cascade; scan first half) and audit-trail-record.tla + 4 twins (record action; scan second and third halves) and audit-trail-binding.tla + 2 twins (binding-set predicate against an in-flight cascade) and audit-trail-abandon.tla + 1 twin (a holder that abandons a call and returns), re-derived against the fresh-reader gates of 2026-10-01
last gate: 2026-08-25 — Final Critique 11, fresh reader — clean

open:
- 2026-08-30-d · refining · Invariant 8 liveness; the scan's first half · a delegation whose outcome record was never written is re-driven "until a `destroyed` outcome lands" against content the mechanism may only ever answer `destruction-failed` for → an *abandoned* record under the operator identity after a declared bound, the arm degrading to *surfaced* (the already-destroyed case closed by erasure mechanism 7a on 2026-10-01; what remains is a mechanism that only ever answers `destruction-failed`); contract-shaped — ripples to every composer that transcribes Invariant 8's unconditional lawfully-destroyed-versus-missing distinction, own round
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/audit-trail.md`.

- **2026-10-02 — Round 18 under the finding-kind template: ten cures, one record.** *Chose:* a no-answer arm on [Purge Event]'s step-0 read (`seal`) and step-0½ read (`step-1`), so neither lands `not-known` or `retention-unresolved` (purge event step 0.11, purge event step 0½.6); an expiry gate on the serialization of Concurrency 3a, since a re-drive runs under a leg's longer lease and a stalled cascade could write over a membership taken after its serialization had passed (Concurrency 3c); a seal term in the closure floor under per-event cadence, the two nested [Record Action] calls each sealing inside the leg's lease; the hold-release window counted from the first run that reads no active hold, not from a release instant a caller may have backdated (First half 11); a live member of a partly-purged seal read under Invariant 5.4 as discharged by the destruction record, so Check 3.3 and Check 5.10 no longer ask for a seal no verifier can re-present (Invariant 5.4, Check 3.3); the four constituent instances dedicated to this composition (Composes 4a); an orphan's beyond-horizon report allowed beside its live intent (Compensation 11); a hold's release restarting the window in the one rule every reader of the window takes it from (Composition-level invariant 1c); the closure floor pricing three sealing record actions at twice the seal bound; one rule that sweeps the no-answer arm over the rest of [Purge Event]'s reads (purge event 8). *Recorded, not cured:* [Read Record]'s `unsealed tail` is the derived index's reading and may lag a seal whose coverage entry failed to land until the next [Seal Now] rebuild (Composition state 5, seal now 13); [Verify Record] locates the covering seal through the coverage ranges with rebuild-on-miss (Composition state 2), and a presentation short of the seal's record set surfaces `failed-verification(seal-record-set-mismatch)` as a finding about what was presented (verify record step 5.2), so a caller who verifies in that window is told the presentation is short, not that the record was altered; owner: the deployment's alert on a refused coverage write (seal now 24). *Over:* a seal-store read on every read of an unsealed event, a hold-release instant taken from the Legal Hold store as stated, and a leg-owned serialization separate from the cascade's. *Because:* each cure closes a state the page permitted and a model or a rule could reach; the record states a behavior the page already declared for derived indexes, and a cure would add a seal-store read to every read of an unsealed event. Not changed: the refining and rhetorical findings of the round, held for the round's close.
- **2026-10-01 — The page declares the gates and arms a fresh reader found it assuming.** *Chose:* the legal hold read under the cascade's own section before step 0 with placement serialized against it (purge event 5c, Capability requirement 7), a held cascade left open and uncounted until release (First half 9, First half 10); a `cascade-failure(in-flight)` arm for a held section; the third half placing under the policy step 4 would have resolved (Third half 15); [Seal Now] rebuilding the ranges before it reads `sealed through`, the slice reference encoding both bounds (seal now 13, seal coverage 13); a death-detected host bounding its live holders (Per-act critical section 10c, 10d, External check 10); [Verify Record] re-reading retention before returning a non-verified outcome (verify record 5, 6). *Over:* leaving each to the implementation and to the models, each of which supplied it. *Because:* a third fresh reader's gate found seven places where two implementations of the page diverge and the page was silent; the models carry none of the seven and say so in their NOT MODELED lists. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — A bound covers every holder, a retry has a terminus, and the constituent invariants are read over what is not destroyed.** *Chose:* the death-detected bound on a scan leg as well as an invocation, with a timed-out call landing the step's storage-failure arm (Per-act critical section 10c, Per-act critical section 10d, Per-act critical section 10e); one attempt per finding per run for a refused compensating record action, retried next run and alerted on at the second (Third half 11, Compensation 15, Compensation 16); Invariant 5.1 and Check 3.3 read over events not yet purged, with the destruction record discharging the proof and record-set invariants for a purged one (Invariant 5.4); a hold being an active one. *Over:* an in-run retry loop with no end, a bound on invocations alone, and a sentence claiming every atom invariant over destroyed content. *Because:* a fourth fresh reader's gate found each of the four, two of them opened by the previous pass's own cures. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — The second half re-derives its predicate under the section, a hold is a standing, and the sealing lock is shared and reports death.** *Chose:* the second half re-reading the binding set for the orphan's attestation id under the critical section before it writes (Second half 16); a *held* event standing beside retained and lawfully destroyed, with the audit checks exempting it (Invariant 8.1a, Invariant 8.2a, Check 5.1, Check 7.5, Check 7.6) and quiescence left as it was; the sealing lock shared by every process and telling its next taker whether the last holder died, the rebuild of the seal coverage ranges keyed on that and on a refused coverage write (Concurrency 1a, Concurrency 1b, seal now 13, External check 11). *Over:* pre-checking only the compensation marker, a quiescence that no hold-bearing instance could reach, and a rebuild triggered by this process's own restart alone. *Because:* a fifth fresh reader's gate found each, two of them opened by the cures of the pass before; the self-gate before the reader also closed a section-kind start check, a key namespace and a third-half policy refusal. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — The seal coverage rebuild is keyed on a mark every process sees, and a leg's lease counts its own pause.** *Chose:* [Seal Now] setting an uncovered mark on the shared sealing lock before it seals and clearing it only once the coverage entry has landed or the seal is known to have written nothing, the next taker rebuilding when the mark stands or is unknown (seal now 13, 15, 16, Concurrency 1b); the longest pause between a lease check and its write counted into compensation closure latency, as it is into both completion bounds (compensation closure latency 2). *Over:* a rebuild keyed on a process's own restart or flag, and a leg bound sized from observed closure time. *Because:* a sixth fresh reader's gate found a second process could seal a slice the first had sealed but not covered, and a stalled leg could write after its lease passed to the next run. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — The per-act critical section is a Lease on every host, and the sealing lock is one too.** *Chose:* the per-act critical section held as a [Lease](../atoms/lease.md) on every host, the host never freeing it on a belief the holder died (Per-act critical section 1, 3, 4); the death-detected kind, its timeout rules and its start check and external check withdrawn; the sealing lock a lease of a declared seal completion bound, sealed through read from the coverage ranges under it and never from a process cache (Concurrency 1c, seal completion bound, seal now 17, seal now 18); a held event answered as purged on both read surfaces (Invariant 8.2b). *Over:* a host that frees a section when it believes its holder died, a mark the next taker is told about by a death nobody can observe, and a held event left without a read answer. *Because:* the Lease atom forbids ending a grant on a belief of death (Lease Invariant 3.1, Lease Invariant 3.2), the page re-derived lease semantics in prose and had admitted the one host the atom rejects; a seventh fresh reader's gate found the double placement that host allows, and that the seal lock's mark could not see an in-flight seal. This supersedes the death-detected rules of the 2026-10-01 decisions above and the 2026-08-30 reconciliation decision's death-detected host. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — The sealing lock's holder stops writing at expiry, the horizon is checked at start, and the erasure mechanism leaves the read surfaces answering.** *Chose:* [Seal Now] issuing no write once the sealing lock's lease has expired and landing [Recording Failure] (seal now 19, seal now 20); the instance refusing to start unless horizon exceeds compensation window (Instance start 21, Instance start 22); the erasure mechanism leaving Event Log's read returning every event and Actor Identity's read answering the surviving fields (erasure mechanism 6a, erasure mechanism 6b). *Over:* a sealing lock that frees without gating its holder's writes, a horizon nobody checks against the window, and a read tolerance the binding set silently assumed. *Because:* an eighth fresh reader's gate found a stalled holder could seal over a slice the next taker had covered, a policy selector could give audit events a retention shorter than the window and leave every orphan reported and none compensated, and a decrypt-on-read log could omit shredded entries and kill the binding set. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — A holder that abandoned a call keeps its lease to expiry, the per-act lease is audited, and a hold placement is a bounded holder.** *Chose:* a holder that abandoned a constituent call releasing nothing before the lease's instant, for the per-act section and the sealing lock (Per-act critical section 2a, Concurrency 1e); the sealing lock taken by [Seal Now] alone (Concurrency 1d, Concurrency 8); the per-act lease shared by every process and audited by an external check (Per-act critical section 1b, External check 11); a hold placement holding the section as a lease of purge completion bound, issuing no write after expiry and waiting rather than racing (Capability requirement 7c, 7d, 7e); the hold read made after the not-known test and counted a composition-built query (purge event 5c). *Over:* releasing on return whatever the holder abandoned, a lock whose conformance nothing checked, and a hold read keyed on an id nobody had validated. *Because:* two fresh readers of the ninth round, reading in parallel through different lenses, found five gaps between them; `audit-trail-abandon.tla` reaches the early-release state and its twin rejects it. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — An abandoned call is any call to any store, a run's enumeration is inside closure latency, and the lease's length and premise are audited.** *Chose:* the abandoned-call rule covering a call to any store or mechanism, the erasure delegation and the Legal Hold store included, with the host releasing only on the holder's release or at the instant (Per-act critical section 2, 2a, 2b, Capability requirement 7f); the rules that bar a later write after expiry scoped to truth-bearing writes, so a record action past step 4 completes its indexes and its per-event seal (Per-act critical section 7, 8, 9c); compensation closure latency counted from a run's start, its enumeration included, with a run starting within one cadence of the last start (compensation closure latency 3, reconciliation cadence 1a), the frozen liveness inequality keeping its three terms; the holder value minted fresh for each attempt (Per-act critical section 1c); the lease's length, the holder and the no-late-landing premise audited (External check 11, External check 12). *Over:* a release rule that fired on any return, a closure latency that began at the take, and a lease whose length and premise nothing checked. *Because:* the tenth round's two readers found, between them, a held event destroyed by a delegation abandoned inside the old lease, two rules that could not both hold on a record action past step 4, an orphan reached after a long enumeration while every start check passed, a fixed-TTL lock service that passed every external check, and a holder value that let a stalled run read the next run's lease as its own. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-10-01 — A run ends at the first refusal that left an orphan, the serialization is a lease, and an unreadable hold fails closed.** *Chose:* the scan ending a run at the first reconciliation-path refusal that left an attested orphan (Invariant 1.10), so a standing outage mints one orphan per run and not a tree of them; the serialization discharging Concurrency 3 a Lease of purge completion bound under the abandoned-call and fresh-holder rules (Concurrency 3a, External check 10); [Seal Now] presenting a fresh holder value per attempt (Concurrency 1f); the uncovered mark stored apart from the lock's grant so it outlives the lease (Concurrency 1b1); a hold read that does not return the holds landing `cascade-failure(hold)` with no step executed (purge event 5e); [Read Record] re-reading retention when the data is unreadable under *Retained* (read record 4.5, 4.6); purge event 0.5 restated on sealed through so it states the same condition as 0.2. *Over:* a retry ceiling per run, a hold read that proceeds on silence, and a lock whose mark dies with its lease. *Because:* each of those left a reachable state with no terminus or a destruction under a hold nobody read; the Lease atom's grant-ends-only-at-release-or-instant rule and the frozen *a stamp from another seam never decides a write alone* decide the first three, and fail-closed is the only arm that cannot destroy what an order forbids.
- **2026-10-01 — The pair's source is keyed on the destruction record, the coverage entry is durable, the outlived test measures at one seam, and a leg's lease counts the run's elapsed time.** *Chose:* event to attestation split on whether the destruction record exists, not on the retention's state, so an entry lost between step 1 and step 2 is rebuilt from the still-readable payload (event to attestation 2, 3); Durability 8 on the coverage entry, since sealed through is the maximum of a derived index whose latest entry is not an observable miss; the outlived test measuring from the invocation's own reading taken before the attest call, two readings at one seam with no allowance and never reading the age low (record action step 2.12, Term outlived, Clock source 1); the first half running first and the circuit break ending only the second and third halves (Reconciliation 1a, Invariant 1.10); a scan leg's lease sized as compensation closure latency less the run's elapsed time at the take, a leg whose remainder does not exceed its work bound skipping the act (Per-act critical section 13a, 13d, Reconciliation 5a); original event payload named as the record set re-presented, the covering range's presentation; [Seal Now] releasing the sealing lock on return; Instance start 6 conditional on the time arm; step 2.9 refusing only a section another holder holds. *Over:* reading the attestation instant through Actor Identity's whole-store read on every call, a rebuild that enumerates the seal store at every take, a fifth closure-sum term for enumeration, and a verify argument that is one event's payload with the range fetched by the composition. *Because:* each was a rule resting on a source the page never named or on an origin two readers placed differently; the Lease atom's rule against a caller subtracting across two seams, and the frozen *a derived index is trustworthy only where a miss is observable*, decide them. Left as they stand and rated: the destruction-failed terminus (Ledger line 2026-08-30-d), and the no-late-landing premise, which stays an audited External check 12 as decided on 2026-10-01.
- **2026-10-01 — Scan legs run concurrently, the erasure mechanism is idempotent over destroyed content, each holder names its lease call, a silent lease host reads as expired, and an outage extends the window.** *Chose:* no scan leg's start waiting on another leg's closure, within a half or across halves, so a backlog of re-drives never eats a later leg's lease, with a skip under the remainder rule surfacing as a deployment-fault alert (Reconciliation 1a, Per-act critical section 13d, 13e); the circuit break reworded to stop only the starting of compensating records (Invariant 1.10); a mechanism asked about already-destroyed content reporting destroyed (erasure mechanism 7a); `try_take` for a record action, a cascade and a scan leg, `take` with a declared arrival term for a hold placement and [Seal Now] (Per-act critical section 15, 15a, Concurrency 1g); a lease call that returns nothing read as expired and a take with no answer at step 2.6 landing as mid-record expiry (Per-act critical section 16); the pause between a reading and the take it sizes counted inside each completion bound; Instance start 23 relating the purge bound to the seal bound; a store outage extending a finding's window, the outage interval recorded, quiescence read per act, Check 2.12 reading the extended window (Composition-level invariant 1c, 1d). *Over:* ordering the halves serially, a per-run cap on re-drives as a new knob, an abandoned-record terminus for the already-destroyed case, and a pause of the window clock with no record. *Because:* a serial run cannot meet a window it does not budget, a cap is a tuning knob the corpus has no number for, and the already-destroyed answer is the only one under which the page's own *permanently unclosable* state cannot arise; the Lease atom's two-ways-to-end rule and the frozen *a derived index is trustworthy only where a miss is observable* decide the rest. Ledger line 2026-08-30-d keeps only a mechanism that always answers `destruction-failed`.
- **2026-10-01 — A call pause bound is a knob, a run's first compensating record goes alone, an outage restarts the window over every dependency, and the scan has a scheduler.** *Chose:* a nineteenth knob, call pause bound, that every completion bound exceeds and includes, Term lease reading *expired* unless the host's remaining term exceeds it, the outlived test and the leg's lease sizing each subtracting it, so a write on a live lease lands inside it and a grant ends inside the bound it was counted from (call pause bound 1, 2, Term lease, Term outlived, Per-act critical section 13a, Instance start 18, 24, 25); a run issuing its first reconciliation-path [Record Action] alone and starting no other until it has returned success or after a refusal that left an orphan, the probe counted inside closure latency (Invariant 1.10, 1.11, 1.12, compensation closure latency 4, Reconciliation 1a); a store outage covering every dependency a leg or a cascade calls and restarting the finding's window at the later of its creation and the outage's end, with Check 2.4, 2.5 and 2.12 reading the audit edge from that restart (Composition-level invariant 1c, Term audit edge, External check 13); the lease-host-silence rule over every lease the composition takes, a hold placement's and the Concurrency 3 serialization's call kind and refusal arm (Per-act critical section 15a, 15b, 16, Concurrency 3b); a scan scheduler and a sealing lock each gated at Instance start (reconciliation cadence 6, Instance start 26, 27); an upper edge for the first half at horizon (First half 12, Boundary one 6); a re-declaration obligation when a leg's remainder falls short (Per-act critical section 13e); the scan's reading taken before its enumeration (Reconciliation 5); invalid-credential on the operator alerted (Compensation 17). *Over:* a closure-sum pause term, a cap on concurrent legs, a pause of the window clock, and leaving the pause as an unnamed ingredient of each bound. *Because:* three readers in three rounds recomputed the closure sum and found the pause between a reading and its take uncounted, and a named knob is the one form a start check can read; concurrent legs and a run's circuit break contradicted each other until the first record goes alone; a restart gives the closure sum its full arithmetic after an outage where an extension did not. Left as recorded: the no-late-landing premise stays audited (External check 12) with the margin now in the page's own seam, the verify presentation's shape (decided 2026-09-30), and Ledger lines 2026-08-30-b and 2026-08-30-d.
- **2026-10-01 — The first half's upper edge is the audit instance's retention, the mark is cleared by its own holder, skew counts twice, and a start check reads a measured enumeration.** *Chose:* the first half's upper edge stated as the retention policy of the audit instance it reads, which keeps everything the half reads indefinitely, and the horizon cut withdrawn (First half 12, Boundary one 6); the uncovered mark set and cleared by compare against the holder's own value on a live lease, the clear inside the seal completion bound (seal now 22, 23); the actor registry among the outage dependencies, an outage defined by calls failing past the call pause bound, the restart limited to an outage that began before the window elapsed, a no-answer attest landing `recording-failure(step-2)` and a no-answer cascade take landing `cascade-failure(in-flight)` (Term store outage, Composition-level invariant 1c, record action step 2.13, purge event step 0.10); the closure sum's skew term doubled, since the scan's reading may run an allowance behind and the widening adds it again, the walkthrough's sum recomputed to 19 minutes 4 seconds; a leg starting a [Record Action] only above that action's bound plus the call pause bound (Per-act critical section 13f); the closure floor four record action bounds, the placement and the probe included, and Instance start 18 and 19 reading a measurement taken at start (Term closure floor, Term measured enumeration, Instance start 18, 19, 28); the scan calling [Seal Now] every run under per-event cadence (seal cadence 3); the knob and check counts propagated. *Over:* a horizon cut that strands a held or outage-delayed entry, a clear any holder may issue, a declared enumeration knob, and leaving per-event retry to the next record action. *Because:* the frozen *every leg names both edges* is met by naming the upper edge the audit instance's retention gives, which for the first half is none; a stale holder's clear reopens the two-seals state the mark exists to prevent; a start check can read a measurement where it cannot read a declaration that grows; an idle per-event trail has no timer, and the scan already has a scheduler (reconciliation cadence 6). Not changed: the registry's behaviour under attest is the Actor Identity atom's silence, not this page's; the verify presentation's shape stands as decided.
- **2026-10-01 — A refusal carries the committed ids, the lease margin is two calls, the per-event retry is an alert and the interval cadence has a driver.** *Chose:* `invalid-request(step-3)`, `invalid-request(step-4)`, `recording-failure(step-3)` and `recording-failure(step-4)` carrying the committed attestation id and event id as an additive payload, so no composer that transcribes the arm token breaks (record action step 7.15, 7.16), which closes Ledger line 2026-08-30-b; Term lease reading live only above twice the call pause bound, the check's answer and the write being two calls, with the completion-bound check, the leg's start margin and the closure floor carrying it (Term lease, call pause bound 2, Instance start 25, Per-act critical section 13f, Term closure floor); a leg taking its section before it waits on the probe (Reconciliation 1b); a failed per-event seal standing as the step-6 alert until a later record, purge or [Seal Now] seals it, withdrawing the scan's per-run [Seal Now] of the previous entry (seal cadence 3); a cadence driver for an interval-based cadence that survives a process loss, fires at start and counts the events arm as the log tail less sealed through, gated at Instance start (seal cadence 4, 5, Instance start 29); Durability 6 holding the pair, the membership and the outcomes for the life of the seal record; overlapping outages read by the latest end (Composition-level invariant 1c); *no answer* defined for any call; the sealing lock, the uncovered mark and the probe given Terms. *Over:* the scan driving a per-event seal each run, which put a seal's time and failure in the closure the scan budgets; routing the step-3 and step-4 payload as a corpus sweep, since the payload is additive; and a margin of one call. *Because:* every seal call the scan adds is up to twice the seal bound inside a lease sized without it; an additive carrier needs no composer to change while leaving a retry able to find what the first attempt committed; and a check followed by a write is two calls under the page's own definition of the knob. Left as decided: the no-late-landing premise (External check 12), the verify presentation's shape, and Ledger line 2026-08-30-d.
- **2026-10-01 — A leg's in-lease reads are inside its work bound, every constituent call has a no-answer arm, an orphan attestation is a non-goal, and the horizon is the lesser of two.** *Chose:* the second and third halves' work bound counting the binding-set re-read and the narrated read as two further measured enumerations, the start check reading three, the measurement covering the retention store too, and a start declined under 13f taking the 13d consequence — alert, re-declare, re-run Instance start 16, 18, 19 and 28 — and skipping the act (Term work bound, Term measured enumeration, Instance start 18, 28, Per-act critical section 13e, 13g); a call that answers no answer landing the step's own arm and never re-issued inside the lease (record action step 3.7, 4.9, purge event step 1.6, 2.8, seal now 24, Per-act critical section 17), a caller not retrying `recording-failure(step-4)` (record action step 7.17); the mark cleared against the value the taker last read under its live lease (seal now 23); an attestation no event binds stated as a non-goal — no retention placed, none destroyed, its retirement left to Erasure Tombstone *(forthcoming)* — and the Summary's lifetime claim narrowed to events (Non-goal 11); horizon the lesser of the retention periods of `audit.compensation` and `audit.reconciliation` events (Instance start 21, Term horizon); the cadence driver counted among the capability requirements and audited (External check 13); Second half 13 and Durability 5 reconciled; the Per-act rules put in order. *Over:* a work bound that stops at the writes, a no-answer arm only for attest, placing a retention on the orphan attestation, which Composes 9 forbids and which has no event to cascade through, and one horizon read from the compensation event alone. *Because:* a re-read that runs under the section is time the lease spends, and a rule the leg cannot meet must say what it does instead; a call whose answer never came may still land, so repeating it can bind two events to one attestation; the corpus's own rule is that a record this page cannot retire is named as such and handed to the pattern that will. Not changed: the compare-and-clear's stale-mark cost on an idle firing, the horizon comparison's allowance widening, and the acronym glosses, all refining.
- **2026-10-01 — The leg's reads are one enumeration, the read surfaces answer no answer rather than not-known, and the nested record action sits inside the leg's lease.** *Chose:* the binding-set re-read, the marker reads and the narrated read served from ONE enumeration read under the section (Second half 17), the work bound counting one measured enumeration under the lease and the start check two in all — one before the take, one under it — which replaces the three of the previous entry; the measured enumeration taken as the audit log followed by the destruction-record read, the order Second half 15 forces, against the attestation store and the retention store (Term measured enumeration, Instance start 18, 28); the walkthrough recomputed to 214 seconds; a [Record Action] a leg starts completing its writes inside its bound and the leg's lease (Per-act critical section 13h); [Read Record], [Verify Record] and [Purge Eligible] answering no answer, never not-known, an unverifiable or an empty list, when a constituent read answers none, and Invariant 6.1 holding while the reads answer (read record 5, verify record 7, purge eligible 7, Invariant 6.1). *Over:* three enumerations in the lease, an `unavailable` arm on each read surface, which adds a token every composer would transcribe, and a nested lease for the leg's record action. *Because:* the closed-state markers are derived from the same log pass, so one read serves them all; a read surface that cannot see a store has no true answer to give, and the call-level no answer is the one already used for every other call; the premise that a record action completes inside its bound makes the leg's lease the outer fence without a second lease. Not changed: Ledger line 2026-08-30-d, the horizon comparison's widening and the acronym glosses.
- **2026-09-30 — The binding set reads payloads by readability, not retention state, and reads destruction records second.** *Chose:* the first enumeration takes the attestation id from every payload the full enumeration reads, whatever the retention state, and the destruction records are read after it (Second half 14, Second half 15); `record set match` is declared a deployment requirement with its own external check (Capability requirement 5, Capability requirement 6, External check 8). *Over:* keying the first enumeration on `live`, and leaving Tamper Evidence's host obligation to the atom's own page. *Because:* a fresh reader found that between [Purge Event] steps 1 and 2 a retention reads *Purged* over a readable payload with no destruction record yet, so the old keying held the attestation in neither enumeration and the scan compensated a lawfully held attestation; `audit-trail-binding.tla` reaches it and both twins (retention-keyed, records-first) fail it. The same reader found the record set match obligation declared nowhere on the page. Ledger 2026-08-30-b and 2026-08-30-d stay open.
- **2026-09-30 — The page states the discipline its model had to supply.** *Chose:* the pause between a lease check and its write inside both completion bounds; a scan leg's lease at compensation closure latency, a leg that stops writing at expiry; the cascade taking its section before step 0 and adopting what landed at steps 2 and 3; a record action's step 3 reading compensated attestations under the section it takes after the attestation; the liveness arithmetic budgeting one dead scan run; the first half writing no intent; the audit log's durability a declared capability requirement. *Over:* leaving each to the model alone. *Because:* a fresh reader's gate found that the model supplied each and the page said none, and an implementation built from the page alone breaks Invariant 2.4a, Second half 13 or Invariant 1.4; Event Log's own Durability 4 requires the last. Closes the 2026-08-30-c ledger line.
- **2026-09-30 — `invalid-request` carries the step, as `recording-failure` does.** *Chose:* `record_action` refuses `invalid-request(step)`, step-1 through step-4, and a caller is told not to retry on step-3 or step-4 (record action step 7.9 through 7.13); every composer that transcribes the arm reads the step. *Over:* a bare token, and a second refusal code. *Because:* the bare token landed at steps 1–2 with nothing committed and at steps 3–4 after the attestation and the event committed, so a caller told *invalid-request* could retry a committed act and mint a second attestation; the frozen rule that a composition's own rejection arm carries the retry bit, and the precedent `recording-failure(step)` already set, decide it. The cold gate of 2026-09-30 found it; closes the 2026-08-30-a ledger line.
- **2026-09-27 — A finding is narrated once, and the cascade's re-drive reads what already landed.** *Chose:* a finding's intent carries its subject and id, and the scan reads *narrated* under the critical section before writing one (Compensation 9 through 11); the pre-check names the destruction record and a destroyed outcome, the reads *proceed as landed* already named. *Over:* leaving the next run to re-detect the finding and narrate it again, and a pre-check list that left a re-driven cascade free to rewrite its destruction record or re-delegate a completed destruction. *Because:* the cold regeneration of 2026-09-27 wrote two intents for one orphan and two for one unretained event whenever the repair failed after its intent landed, against one record per finding (Compensation 2).
- **2026-09-11 — Rewritten in GRACE lang v0.31; nothing but language changed.** *Chose:* labelled rules in fenced blocks, rationale under `WHY:`, terms declared where they are used, the Ledger and the invariant numbers unchanged; the instance-start conditions given one owner (the section titled *Instance start*), the class boundary and the scan's halves cited by label from every site that used to restate them. *Over:* the prose spec. *Because:* the migration plan — the corpus is being rewritten in the language, and a spec whose obligations have one owner each is what the reverse diff reads.
- **2026-08-30 — The reconciliation is one writer per act, bounded at both edges, and the scan writes its intent before its repair.** *Chose:* a per-act critical section keyed by the act's id (attestation id for a record action, event id for a cascade), declared as an instance capability requirement with lease semantics, held by the invocation from its first write and taken by every scan half before its pre-check; two completion bounds (record action completion bound, purge completion bound) below which no half examines anything and at which the invocation yields; a horizon at which the second half reports rather than re-compensates, once, behind a reported beyond horizon marker; compensation closure latency and clock offset allowance declared, the window measured from the finding's creation, the three-term inequality checked at start; the scan reading its own now once per run; `audit.reconciliation` written one record per finding before the act it announces, under a declared reconciliation operator credential; the scan as the sole writer of an orphan's compensation. *Over:* a third half whose placement raced the invocation's own step 4 under no shared key; halves with no lower edge, compensating attestations and events whose [Record Action] was still between two steps; a window measured from detection and an inequality with one term; a findings record of unbounded size and unstated position. *Because:* two writers over one act land two records the seal protects forever, a leg with no lower edge reads work in flight as an orphan and corrects it, and a liveness promise is arithmetic or it is nothing (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *An outcome is sized before the intent*, and *Capability provenance*; with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md` and the section titled *Recovery commits under a declared service identity* in `pressure-testing.md`). The four contract-shaped sites — invalid-request's position, `recording-failure(step-4)`'s event id, the Event Log durability obligation, Invariant 8's abandoned terminus — are routed as open lines rather than fixed, because every composer transcribes them. *Round 2, same day:* the inequality gained its skew term and its closure latency (the whole closure, intent through compensation, or a cascade round-trip); the per-act critical section gained its non-lease branch — a leg skips a held act and never blocks, a host that cannot detect death must lease, and the non-lease terminus is *proceed as landed* behind step 4's pre-check; the lease terminus is confined to steps 2–4 inclusive, an invocation past step 4 completing its index writes; the beyond-horizon report and the recording-half detector both gained the horizon; and every *all succeed or none* sentence over un-withdrawable writes was restated as ordered writes plus compensation. The five *until a destroyed outcome lands* loops are bounded by open line 2026-08-30-d rather than given a terminus here.
- **2026-08-24 — Seal supersession is extracted to a forthcoming Seal Lifecycle composing pattern, not absorbed.** *Chose:* remove the Reseal action, `superseded_by`, `reseal_on_purge` and every current-seal qualification from the canonical composition; name Seal Lifecycle as owner of re-sealing partly purged seals, mechanism rotation, and supersession bookkeeping. *Over:* keeping the mechanism added at Final Critique 6. *Because:* which seal is current over a range two seals cover is new truth no constituent store carries and no rebuild replays — it clears the extraction gates, and it had spread through three invariants, three checks and four cards.

NOTE: End of Audit Trail.

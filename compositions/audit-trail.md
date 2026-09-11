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

It does this by wiring four simpler patterns into one queryable record: an add-only event log (what happened), cryptographic attribution tying each event to the actor who performed it (who), tamper-evident sealing that makes any after-the-fact change detectable (has it been altered), and a retention policy that fixes how long records are kept (kept long enough). None of the four answers the full question alone; stacked, they produce a record that is observable, attributable, tamper-evident, and lifetime-bounded, and the stack adds guarantees none has alone: every event is logged, attributed, retention-tracked, and sealed at once, and a query on any kept event returns a definite answer that tells a lawfully destroyed record from a missing one.

Two of the four patterns offer no way to delete anything, which is what makes them trustworthy. So the end of a record's life is not a deletion: the composition records the lawful end of the retention period, marks on the covering seal exactly which of the records it commits to were destroyed, and hands the destruction of the stored content to whatever erasure mechanism the deployment has declared. What survives is the proof that the record existed and was destroyed lawfully — which is what the regulator asks for.

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

```text
Composes 1: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 2: EXACTLY ONE Actor Identity instance MUST serve the composition.
Composes 3: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 4: EXACTLY ONE Tamper Evidence instance MUST serve the composition.
Composes 5: The composition MUST call ActorIdentity.attest at [Record Action] step 2 alone.
Composes 6: The composition MUST call ActorIdentity.verify at [Verify Record] step 3 alone.
Composes 7: The composition MUST read an attestation's surviving fields through Actor Identity's declared read surface.
Composes 8: The composition MUST NOT delete an attestation.
Composes 9: The composition MUST call RetentionWindow.place_under_retention at [Record Action] step 4 and at the third half's compensating placement alone.
Composes 10: The composition MUST call RetentionWindow.purge at [Purge Event] step 1 alone.
Composes 11: [Purge Eligible] MUST delegate eligibility to RetentionWindow.purge_eligible.
Composes 12: The composition MUST NOT evaluate an eligibility clock.
Composes 13: The composition MUST call TamperEvidence.seal from [Seal Now] alone.
Composes 14: The composition MUST call TamperEvidence.verify at [Verify Record] step 5 alone.
Composes 15: The composition MUST NOT write an entry into the seal store other than through TamperEvidence.seal.
Composes 16: The composition MUST NOT dispose of a seal.
Composes 17: The composition MUST NOT seal a range some seal covers.
```

Terms › `audit log`: the composition's Event Log instance.

Terms › `attestation store`: the composition's Actor Identity instance.

Terms › `retention store`: the composition's Retention Window instance.

Terms › `seal store`: the composition's Tamper Evidence instance.

Terms › `surviving fields`: an attestation's `attestation_id`, `action_ref`, `actor_ref` and `attested_at` — Actor Identity's five-field record less the `proof`.

### Instance capability requirement

```text
Capability requirement 1: The wired Event Log instance MUST expose the open-upper-bound read.
Capability requirement 2: The deployment MUST alert on invalid-query from a composition-built query as a deployment fault.
Capability requirement 3: The composition MUST NOT surface invalid-query from a composition-built query as an outcome of any action.
```

Terms › `open-upper-bound read`: `EventLog.read` over a sequence-number range beginning at a given `sequence_number` with no upper bound.

Terms › `full enumeration`: the open-upper-bound read beginning at sequence 1.

Terms › `composition-built query`: the open-upper-bound read, and the singleton range read of event_to_sequence 5 — queries the composition builds from its own indexes, which no caller input reaches.

WHY:
Eight procedures issue the read and none has a substitute — [Seal Now]'s head read, [Record Action] step 5's read-back, the rebuilds of `event_to_sequence`, `event_to_attestation`'s live entries and `compensated_attestations`, the scan's binding set and third half, and the auditor's own enumeration at Check 2 — and the last is why the requirement is a deployment obligation: an instance that cannot serve it cannot be audited for orphan-freedom at all. No caller input reaches any of these queries (Capability requirement 3).

---

## Composition logic

### Composition state

Eight elements, each carrying the Contract classification of [`execution-contract.md`](../execution-contract.md) §Composition state. Five are wholly derived indexes — `event_to_retention`, `event_to_sequence`, `sealed_through`, `compensated_attestations`, `reported_beyond_horizon`. Two split — `event_to_attestation` is derived for live events and extraction-pending for purged ones; `seal_coverage` is derived over ranges and carries one extraction-pending per-entry set. One is wholly extraction-pending — `erasure_outcomes`.

Terms › `derived index`: an element regenerated from the constituent stores by the element's rebuild procedure.

Terms › `extraction-pending`: an element carrying truth no constituent store replays, classified against a named proposed atom.

Terms › `rebuild-on-miss`: a read of a derived index that runs the element's rebuild procedure on a missing entry and concludes nothing from the miss itself.

Terms › `retention_state`: the state of the event's retention record — `Retained` | `Purged`; absent where no retention record exists.

Terms › `live`: an event whose `retention_state` != `Purged`.

Terms › `purged`: an event whose `retention_state` = `Purged`.

```text
Composition state 1: EVERY derived index MUST sit outside every action's atomicity surface.
Composition state 2: A reader MUST consult a derived index with rebuild-on-miss.
Composition state 3: The composition MUST treat a lost derived-index entry as a rebuild trigger.
Composition state 4: The composition MUST NOT treat a lost derived-index entry as data loss.
Composition state 5: A derived index MUST NOT claim cross-constituent transactional consistency.
Composition state 6: The composition MUST NOT modify an inserted entry of an insert-only map.
Composition state 7: The composition MUST NOT remove an inserted member of a closed-state marker.
```

Terms › `insert-only map`: `event_to_attestation`, `event_to_retention`, `event_to_sequence`, and the ranges of `seal_coverage`; a `purged_events` set is written by the cascade and is not part of the range.

Terms › `closed-state marker`: `compensated_attestations` and `reported_beyond_horizon`.

WHY:
An index entry is evidence that the truth-bearing writes committed, never a peer write the compensation protocol has to handle. Both sides of every derived mapping are immutable constituent content, so each rebuild is total over what the constituent stores still hold.

- **`event_to_attestation`** — map from `event_id` to the `attestation_id` Actor Identity produced at record time; the auditor's traversal from an event to its attribution. The classification splits by retention state, because the rebuild's source does not survive the cascade.
  ```text
  event_to_attestation 1: [Record Action] step 5 MUST populate event_to_attestation with the event's event_id → attestation_id.
  event_to_attestation 2: WHEN retention_state != Purged:
      event_to_attestation 2a: The composition MUST classify the entry as derived index.
      event_to_attestation 2b: The rebuild MUST take, for EVERY event the full enumeration returns, the event's event_id as the key and the payload's attestation_id as the value.
  event_to_attestation 3: WHEN retention_state = Purged:
      event_to_attestation 3a: The composition MUST classify the entry as extraction-pending against Erasure Tombstone.
      event_to_attestation 3b: The destruction record MUST carry the pair (event_id, attestation_id).
      event_to_attestation 3c: The pair MUST carry the durability obligation of Durability 6.
  ```
  WHY: [Record Action] step 3 writes `attestation_id` into the appended payload, so the live binding is immutable Event Log content. The cascade destroys the payload's recoverability, so for a purged event the binding is destroyed with the thing that carried it, and only a record written before the delegation can carry it ([Purge Event] step 2).
- **`event_to_retention`** — map from `event_id` to the `retention_id` Retention Window produced at record time; the policy the event is held under.
  ```text
  event_to_retention 1: [Record Action] step 5 MUST populate event_to_retention with the event's event_id → retention_id.
  event_to_retention 2: The composition MUST classify event_to_retention as derived index.
  event_to_retention 3: The rebuild MUST enumerate the retention store and re-key each retention record by the record's record_ref.
  ```
- **`event_to_sequence`** — map from `event_id` to the `sequence_number` Event Log assigned at append; the index that makes id-addressed reads possible.
  ```text
  event_to_sequence 1: [Record Action] step 5 MUST populate event_to_sequence with the event's event_id → sequence_number.
  event_to_sequence 2: The composition MUST classify event_to_sequence as derived index.
  event_to_sequence 3: The rebuild MUST re-key EVERY event the full enumeration returns by the event's own event_id.
  event_to_sequence 4: [Read Record], [Verify Record] and [Purge Event] MUST resolve a caller-supplied event_id through event_to_sequence.
  event_to_sequence 5: An id-addressed action MUST read the event by EventLog.read over the singleton range at the resolved sequence_number.
  event_to_sequence 6: The composition MUST NOT ask EventLog.read to select on event_id.
  event_to_sequence 7: The composition MUST NOT ask EventLog.read for a payload predicate.
  ```
  WHY: Event Log declares no read-by-id surface — `read` takes a sequence-number range, a wall-time range or a payload predicate, and routes lookup by payload field to a Reverse Index pattern *(forthcoming)*. Event Log's Outputs declare that every returned event carries its `event_id`, `sequence_number`, `recorded_at` and `data`, so both sides of the map are immutable Event Log content and the rebuild is total; the relation `event_id` ↔ `sequence_number` is one-to-one and mandatory on both sides at quiescence (Event Log Invariants 2, 3 and 6), and a lost entry is a rebuild trigger, never a relation violation.
- **`seal_coverage`** — for each `evidence_id` in the seal store, the contiguous sequence-number range the seal commits to as [Seal Now] cut it, plus a per-entry `purged_events` set the cascade writes; what tells the verifier which record set to present.
  ```text
  seal_coverage 1: [Seal Now] MUST populate seal_coverage with evidence_id → the sealed slice.
  seal_coverage 2: The composition MUST classify the ranges of seal_coverage as derived index.
  seal_coverage 3: The rebuild of the ranges MUST enumerate the seal store and read each evidence record's record_set_ref.
  seal_coverage 4: The rebuild of the ranges MUST NOT issue EventLog.read.
  seal_coverage 5: A coverage range MUST key on sequence_number.
  seal_coverage 6: A coverage range MUST NOT key on event_id.
  seal_coverage 7: Two coverage ranges MUST NOT overlap.
  seal_coverage 8: A coverage range MUST NOT carry a hole.
  seal_coverage 9: The composition MUST classify purged_events as extraction-pending against Erasure Tombstone.
  seal_coverage 10: The cascade MUST record the records-purged fact at event granularity.
  seal_coverage 11: The cascade MUST NOT flag a whole seal_coverage entry as purged.
  seal_coverage 12: purged_events MUST carry the durability obligation of Durability 6.
  ```
  Terms › `purged_events`: the set of `sequence_number`s within one seal's range whose content the cascade has had destroyed.

  Terms › `covering seal`: the `evidence_id` whose `seal_coverage` range contains the event's `sequence_number`.

  WHY: `event_id` carries no ordering, so a range of ids is not an interval. Nothing but [Seal Now] writes a coverage entry, so a hole or an overlap is not a state this composition reaches. A seal covering a thousand events is very often partly purged and partly live — a policy selector gives two events in one range two retention periods — and a whole-entry flag would report a live event as destroyed. No constituent store says *this member was later destroyed*, so no rebuild regenerates the set.
- **`erasure_outcomes`** — for each event over which [Purge Event] step 3 has issued its delegation, the outcome the configured `erasure_mechanism` reported: `destroyed` or `destruction-failed(reason)`.
  ```text
  erasure_outcomes 1: The cascade MUST record the mechanism's reported outcome in erasure_outcomes for EVERY delegation [Purge Event] step 3 issues.
  erasure_outcomes 2: erasure_outcomes MUST address an outcome per event_id.
  erasure_outcomes 3: The composition MUST classify erasure_outcomes as extraction-pending against Erasure Tombstone.
  erasure_outcomes 4: The outcome record MUST land on the event's destruction record.
  erasure_outcomes 5: erasure_outcomes MUST carry the durability obligation of Durability 6.
  erasure_outcomes 6: A destruction-failed record MUST NOT close an entry.
  ```
  Terms › `closed entry`: an `erasure_outcomes` entry among whose records a `destroyed` outcome exists.

  Terms › `open entry`: an `erasure_outcomes` entry that is not a closed entry; open for re-driving.

  WHY: no constituent witnessed the mechanism's report. A lost outcome is not safely re-derivable — re-driving over already-destroyed content may only answer *target already unreadable in a way it cannot confirm* — so losing a `destroyed` outcome can leave a completed cascade permanently unclosable. Four surfaces read the element: First half 3, purge_event step 4.1, Invariant 8.3 and Check 5.8.
- **`sealed_through`** — the most recent `sequence_number` any seal covers.
  ```text
  sealed_through 1: The composition MUST classify sealed_through as derived index.
  sealed_through 2: The rebuild MUST compute sealed_through from the rebuilt ranges of seal_coverage.
  ```
  Terms › `sealed_through`: the maximum `sequence_number` over all `seal_coverage` ranges; zero for an empty seal store.

  Terms › `unsealed tail`: the events whose `sequence_number` EXCEEDS `sealed_through`.
- **`compensated_attestations`** — the set of `attestation_id`s for which an `audit.compensation` event has been recorded; the closed-state marker for orphan reconciliation.
  ```text
  compensated_attestations 1: The composition MUST classify compensated_attestations as derived index.
  compensated_attestations 2: The rebuild MUST keep, from the full enumeration, EVERY event whose action_ref = audit.compensation AND whose payload subject = attestation, and take the attestation_id each payload names.
  compensated_attestations 3: The rebuild MUST filter on the subject-kind discriminator.
  compensated_attestations 4: The rebuild MUST filter in composition code.
  compensated_attestations 5: A deployment composing Reverse Index MAY filter through Reverse Index as an instance optimization.
  compensated_attestations 6: The rebuild MUST cover the audit.compensation events live in the log.
  ```
  Terms › `reconciled`: an orphan whose `attestation_id` is a member of `compensated_attestations`.

  WHY: the orphan never goes away — Actor Identity Invariant 9 forecloses deletion — so the store cannot carry the closure; the marker does. Without the subject filter a rebuild would read an `event_id` where it expected an `attestation_id`. Compensation events are themselves purged in time, so the rebuilt set covers the compensations still live (compensated_attestations 6); the residual — a second compensation for an orphan compensated a retention period earlier — is a duplicate, never a false record. The rebuild is trustworthy because the reserved namespace (Primitive policy 8) means the set is read from records only the composition's own reconciliation path could have written.
- **`reported_beyond_horizon`** — the set of `attestation_id`s for which the scan's second half has recorded a *beyond the horizon* finding; the closed-state marker for that report.
  ```text
  reported_beyond_horizon 1: The composition MUST classify reported_beyond_horizon as derived index.
  reported_beyond_horizon 2: The rebuild MUST keep, from the full enumeration, EVERY event whose action_ref = audit.reconciliation AND whose payload subject = attestation AND whose payload disposition = beyond-horizon, and take the attestation_id each names.
  reported_beyond_horizon 3: The rebuild MUST cover the audit.reconciliation events live in the log.
  ```
  WHY: the orphan is permanent, so without the marker the report would be written every cadence; with it, an orphan past the horizon is reported at most once per retention period of the report itself, and a short rebuild produces a duplicate report, never a false one.

### Configuration

Seventeen knobs and one instance capability requirement, the per-act section. Each knob carries a type, a default and a setting rule; every default of *none* is deployment-required, and §*Instance start* is the one owner of what an instance refuses to start without.

- **`retention_policy`** — a Retention Window `policy_ref`, or a policy selector `(action_ref, actor_ref, data) → policy_ref` for content-derived rules. *Default:* none.
  ```text
  retention_policy 1: The deployment MUST set retention_policy to the reconciled policy for the record class.
  retention_policy 2: [Record Action] step 4 MUST place the retention under the resolved policy.
  retention_policy 3: EXACTLY ONE retention record MUST govern an audit event and the event's attestation.
  retention_policy 4: The composition MUST NOT hold an attestation meta-retention policy.
  retention_policy 5: The composition MUST retain a seal indefinitely.
  ```
  Terms › `reconciled policy`: the longest applicable retention across every regulation in force, the strictest data-minimization posture, and any conflicting destruction rules reconciled — produced by a Policy Reconciliation pattern *(forthcoming)*.

  Terms › `resolved policy`: `retention_policy` where the knob is a `policy_ref`; the `policy_ref` the selector returns where the knob is a selector.

  WHY: a retention period is a legal obligation, and a composition that picked one would assert a legal conclusion it cannot make; a Policy Reconciliation pattern *(forthcoming)* produces the reconciled value across every regulation in force. The attestation's lifetime rides the event's retention and the two are destroyed in one cascade, so the *Composes* declaration of one Retention Window instance is literally accurate.
- **`seal_cadence`** — `per-event` | `interval-based` | `on-demand`; an interval-based cadence carries an events arm (every N events), a time arm (every T seconds), or both. *Default:* none.
  ```text
  seal_cadence 1: The deployment MUST set seal_cadence from the forensic window the deployment's regime tolerates.
  seal_cadence 2: A deployment whose auditor requires a bounded per-event tampering window MUST set per-event.
  ```
  Terms › `time arm`: the every-T-seconds arm of an interval-based `seal_cadence`.

  WHY: the cadence bounds the forensic window for any detected tampering; tighter cadence narrows the window at the cost of seal-store growth and verify-time work, and a coarse cadence strands more live seal-mates at every purge (Edge cases).
- **`seal_mechanism`** — a Tamper Evidence mechanism reference: hash chain, Merkle tree, RFC 3161-anchored timestamp. *Default:* none.
  ```text
  seal_mechanism 1: The deployment MUST select a mechanism sound for the full audit horizon.
  seal_mechanism 2: A deployment requiring the forensic-window bound of Check 4 MUST select a chained mechanism.
  seal_mechanism 3: The deployment MUST set seal_mechanism to the mechanism the wired Tamper Evidence instance runs.
  seal_mechanism 4: The deployment MUST alert on a disagreement between seal_mechanism and the wired instance's mechanism as a deployment fault.
  seal_mechanism 5: The mechanism's seal-time rendering MUST match the verify-time presentation.
  seal_mechanism 6: The deployment MUST declare the agreement of seal_mechanism 5.
  ```
  Terms › `chained mechanism`: a mechanism under which each seal commits to its predecessor.

  Terms › `verify-time presentation`: the payloads of every event in the covering seal's range, byte-exact, in ascending `sequence_number` order — no re-serialization, key reordering or encoding fixup.

  WHY: Tamper Evidence is mechanism-neutral (its Invariant 8) and records the choice outside itself, so the knob declares the wired choice and configures nothing; every disagreement but a refused credential is invisible by opacity, which is why seal_mechanism 5 is audited outside the records (External check 4). Nothing in the seal store says which rendering a seal committed to, so a mechanism that hashed a different order or a re-serialized form would fail every conforming presentation with nothing in the trail saying why; Tamper Evidence's *Record-set definition* edge case routes the agreement to the host, and this composition is the host.
- **`mechanism_credential`** — opaque credential material passed to `TamperEvidence.seal` on every seal, whatever the cadence: a signing key for a keyed mechanism, a TSA client credential for an anchored one. *Default:* empty (unkeyed).
  ```text
  mechanism_credential 1: The composition MUST pass mechanism_credential to TamperEvidence.seal on every seal.
  mechanism_credential 2: The composition MUST pass mechanism_credential through unchanged.
  mechanism_credential 3: The composition MUST NOT inspect mechanism_credential.
  mechanism_credential 4: The composition MUST NOT log mechanism_credential.
  mechanism_credential 5: IF mechanism class != unkeyed THEN the deployment MUST set mechanism_credential.
  mechanism_credential 6: IF mechanism class = unkeyed THEN the deployment MUST NOT set mechanism_credential.
  mechanism_credential 7: A deployment requiring non-repudiation of the seal MUST set a credential whose nature supplies non-repudiation.
  mechanism_credential 8: IF mechanism_credential NOT EXISTS THEN the composition MUST pass an empty credential.
  ```
  Terms › `mechanism class`: `unkeyed` | `keyed` | `anchored`.

  WHY: a bare hash chain needs no credential and Tamper Evidence permits an empty one, so the precondition check lives in the constituent, not here. Non-repudiation depends on the credential, not on this composition's surface.
- **`unsealed_tail_mode`** — `strict` | `lenient`: what [Verify Record] returns for an event in the unsealed tail. *Default:* `strict`.
  ```text
  unsealed_tail_mode 1: A deployment MAY set lenient ONLY IF independently trusted substrate EXISTS AND standing false negative EXISTS.
  unsealed_tail_mode 2: A regulated deployment MUST NOT set lenient.
  NOTE: watch applicability — the source's setting rules read *where X, do Y*; the applicability is carried in the subject here (unsealed_tail_mode 2, seal_mechanism 2, reference_length_cap 3, mechanism_credential 7).
  unsealed_tail_mode 3: IF unsealed_tail_mode NOT EXISTS THEN the instance MUST take strict.
  ```
  Terms › `independently trusted substrate`: a log substrate trusted apart from this composition's seals — WORM storage, an external replica.

  Terms › `standing false negative`: a `strict` tail that would answer `failed-verification(unsealed)` for the whole of a coarse cadence interval.

  WHY: `strict` is the fail-closed value — integrity is unverified until a seal covers the event, and defaulting the other way would let a deployment report unverified events as `verified` by omission. Regulated deployments keep `strict`.
- **`erasure_mechanism`** — a reference to the deployment's composed content-destruction mechanism, invoked at [Purge Event] step 3. *Default:* none.
  ```text
  erasure_mechanism 1: The deployment MUST wire a shredding-class erasure mechanism.
  erasure_mechanism 2: The deployment MUST NOT wire a tombstone-by-mutation mechanism.
  erasure_mechanism 3: The erasure mechanism MUST destroy the readability of the whole of Event Log's data field.
  erasure_mechanism 4: The erasure mechanism MUST destroy the readability of the attestation's proof.
  erasure_mechanism 5: The erasure mechanism MUST NOT rewrite a stored field.
  erasure_mechanism 6: The erasure mechanism MUST leave the attestation's surviving fields readable.
  erasure_mechanism 7: The erasure mechanism MUST report EXACTLY ONE OF destroyed, destruction-failed(reason) for EVERY event the mechanism is asked about.
  erasure_mechanism 8: The erasure mechanism MUST name the event_id in EVERY outcome.
  erasure_mechanism 9: The deployment MUST evidence the mechanism's class to the auditor outside the records.
  ```
  Terms › `shredding-class`: a mechanism that destroys recoverability — the key material under which the content was stored — and never a stored byte.

  Terms › `tombstone-by-mutation`: overwriting, blanking or truncating a stored field in place.

  Terms › `Event Log's data field`: the whole constructed object `{action_ref, actor_ref, attestation_id, data}` [Record Action] step 3 appends; the caller-supplied `data` is one member inside it.

  WHY: the name `data` does double duty. The mechanism takes the outer object, so the payload's copies of `action_ref`, `actor_ref` and `attestation_id` go with it, which is why the purged-event answers read the attestation store; the *who / what / when* outlives the purge, the payload and the binding's verifiability do not. There is no safe default: defaulting to *no destruction* would leave *Purged* over readable content, the gap Invariant 8 forecloses. A mechanism that only reported *I was called* would make success undecidable (erasure_mechanism 7), and an outcome not traceable to its event could close nothing (erasure_mechanism 8). The class boundary is argued at Boundary one.
- **`compensation_window`** — the duration within which the liveness arms of Invariants 1, 2 and 8 close: an orphan attestation, an unretained event or a half-completed cascade is surfaced and reconciled inside it. *Default:* none.
  ```text
  compensation_window 1: The deployment MUST set compensation_window from the tightest reconciliation deadline the deployment's regime imposes.
  compensation_window 2: The composition MUST measure compensation_window from the finding's creation.
  compensation_window 3: The composition MUST NOT measure compensation_window from the finding's detection.
  compensation_window 4: An auditor MUST read the quiescence condition of Check 2 from compensation_window.
  ```
  Terms › `finding's creation`: the orphan attestation's `attested_at`; the unretained event's `recorded_at`; the half-completed cascade's `purged_at`.

  WHY: the window is the deployment's declared tolerance for a surfaced finding standing open — a regulatory judgment about its own regime. An orphan created at `t` is invisible to the scan until `t + bound + allowance`, the next run is at most one cadence later, and the closure lands one latency after that (Instance start 16); a cadence no longer than the window is satisfied by a deployment that breaches on every orphan.
- **`reconciliation_cadence`** — how often the reconciliation scan runs. *Default:* the time arm of `seal_cadence` where that cadence carries one; none otherwise.
  ```text
  reconciliation_cadence 1: The reconciliation scan MUST run PER reconciliation_cadence.
  reconciliation_cadence 2: The reconciliation scan MUST run at restart.
  reconciliation_cadence 3: IF time arm NOT EXISTS THEN the deployment MUST set reconciliation_cadence.
  reconciliation_cadence 4: IF time arm EXISTS AND reconciliation_cadence NOT EXISTS THEN the instance MUST take the time arm as reconciliation_cadence.
  reconciliation_cadence 5: reconciliation_cadence MUST govern all three halves of the scan.
  ```
  WHY: an events-only cadence yields no duration — a rate in appends says nothing about how long a finding may stand, and a quiet write period would stretch the interval without bound while the window kept running — so events-only, per-event and on-demand cadences are deployment-required. The time arm is the safe derived default because it is the rate at which the deployment has already declared it wants the audit surface brought up to date. A deployment tightens the cadence where purge volume would otherwise leave many unreconciled entries per sweep.
- **`reconciliation_operator`** — an `actor_ref`: the deployment's maintenance actor authorized to record under the reserved `audit.*` namespace; the discriminator [Record Action] step 1's namespace gate turns on. *Default:* none.
  ```text
  reconciliation_operator 1: The deployment MUST provision reconciliation_operator as an actor in the wired attestation store with usable credential material.
  reconciliation_operator 2: [Record Action] step 1 MUST decide the reconciliation path by actor_ref = reconciliation_operator, byte-identity.
  ```
  WHY: without a declared discriminator the gate is undecidable — *external caller* names no observable property of a call — so an implementer could refuse `audit.*` from everyone (the liveness arms never close) or accept it from everyone (the closure marker is forgeable). Knowing the operator's `actor_ref` admits a caller past step 1 only; step 2's `attest` still demands the credential, so an `audit.*` event cannot exist in the log unless attested under the operator identity (Check 7).
- **`reconciliation_operator_credential`** — opaque credential material for the actor `reconciliation_operator` names. *Default:* none.
  ```text
  reconciliation_operator_credential 1: The scan MUST hand reconciliation_operator_credential to ActorIdentity.attest on EVERY reconciliation-path write.
  reconciliation_operator_credential 2: The composition MUST NOT inspect reconciliation_operator_credential.
  reconciliation_operator_credential 3: The composition MUST NOT log reconciliation_operator_credential.
  reconciliation_operator_credential 4: The composition MUST NOT write reconciliation_operator_credential into a payload.
  ```
  WHY: an `actor_ref` without credential material in hand is an identity the scan cannot attest under; storage and rotation are Credential management's business.
- **`payload_cap`** — the byte ceiling [Record Action] step 1 checks the full constructed payload against. *Default:* none.
  ```text
  payload_cap 1: The deployment MUST set payload_cap to the wired Event Log instance's own configured cap.
  payload_cap 2: [Record Action] step 1 MUST measure the serialized envelope against payload_cap.
  payload_cap 3: [Record Action] step 1 MUST NOT measure the sum of the members' own lengths.
  payload_cap 4: The deployment MUST alert on invalid-payload at [Record Action] step 3 as a deployment fault.
  ```
  Terms › `serialized envelope`: the byte length of Event Log's data field exactly as handed to `EventLog.append`, in the encoding the wired instance sizes it in, framing and field names included.

  WHY: the cap is per-instance configuration the wired instance may have changed from the atom's 64 KB default, so the composition can neither derive nor assume one. Summing the members under-counts by the serialization's structure, and under-counting is the direction that strands a committed attestation. Reaching `invalid-payload` at step 3 after step 1 passed means the two caps disagree.
- **`reference_length_cap`** — a byte length, applied independently to `action_ref` and `actor_ref` at [Record Action] step 1. *Default:* 1 KB each.
  ```text
  reference_length_cap 1: [Record Action] step 1 MUST apply reference_length_cap to action_ref and to actor_ref independently.
  reference_length_cap 2: reference_length_cap MUST NOT EXCEED reference headroom.
  reference_length_cap 3: A deployment MAY raise reference_length_cap above 1 KB ONLY IF a genuine reference scheme EXCEEDS 1 KB.
  reference_length_cap 4: IF reference_length_cap NOT EXISTS THEN the instance MUST take 1 KB.
  ```
  Terms › `reference headroom`: `payload_cap − attestation_id_width − the largest data the deployment intends to accept`.

  WHY: a ceiling, not a semantic choice: it exists so a caller cannot push the constructed payload past the cap through the reference fields alone. A deployment lowers it where it wants the rejection to arrive at the reference, and raises it only where a genuine scheme exceeds 1 KB.
- **`attestation_id_width`** — the width of the `attestation_id` the configured Actor Identity instance allocates. *Default:* none.
  ```text
  attestation_id_width 1: The deployment MUST set attestation_id_width to the maximum width the wired Actor Identity instance allocates.
  attestation_id_width 2: [Record Action] step 1 MUST size the payload with attestation_id_width.
  ```
  WHY: Actor Identity declares the id opaque, host-allocated and of no fixed width. An under-declared width makes step 1's check optimistic and reopens the path where an oversized payload strands a committed attestation.
- **`record_action_completion_bound`** — the longest a [Record Action] may take between its first committed write (step 2's attestation, stamped `attested_at` at Actor Identity's seam) and its last (step 5's index writes). *Default:* none.
  ```text
  record_action_completion_bound 1: The deployment MUST set record_action_completion_bound from the observed worst-case latency of [Record Action] steps 2–5 with headroom, constituent round-trips included.
  ```
  WHY: a write issued inside the bound must also have landed inside it. The bound does three jobs, each stated where it happens: the lower edge of the scan's second and third halves (`record_edge`), the per-act lease length for a record action (Per-act section 9a), and the invocation's terminus (record_action step 7.6).
- **`purge_completion_bound`** — the longest a [Purge Event] may take between step 1's transition (stamped `purged_at` at Retention Window's seam) and step 3's outcome record. *Default:* none.
  ```text
  purge_completion_bound 1: The deployment MUST set purge_completion_bound from the observed worst-case latency of [Purge Event] steps 2–3 with headroom, the erasure mechanism's round-trip included.
  ```
  WHY: the lower edge of the scan's first half (`purge_edge`), the lease length for a cascade's section, and the cascade's terminus, on the record action's terms.
- **`compensation_closure_latency`** — the deployment's disclosed bound on one whole closure landing, from the moment a scan half takes an act's section to the moment the closure's last record has landed. *Default:* none.
  ```text
  compensation_closure_latency 1: The deployment MUST declare compensation_closure_latency as the bound on one whole closure.
  ```
  Terms › `whole closure`: for the second and third halves, the `audit.reconciliation` intent, the compensating act and the `audit.compensation` record — three writes, each an attest-append-place across three stores or a retention placement; for the first half, a re-driven cascade, the erasure mechanism's round-trip included.

  WHY: declared rather than observed so that the start check can read it; the fourth term of the inequality.
- **`clock_skew_allowance`** — the most the composition's seam clock and any constituent's seam clock may differ. *Default:* none.
  ```text
  clock_skew_allowance 1: The deployment MUST set clock_skew_allowance from the deployment's clock discipline.
  clock_skew_allowance 2: The scan MUST widen EVERY comparison of now with a constituent-stamped time by clock_skew_allowance.
  clock_skew_allowance 3: The scan MUST NOT decide a write by a cross-seam comparison alone.
  clock_skew_allowance 4: A cross-seam comparison MUST exclude a record from the pass and nothing more.
  ```
  WHY: the scan reads `now` once per run at its own seam and compares it to `attested_at` (Actor Identity), `recorded_at` (Event Log) and `purged_at` (Retention Window), each written at another seam; every such comparison widens the completion bound by the allowance, and the write is decided by the half's own predicate read under the section.
- **Per-act section** — an instance capability requirement, not a knob: a per-key critical section the host supplies, keyed by an act's id — the `attestation_id` [Record Action] step 2 returns for a record action, the `event_id` for a cascade. *Default:* none.
  ```text
  Per-act section 1: The host MUST supply a per-key critical section keyed by the act's id.
  Per-act section 2: The host MUST release the section on the holder's return.
  Per-act section 3: The host MUST release the section on the holder's death.
  Per-act section 4: A host that cannot detect the holder's death MUST implement the section as a lease.
  Per-act section 5: A leg that finds an act's section held MUST skip the act for the rest of the run.
  Per-act section 6: A leg MUST NOT block on a held section.
  Per-act section 7: IF held section NOT EXISTS THEN the invocation MUST NOT issue a later write.
  NOTE: watch condition negation — *not holding the section* is written as a minted term's NOT EXISTS (Per-act section 7, Per-act section 8, Invariant 6.3).
  Per-act section 8: IF held section NOT EXISTS THEN the invocation MUST NOT land a later write.
  Per-act section 9: WHEN section_kind = lease:
      Per-act section 9a: The host MUST set the lease to the act's completion bound.
      Per-act section 9b: IF lease = expired THEN the invocation MUST NOT issue a truth-bearing write.
      Per-act section 9c: An invocation whose truth-bearing writes have all landed MUST complete the invocation's index writes and return success.
  Per-act section 10: WHEN section_kind = death-detected:
      Per-act section 10a: The invocation MUST NOT read a clock.
      Per-act section 10b: The invocation MUST take proceed as landed as the invocation's terminus.
  Per-act section 11: A writer without the section MUST NOT read a pre-check BEFORE re-taking the section.
  Per-act section 12: A writer MUST re-read the pre-check under the re-taken section.
  ```
  Terms › `section_kind`: `lease` | `death-detected` — a lease where the host times the section; death-detected where the host's own section contract releases a section its holder's process no longer holds.

  Terms › `act's completion bound`: `record_action_completion_bound` for a record action; `purge_completion_bound` for a cascade.

  Terms › `lease`: `live` | `expired`.

  Terms › `holder`: the party the section is held by; a record action's invocation, a cascade, or a scan half.

  Terms › `held section`: the act's section with the invocation as holder.

  Terms › `later write`: a write after the invocation's first write.

  Terms › `truth-bearing write`: a write to a constituent store — steps 2–4 of a record action, steps 1–3 of a cascade; the index writes of step 5 are not truth-bearing.

  Terms › `proceed as landed`: the outcome or placement step runs the step's pre-check under the section — `event_to_retention` at [Record Action] step 4, the destruction record and `erasure_outcomes` at [Purge Event] steps 2–3 — and, where the record already exists because a leg landed it after the invocation lost the section, adopts the record as the invocation's own and continues.

  Terms › `pre-check`: the read a writer makes under the section before writing — `compensated_attestations`, `reported_beyond_horizon`, `event_to_retention`, or the first half's predicate.

  WHY: one-writer-per-act rests on the section. A held section is a live invocation inside its bound, and the age edge already keeps a leg off work that young, so a leg skips rather than waits. A record action's key is the `attestation_id` because no `event_id` exists before step 3, and a section that began there would leave the append outside it. Where the section is a lease, expiry is the terminus (record_action step 7.6, purge_event 7); where it is not, the terminus is the pre-check-and-adopt of step 4 or steps 2–3.

### Instance start

```text
Instance start 1: IF retention_policy NOT EXISTS THEN the instance MUST NOT start.
Instance start 2: IF seal_cadence NOT EXISTS THEN the instance MUST NOT start.
Instance start 3: IF seal_mechanism NOT EXISTS THEN the instance MUST NOT start.
Instance start 4: IF erasure_mechanism NOT EXISTS THEN the instance MUST NOT start.
Instance start 5: IF compensation_window NOT EXISTS THEN the instance MUST NOT start.
Instance start 6: IF reconciliation_cadence NOT EXISTS THEN the instance MUST NOT start.
Instance start 7: IF reconciliation_operator NOT EXISTS THEN the instance MUST NOT start.
Instance start 8: IF reconciliation_operator_credential NOT EXISTS THEN the instance MUST NOT start.
Instance start 9: IF payload_cap NOT EXISTS THEN the instance MUST NOT start.
Instance start 10: IF attestation_id_width NOT EXISTS THEN the instance MUST NOT start.
Instance start 11: IF record_action_completion_bound NOT EXISTS THEN the instance MUST NOT start.
Instance start 12: IF purge_completion_bound NOT EXISTS THEN the instance MUST NOT start.
Instance start 13: IF compensation_closure_latency NOT EXISTS THEN the instance MUST NOT start.
Instance start 14: IF clock_skew_allowance NOT EXISTS THEN the instance MUST NOT start.
Instance start 15: IF the per-act section NOT EXISTS THEN the instance MUST NOT start.
Instance start 16: The instance MAY start ONLY IF compensation_window EXCEEDS closure_sum.
Instance start 17: The instance MUST read closure_sum's four terms at start.
```

Terms › `closure_sum`: `max(record_action_completion_bound, purge_completion_bound) + clock_skew_allowance + reconciliation_cadence + compensation_closure_latency`.

WHY:
Instance start 6 applies where reconciliation_cadence 3 leaves the cadence unset — an events-only, per-event or on-demand seal cadence with no time arm. Instance start 16 is strict: equality lands the closure at the window's edge after a latency the check did not count, and a window the scan cannot close inside is not a tolerance but a standing violation declared in advance. The refusal is the same one every mis-set deployment-required knob gets.

### Primitive policies

The composition takes four caller-supplied inputs at [Record Action], one at each id-addressed surface, and one more at [Verify Record]. Each is validated at this layer or by a named constituent; nothing is normalized anywhere.

```text
Primitive policy 1: action_ref MUST contain a non-whitespace character.
Primitive policy 2: actor_ref MUST contain a non-whitespace character.
Primitive policy 3: [Record Action] step 1 MUST validate action_ref and actor_ref at this layer.
Primitive policy 4: [Record Action] MUST NOT call a constituent BEFORE step 1 completes.
Primitive policy 5: [Record Action] step 1 MUST land rejected(invalid-request) for a malformed reference, with nothing recorded.
Primitive policy 6: The composition MUST NOT normalize any input.
Primitive policy 7: The composition MUST compare references by byte-identity.
Primitive policy 8: [Record Action] step 1 MUST land rejected(invalid-request) for an action_ref whose bytes begin with the prefix audit. from a caller whose actor_ref != reconciliation_operator, with nothing recorded.
Primitive policy 9: The reconciliation path MAY record under the reserved namespace ONLY IF the action_ref = audit.compensation OR the action_ref = audit.reconciliation.
Primitive policy 10: The composition MUST consume credential through ActorIdentity.attest alone.
Primitive policy 11: The composition MUST NOT inspect credential.
Primitive policy 12: The composition MUST NOT store credential.
Primitive policy 13: The composition MUST NOT write credential into a payload.
Primitive policy 14: The composition MUST NOT write credential into a log line.
Primitive policy 15: The composition MUST NOT apply a length cap to credential.
Primitive policy 16: The composition MUST NOT read inside a caller's data.
Primitive policy 17: A policy selector MAY inspect data at [Record Action] step 4's policy resolution.
Primitive policy 18: The composition MUST NOT retain what the selector reads.
Primitive policy 19: The composition MUST NOT log what the selector reads.
Primitive policy 20: The composition MAY read inside a payload ONLY IF the payload's action_ref = audit.compensation OR the payload's action_ref = audit.reconciliation.
Primitive policy 21: [Record Action] step 1 MUST measure the serialized envelope of the full constructed payload against payload_cap, sized with attestation_id_width.
Primitive policy 22: [Record Action] step 1 MUST land rejected(invalid-request) for an oversize payload, with nothing recorded.
Primitive policy 23: An empty data MUST count as valid.
Primitive policy 24: An unknown event_id MUST yield not-known from the addressed action.
Primitive policy 25: The composition MUST pass original_event_payload through to TamperEvidence.verify unchanged.
Primitive policy 26: original_event_payload MUST match the verify-time presentation.
Primitive policy 27: The caller MUST present a non-empty original_event_payload.
Primitive policy 28: The composition MUST NOT canonicalize original_event_payload.
```

Terms › `malformed reference`: an `action_ref` or `actor_ref` that is empty, all whitespace, or over `reference_length_cap`.

Terms › `full constructed payload`: Event Log's data field — `{action_ref, actor_ref, attestation_id, data}` — the exact object [Record Action] step 3 hands to `EventLog.append`.

Terms › `reserved namespace`: every `action_ref` whose bytes begin with `audit.`; `Audit.` is a different reference and is not reserved.

Terms › `reconciliation path`: the scan's own writes — `audit.reconciliation` and `audit.compensation` records — identified by `actor_ref` = `reconciliation_operator`.

WHY:
Byte-identity is what makes Invariant 1's `action_ref`-match check mechanical; Actor Identity applies the same non-empty minimum at `attest`, and validating here first makes the rejection clean rather than post-attestation. The namespace is reserved because two composition-owned surfaces read inside payloads written under it — `compensated_attestations`' rebuild and, through it, Invariant 1's closure — and a caller able to write under it could close a finding the composition never compensated; the reservation makes those records evidence rather than assertion. The one payload the composition reads inside is one it wrote itself under a reference it owns (Primitive policy 20), so a caller's `data` stays opaque throughout, with the selector seam as the named exception (Primitive policy 17). `credential` never enters the payload, so it cannot contribute to the cap check. Empty `data` is Event Log's rule — rejecting meaningless events is the composing pattern's job — and a richer payload schema is a Schema Evolution pattern *(forthcoming)*. `event_id` carries no ordering (Event Log's Identity model), which is why coverage ranges over `sequence_number` and an id-addressed read goes through `event_to_sequence`. An empty presentation surfaces from Tamper Evidence as `failed-verification(seal-record-set-mismatch)`, never as the composition's own `not-known`; a layer that quietly canonicalized the presentation would manufacture agreement the seal never certified. Deployments wanting normalization wire it at the calling layer.

### Action wiring

One *record* action wraps all four constituents; *seal*, *read*, *verify* and *purge* actions run over the composed surface; the consolidated per-event join is [Read Record]. Each step names every rejection its constituent call can return and where the rejection lands at this composition's boundary; the enumeration is exhaustive, because silent rejection-code drift is a Pass 1 reference-graph finding.

```text
Action wiring 1: The composition MUST pass a query by sequence-number range through to EventLog.read unchanged.
Action wiring 2: The composition MUST pass a query by wall-time range through to EventLog.read unchanged.
Action wiring 3: The composition MUST NOT serve a query by payload field.
Action wiring 4: A deployment needing a query by payload field MUST compose Reverse Index over the audit log and join the results through [Read Record] one event_id at a time.
```

WHY:
Both range shapes are declared query shapes on Event Log's `read`. Every event referencing action X, every event by actor Y, every event carrying a business id inside `data` — Event Log's own *Reverse lookup / indexing* edge case routes these to Reverse Index *(forthcoming)*, and this composition does not absorb it. The one payload-field lookup this composition owns — `event_id` to `sequence_number` — it owns because it maintains `event_to_sequence` for exactly that purpose.

---

#### `record_action`

```
record_action(action_ref, actor_ref, credential, data) →
    event_id
  | rejected(
      invalid-credential
    | invalid-request
    | recording-failure(step)
    )
```

Validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal.

```text
record_action 1: The recording-failure arm MUST carry the step that refused.
```

WHY: a bare token would satisfy the projection while defeating the three surfaces that read the step off the outcome — step 7's operator diagnosis, Invariant 1's surfaced-orphan requirement, and the rejection walkthrough.

Steps:

1. **Validate the primitives at this layer, before any constituent is called.**
   ```text
   record_action step 1.1: [Record Action] step 1 MUST validate action_ref and actor_ref per Primitive policy 1–5 and Primitive policy 8.
   record_action step 1.2: [Record Action] step 1 MUST size the full constructed payload per Primitive policy 21 and Primitive policy 22.
   record_action step 1.3: A step-1 refusal MUST record nothing.
   record_action step 1.4: WHEN actor_ref = reconciliation_operator:
       record_action step 1.4a: [Record Action] step 1 MUST land rejected(invalid-request) for an audit.compensation payload carrying no subject-kind discriminator.
       record_action step 1.4b: [Record Action] step 1 MUST land rejected(invalid-request) for an audit.compensation payload carrying no id for the subject.
   record_action step 1.5: [Record Action] step 1 MUST NOT validate the shape of a payload written outside the reserved namespace.
   ```
   Terms › `subject-kind discriminator`: the payload field `subject` = `attestation` | `event`; with `subject = attestation` the payload carries the orphan's `attestation_id`, with `subject = event` the `event_id` whose retention was placed.

   WHY: the size check sits ahead of step 2 so an oversized payload can never strand a committed, immutable attestation. The namespace check has an external side — any call whose `actor_ref` is not the operator's, there being no other marker of origin — and an internal side, record_action step 1.4's payload requirement; a caller supplying the operator's `actor_ref` without the credential passes here and is refused at step 2 with nothing recorded. This is the one place the composition validates a payload's shape, and only of payloads it wrote itself.
2. **Attest.**
   ```text
   record_action step 2.1: [Record Action] step 2 MUST call ActorIdentity.attest(action_ref, actor_ref, credential) → attestation_id.
   record_action step 2.2: [Record Action] step 2 MUST land invalid-credential as rejected(invalid-credential).
   record_action step 2.3: [Record Action] step 2 MUST land invalid-request as rejected(invalid-request).
   record_action step 2.4: [Record Action] step 2 MUST land storage-failure as [Recording Failure].
   record_action step 2.5: A step-2 refusal MUST record nothing further.
   record_action step 2.6: [Record Action] MUST take the per-act section on the attestation_id step 2 returned.
   record_action step 2.7: [Record Action] MUST hold the section through step 5.
   record_action step 2.8: [Record Action] MUST release the section on return.
   ```
   WHY: in all three refusal arms no attestation exists — Actor Identity's `storage-failure` guarantees no partial record. The key is the act's own, minted at its first write.
3. **Append.**
   ```text
   record_action step 3.1: [Record Action] step 3 MUST call EventLog.append with the full constructed payload → event_id.
   record_action step 3.2: The composition MUST NOT supply recorded_at.
   record_action step 3.3: [Record Action] step 3 MUST land storage-failure as [Recording Failure].
   record_action step 3.4: [Record Action] step 3 MUST land invalid-payload as rejected(invalid-request).
   ```
   WHY: Event Log stamps `recorded_at` at its own seam from the host-injected clock, and that stamp is the audit event's timestamp wherever it is read back; a business event-time lives inside the opaque `data`. `invalid-payload` is reachable — `data` is caller-supplied and Event Log enforces a cap — which is why step 1 sizes first; reaching the arm after step 1 passed means `payload_cap` and the wired instance's cap disagree, a deployment fault (payload_cap 4), not a caller rejection.
4. **Place under retention.**
   ```text
   record_action step 4.1: [Record Action] step 4 MUST NOT place a retention BEFORE re-reading event_to_retention for the event_id under the section.
   record_action step 4.2: IF a retention for the event_id EXISTS THEN [Record Action] step 4 MUST adopt the retention as landed and continue to step 5.
   record_action step 4.3: [Record Action] step 4 MUST call RetentionWindow.place_under_retention(event_id, resolved policy) → retention_id, with record_ref = event_id.
   record_action step 4.4: IF lease = expired THEN [Record Action] step 4 MUST NOT place.
   record_action step 4.5: [Record Action] step 4 MUST land invalid-request as rejected(invalid-request).
   record_action step 4.6: [Record Action] step 4 MUST land invalid-policy and policy-not-found as rejected(invalid-request).
   record_action step 4.7: The deployment MUST alert on invalid-policy and policy-not-found as a deployment fault.
   record_action step 4.8: [Record Action] step 4 MUST land storage-failure as [Recording Failure].
   ```
   WHY: the third half takes the same section — on the event's payload `attestation_id` — before it pre-checks `event_to_retention` and places, and examines no event younger than `record_edge`, so this placement and the leg's are never both made for one event (Concurrency 6, Third half 4). Where the lease has expired before this step issues, the event is the third half's from here on and a later placement is the leg's. The policy reference came from Configuration, not the caller, so `invalid-policy` and `policy-not-found` are deployment faults surfaced on the caller's arm.
5. **Record the indexes.**
   ```text
   record_action step 5.1: [Record Action] step 5 MUST record event_to_attestation, event_to_retention and event_to_sequence for the event.
   record_action step 5.2: [Record Action] step 5 MUST take sequence_number from the read-back.
   record_action step 5.3: The read-back MUST run from the high-water mark to the open end.
   record_action step 5.4: The read-back MUST match the returned event_id by equality.
   record_action step 5.5: IF the read-back returns no event carrying the event_id THEN [Record Action] step 5 MUST fall back to the rebuild of event_to_sequence.
   record_action step 5.6: [Record Action] step 5 MUST NOT guess a sequence_number.
   record_action step 5.7: An implementation whose append result surfaces sequence_number MAY take the value from the append result and skip the read-back.
   record_action step 5.8: The composition MUST NOT depend on the append result surfacing sequence_number.
   record_action step 5.9: The composition MUST treat a step-5 failure as a rebuild trigger.
   record_action step 5.10: A step-5 failure MUST NOT land [Recording Failure].
   ```
   Terms › `read-back`: the open-upper-bound read over the new tail through `EventLog.read`.

   Terms › `high-water mark`: the greater of `sealed_through` and the highest `sequence_number` this instance has itself recorded into `event_to_sequence`.

   WHY: concurrent record actions interleave, so the event may sit behind several others by the time the read issues; the open upper bound keeps that from being a miss, and a stale mark or a lagging replica falls back to the total rebuild rather than a wrong number. The read-back uses only Event Log's declared Q surface; no Event Log invariant obliges an instance to surface the value at the append seam.
6. **Seal under per-event cadence.**
   ```text
   record_action step 6.1: IF seal_cadence = per-event THEN [Record Action] step 6 MUST seal through [Seal Now].
   record_action step 6.2: IF seal_cadence != per-event THEN [Record Action] step 6 MUST defer sealing to the next cadence firing.
   record_action step 6.3: A cadence firing MUST seal the slice.
   record_action step 6.4: A seal failure at step 6 MUST NOT reject [Record Action].
   record_action step 6.5: The deployment MUST alert on a step-6 seal failure with the cause.
   record_action step 6.6: The next cadence firing MUST retry the seal.
   ```
   WHY: the firing seals the tail it finds — typically the singleton range holding the new event, wider whenever a prior firing's seal failed — not the event that triggered it. The load-bearing writes have committed, the event remains in the unsealed tail Invariant 3 already states the coverage claim modulo, and rejecting the call would misdescribe a record that exists and is attributed.
7. **Return.**
   ```text
   record_action step 7.1: [Record Action] step 7 MUST return event_id.
   record_action step 7.2: IF step-3 storage failure EXISTS THEN [Record Action] MUST return rejected(recording-failure(step-3)).
   NOTE: watch event versus state — *step 3 refusing after step 2 committed* is an event, written as a minted term's EXISTS (record_action step 7.2, record_action step 7.3); *[Seal Now] rejects* is written as a bare condition (seal_now 9–11, purge_event step 0.4).
   record_action step 7.3: IF step-4 storage failure EXISTS THEN [Record Action] MUST return rejected(recording-failure(step-4)).
   record_action step 7.4: A recording-failure outcome MUST surface the partial state the invocation left.
   record_action step 7.5: [Record Action] MUST NOT land a non-storage refusal of steps 3–4 as [Recording Failure].
   record_action step 7.6: WHEN mid-record expiry EXISTS:
       record_action step 7.6a: [Record Action] MUST NOT issue a further constituent write.
       record_action step 7.6b: [Record Action] MUST return rejected(recording-failure(step)) naming the first step not completed.
       record_action step 7.6c: [Record Action] MUST release the section.
   record_action step 7.7: An invocation past step 4 at the bound MUST complete step 5 and return event_id.
   record_action step 7.8: The invocation MUST NOT write a compensation for the partial state the invocation left.
   ```
   Terms › `step-3 storage failure`: `EventLog.append` answering `storage-failure` with step 2's attestation committed.

   Terms › `step-4 storage failure`: `RetentionWindow.place_under_retention` answering `storage-failure` with step 3's append committed.

   Terms › `mid-record expiry`: the lease expiring while the invocation is between step 2 and step 4 inclusive, no store having refused.

   Terms › `non-storage refusal`: `invalid-payload` at step 3; `invalid-request`, `invalid-policy` or `policy-not-found` at step 4.

   WHY: step 3 failing after step 2 leaves an orphan attestation, closed by Invariant 1's liveness arm and found by the binding-set half; step 4 failing after step 3 leaves an unretained event, closed by Invariant 2's arm and found by the third half. The two are not interchangeable, and which one the operator is looking at is read off the step. record_action step 7.5's refusals leave the same partial state but are input or deployment faults, and collapsing them into `recording-failure` would misname the cause. record_action step 7.6b names `step-3` or `step-4`, never `step-5`; a later success is the leg's. On a death-detected host the terminus is step 4's pre-check-and-adopt (Per-act section 10).

---

#### `seal_now`

```
seal_now() →
    evidence_id
  | rejected(
      nothing-to-seal
    | mechanism-failure(reason)
    | invalid-request
    | recording-failure
    )
```

Under interval or on-demand cadence, seals the current unsealed tail; [Record Action] step 6 and [Purge Event] step 0 reach it too.

```text
seal_now 1: [Seal Now] MUST read tail by the open-upper-bound read beginning at the slice's first sequence_number.
seal_now 2: [Seal Now] MUST NOT read next_sequence_number.
seal_now 3: IF the tail read returns no event THEN [Seal Now] MUST land [Nothing To Seal].
seal_now 4: [Seal Now] MUST call TamperEvidence.seal(slice_ref, mechanism_credential) over the slice.
seal_now 5: [Seal Now] MUST record the seal_coverage entry for evidence_id as the slice and advance sealed_through to tail.
seal_now 6: [Seal Now] MUST land mechanism-failure(reason) as [Mechanism Failure] carrying the reason unchanged.
seal_now 7: [Seal Now] MUST land invalid-request as rejected(invalid-request).
seal_now 8: [Seal Now] MUST land storage-failure as [Recording Failure].
seal_now 9: IF [Seal Now] rejects THEN sealed_through MUST NOT advance.
seal_now 10: IF [Seal Now] rejects THEN [Seal Now] MUST NOT write a seal_coverage entry.
seal_now 11: IF [Seal Now] rejects THEN the next cadence firing MUST re-seal the slice.
seal_now 12: The composition MUST NOT expose a re-sealing surface.
```

Terms › `slice`: the sequence-number range from `sealed_through + 1` to `tail`, inclusive.

Terms › `tail`: the highest `sequence_number` the open-upper-bound read beginning at `sealed_through + 1` returns; the empty result of that read is the empty-tail condition.

WHY:
The obvious alternative, *the log's `next_sequence_number` minus one*, reads an internal state field the atom exposes on no declared surface: it counts allocations rather than successful appends (Event Log's storage-failure gap), and Event Log's Invariant 5 was re-scoped off it for that reason. The three failure arms name three different things an operator has to fix. `mechanism-failure(reason)` carries two worlds on one arm — transient outage (signing hardware down, TSA unreachable, HSM session lost), which the next firing may clear, and standing misconfiguration (keying material that fails the running mechanism's preconditions), which every firing reproduces until Configuration changes — and the reason is what tells them apart. `invalid-request` is reserved by that atom for a record-set reference with no non-whitespace character or a credential absent entirely; neither comes from a caller, so the arm means a defect in the composition's own construction or a plumbing fault, standing rather than transient, a page for a human. `recording-failure` means the mechanism computed a proof and the seal store refused to persist it, with no partial evidence record written. Under every arm the events stay in the tail and `unsealed_tail_mode` governs what [Verify Record] says about them; a tail that stops draining is the alarm TV names. Re-sealing a partly-purged seal's survivors and rotating a seal onto a fresh mechanism belong to Seal Lifecycle *(forthcoming)*, with the supersession bookkeeping both require.

---

#### `read_record`

```
read_record(event_id) →
    audit_record
  | not-known
```

The consolidated read surface: a pure projection, the surface Invariant 6 rests on and the one [Audit Record] is produced by.

```text
read_record 1: [Read Record] MUST NOT change state.
read_record 2: [Read Record] MUST NOT produce an audit event.
read_record 3: [Read Record] MUST NOT carry a permissions layer at this composition.
read_record 4: [Read Record] MUST NOT verify.
```

Steps:

1. **Read the retention record.**
   ```text
   read_record step 1.1: [Read Record] step 1 MUST read the retention record through event_to_retention.
   ```
2. **Read the event.**
   ```text
   read_record step 2.1: [Read Record] step 2 MUST read the event per event_to_sequence 4 and event_to_sequence 5.
   ```
   WHY: `invalid-query` is unreachable by construction — the composition builds the query from its own index over a value Event Log itself assigned — so an implementation that observes it has a defective index, a deployment fault to alert on; that is why `read_record` carries a `not-known` arm and no rejection arm.
3. **Decide `not-known`.**
   ```text
   read_record step 3.1: IF retention record NOT EXISTS AND log entry NOT EXISTS THEN [Read Record] step 3 MUST land not-known.
   read_record step 3.2: [Read Record] MUST NOT land not-known for an event_id with a log entry.
   read_record step 3.3: The deployment MUST alert on a retention record whose event_id resolves to no log entry as a deployment fault.
   ```
   WHY: the conjunction is the definition of a fabricated id — no constituent has heard of it. The fourth cell of the two-by-two, a retention over a log-absent id, is unreachable by construction: step 4 places a retention only after step 3's append committed, a committed event never leaves the log, and the cascade transitions a retention without removing the entry. [Verify Record] step 2 and [Purge Event]'s `not-known` arm read the same two-by-two.
4. **Assemble the [Audit Record].**
   ```text
   read_record step 4.1: [Read Record] step 4 MUST assemble and return the audit record.
   read_record step 4.2: [Read Record] step 4 MUST report coverage status per event.
   read_record step 4.3: [Read Record] step 4 MUST return the covering seal's full range.
   read_record step 4.4: WHEN retention_state = Purged:
       read_record step 4.4a: [Read Record] step 4 MUST read action_ref, actor_ref and attested_at from the attestation store through the pair.
       read_record step 4.4b: [Read Record] step 4 MUST NOT read the who / what / when from the event payload.
       read_record step 4.4c: [Read Record] step 4 MUST return no data.
       read_record step 4.4d: IF pair NOT EXISTS THEN [Read Record] step 4 MUST return the audit record with attribution not-recoverable, the retention record in Purged with purged_at, the coverage status, sequence_number and recorded_at.
       read_record step 4.4e: IF pair NOT EXISTS THEN [Read Record] step 4 MUST NOT land not-known.
   ```
   Terms › `audit record`: the join of the event's `action_ref`, `actor_ref`, `sequence_number`, `recorded_at` and `data` where the content is still present; the `attestation_id` from `event_to_attestation`; the retention record's `retention_id`, policy reference, state, `retention_until`, `purge_deadline` and `purged_at` where set; and the coverage status.

   Terms › `coverage status`: `covered` (the covering `evidence_id` with the seal's full sequence-number range, `sealed_at`, and `anchored_at` where the mechanism anchors) | `unsealed tail` (`sequence_number` EXCEEDS `sealed_through`) | `records-purged` (the event's own `sequence_number` is a member of the covering seal's `purged_events`) | `partially purged` (the event's `sequence_number` is not a member while another member's is).

   Terms › `pair`: the destruction record's `(event_id, attestation_id)`, captured at [Purge Event] step 2.

   Terms › `who / what / when`: the attestation's `actor_ref`, `action_ref` and `attested_at`.

   WHY: returning the range is what makes [Verify Record]'s asymmetry usable (Invariant 7): the composition tells the caller what to present, and presenting exactly that is the whole of the caller's obligation. `partially purged` is the honest signal that [Verify Record] answers `unverifiable(partially-purged-coverage)`, standing, since there is no re-sealing surface. For a purged event the surviving carrier is the pair, and Actor Identity's Outputs — each attestation carries its own `attestation_id` among its fields — make an enumeration re-keyed on that id an id-addressed lookup built from nothing the atom does not declare, the mirror of `event_to_sequence`'s argument, landing differently because Event Log's `read` takes a query. read_record step 4.4d is the conformance failure Check 7.6 names, reported on the record: lawful destruction is never reported as absence. For a live event both sources carry the same `action_ref` and `actor_ref`, and reading either is correct.
5. **Orphan window.**
   ```text
   read_record step 5.1: IF log entry EXISTS AND retention record NOT EXISTS THEN [Read Record] step 5 MUST return the audit record with retention status unresolved (compensation window).
   read_record step 5.2: [Read Record] step 5 MUST NOT fabricate a retention.
   ```
   WHY: the event is real and the log proves it; the retention side has not landed yet and reconciliation owes it. The status is a surfaced compliance finding, not a steady state (Invariant 8).
6. **No verification** (read_record 4). [Read Record] presents; [Verify Record] proves. The split is forced by Invariant 7 — verification needs the original payload re-presented, and a read surface that fetched it internally would destroy the asymmetry the composition exists to surface.

---

#### `verify_record`

```
verify_record(event_id, original_event_payload) →
    outcome
  | not-known
```

`outcome` is `verified` | `failed-verification(reason)` | `unverifiable(reason)`, each of which may additionally carry the qualifier `(compensation-window)`.

```text
verify_record 1: The qualifier (compensation-window) MUST ride a separate channel beside the outcome.
verify_record 2: The composition MUST NOT fold the qualifier into a reason.
verify_record 3: The composition MUST NOT promote the qualifier to an outcome.
verify_record 4: not-known MUST NOT carry the qualifier.
```

WHY: step 2 can establish that the event is inside Invariant 2's compensation window, and that fact is orthogonal to every integrity finding the remaining steps produce, so all three combinations are reachable and meaningful — `verified (compensation-window)`, `failed-verification(seal-proof-invalid) (compensation-window)`, `unverifiable(attestation-registry-unavailable) (compensation-window)`. Folding it into a reason would accuse a record with nothing wrong with its integrity; promoting it would suppress the integrity answer the caller asked for. `not-known` presupposes no log entry, so it never carries the qualifier.

Steps:

1. **Retention state first.**
   ```text
   verify_record step 1.1: [Verify Record] step 1 MUST read the retention record through event_to_retention.
   verify_record step 1.2: IF retention_state = Purged THEN [Verify Record] step 1 MUST land failed-verification(purged).
   verify_record step 1.3: [Verify Record] MUST NOT run step 3 for a purged event.
   ```
   WHY: under a shredding-class mechanism the log entry is still there, so `not-known` was never the risk; what the cascade destroys is the payload and the `proof`, and every downstream check is payload-dependent — step 3 would re-check a `proof` the cascade destroyed and could only answer a non-`verified` arm. Reading the retention first answers out of the record the composition still has, and keeps it from reporting its own lawful destruction as an attestation failure.
2. **Log presence.**
   ```text
   verify_record step 2.1: [Verify Record] step 2 MUST read the event per event_to_sequence 4 and event_to_sequence 5.
   verify_record step 2.2: IF retention record NOT EXISTS AND log entry NOT EXISTS THEN [Verify Record] step 2 MUST land not-known.
   verify_record step 2.3: IF log entry EXISTS AND retention record NOT EXISTS THEN [Verify Record] MUST proceed to step 3 and carry the qualifier on the outcome.
   ```
   WHY: an event in the compensation window is verifiable but not yet retention-covered, and reporting the two facts separately is the honest form; [Read Record] step 5 surfaces the same finding as `unresolved (compensation window)`.
3. **Attestation.**
   ```text
   verify_record step 3.1: [Verify Record] step 3 MUST call ActorIdentity.verify on event_to_attestation's entry for the event_id.
   verify_record step 3.2: [Verify Record] step 3 MUST land a failed-verification(reason) with the reason prefixed attestation-.
   verify_record step 3.3: [Verify Record] step 3 MUST route registry-unavailable to step 6.
   verify_record step 3.4: [Verify Record] step 3 MUST land Actor Identity's not-known as failed-verification(attestation-not-known).
   verify_record step 3.5: IF step 3 lands failed-verification THEN [Verify Record] MUST return the step-3 outcome.
   verify_record step 3.6: IF step 3 lands failed-verification THEN [Verify Record] MUST NOT run steps 4, 5 and 6.
   verify_record step 3.7: IF step 3 routes registry-unavailable THEN [Verify Record] MUST NOT run steps 4 and 5.
   verify_record step 3.8: [Verify Record] MAY run steps 4 and 5 ONLY IF step 3 landed verified.
   ```
   WHY: `registry-unavailable` is a reason under Actor Identity's `failed-verification(...)` arm and is re-levelled, because *the registry was unreachable* is not a finding about the record; Actor Identity's `not-known` is an arm — the `attestation_id` does not resolve — and the event exists, so it is a broken link inside a known record, never the composition's own `not-known`. A record whose attribution has failed gains nothing from a subordinate finding against its seal; where verification could not be performed at all, no integrity claim is made either way, which is what makes step 6's answer *unknown* rather than *bad*.
4. **Locate the covering seal.**
   ```text
   verify_record step 4.1: [Verify Record] step 4 MUST locate the covering seal.
   verify_record step 4.2: IF partly-purged coverage EXISTS THEN [Verify Record] step 4 MUST land unverifiable(partially-purged-coverage).
   verify_record step 4.3: IF partly-purged coverage EXISTS THEN [Verify Record] MUST NOT run step 5.
   verify_record step 4.4: IF covering seal NOT EXISTS AND unsealed_tail_mode = strict THEN [Verify Record] step 4 MUST land failed-verification(unsealed).
   verify_record step 4.5: WHEN covering seal NOT EXISTS AND unsealed_tail_mode = lenient:
       verify_record step 4.5a: [Verify Record] step 4 MUST treat coverage as satisfied.
       verify_record step 4.5b: [Verify Record] MUST skip step 5 and proceed to step 6.
   ```
   Terms › `partly-purged coverage`: a covering seal whose `purged_events` is non-empty and does not contain the event's own `sequence_number`.

   WHY: Invariant 3 guarantees at most one covering seal. Under partly-purged coverage the record set cannot be re-presented, and nothing is known to be wrong with the event, so `failed-verification(seal-record-set-mismatch)` would be the composition manufacturing a finding out of its own lawful work; the answer stands for the rest of those events' retained lifetimes, and the remedy is Seal Lifecycle *(forthcoming)*. The `lenient` path reaches `verified` on the attestation check plus Event Log's per-event immutability, which is what the deployment declared.
5. **Seal.**
   ```text
   verify_record step 5.1: [Verify Record] step 5 MUST call TamperEvidence.verify(evidence_id, original_event_payload).
   verify_record step 5.2: [Verify Record] step 5 MUST land a failed-verification(reason) with the reason prefixed seal-.
   verify_record step 5.3: [Verify Record] step 5 MUST route mechanism-verification-unavailable to step 6.
   verify_record step 5.4: [Verify Record] step 5 MUST land Tamper Evidence's not-known as failed-verification(seal-not-known).
   ```
   WHY: the verifier presents what the covering seal commits to (Primitive policy 26): under per-event cadence typically this one event's payload; under interval-based or on-demand cadence the payloads of the seal's whole range, obtained through Event Log's range read over the range [Read Record] reported. An absent, short or wrong presentation surfaces as `failed-verification(seal-record-set-mismatch)` from Tamper Evidence.
6. **Availability arm.**
   ```text
   verify_record step 6.1: [Verify Record] step 6 MUST land unverifiable(attestation-registry-unavailable) for registry-unavailable.
   verify_record step 6.2: [Verify Record] step 6 MUST land unverifiable(seal-mechanism-verification-unavailable) for mechanism-verification-unavailable.
   ```
   WHY: a transient outage is *verification could not be performed*, emphatically not *this record failed*; retrying when the surface returns is the correct response. Step 4's `partially-purged-coverage` is the third reason on this arm and the one that is not transient; all three share the arm because they are the same kind of answer.
7. **Verified.**
   Terms › `standing finding`: a `failed-verification(reason)` or `unverifiable(reason)` outcome one of steps 1–6 landed.
   ```text
   verify_record step 7.1: IF standing finding NOT EXISTS THEN [Verify Record] step 7 MUST land verified.
   verify_record step 7.2: IF step 2 established the compensation window THEN the returned outcome MUST carry the qualifier.
   ```

---

#### `purge_eligible`

```
purge_eligible() → list of event_ids
```

```text
purge_eligible 1: [Purge Eligible] MUST delegate eligibility to RetentionWindow.purge_eligible.
purge_eligible 2: [Purge Eligible] MUST map each eligible retention_id to the event_id through the retention record's record_ref.
purge_eligible 3: [Purge Eligible] MUST NOT re-derive eligibility.
purge_eligible 4: [Purge Eligible] MUST NOT share the projection's now reading with a later RetentionWindow.purge.
purge_eligible 5: [Purge Eligible] MUST NOT reject.
purge_eligible 6: [Purge Eligible] MUST NOT filter by legal hold.
```

WHY:
Eligibility is derived at read time and never stored (Retention Window Invariant 11), so the eligibility clock is that instance's injected `now`, one reading per call. The projection and the purge are two readings at two moments — Retention Window's Invariant 8 single-reading discipline is scoped within its own Purge action — and the gap is harmless because eligibility is monotone in `now`: an event on the list cannot become ineligible before the cascade reaches it, and the residual disagreement is the benign one Retention Window's *Clock semantics* edge case names. The composition's own `now` governs `seal_cadence` and the scan's edges, nothing else. A pure projection over the retention store with no caller input has nothing to refuse. The list means *retention has elapsed*, which is true of a held record; a hold is refused at [Purge Event]'s gate, not filtered ahead of it.

---

#### `purge_event`

```
purge_event(event_id) →
    ok
  | rejected(
      not-known
    | not-eligible
    | retention-unresolved
    | cascade-failure(step)
    | under-legal-hold†
    )
```

For any event whose retention has elapsed, the composition coordinates a cascade across the four stores. The arms: `not-known` for an id no constituent knows; [Not Eligible] when Retention Window refuses because the period has not elapsed; [Retention Unresolved] when the id resolves to a log entry but to no retention record; [Cascade Failure] carrying the step; and, where a Legal Hold is composed, [Under Legal Hold].

```text
purge_event 1: IF retention record NOT EXISTS AND log entry NOT EXISTS THEN [Purge Event] MUST land rejected(not-known).
purge_event 2: [Cascade Failure] MUST carry EXACTLY ONE OF seal, step-1, step-2, step-3.
purge_event 3: WHEN cascade-failure = seal OR cascade-failure = step-1:
    purge_event 3a: The cascade MUST leave the retention in Retained.
    purge_event 3b: The cascade MUST write nothing.
    purge_event 3c: [Purge Eligible] MUST re-offer the event.
purge_event 4: WHEN cascade-failure = step-2 OR cascade-failure = step-3:
    purge_event 4a: The reconciliation scan MUST re-drive the entry.
    purge_event 4b: The deployment MUST surface an open entry as a compliance alert.
    NOTE: watch persistent state — the source says *until the scan closes it*; the duration is carried by the term open entry (purge_event 4b), by *for the rest of the run* (Per-act section 5) and by *through the outage* (Composition-level invariant 1b).
purge_event 5: WHEN Legal Hold = composed:
    purge_event 5a: [Purge Event] MUST carry the under-legal-hold arm.
    purge_event 5b: IF hold EXISTS THEN [Purge Event] MUST land rejected(under-legal-hold) with no cascade step executed.
purge_event 6: IF Legal Hold != composed THEN [Purge Event] MUST NOT carry the under-legal-hold arm.
purge_event 7: WHEN mid-cascade expiry EXISTS:
    purge_event 7a: [Purge Event] MUST NOT issue a further write.
    purge_event 7b: [Purge Event] MUST return rejected(cascade-failure(step)) naming the first step not completed.
    purge_event 7c: The reconciliation scan MUST re-drive the cascade.
```

Terms › `Legal Hold`: `composed` | `absent` — whether the deployment composes the [Legal Hold](../atoms/legal-hold.md) pattern over this instance.

Terms › `hold`: a Legal Hold preservation order over the record.

Terms › `mid-cascade expiry`: the lease expiring after step 1 has committed and before step 3's outcome record has landed.

Terms › `cascade-failure(step-3)`: a delegation not issued, an outcome not recorded, or a reported `destruction-failed(reason)` — three failures leaving one world, retention *Purged* over readable content.

WHY:
`seal` is named separately from `step-1` because the surface that refused is the seal mechanism or seal store, and the remedy is [Seal Now]'s three-way diagnosis rather than a retention retry; under both, nothing changed anywhere and the ordinary sweep re-offers the event. `step-2` and `step-3` are the dangerous half: the record says the content was lawfully destroyed while the evidence is missing or the content is still readable, and the state is invisible to [Purge Eligible], whose projection is false for a *Purged* retention — so the sweep never re-offers it and the reconciliation scan is the retry trigger, at restart and on `reconciliation_cadence`, the entry standing as a surfaced alert bounded by `compensation_window`. Absorbing either into a bare `ok` would hide the gap this composition exists to make unhideable; collapsing the two would tell an operator to retry when the retry path is a scan, or to run a scan when a retry would do. † The hold arm is conditional because a composition that declared it unconditionally would promise a hold check it does not perform; [Legal Hold](../atoms/legal-hold.md) owns the gate and this composition names where it lands — a preservation order, so a partial cascade under a hold would be the exact destruction the order forbids.

Steps:

0. **Seal before purge.**
   ```text
   purge_event step 0.1: [Purge Event] step 0 MUST resolve event_to_sequence for the event_id.
   purge_event step 0.2: IF the event's sequence_number EXCEEDS sealed_through THEN [Purge Event] step 0 MUST invoke [Seal Now].
   purge_event step 0.3: [Purge Event] MUST NOT run step 1 BEFORE the covering seal exists.
   purge_event step 0.4: IF [Seal Now] rejects THEN [Purge Event] MUST land rejected(cascade-failure(seal)).
   purge_event step 0.5: IF the covering seal EXISTS THEN [Purge Event] step 0 MUST NOT invoke [Seal Now].
   ```
   WHY: step 2's destruction record lives on a covering `seal_coverage` entry, and an event with no covering entry has nowhere to record that it was destroyed — the cascade would move the retention to *Purged* and then produce `cascade-failure(step-2)` by construction on every tail purge. Under per-event cadence the step is almost always a no-op, reachable only where the record-time seal failed and the tail has not drained.

   **Step 0½ — retention must be resolved before the cascade proper begins.**
   ```text
   purge_event step 0½.1: [Purge Event] MUST NOT run step 0½ BEFORE step 0.
   purge_event step 0½.2: IF log entry EXISTS AND retention record NOT EXISTS THEN [Purge Event] step 0½ MUST land rejected(retention-unresolved).
   purge_event step 0½.3: A retention-unresolved refusal MUST run no cascade step.
   purge_event step 0½.4: A retention-unresolved refusal MUST leave step 0's seal standing.
   purge_event step 0½.5: The composition MUST NOT invent a retention in order to expire an event.
   ```
   WHY: a half-step because it is a second precondition, not a store-touching step. `RetentionWindow.purge` takes a `retention_id` and there is none; the remedy is the third half's placement, after which the event is purgeable, or not, on the same terms as every other. A tail event that got sealed is in a state the composition wanted regardless. The check sits after step 0 because step 0's resolution is what establishes that a log entry exists — the antecedent that distinguishes `retention-unresolved` from `not-known`.
1. **Purge the retention.**
   ```text
   purge_event step 1.1: [Purge Event] step 1 MUST call RetentionWindow.purge(retention_id).
   purge_event step 1.2: [Purge Event] step 1 MUST land retention-period-not-elapsed as [Not Eligible].
   purge_event step 1.3: [Purge Event] step 1 MUST land not-known as rejected(not-known).
   purge_event step 1.4: IF step 1 lands not-retained THEN the cascade MUST resume from step 2.
   purge_event step 1.5: [Purge Event] step 1 MUST land storage-failure as rejected(cascade-failure(step-1)).
   ```
   WHY: the one constituent with a purge surface, and even it deletes no record — `purge` is a state transition, the record survives in *Purged* with `purged_at`, and that surviving record is the evidence the destruction was lawful. purge_event step 1.4 is what makes a re-driven or retried cascade idempotent.
2. **Write the destruction record, before anything is destroyed.**
   ```text
   purge_event step 2.1: [Purge Event] step 2 MUST write the destruction record in one durable write.
   purge_event step 2.2: The destruction record MUST add the event's sequence_number to the covering seal's purged_events.
   purge_event step 2.3: The destruction record MUST carry the pair, read from event_to_attestation with rebuild-on-miss.
   purge_event step 2.4: [Purge Event] MUST NOT issue the delegation BEFORE the destruction record has landed.
   purge_event step 2.5: A step-2 failure MUST land rejected(cascade-failure(step-2)).
   ```
   WHY: the binding lives inside the payload and step 3 destroys the payload's recoverability, so a cascade that captured the pair after the delegation would read a binding that no longer exists; capturing it here keeps the traversal *purged event → the attestation destroyed with it* possible at all. Both facts are extraction-pending truth against Erasure Tombstone, and this write is the part of the cascade carrying a durability obligation (Durability 6). The seal record itself is retained indefinitely as evidence that the records existed and were sealed before they were destroyed.
3. **Delegate the destruction.**
   ```text
   purge_event step 3.1: [Purge Event] step 3 MUST delegate destruction to erasure_mechanism.
   purge_event step 3.2: The cascade MUST NOT destroy content.
   purge_event step 3.3: The delegation MUST name the whole of Event Log's data field and the attestation's proof, and nothing else.
   purge_event step 3.4: [Purge Event] step 3 MUST record the mechanism's outcome in erasure_outcomes.
   purge_event step 3.5: IF outcome = destruction-failed THEN [Purge Event] step 3 MUST land rejected(cascade-failure(step-3)).
   purge_event step 3.6: A delegation not issued MUST land rejected(cascade-failure(step-3)).
   purge_event step 3.7: An outcome not recorded MUST land rejected(cascade-failure(step-3)).
   purge_event step 3.8: The cascade MUST NOT record a destroyed outcome the mechanism did not report.
   purge_event step 3.9: The composition MUST NOT repair a partly-purged seal.
   purge_event step 3.10: A partly-purged seal MUST remain the one seal over the seal's range.
   ```
   WHY: what is destroyed is exact, and the exactness is the point — the surviving fields stay readable, so the *who / what / when* outlives the purge, read through the pair from here on. In the execution contract's vocabulary this step is a mechanism-capability invocation ([`execution-contract.md`](../execution-contract.md) §Substrate composition invocation): the capability is declared, the consuming surface is composition-introduced, the invocation is logic-confinement-clean, and the construct carries a named exit — Erasure Tombstone *(forthcoming)*. Swallowing a negative outcome would produce the state Invariant 8 forecloses with the composition's own records agreeing; the scan re-drives a `destruction-failed` entry every cycle until `destroyed` lands, the loop whose terminus Ledger line 2026-08-30-d names. The survivors verify as `unverifiable(partially-purged-coverage)` from here on.
4. **What survives a completed cascade.**
   ```text
   purge_event step 4.1: A completed cascade MUST leave standing the retention record in Purged with purged_at, the seal record with the event's sequence_number in purged_events, the destruction record's pair, the destroyed outcome in erasure_outcomes, and the attestation's surviving fields.
   purge_event step 4.2: The delegation MUST cover the event and the attestation in one cascade under one retention_id.
   ```
   Terms › `completed cascade`: a cascade whose step 3 recorded a `destroyed` outcome.

   WHY: the retention record proves the destruction was lawful; the seal record proves a record set existed and which members were destroyed; the pair is the traversal the payload can no longer supply; the outcome record proves the delegation completed, which is what the scan tests; the surviving fields are the *who / what / when*. Once Erasure Tombstone lands, the tombstone naming what was destroyed and under whose authority joins the set.

### The cascade-on-purge rule

The composition's load-bearing wiring decision: when an event's retention elapses, the composition first ensures the event is covered by a seal (purge_event step 0.1–0.5), then purges the one record it is permitted to purge — the Retention Window record (purge_event step 1.1) — writes a destruction record adding the event's sequence number to the covering seal's `purged_events` set and capturing the event's `(event_id, attestation_id)` binding before it is destroyed (purge_event step 2.1–2.4), and delegates destruction of Event Log's `data` field and the attestation's `proof` to the deployment's shredding-class erasure mechanism (purge_event step 3.1–3.4). It coordinates the cascade and records the outcome; it destroys nothing itself (purge_event step 3.2), disposes of no seal (Composes 16), and re-seals nothing (seal_now 12).

WHY:
*Principle.* When a regulated record reaches the end of its lifetime, all four stores must reach a coherent end state together: no retained event without attribution or integrity coverage, and no destroyed event leaving a dangling attestation or a live content claim on a seal. Coordinating that across four independent stores is work no constituent can do — each knows only its own record — so it belongs at the composition layer, with the honest record of what the coordination achieved.

*Likely objection.* Why not have the composition delete the content directly? It knows which event, which attestation and which seal are involved, and a cascade that ends in a delegation looks like one that does not finish.

*Mechanism that resolves it.* Two of the four constituents forbid it in their own invariant text, and a composition that overrode them would be silently substituting weaker atoms. Event Log declares only `append` and `read`, holds Invariant 1 (append-only), and routes true deletion to a composing pattern in its *Right-to-be-forgotten erasure* edge case. Actor Identity's Invariant 9 states that an attestation is never deleted by the atom and that cascading deletion under a retention policy is the composing pattern's responsibility. So the destruction surface is named where the atoms say it belongs — an Erasure Tombstone *(forthcoming)* composing pattern, or cryptographic shredding at the storage layer, declared per deployment — and this composition wires the coordination around it.

*Result.* Four constituent invariants hold verbatim over their instances — Event Log's 1 and 2, Actor Identity's 9 and 1 — which is what makes Invariant 5 a literal claim; a lawfully destroyed event still answers `failed-verification(purged)` from its *Purged* record, still leaves a seal whose `purged_events` names it, and still distinguishes lawful destruction from a missing record (Invariant 8).

#### Boundary one — only shredding-class mechanisms conform

The class boundary's home; erasure_mechanism 1–9, [Purge Event] step 3, Invariant 5 and the [Purge Event] card cite it.

```text
Boundary one 1: [Purge Event] MUST NOT write the destruction record BEFORE step 1's transition has committed.
Boundary one 2: The composition MUST NOT condition RetentionWindow.purge's outcome on the erasure mechanism's answer.
Boundary one 3: The composition MUST record a divergence between a Purged retention and readable content.
Boundary one 4: The composition MUST surface a divergence as a compliance alert.
Boundary one 5: The composition MUST bound a divergence by compensation_window.
Boundary one 6: The first half MUST re-drive a divergence on EVERY run.
```

Terms › `divergence`: a retention in *Purged* over content still readable — `cascade-failure(step-3)`; a `destruction-failed` outcome in `erasure_outcomes`.

WHY:
A conforming mechanism destroys the key material under which the content was stored and leaves every stored field as written, which is why Event Log Invariant 2 and Actor Identity Invariant 1 — immutability claims over stored fields, neither claiming readability — survive the cascade verbatim; tombstone-by-mutation breaks exactly those two (erasure_mechanism 2). Erasure Tombstone records destruction as a new write-once record and never mutates the record it describes. One constituent prescription is declined by name: Retention Window's *Divergence between retention state and underlying record* edge case has `purge` return `storage-failure` when destruction cannot be confirmed. This composition cannot take it — the destruction record must be written after the transition and before the delegation (Boundary one 1, purge_event step 2.4), and the destruction is performed by a mechanism `RetentionWindow.purge` has no view of — so the divergence is recorded, surfaced, bounded and re-driven rather than prevented (Boundary one 3–6), the trade that buys the durable pre-destruction record. The terminus of Boundary one 6's loop is the open question Ledger line 2026-08-30-d names.

#### Boundary two — the composition disposes of no seal and writes no replacement

```text
Boundary two 1: EVERY seal MUST remain the only seal over the seal's range.
Boundary two 2: IF seal disposal EXISTS THEN the deployment MUST compose Erasure Tombstone for the seal-disposal surface and the coverage bookkeeping.
Boundary two 3: IF re-sealing EXISTS THEN the deployment MUST compose Seal Lifecycle.
Boundary two 4: The composition MUST NOT carry a which-seal-is-current fact.
```

Terms › `seal disposal`: a jurisdiction's requirement to dispose of a seal — a commitment over erased personal data treated as residual personal data.

Terms › `re-sealing`: a deployment's requirement to write a second seal over a range some seal covers — a partly-purged seal's survivors made verifiable again, or a seal rotated onto a sound mechanism ahead of a deprecation.

WHY:
A seal is a proof, not a copy, and its indefinite retention (retention_policy 5) keeps Invariant 3 and Tamper Evidence's Invariant 9 unconditionally true: a seal that survives its records is the evidence that they existed. Tamper Evidence's *retention coupling* edge case suggests purging a seal over a destroyed record set; this composition takes the reading Tamper Evidence's Invariant 9 supports, and a jurisdiction that treats a commitment over erased data as residual data composes Erasure Tombstone, which then owns which events lose their cover. The cost of no replacement seal is named on the same terms: survivors answer `unverifiable(partially-purged-coverage)` for their retained lifetimes, and a seal cannot be rotated ahead of a deprecation — the remedy Tamper Evidence's Invariant 2 prescribes. Both need a *which seal is current* fact, new truth no constituent carries and no rebuild replays (Tamper Evidence's *Concurrent seals on the same record set* takes no view on supersession), so absorbing it would hold unclassifiable truth for a concept not yet specified.

#### The reconciliation scan — three halves

The composition's three liveness arms fail in three structurally different ways — a cascade that stopped partway, an attestation nothing points at, and an event nothing bounds — and each needs its own detector, predicate and compensating write. A scan that ran only the first two would carry the third state forever, because no other surface looks for it.

```text
Reconciliation scan 1: The reconciliation scan MUST run a first half over Purged retentions, a second half over the attestation store, and a third half over the audit log.
Reconciliation scan 2: The scan MUST surface EVERY unreconciled finding as a compliance alert.
Reconciliation scan 3: The scan MUST NOT carry an unreconciled finding silently.
Reconciliation scan 4: The scan MUST close EVERY finding WITHIN compensation_window of the finding's creation.
NOTE: watch satisfaction — what a run that misses WITHIN is (Reconciliation scan 4, Invariant 1.4, Invariant 2.2) is decided by Composition-level invariant 1 for an outage and by Check 2 otherwise; the language says nothing.
Reconciliation scan 5: The scan MUST read now once per run at the scan's own seam.
Reconciliation scan 6: The scan MUST NOT write BEFORE taking the per-act section for the act.
Reconciliation scan 7: EVERY half MUST decide a write by the half's own predicate, read under the section.
```

Terms › `record_edge`: `record_action_completion_bound + clock_skew_allowance`.

Terms › `purge_edge`: `purge_completion_bound + clock_skew_allowance`.

Terms › `horizon`: the retention period `retention_policy` gives an `audit.compensation` event.

Terms › `purge age`: `now − purged_at`.

Terms › `attestation age`: `now − attested_at`.

Terms › `event age`: `now − recorded_at`.

WHY:
The halves share a trigger (reconciliation_cadence 1, reconciliation_cadence 2), a surfacing discipline (Reconciliation scan 2, Reconciliation scan 3), a deadline measured from the finding's creation (compensation_window 2, Reconciliation scan 4), and two edges. Below, each half examines nothing younger than its completion bound widened by the allowance, because each stamp was written at a constituent's seam and the scan's `now` is read once at its own (Reconciliation scan 5, clock_skew_allowance 2); the comparison only excludes a record from the pass (clock_skew_allowance 4). Above, the horizon is the point past which the compensation event a half would look for has been lawfully purged, and there the half reports rather than repairs.

*First half — the half-completed cascade.*

```text
First half 1: The first half MUST enumerate Purged retentions.
First half 2: IF purge_edge EXCEEDS purge age THEN the first half MUST NOT examine the retention.
First half 3: The first half MUST test EVERY examined retention for a purged_events membership, a pair in the destruction record, and a destroyed outcome in erasure_outcomes.
First half 4: The first half MUST test for a destroyed outcome.
First half 5: The first half MUST re-drive a retention failing First half 3 through [Purge Event].
First half 6: The first half MUST NOT re-read the predicate BEFORE taking the section keyed by event_id.
First half 7: The first half MUST NOT write BEFORE re-reading the predicate under the section.
First half 8: The first half MUST re-drive EVERY examined open entry on EVERY run.
```

WHY: a crash between the cascade's steps is reachable, and the state is invisible to [Purge Eligible], whose projection is false for a *Purged* retention — the retry can never be driven from the eligible list. A cascade still inside its bound is in flight, not half-completed (First half 2). Presence of an outcome record is not the test (First half 4): an entry carrying `destruction-failed` is a retention saying *lawfully destroyed* over readable content, and a predicate that accepted any outcome would close it on the evidence of its own failure. Two scan runs, or a run and a cascade short of its bound, never both drive one entry (First half 6, First half 7).

*Second half — the orphan-attestation predicate.*

```text
Second half 1: The second half MUST build the binding set.
Second half 2: The second half MUST treat an attestation absent from the binding set as an orphan.
Second half 3: IF record_edge EXCEEDS attestation age THEN the second half MUST NOT examine the attestation.
Second half 4: IF attestation age EXCEEDS horizon THEN the second half MUST report the orphan as beyond the horizon.
Second half 5: IF attestation age EXCEEDS horizon THEN the second half MUST NOT write a compensation.
Second half 6: A beyond-horizon report MUST carry subject = attestation, the attestation_id and disposition = beyond-horizon, as an audit.reconciliation record.
Second half 7: The second half MUST NOT report BEFORE reading reported_beyond_horizon under the section.
Second half 8: The second half MUST NOT report an orphan whose attestation_id is a member of reported_beyond_horizon.
Second half 9: The second half MUST NOT write a compensation BEFORE reading compensated_attestations under the section keyed by the orphan's attestation_id.
Second half 10: The second half MUST NOT write a compensation for a reconciled orphan.
Second half 11: The second half MUST hold the section through the compensating write.
Second half 12: A writer other than the scan MUST NOT write an orphan's compensation.
Second half 13: The second half MUST write EXACTLY ONE compensation per orphan.
```

Terms › `binding set`: the union of the `attestation_id`s carried in live event payloads, from the full enumeration, and the `attestation_id`s in destruction records.

Terms › `orphan`: an attestation in the store whose `attestation_id` is in neither enumeration of the binding set.

WHY: *an attestation with no event* is not a fact any single store holds, so the set needs both enumerations: the first alone would report every lawfully purged event's attestation as an orphan the day its payload was shredded, the second alone would see nothing but purges — Check 7's live/purged split read in the other direction. An attestation younger than `record_edge` may be a [Record Action] between steps 2 and 3, and a compensation for it would be a false record the seal then protects (Second half 3). Past the horizon the compensation, had it been written, has been purged out of the rebuild, so the half reports once (Second half 4–7). The orphan is permanent, so without Second half 9 a scan would compensate it every cadence forever; the pair under the section is what makes it a decision rather than a race (Concurrency 9). The invocation writes nothing (record_action step 7.8), so a stalled invocation waking after the scan has nothing left to write.

*Third half — the unretained-event predicate.*

```text
Third half 1: The third half MUST enumerate the audit log by the full enumeration.
Third half 2: The third half MUST test EVERY returned event against event_to_retention with rebuild-on-miss.
Third half 3: The third half MUST NOT conclude a missing retention BEFORE rebuilding event_to_retention.
Third half 4: IF record_edge EXCEEDS event age THEN the third half MUST NOT examine the event.
Third half 5: The third half MUST take the section keyed by the event's payload attestation_id for a true miss.
Third half 6: The third half MUST NOT place BEFORE re-reading event_to_retention under the section.
Third half 7: The third half MUST hold the section through the placement.
Third half 8: The third half MUST NOT place BEFORE the audit.reconciliation intent has landed.
Third half 9: The third half MUST NOT write the audit.compensation record BEFORE the placement has landed.
Third half 10: The audit.compensation record MUST carry subject = event and the event_id.
Third half 11: The scan MUST retry a refused compensating [Record Action].
Third half 12: The third half MUST treat an owed narration as a repair to record.
Third half 13: The next run MUST NOT record an owed compensation BEFORE confirming under the section that the retention exists.
Third half 14: The third half MUST NOT treat an intent past the horizon as a finding.
```

Terms › `true miss`: a miss of `event_to_retention` that survives the rebuild.

Terms › `owed narration`: an `audit.reconciliation` intent older than `record_action_completion_bound`, inside the horizon, whose subject has no matching `audit.compensation` record — both read composition-side out of the full enumeration filtered on the two reserved references.

WHY: the state step 4 leaves when it fails after step 3 is durable and invisible to every other surface — [Purge Eligible] enumerates retentions, the first half *Purged* retentions, the second half attestations, and an unretained event's attestation is perfectly bound. A scan that read a lost index entry as *no retention exists* would place a second retention over an event that already had one, which Retention Window's Invariant 5 records as new and which falsifies Invariant 2's *exactly one* (Third half 3). Intent before act lets the trail show the repair was the scan's; placement before compensation keeps the compensation truthful (Third half 8, Third half 9). A crash between the two leaves the gap closed but unrecorded, and the intent record is its detector (Third half 12, Third half 13) — what can be delayed is the narration, never a false closure and never an unclosed gap. Check 2's retention side is this half run from outside.

*Where the compensation lands — the composition is its own event log.*

```text
Compensation 1: The scan MUST record EVERY finding as an audit.reconciliation event through [Record Action].
Compensation 2: The scan MUST record one audit.reconciliation record per finding.
Compensation 3: The scan MUST NOT write a compensating act BEFORE the finding's audit.reconciliation record has landed.
Compensation 4: The scan MUST record EVERY compensating write as an audit.compensation event through [Record Action].
Compensation 5: The scan MUST supply actor_ref = reconciliation_operator and credential = reconciliation_operator_credential at EVERY reconciliation-path [Record Action].
Compensation 6: The composition MUST NOT grow a second store for the reconciliation history.
Compensation 7: The composition MUST NOT add an action for the reconciliation path.
Compensation 8: The composition MUST place a reconciliation-path event under retention_policy like any other event.
```

WHY:
The findings and the compensating writes are audit events — attested, sequenced, retention-governed and sealed like the events they are about — so *what did this system do about the gap it found?* has a first-class answer from the same traversal. One record per finding keeps any findings set inside `payload_cap`. The reserved namespace (Primitive policy 8, Primitive policy 9) is the difference between a marker that is evidence of a compensation and one that is anybody's claim. The scan is an ordinary caller of [Record Action] (Compensation 5); `execution-contract.md` has a composition record a multi-step sequence by composing Event Log, never by growing a second store, and this composition *is* an Event Log composition (Compensation 6, Compensation 7).

---

## Composition-level invariants

These invariants emerge from the composition; none belongs to a single constituent atom. Each carries a *Rests on:* line naming the wiring that establishes it and the constituent invariants it stands on. Per [`spec-format.md`](../spec-format.md) §Structural-relation invariant templates, the composition's three structural relations are: event ↔ attestation, one-to-one, mandatory on both sides at quiescence (Invariant 1, in the orphan-freedom template's safety-plus-liveness form); event ↔ retention, one-to-one, mandatory on both sides at quiescence, the retention governing the event's attestation jointly (Invariant 2); seal → events, one-to-many, optional on the event side while the event is in the unsealed tail and mandatory once `sequence_number` ≤ `sealed_through` (Invariant 3) — a composed Seal Lifecycle *(forthcoming)* would make it many-to-one and own the *which seal is current* bookkeeping that reading requires. The inverse directions are read through the derived indexes; a lost index entry is a rebuild trigger, never a relation violation.

```text
Composition-level invariant 1: WHEN store outage EXISTS:
    Composition-level invariant 1a: The liveness arms of Invariants 1, 2 and 8 MUST suspend for the outage.
    Composition-level invariant 1b: EVERY outstanding finding MUST stay surfaced through the outage.
```

Terms › `store outage`: a constituent store unreachable.

Terms › `compliance alert`: a finding surfaced on the deployment's alerting surface, never silently carried.

Terms › `quiescence`: no [Record Action] in flight, `compensation_window` elapsed, constituent stores reachable.

Terms › `recorded through [Record Action]`: the quantifier of Invariants 1, 2 and 8 — this composition declares exactly one way in, and an event written around it is not one these invariants cover (Non-goal 2).

WHY: reconciliation is itself a [Record Action] against the attestation, log and retention stores, and the pre-check reads the retention store, so a store that cannot be reached suspends the window's closure rather than falsifying the claim.

- **Invariant 1 — Attribution coverage (safety + liveness at quiescence).**
  ```text
  Invariant 1.1: An action of this composition MUST NOT leave an event in the audit log with the event's attestation side unbound and unsurfaced.
  Invariant 1.2: [Record Action] MUST NOT append BEFORE attesting.
  Invariant 1.3: EVERY appended event MUST carry a committed attestation_id inside the event's own payload.
  Invariant 1.4: The scan MUST surface and reconcile EVERY orphan WITHIN compensation_window of the orphan's attested_at.
  Invariant 1.5: WHEN quiescence EXISTS:
      Invariant 1.5a: For EVERY event_id recorded through [Record Action], event_to_attestation's entry MUST reference a recorded attestation carrying a readable action_ref and actor_ref.
      Invariant 1.5b: EVERY attestation in the store MUST fall in EXACTLY ONE OF the binding set, compensated_attestations.
  Invariant 1.6: WHEN retention_state != Purged:
      Invariant 1.6a: The attestation's action_ref and actor_ref MUST match the event payload's, byte for byte.
  Invariant 1.7: WHEN retention_state = Purged:
      Invariant 1.7a: The attestation the pair names MUST exist with readable surviving fields.
      Invariant 1.7b: An auditor MUST evaluate Invariant 1.5a against the attestation store's surviving fields alone.
      Invariant 1.7c: An auditor MUST NOT read the who / what / when from the destruction record.
  Invariant 1.8: A new orphan a compensating write leaves MUST count as a new finding with the new orphan's own attested_at.
  Invariant 1.9: The scan's next run MUST retry EVERY orphan not yet reconciled.
  Invariant 1.10: The composition MUST NOT condition convergence on a compensating write succeeding.
  ```
  *Rests on:* [Record Action] steps 2, 3 and 5; the liveness arm on [Record Action] itself — the compensating record is written through it under `audit.compensation` and the finding under `audit.reconciliation` (Compensation 1–5), with the observable closure on `compensated_attestations` pre-checked under the per-`attestation_id` section (Second half 9, Concurrency 9); Actor Identity Invariants 1 (attestation immutability), 2 (action binding), 3 (actor binding) and 9 (attestation durability — why the closure needs a marker at all, since the orphan it forecloses deleting is permanent); Event Log Invariants 1 (append-only) and 2 (event immutability).

  WHY: the reverse partial is reachable and durable, since synchronous rollback is unavailable, so the honest claim is a surfaced transient under compensation, never a quiet inconsistency. *Reconciled* is membership in `compensated_attestations` because nothing about the attestation itself ever changes to say *dealt with*; the marker is not forgeable (Primitive policy 8, reconciliation_operator 2, Check 7). A compensation is an ordinary [Record Action] and can itself fail at step 3, leaving a new orphan; the chain terminates the way retries terminate, each orphan bounded from its own creation, no link unsurfaced (Invariant 1.8). The clause compares differently by retention state because the cascade destroys one side of the comparison and not the other.

- **Invariant 2 — Retention coverage (safety + liveness at quiescence).**
  ```text
  Invariant 2.1: A successful [Record Action] MUST NOT return an event_id with no retention record.
  Invariant 2.2: The scan MUST reconcile EVERY unretained event WITHIN compensation_window of the event's recorded_at by placing the missing retention.
  Invariant 2.3: The reconciliation path MAY place a retention ONLY IF true miss EXISTS for the event_id.
  Invariant 2.4: WHEN quiescence EXISTS:
      Invariant 2.4a: For EVERY event_id recorded through [Record Action], event_to_retention's entry MUST reference EXACTLY ONE recorded retention of either retention_state.
  ```
  *Rests on:* [Record Action] steps 3, 4 and 5; the liveness arm on [Record Action] itself (Compensation 1–5); the composition's own `event_to_retention` pre-check under the per-act section and below `record_edge` (Third half 2–7, Concurrency 6), which supplies the idempotence Retention Window's Invariant 5 nowhere declares; the third half as the arm's detector (Third half 1); [Purge Event] step 0½ as the arm that keeps the cascade out of the window (purge_event step 0½.2); Retention Window Invariants 1 (membership exclusivity), 5 (`record_ref` and `policy_ref` immutability, and the new-retention-on-re-retention-under-a-different-policy rule that makes the pre-check necessary) and 10 (retention store durability); Event Log Invariant 1.

  WHY: a failure between step 3 and step 4 is reachable because an appended event cannot be withdrawn; it is surfaced as `rejected(recording-failure(step-4))` and reconciled by placing the missing retention. Retention Window's Invariant 5 says re-retaining under a different policy produces a new retention with a new id and declares nothing about the same policy, so `place_under_retention` is nowhere idempotent on `record_ref`, and a path that re-placed on every pass would accumulate retentions governing one event — falsifying *exactly one* in the direction the atom cannot refuse. Without the third half this arm would have a compensation and no detector.

- **Invariant 3 — Integrity coverage (modulo unsealed tail).**
  ```text
  Invariant 3.1: IF sealed_through EXCEEDS the event's sequence_number OR sealed_through = the event's sequence_number THEN EXACTLY ONE seal MUST cover the event.
  Invariant 3.2: A purged event MUST remain covered by the covering seal.
  ```
  *Rests on:* [Seal Now] (and [Record Action] step 6 under per-event cadence), with [Purge Event] step 0 keeping it true of every purged event by construction; Tamper Evidence Invariants 1 (evidence immutability), 3 (record-set binding) and 9 (seal store durability, why a seal outlives the records it committed to); Event Log Invariants 3 (total order) and 4 (sequence-number monotonicity), without which a contiguous range is not a well-defined cover.

  WHY: the claim is exact because there is exactly one way a coverage entry gets written — [Seal Now] cuts the slice and advances `sealed_through` past it, so slices are contiguous, disjoint and strictly advancing (seal_coverage 7, seal_coverage 8). *At most one* follows from disjointness and *at least one* from the bound; the claim is over seals, full stop, with no second class of seal to quantify around. What a purged event loses is verifiability, not coverage, and [Verify Record] reports that honestly. The claim is unconditional rather than modulo a seal lifetime because seals are retained indefinitely (retention_policy 5); Erasure Tombstone composed for seal disposal and Seal Lifecycle composed for re-sealing would each put it modulo their own bookkeeping, and both are named and out of scope. The unsealed tail is a bounded gap the cadence shrinks and `unsealed_tail_mode` names what a verifier makes of it.

- **Invariant 4 — Cascade coordination on purge.**
  ```text
  Invariant 4.1: A [Purge Event] MUST leave the four stores in the coherent end state: the event covered, the retention in Purged with purged_at, the sequence_number in purged_events with the pair captured, and the destruction delegated with the outcome recorded.
  Invariant 4.2: The cascade MUST commit the steps in the declared order.
  Invariant 4.3: The composition MUST NOT claim an atomic set spanning the retention transition and the delegated destruction.
  Invariant 4.4: An auditor MUST clear the delegated destruction's completion outside the records.
  ```
  *Rests on:* [Purge Event] steps 0–4, defended by the cascade-on-purge rule; Retention Window Invariants 3 (terminal absorption), 7 (no early purge) and 8 (purge timestamp consistency); Tamper Evidence Invariant 1; Event Log Invariant 1 and Actor Identity Invariant 9, which are what make the delegation necessary rather than optional.

  WHY: the invariant is over the coordination, not over a destruction this composition performs: no retained event is left without attestation or integrity coverage, and no purged event leaves a dangling attestation reference or a live seal content claim. The retention transition and the delegated destruction are each un-withdrawable, so no atomic set spans them (§*Durability boundaries*); the coordination is ordered writes plus compensation — a partial state surfaces as `cascade-failure(step)` and the scan re-drives it — and a `destruction-failed` outcome leaves the coordination incomplete, re-driven each cycle until it completes (Boundary one 6).

- **Invariant 5 — Constituent invariants preserved.**
  ```text
  Invariant 5.1: EVERY invariant of the four constituent atoms MUST hold over the atom's instance.
  Invariant 5.2: The composition MUST NOT remove a log entry.
  Invariant 5.3: The composition MUST NOT rewrite a stored field of a constituent record.
  ```
  *Rests on:* the whole action wiring — every constituent call this composition makes is a declared surface of that constituent, and no step reaches around one; the cascade-on-purge rule is where the claim would otherwise break; Composes 13, Composes 15 and Composes 16 for the seal store.

  WHY: one sentence carries the whole of what makes it literal, argued at Boundary one: the cascade delegates destruction to a shredding-class mechanism that destroys recoverability while leaving every stored field as written. Granting it, the four invariants the cascade could threaten hold verbatim — Event Log 1 (no entry removed), Event Log 2 (no stored field rewritten; shredding destroys the key, not the bytes), Actor Identity 9 (no attestation deleted), Actor Identity 1 (no attestation field rewritten). The composition's only writes into the seal store are `TamperEvidence.seal` calls from [Seal Now]: new evidence records, none mutated (Tamper Evidence Invariant 1), none deleted (Tamper Evidence Invariant 9).

- **Invariant 6 — Forensic completability.**
  ```text
  Invariant 6.1: For EVERY event_id, [Read Record] MUST return EXACTLY ONE OF the audit record, not-known.
  Invariant 6.2: For EVERY event_id, [Verify Record] MUST return EXACTLY ONE OF verified, failed-verification(reason), unverifiable(reason), not-known.
  Invariant 6.3: IF verification surface outage NOT EXISTS THEN [Verify Record] MUST answer deterministically over a fixed record set.
  ```
  Terms › `verification surface outage`: the actor registry or the seal mechanism unreachable.

  *Rests on:* [Read Record] and [Verify Record]; for a purged event the *who / what / when* half of the join on the pair captured at [Purge Event] step 2 and the surviving fields it names (read_record step 4.4), the only route left once Event Log's `data` field is unreadable; Actor Identity Invariants 1 and 9 (without which the record would not still be there to read), 6 (self-containment) and 7 (verification consistency under fixed registry state); Tamper Evidence Invariants 4 (verification self-containment given the originating records) and 7 (verification consistency under a fixed record set); Invariants 1–3 above for the completeness of what is joined.

  WHY: an investigator reconstructs the full history from records alone. The hedge *where content is still present* is the cascade's, not a softening: completability is a claim about the record set, not the content. The availability condition is the reason the [Unverifiable] arm exists — when the registry or the mechanism cannot be reached the honest answer is that verification could not be performed — and determinism is claimed over the outcomes reachable with the surfaces up. The first three outcomes may carry the `(compensation-window)` qualifier on the separate channel.

- **Invariant 7 — Verification asymmetry preserved.**
  ```text
  Invariant 7.1: [Verify Record] MUST require the original record set re-presented.
  Invariant 7.2: [Verify Record] MUST NOT require the actor's credential beyond the registry's public material.
  Invariant 7.3: The composition MUST NOT fetch the covering record set internally for verification.
  ```
  *Rests on:* [Verify Record] steps 3 and 5; [Read Record] step 4, which supplies the covering range (read_record step 4.3); Primitive policy 25–28, which fix both shapes; Tamper Evidence Invariants 3 (record-set binding) and 4; Actor Identity Invariant 6.

  WHY: the asymmetry inherits Tamper Evidence's verification self-containment given the originating records and Actor Identity's verification self-containment, and it surfaces at the caller boundary — which is why [Read Record] does not verify (read_record 4): a read surface that fetched the payload internally would hide exactly this asymmetry. The asymmetry extends to cadence rather than being narrowed by it: the verifier presents what the covering seal commits to (Primitive policy 26), and only its extent moves; what the composition owes in exchange is knowing which record set that is, discharged through [Read Record]'s returned range.

- **Invariant 8 — Honest representation of destruction (at quiescence).**
  ```text
  Invariant 8.1: WHEN quiescence EXISTS:
      Invariant 8.1a: EVERY event the composition recorded MUST stand in EXACTLY ONE OF retained, lawfully destroyed.
  Invariant 8.2: A retained event MUST carry a retention record in Retained.
  Invariant 8.3: A lawfully destroyed event MUST carry a retention record in Purged with purged_at, the sequence_number in the covering seal's purged_events, the pair in the destruction record, and a destroyed outcome in erasure_outcomes.
  Invariant 8.4: [Verify Record] MUST NOT read purged off the absence of content.
  Invariant 8.5: The composition MUST reserve not-known for an event_id no constituent has heard of.
  ```
  Terms › `event standing`: `retained` | `lawfully destroyed`.

  *Rests on:* [Purge Event] steps 0, 1, 2 and 4 and [Verify Record] steps 1–2; [Read Record] step 5 and [Verify Record] step 2 for the compensation-window reading (read_record step 5.1, verify_record step 2.3); the liveness arm — that the compensation-window state is bounded and closes — on [Record Action], through which the scan records its findings and the compensating placement (Compensation 1–5); Retention Window Invariants 1 (membership exclusivity), 3 (terminal absorption) and 10 (retention store durability); Tamper Evidence Invariant 1; Invariant 2 above for the window it is conditioned on and Invariant 4 for the coordination that produces the surviving records.

  WHY: *missing without record* does not occur through this composition. The fourth record is why the foreclosed state stays foreclosed, and the mechanism is the scan: a `destruction-failed` delegation leaves *Purged* over readable content, and First half 4's predicate re-drives it every cycle — foreclosed because the scan retries, not because failure was assumed away. Every purged event has a covering entry by construction (purge_event step 0.3). Without the quiescence qualifier this invariant would contradict Invariant 2's liveness arm; inside the window the event is verifiable but not yet retention-covered, a bounded finding, not a third steady state. Reading `purged` off the record rather than off the absence of content is what makes the distinction survive every conforming erasure mechanism.

Attribution coverage and retention coverage together give the complete-record property; integrity coverage modulo unsealed tail names the cadence trade-off honestly; cascade coordination on purge prevents dangling state across the four stores without pretending to a destruction surface two constituents forbid; honest representation of destruction is what distinguishes a *complete* audit trail from a *suspicious* one.

---

## Examples

### Walkthrough

A regulated bank deploys the composition as the canonical audit trail for its core ledger: `retention_policy = sox_7_year`; `seal_cadence = every 1000 events or 60 seconds, whichever first`; `seal_mechanism = SHA-256 hash chain, chain tail anchored synchronously at seal time to an RFC 3161 TSA`, linked across seals; `erasure_mechanism = per-event content-key shredding at the storage layer`; `compensation_window = 24 hours`; `record_action_completion_bound = 30 seconds`; `purge_completion_bound = 5 minutes`; `compensation_closure_latency = 15 seconds`; `clock_skew_allowance = 2 seconds`; `reconciliation_cadence = 60 seconds` (the derived default — the time arm of its interval cadence; the thousand-event arm is not a duration); `payload_cap = 64 KB`, matching the wired Event Log instance. Instance start 16 holds with room to spare: `closure_sum` is 5 minutes + 2 seconds + 60 seconds + 15 seconds, against 24 hours.

1. **A wire-transfer authorization arrives.** `record_action(wire_w91, supervisor_s12, supervisor_credential, {amount: 50000, counterparty: ...})`. Actor Identity → `attestation_a44`; Event Log → `event_e9301`; Retention Window → `retention_r9301` with `retention_until = 2033-05-10`; the event lands in the unsealed tail. Returns `event_e9301`.
2. **The cadence fires.** The thousand-event arm trips first: [Seal Now] runs over the slice `[8302 .. 9301]`, whose last member is `e9301`. The chain tail is anchored to the TSA synchronously, within the seal call — which is what entitles the record to carry `anchored_at` at all; batched anchoring after the fact is a separate External Anchoring pattern — and `evidence_s127` is recorded with `anchored_at = 2026-05-10T14:33:00Z`. The `seal_coverage` entry for `s127` is `[8302 .. 9301]`; `sealed_through` advances to 9301.
3. **Six years later, a SOX §404 audit.** *Show me the supervisor authorization on wire w91, and prove it hasn't been altered.* `read_record(e9301)` returns the [Audit Record] in one shot: action `wire_w91`, actor `supervisor_s12`, attestation `a44`, retention `r9301` in *Retained*, and coverage `s127` over `[8302 .. 9301]` — the instruction for the next call. This deployment runs interval cadence, so the auditor pulls all thousand payloads for that range — through Event Log's range read where the log is online, from the archive otherwise — and calls `verify_record(e9301, payloads_8302_through_9301)`. Retention reads *Retained* (no `purged` short-circuit), the event is present, the attestation verifies against `s12`'s public material, `s127` is the covering seal, the presented range passes through to `TamperEvidence.verify`. Returns `verified`. Under a per-event cadence the same call would carry `e9301`'s single payload; the argument is the same argument, only its extent moves.
4. **Seven years and one month later.** [Purge Eligible] runs nightly and `e9301` is on the list. `purge_event(e9301)`: step 0 is a no-op — `9301 ≤ sealed_through`, so `s127` covers it. `RetentionWindow.purge(r9301)` moves the retention to *Purged* with `purged_at = 2033-06-14`; `9301` joins `s127`'s `purged_events` — just that one number, since the other 999 members are under their own retentions — and the same write captures the pair `(e9301, a44)` before anything is destroyed. Destruction of Event Log's `data` field for `e9301` and of `a44`'s `proof` goes to the content-key shredder, which reports `destroyed`; the cascade completes. Had it reported `destruction-failed(...)`, the cascade would have rejected `cascade-failure(step-3)` and the 60-second scan would have re-driven the entry each cycle until a `destroyed` outcome landed, `r9301` standing as a surfaced alert meanwhile. The Event Log entry's and the attestation's stored fields are byte-for-byte what they were; the key is gone, so the payload and the proof no longer read, while `a44`'s `action_ref`, `actor_ref` and `attested_at` still do. `verify_record(e9301, ...)` now returns `failed-verification(purged)`, read off `r9301` before any `ActorIdentity.verify` call. No re-seal follows: `s127` stays the one seal over `[8302 .. 9301]`, and its 999 survivors answer `unverifiable(partially-purged-coverage)` for the rest of their retained lifetimes — unknown, not bad. A bank that could not accept that composes Seal Lifecycle *(forthcoming)*, at the cost of a mechanism round-trip per purge and a pattern to wire.
5. **A subsequent regulator inquiry.** *What happened to wire w91?* The retention store holds `r9301` in *Purged* with `purged_at` inside the lawful window; the seal store retains `s127` indefinitely, now carrying `9301` in `purged_events` and still the cover for its other members; the attestation store retains `a44` with its surviving fields readable. `read_record(e9301)` sees *Purged*, takes `(e9301, a44)` out of the destruction record, and reads the *who / what / when* off `a44` — so the answer is not merely *something was destroyed* but *`supervisor_s12`'s authorization of `wire_w91`, attested at that moment, was destroyed lawfully on 2033-06-14*.

### Walkthrough — rejection paths

**Orphan attestation — `attest` succeeds, `append` fails.** `record_action(wire_w92, supervisor_s12, supervisor_credential, {amount: 75000, ...})`.

1. Step 1 passes: both references are far inside the 1 KB cap and the full constructed payload is about 2 KB against the 64 KB cap. Nothing is recorded yet.
2. Step 2: `ActorIdentity.attest(...)` → `attestation_a45`, committed and immutable.
3. Step 3: `EventLog.append({...})` — the store is mid-failover and returns `storage-failure`. Per Event Log's contract that is definitive: `event_e9302` does not exist and never will.
4. The composition returns `rejected(recording-failure(step-3))` and, in the same outcome, surfaces `a45` as an orphan; it writes nothing further, releases its section on `a45`, and yields. Once `a45`'s `attested_at` is older than 30 + 2 seconds, the scan takes the section on `a45`, records an `audit.reconciliation` finding naming it, then a compensating record naming `a45` as unbound — through [Record Action] under `audit.compensation`, attributed to the bank's operator identity, raised as a high-priority compliance finding. The scan found `a45` by the binding-set test — in the attestation store, in no live payload, in no destruction record — and, finding it absent from `compensated_attestations`, wrote the one compensation; the next scan leaves it alone.
5. The caller retries after the store recovers and gets a fresh `attestation_a46` and `event_e9303`. `a45` remains in the store forever as a surfaced, reconciled orphan — the honest record of what happened rather than a defect to be hidden.

Had `data` been 80 KB, the rejection would have arrived at step 1 as `rejected(invalid-request)` with nothing recorded — no attestation to orphan; that is why the size check sits where it does.

**`not-eligible` — a purge attempted before the window elapses.** In 2030 a records-management job misconfigured with a five-year policy calls `purge_event(e9301)`.

1. The composition resolves `r9301` and calls `RetentionWindow.purge(r9301)`.
2. Retention Window evaluates its no-early-purge guard against its own `now`: `2030-06-14 < 2033-05-10`. It refuses with `retention-period-not-elapsed`, writing nothing (Retention Window Invariant 7).
3. The composition returns `rejected(not-eligible)`. No cascade step runs: nothing joins `s127`'s `purged_events`, no delegation is issued, `r9301` stays *Retained*, and `verify_record(e9301, ...)` still returns `verified`.
4. The gate is structural: the composition does not evaluate eligibility itself, and the atom's guard is a precondition on its own state.

### Selected rejection and outcome runs

Selected, not exhaustive; each makes a distinction the composition is built on legible.

**`unverifiable(attestation-registry-unavailable)`.** During the same audit, `verify_record(e9308, payloads_9302_through_10301)`: retention *Retained*, log entry present, `ActorIdentity.verify(a51)` — and the registry is unreachable behind a network partition. Step 3 does not prefix `registry-unavailable`; it routes it to step 6, which returns `unverifiable(attestation-registry-unavailable)`. Steps 4 and 5 do not run, so no integrity claim is made either way. The auditor records the outage, not a finding, and retries when the registry returns.

**A `lenient`-mode tail verify.** A second deployment — an internal operations trail over a WORM substrate, `seal_cadence = every 6 hours`, `unsealed_tail_mode = lenient` — records `e440` at 09:12 and verifies it at 09:20. `read_record(e440)` reports *unsealed tail* (`440 > sealed_through = 431`). `verify_record(e440, e440_payload)`: retention *Retained*, log entry present, attestation verifies; step 4 finds no covering seal and, under `lenient`, treats coverage as satisfied, skips step 5, finds no availability failure at step 6, and returns `verified` at step 7. The same call against the bank's `strict` instance returns `failed-verification(unsealed)` — same records, different declared posture, visible in Configuration.

**`invalid-credential` — rejected before anything is written.** A terminated supervisor's smart card: `record_action(wire_w95, supervisor_s12, revoked_credential, {...})`. Step 1 passes; step 2's `attest` refuses `invalid-credential`; the composition propagates it and stops. No attestation, no event, no retention, no seal attempt, no orphan. The log carries no trace of the attempt — the scope line of Failed attribution 1; a deployment that must audit the attempt composes a Failed-Attempt Log *(forthcoming)*.

### Regulated deployments

*Banking — SOX §404.* Every action against the general ledger is recorded with the controller's attested approval, retained 7 years per SOX §802, sealed in a hash-chained log anchored to a qualified TSA; the external auditor walks the trail without privileged database access, and [Verify Record] over each in-scope action is what *adequate internal controls* operationally means.

*Healthcare — HIPAA §164.312(b).* Every read, write or amendment of protected health information is recorded with the clinician's attestation, retained for the longer of HIPAA's 6-year baseline or state law, sealed in a per-patient Merkle tree; a §164.524 access request and a breach investigation walk the same trail.

*Payments — PCI DSS Requirement 10.* Every access to cardholder data, every export, every key-management operation is recorded with the operator's attestation, retained per Requirement 3.1, HMAC-chained per 10.5; the annual QSA assessment runs [Verify Record] over the year's high-risk actions.

*Pharmaceutical — 21 CFR Part 11.* Every change to an electronic batch record is recorded with the operator's qualified electronic signature, retained per the predicate rule, sealed in a hash chain; an FDA inspection produces the verified history of any batch, and the ALCOA properties are the composition's emergent property.

*Communications — SEC Rule 17a-4.* Every business communication at a registered broker-dealer is recorded with the originator's attestation, retained 3–7 years with the first two immediately accessible (composing a Storage Tier *(forthcoming)*), Merkle-tree sealed; a FINRA examination and a litigation discovery walk the same trail. WORM storage is one mechanism the composition can be realized over; the composition names the structural form.

### Regulated adversarial scenarios

**Regulator audit — "show me the complete, verifiable history of action X over the retention horizon."** *Every event referencing action X* is a query by payload field, so the enumeration is a composed Reverse Index *(forthcoming)*, not a passthrough (Action wiring 3, Action wiring 4); a sequence-number or wall-time window would pass straight through. From there the composition answers per event: `verified` for each retained event, the *Purged* retention record for each destroyed one. Invariants 1, 2, 3 and 8 are the structural answer, from the records, without source code or runbooks.

**Disputed action — "I didn't do that."** The investigator retrieves the event and calls [Verify Record]. If `verified`, the attestation binds the named actor to the named action at `attested_at` (Actor Identity's non-repudiation contract, through Invariant 5); the actor cannot plausibly deny it without claiming credential compromise, which a Compromise Disclosure pattern *(forthcoming)* handles by new records, never by mutating the trail.

**Breach forensics — "when was the trail compromised?"** The responder walks every seal in `sealed_at` order — one seal per range, never a replacement — running [Verify Record] against representative events in each range. The most recent seal that returns `verified` end-to-end and the next that returns `failed-verification(seal-proof-invalid)` bound the forensic window, provided the mechanism is chained across seals (seal_mechanism 2); under independent per-range seals a failed seal narrows the tampering only to its own range, and the responder gets a set of compromised ranges rather than a window — which of the two the mechanism is, the deployment declares, since mechanism opacity hides it (Tamper Evidence Invariant 8). An `unverifiable(...)` result bounds nothing: under the availability reasons the responder retries; under `partially-purged-coverage` the responder steps over the seal to the nearest presentable one, which widens the window rather than falsifying it. Where seals carry `anchored_at` from a TSA outside the adversary's reach, the upper bound on the time of tampering is independently established.

---

## Generation acceptance

A derived implementation of Audit Trail is acceptable — in the regulator-acceptance sense — when an external auditor, given the composition's emergent state plus the four constituent stores, can clear the checks below without recourse to source code, runbooks or developer narration. The first list is what the composition's own records answer; the second is what arises around the composition and needs evidence the composition does not hold.

### Record checks

```text
Check 1.1: An auditor MUST obtain, from one [Read Record] call on any event_id, the joined audit record — what, who, integrity and retention.
Check 1.2: An auditor MUST confirm that not-known is returned only for an event_id no constituent knows.
Check 2.1: An auditor MUST verify all eight composition-level invariants over the record set.
Check 2.2: An auditor MUST verify Invariants 1 and 2 at quiescence, reading the quiescence condition from compensation_window.
Check 2.3: An auditor MUST enumerate the log against the attestation store and the retention store.
Check 2.4: IF attestation age EXCEEDS audit edge THEN an auditor MUST read an unreconciled orphan as a residual finding.
Check 2.5: IF event age EXCEEDS audit edge THEN an auditor MUST read an unreconciled unretained event as a residual finding.
Check 2.6: IF audit edge EXCEEDS a finding's age THEN an auditor MUST NOT read the finding as a residual finding.
Check 2.7: IF attestation age EXCEEDS horizon THEN an auditor MUST read the orphan against the scan's beyond-horizon audit.reconciliation findings.
Check 2.8: An auditor MUST NOT read a purged compensation of a standing orphan as a violation.
Check 2.9: An auditor MUST run the retention side of the enumeration as the mirror of the third half: the full enumeration, the per-event test of event_to_retention with rebuild-on-miss first, and a true miss past the window read as a finding.
Check 2.10: An auditor MUST build the binding set and take EVERY attestation in neither enumeration as an orphan.
Check 2.11: An auditor MUST read an orphan in compensated_attestations as reconciled and the orphan's audit.compensation event as the proof.
Check 2.12: An auditor MUST read an orphan not in compensated_attestations, past compensation_window, as the residual finding.
Check 2.13: IF compensation_window NOT EXISTS THEN an instance MUST fail Check 2.
Check 3.1: An auditor MUST verify all seven Event Log invariants over the audit log instance.
Check 3.2: An auditor MUST read a violation of Event Log Invariant 7 as a clock finding.
Check 3.3: An auditor MUST verify Actor Identity's, Retention Window's and Tamper Evidence's Generation-acceptance bars over the respective instances.
Check 4.1: An auditor MUST bound the forensic window of any detected tampering by the latest verified seal and the first failed seal, with the seal stamps.
Check 4.2: An auditor MUST walk EVERY entry in the seal store.
Check 4.3: An auditor MUST step over a seal answering unverifiable(partially-purged-coverage) to the nearest presentable seal.
Check 4.4: An auditor MUST read the mechanism's chaining posture from the deployment's declaration.
Check 5.1: An auditor MUST confirm, for EVERY purged event, that failed-verification(purged) is backed by the records of Check 5.2–5.8.
Check 5.2: An auditor MUST confirm the retention record in Purged.
Check 5.3: An auditor MUST confirm the event's own sequence_number in the covering seal's purged_events.
Check 5.4: An auditor MUST read a purged event with no covering entry as a conformance failure.
Check 5.5: An auditor MUST confirm the pair in the destruction record.
Check 5.6: An auditor MUST confirm the attestation the pair names exists with readable surviving fields.
Check 5.7: An auditor MUST read a mechanism that destroyed more than the data field and the proof as non-conforming.
Check 5.8: An auditor MUST confirm a destroyed outcome recorded for the event in erasure_outcomes.
Check 5.9: An auditor MUST NOT read a destruction-failed record as completion.
Check 5.10: An auditor MUST confirm the live members of a partly-purged seal answer unverifiable(partially-purged-coverage).
Check 5.11: An auditor MUST read an instance answering verified for a live member of a partly-purged seal as composing Seal Lifecycle, audited against that pattern's bar.
Check 5.12: An auditor MUST confirm an event with no retention record inside compensation_window carries retention status unresolved (compensation window).
Check 5.13: An auditor MUST confirm [Purge Event] over an event with no retention record inside compensation_window returns rejected(retention-unresolved).
Check 6.1: An auditor MUST confirm that verification could not be performed surfaces as unverifiable(reason) and never as failed-verification(reason), for attestation-registry-unavailable, seal-mechanism-verification-unavailable and partially-purged-coverage.
Check 7.1: An auditor MUST discard event_to_retention, event_to_sequence, sealed_through, seal_coverage's ranges, compensated_attestations and reported_beyond_horizon, run the rebuild procedures against the constituent stores, and reproduce EVERY traversal answer.
Check 7.2: An auditor MUST discard event_to_sequence first.
Check 7.3: An auditor MUST confirm EVERY member of compensated_attestations came from an event carrying an audit.* action_ref whose payload actor_ref = reconciliation_operator.
Check 7.4: An auditor MUST regenerate event_to_attestation's entry for EVERY live event from the event's payload.
Check 7.5: An auditor MUST confirm event_to_attestation's entry for EVERY purged event is present in the destruction record.
Check 7.6: An auditor MUST read a purged event with no destruction-record pair as a conformance failure.
Check 7.7: An auditor MUST confirm the scan's binding set and event_to_attestation's two halves agree.
Check 7.8: An auditor MUST NOT expect a rebuild of an extraction-pending fact.
Check 8.1: An auditor MUST identify the composing patterns active in the deployment and the patterns' configuration.
Check 8.2: An auditor MUST NOT run Check 1–7 BEFORE identifying Reverse Index, Legal Hold, Erasure Tombstone composed for seal disposal, and Seal Lifecycle.
```

Terms › `audit edge`: `compensation_window + clock_skew_allowance` — the auditor's own reading compared to a constituent's stamp only under the allowance.

Terms › `residual finding`: an unreconciled finding older than the audit edge — the conformance failure Check 2 reports.

Terms › `seal stamps`: `sealed_at`, and `anchored_at` where the mechanism anchors.

Terms › `extraction-pending fact`: `purged_events`, `event_to_attestation`'s purged entries, and `erasure_outcomes`.

WHY:
Check 2 reads quiescence off a declared number, not the spec's confidence; its retention side is the third half run from outside (Check 2.9), and its orphan side is audited against a marker because Actor Identity Invariant 9 makes *no orphans remain* unreachable — what a conforming instance reaches is *every orphan compensated* (Check 2.10–2.12). Event Log carries no acceptance bar, so its seven invariants are verified directly (Check 3). Check 4 clears as a window only under a chained mechanism, which opacity keeps out of the records (Check 4.4). Check 5 reads records, not the absence of content, and mere presence of an outcome record would clear the state Invariant 8 forbids (Check 5.9). Check 6's third reason is the sharpest, because the composition's own cascade created the condition. Check 7.3 is what makes `compensated_attestations` unforgeable; the three extraction-pending facts are verified by Check 5 instead (Check 7.8). Check 8's full list: Legal Hold, Defensible Retention, and *(forthcoming)* Trusted Timestamping, Storage Tier, Compromise Disclosure, Erasure Coordination, Policy Reconciliation, Mechanism Registry, Reverse Index, Legacy Import, Failed-Attempt Log, Schema Evolution, Erasure Tombstone, Seal Lifecycle, and the declared erasure mechanism; the four Check 8.2 names change what the other checks mean.

### Generator's contract

```text
Generator's contract 1: An implementation derived from this composition MUST produce records and a runtime surface that clear Check 1–8.
Generator's contract 2: An implementation derived from this composition MUST make External check 1–6 askable, naming the external evidence each needs.
```

### External checks

```text
External check 1: An auditor MUST clear from external evidence that the erasure mechanism was authorized to destroy, is shredding-class, and completed each destruction.
External check 2: An auditor MUST clear from external evidence that the actor registry retained the registry's historical public material across key rotation.
External check 3: An auditor MUST clear from external evidence that the seal mechanism is cryptographically sound for the audit horizon.
External check 4: An auditor MUST clear from external evidence that the mechanism's seal-time rendering agrees with the verify-time presentation.
External check 5: An auditor MUST clear from external evidence that the clock was monotonic and unmanipulated over the audit horizon.
External check 6: An auditor MUST clear from external evidence that the configured retention_policy was the correct one for the record class.
```

Terms › `external evidence`: evidence outside the records — the mechanism's documentation and configuration, the registry's retention policy, cryptographic review, time-service logs, the deployment's regulations.

WHY:
The records show a changed stored field against the immutability invariants and cannot show that the key really went away — the direct cost of the delegation, part of which migrates to the traversal list once Erasure Tombstone lands (External check 1). A registry that drops superseded material fails old attestations for a reason that has nothing to do with the trail (External check 2). A rendering mismatch surfaces as `failed-verification(seal-proof-invalid)`, indistinguishable from tampering — the worst ambiguity for the one answer this composition exists to give (External check 4). Every stamp is only as truthful as the injected clock (External check 5). Code generated from this composition must clear the eight traversal checks and make the six external questions askable, naming the evidence each needs.

---

## Non-goals

```text
Non-goal 1: The composition MUST specify one instance.
Non-goal 2: The composition MUST NOT provide a path for a pre-attestation legacy event.
Non-goal 3: A Legacy Import pattern MUST NOT write into the audit log around [Record Action].
Non-goal 4: A Legacy Import pattern MUST take EXACTLY ONE OF attesting each imported record under a declared import identity through [Record Action], a separate unattested store the auditor reads as explicitly unattributed history.
Non-goal 5: The composition MUST NOT invalidate an attestation retroactively.
Non-goal 6: The composition MUST NOT adjudicate an erasure request against a retention obligation.
Non-goal 7: The composition MUST NOT declare a seal-store retention owner.
Non-goal 8: The composition MUST NOT rotate a seal onto a new mechanism.
Non-goal 9: seal_mechanism MUST govern seals cut from the time of setting on.
Non-goal 10: The composition MUST NOT treat a storage tier differently at [Verify Record].
```

WHY: multi-instance configuration and federation are the deployment layer's — an Audit Federation pattern *(forthcoming)* composes naturally (Non-goal 1). An import identity binds the importer, not the original actor; whether the attribution gap is acceptable is a legal question about the imported body (Non-goal 2–4). Attestations made during a compromise window verify but should be reinterpreted by new records — Compromise Disclosure *(forthcoming)* (Non-goal 5). A GDPR Article 17 request colliding with a retention obligation is Erasure Coordination's *(forthcoming)* decision, with counsel in the loop (Non-goal 6). A coarse cadence has a second cost that arrives years later: the more live seal-mates each purge strands. Seals already written stay under the mechanism that produced them (Non-goal 8, Non-goal 9). Storage Tier *(forthcoming)* owns the active-to-cold transition (Non-goal 10).

### Legal hold suspension of purge

Where the composed hold lands is [Purge Event], not [Purge Eligible] (purge_event 5, purge_eligible 6); [Defensible Retention](./defensible-retention.md) already wires the gate over a business record set. A deployment wanting a hold-filtered worklist asks the composed Legal Hold pattern.

### Failed attribution attempts

```text
Failed attribution 1: The composition MUST NOT record a [Record Action] rejected at step 1.
Failed attribution 2: The composition MUST NOT record a [Record Action] rejected at step 2.
```

WHY: the audit surface is committed actions, not attempted ones; a Failed-Attempt Log *(forthcoming)* records the rejected attempt for deployments where an insider retrying with forged credentials is itself auditable.

Where the composition breaks down: when the four constituent stores share an adversary with write access to all of them and external anchoring is absent; when the host cannot supply a stable, reproducibly-addressable record set at verify time; when the retention policy and the integrity-coverage cadence are mismatched — events purged before their covering seal is verified against them; when the actor registry's historical public material is not retained and old attestations begin failing under a new key.

## Edge cases

### Concurrency

Four serialization obligations, all implementation-owned.

```text
Concurrency 1: The implementation MUST serialize the read-seal-advance sequence per instance across [Seal Now], the cadence-fired seal and [Purge Event] step 0.
Concurrency 2: The implementation MUST serialize the cascade per event_id.
Concurrency 3: The implementation MUST protect the destruction-record write against a lost membership.
Concurrency 4: A per-evidence_id serialization MAY discharge Concurrency 3.
Concurrency 5: An atomic set-add MAY discharge Concurrency 3.
NOTE: watch cardinality — an inclusive *either discharges it* has no form; written as one obligation and two MAY rules (Concurrency 3–5). The same pressure at Second half 12 (one writer) and Compensation 2 (one record per finding).
Concurrency 6: [Record Action] steps 3–5 MUST run under the per-act section keyed by the attestation_id step 2 returned.
Concurrency 7: [Record Action] steps 1–2 MUST NOT require composition-level serialization.
Concurrency 8: [Record Action] step 6 MUST take the per-instance sealing lock of Concurrency 1.
Concurrency 9: The scan MUST serialize an orphan's compensation per attestation_id.
Concurrency 10: [Read Record] and [Purge Eligible] MUST NOT take a serialization lock.
```

WHY: two sealings reading the same `sealed_through` would produce two `evidence_id`s over one range, violating Invariant 3, and Tamper Evidence will not stop them — one seal per record set per cadence is the composing pattern's job (Concurrency 1). The cascade and its second step contend on different resources: the cascade on `event_id` — the per-act section for a cascade, its lease `purge_completion_bound` long — while the step-2 write contends on the covering seal's entry, shared by every member of the range, where a read-modify-write under the race silently loses a membership no rebuild brings back; the per-`event_id` lock alone is the natural mistake (Concurrency 2, Concurrency 3). The record action's section exists from the act's first write, which a per-`event_id` key could not; step 6 is the read-seal-advance sequence Concurrency 1 governs (Concurrency 6). An orphan has no `event_id` to lock; unserialized, a restart scan and a cadence scan both read *absent* and both record — duplicates are not false, but they make *once, or looping?* a question answered by reading timestamps (Concurrency 9).

### Durability across crashes

The obligation follows the classification, not the element list.

```text
Durability 1: The composition MUST treat a crash that records the event and loses a derived-index entry as a rebuild trigger.
Durability 2: The reconciliation path MUST NOT read a lost event_to_retention entry as absent.
Durability 3: An id-addressed action MUST NOT treat an event_to_sequence miss as not-known.
Durability 4: A short rebuild of a closed-state marker MUST NOT produce a false record.
Durability 5: A short rebuild of a closed-state marker MAY produce a duplicate record.
Durability 6: The deployment MUST persist purged_events membership, the pair and erasure_outcomes with the cascade's write.
Durability 7: The implementation MUST own the transactional boundary for the truth-bearing writes.
```

WHY: `event_to_retention`'s rebuild-on-miss is load-bearing because Invariant 2's placement pre-checks it (Durability 2); `event_to_sequence`'s is the hottest, because every id-addressed action resolves through it (Durability 3). `compensated_attestations` is safe in the direction that matters — nothing enters the set except a compensation that was recorded (Durability 4). The membership and the pair are unreproducible because the cascade destroys the payload the rebuild would read; `erasure_outcomes` because re-driving over destroyed content need not answer `destroyed` again (Durability 6). `event_to_attestation` is a discardable index for a live event and durable truth for a purged one, and an implementation that treats the map uniformly gets one half wrong. Until Erasure Tombstone lands, the deployment owns persisting all three.

### Cross-store consistency under failure

```text
Cross-store 1: The composition MUST require ordered writes plus compensation for a sequence of un-withdrawable writes.
Cross-store 2: The composition MUST NOT require a rollback of a committed constituent write.
Cross-store 3: The implementation MUST own how the implementation's own process survives the gap between two commits.
```

WHY: if `EventLog.append` succeeds and `place_under_retention` fails, the composition is in a state Invariant 2's safety arm forbids at quiescence, and append-only forecloses withdrawing the event; the attestation and the append are each un-withdrawable, so *all succeed or none* is not a state the constituents can offer (§*Durability boundaries*). The failure is surfaced as `rejected(recording-failure(step))`, recorded as a compliance finding, and reconciled within `compensation_window`; the finding and the compensating write are audit events through [Record Action] (Compensation 1–8), never an operational log. The scan's three predicates are all stated (FH, SH, TH); the cascade's own half-completed state needs the first half because it is invisible to [Purge Eligible].

### Verification of the unsealed tail

```text
Unsealed tail 1: The deployment MUST monitor tail depth and age against seal_cadence.
Unsealed tail 2: The deployment MUST read a [Mechanism Failure] with a preconditions reason as a standing misconfiguration.
Unsealed tail 3: The deployment MUST read a [Seal Now] invalid-request as a standing defect.
```

WHY: two things put an event in the tail — the cadence has not fired, or a seal attempt failed — and a tail that stops draining is an operational alarm, not a silent gap. [Nothing To Seal] is not an alarm. An outage reason is transient and the next firing may clear it; a preconditions reason (wrong-shape keying material, which Tamper Evidence routes here rather than to `invalid-request`) reproduces every firing until Configuration changes; [Recording Failure] means the store refused and the next firing re-seals the same slice. A preconditions reason or `invalid-request` is a page for a human, not something to wait out.

### Partial attestation on step failure

The state, the surfacing and the closure are owned where they happen: the invocation surfaces the orphan in `rejected(recording-failure(step-3))` and writes no compensation (record_action step 7.2, record_action step 7.8); the scan is the one writer of the compensating record (Second half 12), finds the orphan by the binding set (Second half 1, Second half 2), examines nothing younger than `record_edge` (Second half 3), and pre-checks `compensated_attestations` (Second half 9); reconciled has the observable form the term `reconciled` names; the compensating record is an audit event (Compensation 4). High-assurance deployments treat any orphan not in the set, past the window, as a gap in the audit surface and alert.

### Clock source for cadence and purge

```text
Clock source 1: The composition MUST NOT read now other than for the seal_cadence timer and the scan's once-per-run reading.
Clock source 2: The composition MUST NOT run the transition BEFORE reading now at the composition's I/O seam.
Clock source 3: An invocation in flight MUST NOT read a clock.
Clock source 4: The deployment MUST supply a monotonically non-decreasing clock.
```

Terms › `invocation`: a [Record Action] or a [Purge Event] between the invocation's first write and the invocation's return.

WHY: the orchestration transition is a pure function of injected `now` (`execution-contract.md` §Logic Confinement). An invocation's terminus at the completion bound is the expiry of a lease the host times, and on a death-detected host it is *proceed as landed*, which needs no reading. Purge eligibility is not evaluated here (purge_eligible 1–4). Clock skew across nodes can cause non-deterministic eligibility and inconsistent cadence firing; the deployer configures the source — system clock, GPS-disciplined, NTP-synchronized cluster — and owns monotonicity, or composes a Trusted Timestamping pattern *(forthcoming)* whose anchored time serves as the authoritative source.

---

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind** — Type, Operation, Member, Field or Parameter — with the Type it is a Member of, its Role, and one **Projects** line for every pinned or wire Member, the single canonical lowering token every target casing is derived from by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs). This is a composition, so its concepts are the composed action-wirings, the consolidated read, the derived read over eligible events, the [Audit Record], and its own outcomes and rejections. Backticked rather than carded, because they are reasons or qualifiers under inherited tokens rather than outcomes of their own: `unsealed` and `purged` under `failed-verification(...)`, `partially-purged-coverage` under `unverifiable(...)`, the `(compensation-window)` qualifier, and the reserved references `audit.compensation` and `audit.reconciliation`. The erasure mechanism's two outcome values belong to the deployment-declared mechanism and stay uncarded on the same terms as the constituent tokens; the derived indexes store no truth the constituent stores do not, and the three extraction-pending facts will be carded on Erasure Tombstone's own page when it lands. Constituent operations, inherited outcome tokens, constituent id tokens, the seventeen knobs and the per-act section stay backticked. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant or behavior of the composition above.)*

### Vocabulary

Terms › `actors`: the composition; the deployment; the host; the implementation; the instance; the invocation; a [Record Action] step (also: the step); a cadence firing; the reconciliation scan (also: the scan, a scan run) and its first half, second half and third half (also: a leg, the reconciliation path); the cascade; the holder; a reader; a writer; a caller; the verifier; an auditor; an action of this composition; an id-addressed action; a read path; the rebuild; the read-back; the erasure mechanism; a policy selector; a regulated deployment; an implementation derived from this composition; a Legacy Import pattern; the next run; the next cadence firing; a constituent — Event Log, Actor Identity, Retention Window, Tamper Evidence — and the audit log, the attestation store, the retention store and the seal store; a derived index; an element; a coverage range; a seal; an attestation; an event; a retention record; the destruction record; the outcome record; a finding; a divergence; an entry.

Terms › `composing patterns`: (named, never constituents) Erasure Tombstone, Seal Lifecycle, Reverse Index, Legal Hold, Defensible Retention, Legacy Import, Policy Reconciliation, Mechanism Registry, Storage Tier, Trusted Timestamping, Compromise Disclosure, Erasure Coordination, Failed-Attempt Log, Schema Evolution, Audit Federation.

Terms › `records`: the audit event (Event Log's data field); the attestation; the retention record; the seal (evidence record); the destruction record; the `audit.reconciliation` record; the `audit.compensation` record; the beyond-horizon report; the outcome record; the [Audit Record]; the derived indexes — `event_to_attestation`, `event_to_retention`, `event_to_sequence`, `seal_coverage`, `sealed_through`, `compensated_attestations`, `reported_beyond_horizon`; `erasure_outcomes`.

Terms › `record verbs`: serve, call, read, delete, evaluate, write, dispose, seal, expose, alert, surface, retry, sit, consult, treat, claim, modify, remove, populate, classify, take, re-key, resolve, ask, key, overlap, carry, flag, record, address, land, close, compute, keep, filter, cover, set, place, hold, retain, select, declare, pass, inspect, log, wire, rewrite, leave, report, name, evidence, measure, run, govern, provision, decide, hand, apply, size, widen, exclude, supply, release, skip, block, issue, implement, complete, re-read, start, contain, validate, normalize, compare, consume, store, count, yield, present, canonicalize, return, adopt, guess, fall, depend, defer, return, invoke, advance, re-seal, change, produce, verify, assemble, fabricate, ride, fold, promote, route, proceed, locate, map, re-derive, share, reject, re-offer, re-drive, invent, resume, add, destroy, repair, remain, conclude, grow, suspend, stay, append, match, exist, condition, reconcile, commit, bound, answer, fetch, reserve, stand, obtain, confirm, enumerate, build, fail, walk, step, discard, regenerate, expect, identify, clear, specify, provide, invalidate, adjudicate, rotate, serialize, require, protect, persist, own, monitor, examine, test, delegate, compose, reference, hold, raise, make, discharge.

Terms › `cited`: `append`, `read`, `event_id`, `sequence_number`, `recorded_at`, `data`, `next_sequence_number`, `invalid-query`, `invalid-payload`, `storage-failure`: Event Log. `attest`, `verify`, `attestation_id`, `action_ref`, `actor_ref`, `attested_at`, `proof`, `invalid-credential`, `invalid-request`, `not-known`, `registry-unavailable`: Actor Identity. `place_under_retention`, `purge`, `purge_eligible`, `retention_id`, `policy_ref`, `record_ref`, `retention_until`, `purge_deadline`, `purged_at`, `retention-period-not-elapsed`, `not-retained`, `invalid-policy`, `policy-not-found`: Retention Window. `seal`, `evidence_id`, `record_set_ref`, `sealed_at`, `anchored_at`, `mechanism-failure(reason)`, `mechanism-verification-unavailable`, `seal-record-set-mismatch`, `seal-proof-invalid`: Tamper Evidence.

Terms › `value sets`: `retention_state` = Retained | Purged. `seal_cadence` = per-event | interval-based | on-demand. `unsealed_tail_mode` = strict | lenient. `mechanism class` = unkeyed | keyed | anchored. erasure outcome = destroyed | destruction-failed(reason). `coverage status` = covered | unsealed tail | records-purged | partially purged. verify outcome = verified | failed-verification(reason) | unverifiable(reason). unverifiable reasons = attestation-registry-unavailable | seal-mechanism-verification-unavailable | partially-purged-coverage. composition-introduced failed-verification reasons = unsealed | purged | attestation-not-known | seal-not-known, plus the constituents' reasons prefixed `attestation-` and `seal-`. `subject` = attestation | event. `disposition` = beyond-horizon. `cascade-failure` step = seal | step-1 | step-2 | step-3. `recording-failure` step = step-3 | step-4. classification = derived index | extraction-pending. `section_kind` = lease | death-detected. `lease` = live | expired. `Legal Hold` = composed | absent. retention status on the audit record = the retention record's state | unresolved (compensation window). attribution on the audit record = the surviving fields | not-recoverable. reserved references = audit.compensation | audit.reconciliation. `event standing` = retained | lawfully destroyed.

Terms › `bounds`: `compensation_window`, `record_action_completion_bound`, `purge_completion_bound`, `compensation_closure_latency`, `clock_skew_allowance`, `payload_cap`, `reference_length_cap`, `attestation_id_width`.

Terms › `cadences`: `seal_cadence`, `reconciliation_cadence`.

Terms › `qualifiers`: `(compensation-window)` — carried beside a [Verify Record] outcome on a separate channel.

Terms › `terms`: (each declared where it is used) `audit log`, `attestation store`, `retention store`, `seal store`, `surviving fields`, `open-upper-bound read`, `full enumeration`, `derived index`, `extraction-pending`, `rebuild-on-miss`, `retention_state`, `live`, `purged`, `purged_events`, `covering seal`, `closed entry`, `sealed_through`, `unsealed tail`, `reconciled`, `resolved policy`, `time arm`, `chained mechanism`, `verify-time presentation`, `mechanism class`, `independently trusted substrate`, `standing false negative`, `shredding-class`, `tombstone-by-mutation`, `Event Log's data field`, `finding's creation`, `serialized envelope`, `reference headroom`, `whole closure`, `section_kind`, `act's completion bound`, `lease`, `holder`, `proceed as landed`, `pre-check`, `closure_sum`, `full constructed payload`, `reserved namespace`, `reconciliation path`, `subject-kind discriminator`, `read-back`, `high-water mark`, `mid-record expiry`, `non-storage refusal`, `slice`, `tail`, `audit record`, `coverage status`, `pair`, `partly-purged coverage`, `Legal Hold`, `hold`, `mid-cascade expiry`, `cascade-failure(step-3)`, `completed cascade`, `divergence`, `record_edge`, `purge_edge`, `horizon`, `purge age`, `attestation age`, `event age`, `binding set`, `orphan`, `true miss`, `owed narration`, `quiescence`, `recorded through [Record Action]`, `audit edge`, `composition-built query`, `insert-only map`, `closed-state marker`, `reconciled policy`, `held section`, `truth-bearing write`, `who / what / when`, `seal disposal`, `re-sealing`, `store outage`, `compliance alert`, `verification surface outage`, `event standing`, `residual finding`, `seal stamps`, `extraction-pending fact`, `invocation`, `later write`, `malformed reference`, `step-3 storage failure`, `step-4 storage failure`, `standing finding`, `open entry`, `external evidence`; and `now`, the seam-injected reading (Clock source 1–3).

#### Record Action

The composition's core action: validates the caller's primitives, attests the actor, appends the event, places the retention, links the three in the derived indexes, and under per-event cadence fires a seal over the slice the firing cuts. Returns the new `event_id`; `invalid-credential` or `invalid-request` before anything is recorded; [Recording Failure] carrying the step where a store refused after the attestation, or where a lease host's terminus fell between steps 2 and 4 — an orphan attestation at `step-3`, an unretained event at `step-4`, found by different halves of the scan. A seal failure at step 6 does not reject the call.

Kind: Operation

#### Seal Now

The action that seals the current unsealed tail — under interval or on-demand cadence, from [Record Action] step 6 under per-event cadence, and from [Purge Event] step 0 — over the slice, where `tail` is what the open-upper-bound read returns; records the coverage and advances `sealed_through`. Cuts new coverage only. Returns the `evidence_id`, [Nothing To Seal], [Mechanism Failure] with the mechanism's reason, `invalid-request`, or [Recording Failure]; under all of them the events stay in the tail and the next firing retries.

Kind: Operation

#### Read Record

The consolidated read: resolves the `event_id` through `event_to_sequence`, joins the event, its attestation reference, its retention record and its coverage status into one [Audit Record], or returns `not-known`. For a purged event reads the *who / what / when* from the attestation record through the pair. Returning the covering range is what tells a [Verify Record] caller what to present. A pure projection; it presents, [Verify Record] proves.

Kind: Operation

#### Verify Record

The four-way verification query: retention state first, then log presence, then the attestation, then the covering seal. Returns `verified`, a prefixed `failed-verification(reason)` (including `purged`), [Unverifiable], or `not-known`; any of the first three may carry `(compensation-window)` on a separate channel. The record set re-presented is always the payloads of the covering seal's range.

Kind: Operation

#### Purge Eligible

The derived read returning the `event_id`s eligible for the cascade: delegates to Retention Window's read-time `purge_eligible` projection and maps each retention to its event; evaluates no clock, has no rejection arm. Distinct from `RetentionWindow.purge_eligible`, the constituent projection over `retention_id`s.

Kind: Operation

#### Purge Event

The action that coordinates the cascade for a retention-elapsed event: seals the event if it is in the tail, requires the retention to be resolved, purges the retention record, writes the destruction record, and delegates destruction of Event Log's `data` field and the attestation's `proof` to the shredding-class `erasure_mechanism`, branching on the reported outcome. Destroys nothing itself, disposes of no seal, re-seals nothing. Returns `ok`, `not-known`, [Not Eligible], [Retention Unresolved], [Cascade Failure] carrying the step, or — where a Legal Hold is composed — [Under Legal Hold].

Kind: Operation

#### Audit Record

The composition's emergent output, produced by [Read Record]: the single consolidated structure the four atoms together present for one event — the event bound to its attestation, its retention and its seal coverage. No constituent presents it alone.

Kind: Type

#### Recording Failure

The composition's rejection for *a store refused the write*, carrying the step: from [Record Action] on any constituent `storage-failure` — nothing committed at step 2, a partial state after the attestation at step 3 or 4 — and as a lease host's terminus between steps 2 and 4; from [Seal Now] when the seal store would not persist a computed proof. The surface that failed is a store, not a mechanism.

Kind:      Member
Member of: the record-action and seal rejections
Role:      Rejection
Projects:  recording-failure

#### Nothing To Seal

The composition's rejection from [Seal Now] when the unsealed tail is empty.

Kind:      Member
Member of: the seal rejection
Role:      Rejection
Projects:  nothing-to-seal

#### Mechanism Failure

The composition's rejection from [Seal Now] when the mechanism could not compute a proof, carrying the constituent's `(reason)` unchanged: a transient outage or a standing preconditions failure, told apart by the reason. Not a malformed request (`invalid-request`) and not a store refusal ([Recording Failure]). No coverage entry is written and `sealed_through` does not move.

Kind:      Member
Member of: the seal rejection
Role:      Rejection
Projects:  mechanism-failure

#### Cascade Failure

The composition's rejection from [Purge Event] when a store or the seal mechanism refuses mid-cascade, carrying the step: `seal` and `step-1` leave nothing changed and the event on [Purge Eligible]'s list; `step-2` and `step-3` leave the retention *Purged* over an incomplete cascade, invisible to [Purge Eligible] and re-driven by the reconciliation scan. On a lease host, the cascade's terminus after step 1.

Kind:      Member
Member of: the purge rejection
Role:      Rejection
Projects:  cascade-failure

#### Not Eligible

The composition's rejection from [Purge Event] when the retention has not elapsed and Retention Window's no-early-purge gate refuses the cascade.

Kind:      Member
Member of: the purge rejection
Role:      Rejection
Projects:  not-eligible

#### Retention Unresolved

The composition's rejection from [Purge Event] step 0½ when the `event_id` resolves to a log entry but to no retention record — the compensation-window state of Invariant 2's liveness arm. Nothing to purge; the remedy is the reconciliation path. Distinct from `not-known` and from [Not Eligible].

Kind:      Member
Member of: the purge rejection
Role:      Rejection
Projects:  retention-unresolved

#### Under Legal Hold

The conditional rejection from [Purge Event], present exactly when the deployment composes a [Legal Hold](../atoms/legal-hold.md) pattern: a preservation order intercepts the cascade before its first step, so no step runs.

Kind:      Member
Member of: the purge rejection
Role:      Rejection
Projects:  under-legal-hold

#### Unverifiable

The composition's [Verify Record] outcome for *verification could not be performed*: two availability reasons, retried when the surface returns, and `partially-purged-coverage`, standing for the rest of the event's retained lifetime. Nothing is known to be wrong with the record.

Kind:      Member
Member of: the verify-record outcome
Role:      Outcome
Projects:  unverifiable

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

The composition is the structural form of what every major audit regime requires: SOX §404 (internal control over financial reporting) and §802 (records retention); HIPAA §164.312(b) (audit controls) and §164.530(j) (documentation retention); PCI DSS Requirement 10 — 10.2, 10.3, 10.5, 10.7; 21 CFR Part 11 (ALCOA and ALCOA+); SEC Rule 17a-4 and FINRA Rule 4511 (composing with Storage Tier); ISO/IEC 27001 §A.12.4.1–4 (the clock-synchronization control via Trusted Timestamping); GDPR Articles 30 and 32; eIDAS (EU 910/2014) qualified preservation, with `anchored_at` from a qualified TSA as the time anchor; DoD 5015.02-STD; NIST SP 800-92; Basel III BCBS 239. The four atoms carry their own standards inheritance. It inherits from Daniel Jackson, *The Essence of Software* — a composition is the wiring of freestanding concepts, not a new primitive; from the audit-grade systems literature — COSO, COBIT and SOC 2 name attribution, integrity, retention and event recording as the four pillars the frameworks assume but never specify; and from Schneier and Kelsey 1999, *Secure Audit Logs to Support Computer Forensics*, the original formal framing of cryptographically protected audit logs.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the reconciliation scan is now a second process over each act with a completion bound at which the invocation yields, a per-act section, and age-bounded legs, none of which the model carries; was verified — audit-trail.tla + 1 twin, 2026-06-03
last gate: 2026-08-25 — Final Critique 11, fresh reader — clean

open:
- 2026-08-30-a · refining · [Record Action] signature, `invalid-request` · one bare token lands at steps 1–2 with nothing committed and at steps 3–4 after the attestation (and the event) committed, so a caller told `invalid-request` retries a committed act → carry the position (`invalid-request(step)`, or a `deployment-fault(step)` code) in the signature block; contract-shaped — ripples to every composer that transcribes `record_action`'s `invalid-request` arm as a clean pre-state rejection, own round
- 2026-08-30-b · refining · [Record Action] step 7, `recording-failure(step-4)` · the appended event's `event_id` is never returned, so a caller's retry appends a second attested event for one act and nothing marks the first a dead duplicate → carry the committed `event_id` in the `(step-4)` payload; contract-shaped — ripples to every composer that transcribes the `recording-failure(step)` payload, own round
- 2026-08-30-c · refining · Composes, Event Log · every rebuild, the scan's binding set, and [Read Record] step 3's "unreachable by construction" fourth cell rest on the audit log surviving a restart, which Event Log disclaims ("persistence across process restarts is handled at the deployment layer") and no Composes requirement or Configuration entry declares → declare the audit log instance's durability (including `next_sequence_number`) as an instance capability requirement routed to an externally-clearable check; contract-shaped — ripples to every composer whose Rests-on lines transcribe the substrate's durability, own round
- 2026-08-30-d · refining · Invariant 8 liveness; the scan's first half · a delegation whose outcome record was never written is re-driven "until a `destroyed` outcome lands" against content the mechanism may only ever answer `destruction-failed` for → an *abandoned* record under the operator identity after a declared bound, the arm degrading to *surfaced*; contract-shaped — ripples to every composer that transcribes Invariant 8's unconditional lawfully-destroyed-versus-missing distinction, own round
- 2026-08-30-e · refining · formal · the model has no reconciliation leg as a second process over one act, no completion bound at which the invocation yields, no per-act section, and no age-bounded scan → extend it
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/audit-trail.md`.

- **2026-09-11 — Rewritten in GRACE lang v0.31; nothing but language changed.** *Chose:* labelled rules in fenced blocks, rationale under `WHY:`, terms declared where they are used, the Ledger and the invariant numbers unchanged; the instance-start conditions given one owner (§*Instance start*), the class boundary and the scan's halves cited by label from every site that used to restate them. *Over:* the prose spec. *Because:* the migration plan — the corpus is being rewritten in the language, and a spec whose obligations have one owner each is what the reverse diff reads.
- **2026-08-30 — The reconciliation is one writer per act, bounded at both edges, and the scan writes its intent before its repair.** *Chose:* a per-act critical section keyed by the act's id (`attestation_id` for a record action, `event_id` for a cascade), declared as an instance capability requirement with lease semantics, held by the invocation from its first write and taken by every scan half before its pre-check; two completion bounds (`record_action_completion_bound`, `purge_completion_bound`) below which no half examines anything and at which the invocation yields; a horizon at which the second half reports rather than re-compensates, once, behind a `reported_beyond_horizon` marker; `compensation_closure_latency` and `clock_skew_allowance` declared, the window measured from the finding's creation, the three-term inequality checked at start; the scan reading its own `now` once per run; `audit.reconciliation` written one record per finding before the act it announces, under a declared `reconciliation_operator_credential`; the scan as the sole writer of an orphan's compensation. *Over:* a third half whose placement raced the invocation's own step 4 under no shared key; halves with no lower edge, compensating attestations and events whose [Record Action] was still between two steps; a window measured from detection and an inequality with one term; a findings record of unbounded size and unstated position. *Because:* two writers over one act land two records the seal protects forever, a leg with no lower edge reads work in flight as an orphan and corrects it, and a liveness promise is arithmetic or it is nothing (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone*, *An outcome is sized before the intent*, and *Capability provenance*; with §*A reconciliation is bounded at both ends* and §*Recovery commits under a declared service identity*). The four contract-shaped sites — `invalid-request`'s position, `recording-failure(step-4)`'s `event_id`, the Event Log durability obligation, Invariant 8's abandoned terminus — are routed as open lines rather than fixed, because every composer transcribes them. *Round 2, same day:* the inequality gained its skew term and its closure latency (the whole closure, intent through compensation, or a cascade round-trip); the per-act section gained its non-lease branch — a leg skips a held act and never blocks, a host that cannot detect death must lease, and the non-lease terminus is *proceed as landed* behind step 4's pre-check; the lease terminus is confined to steps 2–4 inclusive, an invocation past step 4 completing its index writes; the beyond-horizon report and the recording-half detector both gained the horizon; and every *all succeed or none* sentence over un-withdrawable writes was restated as ordered writes plus compensation. The five *until a `destroyed` outcome lands* loops are bounded by open line 2026-08-30-d rather than given a terminus here.
- **2026-08-24 — Seal supersession is extracted to a forthcoming Seal Lifecycle composing pattern, not absorbed.** *Chose:* remove the Reseal action, `superseded_by`, `reseal_on_purge` and every current-seal qualification from the canonical composition; name Seal Lifecycle as owner of re-sealing partly purged seals, mechanism rotation, and supersession bookkeeping. *Over:* keeping the mechanism added at Final Critique 6. *Because:* which seal is current over a range two seals cover is new truth no constituent store carries and no rebuild replays — it clears the extraction gates, and it had spread through three invariants, three checks and four cards.

NOTE: End of Audit Trail.

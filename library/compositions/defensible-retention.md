---
title: Defensible Retention
id: 1
audience: common
nav_order: 7
---

# Defensible Retention

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## Summary

Defensible Retention makes record destruction provably lawful. It combines three patterns: Legal Hold, which records who ordered a record preserved and why; Retention Window, which records the minimum keep-period and blocks early deletion; and Audit Trail, the tamper-evident record that stamps and seals every decision.

The guarantee none of the three has alone is a gate that sits between checking for holds and actually deleting. Under strict mode, no record carrying an active hold is destroyed through this composition, however long ago its keep-period ended. The gate stands over a record this composition placed under retention (Invariant 2.2): a hold placed over a record under no retention is recorded (Non-goal 5) and fires no gate here. A deployment may instead configure advisory mode, which records an externally-authorized override and proceeds; strict is the required posture under Rule 37(e) of the Federal Rules of Civil Procedure, Securities and Exchange Commission Rule 17a-4 and the Sarbanes-Oxley Act.

The same composition owns the end of the audit instance's own events, which moved here from Audit Trail so that lawful destruction lives in one pattern: the cascade that seals an event, has Audit Trail end its retention and write the destruction record, and delegates the shred of its content to the deployment's erasure mechanism, behind the same kind of hold gate.

The business gate is audited in both directions — an event when it allows a destruction, naming that no holds applied, and an event when it blocks one, naming which holds applied — so both halves of the gate's behaviour are provable.

Every destroyed record leaves three things behind: a destruction event naming what the hold records held at gate time, a retention record standing purged, and a tamper-evident seal once the substrate's seal cadence (the schedule on which it seals events) covers the event. Together they prove the destruction was lawful, attributed and unaltered — for as long as the audit records themselves are kept, which is the deployment's own ordering obligation rather than this composition's guarantee.

Its most common uses are financial records governance under SOX (Sarbanes-Oxley Act) section 802, patient records under HIPAA (US Health Insurance Portability and Accountability Act) section 164.530(j), electronically stored information subject to FRCP (Federal Rules of Civil Procedure) Rule 37(e) litigation holds, and broker-dealer communications under SEC (US Securities and Exchange Commission) Rule 17a-4. Any system that must prove it did not destroy records while a legal or regulatory hold was active — and that it did eventually destroy them once the hold was released and the retention window had closed — is a candidate for this composition.

---

## Intent

A record's life under a regulated system follows two governance tracks that must coexist without one silently overriding the other. The first is the *retention clock*: a record must be kept for a minimum period mandated by statute, regulation, or contract — seven years under SOX, six under HIPAA, three for some broker-dealer communications under SEC Rule 17a-4. The second is the *preservation directive*: when litigation is anticipated, when a regulator opens an investigation, when an audit freeze is ordered, the normal retention clock stops being the governing rule and the obligation shifts to *keep this record until the legal matter resolves, regardless of what the schedule says.*

Neither Retention Window nor Legal Hold alone enforces that coexistence. Retention Window enforces the clock — it prevents purge before retention deadline and records the eligibility transition. Legal Hold records the preservation obligation — who placed the hold, why, and when. Neither enforces the other's constraint: a retention whose window has elapsed is eligible for `RetentionWindow.purge` with no knowledge of any hold, and a record under an active hold is recorded as preserved while the Legal Hold atom intercepts nothing. The gate that enforces *no purge while any active hold covers a record* belongs to the composition, and this composition is that gate.

Audit Trail provides the third leg: every hold placement, every release, every retention placement and every purge decision is attribution-stamped, retention-bounded and tamper-evident. A destruction is defensible because the evidence trail — who held the record, who released the hold, who purged it, under what policy, at what time — is itself a regulated, integrity-protected record, so the destruction is provable.

This is a composition, not a new primitive. Legal Hold, Retention Window and Audit Trail are unchanged; the composition is the wiring that makes them coherent as one retention-governance surface. It wires the hold gate over the *business* record set, and owns the destruction of those records, which it makes through a record destruction pattern. It also owns the end of the audit instance's own events, which moved here from [Audit Trail](./audit-trail.md) on 2026-11-02 under the maintainer's ruling that lawful destruction lives in one pattern: the cascade that seals an event, has Audit Trail end its retention and write its destruction record, and delegates the shred of its content to the deployment's erasure mechanism; the Legal Hold gate over that cascade, so that the events proving a hold are not destroyed while the hold is live; and the first half of the reconciliation scan that completes a cascade that stopped partway (`Capability requirement 69` through `Capability requirement 72`). The destruction record itself stays Audit Trail's, written by its record_destruction, which this composition reaches through its declared surface alone (`Composes 21`).

---

## Composes

- **[Legal Hold](../atoms/legal-hold.md)** — the preservation directive over a record.
- **[Retention Window](../atoms/retention-window.md)** — the policy-bounded lifetime of a business record.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate every decision is recorded through.

```
Composes 1: EXACTLY ONE Legal Hold instance MUST serve the composition.
Composes 2: EXACTLY ONE Retention Window instance MUST serve the composition.
Composes 3: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 4: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST read Audit Trail as a substrate PER the section titled Substrate composition invocation in `execution-contract.md`.
Composes 7: The composition MUST NOT hold an instance Audit Trail reaches.
Composes 8: The business retention instance MUST NOT govern an audit event.
Composes 9: The composition MUST reach a constituent through the constituent's declared surface.
Composes 10: The composition MUST NOT read a constituent's records beside the constituent's declared read.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range through a declared direct invocation of Event Log's range read over the Event Log instance Audit Trail carries (the section titled Substrate composition invocation in `execution-contract.md`).
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST attest an invocation's audit record under the calling actor's credential.
Composes 19: [Purge Eligible Events] MUST read eligibility through Retention Window's declared read over the audit retention instance.
Composes 20: The composition MUST NOT evaluate an eligibility clock over the audit retention instance.
Composes 21: The composition MUST end an audit event's retention through Audit Trail's record_destruction alone.
Composes 22: The composition MUST NOT write a destruction record beside Audit Trail's record_destruction.
Composes 23: The first half MUST read an audit event's destruction through Audit Trail's read_record alone.
```

Term composition: this pattern's wiring of [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) and the [Audit Trail](./audit-trail.md) substrate — the five actions, the hold gate and the two indexes.

Term constituents: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md).

Term business retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over business records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

Term audit retention instance: the one [Retention Window](../atoms/retention-window.md) instance [Audit Trail](./audit-trail.md) wires over the audit log's events (Audit Trail Composes 3) — read by the audit cascade through the constituent's declared read and never held by this composition (Composes 7).

---

## Composition logic

### Composition state

```
Composition state 1: The composition MUST store a record-to-retentions index.
Composition state 2: The composition MUST store a retention-to-record index.
Composition state 3: A committed placement MUST add the placement's retention to the record-to-retentions index.
Composition state 4: A committed placement MUST add the placement's retention to the retention-to-record index.
Composition state 5: A committed purge MUST remove a purged retention from the record-to-retentions index.
Composition state 6: A committed purge MUST remove a purged retention from the retention-to-record index.
Composition state 8: The composition MUST remove a record reference carrying no retention from the record-to-retentions index.
Composition state 9: The record-to-retentions index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 10: The retention-to-record index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 11: The composition MUST NOT store a truth beside a constituent's records.
Composition state 12: The rebuild MUST read a surviving placement event for an index entry.
Composition state 13: The rebuild MUST take EVERY retention Retention Window's declared read answers as an index entry.
Composition state 14: The rebuild MUST NOT read a purged placement event's payload.
Composition state 15: The rebuild MUST NOT read a trail miss as an absent retention.
Composition state 16: The database-sourced rebuild MUST admit a retention the composition did not place.
Composition state 17: A refusal resting on the database-sourced rebuild MUST NOT claim the retention was placed through this composition (Composition state 16).
Composition state 18: The composition MUST NOT rest a purge admission on an index.
Composition state 19: The composition MUST read the sibling set from Retention Window's records.
Composition state 20: An index MUST stand outside an action's atomicity set.
Composition state 21: A reader of an index MUST read a missing index entry as a rebuild trigger (Execution Contract Derived index 1).
Composition state 22: The composition MUST NOT claim a cross-constituent consistency for an index.
Composition state 23: The rebuild MUST drop an index entry whose retention's retention state EQUALS purged.
Composition state 24: The rebuild MUST report a dropped entry over a surviving destruction that carries no record_purged event as a bypass finding on the alerting surface.
Composition state 25: The composition MUST NOT read a stale index entry as a bypass alone.
Composition state 35: The composition MUST NOT read the trail a bypass finding rests on BEFORE reading the retention state of the dropped entry's retention.
Composition state 26: EVERY rebuild MUST leave the record-to-retentions index AND the retention-to-record index agreeing, an action's own commit standing outside the agreement (Composition state 20).
Composition state 27: EVERY retention MUST cover EXACTLY ONE record.
Composition state 28: A record MAY carry a retention beside another retention.
Composition state 29: EVERY hold MUST name EXACTLY ONE record.
Composition state 30: A record MAY carry a hold beside another hold.
Composition state 31: A record MAY carry no hold.
Composition state 32: A hold MUST NOT rest on a retention.
Composition state 36: The indexes MUST serve a reader's query alone, no action reading an index.
```

Term record-to-retentions index: record_to_retentions — the composition's index from a record reference to the retentions whose retention state EQUALS retained over the record — the auditor's first query surface and a read-path convenience, never the gate's input.

Term retention-to-record index: retention_to_record — the composition's index from a retention id to the record the retention covers, with the retention's retention deadline and purge deadline read back from Retention Window's declared read.

Term payload horizon: the age past which the audit instance has destroyed an event's payload — the retention period of the one policy audit_trail_retention_policy answers for every event of the audit instance (Capability requirement 57). Audit Trail's Term audit horizon, the span through which events are live, is another, and the name here is distinct (GRACE-lang Closed vocabulary 17); every rule here reads this one.

Term surviving placement event: a retention_placed event whose payload the audit instance has not destroyed.

Term purged placement event: a retention_placed event whose payload the audit instance has destroyed.

Term rebuild: the composition's named regeneration of an index — select this composition's placement events over an open-ended sequence range, keeping each event whose action reference names retention_placed, the outcome a committed placement records (Term outcome), the action reference being what Audit Trail's read answers for every event, a destroyed event included (Term destroyed event); take a surviving event's record reference and retention id, and take and drop retentions as Composition state 13 and Composition state 23 write.

Term sibling set: the retentions whose retention state EQUALS retained over one record beside the named retention, read from Retention Window's records.

Term within the payload horizon: said of a retention placement or a purge by the instant Retention Window's records carry for it, and of a hold placement or a hold release by its entry instant, never by the placement or release instant a caller may assert (Clock semantics 18) — the act's age, the reader's now less that instant, plus the horizon margin DOES NOT EXCEED the payload horizon, so the act's own audit records cannot have aged out. A hold whose entry instant the trail cannot state, the intent it is read from having aged out, does not stand within it. An act that does not stand within the payload horizon reads unknown wherever its record is missing (Check 6.4).

Term horizon margin: `(((2 * seam_offset_allowance) + time_resolution) + section_term)` — how far below the payload horizon an act's age must stand for the act's own audit records not to have aged out (Term within the payload horizon): two allowances, because the substrate places a record's retention on one clock after the database stamped the act on another, and judges the record's purge on the first against a now the reader takes on a third; one time resolution, the smallest span the database tells apart (Retention Window Capability requirement 5); and one section term, the longest an intent stands ahead of the act it announces, the two landing under one grant of the record section (Concurrency 8, Concurrency 14), so the intent, the act's oldest audit record, has not aged out while the act stands within the payload horizon.

Term surviving destruction: a destroyed record whose earliest purge among the retentions over the record stands within the payload horizon — a destruction whose own record purged outcome and purge intent cannot have aged out. The edge is the record's first purge and never a sibling's later one.

The audit cascade keeps one composition-state element of its own, moved here from Audit Trail with the cascade: erasure outcomes, extraction-pending against [Erasure Tombstone](../atoms/erasure-tombstone.md) (Execution Contract Composition state).

- **erasure outcomes**
  Term erasure outcomes: for each event over which [Purge Event] step 3 has issued its delegation, the outcome the configured erasure mechanism reported: destroyed or `destruction-failed(reason)`.
  ```
  erasure outcomes 1: The cascade MUST record the mechanism's reported outcome in erasure outcomes for EVERY delegation [Purge Event] step 3 issues.
  erasure outcomes 2: erasure outcomes MUST address an outcome per event id.
  erasure outcomes 3: The composition MUST classify erasure outcomes as extraction-pending against Erasure Tombstone.
  erasure outcomes 4: The outcome record MUST land under the event id alone AND MUST NOT rewrite the covering seal's purged events.
  erasure outcomes 6: A destruction-failed record MUST NOT close an entry.
  ```
  The instant of a destruction is no part of erasure outcomes: Retention Window Capability requirement 7 asks the deployment to retain it, read from the clock that supplies now, which the composition reads only for the seal cadence timer and the scan (Audit Trail Clock source 1), and Retention Window External check 5 reads it from the deployment's own destruction records.

  Term closed entry: a Purged retention whose cascade is a completed cascade.

  Term open entry: a Purged retention whose cascade is not a completed cascade; open for re-driving.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one invocation id at the seam PER state-changing invocation.
Capability requirement 4: The transition MUST NOT mint an invocation id.
Capability requirement 6: The composition MUST NOT accept an invocation id as an input.
Capability requirement 7: The composition MUST NOT mint a retention id.
Capability requirement 8: The composition MUST NOT mint a hold id.
Capability requirement 9: The composition MUST NOT mint an event id.
Capability requirement 10: A deployment MUST configure the audit instance with an audit retention policy.
Capability requirement 11: A deployment MUST set the audit retention policy so that the evidence floor DOES NOT EXCEED the payload horizon.
Capability requirement 12: A deployment MUST declare the longest hold the deployment admits.
Capability requirement 13: IF a deployment admits an unbounded hold THEN the deployment MUST wire a horizon alert.
Capability requirement 14: A deployment MAY declare a field cap PER payload field (Execution Contract Input 2).
Capability requirement 15: A deployment MUST NOT declare a field cap that EXCEEDS the audit instance's payload cap.
Capability requirement 16: A deployment MAY declare the hold ids cap (Execution Contract Input 2).
Capability requirement 22: A deployment MUST disclose the audit write latency.
Capability requirement 24: A deployment MUST set the hold check mode.
Capability requirement 25: The hold check mode MUST stand as one instance-wide value for the life of the instance.
Capability requirement 26: An action MUST NOT read a per-record hold check mode.
Capability requirement 27: A deployment under Rule 37(e) of the Federal Rules of Civil Procedure MUST NOT set advisory.
Capability requirement 28: A deployment under Securities and Exchange Commission Rule 17a-4 MUST NOT set advisory.
Capability requirement 29: A deployment under the Sarbanes-Oxley Act MUST NOT set advisory.
Capability requirement 30: A deployment needing two hold check modes MUST run two instances over disjoint records.
Capability requirement 31: A deployment MUST resolve a policy reference at Retention Window's seam.
Capability requirement 32: The composition MUST NOT reconcile two policies.
Capability requirement 33: The composition MUST NOT store an override authorization.
Capability requirement 36: The deployment MUST declare the seam offset allowance.
Capability requirement 37: A deployment MUST supply a Lease host PER Lease Capability requirement 1, 2, 4, 5, 7 and 11.
Capability requirement 38: A deployment MUST set the section call pause bound.
Capability requirement 39: A deployment MUST set the section term.
Capability requirement 40: A deployment MUST set the section work bound.
Capability requirement 41: A deployment MUST set a section work bound that includes twice the section call pause bound (Lease Sizing 4).
Capability requirement 42: A deployment MAY start an instance ONLY IF the section term EXCEEDS the section work bound (Lease Sizing 4a).
Capability requirement 43: A deployment MAY start an instance ONLY IF the section work bound EXCEEDS the record start floor (Lease Sizing 9).
Capability requirement 45: A deployment MUST place a retention of the business retention instance through [Place Record Under Retention] alone (Retention Window Simultaneous retention 5).
Capability requirement 46: A deployment MUST purge a retention of the business retention instance through [Purge Record] alone (Retention Window Simultaneous retention 5).
Capability requirement 47: A deployment MUST place a hold of the hold records through [Place Hold] alone.
Capability requirement 48: A deployment MUST declare the hold database name.
Capability requirement 50: A deployment MUST supply the alerting surface.
Capability requirement 53: A deployment MUST release a hold of the hold records through [Release Hold] alone.
Capability requirement 54: A deployment MUST supply hold records, a business retention instance, an audit instance AND a record destruction pattern bound by Lease Capability requirement 8 and 10 for EVERY call the composition issues under the record section.
Capability requirement 55: A deployment MUST supply the business retention instance PER Retention Window Capability requirement 1, 5 and 6a through 16, the composition owning the destruction (Retention Window Record divergence 4).
Capability requirement 57: A deployment MUST set an audit retention policy that answers one policy for EVERY event of the audit instance.
Capability requirement 59: A deployment MUST NOT serve two instances of the composition by one constituent instance.
Capability requirement 60: The audit retention policy MUST stand as one value for the life of the instance.
Capability requirement 62: A deployment MUST NOT declare a field cap of a reference that EXCEEDS the audit instance's reference length cap.
Capability requirement 63: The host MUST NOT supply one invocation id to two invocations.
Capability requirement 64: A deployment MUST NOT admit another writer of the composition's action references on the audit instance.
Capability requirement 65: The deployment MUST supply the constituent instances' database PER Execution Contract Database 1 through 4 and Execution Contract Read 6.
Capability requirement 66: A deployment MUST supply the record destruction pattern PER Retention Window Record divergence 4a through 6.
Capability requirement 67: The record destruction pattern MUST NOT retry a destruction BEFORE taking the record section over the record reference (Retention Window Simultaneous retention 6).
Capability requirement 68: IF the hold check mode EQUALS strict THEN the record destruction pattern MUST retry a destruction ONLY IF a read of Legal Hold made under the record section answers no active hold over the record (Wiring decision 1).
Capability requirement 69: WHEN Legal Hold EQUALS composed:
    Capability requirement 69a: The deployment MUST serialize a hold placement over an event id with the per-act critical section keyed by that event id.
    Capability requirement 69b: The deployment MUST read hold from the Legal Hold database instance wired to this instance (Legal Hold Instance 5 through 7).
    Capability requirement 69c: A hold placement MUST hold the critical section as a lease of purge completion bound.
    Capability requirement 69d: A hold placement MUST NOT issue a write after the lease has expired.
    Capability requirement 69e: A hold placement that finds the critical section held MUST wait for the lease's instant or the holder's release.
    Capability requirement 69g: The deployment MUST place a hold over an event id of this instance through a hold placement alone.
    Capability requirement 69h: A deployment whose regime orders the preservation of audit records MUST set Legal Hold to composed.
    Capability requirement 69i: The deployment's placement gate MUST bound the hold placements over an open entry to one displacement of the entry's first-half leg WITHIN Audit Trail's compensation window of the finding's creation, a displacement being a hold placement holding the entry's critical section when a first-half leg comes for the entry (Audit Trail Per-act critical section 5).
Capability requirement 70: IF erasure mechanism EQUALS blank THEN the instance MUST NOT start.
Capability requirement 71: IF Legal Hold EQUALS composed AND no Legal Hold database instance is wired to this instance THEN the instance MUST NOT start.
Capability requirement 72: IF Legal Hold EQUALS composed AND no hold placement EXISTS THEN the instance MUST NOT start.
Capability requirement 73: A deployment MUST NOT declare a field cap of a record reference that EXCEEDS Legal Hold's string cap.
Capability requirement 74: IF the largest gate record EXCEEDS the audit instance's payload cap THEN the instance MUST NOT start.
Capability requirement 75: The audit instance's payload cap MUST stand as one value for the life of this instance.
Capability requirement 76: A deployment MUST declare the longest retention duration in use on the business retention instance.
Capability requirement 77: A deployment MUST declare the longest purge delay in use on the business retention instance.
Capability requirement 78: IF a deployment admits no unbounded hold THEN a hold's life MUST NOT EXCEED the longest hold the deployment declared.
Capability requirement 79: A deployment MUST hold EVERY read of a constituent's records that an act makes for the act's outcome inside the section call pause bound.
Capability requirement 80: The composition MUST NOT rest a decision on a refused purge of Retention Window having been left unapplied (Lease Capability requirement 9 declined: Atomic writes 8, Atomic writes 9).
Capability requirement 81: A deployment MUST declare the retentions cap.
Capability requirement 82: The retentions cap MUST stand as one value for the life of this instance.
Capability requirement 83: IF the largest purge record EXCEEDS the audit instance's payload cap THEN the instance MUST NOT start.
Capability requirement 84: IF a deployment admits an unbounded hold THEN the deployment MUST declare the horizon alert lead.
```

NOTE: watch the id the host supplies to two calls (Capability requirement 63).

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one invocation id here.
Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term invocation id: the id the seam allocates for one state-changing invocation; an intent and the outcome matched to it carry the same one (Capability requirement 2, Reconciliation 6).

Term intent instant: the instant an intent records (Action wiring 8).

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term evidence floor: `(((longest_retention_duration + longest_purge_delay) + longest_hold_duration) + horizon_margin)` — the longest retention policy in use on the business retention instance, the longest max purge delay and the longest hold the deployment admits (Capability requirement 76, Capability requirement 77, Capability requirement 12), summed with the horizon margin — what audit_trail_retention_policy must outlast. The margin is in the sum because an act stands within the payload horizon only by it (Term within the payload horizon): a horizon equal to the three durations alone reads the placement of a record they cover as not within the payload horizon by the time the record is destroyed. The sum is a floor under the policy and no bound on a record's life: a later sibling or a second hold carries a record past it, and what the trail has lost by then the rebuild reads from Retention Window's records (Composition state 13). Where the deployment admits an unbounded hold the hold term is zero: no horizon outlasts such a hold, and the horizon alert and the substrate's own hold placement carry what the sum cannot (Capability requirement 13, Non-goal 22, Non-goal 23).

Term constituent instance: the Legal Hold instance holding the hold records, the business retention instance, or the audit instance — the three Composes 1 through 3 give one instance of the composition. Two instances of the composition sharing one would each take a record section the other does not see, and each sweep would read the other's intents as its own.

Term hold check mode: hold_check_mode — strict | advisory.

Term record section: the [Lease](../atoms/lease.md) this composition takes on a record reference — the key is the record reference under this instance's own namespace on the host (Concurrency 30) and the holder value is minted fresh for each take — under which one act over the record runs, from the act's first read at the gate to the act's outcome.

Term section call pause bound: this composition's value of [Lease](../atoms/lease.md)'s call pause bound — the longest time from the decision to issue one call to the moment the call has taken effect or failed. It bounds a lease call, a committing call and the read an act makes for the act's outcome (Capability requirement 79), and never a whole record_action (Lease Capability requirement 7).

Term record destruction pattern: the pattern through which the composition destroys a business record — Record Destruction *(forthcoming)*. It destroys only a record a purged retention names, keeps each destruction's confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the pattern that owns the destruction (Capability requirement 66). Under strict mode a standing record an active hold covers is a withheld record: the pattern retries a destruction only under the record section, and only where a read of Legal Hold made there answers no active hold over the record (Capability requirement 67, Capability requirement 68), so a hold placed after the purge keeps the record until the hold is released.

Term section term: the duration every take of the record section asks for (Lease Composition note 5d).

Term section work bound: the deployment's declared longest time from a take's answer to the landing of an act's outcome — the gate read, the sibling set's read, the intent, the act's first committing call, the read of the purge instant (Action wiring 106) and the outcome counted, each record_action at the audit write latency. A sibling's purge the grant no longer admits stands pending, and a record whose call to the record destruction pattern the grant no longer admits stands for that pattern's retry, so no act's work outruns the bound.

Term audit write latency: the deployment's disclosed longest time from issuing a record_action to the landing of the call's last write, an abandoned call's included. The unit's bound of a record_action under the record section (Lease Composition note 8a); a record_action that has not answered within it answers no answer (Audit arm 18). It is counted from the start of the unit, which starts within one section call pause bound of asking for the unit's reading (Lease Sizing 5c), as Lease's unit bound is, so the record start floor adds that pause and the one left before the instant.

Term record start floor: `(audit_write_latency + (2 * section_call_pause_bound))` — the remaining term a record_action needs to land inside the grant. The floor admits a call whose [Remaining](../atoms/lease.md) reading answers a remaining term exceeding the floor (Lease Sizing 5).

Term sibling floor: `(record_start_floor + (3 * section_call_pause_bound))` — the remaining term below which a purge starts no further sibling's purge, so that the purge's outcome still has its floor: two section call pause bounds for the sibling's own reading and call (Lease Sizing 3, Lease Sizing 3a) and one for the read of the named retention's purge instant the outcome carries (Action wiring 106, Capability requirement 79).

Term lease reading: live | expired — what a [Remaining](../atoms/lease.md) reading of the record section says of the grant, as [Lease](../atoms/lease.md) declares the two (Lease Sizing 2, Lease Sizing 2a, Lease Sizing 7).

Term hold database name: the deployment's declared name of the one Legal Hold database instance serving the composition (Composes 1), matched against the database name Legal Hold's read answers (Legal Hold Instance 5).

Term alerting surface: the deployment's surface on which the composition alerts.

Term field cap: the deployment's declared maximum size of one audit payload field. *Default:* 1 kilobyte, or the audit instance's payload cap where that is smaller, or for a reference the audit instance's reference length cap where that is smaller, or for a record reference Legal Hold's string cap where that is smaller (Capability requirement 15, Capability requirement 62, Capability requirement 73).

Term hold ids cap: hold_ids_cap — the deployment's declared maximum count of hold ids a hold check result carries, in an answer and in a record (Primitive policy 20). *Default:* 32.

NOTE: watch the unset setting (Capability requirement 14, Capability requirement 16).

Term Legal Hold: composed | absent — whether the deployment composes the [Legal Hold](../atoms/legal-hold.md) pattern over this instance; a knob, set by Capability requirement 69h. *Default:* absent.

Term gate: the composition's check of a record's active holds ahead of a destruction — the gate read, the refusal it fires under strict mode and the gate record that refusal writes (Wiring decision 1 through 4); over an audit event, the check [Purge Event] makes at purge event 5.

Term placement: a retention placement — a [Place Record Under Retention] call (Term admitted placement, Term committed placement); a hold's own is a hold placement.

Term audit instance: the one [Audit Trail](./audit-trail.md) instance serving the composition (Composes 3) — the substrate every decision is recorded through, whose own events the cascade ends.

Term hold records: the holds of the one Legal Hold database instance serving the composition (Composes 1, Term hold database name), read through Legal Hold's read.

Term eligible: elapsed (Term elapsed retention) for a retention of the business retention instance, and Retention Window's purge eligible projection (Retention Window Operation 31) for a retention of the audit retention instance (Composes 19); [Purge Eligible] and [Purge Eligible Events] are the two reads.

Term hold placement: the deployment's own call of Legal Hold's place over an event id of this instance, made under the per-act critical section as Capability requirement 69 states it — a deployment facility, as a scheduled leg's starter is (Execution Contract Scheduled leg 1), and no action of this composition (Non-goal 30); a hold of the business record set is placed by [Place Hold], an admitted hold placement and a committed hold placement, never by this term.

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
  erasure mechanism 10: The erasure mechanism MUST report destroyed for EVERY event a cascade delegates WITHIN Audit Trail's compensation window of the finding's creation.
  NOTE: watch satisfaction (erasure mechanism 10).
  ```
  Term tombstone-by-mutation: overwriting, blanking or truncating a stored field in place.

- **Cascade critical section** — an instance capability requirement, not a knob: Audit Trail's per-act critical section as the audit cascade holds it, a per-key mutual exclusion the host supplies, keyed by the event id; the rest of the family is Audit Trail's (Audit Trail Per-act critical section 1 through 6, 15 and 16). *Default:* none.
  ```
  Cascade critical section 1: A holder that abandoned a call MUST NOT release the critical section BEFORE the lease's instant.
  Cascade critical section 2: IF no held critical section EXISTS THEN the cascade MUST NOT issue a later truth-bearing write.
  NOTE: watch condition negation — *not holding the critical section* is written as a minted term that no instance EXISTS of (Cascade critical section 2, Cascade critical section 3).
  Cascade critical section 3: IF no held critical section EXISTS THEN the cascade MUST NOT land a later truth-bearing write.
  Cascade critical section 4: The host MUST hold a cascade's critical section as a lease:
      Cascade critical section 4a: The host MUST set the lease above the act's completion bound by at least the time resolution, a [Purge Event] re-driven by the first half excepted (Audit Trail Per-act critical section 1e, Per-act critical section 13a, Cascade critical section 5).
      Cascade critical section 4b: IF lease EQUALS expired THEN the invocation MUST NOT issue a truth-bearing write.
  Cascade critical section 5: A [Purge Event] re-driven by the first half MUST NOT take a second critical section for an event id the first half holds.
  Cascade critical section 6: A hold placement MUST take the critical section by Lease's take, waiting no longer than Lease's arrival term (Lease Operation 3).
  Cascade critical section 7: IF a hold placement's take answers unavailable OR no answer THEN the placement MUST NOT write AND MUST report not placed to the placement's caller.
Cascade critical section 8: A cascade MUST take the critical section by Lease's try_take, a [Purge Event] re-driven by the first half excepted (Cascade critical section 5).
  ```

  Term later truth-bearing write: a truth-bearing write after the invocation's first write.

  Term act's completion bound: purge completion bound for a cascade.

  Term abandoned call: a delegation to the erasure mechanism that the holder issued and stopped waiting for without an answer, whose destruction may still take effect inside the lease — never a call to a database, whose write lands under the holder's lease or not at all (Audit Trail Capability requirement 13).

<details markdown="block">
<summary>WHY</summary>

The one Lease requirement no constituent can meet whole is that a refused write was not applied: Retention Window's failed purge may follow a destruction (`Atomic writes 9`), which `Capability requirement 80` declines and the composition reads as what it is.

</details>

### Primitive policy

```
Primitive policy 1: The composition MUST answer invalid-request for a blank record reference.
Primitive policy 2: The composition MUST answer invalid-request for a blank policy reference.
Primitive policy 3: The composition MUST answer invalid-request for a blank actor reference.
Primitive policy 4: The composition MUST answer invalid-request for a blank placing actor.
Primitive policy 5: The composition MUST answer invalid-request for a blank releasing actor.
Primitive policy 6: The composition MUST answer invalid-request for a blank reason.
Primitive policy 7: The composition MUST answer invalid-request for a blank credential.
Primitive policy 8: The composition MUST answer invalid-request for a blank hold id.
Primitive policy 9: The composition MUST answer invalid-request for a supplied blank case reference.
Primitive policy 10: The composition MUST answer invalid-request for a malformed supplied placement instant.
Primitive policy 11: The composition MUST answer invalid-request for a malformed supplied release instant.
Primitive policy 12: IF a payload field EXCEEDS the field's cap THEN the composition MUST answer invalid-request.
Primitive policy 13: The composition MUST NOT call a constituent BEFORE judging the boundary predicate.
Primitive policy 14: An action MUST NOT issue a record_action BEFORE sizing the largest record against the audit instance's payload cap.
Primitive policy 16: The composition MUST compare an opaque input byte-exact.
Primitive policy 17: The composition MUST NOT normalize an opaque input.
Primitive policy 18: The composition MUST NOT store a credential.
Primitive policy 19: The composition MUST NOT answer a credential.
Primitive policy 20: The composition MUST truncate an answered hold id list PER the hold ids cap, keeping the first hold ids of Legal Hold's read order (Legal Hold Operation 24, 25).
Primitive policy 21: A truncated hold id list MUST carry the list's true count.
Primitive policy 22: The composition MUST NOT read a truncated hold id list as an empty hold check result.
Primitive policy 23: IF the largest record EXCEEDS the audit instance's payload cap THEN the action MUST answer invalid-request.
Primitive policy 24: The composition MUST answer invalid-request for a blank retention id.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: record reference | policy reference | actor reference | placing actor | releasing actor | hold id | retention id | case reference.

Term largest record: the largest audit record the act can still leave once the refusals ahead of the intent are judged (Action wiring 108), measured as the serialized envelope Audit Trail measures (Audit Trail payload cap 2) — the gate record alone where the gate refuses under strict mode; otherwise the larger of the intent and the outcome, carrying every retention the read under the record section answered over the record and the hold check result as truncated. An id a constituent has yet to mint is sized at the id's field cap.

Term retentions cap: retentions_cap — the deployment's declared maximum count of retentions one record carries (Capability requirement 81, Capability requirement 82). Placing a retention over a record at the cap is refused (Action wiring 113), so no purge of a record meets more retentions than the cap.

Term full record: a record whose count of retentions Retention Window's declared read answers, read under the record section before the intent (Action wiring 92), EXCEEDS the retentions cap less one — a record that carries no further retention.

Term largest purge record: the record purged outcome of a purge over a record carrying the retentions cap, every field at its field cap and the hold ids at the hold ids cap, measured as Term largest record measures a record — the largest record a purge can leave, so a deployment whose largest purge record fits the payload cap never meets Primitive policy 23 on a purge (Capability requirement 83).

Term largest gate record: the gate record with every field at its field cap and the hold ids at the hold ids cap, measured as Term largest record measures a record — the one record a strict purge over a held record can leave that Primitive policy 23 would refuse, so a deployment whose largest gate record fits the payload cap never meets it (Capability requirement 74, Capability requirement 75).

### Identity

```
Identity 1: The composition MUST compare a record reference byte-exact.
Identity 2: The composition MUST NOT fold a record reference's case.
Identity 3: The composition MUST NOT normalize a record reference.
Identity 4: The composition MUST NOT trim a record reference.
Identity 5: A renamed record MUST NOT inherit the prior record reference's hold.
Identity 6: A deployment needing an identity continuity MUST discharge the continuity ahead of a call.
Identity 7: A deployment MAY place a hold again under a new record reference.
Identity 8: A deployment MAY canonicalize a record reference ahead of a call.
```

### Audit arm

```
Audit arm 1: IF the record start floor admits a further call THEN the composition MUST retry a recording-failure carrying step-2.
Audit arm 2: The composition MUST NOT retry a recording-failure carrying step-3.
Audit arm 5: The composition MUST read a landed record back by the invocation id.
Audit arm 6: The composition MUST alert on a landed record carrying no retention.
Audit arm 7: IF the substrate refuses an intent on a credential THEN the action MUST answer invalid-credential.
Audit arm 10: The composition MUST NOT retry an invalid-credential answer in a loop.
Audit arm 11: The composition MUST NOT read an invalid-request answer as unreachable.
Audit arm 12: The composition MUST read an invalid-request carrying step-4 as a landed record.
Audit arm 13: The composition MUST read an invalid-request carrying a step below step-4 as an owed record, so the action answers recording-failure and commits nothing.
Audit arm 14: The composition MUST alert on an invalid-request answer.
Audit arm 15: The composition MUST NOT retry an invalid-request answer.
Audit arm 16: The composition MUST read a recording-failure carrying step-3 as an owed record, so the action answers recording-failure and commits nothing.
Audit arm 17: IF the record start floor admits no further call THEN the composition MUST read a recording-failure carrying step-2 as an owed record, so the action answers recording-failure and commits nothing.
Audit arm 18: The composition MUST read a record_action that answers no answer as an owed record, so the action answers recording-failure and commits nothing.
Audit arm 19: IF the substrate refuses a gate record on a credential THEN [Purge Record] MUST answer invalid-credential.
Audit arm 20: The composition MUST read an outcome the substrate refuses on a credential as an owed record, so the action answers recording-failure and commits nothing.
Audit arm 21: IF the record start floor admits a further call THEN the composition MUST retry a recording-failure carrying step-4.
Audit arm 22: IF the record start floor admits no further call THEN the composition MUST read a recording-failure carrying step-4 as an owed record, so the action answers recording-failure and commits nothing.
NOTE: watch the retention step's recording failure (Audit arm 21, Audit arm 22).
Audit arm 23: The composition MUST read a record_action that answers state-unavailable as a recording-failure carrying step-2 (Execution Contract Read 3).
NOTE: watch the constituent's failed read (Audit arm 23).
```

Term landed record: an audit record the substrate has appended and attested, whatever the substrate then answered.

Term owed record: an audit record this composition must write in the act's own transaction and the substrate has not appended — the act then answers recording-failure carrying the record's position and commits nothing (Execution Contract Read 4); a record the substrate refuses on the caller's credential is the caller's own answer (Audit arm 7, 19), and a record the record section admitted no first call of was never issued (Concurrency 20, 21).

### Action wiring

```
place_record_under_retention(record_ref, policy_ref, actor_ref, credential)
  answers retention_id
  refuses invalid-request | invalid-credential | section-unavailable | storage-failure | recording-failure(position)

place_hold(record_ref, placed_by, credential, reason, optional case_ref, optional placed_at)
  answers hold_id
  refuses invalid-request | invalid-credential | section-unavailable | storage-failure | recording-failure(position)

release_hold(hold_id, released_by, credential, reason, optional released_at)
  answers released
  refuses invalid-request | invalid-credential | not-known | already-released | hold-check-unavailable | section-unavailable | storage-failure | recording-failure(position)

purge_eligible()
  answers the eligibility tuples
  refuses storage-failure

purge_record(retention_id, actor_ref, credential)
  answers ok
  refuses invalid-request | invalid-credential | not-known | not-eligible | under-active-retention | under-legal-hold(hold_ids, count) | hold-check-unavailable | section-unavailable | storage-failure | recording-failure(position)
```

Term position: intent | outcome | gate — the record a write lands: the intent, the outcome or the gate record.

```
Action wiring 1: The composition MUST NOT record an intent BEFORE the boundary predicate passes.
Action wiring 2: The composition MUST NOT make a committing call BEFORE recording an intent.
Action wiring 3: An intent MUST carry the invocation id.
Action wiring 4: An outcome MUST carry the invocation id.
Action wiring 5: A gate record MUST carry the invocation id.
Action wiring 6: An intent MUST carry the invocation's inputs, the credential excepted.
Action wiring 7: An intent MUST NOT carry an id a constituent mints for the intent's own act.
Action wiring 8: An intent MUST carry the injected now as intent instant.
Action wiring 9: An admitted placement MUST call Retention Window's place_under_retention with the record reference AND the policy reference.
Action wiring 10: A committed placement MUST read the retention's retention deadline AND purge deadline from Retention Window's declared read.
Action wiring 11: A committed placement MUST record a retention placed outcome carrying the retention id, the record reference, the policy reference, the retention deadline AND the purge deadline.
Action wiring 12: IF a committed placement's outcome landed THEN [Place Record Under Retention] MUST answer the retention id.
Action wiring 13: IF Retention Window answers invalid-policy THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 14: IF Retention Window answers policy-not-found THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 15: IF Retention Window answers invalid-request THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 16a: IF Retention Window answers registry-unavailable THEN [Place Record Under Retention] MUST answer storage-failure (Execution Contract Constituent failure 2).
Action wiring 17: An admitted hold placement MUST call Legal Hold's place with the record reference, the placing actor, the reason, the case reference AND the supplied placement instant, where the call supplies one (Primitive policy 10).
Action wiring 18: A committed hold placement MUST record a hold placed outcome carrying the hold id, the record reference, the placing actor, the reason, the case reference AND the placement instant.
Action wiring 19: IF a committed hold placement's outcome landed THEN [Place Hold] MUST answer the hold id.
Action wiring 20: IF Legal Hold answers invalid-request THEN [Place Hold] MUST answer invalid-request.
Action wiring 22: The composition MUST NOT record a hold release intent BEFORE reading the hold through Legal Hold's read.
Action wiring 23: IF no hold EXISTS for the hold id THEN [Release Hold] MUST answer not-known.
Action wiring 24: IF the hold state EQUALS released THEN [Release Hold] MUST answer already-released.
Action wiring 25: An admitted hold release MUST call Legal Hold's release with the hold id, the releasing actor, the reason AND the supplied release instant, where the call supplies one (Primitive policy 11).
Action wiring 26: A committed hold release MUST record a hold released outcome carrying the hold id, the reason AND the release instant.
Action wiring 27: IF a committed hold release's outcome landed THEN [Release Hold] MUST answer released.
Action wiring 28: IF Legal Hold answers not-known THEN [Release Hold] MUST answer not-known.
Action wiring 29: IF Legal Hold answers already-released THEN [Release Hold] MUST answer already-released.
Action wiring 30: IF Legal Hold answers invalid-request THEN [Release Hold] MUST answer invalid-request.
Action wiring 32: [Purge Eligible] MUST read the retentions from Retention Window's declared read.
Action wiring 33: [Purge Eligible] MUST NOT answer a retention outside elapsed retention.
Action wiring 34: [Purge Eligible] MUST call Legal Hold's read with the record reference AND the active state PER answered retention.
Action wiring 35: [Purge Eligible] MUST answer the hold count PER answered retention.
Action wiring 36: IF Legal Hold refuses the read THEN [Purge Eligible] MUST carry the unavailable sentinel as the hold count.
Action wiring 37: [Purge Eligible] MUST NOT answer a zero hold count for unreadable hold records.
Action wiring 38: [Purge Eligible] MUST answer the retention deadline AND the purge deadline PER answered retention.
Action wiring 39: [Purge Eligible] MUST order the answer by retention deadline, rising.
Action wiring 40: [Purge Eligible] MUST order two retentions sharing a retention deadline by retention id, rising.
Action wiring 41: [Purge Eligible] MUST NOT write.
Action wiring 43: A reader MUST NOT read [Purge Eligible]'s answer as a sibling statement.
Action wiring 44: The composition MUST NOT answer not-known for a purge BEFORE reading the retention id from Retention Window's declared read.
Action wiring 45: IF Retention Window's declared read answers no retention for the retention id THEN [Purge Record] MUST answer not-known.
Action wiring 47: IF the hold check admitted the destruction AND the named retention IS IN the elapsed retentions AND the sibling set carries a retention outside elapsed retention THEN [Purge Record] MUST answer under-active-retention.
Action wiring 48: A purge MUST call Legal Hold's read with the record reference AND the active state.
Action wiring 49: A purge MUST call Legal Hold's read whatever the named retention's eligibility.
Action wiring 50: IF Legal Hold refuses the read THEN [Purge Record] MUST answer hold-check-unavailable.
Action wiring 52: IF the hold check result stands non-empty AND the hold check mode EQUALS strict THEN a purge MUST record a purge blocked gate record carrying the retention id, the record reference AND the hold check result.
Action wiring 53: IF the hold check result stands non-empty AND the hold check mode EQUALS strict AND the gate record landed THEN a purge MUST answer under-legal-hold carrying the hold ids AND the count.
Action wiring 54: IF the hold check result stands non-empty AND the hold check mode EQUALS strict THEN a purge MUST NOT call Retention Window's purge.
Action wiring 55: IF the hold check result stands non-empty AND the hold check mode EQUALS advisory THEN a purge MUST record the hold override.
Action wiring 56: IF the hold check result stands non-empty AND the hold check mode EQUALS advisory THEN a purge MUST NOT record a purge blocked gate record.
Action wiring 57: IF the hold check admitted the destruction AND the named retention IS NOT IN the elapsed retentions THEN a purge MUST answer not-eligible.
Action wiring 58: An admitted purge MUST call Retention Window's purge with the retention id.
Action wiring 59: A committed purge MUST call Retention Window's purge PER sibling set member, a sibling Action wiring 81 covers excepted.
Action wiring 60: A committed purge MUST record a record purged outcome carrying the retention id, the record reference, the purged retention ids, the hold check result, the hold override AND the named retention's purge instant as purge instant.
Action wiring 61: A committed purge MUST mark a purged sibling purged in the purged retention ids.
Action wiring 63: IF a committed purge's outcome landed THEN [Purge Record] MUST answer ok.
Action wiring 64: IF Retention Window answers not-retained for the named retention THEN a purge MUST answer not-known.
Action wiring 65: IF Retention Window answers not-known for the named retention THEN a purge MUST answer not-known.
Action wiring 66: IF Retention Window answers retention-period-not-elapsed for the named retention THEN a purge MUST answer not-eligible.
Action wiring 68: IF Retention Window answers a refusal for a sibling AND the refusal DOES NOT EQUAL not-retained THEN a purge MUST commit nothing AND MUST answer storage-failure.
Action wiring 69: The composition MUST remove a purged retention from an index whatever the outcome record's answer.
Action wiring 73: A caller MUST read a not-known on a re-invoked purge as a committed destruction, a caller that reads the retention's state from Retention Window's declared read instead MAY read the state the read answers.
Action wiring 74: IF Legal Hold's read answers invalid-query THEN the composition MUST read the read as refused AND MUST alert.
Action wiring 75: The composition MUST answer hold-check-unavailable for a Legal Hold read that answers no answer, or answers other than holds or invalid-query, ahead of an act's first committing call.
Action wiring 76: A purge intent MUST carry the hold check result.
Action wiring 77: IF the database name a read of Legal Hold answers DOES NOT EQUAL the hold database name THEN the composition MUST read the read as refused (Legal Hold Instance 7).
Action wiring 79: IF an act's first committing call answers no answer THEN the action MUST answer storage-failure.
Action wiring 80: IF Retention Window's purge answers no answer OR state-unavailable for a sibling THEN a purge MUST commit nothing AND MUST answer storage-failure.
NOTE: watch the constituent's failed read (Action wiring 80).
Action wiring 81: IF the remaining term a sibling's reading answers DOES NOT EXCEED the sibling floor THEN a purge MUST commit nothing AND MUST answer section-unavailable.
Action wiring 82: A caller MUST retry a [Purge Record] that answered storage-failure (Retention Window Purge persistence 2).
Action wiring 83: IF an action's intent stands as an owed record THEN the action MUST commit nothing AND MUST answer recording-failure carrying intent.
Action wiring 84: IF an action's outcome stands as an owed record THEN the action MUST commit nothing AND MUST answer recording-failure carrying outcome.
Action wiring 85: IF a purge's gate record stands as an owed record THEN [Purge Record] MUST commit nothing AND MUST answer recording-failure carrying gate.
Action wiring 86: An action whose first committing call answered no answer MUST NOT record an outcome.
Action wiring 87: A committed hold placement MUST read the hold's placement instant from Legal Hold's read.
Action wiring 88: A committed hold release MUST read the hold's release instant from Legal Hold's read.
Action wiring 89: IF Legal Hold refuses the read of Action wiring 22 THEN [Release Hold] MUST answer hold-check-unavailable.
Action wiring 90: IF Retention Window answers not-retained for a sibling THEN a purge MUST mark the sibling purged.
Action wiring 91: A purge MUST NOT call Retention Window's purge for a sibling BEFORE the named retention's purge answered ok.
Action wiring 92: A placement MUST NOT record an intent BEFORE reading the record's retentions from Retention Window's declared read.
Action wiring 93: IF the record reference names a destroyed record THEN [Place Record Under Retention] MUST answer invalid-request (Retention Window Capability requirement 15).
Action wiring 94: IF the named retention covers a destroyed record THEN [Purge Record] MUST answer not-known.
Action wiring 95: [Purge Eligible] MUST NOT answer a retention covering a destroyed record.
Action wiring 96: IF [Place Hold] answers storage-failure OR section-unavailable OR recording-failure carrying intent THEN the caller MUST retry the call (Legal Hold Place persistence 2).
Action wiring 97: The composition MUST alert on a storage-failure from a committing call (Legal Hold Place persistence 3, Retention Window Purge persistence 3).
Action wiring 98: IF a constituent answers state-unavailable to an act's first committing call THEN the action MUST answer storage-failure.
Action wiring 99: IF a read an act makes for the act's outcome answers a refusal OR state-unavailable OR no answer THEN the action MUST commit nothing AND MUST answer recording-failure carrying outcome.
Action wiring 100: A purge MUST NOT make the gate read BEFORE judging the not-known refusals of Action wiring 45 and Action wiring 94.
Action wiring 101: [Purge Eligible] MUST NOT answer a retention whose retention state Retention Window's declared read answers purged.
Action wiring 106: A committed purge MUST read the named retention's purge instant from Retention Window's declared read.
Action wiring 108: A purge MUST NOT record an intent BEFORE judging the refusals of Action wiring 47, Action wiring 50, Action wiring 53 and Action wiring 57.
Action wiring 109: IF Retention Window's declared read answers state-unavailable OR no answer ahead of an act's first committing call THEN the action MUST answer storage-failure.
Action wiring 110: [Purge Eligible] MUST answer EVERY elapsed retention Retention Window's declared read answers, a retention Action wiring 95 covers excepted AND a retention Action wiring 101 covers excepted.
Action wiring 111: IF Retention Window's declared read answers state-unavailable OR no answer to a call of [Purge Eligible] THEN the action MUST answer storage-failure.
NOTE: watch the constituent's failed read (Action wiring 98, Action wiring 109, Action wiring 111).
Action wiring 112: A purge MUST call the record destruction pattern with the record reference ONLY AFTER the purge's transaction committed (Execution Contract Atomicity layers).
Action wiring 113: IF the record is a full record THEN [Place Record Under Retention] MUST answer invalid-request.
Action wiring 114: A caller's retry of [Purge Record] MUST end at the first answer other than storage-failure; a caller that stops earlier leaves the retention on [Purge Eligible]'s list, which re-offers the retention while the retention stands elapsed (Action wiring 110).
Action wiring 115: A caller's retry of [Place Hold] MUST end at the first answer other than storage-failure, section-unavailable and recording-failure carrying intent; a hold a retried call placed twice stands twice (Composition state 30).
```

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended.

Term outcome: the record_action call naming what an invocation did — retention_placed | hold_placed | hold_released | record_purged.

Term gate record: the purge_blocked_by_hold record a strict-mode refusal writes at the gate — a self-standing record, neither an intent nor an outcome.

Term committing call: `RetentionWindow.place_under_retention` | `RetentionWindow.purge` | `LegalHold.place` | `LegalHold.release` | a call to the record destruction pattern — a call that writes outside the audit instance.

Term admitted placement: a [Place Record Under Retention] call whose boundary predicate passed and whose intent landed.

Term admitted hold placement: a [Place Hold] call whose boundary predicate passed and whose intent landed.

Term admitted hold release: a [Release Hold] call whose boundary predicate passed, whose named hold's hold state EQUALS active and whose intent landed.

Term admitted purge: a [Purge Record] call whose boundary predicate passed, whose named retention is an elapsed retention, whose sibling set carries no retention outside elapsed retention, whose hold check admitted the destruction and whose intent landed.

Term committed placement: an admitted placement whose call of Retention Window's place_under_retention answered a retention id.

Term committed hold placement: an admitted hold placement whose call of Legal Hold's place answered a hold id.

Term committed hold release: an admitted hold release whose call of Legal Hold's release answered released.

Term committed purge: an admitted purge whose named retention's purge answered ok — the word names that write, which Atomic writes 5 commits in one transaction with the outcome record, so no commit stands apart from the outcome.

Term destroyed record: a record a purged retention of the business retention instance covers.

Term elapsed retention: a retention whose retention deadline does not exceed the injected now less the seam offset allowance — the eligibility predicate, derived at read time and never stored. The allowance is there because Retention Window set the retention deadline from the reading of the call that placed the retention, another call and perhaps another node's clock, and this composition sets that deadline against a reading of its own (Execution Contract Logic confinement 18): a sibling read as elapsed on a reading ahead of that clock's would be destroyed with the record before the sibling's own deadline, though Retention Window's purge, a constituent call of this one, reads this composition's now (Execution Contract Logic confinement 19). So elapsed retention is stricter by one allowance than the eligibility Retention Window reads at its own seam, and on purpose: a retention whose deadline falls within one allowance of the now is eligible there and not yet elapsed here, and until the allowance has passed a purge that names it answers not-eligible, and a purge whose sibling it is answers under-active-retention (Action wiring 57, Action wiring 47). Retention Window's eligibility forbids a destruction where it answers no and obliges none where it answers yes (Retention Window Simultaneous retention 4), so the gate may refuse, for one allowance, what the constituent would allow.

Term hold check result: what Legal Hold's read answered at the gate — empty, or the blocking hold ids with the blocking count.

Term hold check admitted: said of a gate read whose hold check result stands empty, or stands non-empty under advisory mode.

Term hold-blocked: said of a retention [Purge Eligible] answers with a hold count above zero or with the unavailable sentinel.

Term eligibility tuples: the answer of [Purge Eligible] — for each answered retention, the retention id, the record reference, the retention deadline, the purge deadline and the hold count.

Term hold override: the field a record purged outcome carries — true where the hold check result stands non-empty under advisory mode, and false everywhere else.

Term hold count: the count of active holds over a retention's record that [Purge Eligible] answers, or the unavailable sentinel.

Term horizon alert: the alert a deployment admitting an unbounded hold raises, on the alerting surface, for a hold approaching the payload horizon — a hold whose life EXCEEDS the payload horizon less the horizon alert lead (Capability requirement 13, Capability requirement 84, Non-goal 23).

Term horizon alert lead: horizon_alert_lead — the deployment's declared span before the payload horizon at which a hold's life is read as approaching it. *Default:* none.

Term entry instant: the recording instant of a hold placement's intent, and of a hold release's — when the hold, and its release, entered the system, as against the placement instant and the release instant a caller may assert (Clock semantics 15, Clock semantics 18). The intent and not the outcome.

Term hold life: the span from a hold's entry instant to the entry instant of its release, or to the injected now while the hold stands active.

Term unavailable sentinel: unavailable — the one non-integer value a hold count admits — what [Purge Eligible] answers for a retention whose hold records could not be read, and what a reader treats as hold-blocked rather than as zero.

Term purged retention ids: the named retention and every sibling set member a record purged outcome names, each marked purged.

#### Closure table

Every input an action takes, and every answer a call of the five business actions, of the two audit-instance actions and of the first half can meet — an action of [Audit Trail](./audit-trail.md) called inside another, a constituent's action or read, a read or write of this composition's own records, a lease, the erasure mechanism — with where the call lands it and the rule that owns the landing, in the form Audit Trail's closure table takes. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here (Term no answer, Audit Trail). The table covers the five business actions and the audit cascade, which moved here from Audit Trail.

**The business actions.** Every refusal of [Place Record Under Retention], [Place Hold], [Release Hold], [Purge Eligible] and [Purge Record] commits nothing (Execution Contract Read 4), so no row of this table lands a partial; each state-changing action is one transaction with its intent and outcome (Atomic writes 5, Execution Contract Database 1). The rows below read what each call answers and where the answer lands, in the order the action makes the calls.

**Inputs.** [Purge Eligible] and [Purge Eligible Events] take none.

| Action | Input | Lands | Owner |
|---|---|---|---|
| [Place Record Under Retention] | a blank record reference, policy reference, actor reference or credential | invalid-request, no call and no intent | Primitive policy 1, 2, 3, 7, 13 |
| [Place Hold] | a blank record reference, placing actor, reason or credential; a supplied blank case reference; a malformed supplied placement instant | invalid-request, no call and no intent | Primitive policy 1, 4, 6, 7, 9, 10, 13 |
| [Release Hold] | a blank hold id, releasing actor, reason or credential; a malformed supplied release instant | invalid-request, no call and no intent | Primitive policy 5, 6, 7, 8, 11, 13 |
| [Purge Record] | a blank retention id, actor reference or credential | invalid-request, no call and no intent | Primitive policy 3, 7, 13, 24 |
| every state-changing action | a payload field past its field cap; a largest record past the audit instance's payload cap | invalid-request, no record_action issued | Primitive policy 12, 14, 23 |
| [Purge Event] | an event id no constituent knows | not-known | purge event 1; purge event step 0.1a; Audit Trail Primitive policy 24 |

**Every state-changing action: the take and the record_action calls.**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the try-take of the record section | held, or no answer | section-unavailable, nothing written | Concurrency 12 |
| | granted, then the lease reading expired ahead of the act's first committing call, or the record start floor admitting no first call of the act's first record_action | section-unavailable, nothing written | Concurrency 20, 21 |
| the intent's record_action | landed | the act's first committing call | Action wiring 2 |
| | refused on the credential | invalid-credential | Audit arm 7 |
| | invalid-request carrying step-4 | a landed record | Audit arm 12 |
| | invalid-request carrying a step below step-4 | an owed record: recording-failure(intent), nothing committed, an alert, no retry | Audit arm 13, 14, 15; Action wiring 83 |
| | recording-failure carrying step-2 or step-4 | retried while the record start floor admits a further call, else an owed record | Audit arm 1, 17, 21, 22 |
| | recording-failure carrying step-3 | an owed record: recording-failure(intent), no retry | Audit arm 2, 16 |
| | state-unavailable | recording-failure carrying step-2 | Audit arm 23 |
| | no answer | an owed record: recording-failure(intent) | Audit arm 18; Action wiring 83 |
| the outcome's record_action | landed | the action's answer | Action wiring 12, 19, 27, 63 |
| | refused on the credential, or no answer | an owed record: recording-failure(outcome), nothing committed | Audit arm 18, 20; Action wiring 84 |

**[Place Record Under Retention].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the read of the record's retentions, under the record section | the retentions | the intent | Action wiring 92 |
| | a purged retention over the record, a destroyed record | invalid-request | Action wiring 93 |
| | a full record | invalid-request | Action wiring 113 |
| | state-unavailable, or no answer | storage-failure | Action wiring 109 |
| Retention Window's place_under_retention | a retention id | the retention's deadlines read, the outcome recorded, the retention id answered | Action wiring 9 through 12 |
| | invalid-policy, policy-not-found or invalid-request | invalid-request | Action wiring 13, 14, 15 |
| | registry-unavailable, or state-unavailable | storage-failure | Action wiring 16a, 98 |
| | no answer | storage-failure, no outcome | Action wiring 79, 86 |
| the read of the retention's deadlines for the outcome | a refusal, state-unavailable or no answer | recording-failure(outcome), nothing committed | Action wiring 10, 99 |

**[Place Hold].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Legal Hold's place | a hold id | the hold's placement instant read, the outcome recorded, the hold id answered | Action wiring 17 through 19, 87 |
| | invalid-request | invalid-request | Action wiring 20 |
| | state-unavailable | storage-failure | Action wiring 98 |
| | no answer | storage-failure, no outcome | Action wiring 79, 86 |
| the read of the placement instant for the outcome | a refusal, state-unavailable or no answer | recording-failure(outcome), nothing committed | Action wiring 87, 99 |
| the answer | storage-failure, section-unavailable or recording-failure(intent) | the caller retries to the first other answer; an alert on a storage-failure | Action wiring 96, 97, 115 |

**[Release Hold].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Legal Hold's read of the hold, under the record section, ahead of the intent | no hold | not-known | Action wiring 22, 23 |
| | a hold whose hold state EQUALS released | already-released | Action wiring 24 |
| | a refusal, or no answer | hold-check-unavailable | Action wiring 75, 89 |
| Legal Hold's release | released | the release instant read, the outcome recorded, released answered | Action wiring 25 through 27, 88 |
| | not-known, already-released or invalid-request | the same answer | Action wiring 28, 29, 30 |
| | state-unavailable | storage-failure | Action wiring 98 |
| | no answer | storage-failure, no outcome | Action wiring 79, 86 |
| the read of the release instant for the outcome | a refusal, state-unavailable or no answer | recording-failure(outcome), nothing committed | Action wiring 88, 99 |

**[Purge Eligible].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Retention Window's declared read | the retentions | each elapsed retention, a retention covering a destroyed record and a purged retention left out, ordered by retention deadline and then retention id | Action wiring 32, 33, 39, 40, 95, 101, 110 |
| | state-unavailable, or no answer | storage-failure | Action wiring 111 |
| Legal Hold's read, per answered retention | the active holds | the hold count | Action wiring 34, 35 |
| | a refusal | the unavailable sentinel as the hold count, never zero | Action wiring 36, 37; Invariant 7.3 |

**[Purge Record].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| Retention Window's declared read of the named retention, before the gate read | no retention for the id, or a retention covering a destroyed record | not-known, no gate read | Action wiring 44, 45, 94, 100 |
| | state-unavailable, or no answer | storage-failure | Action wiring 109 |
| Legal Hold's read at the gate | no active hold | the sibling set | Action wiring 48, 49 |
| | active holds, strict mode | the gate record, under-legal-hold carrying the hold ids and the count, Retention Window's purge not called | Action wiring 52, 53, 54 |
| | active holds, advisory mode | the hold override recorded, no gate record | Action wiring 55, 56 |
| | a refusal, an invalid-query, a database name that is not the hold database name, or no answer | hold-check-unavailable | Action wiring 50, 74, 75, 77 |
| the gate record's record_action | refused on the credential | invalid-credential | Audit arm 19 |
| | owed | recording-failure(gate), nothing committed | Action wiring 85 |
| the sibling set, the hold check admitting | a sibling outside elapsed retention | under-active-retention | Action wiring 47 |
| the named retention, the hold check admitting | not in the elapsed retentions | not-eligible | Action wiring 57 |
| Retention Window's purge of the named retention | ok | the siblings purged, the outcome recorded | Action wiring 58, 59, 91 |
| | not-retained, or not-known | not-known | Action wiring 64, 65 |
| | retention-period-not-elapsed | not-eligible | Action wiring 66 |
| | state-unavailable, or no answer | storage-failure | Action wiring 79, 98 |
| Retention Window's purge of a sibling | ok | the sibling marked purged | Action wiring 59, 61 |
| | not-retained | the sibling marked purged | Action wiring 90 |
| | another refusal, state-unavailable or no answer | nothing committed, storage-failure | Action wiring 68, 80 |
| | the remaining term not exceeding the sibling floor | nothing committed, section-unavailable | Action wiring 81 |
| the read of the named retention's purge instant for the outcome | a refusal, state-unavailable or no answer | recording-failure(outcome), nothing committed | Action wiring 99, 106 |
| the call to the record destruction pattern, after the commit | any answer | no answer to the action: the purge stands committed, the pattern retries a record it left standing | Action wiring 112; Capability requirement 66 through 68 |

**[Purge Eligible Events]: what the read answers, and a read that fails or never answers.**

| Action | What the reads answer | Lands | Owner |
|---|---|---|---|
| [Purge Eligible Events] | every retention | each eligible one mapped to its event id, no refusal, no hold filter | purge eligible events 1, 2, 5, 6 |
| [Purge Eligible Events] | a failed read | state-unavailable (Execution Contract Read 1 through 3) | purge eligible events 1 |
| [Purge Eligible Events] | no answer | no answer to give, never an empty list (Execution Contract Error model 1) | purge eligible events 1 |

**[Purge Event].**

| Call | Answer | Lands | Owner |
|---|---|---|---|
| the try-take of the critical section keyed by event id | its answers | the lease tables below | purge event step 0.6; Cascade critical section 8 |
| the read of the audit record through Audit Trail's read_record, step 0 | not-known | not-known, no step 0.2 | purge event 1; purge event step 0.1a |
| | an audit record | the hold read where Legal Hold is composed, then step 0 | purge event step 0.1; purge event 5c |
| | a failed read or an invalid-query | state-unavailable, nothing written | Execution Contract Read 1 through 3; Audit Trail Capability requirement 3a |
| | no answer | cascade-failure(seal), never not-known | purge event step 0.11 |
| the hold read, where Legal Hold is composed | a hold over the event | under-legal-hold, no cascade step | purge event 5b, 5d |
| | no hold | step 0 | purge event 5c |
| | no holds returned: a failed read, an invalid-query, no answer or a database name that is not the hold database name | cascade-failure(hold), no cascade step | purge event 5e, 5f |
| the coverage status the audit record carries | covered, records-purged or partially purged, a covering seal existing | step 0½, no seal_now | purge event step 0.5 |
| | unsealed tail | Audit Trail's seal_now | purge event step 0.2 |
| Audit Trail's seal_now | evidence id, a covering seal existing for the event | step 0½ | purge event step 0.3, 0.12 |
| | evidence id, no covering seal for the event | cascade-failure(seal), the event left on [Purge Eligible Events]'s list | purge event step 0.12; purge event 3c |
| | nothing-to-seal | the covering seal read again, and where none exists, cascade-failure(seal) | purge event step 0.8, 0.9 |
| | any other answer | cascade-failure(seal) | purge event step 0.4 |
| the retention status the audit record carries, step 0½ | a retention record | step 1 | purge event step 0½.1 |
| | none, a log entry standing | retention-unresolved, no cascade step, step 0's seal standing | purge event step 0½.2 through 0½.4 |
| | no answer | cascade-failure(step-1), never retention-unresolved or not-known | purge event step 0½.6 |
| Audit Trail's record_destruction, step 1 | ok | step 3 | purge event step 1.1, 2.4 |
| | retention-period-not-elapsed | [Not Eligible], step 0's seal standing, nothing else written | purge event step 1.2; Audit Trail retention policy 5 |
| | not-known | cascade-failure(step-1), the retention as found: the event stood in the log at step 0 (Audit Trail Invariant 8.5) | purge event step 1.3; purge event 3a |
| | destruction-failure(step-1) | cascade-failure(step-1), the retention as found | purge event step 1.5; purge event 3a |
| | destruction-failure(step-2) | cascade-failure(step-2), the retention as found | purge event step 1.7; purge event 3a |
| | state-unavailable | passed through unchanged, nothing written | Execution Contract Read 1 through 3 |
| | no answer | cascade-failure(step-2); a write that landed commits step 1's transition with it, an open entry the first half re-drives | purge event step 1.6; purge event 3a, 4a; First half 3, 5 |
| the read of erasure outcomes, step 3 | a destroyed outcome | no delegation: the cascade complete, ok | purge event step 3.12; Term completed cascade |
| | none | the delegation | purge event step 3.1, 3.11 |
| the delegation to the erasure mechanism | destroyed | the outcome recorded | purge event step 3.4; erasure outcomes 1 |
| | destruction-failed(reason) | the outcome recorded, cascade-failure(step-3) | purge event step 3.4, 3.5; erasure outcomes 1, 6 |
| | no answer | an abandoned call: no outcome to record, cascade-failure(step-3), the lease kept to its instant | purge event step 3.7; Cascade critical section 1 |
| the outcome record's write | written | ok, the cascade complete | purge event step 3.4, 4.1; Term completed cascade |
| | refused or no answer | cascade-failure(step-3) | purge event step 3.7 |
| a read at step 0, step 0½ or step 3 | a failed read or an invalid-query | the step's cascade-failure, its write not issued | purge event step 3.6; Audit Trail Capability requirement 3a |
| | no answer | the step's cascade-failure, no further write | purge event 8 |

Audit Trail's record_destruction commits step 1's transition only with step 2's destruction record (Audit Trail Invariant 4.2), so a cascade-failure(seal), (hold), (step-1), (step-2) or (in-flight) leaves the retention as found and on [Purge Eligible Events]'s list while Retained, a step-2 write that landed without an answer excepted (purge event 3a, 3b, 3c, 3d, 3e). A cascade-failure(step-3) over an incomplete cascade, or a step-2 one over an open entry, leaves an open entry the first half re-drives and the deployment surfaces (purge event 4a, 4b), and one a repeat lands over a completed cascade, its read at step 3 failing or giving no answer, leaves the cascade complete (purge event step 3.6; purge event 8).

**The first half: what the reads answer.**

| Half | What the reads answer | Lands | Owner |
|---|---|---|---|
| first | a Purged retention younger than purge edge | not examined | First half 2 |
| first | a Purged retention whose read_record answers records-purged, and a destroyed outcome | left alone, a hold placed after its destruction changing nothing of it | First half 3; Composes 23; Invariant 6.1 |
| first | records-purged or the destroyed outcome missing, at the read under the critical section keyed by event id as well | the cascade re-driven through [Purge Event] | First half 3, 5 through 7 |
| first | a Purged retention past the audit edge with no destroyed outcome, no suspended entry | not re-driven, surfaced as a residual finding against the erasure mechanism | First half 14; Boundary one 5; Check 8.12 |

**The first half's re-drive.**

| [Purge Event] answers | Lands | Owner |
|---|---|---|
| ok | the entry closed | First half 5; Term completed cascade |
| under-legal-hold | the entry left open and uncounted, re-driven on the first run after the hold is released, its window counted from the first hold-free run | First half 9 through 11; Invariant 12.1, 12.2, 12.3 |
| a cascade-failure other than in-flight, or state-unavailable | the entry left open, re-driven on every run that takes its critical section, and surfaced | First half 5; Boundary one 4; purge event 4a, 4b |
| not-known, not-eligible, retention-unresolved, cascade-failure(in-flight) | unreachable: the event is logged under a Purged retention, its purge answers not-retained, and the re-drive runs under the half's own critical section | Audit Trail Composes 9; Audit Trail record destruction step 1.4; Cascade critical section 5 |

**Leases: the take and the remaining reading.** Audit Trail's lease tables carry the cascade's cells as columns of their own (Audit Trail, Action wiring, Closure table); the cascade's cells read:

| take answers | [Purge Event]: try_take, keyed by event id |
|---|---|
| granted | the read of the audit record of step 0.1 (purge event step 0.6) |
| unavailable, or held | cascade-failure(in-flight), nothing written, the retention as found (purge event step 0.7; purge event 3d, 3e) |
| no answer | cascade-failure(in-flight) (purge event step 0.10) |

| remaining answers | [Purge Event] |
|---|---|
| live | the step's write (Cascade critical section 4b) |
| expired, none, or no answer (Audit Trail Term lease; Audit Trail Per-act critical section 16) | before step 1 commits, no step 1 and cascade-failure(step-1); after it, no further write and cascade-failure naming the first step not completed, which the first half re-drives (purge event 7a, 7b, 7c, 7d) |

A cascade, or a first half re-driving one, whose delegation gave no answer keeps the lease to its instant (Cascade critical section 1).

#### Purge Eligible Events contract

```
purge_eligible_events()
  answers list of event_ids
```

```
purge eligible events 1: [Purge Eligible Events] MUST read eligibility through Retention Window's declared read.
purge eligible events 2: [Purge Eligible Events] MUST map each eligible retention id to the event id through the retention record's record reference.
purge eligible events 3: [Purge Eligible Events] MUST NOT re-derive eligibility.
purge eligible events 4: [Purge Eligible Events] MUST NOT share the projection's now reading with a later RetentionWindow.purge.
purge eligible events 5: [Purge Eligible Events] MUST NOT answer a refusal, the state-unavailable of a failed read (Execution Contract Read 1) excepted.
purge eligible events 6: [Purge Eligible Events] MUST NOT filter by legal hold.
purge eligible events 8: The deployment MUST call [Purge Event] for EVERY event [Purge Eligible Events] answers.
purge eligible events 9: IF a Retained retention's purge deadline PRECEDES now AND no hold EXISTS over the event THEN the deployment MUST surface a compliance alert.
```

Term purge sweep: the deployment's calls of [Purge Event] over the events [Purge Eligible Events] answers (purge eligible events 8) — the sweep a refusal that changed nothing leaves the event to (purge event 3c).

#### Purge Event contract

```
purge_event(event_id)
  answers ok
  refuses not-known | not-eligible | retention-unresolved | cascade-failure(step) | under-legal-hold
```

For any event whose retention has elapsed, the composition coordinates a cascade across the records of Audit Trail's four constituents, reaching them through Audit Trail's read_record, seal_now and record_destruction and the deployment's erasure mechanism. The arms: not-known for an id no constituent knows; [Not Eligible] when Retention Window refuses because the period has not elapsed; [Retention Unresolved] when the id resolves to a log entry but to no retention record; [Cascade Failure] carrying the step; and, where a Legal Hold is composed, [Under Legal Hold].

```
purge event 1: IF no retention record EXISTS AND no log entry EXISTS THEN [Purge Event] MUST land not-known.
purge event 2: [Cascade Failure] MUST carry EXACTLY ONE OF seal, hold, step-1, step-2, step-3, in-flight.
purge event 3: WHEN cascade-failure EQUALS seal OR cascade-failure EQUALS hold OR cascade-failure EQUALS step-1 OR cascade-failure EQUALS step-2:
    purge event 3a: The cascade MUST leave the retention as the cascade found the retention, Retained for a first run, a step-2 write that answered no answer and committed under the cascade's lease excepted (Audit Trail Capability requirement 13).
    purge event 3b: The cascade MUST NOT write an erasure outcome.
    purge event 3c: [Purge Eligible Events] MUST re-offer the event for as long as the retention EQUALS Retained.
purge event 3d: IF cascade-failure EQUALS in-flight THEN the cascade MUST write nothing.
purge event 3e: IF cascade-failure EQUALS in-flight THEN the cascade MUST leave the retention as found.
purge event 4: WHEN cascade-failure EQUALS step-2 OR cascade-failure EQUALS step-3:
    purge event 4a: The reconciliation scan MUST re-drive the entry.
    purge event 4b: The deployment MUST surface an open entry not under a hold as a compliance alert.
    NOTE: watch persistent state — the source says *until the scan closes it*; the duration is carried by the term open entry (purge event 4b), by *for the rest of the run* (Audit Trail Per-act critical section 5) and by *through the outage* (Audit Trail Composition-level invariant 1b).
purge event 5: WHEN Legal Hold EQUALS composed:
    purge event 5a: [Purge Event] MUST carry the under-legal-hold arm.
    purge event 5b: IF hold EXISTS THEN [Purge Event] MUST land under-legal-hold with no further cascade step executed.
    purge event 5c: [Purge Event] MUST read hold under the held critical section AFTER step 0.1a and BEFORE step 0.2.
    purge event 5d: IF a re-drive lands under-legal-hold THEN the retention, the destruction record and the content MUST stand as found.
    purge event 5e: IF the hold read does not return the holds THEN [Purge Event] MUST land cascade-failure(hold) with no cascade step executed.
    purge event 5f: IF the database name the hold read answers DOES NOT EQUAL the hold database name THEN [Purge Event] MUST read the read as one that does not return the holds (Legal Hold Instance 6, Legal Hold Instance 7).
purge event 6: IF Legal Hold DOES NOT EQUAL composed THEN [Purge Event] MUST NOT carry the under-legal-hold arm.
purge event 7: WHEN mid-cascade expiry EXISTS:
    purge event 7a: [Purge Event] MUST NOT issue a further write.
    purge event 7b: [Purge Event] MUST return cascade-failure(step) naming the first step not completed.
    purge event 7c: The reconciliation scan MUST re-drive the cascade.
purge event 7d: IF the lease expires BEFORE step 1 commits THEN [Purge Event] MUST NOT issue step 1 AND MUST land cascade-failure(step-1).
purge event 8: IF a read [Purge Event] issues at step 0, step 0½ or step 3 answers no answer AND no rule above names the arm THEN [Purge Event] MUST land cascade-failure naming the step AND MUST issue no further write, step 0 naming `seal`, step 0½ naming `step-1` and step 3 naming `step-3`.
```

Term hold: a Legal Hold preservation order whose hold state EQUALS active and whose record reference EQUALS the event id, read through Legal Hold's read (Legal Hold Operation 23) from the Legal Hold database instance wired to this instance.

Term mid-cascade expiry: the lease expiring after step 1 has committed and before step 3's outcome record has landed.

Term cascade-failure(step-3): a delegation not issued, an outcome not recorded, or a reported `destruction-failed(reason)` — three failures that, over an incomplete cascade, leave one record, retention *Purged* with no destroyed outcome: the content readable where no delegation was issued or the mechanism reported destruction-failed, and already destroyed where the mechanism destroyed and the outcome was not recorded; over a completed cascade, a repeat whose step 3 cannot read the destroyed outcome lands it too, its delegation not issued (purge event step 3.6, purge event 8), and the cascade stays complete.

Steps:

0. **Seal before purge.**
   ```
   purge event step 0.1: [Purge Event] step 0 MUST read the event through Audit Trail's read_record.
   purge event step 0.1a: IF Audit Trail's read_record answers not-known at step 0.1 THEN [Purge Event] MUST land not-known AND MUST NOT run step 0.2.
   purge event step 0.2: IF the audit record's coverage status IS unsealed tail THEN [Purge Event] step 0 MUST invoke Audit Trail's seal_now.
   purge event step 0.3: [Purge Event] MUST NOT run step 1 BEFORE the covering seal exists.
   purge event step 0.4: IF Audit Trail's seal_now rejects other than with Audit Trail's nothing-to-seal THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.5: IF the audit record's coverage status DOES NOT EQUAL unsealed tail THEN [Purge Event] step 0 MUST NOT invoke Audit Trail's seal_now.
   purge event step 0.6: [Purge Event] MUST NOT run step 0 BEFORE taking the per-act critical section keyed by event id, a [Purge Event] re-driven by the first half excepted (Cascade critical section 5).
   purge event step 0.7: IF another holder holds the critical section THEN [Purge Event] MUST land cascade-failure(in-flight), a [Purge Event] re-driven by the first half excepted (Cascade critical section 5).
   purge event step 0.8: IF Audit Trail's seal_now lands Audit Trail's nothing-to-seal THEN [Purge Event] step 0 MUST read the event again through Audit Trail's read_record and proceed ONLY IF a covering seal EXISTS.
   purge event step 0.10: IF the take at step 0.6 answers no answer THEN [Purge Event] MUST land cascade-failure(in-flight).
   purge event step 0.9: IF no covering seal EXISTS after Audit Trail's nothing-to-seal THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.12: IF Audit Trail's seal_now answers AND no covering seal EXISTS for the event THEN [Purge Event] MUST land cascade-failure(seal).
   purge event step 0.11: IF the read at step 0.1 answers no answer THEN [Purge Event] MUST land cascade-failure(seal) AND MUST NOT land not-known.
   ```
   An event more than slice cap events past sealed through is reached one slice a call: Audit Trail's seal_now seals at most slice cap events (Audit Trail seal now 1a), so the purge lands cascade-failure(seal) (purge event step 0.12) and stays on [Purge Eligible Events]'s list (purge event 3c) until a slice covers it, a wait the unsealed tail's depth sets and the deployment watches (Audit Trail Unsealed tail 1).

   **Step 0½ — retention must be resolved before the cascade proper begins.**
   ```
   purge event step 0½.1: [Purge Event] MUST NOT run step 0½ BEFORE step 0.
   purge event step 0½.2: IF the audit record carries retention status unresolved THEN [Purge Event] step 0½ MUST land retention-unresolved.
   purge event step 0½.3: A retention-unresolved refusal MUST run no cascade step.
   purge event step 0½.4: A retention-unresolved refusal MUST leave step 0's seal standing.
   purge event step 0½.5: The composition MUST NOT invent a retention in order to expire an event.
   purge event step 0½.6: IF the read of the audit record at step 0½ answers no answer THEN [Purge Event] step 0½ MUST land cascade-failure(step-1) AND MUST NOT land retention-unresolved AND MUST NOT land not-known.
   ```
1. **Record the destruction, before anything is destroyed.**
   ```
   purge event step 1.1: [Purge Event] step 1 MUST call Audit Trail's record_destruction with the event id.
   purge event step 1.2: [Purge Event] step 1 MUST land Audit Trail's retention-period-not-elapsed as [Not Eligible].
   purge event step 1.3: [Purge Event] step 1 MUST land Audit Trail's not-known as cascade-failure(step-1), the event standing in the log from step 0 (Audit Trail Invariant 8.5).
   purge event step 1.5: [Purge Event] step 1 MUST land Audit Trail's destruction-failure(step-1) as cascade-failure(step-1).
   purge event step 1.6: IF the call to Audit Trail's record_destruction answers no answer THEN [Purge Event] step 1 MUST land cascade-failure(step-2).
   purge event step 1.7: [Purge Event] step 1 MUST land Audit Trail's destruction-failure(step-2) as cascade-failure(step-2).
   ```
2. **The delegation waits for the destruction record.**
   ```
   purge event step 2.4: [Purge Event] MUST NOT issue the delegation BEFORE Audit Trail's record_destruction has answered ok.
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

```
Wiring decision 1: The composition MUST NOT destroy a record covered by an active hold under strict mode.
Wiring decision 2: The composition MUST destroy a record ONLY AFTER the gate read.
Wiring decision 3: The composition MUST record the hold check result on a destruction.
Wiring decision 4: The composition MUST record the hold check result on a refusal the gate fires.
Wiring decision 5: Legal Hold MUST NOT intercept Retention Window's purge.
Wiring decision 6: A purge MUST NOT release a hold the purge overrode.
Wiring decision 7: The composition MUST NOT compose a release reason for an overridden hold.
```

<details markdown="block">
<summary>WHY</summary>

*Principle:* Retention Window's own precondition prevents a premature purge and knows nothing of any hold; Legal Hold records a preservation obligation and intercepts nothing. Without the composition wiring the two checks together, a system can lawfully — from each atom's own perspective — destroy a record under an active litigation hold, which is a spoliation exposure structurally invisible to either atom alone.

*Likely objection:* why not have Legal Hold intercept `RetentionWindow.purge` directly, and skip the composition?

*Mechanism that resolves it:* Wiring decision 5 is the answer and it is about freestanding status rather than convenience. An atom that intercepted purge calls would have to know about retention records, storage layers and destruction mechanisms — absorbing concepts that belong to the composing layer. The atom records the obligation; the composition enforces it. Both constituents were written for this: [Legal Hold](../atoms/legal-hold.md)'s `Composition note 2` obliges a composing pattern to check a record's active holds at the purge surface, and [Retention Window](../atoms/retention-window.md)'s `Composition note 3` obliges one to own joint enforcement across retentions over one record. Both name this composition in their own words, and the *Legal hold suspension of purge* edge case, which moved here from [Audit Trail](./audit-trail.md) with the audit cascade, names it for the audit-event half of the gate (`Capability requirement 69`).

*Result:* the gate is structural under strict mode rather than a runtime check an operator can talk past inside this composition's surface — though not a gate a direct atom-level call cannot route around, which `Composition state 24` detects rather than prevents. Both halves of the gate's behaviour are provable: `hold_check_result: empty` on every non-override destruction, and a gate record naming the blocking holds on every refusal. On an advisory instance the [Hold Override] marker is the third reading — a destruction that proceeded past a hold the records still name.

</details>

*The cascade-on-purge rule.*

The cascade-on-purge rule, moved here from Audit Trail's wiring decision, is this composition's second load-bearing wiring decision: when an event's retention elapses, the composition first ensures the event is covered by a seal (purge event step 0.1 through 0.5), then has Audit Trail end the one record it is permitted to end — the Retention Window record — and write a destruction record adding the event's sequence number to the covering seal's purged events set and capturing the event's `(event_id, attestation_id)` binding before it is destroyed (purge event step 1.1; Audit Trail record destruction step 1.1 through 2.3), and delegates the shred of Event Log's data field and the attestation's proof to the deployment's erasure mechanism (purge event step 3.1 through 3.4). It coordinates the cascade and records the outcome; it destroys nothing itself (purge event step 3.2), disposes of no seal (Audit Trail Composes 16), and re-seals nothing (Audit Trail seal now 12).

<details markdown="block">
<summary>WHY</summary>

*Principle.* When a regulated record reaches the end of its lifetime, the records of all four constituents must reach a coherent end state together: no retained event without attribution or integrity coverage, and no destroyed event leaving a dangling attestation or a live content claim on a seal. Coordinating that across four constituents' records is work no constituent can do — each knows only its own record — so it belongs at the composition layer, with the honest record of what the coordination achieved.

*Likely objection.* Why not have the composition delete the content directly? It knows which event, which attestation and which seal are involved, and a cascade that ends in a delegation looks like one that does not finish.

*Mechanism that resolves it.* Two of the four constituents forbid it in their own invariant text, and a composition that overrode them would be silently substituting weaker atoms. Event Log declares only append and read, holds its Invariant 1 (append-only), and routes true deletion to a composing pattern in its *Erasure where law requires it* edge case. Actor Identity's Invariant 9 states that an attestation is never deleted by the atom, and its Composition note 4 gives an attestation's retention to the composing pattern. So the destruction surface is named where the atoms say it belongs — an Erasure Tombstone *(forthcoming)* composing pattern, or a shred at the storage layer, declared per deployment — and this composition wires the coordination around it.

*Result.* Four constituent invariants hold verbatim over their instances — Event Log's 1 and 2, Actor Identity's 9 and 1 — which is what makes Audit Trail Invariant 5 a literal claim; a lawfully destroyed event still answers `failed-verification(purged)` from its *Purged* record, still leaves a seal whose purged events names it, and still distinguishes lawful destruction from a missing record (Audit Trail Invariant 8).

</details>

#### Boundary one — only mechanisms that shred conform

The class boundary's home; erasure mechanism 1 through 9, [Purge Event] step 3, Audit Trail Invariant 5 and the [Purge Event] term entry cite it.

```
Boundary one 2: The composition MUST NOT condition RetentionWindow.purge's outcome on the erasure mechanism's answer.
Boundary one 3: The composition MUST record a divergence between a Purged retention and readable content.
Boundary one 4: The composition MUST surface a divergence as a compliance alert.
Boundary one 5: IF purge age EXCEEDS audit edge THEN an auditor MUST read a divergence as a residual finding against the erasure mechanism.
```

Term divergence: a retention in *Purged* over content still readable — `cascade-failure(step-3)`; a destruction-failed outcome in erasure outcomes.

### Reconciliation

Term destroyed event: an event whose payload the audit instance has destroyed. The log still answers the event's sequence number and recording instant, and Audit Trail's read answers the attestation's action reference (Audit Trail read record step 4.4a).

Term stand-in: a destroyed event that may be the missing half of a pairing, answering an action reference the missing record could carry. For an intent that carries no outcome it is a destroyed event later in the log. For an outcome that carries no intent it is a destroyed event earlier in the log whose recording instant stands within the horizon margin of the outcome's own, since an invocation's intent and outcome land under one grant of the record section (Term horizon margin). The invocation id went with the payload, so the trail cannot say whether the missing record was written; a pairing with a stand-in reads unknown and never open, orphaned or failed.

Term aged-out event: an event whose age — the injected now less the event's `recorded_at` — exceeds the payload horizon. No clock decides the edge alone: an intent short of the edge whose outcome the audit instance has already destroyed carries a stand-in (Term stand-in).

Term log order: the order of the substrate's sequence numbers. Wherever a rule or a term of this composition says an event is earlier, later, the next or the latest, it means in log order and never by an instant an event carries: two seams' instants may stand an allowance apart, and the record section is what orders two acts over one record.

#### First half — the half-completed cascade

*First half — the half-completed cascade.*

```
First half 1: The first half MUST enumerate Purged retentions through Retention Window's declared read over the audit retention instance (Composes 19).
First half 2: IF purge edge EXCEEDS purge age THEN the first half MUST NOT examine the retention.
First half 3: The first half MUST test EVERY examined retention for the coverage status records-purged on Audit Trail's read_record, which stands only where the covering seal's purged events carry the event's sequence number and the destruction record's pair stands with the sequence number (Term destruction record, Composes 23), and for a destroyed outcome in erasure outcomes.
First half 5: The first half MUST re-drive a retention failing First half 3 through [Purge Event].
First half 6: The first half MUST NOT re-read the predicate BEFORE taking the critical section keyed by event id.
First half 7: The first half MUST NOT write BEFORE re-reading the predicate under the critical section.
First half 9: IF a re-drive lands under-legal-hold THEN the first half MUST leave the entry open and MUST NOT count the entry against Audit Trail's compensation window.
First half 10: The first half MUST re-drive an entry left open under a hold on the first run after the hold is released.
First half 11: IF a hold over an open entry is released THEN the first half MUST count the entry's Audit Trail compensation window from the instant of the first run that reads no active hold over the event, AND MUST NOT count the window from a release instant the Legal Hold records carry, which a caller may have supplied and backdated (Legal Hold Operation 39, Operation 18).
First half 12: The first half MUST take as upper edge the retention policy of the audit instance the first half reads, under which the Purged retention (Retention Window Invariant 10.1), the seal record (Audit Trail retention policy 5), the destruction record and the erasure outcome (Execution Contract Database 3, Execution Contract Database 4) stand indefinitely.
First half 13: The first half MUST NOT record an audit.reconciliation event.
First half 14: IF purge age EXCEEDS audit edge THEN the first half MUST NOT re-drive the retention AND MUST surface the retention as a residual finding against the erasure mechanism, a suspended entry excepted (Boundary one 5, Check 8.12).
```

Term suspended entry: an open entry a run landed under-legal-hold, from that run until a later run reads no active hold over the event — the entry First half 9 leaves uncounted and Invariant 12.1 restarts.


Term purge edge: `(purge_completion_bound + clock_offset_allowance)` — Audit Trail's purge completion bound and Audit Trail's clock offset allowance, the allowance Audit Trail's Term audit edge adds to its own window span, never this composition's seam offset allowance.

Term purge age: `(now - purged_at)`.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Hold-blocks-purge.**
  ```
  Invariant 1.1: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN the composition MUST NOT call Retention Window's purge.
  Invariant 1.2: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN a purge MUST NOT answer ok.
  Invariant 1.3: The composition MUST NOT read unreadable hold records as an empty hold check result.
  Invariant 1.5: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN a purge MUST NOT answer not-eligible.
  Invariant 1.6: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN a purge MUST NOT answer under-active-retention.
  ```
- **Invariant 2 — Retention coverage.**
  ```
  Invariant 2.1: EVERY record a committed placement covered MUST carry a retention whose retention state EQUALS EXACTLY ONE OF retained, purged.
  Invariant 2.2: The composition MUST NOT gate a record no committed placement covered.
  ```
- **Invariant 3 — Hold audit coverage.**
  ```
  Invariant 3.1: EVERY committed hold placement that stands within the payload horizon MUST carry a hold placed outcome.
  Invariant 3.2: EVERY committed hold release that stands within the payload horizon MUST carry a hold released outcome.
  Invariant 3.3: A hold placed outcome MUST carry the hold id, the record reference AND the placing actor.
  Invariant 3.4: The composition MUST NOT claim a hold lifecycle reconstructible from an aged-out event.
  Invariant 3.5: The composition MUST NOT claim a tamper-evidence over the substrate's unsealed tail.
  ```
- **Invariant 4 — Retention-decision audit coverage.**
  ```
  Invariant 4.1: EVERY committed placement that stands within the payload horizon MUST carry a retention placed outcome.
  Invariant 4.2: EVERY committed purge that stands within the payload horizon MUST carry a record purged outcome.
  Invariant 4.3: EVERY [Purge Record] that answered under-legal-hold MUST carry a gate record.
  Invariant 4.4: A record purged outcome MUST carry the hold check result.
  Invariant 4.5: A gate record MUST carry the blocking hold ids AND the blocking count.
  Invariant 4.6: The composition MUST NOT record an outcome for a refusal no intent preceded.
  ```
- **Invariant 5 — Audit completeness modulo the substrate's partial-attestation contract.**
  ```
  Invariant 5.1: EVERY outcome MUST follow an intent carrying the outcome's invocation id.
  Invariant 5.4: A gate record MUST NOT follow an intent.
  Invariant 5.5: EVERY admitted placement, admitted hold placement, admitted hold release AND admitted purge MUST record EXACTLY ONE intent.
  Invariant 5.6: An admitted placement, admitted hold placement, admitted hold release AND admitted purge MUST NOT record two outcomes.
  Invariant 5.7: EVERY intent carrying no stand-in MUST carry EXACTLY ONE outcome, an aged-out event AND a destroyed event excepted.
  ```
- **Invariant 6 — Non-retroactivity of holds.**
  ```
  Invariant 6.1: A post-destruction hold MUST NOT change the destroyed record's retention.
  Invariant 6.2: A post-destruction hold MUST NOT remove the record purged outcome.
  Invariant 6.3: A reader MUST decide a hold's order against a destruction by the log position of the hold placed outcome's own intent against the destruction's purge intent.
  Invariant 6.4: A reader MUST NOT decide a hold's order against a destruction by placement instant.
  Invariant 6.5: A reader MUST decide a release's order against a destruction by the log position of the hold released outcome's own intent against the destruction's purge intent.
  Invariant 6.6: A reader MUST NOT decide a release's order against a destruction by release instant.
  ```
- **Invariant 7 — Multi-hold independence.**
  ```
  Invariant 7.1: IF an active hold covers the record THEN a release MUST NOT make the record purge-eligible.
  Invariant 7.2: [Purge Eligible] MUST answer a record carrying an active hold as hold-blocked.
  Invariant 7.3: [Purge Eligible] MUST answer a record carrying the unavailable sentinel as hold-blocked.
  ```
- **Invariant 8 — Defensible destruction.**
  ```
  Invariant 8.1: EVERY surviving destruction MUST carry a record purged outcome naming the hold check result.
  Invariant 8.2: EVERY destroyed record MUST carry a retention whose retention state EQUALS purged.
  Invariant 8.3: A destroyed record's retention deadline MUST NOT EXCEED the retention's purge instant.
  Invariant 8.4: A record purged outcome MUST carry a seal ONLY AFTER the cadence coverage.
  Invariant 8.5: A reader MUST read an unverifiable partially-purged-coverage answer as unknown.
  Invariant 8.6: The composition MUST NOT claim a defensibility resting on an aged-out event.
  ```
- **Invariant 9 — Cross-retention joint enforcement.**
  ```
  Invariant 9.1: IF the sibling set carries a retention outside elapsed retention THEN the composition MUST NOT destroy the record.
  Invariant 9.3: The composition MUST NOT leave a sibling retained over a destroyed record.
  Invariant 9.5: The gate MUST NOT rest on the payload horizon.
  ```
- **Invariant 10 — Authentication precedes destruction and commitment.**
  ```
  Invariant 10.1: The composition MUST NOT make a committing call BEFORE the caller's credential validates.
  Invariant 10.2: The composition MUST NOT destroy a record BEFORE the caller's credential validates.
  Invariant 10.3: The composition MUST NOT claim a presenter stands as the actor.
  Invariant 10.4: The composition MUST NOT claim a presentation binds to a channel.
  Invariant 10.5: The composition MUST NOT claim a presentation resists a replay.
  ```

- **Invariant 11 — Cascade coordination on purge.**
  ```
  Invariant 11.1: The cascade MUST commit step 3's outcome record AFTER the delegation.
  Invariant 11.2: The composition MUST NOT claim an atomic set spanning the retention transition and the delegated destruction.
  Invariant 11.3: An auditor MUST clear the delegated destruction's completion outside the records.
  ```
  *Rests on:* Audit Trail's record_destruction and [Purge Event] steps 0–4, defended by the cascade-on-purge rule; Audit Trail Invariant 4.2, which commits the transition and the destruction record together; Retention Window Invariants 3 (terminal absorption), 7 (no early purge) and 8 (purge timestamp consistency); Tamper Evidence Invariant 1; Event Log Invariant 1 and Actor Identity Invariant 9, which are what make the delegation necessary rather than optional.

- **Invariant 12 — A hold over an open cascade entry.**
  ```
  Invariant 12.1: IF a run has landed an open cascade entry under-legal-hold (First half 9) AND a later run reads no active hold over the event THEN the entry's Audit Trail compensation window MUST restart at that later run's instant (First half 11).
  Invariant 12.2: IF a run has landed an open cascade entry under-legal-hold AND a later run reads no active hold over the event THEN the deployment MUST record the instant of EVERY run that landed the entry under-legal-hold and the instant of the later run, in the outage record.
  Invariant 12.3: IF a run has landed an open cascade entry under-legal-hold AND a later run reads no active hold over the event THEN an entry no run landed under-legal-hold MUST NOT restart.
  ```

- **Invariant 13 — Honest representation of a destroyed audit event.**
  ```
  Invariant 13.1: A lawfully destroyed event MUST carry a retention record in Purged with purge instant, the sequence number in the covering seal's purged events, the pair in the destruction record, and a destroyed outcome in erasure outcomes.
  ```

  *Rests on:* [Purge Event] steps 0, 1 and 4; Audit Trail Invariant 8, whose three standings (retained, lawfully destroyed, held) this invariant completes for a destroyed event; Retention Window Invariants 1, 3 and 10.

---

## Examples

### Walkthrough — regulated bank under SOX section 802 and FRCP Rule 37(e)

A multinational bank governs its general-ledger transaction records with this instance. The deployment sets `hold_check_mode = strict` and configures the audit instance with a twelve-year policy against a seven-year business policy, a longest hold of four years and a purge delay of thirty days, so the evidence floor sits inside the payload horizon.

1. **Retention placed.** `place_record_under_retention("txn-2026-0441", "sox_7_year", "records_system", credential)`. The boundary predicate passes; a retention_placement_intended record lands carrying `invocation_id: inv-a1`, the two references and intent instant; `RetentionWindow.place_under_retention` answers `ret-0441` with `retention_until = 2033-05-10`; a retention_placed outcome lands carrying `inv-a1`, `ret-0441`, the record reference, the policy reference and both deadlines. Returns `ret-0441`.

2. **Litigation anticipated.** Three years later: `place_hold("txn-2026-0441", "counsel_morgan", credential, "Litigation hold — anticipated class action re Q3 2026 operations", "matter-2029-morgan")`. Intent, then `LegalHold.place` answering `hold-0441-a`, then the hold_placed outcome carrying the hold id, the record reference, the placing actor, the reason, the case reference and the placement instant. Returns `hold-0441-a`.

3. **Retention window elapses.** In 2033 `purge_eligible()` answers `ret-0441` with `hold_count = 1` — hold-blocked, not purge-ready. A records-management job calls `purge_record("ret-0441", "records_system", credential)` anyway. The sibling set is empty; the gate reads one active hold; the mode is strict, so a purge_blocked_by_hold gate record lands carrying `inv-b7`, the retention, the record and `{hold_ids: ["hold-0441-a"], count: 1}`, and the call answers `under-legal-hold(["hold-0441-a"], 1)`. **No intent record is written on this path** — the gate record precedes it and verifies the same credential — and nothing is destroyed.

4. **Litigation settles.** `release_hold("hold-0441-a", "counsel_morgan", credential, "Class action settled — May 2033")`. The pre-intent read finds the hold active; intent, `LegalHold.release`, hold_released outcome carrying the hold id, the reason and the release instant. Returns released.

5. **Purge proceeds.** `purge_eligible()` now answers `ret-0441` with `hold_count = 0`. `purge_record("ret-0441", "records_system", credential)`: the sibling set is empty, the gate reads no active hold, the named retention is elapsed, a purge_intended record lands carrying `inv-c2`, `RetentionWindow.purge` stands `ret-0441` purged, and a record_purged outcome lands carrying `inv-c2`, `ret-0441`, the record reference, `purged_retention_ids: [{ret-0441, purged}]`, `hold_check_result: empty`, `hold_override: false` and `purge_instant: 2033-05-15`, the three committing together; the two index entries are removed; then the record destruction pattern destroys the record. Returns ok.

6. **SOX section 404 audit.** The auditor walks `Check 1.1` through `Check 7.3` over the trail and the two constituent records. The full arc reads: placement intent, placement, hold intent, hold, blocked purge, release intent, release, purge intent, purge. `verify_record` answers `verified` on each outcome the seal cadence covers. The auditor confirms that no destruction occurred while the hold was active, that the destruction landed inside the allowable window — retention deadline at or before `purged_at`, and `purged_at` below purge deadline — and that every act was attributed to a named actor whose credential the substrate verified before the act committed.

### A sibling retention blocks, then travels with the destruction

The same record acquires a second retention in 2030 under a policy transition: `place_record_under_retention("txn-2026-0441", "ledger_6_year", "records_system", credential)` → `ret-0441-b`, `retention_until = 2036-05-10`. In 2033, with the hold released, `purge_record("ret-0441", …)` reads the sibling set from Retention Window's records, finds `ret-0441-b` outside elapsed retention, and answers under-active-retention — nothing destroyed, no intent written. In 2036 the same call finds both elapsed, destroys the record once, purges `ret-0441-b` in the same invocation, and records `purged_retention_ids: [{ret-0441, purged}, {ret-0441-b, purged}]`. Had the second purge answered storage-failure, the call would commit nothing and answer storage-failure, the record would stand, and the caller would retry (Action wiring 68, Action wiring 82).

### The substrate refuses — a recording failure

On the bank's instance, `purge_record("ret-0441", "records_system", credential)` is called while the audit instance's database is down. The boundary predicate passes, the take of the record section is granted, the sibling set is empty and the gate reads no active hold. The purge intent's record_action answers state-unavailable, which the composition reads as a recording-failure carrying step-2 (Audit arm 23); the record start floor admits one further call, so the composition retries once (Audit arm 1) and the answer is the same, and with no further call admitted it reads the intent as an owed record (Audit arm 17), commits nothing, releases the record section and answers `recording-failure(intent)` (Action wiring 83). `RetentionWindow.purge` was never called, `ret-0441` stands retained and the trail carries no purge intent. The job's next call, once the database answers, meets the same state.

### The record section is taken — section-unavailable

A second records-management job calls `purge_record("ret-0441", ...)` while the first holds the record section over `txn-2026-0441`. Its try_take answers held (Concurrency 12): the action answers section-unavailable, writes nothing and makes no gate read (Concurrency 6). The caller retries after the first act has released the section; if the first act purged `ret-0441`, the retry's answer is not-known, which the caller reads as a committed destruction (Action wiring 73).

### Banking — concurrent regulatory investigations under SOX

A bank faces simultaneous DOJ (US Department of Justice) criminal and SEC civil enforcement, and both demand preservation of the same trading records. Two independent hold sets are placed under `case_ref: "doj-crim-2026-0011"` and `case_ref: "sec-enf-2026-0087"`. When DOJ closes, every `hold-doj-*` hold is released; `purge_eligible()` still answers the records hold-blocked with `hold_count = 1`, because `Invariant 7.1` makes releasing a subset no release at all. Only when the SEC holds are released do the records become purge-ready.

### Healthcare — HIPAA section 164.530(j) records under HHS OCR investigation

HHS (the US Department of Health and Human Services) and its OCR (Office for Civil Rights, which enforces HIPAA) open a breach investigation while a hospital's patient encounter records sit under a six-year retention policy. Compliance places holds under `case_ref: "ocr-hipaa-inv-2026-0334"`. The six-year windows elapse during the investigation and `purge_eligible()` answers the affected records hold-blocked throughout. After the investigation closes, the holds are released and the records are purged in the next run. Each record's trail reads placement, hold, release, destruction — the arc an OCR auditor reads to confirm the preservation obligation was honoured.

### Broker-dealer — SEC Rule 17a-4 non-erasable records under FINRA examination

A broker-dealer places all business communications under a seven-year policy per SEC Rule 17a-4. A FINRA (Financial Industry Regulatory Authority) examination is announced and holds are placed on every in-scope record under `case_ref: "finra-exam-2026-0112"`. No in-scope record is purged during the examination. Afterwards the holds are released and the elapsed records are destroyed. The Tamper Evidence seal reached through the substrate is the write-once-read-many equivalent the rule's integrity requirement asks for, and the gate is what satisfies its non-premature-destruction half.

### E-discovery — FRCP Rule 37(e) preservation duty, disputed destruction

Opposing counsel moves for sanctions under FRCP Rule 37(e), claiming ESI (electronically stored information) was destroyed after the preservation duty arose. The defence reads every record_purged outcome in the disputed scope. Each either carries a `purge_instant` predating the duty's trigger date, or carries `hold_check_result: empty` with no hold over that record standing unreleased where the destruction's purge intent sits in the log, or carries a non-empty hold check result with `hold_override: true` (Check 1.2). Where a hold was placed before a destruction and stood unreleased at its purge intent, the log carries the hold's placement intent ahead of the purge intent (Invariant 6.3), and `purge_eligible()` at that time would have answered the record hold-blocked. `Check 1.3` and `Check 1.4` are the two the defence runs, and the spoliation question's answer is provable.

### Advisory-mode override — court-ordered destruction superseding a hold

A pharmaceutical company keeps its general email population under an FRCP-exposed instance configured strict, which is never reconfigured. A federal court orders destruction of records containing trade-secret formulations of a discontinued product line, which an internal review's hold — no litigation duty, and so outside `Capability requirement 27` — still covers. Because the mode is one instance-wide value (`Capability requirement 25`), that population is handled the way `Capability requirement 30` prescribes: the product line's records were placed from the start under a second, disjoint instance deployed with `hold_check_mode = advisory`.

For each in-scope record, `purge_record(retention_id, "counsel_walsh", credential)` reads a non-empty hold check result, proceeds under advisory mode, destroys the record, and records a record_purged outcome carrying `hold_check_result: {hold_ids: [...], count: 1}` and `hold_override: true`. The blocking hold stays active: the composition does not release it (`Wiring decision 6`), because the court order settled one record's fate without ending the review. The dashboard surfaces the discrepancy — an active hold over a destroyed record — and counsel decides separately whether to release.

The override's authorization is not in these records. `hold_override: true` makes it provable that an override happened; `External check 4` is where an auditor goes for the order behind it, because `Capability requirement 33` keeps this layer from holding a datum it cannot verify. That is the only configuration in which advisory mode is appropriate: a dedicated instance, a disjoint population, and an external authority that can produce written authorization per override.

### GDPR Article 17 collision — erasure request against a hold

A data subject in the EU invokes the GDPR (EU General Data Protection Regulation) Article 17 right to erasure. Before executing, the system asks this composition, and there are four answers rather than three.

If the hold check answers non-empty, the erasure is deferred: Article 17(3)(e) exempts data necessary for the establishment, exercise or defence of legal claims, and the active hold is the operational record establishing the exception. If no hold is active and the named retention is outside elapsed retention, the record is under a live retention obligation — Article 17(3)(b)'s legal-obligation ground — and purge_record answers not-eligible. If no hold is active, the named retention is elapsed and a **sibling** is not, purge_record answers under-active-retention: a longer obligation over the same record survives the shorter one, which is the branch a request scoped to one retention most easily misses. Only when no hold is active and every retention over the record is elapsed does the destruction proceed.

In all four branches the trail is the evidence of what the system decided and on what ground. The composition does not adjudicate the legal question; it records the state of the atoms at decision time.

### Regulated adversarial scenarios

**Regulator audit — *prove no record under hold was destroyed during the examination window*.** An SEC examiner reads every record_purged outcome in the period and confirms `hold_check_result: empty` on each (`Check 1.1`). The examiner then builds the historical hold set — Legal Hold's read unfiltered by state, so a hold released *after* an improper destruction is still visible, less any hold whose placement intent sits later in the log than the purge's intent (`Check 1.4`) and any released before it (`Check 1.8`) — and confirms the set is empty (`Check 1.3`). A current-state read would not do: the release-after-destruction sequence is precisely the spoliating history the check exists to catch.

**Disputed destruction — the data subject challenges a deferral.** A subject's representative asks whether there was really a hold. Legal Hold's read answers the active hold with placing actor, `hold_reason`, placement instant and case reference, immutable under Legal Hold Invariant 1, and the deferral's trail entry names the hold id. `verify_record` confirms the entry is unaltered. Legal Hold Invariant 7 is why the hold cannot have been placed anonymously. Sustaining the challenge would require claiming the whole hold records were fabricated, at which point the seal reached through the substrate is the structural rebuttal.

**Breach forensics — *was a preservation-deferred record improperly destroyed?*** The team reads the trail for record_purged outcomes naming the suspect record. None means the record was not destroyed through this composition, and the investigation moves to direct atom-level or storage-layer access — the bypass case `Check 3.4` signals. One means the `hold_check_result` and the historical hold predicate answer the question directly. The forensic window is bounded by the seal cadence below and by the payload horizon above, and `Invariant 8.6` is where that bound is stated rather than assumed.

### Walkthrough — the audit cascade

A bank's audit trail ([Audit Trail](./audit-trail.md)) holds `e9301`, covered by the seal `s127` over `[8302 .. 9301]`, with the retention `r9301` in *Retained* and the pair `(e9301, a44)` readable from the attestation records. Legal Hold is composed over the audit instance, and no hold stands over `e9301`.

1. **Seven years and one month later.** [Purge Eligible Events] runs nightly and `e9301` is on the list. `purge_event(e9301)`: step 0 reads the event through Audit Trail's `read_record`, finds the coverage status covered, so `s127` covers it and `seal_now` is not invoked; the hold read finds none.
2. **Step 1.** `record_destruction(e9301)`: `RetentionWindow.purge(r9301)` moves the retention to *Purged* with `purged_at = 2033-06-14`; `9301` joins `s127`'s purged events — just that one number, since the other 999 members are under their own retentions — and the same transaction captures the pair `(e9301, a44)` before anything is destroyed.
3. **Step 3.** Destruction of Event Log's data field for `e9301` and of `a44`'s proof goes to the erasure mechanism, which shreds both and reports destroyed; the outcome is recorded in erasure outcomes and the cascade completes. Had it reported `destruction-failed(...)`, the cascade would have rejected `cascade-failure(step-3)` and the first half would have re-driven the entry each cycle until a destroyed outcome landed, `r9301` standing as a surfaced alert meanwhile.

### Walkthrough — the audit cascade, rejected

**not-eligible — a purge attempted before the window elapses.** In 2030 a records-management job misconfigured with a five-year policy calls `purge_event(e9301)`.

1. Step 0 finds `e9301` covered by `s127`, step 0½ resolves `r9301`, and step 1 calls `record_destruction(e9301)`, which calls `RetentionWindow.purge(r9301)`.
2. Retention Window evaluates its no-early-purge guard against its own now: `2030-06-14 < 2033-05-10`. It refuses with retention-period-not-elapsed, writing nothing (Retention Window Invariant 7), and Audit Trail passes the refusal through.
3. The composition returns not-eligible. The cascade stops at step 1: nothing joins `s127`'s purged events, no delegation is issued, `r9301` stays *Retained*, and Audit Trail's `verify_record(e9301, ...)` still returns `verified`.
4. The gate is structural: the composition does not evaluate eligibility itself, and the atom's guard is a precondition on its own state.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the two indexes, the hold records, the business retention instance and the substrate's trail.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY record purged outcome carrying an empty hold check result under strict mode (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY record purged outcome carrying a non-empty hold check result carrying the hold override (Action wiring 55).
Check 1.3: An auditor MUST find EVERY member of a destruction's historical hold set named in the destruction's hold check result, a truncated result read PER Check 1.9 (Invariant 1.1).
Check 1.4: An auditor MUST read a post-destruction hold as outside the historical hold set (Invariant 6.3).
Check 1.5: An auditor MUST find EVERY gate record carrying a non-empty hold check result (Invariant 4.5).
Check 1.6: An auditor MUST find EVERY hold a gate record names in the hold records, released by no release whose own intent sits earlier in the log than the gate record (Action wiring 48, Invariant 4.5).
Check 1.7: An auditor MUST read Legal Hold's read unfiltered by hold state for the historical hold set (Invariant 6.3).
Check 1.8: An auditor MUST read a pre-destruction release as outside the historical hold set (Invariant 6.5).
Check 1.9: An auditor MUST read a truncated hold check result's count as naming the members the list omits (Primitive policy 21).
Check 1.10: An auditor MUST read an aged-out hold as unknown for Check 1.3 (Invariant 3.4).
Check 1.12: An auditor MUST find the retention of a destroyed record unchanged by a post-destruction hold (Invariant 6.1).
Check 1.13: An auditor MUST find the record purged outcome of a destruction standing beside a post-destruction hold (Invariant 6.2).
Check 2.1: An auditor MUST find a hold placed outcome PER hold whose placement stands within the payload horizon (Invariant 3.1).
Check 2.2: An auditor MUST find a hold released outcome PER released hold whose release stands within the payload horizon (Invariant 3.2).
Check 2.4: An auditor MUST read an aged-out hold as covered by the count of surviving attestations alone (Invariant 3.1, Invariant 3.4).
Check 2.5: An auditor MUST find Audit Trail's verify_record answering verified PER outcome the seal cadence covers, an outcome Check 2.6 covers AND an outcome Check 2.7 covers excepted (Invariant 3.5).
Check 2.6: An auditor MUST read a failed-verification carrying purged as a lawful destruction (Invariant 3.4).
Check 2.7: An auditor MUST read an unverifiable partially-purged-coverage answer as unknown (Invariant 8.5).
Check 2.8: An auditor MUST find [Purge Eligible] answering a retention over a record carrying an active hold as hold-blocked (Invariant 7.2).
Check 2.9: An auditor MUST find [Purge Eligible] answering a retention over a record whose hold read was refused as hold-blocked (Invariant 7.3).
Check 2.10: An auditor MUST find a record still carrying an active hold after a release answered as hold-blocked, never purge-eligible (Invariant 7.1).
Check 3.1: An auditor MUST find a retention placed outcome PER retention whose placement stands within the payload horizon (Invariant 4.1).
Check 3.2: An auditor MUST find a record purged outcome naming EVERY purged retention over a surviving destruction (Invariant 4.2).
Check 3.4: An auditor MUST read a purged retention over a surviving destruction that carries no record purged outcome as a bypass finding (Composition state 24).
Check 3.5: An auditor MUST read a retained retention over a destroyed record as a conformance failure (Invariant 9.3).
Check 3.6: An auditor MUST select a retention a committed placement covered PER the rebuild (Composition state 12).
Check 3.8: An auditor MUST find EVERY record a committed placement covered carrying a retention whose retention state EQUALS retained or purged (Invariant 2.1).
Check 3.9: An auditor MUST find no gate record over a record no committed placement covered (Invariant 2.2).
Check 3.10: An auditor MUST find EVERY destroyed record carrying a retention whose retention state EQUALS purged (Invariant 8.2).
Check 3.7: An auditor MUST find no retention over a destroyed record carrying a retention deadline the destruction's purge instant does not reach (Invariant 8.3).
Check 4.1: An auditor MUST reconstruct a retention's lifecycle from the retention placed outcome, the hold outcomes AND the record purged outcome (Invariant 8.1).
Check 4.2: An auditor MUST join a hold to a retention by the record reference (Composition state 29).
Check 5.1: An auditor MUST find an intent preceding EVERY outcome in the substrate's own sequence (Invariant 5.1).
Check 5.2: An auditor MUST find an outcome's intent carrying the outcome's invocation id (Invariant 5.1).
Check 5.3: An auditor MUST find the intent of EVERY outcome a calling actor attested carrying the outcome's actor reference (Composes 15).
Check 5.4: An auditor MUST read an outcome carrying no intent AND no stand-in as a conformance failure (Invariant 5.1).
Check 5.5: An auditor MUST read an intent carrying no outcome AND no stand-in as a conformance failure (Invariant 5.7).
Check 5.6: An auditor MUST read a gate record carrying no intent as conformant (Invariant 5.4).
Check 5.7: An auditor MUST find no two outcomes sharing one invocation id (Invariant 5.6).
Check 5.10: An auditor MUST find no two intents sharing one invocation id (Invariant 5.5, Capability requirement 63).
Check 5.11: An auditor MUST find, for EVERY outcome, the intent the substrate attested under the caller's credential ahead of the outcome in the log (Invariant 10.1, Invariant 10.2, Audit arm 7).
Check 6.1: An auditor MUST find the evidence floor not exceeding the payload horizon (Capability requirement 11).
Check 6.2: An auditor MUST find the rebuild reading Retention Window's records for an entry a purged placement event covers (Composition state 13).
Check 6.3: An auditor MUST read an payload horizon below the evidence floor as a conformance failure (Capability requirement 11).
Check 6.4: An auditor MUST read a record missing from the trail whose act does not stand within the payload horizon as unknown (Invariant 8.6).
Check 6.5: An auditor MUST read an outcome carrying no intent AND a stand-in as unknown for Check 5.1 through 5.3 (Invariant 8.6).
Check 6.6: An auditor MUST read an intent carrying no outcome AND a stand-in as unknown (Invariant 8.6).
Check 6.7: An auditor MUST read a hold's order against a destruction whose purge intent the trail does not carry as unknown for Check 1.3, Check 1.4 AND Check 1.8 (Invariant 8.6).
Check 6.9: An auditor MUST read a hold's order against a destruction as unknown for Check 1.3, Check 1.4 AND Check 1.8 where the trail does not carry the intent of the hold's own outcome (Invariant 8.6).
Check 6.10: IF the deployment admits no unbounded hold THEN an auditor MUST read a hold whose life EXCEEDS the longest hold the deployment declared as a conformance failure (Capability requirement 78).
Check 7.1: An auditor MUST clear Legal Hold's own acceptance over the hold records (Composes 5).
Check 7.2: An auditor MUST clear Retention Window's own acceptance over the business retention instance (Composes 5).
Check 7.3: An auditor MUST clear Audit Trail's own acceptance over the audit instance (Composes 6).
Check 7.4: An auditor MUST clear Lease's own holder-side acceptance over the record section, Lease Check 7.1 through 7.8, and Lease Check 8.1 over the parties the composition writes to (Capability requirement 37, Capability requirement 54, Concurrency 14).
Check 8.1: An auditor MUST confirm, for EVERY purged event that is not held and whose cascade is quiescent (Audit Trail Term quiescence), that failed-verification(purged) is backed by the records of Check 8.2 through 8.8.
Check 8.2: An auditor MUST confirm the retention record in Purged.
Check 8.3: An auditor MUST confirm the event's own sequence number in the covering seal's purged events.
Check 8.4: An auditor MUST read a purged event with no covering entry as a conformance failure.
Check 8.5: An auditor MUST confirm the pair in the destruction record.
Check 8.6: An auditor MUST confirm the attestation the pair names exists with readable surviving fields.
Check 8.7: An auditor MUST read a mechanism that destroyed more than the data field and the proof as non-conforming.
Check 8.8: An auditor MUST confirm a destroyed outcome recorded for the event in erasure outcomes.
Check 8.9: An auditor MUST NOT read a destruction-failed record as completion.
Check 8.10: An auditor MUST confirm [Purge Event] over an event with no retention record returns retention-unresolved.
Check 8.11: An auditor MUST read a member of a covering seal's purged events whose retention state EQUALS Retained as a conformance failure (Audit Trail Invariant 4.5).
Check 8.12: IF purge age EXCEEDS audit edge THEN an auditor MUST read a divergence as a residual finding against the deployment's erasure mechanism (Boundary one 5, erasure mechanism 10).
Check 8.13: An auditor MUST confirm event to attestation's entry for EVERY purged event that is not held and whose cascade is quiescent (Audit Trail Term quiescence) is present in the destruction record.
Check 8.14: An auditor MUST read a purged event that is not held and whose cascade is quiescent (Audit Trail Term quiescence), with no destruction-record pair, as a conformance failure.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the business retention durations confirmed MUST read the deployment's own policy register (Capability requirement 11).
External check 2: An auditor needing a retention policy's correctness confirmed MUST read the deployment's own regulatory obligations (Capability requirement 31).
External check 3: An auditor needing a hold's authority confirmed MUST read the deployment's own permissions surface (Non-goal 13).
External check 4: An auditor needing an override's authorization confirmed MUST read the deployment's own authorization documentation (Capability requirement 33).
External check 6: An auditor needing a declared setting confirmed MUST read the deployment's own declaration (Capability requirement 10, Capability requirement 12, Capability requirement 14 through 16, Capability requirement 22, Capability requirement 24, Capability requirement 25, Capability requirement 27 through 30, Capability requirement 36, Capability requirement 38 through 43, Capability requirement 57, Capability requirement 59, Capability requirement 60, Capability requirement 62, Capability requirement 64, Capability requirement 73, Capability requirement 76, Capability requirement 77, Capability requirement 81, Capability requirement 82, Capability requirement 84).
External check 7: An auditor needing the serialization confirmed MUST read the deployment's own Lease host (Capability requirement 37).
External check 8: An auditor needing a record's fate under a record purged outcome confirmed MUST read the deployment's own destruction confirmations (Capability requirement 55).
External check 9: An auditor needing the single surface confirmed MUST read the deployment's own access control over the hold records and the business retention instance (Capability requirement 45 through 47, Capability requirement 53).
External check 10: An auditor needing the section call pause bound confirmed MUST read the deployment's own constituent clients (Capability requirement 38, Capability requirement 54, Capability requirement 79).
External check 11: An auditor needing the hold database name confirmed MUST read the deployment's own declaration (Capability requirement 48).
External check 13: An auditor needing the alerting surface confirmed MUST read the deployment's own alert records (Capability requirement 13, Capability requirement 50, Capability requirement 84, Non-goal 23).
External check 15: An auditor MUST clear from external evidence that the erasure mechanism was authorized to destroy, shreds, and completed each destruction.
External check 16: IF Legal Hold EQUALS composed THEN an auditor MUST clear from the deployment's own concurrency control that a hold placement over an event id and a cascade on that event id serialize, the placement a bounded holder of the section, that no hold over an event id of this instance is placed outside the hold placement, and that the placement gate bounds the hold placements over an open entry to one displacement of the entry's first-half leg WITHIN compensation window of the finding's creation (Capability requirement 69a, 69b, 69c, 69d, 69e, 69g, 69i, Non-goal 22).
External check 17: An auditor MUST clear from the deployment's own lock that the cascade's critical section is a lease of the act's completion bound, a [Purge Event] re-driven by the first half excepted, and for a hold placement, shared by every process serving the instance, keyed by the event id namespaced by the act's kind, held under a holder value minted fresh for each attempt, and not released early by an abandoned call (Audit Trail Per-act critical section 1, 1a, 1b, 1c, Cascade critical section 1, 4a, 5).
External check 18: An auditor MUST clear from the deployment's own sweep that the purge sweep calls [Purge Event] over the eligible list (purge eligible events 8).
External check 19: An auditor needing the release of a hold the deployment's own authority overrode confirmed MUST read the deployment's own release records (Composition note 8).
External check 20: An auditor needing an active hold over a destroyed record confirmed surfaced MUST read the deployment's own alert records (Composition note 9, Capability requirement 50).
External check 21: An auditor needing an identity continuity confirmed MUST read the deployment's own continuity records (Identity 6).
External check 22: An auditor needing a caller's reading of a re-invoked not-known and the caller's retries confirmed MUST read the caller's own call records (Action wiring 73, Action wiring 82, Action wiring 96).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT reconcile two retention policies.
Non-goal 2: A deployment needing a reconciled policy MUST compose a Policy Reconciliation pattern.
Non-goal 3: The composition MUST NOT destroy a record set in one call.
Non-goal 4: A deployment needing an atomic batch destruction MUST compose a transaction wrapper.
Non-goal 5: The composition MUST NOT judge a record reference against the retention records at a hold placement.
Non-goal 6: The composition MUST NOT adjudicate an erasure request.
Non-goal 7: The composition MUST NOT adjudicate a hold's proportionality.
Non-goal 8: The composition MUST NOT refuse a backdated placement instant.
Non-goal 9: The composition MUST NOT own who may place a hold.
Non-goal 10: The composition MUST NOT own who may release a hold.
Non-goal 11: The composition MUST NOT own who may destroy a record.
Non-goal 12: A deployment needing an authorization MUST compose Permissions.
Non-goal 13: The composition MUST NOT verify a hold's legal authority.
Non-goal 14: The composition MUST NOT resolve a case reference against a legal matter.
Non-goal 15: The composition MUST NOT own a destruction mechanism.
Non-goal 16: A deployment needing a shred MUST compose a shred pattern.
Non-goal 17: The composition MUST NOT record an outcome for a rejection outside the gate.
Non-goal 18: A deployment needing an attempted-action record MUST compose a Failed-Attempt Log pattern.
Non-goal 19: The composition MUST NOT govern a Legal Hold record's own retention.
Non-goal 21: The composition MUST NOT keep an aged-out event.
Non-goal 22: A deployment whose hold outlives the payload horizon MUST hold the audit events proving the hold through the hold placement of Capability requirement 69g.
Non-goal 23: A deployment that admits an unbounded hold MUST alert for a hold approaching the payload horizon (Capability requirement 13, Term horizon alert).

Non-goal 24: The composition MUST NOT resolve a record reference rename.
Non-goal 25: The composition MUST NOT place a hold set in one call.
Non-goal 26: The composition MUST NOT release a hold set in one call.
Non-goal 27: A deployment needing a bulk hold change MUST own the loop over [Place Hold] and [Release Hold].
Non-goal 28: The composition MUST NOT hold an idempotence key for a placement.
Non-goal 29: A deployment needing an at-most-once placement MUST compose Duplicate Prevention.
Non-goal 30: The composition MUST NOT place a hold; the deployment owns the hold placement and the placement's gate (Capability requirement 69).
Non-goal 31: The composition MUST NOT gate a refusal ahead of the intent, nor the take of the record section, on the caller's credential (Action wiring 44, Action wiring 45, Action wiring 94, Action wiring 108).
Non-goal 32: A deployment needing an unauthenticated caller kept from the refusals ahead of the intent AND from the take of the record section MUST validate the caller's credential ahead of the call (Non-goal 12).
```

Non-goal 31 and Non-goal 32 rest on one fact: [Purge Eligible] takes no credential and answers every elapsed retention's hold count and deadlines (Action wiring 35, Action wiring 38), so a refusal ahead of the intent tells an unauthenticated caller nothing that read does not, and the intent, the first record of an act, is where the substrate validates the credential (Audit arm 7, Invariant 10.1).

NOTE: the owners — Policy Reconciliation *(forthcoming)* (Non-goal 1, Non-goal 2); the deployment (Non-goal 8; Non-goal 25 through 27); [Permissions](../atoms/permissions.md) and the deployment (Non-goal 9 through 12, Composition note 3 through 5); Shred *(forthcoming)* (Non-goal 15, Non-goal 16); a Failed-Attempt Log *(forthcoming)* (Non-goal 17, Non-goal 18); the deployment (Non-goal 22, Non-goal 23); Reverse Index *(forthcoming)* (Composes 14); Override Authorization *(forthcoming)* (Capability requirement 33).

## Edge cases

### Atomic writes

```
Atomic writes 5: An admitted purge MUST commit the constituent write AND the outcome record in one transaction (Execution Contract Database 1).
Atomic writes 6: The composition MUST NOT reverse Retention Window's purge.
Atomic writes 8: The composition MUST read a storage-failure from Retention Window's purge as the retention standing retained (Retention Window Purge persistence 1).
Atomic writes 9: The composition MUST NOT read a storage-failure from Retention Window's purge as the record standing undestroyed (Retention Window Purge persistence 1a).
Atomic writes 10: A reader MUST NOT read a record purged outcome as the record destroyed (Retention Window Record divergence 5).
```

### Clock semantics

```
Clock semantics 4: The composition MUST judge elapsed retention against the injected now.
Clock semantics 5: The composition MUST judge a sibling set member's eligibility against the injected now.
Clock semantics 11: A reader MUST read a record purged outcome's purge instant as the instant Retention Window stamped the purge.
Clock semantics 14: The composition MUST NOT read a supplied placement instant as the entry instant.
Clock semantics 15: A reader MUST read the recording instant of a hold placement's intent as the entry instant.
Clock semantics 16: The gate MUST NOT read a clock.
Clock semantics 18: A reader MUST count a hold placement's age from the entry instant of the placement's intent AND a hold release's age from the entry instant of the release's intent.
```

Term seam offset allowance: seam offset allowance — the deployment's declared envelope between two seams' readings of one moment — what this composition allows wherever a reading at its own seam is set against an instant another seam stamped (Term elapsed retention).

Term constituent commit: the instant a committing call's write lands in the constituent's own records.

Term gate read: the composition's read of a record's active holds at [Purge Record], taken before any destruction.

Term cadence coverage: the point at which the substrate's seal cadence covers an event.

Term post-destruction hold: a hold whose hold_placed outcome's own intent sits later in the log than the purge intent of the record's destruction.

Term pre-destruction release: a hold whose hold state EQUALS released and whose hold released outcome, or that outcome's own intent, sits earlier in the log than the purge intent of the record's destruction.

Term aged-out hold: a hold whose placement does not stand within the payload horizon and which carries no surviving hold_placed outcome, or a released hold whose release does not stand within the payload horizon and which carries no surviving hold_released outcome — a hold whose order against a destruction the trail can no longer state.

Term historical hold set: the holds over a destroyed record that Legal Hold's read answers unfiltered by hold state, less every post-destruction hold, every pre-destruction release and every aged-out hold — the holds the destruction's gate read met, as far as the surviving trail can say.

### Concurrency

```
Concurrency 5: The composition MUST NOT make a committing call BEFORE taking the record section over the call's record reference.
Concurrency 6: A purge MUST NOT make the gate read BEFORE taking the record section.
Concurrency 7: A purge MUST NOT read the sibling set BEFORE taking the record section.
Concurrency 8: The composition MUST NOT record an intent BEFORE taking the record section.
Concurrency 9: The composition MUST NOT record a gate record BEFORE taking the record section.
Concurrency 10: The composition MUST take the record section by Lease's try_take carrying the section term as duration.
Concurrency 11: The composition MUST mint a fresh holder value PER take (Lease Identity 6).
NOTE: watch the fresh holder value (Concurrency 11).
Concurrency 12: IF Lease's try_take answers held OR no answer THEN an action MUST answer section-unavailable.
Concurrency 13: The composition MUST take one reading of Lease's remaining PER committing call.
Concurrency 14: The composition MUST make a committing call ONLY IF the lease reading taken for the call EQUALS live (Lease Sizing 3).
Concurrency 15: The composition MUST make a committing call WITHIN the section call pause bound of asking for the call's reading (Lease Sizing 3a).
Concurrency 16: The composition MUST take one reading of Lease's remaining PER record_action call under the record section (Lease Sizing 5b).
Concurrency 17: The composition MUST issue a record_action call under the record section ONLY IF the record start floor admits the call (Lease Sizing 5).
Concurrency 18: IF a lease call answers no answer THEN the composition MUST read the lease reading as expired for the rest of the grant (Lease Sizing 7).
Concurrency 19: The composition MUST NOT issue a second time, under one grant, a call that answered no answer (Lease Sizing 8).
Concurrency 20: IF the lease reading EQUALS expired ahead of an act's first committing call THEN the action MUST answer section-unavailable.
Concurrency 21: IF the record start floor admits no first call of an act's first record_action THEN the action MUST answer section-unavailable.
Concurrency 22: IF a call in flight EXISTS under the grant THEN the composition MUST NOT release the record section (Lease Composition note 5c).
Concurrency 23: The composition MUST NOT issue a write under a grant the composition released (Lease Composition note 5f).
Concurrency 24: The composition MUST release the record section ONLY AFTER the act's last call answered.
Concurrency 26: A placement MUST NOT read the record's retentions BEFORE taking the record section.
Concurrency 27: A purge MUST NOT record an intent BEFORE reading the retention state of EVERY retention over the record under the record section.
Concurrency 28: The composition MUST NOT record a hold release intent BEFORE reading the hold's hold state under the record section.
Concurrency 29: The composition MUST issue a record_action call WITHIN the section call pause bound of asking for the call's reading.
Concurrency 30: The composition MUST namespace the record section's key apart from EVERY other key on the Lease host (Lease Composition note 4).
Concurrency 31: The composition MUST read under the record section EVERY database state AND EVERY trail state the composition decides on, a call of [Purge Eligible] excepted.
Concurrency 32: A read made ahead of the take MUST serve to name the record section's key alone, a not-known for an id no database carries excepted.
Concurrency 33: An act whose EVERY call answered MUST release the record section.
Concurrency 35: The implementation MUST serialize the cascade per event id.
Concurrency 36: [Purge Eligible Events] MUST NOT take a serialization lock.
```

### Legal hold suspension of purge

Where the composed hold lands is [Purge Event], not [Purge Eligible Events] (purge event 5, purge eligible events 6), read under the cascade's own critical section after the not-known test and before the seal (purge event 5c) with hold placement serialized against that section (Capability requirement 69a): a hold placed before the read stops the cascade with nothing written, and a hold placed after the section is released finds the cascade finished or left open at step 2 or 3, so there is no placement between a step-1 commit and the step-3 delegation to race it. A cascade left open by a failure at step 2 or 3 and re-driven after a hold is placed stands *Purged* under the hold, lawfully, until release, its content readable unless step 3 destroyed it and the outcome was not recorded; the first half neither alerts on it nor counts it against compensation window (First half 9, First half 10), and Audit Trail Invariant 8 reads it as *held*, a third standing, not a divergence (Audit Trail Invariant 8.1a, Audit Trail Invariant 8.2a), while a hold over a completed purge changes no standing; [Defensible Retention](./defensible-retention.md) already wires the gate over a business record set, and over this instance the placement is the deployment's own facility, which this composition gates and does not perform (Term hold placement, Non-goal 30). A deployment wanting a hold-filtered worklist asks the composed Legal Hold pattern.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own the policy a record is placed under.
Composition note 3: A deployment MUST own who may place a hold.
Composition note 4: A deployment MUST own who may release a hold.
Composition note 5: A deployment MUST own who may destroy a record.
Composition note 8: A deployment MUST own the release of a hold the deployment's own authority overrode.
Composition note 9: A deployment MUST surface an active hold over a destroyed record.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**, and carries no obligation of its own.

### Vocabulary

Term actors: the composition; a deployment; the host; the transition; the seam; a caller; an auditor; a reader; an implementation; an invocation; an action; an intent; an outcome; a gate record; the gate; the rebuild; an index; the record-to-retentions index; the retention-to-record index; a record; a retention; a sibling; a hold; a hold check result; a hold count; a placement; a hold placement; a hold release; a purge; a release; a destruction; a record destruction pattern; a committing call; a landed record; an owed record; an aged-out event; a surviving placement event; a purged placement event; a field cap; the evidence floor; the payload horizon; a policy; the record section; the section term; the section work bound; the record start floor; Legal Hold; Retention Window; Audit Trail; Event Log; a presenter; a presentation; a hold id list; a truncated hold id list; a divergence; a renamed record; the cascade; the first half; the erasure mechanism; an open entry; a closed entry; a suspended entry; the audit retention instance.

Term record verbs: serve, change, inherit, read, hold, reach, call, gate, select, query, attest, govern, store, add, remove, leave, stand, rest, admit, drop, report, agree, cover, name, carry, claim, supply, mint, accept, configure, declare, wire, set, provision, rotate, disclose, start, run, resolve, reconcile, serialize, answer, judge, size, compare, normalize, truncate, fold, trim, discharge, place, canonicalize, retry, alert, record, make, pass, write, order, refuse, own, destroy, intercept, compose, release, match, close, emit, escalate, examine, derive, follow, decide, purge, validate, bind, resist, find, join, reconstruct, clear, act, surface, keep, adjudicate, verify, stamp, block, commit, reverse, mark, need, take, issue, include, survive, namespace, address, bound, classify, condition, confirm, count, delegate, enumerate, evaluate, evidence, filter, invent, invoke, land, map, re-derive, re-drive, re-offer, re-read, reject, remain, repair, restart, return, rewrite, share, test, wait, end.

Term records: empty.

Term bounds: payload horizon (audit_trail_retention_policy), evidence floor, horizon margin, seam offset allowance, field cap, hold ids cap (hold_ids_cap), retentions cap (retentions_cap), horizon alert lead (horizon_alert_lead), audit write latency, section call pause bound, section term, section work bound, record start floor, sibling floor.

Term cadences: seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term value sets: hold check mode = strict | advisory. hold check result = empty | the blocking hold ids with the blocking count. intent = retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended. outcome = retention_placed | hold_placed | hold_released | record_purged.sibling disposition = purged. lease reading = live | expired. erasure outcome = destroyed | destruction-failed(reason). cascade-failure step = seal | hold | step-1 | step-2 | step-3 | in-flight. `Legal Hold` = composed | absent.

Term terms: composition, constituents, business retention instance, record, record-to-retentions index, retention-to-record index, payload horizon, surviving placement event, purged placement event, rebuild, sibling set, seam, transition, evidence floor, hold check mode, now, boundary predicate, opaque input, landed record, owed record, intent, outcome, gate record, committing call, admitted placement, admitted hold placement, admitted hold release, admitted purge, elapsed retention, hold check result, hold override, unavailable sentinel, purged retention ids, sweep, aged-out event, seam offset allowance, constituent commit, gate read, cadence coverage, post-destruction hold, pre-destruction release, aged-out hold, historical hold set, log order, destroyed record, committed placement, committed hold placement, committed hold release, committed purge, record section, section call pause bound, section term, section work bound, audit write latency, record start floor, sibling floor, leg, destroyed event, stand-in, within the payload horizon, horizon margin, constituent instance, largest record, largest gate record, surviving destruction, hold count, horizon alert, entry instant, hold check admitted, hold-blocked, eligibility tuples, lease reading, hold database name, alerting surface, field cap, hold ids cap, position, invocation id, intent instant, record destruction pattern, audit retention instance, erasure outcomes, closed entry, open entry, erasure mechanism, `Legal Hold`, hold placement, tombstone-by-mutation, `act's completion bound`, abandoned call, later truth-bearing write, hold, mid-cascade expiry, `cascade-failure(step-3)`, completed cascade, divergence, purge edge, purge age, suspended entry, purge sweep, hold life, retentions cap, full record, largest purge record, horizon alert lead, gate, placement, audit instance, hold records, eligible.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. verify_record, read_record, seal_now, record_destruction, destruction-failure, nothing-to-seal, retention-period-not-elapsed, event id, recording instant, sequence number, coverage status, covering seal, purged events, destruction record, pair, retention state, per-act critical section, sealed through, unsealed tail, purge completion bound, audit edge, compensation window, slice cap, payload cap, reference length cap, clock offset allowance, call pause bound, seal cadence, window span: Audit Trail. try_take, remaining, grant, holder value, remaining term, call in flight, no answer: Lease. time resolution, standing record, withheld record, retention deadline, purge deadline, purge instant, max purge delay: Retention Window. hold state, hold id, hold reason, placing actor, placement instant, release instant, case reference, database name, string cap: Legal Hold.

Term composing patterns: Policy Reconciliation *(forthcoming)*; Record Destruction *(forthcoming)*; Override Authorization *(forthcoming)*; Reverse Index *(forthcoming)*; Failed-Attempt Log *(forthcoming)*; Shred *(forthcoming)*; [Erasure Tombstone](../atoms/erasure-tombstone.md); [Permissions](../atoms/permissions.md); [Duplicate Prevention](../atoms/duplicate-prevention.md).

Term record: the host's business record this composition governs — named by a record reference, held in the host's own records, and destroyed by the composition through the record destruction pattern once `RetentionWindow.purge` has stood its retention purged (Action wiring 112).

#### Place Record Under Retention

The action that starts a business record's retention clock: it validates, records a placement intent, calls `RetentionWindow.place_under_retention`, indexes the new retention and records the placement. Answers the retention id.

Kind: Operation

#### Place Hold

The action that places a named, actor-issued hold on a record — suspending destruction regardless of the retention clock — and records the placement. Answers the hold id.

Kind: Operation

#### Release Hold

The action that releases a hold and records the release. A record becomes purge-eligible only when no active hold remains (`Invariant 7.1`); releasing one of several is not a release of the obligation.

Kind: Operation

#### Purge Eligible

The read-only query answering every retention of the business retention instance past its retention deadline, each with its active-hold count, so a dashboard tells *purge-ready* from *hold-blocked*. Distinct from [Purge Eligible Events], which answers the audit instance's events. It writes nothing, refuses only where the retention records cannot be read (Action wiring 111), and states no sibling liveness — a tuple can look ready while an in-window sibling, excluded by construction, still covers its record (`Action wiring 43`).

Kind: Operation

#### Purge Record

The composition's load-bearing action: destroy a record only after the gate passes. It reads the sibling set from the constituent's records, reads the record's active holds, refuses with [Under Legal Hold] and records the gate's firing under strict mode, and otherwise records the intent, purges the named retention and every eligible sibling, destroys the record through the record destruction pattern, and records the destruction with the [Hold Check Result]. Where the hold check admitted the destruction, refused [Not Eligible] while the named retention is still running and [Under Active Retention] while a sibling is; refused [Hold Check Unavailable] where the hold records cannot answer the gate's read, and [Section Unavailable] where the record section cannot carry the act.

Kind: Operation

#### Hold Check Result

What Legal Hold's read answered at the gate, carried on the record purged outcome and on the gate record alike: empty when no active hold covered the record, and the blocking hold ids with the blocking count when one did. It is what makes it provable that the gate passed or fired.

Kind:       Field
Field of:   the record purged outcome
Role:       the auditable gate result
Projection: hold_check_result

#### Hold Override

The marker a record purged outcome carries when the [Hold Check Result] stands non-empty under advisory mode, and only then — what makes it provable that a destruction proceeded past an active hold under an authority this layer does not hold.

Kind:       Field
Field of:   the record purged outcome
Role:       the advisory-override marker
Projection: hold_override

#### Under Legal Hold

The load-bearing refusal: under strict mode a destruction is refused while any active hold covers the record, whatever the retention clock says (`Invariant 1.1`). The refusal carries the blocking hold ids and count, and the gate's firing is itself recorded, so the refusal is a record rather than a silence. [Purge Event] refuses with the same token, bare, and only where Legal Hold is composed over the audit instance and a hold stands over the event: a preservation order intercepts the cascade before its first step, so no step runs.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-legal-hold

#### Not Eligible

The refusal for a record whose **named** retention has not yet elapsed — the window is still running, so the record may not be destroyed even with no hold over it. [Purge Event] refuses with it too, where Retention Window's no-early-purge gate refuses the retention of an audit event.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: not-eligible

#### Under Active Retention

The refusal from the cross-retention gate (`Invariant 9.1`): a *sibling* retention over the same record is still inside its window, and a committed purge destroys the record rather than closing the named retention alone, so the longer live obligation refuses the shorter one's destruction.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-active-retention

#### Hold Check Unavailable

The fail-closed refusal when the hold records cannot answer the gate's read or the read a release makes of its own hold. Unreadable hold records are never read as no holds (`Invariant 1.3`), and nothing is destroyed on this arm.

Kind:       Member
Member of:  the purge rejection and the release rejection
Role:       Rejection
Projection: hold-check-unavailable

#### Section Unavailable

The refusal when the record section cannot carry the act: another act over the same record holds it, the take never answered, or this act's own grant ran out before its first committing call. Nothing is committed on this arm, and a retry may clear it.

Kind:       Member
Member of:  the rejection of every state-changing action
Role:       Rejection
Projection: section-unavailable

#### Purge Eligible Events

The derived read returning the event id values eligible for the cascade: delegates to Retention Window's read-time purge eligible projection and maps each retention to its event; evaluates no clock, has no rejection arm. Distinct from Retention Window's purge eligible, the projection that atom's read answers per retained retention (Retention Window Operation 31), keyed by retention id.

Kind: Operation

#### Purge Event

The action that coordinates the cascade for a retention-elapsed event: seals the event if it is in the unsealed tail, requires the retention to be resolved, purges the retention record, writes the destruction record, and delegates the shred of Event Log's data field and the attestation's proof to the erasure mechanism, branching on the reported outcome. Destroys nothing itself, disposes of no seal, re-seals nothing. Returns ok, not-known, [Not Eligible], [Retention Unresolved], [Cascade Failure] carrying the step, or — where a Legal Hold is composed — [Under Legal Hold].

Kind: Operation

#### Cascade Failure

The composition's rejection from [Purge Event] when a database or the seal mechanism refuses mid-cascade, carrying the step: hold, when the hold read answers nothing (the gate fails closed, since the step after it is irreversible), leaving nothing changed; in-flight, when the event's critical section is held by another holder, writes nothing and leaves whatever the holder is doing to it; seal, step-1 and step-2 leave nothing changed and the event on [Purge Eligible Events]'s list, since step 1's transition commits only with step 2's destruction record (Audit Trail Invariant 4.2); step-3 leaves the retention *Purged* over an incomplete cascade, invisible to [Purge Eligible Events] and re-driven by the reconciliation scan, as does a step-2 whose write landed without an answer or that met an open entry; and step-2 and step-3 leave a completed cascade complete where a repeat's read at step 2 or step 3 fails or gives no answer. On a lease host, the cascade's terminus after step 1.

Kind:       Member
Member of:  the purge-event rejection
Role:       Rejection
Projection: cascade-failure

#### Retention Unresolved

The composition's rejection from [Purge Event] step 0½ when the event id resolves to a log entry but to no retention record — the compensation-window state of Audit Trail Invariant 2's liveness arm. Nothing to purge; the remedy is the reconciliation path. Distinct from not-known and from [Not Eligible].

Kind:       Member
Member of:  the purge-event rejection
Role:       Rejection
Projection: retention-unresolved

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Record Under Retention]: #place-record-under-retention
[Place Hold]: #place-hold
[Release Hold]: #release-hold
[Purge Eligible]: #purge-eligible
[Purge Record]: #purge-record
[Hold Check Result]: #hold-check-result
[Hold Override]: #hold-override
[Under Legal Hold]: #under-legal-hold
[Not Eligible]: #not-eligible
[Under Active Retention]: #under-active-retention
[Hold Check Unavailable]: #hold-check-unavailable
[Section Unavailable]: #section-unavailable
[Purge Eligible Events]: #purge-eligible-events
[Purge Event]: #purge-event
[Cascade Failure]: #cascade-failure
[Retention Unresolved]: #retention-unresolved

---

## Standards references

- **Federal Rules of Civil Procedure Rule 37(e)** — the preservation duty for ESI (electronically stored information). A party that fails to preserve when a hold should have been in place faces sanctions including adverse inference. `Invariant 1` and `Invariant 8` are the structural forms of the reasonable-steps obligation; the trail is the evidence.
- **Sarbanes-Oxley section 802 (18 U.S.C. — the United States Code — section 1519)** — criminal obstruction for destroying records subject to a federal investigation. The gate is the structural defence and the destruction record carrying an empty [Hold Check Result] is the evidence that a destruction was not obstruction.
- **Sarbanes-Oxley section 404** — internal controls over financial reporting, retention and destruction controls included. The composition is the structural form of those controls.
- **HIPAA section 164.530(j)** — documentation retention, a six-year federal baseline and longer under state law. The composition governs the PHI (protected health information) retention and hold-during-investigation lifecycle; the substrate provides the attribution trail HIPAA's audit controls require.
- **SEC Rule 17a-4(f)** — broker-dealer preservation in non-rewriteable, non-erasable form. The substrate's Tamper Evidence satisfies the integrity half and the gate the non-premature-destruction half.
- **GDPR Article 17 (right to erasure)** — the composition answers whether an erasure is permissible: an active hold establishes the legal-claims exception under Article 17(3)(e), a live retention the legal-obligation ground under Article 17(3)(b).
- **GDPR Article 5(1)(e) (storage limitation)** — personal data must not be kept longer than necessary. [Purge Eligible] surfaces every retention past retention deadline with its purge deadline, so a caller identifies overshoot; the destruction record proves timely destruction.
- **Federal Rules of Civil Procedure Rule 26(b)** — proportionality in preservation. Legal Hold's `hold_reason` and case reference document each hold's proportionality; the composition preserves the record without adjudicating it (`Non-goal 7`).
- **ISO (International Organization for Standardization) 15489-1 (records management)** — clause 9.7, suspension of disposition, maps to the gate; the two-state hold lifecycle maps to the standard's hold lifecycle.

The three constituents carry their own standards inheritance — see each constituent's own Standards references.

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — defensible-retention.tla + 6 twins + 2 probes (the gate under the record section: a purge against a hold placement and a sibling placement, and the record destruction pattern's retry of a destruction the purge left standing, checked for no destruction over a hold; 16,380 states, holding at a term of 5 within 8 ticks), re-derived from the page as it stands with its recovery retired to Execution Contract Database 1, 2026-11-18 (the outcome module and the sweep went with the rules they checked), and the audit cascade's models, moved here with the cascade: defensible-retention-audit-hold.tla + 7 twins + 3 probes (a hold placed over an open cascade entry, released and re-driven; 43,688 states within 15 ticks, re-run 2026-11-02) and audit-trail.tla + 2 twins (the cascade's order and the scan's first half, which both pages cite); defensible-retention.als + 14 twins (the static data model, 2026-11-12, re-derived 2026-11-18: Invariant 1.1 through 1.3, 1.5, 1.6, 3.1 through 3.3, 4.1 through 4.6, 5.1, 5.4, 5.6, 7.1 through 7.3, 8.1 and 9.1 checked on what one [Purge Record] call answers and writes from its reads, on every state of the retentions, holds and trail the actions leave, and on what [Purge Eligible] answers over one state, Invariant 1.1 and 9.1 a cross-check with the TLA+ models; nothing testable in Alloy for Invariant 2.1 (Retention Window's own records), 2.2, 5.5, 10.1 and 10.2 (orders of reads and calls), 3.4, 3.5, 8.6 and 10.3 through 10.5 (claims), 8.2 (a definition), 9.3 (a refusal the purge's wiring answers), 6.3 through 6.6 (a reader's rules), 5.7 (one transaction), 6.1 and 6.2 (two states), 8.3 (instants), 8.4 and 8.5 (Audit Trail's seal and verification), 9.5 (what the gate reads) and 11 through 13 (the cascade's models); the model found that Invariant 7.1's purge-eligible is no declared term, that 7.3 restates Term hold-blocked, and that 4.2 and 8.1 rest on Action wiring 76, which Invariant 4 does not name); models last run 2026-11-18; coverage 2026-11-18, 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-12, 2026-11-02
last gate: 2026-11-19 — Final Critique 25, a delta round, one reader (Linus minimax-m3), frozen at c6491380 — foundational count 0 after the blind second triage, clean, one sample; the round reopened the page by Audit Trail's cures (09264667, c6491380); Linus's one report claimed 3 foundational, 4 refining and 2 rhetorical, all on Audit Trail's rules bar one on Capability requirement 75, and none held (refuted against the frozen text, which the reader, shown only the reached rules, did not have: Term quiescence counts the bound from the end of the window Composition-level invariant 1c runs on and Defensible Retention Invariant 12.1 restarts; Audit Trail leaves an act whose records stay unreachable to the checks that name its records, Check 8.1, 8.13 and 8.14 among them; a presentation whose count differs from the slice's lands seal-record-set-mismatch at Audit Trail's verify record step 5.2, before step 5.5; Capability requirement 75's "this instance" is the page's own, as in Capability requirement 71 through 74); no cure to the page; 2026-11-19 — Final Critique 24, a delta round, one reader (Linus beam-free), frozen at bfcbbe1a — foundational count 0 after the blind second triage, clean, one sample; Linus's one report claimed 1 foundational and none held (refuted: Capability requirement 74's instance is this one, as Capability requirement 70 through 72 read, and a restart of this instance, the only way its field caps or hold ids cap change, judges it again against the payload cap Capability requirement 75 pins); the settle's own refining cure: Capability requirement 75 reads "the life of this instance", as Capability requirement 71 words it; 2026-11-18 — Final Critique 23, a delta round, one reader (Linus minimax-m3), frozen at 475f0497 — foundational count 1, cured, not clean, no sample; Linus's report claimed 2 foundational, 6 refining and 2 rhetorical, and none of the ten held (both foundational refuted: Term largest record is the page's own term and measures the serialized envelope Audit Trail measures, so the hold ids are counted; Capability requirement 74's instance is this one, as Capability requirement 70 through 72 read, and the cap it judges is the deployment's declaration), the first triage placing one foundational the report did not name, a reachable state: the audit instance restarted alone with a lower payload cap than the largest gate record, which Capability requirement 74, judged once at this instance's start, never re-judges, so a strict purge over a held record answers invalid-request by Primitive policy 23 and leaves no gate record Action wiring 52 and Wiring decision 4 require; cured by Capability requirement 75, the audit instance's payload cap standing as one value for this instance's life, as Capability requirement 60 holds the audit retention policy; 2026-11-18 — Final Critique 22, a delta round, one reader (Linus minimax-m3), frozen at 213cedc — foundational count 1 after the blind second triage, cured, not clean, no sample; Linus's one report claimed 0 foundational, 7 refining, 4 rhetorical, and the first triage placed none foundational (refuted: Action wiring 57's "a purge", which the page uses as the name of a [Purge Record] call in Action wiring 48 through 56 and 64 through 90, [Purge Eligible] against [Purge Eligible Events], Term largest record's sizing of the envelope whole, Invariant 9.1's form; cured: Term committed purge names the write Atomic writes 5 commits with the outcome record, Action wiring 110 says excepted twice, Check 5.10 cites Invariant 5.5); the blind second triage placed the open line 2026-11-04-a foundational, Kind A, a reachable state no report of the round named (a strict purge over a held record whose largest gate record exceeds the payload cap answers invalid-request by Primitive policy 23 and leaves no gate record Action wiring 52 and Wiring decision 4 require), and Linus's own findings none; cured by Term largest gate record and Capability requirement 74, the first of the line's two proposed cures (a start condition that the gate record at the caps fits), so the line closes and the page takes a delta round; 2026-11-18 — Final Critique 21, a full round, frozen at fd07bd5 — foundational count 3, cured (the failed read of [Purge Eligible Events], Composes 20's unscoped eligibility clock, a record reference's field cap past Legal Hold's string cap), not clean, one sample; 2026-11-17 — Final Critique 20, a delta round, frozen at f8dce3b — foundational count 0 after the blind second triage, clean, one sample, the page stays doing on open line 2026-10-04-r (Linus's one report claimed two foundational: that Input 2's start-time floor has no failing arm, which both triages placed refining, since a deployment that starts on a cap a held record exceeds breaks Input 2's own MUST NOT; and that Capability requirement 58's audit horizon is unresolved between this page and Audit Trail, which both placed refining, since Term audit horizon says which one every rule here reads and the homonym is open line 2026-10-25-b; refining 5 and rhetorical 1 refuted or owned, none cured); 2026-11-17 — Final Critique 19 — delta, frozen at ce2aad2 — foundational count 2, one cured, one carried by the unit that composes Recoverable Invocation, not clean, one sample

open:
- 2026-10-04-u · refining · Capability requirement 69; Non-goal 30 · the hold-gate wiring over the audit instance's events is an extraction candidate, a pattern of its own beside this page, Hold-Aware Audit Retention → Scott decides whether to extract it; the page keeps the wiring until he does (a question under Needs Scott)
- 2026-10-06-e · refining · Action wiring 110 · the [Purge Eligible] listing has no cap and no page, so every elapsed retention answers in one call → Scott decides the page's shape, a listing cap the deployment declares and an `after` retention id, since a plain cap would hide purge-ready retentions behind a run of hold-blocked ones (a question under Needs Scott)
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./defensible-retention.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- compositions/defensible-retention.md`.

</details>

NOTE: End of Defensible Retention.

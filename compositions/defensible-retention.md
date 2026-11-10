---
title: Defensible Retention
parent: Conceptual Compositions
nav_order: 7
has_toc: true
toc: true
---

# Defensible Retention

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Defensible Retention makes record destruction provably lawful. It combines three patterns: Legal Hold, which records who ordered a record preserved and why; Retention Window, which records the minimum keep-period and blocks early deletion; and Audit Trail, the tamper-evident record that stamps and seals every decision.

The guarantee none of the three has alone is a gate that sits between checking for holds and actually deleting. Under strict mode, no record carrying an active hold is destroyed through this composition, however long ago its keep-period ended. A deployment may instead configure advisory mode, which records an externally-authorized override and proceeds; strict is the required posture under Rule 37(e) of the Federal Rules of Civil Procedure, Securities and Exchange Commission Rule 17a-4 and the Sarbanes-Oxley Act.

The same composition owns the end of the audit instance's own events, which moved here from Audit Trail so that lawful destruction lives in one page: the cascade that seals an event, has Audit Trail end its retention and write the destruction record, and delegates the shred of its content to the deployment's erasure mechanism, behind the same kind of hold gate.

The gate is audited in both directions — an event when it allows a destruction, naming that no holds applied, and an event when it blocks one, naming which holds applied — so both halves of the gate's behaviour are provable.

Every destroyed record leaves three things behind: a destruction event naming what the hold records held at gate time, a retention record standing purged, and a tamper-evident seal once the seal cadence covers the event. Together they prove the destruction was lawful, attributed and unaltered — for as long as the audit records themselves are kept, which is the deployment's own ordering obligation rather than this composition's guarantee.

Its most common uses are financial records governance under SOX (Sarbanes-Oxley Act) section 802, patient records under HIPAA (US Health Insurance Portability and Accountability Act) section 164.530(j), electronically stored information subject to FRCP (Federal Rules of Civil Procedure) Rule 37(e) litigation holds, and broker-dealer communications under SEC (US Securities and Exchange Commission) Rule 17a-4. Any system that must prove it did not destroy records while a legal or regulatory hold was active — and that it did eventually destroy them once the hold was released and the retention window had closed — is a candidate for this composition.

---

## Intent

A record's life under a regulated system follows two governance tracks that must coexist without one silently overriding the other. The first is the *retention clock*: a record must be kept for a minimum period mandated by statute, regulation, or contract — seven years under SOX, six under HIPAA, three for some broker-dealer communications under SEC Rule 17a-4. The second is the *preservation directive*: when litigation is anticipated, when a regulator opens an investigation, when an audit freeze is ordered, the normal retention clock stops being the governing rule and the obligation shifts to *keep this record until the legal matter resolves, regardless of what the schedule says.*

Neither Retention Window nor Legal Hold alone enforces that coexistence. Retention Window enforces the clock — it prevents purge before retention deadline and records the eligibility transition. Legal Hold records the preservation obligation — who placed the hold, why, and when. Neither enforces the other's constraint: a retention whose window has elapsed is eligible for `RetentionWindow.purge` with no knowledge of any hold, and a record under an active hold is recorded as preserved while the Legal Hold atom intercepts nothing. The gate that enforces *no purge while any active hold covers a record* belongs to the composition, and this composition is that gate.

Audit Trail provides the third leg: every hold placement, every release, every retention placement and every purge decision is attribution-stamped, retention-bounded and tamper-evident. A destruction is defensible because the evidence trail — who held the record, who released the hold, who purged it, under what policy, at what time — is itself a regulated, integrity-protected record, so the destruction is provable.

This is a composition, not a new primitive. Legal Hold, Retention Window and Audit Trail are unchanged; the composition is the wiring that makes them coherent as one retention-governance surface. It wires the hold gate over the *business* record set, and owns the destruction of those records, which it makes through a record destruction pattern. It also owns the end of the audit instance's own events, which moved here from [Audit Trail](./audit-trail.md) on 2026-11-02 under the maintainer's ruling that lawful destruction lives in one page: the cascade that seals an event, has Audit Trail end its retention and write its destruction record, and delegates the shred of its content to the deployment's erasure mechanism; the Legal Hold gate over that cascade, so that the events proving a hold are not destroyed while the hold is live; and the first half of the reconciliation scan that completes a cascade that stopped partway (`Capability requirement 69` through `Capability requirement 72`). The destruction record itself stays Audit Trail's, written by its record_destruction, which this composition reaches through its declared surface alone (`Composes 21`).

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
Deleted: Composes 11. Composes 21 owns it: the audit instance's end of life is this composition's own, reached through Audit Trail's record_destruction.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST attest an invocation's audit record under the calling actor's credential.
Composes 16: The composition MUST attest a sweep's audit record under the service identity.
Composes 17: The composition MUST NOT attest a sweep's audit record under a calling actor's credential.
Composes 18: The composition MUST NOT supply the injected now to a constituent.
Composes 19: [Purge Eligible Events] MUST read eligibility through Retention Window's declared read over the audit retention instance.
Composes 20: The composition MUST NOT evaluate an eligibility clock.
Composes 21: The composition MUST end an audit event's retention through Audit Trail's record_destruction alone.
Composes 22: The composition MUST NOT write a destruction record beside Audit Trail's record_destruction.
```

Term composition: this pattern's wiring of [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) and the [Audit Trail](./audit-trail.md) substrate — the five actions, the hold gate, the two indexes and the sweep.

Term constituents: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md).

Term business retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over business records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

Term audit retention instance: the one [Retention Window](../atoms/retention-window.md) instance [Audit Trail](./audit-trail.md) wires over the audit log's events (Audit Trail Composes 3) — read by the audit cascade through the constituent's declared read and never held by this composition (Composes 7).

Term service identity: application_actor_ref and application_credential — the composition's own registered actor and credential, and the attested emitter of every record the sweep writes.

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
Composition state 7: A committed purge MUST leave a pending sibling in the record-to-retentions index.
Composition state 8: The composition MUST remove a record reference carrying no retention from the record-to-retentions index.
Composition state 9: The record-to-retentions index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 10: The retention-to-record index MUST stand as a derived index PER the section titled Composition state in `execution-contract.md`.
Composition state 11: The composition MUST NOT store a truth beside a constituent's records.
Composition state 12: The rebuild MUST read a surviving placement event for an index entry.
Composition state 13: The rebuild MUST take EVERY retention Retention Window's declared read answers as an index entry.
Composition state 14: The rebuild MUST NOT read a purged placement event's payload.
Composition state 15: The rebuild MUST NOT read a trail miss as an absent retention.
Composition state 16: The database-sourced rebuild MUST admit a retention the composition did not place.
Composition state 17: A refusal resting on the database-sourced rebuild MUST NOT stand as a scope statement.
NOTE: open 2026-11-05-a — "scope statement" in Composition state 17 is no declared term, so what a refusal resting on the database-sourced rebuild may not claim (that the retention was placed through this composition, Composition state 16) is unstated.
Composition state 18: The composition MUST NOT rest a purge admission on an index.
Composition state 19: The composition MUST read the sibling set from Retention Window's records.
Composition state 20: An index MUST stand outside an action's atomicity set.
Composition state 21: The composition MUST read a missing index entry as a rebuild trigger.
Composition state 22: The composition MUST NOT claim a cross-constituent consistency for an index.
Composition state 23: The rebuild MUST drop an index entry whose retention's retention state EQUALS purged.
Composition state 24: The composition MUST report a dropped entry over a surviving destruction that carries no record_purged event AND no open purge marker as a bypass finding.
Composition state 25: The composition MUST NOT read a stale index entry as a bypass alone.
Composition state 26: The record-to-retentions index AND the retention-to-record index MUST agree.
Composition state 27: EVERY retention MUST cover EXACTLY ONE record.
Composition state 28: A record MAY carry a retention beside another retention.
Composition state 29: EVERY hold MUST name EXACTLY ONE record.
Composition state 30: A record MAY carry a hold beside another hold.
Composition state 31: A record MAY carry no hold.
Composition state 32: A hold MUST NOT rest on a retention.
Composition state 33: The sweep MUST remove a retention the sweep purged from the record-to-retentions index AND the retention-to-record index.
Deleted: Composition state 34. Execution Contract Database 1 owns it.
```

Term record-to-retentions index: record_to_retentions — the composition's index from a record reference to the retentions whose retention state EQUALS retained over the record — the auditor's first query surface and a read-path convenience, never the gate's input.

Term retention-to-record index: retention_to_record — the composition's index from a retention id to the record the retention covers, with the retention's retention deadline and purge deadline read back from Retention Window's declared read.

Term audit horizon: the age past which the audit instance has destroyed an event's payload — the retention period of the one policy audit_trail_retention_policy answers for every event of the audit instance (Capability requirement 57). Audit Trail's Term audit horizon, the span through which events are live, is another (open line 2026-10-25-b); every rule here reads this one.

Term surviving placement event: a retention_placed event whose payload the audit instance has not destroyed.

Term purged placement event: a retention_placed event whose payload the audit instance has destroyed.

Term rebuild: the composition's named regeneration of an index — select this composition's placement events over an open-ended sequence range, keeping each event whose action reference names retention_placed, the outcome a committed placement records (Term outcome), the action reference being what Audit Trail's read answers for every event, a destroyed event included (Term destroyed event); take a surviving event's record reference and retention id, and take and drop retentions as Composition state 13 and Composition state 23 write.

Term sibling set: the retentions whose retention state EQUALS retained over one record beside the named retention, read from Retention Window's records.

Term pending sibling: a retention standing retained over a destroyed record — a sibling whose own purge has not landed.

Term within the audit horizon: said of a placement, a release or a purge by the instant the constituent's records carry for it — the act's age, the reader's now less that instant, plus the horizon margin DOES NOT EXCEED the audit horizon, so the act's own audit records cannot have aged out. An act that does not stand within the audit horizon reads unknown wherever its record is missing (Check 6.4).

NOTE: open 2026-10-04-g — a hold's placement and release are aged by the instant Legal Hold's records carry, which a caller may assert, so a hold backdated past the horizon reads as outside it the day it is entered.

Term horizon margin: `(((2 * clock_offset_allowance) + time_resolution) + section_term)` — how far below the audit horizon an act's age must stand for the act's own audit records not to have aged out (Term within the audit horizon): two allowances, because the substrate places a record's retention on one clock after the database stamped the act on another, and judges the record's purge on the first against a now the reader takes on a third; one time resolution, the smallest span the database tells apart (Retention Window Capability requirement 5); and one section term, the longest an intent stands ahead of the act it announces, the two landing under one grant of the record section (Concurrency 8, Concurrency 14), so the intent, the act's oldest audit record, has not aged out while the act stands within the audit horizon.

Term surviving destruction: a destroyed record whose earliest purge among the retentions over the record stands within the audit horizon — a destruction whose own record purged outcome and purge intent cannot have aged out. The edge is the record's first purge and never a sibling's later one, which the sweep may land after the outcome.

The audit cascade keeps one composition-state element of its own, moved here from Audit Trail with the cascade: erasure outcomes, extraction-pending against [Erasure Tombstone](../atoms/erasure-tombstone.md) (Execution Contract Composition state).

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
  The instant of a destruction is no part of erasure outcomes: Retention Window Capability requirement 7 asks the deployment to retain it, read from the clock that supplies now, which the composition reads only for the seal cadence timer and the scan (Audit Trail Clock source 1), and Retention Window External check 5 reads it from the deployment's own destruction records.

  Term closed entry: a Purged retention whose cascade is a completed cascade.

  Term open entry: a Purged retention whose cascade is not a completed cascade; open for re-driving.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one invocation id at the seam PER state-changing invocation.
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Capability requirement 4: The transition MUST NOT mint an invocation id.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Capability requirement 6: The composition MUST NOT accept an invocation id as an input.
Capability requirement 7: The composition MUST NOT mint a retention id.
Capability requirement 8: The composition MUST NOT mint a hold id.
Capability requirement 9: The composition MUST NOT mint an event id.
Capability requirement 10: A deployment MUST configure the audit instance with an audit retention policy.
Capability requirement 11: The evidence floor MUST NOT EXCEED the audit horizon.
Capability requirement 12: A deployment MUST declare the longest hold the deployment admits.
Capability requirement 13: IF a deployment admits an unbounded hold THEN the deployment MUST wire a horizon alert.
Capability requirement 14: A deployment MAY declare a field cap PER payload field (Execution Contract Input 2).
Capability requirement 15: A field cap MUST NOT EXCEED the audit instance's payload cap.
Capability requirement 16: A deployment MAY declare the hold ids cap (Execution Contract Input 2).
Capability requirement 17: A deployment MUST provision the service identity as a registered actor.
Capability requirement 18: A deployment MUST rotate the service identity's credential.
Capability requirement 19: A deployment MUST set the retention completion bound.
Capability requirement 20: A deployment MUST set the compensation window.
Capability requirement 21: A deployment MUST set the reconciliation cadence.
Capability requirement 22: A deployment MUST disclose the audit write latency.
Capability requirement 23: A deployment MAY start an instance ONLY IF the compensation window EXCEEDS the closure floor.
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
Deleted: Capability requirement 34. Concurrency 5 owns it.
Deleted: Capability requirement 35. Concurrency 5 owns it.
Capability requirement 36: The deployment MUST declare the clock offset allowance.
Capability requirement 37: A deployment MUST supply a Lease host PER Lease Capability requirement 1, 2, 4, 5, 7 and 11.
Capability requirement 38: A deployment MUST set the call pause bound.
Capability requirement 39: A deployment MUST set the section term.
Capability requirement 40: A deployment MUST set the section work bound.
Capability requirement 41: The section work bound MUST include twice the call pause bound (Lease Sizing 4).
Capability requirement 42: A deployment MAY start an instance ONLY IF the section term EXCEEDS the section work bound (Lease Sizing 4a).
Capability requirement 43: A deployment MAY start an instance ONLY IF the section work bound EXCEEDS the record start floor (Lease Sizing 9).
Capability requirement 44: The section term MUST NOT EXCEED the retention completion bound.
Capability requirement 45: A deployment MUST place a retention of the business retention instance through [Place Record Under Retention] alone (Retention Window Simultaneous retention 5).
Capability requirement 46: A deployment MUST purge a retention of the business retention instance through [Purge Record] alone (Retention Window Simultaneous retention 5).
Capability requirement 47: A deployment MUST place a hold of the hold records through [Place Hold] alone.
Capability requirement 48: A deployment MUST declare the hold database name.
Deleted: Capability requirement 49. Execution Contract Database 3 owns it.
Capability requirement 50: A deployment MUST supply the alerting surface.
Deleted: Capability requirement 51. Execution Contract Scheduled leg 1 owns it.
Deleted: Capability requirement 52. Execution Contract Scheduled leg 1 owns it.
Capability requirement 53: A deployment MUST release a hold of the hold records through [Release Hold] alone.
Capability requirement 54: A deployment MUST supply hold records, a business retention instance, an audit instance AND a record destruction pattern bound by Lease Capability requirement 8 and 10 for EVERY call the composition issues under the record section.
Capability requirement 55: A deployment MUST supply the business retention instance PER Retention Window Capability requirement 1, 5 and 6a through 16, the composition owning the destruction (Retention Window Record divergence 4).
Deleted: Capability requirement 56. Execution Contract Database 2 owns it: Audit Trail names no margin for a record action to start on.
Capability requirement 57: A deployment MUST set an audit retention policy that answers one policy for EVERY event of the audit instance.
Capability requirement 58: A deployment MAY start an instance ONLY IF the audit horizon EXCEEDS the alert floor.
Capability requirement 59: A deployment MUST NOT serve two instances of the composition by one constituent instance.
Capability requirement 60: The audit retention policy MUST stand as one value for the life of the instance.
Capability requirement 61: A deployment MUST declare the enumeration bound.
Capability requirement 62: A field cap of a reference MUST NOT EXCEED the audit instance's reference length cap.
Capability requirement 63: The host MUST NOT supply one invocation id to two invocations.
Capability requirement 64: A deployment MUST NOT admit another writer of the composition's action references on the audit instance.
Capability requirement 65: The deployment MUST supply the constituent instances' database PER Execution Contract Database 1 through 4 and Execution Contract Read 6.
Capability requirement 66: A deployment MUST supply the record destruction pattern PER Retention Window Record divergence 4a through 6.
Capability requirement 67: The record destruction pattern MUST NOT retry a destruction BEFORE taking the record section over the record reference (Retention Window Simultaneous retention 6).
Capability requirement 68: IF the hold check mode EQUALS strict THEN the record destruction pattern MUST retry a destruction ONLY IF a read of Legal Hold made under the record section answers no active hold over the record (Wiring decision 1).
Capability requirement 69: WHEN Legal Hold EQUALS composed:
    Capability requirement 69a: The deployment MUST serialize a hold placement over an event id with the per-act critical section keyed by that event id.
    Capability requirement 69b: The deployment MUST read hold from the Legal Hold database instance wired to this instance.
    Capability requirement 69c: A hold placement MUST hold the critical section as a lease of purge completion bound.
    Capability requirement 69d: A hold placement MUST NOT issue a write after the lease has expired.
    Capability requirement 69e: A hold placement that finds the critical section held MUST wait for the lease's instant or the holder's release.
    Capability requirement 69g: The deployment MUST place a hold over an event id of this instance through a hold placement alone.
    Capability requirement 69h: A deployment whose regime orders the preservation of audit records MUST set Legal Hold to composed.
    Capability requirement 69i: The deployment's placement gate MUST bound the hold placements over an open entry to one displacement of the entry's first-half leg WITHIN Audit Trail's compensation window of the finding's creation, a displacement being a hold placement holding the entry's critical section when a first-half leg comes for the entry (Audit Trail Per-act critical section 5).
Capability requirement 70: IF erasure mechanism EQUALS blank THEN the instance MUST NOT start.
Capability requirement 71: IF Legal Hold EQUALS composed AND no Legal Hold database instance is wired to this instance THEN the instance MUST NOT start.
Capability requirement 72: IF Legal Hold EQUALS composed AND no hold placement EXISTS THEN the instance MUST NOT start.
```

NOTE: watch the id the host supplies to two calls (Capability requirement 63).

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one invocation id here.
Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term invocation id: the id the seam allocates for one state-changing invocation; an intent and the outcome matched to it carry the same one (Capability requirement 2, Reconciliation 6).

Term intent instant: the instant an intent records (Action wiring 8).

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term evidence floor: `(((longest_retention_duration + longest_purge_delay) + longest_hold_duration) + horizon_margin)` — the longest retention policy in use on the business retention instance, the longest max purge delay and the longest hold the deployment admits, summed with the horizon margin — what audit_trail_retention_policy must outlast. The margin is in the sum because an act stands within the audit horizon only by it (Term within the audit horizon): a horizon equal to the three durations alone reads the placement of a record they cover as not within the audit horizon by the time the record is destroyed. The sum is a floor under the policy and no bound on a record's life: a later sibling or a second hold carries a record past it, and what the trail has lost by then the rebuild reads from Retention Window's records (Composition state 13). Where the deployment admits an unbounded hold the hold term is zero: no horizon outlasts such a hold, and the horizon alert and the substrate's own hold placement carry what the sum cannot (Capability requirement 13, Non-goal 22, Non-goal 23).

Term closure floor: `(((((retention_completion_bound + (2 * clock_offset_allowance)) + reconciliation_cadence) + enumeration_bound) + call_pause_bound) + (2 * audit_write_latency))` — the longest interval in which a run that takes the record section closes an open marker: the marker's age at the lower edge, read at a seam that may stand an allowance either side of the intent's; one cadence to the next run; that run's enumeration and its alerts; the leg's take; and the leg's two records. The floor is the first leg's: each leg a run works ahead of a marker's own adds a take and a grant, which no floor counts, so a backlog is alerted on before it is closed.

NOTE: open 2026-10-25-b — Audit Trail declares its own Term closure floor, another formula, and its own Term call pause bound, clock offset allowance, compensation window, intent, leg, quiescence, reconciliation cadence, seal coverage and audit horizon (GRACE-lang Closed vocabulary 17).

Term alert floor: `((((2 * compensation_window) + reconciliation_cadence) + enumeration_bound) + (2 * clock_offset_allowance))` — the age by which a run has alerted on an overdue marker and the deployment has had a window to answer the alert, while the marker's intent can still be read. The terms in order: the window; a cadence to the run that reads the marker overdue, and that run's enumeration; a second window for the alert to be answered in; and two allowances, one where a run reads overdue against an instant another seam stamped and one where the substrate destroys on a clock of its own. The alert rests on the run's own enumeration and waits for no section, so a held section or a refused read of a leg delays the closing and never the alert; a run whose enumeration answers a refusal, state-unavailable or no answer alerts on that (Reconciliation 44). The floor promises the alert and its window and nothing of the closing that follows the answer: a run closes what its legs reach, one grant after another, and a marker still open when its intent is destroyed stays the alerted partial it was (Atomic writes 7), its outcome unwritten (Invariant 5.7). A deployment that means every marker to close sets the horizon above the floor by the runs its backlog needs.

Term enumeration bound: enumeration_bound — the deployment's declared longest time from a run's start to the end of the run's enumeration of the open markers and of its alerts on them. The trail grows and the sweep keeps no cursor (Reconciliation 3), so holding the bound is the deployment's.

Term overdue marker: an open marker whose intent instant stands older than the compensation window of the now a run is given at its start — a marker the compensation window did not close.

Term constituent instance: the Legal Hold instance holding the hold records, the business retention instance, or the audit instance — the three Composes 1 through 3 give one instance of the composition. Two instances of the composition sharing one would each take a record section the other does not see, and each sweep would read the other's intents as its own.

Term retention completion bound: retention_completion_bound — the deployment's declared maximum duration between an invocation's intent record and the invocation's outcome record, read against the injected now the intent carries.

Term hold check mode: hold_check_mode — strict | advisory.

Term record section: the [Lease](../atoms/lease.md) this composition takes on a record reference — the key is the record reference under this instance's own namespace on the host (Concurrency 30) and the holder value is minted fresh for each take — under which one act over the record runs, from the act's first read at the gate to the act's outcome.

Term call pause bound: this composition's value of [Lease](../atoms/lease.md)'s call pause bound — the longest time from the decision to issue one call to the moment the call has taken effect or failed. It bounds a lease call and a committing call, and never a whole record_action (Lease Capability requirement 7).

Term record destruction pattern: the pattern through which the composition destroys a business record — Record Destruction *(forthcoming)*. It destroys only a record a purged retention names, keeps each destruction's confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the pattern that owns the destruction (Capability requirement 66). Under strict mode a standing record an active hold covers is a withheld record: the pattern retries a destruction only under the record section, and only where a read of Legal Hold made there answers no active hold over the record (Capability requirement 67, Capability requirement 68), so a hold placed after the purge keeps the record until the hold is released.

Term section term: the duration every take of the record section asks for (Lease Composition note 5d).

Term section work bound: the deployment's declared longest time from a take's answer to the landing of an act's outcome — the gate read, the sibling set's read, the intent, the act's first committing call and the outcome counted, each record_action at the audit write latency. A sibling's purge the grant no longer admits stands pending, and a record whose call to the record destruction pattern the grant no longer admits stands for that pattern's retry, so no act's work outruns the bound.

NOTE: open 2026-10-04-e — a leg has no work bound the section term must exceed, the audit write latency runs from the issue where Lease's unit runs from the ask, and the sibling floor leaves no pause for the outcome's own reading or the purge-instant read.

Term audit write latency: the deployment's disclosed longest time from issuing a record_action to the landing of the call's last write, an abandoned call's included. The unit's bound of a record_action under the record section (Lease Composition note 8a); a record_action that has not answered within it answers no answer (Audit arm 18).

Term record start floor: `(audit_write_latency + (2 * call_pause_bound))` — the remaining term a record_action needs to land inside the grant. The floor admits a call whose [Remaining](../atoms/lease.md) reading answers a remaining term exceeding the floor (Lease Sizing 5).

Term sibling floor: `(record_start_floor + (2 * call_pause_bound))` — the remaining term below which a purge starts no further sibling's purge and no call to the record destruction pattern, so that the outcome still has its floor once that call has landed.

Term lease reading: live | expired — what a [Remaining](../atoms/lease.md) reading of the record section says of the grant, as [Lease](../atoms/lease.md) declares the two (Lease Sizing 2, Lease Sizing 2a, Lease Sizing 7).

Term hold database name: the deployment's declared name of the one Legal Hold database instance serving the composition (Composes 1), matched against the database name Legal Hold's read answers (Legal Hold Instance 5).

Term alerting surface: the deployment's surface on which the composition alerts.

Term compensation window: compensation_window — the duration within which the sweep closes an open marker or escalates it (Reconciliation 25).

Term reconciliation cadence: reconciliation_cadence — the interval between the sweep's runs, beside the run at an instance's start.

Term field cap: the deployment's declared maximum size of one audit payload field. *Default:* 1 kilobyte, or the audit instance's payload cap where that is smaller, or for a reference the audit instance's reference length cap where that is smaller (Capability requirement 15, Capability requirement 62).

Term hold ids cap: hold_ids_cap — the deployment's declared maximum count of hold ids a hold check result carries, in an answer and in a record (Primitive policy 20). *Default:* 32.

NOTE: watch the unset setting (Capability requirement 14, Capability requirement 16).

Term Legal Hold: composed | absent — whether the deployment composes the [Legal Hold](../atoms/legal-hold.md) pattern over this instance; a knob, set by Capability requirement 69h. *Default:* absent.

Term hold placement: the deployment's own call of Legal Hold's place over an event id of this instance, made under the per-act critical section as Capability requirement 69 states it — a deployment facility, as a scheduled leg's starter is (Execution Contract Scheduled leg 1), and no action of this composition (Non-goal 30).

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
      Cascade critical section 4a: The host MUST set the lease to the act's completion bound, a [Purge Event] re-driven by the first half excepted (Audit Trail Per-act critical section 13a, Cascade critical section 5).
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

The one Lease requirement no constituent can meet whole is that a refused write was not applied: the substrate's step-3 refusal may hide an append still to land (`Concurrency 25`), and Retention Window's failed purge may follow a destruction (`Atomic writes 9`). Each is read here as what it is.

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
Deleted: Primitive policy 15. Primitive policy 14 owns it.
Primitive policy 16: The composition MUST compare an opaque input byte-exact.
Primitive policy 17: The composition MUST NOT normalize an opaque input.
Primitive policy 18: The composition MUST NOT store a credential.
Primitive policy 19: The composition MUST NOT answer a credential.
Primitive policy 20: The composition MUST truncate an answered hold id list PER the hold ids cap, keeping the first hold ids of Legal Hold's read order (Legal Hold Operation 24, 25).
Primitive policy 21: A truncated hold id list MUST carry the list's true count.
Primitive policy 22: The composition MUST NOT read a truncated hold id list as an empty hold check result.
Primitive policy 23: IF the largest record EXCEEDS the audit instance's payload cap THEN the action MUST answer invalid-request.
NOTE: open 2026-11-04-a — nothing binds the capped fields and the capped hold ids jointly to the payload cap, so a strict purge over a held record can answer invalid-request and leave no gate record.
```


Term boundary predicate: the composition's own validation of an input at an action's boundary, judged before any constituent call.

Term opaque input: record reference | policy reference | actor reference | placing actor | releasing actor | hold id | retention id | case reference.

Term largest record: the largest audit record the act can still leave once the refusals ahead of the intent are judged (Action wiring 108), measured as the serialized envelope Audit Trail measures (Audit Trail payload cap 2) — the gate record alone where the gate refuses under strict mode; otherwise the largest of the intent, the outcome, and the recovery intent and the recovery outcome the sweep writes where the act's own outcome stays owed, carrying every retention the read under the record section answered over the record and the hold check result as truncated. An id a constituent has yet to mint is sized at the id's field cap.

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
Deleted: Audit arm 3. Execution Contract Database 1 owns it.
Deleted: Audit arm 4. Execution Contract Database 1 owns it.
Audit arm 5: The composition MUST read a landed record back by the invocation id.
Audit arm 6: The composition MUST alert on a landed record carrying no retention.
Audit arm 7: IF the substrate refuses an intent on a credential THEN the action MUST answer invalid-credential.
Audit arm 8: The composition MUST read an invalid-credential on a sweep record as a deployment fault.
Audit arm 9: The composition MUST alert on an invalid-credential on a sweep record.
Audit arm 10: The composition MUST NOT retry an invalid-credential answer in a loop.
Audit arm 11: The composition MUST NOT read an invalid-request answer as unreachable.
Audit arm 12: The composition MUST read an invalid-request carrying step-4 as a landed record.
Audit arm 13: The composition MUST read an invalid-request carrying a step below step-4 as an owed record.
Audit arm 14: The composition MUST alert on an invalid-request answer.
Audit arm 15: The composition MUST NOT retry an invalid-request answer.
Audit arm 16: The composition MUST read a recording-failure carrying step-3 as an owed record.
Audit arm 17: IF the record start floor admits no further call THEN the composition MUST read a recording-failure carrying step-2 as an owed record.
Audit arm 18: The composition MUST read a record_action that answers no answer as an owed record.
Audit arm 19: IF the substrate refuses a gate record on a credential THEN [Purge Record] MUST answer invalid-credential.
Audit arm 20: The composition MUST read an outcome the substrate refuses on a credential as an owed record.
Audit arm 21: IF the record start floor admits a further call THEN the composition MUST retry a recording-failure carrying step-4.
Audit arm 22: IF the record start floor admits no further call THEN the composition MUST read a recording-failure carrying step-4 as an owed record.
NOTE: watch the retention step's recording failure (Audit arm 21, Audit arm 22).
Audit arm 23: The composition MUST read a record_action that answers state-unavailable as a recording-failure carrying step-2 (Execution Contract Read 3).
NOTE: watch the constituent's failed read (Audit arm 23).
```

Term landed record: an audit record the substrate has appended and attested, whatever the substrate then answered.

Term owed record: an audit record this composition must write and the substrate has not appended. After the act's commit that is the act's outcome, whether the substrate did not append it (Audit arm 13, 16, 17, 18, 20) or the record section admitted no call of it (Concurrency 34). Ahead of any commit it is an intent or a gate record this composition issued and the audit arms read as owed (Audit arm 13, 16, 17, 18); a record the substrate refuses there on the caller's credential is the caller's own answer and leaves nothing owed (Audit arm 7, 19), and a record the record section admitted no first call of was never issued (Concurrency 20, 21). An owed gate record has no intent behind it and so no later writer: it ends with the answer (Action wiring 85).

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
Deleted: Action wiring 16. Execution Contract Constituent failure 1 owns it.
Action wiring 16a: IF Retention Window answers registry-unavailable THEN [Place Record Under Retention] MUST answer storage-failure (Execution Contract Constituent failure 2).
Action wiring 17: An admitted hold placement MUST call Legal Hold's place with the record reference, the placing actor, the reason, the case reference AND the supplied placement instant, where the call supplies one (Primitive policy 10).
Action wiring 18: A committed hold placement MUST record a hold placed outcome carrying the hold id, the record reference, the placing actor, the reason, the case reference AND the placement instant.
Action wiring 19: IF a committed hold placement's outcome landed THEN [Place Hold] MUST answer the hold id.
Action wiring 20: IF Legal Hold answers invalid-request THEN [Place Hold] MUST answer invalid-request.
Deleted: Action wiring 21. Execution Contract Constituent failure 1 owns it.
Action wiring 22: The composition MUST NOT record a hold release intent BEFORE reading the hold through Legal Hold's read.
Action wiring 23: IF no hold EXISTS for the hold id THEN [Release Hold] MUST answer not-known.
Action wiring 24: IF the hold state EQUALS released THEN [Release Hold] MUST answer already-released.
Action wiring 25: An admitted hold release MUST call Legal Hold's release with the hold id, the releasing actor, the reason AND the supplied release instant, where the call supplies one (Primitive policy 11).
Action wiring 26: A committed hold release MUST record a hold released outcome carrying the hold id, the reason AND the release instant.
Action wiring 27: IF a committed hold release's outcome landed THEN [Release Hold] MUST answer released.
Action wiring 28: IF Legal Hold answers not-known THEN [Release Hold] MUST answer not-known.
Action wiring 29: IF Legal Hold answers already-released THEN [Release Hold] MUST answer already-released.
Action wiring 30: IF Legal Hold answers invalid-request THEN [Release Hold] MUST answer invalid-request.
Deleted: Action wiring 31. Execution Contract Constituent failure 1 owns it.
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
Deleted: Action wiring 42. Action wiring 111 owns it.
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
NOTE: open 2026-10-06-a — the order of the sibling purges, and the place of the call to the record destruction pattern among them, is unstated (Action wiring 59, Action wiring 112).
Action wiring 60: A committed purge MUST record a record purged outcome carrying the retention id, the record reference, the purged retention ids, the hold check result, the hold override AND the named retention's purge instant as purge instant.
Action wiring 61: A committed purge MUST mark a purged sibling purged in the purged retention ids.
Action wiring 62: A committed purge MUST mark a pending sibling pending in the purged retention ids.
Action wiring 63: IF a committed purge's outcome landed THEN [Purge Record] MUST answer ok.
Action wiring 64: IF Retention Window answers not-retained for the named retention THEN a purge MUST answer not-known.
Action wiring 65: IF Retention Window answers not-known for the named retention THEN a purge MUST answer not-known.
Action wiring 66: IF Retention Window answers retention-period-not-elapsed for the named retention THEN a purge MUST answer not-eligible.
Deleted: Action wiring 67. Execution Contract Constituent failure 1 owns it.
Action wiring 68: IF Retention Window answers a refusal for a sibling AND the refusal DOES NOT EQUAL not-retained THEN a purge MUST mark the sibling pending.
Action wiring 69: The composition MUST remove a purged retention from an index whatever the outcome record's answer.
Action wiring 70: The composition MUST alert on a destroyed record carrying an owed record.
Action wiring 71: A yielded invocation MUST NOT retry an owed record.
Action wiring 72: The sweep MUST own a yielded invocation's owed record.
Action wiring 73: A caller MUST read a not-known on a re-invoked purge as a committed destruction.
Action wiring 74: IF Legal Hold's read answers invalid-query THEN the composition MUST read the read as refused AND MUST alert.
Action wiring 75: The composition MUST answer hold-check-unavailable for a hold-record fault outside Legal Hold's read contract ahead of an act's first committing call.
Action wiring 76: A purge intent MUST carry the hold check result.
Action wiring 77: IF the database name a read of Legal Hold answers DOES NOT EQUAL the hold database name THEN the composition MUST read the read as refused (Legal Hold Instance 7).
Deleted: Action wiring 78. Action wiring 77 owns it.
Action wiring 79: IF an act's first committing call answers no answer THEN the action MUST answer storage-failure.
NOTE: open 2026-10-06-c — a storage-failure answers where nothing committed and where the call may still land, with nothing to tell the two apart (Execution Contract Constituent failure 1; Action wiring 16a, 79, 96).
Action wiring 80: IF Retention Window's purge answers no answer OR state-unavailable for a sibling THEN a purge MUST mark the sibling pending.
NOTE: watch the constituent's failed read (Action wiring 80).
Action wiring 81: IF the remaining term a sibling's reading answers DOES NOT EXCEED the sibling floor THEN a purge MUST mark the sibling pending.
Action wiring 82: A caller MUST retry a [Purge Record] that answered storage-failure (Retention Window Purge persistence 2).
Action wiring 83: IF an action's intent stands as an owed record THEN the action MUST answer recording-failure carrying intent.
Action wiring 84: IF an action's outcome stands as an owed record THEN the action MUST answer recording-failure carrying outcome.
Action wiring 85: IF a purge's gate record stands as an owed record THEN [Purge Record] MUST answer recording-failure carrying gate.
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
Action wiring 99: IF a read a committed act makes for the act's outcome answers a refusal OR state-unavailable OR no answer THEN the composition MUST read the outcome as an owed record.
Action wiring 100: A purge MUST NOT make the gate read BEFORE judging the not-known refusals of Action wiring 45 and Action wiring 94.
Action wiring 101: [Purge Eligible] MUST NOT answer a retention whose retention state Retention Window's declared read answers purged.
Deleted: Action wiring 102. Execution Contract Database 1 owns it.
Deleted: Action wiring 103. Execution Contract Database 1 owns it.
Deleted: Action wiring 104. Execution Contract Database 1 owns it: a hold placement's intent, hold and outcome commit together, and the composition names no read ahead of the intent for Legal Hold to refuse.
Deleted: Action wiring 105. Execution Contract Database 1 owns it: a placement's intent, act and outcome commit together, and the composition names no id list for a placement intent to carry.
Action wiring 106: A committed purge MUST read the named retention's purge instant from Retention Window's declared read.
Deleted: Action wiring 107. Execution Contract Database 1 owns it.
Action wiring 108: A purge MUST NOT record an intent BEFORE judging the refusals of Action wiring 47, Action wiring 50, Action wiring 53 and Action wiring 57.
NOTE: open 2026-10-05-j — the refusals ahead of the intent, not-known and not-eligible among them, and the take precede any check of the credential (Action wiring 44, Action wiring 45, Action wiring 94, Action wiring 108).
Action wiring 109: IF Retention Window's declared read answers state-unavailable OR no answer ahead of an act's first committing call THEN the action MUST answer storage-failure.
Action wiring 110: [Purge Eligible] MUST answer EVERY elapsed retention Retention Window's declared read answers, a retention Action wiring 95 covers AND a retention Action wiring 101 covers excepted.
Action wiring 111: IF Retention Window's declared read answers state-unavailable OR no answer to a call of [Purge Eligible] THEN the action MUST answer storage-failure.
NOTE: watch the constituent's failed read (Action wiring 98, Action wiring 109, Action wiring 111).
Action wiring 112: IF the remaining term the destruction call's reading answers EXCEEDS the sibling floor THEN a committed purge MUST call the record destruction pattern with the record reference.
Deleted: Action wiring 46. Composition state 19 owns it.
Deleted: Action wiring 51. Invariant 1.3 owns it.
```

Term intent: the record_action call naming what an invocation is about to do, written before any committing call — retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended.

Term outcome: the record_action call naming what an invocation did — retention_placed | hold_placed | hold_released | record_purged | intent_abandoned.

Term gate record: the purge_blocked_by_hold record a strict-mode refusal writes at the gate — a self-standing record, neither an intent nor an outcome.

Term committing call: `RetentionWindow.place_under_retention` | `RetentionWindow.purge` | `LegalHold.place` | `LegalHold.release` | a call to the record destruction pattern — a call that writes outside the audit instance.

Term admitted placement: a [Place Record Under Retention] call whose boundary predicate passed and whose intent landed.

Term admitted hold placement: a [Place Hold] call whose boundary predicate passed and whose intent landed.

Term admitted hold release: a [Release Hold] call whose boundary predicate passed, whose named hold's hold state EQUALS active and whose intent landed.

Term admitted purge: a [Purge Record] call whose boundary predicate passed, whose named retention is an elapsed retention, whose sibling set carries no retention outside elapsed retention, whose hold check admitted the destruction and whose intent landed.

Term committed placement: an admitted placement whose call of Retention Window's place_under_retention answered a retention id.

Term committed hold placement: an admitted hold placement whose call of Legal Hold's place answered a hold id.

Term committed hold release: an admitted hold release whose call of Legal Hold's release answered released.

Term committed purge: an admitted purge whose named retention's purge answered ok.

Term destroyed record: a record a purged retention of the business retention instance covers.

Term elapsed retention: a retention whose retention deadline does not exceed the injected now less the clock offset allowance — the eligibility predicate, derived at read time and never stored. The allowance is there because Retention Window judges a purge against the reading at its own seam: a sibling this composition read as elapsed on a reading ahead of that seam's would be destroyed with the record before the sibling's own deadline. So elapsed retention is stricter by one allowance than the eligibility Retention Window reads at its own seam, and on purpose: a retention whose deadline falls within one allowance of the now is eligible there and not yet elapsed here, and until the allowance has passed a purge that names it answers not-eligible, and a purge whose sibling it is answers under-active-retention (Action wiring 57, Action wiring 47). Retention Window's eligibility forbids a destruction where it answers no and obliges none where it answers yes (Retention Window Simultaneous retention 4), so the gate may refuse, for one allowance, what the constituent would allow.

Term hold check result: what Legal Hold's read answered at the gate — empty, or the blocking hold ids with the blocking count.

Term hold check admitted: said of a gate read whose hold check result stands empty, or stands non-empty under advisory mode.

Term hold-blocked: said of a retention [Purge Eligible] answers with a hold count above zero or with the unavailable sentinel.

Term eligibility tuples: the answer of [Purge Eligible] — for each answered retention, the retention id, the record reference, the retention deadline, the purge deadline and the hold count.

Term hold override: the field a record purged outcome carries — true where the hold check result stands non-empty under advisory mode, and false everywhere else.

Term hold count: the count of active holds over a retention's record that [Purge Eligible] answers, or the unavailable sentinel.

Term horizon alert: the alert a deployment admitting an unbounded hold raises, on the alerting surface, for a hold approaching the audit horizon (Capability requirement 13, Non-goal 23).

Term entry instant: the recording instant of a hold placement's intent — when the hold entered the system, as against the placement instant a caller may assert (Clock semantics 15). The intent and not the outcome, which the sweep may write long after.

Term quiescence: the state in which no invocation holds a record section, no open marker stands younger than the compensation window, and the sweep has no open marker and no pending sibling left to work. The quiescence of a cascade, which Check 8.1, Check 8.13 and Check 8.14 read, is not this state but Audit Trail's, said of one act (Audit Trail Term quiescence). An invariant stated at quiescence is owed by then and not at every instant before it: an owed outcome and a pending sibling are states the rules reach and the sweep closes (Action wiring 70, Reconciliation 11, Reconciliation 19).

Term unavailable sentinel: unavailable — the one non-integer value a hold count admits — what [Purge Eligible] answers for a retention whose hold records could not be read, and what a reader treats as hold-blocked rather than as zero.

Term purged retention ids: the named retention and every sibling set member a record purged outcome names, each marked purged or pending.

Term sweep: the reconciliation the Reconciliation rules state.

#### Closure table

Every input an action takes, and every answer a call of the two audit-instance actions and of the first half can meet — an action of [Audit Trail](./audit-trail.md) called inside another, a constituent's action or read, a read or write of this composition's own records, a lease, the erasure mechanism — with where the call lands it and the rule that owns the landing, in the form Audit Trail's closure table takes. A constituent call meets the answers its signature declares and the state-unavailable a failed read of the database gives every action (Execution Contract Read 1); a call that never answers is the lost answer of Execution Contract Error model 1, written no answer here (Term no answer, Audit Trail). The table covers the audit cascade, which moved here from Audit Trail; the five business actions' rows are owed (open line 2026-11-02-b).

**Inputs.** [Purge Eligible Events] takes none.

| Action | Input | Lands | Owner |
|---|---|---|---|
| [Purge Event] | an event id no constituent knows | not-known | purge event 1; purge event step 0.1a; Audit Trail Primitive policy 24 |

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
| | no holds returned: a failed read, an invalid-query or no answer | cascade-failure(hold), no cascade step | purge event 5e |
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
| | not-known | passed through unchanged | purge event step 1.3 |
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
| first | a Purged retention carrying its sequence number in purged events, the pair and a destroyed outcome | left alone | First half 3 |
| first | one of the three missing, at the read under the critical section keyed by event id as well | the cascade re-driven through [Purge Event] | First half 3, 5 through 7 |

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
purge eligible events 5: [Purge Eligible Events] MUST NOT answer a refusal, the storage-failure of a failed read (Action wiring 111) excepted.
purge eligible events 6: [Purge Eligible Events] MUST NOT filter by legal hold.
Deleted: purge eligible events 7. Execution Contract Error model 1 owns it: a declared read of Retention Window whose answer never arrives leaves [Purge Eligible Events] no answer to give, and none to read as an empty list.
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
   purge event step 1.3: [Purge Event] step 1 MUST pass Audit Trail's not-known through unchanged.
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
Deleted: Boundary one 1. Audit Trail record destruction step 2.9 owns it.
Boundary one 2: The composition MUST NOT condition RetentionWindow.purge's outcome on the erasure mechanism's answer.
Boundary one 3: The composition MUST record a divergence between a Purged retention and readable content.
Boundary one 4: The composition MUST surface a divergence as a compliance alert.
Boundary one 5: IF purge age EXCEEDS audit edge THEN an auditor MUST read a divergence as a residual finding against the erasure mechanism.
Deleted: Boundary one 6. First half 5 owns it.
```

Term divergence: a retention in *Purged* over content still readable — `cascade-failure(step-3)`; a destruction-failed outcome in erasure outcomes.

### Reconciliation

```
Reconciliation 1: The sweep MUST run at an instance's start.
Reconciliation 2: The sweep MUST run PER reconciliation cadence.
Reconciliation 3: The sweep MUST NOT store a record of the sweep's own.
Reconciliation 4: The sweep MUST NOT examine a young marker.
Reconciliation 5: The sweep MUST read an intent carrying no outcome AND no stand-in as an open marker.
Reconciliation 6: The sweep MUST match an intent to an outcome by the invocation id.
Reconciliation 7: The sweep MUST NOT match an intent to an outcome by an input.
Reconciliation 8: The sweep MUST read the constituent records for the act an open marker names.
Reconciliation 9: IF the act did not commit THEN the sweep MUST close the open marker as intent abandoned.
Deleted: Reconciliation 10. Execution Contract Database 1 owns it.
Reconciliation 11: IF the constituents' records carry EVERY datum a recovery outcome needs THEN the sweep MUST emit EXACTLY ONE recovery outcome PER committed act carrying no outcome.
Deleted: Reconciliation 12. Reconciliation 9 owns it.
Reconciliation 13: A recovery outcome MUST carry the candidate marker's invocation id.
Reconciliation 14: A recovery outcome MUST carry the candidate marker's actor reference as attributed actors.
Reconciliation 15: A recovery outcome MUST carry the recovery marker.
Deleted: Reconciliation 16. Reconciliation 14 owns it.
Reconciliation 17: The sweep MUST NOT emit a recovery outcome BEFORE recording a recovery intent.
Reconciliation 18: The sweep MUST NOT make a committing call BEFORE recording a recovery intent.
Reconciliation 19: The sweep MUST call Retention Window's purge PER pending sibling.
Reconciliation 20: The sweep MUST NOT close an open marker BEFORE taking the record section over the record the open marker names.
Reconciliation 21: The sweep MUST read the constituent records AND the open markers over the record again under the record section.
Reconciliation 22: The sweep MUST NOT emit a recovery outcome for an act already carrying an outcome.
Reconciliation 23: The sweep MUST NOT examine an aged-out event.
Reconciliation 24: The sweep MUST read a constituent's records' own state for an act an aged-out event names.
Reconciliation 25: The sweep MUST alert on an open marker the compensation window did not close.
Reconciliation 26: The sweep MUST NOT emit a datum no constituent's records carry.
Reconciliation 27: IF a constituent's records carry no datum a recovery outcome needs THEN the sweep MUST close the open marker as intent abandoned.
Reconciliation 28: The sweep MUST read the record a hold release marker names from Legal Hold's read.
Reconciliation 29: The sweep MUST read the record a purge marker names from Retention Window's declared read.
Reconciliation 30: IF Lease's try_take answers held OR no answer THEN the sweep MUST leave the open marker to the next run.
Reconciliation 31: The sweep MUST NOT record a recovery intent BEFORE taking the record section.
Reconciliation 32: A reader MUST NOT read an abandoned purge intent as the record standing undestroyed (Retention Window Purge persistence 1a).
Reconciliation 33: IF a read the sweep makes answers a refusal OR state-unavailable OR no answer THEN the sweep MUST leave the open marker to the next run.
Reconciliation 34: A recovery outcome of a purge MUST carry the hold check result of the purge intent whose invocation id the outcome carries.
Reconciliation 35: A recovery outcome of a purge MUST carry the purge instant of the candidate marker's named retention from Retention Window's declared read as purge instant.
Reconciliation 36: IF an open marker over the record stands as a young marker THEN the sweep MUST leave EVERY open marker over the record to the next run.
NOTE: open 2026-10-05-i — a mandated retry has no terminus, and each retry's young marker parks every older marker over the record (Reconciliation 36).
Reconciliation 37: An intent abandoned outcome MUST carry the closed marker's invocation id.
Reconciliation 38: A recovery outcome of a purge MUST carry EVERY retention Retention Window's declared read answers over the record in the purged retention ids, a purged retention marked purged AND a retained retention marked pending.
Reconciliation 39: IF the hold check result a recovery outcome of a purge carries stands non-empty THEN the recovery outcome MUST carry the hold override.
Reconciliation 40: IF the record section admits no call a leg issues OR a leg's committing call answers a refusal OR state-unavailable OR no answer THEN the sweep MUST leave the leg's remaining work to the next run.
Reconciliation 41: The sweep MUST read the pending siblings from Retention Window's declared read on EVERY run.
Reconciliation 42: The sweep MUST leave an intent carrying a stand-in.
Reconciliation 43: A run MUST NOT take a record section BEFORE alerting on EVERY overdue marker the run's enumeration answers.
Reconciliation 44: IF the read a run enumerates the open markers from answers a refusal OR state-unavailable OR no answer THEN the sweep MUST alert.
Reconciliation 45: A recovery intent MUST carry the record reference AND the plan.
```

Term open marker: an intent carrying no outcome under the intent's own invocation id and no stand-in — an invocation that committed nothing, committed and failed to record, or died between the two. An open marker takes its act's name from its intent: an open purge marker, the purge marker of Reconciliation 29, is an open marker whose intent is a purge_intended record, an open release marker, the hold release marker of Reconciliation 28, one whose intent is a hold_release_intended record, an open placement marker one whose intent is a retention_placement_intended record, and an open hold placement marker one whose intent is a hold_placement_intended record.

Term destroyed event: an event whose payload the audit instance has destroyed. The log still answers the event's sequence number and recording instant, and Audit Trail's read answers the attestation's action reference (Audit Trail read record step 4.4a).

Term stand-in: a destroyed event that may be the missing half of a pairing, answering an action reference the missing record could carry. For an intent that carries no outcome it is a destroyed event later in the log. For an outcome that carries no intent it is a destroyed event earlier in the log whose recording instant stands within the retention completion bound, taken with the clock offset allowance, of the outcome's own — an invocation writes its outcome within the bound or yields — and, where the service identity attested the outcome, any destroyed event earlier in the log, since the sweep writes a recovery outcome or an intent abandoned for a marker of any age short of the horizon (Composes 16). The invocation id went with the payload, so the trail cannot say whether the missing record was written; a pairing with a stand-in reads unknown and never open, orphaned or failed.

Term young marker: an open marker whose intent instant stands within the retention completion bound, taken with the clock offset allowance, of the injected now.

Term aged-out event: an event whose age — the injected now less the event's `recorded_at` — exceeds the audit horizon. No clock decides the edge alone: an intent short of the edge whose outcome the audit instance has already destroyed carries a stand-in and is no open marker (Term stand-in).

Term recovery intent: the `retention.recovery_intended` record the sweep writes before a leg commits or re-emits — one per leg, carrying the record reference and the plan (Reconciliation 45). A closing as intent abandoned takes none. A recovery intent is none of Term intent's four kinds, so it opens no marker and takes no outcome (Invariant 5.2); the purges of a sibling-purge leg are the named purge's act (Term candidate marker) and owe no recovery outcome of their own.

Term plan: re-emit | sibling-purge — what a leg is about to do: emit the recovery outcomes the record's candidate markers are owed, or purge the record's pending siblings.

Term leg: the sweep's handling of the open markers over one record, under one grant of the record section.

Term recovery marker: the marker a recovery outcome carries so a reader tells a clean act from a recovered one.

Term recovery outcome: the outcome the sweep emits for a committed act whose own invocation did not record one.

Term intent abandoned: intent_abandoned — the outcome the sweep writes over an open marker whose act it does not recover (Reconciliation 9, Reconciliation 27).

Term attributed actors: the actor reference of the candidate marker, carried by a recovery outcome (Reconciliation 14).

Term log order: the order of the substrate's sequence numbers. Wherever a rule or a term of this composition says an event is earlier, later, the next or the latest, it means in log order and never by an instant an event carries: two seams' instants may stand an allowance apart, and the record section is what orders two acts over one record.

Term candidate marker: the open marker that committed the act, a young marker included — which is why a run that meets a young marker over a record leaves every marker over the record (Reconciliation 36). An open marker that is no candidate marker did not commit. Over a hold release it is the latest open release marker over the hold in log order, where the hold stands released and no hold released outcome names it. Over a purge it is the latest open purge marker in log order over the **record**, where the record stands as a destroyed record and no record purged outcome names it: a record is destroyed once, whichever of its retentions the call named, and a retention purged as a sibling under another marker is that marker's act. In both, each act reads its pre-state again under the record section (Concurrency 27, Concurrency 28), so a call that follows the commit records no intent, and every earlier marker failed before the commit. A placement and a hold placement read no pre-state that refuses a second call over the record, so a call that follows the commit records an intent of its own, and log order alone names no candidate. Over a placement it is an open placement marker over the record whose intent carries the policy reference of a retention over the record whose placement stands within the audit horizon and that no retention placed outcome names. Over a hold placement it is an open hold placement marker over the record whose intent carries the placing actor, the reason and the case reference, or no case reference where the hold carries none, of a hold over the record whose placement stands within the audit horizon and that no hold placed outcome names, and carries the hold's placement instant where the call supplied one. That match pairs an intent with a constituent's record by the inputs the intent carries (Action wiring 6), never an intent with an outcome (Reconciliation 7). Where those data answer several markers and several records alike, the latest marker in log order answers for the latest record — by retention instant for a retention, in Legal Hold's read order for a hold — the next latest for the next, and every marker left over failed before a commit: a caller retries a refused call (Action wiring 96), so the retry follows the failure it repeats.

#### First half — the half-completed cascade

*First half — the half-completed cascade.*

```
First half 1: The first half MUST enumerate Purged retentions.
First half 2: IF purge edge EXCEEDS purge age THEN the first half MUST NOT examine the retention.
First half 3: The first half MUST test EVERY examined retention for a purged events membership, a pair in the destruction record, and a destroyed outcome in erasure outcomes.
Deleted: First half 4. First half 3 owns it.
First half 5: The first half MUST re-drive a retention failing First half 3 through [Purge Event].
First half 6: The first half MUST NOT re-read the predicate BEFORE taking the critical section keyed by event id.
First half 7: The first half MUST NOT write BEFORE re-reading the predicate under the critical section.
Deleted: First half 8. First half 5 owns it.
First half 9: IF a re-drive lands under-legal-hold THEN the first half MUST leave the entry open and MUST NOT count the entry against Audit Trail's compensation window.
First half 10: The first half MUST re-drive an entry left open under a hold on the first run after the hold is released.
First half 11: IF a hold over an open entry is released THEN the first half MUST count the entry's Audit Trail compensation window from the instant of the first run that reads no active hold over the event, AND MUST NOT count the window from a release instant the Legal Hold records carry, which a caller may have supplied and backdated (Legal Hold Operation 39, Operation 41).
First half 12: The first half MUST take as upper edge the retention policy of the audit instance the first half reads, under which the Purged retention (Retention Window Invariant 10.1), the seal record (Audit Trail retention policy 5), the destruction record and the erasure outcome (Execution Contract Database 3, Execution Contract Database 4) stand indefinitely.
First half 13: The first half MUST NOT record an audit.reconciliation event.
```

NOTE: open 2026-08-30-d — a divergence whose erasure mechanism only ever answers destruction-failed, breaking erasure mechanism 10, is re-driven run after run (First half 5) and has no terminus; past the audit edge it is a residual finding against the mechanism (Check 8.12).

Term suspended entry: an open entry a run landed under-legal-hold, from that run until a later run reads no active hold over the event — the entry First half 9 leaves uncounted and Invariant 12.1 restarts.


Term purge edge: `(purge_completion_bound + clock_offset_allowance)`.

Term purge age: `(now - purged_at)`.

---

## Composition-level invariants

Each emerges from the composition; none belongs to one constituent.

- **Invariant 1 — Hold-blocks-purge.**
  ```
  Invariant 1.1: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN the composition MUST NOT call Retention Window's purge.
  Invariant 1.2: IF an active hold covers a record outside the destroyed records AND the hold check mode EQUALS strict THEN a purge MUST NOT answer ok.
  Invariant 1.3: The composition MUST NOT read unreadable hold records as an empty hold check result.
  Deleted: Invariant 1.4. Wiring decision 1 owns it.
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
  Invariant 3.1: EVERY committed hold placement that stands within the audit horizon MUST carry a hold placed outcome at quiescence.
  Invariant 3.2: EVERY committed hold release that stands within the audit horizon MUST carry a hold released outcome at quiescence.
  Invariant 3.3: A hold placed outcome MUST carry the hold id, the record reference AND the placing actor.
  Invariant 3.4: The composition MUST NOT claim a hold lifecycle reconstructible from an aged-out event.
  Invariant 3.5: The composition MUST NOT claim a tamper-evidence over the substrate's unsealed tail.
  ```
- **Invariant 4 — Retention-decision audit coverage.**
  ```
  Invariant 4.1: EVERY committed placement that stands within the audit horizon MUST carry a retention placed outcome at quiescence.
  Invariant 4.2: EVERY committed purge that stands within the audit horizon MUST carry a record purged outcome at quiescence.
  Invariant 4.3: EVERY purge that answered under-legal-hold MUST carry a gate record.
  Invariant 4.4: A record purged outcome MUST carry the hold check result.
  Invariant 4.5: A gate record MUST carry the blocking hold ids AND the blocking count.
  Invariant 4.6: The composition MUST NOT record an outcome for a refusal no intent preceded.
  ```
- **Invariant 5 — Audit completeness modulo the substrate's partial-attestation contract.**
  ```
  Invariant 5.1: EVERY outcome MUST follow an intent carrying the outcome's invocation id.
  Invariant 5.2: An intent carrying no outcome AND no stand-in MUST stand as an open marker.
  Invariant 5.3: The composition MUST NOT read an open marker as a conformance failure.
  Invariant 5.4: A gate record MUST NOT follow an intent.
  Invariant 5.5: EVERY admitted invocation MUST record EXACTLY ONE intent.
  Invariant 5.6: An admitted invocation MUST NOT record two outcomes.
  Invariant 5.7: EVERY intent carrying no stand-in MUST carry EXACTLY ONE outcome at quiescence, an aged-out event AND a destroyed event excepted.
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
  Deleted: Invariant 7.4. Action wiring 53 owns it.
  ```
- **Invariant 8 — Defensible destruction.**
  ```
  Invariant 8.1: EVERY surviving destruction MUST carry a record purged outcome naming the hold check result at quiescence.
  Invariant 8.2: EVERY destroyed record MUST carry a retention whose retention state EQUALS purged.
  Invariant 8.3: A destroyed record's retention deadline MUST NOT EXCEED the retention's purge instant.
  Invariant 8.4: A record purged outcome MUST carry a seal ONLY AFTER the seal coverage.
  Invariant 8.5: A reader MUST read an unverifiable partially-purged-coverage answer as unknown.
  Invariant 8.6: The composition MUST NOT claim a defensibility resting on an aged-out event.
  ```
- **Invariant 9 — Cross-retention joint enforcement.**
  ```
  Invariant 9.1: IF the sibling set carries a retention outside elapsed retention THEN the composition MUST NOT destroy the record.
  Invariant 9.3: The composition MUST NOT leave a sibling retained over a destroyed record at quiescence.
  Invariant 9.4: A pending sibling MUST stand named in the record purged outcome.
  Invariant 9.5: The gate MUST NOT rest on the audit horizon.
  Deleted: Invariant 9.2. Composition state 19 owns it.
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

  NOTE: open 2026-08-30-d — a cascade whose erasure mechanism only ever answers destruction-failed, breaking erasure mechanism 10, stands at quiescence in none of Audit Trail Invariant 8.1a's three standings; past the audit edge it is a residual finding against the mechanism (Check 8.12).

  *Rests on:* [Purge Event] steps 0, 1 and 4; Audit Trail Invariant 8, whose three standings (retained, lawfully destroyed, held) this invariant completes for a destroyed event; Retention Window Invariants 1, 3 and 10.

---

## Examples

### Walkthrough — regulated bank under SOX section 802 and FRCP Rule 37(e)

A multinational bank governs its general-ledger transaction records with this instance. The deployment sets `hold_check_mode = strict` and configures the audit instance with a twelve-year policy against a seven-year business policy, a longest hold of four years and a purge delay of thirty days, so the evidence floor sits inside the audit horizon.

1. **Retention placed.** `place_record_under_retention("txn-2026-0441", "sox_7_year", "records_system", credential)`. The boundary predicate passes; a retention_placement_intended record lands carrying `invocation_id: inv-a1`, the two references and intent instant; `RetentionWindow.place_under_retention` answers `ret-0441` with `retention_until = 2033-05-10`; a retention_placed outcome lands carrying `inv-a1`, the retention and both deadlines. Returns `ret-0441`.

2. **Litigation anticipated.** Three years later: `place_hold("txn-2026-0441", "counsel_morgan", credential, "Litigation hold — anticipated class action re Q3 2026 operations", "matter-2029-morgan")`. Intent, then `LegalHold.place` answering `hold-0441-a`, then the hold_placed outcome. Returns `hold-0441-a`.

3. **Retention window elapses.** In 2033 `purge_eligible()` answers `ret-0441` with `hold_count = 1` — hold-blocked, not purge-ready. A records-management job calls `purge_record("ret-0441", "records_system", credential)` anyway. The sibling set is empty; the gate reads one active hold; the mode is strict, so a purge_blocked_by_hold gate record lands carrying `inv-b7`, the retention, the record and `{hold_ids: ["hold-0441-a"], count: 1}`, and the call answers `under-legal-hold(["hold-0441-a"], 1)`. **No intent record is written on this path** — the gate record precedes it and verifies the same credential — and nothing is destroyed.

4. **Litigation settles.** `release_hold("hold-0441-a", "counsel_morgan", credential, "Class action settled — May 2033")`. The pre-intent read finds the hold active; intent, `LegalHold.release`, hold_released outcome. Returns released.

5. **Purge proceeds.** `purge_eligible()` now answers `ret-0441` with `hold_count = 0`. `purge_record("ret-0441", "records_system", credential)`: the sibling set is empty, the gate reads no active hold, the named retention is elapsed, a purge_intended record lands carrying `inv-c2`, `RetentionWindow.purge` stands `ret-0441` purged, the record destruction pattern destroys the record, and a record_purged outcome lands carrying `inv-c2`, `purged_retention_ids: [{ret-0441, purged}]`, `hold_check_result: empty`, `hold_override: false` and `purge_instant: 2033-05-15`. The two index entries are removed. Returns ok.

6. **SOX section 404 audit.** The auditor walks `Check 1.1` through `Check 7.3` over the trail and the two constituent records. The full arc reads: placement intent, placement, hold intent, hold, blocked purge, release intent, release, purge intent, purge. `verify_record` answers `verified` on each outcome the seal cadence covers. The auditor confirms that no destruction occurred while the hold was active, that the destruction landed inside the allowable window — retention deadline at or before `purged_at`, and `purged_at` below purge deadline — and that every act was attributed to a named actor whose credential the substrate verified before the act committed.

### A sibling retention blocks, then travels with the destruction

The same record acquires a second retention in 2030 under a policy transition: `place_record_under_retention("txn-2026-0441", "ledger_6_year", "records_system", credential)` → `ret-0441-b`, `retention_until = 2036-05-10`. In 2033, with the hold released, `purge_record("ret-0441", …)` reads the sibling set from Retention Window's records, finds `ret-0441-b` outside elapsed retention, and answers under-active-retention — nothing destroyed, no intent written. In 2036 the same call finds both elapsed, destroys the record once, purges `ret-0441-b` in the same invocation, and records `purged_retention_ids: [{ret-0441, purged}, {ret-0441-b, purged}]`. Had the second purge answered storage-failure, the outcome would name it pending, `Check 3.3` would read it as an open obligation rather than a finding, and `Reconciliation 19` would retry it until the database reports it purged.

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

**Breach forensics — *was a preservation-deferred record improperly destroyed?*** The team reads the trail for record_purged outcomes naming the suspect record. None means the record was not destroyed through this composition, and the investigation moves to direct atom-level or storage-layer access — the bypass case `Check 3.4` signals. One means the `hold_check_result` and the historical hold predicate answer the question directly. The forensic window is bounded by the seal cadence below and by the audit horizon above, and `Invariant 8.6` is where that bound is stated rather than assumed.

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
Check 1.6: An auditor MUST find EVERY hold a gate record names in the hold records, released by no release whose own intent sits earlier in the log than the gate record (Invariant 4.5).
Check 1.7: An auditor MUST read Legal Hold's read unfiltered by hold state for the historical hold set (Invariant 6.3).
Check 1.8: An auditor MUST read a pre-destruction release as outside the historical hold set (Invariant 6.5).
Check 1.9: An auditor MUST read a truncated hold check result's count as naming the members the list omits (Primitive policy 21).
Check 1.10: An auditor MUST read an aged-out hold as unknown for Check 1.3 (Invariant 3.4).
Check 1.11: An auditor MUST read Check 1.3 over a record carrying an open marker inside the compensation window as an open obligation (Invariant 5.3).
Check 2.1: An auditor MUST find a hold placed outcome PER hold whose placement stands within the audit horizon (Invariant 3.1).
Check 2.2: An auditor MUST find a hold released outcome PER released hold whose release stands within the audit horizon (Invariant 3.2).
Deleted: Check 2.3. Check 2.4 owns it.
Check 2.4: An auditor MUST read an aged-out hold as covered by the count of surviving attestations alone (Invariant 3.4).
Check 2.5: An auditor MUST find Audit Trail's verify_record answering verified PER outcome the seal cadence covers, an outcome Check 2.6 covers AND an outcome Check 2.7 covers excepted (Invariant 3.5).
Check 2.6: An auditor MUST read a failed-verification carrying purged as a lawful destruction (Invariant 3.4).
Check 2.7: An auditor MUST read an unverifiable partially-purged-coverage answer as unknown (Invariant 8.5).
Check 3.1: An auditor MUST find a retention placed outcome PER retention whose placement stands within the audit horizon (Invariant 4.1).
Check 3.2: An auditor MUST find a record purged outcome naming EVERY purged retention over a surviving destruction (Invariant 4.2).
Check 3.3: An auditor MUST read a retained retention a record purged outcome names pending as an open obligation (Invariant 9.4).
Check 3.4: An auditor MUST read a purged retention over a surviving destruction that carries no record purged outcome AND no open purge marker as a bypass finding (Composition state 24).
Check 3.5: An auditor MUST read a retained retention over a destroyed record carrying no pending mark AND no open purge marker as a conformance failure (Invariant 9.3).
Check 3.6: An auditor MUST select a retention a committed placement covered PER the rebuild (Composition state 12).
Check 3.7: An auditor MUST find no retention over a destroyed record carrying a retention deadline the destruction's purge instant does not reach (Invariant 9.1).
Check 4.1: An auditor MUST reconstruct a retention's lifecycle from the retention placed outcome, the hold outcomes AND the record purged outcome (Invariant 8.1).
Check 4.2: An auditor MUST join a hold to a retention by the record reference (Composition state 29).
Check 5.1: An auditor MUST find an intent preceding EVERY outcome in the substrate's own sequence (Invariant 5.1).
Check 5.2: An auditor MUST find an outcome's intent carrying the outcome's invocation id (Invariant 5.1).
Check 5.3: An auditor MUST find the intent of EVERY outcome a calling actor attested carrying the outcome's actor reference (Composes 15).
Check 5.4: An auditor MUST read an outcome carrying no intent AND no stand-in as a conformance failure (Invariant 5.1).
Check 5.5: An auditor MUST read an intent carrying no outcome AND no stand-in as an open marker (Invariant 5.2).
Check 5.6: An auditor MUST read a gate record carrying no intent as conformant (Invariant 5.4).
Check 5.7: An auditor MUST find no two outcomes sharing one invocation id (Invariant 5.6).
Check 5.8: An auditor MUST read an outcome carrying the recovery marker as the sweep's own (Reconciliation 15).
Check 5.9: An auditor MUST read an outcome missing under an open marker inside the compensation window as an open obligation (Invariant 5.3).
Check 5.10: An auditor MUST find no two intents sharing one invocation id (Capability requirement 63).
Check 6.1: An auditor MUST find the evidence floor not exceeding the audit horizon (Capability requirement 11).
Check 6.2: An auditor MUST find the rebuild reading Retention Window's records for an entry a purged placement event covers (Composition state 13).
Check 6.3: An auditor MUST read an audit horizon below the evidence floor as a conformance failure (Capability requirement 11).
Check 6.4: An auditor MUST read a record missing from the trail whose act does not stand within the audit horizon as unknown (Invariant 8.6).
Check 6.5: An auditor MUST read an outcome carrying no intent AND a stand-in as unknown for Check 5.1 through 5.3 (Invariant 8.6).
Check 6.6: An auditor MUST read an intent carrying no outcome AND a stand-in as unknown for Check 5.9 (Invariant 8.6).
Check 6.7: An auditor MUST read a hold's order against a destruction whose purge intent the trail does not carry as unknown for Check 1.3, Check 1.4 AND Check 1.8 (Invariant 8.6).
Check 6.8: An auditor MUST find the audit horizon exceeding the alert floor (Capability requirement 58).
Check 6.9: An auditor MUST read a hold's order against a destruction as unknown for Check 1.3, Check 1.4 AND Check 1.8 where the trail does not carry the intent of the hold's own outcome (Invariant 8.6).
Check 7.1: An auditor MUST clear Legal Hold's own acceptance over the hold records (Composes 5).
Check 7.2: An auditor MUST clear Retention Window's own acceptance over the business retention instance (Composes 5).
Check 7.3: An auditor MUST clear Audit Trail's own acceptance over the audit instance (Composes 6).
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
External check 5: An auditor needing the service identity's provisioning confirmed MUST read the substrate's actor registry (Capability requirement 17, Capability requirement 18).
External check 6: An auditor needing a declared setting confirmed MUST read the deployment's own declaration (Capability requirement 10, Capability requirement 12, Capability requirement 14 through 16, Capability requirement 19 through 25, Capability requirement 27 through 30, Capability requirement 36, Capability requirement 38 through 44, Capability requirement 57 through 62, Capability requirement 64).
External check 7: An auditor needing the serialization confirmed MUST read the deployment's own Lease host (Capability requirement 37).
External check 8: An auditor needing a record's fate under an abandoned purge intent confirmed MUST read the deployment's own destruction records (Reconciliation 32, Capability requirement 55).
External check 9: An auditor needing the single surface confirmed MUST read the deployment's own access control over the hold records and the business retention instance (Capability requirement 45 through 47, Capability requirement 53).
External check 10: An auditor needing the call pause bound confirmed MUST read the deployment's own constituent clients (Capability requirement 38, Capability requirement 54).
External check 11: An auditor needing the hold database name confirmed MUST read the deployment's own declaration (Capability requirement 48).
Deleted: External check 12. Execution Contract Database 3 owns it.
External check 13: An auditor needing the alerting surface confirmed MUST read the deployment's own alert records (Capability requirement 13, Capability requirement 50).
Deleted: External check 14. Execution Contract Scheduled leg 1 owns it.
External check 15: An auditor MUST clear from external evidence that the erasure mechanism was authorized to destroy, shreds, and completed each destruction.
External check 16: IF Legal Hold EQUALS composed THEN an auditor MUST clear from the deployment's own concurrency control that a hold placement over an event id and a cascade on that event id serialize, the placement a bounded holder of the section, that no hold over an event id of this instance is placed outside the hold placement, and that the placement gate bounds the hold placements over an open entry to one displacement of the entry's first-half leg WITHIN compensation window of the finding's creation (Capability requirement 69a, 69b, 69c, 69d, 69e, 69g, 69i).
External check 17: An auditor MUST clear from the deployment's own lock that the cascade's critical section is a lease of the act's completion bound, a [Purge Event] re-driven by the first half excepted, and for a hold placement, shared by every process serving the instance, keyed by the event id namespaced by the act's kind, held under a holder value minted fresh for each attempt, and not released early by an abandoned call (Audit Trail Per-act critical section 1, 1a, 1b, 1c, Cascade critical section 1, 4a, 5).
External check 18: An auditor MUST clear from the deployment's own sweep that the purge sweep calls [Purge Event] over the eligible list (purge eligible events 8).
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
Non-goal 17: The composition MUST NOT record an outcome for a rejection outside the gate, an intent abandoned excepted.
Non-goal 18: A deployment needing an attempted-action record MUST compose a Failed-Attempt Log pattern.
Non-goal 19: The composition MUST NOT govern a Legal Hold record's own retention.
Deleted: Non-goal 20. Capability requirement 69 owns it: this composition gates the audit instance's cascade, which moved here from Audit Trail.
Non-goal 21: The composition MUST NOT keep an aged-out event.
Non-goal 22: A deployment whose hold outlives the audit horizon MUST hold the audit events proving the hold through the hold placement of Capability requirement 69g.
Non-goal 23: A deployment that admits an unbounded hold MUST alert for a hold approaching the audit horizon (Capability requirement 13, Term horizon alert).

NOTE: open 2026-11-04-c — Non-goal 23 declares no threshold for approaching the audit horizon, so which hold the alert reads is unstated.
Non-goal 24: The composition MUST NOT resolve a record reference rename.
Non-goal 25: The composition MUST NOT place a hold set in one call.
Non-goal 26: The composition MUST NOT release a hold set in one call.
Non-goal 27: A deployment needing a bulk hold change MUST own the loop over [Place Hold] and [Release Hold].
Non-goal 28: The composition MUST NOT hold an idempotence key for a placement.
Non-goal 29: A deployment needing an at-most-once placement MUST compose Duplicate Prevention.
Non-goal 30: The composition MUST NOT place a hold; the deployment owns the hold placement and the placement's gate (Capability requirement 69).
```

NOTE: the owners — Policy Reconciliation *(forthcoming)* (Non-goal 1, Non-goal 2); the deployment (Non-goal 8; Non-goal 25 through 27); [Permissions](../atoms/permissions.md) and the deployment (Non-goal 9 through 12, Composition note 3 through 5); Shred *(forthcoming)* (Non-goal 15, Non-goal 16); a Failed-Attempt Log *(forthcoming)* (Non-goal 17, Non-goal 18); the deployment (Non-goal 22, Non-goal 23); Reverse Index *(forthcoming)* (Composes 14); Override Authorization *(forthcoming)* (Capability requirement 33).

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
Atomic writes 5: An admitted purge MUST record the outcome ONLY AFTER the constituent commit.
Atomic writes 6: The composition MUST NOT reverse Retention Window's purge.
Atomic writes 7: A destroyed record carrying an owed record MUST stand as the composition's own partial.
Atomic writes 8: The composition MUST read a storage-failure from Retention Window's purge as the retention standing retained (Retention Window Purge persistence 1).
Atomic writes 9: The composition MUST NOT read a storage-failure from Retention Window's purge as the record standing undestroyed (Retention Window Purge persistence 1a).
```

### Clock semantics

```
Clock semantics 4: The composition MUST judge elapsed retention against the injected now.
Deleted: Clock semantics 2. Action wiring 8 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Action wiring 106 owns it.
Clock semantics 5: The composition MUST judge a sibling set member's eligibility against the injected now.
Deleted: Clock semantics 6. Composes 18 owns it.
Deleted: Clock semantics 7. Retention Window Operation 13 owns it.
Deleted: Clock semantics 8. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 9. Execution Contract Logic confinement 12 owns it.
Deleted: Clock semantics 10. Event Log Operation 2 owns it, reached through Audit Trail.
Clock semantics 11: A reader MUST read a record purged outcome's purge instant as the instant Retention Window stamped the purge.
Deleted: Clock semantics 12. Action wiring 106 owns it.
Deleted: Clock semantics 13. Action wiring 106 owns it.
Clock semantics 14: The composition MUST NOT read a supplied placement instant as the entry instant.
Clock semantics 15: A reader MUST read the recording instant of a hold placement's intent as the entry instant.
Clock semantics 16: The gate MUST NOT read a clock.
Deleted: Clock semantics 17. Capability requirement 36 owns it.
```

Term clock offset allowance: clock offset allowance — the deployment's declared envelope between two seams' readings of one moment — what this composition allows wherever a reading at its own seam is set against an instant another seam stamped (Term elapsed retention, Term young marker).

Term constituent commit: the instant a committing call's write lands in the constituent's own records.

Term gate read: the composition's read of a record's active holds at [Purge Record], taken before any destruction.

Term seal coverage: the point at which the substrate's seal cadence covers an event.

Term yielded invocation: an invocation whose grant of the record section has ended or reads expired — past which the invocation writes nothing more and the owed record is the sweep's.

Term post-destruction hold: a hold whose hold_placed outcome's own intent sits later in the log than the purge intent of the record's destruction.

Term pre-destruction release: a hold whose hold state EQUALS released and whose hold released outcome, or that outcome's own intent, sits earlier in the log than the purge intent of the record's destruction.

Term aged-out hold: a hold carrying no surviving hold_placed outcome whose placement does not stand within the audit horizon, or a released hold carrying no surviving hold_released outcome whose release does not stand within the audit horizon — a hold whose order against a destruction the trail can no longer state.

Term historical hold set: the holds over a destroyed record that Legal Hold's read answers unfiltered by hold state, less every post-destruction hold, every pre-destruction release and every aged-out hold — the holds the destruction's gate read met, as far as the surviving trail can say.

### Concurrency

```
Deleted: Concurrency 1. Concurrency 5 owns it.
Deleted: Concurrency 2. Concurrency 5 owns it.
Deleted: Concurrency 3. Concurrency 5 owns it.
Concurrency 4: Two sweeps MUST NOT emit two outcomes for one act.
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
Concurrency 15: The composition MUST make a committing call WITHIN the call pause bound of asking for the call's reading (Lease Sizing 3a).
Concurrency 16: The composition MUST take one reading of Lease's remaining PER record_action call under the record section (Lease Sizing 5b).
Concurrency 17: The composition MUST issue a record_action call under the record section ONLY IF the record start floor admits the call (Lease Sizing 5).
Concurrency 18: IF a lease call answers no answer THEN the composition MUST read the lease reading as expired for the rest of the grant (Lease Sizing 7).
Concurrency 19: The composition MUST NOT issue a second time, under one grant, a call that answered no answer (Lease Sizing 8).
Concurrency 20: IF the lease reading EQUALS expired ahead of an act's first committing call AND the act carries no owed record THEN the action MUST answer section-unavailable.
Concurrency 21: IF the record start floor admits no first call of an act's first record_action THEN the action MUST answer section-unavailable.
Concurrency 22: IF a call in flight EXISTS under the grant THEN the composition MUST NOT release the record section (Lease Composition note 5c).
Concurrency 23: The composition MUST NOT issue a write under a grant the composition released (Lease Composition note 5f).
Concurrency 24: IF no record_action under the record section answers recording-failure carrying step-3 THEN the composition MUST release the record section ONLY AFTER the act's last call answered.
Concurrency 25: IF a record_action under the record section answers recording-failure carrying step-3 THEN the composition MUST NOT release the record section.
NOTE: open 2026-10-31-a — Audit Trail now commits nothing on a recording-failure carrying step-3, so the append still to land that this hold and Audit arm 2 wait on is its earlier contract (Concurrency 24, Concurrency 25, Audit arm 2, Audit arm 16).
Concurrency 26: A placement MUST NOT read the record's retentions BEFORE taking the record section.
Concurrency 27: A purge MUST NOT record an intent BEFORE reading the retention state of EVERY retention over the record under the record section.
Concurrency 28: The composition MUST NOT record a hold release intent BEFORE reading the hold's hold state under the record section.
Concurrency 29: The composition MUST issue a record_action call WITHIN the call pause bound of asking for the call's reading.
Concurrency 30: The composition MUST namespace the record section's key apart from EVERY other key on the Lease host (Lease Composition note 4).
Concurrency 31: The composition MUST read under the record section EVERY database state AND EVERY trail state the composition decides on, a call of [Purge Eligible] excepted.
Concurrency 32: A read made ahead of the take MUST serve to name the record section's key alone, a not-known for an id no database carries AND the alert of Reconciliation 43 excepted.
Concurrency 33: An act whose EVERY call answered MUST release the record section, a call Concurrency 25 covers excepted.
Concurrency 34: IF the record section admits no call of a committed act's outcome THEN the composition MUST read the outcome as an owed record.
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
Composition note 6: A deployment MUST act on the sweep's escalation.
Composition note 7: A deployment MUST act on a destroyed record carrying an owed record.
Composition note 8: A deployment MUST own the release of a hold the deployment's own authority overrode.
Composition note 9: A deployment MUST surface an active hold over a destroyed record.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**, and carries no obligation of its own.

### Vocabulary

Term actors: the composition; a deployment; the host; the transition; the seam; the sweep; a caller; an auditor; a reader; an implementation; an invocation; an action; an intent; an outcome; a gate record; an open marker; a young marker; a recovery intent; the gate; the rebuild; an index; the record-to-retentions index; the retention-to-record index; a record; a retention; a sibling; a pending sibling; a hold; a hold check result; a hold count; a placement; a hold placement; a hold release; a purge; a release; a destruction; a record destruction pattern; a committing call; a landed record; an owed record; an aged-out event; a surviving placement event; a purged placement event; a field cap; the evidence floor; the closure floor; the audit horizon; a policy; the record section; the section term; the section work bound; the record start floor; Legal Hold; Retention Window; Audit Trail; Event Log; a presenter; a presentation; a hold id list; a truncated hold id list; a divergence; two sweeps; a renamed record; the cascade; the first half; the erasure mechanism; an open entry; a closed entry; a suspended entry; the audit retention instance.

Term record verbs: serve, change, inherit, read, hold, reach, call, gate, select, query, attest, govern, store, add, remove, leave, stand, rest, admit, drop, report, agree, cover, name, carry, claim, supply, mint, accept, configure, declare, wire, set, provision, rotate, disclose, start, run, resolve, reconcile, serialize, answer, judge, size, compare, normalize, truncate, fold, trim, discharge, place, canonicalize, retry, alert, record, make, pass, write, order, refuse, own, destroy, intercept, compose, release, match, close, emit, escalate, examine, derive, follow, decide, purge, validate, bind, resist, find, join, reconstruct, clear, act, surface, keep, adjudicate, verify, stamp, block, commit, reverse, mark, need, take, issue, include, survive, namespace, address, bound, classify, condition, confirm, count, delegate, enumerate, evaluate, evidence, filter, invent, invoke, land, map, re-derive, re-drive, re-offer, re-read, reject, remain, repair, restart, return, rewrite, share, test, wait, end.

Term records: empty.

Term bounds: retention completion bound (retention_completion_bound), compensation window, audit horizon (audit_trail_retention_policy), evidence floor, horizon margin, closure floor, clock offset allowance, field cap, hold ids cap (hold_ids_cap), audit write latency, call pause bound, section term, section work bound, record start floor, sibling floor, alert floor, enumeration bound (enumeration_bound).

Term cadences: reconciliation cadence, seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term value sets: hold check mode = strict | advisory. hold check result = empty | the blocking hold ids with the blocking count. intent = retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended. outcome = retention_placed | hold_placed | hold_released | record_purged | intent_abandoned. sibling disposition = purged | pending. lease reading = live | expired. erasure outcome = destroyed | destruction-failed(reason). cascade-failure step = seal | hold | step-1 | step-2 | step-3 | in-flight. `Legal Hold` = composed | absent.

Term terms: composition, constituents, business retention instance, service identity, record, record-to-retentions index, retention-to-record index, audit horizon, surviving placement event, purged placement event, rebuild, sibling set, pending sibling, seam, transition, evidence floor, closure floor, retention completion bound, hold check mode, now, boundary predicate, opaque input, landed record, owed record, intent, outcome, gate record, committing call, admitted placement, admitted hold placement, admitted hold release, admitted purge, elapsed retention, hold check result, hold override, unavailable sentinel, purged retention ids, sweep, open marker, young marker, aged-out event, recovery intent, recovery marker, recovery outcome, clock offset allowance, constituent commit, gate read, seal coverage, yielded invocation, post-destruction hold, pre-destruction release, aged-out hold, historical hold set, log order, destroyed record, committed placement, committed hold placement, committed hold release, committed purge, record section, call pause bound, section term, section work bound, audit write latency, record start floor, sibling floor, candidate marker, leg, plan, destroyed event, stand-in, within the audit horizon, horizon margin, quiescence, alert floor, enumeration bound, overdue marker, constituent instance, largest record, surviving destruction, hold count, horizon alert, entry instant, hold check admitted, hold-blocked, eligibility tuples, lease reading, hold database name, alerting surface, compensation window, reconciliation cadence, field cap, hold ids cap, position, invocation id, intent instant, intent abandoned, attributed actors, record destruction pattern, audit retention instance, erasure outcomes, closed entry, open entry, erasure mechanism, `Legal Hold`, hold placement, tombstone-by-mutation, `act's completion bound`, abandoned call, later truth-bearing write, hold, mid-cascade expiry, `cascade-failure(step-3)`, completed cascade, divergence, purge edge, purge age, suspended entry, purge sweep.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. verify_record, read_record, seal_now, record_destruction, destruction-failure, nothing-to-seal, retention-period-not-elapsed, event id, recording instant, sequence number, coverage status, covering seal, purged events, destruction record, pair, retention state, per-act critical section, sealed through, unsealed tail, purge completion bound: Audit Trail. try_take, remaining, grant, holder value, remaining term, call in flight, no answer: Lease. time resolution, standing record, withheld record: Retention Window.

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

What Legal Hold's read answered at the gate, carried on the destruction record and on the gate record alike: empty when no active hold covered the record, and the blocking hold ids with the blocking count when one did. It is what makes it provable that the gate passed or fired.

Kind:       Field
Field of:   the destruction record
Role:       the auditable gate result
Projection: hold_check_result

#### Hold Override

The marker a destruction record carries when the [Hold Check Result] stands non-empty under advisory mode, and only then — what makes it provable that a destruction proceeded past an active hold under an authority this layer does not hold.

Kind:       Field
Field of:   the destruction record
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
Member of:  the purge rejection
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
- **ISO 15489-1 (records management)** — clause 9.7, suspension of disposition, maps to the gate; the two-state hold lifecycle maps to the standard's hold lifecycle.

The three constituents carry their own standards inheritance — see each constituent's own Standards references.

---

## Status

`grounded on Final Critique 18 — 2026-11-05 at 4e61dc9` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 18 — 2026-11-05 at 4e61dc9
formal: verified — defensible-retention.tla + 5 twins + 1 probe (the gate under the record section: a purge against a hold placement and a sibling placement; 4,206 states, holding at a term of 7 within 10 ticks) and defensible-retention-outcome.tla + 3 twins + 1 probe (one outcome per destruction: the invocation's outcome, a step-3 refusal whose append lands late, and a sweep leg; 4,222 states, holding at a term of 9 within 12 ticks), re-derived from the page as it stands, 2026-10-04, and the audit cascade's models, moved here with the cascade: defensible-retention-audit-hold.tla + 5 twins + 3 probes (a hold placed over an open cascade entry, released and re-driven; 43,688 states within 15 ticks, re-run 2026-11-02) and audit-trail.tla + 2 twins (the cascade's order and the scan's first half, which both pages cite); models last run; coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes Alloy (the static data model); owed rows: Invariant 4; Invariant 7, 2026-11-02
last gate: 2026-11-05 — Final Critique 18 — delta, frozen at 4e61dc9 — foundational count 0, clean, one sample

open:
- 2026-11-05-a · refining · Composition state 17 · "scope statement" is no declared term, and what a refusal resting on the database-sourced rebuild may not claim is unstated → declare the claim (that the composition placed the retention, Composition state 16) and write the rule by it
- 2026-10-04-d · refining · Term evidence floor; Capability requirement 11, 12 · the retention and purge-delay terms have no declaring requirement, and no check sets a hold's actual life against the longest hold declared → declare; a provable check
- 2026-10-04-e · refining · Term closure floor; Term section work bound; Term sibling floor; Term audit write latency; Reconciliation 21 · a leg's re-read under the section and its lease readings are uncounted and a leg has no work bound the section term must exceed, the latency runs from the issue where Lease's unit runs from the ask, and the sibling floor leaves no pause for the outcome's own reading or the purge-instant read; the worst case is an owed outcome or an early alert → a leg work bound; recount
- 2026-10-04-f · refining · Reconciliation 19, 25, 41; Check 3.3; Term leg · a pending sibling has no window and no alert, and the Term covers a leg over open markers and not one over siblings alone → a window; widen the Term
- 2026-10-04-g · refining · Term within the audit horizon; Term aged-out hold; Check 1.10, 2.1, 2.2 · a hold's act is aged by the placement or release instant a caller may assert, so a hold backdated past the horizon reads aged-out the day it is entered → age it by its intent's recording instant where the intent survives
- 2026-10-04-h · refining · Composition note 6 through 9; Identity 6; Non-goal 22, 23; Action wiring 73, 82, 96; Capability requirement 11, 15, 41, 44 · deployment and caller obligations outside the capability list with no external check, and four requirements naming no supplier → move or cite each
- 2026-10-04-j · refining · Capability requirement 37, 54; Check 7.1 through 7.3 · Lease Capability requirement 9 is declined in a WHY alone, and Lease's holder-side checks are cleared by no check here → state each
- 2026-10-04-k · refining · Term recovery intent; Term plan; Reconciliation 3, 17, 18, 24, 38 · the recovery intent's invocation id and its own audit arms are unstated, a record owing both a re-emit and a sibling purge has no stated order, the sweep is said to store no record of its own beside the recovery intents it writes, and Reconciliation 24 reads a database without saying what follows → state or strike
- 2026-10-04-m · refining · Action wiring 60; Primitive policy 23 · nothing caps the retentions over a record, so one more can make its purge answer invalid-request until the caps change → a non-goal, or a cap at placement
- 2026-10-04-p · refining · Check 1.6, 2.4; Invariant 2, 6.1, 6.2, 7, 8.2, 8.3, 10; Term cited · two checks cite a rule that does not say what they test, seven invariants are named by no check, and the constituent terms the rules use are missing from Term cited → re-cite; a check per invariant
- 2026-10-04-q · refining · Composition state 24; Check 3.4; Term candidate marker; Term surviving destruction · an open purge marker a failed purge left masks a purge made outside the composition, which the sweep then recovers as that marker's act; it needs a breach of Capability requirement 46; and a bypass is judged on a now older than the read it rests on → say the detection excepts it; judge under the section
- 2026-10-04-r · refining · Audit arm; Reconciliation; Concurrency 5 through 34 · the intent and outcome pairing, the audit arms, the sweep and the record section are the invocation protocol Recoverable Invocation is drafted to own → extract when that composition grounds; own round
- 2026-10-04-s · rhetorical · Examples; Terms · nothing walks the sweep, a recording-failure or a take of the record section, two walkthrough payloads omit fields the rules require, Hold Check Unavailable is a member of the purge rejection alone, tombstones sit out of order, and ISO is not spelled out → rewrite on the next load-bearing touch
- 2026-10-05-b · refining · Term stand-in; Check 5.4, 6.5 · the service-identity arm takes any earlier destroyed event, so an intent-less sweep outcome reads unknown for good once one event has aged out → bound the arm to one horizon before the outcome
- 2026-10-05-d · refining · Composition state 3, 21, 24, 26, 33, 34; Invariant 2.2 · no action reads an index now, so the rebuild has no trigger and the bypass report no surface, the sweep removes only what it purged, the two indexes are said to agree with no qualifier, and placed-through-this-composition is tested by no rule → name the trigger, or make the index a convenience
- 2026-10-05-e · refining · Term committed placement; Term committed hold placement; Term committed hold release; Term committed purge; Reconciliation 11; Action wiring 86 · committed is the call's answer in the Terms and the database's state in the sweep, so a call that landed without answering sits outside the invariants that quantify over the Terms; keying the Terms on the database collides with Action wiring 86, which forbids that invocation an outcome → a second Term for the sweep's reading
- 2026-10-05-g · refining · Primitive policy 18; Capability requirement 17 · the composition must not store a credential and the sweep presents one each run, with no named supplier → scope the rule to a caller's credential; name the supplier
- 2026-10-05-h · refining · Capability requirement 55; Non-goal 15, 16; Term record · both of Retention Window's destruction branches are passed down and neither is pinned → pin the branch
- 2026-10-05-i · refining · Action wiring 82, 96; Reconciliation 36; Concurrency 14 · a mandated retry has no terminus and each one leaves a young marker that parks every older marker over the record, and a first committing call needs only a live reading where its outcome needs a floor → a terminus; a commit floor
- 2026-10-05-j · refining · Action wiring 44, 45, 47, 50, 57, 94, 100, 108; Concurrency 5 through 9 · refusals and the take precede any check of the credential, so an unauthenticated caller holds a section and learns that no active hold exists, or that a retention is unknown or not yet eligible → authenticate first, or name the non-goal
- 2026-10-05-l · rhetorical · Terms; Composes 12 · the gate, placement, audit instance, hold records, destruction record and eligible each carry two meanings or no entry, and Composes 12 does not name Event Log's read → one term each; name the read
- 2026-10-06-a · refining · Action wiring 59, 112 · the order of the sibling purges, and the place of the call to the record destruction pattern among them, is unstated → pin the order
- 2026-10-06-b · refining · Check 1.3, 1.11, 5.9; Invariant 5.3 · a release that committed ahead of a purge and whose outcome is still owed past the compensation window leaves its hold in the historical hold set, and an open marker older than the window that carries no stand-in has no verdict → an open obligation while a release marker stands; a verdict
- 2026-10-06-c · refining · Action wiring 16a, 79, 96; Execution Contract Constituent failure 1 · storage-failure lands where nothing committed and where the call may still land, with nothing to tell the two apart, and only a purge has a caller's reading of the retry → carry the position, or a caller rule for each action
- 2026-10-06-d · refining · Primitive policy 1 through 11; Action wiring 45, 73 · a blank retention id has no boundary rule beside the blank hold id's and falls to not-known, which a re-invoking caller reads as a destruction → add the rule
- 2026-10-06-e · refining · Term reconciliation cadence; Reconciliation 2; Term alert floor; Action wiring 110 · the cadence is not said to run start to start, so a backlog's legs can delay the next run's alerts, and the listing has no cap, no page and no collation for its tie → pin start to start; cap the listing
- 2026-10-06-f · refining · Term overdue marker; Term young marker; Action wiring 8 · both edges of the sweep read the intent instant, the now an invocation stamps ahead of its take, so a host stalled between the seam and the take stamps an old instant on a fresh intent and the sweep reads a live invocation's marker as overdue; Resolve a Person's Data Rights now reads both of its edges on the log's recording instant → the log's stamp; found by that composition's round of 2026-10-06
- 2026-10-06-g · refining · Term alert floor; Term enumeration bound · the floor and the bound count one cadence to a run that ends its enumeration and no run that dies part-way, which nothing alerts on and which an auditor reads as a failure → the deployment's alert; an open-obligation reading; found by the same round, cured there as Resolve a Person's Data Rights Reconciliation 40
- 2026-10-06-h · refining · Action wiring 73; Non-goal 5 · a caller MUST read a re-invoked not-known as a committed destruction, with no exception for a caller that asks the database instead, as Resolve a Person's Data Rights does; and a hold placed over a record under no retention is admitted, so a hold this composition's own records carry over a host-managed record fires no gate → admit the reading; say so where the hold guarantee is stated; reported by the same round
- 2026-10-25-b · refining · Term closure floor; Term call pause bound; Term clock offset allowance; Term compensation window; Term intent; Term leg; Term quiescence; Term reconciliation cadence; Term seal coverage; Term audit horizon · Audit Trail declares each of these names with a definition of its own (its closure floor another formula, its compensation window and its reconciliation cadence its own reconciliation's, its intent a finding's record), so each word means two things across the seam (GRACE-lang Closed vocabulary 17) → rename this page's side of each; a council commit of this page cannot change Audit Trail
- 2026-10-31-a · refining · Concurrency 24, 25; Audit arm 2, 16; the WHY after Term hold ids cap · Audit Trail's record action now commits nothing on a recording-failure carrying step-3 (its record action step 3.3, 3.7), so the append still to land that the WHY names, and the section hold and the never-retried owed record resting on it, are its earlier contract, and the outcome model's step-3 twin models that contract → land step-3 with step-2 and step-4; re-derive the outcome model
- 2026-10-03-h · refining · Audit Trail record destruction step 1.3; purge event 1; Audit Trail Invariant 8.5 · Retention Window's not-known passes through as this composition's for an event with a log entry → land it on the cascade-failure arm
- 2026-10-04-t · refining · Capability requirement 69; Capability requirement 71 · (Audit Trail's 2026-10-04-k) the hold gate's read does not match the Legal Hold database name the atom has a composing pattern match (Legal Hold Instance 5 through 7) → cite the atom's rule at the gate
- 2026-10-04-u · refining · Capability requirement 69; Non-goal 30 · (Audit Trail's 2026-10-04-p) the hold-gate wiring is an extraction candidate, the Hold-Aware Audit Retention pattern Defensible Retention names as a non-goal → own round
- 2026-08-30-d · refining · Audit Trail Invariant 8 liveness; the scan's first half · a delegation whose outcome record was never written is re-driven "until a `destroyed` outcome lands" against content the mechanism may only ever answer `destruction-failed` for → an *abandoned* record under the operator identity after a declared bound, the arm degrading to *surfaced* (the already-destroyed case closed by erasure mechanism 7a on 2026-10-01; a mechanism that only ever answers `destruction-failed` breaks erasure mechanism 10 since 2026-10-24, so what remains is the terminus its divergence lacks); contract-shaped — ripples to every composer that transcribes Audit Trail Invariant 8's unconditional lawfully-destroyed-versus-missing distinction, own round
- 2026-11-02-a · refining · purge event step 0.1 through 0½.6; purge eligible events 1, 2; First half 1, 3; Composes 19 · the audit cascade now reaches Audit Trail through read_record, seal_now and record_destruction, but its first half and its eligible list still read the audit retention instance beside the declared reads, and the first half tests purged events, the pair and the destruction record, which are Audit Trail's indexes → declare the reads on Audit Trail, or route each through read_record; found by the purge move
- 2026-11-02-b · refining · Closure table; Action wiring · the closure table covers the audit cascade alone, and the five business actions' rows are owed → draft them in the page's full round; found by the purge move
- 2026-11-02-c · refining · compensation window; quiescence; leg; call pause bound; clock offset allowance; reconciliation cadence; Term purge edge · the moved cascade reads Audit Trail's compensation window, quiescence, call pause bound, clock offset allowance and reconciliation cadence beside this page's own sweep terms of the same names, qualified in the rules that name them and not renamed (open line 2026-10-25-b, GRACE-lang Closed vocabulary 17) → rename this page's side of each; found by the purge move
- 2026-11-04-a · refining · Capability requirement 14, 15, 16; Primitive policy 23; Action wiring 52; Term largest record; Wiring decision 4 · caps each within the payload cap can sum past it, so the sized gate record exceeds the payload cap, a strict purge over a held record answers invalid-request (Primitive policy 23) and leaves no gate record for Check 1.5 and 1.6 to read (with 2026-10-04-m) → a start condition that the gate record at the caps fits, or a non-goal naming the deployment's sizing
- 2026-11-04-c · refining · Non-goal 23; Term horizon alert · the alert for a hold approaching the audit horizon names no threshold for approaching → state the span before the horizon at which the alert reads, a decision no rule makes; found by the Final Critique 17 delta round
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/defensible-retention.md`; the round and the migration that got it here are in [its history](./defensible-retention.hist.md).

- **2026-11-01 — The cascade's purge and its destruction record commit together.** *Chose:* step 1's transition and step 2's destruction record committed as one transaction before the delegation, and step 3's outcome record in a transaction of its own after it (Invariant 4.2, 4.2a, Audit Trail record destruction step 2.9), so a step-2 failure leaves the retention as found, Retained for a first run (purge event 3), and a Purged retention with no destruction record stands only where a deployment fault leaves one. *Over:* step 1 committed alone before step 2 was written, the split Audit Trail record destruction step 2.9 kept through the 2026-10-20 sweep and Audit Trail read record step 4.4g and 4.4h served from Final Critique 41. *Because:* Execution Contract Database 1 commits every write of one action together, and the maintainer ruled 2026-10-20 that one transaction spans every store write of one composition action, its constituents' included; only the delegation, an act outside the store, stands between two of the cascade's writes, so only it splits the cascade's commits (Final Critique 59).
- **2026-11-02 — The audit instance's end of life comes here from Audit Trail: lawful destruction lives in one page.** *Chose:* under the maintainer's ruling of 2026-11-01 18:15Z ("Lawful destruction lives in one page"), kept by his "as recommended" of 21:37Z, the purge machinery of [Audit Trail](./audit-trail.md) came here whole: Purge Eligible Events (named apart from this page's Purge Eligible, which answers the business retention instance) and Purge Event with their contracts and closure rows; the erasure mechanism and Legal Hold knobs (Capability requirement 69 through 72, Instance start 4, 31 and 32 of that page); the cascade's critical section (Cascade critical section 1 through 8); erasure outcomes; the first half of the reconciliation scan (First half 1 through 13); Boundary one; the cascade-on-purge rule and its WHY; Invariant 11 through 13; Check 8; External check 15 through 18; Non-goal 30; the edge case Legal hold suspension of purge; four open lines and four Decisions entries; the cascade reaches Audit Trail through its declared surface alone: step 0 and 0½ read the event through read_record and ask seal_now, step 1 calls record_destruction, which keeps the retention's purge and the destruction record in one transaction on Audit Trail's side (Audit Trail Invariant 4.2), step 3 delegates the shred (Composes 21, 22); Not Eligible and Under Legal Hold are shared with Purge Record; Composes 11 and Non-goal 20 tombstoned (the audit cascade is this page's own), Non-goal 22 cites Capability requirement 69g, and the Hold-Aware Audit Retention pattern this page named forthcoming is this page's own; the audit-trail-hold models renamed defensible-retention-audit-hold; a first closure table, covering the audit cascade (open line 2026-11-02-b); Audit Trail's open lines 2026-10-04-k and 2026-10-04-p arrived as 2026-10-04-t and 2026-10-04-u, their ids taken here; rules 499 to 657, lines 1,274 to 1,753. *Over:* keeping the cascade in Audit Trail and wrapping it here, which kept two pages over one act and Non-goal 20 through 23 as the debt; reaching the audit instance's indexes and records directly, which a composer's declared surfaces forbid; and moving the destruction record's write, which only Audit Trail's indexes and seal coverage can write consistently. *Because:* the end of a record's life is named once, and this composition exists to make record destruction lawful; no moved rule's content changed beyond the citations and the reads named above. Both pages owe a full round.
- **2026-10-23 — The composition owns its records' destruction and makes it through a record destruction pattern.** *Chose:* the business retention instance supplied with the composition owning the destruction (Capability requirement 55, Retention Window Record divergence 4), as Audit Trail owns its own instance's, so Retention Window's purge is the state transition alone over it; the destruction made through a record destruction pattern, Record Destruction *(forthcoming)*, which a committed purge calls with the record reference while the grant still has the sibling floor, and which destroys only a record a purged retention names, keeps each confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the owner (Capability requirement 66, Action wiring 112, Term record destruction pattern); that call a committing call, so it waits on the intent, the credential and a live reading of the record section as Retention Window's purge does, and its party bound by Lease Capability requirement 8 and 10 beside the constituents (Term committing call, Capability requirement 54, Term sibling floor, Term section work bound); Capability requirement 55 citing Retention Window Capability requirement 5 and 6a through 11, since 4, 4a and 6 are deleted; Term destroyed record's case of a record the storage layer destroyed under a purge that left every retention retained deleted, since nothing is destroyed before Retention Window's write commits; the Intent, [Purge Record], [Under Active Retention], the walkthrough and Term record saying who destroys; open line 2026-10-05-k closed as dissolved and 2026-10-04-j narrowed; rules 499 to 501. *Over:* the record destruction pattern owning the destruction itself, which Retention Window Record divergence 4 grants only to the pattern that wires the instance, and which its Simultaneous retention 6a would make owner of the joint enforcement this composition holds (Capability requirement 45, 46); and the business records kept in the database alone, removed by Retention Window's own purge, which would leave the electronically stored information, communications and non-erasable media this page governs with no one to destroy them. *Because:* the maintainer ruled on 2026-10-23 that every destruction outside the database is owned by a composing pattern, never by Retention Window, whose Record divergence 1 through 2b and Capability requirement 4, 4a and 6 this page's purge had rested on (Retention Window's 2026-10-03 entry: *Defensible Retention keeps a purge that destroys*), and no pattern in the corpus makes that destruction, so the pattern is named as forthcoming. What the gate decides, refuses and records is unchanged.
- **2026-10-21 — The shred pattern named, and the gate's evidence provable.** *Chose:* *shred* (`glossary.md`) where the page wrote *cryptographic shredding*: Non-goal 16, under which a deployment needing a shred composes a shred pattern, with the composing patterns line and the owners NOTE; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where it wrote *from the records*, *records-alone* or their like, by wording alone: the Summary, the Intent, the gate's two halves, the [Hold Check Result] and [Hold Override] term entries, the override and spoliation examples, the acceptance bar and open line 2026-10-04-d; rules 499 to 499. *Over:* the phrases restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Non-goal 16 changed and no obligation did.
- **2026-10-21 — The erasure mechanism shreds, and the regulator's answer is provable.** *Chose:* *shred* (`glossary.md`: destroy the keys that decrypt a record's content, so the content cannot be recovered while every stored version stays as written) in place of the page's own Term shredding-class, deleted with its place on the terms line: erasure mechanism 1, under which the deployment wires an erasure mechanism that shreds, and External check 15, under which an auditor clears that it shreds, with *shred* among the record verbs; by wording alone, Boundary one's heading, the cascade-on-purge paragraph and its WHY, the bank example and the [Purge Event] term entry; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) in the regulator-audit example and the acceptance bar; rules 749 to 749. The knob keeps its name, erasure mechanism, and the bank example's configuration value keeps its code spelling. *Over:* a shredding class declared on this page alone, holding the meaning the glossary now holds once. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood, and Execution Contract Database 5 says a shred is not an erasure; the wording of erasure mechanism 1 and External check 15 changed and no obligation did.
- **2026-10-20 — The store's guarantees cited, not restated, and a store-only act's intent, write and outcome one transaction.** *Chose:* Capability requirement 65 citing Execution Contract Store 1 through 4 for the store of the three constituent instances; the rules restating what that store guarantees tombstoned to it (Capability requirement 49, External check 12); and the machinery that existed only because a placement's, a hold placement's or a hold release's intent, constituent write and outcome could come apart — the audit append held out of the act's transaction, each outcome ordered after its constituent commit, the ids a placement intent carried so the sweep could name the act an open marker had made, the read and the cap that list needed, the id a placement's outcome-position failure carried, and the index entries a recovered placement added (Atomic writes 1 through 4, Action wiring 102, 103, 104, 105, 107, Reconciliation 10, Composition state 34), with the reading of a recording-failure at step 4 as a landed record, a split Audit Trail's own rewrite removed (Audit arm 3, 4). Rules 513 to 499. *Over:* an audit append no host transaction could enlist, so that a store-only act's outcome followed its constituent's commit and the sweep recovered whatever a crash between the two left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal: so a refused act's intent still stands for the sweep to close as abandoned (Reconciliation 9, 28), the purge, whose destruction is an act outside the store, keeps its intent, its outcome and the sweep that recovers them, and the two indexes stay derived indexes outside every action's transaction (Composition state 20). What the composition does for its domain is unchanged.
- **2026-10-05 — The horizon is read from the log, the store answers what the index did, a record is sized whole, and one instance serves one composition.** *Chose:* a destroyed event later in the log as the sign that an intent's outcome may have aged out — an intent with such a stand-in is no open marker and the sweep leaves it — and the same reading for an auditor's pairing checks (Term stand-in, Reconciliation 5, 42, Check 5.4, 5.5, 6.5 through 6.7); one audit retention policy over every event the composition records, kept for the life of the instance (Capability requirement 57, 60); the horizon above an alert floor, with the escalation raised ahead of any take (Capability requirement 58, Reconciliation 43); the largest record sized whole against the payload cap before the first audit record is issued (Primitive policy 14, 23); not-known and the listing decided on Retention Window's store, and [Purge Eligible] refusing where that store cannot be read (Action wiring 32, 44, 45, 110, 111); a failed read ahead of the commit a storage-failure and after it an owed outcome, and an outcome the section admits no call of owed (Action wiring 98, 99, 109, Concurrency 34); a gate record owed only as the audit arms read it (Action wiring 85, Term owed record); one instance of the composition for each constituent instance (Capability requirement 59). *Over:* an edge a clock decided alone, which allowances and a leg's own span narrowed and never closed; an index a lost entry could make lie; field caps under a cap the substrate measures over the whole envelope; a gate record that had not landed, a condition three other rules also answered. *Because:* Resolve a Person's Data Rights' gate found its horizon assumed single and exact, and this page carried the same assumption (the batch rule — reference first, then swept, one closing round); the rest is what eighteen reader runs found on the way to one clean text, each a state two implementations would have answered differently. The models stand: no rule either one reads was changed.
- **2026-10-04 — Every act over a record runs under one record section, and the late hold is closed here.** *Chose:* a [Lease](../atoms/lease.md) on the record reference, taken before the gate read and held to the outcome by a placement, a hold placement, a hold release, a purge and a sweep leg (Concurrency 5 through 24, Reconciliation 20, 21, 30, 31); the atom's sizing rules stated as this composition's own over two kinds of write, a committing call on a live reading and a record_action above a start floor (Capability requirement 37 through 44); one refusal, section-unavailable, for a section held or run out before anything committed; the deployment bound to place and purge through this composition alone (Capability requirement 45 through 47). *Over:* a serialization the deployment owed and no rule sized (Capability requirement 34, 35, tombstoned), a late-hold race the page named and declined to close (Concurrency 1 through 3, tombstoned), and a sweep serialized on an invocation id by no declared means. *Because:* Retention Window re-grounded on Final Critique 7 obliging the pattern that owns joint enforcement to serialize a placement, the sibling read, a purge and a destruction over one record reference (its Simultaneous retention 5, 6), and Lease grounded on Final Critique 4 with the rules to do it by. Closes Ledger line 2026-10-03-a. The model is re-derived: the old one made the gate and the destruction one step, so it could not show the race at all; the 2026-08-29 line asking for the sweep in the model closes with it.
- **2026-10-04 — What the constituents now say is read as they say it.** *Chose:* a storage-failure from Retention Window's purge read as the retention retained and never as the record intact, with the deployment's destruction record named as where the record's fate is answered (Atomic writes 8, 9, Reconciliation 32, External check 8); the hold store's name matched at the gate (Action wiring 77, 78); the substrate's refusals read by the step they carry, and a step-3 failure never retried, since an append that did not answer may still land (Audit arm 2, 12, 13, 16, 17); a hold's order against a destruction decided against the purge intent, which lands under the section between the gate read and the destruction, and not against an outcome the sweep may write long after (Invariant 6.3, Check 1.4); a placement over a destroyed record refused and a pending sibling left to the sweep alone, since a purge call over one wrote a second record purged outcome for one destruction (Action wiring 93, 94, 95); a release ordered against a destruction by its intent's log position, as a placement is, since the two instants are read at two seams (Invariant 6.5, Check 1.3, Check 1.8); a sibling read as elapsed only past the clock offset allowance (Term elapsed retention); an outcome owed by a committed act and not by an admitted one, which a constituent may still refuse (Term committed purge); Invariant 7.4 tombstoned for Action wiring 53, and Invariant 1.2 restated as what a blocked purge never answers (Invariant 1.2, 1.5, 1.6); a recovered purge or release paired with the latest marker, which is the one that committed, and a placement paired by the ids its intent carries, since two placements with the same inputs are two acts and an old record with those inputs is none of them (Reconciliation 10 through 14, 34 through 38, Action wiring 102, 103, Concurrency 27, 28); the checks given a reading past the audit horizon, where a lawful act's own record has aged out (Check 1.10, 3.2, 3.4, 6.4); the section held over a step-3 refusal, whose append may still land (Concurrency 25); a release bound to this composition's surface as a placement is (Capability requirement 53). *Over:* a WHY that called the record intact after a failed purge, a gate that matched no store name, arms keyed on a source the substrate no longer reports, and a log-position test that read a recovered destruction as later than a hold it preceded. *Because:* each was a constituent's own rule this page contradicted or did not meet (Retention Window Purge persistence 1, 1a; Legal Hold Instance 5 through 7; Audit Trail's record action step 7), found by reading the three constituents as they stand after this campaign and by the three passes over the result.
- **2026-10-04 — The gated hold placement is the deployment's, and Legal Hold is a knob.** *Chose:* the hold placement a declared deployment facility with a term, a rule that no hold over this instance is placed outside it, a named non-goal, and two start refusals where it or its store is missing (Term hold placement, Capability requirement 69g, Non-goal 30, Capability requirement 71, 72); Legal Hold a knob with a default of absent and a setting rule (Term Legal Hold, Capability requirement 69h). *Over:* a seventh action on this composition, which would have to attest and record a placement Defensible Retention already attests; and an arm on Legal Hold's place, an atom that knows no lease. *Because:* the rule of 2026-10-02 lets an ownership finding close on a capability requirement that states the behaviour and its owner, the placement's rules already bound a party the page did not name, and the scan scheduler, the cadence driver and the erasure mechanism are owned the same way. Closes Ledger lines 2026-10-03-p and v.
- **2026-10-02 — The hold over an open entry is modelled: a suspended entry is a term, and closure sum budgets one hold placement.** *Chose:* Term suspended entry — an open entry a run landed under-legal-hold, until a later run reads no active hold — read by quiescence and by the audit edge, so the checks scoped to a quiescent cascade wait for the hold-free run (Term suspended entry, Term quiescence, Term audit edge); closure sum gaining `purge_completion_bound + reconciliation_cadence` WHERE Legal Hold EQUALS composed, one hold placement's lease and the run it displaces (Term closure sum, Audit Trail Instance start 17); `audit-trail-hold.tla` with five twins and three probes, and the enumerator's schedule carrying the placement. *Over:* a window counted from the entry's creation the moment the hold is released, before any run has read it free; a restart for every entry a placement touched, which Invariant 12.3 refuses; and a closure sum that budgets a dead run alone. *Because:* the model reaches an entry between its hold's release and the next run, open, not held and past its window, which Check 8.1 read as a conformance failure on a conforming instance — the residue of the finding four rounds reported; and a hold placement takes the entry's section by a waiting take while a leg skips a held section, so one placement costs the entry a run, and with the budgeted dead run the entry outlived closure sum on 2,508 of 2,592 composed tuples. With the part added none does, at zero slack, so it is the least that holds. The model also confirms what the page already said: a placement serialized by the section and a leg that writes nothing on an expired lease keep content from destruction under a hold, and a window restarted from the store's release instant, which a caller may backdate, breaches. Outside the budget, and unchanged: two hold placements over one entry inside one window.
- **2026-09-27 — The sweep can write the destruction record it owns, a closed marker stays closed, and the purge refusals take an order.** *Chose:* the purge intent carries the hold check result (Action wiring 76); intent_abandoned is an outcome; the not-eligible and under-active-retention rules apply only once the hold check admitted the destruction, and the second only over an elapsed named retention; a gate record that cannot land answers `recording-failure(gate)`. *Over:* a recovery outcome needing a hold check result no store carried, so every owed destruction record closed as abandoned; a closing no rule counted as an outcome, so the sweep re-closed it every run and Invariant 5.6 failed for every abandoned invocation; three refusal rules that could each demand their own answer for one call; and a position token with no member for the gate record. *Because:* the cold regeneration of 2026-09-27 met each — the owed record the 2026-09-14 decision gave the sweep could never be written.
- **2026-09-14 — A constituent's storage failure surfaces as itself, and this composition's own recording failure carries its position.** *Chose:* storage-failure exported unchanged from all four state-changing actions, and `recording-failure(intent | outcome)` on every one of them. *Over:* the prose's mapping of a constituent storage-failure onto recording-failure, and a bare recording-failure on the three non-destructive actions. *Because:* the first renamed a failure to *write a record* into a failure to *record it*, which is a different fact and a different repair; the second put one token on both sides of the commit, so a caller who retried on it could not know whether anything had committed — which the corpus's own rule requires the exported code to answer.
- **2026-09-14 — The owed destruction record has exactly one writer.** *Chose:* an invocation retries its outcome until the retention completion bound and then yields; past the bound the record belongs to the sweep, which serializes its leg on the act's invocation id and re-reads the act's outcome under that serialization. *Over:* an out-of-band retry and a sweep both owing the same record with nothing between them. *Because:* two writers over one destruction land two record_purged events for one act, and the trail then protects both — the one failure a compensating write cannot undo.

</details>

NOTE: End of Defensible Retention.

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

The gate is audited in both directions — an event when it allows a destruction, naming that no holds applied, and an event when it blocks one, naming which holds applied — so both halves of the gate's behaviour are provable.

Every destroyed record leaves three things behind: a destruction event naming what the hold records held at gate time, a retention record standing purged, and a tamper-evident seal once the seal cadence covers the event. Together they prove the destruction was lawful, attributed and unaltered — for as long as the audit records themselves are kept, which is the deployment's own ordering obligation rather than this composition's guarantee.

Its most common uses are financial records governance under SOX (Sarbanes-Oxley Act) section 802, patient records under HIPAA (US Health Insurance Portability and Accountability Act) section 164.530(j), electronically stored information subject to FRCP (Federal Rules of Civil Procedure) Rule 37(e) litigation holds, and broker-dealer communications under SEC (US Securities and Exchange Commission) Rule 17a-4. Any system that must prove it did not destroy records while a legal or regulatory hold was active — and that it did eventually destroy them once the hold was released and the retention window had closed — is a candidate for this composition.

---

## Intent

A record's life under a regulated system follows two governance tracks that must coexist without one silently overriding the other. The first is the *retention clock*: a record must be kept for a minimum period mandated by statute, regulation, or contract — seven years under SOX, six under HIPAA, three for some broker-dealer communications under SEC Rule 17a-4. The second is the *preservation directive*: when litigation is anticipated, when a regulator opens an investigation, when an audit freeze is ordered, the normal retention clock stops being the governing rule and the obligation shifts to *keep this record until the legal matter resolves, regardless of what the schedule says.*

Neither Retention Window nor Legal Hold alone enforces that coexistence. Retention Window enforces the clock — it prevents purge before retention deadline and records the eligibility transition. Legal Hold records the preservation obligation — who placed the hold, why, and when. Neither enforces the other's constraint: a retention whose window has elapsed is eligible for `RetentionWindow.purge` with no knowledge of any hold, and a record under an active hold is recorded as preserved while the Legal Hold atom intercepts nothing. The gate that enforces *no purge while any active hold covers a record* belongs to the composition, and this composition is that gate.

Audit Trail provides the third leg: every hold placement, every release, every retention placement and every purge decision is attribution-stamped, retention-bounded and tamper-evident. A destruction is defensible because the evidence trail — who held the record, who released the hold, who purged it, under what policy, at what time — is itself a regulated, integrity-protected record, so the destruction is provable.

This is a composition, not a new primitive. Legal Hold, Retention Window and Audit Trail are unchanged; the composition is the wiring that makes them coherent as one retention-governance surface. It wires the hold gate over the *business* record set, and owns the destruction of those records, which it makes through a record destruction pattern. It does **not** wire the gate [Audit Trail](./audit-trail.md)'s edge case *Legal hold suspension of purge* names — a Legal Hold gate over the audit instance's own `purge_event` cascade, so that the events proving a hold are not destroyed while the hold is live — and an earlier revision's claim to have retired that debt is withdrawn (`Non-goal 20` through `Non-goal 23`).

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
Composes 7: The composition MUST NOT hold an instance of a constituent Audit Trail reaches.
Composes 8: The business retention instance MUST NOT govern an audit event.
Composes 9: The composition MUST reach a constituent through the constituent's declared surface.
Composes 10: The composition MUST NOT read a constituent's records beside the constituent's declared read.
Composes 11: The composition MUST NOT call Audit Trail's purge_event.
Composes 12: The composition MUST read the substrate's events by an open-ended sequence range.
Composes 13: The composition MUST select an event in the composition's own code.
Composes 14: The composition MUST NOT query the substrate by a payload predicate.
Composes 15: The composition MUST attest an invocation's audit record under the calling actor's credential.
Composes 16: The composition MUST attest a sweep's audit record under the service identity.
Composes 17: The composition MUST NOT attest a sweep's audit record under a calling actor's credential.
Composes 18: The composition MUST NOT supply the injected now to a constituent.
```

Term composition: this pattern's wiring of [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md) and the [Audit Trail](./audit-trail.md) substrate — the five actions, the hold gate, the two indexes and the sweep.

Term constituents: [Legal Hold](../atoms/legal-hold.md), [Retention Window](../atoms/retention-window.md), [Audit Trail](./audit-trail.md).

Term business retention instance: the one [Retention Window](../atoms/retention-window.md) instance this composition wires over business records — distinct from the instance [Audit Trail](./audit-trail.md) carries for the substrate's own events.

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
Composition state 13: The rebuild MUST read Retention Window's records for an entry a purged placement event covers.
Composition state 14: The rebuild MUST NOT read a purged placement event's payload.
Composition state 15: The rebuild MUST NOT read a trail miss as an absent retention.
Composition state 16: The database-sourced rebuild MUST admit a retention the composition did not place.
Composition state 17: A refusal resting on the database-sourced rebuild MUST NOT stand as a scope statement.
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

Term audit horizon: the age past which the audit instance has destroyed an event's payload — the retention period of the one policy audit_trail_retention_policy answers for every event of the audit instance (Capability requirement 57).

Term surviving placement event: a retention_placed event whose payload the audit instance has not destroyed.

Term purged placement event: a retention_placed event whose payload the audit instance has destroyed.

Term rebuild: the composition's named regeneration of an index — select this composition's placement events over an open-ended sequence range, take a surviving event's record reference and retention id, read Retention Window's records for an entry a purged placement event covers, and drop every retention the database reports purged.

Term sibling set: the retentions whose retention state EQUALS retained over one record beside the named retention, read from Retention Window's records.

Term pending sibling: a retention standing retained over a destroyed record — a sibling whose own purge has not landed.

Term within the audit horizon: said of a placement, a release or a purge by the instant the constituent's records carry for it — the reader's now less that instant stands below the audit horizon by more than twice the clock offset allowance taken with the database's time resolution, so the act's own audit record cannot have aged out. Two allowances, because the substrate places a record's retention on one clock after the database stamped the act on another, and judges the record's purge on the first against a now the reader takes on a third. An act that does not stand within the audit horizon reads unknown wherever its record is missing (Check 6.4).

Term surviving destruction: a destroyed record whose earliest purge among the retentions over the record stands within the audit horizon — a destruction whose own record purged outcome cannot have aged out. The edge is the record's first purge and never a sibling's later one, which the sweep may land long after the outcome.

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
Capability requirement 14: A deployment MUST set a field cap PER payload field.
Capability requirement 15: A field cap MUST NOT EXCEED the audit instance's payload cap.
Capability requirement 16: A deployment MUST set the hold ids cap.
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
Capability requirement 51: A deployment MUST supply the scheduler.
Capability requirement 52: The scheduler MUST survive the loss of one process.
Capability requirement 53: A deployment MUST release a hold of the hold records through [Release Hold] alone.
Capability requirement 54: A deployment MUST supply hold records, a business retention instance, an audit instance AND a record destruction pattern bound by Lease Capability requirement 8 and 10 for EVERY call the composition issues under the record section.
Capability requirement 55: A deployment MUST supply the business retention instance PER Retention Window Capability requirement 5 and 6a through 11, the composition owning the destruction (Retention Window Record divergence 4).
Capability requirement 56: The substrate's start margin MUST NOT EXCEED the audit write latency.
Capability requirement 57: A deployment MUST set an audit retention policy that answers one policy for EVERY event of the audit instance.
Capability requirement 58: A deployment MAY start an instance ONLY IF the audit horizon EXCEEDS the alert floor.
Capability requirement 59: A deployment MUST NOT serve two instances of the composition by one constituent instance.
Capability requirement 60: The audit retention policy MUST stand as one value for the life of the instance.
Capability requirement 61: A deployment MUST declare the enumeration bound.
Capability requirement 62: A field cap of a reference MUST NOT EXCEED the audit instance's reference length cap.
Capability requirement 63: The host MUST NOT supply one invocation id to two invocations.
Capability requirement 64: A deployment MUST NOT admit another writer of the composition's action references on the audit instance.
Capability requirement 65: The deployment MUST supply the constituent instances' database PER Execution Contract Database 1 through 4.
Capability requirement 66: A deployment MUST supply the record destruction pattern PER Retention Window Record divergence 4a through 6.
```

Term seam: the composition's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects one clock reading and one invocation id here.
Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term invocation id: the id the seam allocates for one state-changing invocation; an intent and the outcome matched to it carry the same one (Capability requirement 2, Reconciliation 6).

Term intent instant: the instant an intent records (Action wiring 8).

Term transition: the composition's evaluation of one call against the constituents, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term evidence floor: `longest_retention_duration + longest_purge_delay + longest_hold_duration` — the longest retention policy in use on the business retention instance, the longest max purge delay and the longest hold the deployment admits, summed — what audit_trail_retention_policy must outlast. The sum is a floor under the policy and no bound on a record's life: a later sibling or a second hold carries a record past it, and what the trail has lost by then the rebuild reads from Retention Window's records (Composition state 13). Where the deployment admits an unbounded hold the hold term is zero: no horizon outlasts such a hold, and the horizon alert and the substrate's own hold placement carry what the sum cannot (Capability requirement 13, Non-goal 22, Non-goal 23).

Term closure floor: `retention_completion_bound + 2 * clock_offset_allowance + reconciliation_cadence + enumeration_bound + call_pause_bound + 2 * audit_write_latency` — the longest interval in which a run that takes the record section closes an open marker: the marker's age at the lower edge, read at a seam that may stand an allowance either side of the intent's; one cadence to the next run; that run's enumeration and its alerts; the leg's take; and the leg's two records. The floor is the first leg's: each leg a run works ahead of a marker's own adds a take and a grant, which no floor counts, so a backlog is alerted on before it is closed.

Term alert floor: `2 * compensation_window + reconciliation_cadence + enumeration_bound + 2 * clock_offset_allowance` — the age by which a run has alerted on an overdue marker and the deployment has had a window to answer the alert, while the marker's intent can still be read. The terms in order: the window; a cadence to the run that reads the marker overdue, and that run's enumeration; a second window for the alert to be answered in; and two allowances, one where a run reads overdue against an instant another seam stamped and one where the substrate destroys on a clock of its own. The alert rests on the run's own enumeration and waits for no section, so a held section or a refused read of a leg delays the closing and never the alert. The floor promises the alert and its window and nothing of the closing that follows the answer: a run closes what its legs reach, one grant after another, and a marker still open when its intent is destroyed stays the alerted partial it was (Atomic writes 7), its outcome unwritten. A deployment that means every marker to close sets the horizon above the floor by the runs its backlog needs.

Term enumeration bound: enumeration_bound — the deployment's declared longest time from a run's start to the end of the run's enumeration of the open markers and of its alerts on them. The trail grows and the sweep keeps no cursor (Reconciliation 3), so holding the bound is the deployment's.

Term overdue marker: an open marker whose intent instant stands older than the compensation window of the now a run is given at its start — a marker the compensation window did not close.

Term constituent instance: the Legal Hold instance holding the hold records, the business retention instance, or the audit instance — the three Composes 1 through 3 give one instance of the composition. Two instances of the composition sharing one would each take a record section the other does not see, and each sweep would read the other's intents as its own.

Term retention completion bound: retention_completion_bound — the deployment's declared maximum duration between an invocation's intent record and the invocation's outcome record, read against the injected now the intent carries.

Term hold check mode: hold_check_mode — strict | advisory.

Term record section: the [Lease](../atoms/lease.md) this composition takes on a record reference — the key is the record reference under this instance's own namespace on the host (Concurrency 30) and the holder value is minted fresh for each take — under which one act over the record runs, from the act's first read at the gate to the act's outcome.

Term call pause bound: this composition's value of [Lease](../atoms/lease.md)'s call pause bound — the longest time from the decision to issue one call to the moment the call has taken effect or failed. It bounds a lease call and a committing call, and never a whole record_action (Lease Capability requirement 7).

Term record destruction pattern: the pattern through which the composition destroys a business record — Record Destruction *(forthcoming)*. It destroys only a record a purged retention names, keeps each destruction's confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the pattern that owns the destruction (Capability requirement 66).

Term section term: the duration every take of the record section asks for (Lease Composition note 5d).

Term section work bound: the deployment's declared longest time from a take's answer to the landing of an act's outcome — the gate read, the sibling set's read, the intent, the act's first committing call and the outcome counted, each record_action at the audit write latency. A sibling's purge the grant no longer admits stands pending, and a record whose call to the record destruction pattern the grant no longer admits stands for that pattern's retry, so no act's work outruns the bound.

Term audit write latency: the deployment's disclosed longest time from issuing a record_action to the landing of the call's last write, an abandoned call's included — never less than the start margin [Audit Trail](./audit-trail.md) declares for a record action (Capability requirement 56). The unit's bound of a record_action under the record section (Lease Composition note 8a); a record_action that has not answered within it answers no answer (Audit arm 18).

Term record start floor: `audit_write_latency + 2 * call_pause_bound` — the remaining term a record_action needs to land inside the grant. The floor admits a call whose [Remaining](../atoms/lease.md) reading answers a remaining term exceeding the floor (Lease Sizing 5).

Term sibling floor: `record_start_floor + 2 * call_pause_bound` — the remaining term below which a purge starts no further sibling's purge and no call to the record destruction pattern, so that the outcome still has its floor once that call has landed.

Term lease reading: live | expired — what a [Remaining](../atoms/lease.md) reading of the record section says of the grant, as [Lease](../atoms/lease.md) declares the two (Lease Sizing 2, Lease Sizing 2a, Lease Sizing 7).

Term hold database name: the deployment's declared name of the one Legal Hold database instance serving the composition (Composes 1), matched against the database name Legal Hold's read answers (Legal Hold Instance 5).

Term alerting surface: the deployment's surface on which the composition alerts.

Term scheduler: the deployment's facility that runs the sweep at an instance's start and at the reconciliation cadence.

Term compensation window: compensation_window — the duration within which the sweep closes an open marker or escalates it (Reconciliation 25).

Term reconciliation cadence: reconciliation_cadence — the interval between the sweep's runs, beside the run at an instance's start.

Term field cap: the deployment's declared maximum size of one audit payload field.

Term hold ids cap: hold_ids_cap — the deployment's declared maximum count of hold ids a hold check result carries, in an answer and in a record (Primitive policy 20).

WHY:
The one Lease requirement no constituent can meet whole is that a refused write was not applied: the substrate's step-3 refusal may hide an append still to land (`Concurrency 25`), and Retention Window's failed purge may follow a destruction (`Atomic writes 9`). Each is read here as what it is.

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
Action wiring 16: IF Retention Window answers storage-failure THEN [Place Record Under Retention] MUST answer storage-failure.
Action wiring 17: An admitted hold placement MUST call Legal Hold's place with the record reference, the placing actor, the reason, the case reference AND the placement instant.
Action wiring 18: A committed hold placement MUST record a hold placed outcome carrying the hold id, the record reference, the placing actor, the reason, the case reference AND the placement instant.
Action wiring 19: IF a committed hold placement's outcome landed THEN [Place Hold] MUST answer the hold id.
Action wiring 20: IF Legal Hold answers invalid-request THEN [Place Hold] MUST answer invalid-request.
Action wiring 21: IF Legal Hold answers storage-failure THEN [Place Hold] MUST answer storage-failure.
Action wiring 22: The composition MUST NOT record a hold release intent BEFORE reading the hold through Legal Hold's read.
Action wiring 23: IF no hold EXISTS for the hold id THEN [Release Hold] MUST answer not-known.
Action wiring 24: IF the hold state EQUALS released THEN [Release Hold] MUST answer already-released.
Action wiring 25: An admitted hold release MUST call Legal Hold's release with the hold id, the releasing actor, the reason AND the release instant.
Action wiring 26: A committed hold release MUST record a hold released outcome carrying the hold id, the reason AND the release instant.
Action wiring 27: IF a committed hold release's outcome landed THEN [Release Hold] MUST answer released.
Action wiring 28: IF Legal Hold answers not-known THEN [Release Hold] MUST answer not-known.
Action wiring 29: IF Legal Hold answers already-released THEN [Release Hold] MUST answer already-released.
Action wiring 30: IF Legal Hold answers invalid-request THEN [Release Hold] MUST answer invalid-request.
Action wiring 31: IF Legal Hold answers storage-failure THEN [Release Hold] MUST answer storage-failure.
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
Action wiring 59: A committed purge MUST call Retention Window's purge PER sibling set member.
Action wiring 60: A committed purge MUST record a record purged outcome carrying the retention id, the record reference, the purged retention ids, the hold check result, the hold override AND the named retention's purge instant as purge instant.
Action wiring 61: A committed purge MUST mark a purged sibling purged in the purged retention ids.
Action wiring 62: A committed purge MUST mark a pending sibling pending in the purged retention ids.
Action wiring 63: IF a committed purge's outcome landed THEN [Purge Record] MUST answer ok.
Action wiring 64: IF Retention Window answers not-retained for the named retention THEN a purge MUST answer not-known.
Action wiring 65: IF Retention Window answers not-known for the named retention THEN a purge MUST answer not-known.
Action wiring 66: IF Retention Window answers retention-period-not-elapsed for the named retention THEN a purge MUST answer not-eligible.
Action wiring 67: IF Retention Window answers storage-failure for the named retention THEN a purge MUST answer storage-failure.
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
Action wiring 80: IF Retention Window's purge answers no answer for a sibling THEN a purge MUST mark the sibling pending.
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
Action wiring 93: IF the record reference names a destroyed record THEN [Place Record Under Retention] MUST answer invalid-request (Retention Window Capability requirement 10).
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
Action wiring 109: IF Retention Window's declared read answers state-unavailable OR no answer ahead of an act's first committing call THEN the action MUST answer storage-failure.
Action wiring 110: [Purge Eligible] MUST answer EVERY elapsed retention Retention Window's declared read answers, a retention Action wiring 95 covers AND a retention Action wiring 101 covers excepted.
Action wiring 111: IF Retention Window's declared read answers state-unavailable OR no answer to a call of [Purge Eligible] THEN the action MUST answer storage-failure.
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

Term elapsed retention: a retention whose retention deadline does not exceed the injected now less the clock offset allowance — the eligibility predicate, derived at read time and never stored. The allowance is there because Retention Window judges a purge against the reading at its own seam: a sibling this composition read as elapsed on a reading ahead of that seam's would be destroyed with the record before the sibling's own deadline.

Term hold check result: what Legal Hold's read answered at the gate — empty, or the blocking hold ids with the blocking count.

Term hold check admitted: said of a gate read whose hold check result stands empty, or stands non-empty under advisory mode.

Term hold-blocked: said of a retention [Purge Eligible] answers with a hold count above zero or with the unavailable sentinel.

Term eligibility tuples: the answer of [Purge Eligible] — for each answered retention, the retention id, the record reference, the retention deadline, the purge deadline and the hold count.

Term hold override: the field a record purged outcome carries — true where the hold check result stands non-empty under advisory mode, and false everywhere else.

Term hold count: the count of active holds over a retention's record that [Purge Eligible] answers, or the unavailable sentinel.

Term horizon alert: the alert a deployment admitting an unbounded hold raises, on the alerting surface, for a hold approaching the audit horizon (Capability requirement 13, Non-goal 23).

Term entry instant: the recording instant of a hold placement's intent — when the hold entered the system, as against the placement instant a caller may assert (Clock semantics 15). The intent and not the outcome, which the sweep may write long after.

Term quiescence: the state in which no invocation holds a record section, no open marker stands younger than the compensation window, and the sweep has no open marker and no pending sibling left to work. An invariant stated at quiescence is owed by then and not at every instant before it: an owed outcome and a pending sibling are states the rules reach and the sweep closes (Action wiring 70, Reconciliation 11, Reconciliation 19).

Term unavailable sentinel: unavailable — the one non-integer value a hold count admits — what [Purge Eligible] answers for a retention whose hold records could not be read, and what a reader treats as hold-blocked rather than as zero.

Term purged retention ids: the named retention and every sibling set member a record purged outcome names, each marked purged or pending.

Term sweep: the reconciliation the Reconciliation rules state.

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

WHY:
*Principle:* Retention Window's own precondition prevents a premature purge and knows nothing of any hold; Legal Hold records a preservation obligation and intercepts nothing. Without the composition wiring the two checks together, a system can lawfully — from each atom's own perspective — destroy a record under an active litigation hold, which is a spoliation exposure structurally invisible to either atom alone.

*Likely objection:* why not have Legal Hold intercept `RetentionWindow.purge` directly, and skip the composition?

*Mechanism that resolves it:* Wiring decision 5 is the answer and it is about freestanding status rather than convenience. An atom that intercepted purge calls would have to know about retention records, storage layers and destruction mechanisms — absorbing concepts that belong to the composing layer. The atom records the obligation; the composition enforces it. Both constituents were written for this: [Legal Hold](../atoms/legal-hold.md)'s `Composition note 2` obliges a composing pattern to check a record's active holds at the purge surface, and [Retention Window](../atoms/retention-window.md)'s `Composition note 3` obliges one to own joint enforcement across retentions over one record. Both name this composition in their own words, and [Audit Trail](./audit-trail.md)'s *Legal hold suspension of purge* edge case names it for the business-record half of the gate — the audit-event half stays open and is `Non-goal 20` through `Non-goal 23`.

*Result:* the gate is structural under strict mode rather than a runtime check an operator can talk past inside this composition's surface — though not a gate a direct atom-level call cannot route around, which `Composition state 24` detects rather than prevents. Both halves of the gate's behaviour are provable: `hold_check_result: empty` on every non-override destruction, and a gate record naming the blocking holds on every refusal. On an advisory instance the [Hold Override] marker is the third reading — a destruction that proceeded past a hold the records still name.

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
Reconciliation 11: The sweep MUST emit EXACTLY ONE recovery outcome PER committed act carrying no outcome.
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

Term open marker: an intent carrying no outcome under the intent's own invocation id and no stand-in — an invocation that committed nothing, committed and failed to record, or died between the two.

Term destroyed event: an event whose payload the audit instance has destroyed. The log still answers the event's sequence number and recording instant, and Audit Trail's read answers the attestation's action reference (Audit Trail read record step 4.4a).

Term stand-in: a destroyed event that may be the missing half of a pairing, answering an action reference the missing record could carry. For an intent that carries no outcome it is a destroyed event later in the log. For an outcome that carries no intent it is a destroyed event earlier in the log whose recording instant stands within the retention completion bound, taken with the clock offset allowance, of the outcome's own — an invocation writes its outcome within the bound or yields — and, where the service identity attested the outcome, any destroyed event earlier in the log, since the sweep writes a recovery outcome or an intent abandoned for a marker of any age short of the horizon (Composes 16). The invocation id went with the payload, so the trail cannot say whether the missing record was written; a pairing with a stand-in reads unknown and never open, orphaned or failed.

Term young marker: an open marker whose intent instant stands within the retention completion bound, taken with the clock offset allowance, of the injected now.

Term aged-out event: an event whose age — the injected now less the event's `recorded_at` — exceeds the audit horizon. No clock decides the edge alone: an intent short of the edge whose outcome the audit instance has already destroyed carries a stand-in and is no open marker (Term stand-in).

Term recovery intent: the `retention.recovery_intended` record the sweep writes before a leg commits or re-emits — one per leg, carrying the record reference and the plan (Reconciliation 45). A closing as intent abandoned takes none.

Term plan: re-emit | sibling-purge — what a leg is about to do: emit the recovery outcomes the record's candidate markers are owed, or purge the record's pending siblings.

Term leg: the sweep's handling of the open markers over one record, under one grant of the record section.

Term recovery marker: the marker a recovery outcome carries so a reader tells a clean act from a recovered one.

Term recovery outcome: the outcome the sweep emits for a committed act whose own invocation did not record one.

Term intent abandoned: intent_abandoned — the outcome the sweep writes over an open marker whose act it does not recover (Reconciliation 9, Reconciliation 27).

Term attributed actors: the actor reference of the candidate marker, carried by a recovery outcome (Reconciliation 14).

Term log order: the order of the substrate's sequence numbers. Wherever a rule or a term of this composition says an event is earlier, later, the next or the latest, it means in log order and never by an instant an event carries: two seams' instants may stand an allowance apart, and the record section is what orders two acts over one record.

Term candidate marker: the open marker that committed the act, a young marker included — which is why a run that meets a young marker over a record leaves every marker over the record (Reconciliation 36). An open marker that is no candidate marker did not commit. Over a hold release it is the latest open release marker over the hold in log order, where the hold stands released and no hold released outcome names it. Over a purge it is the latest open purge marker in log order over the **record**, where the record stands as a destroyed record and no record purged outcome names it: a record is destroyed once, whichever of its retentions the call named, and a retention purged as a sibling under another marker is that marker's act. In both, each act reads its pre-state again under the record section (Concurrency 27, Concurrency 28), so a call that follows the commit records no intent, and every earlier marker failed before the commit.

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
  Invariant 5.6: EVERY admitted invocation MUST record EXACTLY ONE outcome at quiescence.
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

---

## Examples

### Walkthrough — regulated bank under SOX section 802 and FRCP Rule 37(e)

A multinational bank governs its general-ledger transaction records with this instance. The deployment sets `hold_check_mode = strict` and configures the audit instance with a twelve-year policy against a seven-year business policy, a longest hold of four years and a purge delay of thirty days, so the evidence floor sits inside the audit horizon.

1. **Retention placed.** `place_record_under_retention("txn-2026-0441", "sox_7_year", "records_system", credential)`. The boundary predicate passes; a retention_placement_intended record lands carrying `invocation_id: inv-a1`, the two references and intent instant; `RetentionWindow.place_under_retention` answers `ret-0441` with `retention_until = 2033-05-10`; a retention_placed outcome lands carrying `inv-a1`, the retention and both deadlines. Returns `ret-0441`.

2. **Litigation anticipated.** Three years later: `place_hold("txn-2026-0441", "counsel_morgan", credential, "Litigation hold — anticipated class action re Q3 2026 operations", "matter-2029-morgan")`. Intent, then `LegalHold.place` answering `hold-0441-a`, then the hold_placed outcome. Returns `hold-0441-a`.

3. **Retention window elapses.** In 2033 `purge_eligible()` answers `ret-0441` with `hold_count = 1` — hold-blocked, not purge-ready. A records-management job calls `purge_record("ret-0441", "records_system", credential)` anyway. The sibling set is empty; the gate reads one active hold; the mode is strict, so a purge_blocked_by_hold gate record lands carrying `inv-b7`, the retention, the record and `{hold_ids: ["hold-0441-a"], count: 1}`, and the call answers `under-legal-hold(["hold-0441-a"], 1)`. **No intent record is written on this path** — the gate record precedes it and verifies the same credential — and nothing is destroyed.

4. **Litigation settles.** `release_hold("hold-0441-a", "counsel_morgan", credential, "Class action settled — May 2033")`. The pre-intent read finds the hold active; intent, `LegalHold.release`, hold_released outcome. Returns released.

5. **Purge proceeds.** `purge_eligible()` now answers `ret-0441` with `hold_count = 0`. `purge_record("ret-0441", "records_system", credential)`: the sibling set is empty, the gate reads no active hold, the named retention is elapsed, a purge_intended record lands carrying `inv-c2`, `RetentionWindow.purge` stands `ret-0441` purged, the record destruction pattern destroys the record, and a record_purged outcome lands carrying `inv-c2`, `purged_retention_ids: [{ret-0441, purged}]`, `hold_check_result: empty`, `hold_override: false` and `purged_at: 2033-05-15`. The two index entries are removed. Returns ok.

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

Opposing counsel moves for sanctions under FRCP Rule 37(e), claiming ESI (electronically stored information) was destroyed after the preservation duty arose. The defence reads every record_purged outcome in the disputed scope. Each either carries a `purged_at` predating the duty's trigger date, or carries `hold_check_result: empty` with no hold over that record standing unreleased where the destruction's purge intent sits in the log. Where a hold was placed before a destruction, the log carries the hold's placement intent ahead of the purge intent (Invariant 6.3), and `purge_eligible()` at that time would have answered the record hold-blocked. `Check 1.3` and `Check 1.4` are the two the defence runs, and the spoliation question's answer is provable.

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

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the two indexes, the hold records, the business retention instance and the substrate's trail.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY record purged outcome carrying an empty hold check result under strict mode (Invariant 1.1).
Check 1.2: An auditor MUST find EVERY record purged outcome carrying a non-empty hold check result carrying the hold override (Action wiring 55).
Check 1.3: An auditor MUST find EVERY member of a destruction's historical hold set named in the destruction's hold check result (Invariant 1.1).
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
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the business retention durations confirmed MUST read the deployment's own policy register (Capability requirement 11).
External check 2: An auditor needing a retention policy's correctness confirmed MUST read the deployment's own regulatory obligations (Capability requirement 31).
External check 3: An auditor needing a hold's authority confirmed MUST read the deployment's own permissions surface (Non-goal 13).
External check 4: An auditor needing an override's authorization confirmed MUST read the deployment's own authorization documentation (Capability requirement 33).
External check 5: An auditor needing the service identity's provisioning confirmed MUST read the substrate's actor registry (Capability requirement 17, Capability requirement 18).
External check 6: An auditor needing a declared setting confirmed MUST read the deployment's own declaration (Capability requirement 10, Capability requirement 12, Capability requirement 14 through 16, Capability requirement 19 through 25, Capability requirement 27 through 30, Capability requirement 36, Capability requirement 38 through 44, Capability requirement 56 through 62, Capability requirement 64).
External check 7: An auditor needing the serialization confirmed MUST read the deployment's own Lease host (Capability requirement 37).
External check 8: An auditor needing a record's fate under an abandoned purge intent confirmed MUST read the deployment's own destruction records (Reconciliation 32, Capability requirement 55).
External check 9: An auditor needing the single surface confirmed MUST read the deployment's own access control over the hold records and the business retention instance (Capability requirement 45 through 47, Capability requirement 53).
External check 10: An auditor needing the call pause bound confirmed MUST read the deployment's own constituent clients (Capability requirement 38, Capability requirement 54).
External check 11: An auditor needing the hold database name confirmed MUST read the deployment's own declaration (Capability requirement 48).
Deleted: External check 12. Execution Contract Database 3 owns it.
External check 13: An auditor needing the alerting surface confirmed MUST read the deployment's own alert records (Capability requirement 13, Capability requirement 50).
External check 14: An auditor needing the scheduler confirmed MUST read the deployment's own schedule records (Capability requirement 51, Capability requirement 52).
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
Non-goal 20: The composition MUST NOT gate the audit instance's cascade.
Non-goal 21: The composition MUST NOT keep an aged-out event.
Non-goal 22: A deployment whose hold outlives the audit horizon MUST hold the audit events proving the hold through the substrate's own hold placement (Audit Trail Capability requirement 7g).
Non-goal 23: A deployment whose hold approaches the audit horizon MUST alert.
Non-goal 24: The composition MUST NOT resolve a record reference rename.
Non-goal 25: The composition MUST NOT place a hold set in one call.
Non-goal 26: The composition MUST NOT release a hold set in one call.
Non-goal 27: A deployment needing a bulk hold change MUST own the loop over [Place Hold] and [Release Hold].
Non-goal 28: The composition MUST NOT hold an idempotence key for a placement.
Non-goal 29: A deployment needing an at-most-once placement MUST compose Duplicate Prevention.
```

NOTE: the owners — Policy Reconciliation *(forthcoming)* (Non-goal 1, Non-goal 2); the deployment (Non-goal 8; Non-goal 25 through 27); [Permissions](../atoms/permissions.md) and the deployment (Non-goal 9 through 12, Composition note 3 through 5); a shred pattern *(forthcoming)* (Non-goal 15, Non-goal 16); a Failed-Attempt Log *(forthcoming)* (Non-goal 17, Non-goal 18); [Audit Trail](./audit-trail.md), the deployment and Hold-Aware Audit Retention *(forthcoming)* (Non-goal 20 through 23); Reverse Index *(forthcoming)* (Composes 14); Override Authorization *(forthcoming)* (Capability requirement 33).

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
Deleted: Clock semantics 8. Legal Hold Operation 9 owns it.
Deleted: Clock semantics 9. Legal Hold Operation 18a owns it.
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
Concurrency 24: The composition MUST release the record section ONLY AFTER the act's last call answered.
Concurrency 25: IF a record_action under the record section answers recording-failure carrying step-3 THEN the composition MUST NOT release the record section.
Concurrency 26: A placement MUST NOT read the record's retentions BEFORE taking the record section.
Concurrency 27: A purge MUST NOT record an intent BEFORE reading the retention state of EVERY retention over the record under the record section.
Concurrency 28: The composition MUST NOT record a hold release intent BEFORE reading the hold's hold state under the record section.
Concurrency 29: The composition MUST issue a record_action call WITHIN the call pause bound of asking for the call's reading.
Concurrency 30: The composition MUST namespace the record section's key apart from EVERY other key on the Lease host (Lease Composition note 4).
Concurrency 31: The composition MUST read under the record section EVERY database state AND EVERY trail state the composition decides on, a call of [Purge Eligible] excepted.
Concurrency 32: A read made ahead of the take MUST serve to name the record section's key alone, a not-known for an id no database carries AND the alert of Reconciliation 43 excepted.
Concurrency 33: An act whose EVERY call answered MUST release the record section, a call Concurrency 25 covers excepted.
Concurrency 34: IF the record section admits no call of a committed act's outcome THEN the composition MUST read the outcome as an owed record.
```

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

Term actors: the composition; a deployment; the host; the transition; the seam; the sweep; a caller; an auditor; a reader; an implementation; an invocation; an action; an intent; an outcome; a gate record; an open marker; a young marker; a recovery intent; the gate; the rebuild; an index; the record-to-retentions index; the retention-to-record index; a record; a retention; a sibling; a pending sibling; a hold; a hold check result; a hold count; a placement; a hold placement; a hold release; a purge; a release; a destruction; a record destruction pattern; a committing call; a landed record; an owed record; an aged-out event; a surviving placement event; a purged placement event; a field cap; the evidence floor; the closure floor; the audit horizon; a policy; the record section; the section term; the section work bound; the record start floor; the scheduler; Legal Hold; Retention Window; Audit Trail; Event Log; a presenter; a presentation; a hold id list; a truncated hold id list; a divergence; two sweeps; a renamed record.

Term record verbs: serve, change, inherit, read, hold, reach, call, gate, select, query, attest, govern, store, add, remove, leave, stand, rest, admit, drop, report, agree, cover, name, carry, claim, supply, mint, accept, configure, declare, wire, set, provision, rotate, disclose, start, run, resolve, reconcile, serialize, answer, judge, size, compare, normalize, truncate, fold, trim, discharge, place, canonicalize, retry, alert, record, make, pass, write, order, refuse, own, destroy, intercept, compose, release, match, close, emit, escalate, examine, derive, follow, decide, purge, validate, bind, resist, find, join, reconstruct, clear, act, surface, keep, adjudicate, verify, stamp, block, commit, reverse, mark, need, take, issue, include, survive, namespace.

Term records: empty.

Term bounds: retention completion bound (retention_completion_bound), compensation window, audit horizon (audit_trail_retention_policy), evidence floor, closure floor, clock offset allowance, field cap, hold ids cap (hold_ids_cap), audit write latency, call pause bound, section term, section work bound, record start floor, sibling floor, alert floor, enumeration bound (enumeration_bound).

Term cadences: reconciliation cadence, seal cadence.

Term qualifiers: migrated — rewritten in GRACE lang v0.40 (2026-09-14).

Term value sets: hold check mode = strict | advisory. hold check result = empty | the blocking hold ids with the blocking count. intent = retention_placement_intended | hold_placement_intended | hold_release_intended | purge_intended. outcome = retention_placed | hold_placed | hold_released | record_purged | intent_abandoned. sibling disposition = purged | pending. lease reading = live | expired.

Term terms: composition, constituents, business retention instance, service identity, record, record-to-retentions index, retention-to-record index, audit horizon, surviving placement event, purged placement event, rebuild, sibling set, pending sibling, seam, transition, evidence floor, closure floor, retention completion bound, hold check mode, now, boundary predicate, opaque input, landed record, owed record, intent, outcome, gate record, committing call, admitted placement, admitted hold placement, admitted hold release, admitted purge, elapsed retention, hold check result, hold override, unavailable sentinel, purged retention ids, sweep, open marker, young marker, aged-out event, recovery intent, recovery marker, recovery outcome, clock offset allowance, constituent commit, gate read, seal coverage, yielded invocation, post-destruction hold, pre-destruction release, aged-out hold, historical hold set, log order, destroyed record, committed placement, committed hold placement, committed hold release, committed purge, record section, call pause bound, section term, section work bound, audit write latency, record start floor, sibling floor, candidate marker, leg, plan, destroyed event, stand-in, within the audit horizon, quiescence, alert floor, enumeration bound, overdue marker, constituent instance, largest record, surviving destruction, hold count, horizon alert, entry instant, hold check admitted, hold-blocked, eligibility tuples, lease reading, hold database name, alerting surface, scheduler, compensation window, reconciliation cadence, field cap, hold ids cap, position, invocation id, intent instant, intent abandoned, attributed actors, record destruction pattern.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Substrate composition invocation in `execution-contract.md` — the substrate relation and its instance topology. The section titled Composition state in `execution-contract.md` — the derived-index classification and its obligations. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. verify_record, purge_event, event id, recording instant, start margin: Audit Trail. try_take, remaining, grant, holder value, remaining term, call in flight, no answer: Lease.

Term composing patterns: Policy Reconciliation *(forthcoming)*; Record Destruction *(forthcoming)*; Hold-Aware Audit Retention *(forthcoming)*; Override Authorization *(forthcoming)*; Reverse Index *(forthcoming)*; Failed-Attempt Log *(forthcoming)*; a shred pattern *(forthcoming)*; [Permissions](../atoms/permissions.md); [Duplicate Prevention](../atoms/duplicate-prevention.md).

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

The read-only query answering every retention past its retention deadline, each with its active-hold count, so a dashboard tells *purge-ready* from *hold-blocked*. It writes nothing, refuses only where the retention records cannot be read (Action wiring 111), and states no sibling liveness — a tuple can look ready while an in-window sibling, excluded by construction, still covers its record (`Action wiring 43`).

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

The load-bearing refusal: under strict mode a destruction is refused while any active hold covers the record, whatever the retention clock says (`Invariant 1.1`). The refusal carries the blocking hold ids and count, and the gate's firing is itself recorded, so the refusal is a record rather than a silence.

Kind:       Member
Member of:  the purge rejection
Role:       Rejection
Projection: under-legal-hold

#### Not Eligible

The refusal for a record whose **named** retention has not yet elapsed — the window is still running, so the record may not be destroyed even with no hold over it.

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

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — defensible-retention.tla + 5 twins + 1 probe (the gate under the record section: a purge against a hold placement and a sibling placement; 4,206 states, holding at a term of 7 within 10 ticks) and defensible-retention-outcome.tla + 3 twins + 1 probe (one outcome per destruction: the invocation's outcome, a step-3 refusal whose append lands late, and a sweep leg; 4,222 states, holding at a term of 9 within 12 ticks), re-derived from the page as it stands, 2026-10-04
last gate: 2026-10-06 — Final Critique 13, fresh reader, three passes on one text — 0 foundational, 37 refining reports, 13 rhetorical reports; one sample

open:
- 2026-10-04-d · refining · Term evidence floor; Capability requirement 11, 12 · the retention and purge-delay terms have no declaring requirement, and no check sets a hold's actual life against the longest hold declared → declare; a provable check
- 2026-10-04-e · refining · Term closure floor; Term section work bound; Term sibling floor; Term audit write latency; Reconciliation 21 · a leg's re-read under the section and its lease readings are uncounted and a leg has no work bound the section term must exceed, the latency runs from the issue where Lease's unit runs from the ask, and the sibling floor leaves no pause for the outcome's own reading or the purge-instant read; the worst case is an owed outcome or an early alert → a leg work bound; recount
- 2026-10-04-f · refining · Reconciliation 19, 25, 41; Check 3.3; Term leg · a pending sibling has no window and no alert, and the Term covers a leg over open markers and not one over siblings alone → a window; widen the Term
- 2026-10-04-g · refining · Term within the audit horizon; Term aged-out hold; Check 1.10, 2.1, 2.2 · a hold's act is aged by the placement or release instant a caller may assert, so a hold backdated past the horizon reads aged-out the day it is entered → age it by its intent's recording instant where the intent survives
- 2026-10-04-h · refining · Composition note 6 through 9; Identity 6; Non-goal 22, 23; Action wiring 73, 82, 96; Capability requirement 11, 15, 41, 44, 56 · deployment and caller obligations outside the capability list with no external check, and five requirements naming no supplier → move or cite each
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
- 2026-10-05-j · refining · Action wiring 47, 50, 57, 100, 108; Concurrency 5 through 9 · refusals and the take precede any check of the credential, so an unauthenticated caller holds a section and learns that no active hold exists → authenticate first, or name the non-goal
- 2026-10-05-l · rhetorical · Terms; Composes 7, 12 · the gate, placement, audit instance, hold records, destruction record and eligible each carry two meanings or no entry, Composes 7's letter forbids the instances Composes 1 and 2 hold, and Composes 12 does not name Event Log's read → one term each; name the read
- 2026-10-06-a · refining · Action wiring 59, 68, 80, 81 · a committed purge is to call the purge of every sibling where the sibling floor marks one pending uncalled, a sibling's purge that answers state-unavailable has no arm, and the order of the sibling purges is unstated → condition the call on the floor; add the arm; pin the order
- 2026-10-06-b · refining · Check 1.3, 1.11, 5.9; Invariant 5.3 · a release that committed ahead of a purge and whose outcome is still owed past the compensation window leaves its hold in the historical hold set, and an open marker older than the window that carries no stand-in has no verdict → an open obligation while a release marker stands; a verdict
- 2026-10-06-c · refining · Action wiring 16, 21, 31, 67, 79, 96 · storage-failure lands where nothing committed and where the call may still land, with nothing to tell the two apart, and only a purge has a caller's reading of the retry → carry the position, or a caller rule for each action
- 2026-10-06-d · refining · Primitive policy 1 through 11; Action wiring 45, 73 · a blank retention id has no boundary rule beside the blank hold id's and falls to not-known, which a re-invoking caller reads as a destruction → add the rule
- 2026-10-06-e · refining · Term reconciliation cadence; Reconciliation 2; Term alert floor; Action wiring 110 · the cadence is not said to run start to start, so a backlog's legs can delay the next run's alerts, and the listing has no cap, no page and no collation for its tie → pin start to start; cap the listing
- 2026-10-06-f · refining · Term overdue marker; Term young marker; Action wiring 8 · both edges of the sweep read the intent instant, the now an invocation stamps ahead of its take, so a host stalled between the seam and the take stamps an old instant on a fresh intent and the sweep reads a live invocation's marker as overdue; Resolve a Person's Data Rights now reads both of its edges on the log's recording instant → the log's stamp; found by that composition's round of 2026-10-06
- 2026-10-06-g · refining · Term alert floor; Term enumeration bound · the floor and the bound count one cadence to a run that ends its enumeration and no run that dies part-way, which nothing alerts on and which an auditor reads as a failure → the scheduler's alert; an open-obligation reading; found by the same round, cured there as Resolve a Person's Data Rights Reconciliation 40
- 2026-10-06-h · refining · Action wiring 73; Non-goal 5 · a caller MUST read a re-invoked not-known as a committed destruction, with no exception for a caller that asks the database instead, as Resolve a Person's Data Rights does; and a hold placed over a record under no retention is admitted, so a hold this composition's own records carry over a host-managed record fires no gate → admit the reading; say so where the hold guarantee is stated; reported by the same round
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/defensible-retention.md`; the round and the migration that got it here are in [its history](./defensible-retention.hist.md).

- **2026-10-23 — The composition owns its records' destruction and makes it through a record destruction pattern.** *Chose:* the business retention instance supplied with the composition owning the destruction (Capability requirement 55, Retention Window Record divergence 4), as Audit Trail owns its own instance's, so Retention Window's purge is the state transition alone over it; the destruction made through a record destruction pattern, Record Destruction *(forthcoming)*, which a committed purge calls with the record reference while the grant still has the sibling floor, and which destroys only a record a purged retention names, keeps each confirmation and retries a record a purge left standing, as Retention Window Record divergence 4a through 6 ask of the owner (Capability requirement 66, Action wiring 112, Term record destruction pattern); that call a committing call, so it waits on the intent, the credential and a live reading of the record section as Retention Window's purge does, and its party bound by Lease Capability requirement 8 and 10 beside the constituents (Term committing call, Capability requirement 54, Term sibling floor, Term section work bound); Capability requirement 55 citing Retention Window Capability requirement 5 and 6a through 11, since 4, 4a and 6 are deleted; Term destroyed record's case of a record the storage layer destroyed under a purge that left every retention retained deleted, since nothing is destroyed before Retention Window's write commits; the Intent, [Purge Record], [Under Active Retention], the walkthrough and Term record saying who destroys; open line 2026-10-05-k closed as dissolved and 2026-10-04-j narrowed; rules 499 to 501. *Over:* the record destruction pattern owning the destruction itself, which Retention Window Record divergence 4 grants only to the pattern that wires the instance, and which its Simultaneous retention 6a would make owner of the joint enforcement this composition holds (Capability requirement 45, 46); and the business records kept in the database alone, removed by Retention Window's own purge, which would leave the electronically stored information, communications and non-erasable media this page governs with no one to destroy them. *Because:* the maintainer ruled on 2026-10-23 that every destruction outside the database is owned by a composing pattern, never by Retention Window, whose Record divergence 1 through 2b and Capability requirement 4, 4a and 6 this page's purge had rested on (Retention Window's 2026-10-03 entry: *Defensible Retention keeps a purge that destroys*), and no pattern in the corpus makes that destruction, so the pattern is named as forthcoming. What the gate decides, refuses and records is unchanged.
- **2026-10-21 — The shred pattern named, and the gate's evidence provable.** *Chose:* *shred* (`glossary.md`) where the page wrote *cryptographic shredding*: Non-goal 16, under which a deployment needing a shred composes a shred pattern, with the composing patterns line and the owners NOTE; and *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where it wrote *from the records*, *records-alone* or their like, by wording alone: the Summary, the Intent, the gate's two halves, the [Hold Check Result] and [Hold Override] term entries, the override and spoliation examples, the acceptance bar and open line 2026-10-04-d; rules 499 to 499. *Over:* the phrases restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Non-goal 16 changed and no obligation did.
- **2026-10-20 — The store's guarantees cited, not restated, and a store-only act's intent, write and outcome one transaction.** *Chose:* Capability requirement 65 citing Execution Contract Store 1 through 4 for the store of the three constituent instances; the rules restating what that store guarantees tombstoned to it (Capability requirement 49, External check 12); and the machinery that existed only because a placement's, a hold placement's or a hold release's intent, constituent write and outcome could come apart — the audit append held out of the act's transaction, each outcome ordered after its constituent commit, the ids a placement intent carried so the sweep could name the act an open marker had made, the read and the cap that list needed, the id a placement's outcome-position failure carried, and the index entries a recovered placement added (Atomic writes 1 through 4, Action wiring 102, 103, 104, 105, 107, Reconciliation 10, Composition state 34), with the reading of a recording-failure at step 4 as a landed record, a split Audit Trail's own rewrite removed (Audit arm 3, 4). Rules 513 to 499. *Over:* an audit append no host transaction could enlist, so that a store-only act's outcome followed its constituent's commit and the sweep recovered whatever a crash between the two left. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice, written in the same transaction as the refusal: so a refused act's intent still stands for the sweep to close as abandoned (Reconciliation 9, 28), the purge, whose destruction is an act outside the store, keeps its intent, its outcome and the sweep that recovers them, and the two indexes stay derived indexes outside every action's transaction (Composition state 20). What the composition does for its domain is unchanged.
- **2026-10-05 — The horizon is read from the log, the store answers what the index did, a record is sized whole, and one instance serves one composition.** *Chose:* a destroyed event later in the log as the sign that an intent's outcome may have aged out — an intent with such a stand-in is no open marker and the sweep leaves it — and the same reading for an auditor's pairing checks (Term stand-in, Reconciliation 5, 42, Check 5.4, 5.5, 6.5 through 6.7); one audit retention policy over every event the composition records, kept for the life of the instance (Capability requirement 57, 60); the horizon above an alert floor, with the escalation raised ahead of any take (Capability requirement 58, Reconciliation 43); the largest record sized whole against the payload cap before the first audit record is issued (Primitive policy 14, 23); not-known and the listing decided on Retention Window's store, and [Purge Eligible] refusing where that store cannot be read (Action wiring 32, 44, 45, 110, 111); a failed read ahead of the commit a storage-failure and after it an owed outcome, and an outcome the section admits no call of owed (Action wiring 98, 99, 109, Concurrency 34); a gate record owed only as the audit arms read it (Action wiring 85, Term owed record); one instance of the composition for each constituent instance (Capability requirement 59). *Over:* an edge a clock decided alone, which allowances and a leg's own span narrowed and never closed; an index a lost entry could make lie; field caps under a cap the substrate measures over the whole envelope; a gate record that had not landed, a condition three other rules also answered. *Because:* Resolve a Person's Data Rights' gate found its horizon assumed single and exact, and this page carried the same assumption (the batch rule — reference first, then swept, one closing round); the rest is what eighteen reader runs found on the way to one clean text, each a state two implementations would have answered differently. The models stand: no rule either one reads was changed.
- **2026-10-04 — Every act over a record runs under one record section, and the late hold is closed here.** *Chose:* a [Lease](../atoms/lease.md) on the record reference, taken before the gate read and held to the outcome by a placement, a hold placement, a hold release, a purge and a sweep leg (Concurrency 5 through 24, Reconciliation 20, 21, 30, 31); the atom's sizing rules stated as this composition's own over two kinds of write, a committing call on a live reading and a record_action above a start floor (Capability requirement 37 through 44); one refusal, section-unavailable, for a section held or run out before anything committed; the deployment bound to place and purge through this composition alone (Capability requirement 45 through 47). *Over:* a serialization the deployment owed and no rule sized (Capability requirement 34, 35, tombstoned), a late-hold race the page named and declined to close (Concurrency 1 through 3, tombstoned), and a sweep serialized on an invocation id by no declared means. *Because:* Retention Window re-grounded on Final Critique 7 obliging the pattern that owns joint enforcement to serialize a placement, the sibling read, a purge and a destruction over one record reference (its Simultaneous retention 5, 6), and Lease grounded on Final Critique 4 with the rules to do it by. Closes Ledger line 2026-10-03-a. The model is re-derived: the old one made the gate and the destruction one step, so it could not show the race at all; the 2026-08-29 line asking for the sweep in the model closes with it.
- **2026-10-04 — What the constituents now say is read as they say it.** *Chose:* a storage-failure from Retention Window's purge read as the retention retained and never as the record intact, with the deployment's destruction record named as where the record's fate is answered (Atomic writes 8, 9, Reconciliation 32, External check 8); the hold store's name matched at the gate (Action wiring 77, 78); the substrate's refusals read by the step they carry, and a step-3 failure never retried, since an append that did not answer may still land (Audit arm 2, 12, 13, 16, 17); a hold's order against a destruction decided against the purge intent, which lands under the section between the gate read and the destruction, and not against an outcome the sweep may write long after (Invariant 6.3, Check 1.4); a placement over a destroyed record refused and a pending sibling left to the sweep alone, since a purge call over one wrote a second record purged outcome for one destruction (Action wiring 93, 94, 95); a release ordered against a destruction by its intent's log position, as a placement is, since the two instants are read at two seams (Invariant 6.5, Check 1.3, Check 1.8); a sibling read as elapsed only past the clock offset allowance (Term elapsed retention); an outcome owed by a committed act and not by an admitted one, which a constituent may still refuse (Term committed purge); Invariant 7.4 tombstoned for Action wiring 53, and Invariant 1.2 restated as what a blocked purge never answers (Invariant 1.2, 1.5, 1.6); a recovered purge or release paired with the latest marker, which is the one that committed, and a placement paired by the ids its intent carries, since two placements with the same inputs are two acts and an old record with those inputs is none of them (Reconciliation 10 through 14, 34 through 38, Action wiring 102, 103, Concurrency 27, 28); the checks given a reading past the audit horizon, where a lawful act's own record has aged out (Check 1.10, 3.2, 3.4, 6.4); the section held over a step-3 refusal, whose append may still land (Concurrency 25); a release bound to this composition's surface as a placement is (Capability requirement 53). *Over:* a WHY that called the record intact after a failed purge, a gate that matched no store name, arms keyed on a source the substrate no longer reports, and a log-position test that read a recovered destruction as later than a hold it preceded. *Because:* each was a constituent's own rule this page contradicted or did not meet (Retention Window Purge persistence 1, 1a; Legal Hold Instance 5 through 7; Audit Trail's record action step 7), found by reading the three constituents as they stand after this campaign and by the three passes over the result.
- **2026-09-27 — The sweep can write the destruction record it owns, a closed marker stays closed, and the purge refusals take an order.** *Chose:* the purge intent carries the hold check result (Action wiring 76); intent_abandoned is an outcome; the not-eligible and under-active-retention rules apply only once the hold check admitted the destruction, and the second only over an elapsed named retention; a gate record that cannot land answers `recording-failure(gate)`. *Over:* a recovery outcome needing a hold check result no store carried, so every owed destruction record closed as abandoned; a closing no rule counted as an outcome, so the sweep re-closed it every run and Invariant 5.6 failed for every abandoned invocation; three refusal rules that could each demand their own answer for one call; and a position token with no member for the gate record. *Because:* the cold regeneration of 2026-09-27 met each — the owed record the 2026-09-14 decision gave the sweep could never be written.
- **2026-09-14 — A constituent's storage failure surfaces as itself, and this composition's own recording failure carries its position.** *Chose:* storage-failure exported unchanged from all four state-changing actions, and `recording-failure(intent | outcome)` on every one of them. *Over:* the prose's mapping of a constituent storage-failure onto recording-failure, and a bare recording-failure on the three non-destructive actions. *Because:* the first renamed a failure to *write a record* into a failure to *record it*, which is a different fact and a different repair; the second put one token on both sides of the commit, so a caller who retried on it could not know whether anything had committed — which the corpus's own rule requires the exported code to answer.
- **2026-09-14 — The owed destruction record has exactly one writer.** *Chose:* an invocation retries its outcome until the retention completion bound and then yields; past the bound the record belongs to the sweep, which serializes its leg on the act's invocation id and re-reads the act's outcome under that serialization. *Over:* an out-of-band retry and a sweep both owing the same record with nothing between them. *Because:* two writers over one destruction land two record_purged events for one act, and the trail then protects both — the one failure a compensating write cannot undo.

NOTE: End of Defensible Retention.

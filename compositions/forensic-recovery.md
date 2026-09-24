---
title: Forensic Recovery
parent: Conceptual Compositions
nav_order: 18
has_toc: true
toc: true
---

# Forensic Recovery

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Forensic Recovery makes soft deletion forensically complete. Every delete, restore, and purge action against a record is attributed (the acting actor verified via credential), tamper-evident (the Audit Trail substrate seals each event), and retention-governed (the audit events are placed under retention).

The composition's headline emergent guarantee is **full ordered lifecycle history recoverability**: a single forensic read action, [Recover History], reconstructs the complete delete/restore/purge history of any record from the Audit Trail event stream — including prior epochs that Soft Delete's current-state-only summary overwrites — proving, from the records alone, that no record was purged without an auditable record naming who purged it, when, and under what stated authority.

Neither Soft Delete (no tamper-evidence, current-state attribution only) nor Audit Trail (no lifecycle-continuity model) provides this guarantee alone; the composition's lifecycle-transition ⇒ audit-event binding is what makes it emergent.

---

## Intent

A record's destruction lifecycle carries two distinct obligations that neither Soft Delete nor an audit substrate satisfies alone. The first is *lifecycle faithfulness*: every step of the Active → Deleted → Purged path — including every restore that returns a record to Active — is individually attributed to a named, verifiable actor, placed in an immutable event stream in the order it occurred, and sealed against post-hoc modification. The second is *full-history recoverability*: given any record_id, an investigator must be able to reconstruct the complete ordered sequence of what happened to that record — all the deletes, all the restores, the final purge — not just a snapshot of the most recent state.

Soft Delete provides a lifecycle state machine and current-state attribution: who most recently deleted the record, who most recently restored it, and who purged it. This is a deliberate design choice — Soft Delete is a freestanding (specifiable without naming any other pattern) atom, and retaining a full ordered history would absorb the Event Log concept, breaking that freestanding status. The atom's Behavior section is explicit: "The atom retains only the most recent attribution in each category; the full cycle history requires Event Log composition." The atom's Edge cases name the gap precisely: *"full history of all cycles requires composition with Event Log."* The composition is exactly where that gap is filled.

Audit Trail provides attribution, tamper-evidence, and retention governance for events it is explicitly told about, but it does not know what a deletion lifecycle is. It does not know that a `record_action` labeled `record.soft_deleted` must be followed (eventually) by either `record.restored` or `record.purged` for the same record_id. It cannot reconstruct the lifecycle of a specific record across multiple events without a binding structure that names which events belong to which record's lifecycle. The composition provides that binding via its emergent composition state — `record_to_events`, the ordered map from record_id to the sequence of Audit Trail `event_id`s for that record's lifecycle transitions.

The load-bearing emergent guarantee this composition exists to enforce is: **no record reaches Purged without an attributed, tamper-evident Audit Trail event naming who purged it, when, and under what stated reason — and the full ordered history of every prior lifecycle transition is recoverable from the same event stream.** The [Recover History] action is the forensic read surface: it builds the record's reconciled transition sequence from the substrate's lifecycle events and the `record_to_events` index (Action wiring 21), returns every transition in order, and calls `AuditTrail.verify_record` on each event to produce a verified, seal-confirmed, retention-governed history with no gaps.

One boundary this composition does not cross is critical to name in Intent: **this composition does not gate purge eligibility.** It does not check whether a Legal Hold is active, whether the Retention Window has elapsed, or whether any other governance condition permits destruction. That gate belongs to [Defensible Retention](./defensible-retention.md), and absorbing it here would duplicate Defensible Retention's hold-blocks-purge logic — the defining emergent invariant of a separate composition. This composition is the *forensic attribution* composition: it records every lifecycle transition faithfully, makes each attributed and tamper-evident, and makes the full history recoverable. Whether a given purge was *permissible* — whether the actor had authority, whether the hold check was clear — is the composing peer's (Defensible Retention's) question. An auditor using this composition can determine *what happened and to whom*, and can verify the records' integrity; whether *what happened was authorized* requires Defensible Retention's records (the hold-check audit events) and external evidence (the Permissions registry). This composition names this boundary explicitly in each relevant section rather than silently absorbing a responsibility that belongs elsewhere.

This is a composition, not a new primitive. Soft Delete and Audit Trail are unchanged. The composition is the wiring that makes them coherent as a single forensic-deletion surface. It introduces four emergent actions — [Recover History] and the three lifecycle-wrapping actions [Delete Record], [Restore Record], [Purge Record] — that belong to neither constituent alone and exist only because the two are wired together. [Recover History] in particular belongs to neither alone: Soft Delete can return the current-state summary, but it cannot return the full ordered history because it discards prior epochs; Audit Trail can return all events matching a query, but it cannot identify which events constitute a deletion lifecycle for a specific record without `record_to_events`. The composition is the layer that answers: *what is the complete attributed, sealed, historically-ordered deletion lifecycle of this record?*

---

## Composes

- **[Soft Delete](../atoms/soft-delete.md)** — the recoverable-destruction lifecycle: the Active → Deleted → Purged state machine with the Deleted → Active restore, the current-state attribution of each kind, and the rule that a record passes through Deleted before it is purged.
- **[Audit Trail](./audit-trail.md)** — the regulated-audit substrate: every lifecycle action records through it, and each record is appended to Event Log, attested by Actor Identity, placed under Retention Window and sealed by Tamper Evidence at the configured cadence.

```
Composes 1: EXACTLY ONE Soft Delete instance MUST serve the composition.
Composes 2: EXACTLY ONE Audit Trail instance MUST serve the composition.
Composes 3: The composition MUST reach a transitive atom ONLY through Audit Trail.
Composes 4: The composition MUST NOT compose an instance of a transitive atom.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST NOT share the Soft Delete instance with another writer.
Composes 8: The composition MUST call a Soft Delete write ONLY inside a lifecycle action.
Composes 9: The composition MUST select the lifecycle events through the lifecycle enumeration.
Composes 10: The composition MUST read an event's metadata ONLY through the record read.
Composes 11: The composition MUST NOT read an Audit Trail store directly.
Composes 12: IF the lifecycle enumeration answers invalid-query THEN the deployment MUST alert on a configuration fault.
Composes 13: The composition MUST NOT answer invalid-query from the lifecycle enumeration to a caller.
```

Term composition: this pattern's wiring of [Soft Delete](../atoms/soft-delete.md) and [Audit Trail](./audit-trail.md) — the three lifecycle actions, the forensic read, the lifecycle index and the reconciliation.

Term constituents: [Soft Delete](../atoms/soft-delete.md), [Audit Trail](./audit-trail.md).

Term transitive atoms: [Event Log](../atoms/event-log.md), [Actor Identity](../atoms/actor-identity.md), [Retention Window](../atoms/retention-window.md) and [Tamper Evidence](../atoms/tamper-evidence.md), reached through Audit Trail.

Term Soft Delete write: Soft Delete's soft_delete, restore or purge.

Term lifecycle enumeration: Event Log's read by sequence-number range with an open upper bound, passed through Audit Trail unchanged, with every selection by action reference and payload field made in the composition's own code.

Term record read: Audit Trail's read_record on an event id — the substrate's declared consolidated read surface.

Term audit write: Audit Trail's record_action.

Term verification: Audit Trail's verify_record on an event id and a presentation.

WHY:
**Soft Delete** supplies the state machine and the current-state attribution — who most recently deleted the record, who most recently restored it, who purged it — and by its own design retains nothing older: a freestanding atom that kept a full ordered history would absorb Event Log. Its own text names the gap this composition fills: the full history of all cycles requires composition with Event Log, and Actor Identity is what attests that its attribution references are real, credentialed actors. The composition calls its three writes and its read, and nothing else writes it (Composes 7 and 8) — the precondition Invariant 4's reverse direction rests on, since a direct write would be a transition with no audit event.

**Audit Trail** supplies attribution, tamper evidence and retention for the events it is told about, and knows nothing of a deletion lifecycle — that a delete is followed by a restore or a purge for the same record. Its four atoms are reached through it and never instanced here (Composes 3 and 4), per the section titled Compositions of compositions in `spec-format.md`.

**The lifecycle enumeration is declared, not assumed** (Composes 9 through 13). Every records-alone claim on this page that quantifies over the lifecycle events — the lifecycle rebuild, [Recover History]'s reconciliation and residue, the read-backs, the orphan pre-check, the reconciliation and the conformance checks — selects by action reference and by a payload field, and the substrate serves no such read: Event Log routes lookup by payload field to a Reverse Index pattern *(forthcoming)*, and Audit Trail passes its range read through unchanged and absorbs nothing more. So the route is the pass-through range read with the selection made in composition code, exactly as the substrate's own rebuilds enumerate and filter; a deployment composing Reverse Index over the log may use it to accelerate the selection, and the enumeration stays the route an auditor reproduces. invalid-query on it is a configuration fault, alerted on and never a caller outcome. **Its totality is bounded by the audit horizon**: the substrate's purge destroys an event's payload whole, so a selection on a payload field cannot see a purged event — the reason Composition state splits the lifecycle index at the horizon and [Recover History] reconciles rather than re-reads. Id-addressed reads go through the record read, which the substrate does declare (Composes 10 and 11).

Adjacent, **not** constituents: [Defensible Retention](./defensible-retention.md) (the purge-eligibility gate); [Permissions](../atoms/permissions.md) (authority); [Chain of Custody](./chain-of-custody.md) (the caller-presented verification it mirrors).

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the lifecycle index.
Composition state 2: The composition MUST key the lifecycle index by record id.
Composition state 3: A lifecycle entry MUST carry an outcome event id AND the intent position of the intent event the outcome event names.
Composition state 4: The composition MUST order a record's lifecycle entries by intent position.
Composition state 5: The composition MUST insert a lifecycle entry at the entry's intent position.
Composition state 6: The composition MUST NOT remove a lifecycle entry.
Composition state 7: The composition MUST insert a lifecycle entry ONLY AFTER the entry's outcome event lands.
Composition state 8: A lifecycle entry's outcome event MUST carry the entry's record id.
Composition state 9: The composition MUST classify a live entry as a derived index.
Composition state 10: The composition MUST rebuild a missing live entry PER the lifecycle rebuild.
Composition state 11: The composition MUST classify a purged entry as extraction-pending against Erasure Tombstone.
Composition state 12: A purged entry MUST keep the entry's intent position.
Composition state 13: The deployment MUST persist the lifecycle index PER the index durability.
Composition state 14: The composition MUST store the enumeration mark.
Composition state 15: The composition MUST rebuild a missing enumeration mark as the greatest intent position the lifecycle index carries.
Composition state 16: IF the lifecycle index carries no entry THEN the rebuilt enumeration mark MUST carry zero.
Composition state 17: IF a read-back from the enumeration mark misses the event THEN the composition MUST re-read from the log's start.
Composition state 18: The reconciliation MUST NOT read the enumeration mark.
Composition state 19: The composition MUST NOT duplicate a constituent's store.
```

Term record id: the opaque byte-identity of a record in Soft Delete's store.

Term lifecycle index: the composition's map from a record id to the ordered lifecycle entries of the record — `record_to_events` in an implementation.

Term lifecycle entry: one outcome event id with an intent position — one lifecycle transition, one outcome event, one binding.

Term intent position: the Event Log sequence number of the intent event an outcome event names by the outcome's intent event id — the transition's occurrence key.

Term live entry: a lifecycle entry whose outcome event's payload the audit horizon has not reached.

Term purged entry: a lifecycle entry whose outcome event's payload the audit horizon has destroyed.

Term lifecycle rebuild: the lifecycle enumeration from the log's start, kept to the outcome events, grouped by the payload's record id, each group ordered by the intent position its intent event id resolves to through the record read.

Term enumeration mark: the highest sequence number this instance has read back through the lifecycle enumeration — `enumeration_high_water` in an implementation; the lower edge of a read-back.

WHY:
**The key is the intent's position, not the outcome's, and the choice is load-bearing** (Composition state 3 through 5). The intent record is written inside the record exclusion before the transition commits and is never re-emitted, so under the whole-action exclusion (Concurrency 1) intent order *is* commit order, structurally and without a timestamp. An outcome event's own position is not: a compensated outcome lands whenever the compensation lands — after a later transition's outcome, if a restore ran while a delete's audit write was being retried — and a replay ordered by outcome position would show the record restored before it was deleted. The compensating event carries the original intent event id unchanged, so the key survives compensation, and a late-landing compensation takes the place its intent already fixed rather than the end of the list — the one reorder the list admits is not one, since the key was settled before the transition committed.

**The index is split by retention state** (Composition state 9 through 13; the section titled Composition state in `execution-contract.md`). A live entry is a derived index: outside the two truth-bearing writes — the Soft Delete transition and the outcome event — rebuilt on a miss, carrying no cross-constituent consistency claim, and its insertion is *evidence* the binding was met, never a peer write the compensation must handle. A purged entry is extraction-pending: its loss is data loss, not a rebuild trigger. **The split is forced rather than fastidious.** The rebuild filters on action reference and groups by the payload's record id, and the substrate's purge destroys the payload whole, leaving the event id and the sequence number — so past the horizon neither rebuild key is readable. Meanwhile the retention asymmetry (Retention asymmetry 1) keeps those events in the history as lawfully destroyed, which is possible only if the index holds an event id no rebuild regenerates. **The fact is already captured, which is what makes this cheap**: Audit Trail had to *capture* its purged pair into the destruction record because nothing else held it; here the event id is written when the transition commits, long before any purge, so the treatment is a durability obligation rather than a capture mechanism (Composition state 13). The named eventual home is the same Erasure Tombstone *(forthcoming)* that carries Audit Trail's purged pair. A purged entry keeps its intent position (Composition state 12) — the intent's payload is destroyed at the same horizon, but its sequence number is what the entry recorded — which is what lets it keep its place in the replay.

**A missing entry is a rebuild trigger, and an entry that does not point back is a finding** (Composition state 8 and 10). A committed transition whose rebuild yields no outcome event is the real orphan, surfaced by the reconciliation; an outcome event id in the index whose payload's record id names another record is Invariant 4's inverse orphan, unreachable through this wiring.

**The enumeration mark** (Composition state 14 through 18) is a derived index that makes a read-back a short tail read rather than a full enumeration in the healthy case. A lost or stale mark costs one thing: the read from it comes back without the event and falls back to the log's start, which is total for a live payload — so a miss is observable and never writes a wrong id. The reconciliation and every conformance check read from the log's start and never consult it.

The Soft Delete store and the Audit Trail stores are owned by their instances; the composition indexes into them and duplicates none (Composition state 19).

### Capability requirement

```
Capability requirement 1: A deployment MUST set the audit retention policy on the Audit Trail instance.
Capability requirement 2: The composition MUST NOT pass a retention input to the audit write.
Capability requirement 3: A regulated deployment MUST set an audit retention policy encoding the regime's minimum audit-record retention.
Capability requirement 4: A deployment MUST set the seal cadence on the Audit Trail instance.
Capability requirement 5: The composition MUST NOT override the seal cadence.
Capability requirement 6: A deployment MUST provision the recovery identity.
Capability requirement 7: A deployment MUST set the transition completion bound.
Capability requirement 8: IF the transition completion bound EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 9: A deployment MUST set the outcome retry attempts.
Capability requirement 10: A deployment MUST size the outcome retry attempts to complete WITHIN the transition completion bound.
Capability requirement 11: The host MUST supply the record exclusion keyed by record id.
Capability requirement 12: The host MUST release the record exclusion on the holder's return.
Capability requirement 13: The host MUST release the record exclusion on the holder's death.
Capability requirement 14: IF the host holds the record exclusion as a lease THEN the host MUST set the lease length to the transition completion bound.
Capability requirement 15: The composition MUST read a lease's expiry as the holder's terminus.
Capability requirement 16: IF the host supplies no record exclusion THEN the composition MUST refuse to start.
Capability requirement 17: A deployment MUST set the compensation window.
Capability requirement 18: A deployment MUST set the reconciliation cadence.
Capability requirement 19: A deployment MUST disclose the outcome write latency.
Capability requirement 20: The composition MUST start ONLY IF the compensation window EXCEEDS the liveness sum.
Capability requirement 21: A deployment MUST set the intent candidates cap.
Capability requirement 22: A deployment MUST declare the index durability.
Capability requirement 23: The index durability MUST NOT fall below the Soft Delete store's durability.
Capability requirement 24: The wired Audit Trail instance MUST expose the lifecycle enumeration.
Capability requirement 25: A deployment MAY set the permissions scope prefix.
Capability requirement 26: The composition MUST NOT gate an action on the permissions scope prefix.
Capability requirement 27: The host MUST inject now at the seam once per invocation.
Capability requirement 28: The host MUST inject the reconciliation's now at the reconciliation's own seam.
```

Term audit retention policy: the policy reference configured on the composition's single Audit Trail instance, governing the lifetime of every lifecycle event — never the Soft Delete records themselves.

Term audit horizon: the audit retention policy's horizon, past which a lifecycle event's payload is lawfully destroyed.

Term seal cadence: Audit Trail's per-event | interval-based | on-demand setting, which fixes each lifecycle event's covering range.

Term recovery identity: a deployment-provisioned actor reference and credential under which the reconciliation attests every write it makes, and under which an invocation re-attests an outcome record the caller's credential can no longer land.

Term transition completion bound: the longest a lifecycle action may run from its intent record to its outcome record, retries included — the invocation's terminus, the lease length and the reconciliation's lower edge.

Term outcome retry attempts: how many times an invocation re-attempts a refused outcome record before it yields the orphan — the counted terminus, since an invocation holds one now and watches no clock.

Term record exclusion: the host-supplied mutual exclusion on a record id under which a lifecycle action runs from its orphan pre-check to its answer, and which the reconciliation takes for every record it compensates.

Term compensation window: the duration within which an orphan's outcome event lands or the orphan is escalated.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every restart.

Term outcome write latency: the deployment's disclosed bound on one audit write landing — attestation, append and retention placement.

Term liveness sum: `transition completion bound + reconciliation cadence + outcome write latency`.

Term intent candidates cap: the most intent candidates one compensating event may name.

Term index durability: the durability the deployment owes the lifecycle index, stated as an ordering against the Soft Delete store's.

Term permissions scope prefix: the optional prefix naming the scopes a Permissions pattern wired above the composition checks — forensic:delete, forensic:restore, forensic:purge and forensic:read.

Term seam: the composition's input and output boundary — the one place the host reads the clock, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the wall-time reading the host injects at the seam, once per invocation.

WHY:
**Retention and cadence are the substrate's, set once** (Capability requirement 1 through 5). record_action takes no per-call retention argument, so every lifecycle event inherits the instance's policy; a GDPR (EU General Data Protection Regulation) Article 17 deployment's policy accounts for the retention of the erasure's own audit record (Non-goal 4), and a HIPAA (Health Insurance Portability and Accountability Act) §164.312(b) deployment's encodes the minimum audit-record retention. **The cadence sets the shape of every verification presentation.** [Recover History] presents each event's whole covering range (Audit Trail Invariant 7), so under an interval or on-demand cadence one event's check re-presents every seal-mate — intent records and unrelated actions included — and a lawful purge of any seal-mate leaves the survivors unverifiable with partially-purged coverage, a standing answer absent a composed Seal Lifecycle pattern. **Per-event cadence is the recommended wiring for a lifecycle-history instance**: each presentation is a singleton, each purge isolates to its own event, and the unsealed tail — the window in which tampering is structurally undetectable — is as narrow as it gets. An interval cadence remains admissible where the deployment accepts the range-shaped presentation and that standing answer.

**The recovery identity** (Capability requirement 6) attests every write the reconciliation makes, because the actor's credential is never persisted, and every in-invocation re-attestation after the caller's credential is revoked between the intent and the outcome, because repetition cannot land a deterministic refusal. Events it attests carry the recovery flag and name the original actor, so the record shows which operational identity attested the compensation and which actor performed the transition — the composition-actor convention Multi-Party Approval established. A deployment wiring a credential pre-check above the composition may never exercise it and still declares it wherever the arm is reachable.

**The bound, the count and the exclusion are one terminus** (Capability requirement 7 through 16; the section titled *A compensator is exclusive* in `pressure-testing.md`). An invocation holds the record exclusion across its outcome retries and has yielded by the bound, so the reconciliation's lower edge and the invocation's last possible write are the same instant and the two never both land an outcome for one transition. The count is how the invocation knows it has reached the bound without a clock; the deployment sets the count so every attempt completes inside it. The exclusion is this composition's own obligation on the deployment — Soft Delete serializes its own transitions on a record and declares nothing wider (the section titled *Capability provenance* in `pressure-testing.md`, the multi-call-section tell). As a lease it is exactly the bound long: at least the bound, so no live invocation is preempted inside its retries, and no longer, so the time a stalled holder keeps the reconciliation off a record is bounded by the bound — and its expiry is the invocation's terminus. That hold time is why the liveness sum's first term is the bound and not a separate lease term.

**Liveness is arithmetic** (Capability requirement 17 through 20; the section titled *Liveness is arithmetic* in `pressure-testing.md`). An orphan created at *t* is invisible to the reconciliation until *t* plus the bound; the next run is at most a cadence later; the compensating write lands a latency after that. *A cadence no longer than the window* is satisfied by a deployment that breaches on every orphan, so the three terms are checked at start and a deployment failing the strict inequality refuses to start. The latency is observed at the deployment, so it is disclosed rather than derived.

**The candidates cap** (Capability requirement 21) keeps the compensation payload — the outcome's fields plus the recovery flag, the acting actor reference and the candidate set — inside the envelope a lifecycle action sizes before its intent (Primitive policy 7). **The index durability** (Capability requirement 22 and 23) is an ordering, not a number: the purged half of the index is the only carrier of those transitions' existence, so it is at least as durable as the store it keys.

**The permissions scope prefix is a naming, not a gate** (Capability requirement 25 and 26): the deployment wires Permissions at the calling layer under those scope names; absent it, the composition records whoever presents a credential that verifies (Invariant 6), and authority stays the composing layer's (Non-goal 3).

**One now per invocation** (Capability requirement 27 and 28): the intent's intended instant, the Soft Delete transition instant and the outcome's recorded instant carry the same reading (Clock semantics 1). The reconciliation is a composition process with no caller, so its reading is injected at its own seam rather than borrowed from a constituent.

### Primitive policy

```
Primitive policy 1: IF the record id EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 2: IF the actor reference EQUALS blank THEN the lifecycle action MUST answer invalid-request.
Primitive policy 3: IF the reason EQUALS blank THEN [Purge Record] MUST answer invalid-request.
Primitive policy 4: The composition MUST compare a record id byte-exact.
Primitive policy 5: The composition MUST NOT normalize a caller string.
Primitive policy 6: The composition MUST NOT inspect a credential.
Primitive policy 7: A lifecycle action MUST NOT record the intent BEFORE sizing the envelope.
Primitive policy 8: The envelope MUST size the outcome payload AND the compensation payload against Audit Trail's payload cap.
Primitive policy 9: The envelope MUST size the compensation payload under the longer of the actor reference AND the recovery identity's actor reference.
Primitive policy 10: IF a sized payload EXCEEDS the payload cap THEN the lifecycle action MUST answer invalid-request.
Primitive policy 11: An action refused under Primitive policy 1 through 10 MUST NOT write.
Primitive policy 12: The composition MUST pass the actor reference to the audit write as the actor reference AND to the Soft Delete write as the transition's attribution.
Primitive policy 13: The composition MUST pass a supplied reason to the Soft Delete write unchanged.
Primitive policy 14: The composition MUST compare an event id byte-exact.
```

Term actor reference: the opaque reference to the actor performing a lifecycle action — actor_ref.

Term credential: the opaque credential material the audit write validates against the actor registry's public material for the actor reference.

Term reason: the stated justification a lifecycle action carries — required on [Purge Record], optional on [Delete Record] and [Restore Record].

Term event id: the opaque, system-generated id Event Log assigns an event.

Term outcome payload: the record id, the reason, the transition instant and the intent event id.

Term compensation payload: the outcome payload with the recovery flag, the acting actor reference and up to the intent candidates cap of intent candidates, behind a recovery intent.

Term caller string: a record id, an actor reference or a reason.

Term envelope: the serialized payload with the transition's action reference under Audit Trail's reference length cap and the attestation id at the substrate's declared width.

WHY:
Every string-typed input is validated here or by a constituent, before any constituent call, and nothing is case-folded, trimmed or normalized (Primitive policy 1 through 5 and 14); a deployment wanting normalization wires it at the calling layer. The whitespace rule is Soft Delete's own, applied before the call so a refusal writes nothing. The credential is opaque here: it is consumed only inside the audit write, by Actor Identity within the substrate, and **that validation is reached before anything commits** because every lifecycle action opens with an intent record (Invariant 6). The Actor Identity surface is reached only transitively — the composition composes no Credential or Actor Identity instance — which is exactly why the *position* of the audit write is load-bearing.

**Size the largest record, not the intent** (Primitive policy 7 through 10; the section titled *An outcome is sized before the intent* in `pressure-testing.md`). The intent is the smallest record an action writes; the outcome, and the compensation the reconciliation would write for it, are larger, and the compensation is attested under the recovery identity, whose actor reference may be the longer. An over-long reason is the reachable case, and it is refused here, before the intent — never discovered over a committed transition, and for [Purge Record] never over a destroyed record.

### Audit arm

```
Audit arm 1: IF Audit Trail answers invalid-credential at an intent record THEN the lifecycle action MUST answer invalid-credential.
Audit arm 2: IF Audit Trail answers recording-failure carrying a pre-append step at an intent record THEN the lifecycle action MUST answer recording-failure carrying intent.
Audit arm 3: IF Audit Trail answers recording-failure carrying the retention step at a record THEN the composition MUST read the record's event id back.
Audit arm 4: IF Audit Trail answers invalid-request at a record THEN the composition MUST read the record's event id back.
Audit arm 5: IF the read-back finds the record THEN the composition MUST proceed as landed.
Audit arm 6: The composition MUST name a record read back as landed in the unretained field.
Audit arm 7: The composition MUST NOT retry a record the read-back finds.
Audit arm 8: IF the read-back finds no intent record THEN the lifecycle action MUST answer invalid-request.
Audit arm 9: The composition MUST NOT retry an intent record answered with invalid-request.
Audit arm 10: IF Audit Trail answers recording-failure carrying a pre-append step at an outcome record THEN the invocation MUST retry the outcome record under the record exclusion.
Audit arm 11: The invocation's retries of one outcome record MUST NOT EXCEED the outcome retry attempts.
Audit arm 12: IF Audit Trail answers invalid-credential at an outcome record THEN the invocation MUST record a recovery intent under the recovery identity.
Audit arm 13: A re-attested outcome record MUST carry the recovery flag AND the actor reference as the acting actor reference.
Audit arm 14: The invocation MUST NOT record a re-attested outcome record BEFORE the recovery intent lands.
Audit arm 15: IF no outcome record lands THEN the lifecycle action MUST answer recording-failure carrying outcome AND the finding.
Audit arm 16: IF the read-back finds no outcome record after an invalid-request THEN the finding MUST carry invalid-request as the cause.
Audit arm 17: The composition MUST escalate an orphan whose cause EQUALS invalid-request.
Audit arm 18: An invocation answering recording-failure carrying outcome MUST release the record exclusion.
Audit arm 19: The invocation MUST NOT append an outcome record BEFORE re-reading the lifecycle enumeration for an outcome naming the intent event id under the record exclusion.
Audit arm 20: IF the re-read finds an outcome naming the intent event id THEN the invocation MUST proceed as landed.
Audit arm 21: IF the invocation's lease expired THEN the invocation MUST NOT re-read BEFORE re-taking the record exclusion.
Audit arm 22: IF the invocation's lease expired AND the re-read finds no outcome THEN the lifecycle action MUST answer recording-failure carrying outcome AND the finding.
Audit arm 23: An invocation whose lease expired MUST NOT append an outcome record.
Audit arm 24: An intent read-back MUST match the kind's intent event carrying the record id, now as the intended instant AND the caller's actor reference.
Audit arm 25: An outcome read-back MUST match the kind's outcome event carrying the intent event id.
Audit arm 26: A read-back MUST read the lifecycle enumeration from the enumeration mark.
Audit arm 27: A caller MUST read recording-failure carrying intent as a committed nothing.
Audit arm 28: A caller MUST read recording-failure carrying outcome as a committed transition.
Audit arm 29: The deployment MUST alert on a record named in the unretained field.
Audit arm 30: The deployment MUST alert on an invalid-request from Audit Trail as a deployment fault.
```

Term intent record: the record a lifecycle action writes before its Soft Delete write — the intent event of the action's kind.

Term outcome record: the record a lifecycle action writes after its Soft Delete write — the outcome event of the action's kind.

Term pre-append step: a recording-failure step naming a step before the substrate's append — step-2 or step-3; the event is not in the log.

Term retention step: the recording-failure step naming the substrate's retention placement — step-4; the event is appended and attested, and only its retention failed.

Term position: intent | outcome carrying the finding — where a recording-failure sat: intent, nothing committed and the whole action may be retried; outcome, the Soft Delete transition exists.

Term finding: the record id, the transition kind, the intent event id and the cause — the orphan named in the answer that reports it.

Term cause: step-2 | step-3 | invalid-credential | invalid-request — why the outcome record did not land.

Term unretained field: the optional field of a lifecycle result naming the intent or outcome event whose retention placement the substrate reported failed.

Term recovery intent: the record.recovery_intended event — naming the record id, the transition kind and the intent reference an outcome under the recovery identity is about to bind.

Term recovery flag: recovery set to true on an outcome event attested under the recovery identity.

Term acting actor reference: the actor who performed a transition, carried in the payload of an outcome event attested under the recovery identity — acting_actor_ref.

WHY:
One arm rule per answer the substrate can give, mapped **by the record's position relative to the Soft Delete write**, and every lifecycle action has exactly two positions: an intent record before it and an outcome record after it. The steps are [Audit Trail](./audit-trail.md)'s own: the substrate places retention *after* it appends, so the retention step means the event **is** in the log — the composition reads its id back and proceeds, and a retry would append a second intent for one act or a second outcome for one transition (Audit arm 3 through 7; the section titled *A transcribed rejection arm keeps its payload and its reachability* in `pressure-testing.md`). The read-back is a tail read from the enumeration mark, matching the record exactly — for an intent, the kind, the record, this invocation's now and the caller's actor reference; for an outcome, the intent event id it carries — and falls back to the log's start where a replica behind the append misses it (Composition state 17).

**At the intent, nothing has committed**, so every arm but the landed one is a clean pre-state refusal (Audit arm 1, 2, 8 and 9). invalid-credential is the caller's credential failing against the registry for the actor reference claimed. A pre-append step is the genuinely retryable arm. invalid-request has three sources: the substrate's retention-configuration fault, with the intent appended — the read-back finds it and it proceeds as the retention step — and, once the envelope is sized, two with nothing appended: the substrate's own cap disagreement and Actor Identity's own invalid-request at attest. The read-back tells them apart; with nothing appended the action refuses, pageable, never retried, since a retry re-sends the identical payload.

**At the outcome, the transition has committed**, so no arm can refuse the act, only report it (Audit arm 10 through 23). A pre-append step is transient: the invocation retries under the exclusion up to its counted terminus, then answers the orphan, releases the exclusion and yields to the reconciliation — a later success is the reconciliation's, never the invocation's. invalid-credential means the credential was revoked between the two writes and repetition cannot land it, so the invocation re-attests under the recovery identity behind a recovery intent, as the reconciliation would; if that write fails in turn, the orphan's cause says so and the reconciliation finishes it. invalid-request with nothing appended is a deployment fault no compensation can land until it is repaired, so it is escalated at once (Invariant 4.5). **Every outcome append is pre-checked under the exclusion** — a first attempt, a retry, a re-attestation, a resumption after a stall — and an outcome already naming the intent is adopted rather than appended beside (the section titled *A compensator is exclusive* in `pressure-testing.md`). An invocation whose lease expired has passed its terminus: it re-takes the exclusion before the pre-check, adopts what the reconciliation landed, and otherwise writes nothing.

**The position rides the exported code** (Audit arm 15, 27 and 28; the section titled *A composition's own rejection arm carries the retry bit* in `pressure-testing.md`): intent tells the caller nothing committed and the whole action may be retried; outcome tells the caller the transition exists and names the orphan in the same answer, and a retry is refused orphan-pending until the reconciliation binds it (Action wiring 7). The retention-step landing is delivered in the result, the unretained field, as the hard alert the deployment pages on (Audit arm 29), not only to a dashboard.

### Action wiring

```
delete_record(actor_ref, credential, record_id, optional reason)
  answers lifecycle result
  refuses invalid-request | invalid-credential | already-deleted | already-purged | orphan-pending(intent_event_id) | recording-failure(position)

restore_record(actor_ref, credential, record_id, optional reason)
  answers lifecycle result
  refuses invalid-request | invalid-credential | not-known | not-deleted | already-purged | orphan-pending(intent_event_id) | recording-failure(position)

purge_record(actor_ref, credential, record_id, reason)
  answers lifecycle result
  refuses invalid-request | invalid-credential | not-known | not-deleted | orphan-pending(intent_event_id) | recording-failure(position)

recover_history(record_id, original_event_payloads)
  answers lifecycle history
  refuses invalid-request | not-known

read(query)
  answers the matching lifecycle records
  refuses invalid-query
```

Term lifecycle result: the record id, the outcome event id, and the unretained field where the substrate reported a retention placement failed.

Term lifecycle history: what [Recover History] answers — a [Lifecycle History].

Term original event payloads: the caller's map from an audit-log sequence number to the byte-exact payload Event Log holds at that position.

```
Action wiring 1: A validated [Delete Record] MUST carry delete as the kind.
Action wiring 2: A validated [Restore Record] MUST carry restore as the kind.
Action wiring 3: A validated [Purge Record] MUST carry purge as the kind.
Action wiring 4: A validated lifecycle action MUST NOT run the orphan pre-check BEFORE taking the record exclusion.
Action wiring 5: The orphan pre-check MUST read the record's current attribution through Soft Delete's read.
Action wiring 6: The orphan pre-check MUST read the record's unmatched intents through the lifecycle enumeration from the pre-check's start.
Action wiring 7: IF the orphan pre-check finds a pending orphan THEN the lifecycle action MUST answer orphan-pending carrying the pending orphan's intent event id.
Action wiring 8: A lifecycle action answering orphan-pending MUST NOT write.
Action wiring 9: A cleared lifecycle action MUST record the kind's intent event carrying the record id, the reason AND now as the intended instant under the caller's credential.
Action wiring 10: The composition MUST NOT call a Soft Delete write BEFORE the lifecycle action's intent record lands.
Action wiring 11: An admitted lifecycle action MUST call the kind's Soft Delete write with the record id, the actor reference as the attribution, the reason AND now as the transition instant.
Action wiring 12: IF the Soft Delete write answers a state refusal THEN the lifecycle action MUST answer the state refusal.
Action wiring 13: IF the Soft Delete write answers storage-failure THEN the lifecycle action MUST answer recording-failure carrying intent.
Action wiring 14: A refused Soft Delete write MUST NOT write beyond the intent record.
Action wiring 15: A committed lifecycle action MUST record the kind's outcome event carrying the outcome payload under the caller's credential ONLY AFTER the Soft Delete write answers.
Action wiring 16: A bound lifecycle action MUST insert the lifecycle entry carrying the outcome event id AND the intent position the record read answers for the intent event id.
Action wiring 17: A lifecycle action MUST release the record exclusion at EVERY answer.
Action wiring 18: A bound lifecycle action MUST answer the lifecycle result.
Action wiring 19: A validated history read MUST read the record's lifecycle record through Soft Delete's read.
Action wiring 20: IF Soft Delete's read answers no lifecycle record THEN [Recover History] MUST answer not-known.
Action wiring 21: A found history read MUST build the reconciled sequence from the lifecycle enumeration AND the lifecycle index.
Action wiring 22: A found history read MUST NOT build the reconciled sequence from the lifecycle index alone.
Action wiring 23: An index gap MUST enter the reconciled sequence carrying index-gap-repaired as the provenance.
Action wiring 24: A found history read MUST insert an index gap's lifecycle entry.
Action wiring 25: IF the record read answers Purged for an enumeration gap THEN the enumeration gap MUST enter the reconciled sequence carrying payload-purged as the provenance.
Action wiring 26: IF the record read answers a live state for an enumeration gap THEN the found history read MUST re-read the lifecycle enumeration from the log's start.
Action wiring 27: IF the re-read finds the enumeration gap's outcome event naming the record THEN the enumeration gap MUST enter the reconciled sequence carrying enumeration-miss as the provenance.
Action wiring 28: A reconciled event the enumeration AND the lifecycle index both carry MUST carry both as the provenance.
Action wiring 29: A found history read MUST order the reconciled sequence by intent position.
Action wiring 30: A found history read MUST number the reconciled sequence from one as the sequence position.
Action wiring 31: A found history read MUST read EVERY reconciled event through the record read.
Action wiring 32: IF the record read answers Purged for a reconciled event THEN the found history read MUST call the verification with the covering range's members the original event payloads carry.
Action wiring 33: The found history read MUST NOT check the original event payloads for a reconciled event the record read answers Purged for.
Action wiring 34: IF a member of a live event's covering range IS NOT IN the original event payloads THEN the event MUST carry payload-not-supplied AND the missing sequence numbers as the attestation verification.
Action wiring 35: IF EVERY member of a live event's covering range IS IN the original event payloads THEN the found history read MUST call the verification with the covering range's payloads in ascending sequence order.
Action wiring 36: The found history read MUST carry the verification's outcome as the attestation verification.
Action wiring 37: The found history read MUST carry the verification's compensation-window qualifier in the retention state.
Action wiring 38: The found history read MUST NOT change a presented payload.
Action wiring 39: The composition MUST NOT fetch a payload for the verification.
Action wiring 40: A found history read MUST collect the record's intent events no reconciled outcome event names as the attempts.
Action wiring 41: A found history read MUST NOT place an attempt among the events.
Action wiring 42: A found history read MUST answer the lifecycle history.
Action wiring 43: [Recover History] MUST NOT record an audit event.
Action wiring 44: The read passthrough MUST answer Soft Delete's read for the query unchanged.
Action wiring 45: IF Soft Delete's read answers invalid-query THEN the read passthrough MUST answer invalid-query.
Action wiring 46: The read passthrough MUST NOT record an audit event.
```

Term lifecycle action: [Delete Record], [Restore Record] or [Purge Record].

Term read passthrough: Soft Delete's read, passed through unchanged — the composition's read.

Term kind: delete | restore | purge — which transition a lifecycle action makes.

Term kind's intent event: record.soft_delete_intended for delete, record.restore_intended for restore, record.purge_intended for purge.

Term kind's outcome event: record.soft_deleted for delete, record.restored for restore, record.purged for purge — a lifecycle event.

Term kind's Soft Delete write: soft_delete for delete, restore for restore, purge for purge.

Term validated lifecycle action: a lifecycle action whose inputs and envelope cleared Primitive policy.

Term pre-check's start: the sequence number after the intent position of the record's last lifecycle entry, or the log's start where the record carries no lifecycle entry — read through the lifecycle rebuild on a miss.

Term unmatched intent: an intent event for the record that no outcome event names by intent event id or among its intent candidates.

Term cleared lifecycle action: a validated lifecycle action whose orphan pre-check found no pending orphan under the record exclusion.

Term admitted lifecycle action: a cleared lifecycle action whose intent record landed.

Term state refusal: invalid-request | already-deleted | already-purged | not-known | not-deleted — Soft Delete's refusals of a write, relayed by name.

Term committed lifecycle action: an admitted lifecycle action whose Soft Delete write answered.

Term bound lifecycle action: a committed lifecycle action whose outcome record landed.

Term intended instant: the now an intent event carries — intended_at.

Term transition instant: the now a lifecycle action passes to the Soft Delete write as deleted_at, restored_at or purged_at, and carries on the outcome event as recorded_at — the invocation's one reading.

Term recording instant: Event Log's own stamp on an appended event — distinct from the transition instant a payload carries.

Term validated history read: a [Recover History] call whose record id cleared Primitive policy.

Term found history read: a validated history read whose record carries a Soft Delete lifecycle record.

Term reconciled sequence: the record's transitions built from the lifecycle enumeration and the lifecycle index in both directions, ordered by intent position.

Term index gap: an outcome event for the record the enumeration finds and the lifecycle index does not carry.

Term enumeration gap: a lifecycle entry the enumeration does not find.

Term covering range: the sequence range the record read names for an event's covering seal, or the event's own sequence number in the unsealed tail.

Term live event: a reconciled event the record read answers Retained or unresolved in its compensation window.

Term attempts: the record's unmatched intents — each carrying the intent event id, the kind's intent event, the actor reference, the intended instant and the reason.

WHY:
**The lifecycle actions run one protocol, three times** (Action wiring 4 through 18): take the record exclusion; clear the orphan pre-check; record the intent under the caller's credential; make the Soft Delete write; record the outcome naming the intent; insert the entry at the intent's position; release and answer. The whole action runs inside the exclusion (Concurrency 1). Every Soft Delete write passes the invocation's now explicitly as its transition instant and stamps the same reading on the intent — which is what makes the pairing rule's stamp a key rather than a hint (Reconciliation 5). The state refusals are Soft Delete's and relayed by name; a storage-failure leaves the record in its prior state, so nothing committed and the whole action may be retried (Action wiring 13). The intent record of a refused write stands as the record of an attempt.

**A record with a pending orphan admits no new transition** (Action wiring 4 through 8; the section titled *Intents pair with outcomes* in `pressure-testing.md`). Soft Delete keeps the most recent attribution of each kind and nothing older, so a transition committed on top of an unbound one would overwrite the very field the pairing reads and leave the orphan unpairable for good — classified as a refused attempt, and the replay out of order. The pre-check reads the same rule the reconciliation reads, from the record's last bound intent forward, so it is a tail read in the healthy case. A purge is never committed on top of an unbound delete.

**[Purge Record] does not check purge eligibility** (Non-goal 1). Whether a hold was active, a retention had elapsed or the actor was authorized is [Defensible Retention](./defensible-retention.md)'s and a Permissions pattern's; this composition records the purge faithfully, and absorbing the gate would duplicate Defensible Retention's defining invariant. The reason is required because a purge without a stated justification is an attributed destruction with no record of its authority. **The purge's partial failure is the most consequential**: Purged is terminal (Soft Delete Invariant 3), so a destroyed record awaits its outcome event — but it carries the intent, which makes the destruction visible to the reconciliation and names the actor whose credential was verified before it happened.

**[Recover History] reconciles; it does not read the index** (Action wiring 21 through 28). The class treatment for a derived index is to anchor in the authoritative record and use the index as a cache, because rebuild-on-miss is a **keyed-lookup** contract — and reading the list under a key honours the contract at the key's granularity while violating it at the element's: a list that lost an element is not a miss, the rebuild never fires, and the history returns short while claiming to be complete. **But here the cache can outlive its source**: the enumeration keys on a payload field the retention purge destroys, so past the horizon the enumeration finds fewer transitions than the index, whose event ids still resolve. Both directions are computed and both are informative. *An index gap* is the derived index's own rebuild trigger: repaired, included, reported — never a defect in the lifecycle record. *An enumeration gap* is decided by the record read, never presumed: Purged means the payload is past the horizon, a first-class forensic fact (the distinction Audit Trail Invariant 8 draws between purged and missing); live means the enumeration missed it, so it is re-run once — a replica behind the append if the event points back, and Invariant 4's inverse orphan if it does not (Verdict 4). *In neither*, for a record Soft Delete shows moved, is the orphan Invariant 4 names. The **sequence position** numbers the reconciled sequence, never the index's list: a list that lost an element renumbers everything after it, so contiguous positions are evidence of completeness only when the sequence they number is the reconciled one.

**Lawful destruction is answered before absence** (Action wiring 32 and 33; the section titled *Lawful destruction is answered before absence* in `pressure-testing.md`). The branch is taken on the state the record read answers, before anything the caller supplied is examined: the substrate reads retention state at its own step 1 and answers failed-verification with purged before it reads a presentation, so a membership check run first would report every purged transition as payload-not-supplied and make [History Complete] unreachable for any record past its first purge.

**The verifier presents the record set** (Action wiring 34 through 39; Audit Trail Invariant 7). The map is keyed by sequence number because **what a seal commits to is a range, not one event**: under interval and on-demand cadences a range spans intent records and unrelated actions, and a one-payload-per-event presentation would answer a record-set mismatch for every event, indistinguishable from tampering. Under per-event cadence each range is a singleton — the special case, not the rule. The argument is required, not fetched, because a verifier who trusts the host to supply the record set has verified nothing. A partial map gives a partial history: the events whose ranges are incomplete say so and name the absent positions, and attribution and retention for the rest are still verified. For interactive investigations the investigator retrieves the payloads through Event Log's range read while the log is online, keyed by the positions the record read names; for operational monitoring the system supplies them from its own store — the design of Chain of Custody's verify_custody.

**Attempts are a separate residue** (Action wiring 40 and 41): an authenticated actor began a lifecycle change that did not complete, or completed without recording. They are forensically material precisely because they are attempts, and interleaving them into the events would corrupt the replay Invariant 3 rests on. Check 5.3 adjudicates them against the Soft Delete store.

**[Recover History] takes no actor reference** (2026-08-26-l): nothing consumed it — the read records no audit event and gates nothing, and who queried the history is an access-logging wrapper's to record (Non-goal 6). A parameter no rule reads is a promise with nothing behind it. **The read passthrough is Soft Delete's read, unchanged** (Action wiring 44 and 45): it answers the matching lifecycle records for a query and refuses only invalid-query, which is the whole of the constituent's contract — the current-state summary, never the history.

### Wiring decision

```
Wiring decision 1: The composition MUST follow EVERY Soft Delete transition with the kind's outcome event naming the record id.
Wiring decision 2: The composition MUST attest EVERY outcome event under a credential Audit Trail validates.
Wiring decision 3: The composition MUST NOT claim an atomic set spanning a Soft Delete transition AND the transition's outcome event.
Wiring decision 4: The composition MUST bind EVERY outcome event into the lifecycle index at the outcome's intent position.
```

WHY:
**Every lifecycle transition is followed — ordered after it, never atomically with it — by an Audit Trail event that names the record, attributes the acting actor through a verified credential, and is thereby sealed and placed under retention; the binding is inserted into the lifecycle index at its intent's position.**

*Principle.* A defensible deletion record requires every delete, restore and purge attributed to a verified actor, tamper-evidently sealed, and the *complete* lifecycle of any record reconstructable — not only its current state. No single constituent satisfies all three. Soft Delete's attribution fields are immutable by specification but not cryptographically, it defers full history to Event Log composition, and it defers tamper evidence to Tamper Evidence. Audit Trail satisfies attribution, tamper evidence and retention, and does not know which events belong to which record's lifecycle.

*Likely objection.* Soft Delete already records who deleted and who purged — why compose?

*Mechanism.* Soft Delete keeps only the *most recent* attribution per kind, immutable only by specification. The composition fills each gap at once through the substrate: Event Log keeps every transition in order, Tamper Evidence seals them cryptographically, Actor Identity verifies the actor rather than recording an opaque reference, and the lifecycle index makes all three available per transition and per record (Wiring decision 1, 2 and 4). The pair is ordered, not atomic (Wiring decision 3; the section titled *Durability boundaries* in `pressure-testing.md`): the substrate's append cannot be withdrawn and Purged is terminal, so no transaction spans them and none is claimed — the one partial the order leaves is the orphan, surfaced and bound by the Audit arm and the Reconciliation.

*Result.* A records-alone-defensible, tamper-evident, fully recoverable deletion lifecycle neither constituent provides alone. An investigator holding the lifecycle index, the Soft Delete store and the Audit Trail substrate answers the regulator's questions — who deleted it, who restored it, who purged it, in what order, is the record intact, was it kept long enough — from the records alone, without developer narration, source code or runbooks.

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run at EVERY process start.
Reconciliation 2: The reconciliation MUST run every reconciliation cadence.
Reconciliation 3: The reconciliation MUST NOT examine a young intent.
Reconciliation 4: The reconciliation MUST NOT write for an aged intent.
Reconciliation 5: The orphan pre-check AND the reconciliation MUST read an unmatched intent as a pending orphan ONLY IF the intent pairs.
Reconciliation 6: The reconciliation MUST NOT pair a record's intents BEFORE taking the record exclusion.
Reconciliation 7: IF another holder holds the record exclusion THEN the reconciliation MUST leave the record to the reconciliation's next run.
Reconciliation 8: The reconciliation MUST hold the record exclusion from the pairing through the compensating event.
Reconciliation 9: The reconciliation MUST NOT record a compensating event BEFORE the reconciliation's recovery intent lands.
Reconciliation 10: The reconciliation MUST attest EVERY write the reconciliation makes under the recovery identity.
Reconciliation 11: A compensating event MUST carry the recovery flag, the acting actor reference AND the intent reference.
Reconciliation 12: The reconciliation MUST re-derive a compensating event from the intent event's payload AND the Soft Delete record.
Reconciliation 13: The reconciliation MUST NOT record a fresh intent for a compensation.
Reconciliation 14: IF the candidate count EXCEEDS one THEN the compensating event MUST carry the intent candidates.
Reconciliation 15: IF the candidate count EXCEEDS the intent candidates cap THEN the reconciliation MUST NOT compensate the orphan.
Reconciliation 16: IF the candidate count EXCEEDS the intent candidates cap THEN the reconciliation MUST escalate the orphan.
Reconciliation 17: The reconciliation MUST insert a compensating event's lifecycle entry at the earliest intent position the intent reference names.
Reconciliation 18: The reconciliation MUST NOT re-send a payload Audit Trail refused with invalid-request.
Reconciliation 19: The reconciliation MUST escalate EVERY overdue orphan as an unresolved finding.
Reconciliation 20: The reconciliation MUST surface EVERY pending orphan to the compliance dashboard.
Reconciliation 21: A regulated deployment MUST alert on a pending orphan of a purge.
```

Term reconciliation: the leg the composition runs outside every invocation, whose output — a bound orphan or an escalation — an auditor awaits within the compensation window.

Term young intent: an intent whose `intended instant + transition completion bound` DOES NOT PRECEDE now — possibly an invocation still between its writes.

Term aged intent: an intent whose `recording instant + audit horizon` PRECEDES now — its payload lawfully destroyed, its transition's lifecycle entry a purged entry.

Term pairing: an unmatched intent pairs when the record's current attribution of the intent's kind carries the intent's intended instant as the transition instant AND the intent's actor reference as the attribution, and no outcome event of that kind and that instant already binds the attribution.

Term pending orphan: an unmatched intent that pairs — the intent of a committed transition still owed its outcome event.

Term crash orphan: a pending orphan whose invocation died between its two truth-bearing writes, leaving no answer to surface it.

Term intent candidates: the unmatched intents that pair to one attribution where the clock's resolution admits more than one — intent_event_candidates.

Term candidate count: how many unmatched intents pair to one attribution.

Term intent reference: the original intent event id, or the intent candidates.

Term compensating event: an outcome event the reconciliation records under the recovery identity.

Term overdue orphan: a pending orphan whose `intended instant + compensation window` PRECEDES now.

WHY:
**Why the reconciliation is mandatory.** A partial failure that *returns* surfaces the orphan in the same answer (Audit arm 15); a partial failure that *cannot* return — a process death between the two truth-bearing writes — is the crash orphan, and only this leg finds it. **The intent record sharpens it rather than replacing it**: the crashed invocation left a record of its own naming the record, the actor whose credential was verified and the transition it was about to make, so the leg reads *what was attempted* from the trail instead of reconstructing it, and an orphan is told from a bypass without consulting anything outside Audit Trail. The leg is **Reconciliation, not Housekeeping**: an auditor awaits its output within the compensation window.

**It is bounded at both ends** (Reconciliation 3 and 4; the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md`). Below: an intent younger than the bound may belong to an invocation still between its Soft Delete write and its outcome, and a compensation fired at it would land a second outcome for one transition — the duplicate Invariant 4 forbids. Above: past the audit horizon the intent is destroyed and the transition's lifecycle entry is the purged half — read, never re-emitted; a Soft Delete state whose events aged out is the retention asymmetry, never an orphan.

**It pairs by the records** (Reconciliation 5; the section titled *Intents pair with outcomes* in `pressure-testing.md`). Every lifecycle action passes its now to Soft Delete as the transition instant, stamps the same reading on its intent, and names the actor as the attribution — so an unmatched intent is a committed transition's exactly when the current attribution of its kind carries its instant and its actor and no outcome already binds that attribution; a same-stamp unmatched intent beside a bound one is a refused attempt. One rule, read by the pre-check and the leg alike. **The rule is exact only because a record with a pending orphan admits no new transition** (Action wiring 7): the gate is what makes the stamp a key rather than a hint. Where the clock's resolution admits several candidates, the compensating event names them, up to the cap, and takes the earliest one's place, and the record says so (Reconciliation 14 through 17).

**One writer per transition** (Reconciliation 6 through 8; the section titled *A compensator is exclusive* in `pressure-testing.md`). The leg takes the record exclusion for every record it compensates and re-reads the pairing under it, never before; a record whose exclusion it cannot take — an invocation still inside its retries — is left to the next run rather than raced; and two runs, restart and cadence, one node or two, serialize on the same exclusion, so the second finds the first's outcome and writes nothing.

**It commits as the composition** (Reconciliation 9 through 13; the section titled *Recovery commits under a declared service identity* in `pressure-testing.md`). Every write is attested under the recovery identity — the actor's credential is not in hand — behind a recovery intent naming the record, the transition and the intent it pairs to, so the trail shows the compensation was occasioned by the leg and not by a direct call; the same recovery intent precedes an invocation's own re-attestation (Audit arm 14), so *preceded by a recovery intent* holds for every event carrying the recovery flag, whichever writer landed it. What the compensating event carries is re-derived from the intent's payload and the Soft Delete record, never remembered; and it carries the original intent event id, **never a fresh intent**, which would move the transition's place in the replay and make the recovery identity its authenticated principal.

**The deterministic arm is narrower than its token** (Reconciliation 18; Audit arm 17). Once the envelope is sized, the only invalid-request that leaves the outcome unappended is the substrate's own cap disagreement or Actor Identity's own refusal at attest — deployment faults. That orphan is escalated at once and bound when the deployment repairs the fault, never by re-sending the identical payload. **An orphan purge is a hard alert** (Reconciliation 21): a Purged record with no attributed purge event is a direct breach of Invariant 2, visible the whole time it awaits compensation; deployments under GDPR Article 17, HIPAA §164.310(d)(2) or FRCP (Federal Rules of Civil Procedure) Rule 37(e) exposure page on it.

### Verdict

```
Verdict 1: The overall verdict MUST carry history-complete ONLY IF no class applies.
Verdict 2: IF a class applies THEN the overall verdict MUST carry history-incomplete naming EVERY class that applies.
Verdict 3: IF the reconciled sequence carries no event AND the record's current state IS IN Deleted and Purged THEN binding-gap MUST apply.
Verdict 4: IF a live enumeration gap's outcome event DOES NOT name the record THEN binding-gap MUST apply.
Verdict 5: IF the verification answers not-known THEN binding-gap MUST apply.
Verdict 6: IF the reconciled sequence carries an event AND the sequence's first transition DOES NOT EQUAL delete THEN binding-gap MUST apply.
Verdict 7: IF the reconciled sequence carries an event AND the sequence's last transition DOES NOT EQUAL the current state's transition THEN binding-gap MUST apply.
Verdict 8: IF an adjacent pair of the reconciled sequence IS NOT IN the lifecycle steps THEN out-of-order MUST apply.
Verdict 9: IF an attestation verification carries a failed attestation THEN attestation-failed MUST apply.
Verdict 10: IF an attestation verification carries a failed seal THEN seal-failed MUST apply.
Verdict 11: IF an attestation verification carries unsealed THEN unsealed MUST apply.
Verdict 12: IF an attestation verification carries payload-not-supplied THEN payload-not-supplied MUST apply.
Verdict 13: IF an attestation verification carries partially-purged-coverage THEN partially-purged-coverage MUST apply.
Verdict 14: IF an attestation verification carries an unavailable surface THEN availability MUST apply.
Verdict 15: The found history read MUST report EVERY reported outcome beside the overall verdict.
Verdict 16: A reported outcome MUST NOT apply as a class.
Verdict 17: An attestation verification carrying purged MUST NOT apply as a class.
```

Term class: a failure class or an incomplete-verification class — each blocks [History Complete].

Term failure class: binding-gap | attestation-failed | seal-failed | unsealed | out-of-order — a defect in the lifecycle record or its evidence.

Term incomplete-verification class: payload-not-supplied | partially-purged-coverage | availability — verification could not be performed, which is not a defect in the record.

Term reported outcome: index-gap-repaired | payload-purged | enumeration-miss | retention-pending — a fact a forensic reader needs that is no defect in the lifecycle record.

Term current state's transition: delete for Deleted, restore for Active, purge for Purged.

Term lifecycle steps: delete then restore; delete then purge; restore then delete.

Term failed attestation: failed-verification carrying an attestation reason.

Term failed seal: failed-verification carrying seal-proof-invalid, seal-record-set-mismatch or seal-not-known.

Term unavailable surface: unverifiable carrying attestation-registry-unavailable or seal-mechanism-verification-unavailable.

WHY:
**Every outcome the substrate can return has one landing** (Verdict 5 and 9 through 14): verified; failed-verification with purged, lawful destruction and no class (Verdict 17); a failed attestation; a failed seal; unsealed, the event in the unsealed tail under strict mode, its seal owed at the next cadence firing; not-known, a binding gap; payload-not-supplied, this composition's own, where the map lacks a member of the range; partially-purged-coverage, the substrate's standing answer for survivors under an interval cadence, resolvable only by a composed Seal Lifecycle pattern; and an unavailable surface, transient, re-run when it returns. **Every class blocks [History Complete]** (Verdict 1): a history is proven only when every step was verified, and *could not be verified* is not *verified*. The substrate's compensation-window qualifier is a separate channel, reported through the retention state and never folded into a verification (Action wiring 37).

**The reported outcomes are not classes, and keeping them out is the point** (Verdict 15 and 16): a repaired index gap, a payload past the horizon, a replica's lag and a retention placement still owed inside the substrate's own window are facts a reader needs and no defect in the lifecycle record; reporting the first as a binding gap would be the misdiagnosis Audit Trail names — an index gap read as a compliance finding.

**The path test separates a missing transition from a misordered one** (Verdict 6 through 8; 2026-08-30-b). A sequence that does not begin with a delete, or whose last transition disagrees with Soft Delete's current state, is **missing** a transition at an edge — one that predates the composition (Pre-composition transitions 1), or an orphan still owed its outcome — and a transition with no event is a binding gap by the class's own meaning. An interior pair no lifecycle could have committed — a delete after a delete, anything after a purge — is an **ordering** defect: under the sole write path and the pending-orphan gate an interior transition cannot go missing, so what remains is a compensation landed under a broken exclusion or an index insert under the wrong key — out-of-order. Each class names one defect.

## Composition-level invariants

These emerge from the composition; none belongs to one constituent, and each needs Soft Delete and the Audit Trail substrate together.

- **Invariant 1 — Lifecycle attribution coverage.**
  ```
  Invariant 1.1: IF a settled transition carries no escalation THEN the transition MUST carry EXACTLY ONE outcome event of the transition's kind naming the record.
  Invariant 1.2: EVERY outcome event MUST carry a committed attestation of the attesting actor reference.
  ```
  Term settled transition: a Soft Delete transition whose `transition instant + compensation window` PRECEDES now.

  WHY: no lifecycle transition stands past its window without an attributable, attested audit record — the qualification is Invariant 4's, whose liveness arm admits an orphan inside the window and an escalated one past it, and Invariant 1 claims nothing Invariant 4 does not deliver (2026-08-26-i). *Rests on* Soft Delete Invariant 1 and 8 (deletion attribution immutable and complete), Soft Delete Invariant 5 (purge attribution complete), and Audit Trail Invariant 1 — attribution coverage: every appended event carries a committed attestation id in its own payload, a claim about coverage and not about verification, which [Recover History] performs separately. Established by Action wiring 15 and 16.
- **Invariant 2 — Purge accountability.**
  ```
  Invariant 2.1: IF a settled purge carries no escalation THEN the purge MUST carry an outcome event naming the acting actor, the transition instant AND a reason.
  Invariant 2.2: IF a purge outcome event's sequence number DOES NOT EXCEED sealed through THEN EXACTLY ONE seal MUST cover the event.
  ```
  WHY: no record reaches Purged without an audit event naming who purged it, when and under what stated authority, sealed once the cadence reaches it. An anonymous purge, a missing reason, or a purge event left outside the seal the cadence owes it is a conformance failure; a purge event inside the unsealed tail is not, and Invariant 2.2 claims exactly what Audit Trail Invariant 3 delivers at a permitted cadence (2026-08-26-j). The composition's headline regulated invariant — the property no auditor, regulator or court should discover violated without the records surfacing it. *Rests on* Soft Delete Invariant 5 (the purging actor and the purge reason required), Soft Delete Invariant 4 (purge requires a prior deletion), Primitive policy 3, and Audit Trail Invariant 3 (integrity coverage, modulo the unsealed tail the seal cadence bounds).
- **Invariant 3 — Forensic completeness.**
  ```
  Invariant 3.1: [Recover History] MUST answer EVERY transition of the record's reconciled sequence.
  Invariant 3.2: [Recover History] MUST answer the reconciled sequence in intent-position order.
  Invariant 3.3: [Recover History] MUST answer a transition Soft Delete's current attribution overwrote.
  ```
  WHY: the complete ordered history — prior epochs included — is the guarantee neither constituent gives alone: Soft Delete keeps the current state; Event Log keeps every event and cannot group them into a lifecycle. **Completeness rests on the reconciliation, not on the index**, a capability-provenance dependency rather than an implementation note: the index's rebuild-on-miss covers a keyed lookup, and reading the list under a key is a shape it does not cover (Action wiring 21 and 22). *Rests on* Event Log Invariant 3 (total order) applied to the intent events — the occurrence key every outcome carries, which makes the sequence orderable and keeps a late compensation in its place — with out-of-order as the verdict when the order is not a legal path (Verdict 8); Event Log Invariant 2 (event immutability); Audit Trail Invariant 7 (the verifier presents the record set); Audit Trail Invariant 8 (purged distinguished from missing), which lets the reconciliation report payload-purged as a fact; the lifecycle enumeration (Composes 9, Capability requirement 24); the index's insert-only discipline (Composition state 6); and, for the enumeration's totality, the audit horizon — the reason the reconciliation runs both ways.
- **Invariant 4 — Binding bijection.**
  ```
  Invariant 4.1: The composition MUST NOT leave a pending orphan unsurfaced.
  Invariant 4.2: EVERY compensable orphan MUST land an outcome event WITHIN the compensation window.
  Invariant 4.3: Two outcome events MUST NOT name one intent event.
  Invariant 4.4: EVERY outcome event MUST name a record carrying a Soft Delete lifecycle record.
  Invariant 4.5: The reconciliation MUST escalate EVERY uncompensable orphan.
  Invariant 4.6: The composition MUST NOT commit a transition on a record carrying a pending orphan.
  Invariant 4.7: EVERY compensating event MUST carry the recovery flag.
  ```
  Term compensable orphan: a pending orphan whose cause DOES NOT EQUAL invalid-request and whose candidate count DOES NOT EXCEED the intent candidates cap.

  Term uncompensable orphan: a pending orphan that is not compensable — refused invalid-request with nothing appended, or pairing to more candidates than the cap.

  WHY: a one-to-one binding between the transitions committed through this composition and their outcome events. The two truth-bearing writes are **ordered, never atomic** (Wiring decision 3), so the orphan — a committed transition with no outcome event — *is* reachable under the prescribed design, durably, until compensation lands; for a purge it is Invariant 2's worst case. The honest claim therefore splits. **Safety** (Invariant 4.1): every orphan is detectable from the records alone at all times — a returning partial names it in its answer (Audit arm 15), a crash is caught by the reconciliation (Reconciliation 1 and 2) — and an orphan stays pairable while it stands, because no later transition may overwrite the attribution the pairing reads (Invariant 4.6). **Liveness** (Invariant 4.2): *Orphan(t) ↝ Bound(t)* under weak fairness on the compensation — the invocation's counted retries, then the reconciliation's runs; the eventuality lives in the reconciliation's obligation, not in an unbounded retry, and holds across both failure classes, by retry on the transient one and by re-attestation under the recovery identity on the deterministic one. **The carve-out, stated** (Invariant 4.5): an outcome refused invalid-request with nothing appended is a deployment fault, and no compensation lands until it is repaired — the orphan is bound within the window only in a deployment that repaired it inside the window; an orphan pairing to more candidates than the cap cannot be compensated inside the envelope the action sized (Reconciliation 15). Both are escalated at once rather than left to breach. **One writer** (Invariant 4.3): a second outcome naming one intent is a second writer, foreclosed by the exclusion. The inverse orphan (Invariant 4.4) is unreachable through this wiring. Recovered bindings stay distinguishable from clean ones (Invariant 4.7).

  **The formal model is the verification surface**: forensic-recovery.tla and its twin, both named on the Ledger's formal line and both owed a re-derivation over the invocation and the reconciliation as two processes over one transition, the bound as the yield point, and the orphan-pending refusal (2026-08-26-p; 2026-08-29-a and 2026-08-30-h stay open). The claim mirrors Audit Trail Invariant 4 — cascade coordination on purge, ordered writes plus compensation and never an atomic set (2026-08-26-q) — at the transition-creation boundary. **The precondition** is Composes 7: the composition is the sole writer of its Soft Delete instance. Because Soft Delete keeps no transition history, the authoritative sequence is the lifecycle index plus the Event Log; the forward direction (every indexed event is real and points back) is auditable from the records, and the reverse (every committed transition has an event) holds by the sole write path and is corroborated for the *current* state by Soft Delete's read.
- **Invariant 6 — Authentication precedes commitment.**
  ```
  Invariant 6.1: The composition MUST NOT commit a Soft Delete transition BEFORE Audit Trail validates the caller's credential for the actor reference.
  Invariant 6.2: An action refused invalid-credential at the intent record MUST NOT commit a Soft Delete transition.
  Deleted: Invariant 5. Composes 5 owns it.
  ```
  WHY: the intent record is the mechanism — an audit write, inside which the substrate validates the credential, standing before every Soft Delete write and, the load-bearing case, before purge. A record is never destroyed on an unverified actor's asserted authority, and the claim to record *an actor with a valid credential* is exact. **What it does not establish**: a successful validation shows that material matching the actor's registered verifier was presented at that instant — not that the presenter *is* that actor (a stolen credential validates), not that the presentation is bound to a channel or cannot be replayed, and nothing whatever about authority, which is the composing layer's (Non-goal 3). *Rests on* the audit write and the Actor Identity attestation reached through it; Check 5.1 tests the order from the records alone. The deleted invariant asserted every constituent's invariants hold over its instance, which Execution Contract Conformance 8 settles by reference (council read 53).

Coverage, accountability and the bijection give *every transition is attributed*; completeness gives *the whole history is recoverable*; authentication before commitment gives *the attribution is of an actor who proved it*.

---

## Examples

### Walkthrough — GDPR Article 17 erasure under supervisory authority scrutiny

A healthcare SaaS (Software as a Service) platform uses this composition to govern the deletion lifecycle of patient profile records. Configuration: `audit_trail_retention_policy = hipaa_6yr_audit` (encoding a 6-year audit-record retention minimum per HIPAA §164.312(b)), `seal_cadence = per-event`.

1. **Patient requests erasure.** DSAR (Data Subject Access Request — a request by an individual to see, correct, or erase the personal data an organization holds about them) workflow calls `delete_record(actor_ref="dsar_service", record_id="profile-4491", credential=<dsar_credential>, reason="GDPR Art. 17 erasure request — ticket DSR-2026-0441")` → `{record_id="profile-4491", event_id="ev_5001"}`. The action takes the record exclusion, finds no pending orphan, and writes the intent record `record.soft_delete_intended` → `ev_5000` at sequence position 5000; Soft Delete transitions `profile-4491` to Deleted; `AuditTrail.record_action(record.soft_deleted, actor_ref="dsar_service", ...)` → `ev_5001`; `record_to_events["profile-4491"] = [{event_id="ev_5001", intent_position=5000}]`. The deletion is attributed and sealed.

2. **Erasure confirmed and purge executed.** After confirming no Legal Hold blocks the purge (that check is the responsibility of a composing [Defensible Retention](./defensible-retention.md) instance in this deployment), the workflow calls `purge_record(actor_ref="dsar_service", record_id="profile-4491", credential=<dsar_credential>, reason="GDPR Art. 17 erasure confirmed — no blocking hold — ticket DSR-2026-0441")` → `{record_id="profile-4491", event_id="ev_5003"}`. The intent record `record.purge_intended` → `ev_5002` at position 5002; Soft Delete transitions `profile-4491` to Purged; `AuditTrail.record_action(record.purged, actor_ref="dsar_service", ...)` → `ev_5003`; `record_to_events["profile-4491"] = [{event_id="ev_5001", intent_position=5000}, {event_id="ev_5003", intent_position=5002}]`.

3. **GDPR supervisory authority audit.** A Data Protection Authority (DPA) auditor asks: *"Prove the erasure of profile-4491 was performed, attributed, tamper-evident, and the full lifecycle is recoverable."* The system calls `recover_history(record_id="profile-4491", original_event_payloads={5001: <payload_1>, 5003: <payload_2>})` — the map is keyed by sequence position, and under `per-event` cadence each covering range is the singleton at the event's own position.
   - `current_state = Purged`.
   - `attempts = []`.
   - `events`: `[{sequence_position=1, provenance=both, event_id="ev_5001", action_ref=record.soft_deleted, actor_ref="dsar_service", acting_actor_ref="dsar_service", recovery=false, recorded_at=T1, recording_instant=R1, reason="GDPR Art. 17 erasure request…", attestation_verification=verified, retention_state=Retained}, {sequence_position=2, provenance=both, event_id="ev_5003", action_ref=record.purged, actor_ref="dsar_service", acting_actor_ref="dsar_service", recovery=false, recorded_at=T2, recording_instant=R2, reason="GDPR Art. 17 erasure confirmed…", attestation_verification=verified, retention_state=Retained}]`.
   - `overall_verdict = history-complete`.
   The DPA auditor sees: (a) who deleted the record and why; (b) who purged it, when, and under what stated reason; (c) both events are tamper-evidently sealed; (d) both are under active retention; and (e) T1 and T2 are the transition instants the two actions carried, R1 and R2 the instants Event Log recorded the appends (Clock semantics 2). Invariant 1 through 3 are the structural guarantees behind each field. No developer narration required.

### Multi-epoch lifecycle — delete, restore, re-delete, purge

A content moderation system uses this composition for post lifecycle management. A post is deleted, then reinstated on appeal, then deleted and purged after the appeal window closes. Soft Delete retains only the most recent deletion attribution; this composition retains the full ordered history.

1. `delete_record(actor_ref="mod_jones", record_id="post-8821", credential=..., reason="Policy violation — review pending")` → `ev_6001` (its intent `ev_6000` at position 6000). `record_to_events["post-8821"] = [{ev_6001, 6000}]`.
2. `restore_record(actor_ref="appeals_team", record_id="post-8821", credential=..., reason="Appeal upheld — reinstatement")` → `ev_6003` (intent at 6002). `record_to_events["post-8821"] = [{ev_6001, 6000}, {ev_6003, 6002}]`.
3. `delete_record(actor_ref="mod_chen", record_id="post-8821", credential=..., reason="Policy violation — appeal exhausted")` → `ev_6005` (intent at 6004). `record_to_events["post-8821"] = [{ev_6001, 6000}, {ev_6003, 6002}, {ev_6005, 6004}]`. At this point Soft Delete's `deleted_by = "mod_chen"`, overwriting `"mod_jones"` — the prior epoch is gone from Soft Delete's current-state summary.
4. `purge_record(actor_ref="retention_service", record_id="post-8821", credential=..., reason="90-day post-appeal purge policy")` → `ev_6007` (intent at 6006). `record_to_events["post-8821"] = [{ev_6001, 6000}, {ev_6003, 6002}, {ev_6005, 6004}, {ev_6007, 6006}]`.

`recover_history(record_id="post-8821", ...)` returns all four events in order, including `ev_6001` (the original moderation deletion by `"mod_jones"`) that Soft Delete's current-state summary no longer carries. Invariant 3 (forensic completeness) is the structural guarantee: the full ordered history is recoverable from the composition's records even after Soft Delete's current-state attribution has been overwritten by a subsequent epoch.

### Rejection path — purge of an Active record

An automated purge job targets a record that was never soft-deleted: `purge_record(actor_ref="purge_job", record_id="doc-0099", credential=..., reason="scheduled purge")`. The action takes the record exclusion, finds no pending orphan, and writes the intent record `record.purge_intended` — the job's credential validates, so the attempt is authenticated and durable. The Soft Delete write `SoftDelete.purge("doc-0099", ...)` → `rejected(not-deleted)` (per Soft Delete Invariant 4 — Active → Purged direct path is prohibited). The composition returns `rejected(not-deleted)`. No Soft Delete state is written; no *outcome* event is recorded; `record_to_events` is unchanged. Invariant 4 (binding bijection) is preserved: no transition, no outcome event, no entry — the binding bijection is over transitions and outcome events, and an intent record is neither. **The intent record stands, and this is the point:** an automated job attempting to destroy a record it had no business destroying is exactly what a forensic trail should retain. It surfaces in [Recover History]'s attempts residue and is adjudicated by Check 5.3 against a Soft Delete store that shows the record was never deleted — an attempted destruction that the composition refused. Before the intent record existed, this attempt left no trace anywhere.

### Rejection path — [Delete Record] on an already-Deleted record

`delete_record(actor_ref="admin", record_id="profile-7723", credential=..., reason="duplicate delete")` where the record is already Deleted. The orphan pre-check finds no pending orphan (the record's current deletion is bound) and writes the intent record `record.soft_delete_intended`. The Soft Delete write `SoftDelete.soft_delete("profile-7723", ...)` → `rejected(already-deleted)`. The composition returns `rejected(already-deleted)`. No state is written; no *outcome* event is recorded. The intent record stands and appears in [Recover History]'s attempts residue — here the benign reading, a duplicate request against a record already in the state the caller wanted, which Check 5.3 resolves against the Soft Delete store.

### Regulated adversarial scenarios

Three scenarios the composition must survive in regulated contexts:

**Regulator audit — GDPR/HIPAA: prove a data subject's erasure was performed, attributed, tamper-evident, and the full lifecycle is recoverable.**

A GDPR supervisory authority or HIPAA Office for Civil Rights (OCR) investigator queries `recover_history(record_id="profile-4491", ...)` with original event payloads. The returned `lifecycle_history`:
- `current_state = Purged` — the record is destroyed, consistent with the erasure claim.
- For each event in the reconciled sequence for `profile-4491`: `attestation_verification = verified` by Invariant 1 (lifecycle attribution coverage) — each transition has an Audit Trail event whose Actor Identity attestation binds actor_ref to a credential. The Tamper Evidence seal (via Audit Trail Invariant 3) confirms no event was rewritten after the fact.
- Every event's `retention_state = Retained` — the audit events are under active retention per the configured policy (Audit Trail Invariant 2 — retention coverage).
- `overall_verdict = history-complete`.
The regulator's question — *who deleted the record, who purged it, was the record tampered with, and is the audit trail being kept?* — is answered from the records alone. Invariant 1 through 3 are the structural basis for each answer. No developer narration is required.

**Disputed erasure — data subject claims their record was not erased, or was erased without their request.**

A data subject or their representative challenges the system: *"I never requested erasure — who deleted my record and why?"* or *"I requested erasure months ago and nothing was done."*

Claim (a) — unauthorized erasure: [Recover History] returns the full event list, including the earliest `record.soft_deleted` event with actor_ref and `data.reason`. Invariant 1 (lifecycle attribution coverage) guarantees every transition is attributed. If the reason field on the first `record.soft_deleted` event does not reference a DSAR ticket or an authorized process, the attribution is in the record — the actor who performed the deletion is named. The data subject's claim that it was unauthorized is an external-clearable question (whether the actor had authorization is a Permissions/governance matter, not a records matter), but the records name who did it.

Claim (b) — erasure not performed: `SoftDelete.read({record_id})` returns the current lifecycle record. If the record is in Deleted or Active state rather than Purged, the erasure was not completed; the reconciled sequence [Recover History] returns shows every transition taken, and the absence of a `record.purged` event in that sequence is the structural evidence. The composition records what happened, not what should have happened; the absence of a purge event is the honest answer that the erasure was not completed.

In both cases the records answer from Invariants 1 and 3; the challenge cannot be sustained without claiming the records were fabricated, at which point Audit Trail Invariant 3 (tamper-evident seal) and `attestation_verification = verified` from each event are the structural rebuttal.

**Breach or incident investigation — reconstruct every delete/restore/purge in an anomaly window and detect tampering via seal verification.**

An incident responder suspects records were purged by an unauthorized actor during an anomaly window (02:00–04:00 UTC (Coordinated Universal Time) on a given date). The responder reads the window through the substrate's pass-through **wall-time range read** — a declared query shape on Event Log's read, which passes through Audit Trail unchanged — and keeps, in the responder's own code, the events whose `action_ref = record.purged`, since a selection by `action_ref` is not a query the substrate serves (Composes 9 — the lifecycle enumeration). For each found `event_id`:
- The actor_ref field names who executed the purge. An actor_ref outside the authorized purge-actor set is an immediate finding (Invariant 2 — purge accountability requires the purge be attributed; it does not guarantee the actor was authorized, which is externally clearable via Defensible Retention / Permissions, but it names the actor structurally).
- `AuditTrail.verify_record(event_id, <the covering range's payloads, as read_record names the range>) → verified` confirms the event has not been tampered with since it was sealed. A `failed-verification(seal-proof-invalid)` result is a finding that the record was altered after sealing.
- `record_to_events[record_id]` can be read for each affected record_id to reconstruct the full lifecycle context around the anomaly purge: was the record deleted just before the purge (consistent with a rapid delete + purge sequence), or was it in a long-standing Deleted state (consistent with a scheduled purge)?

An unexpected actor_ref on a `record.purged` event, or a `failed-verification` on any event in the window, is a forensic finding. The seal cadence governs the window's resolution: a tighter cadence narrows the range of events that could have been tampered with between seal checkpoints. Invariant 1 through 4 are the structural basis for the investigation; the composition's records answer the investigation's questions from the records alone.

---

## Generation acceptance

An implementation is acceptable — in the regulator-acceptance sense — when an external auditor, given the lifecycle index, the Soft Delete store and the Audit Trail substrate stores, can clear the checks below without recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST enumerate the lifecycle events through the lifecycle enumeration AND reconcile the events against the lifecycle index (Action wiring 21).
Check 1.2: An auditor MUST NOT quantify over the lifecycle index alone (Action wiring 22).
Check 1.3: An auditor MUST find a passing verification for EVERY reconciled event whose covering range the auditor presents (Invariant 1.2).
Check 2.1: An auditor MUST find a purge outcome event in the reconciled sequence of EVERY Purged record (Invariant 2.1).
Check 2.2: An auditor MUST find no purge outcome event whose reason EQUALS blank (Invariant 2.1).
Check 2.3: An auditor MUST find no purge outcome event whose acting actor EQUALS blank (Invariant 2.1).
Check 3.1: An auditor MUST call [Recover History] for a sample of records with EVERY covering range supplied AND find history-complete (Invariant 3.1).
Check 3.2: An auditor MUST NOT test a history against the lifecycle index (Action wiring 22).
Check 3.3: An auditor MUST find EVERY transition the lifecycle enumeration finds for the record among the history's events (Invariant 3.1).
Check 3.4: An auditor MUST find EVERY payload-purged event resolving through the record read to a lifecycle event in Purged (Action wiring 25).
Check 3.5: An auditor MUST find the history's events ordered by intent position AND EVERY readable intent event id resolving to an intent event at exactly that position (Invariant 3.2).
Check 3.6: An auditor MUST find the history passing the path test against Soft Delete's current state (Verdict 6 through 8).
Check 3.7: An auditor MUST find a multi-cycle record's intermediate transitions among the history's events (Invariant 3.3).
Check 4.1: An auditor MUST find EVERY lifecycle entry's outcome event present in Audit Trail AND naming the entry's record (Composition state 8).
Check 4.2: An auditor MUST reconcile EVERY outcome event the lifecycle enumeration finds against the lifecycle index (Composition state 10).
Check 4.3: An auditor MUST find EXACTLY ONE outcome event naming each intent event an outcome event names (Invariant 4.3).
Check 4.4: An auditor MUST find Soft Delete's current transition of EVERY record matching the last transition of the record's reconciled sequence (Invariant 4.1).
Check 4.5: IF an examinable orphan carries no open finding THEN an auditor MUST find the orphan's compensating event landed WITHIN the compensation window (Invariant 4.2).
Check 4.6: An auditor MUST find EVERY compensating event attested under the recovery identity AND carrying the recovery flag, the acting actor reference AND the intent reference (Reconciliation 10 and 11).
Check 4.7: An auditor MUST find EVERY outcome event carrying the recovery flag preceded by a recovery intent (Reconciliation 9).
Check 4.8: An auditor MUST find the compensation window exceeding the liveness sum (Capability requirement 20).
Check 4.9: An auditor MUST find no outcome event whose intent position falls between a pending orphan's intent position AND the orphan's compensating event (Invariant 4.6).
Check 5.1: An auditor MUST find EVERY outcome event's intent event id naming an intent event of the matching kind that PRECEDES the outcome event (Invariant 6.1).
Check 5.2: An auditor MUST find EVERY outcome event's acting actor matching the named intent event's actor reference (Invariant 6.1).
Check 5.3: An auditor MUST classify EVERY unmatched intent against the Soft Delete store (Action wiring 40).
Check 6.1: An auditor MUST clear Soft Delete's Generation acceptance over the Soft Delete instance (Composes 5).
Check 6.2: An auditor MUST clear Audit Trail's Generation acceptance over the Audit Trail instance (Composes 5).
```

NOTE: EVERY check names the rule the check tests.

Term passing verification: verified | failed-verification carrying purged.

Term acting actor: an outcome event's actor reference, or its acting actor reference where it carries the recovery flag.

Term examinable orphan: a pending orphan whose intent is neither a young intent nor an aged intent.

WHY:
**The auditor enumerates from the substrate, never from the index** (Check 1.1, 1.2 and 3.2). An auditor who quantified over the index would read a derived index at a shape its rebuild-on-miss does not cover, so a lost key or a lost element would present as a record or transition that never existed, and the check would pass over exactly what it exists to verify. And a history is tested against sources it was not built from: [Recover History] reconciled it with the index, so agreement with the index proves nothing (Check 3.3 through 3.7) — a history that passes them is complete by evidence outside the index.

**The bijection has two directions, and only one finds omissions** (Check 4.1 through 4.4). The forward direction verifies the index against its source and can find only dangling references — it cannot find an omission by construction, and a clean forward pass is not evidence of completeness. The reconciliation is the direction that finds omissions: a transition the enumeration finds and the index lacks is an index gap the rebuild closes; one the index holds and the enumeration cannot reach is payload-purged, not a defect. The reverse direction — every committed transition has an event — holds by the sole write path and is corroborated for the current state (Check 4.4), **between two edges**: a current state whose intent is younger than the bound is inconclusive, and one whose events lie past the audit horizon is the retention asymmetry, answered by the index's purged half. Inside the edges an orphan carries a compensating event inside the window or an open finding, and neither is the failure (Check 4.5). A check that read one knob of the window confirms nothing; the inequality is read whole (Check 4.8; the section titled *Liveness is arithmetic* in `pressure-testing.md`). Check 4.9 confirms the gate held: a transition committed on top of a pending orphan overwrote the attribution the pairing needed.

**Authentication precedes the transition, and the join is exact** (Check 5.1 and 5.2). Every outcome carries the id of the intent that authenticated it, and because the substrate validates the caller's credential inside every audit write, the named intent *is* the records-alone proof that the actor was authenticated before the transition committed — what makes Invariant 6 verifiable rather than asserted. **The carve-out is the compensation path**: an event carrying the recovery flag is attested under the recovery identity, so the check compares the intent's actor with the original actor the event names, not its attester — without that, the check would condemn every event the composition's own recovery produces. **An intent with no outcome is not a failure, and here it is forensically material** (Check 5.3): classified against the Soft Delete store, a moved state is the pending orphan the reconciliation compensates, and an unmoved one is the record of an attempted deletion, restore or destruction that did not happen — so a regulated reader can tell *nothing was attempted* from *something was attempted and refused or lost*.

**The constituents' own bars are cited, not counted** (Check 6.1 and 6.2; 2026-08-26-e): the composition's invariants depend on its constituents', and a count copied from another page goes stale on that page's next change.

### External checks

```
External check 1: An auditor needing purge eligibility confirmed MUST read Defensible Retention's records (Non-goal 1).
External check 2: An auditor needing the acting actor's authority confirmed MUST read the deployment's Permissions records (Non-goal 3).
External check 3: An auditor needing content destruction confirmed MUST read the host system's destruction attestation (Non-goal 5).
External check 4: An auditor needing the sole write path confirmed MUST read the deployment's attestation (Composes 7).
External check 5: An auditor needing the index durability confirmed MUST read the deployment's provisioning of the lifecycle index (Capability requirement 22).
External check 6: An auditor needing the record exclusion confirmed MUST read the host's declaration of the record exclusion (Capability requirement 11).
```

WHY:
**Eligibility is a sibling's record** (External check 1): the composition records that a purge happened, who ran it, when and why; whether a hold was active or a retention had elapsed is [Defensible Retention](./defensible-retention.md)'s hold-check evidence. A deployment composing both gets the attributed history and the eligibility evidence. **Authority is a Permissions question** (External check 2): the composition records an actor whose credential verified at the intent, before the transition committed (Invariant 6); whether that actor was the *right* actor is not in these records. **Content destruction is the host's** (External check 3): the composition records that Soft Delete answered purged, and whether the bytes were erased is the host system's to attest — or a media-sanitization audit under NIST SP 800-88 (the US National Institute of Standards and Technology's storage sanitization guidelines). The sole write path, the index's durability and the exclusion are deployment capabilities the records rest on and cannot prove (External check 4 through 6).

---

## Non-goals

```
Non-goal 1: The composition MUST NOT gate purge eligibility.
Non-goal 2: A deployment needing the hold-blocks-purge gate MUST compose Defensible Retention.
Non-goal 3: The composition MUST NOT gate an action on authority.
Non-goal 4: The composition MUST NOT adjudicate the retention of an erasure's own audit record.
Non-goal 5: The composition MUST NOT perform content destruction.
Non-goal 6: The composition MUST NOT record an audit event for a query.
Non-goal 7: A deployment needing an access audit of the query surface MUST wrap [Recover History] AND the read passthrough in an access-logging pattern.
Non-goal 8: A lifecycle action MUST act on EXACTLY ONE record.
Non-goal 9: A deployment needing atomic bulk deletion MUST wrap the lifecycle actions in a transaction at the composing layer.
Non-goal 10: The composition MUST NOT dispose of a Soft Delete lifecycle record.
Non-goal 11: A deployment needing a credential checked ahead of the intent record MUST wire an Actor Identity pre-check above the composition.
```

WHY:
**Purge eligibility belongs to [Defensible Retention](./defensible-retention.md)** (Non-goal 1 and 2), which wires Legal Hold, Retention Window and Audit Trail into the hold-blocks-purge gate. This is the forensic-attribution composition and that is the eligibility-gate composition; a deployment needing both composes both, and neither absorbs the other's concept. **Authenticity is gated here; authority is not** (Non-goal 3). An actor who cannot present a credential that validates against the actor reference claimed gets nothing done (Invariant 6), while an actor who can, but should not, is the question a composing [Permissions](../atoms/permissions.md) pattern answers at the calling layer under the permissions scope prefix's scopes. Purge in particular is a restricted action in any deployment handling regulated records.

**The right-to-erasure meta-question** (Non-goal 4). A data subject's GDPR Article 17 request destroys the underlying record; the lifecycle events recording that destruction carry an actor reference, a reason and an instant that may themselves be personal data. Article 17(3)(b) permits retention necessary for compliance with a legal obligation, and audit records of erasure decisions are typically retained to demonstrate compliance — but what beyond the structural fields may be kept is legal counsel's to assess. The composition does not adjudicate it and inherits the substrate's posture: Audit Trail Non-goal 6, which declines to adjudicate an erasure request against a retention obligation (2026-08-30-a).

**Content destruction is the host system's** (Non-goal 5), inherited from Soft Delete: [Purge Record] delegates to Soft Delete's purge, which signals the purged outcome, and the host executes the erasure against its own storage.

**Queries are not audited here** (Non-goal 6 and 7). [Recover History] and the read passthrough change no state and record no audit event; the composition's audit surface is committed lifecycle *actions*, not lifecycle *queries*. A deployment that must account for who queried the history wraps the read surface in an access-logging pattern — Audit Trail's failed-attribution-attempts posture and Chain of Custody's custody-query posture, the same line.

**One record per call** (Non-goal 8 and 9): bulk deletion over a filter is a composing-layer operation, and all-or-nothing bulk deletion needs a transaction wrapper there. **The lifecycle records outlive their audit events** (Non-goal 10): disposing of Soft Delete's own records is a separate concept — a Defensible Retention instance applied to the Soft Delete store directly (Retention asymmetry 1). **A credential checked ahead of the intent** (Non-goal 11) is a composing peer's, and needless for the guarantee: the intent record already refuses a credential that does not verify before anything commits.

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A lifecycle action's intent event, Soft Delete write AND outcome event MUST carry the invocation's now.
Clock semantics 2: The composition MUST NOT read a recording instant as a transition instant.
Clock semantics 3: IF the Soft Delete write refuses the transition instant THEN the lifecycle action's intent record MUST stand as an attempt.
```

WHY:
**One reading carries three names** (Clock semantics 1; 2026-08-26-m): the intent's intended instant, the Soft Delete write's transition instant, and the outcome payload's recorded instant are the one now the host injected at the seam, which is what lets the pairing rule use the stamp as a key. A compensating event re-derives its transition instant from the intent it binds, so a recovery carries the transition's instant, not the compensation's. **Two instants are distinct** (Clock semantics 2; 2026-08-26-h): the payload's transition instant is the composition's reading, and Event Log's recording instant is the substrate's own stamp of the append; a history event carries both, and an auditor asking *when did this happen* reads the first, while *when was it recorded* reads the second. **Skew is the deployment's** (Clock semantics 3; 2026-08-30-d): Soft Delete refuses a transition instant later than its own now (Soft Delete Operation 16), and the cross-node agreement between the seam's clock and Soft Delete's is owned by the deployment under Execution Contract Logic confinement 7. A seam clock running ahead makes that refusal reachable after the intent — a refused attempt with nothing committed, relayed as invalid-request (Action wiring 12) and classified by Check 5.3 — so the assumption is named here rather than absorbed into a new setting.

### Concurrency

```
Concurrency 1: The record exclusion MUST span the orphan pre-check, the intent record, the Soft Delete write, the outcome record's retries AND the lifecycle entry's insert.
Concurrency 2: The reconciliation MUST compensate a record ONLY under the record exclusion.
```

WHY:
Two callers acting on one record are serialized: Soft Delete's first write wins, and the second observes the new state and answers already-deleted, already-purged or not-deleted. The composition **widens the serialization to the whole action** (Concurrency 1), and the widened exclusion is the deployment's, not Soft Delete's (Capability requirement 11). The widening is what makes intent order commit order: an exclusion scoped to the transition alone lets another action's intent and outcome interleave between this one's transition and its outcome, so the audit writes commit out of the order the transitions did and no key in the records recovers it. A compensation runs later **under the same exclusion** (Concurrency 2): the exclusion governs how many writers an outcome can have — one — and the intent governs where the outcome sits in the replay, fixed before the transition committed.

### Retention asymmetry

```
Retention asymmetry 1: A purged entry MUST stay in the record's reconciled sequence.
Retention asymmetry 2: The composition MUST NOT read a Soft Delete record whose lifecycle events aged out as an orphan.
```

WHY:
The audit retention policy governs the lifecycle events; Soft Delete's lifecycle records persist by the atom's own discipline (Soft Delete Invariant 7). When an event's horizon lapses and the substrate's cascade purges it, the lifecycle record stays, and [Recover History] reports the transition as lawfully destroyed — honestly distinguished from missing (Audit Trail Invariant 8). The index's purged half is what keeps the transition in the history (Composition state 11), and the reconciliation's upper edge is what keeps it from being mistaken for an orphan (Reconciliation 4).

### Pre-composition transitions

```
Pre-composition transitions 1: The composition MUST read a transition predating the composition as a binding gap.
Pre-composition transitions 2: A deployment migrating an existing Soft Delete store MUST take EXACTLY ONE OF a backfill of the lifecycle index and the matching audit events, a disclosed coverage boundary.
```

WHY:
A record transitioned before the composition carried it has no intent, no outcome and no lifecycle entry for those transitions, so [Recover History] answers the current state and a history holding only what came after. The missing transitions are at the sequence's head, and Verdict 6 and 7 read an edge disagreement as binding-gap — a transition with no event — never as out-of-order, which names an ordering defect among transitions that are all present (2026-08-30-b).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the three lifecycle actions it wraps ([Delete Record], [Restore Record], [Purge Record]) and the emergent forensic read ([Recover History]); the structure that read answers ([Lifecycle History]) with its summary [Overall Verdict] and per-event [Attestation Verification]; and the two verdict values ([History Complete], [History Incomplete]). The binding bijection, forensic completeness and authentication before commitment are structural properties, not data. The deployment settings keep their wire spellings in configuration — `audit_trail_retention_policy`, `seal_cadence`, `recovery_identity`, `transition_completion_bound`, `outcome_retry_attempts`, `record_serialization`, `compensation_window`, `reconciliation_cadence`, `outcome_write_latency`, `intent_candidates_cap`, `index_durability`, `permissions_scope_prefix` — and the split-classified lifecycle index and the enumeration mark theirs in an implementation, `record_to_events` and `enumeration_high_water`; the page names each in English where it declares it. The record lifecycle states are Soft Delete's and are not carded here. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the reconciliation; a deployment; a regulated deployment; an auditor; a caller; an investigator; an invocation; a holder; a lifecycle action; a validated lifecycle action; a cleared lifecycle action; an admitted lifecycle action; a committed lifecycle action; a bound lifecycle action; a validated history read; a found history read.

Term records: the intent events, outcome events and recovery intents the composition records through Audit Trail — each an Event Log event carrying one action reference below — and the lifecycle index's entries.

Term record verbs: act, adjudicate, alert, answer, append, apply, attest, bind, build, call, carry, change, check, claim, classify, clear, collect, commit, compare, compensate, compose, cover, declare, disclose, dispose, duplicate, enter, enumerate, escalate, examine, expose, fall, fetch, find, follow, gate, hold, inherit, inject, insert, inspect, keep, key, land, leave, match, name, normalize, number, order, override, pair, pass, perform, persist, place, proceed, provision, quantify, re-derive, re-read, re-send, reach, read, rebuild, reconcile, record, refuse, release, remove, report, retry, run, select, serve, set, share, size, span, stand, start, stay, store, supply, surface, take, test, wire, wrap, write.

Term value sets: action reference = record.soft_delete_intended | record.restore_intended | record.purge_intended | record.soft_deleted | record.restored | record.purged | record.recovery_intended. provenance = both | index-gap-repaired | payload-purged | enumeration-miss. The rest are declared where the section that owns each declares it: kind, position, cause, state refusal, class, failure class, incomplete-verification class, reported outcome, passing verification.

Term bounds: transition completion bound (transition_completion_bound), outcome retry attempts (outcome_retry_attempts), compensation window (compensation_window), outcome write latency (outcome_write_latency), intent candidates cap (intent_candidates_cap), audit horizon (audit_trail_retention_policy).

Term cadences: reconciliation cadence (reconciliation_cadence), seal cadence (seal_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-24).

Term terms: composition, constituents, transitive atoms, Soft Delete write, lifecycle enumeration, record read, audit write, verification, record id, lifecycle index, lifecycle entry, intent position, live entry, purged entry, lifecycle rebuild, enumeration mark, audit retention policy, audit horizon, seal cadence, recovery identity, transition completion bound, outcome retry attempts, record exclusion, compensation window, reconciliation cadence, outcome write latency, liveness sum, intent candidates cap, index durability, permissions scope prefix, seam, now, actor reference, credential, reason, event id, outcome payload, compensation payload, caller string, envelope, intent record, outcome record, pre-append step, retention step, position, finding, cause, unretained field, recovery intent, recovery flag, acting actor reference, lifecycle result, lifecycle history, original event payloads, lifecycle action, read passthrough, kind, kind's intent event, kind's outcome event, kind's Soft Delete write, validated lifecycle action, pre-check's start, unmatched intent, cleared lifecycle action, admitted lifecycle action, state refusal, committed lifecycle action, bound lifecycle action, intended instant, transition instant, recording instant, validated history read, found history read, reconciled sequence, index gap, enumeration gap, covering range, live event, attempts, reconciliation, young intent, aged intent, pairing, pending orphan, crash orphan, intent candidates, candidate count, intent reference, compensating event, overdue orphan, class, failure class, incomplete-verification class, reported outcome, current state's transition, lifecycle steps, failed attestation, failed seal, unavailable surface, settled transition, compensable orphan, uncompensable orphan, passing verification, acting actor, examinable orphan, history event, sequence position, provenance, retention state, current state, current summary.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. Execution Contract Logic confinement 7 — the clock's guarantees are the deployment's. The section titled Composition state in `execution-contract.md` — the derived-index and extraction-pending classifications. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. The section titled Compositions of compositions in `spec-format.md` — the transitive atoms. soft_delete, restore, purge, read, Active, Deleted, Purged, deleted_by, restored_by, purged_by, deleted_at, restored_at, purged_at, lifecycle record, invalid-request, already-deleted, already-purged, not-known, not-deleted, storage-failure, invalid-query: Soft Delete. record_action, read_record, verify_record, payload cap, reference length cap, attestation id, sealed through, unsealed tail, unsealed tail mode, strict, step-2, step-3, step-4, invalid-credential, recording-failure, verified, failed-verification, unverifiable, purged, compensation-window, Retained, Erasure Tombstone: Audit Trail. sequence number, append: Event Log. attest: Actor Identity.

Term composing patterns: [Defensible Retention](./defensible-retention.md); [Permissions](../atoms/permissions.md); [Chain of Custody](./chain-of-custody.md); [Multi-Party Approval](./multi-party-approval.md).

Term history event: one entry of a lifecycle history's events — its sequence position, provenance, event id, action reference, actor reference, acting actor reference, recovery flag, transition instant, recording instant, reason, [Attestation Verification] and retention state.

Term sequence position: a history event's one-based index in the reconciled sequence.

Term provenance: how a history event was reached — both, index-gap-repaired, payload-purged or enumeration-miss.

Term retention state: the retention state the record read answers for a history event — Retained, Purged, unresolved in its compensation window, or unknown.

Term current state: the record's Soft Delete state, read through Soft Delete's read.

Term current summary: the record's current attribution from Soft Delete's read — the summary Soft Delete keeps, beside the history it does not.

#### Delete Record

The composition action that soft-deletes a record through Soft Delete and, ordered after that write, binds the transition to an attributed, sealed Audit Trail event (`record.soft_deleted`) inserted into `record_to_events` at its intent position. Refused orphan-pending while a committed transition of the record is still owed its audit event. Returns `{record_id, event_id, unretained?}`.

Kind: Operation

#### Restore Record

The composition action that restores a Deleted record to Active through Soft Delete and binds the restore transition to an attributed Audit Trail event (`record.restored`). Refused orphan-pending while a committed transition of the record is still owed its audit event. Returns `{record_id, event_id, unretained?}`.

Kind: Operation

#### Purge Record

The composition action that permanently destroys a record through Soft Delete and binds the purge to an attributed Audit Trail event (`record.purged`) naming who purged it, when, and under what stated reason. It does **not** check purge eligibility — Legal Hold and retention gating belong to Defensible Retention; this composition records the purge faithfully. reason is required. Refused orphan-pending while a committed transition of the record is still owed its audit event. Returns `{record_id, event_id, unretained?}`.

Kind: Operation

#### Recover History

The composition's emergent forensic read: reconstruct the complete, ordered, attributed, tamper-verified delete/restore/purge history of a record from `record_to_events` and the Audit Trail substrate — including prior epochs Soft Delete's current-state summary overwrites. Returns a [Lifecycle History]; the caller must present the original event payloads (Audit Trail's verification asymmetry). No audit event is produced — it changes no state.

Kind: Operation

#### Lifecycle History

The structure [Recover History] returns: the record's current Soft Delete state and attribution summary, an ordered per-event verification list, and a summary [Overall Verdict]. The records-alone answer to *who deleted, restored, and purged this record, in what order, and is each step attributed, sealed, and within its retention horizon?* — which neither constituent provides alone.

Kind: Type
Role: the reconstructed lifecycle-history structure

#### Overall Verdict

The summary field of a [Lifecycle History], computed over the reconciled sequence: [History Complete] when every transition has a binding, the sequence replays as a legal lifecycle path, and every verification passes (or is lawful destruction), else [History Incomplete] naming each class that applies — the failure classes (binding-gap, attestation-failed, seal-failed, unsealed, out-of-order) and the incomplete-verification classes (payload-not-supplied, partially-purged-coverage, availability).

Kind:       Field
Field of:   the lifecycle history
Role:       the summary verdict
Projection: overall_verdict

#### Attestation Verification

The per-event field of a [Lifecycle History]: the result of re-verifying each transition's Audit Trail seal — verified, `failed-verification(reason)` (the substrate's purged, `attestation-…`, `seal-…`, or unsealed), not-known, or `unverifiable(reason)` (this composition's `payload-not-supplied(missing)` when the caller did not supply the event's covering range, or the substrate's partially-purged-coverage, `attestation-registry-unavailable`, `seal-mechanism-verification-unavailable`), optionally qualified `(compensation-window)`. For a purged event the substrate's own answer comes first and the caller's map is not consulted.

Kind:       Field
Field of:   the per-event verification record
Role:       the per-event seal-verification result
Projection: attestation_verification

#### History Complete

The [Overall Verdict] value when every transition in the reconciled sequence has a binding, the sequence is a legal lifecycle path, and every [Attestation Verification] returns verified (or a lawful `failed-verification(purged)`) — the record's full lifecycle is proven from the records alone. A retention-pending, index-gap-repaired or payload-purged outcome is reported beside it and does not block it.

Kind:       Member
Member of:  the overall verdict
Role:       Verdict
Projection: history-complete

#### History Incomplete

The [Overall Verdict] value when at least one class applies (a binding gap, a failed attestation, a seal failure, an unsealed tail event, a sequence that does not replay as a legal lifecycle path, a not-supplied payload, partially-purged seal coverage, or a verifying surface that was unavailable) — the reconstruction is not fully self-proving, and the verdict names why.

Kind:       Member
Member of:  the overall verdict
Role:       Verdict
Projection: history-incomplete

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Delete Record]: #delete-record
[Restore Record]: #restore-record
[Purge Record]: #purge-record
[Recover History]: #recover-history
[Lifecycle History]: #lifecycle-history
[Overall Verdict]: #overall-verdict
[Attestation Verification]: #attestation-verification
[History Complete]: #history-complete
[History Incomplete]: #history-incomplete


## Standards references

This composition is the structural form of the forensic-deletion-lifecycle requirement across its canonical regulated domains:

- **GDPR Article 17 (Right to erasure / Right to be forgotten — EU General Data Protection Regulation)** — the data subject's right to request destruction of personal data. Invariant 2 (purge accountability) and Invariant 3 (forensic completeness) together provide the structural erasure proof: not only is the destruction recorded and attributed, but the full lifecycle leading to the erasure is recoverable. Article 5(1)(e) (storage limitation) is satisfied by the attributed, time-bounded purge record; Article 5(1)(f) (integrity and confidentiality) is supported by the Tamper Evidence sealing via the Audit Trail substrate.

- **HIPAA §164.310(d)(2)(i) (Disposal — Health Insurance Portability and Accountability Act)** — covered entities must implement policies for the final disposition of electronic Protected Health Information (PHI). This composition's [Purge Record] + `record.purged` audit event is the disposal-attribution record required by this provision; [Recover History] is the audit surface demonstrating that disposal was attributed and complete.

- **HIPAA §164.312(b) (Audit controls)** — electronic information systems must record and examine activity. The lifecycle audit events produced by this composition (one per [Delete Record], [Restore Record], and [Purge Record] call) are the audit-control records for the deletion lifecycle; [Recover History] is the examination surface. The Audit Trail substrate's attribution, retention, and tamper-evidence satisfy the integrity and non-repudiation aspects of the audit-controls requirement.

- **FRCP Rule 37(e) (Federal Rules of Civil Procedure — preservation duty for electronically stored information, spoliation)** — failure to preserve ESI (Electronically Stored Information) when litigation is reasonably anticipated can result in sanctions. A [Purge Record] call executed while a Legal Hold is active is the spoliation exposure; this composition's `record.purged` audit event (with actor_ref, reason, and `recorded_at`) is the structural record of the destruction. Whether the purge was permissible under the legal duty is Defensible Retention's records question; whether the purge happened and who executed it is this composition's records answer. The sealed, attributed, retained audit event is the evidence-grade record FRCP Rule 37(e) sanctions hearings require.

- **SOX §802 (Sarbanes-Oxley Act — 18 U.S.C. §1519, criminal obstruction of justice for records destruction subject to federal investigation)** — this composition's purge accountability invariant (Invariant 2) is the structural defense: no purge occurs without an attributed, sealed, retained audit event naming the actor and the stated reason. Whether a legal hold was active at purge time is Defensible Retention's question; whether the purge was attributed is this composition's guarantee.

- **ISO 15489-1 (Records management — International Organization for Standardization)** — Section 9.7 (suspension of disposition) and Section 9.9 (destruction of records). The Deleted → Purged path in this composition aligns with ISO 15489's deliberate-authorization requirement for records destruction; the attributed audit trail satisfies the accountability requirement for destruction decisions.

- **NIST SP 800-88 (Guidelines for Media Sanitization — US National Institute of Standards and Technology)** — the reason field in the `record.purged` audit event documents the stated authority for destruction; the media-sanitization mechanism itself is the host system's obligation (Non-goal 5).

This composition inherits the broader standards compliance of its constituents:

- Through **Audit Trail** (and its transitive atoms): SOX §802 record retention, HIPAA §164.312(b) audit controls, PCI DSS (Payment Card Industry Data Security Standard) Requirement 10, 21 CFR Part 11 (US Code of Federal Regulations — electronic records and signatures in regulated industries), SEC (US Securities and Exchange Commission) Rule 17a-4, ISO/IEC 27001 §A.12.4 (logging and monitoring), GDPR Articles 30 and 32, and the full Audit Trail standards inheritance. Deployments composing this composition for regulated-record-lifecycle purposes receive these as the substrate's contribution; they are framed as inherited, not as this composition's own primary standards anchors.

- Through **Soft Delete**: GDPR Article 17, GDPR Article 5(1)(e), HIPAA §164.310(d)(2)(i), HIPAA §164.312(b), FRCP Rule 37(e), SOX §802, ISO 15489-1, and NIST SP 800-88 at the lifecycle-state and attribution layer. This composition lifts these to the full attributed+sealed+full-history-recoverable form those standards actually require but that Soft Delete alone cannot satisfy.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: forensic-recovery.tla + 1 twin verified 2026-06-11 over a single-writer invocation with no terminus and no orphan gate; re-derive over the invocation and the scan as two processes over one transition, the bound as the yield point, and the `orphan-pending` refusal on a later transition (2026-08-29-a, 2026-08-30-h)
last gate: 2026-08-30 — third gate, fresh reader, under the frozen rules — 7 foundational and 10 refining corrected in-round, 4 refining (one the formal re-derivation) and 3 rhetorical routed (3 refining and 1 rhetorical duplicating lines already open); closure check 2026-08-30 — 5 new defects and 10 consistency items corrected in-round; 2026-08-26 authentication-precedence gate — 4 foundational routed (all since closed), 1 foundational and 6 refining corrected in-round, 13 refining (3 since closed) and 3 rhetorical routed

open:
- 2026-08-29-a · refining · formal · the model's compensation action carries no identity, no recovery record, and no age bound → extend the model with the bounded scan under `recovery_identity`
- 2026-08-30-h · refining · formal · the model has one writer per transition and no gate: it cannot exhibit the invocation and the scan both landing an outcome, nor a later transition overwriting a pending orphan's attribution → extend it with the scan as a second process over one transition, the bound as the yield point, and the `orphan-pending` refusal
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/forensic-recovery.md`.

- **2026-09-24 — Rewritten in GRACE lang v0.61; eighteen of twenty open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, the critical section renamed the record exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the verdict table as its own `Verdict` family; invariant numbers 1 through 4 and 6 unchanged, Invariant 5 tombstoned to Composes 5; the record checks renumbered as Conformance checks that each name the rule they test; the edge cases split into Non-goals and four Edge cases families. Three choices were the page's to make, each decided by a standing rule: [Recover History] drops the actor reference nothing consumed (2026-08-26-l — *make all things mean one thing*: a parameter no rule reads is a promise with nothing behind it); an edge disagreement in the path test is binding-gap and an interior one out-of-order (2026-08-30-b — the same rule: each class names one defect); and the clock skew behind Soft Delete's future bound is named as Execution Contract Logic confinement 7's rather than absorbed into a new setting (2026-08-30-d — *generalize nothing*). *Over:* keeping the prose's five-arm step lists and its recorded instant that named two values. *Because:* the rules state the protocol once and every step cites it; the two formal lines stay open because the model, not the page, is what they owe.
- **2026-08-30 — One writer per transition, a record with a pending orphan admits no new transition, the purged answer first, the enumeration route declared, the envelope sized before the intent, the retry bit carried.** *Chose:* an in-invocation retry bounded by `outcome_retry_attempts` inside the record's critical section, a scan that takes the same section (`record_serialization`, a declared instance capability) for every record it compensates and re-reads its pre-check under it, and an outcome step that adopts an outcome it finds rather than appending beside it; an orphan-pending refusal at step 2 of every lifecycle action while a committed transition is owed its outcome event, so the stamp-and-actor pairing against Soft Delete's current attribution stays exact — the atom keeps only the most recent of each kind, and a later transition would overwrite the field the pairing reads; [Recover History] branching on retention state before any membership check, so a purged transition lands `failed-verification(purged)` and [History Complete] stays reachable after a purge; every substrate verification outcome placed in a verdict class, with `retention-lapsed` dropped as a class nothing produced; the lifecycle-event enumeration declared as the substrate's pass-through open-upper-bound sequence-range read with the selection made in composition code, Reverse Index an optimization; the outcome and compensation envelopes sized at step 1 against `payload_cap` with `intent_candidates_cap` bounding the compensation; `recording-failure(intent | outcome(finding))` on every lifecycle signature with the orphan in the finding and `unretained` in the result; the liveness inequality written out with `outcome_write_latency` (declared) and checked at instance start; and, from the closure check the same day, the section's lease semantics stated — exactly `transition_completion_bound` long, expiry the invocation's terminus, re-taken before any later pre-check and never written past — so the hold time a stalled holder can impose on the scan is the inequality's first term, `enumeration_high_water` declared as the read-back's derived lower edge, Actor Identity's own invalid-request landed at both positions, the envelope sized with the longer of the two attesting actors, and every remaining "atomic" and "walks the index" phrasing brought to *ordered* and *reconciled sequence*. *Over:* "retry until it lands" beside a scan starting at the bound; a pairing by a stamp any later transition could overwrite; a membership check ahead of the constituent's purged short-circuit; a read "by `data.record_id`" the substrate routes to a forthcoming pattern; a foreclosed-by-construction argument made about the intent and not the outcome; a bare token on both sides of the commit with the finding in prose only; a section attributed to the host with no lease length, whose stalled holder could block the scan for as long as it liked. *Because:* two compensators over one transition land two outcomes the seal then protects; a lawfully destroyed payload is not one the caller failed to supply; a capability the constituent declines is an undeclared dependency however often the page calls it declared; an unbounded set is an input, not a construction; a caller who cannot tell intent from `outcome` re-runs a committed act; and a lease longer than the bound is a hold time the inequality never counted — while the gate is what keeps an orphan pairable, since the composition does not get to weaken Soft Delete's latest-only attribution by paraphrase (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Lawful destruction is answered before absence*, *An outcome is sized before the intent*, *Liveness is arithmetic*, *A stamp from another seam never decides a write alone* (swept: the pairing passes the composition's own reading through, so equality is by construction; the skew on Soft Delete's future-bound routed as 2026-08-30-d), *A composition's own rejection arm carries the retry bit*, and *Capability provenance* frozen — with §*Intents pair with outcomes* and §*A transcribed rejection arm*'s fourth tell).
- **2026-06-11 — Invariant 4's compensated arm is in the model, not idealized away.** *Chose:* re-derive the model over sequential sub-writes with compensation. *Over:* the original model, which committed three sub-writes as one atomic action. *Because:* Soft Delete writes first and Purged is terminal, so rollback is not universally available and the compensated path is the design, not an exception.
- **2026-08-27 — The replay is ordered by the intent event's position, not the outcome's.** *Chose:* `record_to_events` entries carry `intent_position`, the Event Log sequence number of the intent event each outcome names; the list, the rebuild and [Recover History] order by it; the per-record critical section spans the whole action; and an ordered sequence that is not a legal lifecycle path carries the out-of-order failure class. *Over:* ordering by the outcome events' own positions, or by a timestamp the compensation preserves. *Because:* a compensated outcome lands when the compensation lands, so outcome order replays a retried delete after the restore that followed it; the intent record is written before the transition inside the serialized section and never re-emitted, so its position is commit order structurally, without a clock.
- **2026-08-29 — The scan is bounded at both edges, pairs by the injected reading, and writes as the recovery identity behind a recovery record; the outcome's step decides its landing.** *Chose:* `transition_completion_bound` below and the audit horizon above for the reconciliation scan; pairing of an orphan transition to its intent by `intended_at = deleted_at / restored_at / purged_at` and the attribution field, candidates named where undecidable; every scan write under `recovery_identity` behind `record.recovery_intended`; `recording-failure(step-4)` and the retention-source invalid-request at an outcome record read back and treated as landed; `compensation_window`, `reconciliation_cadence` and `index_durability` declared; Invariant 4's "committed atomically or" restated as ordered. *Over:* an unbounded scan re-emitting under an unstated identity, and a uniform "all three arms surface as recording-failure" at the outcome. *Because:* an unbounded scan appends a second outcome beside an in-flight invocation's and re-emits lawful destruction as orphans; the actor's credential is never persisted; and the substrate's step-4 arm means the event exists (the frozen rules of 2026-08-29 — *A reconciliation is bounded at both ends*, *Intents pair with outcomes*, *Recovery commits under a declared service identity*, *A transcribed rejection arm keeps its payload*).
- **2026-08-27 — [Recover History] reconciles the index against the enumeration in both directions.** *Chose:* report a transition the index lost as index-gap-repaired and one the enumeration can no longer reach as payload-purged, neither a failure class. *Over:* replacing the index list with the substrate enumeration. *Because:* the enumeration keys on a payload field the retention purge destroys while the index's `event_id`s still resolve, so naive anchoring would have shortened exactly the histories a forensic reader most needs.

NOTE: End of Forensic Recovery.

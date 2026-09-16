---
title: Soft Delete
parent: Atomic Concepts
has_toc: true
toc: true
---

# Soft Delete

<details open markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Soft Delete splits apart the two things an ordinary "delete" lumps together: hiding a record from normal use, and destroying it for good.

Here, "deleting" only does the first — the record is marked as removed and kept out of normal views, but it stays in storage, it records who deleted it, and it can be brought back. "Purging" does the second — the record is destroyed permanently, again recording who authorized it and when. Between deletion and purge there is always a way back: a deleted record can be restored as if nothing happened.

The pattern tracks three states — Active, Deleted, and Purged — and once something is Purged there is no return; even then, a small record of the destruction (who, when, why) is kept as evidence, while the actual content is gone.

Purge is the part that regulators care about — it is where data-erasure laws and records-destruction rules apply — but the pattern only records the destruction faithfully; deciding whether a given purge is actually allowed (a legal hold in effect, a retention period not yet elapsed) is left to other patterns that wrap around it.

*Also known as: archiving, deactivation, tombstoning, voiding.*

---

## Intent

WHY:
Most systems eventually need to delete records, and the naive implementation — remove the row, free the storage — destroys information that may still be needed: by the user who wants to undo a mistake, by an auditor tracing a decision, by a regulator exercising a right of access, or by a legal hold requiring preservation of exactly the records a purge would remove.

This atom separates the two concepts a hard delete conflates. *Deletion* means the record is marked removed, excluded from normal read surfaces, and no longer available for ordinary use — while remaining retained, attributable and recoverable. *Purge* means permanent destruction, with full attribution of who authorized it and when. Between the two, restoration is always available: the record returns to active as though it had never been deleted.

The three-state lifecycle appears in nearly every domain that handles records with lifecycle significance — content moderation, account management, clinical records, financial reconciliation, e-discovery — and the states are constant across them even where the vocabulary is not. *Archived*, *deactivated*, *tombstoned* and *voided* are all deleted by another name.

What the atom deliberately does not define is what *hidden from normal query* means operationally. That is deployment policy: a social platform hides deleted posts from public feeds and may surface them in moderator queues; a clinical system hides deleted observations from summaries and returns them on full audit export. Neither is wrong, and both correctly implement the deleted state. The atom defines the state and the recoverability guarantee, and leaves the read surfaces to the deployment.

Purge is the regulated interface. GDPR (EU General Data Protection Regulation) Article 17 erasure, HIPAA (Health Insurance Portability and Accountability Act) record destruction, and e-discovery spoliation risk all attach to the purge action rather than to the deleted state. The atom records the purge faithfully and asks no questions about it: whether a purge is legally permissible at a given moment — whether a hold is live, whether a retention window has elapsed — belongs to the composing layer, and building the gate in here would make the atom depend on the two patterns it is most often composed with.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a lifecycle record by the record_id.
Identity 2: The caller MUST supply the record_id.
Identity 3: The atom MUST NOT allocate a record_id.
Identity 4: The atom MUST NOT change a record_id.
Identity 5: Two lifecycle records in one store instance MUST NOT share a record_id.
Identity 6: The deployment MUST supply a record_id that sorts in lexicographic byte order.
Identity 7: The deployment MUST route EVERY call to one store instance.
Identity 8: The atom MUST compare a reference byte-exactly.
Identity 9: The atom MUST NOT normalize a reference.
Identity 10: The atom MUST NOT confirm that a record_id names a known host record.
Identity 11: The atom MUST NOT hold the host record's content.
```

Term lifecycle record: the state and attribution this atom holds for one host record — a state, the most recent deletion's attribution, and where they exist the most recent restore's and the purge's; the record this atom holds.

Term record_id: the opaque value naming one lifecycle record — a [Record Id]; the host record's identity, supplied by the caller and never allocated here.

Term tracked record: a host record carrying a lifecycle record — one that has undergone at least one [Soft Delete].

Term reference: `record_id`, `deleted_by`, `restored_by` OR `purged_by` — every opaque reference this atom records.

Term store instance: one named lifecycle store a call is routed to; `record_id` uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading here.

Term transition: the atom's evaluation of one call against the lifecycle store, as `execution-contract.md` §Logic confinement declares it.

WHY:
Identity 2 and Identity 3 are the atom's one departure from the corpus's usual identity shape, and the departure is the point: this atom does not own records, it overlays a lifecycle onto records the host already owns. There is nothing for it to allocate an id *for*. Identity 11 states the other half — the content stays in the host system, and what a purge destroys is the host's content, not anything held here (Non-goal 3).

Identity 10 follows from both. A `record_id` that names nothing in the host system still produces a valid lifecycle record: the atom is tracking a lifecycle it was told about, and confirming the subject exists would require reaching into a store it has no knowledge of.

### State

```
State 1: A host record carrying no lifecycle record MUST NOT stand in a state.
State 2: A lifecycle record MUST NOT leave purged.
State 3: The atom MUST NOT offer a restore-from-purged surface.
State 4: The atom MUST NOT offer a direct active-to-purged transition.
State 5: The atom MUST NOT offer a lifecycle record removal surface.
State 6: The atom MUST NOT offer an untrack surface.
State 7: EVERY lifecycle record MUST carry record_id, a state, deleted_by and deleted_at.
State 8: A lifecycle record MAY carry deletion_reason.
State 9: A lifecycle record MAY carry a restore field.
State 10: EVERY purged lifecycle record MUST carry purged_by, purge_reason and purged_at.
State 11: A purged lifecycle record MUST carry the deletion fields the purge found.
State 12: The store instance's lifecycle record count MUST NOT fall.
State 13: The atom MUST NOT record a receipt instant.
```

WHY:
State 7 says something easy to misread: *every* lifecycle record carries deletion attribution, including one standing in active. An active lifecycle record is a record that was deleted and then restored — the atom has no record of anything that was never deleted (State 1) — so the deletion fields are always populated, and they describe the most recent deletion rather than a current one.

State 11 is what makes a purge auditable. The lifecycle record outlives the content it describes: the host destroys the content on receiving the `purged` answer, and what remains here is the evidence that the destruction happened, who authorized it, and which deletion preceded it. Removing the lifecycle record would destroy the proof of destruction, which is the one thing a regulator comes to this store for.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST own the clock's monotonicity.
Capability requirement 3: The deployment MUST own the clock's honesty.
Capability requirement 4: The deployment MUST own the clock's synchronization.
Deleted: Clock semantics 1. Capability requirement 2 owns it.
Deleted: Clock semantics 2. Capability requirement 3 owns it.
Deleted: Clock semantics 3. Capability requirement 4 owns it.
Deleted: Clock semantics 4. State 13 owns it.
Deleted: Clock semantics 5. Non-goal 20 owns it.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

WHY:
The lower bounds (Operation 17, Operation 18) hold against the *resolved* value, so a skewed node cannot default its way past them: a wall-clock default that lands before the record's `deleted_at` is refused exactly as a caller-supplied one would be. A backdated instant is otherwise accepted — documenting a deletion or purge recognized later is valid, and the future bound refuses the one direction that is always fabrication.

### Operations

```
soft_delete(record_id, deleted_by, optional reason, optional deleted_at)
  answers deleted
  refuses invalid-request | already-deleted | already-purged | storage-failure

restore(record_id, restored_by, optional reason, optional restored_at)
  answers restored
  refuses invalid-request | not-known | not-deleted | already-purged | storage-failure

purge(record_id, purged_by, reason, optional purged_at)
  answers purged
  refuses invalid-request | not-known | not-deleted | storage-failure

read(query)
  answers the matching lifecycle records
  refuses invalid-query
```

```
Operation 1: IF record_id NOT EXISTS THEN a transitioning action MUST answer invalid-request.
Operation 2: IF the acting reference NOT EXISTS THEN a transitioning action MUST answer invalid-request.
Operation 3: IF reason NOT EXISTS THEN [Purge] MUST answer invalid-request.
Operation 4: IF the record_id names no lifecycle record THEN [Restore] MUST answer not-known.
Operation 5: IF the record_id names no lifecycle record THEN [Purge] MUST answer not-known.
Operation 6: [Soft Delete] MUST NOT answer not-known.
Operation 7: IF the record_id names no lifecycle record THEN an admitted soft delete MUST record the lifecycle record.
Operation 8: The atom MUST NOT offer a registration action.
Operation 9: IF the lifecycle record stands in deleted THEN [Soft Delete] MUST answer already-deleted.
Operation 10: IF the lifecycle record stands in purged THEN [Soft Delete] MUST answer already-purged.
Operation 11: IF the lifecycle record stands in purged THEN [Restore] MUST answer already-purged.
Operation 12: IF the lifecycle record stands in active THEN [Restore] MUST answer not-deleted.
Operation 13: IF the lifecycle record NOT EXISTS in deleted THEN [Purge] MUST answer not-deleted.
Operation 14: A transitioning action MUST answer a state rejection ONLY IF record_id EXISTS.
Operation 15: A transitioning action MUST answer invalid-request on an attribution fault ONLY IF EVERY state check passes.
Operation 16: IF the resolved transition instant EXCEEDS now THEN a transitioning action MUST answer invalid-request.
Operation 17: IF the resolved restored_at precedes the lifecycle record's deleted_at THEN [Restore] MUST answer invalid-request.
Operation 18: IF the resolved purged_at precedes the lifecycle record's deleted_at THEN [Purge] MUST answer invalid-request.
Operation 19: An admitted soft delete MUST stand the lifecycle record in deleted.
Operation 20: An admitted restore MUST stand the lifecycle record in active.
Operation 21: An admitted purge MUST stand the lifecycle record in purged.
Operation 22: An admitted soft delete MUST record deleted_by and the resolved deleted_at.
Operation 23: An admitted soft delete MUST record a supplied reason as deletion_reason.
Operation 24: An admitted restore MUST record restored_by and the resolved restored_at.
Operation 25: An admitted restore MUST record a supplied reason as restoration_reason.
Operation 26: An admitted purge MUST record purged_by, reason as purge_reason and the resolved purged_at.
Operation 27: An admitted restore MUST replace the lifecycle record's restore fields.
Operation 28: An admitted purge MUST NOT change a restore field.
Operation 29: A transitioning action MUST commit the state change and the recorded fields in one operation.
Operation 30: IF the store refuses the write THEN a transitioning action MUST answer storage-failure.
Operation 31: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 32: A refused action MUST leave the lifecycle record as the call found the lifecycle record.
Operation 33: A refused [Soft Delete] MUST NOT record a lifecycle record.
Operation 34: An admitted read MUST answer the matching lifecycle records in latest transition instant descending order.
Operation 35: An admitted read MUST order two lifecycle records sharing a latest transition instant by record_id ascending.
Operation 36: An admitted read MUST answer EVERY lifecycle record matching the supplied filters.
Operation 37: An admitted read MUST NOT answer a lifecycle record failing a supplied filter.
Operation 38: An admitted read MUST NOT answer a host record carrying no lifecycle record.
Operation 39: IF no lifecycle record matches THEN an admitted read MUST answer an empty record sequence.
Operation 40: An admitted read MUST match an instant-range filter against ONLY the lifecycle records carrying the filter's field.
Operation 41: IF a filter's axis NOT EXISTS in the filter axes THEN [Read] MUST answer invalid-query.
Operation 42: IF a reference filter's value NOT EXISTS THEN [Read] MUST answer invalid-query.
Operation 43: IF a state filter's value NOT EXISTS in the states THEN [Read] MUST answer invalid-query.
Operation 44: IF a range filter's end precedes the range's start THEN [Read] MUST answer invalid-query.
Operation 45: [Read] MUST NOT write.
Deleted: Operation 46. Capability requirement 1 owns it.
Deleted: Operation 47. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 48. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 49. `execution-contract.md` §Logic confinement owns it.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Term states: `active` | `deleted` | `purged` — a [State], and the whole state space a tracked record may stand in.

Term transitioning action: [Soft Delete] | [Restore] | [Purge] — the three actions that move a lifecycle record.

Term acting reference: `deleted_by` on [Soft Delete], `restored_by` on [Restore], and `purged_by` on [Purge] — the actor reference a transitioning action carries.

Term transition instant: `deleted_at` on [Soft Delete], `restored_at` on [Restore], and `purged_at` on [Purge] — the instant a transitioning action records.

Term resolved transition instant: the transition instant the lifecycle record carries — the supplied value where one exists, and `now` otherwise.

Term state rejection: `already-deleted`, `already-purged` OR `not-deleted` — every refusal that rests on the lifecycle record's state.

Term deletion field: `deleted_by`, `deleted_at` OR `deletion_reason` — the fields [Soft Delete] sets.

Term restore field: `restored_by`, `restored_at` OR `restoration_reason` — the fields [Restore] sets.

Term purge field: `purged_by`, `purged_at` OR `purge_reason` — the fields [Purge] sets.

Term deletion epoch: the span from one admitted soft delete to the lifecycle record's next admitted soft delete; the deletion fields carry one epoch's attribution and no more.

Term latest transition instant: the most recent of a lifecycle record's `deleted_at`, `restored_at` and `purged_at`.

Term filter axes: `record_id` | `deleted_by` | `purged_by` | `state` | `deleted_at` | `restored_at` | `purged_at` — the seven axes [Read] accepts, and no others.

Term admitted soft delete: a [Soft Delete] call whose record_id and deleted_by exist, whose lifecycle record stands outside deleted and purged, and whose resolved deleted_at the guards admit.

Term admitted restore: a [Restore] call whose record_id names a lifecycle record standing in deleted, and whose restored_by and resolved restored_at the guards admit.

Term admitted purge: a [Purge] call whose record_id names a lifecycle record standing in deleted, and whose purged_by, reason and resolved purged_at the guards admit.

Term admitted read: a [Read] call whose every filter axis and filter value the guards admit.

| # | Condition | a transitioning action answers |
|---|---|---|
| 1 | record_id is blank | `invalid-request` |
| 2 | [Restore] or [Purge], record_id names no lifecycle record | `not-known` |
| 3 | the lifecycle record's state refuses the action | a state rejection |
| 4 | the state admits the action, an attribution or temporal check fails | `invalid-request` |
| 5 | every precondition passes, the store refuses the write | `storage-failure` |
| 6 | every precondition passes, the store accepts the write | the success token |

NOTE: watch condition negation — `invalid-request` occupies rows 1 and 4 of one precedence chain, so the answer alone does not say which guard refused. [Approval Step](./approval-step.md), [State Machine](./state-machine.md) and [Audit Trail](../compositions/audit-trail.md) carry the same shape.

WHY:
Row 2 is where this atom differs from every sibling and the difference is deliberate. [Soft Delete] never answers `not-known` (Operation 6), because an unknown `record_id` is not an error there — it is the entry point. The first [Soft Delete] on a `record_id` creates the lifecycle record and stands it in deleted in one step, which is why there is no registration action to call first (Operation 7, Operation 8). [Restore] and [Purge] do answer `not-known`, because both are operations on a lifecycle the atom must already be tracking.

Operation 17 and Operation 18 state the within-record temporal bounds as precedences rather than as comparisons, so no rule here spells `≥` as a two-arm disjunction. A restore or a purge recorded *at* the deletion instant is legal, and `precedes` admits it in one arm.

Operation 38 is the scope rule an auditor must read before trusting an empty answer. This store holds lifecycle records, not host records, so a host record that has never been soft-deleted is not *absent from the results* — it is outside the atom entirely, in no state, with nothing here to return. An empty answer to a `record_id` query means *never deleted*, not *not found*.

### Invariants

- **Invariant 1 — Deletion attribution is immutable within a deletion epoch.**
  ```
  Invariant 1.1: An admitted restore MUST NOT change a deletion field.
  Invariant 1.2: An admitted purge MUST NOT change a deletion field.
  Invariant 1.3: An admitted soft delete MUST replace EVERY deletion field.
  ```
  WHY: the epoch is the unit of immutability, not the record. A restore and a purge leave the deletion attribution exactly as they found it; a second soft delete replaces all three fields together, and the prior epoch's attribution is gone from this store. The full cycle history is [Event Log](./event-log.md)'s (Non-goal 5), and the reason the atom keeps only the latest is that a summary the reader can trust beats a history the reader has to reconstruct — the summary answers *who deleted this, and when* without ambiguity about which deletion is meant.
- **Invariant 2 — Membership exclusivity.**
  ```
  Invariant 2.1: EVERY tracked record MUST stand in EXACTLY ONE OF active, deleted, purged.
  ```
- **Invariant 3 — Purge is terminal.**
  ```
  Invariant 3.1: A lifecycle record standing in purged MUST NOT leave purged.
  ```
- **Invariant 4 — Purge requires a prior deletion.**
  ```
  Invariant 4.1: EVERY purged lifecycle record MUST carry a deleted_by and a deleted_at.
  Invariant 4.2: A purged lifecycle record's deleted_by MUST carry a non-whitespace character.
  ```
  WHY: there is no direct path from active to purged (State 4), so every purged record passed through deleted and carries that step's attribution as evidence. The two-step shape is the atom's deliberate friction: the first step hides the record and is reversible, the second destroys it and is not, and separating them creates a moment where the decision can be reconsidered.
- **Invariant 5 — Purge attribution is complete.**
  ```
  Invariant 5.1: EVERY purged lifecycle record's purged_by MUST carry a non-whitespace character.
  Invariant 5.2: EVERY purged lifecycle record's purge_reason MUST carry a non-whitespace character.
  Invariant 5.3: EVERY purged lifecycle record MUST carry a purged_at.
  ```
  WHY: the load-bearing one. An anonymous purge, a whitespace-only reason or a missing instant each defeat the record that legal proceedings, regulatory inspections and GDPR compliance demonstrations require. A reason is mandatory on purge and optional on deletion because destruction is the act that must justify itself.
- **Invariant 6 — Temporal ordering within a transition.**
  ```
  Invariant 6.1: A purged lifecycle record's purged_at MUST NOT precede the record's deleted_at.
  Invariant 6.2: A recorded restored_at MUST NOT precede the deleted_at the restore found.
  Invariant 6.3: The atom MUST NOT order two deletion epochs from the stored fields.
  ```
  WHY: Invariant 6.3 is an honest limit rather than a gap. After a soft delete following a restore, `deleted_at` is replaced and the stored `restored_at` from the prior cycle then precedes it — which looks inverted and is correct, because the two fields describe different epochs. The stored fields bound each transition against the deletion current *at that moment*, and cross-epoch ordering is recoverable only from a composed [Event Log](./event-log.md).
- **Invariant 7 — Lifecycle record durability.**
  ```
  Invariant 7.1: The atom MUST NOT remove a lifecycle record from the store.
  Invariant 7.2: A storage-failure rejection MUST leave no partial record in the store.
  ```
- **Invariant 8 — Deletion attribution is complete.**
  ```
  Invariant 8.1: EVERY lifecycle record's deleted_by MUST carry a non-whitespace character.
  Invariant 8.2: EVERY lifecycle record MUST carry a deleted_at.
  ```

---

## Examples

### Delete, restore, delete, purge

A user deletes a post: `soft_delete(record_id: "post-8821", deleted_by: "user-4491", reason: "User-initiated delete")` → `deleted`. No lifecycle record existed, so this call created one and stood it in deleted — no registration step (Operation 7, Operation 8). The platform hides the post.

The user reconsiders within the undo window: `restore("post-8821", restored_by: "user-4491", reason: "User-initiated restore — undo")` → `restored`. The record stands in active, carrying both the restore fields and the deletion fields the restore found (Invariant 1.1).

The user deletes it again. The deletion fields are replaced with the new epoch's attribution and the restore fields stand as they were (Invariant 1.3, Operation 27). Ninety days later the retention service purges it: `purge("post-8821", purged_by: "retention_service", reason: "90-day deleted-record purge policy")` → `purged`. The host destroys the content; the lifecycle record stays as the evidence (State 11).

A support agent asks whether it can be recovered: `restore("post-8821", …)` → `already-purged` (Operation 11). What they *can* see is the whole lifecycle — the latest deletion, the restore, and the purge with its actor and reason.

### GDPR Article 17 erasure

A data subject submits an erasure request. The DSAR workflow calls `soft_delete("profile-4491", deleted_by: "dsar_service", reason: "GDPR Art. 17 erasure request — ticket DSR-2026-0441")` → `deleted`, then — having confirmed no live hold blocks it, which is the composing layer's check and not this atom's — `purge("profile-4491", purged_by: "dsar_service", reason: "GDPR Art. 17 erasure confirmed — no blocking hold — ticket DSR-2026-0441")` → `purged`. The lifecycle record proves the erasure was performed, attributed and documented (Non-goal 8).

### Rejection paths

`purge("doc-77", purged_by: "admin", reason: "cleanup")` where `doc-77` has never been deleted → `not-known`. There is no lifecycle record to purge, and [Purge] does not create one (Operation 5).

`purge("post-8821", …)` against the restored, active record → `not-deleted`. A record must be deleted before it can be destroyed; there is no direct path (Operation 13, State 4).

`soft_delete("post-8821", deleted_by: "user-4491")` against the already-deleted record → `already-deleted`, not a silent success (Operation 9, Non-goal 1).

`purge("post-8821", purged_by: "retention_service", reason: "   ")` → `invalid-request`. A destruction with no stated reason is not an audit record (Operation 3, Invariant 5.2).

`soft_delete("post-8821", deleted_by: "svc", deleted_at: "2030-01-01")` → `invalid-request` (Operation 16).

`restore("post-8821", restored_by: "svc", restored_at: "2020-01-01")` against a record deleted in 2026 → `invalid-request`. A restore cannot precede the deletion it undoes (Operation 17).

`read({record_id: "post-8821", deleted_reason: "spam"})` → `invalid-query`. The key stands outside the seven axes and is refused rather than ignored (Operation 41).

### Regulated adversarial scenarios

- **Regulator audit.** A GDPR supervisory authority asks for evidence that a data subject's erasure was completed. `read({record_id: "profile-4491"})` answers a purged lifecycle record with its actor, reason and instant, plus the deletion attribution from the step before. Invariant 5 and Invariant 7 together are the structural guarantee — the record exists, is fully attributed, and cannot have been removed after the fact. The same query answers HIPAA disposal audits and SOX (Sarbanes-Oxley Act) §802 records-management reviews.
- **Disputed erasure.** A data subject claims their profile was never erased, or erased without their request. The purged record names who deleted and why, and who purged and why, and Invariant 4 establishes the two-step chain. If the record still stands in deleted, the compliance team has evidence the erasure was *not* completed and a remediation path — which is a more useful answer than an absence would be.
- **Breach investigation.** An incident responder asks which records were purged inside an anomaly window: `read({state: purged, purged_at: {after: …, before: …}})`. Every result carries its actor, and an actor outside the authorized set is a finding on sight. Invariant 7.1 is why the query can be trusted — a purge performed during the window cannot be erased from this store afterwards.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the lifecycle store alone, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```
Check 1.1: An auditor MUST find no lifecycle record absent from a later read (Invariant 7.1).
Check 1.2: An auditor MUST find a purged lifecycle record in the store (Invariant 7.1, State 11).
Check 2.1: An auditor MUST find a non-whitespace character in EVERY purged lifecycle record's purged_by (Invariant 5.1).
Check 2.2: An auditor MUST find a non-whitespace character in EVERY purged lifecycle record's purge_reason (Invariant 5.2).
Check 2.3: An auditor MUST find a purged_at on EVERY purged lifecycle record (Invariant 5.3).
Check 2.4: An auditor MUST find no purged lifecycle record's purged_at preceding the record's deleted_at (Invariant 6.1).
Check 3.1: An auditor MUST find a deleted_by and a deleted_at on EVERY purged lifecycle record (Invariant 4.1).
Check 3.2: An auditor MUST find a non-whitespace character in EVERY purged lifecycle record's deleted_by (Invariant 4.2).
Check 4.1: An auditor MUST find EVERY tracked record standing in EXACTLY ONE OF active, deleted, purged (Invariant 2.1).
Check 4.2: An auditor MUST find no lifecycle record standing outside purged on a later read of a record a prior read found purged (Invariant 3.1).
Check 5.1: An auditor MUST find a non-whitespace character in EVERY lifecycle record's deleted_by (Invariant 8.1).
Check 5.2: An auditor MUST find a deleted_at on EVERY lifecycle record (Invariant 8.2).
Check 5.3: An auditor MUST find a re-read lifecycle record's deletion fields unchanged across an admitted restore (Invariant 1.1).
Check 5.4: An auditor MUST find a re-read lifecycle record's deletion fields unchanged across an admitted purge (Invariant 1.2).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: A deployment needing the host record's content confirmed destroyed MUST read the host system (Identity 11, Non-goal 3).
External check 2: A deployment needing two deletion epochs ordered MUST read the composing [Event Log](./event-log.md) (Invariant 6.3).
External check 3: A deployment needing a purge's eligibility confirmed MUST read the composing gate (Non-goal 8).
External check 4: A deployment needing an acting reference bound to an actor MUST read the composing [Actor Identity](./actor-identity.md) attestation (Non-goal 12).
```

WHY:
External check 1 is the atom's sharpest boundary and the one a deployment can quietly fail. A purged lifecycle record attests that a purge was *recorded*; the content lives in the host system, and a deployment that stands the record in purged without destroying the content conforms to every invariant here and defeats the whole point. The atom cannot see the content and so cannot check it, which is exactly why this is stated rather than assumed.

External check 2 follows from Invariant 6.3. The stored fields carry one deletion epoch and one restore epoch, so an auditor reconstructing *what happened in what order across cycles* needs the transition history, not this summary.

## Non-goals

```
Non-goal 1: The atom MUST NOT answer a second [Soft Delete] against a deleted lifecycle record as a success.
Non-goal 2: A deployment needing an idempotent delete MUST read already-deleted as a success.
Non-goal 3: The atom MUST NOT destroy the host record's content.
Non-goal 4: The atom MUST NOT confirm that the host record's content stands destroyed.
Non-goal 5: The atom MUST NOT retain a prior deletion epoch's attribution.
Non-goal 6: A deployment needing the full cycle history MUST compose [Event Log](./event-log.md).
Non-goal 7: The atom MUST NOT gate a purge on the purge's eligibility.
Non-goal 8: A deployment needing a purge gated MUST compose [Defensible Retention](../compositions/defensible-retention.md).
Non-goal 9: The atom MUST NOT read a live hold.
Non-goal 10: The atom MUST NOT read a retention deadline.
Non-goal 11: The atom MUST NOT offer a batch transitioning action.
Non-goal 12: The atom MUST NOT bind an acting reference to an actor.
Non-goal 13: A deployment needing a non-repudiable purge MUST compose [Actor Identity](./actor-identity.md).
Non-goal 14: The atom MUST NOT decide who may call an action.
Non-goal 15: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 16: The atom MUST NOT detect a rewrite under the store.
Non-goal 17: A deployment needing a rewrite detected MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 18: The atom MUST NOT define which read surface a deleted record leaves.
Non-goal 19: The atom MUST NOT bound a transition instant from below by anything beside the lifecycle record's own deleted_at.
Non-goal 20: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 7 through 10 are the boundary that most looks like a safety hole and is the atom's central factoring decision. This atom will execute a purge whenever it is called and well-formed. It does not read a hold, does not read a retention deadline, and does not ask whether GDPR Article 17(3)(e) — which suspends the right to erasure where processing is necessary for legal claims — applies to this record right now. Building any of that in would make the destruction primitive depend on the two patterns most often composed with it, and would put the gate inside the thing being gated. [Defensible Retention](../compositions/defensible-retention.md) wires the hold-blocks-purge check; [Forensic Recovery](../compositions/forensic-recovery.md) supplies the attributed, sealed, fully-recoverable destruction audit surface and deliberately does *not* gate eligibility. A deployment calling [Purge] without checking is operationally non-conforming and syntactically valid, and the spec says so rather than pretending the atom could tell.

Non-goal 18 is the deliberate silence the Intent names. *Hidden from normal query* is a deployment's decision about its own read surfaces, and two correct deployments disagree about it — a moderator queue that shows deleted posts and a clinical summary that does not are both implementing the deleted state faithfully.

Non-goal 1 is worth stating because the alternative is tempting. A second [Soft Delete] on a deleted record answers `already-deleted` rather than succeeding silently, because a repeat call is more often a bug or a retry than a fresh intent, and a caller who wants idempotence can read the answer as one (Non-goal 2) while a caller who has a bug finds it.

---

## Edge cases

### Atomic writes

```
Atomic writes 1: A reader MUST NOT observe a state change without the transition's recorded fields.
Atomic writes 2: An uncommitted crash MUST leave the lifecycle record as the call found the lifecycle record.
Atomic writes 3: The implementation MUST resolve a dangling transition.
Atomic writes 4: The store MUST NOT serve a read BEFORE the implementation resolves the dangling transition.
```

Term uncommitted crash: a crash BEFORE a transitioning action's commit lands.

Term dangling transition: a transitioning action's mutations standing partly applied once a crash has landed; the implementation resolves one by completing the mutations OR rolling the mutations back.

WHY:
Every transitioning action writes the state and its fields together (Operation 29), and a crash between them produces a purged record with no purge reason — Invariant 5 violated in exactly the way an auditor cannot tell from an implementation that never wrote one. The obligation is all-or-none observability.

### Concurrency

```
Concurrency 1: The implementation MUST serialize two transitioning actions against one lifecycle record.
Concurrency 2: A serialized transitioning action MUST read the state the prior transitioning action left.
Concurrency 3: The second serialized [Soft Delete] against one lifecycle record MUST answer already-deleted.
Concurrency 4: The second serialized [Restore] against one lifecycle record MUST answer not-deleted.
Concurrency 5: The second serialized [Purge] against one lifecycle record MUST answer not-deleted.
```

WHY:
Concurrency 5 reads oddly and is right: a second purge answers `not-deleted` rather than `already-purged`, because the guard tests *standing in deleted* (Operation 13) and a purged record does not. The answer names what the guard checked rather than what the caller probably wanted to hear, and a caller who needs to distinguish *already destroyed* from *never deleted* reads the record's state.

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The atom MUST read an absent string input as blank.
String 7: The deployment MUST canonicalize an opaque reference.
```

Term string input: a reference, `reason` OR a filter's value — every caller-supplied string this atom accepts.

Term blank: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Byte-exactness costs more here than in most atoms, because `record_id` is the *caller's* identifier rather than one this atom issued (Identity 2). A host that supplies `Post-8821` on delete and `post-8821` on purge has two lifecycle records, and the purge answers `not-known` on a record that visibly exists. Canonicalization is the deployment's (String 7, Identity 9).

NOTE: watch host obligations — this atom sets no maximum length on a string input, where [Duplicate Prevention](./duplicate-prevention.md) declares a cap and [Provenance](./provenance.md) obliges the deployment to set one. Three postures, and the *host obligations* docket row carries the count — a watch flag states the pressure, never a census nothing reads.

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the purge eligibility gate.
Composition note 3: A composing pattern MUST own the authorization of a call.
Composition note 4: A composing pattern MUST own the attestation binding an acting reference.
Composition note 5: A composing pattern MUST own the full cycle history.
Composition note 6: A composing pattern MUST own the tamper seal over the lifecycle store.
Composition note 7: A composing pattern MUST own a batch transition.
Composition note 8: A composing pattern MUST own the host record's content destruction.
Composition note 9: A composing pattern reading the lifecycle store MUST NOT write to the lifecycle store.
```

WHY:
[Forensic Recovery](../compositions/forensic-recovery.md) (`grounded` 2026-06-04) wires this atom onto an [Audit Trail](../compositions/audit-trail.md) substrate to produce the attributed, tamper-evident, fully recoverable destruction audit surface — every delete, restore and purge attributed and sealed, with the ordered lifecycle reconstructable rather than summarized (Composition note 5, Invariant 6.3). It deliberately does not gate purge eligibility. [Defensible Retention](../compositions/defensible-retention.md) is the composition that does, wiring [Legal Hold](./legal-hold.md) and [Retention Window](./retention-window.md) into the hold-blocks-purge check this atom refuses to make (Composition note 2, Non-goal 7 through 10).

[Event Log](./event-log.md) is the history behind the summary: this atom keeps the latest deletion and the latest restore, and the event log keeps every transition in order, which is the only place cross-epoch questions can be answered. [Actor Identity](./actor-identity.md) makes a purge non-repudiable, which regulated destruction needs and an opaque reference cannot supply. [Legal Hold](./legal-hold.md) and [Retention Window](./retention-window.md) are composing peers rather than constituents — one records the preservation obligation and the other the eligibility deadline, and neither is read here. [Permissions](./permissions.md) governs who may call what, and purge in particular is the action a deployment should restrict, because unrestricted destruction defeats the audit guarantee this atom exists to provide. [Duplicate Prevention](./duplicate-prevention.md) supplies idempotent delete semantics under retry (Non-goal 1, Non-goal 2).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the host system; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; a data subject; an investigator; the store; a lifecycle record; a tracked record; a host record; a purged lifecycle record; a deleted lifecycle record; a transitioning action; a refused action; an action; a query; a filter; a reference filter; a state filter; a range filter; an instant-range filter; a state rejection; a rejection; a crash; a reader; a deletion epoch; a string input; an opaque reference; the store instance's lifecycle record count.

Term records: `lifecycle record` — the state and attribution this atom holds for one host record, carrying `record_id`, a state, `deleted_by`, `deleted_at` and, where supplied or set, `deletion_reason`, `restored_by`, `restored_at`, `restoration_reason`, `purged_by`, `purged_at` and `purge_reason`.

Term record verbs: identify, allocate, change, carry, stand, answer, record, set, replace, leave, own, match, normalize, confirm, admit, offer, detect, route, share, precede, follow, exceed, compare, trim, case-fold, refuse, write, read, find, observe, resolve, complete, serve, serialize, commit, fall, bound, decide, declare, compose, wire, supply, remove, sort, order, name, bind, destroy, hold, gate, retain, define, canonicalize, register, untrack.

Term value sets: soft_delete answers deleted and refuses invalid-request | already-deleted | already-purged | storage-failure. restore answers restored and refuses invalid-request | not-known | not-deleted | already-purged | storage-failure. purge answers purged and refuses invalid-request | not-known | not-deleted | storage-failure. read answers the matching lifecycle records and refuses invalid-query. `state` = active | deleted | purged.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: `migrated` — rewritten in GRACE lang v0.40 (2026-09-13).

Term terms: `lifecycle record`, `record_id`, `tracked record`, `reference`, `store instance`, `seam`, `transition`, `now`, `business caller`, `states`, `transitioning action`, `acting reference`, `transition instant`, `resolved transition instant`, `state rejection`, `deletion field`, `restore field`, `purge field`, `deletion epoch`, `latest transition instant`, `filter axes`, `admitted soft delete`, `admitted restore`, `admitted purge`, `admitted read`, `string input`, `blank`, `uncommitted crash`, `dangling transition`.

#### Soft Delete

The behavior that marks a record as removed and hidden but recoverable — transitioning it to [Deleted] (creating the lifecycle record on the first call for a new [Record Id]) and recording [Deleted By], [Deleted At], and an optional [Deletion Reason]. Returns `deleted`, or a rejection ([Invalid Request], [Already Deleted], [Already Purged], [Storage Failure]).

Kind: Operation

#### Restore

The behavior that returns a [Deleted] record to [Active], recording [Restored By], [Restored At], and an optional [Restoration Reason]. Rejected for an unknown ([Not Known]), non-[Deleted] ([Not Deleted]), or [Purged] ([Already Purged]) record.

Kind: Operation

#### Purge

The behavior that permanently destroys a [Deleted] record's content and transitions it to terminal [Purged], recording [Purged By], a required [Purge Reason], and [Purged At]. The lifecycle record survives as audit evidence. Rejected for a non-[Deleted] record ([Not Deleted]).

Kind: Operation

#### Read

The read-only query returning lifecycle records — only for [Record Id]s that have undergone at least one [Soft Delete] — ordered by most-recent transition timestamp then [Record Id]. Filterable by [Record Id], [Deleted By], [Purged By], [State], or time ranges on [Deleted At] / [Restored At] / [Purged At]. Rejected [Invalid Query] for a malformed filter.

Kind: Operation

#### Record Id

The opaque identity of the record in the host system — supplied by the caller on [Soft Delete] (the atom accepts ids, never generates them), immutable once a lifecycle record exists (Invariant 7). Unique within a store instance.

Kind:     Field
Field of: the lifecycle record
Projects: record_id

#### State

The record's lifecycle state — [Active], [Deleted], or [Purged] (Invariant 2). Set on each transition; exactly one value at any time.

Kind:     Field
Field of: the lifecycle record
Projects: state

#### Deleted By

The opaque reference to the actor who performed the most recent deletion. Set on [Soft Delete], non-whitespace (Invariant 8), immutable within the deletion epoch (Invariant 1).

Kind:     Field
Field of: the lifecycle record
Projects: deleted_by

#### Deleted At

The timestamp of the most recent deletion. Set on [Soft Delete] (caller-supplied or wall-clock-defaulted; not in the future); immutable within the epoch. The lower bound for [Restored At] and [Purged At] (Invariant 6).

Kind:     Field
Field of: the lifecycle record
Projects: deleted_at

#### Deletion Reason

The optional stated reason for the most recent deletion — the [Reason] parameter of [Soft Delete], stored under this name. Immutable within the epoch.

Kind:     Field
Field of: the lifecycle record
Projects: deletion_reason

#### Restored By

The opaque reference to the actor who performed the most recent restore. Set on [Restore].

Kind:     Field
Field of: the lifecycle record
Projects: restored_by

#### Restored At

The timestamp of the most recent restore. Set on [Restore]; must be ≥ the then-current [Deleted At] (Invariant 6) and not in the future.

Kind:     Field
Field of: the lifecycle record
Projects: restored_at

#### Restoration Reason

The optional stated reason for the most recent restore — the [Reason] parameter of [Restore], stored under this name.

Kind:     Field
Field of: the lifecycle record
Projects: restoration_reason

#### Purged By

The opaque reference to the actor who authorized and performed the purge. Set on [Purge], non-whitespace (Invariant 5), immutable.

Kind:     Field
Field of: the lifecycle record
Projects: purged_by

#### Purged At

The timestamp of the purge. Set on [Purge]; must be ≥ [Deleted At] (Invariant 6) and not in the future.

Kind:     Field
Field of: the lifecycle record
Projects: purged_at

#### Purge Reason

The required stated reason for the purge — the [Reason] parameter of [Purge], stored under this name. Non-whitespace (Invariant 5), immutable. Unlike the deletion and restore reasons, purge's reason is mandatory.

Kind:     Field
Field of: the lifecycle record
Projects: purge_reason

#### Reason

The stated justification an action carries — optional on [Soft Delete] and [Restore], required on [Purge]. Consumed at the action and stored under the action-specific field name ([Deletion Reason], [Restoration Reason], or [Purge Reason]), not under this name.

Kind:         Parameter
Parameter of: Soft Delete, Restore, Purge
Projects:     reason

#### Active

The state of a tracked record in normal operation — reached only by a [Restore] from [Deleted] (a record never soft-deleted has no lifecycle record and is not in any atom state). May be soft-deleted again.

Kind:      Member
Member of: the lifecycle state
Role:      Outcome

#### Deleted

The state of a record marked as removed and hidden but retained and recoverable. Deletion fields are set and immutable within the epoch (Invariant 1). May be restored or purged.

Kind:      Member
Member of: the lifecycle state
Role:      Outcome

#### Purged

The terminal state of a record whose content has been permanently destroyed; the lifecycle record is retained as audit evidence (Invariant 7). Absorbing — no action transitions out of it (Invariant 3).

Kind:      Member
Member of: the lifecycle state
Role:      Outcome

#### Invalid Request

The rejection [Soft Delete], [Restore], or [Purge] returns for a malformed [Record Id], a missing or whitespace-only attribution field ([Deleted By] / [Restored By] / [Purged By]) or [Reason], or a future-dated or out-of-order timestamp.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-request

#### Already Deleted

The rejection [Soft Delete] returns when the target record is already in [Deleted] state (non-idempotent by design).

Kind:      Member
Member of: the Soft Delete rejection
Role:      Outcome
Projects:  already-deleted

#### Already Purged

The rejection [Soft Delete] or [Restore] returns when the target record is already [Purged] — a [Purged] record cannot be re-deleted or restored (Invariant 3).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  already-purged

#### Storage Failure

The rejection any write action returns when the store write fails after all preconditions pass; the record is left in its prior state (Invariant 7).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Not Known

The rejection [Restore] or [Purge] returns when the [Record Id] references no lifecycle record in the store.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Not Deleted

The rejection [Restore] or [Purge] returns when the record is [Active] — there is nothing to restore, and a [Purge] requires a prior [Deleted] state (Invariant 4).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-deleted

#### Invalid Query

The rejection [Read] returns for a malformed filter — a null or whitespace-only [Record Id], [Deleted By], or [Purged By]; a [State] outside the three values; a reversed time range; or an unrecognized filter key.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Soft Delete]: #soft-delete
[Restore]: #restore
[Purge]: #purge
[Read]: #read
[Record Id]: #record-id
[State]: #state
[Deleted By]: #deleted-by
[Deleted At]: #deleted-at
[Deletion Reason]: #deletion-reason
[Restored By]: #restored-by
[Restored At]: #restored-at
[Restoration Reason]: #restoration-reason
[Purged By]: #purged-by
[Purged At]: #purged-at
[Purge Reason]: #purge-reason
[Reason]: #reason
[Active]: #active
[Deleted]: #deleted
[Purged]: #purged
[Invalid Request]: #invalid-request
[Already Deleted]: #already-deleted
[Already Purged]: #already-purged
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Not Deleted]: #not-deleted
[Invalid Query]: #invalid-query

---

## Standards references

- **GDPR Article 17 (Right to erasure / Right to be forgotten)** — the data subject's right to request destruction of personal data. The [Purge] action is the implementation surface; the [Purged] lifecycle record is the compliance proof. Article 17(3) exceptions (legal claims, public interest, etc.) are handled at the composing layer — the atom records the purge; the composing workflow enforces eligibility.
- **GDPR Article 5(1)(e) (Storage limitation)** — personal data may not be kept in identifiable form longer than necessary. Soft Delete + Retention Window is the structural implementation: deletion marks the record for eventual destruction; the retention clock governs when purge becomes eligible.
- **HIPAA §164.310(d)(2)(i) (Disposal)** — covered entities must implement policies for the final disposition of electronic PHI (Protected Health Information — individually identifiable health data covered by HIPAA). The [Purge] action + [Purged] lifecycle record is the disposal audit surface.
- **HIPAA §164.312(b) (Audit controls)** — electronic information systems must record and examine activity. Every [Soft Delete], [Restore], and [Purge] event is an auditable action; composed with Audit Trail, the full destruction history is available for HIPAA audit.
- **Federal Rules of Civil Procedure (FRCP — the rules governing civil lawsuits in US federal courts) Rule 37(e)** — failure to preserve ESI (Electronically Stored Information — digital records subject to legal discovery) when litigation is reasonably anticipated can result in sanctions. A [Purge] executed while an Active Legal Hold covers the record is the spoliation event; the [Purged] lifecycle record is the evidence. The atom faithfully records the destruction; whether it was permissible is a legal question.
- **SOX §802 (18 U.S.C. §1519)** — criminal obstruction-of-justice provision for destruction of documents subject to federal investigation. Purge of a record under an Active Legal Hold is the §802 risk surface; the atom's records provide the audit trail.
- **ISO 15489-1 (Records management)** — the International Organization for Standardization's standard for records management. Soft Delete maps to ISO 15489's "suspension of disposition" ([Deleted] state); Purge maps to "authorized destruction." The two-step destruction path ([Soft Delete] then [Purge]) aligns with ISO 15489's requirement that destruction be deliberate and authorized.
- **NIST (National Institute of Standards and Technology — US federal standards body) SP 800-88 (Guidelines for Media Sanitization)** — purge-level destruction of storage media. The [Purge] action's attribution fields document who authorized the destruction; the implementation of the actual data destruction is handled at the media-sanitization layer and is outside this atom's scope.

---

## Status

`grounded on Final Critique 4 — 2026-05-20` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-05-20
formal: not applicable — vote no 2026-06-03
last gate: 2026-05-20 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/soft-delete.md`.

- **2026-09-13 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the four actions as a signature block, Invariant 1 through 8 keeping their numbers, every success effect conditioned on a declared `admitted soft delete`, `admitted restore`, `admitted purge` or `admitted read` (Hard invariant 16), the three transitioning actions unified under declared `transitioning action`, `acting reference` and `transition instant` terms so their shared guards are stated once rather than three times, the four per-action *rejection priority* lines collapsed to one six-row case space, `Generation acceptance` moved ahead of `Non-goals` to match the migrated corpus, the six acceptance areas opened into `Check 1.1 through 5.4` with four `External check`s, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 19` family and four edge-case families. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into soft-delete` found nothing citing this atom by label. 58.5 KB → 53.8 KB, the smallest reduction of the migration — this atom's prose was already dense, and most of what came out was the four repeated precedence lines.

- **2026-09-13 — The caller owns the identity, and the atom owns no content.** *Chose:* `Identity 2` and `Identity 3` — the caller supplies `record_id`, the atom never allocates one — with `Identity 11` stating that the host record's content is not held here. *Over:* the host-allocates-at-the-seam shape every other migrated atom carries. *Because:* this atom is a lifecycle overlay rather than a record store, so there is nothing for it to allocate an id *for*, and what a purge destroys is the host's content rather than anything in this store. The consequence is stated where it bites: `External check 1` — a deployment can stand a record in purged without destroying the content, conform to every invariant here, and defeat the atom's whole purpose, because the atom cannot see the content it is recording the destruction of.

- **2026-09-13 — Three propositions had two owners each.** *Chose:* `Invariant 1` owns the deletion-epoch semantics and three `Operation` rules that restated it are gone; `Invariant 2` owns membership exclusivity and the `State` family no longer restates it. *Over:* keeping each pair. *Because:* Authority 3, found by `W-duplicate-proposition`. The citation-aim audit then caught the consequence a checker cannot: an Examples citation pointed at deleted `Operation 29`, and after the renumber it resolved cleanly to a different rule about commit atomicity. Third atom running where the audit catches a silently repointed citation, and the second where a *deleted* rule's citation found a new home rather than dangling.

NOTE: End of Soft Delete.

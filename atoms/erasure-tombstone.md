---
title: Erasure Tombstone
parent: Atomic Concepts
has_toc: true
toc: true
---

# Erasure Tombstone

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Erasure Tombstone keeps the permanent record that one record was lawfully destroyed. When a pattern purges a record at the end of its retention, or erases it on a person's request, it records an erasure tombstone in the same transaction: which record (its id and the pattern it belonged to), when it was destroyed, under what authority (the kind — a retention purge or an erasure request — and a reference to the deciding record) and who carried it out. The erasure tombstone keeps none of the destroyed record's content, so it can be kept forever. Anything that still names the destroyed id — an index entry, a seal, a composing pattern's own records — finds, by [Read Tombstone], *destroyed at this instant under this authority* instead of *not found*. The atom does not delete anything itself, does not decide whether a destruction is lawful and does not weigh an erasure request against a retention obligation; those belong to the patterns that compose it.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Every pattern in the library that keeps records also, sooner or later, lets one go: a retention period ends, a person exercises a right to erasure, a hold is lifted and the purge it held back proceeds. The record leaves. What stays behind is everything that pointed at it — the index entry that named it, the seal whose coverage counted it, the binding a composition kept from it to something else. Without a record of the destruction, each of those reads a dangling id, and a dangling id means three different things a reader cannot tell apart: the record was lawfully destroyed, the record never existed, or the record was lost.

The compositions found this first. Nine of them carry facts they cannot derive from their constituents once a record is purged, and each classifies those facts as *extraction-pending against Erasure Tombstone* (the section titled Composition state in `execution-contract.md`): the debt was named before the atom existed. This atom is that extraction. It holds one record per destruction and nothing else, so a composition's purged half rests on a constituent instead of on records of its own.

Two disciplines carry the rest. The erasure tombstone holds no content of the destroyed record — only its id, its pattern, the instant, the authority and the actor — which is what lets the erasure tombstone outlive every retention that governed the record it names. And the atom never destroys anything: the destroying pattern deletes the record and calls [Record Destruction] in one transaction (Execution Contract Database 1), so a record is never gone without its erasure tombstone, and an erasure tombstone never stands for a record still kept.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify an erasure tombstone by the destroyed pattern and the destroyed id.
Identity 2: The atom MUST NOT interpret a destroyed id.
Identity 3: The atom MUST NOT interpret an authority reference.
Identity 4: The atom MUST NOT interpret an actor reference.
```

Term erasure tombstone: the record that one record was destroyed — the record this atom holds.

Term destroyed id: the opaque id the destroyed record carried in the destroyed pattern — a [Destroyed Id].

Term destroyed pattern: the name of the pattern the destroyed record belonged to — a [Destroyed Pattern].

Term authority reference: the opaque reference naming the record that authorized the destruction, such as a retention or an erasure request — an [Authority Reference].

Term actor reference: the opaque reference naming the actor or system identity that carried out the destruction — an [Actor Reference].

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading here.

### State

```
State 1: EVERY erasure tombstone MUST carry destroyed pattern, destroyed id, destruction instant, authority kind, authority reference and actor reference.
State 2: The atom MUST NOT offer a transition on an erasure tombstone.
State 3: The atom MUST NOT remove an erasure tombstone from the database.
State 4: An erasure tombstone MUST NOT carry a field of the destroyed record beside destroyed pattern and destroyed id.
```

Term authority kind: retention-purge | erasure-request | a deployment kind — the ground on which the record was destroyed; an [Authority Kind].

Term deployment kind: an authority kind the deployment declares beside retention-purge and erasure-request, such as a court order.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the erasure tombstone records PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1, Execution Contract Query 1, Execution Contract Query 3, Execution Contract Query 4 and Execution Contract Input 1.
Capability requirement 3: The deployment MAY declare a deployment kind.
Capability requirement 4: The deployment MUST NOT remove retention-purge from the authority kinds.
Capability requirement 5: The deployment MUST NOT remove erasure-request from the authority kinds.
Capability requirement 6: The deployment MAY override the reference cap.
Capability requirement 7: The deployment MAY override the pattern name cap.
Capability requirement 8: The deployment MAY override the page size.
Capability requirement 9: The deployment MAY override a bound ONLY IF the override EXCEEDS zero.
Capability requirement 10: The deployment MUST NOT remove a deployment kind from the authority kinds.
```

Term reference cap: 256 Unicode code points (Execution Contract Input 2) — the longest authority reference, destroyed id or actor reference an action accepts, unless the deployment overrides it.

Term pattern name cap: 128 Unicode code points (Execution Contract Input 2) — the longest destroyed pattern an action accepts, unless the deployment overrides it.

Term page size: 1,000 erasure tombstones — the most [List Destroyed] answers in one call, unless the deployment overrides it.

Term zero: the count of nothing — the floor an overriding bound must exceed.

### Operations

```
record_destruction(destroyed_pattern, destroyed_id, authority_kind, authority_ref, actor_ref)
  answers recorded
  refuses duplicate | invalid-request | storage-failure

read_tombstone(destroyed_pattern, destroyed_id)
  answers the erasure tombstone | none
  refuses invalid-request

list_destroyed(destroyed_pattern, window_start, window_end, optional continuation_key)
  answers the matching erasure tombstones
  refuses invalid-request
```

```
Operation 1: [Record Destruction] MUST record EXACTLY ONE erasure tombstone per successful call, carrying the call's destroyed pattern, destroyed id, authority kind, authority reference and actor reference.
Operation 2: [Record Destruction] MUST stamp destruction instant from the injected now.
Operation 3: [Record Destruction] MUST answer recorded.
Operation 4: IF an erasure tombstone EXISTS for the destroyed pattern and the destroyed id THEN [Record Destruction] MUST answer duplicate.
Operation 5: IF destroyed pattern EQUALS blank OR destroyed id EQUALS blank THEN [Record Destruction] MUST answer invalid-request.
Operation 6: IF authority reference EQUALS blank OR actor reference EQUALS blank THEN [Record Destruction] MUST answer invalid-request.
Operation 7: IF authority kind IS NOT IN the recognized kinds THEN [Record Destruction] MUST answer invalid-request.
Operation 8: IF destroyed pattern EXCEEDS the pattern name cap THEN [Record Destruction] MUST answer invalid-request.
Operation 9: IF destroyed id EXCEEDS the reference cap OR authority reference EXCEEDS the reference cap OR actor reference EXCEEDS the reference cap THEN [Record Destruction] MUST answer invalid-request.
Operation 10: IF the database refuses the write THEN [Record Destruction] MUST answer storage-failure.
Operation 11: [Record Destruction] MUST NOT read a record of the destroyed pattern.
Operation 12: [Read Tombstone] MUST answer the erasure tombstone the destroyed pattern and the destroyed id identify.
Operation 13: IF no erasure tombstone EXISTS for the destroyed pattern and the destroyed id THEN [Read Tombstone] MUST answer none.
Operation 14: IF destroyed pattern EQUALS blank OR destroyed id EQUALS blank OR destroyed pattern EXCEEDS the pattern name cap OR destroyed id EXCEEDS the reference cap THEN [Read Tombstone] MUST answer invalid-request.
Operation 15: [List Destroyed] MUST answer the matching erasure tombstones with the earliest listing keys, up to the page size.
Operation 16: [List Destroyed] MUST order the answer by destruction instant, then by destroyed id.
Deleted: Operation 17. Term matching erasure tombstone owns it.
Operation 18: IF window end PRECEDES window start THEN [List Destroyed] MUST answer invalid-request.
Operation 19: IF destroyed pattern EQUALS blank OR destroyed pattern EXCEEDS the pattern name cap THEN [List Destroyed] MUST answer invalid-request.
Operation 20: [Read Tombstone] MUST NOT write.
Operation 21: [List Destroyed] MUST NOT write.
Operation 22: The atom MUST NOT offer a change action.
Operation 23: The atom MUST NOT offer a removal action.
Operation 24: [List Destroyed] MUST NOT answer an erasure tombstone that is not a matching erasure tombstone.
Operation 25: IF window start EQUALS blank OR window end EQUALS blank THEN [List Destroyed] MUST answer invalid-request.
Operation 26: IF continuation key DOES NOT EQUAL blank AND the continuation key is malformed THEN [List Destroyed] MUST answer invalid-request.
Operation 27: IF window start is malformed OR window end is malformed THEN [List Destroyed] MUST answer invalid-request (Execution Contract Input 1).
```

NOTE: watch the listing page (Operation 15, Operation 24, Term matching erasure tombstone).

NOTE: watch the blank optional input (Term matching erasure tombstone).

NOTE: watch the untyped input (Operation 27, Term window start).

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it.

Term destruction instant: the clock reading the erasure tombstone was stamped from, the instant the destroying pattern states for the destruction (Non-goal 1) — a [Destruction Instant].

Term recognized kinds: retention-purge, erasure-request, and EVERY deployment kind the deployment declared.

Term window: the half-open span from window start to window end, window start included and window end excluded, in place of Execution Contract Query 2's closed range.

Term window start: the earliest destruction instant a [List Destroyed] call asks for — a [Window Start], malformed where it is not an instant.

Term window end: the instant the [List Destroyed] window closes — a [Window End], malformed where it is not an instant.

Term listing key: an erasure tombstone's destruction instant paired with its destroyed id, compared first by instant, then by id in code point order (Execution Contract Logic confinement 10) — the order [List Destroyed] answers in.

Term continuation key: the listing key of the last erasure tombstone a previous [List Destroyed] call answered — a [Continuation Key], malformed where it is not an instant paired with a destroyed id; what a caller passes to read the next page.

Term matching erasure tombstone: an erasure tombstone of the destroyed pattern whose destruction instant falls in the window, only where the listing key EXCEEDS the continuation key where continuation key DOES NOT EQUAL blank. Where none match the answer is empty.

Term none: the answer [Read Tombstone] gives where no erasure tombstone names the destroyed pattern and the destroyed id — never destroyed through this atom, which is not the same as never existing.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Record Destruction] | every field present, within its cap, a recognized kind, no erasure tombstone for the pair, database accepts | recorded | one erasure tombstone lands, destruction instant stamped from now (Operation 1, Operation 2, Operation 3) |
| [Record Destruction] | an erasure tombstone already names the pair | [Duplicate] | none (Operation 4) |
| [Record Destruction] | a blank field, a field over its cap, or a kind not recognized | [Invalid Request] | none (Operation 5 through 9), and the caller's delete is not made (Composition note 6) |
| [Record Destruction] | database refuses the write | [Storage Failure] | none, and the caller's delete in the same transaction rolls back with it (Operation 10, Execution Contract Constituent failure 1) |
| [Read Tombstone] | an erasure tombstone names the pair | the erasure tombstone | none (Operation 12) |
| [Read Tombstone] | no erasure tombstone names the pair | none | none (Operation 13) |
| [Read Tombstone] | a blank pattern or id, or a pattern or id over its cap | [Invalid Request] | none (Operation 14) |
| [List Destroyed] | a pattern, a window, an optional continuation key | the matching erasure tombstones with the earliest listing keys, up to the page size, in listing-key order; none where none match | none (Operation 15, Operation 16, Operation 24) |
| [List Destroyed] | a window that ends before the window starts, a blank or malformed window start or window end, a malformed continuation key, or a blank or over-long pattern | [Invalid Request] | none (Operation 18, Operation 19, Operation 25, Operation 26, Operation 27) |

### Invariants

- **Invariant 1 — An erasure tombstone never changes.**
  ```
  Invariant 1.1: A recorded erasure tombstone's fields MUST NOT change.
  Invariant 1.2: The atom MUST NOT remove a recorded erasure tombstone.
  ```
- **Invariant 2 — One erasure tombstone per destroyed record.**
  ```
  Invariant 2.1: Two erasure tombstones MUST NOT share a destroyed pattern and a destroyed id.
  Invariant 2.2: The database MUST refuse a write recording a second erasure tombstone for one destroyed pattern and one destroyed id.
  ```
- **Invariant 3 — No content of the destroyed record.**
  ```
  Invariant 3.1: An erasure tombstone MUST NOT carry a payload of the destroyed record.
  Invariant 3.2: The atom MUST NOT accept an input naming a field of the destroyed record beside destroyed pattern and destroyed id.
  ```
- **Invariant 4 — Every destruction carries its authority and its actor.**
  ```
  Invariant 4.1: The atom MUST NOT record an erasure tombstone whose authority kind IS NOT IN the recognized kinds.
  Invariant 4.2: EVERY erasure tombstone's authority reference MUST stand non-blank.
  Invariant 4.3: EVERY erasure tombstone's actor reference MUST stand non-blank.
  ```
- **Invariant 5 — Listing is deterministic.**
  ```
  Invariant 5.1: Two [List Destroyed] calls with one destroyed pattern, one window and one continuation key MUST answer one sequence of erasure tombstones over one database state.
  ```

Invariants 1 and 2 give *permanence*: an erasure tombstone, once recorded, reads the same forever, and a destroyed record has at most one. Invariant 3 gives *lawful permanence*: the erasure tombstone holds nothing of what was destroyed, which is why the erasure tombstone may outlive the retention of the record the erasure tombstone names. Invariant 4 gives *authority*: every destruction answers under what and by whom. Invariant 5 gives *rebuildability*: a seal or an index that lists the destroyed members of a range gets the same members in the same order every time.

---

## Examples

### A retention purge

A billing record `inv_8c21` in Event Log reaches the end of its seven-year retention. Defensible Retention, finding no hold, deletes the record and in the same transaction calls `record_destruction(destroyed_pattern: "event-log", destroyed_id: "inv_8c21", authority_kind: retention-purge, authority_ref: "ret_31f0", actor_ref: "svc_retention_r01")`, with the host injecting `now: 2033-03-02T04:00:00Z` → recorded. The erasure tombstone carries those five values and `destruction_instant: 2033-03-02T04:00:00Z`, and nothing of the billing record's content.

A year later an auditor's seal verification meets `inv_8c21` in the coverage of a seal made in 2027. `read_tombstone(destroyed_pattern: "event-log", destroyed_id: "inv_8c21")` → the erasure tombstone: destroyed on 2033-03-02 under retention `ret_31f0`. The seal's coverage reads one member lawfully removed, not one member missing.

### An erasure request

A person asks a clinic to erase their marketing preferences. The clinic's erasure pattern, having found no retention obligation in force, deletes the preference record `pref_19aa` and records `record_destruction(destroyed_pattern: "message-preference", destroyed_id: "pref_19aa", authority_kind: erasure-request, authority_ref: "req_e402", actor_ref: "svc_privacy_p01")` → recorded. The person's request `req_e402` is the authority; the erasure tombstone names it and holds nothing else of the person.

### Rejection paths

The retention service retries the purge of `inv_8c21` after a timeout it misread as a failure: `record_destruction(destroyed_pattern: "event-log", destroyed_id: "inv_8c21", ...)` → duplicate (Operation 4). The first call landed; the record stays destroyed once.

`record_destruction(destroyed_pattern: "event-log", destroyed_id: "inv_9d02", authority_kind: "cleanup", authority_ref: "ret_31f0", actor_ref: "svc_retention_r01")` → invalid-request: "cleanup" is no recognized kind (Operation 7).

`record_destruction(...)` whose write the database refuses → storage-failure, and the delete it rode with rolls back: the record is still there, and still under retention (Operation 10, Execution Contract Constituent failure 1).

`list_destroyed(destroyed_pattern: "event-log", window_start: 2033-04-01T00:00:00Z, window_end: 2033-03-01T00:00:00Z)` → invalid-request: the window ends before it starts (Operation 18).

### Regulated adversarial scenarios

- **Regulator audit — was this record destroyed or lost?** A regulator finds an index entry naming a transaction the database no longer holds. [Read Tombstone] answers the destruction instant, the retention that authorized it and the service that carried it out. An answer of none means the record left by no destruction this atom recorded, and that is itself the finding to investigate (Operation 13).
- **Rebuilding a seal's coverage.** An auditor rebuilding the coverage of a day's seal lists the destroyed members of that day with [List Destroyed], page by page, and gets the same members in the same order on every run, so two auditors reach one coverage (Invariant 5.1).
- **A person asks whether their record was erased.** A data subject disputes that their preference record went. [Read Tombstone] for the pair answers the destruction instant, the authority kind (an erasure-request) and the request that authorized it; an answer of none is no proof the record was never erased by another route (Operation 12, Operation 13, Non-goal 1).
- **A breach investigation.** After a breach, investigators ask which records left lawfully before it. [List Destroyed] over the breach window lists the matching erasure tombstones, earliest first, page by page, so a record gone with no erasure tombstone stands out from one destroyed with its authority recorded (Operation 15, Invariant 5.1).
- **An erasure that came back.** A backup is restored and a deleted record reappears. Its erasure tombstone still stands, naming when and why it was destroyed, so the restore's reconciliation finds the record that should not be there (Invariant 1.1).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the erasure tombstone records, with their committed versions (Execution Contract Generation acceptance 1).

### Conformance checks

```
Check 1.1: An auditor MUST find destroyed pattern, destroyed id, destruction instant, authority kind, authority reference and actor reference on EVERY erasure tombstone (State 1).
Check 1.2: An auditor MUST find one set of field values per erasure tombstone across the erasure tombstone's whole life (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 2.1: An auditor MUST find no two erasure tombstones sharing a destroyed pattern and a destroyed id (Invariant 2.1).
Check 3.1: An auditor MUST find no field on any erasure tombstone beside the six State 1 names (Invariant 3.1, State 4).
Check 4.1: An auditor MUST find no erasure tombstone whose authority kind IS NOT IN the recognized kinds (Invariant 4.1).
Deleted: Check 5.1. Execution Contract Database 6 owns it: a purge another specification declares is answered by that specification's records.
Check 6.1: An auditor MUST find destroyed pattern, destroyed id, authority reference and actor reference non-blank on EVERY erasure tombstone (Invariant 4.2, Invariant 4.3).
Check 7.1: An auditor MUST find two [List Destroyed] calls with one destroyed pattern, one window and one continuation key answering one sequence over one database state (Invariant 5.1).
```

NOTE: EVERY check names the rule the check tests.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: An auditor MUST read whether a destruction was lawful from the destroying pattern's records (Non-goal 3).
External check 2: An auditor MUST read whether the destroyed record left the database from the destroyed pattern's database (Non-goal 1).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT confirm a destroyed record left the database.
Non-goal 2: A deployment destroying a record MUST compose Defensible Retention.
Non-goal 3: The atom MUST NOT judge whether a destruction is lawful.
Non-goal 4: A deployment needing a lawful destruction MUST compose Defensible Retention.
Non-goal 5: The atom MUST NOT weigh an erasure request against a retention obligation.
Non-goal 6: A deployment facing an erasure request MUST compose Erasure Coordination.
Non-goal 7: The atom MUST NOT delete a record.
Non-goal 8: A deployment needing a storage-layer destruction MUST compose Shred.
Non-goal 9: The atom MUST NOT attest an actor reference.
Non-goal 10: A deployment needing an attested actor MUST compose Actor Identity.
Non-goal 11: The atom MUST NOT seal an erasure tombstone against modification.
Non-goal 12: A deployment needing court-admissible erasure tombstones MUST compose Tamper Evidence.
Non-goal 13: The atom MUST NOT purge an erasure tombstone.
```

NOTE: the owners — [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 1 through 4); Erasure Coordination *(forthcoming)* (Non-goal 5, Non-goal 6); Shred *(forthcoming)* (Non-goal 7, Non-goal 8); [Actor Identity](./actor-identity.md) (Non-goal 9, Non-goal 10); [Tamper Evidence](./tamper-evidence.md) (Non-goal 11, Non-goal 12); the atom's own permanence, Invariant 1.2 (Non-goal 13).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: [Record Destruction] MUST NOT accept a caller-supplied destruction instant.
```

### Concurrency

```
Concurrency 1: IF two [Record Destruction] calls name one destroyed pattern and one destroyed id THEN EXACTLY ONE call MUST answer recorded.
Concurrency 2: IF two [Record Destruction] calls name one destroyed pattern and one destroyed id THEN the other call MUST answer duplicate.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
```

## Composition notes

```
Composition note 1: A composing pattern MUST call [Record Destruction] in the transaction that removes the destroyed record (Execution Contract Database 1).
Composition note 2: A composing pattern MUST supply an opaque destroyed id.
Composition note 3: A composing pattern MUST NOT supply a destroyed id derived from a person's data.
Composition note 4: A composing pattern MUST own the authority reference's meaning.
Composition note 5: A composing pattern MUST call [Read Tombstone] for a destroyed id the destroyed pattern's database holds no record for.
Composition note 6: IF [Record Destruction] answers invalid-request OR [Record Destruction] answers storage-failure OR [Record Destruction] answers state-unavailable THEN a composing pattern MUST NOT remove the destroyed record.
Composition note 7: A composing pattern MUST own whether a duplicate answer permits removing the destroyed record.
```

NOTE: composing patterns — the nine compositions whose Composition state names an extraction-pending fact against this atom: [Audit Trail](../compositions/audit-trail.md), [Immutable Ledger](../compositions/immutable-ledger.md), [Reserve from Pool](../compositions/reserve-from-pool.md), [Propagate Consent Revocation Downstream](../compositions/propagate-consent-revocation-downstream.md), [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md), [Chain of Custody](../compositions/chain-of-custody.md), [Execute Gated Workflow](../compositions/execute-gated-workflow.md), [Capability-Backed Sharing](../compositions/capability-backed-sharing.md), [Multi-Party Approval](../compositions/multi-party-approval.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment; a composing pattern; a caller; a guard; an auditor; the database; an erasure tombstone; a write; an action; a call; a string input; an opaque reference; an override; a bound.

Term records: erasure tombstone — the record that one record was destroyed, carrying destroyed pattern, destroyed id, destruction instant, authority kind, authority reference and actor reference.

Term record verbs: identify, share, interpret, carry, offer, remove, supply, declare, override, record, stamp, answer, read, write, order, fall, change, refuse, accept, stand, call, own, confirm, judge, compose, weigh, delete, attest, seal, purge, compare, trim, normalize, case-fold, find.

Term value sets: authority kind = retention-purge | erasure-request | a deployment kind.

Term bounds: reference cap (the longest reference an action accepts); pattern name cap (the longest destroyed pattern an action accepts); page size (the most erasure tombstones [List Destroyed] answers in one call); zero (the floor an overriding bound must exceed).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-01) through the Grace connector.

Term terms: erasure tombstone, destroyed id, destroyed pattern, authority reference, actor reference, seam, authority kind, deployment kind, reference cap, pattern name cap, page size, zero, now, destruction instant, recognized kinds, window, window start, window end, listing key, continuation key, matching erasure tombstone, none, committed version.

#### Record Destruction

The behavior a destroying pattern invokes, in the transaction that removes a record, to record that the record was destroyed. It takes the [Destroyed Pattern], [Destroyed Id], [Authority Kind], [Authority Reference] and [Actor Reference], stamps [Destruction Instant] from the injected [Now], and answers recorded. It refuses [Duplicate] where an erasure tombstone already names the pair, [Invalid Request] for a blank, over-long or unrecognized input, and [Storage Failure] where the database refuses the write. It reads nothing of the destroyed pattern.

Kind: Operation

#### Read Tombstone

The behavior a reader invokes with a [Destroyed Pattern] and a [Destroyed Id] to learn whether the record was destroyed through this atom. It answers the erasure tombstone, or none. It only reads.

Kind: Operation

#### List Destroyed

The behavior an auditor or a rebuilding composition invokes to list the matching erasure tombstones of one [Destroyed Pattern] whose [Destruction Instant] falls in a window, the earliest listing keys first, at most a page at a time, continuing past a [Continuation Key]. It only reads.

Kind: Operation

#### Destroyed Id

The opaque id the destroyed record carried in its own pattern. Supplied by the destroying pattern, never interpreted, never changed.

Kind:       Field
Field of:   Erasure Tombstone
Projection: destroyed_id

#### Destroyed Pattern

The name of the pattern the destroyed record belonged to; with the [Destroyed Id], it identifies the erasure tombstone.

Kind:       Field
Field of:   Erasure Tombstone
Projection: destroyed_pattern

#### Destruction Instant

The instant [Record Destruction] was called, stamped from the injected [Now]: the instant the destroying pattern states for the destruction, which the atom does not confirm against the removal (Non-goal 1). Never changed.

Kind:       Field
Field of:   Erasure Tombstone
Projection: destruction_instant

#### Authority Kind

The ground on which the record was destroyed: [Retention Purge], [Erasure Request], or a kind the deployment declared.

Kind:       Field
Field of:   Erasure Tombstone
Projection: authority_kind

#### Authority Reference

The opaque reference to the record that authorized the destruction — a retention for a retention purge, an erasure request for an erasure. Never interpreted.

Kind:       Field
Field of:   Erasure Tombstone
Projection: authority_ref

#### Actor Reference

The opaque reference to the actor or system identity that carried out the destruction. Never interpreted.

Kind:       Field
Field of:   Erasure Tombstone
Projection: actor_ref

#### Now

The current clock reading [Record Destruction] consumes, injected at the seam, never a signature parameter. It stamps [Destruction Instant] and nothing else.

Kind:         Parameter
Parameter of: Record Destruction
Projection:   now

#### Window Start

The earliest [Destruction Instant] a [List Destroyed] call asks for, included in the window.

Kind:         Parameter
Parameter of: List Destroyed
Projection:   window_start

#### Window End

The instant the [List Destroyed] window closes, excluded from the window.

Kind:         Parameter
Parameter of: List Destroyed
Projection:   window_end

#### Continuation Key

The destruction instant and destroyed id of the last erasure tombstone a previous [List Destroyed] call answered; the next call answers only what comes past it. A blank continuation key starts at the earliest.

Kind:         Parameter
Parameter of: List Destroyed
Projection:   continuation_key

#### Retention Purge

The authority kind for a record destroyed because its retention ended. Every deployment recognizes it.

Kind:      Member
Member of: the authority kind
Role:      Outcome

#### Erasure Request

The authority kind for a record destroyed on a person's request to erase it. Every deployment recognizes it.

Kind:      Member
Member of: the authority kind
Role:      Outcome

#### Duplicate

The refusal [Record Destruction] answers where an erasure tombstone already names the destroyed pattern and destroyed id. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: duplicate

#### Invalid Request

The refusal an action answers for a blank input, an input over its cap, an unrecognized [Authority Kind], a window that ends before it starts, or a malformed window bound or continuation key. Nothing is written.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal [Record Destruction] answers where the database refuses its write. Nothing is written, and the destroying pattern's delete in the same transaction rolls back with it.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. -->

[Record Destruction]: #record-destruction
[Read Tombstone]: #read-tombstone
[List Destroyed]: #list-destroyed
[Destroyed Id]: #destroyed-id
[Destroyed Pattern]: #destroyed-pattern
[Destruction Instant]: #destruction-instant
[Authority Kind]: #authority-kind
[Authority Reference]: #authority-reference
[Actor Reference]: #actor-reference
[Now]: #now
[Window Start]: #window-start
[Window End]: #window-end
[Continuation Key]: #continuation-key
[Retention Purge]: #retention-purge
[Erasure Request]: #erasure-request
[Duplicate]: #duplicate
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure

## Standards references

- **GDPR (General Data Protection Regulation — the European Union's data-protection law) Article 17 (Right to erasure)** and **Article 5(2) (Accountability)** — a controller must erase on a valid request and be able to demonstrate compliance; the erasure tombstone is the demonstration that holds none of the erased data.
- **SEC (U.S. Securities and Exchange Commission) Rule 17a-4** and **HIPAA (Health Insurance Portability and Accountability Act) section 164.530(j)** — records kept for a set period and then lawfully disposed of; the erasure tombstone records the disposal and its authority.

Inherited from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture: one purpose, the record of a destruction, separate from the decision to destroy and from the act of destroying.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-11-02: no guard reads the clock, which only stamps the destruction instant, and the atom claims no commit order of its own; its permanence, one-record-per-destruction and no-content claims are single-state properties each action's rules hold, its listing order is a sort over stored fields, and its concurrency is Execution Contract Database 2's
last gate: 2026-11-02 — Final Critique 1, frozen at b703490 — foundational count 8, all cured, not clean, no sample

open:
- 2026-11-02-a · refining · Composition note 3; Identity 3, Identity 4 · a person-derived authority reference or actor reference is barred nowhere, though a destroyed id derived from a person's data is (Composition note 3), and no rule says whether an actor reference naming a person's own account is the person's data → decide whether Composition note 3 reaches the authority reference and the actor reference
- 2026-11-02-b · refining · State 1; Operation 5 through 9 · the atom declares no type for its string inputs beyond blank and cap, so a value of another type answers by Execution Contract Input 1 only through Operation 27 on the list's window → decide whether each [Record Destruction] input carries a declared type and a malformed refusal
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why.

- **2026-11-01 — Drafted as the extraction nine compositions name.** *Chose:* one record per destruction — destroyed pattern, destroyed id, destruction instant, authority kind and reference, actor — with no content of the destroyed record and no state, three actions (record, read one, list a window), the destroying pattern calling [Record Destruction] in the transaction that deletes, two authority kinds every deployment keeps and others it may add, and stated default caps a deployment may override. The record is named *erasure tombstone* in full, since GRACE-lang already calls a deleted rule's label a tombstone. *Over:* a tombstone that also deletes, judges lawfulness, or keeps any field of the destroyed record. *Because:* Scott's interview of 2026-11-01 and his ruling the same day that a host's bounds take a stated default a deployment may override; the atom carries exactly what the nine compositions' extraction-pending facts need, and nothing a deletion would have to forget.

</details>

NOTE: End of Erasure Tombstone.

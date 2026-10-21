---
title: Provenance
parent: Atomic Concepts
has_toc: true
toc: true
---

# Provenance

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Provenance answers one question: who has held this artifact, in what order, from intake to disposition. A chain opens with a genesis entry naming its first custodian and accumulates entries — transfers, transformations, disclosures — until it is archived. Each entry names a custodian; the chain is append-only; nothing is ever edited.

Order comes from a sequence number, not the clock. A skewed or dishonest clock degrades a timestamp and can change nothing else — which entries are accepted, how they replay, or who holds the artifact now.

The load-bearing rule is continuity: from genesis to archive the chain has exactly one current custodian, never none and never two. A transfer is hand-to-hand — the outgoing custodian is read from the chain's own state and never supplied by the caller, so a transferred entry cannot record a false hand-off.

This is the mechanism behind pharmaceutical chain of custody, legal evidence handling, forensic specimen tracking and regulated document lineage. It does not verify that a custodian is who they claim, decide who may call, or seal the chain against an adversary with write access.

---

## Intent

WHY:
A regulator's question about a controlled artifact is always the same shape: *prove nobody unaccounted-for held this*. Answering it needs a record where custody has no gaps by construction rather than by diligence — because a gap that can be created will be created, and the one place it must not be creatable is the record that exists to disprove it.

So the atom holds a chain per custody episode, and one rule carries the weight: exactly one current custodian at every point. There is no action that empties custody, none that admits two holders, and none but [Transfer] that moves it. A transfer reads the outgoing side from the chain's own state, so the from-field cannot be claimed — which is a stronger guarantee than checking a claim, because there is nothing to check.

[Event Log](./event-log.md) cannot express this, and the difference is why Provenance is its own concept rather than a configured stream. Event Log is content-agnostic, has no subject, no custodian, and permits sequence gaps by design. Continuity needs a subject and a holder and a dense sequence; a stream that allows a gap cannot prove there wasn't one.

Two disciplines carry the rest. **Order is the sequence number, never the clock** — the clock stamps an annotation and nothing reads it, so an adversarial clock cannot reorder a custody history. And **identity is the chain, never the artifact reference** — the same artifact may lawfully begin a second chain for a second episode, a returned batch or re-introduced exhibit, and identifying by artifact would merge two histories that must stay apart.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a chain by the chain id.
Identity 2: The atom MUST identify an entry by the entry id.
Identity 3: The host MUST allocate a chain id at the seam.
Identity 4: The host MUST allocate an entry id at the seam.
Identity 5: The transition MUST NOT allocate a chain id.
Identity 6: The transition MUST NOT allocate an entry id.
Identity 7: The atom MUST NOT change a chain id.
Identity 8: The atom MUST NOT change an entry id.
Identity 9: The atom MUST NOT identify a chain by the artifact reference.
Identity 10: The atom MUST admit a second chain carrying a recorded artifact reference.
Identity 11: The atom MUST match a custodian reference exactly.
Identity 12: The atom MUST NOT normalize a custodian reference.
Identity 13: The atom MUST NOT interpret an artifact reference.
Identity 14: The atom MUST NOT confirm that an artifact reference names a known artifact.
Identity 15: Two chains in one database instance MUST NOT share a chain id.
Identity 16: Two entries in one chain MUST NOT share an entry id.
Identity 17: The deployment MUST route EVERY call to one database instance.
```

Term chain: one artifact's custody history for one episode, from a genesis entry to a terminal disposition — the record this atom holds.

Term entry: one appended event on a chain, carrying an entry id, a sequence number, an event type, a custodian and a recording instant.

Term chain id: the opaque value naming one chain — a [Chain Id]; host-allocated at the seam.

Term artifact reference: the opaque reference naming what a chain tracks — an [Artifact Reference]; a property of the chain, never the chain's identity.

Term entry id: the opaque value naming one entry — an [Entry Id]; host-allocated at the seam.

Term custodian reference: the opaque reference naming who holds the artifact — a [Custodian Reference]; compared by exact byte identity.

Term database instance: one named database a call is routed to; chain id uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the chain id and the entry id here.

Term transition: the atom's evaluation of one call against the chain records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

```
State 1: EVERY chain MUST stand in EXACTLY ONE OF open, archived.
State 2: EVERY chain MUST carry chain id, artifact reference, a chain state, a current custodian and next sequence number.
State 3: EVERY entry MUST carry entry id, sequence number, event type and recording instant.
State 4: EVERY non-transferred entry MUST carry a custodian reference.
State 5: A transferred entry MUST NOT carry a custodian reference.
State 6: EVERY transferred entry MUST carry from custodian reference and to custodian reference.
State 7: EVERY transformed entry MUST carry a transformation descriptor.
State 8: EVERY disclosed entry MUST carry a recipient reference.
State 9: A genesis entry MAY carry metadata.
State 10: An entry MUST NOT carry a stored genesis type.
State 11: The atom MUST NOT offer a transition out of archived.
State 12: The atom MUST NOT offer an action that empties the current custodian.
State 13: The atom MUST NOT offer an action that stands two custodians current.
State 14: The atom MUST NOT offer an action beside [Transfer] that moves the current custodian.
State 15: The atom MUST NOT offer a removal surface.
State 16: The atom MUST NOT offer a reorder surface.
State 17: The atom MUST NOT offer an edit surface.
State 18: The entry chain MUST govern where the cached current custodian disagrees with a replay.
Deleted: State 19. Execution Contract Database 3 owns it.
```

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the chain records PER Execution Contract Database 1 through 4.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
```

### Operations

```
originate(artifact_ref, custodian_ref, genesis_type, metadata)
  answers chain_id
  refuses invalid-ref | invalid-genesis-type | storage-failure

transfer(chain_id, to_custodian_ref)
  answers entry_id
  refuses not-known | archived | invalid-ref | storage-failure

transform(chain_id, custodian_ref, transformation_descriptor)
  answers entry_id
  refuses not-known | archived | invalid-ref | invalid-descriptor | not-current-custodian | storage-failure

disclose(chain_id, custodian_ref, recipient_ref)
  answers entry_id
  refuses not-known | archived | invalid-ref | not-current-custodian | storage-failure

archive(chain_id, custodian_ref)
  answers entry_id
  refuses not-known | already-archived | invalid-ref | not-current-custodian | storage-failure

read(chain_id, query)
  answers entry_sequence
  refuses not-known | invalid-query
```

```
Operation 1: IF artifact reference EQUALS blank THEN [Originate] MUST answer invalid-ref.
Operation 2: IF custodian reference EQUALS blank THEN [Originate] MUST answer invalid-ref.
Operation 3: IF genesis type IS NOT IN the genesis types THEN [Originate] MUST answer invalid-genesis-type.
Operation 4: [Originate] MUST answer invalid-genesis-type ONLY IF artifact reference DOES NOT EQUAL blank AND custodian reference DOES NOT EQUAL blank.
Operation 5: An admitted originate MUST record EXACTLY ONE chain.
Operation 6: An admitted originate MUST append the genesis entry.
Operation 7: An admitted originate MUST set the genesis entry's event type to the call's genesis type.
Operation 8: An admitted originate MUST stand the chain in open.
Operation 9: An admitted originate MUST answer the chain id.
Operation 10: IF the chain id names no chain THEN an addressed action MUST answer not-known.
Operation 11: An addressed action MUST answer not-known ONLY IF the chain id names no chain.
Operation 12: IF the chain state EQUALS archived THEN [Transfer] MUST answer archived.
Operation 13: IF the chain state EQUALS archived THEN [Transform] MUST answer archived.
Operation 14: IF the chain state EQUALS archived THEN [Disclose] MUST answer archived.
Operation 15: IF the chain state EQUALS archived THEN [Archive] MUST answer already-archived.
Operation 16: A chain-state rejection MUST answer ONLY IF the chain id names a chain.
Operation 17: IF to custodian reference EQUALS blank THEN [Transfer] MUST answer invalid-ref.
Operation 18: [Transfer] MUST NOT accept a from custodian reference from the caller.
Operation 19: An admitted transfer MUST read from custodian reference from the current custodian.
Operation 20: An admitted transfer MUST append a transferred entry.
Operation 21: An admitted transfer MUST set the current custodian to to custodian reference.
Operation 22: [Transfer] MUST NOT guard a call on the caller's custodian reference.
Operation 23: IF custodian reference EQUALS blank THEN a custodian-guarded action MUST answer invalid-ref.
Operation 24: IF transformation descriptor EQUALS blank THEN [Transform] MUST answer invalid-descriptor.
Operation 25: IF recipient reference EQUALS blank THEN [Disclose] MUST answer invalid-ref.
Operation 26: IF custodian reference DOES NOT EQUAL the current custodian THEN a custodian-guarded action MUST answer not-current-custodian.
Operation 27: A custodian-guarded action MUST answer not-current-custodian ONLY IF EVERY supplied reference DOES NOT EQUAL blank.
Operation 28: An admitted transform MUST append a transformed entry.
Operation 29: An admitted disclose MUST append a disclosed entry.
Operation 30: An admitted archive MUST append an archived entry.
Operation 31: An admitted archive MUST stand the chain in archived.
Operation 32: An admitted archive MUST NOT change the current custodian.
Operation 33: An admitted transform MUST NOT change the current custodian.
Operation 34: An admitted disclose MUST NOT change the current custodian.
Operation 35: An admitted disclose MUST NOT change the artifact's custody.
Operation 36: An appending action MUST take the entry's sequence number from next sequence number.
Operation 37: An appending action MUST raise next sequence number by one.
Deleted: Operation 38. Execution Contract Database 1 owns it.
Operation 39: An appending action MUST answer the entry id.
Operation 40: An appending action MUST stamp recording instant from the injected now.
Operation 41: IF the database refuses the write THEN an appending action MUST answer storage-failure.
Operation 42: A refused action MUST leave the chain as the call found the chain.
Operation 43: A refused action MUST NOT append an entry.
Operation 44: A refused action MUST NOT take a sequence number.
Operation 45: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 46: [Read] MUST answer the chain's entries in sequence number ascending order.
Operation 47: [Read] MUST answer an empty entry sequence for a well-formed query no entry matches.
Operation 48: IF a query range's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
Operation 49: IF a query's event type IS NOT IN the event types THEN [Read] MUST answer invalid-query.
Operation 50: [Read] MUST NOT write.
Operation 51: [Read] MUST NOT answer storage-failure.
Operation 52: IF the database refuses a read THEN [Read] MUST NOT answer a partial entry sequence.
Operation 53: [Read] MUST NOT answer archived.
Deleted: Operation 54. Capability requirement 1 owns it.
Deleted: Operation 55. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 56. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 57. Clock dependence 2 owns it.
Operation 58: An ordering rule MUST NOT rest on recording instant.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term genesis type: the call input selecting a genesis entry's event type — a [Genesis Type]; an input name, never a stored field.

Term genesis types: originated | received — what a genesis entry's event type may be.

Term event type: originated | received | transferred | transformed | disclosed | archived — an [Event Type], set at append and never changed.

Term event types: the six members of event type, cited here from that declaration (Closed vocabulary 15).

Term chain state: open | archived — accepting entries, or at terminal disposition. A [Chain State].

Term current custodian: the to custodian reference of the chain's latest transferred entry, or the genesis entry's custodian reference where no transfer has landed — a [Current Custodian]; a projection of the entry chain, cached as chain state so a guard need not replay.

Term sequence number: the strictly increasing integer an entry takes at append — a [Sequence Number]; the chain's order source, and never taken from a clock.

Term next sequence number: the counter an appending action takes a sequence number from — a [Next Sequence Number]; begins at one and rises by one per append.

Term recording instant: the instant an entry was appended — a [Recording Instant]; a best-effort annotation, and never an order source.

Term addressed action: any action carrying a chain id — every action but [Originate].

Term custodian-guarded action: [Transform] | [Disclose] | [Archive] — the three an attribution guard covers.

Term appending action: [Originate] | [Transfer] | [Transform] | [Disclose] | [Archive] — every action but [Read].

Term chain-state rejection: the archived answer a writer gives against a closed chain, and the already-archived answer [Archive] gives.

Term admitted originate: an [Originate] call whose artifact reference, custodian reference and genesis type the guards all admit.

Term admitted transfer: a [Transfer] call whose chain id names an open chain and whose to custodian reference exists.

Term admitted transform: a [Transform] call whose chain id names an open chain, whose references and descriptor exist, and whose custodian reference matches the current custodian.

Term admitted disclose: a [Disclose] call whose chain id names an open chain, whose references exist, and whose custodian reference matches the current custodian.

Term admitted archive: an [Archive] call whose chain id names an open chain, whose custodian reference exists and matches the current custodian.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Originate] | refs present, genesis type admitted | the new chain id | a chain opens, genesis entry at sequence one (Operation 5 through 9) |
| [Originate] | a blank reference | [Invalid Reference] | none (Operation 1, Operation 2) |
| [Originate] | genesis type outside the two | [Invalid Genesis Type] | none (Operation 3, Operation 4) |
| [Transfer] | open chain, to custodian reference present | the entry id | transferred entry; the from-side read from state; custody moves (Operation 19 through 21) |
| [Transform] | open chain, refs present, custodian current | the entry id | transformed entry; custody unchanged (Operation 28, Operation 33) |
| [Disclose] | open chain, refs present, custodian current | the entry id | disclosed entry; custody unchanged (Operation 29, Operation 34) |
| [Archive] | open chain, custodian current | the entry id | archived entry; chain closes; custody unchanged (Operation 30 through 32) |
| any writer | chain is archived | [Archived] | none (Operation 12 through 14) |
| [Archive] | chain is archived | [Already Archived] | none (Operation 15) |
| custodian-guarded | custodian reference is not the current custodian | [Not Current Custodian] | none (Operation 26) |
| any addressed action | id names nothing | [Not Known] | none (Operation 10) |
| any appending action | database refuses | [Storage Failure] | none (Operation 41 through 44) |
| [Read] | a well-formed query, any chain state | the matching entries, oldest first | none (Operation 46, Operation 53) |
| [Read] | an inverted range, or an unknown event type | [Invalid Query] | none (Operation 48, Operation 49) |

### Invariants

- **Invariant 1 — Entry immutability.**
  ```
  Invariant 1.1: A recorded entry's fields MUST NOT change.
  ```
- **Invariant 2 — Append-only chain.**
  ```
  Invariant 2.1: A chain's entry count MUST NOT fall under the atom's actions.
  Invariant 2.2: A recorded entry's sequence number MUST NOT change.
  ```
- **Invariant 3 — Single origin.**
  ```
  Invariant 3.1: EVERY chain MUST carry EXACTLY ONE genesis entry.
  Invariant 3.2: A genesis entry's sequence number MUST stand at one.
  Invariant 3.3: The atom MUST NOT offer a second originate against a recorded chain.
  ```
- **Invariant 4 — Custody continuity.**
  ```
  Invariant 4.1: EVERY open chain MUST carry EXACTLY ONE current custodian.
  Invariant 4.2: EVERY custodian-guarded entry's custodian reference MUST equal the current custodian the entry found.
  Invariant 4.3: EVERY transferred entry's from custodian reference MUST equal the current custodian the entry found.
  Invariant 4.4: EVERY transferred entry's to custodian reference MUST stand as the current custodian the entry left.
  ```
- **Invariant 5 — Dense total order within a chain.**
  ```
  Invariant 5.1: Two entries in one chain MUST NOT share a sequence number.
  Invariant 5.2: A chain's sequence numbers MUST stand from one to the chain's entry count.
  Invariant 5.3: A chain's order MUST rest on sequence number alone.
  ```
- **Invariant 6 — Archived is terminal and absorbing.**
  ```
  Invariant 6.1: An archived chain MUST NOT leave archived.
  Invariant 6.2: An archived chain MUST NOT admit an entry.
  ```
- **Invariant 7 — Custodian presence.**
  ```
  Invariant 7.1: EVERY non-transferred entry's custodian reference MUST stand non-blank.
  Invariant 7.2: EVERY transferred entry's from custodian reference and to custodian reference MUST stand non-blank.
  ```
- **Invariant 8 — Event type validity.**
  ```
  Invariant 8.1: EVERY entry's event type MUST stand in the event types.
  Invariant 8.2: A genesis entry's event type MUST stand in the genesis types.
  Invariant 8.3: A non-genesis entry's event type MUST NOT stand in the genesis types.
  Invariant 8.4: An archived chain's last entry's event type MUST stand at archived.
  ```
- **Invariant 10 — Chain durability over this atom's own surface.**
  ```
  Deleted: Invariant 9. Identity 15 and Identity 16 own id uniqueness.
  Invariant 10.1: The chain count MUST NOT fall under the atom's actions.
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
  ```

---

## Examples

### Pharmaceutical — a batch from manufacture to dispensing

A manufacturer opens the chain: `originate(artifact_ref: "batch-x91", custodian_ref: "manuf-lab-7", genesis_type: originated)` → `chain-0041`. The genesis entry takes `sequence_number: 1` and the chain stands open with `manuf-lab-7` current (Operation 5 through 9).

`transfer("chain-0041", to_custodian_ref: "dist-region-3")` → `e2`. The entry records `from_custodian_ref: "manuf-lab-7"` — read from the current custodian, never from the caller (Operation 18, Operation 19). `transfer("chain-0041", "pharm-hosp-9")` → `e3`. The pharmacist records the dispense: `transform("chain-0041", "pharm-hosp-9", "dispensed 10mg dose into unit D44")` → `e4`, then closes it: `archive("chain-0041", "pharm-hosp-9")` → `e5`. The chain stands archived.

A regulator asks whether custody was unbroken. `read("chain-0041")` answers five entries in sequence order. Every transferred entry's from custodian reference equals the prior entry's to custodian reference, or the genesis custodian reference for the first transfer. Invariant 4 is the structural answer.

### Legal evidence — a physical exhibit

`originate(artifact_ref: "exhibit-A", custodian_ref: "det-r.james", genesis_type: originated)` → `chain-0107`. The exhibit moves to the evidence room (`e2`), then the lab (`e3`). The lab records its work: `transform("chain-0107", "forensic-lab-12", "fingerprint-lifted; DNA-sample-taken; original-exhibit-intact")` → `e4`. It returns to the evidence room (`e5`). The chain stands open pending trial.

Defense counsel claims an undocumented handler between the detective and the lab. `read("chain-0107")` answers five entries; no entry's from custodian reference names a party who was not the immediately prior to custodian reference, and every entry names a custodian (Invariant 4, Invariant 7). An unrecorded intermediary was never the current custodian, so no intermediary could have recorded a transformation or generated a transfer.

### Rejection paths

`transform("chain-0041", "manuf-lab-7", "added label update")` against the archived pharmaceutical chain → archived. The chain-state rejection precedes the attribution guard, so the caller learns the chain is closed rather than that they are not the custodian (Operation 13, Operation 16).

The same call against the chain while it stood open, after custody had moved to `pharm-hosp-9` → not-current-custodian (Operation 26).

`originate("sample-99", custodian_ref: "", genesis_type: originated)` → invalid-ref. No chain is recorded (Operation 2, Operation 43).

`originate("sample-77", "lab-2", genesis_type: imported)` → invalid-genesis-type. `imported` stands outside the genesis types (Operation 3).

`transform("chain-0107", "forensic-lab-12", "   ")` → invalid-descriptor. A whitespace-only descriptor EQUALS blank (Operation 24, String 5).

`archive("chain-0041", "pharm-hosp-9")` against the archived chain → already-archived — a distinct reason from the writer actions' archived, so a retrying archiver learns the work is done rather than refused (Operation 15).

`read("chain-9999")` → not-known (Operation 10).

`read("chain-0041", {sequence_range: [5, 2]})` → invalid-query. The caller corrects the query rather than reading an empty answer as *no entries matched* (Operation 47, Operation 48).

`transfer("chain-0107", "forensic-lab-12")` while the database's write path is down → storage-failure. Every precondition passed and the write did not; no entry is appended, no sequence number is taken, and the current custodian holds its prior value (Operation 41 through 45).

### Regulated adversarial scenarios

- **Regulator audit.** An FDA (US Food and Drug Administration) inspector asks for the complete chain of custody for `batch-x91` under 21 CFR (Code of Federal Regulations) Part 211. `read("chain-0041")` answers the ordered sequence; the inspector clears Check 1.1 through 7.2 provably, from those records.
- **Disputed transaction.** The defense rebuttal above rests on two invariants together: custody continuity, because from custodian reference is read from chain state and cannot be supplied (Invariant 4, Operation 18), and custodian presence, because no entry may name an empty custodian (Invariant 7).
- **Breach investigation.** An investigator brackets an anomaly window generously: `read("chain-0041", {recorded_at_range: ["2026-02-27", "2026-03-17"]})`. A wall-time filter is a convenience over a best-effort annotation and never an ordering claim (Operation 58), so the window's completeness is confirmed from an unfiltered read — the filtered window's first and last entries are located in the full sequence and their sequence-adjacent neighbours checked to fall outside the bracket. The sequence is dense (Invariant 5), so no entry lies between an entry and its sequence-adjacent neighbour and a clock-skewed entry cannot have been silently excluded. The custodian in force at any point is then exactly determined by replaying the preceding entries.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the chain records and the chain's entries.

### Conformance checks

```
Check 1.1: An auditor MUST find a custodian reference on EVERY non-transferred entry (Invariant 7.1).
Check 1.2: An auditor MUST find a from custodian reference and a to custodian reference on EVERY transferred entry (Invariant 7.2).
Check 2.1: An auditor MUST find EXACTLY ONE genesis entry per chain (Invariant 3.1).
Check 2.2: An auditor MUST find EVERY genesis entry standing at sequence number one (Invariant 3.2).
Check 3.1: An auditor MUST replay a chain in sequence number ascending order against a current custodian cursor (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY transferred entry's from custodian reference equal to the cursor the replay carried in (Invariant 4.3).
Check 3.3: An auditor MUST find EVERY custodian-guarded entry's custodian reference equal to the cursor at that entry (Invariant 4.2).
Check 4.1: An auditor MUST find a chain's sequence numbers standing from one to the chain's entry count (Invariant 5.2).
Check 4.2: An auditor MUST reconstruct a chain's order from sequence number alone (Invariant 5.3).
Check 5.1: An auditor MUST find no entry in an archived chain following the archived entry's sequence number (Invariant 6.2).
Check 6.1: An auditor MUST find a re-read entry's fields unchanged from the prior read (Invariant 1.1).
Check 7.1: An auditor MUST find EVERY entry whose event type IS IN the event types (Invariant 8.1).
Check 7.2: An auditor MUST find EVERY archived chain's last entry standing at archived (Invariant 8.4).
Check 7.3: An auditor MUST find no entry id repeated within a chain (Identity 16).
Check 7.4: An auditor MUST find no chain id repeated within a database instance (Identity 15).
```

NOTE: EVERY check names the rule the check tests.

## Non-goals

```
Non-goal 1: The atom MUST NOT confirm that a custodian reference names a credentialed party.
Non-goal 2: A deployment needing a non-repudiable custodian MUST compose Actor Identity.
Non-goal 3: The atom MUST NOT decide who may call an action.
Non-goal 4: A deployment needing an authorization decision MUST compose Permissions.
Non-goal 5: The atom MUST NOT record a disclosure's scope.
Non-goal 6: The atom MUST NOT record a disclosure's authority.
Non-goal 7: A deployment needing a disclosure's scope recorded MUST compose Selective Disclosure.
Non-goal 8: The atom MUST NOT claim a custody the chain's entries do not record.
Non-goal 9: The atom MUST NOT offer an amendment entry.
Non-goal 10: The atom MUST NOT offer a supersedes link between two entries.
Non-goal 11: The atom MUST NOT offer a view that resolves a correction.
Non-goal 12: The atom MUST NOT detect a rewrite under the database.
Non-goal 13: A deployment needing a rewrite detected MUST compose Tamper Evidence.
Non-goal 14: The atom MUST NOT bound a chain's retention.
Non-goal 15: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 16: The atom MUST NOT record a chain derived from a second chain.
Non-goal 17: The atom MUST NOT record two current custodians on one chain.
Non-goal 18: The atom MUST NOT interpret the artifact's medium.
Non-goal 19: The atom MUST NOT dispose of a chain.
Non-goal 20: A deployment needing a lawful disposal MUST compose Defensible Retention.
Non-goal 21: The atom MUST NOT offer a read keyed by artifact reference.
Non-goal 22: The atom MUST NOT offer a compare-and-swap arm on [Transfer].
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — [Actor Identity](./actor-identity.md) (Non-goal 1, Non-goal 2, Composition note 3); [Permissions](./permissions.md) (Non-goal 3, Non-goal 4); [Selective Disclosure](./selective-disclosure.md) (Non-goal 5 through 7, Composition note 6); a separate chain, or an external record the host links through the genesis metadata (Non-goal 8, State 9); [Tamper Evidence](./tamper-evidence.md) (Non-goal 12, Non-goal 13, Composition note 4); [Retention Window](./retention-window.md) (Non-goal 14, Non-goal 15, Composition note 5); a composing pattern (Non-goal 16, Composition note 7); [Retention Window](./retention-window.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 19, Non-goal 20); the host (Non-goal 21; Non-goal 22, Concurrency 4).

---

## Edge cases

### Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 owns it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 5. Execution Contract Database 1 owns it.
Deleted: Atomic writes 6. Execution Contract Database 1 owns it.
Deleted: Atomic writes 7. Execution Contract Database 1 owns it.
```

### Clock dependence

```
Clock dependence 1: A rejection MUST NOT rest on now.
Clock dependence 2: A guard MUST NOT read now.
```

### Clock semantics

```
Clock semantics 4: A guard MUST NOT rest on recording instant.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 5. Clock dependence 1 owns it.
Deleted: Clock semantics 6. Non-goal 23 owns it.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Concurrency 2: EVERY serialized transfer against one open chain MUST append.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Concurrency 4: A host needing a transfer conditional on the current custodian MUST serialize the host's own calls.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a reference EXCEEDS the maximum length THEN the action MUST answer invalid-ref.
String 8: IF transformation descriptor EXCEEDS the maximum length THEN [Transform] MUST answer invalid-descriptor.
String 9: IF metadata EXCEEDS the maximum length THEN [Originate] MUST answer invalid-ref.
```

Term string input: artifact reference, custodian reference, to custodian reference, recipient reference, transformation descriptor OR metadata — every caller-supplied string this atom accepts.

Term reference: artifact reference, custodian reference, to custodian reference OR recipient reference — every string input naming a party or an artifact.


Term maximum length: the deployment's cap per string input.

### Correction by append

```
Correction 1: The atom MUST NOT edit an entry.
Correction 2: The atom MUST NOT remove an entry.
Correction 3: The current custodian MUST record a correction as a subsequent entry.
Correction 4: A correcting entry MUST name the corrected entry's sequence number.
```

---

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the attestation binding a custodian reference to an actor.
Composition note 4: A composing pattern MUST own the tamper seal over the entry chain.
Composition note 5: A composing pattern MUST own the retention of the chain records.
Composition note 6: A composing pattern MUST own a disclosure's scope and authority.
Composition note 7: A composing pattern MUST own the relationship between two chains.
Composition note 8: A composing pattern reading the chain records MUST NOT write to the chain records.
```

NOTE: composing patterns — [Chain of Custody](../compositions/chain-of-custody.md).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; the database; a chain; an entry; a genesis entry; a transferred entry; a non-transferred entry; a transformed entry; a disclosed entry; an archived entry; a custodian-guarded entry; an addressed action; an appending action; a custodian-guarded action; a writer action; a refused action; an ordering rule; a query; a replay; a rejection; a correction; a string input; a reference; an opaque reference; the chain count; the entry count.

Term records: chain — one artifact's custody history for one episode, carrying chain id, artifact reference, a chain state, a current custodian and next sequence number. entry — one appended event on a chain, carrying entry id, sequence number, event type, custodian reference and recording instant, and the per-type fields from custodian reference, to custodian reference, transformation descriptor, recipient reference and metadata.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, read, take, raise, stamp, leave, own, match, normalize, interpret, confirm, admit, offer, govern, route, share, equal, precede, follow, exceed, compare, trim, case-fold, refuse, write, find, replay, reconstruct, repeat, complete, roll back, accept, serialize, name, claim, detect, bound, dispose, decide, compose, declare, wire, guard, rest, apply, supply, inject, fall, remove, edit, reorder, empty, move, cache, run.

Term value sets: event type = originated | received | transferred | transformed | disclosed | archived. genesis types = originated | received. chain state = open | archived.

Term bounds: maximum length (the deployment's cap per string input).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.39 (2026-09-12).

Term terms: chain, entry, chain id, artifact reference, entry id, custodian reference, database instance, seam, transition, now, business caller, genesis type, genesis types, event type, event types, chain state, current custodian, sequence number, next sequence number, recording instant, from custodian reference, to custodian reference, transformation descriptor, recipient reference, metadata, addressed action, custodian-guarded action, appending action, chain-state rejection, admitted originate, admitted transfer, admitted transform, admitted disclose, admitted archive, string input, reference, blank, maximum length.

#### Originate

The behavior that opens a new chain for an artifact: it writes the genesis entry (`sequence_number = 1`) with the selected [Genesis Type], records the [Artifact Reference], sets [Current Custodian] to the genesis [Custodian Reference], and returns a fresh [Chain Id]. Rejected for an empty reference ([Invalid Reference]), a bad [Genesis Type] ([Invalid Genesis Type]), or a failed write ([Storage Failure]).

Kind: Operation

#### Transfer

The behavior that records a hand-to-hand change of custody on an [Open] chain: it appends a transferred entry whose [From Custodian Reference] is read from [Current Custodian] (never caller-supplied) and whose [To Custodian Reference] is the new holder, then updates [Current Custodian]. Returns an [Entry Id].

Kind: Operation

#### Transform

The behavior by which the current custodian records a transformation of the artifact on an [Open] chain, appending a transformed entry that carries a [Transformation Descriptor]. [Current Custodian] is unchanged; guarded by [Not Current Custodian].

Kind: Operation

#### Disclose

The behavior by which the current custodian records that the artifact was disclosed to a [Recipient Reference] on an [Open] chain, appending a disclosed entry. Custody is not transferred; [Current Custodian] is unchanged. Records only the custody-timeline fact, not the disclosure's scope or authority (that is Selective Disclosure).

Kind: Operation

#### Archive

The behavior by which the current custodian brings an [Open] chain to terminal disposition, appending an archived entry and transitioning [Chain State] to [Archived]. Absorbing thereafter (Invariant 6).

Kind: Operation

#### Read

The read-only query returning a chain's entries in [Sequence Number] ascending order (optionally filtered). Never transitions. Rejected for an unknown chain ([Not Known]) or a malformed query ([Invalid Query]).

Kind: Operation

#### Chain Id

The opaque, immutable, system-generated identity of a chain — produced by [Originate], unique within a database, never reused (Identity 15). It is the chain's identity; [Artifact Reference] is a property, not the identity.

Kind:       Field
Field of:   the chain
Projection: chain_id

#### Artifact Reference

The opaque reference to *what* the chain tracks. Set at genesis, immutable; the atom neither validates nor interprets it. The same reference may recur across database instances for genuinely different artifacts.

Kind:       Field
Field of:   the chain
Projection: artifact_ref

#### Chain State

The chain's lifecycle state — [Open] or [Archived]. Begins [Open] on [Originate]; transitions once to [Archived] on [Archive], then never again.

Kind:       Field
Field of:   the chain
Projection: chain_state

#### Current Custodian

The opaque reference of the chain's single current holder — a derived projection (cache) of the entry chain: the [To Custodian Reference] of the latest transferred entry, or the genesis [Custodian Reference]. Non-null while the chain exists; changes only on [Transfer]. On any disagreement the replayed entry chain is authoritative.

Kind:       Field
Field of:   the chain
Projection: current_custodian

#### Next Sequence Number

The chain's per-instance counter, beginning at 1 and incrementing by one per successful entry write.

Kind:       Field
Field of:   the chain
Projection: next_sequence_number

#### Entry Id

The opaque, immutable, system-generated identity of a custody entry — assigned at append, unique within the chain, never reused (Invariants 1 and 9).

Kind:       Field
Field of:   the entry
Projection: entry_id

#### Sequence Number

The strictly increasing integer assigned to an entry from [Next Sequence Number] at append. The authoritative, clock-independent order source within the chain (Invariant 5); [Recording Instant] is not.

Kind:       Field
Field of:   the entry
Projection: sequence_number

#### Event Type

The entry's kind — one of originated, received, transferred, transformed, disclosed, or archived (Invariant 8). Set at append, immutable. The [Genesis Type] argument selects the genesis entry's value.

Kind:       Field
Field of:   the entry
Projection: event_type

#### Custodian Reference

On every non-transferred entry, the custodian who performed or is affected by the entry's event — non-empty (Invariant 7), immutable. A transferred entry carries no single [Custodian Reference]; it records the [From Custodian Reference]/[To Custodian Reference] pair instead. For [Transform], [Disclose], and [Archive] the supplied value must equal [Current Custodian] (else [Not Current Custodian]).

Kind:       Field
Field of:   the entry
Projection: custodian_ref

#### Recording Instant

The best-effort wall-time an entry was appended, stamped from the wall-time reading injected at the atom's I/O seam — never read inside a transition and never a caller-supplied argument. An annotation only — never the order source ([Sequence Number] is).

Kind:       Field
Field of:   the entry
Projection: recorded_at

#### From Custodian Reference

On a transferred entry, the outgoing custodian — read from [Current Custodian] at transition time, never caller-supplied (the hand-to-hand guarantee that forecloses a false predecessor). Non-empty (Invariant 7).

Kind:       Field
Field of:   the entry
Projection: from_custodian_ref

#### To Custodian Reference

On a transferred entry, the incoming custodian supplied by the caller; it becomes the new [Current Custodian] after the entry. Non-empty (Invariant 7).

Kind:       Field
Field of:   the entry
Projection: to_custodian_ref

#### Transformation Descriptor

On a transformed entry, the opaque, non-empty description of what was done. An empty or whitespace-only value is [Invalid Descriptor].

Kind:       Field
Field of:   the entry
Projection: transformation_descriptor

#### Recipient Reference

On a disclosed entry, the opaque reference to the party a view or copy was disclosed to. Custody is not transferred.

Kind:       Field
Field of:   the entry
Projection: recipient_ref

#### Metadata

Optional opaque data carried on a genesis (originated/received) entry — e.g., a link to pre-intake provenance for a received artifact.

Kind:       Field
Field of:   the entry
Projection: metadata

#### Genesis Type

The [Originate] argument selecting the genesis entry's [Event Type] — exactly originated or received (else [Invalid Genesis Type]). Consumed at genesis; not stored as a field distinct from [Event Type].

Kind:         Parameter
Parameter of: Originate
Projection:   genesis_type

#### Open

The active state of a chain: entries may be appended and the chain has exactly one [Current Custodian]. The entry state of every chain at [Originate].

Kind:      Member
Member of: the chain state
Role:      Outcome

#### Archived

The terminal, absorbing state of a chain at final disposition (Invariant 6): [Transfer], [Transform], [Disclose], and [Archive] are all rejected, but the chain remains readable. Reached once, via [Archive]. Its name also projects as the archived rejection reason the writer actions return against a closed chain — the shared term entry the Decision points name, kept backticked in prose to keep the rejection token distinct from this state anchor.

Kind:       Member
Member of:  the chain state
Role:       Outcome
Projection: archived

#### Invalid Reference

The rejection an action returns when a required reference ([Artifact Reference], [Custodian Reference], [To Custodian Reference], or [Recipient Reference]) is empty, whitespace-only, or over the deployment-pinned length cap — also returned by [Originate] for an over-limit [Metadata] (Edge cases — *Length caps*).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-ref

#### Invalid Genesis Type

The rejection [Originate] returns when [Genesis Type] is not exactly originated or received.

Kind:       Member
Member of:  the Originate rejection
Role:       Outcome
Projection: invalid-genesis-type

#### Storage Failure

The rejection any action returns when its database write fails after all preconditions pass; guarantees no partial record is observable (Operation 42 through 44).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The rejection [Transfer], [Transform], [Disclose], [Archive], or [Read] returns when the [Chain Id] references no known chain.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Already Archived

The rejection [Archive] returns when the target chain is already [Archived]. (The same condition reaches [Transfer], [Transform], and [Disclose] as the archived rejection — kept a distinct token to avoid colliding with the [Archived] state.)

Kind:       Member
Member of:  the Archive rejection
Role:       Outcome
Projection: already-archived

#### Not Current Custodian

The rejection [Transform], [Disclose], or [Archive] returns when the supplied [Custodian Reference] is not the chain's [Current Custodian] — a prior holder has no write authority.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-current-custodian

#### Invalid Descriptor

The rejection [Transform] returns when the [Transformation Descriptor] is empty, whitespace-only, or over the deployment-pinned length cap — a content field, distinct from [Invalid Reference].

Kind:       Member
Member of:  the Transform rejection
Role:       Outcome
Projection: invalid-descriptor

#### Invalid Query

The rejection [Read] returns when a query parameter is malformed — e.g., a range with start greater than end, or an unknown [Event Type] filter value.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Originate]: #originate
[Transfer]: #transfer
[Transform]: #transform
[Disclose]: #disclose
[Archive]: #archive
[Read]: #read
[Chain Id]: #chain-id
[Artifact Reference]: #artifact-reference
[Chain State]: #chain-state
[Current Custodian]: #current-custodian
[Next Sequence Number]: #next-sequence-number
[Entry Id]: #entry-id
[Sequence Number]: #sequence-number
[Event Type]: #event-type
[Custodian Reference]: #custodian-reference
[Recording Instant]: #recording-instant
[From Custodian Reference]: #from-custodian-reference
[To Custodian Reference]: #to-custodian-reference
[Transformation Descriptor]: #transformation-descriptor
[Recipient Reference]: #recipient-reference
[Metadata]: #metadata
[Genesis Type]: #genesis-type
[Open]: #open
[Archived]: #archived
[Invalid Reference]: #invalid-reference
[Invalid Genesis Type]: #invalid-genesis-type
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Already Archived]: #already-archived
[Not Current Custodian]: #not-current-custodian
[Invalid Descriptor]: #invalid-descriptor
[Invalid Query]: #invalid-query

---

## Standards references

Provenance is an infrastructure primitive with regulatory anchoring across pharmaceutical, legal, and financial domains:

- **ISO 23081 (Information and documentation — Managing metadata for records)** — the International Organization for Standardization's standard on records-management metadata. Provenance is a required element in ISO 23081-compliant records; the atom's chain-of-custody entries map directly to the origin, transfer, and transformation metadata elements ISO 23081 specifies.

- **W3C PROV (Provenance Data Model — W3C's RDF-based standard for representing provenance)** — the atom models the linear single-artifact custody slice of PROV's entity/activity/agent framework. PROV expresses a DAG of provenance relationships; this atom is the linear spine of a single-entity PROV graph — the `wasGeneratedBy`, `used`, and `wasAttributedTo` relationships along a single entity's chain. The deliberate non-goal of `wasDerivedFrom` (DAG derivation) and artifact splitting (one entity split into several) are both out-of-scope relative to the full PROV model.

- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice — Finished Pharmaceuticals)** — US pharmaceutical manufacturing regulations requiring a chain-of-custody record for drug substances and products from manufacture through distribution. The atom's genesis + transfer + transformation + archive lifecycle is the operational form of Part 211's custodial recording requirements.

- **DEA 21 CFR Part 1304 (Controlled Substance Inventory Records)** — US Drug Enforcement Administration (DEA) regulations requiring complete, accurate records of the disposition of controlled substances, including every change of custody. Invariant 4 (custody continuity) is the structural implementation of this requirement.

- **SEC Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — US Securities and Exchange Commission rule requiring records to be preserved as originally created, in a non-rewriteable, non-erasable format. The atom's append-only, entry-immutable chain (Invariants 1 and 2) is the structural form of the preservation-as-originally-created requirement — **necessary, not by itself sufficient**: the rule's format requirement is met by the deployment's storage medium and the audit proof by a composed Tamper Evidence seal (WORM — write-once, read-many — storage being one realization). The atom contributes the record structure the rule preserves, never the whole compliance claim.

- **Federal Rules of Evidence 901(b)(9) (Authenticating or Identifying Evidence — Process or System)** — the US evidentiary rule for authenticating physical or electronic evidence via chain-of-custody records. The atom's custody-continuity invariant is the structural basis for authenticating evidence under 901(b)(9): a chain whose [From Custodian Reference] values match the prior [Current Custodian] at every transfer step produces the unbroken sequence courts require for authentication.

- **RFC (Request for Comments) 3161 (Time-Stamp Protocol)** — the standard for trusted timestamping. Where a custodial timestamp carries legal force — a chain-of-custody stamp in court proceedings, a pharmaceutical distribution record — RFC 3161 trusted timestamping supplies the verifiable anchor, through a composed trusted timestamping pattern (Non-goal 23).

The cross-domain structural identity is the atom's core thesis: the pharmaceutical chain of custody, the legal evidence chain, the financial instrument custody record, and the DEA controlled-substance custody log are all instances of the same primitive — one artifact, one current custodian, append-only entries, custody never gaps. This atom is the core of the Chain of Custody composition, `grounded` 2026-06-04.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing identity attestation, tamper-evidence, and retention as separate concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on every action, every rejection reason named.
- **Linear temporal logic** — custody continuity (Invariant 4) and archived-is-terminal (Invariant 6) expressed as temporal properties holding across every reachable state.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — provenance.als + 1 twin, 2026-06-04
last gate: 2026-08-26 — Final Critique 7, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/provenance.md`; the rounds and the migration that got it here are in [its history](./provenance.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the chain store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the twelve rules that restated them, or existed only for a store that could split an append, tombstoned to their owner — Operation 38, an append's entry and counter raise committed in one operation, Invariant 10.2, no partial record left by a storage-failure rejection, and Atomic writes 1 through 3, no reader observing an entry without its counter raise, a transferred entry without its custodian change or an archived entry without the chain's move to archived, to Store 1; Atomic writes 4, an uncommitted crash leaving the chain as the call found it, to Store 1 and Store 3; Atomic writes 5 through 7, the implementation resolving a dangling transition before the store serves a read or accepts an action, to Store 1, under which no append stands partly applied; State 19, next sequence number surviving a restart, to Store 3; Concurrency 1, two calls against one chain serialized, and Concurrency 3, the second serialized transfer reading the custodian the first set, to Store 2; rules 187 to 176. *Over:* the atom restating, for its own store, what every deployment's store guarantees, and keeping a crash-recovery protocol for a split append that no conforming store leaves. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. What stays is the atom's own: a refused action leaving the chain as the call found it, appending no entry and taking no sequence number (Operation 42 through 44), the entry chain governing a cached current custodian that disagrees with a replay (State 18), every serialized transfer appending, since [Transfer] carries no custodian guard (Concurrency 2), the host serializing its own calls for a transfer conditional on the custodian (Concurrency 4), and the append-only chain the atom never edits (State 15 through 17, Invariant 1.1, Invariant 2.1, Invariant 2.2, Invariant 10.1, Correction 1, Correction 2). The sequence number is the chain's own dense order, taken inside the append, and no rule reads an earlier version of a record, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

NOTE: End of Provenance.

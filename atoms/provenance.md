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

The load-bearing rule is continuity: from genesis to archive the chain has exactly one current custodian, never none and never two. A transfer is hand-to-hand — the outgoing custodian is read from the chain's own state and never supplied by the caller, so a `transferred` entry cannot record a false hand-off.

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

```text
Identity 1: The atom MUST identify a chain by the chain_id.
Identity 2: The atom MUST identify an entry by the entry_id.
Identity 3: The host MUST allocate a chain_id at the seam.
Identity 4: The host MUST allocate an entry_id at the seam.
Identity 5: The transition MUST NOT allocate a chain_id.
Identity 6: The transition MUST NOT allocate an entry_id.
Identity 7: The atom MUST NOT change a chain_id.
Identity 8: The atom MUST NOT change an entry_id.
Identity 9: The atom MUST NOT identify a chain by the artifact_ref.
Identity 10: The atom MUST admit a second chain carrying a recorded artifact_ref.
Identity 11: The atom MUST match a custodian_ref exactly.
Identity 12: The atom MUST NOT normalize a custodian_ref.
Identity 13: The atom MUST NOT interpret an artifact_ref.
Identity 14: The atom MUST NOT confirm that an artifact_ref names a known artifact.
Identity 15: Two chains in one store instance MUST NOT share a chain_id.
Identity 16: Two entries in one chain MUST NOT share an entry_id.
Identity 17: The deployment MUST route EVERY call to one store instance.
```

Term chain: one artifact's custody history for one episode, from a genesis entry to a terminal disposition — the record this atom holds.

Term entry: one appended event on a chain, carrying an `entry_id`, a `sequence_number`, an `event_type`, a custodian and a `recorded_at`.

Term chain_id: the opaque value naming one chain — a [Chain Id]; host-allocated at the seam.

Term artifact_ref: the opaque reference naming what a chain tracks — an [Artifact Ref]; a property of the chain, never the chain's identity.

Term entry_id: the opaque value naming one entry — an [Entry Id]; host-allocated at the seam.

Term custodian_ref: the opaque reference naming who holds the artifact — a [Custodian Ref]; compared by exact byte identity.

Term store instance: one named chain store a call is routed to; `chain_id` uniqueness ranges over one instance.

Term seam: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the chain_id and the entry_id here.

Term transition: the atom's evaluation of one call against the chain store, as `execution-contract.md` §Logic confinement declares it.

WHY:
Identity by artifact would be the natural-looking choice and it destroys the thing the atom is for. A returned-and-reprocessed batch, a re-introduced exhibit, a reissued instrument — each is a *second episode* of the same artifact, and merging the two histories under one identity makes the gap between them invisible. So the chain owns identity and the artifact reference is a field (Identity 9, Identity 10).

Custodian equality is byte-exact: `Lab-7` and `lab-7` are two custodians here. Continuity rests on that comparison being mechanical, so canonicalization belongs to the deployment before the call (Identity 11, Identity 12, Invariant 4.2).

### State

```text
State 1: EVERY chain MUST stand in EXACTLY ONE OF open, archived.
State 2: EVERY chain MUST carry chain_id, artifact_ref, a chain state, a current custodian and next_sequence_number.
State 3: EVERY entry MUST carry entry_id, sequence_number, event_type and recorded_at.
State 4: EVERY non-transferred entry MUST carry a custodian_ref.
State 5: A transferred entry MUST NOT carry a custodian_ref.
State 6: EVERY transferred entry MUST carry from_custodian_ref and to_custodian_ref.
State 7: EVERY transformed entry MUST carry a transformation_descriptor.
State 8: EVERY disclosed entry MUST carry a recipient_ref.
State 9: A genesis entry MAY carry metadata.
State 10: An entry MUST NOT carry a stored genesis_type.
State 11: The atom MUST NOT offer a transition out of archived.
State 12: The atom MUST NOT offer an action that empties the current custodian.
State 13: The atom MUST NOT offer an action that stands two custodians current.
State 14: The atom MUST NOT offer an action beside [Transfer] that moves the current custodian.
State 15: The atom MUST NOT offer a removal surface.
State 16: The atom MUST NOT offer a reorder surface.
State 17: The atom MUST NOT offer an edit surface.
State 18: The entry chain MUST govern where the cached current custodian disagrees with a replay.
State 19: next_sequence_number MUST survive a restart.
```

WHY:
The current custodian is a projection, not a fact of its own: replay the entries in sequence order and the value falls out. It is cached as chain state so a guard need not walk the chain, and the cache is never the authority — a disagreement between cache and replay is resolved by the replay and is itself a conformance failure (State 17, Check 3.2). No invariant here rests on the cache being right; every one is stated over the entries.

`next_sequence_number` is persistent state and the one piece of this atom that a volatile implementation silently breaks. A counter that resets on restart reuses numbers, and the dense sequence — the thing that distinguishes this chain from a gap-permitting stream — is gone without any single action having misbehaved (State 18, Invariant 5.2).

### Capability requirement

```text
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST own the clock's monotonicity.
Capability requirement 3: The deployment MUST own the clock's honesty.
Capability requirement 4: The deployment MUST own the clock's synchronization.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

### Operations

```
originate(artifact_ref, custodian_ref, genesis_type, metadata) → chain_id | rejected(invalid-ref | invalid-genesis-type | storage-failure)
transfer(chain_id, to_custodian_ref) → entry_id | rejected(not-known | archived | invalid-ref | storage-failure)
transform(chain_id, custodian_ref, transformation_descriptor) → entry_id | rejected(not-known | archived | invalid-ref | invalid-descriptor | not-current-custodian | storage-failure)
disclose(chain_id, custodian_ref, recipient_ref) → entry_id | rejected(not-known | archived | invalid-ref | not-current-custodian | storage-failure)
archive(chain_id, custodian_ref) → entry_id | rejected(not-known | already-archived | invalid-ref | not-current-custodian | storage-failure)
read(chain_id, query) → entry_sequence | rejected(not-known | invalid-query)
```

```text
Operation 1: IF artifact_ref NOT EXISTS THEN [Originate] MUST answer invalid-ref.
Operation 2: IF custodian_ref NOT EXISTS THEN [Originate] MUST answer invalid-ref.
Operation 3: IF genesis_type NOT EXISTS in the genesis types THEN [Originate] MUST answer invalid-genesis-type.
Operation 4: [Originate] MUST answer invalid-genesis-type ONLY IF artifact_ref EXISTS AND custodian_ref EXISTS.
Operation 5: An admitted originate MUST record EXACTLY ONE chain.
Operation 6: An admitted originate MUST append the genesis entry.
Operation 7: An admitted originate MUST set the genesis entry's event_type to the call's genesis_type.
Operation 8: An admitted originate MUST stand the chain in open.
Operation 9: An admitted originate MUST answer the chain_id.
Operation 10: IF the chain_id names no chain THEN an addressed action MUST answer not-known.
Operation 11: An addressed action MUST answer not-known ONLY IF the chain_id names no chain.
Operation 12: IF the chain stands in archived THEN [Transfer] MUST answer archived.
Operation 13: IF the chain stands in archived THEN [Transform] MUST answer archived.
Operation 14: IF the chain stands in archived THEN [Disclose] MUST answer archived.
Operation 15: IF the chain stands in archived THEN [Archive] MUST answer already-archived.
Operation 16: A chain-state rejection MUST answer ONLY IF the chain_id names a chain.
Operation 17: IF to_custodian_ref NOT EXISTS THEN [Transfer] MUST answer invalid-ref.
Operation 18: [Transfer] MUST NOT accept a from_custodian_ref from the caller.
Operation 19: An admitted transfer MUST read from_custodian_ref from the current custodian.
Operation 20: An admitted transfer MUST append a transferred entry.
Operation 21: An admitted transfer MUST set the current custodian to to_custodian_ref.
Operation 22: [Transfer] MUST NOT guard a call on the caller's custodian_ref.
Operation 23: IF custodian_ref NOT EXISTS THEN a custodian-guarded action MUST answer invalid-ref.
Operation 24: IF transformation_descriptor NOT EXISTS THEN [Transform] MUST answer invalid-descriptor.
Operation 25: IF recipient_ref NOT EXISTS THEN [Disclose] MUST answer invalid-ref.
Operation 26: IF custodian_ref != the current custodian THEN a custodian-guarded action MUST answer not-current-custodian.
Operation 27: A custodian-guarded action MUST answer not-current-custodian ONLY IF EVERY supplied reference EXISTS.
Operation 28: An admitted transform MUST append a transformed entry.
Operation 29: An admitted disclose MUST append a disclosed entry.
Operation 30: An admitted archive MUST append an archived entry.
Operation 31: An admitted archive MUST stand the chain in archived.
Operation 32: An admitted archive MUST NOT change the current custodian.
Operation 33: An admitted transform MUST NOT change the current custodian.
Operation 34: An admitted disclose MUST NOT change the current custodian.
Operation 35: An admitted disclose MUST NOT change the artifact's custody.
Operation 36: An appending action MUST take the entry's sequence_number from next_sequence_number.
Operation 37: An appending action MUST raise next_sequence_number by one.
Operation 38: An appending action MUST commit the entry and the raise in one operation.
Operation 39: An appending action MUST answer the entry_id.
Operation 40: An appending action MUST stamp recorded_at from the injected now.
Operation 41: IF the store refuses the write THEN an appending action MUST answer storage-failure.
Operation 42: A refused action MUST leave the chain as the call found the chain.
Operation 43: A refused action MUST NOT append an entry.
Operation 44: A refused action MUST NOT take a sequence_number.
Operation 45: An action MUST answer storage-failure ONLY IF EVERY precondition passes.
Operation 46: [Read] MUST answer the chain's entries in sequence_number ascending order.
Operation 47: [Read] MUST answer an empty entry sequence for a well-formed query no entry matches.
Operation 48: IF a query range's end precedes the range's start THEN [Read] MUST answer invalid-query.
Operation 49: IF a query's event_type NOT EXISTS in the event types THEN [Read] MUST answer invalid-query.
Operation 50: [Read] MUST NOT write.
Operation 51: [Read] MUST NOT answer storage-failure.
Operation 52: IF the store refuses a read THEN [Read] MUST NOT answer a partial entry sequence.
Operation 53: [Read] MUST NOT answer archived.
Deleted: Operation 54. Capability requirement 1 owns it.
Deleted: Operation 55. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 56. `execution-contract.md` §Logic confinement owns it.
Deleted: Operation 57. Clock dependence 2 owns it.
Operation 58: An ordering rule MUST NOT rest on recorded_at.
```

Term now: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Term business caller: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Term genesis_type: the call argument selecting a genesis entry's event_type — a [Genesis Type]; an input name, never a stored field.

Term genesis types: `originated` | `received` — what a genesis entry's event_type may be.

Term event_type: `originated` | `received` | `transferred` | `transformed` | `disclosed` | `archived` — an [Event Type], set at append and never changed.

Term event types: the six members of `event_type`, cited here from that declaration (Closed vocabulary 15).

Term chain state: `open` | `archived` — accepting entries, or at terminal disposition. A [Chain State].

Term current custodian: the `to_custodian_ref` of the chain's latest `transferred` entry, or the genesis entry's `custodian_ref` where no transfer has landed — a [Current Custodian]; a projection of the entry chain, cached as chain state so a guard need not replay.

Term sequence_number: the strictly increasing integer an entry takes at append — a [Sequence Number]; the chain's order source, and never taken from a clock.

Term next_sequence_number: the counter an appending action takes a `sequence_number` from — a [Next Sequence Number]; begins at one, rises by one per append, and survives a restart.

Term recorded_at: the instant an entry was appended — a [Recorded At]; a best-effort annotation, and never an order source.

Term addressed action: any action carrying a `chain_id` — every action but [Originate].

Term custodian-guarded action: [Transform] | [Disclose] | [Archive] — the three an attribution guard covers.

Term appending action: [Originate] | [Transfer] | [Transform] | [Disclose] | [Archive] — every action but [Read].

Term chain-state rejection: the `archived` answer a writer gives against a closed chain, and the `already-archived` answer [Archive] gives.

Term admitted originate: an [Originate] call whose artifact_ref, custodian_ref and genesis_type the guards all admit.

Term admitted transfer: a [Transfer] call whose chain_id names an open chain and whose to_custodian_ref exists.

Term admitted transform: a [Transform] call whose chain_id names an open chain, whose references and descriptor exist, and whose custodian_ref matches the current custodian.

Term admitted disclose: a [Disclose] call whose chain_id names an open chain, whose references exist, and whose custodian_ref matches the current custodian.

Term admitted archive: an [Archive] call whose chain_id names an open chain, whose custodian_ref exists and matches the current custodian.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Originate] | refs present, genesis type admitted | the new `chain_id` | a chain opens, genesis entry at sequence one (Operation 5 through 9) |
| [Originate] | a blank reference | [Invalid Ref] | none (Operation 1, Operation 2) |
| [Originate] | genesis type outside the two | [Invalid Genesis Type] | none (Operation 3, Operation 4) |
| [Transfer] | open chain, `to_custodian_ref` present | the `entry_id` | `transferred` entry; the from-side read from state; custody moves (Operation 19 through 21) |
| [Transform] | open chain, refs present, custodian current | the `entry_id` | `transformed` entry; custody unchanged (Operation 28, Operation 33) |
| [Disclose] | open chain, refs present, custodian current | the `entry_id` | `disclosed` entry; custody unchanged (Operation 29, Operation 34) |
| [Archive] | open chain, custodian current | the `entry_id` | `archived` entry; chain closes; custody unchanged (Operation 30 through 32) |
| any writer | chain is archived | [Archived] | none (Operation 12 through 14) |
| [Archive] | chain is archived | [Already Archived] | none (Operation 15) |
| custodian-guarded | `custodian_ref` is not the current custodian | [Not Current Custodian] | none (Operation 26) |
| any addressed action | id names nothing | [Not Known] | none (Operation 10) |
| any appending action | store refuses | [Storage Failure] | none (Operation 41 through 44) |
| [Read] | a well-formed query, any chain state | the matching entries, oldest first | none (Operation 46, Operation 53) |
| [Read] | an inverted range, or an unknown event type | [Invalid Query] | none (Operation 48, Operation 49) |

WHY:
Rejection precedence lives in the guards rather than in a note. Existence comes first because every later check needs a chain to inspect (Operation 10, Operation 11). Chain state comes next, conditioned on the chain existing (Operation 16). Field format comes before the custodian comparison, and that order is load-bearing rather than conventional: the current custodian is never blank (Invariant 7.1), so a blank caller-supplied reference can never equal it — a comparison-first order would make [Invalid Ref] unreachable and report every malformed input as an attribution failure (Operation 27).

`archived` and `already-archived` are two answers to one state because they tell a retrying caller opposite things. A writer meeting `archived` learns the chain is closed to that intent; [Archive] meeting `already-archived` learns the state it wanted already holds. The first is final, the second is a done-signal — and the action still writes no second entry (Operation 12 through 15).

[Transfer] carries no custodian guard, and the asymmetry is designed. The other three guards are *attribution* constraints — they stop an entry claiming a custodian who is not current. On a transfer the same constraint holds more strongly and by construction, because the from-side is never claimed at all: it is read from the chain (Operation 18, Operation 19, Operation 22). Adding a caller-supplied check would buy nothing structural — an opaque reference is a label, not a credential, exactly as forgeable as on the other three — and would block the receive-side and system-mediated recording of a hand-off that real deployments need.

### Invariants

- **Invariant 1 — Entry immutability.**
  ```text
  Invariant 1.1: A recorded entry's fields MUST NOT change.
  ```
- **Invariant 2 — Append-only chain.**
  ```text
  Invariant 2.1: A chain's entry count MUST NOT fall under the atom's actions.
  Invariant 2.2: A recorded entry's sequence_number MUST NOT change.
  ```
- **Invariant 3 — Single origin.**
  ```text
  Invariant 3.1: EVERY chain MUST carry EXACTLY ONE genesis entry.
  Invariant 3.2: A genesis entry's sequence_number MUST stand at one.
  Invariant 3.3: The atom MUST NOT offer a second originate against a recorded chain.
  ```
- **Invariant 4 — Custody continuity.**
  ```text
  Invariant 4.1: EVERY open chain MUST carry EXACTLY ONE current custodian.
  Invariant 4.2: EVERY custodian-guarded entry's custodian_ref MUST equal the current custodian the entry found.
  Invariant 4.3: EVERY transferred entry's from_custodian_ref MUST equal the current custodian the entry found.
  Invariant 4.4: EVERY transferred entry's to_custodian_ref MUST stand as the current custodian the entry left.
  ```
  WHY: the load-bearing one, and the reason this is not a configured [Event Log](./event-log.md). That atom is content-agnostic, carries no subject and no custodian, and permits sequence gaps by design; continuity needs all three. A stream that admits a gap cannot prove there wasn't one.
- **Invariant 5 — Dense total order within a chain.**
  ```text
  Invariant 5.1: Two entries in one chain MUST NOT share a sequence_number.
  Invariant 5.2: A chain's sequence_numbers MUST stand from one to the chain's entry count.
  Invariant 5.3: A chain's order MUST rest on sequence_number alone.
  ```
- **Invariant 6 — Archived is terminal and absorbing.**
  ```text
  Invariant 6.1: An archived chain MUST NOT leave archived.
  Invariant 6.2: An archived chain MUST NOT admit an entry.
  ```
- **Invariant 7 — Custodian presence.**
  ```text
  Invariant 7.1: EVERY non-transferred entry's custodian_ref MUST carry a non-whitespace character.
  Invariant 7.2: EVERY transferred entry's from_custodian_ref and to_custodian_ref MUST carry a non-whitespace character.
  ```
- **Invariant 8 — Event type validity.**
  ```text
  Invariant 8.1: EVERY entry's event_type MUST stand in the event types.
  Invariant 8.2: A genesis entry's event_type MUST stand in the genesis types.
  Invariant 8.3: A non-genesis entry's event_type MUST NOT stand in the genesis types.
  Invariant 8.4: An archived chain's last entry's event_type MUST stand at archived.
  ```
- **Invariant 9 — Chain durability over this atom's own surface.**
  ```text
  Invariant 9.1: The chain count MUST NOT fall under the atom's actions.
  Invariant 9.2: A storage-failure rejection MUST leave no partial record in the store.
  ```
  WHY: scoped to the atom's own surface. Lawful disposal under a composed [Retention Window](./retention-window.md) or [Defensible Retention](../compositions/defensible-retention.md) is that pattern's declared and recorded act (Non-goal 19, Non-goal 20).

---

## Examples

### Pharmaceutical — a batch from manufacture to dispensing

A manufacturer opens the chain: `originate(artifact_ref: "batch-x91", custodian_ref: "manuf-lab-7", genesis_type: originated)` → `chain-0041`. The genesis entry takes `sequence_number: 1` and the chain stands open with `manuf-lab-7` current (Operation 5 through 9).

`transfer("chain-0041", to_custodian_ref: "dist-region-3")` → `e2`. The entry records `from_custodian_ref: "manuf-lab-7"` — read from the current custodian, never from the caller (Operation 18, Operation 19). `transfer("chain-0041", "pharm-hosp-9")` → `e3`. The pharmacist records the dispense: `transform("chain-0041", "pharm-hosp-9", "dispensed 10mg dose into unit D44")` → `e4`, then closes it: `archive("chain-0041", "pharm-hosp-9")` → `e5`. The chain stands archived.

A regulator asks whether custody was unbroken. `read("chain-0041")` answers five entries in sequence order. Every transferred entry's `from_custodian_ref` equals the prior entry's `to_custodian_ref`, or the genesis `custodian_ref` for the first transfer. Invariant 4 is the structural answer.

### Legal evidence — a physical exhibit

`originate(artifact_ref: "exhibit-A", custodian_ref: "det-r.james", genesis_type: originated)` → `chain-0107`. The exhibit moves to the evidence room (`e2`), then the lab (`e3`). The lab records its work: `transform("chain-0107", "forensic-lab-12", "fingerprint-lifted; DNA-sample-taken; original-exhibit-intact")` → `e4`. It returns to the evidence room (`e5`). The chain stands open pending trial.

Defense counsel claims an undocumented handler between the detective and the lab. `read("chain-0107")` answers five entries; no entry's `from_custodian_ref` names a party who was not the immediately prior `to_custodian_ref`, and every entry names a custodian (Invariant 4, Invariant 7). An unrecorded intermediary was never the current custodian, so no intermediary could have recorded a transformation or generated a transfer.

### Rejection paths

`transform("chain-0041", "manuf-lab-7", "added label update")` against the archived pharmaceutical chain → `rejected(archived)`. The chain-state rejection precedes the attribution guard, so the caller learns the chain is closed rather than that they are not the custodian (Operation 13, Operation 16).

The same call against the chain while it stood open, after custody had moved to `pharm-hosp-9` → `rejected(not-current-custodian)` (Operation 26).

`originate("sample-99", custodian_ref: "", genesis_type: originated)` → `rejected(invalid-ref)`. No chain is recorded (Operation 2, Operation 43).

`originate("sample-77", "lab-2", genesis_type: imported)` → `rejected(invalid-genesis-type)`. `imported` stands outside the genesis types (Operation 3).

`transform("chain-0107", "forensic-lab-12", "   ")` → `rejected(invalid-descriptor)`. A whitespace-only descriptor NOT EXISTS (Operation 24, String 5).

`archive("chain-0041", "pharm-hosp-9")` against the archived chain → `rejected(already-archived)` — a distinct reason from the writer actions' `archived`, so a retrying archiver learns the work is done rather than refused (Operation 15).

`read("chain-9999")` → `rejected(not-known)` (Operation 10).

`read("chain-0041", {sequence_range: [5, 2]})` → `rejected(invalid-query)`. The caller corrects the query rather than reading an empty answer as *no entries matched* (Operation 47, Operation 48).

`transfer("chain-0107", "forensic-lab-12")` while the store's write path is down → `rejected(storage-failure)`. Every precondition passed and the write did not; no entry is appended, no `sequence_number` is taken, and the current custodian holds its prior value (Operation 41 through 45).

### Regulated adversarial scenarios

- **Regulator audit.** An FDA (US Food and Drug Administration) inspector asks for the complete chain of custody for `batch-x91` under 21 CFR (Code of Federal Regulations) Part 211. `read("chain-0041")` answers the ordered sequence; the inspector clears Check 1.1 through 7.2 from those records alone, without the facility's assertion that custody was maintained.
- **Disputed transaction.** The defense rebuttal above rests on two invariants together: custody continuity, because `from_custodian_ref` is read from chain state and cannot be supplied (Invariant 4, Operation 18), and custodian presence, because no entry may name an empty custodian (Invariant 7).
- **Breach investigation.** An investigator brackets an anomaly window generously: `read("chain-0041", {recorded_at_range: ["2026-02-27", "2026-03-17"]})`. A wall-time filter is a convenience over a best-effort annotation and never an ordering claim (Operation 58), so the window's completeness is confirmed from an unfiltered read — the filtered window's first and last entries are located in the full sequence and their sequence-adjacent neighbours checked to fall outside the bracket. The sequence is dense (Invariant 5), so no entry lies between an entry and its sequence-adjacent neighbour and a clock-skewed entry cannot have been silently excluded. The custodian in force at any point is then exactly determined by replaying the preceding entries.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the chain store and its entries, with no recourse to source code, runbooks or developer narration.

### Conformance checks

```text
Check 1.1: An auditor MUST find a custodian_ref on EVERY non-transferred entry (Invariant 7.1).
Check 1.2: An auditor MUST find a from_custodian_ref and a to_custodian_ref on EVERY transferred entry (Invariant 7.2).
Check 2.1: An auditor MUST find EXACTLY ONE genesis entry per chain (Invariant 3.1).
Check 2.2: An auditor MUST find EVERY genesis entry standing at sequence_number one (Invariant 3.2).
Check 3.1: An auditor MUST replay a chain in sequence_number ascending order against a current custodian cursor (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY transferred entry's from_custodian_ref equal to the cursor the replay carried in (Invariant 4.3).
Check 3.3: An auditor MUST find EVERY custodian-guarded entry's custodian_ref equal to the cursor at that entry (Invariant 4.2).
Check 4.1: An auditor MUST find a chain's sequence_numbers standing from one to the chain's entry count (Invariant 5.2).
Check 4.2: An auditor MUST reconstruct a chain's order from sequence_number alone (Invariant 5.3).
Check 5.1: An auditor MUST find no entry in an archived chain following the archived entry's sequence_number (Invariant 6.2).
Check 6.1: An auditor MUST find a re-read entry's fields unchanged from the prior read (Invariant 1.1).
Check 7.1: An auditor MUST find EVERY entry's event_type standing in the event types (Invariant 8.1).
Check 7.2: An auditor MUST find EVERY archived chain's last entry standing at archived (Invariant 8.4).
Check 7.3: An auditor MUST find no entry_id repeated within a chain (Identity 16).
Check 7.4: An auditor MUST find no chain_id repeated within a store instance (Identity 15).
```

NOTE: EVERY check names the rule the check tests.

WHY:
Check 3.1 is the replay the atom's own guards apply, run offline. It needs the entries and nothing else — no cached current custodian, no implementation account of what the cursor held — which is why State 18 gives the entry chain the governing word where the cache disagrees.

Check 5.1 rests on `sequence_number` rather than `recorded_at` deliberately: a best-effort wall-time annotation later than the archive stamp is a clock artifact, not a broken chain (Operation 58).

## Non-goals

```text
Non-goal 1: The atom MUST NOT confirm that a custodian_ref names a credentialed party.
Non-goal 2: A deployment needing a non-repudiable custodian MUST compose [Actor Identity](./actor-identity.md).
Non-goal 3: The atom MUST NOT decide who may call an action.
Non-goal 4: A deployment needing an authorization decision MUST compose [Permissions](./permissions.md).
Non-goal 5: The atom MUST NOT record a disclosure's scope.
Non-goal 6: The atom MUST NOT record a disclosure's authority.
Non-goal 7: A deployment needing a disclosure's scope recorded MUST compose [Selective Disclosure](./selective-disclosure.md).
Non-goal 8: The atom MUST NOT claim a custody the chain's entries do not record.
Non-goal 9: The atom MUST NOT offer an amendment entry.
Non-goal 10: The atom MUST NOT offer a supersedes link between two entries.
Non-goal 11: The atom MUST NOT offer a view that resolves a correction.
Non-goal 12: The atom MUST NOT detect a rewrite under the store.
Non-goal 13: A deployment needing a rewrite detected MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 14: The atom MUST NOT bound a chain's retention.
Non-goal 15: A deployment needing a retention bound MUST compose [Retention Window](./retention-window.md).
Non-goal 16: The atom MUST NOT record a chain derived from a second chain.
Non-goal 17: The atom MUST NOT record two current custodians on one chain.
Non-goal 18: The atom MUST NOT interpret the artifact's medium.
Non-goal 19: The atom MUST NOT dispose of a chain.
Non-goal 20: A deployment needing a lawful disposal MUST compose [Defensible Retention](../compositions/defensible-retention.md).
Non-goal 21: The atom MUST NOT offer a read keyed by artifact_ref.
Non-goal 22: The atom MUST NOT offer a compare-and-swap arm on [Transfer].
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

WHY:
Non-goal 3 is the one most often mistaken for a gap. The atom guards *attribution* — the custodian-guarded actions reject a caller who is not the current custodian — and that guard is exact equality on an opaque label, not authentication. A caller who knows the current custodian's reference can record entries under it, and the records will show every action faithfully attributed without recording whether the attribution was permitted or authentic. A regulator asking *was this transfer authorized, and was it really the pharmacist?* reads [Permissions](./permissions.md)' decision and [Actor Identity](./actor-identity.md)'s attestation for those two answers, and this atom's records for the custody fact they admitted.

Non-goal 8 bounds what a `received` genesis claims. The artifact had a custody history outside the system before intake; the chain documents custody from genesis forward and asserts nothing about what came before. Pre-intake provenance, where a deployment needs it, is a separate chain or an external record the host links through the genesis metadata.

Non-goal 16 is what keeps custody continuity well-defined. W3C PROV's `wasDerivedFrom` relationship — one artifact produced by transforming or combining others — has no single current custodian to guard, and this atom is a linear single-artifact chain by construction. A sample aliquoted into five sub-samples is five new chains, each opening with `received`; the parent-to-child relationship is a composing concept.

Non-goal 21 follows from the identity model: `artifact_ref` is opaque and non-unique (Identity 9, Identity 10), so an artifact-keyed read would have to answer with a set of chains and would invite treating the reference as an identity. The `chain_id` [Originate] answers is the designed handle; a reverse index over genesis entries is host-side, rebuildable from the chains, and carries no consistency claim of its own.

---

## Edge cases

### Atomic writes

```text
Atomic writes 1: A reader MUST NOT observe an entry without the entry's next_sequence_number raise.
Atomic writes 2: A reader MUST NOT observe a transferred entry without the entry's current custodian change.
Atomic writes 3: A reader MUST NOT observe an archived entry without the chain's move to archived.
Atomic writes 4: An uncommitted crash MUST leave the chain as the call found the chain.
Atomic writes 5: The implementation MUST resolve a dangling transition.
Atomic writes 6: The store MUST NOT serve a read BEFORE the implementation resolves the dangling transition.
Atomic writes 7: The store MUST NOT accept an action BEFORE the implementation resolves the dangling transition.
```

Term uncommitted crash: a crash BEFORE an appending action's commit lands.

Term dangling transition: an appending action's mutations standing partly applied once a crash has landed; the implementation resolves one by completing the mutations OR rolling the mutations back.

WHY:
Every append couples at least two durable mutations — the entry and the counter raise — and [Transfer] and [Archive] carry a third (Operation 36 through 38). The obligation is an observability guarantee, all-or-none: a partly applied append is not a transient condition an implementation may expose and repair later; it must never be servable. A [Storage Failure] answer carries the same guarantee from the caller's side (Operation 41, Invariant 9.2).

### Clock dependence

```text
Clock dependence 1: A rejection MUST NOT rest on now.
Clock dependence 2: A guard MUST NOT read now.
```

WHY:
Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated here rather than among the rules about what the clock is and what a transition stamps from it. Every rule below keeps the words it carried under `Clock semantics`; only the heading changed.

### Clock semantics

```text
Clock semantics 4: A guard MUST NOT rest on recorded_at.
Deleted: Clock semantics 1. Capability requirement 2 owns it.
Deleted: Clock semantics 2. Capability requirement 3 owns it.
Deleted: Clock semantics 3. Capability requirement 4 owns it.
Deleted: Clock semantics 5. Clock dependence 1 owns it.
Deleted: Clock semantics 6. Non-goal 23 owns it.
```

WHY:
No invariant here is at risk from a bad clock, because ordering rests on `sequence_number` and never on `recorded_at` (Invariant 5.3, Operation 58). Where a custodial timestamp carries legal force — a chain-of-custody stamp in court proceedings, a pharmaceutical distribution record — the deployment sources time from a trustworthy clock, and RFC (Request for Comments) 3161 trusted timestamping supplies the verifiable anchor (Non-goal 23).

### Concurrency

```text
Concurrency 1: The implementation MUST serialize two calls against one chain.
Concurrency 2: EVERY serialized transfer against one open chain MUST append.
Concurrency 3: The second serialized transfer MUST read from_custodian_ref from the current custodian the first transfer set.
Concurrency 4: A host needing a transfer conditional on the current custodian MUST serialize the host's own calls.
```

WHY:
[Transfer] carries no custodian guard by design (Operation 22), so a second concurrent transfer is not rejected — it records a hand-off from the first transfer's recipient onward, and the chain stays hand-to-hand consistent either way (Invariant 4.3). What the atom cannot know is whether the resulting double hop reflects what physically happened; that check belongs to the host. A host that needs *record this hand-off only if the holder is still X* reads first and serializes, or composes an optimistic-concurrency surface (Non-goal 22).

### String policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 6: The deployment MUST set a maximum length per string input.
String 7: IF a reference EXCEEDS the maximum length THEN the action MUST answer invalid-ref.
String 8: IF transformation_descriptor EXCEEDS the maximum length THEN [Transform] MUST answer invalid-descriptor.
String 9: IF metadata EXCEEDS the maximum length THEN [Originate] MUST answer invalid-ref.
```

Term string input: `artifact_ref`, `custodian_ref`, `to_custodian_ref`, `recipient_ref`, `transformation_descriptor` OR `metadata` — every caller-supplied string this atom accepts.

Term reference: `artifact_ref`, `custodian_ref`, `to_custodian_ref` OR `recipient_ref` — every string input naming a party or an artifact.

Term blank: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

Term maximum length: the deployment's cap per string input.

WHY:
The cap's value is a deployment choice; the cap's existence is part of the contract. An uncapped opaque field turns an append-only chain that is never deleted (Invariant 9.1) into an unbounded-payload sink, and a regulated store must be able to state its maximum record size.

A whitespace-only descriptor answers `invalid-descriptor` rather than `invalid-ref` because a descriptor is content, not a reference (Operation 24). An opaque transformation that cannot be described at all is a gap in the chain's story, not a transformation entry.

### Correction by append

```text
Correction 1: The atom MUST NOT edit an entry.
Correction 2: The atom MUST NOT remove an entry.
Correction 3: The current custodian MUST record a correction as a subsequent entry.
Correction 4: A correcting entry MUST name the corrected entry's sequence_number.
```

WHY:
The chain is append-only and entries are immutable (Invariant 1.1, Invariant 2.1), so a mis-keyed descriptor or a disclosure recorded against the wrong recipient is never edited away. Correction-by-append is what regulated record-keeping asks for: the record shows both the error and its correction, in order, and the correcting entry is appended under the then-current custodian like any other. Formal amendment semantics stay out (Non-goal 9 through 11).

---

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the attestation binding a custodian_ref to an actor.
Composition note 4: A composing pattern MUST own the tamper seal over the entry chain.
Composition note 5: A composing pattern MUST own the retention of the chain store.
Composition note 6: A composing pattern MUST own a disclosure's scope and authority.
Composition note 7: A composing pattern MUST own the relationship between two chains.
Composition note 8: A composing pattern reading the chain store MUST NOT write to the chain store.
```

WHY:
[Chain of Custody](../compositions/chain-of-custody.md) is the composition this atom exists inside: it wires Provenance with [Actor Identity](./actor-identity.md), [Tamper Evidence](./tamper-evidence.md) and [Retention Window](./retention-window.md) to produce the full chain-of-custody surface — structural continuity from this atom, per-entry attestation, the chain seal, and the retention clock (Composition note 3 through 5). It is the canonical implementation for pharmaceutical custody under 21 CFR Part 211 and DEA 21 CFR Part 1304, regulated evidence custody under Federal Rules of Evidence 901(b)(9), and financial instrument custody records under SEC Rule 17a-4.

[Immutable Transaction Ledger](../compositions/immutable-transaction-ledger.md) enriches ledger entries that reference a tracked artifact, naming this enrichment in its single-artifact financial-instrument custody edge case. [Resolve a Person's Data Rights](../compositions/resolve-a-persons-data-rights.md) reads the custody record as evidence of lawful handling under GDPR (EU General Data Protection Regulation) Articles 5 and 30, and [Customer Onboarding](../compositions/customer-onboarding.md) optionally chains the custody of identity-verification documents.

[Selective Disclosure](./selective-disclosure.md) is the partner that makes [Disclose] complete: this atom marks where on the custody timeline a disclosure occurred and to whom, and Selective Disclosure records what scope was shared under what authority. Neither duplicates the other (Composition note 6, Non-goal 5 through 7).

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the implementation; the deployment; a composing pattern; a business caller; a caller; a guard; an auditor; a regulator; the store; a reader; a chain; an entry; a genesis entry; a transferred entry; a non-transferred entry; a transformed entry; a disclosed entry; an archived entry; a custodian-guarded entry; an addressed action; an appending action; a custodian-guarded action; a writer action; a refused action; an ordering rule; a query; a replay; a rejection; a correction; a crash; a string input; a reference; an opaque reference; the chain count; the entry count.

Term records: `chain` — one artifact's custody history for one episode, carrying `chain_id`, `artifact_ref`, a chain state, a current custodian and `next_sequence_number`. `entry` — one appended event on a chain, carrying `entry_id`, `sequence_number`, `event_type`, `custodian_ref` and `recorded_at`, and the per-type fields `from_custodian_ref`, `to_custodian_ref`, `transformation_descriptor`, `recipient_ref` and `metadata`.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, read, take, raise, commit, stamp, leave, own, match, normalize, interpret, confirm, admit, offer, govern, survive, route, share, equal, precede, follow, exceed, compare, trim, case-fold, refuse, write, find, replay, reconstruct, repeat, observe, complete, roll back, serve, accept, serialize, name, claim, detect, bound, dispose, decide, compose, declare, wire, guard, rest, apply, supply, inject, fall, remove, edit, reorder, empty, move, cache, resolve, run.

Term value sets: originate answers = chain_id | rejected(invalid-ref | invalid-genesis-type | storage-failure). transfer answers = entry_id | rejected(not-known | archived | invalid-ref | storage-failure). transform answers = entry_id | rejected(not-known | archived | invalid-ref | invalid-descriptor | not-current-custodian | storage-failure). disclose answers = entry_id | rejected(not-known | archived | invalid-ref | not-current-custodian | storage-failure). archive answers = entry_id | rejected(not-known | already-archived | invalid-ref | not-current-custodian | storage-failure). read answers = the matching entries | rejected(not-known | invalid-query). `event_type` = originated | received | transferred | transformed | disclosed | archived. `genesis types` = originated | received. `chain state` = open | archived.

Term bounds: `maximum length` (the deployment's cap per string input).

Term cadences: empty.

Term qualifiers: `migrated` — rewritten in GRACE lang v0.39 (2026-09-12).

Term terms: `chain`, `entry`, `chain_id`, `artifact_ref`, `entry_id`, `custodian_ref`, `store instance`, `seam`, `transition`, `now`, `business caller`, `genesis_type`, `genesis types`, `event_type`, `event types`, `chain state`, `current custodian`, `sequence_number`, `next_sequence_number`, `recorded_at`, `from_custodian_ref`, `to_custodian_ref`, `transformation_descriptor`, `recipient_ref`, `metadata`, `addressed action`, `custodian-guarded action`, `appending action`, `chain-state rejection`, `admitted originate`, `admitted transfer`, `admitted transform`, `admitted disclose`, `admitted archive`, `string input`, `reference`, `blank`, `maximum length`, `uncommitted crash`, `dangling transition`.

#### Originate

The behavior that opens a new chain for an artifact: it writes the genesis entry (`sequence_number = 1`) with the selected [Genesis Type], records the [Artifact Ref], sets [Current Custodian] to the genesis [Custodian Ref], and returns a fresh [Chain Id]. Rejected for an empty reference ([Invalid Ref]), a bad [Genesis Type] ([Invalid Genesis Type]), or a failed write ([Storage Failure]).

Kind: Operation

#### Transfer

The behavior that records a hand-to-hand change of custody on an [Open] chain: it appends a `transferred` entry whose [From Custodian Ref] is read from [Current Custodian] (never caller-supplied) and whose [To Custodian Ref] is the new holder, then updates [Current Custodian]. Returns an [Entry Id].

Kind: Operation

#### Transform

The behavior by which the current custodian records a transformation of the artifact on an [Open] chain, appending a `transformed` entry that carries a [Transformation Descriptor]. [Current Custodian] is unchanged; guarded by [Not Current Custodian].

Kind: Operation

#### Disclose

The behavior by which the current custodian records that the artifact was disclosed to a [Recipient Ref] on an [Open] chain, appending a `disclosed` entry. Custody is not transferred; [Current Custodian] is unchanged. Records only the custody-timeline fact, not the disclosure's scope or authority (that is Selective Disclosure).

Kind: Operation

#### Archive

The behavior by which the current custodian brings an [Open] chain to terminal disposition, appending an `archived` entry and transitioning [Chain State] to [Archived]. Absorbing thereafter (Invariant 6).

Kind: Operation

#### Read

The read-only query returning a chain's entries in [Sequence Number] ascending order (optionally filtered). Never transitions. Rejected for an unknown chain ([Not Known]) or a malformed query ([Invalid Query]).

Kind: Operation

#### Chain Id

The opaque, immutable, system-generated identity of a chain — produced by [Originate], unique within a store, never reused (Identity 15). It is the chain's identity; [Artifact Ref] is a property, not the identity.

Kind:     Field
Field of: the chain
Projects: chain_id

#### Artifact Ref

The opaque reference to *what* the chain tracks. Set at genesis, immutable; the atom neither validates nor interprets it. The same reference may recur across store instances for genuinely different artifacts.

Kind:     Field
Field of: the chain
Projects: artifact_ref

#### Chain State

The chain's lifecycle state — [Open] or [Archived]. Begins [Open] on [Originate]; transitions once to [Archived] on [Archive], then never again.

Kind:     Field
Field of: the chain
Projects: chain_state

#### Current Custodian

The opaque reference of the chain's single current holder — a derived projection (cache) of the entry chain: the [To Custodian Ref] of the latest `transferred` entry, or the genesis [Custodian Ref]. Non-null while the chain exists; changes only on [Transfer]. On any disagreement the replayed entry chain is authoritative.

Kind:     Field
Field of: the chain
Projects: current_custodian

#### Next Sequence Number

The chain's per-instance counter, beginning at 1 and incrementing by one per successful entry write. Part of persistent chain state; must survive restarts (State 19).

Kind:     Field
Field of: the chain
Projects: next_sequence_number

#### Entry Id

The opaque, immutable, system-generated identity of a custody entry — assigned at append, unique within the chain, never reused (Invariants 1 and 9).

Kind:     Field
Field of: the entry
Projects: entry_id

#### Sequence Number

The strictly increasing integer assigned to an entry from [Next Sequence Number] at append. The authoritative, clock-independent order source within the chain (Invariant 5); [Recorded At] is not.

Kind:     Field
Field of: the entry
Projects: sequence_number

#### Event Type

The entry's kind — one of `originated`, `received`, `transferred`, `transformed`, `disclosed`, or `archived` (Invariant 8). Set at append, immutable. The [Genesis Type] argument selects the genesis entry's value.

Kind:     Field
Field of: the entry
Projects: event_type

#### Custodian Ref

On every non-`transferred` entry, the custodian who performed or is affected by the entry's event — non-empty (Invariant 7), immutable. A `transferred` entry carries no single [Custodian Ref]; it records the [From Custodian Ref]/[To Custodian Ref] pair instead. For [Transform], [Disclose], and [Archive] the supplied value must equal [Current Custodian] (else [Not Current Custodian]).

Kind:     Field
Field of: the entry
Projects: custodian_ref

#### Recorded At

The best-effort wall-time an entry was appended, stamped from the wall-time reading injected at the atom's I/O seam — never read inside a transition and never a caller-supplied argument. An annotation only — never the order source ([Sequence Number] is).

Kind:     Field
Field of: the entry
Projects: recorded_at

#### From Custodian Ref

On a `transferred` entry, the outgoing custodian — read from [Current Custodian] at transition time, never caller-supplied (the hand-to-hand guarantee that forecloses a false predecessor). Non-empty (Invariant 7).

Kind:     Field
Field of: the entry
Projects: from_custodian_ref

#### To Custodian Ref

On a `transferred` entry, the incoming custodian supplied by the caller; it becomes the new [Current Custodian] after the entry. Non-empty (Invariant 7).

Kind:     Field
Field of: the entry
Projects: to_custodian_ref

#### Transformation Descriptor

On a `transformed` entry, the opaque, non-empty description of what was done. An empty or whitespace-only value is [Invalid Descriptor].

Kind:     Field
Field of: the entry
Projects: transformation_descriptor

#### Recipient Ref

On a `disclosed` entry, the opaque reference to the party a view or copy was disclosed to. Custody is not transferred.

Kind:     Field
Field of: the entry
Projects: recipient_ref

#### Metadata

Optional opaque data carried on a genesis (`originated`/`received`) entry — e.g., a link to pre-intake provenance for a `received` artifact.

Kind:     Field
Field of: the entry
Projects: metadata

#### Genesis Type

The [Originate] argument selecting the genesis entry's [Event Type] — exactly `originated` or `received` (else [Invalid Genesis Type]). Consumed at genesis; not stored as a field distinct from [Event Type].

Kind:         Parameter
Parameter of: Originate
Projects:     genesis_type

#### Open

The active state of a chain: entries may be appended and the chain has exactly one [Current Custodian]. The entry state of every chain at [Originate].

Kind:      Member
Member of: the chain state
Role:      Outcome

#### Archived

The terminal, absorbing state of a chain at final disposition (Invariant 6): [Transfer], [Transform], [Disclose], and [Archive] are all rejected, but the chain remains readable. Reached once, via [Archive]. Its name also projects as the `archived` rejection reason the writer actions return against a closed chain — the shared term entry the Decision points name, kept backticked in prose to keep the rejection token distinct from this state anchor.

Kind:      Member
Member of: the chain state
Role:      Outcome
Projects:  archived

#### Invalid Ref

The rejection an action returns when a required reference ([Artifact Ref], [Custodian Ref], [To Custodian Ref], or [Recipient Ref]) is empty, whitespace-only, or over the deployment-pinned length cap — also returned by [Originate] for an over-limit [Metadata] (Edge cases — *Length caps*).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  invalid-ref

#### Invalid Genesis Type

The rejection [Originate] returns when [Genesis Type] is not exactly `originated` or `received`.

Kind:      Member
Member of: the Originate rejection
Role:      Outcome
Projects:  invalid-genesis-type

#### Storage Failure

The rejection any action returns when its store write fails after all preconditions pass; guarantees no partial record is observable (Invariant 9).

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Not Known

The rejection [Transfer], [Transform], [Disclose], [Archive], or [Read] returns when the [Chain Id] references no known chain.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Already Archived

The rejection [Archive] returns when the target chain is already [Archived]. (The same condition reaches [Transfer], [Transform], and [Disclose] as the `archived` rejection — kept a distinct token to avoid colliding with the [Archived] state.)

Kind:      Member
Member of: the Archive rejection
Role:      Outcome
Projects:  already-archived

#### Not Current Custodian

The rejection [Transform], [Disclose], or [Archive] returns when the supplied [Custodian Ref] is not the chain's [Current Custodian] — a prior holder has no write authority.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-current-custodian

#### Invalid Descriptor

The rejection [Transform] returns when the [Transformation Descriptor] is empty, whitespace-only, or over the deployment-pinned length cap — a content field, distinct from [Invalid Ref].

Kind:      Member
Member of: the Transform rejection
Role:      Outcome
Projects:  invalid-descriptor

#### Invalid Query

The rejection [Read] returns when a query parameter is malformed — e.g., a range with start greater than end, or an unknown [Event Type] filter value.

Kind:      Member
Member of: the Read rejection
Role:      Outcome
Projects:  invalid-query

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
[Artifact Ref]: #artifact-ref
[Chain State]: #chain-state
[Current Custodian]: #current-custodian
[Next Sequence Number]: #next-sequence-number
[Entry Id]: #entry-id
[Sequence Number]: #sequence-number
[Event Type]: #event-type
[Custodian Ref]: #custodian-ref
[Recorded At]: #recorded-at
[From Custodian Ref]: #from-custodian-ref
[To Custodian Ref]: #to-custodian-ref
[Transformation Descriptor]: #transformation-descriptor
[Recipient Ref]: #recipient-ref
[Metadata]: #metadata
[Genesis Type]: #genesis-type
[Open]: #open
[Archived]: #archived
[Invalid Ref]: #invalid-ref
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

- **Federal Rules of Evidence 901(b)(9) (Authenticating or Identifying Evidence — Process or System)** — the US evidentiary rule for authenticating physical or electronic evidence via chain-of-custody records. The atom's custody-continuity invariant is the structural basis for authenticating evidence under 901(b)(9): a chain whose [From Custodian Ref] values match the prior [Current Custodian] at every transfer step produces the unbroken sequence courts require for authentication.

The cross-domain structural identity is the atom's core thesis: the pharmaceutical chain of custody, the legal evidence chain, the financial instrument custody record, and the DEA controlled-substance custody log are all instances of the same primitive — one artifact, one current custodian, append-only entries, custody never gaps. This atom is the core of the Chain of Custody composition, `grounded` 2026-06-04.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing identity attestation, tamper-evidence, and retention as separate concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on every action, every rejection reason named.
- **Linear temporal logic** — custody continuity (Invariant 4) and archived-is-terminal (Invariant 6) expressed as temporal properties holding across every reachable state.

---

## Status

`grounded on Final Critique 7 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 7 — 2026-08-26
formal: verified — provenance.als + 1 twin, 2026-06-04
last gate: 2026-08-26 — Final Critique 7, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/provenance.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.39; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, Invariant 1 through 8 keeping their numbers and their sub-rule numbering, every success effect conditioned on a declared `admitted originate` / `admitted transfer` / `admitted transform` / `admitted disclose` / `admitted archive` so no effect binds a refused call (Hard invariant 16), rejection precedence carried by `Operation 11`, `Operation 16` and `Operation 27` rather than by a WHY note, the seven acceptance areas raised to `Check 1.1 through 7.4`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Correction`), the Composition notes prose raised to `Composition note 1 through 8` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into provenance` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk.

- **2026-09-12 — Id uniqueness and the archived read are stated once.** *Chose:* the former Invariant 9 (no id reuse) is carried by `Identity 15` and `Identity 16` in the Identity model, and the former archived-chain-admits-a-read invariant by `Operation 53` on the action surface; the durability invariant took the freed number 9. *Over:* keeping both copies for emphasis. *Because:* Authority 3 — two rules must not claim authority for one proposition, and the identity model is where identity rules sit. Both duplicates were found by the checker, not by a reader.

- **2026-09-12 — The transferred entry carries the custodian pair in place of a single custodian_ref, not beside it.** *Chose:* `State 4` bounded to a non-transferred entry, `State 5` stating the exclusion, `Invariant 7.1` and `Check 1.1` bounded to match. *Over:* the rewrite's `EVERY entry MUST carry a custodian_ref`, which was mine and wrong. *Because:* the prose State section said the single field "is replaced by" the pair, and the preserved [Custodian Ref] term entry says so too — a rewritten rule contradicted a term entry the migration carried across byte-identical. Found by GLM on a first council read of this atom; the witness was the untouched half of the document, which is the argument for preserving term entries verbatim through a migration.

NOTE: End of Provenance.

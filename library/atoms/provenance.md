---
title: Provenance
id: 53
audience: common
---

# Provenance

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Provenance answers one question: who has held this artifact, in what order, from intake to disposition. A chain opens with a genesis entry naming its first custodian and accumulates entries — transfers, transformations, disclosures — until it is archived. Each entry names a custodian, and a transfer names two, the outgoing and the incoming; the chain is append-only; nothing is ever edited.

Order comes from a sequence number, not the clock. A skewed or dishonest clock degrades a timestamp and can change nothing else — which entries are accepted, how they replay, or who holds the artifact now.

The load-bearing rule is continuity: from genesis to archive the chain has exactly one current custodian, never none and never two. A transfer is hand-to-hand — the outgoing custodian is read from the chain's current custodian and never supplied by the caller, so a transferred entry cannot record a false hand-off.

This is the mechanism behind pharmaceutical chain of custody, legal evidence handling, forensic specimen tracking and regulated document lineage. It does not verify that a custodian is who they claim, decide who may call, or seal the chain against an adversary with write access. It holds every chain id it mints.

<details markdown="block">
<summary>WHY</summary>

A regulator's question about a controlled artifact is always the same shape: *prove nobody unaccounted-for held this*. Answering it needs a record where custody has no gaps by construction rather than by diligence — because a gap that can be created will be created, and the one place it must not be creatable is the record that exists to disprove it.

So the atom holds a chain per custody episode, and one rule carries the weight: exactly one current custodian at every point. There is no action that empties custody, none that admits two holders, and none but [Transfer] that moves it. A transfer reads the outgoing side from the chain's current custodian, so the from-field cannot be claimed — which is a stronger guarantee than checking a claim, because there is nothing to check.

A content-agnostic journal cannot express this, and the difference is why Provenance is its own concept rather than a configured stream: a journal has no subject and no custodian. Continuity needs a subject, a holder and a dense sequence; a stream that names no holder cannot prove that no one unaccounted-for held the artifact.

Two disciplines carry the rest. **Order is the sequence number, never the clock** — the clock stamps an annotation and nothing reads it, so an adversarial clock cannot reorder a custody history. And **identity is the chain, never the artifact reference** — the same artifact may lawfully begin a second chain for a second episode, a returned batch or re-introduced exhibit, and identifying by artifact would merge two histories that must stay apart.

</details>

## What it keeps

### The chains

```
Identity 1: The atom MUST identify a chain by the chain id.
Identity 2: The atom MUST identify an entry by the entry id.
Identity 3: The host MUST allocate a chain id at the seam.
Identity 4: The host MUST allocate an entry id at the seam.
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
```

NOTE: watch the allocation ban (Identity 5, Identity 6).

Term chain: one artifact's custody history for one episode, from a genesis entry to a terminal disposition — the record this atom holds.

Term entry: one appended event on a chain, carrying an entry id, a sequence number, an event type, a recording instant and the per-type fields.

Term artifact reference: the opaque reference naming what a chain tracks — an [Artifact Reference]; a property of the chain, never the chain's identity.

Term entry id: the opaque value naming one entry — an [Entry Id]; host-allocated at the seam.

Term custodian reference: the opaque reference naming who holds the artifact — a [Custodian Reference]; compared by exact byte identity.

Term database instance: one named database a call is routed to; chain id uniqueness ranges over one instance.

NOTE: watch the seam citation (Term seam, Term transition).

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
State 18: The chain's entries IS AUTHORITATIVE FOR the current custodian.
```

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

The opaque reference of the chain's single current holder — a derived projection (cache) of the chain's entries: the [To Custodian Reference] of the latest transferred entry, or the genesis [Custodian Reference]. Non-null while the chain exists; changes only on [Transfer]. On any disagreement the chain's replayed entries are authoritative (State 18).

Kind:       Field
Field of:   the chain
Projection: current_custodian

#### Next Sequence Number

The chain's own counter, beginning at 1 and incrementing by one per successful entry write.

Kind:       Field
Field of:   the chain
Projection: next_sequence_number

#### Entry Id

The opaque, immutable, system-generated identity of a custody entry — assigned at append, unique within the chain, never reused (Invariant 1, Identity 16).

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

#### Open

The active state of a chain: entries may be appended and the chain has exactly one [Current Custodian]. The entry state of every chain at [Originate].

Kind:      Member
Member of: the chain state
Role:      Outcome

#### Archived

The terminal, absorbing state of a chain at final disposition (Invariant 6): [Transfer], [Transform], [Disclose], and [Archive] are all rejected, but the chain remains readable. Reached once, via [Archive]. The archived rejection [Transfer], [Transform] and [Disclose] answer against a closed chain (Operation 12 through 14) is an arm of their refuses lines spelled as this member projects, so every build answers the one token archived.

Kind:       Member
Member of:  the chain state
Role:       Outcome
Projection: archived

Term event type: originated | received | transferred | transformed | disclosed | archived — an [Event Type], set at append and never changed.

Term chain state: open | archived — accepting entries, or at terminal disposition. A [Chain State].

Term current custodian: the to custodian reference of the chain's latest transferred entry, or the genesis entry's custodian reference where no transfer has landed — a [Current Custodian]; a projection of the chain's entries, cached as chain state so a guard need not replay.

Term sequence number: the strictly increasing integer an entry takes at append — a [Sequence Number]; the chain's order source, and never taken from a clock.

Term next sequence number: the counter an appending action takes a sequence number from — a [Next Sequence Number]; begins at one and rises by one per append.

Term recording instant: the instant an entry was appended — a [Recording Instant]; a best-effort annotation, and never an order source.

## What people do

### Every action

```
Operation 5: An admitted originate MUST record EXACTLY ONE chain.
Operation 6: An admitted originate MUST append the genesis entry.
Operation 7: An admitted originate MUST set the genesis entry's event type to the call's genesis type.
Operation 8: An admitted originate MUST stand the chain in open.
Operation 9: An admitted originate MUST answer the chain id.
Operation 10: IF the chain id names no chain THEN an addressed action MUST answer not-known.
Operation 11: An addressed action MUST answer not-known ONLY IF the chain id names no chain.
Operation 19: An admitted transfer MUST read from custodian reference from the current custodian.
Operation 20: An admitted transfer MUST append a transferred entry.
Operation 21: An admitted transfer MUST set the current custodian to to custodian reference.
Operation 23: IF custodian reference EQUALS blank THEN a custodian-guarded action MUST answer invalid-ref.
Operation 26: IF custodian reference DOES NOT EQUAL the current custodian THEN a custodian-guarded action MUST answer not-current-custodian.
Operation 28: An admitted transform MUST append a transformed entry.
Operation 29: An admitted disclose MUST append a disclosed entry.
Operation 30: An admitted archive MUST append an archived entry.
Operation 31: An admitted archive MUST stand the chain in archived.
Operation 32: An admitted archive MUST NOT change the current custodian.
Operation 33: An admitted transform MUST NOT change the current custodian.
Operation 34: An admitted disclose MUST NOT change the current custodian.
Operation 36: An appending action MUST take the entry's sequence number from next sequence number.
Operation 37: An appending action MUST raise next sequence number by one.
Operation 39: An appending action MUST answer the entry id.
Operation 40: An appending action MUST stamp recording instant from the injected now.
Operation 41: IF the database refuses the write THEN an appending action MUST answer storage-failure.
Operation 42: A refused action MUST leave the chain as the call found the chain.
Operation 43: A refused action MUST NOT append an entry.
Operation 44: A refused action MUST NOT take a sequence number.
Operation 58: An ordering rule MUST NOT rest on recording instant.
Operation 61: An admitted originate MUST set the genesis entry's metadata to the call's metadata.
Operation 62: An admitted originate MUST set the chain's artifact reference to the call's artifact reference.
Operation 63: An admitted originate MUST set the genesis entry's custodian reference to the call's custodian reference.
Operation 64: An admitted transform MUST set the transformed entry's transformation descriptor to the call's transformation descriptor.
Operation 65: An admitted disclose MUST set the disclosed entry's recipient reference to the call's recipient reference.
Operation 66: An admitted transfer MUST set the transferred entry's event type to transferred.
Operation 67: An admitted transfer MUST set the transferred entry's from custodian reference to the current custodian the entry found.
Operation 68: An admitted transfer MUST set the transferred entry's to custodian reference to the call's to custodian reference.
Operation 69: An admitted transform MUST set the transformed entry's event type to transformed.
Operation 70: An admitted transform MUST set the transformed entry's custodian reference to the call's custodian reference.
Operation 71: An admitted disclose MUST set the disclosed entry's event type to disclosed.
Operation 72: An admitted disclose MUST set the disclosed entry's custodian reference to the call's custodian reference.
Operation 73: An admitted archive MUST set the archived entry's event type to archived.
Operation 74: An admitted archive MUST set the archived entry's custodian reference to the call's custodian reference.
Operation 75: An admitted originate MUST set the current custodian to the call's custodian reference.
```

NOTE: watch the integer range (Operation 48, Operation 60).

NOTE: watch the optional field no rule records (Operation 61).

NOTE: watch the required input no rule records (Operation 62, Operation 63, Operation 64, Operation 65, Operation 68, Operation 70, Operation 72, Operation 74).

NOTE: Operation 39 binds the four appending actions whose signatures answer the entry id, [Transfer], [Transform], [Disclose] and [Archive], and not [Originate], whose signature answers the chain id (Operation 9; GRACE-lang Closed vocabulary 29).

Term writer action: an appending action — [Originate], [Transfer], [Transform], [Disclose] or [Archive]; [Read] is no writer action.

Term refused action: an action whose call a rule of this pattern refuses, answering a refusal code and writing nothing.

Term ordering rule: a rule that places one entry before another; the sequence number places entries, never the recording instant (Operation 58).

Term entry count: the number of entries a chain holds.

Term chain count: the number of chains the database holds.

Term genesis type: the call input selecting a genesis entry's event type — a [Genesis Type]; an input name, never a stored field.

Term genesis types: originated | received — what a genesis entry's event type may be.

Term event types: the six members of event type, cited here from that declaration (Closed vocabulary 15).

Term addressed action: any action carrying a chain id — every action but [Originate].

Term custodian-guarded action: [Transform] | [Disclose] | [Archive] — the three an attribution guard covers.

Term appending action: [Originate] | [Transfer] | [Transform] | [Disclose] | [Archive] — every action but [Read].

Term chain-state rejection: the archived answer [Transfer], [Transform] and [Disclose] give against a closed chain, and the already-archived answer [Archive] gives.

Term admitted originate: an [Originate] call the action admits (Execution Contract Read 4).

Term admitted transfer: a [Transfer] call the action admits (Execution Contract Read 4).

Term admitted transform: a [Transform] call the action admits (Execution Contract Read 4).

Term admitted disclose: a [Disclose] call the action admits (Execution Contract Read 4).

Term admitted archive: an [Archive] call the action admits (Execution Contract Read 4).

Term entry sequence: what [Read] answers — the chain's entries the query matches, as Operation 46 orders them.

Term filter axes: sequence number | recording instant | event type — the three axes a query filters a chain's entries on, a filter keyed by the projection of the field its axis names, and a filter on sequence number or recording instant carrying a range, written start first and end second.

NOTE: watch the wire layer (Term filter axes).

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| custodian-guarded | custodian reference present and not the current custodian | [Not Current Custodian] | none (Operation 26) |
| any addressed action | id names nothing | [Not Known] | none (Operation 10) |
| any appending action | database refuses | [Storage Failure] | none (Operation 41 through 44) |
| custodian-guarded | a blank custodian reference | [Invalid Reference] | none (Operation 23) |
| any appending action | a reference over the maximum length | [Invalid Reference] | none (String 7) |
| any action | the database cannot be read | state-unavailable | none (Execution Contract Read 1) |

The same call against the chain while it stood open, after custody had moved to `pharm-hosp-9` → not-current-custodian (Operation 26).

#### Invalid Reference

The rejection an action returns when a required reference ([Artifact Reference], [Custodian Reference], [To Custodian Reference], or [Recipient Reference]) is empty, whitespace-only, or over the deployment-pinned length cap (String 7) — also returned by [Originate] for an over-limit [Metadata] (String 9).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-ref

#### Storage Failure

The rejection an appending action returns when its database write fails after all preconditions pass; guarantees no partial record is observable (Operation 42 through 44).

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

#### Not Current Custodian

The rejection [Transform], [Disclose], or [Archive] returns when the supplied [Custodian Reference] is not the chain's [Current Custodian] — a prior holder's call on any of the three lands no entry; [Transfer] guards no caller (Operation 22).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-current-custodian

### Originate

#### Originate

The behavior that opens a new chain for an artifact: it writes the genesis entry (`sequence_number = 1`) with the selected [Genesis Type], records the [Artifact Reference], sets [Current Custodian] to the genesis [Custodian Reference], and returns a fresh [Chain Id]. Rejected for an empty reference ([Invalid Reference]), a bad [Genesis Type] ([Invalid Genesis Type]), or a failed write ([Storage Failure]).

Kind: Operation

```
originate(artifact_ref, custodian_ref, genesis_type, optional metadata)
  answers chain_id
  refuses invalid-ref | invalid-genesis-type | storage-failure
```

```
Operation 1: IF artifact reference EQUALS blank THEN [Originate] MUST answer invalid-ref.
Operation 2: IF custodian reference EQUALS blank THEN [Originate] MUST answer invalid-ref.
Operation 3: IF genesis type IS NOT IN the genesis types THEN [Originate] MUST answer invalid-genesis-type.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Originate] | refs present, genesis type admitted | the new chain id | a chain opens, genesis entry at sequence one (Operation 5 through 9, Operation 61 through 63, Operation 75) |
| [Originate] | a blank reference | [Invalid Reference] | none (Operation 1, Operation 2) |
| [Originate] | genesis type outside the two | [Invalid Genesis Type] | none (Operation 3, Execution Contract Refusal 1) |
| [Originate] | metadata over the maximum length | [Invalid Reference] | none (String 9) |

`originate("sample-99", custodian_ref: "", genesis_type: originated)` → invalid-ref. No chain is recorded (Operation 2, Operation 43).

`originate("sample-77", "lab-2", genesis_type: imported)` → invalid-genesis-type. `imported` stands outside the genesis types (Operation 3).

#### Genesis Type

The [Originate] argument selecting the genesis entry's [Event Type] — exactly originated or received (else [Invalid Genesis Type]). Consumed at genesis; not stored as a field distinct from [Event Type].

Kind:         Parameter
Parameter of: Originate
Projection:   genesis_type

#### Invalid Genesis Type

The rejection [Originate] returns when [Genesis Type] is not exactly originated or received.

Kind:       Member
Member of:  the Originate rejection
Role:       Outcome
Projection: invalid-genesis-type

### Transfer

#### Transfer

The behavior that records a hand-to-hand change of custody on an [Open] chain: it appends a transferred entry whose [From Custodian Reference] is read from [Current Custodian] (never caller-supplied) and whose [To Custodian Reference] is the new holder, then updates [Current Custodian]. Returns an [Entry Id].

Kind: Operation

```
transfer(chain_id, to_custodian_ref)
  answers entry_id
  refuses not-known | archived | invalid-ref | storage-failure
```

```
Operation 12: IF the chain state EQUALS archived THEN [Transfer] MUST answer archived.
Operation 17: IF to custodian reference EQUALS blank THEN [Transfer] MUST answer invalid-ref.
Operation 18: [Transfer] MUST NOT accept a from custodian reference from the caller.
Operation 22: [Transfer] MUST NOT guard a call on the caller's custodian reference.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Transfer] | open chain, to custodian reference present | the entry id | transferred entry; the from-side read from the current custodian; custody moves; every recorded entry's fields and sequence number stand (Operation 19 through 21, Operation 66 through 68, Invariant 1.1, Invariant 2.2) |
| [Transfer], [Transform] or [Disclose] | chain is archived | [Archived] | none (Operation 12 through 14) |
| [Transfer] | a blank to custodian reference | [Invalid Reference] | none (Operation 17) |

`archive("chain-0041", "pharm-hosp-9")` against the archived chain → already-archived — a distinct reason from the archived that [Transfer], [Transform] and [Disclose] answer, so a retrying archiver learns the work is done rather than refused (Operation 15).

`transfer("chain-0107", "forensic-lab-12")` while the database's write path is down → storage-failure. Every precondition passed and the write did not; no entry is appended, no sequence number is taken, and the current custodian holds its prior value (Operation 41 through 44, Execution Contract Refusal 1).

### Transform

#### Transform

The behavior by which the current custodian records a transformation of the artifact on an [Open] chain, appending a transformed entry that carries a [Transformation Descriptor]. [Current Custodian] is unchanged; guarded by [Not Current Custodian].

Kind: Operation

```
transform(chain_id, custodian_ref, transformation_descriptor)
  answers entry_id
  refuses not-known | archived | invalid-ref | invalid-descriptor | not-current-custodian | storage-failure
```

```
Operation 13: IF the chain state EQUALS archived THEN [Transform] MUST answer archived.
Operation 24: IF transformation descriptor EQUALS blank THEN [Transform] MUST answer invalid-descriptor.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Transform] | open chain, refs present, custodian current | the entry id | transformed entry; custody unchanged; every recorded entry's fields and sequence number stand (Operation 28, Operation 33, Operation 64, Operation 69, Operation 70, Invariant 1.1, Invariant 2.2) |
| [Transform] | a blank transformation descriptor | [Invalid Descriptor] | none (Operation 24) |
| [Transform] | a transformation descriptor over the maximum length | [Invalid Descriptor] | none (String 8) |

`transform("chain-0041", "manuf-lab-7", "added label update")` against the archived pharmaceutical chain → archived. The chain-state rejection precedes the attribution guard, so the caller learns the chain is closed rather than that they are not the custodian (Operation 13, Execution Contract Refusal 1).

`transform("chain-0107", "forensic-lab-12", "   ")` → invalid-descriptor. A whitespace-only descriptor EQUALS blank (Operation 24, String 5).

#### Invalid Descriptor

The rejection [Transform] returns when the [Transformation Descriptor] is empty, whitespace-only, or over the deployment-pinned length cap — a content field, distinct from [Invalid Reference].

Kind:       Member
Member of:  the Transform rejection
Role:       Outcome
Projection: invalid-descriptor

### Disclose

#### Disclose

The behavior by which the current custodian records that the artifact was disclosed to a [Recipient Reference] on an [Open] chain, appending a disclosed entry. Custody is not transferred; [Current Custodian] is unchanged. Records only the custody-timeline fact, not the disclosure's scope or authority (that belongs to a pattern that records a disclosure's scope).

Kind: Operation

```
disclose(chain_id, custodian_ref, recipient_ref)
  answers entry_id
  refuses not-known | archived | invalid-ref | not-current-custodian | storage-failure
```

```
Operation 14: IF the chain state EQUALS archived THEN [Disclose] MUST answer archived.
Operation 25: IF recipient reference EQUALS blank THEN [Disclose] MUST answer invalid-ref.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Disclose] | open chain, refs present, custodian current | the entry id | disclosed entry; custody unchanged; every recorded entry's fields and sequence number stand (Operation 29, Operation 34, Operation 65, Operation 71, Operation 72, Invariant 1.1, Invariant 2.2) |
| [Disclose] | a blank recipient reference | [Invalid Reference] | none (Operation 25) |

### Archive

#### Archive

The behavior by which the current custodian brings an [Open] chain to terminal disposition, appending an archived entry and transitioning [Chain State] to [Archived]. Absorbing thereafter (Invariant 6).

Kind: Operation

```
archive(chain_id, custodian_ref)
  answers entry_id
  refuses not-known | already-archived | invalid-ref | not-current-custodian | storage-failure
```

```
Operation 15: IF the chain state EQUALS archived THEN [Archive] MUST answer already-archived.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Archive] | open chain, custodian current | the entry id | archived entry; chain closes; custody unchanged; every recorded entry's fields and sequence number stand (Operation 30 through 32, Operation 73, Operation 74, Invariant 1.1, Invariant 2.2) |
| [Archive] | chain is archived | [Already Archived] | none (Operation 15) |

#### Already Archived

The rejection [Archive] returns when the target chain is already [Archived] (Operation 15). The same condition answers [Transfer], [Transform] and [Disclose] with the archived rejection (Operation 12 through 14); [Archive] answers a token of its own, so a retrying archiver learns the work is done rather than refused.

Kind:       Member
Member of:  the Archive rejection
Role:       Outcome
Projection: already-archived

### Read

#### Read

The read-only query returning a chain's entries in [Sequence Number] ascending order (optionally filtered). Never transitions. Rejected for an unknown chain ([Not Known]) or a malformed query ([Invalid Query]).

Kind: Operation

```
read(chain_id, optional query)
  answers entry_sequence
  refuses not-known | invalid-query
```

```
Operation 46: [Read] MUST answer the chain's entries in sequence number ascending order.
Operation 47: [Read] MUST answer an empty entry sequence for a well-formed query no entry matches.
Operation 48: IF a sequence number range's start EXCEEDS the range's end THEN [Read] MUST answer invalid-query.
Operation 49: IF a query's event type IS NOT IN the event types THEN [Read] MUST answer invalid-query.
Operation 50: [Read] MUST NOT write.
Operation 51: [Read] MUST NOT answer storage-failure.
Operation 53: [Read] MUST NOT answer archived.
Operation 59: IF the query is malformed THEN [Read] MUST answer invalid-query.
Operation 60: IF a recording instant range's end PRECEDES the range's start THEN [Read] MUST answer invalid-query.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the chain |
|---|---|---|---|
| [Read] | a well-formed query, any chain state | the matching entries, in sequence number order | none (Operation 46, Operation 53) |
| [Read] | an inverted range, a range missing an end, an unknown event type, or a filter keyed by no axis's projection | [Invalid Query] | none (Operation 48, Operation 49, Operation 59, Operation 60) |

`read("chain-9999")` → not-known (Operation 10).

`read("chain-0041", {sequence_number: [5, 2]})` → invalid-query. The caller corrects the query rather than reading an empty answer as *no entries matched* (Operation 47, Operation 48).

#### Invalid Query

The rejection [Read] returns when a query is malformed — e.g., a range with start greater than end, an unknown [Event Type] filter value, or a filter keyed by no axis's projection.

Kind:       Member
Member of:  the Read rejection
Role:       Outcome
Projection: invalid-query

## What is and what should never be (Invariants)

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
  Invariant 4.4: EVERY transferred entry's to custodian reference MUST equal the current custodian the entry set.
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
  Invariant 10.1: The chain count MUST NOT fall under the atom's actions.
  ```

---

## When something happens

### Concurrency

```
Concurrency 2: EVERY serialized transfer against one open chain MUST append.
Concurrency 4: A host needing a transfer conditional on the current custodian MUST serialize the host's own calls.
```

### Correction by append

```
Correction 1: The atom MUST NOT edit an entry.
Correction 2: The atom MUST NOT remove an entry.
Correction 3: A caller correcting an entry of an open chain MUST call [Transform].
Correction 4: A caller's correcting [Transform] call MUST carry a transformation descriptor that names the corrected entry's sequence number.
```

---

## While something is so

### Clock dependence

```
Clock dependence 1: A rejection MUST NOT rest on now.
Clock dependence 2: A guard MUST NOT read now.
```

### Clock semantics

```
Clock semantics 4: A guard MUST NOT rest on recording instant.
```

### String policy

```
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only string input as blank.
String 7: IF a reference EXCEEDS the maximum length THEN the action MUST answer invalid-ref.
String 8: IF transformation descriptor EXCEEDS the maximum length THEN [Transform] MUST answer invalid-descriptor.
String 9: IF metadata EXCEEDS the maximum length THEN [Originate] MUST answer invalid-ref.
```

Term reference: artifact reference, custodian reference, to custodian reference OR recipient reference — every string input naming a party or an artifact, as Execution Contract Logic confinement 13 canonicalizes each at the seam.

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the chain records PER Execution Contract Database 1 through 4, Execution Contract Database 7, Execution Contract Read 1 through 4, Execution Contract Refusal 1 and Execution Contract Query 1 through 4.
Capability requirement 6: The deployment MAY declare a maximum length per string input PER Execution Contract Input 2.
Capability requirement 7: The deployment MUST declare which composing patterns the deployment wired in.
```

NOTE: watch the deployment's composition note (Capability requirement 7).

Term seam: the atom's I/O (input and output) boundary; the host injects the clock reading, the chain id and the entry id here.

Term transition: the atom's evaluation of one call against the chain records.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term query: what a read asks for beside the chain id; any combination of the filter axes, a filter on another axis making the query malformed.

Term string input: artifact reference, custodian reference, to custodian reference, recipient reference, transformation descriptor OR metadata — every caller-supplied string this atom accepts.

Term maximum length: the cap on one string input, each string input carrying its own, measured in Unicode code points; 1,024 code points for each where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs custodian references.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key chain id; carried by chains.

## Left to others

```
Non-goal 1: The atom MUST NOT confirm that a custodian reference names a credentialed party.
Deleted: Non-goal 2. Non-goal 1 owns it: the atom confirms no custodian, and which pattern attests an actor is the app's choice.
Non-goal 3: The atom MUST NOT decide who may call an action.
Deleted: Non-goal 4. Non-goal 3 owns it: the atom decides no caller's authority; the app's permission does.
Non-goal 5: The atom MUST NOT record a disclosure's scope.
Non-goal 6: The atom MUST NOT record a disclosure's authority.
Deleted: Non-goal 7. Non-goal 5 owns it: the atom records no disclosure's scope, and which pattern does is the app's choice.
Non-goal 8: The atom MUST NOT claim a custody the chain's entries do not record.
Non-goal 9: The atom MUST NOT offer an amendment entry.
Non-goal 10: The atom MUST NOT offer a supersedes link between two entries.
Non-goal 11: The atom MUST NOT offer a view that resolves a correction.
Non-goal 12: The atom MUST NOT detect a rewrite under the database.
Deleted: Non-goal 13. Non-goal 12 owns it: the atom detects no rewrite, and which pattern makes records tamper-evident is the app's choice.
Non-goal 14: The atom MUST NOT bound a chain's retention.
Deleted: Non-goal 15. Non-goal 14 owns it: the atom bounds no retention, and which pattern does is the app's choice.
Non-goal 16: The atom MUST NOT record a chain derived from a second chain.
Non-goal 17: The atom MUST NOT record two current custodians on one chain.
Non-goal 18: The atom MUST NOT interpret the artifact's medium.
Non-goal 19: The atom MUST NOT dispose of a chain.
Deleted: Non-goal 20. Non-goal 19 owns it: the atom disposes of no chain, and which pattern disposes lawfully is the app's choice.
Non-goal 21: The atom MUST NOT offer a read keyed by artifact reference.
Non-goal 22: The atom MUST NOT offer a compare-and-swap arm on [Transfer].
Non-goal 23: A deployment needing a verifiable time anchor MUST compose a trusted timestamping pattern.
```

NOTE: the owners — a pattern that attests actors (Non-goal 1, Composition note 3); the app's permission (Non-goal 3, Composition note 2); a pattern that records a disclosure's scope and authority (Non-goal 5, Non-goal 6, Composition note 6); a separate chain, or an external record the host links through the genesis metadata (Non-goal 8, State 9); Correction 3 and Correction 4, a correction appended as a transformed entry naming the corrected entry's sequence number (Non-goal 9 through 11); a pattern that makes records tamper-evident (Non-goal 12, Composition note 4); a pattern that bounds retention (Non-goal 14, Composition note 5); a composing pattern (Non-goal 16, Composition note 7); a pattern that disposes of records lawfully (Non-goal 19); the host (Non-goal 18, Non-goal 21; Non-goal 22, Concurrency 4).

---

```
Composition note 2: A composing pattern MUST own the authorization of a call.
Composition note 3: A composing pattern MUST own the attestation binding a custodian reference to an actor.
Composition note 4: A composing pattern MUST own the tamper seal over the chain's entries.
Composition note 5: A composing pattern MUST own the retention of the chain records.
Composition note 6: A composing pattern MUST own a disclosure's scope and authority.
Composition note 7: A composing pattern MUST own the relationship between two chains.
```

## Example

### Pharmaceutical — a batch from manufacture to dispensing

A manufacturer opens the chain: `originate(artifact_ref: "batch-x91", custodian_ref: "manuf-lab-7", genesis_type: originated)` → `chain-0041`. The genesis entry takes `sequence_number: 1` and the chain stands open with `manuf-lab-7` current (Operation 5 through 9, Operation 63).

`transfer("chain-0041", to_custodian_ref: "dist-region-3")` → `e2`. The entry records `from_custodian_ref: "manuf-lab-7"` — read from the current custodian, never from the caller (Operation 18, Operation 19, Operation 67). `transfer("chain-0041", "pharm-hosp-9")` → `e3`. The pharmacist records the dispense: `transform("chain-0041", "pharm-hosp-9", "dispensed 10mg dose into unit D44")` → `e4`, then closes it: `archive("chain-0041", "pharm-hosp-9")` → `e5`. The chain stands archived.

A regulator asks whether custody was unbroken. `read("chain-0041")` answers five entries in sequence order. Every transferred entry's from custodian reference equals the prior entry's to custodian reference, or the genesis custodian reference for the first transfer. Invariant 4 is the structural answer.

Weeks later the hospital returns part of the batch for re-inspection, and the return opens a second chain for the same artifact rather than reopening the archived one (Identity 10, Invariant 6): `originate(artifact_ref: "batch-x91", custodian_ref: "qa-returns-2", genesis_type: received, metadata: "returned by pharm-hosp-9; earlier custody in chain-0041")` → `chain-0052`. Its genesis entry takes `sequence_number: 1` with event type received and `qa-returns-2` as the first custodian (Operation 5 through 9, Operation 63). The chain records custody from intake forward; what came before intake stays in `chain-0041`, which the genesis metadata names (State 9, Operation 61, Non-goal 8).

### Legal evidence — a physical exhibit

`originate(artifact_ref: "exhibit-A", custodian_ref: "det-r.james", genesis_type: originated)` → `chain-0107`. The exhibit moves to the evidence room (`e2`), then the lab (`e3`). The lab records its work: `transform("chain-0107", "forensic-lab-12", "fingerprint-lifted; DNA-sample-taken; original-exhibit-intact")` → `e4`. It returns to the evidence room (`e5`). The chain stands open pending trial.

Defense counsel claims an undocumented handler between the detective and the lab. `read("chain-0107")` answers five entries in sequence order; every transferred entry's from custodian reference equals the current custodian the entry found, and every entry names a custodian (Invariant 4, Invariant 7). The records show no intermediary: custody is set only by an admitted originate and an admitted transfer (Operation 75, Operation 21), so an unrecorded party was never the current custodian, and no entry names one as the custodian of a transformation or as the sender of a transfer.

### Regulated adversarial scenarios

- **Regulator audit.** An FDA (US Food and Drug Administration) inspector asks for the complete chain of custody for `batch-x91` under 21 CFR (Code of Federal Regulations) Part 211. `read("chain-0041")` answers the ordered sequence; the inspector clears Check 1.1 through 7.4 provably, from those records and their committed versions (Execution Contract Generation acceptance 1).
- **Disputed transaction.** The defense rebuttal above rests on two invariants together: custody continuity, because from custodian reference is read from the current custodian and cannot be supplied (Invariant 4, Operation 18), and custodian presence, because no entry may name an empty custodian (Invariant 7).
- **Breach investigation.** An investigator brackets an anomaly window generously: `read("chain-0041", {recorded_at: ["2026-02-27T00:00:00Z", "2026-03-17T23:59:59Z"]})`. A wall-time filter is a convenience over a best-effort annotation and never an ordering claim (Operation 58), so the window is checked against an unfiltered read — the filtered window's first and last entries are located in the full sequence and their sequence-adjacent neighbours checked to fall outside the bracket. The sequence is dense (Invariant 5), so the run from the window's first entry to its last holds every entry appended between them, one whose skewed recording instant the filter missed among them; an entry outside the run whose skewed recording instant fell outside the bracket stays outside it, a miss the generous bracket narrows and no record rules out. The custodian in force at any point is then exactly determined by replaying the preceding entries.

---

## Source

Provenance is an infrastructure primitive with regulatory anchoring across pharmaceutical, legal, and financial domains:

- **ISO 23081 (Information and documentation — Managing metadata for records)** — the International Organization for Standardization's standard on records-management metadata. Provenance is a required element in ISO 23081-compliant records; the atom's chain-of-custody entries map directly to the origin, transfer, and transformation metadata elements ISO 23081 specifies.

- **W3C (the World Wide Web Consortium) PROV (Provenance Data Model — W3C's RDF (Resource Description Framework)-based standard for representing provenance)** — the atom models the linear single-artifact custody slice of PROV's entity/activity/agent framework. PROV expresses a DAG (directed acyclic graph) of provenance relationships; this atom is the linear spine of a single-entity PROV graph — the `wasGeneratedBy`, `used`, and `wasAttributedTo` relationships along a single entity's chain. The deliberate non-goal of `wasDerivedFrom` (DAG derivation) and artifact splitting (one entity split into several) are both out-of-scope relative to the full PROV model.

- **FDA 21 CFR Part 211 (Current Good Manufacturing Practice — Finished Pharmaceuticals)** — US pharmaceutical manufacturing regulations requiring a chain-of-custody record for drug substances and products from manufacture through distribution. The atom's genesis + transfer + transformation + archive lifecycle is the operational form of Part 211's custodial recording requirements — necessary, not by itself sufficient: the atom contributes the custody record, never the manufacturing practice.

- **DEA 21 CFR Part 1304 (Controlled Substance Inventory Records)** — US Drug Enforcement Administration (DEA) regulations requiring complete, accurate records of the disposition of controlled substances, including every change of custody. Invariant 4 (custody continuity) is the structural form of this requirement — necessary, not by itself sufficient: the atom contributes the record structure, never the inventory itself.

- **SEC Rule 17a-4 (Records to be preserved by certain exchange members, brokers, and dealers)** — US Securities and Exchange Commission rule requiring records to be preserved as originally created, in a non-rewriteable, non-erasable format. The atom's append-only, entry-immutable chain (Invariants 1 and 2) is the structural form of the preservation-as-originally-created requirement — **necessary, not by itself sufficient**: the rule's format requirement is met by the deployment's storage medium and the audit proof by a composed tamper-evidence seal (WORM — write-once, read-many — storage being one realization). The atom contributes the record structure the rule preserves, never the whole compliance claim.

- **Federal Rules of Evidence 901(b)(9) (Authenticating or Identifying Evidence — Process or System)** — the US evidentiary rule for authenticating physical or electronic evidence via chain-of-custody records. The atom's custody-continuity invariant is the structural basis for authenticating evidence under 901(b)(9): a chain whose [From Custodian Reference] values match the prior [Current Custodian] at every transfer step produces the unbroken sequence courts require for authentication.

- **RFC (Request for Comments) 3161 (Time-Stamp Protocol)** — the standard for trusted timestamping. Where a custodial timestamp carries legal force — a chain-of-custody stamp in court proceedings, a pharmaceutical distribution record — RFC 3161 trusted timestamping supplies the verifiable anchor, through a composed trusted timestamping pattern (Non-goal 23).

The cross-domain structural identity is the atom's core thesis: the pharmaceutical chain of custody, the legal evidence chain, the financial instrument custody record, and the DEA controlled-substance custody log are all instances of the same primitive — one artifact, one current custodian, append-only entries, custody never gaps.

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the freestanding-atom posture; the discipline of composing identity attestation, tamper-evidence, and retention as separate concepts rather than absorbing them.
- **Eiffel's design-by-contract** — preconditions on every action, every rejection reason named.
- **Linear temporal logic** — custody continuity (Invariant 4) and archived-is-terminal (Invariant 6) expressed as temporal properties holding across every reachable state.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the chain records and the chain's entries, with their committed versions (Execution Contract Generation acceptance 1).

#### Conformance checks

```
Check 1.1: An auditor MUST find a custodian reference on EVERY non-transferred entry (Invariant 7.1).
Check 1.2: An auditor MUST find a from custodian reference and a to custodian reference and no custodian reference on EVERY transferred entry (State 5, Invariant 7.2).
Check 2.1: An auditor MUST find EXACTLY ONE genesis entry per chain (Invariant 3.1).
Check 2.2: An auditor MUST find EVERY genesis entry standing at sequence number one (Invariant 3.2).
Check 3.1: An auditor MUST replay a chain in sequence number ascending order against a current custodian cursor (Invariant 4.1).
Check 3.2: An auditor MUST find EVERY transferred entry's from custodian reference equal to the cursor the replay carried in (Invariant 4.3).
Check 3.3: An auditor MUST find EVERY custodian-guarded entry's custodian reference equal to the cursor at that entry (Invariant 4.2).
Check 4.1: An auditor MUST find a chain's sequence numbers standing from one to the chain's entry count (Invariant 5.2).
Check 4.2: An auditor MUST reconstruct a chain's order from sequence number alone (Invariant 5.3).
Check 4.3: An auditor MUST find no sequence number repeated within a chain (Invariant 5.1).
Check 5.1: An auditor MUST find no entry in an archived chain following the archived entry's sequence number (Invariant 6.2).
Check 6.1: An auditor MUST find EVERY entry's fields unchanged across EVERY committed version of the entry (Invariant 1.1; Execution Contract Generation acceptance 1).
Check 7.1: An auditor MUST find EVERY entry's event type standing in the event types (Invariant 8.1).
Check 7.2: An auditor MUST find EVERY archived chain's last entry standing at archived (Invariant 8.4).
Check 7.3: An auditor MUST find no entry id repeated within a chain (Identity 16).
Check 7.4: An auditor MUST find no chain id repeated within a database instance (Identity 15).
```

Term cited: chain id, actor id: Declarations.

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 2: A deployment needing a correction cleared MUST read the correcting transformed entry's transformation descriptor beside the corrected entry's sequence number (Correction 4).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern; a caller; a guard; an auditor; a regulator; the database; a chain; an entry; a genesis entry; a transferred entry; a non-transferred entry; a transformed entry; a disclosed entry; an archived entry; a custodian-guarded entry; an addressed action; an appending action; a custodian-guarded action; a writer action; a refused action; an ordering rule; a query; a replay; a rejection; a correction; a string input; a reference; an opaque reference; the chain count; the entry count.

Term records: chain — one artifact's custody history for one episode, carrying chain id, artifact reference, a chain state, a current custodian and next sequence number. entry — one appended event on a chain, carrying entry id, sequence number, event type and recording instant, and the per-type fields custodian reference, from custodian reference, to custodian reference, transformation descriptor, recipient reference and metadata. custodian reference — the actor id a chain or an entry carries for a custodian: the current custodian, the custodian reference and the from and to custodian references.

Term record verbs: identify, allocate, change, carry, stand, answer, record, append, set, read, take, raise, stamp, leave, own, match, normalize, interpret, confirm, admit, offer, govern, route, share, equal, precede, follow, exceed, compare, trim, case-fold, refuse, write, find, replay, reconstruct, repeat, complete, roll back, accept, serialize, name, claim, detect, bound, dispose, decide, compose, declare, wire, guard, rest, apply, supply, inject, fall, remove, edit, reorder, empty, move, cache, run, call, resolve.

Term value sets: event type = originated | received | transferred | transformed | disclosed | archived. genesis types = originated | received. chain state = open | archived. filter axes = sequence number | recording instant | event type. custodian-guarded action = [Transform] | [Disclose] | [Archive]. appending action = [Originate] | [Transfer] | [Transform] | [Disclose] | [Archive].

Term bounds: maximum length (the cap on one string input, each string input carrying its own, measured in Unicode code points, 1,024 for each where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.39 (2026-09-12).

Term terms: chain, entry, artifact reference, entry id, custodian reference, database instance, seam, transition, now, genesis type, genesis types, event type, event types, chain state, current custodian, sequence number, next sequence number, recording instant, from custodian reference, to custodian reference, transformation descriptor, recipient reference, metadata, addressed action, custodian-guarded action, appending action, chain-state rejection, admitted originate, admitted transfer, admitted transform, admitted disclose, admitted archive, query, entry sequence, filter axes, string input, reference, blank, maximum length, committed version.

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

## Status

`done — 2026-11-19` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-19
formal: verified — provenance.als + 6 twins (the static data model, re-derived 2026-11-12 as the entries and chain record versions an ordered sequence of admitted calls leaves, custody replayed by sequence number as Check 3.1 reads it; the 2026-06-04 fact CustodyContinuity, which its checks restated, and its 2 twins gone: Invariant 4.2, 4.3, 4.4, 5.1, 7.1 and 7.2); provenance.tla + 13 twins (the operation sequences, 2026-11-12, while the clock reads any instant, backwards included: Invariant 1.1, 2.1, 2.2, 3.1, 3.2, 3.3, 4.1, 5.2, 5.3, 6.1, 6.2, 8.2, 8.3, 8.4 and 10.1, Operation 42 through 44, with State 11 and 18 checked through them); Invariant 8.1 holds by both models' typing; coverage 2026-11-12 (unit `atoms/provenance.md formal layer`): owed rows: none, 2026-11-12
last gate: 2026-11-19 — Final Critique 14, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at 36366af9 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim (the example leaves [Read]'s order to the Execution Contract) refuted by both triages, since Operation 46 names the order outside the delta set; its seven refining and three rhetorical findings placed two refining cured (the Defense counsel example's reasoning narrowed to what the records show, and the owners NOTE naming Permissions for Composition note 2 and the host for Non-goal 18), the rest refuted (Operation 22, the Terms maximum length, Non-goal 11) or left as wording, and the blind triage's own two refining finds cured (the older "writer" wording of the archived rows against Term writer action, the example's genesis exception); 2026-11-03 — Final Critique 13, frozen at e0a85af — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./provenance.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/provenance.md`.

</details>

NOTE: End of Provenance.

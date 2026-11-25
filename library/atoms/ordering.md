---
title: Ordering
id: 79
audience: common
has_toc: true
toc: true
---

# Ordering

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Ordering keeps the sequence of one list's items: each new item enters at the bottom, one item moves to a new place at a time, and the order reads back, first place to last. It holds the order and nothing about what an item is, who may move it or what the order means.

<details markdown="block">
<summary>WHY</summary>

A list people arrange by hand needs one answer, the same for every reader and every build, to which item comes before which. The items are made and deleted by other atoms, so this atom holds the sequence and nothing else: who may move an item is the app's permission, what the order means is the author's, and who wins a race is the Execution Contract's commit order (Scott, 2026-11-24 3:23 and 3:25 PM Central: the order is per list, a new item goes at the bottom, only the author reorders, and the order is the author's priority).

</details>

## What it keeps

### The sequence

Term sequence: the entries of one list, in order — a [Sequence]; one sequence for each list.

#### Sequence

Holds one entry for each item the list orders, the places running from the first place to the last with none missing. A list id no entry carries holds an empty sequence, and a list whose entries are all taken out holds the same one: the atom keeps no record of an emptied list.

Kind: Type

```
Identity 1: The atom MUST identify a sequence by the sequence's list id.
```

Term entry: one item's position in one sequence — an [Entry]; it carries the list id, the item id and the place.

#### Entry

Written by [Place Item], carried to another place by [Move Item] and taken out by [Remove Item].

Kind: Type

```
Identity 2: The atom MUST identify an entry by the entry's list id and item id.
```

Term item id: the value naming an item an entry orders, minted by another atom and compared by byte identity — an [Item Id]; the atom reads nothing in it.

#### Item Id

Stored as supplied and compared by byte identity; whether it names a real item is another atom's.

Kind:       Field
Field of:   Entry
Projection: item_id

Term place: a whole number, the position of an entry in its sequence, counted from 1 at the first place — a [Place].

#### Place

Held by each entry, running from the first place to the last.

Kind:       Field
Field of:   Entry
Projection: place

Term first place: the place 1, where the first entry of a sequence stands.

Term last place: the place equal to the number of entries a sequence holds, and 0 where it holds none.

Term bottom: the place one after the last place, where a new entry enters.

```
State 1: EVERY entry MUST carry list id, item id and place.
```

### Ordering

The six rules of the sequence, each cited by the action that carries it.

```
Ordering 1: For each list, the atom MUST hold ONE sequence, the places running from the first place to the last with none missing.
Ordering 2: A placed item that holds no entry in the sequence MUST enter at the bottom.
Ordering 3: A move MUST carry ONE entry to a place from the first place to the last.
Ordering 4: A remove MUST take the item's entry out.
Ordering 5: The atom MUST NOT judge whether a list id names a real list.
Ordering 6: The atom MUST NOT judge whether an item id names a real item.
```

## What people do

### Every action

```
Operation 1: IF the list id OR the item id EQUALS blank THEN a writing action MUST answer invalid-id.
Operation 13: IF an action reads OR writes an entry THEN the entry MUST carry the action's list id.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the sequences |
|---|---|---|---|
| a writing action | an input is no string | invalid-request | none (Execution Contract Input 3) |
| a writing action | list id or item id blank | [Invalid Id] | none (Operation 1) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | the item holds an entry carrying another list id | the call answers as if that entry were absent | none to that entry (Operation 13) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Invalid Id

The refusal of a blank list id or a blank item id (Operation 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-id

#### Storage Failure

The refusal a writing action answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Place Item

Puts an item that holds no entry in the sequence at the bottom of its list's sequence: records the [Entry] at the bottom. An item that already holds an entry in the sequence is left as it is, and the call answers its place as it stands, so the answer tells a caller nothing of whether an entry landed now. Answers the item's place.

Kind: Operation

```
place_item(list_id, item_id)
  answers place
  refuses invalid-request | invalid-id | storage-failure
```

```
Operation 2: [Place Item] MUST answer the place of the item's entry.
Operation 9: IF the item holds an entry in the sequence THEN [Place Item] MUST NOT write.
```

| Call | Case | Answer | Effect on the sequences |
|---|---|---|---|
| [Place Item] | the item holds no entry in the sequence | its new place, at the bottom | one entry lands (Ordering 2, Operation 2, Ordering 1) |
| [Place Item] | the item holds an entry in the sequence | its place, as it stands | none, no write (Operation 9, Operation 2) |

- `place_item("l1", "a")`, then `place_item("l1", "b")` — answers 1, then 2: each item enters at the bottom.

### Move Item

Carries one item's entry to another place in its sequence; every other entry keeps its relative order. Answers the item's new place.

Kind: Operation

```
move_item(list_id, item_id, place)
  answers place
  refuses invalid-request | invalid-id | unknown-item | invalid-place | storage-failure
```

```
Operation 3: IF the item holds no entry in the sequence THEN [Move Item] MUST answer unknown-item.
Operation 4: IF the place IS NOT a whole number from the first place to the last THEN [Move Item] MUST answer invalid-place.
Operation 10: [Move Item] MUST answer the entry's new place.
Operation 12: IF the place EQUALS the entry's place THEN [Move Item] MUST NOT write.
```

| Call | Case | Answer | Effect on the sequences |
|---|---|---|---|
| [Move Item] | the item holds an entry in the sequence, the place lies in the sequence and is not the entry's own | the new place | the entry stands at the place, the others keep their order (Ordering 3, Operation 10, Invariant 2.1) |
| [Move Item] | the place is the entry's own | the entry's place | none, no write (Operation 12, Operation 10) |
| [Move Item] | the item holds no entry in the sequence | [Unknown Item] | none (Operation 3) |
| [Move Item] | the place is no whole number from the first place to the last | [Invalid Place] | none (Operation 4) |

- `move_item("l1", "b", 1)` over a sequence of a, b — answers 1: b stands first and a second.
- `move_item("l1", "z", 1)` — rejected as [Unknown Item]: z holds no entry in the sequence.

#### Unknown Item

The refusal of a move for an item that holds no entry in the sequence (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-item

#### Invalid Place

The refusal of a move to a place that is not a whole number from the first place to the last (Operation 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-place

### Remove Item

Takes an item's entry out of its sequence; the sequence closes so its places stay in a run. An item that holds no entry in the sequence is left as it is: the caller is the deletion path, where an earlier call may already have removed it. Answers ok.

Kind: Operation

```
remove_item(list_id, item_id)
  answers ok
  refuses invalid-request | invalid-id | storage-failure
```

```
Operation 5: [Remove Item] MUST answer ok.
Operation 11: IF the item holds no entry in the sequence THEN [Remove Item] MUST NOT write.
```

Term ok: the answer [Remove Item] gives once the call is admitted; it carries nothing.

| Call | Case | Answer | Effect on the sequences |
|---|---|---|---|
| [Remove Item] | the item holds an entry in the sequence | ok | the entry is gone and the sequence closes (Ordering 4, Ordering 1, Operation 5) |
| [Remove Item] | the item holds no entry in the sequence | ok | none, no write (Operation 11, Operation 5) |

### Read Order

Answers a list's item ids in order, first place to last, and changes nothing; an empty list where the sequence holds no entry, a blank list id included, since no entry carries one.

Kind: Operation

```
read_order(list_id)
  answers items(item_id)
```

Term items: the item ids of one sequence, one for each entry, in place order from the first place to the last; an empty list where the sequence holds no entry.

```
Operation 6: [Read Order] MUST answer EVERY entry's item id, first place to last.
Operation 7: [Read Order] MUST answer an empty list for a list id whose sequence holds no entry.
Operation 8: [Read Order] MUST NOT write.
```

| Call | Case | Answer | Effect on the sequences |
|---|---|---|---|
| [Read Order] | the sequence holds entries | their item ids, first place to last | none (Operation 6, Operation 8) |
| [Read Order] | no entry, a blank list id among the cases | an empty list | none (Operation 7) |

## What is and what should never be (Invariants)

- **Invariant 1 — An item stands once in a sequence.**
  ```
  Invariant 1.1: Two entries one sequence carries MUST NOT share an item id.
  ```

- **Invariant 2 — A move or a remove keeps the others' order.**
  ```
  Invariant 2.1: A move MUST NOT change the relative order of the entries the move does not carry.
  Invariant 2.2: A remove MUST NOT change the relative order of the entries the remove leaves.
  ```

## When something happens

### Concurrency

Two calls for one list are serialized in the commit order (Execution Contract Database 2, Order 2): the later reads what the earlier committed, so two moves to one place leave the sequence as the later one carries it. The rules above hold for calls arriving one at a time in that order, and the rules above do not restate it.

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 8, Execution Contract Order 1 through 2, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 AND Execution Contract Input 3.
```

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. [Move Item] takes no caller and checks none (Non-goal 1): who may move an item is the app's permission, gated before the call.

Term need key: key opaque; pairs entries.

Term need key: key list id; pairs sequences.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may change a sequence.
Non-goal 2: The atom MUST NOT hold what an item is.
Non-goal 3: The atom MUST NOT remove an entry when an item is deleted elsewhere.
Non-goal 4: The atom MUST NOT give an order a meaning.
Non-goal 5: The atom MUST NOT keep one list's order per person.
```

NOTE: the owners — the app's permission, gated before the call (Non-goal 1); the atom that holds the items (Non-goal 2); the app's pattern, which removes every entry an item holds as it deletes the item, a glue line (Non-goal 3); the author of the list (Non-goal 4, Non-goal 5).

```
Composition note 1: A composing pattern MUST remove every entry an item holds when the composing pattern deletes the item.
Composition note 2: A composing pattern MUST decide who may move an item, since [Move Item] checks no caller (Non-goal 1).
```

NOTE: composing patterns — none yet.

## Example

An author sets up a list `l1` and adds three tasks: `place_item("l1", "buy-milk")` answers 1, `place_item("l1", "call-bank")` answers 2, `place_item("l1", "book-trip")` answers 3. The author decides the trip comes first: `move_item("l1", "book-trip", 1)` answers 1, and `read_order("l1")` is answered book-trip, buy-milk, call-bank. When buy-milk is deleted elsewhere, `remove_item("l1", "buy-milk")` answers ok, and the order reads book-trip, call-bank with places 1 and 2.

## Source

Ordering is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design; the order of a list is its own concept.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the entries the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY entry carrying list id, item id AND place (State 1).
Check 1.2: An auditor MUST find no two entries sharing a list id and an item id (Invariant 1.1).
Check 1.3: An auditor MUST find the places of each list's entries running from the first place to the last with none missing (Ordering 1).
Check 1.4: An auditor MUST find each entry's first version at the bottom of the list's other entries at that version (Ordering 2).
Check 2.1: An auditor MUST find, across two successive versions of a sequence that hold the same items, one entry whose removal leaves the other entries in the same relative order in both versions (Invariant 2.1).
Check 2.2: An auditor MUST find, across two successive versions of a sequence of which the later holds one entry fewer, the entries both versions hold in the same relative order (Ordering 4, Invariant 2.2).
```

NOTE: EVERY check names the rule the check tests.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; an auditor.

Term records: entry — one item's position in one sequence, carrying list id, item id and place; sequence — the entries of one list, in order.

Term record verbs: identify, carry, hold, keep, share, tell, give, remove, place, move, read, answer, write, change, supply, find, name, close, enter, take, leave, judge, decide.

Term value sets: action rejection — invalid-id | invalid-place | unknown-item | storage-failure.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-24) from GLM's Ordering draft.

Term terms: sequence, entry, item id, place, first place, last place, bottom, items, ok.

Term cited: list id: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Place Item]: #place-item
[Move Item]: #move-item
[Remove Item]: #remove-item
[Read Order]: #read-order
[Sequence]: #sequence
[Entry]: #entry
[Item Id]: #item-id
[Place]: #place
[Invalid Id]: #invalid-id
[Invalid Place]: #invalid-place
[Unknown Item]: #unknown-item
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-25` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-25
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: 2026-11-25 — Final Critique 4, delta (the reach of Final Critique 3's settle, Operation 13 and the case-space row that cites it), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 2f4dd26f — foundational count 0 after the blind second triage, clean, one sample (Linus's report counted 0 foundational, 0 refining and 0 rhetorical and pressed three questions, each of which held under both triages: an entry carrying another list id stays owned by the list whose id it carries (Identity 2), and Operation 13 with its case-space row leaves it as it stands; two actions on two lists sharing one item touch two records, so neither overwrites the other; a read that finds no entry implicates none, so Operation 13 obliges no list id then; the blind second triage (an Opus subagent) found no foundational edge of its own and placed one refining, Kind C, cured: Composition note 1 said a composing pattern removes "an item's entry" when it deletes the item, which read as one entry where Identity 2 and Operation 13 let an item hold one in each list, so it now says every entry the item holds, and the Left to others note that restates it says the same; four points were placed rhetorical, Kind D, and left as written)

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./ordering.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/ordering.md`.

</details>

NOTE: End of Ordering.

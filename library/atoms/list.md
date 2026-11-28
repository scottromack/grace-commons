---
title: List
id: 80
audience: common
---

# List

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

List holds a name, an author and an id for each list an app makes: make a list, rename it, delete it, read it. It holds nothing about the items, nothing about who may rename or delete it, and reads nothing in the author.

<details markdown="block">
<summary>WHY</summary>

Several atoms of an app carry a list id, and none of them made the list, minted its id or held its author, so the id had no owner and "the author" had no home (Scott, 2026-11-24 3:23 PM Central, "the author owns the list", on the design round's finding (c)4). This atom owns the three facts.

</details>

## What it keeps

### The lists

Term list: one name with its author under one list id, the atom holding none of the list's items (Non-goal 2) — a [List Record]; one for each list id while the list stands.

#### List Record

Holds the list id, the name and the author. A list id that no record carries names no list, and a deleted list's record has ended.

Kind: Type

```
Identity 1: The atom MUST identify a list by the list's list id.
Identity 2: The host MUST allocate the list id for [Make List] at the atom's seam.
Identity 3: [Make List] MUST NOT take a list id from the business caller.
Identity 4: The host MUST NOT reuse a list id.
```

Term name: the text a list is called by, held as supplied — a [Name]; the atom reads no meaning in it and compares a name with the list's name only as exact code points, in [Rename List].

#### Name

Set by [Make List] from its input (Execution Contract Input 4) and held as supplied; changed only by [Rename List] (List 4), the one action that writes it, so no rule against the others is stated.

Kind:       Field
Field of:   List Record
Projection: name

Term author: the actor id of the party who made the list — an [Author]; the atom reads nothing in it.

#### Author

Set by [Make List] from its input (Execution Contract Input 4) and held as supplied: this atom declares no reference, so Execution Contract Logic confinement 13 canonicalizes nothing in it; the same actor id is the one every other record that names that party carries.

Kind:       Field
Field of:   List Record
Projection: author

```
State 1: EVERY list MUST carry list id, name and author.
```

### The rules of a list

```
List 1: [Make List] MUST give the list the list id the host allocated for the call.
Deleted: List 2. Execution Contract Input 4 owns it: an admitted [Make List] sets the author field to the author input, and Invariant 2.1 keeps it, so no second rule need say it.
Deleted: List 3. Invariant 2.1 owns it: a list's author never changes between two versions, so no second rule need say it.
List 4: IF the name [Rename List] was given DOES NOT EQUAL the list's name THEN [Rename List] MUST change the list's name.
List 5: An action MUST NOT change a list's list id.
List 6: [Delete List] MUST end the list, so that a later [Read List] answers none.
Deleted: List 7. Non-goal 1 owns it: the atom tells no one who may change a list, so no second rule need say it.
```

## What people do

### Every action

```
Operation 1: IF the list id EQUALS blank THEN [Rename List] and [Delete List] MUST answer invalid-id.
Operation 2: IF the name EQUALS blank THEN [Make List] and [Rename List] MUST answer invalid-name.
Operation 3: IF the author EQUALS blank THEN [Make List] MUST answer invalid-author.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| a writing action | an input is no string | [Invalid Request] | none (Execution Contract Input 3) |
| a writing action | the list id, the name or the author is blank | [Invalid Id], [Invalid Name] or [Invalid Author] | none (Operation 1, Operation 2, Operation 3) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any writing call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Invalid Id

The refusal of a blank list id (Operation 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-id

#### Invalid Name

The refusal of a blank name (Operation 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-name

#### Invalid Author

The refusal of a blank author (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-author

#### Invalid Request

The refusal a writing action answers when an input is malformed, as no string where the input has no declared type (Execution Contract Input 1, Input 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-request

#### Storage Failure

The refusal a writing action answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure (Execution Contract Read 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Make List

Makes a list with a name and an author, and gives it a new list id. Answers the list id.

Kind: Operation

```
make_list(name, author)
  answers list id
  refuses invalid-request | invalid-name | invalid-author | storage-failure
```

```
Operation 4: [Make List] MUST answer the list id [Make List] gave the list.
```

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Make List] | a name and an author | the new list id | one list lands, carrying the name and the author (List 1, Execution Contract Input 4, Operation 4) |

- `make_list("Groceries", "a1")` — answers a list id, say `l1`: the list named Groceries stands with author a1.
- `make_list("Groceries", "a1")` again — answers a second list id, `l2`: two lists may share a name (Name).

### Rename List

Changes one list's name. A rename to the list's own name writes nothing, so that the list's versions record only real changes. Answers ok.

Kind: Operation

```
rename_list(list_id, name)
  answers ok
  refuses invalid-request | invalid-id | invalid-name | unknown-list | storage-failure
```

```
Operation 5: IF no list carries the list id THEN [Rename List] MUST answer unknown-list.
Operation 6: [Rename List] MUST answer ok.
Operation 7: IF the name [Rename List] was given EQUALS the list's name THEN [Rename List] MUST NOT write.
```

Term ok: the answer [Rename List] and [Delete List] give once the call is admitted; it carries nothing.

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Rename List] | the list exists and the name differs | [Ok] | the list's name becomes the name given, its list id and author stay (List 4, Execution Contract Input 4, Invariant 2.1, List 5, Operation 6) |
| [Rename List] | the list exists and the name is its own | [Ok] | none, no write (Operation 7, Operation 6) |
| [Rename List] | no list carries the list id | [Unknown List] | none (Operation 5) |

- `rename_list("l1", "Weekly shop")` — answers ok: the list reads as Weekly shop, still author a1.
- `rename_list("zz", "x")` — rejected as [Unknown List]: no list carries zz.

#### Unknown List

The refusal of a rename for a list id no list carries (Operation 5).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-list

#### Ok

The answer [Rename List] and [Delete List] give once the call is admitted (Operation 6, Operation 8); it carries nothing.

Kind:       Member
Member of:  the action answer
Role:       Outcome
Projection: ok

### Delete List

Ends a list: its record ends, and as no erasure is declared here its earlier versions remain in the database, visible to the auditor (Execution Contract Database 5, Undo 1), and a later read answers none. A list id no list carries is left as it is, since an earlier call may already have deleted it. Answers ok.

Kind: Operation

```
delete_list(list_id)
  answers ok
  refuses invalid-request | invalid-id | storage-failure
```

```
Operation 8: [Delete List] MUST answer ok.
Operation 9: IF no list carries the list id THEN [Delete List] MUST NOT write.
```

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Delete List] | the list exists | [Ok] | the list has ended (List 6, Operation 8) |
| [Delete List] | no list carries the list id | [Ok] | none, no write (Operation 9, Operation 8) |

### Read List

Answers a list's name and author, or none; changes nothing. A list id that no list carries answers none, a blank one, one over its cap (Execution Contract Input 2, Query 5) or one that is no string included.

Kind: Operation

```
read_list(list_id)
  answers found(name, author) | none
```

Term found: the name and author of one list.

Term none: the answer of [Read List] where no list carries the list id; it carries nothing.

```
Operation 10: IF a list carries the list id THEN [Read List] MUST answer the list's name AND author.
Operation 11: IF no list carries the list id THEN [Read List] MUST answer none.
Operation 12: [Read List] MUST NOT write.
```

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Read List] | the list exists | [Found], its name and author | none (Operation 10, Operation 12) |
| [Read List] | no list carries the list id, a blank, over-cap (Execution Contract Input 2, Query 5) or non-string one included, or the list was deleted | [None] | none (Operation 11, Operation 12, List 6) |

#### Found

The answer [Read List] gives when a list carries the list id: the list's name and author (Operation 10).

Kind:       Member
Member of:  the Read List answer
Role:       Outcome
Projection: found

#### None

The answer [Read List] gives when no list carries the list id, a blank, over-cap or non-string one included, and for a list that was deleted (Operation 11, List 6); it carries nothing, and it is no rejection.

Kind:       Member
Member of:  the Read List answer
Role:       Outcome
Projection: none

## What is and what should never be (Invariants)

- **Invariant 1 — A list id names one list for good.**
  ```
  Invariant 1.1: A list id MUST NOT name two list records.
  Invariant 1.2: A list id a deleted list carried MUST NOT name a list again.
  ```

- **Invariant 2 — A list's author never changes.**
  ```
  Invariant 2.1: A list's author MUST NOT change between two versions of the list.
  ```

## When something happens

### Concurrency

Two calls for one list are serialized in the commit order (Execution Contract Database 2, Order 2): so a rename after a delete answers unknown-list (Operation 5) and a read after a rename answers the new name (Operation 10).

### What undoes a write

A [Rename List] is undone by a [Rename List] carrying the earlier name, which the list's earlier versions hold, and a [Make List] is undone by a [Delete List]. A [Delete List] is not undone by this atom: a deleted list stays ended, its list id names no list again (Invariant 1.2), and the author makes a new list (Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 8, Execution Contract Order 1 through 2, Execution Contract Read 1 through 6, Execution Contract Refusal 1 AND Execution Contract Input 1 through 4.
Capability requirement 2: The host MUST supply EVERY list id PER Execution Contract Logic confinement 3, Execution Contract Logic confinement 14 AND Execution Contract Logic confinement 16.
```

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice.

Term need key: key actor id; pairs lists.

## Offers

Term offer key: key list id; carried by lists; ends Delete List; calls Read List.

The app's flow calls the four actions; the key offer names [Delete List] under ends and [Read List] under calls, for the app to call.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may change a list.
Non-goal 2: The atom MUST NOT hold the items of a list.
Non-goal 3: The atom MUST NOT tell whether an author names a real party.
Non-goal 4: The atom MUST NOT take out an item another atom holds.
Non-goal 5: The atom MUST NOT keep a list's order.
Non-goal 6: The atom MUST NOT take a deleted list back.
```

NOTE: the owners — the app's permission, gated before the call (Non-goal 1); the atoms that hold the items (Non-goal 2); the atom that names parties, through the need for an actor id (Non-goal 3); the atoms that hold the items, whose key needs' on end the app calls as [Delete List] ends a list (Non-goal 4); the atom that keeps an order (Non-goal 5); no pattern: a deleted list stays ended (Invariant 1.2), and the author makes a new list (Non-goal 6).

```
Composition note 1: A composing pattern MUST decide who may make a list, who may rename a list AND who may delete a list, since [Make List], [Rename List] and [Delete List] check no caller (Non-goal 1).
Deleted: Composition note 2. The key needs' on end own it: the app calls each needing atom's on end action when [Delete List] ends the list (Bonds Key 3).
```

NOTE: deliberate — [Delete List] answers ok for a list already gone, and the app reads ok and none alike as nothing to do.

NOTE: composing patterns — none yet.

## Example

### A list made, renamed, read and deleted

An author, actor a1, sets up a list: `make_list("Groceries", "a1")` answers `l1`. Later they rename it: `rename_list("l1", "Weekly shop")` answers ok, and `read_list("l1")` is answered Weekly shop and a1. When the week is over, `delete_list("l1")` answers ok, and `read_list("l1")` is answered none. Calls that change nothing leave the lists as they were: `make_list("", "a1")` answers invalid-name and no list lands; `rename_list("zz", "x")` answers unknown-list; `delete_list("zz")` answers ok and writes nothing; `read_list("zz")` is answered none.

## Source

List is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design; a named list that someone made is its own concept.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the lists the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The input a call gave is no record of the database, so that [Make List] carried it as given (Execution Contract Input 4) lives at the seam, outside the auditor's frame. The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY list carrying list id, name AND author (State 1).
Check 1.2: An auditor MUST find no two lists sharing a list id across the committed versions (Identity 4, Invariant 1.1, Invariant 1.2).
Check 1.3: An auditor MUST find every list's author the same in every version of the list (Invariant 2.1).
Check 1.4: An auditor MUST find, across two successive versions of a list whose names differ, the list id and the author unchanged (Invariant 2.1, List 5).
Check 1.5: An auditor MUST find no list record in a version that follows a version that deleted the list (List 6).
```

NOTE: EVERY check names the rule the check tests.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; an auditor; the business caller.

Term records: list — one name with its author under one list id, carrying list id, name and author.

Term record verbs: identify, carry, hold, keep, tell, give, make, rename, delete, read, answer, write, change, supply, find, name, end, judge, decide, allocate, reuse, take, share, remove.

Term value sets: action rejection — invalid-request | invalid-id | invalid-name | invalid-author | unknown-list | storage-failure; the set is what the actions' refuses lines carry, so `state-unavailable`, which a failed read answers and no refuses line lists, is no member.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-25) from Scott's ruling of 2026-11-24 10:50 PM Central.

Term terms: list, name, author, found, none, ok.

Term cited: list id, actor id: Declarations.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Make List]: #make-list
[Rename List]: #rename-list
[Delete List]: #delete-list
[Read List]: #read-list
[List Record]: #list-record
[Name]: #name
[Author]: #author
[Invalid Id]: #invalid-id
[Invalid Name]: #invalid-name
[Invalid Author]: #invalid-author
[Unknown List]: #unknown-list
[Invalid Request]: #invalid-request
[Storage Failure]: #storage-failure
[Ok]: #ok
[Found]: #found
[None]: #none

## Status

`done — 2026-11-25` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-25
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: 2026-11-28 — Final Critique 5, a delta round (diff base f5f4ab98, 2 labels, Capability requirement 2, which cites Execution Contract Logic confinement 16 as 20258c18 changed it, and Term offer key, which bf3c98b8 gave `calls Read List` as the atom's existence read for Bonds Key 26), one reader (Linus opencode-go/beam-free; GRID and EOS not run; the Claude reader off), frozen at e53d8535 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational-rated finding (the offer line's `ends Delete List` leaves a deleted list id open to reuse, with a cure that writes the non-reuse into the offer line) was refuted by both triages: Identity 4, Invariant 1.2 and Capability requirement 2 citing Logic confinement 16 already forbid any reuse, so no conforming build differs, and the cure would restate Logic confinement 16; the checker's four hits placed one false (`answers list id` is a bare id, not a code), one false (Operation 10 and the case row state what found carries) and two refining cured (the registry's found and none had no term entry, nor did ok, which the checker passes over: the three entries are written, Kind Member, Role Outcome), and the blind second triage's own rhetorical find cured (the sentence after the offer line said no bond serves the four actions, while the offer now names Delete List under ends and Read List under calls); model redraw: none; 2026-11-25 — Final Critique 4, a delta round (diff base 4a4063ea: Final Critique 3's cures and the on end commit, 3 labels reached), one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at f5f4ab98 — foundational count 0 after the blind second triage, clean, one sample (Linus's report counted 1 foundational, Kind C, and it did not stand under either triage: its trace put a second [Delete List] on an ended list in the row "the list exists", but the page's Delete List text says a list id no list carries is left as it is since an earlier call may already have deleted it, List Record says a deleted list's record has ended, and Read List counts a deleted list among those no list carries, so a re-delete falls in the row "no list carries the list id", which answers ok and writes nothing (Operation 9), ends no value and so owes no on end call (Bonds Key 3); its cure would restate Bonds Key 3 on this page, which the placement rule refuses; the blind second triage (an Opus subagent) placed it no defect and found no foundational edge of its own, and no cure was made)

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./list.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/list.md`.

</details>

NOTE: End of List.

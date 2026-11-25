---
title: List
id: 80
audience: common
has_toc: true
toc: true
---

# List

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

List names a set of items and holds who made it: make a list, rename it, delete it, read it. It holds the list's id, its name and its author, and nothing about the items, who may rename or delete it, or who the author is.

<details markdown="block">
<summary>WHY</summary>

Several atoms of an app carry a list id, and none of them made the list, minted its id or held its author, so the id had no owner and "the author" had no home (Scott, 2026-11-24 10:50 PM Central, "yes", on the design round's finding (c)4; and 3:23 PM, "the author owns the list"). This atom owns the three facts and judges no caller: who may rename or delete is the app's permission, gated before the call.

</details>

## What it keeps

### The lists

Term list: one named set of items, with its author — a [List Record]; one for each list id.

#### List Record

Holds the list id, the name and the author. A list id no record carries names no list, and a deleted list's record is gone.

Kind: Type

```
Identity 1: The atom MUST identify a list by the list's list id.
Identity 2: The host MUST allocate the list id for [Make List] at the atom's seam.
Identity 3: [Make List] MUST NOT take a list id from the business caller.
Identity 4: The atom MUST NOT reuse a list id.
```

Term name: the text a list is called by, held as supplied — a [Name]; the atom reads no meaning in it and compares no two names.

#### Name

Held by each list; changed only by [Rename List].

Kind:       Field
Field of:   List Record
Projection: name

Term author: the actor id of the party who made the list — an [Author]; the atom reads nothing in it.

#### Author

Set by [Make List] from its input and held as supplied; the same actor id is the one every other record that names that party carries.

Kind:       Field
Field of:   List Record
Projection: author

```
State 1: EVERY list MUST carry list id, name and author.
```

### The rules of a list

```
List 1: [Make List] MUST give the list a list id that no list has carried.
List 2: A list MUST carry the author [Make List] was given.
List 3: An action MUST NOT change a list's author.
List 4: IF the name DOES NOT EQUAL the list's name THEN [Rename List] MUST change the list's name.
List 5: An action MUST NOT change a list's list id.
List 6: [Delete List] MUST end the list, so that a later [Read List] answers none.
List 7: The atom MUST NOT judge who may change a list.
```

## What people do

### Every action

```
Operation 1: IF the list id EQUALS blank THEN a writing action MUST answer invalid-id.
Operation 2: IF the name EQUALS blank THEN a writing action MUST answer invalid-name.
Operation 3: IF the author EQUALS blank THEN [Make List] MUST answer invalid-author.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| a writing action | an input is no string | invalid-request | none (Execution Contract Input 3) |
| a writing action | the list id, the name or the author is blank | [Invalid Id], [Invalid Name] or [Invalid Author] | none (Operation 1, Operation 2, Operation 3) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

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

#### Storage Failure

The refusal a writing action answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

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
| [Make List] | a name and an author | the new list id | one list lands, carrying the name and the author (List 1, List 2, Operation 4) |

- `make_list("Groceries", "a1")` — answers a list id, say `l1`: the list named Groceries stands with author a1.
- `make_list("Groceries", "a1")` again — answers a second list id, `l2`: two lists may share a name (Name).

### Rename List

Changes one list's name. Answers ok.

Kind: Operation

```
rename_list(list_id, name)
  answers ok
  refuses invalid-request | invalid-id | invalid-name | unknown-list | storage-failure
```

```
Operation 5: IF no list carries the list id THEN [Rename List] MUST answer unknown-list.
Operation 6: [Rename List] MUST answer ok.
Operation 7: IF the name EQUALS the list's name THEN [Rename List] MUST NOT write.
```

Term ok: the answer [Rename List] and [Delete List] give once the call is admitted; it carries nothing.

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Rename List] | the list exists and the name differs | ok | the list's name changes, its list id and author stay (List 4, List 3, List 5, Operation 6) |
| [Rename List] | the list exists and the name is its own | ok | none, no write (Operation 7, Operation 6) |
| [Rename List] | no list carries the list id | [Unknown List] | none (Operation 5) |

- `rename_list("l1", "Weekly shop")` — answers ok: the list reads as Weekly shop, still author a1.
- `rename_list("zz", "x")` — rejected as [Unknown List]: no list carries zz.

#### Unknown List

The refusal of a rename for a list id no list carries (Operation 5).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-list

### Delete List

Ends a list: its record is gone, and a later read answers none. A list id no list carries is left as it is, since an earlier call may already have deleted it. Answers ok.

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
| [Delete List] | the list exists | ok | the list is gone (List 6, Operation 8) |
| [Delete List] | no list carries the list id | ok | none, no write (Operation 9, Operation 8) |

### Read List

Answers a list's name and author, or none; changes nothing. A blank list id answers none, since no list carries one.

Kind: Operation

```
read_list(list_id)
  answers found(name, author)
```

Term found: the name and author of one list, or none where no list carries the list id; none carries nothing.

```
Operation 10: [Read List] MUST answer the list's name AND author.
Operation 11: IF no list carries the list id THEN [Read List] MUST answer none.
Operation 12: [Read List] MUST NOT write.
```

| Call | Case | Answer | Effect on the lists |
|---|---|---|---|
| [Read List] | the list exists | its name and author | none (Operation 10, Operation 12) |
| [Read List] | no list carries the list id, a blank one included, or the list was deleted | none | none (Operation 11, Operation 12, List 6) |

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

Two calls for one list are serialized in the commit order (Execution Contract Database 2, Order 2): the later reads what the earlier committed, so a rename after a delete answers unknown-list and a read after a rename answers the new name. The rules above hold for calls arriving one at a time in that order, and the rules above do not restate it.

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 8, Execution Contract Order 1 through 2, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 AND Execution Contract Input 3.
```

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states; which atom meets each is the app's choice. [Rename List] and [Delete List] take no caller and check none (List 7): who may rename or delete a list is the app's permission, gated before the call.

Term need key: key actor id; pairs lists.

## Offers

Term offer key: key list id; carried by lists.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may change a list.
Non-goal 2: The atom MUST NOT hold the items of a list.
Non-goal 3: The atom MUST NOT tell whether an author names a real party.
Non-goal 4: The atom MUST NOT remove the items of a list when the list is deleted.
Non-goal 5: The atom MUST NOT keep a list's order.
```

NOTE: the owners — the app's permission, gated before the call (Non-goal 1); the atoms that hold the items (Non-goal 2); the atom that names parties, through the need for an actor id (Non-goal 3); the app's pattern, which takes every item of a list out as it deletes the list, a glue line (Non-goal 4); the atom that keeps an order (Non-goal 5).

```
Composition note 1: A composing pattern MUST decide who may change a list, since [Rename List] and [Delete List] check no caller (List 7).
Composition note 2: A composing pattern MUST take every item of a list out when the composing pattern deletes the list.
```

NOTE: composing patterns — none yet.

## Example

An author, actor a1, sets up a list: `make_list("Groceries", "a1")` answers `l1`. Later they rename it: `rename_list("l1", "Weekly shop")` answers ok, and `read_list("l1")` is answered Weekly shop and a1. When the week is over, `delete_list("l1")` answers ok, and `read_list("l1")` is answered none.

## Source

List is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design; a named list that someone made is its own concept.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the lists the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY list carrying list id, name AND author (State 1).
Check 1.2: An auditor MUST find no two lists sharing a list id across the committed versions (Identity 4, Invariant 1.1, Invariant 1.2).
Check 1.3: An auditor MUST find every list's author the same in every version of the list (List 2, List 3, Invariant 2.1).
Check 1.4: An auditor MUST find, across two successive versions of a list where the later is a rename, the list id and the author unchanged (List 3, List 5).
Check 1.5: An auditor MUST find no list record in a version that follows a version that deleted the list (List 6).
```

NOTE: EVERY check names the rule the check tests.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; an auditor; the business caller.

Term records: list — one named set of items, carrying list id, name and author.

Term record verbs: identify, carry, hold, keep, tell, give, make, rename, delete, read, answer, write, change, supply, find, name, end, judge, decide, allocate, reuse, take, share, remove.

Term value sets: action rejection — invalid-id | invalid-name | invalid-author | unknown-list | storage-failure.

Term bounds: empty.

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-25) from Scott's ruling of 2026-11-24 10:50 PM Central.

Term terms: list, name, author, found, ok.

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
[Storage Failure]: #storage-failure

## Status

`todo` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: todo
formal: pending — no model yet; new formal modelling is paused (budget.toml formal_new_models, Scott 2026-11-23) and Lean replaces the model layer
last gate: none

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

---
title: Category
id: 71
audience: common
---

# Category

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Category lets a business arrange named categories as a tree — Gardening, and under it Soil and Seeds — and file each item in one home category. The tree is also the menu: every category has a place in its row that the business can change, and a category can be hidden from the menu without losing what is filed in it. Two categories side by side never share a name. An item has one home or none; filing it again moves it. Categories are never removed, so nothing filed is ever left pointing nowhere. Who may arrange the tree or file an item, the items themselves, flat tags, moving a category under another, and turning a busy tag into a category each belong to another pattern.

<details markdown="block">
<summary>WHY</summary>

Every place with many items needs somewhere to go first: a forum's boards, a shop's departments, a help center's sections. This atom is that and nothing more. Three decisions carry the weight. An item has exactly one home, so a reader always knows where an item lives and a count per category adds up; several names per item is a tag's job, a different pattern. The tree and the menu are one thing, so the business orders and hides categories where the categories are kept and no second menu drifts out of step. And a category is never removed, only hidden, so an item's home always names a real category and the database's history keeps every rename. The Massachusetts Institute of Technology's (MIT) sync-engine Labeling concept (Daniel Jackson's group) is read for its naming rules; Labeling's several labels per item are kept for another pattern.

</details>

## What it keeps

### The categories

```
Identity 1: The atom MUST identify a category by the category's category id.
Identity 2: The atom MUST assign EVERY category a category id no other category carries.
Identity 3: The atom MUST identify a home by the home's item reference.
Identity 4: The atom MUST NOT normalize an item reference.
Identity 5: The atom MUST compare two item references codepoint for codepoint.
Identity 6: The atom MUST NOT normalize a category name.
Identity 7: The atom MUST compare two category names codepoint for codepoint.
Identity 8: The atom MUST NOT normalize a category id.
Identity 9: The atom MUST compare two category ids codepoint for codepoint.
```

Term category: one named place in the tree, top level or under another category — a [Category].

Term category id: the string the atom assigns a category when the category is created — a [Category Id].

Term parent category: the category a category sits under; a top-level category has none — the [Parent Category].

Term siblings: categories sharing one parent category, or all top-level categories; no category is a sibling of itself.

Term ancestor: a category's parent category, or an ancestor of the category's parent category.

Term position: a whole number of one or more giving a category's place among the category's siblings, lowest first — a [Position].

Term home: the record filing one item in one category — a [Home].

NOTE: Capability requirement 3, Capability requirement 4 and Capability requirement 6 are the atom's own rule for the canonical form of the item reference, the category name and the category id, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each is recorded as the call carries it (Execution Contract Input 4; Identity 4, Identity 6, Identity 8).

```
State 1: EVERY category MUST carry category id, category name, position and status.
State 2: EVERY category MUST stand in EXACTLY ONE OF listed, hidden.
State 3: EVERY home MUST carry item reference and category id.
State 4: EVERY home MUST carry the category id of a category the database holds.
State 5: The atom MUST NOT remove a category.
State 6: EVERY category carrying a parent category MUST carry the category id of a category the database holds.
State 7: EVERY category MUST carry a position that EXCEEDS zero.
```

Term status: where a category stands in the menu, listed or hidden — the [Status].

Term listed: the status of a category the menu shows — [Listed].

Term hidden: the status of a category the menu leaves out — [Hidden]; homes in a hidden category stand.

NOTE: [Hide] stands the one category in hidden (Operation 13); a category under it keeps its own status, and whether a menu shows it is the composing pattern's (Non-goal 7).

#### Category

One named place in the tree: recorded by [Create] or [Create Under], renamed, reordered, hidden and shown; never moved and never removed by the atom.

Kind: Type

#### Category Id

The string the atom assigns a category when the category is created, carried by no other category; never changed.

Kind:       Field
Field of:   Category
Projection: category_id

#### Category Name

The category's name as the business wrote it; no sibling carries the same name. Compared codepoint for codepoint.

Kind:       Field
Field of:   Category
Projection: category_name

#### Parent Category

The category id of the category a category sits under; a top-level category has none. Set once, never changed by the atom.

Kind:       Field
Field of:   Category
Projection: parent_category_id

#### Position

A whole number above zero giving a category's place among the category's siblings, lowest first; Operation 24 orders two siblings carrying one position.

Kind:       Field
Field of:   Category
Projection: position

#### Status

Where a category stands in the menu: [Listed] or [Hidden].

Kind:       Field
Field of:   Category
Projection: status

#### Listed

The status of a category the menu shows.

Kind:       Member
Member of:  the status
Projection: listed

#### Hidden

The status of a category the menu leaves out; the items filed in it stay filed.

Kind:       Member
Member of:  the status
Projection: hidden

Term category name: the category's name as the business wrote it, such as Soil — a [Category Name].

Term item reference: the string naming an item, such as a post or a product, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it.

### The homes

#### Home

One item filed in one category: recorded or replaced by [Place], removed by [Unplace].

Kind: Type

#### Item Reference

Names the item a home files, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; whether it names a real item is a catalog's question.

Kind:       Field
Field of:   Home
Projection: item_reference

## What people do

### Every action

```
Operation 1: IF the category name of the call EQUALS blank OR the category name of the call EXCEEDS the string cap THEN a naming action MUST answer invalid-category-name.
Operation 2: IF a sibling of the named category carries the category name of the call THEN a naming action MUST answer name-taken.
Operation 3: IF the category id EQUALS blank OR the category id is malformed OR no category carries the category id THEN a category action MUST answer unknown-category (Execution Contract Input 3).
Operation 4: IF the item reference of the call EQUALS blank OR the item reference of the call EXCEEDS the string cap THEN a filing action MUST answer invalid-item-reference.
Operation 8: A creating action MUST stamp the category's position from the next position.
Operation 9: A creating action MUST stand the category in listed.
Operation 10: A creating action MUST answer the category id of the category the action recorded.
Operation 20: A changing action MUST answer ok.
Operation 25: A reading action MUST NOT write.
Operation 26: IF the category name of the call is malformed THEN a naming action MUST answer invalid-category-name (Execution Contract Input 1).
Operation 27: IF the item reference of the call is malformed THEN a filing action MUST answer invalid-item-reference (Execution Contract Input 1).
NOTE: Operation 11 and 12 take the changed-value condition, and Operation 16 and 17 the no-home and other-home conditions, so each is disjoint from the no-write rule of its action, Operation 34, 33 and 35, as Operation 13 and 15, and Operation 14 and 31, are.
```

Term naming action: [Create] | [Create Under] | [Rename] — the actions that set a category name.

Term creating action: [Create] | [Create Under] — the actions that record a new category.

Term category action: [Create Under] | [Rename] | [Reorder] | [Hide] | [Show] | [Place] | [Read Category] — the actions that name a category by category id and refuse one no category carries; [List Items] names one too and answers an empty list instead (Operation 29, Operation 32).

Term filing action: [Place] | [Unplace] — the actions that set an item's home.

Term changing action: [Rename] | [Reorder] | [Hide] | [Show] | [Place] | [Unplace] — the actions that answer ok.

Term reading action: [Look Up] | [List Items] | [Tree] | [Read Category] — the actions that change nothing.

Term named category: for [Create] and [Create Under], the category the call would record; for [Rename], the category the call names.

Term highest position: the highest position among the named category's siblings, zero where the named category has no sibling.

Term next position: `(highest_position + 1)` — what a creating action stamps as the category's position.

Term menu: the row of categories a composing pattern shows, drawn from the categories the atom holds; the atom keeps each category's status and position, which say what the menu shows and in what order, and draws nothing (Non-goal 7).

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| a naming action | a sibling already carries the name | [Name Taken] | none (Operation 2) |
| a category action | category id blank, malformed, or carried by no category | [Unknown Category] | none (Operation 3) |
| a naming action | name blank, over the string cap, or not a string | [Invalid Category Name] | none (Operation 1, Operation 26) |
| a filing action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 4, Operation 27) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

- `create("")` — rejected as [Invalid Category Name]: the name is blank.
- `create_under("g", "Soil")` a second time — rejected as [Name Taken]: Gardening already holds a Soil.
- `create("Soil")` — answers a new category id: a top-level Soil is no sibling of the Soil under Gardening.
- `place("p-7", "nope")` — rejected as [Unknown Category]: no category carries the category id.
- `reorder(soil-id, 0)` — rejected as [Invalid Position]: positions start at one.
- `place("", soil-id)` — rejected as [Invalid Item Reference]: the item reference is blank.

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

#### Invalid Category Name

The refusal of a blank [Category Name], one over the string cap, or one that is not a string, on [Create], [Create Under] or [Rename] (Operation 1, Operation 26).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-category-name

#### Name Taken

The refusal of a category name a sibling already carries (Operation 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: name-taken

#### Unknown Category

The refusal of a blank or malformed [Category Id], or one no category carries (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-category

#### Invalid Position

The refusal of a [Position] that is blank, zero, below zero, or not a whole number, on [Reorder] (Operation 5, Operation 30).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-position

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string, on [Place] or [Unplace] (Operation 4, Operation 27).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Create

#### Create

Records a new top-level [Category] with a [Category Name], [Listed], last among the top-level categories. Answers its [Category Id].

Kind: Operation

```
create(category_name)
  answers category_id
  refuses invalid-category-name | name-taken | storage-failure
```

```
Operation 6: [Create] MUST record EXACTLY ONE top-level category carrying the category id the seam supplies AND the category name of the call.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Create] | name valid, no top-level category carries the name | the category id | one top-level category lands, listed, last in the row (Operation 6, Operation 8 through 10) |

### Create Under

#### Create Under

Records a new [Category] under a [Parent Category], with a [Category Name], [Listed], last among the parent's categories. Answers its [Category Id].

Kind: Operation

```
create_under(category_id, category_name)
  answers category_id
  refuses unknown-category | invalid-category-name | name-taken | storage-failure
```

```
Operation 7: [Create Under] MUST record EXACTLY ONE category carrying the category id the seam supplies, the category name of the call AND the category id of the call as parent category.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Create Under] | the parent exists, name valid and free among the parent's categories | the category id | one category lands under the parent, listed, last in the row (Operation 7 through 10) |

### Rename

#### Rename

Replaces a category's [Category Name]; the earlier name stays in the category's earlier versions. Answers ok.

Kind: Operation

```
rename(category_id, category_name)
  answers ok
  refuses unknown-category | invalid-category-name | name-taken | storage-failure
```

```
Operation 11: IF the call changes the category's category name THEN [Rename] MUST replace the category's category name with the category name of the call.
Operation 34: IF the category carries the category name of the call THEN [Rename] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Rename] | the category exists, name valid and free, and the call changes the category's name | ok | the name replaced; the earlier name stays in the category's earlier versions (Operation 11) |
| [Rename], [Reorder] or [Place] | the call asks for what already stands: the category's name, the category's position or the item's home | ok | none, no write (Operation 33 through 35) |

### Reorder

#### Reorder

Replaces a category's [Position] among the category's siblings. Answers ok.

Kind: Operation

```
reorder(category_id, position)
  answers ok
  refuses unknown-category | invalid-position | storage-failure
```

```
Operation 5: IF the position EQUALS blank OR the position DOES NOT EXCEED zero THEN [Reorder] MUST answer invalid-position.
Operation 12: IF the call changes the category's position THEN [Reorder] MUST replace the category's position with the position of the call.
Operation 30: IF the position is malformed THEN [Reorder] MUST answer invalid-position (Execution Contract Input 1).
Operation 33: IF the category carries the position of the call THEN [Reorder] MUST NOT write.
Operation 38: [Reorder] MUST NOT change the position of a category the call does not name.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Reorder] | the category exists, position a whole number above zero, and the call changes the category's position | ok | the position replaced; no other category's position changes (Operation 12, Operation 38) |
| [Reorder] | position blank, zero, below zero, or not a whole number | [Invalid Position] | none (Operation 5, Operation 30) |

### Hide

#### Hide

Stands a [Listed] category in [Hidden], leaving every [Home] in the category as it is. Answers ok.

Kind: Operation

```
hide(category_id)
  answers ok
  refuses unknown-category | storage-failure
```

```
Operation 13: IF the category's status EQUALS listed THEN [Hide] MUST stand the category in hidden.
Operation 15: IF the category's status EQUALS hidden THEN [Hide] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Hide] | the category stands listed | ok | the category stands hidden; homes in the category stand (Operation 13) |
| [Hide] or [Show] | the category already stands as asked | ok | none, no write (Operation 15, Operation 31) |

### Show

#### Show

Stands a [Hidden] category in [Listed]. Answers ok.

Kind: Operation

```
show(category_id)
  answers ok
  refuses unknown-category | storage-failure
```

```
Operation 14: IF the category's status EQUALS hidden THEN [Show] MUST stand the category in listed.
Operation 31: IF the category's status EQUALS listed THEN [Show] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Show] | the category stands hidden | ok | the category stands listed (Operation 14) |

### Place

#### Place

Files an item in one category, replacing the item's earlier [Home] where there was one. Answers ok.

Kind: Operation

```
place(item_reference, category_id)
  answers ok
  refuses invalid-item-reference | unknown-category | storage-failure
```

```
Operation 16: IF no home carries the item reference THEN [Place] MUST record EXACTLY ONE home for the item reference, carrying the category id of the call.
Operation 17: IF a home carries the item reference AND the home's category id DOES NOT EQUAL the category id of the call THEN [Place] MUST replace the home's category id with the category id of the call.
Operation 35: IF the item reference's home carries the category id of the call THEN [Place] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Place] | item reference valid, the category exists, and the item has no home | ok | one home lands carrying the category (Operation 16) |
| [Place] | item reference valid, the category exists, and the item's home is another category | ok | the home's category is replaced by the category (Operation 17) |

### Unplace

#### Unplace

Removes an item's [Home]; an item with none is left as it is. Answers ok.

Kind: Operation

```
unplace(item_reference)
  answers ok
  refuses invalid-item-reference | storage-failure
```

```
Operation 18: IF a home carries the item reference THEN [Unplace] MUST remove the home of the item reference.
Operation 19: IF no home carries the item reference THEN [Unplace] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Unplace] | the item has a home | ok | the home removed (Operation 18) |
| [Unplace] | the item has no home | ok | none, no write (Operation 19) |

### Look Up

#### Look Up

Answers the category id of an item's home, and changes nothing; an empty list where the item has none.

Kind: Operation

```
look_up(item_reference)
  answers categories(category_id)
```

```
Operation 21: [Look Up] MUST answer the category id of the item reference's home.
Operation 22: [Look Up] MUST answer an empty list for an item reference no home carries.
Operation 28: IF the item reference of the call is malformed OR the item reference of the call EQUALS blank OR the item reference of the call EXCEEDS the string cap THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Look Up] | the item has a home | the category id | none (Operation 21) |
| [Look Up] | the item has none, or the reference is blank, over the string cap, or not a string | an empty list | none (Operation 22, Operation 28) |

### List Items

#### List Items

Answers every [Item Reference] filed in one category, and changes nothing.

Kind: Operation

```
list_items(category_id)
  answers items(item_reference)
```

```
Operation 23: [List Items] MUST answer EVERY item reference whose home carries the category id, in codepoint order (Execution Contract Logic confinement 10).
Operation 29: IF no category carries the category id THEN [List Items] MUST answer an empty list.
Operation 32: IF the category id EQUALS blank OR the category id is malformed THEN [List Items] MUST answer an empty list (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [List Items] | the category exists | every item filed in the category | none (Operation 23) |
| [List Items] | no category carries the category id, or the id is blank or malformed | an empty list | none (Operation 29, Operation 32) |

### Tree

#### Tree

Answers every category with its parent category, name, position and status, depth first, siblings in position order, and changes nothing.

Kind: Operation

```
tree()
  answers categories(category_id, parent_category_id, category_name, position, status)
```

```
Operation 24: [Tree] MUST answer EVERY category depth first, each category ahead of the categories under the category, siblings in position order, then in codepoint order of category name (Execution Contract Logic confinement 10).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Tree] | any | every category with parent, name, position and status | none (Operation 24) |

### Read Category

#### Read Category

Answers one category by its [Category Id] and changes nothing: its category id, name, position, status and, under another category, its parent. It is the read an app's key check makes on a category id (Bonds Key 26).

Kind: Operation

```
read_category(category_id)
  answers category
  refuses unknown-category
```

```
Operation 36: [Read Category] MUST answer the category's category id, category name, position, status AND, where the category carries one, parent category.
Operation 37: [Read Category] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Read Category] | a category carries the category id | the category's id, name, position, status and parent | none (Operation 36, Operation 37) |
| [Read Category] | the category id is blank, malformed or names no category | [Unknown Category] | none (Operation 3) |

## What is and what should never be (Invariants)

- **Invariant 2 — Names and homes stay one each.**
  ```
  Invariant 2.1: Two siblings MUST NOT share a category name.
  Invariant 2.2: Two homes MUST NOT share an item reference.
  Invariant 2.3: Two categories MUST NOT share a category id.
  ```
- **Invariant 3 — The tree has no loop.**
  ```
  Invariant 3.1: A category MUST NOT stand among the category's ancestors.
  ```
- **Invariant 1 — A category never moves in the tree.**
  ```
  Invariant 1.1: The atom MUST NOT change a category's category id.
  Invariant 1.2: The atom MUST NOT change a category's parent category.
  ```

## When something happens

### Concurrency

Two [Create] calls with one name, or two [Create Under] calls with one parent and one name, are serialized (Execution Contract Database 2): the later meets the earlier's category and answers [Name Taken], so siblings never share a name. Two [Place] calls for one item are serialized the same way, and the item's home is the later's (Execution Contract Order 2).

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). Where no other call changed the category or the home in between, a repeated [Place], [Unplace], [Hide], [Show], [Rename] or [Reorder] where the first landed changes nothing and answers ok, and a repeated [Create] or [Create Under] where the first landed answers [Name Taken], which tells the caller the category exists; [Tree] answers its category id. Where another call did change it, the repeat is decided afresh on what that call left (Execution Contract Database 2).

### What undoes a write

[Show] undoes [Hide] and [Hide] undoes [Show]; a [Rename] or a [Reorder] is undone by another carrying the earlier value, which the category's earlier versions hold; a [Place] is undone by a [Place] to the earlier home or by [Unplace]; an [Unplace] is undone by a [Place] to the home the home's earlier versions hold. A [Create] or a [Create Under] is undone by hiding the category, since the atom removes no category (State 5; Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 8, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 3: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 4: The deployment MUST NOT normalize a category name at the seam.
Capability requirement 5: The deployment MUST supply at the seam, for each creating action call, a category id no category has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
Capability requirement 6: The deployment MUST NOT normalize a category id at the seam.
```

Term string cap: the one bound on an item reference's length and on a category name's length in Unicode code points; 1,024 code points where a deployment declares none, and a deployment declares one value for both.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the category id a creating action records here (Capability requirement 5).

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key category id; carried by categories; calls Read Category.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may arrange the tree.
Non-goal 2: The atom MUST NOT tell who may file an item.
Non-goal 3: The atom MUST NOT check an item reference against a catalog.
Non-goal 4: The atom MUST NOT file an item under several names.
Non-goal 5: The atom MUST NOT move a category under another category.
Non-goal 6: The atom MUST NOT turn a tag into a category.
Non-goal 7: The atom MUST NOT draw the menu.
Non-goal 8: The atom MUST NOT count the items in a category.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or the app's [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3; External check 1); [Tag](./tag.md) (Non-goal 4); Category Move *(forthcoming)* (Non-goal 5); Tag Promotion *(forthcoming)*, which graduates a busy tag into a category, as communities already do by hand (Non-goal 6); the composing pattern that shows the menu (Non-goal 7); the composing pattern that shows the category, reading [List Items] (Non-goal 8).

Where the atom breaks down: several names on one item, found through any of the names, which is a tag pattern's; a folder a person keeps for their own items, which is a collection *(forthcoming)*.

```
Composition note 1: A composing pattern MUST own what this atom declines.
```

NOTE: composing patterns — none yet. Forthcoming: Forum, Tag Promotion.

## Example

The same pattern in two domains, then the rejection paths.

### Forum

A forum creates `create("Gardening")`, answered `g`, then `create_under("g", "Soil")` and `create_under("g", "Seeds")`, which land in that order. A member's post `p-7` is filed with `place("p-7", soil-id)`; the moderators decide the post fits Seeds better and call `place("p-7", seeds-id)`, which moves the post's one home. The forum moves Seeds ahead of Soil with `reorder(seeds-id, 1)` and `reorder(soil-id, 2)`, and `tree()` answers the new order.

### Shop

A shop hides its Winter Coats department in May: `hide(coats-id)` answers ok, `tree()` answers the department as hidden so the menu leaves it out, and every coat stays filed there for October, when `show(coats-id)` lists it again.

## Source

Category is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.
- **The Massachusetts Institute of Technology's sync-engine, Labeling concept** (github.com/mit-sdg/sync-engine) — read for its naming rules (a name unique in its scope, a rename that keeps what is filed). Its several labels per item are not taken here; they are a tag pattern's.

---

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the categories and homes the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY category carrying category id, category name, position AND status (State 1).
Check 1.2: An auditor MUST find EVERY category standing in EXACTLY ONE OF listed, hidden (State 2).
Check 1.3: An auditor MUST find EVERY home carrying the category id of a category the database holds (State 4).
Check 1.4: An auditor MUST find an unfiltered read answering EVERY category with a committed version (State 5; Execution Contract Generation acceptance 1).
Check 1.5: An auditor MUST find EVERY parent category naming a category the database holds (State 6).
Check 1.6: An auditor MUST find EVERY home carrying item reference AND category id (State 3).
Check 1.7: An auditor MUST find EVERY category carrying a position that EXCEEDS zero (State 7).
Check 2.1: An auditor MUST find EVERY version of a category that an action of the atom wrote, the first version excepted, carrying the parent category of the category's preceding version (Invariant 1.2; Execution Contract Database 6, Execution Contract Generation acceptance 1).
Check 2.2: An auditor MUST find EVERY version of a category carrying the category id of the category's first version (Invariant 1.1).
Check 2.3: An auditor MUST find no category standing among the category's ancestors (Invariant 3.1; Execution Contract Database 8).
Check 3.1: An auditor MUST find no two siblings sharing a category name (Invariant 2.1).
Check 3.2: An auditor MUST find no two homes sharing an item reference (Invariant 2.2).
Check 3.3: An auditor MUST find no two categories sharing a category id (Invariant 2.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
External check 2: An auditor needing a version of a category told apart as written by an action another specification declares, such as a move, MUST read that specification's records (Non-goal 5; Execution Contract Database 4, Execution Contract Database 6).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a category; a home; a naming action; a creating action; a category action; a filing action; a changing action; a reading action; an auditor.

Term records: category — one named place in the tree, carrying category id, category name, position, status and, under another category, parent category; home — one item filed in one category, carrying item reference and category id.

Term record verbs: identify, assign, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, replace, change, write, share, find, read, tell, check, file, move, turn, draw, count, own.

Term value sets: naming action, creating action, category action, filing action, changing action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — listed | hidden; action rejection — invalid-category-name | name-taken | unknown-category | invalid-position | invalid-item-reference | storage-failure.

Term bounds: string cap (declared once at Term string cap, cited here under GRACE-lang Closed vocabulary 15).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from Scott's forum sketch and the Massachusetts Institute of Technology's sync-engine Labeling concept.

Term terms: category, categories, category id, category name, parent category, siblings, sibling, ancestor, ancestors, position, home, homes, item reference, string cap, seam, status, listed, hidden, naming action, creating action, category action, filing action, changing action, reading action, named category, highest position, next position, menu, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Create]: #create
[Create Under]: #create-under
[Rename]: #rename
[Reorder]: #reorder
[Hide]: #hide
[Show]: #show
[Place]: #place
[Unplace]: #unplace
[Look Up]: #look-up
[List Items]: #list-items
[Tree]: #tree
[Read Category]: #read-category
[Category]: #category
[Home]: #home
[Category Id]: #category-id
[Category Name]: #category-name
[Parent Category]: #parent-category
[Position]: #position
[Item Reference]: #item-reference
[Status]: #status
[Listed]: #listed
[Hidden]: #hidden
[Invalid Category Name]: #invalid-category-name
[Name Taken]: #name-taken
[Unknown Category]: #unknown-category
[Invalid Position]: #invalid-position
[Invalid Item Reference]: #invalid-item-reference
[Storage Failure]: #storage-failure

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: pending — no model yet
last gate: 2026-11-27 — Final Critique 5, a full round, frozen at 3e5074a7 — foundational count 4, cured, not clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-18 — Drafted through the Grace connector mirroring Reaction, from Scott's forum sketch.** *Chose:* a tree that is also the menu, one home per item, hide in place of remove, no move. *Over:* MIT's Labeling, several names per item in one flat scope. *Because:* Scott 2026-11-18: a forum gets both categories and tags, and a busy tag is graduated into a category; one home per item is the category, several names is the tag, and the graduation is Tag Promotion *(forthcoming)*. Moving a category is left to Category Move *(forthcoming)*, so the atom stays as simple as possible without losing fidelity.

- **2026-11-19 — One string cap bounds an item reference and a category name.** *Chose:* the atom states one cap for both, as Tag and Reaction do, and a deployment declares one value (Execution Contract Input 2: a deployment overrides the cap the page states, and the page states one). *Over:* a cap for each, as Erasure Tombstone and Condition Register declare. *Because:* a deployment that wants a different bound for a name declares it by a new direction on this page, not by a gap in this one; "as simple as possible without losing fidelity" keeps Category the same shape as Tag, its sibling with the same two inputs.

</details>

NOTE: End of Category.

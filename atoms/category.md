---
title: Category
id: 71
parent: Atomic Concepts
has_toc: true
toc: true
---

# Category

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Category lets a business arrange named categories as a tree — Gardening, and under it Soil and Seeds — and file each item in one home category. The tree is also the menu: every category has a place in its row that the business can change, and a category can be hidden from the menu without losing what is filed in it. Two categories side by side never share a name. An item has one home or none; filing it again moves it. Categories are never removed, so nothing filed is ever left pointing nowhere. Who may arrange the tree or file an item, the items themselves, flat tags, moving a category under another, and turning a busy tag into a category each belong to another pattern, which is why one category tree serves a forum, a shop and a help center alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Every place with many items needs somewhere to go first: a forum's boards, a shop's departments, a help center's sections. This atom is that and nothing more. Three decisions carry the weight. An item has exactly one home, so a reader always knows where an item lives and a count per category adds up; several names per item is a tag's job, a different pattern. The tree and the menu are one thing, so the business orders and hides categories where the categories are kept and no second menu drifts out of step. And a category is never removed, only hidden, so an item's home always names a real category and the database's history keeps every rename. Taken in from Scott's forum sketch ("tree, one home per post, carries menu order"), with MIT's sync-engine Labeling concept (Daniel Jackson's group) read for its naming rules; Labeling's several labels per item are kept for Tag *(forthcoming)*.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a category by the category's category id.
Identity 2: The atom MUST assign EVERY category a category id no other category carries.
Identity 3: The atom MUST identify a home by the home's item reference.
Identity 4: The atom MUST NOT normalize an item reference.
Identity 5: The atom MUST compare two item references codepoint for codepoint.
Identity 6: The atom MUST NOT normalize a category name.
Identity 7: The atom MUST compare two category names codepoint for codepoint.
```

Term category: one named place in the tree, top level or under another category — a [Category].

Term category id: the string the atom assigns a category when the category is created — a [Category Id].

Term category name: the category's name as the business wrote it, such as Soil — a [Category Name].

Term parent category: the category a category sits under; a top-level category has none — the [Parent Category].

Term siblings: categories sharing one parent category, or all top-level categories.

Term position: a whole number giving a category's place among the category's siblings, lowest first — a [Position].

Term home: the record filing one item in one category — a [Home].

Term item reference: the string naming an item, such as a post or a product, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it.

Term string cap: the bound on an item reference's length and on a category name's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

### State

```
State 1: EVERY category MUST carry category id, category name, position and status.
State 2: EVERY category MUST stand in EXACTLY ONE OF listed, hidden.
State 3: EVERY home MUST carry item reference and category id.
State 4: EVERY home MUST carry the category id of a category the database holds.
State 5: The atom MUST NOT remove a category.
```

Term status: where a category stands in the menu, listed or hidden — the [Status].

Term listed: the status of a category the menu shows — [Listed].

Term hidden: the status of a category the menu leaves out — [Hidden]; homes in a hidden category stand.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 3: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 4: The deployment MUST NOT normalize a category name at the seam.
```

### Operations

```
create(category_name)
  answers category_id
  refuses invalid-category-name | name-taken | storage-failure

create_under(category_id, category_name)
  answers category_id
  refuses unknown-category | invalid-category-name | name-taken | storage-failure

rename(category_id, category_name)
  answers ok
  refuses unknown-category | invalid-category-name | name-taken | storage-failure

reorder(category_id, position)
  answers ok
  refuses unknown-category | invalid-position | storage-failure

hide(category_id)
  answers ok
  refuses unknown-category | storage-failure

show(category_id)
  answers ok
  refuses unknown-category | storage-failure

place(item_reference, category_id)
  answers ok
  refuses invalid-item-reference | unknown-category | storage-failure

unplace(item_reference)
  answers ok
  refuses invalid-item-reference | storage-failure

look_up(item_reference)
  answers categories(category_id)

list_items(category_id)
  answers items(item_reference)

tree()
  answers categories(category_id, parent_category_id, category_name, position, status)
```

```
Operation 1: IF the category name EQUALS blank OR the category name EXCEEDS the string cap THEN a naming action MUST answer invalid-category-name.
Operation 2: IF a sibling of the named category carries the category name THEN a naming action MUST answer name-taken.
Operation 3: IF no category carries the category id THEN a category action MUST answer unknown-category.
Operation 4: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a filing action MUST answer invalid-item-reference.
Operation 5: IF the position DOES NOT EXCEED zero THEN [Reorder] MUST answer invalid-position.
Operation 6: [Create] MUST record EXACTLY ONE top-level category carrying the category name of the call.
Operation 7: [Create Under] MUST record EXACTLY ONE category carrying the category name of the call AND the category id of the call as parent category.
Operation 8: A creating action MUST stamp the category's position one higher than the highest position among the category's siblings.
Operation 9: A creating action MUST stand the category in listed.
Operation 10: A creating action MUST answer the category id of the category the action recorded.
Operation 11: [Rename] MUST replace the category's category name with the category name of the call.
Operation 12: [Reorder] MUST replace the category's position with the position of the call.
Operation 13: IF the category's status EQUALS listed THEN [Hide] MUST stand the category in hidden.
Operation 14: IF the category's status EQUALS hidden THEN [Show] MUST stand the category in listed.
Operation 15: IF the category's status EQUALS hidden THEN [Hide] MUST NOT write.
Operation 16: [Place] MUST record EXACTLY ONE home for the item reference, carrying the category id of the call.
Operation 17: [Place] MUST replace any earlier home of the item reference.
Operation 18: IF a home carries the item reference THEN [Unplace] MUST remove the home of the item reference.
Operation 19: IF no home carries the item reference THEN [Unplace] MUST NOT write.
Operation 20: A changing action MUST answer ok.
Operation 21: [Look Up] MUST answer the category id of the item reference's home.
Operation 22: [Look Up] MUST answer an empty list for an item reference no home carries.
Operation 23: [List Items] MUST answer EVERY item reference whose home carries the category id, in codepoint order.
Operation 24: [Tree] MUST answer EVERY category, siblings in position order, then in codepoint order of category name.
Operation 25: A reading action MUST NOT write.
Operation 26: IF the category name is malformed THEN a naming action MUST answer invalid-category-name (Execution Contract Input 1).
Operation 27: IF the item reference is malformed THEN a filing action MUST answer invalid-item-reference (Execution Contract Input 1).
Operation 28: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
Operation 29: IF no category carries the category id THEN [List Items] MUST answer an empty list (Execution Contract Query 5).
Operation 30: IF the position is malformed THEN [Reorder] MUST answer invalid-position (Execution Contract Input 1).
Operation 31: IF the category's status EQUALS listed THEN [Show] MUST NOT write.
```

Term naming action: [Create] | [Create Under] | [Rename] — the actions that set a category name.

Term creating action: [Create] | [Create Under] — the actions that record a new category.

Term category action: [Create Under] | [Rename] | [Reorder] | [Hide] | [Show] | [Place] | [List Items] — the actions that name a category by category id.

Term filing action: [Place] | [Unplace] — the actions that set an item's home.

Term changing action: [Rename] | [Reorder] | [Hide] | [Show] | [Place] | [Unplace] — the actions that answer ok.

Term reading action: [Look Up] | [List Items] | [Tree] — the actions that change nothing.

Term named category: for [Create] and [Create Under], the category the call would record; for [Rename], the category the call names.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Create] | name valid, no top-level category carries the name | the category id | one top-level category lands, listed, last in the row (Operation 6, Operation 8 through 10) |
| [Create Under] | the parent exists, name valid and free among the parent's categories | the category id | one category lands under the parent, listed, last in the row (Operation 7 through 10) |
| a naming action | a sibling already carries the name | [Name Taken] | none (Operation 2) |
| [Rename] | the category exists, name valid and free | ok | the name replaced; the earlier name stays in the category's history (Operation 11) |
| [Reorder] | the category exists, position a whole number above zero | ok | the position replaced (Operation 12) |
| [Reorder] | position zero, below zero, or not a whole number | [Invalid Position] | none (Operation 5, Operation 30) |
| [Hide] | the category stands listed | ok | the category stands hidden; homes in the category stand (Operation 13) |
| [Show] | the category stands hidden | ok | the category stands listed (Operation 14) |
| [Hide] or [Show] | the category already stands as asked | ok | none, no write (Operation 15, Operation 31) |
| [Place] | item reference valid, the category exists | ok | the item's home is the category; any earlier home is replaced (Operation 16, Operation 17) |
| [Unplace] | the item has a home | ok | the home removed (Operation 18) |
| [Unplace] | the item has no home | ok | none, no write (Operation 19) |
| a category action | no category carries the category id | [Unknown Category] | none (Operation 3) |
| a naming action | name blank, over the string cap, or not a string | [Invalid Category Name] | none (Operation 1, Operation 26) |
| a filing action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 4, Operation 27) |
| [Look Up] | the item has a home | the category id | none (Operation 21) |
| [Look Up] | the item has none, or the reference is blank, over the string cap, or not a string | an empty list | none (Operation 22, Operation 28) |
| [List Items] | the category exists | every item filed in the category | none (Operation 23) |
| [Tree] | any | every category with parent, name, position and status | none (Operation 24) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A category never moves in the tree.**
  ```
  Invariant 1.1: The atom MUST NOT change a category's category id.
  Invariant 1.2: The atom MUST NOT change a category's parent category.
  ```
- **Invariant 2 — Names and homes stay one each.**
  ```
  Invariant 2.1: Two siblings MUST NOT share a category name.
  Invariant 2.2: Two homes MUST NOT share an item reference.
  Invariant 2.3: Two categories MUST NOT share a category id.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Forum

A forum creates `create("Gardening")`, answered `g`, then `create_under("g", "Soil")` and `create_under("g", "Seeds")`, which land in that order. A member's post `p-7` is filed with `place("p-7", soil-id)`; the moderators decide the post fits Seeds better and call `place("p-7", seeds-id)`, which moves the post's one home. The forum moves Seeds ahead of Soil with `reorder(seeds-id, 1)` and `reorder(soil-id, 2)`, and `tree()` answers the new order.

### Shop

A shop hides its Winter Coats department in May: `hide(coats-id)` answers ok, `tree()` answers the department as hidden so the menu leaves it out, and every coat stays filed there for October, when `show(coats-id)` lists it again.

### Rejection paths

- `create("")` — rejected as [Invalid Category Name]: the name is blank.
- `create_under("g", "Soil")` a second time — rejected as [Name Taken]: Gardening already holds a Soil.
- `create("Soil")` — answers a new category id: a top-level Soil is no sibling of the Soil under Gardening.
- `place("p-7", "nope")` — rejected as [Unknown Category]: no category carries the category id.
- `reorder(soil-id, 0)` — rejected as [Invalid Position]: positions start at one.

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the categories and homes the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY category carrying category id, category name, position AND status (State 1).
Check 1.2: An auditor MUST find EVERY category standing in EXACTLY ONE OF listed, hidden (State 2).
Check 1.3: An auditor MUST find EVERY home carrying the category id of a category the database holds (State 4).
Check 2.1: An auditor MUST find EVERY version of a category carrying the parent category of the category's first version (Invariant 1.2).
Check 3.1: An auditor MUST find no two siblings sharing a category name (Invariant 2.1).
Check 3.2: An auditor MUST find no two homes sharing an item reference (Invariant 2.2).
Check 3.3: An auditor MUST find no two categories sharing a category id (Invariant 2.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
```

## Non-goals

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

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3; External check 1); Tag *(forthcoming)* (Non-goal 4); Category Move *(forthcoming)* (Non-goal 5); Tag Promotion *(forthcoming)*, which graduates a busy tag into a category, as communities already do by hand (Non-goal 6); the composing pattern that shows the menu (Non-goal 7); the composing pattern that shows the category, reading [List Items] (Non-goal 8).

Where the atom breaks down: several names on one item, found through any of the names, which is a tag *(forthcoming)*; a folder a person keeps for their own items, which is a collection *(forthcoming)*.

## Edge cases

### Concurrency

Two [Create Under] calls with one parent and one name are serialized (Execution Contract Database 2): the later meets the earlier's category and answers [Name Taken], so siblings never share a name. Two [Place] calls for one item are serialized the same way, and the item's home is the later's.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Place], [Unplace], [Hide], [Show], [Rename] or [Reorder] where the first landed changes nothing and answers ok. A repeated [Create] or [Create Under] where the first landed answers [Name Taken], which tells the caller the category exists; [Tree] answers its category id.

### What undoes a write

[Show] undoes [Hide] and [Hide] undoes [Show]; a [Rename] or a [Reorder] is undone by another carrying the earlier value, which the category's history holds; a [Place] is undone by a [Place] to the earlier home or by [Unplace]. A [Create] is undone by hiding the category, since the atom removes no category (Execution Contract Undo 4).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
```

NOTE: composing patterns — none yet. Forthcoming: Forum, Tag Promotion.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a category; a home; a naming action; a creating action; a category action; a filing action; a changing action; a reading action; an auditor.

Term records: category — one named place in the tree, carrying category id, category name, position, status and, under another category, parent category; home — one item filed in one category, carrying item reference and category id.

Term record verbs: identify, assign, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, replace, change, write, share, find, read, tell, check, file, move, turn, draw, count, own.

Term value sets: naming action, creating action, category action, filing action, changing action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — listed | hidden; action rejection — invalid-category-name | name-taken | unknown-category | invalid-position | invalid-item-reference | storage-failure.

Term bounds: string cap (the bound on an item reference's length and on a category name's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from Scott's forum sketch and MIT's sync-engine Labeling concept.

Term terms: category, categories, category id, category name, parent category, siblings, sibling, position, home, homes, item reference, string cap, seam, status, listed, hidden, naming action, creating action, category action, filing action, changing action, reading action, named category, version.

#### Create

Records a new top-level [Category] with a [Category Name], [Listed], last among the top-level categories. Answers its [Category Id].

Kind: Operation

#### Create Under

Records a new [Category] under a [Parent Category], with a [Category Name], [Listed], last among the parent's categories. Answers its [Category Id].

Kind: Operation

#### Rename

Replaces a category's [Category Name]; the earlier name stays in the category's history. Answers ok.

Kind: Operation

#### Reorder

Replaces a category's [Position] among the category's siblings. Answers ok.

Kind: Operation

#### Hide

Stands a [Listed] category in [Hidden], leaving every [Home] in the category as it is. Answers ok.

Kind: Operation

#### Show

Stands a [Hidden] category in [Listed]. Answers ok.

Kind: Operation

#### Place

Files an item in one category, replacing the item's earlier [Home] where there was one. Answers ok.

Kind: Operation

#### Unplace

Removes an item's [Home]; an item with none is left as it is. Answers ok.

Kind: Operation

#### Look Up

Answers the category id of an item's home, and changes nothing; an empty list where the item has none.

Kind: Operation

#### List Items

Answers every [Item Reference] filed in one category, and changes nothing.

Kind: Operation

#### Tree

Answers every category with its parent category, name, position and status, siblings in position order, and changes nothing.

Kind: Operation

#### Category

One named place in the tree: recorded by [Create] or [Create Under], renamed, reordered, hidden and shown; never moved and never removed by the atom.

Kind: Type

#### Home

One item filed in one category: recorded or replaced by [Place], removed by [Unplace].

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

The category id of the category a category sits under; a top-level category has none. Set once, never changed.

Kind:       Field
Field of:   Category
Projection: parent_category_id

#### Position

A whole number above zero giving a category's place among the category's siblings, lowest first; ties fall to codepoint order of name.

Kind:       Field
Field of:   Category
Projection: position

#### Item Reference

Names the item a home files, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; whether it names a real item is a catalog's question.

Kind:       Field
Field of:   Home
Projection: item_reference

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

#### Invalid Category Name

The refusal of a blank [Category Name], one over the string cap, or one that is not a string (Operation 1, Operation 26).

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

The refusal of a [Category Id] no category carries (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-category

#### Invalid Position

The refusal of a [Position] that is zero, below zero, or not a whole number, on [Reorder] (Operation 5).

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

## Standards references

Category is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.
- **MIT's sync-engine, Labeling concept** (github.com/mit-sdg/sync-engine) — read for its naming rules (a name unique in its scope, a rename that keeps what is filed). Its several labels per item are not taken here; they are Tag's.

---

## Status

`todo` — see the Ledger.

## Ledger

```
status: todo
formal: pending — no model yet
last gate: none

open: none
```

## Decisions

- **2026-11-18 — Drafted through the Grace connector mirroring Reaction, from Scott's forum sketch.** *Chose:* a tree that is also the menu, one home per item, hide in place of remove, no move. *Over:* MIT's Labeling, several names per item in one flat scope. *Because:* Scott 2026-11-18: a forum gets both categories and tags, and a busy tag is graduated into a category; one home per item is the category, several names is the tag, and the graduation is Tag Promotion *(forthcoming)*. Moving a category is left to Category Move *(forthcoming)*, so the atom stays as simple as possible without losing fidelity.

NOTE: End of Category.

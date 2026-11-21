---
title: Tag
id: 73
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Tag

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Tag lets a business keep a flat list of named tags — clay, cover-crops, beginners — and put several on one item, so the item is found through any of them. Two tags never share a name; renaming a tag keeps every item it is on. Putting a tag on an item it is already on, or taking off one it is not on, changes nothing. Tags are never removed, so an item is never left carrying a tag that does not exist. Who may make or apply a tag, the items themselves, the one home an item lives in, and turning a busy tag into a category each belong to another pattern, which is why one tag list serves a forum, a shop and a photo library alike.

<details markdown="block">
<summary>WHY</summary>

A category says where an item lives; a tag says what an item is about, and an item is about several things at once. This atom is that and nothing more. Four decisions carry the weight. Tags are flat and many-to-many: no tag sits under another, and an item carries any number. A tag's name is unique and a rename keeps every item the tag is on, so fixing a typo never loses anything. And putting a tag on and taking a tag off are each safe to repeat, so a double click never errors. Tags are never removed, which keeps every item's tags real; a tag no longer wanted is simply taken off its items. Taken in from MIT's sync-engine Labeling concept (Daniel Jackson's group), narrowed to one list per deployment and made safe to repeat. Scott, 2026-11-18: a forum gets both categories and tags, and communities graduate a busy tag into a category, which is Tag Promotion's job.

</details>

## What it keeps

### The record

Term tag: one named tag in the deployment's list — a [Tag].

#### Tag

One named tag in the deployment's list: recorded by [Create], renamed by [Rename]; never removed by the atom.

Kind: Type

Term tag id: the string the atom assigns a tag when the tag is created — a [Tag Id].

#### Tag Id

The string the atom assigns a tag when the tag is created, carried by no other tag; never changed.

Kind:       Field
Field of:   Tag
Projection: tag_id

```
Identity 1: The atom MUST identify a tag by the tag's tag id.
Identity 2: The atom MUST assign EVERY tag a tag id no other tag carries.
```

Term tag name: the string the business wrote as the tag's name, such as clay — a [Tag Name].

#### Tag Name

The string the business wrote as the tag's name; no other tag carries the same name. Compared codepoint for codepoint.

Kind:       Field
Field of:   Tag
Projection: tag_name

```
Identity 6: The atom MUST NOT normalize a tag name.
Identity 7: The atom MUST compare two tag names codepoint for codepoint.
```

Term tagging: the record that one tag is on one item — a [Tagging].

#### Tagging

One tag on one item: recorded by [Apply], removed by [Remove].

Kind: Type

```
Identity 3: The atom MUST identify a tagging by the tagging's tag id AND item reference.
```

Term item reference: the string naming an item, such as a post or a product, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it.

#### Item Reference

Names the item a tagging is on, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Tagging
Projection: item_reference

```
Identity 4: The atom MUST NOT normalize an item reference.
Identity 5: The atom MUST compare two item references codepoint for codepoint.
```

```
State 1: EVERY tag MUST carry tag id AND tag name.
State 2: EVERY tagging MUST carry tag id AND item reference.
State 3: EVERY tagging MUST carry the tag id of a tag the database holds.
State 4: The atom MUST NOT remove a tag.
```

## What people do

### Every action

Term naming action: [Create] | [Rename] — the actions that set a tag name.

Term tag action: [Rename] | [Apply] | [Remove] — the actions that name a tag by tag id and refuse an unknown one.

Term tagging action: [Apply] | [Remove] — the actions that put a tag on an item or take a tag off.

Term changing action: [Rename] | [Apply] | [Remove] — the actions that answer ok.

Term reading action: [Tags On] | [Items With] | [List Tags] — the actions that change nothing.

```
Operation 1: IF the tag name EQUALS blank OR the tag name EXCEEDS the string cap THEN a naming action MUST answer invalid-tag-name.
Operation 2: IF another tag carries the tag name THEN a naming action MUST answer name-taken.
Operation 3: IF no tag carries the tag id THEN a tag action MUST answer unknown-tag.
Operation 4: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a tagging action MUST answer invalid-item-reference.
Operation 12: A changing action MUST answer ok.
Operation 16: A reading action MUST NOT write.
Operation 17: IF the tag name is malformed THEN a naming action MUST answer invalid-tag-name (Execution Contract Input 1).
Operation 18: IF the item reference is malformed THEN a tagging action MUST answer invalid-item-reference (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| a naming action | another tag carries the name | [Name Taken] | none (Operation 2) |
| a tag action | no tag carries the tag id | [Unknown Tag] | none (Operation 3) |
| a naming action | name blank, over the string cap, or not a string | [Invalid Tag Name] | none (Operation 1, Operation 17) |
| a tagging action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 4, Operation 18) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Invalid Tag Name

The refusal of a blank [Tag Name], one over the string cap, or one that is not a string (Operation 1, Operation 17).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-tag-name

#### Name Taken

The refusal of a tag name another tag already carries (Operation 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: name-taken

#### Unknown Tag

The refusal of a [Tag Id] no tag carries (Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-tag

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string, on [Apply] or [Remove] (Operation 4, Operation 18).

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

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

### Create

Records a new [Tag] with a [Tag Name] no other tag carries. Answers its [Tag Id].

Kind: Operation

```
create(tag_name)
  answers tag_id
  refuses invalid-tag-name | name-taken | storage-failure
```

```
Operation 5: [Create] MUST record EXACTLY ONE tag carrying the tag name of the call.
Operation 6: [Create] MUST answer the tag id of the tag [Create] recorded.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Create] | name valid and unused | the tag id | one tag lands (Operation 5, Operation 6) |

- `create("")` — rejected as [Invalid Tag Name]: the name is blank.
- `create("clay")` a second time — rejected as [Name Taken].

### Rename

Replaces a tag's [Tag Name], keeping every [Tagging]; the earlier name stays in the tag's history (Execution Contract Database 5). Answers ok.

Kind: Operation

```
rename(tag_id, tag_name)
  answers ok
  refuses unknown-tag | invalid-tag-name | name-taken | storage-failure
```

```
Operation 7: IF the tag's tag name DOES NOT EQUAL the tag name of the call THEN [Rename] MUST replace the tag's tag name with the tag name of the call.
Operation 21: IF the tag's tag name EQUALS the tag name of the call THEN [Rename] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Rename] | the tag exists, name valid, no other tag carries it, and the tag carries a name other than the name of the call | ok | the name replaced; every tagging stands; the earlier name stays in the tag's history (Operation 7, Execution Contract Database 5) |
| [Rename] | the tag already carries the name of the call | ok | none, no write (Operation 21) |

### Apply

Puts a tag on an item, recording a [Tagging] where the item does not already carry the tag. Answers ok.

Kind: Operation

```
apply(tag_id, item_reference)
  answers ok
  refuses unknown-tag | invalid-item-reference | storage-failure
```

```
Operation 8: IF no tagging EXISTS for the tag id AND the item reference THEN [Apply] MUST record EXACTLY ONE tagging carrying the tag id AND the item reference of the call.
Operation 9: IF a tagging EXISTS for the tag id AND the item reference THEN [Apply] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Apply] | the tag exists, the item does not carry the tag | ok | one tagging lands (Operation 8) |
| [Apply] | the item already carries the tag | ok | none, no write (Operation 9) |

- `apply("nope", "p-7")` — rejected as [Unknown Tag]: no tag carries the tag id.
- `apply(clay-id, "")` — rejected as [Invalid Item Reference]: the reference is blank.

### Remove

Takes a tag off an item, removing the [Tagging] where there is one. Answers ok.

Kind: Operation

```
remove(tag_id, item_reference)
  answers ok
  refuses unknown-tag | invalid-item-reference | storage-failure
```

```
Operation 10: IF a tagging EXISTS for the tag id AND the item reference THEN [Remove] MUST remove the tagging.
Operation 11: IF no tagging EXISTS for the tag id AND the item reference THEN [Remove] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Remove] | the item carries the tag | ok | the tagging removed (Operation 10) |
| [Remove] | the item does not carry the tag | ok | none, no write (Operation 11) |

### Tags On

Answers every tag on one item, in order of name, and changes nothing.

Kind: Operation

```
tags_on(item_reference)
  answers tags(tag_id, tag_name)
```

```
Operation 13: [Tags On] MUST answer EVERY tag a tagging carrying the item reference names, in codepoint order of tag name (Execution Contract Logic confinement 10).
Operation 19: IF the item reference is malformed (Execution Contract Query 5) THEN [Tags On] MUST answer an empty list in place of Execution Contract Query 5's refusal.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Tags On] | any | every tag on the item, by name; an empty list where none or the reference is bad | none (Operation 13, Operation 19) |

### Items With

Answers every [Item Reference] carrying one tag, and changes nothing.

Kind: Operation

```
items_with(tag_id)
  answers items(item_reference)
```

```
Operation 14: [Items With] MUST answer EVERY item reference a tagging carrying the tag id carries, in codepoint order (Execution Contract Logic confinement 10).
Operation 20: IF no tag carries the tag id THEN [Items With] MUST answer an empty list, and a blank tag id is one no tag carries, in place of Execution Contract Query 5's refusal.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Items With] | any | every item carrying the tag; an empty list where none or no such tag | none (Operation 14, Operation 20) |

### List Tags

Answers every tag, in order of name, and changes nothing.

Kind: Operation

```
list_tags()
  answers tags(tag_id, tag_name)
```

```
Operation 15: [List Tags] MUST answer EVERY tag, in codepoint order of tag name (Execution Contract Logic confinement 10).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [List Tags] | any | every tag, by name | none (Operation 15) |

## Always true

- **Invariant 1 — Names and taggings stay one each.**
  ```
  Invariant 1.1: Two tags MUST NOT share a tag name.
  Invariant 1.2: Two tags MUST NOT share a tag id.
  Invariant 1.3: Two taggings MUST NOT share a tag id AND an item reference.
  ```

## When something happens

### Concurrency

Two [Apply] calls for one tag and one item are serialized (Execution Contract Database 2): the later meets the earlier's tagging and writes nothing. Two [Create] calls with one name each read the tags inside the transaction that writes (Execution Contract Database 2): the later meets the earlier's tag and answers [Name Taken].

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Apply], [Remove] or [Rename] where the first landed changes nothing and answers ok. A repeated [Create] where the first landed answers [Name Taken], and [List Tags] answers the tag id.

### What undoes a write

[Remove] undoes [Apply] and [Apply] undoes [Remove]; a [Rename] is undone by a [Rename] carrying the earlier name. A [Create] owes no undo: the atom removes no tag (State 4, Execution Contract Undo 4), and a tag no longer wanted is taken off its items.

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 3: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 4: The deployment MUST NOT normalize a tag name at the seam.
Capability requirement 5: The deployment MUST supply EVERY tag id PER Execution Contract Logic confinement 16.
```

Term string cap: the bound on an item reference's length and on a tag name's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may make a tag.
Non-goal 2: The atom MUST NOT tell who may apply a tag.
Non-goal 3: The atom MUST NOT check an item reference against a catalog.
Non-goal 4: The atom MUST NOT give an item a home.
Non-goal 5: The atom MUST NOT nest a tag under another tag.
Non-goal 6: The atom MUST NOT turn a tag into a category.
Non-goal 7: The atom MUST NOT count the items carrying a tag.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3; External check 1); [Category](./category.md) (Non-goal 4, 5); Tag Promotion *(forthcoming)*, which graduates a busy tag into a category (Non-goal 6); the composing pattern that shows the tag, reading [Items With] (Non-goal 7).

Where the atom breaks down: one place an item lives, shown in a menu, which is a [Category](./category.md); a person's own mark to find an item again, which is a [Favorite](./favorite.md).

```
Composition note 1: A composing pattern MUST own what this atom declines.
```

NOTE: composing patterns — none yet. Forthcoming: Forum, Tag Promotion.

## Example

The same pattern in two domains, then the rejection paths.

### Forum

A forum creates `create("claey")`, a typo, and `create("cover-crops")`. A post, `p-7`, gets both: `apply(claey-id, "p-7")` and `apply(cover-id, "p-7")`. `items_with(claey-id)` now answers `p-7` with every other claey post, and `tags_on("p-7")` answers claey and cover-crops. A moderator fixes the typo with `rename(claey-id, "clay")`, a name no tag carries; every post stays tagged, and `tags_on("p-7")` now answers clay and cover-crops.

### Photo library

A photographer tags one photo `beach`, `sunset` and `family`. Taking `family` off is `remove(family-id, "img-204")`; a second, identical remove sent by a slow connection answers ok and changes nothing.

## Source

Tag is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, and its Label concept.
- **MIT's sync-engine, Labeling concept** (github.com/mit-sdg/sync-engine) — the taken-in source: several stable names on one item, a rename that keeps assignments. This atom keeps one list per deployment and makes putting a tag on and taking it off safe to repeat.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the tags and taggings the database holds, with their earlier versions (Execution Contract Database 5); Check 1.1 through 2.3 are checks of one state (Execution Contract Database 8). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY tag carrying tag id AND tag name (State 1).
Check 1.2: An auditor MUST find EVERY tagging carrying the tag id of a tag the database holds (State 3).
Check 2.1: An auditor MUST find no two tags sharing a tag name (Invariant 1.1).
Check 2.2: An auditor MUST find no two tags sharing a tag id (Invariant 1.2).
Check 2.3: An auditor MUST find no two taggings sharing a tag id AND an item reference (Invariant 1.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a tag; a tagging; a naming action; a tag action; a tagging action; a changing action; a reading action; an auditor.

Term records: tag — one named tag, carrying tag id and tag name; tagging — one tag on one item, carrying tag id and item reference.

Term record verbs: identify, assign, normalize, compare, carry, remove, supply, declare, record, answer, replace, write, share, find, read, tell, check, give, nest, turn, count, own.

Term value sets: naming action, tag action, tagging action, changing action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); action rejection — invalid-tag-name | name-taken | unknown-tag | invalid-item-reference | storage-failure.

Term bounds: string cap (the bound on an item reference's length and on a tag name's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from MIT's sync-engine Labeling concept.

Term terms: tag, tags, tag id, tag name, tagging, taggings, item reference, string cap, seam, naming action, tag action, tagging action, changing action, reading action, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Create]: #create
[Rename]: #rename
[Apply]: #apply
[Remove]: #remove
[Tags On]: #tags-on
[Items With]: #items-with
[List Tags]: #list-tags
[Tag]: #tag
[Tagging]: #tagging
[Tag Id]: #tag-id
[Tag Name]: #tag-name
[Item Reference]: #item-reference
[Invalid Tag Name]: #invalid-tag-name
[Name Taken]: #name-taken
[Unknown Tag]: #unknown-tag
[Invalid Item Reference]: #invalid-item-reference
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-19` — see the Ledger.

## Ledger

```
status: done — 2026-11-19
formal: pending — no model yet
last gate: 2026-11-21 — Final Critique 4, a delta round, one reader (Linus opencode/nemotron-3.5-super-vl-free), frozen at b8c40cd2 — foundational count 0 after the blind second triage, clean, no sample; Linus's one foundational finding (Operation 19 cited Execution Contract Query 5 while answering a blank reference an empty list) was placed refining by the first triage and refuted by the blind second, every build answering an empty list, and its one refining finding (the blank and over-cap cases restate Query 5's classification) was cured with the first: Operation 19 reads the blank and over-cap cases as the malformed Query 5 classifies, and Operation 19 and Operation 20 state their empty list in place of Execution Contract Query 5's refusal; 2026-11-19 — Final Critique 3, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at a69c19d0 — foundational count 0 after the blind second triage, clean, one sample; Linus's four refining and two rhetorical findings placed one refining (Generation acceptance restated Execution Contract Database 8's bound, now only the checks' range and the label), one rhetorical (the Rename row's "another name", now "a name other than the name of the call") and the rest refuted or left as wording (Generation acceptance 1 binds no check on this page, Identity 6 and 7 settle how a tag name compares, "tag name" is the declared term); 2026-11-19 — Final Critique 2, a delta round, one reader (Linus claude-sonnet-5-5), frozen at 36794699 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim (Check 2.1 names no commit) placed refining by both triages, since the state it needs is a build that broke Database 2, and opened as a Ledger line because the cure is the Execution Contract's, a refining Rename row that said unused where Operation 2 says no other tag and a Rename to the tag's own name that wrote an identical version, both cured (Operation 7, Operation 21 and the row), its other refining item on Check 1.1 refuted; 2026-11-18 — Final Critique 1, frozen at 0c559850 — foundational count 1, cured by the settle, not clean, no sample

open: none
```

## Decisions

- **2026-11-18 — Taken in from MIT's Labeling concept, drafted through the Grace connector mirroring Reaction.** *Chose:* one flat list of tags per deployment, many per item, apply and remove safe to repeat, no tag removed. *Over:* MIT's scoped labels, whose duplicate apply and missing remove are refused. *Because:* Scott 2026-11-18: a forum gets both categories and tags; repeat-safe calls match Reaction's precedent, and one list per deployment is as simple as possible without losing fidelity.

NOTE: End of Tag.

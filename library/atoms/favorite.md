---
title: Favorite
id: 64
audience: common
---

# Favorite

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Favorite lets a person mark an item so they can find it again later: a product, a recipe, an article, anything the business shows them. On a screen it is a heart: one tap fills it, the next tap empties it. A person's favorites are that person's own list, and an item is on the list once or not at all. Emptying a heart does not throw the favorite away: it keeps the moment it was first marked, so filling the heart again puts the item back exactly where it was in the list the atom answers, and a slip of the finger costs one tap. The same tap arriving twice changes nothing the second time. A favorite stays on the list even when the item is discontinued or taken down, because the person saved it and should see what became of it. There is no limit on how many a person may keep. Whether an item is in stock, who is signed in, sharing a list with someone else, and counting how many people like an item each belong to another pattern, which is why one favorite serves a shop, a recipe site and a library alike.

<details markdown="block">
<summary>WHY</summary>

The shape recurs wherever a business shows people more than they can use today: a heart on a product, a star on a recipe, a bookmark on an article. Two decisions carry the weight. Marking and unmarking are two requests, each safe to repeat, so a double tap or a slow connection never undoes what the person meant. And unmarking keeps the first marked moment, so the list the atom answers never reshuffles because of a slip; how a page shows that list is the page's (Non-goal 6). What the item is, whether it can still be had, and who may look are other patterns' questions, and declining them is what lets one favorite serve products, recipes and articles alike.

</details>

## What it keeps

### The record

Term favorite: one person's mark on one item, kept from the first mark on — a [Favorite].

#### Favorite

Recorded by the first [Mark], stood in [Unmarked] by [Unmark] and back in [Marked] by [Mark]; never removed by the atom.

Kind: Type

```
Identity 1: The atom MUST identify a favorite by the favorite's pair.
```

Term pair: the person reference and the item reference a favorite carries, or a call names.

Term person reference: the string naming the person a favorite belongs to, in the deployment's own scheme — a [Person Reference]; the atom reads nothing in it.

#### Person Reference

Stored as supplied and compared codepoint for codepoint; whether the caller is that person is the composing pattern's question.

Kind:       Field
Field of:   Favorite
Projection: person_reference

```
Identity 2: The atom MUST NOT normalize a person reference.
Identity 3: The atom MUST compare two person references code point for code point.
```

Term item reference: the string naming the item a favorite is for, such as a product, a recipe or an article, in the deployment's own scheme — an [Item Reference]; the atom reads nothing in it.

#### Item Reference

Stored as supplied and compared codepoint for codepoint; whether it names a real item, and whether that item can still be had, are a catalog's questions.

Kind:       Field
Field of:   Favorite
Projection: item_reference

```
Identity 4: The atom MUST NOT normalize an item reference.
Identity 5: The atom MUST compare two item references code point for code point.
```

Term first marked instant: the instant of the first [Mark] call that recorded a favorite — the [First Marked Instant]; set once, never changed.

#### First Marked Instant

Stamped from the injected now, so a favorite unmarked and marked again keeps it.

Kind:       Field
Field of:   Favorite
Projection: first_marked_instant

Term status: where a favorite stands, marked or unmarked — the [Status].

#### Status

Holds [Marked] or [Unmarked].

Kind:       Field
Field of:   Favorite
Projection: status

Term marked: the status of a favorite the person keeps — [Marked]; the heart is filled.

#### Marked

[Look Up]'s answer for one.

Kind:       Member
Member of:  the status
Projection: marked

Term unmarked: the status of a favorite the person has let go — [Unmarked]; the heart is empty, and the favorite keeps its first marked instant.

#### Unmarked

[Look Up]'s answer for one and for a pair with no favorite.

Kind:       Member
Member of:  the status
Projection: unmarked

```
State 1: EVERY favorite MUST carry person reference, item reference, first marked instant and status.
State 2: EVERY favorite MUST stand in EXACTLY ONE OF marked, unmarked.
State 3: The atom MUST NOT remove a favorite.
```

## What people do

### Every action

Term writing action: [Mark] | [Unmark] — the actions that change a favorite.

```
Operation 1: IF the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN a writing action MUST answer invalid-person-reference.
Operation 2: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a writing action MUST answer invalid-item-reference.
Operation 20: IF the person reference is malformed THEN a writing action MUST answer invalid-person-reference (Execution Contract Input 1).
Operation 21: IF the item reference is malformed THEN a writing action MUST answer invalid-item-reference (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the favorites |
|---|---|---|---|
| a writing action | person reference blank, over the string cap, or not a string | [Invalid Person Reference] | none (Operation 1, Operation 20) |
| a writing action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 2, Operation 21) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Invalid Person Reference

The refusal of a blank [Person Reference], one over the string cap, or one that is not a string, on [Mark] or [Unmark] (Operation 1, Operation 20).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string, on [Mark] or [Unmark] (Operation 2, Operation 21).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Storage Failure

The refusal [Mark] or [Unmark] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

### Mark

Marks an item as a person's favorite: records the [Favorite] where the pair has none, stamping its [First Marked Instant], or stands an [Unmarked] favorite back in [Marked], leaving its first marked instant as it was. A favorite already marked is left as it is. Answers ok.

Kind: Operation

```
mark(person_reference, item_reference)
  answers ok
  refuses invalid-person-reference | invalid-item-reference | storage-failure
```

```
Operation 3: IF no favorite EXISTS for the pair THEN [Mark] MUST record EXACTLY ONE favorite carrying the person reference AND the item reference of the call.
Operation 4: IF no favorite EXISTS for the pair THEN [Mark] MUST stamp first marked instant from the injected now.
Operation 5: IF no favorite EXISTS for the pair THEN [Mark] MUST stand the favorite in marked.
Operation 6: IF the favorite's status EQUALS unmarked THEN [Mark] MUST stand the favorite in marked.
Operation 7: IF the favorite's status EQUALS marked THEN [Mark] MUST NOT write.
Operation 8: [Mark] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the favorites |
|---|---|---|---|
| [Mark] | both references valid, no favorite for the pair, database accepts | ok | one favorite lands, marked, its first marked instant now (Operation 3 through 5, Invariant 1.1) |
| [Mark] | both references valid, the favorite stands unmarked | ok | the favorite stands marked; its first marked instant, person reference and item reference stand (Operation 6, Invariant 2.1, Invariant 2.2, Invariant 2.3) |
| [Mark] | both references valid, the favorite stands marked | ok | none, no write (Operation 7) |

- `mark("", "kettle-blue")` — rejected as [Invalid Person Reference]: the reference is blank.
- `mark("ana", "   ")` — rejected as [Invalid Item Reference]: the reference is blank.
- `mark("", "")` — rejected as [Invalid Person Reference]: two refusals apply, and the one listed first on [Mark]'s refuses line answers (Execution Contract Refusal 1).
- `mark(42, "kettle-blue")` — rejected as [Invalid Person Reference]: the reference is not a string (Operation 20).

### Unmark

Lets a favorite go: stands a [Marked] favorite in [Unmarked] and removes nothing. A favorite already unmarked, or a pair with no favorite, is left as it is. Answers ok.

Kind: Operation

```
unmark(person_reference, item_reference)
  answers ok
  refuses invalid-person-reference | invalid-item-reference | storage-failure
```

```
Operation 9: IF the favorite's status EQUALS marked THEN [Unmark] MUST stand the favorite in unmarked.
Operation 10: IF the favorite's status EQUALS unmarked THEN [Unmark] MUST NOT write.
Operation 11: IF no favorite EXISTS for the pair THEN [Unmark] MUST NOT write.
Operation 12: [Unmark] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the favorites |
|---|---|---|---|
| [Unmark] | both references valid, the favorite stands marked | ok | the favorite stands unmarked; its person reference and item reference stand; nothing is removed (Operation 9, State 3, Invariant 2.2, Invariant 2.3) |
| [Unmark] | both references valid, the favorite stands unmarked or no favorite for the pair | ok | none, no write (Operation 10, Operation 11) |

- `unmark("ana", "Kettle-Blue")` — answers ok and writes nothing: two item references are compared codepoint for codepoint, and neither the atom nor the deployment normalizes one, so `ana` holds no favorite for that one (Identity 5, Capability requirement 5, Operation 11).

### Look Up

Answers whether one item is a person's favorite now, [Marked] or [Unmarked], and changes nothing; a pair with no favorite answers unmarked.

Kind: Operation

```
look_up(person_reference, item_reference)
  answers marked | unmarked

```

```
Operation 13: [Look Up] MUST answer EXACTLY ONE OF marked, unmarked.
Operation 14: [Look Up] MUST answer marked ONLY IF a marked favorite EXISTS for the pair.
Operation 15: [Look Up] MUST NOT write.
Operation 22: IF the person reference is malformed OR the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Look Up] MUST answer unmarked (Execution Contract Query 5).
Operation 23: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Look Up] MUST answer unmarked (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the favorites |
|---|---|---|---|
| [Look Up] | a marked favorite for the pair | marked | none (Operation 14, Operation 15) |
| [Look Up] | an unmarked favorite, or none, for the pair | unmarked | none (Operation 13, Operation 15) |
| [Look Up] | a person reference or an item reference blank, over the string cap, or not a string | unmarked | none (Operation 22, Operation 23) |

- `look_up("", "kettle-blue")` — answers unmarked: the reference is blank, and no favorite carries a blank reference (Operation 22).

### List

Answers every [Marked] favorite of one person, each with its [Item Reference] and [First Marked Instant], and changes nothing; an empty list where the person keeps none.

Kind: Operation

```
list(person_reference)
  answers favorites(item_reference, first_marked_instant)
```

```
Operation 16: [List] MUST answer EVERY marked favorite carrying the person reference.
Operation 17: [List] MUST answer a favorite's item reference AND first marked instant.
Operation 18: [List] MUST answer an empty list for a person reference no marked favorite carries.
Operation 19: [List] MUST NOT write.
Operation 24: IF the person reference is malformed OR the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [List] MUST answer an empty list (Execution Contract Query 5).
Operation 25: [List] MUST answer favorites by first marked instant, earliest first, then by item reference (Execution Contract Read 5, Execution Contract Logic confinement 10).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the favorites |
|---|---|---|---|
| [List] | the person keeps marked favorites | each one's item reference and first marked instant, earliest first, then by item reference | none (Operation 16, Operation 17, Operation 19, Operation 25) |
| [List] | the person keeps none, or the person reference is blank, over the string cap, or not a string | an empty list | none (Operation 18, Operation 24) |

## What is and what should never be (Invariants)

- **Invariant 1 — An item is a person's favorite once or not at all.**
  ```
  Invariant 1.1: Two favorites MUST NOT share a pair.
  ```

- **Invariant 2 — A favorite never moves.**
  ```
  Invariant 2.1: The atom MUST NOT change a favorite's first marked instant.
  Invariant 2.2: The atom MUST NOT change a favorite's person reference.
  Invariant 2.3: The atom MUST NOT change a favorite's item reference.
  ```

## When something happens

### Concurrency

Two [Mark] calls for one pair are serialized (Execution Contract Database 2): the later reads the favorite the earlier recorded and writes nothing, so a person never holds two favorites for one item (Invariant 1.1). A [Mark] and an [Unmark] for one pair are serialized the same way, and the favorite stands where the later call left it.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Mark] where the first landed writes nothing and answers ok; a repeated [Unmark] where the first landed writes nothing and answers ok. So a caller repeats either call freely, and a caller needing the truth asks [Look Up].

### An item that is no longer offered

The atom keeps a favorite whatever becomes of the item (State 3, Non-goal 4). The composing pattern that shows the list reads the item's availability from the deployment's catalog and shows it beside the favorite.

### What undoes a write

[Unmark] undoes [Mark] and [Mark] undoes [Unmark], and State 3 keeps the favorite either way, so no undo is owed beyond the pair (Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
```

Term string cap: the bound on a person reference's length and on an item reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

NOTE: Capability requirement 4 and Capability requirement 5 are the atom's own rule for the canonical form of each reference, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each person reference and each item reference is recorded as the call carries it (Execution Contract Input 4; Identity 2 through 5).

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may read a person's favorites.
Non-goal 2: The atom MUST NOT tell who may change a person's favorites.
Non-goal 3: The atom MUST NOT check an item reference against a catalog.
Non-goal 4: The atom MUST NOT hold an item's availability.
Non-goal 5: The atom MUST NOT share a person's favorites.
Non-goal 6: The atom MUST NOT order a person's favorites for display.
Non-goal 7: The atom MUST NOT count the persons marking an item.
Non-goal 8: The atom MUST NOT hold a save-for-later list.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3, 4; External check 1); Favorite Sharing *(forthcoming)* (Non-goal 5); the composing pattern that shows the list, in whatever order it sets (Non-goal 6); Reaction *(forthcoming)* (Non-goal 7); Save For Later *(forthcoming)* (Non-goal 8).

NOTE: watch the order an atom forbids — [List]'s answer comes in the order Operation 25 states, which stands in place of Execution Contract Read 5's default order, and any other order a page shows is the composing pattern's (Non-goal 6).

Where the atom breaks down: a list an item leaves when the person is done with it, which is save for later; a mark other people are meant to see and count, which is a reaction.

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the person reference of the caller the composing pattern authenticated.
```

NOTE: composing patterns — none yet. Forthcoming: Catalog, Favorite Sharing.

## Example

A shopper, `ana`, taps the heart on a blue kettle: `mark("ana", "kettle-blue")` answers ok, and the favorite's first marked instant is that moment, 9:14 on Monday. She marks a teapot on Tuesday. Her favorites page asks `list("ana")` and is answered the kettle, then the teapot, each with its first marked instant, and the page, which sets its own order (Non-goal 6), shows the teapot above the kettle. On Wednesday she taps the kettle's heart by mistake: `unmark("ana", "kettle-blue")` answers ok, and the kettle leaves what `list("ana")` answers, while the shop still shows the kettle with an empty heart. She taps it again: `mark("ana", "kettle-blue")` answers ok, and the kettle is marked with the first marked instant it always had, 9:14 on Monday, so `list("ana")` answers it first again. Nothing moved. A week later the shop discontinues the kettle; `list("ana")` still answers it, and the page shows it as discontinued from the shop's own catalog.

A recipe site reads the same list a heart at a time: `look_up("r7", "recipe-lentil-soup")` answers marked for a recipe the cook starred and `look_up("r7", "recipe-flatbread")` answers unmarked for one never marked, and a star sent twice answers ok the second time and writes nothing.

## Source

Favorite is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design. The concept was raised in the Concept Design Community forum's concept catalog, where a favorite is a user saving an item for their own review later.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the favorites the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY favorite carrying person reference, item reference, first marked instant AND status (State 1).
Check 1.2: An auditor MUST find EVERY favorite standing in EXACTLY ONE OF marked, unmarked (State 2).
Check 2.1: An auditor MUST find no two favorites sharing a pair (Invariant 1.1).
Check 3.1: An auditor MUST find EVERY version of a favorite carrying the first marked instant of the favorite's first version (Invariant 2.1).
Check 3.2: An auditor MUST find EVERY version of a favorite carrying the person reference of the favorite's first version (Invariant 2.2).
Check 3.3: An auditor MUST find EVERY version of a favorite carrying the item reference of the favorite's first version (Invariant 2.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a favorite; a writing action; an auditor.

Term records: favorite — one person's mark on one item, carrying person reference, item reference, first marked instant and status.

Term record verbs: identify, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, write, change, share, find, read, tell, check, hold, order, count, own, refuse.

Term value sets: writing action is declared above and cited here (GRACE-lang Closed vocabulary 15); status — marked | unmarked; action rejection — invalid-person-reference | invalid-item-reference | storage-failure.

Term bounds: string cap (the bound on a person reference's length and on an item reference's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-14) through the Grace connector.

Term terms: favorite, favorites, pair, person reference, item reference, string cap, seam, first marked instant, status, marked, unmarked, writing action, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Mark]: #mark
[Unmark]: #unmark
[Look Up]: #look-up
[List]: #list
[Favorite]: #favorite
[Person Reference]: #person-reference
[Item Reference]: #item-reference
[First Marked Instant]: #first-marked-instant
[Status]: #status
[Marked]: #marked
[Unmarked]: #unmarked
[Invalid Person Reference]: #invalid-person-reference
[Invalid Item Reference]: #invalid-item-reference
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-17` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-17
formal: verified — favorite.als + 7 twins (the static data model: State 1 and 2, Identity 3 and 5, Operation 3, 4 and 5, Invariant 1.1 checked on every version a sequence of admitted calls leaves, Identity 1 caught by the Invariant 1.1 check, Identity 2 and 4 by the Operation 3 check); favorite.tla + 24 twins (across steps: State 3, Invariant 2.1 through 2.3, Operation 1 through 3 and 6 through 25, the other half of Operation 14 and 16 read from the terms Look Up and List); on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), neither vetoed, 2026-11-14
last gate: 2026-11-21 — Final Critique 6, a delta round, one reader (Linus beam-free), frozen at 79bd1a91 — foundational count 0 after the blind second triage, clean, one sample (Linus's three findings, all refining Kind B, none foundational: that Invariant 1.1 is no standard sentence because a pair is no field, which stays as written, a key over several fields written over a Term that lists them, as Scott's ruling of 2026-11-19 gives the form and the IR does not yet read it, the advisory named in the reorganise commit; and that Operation 8, 12, 13 and 18 do not acknowledge state-unavailable on a failed read, refuted by both triages, since Execution Contract Read 2 limits every rule that says what an action answers to a call whose read answered, Read 4 limits a rule that says what an action does to a call it admits, the page cites Read 1 through 6 in Capability requirement 1 and states the failed read in its case table, and a restatement would break Authority 6; the blind second triage placed all three rhetorical, Kind D; no page cure); 2026-11-17 — Final Critique 5, a delta round, frozen at b2e418cf — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Input 2 bars a zero string cap only on a deployment's declaration and not on a specification's default, placed refining, Kind B, by both triages: its two implementations serve different specifications and Favorite's default is 1,024; refining 2 on the Execution Contract; all three cured by held replacements to the Execution Contract, none by the page); 2026-11-17 — Final Critique 4, a delta round, frozen at f7caec5a — foundational count 1 after the blind second triage, cured by a held cure, not clean, one sample (Linus's three foundational reports, all on the Execution Contract and reached through Capability requirement 3: F1, that Logic confinement 17 names no start for an instance with no scheduled leg, and F3, that Input 2 counts the cap on two bases, both refuted by both triages, F3 since Capability requirement 4 and 5 and the NOTE at page line 57 replace Logic confinement 13 here and the carried value finds the record; F2, that Input 2's start-time floor and Logic confinement 17 permit an unplanned restart to start the instance on a declared cap a held value exceeds, which the blind second triage placed foundational, Kind A, cured by two held replacements to the Execution Contract; refining 1 and rhetorical 1 not cured); 2026-11-17 — Final Critique 3, a delta round, frozen at d9b6ee5a — foundational count 1, cured by a held cure, not clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./favorite.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/favorite.md`.

</details>

NOTE: End of Favorite.

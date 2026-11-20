---
title: Reaction
id: 65
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Reaction

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Reaction lets a person answer an item with one word from a short list the business offers: "Like" on a post, "Thanks" on an answer, or a small set such as Like, Love and Angry. Choosing a reaction holds it; where a person may hold one in all, choosing a different one replaces the first; taking a reaction back leaves the item as if the person had never reacted. Everyone can see how many people hold each reaction on an item. The business makes two choices. The first is the list of reactions, from a single Like to a handful. The second is how many a person may hold on one item: one in all, as on Facebook, or one of each, as on Slack and GitHub. The same request arriving twice changes nothing the second time, unless another request on the same item landed between them. A reaction says the item drew a person's attention, an angry one included; it is not approval, not a vote and not a saved item. Who may react, what the item is, telling the item's author, and any score built from the counts each belong to another pattern — another separately specified building block of the same kind — which is why one reaction serves a forum, a shop's reviews and a team chat alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Wherever people are shown items other people made, they want to answer without writing: a like on a post, a thumb on a review, a small face on a message. This atom is that and nothing more. Three decisions carry the weight. Reacting and taking back are two requests, each safe to repeat, so a double tap or a slow connection never undoes what the person meant; the screen sends whichever fits the control it is showing. A reaction taken back is kept as withdrawn and counts for nothing, so the count is always the reactions held now and a slip costs one tap. And the list of reactions and the number a person may hold on an item are the deployment's two settings, not two patterns: the record and the requests are the same whether the business offers one Like or six faces. Every reaction is named by its word, never by its picture, so a thumb is "like" and how it is drawn is the page's. Who may react, whether the item exists, and what a count is worth are other patterns' questions, and declining them is what lets one reaction serve posts, reviews and messages alike.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a reaction by the reaction's triple.
Identity 2: The atom MUST NOT normalize a person reference.
Identity 3: The atom MUST compare two person references codepoint for codepoint.
Identity 4: The atom MUST NOT normalize an item reference.
Identity 5: The atom MUST compare two item references codepoint for codepoint.
Identity 6: The atom MUST NOT normalize a reaction name.
Identity 7: The atom MUST compare two reaction names codepoint for codepoint.
```

Term reaction: one person's answer to one item in one reaction name, kept from the first time the person chose it — a [Reaction].

Term triple: the person reference, the item reference and the reaction name a reaction carries, or a call names.

Term pair: the person reference and the item reference a reaction carries, or a call names.

Term person reference: the string naming the person a reaction belongs to, in the deployment's own scheme — a [Person Reference]; the atom reads no scheme in it; malformed where it is no string.

Term item reference: the string naming the item a reaction answers, such as a post, a review or a message, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it; malformed where it is no string.

Term reaction name: the string naming which reaction a person chose, such as like — a [Reaction Name]; a word, never a picture; malformed where it is no string.

Term reaction set: the reaction names a deployment offers; the single name like where a deployment declares none.

Term holding rule: how many reactions a person may hold on one item, one-per-item or one-of-each — the [Holding Rule]; one-per-item where a deployment declares none.

Term string cap: the bound on a person reference's length, on an item reference's length and on a reaction name's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

NOTE: Capability requirement 4 through 6 are the atom's own rule for the canonical form of each reference and of the reaction name, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each is recorded as the call carries it (Execution Contract Input 4; Identity 2 through 7).

### State

```
State 1: EVERY reaction MUST carry person reference, item reference, reaction name, first reacted instant and status.
State 2: EVERY reaction MUST stand in EXACTLY ONE OF held, withdrawn.
State 3: The atom MUST NOT remove a reaction.
```

Term first reacted instant: the instant of the first [React] call that recorded a reaction — the [First Reacted Instant]; set once, never changed.

Term status: where a reaction stands, held or withdrawn — the [Status].

Term held: the status of a reaction the person keeps on the item — [Held]; the reaction counts.

Term withdrawn: the status of a reaction the person took back or replaced — [Withdrawn]; the reaction counts for nothing.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 6: The deployment MUST NOT normalize a reaction name at the seam.
Capability requirement 7: The deployment MAY declare the reaction set PER Execution Contract Logic confinement 17.
Capability requirement 8: The deployment MAY declare the holding rule PER Execution Contract Logic confinement 17.
Capability requirement 9: IF a member of the reaction set EQUALS blank OR a member of the reaction set EXCEEDS the string cap THEN the deployment MUST NOT declare the reaction set.
Capability requirement 10: IF a member of the reaction set EXCEEDS the string cap THEN the deployment MUST NOT declare the string cap.
```

### Operations

```
react(person_reference, item_reference, reaction_name)
  answers ok
  refuses invalid-person-reference | invalid-item-reference | invalid-reaction-name | storage-failure

withdraw(person_reference, item_reference, reaction_name)
  answers ok
  refuses invalid-person-reference | invalid-item-reference | invalid-reaction-name | storage-failure

look_up(person_reference, item_reference)
  answers reaction_names(reaction_name)

count(item_reference)
  answers tallies(reaction_name, tally)
```

```
Operation 1: IF the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN a writing action MUST answer invalid-person-reference.
Operation 2: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a writing action MUST answer invalid-item-reference.
Operation 3: IF the reaction name EQUALS blank OR the reaction name EXCEEDS the string cap THEN a writing action MUST answer invalid-reaction-name.
Operation 4: IF no member of the reaction set EQUALS the reaction name THEN [React] MUST answer invalid-reaction-name.
Operation 5: IF no reaction EXISTS for the triple THEN [React] MUST record EXACTLY ONE reaction carrying the triple of the call.
Operation 6: IF no reaction EXISTS for the triple THEN [React] MUST stamp first reacted instant from the injected now.
Operation 7: IF no reaction EXISTS for the triple THEN [React] MUST stand the reaction in held.
Operation 8: IF the reaction's status EQUALS withdrawn THEN [React] MUST stand the reaction in held.
Operation 9: IF the reaction's status EQUALS held THEN [React] MUST NOT change the reaction.
Operation 10: IF the holding rule EQUALS one-per-item THEN [React] MUST stand EVERY rival in withdrawn.
Operation 11: IF the holding rule EQUALS one-of-each THEN [React] MUST NOT change a rival.
Operation 12: [React] MUST answer ok.
Operation 13: IF the reaction's status EQUALS held THEN [Withdraw] MUST stand the reaction in withdrawn.
Operation 14: IF the reaction's status EQUALS withdrawn THEN [Withdraw] MUST NOT write.
Operation 15: IF no reaction EXISTS for the triple THEN [Withdraw] MUST NOT write.
Operation 16: [Withdraw] MUST answer ok.
Operation 17: [Look Up] MUST answer the reaction name of EVERY held reaction carrying the pair.
Operation 18: [Look Up] MUST answer an empty list for a pair no held reaction carries.
Operation 19: [Look Up] MUST NOT write.
Operation 20: [Count] MUST answer the tally of EVERY reaction name a held reaction carrying the item reference carries.
Operation 21: [Count] MUST answer an empty list for an item reference no held reaction carries.
Operation 22: [Count] MUST NOT write.
Operation 23: IF the person reference is malformed THEN a writing action MUST answer invalid-person-reference (Execution Contract Input 1).
Operation 24: IF the item reference is malformed THEN a writing action MUST answer invalid-item-reference (Execution Contract Input 1).
Operation 25: IF the reaction name is malformed THEN a writing action MUST answer invalid-reaction-name (Execution Contract Input 1).
Operation 26: IF the person reference is malformed OR the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
Operation 27: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
Operation 28: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Count] MUST answer an empty list (Execution Contract Query 5).
Operation 29: [Look Up] MUST answer reaction names in codepoint order (Execution Contract Read 5, Execution Contract Logic confinement 10).
Operation 30: [Count] MUST answer tallies in codepoint order of reaction name (Execution Contract Read 5, Execution Contract Logic confinement 10).
```

Term writing action: [React] | [Withdraw] — the actions that change a reaction, each answering [Ok] once admitted.

Term rival: a held reaction carrying the pair of the call and a reaction name other than the reaction name of the call.

Term tally: the number of held reactions carrying one item reference and one reaction name — a [Tally].

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the reactions |
|---|---|---|---|
| [React] | all three valid, the name in the reaction set, no reaction for the triple, database accepts | ok | one reaction lands, held, its first reacted instant now (Operation 5 through 7, Invariant 1.1) |
| [React] | all three valid, the name in the reaction set, the reaction stands withdrawn | ok | the reaction stands held; its first reacted instant, person reference, item reference and reaction name stand (Operation 8, Invariant 2.1, Invariant 2.2, Invariant 2.3, Invariant 2.4) |
| [React] | all three valid, the name in the reaction set, the reaction stands held | ok | the reaction is left as it is (Operation 9); under one-per-item any rival still held stands withdrawn (Operation 10) |
| [React] | the holding rule is one-per-item and the person holds another reaction on the item | ok | every rival stands withdrawn, in the same commit (Operation 10, Execution Contract Database 1) |
| [React] | the holding rule is one-of-each and the person holds another reaction on the item | ok | the rivals are left as they are (Operation 11) |
| [React] | the reaction name is not in the reaction set | [Invalid Reaction Name] | none (Operation 4) |
| [Withdraw] | all three valid, the reaction stands held | ok | the reaction stands withdrawn; its first reacted instant, person reference, item reference and reaction name stand; nothing is removed (Operation 13, State 3, Invariant 2.1, Invariant 2.2, Invariant 2.3, Invariant 2.4) |
| [Withdraw] | all three valid, the reaction stands withdrawn or no reaction for the triple | ok | none, no write (Operation 14, Operation 15) |
| a writing action | person reference blank, over the string cap, or not a string | [Invalid Person Reference] | none (Operation 1, Operation 23) |
| a writing action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 2, Operation 24) |
| a writing action | reaction name blank, over the string cap, or not a string | [Invalid Reaction Name] | none (Operation 3, Operation 25) |
| [Look Up] | the person holds reactions on the item | each one's reaction name, in codepoint order | none (Operation 17, Operation 19, Operation 29) |
| [Look Up] | the person holds none, or a reference is blank, over the string cap, or not a string | an empty list | none (Operation 18, Operation 26, Operation 27) |
| [Count] | the item has held reactions | each reaction name held, with its tally, in codepoint order of reaction name | none (Operation 20, Operation 22, Operation 30) |
| [Count] | the item has none, or the item reference is blank, over the string cap, or not a string | an empty list | none (Operation 21, Operation 28) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A person holds a reaction for one triple once or not at all.**
  ```
  Invariant 1.1: Two reactions MUST NOT share a triple.
  ```
- **Invariant 2 — A reaction never changes whose it is or what it says.**
  ```
  Invariant 2.1: The atom MUST NOT change a reaction's first reacted instant.
  Invariant 2.2: The atom MUST NOT change a reaction's person reference.
  Invariant 2.3: The atom MUST NOT change a reaction's item reference.
  Invariant 2.4: The atom MUST NOT change a reaction's reaction name.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Forum

A forum offers three reactions, like, love and angry, and keeps the holding rule it starts with, one-per-item. A reader, `ana`, likes a post: `react("ana", "post-41", "like")` answers ok, and `count("post-41")` answers like with a tally of 1. She changes her mind and chooses love: `react("ana", "post-41", "love")` answers ok, her like stands withdrawn in the same commit, and `count("post-41")` answers love with a tally of 1 and no like. She taps love again to take it back; the page, which is showing love as chosen, sends `withdraw("ana", "post-41", "love")`, and `count("post-41")` answers an empty list. Another reader's angry reaction counts as one reaction like any other: `count("post-41")` answers angry with a tally of 1, which says the post drew attention, not that anyone approves.

### Team chat

A chat declares the holding rule one-of-each and a reaction set of thanks, done and eyes. A teammate, `r7`, answers one message twice: `react("r7", "msg-9", "thanks")` and `react("r7", "msg-9", "eyes")` each answer ok, and `look_up("r7", "msg-9")` answers eyes and thanks. A slow connection sends the first request again; the second `react("r7", "msg-9", "thanks")` answers ok and changes nothing, and `count("msg-9")` still answers eyes with a tally of 1 and thanks with a tally of 1.

### Rejection paths

- `react("", "post-41", "like")` — rejected as [Invalid Person Reference]: the reference is blank.
- `react("ana", "   ", "like")` — rejected as [Invalid Item Reference]: the reference is blank.
- `react("ana", "post-41", "wow")` — rejected as [Invalid Reaction Name]: the forum's reaction set has no wow (Operation 4).
- `react("ana", "post-41", "Like")` — rejected as [Invalid Reaction Name]: two reaction names are compared codepoint for codepoint, and the set holds like (Identity 7, Operation 4).
- `react("", "", "")` — rejected as [Invalid Person Reference]: three refusals apply, and the one listed first on [React]'s refuses line answers (Execution Contract Refusal 1).
- `react(42, "post-41", "like")` — rejected as [Invalid Person Reference]: the reference is not a string (Operation 23).
- `withdraw("ana", "post-41", "angry")` — answers ok and writes nothing: `ana` holds no angry reaction on the post (Operation 15).
- `count("")` — answers an empty list: the reference is blank, and no reaction carries a blank reference (Operation 28).

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the reactions the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY reaction carrying person reference, item reference, reaction name, first reacted instant AND status (State 1).
Check 1.2: An auditor MUST find EVERY reaction standing in EXACTLY ONE OF held, withdrawn (State 2).
Check 2.1: An auditor MUST find no two reactions sharing a triple (Invariant 1.1).
Check 3.1: An auditor MUST find EVERY version of a reaction carrying the first reacted instant of the reaction's first version (Invariant 2.1).
Check 3.2: An auditor MUST find EVERY version of a reaction carrying the person reference of the reaction's first version (Invariant 2.2).
Check 3.3: An auditor MUST find EVERY version of a reaction carrying the item reference of the reaction's first version (Invariant 2.3).
Check 3.4: An auditor MUST find EVERY version of a reaction carrying the reaction name of the reaction's first version (Invariant 2.4).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT tell who may react to an item.
Non-goal 2: The atom MUST NOT tell who may read an item's reactions.
Non-goal 3: The atom MUST NOT check an item reference against a catalog.
Non-goal 4: The atom MUST NOT notify an item's author.
Non-goal 5: The atom MUST NOT score a person from the tallies.
Non-goal 6: The atom MUST NOT decide a vote.
Non-goal 7: The atom MUST NOT hold a person's favorites.
Non-goal 8: The atom MUST NOT hold a save-for-later list.
Non-goal 9: The atom MUST NOT draw a reaction.
Non-goal 10: The atom MUST NOT list the persons holding a reaction.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3; External check 1); the composing pattern that tells the author, such as one built on [Notification](./notification.md) (Non-goal 4); Reputation *(forthcoming)* (Non-goal 5); Vote *(forthcoming)* (Non-goal 6); [Favorite](./favorite.md) (Non-goal 7); Save For Later *(forthcoming)* (Non-goal 8); the composing pattern that shows the item, which draws each reaction name as it likes (Non-goal 9); Reactor List *(forthcoming)* (Non-goal 10).

Where the atom breaks down: a mark a person keeps for themselves to find an item again, which is a favorite; a choice that is counted to decide something, which is a vote; an answer in the person's own words, which is a [comment](./comment.md).

## Edge cases

### Concurrency

Two [React] calls for one triple are serialized (Execution Contract Database 2): the later reads the reaction the earlier recorded and changes nothing, so a person never holds one reaction twice (Invariant 1.1). Two [React] calls for one pair with two reaction names are serialized the same way: under one-per-item the later withdraws the earlier's reaction as a rival, and the reaction held is the later call's.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [React] where the first landed and nothing else on the item has changed since changes nothing and answers ok; a repeated [Withdraw] where the first landed and nothing else on the item has changed since writes nothing and answers ok. Where another call on the item landed between the two, the repeat meets what that call left (Operation 8, Operation 10, Operation 13); where the reaction set dropped the reaction name between the two, a repeated [React] is refused (Operation 4). So a caller repeats either call freely where nothing else changed, and a caller needing the truth asks [Look Up].

### A reaction set or a holding rule that changes

A deployment that drops a reaction name from the reaction set stops every [React] in that name (Operation 4), a repeat on a reaction already held in it included; the reactions already held in it stay held and counted, and each person may still withdraw theirs. A deployment that moves from one-of-each to one-per-item withdraws nothing by itself: a person's several held reactions stay until that person's next [React] on the item, which withdraws every rival (Operation 10).

### What undoes a write

[Withdraw] undoes [React] and [React] undoes [Withdraw], and State 3 keeps the reaction either way. A [React] that withdrew a rival is undone by a [React] in the rival's reaction name, so no undo is owed beyond the two calls (Execution Contract Undo 4).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the person reference of the caller the composing pattern authenticated.
```

NOTE: composing patterns — none yet. Forthcoming: Reputation, Reactor List.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a reaction; a writing action; an auditor.

Term records: reaction — one person's answer to one item in one reaction name, carrying person reference, item reference, reaction name, first reacted instant and status.

Term record verbs: identify, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, write, change, share, find, read, tell, check, notify, score, decide, hold, draw, list, own, refuse.

Term value sets: writing action is declared above and cited here (GRACE-lang Closed vocabulary 15); status — held | withdrawn; holding rule — one-per-item | one-of-each; action rejection — invalid-person-reference | invalid-item-reference | invalid-reaction-name | storage-failure.

Term bounds: string cap (the bound on a person reference's length, on an item reference's length and on a reaction name's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-14) through the Grace connector.

Term terms: reaction, reactions, triple, pair, person reference, item reference, reaction name, reaction names, reaction set, holding rule, string cap, seam, first reacted instant, status, held, withdrawn, writing action, rival, tally, tallies, version.

#### React

Holds a reaction for a person on an item: records the [Reaction] where the triple has none, stamping its [First Reacted Instant], or stands a [Withdrawn] reaction back in [Held]. A reaction already held is left as it is. Under the [Holding Rule] one-per-item it also stands the person's other held reactions on the item in withdrawn. Answers ok.

Kind: Operation

#### Withdraw

Takes a reaction back: stands a [Held] reaction in [Withdrawn] and removes nothing. A reaction already withdrawn, or a triple with no reaction, is left as it is. Answers ok.

Kind: Operation

#### Look Up

Answers the [Reaction Name] of every reaction one person holds on one item now, and changes nothing; an empty list where the person holds none.

Kind: Operation

#### Count

Answers, for one item, each [Reaction Name] held on it with its [Tally], and changes nothing; an empty list where the item has no held reaction.

Kind: Operation

#### Reaction

One person's answer to one item in one reaction name: recorded by the first [React], stood in [Withdrawn] by [Withdraw] or by a replacing [React], and back in [Held] by [React]; never removed by the atom.

Kind: Type

#### Person Reference

Names the person a reaction belongs to, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; the atom reads no scheme in it, and whether the caller is that person is the composing pattern's question.

Kind:       Field
Field of:   Reaction
Projection: person_reference

#### Item Reference

Names the item a reaction answers, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; the atom reads no scheme in it, and whether it names a real item is a catalog's question.

Kind:       Field
Field of:   Reaction
Projection: item_reference

#### Reaction Name

The string naming which reaction the person chose, one of the reaction set the deployment offered when the reaction was recorded, such as like. Stored as supplied and compared codepoint for codepoint; how it is drawn is the page's.

Kind:       Field
Field of:   Reaction
Projection: reaction_name

#### First Reacted Instant

The instant of the [React] call that recorded the reaction, stamped from the injected now; never changed, so a reaction withdrawn and held again keeps it.

Kind:       Field
Field of:   Reaction
Projection: first_reacted_instant

#### Status

Where a reaction stands: [Held] or [Withdrawn].

Kind:       Field
Field of:   Reaction
Projection: status

#### Held

The status of a reaction the person keeps on the item; it is counted in the item's [Tally] for its reaction name.

Kind:       Member
Member of:  the status
Projection: held

#### Withdrawn

The status of a reaction the person took back or replaced; it is counted in no tally.

Kind:       Member
Member of:  the status
Projection: withdrawn

#### Holding Rule

The deployment's setting for how many reactions a person may hold on one item: one in all (one-per-item, the rule where none is declared) or one in each reaction name (one-of-each).

Kind:       Type
Projection: holding_rule

#### Tally

The number of held reactions carrying one item reference and one reaction name, as [Count] answers it.

Kind:       Type
Projection: tally

#### Ok

The answer [React] and [Withdraw] give once the call is admitted (Operation 12, Operation 16), whether or not the call changed the reaction; it carries nothing.

Kind:       Member
Member of:  the action answer
Role:       Outcome
Projection: ok

#### Invalid Person Reference

The refusal of a blank [Person Reference], one over the string cap, or one that is not a string, on [React] or [Withdraw] (Operation 1, Operation 23).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string, on [React] or [Withdraw] (Operation 2, Operation 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Invalid Reaction Name

The refusal of a blank [Reaction Name], one over the string cap, or one that is not a string, on [React] or [Withdraw], and of a name the reaction set does not offer on [React] (Operation 3, Operation 4, Operation 25).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-reaction-name

#### Storage Failure

The refusal [React] or [Withdraw] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[React]: #react
[Withdraw]: #withdraw
[Look Up]: #look-up
[Count]: #count
[Reaction]: #reaction
[Person Reference]: #person-reference
[Item Reference]: #item-reference
[Reaction Name]: #reaction-name
[First Reacted Instant]: #first-reacted-instant
[Status]: #status
[Held]: #held
[Withdrawn]: #withdrawn
[Holding Rule]: #holding-rule
[Tally]: #tally
[Ok]: #ok
[Invalid Person Reference]: #invalid-person-reference
[Invalid Item Reference]: #invalid-item-reference
[Invalid Reaction Name]: #invalid-reaction-name
[Storage Failure]: #storage-failure

---

## Standards references

Reaction is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design. The concept was raised twice in the Concept Design Community forum: as the question of what a like is, and as the sample catalog entry Upvote, also known as Like.

---

## Status

`doing` — see the Ledger.

## Ledger

```
status: doing
formal: verified — reaction.als + 8 twins (the static data model: State 1 and 2, Identity 3, 5 and 7, Operation 4 through 7, Invariant 1.1 checked on every version a sequence of admitted calls leaves, Identity 1 caught by the Invariant 1.1 check, Identity 2, 4 and 6 by the Operation 5 check); reaction.tla + 30 twins (across steps, under either holding rule and a reaction set the deployment may change between calls: State 3, Invariant 2.1 through 2.4, Operation 1 through 5 and 8 through 30, the other half of Operation 17 and 20 read from the terms Look Up and Count); on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), neither vetoed, 2026-11-15
last gate: 2026-11-17 — Final Critique 2, a delta round, frozen at 9bb9b4a — foundational count 0 after the blind second triage, clean, one sample

open: none
```

## Decisions

Decisions are kept in [the pattern's history](./reaction.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/reaction.md`.

NOTE: End of Reaction.

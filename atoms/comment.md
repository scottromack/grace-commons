---
title: Comment
id: 70
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Comment

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Comment lets people answer an item in their own words — a post, a product, a photo — and answer each other, so the comments on an item form a tree of replies. Every comment has one author for good; only that author can change the wording or take the comment back. A comment taken back keeps its place in the tree, so the replies under it still make sense, but shows no words. Every earlier wording stays readable to an auditor, because the database keeps each version of the record. Who may comment, whether the item exists, hiding someone else's comment, reactions on a comment, and telling the item's author each belong to another pattern, which is why one comment serves a forum, a shop's reviews and a photo page alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Wherever people are shown something, they want to say something about it, and then to answer what others said. This atom is that and nothing more. Three decisions carry the weight. A comment either answers the item or answers another comment, and a reply always sits on the same item as the comment it answers, so the tree never crosses items. Only the author changes or takes back a comment, so one person can never erase another's words through this atom; a moderator's hiding is a different act, owned elsewhere. And a comment taken back is kept as retracted with its place in the tree, so replies are never orphaned and the record of what was said survives in the database's history. The item is named by the deployment's own reference and never read, which is why one comment serves any item. Taken in from the Massachusetts Institute of Technology's sync-engine Commenting concept (Daniel Jackson's group), which removes a retracted comment and has no replies; a forum needs the tree and the history, so this one keeps both.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a comment by the comment's comment id.
Identity 2: The atom MUST assign EVERY comment a comment id no other comment carries.
Identity 3: The atom MUST NOT normalize an author reference.
Identity 4: The atom MUST compare two author references codepoint for codepoint.
Identity 5: The atom MUST NOT normalize a target reference.
Identity 6: The atom MUST compare two target references codepoint for codepoint.
```

Term comment: one person's words on one item, answering the item or another comment on the item — a [Comment].

Term comment id: the string the atom assigns a comment when the comment is added — a [Comment Id].

Term target reference: the string naming the item a comment is on, such as a post, a product or a photo, in the deployment's own scheme — a [Target Reference]; the atom reads no scheme in it.

Term author reference: the string naming the person who wrote a comment, in the deployment's own scheme — an [Author Reference]; the atom reads no scheme in it.

Term text: the comment's words as the author wrote them — the [Text].

Term reply: a comment answering another comment on the same item, recorded by [Reply].

Term parent: the comment a reply answers — the [Parent].

Term string cap: the bound on a target reference's length and on an author reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term text cap: the bound on a text's length in Unicode code points; 10,000 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

### State

```
State 1: EVERY comment MUST carry comment id, target reference, author reference, text, added instant and status.
State 2: EVERY comment MUST stand in EXACTLY ONE OF shown, retracted.
State 3: EVERY reply MUST carry the comment id of the reply's parent.
State 4: EVERY reply MUST carry the target reference of the reply's parent.
State 5: The atom MUST NOT remove a comment.
```

Term added instant: the instant of the call that recorded the comment — the [Added Instant]; set once, never changed.

Term status: where a comment stands, shown or retracted — the [Status].

Term shown: the status of a comment whose words are read — [Shown].

Term retracted: the status of a comment the author took back — [Retracted]; the comment keeps a place in the tree and shows no words.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MAY declare the text cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 5: The deployment MUST NOT normalize an author reference at the seam.
Capability requirement 6: The deployment MUST NOT normalize a target reference at the seam.
Capability requirement 7: The deployment MUST supply EVERY comment id PER Execution Contract Logic confinement 16.
```

NOTE: Capability requirement 5 and 6 are the atom's own rule for the canonical form of each reference, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each is recorded as the call carries it (Execution Contract Input 4; Identity 3 through 6).

### Operations

```
add(target_reference, author_reference, text)
  answers comment_id
  refuses invalid-target-reference | invalid-author-reference | invalid-text | storage-failure

reply(comment_id, author_reference, text)
  answers comment_id
  refuses unknown-comment | invalid-author-reference | invalid-text | storage-failure

edit(comment_id, author_reference, text)
  answers ok
  refuses unknown-comment | invalid-author-reference | not-author | comment-retracted | invalid-text | storage-failure

retract(comment_id, author_reference)
  answers ok
  refuses unknown-comment | invalid-author-reference | not-author | storage-failure

list(target_reference)
  answers comments(comment_id, parent_comment_id, author_reference, text, added_instant, status)
```

```
Operation 1: IF the target reference EQUALS blank OR the target reference EXCEEDS the string cap THEN [Add] MUST answer invalid-target-reference.
Operation 2: IF the author reference EQUALS blank OR the author reference EXCEEDS the string cap THEN a writing action MUST answer invalid-author-reference.
Operation 3: IF the text EQUALS blank OR the text EXCEEDS the text cap THEN a wording action MUST answer invalid-text.
Operation 4: IF the comment id is malformed OR no comment carries the comment id THEN a comment action MUST answer unknown-comment (Execution Contract Input 3).
Operation 5: [Add] MUST record EXACTLY ONE comment carrying the target reference, the author reference and the text of the call.
Operation 6: [Reply] MUST record EXACTLY ONE reply carrying the author reference and the text of the call.
Operation 7: [Reply] MUST stamp the reply with the comment id AND the target reference of the parent the call names.
Operation 8: A recording action MUST stamp added instant from the injected now.
Operation 9: A recording action MUST stand the comment in shown.
Operation 10: A recording action MUST answer the comment id of the comment the action recorded.
Operation 11: IF the author reference differs from the comment's author reference THEN [Edit] MUST answer not-author.
Operation 12: IF the author reference differs from the comment's author reference THEN [Retract] MUST answer not-author.
Operation 13: IF the comment's status EQUALS retracted THEN [Edit] MUST answer comment-retracted.
Operation 14: [Edit] MUST replace the comment's text with the text of the call.
Operation 15: [Edit] MUST answer ok.
Operation 16: IF the comment's status EQUALS shown THEN [Retract] MUST stand the comment in retracted.
Operation 17: IF the comment's status EQUALS retracted THEN [Retract] MUST NOT write.
Operation 18: [Retract] MUST answer ok.
Operation 19: [List] MUST answer EVERY comment carrying the target reference, in added instant order, oldest first, then in codepoint order of comment id.
Operation 20: [List] MUST answer blank text for EVERY retracted comment.
Operation 21: [List] MUST answer an empty list for a target reference no comment carries.
Operation 22: [List] MUST NOT write.
Operation 23: IF the target reference is malformed THEN [Add] MUST answer invalid-target-reference (Execution Contract Input 1).
Operation 24: IF the author reference is malformed THEN a writing action MUST answer invalid-author-reference (Execution Contract Input 1).
Operation 25: IF the text is malformed THEN a wording action MUST answer invalid-text (Execution Contract Input 1).
Operation 26: IF the target reference is malformed OR the target reference EQUALS blank OR the target reference EXCEEDS the string cap THEN [List] MUST answer an empty list (Execution Contract Query 5).
Operation 27: [List] MUST answer the comment id of the parent for EVERY reply.
Operation 28: [List] MUST answer a blank parent comment id for EVERY comment that is not a reply.
```

Term writing action: [Add] | [Reply] | [Edit] | [Retract] — the actions that change a comment.

Term recording action: [Add] | [Reply] — the actions that record a new comment.

Term wording action: [Add] | [Reply] | [Edit] — the actions that set a text.

Term comment action: [Reply] | [Edit] | [Retract] — the actions that name a comment by comment id.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the comments |
|---|---|---|---|
| [Add] | target reference, author reference and text valid, database accepts | the comment id | one comment lands on the item, shown, its added instant now (Operation 5, Operation 8 through 10) |
| [Reply] | the parent exists, author reference and text valid | the comment id | one reply lands under the parent, on the parent's item, shown (Operation 6 through 10, State 3, State 4) |
| [Reply] | the parent stands retracted | the comment id | the reply lands; the parent keeps a place in the tree (Operation 6 through 10) |
| [Edit] | the caller wrote the comment, the comment stands shown, text valid | ok | the text replaced; the earlier wording stays in the comment's history (Operation 14) |
| [Edit] | the caller did not write the comment | [Not Author] | none (Operation 11) |
| [Edit] | the comment stands retracted | [Comment Retracted] | none (Operation 13) |
| [Retract] | the caller wrote the comment, the comment stands shown | ok | the comment stands retracted; nothing is removed (Operation 16, State 5) |
| [Retract] | the caller wrote the comment, the comment stands retracted | ok | none, no write (Operation 17) |
| [Retract] | the caller did not write the comment | [Not Author] | none (Operation 12) |
| a comment action | the comment id is not a string, or no comment carries it | [Unknown Comment] | none (Operation 4) |
| [Add] | target reference blank, over the string cap, or not a string | [Invalid Target Reference] | none (Operation 1, Operation 23) |
| a writing action | author reference blank, over the string cap, or not a string | [Invalid Author Reference] | none (Operation 2, Operation 24) |
| a wording action | text blank, over the text cap, or not a string | [Invalid Text] | none (Operation 3, Operation 25) |
| [List] | the item has comments | every comment, oldest first, each with the parent's comment id where the comment is a reply and a blank parent comment id where it is not, retracted ones with blank text | none (Operation 19, Operation 20, Operation 22, Operation 27, Operation 28) |
| [List] | the item has none, or the target reference is blank, over the string cap, or not a string | an empty list | none (Operation 21, Operation 26) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A comment never changes whose it is, where it sits or when it was added.**
  ```
  Invariant 1.1: The atom MUST NOT change a comment's comment id.
  Invariant 1.2: The atom MUST NOT change a comment's author reference.
  Invariant 1.3: The atom MUST NOT change a comment's target reference.
  Invariant 1.4: The atom MUST NOT change a reply's parent comment id.
  Invariant 1.5: The atom MUST NOT change a comment's added instant.
  ```
- **Invariant 2 — Two comments never share a comment id.**
  ```
  Invariant 2.1: Two comments MUST NOT share a comment id.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Forum

On a post, `p-7`, a member `bo` writes `add("p-7", "bo", "Try crimson clover.")`, answered `c-1`. Another member, `ana`, answers him: `reply("c-1", "ana", "Does it handle wet feet?")`, answered `c-2`, which sits under `c-1` on `p-7`. Bo fixes a word with `edit("c-1", "bo", "Try crimson clover first.")`. Later he takes it back: `retract("c-1", "bo")`. `list("p-7")` answers `c-1` with blank text and status retracted, and `c-2` under it, still readable, so Ana's question still has a place.

### Shop reviews

A shop lets buyers comment on a product, `sku-55`. A buyer adds a comment; the shop's own staff reply under it. A second buyer tries to edit the first buyer's comment and is answered [Not Author]; hiding a rude comment is the shop's moderation, not an edit.

### Rejection paths

- `add("", "bo", "Hi")` — rejected as [Invalid Target Reference]: the reference is blank.
- `add("p-7", "bo", "   ")` — rejected as [Invalid Text]: the text is blank.
- `reply("c-999", "bo", "Hi")` — rejected as [Unknown Comment]: no comment carries the comment id.
- `edit("c-1", "ana", "Hi")` — rejected as [Not Author]: Bo wrote the comment.
- `edit("c-1", "bo", "Hi")` once the comment is retracted — rejected as [Comment Retracted].
- `retract("c-1", "bo")` a second time — answers ok and writes nothing (Operation 17).

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the comments the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY comment carrying comment id, target reference, author reference, text, added instant AND status (State 1).
Check 1.2: An auditor MUST find EVERY comment standing in EXACTLY ONE OF shown, retracted (State 2).
Check 1.3: An auditor MUST find EVERY reply carrying the comment id of a comment the database holds (State 3).
Check 1.4: An auditor MUST find EVERY reply carrying the target reference of the reply's parent (State 4).
Check 1.5: An auditor MUST find an unfiltered read answering EVERY comment with a committed version (State 5; Execution Contract Generation acceptance 1).
Check 1.6: An auditor MUST find EVERY comment that stood in retracted in one version standing in retracted in EVERY later version (Operation 13, Operation 17).
Check 2.1: An auditor MUST find EVERY version of a comment carrying the author reference of the comment's first version (Invariant 1.2).
Check 2.2: An auditor MUST find EVERY version of a comment carrying the target reference of the comment's first version (Invariant 1.3).
Check 2.3: An auditor MUST find EVERY version of a reply carrying the parent comment id of the reply's first version (Invariant 1.4).
Check 2.4: An auditor MUST find EVERY version of a comment carrying the added instant of the comment's first version (Invariant 1.5).
Check 2.5: An auditor MUST find EVERY version of a comment carrying the comment id of the comment's first version (Invariant 1.1).
Check 3.1: An auditor MUST find no two comments sharing a comment id (Invariant 2.1).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a target reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 3).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT tell who may comment on an item.
Non-goal 2: The atom MUST NOT tell who may read an item's comments.
Non-goal 3: The atom MUST NOT check a target reference against a catalog.
Non-goal 4: The atom MUST NOT hide a comment for a moderator.
Non-goal 5: The atom MUST NOT hold a reaction.
Non-goal 6: The atom MUST NOT notify an item's author.
Non-goal 7: The atom MUST NOT draw a text.
Non-goal 8: The atom MUST NOT remove a comment's text from any version of the comment.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); Catalog *(forthcoming)* (Non-goal 3; External check 1); [Moderation](./moderation.md) (Non-goal 4); [Reaction](./reaction.md) (Non-goal 5); the composing pattern that tells the author, such as one built on [Notification](./notification.md) (Non-goal 6); the composing pattern that shows the comments, which draws each text as it likes (Non-goal 7); [Erasure Tombstone](./erasure-tombstone.md) (Non-goal 8).

Where the atom breaks down: a one-word answer from a short list, which is a reaction; a titled piece that stands on its own, which is a [post](./post.md).

## Edge cases

### Concurrency

Two [Reply] calls on one parent are serialized (Execution Contract Database 2), and each records its own reply. An [Edit] and a [Retract] on one comment are serialized the same way: an [Edit] that meets a retracted comment answers [Comment Retracted], and a [Retract] that meets an edited comment retracts the edited wording, which stays in the comment's history.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Retract] where the first landed changes nothing a reader sees and answers ok; a repeated [Edit] writes its text again, which changes nothing only where no other [Edit] came between the two. A repeated [Add] or [Reply] records a second comment, so a caller whose answer was lost asks [List] before adding again.

### What undoes a write

An [Edit] is undone by an [Edit] carrying the earlier wording, which the comment's history holds. A [Retract] is not undone by this atom: a comment taken back stays taken back, and the author adds a new one (Execution Contract Undo 4).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the author reference of the caller the composing pattern authenticated.
```

NOTE: composing patterns — none yet. Forthcoming: Forum.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a comment; a reply; a writing action; a recording action; a wording action; a comment action; an auditor.

Term records: comment — one person's words on one item, carrying comment id, target reference, author reference, text, added instant, status and, for a reply, the parent's comment id.

Term record verbs: identify, assign, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, replace, change, write, share, find, read, tell, check, hide, hold, notify, draw, own, differ.

Term value sets: writing action, recording action, wording action and comment action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — shown | retracted; action rejection — invalid-target-reference | invalid-author-reference | invalid-text | unknown-comment | not-author | comment-retracted | storage-failure.

Term bounds: string cap (the bound on a target reference's length and on an author reference's length in Unicode code points, 1,024 where a deployment declares none); text cap (the bound on a text's length in Unicode code points, 10,000 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from the Massachusetts Institute of Technology's sync-engine Commenting concept.

Term terms: comment, comments, reply, replies, parent, comment id, target reference, author reference, text, string cap, text cap, seam, added instant, status, shown, retracted, writing action, recording action, wording action, comment action, version.

#### Add

Records a new [Comment] on an item for an author, with a [Text], [Shown], stamping its [Added Instant]. Answers the comment's [Comment Id].

Kind: Operation

#### Reply

Records a new comment under a [Parent], on the parent's item, for an author, with a [Text], [Shown], stamping its [Added Instant]. Answers the new comment's [Comment Id].

Kind: Operation

#### Edit

Replaces a shown comment's text, for the comment's author only; the earlier wording stays in the comment's history. Answers ok.

Kind: Operation

#### Retract

Stands a comment in [Retracted], for the comment's author only, and removes nothing. A comment already retracted is left as it is. Answers ok.

Kind: Operation

#### List

Answers every comment on one item, oldest first, each with its parent's comment id where the comment is a reply and a blank parent comment id where it is not, and a [Retracted] comment with blank text; changes nothing.

Kind: Operation

#### Comment

One person's words on one item: recorded by [Add] or [Reply], changed by [Edit], stood in [Retracted] by [Retract]; never removed by the atom.

Kind: Type

#### Parent

The comment id of the comment a reply answers; a comment that is not a reply has none, and [List] answers it blank (Operation 28). Set once, never changed.

Kind:       Field
Field of:   Comment
Projection: parent_comment_id

#### Comment Id

The string the atom assigns a comment when the comment is added, carried by no other comment; never changed.

Kind:       Field
Field of:   Comment
Projection: comment_id

#### Target Reference

Names the item a comment is on, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; whether it names a real item is a catalog's question.

Kind:       Field
Field of:   Comment
Projection: target_reference

#### Author Reference

Names the person who wrote the comment, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; set once, never changed.

Kind:       Field
Field of:   Comment
Projection: author_reference

#### Text

The comment's words as the author wrote them; replaced by [Edit]. How they are drawn is the page's.

Kind:       Field
Field of:   Comment
Projection: text

#### Added Instant

The instant of the [Add] or [Reply] call that recorded the comment, stamped from the injected now; never changed.

Kind:       Field
Field of:   Comment
Projection: added_instant

#### Status

Where a comment stands: [Shown] or [Retracted].

Kind:       Field
Field of:   Comment
Projection: status

#### Shown

The status of a comment whose words [List] answers.

Kind:       Member
Member of:  the status
Projection: shown

#### Retracted

The status of a comment the author took back; [List] answers it with blank text, in its place in the tree.

Kind:       Member
Member of:  the status
Projection: retracted

#### Invalid Target Reference

The refusal of a blank [Target Reference], one over the string cap, or one that is not a string, on [Add] (Operation 1, Operation 23).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-target-reference

#### Invalid Author Reference

The refusal of a blank [Author Reference], one over the string cap, or one that is not a string, on any writing call (Operation 2, Operation 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-author-reference

#### Invalid Text

The refusal of a blank [Text], one over the text cap, or one that is not a string, on [Add], [Reply] or [Edit] (Operation 3, Operation 25).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-text

#### Unknown Comment

The refusal of a [Comment Id] that is not a string or that no comment carries, on [Reply], [Edit] or [Retract] (Operation 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-comment

#### Not Author

The refusal of an [Edit] or a [Retract] whose author reference is not the comment's (Operation 11, Operation 12).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-author

#### Comment Retracted

The refusal of an [Edit] on a [Retracted] comment (Operation 13).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: comment-retracted

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Add]: #add
[Reply]: #reply
[Edit]: #edit
[Retract]: #retract
[List]: #list
[Comment]: #comment
[Parent]: #parent
[Comment Id]: #comment-id
[Target Reference]: #target-reference
[Author Reference]: #author-reference
[Text]: #text
[Added Instant]: #added-instant
[Status]: #status
[Shown]: #shown
[Retracted]: #retracted
[Invalid Target Reference]: #invalid-target-reference
[Invalid Author Reference]: #invalid-author-reference
[Invalid Text]: #invalid-text
[Unknown Comment]: #unknown-comment
[Not Author]: #not-author
[Comment Retracted]: #comment-retracted
[Storage Failure]: #storage-failure

---

## Standards references

Comment is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.
- **The Massachusetts Institute of Technology's sync-engine, Commenting concept** (github.com/mit-sdg/sync-engine) — the taken-in source: authored comments on an outside target, retracted only by the author. This atom differs by adding replies and keeping a retracted comment in place.

---

## Status

`doing` — see the Ledger.

## Ledger

```
status: doing
formal: pending — no model yet
last gate: 2026-11-19 — Final Critique 2, a delta round, one counted reader (Linus claude-sonnet-5-5; the first pass read the round's freeze record and lapsed, its report triaged and not counted, and the seat ran the pass again on the same text), frozen at e3af1687 — foundational count 0 after the blind second triage, clean, one sample; the two reports claimed no foundational and the blind second triage placed none (refuted: Operation 19 fixes the tie of the list's order, Operation 20 and Operation 16 the retracted text Non-goal 8 keeps in every version, Logic confinement 16 the comment id a call carries onward, Term comment action the actions Operation 4 names, and Term blank the spellings of a blank); the settle's own refining cure: Operation 27 carried two obligations joined by AND, so Operation 27 answers the parent's comment id for every reply and Operation 28 the blank parent comment id for every comment that is not a reply (GRACE-lang Rule shape 3); the round read the reach of Final Critique 1's cures (7 labels) by their diff, and the blind second triage's press found no foundational; 2026-11-18 — Final Critique 1, frozen at b0af523c — foundational count 2, cured by the settle, not clean, no sample

open: none
```

## Decisions

- **2026-11-18 — Taken in from MIT's Commenting concept, drafted through the Grace connector mirroring Reaction.** *Chose:* a reply tree on one item, edit and retract by the author only, a retracted comment kept in place with no words. *Over:* MIT's flat list where a retracted comment is deleted. *Because:* a forum's replies must not be orphaned, and Execution Contract Database 5 keeps every wording.

NOTE: End of Comment.

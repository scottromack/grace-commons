---
title: Post
id: 69
audience: common
---

# Post

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Post lets a person write a piece with a title and a body in markdown, keep it as a draft, change it, publish it for readers and take it back down. Every post has one author for good, and every earlier wording stays readable, because the database keeps each version of the record: a post's revisions are its history, not a second list. Readers see the published posts, oldest published first, and a writer sees their own posts, drafts included. Who may read, write, change or publish a post, where a post is filed, the comments and reactions on it, removing it, and drawing the markdown on a page each belong to another pattern, which is why one post serves a forum, a blog and a news page alike.

<details markdown="block">
<summary>WHY</summary>

A forum, a blog and a newsroom all start from the same thing: someone writes something, gets it right, then lets others read it. This atom is that and nothing more. Three decisions carry the weight. A post is a draft or published, and the two moves between them are separate requests, each answered ok again when its work is already done. Changing a post replaces its title and body and leaves the earlier wording in the database's history, so an edit never loses what was said and no revision list is kept by hand. And the author is set once and never changes, so the record always says whose words these are. The body is markdown, kept exactly as written; how it is drawn is the page's. Who may read, write or publish, where a post is filed, and how a post is removed are other patterns' questions, and declining them is what lets one post serve every place people publish. Taken in from the Massachusetts Institute of Technology's sync-engine Posting concept (Daniel Jackson's group), which keeps an unchanging message; a forum's posts are drafted and corrected, so this one is changeable with its history kept.

</details>

## What it keeps

### The record

Term post: one titled piece of writing by one author, a draft or published — a [Post].

#### Post

One titled piece of writing by one author: recorded by [Write], changed by [Edit], moved between [Draft] and [Published] by [Publish] and [Unpublish]; never removed by the atom.

Kind: Type

```
Identity 1: The atom MUST identify a post by the post's post id.
```

Term post id: the string the atom assigns a post when the post is written — a [Post Id].

#### Post Id

The string the atom assigns a post when the post is written, carried by no other post; never changed.

Kind:       Field
Field of:   Post
Projection: post_id

```
Identity 2: The atom MUST assign EVERY post a post id no other post carries.
```

Term author reference: the string naming the person who wrote a post, in the deployment's own scheme — an [Author Reference]; the atom reads no scheme in it.

#### Author Reference

Names the person who wrote the post, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; set once, never changed.

Kind:       Field
Field of:   Post
Projection: author_reference

```
Identity 3: The atom MUST NOT normalize an author reference.
Identity 4: The atom MUST compare two author references code point for code point.
```

Term title: the post's heading as the author wrote it — a [Title].

#### Title

The post's heading as the author wrote it; replaced by [Edit].

Kind:       Field
Field of:   Post
Projection: title

Term body: the post's text in markdown, kept exactly as written — a [Body].

#### Body

The post's text in markdown, kept exactly as written; replaced by [Edit]. How it is drawn is the page's.

Kind:       Field
Field of:   Post
Projection: body

Term written instant: the instant of the [Write] call that recorded the post — the [Written Instant]; set once, never changed.

#### Written Instant

The instant of the [Write] call that recorded the post, stamped from the injected now; never changed.

Kind:       Field
Field of:   Post
Projection: written_instant

Term published instant: the instant of the latest [Publish] call that stood the post in published — the [Published Instant]; blank where no [Publish] call has stood the post in published.

#### Published Instant

The instant of the latest [Publish] that stood the post in published, stamped from the injected now; blank where no [Publish] has. [Edit] and [Unpublish] leave it as it was (Operation 29, Operation 30).

Kind:       Field
Field of:   Post
Projection: published_instant

Term status: where a post stands, draft or published — the [Status].

#### Status

Where a post stands: [Draft] or [Published].

Kind:       Field
Field of:   Post
Projection: status

Term draft: the status of a post [List Published] does not show — [Draft].

#### Draft

The status of a post [List Published] does not show; [List By Author] shows it in the author's own list, and [Look Up] answers it to any call.

Kind:       Member
Member of:  the status
Projection: draft

Term published: the status of a post readers see — [Published].

#### Published

The status of a post readers see in [List Published].

Kind:       Member
Member of:  the status
Projection: published

```
State 1: EVERY post MUST carry post id, author reference, title, body, written instant and status.
State 2: EVERY post MUST stand in EXACTLY ONE OF draft, published.
State 3: EVERY published post MUST carry a published instant.
State 4: The atom MUST NOT remove a post.
```

## What people do

### Every action

Term text action: [Write] | [Edit] — the actions that set a title and a body.

Term post action: [Edit] | [Publish] | [Unpublish] — the actions that change the post a post id names.

Term reading action: [Look Up] | [List Published] | [List By Author] — the actions that change nothing.

```
Operation 2: IF the title EQUALS blank OR the title EXCEEDS the string cap THEN a text action MUST answer invalid-title.
Operation 3: IF the body EQUALS blank OR the body EXCEEDS the body cap THEN a text action MUST answer invalid-body.
Operation 4: IF the post id is malformed OR no post carries the post id THEN a post action MUST answer unknown-post (Execution Contract Input 3).
Operation 23: A reading action MUST NOT write.
Operation 25: IF the title is malformed THEN a text action MUST answer invalid-title (Execution Contract Input 1).
Operation 26: IF the body is malformed THEN a text action MUST answer invalid-body (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| a post action | the post id is not a string, or no post carries it | [Unknown Post] | none (Operation 4) |
| a text action | title blank, over the string cap, or not a string | [Invalid Title] | none (Operation 2, Operation 25) |
| a text action | body blank, over the body cap, or not a string | [Invalid Body] | none (Operation 3, Operation 26) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Invalid Title

The refusal of a blank [Title], one over the string cap, or one that is not a string, on [Write] or [Edit] (Operation 2, Operation 25).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-title

#### Invalid Body

The refusal of a blank [Body], one over the body cap, or one that is not a string, on [Write] or [Edit] (Operation 3, Operation 26).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-body

#### Unknown Post

The refusal of a [Post Id] that is not a string or that no post carries, on [Edit], [Publish] or [Unpublish] (Operation 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: unknown-post

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Write

Records a new [Post] in [Draft] for an author, with a [Title] and a [Body], stamping its [Written Instant]. Answers the post's [Post Id].

Kind: Operation

```
write(author_reference, title, body)
  answers post_id
  refuses invalid-author-reference | invalid-title | invalid-body | storage-failure
```

```
Operation 1: IF the author reference EQUALS blank OR the author reference EXCEEDS the string cap THEN [Write] MUST answer invalid-author-reference.
Operation 5: [Write] MUST record EXACTLY ONE post carrying the author reference, the title and the body of the call.
Operation 6: [Write] MUST stamp written instant from the injected now.
Operation 7: [Write] MUST stand the post in draft.
Operation 8: [Write] MUST answer the post id.
Operation 24: IF the author reference is malformed THEN [Write] MUST answer invalid-author-reference (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [Write] | author reference, title and body valid, database accepts | the post id | one post lands, a draft, its written instant now (Operation 5 through 8) |
| [Write] | author reference blank, over the string cap, or not a string | [Invalid Author Reference] | none (Operation 1, Operation 24) |

#### Invalid Author Reference

The refusal of a blank [Author Reference], one over the string cap, or one that is not a string, on [Write] (Operation 1, Operation 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-author-reference

- `write("", "Hello", "Hi")` — rejected as [Invalid Author Reference]: the reference is blank.
- `write("ana", "", "Hi")` — rejected as [Invalid Title]: the title is blank.
- `write("ana", "Hello", "   ")` — rejected as [Invalid Body]: the body is blank.
- `write("", "", "")` — rejected as [Invalid Author Reference]: three refusals apply, and the one listed first on [Write]'s refuses line answers (Execution Contract Refusal 1).

### Edit

Replaces a post's title and body; the earlier wording stays in the post's history. The status and the [Published Instant] are left as they are. Answers ok.

Kind: Operation

```
edit(post_id, title, body)
  answers ok
  refuses unknown-post | invalid-title | invalid-body | storage-failure
```

```
Operation 9: [Edit] MUST replace the post's title AND body with the title AND body of the call.
Operation 10: [Edit] MUST NOT change the post's status.
Operation 11: [Edit] MUST answer ok.
Operation 29: [Edit] MUST NOT change the post's published instant.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [Edit] | the post exists, title and body valid | ok | title and body replaced; the status, post id, author reference, written instant and published instant stand; the earlier wording stays in the post's history (Operation 9, Operation 10, Operation 29, Invariant 1.1 through 1.3) |

- `edit("p-999", "Hello", "Hi")` — rejected as [Unknown Post]: no post carries the post id.

### Publish

Stands a [Draft] post in [Published] and stamps its [Published Instant]. A post already published is left as it is. Answers ok.

Kind: Operation

```
publish(post_id)
  answers ok
  refuses unknown-post | storage-failure
```

```
Operation 12: IF the post's status EQUALS draft THEN [Publish] MUST stand the post in published.
Operation 13: IF the post's status EQUALS draft THEN [Publish] MUST stamp published instant from the injected now.
Operation 14: IF the post's status EQUALS published THEN [Publish] MUST NOT write.
Operation 15: [Publish] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [Publish] | the post stands draft | ok | the post stands published, its published instant now (Operation 12, Operation 13) |
| [Publish] | the post stands published | ok | none, no write (Operation 14) |

### Unpublish

Stands a [Published] post back in [Draft], leaving its [Published Instant] as it was. A draft is left as it is. Answers ok.

Kind: Operation

```
unpublish(post_id)
  answers ok
  refuses unknown-post | storage-failure
```

```
Operation 16: IF the post's status EQUALS published THEN [Unpublish] MUST stand the post in draft.
Operation 17: IF the post's status EQUALS draft THEN [Unpublish] MUST NOT write.
Operation 18: [Unpublish] MUST answer ok.
Operation 30: [Unpublish] MUST NOT change the post's published instant.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [Unpublish] | the post stands published | ok | the post stands draft, its published instant as it was (Operation 16, Operation 30) |
| [Unpublish] | the post stands draft | ok | none, no write (Operation 17) |

### Look Up

Answers the post a [Post Id] names, with a blank [Published Instant] where no [Publish] call has stood it in published, and changes nothing; an empty list where no post carries it.

Kind: Operation

```
look_up(post_id)
  answers posts(author_reference, title, body, status, published_instant)
```

```
Operation 19: [Look Up] MUST answer the post carrying the post id.
Operation 20: [Look Up] MUST answer an empty list for a post id no post carries.
Operation 28: IF the post id is malformed THEN [Look Up] MUST answer an empty list (Execution Contract Query 5).
Operation 31: [Look Up] MUST answer a blank published instant for a post no [Publish] call has stood in published.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [Look Up] | the post exists | the post, its published instant blank where no [Publish] call has stood it in published | none (Operation 19, Operation 23, Operation 31) |
| [Look Up] | no post carries the post id, or the post id is not a string | an empty list | none (Operation 20, Operation 28) |

- `look_up("p-999")` — answers an empty list: no post carries the post id (Operation 20).

### List Published

Answers every published post, oldest published first, and changes nothing.

Kind: Operation

```
list_published()
  answers posts(post_id, author_reference, title, published_instant)
```

```
Operation 21: [List Published] MUST answer EVERY published post, in published instant order, earliest first, then in code point order of post id (Execution Contract Logic confinement 10).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [List Published] | any | every published post, oldest published first | none (Operation 21, Operation 23) |

### List By Author

Answers every post one [Author Reference] wrote, drafts included, oldest written first, and changes nothing.

Kind: Operation

```
list_by_author(author_reference)
  answers posts(post_id, title, status)
```

```
Operation 22: [List By Author] MUST answer EVERY post carrying the author reference, in written instant order, earliest first, then in code point order of post id (Execution Contract Logic confinement 10).
Operation 27: IF the author reference is malformed OR the author reference EQUALS blank OR the author reference EXCEEDS the string cap THEN [List By Author] MUST answer an empty list (Execution Contract Query 5).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the posts |
|---|---|---|---|
| [List By Author] | the author reference is valid | every post by the author, drafts included, oldest written first | none (Operation 22, Operation 23) |
| [List By Author] | the author reference is blank, over the string cap, or not a string | an empty list | none (Operation 27, Operation 23) |

## What is and what should never be (Invariants)

- **Invariant 2 — Two posts never share a post id.**
  ```
  Invariant 2.1: Two posts MUST NOT share a post id.
  ```

- **Invariant 1 — A post never changes its post id, whose it is or when it was written.**
  ```
  Invariant 1.1: The atom MUST NOT change a post's post id.
  Invariant 1.2: The atom MUST NOT change a post's author reference.
  Invariant 1.3: The atom MUST NOT change a post's written instant.
  ```

## When something happens

### Concurrency

Two [Edit] calls on one post are serialized (Execution Contract Database 2): the later replaces what the earlier wrote, and both wordings stay in the post's history. A [Publish] and an [Unpublish] on one post are serialized the same way, and the post stands as the later left it.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Publish] or [Unpublish] where the first landed writes nothing and answers ok, unless a call of the other kind came between; a repeated [Edit] writes its text again, which changes nothing only where no other [Edit] came between the two. A repeated [Write] records a second post, so a caller whose [Write] answer was lost asks [List By Author] and then [Look Up] on each post carrying the title, before writing again.

### What undoes a write

[Unpublish] undoes [Publish] and [Publish] undoes [Unpublish]; an [Edit] is undone by an [Edit] carrying the earlier wording, which the author keeps or an auditor reads from the post's history (Execution Contract Database 5). A [Write] is undone by removing the post from view, which [Restorable Delete](./restorable-delete.md) owns (Execution Contract Undo 4).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MAY declare the body cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 5: The deployment MUST NOT normalize an author reference at the seam.
Capability requirement 6: The deployment MUST supply EVERY post id PER Execution Contract Logic confinement 16.
```

Term string cap: the bound on an author reference's length and on a title's length in Unicode code points; 1,024 code points where a deployment declares none.

Term body cap: the bound on a body's length in Unicode code points; 100,000 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

NOTE: Capability requirement 5 is the atom's own rule for the canonical form of an author reference, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so an author reference is recorded as the call carries it (Execution Contract Input 4; Identity 3 and 4).

## Left to others

```
Non-goal 1: The atom MUST NOT tell who may write a post.
Non-goal 2: The atom MUST NOT tell who may change a post.
Non-goal 3: The atom MUST NOT file a post.
Non-goal 4: The atom MUST NOT hold a comment.
Non-goal 5: The atom MUST NOT hold a reaction.
Non-goal 6: A deployment needing a post removed MUST compose Restorable Delete.
Non-goal 7: The atom MUST NOT publish a post at a set time.
Non-goal 8: The atom MUST NOT give a post a web address.
Non-goal 9: The atom MUST NOT draw a body.
Non-goal 10: The atom MUST NOT find a post by a word in a body.
Non-goal 11: The atom MUST NOT tell who may publish a post.
Non-goal 12: The atom MUST NOT tell who may read a post.
Non-goal 13: The atom MUST NOT offer a moderator's hiding of a post.
Non-goal 14: A deployment needing a moderator to hide a post MUST compose Moderation.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2, 11, 12); [Category](./category.md) (Non-goal 3); [Comment](./comment.md) (Non-goal 4); [Reaction](./reaction.md) (Non-goal 5); [Restorable Delete](./restorable-delete.md) (Non-goal 6); Scheduled Publish *(forthcoming)* (Non-goal 7); Post Address *(forthcoming)* (Non-goal 8); the composing pattern that shows the post, which draws the markdown as it likes (Non-goal 9); Search *(forthcoming)* (Non-goal 10); [Moderation](./moderation.md) (Non-goal 13, Non-goal 14); a moderator's hiding is Moderation's act and not [Unpublish], whose caller the composing pattern that knows the caller admits (Non-goal 2, Non-goal 11).

Where the atom breaks down: an answer in a person's own words to someone else's post, which is a [comment](./comment.md); a message to one person, which is a communication.

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the author reference of the caller the composing pattern authenticated.
```

NOTE: composing patterns — none yet. Forthcoming: Forum.

## Example

The same pattern in two domains; each action's rejection paths stand in its branch.

### Forum

A member, `ana`, starts a topic: `write("ana", "Best cover crop for clay?", "We have heavy clay...")` answers `p-7`, a draft. She fixes a typo with `edit("p-7", "Best cover crop for clay?", "We have heavy clay soil...")`, then `publish("p-7")` answers ok, and `list_published()` now answers `p-7` with her name and the instant she published. A reader who opens the post later sees the corrected wording; an auditor reading the post's history sees both.

### Blog

A writer keeps three drafts going. `list_by_author("sam")` answers all three with status draft; readers' `list_published()` answers none of them. The writer publishes one, then spots an error and unpublishes it; the post stands draft again, out of readers' list, and publishing it again puts it back with a new published instant. A second publish request on the same post, sent by a double click, answers ok and changes nothing.

## Source

Post is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.
- **The Massachusetts Institute of Technology's sync-engine, Posting concept** (github.com/mit-sdg/sync-engine) — the taken-in source: an authored message listed in time order. This atom differs by letting a post be changed and unpublished, with the database's history keeping every wording.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the posts the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Database 8, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY post carrying post id, author reference, title, body, written instant AND status (State 1).
Check 1.2: An auditor MUST find EVERY post standing in EXACTLY ONE OF draft, published (State 2).
Check 1.3: An auditor MUST find EVERY published post carrying a published instant (State 3).
Check 2.1: An auditor MUST find EVERY version of a post carrying the post id of the post's first version (Invariant 1.1).
Check 2.2: An auditor MUST find EVERY version of a post carrying the author reference of the post's first version (Invariant 1.2).
Check 2.3: An auditor MUST find EVERY version of a post carrying the written instant of the post's first version (Invariant 1.3).
Check 3.1: An auditor MUST find no two posts sharing a post id (Invariant 2.1).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a post; a text action; a post action; a reading action; an auditor.

Term records: post — one titled piece of writing by one author, carrying post id, author reference, title, body, written instant, status and, once published, published instant.

Term record verbs: identify, assign, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, replace, change, write, share, find, read, tell, publish, file, hold, give, draw, own, offer, hide, compose.

Term value sets: text action, post action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — draft | published; action rejection — invalid-author-reference | invalid-title | invalid-body | unknown-post | storage-failure.

Term bounds: string cap (the bound on an author reference's length and on a title's length in Unicode code points, 1,024 where a deployment declares none); body cap (the bound on a body's length in Unicode code points, 100,000 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from the Massachusetts Institute of Technology's sync-engine Posting concept.

Term terms: post, posts, post id, author reference, title, body, string cap, body cap, seam, written instant, published instant, status, draft, published, text action, post action, reading action, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Write]: #write
[Edit]: #edit
[Publish]: #publish
[Unpublish]: #unpublish
[Look Up]: #look-up
[List Published]: #list-published
[List By Author]: #list-by-author
[Post]: #post
[Post Id]: #post-id
[Author Reference]: #author-reference
[Title]: #title
[Body]: #body
[Written Instant]: #written-instant
[Published Instant]: #published-instant
[Status]: #status
[Draft]: #draft
[Published]: #published
[Invalid Author Reference]: #invalid-author-reference
[Invalid Title]: #invalid-title
[Invalid Body]: #invalid-body
[Unknown Post]: #unknown-post
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-23` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-23
formal: pending — no model yet
last gate: 2026-11-23 — Final Critique 4, a delta round, one reader (Linus opencode-go/minimax-m3), frozen at ccae326b — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed none, held three questions (whether a post state breaks State 1 through 3 or the Invariants, whether two rules oblige two answers on one call, whether a lost answer, a failed read or write or two callers leave a state no rule covers) and made nine refining and two rhetorical reports, which the blind triage placed refining A for the Term post action gloss, the Edit case row's post id and the List By Author case row, refining C for the string order's citation of Execution Contract Logic confinement 10, the Generation acceptance paragraph's citation of Execution Contract Database 8 and State 4 repeating Non-goal 6, refining B for the post id's missing cap, refuted for Order 1 and for the Look Up row's Operation 19, and rhetorical for Term published and Term published instant; cured: those wordings and citations, Non-goal 6 now names Restorable Delete as the pattern a deployment needing a removal composes, the stray sentence after the Storage Failure entry is cut, and the post id's cap is decided by Execution Contract Input 2, which owes no restatement of an allocated id's bounds; 2026-11-20 — Final Critique 3, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at 369b7bb0 — foundational count 0 after the blind second triage, clean, one sample; Linus's report claimed none and held three questions (whether Non-goal 13 and Non-goal 14 conflict, whether a moderator's hiding overlaps Unpublish, whether a deployment that composes no Moderation leaves a state no rule covers); 2026-11-19 — Final Critique 2, a delta round, one reader (Linus opencode/beam-free), frozen at 4b9a398b — foundational count 0 after the blind second triage, clean, one sample; Linus's three foundational claims placed none foundational by both triages: the refusal that answers for a call with two invalid inputs is the one listed first on the action's refuses line (Execution Contract Refusal 1, the page's signature blocks), a second Publish on a published post writes nothing (Operation 14) so it stood the post in published no further, and Capability requirement 5 is the atom's own rule for the canonical form of an author reference that Logic confinement 13's last sentence lets stand in place of it, which the page now says in a NOTE as Comment and Reaction do; both refining items refuted (Operation 23 stands on the page, and Restorable Delete owns Non-goal 6 by composing); 2026-11-19 — Final Critique 1, frozen at 4787905a — foundational count 3, cured by the settle, not clean, no sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

- **2026-11-18 — Taken in from MIT's Posting concept, drafted through the Grace connector mirroring Reaction.** *Chose:* a changeable post, draft or published, its revisions read from the database's history. *Over:* MIT's unchanging message, and a revision list kept by hand. *Because:* a forum post is drafted and corrected, and Execution Contract Database 5 already keeps every version. A post's web address is left to Post Address *(forthcoming)*, so the atom stays as simple as possible without losing fidelity.

</details>

NOTE: End of Post.

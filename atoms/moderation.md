---
title: Moderation
id: 75
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Moderation

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Moderation lets people flag an item that needs a moderator's eye — a post, a comment, a review — and lets a moderator act on it: hide it or show it again, lock its replies or open them, pin it to the top or unpin it, or dismiss the flags. Hiding an item clears its pending flags on its own, so no moderator is left cleaning up a queue for something already dealt with, and a hidden item takes no new flag. A person has one pending flag on an item at a time; flagging again changes nothing. Each item keeps which moderator last changed how it stands, and when. Who counts as a moderator, removing an item for good, the reasons a business offers for a flag, and telling the author each belong to another pattern, which is why one moderation serves a forum, a shop's reviews and a chat alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Every place people post needs a way to say "look at this" and a way to answer it. This atom is that and nothing more. Three decisions carry the weight. Moderation changes an item's standing, never the item: hiding keeps the item and its history, so a wrong hide is undone by showing it again, and removing for good is Restorable Delete's. A moderator's move clears the work it settles: hiding an item clears the item's open flags in the same commit, because making a person clear a queue by hand for something already handled is pure make-work (Scott, 2026-11-18: "We are here to reduce work"). And the three settings — shown or hidden, open or locked, pinned or not — are independent, so a pinned announcement can be locked and a hidden post stays locked when shown again. Who may moderate is a role's question, asked by the composing pattern. Scott's forum sketch named Moderation among the seven a forum cannot open without: "flag, hide, lock, pin."

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a standing by the standing's item reference.
Identity 2: The atom MUST identify a report by the report's item reference AND reporter reference AND flagged instant.
Identity 3: The atom MUST NOT normalize an item reference.
Identity 4: The atom MUST compare two item references codepoint for codepoint.
Identity 5: The atom MUST NOT normalize a person reference.
Identity 6: The atom MUST compare two person references codepoint for codepoint.
```

Term standing: where one item stands with the moderators — shown or hidden, open or locked, pinned or unpinned — a [Standing].

Term report: one person's flag on one item, pending or cleared — a [Report].

Term item reference: the string naming an item, such as a post or a comment, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it.

Term item: what a person flags and a moderator moves, such as a post, a comment or a review, named by an item reference.

Term person reference: the string naming a person, in the deployment's own scheme; the atom reads no scheme in it.

Term reporter reference: the person reference of the person who flagged an item — a [Reporter Reference].

Term moderator reference: the person reference of the moderator who made a move — a [Moderator Reference].

Term reason: the words a person gives for a flag — a [Reason].

Term string cap: the bound on an item reference's length and on a person reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term reason cap: the bound on a reason's length in Unicode code points; 1,000 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

### State

```
State 1: EVERY standing MUST carry item reference, visibility, replies, placement, moderator reference and moderated instant.
State 2: EVERY standing MUST stand in EXACTLY ONE OF shown, hidden for visibility.
State 3: EVERY standing MUST stand in EXACTLY ONE OF open, locked for replies.
State 4: EVERY standing MUST stand in EXACTLY ONE OF unpinned, pinned for placement.
State 5: EVERY report MUST carry item reference, reporter reference, reason, flagged instant and status.
State 6: EVERY report MUST stand in EXACTLY ONE OF pending, cleared.
State 7: The atom MUST NOT remove a standing.
State 8: The atom MUST NOT remove a report.
```

Term visibility: whether readers see the item, shown or hidden — the [Visibility].

Term replies: whether the item takes new replies, open or locked — the [Replies].

Term placement: whether the item sits at the top of its list, unpinned or pinned — the [Placement].

Term moderated instant: the instant of the latest [Moderate] call that changed the standing — the [Moderated Instant].

Term flagged instant: the instant of the [Flag] call that recorded the report — the [Flagged Instant].

Term status: where a report stands, pending or cleared — the [Status].

Term untouched: an item no standing carries, which stands shown, open and unpinned.

Term stands shown, stands hidden: an item stands shown where it is untouched or its standing stands shown for visibility, and stands hidden where its standing stands hidden for visibility.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11 AND Execution Contract Logic confinement 7.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MAY declare the reason cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 6: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 7: The deployment MUST NOT supply one now to two calls of [Flag] carrying one item reference AND one reporter reference.
```

### Operations

```
flag(item_reference, reporter_reference, reason)
  answers ok
  refuses invalid-item-reference | invalid-person-reference | invalid-reason | storage-failure

moderate(item_reference, moderator_reference, move)
  answers ok
  refuses invalid-item-reference | invalid-person-reference | invalid-move | storage-failure

dismiss(item_reference, moderator_reference)
  answers ok
  refuses invalid-item-reference | invalid-person-reference | storage-failure

look_up(item_reference)
  answers standings(visibility, replies, placement)

list_flagged()
  answers items(item_reference, pending_count, flagged_instant)
```

```
Operation 1: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a writing action MUST answer invalid-item-reference.
Operation 2: IF the person reference of the call EQUALS blank OR the person reference of the call EXCEEDS the string cap THEN a writing action MUST answer invalid-person-reference.
Operation 3: IF the reason EQUALS blank OR the reason EXCEEDS the reason cap THEN [Flag] MUST answer invalid-reason.
Operation 4: IF the move IS NOT IN hide, show, lock, unlock, pin, unpin THEN [Moderate] MUST answer invalid-move.
Operation 5: IF no pending report EXISTS for the item reference AND the reporter reference AND the item stands shown THEN [Flag] MUST record EXACTLY ONE report carrying the item reference, the reporter reference AND the reason of the call.
Operation 6: IF no pending report EXISTS for the item reference AND the reporter reference AND the item stands shown THEN [Flag] MUST stamp flagged instant from the injected now AND stand the report in pending.
Operation 7: IF a pending report EXISTS for the item reference AND the reporter reference THEN [Flag] MUST NOT write.
Operation 8: IF the item is untouched AND the move IS IN hide, lock, pin THEN [Moderate] MUST record EXACTLY ONE standing for the item reference, shown, open AND unpinned, ahead of the move.
Operation 9: IF the move EQUALS hide THEN [Moderate] MUST stand the visibility in hidden.
Operation 10: IF the move EQUALS show THEN [Moderate] MUST stand the visibility in shown.
Operation 11: IF the move EQUALS lock THEN [Moderate] MUST stand the replies in locked.
Operation 12: IF the move EQUALS unlock THEN [Moderate] MUST stand the replies in open.
Operation 13: IF the move EQUALS pin THEN [Moderate] MUST stand the placement in pinned.
Operation 14: IF the move EQUALS unpin THEN [Moderate] MUST stand the placement in unpinned.
Operation 15: IF the move changes the standing THEN [Moderate] MUST stamp the moderator reference of the call AND moderated instant from the injected now.
Operation 16: IF the move leaves the standing as the standing was THEN [Moderate] MUST NOT write.
Operation 17: IF the move EQUALS hide THEN [Moderate] MUST stand EVERY pending report carrying the item reference in cleared, in the same commit.
Operation 18: [Dismiss] MUST stand EVERY pending report carrying the item reference in cleared.
Operation 19: IF no pending report carries the item reference THEN [Dismiss] MUST NOT write.
Operation 20: A writing action MUST answer ok.
Operation 21: [Look Up] MUST answer the visibility, replies AND placement of the item reference's standing.
Operation 22: [Look Up] MUST answer shown, open AND unpinned for an item no standing carries.
Operation 23: [List Flagged] MUST answer EVERY item reference a pending report carries, with the count of pending reports AND the earliest flagged instant among the pending reports, in earliest flagged instant order, then in codepoint order of item reference.
Operation 24: A reading action MUST NOT write.
Operation 25: IF the item reference is malformed THEN a writing action MUST answer invalid-item-reference (Execution Contract Input 1).
Operation 26: IF the person reference of the call is malformed THEN a writing action MUST answer invalid-person-reference (Execution Contract Input 1).
Operation 27: IF the reason is malformed THEN [Flag] MUST answer invalid-reason (Execution Contract Input 1).
Operation 28: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Look Up] MUST answer shown, open AND unpinned (Execution Contract Query 5).
Operation 29: IF the item stands hidden THEN [Flag] MUST NOT write.
```

Term writing action: [Flag] | [Moderate] | [Dismiss] — the actions that change a standing or a report.

Term reading action: [Look Up] | [List Flagged] — the actions that change nothing.

Term move: what [Moderate] asks for — a [Move].

Term person reference of the call: the reporter reference on [Flag], the moderator reference on [Moderate] and [Dismiss].

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Flag] | references and reason valid, the item stands shown, the person has no pending report on the item | ok | one report lands, pending (Operation 5, Operation 6) |
| [Flag] | the person already has a pending report on the item | ok | none, no write (Operation 7) |
| [Flag] | references and reason valid, the item stands hidden | ok | none, no write (Operation 29) |
| [Moderate] | the move changes the standing | ok | the setting changed, the moderator and now stamped; a standing recorded first where the item had none (Operation 8 through 15) |
| [Moderate] | the move leaves the standing as it was | ok | none, no write (Operation 16) |
| [Moderate] | the move is hide | ok | the item hidden, and every pending report on it cleared in the same commit (Operation 9, Operation 17) |
| [Moderate] | the move is not one of the six | [Invalid Move] | none (Operation 4) |
| [Dismiss] | the item has pending reports | ok | every pending report cleared; the standing untouched (Operation 18) |
| [Dismiss] | the item has none | ok | none, no write (Operation 19) |
| a writing action | item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 1, Operation 25) |
| a writing action | person reference blank, over the string cap, or not a string | [Invalid Person Reference] | none (Operation 2, Operation 26) |
| [Flag] | reason blank, over the reason cap, or not a string | [Invalid Reason] | none (Operation 3, Operation 27) |
| [Look Up] | any | the item's three settings; shown, open and unpinned where untouched | none (Operation 21, Operation 22, Operation 28) |
| [List Flagged] | any | every item with pending reports, the longest waiting first | none (Operation 23) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A hidden item waits in no queue.**
  ```
  Invariant 1.1: A pending report MUST NOT carry the item reference of a standing whose visibility EQUALS hidden.
  ```
- **Invariant 2 — One pending flag per person per item, one standing per item.**
  ```
  Invariant 2.1: Two pending reports MUST NOT share an item reference AND a reporter reference.
  Invariant 2.2: Two standings MUST NOT share an item reference.
  ```
- **Invariant 3 — A flag never changes whose it is or what it said.**
  ```
  Invariant 3.1: The atom MUST NOT change a report's reporter reference.
  Invariant 3.2: The atom MUST NOT change a report's reason.
  Invariant 3.3: The atom MUST NOT change a report's flagged instant.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Forum

Two members flag a post, `p-9`, as spam: `flag("p-9", "ana", "spam")` and `flag("p-9", "bo", "spam link")`. `list_flagged()` answers `p-9` with two pending reports. A moderator, `mo`, calls `moderate("p-9", "mo", "hide")`: the post is hidden and both reports are cleared in the same commit, so the queue is empty without another click. A weekly announcement, `p-1`, is pinned and locked: `moderate("p-1", "mo", "pin")` and `moderate("p-1", "mo", "lock")`; `look_up("p-1")` answers shown, locked, pinned.

### Shop reviews

A shopper flags a review as off-topic. The moderator reads it, finds it fair, and calls `dismiss("rev-44", "mo")`: the report is cleared and the review stays shown.

### Rejection paths

- `flag("", "ana", "spam")` — rejected as [Invalid Item Reference]: the reference is blank.
- `flag("p-9", "ana", "")` — rejected as [Invalid Reason]: the reason is blank.
- `moderate("p-9", "mo", "ban")` — rejected as [Invalid Move]: ban is not one of the six moves; cutting a person off is another pattern's.
- `moderate("p-9", "", "hide")` — rejected as [Invalid Person Reference].

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the standings and reports the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY standing carrying item reference, visibility, replies, placement, moderator reference AND moderated instant (State 1).
Check 1.2: An auditor MUST find EVERY report carrying item reference, reporter reference, reason, flagged instant AND status (State 5).
Check 2.1: An auditor MUST find no pending report carrying the item reference of a hidden standing (Invariant 1.1).
Check 3.1: An auditor MUST find no two pending reports sharing an item reference AND a reporter reference (Invariant 2.1).
Check 3.2: An auditor MUST find no two standings sharing an item reference (Invariant 2.2).
Check 4.1: An auditor MUST find EVERY version of a report carrying the reporter reference, reason AND flagged instant of the report's first version (Invariant 3.1 through 3.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a moderator confirmed as holding the right to moderate MUST read the deployment's roles (Non-goal 1).
External check 2: An auditor needing the deployment's clock confirmed as never reading one instant for two flags of one item by one person MUST read the deployment's clock declaration (Capability requirement 7).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT tell who may moderate.
Non-goal 2: The atom MUST NOT tell who may flag.
Non-goal 3: The atom MUST NOT remove an item.
Non-goal 4: The atom MUST NOT offer a list of reasons.
Non-goal 5: The atom MUST NOT notify an item's author.
Non-goal 6: The atom MUST NOT bar a person.
Non-goal 7: The atom MUST NOT refuse a reply on a locked item.
```

NOTE: the owners — the composing pattern that asks [Role](./role.md) (Non-goal 1, 2; External check 1); [Restorable Delete](./restorable-delete.md) (Non-goal 3); the composing pattern that shows the flag form (Non-goal 4); the composing pattern that tells the author, such as one built on [Notification](./notification.md) (Non-goal 5); [Actor Suspension](../compositions/actor-suspension.md) (Non-goal 6); the composing pattern that wires [Comment](./comment.md), reading [Look Up] before a reply (Non-goal 7); the composing pattern that attests who dismissed a report, such as [Audit Trail](../compositions/audit-trail.md), since [Dismiss] validates its moderator reference (Operation 2) and keeps none and State 5 gives a report no clearing field.

Where the atom breaks down: deleting an item, which is [Restorable Delete](./restorable-delete.md); cutting a person off, which is [Actor Suspension](../compositions/actor-suspension.md).

## Edge cases

### Concurrency

A [Flag] and a hide on one item are serialized (Execution Contract Database 2): a flag that lands first is cleared by the hide; a flag that lands on a hidden item writes nothing and answers ok (Operation 29, Operation 20), so a hidden item never returns to [List Flagged]. Two [Moderate] calls on one item are serialized the same way, and the standing is the later's.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Flag], [Moderate] or [Dismiss] where the first landed writes nothing and answers ok.

### What undoes a write

Each move has its opposite: show undoes hide, unlock undoes lock, unpin undoes pin. The reports a hide cleared stay cleared when the item is shown again, since the moderator saw them; a person who still objects flags again once the item is shown (Execution Contract Undo 4). A flag is undone by a [Dismiss] or a hide, which clear it, and a cleared report is never reopened.

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST supply the moderator reference of a caller the composing pattern authenticated AND found allowed to moderate.
Composition note 3: A composing pattern MUST hide from readers EVERY item [Look Up] answers hidden.
Composition note 4: A composing pattern MUST supply the reporter reference of a caller the composing pattern authenticated.
```

NOTE: composing patterns — none yet. Forthcoming: Forum, asking [Role](./role.md) who may moderate.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a standing; a report; a writing action; a reading action; an auditor.

Term records: standing — where one item stands with the moderators, carrying item reference, visibility, replies, placement, moderator reference and moderated instant; report — one person's flag on one item, carrying item reference, reporter reference, reason, flagged instant and status.

Term record verbs: identify, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, change, write, share, find, read, tell, offer, notify, bar, refuse, hide, own.

Term value sets: writing action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); visibility — shown | hidden; replies — open | locked; placement — unpinned | pinned; status — pending | cleared; move — hide | show | lock | unlock | pin | unpin; action rejection — invalid-item-reference | invalid-person-reference | invalid-reason | invalid-move | storage-failure.

Term bounds: string cap (the bound on an item reference's length and on a person reference's length in Unicode code points, 1,024 where a deployment declares none); reason cap (the bound on a reason's length in Unicode code points, 1,000 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from Scott's forum sketch.

Term terms: standing, standings, report, reports, item reference, reporter reference, moderator reference, reason, string cap, reason cap, seam, item, person reference, visibility, replies, placement, moderated instant, flagged instant, status, untouched, stands shown, stands hidden, writing action, reading action, move, person reference of the call, version.

#### Flag

Records a [Report] on an item from a person, with a [Reason], [Pending]; a person with a pending report on the item already is left as they are, and a hidden item takes no report. Answers ok.

Kind: Operation

#### Moderate

Applies one [Move] to an item's [Standing], stamping the [Moderator Reference] and [Moderated Instant]; a hide also clears every pending report on the item. A move that changes nothing writes nothing. Answers ok.

Kind: Operation

#### Dismiss

Clears every pending report on an item, leaving the standing as it is. Answers ok.

Kind: Operation

#### Look Up

Answers an item's [Visibility], [Replies] and [Placement], and changes nothing; shown, open and unpinned for an item no standing carries.

Kind: Operation

#### List Flagged

Answers every item with pending reports, the count and the earliest [Flagged Instant], longest waiting first, and changes nothing.

Kind: Operation

#### Standing

Where one item stands with the moderators: recorded by the first [Moderate] on the item that hides, locks or pins it, changed by later ones that change it; never removed by the atom.

Kind: Type

#### Report

One person's flag on one item: recorded by [Flag], cleared by a hide or by [Dismiss]; never removed by the atom.

Kind: Type

#### Move

What [Moderate] asks for: hide, show, lock, unlock, pin or unpin.

Kind:       Type
Projection: move

#### Item Reference

Names the item, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Standing
Projection: item_reference

#### Reporter Reference

The person reference of the person who flagged the item; never changed.

Kind:       Field
Field of:   Report
Projection: reporter_reference

#### Moderator Reference

The person reference of the moderator whose move last changed the standing.

Kind:       Field
Field of:   Standing
Projection: moderator_reference

#### Reason

The person's words for the flag; never changed.

Kind:       Field
Field of:   Report
Projection: reason

#### Visibility

Whether readers see the item: shown or hidden.

Kind:       Field
Field of:   Standing
Projection: visibility

#### Replies

Whether the item takes new replies: open or locked.

Kind:       Field
Field of:   Standing
Projection: replies

#### Placement

Whether the item sits at the top of its list: unpinned or pinned.

Kind:       Field
Field of:   Standing
Projection: placement

#### Moderated Instant

The instant of the latest [Moderate] that changed the standing, stamped from the injected now.

Kind:       Field
Field of:   Standing
Projection: moderated_instant

#### Flagged Instant

The instant of the [Flag] that recorded the report, stamped from the injected now; never changed.

Kind:       Field
Field of:   Report
Projection: flagged_instant

#### Status

Where a report stands: [Pending] or [Cleared].

Kind:       Field
Field of:   Report
Projection: status

#### Pending

The status of a report waiting for a moderator; it counts in [List Flagged].

Kind:       Member
Member of:  the status
Projection: pending

#### Cleared

The status of a report a hide or a [Dismiss] settled; it counts nowhere.

Kind:       Member
Member of:  the status
Projection: cleared

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string (Operation 1, Operation 25).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Invalid Person Reference

The refusal of a blank reporter or moderator reference, one over the string cap, or one that is not a string (Operation 2, Operation 26).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Invalid Reason

The refusal of a blank [Reason], one over the reason cap, or one that is not a string, on [Flag] (Operation 3, Operation 27).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-reason

#### Invalid Move

The refusal of a [Move] that is not hide, show, lock, unlock, pin or unpin (Operation 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-move

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Flag]: #flag
[Moderate]: #moderate
[Dismiss]: #dismiss
[Look Up]: #look-up
[List Flagged]: #list-flagged
[Standing]: #standing
[Report]: #report
[Move]: #move
[Item Reference]: #item-reference
[Reporter Reference]: #reporter-reference
[Moderator Reference]: #moderator-reference
[Reason]: #reason
[Visibility]: #visibility
[Replies]: #replies
[Placement]: #placement
[Moderated Instant]: #moderated-instant
[Flagged Instant]: #flagged-instant
[Status]: #status
[Pending]: #pending
[Cleared]: #cleared
[Invalid Item Reference]: #invalid-item-reference
[Invalid Person Reference]: #invalid-person-reference
[Invalid Reason]: #invalid-reason
[Invalid Move]: #invalid-move
[Storage Failure]: #storage-failure

---

## Standards references

Moderation is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.

---

## Status

`done — 2026-11-19` — see the Ledger.

## Ledger

```
status: done — 2026-11-19
formal: pending — no model yet
last gate: 2026-11-19 — Final Critique 2, a delta round, one reader (Linus claude-sonnet-5-5), frozen at 7912d4e3 — foundational count 0 after the blind second triage, clean, one sample; Linus's one report claimed none and held three questions (a pending report on a hidden item, two reports sharing a key, a standing without its stamp), which the blind triage traced through the frozen text and agreed hold; refining: show, unlock or unpin of an untouched item refuted (Term untouched stands shown, open and unpinned, so the move leaves the standing as it was and Operation 16 writes nothing, and a stamp would break Term moderated instant), [Dismiss] validating a moderator reference and keeping none placed Kind C and cured by naming the owner in the owners NOTE (an audit-recording composing pattern, such as Audit Trail; State 5 gives a report no clearing field), one string cap for both references declined as Kind D (Execution Contract Input 2 with Logic confinement 17 already holds an old cap until no held value exceeds the new one), Capability requirement 7 binding a no-write retry declined as Kind D (the deployment cannot know a call's outcome when it supplies now, Logic confinement 3 and 16); rhetorical accepted (the name Term person reference of the call); 2026-11-18 — Final Critique 1, frozen at b3395186 — foundational count 4, cured by the settle, not clean, no sample

open: none
```

## Decisions

- **2026-11-18 — Drafted through the Grace connector mirroring Reaction, from Scott's forum sketch.** *Chose:* flag, then six moves on three independent settings, and a hide that clears the item's pending flags in the same commit. *Over:* a moderator clearing the queue by hand. *Because:* Scott, 2026-11-18, on leftover approval items: "making managers manually clean up workers mess is ... pure make work. We are here to reduce work."

NOTE: End of Moderation.

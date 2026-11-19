---
title: Restorable Delete
id: 72
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Restorable Delete

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Restorable Delete makes deleting something a two-step act: delete marks an item deleted and opens a window to bring it back, 30 days unless the business sets another; restore brings it back inside that window; purge makes the delete final, and nothing brings back a purged item. An accidental delete is undone by one restore, and a final delete is always a separate, deliberate act. The atom records where each item stands — present, deleted or purged — and answers which deleted items are past their window, so a nightly job can purge them. Who may delete or restore, hiding a deleted item from readers, destroying the item's stored copies, and a legal hold that forbids destruction each belong to another pattern, which is why one restorable delete serves a forum's posts, a shop's products and a team's files alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

People delete by mistake, and businesses need some deletes to be final. This atom holds both. Three decisions carry the weight. Deleting and purging are two acts, and purge is refused on an item not first deleted, so nothing is destroyed in one slip. The restore window is fixed when the item is deleted, so a reader can always tell a person how long they have, and a restore past the window is refused rather than silently honoured. And the atom keeps only where an item stands: the item's own record is another pattern's, the database's history keeps every earlier version of the item, and destroying those versions is a separate pattern's job, with Erasure Tombstone recording that a lawful destruction happened. An item with no deletion record stands present, so nothing is written for the many items never deleted. Taken in from MIT's sync-engine Trashing concept (Daniel Jackson's group). Its spec names the normal state "kept" while its actions say "active"; here the one word is present.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a deletion by the deletion's item reference.
Identity 2: The atom MUST NOT normalize an item reference.
Identity 3: The atom MUST compare two item references codepoint for codepoint.
```

Term deletion: the record of where one deleted item stands, kept from the item's first delete — a [Deletion].

Term item reference: the string naming an item, such as a post, a product or a file, in the deployment's own scheme — an [Item Reference]; the atom reads no scheme in it.

Term restore window: how long a deleted item may be restored, a whole number of days of 86,400 seconds each, one or more; 30 days where a deployment declares none.

Term string cap: the bound on an item reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

### State

```
State 1: EVERY deletion MUST carry item reference and status.
State 2: EVERY deletion MUST stand in EXACTLY ONE OF present, deleted, purged.
State 3: EVERY deletion standing in deleted MUST carry a deleted instant AND a restore deadline.
State 4: The atom MUST NOT remove a deletion.
```

Term status: where an item stands, present, deleted or purged — the [Status].

Term present: the status of an item readers may see — [Present]; an item with no deletion stands present.

Term deleted: the status of an item marked deleted, restorable until its restore deadline passes — [Deleted].

Term purged: the status of an item deleted for good — [Purged]; final.

Term deleted instant: the instant of the latest [Delete] call that stood the item in deleted — the [Deleted Instant].

Term restore deadline: `(deleted_instant + restore_window)` — the [Restore Deadline] (Execution Contract Logic confinement 9).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MAY declare the restore window PER Execution Contract Logic confinement 17.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
```

### Operations

```
delete(item_reference)
  answers ok
  refuses invalid-item-reference | item-purged | storage-failure

restore(item_reference)
  answers ok
  refuses invalid-item-reference | item-purged | restore-window-closed | storage-failure

purge(item_reference)
  answers ok
  refuses invalid-item-reference | not-deleted | storage-failure

look_up(item_reference)
  answers standings(status, restore_deadline)

list_deleted()
  answers items(item_reference, deleted_instant, restore_deadline)

list_expired()
  answers items(item_reference, restore_deadline)
```

```
Operation 1: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN a writing action MUST answer invalid-item-reference.
Operation 2: IF the deletion's status EQUALS purged THEN [Delete] MUST answer item-purged.
Operation 3: IF the deletion's status EQUALS purged THEN [Restore] MUST answer item-purged.
Operation 4: IF no deletion EXISTS for the item reference THEN [Delete] MUST record EXACTLY ONE deletion carrying the item reference of the call.
Operation 5: IF the item stands present THEN [Delete] MUST stand the deletion in deleted.
Operation 6: IF the item stands present THEN [Delete] MUST stamp deleted instant from the injected now.
Operation 7: IF the item stands present THEN [Delete] MUST stamp restore deadline from the injected now AND the restore window.
Operation 8: IF the deletion's status EQUALS deleted THEN [Delete] MUST NOT write.
Operation 9: IF the deletion's status EQUALS deleted AND the deletion's restore deadline PRECEDES the injected now THEN [Restore] MUST answer restore-window-closed.
Operation 10: IF the deletion's status EQUALS deleted THEN [Restore] MUST stand the deletion in present.
Operation 11: IF the item stands present THEN [Restore] MUST NOT write.
Operation 12: IF the item stands present THEN [Purge] MUST answer not-deleted.
Operation 13: IF the deletion's status EQUALS deleted THEN [Purge] MUST stand the deletion in purged.
Operation 14: IF the deletion's status EQUALS purged THEN [Purge] MUST NOT write.
Operation 15: A writing action MUST answer ok.
Operation 16: [Look Up] MUST answer the status of the item reference's deletion.
Operation 17: [Look Up] MUST answer present for an item reference no deletion carries.
Operation 18: [List Deleted] MUST answer EVERY deletion standing in deleted, in deleted instant order, then in codepoint order of item reference.
Operation 19: [List Expired] MUST answer EVERY deletion standing in deleted whose restore deadline PRECEDES the injected now, in restore deadline order, then in codepoint order of item reference.
Operation 20: A reading action MUST NOT write.
Operation 21: IF the item reference is malformed THEN a writing action MUST answer invalid-item-reference (Execution Contract Input 1).
Operation 22: IF the item reference is malformed OR the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Look Up] MUST answer present (Execution Contract Query 5).
Operation 23: IF the deletion's status EQUALS deleted THEN [Look Up] MUST answer the restore deadline of the deletion.
Operation 24: IF the item stands present OR the deletion's status EQUALS purged THEN [Look Up] MUST answer a blank restore deadline.
```

Term writing action: [Delete] | [Restore] | [Purge] — the actions that change where an item stands.

Term reading action: [Look Up] | [List Deleted] | [List Expired] — the actions that change nothing.

Term stands present: an item stands present where no deletion carries the item reference, or where the item's deletion's status EQUALS present.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect |
|---|---|---|---|
| [Delete] | the item stands present, reference valid | ok | the item stands deleted, its deleted instant now, its restore deadline one restore window on (Operation 4 through 7) |
| [Delete] | the item stands deleted | ok | none, no write; the restore deadline stands (Operation 8) |
| [Delete] | the item stands purged | [Item Purged] | none (Operation 2) |
| [Restore] | the item stands deleted, inside the window | ok | the item stands present (Operation 10) |
| [Restore] | the item stands deleted, past the window | [Restore Window Closed] | none (Operation 9) |
| [Restore] | the item stands present | ok | none, no write (Operation 11) |
| [Restore] | the item stands purged | [Item Purged] | none (Operation 3) |
| [Purge] | the item stands deleted, inside or past the window | ok | the item stands purged, for good (Operation 13) |
| [Purge] | the item stands present | [Not Deleted] | none (Operation 12) |
| [Purge] | the item stands purged | ok | none, no write (Operation 14) |
| a writing action | reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 1, Operation 21) |
| [Look Up] | any | the item's status, and the restore deadline where the item stands deleted; present where no deletion carries the reference; a blank restore deadline where the item does not stand deleted | none (Operation 16, Operation 17, Operation 22, Operation 23, Operation 24) |
| [List Deleted] | any | every deleted item, oldest deleted first | none (Operation 18) |
| [List Expired] | any | every deleted item past its window, the earliest deadline first | none (Operation 19) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — Purged is final.**
  ```
  Invariant 1.1: The atom MUST NOT change the status of a deletion standing in purged.
  ```
- **Invariant 2 — One deletion per item.**
  ```
  Invariant 2.1: Two deletions MUST NOT share an item reference.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Forum

A member deletes her own post, `p-7`: `delete("p-7")` answers ok, and `look_up("p-7")` answers deleted with a restore deadline 30 days on. The forum hides the post from readers because the post stands deleted. Two days later she changes her mind; `restore("p-7")` answers ok and the post is back. A spam post, `p-9`, is deleted by a moderator and purged at once with `purge("p-9")`; `restore("p-9")` now answers [Item Purged].

### Shop

A shop sets the restore window to seven days. Each night a job calls `list_expired()` and purges every product it answers; a product deleted six days ago is not in the list and can still be restored.

### Rejection paths

- `delete("")` — rejected as [Invalid Item Reference]: the reference is blank.
- `purge("p-8")` on a post never deleted — rejected as [Not Deleted]: purge is refused on an item not first deleted.
- `restore("p-5")` 31 days after `delete("p-5")` — rejected as [Restore Window Closed]: the item still stands deleted, past its deadline.
- `delete("p-9")` once purged — rejected as [Item Purged]: purged is final.

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the deletions the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY deletion carrying item reference AND status (State 1).
Check 1.2: An auditor MUST find EVERY deletion standing in EXACTLY ONE OF present, deleted, purged (State 2).
Check 1.3: An auditor MUST find EVERY deletion standing in deleted carrying a deleted instant AND a restore deadline (State 3).
Check 2.1: An auditor MUST find EVERY version of a deletion later than a purged version standing in purged (Invariant 1.1).
Check 3.1: An auditor MUST find no two deletions sharing an item reference (Invariant 2.1).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a purged item's stored copies confirmed as destroyed MUST read the deployment's erasure tombstones (Non-goal 4).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT tell who may delete an item.
Non-goal 2: The atom MUST NOT tell who may restore an item.
Non-goal 3: The atom MUST NOT hide a deleted item from readers.
Non-goal 4: The atom MUST NOT destroy an item's stored copies.
Non-goal 5: The atom MUST NOT hold a legal hold.
Non-goal 6: The atom MUST NOT purge an item on a schedule.
Non-goal 7: The atom MUST NOT check an item reference against a catalog.
```

NOTE: the owners — the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 1, 2); the composing pattern that shows the item, reading [Look Up] (Non-goal 3); Shred *(forthcoming)*, with [Erasure Tombstone](./erasure-tombstone.md) recording the destruction (Non-goal 4; External check 1); [Legal Hold](./legal-hold.md) and [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 5); the composing pattern whose nightly job reads [List Expired] (Non-goal 6); Catalog *(forthcoming)* (Non-goal 7).

Where the atom breaks down: a record kept for a set time by law and then destroyed, which is [Retention Window](./retention-window.md); a person's own take-back of a comment, which is a comment's retraction *(forthcoming)*.

## Edge cases

### Concurrency

A [Restore] and a [Purge] on one deleted item are serialized (Execution Contract Database 2): where the restore lands first, the purge meets a present item and answers [Not Deleted]; where the purge lands first, the restore answers [Item Purged]. Either way the item ends in one status.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Delete], [Restore] or [Purge] where the first landed and nothing has moved the item since writes nothing and answers ok; a repeated [Delete] keeps the first restore deadline.

### A restore window that changes

A deployment that changes the restore window changes the deadline of items deleted from then on; an item already deleted keeps the restore deadline stamped at its delete.

### What undoes a write

[Restore] undoes [Delete] inside the restore window, and [Delete] undoes [Restore]. A [Purge] is never undone: that is the point of the act, and the item's history in the database stays until Shred *(forthcoming)* destroys it (Execution Contract Undo 4).

NOTE: open 2026-11-18-a — nothing says whether [Purge] is an irreversible action in the sense of Execution Contract Undo 1, which would owe Undo 2's naming in its own rules, or a state made final that erases no record (State 4, Undo 4).

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST hide from readers EVERY item the atom answers deleted.
Composition note 3: A composing pattern MUST hide from readers EVERY item the atom answers purged.
```

NOTE: composing patterns — none yet. Forthcoming: Forum.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a deletion; a writing action; a reading action; an auditor.

Term records: deletion — where one deleted item stands, carrying item reference, status and, while deleted, deleted instant and restore deadline.

Term record verbs: identify, normalize, compare, carry, stand, remove, supply, declare, record, stamp, answer, change, write, share, find, read, tell, hide, destroy, hold, purge, check, own.

Term value sets: writing action and reading action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — present | deleted | purged; action rejection — invalid-item-reference | item-purged | restore-window-closed | not-deleted | storage-failure.

Term bounds: string cap (the bound on an item reference's length in Unicode code points, 1,024 where a deployment declares none); restore window (a whole number of days of 86,400 seconds each, one or more; 30 days where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang (2026-11-18) through the Grace connector, from MIT's sync-engine Trashing concept.

Term terms: deletion, deletions, item reference, restore window, string cap, seam, status, present, deleted, purged, deleted instant, restore deadline, writing action, reading action, stands present, version.

#### Delete

Stands a present item in [Deleted], recording its [Deletion] where it has none, stamping its [Deleted Instant] and its [Restore Deadline]. An item already deleted is left as it is. Answers ok.

Kind: Operation

#### Restore

Stands a deleted item back in [Present] inside its restore window. A present item is left as it is. Answers ok.

Kind: Operation

#### Purge

Stands a deleted item in [Purged], for good. A purged item is left as it is. Answers ok.

Kind: Operation

#### Look Up

Answers where one item stands, with its restore deadline where it stands deleted, and changes nothing; present where no deletion carries it.

Kind: Operation

#### List Deleted

Answers every deleted item, oldest deleted first, and changes nothing.

Kind: Operation

#### List Expired

Answers every deleted item past its restore deadline, the earliest deadline first, and changes nothing; a nightly job reads it to purge.

Kind: Operation

#### Deletion

Where one deleted item stands: recorded by the item's first [Delete], moved by [Restore] and [Purge]; never removed by the atom.

Kind: Type

#### Item Reference

Names the item a deletion is about, in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Deletion
Projection: item_reference

#### Status

Where an item stands: [Present], [Deleted] or [Purged].

Kind:       Field
Field of:   Deletion
Projection: status

#### Present

The status of an item readers may see; an item never deleted stands present without a record.

Kind:       Member
Member of:  the status
Projection: present

#### Deleted

The status of an item marked deleted, restorable until its restore deadline passes.

Kind:       Member
Member of:  the status
Projection: deleted

#### Purged

The status of an item deleted for good; never changed.

Kind:       Member
Member of:  the status
Projection: purged

#### Deleted Instant

The instant of the latest [Delete] that stood the item in deleted, stamped from the injected now.

Kind:       Field
Field of:   Deletion
Projection: deleted_instant

#### Restore Deadline

The instant one restore window on from the [Deleted Instant]; a [Restore] later than it is refused.

Kind:       Field
Field of:   Deletion
Projection: restore_deadline

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string (Operation 1, Operation 21).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Item Purged

The refusal of a [Delete] or a [Restore] on a [Purged] item (Operation 2, Operation 3).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: item-purged

#### Restore Window Closed

The refusal of a [Restore] on a [Deleted] item past the item's [Restore Deadline] (Operation 9).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: restore-window-closed

#### Not Deleted

The refusal of a [Purge] on a [Present] item: purge follows a delete, never replaces one (Operation 12).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-deleted

#### Storage Failure

The refusal a writing call answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Delete]: #delete
[Restore]: #restore
[Purge]: #purge
[Look Up]: #look-up
[List Deleted]: #list-deleted
[List Expired]: #list-expired
[Deletion]: #deletion
[Item Reference]: #item-reference
[Status]: #status
[Present]: #present
[Deleted]: #deleted
[Purged]: #purged
[Deleted Instant]: #deleted-instant
[Restore Deadline]: #restore-deadline
[Invalid Item Reference]: #invalid-item-reference
[Item Purged]: #item-purged
[Restore Window Closed]: #restore-window-closed
[Not Deleted]: #not-deleted
[Storage Failure]: #storage-failure

---

## Standards references

Restorable Delete is a primitive with no regulatory anchor. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, and its Trash concept, which this atom narrows to the rules alone (the database remembers where the item was).
- **MIT's sync-engine, Trashing concept** (github.com/mit-sdg/sync-engine) — the taken-in source: a reversible removal recorded before an irreversible one. This atom adds the restore window and names the normal state once, present.

---

## Status

`doing` — see the Ledger.

## Ledger

```
status: doing
formal: pending — no model yet
last gate: 2026-11-19 — Final Critique 2, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at bcecf938 — foundational count 0 after the blind second triage, clean, one sample; Linus's one foundational claim and two refining remarks placed none held by both triages (the foundational refuted: Operation 9 lands restore-window-closed, which [Restore] lists on its refuses line, and Operation 10 says what the action writes, which Execution Contract Read 4 holds only for a call the action admits, so a refused call writes nothing and no build reads the two as competing; the cure would restate Read 4; refining: the NOTE under State 4 is the open line 2026-11-18-a, and the restore window's default read at start is Execution Contract Logic confinement 17, which Capability requirement 4 cites); the round read the reach of Final Critique 1's cures (46 labels) by their diff, and the blind second triage's press found no foundational; 2026-11-18 — Final Critique 1, frozen at 27b7fd47 — foundational count 3, cured by the settle, not clean, no sample

open:
- 2026-11-18-a · refining · Operation 13 · nothing says whether Purge is irreversible in the sense of Execution Contract Undo 1 or a state made final that erases nothing → decide which, and name the irreversible action in its own rules if it is
```

## Decisions

- **2026-11-18 — Taken in from MIT's Trashing concept, drafted through the Grace connector mirroring Reaction.** *Chose:* present, deleted and purged, a restore window fixed at delete, purge refused on an item not first deleted. *Over:* MIT's three states, whose spec names the normal one kept and whose actions say active, and a restore with no window. *Because:* Scott's forum sketch: "tombstone with a restore window"; one name for one state.

NOTE: End of Restorable Delete.

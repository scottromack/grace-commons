---
title: Punch Card
id: 62
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Punch Card

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Punch Card is a shop's punch card: a punch card collects one stamp per purchase, and a punch card that has reached its goal, five stamps where the shop sets no other number, is traded for one free item. Whoever holds the punch card's code collects the stamps and claims the free item, so the code is drawn at random, so that nobody can guess it, and the shop's own records name the punch card by a separate card id that carries no meaning of its own. A stamp adds exactly one, and a full punch card takes no more stamps until its free item is claimed. Claiming the free item empties the punch card, so the same punch card starts again from no stamps, and the punch card counts every free item it has given. What counts as a purchase, which item is free, who at the shop may stamp, and extras such as double-stamp days or expiry each belong to another pattern, which is why one punch card serves a thrift store, a café and a car wash alike.

<details markdown="block">
<summary>WHY</summary>

The shape recurs wherever a shop rewards a returning customer: a count, a goal, a reward claimed at the goal. Two decisions carry the weight. A stamp adds one or is refused, so a call means one thing and a stamp count never passes the goal. Redeeming restarts the same punch card, so one punch card serves a customer for good and a balance is read from the punch card alone. Double stamps, expiry, transfer and taking a stamp back make a loyalty card system, a different concept.

</details>

## What it keeps

### The record

Term punch card: one count of stamps collected toward a goal and traded for a free item at the goal — a [Punch Card].

#### Punch Card

Started by [Issue], raised by [Stamp], emptied by [Redeem]; the atom never cancels, expires or removes it.

Kind: Type

Term card id: the opaque value naming one punch card in the shop's records — a [Card Id]; unique for the system's life, and it claims nothing.

#### Card Id

Immutable; allocated by the host at the seam on [Issue].

Kind:       Field
Field of:   Punch Card
Projection: card_id

```
Identity 1: The atom MUST identify a punch card by the card id.
Identity 6: The atom MUST NOT reuse a card id.
Identity 10: The atom MUST compare two card ids codepoint for codepoint.
```

Term card code: the random value whose holder collects stamps on a punch card and claims its free item — a [Card Code]; unique for the system's life, answered once, by [Issue].

#### Card Code

Allocated by the host at the seam on [Issue] from a cryptographically secure random source, with at least 64 bits of random material; never changed, stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Punch Card
Projection: card_code

```
Identity 2: The atom MUST find a punch card by the card code.
Identity 3: The card code MUST serve as the bearer credential [Check Stamps] accepts.
Identity 4: The card code MUST serve as the bearer credential [Stamp] accepts.
Identity 5: The card code MUST serve as the bearer credential [Redeem] accepts.
Identity 7: The atom MUST NOT reuse a card code.
Identity 8: The atom MUST NOT normalize a card code.
Identity 9: The atom MUST compare two card codes codepoint for codepoint.
```

Term whole count: a whole number, zero or more.

Term positive count: a whole count of one or more.

Term goal: the number of stamps that earns a punch card's free item — a [Goal]; a positive count, set when the punch card is issued.

#### Goal

Set by [Issue] from the [Stamp Goal]; never changed.

Kind:       Field
Field of:   Punch Card
Projection: goal

Term stamps: the number of stamps a punch card holds toward its next free item — the [Stamps]; a whole count, never more than the goal.

#### Stamps

Set to zero by [Issue], raised by one by [Stamp], set to zero by [Redeem].

Kind:       Field
Field of:   Punch Card
Projection: stamps

Term redemptions: the number of free items a punch card has given — the [Redemptions]; a whole count.

#### Redemptions

Set to zero by [Issue], raised by one by [Redeem], never lowered.

Kind:       Field
Field of:   Punch Card
Projection: redemptions

```
State 1: EVERY punch card MUST carry card id, card code, goal, stamps and redemptions.
State 2: The atom MUST NOT remove a punch card.
```

## What people do

### Every action

Term code action: [Check Stamps] | [Stamp] | [Redeem] — the actions that name a punch card by the card code.

```
Operation 6: IF no punch card EXISTS for the card code, including a card code that is not a string, THEN a code action MUST answer not-known.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| a code action | the code names nothing | [Not Known] | none (Operation 6) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

#### Not Known

The refusal of a [Card Code] naming no punch card, on [Check Stamps], [Stamp] or [Redeem], or of a [Card Id] naming no punch card, on [Read].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Storage Failure

The refusal [Issue], [Stamp] or [Redeem] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

### Issue

Starts a punch card: records a punch card whose [Goal] is the [Stamp Goal] and whose [Stamps] and [Redemptions] are zero, and answers [Issued], the new [Card Id] and [Card Code]. The only action that ever answers the code.

Kind: Operation

```
issue()
  answers issued(card_id, card_code)
  refuses storage-failure
```

```
Operation 1: [Issue] MUST record EXACTLY ONE punch card carrying the card id AND the card code the seam supplied.
Operation 2: [Issue] MUST set the punch card's goal to the stamp goal PER Execution Contract Logic confinement 17.
Operation 3: [Issue] MUST set the punch card's stamps to zero.
Operation 4: [Issue] MUST set the punch card's redemptions to zero.
Operation 5: [Issue] MUST answer the card id AND the card code.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| [Issue] | database accepts | the card id and the card code | one punch card lands, its goal the stamp goal, its stamps and redemptions zero (Operation 1 through 4) |

#### Issued

The [Issue] outcome when the call records a punch card. It carries the [Card Id] and the [Card Code].

Kind:       Member
Member of:  the issue outcome
Role:       Outcome
Projection: issued

### Check Stamps

Answers how far along a punch card is, its [Stamps] and [Goal], for the [Card Code] presented, and changes nothing.

Kind: Operation

```
check_stamps(card_code)
  answers stamps(stamps, goal)
  refuses not-known
```

```
Operation 7: [Check Stamps] MUST answer the punch card's stamps AND the punch card's goal.
Operation 8: [Check Stamps] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| [Check Stamps] | the code names a punch card | the stamps and the goal | none (Operation 7, Operation 8) |

- `check_stamps("NOSUCHCODE000000")` — rejected as [Not Known].

### Stamp

Adds one stamp to a punch card, named by its [Card Code], and answers the new [Stamps]. A punch card already at its [Goal] is refused, and the stamps stay as they were.

Kind: Operation

```
stamp(card_code)
  answers stamps
  refuses not-known | full | storage-failure
```

Term stamped total: (the punch card's stamps + 1) — the stamps a [Stamp] call that lands leaves on the punch card.

```
Operation 9: IF the punch card's stamps EQUALS the punch card's goal THEN [Stamp] MUST answer full.
Operation 10: [Stamp] MUST set stamps to the stamped total PER Execution Contract Logic confinement 9.
Operation 11: [Stamp] MUST answer the punch card's new stamps.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| [Stamp] | stamps below the goal, database accepts | the new stamps | the stamps rise by one; the card code and the goal stand (Operation 10, Invariant 2.1, Invariant 2.2) |
| [Stamp] | stamps at the goal | [Full] | none (Operation 9, Invariant 3.1) |

#### Full

[Stamp]'s refusal of a punch card whose [Stamps] have reached its [Goal]; the stamps stay as they were, and the caller redeems the punch card first.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: full

The thrift store above, with punch card `p1` holding 5 stamps of a goal of 5, and punch card `p2`, code `"M3RX8TQ2WN6PLHC4"`, holding 3:

- `stamp("7KQ9M2XV4RTP8HNC")` — rejected as [Full]; the stamps stay 5 (Invariant 3.1), and the till redeems the punch card, then stamps it.

- `stamp("7kq9m2xv4rtp8hnc")` — rejected as [Not Known]: two codes are compared codepoint for codepoint, and neither the atom nor the deployment normalizes one (Identity 8, Identity 9, Capability requirement 7).

### Redeem

Trades a full punch card, named by its [Card Code], for one free item: sets the [Stamps] to zero, adds one to the [Redemptions], and answers the new redemptions. A punch card below its [Goal] is refused and stays as it was.

Kind: Operation

```
redeem(card_code)
  answers redemptions
  refuses not-known | not-full | storage-failure
```

Term redeemed total: (the punch card's redemptions + 1) — the redemptions a [Redeem] call that lands leaves on the punch card.

```
Operation 12: IF the punch card's stamps DOES NOT EQUAL the punch card's goal THEN [Redeem] MUST answer not-full.
Operation 13: [Redeem] MUST set stamps to zero.
Operation 14: [Redeem] MUST set redemptions to the redeemed total PER Execution Contract Logic confinement 9.
Operation 15: [Redeem] MUST answer the punch card's new redemptions.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| [Redeem] | stamps at the goal, database accepts | the new redemptions | the stamps fall to zero and the redemptions rise by one; the card code and the goal stand (Operation 13, Operation 14, Invariant 2.1, Invariant 2.2) |
| [Redeem] | stamps below the goal | [Not Full] | none (Operation 12, Invariant 3.2, Invariant 3.3) |

#### Not Full

[Redeem]'s refusal of a punch card whose [Stamps] have not reached its [Goal]; the punch card stays as it was.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-full

- `redeem("M3RX8TQ2WN6PLHC4")` — rejected as [Not Full]; the stamps stay 3 (Invariant 3.2).

### Read

Answers a punch card for the shop's records, named by its [Card Id]: the card id, its [Goal], [Stamps] and [Redemptions], never its [Card Code]; changes nothing.

Kind: Operation

```
read(card_id)
  answers punch card(card_id, goal, stamps, redemptions)
  refuses not-known
```

```
Operation 16: IF no punch card EXISTS for the card id, including a card id that is not a string, THEN [Read] MUST answer not-known.
Operation 17: [Read] MUST answer the punch card's card id, goal, stamps AND redemptions.
Operation 18: [Read] MUST NOT answer the card code.
Operation 19: [Read] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the punch cards |
|---|---|---|---|
| [Read] | the card id names a punch card | the card id, goal, stamps and redemptions, never the code | none (Operation 17 through 19) |
| [Read] | the card id names nothing | [Not Known] | none (Operation 16) |

- `read(p404)`, where no punch card `p404` exists — rejected as [Not Known].

## What is and what should never be (Invariants)

- **Invariant 1 — A punch card never holds more stamps than its goal.**
  ```
  Invariant 1.1: EVERY punch card MUST carry a whole count as the punch card's stamps.
  Invariant 1.2: A punch card's stamps MUST NOT EXCEED the punch card's goal.
  ```

- **Invariant 2 — A punch card keeps its code and its goal, and its redemptions never fall.**
  ```
  Invariant 2.1: The atom MUST NOT change a punch card's card code.
  Invariant 2.2: The atom MUST NOT change a punch card's goal.
  Invariant 2.3: The atom MUST NOT lower a punch card's redemptions.
  ```
- **Invariant 3 — A refused call changes nothing.**
  ```
  Invariant 3.1: A refused [Stamp] MUST NOT change a punch card's stamps.
  Invariant 3.2: A refused [Redeem] MUST NOT change a punch card's stamps.
  Invariant 3.3: A refused [Redeem] MUST NOT change a punch card's redemptions.
  ```

## When something happens

### Concurrency

Two stamps on one punch card are serialized (Execution Contract Database 2): the later reads the stamps the earlier left and is refused as [Full] if the earlier reached the goal, so two stamps never carry a punch card past its goal (Invariant 1). Two redeems on one full punch card are serialized the same way: the later reads an empty punch card and is refused as [Not Full], so one full punch card gives one free item.

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Stamp] where the first landed adds a second stamp, or is refused as [Full]; so a caller whose answer to [Stamp] is lost calls [Check Stamps] first, and a composing pattern needing a repeat to stamp once composes Duplicate Prevention (Non-goal 13). A repeated [Redeem] where the first landed is refused as [Not Full] and gives nothing more. A repeated [Issue] records a second punch card; the first stays empty, its card code known to the deployment alone, since the code reaches a caller only in [Issue]'s answer (Operation 5, Operation 18).

## Optional

```
Capability requirement 1: The deployment MUST supply at the seam a card id no punch card has carried PER Execution Contract Logic confinement 3.
Capability requirement 2: The deployment MUST supply at the seam a card code no punch card has carried PER Execution Contract Logic confinement 3.
Capability requirement 3: The deployment MUST draw a card code from a cryptographically secure random source.
Capability requirement 4: The card code's random material MUST NOT fall below the code entropy.
Capability requirement 5: The deployment MAY supply the stamp goal ONLY IF the stamp goal IS IN the positive counts PER Execution Contract Input 2.
Capability requirement 6: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
Capability requirement 7: The deployment MUST NOT normalize a card code at the seam.
Capability requirement 8: The deployment MUST supply each card id PER Execution Contract Logic confinement 16.
Capability requirement 9: The deployment MUST supply each card code PER Execution Contract Logic confinement 16.
```

NOTE: the atom declares no reference, so Execution Contract Logic confinement 13 does not reach the card code (Capability requirement 7).

NOTE: watch the id the host supplies to two calls (Capability requirement 8, Capability requirement 9).

Term code entropy: 64 bits, the least random material a card code carries.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each card id and card code here.

Term stamp goal: the number of stamps the deployment asks for one free item — a [Stamp Goal]; a positive count; five where a deployment declares none.

#### Stamp Goal

The number of stamps the deployment asks for one free item; five where a deployment declares none. A change reaches the punch cards issued from the instance's next start on (Execution Contract Logic confinement 17).

Kind:       Parameter
Parameter of: Issue
Projection: stamp_goal

NOTE: watch the unset setting (Capability requirement 5).

## Left to others

```
Non-goal 1: The atom MUST NOT add a bonus stamp.
Non-goal 2: The atom MUST NOT take a stamp back.
Non-goal 3: The atom MUST NOT transfer a punch card's stamps.
Non-goal 4: The atom MUST NOT expire a punch card.
Non-goal 5: The atom MUST NOT cancel a punch card.
Non-goal 6: The atom MUST NOT tell what counts as a purchase.
Non-goal 7: The atom MUST NOT choose the free item.
Non-goal 8: The atom MUST NOT price the free item.
Non-goal 9: The atom MUST NOT tell who may stamp a punch card.
Non-goal 10: The atom MUST NOT limit attempts to guess a card code.
Non-goal 11: The atom MUST NOT hold a punch card's owner.
Non-goal 12: The atom MUST NOT hold money.
Non-goal 13: The atom MUST NOT tell a repeated stamp from a new stamp.
```

NOTE: the owners — Loyalty Card *(forthcoming)* (Non-goal 1, 2, 3, 4, 5); Checkout *(forthcoming)* (Non-goal 6, 7, 8); [Permissions](./permissions.md) (Non-goal 9); Rate Limit *(forthcoming)* (Non-goal 10); the composing pattern that knows the holder, such as one built on [Session](./session.md) or [Party Identity](./party-identity.md) (Non-goal 11); [Gift Card](./gift-card.md) (Non-goal 12); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 13).

Where the atom breaks down: a reward that grows with the money spent, a double-stamp day, or a stamp that must come back off when a purchase is returned, which is a loyalty card system.

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST stamp a punch card once per purchase.
```

NOTE: composing patterns — none yet. Forthcoming: Checkout.

## Example

A thrift store that declares no stamp goal hands a shopper a punch card: `issue()` answers `issued(p1, "7KQ9M2XV4RTP8HNC")`. Each purchase earns a stamp: the first `stamp("7KQ9M2XV4RTP8HNC")` answers 1, and the fifth answers 5. The shopper picks a free item, and the till redeems: `redeem("7KQ9M2XV4RTP8HNC")` answers 1, the punch card's first redemption, and the next purchase's stamp answers 1 again. The back office reads the punch card by its id: `read(p1)` answers a goal of 5, 1 stamp and 1 redemption, and no code. A café that declares a stamp goal of 6 runs the same calls with six coffees; when it later raises the goal to 8 and the instance restarts (Execution Contract Logic confinement 17), its earlier punch cards keep 6 and a punch card issued after the restart carries 8.

## Source

Punch Card is a primitive with no regulatory anchor: a punch card holds no money (Non-goal 12). It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving checkout, permissions and loyalty to concepts of their own.

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the punch cards the database holds, with their earlier versions (Execution Contract Database 5). The atom carries no adversarial scenarios: a punch card holds no money and never expires (Non-goal 4, Non-goal 12).

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY punch card carrying card id, card code, goal, stamps AND redemptions (State 1).
Check 2.1: An auditor MUST find no two punch cards sharing a card id (Identity 6).
Check 2.2: An auditor MUST find no two punch cards sharing a card code (Identity 7).
Check 3.1: An auditor MUST find EVERY punch card carrying a whole count as the punch card's stamps (Invariant 1.1).
Check 3.2: An auditor MUST find no punch card whose stamps EXCEEDS the punch card's goal (Invariant 1.2).
Check 4.1: An auditor MUST find EVERY version of a punch card carrying the card code of the punch card's first version (Invariant 2.1).
Check 4.2: An auditor MUST find EVERY version of a punch card carrying the goal of the punch card's first version (Invariant 2.2).
Check 4.3: An auditor MUST find no version of a punch card whose redemptions fall below the redemptions of the punch card's previous version (Invariant 2.3).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor MUST clear from the deployment's own random source that EVERY card code is drawn from a cryptographically secure random source carrying the code entropy (Capability requirement 3, Capability requirement 4).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a punch card; a code action; an auditor.

Term records: punch card — one count of stamps collected toward a goal, carrying card id, card code, goal, stamps and redemptions.

Term record verbs: identify, find, serve, reuse, normalize, compare, carry, remove, supply, draw, fall, record, set, answer, write, change, lower, share, read, add, take, transfer, expire, cancel, tell, choose, price, limit, hold, own, stamp, clear, refuse.

Term value sets: code action is declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: positive count (one, the floor of a goal and a stamp goal); whole count (zero, the floor of stamps and redemptions); code entropy (64 bits, the floor of a card code's random material).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.69 (2026-11-13) through the Grace connector.

Term terms: punch card, card id, card code, code entropy, seam, goal, stamps, redemptions, whole count, positive count, stamp goal, stamped total, redeemed total, code action, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Issue]: #issue
[Check Stamps]: #check-stamps
[Stamp]: #stamp
[Redeem]: #redeem
[Read]: #read
[Issued]: #issued
[Punch Card]: #punch-card
[Card Id]: #card-id
[Card Code]: #card-code
[Goal]: #goal
[Stamps]: #stamps
[Redemptions]: #redemptions
[Stamp Goal]: #stamp-goal
[Not Known]: #not-known
[Full]: #full
[Not Full]: #not-full
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-13` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-13
formal: verified — punch-card.als + 11 twins (the static data model: State 1, Identity 6 through 9, Operation 1 through 4, Invariant 1.1 and 1.2 checked on every version a sequence of admitted calls leaves, Identity 1 caught by the Identity 6 check, Identity 2, 4 and 5 by the Identity 9 check); punch-card.tla + 23 twins (across steps and restarts: State 2, Invariant 2.1 through 2.3 and 3.1 through 3.3, Operation 1 and 5 through 19, Identity 3 caught by the Operation 6 and 7 checks, Identity 10 by the Operation 16 check); the vote yes of 2026-11-13, on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), and neither vetoed, 2026-11-13
last gate: 2026-11-21 — Final Critique 5, a delta round, one reader (Linus opencode/minimax-m3), frozen at 69152133 — foundational count 0 after the blind second triage, clean, one sample (Linus's three refining findings and two rhetorical, none foundational: that Operation 10 reads as an unconditional write beside Operation 9 at the goal, refuted by both triages, since Execution Contract Read 4 holds a rule about an action to the call it admits, Invariant 3.1 names the case, Operation 13 is no more conditional, and a condition would restate Read 4; that the card code names no type and that [Issue]'s table has no refusal rows for a duplicate or a non-string code, refuted or placed rhetorical, since [Issue] takes no input and the host's code is owned by Capability requirement 2, 3 and 9 and Logic confinement 3 and 16, and the Term is Gift Card's own; the two rhetorical, not-known twice and Operation 5's AND, left as written; nothing cured); 2026-11-14 — Final Critique 4, a delta round, one reader (Linus claude-haiku-5-5), frozen at c725410 — foundational count 0, clean, one sample, the blind second triage agreeing (it placed no item foundational; Linus's one foundational rating, Operation 10 at the goal, was placed not a finding, since Operation 9 and Invariant 3.1 own the Stamp at the goal and Execution Contract Read 4 holds a rule about an action to the call it admits; its one refining rating, Operation 16's non-string card id, was placed rhetorical Kind D, the clause worded as Operation 6 words it and as Final Critique 3 left it; nothing cured); 2026-11-13 — Final Critique 3, full, three fresh readers (GRID glm-5.3-flash, EOS minimax-m3, Linus mimo-v2.6-pro), frozen at b82922c — foundational count 0, clean, one sample, the blind second triage agreeing (it placed no item foundational; Linus's two foundational ratings were placed refining Kind D, [Read]'s non-string card id, whose answer Operation 16 already gave and which Operation 16 now states as Operation 6 does, and not a finding Kind C, a shred over Checks 4.1 and 4.2, which Execution Contract Database 5 and Database 6 own; the Summary's "next five" and the Read entry's missing card id cured, the rest settled by Gift Card precedent); 2026-11-13 — Final Critique 2, a delta round, one reader (Linus kimi-k3.1-pro), frozen at a3fb226 — foundational count 0, clean, one sample, the blind second triage agreeing (it placed no foundational item; it raised Capability requirement 5's citation of Execution Contract Input 2 as refining and the NOTE beside Term stamp goal as rhetorical, both worded as Gift Card's Capability requirement 6 and its NOTE are, so settled by that precedent, not cured); 2026-11-13 — Final Critique 1, full, three fresh readers (GRID glm-5.3-flash, EOS minimax-m3, Linus mimo-v2.6-pro), frozen at 331116c — foundational count 1, not clean (the stamp goal's read moment: two passes foundational, GRID refining; cured by citing Execution Contract Logic confinement 17 at Operation 2, the Stamp Goal entry and the Café example), 12 refining and 5 rhetorical reported (the two summary wordings cured, the rest settled by Gift Card precedent), one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./punch-card.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/punch-card.md`.

</details>

NOTE: End of Punch Card.

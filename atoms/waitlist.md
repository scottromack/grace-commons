---
title: Waitlist
id: 68
audience: common
parent: Atomic Concepts
has_toc: true
toc: true
---

# Waitlist

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Waitlist keeps people in line, first come, first served, for something with no room left: a full class, an earlier appointment, a sold-out item waiting on returns. A waitlist is started for one offering and holds one spot per person waiting; a person joins at the back and may leave, and when an opening comes up the person at the front is called and comes off the line. Each spot carries a join number the atom sets, one more than the waitlist's highest, so the order never rests on a clock and no one is called ahead of anyone who joined earlier. A closed waitlist takes no one new, and every spot still waiting on it ends. The waitlist decides nothing about how many openings an offering has, what is offered to the person called or for how long, how that person is told, or who may do what: each of those belongs to another pattern, which is why one waitlist can serve a class, a clinic and a shop alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Wherever demand outruns room, people line up: a class that has filled, a clinic with no earlier appointment, a product sold out until returns come back. The shape is constant — a line for one thing, people in the order they joined, the one at the front taken when an opening comes up, and anyone free to step out — and this atom is that and nothing more. It does not count openings, hold one for the person called, set how long an offer lasts, tell anyone they are up, or decide who may join or call; each belongs to a composing pattern, and declining them is what lets one waitlist serve a class, a clinic and a shop alike. Three decisions carry the weight. The order is a join number the atom sets, one more than the waitlist's highest, so two joins at one instant, or a clock that steps back, cannot reorder the line. A called spot comes off the line for good, so the line is only ever the people still waiting; a person whose offer falls through joins again at the back. And closing a waitlist ends every spot still waiting on it, so no one is left recorded as waiting on an offering that has started.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a waitlist by the waitlist id.
Identity 2: The atom MUST identify a spot by the spot id.
Identity 3: The atom MUST NOT reuse a waitlist id.
Identity 4: The atom MUST NOT reuse a spot id.
Identity 5: The atom MUST NOT identify a spot by the spot's person reference.
Identity 6: The atom MUST NOT normalize an offering reference.
Identity 7: The atom MUST compare two offering references codepoint for codepoint.
Identity 8: The atom MUST NOT normalize a person reference.
Identity 9: The atom MUST compare two person references codepoint for codepoint.
Identity 10: The deployment MUST draw a spot id from a cryptographically secure random source.
Identity 11: The deployment MUST NOT derive a spot id from the spot's other fields.
Identity 12: The deployment MUST record the offering reference exactly as written in the call.
Identity 13: The deployment MUST record the person reference exactly as written in the call.
```

Term string cap: the bound on an offering reference's or a person reference's length in Unicode code points; 1,024 code points where a deployment declares none.

Term waitlist: a line of spots for one offering, open to new spots or closed — a [Waitlist].

Term spot: one person's place on a waitlist, with the join number that orders the place and the place's state — a [Spot].

Term waitlist id: the opaque value naming one waitlist — a [Waitlist Id]; unique for the system's life.

Term spot id: the opaque value naming one spot — a [Spot Id]; unique for the system's life and drawn at random, so no one can guess another person's spot id, as [Capability](./capability.md) draws a token, though the id is no protection of the spot, which a caller's authority protects (Non-goal 9, Non-goal 10); a person who joins again gets a new spot id.

Term offering reference: the value naming what a waitlist is for — a class, an earlier appointment, a sold-out item in one size — in the deployment's own scheme — an [Offering Reference]; the atom reads nothing in it.

Term opening: room for one more on an offering — a seat, an appointment, a returned pair — which the atom never counts or holds (Non-goal 1, Non-goal 3).

Term person reference: the value naming the person a spot is for — a member, a patient, a shopper — in the deployment's own scheme — a [Person Reference]; the atom reads nothing in it.

NOTE: the offering reference and the person reference take the value exactly as written in the call (Identity 12, Identity 13), standing in place of Execution Contract Logic confinement 13 (Execution Contract Input 4; Identity 6 through 9).

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects each waitlist id, each spot id and the clock reading, now, at the seam.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it; the injected now is the reading the host hands the atom at the seam.

### State

```
State 1: EVERY waitlist MUST carry waitlist id, offering reference and waitlist state.
State 2: EVERY spot MUST carry spot id, waitlist id, person reference, join number, join instant and spot state.
State 3: EVERY waitlist MUST stand in EXACTLY ONE OF open, closed.
State 4: EVERY spot MUST stand in EXACTLY ONE OF waiting, called, left, unserved.
State 5: The atom MUST NOT remove a waitlist.
State 6: The atom MUST NOT remove a spot.
```

Term waitlist state: open | closed — whether a waitlist takes new spots — a [Waitlist State]; open from [Start], closed from [Close] on.

Term spot state: waiting | called | left | unserved — where a spot stands — a [Spot State]; waiting from [Join], then called by [Call Next], left by [Leave] or unserved by [Close], each final.

Term open waitlist: a waitlist standing in open.

Term closed waitlist: a waitlist standing in closed.

Term waiting spot: a spot standing in waiting.

Term ended spot: a spot standing in called, left or unserved.

Term join number: the place a spot took in the waitlist's order — a [Join Number]; a positive count, one more than the waitlist's highest join number when the spot joined.

Term highest join number: the greatest join number any spot of a waitlist carries, an ended spot's included; zero for a waitlist carrying no spot.

Term join instant: when a spot joined, stamped from the injected now — a [Join Instant]; a record of when, never the order.

Term positive count: a whole number, one or more.

Term front spot: the waiting spot of a waitlist carrying the lowest join number among the waitlist's waiting spots.

Term ahead count: the number of waiting spots of a spot's waitlist carrying a join number below the spot's join number — an [Ahead Count]; zero for the front spot, computed at each [Read Spot] and never stored.

NOTE: watch a term entry's kind — the ahead count is computed at each read and never stored, yet its term entry takes `Kind: Field`, as a stored field's does.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply at the seam, for each [Start] call, a waitlist id no waitlist has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
Capability requirement 2: The deployment MUST supply at the seam, for each [Join] call, a spot id no spot has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
Capability requirement 3: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Order 1, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
Capability requirement 5: The deployment MAY declare the string cap PER Execution Contract Input 2.
```

### Operations

```
start(offering_reference)
  answers waitlist_id
  refuses invalid-offering-reference | storage-failure

join(waitlist_id, person_reference)
  answers spot_id
  refuses not-known | invalid-person-reference | waitlist-closed | already-waiting | storage-failure

leave(spot_id)
  answers ok
  refuses not-known | not-waiting | storage-failure

call_next(waitlist_id)
  answers spot(spot_id, person_reference)
  refuses not-known | waitlist-closed | nobody-waiting | storage-failure

close(waitlist_id)
  answers ok
  refuses not-known | waitlist-closed | storage-failure

read_spot(spot_id)
  answers spot
  refuses not-known

read_waitlist(waitlist_id)
  answers waitlist
  refuses not-known
```

```
Operation 1: IF the offering reference EQUALS blank OR the offering reference EXCEEDS the string cap THEN [Start] MUST answer invalid-offering-reference.
Operation 2: IF an open waitlist EXISTS for the offering reference THEN [Start] MUST answer the open waitlist's waitlist id.
Operation 3: IF an open waitlist EXISTS for the offering reference THEN [Start] MUST NOT write.
Operation 4: IF no open waitlist EXISTS for the offering reference THEN [Start] MUST record EXACTLY ONE waitlist carrying the waitlist id the seam supplies and the offering reference of the call.
Operation 5: IF no open waitlist EXISTS for the offering reference THEN [Start] MUST stand the recorded waitlist in open.
Operation 6: IF no open waitlist EXISTS for the offering reference THEN [Start] MUST answer the recorded waitlist's waitlist id.
Operation 7: IF no waitlist EXISTS for the waitlist id THEN a waitlist action MUST answer not-known.
Operation 8: IF the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Join] MUST answer invalid-person-reference.
Operation 9: IF the waitlist state EQUALS closed THEN [Join] MUST answer waitlist-closed.
Operation 10: IF a waiting spot of the waitlist EXISTS for the person reference THEN [Join] MUST answer already-waiting.
Operation 11: [Join] MUST record EXACTLY ONE spot carrying the spot id the seam supplies and the waitlist id and person reference of the call.
Operation 12: [Join] MUST set the spot's join number to the waitlist's next join number.
Operation 13: [Join] MUST stamp join instant from the injected now.
Operation 14: [Join] MUST stand the spot in waiting.
Operation 15: [Join] MUST answer the spot id.
Operation 16: IF no spot EXISTS for the spot id THEN a spot action MUST answer not-known.
Operation 17: IF a spot EXISTS for the spot id AND the spot state DOES NOT EQUAL waiting THEN [Leave] MUST answer not-waiting.
Operation 18: [Leave] MUST stand the spot in left.
Operation 19: [Leave] MUST answer ok.
Operation 20: IF the waitlist state EQUALS closed THEN [Call Next] MUST answer waitlist-closed.
Operation 21: IF no waiting spot of the waitlist EXISTS THEN [Call Next] MUST answer nobody-waiting.
Operation 22: [Call Next] MUST stand the front spot in called.
Operation 23: [Call Next] MUST answer the front spot's spot id AND person reference.
Operation 24: [Call Next] MUST NOT change a spot other than the front spot.
Operation 25: IF the waitlist state EQUALS closed THEN [Close] MUST answer waitlist-closed.
Operation 26: [Close] MUST stand the waitlist in closed.
Operation 27: [Close] MUST stand EVERY waiting spot of the waitlist in unserved.
Operation 28: [Close] MUST answer ok.
Operation 29: [Read Spot] MUST answer the spot's spot id, waitlist id, person reference, join number, join instant AND spot state.
Operation 30: IF the spot state EQUALS waiting THEN [Read Spot] MUST answer the spot's ahead count.
Operation 31: [Read Spot] MUST NOT write.
Operation 32: [Read Waitlist] MUST answer the waitlist's waitlist id, offering reference AND waitlist state.
Operation 33: [Read Waitlist] MUST answer EVERY waiting spot of the waitlist, lowest join number first.
Operation 34: [Read Waitlist] MUST answer a waiting spot's spot id, person reference, join number AND join instant.
Operation 35: [Read Waitlist] MUST NOT write.
Operation 36: [Read Waitlist] MUST NOT answer a spot that is not waiting.
```

Term next join number: (highest join number + 1) for a waitlist — the join number [Join] sets on the waitlist's next spot; one for a waitlist carrying no spot.

Term waitlist action: [Join] | [Call Next] | [Close] | [Read Waitlist] — the actions that name a waitlist by the waitlist id.

Term spot action: [Leave] | [Read Spot] — the actions that name a spot by the spot id.

NOTE: the waiting spots a [Read Waitlist] answers come lowest join number first (Operation 33), the one order the atom keeps; an ended spot is read by [Read Spot].

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the waitlists |
|---|---|---|---|
| [Start] | reference valid, no open waitlist for it, database accepts | the waitlist id | one waitlist lands, open, carrying the offering reference and no spot (Operation 4, Operation 5) |
| [Start] | an open waitlist already stands for the reference | the open waitlist's id | none — no write (Operation 2, Operation 3) |
| [Start] | offering reference blank or over the string cap | [Invalid Offering Reference] | none (Operation 1) |
| [Join] | inputs valid, waitlist open, person not already waiting, database accepts | the spot id | one spot lands at the back, waiting, carrying the waitlist's next join number and a join instant of now (Operation 11 through 14) |
| [Join] | person reference blank or over the string cap | [Invalid Person Reference] | none (Operation 8) |
| [Join] | waitlist closed | [Waitlist Closed] | none (Operation 9) |
| [Join] | the person already holds a waiting spot on the waitlist | [Already Waiting] | none (Operation 10) |
| [Leave] | the spot is waiting | ok | the spot stands in left (Operation 18) |
| [Leave] | the spot is called, left or unserved | [Not Waiting] | none (Operation 17) |
| [Call Next] | waitlist open, someone waiting | the front spot's spot id and person reference | the front spot stands in called; no other spot changes (Operation 22 through 24) |
| [Call Next] | waitlist open, nobody waiting | [Nobody Waiting] | none (Operation 21) |
| [Call Next] | waitlist closed | [Waitlist Closed] | none (Operation 20) |
| [Close] | waitlist open | ok | the waitlist stands in closed and every waiting spot stands in unserved (Operation 26, Operation 27) |
| [Close] | waitlist already closed | [Waitlist Closed] | none (Operation 25) |
| a waitlist action or a spot action | the id names nothing | [Not Known] | none (Operation 7, Operation 16) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| [Read Spot] | the spot exists | the spot's fields, with the ahead count where the spot is waiting | none (Operation 29 through 31) |
| [Read Waitlist] | the waitlist exists | the waitlist's fields and its waiting spots, lowest join number first | none (Operation 32 through 36) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — First come, first served.**
  ```
  Invariant 1.1: Two spots of one waitlist MUST NOT share a join number.
  Invariant 1.2: The atom MUST NOT call a spot other than the front spot of the spot's waitlist.
  Invariant 1.3: The atom MUST NOT change a spot's join number.
  ```
- **Invariant 2 — One waiting spot per person.**
  ```
  Invariant 2.1: Two waiting spots of one waitlist MUST NOT share a person reference.
  ```
- **Invariant 3 — A spot keeps its waitlist, its person and its join instant.**
  ```
  Invariant 3.1: The atom MUST NOT change a spot's waitlist id.
  Invariant 3.2: The atom MUST NOT change a spot's person reference.
  Invariant 3.3: The atom MUST NOT change a spot's join instant.
  ```
- **Invariant 4 — An ended spot stays ended.**
  ```
  Invariant 4.1: The atom MUST NOT change the spot state of an ended spot.
  ```
- **Invariant 5 — A closed waitlist stays closed, with no one waiting on it.**
  ```
  Invariant 5.1: The atom MUST NOT change the waitlist state of a closed waitlist.
  Invariant 5.2: A closed waitlist MUST NOT carry a waiting spot.
  ```
- **Invariant 6 — One open waitlist per offering.**
  ```
  Invariant 6.1: Two open waitlists MUST NOT share an offering reference.
  ```
- **Invariant 7 — A waitlist keeps its offering.**
  ```
  Invariant 7.1: The atom MUST NOT change a waitlist's offering reference.
  ```
- **Invariant 8 — Every spot belongs to a waitlist.**
  ```
  Invariant 8.1: EVERY spot's waitlist id MUST name a waitlist.
  ```
- **Invariant 9 — Join numbers stay whole.**
  ```
  Invariant 9.1: EVERY spot MUST carry a positive count as the spot's join number.
  ```

## Examples

The same pattern in three domains, then the rejection paths. A spot id is drawn at random; the short ones below stand in for real ones.

### Pottery class

A community center's Tuesday pottery class has twelve seats, all taken, so the center starts a waitlist for the class — `start("pottery-tue")` answers [Waitlist Id] `w1`. Ana joins — `join(w1, "ana")` answers [Spot Id] `s-9fQ2`, with [Join Number] 1 — then Ben — `join(w1, "ben")` answers `s-T4mx`, join number 2 — then Cara — `join(w1, "cara")` answers `s-Lw0c`, join number 3. Cara checks her place — `read_spot(s-Lw0c)` answers waiting, with an [Ahead Count] of 2. Ben finds a seat in another class and leaves — `leave(s-T4mx)` — and Cara's ahead count drops to 1. A student drops the class, and the center calls the next person — `call_next(w1)` answers `s-9fQ2` and `"ana"`; Ana's spot stands in called, and the center offers her the seat for a day. The day runs out without an answer, but Ana still wants in, so she joins again — `join(w1, "ana")` answers `s-Pz7k`, join number 4, behind Cara: `read_waitlist(w1)` answers Cara, then Ana. The class starts, and the center closes the waitlist — `close(w1)`: Cara's and Ana's spots stand in unserved.

### Clinic cancellation list

A physiotherapy clinic keeps a list of patients who want an earlier appointment with one therapist — `start("physio-rao-earlier")` answers `w5`. Three patients join in one morning: `"p-2231"` with join number 1, `"p-0418"` with 2 and `"p-7760"` with 3. Two appointments are cancelled at once, and two receptionists each call the next patient — the two `call_next(w5)` calls are serialized: the first answers the spot of `"p-2231"` and the second the spot of `"p-0418"`, so no patient is called twice and none is passed over. Patient `"p-7760"` books with another clinic and leaves. At the end of the season the clinic closes the list — `close(w5)` — with no spot left waiting.

### Sold-out trainers

A shop's limited trainers sell out, and returns come back one pair at a time, so the shop keeps one waitlist per size — `start("runner-x-42")` answers `w8` and `start("runner-x-43")` answers `w9`, since a returned pair in one size is no opening for someone waiting on another. Sam joins the size-42 list — `join(w8, "sam")` answers join number 1. The shop's system restarts and starts the size-42 list again — `start("runner-x-42")` answers `w8` once more and writes nothing, since one open waitlist stands per offering, and Sam keeps the spot. A size-43 pair comes back with no one on `w9` — `call_next(w9)` is refused as [Nobody Waiting], and the shop puts the pair back on sale.

### Rejection paths

A deployment exercising the rejection surface in one short sequence on waitlist `w12`, started for `"yoga-sat"`:

- `start("   ")` — rejected as [Invalid Offering Reference]: the reference is blank.
- `start("yoga-sat")` — answers `w12` again and writes nothing: an open waitlist already stands for the offering.
- `join(w12, "")` — rejected as [Invalid Person Reference].
- `join(w12, "mo")` — accepted, spot `s-Aq31`, join number 1. A second `join(w12, "mo")` is rejected as [Already Waiting].
- `join(w12, "Mo")` — accepted as a different person, spot `s-hR8e`, join number 2: two person references are compared codepoint for codepoint.
- `leave(s-Aq31)` — ok. A second `leave(s-Aq31)` is rejected as [Not Waiting].
- `call_next(w12)` — answers `s-hR8e`. A second `call_next(w12)` is rejected as [Nobody Waiting].
- `join(w404, "mo")`, where no waitlist `w404` exists — rejected as [Not Known]; so is `leave(s-0000)`, where no spot `s-0000` exists.
- `close(w12)` — ok. Then `join(w12, "mo")`, `call_next(w12)` and `close(w12)` are each rejected as [Waitlist Closed].
- `join(w12, "")` on the closed waitlist — rejected as [Invalid Person Reference]: two refusals apply, and the one listed first on [Join]'s refuses line answers (Execution Contract Refusal 1).

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the waitlists and spots the database holds, with their earlier versions (Execution Contract Database 5). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY waitlist carrying waitlist id, offering reference AND waitlist state (State 1).
Check 1.2: An auditor MUST find EVERY spot carrying spot id, waitlist id, person reference, join number, join instant AND spot state (State 2).
Check 2.1: An auditor MUST find no two waitlists sharing a waitlist id (Identity 3).
Check 2.2: An auditor MUST find no two spots sharing a spot id (Identity 4).
Check 2.3: An auditor MUST find no two spots of one waitlist sharing a join number (Invariant 1.1).
Check 2.4: An auditor MUST find no commit as of which two waiting spots of one waitlist share a person reference (Invariant 2.1).
Check 2.5: An auditor MUST find no commit as of which two open waitlists share an offering reference (Invariant 6.1).
Check 2.6: An auditor MUST find EVERY spot's waitlist id naming a waitlist (Invariant 8.1).
Check 2.7: An auditor MUST find no commit as of which a closed waitlist carries a waiting spot (Invariant 5.2).
Check 3.1: An auditor MUST find no commit as of which a waiting spot carries a join number below the join number of a spot of the same waitlist standing in called (Invariant 1.2).
Check 3.2: An auditor MUST find EVERY version of a spot carrying the join number of the spot's first version (Invariant 1.3).
Check 3.3: An auditor MUST find EVERY version of a spot carrying the waitlist id of the spot's first version (Invariant 3.1).
Check 3.4: An auditor MUST find EVERY version of a spot carrying the person reference of the spot's first version (Invariant 3.2).
Check 3.5: An auditor MUST find EVERY version of a spot carrying the join instant of the spot's first version (Invariant 3.3).
Check 3.6: An auditor MUST find EVERY version of a spot later than the spot's first ended version carrying the spot state of the first ended version (Invariant 4.1).
Check 3.7: An auditor MUST find EVERY version of a waitlist later than the waitlist's first closed version standing in closed (Invariant 5.1).
Check 3.8: An auditor MUST find EVERY version of a waitlist carrying the offering reference of the waitlist's first version (Invariant 7.1).
Check 4.1: An auditor MUST find EVERY spot carrying a positive count as the spot's join number (Invariant 9.1).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes.

Term first ended version: the earliest version of a spot standing in called, left or unserved.

Term first closed version: the earliest version of a waitlist standing in closed.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a called person confirmed as offered an opening MUST read the records of the pattern that held the opening (Non-goal 1).
External check 2: An auditor needing an action attributed to an actor MUST read the records of the pattern that attributes actions (Non-goal 11).
External check 3: An auditor needing a person reference confirmed as naming a real person MUST read the deployment's records of people (Non-goal 17).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT hold an opening for a called person.
Non-goal 2: A deployment needing an opening held for a called person MUST compose Provisional Commitment.
Non-goal 3: The atom MUST NOT count the openings an offering has.
Non-goal 4: The atom MUST NOT limit how many spots a waitlist carries.
Non-goal 5: A deployment needing a bound on spots MUST compose Capacity Constraint Enforcement.
Non-goal 6: The atom MUST NOT decide when to call a spot.
Non-goal 7: The atom MUST NOT notify a called person.
Non-goal 8: A deployment needing notice to a called person MUST compose Notification.
Non-goal 9: The atom MUST NOT gate an action on a caller's authority.
Non-goal 10: A deployment needing authorization MUST compose Permissions.
Non-goal 11: The atom MUST NOT attribute an action to an actor.
Non-goal 12: A deployment needing attribution MUST compose Event Log.
Non-goal 13: The atom MUST NOT distinguish a retried call from a new call.
Non-goal 14: A deployment needing a retried call answered once MUST compose Duplicate Prevention.
Non-goal 15: The atom MUST NOT give a spot priority.
Non-goal 16: The atom MUST NOT hold a party size.
Non-goal 17: The atom MUST NOT check a person reference against the deployment's records of people.
Non-goal 18: The atom MUST NOT check an offering reference against a catalog.
Non-goal 19: The atom MUST NOT expire a spot.
Non-goal 20: A deployment needing a spot with a bounded lifetime MUST compose Lease.
Non-goal 21: The atom MUST NOT move a spot between two waitlists.
Non-goal 22: The atom MUST NOT bound how long a spot is kept.
Non-goal 23: A deployment needing a retention bound MUST compose Retention Window.
Non-goal 24: A deployment needing openings counted MUST compose Capacity Constraint Enforcement.
```

NOTE: the owners — [Provisional Commitment](./provisional-commitment.md) (Non-goal 1, 2; External check 1); [Capacity Constraint Enforcement](./capacity-constraint-enforcement.md) (Non-goal 3, 4, 5, 24); Offer from Waitlist *(forthcoming)*, which offers each opening to a waitlist's front spot (Non-goal 6); [Notification](./notification.md) (Non-goal 7, 8); [Permissions](./permissions.md) (Non-goal 9, 10); [Event Log](./event-log.md) (Non-goal 11, 12; External check 2); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 13, 14); Priority Waitlist *(forthcoming)* (Non-goal 15); Group Booking *(forthcoming)* (Non-goal 16); the composing pattern that knows the person, such as one built on [Session](./session.md) or [Party Identity](./party-identity.md) (Non-goal 17; External check 3); Catalog *(forthcoming)* (Non-goal 18); [Lease](./lease.md) (Non-goal 19, 20); the composing pattern that moves a person, by [Leave] on one waitlist and [Join] on the other (Non-goal 21); [Retention Window](./retention-window.md) (Non-goal 22, 23).

Where the atom breaks down: a line ordered by anything but arrival, such as need or membership; a place that stands for several people who must be seated together.

## Edge cases

### Concurrency

Two calls on one waitlist are serialized (Execution Contract Database 2). Two [Call Next] calls at one moment: the later reads the spot the earlier called and calls the next waiting spot, so no spot is called twice and none is passed over (Invariant 1.2, Invariant 4.1). Two [Start] calls for one offering: the later reads the waitlist the earlier recorded and answers its waitlist id (Execution Contract Database 2; Operation 2, Invariant 6.1). Two [Join] calls for one person: the later reads the spot the earlier recorded and answers [Already Waiting] (Execution Contract Database 2; Operation 10, Invariant 2.1). A [Leave] racing a [Call Next] for the front spot: whichever lands first decides — a [Leave] that lands first leaves the spot, and the [Call Next] calls the front spot then standing (Operation 22); a [Call Next] that lands first calls the spot, and the [Leave] answers [Not Waiting]. A [Join] racing a [Close]: a [Join] that lands first records a waiting spot, which the [Close] then stands in unserved; a [Close] that lands first leaves the [Join] answering [Waitlist Closed] (Invariant 5.2).

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). Where no other call changed the waitlist in between, a repeated [Start] answers the same waitlist id, since the first left an open waitlist for the offering (Operation 2); a repeated [Join] answers [Already Waiting] where the first landed, and [Read Waitlist] then shows the spot and its [Spot Id]; a repeated [Leave] answers [Not Waiting] where the first landed; a repeated [Close] answers [Waitlist Closed] where the first landed. A repeated [Call Next] is the one to watch: where the first landed, the repeat calls the next waiting spot as well, so a deployment that retries [Call Next] composes Duplicate Prevention (Non-goal 13, 14). Where another call did change the waitlist, the repeat is decided afresh on what that call left (Execution Contract Database 2).

### A called person whose offer falls through

[Call Next] ends the spot (Operation 22), and an ended spot stays ended (Invariant 4.1): the atom never puts a called person back in line. A person who turns an offer down, or lets one run out, joins again at the back with [Join]: a new spot, a new [Spot Id] and the next join number. A composing pattern that holds an opening for the person it calls does both in one transaction (Composition note 2), so no one comes off the line without an opening held for them.

### What undoes a write

[Close] undoes [Start], standing the waitlist in closed, which takes no new spot (Operation 26); [Leave] undoes [Join], standing the spot in left (Operation 18). [Leave], [Call Next] and [Close] are final (Invariant 4.1, Invariant 5.1), so no undo is owed beyond them: a person who left or was called joins again at the back (Operation 11, Operation 12), and a waitlist closed by mistake is started again as a new waitlist (Operation 4) (Execution Contract Undo 4).

## Composition notes

```
Composition note 1: A composing pattern MUST own what the atom declines.
Composition note 2: A composing pattern holding an opening for a called person MUST hold the opening in the one transaction that writes the [Call Next] call's effects (Execution Contract Database 1).
```

NOTE: composing patterns — none yet. Forthcoming: Offer from Waitlist, which offers each opening to a waitlist's front spot through Provisional Commitment.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); a composing pattern; the database; a caller; a waitlist; a spot; a waitlist action; a spot action; an auditor.

Term records: waitlist — a line of spots for one offering, carrying waitlist id, offering reference and waitlist state; spot — one person's place on a waitlist, carrying spot id, waitlist id, person reference, join number, join instant and spot state.

Term record verbs: identify, reuse, normalize, compare, draw, derive, carry, stand, remove, supply, declare, answer, record, write, set, stamp, change, share, call, name, find, read, hold, count, limit, compose, decide, notify, gate, attribute, distinguish, give, check, expire, move, bound, own.

Term value sets: waitlist state = open | closed; spot state = waiting | called | left | unserved; waitlist action and spot action are declared above and cited here (GRACE-lang Closed vocabulary 15).

Term bounds: positive count (one, the floor of a join number); string cap (the bound on an offering reference's or a person reference's length in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang unknown (2026-11-17) through the Grace connector.

Term terms: waitlist, spot, waitlist id, spot id, offering reference, opening, person reference, seam, now, string cap, waitlist state, spot state, open waitlist, closed waitlist, waiting spot, ended spot, join number, highest join number, next join number, join instant, positive count, front spot, ahead count, waitlist action, spot action, version, first ended version, first closed version.

#### Start

Starts a waitlist for an offering: where no open waitlist stands for the [Offering Reference], records a [Waitlist] carrying the new [Waitlist Id] and the reference, open and with no spot, and answers the new id; where one stands, answers the open waitlist's id and writes nothing.

Kind: Operation

#### Join

Puts a person at the back of a waitlist: records one [Spot] carrying the new [Spot Id], the call's [Waitlist Id] and [Person Reference], the next [Join Number] and the [Join Instant], waiting, and answers the new [Spot Id]. A closed waitlist, or a person already waiting on the waitlist, is refused (Operation 9, Operation 10).

Kind: Operation

#### Leave

Takes a waiting [Spot] off its waitlist: the spot stands in left, and every spot behind has one fewer waiting spot ahead.

Kind: Operation

#### Call Next

Calls the front spot of a waitlist: the waiting [Spot] with the lowest [Join Number] stands in called, and its [Spot Id] and [Person Reference] are answered; no other spot changes.

Kind: Operation

#### Close

Closes a waitlist: the [Waitlist] stands in closed and takes no new spot, and every spot still waiting on it stands in unserved.

Kind: Operation

#### Read Spot

Answers a spot and changes nothing: its [Spot Id], [Waitlist Id], [Person Reference], [Join Number], [Join Instant] and [Spot State], and, for a waiting spot, its [Ahead Count].

Kind: Operation

#### Read Waitlist

Answers a waitlist and changes nothing: its [Waitlist Id], [Offering Reference] and [Waitlist State], and every waiting spot on it, lowest [Join Number] first, with each spot's [Spot Id], [Person Reference], [Join Number] and [Join Instant].

Kind: Operation

#### Waitlist

A line of spots for one offering, open to new spots or closed; started by [Start], closed by [Close], never removed by the atom.

Kind: Type

#### Spot

One person's place on a waitlist: the [Person Reference], the [Join Number] that orders the place, the [Join Instant] and the [Spot State]; recorded by [Join], ended by [Call Next], [Leave] or [Close], never removed by the atom.

Kind: Type

#### Waitlist Id

The opaque, immutable identity of a waitlist, allocated by the host at the seam on [Start], never reused.

Kind:       Field
Field of:   Waitlist
Projection: waitlist_id

#### Spot Id

The opaque, immutable identity of a spot, allocated by the host at the seam on [Join] from a cryptographically secure random source, never reused; a person who joins again gets a new one.

Kind:       Field
Field of:   Spot
Projection: spot_id

#### Offering Reference

Names what a waitlist is for — a class, an earlier appointment, a sold-out item in one size — in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; the atom reads nothing in it, and whether it names a real offering is a catalog's question.

Kind:       Field
Field of:   Waitlist
Projection: offering_reference

#### Person Reference

Names the person a spot is for — a member, a patient, a shopper — in the deployment's own scheme. Stored as supplied and compared codepoint for codepoint; the atom reads nothing in it, and whether it names a real person is the deployment's question.

Kind:       Field
Field of:   Spot
Projection: person_reference

#### Join Number

The place a spot took in its waitlist's order: one more than the waitlist's highest join number when the spot joined, a whole number of one or more, never changed. The waiting spot with the lowest join number is the front of the line.

Kind:       Field
Field of:   Spot
Projection: join_number

#### Join Instant

When a spot joined, stamped from the injected now at [Join] and never changed; a record of when, never the order, which the [Join Number] alone sets.

Kind:       Field
Field of:   Spot
Projection: join_instant

#### Waitlist State

Whether a waitlist takes new spots: open from [Start], closed from [Close] on, and never open again.

Kind:       Field
Field of:   Waitlist
Projection: state

#### Spot State

Where a spot stands: waiting from [Join], then called by [Call Next], left by [Leave] or unserved by [Close], each final.

Kind:       Field
Field of:   Spot
Projection: state

#### Ahead Count

How many waiting spots of a spot's waitlist carry a lower [Join Number]: zero for the front spot; computed at each [Read Spot] of a waiting spot, never stored.

Kind:       Field
Field of:   Spot
Projection: ahead_count

#### Invalid Offering Reference

[Start]'s refusal of a blank [Offering Reference], or one over the string cap (Operation 1).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-offering-reference

#### Not Known

The refusal of a [Waitlist Id] naming no waitlist, on [Join], [Call Next], [Close] or [Read Waitlist], or of a [Spot Id] naming no spot, on [Leave] or [Read Spot].

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Invalid Person Reference

[Join]'s refusal of a blank [Person Reference], or one over the string cap (Operation 8).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Waitlist Closed

The refusal of [Join], [Call Next] or [Close] on a waitlist standing in closed.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: waitlist-closed

#### Already Waiting

[Join]'s refusal of a [Person Reference] already holding a waiting spot on the waitlist; the person keeps the spot already held.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-waiting

#### Not Waiting

[Leave]'s refusal of a spot standing in called, left or unserved.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-waiting

#### Nobody Waiting

[Call Next]'s refusal on an open waitlist with no waiting spot.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: nobody-waiting

#### Storage Failure

The refusal [Start], [Join], [Leave], [Call Next] or [Close] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Start]: #start
[Join]: #join
[Leave]: #leave
[Call Next]: #call-next
[Close]: #close
[Read Spot]: #read-spot
[Read Waitlist]: #read-waitlist
[Waitlist]: #waitlist
[Spot]: #spot
[Waitlist Id]: #waitlist-id
[Spot Id]: #spot-id
[Offering Reference]: #offering-reference
[Person Reference]: #person-reference
[Join Number]: #join-number
[Join Instant]: #join-instant
[Waitlist State]: #waitlist-state
[Spot State]: #spot-state
[Ahead Count]: #ahead-count
[Invalid Offering Reference]: #invalid-offering-reference
[Not Known]: #not-known
[Invalid Person Reference]: #invalid-person-reference
[Waitlist Closed]: #waitlist-closed
[Already Waiting]: #already-waiting
[Not Waiting]: #not-waiting
[Nobody Waiting]: #nobody-waiting
[Storage Failure]: #storage-failure

---

## Standards references

Waitlist is a primitive with no regulatory anchor of its own. It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design, leaving openings, offers and notice to concepts of their own.
- **First come, first served** — the queue discipline a waitlist keeps: the earliest arrival still waiting is served next.

Any rule a school, a clinic or a shop must follow in running a waitlist binds the composing pattern or the deployment, not the waitlist.

---

## Status

`done — 2026-11-17` — see the Ledger.

## Ledger

```
status: done — 2026-11-17
formal: verified — waitlist.als + 18 twins (the static data model: State 1 through 4, Identity 3 and 4, Operation 4, 5 and 11 through 14, Invariant 1.1, 1.2, 2.1, 5.2, 6.1, 8.1 and 9.1 checked on every version a sequence of admitted calls leaves, Identity 1, 2 and 5 caught by the Identity 3 and 4 checks, Identity 6, 8, 12 and 13 by the Operation 4 and 11 checks); waitlist.tla + 40 twins (across steps: State 5 and 6, Invariant 1.2, 1.3, 3.1 through 3.3, 4.1, 5.1 and 7.1, Operation 1 through 4, 6 through 12 and 15 through 36, Identity 7 and 9 read through Operation 2, 4, 10 and 11); on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), neither vetoed; Identity 10 and 11 (the deployment's random draw) cannot be stated, 2026-11-19
last gate: 2026-11-17 — Final Critique 2, delta, frozen at 8d7d3b9 — foundational count 0, clean, one sample; 2026-11-17 — Final Critique 1, full, frozen at e7a3151 — foundational count 5, cured, not clean, no sample

open: none
```

## Decisions

Decisions are kept in [the pattern's history](./waitlist.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/waitlist.md`.

NOTE: End of Waitlist.

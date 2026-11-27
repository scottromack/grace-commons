---
title: Tenure
id: 67
audience: common
---

# Tenure

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Tenure records who holds which role in what, and since when: a person, a role such as buyer, billing contact or account manager, the thing the role is held in — a customer, a deal, a club — a start date, and an end date once the tenure ends. Several people can share a role, and one person can hold several. On any day a tenure is upcoming, held or ended, worked out from the tenure's dates, so a departure learned late is entered with the day it happened. The end date is the first day the role is not held, so a handover uses one date for both people. A role or a date entered wrong can be changed, and the earlier version stays on file; a tenure entered by mistake is withdrawn: left out of every history, still readable, and withdrawn for good. The business makes two choices: the roles it offers, and which roles have one holder at a time, such as account manager. Who the people are, what the things are, what a role lets someone do, who is responsible for a piece of work, and acting when a date arrives each belong to another pattern — another separately specified building block of the same kind — which is why one tenure serves a customer's contacts, a team's roles and a club's officers alike.

<details markdown="block">
<summary>WHY</summary>

Wherever people take parts in something that lasts — a customer's buyer, a team's lead, a club's treasurer — whoever deals with the thing needs to know who holds which part now, and who did before. This atom is that record and nothing more. Three decisions carry the weight. A tenure carries the dates the role was held, not the dates anyone typed them, so a departure learned late lands on the day it happened, and a read for any day answers who held what that day. The end date is the first day the role is not held, so one date ends one tenure and begins the next with no gap and no overlap. And a tenure entered by mistake is withdrawn, never removed, so fixing a mistake never erases evidence. What a role permits, who the people are and what happens when a date arrives are other patterns' questions, and declining them is what lets one tenure serve any business that keeps track of who plays which part.

</details>

## What it keeps

### The tenures

```
Identity 1: The atom MUST identify a tenure by the tenure's tenure id.
Identity 2: The host MUST allocate a tenure id at the atom's seam.
Identity 3: [Begin] MUST NOT take a tenure id from the business caller.
Identity 4: The atom MUST NOT reuse a tenure id.
Identity 5: The implementation MUST own the tenure id's scheme.
Identity 6: The atom MUST NOT normalize a person reference.
Identity 7: The atom MUST compare two person references codepoint for codepoint.
Identity 8: The atom MUST NOT normalize an item reference.
Identity 9: The atom MUST compare two item references codepoint for codepoint.
Identity 10: The atom MUST NOT normalize a role.
Identity 11: The atom MUST compare two roles codepoint for codepoint.
Identity 12: The atom MUST compare two tenure ids codepoint for codepoint.
```

Term tenure: one person's time in one role in one thing, kept from the [Begin] call that recorded the tenure — a [Tenure].

Term tenure id: the id the host allocates at the seam for each tenure — the [Tenure Id]; never reused.

NOTE: Capability requirement 4 through 6 are the atom's own rule for the canonical form of each reference and of a role, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each is recorded as the call carries it (Execution Contract Input 4; Identity 6 through 11).

```
State 1: EVERY tenure MUST carry tenure id, person reference, role, item reference and start date.
State 2: A tenure MAY carry end date and withdrawn instant.
State 3: The atom MUST NOT remove a tenure.
```

Term date: a calendar date of the Gregorian calendar of ISO 8601, run back before 1582 as if always in force, written `YYYY-MM-DD` with a four-digit year, a two-digit month and a two-digit day, naming a day the calendar holds and carrying no time of day; a value not written so, or naming no day the calendar holds, such as `2026-02-30`, is malformed (Execution Contract Input 1); a blank value is no date and is not malformed; what a date means in a place is a time-zone pattern's.

Term start date: the first of the tenure's days — the [Start Date].

Term end date: the first day after the tenure's days — the [End Date]; a tenure carrying none is open.

Term withdrawn instant: the instant of the [Withdraw] call that withdrew a tenure, stamped from the injected now — the [Withdrawn Instant]; set once.

Term withdrawn tenure: a tenure carrying a withdrawn instant; withdrawn is final.

Term days: the days of a tenure are every date from the start date up to the day preceding the end date, and every date from the start date on where the tenure carries no end date.

Term held: a tenure is held on a date where the date lies in the days of the tenure.

Term upcoming: a tenure is upcoming on a date preceding the start date of the tenure.

Term ended: a tenure is ended on the end date of the tenure and on every later date.

#### Tenure

One person's time in one role in one thing: recorded by [Begin], ended by [End], corrected by [Change], withdrawn by [Withdraw].

Kind: Type

#### Tenure Id

Names one tenure; allocated by the host at the seam.

Kind:       Field
Field of:   Tenure
Projection: tenure_id

#### Person Reference

Names the person who holds the role, in the deployment's own scheme; whether the reference names a real person is a directory's question.

Kind:       Field
Field of:   Tenure
Projection: person_reference

#### Role

The part the person plays in the thing, one of the role set the deployment offered at the call that set the role, such as buyer.

Kind:       Field
Field of:   Tenure
Projection: role

#### Item Reference

Names the thing the role is held in, in the deployment's own scheme, such as a customer or a club; whether the reference names a real item is a catalog's question.

Kind:       Field
Field of:   Tenure
Projection: item_reference

#### Start Date

The first day the person holds the role; a date with no time of day.

Kind:       Field
Field of:   Tenure
Projection: start_date

#### End Date

The first day the person no longer holds the role; absent while the tenure is open.

Kind:       Field
Field of:   Tenure
Projection: end_date

#### Withdrawn Instant

The instant of the [Withdraw] call that withdrew the tenure, stamped from the injected now; absent on a tenure never withdrawn.

Kind:       Field
Field of:   Tenure
Projection: withdrawn_instant

Term person reference: the string naming the person who holds the role, in the deployment's own scheme — the [Person Reference]; the atom reads no scheme in it.

Term role: the part a person plays in the thing, such as buyer, billing-contact or account-manager, one of the role set — the [Role].

Term item reference: the string naming the thing the role is held in, such as a customer, a deal or a club, in the deployment's own scheme — the [Item Reference]; the atom reads no scheme in it.

## What people do

### Every action

```
Operation 5: IF the role of the proposed tenure EQUALS blank OR the role of the proposed tenure EXCEEDS the string cap THEN a placing action MUST answer invalid-role.
Operation 6: IF the call carries a role AND the role of the call IS NOT IN the role set THEN a placing action MUST answer invalid-role.
Operation 7: IF the role of the call is malformed THEN a placing action MUST answer invalid-role (Execution Contract Input 1).
Operation 8: IF the start date of the call is malformed THEN a placing action MUST answer invalid-start-date (Execution Contract Input 1).
Operation 9: IF the end date of the call is malformed THEN a dating action MUST answer invalid-end-date (Execution Contract Input 1).
Operation 10: IF the end date of the proposed tenure EQUALS the start date of the proposed tenure THEN a dating action MUST answer end-too-early.
Operation 11: IF the end date of the proposed tenure PRECEDES the start date of the proposed tenure THEN a dating action MUST answer end-too-early.
Operation 12: IF an overlapping twin EXISTS THEN a placing action MUST answer already-held.
Operation 13: IF the role of the proposed tenure IS IN the one-holder set AND an overlapping rival EXISTS THEN a placing action MUST answer role-taken.
Operation 14: IF the tenure id of the call is malformed OR no tenure carries the tenure id of the call THEN a keyed action MUST answer not-known.
```

Term detail: a role, a start date or an end date — what a [Change] call may carry; a detail the call leaves blank is a detail the call omits.

Term placing action: [Begin] | [Change] — every [Begin] call and every [Change] call, each checked against the other tenures.

Term dating action: [End] | [Change] — every [End] call and every [Change] call, each checked against the proposed tenure.

Term keyed action: [End] | [Change] | [Withdraw] | [Look Up] — the actions that name one tenure by tenure id; in a rule on a keyed action, the tenure is the one carrying the tenure id of the call.

Term writing action: [Begin] | [End] | [Change] | [Withdraw] — the actions that change the tenures.

Term proposed tenure: the tenure as a [Begin] call would record the tenure, or as an [End] or [Change] call would leave the tenure, with the values the call carries in place of the tenure's own.

Term overlap: two tenures overlap where one date lies in the days of both.

Term twin: a tenure carrying no withdrawn instant, other than the tenure the call names, with the person reference, the role and the item reference of the proposed tenure.

Term overlapping twin: a twin that overlaps the proposed tenure.

Term rival: a tenure carrying no withdrawn instant, other than the tenure the call names, with the role and the item reference of the proposed tenure and another person reference.

Term overlapping rival: a rival that overlaps the proposed tenure.

Term match: a tenure carrying no withdrawn instant and carrying the reference as the person reference or the item reference, held on the date of the call where the call carries a date.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| a placing action | the role of the proposed tenure blank or over the string cap, or the call carries a role that is not a string or not in the role set | [Invalid Role] | none (Operation 5, Operation 6, Operation 7) |
| a placing action | the start date carried and not a date | [Invalid Start Date] | none (Operation 8) |
| a placing action | the same person holds the same role in the same thing on a day the proposed tenure covers | [Already Held] | none (Operation 12) |
| a placing action | the role in the one-holder set, and another person holds the role in the thing on a day the proposed tenure covers | [Role Taken] | none (Operation 13) |
| a dating action | the end date carried and not a date | [Invalid End Date] | none (Operation 9) |
| a dating action | the end date the same as the start date, or earlier | [End Too Early] | none (Operation 10, Operation 11) |
| a keyed action | no tenure carries the tenure id, or the id is not a string | [Not Known] | none (Operation 14) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

The sales team's calls, made on Monday 2026-11-16:

- `begin("sam", "account-manager", "acme-supply", "2026-11-20")` — rejected as [Role Taken]: account-manager has one holder at a time, Dana's `t-3` runs through November 30, and Lee's `t-19` runs from December 1 (Operation 13).
- `begin("jane-ruiz", "buyer", "acme-supply", "2026-05-01")` — rejected as [Already Held]: Jane's `t-12` covers May (Operation 12).
- `begin("dana", "account-manager", "acme-supply", "2026-11-20")` — rejected as [Already Held]: the proposed tenure is open from November 20, so it overlaps Dana's own `t-3`, which runs through November 30, and Lee's `t-19`, which runs from December 1; Operation 12 and Operation 13 both apply, and the refusal listed first on [Begin]'s refuses line answers (Execution Contract Refusal 1).
- `begin("jane-ruiz", "cfo", "acme-supply", "2026-03-02")` — rejected as [Invalid Role]: the team's role set has no cfo (Operation 6).
- `begin("", "buyer", "acme-supply", "2026-03-02")` — rejected as [Invalid Person Reference]: the reference is blank (Operation 1).
- `begin("jane-ruiz", "buyer", "", "2026-03-02")` — rejected as [Invalid Item Reference]: the reference is blank (Operation 3).
- `begin("jane-ruiz", "buyer", "acme-supply", "March")` — rejected as [Invalid Start Date]: March is not a date (Operation 8).
- `begin("jane-ruiz", "buyer", "acme-supply", "2026-02-30")` — rejected as [Invalid Start Date]: the calendar holds no February 30 (Operation 8).
- `begin("jane-ruiz", "buyer", "acme-supply", "")` — rejected as [Invalid Start Date]: the start date is blank (Operation 40).
- `begin("", "cfo", "", "March")` — rejected as [Invalid Person Reference]: four refusals apply, and the one listed first on [Begin]'s refuses line answers (Execution Contract Refusal 1).
- `end("t-12", "2026-10-15")` — rejected as [Already Ended]: `t-12` carries an end date (Operation 20).
- `end("t-19", "2026-11-01")` — rejected as [End Too Early]: Lee's tenure starts on December 1 (Operation 11).
- `end("t-19", "soon")` — rejected as [Invalid End Date]: soon is not a date (Operation 9).
- `end("t-19", "")` — rejected as [Invalid End Date]: the end date is blank (Operation 41).
- `change("t-12", start_date="2026-11-01")` — rejected as [End Too Early]: `t-12` ends on October 1 (Operation 11).
- `withdraw("t-404")` — rejected as [Not Known]: no tenure carries `t-404` (Operation 14).
- `withdraw("t-12")` twice — the second is rejected as [Already Withdrawn] (Operation 17).
- `look_up("t-404")` — rejected as [Not Known] (Operation 14).
- `history_for("acme-supply", date="next Tuesday")` — answers an empty list: the date is not a date (Operation 38).

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

#### Invalid Person Reference

The refusal of a blank [Person Reference], one over the string cap, or one that is not a string, on [Begin] (Operation 1, Operation 2).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-person-reference

#### Invalid Role

The refusal of a blank [Role], one over the string cap, one that is not a string, or one the role set does not offer, on [Begin] or [Change] (Operation 5, Operation 6, Operation 7).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-role

#### Invalid Item Reference

The refusal of a blank [Item Reference], one over the string cap, or one that is not a string, on [Begin] (Operation 3, Operation 4).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-reference

#### Invalid Start Date

The refusal of a [Start Date] that is not a date on [Begin] or [Change], or that is blank on [Begin] (Operation 8, Operation 40).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-start-date

#### Invalid End Date

The refusal of an [End Date] that is not a date on [End] or [Change], or that is blank on [End] (Operation 9, Operation 41).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-end-date

#### End Too Early

The refusal of an end date the same as the start date or earlier, on [End] or [Change] (Operation 10, Operation 11).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: end-too-early

#### Already Held

The refusal of a tenure the same person already holds in the same role and the same thing on one of the same days, on [Begin] or [Change] (Operation 12).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-held

#### Role Taken

The refusal of a role with one holder at a time that another person holds in the same thing on one of the same days, on [Begin] or [Change] (Operation 13).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: role-taken

#### Already Ended

The refusal of [End] on a tenure that already carries an end date (Operation 20).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-ended

#### Already Withdrawn

The refusal of [End], [Change] or [Withdraw] on a withdrawn tenure (Operation 15, Operation 16, Operation 17).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: already-withdrawn

#### Not Known

The refusal of a tenure id no tenure carries, or one that is not a string, on [End], [Change], [Withdraw] or [Look Up] (Operation 14).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Storage Failure

The refusal [Begin], [End], [Change] or [Withdraw] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

### Begin

#### Begin

Records a [Tenure]: one person in one [Role] in one thing from a [Start Date], open, and answers the [Tenure Id] the host allocated. Refused where the same person already holds the role in the thing on one of the days, or where the role has one holder at a time and someone else holds the role on one of the days.

Kind: Operation

```
begin(person_reference, role, item_reference, start_date)
  answers tenure_id
  refuses invalid-person-reference | invalid-role | invalid-item-reference | invalid-start-date | already-held | role-taken | storage-failure
```

```
Operation 1: IF the person reference EQUALS blank OR the person reference EXCEEDS the string cap THEN [Begin] MUST answer invalid-person-reference.
Operation 2: IF the person reference is malformed THEN [Begin] MUST answer invalid-person-reference (Execution Contract Input 1).
Operation 3: IF the item reference EQUALS blank OR the item reference EXCEEDS the string cap THEN [Begin] MUST answer invalid-item-reference.
Operation 4: IF the item reference is malformed THEN [Begin] MUST answer invalid-item-reference (Execution Contract Input 1).
Operation 18: [Begin] MUST record EXACTLY ONE tenure carrying the person reference, the role, the item reference and the start date of the call.
Operation 19: [Begin] MUST answer the tenure id.
Operation 40: IF the start date of the call EQUALS blank THEN [Begin] MUST answer invalid-start-date (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [Begin] | every input valid, the role in the role set, no overlapping twin, no overlapping rival where the role is in the one-holder set, database accepts | the tenure id | one tenure lands, open, carrying the person reference, the role, the item reference and the start date of the call (Operation 18, Operation 19, State 1) |
| [Begin] | the person reference blank, over the string cap, or not a string | [Invalid Person Reference] | none (Operation 1, Operation 2) |
| [Begin] | the item reference blank, over the string cap, or not a string | [Invalid Item Reference] | none (Operation 3, Operation 4) |
| [Begin] | the start date blank | [Invalid Start Date] | none (Operation 40) |

### End

#### End

Sets the [End Date] of an open tenure: the first day the role is not held, past or future. Answers ok.

Kind: Operation

```
end(tenure_id, end_date)
  answers ok
  refuses not-known | already-withdrawn | already-ended | invalid-end-date | end-too-early | storage-failure
```

```
Operation 15: IF the tenure carries a withdrawn instant THEN [End] MUST answer already-withdrawn.
Operation 20: IF the tenure carries an end date THEN [End] MUST answer already-ended.
Operation 21: [End] MUST set the end date of the call on the tenure.
Operation 22: [End] MUST answer ok.
Operation 41: IF the end date of the call EQUALS blank THEN [End] MUST answer invalid-end-date (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [End] | the end date blank | [Invalid End Date] | none (Operation 41) |
| [End] | the tenure open and not withdrawn, the end date valid, database accepts | ok | the tenure carries the end date; the earlier version stays readable (Operation 21, Operation 22, Execution Contract Database 5) |
| [End] | the tenure already carries an end date | [Already Ended] | none (Operation 20) |
| [End], [Change] or [Withdraw] | the tenure carries a withdrawn instant | [Already Withdrawn] | none (Operation 15, Operation 16, Operation 17) |

### Change

#### Change

Sets each detail the call carries, the role, the start date or the end date, on a tenure entered wrong, and leaves every other detail as it stands; the earlier version stays readable. A call carrying no detail writes nothing. Answers ok.

Kind: Operation

```
change(tenure_id, optional role, optional start_date, optional end_date)
  answers ok
  refuses not-known | already-withdrawn | invalid-role | invalid-start-date | invalid-end-date | end-too-early | already-held | role-taken | storage-failure
```

```
Operation 16: IF the tenure carries a withdrawn instant THEN [Change] MUST answer already-withdrawn.
Operation 23: IF the call carries a detail THEN [Change] MUST set EVERY detail the call carries.
Operation 24: [Change] MUST NOT change a detail the call omits.
Operation 25: IF the call carries no detail THEN [Change] MUST NOT write.
Operation 26: [Change] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [Change] | the tenure carries no withdrawn instant, every carried detail valid, no overlapping twin, no overlapping rival where the role is in the one-holder set, database accepts | ok | each carried detail is set and every other detail stands; the earlier version stays readable (Operation 23, Operation 24, Operation 26) |
| [Change] | the call carries no detail, the tenure is known and carries no withdrawn instant, and no overlapping rival stands | ok | none, no write (Operation 25) |

### Withdraw

#### Withdraw

Takes back a tenure entered by mistake: stamps the [Withdrawn Instant], changes no detail, and removes nothing. Answers ok.

Kind: Operation

```
withdraw(tenure_id)
  answers ok
  refuses not-known | already-withdrawn | storage-failure
```

```
Operation 17: IF the tenure carries a withdrawn instant THEN [Withdraw] MUST answer already-withdrawn.
Operation 27: [Withdraw] MUST stamp the withdrawn instant from the injected now.
Operation 28: [Withdraw] MUST NOT change a detail.
Operation 29: [Withdraw] MUST answer ok.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [Withdraw] | the tenure carries no withdrawn instant | ok | the tenure carries the withdrawn instant, now; every detail stands; nothing is removed (Operation 27, Operation 28, Operation 29, State 3) |

### Look Up

#### Look Up

Answers the [Tenure] carrying the tenure id, withdrawn or not, and changes nothing.

Kind: Operation

```
look_up(tenure_id)
  answers tenure
  refuses not-known
```

```
Operation 30: [Look Up] MUST answer the tenure.
Operation 31: [Look Up] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [Look Up] | the tenure exists, carrying a withdrawn instant or not | the tenure | none (Operation 30, Operation 31) |

### History For

#### History For

Answers the [Tenures] not withdrawn naming the reference as the person or the thing, held on the date where the call carries one, in order of [Start Date], and changes nothing; an empty list where none matches.

Kind: Operation

```
history_for(reference, optional date)
  answers tenures(tenure)
```

```
Operation 32: [History For] MUST answer EVERY match.
Operation 33: [History For] MUST NOT answer a withdrawn tenure.
Operation 34: [History For] MUST answer an empty list for a reference no match carries.
Operation 35: [History For] MUST answer matches in order of start date (Execution Contract Read 5, Execution Contract Logic confinement 10).
Operation 36: [History For] MUST answer two matches sharing a start date in codepoint order of tenure id (Execution Contract Read 5, Execution Contract Logic confinement 10).
Operation 37: IF the reference is malformed OR the reference EQUALS blank OR the reference EXCEEDS the string cap THEN [History For] MUST answer an empty list (Execution Contract Query 5).
Operation 38: IF the date of the call is malformed THEN [History For] MUST answer an empty list (Execution Contract Query 1).
Operation 39: [History For] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the tenures |
|---|---|---|---|
| [History For] | tenures match the reference, held on the date where the call names one | each match, in order of start date, ties in codepoint order of tenure id | none (Operation 32, Operation 33, Operation 35, Operation 36, Operation 39) |
| [History For] | no match, the reference blank, over the string cap or not a string, or the date carried and not a date | an empty list | none (Operation 34, Operation 37, Operation 38) |

#### Tenures

The outcome [History For] returns: the list of tenures the reference matches, in order, empty where none matches.

Kind:       Member
Member of:  the History For outcome
Role:       Outcome
Projection: tenures

## What is and what should never be (Invariants)

- **Invariant 1 — A tenure ends after it starts.**
  ```
  Invariant 1.1: The start date of EVERY tenure carrying an end date MUST PRECEDE the end date of the tenure.
  ```
- **Invariant 2 — One person holds one role in one thing once on any day, a withdrawn tenure excepted.**
  ```
  Invariant 2.1: Two tenures sharing a person reference, a role AND an item reference MUST NOT overlap, a withdrawn tenure excepted.
  ```
- **Invariant 3 — A tenure keeps its id, its person and its thing.**
  ```
  Invariant 3.1: The atom MUST NOT change a tenure's tenure id.
  Invariant 3.2: The atom MUST NOT change a tenure's person reference.
  Invariant 3.3: The atom MUST NOT change a tenure's item reference.
  ```
- **Invariant 4 — Withdrawn is final.**
  ```
  Invariant 4.1: The atom MUST NOT change a withdrawn tenure.
  ```

## When something happens

### Concurrency

Any two writing calls whose overlap checks (Operation 12, Operation 13) decide on the same tenures are serialized (Execution Contract Database 2, whose first sentence lets no write commit against a state its guards did not see), whichever tenure each call writes: the later reads what the earlier committed and decides again. Two [Begin] calls for one role of the one-holder set in one thing, on days that overlap, are such a pair: the later reads the tenure the earlier recorded and answers [Role Taken] (Operation 13), so the two calls never leave two people holding a one-holder role on one day. So are two [Begin] calls for one person, role and thing, where the later answers [Already Held] (Operation 12), and two [Change] or [End] calls on two tenures of one person, role and thing, which never leave the two overlapping (Invariant 2.1). Two [Change] calls on one tenure are serialized the same way: each sets only the details its call carries, and on a detail both carry, the later call's value stands; the database keeps every version (Execution Contract Database 5).

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Begin] meets the tenure the first recorded and answers [Already Held] (Operation 12), but the answer alone does not tell the caller the first landed, since a tenure of the same person, role and thing that covers a day the call covers answers it too, whoever recorded it: the caller asks [History For], finds the first landed where a tenure carries the call's person reference, role, item reference and start date, and reads the tenure id there. A repeated [End] answers [Already Ended] where an end date stands, the first call's or another caller's, so the caller asks [Look Up] and finds the first landed where the end date is the one the call carried. A repeated [Withdraw] answers [Already Withdrawn], and the tenure is withdrawn, as the first call asked. A repeated [Change] carrying the same details sets the same values again.

### A detail once given

A [Change] corrects the role, the start date or the end date, but cannot take an end date off a tenure. A tenure ended by mistake is withdrawn and begun again; the database keeps both, and [History For] answers the second alone (Operation 33).

### A handover

A role of the one-holder set passes from one person to the next on one date: [End] the first tenure on the date, then [Begin] the next on the same date. The days do not overlap, since an end date is the first day the role is not held, and no day goes without a holder. A composing pattern needing the two in one step makes both calls in one transaction (Execution Contract Database 1).

### A role set or a one-holder set that changes

A deployment that drops a role from the role set or adds a role to the one-holder set changes a setting, and the change takes effect at the instance's next start (Execution Contract Logic confinement 17): from that start on, every [Begin] and every [Change] carrying the dropped role answers [Invalid Role] (Operation 6), and every [Begin] and every [Change] in the newly capped role is checked against the one-holder set (Operation 13). Tenures already in the dropped role keep the role and keep answering; tenures already overlapping in the newly capped role stay as they are, and a [Change] to one of them that leaves the overlap in place answers [Role Taken].

### Dates entered late

A tenure begins and ends on the days the role was held, whenever the call is made: a departure at the end of September learned in November is entered with the end date October 1, and every read for a date from October 1 on answers the tenure as ended. A read made in October answered the tenure as held, and the database's versions keep what each read could see (Execution Contract Database 5). [Begin] records an open tenure, so a tenure that was over before a later tenure of the same person, role and thing began, or before a later holder of a role of the one-holder set began, is entered in the order of its days: begun while the later tenure stands, it overlaps the later tenure and answers [Already Held] or [Role Taken] (Operation 12, Operation 13), and the later tenures are withdrawn and begun again after it, with new tenure ids.

### What undoes a write

[Withdraw] undoes [Begin]. [End] is undone by withdrawing the tenure and beginning the tenure again, since no end date can be taken off. A [Change] is undone by a [Change] carrying the earlier values, which the database keeps readable (Execution Contract Database 5). [Withdraw] is final (Invariant 4.1).

## While something is so

### String policy

A person reference, an item reference and a role are strings the atom compares codepoint for codepoint and never normalizes (Identity 6 through 11, Capability requirement 4 through 6). Each is held to the string cap, and a blank one is refused (Operation 1, Operation 3, Operation 5); a value that is not a string is malformed (Execution Contract Input 1). A [History For] reference is held to the same bounds and answers an empty list where it is blank, over the cap or malformed (Operation 37).

## Optional

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1, Execution Contract Query 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 6: The deployment MUST NOT normalize a role at the seam.
Capability requirement 7: The deployment MAY declare the role set PER Execution Contract Logic confinement 17.
Capability requirement 8: The deployment MAY declare the one-holder set PER Execution Contract Logic confinement 17.
Capability requirement 9: IF a member of the role set EQUALS blank OR a member of the role set EXCEEDS the string cap THEN the deployment MUST NOT declare the role set.
Capability requirement 10: IF a member of the one-holder set IS NOT IN the role set THEN the deployment MUST NOT declare the one-holder set.
Capability requirement 11: IF the deployment declares the string cap AND a member of the role set EXCEEDS the string cap declared THEN the deployment MUST NOT declare the string cap.
```

Term role set: the roles a deployment offers; the one role `contact` where a deployment declares none.

Term one-holder set: the roles a deployment lets one person at a time hold in one thing, such as account-manager; none where a deployment declares none.

Term string cap: the bound on the length of a person reference, an item reference and a role in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

Term reference: the string a [History For] call names — a person reference or an item reference.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key tenure id; carried by tenures; calls Look Up.

## Left to others

```
Non-goal 1: The atom MUST NOT check a person reference against a directory.
Non-goal 2: The atom MUST NOT check an item reference against a catalog.
Non-goal 3: The atom MUST NOT grant a permission for a role.
Non-goal 4: The atom MUST NOT make a person responsible for a piece of work.
Non-goal 5: The atom MUST NOT act when a date arrives.
Non-goal 6: The atom MUST NOT tell who may call an action.
Non-goal 7: The atom MUST NOT record who called an action.
Non-goal 8: The atom MUST NOT read a date in a place.
Non-goal 9: The atom MUST NOT find a tenure by a role across items.
Non-goal 10: The atom MUST NOT bound a tenure's retention.
Non-goal 11: The atom MUST NOT destroy a tenure.
Non-goal 12: The atom MUST NOT make a tenure tamper-evident; a withdrawn tenure stands unchanged by Invariant 4.1, which is no seal.
```

NOTE: the owners — [Party Identity](./party-identity.md) and [Actor Identity](./actor-identity.md), which attests (Non-goal 1; External check 1); Catalog *(forthcoming)* (Non-goal 2; External check 2); the app's permission, which a deployment needing roles calls once the deployment resolves the role to grants (Non-goal 3); [Assignment](./assignment.md) (Non-goal 4); Scheduler *(forthcoming)* (Non-goal 5); the composing pattern that knows the caller, such as one built on a session or the app's permission (Non-goal 6); [Event Log](./event-log.md) (Non-goal 7); [Calendar Time](./calendar-time.md) (Non-goal 8); Reverse Index *(forthcoming)* (Non-goal 9); [Retention Window](./retention-window.md) (Non-goal 10); [Defensible Retention](../compositions/defensible-retention.md) and [Erasure Tombstone](./erasure-tombstone.md) (Non-goal 11); [Tamper Evidence](./tamper-evidence.md) (Non-goal 12).

Where the atom breaks down: what a role lets a person do, which is a grant in the app's permission; one person responsible for one piece of work, which is an assignment; a company's tie to another company, which is no one person's role.

```
Composition note 1: A composing pattern MUST own what this atom declines (Non-goal 1 through 12).
Composition note 2: A composing pattern MUST NOT carry one string as a person reference and as an item reference, since [History For] matches a reference against both (Operation 32).
```

NOTE: composing patterns — none yet. Forthcoming: Customer Relationship.

## Example

The same pattern in two domains, then the rejection paths.

### Sales team

A sales team declares the role set buyer, billing-contact, champion and account-manager, with account-manager in the one-holder set. Dana has been Acme Supply's account manager since 2025: `begin("dana", "account-manager", "acme-supply", "2025-06-01")` answered `t-3`. Jane Ruiz becomes Acme's buyer: `begin("jane-ruiz", "buyer", "acme-supply", "2026-03-02")` answers `t-12`. Jane leaves at the end of September; the team hears in November and ends her tenure on the day it ended: `end("t-12", "2026-10-01")` answers ok. `history_for("acme-supply", date="2026-10-15")` answers `t-3` alone, and `history_for("acme-supply")` answers `t-3` then `t-12`, in order of start date. Lee takes over from Dana on December 1: `end("t-3", "2026-12-01")` answers ok, then `begin("lee", "account-manager", "acme-supply", "2026-12-01")` answers `t-19`; on December 1 Lee holds the role and Dana does not.

### Food pantry

A food pantry declares the role set volunteer, shift-lead and treasurer, with treasurer in the one-holder set. Maria volunteers from January and leads shifts from April: `begin("maria", "volunteer", "pantry", "2026-01-05")` answers `t-1` and `begin("maria", "shift-lead", "pantry", "2026-04-01")` answers `t-2`. `history_for("maria", date="2026-05-01")` answers both, since one person holds two roles. Ten other people hold volunteer at the same time, and every one of those tenures lands, since volunteer is shared.

## Source

Tenure is a primitive with no regulatory anchor. It inherits from:

- **Salesforce, the Account Contact Relationship** — shipped practice: a contact's roles at an account, such as Decision Maker or Influencer, kept with a start date and an end date so the relationship's history is kept; this atom keeps the same shape for any person in any thing.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.

---

## Proof

### Generation acceptance

Acceptable when the checks below are provable to an external auditor from the tenures the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

#### Conformance checks

```
Check 1.1: An auditor MUST find EVERY tenure carrying tenure id, person reference, role, item reference AND start date (State 1).
Check 2.1: An auditor MUST find no tenure whose end date PRECEDES the tenure's start date (Invariant 1.1).
Check 2.2: An auditor MUST find no tenure whose end date EQUALS the tenure's start date (Invariant 1.1).
Check 3.1: An auditor MUST find no two tenures sharing a person reference, a role AND an item reference overlapping, a withdrawn tenure excepted (Invariant 2.1).
Check 4.1: An auditor MUST find EVERY version of a tenure carrying the tenure id of the tenure's first version (Invariant 3.1).
Check 4.2: An auditor MUST find EVERY version of a tenure carrying the person reference of the tenure's first version (Invariant 3.2).
Check 4.3: An auditor MUST find EVERY version of a tenure carrying the item reference of the tenure's first version (Invariant 3.3).
Check 5.1: An auditor MUST find no version of a tenure written after the tenure's withdrawn version differing from the withdrawn version (Invariant 4.1).
Check 6.1: An auditor MUST find no two first versions of tenures sharing a tenure id (Identity 4).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing a person reference confirmed as naming a real person MUST read the deployment's directory (Non-goal 1).
External check 2: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 2).
External check 3: An auditor needing the roles that have one holder at a time MUST read the deployment's one-holder set (Operation 13).
External check 4: An auditor needing to know that no two people held a role of the one-holder set in one thing on one day MUST find no two overlapping tenures that carry one item reference, two person references and one role of the deployment's one-holder set, except an overlap standing when the role joined the set (Operation 13).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the deployment (also: a deployment); the implementation; the business caller; a composing pattern; the database; a tenure; a placing action; a dating action; a keyed action; a writing action; an auditor.

Term records: tenure — one person's time in one role in one thing, carrying tenure id, person reference, role, item reference and start date, and where given, end date and withdrawn instant.

Term record verbs: identify, allocate, take, reuse, own, normalize, compare, carry, remove, supply, declare, record, answer, set, change, write, stamp, overlap, find, read, check, grant, make, act, tell, bound, destroy, seal, keep.

Term value sets: placing action, dating action, keyed action and writing action are declared above and cited here (GRACE-lang Closed vocabulary 15); action rejection — invalid-person-reference | invalid-role | invalid-item-reference | invalid-start-date | invalid-end-date | end-too-early | already-held | role-taken | already-ended | already-withdrawn | not-known | storage-failure.

Term bounds: string cap (the bound on the length of a person reference, an item reference and a role in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang v0.73 (2026-11-16) through the Grace connector.

Term terms: tenure, tenures, tenure id, person reference, person references, role, roles, role set, one-holder set, item reference, item references, string cap, seam, date, dates, start date, end date, withdrawn instant, withdrawn tenure, days, held, upcoming, ended, detail, details, placing action, dating action, keyed action, writing action, proposed tenure, overlap, twin, overlapping twin, rival, overlapping rival, reference, match, matches, version.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Begin]: #begin
[End]: #end
[Change]: #change
[Withdraw]: #withdraw
[Look Up]: #look-up
[History For]: #history-for
[Tenure]: #tenure
[Tenure Id]: #tenure-id
[Tenures]: #tenures
[Person Reference]: #person-reference
[Role]: #role
[Item Reference]: #item-reference
[Start Date]: #start-date
[End Date]: #end-date
[Withdrawn Instant]: #withdrawn-instant
[Invalid Person Reference]: #invalid-person-reference
[Invalid Role]: #invalid-role
[Invalid Item Reference]: #invalid-item-reference
[Invalid Start Date]: #invalid-start-date
[Invalid End Date]: #invalid-end-date
[End Too Early]: #end-too-early
[Already Held]: #already-held
[Role Taken]: #role-taken
[Already Ended]: #already-ended
[Already Withdrawn]: #already-withdrawn
[Not Known]: #not-known
[Storage Failure]: #storage-failure

---

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: pending — no model yet
last gate: 2026-11-27 — Final Critique 5, a full round, frozen at 79cac81e — foundational count 1, not clean, three passes and the Claude reader

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./tenure.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/tenure.md`.

</details>

NOTE: End of Tenure.

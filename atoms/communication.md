---
title: Communication
id: 66
parent: Atomic Concepts
has_toc: true
toc: true
---

# Communication

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## Summary

Communication keeps the history of exchanges between a business and people outside the business: a phone call, an email, a meeting, a message, a letter or a visit. Each communication says how the exchange happened, when, which way it went, who took part on each side, a short summary, what the exchange was about — a customer, a deal, a repair — and, where the business keeps them, an outcome such as no answer. A communication records an exchange that already happened; a meeting still to come belongs to a calendar. The history reads in the order things happened, not the order they were logged, so a phone call logged on Friday for Tuesday sits on Tuesday. Any detail can be changed later, and the earlier version stays on file. A communication logged by mistake is withdrawn: the communication leaves the history, stays readable marked withdrawn, and stays withdrawn. The business makes two choices: the ways an exchange can happen, and the outcomes a communication can carry. Sending anything, meetings still to come, notes kept only for the team, files and recordings, who may do what, and stopping a repeat each belong to another pattern — another separately specified building block of the same kind — which is why one history serves a sales team, a clinic's front desk and a property manager alike.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

Wherever a business deals with people over time, whoever picks up the relationship needs to know what was said, when, and by whom. This atom is that record and nothing more. Three decisions carry the weight. A communication carries the instant the exchange happened, and every history reads by that instant, so logging late never reorders the story. A communication logged by mistake is withdrawn, never removed: the history drops the communication, the file keeps the communication, and every earlier version stays readable, so fixing a mistake never erases evidence. And each refusal names the one detail a person can fix, so the screen can say plainly what to fix; the words belong to the screen. Who the people are, what the items are, who may log or read, and how anything is sent are other patterns' questions, and declining them is what lets one history serve any business that talks to people outside the business.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a communication by the communication's communication id.
Identity 2: The host MUST allocate a communication id at the atom's seam.
Identity 3: [Record] MUST NOT take a communication id from the business caller.
Identity 4: The atom MUST NOT reuse a communication id.
Identity 5: The implementation MUST own the communication id's scheme.
Identity 6: The atom MUST NOT normalize a person reference.
Identity 7: The atom MUST compare two person references codepoint for codepoint.
Identity 8: The atom MUST NOT normalize an item reference.
Identity 9: The atom MUST compare two item references codepoint for codepoint.
Identity 10: The atom MUST NOT normalize a medium.
Identity 11: The atom MUST compare two media codepoint for codepoint.
Identity 12: The atom MUST NOT normalize an outcome.
Identity 13: The atom MUST compare two outcomes codepoint for codepoint.
```

Term communication: one exchange between the business and people outside the business, kept from the [Record] call that logged the exchange — a [Communication].

Term communication id: the id the host allocates at the seam for each communication — the [Communication Id]; never reused.

Term detail: a medium, an occurred instant, outside participants, inside participants, a direction, a summary, item references or an outcome — what a communication carries about the exchange, and what a detail action names.

Term medium: how an exchange happened, such as phone, email or meeting, one of the medium set — the [Medium].

Term medium set: the media a deployment offers; phone, email, meeting, message, letter and visit where a deployment declares none.

Term outcome: how an exchange went, such as connected or no-answer, one of the outcome set — the [Outcome].

Term outcome set: the outcomes a deployment offers; none where a deployment declares none.

Term person reference: the string naming one person who took part in an exchange, in the deployment's own scheme; the atom reads no scheme in it.

Term outside participant: a person outside the business who took part in an exchange, named by a person reference.

Term outside participants: the outside participants a communication carries — the [Outside Participants]; never an empty list.

Term inside participant: a person of the business who took part in an exchange, named by a person reference.

Term inside participants: the inside participants a communication carries — the [Inside Participants]; an empty list where the call names none.

Term item reference: the string naming one item an exchange was about, such as a customer, a deal or a repair, in the deployment's own scheme; the atom reads no scheme in it.

Term item references: the item references a communication carries — the [Item References]; an empty list where the call names none.

Term string cap: the bound on the length of a person reference, an item reference, a medium, an outcome and a summary in Unicode code points; 1,024 code points where a deployment declares none.

Term seam: the atom's input and output boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, now, at the seam.

NOTE: Capability requirement 4 through 7 are the atom's own rule for the canonical form of each reference, of a medium and of an outcome, which stands in place of Execution Contract Logic confinement 13 (as that rule's last sentence allows a specification that gives the canonical form another owner), so each is recorded as the call carries it (Execution Contract Input 4; Identity 6 through 13).

### State

```
State 1: EVERY communication MUST carry communication id, medium, occurred instant, outside participants, inside participants, item references and status.
State 2: A communication MAY carry direction, summary and outcome.
State 3: EVERY communication MUST stand in EXACTLY ONE OF active, withdrawn.
State 4: The atom MUST NOT remove a communication.
```

Term occurred instant: the instant the exchange happened, as the [Record] or [Change] call carries it — the [Occurred Instant]; never later than the injected now of the call that set it; a [Record] that leaves it blank is refused (Operation 45), which stands in place of Execution Contract Logic confinement 12, and a [Change] that leaves it blank omits it, and it stands (Operation 27, GRACE-lang Earned vocabulary 22).

Term direction: which way an exchange went — the [Direction]; inbound or outbound.

Term inbound: the direction of an exchange a person outside the business began — [Inbound].

Term outbound: the direction of an exchange the business began — [Outbound].

Term summary: a short account of the exchange in words — the [Summary]; never blank, at most the string cap.

Term status: where a communication stands, active or withdrawn — the [Status].

Term active: the status of a communication in force — [Active]; the communication stands in every history the communication matches.

Term withdrawn: the status of a communication taken back as logged by mistake — [Withdrawn]; the communication stands in no history and stays readable by [Look Up].

### Capability requirement

```
Capability requirement 1: The deployment MUST supply the database PER Execution Contract Database 1 through 7, Execution Contract Read 1 through 6, Execution Contract Refusal 1, Execution Contract Input 1, Execution Contract Query 1 and Execution Contract Query 5.
Capability requirement 2: The deployment MUST supply now at the seam PER Execution Contract Logic confinement 11.
Capability requirement 3: The deployment MAY declare the string cap PER Execution Contract Input 2 and Execution Contract Logic confinement 17.
Capability requirement 4: The deployment MUST NOT normalize a person reference at the seam.
Capability requirement 5: The deployment MUST NOT normalize an item reference at the seam.
Capability requirement 6: The deployment MUST NOT normalize a medium at the seam.
Capability requirement 7: The deployment MUST NOT normalize an outcome at the seam.
Capability requirement 8: The deployment MAY declare the medium set PER Execution Contract Logic confinement 17.
Capability requirement 9: The deployment MAY declare the outcome set PER Execution Contract Logic confinement 17.
Capability requirement 10: IF a member of the medium set EQUALS blank OR a member of the medium set EXCEEDS the string cap THEN the deployment MUST NOT declare the medium set.
Capability requirement 11: IF a member of the outcome set EQUALS blank OR a member of the outcome set EXCEEDS the string cap THEN the deployment MUST NOT declare the outcome set.
Capability requirement 12: The deployment MUST supply each communication id PER Execution Contract Logic confinement 16.
```

### Operations

```
record(medium, occurred_instant, outside_participants, optional inside_participants, optional direction, optional summary, optional item_references, optional outcome)
  answers communication_id
  refuses invalid-medium | invalid-occurred-instant | invalid-outside-participants | invalid-inside-participants | invalid-direction | invalid-summary | invalid-item-references | invalid-outcome | storage-failure

change(communication_id, optional medium, optional occurred_instant, optional outside_participants, optional inside_participants, optional direction, optional summary, optional item_references, optional outcome)
  answers ok
  refuses not-known | not-active | invalid-medium | invalid-occurred-instant | invalid-outside-participants | invalid-inside-participants | invalid-direction | invalid-summary | invalid-item-references | invalid-outcome | storage-failure

withdraw(communication_id)
  answers ok
  refuses not-known | not-active | storage-failure

look_up(communication_id)
  answers communication
  refuses not-known

history_for(reference, optional start_instant, optional end_instant)
  answers communications(communication)
```

```
Operation 1: IF the medium of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-medium.
Operation 2: IF the medium of the call DOES NOT EQUAL blank AND the medium of the call IS NOT IN the medium set THEN a detail action MUST answer invalid-medium.
Operation 3: IF the occurred instant of the call DOES NOT EQUAL blank AND the injected now PRECEDES the occurred instant of the call THEN a detail action MUST answer invalid-occurred-instant.
Operation 4: IF the outside participants of the call EQUALS blank THEN [Record] MUST answer invalid-outside-participants.
Operation 5: IF a member of the outside participants of the call EQUALS blank OR a member of the outside participants of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-outside-participants.
Operation 6: IF a member of the inside participants of the call EQUALS blank OR a member of the inside participants of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-inside-participants.
Operation 7: IF the summary of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-summary.
Operation 8: IF a member of the item references of the call EQUALS blank OR a member of the item references of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-item-references.
Operation 9: IF the outcome of the call EXCEEDS the string cap THEN a detail action MUST answer invalid-outcome.
Operation 10: IF the outcome of the call DOES NOT EQUAL blank AND the outcome of the call IS NOT IN the outcome set THEN a detail action MUST answer invalid-outcome.
Operation 11: IF the medium of the call is malformed THEN a detail action MUST answer invalid-medium (Execution Contract Input 1).
Operation 12: IF the occurred instant of the call is malformed THEN a detail action MUST answer invalid-occurred-instant (Execution Contract Input 1).
Operation 13: IF the outside participants of the call is malformed THEN a detail action MUST answer invalid-outside-participants (Execution Contract Input 1).
Operation 14: IF the inside participants of the call is malformed THEN a detail action MUST answer invalid-inside-participants (Execution Contract Input 1).
Operation 15: IF the direction of the call is malformed THEN a detail action MUST answer invalid-direction (Execution Contract Input 1).
Operation 16: IF the summary of the call is malformed THEN a detail action MUST answer invalid-summary (Execution Contract Input 1).
Operation 17: IF the item references of the call is malformed THEN a detail action MUST answer invalid-item-references (Execution Contract Input 1).
Operation 18: IF the outcome of the call is malformed THEN a detail action MUST answer invalid-outcome (Execution Contract Input 1).
Operation 19: [Record] MUST record EXACTLY ONE communication carrying the details of the call.
Operation 20: [Record] MUST stand the communication in active.
Operation 21: IF the call omits inside participants THEN [Record] MUST record an empty list as the inside participants.
Operation 22: IF the call omits item references THEN [Record] MUST record an empty list as the item references.
Operation 23: [Record] MUST answer the communication id.
Operation 24: IF the communication id of the call is malformed OR no communication carries the communication id of the call THEN a keyed action MUST answer not-known.
Operation 25: IF the communication's status EQUALS withdrawn THEN [Change] MUST answer not-active.
Operation 26: IF the call supplies a detail THEN [Change] MUST set EVERY detail the call supplies.
Operation 27: [Change] MUST NOT change a detail the call omits.
Operation 28: IF the call supplies no detail THEN [Change] MUST NOT write.
Operation 29: [Change] MUST answer ok.
Operation 30: IF the communication's status EQUALS withdrawn THEN [Withdraw] MUST answer not-active.
Operation 31: IF the communication's status EQUALS active THEN [Withdraw] MUST stand the communication in withdrawn.
Operation 32: [Withdraw] MUST NOT change a detail.
Operation 33: [Withdraw] MUST answer ok.
Operation 34: [Look Up] MUST answer the communication.
Operation 35: [Look Up] MUST NOT write.
Operation 36: [History For] MUST answer EVERY match.
Operation 37: [History For] MUST NOT answer a withdrawn communication.
Operation 38: [History For] MUST answer an empty list for a reference no match carries.
Operation 39: [History For] MUST answer matches in order of occurred instant, earliest first (Execution Contract Read 5, Execution Contract Logic confinement 10).
Operation 40: [History For] MUST answer two matches sharing an occurred instant in codepoint order of communication id (Execution Contract Read 5, Execution Contract Logic confinement 10).
Operation 41: IF the reference is malformed OR the reference EQUALS blank OR the reference EXCEEDS the string cap THEN [History For] MUST answer an empty list (Execution Contract Query 5).
Operation 42: IF the start instant is malformed OR the end instant is malformed THEN [History For] MUST answer an empty list (Execution Contract Query 1).
Operation 43: [History For] MUST NOT write.
Operation 44: IF the medium of the call EQUALS blank THEN [Record] MUST answer invalid-medium.
Operation 45: IF the occurred instant of the call EQUALS blank THEN [Record] MUST answer invalid-occurred-instant (Execution Contract Input 1, Execution Contract Logic confinement 12).
```

Term detail action: [Record] | [Change] — the actions that carry details.

Term keyed action: [Change] | [Withdraw] | [Look Up] — the actions that name one communication by communication id; in a rule on a keyed action, the communication is the one carrying the communication id of the call.

Term writing action: [Record] | [Change] | [Withdraw] — the actions that change the communications.

Term reference: the string a [History For] call names — a person reference or an item reference.

Term start instant: the earliest occurred instant a [History For] call asks for; a call with none asks for no earliest.

Term end instant: the latest occurred instant a [History For] call asks for; a call with none asks for no latest.

Term range: the start instant and the end instant of a [History For] call; an occurred instant lies inside the range where the occurred instant is neither earlier than the start instant nor later than the end instant; a call carrying no start instant or no end instant leaves the range open at that end, which Execution Contract Query 1 would read as malformed, and the atom's own rule stands in place of it.

Term match: an active communication carrying the reference as an outside participant, an inside participant or an item reference, with an occurred instant inside the range.

Term history: the matches a [History For] call answers for a reference.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the communications |
|---|---|---|---|
| [Record] | every detail valid, the medium in the medium set, any outcome in the outcome set, the occurred instant no later than now, database accepts | the communication id | one communication lands, active, carrying the details of the call (Operation 19, Operation 20, Operation 23, State 1) |
| [Record] | the call leaves inside participants or item references blank, omitted or an empty list | the communication id | each such list is recorded empty (Operation 21, Operation 22, GRACE-lang Earned vocabulary 22) |
| a detail action | the occurred instant later than now | [Invalid Occurred Instant] | none (Operation 3) |
| a detail action | the occurred instant not an instant | [Invalid Occurred Instant] | none (Operation 12) |
| [Record] | the occurred instant blank | [Invalid Occurred Instant] | none (Operation 45) |
| a detail action | the medium over the string cap, not a string, or not in the medium set | [Invalid Medium] | none (Operation 1, Operation 2, Operation 11) |
| [Record] | the medium blank | [Invalid Medium] | none (Operation 44) |
| [Record] | the outside participants blank, omitted or an empty list | [Invalid Outside Participants] | none (Operation 4) |
| a detail action | an outside participant blank or over the string cap, or not a list of strings | [Invalid Outside Participants] | none (Operation 5, Operation 13) |
| a detail action | an inside participant blank or over the string cap, or not a list of strings | [Invalid Inside Participants] | none (Operation 6, Operation 14) |
| a detail action | the direction neither inbound nor outbound | [Invalid Direction] | none (Operation 15) |
| a detail action | the summary over the string cap, or not a string | [Invalid Summary] | none (Operation 7, Operation 16) |
| a detail action | an item reference blank or over the string cap, or not a list of strings | [Invalid Item References] | none (Operation 8, Operation 17) |
| a detail action | the outcome over the string cap, not a string, or not in the outcome set | [Invalid Outcome] | none (Operation 9, Operation 10, Operation 18) |
| [Change] | the communication stands active, every supplied detail valid, database accepts | ok | every supplied detail is set, every other detail stands, and the earlier version stays readable (Operation 26, Operation 27, Operation 29, Execution Contract Database 5) |
| [Change] | the communication stands active and the call supplies no detail | ok | none, no write (Operation 28) |
| [Change] | the communication stands withdrawn | [Not Active] | none (Operation 25) |
| [Withdraw] | the communication stands active | ok | the communication stands withdrawn; every detail stands; nothing is removed (Operation 31, Operation 32, State 4) |
| [Withdraw] | the communication stands withdrawn | [Not Active] | none (Operation 30) |
| a keyed action | no communication carries the communication id, or the id is not a string | [Not Known] | none (Operation 24) |
| [Look Up] | the communication exists, either status | the communication | none (Operation 34, Operation 35) |
| [History For] | active communications match the reference inside the range | each match, in order of occurred instant, earliest first, ties in codepoint order of communication id | none (Operation 36, Operation 37, Operation 39, Operation 40, Operation 43) |
| [History For] | no match, a range ending earlier than the range starts, the reference blank, over the string cap or not a string, or an instant not an instant | an empty list | none (Operation 38, Operation 41, Operation 42) |
| any writing call | database refuses the write | [Storage Failure] | none (Execution Contract Read 4) |
| any call | its read of the database fails | `state-unavailable` | none (Execution Contract Read 1, Execution Contract Read 3) |
| any call | more than one refusal applies | the refusal listed first on the action's refuses line | none (Execution Contract Refusal 1) |

### Invariants

- **Invariant 1 — A communication always names someone outside the business.**
  ```
  Invariant 1.1: EVERY communication MUST carry an outside participant.
  ```
- **Invariant 2 — A communication keeps its id.**
  ```
  Invariant 2.1: The atom MUST NOT change a communication's communication id.
  ```
- **Invariant 3 — Withdrawn is final.**
  ```
  Invariant 3.1: The atom MUST NOT stand a withdrawn communication in active.
  ```

## Examples

The same pattern in two domains, then the rejection paths.

### Sales team

A sales team keeps the medium set it starts with and declares the outcome set connected, left-voicemail and no-answer. On Tuesday at 10:15 AM, Dana phones Jane Ruiz at Acme Supply about the renewal, and logs the call on Friday: `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], inside_participants=["dana"], direction="outbound", summary="Renewal: wants the three-year price", item_references=["acme-supply", "renewal-2027"], outcome="connected")` answers `c-71`. Jane's email of Wednesday afternoon was logged that day: `record("email", "2026-11-11T14:02:00-06:00", ["jane-ruiz"], inside_participants=["dana"], direction="inbound", item_references=["acme-supply"])` answers `c-72`. `history_for("acme-supply")` answers `c-71` then `c-72`: the phone call happened first, whenever the call was logged. Dana sharpens the summary: `change("c-71", summary="Renewal: wants the three-year price by Friday")` answers ok, and the first summary stays readable as the earlier version. An email sync logs Jane's email a second time as `c-73`; `withdraw("c-73")` answers ok, `history_for("acme-supply")` no longer answers `c-73`, and `look_up("c-73")` answers the communication, withdrawn.

### Property manager

A property manager declares the medium set phone, email, letter and visit, and no outcome set. A tenant, Omar Haddad, phones the front desk about a leaking faucet: `record("phone", "2026-11-12T08:40:00-06:00", ["omar-haddad"], inside_participants=["front-desk"], direction="inbound", item_references=["unit-4b"])` answers `p-9`. The plumber's visit the next morning is logged the same way with medium visit and answers `p-10`. `history_for("unit-4b")` answers `p-9` then `p-10`, and `history_for("omar-haddad")` answers the same two, since Omar took part in both.

### Rejection paths

The sales team's calls, made on Monday 2026-11-16:

- `record("phone", "2026-11-23T09:00:00-06:00", ["jane-ruiz"])` — rejected as [Invalid Occurred Instant]: next Monday is later than now, and a call still to come belongs on a calendar (Operation 3, Non-goal 2).
- `record("phone", "2026-11-10T10:15:00-06:00", [])` — rejected as [Invalid Outside Participants]: nobody from outside the business took part (Operation 4).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz", ""])` — rejected as [Invalid Outside Participants]: one member is blank (Operation 5).
- `record("fax", "2026-11-10T10:15:00-06:00", ["jane-ruiz"])` — rejected as [Invalid Medium]: the team's medium set has no fax (Operation 2).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], outcome="busy")` — rejected as [Invalid Outcome]: busy is not in the team's outcome set (Operation 10).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], direction="sideways")` — rejected as [Invalid Direction]: a direction is inbound or outbound (Operation 15).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], summary=s)`, where `s` runs to 1,025 code points — rejected as [Invalid Summary]: the summary exceeds the string cap (Operation 7). A blank summary is an omitted one, so `summary=""` records no summary (GRACE-lang Earned vocabulary 22).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], inside_participants=[""])` — rejected as [Invalid Inside Participants]: the member is blank (Operation 6).
- `record("phone", "2026-11-10T10:15:00-06:00", ["jane-ruiz"], item_references=[""])` — rejected as [Invalid Item References]: the member is blank (Operation 8).
- `record("phone", "", ["jane-ruiz"])` — rejected as [Invalid Occurred Instant]: a blank instant is refused on [Record] (Operation 45), and `record("phone", "last Tuesday", ["jane-ruiz"])` is rejected the same way because the words are not an instant (Operation 12).
- `record("fax", "", [])` — rejected as [Invalid Medium]: three refusals apply, and the one listed first on [Record]'s refuses line answers (Execution Contract Refusal 1).
- `change("c-404", summary="Renewal")` — rejected as [Not Known]: no communication carries c-404 (Operation 24).
- `change("c-73", summary="Renewal")` — rejected as [Not Active]: c-73 stands withdrawn (Operation 25).
- `withdraw("c-73")` a second time — rejected as [Not Active] (Operation 30).
- `look_up("c-404")` — rejected as [Not Known] (Operation 24).
- `history_for("acme-supply", start_instant="2026-11-12T00:00:00-06:00", end_instant="2026-11-01T00:00:00-06:00")` — answers an empty list: the range ends earlier than the range starts, so no occurred instant lies inside the range.
- At the property manager, `record("phone", "2026-11-12T08:40:00-06:00", ["omar-haddad"], outcome="connected")` — rejected as [Invalid Outcome]: the manager declares no outcome set, so no outcome is offered (Operation 10).

This covers every refusal but [Storage Failure], which answers when the database refuses a write.

## Generation acceptance

Acceptable when the checks below are provable to an external auditor from the communications the database holds, with their earlier versions (Execution Contract Database 5, Execution Contract Generation acceptance 1). The atom is not regulated and carries no adversarial scenarios.

### Conformance checks

```
Check 1.1: An auditor MUST find EVERY communication carrying communication id, medium, occurred instant, outside participants, inside participants, item references AND status (State 1).
Check 1.2: An auditor MUST find EVERY communication standing in EXACTLY ONE OF active, withdrawn (State 3).
Check 2.1: An auditor MUST find EVERY communication carrying an outside participant (Invariant 1.1).
Check 3.1: An auditor MUST find EVERY version of a communication carrying the communication id of the communication's first version (Invariant 2.1).
Check 4.1: An auditor MUST find EVERY version following a withdrawn version of one communication standing in withdrawn (Invariant 3.1).
Check 5.1: An auditor MUST find no two communications sharing a communication id (Identity 4).
```

Term version: a record as it stood at the commit that wrote it, which Execution Contract Database 5 keeps readable after the record changes and Execution Contract Generation acceptance 1 has a check read.

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing a person reference confirmed as naming a real person MUST read the deployment's directory (Non-goal 9).
External check 2: An auditor needing an item reference confirmed as naming a real item MUST read the deployment's catalog (Non-goal 10).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT send a communication.
Non-goal 2: The atom MUST NOT hold an exchange still to come.
Non-goal 3: The atom MUST NOT hold a note kept only for the business.
Non-goal 4: The atom MUST NOT hold an attachment.
Non-goal 5: The atom MUST NOT detect a repeated record.
Non-goal 6: The atom MUST NOT link a reply to an earlier communication.
Non-goal 7: The atom MUST NOT tell who may call an action.
Non-goal 8: The atom MUST NOT record who called an action.
Non-goal 9: The atom MUST NOT check a person reference against a directory.
Non-goal 10: The atom MUST NOT check an item reference against a catalog.
Non-goal 11: The atom MUST NOT find a communication by a word in a summary.
Non-goal 12: The atom MUST NOT bound a communication's retention.
Non-goal 13: The atom MUST NOT destroy a communication.
Non-goal 14: The atom MUST NOT seal a communication against modification.
```

NOTE: the owners — the deployment's transport, with [Notification](./notification.md) recording each delivery (Non-goal 1); Calendar Event *(forthcoming)* (Non-goal 2); Note *(forthcoming)* (Non-goal 3); Attachment *(forthcoming)*, which holds recordings and files (Non-goal 4); [Duplicate Prevention](./duplicate-prevention.md) (Non-goal 5); Conversation *(forthcoming)* (Non-goal 6); the composing pattern that knows the caller, such as one built on [Session](./session.md) or [Permissions](./permissions.md) (Non-goal 7); [Event Log](./event-log.md) (Non-goal 8); [Party Identity](./party-identity.md) and [Actor Identity](./actor-identity.md) (Non-goal 9; External check 1); Catalog *(forthcoming)* (Non-goal 10; External check 2); Reverse Index *(forthcoming)* (Non-goal 11); [Retention Window](./retention-window.md) (Non-goal 12); [Defensible Retention](../compositions/defensible-retention.md) and [Erasure Tombstone](./erasure-tombstone.md) (Non-goal 13); [Tamper Evidence](./tamper-evidence.md) (Non-goal 14).

Where the atom breaks down: a meeting still to come, which is a calendar event *(forthcoming)*; words kept only for the team, which is a note *(forthcoming)*; one message the system sends to many people, which is a notification fanout.

## Edge cases

### Concurrency

Two [Change] calls on one communication are serialized (Execution Contract Database 2): each sets only the details its call carries, so changes to two different details both land, and on a detail both carry, the later call's value stands; the database keeps every version (Execution Contract Database 5). A [Change] and a [Withdraw] on one communication are serialized the same way, and a [Change] landing second meets a withdrawn communication and answers [Not Active] (Operation 25). Of two [Withdraw] calls on one communication, the second answers [Not Active] (Operation 30).

### Indeterminate outcome

A caller whose answer is lost may call again, and the repeat is a second call (Execution Contract Error model 1). A repeated [Record] records a second communication, since the atom cannot tell a repeat from a second exchange that looks the same; a caller needing the truth asks [History For] and withdraws the extra communication, and a deployment needing a repeat stopped at the door composes the pattern Non-goal 5 names. A repeated [Change] carrying the same details sets the same values again. A repeated [Withdraw] where the first landed answers [Not Active], which tells the caller the first landed.

### A detail once given

A [Change] corrects a detail but cannot take a detail off a communication: a detail the call leaves blank, an empty list among them, is a detail the call omits, and the detail stands (Operation 27, GRACE-lang Earned vocabulary 22), so `change("c-71", inside_participants=[])` answers ok and writes nothing (Operation 28), and the outside participants never empty (Invariant 1.1). A communication that should carry less is withdrawn and recorded again.

### A medium set or an outcome set that changes

A deployment that drops a medium from the medium set stops, at the next start, every [Record] and every [Change] carrying that medium (Operation 2; Execution Contract Logic confinement 17); communications already recorded in that medium keep the medium and stay in every history they match, and a [Change] carrying no medium leaves the medium as it stands. The outcome set works the same way (Operation 10).

### A range or a reference that matches nothing

A range whose end instant is earlier than its start instant holds no occurred instant, so [History For] answers an empty list, as it does for a reference no active communication carries. A deployment that writes one string for a person and for an item gets both in one history, so the deployment keeps the two schemes apart (Composition note 2).

### What undoes a write

[Withdraw] undoes [Record]. A [Change] is undone by a [Change] carrying the earlier values, which the database keeps readable (Execution Contract Database 5). [Withdraw] is final (Invariant 3.1): a communication withdrawn by mistake is recorded again.

## Composition notes

```
Composition note 1: A composing pattern MUST own what this atom declines.
Composition note 2: A composing pattern MUST keep person references apart from item references.
```

NOTE: composing patterns — none yet. Forthcoming: Customer Relationship.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the deployment (also: a deployment); the implementation; the business caller; a composing pattern; the database; a communication; a detail action; a keyed action; a writing action; an auditor.

Term records: communication — one exchange between the business and people outside the business, carrying communication id, medium, occurred instant, outside participants, inside participants, item references and status, and where the call gave them, direction, summary and outcome.

Term record verbs: identify, allocate, take, reuse, own, normalize, compare, carry, stand, remove, supply, declare, record, answer, set, change, write, find, read, send, hold, detect, link, tell, check, bound, destroy, seal, keep.

Term value sets: detail action, keyed action and writing action are declared above and cited here (GRACE-lang Closed vocabulary 15); status — active | withdrawn; direction — inbound | outbound; action rejection — invalid-medium | invalid-occurred-instant | invalid-outside-participants | invalid-inside-participants | invalid-direction | invalid-summary | invalid-item-references | invalid-outcome | not-known | not-active | storage-failure.

Term bounds: string cap (the bound on the length of a person reference, an item reference, a medium, an outcome and a summary in Unicode code points, 1,024 where a deployment declares none).

Term cadences: empty.

Term qualifiers: migrated — drafted in GRACE lang unknown (2026-11-16) through the Grace connector.

Term terms: communication, communications, communication id, detail, details, medium, media, medium set, outcome, outcomes, outcome set, person reference, person references, outside participant, outside participants, inside participant, inside participants, item reference, item references, string cap, seam, occurred instant, direction, inbound, outbound, summary, status, active, withdrawn, detail action, keyed action, writing action, reference, start instant, end instant, range, match, matches, history, version.

#### Record

Logs one exchange that already happened: records a [Communication] carrying the details of the call, stands the communication in [Active], and answers the [Communication Id] the host allocated. An omitted list of inside participants or item references is recorded empty; a blank medium, blank outside participants or a blank occurred instant is refused.

Kind: Operation

#### Change

Sets each detail the call supplies on an [Active] communication and leaves every other detail as it stands, a detail the call leaves blank, an empty list among them, included; the earlier version stays readable. A call supplying no detail writes nothing. Answers ok.

Kind: Operation

#### Withdraw

Takes back a communication logged by mistake: stands an [Active] communication in [Withdrawn], changes no detail, and removes nothing. Answers ok.

Kind: Operation

#### Look Up

Answers the [Communication] carrying the communication id, active or withdrawn, and changes nothing.

Kind: Operation

#### History For

Answers every active communication naming the reference as an outside participant, an inside participant or an item, with an [Occurred Instant] inside the range, in order of occurred instant, earliest first, and changes nothing; an empty list where none matches.

Kind: Operation

#### Communication

One exchange between the business and people outside the business: recorded by [Record], changed by [Change], stood in [Withdrawn] by [Withdraw]; never removed by the atom.

Kind: Type

#### Communication Id

Names one communication; allocated by the host at the seam, never taken from the business caller, never reused and never changed.

Kind:       Field
Field of:   Communication
Projection: communication_id

#### Medium

How the exchange happened, one of the medium set the deployment offered when the detail was set, such as phone. Stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Communication
Projection: medium

#### Occurred Instant

The instant the exchange happened, as the call carried it; never later than the injected now of the call that set it, and the order every history reads in.

Kind:       Field
Field of:   Communication
Projection: occurred_instant

#### Outside Participants

The person references of the people outside the business who took part; never an empty list. Each is stored as supplied and compared codepoint for codepoint.

Kind:       Field
Field of:   Communication
Projection: outside_participants

#### Inside Participants

The person references of the people of the business who took part; an empty list where the call named none.

Kind:       Field
Field of:   Communication
Projection: inside_participants

#### Direction

Which way the exchange went: [Inbound] or [Outbound]; absent where the call gave none.

Kind:       Field
Field of:   Communication
Projection: direction

#### Inbound

The direction of an exchange a person outside the business began.

Kind:       Member
Member of:  the direction
Projection: inbound

#### Outbound

The direction of an exchange the business began.

Kind:       Member
Member of:  the direction
Projection: outbound

#### Summary

A short account of the exchange in words; never blank, at most the string cap, and absent where the call gave none.

Kind:       Field
Field of:   Communication
Projection: summary

#### Item References

The references of the items the exchange was about, such as a customer or a deal; an empty list where the call named none. Each is stored as supplied and compared codepoint for codepoint; whether a reference names a real item is a catalog's question.

Kind:       Field
Field of:   Communication
Projection: item_references

#### Outcome

How the exchange went, one of the outcome set the deployment offered when the detail was set, such as no-answer; absent where the call gave none.

Kind:       Field
Field of:   Communication
Projection: outcome

#### Status

Where a communication stands: [Active] or [Withdrawn].

Kind:       Field
Field of:   Communication
Projection: status

#### Active

The status of a communication in force; the communication stands in every history the communication matches.

Kind:       Member
Member of:  the status
Projection: active

#### Withdrawn

The status of a communication taken back as logged by mistake; the communication stands in no history and stays readable by [Look Up]. Final.

Kind:       Member
Member of:  the status
Projection: withdrawn

#### Invalid Medium

The refusal of a [Medium] over the string cap, one that is not a string, or one the medium set does not offer, on [Record] or [Change], and of a blank one on [Record] (Operation 1, Operation 2, Operation 11, Operation 44).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-medium

#### Invalid Occurred Instant

The refusal of an [Occurred Instant] later than now, or one that is not an instant, on [Record] or [Change], and of a blank one on [Record] (Operation 3, Operation 12, Operation 45).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-occurred-instant

#### Invalid Outside Participants

The refusal of [Outside Participants] that hold a blank member or one over the string cap, or are not a list of strings, on [Record] or [Change], and of blank ones, omitted or an empty list, on [Record] (Operation 4, Operation 5, Operation 13).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-outside-participants

#### Invalid Inside Participants

The refusal of [Inside Participants] that hold a blank member or one over the string cap, or are not a list of strings, on [Record] or [Change] (Operation 6, Operation 14).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-inside-participants

#### Invalid Direction

The refusal of a [Direction] that is neither inbound nor outbound, on [Record] or [Change] (Operation 15).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-direction

#### Invalid Summary

The refusal of a [Summary] over the string cap, or one that is not a string, on [Record] or [Change] (Operation 7, Operation 16).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-summary

#### Invalid Item References

The refusal of [Item References] that hold a blank member or one over the string cap, or are not a list of strings, on [Record] or [Change] (Operation 8, Operation 17).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-item-references

#### Invalid Outcome

The refusal of an [Outcome] over the string cap, one that is not a string, or one the outcome set does not offer, on [Record] or [Change] (Operation 9, Operation 10, Operation 18).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: invalid-outcome

#### Not Known

The refusal of a communication id no communication carries, or one that is not a string, on [Change], [Withdraw] or [Look Up] (Operation 24).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Not Active

The refusal of [Change] or [Withdraw] on a [Withdrawn] communication (Operation 25, Operation 30).

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-active

#### Storage Failure

The refusal [Record], [Change] or [Withdraw] answers when the database refuses its write after every precondition passes: the Execution Contract's Step 3 failure.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above. -->

[Record]: #record
[Change]: #change
[Withdraw]: #withdraw
[Look Up]: #look-up
[History For]: #history-for
[Communication]: #communication
[Communication Id]: #communication-id
[Medium]: #medium
[Occurred Instant]: #occurred-instant
[Outside Participants]: #outside-participants
[Inside Participants]: #inside-participants
[Direction]: #direction
[Inbound]: #inbound
[Outbound]: #outbound
[Summary]: #summary
[Item References]: #item-references
[Outcome]: #outcome
[Status]: #status
[Active]: #active
[Withdrawn]: #withdrawn
[Invalid Medium]: #invalid-medium
[Invalid Occurred Instant]: #invalid-occurred-instant
[Invalid Outside Participants]: #invalid-outside-participants
[Invalid Inside Participants]: #invalid-inside-participants
[Invalid Direction]: #invalid-direction
[Invalid Summary]: #invalid-summary
[Invalid Item References]: #invalid-item-references
[Invalid Outcome]: #invalid-outcome
[Not Known]: #not-known
[Not Active]: #not-active
[Storage Failure]: #storage-failure

---

## Standards references

Communication is a primitive with no regulatory anchor. It inherits from:

- **Health Level Seven, Fast Healthcare Interoperability Resources — the Communication resource** — a record of a communication that occurred, carrying its medium, its sender and recipients, when it was sent and what it is about; this atom keeps the same core, takes the word medium from it, and leaves a communication still to be made (the Communication Request resource) to Calendar Event *(forthcoming)*.
- **Daniel Jackson, *The Essence of Software*** — the concept as a freestanding, composable unit of software design.

---

## Status

`done — 2026-11-17` — see the Ledger.

## Ledger

```
status: done — 2026-11-17
formal: verified — communication.als + 15 twins (the static data model: State 1 and 3, Identity 3 and 4, Operation 2, 3 and 10 read as what every version carries, Operation 19 through 22, Invariant 1.1 checked on every version a sequence of admitted calls leaves, Identity 1 and 2 caught by the Identity 3 and 4 checks, Identity 6, 8, 10 and 12 by the Operation 19 check); communication.tla + 45 twins (across steps, under medium and outcome sets the deployment may change between calls: State 4, Invariant 2.1 and 3.1, Operation 1 through 19 and 23 through 45, State 2 read through Operation 19, Identity 7, 9, 11 and 13 through Operation 2, 10 and 38, the other half of Operation 36 read from the terms history and History For); on the maintainer's ruling of 2026-11-09 (both models; only the writing vetoes one), neither vetoed; Identity 5 (the implementation's id scheme) cannot be stated, 2026-11-19
last gate: 2026-11-17 — Final Critique 3, a delta round, frozen at 4aa45fb6 — foundational count 0 after the blind second triage, clean, no sample

open: none
```

## Decisions

Decisions are kept in [the pattern's history](./communication.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/communication.md`.

NOTE: End of Communication.

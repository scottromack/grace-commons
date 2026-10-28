---
title: Message Preference
parent: Atomic Concepts
has_toc: true
toc: true
---

# Message Preference

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Message Preference records how each principal (the person or account the messages are for) wants delivery shaped — which channels, how often at most, what quiet hours, what format. It is strictly about the envelope. Whether the principal wants the information at all is a subscription question; whether the system may contact them at all is a legal-permission question; both live elsewhere. This atom answers only *given that we are going to deliver, how should the delivery look?*

One record per principal is in force at a time. Updating means a new record, with the prior one retired in the same operation. Suspending pauses delivery without touching the stored values, so resuming is a fresh set that replays them. Deleting retires the record outright. Nothing is ever removed through this atom's own surface, so the full history of how a principal's preferences changed stays queryable — a separate retention pattern may still dispose on its own declared schedule.

Each record also carries the channel vocabulary it was validated against, stamped at creation from the list of channels the deployment allowed at that moment. That is what makes every record provable from the record itself, with no configuration artifact and no second clock, and what keeps a historical record verifiable after the deployment's channel declaration moves on.

The pattern stores preference values without interpreting them: what a frequency cap or a quiet-hours window means is the delivery system's call. It underlies notification-settings pages, opt-out and frequency compliance, and the audit trail of preference changes.

---

## Intent

WHY:
Every system that pushes information to people accumulates two questions it must not confuse. *Should this principal hear about this class of thing at all?* is topic interest, and separately legal permission. *Given that delivery is going ahead, what shape should delivery take?* is this atom. A principal may want email and not SMS, at most five a day, silence between 10pm and 7am, plain text rather than rich. None of those is a decision about whether to deliver.

So the atom owns the per-principal record of delivery-shaping values and the lifecycle of that record, and nothing else. It does not deliver, does not consult subscriptions, does not evaluate legal permission, and does not interpret any value it stores. What it enforces is structural: one record in force per principal, every channel key drawn from a declared vocabulary, and values that never change once written.

The three states each answer a different operational question. Active: the principal has stated preferences and delivery proceeds under them. Suspended: the principal paused delivery without modifying the values, so a composing fanout observes the pause and suppresses. Deleted: the record is no longer in force, whether superseded by a new set or retired explicitly. Suspended is deliberately not the same as active-with-everything-opted-out — a suspension preserves the vocabulary, an opt-out destroys it, and the two mean different things to an auditor reconstructing what the principal intended.

Updates are not retroactive in the sense the atom commits to. A new set produces a new record and retires the prior one; no prior record's values change, and no caller's captured copy is touched. A fanout that captured values at queue time keeps delivering under them. The timestamps are sufficient for any composing pattern to reconstruct which record governed any past moment, which is the whole audit story.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a preference record by the preference id.
Identity 2: The host MUST allocate a preference id at the seam.
Identity 3: The transition MUST NOT allocate a preference id.
Identity 4: The atom MUST NOT reuse a preference id.
Identity 5: The atom MUST NOT change a preference id.
Identity 6: The atom MUST NOT identify a preference record by the principal reference.
Identity 7: The atom MUST NOT identify a preference record by the principal reference and the set instant.
Identity 8: The atom MUST NOT interpret a principal reference.
Identity 9: The atom MUST NOT normalize a principal reference.
Identity 10: The atom MUST match a principal reference exactly.
Deleted: Identity 11. Execution Contract Logic confinement 13 owns it.
```

Term preference id: the opaque value naming one preference record — a [Preference Id]; host-allocated at the seam, never reused.

Term principal reference: the opaque reference naming the principal whose preferences the record holds — a [Principal Reference]; compared by exact equality.

### State

```
State 1: EVERY preference record MUST stand in EXACTLY ONE OF active, suspended, deleted.
State 2: EVERY preference record MUST carry preference id, principal reference, declared channels, set instant and status.
State 3: A preference record MUST carry EVERY preference field the [Set] call supplied.
State 4: A preference record MUST NOT carry a preference field the [Set] call omitted.
State 5: A preference record MUST carry metadata the [Set] call supplied.
State 6: A preference record that has stood in suspended MUST carry suspension instant.
State 7: A preference record that has never stood in suspended MUST NOT carry suspension instant.
State 8: A deleted preference record MUST carry deletion instant.
State 9: [Suspend] MUST stamp suspension instant from the injected now.
State 10: [Delete] MUST stamp deletion instant from the injected now.
State 11: [Set] MUST stamp set instant from the injected now.
State 12: A supersession MUST stamp deletion instant on the prior preference record from the injected now.
State 13: A preference record currently in effect MUST NOT carry deletion instant.
State 14: The atom MUST NOT offer a suspended-to-active transition.
State 15: The atom MUST NOT offer a deleted-to-active transition.
State 16: The atom MUST NOT offer a deleted-to-suspended transition.
State 17: The atom MUST NOT remove a preference record from the database.
State 18: The atom MUST NOT hold a notification.
State 19: The atom MUST NOT hold a topic subscription.
State 20: The atom MUST NOT hold a legal permission.
```

Term status: active | suspended | deleted — in force, paused, or retired and terminal.

Term channel preferences: the optional map from a declared channel name to an opaque per-channel preference value — a [Channel Preferences].

Term frequency limit: the optional opaque value carrying the principal's frequency cap — a [Frequency Limit].

Term quiet hours: the optional opaque value carrying the windows delivery should skip — a [Quiet Hours].

Term format: the optional opaque value carrying format preferences — a [Format].

Term metadata: the optional opaque payload the atom stores unchanged — a [Metadata]; deployment context, never a preference field.

Term declared channels: the declared channel set stamped onto a preference record at [Set] — a [Declared Channels]; the record's own validation context.

Term set instant: the instant the preference record was created — a [Set Instant].

Term suspension instant: the instant the preference record was paused — a [Suspension Instant].

Term deletion instant: the instant the preference record was retired — a [Deletion Instant].

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 5. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Capability requirement 6: The deployment MUST supply the preference records PER Execution Contract Database 1 through 4, Execution Contract Database 6, Execution Contract Database 7, Execution Contract Refusal 1 and Execution Contract Conformance 9.
Capability requirement 7: The deployment MUST disclose the fanout-on-no-record policy.
Capability requirement 8: The deployment MUST supply the declared channel set at the seam.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
Deleted: Clock semantics 4. Capability requirement 5 owns it.
```

### Operations

```
set(principal_ref, optional channel_preferences, optional frequency_limit, optional quiet_hours, optional format, optional metadata)
  answers preference_id
  refuses invalid-request | undeclared-channel | storage-failure

suspend(preference_id)
  answers ok
  refuses not-known | not-active | storage-failure

delete(preference_id)
  answers ok
  refuses not-known | already-deleted | storage-failure

current_for(principal_ref)
  answers preference_record | none

read(preference_id)
  answers preference_record | not-known
```

```
Operation 1: [Set] MUST record EXACTLY ONE preference record per successful call.
Operation 2: [Set] MUST stand the new preference record in active.
Operation 3: [Set] MUST answer the preference id.
Operation 4: IF principal reference EQUALS blank THEN [Set] MUST answer invalid-request.
Operation 5: IF EVERY preference field EQUALS blank THEN [Set] MUST answer invalid-request.
Operation 6: [Set] MUST read an empty channel preferences map as an omitted preference field.
Operation 7: [Set] MUST NOT record an empty channel preferences map.
Operation 8: IF a channel preferences key IS NOT IN the injected declared channel set THEN [Set] MUST answer undeclared-channel.
Deleted: Operation 9. Execution Contract Refusal 1 owns it.
Operation 10: [Set] MUST NOT interpret a preference field.
Operation 11: [Set] MUST NOT interpret metadata.
Operation 12: [Set] MUST NOT read metadata as a preference field.
Operation 13: [Set] MUST NOT compare the preference fields of two preference records.
Operation 14: IF a preference record currently in effect EXISTS for the principal reference THEN [Set] MUST stand the prior preference record in deleted.
Deleted: Operation 15. Execution Contract Database 1 owns it.
Operation 16: IF the database refuses the write THEN [Set] MUST answer storage-failure.
Operation 17: IF no preference record EXISTS for the preference id THEN [Suspend] MUST answer not-known.
Operation 18: IF the preference record's status EQUALS suspended THEN [Suspend] MUST answer not-active.
Operation 19: IF the preference record's status EQUALS deleted THEN [Suspend] MUST answer not-active.
Operation 20: [Suspend] MUST stand the preference record in suspended.
Operation 21: [Suspend] MUST NOT change a preference field.
Operation 22: [Suspend] MUST accept the preference id as the whole authorization.
Operation 23: IF the database refuses the write THEN [Suspend] MUST answer storage-failure.
Operation 24: IF no preference record EXISTS for the preference id THEN [Delete] MUST answer not-known.
Operation 25: IF the preference record's status EQUALS deleted THEN [Delete] MUST answer already-deleted.
Operation 26: [Delete] MUST stand the preference record in deleted.
Operation 27: [Delete] MUST NOT remove the preference record from the database.
Operation 28: [Delete] MUST accept the preference id as the whole authorization.
Operation 29: IF the database refuses the write THEN [Delete] MUST answer storage-failure.
Deleted: Operation 30. Execution Contract Database 1 and Execution Contract Database 3 own it.
Operation 31: [Current For] MUST answer EXACTLY ONE OF the preference record currently in effect, none.
Operation 32: [Current For] MUST NOT answer a deleted preference record.
Operation 33: [Current For] MUST NOT refuse a blank input.
Operation 34: [Read] MUST answer EXACTLY ONE OF the whole preference record, not-known.
Operation 35: [Read] MUST answer a deleted preference record in full.
Operation 36: [Read] MUST NOT refuse a blank input.
Operation 37: [Current For] MUST NOT write.
Operation 38: [Read] MUST NOT write.
Deleted: Operation 39. Capability requirement 1 owns it.
Deleted: Operation 40. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 41. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 42. Clock dependence 1 owns it.
Deleted: Operation 43. Clock dependence 2 owns it.
```

NOTE: open 2026-10-22-a — Operation 21 and Invariant 6.2 state one proposition, and Invariant 8.1 restates Instance 2 without its one-instance scope; which label of each pair stands is not settled.

Term preference field: channel preferences | frequency limit | quiet hours | format — the four values a [Set] call must carry one of; metadata is not one.

Term currently in effect: a preference record whose status EQUALS active OR in suspended — what at-most-one ranges over and what [Current For] answers.

Term supersession: the one operation in which a [Set] call stands a principal's prior preference record in deleted and records the new preference record.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term guard: a transition's precondition test; reads the stored preference record and the call's inputs, and writes nothing.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Set] | principal present, a preference field present, every key declared, database accepts, no prior | the new preference id | one record lands in [Active] (Operation 1, Operation 2) |
| [Set] | as above, with a prior currently in effect | the new preference id | the new record lands in [Active], the prior moves to [Deleted] (Operation 14) |
| [Set] | blank principal reference, or no preference field, or an empty map as the only one | [Invalid Request] | none (Operation 4 through 6) |
| [Set] | a channel preferences key outside the injected set | [Undeclared Channel] | none (Operation 8, Execution Contract Refusal 1) |
| [Set] | the injected declared channel set is degenerate | no conforming outcome — fail-stop | none (Instance 13 through 16) |
| [Suspend] | id names a record in [Active] | ok | [Active] → [Suspended], suspension instant stamped (Operation 20, State 9) |
| [Suspend] | id names a record in [Suspended] or [Deleted] | [Not Active] | none (Operation 18, Operation 19) |
| [Delete] | id names a record in [Active] or [Suspended] | ok | → [Deleted], deletion instant stamped (Operation 26, State 10) |
| [Delete] | id names a record in [Deleted] | [Already Deleted] | none (Operation 25) |
| either write | id names nothing | [Not Known] | none (Operation 17, Operation 24) |
| any write | database refuses | [Storage Failure] | none (Operation 16, Operation 23, Operation 29) |
| [Current For] | a record currently in effect matches the principal | that record, in full | none — the call reads (Operation 31, Operation 37) |
| [Current For] | nothing in effect, blank argument included | [None] | none (Operation 32, Operation 33) |
| [Read] | id names a record in any state | that record, in full | none — [Deleted] included (Operation 34, Operation 35) |
| [Read] | id names nothing, blank argument included | [Not Known] | none (Operation 36) |

### Invariants

- **Invariant 1 — Preference record immutability.**
  ```
  Invariant 1.1: A recorded preference record's preference id, principal reference, declared channels and set instant MUST NOT change.
  Invariant 1.2: A recorded preference field MUST NOT change.
  Invariant 1.3: A recorded metadata MUST NOT change.
  Invariant 1.4: A preference field a [Set] call omitted MUST NOT appear later.
  Invariant 1.5: A recorded suspension instant MUST NOT change.
  Invariant 1.6: A recorded deletion instant MUST NOT change.
  Invariant 1.7: A preference record MUST NOT carry a mutable field beyond status.
  ```
- **Invariant 2 — Status monotonicity.**
  ```
  Deleted: Invariant 2.1. State 1 owns it.
  Deleted: Invariant 2.2. State 1 and Invariant 2.3 own it.
  Invariant 2.3: A status MUST NOT move from suspended to active.
  Invariant 2.4: A status MUST NOT move from deleted to active.
  Invariant 2.5: A status MUST NOT move from deleted to suspended.
  ```
- **Invariant 3 — At most one preference record currently in effect per principal.**
  ```
  Invariant 3.1: Two preference records currently in effect MUST NOT share a principal reference.
  ```
- **Invariant 4 — Supersession atomicity.**
  ```
  Deleted: Invariant 4.1. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4.3. Execution Contract Database 1 and Execution Contract Database 3 own it.
  Deleted: Invariant 4.4. Execution Contract Database 1 and Execution Contract Database 3 own it.
  ```
- **Invariant 5 — Channel preferences reference declared channels, and the proof is on the record.**
  ```
  Invariant 5.1: EVERY channel preferences key MUST stand in the preference record's own declared channels.
  Deleted: Invariant 5.2. Check 5.1 owns it.
  Invariant 5.3: A change to the deployment's declared channel set MUST NOT change a recorded declared channels.
  ```
- **Invariant 6 — Suspension is value-preserving.**
  ```
  Invariant 6.1: [Suspend] MUST change status and suspension instant alone.
  Invariant 6.2: [Suspend] MUST NOT change a preference field.
  Invariant 6.3: [Suspend] MUST NOT change principal reference.
  ```
- **Invariant 7 — Current For determinism.**
  ```
  Invariant 7.1: [Current For] MUST answer the preference record currently in effect for the principal reference.
  Invariant 7.2: [Current For] MUST answer none ONLY IF no preference record currently in effect EXISTS for the principal reference.
  Invariant 7.3: [Current For] MUST rest on the preference record set alone.
  ```
- **Invariant 8 — No id reuse.**
  ```
  Invariant 8.1: Two preference records MUST NOT share a preference id.
  ```
- **Invariant 9 — Record durability over this atom's own surface.**
  ```
  Invariant 9.1: The atom MUST NOT offer a removal surface.
  Deleted: Invariant 9.2. State 17 and Execution Contract Database 4 own it.
  Invariant 9.3: [Read] MUST answer a deleted preference record.
  ```
- **Invariant 10 — Validation-context self-containment.**
  ```
  Invariant 10.1: EVERY preference record MUST carry declared channels.
  Invariant 10.2: A recorded declared channels MUST NOT stand empty.
  Deleted: Invariant 10.3. Check 5.1 owns it: a conformance check reads the records alone.
  Invariant 10.4: The atom MUST NOT hold the declared channel set's governance.
  ```
- **Temporal property — Timestamp ordering.**
  ```
  Temporal property 1: IF suspension instant DOES NOT EQUAL blank THEN set instant MUST NOT EXCEED suspension instant.
  Temporal property 2: IF deletion instant DOES NOT EQUAL blank THEN set instant MUST NOT EXCEED deletion instant.
  Temporal property 3: IF suspension instant DOES NOT EQUAL blank AND deletion instant DOES NOT EQUAL blank THEN suspension instant MUST NOT EXCEED deletion instant.
  Deleted: Temporal property 4. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
  Deleted: Temporal property 5. Execution Contract Logic confinement 7 owns it: the deployment owns the clock's guarantees, the implementation none of them.
  ```

NOTE: watch the modal with no temporal scope (State 1, Invariant 2.3).

Immutability and durability together give *auditability* — the full history of every principal's preferences is provable, with no gap but what a separate retention pattern disposes of on its own declared schedule. At-most-one-in-effect and supersession atomicity together give *unambiguous currency* — at any moment a principal has at most one record governing delivery, and the moment of transition is recorded. Suspension being value-preserving gives *cheap resumption* — a principal who pauses and later returns loses nothing but a channel the deployment withdrew in the meantime.

### Database instance model

```
Deleted: Instance 1. Execution Contract Database 7 owns it.
Instance 2: Two preference records in one database instance MUST NOT share a preference id.
Instance 3: The atom MUST read one principal reference in two database instances as two principals.
Instance 4: A database name MUST name one database instance.
Instance 5: The atom MUST NOT accept a database name as an input.
Instance 6: A preference record MUST NOT carry a database name.
Instance 7: The atom MUST NOT hold the declared channel set.
Instance 8: The atom MUST NOT offer an action that changes the declared channel set.
Instance 9: The host MUST resolve the declared channel set at the seam.
Instance 10: The host MUST inject the declared channel set into EVERY [Set] transition.
Instance 11: The host MUST NOT inject a degenerate declared channel set.
Instance 12: [Set] MUST stamp the injected declared channel set onto the new preference record as declared channels.
Instance 13: IF the injected declared channel set is degenerate THEN [Set] MUST NOT validate channel preferences.
Instance 14: IF the injected declared channel set is degenerate THEN [Set] MUST NOT write.
Instance 15: IF the injected declared channel set is degenerate THEN [Set] MUST NOT answer an outcome the signature block carries.
Instance 16: IF the injected declared channel set is degenerate THEN the deployment MUST surface the fault.
```

Term preference record: one principal's stated delivery shaping — the record this atom holds.

Term database instance: one named database a call is routed to; preference id uniqueness ranges over one instance.

Term database name: the identifier naming one database instance — a [Database Name]; deployment routing, never an input and never a stored field.

Term declared channel set: the named delivery surfaces a preference record in this deployment may reference; deployment configuration the host resolves, never state this atom holds.

Term degenerate: a declared channel set that is empty, that repeats a channel name, OR that carries a blank channel name.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading, the preference id and the declared channel set here.

Term transition: the atom's evaluation of one call against the preference records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

## Examples

Three lifecycle scenarios trace one principal (`user_u`) through onboarding, vacation suspend and account closure — the chain `pref_001 → pref_088 → pref_141`. The rejection paths and the regulated scenarios use their own principals and ids. Each deployment below carries `["email", "sms", "push", "in-app"]` on its configuration surface, injected at the seam for each set call, unless the scenario says otherwise.

### Consumer SaaS (Software-as-a-Service) — onboarding preferences

A new user of a productivity app picks preferences on the settings page: email for daily digests, push for real-time mentions, no SMS, plain text. `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "opt-out"}, format: "plain")` → `pref_001`, in [Active].

When the composition fires an event `user_u` is subscribed to, the fanout calls `current_for(user_u)` → `pref_001`, reads the channel preferences, and creates one Notification per channel not opted out.

Three weeks later the user adds SMS for urgent items and a daily cap: `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "urgent-only"}, frequency_limit: {per_day: 10}, format: "plain")` → `pref_088`. `pref_001` moves to [Deleted] with deletion instant. `current_for(user_u)` now answers `pref_088`.

### Marketing platform — vacation suspend

A newsletter subscriber going away for two weeks wants delivery paused without losing the settings. `suspend(pref_088)` → ok; the record moves [Active] → [Suspended] with suspension instant. `current_for(user_u)` still answers the record, and the fanout reads [Suspended] as suppress.

On return, the settings page reads the suspended record's values and offers them as defaults; the subscriber confirms and the page calls `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "urgent-only"}, frequency_limit: {per_day: 10}, format: "plain")` → `pref_141`. `pref_088` moves to [Deleted], keeping its suspension instant and its original set instant. Full delivery resumes under the new record.

### Account closure — explicit deletion

A user closes their account, and the closure flow calls `delete(pref_141)` → ok. The record moves to [Deleted]; `current_for(user_u)` answers none. The fanout, finding nothing in effect, follows the deployment's declared fanout-on-no-record policy.

`pref_001`, `pref_088` and `pref_141` all remain in the database. A later access request for `user_u`'s preference history filters the database on `principal_ref = user_u` and returns the full chronological chain; each record's content is what `read(preference_id)` answers for it — [Preference Id], [Principal Reference], the stated preference fields, [Declared Channels], [Set Instant], [Status] and the applicable lifecycle timestamps.

### Rejection paths

A set carrying nothing: `set(principal_ref: user_u)` → invalid-request. No id is issued, no record enters the database (Operation 5).

A set naming a channel outside the injected set: `set(principal_ref: user_v, channel_preferences: {email: "preferred", carrier-pigeon: "backup"})` → undeclared-channel. The reason names the vocabulary error as its own class, so the composing system knows to fix the channel name rather than the call shape (Operation 8).

A retry after a network timeout: `suspend(pref_001)` → not-active; `pref_001` is [Deleted] (Operation 19).

A duplicate teardown: `delete(pref_141)` → already-deleted; nothing changes (Operation 25). A delete on a *[Suspended]* record, by contrast, answers ok — that transition is admitted (Operation 26).

### Regulated adversarial scenarios

- **Regulator audit — honouring an opt-out under CAN-SPAM (the US Controlling the Assault of Non-Solicited Pornography And Marketing Act — the federal commercial-email law).** A regulator asks whether a marketing platform honoured `user_v`'s email opt-out after `2026-03-14`. The investigator enumerates the principal's records: `pref_201` with `email: "preferred"` in effect from `2025-08-01` to `2026-03-14`; `pref_244` with `email: "opt-out"` in effect from `2026-03-14` onward. For any email alleged after that date, the fanout would have called `current_for(user_v)` and read `pref_244`. A delivery against that record is either a fanout conformance failure or a composing-layer failure — either way the preference record is the structural evidence of what the principal stated at the time. Invariant 1.2 and Temporal property 2 are the rebuttal: the record was created then, with those values, and does not change.
- **Disputed delivery — quiet hours under TCPA (the US Telephone Consumer Protection Act — the federal law restricting unsolicited calls and texts).** A principal reports an SMS at 11:30pm against quiet hours of 10pm–7am. The investigator reconstructs which record was in effect at the delivery instant (Check 2.1), takes its preference id, and calls `read(preference_id)`. The record shows `quiet_hours: {start: "22:00", end: "07:00", timezone: "America/Los_Angeles"}`. Whether the fanout observed them is the composing-layer question; that the principal stated them is provable from the database.
- **Breach investigation — which principals' preferences may have been corrupted.** An incident on `2026-04-01T05:00Z` exposed the database to possible unauthorized modification. The investigator queries for any record with set instant, suspension instant or deletion instant inside the window. Invariant 1.1 and State 17 are the atom-level rebuttal, but as a contract and not as cryptographic enforcement: a record made before the window should not have been altered, and the atom exposes alteration only insofar as the underlying database does. Sealing against post-hoc tampering belongs to a composed [Tamper Evidence](./tamper-evidence.md); without it, the bare atom's records support forensic reconstruction but do not prove that no out-of-band write occurred (Non-goal 28, Non-goal 29).

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the preference records' stored fields. The audit surface is the database, not the action surface: the action surface answers *what does the atom do at runtime*, the audit surface answers *what does the atom commit to recording*.

### Conformance checks

```
Check 1.1: An auditor MUST enumerate EVERY preference record's preference id, principal reference, set instant, status, suspension instant and deletion instant from the database (Invariant 9.1).
Check 1.2: An auditor MUST find EVERY supplied preference field on the preference record (Invariant 1.2, State 3).
Check 2.1: An auditor MUST reconstruct the preference record currently in effect for a principal reference at a past instant from set instant, status and deletion instant (Invariant 3.1).
Check 2.2: An auditor MUST read a currency interval as half-open from set instant to deletion instant (State 11, State 12).
Check 3.1: An auditor MUST find no two preference records currently in effect sharing a principal reference (Invariant 3.1).
Deleted: Check 4.1. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.2. State 11 and State 12 own it: one injected now stamps both instants of a supersession.
Deleted: Check 4.3. Capability requirement 5 owns it; a deployment obligation is not an auditor's check.
Check 5.1: An auditor MUST find EVERY channel preferences key in the preference record's own declared channels (Invariant 5.1, Invariant 10.1).
Check 5.2: An auditor MUST mark an absent declared channels a conformance failure (Invariant 10.1, Invariant 10.2).
Deleted: Check 6.1. Execution Contract Conformance 9 owns it.
Deleted: Check 6.2. Capability requirement 7 owns it; a deployment obligation is not an auditor's check.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT route a notification.
Non-goal 2: The atom MUST NOT fire an event.
Non-goal 3: The atom MUST NOT create a notification.
Non-goal 4: The atom MUST NOT deliver a notification.
Non-goal 5: A deployment needing fanout MUST compose a preference-aware fanout pattern.
Non-goal 6: The atom MUST NOT evaluate a legal permission.
Non-goal 7: A deployment needing a legal-permission decision MUST compose Consent.
Non-goal 8: The atom MUST NOT evaluate a topic subscription.
Non-goal 9: A deployment needing a topic-interest decision MUST compose Subscription.
Non-goal 10: The atom MUST NOT carry a transport mechanism.
Non-goal 11: The atom MUST NOT interpret a preference field's contents.
Non-goal 12: The atom MUST NOT declare which channel names are valid.
Non-goal 13: The atom MUST NOT record who changed the declared channel set.
Non-goal 14: A deployment needing channel-set attribution MUST compose Audit Trail.
Non-goal 15: The atom MUST NOT hold a default preference for a principal carrying no preference record.
Non-goal 16: The atom MUST NOT offer a resume action.
Non-goal 17: The atom MUST NOT carry a deletion reason on a preference record.
Non-goal 18: A deployment needing a recorded deletion reason MUST compose Actor Identity.
Non-goal 19: The atom MUST NOT detect a conflicting preference.
Non-goal 20: The atom MUST NOT offer a bulk action.
Non-goal 21: The atom MUST NOT hold a per-topic preference.
Non-goal 22: The atom MUST NOT record who called an action.
Non-goal 23: The atom MUST NOT gate an action beyond the identifier the action accepts.
Non-goal 24: A deployment needing richer authorization MUST compose Permissions.
Non-goal 25: The atom MUST NOT expire a preference record.
Non-goal 26: The atom MUST NOT redact a preference record.
Non-goal 27: A deployment needing lawful disposal MUST compose Retention Window.
Non-goal 28: The atom MUST NOT seal a preference record against modification.
Non-goal 29: A deployment needing court-admissible records MUST compose Tamper Evidence.
Non-goal 30: The atom MUST NOT guarantee a preference id unique across database instances.
Non-goal 31: The atom MUST NOT push an update into queued work.
Non-goal 32: The atom MUST NOT change a caller's captured copy of a preference record.
```

NOTE: the owners — the composing pattern (Non-goal 1 through 5; Non-goal 11, Composition note 8); [Consent](./consent.md) (Non-goal 6, Non-goal 7, Composition note 6; State 20); [Subscription](./subscription.md) (Non-goal 8, Non-goal 9, Composition note 7; State 19); [Audit Trail](../compositions/audit-trail.md) and [Actor Identity](./actor-identity.md) (Non-goal 13, Non-goal 14; Non-goal 17, Non-goal 18); [Actor Identity](./actor-identity.md) (Non-goal 22); [Retention Window](./retention-window.md) (Non-goal 25, Non-goal 26, Non-goal 27); [Tamper Evidence](./tamper-evidence.md) (Non-goal 28, Non-goal 29); [Notification](./notification.md) (State 18).

## Edge cases

### Clock dependence

```
Clock dependence 1: A guard MUST NOT read now.
Clock dependence 2: A rejection MUST NOT rest on now.
```

### Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Concurrency 2: The recorded timestamps MUST witness the serialization order.
Deleted: Concurrency 3. Execution Contract Database 1 owns it.
Concurrency 4: A composing pattern MUST own how competing callers reach the atom.
```

### Channel set evolution

```
Channel set evolution 1: The deployment MUST own the declared channel set's change history.
Channel set evolution 2: A change to the declared channel set MUST NOT change a recorded preference record.
Channel set evolution 3: An auditor MUST read a historical channel preferences key against the preference record's own declared channels.
Channel set evolution 4: A composing pattern MUST own how a preference record naming a withdrawn channel shapes delivery.
```

### Opaque input bounds

```
Opaque input bound 1: The atom MUST store EVERY opaque input as supplied.
Opaque input bound 2: The atom MUST NOT bound an opaque input's size.
Opaque input bound 3: The deployment MUST own an opaque input's size bound.
Opaque input bound 4: The deployment MUST disclose the opaque input size bound.
```

### Re-creation after deletion

```
Re-creation 1: A [Set] call following a [Delete] MUST record a fresh preference record.
Re-creation 2: The two preference records MUST stand in the database independently.
Re-creation 3: The retired preference id MUST NOT return.
```

### Resumption

```
Resumption 1: A composing pattern MUST read a suspended preference record's values through [Current For].
Resumption 2: A composing pattern MUST replay the values through a fresh [Set] call.
Resumption 3: [Set] MUST validate a replayed channel preferences key against the injected declared channel set.
Resumption 4: IF a replayed channel name IS NOT IN the injected declared channel set THEN a composing pattern MUST drop the channel name.
```

### Supersession atomicity

```
Deleted: Supersession atomicity 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Supersession atomicity 2. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 3. Execution Contract Database 2 owns it.
Deleted: Supersession atomicity 4. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 5. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 6. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 7. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Supersession atomicity 8. Execution Contract Database 3 owns it.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST call [Current For] when a notification is queued.
Composition note 3: A composing pattern MUST capture the preference record's values at queue time.
Composition note 4: A composing pattern MUST read a suspended preference record as delivery-suppress.
Composition note 5: A composing pattern MUST own the fanout-on-no-record policy.
Composition note 6: A composing pattern MUST NOT read a preference record BEFORE the legal-permission decision.
Composition note 7: A composing pattern MUST NOT read a preference record BEFORE the topic-interest decision.
Composition note 8: A composing pattern MUST interpret frequency limit at delivery time.
Composition note 9: A composing pattern MUST interpret quiet hours at delivery time.
Composition note 10: A composing pattern MUST interpret format at delivery time.
Composition note 11: A composing pattern MUST interpret a per-channel preference value at delivery time.
Composition note 12: A composing pattern MUST apply a deployment default for an omitted preference field.
Deleted: Composition note 13. Channel set evolution 1 owns it: the declared channel set and its change history are the deployment's.
```

NOTE: composing patterns — [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a principal; an auditor; the database; a preference record; a status; a supersession; a write; a rejection; the recorded timestamps; a database name.

Term records: preference record — one principal's stated delivery shaping, carrying preference id, principal reference, declared channels, set instant, status, the supplied preference fields and metadata, and, once stamped, suspension instant and deletion instant.

Term record verbs: route, share, read, name, accept, carry, hold, offer, resolve, inject, stamp, validate, write, answer, surface, identify, allocate, reuse, change, interpret, normalize, match, record, stand, compare, remove, refuse, supply, rest, appear, move, call, own, enumerate, find, reconstruct, mark, disclose, fire, create, deliver, compose, evaluate, declare, detect, gate, expire, redact, seal, guarantee, push, replay, drop, witness, store, bound, return, capture, apply.

Term value sets: status = active | suspended | deleted. preference field = channel preferences | frequency limit | quiet hours | format.

Term bounds: opaque input size bound (the deployment's cap on a stored opaque value).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: preference record, database instance, database name, declared channel set, degenerate, seam, transition, preference id, principal reference, blank, preference field, currently in effect, supersession, now, business caller, guard, status, channel preferences, frequency limit, quiet hours, format, metadata, declared channels, set instant, suspension instant, deletion instant.

#### Set

The behavior that records a new preference set for a principal. It assigns the host-allocated [Preference Id], stamps [Set Instant], records [Principal Reference], the supplied preference fields and [Metadata], and stamps the seam-injected declared channel set as [Declared Channels]. The new record enters [Active]; any prior record currently in effect moves to [Deleted] (Operation 14). At least one preference field is required (else [Invalid Request]).

Kind: Operation

#### Suspend

The behavior that pauses delivery, moving an [Active] record to [Suspended] and stamping [Suspension Instant] without altering any preference value (Invariant 6). Rejected for a record that is not [Active] ([Not Active]) or an unknown id ([Not Known]).

Kind: Operation

#### Delete

The behavior that retires a record, moving an [Active] or [Suspended] record to terminal [Deleted] and stamping [Deletion Instant]. Rejected for an already-[Deleted] record ([Already Deleted]) or an unknown id ([Not Known]). The record is retained, not removed (Invariant 9).

Kind: Operation

#### Current For

The read-only query returning the unique record currently in effect ([Active] or [Suspended]) for a [Principal Reference], or none if there is none (Invariant 7). Excludes [Deleted] records; never transitions; refuses nothing.

Kind: Operation

#### Read

The read-only query returning the full record for a [Preference Id] in any state ([Active], [Suspended] or [Deleted]), or [Not Known] if no record has that id. Deletion is a state, not a removal; never transitions; refuses nothing.

Kind: Operation

#### Preference Id

The opaque, immutable identity of a preference record, host-allocated at the I/O seam on [Set], never reused (Invariant 8). The principal reference and the preference values are properties of the record, not its identity.

Kind:       Field
Field of:   the preference record
Projection: preference_id

#### Principal Reference

The opaque reference to the principal whose preferences are recorded. Set on [Set], immutable. Equality is exact and the atom normalizes nothing; the at-most-one-in-effect rule (Invariant 3) ranges over it, so canonicalization is the deployment's, at the seam (Execution Contract Logic confinement 13).

Kind:       Field
Field of:   the preference record
Projection: principal_ref

#### Channel Preferences

The optional map from a declared channel name to an opaque per-channel preference value. Set on [Set] if supplied, immutable. Every key must be a member of the record's own [Declared Channels] stamp — the set injected at the seam for that [Set] call (Invariant 5). A supplied-but-empty map is stored as absent.

Kind:       Field
Field of:   the preference record
Projection: channel_preferences

#### Frequency Limit

The optional, opaque deployment-shaped value carrying the principal's frequency cap. Set on [Set] if supplied, immutable; interpreted by the composing fanout pattern, not by the atom.

Kind:       Field
Field of:   the preference record
Projection: frequency_limit

#### Quiet Hours

The optional, opaque deployment-shaped value carrying the windows during which delivery should be suppressed. Set on [Set] if supplied, immutable; interpreted by the composing layer.

Kind:       Field
Field of:   the preference record
Projection: quiet_hours

#### Format

The optional, opaque deployment-shaped value carrying format preferences. Set on [Set] if supplied, immutable; interpreted by the composing layer.

Kind:       Field
Field of:   the preference record
Projection: format

#### Metadata

The optional opaque payload the atom stores unchanged (form version, user-agent, consent-flow id). Set on [Set] if supplied, immutable. Not a preference field: it does not by itself satisfy the at-least-one requirement on [Set].

Kind:       Field
Field of:   the preference record
Projection: metadata

#### Set Instant

The wall-time the record was created, stamped from the seam-injected clock reading at [Set]. Immutable (Invariant 1). The currency-reconstruction key for [Current For] and for audit.

Kind:       Field
Field of:   the preference record
Projection: set_at

#### Status

The record's lifecycle state — [Active], [Suspended] or [Deleted]. Set to [Active] on [Set]; the only mutable field, moving monotonically (Invariant 2).

Kind:       Field
Field of:   the preference record
Projection: status

#### Suspension Instant

The wall-time the record was suspended, stamped at [Suspend]. Absent on a record that has never been [Suspended]; immutable once set, and retained through a later move to [Deleted].

Kind:       Field
Field of:   the preference record
Projection: suspended_at

#### Deletion Instant

The wall-time the record reached [Deleted], stamped at [Delete] or at supersession. Absent unless the record is [Deleted]; immutable once set.

Kind:       Field
Field of:   the preference record
Projection: deleted_at

#### Database Name

The identifier of the database instance; [Preference Id] values are unique within an instance. No action accepts it as a parameter and no record stores it — instance selection and naming live at the deployment-routing layer (Database instance model).

Kind:       Field
Field of:   the database instance
Projection: store_name

#### Declared Channels

The declared channel set injected at the seam for a record's [Set] call and stamped onto the record at creation — the record's own validation context (Invariants 5 and 10). Non-empty; immutable. What the deployment's channel declaration has done since never touches it.

Kind:       Field
Field of:   the preference record
Projection: declared_channels

#### Undeclared Channel

The [Set] rejection when a supplied [Channel Preferences] key is not a member of the seam-injected declared channel set — a vocabulary error with its own remedy (fix the channel name, or take the declaration question to the deployment), distinct from a malformed call's [Invalid Request].

Kind:       Member
Member of:  the Set rejection
Role:       Outcome
Projection: undeclared-channel

#### Storage Failure

The rejection any state-changing action returns when the write fails after all preconditions pass.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Active

The state of a record whose preferences are in force; it shapes any delivery the composing fanout attempts. At most one [Active]-or-[Suspended] record per principal (Invariant 3).

Kind:      Member
Member of: the preference status
Role:      Outcome

#### Suspended

The state of a record whose delivery the principal has paused; preference values are retained unchanged (Invariant 6), so resumption through a fresh [Set] needs no re-statement. Counts toward the at-most-one-in-effect bound.

Kind:      Member
Member of: the preference status
Role:      Outcome

#### Deleted

The terminal state of a record no longer in effect — reached by supersession (a new [Set]) or by explicit [Delete]. Retained as audit evidence and returned by [Read], but excluded from [Current For].

Kind:      Member
Member of: the preference status
Role:      Outcome

#### Invalid Request

The refusal [Set] returns when the request's shape fails — a blank [Principal Reference], or no preference field supplied (an empty [Channel Preferences] map does not count). A [Channel Preferences] key naming an undeclared channel is not this refusal; it is [Undeclared Channel], its own class with its own remedy.

Kind:       Member
Member of:  the Set rejection
Role:       Outcome
Projection: invalid-request

#### Not Known

The refusal [Suspend] or [Delete] returns when the [Preference Id] references no record in the database. Also the read answer [Read] returns for an id no record carries — there, a first-class outcome rather than a rejection.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: not-known

#### Not Active

The refusal [Suspend] returns when the target is not [Active] — that is, [Suspended] or [Deleted]. The single code covers both ([Suspended] never returns to [Active], Invariant 2); a caller distinguishes them through [Read].

Kind:       Member
Member of:  the Suspend rejection
Role:       Outcome
Projection: not-active

#### None

The answer [Current For] returns when no record is currently in effect for the [Principal Reference] — never subscribed to a shape, or every record retired. A first-class outcome, not a rejection, and structurally what a blank argument gets. The composing pattern's fanout-on-no-record policy keys on it, and the deployment must disclose that policy (Composition note 5, Capability requirement 7).

Kind:       Member
Member of:  the Current For answer
Role:       Outcome
Projection: none

#### Already Deleted

The refusal [Delete] returns when the target is already [Deleted]. A [Suspended] record may still be deleted ([Suspended] → [Deleted]).

Kind:       Member
Member of:  the Delete rejection
Role:       Outcome
Projection: already-deleted

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Set]: #set
[Suspend]: #suspend
[Delete]: #delete
[Current For]: #current-for
[Read]: #read
[Preference Id]: #preference-id
[Principal Reference]: #principal-reference
[Channel Preferences]: #channel-preferences
[Frequency Limit]: #frequency-limit
[Quiet Hours]: #quiet-hours
[Format]: #format
[Metadata]: #metadata
[Set Instant]: #set-instant
[Status]: #status
[Suspension Instant]: #suspension-instant
[Deletion Instant]: #deletion-instant
[Database Name]: #database-name
[Declared Channels]: #declared-channels
[Undeclared Channel]: #undeclared-channel
[Storage Failure]: #storage-failure
[Active]: #active
[Suspended]: #suspended
[Deleted]: #deleted
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[None]: #none
[Not Active]: #not-active
[Already Deleted]: #already-deleted

---

## Standards references

- **CAN-SPAM Act (15 U.S.C. section 7701 et seq.)** — requires commercial email senders to honour unsubscribe requests within 10 business days and to provide a working opt-out mechanism in every commercial message. [Channel Preferences] with a channel-level opt-out value, combined with the composing fanout's enforcement, is the structural mechanism; immutability and durability produce the audit record enforcement requires.
- **Telephone Consumer Protection Act (TCPA, 47 U.S.C. section 227)** — restricts automated and unsolicited calls and SMS, including frequency caps and time-of-day restrictions. [Frequency Limit] and [Quiet Hours], combined with the composing fanout's enforcement, are the mechanism for honouring these per principal.
- **GDPR (EU General Data Protection Regulation — the European Union's data-privacy law) Article 17** — the right to erasure: a deployment may have to erase a principal's preference records. Erasure is a composed retention pattern's declared and recorded act, outside the atom's own surface, which removes nothing (Invariant 9.1, Non-goal 26, Non-goal 27).
- **GDPR Article 7(3)** — withdrawal of consent must be as easy as giving it. Article 7(3) is a *consent* obligation and belongs to [Consent](./consent.md), which owns the legal-permission axis. This atom satisfies an analogous *preference-update ease* principle: a principal changing channels, tightening a cap or pausing delivery calls [Set] or [Suspend] — the same surface that established the preferences. The ease claim here is scoped to shaping, not to consent withdrawal.
- **GDPR Article 21(2)** — right to object to processing for direct marketing; the objection must terminate marketing processing without delay. Full compliance is a two-atom obligation: this atom records the delivery-preference signal of the objection, encoded as the deployment's per-channel opt-out value inside [Channel Preferences], while [Consent](./consent.md) revokes the corresponding legal permission. A deployment that records the opt-out here without updating consent has not discharged Article 21.
- **ePrivacy Directive (2002/58/EC, as amended)** — consent and preference requirements for electronic communications in the EU. Marketing communication preferences fall under this directive's surface; this atom's record is the artifact a preferences page produces.
- **CASL (Canadian Anti-Spam Legislation)** — analogous to CAN-SPAM with stricter consent requirements; honouring per-principal channel preferences is the mechanism.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Channel Preferences], [Frequency Limit], [Quiet Hours] and [Format] as opaque deployment-vocabulary fields.
- **Eiffel's design-by-contract** — preconditions on [Set], [Suspend] and [Delete]; named rejection reasons.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — message-preference.tla + 1 twin, 2026-06-03
last gate: 2026-10-22 — Final Critique 9, the council's first round on the page and the first on its Store-contract rewrite (cac3848) and the refusal-order sweep (c2f4e9a), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 33ccb6d); the round rests on three counted passes — foundational count 3 after triage (13 reports: 5 standing, merged into 3; 7 sent down; 1 rejected), all Kind A: a count that could never fall broke at the first disposal by the Retention Window the page sends lawful disposal to; two conformance checks asked for a wiring declaration and a deployment's disclosure that no preference record carries; and two status rules, read as written, obliged every active or suspended record to move, which no action does on its own; 11 refining reports, 6 rhetorical reports; not clean; every foundational finding cured, every refining finding cured, routed or answered; 2026-08-26 — Final Critique 8, fresh reader — clean

open:
- 2026-10-22-a · refining · Operation 21; Invariant 6.2; Instance 2; Invariant 8.1 · Operation 21 and Invariant 6.2 state one proposition word for word, and Invariant 8.1 restates Instance 2 without the one-instance scope Term database instance gives both, so the page pays for two propositions twice (GRACE-lang Authority 3) → one owner each, the survivor checked against the citers and the model
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/message-preference.md`; the migration that got it here is in [its history](./message-preference.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the preference store supplied under Execution Contract Store 1 through 4 (Capability requirement 6), and the sixteen rules that restated them tombstoned to their owner — Operation 15 and Invariant 4.1, the new record and the supersession committed in one operation, and Invariant 4.2 and Concurrency 3, no reader observing two records in effect for one principal or a torn record, to Store 1; Invariant 4.3 and 4.4, a refused supersession leaving the prior record in effect and recording no new one, Operation 30, a refused write leaving the store as the call found it, and Supersession atomicity 4 through 7, no crash inside [Set], [Suspend] or [Delete] leaving part of its writes, to Store 1 and Store 3; Supersession atomicity 8, a recovered store standing in no violation of Invariant 3.1, to Store 3; Supersession atomicity 1, the currency check and the supersession write one transition, to Store 1 and Store 2; Concurrency 1 and Supersession atomicity 2, the calls on one principal serialized, and Supersession atomicity 3, an isolation level foreclosing two concurrent [Set] calls, to Store 2; rules 211 to 196. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. At most one record in effect per principal stays the atom's own (Invariant 3.1, Operation 14), as do the instants a supersession and each lifecycle move stamp (State 9 through 12), the recorded timestamps witnessing the serialization order (Concurrency 2), and the records the atom never removes and the count that never falls (State 17, Invariant 9.1 through 9.3). A superseded record stays a record of its own with its own instants, and an auditor reconstructs which record governed from those instants (Check 2.1), so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.
- **2026-10-21 — The page's records-alone claims read as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *from the database alone*, *from the record alone* or *with no recourse to source code, runbooks or developer narration*: Invariant 10.3, under which an auditor clears Check 5.1 provably, and, by wording alone, the Summary's self-containment claim, the auditability property, the quiet-hours example and the acceptance bar; rules 196 to 196. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 10.3 changed and no obligation did.

- **2026-10-21 — Which refusal answers is the Execution Contract's.** *Chose:* [Set]'s refuses line kept as the page wrote it, already in the page's order — invalid-request, undeclared-channel, then storage-failure, which answers only at the write — and the order cited from the Execution Contract (Capability requirement 6, Execution Contract Refusal 1); Operation 9 (undeclared-channel only once the principal reference and a preference field are supplied), which only stated it, deleted to Refusal 1; rules 196 to 195. *Over:* the page stating for itself which of [Set]'s refusals answers when both apply. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states once that the refusal listed first on an action's refuses line answers. What each action answers on every call is unchanged.

- **2026-10-22 — A composed retention may dispose of what the atom never removes, no check asks for what no record carries, and no rule moves a status no call moves.** *Chose:* Invariant 9.2, the count that never falls, deleted to State 17 and Execution Contract Database 4, with Check 1.1 citing Invariant 9.1 alone; Check 6.1 deleted to External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, and Check 6.2 to Capability requirement 7, the deployment disclosing the fanout-on-no-record policy; Invariant 2.1 and Invariant 2.2, each read as obliging a status to move, deleted to State 1 and Invariant 2.3. *Over:* a count no lawful disposal may lower beside a non-goal sending lawful disposal to Retention Window; two conformance checks no preference record can answer, under an acceptance an external auditor clears from the stored fields; and two rules that a record left suspended by a principal who never returns breaks. *Because:* Final Critique 9 found all three, and the corpus held each cure: the composed erasure's, made on five atoms; the wiring declaration's, made on nine; and the method's 2026-10-08 rule, under which a rule a lawful state breaks is deleted to a rule that already holds that state. Smaller fixes rode with them: the supersession gap bound, with Temporal property 4, Capability requirement 5 and Check 4.1 and 4.2, deleted to State 11 and State 12, since one injected now stamps both instants of a supersession and the atomicity the bound once checked is Execution Contract Database 1's; Temporal property 5 deleted to Execution Contract Logic confinement 7; Composition note 13 to Channel set evolution 1, the declared channel set's governance the deployment's, as Final Critique 8's text had it; Invariant 5.2 and Invariant 10.3 to Check 5.1; Capability requirement 8, the deployment supplying the declared channel set at the seam; rules 195 to 185. What each action answers and writes on every call is unchanged.

- **2026-10-22 — The wiring and a composed retention's disposal are the Execution Contract's.** *Chose:* External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 6.1's tombstone, which named it, now naming the contract and the checks NOTE's sentence restating it removed; State 17 read by Execution Contract Database 6, so the atom removes no preference record and a disposal a composing retention pattern declares is answered by that pattern's records; both labels cited on Capability requirement 6; rules 185 to 184. *Over:* the page stating for itself that the wiring is an external check and that its no-removal rule binds the atom alone. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration and the composed erasure among them; this page's ninth Final Critique had made both cures one specification at a time. What each action does and answers is unchanged.

NOTE: End of Message Preference.

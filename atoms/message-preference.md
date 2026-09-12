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

Message Preference records how each principal wants delivery shaped — which channels, how often at most, what quiet hours, what format. It is strictly about the envelope. Whether the principal wants the information at all is a subscription question; whether the system may contact them at all is a legal-permission question; both live elsewhere. This atom answers only *given that we are going to deliver, how should the delivery look?*

One record per principal is in force at a time. Updating means a new record, with the prior one retired in the same operation. Suspending pauses delivery without touching the stored values, so resuming is a fresh set that replays them. Deleting retires the record outright. Nothing is ever removed through this atom's own surface, so the full history of how a principal's preferences changed stays queryable — a composed retention pattern may still dispose on its own declared schedule.

Each record also carries the channel vocabulary it was validated against, stamped at creation from the set the host injects at the seam. That is what lets an auditor clear any record from the record alone, with no configuration artifact and no second clock, and what keeps a historical record verifiable after the deployment's channel declaration moves on.

The pattern stores preference values without interpreting them: what a frequency cap or a quiet-hours window means is the delivery system's call. It underlies notification-settings pages, opt-out and frequency compliance, and the audit trail of preference changes.

---

## Intent

WHY:
Every system that pushes information to people accumulates two questions it must not confuse. *Should this principal hear about this class of thing at all?* is topic interest, and separately legal permission. *Given that delivery is going ahead, what shape should delivery take?* is this atom. A principal may want email and not SMS, at most five a day, silence between 10pm and 7am, plain text rather than rich. None of those is a decision about whether to deliver.

So the atom owns the per-principal record of delivery-shaping values and the lifecycle of that record, and nothing else. It does not deliver, does not consult subscriptions, does not evaluate legal permission, and does not interpret any value it stores. What it enforces is structural: one record in force per principal, every channel key drawn from a declared vocabulary, and values that never change once written.

The three states each answer a different operational question. Active: the principal has stated preferences and delivery proceeds under them. Suspended: the principal paused delivery without modifying the values, so a composing fanout observes the pause and suppresses. Deleted: the record is no longer in force, whether superseded by a new set or retired explicitly. Suspended is deliberately not the same as active-with-everything-opted-out — a suspension preserves the vocabulary, an opt-out destroys it, and the two mean different things to an auditor reconstructing what the principal intended.

Updates are not retroactive in the sense the atom commits to. A new set produces a new record and retires the prior one; no prior record's values change, and no caller's captured copy is touched. A fanout that captured values at queue time keeps delivering under them. The timestamps are sufficient for any composing pattern to reconstruct which record governed any past moment, which is the whole audit story.

## Structure

### Store instance model

```text
Instance 1: The deployment MUST route EVERY call to one store instance.
Instance 2: Two preference records in one store instance MUST NOT share a preference_id.
Instance 3: The atom MUST read one principal_ref in two store instances as two principals.
Instance 4: A store_name MUST name one store instance.
Instance 5: The atom MUST NOT accept a store_name as an argument.
Instance 6: A preference record MUST NOT carry a store_name.
Instance 7: The atom MUST NOT hold the declared channel set.
Instance 8: The atom MUST NOT offer an action that changes the declared channel set.
Instance 9: The host MUST resolve the declared channel set at the seam.
Instance 10: The host MUST inject the declared channel set into EVERY [Set] transition.
Instance 11: The host MUST NOT inject a degenerate declared channel set.
Instance 12: [Set] MUST stamp the injected declared channel set onto the new preference record as declared_channels.
Instance 13: IF the injected declared channel set is degenerate THEN [Set] MUST NOT validate channel_preferences.
Instance 14: IF the injected declared channel set is degenerate THEN [Set] MUST NOT write.
Instance 15: IF the injected declared channel set is degenerate THEN [Set] MUST NOT answer an outcome the signature block carries.
Instance 16: IF the injected declared channel set is degenerate THEN the deployment MUST surface the fault.
```

Terms › `preference record`: one principal's stated delivery shaping — the record this atom holds.

Terms › `store instance`: one named preference store a call is routed to; `preference_id` uniqueness ranges over one instance.

Terms › `store_name`: the identifier naming one store instance — a [Store Name]; deployment routing, never an argument and never a stored field.

Terms › `declared channel set`: the named delivery surfaces a preference record in this deployment may reference; deployment configuration the host resolves, never state this atom holds.

Terms › `degenerate`: a declared channel set that is empty, that repeats a channel name, OR that carries a channel name with no non-whitespace character.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading, the preference_id and the declared channel set here.

Terms › `transition`: the atom's evaluation of one call against the preference store, as `execution-contract.md` §Logic confinement declares it.

WHY:
The channel vocabulary is the deployment's, and the atom's job is to consume the resolution and prove the consumption — not to absorb a registry. So the set arrives at the seam like the clock and the id, the transition validates against it, and the transition stamps what it validated against onto the record (Instance 10, Instance 12). Two things follow, and both are the point. The audit surface is self-contained per record: one record, one stamped set, no cross-record join and no configuration artifact (Invariant 5.1, Invariant 10.1, Check 5.1). And a channel-set change is visible only forward — records made after the change carry the new set, historical records keep the set in force at their own creation, which is what keeps them verifiable forever.

A degenerate injection is a deployment fault, not a caller error, and the split matters: with an empty set every supplied key is undeclared by construction, so validating would report a host fault as a caller's vocabulary mistake. Fail-stop instead — nothing validated, nothing written, no conforming outcome, and the fault surfaced where deployment faults are read (Instance 13–16).

Who may change the declared set, when it changed, and the who and when of those changes all live with the deployment's configuration surface. A deployment whose regulator audits channel-set governance wraps *that* surface with [Audit Trail](../compositions/audit-trail.md) or [Actor Identity](./actor-identity.md); this store proves only, and exactly, what each record was validated against (Invariant 10.4, Non-goal 13).

### Identity model

```text
Identity 1: The atom MUST identify a preference record by the preference_id.
Identity 2: The host MUST allocate a preference_id at the seam.
Identity 3: The transition MUST NOT allocate a preference_id.
Identity 4: The atom MUST NOT reuse a preference_id.
Identity 5: The atom MUST NOT change a preference_id.
Identity 6: The atom MUST NOT identify a preference record by the principal_ref.
Identity 7: The atom MUST NOT identify a preference record by the principal_ref and the set_at.
Identity 8: The atom MUST NOT interpret a principal_ref.
Identity 9: The atom MUST NOT normalize a principal_ref.
Identity 10: The atom MUST match a principal_ref exactly.
Identity 11: The deployment MUST canonicalize a principal_ref.
```

Terms › `preference_id`: the opaque value naming one preference record — a [Preference Id]; host-allocated at the seam, never reused.

Terms › `principal_ref`: the opaque reference naming the principal whose preferences the record holds — a [Principal Ref]; compared by exact equality.

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what every presence check in this atom refuses; a blank argument NOT EXISTS.

WHY:
Identity by principal alone would collapse a principal's update history into one mutable row, which is exactly the audit story the atom exists to keep: three updates are three records, three ids, three independently queryable rows. Identity by principal and timestamp would entangle identity with the clock, on an axis at-most-one already polices (Identity 6, Identity 7, Invariant 3.1). *Principal* rather than *recipient* or *subscriber* because a preference record is held against an identity, not against having been the target of anything.

Equality is exact and the atom folds no case, trims no whitespace and normalizes no Unicode. At-most-one-in-force depends on consistent equality, so canonicalization is the deployment's before the call, and two references meant to denote one principal that do not compare equal are two principals here (Identity 9, Identity 11).

### Operations

```
set(principal_ref, channel_preferences?, frequency_limit?, quiet_hours?, format?, metadata?) → preference_id | rejected(invalid-request | undeclared-channel | storage-failure)
suspend(preference_id) → ok | rejected(not-known | not-active | storage-failure)
delete(preference_id) → ok | rejected(not-known | already-deleted | storage-failure)
current_for(principal_ref) → preference_record | none
read(preference_id) → preference_record | not-known
```

```text
Operation 1: [Set] MUST record EXACTLY ONE preference record per successful call.
Operation 2: [Set] MUST stand the new preference record in active.
Operation 3: [Set] MUST answer the preference_id.
Operation 4: IF principal_ref NOT EXISTS THEN [Set] MUST answer invalid-request.
Operation 5: IF no preference field EXISTS in the call THEN [Set] MUST answer invalid-request.
Operation 6: [Set] MUST read an empty channel_preferences map as an omitted preference field.
Operation 7: [Set] MUST NOT record an empty channel_preferences map.
Operation 8: IF a channel_preferences key NOT EXISTS in the injected declared channel set THEN [Set] MUST answer undeclared-channel.
Operation 9: [Set] MUST answer undeclared-channel ONLY IF principal_ref EXISTS AND a preference field EXISTS in the call.
Operation 10: [Set] MUST NOT interpret a preference field.
Operation 11: [Set] MUST NOT interpret metadata.
Operation 12: [Set] MUST NOT read metadata as a preference field.
Operation 13: [Set] MUST NOT compare the preference fields of two preference records.
Operation 14: IF a preference record currently in effect EXISTS for the principal_ref THEN [Set] MUST stand the prior preference record in deleted.
Operation 15: [Set] MUST commit the new preference record and the supersession in one operation.
Operation 16: IF the store refuses the write THEN [Set] MUST answer storage-failure.
Operation 17: IF the preference_id NOT EXISTS THEN [Suspend] MUST answer not-known.
Operation 18: IF the preference record stands in suspended THEN [Suspend] MUST answer not-active.
Operation 19: IF the preference record stands in deleted THEN [Suspend] MUST answer not-active.
Operation 20: [Suspend] MUST stand the preference record in suspended.
Operation 21: [Suspend] MUST NOT change a preference field.
Operation 22: [Suspend] MUST accept the preference_id as the whole authorization.
Operation 23: IF the store refuses the write THEN [Suspend] MUST answer storage-failure.
Operation 24: IF the preference_id NOT EXISTS THEN [Delete] MUST answer not-known.
Operation 25: IF the preference record stands in deleted THEN [Delete] MUST answer already-deleted.
Operation 26: [Delete] MUST stand the preference record in deleted.
Operation 27: [Delete] MUST NOT remove the preference record from the store.
Operation 28: [Delete] MUST accept the preference_id as the whole authorization.
Operation 29: IF the store refuses the write THEN [Delete] MUST answer storage-failure.
Operation 30: A refused write MUST leave the store as the call found the store.
Operation 31: [Current For] MUST answer EXACTLY ONE OF the preference record currently in effect, none.
Operation 32: [Current For] MUST NOT answer a deleted preference record.
Operation 33: [Current For] MUST NOT refuse a blank argument.
Operation 34: [Read] MUST answer EXACTLY ONE OF the whole preference record, not-known.
Operation 35: [Read] MUST answer a deleted preference record in full.
Operation 36: [Read] MUST NOT refuse a blank argument.
Operation 37: [Current For] MUST NOT write.
Operation 38: [Read] MUST NOT write.
Operation 39: The host MUST read the clock at the seam.
Operation 40: The transition MUST NOT read a clock.
Operation 41: The business caller MUST NOT supply now.
Operation 42: A guard MUST NOT read now.
Operation 43: A rejection MUST NOT rest on now.
```

Terms › `preference field`: `channel_preferences` | `frequency_limit` | `quiet_hours` | `format` — the four values a [Set] call must carry one of; `metadata` is not one.

Terms › `currently in effect`: a preference record standing in active OR in suspended — what at-most-one ranges over and what [Current For] answers.

Terms › `supersession`: the one operation in which a [Set] call stands a principal's prior preference record in deleted and records the new preference record.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `guard`: a transition's precondition test; reads the stored preference record and the call's arguments, and writes nothing.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the store |
|---|---|---|---|
| [Set] | principal present, a preference field present, every key declared, store accepts, no prior | the new `preference_id` | one record lands in [Active] (Operation 1, Operation 2) |
| [Set] | as above, with a prior currently in effect | the new `preference_id` | the new record lands in [Active], the prior moves to [Deleted], one operation (Operation 14, Operation 15) |
| [Set] | blank `principal_ref`, or no preference field, or an empty map as the only one | [Invalid Request] | none (Operation 4–6) |
| [Set] | a `channel_preferences` key outside the injected set | [Undeclared Channel] | none (Operation 8, Operation 9) |
| [Set] | the injected declared channel set is degenerate | no conforming outcome — fail-stop | none (Instance 13–16) |
| [Suspend] | id names a record in [Active] | `ok` | [Active] → [Suspended], `suspended_at` stamped (Operation 20, State 9) |
| [Suspend] | id names a record in [Suspended] or [Deleted] | [Not Active] | none (Operation 18, Operation 19) |
| [Delete] | id names a record in [Active] or [Suspended] | `ok` | → [Deleted], `deleted_at` stamped (Operation 26, State 10) |
| [Delete] | id names a record in [Deleted] | [Already Deleted] | none (Operation 25) |
| either write | id names nothing | [Not Known] | none (Operation 17, Operation 24) |
| any write | store refuses | [Storage Failure] | none (Operation 16, Operation 23, Operation 29, Operation 30) |
| [Current For] | a record currently in effect matches the principal | that record, in full | none — the call reads (Operation 31, Operation 37) |
| [Current For] | nothing in effect, blank argument included | [None] | none (Operation 32, Operation 33) |
| [Read] | id names a record in any state | that record, in full | none — [Deleted] included (Operation 34, Operation 35) |
| [Read] | id names nothing, blank argument included | [Not Known] | none (Operation 36) |

WHY:
The two queries refuse nothing, and the asymmetry with the three writes is deliberate: a write with a blank argument would record a bad row, a read with a blank argument has a correct answer — nothing matches, because no record carries a blank principal or a blank id (Operation 33, Operation 36). Neither [None] nor [Not Known] is a rejection; both are answers.

[Undeclared Channel] is its own class and not a shape error because the caller's remedy differs: fix the channel name, or take the declaration question to the deployment. A composing settings page reports the two to a principal differently, which is the test for whether a rejection has earned a name (Operation 8, Operation 9).

[Not Active] covers both [Suspended] and [Deleted] on a suspend, because a [Suspended] record never returns to [Active] and the caller's next move is the same either way; a caller that must tell them apart calls [Read] (Operation 18, Operation 19, Invariant 2.3). On a delete the split does matter — a [Suspended] record deletes cleanly and a [Deleted] one is [Already Deleted] — so delete carries the second code and suspend does not.

The clock enters once, at the seam, and is spent on exactly one thing: stamping `set_at`, `suspended_at` and `deleted_at` inside a committed transition. No guard consults it, so no rejection in the taxonomy depends on it, and a skewed clock can only make a stored timestamp advisory — never admit or refuse a call (Operation 39–43, Clock semantics 1–4).

### State

```text
State 1: EVERY preference record MUST stand in EXACTLY ONE OF active, suspended, deleted.
State 2: EVERY preference record MUST carry preference_id, principal_ref, declared_channels, set_at and status.
State 3: A preference record MUST carry EVERY preference field the [Set] call supplied.
State 4: A preference record MUST NOT carry a preference field the [Set] call omitted.
State 5: A preference record MUST carry metadata the [Set] call supplied.
State 6: A preference record that has stood in suspended MUST carry suspended_at.
State 7: A preference record that has never stood in suspended MUST NOT carry suspended_at.
State 8: A deleted preference record MUST carry deleted_at.
State 9: [Suspend] MUST stamp suspended_at from the injected now.
State 10: [Delete] MUST stamp deleted_at from the injected now.
State 11: [Set] MUST stamp set_at from the injected now.
State 12: A supersession MUST stamp deleted_at on the prior preference record from the injected now.
State 13: A preference record currently in effect MUST NOT carry deleted_at.
State 14: The atom MUST NOT offer a suspended-to-active transition.
State 15: The atom MUST NOT offer a deleted-to-active transition.
State 16: The atom MUST NOT offer a deleted-to-suspended transition.
State 17: The atom MUST NOT remove a preference record from the store.
State 18: The atom MUST NOT hold a notification.
State 19: The atom MUST NOT hold a topic subscription.
State 20: The atom MUST NOT hold a legal permission.
```

Terms › `status`: `active` | `suspended` | `deleted` — in force, paused, or retired and terminal.

Terms › `channel_preferences`: the optional map from a declared channel name to an opaque per-channel preference value — a [Channel Preferences].

Terms › `frequency_limit`: the optional opaque value carrying the principal's frequency cap — a [Frequency Limit].

Terms › `quiet_hours`: the optional opaque value carrying the windows delivery should skip — a [Quiet Hours].

Terms › `format`: the optional opaque value carrying format preferences — a [Format].

Terms › `metadata`: the optional opaque payload the atom stores unchanged — a [Metadata]; deployment context, never a preference field.

Terms › `declared_channels`: the declared channel set stamped onto a preference record at [Set] — a [Declared Channels]; the record's own validation context.

Terms › `set_at`: the instant the preference record was created — a [Set At].

Terms › `suspended_at`: the instant the preference record was paused — a [Suspended At].

Terms › `deleted_at`: the instant the preference record was retired — a [Deleted At].

WHY:
A deleted record stays in the store because *what this principal stated, and when* is the audit surface the atom exists to hold — the atom answers *what now* from the set currently in effect and leaves *what then* reconstructable from the three timestamps (State 17, Check 2.1). Absence is the one stored form of no-channel-preferences: a supplied-but-empty map is stored as absent, so a reader branches on presence alone and never on emptiness (Operation 6, Operation 7, State 4).

An absent preference field says *the principal stated nothing on this dimension*, and the composing fanout applies a deployment default for it. That is structurally distinct from a channel carrying an explicit opt-out value, which is a stated choice. The atom keeps the distinction because a fanout that cannot see it cannot honour either (State 4, Composition note 12).

Nothing about delivery lives here: what was sent, to whom, and whether the principal follows the topic belong to [Notification](./notification.md) and [Subscription](./subscription.md), and whether the system may contact the principal at all belongs to [Consent](./consent.md) (State 18–20).

### Invariants

- **Invariant 1 — Preference record immutability.**
  ```text
  Invariant 1.1: A recorded preference record's preference_id, principal_ref, declared_channels and set_at MUST NOT change.
  Invariant 1.2: A recorded preference field MUST NOT change.
  Invariant 1.3: A recorded metadata MUST NOT change.
  Invariant 1.4: A preference field a [Set] call omitted MUST NOT appear later.
  Invariant 1.5: A recorded suspended_at MUST NOT change.
  Invariant 1.6: A recorded deleted_at MUST NOT change.
  Invariant 1.7: A preference record MUST NOT carry a mutable field beyond status.
  ```
- **Invariant 2 — Status monotonicity.**
  ```text
  Invariant 2.1: A status MUST move from active to EXACTLY ONE OF suspended, deleted.
  Invariant 2.2: A status MUST move from suspended to deleted.
  Invariant 2.3: A status MUST NOT move from suspended to active.
  Invariant 2.4: A status MUST NOT move from deleted to active.
  Invariant 2.5: A status MUST NOT move from deleted to suspended.
  ```
- **Invariant 3 — At most one preference record currently in effect per principal.**
  ```text
  Invariant 3.1: Two preference records currently in effect MUST NOT share a principal_ref.
  ```
- **Invariant 4 — Supersession atomicity.**
  ```text
  Invariant 4.1: A supersession MUST change the prior preference record and the new preference record in one operation.
  Invariant 4.2: A reader MUST NOT observe two preference records currently in effect for one principal_ref.
  Invariant 4.3: A refused supersession MUST leave the prior preference record currently in effect.
  Invariant 4.4: A refused supersession MUST NOT record the new preference record.
  ```
  WHY: Invariant 4.1 asserts the atomic co-occurrence alone, which holds unconditionally. The timestamp relation between the prior record's `deleted_at` and the successor's `set_at` is a best-effort directional claim, and it rests on clock monotonicity the hard set does not carry — so it lives under Temporal property 4, not here.
- **Invariant 5 — Channel preferences reference declared channels, and the proof is on the record.**
  ```text
  Invariant 5.1: EVERY channel_preferences key MUST stand in the preference record's own declared_channels.
  Invariant 5.2: An auditor MUST clear Invariant 5.1 from one preference record.
  Invariant 5.3: A change to the deployment's declared channel set MUST NOT change a recorded declared_channels.
  ```
- **Invariant 6 — Suspension is value-preserving.**
  ```text
  Invariant 6.1: [Suspend] MUST change status and suspended_at alone.
  Invariant 6.2: [Suspend] MUST NOT change a preference field.
  Invariant 6.3: [Suspend] MUST NOT change principal_ref.
  ```
  WHY: this is the structural mechanism behind cheap resumption — a composing pattern reads the suspended record's values and replays them in a fresh [Set], with no vocabulary loss and nothing for the principal to re-enter. The one caveat is that the replay is re-validated against the set injected for the later call, so a channel name dropped from the declaration in the meantime must be dropped from the replay (Resumption 1–4).
- **Invariant 7 — Current For determinism.**
  ```text
  Invariant 7.1: [Current For] MUST answer the preference record currently in effect for the principal_ref.
  Invariant 7.2: [Current For] MUST answer none ONLY IF no preference record currently in effect EXISTS for the principal_ref.
  Invariant 7.3: [Current For] MUST rest on the preference record set alone.
  ```
- **Invariant 8 — No id reuse.**
  ```text
  Invariant 8.1: Two preference records MUST NOT share a preference_id.
  ```
- **Invariant 9 — Store durability over this atom's own surface.**
  ```text
  Invariant 9.1: The atom MUST NOT offer a removal surface.
  Invariant 9.2: The preference record count MUST NOT fall.
  Invariant 9.3: [Read] MUST answer a deleted preference record.
  ```
  WHY: scoped to this atom's own surface on purpose. Lawful disposal under a composed [Retention Window](./retention-window.md), or a deployment's erasure obligations under GDPR (EU General Data Protection Regulation) Article 17, is that pattern's declared and recorded act — an auditor of a composed deployment reads its retention records alongside this store (Non-goal 26, Non-goal 27).
- **Invariant 10 — Validation-context self-containment.**
  ```text
  Invariant 10.1: EVERY preference record MUST carry declared_channels.
  Invariant 10.2: A recorded declared_channels MUST NOT stand empty.
  Invariant 10.3: An auditor MUST clear Check 5.1 from the store alone.
  Invariant 10.4: The atom MUST NOT hold the declared channel set's governance.
  ```
- **Temporal property — Timestamp ordering.**
  ```text
  Temporal property 1: IF suspended_at EXISTS THEN set_at MUST NOT EXCEED suspended_at.
  Temporal property 2: IF deleted_at EXISTS THEN set_at MUST NOT EXCEED deleted_at.
  Temporal property 3: IF suspended_at EXISTS AND deleted_at EXISTS THEN suspended_at MUST NOT EXCEED deleted_at.
  Temporal property 4: A supersession gap MUST NOT EXCEED the clock tolerance.
  Temporal property 5: The implementation MUST own the clock monotonicity Temporal property 1 rests on.
  ```
  WHY: best-effort, and deliberately outside the invariant numbering — Invariants 1 to 10 are the hard set, and giving this a slot among them would read it as their peer. The hard set holds over every state the atom's own accepted actions can reach, given the named host obligations; these four inequalities hold only where the clock does not move backward. They are labelled apart because audit reconstruction depends on the directional guarantee (Check 2.1, Check 4.1), and a violation here is observable and diagnosable rather than silently corrupting.

Terms › `supersession gap`: the interval from a superseded preference record's `deleted_at` to the successor's `set_at`.

Terms › `clock tolerance`: the largest supersession gap the deployment expects between two writes inside one operation; declared by the deployment.

Immutability and durability together give *auditability* — the full history of every principal's preferences is recoverable from the store alone, with no gaps. At-most-one-in-effect and supersession atomicity together give *unambiguous currency* — at any moment a principal has at most one record governing delivery, and the moment of transition is recorded. Suspension being value-preserving gives *cheap resumption* — a principal who pauses and later returns loses nothing.

## Examples

Three lifecycle scenarios trace one principal (`user_u`) through onboarding, vacation suspend and account closure — the chain `pref_001 → pref_088 → pref_141`. The rejection paths and the regulated scenarios use their own principals and ids. Each deployment below carries `["email", "sms", "push", "in-app"]` on its configuration surface, injected at the seam for each `set` call, unless the scenario says otherwise.

### Consumer SaaS — onboarding preferences

A new user of a productivity app picks preferences on the settings page: email for daily digests, push for real-time mentions, no SMS, plain text. `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "opt-out"}, format: "plain")` → `pref_001`, in [Active].

When the composition fires an event `user_u` is subscribed to, the fanout calls `current_for(user_u)` → `pref_001`, reads the channel preferences, and creates one Notification per channel not opted out.

Three weeks later the user adds SMS for urgent items and a daily cap: `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "urgent-only"}, frequency_limit: {per_day: 10}, format: "plain")` → `pref_088`. `pref_001` moves to [Deleted] with `deleted_at` in the same operation. `current_for(user_u)` now answers `pref_088`.

### Marketing platform — vacation suspend

A newsletter subscriber going away for two weeks wants delivery paused without losing the settings. `suspend(pref_088)` → `ok`; the record moves [Active] → [Suspended] with `suspended_at`. `current_for(user_u)` still answers the record, and the fanout reads [Suspended] as suppress.

On return, the settings page reads the suspended record's values and offers them as defaults; the subscriber confirms and the page calls `set(principal_ref: user_u, channel_preferences: {email: "digest", push: "real-time", sms: "urgent-only"}, frequency_limit: {per_day: 10}, format: "plain")` → `pref_141`. `pref_088` moves to [Deleted], keeping its `suspended_at` and its original `set_at`. Full delivery resumes under the new record.

### Account closure — explicit deletion

A user closes their account, and the closure flow calls `delete(pref_141)` → `ok`. The record moves to [Deleted]; `current_for(user_u)` answers `none`. The fanout, finding nothing in effect, follows the deployment's declared fanout-on-no-record policy.

`pref_001`, `pref_088` and `pref_141` all remain in the store. A later access request for `user_u`'s preference history filters the store on `principal_ref = user_u` and returns the full chronological chain; each record's content is what `read(preference_id)` answers for it — [Preference Id], [Principal Ref], the stated preference fields, [Declared Channels], [Set At], [Status] and the applicable lifecycle timestamps.

### Rejection paths

A set carrying nothing: `set(principal_ref: user_u)` → `rejected(invalid-request)`. No id is issued, no record enters the store (Operation 5).

A set naming a channel outside the injected set: `set(principal_ref: user_v, channel_preferences: {email: "preferred", carrier-pigeon: "backup"})` → `rejected(undeclared-channel)`. The reason names the vocabulary error as its own class, so the composing system knows to fix the channel name rather than the call shape (Operation 8).

A retry after a network timeout: `suspend(pref_001)` → `rejected(not-active)`; `pref_001` is [Deleted] (Operation 19).

A duplicate teardown: `delete(pref_141)` → `rejected(already-deleted)`; nothing changes (Operation 25). A delete on a *[Suspended]* record, by contrast, answers `ok` — that transition is admitted (Operation 26, Invariant 2.2).

### Regulated adversarial scenarios

- **Regulator audit — honouring an opt-out under CAN-SPAM (the US Controlling the Assault of Non-Solicited Pornography And Marketing Act — the federal commercial-email law).** A regulator asks whether a marketing platform honoured `user_v`'s email opt-out after `2026-03-14`. The investigator enumerates the principal's records: `pref_201` with `email: "preferred"` in effect from `2025-08-01` to `2026-03-14`; `pref_244` with `email: "opt-out"` in effect from `2026-03-14` onward. For any email alleged after that date, the fanout would have called `current_for(user_v)` and read `pref_244`. A delivery against that record is either a fanout conformance failure or a composing-layer failure — either way the preference record is the structural evidence of what the principal stated at the time. Invariant 1.2 and Temporal property 2 are the rebuttal: the record was created then, with those values, and does not change.
- **Disputed delivery — quiet hours under TCPA (the US Telephone Consumer Protection Act — the federal law restricting unsolicited calls and texts).** A principal reports an SMS at 11:30pm against quiet hours of 10pm–7am. The investigator reconstructs which record was in effect at the delivery instant (Check 2.1), takes its `preference_id`, and calls `read(preference_id)`. The record shows `quiet_hours: {start: "22:00", end: "07:00", timezone: "America/Los_Angeles"}`. Whether the fanout observed them is the composing-layer question; that the principal stated them is settled from the store, with no developer narration.
- **Breach investigation — which principals' preferences may have been corrupted.** An incident on `2026-04-01T05:00Z` exposed the store to possible unauthorized modification. The investigator queries for any record with `set_at`, `suspended_at` or `deleted_at` inside the window. Invariant 1.1 and Invariant 9.2 are the atom-level rebuttal, but as a contract and not as cryptographic enforcement: a record made before the window should not have been altered, and the atom exposes alteration only insofar as the underlying store does. Sealing against post-hoc tampering belongs to a composed [Tamper Evidence](./tamper-evidence.md); without it, the bare atom's records support forensic reconstruction but do not prove that no out-of-band write occurred (Non-goal 28, Non-goal 29).

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the preference store's stored fields, with no recourse to source code, runbooks or developer narration. The audit surface is the store, not the action surface: the action surface answers *what does the atom do at runtime*, the audit surface answers *what does the atom commit to recording*.

### Conformance checks

```text
Check 1.1: An auditor MUST enumerate EVERY preference record's preference_id, principal_ref, set_at, status, suspended_at and deleted_at from the store (Invariant 9.1, Invariant 9.2).
Check 1.2: An auditor MUST find EVERY supplied preference field on the preference record (Invariant 1.2, State 3).
Check 2.1: An auditor MUST reconstruct the preference record currently in effect for a principal_ref at a past instant from set_at, status and deleted_at (Invariant 3.1, Invariant 4.1).
Check 2.2: An auditor MUST read a currency interval as half-open from set_at to deleted_at (Invariant 4.1).
Check 3.1: An auditor MUST find no two preference records currently in effect sharing a principal_ref (Invariant 3.1, Invariant 4.2).
Check 4.1: An auditor MUST read a supersession gap within the clock tolerance as a supersession (Invariant 4.1, Temporal property 4).
Check 4.2: An auditor MUST mark a supersession gap exceeding the clock tolerance ambiguous (Invariant 4.1).
Check 4.3: The deployment MUST disclose the clock tolerance (Temporal property 4).
Check 5.1: An auditor MUST find EVERY channel_preferences key in the preference record's own declared_channels (Invariant 5.1, Invariant 10.1).
Check 5.2: An auditor MUST mark an absent declared_channels a conformance failure (Invariant 10.1, Invariant 10.2).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
Check 6.2: The deployment MUST disclose the fanout-on-no-record policy (Composition note 5).
```

NOTE: EVERY check names the rule the check tests.

WHY:
Check 2.2 fixes the interval convention so two auditors reading one store agree: at `t = set_at` the record is in effect, at `t = deleted_at` it is not, and a successor created in the same supersession is the one in effect at that instant. Check 4.2 is the honest answer to a gap the records cannot resolve on their own — the same record structure is produced by an atomic supersession and by an explicit delete followed by a later re-creation, so a material gap is flagged ambiguous-pending-external-evidence rather than scored as a pass or a failure. Deterministic discrimination needs a composed [Audit Trail](../compositions/audit-trail.md) or [Actor Identity](./actor-identity.md), which records each action as its own attributed event. Check 6.2 exists because without the disclosure the same operational situation — no record for a principal — produces different delivery across deployments, and cross-deployment audit cannot read the stores uniformly.

## Non-goals

```text
Non-goal 1: The atom MUST NOT route a notification.
Non-goal 2: The atom MUST NOT fire an event.
Non-goal 3: The atom MUST NOT create a notification.
Non-goal 4: The atom MUST NOT deliver a notification.
Non-goal 5: A deployment needing fanout MUST compose a preference-aware fanout pattern.
Non-goal 6: The atom MUST NOT evaluate a legal permission.
Non-goal 7: A deployment needing a legal-permission decision MUST compose [Consent](./consent.md).
Non-goal 8: The atom MUST NOT evaluate a topic subscription.
Non-goal 9: A deployment needing a topic-interest decision MUST compose [Subscription](./subscription.md).
Non-goal 10: The atom MUST NOT carry a transport mechanism.
Non-goal 11: The atom MUST NOT interpret a preference field's contents.
Non-goal 12: The atom MUST NOT declare which channel names are valid.
Non-goal 13: The atom MUST NOT record who changed the declared channel set.
Non-goal 14: A deployment needing channel-set attribution MUST compose [Audit Trail](../compositions/audit-trail.md).
Non-goal 15: The atom MUST NOT hold a default preference for a principal carrying no preference record.
Non-goal 16: The atom MUST NOT offer a resume action.
Non-goal 17: The atom MUST NOT carry a deletion reason on a preference record.
Non-goal 18: A deployment needing a recorded deletion reason MUST compose [Actor Identity](./actor-identity.md).
Non-goal 19: The atom MUST NOT detect a conflicting preference.
Non-goal 20: The atom MUST NOT offer a bulk action.
Non-goal 21: The atom MUST NOT hold a per-topic preference.
Non-goal 22: The atom MUST NOT record who called an action.
Non-goal 23: The atom MUST NOT gate an action beyond the identifier the action accepts.
Non-goal 24: A deployment needing richer authorization MUST compose [Permissions](./permissions.md).
Non-goal 25: The atom MUST NOT expire a preference record.
Non-goal 26: The atom MUST NOT redact a preference record.
Non-goal 27: A deployment needing lawful disposal MUST compose [Retention Window](./retention-window.md).
Non-goal 28: The atom MUST NOT seal a preference record against modification.
Non-goal 29: A deployment needing court-admissible records MUST compose [Tamper Evidence](./tamper-evidence.md).
Non-goal 30: The atom MUST NOT guarantee a preference_id unique across store instances.
Non-goal 31: The atom MUST NOT push an update into queued work.
Non-goal 32: The atom MUST NOT change a caller's captured copy of a preference record.
```

WHY:
Everything downstream of *how should this look* belongs to the composing pattern — routing, fanout, transport, delivery guarantees (Non-goal 1–5). The two gating questions are sequenced peers, not alternatives: [Consent](./consent.md) decides whether the system may contact the principal at all, [Subscription](./subscription.md) decides whether the principal follows the topic, and this atom's commitment is conditional on both having resolved in favour of delivery (Non-goal 6–9, Composition note 6, Composition note 7). A composing pattern that reads preferences without first re-checking permission has made a sequencing error, not an atom-conformance error; the atom neither detects nor reacts to a revocation, and the records stay as they were.

Frequency limits and quiet hours are preference fields and not atoms of their own. Rate-limiting recurs in the abstract, but what is stored here is an opaque payload with no state machine, no lifecycle independent of the record carrying it, and no meaning until the fanout interprets it at delivery time. A separate rate-limit atom would have identity, state and actions; this is a parameter (Non-goal 11, Composition note 8).

Authorization is capability-based across writes and reads alike: a caller holding a `principal_ref` may set for that principal or ask what is in effect, a caller holding a `preference_id` may suspend, delete or read. No role check, no per-action authorization. The bare atom enforces something specific and useful, and richer models — the principal must consent to a third party setting their preferences, a deletion must be co-signed, only the principal or a privacy admin may read the history — wrap it rather than replace it (Non-goal 22–24).

No resume action, because returning a [Suspended] record to [Active] would break monotonicity, and a principal cycling suspend and resume repeatedly would pile the whole history onto one record instead of producing one record per lifecycle event. Reading the suspended values and offering them as defaults is cheap, so lifecycle clarity wins over surface convenience (Non-goal 16, Invariant 2.3, Resumption 1–4).

## Edge cases

### Channel set evolution

```text
Channel set evolution 1: The deployment MUST own the declared channel set's change history.
Channel set evolution 2: A change to the declared channel set MUST NOT change a recorded preference record.
Channel set evolution 3: An auditor MUST read a historical channel_preferences key against the preference record's own declared_channels.
Channel set evolution 4: A composing pattern MUST own how a preference record naming a withdrawn channel shapes delivery.
```

WHY:
Adding or withdrawing a channel is a configuration-surface operation; the atom sees only the set injected for each [Set] call. Existing records are untouched and stay verifiable forever, because Invariant 5.1 is per-record against the record's own stamp — a withdrawn channel appearing in a historical record's keys is consistent with that record's set, not a violation. The change is visible only forward. A host that injects a wrong or stale set produces records honestly stamped with the set actually used: a governance failure the stamps surface rather than hide.

### Resumption

```text
Resumption 1: A composing pattern MUST read a suspended preference record's values through [Current For].
Resumption 2: A composing pattern MUST replay the values through a fresh [Set] call.
Resumption 3: [Set] MUST validate a replayed channel_preferences key against the injected declared channel set.
Resumption 4: IF a replayed channel name NOT EXISTS in the injected declared channel set THEN a composing pattern MUST drop the channel name.
```

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: The deployment MUST supply an honest now.
Clock semantics 4: The deployment MUST disclose the clock tolerance.
```

WHY:
Because no precondition consults the reading, a non-monotonic clock degrades only the annotation and never an admission decision (Operation 42, Operation 43). The declared tolerance is what bounds how a supersession gap should be read, which is why Check 4.3 makes the disclosure part of acceptance rather than a deployment note.

### Supersession atomicity

```text
Supersession atomicity 1: The implementation MUST make the currency check and the supersession write one transition.
Supersession atomicity 2: The implementation MUST serialize EVERY operation touching one principal_ref.
Supersession atomicity 3: The deployment MUST choose a host isolation level that forecloses two concurrent [Set] calls standing two preference records currently in effect.
Supersession atomicity 4: A crash inside [Set] MUST NOT leave two preference records currently in effect for one principal_ref.
Supersession atomicity 5: A crash inside [Set] MUST NOT leave the new preference record without the prior preference record's transition.
Supersession atomicity 6: A crash inside [Suspend] MUST NOT leave a suspended status without suspended_at.
Supersession atomicity 7: A crash inside [Delete] MUST NOT leave a deleted status without deleted_at.
Supersession atomicity 8: A recovered store MUST NOT stand in a violation of Invariant 3.1.
```

WHY:
The serialization domain is the principal, not the record id. [Suspend] and [Delete] take a `preference_id`, but every record belongs to exactly one principal, so a concurrent [Set] and [Suspend] on the same principal must serialize against one another or interleave inconsistently (Supersession atomicity 2). Under snapshot or read-committed isolation two concurrent [Set] calls can both observe nothing in effect and both commit, violating the one rule the atom exists to hold (Supersession atomicity 3, Invariant 3.1).

The spec does not define post-crash reconciliation — how an implementation detects and repairs a partial write is the implementor's — but the recovered store must not carry a standing violation, which is what makes atomicity a conformance requirement rather than a best effort (Supersession atomicity 8).

### Concurrency

```text
Concurrency 1: The host MUST serialize concurrent calls on one principal_ref.
Concurrency 2: The recorded timestamps MUST witness the serialization order.
Concurrency 3: [Current For] MUST NOT answer a torn preference record.
Concurrency 4: A composing pattern MUST own how competing callers reach the atom.
```

WHY:
The cases fall out of the rules rather than needing their own. Two sets for one principal: the first records and supersedes any prior, the second records and supersedes the first. Two suspends on one id: the first succeeds, the second meets [Not Active]. Two deletes: the first succeeds, the second meets [Already Deleted]. A suspend and a delete on one [Active] id: whichever serializes first wins, and a late delete after a suspend still succeeds, because [Suspended] → [Deleted] is admitted. A [Current For] concurrent with a [Set] answers the prior record or the new one and never a torn state — and under queue-time capture, an answer naming a just-superseded record is acceptable, because the fanout captured the values at queue time (Concurrency 3, Composition note 3).

### Opaque input bounds

```text
Opaque input bound 1: The atom MUST store EVERY opaque input as supplied.
Opaque input bound 2: The atom MUST NOT bound an opaque input's size.
Opaque input bound 3: The deployment MUST own an opaque input's size bound.
Opaque input bound 4: The deployment MUST disclose the opaque input size bound.
```

WHY:
`principal_ref`, each per-channel preference value, `frequency_limit`, `quiet_hours`, `format` and `metadata` are all stored as-supplied with no length cap here. Bounding them to what the store, the transport and the equality check can carry efficiently is the deployment's, and so is the choice to leave them unbounded and accept the consequences — which is why the bound is disclosed alongside the fanout-on-no-record and clock-tolerance disclosures.

### Re-creation after deletion

```text
Re-creation 1: A [Set] call following a [Delete] MUST record a fresh preference record.
Re-creation 2: The two preference records MUST stand in the store independently.
Re-creation 3: The retired preference_id MUST NOT return.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST call [Current For] when a notification is queued.
Composition note 3: A composing pattern MUST capture the preference record's values at queue time.
Composition note 4: A composing pattern MUST read a suspended preference record as delivery-suppress.
Composition note 5: A composing pattern MUST own the fanout-on-no-record policy.
Composition note 6: A composing pattern MUST NOT read a preference record BEFORE the legal-permission decision.
Composition note 7: A composing pattern MUST NOT read a preference record BEFORE the topic-interest decision.
Composition note 8: A composing pattern MUST interpret frequency_limit at delivery time.
Composition note 9: A composing pattern MUST interpret quiet_hours at delivery time.
Composition note 10: A composing pattern MUST interpret format at delivery time.
Composition note 11: A composing pattern MUST interpret a per-channel preference value at delivery time.
Composition note 12: A composing pattern MUST apply a deployment default for an omitted preference field.
Composition note 13: A composing pattern MUST own the declared channel set's governance.
```

WHY:
[Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) is the wiring this atom was extracted for: [Subscription](./subscription.md), [Notification](./notification.md), this atom and [Event Log](./event-log.md) into an end-to-end pipeline that honours per-principal shaping. That composition reads [Suspended] as delivery-suppress, frequency limits and quiet hours as classified suppressions marked held-for-retry or dropped per declared policy, and channel preferences as route-or-suppress — every suppression journalled with its reason and this atom's record id. It extends rather than replaces [Notification Fanout](../compositions/notification-fanout.md); a deployment that has not adopted preference shaping keeps the base composition.

The rest compose the way the non-goals imply. [Event Log](./event-log.md) records each preference action as an auditable event where the in-record timestamps are not enough — a principal's full sequence of suspend cycles, beyond the single `suspended_at` the record keeps. [Actor Identity](./actor-identity.md) attributes each action, with `preference_id` as the hook: no field is added to the preference record, the attribution lives in the identity store. [Retention Window](./retention-window.md) bounds how long the store is kept and when it may be disposed of. [Tamper Evidence](./tamper-evidence.md) seals the store where a record alleging an opt-out could otherwise be rewritten to allege an opt-in. [Duplicate Prevention](./duplicate-prevention.md) gives at-most-once on [Set] under retry, so a network-timeout retry does not produce a second supersession.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a guard; a principal; an auditor; a reader; the store; a preference record; a status; a supersession; a supersession gap; a write; a rejection; a crash; a recovered store; the preference record count; the recorded timestamps; a store_name.

Terms › `records`: `preference record` — one principal's stated delivery shaping, carrying `preference_id`, `principal_ref`, `declared_channels`, `set_at`, `status`, the supplied preference fields and `metadata`, and, once stamped, `suspended_at` and `deleted_at`.

Terms › `record verbs`: route, share, read, name, accept, carry, hold, offer, resolve, inject, stamp, validate, write, answer, surface, identify, allocate, reuse, change, interpret, normalize, match, canonicalize, record, stand, compare, commit, remove, leave, refuse, supply, rest, appear, move, call, observe, clear, fall, own, enumerate, find, reconstruct, mark, disclose, fire, create, deliver, compose, evaluate, declare, detect, gate, expire, redact, seal, guarantee, push, replay, drop, make, serialize, choose, witness, store, bound, return, capture, apply.

Terms › `value sets`: set answers = preference_id | rejected(invalid-request | undeclared-channel | storage-failure). suspend answers = ok | rejected(not-known | not-active | storage-failure). delete answers = ok | rejected(not-known | already-deleted | storage-failure). current_for answers = the preference record currently in effect | none. read answers = the whole preference record | not-known. `status` = active | suspended | deleted. `preference field` = channel_preferences | frequency_limit | quiet_hours | format.

Terms › `bounds`: `clock tolerance` (the largest supersession gap one operation is expected to span); `opaque input size bound` (the deployment's cap on a stored opaque value).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `preference record`, `store instance`, `store_name`, `declared channel set`, `degenerate`, `seam`, `transition`, `preference_id`, `principal_ref`, `blank`, `preference field`, `currently in effect`, `supersession`, `now`, `business caller`, `guard`, `status`, `channel_preferences`, `frequency_limit`, `quiet_hours`, `format`, `metadata`, `declared_channels`, `set_at`, `suspended_at`, `deleted_at`, `supersession gap`, `clock tolerance`.

#### Set

The behavior that records a new preference set for a principal. It assigns the host-allocated [Preference Id], stamps [Set At], records [Principal Ref], the supplied preference fields and [Metadata], and stamps the seam-injected declared channel set as [Declared Channels]. The new record enters [Active]; any prior record currently in effect moves to [Deleted] in the same operation (Invariant 4). At least one preference field is required (else [Invalid Request]).

Kind: Operation

#### Suspend

The behavior that pauses delivery, moving an [Active] record to [Suspended] and stamping [Suspended At] without altering any preference value (Invariant 6). Rejected for a record that is not [Active] ([Not Active]) or an unknown id ([Not Known]).

Kind: Operation

#### Delete

The behavior that retires a record, moving an [Active] or [Suspended] record to terminal [Deleted] and stamping [Deleted At]. Rejected for an already-[Deleted] record ([Already Deleted]) or an unknown id ([Not Known]). The record is retained, not removed (Invariant 9).

Kind: Operation

#### Current For

The read-only query returning the unique record currently in effect ([Active] or [Suspended]) for a [Principal Ref], or `none` if there is none (Invariant 7). Excludes [Deleted] records; never transitions; refuses nothing.

Kind: Operation

#### Read

The read-only query returning the full record for a [Preference Id] in any state ([Active], [Suspended] or [Deleted]), or [Not Known] if no record has that id. Deletion is a state, not a removal; never transitions; refuses nothing.

Kind: Operation

#### Preference Id

The opaque, immutable identity of a preference record, host-allocated at the I/O seam on [Set], never reused (Invariant 8). The principal reference and the preference values are properties of the record, not its identity.

Kind:     Field
Field of: the preference record
Projects: preference_id

#### Principal Ref

The opaque reference to the principal whose preferences are recorded. Set on [Set], immutable. Equality is exact and the atom normalizes nothing; the at-most-one-in-effect rule (Invariant 3) ranges over it, so canonicalization is the deployment's before the call.

Kind:     Field
Field of: the preference record
Projects: principal_ref

#### Channel Preferences

The optional map from a declared channel name to an opaque per-channel preference value. Set on [Set] if supplied, immutable. Every key must be a member of the record's own [Declared Channels] stamp — the set injected at the seam for that [Set] call (Invariant 5). A supplied-but-empty map is stored as absent.

Kind:     Field
Field of: the preference record
Projects: channel_preferences

#### Frequency Limit

The optional, opaque deployment-shaped value carrying the principal's frequency cap. Set on [Set] if supplied, immutable; interpreted by the composing fanout pattern, not by the atom.

Kind:     Field
Field of: the preference record
Projects: frequency_limit

#### Quiet Hours

The optional, opaque deployment-shaped value carrying the windows during which delivery should be suppressed. Set on [Set] if supplied, immutable; interpreted by the composing layer.

Kind:     Field
Field of: the preference record
Projects: quiet_hours

#### Format

The optional, opaque deployment-shaped value carrying format preferences. Set on [Set] if supplied, immutable; interpreted by the composing layer.

Kind:     Field
Field of: the preference record
Projects: format

#### Metadata

The optional opaque payload the atom stores unchanged (form version, user-agent, consent-flow id). Set on [Set] if supplied, immutable. Not a preference field: it does not by itself satisfy the at-least-one requirement on [Set].

Kind:     Field
Field of: the preference record
Projects: metadata

#### Set At

The wall-time the record was created, stamped from the seam-injected clock reading at [Set]. Immutable (Invariant 1). The currency-reconstruction key for [Current For] and for audit.

Kind:     Field
Field of: the preference record
Projects: set_at

#### Status

The record's lifecycle state — [Active], [Suspended] or [Deleted]. Set to [Active] on [Set]; the only mutable field, moving monotonically (Invariant 2).

Kind:     Field
Field of: the preference record
Projects: status

#### Suspended At

The wall-time the record was suspended, stamped at [Suspend]. Absent on a record that has never been [Suspended]; immutable once set, and retained through a later move to [Deleted].

Kind:     Field
Field of: the preference record
Projects: suspended_at

#### Deleted At

The wall-time the record reached [Deleted], stamped at [Delete] or at supersession. Absent unless the record is [Deleted]; immutable once set.

Kind:     Field
Field of: the preference record
Projects: deleted_at

#### Store Name

The identifier of the store instance; [Preference Id] values are unique within an instance. No action accepts it as a parameter and no record stores it — instance selection and naming live at the deployment-routing layer (Store instance model).

Kind:     Field
Field of: the store instance
Projects: store_name

#### Declared Channels

The declared channel set injected at the seam for a record's [Set] call and stamped onto the record at creation — the record's own validation context (Invariants 5 and 10). Non-empty; immutable. What the deployment's channel declaration has done since never touches it.

Kind:     Field
Field of: the preference record
Projects: declared_channels

#### Undeclared Channel

The [Set] rejection when a supplied [Channel Preferences] key is not a member of the seam-injected declared channel set — a vocabulary error with its own remedy (fix the channel name, or take the declaration question to the deployment), distinct from a malformed call's [Invalid Request].

Kind:      Member
Member of: the Set rejection
Role:      Outcome
Projects:  undeclared-channel

#### Storage Failure

The rejection any state-changing action returns when the write fails after all preconditions pass. Fail-closed at the write: nothing observable was written — for [Set] with supersession, neither half landed (Invariant 4); for [Suspend] and [Delete], no status moved. Which record keeps governing after a refused [Set] is Invariant 4.3's answer, not this card's: the prior record stays in effect, so a failed write is fail-closed on the store and not on whatever the new record was carrying.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

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

The refusal [Set] returns when the request's shape fails — a blank [Principal Ref], or no preference field supplied (an empty [Channel Preferences] map does not count). A [Channel Preferences] key naming an undeclared channel is not this refusal; it is [Undeclared Channel], its own class with its own remedy.

Kind:      Member
Member of: the Set rejection
Role:      Outcome
Projects:  invalid-request

#### Not Known

The refusal [Suspend] or [Delete] returns when the [Preference Id] references no record in the store. Also the read answer [Read] returns for an id no record carries — there, a first-class outcome rather than a rejection.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Not Active

The refusal [Suspend] returns when the target is not [Active] — that is, [Suspended] or [Deleted]. The single code covers both ([Suspended] never returns to [Active], Invariant 2); a caller distinguishes them through [Read].

Kind:      Member
Member of: the Suspend rejection
Role:      Outcome
Projects:  not-active

#### None

The answer [Current For] returns when no record is currently in effect for the [Principal Ref] — never subscribed to a shape, or every record retired. A first-class outcome, not a rejection, and structurally what a blank argument gets. The composing pattern's fanout-on-no-record policy keys on it, and the deployment must disclose that policy (Composition note 5, Check 6.2).

Kind:      Member
Member of: the Current For answer
Role:      Outcome
Projects:  none

#### Already Deleted

The refusal [Delete] returns when the target is already [Deleted]. A [Suspended] record may still be deleted ([Suspended] → [Deleted]).

Kind:      Member
Member of: the Delete rejection
Role:      Outcome
Projects:  already-deleted

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Set]: #set
[Suspend]: #suspend
[Delete]: #delete
[Current For]: #current-for
[Read]: #read
[Preference Id]: #preference-id
[Principal Ref]: #principal-ref
[Channel Preferences]: #channel-preferences
[Frequency Limit]: #frequency-limit
[Quiet Hours]: #quiet-hours
[Format]: #format
[Metadata]: #metadata
[Set At]: #set-at
[Status]: #status
[Suspended At]: #suspended-at
[Deleted At]: #deleted-at
[Store Name]: #store-name
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

- **CAN-SPAM Act (15 U.S.C. §7701 et seq.)** — requires commercial email senders to honour unsubscribe requests within 10 business days and to provide a working opt-out mechanism in every commercial message. [Channel Preferences] with a channel-level opt-out value, combined with the composing fanout's enforcement, is the structural mechanism; immutability and durability produce the audit record enforcement requires.
- **Telephone Consumer Protection Act (TCPA, 47 U.S.C. §227)** — restricts automated and unsolicited calls and SMS, including frequency caps and time-of-day restrictions. [Frequency Limit] and [Quiet Hours], combined with the composing fanout's enforcement, are the mechanism for honouring these per principal.
- **GDPR Article 7(3)** — withdrawal of consent must be as easy as giving it. Article 7(3) is a *consent* obligation and belongs to [Consent](./consent.md), which owns the legal-permission axis. This atom satisfies an analogous *preference-update ease* principle: a principal changing channels, tightening a cap or pausing delivery calls [Set] or [Suspend] — the same surface that established the preferences. The ease claim here is scoped to shaping, not to consent withdrawal.
- **GDPR Article 21(2)** — right to object to processing for direct marketing; the objection must terminate marketing processing without delay. Full compliance is a two-atom obligation: this atom records the delivery-preference signal of the objection, encoded as the deployment's per-channel opt-out value inside [Channel Preferences], while [Consent](./consent.md) revokes the corresponding legal permission. A deployment that records the opt-out here without updating consent has not discharged Article 21.
- **ePrivacy Directive (2002/58/EC, as amended)** — consent and preference requirements for electronic communications in the EU. Marketing communication preferences fall under this directive's surface; this atom's record is the artifact a preferences page produces.
- **CASL (Canadian Anti-Spam Legislation)** — analogous to CAN-SPAM with stricter consent requirements; honouring per-principal channel preferences is the mechanism.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Channel Preferences], [Frequency Limit], [Quiet Hours] and [Format] as opaque deployment-vocabulary fields.
- **Eiffel's design-by-contract** — preconditions on [Set], [Suspend] and [Delete]; named rejection reasons.

---

## Status

`grounded on Final Critique 8 — 2026-08-26` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 8 — 2026-08-26
formal: verified — message-preference.tla + 1 twin, 2026-06-03
last gate: 2026-08-26 — Final Critique 8, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/message-preference.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the five actions as a signature block, the ten invariant numbers unchanged and Timestamp ordering kept outside them as its own label family, the six acceptance checks renumbered only into `Check N.k`, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk.

NOTE: End of Message Preference.

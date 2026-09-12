---
title: Notification
parent: Atomic Concepts
has_toc: true
toc: true
---

# Notification

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Notification records whether a single piece of information was accepted by the transport for a single recipient. Where Subscription records who wants to know about a class of events, Notification records the outcome of one delivery. It creates a permanent, unchangeable record of a delivery attempt and tracks it to one of three end states: [Delivered] (the transport layer confirmed receipt), [Failed] (the transport returned a definite error), or [Expired] (the delivery window ran out with no recorded outcome). These are kept as three distinct states because each answers a different question and is handled by a different part of the system — the delivery layer, the failure handler, the expiry scheduler. The pattern does not decide who should be notified or how to reach them; by the time it is asked to create a record, the recipient and the content are already settled. Nothing is ever deleted, so the full delivery history of any notification is always recoverable. This is what underlies delivery audit trails in regulated settings, and it is the substrate for retry logic, which records each retry as a new notification rather than altering the failed one.

---

## Intent

WHY:
A notification is a promise to tell somebody something, and the interesting part is not the telling — it is the record of whether it happened. Systems that skip this concept end up asking their transport layer what happened weeks ago, which is a question no transport layer can answer. The atom holds the delivery record: who it was for, what it said, when it was made, and exactly one outcome — reached, failed, or ran out of time. It sends nothing. It does not know what a webhook is, does not retry, does not decide whether a bounced email is a failure or an expiry. What it guarantees is that every attempt is one record with one terminal answer and a timestamp, so *did we tell them* is answered from the store rather than from a log nobody kept.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a notification by the notification_id.
Identity 2: The host MUST allocate a notification_id at the atom's seam.
Identity 3: The transition MUST NOT allocate a notification_id.
Identity 4: The business caller MUST NOT supply a notification_id.
Identity 5: The atom MUST NOT reuse a notification_id.
Identity 6: The atom MUST NOT identify a notification by the recipient_ref with the payload.
Identity 7: Two notifications carrying one recipient_ref and one payload MUST carry two notification_ids.
```

Terms › `notification`: one delivery record — one recipient, one payload, one outcome.

Terms › `notification_id`: the opaque value naming one notification — a [Notification Id].

Terms › `recipient_ref`: the opaque reference naming who the notification is for — a [Recipient Ref]; compared by equality and never interpreted.

Terms › `payload`: the opaque content the notification carries — a [Payload]; stored and returned unchanged.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the notification_id here.

Terms › `transition`: the atom's evaluation of one call against the notification store, as `execution-contract.md` §Logic confinement declares it.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition — a [Now], as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

WHY:
One attempt, one record. A retry is a new notification with a new id rather than a second outcome on the old one, which is what keeps *how many times did we try* answerable and stops a terminal record being rewritten (Identity 7, Non-goal 3).

### String input policy

```text
String 1: The atom MUST compare a string input byte-exactly.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 5: The atom MUST read a whitespace-only recipient_ref as empty.
String 6: IF a string input EXCEEDS the string cap THEN [Create] MUST answer invalid-request.
String 7: The business caller MUST own a recipient_ref's canonical form.
String 8: [Pending For] MUST read an over-length recipient_ref as matching nothing.
String 9: [Pending For] MUST read a whitespace-only recipient_ref as matching nothing.
```

Terms › `string cap`: the deployment's bound on a string input's length.

### State

```text
State 1: EVERY notification MUST stand in EXACTLY ONE OF pending, delivered, failed, expired.
State 2: EVERY notification MUST carry notification_id, recipient_ref, payload, created_at and status.
State 3: A delivered notification MUST carry delivered_at.
State 4: A failed notification MUST carry failed_at.
State 5: An expired notification MUST carry expired_at.
State 6: A pending notification MUST NOT carry a terminal stamp.
State 7: [Create] MUST stamp created_at from the injected now.
State 8: A terminal transition MUST stamp the transition's terminal stamp from the injected now.
State 9: The atom MUST NOT offer a transition out of a terminal status.
State 10: The atom MUST NOT delete a notification.
State 11: The atom MUST NOT hold a transport.
State 12: The atom MUST NOT hold a retry.
```

Terms › `status`: `pending` | `delivered` | `failed` | `expired` — the [Status] field's four values: awaiting an outcome, reached, attempted without success, or out of time.

Terms › `terminal stamp`: `delivered_at` | `failed_at` | `expired_at` — the one stamp a terminal status carries.

Terms › `created_at`: the instant the notification was recorded — a [Created At].

WHY:
Four states and exactly one terminal stamp each, because the audit question is *what happened to this one*, and a record carrying two terminal stamps answers it twice (State 6, Invariant 3.1). Nothing about transport lives here: a webhook, a push and an email produce the same three outcomes, and an atom that knew the difference would have to be re-specified every time a deployment changed channel (State 11).

### Operations

```
create(recipient_ref, payload) → notification_id | rejected(invalid-request | storage-failure)
deliver(notification_id) → ok | rejected(not-known | not-pending | storage-failure)
fail(notification_id) → ok | rejected(not-known | not-pending | storage-failure)
expire(notification_id) → ok | rejected(not-known | not-pending | storage-failure)
status_of(notification_id) → notification | not-known
pending_for(recipient_ref) → notification_ids
```

```text
Operation 1: [Create] MUST record EXACTLY ONE notification per successful call.
Operation 2: [Create] MUST stand the notification in pending.
Operation 3: [Create] MUST answer notification_id.
Operation 4: IF recipient_ref is empty THEN [Create] MUST answer invalid-request.
Operation 5: [Create] MUST accept an empty payload.
Operation 6: The atom MUST NOT read a payload.
Operation 7: IF the store refuses the write THEN [Create] MUST answer storage-failure.
Operation 8: IF the notification_id NOT EXISTS THEN a terminal transition MUST answer not-known.
Operation 9: IF the notification stands in a terminal status THEN a terminal transition MUST answer not-pending.
Operation 10: [Deliver] MUST stand the notification in delivered.
Operation 11: [Fail] MUST stand the notification in failed.
Operation 12: [Expire] MUST stand the notification in expired.
Operation 13: [Expire] MUST NOT require a delivery attempt.
Operation 14: The atom MUST NOT choose between fail and expire.
Operation 14a: The atom MUST NOT hold a delivery window.
Operation 14b: A composing pattern MUST own the delivery window an expiry answers to.
Operation 15: IF the store refuses the write THEN a terminal transition MUST answer storage-failure.
Operation 16: A refused call MUST leave the notification as the call found the notification.
Operation 17: [Status Of] MUST answer the notification's stored fields.
Operation 18: IF the notification_id NOT EXISTS THEN [Status Of] MUST answer not-known.
Operation 19: [Pending For] MUST answer the notification_id of EVERY pending notification carrying the recipient_ref.
Operation 20: [Pending For] MUST NOT answer a terminal notification's notification_id.
Operation 21: [Pending For] MUST NOT order the answer.
Operation 22: [Status Of] MUST NOT write.
Operation 23: [Pending For] MUST NOT write.
Operation 24: The host MUST read the clock at the atom's seam.
Operation 25: The transition MUST NOT read a clock.
Operation 26: The business caller MUST NOT supply now.
```

Terms › `terminal transition`: a [Deliver], a [Fail] or an [Expire] call — the three that end a notification, sharing one precondition pair.

Terms › `pending at an instant`: `created_at` at or before the instant, and the terminal stamp either absent or after the instant — the reconstruction an auditor runs over stored fields, never over `status`, which carries the present rather than the past.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification store |
|---|---|---|---|
| [Create] | recipient present, store accepts | `notification_id` | one notification lands in [Pending] (Operation 1, Operation 2) |
| [Create] | empty or whitespace-only recipient, or over the cap | [Invalid Request] | none (Operation 4, String 5, String 6) |
| [Create] | empty payload | `notification_id` | one notification lands — the payload is the caller's business (Operation 5, Operation 6) |
| [Deliver] | notification is pending | `ok` | [Pending] → [Delivered], `delivered_at` stamped (Operation 10, State 8) |
| [Fail] | notification is pending | `ok` | [Pending] → [Failed], `failed_at` stamped (Operation 11) |
| [Expire] | notification is pending, attempted or not | `ok` | [Pending] → [Expired], `expired_at` stamped (Operation 12, Operation 13) |
| any terminal transition | notification already terminal | [Not Pending] | none — including a second [Deliver] (Operation 9) |
| any terminal transition | id names nothing | [Not Known] | none (Operation 8) |
| any write | store refuses | `storage-failure` | none (Operation 7, Operation 15, Operation 16) |
| [Status Of] | id names a notification | its stored fields | none — the call reads (Operation 17, Operation 22) |
| [Status Of] | id names nothing | `not-known` | none (Operation 18) |
| [Pending For] | recipient has pending notifications | their ids, unordered | none (Operation 19, Operation 21) |
| [Pending For] | recipient has none, or only terminal ones | empty list | none (Operation 20) |
| [Pending For] | over-length or whitespace-only recipient | empty list | none — a read with a bad argument has a correct answer (String 8, String 9) |

WHY:
The three terminal transitions share one precondition pair — known, and pending — which is why they are one rule each and two rules between them rather than nine (Operation 8, Operation 9). Which operational event counts as a failure and which as an expiry is the deployment's policy and deliberately not the atom's: a bounced address is a failure in one shop and an expiry in another, and an atom that decided would make two deployments' records mean different things while looking identical (Operation 14, External check 1).

### Invariants

- **Invariant 1 — Notification immutability.**
  ```text
  Invariant 1.1: A recorded notification's notification_id, recipient_ref, payload and created_at MUST NOT change.
  Invariant 1.2: A landed terminal stamp MUST NOT change.
  ```
- **Invariant 2 — Status monotonicity.**
  ```text
  Invariant 2.1: A status MUST move from pending to EXACTLY ONE OF delivered, failed, expired.
  Invariant 2.2: A status MUST NOT move to pending from a terminal status.
  Invariant 2.3: A status MUST NOT move between two terminal statuses.
  Invariant 2.4: A notification MUST read as pending at an instant ONLY IF the notification is pending at an instant.
  ```
- **Invariant 3 — Terminal states are exclusive.**
  ```text
  Invariant 3.1: A notification standing in a terminal status MUST carry EXACTLY ONE terminal stamp.
  Invariant 3.2: A pending notification MUST NOT carry a terminal stamp.
  ```
- **Invariant 4 — Terminal timestamps match status.**
  ```text
  Invariant 4.1: A delivered notification MUST carry delivered_at.
  Invariant 4.2: A notification carrying delivered_at MUST stand in delivered.
  Invariant 4.3: A failed notification MUST carry failed_at.
  Invariant 4.4: A notification carrying failed_at MUST stand in failed.
  Invariant 4.5: An expired notification MUST carry expired_at.
  Invariant 4.6: A notification carrying expired_at MUST stand in expired.
  ```
- **Invariant 5 — Id stability.**
  ```text
  Invariant 5.1: [Create] MUST set the notification_id.
  Invariant 5.2: A notification_id MUST NOT change.
  ```
- **Invariant 6 — No id reuse.**
  ```text
  Invariant 6.1: Two notifications MUST NOT share a notification_id.
  ```
- **Invariant 7 — Pending query excludes terminals.**
  ```text
  Invariant 7.1: [Pending For] MUST answer a notification_id ONLY IF the notification stands in pending.
  ```
- **Invariant 8 — Timestamp ordering.**
  ```text
  Invariant 8.1: IF delivered_at EXISTS THEN created_at MUST NOT EXCEED delivered_at.
  Invariant 8.2: IF failed_at EXISTS THEN created_at MUST NOT EXCEED failed_at.
  Invariant 8.3: IF expired_at EXISTS THEN created_at MUST NOT EXCEED expired_at.
  ```
  WHY: best-effort under a clock that moves backward; the deployment owns clock discipline (Clock semantics 1–2).
- **Invariant 9 — Notification durability.**
  ```text
  Invariant 9.1: The atom MUST NOT delete a notification record.
  Invariant 9.2: The notification set MUST NOT shrink.
  Invariant 9.3: [Status Of] MUST answer a created notification's fields for the store's life.
  ```

Immutability and durability give *auditability* — the delivery history is the store, with no gaps. Exclusivity and the status-stamp match give the *unambiguous record* property — one outcome per notification, with a stable time. Monotonicity and ordering make [Pending For] a deterministic snapshot of what is still unresolved.

## Examples

The same atom, three domains, identical mechanic.

### Shared Todo — assignment notification delivery

A Notification Fanout pattern creates a notification when a task is assigned: `create(dev_d, {type: "task:assigned", task_id: t1, assigned_by: manager_m}) → notif_77`. The WebSocket layer pushes the payload to dev_d's active session and calls `deliver(notif_77)` → [Delivered]. `status_of(notif_77)` returns `status = delivered`, [Delivered At] set. `pending_for(dev_d)` returns `[]`.

If dev_d is offline, the push attempt produces a connection error: `fail(notif_77)` → [Failed]. The composing system may create a retry notification: `create(dev_d, {same payload}) → notif_78` — a new [Pending] record, distinct id, independent outcome.

If neither delivery nor failure is recorded within the expiry window: `expire(notif_77)` → [Expired]. `status_of(notif_77)` returns [Expired At].

### Support queue — escalation alert

When queue 9 escalates, the fanout pattern creates one notification per subscribed supervisor: `create(supervisor_s, {type: "escalation", queue: 9, ticket: t22}) → notif_33`. Email delivery succeeds: `deliver(notif_33)` → [Delivered]. `status_of(notif_33)` returns `status = delivered`, [Delivered At]. Elapsed delivery time is `delivered_at − created_at`.

Supervisor_s later asks *"was I notified about the queue-9 escalation?"* — `pending_for(supervisor_s)` returns an empty list (nothing pending), and `status_of(notif_33)` returns `status = delivered` with [Delivered At]. The delivery record answers the question from stored fields alone.

### Compliance system — policy change

An administrator broadcasts a policy update. Three compliance officers each receive a notification: `create(officer_a, {type: "policy:updated", policy_id: p7}) → notif_101`, similarly for officers b and c. Officer_a's email bounces: `fail(notif_101)`. Officers b and c are delivered successfully. `status_of(notif_101)` shows [Failed At]; `status_of(notif_102)` and `status_of(notif_103)` show [Delivered At]. An operator queries `pending_for` for each officer — empty for all three. The notification store shows: two [Delivered], one [Failed]; the composing system creates a retry for officer_a or escalates to a secondary channel.

### Rejection path — invalid create

A composing system attempts to create a notification with an empty recipient reference: `create(recipient_ref: "", payload: {type: "task:assigned", task_id: "t1"})` → `rejected(invalid-request)`. No [Notification Id] is issued; no record enters the store. The composing system must supply a non-empty recipient reference before the notification can be created.

### Regulated adversarial scenarios

Three scenarios the notification store must survive in regulated contexts:

- **Regulator audit — demonstrate all notifications for a compliance event.** A compliance auditor asks *"show all notifications created for the policy:updated event on 2025-03-14, and whether each was delivered."* The auditor queries the notification store for notifications where `created_at` falls on 2025-03-14 and the payload references the relevant policy. [Status Of] for each returned id shows the delivery outcome — [Delivered At], [Failed At], or [Expired At]. The notification store answers from stored fields alone; Invariants 1 and 3-4 guarantee the delivery record is complete and unambiguous.
- **Disputed delivery — actor claims they were not notified.** Officer_a claims they received no notification of policy update p7. The investigator queries the notification store for notifications where `recipient_ref = officer_a` and the payload references `policy_id: p7`. If a record exists with [Delivered At] set, Invariant 1 (notification immutability) is the structural answer: the notification was created with that recipient and delivery was confirmed at that time. If the record shows [Failed At] or [Expired At], the store confirms delivery was not completed and documents why. The notification store is the single source of truth; no external corroboration is required.
- **Breach investigation — identify Pending notifications that may have exposed payload data.** A security incident requires identifying all notifications that were [Pending] at the time of breach (2025-06-01T03:00Z) and may have carried sensitive payload data. The investigator queries for notifications where `created_at ≤ 2025-06-01T03:00Z` and either `status = pending` (still unresolved now) or the applicable terminal timestamp falls after 2025-06-01T03:00Z (meaning the notification was [Pending] during the breach window but has since resolved). The reconstruction logic mirrors the Subscription pattern: `created_at ≤ T` and (`status = pending` or `delivered_at > T` or `failed_at > T` or `expired_at > T`). [Status Of] for each candidate returns the current record; `created_at` confirms the exposure window. The notification store answers the exposure scope question from stored fields alone without recourse to logs or developer narration.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the notification store's stored fields, with no recourse to source code, runbooks or developer narration. The audit surface is the store, not the action surface.

### Conformance checks

```text
Check 1.1: An auditor MUST read EVERY notification's notification_id, recipient_ref, payload, created_at and status from the store (State 2).
Check 2.1: An auditor MUST reconstruct a notification's status at a past instant from created_at and the terminal stamp (Invariant 2.4).
Check 2.2: An auditor MUST read the reconstruction as deterministic on stored fields (Invariant 1.2).
Check 2.3: An auditor MUST read the reconstruction's wall-clock truth as best-effort (Invariant 8.1, Clock semantics 1).
Check 3.1: An auditor MUST find no notification carrying two terminal stamps (Invariant 3.1).
Check 3.2: An auditor MUST find no pending notification carrying a terminal stamp (Invariant 3.2).
Check 4.1: An auditor MUST find EVERY terminal stamp matching the notification's status (Invariant 4.2, Invariant 4.4, Invariant 4.6).
Check 5.1: An auditor MUST find the notification set never shrinking across two readings (Invariant 9.1, Invariant 9.2).
Check 6.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

### External checks

```text
External check 1: An auditor MUST read the deployment's fail-versus-expire policy from the deployment's own declaration (Operation 14).
External check 2: An auditor MUST read a payload's retention from the composing [Retention Window](./retention-window.md) records (Non-goal 13).
External check 3: An auditor MUST read who created a notification from the composing [Actor Identity](./actor-identity.md) attestations (Non-goal 11).
External check 4: An auditor MUST read the transport's own outcome from the deployment's delivery layer (Non-goal 5).
```

NOTE: EVERY check names the rule the check tests. External check 1 is the one that makes cross-deployment audit possible: without the declared policy, one shop's `failed_at` and another's `expired_at` record the same operational event and no reader can tell.

## Non-goals

```text
Non-goal 1: The atom MUST NOT evaluate a subscription.
Non-goal 2: The atom MUST NOT choose a notification's recipient.
Non-goal 3: The atom MUST NOT retry a failed notification.
Non-goal 4: A composing pattern retrying MUST create a second notification.
Non-goal 5: The atom MUST NOT deliver a notification.
Non-goal 6: The atom MUST NOT hold a transport's mechanism.
Non-goal 7: The atom MUST NOT order two pending notifications.
Non-goal 8: The atom MUST NOT record a recipient's reading.
Non-goal 9: A deployment needing a read acknowledgement MUST create a second notification for the acknowledgement.
Non-goal 10: The atom MUST NOT validate a payload.
Non-goal 11: The atom MUST NOT record who called [Create].
Non-goal 12: The atom MUST NOT deduplicate two notifications.
Non-goal 13: The atom MUST NOT purge a payload.
Non-goal 14: The atom MUST NOT gate [Create].
Non-goal 15: The atom MUST NOT expire notifications in bulk.
```

WHY:
Who should hear about an event is [Subscription](./subscription.md)'s and the fanout that reads it; this atom starts once the recipient is known (Non-goal 1, Non-goal 2). A retry is a new record rather than a second chance at an old one, which is what keeps the count of attempts honest (Non-goal 3, Non-goal 4). Read acknowledgement is two records because *the transport accepted it* and *the person saw it* are two facts, and one record forced to carry both loses whichever is recorded second (Non-goal 8, Non-goal 9). Payload retention is the sharp one: this store keeps every payload for the life of the system, so a deployment whose payloads carry personal or medical content composes [Retention Window](./retention-window.md) rather than trusting an atom that never forgets (Non-goal 13, Payload retention 1–3).

Where the atom breaks down: when *delivered* is not a single observable event — a multi-hop transport with partial acknowledgement; when the same notification must be retried in place, which this atom refuses on purpose; when the payload cannot be stored at all, which needs a reference rather than content.

## Edge cases

### Atomicity of a terminal transition

```text
Terminal atomicity 1: The implementation MUST change status and the terminal stamp together.
Terminal atomicity 2: A crash inside a terminal transition MUST NOT leave a terminal status without the terminal stamp.
Terminal atomicity 3: A crash inside a terminal transition MUST NOT leave a terminal stamp on a pending notification.
Terminal atomicity 4: The implementation MUST serialize two terminal transitions on one notification_id.
```

WHY:
Half a transition breaks Invariant 4 while every field reads plausibly on its own — and Invariant 4's two directions are exactly what an auditor uses to detect it, which is why the repair is the implementation's transactional boundary rather than a reader's inference (Terminal atomicity 1, Invariant 4.2).

### Deliver persistence failure

```text
Deliver persistence 1: A caller MUST read storage-failure from [Deliver] as the notification standing pending.
Deliver persistence 2: A caller MUST retry a deliver that answered storage-failure.
Deliver persistence 3: A caller MUST NOT deliver the payload a second time on that retry.
Deliver persistence 4: A high-assurance deployment MUST raise an alert on storage-failure from [Deliver].
```

WHY:
The transport accepted the notification and the store did not record it, so the record understates what happened — the recipient has been told and *did we tell them* answers no. The retry is a retry of the *write*, never of the send, which is the distinction a caller that treats the two alike gets wrong twice (Deliver persistence 2, Deliver persistence 3; the polarity [Permissions](./permissions.md) states for its own revoke).

### Payload retention

```text
Payload retention 1: The atom MUST keep a payload for the store's life.
Payload retention 2: The atom MUST NOT offer a payload purge.
Payload retention 3: A deployment whose payloads carry sensitive content MUST compose [Retention Window](./retention-window.md).
Payload retention 4: A composing pattern purging a payload MUST leave EVERY stored field as written.
Payload retention 5: A composing pattern MUST NOT delete a notification record.
```

WHY:
Invariant 1.1 forbids a payload changing and Invariant 9.2 forbids the set shrinking, so a composed purge cannot edit the payload or drop the record. What it can do is the shredding-class destruction [Audit Trail](../compositions/audit-trail.md) already wires over its own cascade: the content becomes unrecoverable while every stored field stands as written, which is why the invariants and the retention obligation do not collide (Payload retention 4, Payload retention 5).

### Bulk expiry

```text
Bulk expiry 1: A composing pattern MUST enumerate a recipient's pending notifications.
Bulk expiry 2: A composing pattern MUST call [Expire] for EVERY notification the enumeration returns.
Bulk expiry 3: A composing pattern MUST NOT read one expiry as a deadline sweep.
```

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: A deployment needing a defensible timeline MUST compose a trusted-timestamping pattern.
```

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST declare the deployment's fail-versus-expire policy.
Composition note 3: A composing pattern MUST own who is notified.
Composition note 4: A composing pattern MUST own the transport.
Composition note 5: A composing pattern needing at-most-once notification MUST guard [Create] with [Duplicate Prevention](./duplicate-prevention.md).
Composition note 6: A composing pattern MUST own a payload's retention.
Composition note 7: A composing pattern MUST own the delivery window.
```

WHY:
[Notification Fanout](../compositions/notification-fanout.md) is the wiring this atom was extracted for: an event fires, [Subscription](./subscription.md) answers who is listening, and one notification is created per subscriber — the composition owns the audience, this atom owns the record (Composition note 3). [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) adds [Message Preference](./message-preference.md) between the two. The fail-versus-expire policy is declared by the deployment rather than the atom, and it is what makes two deployments' records comparable (Composition note 2, External check 1).

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a recipient; an auditor; the store; a notification; a status.

Terms › `records`: `notification` — one delivery record, carrying `notification_id`, `recipient_ref`, `payload`, `created_at`, `status` and, once it ends, one terminal stamp.

Terms › `record verbs`: identify, allocate, supply, reuse, carry, compare, trim, normalize, case-fold, read, stand, stamp, offer, delete, hold, record, answer, accept, leave, refuse, order, write, change, move, set, share, shrink, keep, own, evaluate, choose, retry, create, deliver, validate, deduplicate, purge, gate, expire, enumerate, call, serialize, compose, guard, declare, find, reconstruct, raise, require, exceed.

Terms › `value sets`: create answers = notification_id | rejected(invalid-request | storage-failure). deliver answers = ok | rejected(not-known | not-pending | storage-failure). fail answers = ok | rejected(not-known | not-pending | storage-failure). expire answers = ok | rejected(not-known | not-pending | storage-failure). status_of answers = the notification's stored fields | not-known. pending_for answers = a list of notification_id, empty where nothing pends. `status` = pending | delivered | failed | expired. `terminal stamp` = delivered_at | failed_at | expired_at.

Terms › `bounds`: `string cap` (the deployment's bound on a string input's length).

Terms › `cadences`: empty — a delivery window is the composing pattern's (Operation 14b, Composition note 7).

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `notification`, `notification_id`, `recipient_ref`, `payload`, `seam`, `transition`, `business caller`, `now`, `string cap`, `status`, `terminal stamp`, `created_at`, `terminal transition`.

#### Create

The behavior that records a new delivery record. It assigns a fresh [Notification Id] (host-allocated at the seam), records [Recipient Ref], [Payload], and [Created At], and returns the [Notification Id] (or [Invalid Request]). The record enters [Pending].

Kind: Operation

#### Deliver

The behavior that records successful delivery, transitioning a [Pending] notification to terminal [Delivered] and stamping [Delivered At]. Rejected for an unknown id ([Not Known]) or a non-[Pending] notification ([Not Pending]).

Kind: Operation

#### Fail

The behavior that records a definitive delivery failure, transitioning a [Pending] notification to terminal [Failed] and stamping [Failed At]. Same preconditions as [Deliver].

Kind: Operation

#### Expire

The behavior that records lapse of the delivery window without an outcome, transitioning a [Pending] notification to terminal [Expired] and stamping [Expired At]. Same preconditions as [Deliver].

Kind: Operation

#### Status Of

The read-only query returning the full record for a [Notification Id] in any state, or [Not Known] if no notification has that id. Never transitions.

Kind: Operation

#### Pending For

The read-only query returning the [Notification Id] values of all [Pending] notifications addressed to a [Recipient Ref] (unordered; excludes terminals, Invariant 7). Never transitions.

Kind: Operation

#### Notification Id

The opaque, immutable identity of a notification — host-allocated at the I/O seam (the injected id), produced by [Create], never reused (Invariant 6). The recipient and payload are properties of the notification, not its identity.

Kind:     Field
Field of: the notification record
Projects: notification_id

#### Recipient Ref

The opaque reference to the intended recipient. Set on [Create], immutable. Equality is byte-exact (no normalization); [Pending For] filters on it.

Kind:     Field
Field of: the notification record
Projects: recipient_ref

#### Payload

The opaque content of the notification. Set on [Create], immutable, stored and returned unchanged — never parsed, validated, or interpreted by the atom.

Kind:     Field
Field of: the notification record
Projects: payload

#### Created At

The wall-time the notification was created, stamped from the injected clock at [Create]. Immutable (Invariant 1). The lower bound for any terminal timestamp (Invariant 8).

Kind:     Field
Field of: the notification record
Projects: created_at

#### Status

The notification's lifecycle state — [Pending], [Delivered], [Failed], or [Expired]. Set to [Pending] on [Create]; transitions once to a terminal (Invariant 2).

Kind:     Field
Field of: the notification record
Projects: status

#### Delivered At

The wall-time delivery was confirmed, stamped at [Deliver]. Present iff status is [Delivered] (Invariants 3 and 4); immutable once set.

Kind:     Field
Field of: the notification record
Projects: delivered_at

#### Failed At

The wall-time the failure was recorded, stamped at [Fail]. Present iff status is [Failed] (Invariants 3 and 4); immutable once set.

Kind:     Field
Field of: the notification record
Projects: failed_at

#### Expired At

The wall-time the expiry was recorded, stamped at [Expire]. Present iff status is [Expired] (Invariants 3 and 4); immutable once set.

Kind:     Field
Field of: the notification record
Projects: expired_at

#### Pending

The non-terminal state of a created notification whose delivery has not been confirmed, failed, or expired. May transition to exactly one terminal; [Pending For] returns only records in this state.

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Delivered

The terminal state of a notification that reached the recipient (transport confirmed). Carries [Delivered At]; absorbing (Invariant 2).

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Failed

The terminal state of a notification whose delivery was attempted and produced a definitive negative outcome. Carries [Failed At]; absorbing.

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Expired

The terminal state of a notification whose delivery window lapsed without a recorded outcome. Carries [Expired At]; absorbing.

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Now

The current clock reading every writing action consumes — supplied at the atom's seam, never read inside the transition and never a signature parameter. Its only use is the immutable stamps inside committed transitions ([Created At] and the terminal stamp).

Kind:         Parameter
Parameter of: Create, Deliver, Fail and Expire
Projects:     now

#### Invalid Request

The refusal [Create] returns when a request field fails its rule — an empty or whitespace-only [Recipient Ref] (Operation 4, String 5), or a string over the deployment's cap (String 6). An empty [Payload] is not a failure: Operation 5 accepts it.

Kind:      Member
Member of: the Create rejection
Role:      Outcome
Projects:  invalid-request

#### Not Known

The refusal [Deliver], [Fail], or [Expire] returns when the [Notification Id] references no notification in the store. Also the [Status Of] outcome for an unknown id.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-known

#### Not Pending

The refusal [Deliver], [Fail], or [Expire] returns when the target is not in [Pending] — i.e., already in a terminal state.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  not-pending

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Create]: #create
[Deliver]: #deliver
[Fail]: #fail
[Expire]: #expire
[Status Of]: #status-of
[Pending For]: #pending-for
[Notification Id]: #notification-id
[Recipient Ref]: #recipient-ref
[Payload]: #payload
[Created At]: #created-at
[Status]: #status
[Delivered At]: #delivered-at
[Failed At]: #failed-at
[Expired At]: #expired-at
[Pending]: #pending
[Delivered]: #delivered
[Failed]: #failed
[Expired]: #expired
[Now]: #now
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Not Pending]: #not-pending

---

## Standards references

- **Observer pattern** (GoF) — Notification is the structured-natural-language realization of the notification object: the message delivered from subject to observer.
- **SMTP / RFC 5321** — SMTP (Simple Mail Transfer Protocol, defined in the Internet standard RFC 5321) email delivery as the canonical push transport. The three terminal states map directly to SMTP disposition: 2xx success (Delivered), 5xx permanent failure (Failed), and timeout without delivery (Expired).
- **HTTP webhooks** — POST-to-URL delivery model standard in web systems. [Deliver] records a 2xx response; [Fail] records a 4xx/5xx or connection failure.
- **W3C Activity Streams 2.0** — semantic vocabulary for describing social and messaging events. Notification payloads in web deployments often conform to Activity Streams objects.
- **Apple Push Notification Service / Firebase Cloud Messaging** — platform push notification services where [Deliver] corresponds to accepted delivery and [Fail] corresponds to a rejected or unregistered token.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Payload] as an opaque reference whose semantics are defined by the composing system.
- **Eiffel's design-by-contract** — preconditions on [Deliver], [Fail], and [Expire]; named rejection reasons.

---


## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — notification.als + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```


## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/notification.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, the three terminal transitions sharing one declared term and one precondition pair, the nine invariant numbers unchanged, Generation acceptance as conformance checks plus external checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into notification` prints nothing, so no number is frozen from outside, and this atom completes [Notification Fanout](../compositions/notification-fanout.md)'s constituent set with [Subscription](./subscription.md).

NOTE: End of Notification.

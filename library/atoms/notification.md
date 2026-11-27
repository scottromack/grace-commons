---
title: Notification
id: 47
audience: common
---

# Notification

<details markdown="block">
<summary>Table of contents</summary>
1. TOC
{:toc}
</details>

## What it is

Notification records whether a single piece of information was accepted by the transport for a single recipient. Where a subscription pattern records who wants to know about a class of events, Notification records the outcome of one delivery. It creates a permanent, unchangeable record of a delivery attempt and tracks it to one of three end states: [Delivered] (the transport layer confirmed receipt), [Failed] (the transport returned a definite error), or [Expired] (the delivery window ran out with no recorded outcome). These are kept as three distinct states because each answers a different question and is handled by a different part of the system — the delivery layer, the failure handler, the expiry scheduler. The pattern does not decide who should be notified or how to reach them; by the time it is asked to create a record, the recipient and the content are already settled. Nothing is ever deleted, so the full delivery history of any notification is always recoverable. This is what underlies delivery audit trails in regulated settings, and it is the substrate for retry logic, which records each retry as a new notification rather than altering the failed one.

<details markdown="block">
<summary>WHY</summary>

A notification is a promise to tell somebody something, and the interesting part is not the telling — it is the record of whether it happened. Systems that skip this concept end up asking their transport layer what happened weeks ago, which is a question no transport layer can answer. The atom holds the delivery record: who it was for, what it said, when it was made, and exactly one outcome — reached, failed, or ran out of time. It sends nothing. It does not know what a webhook is, does not retry, does not decide whether a bounced email is a failure or an expiry. What it guarantees is that every attempt is one record with one terminal answer and a timestamp, so *did we tell them* is answered from the database rather than from a log nobody kept.

</details>

## What it keeps

### The notifications

```
Identity 1: The atom MUST identify a notification by the notification id.
Identity 2: The host MUST allocate a notification id at the atom's seam.
Identity 4: [Create] MUST NOT accept a notification id from the business caller.
Identity 5: The atom MUST NOT reuse a notification id.
Identity 6: The atom MUST NOT identify a notification by the recipient reference with the payload.
Identity 7: Two notifications carrying one recipient reference and one payload MUST carry two notification ids.
```

NOTE: watch the allocation ban (Execution Contract Logic confinement 3 owns it).

Term notification: one delivery record — one recipient, one payload, one status — a [Notification Record]; one for each notification id.

Term recipient reference: the opaque string naming who the notification is for — a [Recipient Reference]; compared by equality and never interpreted; malformed where it is no string.

Term payload: the opaque content the notification carries — a [Payload]; stored and returned unchanged. The atom sets no cap on its size: a payload the database refuses to write answers storage-failure (Operation 7).

Term delivery outcome: what a delivery attempt — the composing pattern's own, as it owns the transport (Composition note 4) — ended in, as that pattern's records hold it for a pending notification, or none where its delivery window ended with none recorded (Operation 13, Operation 14b); the value the deployment's declared fail-versus-expire policy names for failing or for expiring (Non-goal 5, Capability requirement 8); the atom keeps none (State 2).

NOTE: watch the seam citation (Term seam, Term transition, Term business caller).

```
State 1: EVERY notification MUST stand in EXACTLY ONE OF pending, delivered, failed, expired.
State 2: EVERY notification MUST carry notification id, recipient reference, payload, creation instant and status.
State 3: A delivered notification MUST carry delivery instant.
State 4: A failed notification MUST carry failure instant.
State 5: An expired notification MUST carry lapse instant.
State 6: A pending notification MUST NOT carry a terminal stamp.
State 7: [Create] MUST stamp creation instant from the injected now.
State 8: A terminal transition MUST stamp the transition's terminal stamp from the injected now.
State 9: The atom MUST NOT offer a transition out of a terminal status.
State 10: The atom MUST NOT delete a notification.
State 11: The atom MUST NOT hold a transport.
State 12: The atom MUST NOT hold a retry.
```

Term status: pending | delivered | failed | expired — the [Status] field's four values: awaiting an outcome, reached, ended as failed, or ended as expired.

Term terminal stamp: delivery instant | failure instant | lapse instant — the one stamp a terminal status carries.

Term creation instant: the instant the notification was recorded — a [Creation Instant].

Term notification set: the notifications the database holds.

#### Notification Record

Holds the notification id, the recipient reference, the payload, the creation instant, the status and, once the notification ends, its one terminal stamp. A notification id that no record carries names no notification.

Kind: Type

#### Notification Id

The opaque, immutable identity of a notification — host-allocated at the I/O seam (the injected id), produced by [Create], never reused (Invariant 6). The recipient and payload are properties of the notification, not its identity.

Kind:       Field
Field of:   Notification Record
Projection: notification_id

#### Recipient Reference

The opaque reference to the intended recipient. Set on [Create], immutable. Equality is byte-exact (no normalization); [Pending For] filters on it.

Kind:       Field
Field of:   Notification Record
Projection: recipient_ref

#### Payload

The opaque content of the notification. Set on [Create], immutable, stored and returned unchanged — never parsed, validated, or interpreted by the atom.

Kind:       Field
Field of:   Notification Record
Projection: payload

#### Creation Instant

The wall-time the notification was created, stamped from the injected clock at [Create]. Immutable (Invariant 1). The lower bound for any terminal timestamp (Invariant 8, Execution Contract Logic confinement 7).

Kind:       Field
Field of:   Notification Record
Projection: created_at

#### Status

The notification's lifecycle state — [Pending], [Delivered], [Failed], or [Expired]. Set to [Pending] on [Create]; transitions once to a terminal (State 1, Invariant 2).

Kind:       Field
Field of:   Notification Record
Projection: status

#### Delivery Instant

The wall-time delivery was confirmed, stamped at [Deliver]. Present iff status is [Delivered] (State 3, Invariant 4.2); immutable once set.

Kind:       Field
Field of:   Notification Record
Projection: delivered_at

#### Failure Instant

The wall-time the failure was recorded, stamped at [Fail]. Present iff status is [Failed] (State 4, Invariant 4.4); immutable once set.

Kind:       Field
Field of:   Notification Record
Projection: failed_at

#### Lapse Instant

The wall-time the expiry was recorded, stamped at [Expire]. Present iff status is [Expired] (State 5, Invariant 4.6); immutable once set.

Kind:       Field
Field of:   Notification Record
Projection: expired_at

#### Pending

The non-terminal state of a created notification whose delivery has not been confirmed, failed, or expired. May transition to exactly one terminal; [Pending For] returns only records in this state.

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Delivered

The terminal state of a notification that reached the recipient (transport confirmed). Carries [Delivery Instant]; absorbing (Invariant 2).

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Failed

The terminal state of a notification a composing pattern ended as failed, under the deployment's declared fail-versus-expire policy (Operation 14, Capability requirement 8). Carries [Failure Instant]; absorbing.

Kind:      Member
Member of: the notification status
Role:      Outcome

#### Expired

The terminal state of a notification a composing pattern ended as expired, under the deployment's declared fail-versus-expire policy (Operation 14, Operation 14b, Capability requirement 8). Carries [Lapse Instant]; absorbing.

Kind:      Member
Member of: the notification status
Role:      Outcome

Term notification id: the opaque string naming one notification — a [Notification Id]; malformed where it is no string.

## What people do

### Every action

Term notification ids: the [Notification Id] values of every pending notification addressed to a recipient reference — the answer [Pending For] gives, in the order Execution Contract Read 5 states.

```
Operation 6: The atom MUST NOT evaluate a payload.
Operation 8: IF no notification EXISTS for the notification id THEN a terminal transition MUST answer not-known.
Operation 9: IF the notification's status DOES NOT EQUAL pending THEN a terminal transition MUST answer not-pending.
Operation 14: The atom MUST NOT choose between fail and expire.
Operation 14a: The atom MUST NOT hold a delivery window.
Operation 14b: A composing pattern MUST own the delivery window an expiry answers to.
Operation 15: IF the database refuses the write THEN a terminal transition MUST answer storage-failure.
Operation 16: A refused call MUST leave the notification as the call found the notification.
Operation 32: IF a notification id is malformed THEN a terminal transition MUST answer not-known (Execution Contract Input 1).
```

NOTE: watch the required input no rule records (Execution Contract Input 4 owns it).

NOTE: watch the untyped input (Operation 31, Operation 32, Operation 33, Term notification id, Term recipient reference).

NOTE: the ids a [Pending For] answers come in the order Execution Contract Read 5 states; no rule of this atom names another (Operation 19).

NOTE: watch the order an atom forbids (Execution Contract Read 5 owns the order).

Term terminal transition: a [Deliver], a [Fail] or an [Expire] call — the three that end a notification, sharing one precondition pair.

Term pending at an instant: the instant DOES NOT PRECEDE creation instant, and either the notification carries no terminal stamp or the instant PRECEDES the terminal stamp the notification carries, each field read as the record stood at the commit the read answers from — the reconstruction an auditor runs over stored fields, never over status, which carries the present rather than the past.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| any terminal transition | notification already terminal | [Not Pending] | none — including a second [Deliver]; the landed terminal stamp stands (Operation 9, Invariant 1.2) |
| any terminal transition | id names nothing, or is malformed | [Not Known] | none (Operation 8, Operation 32) |
| any write | database refuses | [Storage Failure] | none (Operation 7, Operation 15, Operation 16) |

#### Not Known

The refusal [Deliver], [Fail], or [Expire] returns when the [Notification Id] references no notification in the database (Operation 8) or is malformed (Operation 32). Also the [Status Of] outcome for an unknown id (Operation 18) or a malformed id (Operation 18b).

Kind:       Member
Member of:  the action rejection
Role:       Rejection
Projection: not-known

#### Not Pending

The refusal [Deliver], [Fail], or [Expire] returns when the target is not in [Pending] — i.e., already in a terminal state.

Kind:       Member
Member of:  the action rejection
Role:       Rejection
Projection: not-pending

#### Storage Failure

The refusal [Create], [Deliver], [Fail] or [Expire] returns when the database refuses the call's write after its guards pass (Operation 7, Operation 15). The notification records stand as the call found them (Operation 16), and a caller reads it from [Deliver] as a notification still pending (Deliver persistence 1).

Kind:       Member
Member of:  the action rejection
Role:       Rejection
Projection: storage-failure

### Create

#### Create

The behavior that records a new delivery record. It assigns a fresh [Notification Id] (host-allocated at the seam), records [Recipient Reference], [Payload], and [Creation Instant], and returns the [Notification Id] (or [Invalid Request]). The record enters [Pending].

Kind: Operation

```
create(recipient_ref, payload)
  answers notification_id
  refuses invalid-request | storage-failure
```

```
Operation 1: [Create] MUST record EXACTLY ONE notification per successful call.
Operation 2: [Create] MUST stand the notification in pending.
Operation 3: [Create] MUST answer notification id.
Operation 4: IF recipient reference EQUALS blank THEN [Create] MUST answer invalid-request.
Operation 5: [Create] MUST accept an empty payload.
Operation 7: IF the database refuses the write THEN [Create] MUST answer storage-failure.
Operation 31: IF a recipient reference is malformed THEN [Create] MUST answer invalid-request (Execution Contract Input 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Create] | recipient present, database accepts | notification id | one notification lands in [Pending] (Operation 1, Operation 2, Execution Contract Input 4) |
| [Create] | blank or malformed recipient, or over the cap | [Invalid Request] | none (Operation 4, Operation 31, String 6) |
| [Create] | empty payload | notification id | one notification lands — the payload is the caller's business (Operation 5, Operation 6) |

#### Invalid Request

The refusal [Create] returns when a request field fails its rule — a blank [Recipient Reference] (Operation 4), a malformed [Recipient Reference] (Operation 31), or a recipient reference over the deployment's cap (String 6). An empty [Payload] is not a failure: Operation 5 accepts it.

Kind:       Member
Member of:  the Create rejection
Role:       Rejection
Projection: invalid-request

### Deliver

#### Deliver

The behavior that records successful delivery, transitioning a [Pending] notification to terminal [Delivered] and stamping [Delivery Instant]. Rejected for an unknown or malformed id ([Not Known]) or a non-[Pending] notification ([Not Pending]).

Kind: Operation

```
deliver(notification_id)
  answers ok
  refuses not-known | not-pending | storage-failure
```

```
Operation 10: [Deliver] MUST stand the notification in delivered.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Deliver] | notification is pending | ok | [Pending] → [Delivered], delivery instant stamped; the notification id, recipient reference, payload and creation instant stand (Operation 10, State 8, Invariant 1.1) |

### Fail

#### Fail

The behavior that records a definitive delivery failure, transitioning a [Pending] notification to terminal [Failed] and stamping [Failure Instant]. Same preconditions as [Deliver].

Kind: Operation

```
fail(notification_id)
  answers ok
  refuses not-known | not-pending | storage-failure
```

```
Operation 11: [Fail] MUST stand the notification in failed.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Fail] | notification is pending | ok | [Pending] → [Failed], failure instant stamped; the notification id, recipient reference, payload and creation instant stand (Operation 11, Invariant 1.1) |

### Expire

#### Expire

The behavior that records lapse of the delivery window without an outcome, transitioning a [Pending] notification to terminal [Expired] and stamping [Lapse Instant]. Same preconditions as [Deliver].

Kind: Operation

```
expire(notification_id)
  answers ok
  refuses not-known | not-pending | storage-failure
```

```
Operation 12: [Expire] MUST stand the notification in expired.
Operation 13: [Expire] MUST NOT require a delivery attempt.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Expire] | notification is pending, attempted or not | ok | [Pending] → [Expired], lapse instant stamped; the notification id, recipient reference, payload and creation instant stand (Operation 12, Operation 13, Invariant 1.1) |

### Status Of

#### Status Of

The read-only query returning the full record for a [Notification Id] in any state, or [Not Known] if no notification has that id or the id is malformed (Operation 18, Operation 18b). Never transitions.

Kind: Operation

```
status_of(notification_id)
  answers notification_record | not-known
```

```
Operation 17: [Status Of] MUST answer the notification's stored fields.
Operation 18: IF no notification EXISTS for the notification id THEN [Status Of] MUST answer not-known.
Operation 18b: IF a notification id is malformed THEN [Status Of] MUST answer not-known (Execution Contract Query 1, Query 5).
Operation 22: [Status Of] MUST NOT write.
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Status Of] | id names a notification | its stored fields | none — the call reads (Operation 17, Operation 22) |
| [Status Of] | id names nothing, or is malformed | not-known | none (Operation 18, Operation 18b) |

### Pending For

#### Pending For

The read-only query returning the [Notification Id] values of all [Pending] notifications addressed to a [Recipient Reference] (in the order Execution Contract Read 5 states; excludes terminals, Operation 20). Never transitions.

Kind: Operation

```
pending_for(recipient_ref)
  answers notification_ids
```

```
Operation 19: [Pending For] MUST answer the notification id of EVERY pending notification carrying the recipient reference.
Operation 20: [Pending For] MUST NOT answer a terminal notification's notification id.
Operation 23: [Pending For] MUST NOT write.
Operation 33: IF a recipient reference is malformed THEN [Pending For] MUST answer an empty list (Execution Contract Query 1).
```

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the notification records |
|---|---|---|---|
| [Pending For] | recipient has pending notifications | their ids, in Execution Contract Read 5's order | none (Operation 19, Execution Contract Read 5) |
| [Pending For] | recipient has none, or only terminal ones | empty list | none (Operation 20) |
| [Pending For] | malformed, over-length or blank recipient | empty list | none — a read with a bad argument has a correct answer (Operation 33, String 8, String 9) |

## What is and what should never be (Invariants)

- **Invariant 1 — Notification immutability.**
  ```
  Invariant 1.1: A recorded notification's notification id, recipient reference, payload and creation instant MUST NOT change.
  Invariant 1.2: A landed terminal stamp MUST NOT change.
  ```
- **Invariant 2 — Status monotonicity.**
  ```
  Invariant 2.2: A status MUST NOT move to pending from a terminal status.
  Invariant 2.3: A status MUST NOT move between two terminal statuses.
  Invariant 2.4: A read of the notification records MUST answer pending ONLY IF the notification carries no terminal stamp as the record stood at the commit the read answers from.
  ```
- **Invariant 3 — Terminal states are exclusive.**
  ```
  Invariant 3.1: A notification whose status DOES NOT EQUAL pending MUST carry EXACTLY ONE terminal stamp.
  ```
- **Invariant 4 — Terminal timestamps match status.**
  ```
  Invariant 4.2: A notification carrying delivery instant MUST stand in delivered.
  Invariant 4.4: A notification carrying failure instant MUST stand in failed.
  Invariant 4.6: A notification carrying lapse instant MUST stand in expired.
  ```
- **Invariant 5 — Id stability.**
  ```
  Invariant 5.1: A recorded notification MUST carry the notification id the host allocated at the atom's seam (Identity 2).
  ```
- **Invariant 6 — No id reuse.**
  ```
  Invariant 6.1: Two notifications MUST NOT share a notification id.
  ```
- **Invariant 8 — Timestamp ordering.**
  ```
  Invariant 8.1: IF delivery instant DOES NOT EQUAL blank THEN delivery instant MUST NOT PRECEDE creation instant (Execution Contract Logic confinement 7).
  Invariant 8.2: IF failure instant DOES NOT EQUAL blank THEN failure instant MUST NOT PRECEDE creation instant (Execution Contract Logic confinement 7).
  Invariant 8.3: IF lapse instant DOES NOT EQUAL blank THEN lapse instant MUST NOT PRECEDE creation instant (Execution Contract Logic confinement 7).
  ```
- **Invariant 9 — Notification durability.**
  ```
  Invariant 9.1: The atom MUST NOT delete a notification record.
  Invariant 9.2: The notification set MUST NOT shrink.
  Invariant 9.3: A created notification MUST carry notification id, recipient reference, payload, creation instant and status for the database's life.
  ```

Immutability and durability give *auditability* — the delivery history is the database, with no gaps. Exclusivity and the status-stamp match give the *unambiguous record* property — one outcome per notification, with a stable time. Monotonicity and ordering make [Pending For] a deterministic snapshot of what is still unresolved.

## When something happens

### Bulk expiry

```
Bulk expiry 1: A composing pattern expiring in bulk MUST enumerate a recipient's pending notifications.
Bulk expiry 2: A composing pattern expiring in bulk MUST call [Expire] for EVERY notification the enumeration returns whose delivery outcome the deployment's declared fail-versus-expire policy names for expiring (Composition note 8, Capability requirement 8).
Bulk expiry 3: A composing pattern MUST NOT read one [Expire] call as the expiry of any notification but the one the call names.
```

### Deliver persistence failure

```
Deliver persistence 1: A caller MUST read storage-failure from [Deliver] as the notification whose status EQUALS pending as the call found the notification.
Deliver persistence 2: A caller MUST retry a terminal transition that answered storage-failure, and the caller owns the interval and every retry past the first.
Deliver persistence 3: A caller MUST NOT deliver the payload a second time on that retry, nor on a repeat of a terminal transition whose reply was lost (Deliver persistence 5).
Deliver persistence 4: A high-assurance deployment MUST raise an alert on storage-failure from [Deliver] to the receiver the deployment declares.
Deliver persistence 5: A caller whose reply to a terminal transition was lost MUST read [Status Of] for the notification (Execution Contract Error model 1).
Deliver persistence 6: A caller MUST NOT deliver the payload again on a [Status Of] answer whose status DOES NOT EQUAL pending (Deliver persistence 5).
```

### Payload retention

```
Payload retention 1: The atom MUST keep a payload for the database's life.
Payload retention 2: The atom MUST NOT offer a payload purge.
Payload retention 3: A deployment whose payloads carry sensitive content MUST compose a retention pattern.
Payload retention 4: A composing pattern MUST purge a payload by a shred that leaves EVERY stored field as written (Execution Contract Database 5).
Payload retention 5: A composing pattern MUST NOT delete a notification record.
```

<details markdown="block">
<summary>WHY</summary>

What a composed purge can do is a shred, as an audit pattern wires one over its own cascade (Payload retention 4, Payload retention 5); a shred removes no version, and a purge another specification declares is answered by that specification's records (Execution Contract Database 5, Execution Contract Database 6).

</details>

## While something is so

### String policy

```
String 1: The atom MUST compare a string input byte for byte.
String 2: The atom MUST NOT trim a string input.
String 3: The atom MUST NOT normalize a string input.
String 4: The atom MUST NOT case-fold a string input.
String 6: IF the recipient reference EXCEEDS the string cap THEN [Create] MUST answer invalid-request.
String 7: The business caller MUST own a recipient reference's canonical form.
String 8: [Pending For] MUST read an over-length recipient reference as matching nothing.
String 9: [Pending For] MUST read a blank recipient reference as matching nothing.
```

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 4: The deployment MUST supply the notification records PER Execution Contract Database 1 through 5, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
Capability requirement 5: The deployment MAY declare the string cap PER Execution Contract Input 2.
Capability requirement 6: The deployment MUST NOT change the string cap for the life of the instance, a restart included (Execution Contract Logic confinement 17); this rule stands in place of the change Execution Contract Input 2 lets a cap take at a later start.
Capability requirement 7: The deployment MUST declare which composing patterns the deployment wired in PER Execution Contract Conformance 9.
Capability requirement 8: The deployment MUST declare the deployment's fail-versus-expire policy, naming the delivery outcomes a composing pattern calls [Fail] for and the delivery outcomes a composing pattern calls [Expire] for, and naming no delivery outcome for both (Execution Contract Logic confinement 15, Execution Contract Logic confinement 17).
Capability requirement 9: The deployment MUST supply at the seam a notification id no notification has carried PER Execution Contract Logic confinement 3 and Execution Contract Logic confinement 16.
Capability requirement 10: The deployment MAY declare the deployment high-assurance.
Capability requirement 11: A high-assurance deployment MUST declare the receiver of the alert Deliver persistence 4 raises.
```

NOTE: watch the deployment's composition note (Capability requirement 7).

#### Now

The current clock reading every writing action consumes — supplied at the atom's seam, never read inside the transition and never supplied by the business caller. Its only use is the immutable stamps inside committed transitions ([Creation Instant] and the terminal stamp).

Kind:         Parameter
Parameter of: Create, Deliver, Fail and Expire
Projection:   now

Term seam: the atom's I/O boundary as Execution Contract Logic confinement 14 declares it; the host injects the clock reading and the notification id here.

Term transition: the evaluation of one call against the notification records, as Execution Contract Logic confinement 14 declares it.

Term business caller: the business caller per Execution Contract Logic confinement 14.

Term now: the deployment's clock reading at the call — a [Now], as Execution Contract Logic confinement 11 declares it; the atom spends no clock allowance, since Invariant 8.1 through 8.3 compare a terminal stamp a call writes from now only with the creation instant an earlier call stamped from the deployment's one clock, whose monotonicity and agreement across nodes the deployment owns (Execution Contract Logic confinement 7 and Execution Contract Logic confinement 18).

Term high-assurance deployment: a deployment that declares itself so (Capability requirement 10); the class and the receiver of its alert are the deployment's own, never the atom's (Capability requirement 11).

Term string cap: the bound on the recipient reference's length, measured in Unicode code points; 256 code points where a deployment declares none.

## Needs

The bonds this atom needs, of a bond kind [Bonds](../bonds.md) states. It states none yet. The recipient reference is a held reference: an opaque pointer to someone else's record, compared by equality and never interpreted. Its key need, `key opaque`, comes with the held-reference batch that follows Tag, which lists this atom beside Favorite, Reaction, Comment and Category. The payload is content and takes no need.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer key: key notification id; carried by notifications; calls Status Of.

## Left to others

```
Non-goal 1: The atom MUST NOT evaluate a subscription.
Non-goal 2: The atom MUST NOT choose a notification's recipient.
Non-goal 3: The atom MUST NOT retry a failed notification.
Non-goal 4: A composing pattern retrying MUST create a second notification.
Non-goal 5: The atom MUST NOT deliver a notification.
Non-goal 6: The atom MUST NOT hold a transport's mechanism.
Non-goal 8: The atom MUST NOT record a recipient's reading.
Non-goal 9: A deployment needing a read acknowledgement MUST create a second notification for the acknowledgement.
Non-goal 10: The atom MUST NOT validate a payload.
Non-goal 11: The atom MUST NOT record who called [Create].
Non-goal 12: The atom MUST NOT deduplicate two notifications.
Non-goal 13: The atom MUST NOT purge a payload.
Non-goal 14: The atom MUST NOT gate [Create] on a caller's authority.
Non-goal 15: The atom MUST NOT expire notifications in bulk.
Non-goal 16: A deployment needing a defensible timeline MUST compose a trusted time-stamping pattern.
```

NOTE: the owners — a subscription pattern and a fanout pattern (Non-goal 1, Non-goal 2; the library holds them as Subscription and Notification Fanout); a retention pattern (Non-goal 13, Payload retention 3; the library's Defensible Retention); an idempotency pattern (Non-goal 12, Composition note 5; the library's Duplicate Prevention); the composing pattern that retries (Non-goal 3, Non-goal 4); an attestation pattern, which says who created a notification (Non-goal 14, External check 3).

Where the atom breaks down: when *delivered* is not a single observable event — a multi-hop transport with partial acknowledgement; when the same notification must be retried in place, which this atom refuses on purpose; when the payload cannot be stored at all, which needs a reference rather than content.

```
Composition note 3: A composing pattern MUST own who is notified.
Composition note 4: A composing pattern MUST own the transport.
Composition note 5: A composing pattern needing at-most-once notification MUST guard [Create] with an idempotency pattern.
Composition note 6: A composing pattern MUST own a payload's retention.
Composition note 8: A composing pattern MUST call [Fail] for each delivery outcome the deployment's declared fail-versus-expire policy names for failing, and [Expire] for each delivery outcome the declared policy names for expiring (Operation 14, Capability requirement 8).
```

NOTE: composing patterns — a fanout pattern and a preference-aware fanout pattern.

## Example

The same atom, three domains, identical mechanic.

### Shared Todo — assignment notification delivery

A fanout pattern creates a notification when a task is assigned: `create(dev_d, {type: "task:assigned", task_id: t1, assigned_by: manager_m}) → notif_77`. The WebSocket layer pushes the payload to dev_d's active session and calls `deliver(notif_77)` → [Delivered]. `status_of(notif_77)` returns `status = delivered`, [Delivery Instant] set. `pending_for(dev_d)` returns `[]`.

The three outcomes of `notif_77` are alternatives, one of them recorded and never two (Invariant 2.3): the walkthrough below shows each as the one a different delivery attempt ends in, not three steps in one sequence.

If dev_d is offline, the push attempt produces a connection error: `fail(notif_77)` → [Failed]. The composing system may create a retry notification: `create(dev_d, {same payload}) → notif_78` — a new [Pending] record, distinct id, independent outcome.

If neither delivery nor failure is recorded within the expiry window: `expire(notif_77)` → [Expired]. `status_of(notif_77)` returns [Lapse Instant].

### Support queue — escalation alert

When queue 9 escalates, the fanout pattern creates one notification per subscribed supervisor: `create(supervisor_s, {type: "escalation", queue: 9, ticket: t22}) → notif_33`. Email delivery succeeds: `deliver(notif_33)` → [Delivered]. `status_of(notif_33)` returns `status = delivered`, [Delivery Instant]. Elapsed delivery time is `delivered_at − created_at`.

Supervisor_s later asks *"was I notified about the queue-9 escalation?"* — `pending_for(supervisor_s)` returns an empty list (nothing pending), and `status_of(notif_33)` returns `status = delivered` with [Delivery Instant]. The delivery record answers the question provably, from stored fields.

### Compliance system — policy change

An administrator broadcasts a policy update. Three compliance officers each receive a notification: `create(officer_a, {type: "policy:updated", policy_id: p7}) → notif_101`, similarly for officers b and c. Officer_a's email bounces: `fail(notif_101)`. Officers b and c are delivered successfully. `status_of(notif_101)` shows [Failure Instant]; `status_of(notif_102)` and `status_of(notif_103)` show [Delivery Instant]. An operator queries pending_for for each officer — empty for all three. The notification records show: two [Delivered], one [Failed]; the composing system creates a retry for officer_a or escalates to a secondary channel.

### Rejection path — invalid create

A composing system attempts to create a notification with an empty recipient reference: `create(recipient_ref: "", payload: {type: "task:assigned", task_id: "t1"})` → invalid-request. No [Notification Id] is issued; no record enters the database. The composing system must supply a non-empty recipient reference before the notification can be created.

### Regulated adversarial scenarios

Three scenarios the notification records must survive in regulated contexts:

- **Regulator audit — demonstrate all notifications for a compliance event.** A compliance auditor asks *"show all notifications created for the policy:updated event on 2025-03-14, and whether each was delivered."* The auditor queries the notification records for notifications where creation instant falls on 2025-03-14 and the payload references the relevant policy. [Status Of] for each returned id shows the delivery outcome — [Delivery Instant], [Failure Instant], or [Lapse Instant]. The notification records answer provably, from stored fields; Invariants 1 and 3-4 guarantee the delivery record is complete and unambiguous.
- **Disputed delivery — actor claims they were not notified.** Officer_a claims they received no notification of policy update p7. The investigator queries the notification records for notifications where `recipient_ref = officer_a` and the payload references `policy_id: p7`. If a record exists with [Delivery Instant] set, Invariant 1 (notification immutability) is the structural answer: the notification was created with that recipient and delivery was confirmed at that time. If the record shows [Failure Instant] or [Lapse Instant], the notification records show that no delivery was recorded, and which outcome was recorded instead. The notification records are the single source of truth for what was recorded; whether the transport reached the recipient regardless is the delivery layer's own record (External check 4).
- **Breach investigation — identify Pending notifications that may have exposed payload data.** A security incident requires identifying all notifications that were [Pending] at the time of breach (2025-06-01T03:00Z) and may have carried sensitive payload data. The investigator queries for notifications where `created_at ≤ 2025-06-01T03:00Z` and either `status = pending` (still unresolved now) or the applicable terminal timestamp falls after 2025-06-01T03:00Z (meaning the notification was [Pending] during the breach window but has since resolved). The reconstruction logic mirrors a subscription pattern's: `created_at ≤ T` and (`status = pending` or `delivered_at > T` or `failed_at > T` or `expired_at > T`). [Status Of] for each candidate returns the current record; creation instant confirms the exposure window. The notification records answer the exposure scope question provably, from stored fields.

---

## Source

- **Observer pattern** (GoF — the Gang of Four, the four authors of *Design Patterns*) — the subject-and-observer side is the library's Subscription and Notification Fanout (Non-goal 1, Non-goal 2); Notification records only the outcome of one message to one recipient, the delivery itself being the transport's (Non-goal 5).
- **SMTP / RFC 5321** — SMTP (Simple Mail Transfer Protocol, defined in the Internet standard RFC (Request for Comments) 5321) email delivery as the canonical push transport. Two of the three terminal states map to an SMTP disposition: 2xx success (Delivered) and 5xx permanent failure (Failed); timeout without delivery (Expired) maps to none, since SMTP has no terminal disposition for it and the composing pattern owns the delivery window (Operation 14b).
- **HTTP (HyperText Transfer Protocol — the request/response protocol of the web) webhooks** — the delivery model standard in web systems, an HTTP POST (the request that sends data) to a URL. [Deliver] records a 2xx response; [Fail] records a 4xx/5xx or connection failure.
- **W3C (World Wide Web Consortium — the web standards body) Activity Streams 2.0** — semantic vocabulary for describing social and messaging events. Notification payloads in web deployments often conform to Activity Streams objects.
- **Apple Push Notification Service / Firebase Cloud Messaging** — platform push notification services where [Deliver] corresponds to accepted delivery and [Fail] corresponds to a rejected or unregistered token.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Payload] as an opaque reference whose semantics are defined by the composing system.
- **Eiffel's design-by-contract** — preconditions on [Deliver], [Fail], and [Expire]; named rejection reasons.

---

## Proof

### Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the notification records' stored fields, with their committed versions (Execution Contract Generation acceptance 1). The audit surface is the database, not the action surface.

#### Conformance checks

```
Check 1.1: An auditor MUST read EVERY notification's notification id, recipient reference, payload, creation instant and status from the database (State 2).
Check 2.1: An auditor MUST reconstruct whether a notification is pending at an instant from creation instant and the terminal stamp (Invariant 2.2, Invariant 2.3).
Check 2.2: An auditor MUST read the reconstruction as deterministic on stored fields (Invariant 1.1, Invariant 1.2).
Check 2.3: An auditor MUST read the reconstruction's wall-clock truth as best-effort (Invariant 8.1 through 8.3, Execution Contract Logic confinement 7).
Check 3.1: An auditor MUST find EVERY notification whose status DOES NOT EQUAL pending carrying EXACTLY ONE terminal stamp (Invariant 3.1).
Check 3.2: An auditor MUST find no pending notification carrying a terminal stamp (State 6).
Check 4.1: An auditor MUST find EVERY terminal stamp matching the notification's status (Invariant 4.2, Invariant 4.4, Invariant 4.6).
Check 5.1: An auditor MUST find the notification set never shrinking across the notifications' committed versions (Invariant 9.1, Invariant 9.2; Execution Contract Generation acceptance 1).
Check 5.2: An auditor MUST find EVERY notification carrying notification id, recipient reference, payload, creation instant and status in each of the notification's committed versions (Invariant 9.3).
Check 6.2: An auditor MUST find no two notifications sharing a notification id (Invariant 6.1).
Check 6.3: An auditor MUST find EVERY notification carrying one notification id across the notification's committed versions (Invariant 5.1).
```

Term committed version: a record as it stood at the commit that wrote it, as Execution Contract Generation acceptance 1 declares it.

#### External checks

```
External check 1: An auditor MUST read the deployment's fail-versus-expire policy from the deployment's own declaration (Operation 14, Capability requirement 8).
External check 2: An auditor MUST read a payload's retention from the composing retention pattern's records (Non-goal 13).
External check 3: An auditor MUST read who created a notification from the composing attestation pattern's attestations (Non-goal 11).
External check 4: An auditor MUST read the transport's own outcome from the deployment's delivery layer (Non-goal 5).
```

NOTE: EVERY check names the rule the check tests. External check 1 is the one that makes cross-deployment audit possible: without the declared policy, one shop's failure instant and another's lapse instant record the same operational event and no reader can tell.

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; a recipient; an auditor; the database; a notification; a status.

Term records: notification — one delivery record, carrying notification id, recipient reference, payload, creation instant, status and, once it ends, one terminal stamp.

Term record verbs: identify, allocate, supply, reuse, carry, compare, trim, normalize, case-fold, read, stand, stamp, offer, delete, hold, record, answer, accept, leave, refuse, order, write, change, move, set, share, shrink, keep, own, evaluate, choose, retry, create, deliver, validate, deduplicate, purge, gate, expire, enumerate, call, compose, guard, declare, find, reconstruct, raise, require, precede.

Term value sets: status = pending | delivered | failed | expired. terminal stamp = delivery instant | failure instant | lapse instant. action rejection = not-known | not-pending | storage-failure. Create rejection = invalid-request.

Term bounds: string cap (the bound on the recipient reference's length, measured in Unicode code points, 256 where a deployment declares none).

Term cadences: empty — a delivery window is the composing pattern's (Operation 14b).

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: notification, notification id, recipient reference, payload, seam, transition, business caller, now, string cap, status, terminal stamp, creation instant, terminal transition, delivery outcome, pending at an instant, committed version, notification set, notification ids, high-assurance deployment, offer key.

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Create]: #create
[Deliver]: #deliver
[Fail]: #fail
[Expire]: #expire
[Status Of]: #status-of
[Pending For]: #pending-for
[Notification Record]: #notification-record
[Notification Id]: #notification-id
[Recipient Reference]: #recipient-reference
[Payload]: #payload
[Creation Instant]: #creation-instant
[Status]: #status
[Delivery Instant]: #delivery-instant
[Failure Instant]: #failure-instant
[Lapse Instant]: #lapse-instant
[Pending]: #pending
[Delivered]: #delivered
[Failed]: #failed
[Expired]: #expired
[Now]: #now
[Invalid Request]: #invalid-request
[Not Known]: #not-known
[Not Pending]: #not-pending
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
formal: verified — notification.als + 5 twins (the static data model: Invariant 2, 3 and 4, and the terminal transitions' fields and statuses, 2026-06-03); notification.tla + 30 twins (2026-11-11; across steps: Invariant 1.1, 1.2, 2.2, 2.3, 2.4 (at the read), 5.1, 6.1, 8.1 through 8.3, 9.1 through 9.3, State 7, 8, Operation 1, 3, 4, 5, 7 through 13, 15 through 20, 22, 23, String 6, 8, 9; and, by way of those checks, Identity 5 through 7 (Invariant 6.1 and Operation 1), State 10 (Invariant 9.1) and Operation 14 (Operation 11 and 12)); the expiry WITHIN the 2026-11-10 note owed is no rule of the page, Operation 14a and 14b giving the delivery window to a composing pattern; owed rows: Operation 33 (a malformed recipient reference answers an empty list; the call reads and adds no state), 2026-11-20; model redraw deferred to Lean: notification.tla, Invariant 2.4 (the model checks the read at the call's instant, which the rule no longer names; its check is the stronger one and still holds), 2026-11-27
last gate: 2026-11-27 — Final Critique 17, a delta round (diff base 9e5cfc06, 115 labels), one reader (Linus, on opencode/beam-free, then anthropic/claude-sonnet-5-5 once the free allowance ran out; GRID and EOS not run), frozen at 7bee90c7 — foundational count 2, cured, not clean, no sample: Invariant 2.4 no longer reads a read at an instant (the read's clock reading precedes its database read, Execution Contract Logic confinement 20, so a [Create] committed between the two could break it) and promises what the commit it answers from holds, no terminal stamp, with Check 2.1 citing Invariant 2.2 and Invariant 2.3 and Term pending at an instant left to the auditor's reconstruction; Capability requirement 8 keeps the failing and the expiring outcomes disjoint; the refining cure widened Deliver persistence 3 to a repeat after a lost reply

open: none
```

retired labels: 32, listed in [the history](notification.hist.md).

How the Ledger's words relate: `owed rows` in the formal line are model checks not yet run; `open` lists critique findings not yet cured, none here; `not clean` says the last round counted a foundational finding, each cured in that round's commit.

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./notification.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/notification.md`.

</details>

NOTE: End of Notification.

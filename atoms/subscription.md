---
title: Subscription
parent: Atomic Concepts
has_toc: true
toc: true
---

# Subscription

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Subscription records who wants to be told about what. It answers the question "who should be notified about this?" the moment an event happens, by keeping a lasting list of named interests that can be queried at any time.

When someone subscribes, the pattern records the link between that subscriber and an event scope (the topic or category of events they care about), gives it an identifier, and keeps the record until the subscription is explicitly cancelled.

Two queries do the real work: one asks whether a given subscriber is currently subscribed to a given scope, and the other returns everyone currently subscribed to a scope — the list a system needs when an event fires and has to reach the right people.

The pattern deliberately does no delivering: it does not know when events happen, what they contain, or how to reach anyone — that is a separate delivery pattern's job, which keeps the subscription list a clean, auditable administrative record on its own.

At most one active subscription can exist per subscriber-and-scope pair, which prevents the duplicate deliveries that double subscriptions would cause, and cancellation is immediate and permanent while the full history (including cancelled subscriptions) stays queryable for audit.

The most common uses are: notifying users of events relevant to them (task assignments, escalations, alerts), broadcasting policy or system changes to a declared audience, and building any system where actors must opt in to event categories with the ability to opt out. This atom is an atomic concept: a freestanding pattern whose specification names no other pattern.

---

## Intent

<details markdown="block">
<summary>WHY</summary>

A subscription is a standing answer to *who wants to hear about this?* — recorded once, read on every event, withdrawn once. Systems that skip the concept end up deriving the audience from whatever is nearby: a role table, a config file, a query over past activity. Each of those answers a different question, and each drifts. The atom holds the interest itself: one actor, one class of events, in force or withdrawn, with a history of both. It fires nothing, delivers nothing, and knows nothing about events — it answers *who should hear about this scope now*, and the composing pattern does the rest. The one structural rule is at most one active subscription per actor and scope (Invariant 6.1, Operation 6), because two produce two notifications for one event, which is almost never what anybody meant.

</details>

## Structure

### Identity model

```
Identity 1: The atom MUST identify a subscription by the subscription id.
Identity 2: The host MUST allocate a subscription id at the atom's seam.
Deleted: Identity 3. Execution Contract Logic confinement 3 owns it.
Identity 4: The atom MUST NOT reuse a subscription id.
Identity 5: The atom MUST NOT identify a subscription by the subscriber reference and the event scope.
Identity 6: The deployment MUST draw a subscription id from a cryptographically secure source.
Identity 7: The deployment MUST NOT draw a subscription id from the subscription's public properties.
```

Term subscription: one actor's standing interest in one class of events — the record this atom holds.

Term subscription id: the opaque value naming one subscription — a [Subscription Id]; unguessable, and the capability [Cancel] accepts.

Term subscriber reference: the opaque reference naming who holds the subscription — a [Subscriber Reference].

Term event scope: the opaque reference naming the class of events covered — an [Event Scope]; matched exactly.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading and the subscription id here.

Term transition: the atom's evaluation of one call against the subscription records, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

NOTE: open 2026-10-21-d — Term seam, Term transition and Term business caller cite the section titled Logic Confinement Principle in `execution-contract.md`, which declares none of them.

Term id entropy: 128 bits of cryptographically secure random material — the floor a subscription id is drawn from, sufficient for negligible collision probability and for unguessability.

### State

```
State 1: EVERY subscription MUST stand in EXACTLY ONE OF active, cancelled.
State 2: EVERY subscription MUST carry subscription id, subscriber reference, event scope, subscription instant and status.
State 3: A cancelled subscription MUST carry cancellation instant.
State 4: [Subscribe] MUST stamp subscription instant from the injected now.
State 5: [Cancel] MUST stamp cancellation instant from the injected now.
State 6: The atom MUST NOT offer a cancelled-to-active transition.
State 7: The atom MUST NOT delete a subscription.
State 8: The atom MUST NOT hold an event.
State 9: The atom MUST NOT hold a delivery.
```

Term status: active | cancelled — in force, or withdrawn and terminal.

Term subscription instant: the instant the subscription was recorded — a [Subscription Instant].

Term cancellation instant: the instant the subscription was withdrawn — a [Cancellation Instant].

Term active set: the subscriptions whose status EQUALS active — what [Subscribed] and [Subscribers For] rest on (Invariant 7.1, Invariant 7.2).

Term active at an instant: subscription instant at or before the instant, and cancellation instant either absent or after the instant — the reconstruction an auditor runs over stored fields, never over status, which carries the present rather than the past.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 5: The deployment MUST supply the subscription records PER Execution Contract Database 1 through 4 and Execution Contract Conformance 9.
Capability requirement 6: The subscription id's random material MUST NOT fall below the id entropy.
Deleted: Capability requirement 2. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 3. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Capability requirement 1 and Execution Contract Logic confinement 7 own it: the seam supplies now, and the reading's honesty is the deployment's.
```

### Operations

```
subscribe(subscriber_ref, event_scope)
  answers subscription_id
  refuses invalid-request | already-subscribed | storage-failure

cancel(subscription_id)
  answers ok
  refuses not-known | not-active | storage-failure

subscribed(subscriber_ref, event_scope)
  answers subscribed | not-subscribed

subscribers_for(event_scope)
  answers subscriber_refs
```

```
Operation 1: [Subscribe] MUST record EXACTLY ONE subscription per successful call.
Operation 2: [Subscribe] MUST stand the subscription in active.
Operation 3: [Subscribe] MUST answer subscription id.
Operation 4: IF subscriber reference EQUALS blank THEN [Subscribe] MUST answer invalid-request.
Operation 5: IF event scope EQUALS blank THEN [Subscribe] MUST answer invalid-request.
Operation 6: IF an active subscription EXISTS for the pair THEN [Subscribe] MUST answer already-subscribed.
Operation 7: The atom MUST NOT interpret subscriber reference beyond the presence check.
Operation 8: The atom MUST NOT interpret event scope beyond the presence check.
Operation 9: IF no subscription EXISTS for the subscription id THEN [Cancel] MUST answer not-known.
Operation 10: IF the subscription's status EQUALS cancelled THEN [Cancel] MUST answer not-active.
Operation 11: [Cancel] MUST stand the subscription in cancelled.
Operation 12: [Cancel] MUST accept the subscription id as the whole authorization.
Operation 13: IF the database refuses the write THEN [Subscribe] MUST answer storage-failure.
Operation 14: IF the database refuses the write THEN [Cancel] MUST answer storage-failure.
Deleted: Operation 15. Execution Contract Database 3 owns it.
Operation 16: [Subscribed] MUST answer EXACTLY ONE OF subscribed, not-subscribed.
Operation 17: [Subscribed] MUST answer subscribed ONLY IF an active subscription EXISTS for the pair.
Operation 18: [Subscribed] MUST NOT refuse a blank input.
Operation 19: [Subscribers For] MUST answer the subscriber reference of EVERY active subscription matching the event scope.
Operation 20: [Subscribers For] MUST NOT answer a cancelled subscription's subscriber reference.
Operation 21: [Subscribers For] MUST match an event scope exactly.
Operation 22: [Subscribers For] MUST answer an empty list for an event scope no active subscription matches.
Operation 23: [Subscribers For] MUST NOT order the answer.
Operation 24: [Subscribed] MUST NOT write.
Operation 25: [Subscribers For] MUST NOT write.
Deleted: Operation 26. Capability requirement 1 owns it.
Deleted: Operation 27. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 28. Execution Contract Logic confinement 3 owns it.
```

Term pair: one subscriber reference with one event scope — what at-most-one ranges over.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the database |
|---|---|---|---|
| [Subscribe] | refs present, no active subscription for the pair, database accepts | subscription id | one subscription lands in [Active] (Operation 1, Operation 2) |
| [Subscribe] | blank subscriber reference or event scope | [Invalid Request] | none (Operation 4, Operation 5) |
| [Subscribe] | the pair already has an active subscription | [Already Subscribed] | none (Operation 6) |
| [Cancel] | id names an active subscription | ok | [Active] → [Cancelled], cancellation instant stamped (Operation 11, State 5) |
| [Cancel] | id names a cancelled subscription | [Not Active] | none (Operation 10) |
| [Cancel] | id names nothing | [Not Known] | none (Operation 9) |
| either write | database refuses | [Storage Failure] | none (Operation 13, Operation 14) |
| [Subscribed] | an active subscription matches the pair | subscribed | none — the call reads (Operation 17, Operation 24) |
| [Subscribed] | nothing matches, blank arguments included | not-subscribed | none (Operation 18, Invariant 8.1) |
| [Subscribers For] | active subscriptions match the scope | their subscriber reference values, unordered | none (Operation 19, Operation 23) |
| [Subscribers For] | scope never subscribed, a blank scope included, or all cancelled | empty list | none — the cases read alike (Operation 5, Operation 22) |

### Invariants

- **Invariant 1 — Subscription immutability.**
  ```
  Invariant 1.1: A recorded subscription's subscription id, subscriber reference, event scope and subscription instant MUST NOT change.
  ```
- **Invariant 2 — Status monotonicity.**
  ```
  Deleted: Invariant 2.1. State 1 owns it.
  Invariant 2.2: A status MUST NOT move from cancelled to active.
  ```
- **Invariant 3 — Cancellation is terminal.**
  ```
  Invariant 3.1: [Cancel] MUST answer not-active for a cancelled subscription.
  Invariant 3.2: [Subscribers For] MUST NOT answer a cancelled subscription's subscriber reference.
  ```
- **Invariant 4 — New subscribe after cancel produces a new id.**
  ```
  Invariant 4.1: A subscription recorded for a pair whose earlier subscription's status EQUALS cancelled MUST carry a fresh subscription id.
  Invariant 4.2: The two subscriptions MUST stand in the database independently.
  ```
- **Invariant 5 — No id reuse.**
  ```
  Invariant 5.1: Two subscriptions MUST NOT share a subscription id.
  ```
- **Invariant 6 — At most one active subscription per pair.**
  ```
  Invariant 6.1: Two active subscriptions MUST NOT share a pair.
  ```
- **Invariant 7 — Evaluation self-containment.**
  ```
  Invariant 7.1: [Subscribed] MUST rest on the active set alone.
  Invariant 7.2: [Subscribers For] MUST rest on the active set alone.
  ```
- **Invariant 8 — Absence means not-subscribed.**
  ```
  Invariant 8.1: [Subscribed] MUST answer not-subscribed ONLY IF no active subscription matches the pair.
  Invariant 8.2: [Subscribers For] MUST NOT answer a subscriber reference whose subscription for the scope IS NOT IN the active set.
  ```
- **Invariant 9 — Timestamp ordering.**
  ```
  Invariant 9.1: IF cancellation instant DOES NOT EQUAL blank THEN cancellation instant MUST NOT PRECEDE subscription instant.
  ```

NOTE: open 2026-10-21-b — Operation 20 and Invariant 3.2, Operation 10 and Invariant 3.1, State 6 and Invariant 2.2, and Lost ledger 2 and Composition note 3a each state one proposition twice, Operation 21 restates Term event scope's matched exactly, and Lost ledger 3 beside Composition note 3b, and Non-goal 12 beside Composition note 4, each give one obligation two subjects.

## Examples

The same atom, three domains, identical mechanic.

### Shared Todo — assignment notification

In a Shared Todo deployment, actors subscribe to assignment events scoped to themselves. `subscribe(dev_d, task:assigned:dev_d) → sub_42`. When manager M assigns a task to dev_d, the composition calls `subscribers_for(task:assigned:dev_d)` — dev_d's [Subscriber Reference] appears in the result; the composition then creates a Notification record for dev_d. When dev_d opts out of assignment emails, `cancel(sub_42)` — subsequent [Subscribers For] queries for that scope return an empty list; dev_d receives no further assignment notifications.

### Support queue — escalation alerts

A supervisor subscribes to escalation events for their queue: `subscribe(supervisor_s, escalation:queue-9) → sub_e1`. When a ticket in queue 9 escalates, the composition calls `subscribers_for(escalation:queue-9)` — supervisor_s appears; a notification is created. When a second supervisor takes over queue 9, the first cancels: `cancel(sub_e1)`. Subsequent escalations notify only those with Active subscriptions for that scope.

### Compliance system — policy change broadcast

An administrator issues subscriptions for each compliance officer: `subscribe(officer_a, policy:updated) → sub_p1`, `subscribe(officer_b, policy:updated) → sub_p2`. Each officer holds their own Active subscription. When a policy is updated, `subscribers_for(policy:updated)` returns both officers; one notification is created per officer. An officer who leaves the team has their subscription cancelled; they no longer appear in subsequent fanout queries.

### Rejection path

A developer attempts to subscribe twice to the same scope: `subscribe(dev_d, task:assigned:dev_d) → sub_42`. Then `subscribe(dev_d, task:assigned:dev_d)` → already-subscribed. The second call does not create a second subscription. To refresh the subscription, the developer first calls `cancel(sub_42)`, then `subscribe(dev_d, task:assigned:dev_d) → sub_97`. The cancellation of sub_42 remains in the subscription records; sub_97 is the new active record.

### Regulated adversarial scenarios

Three scenarios the subscription records must survive in regulated contexts:

- **Regulator audit — who was subscribed to a scope at a given time.** A compliance auditor asks *"which actors were subscribed to `policy:updated` at the time the policy was updated on 2025-03-14T10:00Z?"* The auditor queries the subscription records for subscriptions where `event_scope = policy:updated` and (`status = active` or `cancelled_at > 2025-03-14T10:00Z`) and `subscribed_at ≤ 2025-03-14T10:00Z`. The subscription records answer provably, from stored fields — [Subscriber Reference], [Event Scope], [Subscription Instant], [Status], [Cancellation Instant]. Invariants 1 and 9 make the timeline reconstruction exact.
- **Disputed subscription — actor claims they were never subscribed.** Officer_a denies having subscribed to `escalation:queue-9`. The investigator queries the subscription records for subscriptions where `subscriber_ref = officer_a` and `event_scope = escalation:queue-9`. If a record exists with [Subscription Instant] and the actor's reference, Invariant 1 (subscription immutability) is the structural answer: the record was created at that time with that [Subscriber Reference]; it does not change. If no record exists, the database confirms the actor was never subscribed. The subscription records are the single source of truth; no external corroboration is required.
- **Breach investigation — exposure scope assessment.** A security incident requires identifying all actors who were subscribed to `data:export` at the time of the breach (2025-06-01T03:00Z). The investigator queries subscriptions where `event_scope = data:export` and `subscribed_at ≤ 2025-06-01T03:00Z` and (`status = active` or `cancelled_at > 2025-06-01T03:00Z`). The result set is the exposure scope — every actor who was subscribed to that scope at the instant of the breach. Invariant 6 (at-most-one-active) confirms no actor appears more than once in the Active set at any point in time.

---

## Generation acceptance

This atom's acceptance is provable: an external auditor clears it from the subscription records' stored fields. The audit surface is the database, not the action surface.

### Conformance checks

```
Check 1.1: An auditor MUST reconstruct a scope's subscriptions active at a past instant from subscription instant and cancellation instant (Invariant 1.1, Invariant 9.1).
Check 2.1: An auditor MUST find no two active subscriptions sharing a pair (Invariant 6.1).
Check 3.1: An auditor MUST find cancellation instant present on EVERY cancelled subscription (State 3).
Check 3.2: An auditor MUST find no cancelled subscription in a [Subscribers For] answer (Invariant 3.2).
Check 4.1: An auditor MUST find a fresh subscription id on EVERY re-subscription of a pair (Invariant 4.1, Invariant 5.1).
Deleted: Check 5.1. Execution Contract Conformance 9 owns it.
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
Deleted: External check 1. Execution Contract Conformance 9 owns it.
```

## Non-goals

```
Non-goal 1: The atom MUST NOT fire an event.
Non-goal 2: The atom MUST NOT match an event to a subscription.
Non-goal 3: The atom MUST NOT create a notification.
Non-goal 4: A deployment needing fanout MUST compose Notification Fanout.
Non-goal 5: The atom MUST NOT deliver a notification.
Non-goal 6: The atom MUST NOT expand a scope hierarchy.
Non-goal 7: The atom MUST NOT match a scope pattern.
Non-goal 8: The atom MUST NOT guarantee a delivery count.
Non-goal 9: The atom MUST NOT expire a subscription.
Non-goal 10: A deployment needing a time-bounded subscription MUST compose a temporal-subscription pattern.
Non-goal 11: The atom MUST NOT hold a subscriber's lifecycle.
Non-goal 12: A deployment deprovisioning an actor MUST cancel the actor's active subscriptions one by one.
Non-goal 13: The atom MUST NOT record who called [Subscribe].
Non-goal 14: A deployment needing attribution MUST compose Actor Identity.
Non-goal 15: The atom MUST NOT gate [Cancel] beyond the subscription id.
Non-goal 16: The atom MUST NOT offer a bulk cancel.
Non-goal 17: The atom MUST NOT record an event's firing history.
```

NOTE: the owners — the composing pattern (Non-goal 1 through 5, Non-goal 8, Non-goal 9, Non-goal 16; Non-goal 12, Composition note 4); the composing system (Non-goal 6, Non-goal 7, Composition note 5); a temporal-subscription pattern *(forthcoming)* (Non-goal 10); an actor registry *(forthcoming)* (Non-goal 11); [Actor Identity](./actor-identity.md) (Non-goal 13, Non-goal 14); [Permissions](./permissions.md) (Non-goal 15, Cancel capability 3); [Event Log](./event-log.md) (Non-goal 17); [Event Log](./event-log.md) and [Notification](./notification.md) (State 8, State 9).

Where the atom breaks down: when the audience cannot be named in advance — a rule evaluated per event rather than a standing interest; when one actor genuinely needs two active subscriptions to one scope through two channels, which is a channel concept the composing pattern carries; and when the composing pattern loses the ids it captured — the subscriptions stay active, every audit sees them, and nothing in this atom can cancel them, because the id is the whole authorization and the atom enumerates none (Lost ledger 1 through 4).

## Edge cases

### Atomicity of a cancel

```
Deleted: Cancel atomicity 1. Execution Contract Database 1 owns it.
Deleted: Cancel atomicity 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Cancel atomicity 3. Execution Contract Database 1 and Execution Contract Database 3 own it.
```

### Cancel as a capability

```
Cancel capability 1: A caller holding the subscription id MUST reach [Cancel].
Cancel capability 2: The atom MUST NOT enumerate subscription ids.
Cancel capability 3: A deployment needing richer authorization MUST compose Permissions.
```

### The lost ledger

```
Lost ledger 1: The atom MUST NOT recover a subscription id.
Lost ledger 2: A composing pattern MUST own the durability of the subscription ids the pattern recorded.
Lost ledger 3: A deployment losing a subscription id MUST read the subscription as permanently active.
Lost ledger 4: A deployment needing recovery from a lost subscription id MUST compose an administrative-recovery pattern.
```

### The pair race

```
Deleted: Pair race 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Pair race 2. Execution Contract Database 2 owns it.
Deleted: Pair race 3. Execution Contract Database 2 owns it: the pair check and the write are one transaction, and the atom names no rule left for a uniqueness constraint to discharge.
```

## Composition notes

```
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST call [Subscribers For] when an event fires.
Composition note 3: A composing pattern MUST record the subscription id at subscribe time.
Composition note 3a: A composing pattern MUST own the durability of the subscription ids the pattern recorded.
Composition note 3b: A composing pattern losing a subscription id MUST read the subscription as uncancellable.
Composition note 4: A composing pattern MUST own the subscriber's deprovisioning cascade.
Composition note 5: A composing pattern MUST own scope semantics beyond exact match.
```

NOTE: composing patterns — [Notification Fanout](../compositions/notification-fanout.md). Forthcoming: Temporal Subscription, Actor Registry.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; the deployment; a composing pattern (also: a pattern); a business caller; a caller; an actor; a subscriber; an auditor; the database; a subscription; a status.

Term records: subscription — one standing interest, carrying subscription id, subscriber reference, event scope, subscription instant, status and, once withdrawn, cancellation instant.

Term record verbs: recover, identify, allocate, reuse, draw, carry, stand, stamp, offer, delete, hold, record, answer, interpret, accept, refuse, match, order, write, read, supply, change, move, rest, share, fire, create, deliver, expand, guarantee, expire, cancel, compose, gate, enumerate, reach, own, call, find, reconstruct, declare, precede, fall.

Term value sets: status = active | cancelled.

Term bounds: id entropy (the floor a subscription id's random material is drawn from).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-12).

Term terms: now, subscription, subscription id, subscriber reference, event scope, seam, transition, id entropy, status, subscription instant, cancellation instant, active set, active at an instant, pair, business caller.

#### Subscribe

The behavior that records a named actor's interest — creating a new [Active] subscription for a ([Subscriber Reference], [Event Scope]) pair with a fresh [Subscription Id] and stamping [Subscription Instant]. Returns the [Subscription Id], or a rejection ([Invalid Request], [Already Subscribed], [Storage Failure]).

Kind: Operation

#### Cancel

The behavior that withdraws a subscription, moving it [Active] → [Cancelled] (terminal) and stamping [Cancellation Instant]. Knowledge of the [Subscription Id] is itself the capability. Returns ok, or a rejection ([Not Known], [Not Active], [Storage Failure]).

Kind: Operation

#### Subscribed

The read-only point query — returns subscribed if any [Active] subscription matches the ([Subscriber Reference], [Event Scope]) pair, else not-subscribed. Both are first-class outcomes; no rejection is defined (Invariant 8).

Kind: Operation

#### Subscribers For

The read-only fanout query — returns the [Subscriber Reference] values of all [Active] subscriptions for an [Event Scope] (unordered; empty if none). The list a composing pattern needs when an event fires.

Kind: Operation

#### Subscription Id

The opaque, immutable identity of a subscription — host-allocated at the I/O seam from ≥128-bit cryptographically-secure random material (see the id entropy declaration), produced by [Subscribe], never reused (Invariant 5). It is the subscription's identity, and — being unpredictable — the bearer capability that gates [Cancel].

Kind:       Field
Field of:   the subscription
Projection: subscription_id

#### Subscriber Reference

The opaque reference to the subscribing actor. Set on [Subscribe], immutable (Invariant 1); the actor registry is a separate concept. Equality is exact and the atom normalizes nothing; the at-most-one-active rule (Invariant 6) ranges over it, so canonicalization is the deployment's, at the seam (Execution Contract Logic confinement 13).

Kind:       Field
Field of:   the subscription
Projection: subscriber_ref

#### Event Scope

The opaque reference to the class of events the subscription covers. Set on [Subscribe], immutable; matched by exact value ([Subscribers For] and [Subscribed] compare on it) — scope hierarchy and wildcards belong to composing patterns. The atom normalizes nothing; the at-most-one-active rule (Invariant 6) ranges over it, so canonicalization is the deployment's, at the seam (Execution Contract Logic confinement 13).

Kind:       Field
Field of:   the subscription
Projection: event_scope

#### Subscription Instant

The wall-time the subscription was recorded, injected at the seam on [Subscribe], immutable (Invariant 1). Its lower-bound relation to [Cancellation Instant] holds (Invariant 9.1, Execution Contract Logic confinement 7).

Kind:       Field
Field of:   the subscription
Projection: subscribed_at

#### Status

The subscription's lifecycle state — active or cancelled (i.e., [Active] or [Cancelled]). Set to active on [Subscribe]; transitions once to cancelled on [Cancel] (State 1, Invariant 2).

Kind:       Field
Field of:   the subscription
Projection: status

#### Cancellation Instant

The wall-time the subscription was cancelled, injected at the seam on [Cancel]. Absent while [Active]; set once and immutable thereafter; ≥ [Subscription Instant] (Invariant 9.1, Execution Contract Logic confinement 7).

Kind:       Field
Field of:   the subscription
Projection: cancelled_at

#### Active

The in-force state of a subscription: the subscriber appears in [Subscribers For] results for its [Event Scope]. The entry state on [Subscribe]. At most one [Active] subscription per ([Subscriber Reference], [Event Scope]) pair (Invariant 6).

Kind:      Member
Member of: the subscription status
Role:      Outcome

#### Cancelled

The terminal, withdrawn state of a subscription (Invariant 3): the subscriber no longer appears in [Subscribers For] results. Reached once, via [Cancel]; the record stays queryable for audit.

Kind:      Member
Member of: the subscription status
Role:      Outcome

#### Invalid Request

The rejection [Subscribe] returns when [Subscriber Reference] or [Event Scope] is blank: absent, empty, or carrying only whitespace (Operation 4, Operation 5). (The read queries never return it — a bad query is a correct not-subscribed or empty answer.)

Kind:       Member
Member of:  the Subscribe rejection
Role:       Outcome
Projection: invalid-request

#### Already Subscribed

The rejection [Subscribe] returns when an [Active] subscription already exists for the ([Subscriber Reference], [Event Scope]) pair (Invariant 6) — the mechanism that prevents duplicate notifications.

Kind:       Member
Member of:  the Subscribe rejection
Role:       Outcome
Projection: already-subscribed

#### Storage Failure

The rejection [Subscribe] or [Cancel] returns when the database write fails.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

#### Not Known

The rejection [Cancel] returns when the [Subscription Id] references no subscription.

Kind:       Member
Member of:  the Cancel rejection
Role:       Outcome
Projection: not-known

#### Not Active

The rejection [Cancel] returns when the referenced subscription is already [Cancelled] — cancellation is terminal (Invariant 3).

Kind:       Member
Member of:  the Cancel rejection
Role:       Outcome
Projection: not-active

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Subscribe]: #subscribe
[Cancel]: #cancel
[Subscribed]: #subscribed
[Subscribers For]: #subscribers-for
[Subscription Id]: #subscription-id
[Subscriber Reference]: #subscriber-reference
[Event Scope]: #event-scope
[Subscription Instant]: #subscription-instant
[Status]: #status
[Cancellation Instant]: #cancellation-instant
[Active]: #active
[Cancelled]: #cancelled
[Invalid Request]: #invalid-request
[Already Subscribed]: #already-subscribed
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Not Active]: #not-active

---

## Standards references

- **Observer pattern** (GoF — the Gang of Four, the four authors of *Design Patterns*) — the canonical object-oriented formulation of the subscriber/publisher relationship. Subscription is the structured-natural-language realization of the Subscriber role: an actor with a named interest in a class of events.
- **Publish-subscribe** (Birman & Joseph, 1987; subsequently AMQP (Advanced Message Queuing Protocol — the open messaging-middleware standard), Apache Kafka, etc.) — topic-based subscription as the mechanism for decoupling event producers from consumers. Subscription records the consumer-side interest; the composing fanout pattern is the broker.
- **WebSub** (W3C — World Wide Web Consortium, the web's standards body — Recommendation) — web-native publish-subscribe over HTTP (HyperText Transfer Protocol — the request/response protocol of the web). The subscription resource in WebSub is the Web analog of this atom.
- **XMPP PubSub** (XEP-0060, an XMPP Extension Protocol — publish-subscribe over the Extensible Messaging and Presence Protocol) — structured publish-subscribe over XMPP. Subscription nodes are the protocol-level analog.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Event Scope] as an opaque reference whose semantics are defined by the composing system.
- **Eiffel's design-by-contract** — preconditions on [Subscribe] and [Cancel]; named rejection reasons.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — subscription.als + 1 twin, 2026-06-03
last gate: 2026-10-29 — Final Critique 6 — foundational count 1, not clean, no sample

open:
- 2026-10-21-b · refining · Operation 10, 20, 21; Invariant 2.2, 3.1, 3.2; State 6; Lost ledger 2, 3; Composition note 3a, 3b, 4; Non-goal 12 · propositions owned twice: Operation 20 and Invariant 3.2, word for word; Operation 10 and Invariant 3.1; State 6 and Invariant 2.2; Lost ledger 2 and Composition note 3a, word for word, the second a lettered label outside a WHEN; Operation 21 beside Term event scope's matched exactly; and one obligation given two subjects, Lost ledger 3 (a deployment, permanently active) beside Composition note 3b (a composing pattern, uncancellable), and Non-goal 12 (a deployment) beside Composition note 4 (a composing pattern) → one owner each (GRACE-lang Authority 3), each tombstone checked against the pages that cite it and against what subscription.als checks (Invariant 2, Invariant 3)
- 2026-10-21-d · refining · Term seam; Term transition; Term business caller · each cites the section titled Logic Confinement Principle in `execution-contract.md` as declaring it, and that section declares none of the three → cite the contract's labels that hold each, in the form every page carrying the one seam wording can take
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/subscription.md`; the migration that got it here is in [its history](./subscription.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the subscription store supplied under Execution Contract Store 1 through 4 (Capability requirement 5), and the seven rules that restated them tombstoned to their owner — Cancel atomicity 1, a cancel changing status and cancellation instant together, to Store 1; Cancel atomicity 2 and 3, no crash inside [Cancel] leaving a cancelled status without its cancellation instant or a cancellation instant on an active subscription, to Store 1 and Store 3; Pair race 1, the pair check and the write one transition, to Store 1 and Store 2; Pair race 2, no two active subscriptions for one pair under concurrent calls, and Pair race 3, a store's uniqueness constraint discharging Pair race 1, to Store 2; Operation 15, a refused write leaving the store as the call found the store, to Store 3; rules 99 to 93. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. At most one active subscription per pair stays the atom's own (Invariant 6.1, Operation 6), as do the atom deleting no subscription (State 7) and the recorded fields that never change (Invariant 1.1). The subscription ids a composing pattern recorded are that pattern's records, not this atom's, so their durability stays the composing pattern's to own (Lost ledger 2, Composition note 3a) and no Store rule the atom cites reaches them. A scope's audience at a past instant is read from the subscription and cancellation instants each subscription carries, and [Subscribers For] answers unordered, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — The wiring declaration is an external check.** *Chose:* Check 5.1 deleted to External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration. *Over:* a conformance check no subscription record can answer, under an acceptance an external auditor clears from the subscription records' stored fields. *Because:* Final Critique 5 found that a conforming deployment fails it, and the corpus held the cure: the external check to which seven atoms had moved the same check. Smaller fixes rode with it, none changing what a rule means: Invariant 9.1 compares the two instants with PRECEDES (GRACE-lang Earned vocabulary 18), and the term entries no longer call the order best-effort, since it rests on a clock whose readings never go backward, which the deployment owns (Execution Contract Logic confinement 7, to which Clock semantics 1 through 3 were deleted); Identity 3 is deleted to Execution Contract Logic confinement 3, which it restated. What each action does on a call it admits is unchanged.

- **2026-10-22 — The wiring is read outside the records, as the Execution Contract says.** *Chose:* External check 1, the auditor reading which composing patterns a deployment wired in from the deployment's own declaration, deleted to Execution Contract Conformance 9, with Check 5.1's tombstone, which named it, now naming the contract, the checks NOTE's sentence restating it removed, and the label cited on Capability requirement 5; rules 92 to 91. *Over:* the page stating for itself that the wiring is an external check. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the wiring declaration among them; this page's fifth Final Critique had made the cure one specification at a time. What each action does and answers is unchanged.

</details>

NOTE: End of Subscription.

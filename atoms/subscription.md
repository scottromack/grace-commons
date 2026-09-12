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

The most common uses are: notifying users of events relevant to them (task assignments, escalations, alerts), broadcasting policy or system changes to a declared audience, and building any system where actors must opt in to event categories with the ability to opt out. The atom is the first entry in the `messaging` category.

---

## Intent

WHY:
A subscription is a standing answer to *who wants to hear about this?* — recorded once, read on every event, withdrawn once. Systems that skip the concept end up deriving the audience from whatever is nearby: a role table, a config file, a query over past activity. Each of those answers a different question, and each drifts. The atom holds the interest itself: one actor, one class of events, in force or withdrawn, with a history of both. It fires nothing, delivers nothing, and knows nothing about events — it answers *who should hear about this scope now*, and the composing pattern does the rest. The one structural rule is at most one live subscription per actor and scope, because two produce two notifications for one event, which is almost never what anybody meant.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a subscription by the subscription_id.
Identity 2: The host MUST allocate a subscription_id at the atom's seam.
Identity 3: The transition MUST NOT allocate a subscription_id.
Identity 4: The atom MUST NOT reuse a subscription_id.
Identity 5: The atom MUST NOT identify a subscription by the subscriber_ref and the event_scope.
Identity 6: The deployment MUST draw a subscription_id from a cryptographically secure source.
Identity 7: The deployment MUST NOT draw a subscription_id from the subscription's public properties.
```

Terms › `subscription`: one actor's standing interest in one class of events — the record this atom holds.

Terms › `subscription_id`: the opaque value naming one subscription — a [Subscription Id]; unguessable, and the capability [Cancel] accepts.

Terms › `subscriber_ref`: the opaque reference naming who holds the subscription — a [Subscriber Ref].

Terms › `event_scope`: the opaque reference naming the class of events covered — an [Event Scope]; matched exactly.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading and the subscription_id here.

Terms › `transition`: the atom's evaluation of one call against the subscription store, as `execution-contract.md` §Logic confinement declares it.

Terms › `id entropy`: the random material a subscription_id is drawn from; 128 bits where a deployment declares none.

WHY:
The id is the capability: knowing it is what lets a caller cancel, so it is drawn from a secure source and is unguessable from the subscribe time or the subscriber (Identity 6, Identity 7, Cancel capability 1–3). Identity by the pair would make a cancel-and-resubscribe look like an edit of one record, when it is two records with two histories — which is exactly what an auditor reconstructing a scope's audience needs (Identity 5, Invariant 4.1).

### State

```text
State 1: EVERY subscription MUST stand in EXACTLY ONE OF active, cancelled.
State 2: EVERY subscription MUST carry subscription_id, subscriber_ref, event_scope, subscribed_at and status.
State 3: A cancelled subscription MUST carry cancelled_at.
State 4: [Subscribe] MUST stamp subscribed_at from the injected now.
State 5: [Cancel] MUST stamp cancelled_at from the injected now.
State 6: The atom MUST NOT offer a cancelled-to-active transition.
State 7: The atom MUST NOT delete a subscription.
State 8: The atom MUST NOT hold an event.
State 9: The atom MUST NOT hold a delivery.
```

Terms › `status`: `active` | `cancelled` — in force, or withdrawn and terminal.

Terms › `subscribed_at`: the instant the subscription was recorded — a [Subscribed At].

Terms › `cancelled_at`: the instant the subscription was withdrawn — a [Cancelled At].

WHY:
A cancelled subscription stays in the store because the record of who was listening when is the audit surface — the atom answers *who now* from the active set and leaves *who then* reconstructable from both timestamps (State 7, Check 1.1). Nothing about events lives here: what fired, how often, and whether it arrived belong to [Event Log](./event-log.md) and [Notification](./notification.md) (State 8, State 9).

### Operations

```
subscribe(subscriber_ref, event_scope) → subscription_id | rejected(invalid-request | already-subscribed | storage-failure)
cancel(subscription_id) → ok | rejected(not-known | not-active | storage-failure)
subscribed(subscriber_ref, event_scope) → subscribed | not-subscribed
subscribers_for(event_scope) → subscriber_refs
```

```text
Operation 1: [Subscribe] MUST record EXACTLY ONE subscription per successful call.
Operation 2: [Subscribe] MUST stand the subscription in active.
Operation 3: [Subscribe] MUST answer subscription_id.
Operation 4: IF subscriber_ref is blank THEN [Subscribe] MUST answer invalid-request.
Operation 5: IF event_scope is blank THEN [Subscribe] MUST answer invalid-request.
Operation 6: IF an active subscription EXISTS for the pair THEN [Subscribe] MUST answer already-subscribed.
Operation 7: The atom MUST NOT interpret subscriber_ref beyond the presence check.
Operation 8: The atom MUST NOT interpret event_scope beyond the presence check.
Operation 9: IF the subscription_id NOT EXISTS THEN [Cancel] MUST answer not-known.
Operation 10: IF the subscription stands in cancelled THEN [Cancel] MUST answer not-active.
Operation 11: [Cancel] MUST stand the subscription in cancelled.
Operation 12: [Cancel] MUST accept the subscription_id as the whole authorization.
Operation 13: IF the store refuses the write THEN [Subscribe] MUST answer storage-failure.
Operation 14: IF the store refuses the write THEN [Cancel] MUST answer storage-failure.
Operation 15: A refused write MUST leave the store as the call found the store.
Operation 16: [Subscribed] MUST answer EXACTLY ONE OF subscribed, not-subscribed.
Operation 17: [Subscribed] MUST answer subscribed ONLY IF an active subscription EXISTS for the pair.
Operation 18: [Subscribed] MUST NOT refuse a blank argument.
Operation 19: [Subscribers For] MUST answer the subscriber_ref of EVERY active subscription matching the event_scope.
Operation 20: [Subscribers For] MUST NOT answer a cancelled subscription's subscriber_ref.
Operation 21: [Subscribers For] MUST match an event_scope exactly.
Operation 22: [Subscribers For] MUST answer an empty list for an event_scope no active subscription matches.
Operation 23: [Subscribers For] MUST NOT order the answer.
Operation 24: [Subscribed] MUST NOT write.
Operation 25: [Subscribers For] MUST NOT write.
Operation 26: The host MUST read the clock at the atom's seam.
Operation 27: The transition MUST NOT read a clock.
Operation 28: The business caller MUST NOT supply now.
```

Terms › `pair`: one `subscriber_ref` with one `event_scope` — what at-most-one ranges over.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

The case space, and the rule that owns each case:

| Call | Case | Answer | Effect on the store |
|---|---|---|---|
| [Subscribe] | refs present, no live subscription for the pair, store accepts | `subscription_id` | one subscription lands in [Active] (Operation 1, Operation 2) |
| [Subscribe] | blank `subscriber_ref` or `event_scope` | [Invalid Request] | none (Operation 4, Operation 5) |
| [Subscribe] | the pair already has a live subscription | [Already Subscribed] | none (Operation 6) |
| [Cancel] | id names a live subscription | `ok` | [Active] → [Cancelled], `cancelled_at` stamped (Operation 11, State 5) |
| [Cancel] | id names a cancelled subscription | [Not Active] | none (Operation 10) |
| [Cancel] | id names nothing | [Not Known] | none (Operation 9) |
| either write | store refuses | [Storage Failure] | none (Operation 13–15) |
| [Subscribed] | a live subscription matches the pair | `subscribed` | none — the call reads (Operation 17, Operation 24) |
| [Subscribed] | nothing matches, blank arguments included | `not-subscribed` | none (Operation 18, Invariant 8.1) |
| [Subscribers For] | live subscriptions match the scope | their `subscriber_ref`s, unordered | none (Operation 19, Operation 23) |
| [Subscribers For] | scope never subscribed, or all cancelled | empty list | none — the two cases read alike (Operation 22) |

WHY:
The two queries refuse nothing, and that asymmetry with [Subscribe] is deliberate: a write with a blank argument would record a bad row, while a read with a blank argument has a correct answer — nothing matches (Operation 18, Operation 22). An empty answer does not say whether a scope was never subscribed to or was fully cancelled, because the atom answers *who now* and a reader wanting *who then* has both timestamps to filter on (Check 1.1). [Subscribers For] returns subscriber refs and not ids: a composing pattern that needs the id captured it at subscribe time, and at-most-one is what makes that binding well-defined (Invariant 6.1, Composition note 3).

### Invariants

- **Invariant 1 — Subscription immutability.**
  ```text
  Invariant 1.1: A recorded subscription's subscription_id, subscriber_ref, event_scope and subscribed_at MUST NOT change.
  ```
- **Invariant 2 — Status monotonicity.**
  ```text
  Invariant 2.1: A status MUST move from active to cancelled.
  Invariant 2.2: A status MUST NOT move from cancelled to active.
  ```
- **Invariant 3 — Cancellation is terminal.**
  ```text
  Invariant 3.1: [Cancel] MUST answer not-active for a cancelled subscription.
  Invariant 3.2: [Subscribers For] MUST NOT answer a cancelled subscription's subscriber_ref.
  ```
- **Invariant 4 — New subscribe after cancel produces a new id.**
  ```text
  Invariant 4.1: A subscription recorded for a pair whose earlier subscription stands in cancelled MUST carry a fresh subscription_id.
  Invariant 4.2: The two subscriptions MUST stand in the store independently.
  ```
- **Invariant 5 — No id reuse.**
  ```text
  Invariant 5.1: Two subscriptions MUST NOT share a subscription_id.
  ```
- **Invariant 6 — At most one active subscription per pair.**
  ```text
  Invariant 6.1: Two active subscriptions MUST NOT share a pair.
  ```
  WHY: two live subscriptions for one actor and one scope produce two notifications for one event — the duplicate this atom exists to foreclose, and the structural difference from [Permissions](./permissions.md), which admits many grants over one pair.
- **Invariant 7 — Evaluation self-containment.**
  ```text
  Invariant 7.1: [Subscribed] MUST rest on the active set alone.
  Invariant 7.2: [Subscribers For] MUST rest on the active set alone.
  ```
- **Invariant 8 — Absence means not-subscribed.**
  ```text
  Invariant 8.1: [Subscribed] MUST answer not-subscribed ONLY IF no active subscription matches the pair.
  Invariant 8.2: [Subscribers For] MUST NOT answer a subscriber_ref whose subscription for the scope NOT EXISTS in the active set.
  ```
- **Invariant 9 — Timestamp ordering.**
  ```text
  Invariant 9.1: IF cancelled_at EXISTS THEN subscribed_at MUST NOT EXCEED cancelled_at.
  ```
  WHY: best-effort under a clock that moves backward; the deployment owns clock discipline (Clock semantics 1–2).

## Examples

The same atom, three domains, identical mechanic.

### Shared Todo — assignment notification

In a Shared Todo deployment, actors subscribe to assignment events scoped to themselves. `subscribe(dev_d, task:assigned:dev_d) → sub_42`. When manager M assigns a task to dev_d, the composition calls `subscribers_for(task:assigned:dev_d)` — dev_d's [Subscriber Ref] appears in the result; the composition then creates a Notification record for dev_d. When dev_d opts out of assignment emails, `cancel(sub_42)` — subsequent [Subscribers For] queries for that scope return an empty list; dev_d receives no further assignment notifications.

### Support queue — escalation alerts

A supervisor subscribes to escalation events for their queue: `subscribe(supervisor_s, escalation:queue-9) → sub_e1`. When a ticket in queue 9 escalates, the composition calls `subscribers_for(escalation:queue-9)` — supervisor_s appears; a notification is created. When a second supervisor takes over queue 9, the first cancels: `cancel(sub_e1)`. Subsequent escalations notify only those with Active subscriptions for that scope.

### Compliance system — policy change broadcast

An administrator issues subscriptions for each compliance officer: `subscribe(officer_a, policy:updated) → sub_p1`, `subscribe(officer_b, policy:updated) → sub_p2`. Each officer holds their own Active subscription. When a policy is updated, `subscribers_for(policy:updated)` returns both officers; one notification is created per officer. An officer who leaves the team has their subscription cancelled; they no longer appear in subsequent fanout queries.

### Rejection path

A developer attempts to subscribe twice to the same scope: `subscribe(dev_d, task:assigned:dev_d) → sub_42`. Then `subscribe(dev_d, task:assigned:dev_d)` → `rejected(already-subscribed)`. The second call does not create a second subscription. To refresh the subscription, the developer first calls `cancel(sub_42)`, then `subscribe(dev_d, task:assigned:dev_d) → sub_97`. The cancellation of sub_42 remains in the subscription store; sub_97 is the new active record.

### Regulated adversarial scenarios

Three scenarios the subscription store must survive in regulated contexts:

- **Regulator audit — who was subscribed to a scope at a given time.** A compliance auditor asks *"which actors were subscribed to `policy:updated` at the time the policy was updated on 2025-03-14T10:00Z?"* The auditor queries the subscription store for subscriptions where `event_scope = policy:updated` and (`status = active` or `cancelled_at > 2025-03-14T10:00Z`) and `subscribed_at ≤ 2025-03-14T10:00Z`. The subscription store answers from stored fields alone — [Subscriber Ref], [Event Scope], [Subscribed At], [Status], [Cancelled At] — with no recourse to developer narration. Invariants 1 and 9 make the timeline reconstruction exact.
- **Disputed subscription — actor claims they were never subscribed.** Officer_a denies having subscribed to `escalation:queue-9`. The investigator queries the subscription store for subscriptions where `subscriber_ref = officer_a` and `event_scope = escalation:queue-9`. If a record exists with [Subscribed At] and the actor's reference, Invariant 1 (subscription immutability) is the structural answer: the record was created at that time with that [Subscriber Ref]; it does not change. If no record exists, the store confirms the actor was never subscribed. The subscription store is the single source of truth; no external corroboration is required.
- **Breach investigation — exposure scope assessment.** A security incident requires identifying all actors who were subscribed to `data:export` at the time of the breach (2025-06-01T03:00Z). The investigator queries subscriptions where `event_scope = data:export` and `subscribed_at ≤ 2025-06-01T03:00Z` and (`status = active` or `cancelled_at > 2025-06-01T03:00Z`). The result set is the exposure scope — every actor who would have received notifications fired against that scope during the breach window. Invariant 6 (at-most-one-active) confirms no actor appears more than once in the Active set at any point in time.

---

## Generation acceptance

This atom's acceptance is what an external auditor can clear from the subscription store's stored fields, with no recourse to source code, runbooks or developer narration. The audit surface is the store, not the action surface.

### Conformance checks

```text
Check 1.1: An auditor MUST reconstruct a scope's active subscriber set at a past instant from subscribed_at, status and cancelled_at (Invariant 1.1, Invariant 9.1).
Check 2.1: An auditor MUST find no two active subscriptions sharing a pair (Invariant 6.1).
Check 3.1: An auditor MUST find cancelled_at present on EVERY cancelled subscription (State 3).
Check 3.2: An auditor MUST find no cancelled subscription in a [Subscribers For] answer (Invariant 3.2).
Check 4.1: An auditor MUST find a fresh subscription_id on EVERY re-subscription of a pair (Invariant 4.1, Invariant 5.1).
Check 5.1: An auditor MUST identify which composing patterns a deployment wired in (Composition note 1).
```

NOTE: EVERY check names the rule the check tests.

## Non-goals

```text
Non-goal 1: The atom MUST NOT fire an event.
Non-goal 2: The atom MUST NOT match an event to a subscription.
Non-goal 3: The atom MUST NOT create a notification.
Non-goal 4: A deployment needing fanout MUST compose [Notification Fanout](../compositions/notification-fanout.md).
Non-goal 5: The atom MUST NOT deliver a notification.
Non-goal 6: The atom MUST NOT expand a scope hierarchy.
Non-goal 7: The atom MUST NOT match a scope pattern.
Non-goal 8: The atom MUST NOT guarantee a delivery count.
Non-goal 9: The atom MUST NOT expire a subscription.
Non-goal 10: A deployment needing a time-bounded subscription MUST compose a temporal-subscription pattern.
Non-goal 11: The atom MUST NOT hold a subscriber's lifecycle.
Non-goal 12: A deployment deprovisioning an actor MUST cancel the actor's active subscriptions one by one.
Non-goal 13: The atom MUST NOT record who called [Subscribe].
Non-goal 14: A deployment needing attribution MUST compose [Actor Identity](./actor-identity.md).
Non-goal 15: The atom MUST NOT gate [Cancel] beyond the subscription_id.
Non-goal 16: The atom MUST NOT offer a bulk cancel.
Non-goal 17: The atom MUST NOT record an event's firing history.
```

WHY:
The atom records interest and answers audiences; everything downstream of *who* is the composing pattern's — routing, fanout, transport, delivery guarantees (Non-goal 1–5, 8). Scope is matched exactly, so `task:assigned` does not cover `task:assigned:dev_d`: hierarchy and wildcards are a scope vocabulary the composing system owns, and building them in here would make every deployment inherit one system's naming (Non-goal 6, Non-goal 7). There is no expiry and no bulk cancel: both are loops over ids that a composing pattern runs, and each cancellation stays its own audited record rather than a sweep with no trail (Non-goal 9, Non-goal 12, Non-goal 16).

Where the atom breaks down: when the audience cannot be named in advance — a rule evaluated per event rather than a standing interest; when one actor genuinely needs two live subscriptions to one scope through two channels, which is a channel concept the composing pattern carries; and when the composing pattern loses the ids it captured — the subscriptions stay active, every audit sees them, and nothing in this atom can cancel them, because the id is the whole authorization and the atom enumerates none (Lost ledger 1–4).

## Edge cases

### Cancel as a capability

```text
Cancel capability 1: A caller holding the subscription_id MUST reach [Cancel].
Cancel capability 2: The atom MUST NOT enumerate subscription_ids.
Cancel capability 3: A deployment needing richer authorization MUST compose [Permissions](./permissions.md).
```

WHY:
Knowing the id is the whole authorization, which is honest only because the id is unguessable and the atom exposes no way to list ids (Identity 6, Identity 7, Cancel capability 2). Role gating, multi-party consent and audit-on-cancel wrap the bare capability rather than replacing it.

### Clock semantics

```text
Clock semantics 1: The deployment MUST own the clock's monotonicity.
Clock semantics 2: The deployment MUST own the clock's timezone handling.
Clock semantics 3: The deployment MUST supply an honest now.
```

### The pair race

```text
Pair race 1: The implementation MUST make the pair check and the write one transition.
Pair race 2: The implementation MUST NOT record two active subscriptions for one pair under concurrent calls.
Pair race 3: A store enforcing the pair's uniqueness MAY discharge Pair race 1.
```

WHY:
Operation 6 reads the active set and [Subscribe] then writes; two concurrent calls on one pair both read *absent* and both write, and Invariant 6.1 — the reason this atom exists — is violated by the very sequence it forbids. The guard is check-then-act and the fix is the implementation's: one transition, or a uniqueness constraint in the store that does the same work (Pair race 3).

### The lost ledger

```text
Lost ledger 1: The atom MUST NOT recover a subscription_id.
Lost ledger 2: A composing pattern MUST own the durability of the subscription_ids the pattern recorded.
Lost ledger 3: A deployment losing a subscription_id MUST read the subscription as permanently active.
Lost ledger 4: A deployment needing recovery from a lost subscription_id MUST compose an administrative-recovery pattern.
```

WHY:
The capability trade buys unguessability and pays for it here. The id is the whole authorization (Operation 12), the atom enumerates no ids (Cancel capability 2), and nothing gates [Cancel] beyond the id (Non-goal 15) — so a composing pattern that loses its ledger holds subscriptions that every audit can see and nobody can cancel. Non-goal 12's deprovisioning cascade presupposes that ledger too. Retention Window's principle — observe the failure, never forbid the remediation — inverts here unless the ledger is owned: the remediation is not refused, it is absent. An Administrative Recovery pattern *(forthcoming)*, composing [Actor Identity](./actor-identity.md) so a named administrator can cancel without the id, is the remedy this atom deliberately does not carry (CR-12).

### Atomicity of a cancel

```text
Cancel atomicity 1: The implementation MUST change status and cancelled_at together.
Cancel atomicity 2: A crash inside [Cancel] MUST NOT leave a cancelled status without cancelled_at.
Cancel atomicity 3: A crash inside [Cancel] MUST NOT leave cancelled_at on an active subscription.
```

WHY:
Half a cancel breaks Invariant 2.1 or Invariant 9.1 while every field looks individually plausible — the transactional boundary is the implementor's and is named here because the failure is invisible to a reader of either field alone.

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A composing pattern MUST call [Subscribers For] when an event fires.
Composition note 3: A composing pattern MUST record the subscription_id at subscribe time.
Composition note 3a: A composing pattern MUST own the durability of the subscription_ids the pattern recorded.
Composition note 3b: A composing pattern losing a subscription_id MUST read the subscription as uncancellable.
Composition note 4: A composing pattern MUST own the subscriber's deprovisioning cascade.
Composition note 5: A composing pattern MUST own scope semantics beyond exact match.
```

WHY:
[Notification Fanout](../compositions/notification-fanout.md) is the wiring this atom was extracted for: an event source fires, the composition reads the audience here and creates one [Notification](./notification.md) per subscriber. Traceability runs the other way from what a reader expects — the composing pattern captures the id when it subscribes, because at-most-one makes that binding unambiguous and the atom exposes no id-recovery query (Composition note 3, Invariant 6.1). Forthcoming: Temporal Subscription, Actor Registry.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; the transition; the implementation; the deployment; a composing pattern (also: a pattern); a business caller; a caller; an actor; a subscriber; an auditor; the store; a subscription; a status; a crash.

Terms › `records`: `subscription` — one standing interest, carrying `subscription_id`, `subscriber_ref`, `event_scope`, `subscribed_at`, `status` and, once withdrawn, `cancelled_at`.

Terms › `record verbs`: make, discharge, recover, identify, allocate, reuse, draw, carry, stand, stamp, offer, delete, hold, record, answer, interpret, accept, leave, refuse, match, order, write, read, supply, change, move, rest, share, fire, create, deliver, expand, guarantee, expire, cancel, compose, gate, enumerate, reach, own, call, find, reconstruct, identify, declare, exceed.

Terms › `value sets`: subscribe answers = subscription_id | rejected(invalid-request | already-subscribed | storage-failure). cancel answers = ok | rejected(not-known | not-active | storage-failure). subscribed answers = subscribed | not-subscribed. subscribers_for answers = a list of subscriber_ref, empty where nothing matches. `status` = active | cancelled.

Terms › `bounds`: `id entropy` (the random material a subscription_id is drawn from).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-12).

Terms › `terms`: `now`, `subscription`, `subscription_id`, `subscriber_ref`, `event_scope`, `seam`, `transition`, `id entropy`, `status`, `subscribed_at`, `cancelled_at`, `pair`, `business caller`.

#### Subscribe

The behavior that records a named actor's interest — creating a new [Active] subscription for a ([Subscriber Ref], [Event Scope]) pair with a fresh [Subscription Id] and stamping [Subscribed At]. Returns the [Subscription Id], or a rejection ([Invalid Request], [Already Subscribed], [Storage Failure]).

Kind: Operation

#### Cancel

The behavior that withdraws a subscription, moving it [Active] → [Cancelled] (terminal) and stamping [Cancelled At]. Knowledge of the [Subscription Id] is itself the capability. Returns `ok`, or a rejection ([Not Known], [Not Active], [Storage Failure]).

Kind: Operation

#### Subscribed

The read-only point query — returns `subscribed` if any [Active] subscription matches the ([Subscriber Ref], [Event Scope]) pair, else `not-subscribed`. Both are first-class outcomes; no rejection is defined (Invariant 8).

Kind: Operation

#### Subscribers For

The read-only fanout query — returns the [Subscriber Ref] values of all [Active] subscriptions for an [Event Scope] (unordered; empty if none). The list a composing pattern needs when an event fires.

Kind: Operation

#### Subscription Id

The opaque, immutable identity of a subscription — host-allocated at the I/O seam from ≥128-bit cryptographically-secure random material (see the `id entropy` declaration), produced by [Subscribe], never reused (Invariant 5). It is the subscription's identity, and — being unpredictable — the bearer capability that gates [Cancel].

Kind:     Field
Field of: the subscription
Projects: subscription_id

#### Subscriber Ref

The opaque reference to the subscribing actor. Set on [Subscribe], immutable (Invariant 1); the actor registry is a separate concept.

Kind:     Field
Field of: the subscription
Projects: subscriber_ref

#### Event Scope

The opaque reference to the class of events the subscription covers. Set on [Subscribe], immutable; matched by exact value ([Subscribers For] and [Subscribed] compare on it) — scope hierarchy and wildcards belong to composing patterns.

Kind:     Field
Field of: the subscription
Projects: event_scope

#### Subscribed At

The wall-time the subscription was recorded, injected at the seam on [Subscribe], immutable (Invariant 1). Its lower-bound relation to [Cancelled At] is best-effort (Invariant 9).

Kind:     Field
Field of: the subscription
Projects: subscribed_at

#### Status

The subscription's lifecycle state — `active` or `cancelled` (i.e., [Active] or [Cancelled]). Set to `active` on [Subscribe]; transitions once to `cancelled` on [Cancel] (Invariant 2).

Kind:     Field
Field of: the subscription
Projects: status

#### Cancelled At

The wall-time the subscription was cancelled, injected at the seam on [Cancel]. Absent while [Active]; set once and immutable thereafter; ≥ [Subscribed At] (best-effort, Invariant 9).

Kind:     Field
Field of: the subscription
Projects: cancelled_at

#### Active

The in-force state of a subscription: the subscriber appears in [Subscribers For] results for its [Event Scope]. The entry state on [Subscribe]. At most one [Active] subscription per ([Subscriber Ref], [Event Scope]) pair (Invariant 6).

Kind:      Member
Member of: the subscription status
Role:      Outcome

#### Cancelled

The terminal, withdrawn state of a subscription (Invariant 3): the subscriber no longer appears in [Subscribers For] results. Reached once, via [Cancel]; the record stays queryable for audit.

Kind:      Member
Member of: the subscription status
Role:      Outcome

#### Invalid Request

The rejection [Subscribe] returns when [Subscriber Ref] or [Event Scope] is null, undefined, or empty. (The read queries never return it — a bad query is a correct `not-subscribed` or empty answer.)

Kind:      Member
Member of: the Subscribe rejection
Role:      Outcome
Projects:  invalid-request

#### Already Subscribed

The rejection [Subscribe] returns when an [Active] subscription already exists for the ([Subscriber Ref], [Event Scope]) pair (Invariant 6) — the mechanism that prevents duplicate notifications.

Kind:      Member
Member of: the Subscribe rejection
Role:      Outcome
Projects:  already-subscribed

#### Storage Failure

The rejection [Subscribe] or [Cancel] returns when the store write fails; no partial record is written and state is unchanged.

Kind:      Member
Member of: the action rejection
Role:      Outcome
Projects:  storage-failure

#### Not Known

The rejection [Cancel] returns when the [Subscription Id] references no subscription.

Kind:      Member
Member of: the Cancel rejection
Role:      Outcome
Projects:  not-known

#### Not Active

The rejection [Cancel] returns when the referenced subscription is already [Cancelled] — cancellation is terminal (Invariant 3).

Kind:      Member
Member of: the Cancel rejection
Role:      Outcome
Projects:  not-active

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Subscribe]: #subscribe
[Cancel]: #cancel
[Subscribed]: #subscribed
[Subscribers For]: #subscribers-for
[Subscription Id]: #subscription-id
[Subscriber Ref]: #subscriber-ref
[Event Scope]: #event-scope
[Subscribed At]: #subscribed-at
[Status]: #status
[Cancelled At]: #cancelled-at
[Active]: #active
[Cancelled]: #cancelled
[Invalid Request]: #invalid-request
[Already Subscribed]: #already-subscribed
[Storage Failure]: #storage-failure
[Not Known]: #not-known
[Not Active]: #not-active

---

## Standards references

- **Observer pattern** (GoF) — the canonical object-oriented formulation of the subscriber/publisher relationship. Subscription is the structured-natural-language realization of the Subscriber role: an actor with a named interest in a class of events.
- **Publish-subscribe** (Birman & Joseph, 1987; subsequently AMQP, Apache Kafka, etc.) — topic-based subscription as the mechanism for decoupling event producers from consumers. Subscription records the consumer-side interest; the composing fanout pattern is the broker.
- **WebSub** (W3C Recommendation) — web-native publish-subscribe over HTTP. The subscription resource in WebSub is the direct Web analog of this atom.
- **XMPP PubSub** (XEP-0060) — structured publish-subscribe over XMPP. Subscription nodes are the protocol-level analog.
- **Daniel Jackson, *The Essence of Software*** — freestanding-atom posture; [Event Scope] as an opaque reference whose semantics are defined by the composing system.
- **Eiffel's design-by-contract** — preconditions on [Subscribe] and [Cancel]; named rejection reasons.

---


## Status

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — subscription.als + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```


## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/subscription.md`.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the nine invariant numbers unchanged, Generation acceptance as conformance checks ahead of Non-goals, Non-goals and Edge cases as two sections, the transition table kept beside the rules as the case space. *Over:* the prose spec. *Because:* the migration plan; this atom carries no cross-spec citations, so the rewrite is free of frozen-number risk.

NOTE: End of Subscription.

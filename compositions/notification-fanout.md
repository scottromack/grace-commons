---
title: Notification Fanout
parent: Conceptual Compositions
nav_order: 5
has_toc: true
toc: true
---

# Notification Fanout

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Notification Fanout connects an event to everyone who wants to hear about it. It combines two simpler patterns: one that records who is interested in which kind of event (Subscription) and one that creates a delivery record for one recipient and tracks whether it succeeded (Notification). Neither can do the job alone — the first knows who is interested but cannot deliver, the second can record a delivery but cannot decide who should get it.

When an event fires, the composition asks the subscription list who is currently subscribed to that event's topic and then creates one delivery record for each of them. The subscriber list is fixed at the moment the event fires — someone who cancels a split second later still gets a record for this one, someone who joins later does not — and a failure creating one person's record does not stop the others.

Combining the two patterns guarantees that every current subscriber gets exactly one record per event (or the failure is named in the result, never hidden) whenever the invocation runs to completion — a crash mid-fanout can leave created records with no returned result, the duplicate-risk case the idempotency edge case names — and that all records from one event carry the same content. The composition keeps no state of its own; audit, replay, and deduplication are added by further patterns layered alongside it.

The most common uses are compliance and policy-change broadcast systems where every subscribed officer must receive a delivery record that can be audited; product and project management platforms where task events notify all interested team members; and any distributed system where an action in one domain must propagate to a variable number of downstream consumers without the emitting component knowing who they are.

---

## Intent

Subscription and Notification are freestanding atoms (specs that can be specified without naming any other pattern): Subscription records who is interested in what; Notification records whether a piece of information reached a recipient. Neither knows about the other. What neither can do alone is answer the question that arises when an event fires: *for every subscriber currently Active on this scope, produce a delivery record.* That is the fanout operation — and it is a composition concept, not an atom concept.

The composition is structurally simple: one query (`Subscription.subscribers_for`) followed by N creates (`Notification.create`, one per returned subscriber). Its architectural significance is that it is the first place in the library where a single trigger produces a variable number of effects — N notification records, where N is the count of Active subscribers at trigger time. This is not a single transition with N side effects; it is a directed invocation graph (a representation of all the calls the composition makes and their dependencies — one query feeds N independent creates) with one query edge and N create edges. The fan-out is the composition; the atoms remain closed single-transition state machines.

The composition makes two architectural commitments explicit. First, the subscriber set is determined once at trigger time — a subscriber who cancels after the `subscribers_for` query executes still appears in that invocation's fanout; a subscriber who joins after it does not. Second, fan-out failures are per-recipient and non-aborting — a failure to record one recipient's notification does not cancel the creates for remaining recipients. Both commitments follow from the boundary rule for parallel composition: no rollback guarantee exists across independent create operations.

---

## Composes

```text
Composes 1: EXACTLY ONE Subscription instance MUST serve the composition.
Composes 2: EXACTLY ONE Notification instance MUST serve the composition.
Composes 3: The composition MUST NOT change a constituent's spec.
Composes 5: The composition MUST read the subscription store through Subscription's subscribers_for.
Composes 6: The composition MUST NOT write to the notification store beside Notification's create.
Composes 7: The composition MUST inherit a constituent's invariants PER `execution-contract.md` §Conformance.
NOTE: Composes 4 deleted — Invariant 5.1 owns it.
```

Terms › `composition`: this pattern's wiring of [Subscription](../atoms/subscription.md) and [Notification](../atoms/notification.md) — the one action below, its fan-out and its two result lists.

Terms › `constituents`: [Subscription](../atoms/subscription.md), [Notification](../atoms/notification.md).

WHY:
Composes 7 is one rule where the prose carried two. The prose named the two deleted invariants *preservation claims* and distinguished them from the six that emerge — which is the right distinction and the reason the migration could act on it cleanly. [`execution-contract.md`](../execution-contract.md) §Conformance settles both: conformance extends recursively and no composing layer is obligated to re-verify what a constituent's own conformance establishes, so asserting it twice more was a citing spec restating a rule it cites (Authority 6, council read 53, council read 55).

Composes 5 and Composes 6 are what the preservation claims carried *beyond* the blanket, and none of it is inherited: the read-only posture toward the subscription store and the refusal to reach past `create` are this composition's own restraint, not a guarantee either atom makes about a caller.

---

## Composition logic

### Composition state

```text
Composition state 1: The composition MUST NOT store a record.
Composition state 2: The composition MUST NOT persist a fanout id.
Composition state 3: A deployment needing a fanout recorded MUST compose [Event Log](../atoms/event-log.md).
Composition state 4: A deployment needing a fanout deduplicated MUST compose [Duplicate Prevention](../atoms/duplicate-prevention.md).
```

WHY:
The contract classification is *conforming, no stored composition state* (`execution-contract.md` §Composition state). The subscription store owns who subscribes and the notification store owns what was created; the composition is a stateless interpreter over both. Composition state 3 is the Contract's record-coordination rule applied by name — a composition that must record that its own sequences occurred composes [Event Log](../atoms/event-log.md) rather than growing a store of its own — and this composition routes the concept out rather than holding it.

### Capability requirement

```text
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The host MUST supply one fanout id at the seam.
Capability requirement 3: The host MUST draw a fanout id meeting the entropy floor.
NOTE: Capability requirement 4 deleted — `execution-contract.md` §Logic confinement owns it.
Capability requirement 5: The transition MUST NOT mint an id.
Capability requirement 6: A deployment MUST disclose the deployment's read latency bound.
Capability requirement 7: The deployment MUST declare the clock offset allowance.
```

Terms › `seam`: the composition's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects one clock reading and one fanout id here.
Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `transition`: the composition's evaluation of one [Fanout] call against the two stores, as `execution-contract.md` §Logic confinement declares it.

Terms › `entropy floor`: 128 bits of entropy per id, or a generator whose coordination gives the same uniqueness — an [Entropy Floor]; this composition's own bound on the host.

Terms › `read latency bound`: the deployment's disclosed bound on the interval between the composition dispatching subscribers_for and the subscription store executing it — a [Read Latency Bound].

WHY:
Capability requirement 3 is a floor neither constituent supplies. [Subscription](../atoms/subscription.md) declares the same floor for its own record ids and [Notification](../atoms/notification.md) declares none, so the requirement is this composition's dependency on its host and is attributed to neither atom — which is what makes it a `Capability requirement` rather than an inherited guarantee.

Capability requirement 6 and Capability requirement 7 are the two halves of the boundary window Check 1 needs. Neither is a record, both are operating facts a deployment states, and without them the window is not computable and the audit degrades to a caveat.

### Primitive policy

```text
Primitive policy 1: [Fanout] MUST answer invalid-request for a blank event_scope.
Primitive policy 2: [Fanout] MUST answer invalid-request for a payload that NOT EXISTS.
Primitive policy 3: The composition MUST take the fanout id ONLY AFTER the arguments clear the boundary predicate.
Primitive policy 4: [Fanout] MUST NOT call a constituent for an argument the boundary predicate refuses.
Primitive policy 5: The composition MUST compare an event_scope byte-exact.
Primitive policy 6: [Fanout] MUST NOT normalize an event_scope.
Primitive policy 7: [Fanout] MUST NOT bound a payload's length.
```

Terms › `blank`: a value that is absent, empty, or carries only whitespace — what the boundary predicate refuses; a blank argument NOT EXISTS.

WHY:
`invalid-request` here is the composition's own and nothing is inherited. The check is *consistent* with both constituents' postures — [Notification](../atoms/notification.md)'s `create` refuses a payload that does not exist, and [Subscription](../atoms/subscription.md)'s write surface refuses a blank `event_scope` — but this composition never calls `subscribe`, so no constituent contract governs the check and no constituent is consulted when it fires (Ledger 2026-08-27-k: the provenance is stated once, here).

Primitive policy 7 is a deliberate absence. A payload cap is the composing system's before [Fanout] is called; what the composition does carry is the consequence — an oversized payload is refused by every `create` and lands every subscriber in the failed list, which is the shape Indeterminate outcome 5 tells a caller to read.

### Action wiring

```
fanout(event_scope, payload) →
    {fanout_id, created, failed, fired_at}
  | rejected(invalid-request | subscribers-unavailable)
```

```text
Action wiring 1: An admitted fanout MUST call Subscription's subscribers_for with the event_scope.
Action wiring 2: An admitted fanout MUST take the fired_at from the seam's clock reading.
Action wiring 3: An admitted fanout MUST take the fanout_id from the seam's id.
Action wiring 4: IF the subscription store answers unavailable THEN [Fanout] MUST answer subscribers-unavailable.
Action wiring 5: A subscribers-unavailable answer MUST NOT carry a fanout_id.
Action wiring 6: A subscribers-unavailable answer MUST NOT follow a create.
Action wiring 7: An admitted fanout MUST call Notification's create EXACTLY ONE time per subscriber_ref the subscribers_for answer carries.
Action wiring 8: An admitted fanout MUST call Notification's create with the payload.
Action wiring 9: An admitted fanout MUST NOT call Notification's create for a subscriber_ref the subscribers_for answer does not carry.
Action wiring 10: IF Notification's create answers a notification_id THEN an admitted fanout MUST record the notification_id in the created list.
Action wiring 11: IF Notification's create answers otherwise THEN an admitted fanout MUST record the subscriber_ref in the failed list.
Action wiring 12: An admitted fanout MUST call Notification's create for EVERY remaining subscriber_ref the failed create did not name.
Action wiring 13: An admitted fanout MUST answer the fanout_id, the created list, the failed list AND the fired_at.
Action wiring 14: An admitted fanout MUST answer an empty created list AND an empty failed list for an empty subscribers_for answer.
Action wiring 15: An admitted fanout MUST NOT commit two creates under one transaction.
Action wiring 16: An admitted fanout MUST NOT order the created list.
Action wiring 17: An admitted fanout MUST NOT order the failed list.
Action wiring 18: An admitted fanout MUST NOT answer a create's reason.
```

Terms › `admitted fanout`: a [Fanout] call whose arguments cleared the boundary predicate.

Terms › `created list`: the notification_id of EVERY create the composition saw answer — a [Created] list.

Terms › `failed list`: the subscriber_ref of EVERY create the composition saw answer otherwise — a [Failed] list.

Terms › `unrecordable create`: a create answering no notification_id and no declared rejection — the outcome the composition names at the boundary, because [Notification](../atoms/notification.md) declares no infrastructure arm.

WHY:
Action wiring 11 and Action wiring 12 are the load-bearing decision stated as rules: the fan-out continues and names its failures rather than aborting. Action wiring 15 is what makes that honest — parallel composition carries no rollback guarantee, so each create commits independently and there is no transaction to abort into.

Action wiring 18 is the reason the failed list carries a `subscriber_ref` and not a reason. Two failures collapse into it — the structural `invalid-request` a constituent declared, and the unrecordable create the boundary named — and the composition cannot tell them apart without retrying and watching. A caller needing reason-level diagnostics composes [Event Log](../atoms/event-log.md) at the call site, which Composition state 3 already routes.

Action wiring 5 says the rejection carries no id because the invocation did not happen. An id on a rejection would give a caller a correlation handle for an invocation that produced nothing to correlate.

### Wiring decision

```text
Wiring decision 1: The composition MUST continue a fan-out through a failed create.
Wiring decision 2: The composition MUST NOT abort a fan-out for a failed create.
Wiring decision 3: The composition MUST account for EVERY subscriber the subscribers_for answer carries in EXACTLY ONE OF the created list, the failed list.
```

WHY:
The alternative is all-or-nothing, and it fails the case it exists for: a store briefly unavailable for one subscriber would deny delivery to every reachable subscriber, trading guaranteed delivery to the reachable majority for consistency with the unreachable minority. The failed list is the pressure valve — it makes the trade explicit rather than silent, and the caller applies the policy the event's stakes deserve, which is the mechanism-versus-policy split the composition rests on.

Wiring decision 3 is bounded by what a completed call can claim. A crash inside the fan-out produces no result and therefore no account of anybody — the coverage claim is over an invocation that answered, and Invariant 1 carries the same bound (Ledger 2026-08-27-g).

---

## Composition-level invariants

Invariants 1 through 5 and Invariant 8 emerge from the composition; neither constituent carries them alone.

- **Invariant 1 — Fanout coverage.**
  ```text
  Invariant 1.1: An admitted fanout answering a result MUST call Notification's create EXACTLY ONE time per subscriber_ref the subscribers_for answer carried.
  Invariant 1.2: EVERY subscriber_ref the subscribers_for answer carried MUST stand in EXACTLY ONE OF the created list, the failed list.
  Invariant 1.3: The composition MUST NOT call Notification's create for a subscriber_ref outside the subscribers_for answer.
  ```
  WHY: the claim is over an invocation that answered. A crash inside the fan-out produces no result and no account of anybody, which is the bound Wiring decision 3 carries and the Summary states.
- **Invariant 2 — Payload consistency.**
  ```text
  Invariant 2.1: EVERY notification record of one admitted fanout MUST carry one payload.
  ```
- **Invariant 3 — No cross-notification coupling.**
  ```text
  Invariant 3.1: A failed create MUST NOT change another subscriber_ref's notification record.
  Invariant 3.2: EVERY notification record of one admitted fanout MUST carry the record's own status.
  Invariant 3.3: A notification record MUST NOT reference another notification record.
  ```
- **Invariant 4 — At most one notification per subscriber per fanout.**
  ```text
  Invariant 4.1: An admitted fanout MUST NOT record two notification_ids for one subscriber_ref.
  Invariant 4.2: The composition MUST NOT claim a record the composition did not observe.
  ```
  WHY: Invariant 4.2 is the scope and it is deliberate. An indeterminate create may have committed a record whose id never came back, nothing in [Notification](../atoms/notification.md)'s declared surface lets anyone find it afterwards, and a retry can therefore produce a second record. That residual is the caller's (Indeterminate outcome 4) and is not a breach of an invariant that never claimed to see the unseen.
- **Invariant 5 — The subscription store is read-only.**
  ```text
  Invariant 5.1: The composition MUST NOT write to the subscription store.
  NOTE: Invariant 6 deleted — Composes 7 owns it.
  NOTE: Invariant 7 deleted — Composes 7 owns it.
  ```
  WHY: the two deleted invariants asserted that [Notification](../atoms/notification.md)'s and [Subscription](../atoms/subscription.md)'s own invariants hold over this composition's instances. The prose named them *preservation claims* and set them apart from the six that emerge, which is the right distinction and the reason they could be collapsed cleanly: `execution-contract.md` §Conformance already establishes recursive conformance, so restating it twice was a citing spec restating a rule it cites (Authority 6). What they carried beyond the blanket is Composes 5 and Composes 6.
- **Invariant 8 — Fanout invocation uniqueness.**
  ```text
  Invariant 8.1: Two admitted fanouts answering a result MUST NOT share a fanout_id.
  Invariant 8.2: The composition MUST call a constituent ONLY AFTER taking a fanout_id.
  Invariant 8.3: An admitted fanout answering a result MUST answer a fanout_id.
  ```
  WHY: the uniqueness rests on `Capability requirement 3`'s entropy floor, which is the composition's own dependency on its host because neither constituent supplies it — Subscription declares the same floor for its own ids and Notification declares none.

---

## Examples

### Walkthrough

A project management system uses Notification Fanout to notify subscribers when a task is assigned.

1. **Three team members subscribe.** `Subscription.subscribe(dev_a, "task:assigned") → sub_a1`. Same for dev_b and dev_c.
2. **A task is assigned; the fanout fires.** `fanout("task:assigned", {task_id: t7, assigned_by: manager_m})`:
   - `fanout_id = fanout_f01` generated.
   - `Subscription.subscribers_for("task:assigned") → [dev_a, dev_b, dev_c]`
   - `Notification.create(dev_a, payload) → notif_41`
   - `Notification.create(dev_b, payload) → notif_42`
   - `Notification.create(dev_c, payload) → notif_43`
   - Returns `{fanout_id: fanout_f01, created: [notif_41, notif_42, notif_43], failed: [], fired_at: 2026-03-14T10:02:11Z}`.
3. **dev_b cancels before the next event.** `Subscription.cancel(sub_b1) → ok`.
4. **A second task is assigned.** `fanout("task:assigned", {task_id: t8, assigned_by: manager_m})`:
   - `fanout_id = fanout_f02` generated.
   - `subscribers_for → [dev_a, dev_c]` — dev_b is now Cancelled; not returned.
   - Returns `{fanout_id: fanout_f02, created: [notif_51, notif_52], failed: [], fired_at: 2026-03-14T10:02:12Z}`.
5. **dev_b's earlier notifications are unaffected.** `Notification.status_of(notif_42)` returns the full record; the subscription cancellation does not delete prior notification records (Notification Invariant 9).

### Invalid input

A caller passes a null payload.

- `fanout("task:assigned", null)` → step 1: payload is null; validation fails immediately before any id is generated or any constituent is called.
- Returns `rejected(invalid-request)`. No [Fanout Id] is generated; no subscriber query is made; no notification records are created.

The same rejection fires for an empty `event_scope`: `fanout("", {task_id: t9})` → `rejected(invalid-request)`.

### Subscription store unavailable

The subscription store is down when the fanout fires.

- `fanout("task:assigned", {task_id: t9, assigned_by: manager_m})` → step 3: `Subscription.subscribers_for` fails with an infrastructure error.
- Returns `rejected(subscribers-unavailable)`. No notification records are created; the [Fanout Id] generated in step 2 is discarded and not returned — the invocation did not complete. The caller may retry when the store recovers.

### Partial failure

During a fanout, the notification store becomes temporarily unavailable after the first create succeeds.

- `fanout_id = fanout_f03` generated.
- `subscribers_for → [dev_a, dev_b, dev_c]`
- `Notification.create(dev_a, payload) → notif_61` ✓
- `Notification.create(dev_b, payload)` → the write fails against the unavailable store: no `notification_id`, no conforming constituent outcome — the boundary classifies it as dev_b's fanout failure (action wiring step 4) ✗
- `Notification.create(dev_c, payload) → notif_62` ✓ (fan-out continues)
- Returns `{fanout_id: fanout_f03, created: [notif_61, notif_62], failed: [dev_b], fired_at: 2026-03-14T10:02:13Z}`.

The caller inspects the [Failed] list and retries `Notification.create(dev_b, payload) → notif_63` per *Retry semantics*, knowing what that buys: dev_b's entry was indeterminate, so if the failed write had in fact committed a record before the store went away, dev_b now holds two records from one fanout and the delivery layer sees both — the at-least-once residual the composition names rather than hides. `notif_63` enters Pending independently; dev_a's and dev_c's records are already in their own delivery lifecycles.

### Compliance system — policy change broadcast

An administrator publishes a revised data-handling policy. Every compliance officer with an Active subscription to `policy:updated` events must receive a notification. `fanout("policy:updated", {policy_id: p12, effective_date: "2025-09-01"})` fires. Three officers are Active; three Notification records are created. Each officer's delivery outcome is tracked independently: officer_a delivered, officer_b failed (email bounce), officer_c expired (no delivery attempt within the window).

An auditor later asks: *was every subscribed compliance officer notified of policy p12?* The auditor queries the notification store for records where `payload.policy_id = p12`. Three records appear — one per officer — with their respective delivery outcomes. The Subscription store shows each officer held an Active subscription for the `policy:updated` scope. Invariant 1 gives the structural answer: the [Created] set accounts for all subscribers returned by the fanout query. For a precise binding to the exact fanout invocation — confirming no Active subscriber at that specific moment was omitted — a composed Event Log recording the fanout with `fired_at` provides the timestamp needed to apply Subscription's historical-state filter; without it, Active-status confirmation is over the general period rather than the exact fanout moment.

### Regulated adversarial scenarios

- **Regulator audit — demonstrate all subscribers were notified of a compliance event.** An auditor asks: *show all notification records created by the policy:updated fanout on 2025-08-15 and whether each was delivered.* The auditor queries the notification store for records where `created_at` falls on 2025-08-15 and the payload references the relevant policy. For each returned record, `status_of` shows the delivery outcome. Invariants 1 and 4 are the structural guarantees. Note on completeness: the Subscription store *does* support historical reconstruction of who was Active at any given moment — Subscription Subscription Invariant 9 (timestamp ordering) plus the immutable `subscribed_at` / `cancelled_at` fields make the filter `subscribed_at ≤ T` AND (`status = active` OR `cancelled_at > T`) exact to within Subscription Invariant 9's best-effort clock caveat. The actual completeness gap is different: the auditor needs to know the *exact fanout time* — the moment of the `subscribers_for` query — to apply the filter. The Subscription store doesn't record fanout invocations; that timestamp lives in Event Log, not Subscription. A composed Event Log recording the fanout invocation with its `fired_at` timestamp (see Generation acceptance check 1) is therefore required to bind the audit to a specific fanout invocation among potentially many for the same scope. Without it, the auditor can identify who was notified from the notification records, but cannot pin the audit to one specific fanout.
- **Disputed notification — subscriber claims they were never notified.** An officer claims no notification of policy p12 arrived. The investigator queries the notification store for records where `recipient_ref = officer_ref` and `payload.policy_id = p12`. If a record exists in any state, the store confirms the delivery attempt and its outcome. If the record shows `failed_at` or `expired_at`, the store confirms delivery did not succeed; the [Failed] list from the fanout result (logged via Event Log if composed) identifies this as a named failure, not a silent omission. If no record exists, either the officer had no Active subscription at fanout time (query the subscription store) or their create failed to record — the boundary-classified write failure, again a named failure in the [Failed] list, not a gap. The subscription and notification stores together answer the question.
- **Breach investigation — identify all notifications that may have carried sensitive payload data.** A security incident requires identifying every notification created by fanouts referencing policy p12. The investigator queries the notification store for records where `payload.policy_id = p12` and applies the historical-status reconstruction logic from Notification's regulated adversarial scenarios (`created_at ≤ breach_time` and status was Pending during the window). The notification store answers the exposure scope from stored fields alone.

---

## Generation acceptance

A derived implementation is acceptable when an external auditor, given the subscription store and the notification store, can clear the checks below without recourse to source code, runbooks or developer narration. **Check 1 and Check 2 are clearable only where [Event Log](../atoms/event-log.md) is composed in**, and the preamble says so rather than opening universally: the composition persists no fanout id, so nothing in the bare stores groups a fanout (Ledger 2026-08-27-h).

### Conformance checks

```text
Check 1.1: An auditor MUST read a fanout's event_scope and fired_at from the composed Event Log entry (Invariant 8.3).
Check 1.2: An auditor MUST reconstruct the active subscriber set at the fired_at from Subscription's historical-state filter (Invariant 1.2).
Check 1.3: An auditor MUST find EVERY reconstructed subscriber_ref in EXACTLY ONE OF the created list, the failed list (Invariant 1.2).
Check 1.4: An auditor MUST find the created list's count AND the failed list's count summing to the reconstructed set's count (Invariant 1.2).
Check 1.5: An auditor MUST read a count mismatch inside the boundary window as boundary-adjacent (Capability requirement 6, Capability requirement 7).
Check 1.6: An auditor MUST read a count mismatch outside the boundary window as an Invariant 1.2 violation.
Check 2.1: An auditor MUST find EVERY notification record of one fanout carrying one payload (Invariant 2.1).
Check 3.1: An auditor MUST find EVERY notification record of a fanout carrying the record's own status (Invariant 3.2).
Check 3.2: An auditor MUST find no notification record of a fanout referencing another notification record (Invariant 3.3).
Check 4.1: An auditor MUST find no two notification_ids of one fanout naming one subscriber_ref (Invariant 4.1).
Check 5.1: An auditor MUST find no subscription record written by the composition (Invariant 5.1).
```

NOTE: EVERY check names the rule the check tests.

Terms › `clock offset allowance`: `clock_offset_allowance` — the declared envelope within which the composition's fired_at may be compared with a stamp Subscription wrote at its own seam.

Terms › `boundary window`: the interval the read latency bound and the clock offset allowance together span around a fired_at — a [Boundary Window].

### External checks

```text
External check 1: An auditor needing create-time isolation confirmed MUST read the deployment's own transaction configuration (Invariant 3.1).
External check 2: An auditor needing a fanout grouped MUST read a composed [Event Log](../atoms/event-log.md) (Composition state 2).
External check 3: An auditor needing the boundary window computed MUST read the deployment's disclosed bounds (Capability requirement 6, Capability requirement 7).
External check 4: An auditor needing the composing patterns named MUST read the deployment's own declaration (Composition note 1).
External check 5: An auditor needing a notification record verified MUST read [Notification](../atoms/notification.md)'s own acceptance (Composes 7).
```

WHY:
The split is the record-versus-attempt line the epoch keeps finding. What *stands* clears from the stores — a record's payload, its status, its recipient, the absence of a subscription write. What was *attempted* does not: a create that did not record leaves nothing to inspect, so Invariant 3.1's create-time clause is answered from the deployment's transaction configuration or a fault-injection test and is an external check rather than a record-clearable one (Ledger 2026-08-27-i, which had [Notification](../atoms/notification.md)'s own acceptance classified both ways — it is classified once here, as External check 5, because it is the constituent's acceptance and not this composition's).

Check 1.5 and Check 1.6 are the boundary window doing real work. A subscribe or a cancel stamped inside the window can move the reconstructed count by one, and an auditor who read that as a violation would be filing against a correct implementation; an auditor who read every mismatch as boundary-adjacent would never file at all. The window is computable only from the two disclosed bounds, which is why they are capability requirements rather than advice.

---

## Non-goals

```text
Non-goal 1: The composition MUST NOT guarantee idempotency across two fanouts.
NOTE: Non-goal 2 deleted — Composition state 4 owns it.
Non-goal 3: The composition MUST NOT answer a result for a fanout that crashed.
Non-goal 4: The composition MUST NOT read the subscriber set twice in one fanout.
Non-goal 5: The composition MUST NOT skip a subscriber_ref the subscribers_for answer carried.
Non-goal 6: The composition MUST NOT serve a subscriber_ref the subscribers_for answer did not carry.
Non-goal 7: The composition MUST NOT expand an event_scope.
Non-goal 8: The composition MUST NOT match an event_scope by pattern.
Non-goal 9: The composition MUST NOT order a create.
Non-goal 10: The composition MUST NOT deliver a notification record.
Non-goal 11: The composition MUST NOT authorize a caller.
Non-goal 12: A deployment needing an authorized fanout MUST compose [Permissions](../atoms/permissions.md).
Non-goal 13: The composition MUST NOT validate a payload's schema.
Non-goal 14: The composition MUST NOT bound the fan-out's cost.
```

WHY:
Non-goal 5 and Non-goal 6 are one decision seen from two sides: the subscriber set is the active set at the instant the store executed the query, and the composition neither re-reads it nor filters it afterwards. A subscriber who cancels between the query and their create still receives a record, and one who subscribes after does not — both correct, both consequences of reading once.

Non-goal 3 is the crash bound. A fan-out that dies mid-flight answers nothing, so there is no result to carry an account and no entry for a composed Event Log to hold; the coverage claim is over invocations that answered and says nothing about the ones that did not.

Non-goal 10 is the boundary with the delivery layer. This composition creates records; a transport reads [Notification](../atoms/notification.md)'s `pending_for` and calls `deliver`, `fail` or `expire`. That the two are separate is why an indeterminate create cannot be reconciled from `pending_for` alone (Indeterminate outcome 8).

---

## Edge cases

### Clock semantics

```text
Clock semantics 1: The fired_at MUST stand as a lower bound on the instant the subscription store fixed the subscriber set.
Clock semantics 2: The composition MUST NOT claim the fired_at as the instant the subscription store fixed the subscriber set.
Clock semantics 3: The composition MUST NOT claim the fired_at equal to a notification record's created_at.
Clock semantics 4: The composition MUST answer the fired_at to the caller.
```

WHY:
The set is fixed when the subscription store executes the read, which the composition never observes — `subscribers_for` takes and returns no instant — and validation, dispatch and read latency stand between the seam reading and that execution. An earlier draft called `fired_at` *the instant the subscriber set is fixed*, which named a moment nothing on this page can see. Clock semantics 4 is why the field is returned at all: the caller cannot observe that instant either, so asking a caller to log its own invocation time would pin the wrong one and silently widen the very window Check 1 bounds.

### Indeterminate outcome

```text
Indeterminate outcome 1: An unrecordable create MUST stand as indeterminate.
Indeterminate outcome 2: The composition MUST NOT read an unrecordable create as no record.
Indeterminate outcome 3: A caller retrying a failed subscriber_ref MUST call Notification's create for the subscriber_ref.
Indeterminate outcome 4: A caller retrying an indeterminate subscriber_ref MUST accept a second notification record.
Indeterminate outcome 5: A caller MUST read every subscriber_ref failing alike as the payload's fault.
Indeterminate outcome 6: A caller MUST read one subscriber_ref failing alone as the subscriber_ref's fault.
Indeterminate outcome 7: A caller needing at-most-once across an indeterminate create MUST compose [Idempotent Reservation](./idempotent-reservation.md).
Indeterminate outcome 8: A caller MUST NOT read Notification's pending_for as finding an indeterminate create's record.
```

WHY:
A create that times out or comes back unacknowledged may have committed a record whose id never returned, and **no reconciliation from the bare atoms can find it.** `pending_for` answers only records still pending, so one the delivery layer already moved is invisible to it (Indeterminate outcome 8); a payload is not a fanout identity, since [Notification](../atoms/notification.md) permits any number of records over one `(recipient_ref, payload)` pair and concurrent fanouts legitimately share a payload; and `create` declares no idempotency key by which a retry could name the record it means. A guard composed around the *retry* alone sees nothing of the original create and admits the retry.

So a retry of an indeterminate entry is at-least-once and a second record is a residual the caller accepts, which is why Invariant 4 is scoped to the records the composition observed. Indeterminate outcome 7 names the cure rather than promising it: closing this needs an idempotency key at a store that can honor one, which is outside this composition's surface.

Indeterminate outcome 5 and Indeterminate outcome 6 are the discriminator the composition can offer without a reason field. Every subscriber failing identically is the payload outside [Notification](../atoms/notification.md)'s acceptance; one subscriber failing alone is that `subscriber_ref` outside it — [Subscription](../atoms/subscription.md) admits a whitespace-only ref and imposes no length cap where Notification refuses both, and that enumerable divergence is where a single structural failure comes from (Ledger 2026-08-27-l).

---

## Composition notes

```text
Composition note 1: A deployment MUST declare which composing patterns the deployment wired in.
Composition note 2: A deployment MUST own the caller's authority to fan out.
Composition note 3: A deployment MUST own a payload's schema and size.
Composition note 4: A deployment MUST own the disposition of a failed list.
Composition note 5: A deployment MUST own the fan-out's throughput strategy.
```

WHY:
Composition note 4 is the mechanism-versus-policy split written as an obligation. The composition cannot know whether a missed delivery matters — an activity feed accepts the loss and a regulated broadcast escalates — so it names the gap and hands the decision to the layer that knows the event's stakes.

---

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its term entry here. A term entry states what the concept *is*, in plain English, plus its **Kind** — one of five: **Type** (a thing or category), **Operation** (a behavior), **Member** (a value of an enumerated Type), or, for a named datum, **Field** (a datum a Type carries — *what does it carry?*) or **Parameter** (a value an Operation needs — *what does it need?*). A term entry also names the Type it is a **Member of** / **Field of**, the Operation it is a **Parameter of**, and its **Role** where the domain assigns one. A term entry carries one **Projects** line — the concept's single canonical lowering token, the one place the concrete name stays visible on the page — for every Field, Parameter, and pinned/wire Member. Everything else about casing (each target's snake / camel / pascal / const / wire form) is **derived** from that one token by [`tools/harness/term-adapter.mjs`](../tools/harness/term-adapter.mjs), never hand-written. This is a composition, so its own concepts are the single emergent action it exposes ([Fanout]) and the parts of the result that action returns — the [Fanout Id] correlation handle it takes from the seam, the [Fired At] instant at which it fixed the subscriber set, plus the [Created] and [Failed] lists that partition that set — and its own [Subscribers Unavailable] rejection. The composition keeps **no state of its own** (Composition state: none), so there is no record store to carry a term entry. References to the constituent atoms and their operations — Subscription's `subscribers_for`, Notification's `create` / `status_of` — the relayed constituent tokens (`event_scope`, `subscriber_ref`, `notification_id`, `payload`), and the composition's own boundary rejection (`invalid-request`, Primitive policy 1–2, inherited from neither constituent) remain qualified/backticked, not carded here (the write-side infrastructure failure carries no constituent token — it is the boundary-owned classification of action wiring step 4, absorbed into [Failed]). *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.40 (2026-09-14).

Terms › `terms`: `composition`, `constituents`, `seam`, `transition`, `read latency bound`, `blank`, `admitted fanout`, `created list`, `failed list`, `unrecordable create`, `clock offset allowance`, `boundary window`.

Terms › `record verbs`: call, answer, take, read, write, record, validate, compare, normalize, bound, stand, carry, claim, find, name, own, discharge, inherit, change, serve, compose, declare, disclose, supply, draw, mint, commit, order, continue, abort, account, skip, expand, match, deliver, authorize, reconstruct, sum, persist, guarantee, accept, retry, follow, reference, share, store, meet.

Terms › `actors`: the composition; the constituents; the host; the transition; a deployment; an auditor; a caller; a subscriber; a notification record; a subscription record.

Terms › `value sets`: fanout answers = {fanout_id, created, failed, fired_at} | rejected(invalid-request | subscribers-unavailable).

Terms › `cited`: `execution-contract.md` §Conformance — recursive conformance and the inherited guarantee. `execution-contract.md` §Composition state — the no-stored-state classification and the record-coordination rule. `execution-contract.md` §Logic confinement — the seam and the transition.

#### Fanout

The composition's single emergent action: given an `event_scope` and a `payload`, it queries `Subscription.subscribers_for` once and calls `Notification.create` once per returned subscriber, continuing through per-recipient failures rather than aborting. Returns the [Fanout Id] with the [Created] and [Failed] lists, or rejects [Subscribers Unavailable] (the store read failed) or `invalid-request` (bad input). Neither constituent atom carries this fan-out action.

Kind: Operation

#### Fanout Id

The opaque, invocation-unique correlation handle the composition generates for each fanout (Invariant 8). Present in every non-rejected result, including the empty-subscriber case; ephemeral unless Event Log is composed in, in which case it becomes the durable invocation identity. Not returned on rejection.

Kind:      Field
Field of:  the fanout result
Role:      the invocation correlation handle
Projects:  fanout_id

#### Created

The result list of `notification_id`s for the subscribers whose `Notification.create` succeeded in this fanout.

Kind:      Field
Field of:  the fanout result
Role:      the succeeded recipients
Projects:  created

#### Fired At

The seam-injected clock reading the host supplied when the invocation began — a lower bound on the instant `subscribers_for` fixed the subscriber set, which the composition never observes. Returned so the caller's Event Log entry can pin the instant the composition held; the caller never reproduces it. It is the composition's one clock use (*Logic confinement*) and is a different seam's reading from each record's `created_at`.

Kind:      Field
Field of:  the fanout result
Role:      the lower bound on the instant the subscriber set was fixed
Projects:  fired_at

#### Failed

The result list of `subscriber_ref`s for whom no delivery record was observed — the constituent's declared `invalid-request` (no record exists) and the boundary-classified indeterminate outcome (a record may exist with an id the composition never saw) collapsed into one "delivery not observed" outcome, which is why a retry reconciles first. Together with [Created] it accounts for every subscriber in the query result (Invariant 1: `|created| + |failed| = |subscribers|`); it is the pressure valve that makes the reachable/unreachable split explicit rather than silent.

Kind:      Field
Field of:  the fanout result
Role:      the unreached recipients (retry-eligible)
Projects:  failed

#### Subscribers Unavailable

The composition's own rejection from [Fanout] — returned when the subscription-store read (`Subscription.subscribers_for`) fails with an infrastructure error. No notification records are created and no [Fanout Id] is returned; the invocation did not complete.

Kind:      Member
Member of: the fanout rejection
Role:      Rejection
Projects:  subscribers-unavailable

#### Entropy Floor

The uniqueness bound this composition places on its host's id source: 128 bits of entropy per id, or a generator whose coordination gives the same uniqueness. [Subscription](../atoms/subscription.md) declares the same floor for its own record ids and [Notification](../atoms/notification.md) declares none, so the bound is attributed to neither constituent and stated here as a Capability requirement (Capability requirement 3, Invariant 8.1).

Kind:      Parameter
Parameter of: the host
Projects:  entropy_floor

#### Read Latency Bound

The deployment's disclosed bound on the interval between the composition dispatching `subscribers_for` and the subscription store executing it. An operating fact rather than a record, and one half of the [Boundary Window] an auditor needs to read a coverage mismatch correctly (Capability requirement 6, Check 1.5).

Kind:      Parameter
Parameter of: the deployment
Projects:  read_latency_bound

#### Boundary Window

The interval the [Read Latency Bound] and the clock offset allowance together span around a [Fired At]. A subscribe or a cancel stamped inside it can move a reconstructed subscriber count by one, so a coverage mismatch inside the window is boundary-adjacent and one outside it is a violation (Check 1.5, Check 1.6).

Kind: Type
Projects: boundary_window

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Fanout]: #fanout
[Fanout Id]: #fanout-id
[Created]: #created
[Failed]: #failed
[Fired At]: #fired-at
[Subscribers Unavailable]: #subscribers-unavailable
[Entropy Floor]: #entropy-floor
[Read Latency Bound]: #read-latency-bound
[Boundary Window]: #boundary-window

---

## Standards references

- **Observer pattern** (GoF — the "Gang of Four", the four authors of *Design Patterns*, 1994) — Notification Fanout is the Subject's `notify()` method: iterate the observer list, deliver the update to each. The atoms formalize what the pattern assumes.
- **Publish-subscribe** (Birman & Joseph, 1987; AMQP (Advanced Message Queuing Protocol — the open messaging-middleware standard) topic exchanges; Apache Kafka consumer groups) — the event-scope-to-subscriber binding is a topic subscription; [Fanout] is message dispatch.
- **WebSub (W3C Recommendation)** — hub-based publish-subscribe; [Fanout] corresponds to the hub's distribution step after a publisher notifies the hub of a content update.
- **W3C Activity Streams 2.0** — notification payloads in web deployments often carry Activity Streams objects; the fanout composition is payload-agnostic.
- **Outbox pattern** (Chris Richardson, *Microservices Patterns*) — for reliable fanout, the notification records produced by [Fanout] are the outbox entries the delivery layer consumes. The composition produces the records; the delivery layer is out of scope.

It inherits from:

- **[Subscription](../atoms/subscription.md)** — standards inheritance in full: Observer pattern, pub-sub, WebSub.
- **[Notification](../atoms/notification.md)** — standards inheritance in full: Observer pattern, SMTP (Simple Mail Transfer Protocol — the standard email-delivery protocol), HTTP webhooks, W3C Activity Streams, APNs/FCM (Apple Push Notification service / Firebase Cloud Messaging — the iOS and Android push-delivery services).

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: not applicable — vote no 2026-06-03: single-invocation structural coverage properties, no ordering or concurrency claim
last gate: 2026-08-28 — second gate after closure, fresh reader — 4 foundational (all since closed), 13 refining, 4 rhetorical

open:
- 2026-08-27-j · refining · Generation acceptance check 1, Event Log entry shape · embeds the full `created` and `failed` lists, unbounded in N, against Event Log's payload cap → bound, chunk, or digest
- 2026-08-27-m · refining · Action wiring; Edge cases, [Failed] bullet · retry disposition is deferred without naming *Retry semantics*; the cross-reference runs one way → add the reference
- 2026-08-27-o · refining · Generation acceptance, externally-clearable check · names Tamper Evidence, which appears nowhere else in the spec → enumerate only what the reader can find, or introduce it
- 2026-08-27-p · rhetorical · Standards references · W3C unglossed twice while the other initialisms are spelled out → gloss
- 2026-08-27-q · rhetorical · The load-bearing wiring decision, *Likely objection*; Edge cases, [Failed] disposition · the all-or-nothing argument restated nearly verbatim, "pressure valve" included → say it once
- 2026-08-27-r · rhetorical · Retry semantics; Edge cases, retry targeting · the two-option retry guidance given twice → say it once
- 2026-08-27-s · rhetorical · Summary · forward-references "the duplicate-risk case the idempotency edge case names" → make the Summary self-standing
- 2026-08-26-a · refining · Standards references · "standards inheritance in full" omits Subscription's XMPP PubSub (XEP-0060) → add it
- 2026-08-26-b · refining · Summary · "idempotency" unglossed at Tier 1 → gloss
- 2026-08-26-d · refining · Generation acceptance, externally-clearable list · omits Permissions and Audit Trail, both named in Edge cases → add them
- 2026-08-26-e · rhetorical · Summary · "fixed at the moment the event fires" against the normative query-execution instant → align with the wiring
- 2026-08-26-f · rhetorical · Examples, compliance walkthrough · glosses `expired` as "no delivery attempt", narrowing the constituent's window-lapse semantics → widen the gloss
- 2026-08-28-a · refining · step 1; Invalid-input example; Subscription-unavailable example; Logic confinement · three accounts of when the id exists ("no id is generated" / injected before the orchestration / "generated in step 2") → pin: id and `now` injected pre-validation, discarded on any rejection
- 2026-08-28-b · refining · step 4 discriminator · "every subscriber failing identically is the payload; one is the ref" is unobservable by the caller (no reason surfaced), degenerate at N=1, and indistinguishable from a store down for every create → state it as a caller heuristic with those caveats, or surface a per-entry reason
- 2026-08-28-c · refining · step 4 "the call times out" · no owner or bound for the timeout; a hung `create` hangs the fanout → require the deployment to bound each `create` and disclose the bound
- 2026-08-28-d · refining · Invariant 1 "exactly one `create` is attempted" · does not foreclose transport-level automatic retries inside the call → state that "attempted once" includes the transport layer
- 2026-08-28-e · refining · Edge cases, fanout idempotency · `fanout(event_scope, payload)` carries no event identity, so the Duplicate Prevention key must come from outside the signature → state that the key is a caller-supplied event identity
- 2026-08-28-f · refining · Retry semantics option 2 · re-invoking [Fanout] re-creates for every current subscriber including the [Created] set; the text reads as gap-filling → say it duplicates
- 2026-08-28-g · refining · Regulated scenarios, disputed notification · omits crash-mid-fanout and the structural `invalid-request` arm as causes → enumerate all three; note the crash case is a gap unless Duplicate Prevention/Event Log are composed
- 2026-08-28-i · refining · Composition logic · the fanout→records relation has no declared cardinality/modality or state classification → declare one-to-many, subscriber side mandatory, record side optional under partial failure; classify
- 2026-08-28-j · refining · Standards references; Logic confinement; Summary · `W3C`, `HTTP`, `I/O` unglossed; "idempotency" without an inline gloss in the Summary → gloss at first use
- 2026-08-28-k · refining · step 3; Regulated audit; Fired At term entry · cite "Generation acceptance check 1" but the checks are unnumbered bullets → number the checks
- 2026-08-28-l · refining · Externally-clearable check 2 · lists Event Log, Duplicate Prevention, Actor Identity, Tamper Evidence; the spec also names Audit Trail and Permissions as composing patterns → include them or explain
- 2026-08-28-m · refining · result shape · [Created] holds ids and [Failed] holds refs, so pairing a `notification_id` with its subscriber costs N `status_of` calls check 1(c) silently requires → return `{subscriber_ref, notification_id}` pairs or state the cost
- 2026-08-28-n · rhetorical · Fanout Id term entry · "the correlation handle the composition generates" contradicts "mints no id" → "takes from the seam"
- 2026-08-28-o · rhetorical · Examples, compliance system · "the [Created] set accounts for all subscribers" — Invariant 1 is [Created] ∪ [Failed] → say so
- 2026-08-28-p · rhetorical · Logic confinement · `clock_t`, `id_t` unglossed on this page → gloss or cite
- 2026-08-28-q · rhetorical · Examples · the [Failed] result list and Notification's Failed state collide one paragraph apart → qualify on first use
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/notification-fanout.md`.

- **2026-08-28 — A retry of an indeterminate create is at-least-once, and the page says so.** *Chose:* withdraw the `pending_for` reconciliation and the retry-side Duplicate Prevention claim; scope Invariant 4 to observed records; name Idempotent Reservation over `Notification.create` as the deployment's route to at-most-once. *Over:* keeping a reconciliation that read Pending-only ids and matched on payload. *Because:* `pending_for` cannot see a record the delivery layer has moved on, a payload is not a fanout identity, and a guard first consulted at retry never saw the original create — the reconciliation promised what no read of the bare atoms can deliver.
- **2026-08-28 — `fired_at` is a lower bound on the instant the set was fixed.** *Chose:* the seam reading the invocation began under, with check 1's window widened by a disclosed `max_read_latency`. *Over:* a stamp "taken immediately before the query" described as the instant the set was fixed. *Because:* the store fixes the set when it executes the read, an instant the composition never observes; the earlier wording named a moment nothing on the page can see and let check 1 convict a subscribe that landed inside the read's latency.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two invariants the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision`, `Clock semantics` and `Indeterminate outcome` as the wiring surfaces, the six surviving invariant numbers unchanged, and the acceptance section's own two-tier split carried across as `Check` and `External check`. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. Two families are worth naming: the *Retry semantics* section is `Indeterminate outcome` — the family [Approval Step](../atoms/approval-step.md), [Medication Order](../atoms/medication-order.md) and [Party Identity](../atoms/party-identity.md) already carry — so it was taken rather than minted, which puts that family at four specs and makes this the first composition to hold it. And *Logic confinement* is `Capability requirement`, the standard family, because what the section states is what the host must supply.
- **2026-09-14 — Two preservation claims are one citation.** *Chose:* `Composes 7`, with `Invariant 6` and `Invariant 7` tombstoned to it. *Over:* keeping them. *Because:* the prose already drew the line the ruling needs — *Invariants 1–5 and 8 emerge from the composition; Invariants 6 and 7 are preservation claims* — and [`execution-contract.md`](../execution-contract.md) §Conformance settles a preservation claim by reference, so restating it twice was a citing spec restating a rule it cites (Authority 6, council read 53, council read 55). What the two carried beyond the blanket survives as `Composes 5` and `Composes 6`: reading the subscription store only through `subscribers_for` and refusing to reach past `create` are this composition's own restraint and are not guarantees either atom makes about a caller.
- **2026-09-14 — Five of the Ledger's six open lines are closed by the migration.** *Chose:* to close `2026-08-27-g`, `-h`, `-i`, `-k` and `-l` in the rewrite and strike them from the Ledger's open list, leaving `-j`. *Over:* migrating the language and leaving six known defects standing behind it. *Because:* all five were language or ownership defects a rewrite is the natural moment to fix — an unconditional coverage claim that needed the crash bound (`Wiring decision 3`, `Non-goal 3`, `Invariant 1`'s WHY), an acceptance preamble opening universally where two checks need a composed Event Log (now conditional, and stated in the preamble), Notification's own acceptance classified both record-clearable and external (classified once, as `External check 5`), `invalid-request`'s provenance stated two ways (stated once, in `Primitive policy`'s WHY), and the two constituents' divergent non-empty definitions left unnamed (named in `Indeterminate outcome`'s WHY — Subscription admits a whitespace-only ref and caps nothing, Notification refuses both). `-j` stays open because it is a design choice rather than a defect: an Event Log entry carrying the full created and failed lists is unbounded in N against Event Log's payload cap, and bounding, chunking or digesting it is the maintainer's to pick. The `status:`, `formal:` and `last gate:` lines are untouched (council read 56).

NOTE: End of Notification Fanout.

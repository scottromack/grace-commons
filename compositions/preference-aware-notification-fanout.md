---
title: Preference-Aware Notification Fanout
parent: Conceptual Compositions
has_toc: true
toc: true
---

# Preference-Aware Notification Fanout

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>


## Summary

Preference-Aware Notification Fanout connects an event to everyone who asked to hear about it — delivered the way each of them wants. It wires together four simpler patterns: one for who is interested in which events ([Subscription](../atoms/subscription.md)); one for each person's delivery wishes — preferred channels, "no more than N a day," "nothing between 10pm and 7am," plain versus rich format ([Message Preference](../atoms/message-preference.md)); one that creates a per-recipient delivery record and tracks its outcome ([Notification](../atoms/notification.md)); and one that keeps a permanent ordered journal of everything that happened ([Event Log](../atoms/event-log.md)). When an event fires, it asks who is subscribed and, for each subscriber, reads their current preferences and decides: deliver on these channels in this format, or don't — for a named reason (paused, inside quiet hours, over their frequency limit, or opted out of every channel). The guarantee none of the four can make alone: every subscriber gets exactly one recorded **disposition** — delivered, failed, or suppressed-with-a-reason — and nothing is silently dropped, so the deployment can later prove from the journal that it honored quiet-hours and opt-out rules, the evidence telemarketing and commercial-email regulations effectively demand.

---

## Intent

Notification Fanout answers *who should receive this?* and produces one delivery record per Active subscriber. What it cannot answer is *how does this subscriber want delivery shaped — and is right now even an acceptable moment?* The Message Preference atom records those answers: channels, frequency limits, quiet hours, format. But by its own declaration Message Preference does not deliver, does not consult subscriptions, and does not interpret its own opaque values — it names "the composing fanout pattern" as the interpreter. The interpretation point — the moment a fanout invocation reads a subscriber's in-effect preference record and renders a delivery-or-suppress verdict — belongs to no atom. It is this composition's reason to exist.

The stakes of that interpretation point are regulatory, not cosmetic. The TCPA (Telephone Consumer Protection Act, codified at section 227 of title 47 of the United States Code (U.S.C.) — the US federal law restricting unsolicited calls and text messages) attaches per-message statutory liability to a text sent inside a recipient's quiet window; CAN-SPAM (the US Controlling the Assault of Non-Solicited Pornography And Marketing Act, 15 U.S.C. section 7701 et seq.) requires honored opt-outs in commercial email. A fanout loop that consults preferences "usually" delivers inside quiet windows whenever a code path forgets to check. This composition makes the check structural. The shaping gate sits between `Subscription.subscribers_for` and each `Notification.create`, so every subscriber passes through it on every disposition — the original invocation's pass and any later journaled retry. Its verdict is recorded whether it delivers or suppresses. A suppressed subscriber is not a skipped subscriber — the suppression is a first-class disposition, classified by reason, written to the Event Log, and queryable later by the regulator, the disputing recipient, or the breach investigator.

This composition does **not** compose Notification Fanout. Notification Fanout's fanout action exposes no per-subscriber hook; wrapping it cannot insert the shaping gate between the query and the creates without a breaking change to a grounded composition. The precedent is [Reserve from Pool](./reserve-from-pool.md), the pool-arithmetic superset of Idempotent Reservation: re-wire the same atoms plus more, rather than wrap the smaller composition. Notification Fanout remains the unshaped sibling — deployments that need fanout without preference shaping use it directly. This composition mirrors its loop, its failure isolation, and its fanout_id correlation discipline, widening the bipartition `{created, failed}` to the trichotomy `{created, failed, suppressed}`.

Two boundary declarations the constituents themselves draw, restated here because the composing layer must honor the sequencing. First, **legal permission is not evaluated here**: whether the system may communicate with the principal at all is the Consent pattern's question, and Message Preference's own blockquote draws that line. A deployment whose deliveries require lawful basis sequences the Consent gate *before* invoking this composition; [Consent](../atoms/consent.md) and [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) are named peers, not constituents. Second, **attribution is not provided here**: a deployment that must answer *who triggered this fanout* under credential composes [Audit Trail](./audit-trail.md) or [Actor Identity](../atoms/actor-identity.md) alongside; the bare composition records dispositions, not initiators.

---

## Composes

- **[Subscription](../atoms/subscription.md)** — who is subscribed: the Active subscriber set for a scope, and the point query that re-verifies one subscriber.
- **[Notification](../atoms/notification.md)** — the per-recipient delivery record, its status, and the pending records per recipient.
- **[Message Preference](../atoms/message-preference.md)** — each principal's in-effect delivery-shaping record, read-only.
- **[Event Log](../atoms/event-log.md)** — the durable disposition journal and its replay surface.

```
Composes 1: EXACTLY ONE Subscription instance MUST serve the composition.
Composes 2: EXACTLY ONE Notification instance MUST serve the composition.
Composes 3: EXACTLY ONE Message Preference instance MUST serve the composition.
Composes 4: EXACTLY ONE Event Log instance MUST serve the composition.
Composes 5: The composition MUST inherit a constituent's invariants PER Execution Contract Conformance 8.
Composes 6: The composition MUST NOT change a constituent's spec.
Composes 7: The composition MUST NOT call a Subscription write.
Composes 8: The composition MUST NOT call a Message Preference write.
Composes 9: The composition MUST NOT call a Notification write other than create.
Composes 10: The composition MUST read a constituent ONLY through the constituent's declared action AND query surface.
Composes 11: The composition MUST interpret Message Preference's opaque channel preferences, frequency limit, quiet hours AND format.
Composes 12: The composition MUST NOT interpret a preference record's metadata.
Composes 13: The composition MUST NOT compose Notification Fanout.
```

Term composition: this pattern's wiring of [Subscription](../atoms/subscription.md), [Notification](../atoms/notification.md), [Message Preference](../atoms/message-preference.md) and [Event Log](../atoms/event-log.md) — the four actions, the shaping gate, the two derived indexes and the reconciliation.

Term constituents: [Subscription](../atoms/subscription.md), [Notification](../atoms/notification.md), [Message Preference](../atoms/message-preference.md), [Event Log](../atoms/event-log.md).

Term journal: the Event Log instance's events, in sequence order, as the composition and an auditor read them.

Adjacent, **not** constituents: [Consent](../atoms/consent.md) and [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) (legal permission, sequenced before this composition); [Audit Trail](./audit-trail.md) (attribution and sealing); [Duplicate Prevention](../atoms/duplicate-prevention.md) (at-most-once fanout under wholesale retry).

---
## Composition logic

### Composition state

```
Composition state 1: The composition MUST store the delivery count index.
Composition state 2: The composition MUST key the delivery count index by principal reference.
Composition state 3: A delivery count entry MUST carry the decided instant AND the channels of one of the principal's delivery events.
Composition state 4: The composition MUST rebuild a missing delivery count entry from the principal's delivery events inside the interpreted frequency window.
Composition state 5: The composition MUST write a delivery count entry ONLY AFTER the delivery pair lands.
Composition state 6: The composition MUST remove a delivery count entry whose decided instant leaves every interpreted frequency window.
Composition state 7: The composition MUST store the fanout dispositions index.
Composition state 8: The composition MUST key the fanout dispositions index by fanout id.
Composition state 9: The composition MUST rebuild a missing fanout dispositions entry from the journal's events carrying the fanout id.
Composition state 10: The composition MUST read the journal through the journal query capability.
Composition state 11: EVERY disposition event MUST carry a fanout id naming EXACTLY ONE initiation entry.
Composition state 12: EVERY queried subscriber MUST carry a disposition event at quiescence.
Composition state 13: The composition MUST read a disposition pair's latest disposition event as the pair's operative disposition.
Composition state 14: The composition MUST NOT change a disposition event.
Composition state 15: EVERY preference id a disposition event carries MUST name a record in effect at the event's decided instant.
```

Term delivery count index: the composition's map from a principal to the decided instants and channels of the principal's recent delivery events — the frequency-cap evaluation's input.

Term delivery count entry: one decided instant and channel set in the delivery count index.

Term fanout dispositions index: the composition's map from a fanout id to the invocation's dispositions, for audit queries.

Term interpreted frequency window: a window the frequency limit interpretation reads from a stored frequency limit.

Term disposition pair: a fanout id with one principal reference.

Term queried subscriber: a principal the initiation entry's queried list names.

Term quiescence: a state in which no invocation, redisposition or reconciliation run is in flight for the fanout id.

NOTE: Contract classification, per the section titled Composition state in `execution-contract.md` — the delivery count index: derived index over the principal's delivery events, rebuilt inside the interpreted frequency window (Composition state 4); the fanout dispositions index: derived index over the journal's events carrying the fanout id (Composition state 9).

### Capability requirement

```
Capability requirement 1: A deployment MUST declare the quiet hours interpretation.
Capability requirement 2: A deployment MUST declare the frequency limit interpretation.
Capability requirement 3: A deployment MUST declare the channel interpretation.
Capability requirement 4: A deployment MUST declare the default shape.
Capability requirement 5: IF the default shape's channel set EQUALS blank THEN the composition MUST refuse to start.
Capability requirement 6: An interpretation rule MUST answer one interpretation for one stored value AND one now.
Capability requirement 7: A deployment MUST version the interpretation configuration.
Capability requirement 8: The composition MUST NOT change a configuration version.
Capability requirement 9: A deployment MUST retain EVERY configuration version for the audit horizon.
Capability requirement 10: The quiet hours interpretation MUST resolve a window in the recipient-local time the stored value declares.
Capability requirement 11: A deployment MUST set the no record policy.
Capability requirement 12: A deployment MUST set the cap policy.
Capability requirement 13: A deployment MUST set the quiet window policy.
Capability requirement 14: A deployment MUST declare the cap serialization.
Capability requirement 15: A deployment whose frequency caps carry legal force MUST declare serialized-per-principal as the cap serialization.
Capability requirement 16: IF the cap serialization EQUALS serialized-per-principal THEN the host MUST supply a per-principal exclusion.
Capability requirement 17: IF the cap serialization EQUALS serialized-per-principal THEN the composition MUST NOT evaluate a cap BEFORE rebuilding a missing delivery count entry under the per-principal exclusion.
Capability requirement 18: The per-principal exclusion MUST bind EVERY cap evaluation for the principal.
Capability requirement 19: A deployment MUST declare the journal query capability.
Capability requirement 20: A deployment MUST set the payload digest function.
Capability requirement 21: A deployment MUST set the reconciliation window.
Capability requirement 22: A deployment MUST set the reconciliation cadence.
Capability requirement 23: A deployment MUST disclose the notification create latency.
Capability requirement 24: A deployment MUST disclose the disposition write latency.
Capability requirement 25: A deployment MUST disclose the max query latency.
Capability requirement 26: A deployment MUST set the abandonment principals cap.
Capability requirement 27: A deployment MUST set the invocation duration bound.
Capability requirement 28: A deployment MUST declare the clock tolerance.
Capability requirement 29: The composition MUST start ONLY IF the reconciliation window EXCEEDS the liveness sum.
Capability requirement 30: A deployment MUST set the hold retry horizon.
Capability requirement 31: The host MUST supply a per-disposition exclusion keyed by disposition pair.
Capability requirement 32: The host MUST release the per-disposition exclusion on the holder's return.
Capability requirement 33: The host MUST release the per-disposition exclusion on the holder's death.
Capability requirement 34: The host MUST hold the per-disposition exclusion as a lease.
Capability requirement 35: The host MUST set the lease length to the invocation duration bound.
Capability requirement 36: The composition MUST read a lease's expiry as the holder's terminus.
Capability requirement 37: The per-disposition exclusion MUST admit the holder's own nested call.
Capability requirement 38: The per-disposition exclusion MUST NOT admit a foreign holder.
Capability requirement 39: IF the host supplies no per-disposition exclusion THEN the composition MUST refuse to start.
Deleted: Capability requirement 40. Execution Contract Database 1 owns it: a disposition's create and its delivery event commit together, and the composition names no orphan for a lookup to find.
Capability requirement 41: A deployment whose deliveries on a statutorily time-restricted channel fall within the restriction's scope MUST declare the statutory quiet window.
Capability requirement 42: A deployment omitting the statutory quiet window MUST disclose the omission as the deployment's legal posture.
Capability requirement 43: The host MUST inject now at the seam once per invocation.
Capability requirement 44: The composition MUST stamp the fired instant AND EVERY decided instant of one invocation from the invocation's now.
Capability requirement 45: The composition MUST NOT read the clock inside the shaping gate.
Capability requirement 46: The composition MUST take the fanout id from the seam.
Capability requirement 47: The deployment MUST supply the constituent instances' database PER Execution Contract Database 1 through 4.
```

Term quiet hours interpretation: the deployment's rule reading a stored quiet hours value as a predicate over now — is this instant inside the principal's quiet window.

Term frequency limit interpretation: the deployment's rule reading a stored frequency limit as one or more window-and-cap pairs, rolling or calendar-aligned, channel-scoped or not.

Term channel interpretation: the deployment's rule reading stored channel preferences as the deliverable channel set, and a stored format as the envelope's format.

Term default shape: the channel set and format the deliver path uses where no channels are stated — never an empty channel set.

Term configuration version: the id of one immutable version of the interpretation configuration, the default shape, the statutory quiet window and the policy settings.

Term no record policy: deliver-unshaped | suppress — the disposition where current_for answers none; deliver-unshaped where the deployment declares none.

Term cap policy: drop | hold — whether a frequency-cap suppression is retry-eligible; drop where the deployment declares none.

Term quiet window policy: drop | hold — whether a quiet-window suppression is retry-eligible; hold where the deployment declares none.

Term cap serialization: serialized-per-principal | best-effort — whether the host serializes a principal's cap evaluation and delivery commit; no default.

Term per-principal exclusion: the host-supplied mutual exclusion keyed by principal reference, over a cap evaluation and the delivery commit after it.

Term journal query capability: the deployment's declared guarantee that the Event Log instance's read answers a predicate on event type, fanout id, principal reference and decided-instant range.

Term payload digest function: the deterministic digest the initiation entry and [Redispose] take of the payload content.

Term reconciliation window: the duration within which the reconciliation resolves a journal gap or records a cap overshoot.

Term reconciliation cadence: the interval between the reconciliation's runs, beside the run at every restart.

Term notification create latency: the deployment's disclosed bound on one create landing and becoming visible to pending_for.

Term disposition write latency: the deployment's disclosed bound on one closing write landing.

Term max query latency: the deployment's disclosed bound between the fired instant and subscribers_for answering.

Term abandonment principals cap: the most principals one abandonment record names.

Term invocation duration bound: the longest a [Fanout Shaped] may run from the initiation entry to its last write — the lease length, the gap leg's lower edge with the create latency, and the invocation's terminus.

Term clock tolerance: the write-clock skew bound between now and the constituents' write clocks, and the accounting-clock regression bound — two components.

Term liveness sum: `(((invocation duration bound + notification create latency) + reconciliation cadence) + disposition write latency)`.

Term hold retry horizon: the duration after a hold suppression's decided instant past which the suppression is terminal.

Term per-disposition exclusion: the host-supplied mutual exclusion keyed by disposition pair, held as a lease by every writer of the pair's disposition.

Term statutory quiet window: a deployment-declared window and channel set evaluated for every disposition, whatever the principal's stored preferences — the law's window.

Term audit horizon: the journal's retention horizon.

Term seam: the composition's input and output boundary — the one place the host reads the clock and generates the fanout id, per the section titled Logic Confinement Principle in `execution-contract.md`.

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

### Primitive policy

```
Primitive policy 1: IF the event scope EQUALS blank THEN [Fanout Shaped] MUST answer invalid-request.
Primitive policy 2: IF the payload content EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 3: IF a supplied fanout id EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 4: IF a supplied principal reference EQUALS blank THEN the action MUST answer invalid-request.
Primitive policy 5: The composition MUST compare a subscriber reference with a principal reference byte-exact.
Primitive policy 6: The composition MUST NOT normalize an event scope.
Primitive policy 7: A deployment MUST register one canonical reference per person in Subscription AND Message Preference alike.
Primitive policy 8: A deployment MUST size the payload cap for the largest record the composition writes.
Primitive policy 9: An action refused under Primitive policy 1 through 4 MUST NOT write.
```

### Action wiring

```
fanout_shaped(event_scope, payload_content)
  answers fanout result
  refuses invalid-request | subscribers-unavailable | journal-rejected

redispose(fanout_id, principal_ref, payload_content)
  answers redisposition
  refuses invalid-request | not-known | not-retryable | payload-mismatch | journal-rejected(redispose position) | yielded

reconcile_gaps(fanout_id, optional payload_content, abandon)
  answers gap result
  refuses invalid-request | not-known | payload-mismatch | too-young | journal-rejected(gap position)

reconcile_overshoots(principal_ref)
  answers overshoot result
  refuses invalid-request | journal-rejected
```

Term fanout result: the fanout id and four unordered lists — created (principal and notification id), failed (principal and cause), suppressed (principal, reason and preference id or none) and yielded (principal).

Term redisposition: created carrying the notification id | failed carrying the cause | suppressed carrying the reason and the preference id or none.

Term redispose position: read | outcome — whether the refused read preceded everything, or the outcome's append was refused.

Term gap result: the repaired principals with each outcome, and the abandoned principals or all.

Term gap position: intent | abandonment.

Term overshoot result: the overshoots recorded, each a configuration version, a window, a cap and the committed count.

```
Action wiring 1: A validated fanout MUST take a fanout id from the seam.
Action wiring 2: A validated fanout MUST call the subscriber query with the event scope.
Action wiring 3: IF the subscriber query fails THEN [Fanout Shaped] MUST answer subscribers-unavailable.
Action wiring 4: IF the subscriber query fails THEN [Fanout Shaped] MUST NOT write.
Action wiring 5: A validated fanout MUST record the initiation entry carrying the fanout id, the event scope, the queried list, the configuration version, the payload digest AND the fired instant ONLY AFTER the subscriber query answers.
Action wiring 6: IF Event Log refuses the initiation entry THEN [Fanout Shaped] MUST answer journal-rejected.
Action wiring 7: IF Event Log refuses the initiation entry THEN [Fanout Shaped] MUST NOT call Notification's create.
Action wiring 8: An initiated fanout MUST dispose EVERY queried subscriber.
Deleted: Action wiring 9. Execution Contract Database 2 owns it.
Action wiring 10: An initiated fanout MUST read the pair's latest disposition event under the per-disposition exclusion.
Action wiring 11: IF the read finds a disposition event THEN the initiated fanout MUST answer the event's disposition for the subscriber.
Action wiring 12: IF the read finds a disposition event THEN the initiated fanout MUST NOT write for the subscriber.
Action wiring 13: IF the per-disposition exclusion's lease expired THEN the initiated fanout MUST answer the subscriber AND EVERY remaining subscriber as yielded.
Action wiring 14: The initiated fanout MUST NOT write for a yielded subscriber.
Action wiring 15: IF the read of Action wiring 10 finds no disposition event THEN an initiated fanout MUST read the preference read for the subscriber.
Action wiring 16: IF the preference read fails THEN the initiated fanout MUST fail the subscriber carrying preference-unreadable.
Action wiring 17: IF the preference read fails THEN the initiated fanout MUST NOT run the shaping gate.
Action wiring 18: IF the preference read answers THEN the initiated fanout MUST run the shaping gate on the answer, the now, the delivery history AND the configuration.
Action wiring 19: IF the shaping gate answers deliver THEN the initiated fanout MUST call Notification's create with the subscriber AND the envelope.
Action wiring 20: An envelope MUST carry the payload content, the channels, the format AND the fanout id.
Action wiring 21: The initiated fanout MUST record the delivery event ONLY AFTER Notification's create answers the notification id.
Action wiring 22: A delivery event MUST carry the fanout id, the principal reference, the notification id, the channels, the format, the preference id, the evaluation inputs AND the decided instant.
Action wiring 23: The initiated fanout MUST make the delivery pair under the per-disposition exclusion.
Action wiring 24: IF Event Log refuses a delivery event THEN the initiated fanout MUST answer the subscriber as yielded.
Action wiring 25: IF Event Log refuses a delivery event THEN the initiated fanout MUST NOT record a failure event for the subscriber.
Action wiring 26: IF Notification's create refuses THEN the initiated fanout MUST record a failure event carrying create-failed.
Action wiring 27: A failure event MUST carry the fanout id, the principal reference, the cause, the preference id AND the decided instant.
Action wiring 28: IF the shaping gate answers fail THEN the initiated fanout MUST record a failure event carrying the gate's cause.
Action wiring 29: IF the shaping gate answers suppress THEN the initiated fanout MUST record a suppression event carrying the fanout id, the principal reference, the reason, the preference id, the evaluation inputs, the retry eligibility AND the decided instant.
Action wiring 30: IF Event Log refuses a suppression event OR a failure event THEN the initiated fanout MUST answer the subscriber in the matching list.
Action wiring 31: A delivery event's evaluation inputs MUST carry the observed record status, the now, EVERY interpreted window-and-cap pair with the gate's in-window count AND the statutory exclusion the gate evaluated.
Action wiring 32: A suppression event's evaluation inputs MUST carry the observed record status, the now AND the inputs of the rule that fired.
Action wiring 33: A suppression event MUST carry true as the retry eligibility ONLY IF the reason's policy EQUALS hold.
Action wiring 34: IF the reason IS IN the action-relented reasons THEN the suppression event MUST carry false as the retry eligibility.
Action wiring 35: A subscriber's disposition MUST NOT abort another subscriber's disposition.
Action wiring 36: An initiated fanout MUST answer the fanout result.
Action wiring 37: A validated redisposition MUST resolve the fanout id to an initiation entry through the journal.
Action wiring 38: IF no initiation entry carries the fanout id THEN [Redispose] MUST answer not-known.
Action wiring 39: IF the journal read fails THEN [Redispose] MUST answer journal-rejected carrying read.
Action wiring 40: IF the payload content's digest DOES NOT EQUAL the initiation entry's payload digest THEN [Redispose] MUST answer payload-mismatch.
Deleted: Action wiring 41. Execution Contract Database 2 owns it.
Action wiring 42: IF a foreign holder holds the per-disposition exclusion THEN [Redispose] MUST answer yielded.
Action wiring 43: IF the lease expires ahead of the commit THEN [Redispose] MUST answer yielded.
Action wiring 44: A [Redispose] answering yielded MUST NOT write.
Action wiring 45: IF an abandonment record covers the principal THEN [Redispose] MUST answer not-retryable.
Action wiring 46: IF the pair's operative disposition IS NOT IN the retryable dispositions THEN [Redispose] MUST answer not-retryable.
Action wiring 47: IF the pair carries no disposition event AND the principal IS NOT IN the queried list THEN [Redispose] MUST answer not-retryable.
Action wiring 48: A validated redisposition MUST read a delivery event's record status through the status read.
Deleted: Action wiring 49. Execution Contract Database 1 owns it.
Deleted: Action wiring 50. Execution Contract Database 1 owns it.
Deleted: Action wiring 51. Execution Contract Database 1 owns it.
Action wiring 52: An admitted redisposition MUST call Subscription's subscribed with the principal AND the initiation entry's event scope.
Action wiring 53: IF subscribed answers not-subscribed THEN [Redispose] MUST record a suppression event carrying unsubscribed, false as the retry eligibility, none as the preference id AND the audience check with the now as the evaluation inputs.
Action wiring 54: IF subscribed answers subscribed THEN [Redispose] MUST dispose the principal PER Action wiring 15 through 34 under a fresh now.
NOTE: watch rule inheritance (Action wiring 54) — [Redispose] makes no read of Action wiring 10, the read Action wiring 15's condition names.
Action wiring 55: A redisposition event MUST carry the original fanout id AND the redisposition flag.
Action wiring 56: IF Event Log refuses a redisposition event THEN [Redispose] MUST answer journal-rejected carrying the outcome position.
Deleted: Action wiring 57. Execution Contract Database 1 owns it: a redisposition's writes commit together, so no journal-rejected carries a notification id.
Action wiring 58: An admitted redisposition MUST answer the committed disposition.
```

Term subscriber query: Subscription's subscribers_for on the event scope.

Term preference read: Message Preference's current_for on the subscriber.

Term status read: Notification's status_of on a notification id.

Term validated fanout: a [Fanout Shaped] call whose inputs cleared Primitive policy.

Term initiated fanout: a validated fanout whose initiation entry landed.

Term validated redisposition: a [Redispose] call whose inputs cleared Primitive policy.

Term admitted redisposition: a validated redisposition whose fanout id, digest and retryability checks passed.

Term queried list: the subscriber list subscribers_for answered, journaled whole on the initiation entry — the invocation's true scope.

Term initiation entry: the fanout.initiated event.

Term delivery event: the fanout.created event — in line or a redisposition.

Term suppression event: the fanout.suppressed event.

Term failure event: the fanout.create-failed event.

Term disposition event: a delivery event, a suppression event or a failure event.

Term envelope: the payload content, the channels, the format and the fanout id a created Notification carries.

Term delivery pair: Notification's create, then the delivery event naming the record it answered.

Term delivery history: the principal's delivery count entries | unavailable.

Term reason's policy: the quiet window policy for quiet-window; the cap policy for frequency-cap.

Term action-relented reason: suspended | no-record | channel-opt-out | unsubscribed — a suppression that relents only by the principal's own action.

Term retryable disposition: a failure event; a suppression event carrying true as the retry eligibility whose `(decided instant + hold retry horizon)` DOES NOT PRECEDE now; a delivery event whose record's status IS IN failed and expired.

Term redisposition flag: redisposition set to true.

Term observed record status: active | suspended | none — the status the gate saw, journaled because status is the one field Message Preference leaves mutable.

### Wiring decision

```
Wiring decision 1: The composition MUST place the shaping gate between the subscriber query AND EVERY Notification create.
Wiring decision 2: The composition MUST NOT call Notification's create for a principal the shaping gate did not answer deliver for.
Wiring decision 3: The composition MUST record EVERY suppression as a classified disposition event.
Wiring decision 4: The composition MUST NOT remove a queried subscriber from the fanout without a disposition.
```

<details markdown="block">
<summary>WHY</summary>

*Principle.* Preference shaping is only worth composing if it is unbypassable and auditable. A gate that filters the subscriber list silently produces an unanswerable audit: a subscriber absent from the created list might have been suppressed by preference, lost to a failure or skipped by a bug — three liabilities, indistinguishable. The trichotomy makes the three structurally distinct, and the per-disposition append makes each provable later.

*Likely objection.* Why record a suppression at all? Not delivering is the absence of an action, and recording every non-delivery bloats the log.

*Mechanism.* For an unregulated feed, perhaps. But the regulatory questions this composition exists to answer are about non-delivery: *prove you did not text this person inside their quiet window* and *prove you honoured the opt-out* are answered by the suppression event showing the gate fired, with the reason, the preference record and what the gate saw. An absence proves nothing (Wiring decision 3 and 4). The cost is one append per suppression, and the frequency accounting needs the delivery events in the journal anyway. The gate is a composition-introduced pure function — the preference record or none, the injected now, the principal's delivery history or the unavailable marker, and the configuration in; one verdict out — evaluated once per subscriber per disposition, the original pass and every redisposition, between the query and the create (Wiring decision 1 and 2). Its history input is the history, not a precomputed count, because an interpretation may yield several window-and-cap pairs, possibly channel-scoped, each counted inside the function from the one set. It is pure under the Logic Confinement Principle: the now is injected at the seam and passed as a value, never read inside, and no action signature carries a clock. Purity is what makes Invariant 7 checkable.

*Result.* The four lists partition the queried set (Invariant 1); every suppression is classified and journaled (Invariant 5); the regulator's quiet-window query, the disputing recipient's 3am-text query and the breach investigator's bypass query are all provable from the journal and the preference records.

</details>

### Reconciliation

```
Reconciliation 1: The reconciliation MUST run every reconciliation cadence.
Deleted: Reconciliation 2. Execution Contract Scheduled leg 1 owns it.
Reconciliation 3: IF the fanout id names a young invocation THEN [Reconcile Gaps] MUST answer too-young.
Reconciliation 4: [Reconcile Gaps] MUST NOT write for a young invocation.
Reconciliation 5: [Reconcile Gaps] MUST NOT write for an invocation whose initiation entry is an aged entry.
Reconciliation 6: IF the gap run's fanout id resolves to no initiation entry THEN the gap run MUST answer not-known.
Reconciliation 7: IF a supplied payload content's digest DOES NOT EQUAL the initiation entry's payload digest THEN [Reconcile Gaps] MUST answer payload-mismatch.
Reconciliation 8: A gap run MUST NOT repair BEFORE the gap run's reconcile intent lands.
Reconciliation 9: A reconcile intent MUST carry the fanout id AND the decided instant.
Reconciliation 10: A gap run MUST take the per-disposition exclusion for EVERY gap principal.
Reconciliation 11: IF the re-read under the exclusion finds a disposition event THEN the gap run MUST NOT write for the principal.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Reconciliation 17: IF the payload content EXISTS AND abandon EQUALS false THEN the gap run MUST call [Redispose] as the exclusion's holder.
Reconciliation 18: IF [Redispose] answers yielded, journal-rejected OR not-retryable to a gap run THEN the gap run MUST carry the principal to the next run.
Reconciliation 19: A gap run MUST NOT abandon a principal the gap run carries to the next run.
Reconciliation 20: IF abandon EQUALS true THEN the gap run MUST abandon EVERY remaining gap principal.
Reconciliation 21: IF the payload content EQUALS blank THEN the gap run MUST NOT call [Redispose].
Reconciliation 22: An abandonment record MUST carry the fanout id, the principals, the abandonment reason AND the decided instant.
Reconciliation 23: The principals one abandonment record names MUST NOT EXCEED the abandonment principals cap.
Reconciliation 24: IF a gap run abandons a principal THEN the gap run MUST record an abandonment record under the per-disposition exclusion.
Reconciliation 25: IF a gap run's lease expires THEN the gap run MUST NOT write for the principal.
Reconciliation 26: IF Event Log refuses the reconcile intent THEN [Reconcile Gaps] MUST answer journal-rejected carrying intent.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Reconciliation 28: IF Event Log refuses an abandonment record THEN [Reconcile Gaps] MUST answer journal-rejected carrying abandonment.
Reconciliation 29: A refused append MUST NOT withdraw the gap run's earlier redispositions.
Reconciliation 30: An overshoot run MUST read the principal's delivery events under each journaled configuration version's window-and-cap pairs.
Reconciliation 31: IF a window's committed count EXCEEDS the window's contemporaneous cap AND no overshoot record already names the overshoot AND the window's start IS NOT IN the aged instants THEN the overshoot run MUST record an overshoot record carrying the principal, the configuration version, the window, the cap, the committed count AND the decided instant.
Reconciliation 32: The overshoot run MUST NOT record an overshoot an overshoot record already names.
Deleted: Reconciliation 33. Execution Contract Database 2 owns it.
Deleted: Reconciliation 34. Execution Contract Database 2 owns it.
Reconciliation 35: The overshoot run MUST NOT record a window whose start is an aged instant.
Reconciliation 36: The reconciliation MUST NOT store composition state.
```

Term reconciliation: the two legs, [Reconcile Gaps] and [Reconcile Overshoots], each a scheduled leg (Execution Contract Scheduled leg 1), whose output — a closed gap or a recorded overshoot — an auditor awaits within the reconciliation window.

Term gap run: one call of [Reconcile Gaps].

Term overshoot run: one call of [Reconcile Overshoots].

Term young invocation: an invocation whose `((fired instant + invocation duration bound) + notification create latency)` DOES NOT PRECEDE now — still in its loop.

Term aged entry: a journal entry whose `(recording instant + audit horizon)` PRECEDES now.

Term aged instant: an instant such that `(instant + audit horizon)` PRECEDES now.

Term gap principal: a queried subscriber carrying no disposition event under the fanout id.

Term reconcile intent: the fanout.reconcile-intended event — the gap run's intent, naming the invocation it is about to repair.

Term abandonment record: the fanout.abandoned event — the terminal record discharging the liveness of the principals it names, or of all.

Term abandonment reason: payload-unavailable | operator-declined | redispose-rejected.

Term overshoot record: the fanout.cap-overshoot-reconciled event.

### Shaping gate

```
Shaping gate 1: The shaping gate MUST answer EXACTLY ONE verdict per disposition.
Shaping gate 2: The shaping gate MUST evaluate the precedence rules in the declared order.
Shaping gate 3: The shaping gate MUST stop at the first rule that fires.
Shaping gate 4: The shaping gate MUST skip a rule whose input the record does not carry.
Shaping gate 5: IF the record's status EQUALS suspended THEN the shaping gate MUST answer suppress carrying suspended.
Shaping gate 6: IF the preference read answered none AND the no record policy EQUALS suppress THEN the shaping gate MUST answer suppress carrying no-record.
Shaping gate 7: IF the preference read answered none AND the no record policy EQUALS deliver-unshaped THEN the shaping gate MUST take the default shape to channel selection.
Shaping gate 8: IF the record carries quiet hours AND the quiet hours interpretation reads now inside the window THEN the shaping gate MUST answer suppress carrying quiet-window.
Shaping gate 9: IF the record carries a frequency limit AND an interpreted pair's cap DOES NOT EXCEED the pair's in-window count THEN the shaping gate MUST answer suppress carrying frequency-cap.
Shaping gate 10: The shaping gate MUST NOT count a history entry naming another channel toward a channel-scoped pair.
Shaping gate 11: IF a rule the shaping gate reaches consults a field whose interpretation is undeclared THEN the shaping gate MUST answer fail carrying interpretation-undeclared.
Shaping gate 12: IF the shaping gate reaches the cap rule AND the delivery history EQUALS unavailable THEN the shaping gate MUST answer fail carrying accounting-unreadable.
Shaping gate 13: IF the precedence walk reaches channel selection THEN the shaping gate MUST map the stated channel preferences to the channel set AND format.
Shaping gate 14: IF the deliver path states no channels THEN the shaping gate MUST take the default shape's channel set.
Shaping gate 15: The shaping gate MUST exclude EVERY channel of a statutory quiet window containing now.
Shaping gate 16: IF the channel set DOES NOT EQUAL blank THEN the shaping gate MUST answer deliver carrying the channel set AND the format.
Shaping gate 17: IF the preference values emptied the channel set THEN the shaping gate MUST answer suppress carrying channel-opt-out.
Shaping gate 18: IF the statutory exclusion emptied the channel set THEN the shaping gate MUST answer suppress carrying quiet-window.
Shaping gate 19: The shaping gate MUST NOT answer deliver on a fail-closed cause.
Shaping gate 20: The shaping gate MUST NOT call a constituent.
Shaping gate 21: The composition MUST NOT reorder the precedence rules.
Shaping gate 22: The composition MUST NOT re-render a verdict for a record change the gate's read did not see.
```

Term shaping gate: the composition-introduced pure function rendering one subscriber's verdict — a [Shaping Disposition].

Term verdict: deliver carrying the channels and the format | suppress carrying the reason | fail carrying the fail-closed cause.

Term precedence rules: the suspended rule, the no-record rule, the quiet rule, the cap rule and channel selection — i through v, in that order.

Term suppression reason: suspended | no-record | quiet-window | frequency-cap | channel-opt-out | unsubscribed.

Term fail-closed cause: preference-unreadable | accounting-unreadable | interpretation-undeclared.

Term failure cause: create-failed | preference-unreadable | accounting-unreadable | interpretation-undeclared.

Term interpreted field: channel preferences | frequency limit | quiet hours | format — the four preference fields the composition interprets.

### Verdict replay

```
Verdict replay 1: Re-evaluating the shaping gate on a verdict-bearing event's recorded inputs MUST reproduce the recorded verdict.
Verdict replay 2: The replay MUST take the preference values from Message Preference's read of the event's preference id.
Verdict replay 3: The replay MUST take the observed record status, the now AND the in-window counts from the event's evaluation inputs.
Verdict replay 4: The replay MUST evaluate under the configuration version the initiation entry journaled.
Verdict replay 5: An auditor MUST attribute a replay divergence to EXACTLY ONE OF the journal entry, the configuration disclosure, the implementation's shaping gate.
```

Term verdict-bearing event: a delivery event, or a suppression event whose reason DOES NOT EQUAL unsubscribed.

---

## Composition-level invariants

These emerge from the composition; none belongs to one constituent.

- **Invariant 1 — Disposition trichotomy.**
  ```
  Invariant 1.1: The created, failed, suppressed AND yielded lists of an initiated fanout MUST partition the queried list.
  Invariant 1.2: A principal outside the queried list MUST NOT appear in a list of the fanout result.
  ```
- **Invariant 2 — Suppression precedence over subscription.**
  ```
  Invariant 2.1: A subscriber the shaping gate suppresses MUST NOT receive a Notification create in the pass.
  Invariant 2.2: A suppression event MUST carry the first precedence rule that fired as the reason.
  ```
- **Invariant 3 — Quiet-window safety.**
  ```
  Invariant 3.1: IF the deployment declares the quiet hours interpretation AND a sound recipient-local clock THEN the composition MUST NOT commit a Notification create for a principal whose observed record's quiet hours contain now.
  Invariant 3.2: IF the deployment declares a statutory quiet window THEN the composition MUST NOT commit an envelope naming a channel of the window at a now inside the window.
  ```
- **Invariant 4 — Frequency-cap safety.**
  ```
  Invariant 4.1: IF the deployment declares the frequency limit interpretation THEN EVERY delivery event's observed in-window count MUST fall below EVERY cap interpreted from the record observed at the delivery.
  Invariant 4.2: IF the cap serialization EQUALS serialized-per-principal THEN a delivery event MUST carry the committed count at the delivery as the observed count.
  Invariant 4.3: IF the cap serialization EQUALS best-effort THEN EVERY overshoot MUST carry an overshoot record WITHIN the reconciliation window.
  ```
- **Invariant 5 — No silent disposition.**
  ```
  Invariant 5.1: EVERY suppression MUST land as a suppression event carrying the reason, the preference id, the evaluation inputs AND the retry eligibility.
  Invariant 5.2: EVERY failure MUST land as a failure event carrying the cause AND the preference id.
  ```
- **Invariant 7 — Disposition replayability.**
  ```
  Invariant 7.1: EVERY verdict-bearing event MUST replay to the event's recorded verdict PER Verdict replay 1 through 4.
  ```
- **Invariant 8 — Payload-content consistency.**
  ```
  Invariant 8.1: EVERY Notification record created under one fanout id MUST carry the content the initiation entry's payload digest names.
  ```
- **Invariant 9 — At most one live notification per subscriber per invocation.**
  ```
  Invariant 9.1: A disposition pair MUST NOT carry two live Notification records.
  ```
  Term live record: a Notification record whose status IS IN Pending and Delivered.

- **Invariant 10 — Invocation identity is unique and journaled.**
  ```
  Invariant 10.1: Two initiation entries MUST NOT carry one fanout id.
  Invariant 10.2: An initiated fanout MUST NOT commit a disposition BEFORE the initiation entry lands.
  Deleted: Invariant 6. Composes 5 owns it.
  ```

Trichotomy with no silent disposition gives the *accountable fanout* property; quiet-window safety, cap safety and suppression precedence give *shaping is unbypassable*; replayability gives *the verdict is defensible*.

---

## Examples

The walkthrough deployment declares channels `["email", "sms", "push"]`, `no_record_policy = deliver-unshaped` with default shape `{channels: [email], format: "plain"}`, `cap_policy = drop`, `quiet_window_policy = hold`, `cap_serialization = serialized-per-principal`, `frequency_limit_interpretation` reading `{per_day: N}` as a rolling 24-hour cap, `quiet_hours_interpretation` resolving stored windows in the record's own timezone, a `statutory_quiet_window` of 21:00–08:00 recipient-local on `{sms}` (its SMS sends include solicitations), a `journal_query_capability` covering the four required predicates, a `payload_digest_function`, a one-hour `reconciliation_window`, a seven-day `hold_retry_horizon`, a five-second `invocation_duration_bound`, a one-second `notification_create_latency`, a 500ms `clock_tolerance` declared for both components (the deployment attests the one bound covers write-clock skew and accounting-clock regression alike), and interpretation-configuration version `cfg_v3` in force throughout.

### Walkthrough — one invocation, all three dispositions

Four team members subscribe to `task:assigned`. Their preference states at fanout time: **ana** — Active record `pref_a` `{channel_preferences: {email: "preferred", sms: "opt-out"}, format: "plain"}`; **ben** — Suspended record `pref_b` (vacation pause); **cho** — Active record `pref_c` with `quiet_hours: {start: "22:00", end: "07:00", timezone: "Asia/Tokyo"}` — and it is 23:10 in Tokyo; **dia** — no record.

`fanout_shaped("task:assigned", {task_id: t7, assigned_by: manager_m})`:

- Step 2–4: `fanout_id = fx_01`; `subscribers_for("task:assigned") → [ana, ben, cho, dia]`; `fanout.initiated` journaled with `queried: [ana, ben, cho, dia]`, `config_version: cfg_v3`, and `fired_at`.
- **ana**: record Active; no quiet hours; no cap; channel interpretation → `{channels: [email], format: "plain"}` → `Notification.create(ana, {content, channels: [email], format: "plain"}) → notif_91`; `fanout.created` journaled. → created.
- **ben**: record Suspended → `suppress(suspended)`; `fanout.suppressed` journaled with `preference_id: pref_b`. → suppressed. (Rule 1 fired; ben's quiet hours, had he any, were never evaluated — precedence.)
- **cho**: record Active; 23:10 Tokyo is inside the stored window → `suppress(quiet-window)`; `fanout.suppressed` journaled with `evaluation_inputs` carrying the injected now and the interpreted window, `retry_eligible: true` (policy hold). → suppressed.
- **dia**: `current_for(dia) → none`; policy deliver-unshaped → default shape → `Notification.create(dia, {content, channels: [email], format: "plain"}) → notif_92`; `fanout.created` journaled with `preference_id: none`. → created.
- Returns `{fanout_id: fx_01, created: [(ana, notif_91), (dia, notif_92)], failed: [], suppressed: [(ben, suspended, pref_b), (cho, quiet-window, pref_c)], yielded: []}`.

The deployment's scheduler later queries retry-eligible suppressions for `fx_01`, finds cho's, and after 07:00 Tokyo calls `redispose(fx_01, cho, payload)`. The audience re-check confirms cho is still subscribed (`subscribed → subscribed`); the gate re-evaluates with a fresh now, the quiet window no longer contains it, and the disposition commits as `created(notif_93)` under the same fanout_id with `redisposition: true`. Had cho cancelled in the interim, the retry would have committed `suppressed(unsubscribed)` instead — journaled, never a delivery to someone who left. The composition never schedules; the scheduler decides *when*, the gate decides *whether*.

### Frequency cap firing

eli's record carries `frequency_limit: {per_day: 3}`. Deliveries committed for eli on Monday at 09:00, 11:00, and 19:00 (the `delivery_count_index`, derived from eli's `fanout.created` events). A fourth fanout fires Monday at 21:00: the gate observes three timestamps inside the rolling 24-hour window, count 3 ≥ cap 3 → `suppress(frequency-cap)`; the journaled `evaluation_inputs` record `{count: 3, window: rolling-24h, cap: 3}` and `retry_eligible: false` (policy drop). No Notification record is created. A fifth fanout on Tuesday at 13:00 finds only Monday 19:00 inside the window — count 1 — and delivers.

### Best-effort cap overshoot and reconciliation

A deployment that cannot serialize per principal declares `cap_serialization = best-effort`. Principal **fred** carries `frequency_limit: {per_day: 2}` and has one delivery in the rolling 24-hour window (count 1). Two invocations — `fx_20` and `fx_21` — fire for fred at nearly the same instant. Each gate independently reads the history, observes count 1 < cap 2, and commits a delivery: `fx_20`'s `fanout.created` records `{count: 1, window: rolling-24h, cap: 2}`; `fx_21`'s records the *same* observed `{count: 1}` — neither saw the other's not-yet-committed delivery (the time-of-check-to-time-of-use race). The committed total is now 3 against a cap of 2: a one-delivery overshoot, bounded by the two concurrent invocations.

Nothing is hidden. Each `fanout.created` event carries the headroom its gate actually saw, so Invariant 4's per-commit anchor still holds — each delivery *was* below cap at its own observation — and the overshoot is diagnosable from the journal: a post-hoc recount of fred's window finds 3 committed deliveries under a cap of 2. Within the declared `reconciliation_window`, the deployment's scheduler invokes `reconcile_overshoots(fred)`, whose detector flags the window and appends `{type: "fanout.cap-overshoot-reconciled", principal_ref: fred, config_version: cfg_v3, window: rolling-24h, cap: 2, committed: 3, decided_at}` — the record Check 2.4 reads as the evidence that the overshoot was detected and recorded within the window (Invariant 4's liveness arm, discharged). A regulated deployment whose caps carry legal force would instead have declared serialized-per-principal, under which the second gate observes count 2 and suppresses frequency-cap — no overshoot is possible.

### Statutory window firing — no stored quiet hours

**finn** holds an Active record `pref_f` with `channel_preferences: {sms: "preferred", email: "opt-out", push: "opt-out"}` and **no** stored `quiet_hours`. A fanout fires at 22:40 in finn's locale. Rule iii is skipped (no stored window — absence is no-preference); rule v maps the record to `{sms}`, then the declared `statutory_quiet_window` (21:00–08:00 on `{sms}`) excludes it — the set is emptied **by the statutory exclusion**, so the disposition is `suppress(quiet-window)` with `retry_eligible: true` and `evaluation_inputs` recording the statutory window and the excluded channel. The law's window binds finn even though finn never stated one — that is the statutory arm's whole point. After 08:00 finn-local, the scheduler's [Redispose] delivers.

### Marketing newsletter — channel opt-out under CAN-SPAM

A different deployment (a marketing platform) runs the same composition with `no_record_policy = suppress` — its regulatory posture treats absent preferences as no permission to shape a commercial send. Subscriber **gus** holds an Active record `pref_g` with `channel_preferences: {email: "opt-out", sms: "opt-out", push: "opt-out"}` — a full opt-out recorded after an unsubscribe click. Subscriber **hana** has subscribed but never opened the preferences page: no record. A campaign fanout fires: gus's channel interpretation yields an empty deliverable set → `suppress(channel-opt-out)` with `preference_id: pref_g` — the journaled event is the CAN-SPAM honored-opt-out evidence; hana's `current_for` returns none → `suppress(no-record)` with `preference_id: none`, per this deployment's declared policy. Neither receives a Notification record; both non-deliveries are classified, distinct, and queryable — the difference between *they said no* and *they never said* is preserved in the records.

### Rejection paths

- `fanout_shaped("", {task_id: t9})` → `rejected(invalid-request)` — nothing generated, queried, or written.
- `fanout_shaped("task:assigned", null)` → `rejected(invalid-request)`.
- Subscription records down at the subscriber query → `rejected(subscribers-unavailable)` — no journal entry, no creates.
- Event Log rejects the `fanout.initiated` append (`storage-failure`) → `rejected(journal-rejected)` — the composition refuses to run an unjournaled fanout; no Notification record exists for the invocation. The same rejection covers a definitive `invalid-payload` (an oversized event_scope); retry distinguishes the two.
- `redispose(fx_01, ana, payload)` when ana's latest disposition under `fx_01` is `fanout.created` and `status_of(notif_91)` returns Pending or Delivered → `rejected(not-retryable)` — one invocation never holds two live deliveries for the same principal (the transport-failure path admits her only once `notif_91` has reached `failed` or `expired`).
- `redispose(fx_07, eli, payload)` whose delivery event Event Log refuses → `rejected(journal-rejected(outcome))` — nothing written, the create with it. `reconcile_gaps(fx_08, payload)` on an invocation whose `fired_at` is five seconds old under the five-second `invocation_duration_bound` and one-second `notification_create_latency` → `rejected(too-young)` — nothing examined, nothing written.
- `redispose(fx_99, cho, payload)` where no `fanout.initiated` entry carries `fx_99` → `rejected(not-known)`; `redispose(fx_01, cho, altered_payload)` where the digest does not match `fx_01`'s journaled `payload_digest` → `rejected(payload-mismatch)` — the retry is bound to the original content.

### Fail-closed gate — preference-record outage

A fanout fires while the Message Preference records are down. For each subscriber, `current_for` fails at the read (an infrastructure failure, not a none): the gate renders no verdict, routes nothing through `no_record_policy`, and the subscriber's disposition is `failed` with cause preference-unreadable — journaled, classified, retry-eligible via [Redispose] once the database recovers. A suspended principal and a quiet-houred principal are *not* delivered to unshaped during the outage; the outage degrades to named failures, never to silent unshaped delivery. The same shape covers [Interpretation Undeclared] (a record carries `quiet_hours` but the deployment never declared the interpretation) and [Accounting Unreadable] (a cap-carrying record whose count cannot be rebuilt because the journal read fails) — each raised at the precedence rule that would consult the missing input (rule iii and rule iv respectively), so a Suspended record carrying either still suppresses as suspended first.

### Partial failure

A fanout `fx_07` to `[ana, eli, fay]`: ana's disposition pair commits (created); eli's `Notification.create` is refused by an infrastructure failure — nothing exists for eli, `fanout.create-failed` is journaled with cause create-failed, eli → `failed`; fay's pair commits (created). Returns all three classified. Had eli's delivery event been refused instead, eli would have been returned in yielded with nothing written, the create with it — a gap the next [Reconcile Gaps] run redisposes. The caller retries eli with `redispose(fx_07, eli, payload)`: the gate re-evaluates (eli's preferences may have changed, the quiet window may now apply — the retry earns delivery, it does not assume it), and the outcome lands in the journal under `fx_07`. A direct `Notification.create(eli, envelope)` is **not** the retry path — it would bypass the gate and produce an unjournaled Notification that breach forensics reads as bypass evidence. A fresh [Fanout Shaped] (a new invocation against the *current* Active set) remains correct when re-fanning the whole scope is the intent — composing [Duplicate Prevention](../atoms/duplicate-prevention.md) if at-most-once across such retries is required.

*Transport failure after a committed create:* back on `fx_01`, ana's `notif_91` later fails in transport (the transport layer calls `Notification.fail`). The re-send also routes through `redispose(fx_01, ana, payload)`: the transport-failure path (Action wiring 46) admits her because `status_of(notif_91)` returns `failed`; the audience re-check and the gate run fresh (if it is now 23:30 in ana's declared quiet hours, the re-send is suppressed — the retry earns delivery under *current* rules); a deliver verdict commits a new create, `notif_95`, as Notification's retry model prescribes — a distinct record with its own outcome, journaled under the invocation, with `notif_91` remaining in Failed as the audit record of the first attempt.

### Regulated adversarial scenarios

- **Regulator audit — "show every message delivered inside a declared quiet window."** A TCPA auditor asks for all deliveries to principals whose in-effect preferences declared a quiet window containing the delivery moment. The procedure is provable: enumerate `fanout.created` events in the audit period (Event Log read, time-ranged); for each, fetch the recorded `preference_id` via `Message Preference.read` (immutable, durable); where the record carries `quiet_hours`, evaluate the deployment's disclosed `quiet_hours_interpretation` against the event's `decided_at`. **By Invariant 3 the result set is empty** — any non-empty result is a conformance violation, and the violating event itself carries the evidence (the verdict's inputs are journaled). The auditor separately samples `fanout.suppressed(quiet-window)` events and replays each verdict (Invariant 7) to confirm the gate was evaluating, not rubber-stamping.
- **Disputed delivery — "I was texted at 3am."** A principal complains of a 3am SMS. The investigator reconstructs from records: the principal's in-effect preference record at the delivery moment (Message Preference's in-effect reconstruction — max `set_at ≤ t` within the in-effect window); the disposition — either a `fanout.created` event whose `decided_at`, `channels`, and `preference_id` show what the gate saw and decided, or no such event (the message did not come through this composition — a finding against the deployment's delivery inventory, not this composition's records). If the record carried no `quiet_hours`, the delivery was conformant *with respect to stated preferences* — and the declared `statutory_quiet_window` is then the operative question: a 3am SMS is inside any TCPA-conformant declaration, so a delivered SMS envelope at 3am indicts the deployment's statutory-window declaration (absent, or wrongly scoped) rather than the gate; the event's `evaluation_inputs` show whether a statutory exclusion was evaluated. If it carried one and the interpretation places 3am inside it, Invariant 3's antecedent is examined: either the gate misfired (replay the verdict — Invariant 7 isolates the divergence) or the deployment's declared clock/timezone capability was unsound (the externally-clearable disclosure names the liable layer). The composition's records identify which.
- **Breach investigation — suppression-bypass forensics.** An incident suggests deliveries bypassed suppression during a window (e.g., a deploy that skipped the gate). The investigator cross-checks, per invocation in the window: the Active subscriber set reconstructed at the `fanout.initiated` entry's `fired_at` (Check 1.4's procedure) versus the disposition events under its fanout_id (Invariant 1 — a delivery with no `fanout.created` event, or a reconstructed subscriber with no disposition past the reconciliation window, is structural evidence of bypass); Notification records created in the window versus `fanout.created` events (a Notification whose creation has no journal pair indicates writes outside the composition); and replay of suppression verdicts near the window's edges (Invariant 7) to confirm verdicts matched the stored preferences. The journal's append-only total order (Event Log Invariant 1 through 4) bounds the affected invocations.

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the four constituent records.

### Conformance checks

```
Check 1.1: An auditor MUST find the latest disposition events under a fanout id partitioning the initiation entry's queried list at quiescence (Invariant 1.1).
Deleted: Check 1.2. Execution Contract Database 1 owns it.
Check 1.3: An auditor MUST read an abandonment record as accounting for the principals the record covers (Reconciliation 22).
Check 1.4: An auditor MUST reconstruct the Active set across the fired instant's reconstruction window AND compare the set with the queried list (Composition state 11).
Check 1.5: An auditor MUST report a queried list diverging from EVERY reconstruction in the window as a fidelity finding (Action wiring 5).
Check 1.6: An auditor MUST find EVERY delivery event's notification id naming a record whose recipient EQUALS the event's principal (Action wiring 22).
Check 2.1: An auditor MUST find EVERY delivery event's observed count below EVERY cap the event records (Invariant 4.1).
Check 2.2: IF the cap serialization EQUALS serialized-per-principal THEN an auditor MUST find EVERY delivery event's observed count derivable from the preceding delivery events in the window (Invariant 4.2).
Deleted: Check 2.3. Execution Contract Database 1 owns it.
Check 2.4: IF the cap serialization EQUALS best-effort THEN an auditor MUST find EVERY overshoot matched by an overshoot record WITHIN the reconciliation window (Invariant 4.3).
Check 3.1: An auditor MUST find EVERY suppression event carrying a suppression reason (Invariant 5.1).
Check 3.2: An auditor MUST find EVERY suppression event's preference id naming a record in effect at the decided instant within the clock tolerance (Composition state 15).
Check 3.3: An auditor MUST find EVERY failure event carrying a failure cause (Invariant 5.2).
Check 3.4: An auditor MUST find EVERY delivery event carrying the gate's evaluation inputs (Action wiring 31).
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Check 4.1: An auditor MUST find EVERY disposition event's fanout id naming EXACTLY ONE initiation entry (Invariant 10.1).
Deleted: Check 4.2. Execution Contract Database 1 owns it.
Check 4.3: IF a redisposition event is the pair's first disposition event THEN an auditor MUST find the principal in the queried list (Action wiring 47).
Check 5.1: An auditor MUST replay a sample of verdict-bearing events AND find EVERY recorded verdict reproduced (Invariant 7.1).
Check 6.1: An auditor MUST find EVERY created record's envelope content digesting to the initiation entry's payload digest (Invariant 8.1).
```

NOTE: EVERY check names the rule the check tests.

Term reconstruction window: from `(fired instant - clock tolerance)` to `((fired instant + max query latency) + clock tolerance)`, the tolerance's write-clock component.

### External checks

```
External check 1: An auditor needing the interpretation AND policy disclosures confirmed MUST read the deployment's disclosure of EVERY Capability requirement setting AND EVERY retained configuration version (Capability requirement 9).
External check 2: An auditor needing the reconciliation discipline confirmed MUST read the scheduler's calls of [Reconcile Gaps] AND [Reconcile Overshoots] (Reconciliation 1).
External check 3: An auditor needing the journal's capability confirmed MUST read the deployed Event Log instance's predicates (Capability requirement 19).
External check 4: An auditor needing single-pipeline routing confirmed MUST read the deployment's attestation (Non-goal 5).
External check 5: An auditor needing the recipient-local clock confirmed MUST read the deployment's attestation (Invariant 3.1).
External check 6: An auditor needing the unified principal namespace confirmed MUST read the deployment's canonicalization attestation (Primitive policy 7).
External check 7: An auditor needing payload retention confirmed MUST read the deployment's retention of payload content by fanout id (Payload retention 1).
External check 8: An auditor needing peer-pattern wiring confirmed MUST read the deployment's wiring of Consent, Audit Trail AND Duplicate Prevention (Non-goal 1).
```

---

## Non-goals

```
Non-goal 1: The composition MUST NOT evaluate legal permission.
Non-goal 2: A deployment needing lawful basis MUST gate [Fanout Shaped] on Consent.
Non-goal 3: The composition MUST NOT queue a held suppression.
Non-goal 4: The composition MUST NOT attribute an invocation's initiator.
Non-goal 5: A deployment under a covered obligation MUST route EVERY covered delivery through the shaping gate.
Non-goal 6: The composition MUST NOT dispatch a Notification.
Non-goal 7: The composition MUST NOT gate an action on authorization.
Non-goal 8: The composition MUST NOT read an event scope as a hierarchy.
Non-goal 9: The composition MUST NOT order the creates of one invocation.
Non-goal 10: The composition MUST NOT journal payload content.
Non-goal 11: A deployment needing content in a sealed journal MUST compose Audit Trail.
Non-goal 12: A deployment needing at-most-once across a wholesale re-fanout MUST compose Duplicate Prevention.
```

Term covered obligation: a quiet-window obligation or a frequency obligation the deployment's regime imposes.

NOTE: the owners — the deployment's scheduler (Non-goal 3); the deployment (Non-goal 5, External check 4); the transport (Non-goal 6); a composing [Permissions](../atoms/permissions.md) layer (Non-goal 7); [Audit Trail](./audit-trail.md) (Non-goal 10, Non-goal 11).

---

## Edge cases

### Clock semantics

```
Clock semantics 1: A deployment MUST own the recipient-local soundness of the injected now.
Clock semantics 2: A deployment needing a mid-invocation window change honoured MUST re-check the window at the transport ahead of dispatch.
```

### Concurrency

```
Concurrency 1: A [Redispose] deliver MUST hold the per-disposition exclusion AND the per-principal exclusion alike.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Concurrency 3: The composition MUST NOT roll back one subscriber's disposition for another's failure.
```

### Payload retention

```
Payload retention 1: A deployment MUST retain payload content by fanout id through the later of the reconciliation window AND the hold retry horizon.
Payload retention 2: IF an invocation's payload content is unavailable to the deployment THEN the deployment MUST call [Reconcile Gaps] with no payload content.
```

### Per-channel caps

```
Per-channel caps 1: A deployment encoding a per-channel cap MUST express the cap as a channel-scoped pair in the frequency limit interpretation.
```

### Staleness

```
Staleness 1: The shaping gate MUST evaluate the record the preference read answered at the gate's read.
Staleness 2: An admitted redisposition MUST re-verify the audience AND re-read the preference record.
```

---

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is*, in plain English, and its **Kind**, and — for a Field, a Parameter or a wire Member — carries the one **Projection** line where the concrete name stays visible on the page. The composition's own concepts are the four actions it exposes and the pure gate they run, the invocation's id and two of the gate's journaled data, the closed suppression reasons, the closed fail-closed causes, and its own refusals. The trichotomy, quiet-window and cap safety, no silent disposition and replayability are structural properties, not data. The deployment settings keep their wire spellings in configuration — `quiet_hours_interpretation`, `frequency_limit_interpretation`, `channel_interpretation`, `no_record_policy`, `cap_policy`, `quiet_window_policy`, `cap_serialization`, `journal_query_capability`, `payload_digest_function`, `reconciliation_window`, `reconciliation_cadence`, `notification_create_latency`, `disposition_write_latency`, `max_query_latency`, `abandonment_principals_cap`, `invocation_duration_bound`, `hold_retry_horizon`, `statutory_quiet_window`, `clock_tolerance` — and the two indexes theirs in an implementation, `delivery_count_index` and `fanout_dispositions`; the page names each in English where it declares it. *(annotation.md Terms registry; representational only — it changes no guarantee, invariant, or behavior of the composition above.)*

### Vocabulary

Term actors: the composition; the constituents; the host; the transport; the shaping gate; the reconciliation; the replay; the deployment's scheduler; a deployment; an auditor; a principal; a subscriber; a recipient; an investigator; an invocation; an action; a validated fanout; an initiated fanout; a validated redisposition; an admitted redisposition; a gap run; an overshoot run; a holder; a foreign holder; a writer.

Term records: the initiation entries, disposition events and reconciliation records the composition appends to the journal — each an Event Log event carrying one event type below — and the index entries.

Term record verbs: abandon, abort, admit, answer, appear, attribute, bind, call, carry, change, commit, compare, compose, count, declare, disclose, dispatch, dispose, evaluate, exclude, express, fail, fall, find, gate, hold, inherit, inject, interpret, journal, key, land, make, map, name, normalize, order, own, partition, place, queue, re-check, re-render, re-verify, read, rebuild, receive, reconstruct, record, refuse, register, release, remove, reorder, repair, replay, report, reproduce, resolve, retain, roll, route, run, serve, set, size, skip, stamp, start, stop, store, supply, take, version, withdraw, write.

Term value sets: event type = fanout.initiated | fanout.created | fanout.suppressed | fanout.create-failed | fanout.reconcile-intended | fanout.abandoned | fanout.cap-overshoot-reconciled. The rest are declared where the section that owns each declares it: verdict, suppression reason, fail-closed cause, failure cause, action-relented reason, abandonment reason, observed record status, interpreted field, no record policy, cap policy, quiet window policy, cap serialization, redispose position, gap position.

Term bounds: reconciliation window (reconciliation_window), invocation duration bound (invocation_duration_bound), hold retry horizon (hold_retry_horizon), notification create latency (notification_create_latency), disposition write latency (disposition_write_latency), max query latency (max_query_latency), abandonment principals cap (abandonment_principals_cap), clock tolerance (clock_tolerance), audit horizon.

Term cadences: reconciliation cadence (reconciliation_cadence).

Term qualifiers: migrated — rewritten in GRACE lang v0.61 (2026-09-23).

Term terms: composition, constituents, journal, delivery count index, delivery count entry, fanout dispositions index, interpreted frequency window, disposition pair, queried subscriber, quiescence, quiet hours interpretation, frequency limit interpretation, channel interpretation, default shape, configuration version, no record policy, cap policy, quiet window policy, cap serialization, per-principal exclusion, journal query capability, payload digest function, reconciliation window, reconciliation cadence, notification create latency, disposition write latency, max query latency, abandonment principals cap, invocation duration bound, clock tolerance, liveness sum, hold retry horizon, per-disposition exclusion, statutory quiet window, audit horizon, seam, now, fanout result, redisposition, redispose position, carried by [Redispose]'s journal-rejected, gap result, gap position, carried by [Reconcile Gaps]'s journal-rejected, overshoot result, subscriber query, preference read, status read, validated fanout, initiated fanout, validated redisposition, admitted redisposition, queried list, initiation entry, delivery event, suppression event, failure event, disposition event, envelope, delivery pair, delivery history, reason's policy, action-relented reason, retryable disposition, redisposition flag, observed record status, reconciliation, gap run, overshoot run, young invocation, aged entry, aged instant, gap principal, reconcile intent, abandonment record, abandonment reason, overshoot record, shaping gate, verdict, precedence rules, suppression reason, fail-closed cause, failure cause, interpreted field, verdict-bearing event, live record, reconstruction window, covered obligation, fanout id, payload content, payload digest, fired instant, decided instant, evaluation inputs, retry eligibility.

Term cited: Execution Contract Conformance 8 — the recursive inheritance of a constituent's guarantees. The section titled Composition state in `execution-contract.md` — the derived-index classification. The section titled Composition model in `execution-contract.md` — Event Log as the sanctioned history records. The section titled Logic Confinement Principle in `execution-contract.md` — the seam. subscribers_for, subscribed, not-subscribed, subscriber reference, event scope: Subscription. create, status_of, pending_for, notification id, payload, Pending, Delivered, failed, expired: Notification. current_for, read, preference id, principal reference, preference record, channel preferences, frequency limit, quiet hours, format, metadata, status, suspended: Message Preference. append, recording instant, payload cap, invalid-payload, storage-failure: Event Log.

Term composing patterns: [Notification Fanout](./notification-fanout.md); [Consent](../atoms/consent.md); [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md); [Audit Trail](./audit-trail.md); [Actor Identity](../atoms/actor-identity.md); [Permissions](../atoms/permissions.md); [Duplicate Prevention](../atoms/duplicate-prevention.md); [Reserve from Pool](./reserve-from-pool.md).

Term fanout id: the invocation's opaque, invocation-unique id — a [Fanout Id].

Term payload content: the opaque content a [Fanout Shaped] call carries, wrapped per recipient in an envelope.

Term payload digest: the payload digest function's digest of the payload content, journaled on the initiation entry.

Term fired instant: the invocation's now, stamped on the initiation entry.

Term decided instant: the now stamped on a disposition event or reconciliation record.

Term evaluation inputs: what the gate observed — an [Evaluation Inputs].

Term retry eligibility: whether a suppression may be retried as time passes — a [Retry Eligible].

#### Fanout Shaped

The composition's core action: fire an event to everyone subscribed, shaping each delivery by the recipient's in-effect preferences. It queries the Active subscriber set, journals the invocation, and for each subscriber runs [Shaping Disposition] between the query and the create, so every subscriber gets exactly one recorded disposition — delivered, failed, or suppressed — or, at the invocation's terminus, is left to [Reconcile Gaps]; a subscriber whose preference read fails is failed with [Preference Unreadable] before the gate runs. Returns `{fanout_id, created, failed, suppressed, yielded}` or a rejection — [Journal Rejected] where Event Log refuses the initiation entry.

Kind: Operation

#### Redispose

The journaled, gate-evaluated retry surface for a single principal of a prior invocation — the only conformant recovery path (a failed delivery, a hold-marked suppression whose window relented, a crash-gap subscriber). It re-verifies the audience, re-runs [Shaping Disposition] with fresh inputs, and journals the outcome under the original [Fanout Id]; a direct `Notification.create` would bypass the gate and is branded bypass. Refuses [Yielded] where a foreign holder holds the pair's exclusion or the lease expires ahead of the commit.

Kind: Operation

#### Reconcile Gaps

The composition-introduced reconciliation surface that resolves an invocation's journal gap, examining only invocations older than the invocation duration bound plus the create latency and inside the journal's retention horizon: it writes its `fanout.reconcile-intended` record first, then for each subscriber in the journaled `queried` list with no disposition event — under the per-disposition section — re-disposes through [Redispose], and closes any residue with a terminal `fanout.abandoned` record. Owns the intent and abandonment writes; carries no composition state (the records live in Event Log). Refuses [Too Young] for an invocation younger than the invocation duration bound plus the create latency.

Kind: Operation

#### Reconcile Overshoots

The composition-introduced reconciliation surface that discharges the best-effort frequency-cap liveness arm: it scans a principal's delivery events under each journaled configuration's interpreted windows and appends a `fanout.cap-overshoot-reconciled` record for any window whose committed count exceeded its contemporaneous cap. Idempotent; owns the overshoot write; carries no composition state.

Kind: Operation

#### Shaping Disposition

The composition-introduced **pure gate** every disposition runs — evaluated once per subscriber per disposition, structurally between the subscriber query and each create so no create can bypass it. It reads the in-effect preference record, the injected now, the recent delivery history, and the interpretation rules, and renders one verdict by fixed precedence: deliver, suppress (with one of the six reasons), or fail-closed. Its purity is what makes replay (Invariant 7) checkable.

Kind: Operation

#### Fanout Id

The opaque, system-generated, invocation-unique correlation handle that binds an invocation's journal entries together. Generated at the start of [Fanout Shaped], journaled in the `fanout.initiated` entry before any disposition commits, and carried on every disposition event; [Redispose] appends under the original one.

Kind:       Field
Field of:   the fanout result and every disposition event
Role:       the invocation correlation handle
Projection: fanout_id

#### Retry Eligible

The boolean the composition records on every `fanout.suppressed` event marking whether the suppression may be retried after time passes: [Quiet Window] and [Frequency Cap] carry the deployment's hold / drop policy; [Suspended], [No Record], [Channel Opt Out], and [Unsubscribed] are always false (they relent only by the principal's own action, not time).

Kind:       Field
Field of:   the suppression event
Role:       the time-relents retry marker
Projection: retry_eligible

#### Evaluation Inputs

The record of what the gate observed at disposition time — the observed record status, the injected now, and (for a cap verdict) the interpreted `(window, cap)` pairs and in-window counts — journaled on both `fanout.created` and `fanout.suppressed` events. It is what makes a verdict replayable (Invariant 7) and a best-effort overshoot diagnosable, because it captures the mutable and ephemeral inputs a later re-read cannot recover.

Kind:       Field
Field of:   the disposition event
Role:       the recorded gate observation
Projection: evaluation_inputs

#### Suspended

The [Shaping Disposition] verdict (precedence rule i) when the in-effect preference record's status is suspended — the subscriber is suppressed even though their Subscription is Active, which is what makes Message Preference's pause operative. Consults no count or interpretation, so it wins even during an Event Log outage.

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: suspended

#### Quiet Window

The [Shaping Disposition] verdict (rule iii, and the statutory arm of rule v) when the injected now falls inside the recipient's stored `quiet_hours`, or inside a declared `statutory_quiet_window` for the delivering channel. The structural mechanism of quiet-window safety (Invariant 3, the TCPA arm).

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: quiet-window

#### Frequency Cap

The [Shaping Disposition] verdict (rule iv) when the in-window count of a principal's delivery history has reached an interpreted `(window, cap)` pair. The structural mechanism of frequency-cap safety (Invariant 4, the TCPA frequency arm).

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: frequency-cap

#### No Record

The [Shaping Disposition] verdict (rule ii) when `Message Preference.current_for` returns none and the deployment's `no_record_policy` is suppress — distinct from a delivery on the deliver-unshaped path, and distinct in the records from a stated opt-out (*they never said* versus *they said no*).

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: no-record

#### Channel Opt Out

The [Shaping Disposition] verdict (rule v) when interpreting the record's `channel_preferences` yields an empty deliverable set — the enforcement point for honored opt-outs (Invariant 3 / CAN-SPAM). The journaled event is the honored-opt-out evidence.

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: channel-opt-out

#### Unsubscribed

The suppression reason [Redispose] alone produces, from its audience re-check: a principal who left the audience (`Subscription.subscribed` returns not-subscribed) between the original invocation and a later retry. Deliberately excluded from Invariant 2's "even though Active" scope, because it is not a gate verdict against an Active subscriber.

Kind:       Member
Member of:  the suppression reason
Role:       Suppression reason
Projection: unsubscribed

#### Preference Unreadable

The pre-gate fail-closed cause: a failed Message Preference *read* (infrastructure failure, distinct from a successful none) raised by the orchestration before [Shaping Disposition] runs, since the record gates every rule. A preference-record outage degrades to this named failure — never a silent unshaped deliver to a suspended or quiet-houred principal.

Kind:       Member
Member of:  the delivery-failure cause
Role:       Fail-closed cause
Projection: preference-unreadable

#### Accounting Unreadable

The in-gate fail-closed cause raised at rule iv when a cap-carrying record's delivery history cannot be rebuilt (the journal read fails) — raised only if no higher-precedence rule already suppressed, so a [Suspended] record still suppresses first.

Kind:       Member
Member of:  the delivery-failure cause
Role:       Fail-closed cause
Projection: accounting-unreadable

#### Interpretation Undeclared

The in-gate fail-closed cause raised at the precedence rule (iii / iv / v) that would consult a preference field whose interpretation the deployment never declared — never a silent deliver past an unevaluable value, never a suppression reason claiming an evaluation that did not happen.

Kind:       Member
Member of:  the delivery-failure cause
Role:       Fail-closed cause
Projection: interpretation-undeclared

#### Journal Rejected

The composition's own invocation-level rejection when the `fanout.initiated` append (or a [Redispose] disposition append) is refused by Event Log — the composition does not run an unjournaled fanout, because every downstream guarantee reads from the journal. Covers both the retryable `storage-failure` and the definitive `invalid-payload` append outcomes under one name; on [Redispose] and [Reconcile Gaps] it carries the position — the redispose position and the gap position.

Kind:       Member
Member of:  the fanout rejection
Role:       Rejection
Projection: journal-rejected

#### Yielded

The rejection [Redispose] returns when its per-disposition lease expired before its disposition committed: the call wrote nothing after the expiry, and the principal is [Reconcile Gaps]'s. It is also what a [Redispose] returns when a foreign holder — a live [Fanout Shaped], or [Reconcile Gaps] — holds the pair's section: the call does not wait. Its batch counterpart is [Fanout Shaped]'s yielded list — the subscribers an invocation left undisposed.

Kind:       Member
Member of:  the redispose rejection
Role:       Rejection
Projection: yielded

#### Too Young

The rejection [Reconcile Gaps] returns for an invocation whose `fired_at` is younger than `invocation_duration_bound + notification_create_latency`: the invocation may still be in its loop, its undisposed subscribers are work in flight rather than gaps, and the leg examines nothing and writes nothing.

Kind:       Member
Member of:  the reconcile-gaps rejection
Role:       Rejection
Projection: too-young

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Fanout Shaped]: #fanout-shaped
[Redispose]: #redispose
[Reconcile Gaps]: #reconcile-gaps
[Reconcile Overshoots]: #reconcile-overshoots
[Shaping Disposition]: #shaping-disposition
[Fanout Id]: #fanout-id
[Retry Eligible]: #retry-eligible
[Evaluation Inputs]: #evaluation-inputs
[Suspended]: #suspended
[Quiet Window]: #quiet-window
[Frequency Cap]: #frequency-cap
[No Record]: #no-record
[Channel Opt Out]: #channel-opt-out
[Unsubscribed]: #unsubscribed
[Preference Unreadable]: #preference-unreadable
[Accounting Unreadable]: #accounting-unreadable
[Interpretation Undeclared]: #interpretation-undeclared
[Journal Rejected]: #journal-rejected
[Yielded]: #yielded
[Too Young]: #too-young

---


## Standards references

- **TCPA — Telephone Consumer Protection Act (47 U.S.C. section 227) and 47 CFR section 64.1200(c)(1)** — restricts calls and texts outside permitted hours (the Federal Communications Commission's implementing rule presumes no solicitations before 8am or after 9pm recipient-local time) and underwrites per-message statutory damages. Invariant 3 (quiet-window safety) is the structural mechanism: the gate evaluates the recipient's stored quiet window in recipient-local time before any create, and the suppression record is the affirmative evidence of compliance. The statutory 8am–9pm presumption applies whether or not the principal stored a window, which is why the gate carries the `statutory_quiet_window` arm (Configuration) alongside the stored-preference arm — Invariant 3 covers both. Three obligations this composition names but does not itself discharge: the recipient-local clock capability, the prior-express-consent requirement (the Consent peer's), and the single-pipeline routing obligation — the invariants cover only deliveries routed through the gate, so the deployment must route every TCPA-covered delivery through it and must declare the statutory window for the covered channels (Edge cases; externally-clearable disclosures).
- **CAN-SPAM Act (15 U.S.C. section 7701 et seq., esp. section 7704)** — commercial email senders must honor opt-outs. The channel-opt-out suppression (an `email: "opt-out"` channel preference yielding an empty deliverable set or excluding the channel) is the enforcement point; Message Preference's immutable records plus the suppression journal produce the audit trail CAN-SPAM enforcement requires. The 10-business-day honoring window is a deployment obligation on preference-change-to-enforcement latency, met structurally here because the gate reads the in-effect record at every disposition.
- **GDPR (the EU General Data Protection Regulation) Article 7(3)** — withdrawal of consent must be as easy as giving it. The Article 7(3) obligation proper belongs to the Consent atom and the Propagate Consent Revocation Downstream composition (Message Preference's own Standards references draw this line). This composition's contribution is the enforcement-latency half of the ease story: a withdrawal or preference change recorded upstream is honored at the *next disposition evaluation* — there is no cached permission to invalidate, because the gate reads `current_for` fresh per invocation.
- **GDPR Article 21(2)** — the right to object to direct-marketing processing. Per Message Preference's Standards references, the objection's delivery-shaping signal lives in the preference record and the legal-permission revocation in Consent; this composition is the named enforcement point for the first half — the recorded opt-out becomes a suppression at the next evaluation.
- **CASL (Canadian Anti-Spam Legislation)** and the **ePrivacy Directive (2002/58/EC)** — inherited through Message Preference's standards surface; the same gate is the enforcement point.

It inherits from: **[Subscription](../atoms/subscription.md)** (Observer, pub-sub, WebSub), **[Notification](../atoms/notification.md)** (SMTP — Simple Mail Transfer Protocol — disposition mapping, webhooks, the Apple and Google push services), **[Message Preference](../atoms/message-preference.md)** (CAN-SPAM, TCPA, GDPR 7(3)/21(2), CASL, ePrivacy), **[Event Log](../atoms/event-log.md)** (append-only journaling), and the **Outbox pattern** via [Notification Fanout](./notification-fanout.md)'s framing — the shaped Notification records are the outbox the transport consumes.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: pending — re-derivation, 2026-08-30: the invocation and [Reconcile Gaps] are now two processes over one disposition under a per-disposition section whose lease is the invocation's terminus, the deliver pair is ordered rather than atomic with an adoptable orphan, and the gap leg is age-bounded, none of which the model carries; was verified — preference-aware-notification-fanout.tla + 1 twin, 2026-06-12
last gate: 2026-06-12 — Final Critique 12, fresh reader — clean

open:
- 2026-08-30-d · refining · formal · the model has no [Reconcile Gaps] leg as a second process over one disposition, no per-disposition section with a lease terminus, and no age-bounded leg → extend it
```

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- compositions/preference-aware-notification-fanout.md`; the migration that got it here is in [its history](./preference-aware-notification-fanout.hist.md).

- **2026-10-21 — The store's guarantees cited, not restated, the deliver-pair orphan and its adoption among them.** *Chose:* Capability requirement 47 citing Execution Contract Store 1 through 4 for the store the four constituents keep their records in; to Store 1, under which one subscriber's disposition — its create and its delivery event — commits together, the machinery that existed only because a create could land without its journal half: the orphan lookup, [Redispose]'s selection of a pending record carrying the fanout id with its orphan-pending refusal, the caller's bar on calling [Redispose] again after a journal-rejected that carried a notification id, the gap run's selection, adoption and ambiguous-candidate abandonment with its refused adoption, and the auditor's checks of adoptions (Capability requirement 40, Action wiring 49 through 51, 57, Reconciliation 12 through 16, 27, Check 1.2, 2.3, 3.5, 4.2); to Store 2, under which an action's guard reads and the writes they decide are one transaction, the bars on reading a preference record or checking retryability before taking the per-disposition exclusion, the exclusion's span over a [Redispose]'s status read and create, and the scheduler's one overshoot run per principal with the existence read under it (Action wiring 9, 41, Concurrency 2, Reconciliation 33, 34). By clause, the gap run's [Redispose] call loses its zero-candidate condition, an abandonment record its candidates and a refused append the adoptions it left standing (Reconciliation 17, 22, 29); Check 3.4 reads every delivery event; External check 3 confirms the journal's predicates alone, its durability being Store 3's and Store 4's; [Redispose] no longer refuses orphan-pending, the redispose position carries no notification id, the gap position no adoption and the abandonment reason no candidates-ambiguous. Rules 274 to 255. *Over:* a delivery pair ordered rather than atomic, whose create could stand without its journal half until the gap leg adopted it — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a fan-out's create for each recipient is its own action, and that Store 2 covers a guard decided across a lease check. One subscriber's disposition is that action, so a refused delivery event leaves the subscriber yielded with nothing written, and no orphan is left to adopt. What the page does for its domain is unchanged. The dispositions of one invocation stay separate actions, so a crash between two of them still leaves a gap, and the gap leg — its restart run, its intent, its lower edge, its redisposition and its abandonment — stays. The per-principal exclusion stays, since the cap reads the delivery count index, a derived index outside the action's transaction (obligation 2 of the section titled Composition state in `execution-contract.md`). The per-disposition exclusion stays with its lease, which is the holder's terminus: it bounds how stale the one now is for a late-loop subscriber, on which Invariant 3 rests, and keeps a live loop inside the gap leg's lower edge, which the store does not do.
- **2026-08-30 — The deliver pair is ordered, not atomic; one writer per disposition under a declared section; the gap leg bounded at both edges and writing its intent first.** *Chose:* `Notification.create` then `EventLog.append`, with the reachable partial named — a Pending record carrying the fanout_id in its envelope and no `fanout.created` — and adopted by [Reconcile Gaps] under `recovery: true` through the declared `pending_for` read, with `orphan_lookup` as the optional capability that reaches an orphan in any status; a per-disposition section keyed by `(fanout_id, principal_ref)`, declared as an instance capability requirement with lease semantics, held by [Fanout Shaped], [Redispose], and [Reconcile Gaps] alike, its expiry the holder's terminus (yielded on the batch result, `rejected(yielded)` on [Redispose]); [Reconcile Gaps] examining nothing younger than `invocation_duration_bound` (`rejected(too-young)`) and nothing past the journal's retention horizon, writing `fanout.reconcile-intended` before any repair, and abandoning under the section at most `abandonment_principals_cap` principals per record; `journal-rejected(read | outcome(notification_id | none))` and `journal-rejected(intent | abandonment)` carrying the position; the three-term liveness inequality with `reconciliation_cadence` and `disposition_write_latency`, checked at start; `max_query_latency` widening Check 1's window; the largest writable record sized, not only the intent. *Over:* a pair claimed to land together or not at all over two writes both constituents declare un-withdrawable, and a gap leg that read "a Notification without a journal pair cannot exist" as licence to redispose; a bare host-conformance serialization that ordered the invocation's write after the leg's instead of preventing it; a leg with no lower edge that read a loop still running as a crash; one bare token on both sides of the create. *Because:* an append-only journal and a never-deleted record cannot be enlisted in one transaction, so the honest claim is order plus a named partial plus its repair; two writers over one disposition land two live notifications for one principal, which Invariant 9 exists to forbid; a leg that corrects work in flight is a wrong act, not a wrong report; and a caller who cannot tell read from outcome re-runs a committed create (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Liveness is arithmetic*, *An outcome is sized before the intent*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* — with §*A reconciliation is bounded at both ends*, §*Recovery commits under a declared service identity*, and §*Durability boundaries*). *The same day's closure check moved four more things:* the lease is mandated rather than optional (a section that cannot expire is not a conforming section) and is reentrant for its holder alone, so [Reconcile Gaps] calls [Redispose] as the holder and a foreign-held pair refuses with yielded; adoption is the leg's alone — a caller's [Redispose] that finds an orphan returns `rejected(orphan-pending(notification_id))` and writes nothing; the leg's lower edge is `invocation_duration_bound + notification_create_latency`, because a create issued at the lease's last instant is still landing when a `pending_for` read at the bare bound would miss it; and the leg's arms are closed — `payload_content | none` and `abandon: true` as declared arguments, `rejected(reason)` entries carried to the next run rather than abandoned, `journal-rejected(intent | adoption(notification_id) | abandonment)`, and `fanout.abandoned.reason` enumerated.
- **2026-06-11 — Delivery frequency accounting is a rule inside the shaping disposition, not an extracted concept.** *Chose:* the frequency-cap verdict is a pure function over Event Log's delivery history and the injected clock, evaluated inside `shaping_disposition`. *Over:* a Delivery Frequency Accounting atom. *Because:* it has no state machine of its own, no freestanding surface to compose, and another pattern would reinvent one Event Log read, not a concept.

</details>

NOTE: End of Preference-Aware Notification Fanout.

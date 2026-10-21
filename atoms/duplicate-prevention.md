---
title: Duplicate Prevention
parent: Atomic Concepts
has_toc: true
toc: true
---

# Duplicate Prevention

<details markdown="block">
<summary>Table of contents</summary>
{: .text-delta }
1. TOC
{:toc}
</details>

## Summary

Duplicate Prevention gives a system a short-term memory of things it has recently seen, so it can spot repeats. The way it works is simple. When something happens (an item is removed, a request is processed), the system records that identity; before accepting a new one, it checks whether that identity was recorded within a set time window. If it was, the check reports "seen" and the system can decide what to do — reject the repeat, ignore it, or return the earlier result. Once the window has passed, the same identity is fresh again. The pattern itself stays out of that decision and out of how identities are compared — those belong to the system using it — which is why the same mechanism works for a to-do list (a one-day window blocks accidental re-adds), a payment system (a few-minute window stops a retried charge from billing twice), a comment box (a one-minute window stops double-click double-posts), and a signup form. One firm guarantee: recording the same identity again does not push the window forward, so a flurry of repeats cannot extend the block indefinitely — the clock starts at the first sighting and runs out at a fixed time.

*Also known as: temporal idempotency, recency guard, cooldown window.*

---

## Intent

WHY:
Every system that accepts input from a person or another system meets the same class of problem: the double-submit, the rapid re-add, the replayed message, the retried charge, the double-posted comment, the redundant sign-up. The shape is constant — an action carries an identity, the action should be rejected, de-duplicated or replayed if that identity was seen recently, and *recently* is a wall-time window. The atom is that mechanic and nothing more: it remembers an identity for a bounded term and answers whether the identity is still under guard. It does not compare identities, does not decide what a repeat means, and does not act. The same literature names it three times — *idempotency window* in distributed systems, *cooldown* in user experience, *replay protection* in security — and the concept underneath is one concept.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a guarded entry by the identity.
Identity 2: The atom MUST treat an identity as opaque.
Identity 3: The atom MUST NOT interpret an identity.
Identity 4: The atom MUST NOT normalize an identity.
Identity 5: The containing pattern MUST supply the matching rule.
```

Term identity: the opaque value a containing pattern asks the atom to remember and recognize — an [Identity].

Term matching rule: the containing pattern's rule for judging two identities the same — string equality, case-insensitive, trimmed, normalized, hashed.

### State

```
State 1: The host MUST hold EXACTLY ONE recording instant per guarded identity.
State 2: The host MUST derive under guard from the elapsed term at the moment a question is asked.
State 3: The atom MUST NOT hold state beyond the recorded set.
```

Term recorded set: the identities under guard, each held with the identity's recording instant — the [Recorded Set].

Term recording instant: the instant an identity was placed under guard, stamped from the injected now — a [Recording Instant].

Term window duration: the length a containing pattern chooses for a guard — a [Window Duration]; the value the elapsed term is measured against. The [Window] the length sizes is the interval, and carries no separate name in a rule.

Term elapsed term: `now − recorded_at`.

Term under guard: an identity in the recorded set whose elapsed term is less than window duration — the state [Check] answers seen for.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 4.
```

### Operations

```
record(identity)
  answers ok

check(identity)
  answers seen | not-seen
```

```
Operation 1: [Record] MUST place an identity that is not under guard under guard.
Operation 2: [Record] MUST stamp recording instant from the injected now.
Operation 3: [Record] MUST answer ok.
Operation 4: [Record] MUST NOT refuse.
Operation 5: [Check] MUST answer EXACTLY ONE OF seen, not-seen.
Operation 6: [Check] MUST answer seen for an identity under guard.
Operation 7: [Check] MUST answer not-seen for an identity that is not under guard.
Deleted: Operation 8. Capability requirement 1 owns it.
Deleted: Operation 9. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 10. Execution Contract Logic confinement 3 owns it.
Operation 11: The containing pattern MUST supply window duration.
Operation 12: The containing pattern MUST own the response to an answer.
```

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Record] | no | ok | enters under guard, recording instant from the injected now (Operation 1, Operation 2) |
| [Record] | yes | ok | unchanged — the original recording instant stands (Invariant 2.1, Invariant 2.2) |
| [Check] | yes | [Seen] | none — the call reads (Operation 6, Invariant 3.1) |
| [Check] | no | [Not Seen] | none — the call reads (Operation 7, Invariant 3.1) |

A failed database write sits outside the table: [Record] still answers ok, and the guard is missed rather than refused (Record failure 1 through 3).

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the atom's evaluation of one call against the recorded set, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading here.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

### Invariants

- **Invariant 2 — Single-recording.**
  ```
  Invariant 2.1: [Record] MUST NOT extend the guard of an identity under guard.
  Invariant 2.2: [Record] MUST preserve the recording instant of an identity under guard.
  Invariant 2.3: [Record] MUST open a fresh guard for an identity that is not under guard.
  Deleted: Invariant 1. Operation 6 and Operation 7 own it.
  ```
- **Invariant 3 — Idempotency of check.**
  ```
  Invariant 3.1: [Check] MUST NOT alter the recorded set.
  Invariant 3.2: Two checks of one identity under one now MUST answer alike.
  ```
- **Invariant 4 — Eventual expiry.** NOTE: watch the modal's temporal scope — Invariant 4.1 reads as safety (*always dropped*) and is meant as liveness (*eventually dropped*), the reading Lazy expiry 1 and Lazy expiry 2 license, and the only word carrying the distinction is *Eventual* in this heading. GRACE's MUST has no temporal scope; the docket carries the class (council read 52).
  ```
  Invariant 4.1: The host MUST drop an identity that is not under guard from the recorded set.
  Deleted: Invariant 4.2. Operation 7 owns it.
  ```

## Examples

### Personal Todo (24-hour window)

A user deletes *"buy milk."* Personal Todo calls [Record] with `"buy milk"`. Two hours later, the user attempts to add *"buy milk"* again. Personal Todo calls [Check] with `"buy milk"`, receives [Seen], rejects the add as `duplicate-recent`. Twenty-five hours after the original delete, the user tries again. Personal Todo calls [Check] with `"buy milk"`, receives [Not Seen], accepts the add.

(`duplicate-recent` is shown verbatim by design: it is the **composing pattern's** pinned rejection string — neither this atom's nor Personal Todo's, since neither raises it; it exists only where the two are wired together, and its wire form is frozen because callers switch on the exact string. It is not this atom's Term; when Personal Todo carries a Terms registry it becomes a cross-page reference to that pattern's term entry. Per [`annotation.md`](../working-ideas/annotation.md), a pinned wire literal shown to display its exact form stays backticked — "literal" is a pinned projection, not a kind.)

### Comment double-post protection (60-second window)

A user submits a comment, the page hangs, they click submit again. The comment system calls [Record] with the normalized comment text after the first submission completes. The second click triggers [Check], receives [Seen], rejects the second post. The first comment goes through; the second does not.

### Payment idempotency (5-minute window)

A payment processor receives a charge request with an idempotency key. It calls [Check] with the key, receives [Not Seen], processes the charge, calls [Record] with the key and the response cached against it. A retry within five minutes triggers [Check] with the key, receives [Seen], returns the previously-cached result without re-processing.

### Newsletter double-subscribe (1-hour window)

A user submits the same email address to a newsletter form twice in quick succession (browser back button, double-click on submit). The first submission processes. Subsequent submissions within the hour trigger [Seen] and are silently absorbed-as-already-subscribed rather than producing duplicate confirmation emails.

The mechanic is identical across all four. What differs: the [Window Duration], the identity-matching rule, and the containing pattern's response on [Seen] (reject, return-cached, silently-absorb).

---

## Generation acceptance

An implementation is acceptable when an external auditor, given the recorded set and the atom's own query surface, can clear the checks below without recourse to source code, runbooks or developer narration. The atom is not regulated and carries no adversarial scenarios; what it carries is a guard other patterns rest correctness on, and this section is where that guard becomes testable rather than asserted.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE recording instant PER identity the recorded set holds (State 1).
Check 1.2: An auditor MUST find an identity's recording instant unchanged across a second record inside the identity's window (Invariant 2.2).
Check 1.3: An auditor MUST find no guard extended by a second record (Invariant 2.1).
Check 1.4: An auditor MUST find a fresh recording instant for a record against an identity that is not under guard (Invariant 2.3).
Check 2.1: An auditor MUST find the recorded set unchanged across a check (Invariant 3.1).
Check 2.2: An auditor MUST find two checks of one identity under one now answering alike (Invariant 3.2).
Check 3.1: An auditor MUST find EVERY check answering EXACTLY ONE OF seen, not-seen (Operation 5).
Check 3.2: An auditor MUST find a check answering seen for an identity under guard (Operation 6).
Check 3.3: An auditor MUST find a check answering not-seen for an identity that is not under guard (Operation 7).
Check 3.4: An auditor MUST find a check answering not-seen for an identity a lazy host still holds (Lazy expiry 3).
Check 4.1: An auditor MUST find EVERY record answering ok (Operation 4).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the window duration confirmed MUST read the containing pattern's own declaration (Operation 11).
External check 2: An auditor needing the matching rule confirmed MUST read the containing pattern's own declaration (Identity 5).
External check 3: An auditor needing a guard miss confirmed MUST read the deployment's own database (Record failure 2).
Deleted: External check 4. Execution Contract Database 3 owns it.
External check 5: An auditor needing the unavailability policy confirmed MUST read the deployment's own declaration (Check unavailability 1).
External check 6: An auditor needing the clock's honesty confirmed MUST read the deployment's own clock discipline (Non-goal 12).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT decide the containing pattern's response to an answer.
Deleted: Non-goal 2. Execution Contract Database 3 owns it.
Deleted: Non-goal 3. Execution Contract Database 3 owns it.
Non-goal 4: The atom MUST NOT reconcile two recorded sets.
Non-goal 5: A pattern needing one guard across every node MUST compose a coordination pattern.
Non-goal 6: The atom MUST NOT retain an identity that is not under guard.
Non-goal 7: A pattern needing long-term history MUST compose an audit pattern.
Non-goal 8: The atom MUST NOT supply the matching rule.
Non-goal 9: A pattern needing a guard that resets on every sighting MUST compose a sliding-window pattern.
Non-goal 10: The atom MUST NOT read a calendar.
Non-goal 11: A pattern needing day-boundary semantics MUST compose a calendar-day pattern.
Non-goal 12: The atom MUST NOT correct clock skew.
Non-goal 13: A pattern needing a strictly monotonic guard MUST compose a logical-clock pattern.
```

NOTE: the owners — the containing pattern (Non-goal 1, Operation 12; Non-goal 8, Identity 5); the deployment (Non-goal 4, Non-goal 5); a Coordination pattern *(forthcoming)* (Non-goal 4, Non-goal 5); an Audit pattern (Non-goal 6, Non-goal 7); Sliding Window *(forthcoming)* (Non-goal 9); a Calendar Day pattern *(forthcoming)* (Non-goal 10, Non-goal 11).

Where the pattern breaks down: when *recent* is measured by something other than wall-time elapsed. Number of intervening events, calendar-day boundaries and business-day boundaries each take a separate concept.

## Edge cases

### Clock semantics

```
Clock semantics 1: The atom MUST anchor a guard to the injected now of the opening record.
Deleted: Clock semantics 2. Non-goal 12 owns it.
Deleted: Clock semantics 3. Non-goal 13 owns it.
```

### Check database unavailability

```
Check unavailability 1: The deployment MUST declare EXACTLY ONE OF fail-open, fail-closed.
Check unavailability 2: A fail-open implementation MUST proceed as not-seen.
Check unavailability 3: A fail-closed implementation MUST proceed as seen.
Check unavailability 4: The atom MUST NOT mandate the policy.
```

### Lazy expiry

```
Lazy expiry 1: A host MAY drop an identity that is not under guard at the moment a question is asked.
Lazy expiry 2: A host MAY drop an identity that is not under guard on a schedule.
Lazy expiry 3: A lazy host MUST answer not-seen for an identity the lazy host still holds.
```

WHY:
The atom claims behaviour and not storage, which is why the two host modes are indistinguishable to a caller: Operation 7 answers not-seen for an identity that is not under guard whether or not the host has physically dropped it, and Lazy expiry 3 says so for the entry a lazy host still holds.

### Record storage failure

```
Record failure 1: [Record] MUST NOT refuse on a failed write.
Record failure 2: The atom MUST treat a failed write as a guard miss.
Record failure 3: The atom MUST NOT treat a failed write as a safety violation.
Deleted: Record failure 4. Execution Contract Database 3 owns it.
```

## Composition notes

Three compositions name this atom: [Idempotent Reservation](../compositions/idempotent-reservation.md), [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) and [Reserve from Pool](../compositions/reserve-from-pool.md). What a containing pattern owes is stated where the atom's operations are — the window duration (Operation 11) and the response to an answer (Operation 12) — and is not restated here.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host (also: a host, a lazy host); the transition; a containing pattern (also: the containing pattern, a pattern); a business caller; an implementation (also: a fail-open implementation, a fail-closed implementation); the deployment (also: a deployment); an identity; a guarded entry; an entry; a check; an auditor.

Term records: recorded set — the identities under guard, one recording instant per entry.

Term record verbs: identify, treat, interpret, normalize, supply, hold, derive, stamp, place, answer, refuse, read, own, stand, extend, preserve, open, drop, alter, decide, survive, reconcile, compose, retain, proceed, mandate, declare, anchor, correct, find.

Term value sets: database policy = fail-open | fail-closed.

Term bounds: window duration (the length a containing pattern chooses for a guard; window is the lowering token the [Window Duration] term entry carries).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); under guard — recorded, and the guard's term not yet elapsed.

Term terms: identity, matching rule, recorded set, recording instant, window duration, elapsed term, under guard, now, transition, seam, business caller.

#### Identity

The value a containing pattern asks Duplicate Prevention to remember and recognize — what counts as "the same thing seen again." The concept treats it as opaque: it stores and compares the value but never interprets it, and how two identities are judged equal is the containing pattern's matching rule, not this atom's.

Kind: Type

#### Window

The bounded interval of time during which a recently-recorded [Identity] is still guarded. It opens when the [Identity] is first recorded and closes after a [Window Duration] the containing pattern sets; once it has elapsed, the same [Identity] is fresh again. (The interval is the concept; the duration value that sizes it is a separate [Window Duration] supplied per containing pattern.)

Kind: Type

#### Recorded Set

The atom's short-term memory: the collection of identities currently under guard, each held together with the time it was recorded. An [Identity] enters on [Record] and leaves automatically once its [Window] has elapsed. It is an internal mechanism, queryable for diagnostics, not a user-facing surface.

Kind:       Type
Projection: recorded

#### Record

The behavior a containing pattern invokes when it has just observed an [Identity] (for example, after removing an item) so that future repeats can be recognized. It places the [Identity] under guard, opening a [Window]. It always succeeds — it never refuses — and recording an [Identity] that is already under guard does not push its [Window] forward.

Kind: Operation

#### Check

The behavior a containing pattern invokes before accepting a new [Identity], to ask whether that [Identity] is currently under guard. It only reads — it changes nothing — and reports its answer as [Seen] or [Not Seen]. What to do with the answer is the containing pattern's decision.

Kind: Operation

#### Seen

The answer [Check] gives when the [Identity] is currently under guard — recorded, and still within its [Window]. It signals "this was observed recently"; the containing pattern decides whether that means reject, de-duplicate, or return an earlier result.

Kind:       Member
Member of:  the Check outcome
Role:       Outcome
Projection: seen

#### Not Seen

The answer [Check] gives when the [Identity] is not currently under guard — either never recorded, or its [Window] has elapsed. It signals "this is fresh"; the containing pattern is clear to proceed.

Kind:       Member
Member of:  the Check outcome
Role:       Outcome
Projection: not-seen

#### Recording Instant

The moment an [Identity] was placed under guard — the per-entry timestamp the guard window is measured from. It is stamped from the injected [Now] on the [Record] that opens the guard, and a [Record] on an already-guarded [Identity] leaves it unchanged (single-recording). It is the only datum the [Recorded Set] carries per entry beyond the [Identity] itself.

Kind:       Field
Field of:   Recorded Set
Projection: recorded_at

#### Window Duration

The length the containing pattern chooses for a [Window] — how long a recently-recorded [Identity] stays guarded. It is supplied by the containing pattern per use (24 hours for a to-do list, minutes for a payment), sizes the [Window] but is not itself part of the concept's state, and is the value the expiry comparison measures [Now] − [Recording Instant] against.

Kind:         Parameter
Parameter of: Record
Projection:   window

#### Now

The current wall-time reading the [Record] and [Check] behaviors evaluate against, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller). [Record] stamps [Recording Instant] from it; [Check] compares it against the [Window] to decide [Seen] versus [Not Seen].

Kind:         Parameter
Parameter of: Check
Projection:   now

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its term entry heading above (kramdown
     auto-generates the heading anchors on GitHub Pages). Standard CommonMark /
     kramdown; no plugin required. -->

[Identity]: #identity
[Window]: #window
[Recorded Set]: #recorded-set
[Record]: #record
[Check]: #check
[Seen]: #seen
[Not Seen]: #not-seen
[Recording Instant]: #recording-instant
[Window Duration]: #window-duration
[Now]: #now

---

## Standards references

Duplicate Prevention is a primitive integrity concept. It has no direct ISO / IEEE / regulatory anchor in this generic form, though specific instantiations have widely-used standards behind them:

- **HTTP (HyperText Transfer Protocol — the request/response protocol of the web) idempotency keys** (IETF (Internet Engineering Task Force — the body that develops internet standards) draft and de-facto convention for safe retry of state-changing requests).
- **Stripe / payment-processor idempotency** (industry-standard pattern for at-most-once charge semantics within a window).
- **Message-queue exactly-once-within-window semantics** (Kafka, SQS (Amazon Simple Queue Service), Pub/Sub deduplication).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a freestanding concept with state, actions, and operational principles, designed for composition rather than absorption.
- **Distributed-systems idempotency literature** — the underlying mechanic appears as "idempotency window" or "exactly-once-within-window semantics" in message-queue and payment-processor designs.
- **Linear temporal logic** (a formal notation for reasoning about sequences of states over time) — the eventual-expiry invariant expressed as a temporal property.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — duplicate-prevention.tla + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/duplicate-prevention.md`; the rounds and the migration that got it here are in [its history](./duplicate-prevention.hist.md).

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 2), and the four rules that set the recorded set's durability tombstoned to Store 3 — Non-goal 2 and Non-goal 3, the recorded set's survival across a restart not required of the atom and left to the deployment, Record failure 4, a durable recorded set where duplicate prevention is safety-critical, and External check 4, the auditor's check of that durability; rules 66 to 63. *Over:* a recorded set whose survival across a restart each deployment chose, a volatile set admitted wherever the guard was not safety-critical. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and that the four Store rules hold for every specification; `execution-contract.md` writes them once as the Store contract, and Store 3 keeps every committed write across a restart. A failed write still answers ok and misses the guard (Record failure 1 through 3), the posture under an unavailable store stays the deployment's to declare (Check unavailability 1 through 4), and the host's drop of an identity that is not under guard stays the atom's own (Invariant 4.1, Lazy expiry 1, Lazy expiry 2). Under guard is derived from the recording instant each entry carries, so the atom cites neither History 1 nor Order 1; what the atom does for its domain is unchanged.

NOTE: End of Duplicate Prevention.

---
title: Duplicate Prevention
id: 38
audience: common
---

# Duplicate Prevention

<details markdown="block">
<summary>Table of contents</summary>
{: .text-xs .font-medium .uppercase .tracking-wide .opacity-50 }
1. TOC
{:toc}
</details>

## What it is

Duplicate Prevention gives a system a short-term memory of things it has recently seen, so it can spot repeats. When something happens (an item is removed, a request is processed), the system records the thing's identity — a value that names it, such as the item's text or the request's key; before accepting a new one, it checks whether that identity was recorded within a set time window. If it was, the check reports "seen" and the system can decide what to do — reject the repeat, ignore it, or return the earlier result. Once the window has passed, the same identity is fresh again. The pattern itself stays out of that decision and out of how identities are compared — those belong to the system using it — which is why the same mechanism works for a to-do list (a one-day window blocks accidental re-adds), a payment system (a few-minute window stops a retried charge from billing twice), a comment box (a one-minute window stops double-click double-posts), and a signup form. One firm guarantee: recording the same identity again does not push the window forward, so a flurry of repeats cannot extend the block indefinitely — the clock starts at the sighting that opened the window and runs out at a fixed time.

*Also known as: temporal idempotency (a repeat inside a stretch of time has no further effect), recency guard, cooldown window.*

<details markdown="block">
<summary>WHY</summary>

Every system that accepts input from a person or another system meets the same class of problem: the double-submit, the rapid re-add, the replayed message, the retried charge, the double-posted comment, the redundant sign-up. The shape is constant: an identity, a wall-time window, and a decision about what a repeat means. The atom leaves that decision, and the comparison of identities, to the containing pattern, because one mechanic serves every one of those problems only if it chooses for none of them. The same literature names it three times — *idempotency window* in distributed systems, *cooldown* in user experience, *replay protection* in security — and the concept underneath is one concept.

</details>

## What it keeps

### The record

Term identity: the opaque value a containing pattern asks the atom to remember and recognize — an [Identity].

#### Identity

What counts as "the same thing seen again." How two identities are judged equal is the containing pattern's matching rule, which it applies before the value reaches this atom.

Kind: Type

```
Identity 1: The atom MUST identify a guarded entry by the identity.
Identity 2: The atom MUST treat an identity as opaque.
Identity 3: The atom MUST NOT interpret an identity.
Identity 4: The atom MUST NOT normalize an identity.
Identity 5: The containing pattern MUST supply the identity to [Record] and [Check] already reduced to the value the matching rule compares by.
```

Term matching rule: the containing pattern's rule for judging two identities the same — string equality, case-insensitive, trimmed, normalized, hashed.

Term recorded set: every identity a [Record] has placed under guard, each held with the identity's recording instant, whether or not the identity is still under guard — the [Recorded Set].

#### Recorded Set

An [Identity] enters on [Record] and stays: once its [Window] has elapsed [Check] answers [Not Seen] for it, but no action of the atom removes its entry. An internal mechanism, not a user-facing surface.

Kind:       Type
Projection: recorded

Term recording instant: the instant an identity was placed under guard, stamped from the injected now — a [Recording Instant].

#### Recording Instant

Stamped from the injected [Now] on the [Record] that opens the guard, and a [Record] on an already-guarded [Identity] leaves it unchanged (single-recording). It is the only datum the [Recorded Set] carries per entry beyond the [Identity] itself.

Kind:       Field
Field of:   Recorded Set
Projection: recorded_at

Term now: the deployment's clock reading at the call, as Execution Contract Logic confinement 11 declares it.

#### Now

Supplied to the pure transition by the host at the I/O seam, never read inside the transition and never supplied by the business caller. [Check] compares it against the [Window] to decide [Seen] versus [Not Seen].

Kind:         Parameter
Parameter of: Record and Check
Projection:   now

Term transition: the atom's evaluation of one call against the recorded set, as Execution Contract Logic confinement 14 declares it.

Term seam: the atom's I/O (input and output) boundary as Execution Contract Logic confinement 14 declares it; the host injects the clock reading here.

Term business caller: the party whose action the call carries, as Execution Contract Logic confinement 14 declares it; never the source of an injected value.

#### Window

The bounded interval of time during which a recently-recorded [Identity] is still guarded. It opens when a [Record] places the [Identity] under guard and closes after a [Window Duration] the containing pattern sets; once it has elapsed, the same [Identity] is fresh again. (The interval is the concept; the duration value that sizes it is a separate [Window Duration] supplied per containing pattern.)

Kind: Type

Term window duration: the length a containing pattern chooses for a guard, which EXCEEDS zero — a [Window Duration]; the value the elapsed term is measured against. The [Window] the length sizes is the interval, and carries no separate name in a rule.

NOTE: watch the degenerate bound (Term window duration).

#### Window Duration

One for each instance of the atom (24 hours for a to-do list, minutes for a payment); it sizes the [Window] but is not itself part of the concept's state.

Kind:         Parameter
Parameter of: Record and Check
Projection:   window

Term elapsed term: `(now - recorded_at)`.

Term under guard: an identity in the recorded set whose elapsed term is less than window duration — the state [Check] answers seen for.

```
State 1: The host MUST hold EXACTLY ONE recording instant per identity the recorded set holds.
State 2: The host MUST derive under guard from the elapsed term at EVERY call.
State 3: The atom MUST NOT hold state beyond the recorded set.
```

## What people do

### Every action

```
Operation 11: The containing pattern MUST supply EXACTLY ONE window duration per instance of the atom.
```

### Record

The behavior a containing pattern invokes when it has just observed an [Identity] (for example, after removing an item) so that future repeats can be recognized. It places the [Identity] under guard, opening a [Window]. It never refuses an [Identity] for being under guard — recording one that is already under guard does not push its [Window] forward — and it answers [Storage Failure] when the database refuses its write.

Kind: Operation

```
record(identity)
  answers ok
  refuses storage-failure
```

```
Operation 1: A landed record MUST place an identity that is not under guard under guard.
Operation 3: A landed record MUST answer ok.
Operation 4: [Record] MUST NOT refuse an identity under guard.
Operation 14: IF the database refuses the write THEN [Record] MUST answer storage-failure.
```

Term landed record: a [Record] call the action admits (Execution Contract Read 4).

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Record] | no | ok | enters under guard, recording instant from the injected now (Operation 1, Clock semantics 1) |
| [Record] | yes | ok | unchanged — the original recording instant stands (Invariant 2.1, Invariant 2.2) |
| [Record] | either, and the database refuses the write | [Storage Failure] | unchanged — for an identity that was not under guard, the guard is missed (Operation 14, Record failure 2) |

#### Storage Failure

The refusal [Record] returns when the database refuses its write after the read answers — the Execution Contract's Step 3 failure. Nothing is written, so an [Identity] that was not under guard stays so and the guard is missed; what that means for an act already taken is the containing pattern's decision.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

A comment system calls [Record] with a comment's text, and the database refuses the write: [Record] answers [Storage Failure], nothing is written, and the text, which was not under guard, stays unguarded, so a second post a moment later checks [Not Seen] and goes through (Operation 14, Record failure 2). Had the text been under guard already, the refused write would have left its guard standing.

### Check

The behavior a containing pattern invokes before accepting a new [Identity], to ask whether that [Identity] is currently under guard. It only reads — it changes nothing — and reports its answer as [Seen] or [Not Seen]. What to do with an answer is the containing pattern's decision (Non-goal 1), a state-unavailable one included: proceeding as [Not Seen] is fail-open, as [Seen] fail-closed.

Kind: Operation

```
check(identity)
  answers seen | not-seen
```

```
Operation 5: [Check] MUST answer EXACTLY ONE OF seen, not-seen.
Operation 6: [Check] MUST answer seen for an identity under guard.
Operation 7: [Check] MUST answer not-seen for an identity that is not under guard.
```

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Check] | yes | [Seen] | none — the call reads (Operation 6, Invariant 3.1) |
| [Check] | no | [Not Seen] | none — the call reads (Operation 7, Invariant 3.1) |

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

A payment processor calls [Check] while the database cannot be read: [Check] answers state-unavailable (Execution Contract Read 1), and proceeding as on [Not Seen] (fail-open) or as on [Seen] (fail-closed) is the processor's own decision (Non-goal 1).

## What is and what should never be (Invariants)

- **Invariant 2 — Single-recording.**
  ```
  Invariant 2.1: [Record] MUST NOT extend the guard of an identity under guard.
  Invariant 2.2: [Record] MUST preserve the recording instant of an identity under guard.
  ```
- **Invariant 4 — Eventual expiry.**

- **Invariant 3 — Idempotency of check.**
  ```
  Invariant 3.1: [Check] MUST NOT alter the recorded set.
  ```

## When something happens

### Check database unavailability

### Record storage failure

```
Record failure 2: The atom MUST treat a failed write as a guard miss for an identity that is not under guard.
Record failure 3: The atom MUST NOT treat a failed write as a safety violation.
```

## While something is so

### Clock semantics

```
Clock semantics 1: The atom MUST anchor a guard to the injected now of the opening record.
```

### Lazy expiry

<details markdown="block">
<summary>WHY</summary>

The atom claims behaviour and not storage: Operation 7 answers not-seen for an identity that is not under guard, and the identity's entry stays in the recorded set, since no action of the atom removes one and the database removes nothing on its own (Execution Contract Database 4).

</details>

## Optional

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 4, Execution Contract Read 1 through 4 and Execution Contract Refusal 1.
```

## Left to others

```
Non-goal 1: The atom MUST NOT decide the containing pattern's response to an answer.
Non-goal 4: The atom MUST NOT reconcile two recorded sets.
Non-goal 5: A pattern needing one guard across every instance MUST compose a coordination pattern.
Non-goal 7: A pattern needing long-term history MUST compose an audit pattern.
Non-goal 8: The atom MUST NOT supply the matching rule.
Non-goal 9: A pattern needing a guard that resets on every sighting MUST compose a sliding-window pattern.
Non-goal 10: The atom MUST NOT read a calendar.
Non-goal 11: A pattern needing day-boundary semantics MUST compose a calendar-day pattern.
Non-goal 12: The atom MUST NOT correct clock skew.
Non-goal 13: A pattern needing a strictly monotonic guard MUST compose a logical-clock pattern.
Non-goal 14: A pattern needing the entry of an identity whose guard has elapsed erased MUST compose Defensible Retention.
```

NOTE: the owners — the containing pattern (Non-goal 1; Non-goal 8, Identity 5); the deployment, for each instance's own guard in the database it supplies (Non-goal 4, Non-goal 5, Non-goal 12); a Coordination pattern *(forthcoming)*, for one guard across every instance (Non-goal 4, Non-goal 5); [Audit Trail](../compositions/audit-trail.md) (Non-goal 7); Sliding Window *(forthcoming)* (Non-goal 9); a Calendar Day pattern *(forthcoming)* (Non-goal 10, Non-goal 11); a Logical Clock pattern *(forthcoming)* (Non-goal 13); [Defensible Retention](../compositions/defensible-retention.md) (Non-goal 14).

Where the pattern breaks down: when *recent* is measured by something other than wall-time elapsed. Number of intervening events, calendar-day boundaries and business-day boundaries each take a separate concept.

### Composition notes

Three compositions name this atom: [Idempotent Reservation](../compositions/idempotent-reservation.md), [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) and [Reserve from Pool](../compositions/reserve-from-pool.md). What a containing pattern owes is stated where the atom's operations are — the window duration (Operation 11) and the response to an answer (Non-goal 1) — and is not restated here.

The comment and payment examples check and record in separate steps. A containing pattern that checks, acts and records in one action has Execution Contract Database 1 and Database 2 serialize it: two such actions on one identity run one after the other, and the later reads what the earlier committed. Where the check and the record are separate actions, two first sightings at once can both answer not-seen and both act; which of the two a containing pattern builds is its own (Non-goal 1).

## Example

In Task, with a 24-hour window, a user deletes *"buy milk."* Task calls [Record] with `"buy milk"`. Two hours later, the user attempts to add *"buy milk"* again. Task calls [Check] with `"buy milk"`, receives [Seen], rejects the add as `duplicate-recent`. Twenty-five hours after the original delete, the user tries again. Task calls [Check] with `"buy milk"`, receives [Not Seen], accepts the add.

(`duplicate-recent` is shown verbatim by design: it is the **composing pattern's** pinned rejection string — neither this atom's nor Task's, since neither raises it; it exists only where the two are wired together, and its wire form is frozen because callers switch on the exact string. It is not this atom's Term; Task's term entry [Duplicate Recent](./task.md#duplicate-recent) names it. Per [`annotation.md`](https://github.com/scottromack/grace-commons/blob/main/working-ideas/annotation.md), a pinned wire literal shown to display its exact form stays backticked — "literal" is a pinned projection, not a kind.)

The same two calls serve the others. A comment box records the normalized comment text once the first post completes, so the second click is [Seen] and rejected (60-second window). A payment processor checks the idempotency key, charges and caches the response, then records the key, so a retry two minutes later is [Seen] and answered from the cache (5-minute window); a newsletter form absorbs a second submission of the same address as already subscribed (1-hour window). Where the system checks and records in separate steps, two requests at once can both receive [Not Seen] (see the Composition notes). What differs across all four is the [Window Duration], the identity-matching rule, and the containing pattern's response on [Seen].

## Source

Duplicate Prevention is a primitive integrity concept. It has no direct anchor in ISO (International Organization for Standardization) or IEEE (Institute of Electrical and Electronics Engineers) standards, or in regulation, in this generic form, though specific instantiations have widely-used standards behind them:

- **HTTP (HyperText Transfer Protocol — the request/response protocol of the web) idempotency keys** (IETF (Internet Engineering Task Force — the body that develops internet standards) draft and de-facto convention for safe retry of state-changing requests).
- **Stripe / payment-processor idempotency** (industry-standard pattern for at-most-once charge semantics within a window).
- **Message-queue exactly-once-within-window semantics** (Kafka, SQS (Amazon Simple Queue Service), Pub/Sub deduplication).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a freestanding concept with state, actions, and operational principles, designed for composition rather than absorption.
- **Distributed-systems idempotency literature** — the underlying mechanic appears as "idempotency window" or "exactly-once-within-window semantics" in message-queue and payment-processor designs.
- **Linear temporal logic** (a formal notation for reasoning about sequences of states over time) — a guard's expiry expressed as a temporal property.

## Proof

### Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the recorded set and the atom's own query surface. The atom is not regulated and carries no adversarial scenarios; what it carries is a guard other patterns rest correctness on, and this section is where that guard becomes testable rather than asserted.

#### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE recording instant PER identity the recorded set holds (State 1).
Check 3.1: An auditor MUST find EVERY check answering EXACTLY ONE OF seen, not-seen (Operation 5).
Check 3.2: An auditor MUST find a check answering seen for an identity under guard (Operation 6).
Check 3.3: An auditor MUST find a check answering not-seen for an identity that is not under guard (Operation 7).
```

NOTE: EVERY check names the rule the check tests.

#### External checks

```
External check 1: An auditor needing the window duration confirmed MUST read the containing pattern's own declaration (Operation 11).
External check 2: An auditor needing the matching rule confirmed MUST read the containing pattern's own declaration (Identity 5).
External check 3: An auditor needing a guard miss confirmed MUST read the deployment's own database (Record failure 2).
```

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; the transition; a containing pattern (also: the containing pattern, a pattern); a business caller; the deployment (also: a deployment); the database; an identity; a guarded entry; an entry; a check; an auditor.

Term records: recorded set — every identity placed under guard, one recording instant per entry.

Term record verbs: identify, treat, interpret, normalize, supply, hold, derive, stamp, place, answer, refuse, read, own, extend, preserve, open, alter, decide, reconcile, compose, anchor, correct, find.

Term value sets: empty.

Term bounds: window duration (the length a containing pattern chooses for a guard; window is the lowering token the [Window Duration] term entry carries).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); under guard — recorded, and the guard's term not yet elapsed.

Term terms: identity, matching rule, recorded set, recording instant, window duration, elapsed term, under guard, now, transition, seam, business caller, landed record.

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
[Storage Failure]: #storage-failure

## Status

`done — 2026-11-20` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: done — 2026-11-20
formal: verified — duplicate-prevention.tla + 1 twin (2026-06-03); duplicate-prevention.als + 8 twins (the static data model, 2026-11-11: State 1, Operation 5, 6 and 7 and Invariant 2.1, 2.2 and 3.1 and Operation 1 checked on every recorded set and every answer the [Record] and [Check] calls leave, Invariant 2.1 and 2.2 a cross-check with the TLA+ model; the rules that own the deleted Invariant 1, 3.2 and 4 are among them); coverage 2026-11-10 (unit formal: more coverage for the yes votes), 2026-11-11
last gate: 2026-11-21 — Final Critique 10, a delta round, one reader (Linus beam-free), frozen at 03db0d73 — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Operation 5 obliges [Check] to answer exactly one of seen, not-seen while Execution Contract Read 1 answers state-unavailable on a failed read, was refuted by both triages: Read 2 limits every rule that says what an action answers to a call whose read answered, so Operation 5 never reaches a failed read, Read 1 answers it, and the page cites Read 1 through Capability requirement 2 and does not restate it; the finder's cure would also have Check 3.1 count a state-unavailable answer, which Read 3 says says nothing about the records); 2026-11-20 — Final Critique 9, a delta round, one reader (Linus nemotron-3.5-super-vl-free), frozen at 894be4e7 — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that the owners NOTE names four forthcoming patterns that do not exist, was refuted by both triages: spec-format.md's Non-goals section prescribes the forthcoming marker, the NOTE changes no rule, and Non-goal 5 binds a deployment needing one guard across every instance to compose a coordination pattern whether or not it has landed; its refining and rhetorical reports were refuted too; the blind second triage placed one unreported defect refining, Kind C: the owners NOTE named an audit pattern without its link though Audit Trail has landed, cured); 2026-11-20 — Final Critique 8, a delta round, frozen at 6f568bb1 — foundational count 0, clean, no sample; 2026-10-28 — Final Critique 7, frozen at 7c6ea61 — foundational count 0, clean, one sample

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./duplicate-prevention.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/duplicate-prevention.md`.

</details>

NOTE: End of Duplicate Prevention.

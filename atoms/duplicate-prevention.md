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

Duplicate Prevention gives a system a short-term memory of things it has recently seen, so it can spot repeats. The way it works is simple. When something happens (an item is removed, a request is processed), the system records the thing's identity — a value that names it, such as the item's text or the request's key; before accepting a new one, it checks whether that identity was recorded within a set time window. If it was, the check reports "seen" and the system can decide what to do — reject the repeat, ignore it, or return the earlier result. Once the window has passed, the same identity is fresh again. The pattern itself stays out of that decision and out of how identities are compared — those belong to the system using it — which is why the same mechanism works for a to-do list (a one-day window blocks accidental re-adds), a payment system (a few-minute window stops a retried charge from billing twice), a comment box (a one-minute window stops double-click double-posts), and a signup form. One firm guarantee: recording the same identity again does not push the window forward, so a flurry of repeats cannot extend the block indefinitely — the clock starts at the first sighting and runs out at a fixed time.

*Also known as: temporal idempotency (a repeat inside a stretch of time has no further effect), recency guard, cooldown window.*

---

## Intent

WHY:
Every system that accepts input from a person or another system meets the same class of problem: the double-submit, the rapid re-add, the replayed message, the retried charge, the double-posted comment, the redundant sign-up. The shape is constant — an action carries an identity, the action should be rejected, de-duplicated or replayed if that identity was seen recently, and *recently* is a wall-time window. The atom is that mechanic and nothing more: it places an identity under guard for a bounded term and answers whether the identity is still under guard. It does not compare identities, does not decide what a repeat means, and does not act. The same literature names it three times — *idempotency window* in distributed systems, *cooldown* in user experience, *replay protection* in security — and the concept underneath is one concept.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a guarded entry by the identity.
Identity 2: The atom MUST treat an identity as opaque.
Identity 3: The atom MUST NOT interpret an identity.
Identity 4: The atom MUST NOT normalize an identity.
Identity 5: The containing pattern MUST supply the identity to [Record] and [Check] already reduced to the value the matching rule compares by.
```

Term identity: the opaque value a containing pattern asks the atom to remember and recognize — an [Identity].

Term matching rule: the containing pattern's rule for judging two identities the same — string equality, case-insensitive, trimmed, normalized, hashed.

### State

```
State 1: The host MUST hold EXACTLY ONE recording instant per guarded identity.
State 2: The host MUST derive under guard from the elapsed term at the moment a question is asked.
State 3: The atom MUST NOT hold state beyond the recorded set.
```

Term recorded set: every identity a [Record] has placed under guard, each held with the identity's recording instant, whether or not the identity is still under guard — the [Recorded Set].

Term recording instant: the instant an identity was placed under guard, stamped from the injected now — a [Recording Instant].

Term window duration: the length a containing pattern chooses for a guard — a [Window Duration]; the value the elapsed term is measured against. The [Window] the length sizes is the interval, and carries no separate name in a rule.

Term elapsed term: `now − recorded_at`.

Term under guard: an identity in the recorded set whose elapsed term is less than window duration — the state [Check] answers seen for.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
Capability requirement 2: The deployment MUST supply the database PER Execution Contract Database 1 through 4 and Execution Contract Read 1 through 3.
```

### Operations

```
record(identity)
  answers ok
  refuses storage-failure

check(identity)
  answers seen | not-seen
```

```
Operation 1: A landed record MUST place an identity that is not under guard under guard.
Operation 2: A landed record MUST stamp the recording instant of an identity that is not under guard from the injected now.
Operation 3: A landed record MUST answer ok.
Operation 4: [Record] MUST NOT refuse a call on the ground that the identity is under guard.
Operation 5: [Check] MUST answer EXACTLY ONE OF seen, not-seen.
Operation 6: [Check] MUST answer seen for an identity under guard.
Operation 7: [Check] MUST answer not-seen for an identity that is not under guard.
Deleted: Operation 8. Capability requirement 1 owns it.
Deleted: Operation 9. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 10. Execution Contract Logic confinement 3 owns it.
Operation 11: The containing pattern MUST supply EXACTLY ONE window duration per instance of the atom.
Operation 12: The containing pattern MUST own the response to an answer.
Deleted: Operation 13. Execution Contract Read 1 owns it.
Operation 14: IF the database refuses the write THEN [Record] MUST answer storage-failure.
```

NOTE: watch the admitted effect (Operation 1 through 3, Invariant 2.3).

NOTE: watch the refusal ban (Operation 4).

Term landed record: a [Record] call whose write, where the call makes one, the database commits.

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Record] | no | ok | enters under guard, recording instant from the injected now (Operation 1, Operation 2) |
| [Record] | yes | ok | unchanged — the original recording instant stands (Invariant 2.1, Invariant 2.2) |
| [Record] | either, and the database refuses the write | [Storage Failure] | unchanged — for an identity that was not under guard, the guard is missed (Operation 14, Record failure 2) |
| [Check] | yes | [Seen] | none — the call reads (Operation 6, Invariant 3.1) |
| [Check] | no | [Not Seen] | none — the call reads (Operation 7, Invariant 3.1) |

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the atom's evaluation of one call against the recorded set, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading here.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

### Invariants

- **Invariant 2 — Single-recording.**
  ```
  Invariant 2.1: [Record] MUST NOT extend the guard of an identity under guard.
  Invariant 2.2: [Record] MUST preserve the recording instant of an identity under guard.
  Invariant 2.3: A landed record MUST open a fresh guard for an identity that is not under guard.
  Deleted: Invariant 1. Operation 6 and Operation 7 own it.
  ```
- **Invariant 3 — Idempotency of check.**
  ```
  Invariant 3.1: [Check] MUST NOT alter the recorded set.
  Deleted: Invariant 3.2. Operation 6, Operation 7 and Invariant 3.1 own it.
  ```
- **Invariant 4 — Eventual expiry.**
  ```
  Deleted: Invariant 4.1. Operation 7 and Execution Contract Database 4 own it.
  Deleted: Invariant 4.2. Operation 7 owns it.
  ```

## Examples

### Personal Todo (24-hour window)

A user deletes *"buy milk."* Personal Todo calls [Record] with `"buy milk"`. Two hours later, the user attempts to add *"buy milk"* again. Personal Todo calls [Check] with `"buy milk"`, receives [Seen], rejects the add as `duplicate-recent`. Twenty-five hours after the original delete, the user tries again. Personal Todo calls [Check] with `"buy milk"`, receives [Not Seen], accepts the add.

(`duplicate-recent` is shown verbatim by design: it is the **composing pattern's** pinned rejection string — neither this atom's nor Personal Todo's, since neither raises it; it exists only where the two are wired together, and its wire form is frozen because callers switch on the exact string. It is not this atom's Term; when Personal Todo carries a Terms registry it becomes a cross-page reference to that pattern's term entry. Per [`annotation.md`](../working-ideas/annotation.md), a pinned wire literal shown to display its exact form stays backticked — "literal" is a pinned projection, not a kind.)

### Comment double-post protection (60-second window)

A user submits a comment, the page hangs, they click submit again. The comment system calls [Record] with the normalized comment text after the first submission completes. The second click triggers [Check], receives [Seen], rejects the second post. The first comment goes through; the second does not.

### Payment idempotency (5-minute window)

A payment processor receives a charge request with an idempotency key. It calls [Check] with the key, receives [Not Seen], processes the charge, caches the response against the key in its own records and calls [Record] with the key. A retry two minutes later triggers [Check] with the key, receives [Seen], and the processor returns its cached result without re-processing.

### Newsletter double-subscribe (1-hour window)

A user submits the same email address to a newsletter form twice in quick succession (browser back button, double-click on submit). The first submission processes. The second, a few seconds later, triggers [Seen] and is silently absorbed-as-already-subscribed rather than producing a duplicate confirmation email.

The mechanic is identical across all four. What differs: the [Window Duration], the identity-matching rule, and the containing pattern's response on [Seen] (reject, return-cached, silently-absorb).

---

## Generation acceptance

An implementation is acceptable when the checks below are provable to an external auditor given the recorded set and the atom's own query surface. The atom is not regulated and carries no adversarial scenarios; what it carries is a guard other patterns rest correctness on, and this section is where that guard becomes testable rather than asserted.

### Conformance checks

```
Check 1.1: An auditor MUST find EXACTLY ONE recording instant PER identity the recorded set holds (State 1).
Check 1.2: An auditor MUST find an identity's recording instant unchanged across a second record inside the identity's window (Invariant 2.2).
Check 1.3: An auditor MUST find no guard extended by a second record (Invariant 2.1).
Check 1.4: An auditor MUST find a fresh recording instant for a landed record against an identity that is not under guard (Invariant 2.3).
Check 2.1: An auditor MUST find the recorded set unchanged across a check (Invariant 3.1).
Deleted: Check 2.2. Check 2.1, Check 3.2 and Check 3.3 own it.
Check 3.1: An auditor MUST find EVERY check answering EXACTLY ONE OF seen, not-seen (Operation 5).
Check 3.2: An auditor MUST find a check answering seen for an identity under guard (Operation 6).
Check 3.3: An auditor MUST find a check answering not-seen for an identity that is not under guard (Operation 7).
Deleted: Check 3.4. Check 3.3 owns it.
Check 4.1: An auditor MUST find EVERY landed record answering ok (Operation 3).
```

NOTE: EVERY check names the rule the check tests.

### External checks

```
External check 1: An auditor needing the window duration confirmed MUST read the containing pattern's own declaration (Operation 11).
External check 2: An auditor needing the matching rule confirmed MUST read the containing pattern's own declaration (Identity 5).
External check 3: An auditor needing a guard miss confirmed MUST read the deployment's own database (Record failure 2).
Deleted: External check 4. Execution Contract Database 3 owns it.
Deleted: External check 5. Operation 12 owns it.
External check 6: An auditor needing the clock's honesty confirmed MUST read the deployment's own clock discipline (Non-goal 12).
```

## Non-goals

```
Non-goal 1: The atom MUST NOT decide the containing pattern's response to an answer.
Deleted: Non-goal 2. Execution Contract Database 3 owns it.
Deleted: Non-goal 3. Execution Contract Database 3 owns it.
Non-goal 4: The atom MUST NOT reconcile two recorded sets.
Non-goal 5: A pattern needing one guard across every node MUST compose a coordination pattern.
Deleted: Non-goal 6. Operation 7 and Execution Contract Database 4 own it.
Non-goal 7: A pattern needing long-term history MUST compose an audit pattern.
Non-goal 8: The atom MUST NOT supply the matching rule.
Non-goal 9: A pattern needing a guard that resets on every sighting MUST compose a sliding-window pattern.
Non-goal 10: The atom MUST NOT read a calendar.
Non-goal 11: A pattern needing day-boundary semantics MUST compose a calendar-day pattern.
Non-goal 12: The atom MUST NOT correct clock skew.
Non-goal 13: A pattern needing a strictly monotonic guard MUST compose a logical-clock pattern.
```

NOTE: the owners — the containing pattern (Non-goal 1, Operation 12; Non-goal 8, Identity 5); the deployment (Non-goal 4, Non-goal 5); a Coordination pattern *(forthcoming)* (Non-goal 4, Non-goal 5); an Audit pattern (Non-goal 7); Sliding Window *(forthcoming)* (Non-goal 9); a Calendar Day pattern *(forthcoming)* (Non-goal 10, Non-goal 11).

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
Deleted: Check unavailability 1. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 2. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 3. Operation 12 and Operation 13 own it.
Deleted: Check unavailability 4. Non-goal 1 owns it.
```

### Lazy expiry

```
Deleted: Lazy expiry 1. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 2. Execution Contract Database 4 owns it.
Deleted: Lazy expiry 3. Operation 7 owns it.
```

WHY:
The atom claims behaviour and not storage: Operation 7 answers not-seen for an identity that is not under guard, and the identity's entry stays in the recorded set, since no action of the atom removes one and the database removes nothing on its own (Execution Contract Database 4).

### Record storage failure

```
Deleted: Record failure 1. Operation 14 owns it.
Record failure 2: The atom MUST treat a failed write as a guard miss.
Record failure 3: The atom MUST NOT treat a failed write as a safety violation.
Deleted: Record failure 4. Execution Contract Database 3 owns it.
```

## Composition notes

Three compositions name this atom: [Idempotent Reservation](../compositions/idempotent-reservation.md), [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) and [Reserve from Pool](../compositions/reserve-from-pool.md). What a containing pattern owes is stated where the atom's operations are — the window duration (Operation 11) and the response to an answer (Operation 12) — and is not restated here.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; the transition; a containing pattern (also: the containing pattern, a pattern); a business caller; the deployment (also: a deployment); the database; an identity; a guarded entry; an entry; a check; an auditor.

Term records: recorded set — every identity placed under guard, one recording instant per entry.

Term record verbs: identify, treat, interpret, normalize, supply, hold, derive, stamp, place, answer, refuse, read, own, stand, extend, preserve, open, alter, decide, survive, reconcile, compose, anchor, correct, find.

Term bounds: window duration (the length a containing pattern chooses for a guard; window is the lowering token the [Window Duration] term entry carries).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); under guard — recorded, and the guard's term not yet elapsed.

Term terms: identity, matching rule, recorded set, recording instant, window duration, elapsed term, under guard, now, transition, seam, business caller, landed record.

#### Identity

The value a containing pattern asks Duplicate Prevention to remember and recognize — what counts as "the same thing seen again." The concept treats it as opaque: it stores and compares the value but never interprets it, and how two identities are judged equal is the containing pattern's matching rule, which the containing pattern applies before the value reaches this atom.

Kind: Type

#### Window

The bounded interval of time during which a recently-recorded [Identity] is still guarded. It opens when the [Identity] is first recorded and closes after a [Window Duration] the containing pattern sets; once it has elapsed, the same [Identity] is fresh again. (The interval is the concept; the duration value that sizes it is a separate [Window Duration] supplied per containing pattern.)

Kind: Type

#### Recorded Set

The atom's memory: every [Identity] a [Record] has placed under guard, each held together with the time its current guard opened. An [Identity] enters on [Record] and stays: once its [Window] has elapsed it is no longer under guard and [Check] answers [Not Seen] for it, but no action of the atom removes its entry. It is an internal mechanism, queryable for diagnostics, not a user-facing surface.

Kind:       Type
Projection: recorded

#### Record

The behavior a containing pattern invokes when it has just observed an [Identity] (for example, after removing an item) so that future repeats can be recognized. It places the [Identity] under guard, opening a [Window]. It never refuses an [Identity] for being under guard — recording one that is already under guard does not push its [Window] forward — and it answers [Storage Failure] when the database refuses its write.

Kind: Operation

#### Check

The behavior a containing pattern invokes before accepting a new [Identity], to ask whether that [Identity] is currently under guard. It only reads — it changes nothing — and reports its answer as [Seen] or [Not Seen]. What to do with an answer is the containing pattern's decision (Operation 12), a state-unavailable one included: proceeding as [Not Seen] is fail-open, as [Seen] fail-closed.

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

The length the containing pattern chooses for a [Window] — how long a recently-recorded [Identity] stays guarded. It is supplied by the containing pattern, one for each instance of the atom (24 hours for a to-do list, minutes for a payment), sizes the [Window] but is not itself part of the concept's state, and is the value the expiry comparison measures [Now] − [Recording Instant] against.

Kind:         Parameter
Parameter of: Record and Check
Projection:   window

#### Now

The current wall-time reading the [Record] and [Check] behaviors evaluate against, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller). [Record] stamps [Recording Instant] from it; [Check] compares it against the [Window] to decide [Seen] versus [Not Seen].

Kind:         Parameter
Parameter of: Check
Projection:   now

#### Storage Failure

The refusal [Record] returns when the database refuses its write after the read answers — the Execution Contract's Step 3 failure. Nothing is written, so an [Identity] that was not under guard stays so and the guard is missed; what that means for an act already taken is the containing pattern's decision.

Kind:       Member
Member of:  the action rejection
Role:       Outcome
Projection: storage-failure

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

---

## Standards references

Duplicate Prevention is a primitive integrity concept. It has no direct ISO / IEEE / regulatory anchor in this generic form, though specific instantiations have widely-used standards behind them:

- **HTTP (HyperText Transfer Protocol — the request/response protocol of the web) idempotency keys** (IETF (Internet Engineering Task Force — the body that develops internet standards) draft and de-facto convention for safe retry of state-changing requests).
- **Stripe / payment-processor idempotency** (industry-standard pattern for at-most-once charge semantics within a window).
- **Message-queue exactly-once-within-window semantics** (Kafka, SQS (Amazon Simple Queue Service), Pub/Sub deduplication).

It inherits from:

- **Daniel Jackson, *The Essence of Software*** — the conception of a freestanding concept with state, actions, and operational principles, designed for composition rather than absorption.
- **Distributed-systems idempotency literature** — the underlying mechanic appears as "idempotency window" or "exactly-once-within-window semantics" in message-queue and payment-processor designs.
- **Linear temporal logic** (a formal notation for reasoning about sequences of states over time) — a guard's expiry expressed as a temporal property.

---

## Status

`partially resolved` — see the Ledger.

## Ledger

```
status: partially resolved
formal: verified — duplicate-prevention.tla + 1 twin, 2026-06-03
last gate: 2026-10-21 — Final Critique 5, the council's first round on the page and the first on its Store-contract rewrite (b683119), three fresh readers on free models (GRID Nemotron 3 Ultra, EOS MiniMax M3.1 Flash, Linus GLM-5.3 Flash), each handed only the round's reading set, three passes on one text (frozen at 3e955a5); the round rests on three counted passes — foundational count 6 after triage (17 reports: 9 standing, merged into 6; 4 sent down; 4 rejected), all Kind A: [Check]'s answers and [Record]'s ok were closed against the failed read and the refused write the Execution Contract answers, and a fail-open posture obliged not-seen for an identity under guard; a refused write was obliged to place the guard the page also called missed; the window duration reached the host by no stated route, so builds read it per call, per entry or at every read; the matching rule was handed to an atom forbidden to interpret an identity; a drop was obliged that no declared action can make, beside a lazy host the page licensed to keep the entry; and two checks under one now were said to answer alike across a [Record] between them; 11 refining reports, 5 rhetorical reports; not clean; every foundational finding cured in place; 2026-06-18 — Final Critique 4, fresh reader — clean

open:
- 2026-10-21-a · refining · Term now; Now entry; Capability requirement 1 · Term now hands now to the transition, which the Execution Contract reads as the state-changing T, while [Check], a query, compares now too, and the Now entry gives Parameter of: Check alone though [Record] stamps from it → name every consumer of now, [Check]'s projection among them
- 2026-10-21-b · refining · Examples; Operation 12; Composition notes · the payment and comment examples check, act and record in separate steps, so two first sightings at once both answer not-seen and both act; where [Record] stands against the act is the containing pattern's (Operation 12), and Execution Contract Database 1 and Database 2 serialize a containing action that checks, acts and records in one transaction → say so beside the examples or in the Composition notes
- 2026-10-21-c · refining · Invariant 2.3; Operation 1; Non-goal 1; Operation 12; Clock semantics 1; Operation 2; Invariant 2.2 · three propositions each owned twice: a fresh guard for an identity not under guard, the response left to the containing pattern, and a guard anchored to the opening record's now → one owner each (GRACE-lang Authority 3)
- 2026-10-21-d · refining · Term recorded set; Execution Contract Database 4 · no action erases an entry whose guard has elapsed, so the recorded set keeps every identity ever placed under guard and a pattern that needs the space back has nothing to call → a declared erasure the atom owns, or a Non-goal naming the composing pattern that purges
- 2026-10-21-e · refining · External check 6; Non-goal 12 · External check 6 sends the auditor to Non-goal 12, which owns skew correction, for the clock's honesty, which Execution Contract Logic confinement 7 makes the deployment's → cite Logic confinement 7, or delete the check to it as Event Log's External check 3 was
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/duplicate-prevention.md`; the rounds and the migration that got it here are in [its history](./duplicate-prevention.hist.md).

- **2026-10-21 — A failed read answers as the Execution Contract says.** *Chose:* the failed read cited from the Execution Contract (Capability requirement 2, Execution Contract Read 1 through 3) and the rule that restated it, the atom-wide state-unavailable (Operation 13), deleted to Read 1; state-unavailable off [Check]'s answers (Operation 5, Check 3.1), the read's condition off the rules and the term it held to an answered read (Operation 6, Operation 7, Term landed record), Term database read deleted, and state-unavailable off both signatures and the case table; rules 51 to 50. *Over:* the page stating for itself what every action answers when the recorded set cannot be read. *Because:* the maintainer ruled on 2026-10-21 that the Execution Contract states the failed read once; this page's fifth Final Critique had made one of the cures the contract's Read family is written from. The response to a state-unavailable answer stays the containing pattern's (Operation 12): proceeding as not seen is fail-open, as seen fail-closed, and the atom decides neither.

- **2026-10-21 — A failed read and a refused write answer as the Execution Contract answers them; the window duration is one per instance and the matching rule is applied before the call; nothing drops an entry, so the recorded set holds every identity placed under guard; two checks answer alike by the rules that fix each answer.** *Chose:* state-unavailable on both actions where the read of the recorded set fails (Operation 13, Term database read) and storage-failure on [Record] where the database refuses its write (Operation 14), with [Check]'s answers held to an answered read (Operation 5 through 7) and [Record]'s placing, stamping, ok and fresh guard held to a landed record (Operation 1 through 3, Invariant 2.3, Term landed record); Operation 4 refusing nothing on the ground that the identity is under guard; Record failure 1 deleted to Operation 14, and Check unavailability 1 through 4 and External check 5 to Operation 12, Operation 13 and Non-goal 1, so proceeding as not-seen or as seen on an unavailable read is the containing pattern's response to an answer; one window duration for each instance of the atom (Operation 11); each identity supplied already reduced to the value the containing pattern's matching rule compares by (Identity 5); Invariant 4.1, Non-goal 6 and Lazy expiry 1 through 3 deleted to Operation 7 and Execution Contract Database 4, with Check 3.4 to Check 3.3, and the recorded set declared as every identity placed under guard, held whether or not its guard still runs; Invariant 3.2 deleted to Operation 6, Operation 7 and Invariant 3.1, and Check 2.2 to Check 2.1, Check 3.2 and Check 3.3. *Over:* a [Check] obliged to answer seen or not-seen and a [Record] obliged to answer ok where the contract answers state-unavailable and storage-failure, so a caller could be told a guard stood that the database never kept; a fail-open posture obliging not-seen for an identity under guard; a window duration two builds could take per call, per entry or at every read; a matching rule two builds could apply inside the atom or before the call; a drop obliged of a host that no declared action lets drop, beside a lazy host the page licensed to keep the entry; and two checks under one now said to answer alike across a [Record] between them. *Because:* Final Critique 5 found each a divergence between conforming builds or two rules no build can both obey, and the corpus held each cure: Actor Identity's, Permissions' and Capability's rounds answer the failed read and the refused write, the method's entry of 2026-10-08 deletes a broken rule to the rules that already hold its states, and Final Critique 4's own text configured the window per containing pattern. This turns three choices the 2026-10-20 entry kept — a failed write answering ok, the posture under an unavailable database declared by the deployment, and the host's drop as the atom's own — because the Database contract the atom takes (Capability requirement 2) and the contract's Step 1 and Step 3 failures leave no conforming build that can make them. What [Check] answers on a read that answers, and what [Record] does on a write that lands, are unchanged.

- **2026-10-20 — The store's guarantees cited, not restated.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 2), and the four rules that set the recorded set's durability tombstoned to Store 3 — Non-goal 2 and Non-goal 3, the recorded set's survival across a restart not required of the atom and left to the deployment, Record failure 4, a durable recorded set where duplicate prevention is safety-critical, and External check 4, the auditor's check of that durability; rules 66 to 63. *Over:* a recorded set whose survival across a restart each deployment chose, a volatile set admitted wherever the guard was not safety-critical. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and that the four Store rules hold for every specification; `execution-contract.md` writes them once as the Store contract, and Store 3 keeps every committed write across a restart. A failed write still answers ok and misses the guard (Record failure 1 through 3), the posture under an unavailable store stays the deployment's to declare (Check unavailability 1 through 4), and the host's drop of an identity that is not under guard stays the atom's own (Invariant 4.1, Lazy expiry 1, Lazy expiry 2). Under guard is derived from the recording instant each entry carries, so the atom cites neither History 1 nor Order 1; what the atom does for its domain is unchanged.

NOTE: End of Duplicate Prevention.

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

WHY:
The atom stores a value and compares a value; what counts as *the same thing seen again* is the containing pattern's question. That is why one mechanic serves a to-do title, a payment key and a normalized comment body without a line of difference (Identity 3 through 5).

### State

```
State 1: The host MUST hold EXACTLY ONE recorded_at per guarded identity.
State 2: The host MUST derive under guard from the elapsed term at the moment a question is asked.
State 3: The atom MUST NOT hold state beyond the recorded set.
```

Term recorded set: the identities under guard, each held with the identity's recorded_at — the [Recorded Set].

Term recorded_at: the instant an identity was placed under guard, stamped from the injected now — a [Recorded At].

Term window duration: the length a containing pattern chooses for a guard — a [Window Duration]; the value the elapsed term is measured against. The [Window] the length sizes is the interval, and carries no separate name in a rule.

Term elapsed term: `now − recorded_at`.

Term under guard: an identity in the recorded set whose elapsed term is less than window duration — the state [Check] answers seen for.

WHY:
One set and one stamp per entry are the whole of the atom's storage, and *under guard* is derived at the moment of the question rather than stored. That is what lets a host implement the atom over a store offering nothing but a key with an expiry (State 2).

### Capability requirement

```
Capability requirement 1: The deployment MUST supply now at the seam.
```

WHY:
What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

### Operations

```
record(identity)
  answers ok

check(identity)
  answers seen | not-seen
```

```
Operation 1: [Record] MUST place an identity that is not under guard under guard.
Operation 2: [Record] MUST stamp recorded_at from the injected now.
Operation 3: [Record] MUST answer ok.
Operation 4: [Record] MUST NOT refuse.
Operation 5: [Check] MUST answer EXACTLY ONE OF seen, not-seen.
Operation 6: [Check] MUST answer seen for an identity under guard.
Operation 7: [Check] MUST answer not-seen for an identity that is not under guard.
Deleted: Operation 8. Capability requirement 1 owns it.
Deleted: Operation 9. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Deleted: Operation 10. The section titled Logic Confinement Principle in `execution-contract.md` owns it.
Operation 11: The containing pattern MUST supply window duration.
Operation 12: The containing pattern MUST own the response to an answer.
```

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Record] | no | ok | enters under guard, recorded_at from the injected now (Operation 1, Operation 2) |
| [Record] | yes | ok | unchanged — the original recorded_at stands (Invariant 2.1, Invariant 2.2) |
| [Check] | yes | [Seen] | none — the call reads (Operation 6, Invariant 3.1) |
| [Check] | no | [Not Seen] | none — the call reads (Operation 7, Invariant 3.1) |

A failed store write sits outside the table: [Record] still answers ok, and the guard is missed rather than refused (Record failure 1 through 3).

Term now: the wall-time reading the host takes at the seam and hands to the transition, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never read inside the transition, never supplied by the business caller.

Term transition: the atom's evaluation of one call against the recorded set, as the section titled Logic Confinement Principle in `execution-contract.md` declares it.

Term seam: the atom's I/O boundary as the section titled Logic Confinement Principle in `execution-contract.md` declares it; the host injects the clock reading here.

Term business caller: the party whose action the call carries, as the section titled Logic Confinement Principle in `execution-contract.md` declares it; never the source of an injected value.

WHY:
Both calls are total. The containing pattern has already acted when it records — the item is already removed, the charge already made — so a refusal would have nothing to roll back, and a failed write is a liveness miss rather than a safety violation (Operation 4, Record failure 1 through 3). [Check] reads and nothing else, which is what makes asking twice safe (Invariant 3.1). The clock is read once, at the seam, and handed in: a transition reading a clock of the transition's own would answer two ways for one input (the section titled Logic Confinement Principle in `execution-contract.md`). What a seen answer means — reject, absorb, replay a cached result — is the containing pattern's to decide, and the atom is useful across four domains because the atom never decides it (Operation 12).

### Invariants

- **Invariant 2 — Single-recording.**
  ```
  Invariant 2.1: [Record] MUST NOT extend the guard of an identity under guard.
  Invariant 2.2: [Record] MUST preserve the recorded_at of an identity under guard.
  Invariant 2.3: [Record] MUST open a fresh guard for an identity that is not under guard.
  Deleted: Invariant 1. Operation 6 and Operation 7 own it.
  ```
  WHY: the deleted invariant claimed EVERY identity in the recorded set stands under guard, unconditionally, and a WHY beside it narrowed the claim to an eager host — a rule whose scope lived on a surface Surface 15 tells the parser to ignore and Surface 9 lets a writer delete. The atom sells behaviour rather than storage, which the rules already say in both directions: Operation 6 answers seen for an identity under guard and Operation 7 answers not-seen for one that is not, so nothing remained for the invariant to own. Restating it as the answer claim — *EVERY identity the check answers seen for MUST stand under guard* — was considered and refused: that is Operation 7's contrapositive, one proposition under a second label, which is the defect rather than the cure (Authority 3, council read 52).
  WHY: the clock starts at the first sighting and runs out at a fixed instant, so a flurry of repeats cannot hold an identity blocked past the term the containing pattern asked for. An expired entry a host has not yet dropped is not under guard, and a record against it opens a new guard rather than reviving the old one (Invariant 2.3).
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
  WHY: both rules stated the comparison in raw operators — `EXCEEDS window duration` — where the spec already declares under guard as *elapsed term less than window duration* and Operation 6 and Operation 7 route through it. The two spellings disagree at exactly one instant: at `elapsed term = window duration` an identity is not under guard, so the then-standing window-monotonicity invariant required it out of the recorded set while the old Invariant 4.1 obliged no host to drop it. Routing through the declared term closes the boundary with no new operator, which is the cure the `≥` docket row asks whether the grammar needs — and one site fewer that it does (council read 51).

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
Check 1.1: An auditor MUST find EXACTLY ONE recorded_at PER identity the recorded set holds (State 1).
Check 1.2: An auditor MUST find an identity's recorded_at unchanged across a second record inside the identity's window (Invariant 2.2).
Check 1.3: An auditor MUST find no guard extended by a second record (Invariant 2.1).
Check 1.4: An auditor MUST find a fresh recorded_at for a record against an identity that is not under guard (Invariant 2.3).
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
External check 3: An auditor needing a guard miss confirmed MUST read the deployment's own store (Record failure 2).
External check 4: An auditor needing the recorded set's durability confirmed MUST read the deployment's own store (Non-goal 3).
External check 5: An auditor needing the unavailability policy confirmed MUST read the deployment's own declaration (Check unavailability 1).
External check 6: An auditor needing the clock's honesty confirmed MUST read the deployment's own clock discipline (Non-goal 12).
```

WHY:
The three checks worth the section are `Check 1.2`, `Check 1.3` and `Check 2.1`, because they are what a composing pattern's own guarantee rests on and none of them was testable before. Idempotent Reservation's exactly-once claim holds only if a repeat record does not move the stamp — that is the whole of the window's monotonicity, it clears from two readings of one entry, and it was asserted by an invariant nothing audited.

`Check 3.4` is the one a reader does not expect and the one that proves the atom sells behaviour rather than storage. A lazy host still holding an expired entry must answer not-seen for it, so an auditor who finds the entry present and the answer not-seen has confirmed conformance rather than found a leak — and an auditor told only to compare the set against the window would report the opposite.

The external set is short and each member is a value the records cannot carry. The window duration and the matching rule belong to the containing pattern by construction (`Non-goal 8`); a guard missed by a failed write leaves no trace at all, which is `Record failure 2` stated from the auditor's side; and the unavailability policy is a deployment's declared posture rather than an observation.

## Non-goals

```
Non-goal 1: The atom MUST NOT decide the containing pattern's response to an answer.
Non-goal 2: The atom MUST NOT require a recorded set that survives a restart.
Non-goal 3: The deployment MUST own whether the recorded set survives a restart.
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

WHY:
The atom reports and the containing pattern decides, which is how one mechanic covers rejection, silent absorption and cached replay (Non-goal 1). Durability and clustering are deployment questions: a volatile in-memory set is a valid implementation, and keeping two of them consistent is a Coordination pattern *(forthcoming)*, not this atom (Non-goal 2 through 5). The set is short-term memory, not history; an Audit pattern owns the long view (Non-goal 6, Non-goal 7). A guard that resets on every sighting is the opposite of Invariant 2 and therefore a different concept, Sliding Window *(forthcoming)* (Non-goal 9). *Same day* is not *within twenty-four hours* — it is timezone-sensitive and daylight-saving-sensitive, and a Calendar Day pattern *(forthcoming)* owns it (Non-goal 10, Non-goal 11).

Where the pattern breaks down: when *recent* is measured by something other than wall-time elapsed. Number of intervening events, calendar-day boundaries and business-day boundaries each take a separate concept.

## Edge cases

### Clock semantics

```
Clock semantics 1: The atom MUST anchor a guard to the injected now of the opening record.
Deleted: Clock semantics 2. Non-goal 12 owns it.
Deleted: Clock semantics 3. Non-goal 13 owns it.
```

WHY:
The guard is wall-time. A backward jump can make an identity read as expired before the term truly elapsed; a forward jump can delay expiry. The atom commits to reading the clock at the seam and to nothing else about the clock (Operation 8).

Clock semantics 1 stays under this heading rather than under Clock dependence: it is this atom's one use of the reading, an instance of that family's question rather than a statement of it (council read 75).

### Check store unavailability

```
Check unavailability 1: The deployment MUST declare EXACTLY ONE OF fail-open, fail-closed.
Check unavailability 2: A fail-open implementation MUST proceed as not-seen.
Check unavailability 3: A fail-closed implementation MUST proceed as seen.
Check unavailability 4: The atom MUST NOT mandate the policy.
```

WHY:
Fail-open risks accepting a duplicate; fail-closed risks refusing a first attempt. Which cost is the lower one is a property of the deployment, not of the concept — a comment box and a payment processor answer differently (Check unavailability 4).

### Lazy expiry

```
Lazy expiry 1: A host MAY drop an identity that is not under guard at the moment a question is asked.
Lazy expiry 2: A host MAY drop an identity that is not under guard on a schedule.
Lazy expiry 3: A lazy host MUST answer not-seen for an identity the lazy host still holds.
```

WHY:
The atom claims behaviour and not storage, which is why the two host modes are indistinguishable to a caller: Operation 7 answers not-seen for an identity that is not under guard whether or not the host has physically dropped it, and Lazy expiry 3 says so for the entry a lazy host still holds. The physical removal is an implementation's business, and when it happens is Invariant 4.1's eventual claim rather than a moment any rule names (Lazy expiry 1, Lazy expiry 2).

### Record storage failure

```
Record failure 1: [Record] MUST NOT refuse on a failed write.
Record failure 2: The atom MUST treat a failed write as a guard miss.
Record failure 3: The atom MUST NOT treat a failed write as a safety violation.
Record failure 4: A deployment whose duplicate prevention is safety-critical MUST supply a durable recorded set.
```

WHY:
A failed write leaves the identity unguarded, and checks during the term that should have been covered answer not-seen — duplicates get through, which is the liveness side of the contract. Nothing false is asserted, and there is nothing to roll back, because the containing pattern acted before the call (Operation 4).

## Composition notes

Three compositions name this atom: [Idempotent Reservation](../compositions/idempotent-reservation.md), [Preference-Aware Notification Fanout](../compositions/preference-aware-notification-fanout.md) and [Reserve from Pool](../compositions/reserve-from-pool.md). What a containing pattern owes is stated where the atom's operations are — the window duration (Operation 11) and the response to an answer (Operation 12) — and is not restated here.

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host (also: a host, a lazy host); the transition; a containing pattern (also: the containing pattern, a pattern); a business caller; an implementation (also: a fail-open implementation, a fail-closed implementation); the deployment (also: a deployment); an identity; a guarded entry; an entry; a check; an auditor.

Term records: recorded set — the identities under guard, one recorded_at per entry.

Term record verbs: identify, treat, interpret, normalize, supply, hold, derive, stamp, place, answer, refuse, read, own, stand, extend, preserve, open, drop, alter, decide, require, survive, reconcile, compose, retain, proceed, mandate, declare, anchor, correct, find.

Term value sets: store policy = fail-open | fail-closed.

Term bounds: window duration (the length a containing pattern chooses for a guard; window is the lowering token the [Window Duration] term entry carries).

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11); under guard — recorded, and the guard's term not yet elapsed.

Term terms: identity, matching rule, recorded set, recorded_at, window duration, elapsed term, under guard, now, transition, seam, business caller.

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

#### Recorded At

The moment an [Identity] was placed under guard — the per-entry timestamp the guard window is measured from. It is stamped from the injected [Now] on the [Record] that opens the guard, and a [Record] on an already-guarded [Identity] leaves it unchanged (single-recording). It is the only datum the [Recorded Set] carries per entry beyond the [Identity] itself.

Kind:       Field
Field of:   Recorded Set
Projection: recorded_at

#### Window Duration

The length the containing pattern chooses for a [Window] — how long a recently-recorded [Identity] stays guarded. It is supplied by the containing pattern per use (24 hours for a to-do list, minutes for a payment), sizes the [Window] but is not itself part of the concept's state, and is the value the expiry comparison measures [Now] − [Recorded At] against.

Kind:         Parameter
Parameter of: Record
Projection:   window

#### Now

The current wall-time reading the [Record] and [Check] behaviors evaluate against, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller). [Record] stamps [Recorded At] from it; [Check] compares it against the [Window] to decide [Seen] versus [Not Seen].

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
[Recorded At]: #recorded-at
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

`grounded on Final Critique 4 — 2026-06-18` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-06-18
formal: verified — duplicate-prevention.tla + 1 twin, 2026-06-03
last gate: 2026-06-18 — Final Critique 4, fresh reader — clean

open: none
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/duplicate-prevention.md`.

- **2026-09-11 — Rewritten in GRACE lang v0.34; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the two calls as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged, Non-goals and Edge cases as two sections. *Over:* the prose spec. *Because:* the migration plan — atoms first, since they declare the vocabulary the compositions cite.

- **2026-09-14 — The atom gained an acceptance surface, written from the atom's own rules.** *Chose:* eleven `Check` rules and six `External check` rules, each naming the rule the check tests. *Over:* declining by delegation, which the amended rule admits and this atom cannot honestly take. *Because:* presence became mandatory for every migrated spec on 2026-09-14 (the section titled Generation acceptance in `pressure-testing.md`), and this atom is the one where the absence cost most: a composing pattern's exactly-once guarantee rests on a repeat record not moving the stamp, which is `Invariant 2.2`, and nothing audited it. Every check clears from the recorded set and the atom's own query surface; none invents an obligation, which is what *the bar reduces to the invariants hold* was always asserting and never made testable (council read 65).

NOTE: End of Duplicate Prevention.

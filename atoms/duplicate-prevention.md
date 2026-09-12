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

```text
Identity 1: The atom MUST identify a guarded entry by the identity.
Identity 2: The atom MUST treat an identity as opaque.
Identity 3: The atom MUST NOT interpret an identity.
Identity 4: The atom MUST NOT normalize an identity.
Identity 5: The containing pattern MUST supply the matching rule.
```

Terms › `identity`: the opaque value a containing pattern asks the atom to remember and recognize — an [Identity].

Terms › `matching rule`: the containing pattern's rule for judging two identities the same — string equality, case-insensitive, trimmed, normalized, hashed.

WHY:
The atom stores a value and compares a value; what counts as *the same thing seen again* is the containing pattern's question. That is why one mechanic serves a to-do title, a payment key and a normalized comment body without a line of difference (Identity 3–5).

### State

```text
State 1: The host MUST hold EXACTLY ONE recorded_at per guarded identity.
State 2: The host MUST derive under guard from the elapsed term at the moment a question is asked.
State 3: The atom MUST NOT hold state beyond the recorded set.
```

Terms › `recorded set`: the identities under guard, each held with the identity's `recorded_at` — the [Recorded Set].

Terms › `recorded_at`: the instant an identity was placed under guard, stamped from the injected `now` — a [Recorded At].

Terms › `window duration`: the length a containing pattern chooses for a guard — a [Window Duration]; the value the elapsed term is measured against. The [Window] the length sizes is the interval, and carries no separate name in a rule.

Terms › `elapsed term`: `now − recorded_at`.

Terms › `under guard`: an identity in the recorded set whose elapsed term is less than `window duration` — the state [Check] answers `seen` for.

WHY:
One set and one stamp per entry are the whole of the atom's storage, and *under guard* is derived at the moment of the question rather than stored. That is what lets a host implement the atom over a store offering nothing but a key with an expiry (State 2).

### Operations

```
record(identity) → ok
check(identity) → seen | not-seen
```

```text
Operation 1: [Record] MUST place an identity that is not under guard under guard.
Operation 2: [Record] MUST stamp recorded_at from the injected now.
Operation 3: [Record] MUST answer ok.
Operation 4: [Record] MUST NOT refuse.
Operation 5: [Check] MUST answer EXACTLY ONE OF seen, not-seen.
Operation 6: [Check] MUST answer seen for an identity under guard.
Operation 7: [Check] MUST answer not-seen for an identity that is not under guard.
Operation 8: The host MUST read the clock at the atom's seam.
Operation 9: The transition MUST NOT read a clock.
Operation 10: The business caller MUST NOT supply now.
Operation 11: The containing pattern MUST supply window duration.
Operation 12: The containing pattern MUST own the response to an answer.
```

The case space, and the rule that owns each case:

| Call | Identity under guard? | Answer | Effect on the recorded set |
|---|---|---|---|
| [Record] | no | `ok` | enters under guard, `recorded_at` from the injected `now` (Operation 1, Operation 2) |
| [Record] | yes | `ok` | unchanged — the original `recorded_at` stands (Invariant 2.1, Invariant 2.2) |
| [Check] | yes | [Seen] | none — the call reads (Operation 6, Invariant 3.1) |
| [Check] | no | [Not Seen] | none — the call reads (Operation 7, Invariant 3.1) |

A failed store write sits outside the table: [Record] still answers `ok`, and the guard is missed rather than refused (Record failure 1–3).

Terms › `now`: the wall-time reading the host takes at the seam and hands to the transition, as `execution-contract.md` §Logic confinement declares it; never read inside the transition, never supplied by the business caller.

Terms › `transition`: the atom's evaluation of one call against the recorded set, as `execution-contract.md` §Logic confinement declares it.

Terms › `seam`: the atom's I/O boundary as `execution-contract.md` §Logic confinement declares it; the host injects the clock reading here.

Terms › `business caller`: the party whose action the call carries, as `execution-contract.md` §Logic confinement declares it; never the source of an injected value.

WHY:
Both calls are total. The containing pattern has already acted when it records — the item is already removed, the charge already made — so a refusal would have nothing to roll back, and a failed write is a liveness miss rather than a safety violation (Operation 4, Record failure 1–3). [Check] reads and nothing else, which is what makes asking twice safe (Invariant 3.1). The clock is read once, at the seam, and handed in: a transition reading a clock of the transition's own would answer two ways for one input (Operation 8, Operation 9). What a `seen` answer means — reject, absorb, replay a cached result — is the containing pattern's to decide, and the atom is useful across four domains because the atom never decides it (Operation 12).

### Invariants

- **Invariant 1 — Window monotonicity.**
  ```text
  Invariant 1.1: EVERY identity in the recorded set MUST stand under guard.
  ```
  WHY: the invariant holds over an eager host's stored state; a lazy host keeps the behavior and not the storage claim (Lazy expiry 1–3).
- **Invariant 2 — Single-recording.**
  ```text
  Invariant 2.1: [Record] MUST NOT extend the guard of an identity under guard.
  Invariant 2.2: [Record] MUST preserve the recorded_at of an identity under guard.
  Invariant 2.3: [Record] MUST open a fresh guard for an identity that is not under guard.
  ```
  WHY: the clock starts at the first sighting and runs out at a fixed instant, so a flurry of repeats cannot hold an identity blocked past the term the containing pattern asked for. An expired entry a host has not yet dropped is not under guard, and a record against it opens a new guard rather than reviving the old one (Invariant 2.3).
- **Invariant 3 — Idempotency of check.**
  ```text
  Invariant 3.1: [Check] MUST NOT alter the recorded set.
  Invariant 3.2: Two checks of one identity under one now MUST answer alike.
  ```
- **Invariant 4 — Eventual expiry.**
  ```text
  Invariant 4.1: IF the elapsed term EXCEEDS window duration THEN the host MUST drop the identity from the recorded set.
  Invariant 4.2: IF the elapsed term EXCEEDS window duration THEN [Check] MUST answer not-seen.
  ```

## Examples

### Personal Todo (24-hour window)

A user deletes *"buy milk."* Personal Todo calls [Record] with `"buy milk"`. Two hours later, the user attempts to add *"buy milk"* again. Personal Todo calls [Check] with `"buy milk"`, receives [Seen], rejects the add as `duplicate-recent`. Twenty-five hours after the original delete, the user tries again. Personal Todo calls [Check] with `"buy milk"`, receives [Not Seen], accepts the add.

(`duplicate-recent` is shown verbatim by design: it is the **composing pattern's** pinned rejection string — neither this atom's nor Personal Todo's, since neither raises it; it exists only where the two are wired together, and its wire form is frozen because callers switch on the exact string. It is not this atom's Term; when Personal Todo carries a Terms registry it becomes a cross-page reference to that pattern's card. Per [`annotation.md`](../working-ideas/annotation.md), a pinned wire literal shown to display its exact form stays backticked — "literal" is a pinned projection, not a kind.)

### Comment double-post protection (60-second window)

A user submits a comment, the page hangs, they click submit again. The comment system calls [Record] with the normalized comment text after the first submission completes. The second click triggers [Check], receives [Seen], rejects the second post. The first comment goes through; the second does not.

### Payment idempotency (5-minute window)

A payment processor receives a charge request with an idempotency key. It calls [Check] with the key, receives [Not Seen], processes the charge, calls [Record] with the key and the response cached against it. A retry within five minutes triggers [Check] with the key, receives [Seen], returns the previously-cached result without re-processing.

### Newsletter double-subscribe (1-hour window)

A user submits the same email address to a newsletter form twice in quick succession (browser back button, double-click on submit). The first submission processes. Subsequent submissions within the hour trigger [Seen] and are silently absorbed-as-already-subscribed rather than producing duplicate confirmation emails.

The mechanic is identical across all four. What differs: the [Window Duration], the identity-matching rule, and the containing pattern's response on [Seen] (reject, return-cached, silently-absorb).

---

## Non-goals

```text
Non-goal 1: The atom MUST NOT decide the containing pattern's response to an answer.
Non-goal 2: The atom MUST NOT require a recorded set that survives a restart.
Non-goal 3: The deployment MUST own whether the recorded set survives a restart.
Non-goal 4: The atom MUST NOT reconcile two recorded sets.
Non-goal 5: A pattern needing one guard across every node MUST compose a coordination pattern.
Non-goal 6: The atom MUST NOT retain an identity past the guard.
Non-goal 7: A pattern needing long-term history MUST compose an audit pattern.
Non-goal 8: The atom MUST NOT supply the matching rule.
Non-goal 9: A pattern needing a guard that resets on every sighting MUST compose a sliding-window pattern.
Non-goal 10: The atom MUST NOT read a calendar.
Non-goal 11: A pattern needing day-boundary semantics MUST compose a calendar-day pattern.
```

WHY:
The atom reports and the containing pattern decides, which is how one mechanic covers rejection, silent absorption and cached replay (Non-goal 1). Durability and clustering are deployment questions: a volatile in-memory set is a valid implementation, and keeping two of them consistent is a Coordination pattern *(forthcoming)*, not this atom (Non-goal 2–5). The set is short-term memory, not history; an Audit pattern owns the long view (Non-goal 6, Non-goal 7). A guard that resets on every sighting is the opposite of Invariant 2 and therefore a different concept, Sliding Window *(forthcoming)* (Non-goal 9). *Same day* is not *within twenty-four hours* — it is timezone-sensitive and daylight-saving-sensitive, and a Calendar Day pattern *(forthcoming)* owns it (Non-goal 10, Non-goal 11).

Where the pattern breaks down: when *recent* is measured by something other than wall-time elapsed. Number of intervening events, calendar-day boundaries and business-day boundaries each take a separate concept.

## Edge cases

### Record storage failure

```text
Record failure 1: [Record] MUST NOT refuse on a failed write.
Record failure 2: The atom MUST treat a failed write as a guard miss.
Record failure 3: The atom MUST NOT treat a failed write as a safety violation.
Record failure 4: A deployment whose duplicate prevention is safety-critical MUST supply a durable recorded set.
```

WHY:
A failed write leaves the identity unguarded, and checks during the term that should have been covered answer `not-seen` — duplicates get through, which is the liveness side of the contract. Nothing false is asserted, and there is nothing to roll back, because the containing pattern acted before the call (Operation 4).

### Check store unavailability

```text
Check unavailability 1: The deployment MUST declare EXACTLY ONE OF fail-open, fail-closed.
Check unavailability 2: A fail-open implementation MUST proceed as not-seen.
Check unavailability 3: A fail-closed implementation MUST proceed as seen.
Check unavailability 4: The atom MUST NOT mandate the policy.
```

WHY:
Fail-open risks accepting a duplicate; fail-closed risks refusing a first attempt. Which cost is the lower one is a property of the deployment, not of the concept — a comment box and a payment processor answer differently (Check unavailability 4).

### Clock semantics

```text
Clock semantics 1: The atom MUST anchor a guard to the injected now of the opening record.
Clock semantics 2: The atom MUST NOT correct clock skew.
Clock semantics 3: A pattern needing a strictly monotonic guard MUST compose a logical-clock pattern.
```

WHY:
The guard is wall-time. A backward jump can make an identity read as expired before the term truly elapsed; a forward jump can delay expiry. The atom commits to reading the clock at the seam and to nothing else about the clock (Operation 8).

### Lazy expiry

```text
Lazy expiry 1: A host MAY drop an expired entry at the moment a question is asked.
Lazy expiry 2: A host MAY drop an expired entry on a schedule.
Lazy expiry 3: A lazy host MUST answer not-seen for an expired entry.
```

WHY:
Invariant 1.1 is a claim about stored state and holds of an eager host. A lazy host keeps expired entries until something asks, so the claim does not hold of that host's storage — but Invariant 4.2 does, and the behavior a caller sees is identical. The physical removal is an implementation's business (Lazy expiry 1, Lazy expiry 2).

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host (also: a host, a lazy host); the transition; a containing pattern (also: the containing pattern, a pattern); a business caller; an implementation (also: a fail-open implementation, a fail-closed implementation); the deployment (also: a deployment); an identity; a guarded entry; an entry; a check.

Terms › `records`: `recorded set` — the identities under guard, one `recorded_at` per entry.

Terms › `record verbs`: identify, treat, interpret, normalize, supply, hold, derive, stamp, place, answer, refuse, read, own, stand, extend, preserve, open, drop, alter, decide, require, survive, reconcile, compose, retain, proceed, mandate, declare, anchor, correct.

Terms › `value sets`: check answers = seen | not-seen. record answers = ok. store policy = fail-open | fail-closed.

Terms › `bounds`: `window duration` (the length a containing pattern chooses for a guard; `window` is the lowering token the [Window Duration] card carries).

Terms › `cadences`: empty.

Terms › `qualifiers`: `migrated` — rewritten in GRACE lang v0.35 (2026-09-11); `under guard` — recorded, and the guard's term not yet elapsed.

Terms › `terms`: `identity`, `matching rule`, `recorded set`, `recorded_at`, `window duration`, `elapsed term`, `under guard`, `now`, `transition`, `seam`, `business caller`.

#### Identity

The value a containing pattern asks Duplicate Prevention to remember and recognize — what counts as "the same thing seen again." The concept treats it as opaque: it stores and compares the value but never interprets it, and how two identities are judged equal is the containing pattern's matching rule, not this atom's.

Kind: Type

#### Window

The bounded interval of time during which a recently-recorded [Identity] is still guarded. It opens when the [Identity] is first recorded and closes after a [Window Duration] the containing pattern sets; once it has elapsed, the same [Identity] is fresh again. (The interval is the concept; the duration value that sizes it is a separate [Window Duration] supplied per containing pattern.)

Kind: Type

#### Recorded Set

The atom's short-term memory: the collection of identities currently under guard, each held together with the time it was recorded. An [Identity] enters on [Record] and leaves automatically once its [Window] has elapsed. It is an internal mechanism, queryable for diagnostics, not a user-facing surface.

Kind:     Type
Projects: recorded

#### Record

The behavior a containing pattern invokes when it has just observed an [Identity] (for example, after removing an item) so that future repeats can be recognized. It places the [Identity] under guard, opening a [Window]. It always succeeds — it never refuses — and recording an [Identity] that is already under guard does not push its [Window] forward.

Kind: Operation

#### Check

The behavior a containing pattern invokes before accepting a new [Identity], to ask whether that [Identity] is currently under guard. It only reads — it changes nothing — and reports its answer as [Seen] or [Not Seen]. What to do with the answer is the containing pattern's decision.

Kind: Operation

#### Seen

The answer [Check] gives when the [Identity] is currently under guard — recorded, and still within its [Window]. It signals "this was observed recently"; the containing pattern decides whether that means reject, de-duplicate, or return an earlier result.

Kind:      Member
Member of: the Check outcome
Role:      Outcome
Projects:  seen

#### Not Seen

The answer [Check] gives when the [Identity] is not currently under guard — either never recorded, or its [Window] has elapsed. It signals "this is fresh"; the containing pattern is clear to proceed.

Kind:      Member
Member of: the Check outcome
Role:      Outcome
Projects:  not-seen

#### Recorded At

The moment an [Identity] was placed under guard — the per-entry timestamp the guard window is measured from. It is stamped from the injected [Now] on the [Record] that opens the guard, and a [Record] on an already-guarded [Identity] leaves it unchanged (single-recording). It is the only datum the [Recorded Set] carries per entry beyond the [Identity] itself.

Kind:     Field
Field of: Recorded Set
Projects: recorded_at

#### Window Duration

The length the containing pattern chooses for a [Window] — how long a recently-recorded [Identity] stays guarded. It is supplied by the containing pattern per use (24 hours for a to-do list, minutes for a payment), sizes the [Window] but is not itself part of the concept's state, and is the value the expiry comparison measures [Now] − [Recorded At] against.

Kind:         Parameter
Parameter of: Record
Projects:     window

#### Now

The current wall-time reading the [Record] and [Check] behaviors evaluate against, supplied to the pure transition by the host at the I/O seam (never read inside the transition, never supplied by the business caller). [Record] stamps [Recorded At] from it; [Check] compares it against the [Window] to decide [Seen] versus [Not Seen].

Kind:         Parameter
Parameter of: Check
Projects:     now

<!-- Term registry — shortcut-reference definitions. These produce no visible
     output; each resolves a [Term] marker to its card heading above (kramdown
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

NOTE: End of Duplicate Prevention.

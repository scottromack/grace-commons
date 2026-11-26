---
title: Lease
id: 43
audience: common
has_toc: true
toc: true
---

# Lease

## What it is

A **lease** lets one worker have a thing to itself until a set time. The worker asks for the thing by its name (the key), gets it until, say, 10:00:30, does its work and hands it back. If it never hands it back — it crashed, hung or lost the network — the thing frees itself at 10:00:30, and the next worker waits no longer than that. Stated exactly, a lease is a grant of exclusive standing over a key, to a named holder, until a declared instant.

The whole of the atom is one sentence and its consequences: **the grant ends at the instant, never at an event.** Nothing in a distributed system can tell a dead worker from a slow one, so a grant that ended when its worker looked dead would end on a guess. A lease therefore ends in exactly two ways — the holder releases it, or the instant passes — and every other property here follows from that.

The instant is a value the holder can pass on. A holder may hand it, less a safety allowance, to a third party such as a database as a **fence**: a deadline after which that party refuses the holder's work. A worker that slept through its time and wakes to write finds its write refused there.

<details markdown="block">
<summary>WHY</summary>

A pattern that needs one writer at a time on a key, where a writer can stop without notice, needs a claim that ends on its own, a way to ask how much of the claim is left, and a deadline it can hand to the systems it writes to. The concept has its own state machine, its own operations and its own failure mode, and it belongs to none of the patterns that use it, so a pattern needing exclusive standing over a key cites this atom rather than restating it, and the argument for the one hard rule — the terminus is an instant — is made once, where it can be attacked once. It is deliberately small: a lease does not decide who should hold it, does not record that it was held, and does not know what the holder does; the holder's own discipline for writes no fence guards is stated here as rules a composing pattern takes as its own (Composition note 8).

</details>

## What it keeps

### The empties

```
Identity 1: The atom MUST identify a lease by the pair (key, holder).
Identity 2: The atom MUST compare keys by byte identity.
Identity 3: The atom MUST NOT normalize a key.
Identity 4: The atom MUST compare holders by byte identity.
Identity 6: A caller MUST mint a fresh holder value for EVERY take.
Identity 7: A process that restarts MUST NOT carry a holder value across the restart.
```

Term fresh holder value: a holder value no earlier take on the key carried.

```
State 1: The host MUST hold EXACTLY ONE lease state per key.
State 2: The host MUST derive free from a passed instant at the moment a question is asked.
State 3: The host MUST NOT store a transition for a passed instant.
State 4: The host MUST hold the line of waiters on a key, EVERY waiter with the waiter's bound.
```

Term lease state: free | held — held by one holder until one instant.

Term passed instant: an expires_at the host's reading does not precede; the key is free at the reading that equals expires_at.

Term host's reading: the reading of the granting host's one clock at the moment a question is asked; never a caller's own reading.

#### Lease

A grant of exclusive standing over a key, to a named holder, until a declared instant. Ends at the instant or at the holder's release, and at nothing else.

Kind: Type

#### Expiry Instant

The absolute instant, on the granting host's clock, at which a grant ends. Returned by a successful take; the value a holder mints a fence from.

Kind: Field

#### Fence

An instant no later than expires_at less the allowance, handed to a third party as a deadline: refuse this holder's work unless the work takes effect before this instant. Judged on the third party's clock.

Kind: Type

Term fence: an instant no later than the fence ceiling, handed to a third party as a deadline (a [Fence]) — refuse this holder's work unless the work takes effect before this instant.

### Fence

```
Fence 1: A successful take MUST return expires_at as an absolute instant on the granting host's clock.
Fence 2: A holder MAY pass a fence to a third party.
Fence 3: The fenced party MUST admit a work item ONLY IF the work item's effect instant PRECEDES the fence.
Fence 4: The fenced party MUST judge the fence on the fenced party's own clock.
Fence 4a: The fenced party MUST judge the fence and apply the work item in one atomic step.
Fence 5: The fence ceiling MUST NOT PRECEDE a fence.
Fence 6: The fenced party MUST compare the fence bare.
Fence 8: A holder fencing two parties MUST mint EVERY fence separately.
Fence 9: A holder MUST NOT derive a second fence bare from a minted fence.
Fence 10: A work item MUST NOT carry an effect instant.
```

Term fence ceiling: `(expires_at - allowance)`.

Term effect instant: the instant a work item takes effect, read on the fenced party's own clock in the step that applies the work item.

Term bare: as the instant stands, no allowance added or subtracted; a fenced party compares a fence bare (Fence 6), and a holder derives no second fence bare from a minted one (Fence 9).

### Sizing

```
Sizing 1: A composing pattern MUST declare a [Call Pause Bound].
Sizing 2: IF the remaining term the host answers EXCEEDS the write margin AND unanswered EQUALS no THEN the holder MUST read the lease as live.
Sizing 2a: IF the remaining term the host answers DOES NOT EXCEED the write margin THEN the holder MUST read the lease as expired.
Sizing 2b: IF the [Remaining] answer EQUALS none THEN the holder MUST read the lease as expired.
Sizing 3: A holder MUST issue an unfenced write under a lease ONLY IF the write falls inside a unit of work started under Sizing 5 OR the holder read the lease live for that write.
Sizing 3a: A holder MUST issue a write admitted by a live reading WITHIN the [Call Pause Bound] of asking for the reading.
Sizing 4: The work's bound MUST include twice the [Call Pause Bound].
Sizing 4a: A holder MAY take a lease for unfenced work ONLY IF the duration EXCEEDS the work's bound.
Sizing 5: A holder MAY start a unit of work ONLY IF the remaining term the host answered for that unit EXCEEDS the unit's start floor AND unanswered EQUALS no.
Sizing 5b: A holder MUST take one [Remaining] reading for EVERY unit of work.
Sizing 5c: A holder MUST start a unit of work WITHIN the [Call Pause Bound] of asking for the unit's reading.
Sizing 5a: IF a unit's elapsed time EXCEEDS the unit's issue limit THEN the holder MUST NOT issue a write of the unit.
Sizing 5d: IF the call pause bound EXCEEDS a unit's bound the pattern declares THEN a pattern MUST refuse to start.
Sizing 6: A lease taken by [Try Take] for a share of a budget MUST carry the share term as duration.
Sizing 6a: A holder MUST NOT take a share of a budget by a blocking [Take].
Sizing 7: IF unanswered EQUALS yes THEN the holder MUST read the lease as expired for the rest of the grant.
Sizing 7a: IF unanswered EQUALS yes THEN the holder MUST NOT issue an unfenced write under the grant.
Sizing 8: A holder MUST NOT issue a second time, under one lease, a call that answered no answer.
Sizing 9: IF a work's bound the pattern declares DOES NOT EXCEED the write margin THEN a pattern MUST refuse to start.
```

Term unit's start: the moment the holder issues the unit's first call, after the [Remaining] call whose answer admits the unit (Sizing 5c).

Term work's bound: the bound the composing pattern declares on all the work under one lease, the take's answer, every reading and every unit's bound counted.

Term budget: a bound the composing pattern declares over work that began before the take, of which the lease is given a share.

Term write margin: `(2 * call_pause_bound)` — a check's answer and the write the check guards are two calls.

Term start floor: `(unit_bound + (2 * call_pause_bound))` — what a unit of work needs of the remaining term: one call pause from asking for the reading to the unit's start (Sizing 5c), the unit's bound, and one call pause left before the instant.

Term unit's elapsed time: the time since the unit's start, measured at the holder's own seam.

Term unit's issue limit: `(unit's bound - call pause bound)`, the elapsed time past which a unit issues no write, so a write issued at the limit lands inside the unit's bound.

Term share term: `((budget - time_spent_before_take) - call_pause_bound)`, the time spent measured at the holder's own seam.

Term live: a lease whose remaining term EXCEEDS the write margin, unanswered being no.

Term expired: a lease that is not live, a [Remaining] that answers none or no answer included — a reading the holder acts on, never a transition the host makes (Invariant 2.2).

Term unanswered: yes | no — yes for a grant under which a [Take], a [Try Take], a [Remaining] or a [Release] answered no answer, and for the rest of that grant.

Term no answer: a call that returns neither its answers nor a refusal within the call pause bound, or, for a blocking [Take], within the longest duration declared for the key and the call pause bound (Composition note 5d). Capability requirement 7 is the premise, holding every call to its effect or its failure inside the bound; a no answer stays reachable under the premise, since a call that took effect may still return nothing to the holder, and Sizing 7 and Sizing 8 are the holder's fallback for that call.

<details markdown="block">
<summary>WHY</summary>

A unit's elapsed time and the time spent before a take are spans on the holder's own clock, never instants compared across two clocks; how far two clocks' rates may differ over a span is the deployment's (Execution Contract Logic confinement 7), and Capability requirement 12 is where the page relies on the rate: a holder clock that runs slow would let a write the holder times inside its bound land past the instant, when the next holder may already hold the key.

</details>

## What people do

### Every action

```
Operation 2a: A successful take MUST stand the key in held by the asking holder.
Operation 2b: A successful take MUST set expires_at from the host's reading at the success.
Operation 5: The host MUST NOT extend a waiter's bound.
Operation 5a: The host MUST admit waiters in arrival order.
Operation 5b: The host MUST NOT hold a waiter on the line past the waiter's last reading.
Operation 5c: The host MUST NOT admit a waiter that stood across a host restart.
Operation 10: A caller MUST NOT compute the remaining term from a remembered expires_at and the caller's own reading.
Operation 14: An implementer MUST NOT treat not-held as a failure.
```

Term remaining term: the part of a holder's term not yet elapsed, as the host reads the part.

Term waiting term: the term a waiter has stood at [Take], as the host reads the term.

Term waiter's bound: the instant a waiter stops standing at [Take] where the host admits the waiter at no earlier reading — the expires_at of the grant that held the key at the waiter's arrival, which is the waiter's arrival reading plus the arrival term (Term arrival term, Invariant 4.1); where the key is free at the waiter's arrival and no grant held it, the waiter's arrival reading, the arrival term being zero (Term arrival term, Operation 2c).

Term waiter's last reading: the first host reading at which a waiter's bound DOES NOT EXCEED the host's reading, a reading the bound and the host's clock fix and no act of the host moves; a waiter the host admitted at an earlier reading stopped standing at [Take] at the admission (Operation 2). A bound between two readings of the host's clock, which exact arithmetic allows (Execution Contract Logic confinement 9), is reached by the later one, so the waiter's last reading may follow the bound.

Term arrival term: the remaining term of the holder that held the key at the moment the waiter arrived; zero where the key is free at arrival.

Term arrival order: the order of the host readings at which the waiters' [Take] calls reached the host, two calls at one reading ordered as the host received them.

Term successful take: a [Take] that answers expires_at, or a [Try Take] that answers taken(expires_at).

Term expires_at: `(reading_at_success + duration)` — the instant a grant ends, on the granting host's clock; an [Expiry Instant]. The sum is exact, with no rounding to the clock's resolution (Execution Contract Logic confinement 9).

Term asking party: the party naming itself as holder in a [Remaining] or [Release] call.

<details markdown="block">
<summary>WHY</summary>

A host restart ends the line: a waiter the restarted host can no longer answer is neither admitted nor answered afterwards (Operation 5c, Operation 5d), so its caller reads no answer (Term no answer) and holds nothing; a grant standing at the restart stands after it (Capability requirement 5).

</details>

### Take

#### Take

The blocking acquisition. Waits at most until the waiter's last reading, and answers unavailable if the key is held again at that reading — an earlier waiter took it.

Kind: Operation

```
take(key, holder, duration)
  answers expires_at | unavailable
```

```
Operation 1: [Take] MUST wait for the key to become free.
Operation 1a: IF the lease state EQUALS free AND no waiter stands THEN [Take] MUST succeed at the reading the [Take] arrives at.
Operation 1b: [Take] MUST answer EXACTLY ONE OF expires_at, unavailable, a [Take] that waited across a host restart excepted.
Operation 2: The [Take] of the waiter first in arrival order MUST succeed at the first host reading at which the key is free.
Operation 2c: The host MUST admit a waiter at a host reading only once EVERY [Take] arriving at the reading stands in the line.
Operation 3: [Take] MUST NOT wait past the waiter's last reading.
Operation 4: IF a waiter's bound DOES NOT EXCEED the host's reading AND another holder holds the key THEN [Take] MUST answer unavailable.
Operation 5d: The host MUST NOT answer a [Take] that waited across a host restart.
```

### Try Take

#### Try Take

The non-blocking acquisition. Answers `taken(expires_at)` or held, immediately.

Kind: Operation

```
try_take(key, holder, duration)
  answers taken(expires_at) | held
```

```
Operation 6: [Try Take] MUST NOT wait.
Operation 6a: IF the lease state EQUALS free AND no waiter stands THEN [Try Take] MUST answer taken(expires_at).
Operation 6b: IF the lease state EQUALS held THEN [Try Take] MUST answer held.
Operation 6c: IF the lease state EQUALS free AND a waiter stands THEN [Try Take] MUST answer held.
Operation 7: [Try Take] MUST answer EXACTLY ONE OF taken(expires_at), held.
```

### Remaining

#### Remaining

The host query for how much of the asking holder's term is left, or none if the asking party is not the holder. Never a clock read by the caller.

Kind: Operation

```
remaining(key, holder)
  answers remaining_term | none
```

```
Operation 8: [Remaining] MUST answer the remaining term of the asking holder.
Operation 9: IF the asking party DOES NOT EQUAL the holder THEN [Remaining] MUST answer none.
```

### Release

#### Release

Ends the asking party's grant, or answers not-held if it has none. Never reaches another holder's grant.

Kind: Operation

```
release(key, holder)
  answers released | not-held
```

```
Operation 11: [Release] MUST end the asking holder's grant.
Operation 11a: IF the asking party EQUALS the holder THEN [Release] MUST answer released.
Operation 12: IF the asking party DOES NOT EQUAL the holder THEN [Release] MUST answer not-held.
Operation 13: [Release] MUST NOT reach another holder's grant.
```

## What is and what should never be (Invariants)

- **Invariant 1 — One holder.**
  ```
  Invariant 1.1: A key MUST stand in EXACTLY ONE OF free, held by one holder.
  Invariant 1.2: Two takes on one key with no intervening release and no intervening expiry MUST NOT succeed together.
  ```
- **Invariant 2 — The terminus is the instant.**
  ```
  Invariant 2.1: A grant MUST end at EXACTLY ONE OF release, instant.
  Invariant 2.2: The host MUST NOT end a grant on any other event.
  ```
- **Invariant 3 — Death is not observable.**
  ```
  Invariant 3.1: The atom MUST NOT report a holder's death.
  Invariant 3.2: An implementation MUST NOT end a grant early on a belief that the holder has died.
  ```
- **Invariant 4 — A waiter's bound is fixed at arrival.**
  ```
  Invariant 4.1: A waiter's bound MUST stand as set at the waiter's arrival.
  Invariant 4.2: Admitting an earlier waiter MUST NOT extend a later waiter's bound.
  ```
- **Invariant 5 — Standing is answered, never assumed.**
  ```
  Invariant 5.1: [Remaining] and [Release] MUST answer against the (key, holder) pair as the host holds the pair.
  ```
- **Invariant 6 — A fence instant carries its allowance.**
  ```
  Invariant 6.1: EVERY instant handed to a party judging on another clock MUST carry the allowance subtracted.
  Invariant 6.2: The holder MUST mint EVERY such instant independently.
  ```

## Optional

```
Capability requirement 1: The deployment MUST supply a host offering EVERY operation of the signature block.
Capability requirement 2: The deployment MUST share the host across every node of the instance.
Capability requirement 3: The deployment MUST declare the allowance for EVERY fenced party (Execution Contract Logic confinement 18).
Capability requirement 4: The deployment MUST supply a host that answers EVERY question on one key from one clock (Execution Contract Logic confinement 7).
Capability requirement 5: The deployment MUST supply a host that holds EVERY grant across a host restart.
Capability requirement 6: The deployment MUST supply fenced parties bound by Fence 3, Fence 4, Fence 4a, Fence 6 and Fence 10.
Capability requirement 7: The deployment MUST hold EVERY lease call and EVERY unfenced write a holder issues outside a unit of work, a blocking [Take] excepted, inside the call pause bound the composing pattern declares, a pause of the holder's own process included.
Capability requirement 8: The deployment MUST supply parties that answer a holder's write ONLY AFTER the write has taken effect.
Capability requirement 9: The deployment MUST NOT supply a party that applies a holder's write the party refused.
Capability requirement 10: The deployment MUST NOT supply a party that applies one write of a holder a second time.
Capability requirement 11: The deployment MUST NOT deliver one take to the host a second time.
Capability requirement 12: The deployment MUST supply holder clocks under which the host's measure of EVERY holder's span DOES NOT EXCEED the holder's measure of the span (Execution Contract Logic confinement 7).
Capability requirement 13: The deployment MUST hold EVERY write of a unit of work inside the unit's bound, a pause of the holder's own process included.
```

Term work item: a write a holder hands to a fenced party under a fence; the write and the call that carries it are one thing.

Term taken effect: a write has taken effect when the party it reached holds the write's change, so every later read at that party sees the change.

Term holder's span: a length a Sizing rule measures at the holder's own seam — a unit's elapsed time, the time spent before a take, and the time from asking for a reading to the write or the unit's start the reading admits.

#### Key

The opaque value a lease protects. Compared by byte identity, never normalized, meaningful only to the pattern that supplies it.

Kind: Parameter

#### Holder

The opaque value naming who holds a lease. Compared by byte identity. Minted fresh for every take, so it names one grant's holder and no other.

Kind: Parameter

#### Call Pause Bound

The longest time from a holder's decision to issue one call — a try-take, a lease check, a write under the lease, a delegation — to the moment the call has taken effect or failed; never a whole unit of work, and never a blocking take, whose wait Term no answer bounds. Declared by the composing pattern.

Kind: Parameter

Term key: the opaque value a lease protects — a [Key]; two keys that differ by a byte are two keys, each with its own lease state.

Term holder: the opaque value naming one take's holder — a [Holder]; minted fresh for every take, so a (key, holder) pair names one grant. A bearer value: the host knows a party only by the holder value the party names (Term asking party), so a party carrying the value is the holder for every rule that binds the holder, and the composing pattern keeps the value to the holder (Composition note 5a).

Term take: a [Take] or a [Try Take] call; to take is to make one.

Term process: the running program whose calls carry a holder value; a restart ends one process and starts another.

Term grant: one holding of a key by one holder, from a successful take to the grant's terminus — a [Lease].

Term question: a lease call, and a waiter's standing waiting term — the occasions State 2 derives at.

Term lease call: a [Take], a [Try Take], a [Remaining] or a [Release] call.

Term host: the capability that holds the lease states and answers the lease calls (Capability requirement 1); an adapter outside the Execution Contract's pipeline (Execution Contract Logic confinement 6), so the host reads the granting host's clock at every question and a blocking [Take] waits at the host, where a pipeline call reads the clock once (Execution Contract Logic confinement 3).

Term allowance: the declared cross-seam allowance between the granting host's clock and the judging party's clock; one allowance per fenced party.

Term fenced party: the third party a fence is handed to.

Term unfenced write: a write issued under a lease that carries no fence a fenced party judges; Sizing 2 through 9 bind EVERY unfenced write and no other write, and Sizing 1 binds EVERY composing pattern, since Capability requirement 7 and Term no answer read the call pause bound whatever the pattern's writes.

Term call pause bound: the longest time from a holder's decision to issue one call to the moment the call has taken effect or failed — a [Call Pause Bound]; the composing pattern declares it (Sizing 1).

Term unit of work: one bounded piece of work a holder starts under a lease — one call, or the calls a pattern bounds together.

Term unit's bound: the bound the composing pattern declares on a unit of work, from the unit's start to the landing of the unit's last write.

Term the holder: the party the host holds the key for.

## Offers

The bond this atom offers, of a bond kind [Bonds](../bonds.md) states.

Term offer guard: key opaque; holder opaque; span duration; calls take, try_take, remaining, release; arms take: expires_at, unavailable, no answer / try_take: taken, held, no answer / remaining: remaining_term, none, no answer / release: released, not-held, no answer.

## Left to others

```
Non-goal 2: The atom MUST NOT offer a depth count.
Non-goal 5: The atom MUST NOT make the work under a lease atomic.
Non-goal 6: The atom MUST NOT roll back work done under a lease.
Non-goal 7: The atom MUST NOT isolate a holder's partial work from a reader.
Non-goal 8: The atom MUST NOT write a record.
Non-goal 10: The atom MUST NOT choose a grant's duration, the share term of a share of a budget excepted (Sizing 6).
Non-goal 12: The atom MUST NOT choose the call pause bound.
Non-goal 12a: The atom MUST NOT choose a unit's bound.
Non-goal 13: The atom MUST NOT bound a lease call's inputs at the host.
Non-goal 14: The atom MUST NOT cap the line of waiters on a key.
```

NOTE: the owners — the composing pattern (Non-goal 2, Composition note 9; Non-goal 5, Non-goal 6, Non-goal 7, the pattern's own actions over the work; Non-goal 8, Composition note 10; Non-goal 10, Composition note 5, Composition note 11; Non-goal 12, Sizing 1; Non-goal 12a, Composition note 8a; Non-goal 13, the key, the holder value and the duration, Composition note 4, Composition note 5a, Composition note 5d, Composition note 5e); the deployment (Non-goal 14, Capability requirement 1).

Term call in flight: a call a holder issued under a grant that has returned neither an answer nor a refusal.

```
Composition note 1: A composing pattern MUST name this atom as a capability requirement.
Composition note 4: A composing pattern MUST own which key protects which work.
Composition note 5: A composing pattern MUST own how long the grant lasts, the share term of a share of a budget excepted (Sizing 6).
Composition note 5a: A composing pattern MUST own the holder value.
Composition note 5d: A composing pattern MUST declare the longest duration a take on a key asks for.
Composition note 5e: A caller MAY take ONLY IF the duration asked for EXCEEDS zero.
Composition note 5b: A composing pattern MUST own the release.
Composition note 5c: IF a call in flight EXISTS under a grant THEN the holder MUST NOT release the grant.
Composition note 5f: IF a holder has issued [Release] for a grant THEN the holder MUST NOT issue a write under the grant.
Composition note 6: A pattern fencing a downstream system MUST carry a fence per Fence 1 through 10.
Composition note 7: A pattern MUST NOT invent a second deadline concept for a fence.
Composition note 8: A pattern that issues an unfenced write under a lease MUST state Sizing 1 through 9 as the pattern's own obligations.
Composition note 8a: A pattern that issues an unfenced write under a lease MUST name which declared bound is each unit's bound.
Composition note 9: IF a grant a process took on a key stands THEN the process MUST NOT take the key, Composition note 9a excepted.
Composition note 9a: A process MAY take a key again, under a fresh holder value (Identity 6), after a take of the process answered no answer.
Composition note 10: A pattern that must prove a critical section was held MUST record the critical section.
Composition note 11: A pattern that needs the term to cover the pattern's work MUST state that obligation by Sizing 4a.
```

## Example

The examples share one composing pattern's numbers: a call pause bound of 2 s, so a write margin of 4 s; a unit's bound of 10 s, so a start floor of 14 s; host readings in seconds.

**A critical section around a write.** A process takes key `act-17` with holder value `h-91c2` for 30 s at host reading 1000 and receives expires_at 1030. Its writes carry no fence, so it asks the host what remains: at 1001 the answer is 29 s, above the start floor, and it starts a unit within 2 s of asking, whose writes land by 1013. At 1013 the answer is 17 s, and a second unit runs. At 1025 the answer is 5 s: below the start floor, so no unit starts, but above the write margin, so the lease reads live and one lone write issued by 1027 lands by 1029, before the instant. It releases and is answered released. A second process arriving at 1010 waits at most the first's remaining term, 20 s, and then either takes the key or is told unavailable because an earlier waiter took it first — and it writes only under a grant of its own.

**A fence carried to a database.** The same process passes expires_at less the database's allowance of 1 s, 1029, into the database call as a deadline. The process pauses for longer than anyone budgeted; its term passes at 1030; the key goes to the next holder. The paused process wakes at 1041 and issues its write anyway — and the database refuses it, because 1029 has passed on the database's own clock. The next holder's read is therefore complete: nothing of the previous holder's can still land.

**A holder that dies.** A process takes the key at 1000 for 30 s and is killed at 1005. Nothing is notified. The key stays held until 1030, and the next take waits exactly that long. This is the case that motivates Invariant 3: a host that released the key on the death would hand it over while the dead process's last write was still in flight.

**A call with no answer.** At 1013 the holder asks what remains and hears nothing within 2 s. It cannot tell whether the host answered into a lost reply, so for the rest of the grant it reads the lease as expired (Sizing 7): it issues no write, does not ask again (Sizing 8), and does not release, since the unanswered call is still in flight (Composition note 5c). The key frees at 1030.

**A release that finds not-held.** A holder pauses from 1020 to 1035 and, on waking, releases with `h-91c2`. Its term passed at 1030 and another process took the key at 1031 with holder value `h-4d07`, so the host answers not-held and the later grant stands (Operation 12, Operation 13). Not-held is no failure (Operation 14): it says the grant had already ended.

**A host restart.** The host restarts at 1012 while the key is held until 1030 and one waiter stands. The grant stands after the restart, and the key reads held until 1030 (Capability requirement 5). The waiter is neither admitted nor answered (Operation 5c, Operation 5d): its caller hears nothing within the longest duration declared for the key and one call pause, reads no answer, and holds nothing.

**A share of a budget.** A pattern must finish a request within a 60 s budget. It spent 22 s before reaching the key, so its share term is 60 − 22 − 2 = 36 s, and it takes the key by [Try Take] for 36 s (Sizing 6). The answer is held: it does not wait at a blocking [Take] (Sizing 6a), and what the request does without the key is the pattern's.

## Source

The concept is not itself regulated. It appears in regulated patterns as the mechanism by which a single-writer obligation is met, and those patterns anchor their own regimes; the atom's contribution is that the obligation is met by an argument stated once. The nearest external discipline is the fencing token of the distributed-systems literature on lock services, where a lock that ends on a belief about liveness is shown to admit two writers. Its cure differs from this one: a fencing token is a number that rises with every grant, which the store compares with the highest it has seen, where a fence here is a deadline the store judges on its own clock, less a declared allowance (Fence 3 through 6).

## Proof

### Generation acceptance

This atom writes no records, so its acceptance checks are conformance checks rather than an audit traversal: against a host implementation (Check 4.1 and Check 4.4 read its readings, so the auditor sets its clock), for the fence and the sizing against a holder, and for Capability requirement 8 through 13 against the deployment.

#### Conformance checks

```
Check 1.1: An auditor MUST confirm that two concurrent takes on one key, with no release and no expiry between the takes, yield EXACTLY ONE expires_at (Invariant 1.1, Invariant 1.2).
Check 1.2: An auditor MUST confirm that a [Try Take] on a held key answers held (Operation 6b, Operation 7).
Check 2.1: An auditor MUST confirm that a key held by a party that never releases becomes takeable at the instant (Invariant 2.1).
Check 2.2: An auditor MUST confirm that such a key does not become takeable earlier (Invariant 2.2).
Check 3.1: An auditor MUST confirm that the key of a killed holder reads held at EVERY host reading that PRECEDES the instant (Invariant 2.2, Invariant 3.2).
Check 3.2: An auditor MUST fail a host that frees the key of a killed holder earlier, whatever the host knows about the holder (Invariant 3.2).
Check 4.1: An auditor MUST confirm that [Take] answers a waiter by the first host reading that reaches the waiter's bound, and at the first host reading at which the key is free where the holder releases sooner (Invariant 4.1, Operation 2, Operation 3, Operation 4).
Check 4.2: An auditor MUST confirm that [Take] answers a second waiter by the first host reading that reaches the second waiter's own bound, a release by the admitted earlier waiter answering the second waiter sooner (Invariant 4.2, Operation 2, Operation 5).
Check 4.3: An auditor MUST confirm that a waiter standing at a host restart is neither admitted nor answered once the host restarts, and that a grant standing at the restart reads held at EVERY host reading that PRECEDES the grant's instant (Operation 1b, Operation 5c, Operation 5d, Capability requirement 5).
Check 4.4: An auditor MUST confirm that a [Take] on a free key with no waiter standing succeeds at the reading the [Take] arrives at, that a [Take] arriving at a reading at which the key is free and a waiter stands joins the line behind the waiter and is answered unavailable at that reading, that two waiters on one key are admitted in arrival order, that no waiter is admitted past the waiter's last reading, and that a [Try Take] on a free key with a waiter standing answers held (Operation 1a, Operation 2c, Operation 5a, Operation 5b, Operation 6c).
Check 5.1: An auditor MUST confirm that [Remaining] answers none and [Release] answers not-held to every party that is not the current holder, a former holder whose term has passed included (Invariant 5.1, Operation 9, Operation 12).
Check 5.2: An auditor MUST confirm that neither answer changes the lease state (Operation 13, State 3).
Check 5.3: An auditor MUST confirm that a release carrying the holder value of an ended grant answers not-held and leaves a later grant on the key standing (Identity 6, Operation 12).
Check 6.1: An auditor MUST confirm that the allowance does not exceed the fence margin of any handed instant (Fence 5, Invariant 6.1).
Check 6.2: An auditor MUST confirm that an instant derived from another is minted with the allowance rather than inheriting the allowance (Fence 8, Fence 9, Invariant 6.2).
Check 6.3: An auditor MUST confirm that a fenced party admits no work item whose effect instant falls at the fence or later, and judges in the step that applies the work item (Fence 3, Fence 4a).
Check 7.1: An auditor MUST confirm that a holder issues no unfenced write outside a started unit of work without a live reading taken for that write and followed inside one call pause bound, and no write of a unit whose elapsed time EXCEEDS the unit's issue limit (Sizing 2, Sizing 2a, Sizing 2b, Sizing 3, Sizing 3a, Sizing 5a).
Check 7.2: An auditor MUST confirm that every lease term set for unfenced work exceeds the work's bound and that the bound includes twice the call pause bound (Sizing 4, Sizing 4a).
Check 7.3: An auditor MUST confirm that no unit of work starts on a remaining term that does not exceed the unit's bound plus twice the call pause bound (Sizing 5).
Check 7.4: An auditor MUST confirm that a no answer is treated as expired, that the holder issues no unfenced write after a no answer and that the call is not re-issued within the lease (Sizing 7, Sizing 7a, Sizing 8).
Check 7.5: An auditor MUST confirm that the pattern refuses to start where a declared work bound does not exceed the write margin (Sizing 9).
Check 7.6: An auditor MUST confirm that a lease taken for a share of a budget is taken by [Try Take], never by a blocking [Take], with the share term as duration (Sizing 6, Sizing 6a).
Check 7.7: An auditor MUST confirm that every unit of work has one [Remaining] reading of the unit's own and starts within one call pause bound of asking for the reading (Sizing 5b, Sizing 5c).
Check 7.8: An auditor MUST confirm that a holder issues no [Release] of a grant with a call in flight under the grant, and no write under a grant the holder has released (Composition note 5c, Composition note 5f).
Check 7.9: An auditor MUST confirm that the pattern refuses to start where the call pause bound exceeds a declared unit's bound, whatever the declared work bound (Sizing 5d).
Check 8.1: An auditor MUST confirm that a party a holder writes to answers a write ONLY AFTER the write has taken effect (Capability requirement 8).
Check 8.2: An auditor MUST confirm that a party a holder writes to applies no write the party refused (Capability requirement 9).
Check 8.3: An auditor MUST confirm that a party a holder writes to applies no write of a holder a second time (Capability requirement 10).
Check 8.4: An auditor MUST confirm that the host receives no take a second time (Capability requirement 11).
Check 8.5: An auditor MUST confirm that no holder's span the host's clock measures exceeds the same span the holder's clock measures (Capability requirement 12).
Check 8.6: An auditor MUST confirm that every write of a unit of work lands inside the unit's bound (Capability requirement 13).
```

Term fence margin: `(expires_at - fence)`.

NOTE: EVERY check names the rule the check tests. A check that names none is a check whose failure nobody can state (council read 8).

### Vocabulary

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

Term actors: the atom; the host; a holder (also: the holder, the asking holder, the current holder, a former holder); a waiter; a caller; a party; the asking party; a third party (also: the fenced party, the judging party); an implementation (also: an implementer); a composing pattern (also: a pattern); the deployment; an auditor; a process; a key; a grant; a lease; a take; an instant; a work item.

Term records: empty — the atom writes nothing.

Term record verbs: identify, compare, normalize, hold, derive, store, wait, succeed, answer, extend, compute, end, reach, treat, return, pass, refuse, judge, mint, apply, stand, report, equal, take, offer, admit, carry, make, roll, isolate, write, record, choose, state, check, name, supply, share, own, invent, confirm, fail, declare, set, read, issue, start, include, release, deliver, bound, cap, land, measure.

Term value sets: lease state = free | held. grant terminus = release | instant. unanswered = yes | no.

Term bounds: duration (the term a take asks for); the allowance; the fence ceiling; the call pause bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11).

Term terms: fresh holder value, call in flight, unfenced write, key, holder, take, process, grant, waiter's bound, waiter's last reading, lease state, passed instant, host's reading, question, lease call, host, waiting term, remaining term, arrival term, arrival order, successful take, asking party, the holder, unit of work, unit's start, unit's bound, work's bound, budget, write margin, unanswered, start floor, unit's elapsed time, share term, work item, taken effect, holder's span, fence, fence ceiling, effect instant, allowance, fenced party, bare, fence margin, call pause bound ([Call Pause Bound]), live, expired, no answer, and expires_at ([Expiry Instant]).

[Key]: #key
[Call Pause Bound]: #call-pause-bound
[Holder]: #holder
[Take]: #take
[Try Take]: #try-take
[Remaining]: #remaining
[Release]: #release
[Expiry Instant]: #expiry-instant
[Fence]: #fence
[Lease]: #lease

## Status

`doing` — see the Ledger.

<details markdown="block">
<summary>
    <h2 id="ledger" style="display: inline-block; margin-left: 1.5rem;">Ledger</h2>
</summary>

```
status: doing
formal: verified — lease.tla + 6 twins + 1 probe (vote yes: one holder, the terminus, the fence and the write margin are temporal claims; 14,480 states, holding at clock bounds 8, 10 and 12; 2026-10-04); lease.als + 9 twins (the static data model, 2026-11-12: Invariant 1.1, 2.1, 2.2, 3.1, 3.2, 5.1, 6.1 and 6.2 checked on every lease state a successful take or a release answered released leaves, on what the host derives from it at one reading (State 2) and answers there whatever is believed about a holder's death, and on every instant a holder mints and hands a fenced party; Invariant 1, 2, 3.2 and 6.1 a cross-check with the TLA+ model; nothing testable in Alloy for Invariant 1.2, 2.1's release arm, 4.1 and 4.2: 1.2 orders two takes and a release is a step that stores free, and 4.1 and 4.2 compare a waiter's bound with the one its arrival set, which the host does not keep beside the bound (State 4), so one state cannot show them and they are the TLA+ model's); coverage 2026-11-10 (unit formal: more coverage for the yes votes): owes a TLA+ check of Invariant 4.2 (a second waiter, across steps); owed rows: Invariant 4.2; 2a: Sizing 3a — held as an invariant: the model clock and Pause bound it (Inv_NoLateWrite, twin lease-buggy-margin); no row owed, 2026-11-12; Capability requirement 12 (a holder clock measures no span short) — the model's one clock holds it, twin lease-buggy-drift breaks Inv_NoLateWrite, 2026-11-21
last gate: 2026-11-24 — Final Critique 11, a delta round, one reader (Linus opencode/beam-free; GRID and EOS not run), frozen at 0ea88b89 — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Operation 2c states no reading by which a waiter's admission must occur, so a build that defers the first waiter's admission from the reading at which the holder releases to the next reading conforms, was placed refining by the blind second triage and refuted as foundational by the first, foundational by neither: Operation 2 says the first waiter in arrival order MUST succeed at the first host reading at which the key is free and Check 4.1 tests it, so the deferring build breaks both, and Operation 2c only orders the admission after the arrivals at that reading; the finder's cure, "at that reading", would restate Operation 2; cured, refining: Term waiter's bound cites Term arrival term for the arrival reading plus the arrival term and for the arrival term being zero, where it cited Invariant 4.1 and Operation 2c for the sums, and Term waiter's last reading cites Execution Contract Logic confinement 9 for the exact arithmetic that lets a bound fall between two readings, not for the later reading reaching it; the reader's other refining reports, that Operation 5 restates Invariant 4.1 and that Check 4.4 has no tie-break for two [Take] calls at one reading, were placed refining D by the blind second triage and left as written: Operation 5 is the host's act and Invariant 4.1 the standing property, each cited by a check, and Term arrival order orders two calls at one reading as the host received them); 2026-11-24 — Final Critique 10, a delta round, one reader (Linus claude-sonnet-5-5), frozen at b6ad4b52 — foundational count 1 after the blind second triage, not clean, one sample (Linus's three foundational reports were placed refining by both triages: F1, that a [Take] arriving where the key is free and a waiter stands has no grant to take a bound from, is answered by Term arrival term, zero where the key is free at arrival, so the bound is the arrival reading; F2, that a failed read at a waiter's last reading leaves the waiter standing or not, is answered by Operation 3 and Operation 5b, which bind the waiter at the last reading whatever the call answered; F3, that Check 4.1 and Check 4.4 need readings no record carries, is answered by the page's own Generation acceptance, which runs its checks against a host implementation; the blind second triage on Opus 5.5 found the foundational one the reader did not draw: no rule ordered, within one host reading, the admission of the first waiter against the arrival of a [Take], so a [Take] arriving at reading 10 as a grant ends is answered unavailable by one host and waits on the next waiter's grant at another; cured, foundational: Operation 2c admits a waiter at a reading only once every [Take] arriving at the reading stands in the line, which Operation 6c already assumed, and Check 4.4 tests it; cured, refining: Term waiter's bound names the arrival reading where no grant held the key, Term waiter's last reading no longer says the host has admitted or answered the waiter by that reading, which was false across a host restart and under a failed read, Operation 5b says hold on the line for carry forward, and the Generation acceptance says the auditor sets the host's clock for the two checks that read its readings; the reader's refining reports on Execution Contract Logic confinement 9, on a Waitlist composition, on Operation 5b's Check 4.4 citation and on the clock reading of a standing [Take] were refuted, the Waitlist one by Scott's ruling of 2026-11-22 06:55Z); 2026-11-24 — Final Critique 9, a delta round, one reader (Linus beam-free), frozen at 49b7bbbe — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Term waiter's last reading gives every waiter a last reading and then says a waiter admitted at an earlier reading has no reading past the admission, so a waiter admitted at reading 5 with bound 8 and host readings 0, 5 and 10 has a last reading of 10 and none past 5, was placed refining by both triages, foundational by neither: the build that carries the admitted waiter on to reading 10 would answer one [Take] twice, which Operation 1b forbids, so one behaviour conforms; cured, refining: the term says the admitted waiter stopped standing at [Take] at the admission, Term waiter's bound gives the instant only where the host admits the waiter at no earlier reading, and Check 4.4 tests Operation 1a's own case, a [Take] on a free key with no waiter standing; the finder's fix, which scoped the first clause to a waiter not yet admitted, made the existence of the reading turn on an act of the host the same entry says moves nothing, and dropped the citation of Execution Contract Logic confinement 9); 2026-11-22 — Final Critique 8, a delta round, one reader (Linus minimax-m3), frozen at 6e98e08e — foundational count 0 after the blind second triage, clean, one sample (Linus's one foundational report, that Term waiter's last reading reads as constitutive or as descriptive and a build holding a later waiter queued past its bound differs from one answering it, was placed refining by the first triage and rhetorical by the blind second triage, foundational by neither: Operation 4 answers a waiter whose bound is reached while another holder holds the key, whichever way clause 2 is read, and the trace's two bounds contradict Term waiter's bound and Invariant 4.1; Linus's fix, an AND, would have left Operation 3 and Operation 5b binding a host to answer when it answers; cured, refining: Term waiter's last reading says the bound and the host's clock fix the reading and no act of the host moves it, and its last clause says no reading past the admission; Check 7.5 names the write margin Sizing 9 names, not the product the term declares); 2026-11-22 — Final Critique 7, a delta round, one reader (Linus minimax-m3), frozen at fbd975b6 — foundational count 1 (Term waiter's last reading joined two clauses by a comma, the first host reading at which the bound is reached and the reading at which the host admits or answers, which name different readings where the holder releases before the bound, so a build could read Operation 3 as binding the answer to the first reading that reaches the bound and another as the tautology that a host answers when it answers; Linus's fix, dropping the first clause, left Operation 3 and Operation 5b vacuous, so the settle's own cure keeps the first clause as the definition and says the host has admitted or answered by that reading), not clean, no sample (cured: Term waiter's last reading; the refining cure is Check 7.5 and the new Check 7.9, which read Sizing 9 and Sizing 5d apart; the rhetorical cure is Composition note 9, which now says Composition note 9a excepted, the exception 9a states); 2026-11-22 — Final Critique 6, a delta round, frozen at 132f19c9 — foundational count 1 (a waiter's bound can fall between two readings of the host's clock, so at the first reading at which the key is free Operation 2 admitted the first waiter, Operation 5b barred it and Operation 3 left no build conforming; Linus's second foundational, a take again leaving two grants or a revoked one, refuted on Invariant 1 and Invariant 2), not clean, no sample (cured: Term waiter's last reading, which Operation 3 and Operation 5b now name; the refining cures are Sizing 5d, which refuses a unit's bound under the call pause bound, and Composition note 9, which now carries the exception Composition note 9a lifts); 2026-11-22 — Final Critique 5, full, three fresh readers (GRID, EOS, Linus) — not clean, 4 foundational (EOS reported 7, GRID 0, Linus 0; EOS's host-adapter finding refuted on Term host, its share-term and take-again findings placed refining), cured in the patch (the next round is a delta round); 2026-10-04 — Final Critique 4, fresh reader, three passes, frozen at 46804b7 — 0 foundational, 44 refining reports, 13 rhetorical reports

open: none
```

</details>

<details markdown="block">
<summary>
    <h2 id="decisions" style="display: inline-block; margin-left: 1.5rem;">Decisions</h2>
</summary>

Decisions are kept in [the pattern's history](./lease.hist.md#decisions), one dated entry for each turn the pattern took; everything smaller lives in the commit that made it: `git log -- atoms/lease.md`.

</details>

NOTE: End of Lease.

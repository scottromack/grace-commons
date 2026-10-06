---
title: Lease
parent: Atomic Concepts
has_toc: true
toc: true
---

# Lease

## Summary

A **lease** is a grant of exclusive standing over a key, to a named holder, until a declared instant. It is the smallest concept two patterns in this library kept re-describing in prose: a per-key critical section whose terminus is a time rather than an event.

The whole of the atom is one sentence and its consequences: **the grant ends at the instant, never at an event.** Nothing in a distributed system observes a holder's death, so a grant that ended on death would end on a fact no party holds. A lease therefore ends in exactly two ways — the holder returns and releases it, or the instant passes — and every other property here follows from that.

The instant is a value, not a private timer. A holder may carry it to a third party as a **fence**: a deadline after which that party must refuse work submitted under the grant. That is what makes a lease more than a lock, and it is why the two fences a regulated protocol needs — one on its store, one on its journal — are this concept and not two others.

## Intent

WHY:
Two patterns in this library described a per-key critical section with lease semantics in prose, and a third described two fences that are the same concept reached from the other end. Each stated the same rules in its own words, and each repair to one had to be propagated to the others by hand. The concept has its own state machine, its own operations and its own failure mode, and it belongs to none of the patterns that use it. This atom exists so that a pattern needing exclusive standing over a key cites it rather than restating it, and so that the argument for the one hard rule — the terminus is an instant — is made once, where it can be attacked once. It is deliberately small: a lease does not decide who should hold it, does not record that it was held, and does not know what the holder does.

## Structure

### Identity model

```
Identity 1: The atom MUST identify a lease by the pair (key, holder).
Identity 2: The atom MUST compare keys by byte identity.
Identity 3: The atom MUST NOT normalize a key.
Identity 4: The atom MUST compare holders by byte identity.
Deleted: Identity 5. Identity 6 owns it.
Identity 6: A caller MUST mint a fresh holder value for EVERY take.
Identity 7: A process that restarts MUST NOT carry a holder value across the restart.
```

Term fresh holder value: a holder value no earlier take on the key carried.

Term key: the opaque value a lease protects — a [Key]; two keys that differ by a byte are two leases.

Term holder: the opaque value naming one take's holder — a [Holder]; minted fresh for every take, so a (key, holder) pair names one grant.

WHY:
A holder value names one take. A release that was delayed or duplicated in transit, or sent by a paused process when it wakes, then answers against a pair no later [Lease] carries and finds not-held; under a reused value it would end a grant its sender never held, and the next party would read while that grant's work was still landing (Identity 6, Operation 12). A process that restarts has lost what it knew of the grant — which calls were in flight, whether a release was sent — so it does not resume: the old value is not presented again and the grant runs to its instant (Identity 7); a pattern that must prove which grant it held records the grant (Non-goal 9). The pair matters because [Remaining] and [Release] answer against it (Invariant 5.1): a party that has lost standing finds out from the host, and neither answer is an error.

### State

```
State 1: The host MUST hold EXACTLY ONE lease state per key.
State 2: The host MUST derive free from a passed instant at the moment a question is asked.
State 3: The host MUST NOT store a transition for a passed instant.
State 4: The host MUST hold the line of waiters on a key, EVERY waiter with the waiter's bound.
```

Term grant: one holding of a key by one holder, from a successful take to the grant's terminus.

Term lease state: free | held — held by one holder until one instant.

Term passed instant: an expires_at the host's reading does not precede; the key is free at the reading that equals expires_at.

Term host's reading: the reading of the granting host's one clock at the moment a question is asked; never a caller's own reading.

Term question: a [Take], a [Try Take], a [Remaining] or a [Release] call, and a waiter's standing waiting term — the occasions State 2 derives at.

WHY:
There is no third state — beside it the host holds only the line of waiters, each with its bound (State 4, Operation 5a, Invariant 4.1) — and the passing of the instant is compared against a reading at the moment a question is asked. That is the atom's one storage claim, and it is what makes the concept implementable over a host that offers little more than compare-and-set with an expiry and an ordered line of waiters.

### Capability requirement

```
Capability requirement 1: The deployment MUST supply a host offering EVERY operation of the signature block.
Capability requirement 2: The deployment MUST share the host across every node of the instance.
Capability requirement 3: The deployment MUST declare the allowance for EVERY fenced party (Execution Contract Logic confinement 7).
Capability requirement 4: The deployment MUST supply a host that answers EVERY question on one key from one clock (Execution Contract Logic confinement 7).
Capability requirement 5: The deployment MUST supply a host that holds EVERY grant across a host restart.
Capability requirement 6: The deployment MUST supply fenced parties bound by Fence 3, Fence 4, Fence 4a, Fence 6 and Fence 10.
Capability requirement 7: The deployment MUST hold EVERY lease call and EVERY unfenced write a holder issues, a blocking [Take] excepted, inside the call pause bound the composing pattern declares, a pause of the holder's own process included.
Capability requirement 8: A party that answers a holder's write MUST answer ONLY AFTER the write has taken effect.
Capability requirement 9: A party that refuses a holder's write MUST NOT apply the write.
Capability requirement 10: A party MUST NOT apply one write of a holder a second time.
Capability requirement 11: The deployment MUST NOT deliver one take to the host a second time.
```

WHY:
A critical section held on one node and not another is no critical section (Capability requirement 2). The allowance is how far the granting host's clock and a judging party's clock may stand apart, which is the deployment's to know and to declare; the atom spends the number and does not choose it (Capability requirement 3). The host's reading is one clock's: a host that answered one holder's remaining term from one node's clock and another party's take from a second node's would hold a key for two parties at once, by the gap between the two (Capability requirement 4). A grant a restart ended would be a grant ended on an event, so the host keeps it (Capability requirement 5, Invariant 2.2). The call pause bound is a number the pattern declares and only the deployment can make true: a call, or the process that issues it, stalled past the bound breaks the one premise the sizing rests on (Capability requirement 7). An answer means the write has landed and a refusal means it never will: a store that answered first and applied later would let a holder release, with no call in flight, ahead of its own write, and a copy of an answered write delivered late and applied again would do the same from the other side (Capability requirement 8, Capability requirement 9, Capability requirement 10, Composition note 5c). A take delivered twice is worse than a release delivered twice: the second copy, landing on a key since freed, grants the old pair again, and the host then answers a holder that lost standing as though it had it (Capability requirement 11, Invariant 5.1).

### Operations

```
take(key, holder, duration)
  answers expires_at | unavailable

try_take(key, holder, duration)
  answers taken(expires_at) | held

remaining(key, holder)
  answers remaining_term | none

release(key, holder)
  answers released | not-held
```

```
Operation 1: [Take] MUST wait for the key to become free.
Operation 1a: IF the lease state EQUALS free AND no waiter stands THEN [Take] MUST succeed at the reading the [Take] arrives at.
Operation 1b: [Take] MUST answer EXACTLY ONE OF expires_at, unavailable.
Operation 2: The [Take] of the waiter first in arrival order MUST succeed at the first host reading at which the key is free.
Operation 2a: A successful take MUST stand the key in held by the asking holder.
Operation 2b: A successful take MUST set expires_at from the host's reading at the success.
Operation 3: [Take] MUST NOT wait longer than the arrival term.
Operation 4: IF a waiter's bound DOES NOT EXCEED the host's reading AND another holder holds the key THEN [Take] MUST answer unavailable.
Operation 5: The host MUST NOT extend a waiter's bound.
Operation 5a: The host MUST admit waiters in arrival order.
Operation 5b: The host MUST NOT carry forward a waiter whose bound elapsed.
Operation 5c: The host MUST NOT admit a waiter that stood across a host restart.
Operation 6: [Try Take] MUST NOT wait.
Operation 6a: IF the lease state EQUALS free AND no waiter stands THEN [Try Take] MUST answer taken(expires_at).
Operation 6b: IF the lease state EQUALS held THEN [Try Take] MUST answer held.
Operation 6c: IF the lease state EQUALS free AND a waiter stands THEN [Try Take] MUST answer held.
Operation 7: [Try Take] MUST answer EXACTLY ONE OF taken(expires_at), held.
Operation 8: [Remaining] MUST answer the remaining term of the asking holder.
Operation 9: IF the asking party DOES NOT EQUAL the holder THEN [Remaining] MUST answer none.
Operation 10: A caller MUST NOT compute the remaining term from a remembered expires_at and the caller's own reading.
Operation 11: [Release] MUST end the asking holder's grant.
Operation 11a: IF the asking party EQUALS the holder THEN [Release] MUST answer released.
Operation 12: IF the asking party DOES NOT EQUAL the holder THEN [Release] MUST answer not-held.
Operation 13: [Release] MUST NOT reach another holder's grant.
Operation 14: An implementer MUST NOT treat not-held as a failure.
```

Term remaining term: the part of a holder's term not yet elapsed, as the host reads the part.

Term waiting term: the term a waiter has stood at [Take], as the host reads the term.

Term waiter's bound: the instant a waiter stops standing at [Take] — the expires_at of the grant that held the key at the waiter's arrival, which is the waiter's arrival reading plus the arrival term (Invariant 4.1).

Term arrival term: the remaining term of the holder that held the key at the moment the waiter arrived; zero where the key is free at arrival.

Term successful take: a [Take] that answers expires_at, or a [Try Take] that answers taken(expires_at).

Term expires_at: `reading_at_success + duration` — the instant a grant ends, on the granting host's clock; an [Expiry Instant].

Term asking party: the party naming itself as holder in a [Remaining] or [Release] call.

Term the holder: the party the host holds the key for.

WHY:
A key frees by release or by the current holder's instant passing. A host restart ends the line: a waiter the restarted host can no longer answer is not admitted afterwards, and its caller reads no answer (Operation 5c, Sizing 7). The bound is fixed at arrival and never extended: a second waiter admitted while a first still holds fails on its own bound rather than waiting out the first's whole term, so a pattern that reasons about how long a take can block is entitled to that number and no other (Operation 3 through 5). [Try Take] exists for a caller with other work to do. [Remaining] is a host query and never a clock read by the caller: a caller that subtracts its own reading from a remembered expires_at has introduced a second clock and lost the property the atom exists to provide, since the two are minted at different seams (Operation 10). not-held covers a party whose term has passed and whose key another holder now holds; callers normally discard the answer, and it is declared because an implementer who treats it as a failure will retry it (Operation 14).

### Invariants

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
  WHY: a holder's death, a network partition, a host restart, a supervisor's judgement — none ends a grant.
- **Invariant 3 — Death is not observable.**
  ```
  Invariant 3.1: The atom MUST NOT report a holder's death.
  Invariant 3.2: An implementation MUST NOT end a grant early on a belief that the holder has died.
  ```
  WHY: a host that frees a key the moment it believes a holder is gone hands the key to the next party while the previous holder's work may still be in flight, and Invariant 1 is then true of the grant and false of the world.
- **Invariant 4 — A waiter's bound is fixed at arrival.**
  ```
  Invariant 4.1: A waiter's bound MUST stand as set at the waiter's arrival.
  Invariant 4.2: Admitting an earlier waiter MUST NOT extend a later waiter's bound.
  ```
- **Invariant 5 — Standing is answered, never assumed.**
  ```
  Invariant 5.1: [Remaining] and [Release] MUST answer against the (key, holder) pair as the host holds the pair.
  ```
  WHY: a party that has lost standing learns it from the host rather than from its own clock.
- **Invariant 6 — A fence instant carries its allowance.**
  ```
  Invariant 6.1: EVERY instant handed to a party judging on another clock MUST carry the allowance subtracted.
  Invariant 6.2: The holder MUST mint EVERY such instant independently.
  ```

### Sizing a grant for unfenced work

```
Sizing 1: A composing pattern MUST declare a [Call Pause Bound].
Sizing 2: IF the remaining term the host answers EXCEEDS the write margin AND unanswered EQUALS no THEN the holder MUST read the lease as live.
Sizing 2a: IF the remaining term the host answers DOES NOT EXCEED the write margin THEN the holder MUST read the lease as expired.
Sizing 3: A holder MUST issue an unfenced write under a lease ONLY IF the write falls inside a unit of work started under Sizing 5 OR the holder read the lease live for that write.
Sizing 3a: A holder MUST issue a write admitted by a live reading WITHIN the [Call Pause Bound] of asking for the reading.
Sizing 4: The work's bound MUST include twice the [Call Pause Bound].
Sizing 4a: A holder MAY take a lease for unfenced work ONLY IF the duration EXCEEDS the work's bound.
Sizing 5: A holder MAY start a unit of work ONLY IF the remaining term the host answered for that unit EXCEEDS the unit's start floor AND unanswered EQUALS no.
Sizing 5b: A holder MUST take one [Remaining] reading for EVERY unit of work.
Sizing 5a: IF a unit's elapsed time EXCEEDS the unit's bound THEN the holder MUST NOT issue a write of the unit.
Sizing 6: A lease taken by [Try Take] for a share of a budget MUST carry the share term as duration.
Sizing 6a: A holder MUST NOT take a share of a budget by a blocking [Take].
Sizing 7: IF unanswered EQUALS yes THEN the holder MUST read the lease as expired for the rest of the grant.
Sizing 8: A holder MUST NOT issue a second time, under one lease, a call that answered no answer.
Sizing 9: IF a work's bound the pattern declares DOES NOT EXCEED the write margin THEN a pattern MUST refuse to start.
```

Term unfenced write: a write issued under a lease that carries no fence a fenced party judges; the Sizing rules bind EVERY unfenced write and no other write.

Term call pause bound: the longest time from a holder's decision to issue one call to the moment the call has taken effect or failed — a [Call Pause Bound]; the composing pattern declares it (Sizing 1).

Term unit of work: one bounded piece of work a holder starts under a lease — one call, or the calls a pattern bounds together.

Term unit's start: the moment the holder issues the [Remaining] call whose answer admits the unit.

Term unit's bound: the bound the composing pattern declares on a unit of work, from the unit's start to the landing of the unit's last write.

Term work's bound: the bound the composing pattern declares on all the work under one lease, the take's answer, every reading and every unit's bound counted.

Term budget: a bound the composing pattern declares over work that began before the take, of which the lease is granted a share.

Term write margin: `2 * call_pause_bound` — a check's answer and the write the check guards are two calls.

Term start floor: `unit_bound + 2 * call_pause_bound` — what a unit of work needs of the remaining term to finish with the write margin intact.

Term unit's elapsed time: the time since the unit's start, measured at the holder's own seam.

Term share term: `budget - time_spent_before_take - call_pause_bound`, the time spent measured at the holder's own seam.

Term live: a lease whose remaining term EXCEEDS the write margin, unanswered being no.

Term expired: a lease that is not live, a [Remaining] that answers none or no answer included — a reading the holder acts on, never a transition the host makes (Invariant 2.2).

Term unanswered: yes | no — yes for a grant under which a [Take], a [Try Take], a [Remaining] or a [Release] answered no answer, and for the rest of that grant.

Term no answer: a call that returns neither its answers nor a refusal within the call pause bound, or, for a blocking [Take], within the longest duration declared for the key and the call pause bound (Composition note 5d).

WHY:
A fence is the only thing that stops a holder's late write, and work carrying none has the lease alone to rely on. The holder checks the lease and then writes, and those are two calls with a pause that can fall between them; a write issued on a lease with less than two pauses left can land after the next holder has read, and so can one issued late on a reading that was good when it was asked for, which is why the write follows its reading inside one pause (Sizing 2, Sizing 2a, Sizing 3, Sizing 3a). The term must cover the work and the two-call margin its last write is issued on, or a conforming holder reads its own lease expired inside its own work (Sizing 4, Sizing 4a); no unit may start that the remaining term cannot finish with its two-call margin, one reading admits one unit, the unit's time is counted from the moment that reading was asked for, so a pause before the work begins is spent from the unit's own bound, and the reading covers the unit's writes for as long as the bound, after which the unit writes nothing more (Sizing 3, Sizing 5, Sizing 5a, Sizing 5b); a holder given a share of a longer budget spends the time it has already used and the pause before the grant lands, and takes that share without waiting, since a wait of unknown length cannot be deducted in advance (Sizing 6, Sizing 6a). A host that does not answer is a lease the holder cannot read, and a call re-issued within the lease may land twice (Sizing 7, Sizing 8). A pattern whose declared bounds do not clear the margin has a lease that reads expired from the first call, so it refuses to start rather than run (Sizing 9). The host's grant is untouched throughout: expired is a holder's reading and the grant still ends at the instant (Invariant 2.1, Invariant 2.2). The atom gives the form, never the numbers: the call pause bound and every unit's bound are the pattern's (Non-goal 10, Non-goal 12, Non-goal 12a). A unit's elapsed time and the time spent before a take are spans on the holder's own clock, never instants compared across two clocks; how far two clocks' rates may differ over a span is the deployment's (Execution Contract Logic confinement 7).

### The terminus, and carrying it as a fence

```
Fence 1: A successful take MUST return expires_at as an absolute instant on the granting host's clock.
Fence 2: A holder MAY pass a fence to a third party.
Fence 3: The fenced party MUST admit a work item ONLY IF the work item's effect instant PRECEDES the fence.
Fence 4: The fenced party MUST judge the fence on the fenced party's own clock.
Fence 4a: The fenced party MUST judge the fence and apply the work item in one atomic step.
Fence 5: The fence ceiling MUST NOT PRECEDE a fence.
Fence 6: The fenced party MUST compare the fence bare.
Deleted: Fence 7. Fence 6 owns it.
Fence 8: A holder fencing two parties MUST mint EVERY fence separately.
Fence 9: A holder MUST NOT derive a second fence bare from a minted fence.
Fence 10: A work item MUST NOT carry an effect instant.
```

Term fence: an instant no later than the fence ceiling, handed to a third party as a deadline (a [Fence]) — refuse this holder's work unless the work takes effect before this instant.

Term fence ceiling: `expires_at − allowance`.

Term effect instant: the instant a work item takes effect, read on the fenced party's own clock in the step that applies the work item.

Term allowance: the declared cross-seam allowance between the granting host's clock and the judging party's clock; one allowance per fenced party.

Term fenced party: the third party a fence is handed to.

WHY:
expires_at is the point of the atom ([Expiry Instant]). The judging party's clock is not the granting host's, so the comparison spans two seams and the allowance must be spent somewhere; minted into the instant, never applied at the reading, because applying it at the reading widens the window in the direction that admits a late write — the failure the fence exists to prevent. The ceiling is a ceiling and not an equation: a holder may hand over an earlier instant and keep more margin, never a later one (Fence 5, Check 6.1). Two fenced parties are two seams with two allowances, which is what makes minting each fence separately more than bookkeeping (Fence 8). Minting one instant with the allowance and deriving the others from it bare defeats the margin on every derived instant, the same defect a second time (Fence 8, Fence 9). The effect instant is judged, never claimed: an instant carried by the work item would be the holder's own word, and the holder is the party a fence exists to stop trusting (Fence 3, Fence 4).

## Examples

**A critical section around a write.** A process takes the key for the act it is about to change and receives expires_at. Its write carries no fence, so it asks the host what remains, starts only on an answer above the start floor, does its work, and releases on return. A second process arriving mid-way waits at most the first's remaining term and then either takes the key, or is told unavailable because an earlier waiter took it first — and it writes only under a grant of its own.

**A fence carried to a store.** The same process passes expires_at less the allowance into the store call as a deadline. The process pauses for longer than anyone budgeted; its term passes; the key goes to the next holder. The paused process wakes and issues its write anyway — and the store refuses it, because the deadline it was given has passed on the store's own clock. The next holder's read is therefore complete: nothing of the previous holder's can still land.

**A holder that dies.** A process takes the key and is killed. Nothing is notified. The key stays held until the instant passes, and the next take waits exactly that long. This is the case that motivates Invariant 3: a host that released the key on the death would hand it over while the dead process's last write was still in flight.

## Generation acceptance

This atom writes no records, so its acceptance checks are conformance checks rather than an audit traversal: against a host implementation, and for the fence and the sizing against a holder.

### Conformance checks

```
Check 1.1: An auditor MUST confirm that two concurrent takes on one key, with no release and no expiry between the takes, yield EXACTLY ONE expires_at (Invariant 1.1, Invariant 1.2).
Check 1.2: An auditor MUST confirm that a [Try Take] on a held key answers held (Operation 6b, Operation 7).
Check 2.1: An auditor MUST confirm that a key held by a party that never releases becomes takeable at the instant (Invariant 2.1).
Check 2.2: An auditor MUST confirm that such a key does not become takeable earlier (Invariant 2.2).
Check 3.1: An auditor MUST confirm that the key of a killed holder reads held at EVERY host reading that PRECEDES the instant (Invariant 2.2, Invariant 3.2).
Check 3.2: An auditor MUST fail a host that frees the key of a killed holder earlier, whatever the host knows about the holder (Invariant 3.2).
Check 4.1: An auditor MUST confirm that [Take] answers a waiter at the first host reading that reaches the waiter's bound (Invariant 4.1, Operation 2, Operation 3, Operation 4).
Check 4.2: An auditor MUST confirm that [Take] answers a second waiter at the first host reading that reaches the second waiter's own bound (Invariant 4.2, Operation 5).
Check 5.1: An auditor MUST confirm that [Remaining] answers none and [Release] answers not-held to every party that is not the current holder, a former holder whose term has passed included (Invariant 5.1, Operation 9, Operation 12).
Check 5.2: An auditor MUST confirm that neither answer changes the lease state (Operation 13, State 3).
Check 5.3: An auditor MUST confirm that a release carrying the holder value of an ended grant answers not-held and leaves a later grant on the key standing (Identity 6, Operation 12).
Check 6.1: An auditor MUST confirm that the allowance does not exceed the fence margin of any handed instant (Fence 5, Invariant 6.1).
Check 6.2: An auditor MUST confirm that an instant derived from another is minted with the allowance rather than inheriting the allowance (Fence 8, Fence 9, Invariant 6.2).
Check 6.3: An auditor MUST confirm that a fenced party admits no work item whose effect instant falls at the fence or later, and judges in the step that applies the work item (Fence 3, Fence 4a).
Check 7.1: An auditor MUST confirm that a holder issues no unfenced write outside a started unit of work without a live reading taken for that write and followed inside one call pause bound, and no write of a unit whose bound has elapsed (Sizing 2, Sizing 2a, Sizing 3, Sizing 3a, Sizing 5a).
Check 7.2: An auditor MUST confirm that every lease term set for unfenced work exceeds the work's bound and that the bound includes twice the call pause bound (Sizing 4, Sizing 4a, Sizing 6).
Check 7.3: An auditor MUST confirm that no unit of work starts on a remaining term that does not exceed the unit's bound plus twice the call pause bound (Sizing 5).
Check 7.4: An auditor MUST confirm that a no answer is treated as expired and the call is not re-issued within the lease (Sizing 7, Sizing 8).
Check 7.5: An auditor MUST confirm that the pattern refuses to start where a declared work bound does not exceed twice the call pause bound (Sizing 9).
```

Term fence margin: `expires_at − fence`.

NOTE: EVERY check names the rule the check tests. A check that names none is a check whose failure nobody can state (council read 8).

## Non-goals

```
Non-goal 1: A party MUST NOT take a key the party already holds.
Non-goal 2: The atom MUST NOT offer a depth count.
Deleted: Non-goal 3. Operation 5a owns it.
Deleted: Non-goal 4. Operation 5b owns it.
Non-goal 5: The atom MUST NOT make the work under a lease atomic.
Non-goal 6: The atom MUST NOT roll back work done under a lease.
Non-goal 7: The atom MUST NOT isolate a holder's partial work from a reader.
Non-goal 8: The atom MUST NOT write a record.
Non-goal 9: A pattern that must prove a critical section was held MUST record the critical section.
Non-goal 10: The atom MUST NOT choose a grant's duration.
Non-goal 11: A pattern that needs the term to cover the pattern's work MUST state that obligation by Sizing 4a.
Non-goal 12: The atom MUST NOT choose the call pause bound.
Non-goal 12a: The atom MUST NOT choose a unit's bound.
```

WHY:
The atom does not detect death and no implementation may pretend to (Invariant 3.1, Invariant 3.2). Reentrancy is a caller error, not a supported nesting (Non-goal 1, Non-goal 2). A lease serializes access to a key and nothing more (Non-goal 5 through 7). expires_at is on the granting host's clock (Fence 1); comparing it against any other clock is the cross-seam case Invariant 6 governs.

## Composition notes

Term call in flight: a call a holder issued under a grant that has returned neither an answer nor a refusal.

```
Composition note 1: A composing pattern MUST name this atom as a capability requirement.
Deleted: Composition note 2. Capability requirement 1 owns it.
Deleted: Composition note 3. Capability requirement 2 owns it.
Composition note 4: A composing pattern MUST own which key protects which work.
Composition note 5: A composing pattern MUST own how long the grant lasts.
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
```

WHY:
A waiter is never told its arrival term, so the longest it can be kept is the longest grant the pattern ever asks for on that key, and a pattern that declares that number can tell a slow take from a lost one (Composition note 5d, Term no answer). A holder that gave up on a call does not know the call is dead: released early, the key goes to a party whose read the late call can still follow. The grant is left to end at the instant, as [Audit Trail](../compositions/audit-trail.md) leaves it; a fence does not make an early release safe, since it refuses only what lands after the instant (Composition note 5b, Composition note 5c). A release is the holder's last call under the grant: a write issued behind it would land under a key already handed on (Composition note 5f). A pattern whose work can exceed the term it asks for has a defect this atom will not catch — it will hand the key on at the instant, exactly as specified (Composition note 5, Non-goal 11). A store deadline and a journal deadline are two uses of one atom (Composition note 6, Composition note 7). Work no fence reaches is sized by the one rule set the atom carries, with the pattern's own bounds as its numbers (Composition note 8, Composition note 8a).

## Terms

Each `[Term]` marker above links to its term entry here; a term entry states what the concept *is* and its **Kind**.

### Vocabulary

Term actors: the atom; the host; a holder (also: the holder, the asking holder, the current holder, a former holder); a waiter; a caller; a party; the asking party; a third party (also: the fenced party, the judging party); an implementation (also: an implementer); a composing pattern (also: a pattern); the deployment; an auditor; a key; a grant; a lease; a take; an instant; a work item.

Term records: empty — the atom writes nothing.

Term record verbs: identify, compare, normalize, hold, derive, store, wait, succeed, answer, extend, compute, end, reach, treat, return, pass, refuse, judge, mint, apply, stand, report, equal, take, offer, admit, carry, make, roll, isolate, write, record, choose, state, check, name, supply, share, own, invent, confirm, fail, declare, set, read, issue, start, include, release, deliver.

Term value sets: lease state = free | held. grant terminus = release | instant. unanswered = yes | no.

Term bounds: duration (the term a take asks for); the allowance; the fence ceiling; the call pause bound.

Term cadences: empty.

Term qualifiers: migrated — rewritten in GRACE lang v0.35 (2026-09-11).

Term terms: fresh holder value, call in flight, unfenced write, key, holder, grant, waiter's bound, lease state, passed instant, host's reading, question, waiting term, remaining term, arrival term, successful take, asking party, the holder, unit of work, unit's start, unit's bound, work's bound, budget, write margin, unanswered, start floor, unit's elapsed time, share term, fence, fence ceiling, effect instant, allowance, fenced party, fence margin, call pause bound ([Call Pause Bound]), live, expired, no answer, and expires_at ([Expiry Instant]).

#### Lease

A grant of exclusive standing over a key, to a named holder, until a declared instant. Ends at the instant or at the holder's release, and at nothing else.

Kind: Type

#### Key

The opaque value a lease protects. Compared by byte identity, never normalized, meaningful only to the pattern that supplies it.

Kind: Parameter

#### Holder

The opaque value naming who holds a lease. Compared by byte identity. Minted fresh for every take, so it names one grant's holder and no other.

Kind: Parameter

#### Take

The blocking acquisition. Waits at most the arrival term, and answers unavailable if the key is held again when that term has elapsed — an earlier waiter took it.

Kind: Operation

#### Try Take

The non-blocking acquisition. Answers `taken(expires_at)` or held, immediately.

Kind: Operation

#### Remaining

The host query for how much of the asking holder's term is left, or none if the asking party is not the holder. Never a clock read by the caller.

Kind: Operation

#### Release

Ends the asking party's grant, or answers not-held if it has none. Never reaches another holder's grant.

Kind: Operation

#### Expiry Instant

The absolute instant, on the granting host's clock, at which a grant ends. Returned by a successful take; the value a holder mints a fence from.

Kind: Field

#### Fence

An instant no later than expires_at less the allowance, handed to a third party as a deadline: refuse this holder's work unless the work takes effect before this instant. Judged on the third party's clock.

Kind: Type

#### Call Pause Bound

The longest time from a holder's decision to issue one call — a try-take, a lease check, a write under the lease, a delegation — to the moment the call has taken effect or failed; never a whole unit of work, and never a blocking take, whose wait Term no answer bounds. Declared by the composing pattern.

Kind: Parameter

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

## Standards references

The concept is not itself regulated. It appears in regulated patterns as the mechanism by which a single-writer obligation is met, and those patterns anchor their own regimes; the atom's contribution is that the obligation is met by an argument stated once. The nearest external statement of the same rule is the fencing-token discipline in the distributed-systems literature on lock services, where a lock that ends on a belief about liveness is shown to admit two writers.

## Status

`grounded on Final Critique 4 — 2026-10-04` — see the Ledger.

## Ledger

```
status: grounded on Final Critique 4 — 2026-10-04
formal: verified — lease.tla + 4 twins + 1 probe (vote yes: one holder, the terminus, the fence and the write margin are temporal claims; 14,480 states, holding at clock bounds 8, 10 and 12), 2026-10-04
last gate: 2026-10-04 — Final Critique 4, fresh reader, three passes — 0 foundational, 44 refining reports, 13 rhetorical reports

open:
- 2026-10-04-a · refining · Sizing 1 through 9; Composition note 8 · the sizing is a holder-side discipline with its own latched reading, the atom says a lease does not know what the holder does, and a composer restates the rules as its own → an extraction candidate; decide once a second composer binds it
- 2026-10-04-b · refining · Sizing 3a, 5a, Term share term; Capability requirement · the holder's own span clock is assigned to the deployment in a WHY alone, and no term spends the rate two clocks drift at → a capability requirement, or a drift term in the start floor
- 2026-10-04-c · refining · Operation 1b, 5c · a waiter dropped at a host restart is answered nothing, and only a WHY says its caller reads no answer → say it in a rule
- 2026-10-04-d · refining · Check 4.1, 4.2, 7.2; Generation acceptance · the waiter checks omit a release, Check 7.2 cites Sizing 6 for nothing it tests, and no check covers a host restart, arrival order, one reading per unit, the release rules or Capability requirement 8 through 11 → a check per rule
- 2026-10-04-e · refining · the signature block; Composition note 5e · duration, key and holder have no policy at the host for zero, empty, over-long or unrounded values, and the waiter line has no cap → primitive policies, or a named non-goal
- 2026-10-04-f · refining · Identity 1, 6; Term key; Non-goal 1 · a lease names both a grant and a key's slot, a holder value is a bearer value, lower-case take is never said to include try_take, and Non-goal 1 binds a party the atom carries no identity for → one name each
- 2026-10-04-g · refining · Capability requirement 6, 8, 9, 10 · a write, a work item and a call name one thing, three requirements bind a party where the family binds the deployment, and taken effect has no term → one vocabulary, one subject
- 2026-10-04-h · refining · Sizing 1; Term unfenced write; Capability requirement 7 · the call pause bound is owed by every pattern and the sizing by unfenced writes alone, and the requirement makes a late call unreachable where Sizing 7 and 8 govern exactly that → say which is the premise and which the fallback
- 2026-10-04-i · refining · Non-goals; label families · five non-goals name no owner, three are obligations on a caller or a pattern, two label families do not name their headings, and instance, lease call, bare, arrival order and process are undeclared → mechanical
- 2026-10-04-j · refining · Summary; Intent; Examples; Standards references · the summary is not plain language, the intent is corpus history, no example carries a value or walks no answer, not-held, a restart or a budget share, and a deadline is called the same rule as a fencing token → rewrite at the level the rules hold
- 2026-10-04-k · refining · Operation 1, 2b; Capability requirement 1 · a blocking take reads the host's clock twice and waits, and the page never says the host is a capability outside the Execution Contract's pipeline → say so, citing Logic confinement 3 and 6
- 2026-10-05-a · refining · Term unit of work; Sizing 2a, 5; Capability requirement 7 · a unit's bound runs from the reading's ask where an adopter's latency runs from the call's issue, a remaining that answers none is classed by no sizing rule, and every unfenced write inside the call pause bound cannot hold for an adopter's one-call unit run to its own bound → one origin; an arm; scope the requirement; reported by Defensible Retention's and Resolve a Person's Data Rights' gates
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/lease.md`.

- **2026-10-04 — Grounded: a holder value names one take, release is the holder's last call, and what the atom cannot hold the deployment declares.** *Chose:* a fresh holder value for every take and none carried across a restart, so a stale or duplicated release finds not-held (Identity 6, 7; Identity 5 tombstoned); no release with a call in flight and no write after one (Composition note 5c, 5f); and eleven capability requirements for what only a deployment can make true — one clock per key, grants kept across a restart, calls held inside the call pause bound, an answer that means landed, a refusal that means never, a write applied once, a take delivered once (Capability requirement 1 through 11). *Over:* a holder value reusable across takes and restarts at the pattern's choice; a release rule with an exception for a pattern that shows a late landing to the next holder, which no reader could pin to a time; and host-side memory of every value ever carried. *Because:* each of three adversarial passes reached two writers on one key by a route the host rules alone could not close — a stale release, a release ahead of an answered-then-applied write, a take delivered twice.

- **2026-10-04 — The sizing is anchored to readings, and a waiter's bound is an instant.** *Chose:* one host reading per unit of work, the unit's time counted from the asking; a lone write issued within one call pause of its reading; a work's bound that includes two call pauses and a term that exceeds it; a share of a budget taken without waiting; an unanswered grant read expired to its end (Sizing 2 through 9, Term unit's start, Term unanswered); the key free at the reading that equals expires_at, the first waiter granted at the first free reading, a try-take that does not pass a waiter, and a restart that ends the line (Term passed instant, Term waiter's bound, Operation 1a through 6c). *Over:* a start gate and a write gate with no reading named, a waiter's bound held as a length, and a boundary instant two rules claimed. *Because:* the rules of 2026-10-02 carried Audit Trail's arithmetic and had never been read cold; the first round found the boundary obliging a take to succeed and to fail at one reading. Compositions affected: Audit Trail's completion bounds include two call pauses (its record action, purge and seal completion bound 2) and it declares the longest duration per key (its Per-act critical section 15c); Recoverable Invocation releases with a call in flight and binds no sizing (its Ledger lines 2026-10-04-a through c).

- **2026-10-04 — The formal-layer vote is yes.** *Chose:* lease.tla with four twins and a probe — a death-freed key, a one-pause margin, a bare fence, a release with a call in flight — each rejected, and the invariant that no write of a former holder lands after the next holder has read. *Over:* the draft's "not applicable", which left the atom's claims to its composers' models. *Because:* one holder, a terminus that is an instant and a fence that carries its allowance are temporal claims, and a composition model that assumes them cannot be what verifies them.

- **2026-10-02 — The atom gives the form of a lease's sizing for unfenced work, and none of its numbers.** *Chose:* Sizing 1 through 9 — a declared call pause bound, a lease that reads expired below twice that bound, no write on an expired reading, a term no shorter than the work's bound, a start margin, a share-of-budget rule, a no-answer arm — with Non-goal 10 kept and Non-goal 12 added, and the Ledger's open question answered: the checkable form lives here, the numbers in each composing pattern. *Over:* leaving the form in each composing pattern, and over moving the closure sum, closure floor and measured enumeration into the atom. *Because:* the form is the same for every pattern whose writes carry no fence, and it was being restated, and re-attacked, inside one 281 KB composition; the numbers price a pattern's own work (how many record actions, how many enumerations) and an atom that chose them would own a duration, which Non-goal 10 forbids.

- **2026-09-11 — Rewritten in GRACE lang v0.33; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the operations as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged. *Over:* the prose draft. *Because:* the migration plan — atoms first, since they declare the vocabulary compositions cite.

- **2026-09-10 — Extracted because the obligation kept propagating, not because the shape repeated.** *Chose:* one atom covering the grant and the terminus-as-fence together. *Over:* leaving the prose in the patterns that use it, and over splitting the critical section from the fence into two concepts. *Because:* four consecutive review rounds on one composition showed a flat defect density — one foundational finding per nineteen kilobytes of body — with most new defects being an obligation added in one place and not carried to the others. Lease semantics were the largest single source of such obligations, reaching into fences, timing, expiry, remaining, and worked examples. Splitting the grant from the fence would have preserved exactly the propagation the extraction exists to remove: a fence *is* a terminus handed to another party, and stating it twice is how the two got out of step.

- **2026-09-10 — The terminus is an instant, and death is not observable.** *Chose:* a grant that ends only at its instant or at its holder's release. *Over:* a host that frees a key when it believes the holder is gone, which is what one of the composing descriptions admitted. *Because:* a formal model of a composing pattern rejects the release-on-death variant — a holder that dies with a write in flight frees the key, the next holder reads before that write is visible, and two writers land for one key. The rule is stated here once so that a pattern citing this atom inherits the argument rather than restating it.

NOTE: End of Lease.

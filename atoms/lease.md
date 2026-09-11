# Lease

## Summary

A **lease** is a grant of exclusive standing over a key, to a named holder, until a declared instant. It is the smallest concept two patterns in this library kept re-describing in prose: a per-key critical section whose terminus is a time rather than an event.

The whole of the atom is one sentence and its consequences: **the grant ends at the instant, never at an event.** Nothing in a distributed system observes a holder's death, so a grant that ended on death would end on a fact no party holds. A lease therefore ends in exactly two ways — the holder returns and releases it, or the instant passes — and every other property here follows from that.

The instant is a value, not a private timer. A holder may carry it to a third party as a **fence**: a deadline after which that party must refuse work submitted under the grant. That is what makes a lease more than a lock, and it is why the two fences a regulated protocol needs — one on its store, one on its journal — are this concept and not two others.

## Intent

WHY:
Two patterns in this library described a per-key section with lease semantics in prose, and a third described two fences that are the same concept reached from the other end. Each stated the same rules in its own words, and each repair to one had to be propagated to the others by hand. The concept has its own state machine, its own operations and its own failure mode, and it belongs to none of the patterns that use it. This atom exists so that a pattern needing exclusive standing over a key cites it rather than restating it, and so that the argument for the one hard rule — the terminus is an instant — is made once, where it can be attacked once. It is deliberately small: a lease does not decide who should hold it, does not record that it was held, and does not know what the holder does.

## Structure

### Identity model

```text
Identity 1: The atom MUST identify a lease by the pair (key, holder).
Identity 2: The atom MUST compare keys by byte identity.
Identity 3: The atom MUST NOT normalize a key.
Identity 4: The atom MUST compare holders by byte identity.
```

Terms › `key`: the opaque value a lease protects — a [Key]; two keys that differ by a byte are two leases.

Terms › `holder`: the opaque value naming who holds — a [Holder]; a party, not a process.

WHY:
A holder that restarts and resumes is the same holder only if the pattern gives it the same holder value; a pattern that mints a fresh value per attempt has said that a restart is a different party. Both are legitimate and the choice is the pattern's. The pair matters because [Remaining] and [Release] answer against it (Invariant 5.1): a party that has lost standing finds out from the host, and neither answer is an error.

### State

```text
State 1: The host MUST hold EXACTLY ONE lease state per key.
State 2: The host MUST derive free from a passed instant at the moment a question is asked.
State 3: The host MUST NOT store a transition for a passed instant.
```

Terms › `lease state`: `free` | `held` — held by one holder until one instant.

WHY:
There is no third state, and the passing of the instant is compared against a reading at the moment a question is asked. That is the atom's one storage claim, and it is what makes the concept implementable over a host that offers nothing but compare-and-set with an expiry.

### Operations

```
take(key, holder, duration) → expires_at | unavailable
try_take(key, holder, duration) → taken(expires_at) | held
remaining(key, holder) → duration | none
release(key, holder) → released | not-held
```

```text
Operation 1: [Take] MUST wait for the key to become free.
Operation 2: [Take] MUST succeed at the instant the key becomes free.
Operation 3: [Take] MUST NOT wait longer than the arrival term.
Operation 4: IF the arrival term elapses with the key held THEN [Take] MUST answer unavailable.
Operation 5: The host MUST NOT extend a waiter's bound.
Operation 6: [Try Take] MUST NOT wait.
Operation 7: [Try Take] MUST answer EXACTLY ONE OF taken(expires_at), held.
Operation 8: [Remaining] MUST answer the remaining term of the asking holder.
Operation 9: IF the asking party != the holder THEN [Remaining] MUST answer none.
Operation 10: A caller MUST NOT compute the remaining term from a remembered expires_at and the caller's own reading.
Operation 11: [Release] MUST end the asking holder's grant.
Operation 12: IF the asking party != the holder THEN [Release] MUST answer not-held.
Operation 13: [Release] MUST NOT reach another holder's grant.
Operation 14: An implementer MUST NOT treat not-held as a failure.
```

Terms › `arrival term`: the remaining term of the holder that held the key at the moment the waiter arrived.

Terms › `asking party`: the party naming itself as holder in a [Remaining] or [Release] call.

Terms › `the holder`: the party the host holds the key for.

WHY:
A key frees by release or by the current holder's instant passing. The bound is fixed at arrival and never extended: a second waiter admitted while a first still holds fails on its own bound rather than waiting out the first's whole term, so a pattern that reasons about how long a take can block is entitled to that number and no other (Operation 3–5). [Try Take] exists for a caller with other work to do. [Remaining] is a host query and never a clock read by the caller: a caller that subtracts its own reading from a remembered `expires_at` has introduced a second clock and lost the property the atom exists to provide, since the two are minted at different seams (Operation 10). `not-held` covers a party whose term has passed and whose key another holder now holds; callers normally discard the answer, and it is declared because an implementer who treats it as a failure will retry it (Operation 14).

### The terminus, and carrying it as a fence

```text
Fence 1: [Take] MUST return expires_at as an absolute instant on the granting host's clock.
Fence 2: A holder MAY pass a fence to a third party.
Fence 3: IF a work item's effect instant EXCEEDS the fence THEN the fenced party MUST refuse the work item.
Fence 4: The fenced party MUST judge the fence on the fenced party's own clock.
Fence 5: The holder MUST mint the fence as expires_at less the allowance.
Fence 6: The fenced party MUST compare the fence bare.
Fence 7: The holder MUST NOT apply the allowance at the reading.
Fence 8: A holder fencing more than one party MUST mint EVERY fence separately.
Fence 9: A holder MUST NOT derive a second fence bare from a minted fence.
```

Terms › `fence`: `expires_at` less the allowance, handed to a third party as a deadline (a [Fence]) — refuse this holder's work if it would take effect after this instant.

Terms › `allowance`: the declared cross-seam allowance between the granting host's clock and the judging party's clock.

Terms › `fenced party`: the third party a fence is handed to.

WHY:
`expires_at` is the point of the atom ([Expires At]). The judging party's clock is not the granting host's, so the comparison spans two seams and the allowance must be spent somewhere; minted into the instant, never applied at the reading, because applying it at the reading widens the window in the direction that admits a late write — the failure the fence exists to prevent. Minting one instant with the allowance and deriving the others from it bare defeats the margin on every derived instant, the same defect a second time (Fence 8, Fence 9).

### Invariants

- **Invariant 1 — One holder.**
  ```text
  Invariant 1.1: At every instant a key MUST stand in EXACTLY ONE OF free, held by one holder.
  Invariant 1.2: Two takes on one key with no intervening release and no intervening expiry MUST NOT succeed together.
  ```
- **Invariant 2 — The terminus is the instant.**
  ```text
  Invariant 2.1: A grant MUST end at EXACTLY ONE OF the holder's release, the instant passing.
  Invariant 2.2: The host MUST NOT end a grant on any other event.
  ```
  WHY: a holder's death, a network partition, a host restart, a supervisor's judgement — none ends a grant.
- **Invariant 3 — Death is not observable.**
  ```text
  Invariant 3.1: The atom MUST NOT report a holder's death.
  Invariant 3.2: An implementation MUST NOT end a grant early on a belief that the holder has died.
  ```
  WHY: a host that frees a key the moment it believes a holder is gone hands the key to the next party while the previous holder's work may still be in flight, and Invariant 1 is then true of the grant and false of the world.
- **Invariant 4 — A waiter's bound is fixed at arrival.**
  ```text
  Invariant 4.1: A take's bound MUST equal the arrival term.
  Invariant 4.2: Admitting an earlier waiter MUST NOT extend a later waiter's bound.
  ```
- **Invariant 5 — Standing is answered, never assumed.**
  ```text
  Invariant 5.1: [Remaining] and [Release] MUST answer against the (key, holder) pair as the host holds the pair.
  ```
  WHY: a party that has lost standing learns it from the host rather than from its own clock.
- **Invariant 6 — A fence instant carries its allowance.**
  ```text
  Invariant 6.1: EVERY instant handed to a party judging on another clock MUST carry the allowance subtracted.
  Invariant 6.2: The holder MUST mint EVERY such instant independently.
  ```

## Examples

**A section around a write.** A process takes the key for the act it is about to change, receives `expires_at`, does its work, and releases on return. A second process arriving mid-way waits at most the first's remaining term and then either takes the key or is told `unavailable` — and in neither case does it write.

**A fence carried to a store.** The same process passes `expires_at` less the allowance into the store call as a deadline. The process pauses for longer than anyone budgeted; its term passes; the key goes to the next holder. The paused process wakes and issues its write anyway — and the store refuses it, because the deadline it was given has passed on the store's own clock. The next holder's read is therefore complete: nothing of the previous holder's can still land.

**A holder that dies.** A process takes the key and is killed. Nothing is notified. The key stays held until the instant passes, and the next take waits exactly that long. This is the case that motivates Invariant 3: a host that released the key on the death would hand it over while the dead process's last write was still in flight.

## Generation acceptance

This atom writes no records, so its acceptance checks are conformance checks against a host implementation rather than an audit traversal.

### Conformance checks

```text
Check 1.1: An auditor MUST confirm that two concurrent takes on one key, with no release and no expiry between the takes, yield EXACTLY ONE expires_at.
Check 1.2: An auditor MUST confirm that the other take answers EXACTLY ONE OF unavailable, held.
Check 2.1: An auditor MUST confirm that a key held by a party that never releases becomes takeable at the instant.
Check 2.2: An auditor MUST confirm that such a key does not become takeable earlier.
Check 3.1: An auditor MUST confirm that a host leaves the key of a killed holder held through the instant.
Check 3.2: An auditor MUST fail a host that frees the key of a killed holder earlier, whatever the host knows about the holder.
Check 4.1: An auditor MUST confirm that [Take] answers a waiter WITHIN the waiter's arrival term.
Check 4.2: An auditor MUST confirm that [Take] answers a second waiter WITHIN the second waiter's own arrival term.
Check 5.1: An auditor MUST confirm that [Remaining] answers none and [Release] answers not-held to every party that is not the current holder, a former holder whose term has passed included.
Check 5.2: An auditor MUST confirm that neither answer writes anything.
Check 6.1: An auditor MUST confirm that the allowance does not exceed the fence margin of any handed instant.
Check 6.2: An auditor MUST confirm that an instant derived from another is minted with the allowance rather than inheriting the allowance.
```

Terms › `fence margin`: `expires_at − fence`.

NOTE: Check 1 checks Invariant 1; Check 2 Invariant 2; Check 3 Invariant 3; Check 4 Invariant 4; Check 5 Invariant 5; Check 6 Invariant 6.

## Non-goals

```text
Non-goal 1: A holder MUST NOT take a key the holder already holds.
Non-goal 2: The atom MUST NOT offer a depth count.
Non-goal 3: The host MUST admit waiters in arrival order.
Non-goal 4: The host MUST NOT carry forward a waiter whose bound elapsed.
Non-goal 5: The atom MUST NOT make the work under a lease atomic.
Non-goal 6: The atom MUST NOT roll back work done under a lease.
Non-goal 7: The atom MUST NOT isolate a holder's partial work from a reader.
Non-goal 8: The atom MUST NOT write a record.
Non-goal 9: A pattern that must prove a section was held MUST record the section.
Non-goal 10: The atom MUST NOT choose a grant's duration.
Non-goal 11: A pattern that needs the term to cover the pattern's work MUST state and check that obligation.
```

WHY:
The atom does not detect death and no implementation may pretend to (Invariant 3.1, Invariant 3.2). Reentrancy is a caller error, not a supported nesting (Non-goal 1, Non-goal 2). A lease serializes access to a key and nothing more (Non-goal 5–7). `expires_at` is on the granting host's clock (Fence 1); comparing it against any other clock is the cross-seam case Invariant 6 governs.

## Composition notes

```text
Composition note 1: A composing pattern MUST name this atom as an instance capability requirement.
Composition note 2: The deployment MUST supply a host offering the four operations with the semantics above.
Composition note 3: The deployment MUST share the host across every node of the instance.
Composition note 4: A composing pattern MUST own which key protects which work.
Composition note 5: A composing pattern MUST own how long the grant lasts.
Composition note 6: A pattern fencing a downstream system MUST carry expires_at per Fence 1–9.
Composition note 7: A pattern MUST NOT invent a second deadline concept for a fence.
```

WHY:
A section held on one node and not another is no section (Composition note 3). A pattern whose work can exceed the term it asks for has a defect this atom will not catch — it will hand the key on at the instant, exactly as specified (Composition note 5, Non-goal 11). A store deadline and a journal deadline are two uses of one atom (Composition note 6, Composition note 7).

## Standards references

The concept is not itself regulated. It appears in regulated patterns as the mechanism by which a single-writer obligation is met, and those patterns anchor their own regimes; the atom's contribution is that the obligation is met by an argument stated once. The nearest external statement of the same rule is the fencing-token discipline in the distributed-systems literature on lock services, where a lock that ends on a belief about liveness is shown to admit two writers.

## Terms

Each `[Term]` marker above links to its card here; a card states what the concept *is* and its **Kind**.

### Vocabulary

Terms › `actors`: the atom; the host; a holder (also: the holder, the asking holder, the current holder, a former holder); a waiter; a caller; a party; the asking party; a third party (also: the fenced party, the judging party); an implementation (also: an implementer); a composing pattern (also: a pattern); the deployment; an auditor; a key; a grant; a lease; a take; an instant; a work item.

Terms › `records`: empty — the atom writes nothing.

Terms › `record verbs`: identify, compare, normalize, hold, derive, store, wait, succeed, answer, extend, compute, end, reach, treat, return, pass, refuse, judge, mint, apply, stand, report, equal, take, offer, admit, carry, make, roll, isolate, write, record, choose, state, check, name, supply, share, own, invent, confirm, fail.

Terms › `value sets`: `lease state` = free | held. take answers = expires_at | unavailable. try_take answers = taken(expires_at) | held. remaining answers = duration | none. release answers = released | not-held.

Terms › `bounds`: `duration` (the term a take asks for); the allowance.

Terms › `cadences`: empty.

Terms › `qualifiers`: empty.

Terms › `terms`: `key`, `holder`, `lease state`, `arrival term`, `asking party`, `the holder`, `fence`, `allowance`, `fenced party`, `fence margin`, and `expires_at` ([Expires At]).

#### Lease

A grant of exclusive standing over a key, to a named holder, until a declared instant. Ends at the instant or at the holder's release, and at nothing else.

Kind: Type

#### Key

The opaque value a lease protects. Compared by byte identity, never normalized, meaningful only to the pattern that supplies it.

Kind: Parameter

#### Holder

The opaque value naming who holds a lease. Compared by byte identity. Names a party, not a process.

Kind: Parameter

#### Take

The blocking acquisition. Waits at most the arrival term and answers `unavailable` if that term elapses without the key freeing.

Kind: Operation

#### Try Take

The non-blocking acquisition. Answers `taken(expires_at)` or `held`, immediately.

Kind: Operation

#### Remaining

The host query for how much of the asking holder's term is left, or `none` if the asking party is not the holder. Never a clock read by the caller.

Kind: Operation

#### Release

Ends the asking party's grant, or answers `not-held` if it has none. Never reaches another holder's grant.

Kind: Operation

#### Expires At

The absolute instant, on the granting host's clock, at which a grant ends. Returned by a successful take; the value a holder mints a fence from.

Kind: Field

#### Fence

An `expires_at` less the allowance, handed to a third party as a deadline: refuse this holder's work if it would take effect after this instant. Judged on the third party's clock.

Kind: Type

[Key]: #key
[Holder]: #holder
[Take]: #take
[Try Take]: #try-take
[Remaining]: #remaining
[Release]: #release
[Expires At]: #expires-at
[Fence]: #fence

## Status

`draft` — first draft 2026-09-10, extracted from two patterns that described it in prose; the three passes and a fresh-reader gate are owed before any pattern cites it as grounded.

## Ledger

```
status: draft
formal: not applicable — the atom's invariants are conformance obligations on a host, and are checked by its composing patterns' models where the section appears in them
last gate: none

open:
- 2026-09-10-a · refining · Composition notes · the composing pattern owes an obligation that its work fits inside the term it asks for, and this atom states the obligation without giving it a checkable form → decide whether the check belongs here or in each composing pattern.
```

## Decisions

Directional changes only — the turns a future reader must know the pattern took, and why. Everything smaller lives in the commit that made it: `git log -- atoms/lease.md`.

- **2026-09-11 — Rewritten in GRACE lang v0.33; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the operations as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged. *Over:* the prose draft. *Because:* the migration plan — atoms first, since they declare the vocabulary compositions cite.

- **2026-09-10 — Extracted because the obligation kept propagating, not because the shape repeated.** *Chose:* one atom covering the grant and the terminus-as-fence together. *Over:* leaving the prose in the patterns that use it, and over splitting the section from the fence into two concepts. *Because:* four consecutive review rounds on one composition showed a flat defect density — one foundational finding per nineteen kilobytes of body — with most new defects being an obligation added in one place and not carried to the others. Lease semantics were the largest single source of such obligations, reaching into fences, timing, expiry, `remaining`, and worked examples. Splitting the grant from the fence would have preserved exactly the propagation the extraction exists to remove: a fence *is* a terminus handed to another party, and stating it twice is how the two got out of step.

- **2026-09-10 — The terminus is an instant, and death is not observable.** *Chose:* a grant that ends only at its instant or at its holder's release. *Over:* a host that frees a key when it believes the holder is gone, which is what one of the composing descriptions admitted. *Because:* a formal model of a composing pattern rejects the release-on-death variant — a holder that dies with a write in flight frees the key, the next holder reads before that write is visible, and two writers land for one key. The rule is stated here once so that a pattern citing this atom inherits the argument rather than restating it.

NOTE: End of Lease.

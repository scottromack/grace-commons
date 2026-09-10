# Lease

## Summary

A **lease** is a grant of exclusive standing over a key, to a named holder, until a declared instant. It is the smallest concept two patterns in this library kept re-describing in prose: a per-key critical section whose terminus is a time rather than an event.

The whole of the atom is one sentence and its consequences: **the grant ends at the instant, never at an event.** Nothing in a distributed system observes a holder's death, so a grant that ended on death would end on a fact no party holds. A lease therefore ends in exactly two ways — the holder returns and releases it, or the instant passes — and every other property here follows from that.

The instant is a value, not a private timer. A holder may carry it to a third party as a **fence**: a deadline after which that party must refuse work submitted under the grant. That is what makes a lease more than a lock, and it is why the two fences a regulated protocol needs — one on its store, one on its journal — are this concept and not two others.

## Intent

Two patterns in this library describe a per-key section with lease semantics in prose, and a third describes two fences that are the same concept reached from the other end. Each description states the same rules in its own words, and each round of repair to one of them has to be propagated to the others by hand. The concept has its own state machine, its own operations, and its own failure mode, and it belongs to none of the patterns that use it.

This atom exists so that a pattern needing exclusive standing over a key **cites** it rather than restating it, and so that the argument for the one hard rule — the terminus is an instant — is made once, where it can be attacked once.

It is deliberately small. A lease does not decide who should hold it, does not record that it was held, and does not know what the holder does. Those belong to the pattern that composes it.

## Structure

### Identity model

A lease is identified by its **[Key]** and its **[Holder]** together. The key is opaque to this atom: a pattern supplies whatever names the thing being protected, and the atom compares keys by byte identity and never normalizes them. Two keys that differ by a byte are two leases.

The holder is likewise opaque and likewise byte-compared. It names *who* holds, not *what* runs: a holder that restarts and resumes is the same holder only if the pattern gives it the same holder value, and a pattern that mints a fresh holder value per attempt has said that a restart is a different party. Both are legitimate and the choice is the pattern's.

The pair matters because every operation but the take is answered against it. `remaining` asked by a party that is not the holder answers `none`, and a release by a party that is not the holder does nothing. Neither is an error; both are how a party that has lost standing finds out.

### State

One value per key: **free**, or **held by a holder until an instant**. There is no third state. A lease whose instant has passed is free, and no transition marks the passing — the instant is compared against a reading at the moment a question is asked, and the answer is derived rather than stored.

That is the atom's one storage claim and it is what makes the concept implementable over a host that offers nothing but compare-and-set with an expiry.

### Operations

```
take(key, holder, duration) → expires_at | unavailable
try_take(key, holder, duration) → taken(expires_at) | held
remaining(key, holder) → duration | none
release(key, holder) → released | not-held
```

**[Take]** waits for the key to become free — by release, or by the current holder's instant passing — and succeeds the instant it does. It waits for **at most the remaining term of the holder that held the key at the moment this waiter arrived**, and answers `unavailable` if that term elapses without the key freeing. The bound is fixed at arrival and is never extended: a second waiter admitted while a first still holds fails on its own bound rather than waiting out the first's whole term. A pattern that reasons about how long a take can block is entitled to *that* number and no other.

**[Try Take]** never waits. It answers `taken(expires_at)` or `held`, and exists for a caller with other work to do.

**[Remaining]** is a **host query and never a clock read by the caller**: how much of this holder's term is left, or `none` if the asking party is not the holder. A caller that computes the answer by subtracting its own reading from a remembered `expires_at` has introduced a second clock and lost the property the atom exists to provide, since `expires_at` and the caller's reading are minted at different seams.

**[Release]** ends the grant and answers `released`, or `not-held` for a party that is not the current holder — which includes a party whose term has already passed and whose key another holder now holds. **A release never reaches through to another holder's grant.** Callers normally discard the answer; it is declared because an implementer who treats `not-held` as a failure will retry it.

### The terminus, and carrying it as a fence

`take` returns **[Expires At]** — an absolute instant on the granting host's clock — and that value is the point of the atom.

A holder may pass it to a third party as a **[Fence]**: *refuse any work of mine that would take effect after this instant.* The third party judges the deadline on **its own** clock, which is not the granting host's, so the comparison spans two seams and the allowance between them must be spent somewhere. **It is minted into the instant, not applied at the reading:** the holder subtracts the declared allowance before handing the instant over, and the judging party compares bare. Applying it at the reading instead widens the window in the direction that admits a late write, which is the failure the fence exists to prevent.

A pattern that fences more than one thing mints the instant separately for each and subtracts the allowance from each. **Minting one instant with the allowance and deriving the others from it bare defeats the margin on every derived instant**, which is the same defect a second time and is the reason this paragraph is normative rather than advisory.

### Invariants

- **Invariant 1 — One holder.** At every instant, a key is free or held by exactly one holder. Two successful takes on one key with no intervening release or expiry cannot both have happened.
- **Invariant 2 — The terminus is the instant.** A grant ends when its holder releases it or when its instant passes, and by nothing else. No other event — a holder's death, a network partition, a host restart, a supervisor's judgement — ends a grant.
- **Invariant 3 — Death is not observable.** No operation of this atom reports that a holder has died, and no implementation may end a grant early on a belief that one has. A host that frees a key the moment it believes a holder is gone hands the key to the next party while the previous holder's work may still be in flight, and Invariant 1 is then true of the grant and false of the world.
- **Invariant 4 — A waiter's bound is fixed at arrival.** The term a `take` may block for is the remaining term of the holder at the moment the waiter arrived. Admitting an earlier waiter does not extend a later one's bound.
- **Invariant 5 — Standing is answered, never assumed.** `remaining` and `release` answer against the `(key, holder)` pair as the host holds it, so a party that has lost standing learns it from the host rather than from its own clock.
- **Invariant 6 — A fence instant carries its allowance.** An instant handed to a party that will judge it on another clock is minted with the cross-seam allowance already subtracted, and every such instant is minted that way independently.

## Examples

**A section around a write.** A process takes the key for the act it is about to change, receives `expires_at`, does its work, and releases on return. A second process arriving mid-way waits at most the first's remaining term and then either takes the key or is told `unavailable` — and in neither case does it write.

**A fence carried to a store.** The same process passes `expires_at` less the allowance into the store call as a deadline. The process pauses for longer than anyone budgeted; its term passes; the key goes to the next holder. The paused process wakes and issues its write anyway — and the store refuses it, because the deadline it was given has passed on the store's own clock. The next holder's read is therefore complete: nothing of the previous holder's can still land.

**A holder that dies.** A process takes the key and is killed. Nothing is notified. The key stays held until the instant passes, and the next take waits exactly that long. This is the case that motivates Invariant 3: a host that released the key on the death would hand it over while the dead process's last write was still in flight.

## Edge cases and explicit non-goals

- **The atom does not detect death.** It cannot, and no implementation may pretend to. See Invariant 3.
- **No reentrancy.** A holder that takes a key it already holds is a caller error, not a supported nesting. The atom offers no depth count.
- **No fairness beyond arrival order.** Waiters are admitted in the order they arrived, and a waiter whose bound elapses fails rather than being carried forward.
- **Not a transaction.** A lease serializes access to a key. It does not make the work done under it atomic, does not roll anything back, and offers no isolation between a holder's partial work and any reader.
- **No record.** The atom writes nothing an auditor can read. A pattern that must prove a section was held records that itself.
- **The duration is the caller's.** The atom does not choose how long a grant should last; a pattern that needs the term to cover its work states that obligation and checks it.
- **One key, one clock.** `expires_at` is on the granting host's clock. Comparing it against any other clock is the cross-seam case Invariant 6 governs.

## Composition notes

A pattern composes this atom by naming it as an **instance capability requirement**: the deployment supplies a host offering these four operations with these semantics, shared across every node of the instance. A section held on one node and not another is no section.

Two things a composing pattern owns and this atom does not: **which key** protects which work, and **how long** the grant must last. Both are the composing pattern's obligations, and a pattern whose work can exceed the term it asks for has a defect this atom will not catch — it will hand the key on at the instant, exactly as specified.

Where a pattern needs a fence on a downstream system, it carries `expires_at` per §*The terminus, and carrying it as a fence* rather than inventing a second deadline concept. A store deadline and a journal deadline are two uses of one atom.

## Standards references

The concept is not itself regulated. It appears in regulated patterns as the mechanism by which a single-writer obligation is met, and those patterns anchor their own regimes; the atom's contribution is that the obligation is met by an argument stated once. The nearest external statement of the same rule is the fencing-token discipline described in the distributed-systems literature on lock services, where a lock that ends on a belief about liveness is shown to admit two writers.

## Generation acceptance

This atom writes no records, so its acceptance checks are conformance checks against a host implementation rather than an audit traversal.

1. **One holder.** Two concurrent takes on one key, with no release and no expiry between them, yield exactly one `expires_at` and one `unavailable` or `held`. Invariant 1.
2. **Expiry frees.** A key held by a party that never releases becomes takeable at its instant and not before. Invariant 2.
3. **Death frees nothing early.** A holder killed without releasing leaves the key held until its instant; a host that frees it earlier fails this check whatever it knows about the holder. Invariant 3.
4. **The waiter's bound.** A waiter arriving when a holder has `d` of term left is answered within `d`, and a second waiter arriving later is answered within *its* own `d` rather than the first's. Invariant 4.
5. **Standing.** `remaining` answers `none`, and `release` answers `not-held`, to every party that is not the current holder — including a former holder whose term has passed. Neither writes anything. Invariant 5.
6. **The fence carries its allowance.** Every instant handed to a judging party is smaller than the granting instant by at least the declared allowance, and an instant derived from another is minted with the allowance rather than inheriting it. Invariant 6.

## Terms

The canonical concepts this spec refers to. Each `[Term]` marker in the prose above links to its card here.

#### Lease

A grant of exclusive standing over a key, to a named holder, until a declared instant. Ends at the instant or at the holder's release, and at nothing else.

Kind: Type

#### Key

The opaque value a lease protects. Compared by byte identity, never normalized, and meaningful only to the pattern that supplies it.

Kind: Parameter

#### Holder

The opaque value naming who holds a lease. Compared by byte identity. Names a party, not a process.

Kind: Parameter

#### Take

The blocking acquisition. Waits at most the remaining term of the holder present at the waiter's arrival, and answers `unavailable` if that term elapses without the key freeing.

Kind: Operation

#### Try Take

The non-blocking acquisition. Answers `taken(expires_at)` or `held`, immediately.

Kind: Operation

#### Remaining

The host query for how much of the asking holder's term is left, or `none` if the asking party is not the holder. Never a clock read by the caller.

Kind: Operation

#### Release

Ends the asking party's grant, or answers `not-held` if it has none. Never reaches through to another holder's grant.

Kind: Operation

#### Expires At

The absolute instant, on the granting host's clock, at which a grant ends. Returned by a successful take, and the value a holder may carry as a fence.

Kind: Field

#### Fence

An `expires_at` handed to a third party as a deadline: refuse this holder's work if it would take effect after this instant. Judged on the third party's clock, so the instant is minted with the cross-seam allowance already subtracted.

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

- **2026-09-10 — Extracted because the obligation kept propagating, not because the shape repeated.** *Chose:* one atom covering the grant and the terminus-as-fence together. *Over:* leaving the prose in the patterns that use it, and over splitting the section from the fence into two concepts. *Because:* four consecutive review rounds on one composition showed a flat defect density — one foundational finding per nineteen kilobytes of body — with most new defects being an obligation added in one place and not carried to the others. Lease semantics were the largest single source of such obligations, reaching into fences, timing, expiry, `remaining`, and worked examples. Splitting the grant from the fence would have preserved exactly the propagation the extraction exists to remove: a fence *is* a terminus handed to another party, and stating it twice is how the two got out of step.

- **2026-09-10 — The terminus is an instant, and death is not observable.** *Chose:* a grant that ends only at its instant or at its holder's release. *Over:* a host that frees a key when it believes the holder is gone, which is what one of the composing descriptions admitted. *Because:* a formal model of a composing pattern rejects the release-on-death variant — a holder that dies with a write in flight frees the key, the next holder reads before that write is visible, and two writers land for one key. The rule is stated here once so that a pattern citing this atom inherits the argument rather than restating it.

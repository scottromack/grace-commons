---
title: Lease — history
nav_exclude: true
search_exclude: true
---

# Lease — history

The dated record of how [Lease](./lease.idd) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/lease.md`.

## Decisions

Entries that record the formal-layer vote or a migration rather than a turn the pattern took.

- **2026-09-10 — Extracted because the obligation kept propagating, not because the shape repeated.** *Chose:* one atom covering the grant and the terminus-as-fence together. *Over:* leaving the prose in the patterns that use it, and over splitting the critical section from the fence into two concepts. *Because:* four consecutive review rounds on one composition showed a flat defect density — one foundational finding per nineteen kilobytes of body — with most new defects being an obligation added in one place and not carried to the others. Lease semantics were the largest single source of such obligations, reaching into fences, timing, expiry, remaining, and worked examples. Splitting the grant from the fence would have preserved exactly the propagation the extraction exists to remove: a fence *is* a terminus handed to another party, and stating it twice is how the two got out of step.

- **2026-09-10 — The terminus is an instant, and death is not observable.** *Chose:* a grant that ends only at its instant or at its holder's release. *Over:* a host that frees a key when it believes the holder is gone, which is what one of the composing descriptions admitted. *Because:* a formal model of a composing pattern rejects the release-on-death variant — a holder that dies with a write in flight frees the key, the next holder reads before that write is visible, and two writers land for one key. The rule is stated here once so that a pattern citing this atom inherits the argument rather than restating it.

- **2026-09-11 — Rewritten in GRACE lang v0.33; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the operations as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged. *Over:* the prose draft. *Because:* the migration plan — atoms first, since they declare the vocabulary compositions cite.

- **2026-10-02 — The atom gives the form of a lease's sizing for unfenced work, and none of its numbers.** *Chose:* Sizing 1 through 9 — a declared call pause bound, a lease that reads expired below twice that bound, no write on an expired reading, a term no shorter than the work's bound, a start margin, a share-of-budget rule, a no-answer arm — with Non-goal 10 kept and Non-goal 12 added, and the Ledger's open question answered: the checkable form lives here, the numbers in each composing pattern. *Over:* leaving the form in each composing pattern, and over moving the closure sum, closure floor and measured enumeration into the atom. *Because:* the form is the same for every pattern whose writes carry no fence, and it was being restated, and re-attacked, inside one 281 KB composition; the numbers price a pattern's own work (how many record actions, how many enumerations) and an atom that chose them would own a duration, which Non-goal 10 forbids.

- **2026-10-04 — The formal-layer vote is yes.** *Chose:* lease.tla with four twins and a probe — a death-freed key, a one-pause margin, a bare fence, a release with a call in flight — each rejected, and the invariant that no write of a former holder lands after the next holder has read. *Over:* the draft's "not applicable", which left the atom's claims to its composers' models. *Because:* one holder, a terminus that is an instant and a fence that carries its allowance are temporal claims, and a composition model that assumes them cannot be what verifies them.

- **2026-10-04 — Grounded: a holder value names one take, release is the holder's last call, and what the atom cannot hold the deployment declares.** *Chose:* a fresh holder value for every take and none carried across a restart, so a stale or duplicated release finds not-held (Identity 6, 7; Identity 5 tombstoned); no release with a call in flight and no write after one (Composition note 5c, 5f); and eleven capability requirements for what only a deployment can make true — one clock per key, grants kept across a restart, calls held inside the call pause bound, an answer that means landed, a refusal that means never, a write applied once, a take delivered once (Capability requirement 1 through 11). *Over:* a holder value reusable across takes and restarts at the pattern's choice; a release rule with an exception for a pattern that shows a late landing to the next holder, which no reader could pin to a time; and host-side memory of every value ever carried. *Because:* each of three adversarial passes reached two writers on one key by a route the host rules alone could not close — a stale release, a release ahead of an answered-then-applied write, a take delivered twice.

- **2026-10-04 — The sizing is anchored to readings, and a waiter's bound is an instant.** *Chose:* one host reading per unit of work, the unit's time counted from the asking; a lone write issued within one call pause of its reading; a work's bound that includes two call pauses and a term that exceeds it; a share of a budget taken without waiting; an unanswered grant read expired to its end (Sizing 2 through 9, Term unit's start, Term unanswered); the key free at the reading that equals expires_at, the first waiter granted at the first free reading, a try-take that does not pass a waiter, and a restart that ends the line (Term passed instant, Term waiter's bound, Operation 1a through 6c). *Over:* a start gate and a write gate with no reading named, a waiter's bound held as a length, and a boundary instant two rules claimed. *Because:* the rules of 2026-10-02 carried Audit Trail's arithmetic and had never been read cold; the first round found the boundary obliging a take to succeed and to fail at one reading. Compositions affected: Audit Trail's completion bounds include two call pauses (its record action, purge and seal completion bound 2) and it declares the longest duration per key (its Per-act critical section 15c); Recoverable Invocation releases with a call in flight and binds no sizing (its Ledger lines 2026-10-04-a through c).

- **2026-11-21 — The twelve open lines close: a holder's clock measures no span short, a unit runs from its first call, a restarted host answers no waiter, and the deployment's, the holder's and the composer's obligations each have one subject.** *Chose:* Capability requirement 12, the deployment's holder clocks under which no span the Sizing rules time on the holder's own clock is longer on the host's (Execution Contract Logic confinement 7; until now only a WHY said the rate was the deployment's, and a holder clock running slow lands a write timed inside its bound past the instant); the unit's start moved from the asking to the issue of the unit's first call, which follows its reading within one call pause (Sizing 5c), so the unit's bound runs from the call's issue as Defensible Retention's audit write latency and Resolve a Person's Data Rights' planned call latency already measure it, Capability requirement 7 scoped to writes outside a unit, and Capability requirement 13 holding a unit's writes inside the unit's bound; Sizing 2b reading a [Remaining] that answers none as expired; Operation 1b excepting, and Operation 5d leaving unanswered, a [Take] that waited across a host restart; Capability requirement 8, 9 and 10 bound on the deployment; Non-goal 1, 9 and 11 moved to Composition note 9, 10 and 11, the first on the process the new Term process names; Non-goal 13 and 14 (no bound on a lease call's inputs at the host, no cap on the line), every non-goal with its owner; checks for a release before a waiter's bound, a restart, arrival order, the budget share, one reading and a timely start per unit, the release rules and Capability requirement 8 through 13; the families named for their headings (`### Sizing`, `### Fence`); Terms take, process, lease call, host, arrival order, work item, taken effect, holder's span and bare; a plain Summary, an Intent of purpose, examples with numbers that walk no answer, not-held, a restart and a budget share, and a Standards reference that tells a deadline from a fencing token. The extraction line (2026-10-04-a) closes on Scott's direction 133 (2026-11-19): no extraction now; it reopens when a second composer binds the Sizing rules. *Over:* a drift term in the start floor, which would have the atom spend a rate it states no value for; keeping the unit's origin at the asking, which left both adopters' latencies short by the gap between reading and call; and primitive policies at the host, which would give the signature a refusal surface no composer reads. *Because:* the rules of 2026-10-04 left each of these to a WHY, a composer or a term no rule spent (the open lines of Final Critique 4 and of the 2026-10-05 gates). The twin `lease-buggy-drift.tla` shows Capability requirement 12 load-bearing: a holder clock one tick slow lands the lone write at the instant, after the next holder has read. Compositions affected (`cites.py --reach`): Recoverable Invocation (act section 16, 19, pause bound 1), Defensible Retention (Capability requirement 54, Cascade critical section 6), Resolve a Person's Data Rights (Capability requirement 36, External check 11) and Audit Trail (Per-act critical section 1d, Concurrency 1g); the unit's new origin matches Defensible Retention's audit write latency and Resolve a Person's Data Rights' planned call latency as they stand.

- **2026-11-26 — The atom converted to the tree order, batch 6 of the converter: its guard offer stands, it mints no id, and it names no other pattern.** *Chose:* the tree order, every label kept and none renumbered; the guard offer it already made stands as written; no key offer, since the atom writes no records (Term records: empty) and Bonds Key 9 asks no minted id of it, as on Money. Labelled rules 148 before, 148 after; 527 lines before, 549 after. *Over:* the drafted "empty id" offer, the converter's fallback reading the word empty as a record, now fixed in the converter. *Because:* unit `atom: Lease, converted` (batch 6, 5 of 5).

- **2026-11-26 — GLM's review cured: the joiner's answer owned, the ledger reconciled, the need position stated, the sources named.** *Chose:* Operation 4 answers unavailable once the host has admitted at the reading (Operation 2c), so a [Take] that joins behind a waiter at a free key has a rule, which Check 4.4 already tested (S1); the formal and coverage lines say when each TLA+ twin landed and that Invariant 4.2 is still owed, with Sizing 3a's row owing nothing (S2, measured from lease.tla's header and the twins' first commits); a Needs section stating that the atom declares no need (S3); Gray and Cheriton's leases paper (SOSP 1989) and Chubby's sequencer (OSDI 2006) in Source, both checked (S4); Term no answer speaks of a failure, as no call carries a refuses line (S5); the table of contents every sibling carries (N1); the section The leases (N3); the composition notes in numeric order (N4); a NOTE that the signatures hold Invariant 3.1 (N5); the fence example names the write Sizing 3a already forbade (N6); Capability requirement 12 reads both spans on their own clocks, the same bound (N7); Term expired spelled out (N9). *Over:* N2 (the gaps stand tombstoned below), N8 (the migrated qualifier is every page's form) and O2 (the guard offer carries exactly bonds.md's guard offer fields). *Because:* unit `atom: Lease, review cures`, from assets/design/lease-atom-review.md (Scott 2026-11-26 10:05 and 10:07 AM Central).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Lease](./lease.idd) may carry it again.

### Structure › Identity model

```
Deleted: Identity 5. Identity 6 owns it.
```

### Structure › The terminus, and carrying it as a fence

```
Deleted: Fence 7. Fence 6 owns it.
```

### Non-goals

```
Deleted: Non-goal 1. Composition note 9 owns it: an obligation on the process that took a grant, which the atom names by Term process.
Deleted: Non-goal 3. Operation 5a owns it.
Deleted: Non-goal 4. Operation 5b owns it.
Deleted: Non-goal 9. Composition note 10 owns it: an obligation on a composing pattern, not a non-goal.
Deleted: Non-goal 11. Composition note 11 owns it: an obligation on a composing pattern, not a non-goal.
```

### Composition notes

```
Deleted: Composition note 2. Capability requirement 1 owns it.
Deleted: Composition note 3. Capability requirement 2 owns it.
```

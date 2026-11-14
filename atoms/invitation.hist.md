---
title: Invitation — history
nav_exclude: true
search_exclude: true
---

# Invitation — history

The dated record of how [Invitation](./invitation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/invitation.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-13 — The window boundary is declared once as a window reading, in the same two-member shape [Provisional Commitment](./provisional-commitment.md) uses.** *Chose:* live | lapsed, with the boundary instant declared onto the lapsed side, cited by the three resolving-write guards and by the effective-status projection. *Over:* repeating the comparison at each guard, which is how the prose carried it. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and the arithmetic belongs in the declaration rather than in a rule (Hard invariant 24). The two atoms name the members differently — `open` there, live here — because the record differs; the *shape* being identical across two independent specs is a new instance of the absence-as-nonexistence class the grammar's watch list counts, and is flagged rather than unified, since nothing yet says a shared reading should have one owner.
- **2026-09-13 — The family is resolving write, not `resolving action`, and the difference from [Provisional Commitment](./provisional-commitment.md) is meant.** *Chose:* resolving write — [Accept], [Decline], [Revoke]. *Over:* `resolving action`, which is the name the same concept carries one atom over. *Because:* this atom has a [Read], so *action* would include a surface that resolves nothing and writes nothing, and the whole of the derived-expiry posture is that reading and writing are different things here. Provisional Commitment has no read, so nothing there needs the narrower word. The names diverge because the records do; a reader crossing between them should not assume the drift is carelessness (council read 39).

## Migration notes

- **2026-09-13 — Invariant 1.2, tombstoned as a rule that could not bind.** A draft of the migration carried a second rule — *an admitted resolving write MUST NOT change a resolution field the write found* — and it could not bind. An admitted resolving write runs only on a pending invitation (Operation 16 refuses every other case), and a pending invitation carries no resolution field (State 6), so the set the rule quantified over is empty at every reachable state. Same class as the resource return [Provisional Commitment](./provisional-commitment.md) re-homed one atom earlier: a MUST that cannot be violated is decoration, and the cure is to find the rule that already makes it true rather than to keep a second copy that cannot fail (council read 39).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Invitation](./invitation.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 14. Execution Contract Database 7 owns it.
```

### Structure › State

```
Deleted: State 8. Invariant 12.1 owns it.
Deleted: State 13. Invariant 10.1 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 7. Execution Contract Database 3 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 13 owns it.
Deleted: Capability requirement 10. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 11. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 19. Execution Contract Refusal 1 owns it.
Deleted: Operation 21. Execution Contract Refusal 1 owns it.
Deleted: Operation 22. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 26. Execution Contract Refusal 1 owns it.
Deleted: Operation 34. Execution Contract Database 1 owns it.
Deleted: Operation 36. Execution Contract Refusal 1 owns it.
Deleted: Operation 37. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 38. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 39. Execution Contract Read 4 owns it: a refused call writes nothing.
Deleted: Operation 45. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 46. Execution Contract Logic confinement 3 owns it.
```

### Structure › Invariants › Invariant 1 — Initiation immutability

```
  Deleted: Invariant 1.2. State 6 and Operation 16 leave a resolving write no resolution field to find.
```

### Structure › Invariants › Invariant 3 — Acceptance binds identity

```
  Deleted: Invariant 3.2. Execution Contract Database 1 owns it.
  Deleted: Invariant 4. Identity 13, State 2 and Operation 6 own the opaque invitee.
```

### Structure › Invariants › Invariant 10 — Invitation durability

```
  Deleted: Invariant 10.2. Execution Contract Database 1 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.2. Invariant 12.1 owns it.
Deleted: Check 8.2. Check 8.1 owns it.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 1. Execution Contract Database 1 owns it.
Deleted: Atomic writes 2. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 4. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

---
title: Invitation — history
nav_exclude: true
---

# Invitation — history

The dated record of how [Invitation](./invitation.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/invitation.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-13 — The window boundary is declared once as a window reading, in the same two-member shape [Provisional Commitment](./provisional-commitment.md) uses.** *Chose:* live | lapsed, with the boundary instant declared onto the lapsed side, cited by the three resolving-write guards and by the effective-status projection. *Over:* repeating the comparison at each guard, which is how the prose carried it. *Because:* a spec pays for a proposition once (GRACE-lang Authority 3), and the arithmetic belongs in the declaration rather than in a rule (Hard invariant 24). The two atoms name the members differently — `open` there, live here — because the record differs; the *shape* being identical across two independent specs is a new instance of the absence-as-nonexistence class the grammar's watch list counts, and is flagged rather than unified, since nothing yet says a shared reading should have one owner.
- **2026-09-13 — The family is resolving write, not `resolving action`, and the difference from [Provisional Commitment](./provisional-commitment.md) is meant.** *Chose:* resolving write — [Accept], [Decline], [Revoke]. *Over:* `resolving action`, which is the name the same concept carries one atom over. *Because:* this atom has a [Read], so *action* would include a surface that resolves nothing and writes nothing, and the whole of the derived-expiry posture is that reading and writing are different things here. Provisional Commitment has no read, so nothing there needs the narrower word. The names diverge because the records do; a reader crossing between them should not assume the drift is carelessness (council read 39).

## Migration notes

- **2026-09-13 — Invariant 1.2, tombstoned as a rule that could not bind.** A draft of the migration carried a second rule — *an admitted resolving write MUST NOT change a resolution field the write found* — and it could not bind. An admitted resolving write runs only on a pending invitation (Operation 16 refuses every other case), and a pending invitation carries no resolution field (State 6), so the set the rule quantified over is empty at every reachable state. Same class as the resource return [Provisional Commitment](./provisional-commitment.md) re-homed one atom earlier: a MUST that cannot be violated is decoration, and the cure is to find the rule that already makes it true rather than to keep a second copy that cannot fail (council read 39).

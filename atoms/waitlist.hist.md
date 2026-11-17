---
title: Waitlist — history
nav_exclude: true
search_exclude: true
---

# Waitlist — history

The dated record of how [Waitlist](./waitlist.md) got here, moved out of the spec because a reader does not need it to use the spec today. Everything smaller is in `git log -- atoms/waitlist.md`.

## Decisions

- **2026-11-17 — Drafted through the Grace connector mirroring Cart.** *Chose:* a line of spots for one offering — start, join, leave, call next, close and two reads — and nothing about openings, offers, notice or authority *Over:* a waitlist that also counts seats and holds the offer *Because:* Capacity Constraint Enforcement counts openings and leaves fair ordering to a queueing pattern (its Non-goals 3 and 4), Provisional Commitment holds an offer for a set window, and Reserve from Pool leaves waitlisting to a downstream surface (its Non-goal 16).
- **2026-11-17 — Order by a join number the atom sets.** *Chose:* one more than the waitlist's highest join number *Over:* ordering by join instant *Because:* two joins can share an instant and a clock can step back, while serialized joins (Execution Contract Database 2) never share a number.
- **2026-11-17 — A called spot ends.** *Chose:* [Call Next] stands the front spot in called, a final state *Over:* keeping the spot until the offer resolves, or putting the person back in place *Because:* the offer belongs to Provisional Commitment, and the requester chose that a person whose offer falls through joins again at the back.
- **2026-11-17 — One open waitlist per offering.** *Chose:* [Start] answers the open waitlist's id and writes nothing *Over:* refusing a second start, or allowing two open waitlists for one offering *Because:* a refusal strands a caller whose first answer was lost without a waitlist id, and two open lines for one offering break first come, first served.
- **2026-11-17 — Spot ids drawn at random.** *Chose:* a spot id from a cryptographically secure random source *Over:* a sequential id *Because:* a spot id is what a person holds to leave, and [Capability](./capability.md)'s token sets the precedent that such a value cannot be guessed.
- **2026-11-17 — Closing ends every waiting spot.** *Chose:* [Close] stands every waiting spot in unserved *Over:* leaving spots waiting on a closed waitlist *Because:* a closed waitlist with people recorded as waiting tells the record something untrue.

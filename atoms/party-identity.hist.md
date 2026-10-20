---
title: Party Identity — history
nav_exclude: true
---

# Party Identity — history

The dated record of how [Party Identity](./party-identity.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/party-identity.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-13 — Insertion order is authoritative and a recorded instant is advisory, stated as its own rule family.** *Chose:* an `Ordering` family, with Ordering 4 and Ordering 5 forbidding a reading or a reconstruction from turning on an instant. *Over:* the prose's paragraph saying the same thing beside the state machine. *Because:* Operation 18's *most recent suspend* is the atom's central guarantee and it is decidable two ways, one of which is unsound — under clock skew a later event can carry an earlier instant, and two readers would then disagree about whether a party may be reinstated. A rule family is what makes the sound reading the one a generator implements.
- **2026-09-13 — Invariant 9 and Invariant 10 are tombstoned; Identity owns assigned id stability and uniqueness.** *Chose:* Identity 6 through 9 as the single owners. *Over:* keeping the invariants, which restated them. *Because:* Authority 3. Checked before removing: the corpus cites Party Identity Invariants 1, 4, 5 and 11 — from [Customer Onboarding](../compositions/customer-onboarding.md) and the coverage matrix — and cites neither 9 nor 10, so the tombstones break no citation.

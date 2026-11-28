---
title: Session-Gated Authorization — history
nav_exclude: true
search_exclude: true
---

# Session-Gated Authorization — history

The dated record of how [Session-Gated Authorization](./session-gated-authorization.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/session-gated-authorization.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the single action as a signature block with `Action wiring` carrying the two-step gate, `Primitive policy` carrying the boundary predicate, `Concurrency` carrying the revocation race, the four invariant numbers unchanged, and the acceptance section's two declared tiers split into `Check` and `External check` exactly as the prose divided them. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label, so the rewrite is free of frozen-number risk. The families are the wiring surfaces this composition actually has — no `Event schema`, no `Replay`, because it stores nothing and rebuilds nothing.

- **2026-09-14 — The gate is Session's, the closure is this composition's, and the Summary said both were emergent.** *Chose:* to cite the gate and own the closure — `Composes 7` names [Session](../atoms/session.idd)'s `Composition note 4`, `Invariant 1.2` through `Invariant 1.4` are tombstoned to it, `Invariant 1.1` stands, and the Summary now claims exactly the two rules this composition holds. *Over:* carrying the prose's *emergent* claim unchanged, which the atom contradicts; and over deleting Invariant 1 entirely, which was the reviewer's counsel and cuts one rule too deep. *Because:* `Composition note 4` fires on an invalid answer *given* and `Invariant 1.1` fires on no valid answer *given*, so they do not normalize identically (Authority 4) — a deployment that skipped `validate` altogether would satisfy the note and breach the invariant. `Authority 6` forbids a citing spec to restate a rule, which is what the three enumerations did; it does not reach a rule that is strictly stronger. [Permissions](../atoms/permissions.idd)'s `Composition note 3` is the third shape again: it assigns the caller-to-subject binding without stating it, so `Invariant 2` is owned here outright. The maintainer's ruling settles the row titled *Which direction a rule may point across a seam* in `open-questions.md`, open since council read 36: **atoms may bind compositions; a composition cites what the composition inherits and owns what the composition adds** (council read 53).

- **2026-09-27 — The length bound sits under the Permissions string cap, and the page steps down to run the round that rule owes.** *Chose:* Primitive policy 10, and `partially resolved` until a three-pass round clears it. *Over:* a routed line on a grounded page. *Because:* a cold regeneration met the gap — Permissions answers an over-length argument denied, so a bound above its cap reports a malformed request as a refusal, the collapse Primitive policy 2 through 4 exist to prevent — and the entry *Touch triggers re-pass* in `pressure-testing.md` downgrades a grounded page for a load-bearing edit (council read 236).

- **2026-11-20 — The length bound is held per input, and Check 1.1 and Check 3.1 move under External check 3, 6 and 7.** *Chose:* the session token's bound defaults to Session's maximum length and the action scope's to the Permissions instance's string cap, a declared bound never above its constituent's cap (Primitive policy 1, 10, 11, Term length bound); Check 1.1 deleted to External check 6 and 7, Check 3.1 to External check 3. *Over:* one bound for both inputs at the string cap, under which a session token Session accepts (up to 1,024 code points) answered invalid-request on every call; and over keeping the two checks on a runtime surface the composition holds no record for. *Because:* open lines 2026-11-18-a, 2026-11-05-a and 2026-09-27-a (Scott, 2026-11-19, group 8 of his ruling of 21:32Z: a field an attacker or operator controls gets an explicit cap and a refusal; the checks follow External checks 6 and 7, which moved for the same reason).

## Migration notes

- **2026-09-15 — Wiring decision 1, moved from Action wiring.** Wiring decision 1 is Action wiring 4's words, moved to the heading that names what it is when the headings were standardized (council read 80).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Session-Gated Authorization](./session-gated-authorization.md) may carry it again.

### Composition logic › Action wiring

```
Deleted: Action wiring 4. Wiring decision 1 owns it.
```

### Composition-level invariants › Invariant 1 — Session gates authorization

```
  Deleted: Invariant 1.2. Session Composition note 4 owns it.
  Deleted: Invariant 1.3. Session Composition note 4 owns it.
  Deleted: Invariant 1.4. Session Composition note 4 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.1. External check 6 and External check 7 own it.
Deleted: Check 1.2. External check 6 owns it.
Deleted: Check 1.3. External check 7 owns it.
Deleted: Check 3.1. External check 3 owns it.
```

### Composition notes

```
Deleted: Composition note 2. Composition state 4 owns it.
```

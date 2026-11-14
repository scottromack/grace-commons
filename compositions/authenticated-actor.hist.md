---
title: Authenticated Actor — history
nav_exclude: true
search_exclude: true
---

# Authenticated Actor — history

The dated record of how [Authenticated Actor](./authenticated-actor.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/authenticated-actor.md`.

## Decisions

Entries that record a migration, a council read's collapse, a family placement or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except one invariant the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision`, `Concurrency` and `Reconciliation` as the surfaces, the four surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Reconciliation` is the one family minted, for the orphaned-credential leg — a second instance of the shape [Idempotent Reservation](./idempotent-reservation.md) minted `Eviction` for, a leg running outside an invocation, and the two are deliberately **not** merged: one evicts and one reports, one takes a critical section and one refuses to, and calling them one family would bury the difference that decides whether either owes a liveness bound. Two names at one spec each, both flagged, both waiting (council read 61).
- **2026-09-14 — The fourth preservation-claim collapse, and the cheapest.** *Chose:* `Composes 4`, with `Invariant 5 — Constituent invariants preserved` tombstoned to it. *Over:* keeping it. *Because:* council read 53's ruling at its fourth seam. This spec spent **one** rule covering both constituents where the other three spent one per atom, so one tombstone closes what took two or three elsewhere — and the reason is visible in the document: every other invariant carries a `Rests on:` clause naming the constituent guarantees it leans on, which is provenance done properly at the invariant level. The blanket was the single place that discipline lapsed into a restatement. What it carried beyond the blanket survives as `Composes 5` through `Composes 10`: the refusals (no verify at the gate, no rotate, no revoke, no registry write) and the gate's key, none of which either atom guarantees about a caller.
- **2026-09-14 — Both extraction-pending elements were classified before the rewrite began.** *Chose:* to declare the classification against the prose spec at council read 59 and carry it into the rules here unchanged. *Over:* discovering it during the migration, which is when every other composition's state question surfaced. *Because:* the classification does not depend on the language — the section titled Composition state in `execution-contract.md` turns on whether the truth is reconstructible from constituent stores, which is a fact about the wiring — and settling it first made the `Composition state` family write itself. That order is worth keeping: classify, then migrate.
- **2026-09-14 — `Reconciliation` re-cut as `Housekeeping`, on a discriminator the first cut got wrong.** *Chose:* the family renamed, with the seven rules and every citation of them moving with it. *Over:* keeping the name and letting `Reconciliation` reach three specs. *Because:* the entry above split this leg from [Idempotent Reservation](./idempotent-reservation.md)'s on *one evicts and one reports*, and the drift pass `GRACE-lang.md` Standard label 7 requires found that axis predicts the liveness bound on **two of four** legs — this leg reports and owes none, Eviction takes a critical section and writes and owes none, and the verb decides neither. What survives every member is whether anything **awaits** the leg's output: [Login](./login.md)'s and [Defensible Retention](./defensible-retention.md)'s sweeps discharge a promise inside a declared window and owe a bound; this leg and idempotent reservation's evict or report with nobody waiting and owe none. Two families of two, cut on the guarantee rather than on the verb (council read 64).
- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* an absent credential type passing the gating default (Action wiring 30), where Primitive policy 4 refused it as blank and the default had no reader; Credential's register refusals landing (Action wiring 31, 32), where storage-failure naming the credential sat on the signature with no rule; a lapsed holder finding its actor reference bound answering namespace-conflict naming the binding (Action wiring 33), where only the principal side had a landing and the guard's own answer would have said nothing committed; the refused entry's observed status and credential id stated (Action wiring 34), as the prose stated them; where Check 3.2 cited a rule that says neither; a refused call's failed append answering attest-failed naming a bare log (Action wiring 35), where Action wiring 25 demanded an attestation id no refusal has, and Invariant 4.1 scoped to the calls that append; the orphaned-credential leg keyed on the pair (Housekeeping 6), where keying on the binding's initial credential id reported every rotation's successor as an orphan; a known attestation resolved whatever its verification result (Action wiring 27), where the rewrite resolved only a verified one; and the attest lease's two termini (Action wiring 36, 37), which the prose carried and the rewrite left to a WHY. *Over:* the 2026-09-14 rewrite's readings. *Because:* each was a rule the page's own signature, walkthrough or checks contradicted, or a decision the prose made and the rewrite dropped, found by building it; the pair is the key the gate already uses (Composes 9).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Authenticated Actor](./authenticated-actor.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 3. Execution Contract Database 1 owns it.
Deleted: Composition state 8. Action wiring 45 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 7. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 8. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 and Execution Contract Database 2 own it: the composition names no completion bound or cadence for a deployment to leave unset.
Deleted: Capability requirement 15. Execution Contract Conformance 9 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Deleted: Action wiring 10. Execution Contract Database 2 owns it.
Deleted: Action wiring 12. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 13. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Deleted: Action wiring 16. Execution Contract Database 2 owns it.
Deleted: Action wiring 38. Action wiring 47 owns it.
Deleted: Action wiring 33. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Deleted: Action wiring 35. Action wiring 25 owns it.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 2. Execution Contract Database 2 owns it.
Deleted: Wiring decision 3. Execution Contract Database 2 owns it.
```

### Composition logic › Housekeeping

```
Deleted: Housekeeping 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Housekeeping 2. Execution Contract Database 1 owns it.
Deleted: Housekeeping 3. Execution Contract Database 1 owns it.
Deleted: Housekeeping 4. Execution Contract Database 1 owns it.
Deleted: Housekeeping 5. Execution Contract Database 1 owns it.
Deleted: Housekeeping 6. Execution Contract Database 1 owns it.
Deleted: Housekeeping 7. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 1 — Revocation cascade, attest-surface closure

```
  Deleted: Invariant 1.2. Action wiring 19 and Execution Contract Database 2 own it.
  Deleted: Invariant 1.3. Invariant 1.1 owns it: a revoked credential never reads effective-active again (Credential Invariant 5.1), and a new credential for the principal reference AND the credential type opens the gate (Composes 9).
```

### Composition-level invariants › Invariant 2 — Secret-surface separation

```
  Deleted: Invariant 2.3. Capability requirement 14 owns it.
```

### Composition-level invariants › Invariant 4 — Attestation traceability

```
  Deleted: Invariant 4.1. Action wiring 45 owns it.
  Deleted: Invariant 5. Composes 4 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Execution Contract Database 2 owns it.
Deleted: Check 4.1. Execution Contract Database 1 owns it.
Deleted: Check 6.1. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 2. Execution Contract Database 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 14. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so a revoke of the credential a gate read commits before the read or after the attestation.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue to bound.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 2. Capability requirement 14 owns it.
Deleted: Composition note 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
Deleted: Composition note 6. Execution Contract Database 1 owns it: a registration's credential and binding commit together, so the composition reports no orphaned credential.
```

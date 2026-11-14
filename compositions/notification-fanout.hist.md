---
title: Notification Fanout — history
nav_exclude: true
search_exclude: true
---

# Notification Fanout — history

The dated record of how [Notification Fanout](./notification-fanout.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/notification-fanout.md`.

## Decisions

Entries that record a migration, a council read's collapse, two readings of a gate's open lines or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except two invariants the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision`, `Clock semantics` and `Indeterminate outcome` as the wiring surfaces, the six surviving invariant numbers unchanged, and the acceptance section's own two-tier split carried across as `Check` and `External check`. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. Two families are worth naming: the *Retry semantics* section is `Indeterminate outcome` — the family [Approval Step](../atoms/approval-step.md), [Medication Order](../atoms/medication-order.md) and [Party Identity](../atoms/party-identity.md) already carry — so it was taken rather than minted, which puts that family at four specs and makes this the first composition to hold it. And *Logic confinement* is `Capability requirement`, the standard family, because what the section states is what the host must supply.
- **2026-09-14 — Two preservation claims are one citation.** *Chose:* `Composes 7`, with `Invariant 6` and `Invariant 7` tombstoned to it. *Over:* keeping them. *Because:* the prose already drew the line the ruling needs — *Invariant 1 through 5 and 8 emerge from the composition; Invariants 6 and 7 are preservation claims* — and Execution Contract Conformance 8 settles a preservation claim by reference, so restating it twice was a citing spec restating a rule it cites (Authority 6, council read 53, council read 55). What the two carried beyond the blanket survives as `Composes 5` and `Composes 6`: reading the subscription store only through `subscribers_for` and refusing to reach past `create` are this composition's own restraint and are not guarantees either atom makes about a caller.
- **2026-09-14 — Five of the Ledger's six open lines are closed by the migration.** *Chose:* to close `2026-08-27-g`, `-h`, `-i`, `-k` and `-l` in the rewrite and strike them from the Ledger's open list, leaving `-j`. *Over:* migrating the language and leaving six known defects standing behind it. *Because:* all five were language or ownership defects a rewrite is the natural moment to fix — an unconditional coverage claim that needed the crash bound (`Wiring decision 3`, `Non-goal 3`, `Invariant 1`'s WHY), an acceptance preamble opening universally where two checks need a composed Event Log (now conditional, and stated in the preamble), Notification's own acceptance classified both record-clearable and external (classified once, as `External check 5`), invalid-request's provenance stated two ways (stated once, in `Primitive policy`'s WHY), and the two constituents' divergent non-empty definitions left unnamed (named in `Indeterminate outcome`'s WHY — Subscription admits a whitespace-only ref and caps nothing, Notification refuses both). `-j` stays open because it is a design choice rather than a defect: an Event Log entry carrying the full created and failed lists is unbounded in N against Event Log's payload cap, and bounding, chunking or digesting it is the maintainer's to pick. The `status:`, `formal:` and `last gate:` lines are untouched (council read 56).
- **2026-09-28 — The 2026-08 gate's open lines, read against the rewritten page.** *Chose:* of 28 open lines, 9 were already closed by the rewrite and are removed; 19 were live and are cured here — the create bound, its disclosure and no transport retry (Capability requirement 8 through 10); Duplicate Prevention keyed by a caller-supplied event identity and the fanout-to-record relation's two sides (Composition state 5 through 7); the failure discriminator as a caller's heuristic (Indeterminate outcome 5, 6, now MAY); the cost of pairing a created id with its subscriber stated; and the summary, examples, Fanout Id entry and standards brought to the rules, including two references to sections that no longer exist. *Over:* carrying lines whose anchors — step 4, *Retry semantics*, the externally-clearable list — the rewrite removed. *Because:* a Ledger that names sections the page no longer has cannot be read against the page.
- **2026-09-28 — The page brought to its constituents as they now stand.** *Chose:* the unrecordable create named by what it is — no id and none of Notification's declared refusals — with Notification's storage-failure counted as the declared, recordless refusal it now is; the payload check narrowed to an absent payload (Primitive policy 2), which is what the prose checked, since Notification accepts an empty one; Check 1.2 reading the subscription store's stored instants rather than a filter Subscription does not declare; and the one-subscriber-failing reading narrowed to the length cap, since Subscription now refuses a whitespace-only ref. *Over:* the page's claims about Notification and Subscription as they stood before 2026-09-15. *Because:* the cold regeneration of 2026-09-28 built against the constituents and met each claim false.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Notification Fanout](./notification-fanout.md) may carry it again.

### Composes

```
Deleted: Composes 4. Invariant 5.1 owns it.
```

### Composition logic › Composition state

```
Deleted: Composition state 7. Wiring decision 3 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 4. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 6. Action wiring 9 owns it.
Deleted: Action wiring 12. Action wiring 7 owns it.
```

### Composition-level invariants › Invariant 5 — The subscription records are read-only

```
  Deleted: Invariant 6. Composes 7 owns it.
  Deleted: Invariant 7. Composes 7 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 4. Execution Contract Conformance 9 owns it.
```

### Non-goals

```
Deleted: Non-goal 2. Composition state 4 owns it.
```

### Edge cases › Indeterminate outcome

```
Deleted: Indeterminate outcome 1. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 2. Execution Contract Error model 1 owns it.
Deleted: Indeterminate outcome 4. Execution Contract Error model 1 owns it.
```

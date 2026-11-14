---
title: Lease — history
nav_exclude: true
search_exclude: true
---

# Lease — history

The dated record of how [Lease](./lease.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/lease.md`.

## Decisions

Entries that record the formal-layer vote or a migration rather than a turn the pattern took.

- **2026-10-04 — The formal-layer vote is yes.** *Chose:* lease.tla with four twins and a probe — a death-freed key, a one-pause margin, a bare fence, a release with a call in flight — each rejected, and the invariant that no write of a former holder lands after the next holder has read. *Over:* the draft's "not applicable", which left the atom's claims to its composers' models. *Because:* one holder, a terminus that is an instant and a fence that carries its allowance are temporal claims, and a composition model that assumes them cannot be what verifies them.

- **2026-09-11 — Rewritten in GRACE lang v0.33; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the operations as a signature block, rationale under `WHY:`, terms declared where they are used, the invariant numbers and the Ledger unchanged. *Over:* the prose draft. *Because:* the migration plan — atoms first, since they declare the vocabulary compositions cite.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Lease](./lease.md) may carry it again.

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
Deleted: Non-goal 3. Operation 5a owns it.
Deleted: Non-goal 4. Operation 5b owns it.
```

### Composition notes

```
Deleted: Composition note 2. Capability requirement 1 owns it.
Deleted: Composition note 3. Capability requirement 2 owns it.
```

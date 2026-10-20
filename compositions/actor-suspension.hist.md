---
title: Actor Suspension — history
nav_exclude: true
---

# Actor Suspension — history

The dated record of how [Actor Suspension](./actor-suspension.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/actor-suspension.md`.

## Decisions

Entries that record a migration or an editorial rule rather than a turn the pattern took.

- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its store, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check counts. *Because:* every one of those figures had moved since it was written, so the clause asserting that nothing was weakened was itself stale — a number a tool can compute belongs to the tool, and the corpus has now lost the same wager often enough to write the prohibition down.
- **2026-09-15 — Rewritten in GRACE lang v0.41.** *Chose:* 133.6 KB of prose replaced by labelled rules across fifteen families, five invariant numbers unchanged, seven of nine Ledger lines closed by the rewrite. *Over:* a transliteration that would have carried the page's stale counts and its unclosable-member trap into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the two lines that stay open are the formal model's, which is a model change and not a language one.

## Ledger

The gate record the Ledger's `last gate:` line carried behind its latest until 2026-10-20:

- 2026-06-10 — Final Critique 4, fresh reader — clean

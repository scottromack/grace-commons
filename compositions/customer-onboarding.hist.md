---
title: Customer Onboarding — history
nav_exclude: true
---

# Customer Onboarding — history

The dated record of how [Customer Onboarding](./customer-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/customer-onboarding.md`.

## Decisions

Entries that record a migration or a regeneration rather than a turn the pattern took.

- **2026-09-14 — Rewritten in GRACE lang v0.41.** *Chose:* 180.5 KB of prose replaced by labelled rules across fifteen families, eight invariant numbers unchanged, thirty-eight of thirty-nine Ledger lines closed by the rewrite. *Over:* a mechanical transliteration that would have carried the page's four internal contradictions into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the repairs are named in the entries above and in the commit that lands this.
- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* a clearance forbidden to drop a trigger its record does not name (Action wiring 106), where the rule had forbidden emptying the set — which every healthy clearance does; the external path's unanswered read answered state-unavailable (Action wiring 154), as the trigger and the gate already answer it; and position defined by what the rules use it for — whether a constituent write had committed — rather than by which record failed, which eleven rules contradicted, Action wiring 17 and 62 among them. *Over:* the 2026-09-14 rewrite's readings. *Because:* the prose said *never clear the set*, meaning never sweep it wholesale, and the rewrite made it a prohibition the page's own walkthrough breaks; and a read with no answer had no landing at initiation.

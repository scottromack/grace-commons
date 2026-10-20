---
title: Attributed Permissions Admin — history
nav_exclude: true
---

# Attributed Permissions Admin — history

The dated record of how [Attributed Permissions Admin](./attributed-permissions-admin.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/attributed-permissions-admin.md`.

## Decisions

Entries that record a migration, an editorial rule or a family placement rather than a turn the pattern took.

- **2026-09-15 — The report-only leg is `Housekeeping`, not `Reconciliation`.** *Chose:* classify the Failed-Grant Reconciliation leg under `Housekeeping`, and state its no-write, no-repair, no-closure-window rules as that family's. *Over:* `Reconciliation`, which the leg's inherited name suggests and which three sibling compositions carry. *Because:* the grammar promoted both families at v0.42 and declared the boundary as one question — *does anything await the leg's output?* Nothing awaits this one: it reports, writes nothing, and promises no window in which an orphan closes, because nothing here **can** close one. An orphan's only resolution is a fresh administrative act by a caller. A leg that could close an orphan would be a second writer over one attestation, which breaks Invariant 7's injectivity with no arm to catch it — so the family that fits is the unawaited pole, and the name the leg has carried since it was prose is not the classification.
- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its instance, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check enumerations. *Because:* every one of those figures had moved since it was written, so the clause asserting nothing was weakened was itself stale — a number a tool can compute belongs to the tool.
- **2026-09-15 — Rewritten in GRACE lang v0.42.** *Chose:* 118 KB of prose replaced by labelled rules across fifteen families, nine invariant numbers unchanged, one of two Ledger lines closed by the rewrite. *Over:* a transliteration carrying the page's unguarded tamper reading and its stale constituent counts into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the line that stays open is the formal model's, which is a model change and not a language one.

## Migration notes

- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what an invocation stamps from it. The rule stood as Clock semantics 8 over a clock reading, a term the spec never declared, and was reworded over now, which the same commit declared beside the seam.

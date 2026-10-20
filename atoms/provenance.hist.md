---
title: Provenance — history
nav_exclude: true
---

# Provenance — history

The dated record of how [Provenance](./provenance.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/provenance.md`.

## Decisions

Entries that record a round or a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.39; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the six actions as a signature block, Invariant 1 through 8 keeping their numbers and their sub-rule numbering, every success effect conditioned on a declared admitted originate / admitted transfer / admitted transform / admitted disclose / admitted archive so no effect binds a refused call (Hard invariant 16), rejection precedence carried by `Operation 11`, `Operation 16` and `Operation 27` rather than by a WHY note, the seven acceptance areas raised to `Check 1.1 through 7.4`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and five edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`, `Correction`), the Composition notes prose raised to `Composition note 1 through 8` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into provenance` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk.

- **2026-09-12 — Id uniqueness and the archived read are stated once.** *Chose:* the former Invariant 9 (no id reuse) is carried by `Identity 15` and `Identity 16` in the Identity model, and the former archived-chain-admits-a-read invariant by `Operation 53` on the action surface; the durability invariant took the freed number 9 — a renumbering Hard invariant 26 and Hard invariant 27 forbid, which left Chain of Custody's citation of Provenance's ten invariants pointing past the end; council read 95 returned durability to Invariant 10 and tombstoned Invariant 9. *Over:* keeping both copies for emphasis. *Because:* Authority 3 — two rules must not claim authority for one proposition, and the identity model is where identity rules sit. Both duplicates were found by the checker, not by a reader.

- **2026-09-12 — The transferred entry carries the custodian pair in place of a single custodian reference, not beside it.** *Chose:* `State 4` bounded to a non-transferred entry, `State 5` stating the exclusion, `Invariant 7.1` and `Check 1.1` bounded to match. *Over:* the rewrite's `EVERY entry MUST carry a custodian_ref`, which was mine and wrong. *Because:* the prose State section said the single field "is replaced by" the pair, and the preserved [Custodian Reference] term entry says so too — a rewritten rule contradicted a term entry the migration carried across byte-identical. Found by GLM on a first council read of this atom; the witness was the untouched half of the document, which is the argument for preserving term entries verbatim through a migration.

## Migration notes

- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics and Operation.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 5 and Operation 57; only the heading changed.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

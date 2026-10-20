---
title: Selective Disclosure — history
nav_exclude: true
---

# Selective Disclosure — history

The dated record of how [Selective Disclosure](./selective-disclosure.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/selective-disclosure.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the two actions as a signature block, Invariant 1 through 6 keeping their numbers, every success effect conditioned on a declared admitted record or admitted read so no effect binds a refused call (Hard invariant 16), the disclosure instant resolution routed through a declared resolved disclosure instant so no rule restates the default, the rejection precedence carried by `Operation 8` and `Operation 15` rather than by a prose *rejection priority* line repeated in three sections, the six acceptance areas opened into `Check 2.1 through 6.2` with the three named audit gaps raised to `External check 1 through 3`, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 22` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Correction`), the Composition notes prose raised to `Composition note 1 through 9` with the named compositions moved into the WHY. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into selective-disclosure` found nothing in the corpus citing this atom by label, so the rewrite carried no frozen-number risk. 73.9 KB → 49.9 KB.

- **2026-09-12 — A filter's match semantics is a rule, not an assumption.** *Chose:* `Operation 27` (an admitted read answers every matching record) and `Operation 28` (an admitted read answers no record failing a filter). *Over:* the prose, which spelled out matching for the authority type axis alone and left the other four to be inferred from the word *matching* in the action description. *Because:* the migration's Check 5.1 tests that a subject reference query answers every record carrying the reference, and no rule in the spec owned that proposition — a check resting on an unowned invariant, the class the docket has been collecting since council read 12. The gap was invisible to both tools and surfaced only when each check was made to name the rule it tests, which is the discipline earning its keep rather than a finding against the atom.

- **2026-09-12 — Reference-level filtering is a non-goal, not an operation.** *Chose:* `Non-goal 22`. *Over:* an `Operation` rule saying [Read] must not offer the axis. *Because:* `Term filter axes` enumerates five axes and `Operation 22` rejects anything outside them, so the operation-level rule was entailed twice over (Authority 3); what is not entailed is the design claim — reference search is a composing-layer concept — and that belongs with the other surface refusals.

- **2026-09-12 — Six defects the tools passed, found by a self-read before a council read.** *Chose:* `Invariant 1.1` rewritten from a garbled sentence that barely parsed; `Concurrency 2` restored to the prose's claim — two concurrent calls are *independent*, which is what the spec said, not *non-blocking*, which is what I had written; `Correction 4` given a declared correction narrative, because naming the corrected record is unsatisfiable unless a field holds the naming and the prose named two; `Identity 15` changed from the deployment *allocating* an id (contradicting `Identity 2`, where the host allocates) to the deployment choosing the id *format*; `Operation 20`'s lower-case `where` replaced by an admitted `IF … THEN`; the former first conformance check moved to `External check 4`. *Over:* shipping a file both checkers called clean. *Because:* zero tool findings has never once predicted zero council findings, and three of the six were changes in meaning rather than infelicities. The last is the repeatable one: a check asking an auditor to find *every issued* disclosure id cannot be cleared from the store, because the store is exactly what would be missing one — the same split council read 22 forced on Capability, applied here before a reader had to force it.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

---
title: State Machine — history
nav_exclude: true
---

# State Machine — history

The dated record of how [State Machine](./state-machine.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/state-machine.md`.

## Decisions

Entries that record a migration or a repair rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.40; nothing but language changed.** *Chose:* the five actions as a signature block, Invariant 1 through 10 keeping their numbers, the declaration's ten well-formedness checks raised to a `Declaration 1 through 17` family of their own, every success effect conditioned on a declared admitted instantiate, admitted fire or admitted history (Hard invariant 16), [Fire]'s seven-step rejection precedence kept beside the rules as an eight-row case space with the ordering carried by `ONLY IF` guards rather than by a prose *rejection priority* line repeated in two sections, the six acceptance areas opened into `Check 1.1 through 8.2` with three `External check`s for what the store cannot answer, the Non-goals-and-edge-cases prose split into a `Non-goal 1 through 21` family and four edge-case families (`String`, `Clock semantics`, `Concurrency`, `Atomic writes`), the Composition notes prose raised to `Composition note 1 through 10`. *Over:* the prose spec. *Because:* the migration plan; `cites.py --into state-machine` found nothing in the corpus citing this atom by label. 78.8 KB → 67.0 KB.

- **2026-09-12 — The within-workflow temporal bound is a precedence, not a `≥`.** *Chose:* `Operation 20` — *IF the resolved firing instant precedes the workflow's instantiation instant THEN [Fire] MUST answer invalid-request*. *Over:* `IF fired_at EXCEEDS instantiated_at OR fired_at = instantiated_at`, the two-arm spelling the condition operator set forces on a `≥`. *Because:* that spelling is a watched class at five sites across two specs (council read 29), and this atom would have been the third. A bound that admits its own boundary is a *precedes* prohibition in one arm — the boundary case (a transition firing at the instant of instantiation) is legal, and one arm says so. The class may still earn an operator; it does not need this atom's vote.

- **2026-09-12 — Four propositions had two owners each.** *Chose:* `Invariant 2` owns exactly-one-current-state and the `State` family no longer restates it; `Operation 21` owns *one entry per admitted fire* and `Invariant 5` no longer does; `State 4` owns the history entry's field set and `Invariant 9` no longer does; `Invariant 8.2` owns *the atom does not evaluate a guard* and the `Non-goal` family no longer does. *Over:* keeping each pair for emphasis. *Because:* Authority 3. All four were found by `W-duplicate-proposition`, which is the check earning its keep on the largest atom migrated so far — 192 rules, where a reader cannot hold the whole surface at once and a duplicate is invisible by construction.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).

---
title: External Onboarding — history
nav_exclude: true
---

# External Onboarding — history

The dated record of how [External Onboarding](./external-onboarding.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/external-onboarding.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; twenty-one of twenty-four open Ledger lines closed by the rules that now own them, and nothing else changed but what each line asked for.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and a `Resume` family for the resume arm as the surfaces; invariant numbers 1 through 5 unchanged; the seven prose checks kept as `Check 1.1` through `Check 7.4`, grouped by their old numbers, with the standing rules as a `Standing rule` family; `Non-goals` and `Edge cases` split; Standards renamed Standards references and moved to its place. The lines' own fixes, taken as the ledger prescribed them: the validation depth pinned pre-gate against each constituent's field rules (2026-08-26-f, Primitive policy 3 and 4); the decliner's identity declared unrecorded (2026-08-26-e, Action wiring 47, Non-goal 5); Invariant 2 re-scoped to the completion record's linkage (2026-08-26-i); the substrate's third invalid-request source named, Actor Identity's arm at the substrate's second step, and the read-back floored at the invocation's own attempt record (2026-08-30-c, Audit arm 8 through 12); Party Identity's invalid-query landed as the composition's own defect (2026-08-30-e, Resume 25 and 26); the candidates declared unfiltered by state, since a closed party the arc enrolled is still the arc's party (2026-08-30-k, Resume 19); every alert named onto the deployment's alerting surface (2026-08-30-l); the relation's cardinality and modality declared (2026-08-30-h); the comparisons' edges pinned by the operators (2026-08-30-f); an operational membership test for the horizon (2026-08-30-g); *rests on* in every invariant's WHY (2026-08-30-i); the examples' credential call matched to the atom's raw-material model and the concurrent example changed to the same-acceptor race (2026-08-26-k, 2026-08-30-o); acronyms glossed and the SOC 2 attribution corrected (2026-08-26-j, 2026-08-30-j, 2026-08-30-m); and the mismatch with Invitation's `Composition note 2` and `Composition note 3` noted here and corrected there (2026-08-30-n). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Three stay open: the resume arm's credential read-back (2026-08-30-d), which wants a design choice between walking predecessors and naming the head, and the two formal lines.

## Ledger

The gate record the Ledger's `last gate:` line carried behind its latest until 2026-10-20:

- 2026-08-26 — Final Critique 7, fresh reader — 6 foundational (all since closed), 10 refining, 3 rhetorical

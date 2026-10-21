---
title: Propagate Consent Revocation Downstream — history
nav_exclude: true
---

# Propagate Consent Revocation Downstream — history

The dated record of how [Propagate Consent Revocation Downstream](./propagate-consent-revocation-downstream.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/propagate-consent-revocation-downstream.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-24 — Rewritten in GRACE lang v0.61; nineteen of twenty-one open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole, its per-key serialization split into the consent exclusion and the pair exclusion because the grammar owns the noun *section* — `Primitive policy`, `Audit arm`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces; invariant numbers 1 through 8 unchanged; the record checks renumbered as Conformance checks naming the rule each tests; the edge cases split into Non-goals and three Edge cases families, the two-instance retention entries joining `Retention asymmetry` as its fourth spec. Choices the page left open, each decided by a standing rule: *governed* defined as the record the composition's grant write made — every record of the instance under the reserved write surface — and Invariant 6 split into a floor and a liveness closure (2026-08-30-d); Consent's not-known at the revoke relayed as not-known with an index-anomaly finding rather than as a recording failure (2026-08-26-g — *make all things mean one thing*: recording-failure is a write that did not land); the gate's exposure and the retention policy reference's validation stated as rules (2026-08-30-f, 2026-08-26-b); the bound measured from the seam reading (2026-08-30-h); the knob collisions stated in the terms (2026-08-30-g); the pairing-key deviation declared and no refusal outcome added (2026-08-30-e — *as simple as possible without losing fidelity*); the expiry asymmetry restated on what this composition observes, not on how Consent expires (2026-08-27-c). **One defect fixed in this pass**: the invocation retried its grant event under the pair exclusion while the reconciliation compensated grant orphans under the consent exclusion, so the two could both land a grant event for one consent; the invocation now takes the consent exclusion once the consent id exists, and a grant candidate set whose retention policy references disagree is escalated rather than chosen (Action wiring 16; Reconciliation 29). *Over:* the prose's step lists, a lettered case list, and revision-history prose. *Because:* the rules state each landing once; the two formal lines stay open because the model, not the page, is what they owe.

## Ledger

The gate records the Ledger's `last gate:` line carried behind its latest until 2026-10-21, newest first:

- 2026-08-27 — authentication-precedence gate, fresh reader — 5 foundational (3 corrected in-round, 2 routed and since closed), 9 refining/rhetorical routed (2 since closed)
- Final Critique 7's 7 refining and 3 rhetorical partly still open

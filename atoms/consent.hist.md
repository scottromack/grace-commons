---
title: Consent — history
nav_exclude: true
---

# Consent — history

The dated record of how [Consent](./consent.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/consent.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the ten invariant numbers and the seven acceptance-check numbers unchanged, the [Check] selection routed through a declared candidate record and the two comparisons through withdrawn and elapsed, the semantic/stored split kept as two rule families with the dated residual note carried over verbatim, the case space kept beside the rules as a table, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. The rejection priority [Revoke] carried as an arrow diagram is now carried by the guards — a blank consent id is refused before the store is consulted, the terminal answers are exclusive by Invariant 2.1, and the attribution and temporal checks are conditioned on the record standing in [Granted].

## Migration notes

- **2026-06-21 — Clearly-marked residual (execution/render-time refactor).** The *authoritative* expiry determination is **derived** at read time: [Check] and [Read] both compute the state from [Expiry Instant] and [Revocation Instant] against the evaluation instant, and [Check] is a pure query that never writes (Operation 36; there is no `expire` action — Expiry 5). The stored [State] field's [Expired] value is therefore a **materialized cache of the derived state, not the authority** — written for query convenience, and required by Invariant 2.2 to equal the derived state at the moment any result is returned. This stored write is the **residual** of this atom against the render-time target, which would carry no stored [Expired] write at all and derive the projection on every read, as Invitation does. It was *clearly marked in the spec* rather than removed: dropping the stored [State] field is a structural change beyond this refactor, the eager/lazy design was introduced deliberately (Final Critique 4, to resolve the semantic-versus-stored contradiction), and because the cache must equal the derived value at read time it cannot serve as a flag that lags the clock in any conforming implementation. A future re-pass may collapse the stored [State] field to a pure read-time projection; that is an open design point, not done in the refactor.
- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. The rule keeps the words it carried as Clock semantics 4; only the heading changed.
- **2026-09-15 — Clock semantics 5, 6 and 8, kept under Clock semantics.** Clock semantics 5, Clock semantics 6 and Clock semantics 8 stay under Clock semantics rather than under Clock dependence: each is one action's use of a reading Clock dependence 1 already permits, and a family rule does not enlarge because an action instantiates it (council read 75).

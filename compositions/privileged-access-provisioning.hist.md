---
title: Privileged Access Provisioning — history
nav_exclude: true
search_exclude: true
---

# Privileged Access Provisioning — history

The dated record of how [Privileged Access Provisioning](./privileged-access-provisioning.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/privileged-access-provisioning.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-09-23 — Rewritten in GRACE lang v0.61; forty-four of forty-five open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration and Logic confinement both — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with `Provisioning cascade` and `Scope vocabulary` kept as the page's own; the prose's Behavior section distributed to the rules that own each claim; invariant numbers 1 through 10 unchanged; the checks renumbered `Check 1.1` through `Check 6.5`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency`, `Expiry` and `Multi-use capabilities` under the second. The choices the lines left open, made by standing rules: the credential checked before the request is resolved, closing the unauthenticated existence oracle and declaring the authenticated residual (2026-08-28-j); the exercise ordered before its provisioning event declared lawful rather than gated, since a delivered token is lawful access (2026-08-28-h); the session check stated existentially, since the record names the principal and no session identifier (2026-08-28-m); the decision event and the credential check kept, with what each adds stated — the request-keyed record and the second registry (2026-08-28-n); the one-credential-two-registries assumption declared (2026-08-28-a); the blank-reason denial's entry closed by a recovery record carrying the reason, or by the horizon (2026-08-28-c); a chain found under a request already Withdrawn closed and reported, not recorded (2026-08-27-p); the substrate's refusals over a possibly committed decision routed to an evaluation entry (2026-08-26-b); a read_chain refusal inside the evaluation answered with the decision and an evaluation entry (2026-08-26-a); the token's deadline restated as Capability's reading plus the remaining ttl, since allocate takes a duration (2026-08-27-j). The rest took their prescribed fixes — the terminal-event walk from the tail, read_record's real arms, the chain shape validated at intake, the token resolved by Capability's read on the token with redeem not called on a miss, the credential second in every signature, the third Permissions call site, the cascading-revocation qualifier carried, Provisioned advancing to Revoked, the provisioning event carrying the redemption count and the expiry instant, the chain-less skip, the counts, the examples' quorum vocabulary, material and Assignment attribution. *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. The model line stays open (2026-08-29-a).

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Privileged Access Provisioning](./privileged-access-provisioning.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 15. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Composition state 33. Execution Contract Database 2 owns it.
Deleted: Composition state 34. Execution Contract Database 2 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 11. Execution Contract Database 1 owns it.
Deleted: Capability requirement 12. Execution Contract Database 3 owns it.
Deleted: Capability requirement 20. Execution Contract Database 2 owns it.
Deleted: Capability requirement 21. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion to release.
Deleted: Capability requirement 22. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion to release.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 4. Execution Contract Database 3 and Execution Contract Database 4 own it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Deleted: Action wiring 30. Execution Contract Database 1 owns it.
Deleted: Action wiring 42. Execution Contract Database 2 owns it.
Deleted: Action wiring 83. Execution Contract Database 1 owns it.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 3. Execution Contract Database 2 owns it.
Deleted: Reconciliation 7. Composition state 31 owns it: every pending entry carries an invocation id, so no entry is paired by its payload fields.
Deleted: Reconciliation 8. Composition state 31 owns it.
Deleted: Reconciliation 9. Execution Contract Database 1 owns it.
Deleted: Reconciliation 17. Execution Contract Database 1 owns it.
Deleted: Reconciliation 18. Execution Contract Database 1 owns it.
Deleted: Reconciliation 19. Execution Contract Database 1 owns it.
Deleted: Reconciliation 20. Execution Contract Database 1 owns it.
Deleted: Reconciliation 25. Execution Contract Database 1 owns it.
Deleted: Reconciliation 26. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 28. Execution Contract Database 1 owns it.
Deleted: Reconciliation 31. Execution Contract Database 1 owns it.
Deleted: Reconciliation 34. Execution Contract Database 1 owns it.
```

### Composition logic › Provisioning cascade

```
Deleted: Provisioning cascade 1. Execution Contract Database 2 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion for [Read Request] to take.
Deleted: Concurrency 3. Execution Contract Database 2 owns it: an action's reads of a request and the writes they decide are one transaction, and the composition names no exclusion for an exercise's record write to run outside.
```

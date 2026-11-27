---
title: Session — history
nav_exclude: true
search_exclude: true
---

# Session — history

The dated record of how [Session](./session.md) got here, moved out of the spec on 2026-10-19 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- atoms/session.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-06-21 — Expiry is derived at read time, never stored.** *Chose:* the stored state space is `{Active, Revoked}`; `Expired` is the projection `status = Active ∧ now ≥ expires_at` computed from the immutable expiry instant and the injected clock (Invariant 12). *Over:* a stored `Expired` terminal written by a lazy or scheduled transition. *Because:* a stored flag lags the clock it idealizes, and a session's lapse has no side effect that would need a write to carry it.

- **2026-09-12 — Rewritten in GRACE lang v0.35; nothing but language changed.** *Chose:* labelled rules in fenced blocks, the four actions as a signature block, the twelve invariant numbers and the six acceptance checks unchanged, the derived lapse routed through a declared lapsed and effective status so no rule carries the comparison, the arithmetic in `issued_at + session_duration` moved into a declared expiry deadline (Hard invariant 24), [Validate]'s four-row precedence table kept beside the rules as the case space, Generation acceptance moved ahead of Non-goals to match the migrated corpus, the string-input paragraph raised to a `String 1 through 8` family matching Permissions and Notification, Non-goals and Edge cases split into two sections. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this atom by label, so the rewrite is free of frozen-number risk. Expiry earned its own family — eight rules that say a lapse writes nothing, fires nothing, stamps nothing and is scheduled by nobody — because the whole commitment was carried by prose emphasis in four places and is now a surface a checker can read.

- **2026-10-19 — The store's guarantees cited, not restated.** *Chose:* the session store supplied under Execution Contract Store 1 through 4 (Capability requirement 10), and the six rules that restated them tombstoned to their owner — Operation 32, [Revoke]'s status move and its three revocation fields committed in one operation, and Invariant 9.3, no partial session left by a storage-failure, to Store 1; Operation 35, a write the store refused leaving the store as the call found it, to Store 3; Concurrency 1 through 3, status moves on one session token serialized, two concurrent revokes answering revoked once and the later one already-terminal, to Store 2; rules 178 to 173. *Over:* the atom restating, for its own store, what every deployment's store guarantees. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and `execution-contract.md` writes it once as the Store contract. A session's window stays auditable from its one record, as the Intent has it: the expiry instant is stamped once and no action changes it (Invariant 2.1), and the atom's own no-removal rules stay (State 11, Invariant 9.1 and 9.2). Check 1.2 rests on the auditor's own reads of a session across its life, as Credential's re-read checks do, and Check 3.1 reconstructs a past instant from the instants each record carries, so the atom cites neither History 1 nor Order 1. What the atom does for its domain is unchanged.

- **2026-10-21 — A liveness query reads the present; the effective status reads the stored status; the length cap refuses only the writes; the default window is positive.** *Chose:* the auditor's reconstruction of a past instant taken out of Term liveness query, so Operation 40 and 41 bind the queries [Read] and the administrative surfaces answer at the read-time clock, and a past instant is reconstructed from the three instants each record carries (Check 3.1), the Disputed access investigator with it; Invariant 12.4 and Check 2.4 resting the effective status on the stored status, expiry instant and now, as Term effective status and Term lapsed already did; String 7 naming [Issue], and String 9 and String 10 refusing an over-long revoked by reference or reason only on a session stored active, Operation 25 and 26's form, so [Validate] and [Read], which refuse nothing, meet no length refusal and an over-long token names no session; the default session duration held above the zero duration (Capability requirement 11), the floor of Operation 8 held to a supplied duration, and Operation 6 applying the default only where one is configured. *Over:* an auditor's reconstruction bound to a projection of the present; an invariant the page's own Term breaks on every revoked session past its deadline; a refusal obliged on two actions whose signatures carry none; a configured default of zero or less, which one build refuses and another issues as a window already closed. *Because:* Final Critique 6 found each a divergence between conforming builds, or a stated check a conforming deployment fails, and the corpus already held the length cap's cure: Credential's thirteenth round names the action each length refusal binds. What the atom answers a well-formed call on a conforming deployment is unchanged.

- **2026-10-22 — The length refusal's split stays the page's own.** *Chose:* String 7, String 9 and String 10 kept as written, the category reach's flag removed: GRACE-lang Closed vocabulary 29 now reads a rule over several actions as binding each only where its signature carries the outcome, so [Validate] and [Read] would meet no length refusal under one rule over every action, but the split also refuses on [Revoke] only an over-long revoked by reference or reason, and only on a session stored active, as Operation 25 and Operation 26 refuse a blank one, where [Revoke]'s refuses line lists invalid-request first; one rule over every action would refuse an over-long token or an over-long reason on a revoked session with invalid-request ahead of not-known and already-terminal. *Over:* String 7 written again as one rule over every action, the page's form before its sixth Final Critique. *Because:* the maintainer ruled on 2026-10-22 that five repeated cures are each stated once, the category reach among them, and that a page keeps its own rule where its domain differs. What each action does and answers is unchanged.

- **2026-11-02 — The maximum length has a default.** *Chose:* the maximum length stated as 1,024 Unicode code points where a deployment declares none, the unit written as Unicode code points as Permissions, Credential and Provenance count theirs, and String 6 turned from *set* to *declare*; String 7, String 9 and String 10 stand, citing Execution Contract Input 2. *Over:* a bound the deployment must supply, or silence. *Because:* the maintainer ruled on 2026-11-01 that what the host must bound takes one posture, a corpus default a deployment may override; the string inputs run from principal and issuer references to a revocation reason, and 1,024 code points, the corpus's default for text (Personal Todo's description cap), holds a sentence or two.

- **2026-11-21 — The session is keyed by the digest of the session token, never the token.** *Chose:* a session identified by the session token digest, the digest the host computes of a session token at the seam (Term session token digest, Capability requirement 12; Execution Contract Logic confinement 8 and 21, cited, not restated): [Issue] records and answers the digest (Operation 3, Operation 58), [Validate] and [Revoke] are given the digest, never the live token (the signatures, Operation 14, Operation 22, the case rows), the session token stays the bearer credential and its digest is what [Validate] accepts and [Revoke] takes as the whole authorization (Identity 2, Operation 36), and the live token reaches its holder by the host alone, outside every record, event and log of the atom (Capability requirement 13); the keys and the uniqueness rules read the digest (Identity 1, 5, 6 and 7, State 2, Invariant 1.1, 3.1, 7.1 and 7.2), [Read] still answers no key (Operation 52, now of the digest), and a deployment propagating a logout holds digests (Non-goal 15, Non-goal 18). Retired: Capability requirement 6 and Non-goal 17, both to Logic confinement 21, since the database never holds the token raw. Added: Capability requirement 12 and 13, and the Term session token digest beside the Term session token, whose entry turns from a field of the session to a value (Kind Type). Rules 169 to 169. Both models re-derived over the digest key, every twin still caught. *Over:* the session keyed by the live token, the record identity and the bearer credential in one value. *Because:* Scott's session ruled on 2026-11-21 02:09Z (rounds/escalations.md, "Logic confinement 21 reaches the session token") that Execution Contract Logic confinement 21 reaches the session token: it is the bearer credential a cookie holds, so a record, an event or a log carrying it hands out live sessions; found by Linus in Login Final Critique 21 and 22. The page leaves `done` and takes a delta round; each composition that names Session takes its own.

- **2026-11-25 — The atom reorganised into the tree order and bonded: a session carries its actor id and a session id that grants nothing, and no pattern is named.** *Chose:* the tree order Task, List and Ordering stand in, every label kept and none renumbered; the principal reference is the actor id, met by the need `key actor id; pairs sessions`; the host mints a session id at the seam when [Issue] opens a session (Identity 13 and 14, State 15, Operation 62, Invariant 7.3, Capability requirement 14, Check 7.1), [Read] carries it (Operation 63), and the offer `key session id; carried by sessions` lets other atoms pair on it; Identity 7 now reads that no identifier beside the session token digest authorizes an action, so the session id grants nothing and [Validate] and [Revoke] still take the digest; [Issue]'s and [Validate]'s signatures are unchanged, since Login cites both; Non-goal 2, 4, 6, 21, 22 and 24 tombstoned to the rule that owns the declined job, Non-goal 26, Composition note 4, two Terms, two entries, the WHY, the owners NOTE and the login example name no pattern; `session id` declared in declarations.md. *Over:* no session id at all (Scott's 3:17 PM ruling for option (a), superseded at 3:22 PM), and a session id on [Issue]'s or [Validate]'s answer, which would change signatures a composition cites. *Because:* Scott's ruling of 2026-11-25 3:22 PM Central ("Yes", option (b), "what a good DB would do"), the unit `atom: Session, bonded`.

## Migration notes

- **2026-09-15 — Capability requirement 1, moved from Operation.** What the deployment supplies, which is what the family means. The rule stood under `Operation` — one action's rules — while naming no action, because this spec was migrated before the standard family had a home in an atom; the five atoms migrated a day later put the same obligation here. The words are the words the rule carried (council read 76).
- **2026-09-15 — Clock dependence 1 and 2, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what a transition stamps from it. Both rules keep the words they carried as Clock semantics 4 and 5; only the heading changed.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Session](./session.md) may carry it again.

### Structure › Identity model

```
Deleted: Identity 4. Execution Contract Logic confinement 3 owns it.
Deleted: Identity 8. Invariant 7.1 owns it.
Deleted: Identity 10. Identity 9 and Capability requirement 4 own it.
```

### Structure › State

```
Deleted: State 3. Invariant 10.1 owns it.
Deleted: State 8. Invariant 12.1 owns it.
Deleted: State 9. Invariant 12.2 owns it.
```

### Structure › State › Expiry

```
Deleted: Expiry 1. Invariant 12.3 owns it.
Deleted: Expiry 3. Invariant 12.2 and Invariant 12.3 own it.
Deleted: Expiry 6. Invariant 12.3 owns it.
Deleted: Expiry 7. Operation 38 and Term effective status own it.
Deleted: Expiry 8. Operation 16 owns it.
```

### Structure › Capability requirement

```
Deleted: Capability requirement 11. Operation 56 owns it.
Deleted: Capability requirement 7. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 8. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 9. Execution Contract Logic confinement 7 owns it.
Deleted: Capability requirement 6. Execution Contract Logic confinement 21 owns it: the record carries the session token digest, never the session token.
Deleted: Configuration 1. Capability requirement 2 owns it.
Deleted: Configuration 2. Operation 48 owns it.
Deleted: Configuration 3. Capability requirement 3 owns it.
Deleted: Configuration 4. Execution Contract Logic confinement 3 owns it.
Deleted: Configuration 5. Capability requirement 4 owns it.
Deleted: Configuration 6. Capability requirement 5 owns it.
Deleted: Configuration 7. Execution Contract Logic confinement 21 owns it.
Deleted: Clock semantics 1. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 2. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 7 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 5. Clock dependence 2 owns it.
Deleted: Clock semantics 6. Non-goal 25 owns it.
Deleted: Clock semantics 7. Non-goal 26 owns it.
```

### Structure › Operations

```
Deleted: Operation 7. Operation 8 and Operation 56 own it.
Deleted: Operation 13. Invariant 6.1 owns it.
Deleted: Operation 21. Invariant 6.1 owns it.
Deleted: Operation 32. Execution Contract Database 1 owns it.
Deleted: Operation 35. Execution Contract Database 3 owns it.
Deleted: Operation 42. Capability requirement 1 owns it.
Deleted: Operation 43. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 44. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 46. Non-goal 7 owns it.
Deleted: Operation 49. Execution Contract Logic confinement 3 owns it.
Deleted: Operation 54. Execution Contract Input 1 owns it.
```

### Structure › Invariants › Invariant 2 — Expiry instant immutability

```
  Deleted: Invariant 2.2. Non-goal 7 and Non-goal 8 own it.
```

### Structure › Invariants › Invariant 3 — Validity bound conjunctive, by derivation

```
  Deleted: Invariant 3.2. Expiry 5 owns it.
```

### Structure › Invariants › Invariant 5 — Stored terminal absorbing

```
  Deleted: Invariant 5.2. Operation 23 owns it.
  Deleted: Invariant 5.3. Operation 27 owns it.
```

### Structure › Invariants › Invariant 9 — Session durability over this atom's own surface

```
  Deleted: Invariant 9.3. Execution Contract Database 1 owns it.
```

### Structure › Invariants › Invariant 10 — Every session has a finite lifetime

```
  Deleted: Invariant 10.2. Invariant 10.1 owns it.
```

### Structure › Invariants › Invariant 11 — Expiry absorbing, by derivation

```
  Deleted: Invariant 11.2. Invariant 11.1 and Invariant 4.1 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 5.1. External check 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 17. Execution Contract Logic confinement 21 owns it: the database holds the session token digest, never the session token.
Deleted: Non-goal 23. Non-goal 24 and Composition note 3 own it.
```

### Edge cases › Clock dependence

```
Deleted: Clock dependence 1. Execution Contract Logic confinement 3 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
```

### Edge cases › String policy

```
Deleted: String 8. Execution Contract Logic confinement 13 owns it.
```

### Composition notes

```
Deleted: Composition note 10. Execution Contract Atom interface 1 owns it.
Deleted: Composition note 11. Non-goal 27 owns it.
```

### While something is so › String policy

```
Deleted: String 5. GRACE-lang Term blank owns it: a value carrying only white space is blank.
```

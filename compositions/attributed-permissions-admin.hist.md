---
title: Attributed Permissions Admin — history
nav_exclude: true
search_exclude: true
---

# Attributed Permissions Admin — history

The dated record of how [Attributed Permissions Admin](./attributed-permissions-admin.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/attributed-permissions-admin.md`.

## Decisions

Entries that record a migration, an editorial rule or a family placement rather than a turn the pattern took.

- **2026-08-30 — The reconciliation leg reports and never writes, bounded at both edges; the pairing-write atomicity is a declared capability, not an implementation note.** *Chose:* one writer per act — the invocation lands every grant, revocation and pairing, a retry is always a fresh administrative act under a fresh nonce and a fresh attestation, and the leg only surfaces orphans; the completion bounds as the leg's and the orphan check's lower edge and the pair-scoped retention purge as their horizon, with an unpaired attestation past the horizon reported rather than repaired; the pairing-write atomicity and the constituent-store durability declared as instance capability requirements with externally-clearable checks, the former the antecedent Invariants 1 and 2 carry; the orphan rejection carrying its position so a caller knows whether a grant exists before retrying; the orphan log entry carrying the grant's handle so the join is by key. *Over:* a leg that attempts the corresponding grant on retry beside a stalled invocation that could wake and pair the same attestation to a second grant; a leg with no lower edge and a check with no horizon; a horizon arm that read every unpaired attestation past the horizon as benign when the pair-scoped purge can never have purged an orphan's pair. *Because:* two writers over one attestation break Invariant 7's injectivity with no arm to catch it, a leg with no lower edge reads an invocation mid-flight as an orphan, and an antecedent an invariant rests on must be declared where the deployment can see and clear it (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, *An outcome is sized before the intent*, *Capability provenance*; with the section titled *A reconciliation is bounded at both ends* in `pressure-testing.md`).

- **2026-09-10 — The pair gets its own action; the multiplicity stays.** *Chose:* [Revoke Permission] over the subject-and-scope pair, revoking every active grant, each under its own attestation. *Over:* an issuance precondition refusing a second grant on a pair. *Because:* several active grants on one pair are lawful and often intentional — the constituent permits them by construction, and two grantors independently authorizing the same access is exactly the case an attributed-permissions composition exists to record. A precondition would have deleted that case to fix a surface problem and would have done nothing for the grants already standing. The defect was never the multiplicity; it was that the write surface is keyed by a grant's handle while the evaluation surface is keyed by the pair, with nothing reconciling them. **One attestation per grant rather than one shared across the set** is forced rather than chosen: Invariant 7 requires the revocation map to be injective and a check tests it, so a shared attestation would have broken a checked invariant to save an attest call. The auditor's grouping key is the shared request instant instead.

- **2026-09-10 — The concurrent-issue race is declared, not foreclosed.** *Chose:* a grant committed between the enumeration and the last revocation survives the sweep; the caller's terminal condition is the evaluation answering denied; Invariant 9 is stated over the **enumerated set** rather than over the pair. *Over:* requiring per-pair serialization as a further instance capability. *Because:* this composition declares the capabilities it actually needs and no others, and a critical section held across an administrative sweep is a real cost on every deployment to close a race a re-check closes for free. The deployment that needs the stronger form is told exactly what to supply and what it buys. **What this costs is stated where it lands** — Invariant 9 promises less than a reader would assume from its name, and says so in its own text.

- **2026-09-15 — The report-only leg is `Housekeeping`, not `Reconciliation`.** *Chose:* classify the Failed-Grant Reconciliation leg under `Housekeeping`, and state its no-write, no-repair, no-closure-window rules as that family's. *Over:* `Reconciliation`, which the leg's inherited name suggests and which three sibling compositions carry. *Because:* the grammar promoted both families at v0.42 and declared the boundary as one question — *does anything await the leg's output?* Nothing awaits this one: it reports, writes nothing, and promises no window in which an orphan closes, because nothing here **can** close one. An orphan's only resolution is a fresh administrative act by a caller. A leg that could close an orphan would be a second writer over one attestation, which breaks Invariant 7's injectivity with no arm to catch it — so the family that fits is the unawaited pole, and the name the leg has carried since it was prose is not the classification.

- **2026-09-15 — Constituent guarantees are quantified, never counted.** *Chose:* `EVERY` constituent invariant holds over its instance, each constituent's own acceptance bar cleared over its own store, and a rule forbidding this spec to count them. *Over:* the prose's per-constituent invariant and check enumerations. *Because:* every one of those figures had moved since it was written, so the clause asserting nothing was weakened was itself stale — a number a tool can compute belongs to the tool.

- **2026-09-15 — Rewritten in GRACE lang v0.42.** *Chose:* 118 KB of prose replaced by labelled rules across fifteen families, nine invariant numbers unchanged, one of two Ledger lines closed by the rewrite. *Over:* a transliteration carrying the page's unguarded tamper reading and its stale constituent counts into the rule surface. *Because:* a defect the rewrite finds is repaired in the pass that finds it; the line that stays open is the formal model's, which is a model change and not a language one.

- **2026-09-15 — A lawful destruction is answered before absence.** *Chose:* [Verify Grant Attribution] reads the retention layer's purge record when an attestation is absent, answers `not-applicable(purged)` where the purge record names it, and reaches the tamper reading only where nothing lawful explains the absence; the retention scope is a declared capability and the purge record a served surface. *Over:* leaving the tamper reading to rest on the pair-scoped purge requirement stated three sections away. *Because:* the strong reading is sound only under a pair-scoped retention scope — where nothing lawful can destroy an attestation while its grant stands. A deployment that composes a per-store retention instead reaches the state the requirement was meant to exclude, and the query then hands an auditor a **forensic finding for a correctly-executed retention policy**, which is the one class of false finding an attribution composition can least afford. Closes the Ledger's `2026-08-30-a`.

- **2026-10-20 — The store's guarantees cited, not restated, the pairing write atomicity among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 34), and the forty-eight rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which an administrative act's attestations, constituent writes and pairing entries commit together: the pairing write atomicity the deployment supplied, its one transaction over a constituent write and the write's pairing entry, and the antecedent Invariants 1 and 2 carried on it (Capability requirement 21 through 25, Action wiring 11, 31, Atomic writes 3, Invariant 1.3, 2.3, External check 3), the bar on enclosing an attestation and a constituent write in one transaction (Wiring decision 3), the orphan a constituent's storage failure or a refused commit left behind a landed attestation, and the caller's retry of it on the revoke side (Action wiring 9, 13, 25, 32, 34), the unpaired grant a failed pairing left, with its post-grant and post-revoke landings, the bar on retrying either, its join by the grant's handle and its disposal (Action wiring 14, 33, 35, 36, Composition state 20 through 22, Atomic writes 9 through 11), the completion bounds and the edges and checks that aged an invocation in flight (Capability requirement 16 through 19, Housekeeping 11, 12, Check 1.3, 5.4, 5.5), and the bar on claiming an atomicity across the enumerated set (Action wiring 53); to Store 1 and Store 2, the partially-revoked answer, the call again it alone admitted and the bound on what it asserts (Action wiring 49, 50, Invariant 9.4); to Store 2, a second revocation's not-active, the enclosing transaction's serialization, the sweep's skip of a grant a racing revocation took, and the optional critical section keyed by the pair with the race it closed (Concurrency 4, 5, 9, Action wiring 47, Capability requirement 31); and to Store 3, the answer only after the committed entry and the constituent stores' durability (Action wiring 12, Capability requirement 26, External check 4); with them [Revoke Grant]'s signature loses orphan-attestation and [Revoke Permission]'s loses partially-revoked, no kept rule answering either; rules 348 to 301. *Over:* the attestation committed in a transaction of its own, and a declared capability enclosing only the constituent write and its pairing entry; positioned orphans for a storage failure, a refused commit and a host that did not honour the capability; completion bounds below which the report-only leg examined nothing; and a pair-scoped revocation that claimed no atomicity across its set — the declared atomicity and the leg's lower edge are the turn of 2026-08-30, and the declared race the turn of 2026-09-10, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, while a refused attempt a page keeps as evidence stays a domain choice: an attestation, the grant or revocation it authorizes and the pairing entry are store writes of one act, so a storage failure anywhere in it commits nothing, and Store 2 reads a pair-scoped revocation's enumeration inside the transaction that revokes, so no racing revocation or issuance lands inside the sweep. The attestation a constituent's refusal leaves (invalid-request at the grant, not-known or not-active at the revoke) stays as evidence of an attempted act, written with its orphan log entry in the refusal's transaction (Wiring decision 4, 5), and with it the orphan log, the report-only leg and its horizon arm; a grant committed after the enumeration stays outside the invocation, told from the records by the revocation attestations' shared request instant (Identity 9, 10) rather than by a commit order, so Order 1 is not cited. What the composition does for its domain is otherwise unchanged.

- **2026-10-21 — The attribution answer reads as provable.** *Chose:* *provable* (`glossary.md`: shown by the records alone, never by a system's say-so) where the page wrote *without a narration*, *from the records alone* or their like: Invariant 3.4, under which the composition answers a grant's attribution provably, and, by wording alone, the Summary, the regulator-audit example, the acceptance bar and the attributable-action standard; every *grant* on the page already named a live authorization a revocation ends, so none changed; rules 301 to 301. *Over:* the phrase restated at each site. *Because:* the maintainer ruled 2026-10-21 that *shred*, *grant* and *provable* are declared domain terms, each defined once, in `glossary.md`, and that the specifications say them where their meaning stood; the wording of Invariant 3.4 changed and no obligation did.

- **2026-11-04 — An attempt a constituent turns away is answered, not refused, so the orphan stands.** *Chose:* [Issue Grant] answering orphan-attestation(pre-grant) and [Revoke Grant] answering not-known and not-active as outcomes, each committing the landed attestation and the orphan log entry (Action wiring 101, Action wiring 102), the signatures carrying them on the answers line. *Over:* keeping them in the refuses lines against Execution Contract Read 4, which holds a refused call to write nothing. *Because:* Scott's ruling of 2026-10-31 16:48Z (rounds/escalations.md): the outcomes past the boundary predicate are answered as outcomes, so the call's own record is an admitted call's write and Read 4 holds as written; the same ruling cured Authenticated Actor's attest log. Closes the Ledger's `2026-10-27-a`.

## Migration notes

- **2026-09-15 — Clock dependence 1, cut out of Clock semantics.** Whether a guard's decision may depend on the clock reading, and under what condition — one question, stated in its own family rather than among the rules about what the clock is and what an invocation stamps from it. The rule stood as Clock semantics 8 over a clock reading, a term the spec never declared, and was reworded over now, which the same commit declared beside the seam.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Attributed Permissions Admin](./attributed-permissions-admin.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 20. Execution Contract Database 1 owns it.
Deleted: Composition state 21. Execution Contract Database 1 owns it.
Deleted: Composition state 22. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no unpaired grant for a stamp to join to an orphan log entry.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 5. Execution Contract Logic confinement 3 owns it.
Deleted: Capability requirement 16. Execution Contract Database 1 owns it.
Deleted: Capability requirement 17. Execution Contract Database 1 owns it.
Deleted: Capability requirement 18. Execution Contract Database 1 owns it.
Deleted: Capability requirement 19. Execution Contract Database 1 owns it.
Deleted: Capability requirement 21. Execution Contract Database 1 owns it.
Deleted: Capability requirement 22. Execution Contract Database 1 owns it.
Deleted: Capability requirement 23. Execution Contract Database 1 owns it.
Deleted: Capability requirement 24. Execution Contract Database 1 owns it.
Deleted: Capability requirement 25. Execution Contract Database 1 owns it: an administrative act's attestations, constituent writes and pairing entries commit together, and the composition names no pairing write atomicity for an instance to lack.
Deleted: Capability requirement 26. Execution Contract Database 3 owns it.
Deleted: Capability requirement 31. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, and the composition names no race for a critical section keyed by the pair to close.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 87. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 88. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 9. Execution Contract Database 1 owns it.
Deleted: Action wiring 11. Execution Contract Database 1 owns it.
Deleted: Action wiring 12. Execution Contract Database 3 owns it.
Deleted: Action wiring 13. Execution Contract Database 1 owns it.
Deleted: Action wiring 14. Execution Contract Database 1 owns it.
Deleted: Action wiring 89. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 90. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 25. Execution Contract Database 1 owns it.
Deleted: Action wiring 31. Execution Contract Database 1 owns it.
Deleted: Action wiring 32. Execution Contract Database 1 owns it.
Deleted: Action wiring 33. Execution Contract Database 1 owns it.
Deleted: Action wiring 34. Execution Contract Database 1 owns it.
Deleted: Action wiring 35. Execution Contract Database 1 owns it.
Deleted: Action wiring 36. Execution Contract Database 1 owns it.
Deleted: Action wiring 93. Execution Contract Constituent failure 2 owns it.
Deleted: Action wiring 95. Execution Contract Constituent failure 1 owns it.
Deleted: Action wiring 47. Execution Contract Database 2 owns it.
Deleted: Action wiring 49. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 50. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Action wiring 53. Execution Contract Database 1 owns it.
Deleted: Action wiring 67. Action wiring 63 through 65 own it: an absent attestation the purge record names answers not-applicable(purged) under either retention scope, and one it does not name answers the tamper reading.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 3. Execution Contract Database 1 owns it.
Deleted: Wiring decision 8. Permissions Identity 7 owns it: a pair holds one active grant, so the composition forbids no second one and Action wiring 103 through 106 answer an issuance on a held pair.
```

### Composition logic › Housekeeping

```
Deleted: Housekeeping 11. Execution Contract Database 1 owns it.
Deleted: Housekeeping 12. Execution Contract Database 1 owns it.
Deleted: Housekeeping 19. Action wiring 38 owns it: a retry stands as a fresh administrative act, and no rule obliges a caller to retry an orphan's act.
```

### Composition-level invariants

```
Deleted: Invariant 1.3. Execution Contract Database 1 owns it.
Deleted: Invariant 2.3. Execution Contract Database 1 owns it.
Deleted: Invariant 9.4. Execution Contract Database 1 and Execution Contract Database 2 own it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.3. Execution Contract Database 1 owns it.
Deleted: Check 5.4. Execution Contract Database 1 owns it.
Deleted: Check 5.5. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 3. Execution Contract Database 1 owns it.
Deleted: External check 4. Execution Contract Database 3 owns it.
```

### Non-goals

```
Deleted: Non-goal 10. Permissions Identity 7 owns it: the constituent keeps one grant per pair, so the composition deduplicates nothing and a deduplication layer has nothing to do.
```

### Edge cases › Atomic writes

```
Deleted: Atomic writes 3. Execution Contract Database 1 owns it.
Deleted: Atomic writes 9. Execution Contract Database 1 owns it.
Deleted: Atomic writes 10. Execution Contract Database 1 owns it.
Deleted: Atomic writes 11. Execution Contract Database 1 owns it.
```

### Edge cases › Clock semantics

```
Deleted: Clock semantics 2. Identity 8 owns it: a proposal carries the request instant (Identity 7), and the request instant is the invocation's seam reading.
Deleted: Clock semantics 1. Capability requirement 1 owns it.
Deleted: Clock semantics 3. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 4. Execution Contract Logic confinement 3 owns it.
Deleted: Clock semantics 8. Clock dependence 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 3. Permissions Identity 7 owns it: a pair holds one active grant, so there is no second grant to read as a defect.
Deleted: Concurrency 4. Execution Contract Database 2 owns it.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 9. Execution Contract Database 2 owns it: a pair-scoped revocation's enumeration and the revocations it decides are one transaction, so no issuance commits inside the sweep for a critical section to keep out.
```

---
title: Authenticated Actor — history
nav_exclude: true
search_exclude: true
---

# Authenticated Actor — history

The dated record of how [Authenticated Actor](./authenticated-actor.md) got here, moved out of the spec on 2026-10-20 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/authenticated-actor.md`.

## Decisions

Entries that record a migration, a council read's collapse, a family placement or a regeneration rather than a turn the pattern took.

- **2026-08-30 — The gate runs under the composition's own critical section and names its residue; the orphan re-enters instead of dying; every exported code carries its position.** *Chose:* `principal_section` declared as an instance capability requirement with lease semantics, under which the status read and the attestation write run, with an externally-issued `Credential.revoke` stated as **not** serialized and the one-attestation residue it can produce declared, bounded by `attest_completion_bound`, and made findable by a credential id on every `attest_log` entry; a composition-introduced storage-level uniqueness constraint on both binding maps re-checked at step 4; a re-entry arm on `duplicate-active-credential` that binds the existing effective-Active credential only after `Credential.verify` proves the presenter holds it (`invalid-credential(existing)` otherwise), so a re-invocation after a binding-position failure reaches the step that failed without becoming a way to claim another principal's credential; `orphan-credential(credential_id)` for the post-commit guard re-run; the lease measured from the critical section take as one interval with each completion bound; check 2 sizing the residue on the attestation's `attested_at` against `revoked_at` within `clock_offset_allowance + attest_completion_bound`; a report-only orphaned-credential leg on `reconciliation_cadence` and at restart, filtered by unbound credential id and gating pair, bounded below by `registration_completion_bound`, declared horizon-less, promising no closure window, and carried as check 6; `storage-failure(credential | binding)`, `namespace-conflict(guard | binding)`, and `attest-failed(attestation | log(attestation_id))` on the signatures; clock offset allowance on every cross-seam comparison, with check 2 reporting candidates inside the window. *Over:* a "record lock `Credential.revoke` must acquire" attributed to Credential Invariant 2, which declares a uniqueness constraint and no lock; a re-entry arm that adopted an existing credential on the presenter's say-so; a namespace guard offered as a serialization; an orphan "surfaced as a finding" by no leg and repaired by no action; a bare token on both sides of the credential commit and no arm at all after the attestation commit; a breach example that ordered two seams' stamps as if they were one clock. *Because:* an invariant is only as sound as the capability it rests on, and a lock nobody declared is ambient authority; a re-invocation that dies at `duplicate-active-credential` cannot repair the failure it was retried for; a caller who cannot tell credential from binding registers twice; a binding nobody proved possession for is an authority-bearing transition resting on an unauthenticated principal; and a stamp from another seam narrows a decision, never makes one (the frozen rules of 2026-08-30 — *Capability provenance*, *A composition's own rejection arm carries the retry bit*, *A stamp from another seam never decides a write alone*, *A compensator is exclusive* — with *A reconciliation is bounded at both ends* and *Recovery commits under a declared service identity*, frozen 2026-08-29, and the section titled *Authentication precedence* in `pressure-testing.md`, frozen 2026-08-27).

- **2026-09-14 — Rewritten in GRACE lang v0.40; nothing but language changed except one invariant the Execution Contract already owns.** *Chose:* `Composes`, `Composition state`, `Capability requirement`, `Primitive policy`, `Action wiring`, `Wiring decision`, `Concurrency` and `Reconciliation` as the surfaces, the four surviving invariant numbers unchanged, and the acceptance section's own two tiers carried across. *Over:* the prose spec. *Because:* the migration plan; nothing in the corpus cites this composition by label. `Reconciliation` is the one family minted, for the orphaned-credential leg — a second instance of the shape [Idempotent Reservation](./idempotent-reservation.md) minted `Eviction` for, a leg running outside an invocation, and the two are deliberately **not** merged: one evicts and one reports, one takes a critical section and one refuses to, and calling them one family would bury the difference that decides whether either owes a liveness bound. Two names at one spec each, both flagged, both waiting (council read 61).

- **2026-09-14 — The fourth preservation-claim collapse, and the cheapest.** *Chose:* `Composes 4`, with `Invariant 5 — Constituent invariants preserved` tombstoned to it. *Over:* keeping it. *Because:* council read 53's ruling at its fourth seam. This spec spent **one** rule covering both constituents where the other three spent one per atom, so one tombstone closes what took two or three elsewhere — and the reason is visible in the document: every other invariant carries a `Rests on:` clause naming the constituent guarantees it leans on, which is provenance done properly at the invariant level. The blanket was the single place that discipline lapsed into a restatement. What it carried beyond the blanket survives as `Composes 5` through `Composes 10`: the refusals (no verify at the gate, no rotate, no revoke, no registry write) and the gate's key, none of which either atom guarantees about a caller.

- **2026-09-14 — Both extraction-pending elements were classified before the rewrite began.** *Chose:* to declare the classification against the prose spec at council read 59 and carry it into the rules here unchanged. *Over:* discovering it during the migration, which is when every other composition's state question surfaced. *Because:* the classification does not depend on the language — the section titled Composition state in `execution-contract.md` turns on whether the truth is reconstructible from constituent stores, which is a fact about the wiring — and settling it first made the `Composition state` family write itself. That order is worth keeping: classify, then migrate.

- **2026-09-14 — `Reconciliation` re-cut as `Housekeeping`, on a discriminator the first cut got wrong.** *Chose:* the family renamed, with the seven rules and every citation of them moving with it. *Over:* keeping the name and letting `Reconciliation` reach three specs. *Because:* the entry above split this leg from [Idempotent Reservation](./idempotent-reservation.md)'s on *one evicts and one reports*, and the drift pass `GRACE-lang.md` Standard label 7 requires found that axis predicts the liveness bound on **two of four** legs — this leg reports and owes none, Eviction takes a critical section and writes and owes none, and the verb decides neither. What survives every member is whether anything **awaits** the leg's output: [Login](./login.md)'s and [Defensible Retention](./defensible-retention.md)'s sweeps discharge a promise inside a declared window and owe a bound; this leg and idempotent reservation's evict or report with nobody waiting and owe none. Two families of two, cut on the guarantee rather than on the verb (council read 64).

- **2026-09-28 — What the cold regeneration met, restored.** *Chose:* an absent credential type passing the gating default (Action wiring 30), where Primitive policy 4 refused it as blank and the default had no reader; Credential's register refusals landing (Action wiring 31, 32), where storage-failure naming the credential sat on the signature with no rule; a lapsed holder finding its actor reference bound answering namespace-conflict naming the binding (Action wiring 33), where only the principal side had a landing and the guard's own answer would have said nothing committed; the refused entry's observed status and credential id stated (Action wiring 34), as the prose stated them; where Check 3.2 cited a rule that says neither; a refused call's failed append answering attest-failed naming a bare log (Action wiring 35), where Action wiring 25 demanded an attestation id no refusal has, and Invariant 4.1 scoped to the calls that append; the orphaned-credential leg keyed on the pair (Housekeeping 6), where keying on the binding's initial credential id reported every rotation's successor as an orphan; a known attestation resolved whatever its verification result (Action wiring 27), where the rewrite resolved only a verified one; and the attest lease's two termini (Action wiring 36, 37), which the prose carried and the rewrite left to a WHY. *Over:* the 2026-09-14 rewrite's readings. *Because:* each was a rule the page's own signature, walkthrough or checks contradicted, or a decision the prose made and the rewrite dropped, found by building it; the pair is the key the gate already uses (Composes 9).

- **2026-10-20 — The store's guarantees cited, not restated, the per-principal critical section and its declared residue among them.** *Chose:* the store supplied under Execution Contract Store 1 through 4 (Capability requirement 12), and the forty rules that restated it, or existed only for a store that could lose or split a write, tombstoned to their owner — to Store 1, under which a registration's credential and binding commit together and an attestation commits with its attest log entry: the maps' one transaction and the bar on wrapping the credential write and the binding write in one (Composition state 3, Non-goal 14), the report-only orphaned-credential leg with its cadence, its check and the note obliging a deployment to act on its report (Housekeeping 1 through 7, the first with Store 3; Capability requirement 9, Check 6.1, Composition note 6), and the check finding every attestation older than the attest completion bound carrying its entry (Check 4.1); to Store 1 and Store 2, the two completion bounds and the refusal to start without them (Capability requirement 7, 8, 11); and to Store 2, under which an action's guard reads and the writes they decide are one transaction: the host's critical section keyed by principal reference, with its supply, release, lease and holding rules and its external check (Capability requirement 3 through 6, Action wiring 1, 16, Wiring decision 2, 3, Concurrency 1, External check 2), the binding write's uniqueness refusal and the lapsed section's re-take with its re-run guard's landings (Action wiring 10, 12, 13, 33, 36, 37), the gate read preceding the attestation write inside the held section (Invariant 1.2, with Action wiring 19), and the declared revoke residue with its bound, its check, the routes a deployment had to close it and the gate read after a revoke (Concurrency 2 through 6, Check 2.3, Composition note 5); with them [Register Authenticated Actor]'s signature loses orphan-credential and the conflict position its binding value, a failed success entry answers attest-failed naming the log without a committed attestation's id (Action wiring 25), and Check 2.2 reads a violation beyond the clock offset allowance alone; rules 146 to 107. *Over:* a host-supplied critical section with lease semantics under which the gate read and the attestation write ran, a declared one-attestation residue for a revoke landing inside it, and a credential committed apart from its binding, with positioned arms and a report-only leg for the orphan — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included: Credential's records, the binding maps, Actor Identity's attestations and the attest log are one store, so a registration's credential and binding commit together or not at all, and an attestation commits with its entry. Store 2 reads the state an action's guards decide on inside the transaction that writes the action's effects, so the gate's read of the gating credential is in the attesting transaction and a revoke of that credential commits before the read or after the attestation, as the maintainer ruled 2026-10-20 for a guard decided across a lease check whose grant lives in the one store; the composition still never calls Credential's revoke (Composes 7). The other calls a rule decided: the rewrite's rule that machinery existing only because a store could lose, split, edit or forget a write goes takes the orphaned-credential leg, which the page gave the split's orphan alone (Non-goal 14), though its pair filter would also have reported a credential registered for the pair outside the composition, the kind Action wiring 5 through 7 adopt; the same rule keeps Action wiring 11, a storage failure's only landing and no machinery, now with nothing committed; Action wiring 9 stays as the only rule obliging the binding write, the register's commit being its nested Step 3 inside the registration's one transaction (pipelines nest whole: the section titled Substrate composition invocation in `execution-contract.md`); and Check 5.1 rests on the auditor's own reads rather than on an entry's earlier versions, so Store 5 is not cited. What the composition does for its domain is otherwise unchanged.

- **2026-10-31 — An attempt the gate turns away is answered, not refused, so the attest log keeps it.** *Chose:* [Attest As Actor] answering not-bound, credential-not-active, registry-unavailable and invalid-attest-credential beside the attestation id, and refusing only invalid-request and attest-failed, so each of those four calls is admitted and its attest log entry is its own committed write: the append moved out of the Invariant family into Action wiring 45 (Invariant 4.1 deleted to it), Actor Identity's registry-unavailable landed as the composition's answer by Action wiring 47 under Execution Contract Constituent failure 2, a pair Credential's read answers no credential for recorded as the observed status none (Action wiring 46), and a refused call, the boundary predicate's or Actor Identity's invalid-request, writing nothing. *Over:* the four as refusals whose attest log entries the page obliged while Execution Contract Read 4 has a refused call write nothing (open line 2026-10-27-a, opened by Final Critique 5's settle and re-found by every reader of Final Critiques 6 and 7), and *retire*, which would have dropped the refused attempts' entries and the breach investigation's claim. *Because:* the ruling of 2026-10-31 16:48Z, recorded under the maintainer's standing ruling of 2026-10-20 that a refused attempt a page keeps as evidence stays, written in the same transaction as the refusal, answered the 2026-10-26 11:43Z escalation's (b) for this page: keep, in the form Final Critique 6's Linus pass wrote. The record of every post-revocation attempt is what the breach investigation reads, and Read 4 holds as written, as Credential's verify answers failed-verification as an outcome.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Authenticated Actor](./authenticated-actor.md) may carry it again.

### Composition logic › Composition state

```
Deleted: Composition state 3. Execution Contract Database 1 owns it.
Deleted: Composition state 8. Action wiring 45 owns it.
```

### Composition logic › Capability requirement

```
Deleted: Capability requirement 3. Execution Contract Database 2 owns it.
Deleted: Capability requirement 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to release.
Deleted: Capability requirement 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lease.
Deleted: Capability requirement 7. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 8. Execution Contract Database 1 and Execution Contract Database 2 own it.
Deleted: Capability requirement 9. Execution Contract Database 1 owns it.
Deleted: Capability requirement 11. Execution Contract Database 1 and Execution Contract Database 2 own it: the composition names no completion bound or cadence for a deployment to leave unset.
Deleted: Capability requirement 15. Execution Contract Conformance 9 owns it.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 1. Execution Contract Database 2 owns it.
Deleted: Action wiring 10. Execution Contract Database 2 owns it.
Deleted: Action wiring 12. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 13. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Deleted: Action wiring 16. Execution Contract Database 2 owns it.
Deleted: Action wiring 38. Action wiring 47 owns it.
Deleted: Action wiring 33. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so no guard runs again over a committed credential.
Deleted: Action wiring 35. Action wiring 25 owns it.
Deleted: Action wiring 36. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
Deleted: Action wiring 37. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, and the composition names no critical section to lapse.
```

### Composition logic › Wiring decision

```
Deleted: Wiring decision 2. Execution Contract Database 2 owns it.
Deleted: Wiring decision 3. Execution Contract Database 2 owns it.
```

### Composition logic › Housekeeping

```
Deleted: Housekeeping 1. Execution Contract Database 1 and Execution Contract Database 3 own it.
Deleted: Housekeeping 2. Execution Contract Database 1 owns it.
Deleted: Housekeeping 3. Execution Contract Database 1 owns it.
Deleted: Housekeeping 4. Execution Contract Database 1 owns it.
Deleted: Housekeeping 5. Execution Contract Database 1 owns it.
Deleted: Housekeeping 6. Execution Contract Database 1 owns it.
Deleted: Housekeeping 7. Execution Contract Database 1 owns it.
```

### Composition-level invariants › Invariant 1 — Revocation cascade, attest-surface closure

```
  Deleted: Invariant 1.2. Action wiring 19 and Execution Contract Database 2 own it.
  Deleted: Invariant 1.3. Invariant 1.1 owns it: a revoked credential never reads effective-active again (Credential Invariant 5.1), and a new credential for the principal reference AND the credential type opens the gate (Composes 9).
```

### Composition-level invariants › Invariant 2 — Secret-surface separation

```
  Deleted: Invariant 2.3. Capability requirement 14 owns it.
```

### Composition-level invariants › Invariant 4 — Attestation traceability

```
  Deleted: Invariant 4.1. Action wiring 45 owns it.
  Deleted: Invariant 5. Composes 4 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 2.3. Execution Contract Database 2 owns it.
Deleted: Check 4.1. Execution Contract Database 1 owns it.
Deleted: Check 6.1. Execution Contract Database 1 owns it.
```

### Generation acceptance › External checks

```
Deleted: External check 2. Execution Contract Database 2 owns it.
```

### Non-goals

```
Deleted: Non-goal 14. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 1. Execution Contract Database 2 owns it.
Deleted: Concurrency 2. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so a revoke of the credential a gate read commits before the read or after the attestation.
Deleted: Concurrency 3. Execution Contract Database 2 owns it.
Deleted: Concurrency 4. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue to bound.
Deleted: Concurrency 5. Execution Contract Database 2 owns it.
Deleted: Concurrency 6. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
```

### Composition notes

```
Deleted: Composition note 1. Execution Contract Conformance 9 owns it.
Deleted: Composition note 2. Capability requirement 14 owns it.
Deleted: Composition note 5. Execution Contract Database 2 owns it: an action's guard reads and the writes they decide are one transaction, so the composition declares no residue for a deployment to close.
Deleted: Composition note 6. Execution Contract Database 1 owns it: a registration's credential and binding commit together, so the composition reports no orphaned credential.
```

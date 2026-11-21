---
title: Preference-Aware Notification Fanout — history
nav_exclude: true
search_exclude: true
---

# Preference-Aware Notification Fanout — history

The dated record of how [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) got here, moved out of the spec on 2026-10-21 because a reader does not need it to use the spec today. The spec keeps every section `spec-format.md` requires and its `Deleted:` tombstones; everything smaller is in `git log -- compositions/preference-aware-notification-fanout.md`.

## Decisions

Entries that record a migration rather than a turn the pattern took.

- **2026-06-11 — Delivery frequency accounting is a rule inside the shaping disposition, not an extracted concept.** *Chose:* the frequency-cap verdict is a pure function over Event Log's delivery history and the injected clock, evaluated inside `shaping_disposition`. *Over:* a Delivery Frequency Accounting atom. *Because:* it has no state machine of its own, no freestanding surface to compose, and another pattern would reinvent one Event Log read, not a concept.

- **2026-08-30 — The deliver pair is ordered, not atomic; one writer per disposition under a declared section; the gap leg bounded at both edges and writing its intent first.** *Chose:* `Notification.create` then `EventLog.append`, with the reachable partial named — a Pending record carrying the fanout_id in its envelope and no `fanout.created` — and adopted by [Reconcile Gaps] under `recovery: true` through the declared `pending_for` read, with `orphan_lookup` as the optional capability that reaches an orphan in any status; a per-disposition section keyed by `(fanout_id, principal_ref)`, declared as an instance capability requirement with lease semantics, held by [Fanout Shaped], [Redispose], and [Reconcile Gaps] alike, its expiry the holder's terminus (yielded on the batch result, `rejected(yielded)` on [Redispose]); [Reconcile Gaps] examining nothing younger than `invocation_duration_bound` (`rejected(too-young)`) and nothing past the journal's retention horizon, writing `fanout.reconcile-intended` before any repair, and abandoning under the section at most `abandonment_principals_cap` principals per record; `journal-rejected(read | outcome(notification_id | none))` and `journal-rejected(intent | abandonment)` carrying the position; the three-term liveness inequality with `reconciliation_cadence` and `disposition_write_latency`, checked at start; `max_query_latency` widening Check 1's window; the largest writable record sized, not only the intent. *Over:* a pair claimed to land together or not at all over two writes both constituents declare un-withdrawable, and a gap leg that read "a Notification without a journal pair cannot exist" as licence to redispose; a bare host-conformance serialization that ordered the invocation's write after the leg's instead of preventing it; a leg with no lower edge that read a loop still running as a crash; one bare token on both sides of the create. *Because:* an append-only journal and a never-deleted record cannot be enlisted in one transaction, so the honest claim is order plus a named partial plus its repair; two writers over one disposition land two live notifications for one principal, which Invariant 9 exists to forbid; a leg that corrects work in flight is a wrong act, not a wrong report; and a caller who cannot tell read from outcome re-runs a committed create (the frozen rules of 2026-08-30 — *A compensator is exclusive*, *Liveness is arithmetic*, *An outcome is sized before the intent*, *A stamp from another seam never decides a write alone*, *A composition's own rejection arm carries the retry bit*, and *Capability provenance* — with §*A reconciliation is bounded at both ends*, §*Recovery commits under a declared service identity*, and §*Durability boundaries*). *The same day's closure check moved four more things:* the lease is mandated rather than optional (a section that cannot expire is not a conforming section) and is reentrant for its holder alone, so [Reconcile Gaps] calls [Redispose] as the holder and a foreign-held pair refuses with yielded; adoption is the leg's alone — a caller's [Redispose] that finds an orphan returns `rejected(orphan-pending(notification_id))` and writes nothing; the leg's lower edge is `invocation_duration_bound + notification_create_latency`, because a create issued at the lease's last instant is still landing when a `pending_for` read at the bare bound would miss it; and the leg's arms are closed — `payload_content | none` and `abandon: true` as declared arguments, `rejected(reason)` entries carried to the next run rather than abandoned, `journal-rejected(intent | adoption(notification_id) | abandonment)`, and `fanout.abandoned.reason` enumerated.

- **2026-09-23 — Rewritten in GRACE lang v0.61; two of four open Ledger lines closed by the rules that now own them.** *Chose:* `Composes`, `Composition state`, `Capability requirement` — which takes the prose's Configuration whole — `Primitive policy`, `Action wiring`, `Wiring decision` and `Reconciliation` as the surfaces, with the precedence table as its own `Shaping gate` family and the replay procedure as `Verdict replay`; invariant numbers 1 through 5 and 7 through 10 unchanged, Invariant 6 tombstoned to Composes 5 and its store-write limits kept as Composes 7 through 10; the checks renumbered `Check 1.1` through `Check 6.1`; `Non-goals` and `Edge cases` split, with `Clock semantics`, `Concurrency`, `Payload retention`, `Per-channel caps` and `Staleness` under the second; the host's per-disposition section named an *exclusion*, since the grammar owns *section*. The lines' fixes: the overshoot record's undefined *action* field dropped, a detector taking no action to name (2026-08-30-a); a hold retry horizon declared, past which a hold suppression is not retryable, and payload retention bounded by the later of it and the reconciliation window (2026-08-30-c). *Over:* the prose spec. *Because:* the migration plan, and the standing rule that a migration closes a line only where a rule now owns what the line asked for. Two stay open: the orphan lookup's constituent home, which waits on the Reverse Index pattern (2026-08-30-b), and the model (2026-08-30-d).

- **2026-10-21 — The store's guarantees cited, not restated, the deliver-pair orphan and its adoption among them.** *Chose:* Capability requirement 47 citing Execution Contract Store 1 through 4 for the store the four constituents keep their records in; to Store 1, under which one subscriber's disposition — its create and its delivery event — commits together, the machinery that existed only because a create could land without its journal half: the orphan lookup, [Redispose]'s selection of a pending record carrying the fanout id with its orphan-pending refusal, the caller's bar on calling [Redispose] again after a journal-rejected that carried a notification id, the gap run's selection, adoption and ambiguous-candidate abandonment with its refused adoption, and the auditor's checks of adoptions (Capability requirement 40, Action wiring 49 through 51, 57, Reconciliation 12 through 16, 27, Check 1.2, 2.3, 3.5, 4.2); to Store 2, under which an action's guard reads and the writes they decide are one transaction, the bars on reading a preference record or checking retryability before taking the per-disposition exclusion, the exclusion's span over a [Redispose]'s status read and create, and the scheduler's one overshoot run per principal with the existence read under it (Action wiring 9, 41, Concurrency 2, Reconciliation 33, 34). By clause, the gap run's [Redispose] call loses its zero-candidate condition, an abandonment record its candidates and a refused append the adoptions it left standing (Reconciliation 17, 22, 29); Check 3.4 reads every delivery event; External check 3 confirms the journal's predicates alone, its durability being Store 3's and Store 4's; [Redispose] no longer refuses orphan-pending, the redispose position carries no notification id, the gap position no adoption and the abandonment reason no candidates-ambiguous. Rules 274 to 255. *Over:* a delivery pair ordered rather than atomic, whose create could stand without its journal half until the gap leg adopted it — the turn of 2026-08-30, above. *Because:* the maintainer ruled 2026-10-12 that the corpus takes a store's specification, never the store, and 2026-10-20 that Store 1 binds every store write of one composition action, its constituents' included, that a fan-out's create for each recipient is its own action, and that Store 2 covers a guard decided across a lease check. One subscriber's disposition is that action, so a refused delivery event leaves the subscriber yielded with nothing written, and no orphan is left to adopt. What the page does for its domain is unchanged. The dispositions of one invocation stay separate actions, so a crash between two of them still leaves a gap, and the gap leg — its restart run, its intent, its lower edge, its redisposition and its abandonment — stays. The per-principal exclusion stays, since the cap reads the delivery count index, a derived index outside the action's transaction (obligation 2 of the section titled Composition state in `execution-contract.md`). The per-disposition exclusion stays with its lease, which is the holder's terminus: it bounds how stale the one now is for a late-loop subscriber, on which Invariant 3 rests, and keeps a live loop inside the gap leg's lower edge, which the store does not do.

- **2026-11-21 — A redisposition ends with its initiation entry's aging, and an overshoot's reconciliation window counts from its own delivery event.** *Chose:* [Redispose] answers not-retryable once the initiation entry is an aged entry (Action wiring 62), so the hold retry horizon ends no later than the entry's aging; the best-effort overshoot's window counts from the overshooting delivery event's decided instant, the gap leg's from the fired instant (Invariant 4.3, Check 2.4, Term reconciliation window, Term escalation reach). *Over:* ordering the audit horizon above the hold retry horizon at start, which a chain of hold suppressions each retried inside the horizon defeats; retaining every configuration version through the hold retry horizon; and counting the overshoot's window from the fired instant, which a [Redispose]'s later delivery event has already passed when it lands. *Because:* a retry past the entry's aging needs a configuration version Capability requirement 9 no longer retains (Verdict replay 4, Invariant 7.1), and the fired instant makes Invariant 4.3 unsatisfiable for any redisposition's overshoot.

## Deleted rules

The spec's tombstones, moved here from the page on 2026-11-13 because the spec is done (GRACE-lang Hard invariant 25 and Hard invariant 27, since v0.71): each `Deleted:` line byte for byte and in the page's order, under the heading it stood under there. A tombstone carries no obligation, and each still reserves its label: no rule of [Preference-Aware Notification Fanout](./preference-aware-notification-fanout.md) may carry it again.

### Composition logic › Capability requirement

```
Deleted: Capability requirement 24. Term reconciliation run bound owns it: the run bound counts every write's landing.
Deleted: Capability requirement 40. Execution Contract Database 1 owns it: a disposition's create and its delivery event commit together, and the composition names no orphan for a lookup to find.
```

### Composition logic › Action wiring

```
Deleted: Action wiring 9. Execution Contract Database 2 owns it.
Deleted: Action wiring 41. Execution Contract Database 2 owns it.
Deleted: Action wiring 49. Execution Contract Database 1 owns it.
Deleted: Action wiring 50. Execution Contract Database 1 owns it.
Deleted: Action wiring 51. Execution Contract Database 1 owns it.
Deleted: Action wiring 57. Execution Contract Database 1 owns it: a redisposition's writes commit together, so no journal-rejected carries a notification id.
```

### Composition logic › Reconciliation

```
Deleted: Reconciliation 2. Execution Contract Scheduled leg 1 owns it.
Deleted: Reconciliation 12. Execution Contract Database 1 owns it.
Deleted: Reconciliation 13. Execution Contract Database 1 owns it.
Deleted: Reconciliation 14. Execution Contract Database 1 owns it.
Deleted: Reconciliation 15. Execution Contract Database 1 owns it.
Deleted: Reconciliation 16. Execution Contract Database 1 owns it.
Deleted: Reconciliation 27. Execution Contract Database 1 owns it.
Deleted: Reconciliation 33. Execution Contract Database 2 owns it.
Deleted: Reconciliation 34. Execution Contract Database 2 owns it.
```

### Composition-level invariants › Invariant 10 — Invocation identity is unique and journaled

```
  Deleted: Invariant 6. Composes 5 owns it.
```

### Generation acceptance › Conformance checks

```
Deleted: Check 1.2. Execution Contract Database 1 owns it.
Deleted: Check 2.3. Execution Contract Database 1 owns it.
Deleted: Check 3.5. Execution Contract Database 1 owns it.
Deleted: Check 4.2. Execution Contract Database 1 owns it.
```

### Edge cases › Concurrency

```
Deleted: Concurrency 2. Execution Contract Database 2 owns it.
```

# Coverage matrix — `provenance`

- **Pattern:** `atoms/provenance.md`
- **Model:** `provenance.als`, the static data model, re-derived 2026-11-12 (+ 6 buggy twins `provenance-buggy-<defect>.als`), and `provenance.tla` + `provenance.cfg`, the operation sequences, 2026-11-12 (+ 13 buggy twins `provenance-buggy-<defect>.tla`, each with its `.cfg`). The twins `provenance-buggy.als` (dropped the `CustodyContinuity` fact) and `provenance-buggy-link.als` (the successor link one way) went with the model they were copies of.
- **Reviewer / date:** the models' author, the session that landed them — 2026-11-12 (unit `atoms/provenance.md formal layer`). Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** custody continuity (Invariant 4) first, then single origin (3), archived terminal (6), the append-only chain and its order (2, 5), custodian presence (7) and event-type validity (8). Since the maintainer's ruling of 2026-11-09 the page takes both models; neither is vetoed.

## Step 1 — harness run

- Correct model: `node check.mjs ../../atoms/provenance.als` → `HOLDS` ✓ *(11 commands: 6 checks UNSAT, 5 runs SAT, at `for 5 but 4 Int`, about 20 s)*
- Correct model: `node check.mjs ../../atoms/provenance.tla` → `HOLDS` ✓ *(8,314 states, TLC about 20 s on one worker)*
- Alloy twins, one defect each, each `CAUGHT` on the check it targets: `-guard-unchecked` (`A_Inv4_2`), `-transfer-from-caller` (`A_Inv4_3`), `-transfer-keeps-custodian` (`A_Inv4_4`), `-counter-unraised` (`A_Inv5_1`), `-originate-blank-custodian` (`A_Inv7_1`), `-transfer-blank-to` (`A_Inv7_2`).
- TLA+ twins, one defect each, each `CAUGHT` on the check it targets when run against that check alone: `-disclose-amends` (`Inv1_1_EntryFixed`), `-storage-rollback` (`Inv2_1_CountNeverFalls`), `-newest-first` (`Inv2_2_SequenceFixed`, `Inv3_2_GenesisAtOne`), `-reoriginate` (`Inv3_3_NoSecondOriginate`, `Inv3_1_OneGenesis`), `-transfer-cache-stale` (`Inv4_1_OneCurrentCustodian`), `-storage-takes-number` (`Inv5_2_DenseFromOne`, `Op42_RefusedLeavesChain`), `-read-by-instant` (`Inv5_3_OrderBySequence`), `-archive-toggles` (`Inv6_1_ArchivedStays`), `-transfer-on-archived` (`Inv6_2_ArchivedAdmitsNothing`), `-genesis-unchecked` (`Inv8_2_GenesisTyped`), `-transfer-received` (`Inv8_3_LaterNotGenesis`), `-archive-unrecorded` (`Inv8_4_ArchivedLast`), `-archive-deletes` (`Inv10_1_ChainsNeverFall`).
- `node audit.mjs --only atoms/provenance --limit-min 50` (2026-11-12): 21 models, 2 HOLDS, 19 CAUGHT, 22 checks in 2 correct models, 0 red. Where a twin breaks several checks, its TWIN PER CHECK section may name another breaking twin than the row below; each row's twin was also run against its check alone and breaks it.
- Assumptions: one Alloy fact, `CommitOrder` (calls on a chain commit one after another, each finding what the one before committed: Execution Contract Order 1 and Database 2). The TLA+ model has no ASSUME and no CONSTRAINT; the clock moves, backwards too, by an action of its own, and the host's chain and entry ids come from the model's own slots and counter (Identity 3, 4). Every rule the page promises is checked, none assumed. The model of 2026-06-04 stated custody continuity as a fact and its checks restated it; that is gone.

## Step 2 — coverage matrix

The Alloy model builds one chain as what an ordered sequence of admitted calls leaves: each call's entry and the version of the chain record it left, and reads custody by replaying the entries in sequence number order, as the auditor does (Check 3.1). The TLA+ model runs the calls, a write the database refuses, [Read] and a clock that may read any instant, over one chain slot with room for three entries.

| Spec claim | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a recorded entry's fields do not change | no | `checked` covered (TLA+) | `Inv1_1_EntryFixed`: the entry with the same entry id after a step carries every field it carried (Check 6.1, Correction 1). Nothing testable in Alloy: across steps. Broken by `provenance-buggy-disclose-amends.tla` ([Disclose] amends the latest entry instead of appending). |
| Invariant 2.1 — a chain's entry count does not fall | no | `checked` covered (TLA+) | `Inv2_1_CountNeverFalls` (Correction 2). Broken by `provenance-buggy-storage-rollback.tla` (a refused write rolls back the entry before it); `-archive-deletes` breaks it too. |
| Invariant 2.2 — a recorded entry's sequence number does not change | no | `checked` covered (TLA+) | `Inv2_2_SequenceFixed`. Broken by `provenance-buggy-newest-first.tla` (each append renumbers the chain newest first). |
| Invariant 3.1 — exactly one genesis entry per chain | yes | `checked` covered (TLA+) | `Inv3_1_OneGenesis`, a state invariant over every reachable state (Check 2.1); the genesis entry is the one [Originate] appended (the model's own `op` field: the page stores no genesis type, State 10). Broken by `provenance-buggy-reoriginate.tla` (a second genesis on a recorded chain). |
| Invariant 3.2 — the genesis entry's sequence number stands at one | no | `checked` covered (TLA+) | `Inv3_2_GenesisAtOne` (Check 2.2). Broken by `provenance-buggy-newest-first.tla` (and `-reoriginate`). |
| Invariant 3.3 — no second originate against a recorded chain | yes | `checked` covered (TLA+) | `Inv3_3_NoSecondOriginate`: an admitted [Originate] lands only on a chain id no chain held. Broken by `provenance-buggy-reoriginate.tla` (a returned batch re-opened on its old chain). |
| Invariant 4.1 — an open chain has exactly one current custodian | yes | `checked` covered (TLA+) | `Inv4_1_OneCurrentCustodian`: the cached current custodian is a non-blank reference and is the one the entries name when replayed (State 18), so the cache and the entries never stand two custodians current. Broken by `provenance-buggy-transfer-cache-stale.tla` ([Transfer] leaves the cache where it was). |
| Invariant 4.2 — a custodian-guarded entry's custodian equals the custodian it found | yes | `checked` covered (Alloy) | `A_Inv4_2`, against the custodian replayed from the entries before it (Check 3.3). Broken by `provenance-buggy-guard-unchecked.als` (Operation 26 dropped). |
| Invariant 4.3 — a transferred entry's from custodian equals the custodian it found | yes | `checked` covered (Alloy) | `A_Inv4_3`, against the replay (Check 3.2). Broken by `provenance-buggy-transfer-from-caller.als` (the from-side taken from the caller, Operation 18). |
| Invariant 4.4 — a transferred entry's to custodian equals the custodian it set | yes | `checked` covered (Alloy) | `A_Inv4_4`: the chain record's current custodian after the transfer. Broken by `provenance-buggy-transfer-keeps-custodian.als` (Operation 21 dropped). |
| Invariant 5.1 — two entries in a chain share no sequence number | no | `checked` covered (Alloy) | `A_Inv5_1` (Check 4.3), over sequence numbers (the old model's position stand-in is gone). Broken by `provenance-buggy-counter-unraised.als` (Operation 37 dropped for a guarded append). |
| Invariant 5.2 — a chain's sequence numbers stand from one to the entry count | no | `checked` covered (TLA+) | `Inv5_2_DenseFromOne` (Check 4.1). Broken by `provenance-buggy-storage-takes-number.tla` (a refused write raises next sequence number, Operation 44). |
| Invariant 5.3 — a chain's order rests on sequence number alone | no | `checked` covered (TLA+) | `Inv5_3_OrderBySequence`: what [Read] answers is the append order, while the clock may read backwards between appends (Operation 46, 58; Check 4.2). Broken by `provenance-buggy-read-by-instant.tla` ([Read] orders by recording instant). |
| Invariant 6.1 — an archived chain does not leave archived | yes | `checked` covered (TLA+) | `Inv6_1_ArchivedStays` (State 11). Broken by `provenance-buggy-archive-toggles.tla` ([Archive] of an archived chain opens it again). |
| Invariant 6.2 — an archived chain admits no entry | yes | `checked` covered (TLA+) | `Inv6_2_ArchivedAdmitsNothing` (Check 5.1). Broken by `provenance-buggy-transfer-on-archived.tla` (Operation 12 dropped). |
| Invariant 7.1 — a non-transferred entry's custodian reference is non-blank | no | `checked` covered (Alloy) | `A_Inv7_1` (Check 1.1). Broken by `provenance-buggy-originate-blank-custodian.als` (Operation 2 dropped). |
| Invariant 7.2 — a transferred entry's from and to are non-blank | no | `checked` covered (Alloy) | `A_Inv7_2` (Check 1.2). Broken by `provenance-buggy-transfer-blank-to.als` (Operation 17 dropped). |
| Invariant 8.1 — an entry's event type is in the event types | no | `unstatable` by-construction | Both models type the event type as one of the six (`etype : one EventType`; the TLA+ writes only the six), so no twin could break a check of it. |
| Invariant 8.2 — a genesis entry's event type is a genesis type | no | `checked` covered (TLA+) | `Inv8_2_GenesisTyped`. Broken by `provenance-buggy-genesis-unchecked.tla` (Operation 3 dropped). |
| Invariant 8.3 — a non-genesis entry's event type is not a genesis type | no | `checked` covered (TLA+) | `Inv8_3_LaterNotGenesis`. Broken by `provenance-buggy-transfer-received.tla` ([Transfer] records its entry as received, Operation 66). |
| Invariant 8.4 — an archived chain's last entry's event type is archived | no | `checked` covered (TLA+) | `Inv8_4_ArchivedLast`, by sequence number (Check 7.2). Broken by `provenance-buggy-archive-unrecorded.tla` (Operation 30 dropped); `-transfer-on-archived` breaks it too. |
| Invariant 10.1 — the chain count does not fall | no | `checked` covered (TLA+) | `Inv10_1_ChainsNeverFall`. Broken by `provenance-buggy-archive-deletes.tla` ([Archive] disposes of the chain, Non-goal 19). |
| Operation 42 through 44 — a refused action leaves the chain, appends nothing, takes no number | no | `checked` covered (TLA+) | `Op42_RefusedLeavesChain`, on storage-failure, the refusal after every guard passed. Broken by `provenance-buggy-storage-takes-number.tla`. |

Out of scope, named (the models' headers): the refusal codes and which answers (Execution Contract Refusal 1); artifact reference, metadata, descriptor and recipient contents (Operation 61 through 65); [Read]'s filters (Operation 47 through 49, 59, 60); id uniqueness (Identity 15, 16, the host's allocation); tamper evidence (Tamper Evidence), custodian identity (Actor Identity), disclosure scope (Selective Disclosure).

## Step 3 — bound saturation

Alloy: `for 5` calls reaches the full lifecycle (originate, transfer, transform, disclose, archive); each check reads one entry against the entries before it, so a longer chain repeats a pattern already seen. TLA+: room for three entries reaches every pair of steps the checks compare (an append after a transfer, an archive after a transfer, a transfer onto an archived chain, a read after a skewed append); `MaxLen = 4` reached 149,176 states before it was stopped at depth 10 (2026-11-12), so the audit's one-worker run keeps three. Not re-run at a larger bound.

## Outcome

- GAP rows: none. Every Invariant row is `checked` by one model, but Invariant 8.1, by typing.
- Owed: none.
- Result: **clean** — no finding about the page.

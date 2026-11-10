# Coverage matrix — `chain-of-custody`

- **Pattern:** `compositions/chain-of-custody.md`
- **Model:** one model, `chain-of-custody.tla`, re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 12 through 16, Term custody bindings). Each custody action is an open, a commit and a close (three commits, not one transaction: Non-goal 12), and an act whose outcome never landed is closed by Recoverable Invocation's sweep or an operator's resolve, both modelled as contracts. [Transfer Custody]'s resolution read comes ahead of the open, and its transfer transaction re-reads the holder (Action wiring 63 through 65). The model adds a transfer written to Provenance outside every invocation, the write-ownership leg (Reconciliation 7, 11, 32) and the binding rebuild's duplicate finding (Composition state 9). With it, **11 buggy twins** `chain-of-custody-buggy-<name>.tla`: `unauthenticated`, `owed-unannounced`, `stale-holder`, `payload-pairing`, `equal-now`, `no-finding`, `finding-for-carried`, `no-false-closing-alert`, `genesis`, `no-duplicate-finding`, `unanswered-committed`; and **7 reachability probes** `chain-of-custody-probe-<name>.tla`: `recovered`, `unpaired`, `genesis`, `escalated`, `holder-changed`, `false-closing`, `operator-duplicate`.
- **What retired.** The 2026-10-27 model read a custody action as one transaction and modelled the page's own reconciliation: the pairing by Term realize, the candidates and their cap, the aged edge, the recovery identity and flag, the overdue escalation. All of that is Recoverable Invocation's now (the inherited table below).
  - Twins retired: `-buggy` (an orphan unsurfaced in the answer: Audit arm 19, 24, now Recoverable Invocation Invariant 8.4; its spirit is `Owed_outcome`, and the leg's half is `-buggy-no-finding`), `-buggy-staleread` (the reconciliation's read outside its write: Recoverable Invocation's critical section, Invariant 2, which its `-buggy-reread` breaks), `-buggy-uncapped` (Recoverable Invocation Invariant 3.5a), `-buggy-aged` (Recoverable Invocation Invariant 7.2), `-buggy-unflagged` (Recoverable Invocation Invariant 5.1, 5.2, which recoverable-invocation.tla v8 checks with `-buggy-recoveryintent` and `-buggy-recoveryflag`).
  - Twin changed: `-buggy-transferpair` (the retired Reconciliation 16 pairing) became `-buggy-payload-pairing` (the act probe matching without the pairing datum).
  - Probes retired: `-probe-overcap`, `-probe-aged`, `-probe-fault` (the escalation with candidates, the horizon edge and Primitive policy 42's hard alert: Recoverable Invocation's behaviour).
  - Kept and re-derived: `-buggy-unauthenticated`, `-buggy-genesis`, `-probe-recovered`, `-probe-unpaired` (now the leg's finding), `-probe-genesis`.
- **Reviewer / date:** the model's author, the session that re-derived it — 2026-11-10. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes for Invariant 4 (the binding bijection). What the page now stands on:
  - the acts against Provenance, over the split commit: Invariant 1.2, 4.1, 4.3, 4.4, 7.2, Wiring decision 4, the open before the commit;
  - the probes' pairing datum and the genesis lookup (Term originate probe, Term step probe, Capability requirement 34, 35). Only this page can check these: Recoverable Invocation's model does not model an adopter's probe;
  - the write-ownership leg (Reconciliation 11, 32) and the binding rebuild's duplicate finding (Composition state 9).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/chain-of-custody.tla` → `HOLDS` ✓ *(478,490 states, about 20 seconds under TLC)*
- Buggy twins and probes: each `node check.mjs ../../compositions/chain-of-custody-<name>.tla --buggy` → `CAUGHT` ✓ *(18 files; Step 2 and the twin × check table name the check that finds each)*

## Step 2 — coverage matrix

**The model in brief.**
- **Records.** One artifact, one chain id minted at the origination's commit, two custodians. A Provenance entry carries its chain, its type (genesis, transferred, transformed), its outgoing custodian (the attested custodian), the holder after it, its recording instant and, as a ghost, the invocation whose commit wrote it (0: a write outside every invocation).
- **Bound invocations: three slots,** taken in order: an origination, a transfer (its resolution read first, then its open), or a transformation, which stands for the three custodian-guarded steps.
  - Each open takes a fresh now as its pairing datum: an ordinal clock, the host's injection, which Provenance stamps as the entry's recording instant (Capability requirement 26, 34, 35).
  - Its status is resolved (a transfer between its resolution and its open), live, committed, dead (yielded, died or close failed: the intent open for the sweep), closed, refused, escalated or abandoned. `cby` says who wrote the closing; `oe` names the entry the outcome names.
  - The commit answers committed, pre-commit (the transfer's holder re-check, the transformation's holder guard: a refusal record, nothing written) or unknown (written or not, as the environment chooses).
- **The sweep** runs only on a dead intent. Its probe matches the entries of the intent's kind, key, parameters and pairing datum: one match gives a recovered outcome naming it; none or several, an escalation; an origination with no genesis lookup, an escalation (Recoverable Invocation Deviation 4c).
- **The operator** closes a dead or escalated intent with an outcome naming any entry, or abandons it, and supersedes an abandonment with an outcome. The outcome is not checked against Provenance (resolve 28, 31).
- **One transfer outside any invocation,** by the holder at the time, with no intent.
- **The leg** is one step that reads every entry against the intents; **the rebuild** is one step that reads the outcomes for an entry two name. Each answer is compared with what the records hold (the ghosts), as Propagate Consent Revocation Downstream's leg is.

| Spec rule (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a settled carried entry whose intent is not escalated, abandoned or refused carries an outcome | YES | **covered**, partly | `Owed_outcome` (the intent stands open or beside a closing), `Invariant_4_3` (never two invocation-written outcomes). *Settled* is the clock's (Not modelled); that the sweep closes within the closure window is Recoverable Invocation Invariant 4.2's |
| Invariant 1.2 — an outcome without the recovery flag is attested under the acting custodian | YES | **covered** | `Inv1_Attributed`: every outcome the invocation or the sweep wrote names an entry of its kind whose attested custodian is the intent's actor (the intent's actor is the close's attester: Recoverable Invocation Term outcome shape). Twin `-stale-holder` |
| Invariant 2.1, 2.2 — seal coverage; a rewrite fails verification | no | out-of-scope | Audit Trail's (audit-trail.tla, Invariant 3); [Verify Custody] is not modelled |
| Invariant 3.1, 3.2 — retention record; purged answered | no | out-of-scope | Audit Trail's cascade on purge |
| Invariant 4.1 — no orphan entry unsurfaced | YES | **covered** | `Owed_outcome` for an entry an invocation wrote (an open intent, an outcome, an escalation, an abandonment the leg alerts); `Write_ownership_finding` for one no intent carries; `False_closing_alert` for one beside an abandoned or refused intent. Twins `-owed-unannounced`, `-no-finding`, `-no-false-closing-alert`. Probes `-unpaired`, `-false-closing`, `-escalated` |
| Invariant 4.3 — two invocation-written outcomes never name one entry | YES | **covered** (invocation, sweep); **detected** (operator) | `Invariant_4_3`: two outcomes for one entry are never both the invocation's or the sweep's. An operator's second outcome is reachable (`-probe-operator-duplicate`) and the rebuild's binding-duplicate finding opens for it: `Duplicate_detected`. Twins `-payload-pairing`, `-equal-now`, `-no-duplicate-finding` |
| Invariant 4.4 — every invocation-written outcome names an entry the chain carries | YES | **covered** (invocation, sweep); **detected** (operator, outside the claim) | `Recovered_names_entry`. The operator's outcome names an entry of the operator's choosing; Check 5.2 finds a wrong one. Twin `-unanswered-committed` (a refused probe read mapped to committed) |
| Invariant 5.1 — [Verify Custody] answers continuity, attestation, seal and retention for every entry | no | out-of-scope | a query's shape, discharged in prose and Generation acceptance; Provenance Invariant 4 owns continuity |
| Invariant 7.2 — a validated transfer authenticates the outgoing custodian | YES | **covered** | `Transfer_holder_rechecked`: a transferred entry an invocation wrote carries its intent's attested custodian as its outgoing custodian, kept by the transfer transaction's re-check. Twin `-stale-holder` (no re-check: a transfer resolved before another's commit or the outside write lands from the new holder). Probe `-holder-changed` (the stale transfer refused, its refusal recorded) |
| Wiring decision 1 — deleted (Final Critique 18) | no | **covered** | Invariant 1.1 and 4.3 own it: the outcome a settled carried entry is owed, and no second invocation-written one |
| Wiring decision 3 through 6 — the attester of each action | no | **covered** | the intent's actor (`icu`): the genesis custodian, the resolved holder, the caller's custodian under Provenance's holder guard; `Inv1_Attributed`, `Transfer_holder_rechecked` |
| Action wiring 12, 13, 20, 21, 27, 28 — the open before the commit | no | **covered** | `Inv7_AuthPrecedence` (an entry an invocation wrote follows its intent; Recoverable Invocation Invariant 1.1, which this page's acts rest on). Twin `-unauthenticated` |
| Action wiring 16 through 19 — the resolution read ahead of the open | no | **covered** | the `Resolve` step; `Transfer_holder_rechecked` |
| Action wiring 8, 9, 63 to 65 — a pre-commit arm refused with its refusal record, nothing written | no | **covered** | the `pre` arm; `Owed_outcome`. Probe `-holder-changed`. The archived arm of Action wiring 64 is not reached (Not modelled) |
| Action wiring 15, 26, 66 — the close after a committed arm | no | **covered** | `Close`; `Owed_outcome`, `Recovered_names_entry` |
| Action wiring 67, 68 — an unknown arm yields; a failed close answers recording-failure(outcome) | no | **covered** | the unknown arms and `Close("fail")` leave the intent open for the sweep; `Owed_outcome`. Twin `-owed-unannounced` |
| Cross-record consistency 1 — a committed write whose close never landed stands beside an open intent, closed by the sweep | no | **covered** | `Owed_outcome`. Probe `-recovered`. *Within the closure window* is Recoverable Invocation's (the clock) |
| Term step probe, Term originate probe; Capability requirement 34, 35 — the probes pair on the injected now, never equal for two invocations of one act key | YES | **covered** | `Pairing_unique`: the sweep answers committed only for the intent whose own commit wrote the entry. Twins `-payload-pairing` (no datum: the retired Term realize), `-equal-now` (Capability requirement 35 dropped). Probe `-recovered` |
| Term originate probe; Recoverable Invocation Deviation 4c — no lookup, no recovered origination | YES | **covered** | `Genesis_needs_lookup`. Twin `-genesis`. Probes `-genesis` (recovered through the lookup), `-escalated` |
| Reconciliation 7, 11 — an entry no intent carries opens a write-ownership finding | no | **covered** | `Write_ownership_finding`: every entry the outside write made has a finding, and no other entry does. Twins `-no-finding` (the act key alone, no datum), `-finding-for-carried` (only intents an outcome closed read as carrying). Probe `-unpaired` |
| Reconciliation 32 — a false closing is alerted | no | **covered** | `False_closing_alert`: the leg alerts exactly the entries whose own intent an abandonment or a refusal closed. Twin `-no-false-closing-alert`. Probe `-false-closing` (an operator abandons an intent whose write landed) |
| Reconciliation 2, 4, 30, 31, 33, 34 — the leg's cadence, edges, answered read, run reading, enumeration instant | no | out-of-scope | the clock (Not modelled); a read that fails decides nothing and is no step |
| Composition state 9 — the rebuild opens a binding-duplicate finding | no | **covered** | `Duplicate_detected`. Twin `-no-duplicate-finding`. Probe `-operator-duplicate` |
| Check 5.9 — an orphan entry resolves to one class | no | **covered**, partly | open, escalated, false closing and write-ownership finding are each a state here (`Owed_outcome`, `False_closing_alert`, `Write_ownership_finding`); young and aged are the clock's |
| Composes 1 through 16; Composition state 1 through 8, 10, 11, 13 through 15; Capability requirement 1 through 7, 15, 22 through 26, 28, 33, 36 through 39; Primitive policy 1 through 16; Audit arm 29; Action wiring 5, 11, 14, 33 through 62; Verdict 1 through 19 | no | out-of-scope | wiring, the records' fields, deployment configuration, the Recoverable Invocation instance's settings, input validation before any write, and [Verify Custody] with its verdict (a read over the records, not an interleaving) |
| Check 1.1 through 7.3 other than the rows above; External check 1 through 6 | no | out-of-scope | the auditor's reads of the records and external evidence; the model checks the state they read |
| Non-goal 1 through 13; Clock semantics 1, 2; Retention asymmetry 1; Pre-genesis custody 1; Rename 1 | no | out-of-scope | non-goals bound the claim; Non-goal 12 (open, commit and close are not atomic) is the model's shape |

**Inherited: the rows that left.** The page tombstoned these rules, so the matrix carries no row for them. Each is owned by Recoverable Invocation, and recoverable-invocation.tla or its coverage carries it:

| Former row (former twin) | Owner now |
|---|---|
| Invariant 1.3; Check 1.4, 1.5 — the recovery flag and the recovery identity (`-buggy-unflagged`) | Recoverable Invocation Invariant 5.1, 5.2, which recoverable-invocation.tla v8 checks (`Inv9_RecoveryIntentFirst`, `Inv10_RecoveryFlagged`; twins `-buggy-recoveryintent`, `-buggy-recoveryflag`) |
| Invariant 1.4; Check 6.1 — every outcome names its intent | Recoverable Invocation Invariant 3.1, Check 1.1, Primitive policy 11a |
| Invariant 4.2; Check 5.6, 5.7, 5.8 — closure within the window, the liveness sum, the escalation reach | Recoverable Invocation Invariant 4.2, Check 3.1, Check 4.1, Instance start 4, 5. The owed row of `owed-2026-11-10.md` (Invariant 4.2's eventuality) closes here as inherited: Recoverable Invocation Invariant 4 and its window conditions |
| Invariant 4.5 — every uncompensable orphan escalated | Recoverable Invocation reconcile step 3.5, 3.8; this page's Reconciliation 11 for an entry no intent carries |
| Invariant 7.1 — authentication before the Provenance write | Recoverable Invocation Invariant 1.1; this page keeps `Inv7_AuthPrecedence` for its own Action wiring 12 through 28 |
| Reconciliation 4 — no write for an aged intent (`-buggy-aged`, `-probe-aged`) | Recoverable Invocation Invariant 7.2. **Owed there**: its model does not check the horizon edge; recorded in its coverage |
| Reconciliation 14, 15 — over the cap, escalate and never compensate (`-buggy-uncapped`, `-probe-overcap`) | Recoverable Invocation Invariant 3.5a, reconcile step 3.8 through 3.10. **Owed there**: its model does not check the candidates; recorded in its coverage |
| Reconciliation 25, 26 — the re-read in one transaction with the write (`-buggy-staleread`) | Recoverable Invocation reconcile step 2.4 through 2.6, Invariant 2 (its `-buggy-reread`) |
| Reconciliation 10, 16 — the pairing by Term realize (`-buggy-transferpair`) | Recoverable Invocation Invariant 3.3, pairing datum 2, 6a; this page's probes, checked by `Pairing_unique` (`-buggy-payload-pairing`) |
| Reconciliation 21 through 24 — the recovery intent, the identity, the flag, the re-derivation | Recoverable Invocation Invariant 5.1 through 5.3, reconcile step 3.2a, act probe 6 |
| Audit arm 19, 24, 26 — the orphan surfaced in the answer, the deployment fault (`-buggy`, `-probe-fault`) | Recoverable Invocation commit 8d, Invariant 8.4, Primitive policy 42 |

## Twin × check matrix

Each twin was run against each check it exists for, alone (a one-entry .cfg), 14 runs, and every one is `CAUGHT`. Every check but `TypeOK` rejects at least one twin on its own. The full product of 11 twins and 13 checks was not run.

| Twin | Check(s) it breaks alone (states at the violation) |
|---|---|
| `-unauthenticated` | `Inv7_AuthPrecedence` (636) |
| `-owed-unannounced` | `Owed_outcome` (10) |
| `-stale-holder` | `Transfer_holder_rechecked` (2,815), `Inv1_Attributed` (10,695) |
| `-payload-pairing` | `Pairing_unique` (6,565), `Invariant_4_3` (6,565) |
| `-equal-now` | `Pairing_unique` (18,812), `Invariant_4_3` (18,812) |
| `-no-finding` | `Write_ownership_finding` (2,816) |
| `-finding-for-carried` | `Write_ownership_finding` (34) |
| `-no-false-closing-alert` | `False_closing_alert` (192) |
| `-genesis` | `Genesis_needs_lookup` (37) |
| `-no-duplicate-finding` | `Duplicate_detected` (9,366) |
| `-unanswered-committed` | `Recovered_names_entry` (38) |

## Readings (named, not counterexamples)

1. **The operator's closing.** The invocation resolve checks neither an operator's outcome nor its entry against Provenance (Recoverable Invocation resolve 28, 31). So Invariant 4.3 and 4.4 claim only the invocation-written outcome events, and an operator's closing is detected, not prevented, as the page's Invariant 4 NOTE says: the binding-duplicate finding, Check 5.1 and Check 5.2 find it.
2. **What takes nothing from outside.** No ASSUME, CONSTRAINT or ACTION_CONSTRAINT: the one thing the page takes from outside, the host's fresh now per act key (Capability requirement 35), is the `Nows` the open draws from, and `-equal-now` drops it.
3. **Distinct nows.** The model's clock gives every invocation and the outside write a distinct now. Capability requirement 35 asks this only per act key, so two act keys sharing a now are not explored; the leg pairs on the key and the datum, and the genesis entry's key without its artifact reference is open line 2026-11-10-b.
4. **One chain.** A second origination of the one artifact finds no chain id and only yields, so the originate probe's several-chains arm (undecidable) is not reached.

## Step 3 — bound saturation

Each run explores the state space exhaustively under TLC and holds; the .cfg records them.
- `NC = 1, NCu = 2, N = 3, MaxDirect = 1` → 478,490 states. This is the canonical run.
- `N = 2` → 4,866 states.
- `NCu = 3` → 3,355,208 states, with no new violation.
- `MaxDirect = 2` → 2,151,338 states, with no new violation.
- `N = 4` → not exhaustive: the run stopped at the 25-minute cap after 31,145,765 states, with no violation found.

Why these sizes: `N = 3` is the fewest invocations that reach a transfer resolved before another's commit beside an origination, and a retried act of one key (the `-equal-now` and `-payload-pairing` twins need it).

**saturated** ✓ within the audit's reach. This is not a claim that `N = 3` is enough.

## Outcome

- GAP rows: none on the page's live rules. No by-construction row is load-bearing.
- Inherited: Recoverable Invocation Invariant 5.1, 5.2 (formerly this page's Invariant 1.3) are checked by recoverable-invocation.tla v8. Recoverable Invocation Invariant 7.2 and 3.5a (formerly this page's Reconciliation 4 and 14, 15) are owed in its coverage, not paid in this unit.
- Result: clean — *Coverage cross-check 2026-11-10 — clean (all load-bearing invariants covered on the invocation and the sweep; the operator's closing detected, not prevented; saturation confirmed within the audit's reach).*

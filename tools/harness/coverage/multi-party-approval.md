# Coverage matrix — `multi-party-approval`

> Formal-layer **coverage cross-check** (the section titled *The coverage cross-check* in pressure-testing.md).
> First emitted 2026-10-26 with the page's first model; rewritten whole 2026-11-10 with the model's re-derivation for the page's composition of Recoverable Invocation.

- **Pattern:** `compositions/multi-party-approval.md`
- **Model:** one model, `multi-party-approval.tla`, re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 13 through 17, Term chain bindings). Each state-changing action is an open, a commit and a close (three commits, not one transaction: Non-goal 15); the commit is the initiation transaction, the decision transaction or the withdrawal transaction, inside which every write commits together and every refusal writes nothing (Action wiring 9, 12, 22, 23, 65, 67; Cascade 14). An act whose outcome never landed is closed by Recoverable Invocation's sweep or an operator's resolve, both modelled as contracts. The model adds a step decided out of band, the write-ownership leg (Reconciliation 20, 50) and the chain rebuild's alerts (Composition state 22, 23). With it, **17 buggy twins** `multi-party-approval-buggy-<name>.tla`: `split`, `unstaffed`, `norecall`, `oob`, `close-skipped`, `close-on-refused`, `unanswered-committed`, `stale-trailing`, `withdraw-terminal`, `partial-cascade`, `terminal-data`, `no-terminal-alert`, `no-shape-alert`, `equal-now`, `no-finding`, `finding-for-carried`, `no-false-closing-alert`; and **8 reachability probes** `multi-party-approval-probe-<name>.tla`: `initiation-recovered`, `terminating-recovered`, `escalated`, `temporal-refused`, `false-closing`, `trailing`, `approved`, `outofband`.
- **What retired.** The 2026-10-26 model read each action as one transaction with the initiation recovery (dispositions a and c, the quarantine), the sweep's retry of a call a partial flag named, and the initiation leg, and checked `NoStuck` beside the quorum's invariants. Under Recoverable Invocation those rules are tombstoned (Reconciliation 8 through 43 but 20 and 39, Cascade 9, Invariant 1.2, 8.2), so:
  - `-buggy-closure` (SupersedeAny) and `-buggy-shortshape` (ShortRecovered) retire with the closure mark and the initiation recovery they broke; `NoStuck` retires with Reconciliation 26 and 30 and Check 5.4, and moves onto nothing.
  - `-buggy-steplist` (N read as the step list's count) retires: a refused submit or assign now fails the initiation transaction whole (Action wiring 9, 12), so no chain stands with a short step list for the count to differ on; `Inv1_1` keeps `-buggy-split` (re-pointed: a refused submit that keeps the steps before it).
  - `-buggy-trailing` (a trailing decision counted) retires: a Withdrawn chain carries no Pending step once the cascade's temporal refusal fails the commit (Cascade 14), and the met and lost vectors are closed under further decisions, so no reachable trailing decision moves the quorum's answer; Wiring decision 6's exclusion of it stays, and `-probe-trailing` shows trailing decisions are reached. Its role passes to `-buggy-stale-trailing`, against the re-read that keeps a decision opened as not trailing from committing on a terminal chain (Action wiring 64, 65).
  - Probes `-probe-residue`, `-probe-recoveryclosed` and `-probe-shortterminal` retire with the partial flag and the initiation recovery; `-probe-superseded` retires because the model's cascade withdraws the steps Approval Step holds Pending and never meets not-pending (the reading open line 2026-11-06-c carries).
  - `-buggy-split`, `-buggy-unstaffed`, `-buggy-norecall` and `-buggy-oob` are kept, rewritten as defects of the new module (each the model with one rule's text changed, as the Capability-Backed Sharing twins are), and `-probe-trailing`, `-probe-approved` and `-probe-outofband` are kept.
- **Open line 2026-08-29-u closes.** It said the model wrote no audit record, so no check reached the sweep's recovery intent before its closure (Reconciliation 28, 29). Those rules are Recoverable Invocation's now (Invariant 5.1, reconcile step 3.2a), which recoverable-invocation.tla checks (`Inv9_RecoveryIntentFirst`); this model writes the outcomes and checks what they name.
- **Reviewer / date:** the model's author, the session that re-derived it — 2026-11-10. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** quorum determinism split by terminal path (Invariant 2), bypass resistance, chain completeness (Invariant 1.1), assignment coverage at quiescence (Invariant 4), terminal absorption (Invariant 7.1); and, new with the split arc, the owed outcome (Invariant 5.1), what the probes and the close write (Composition state 6, 7), the trailing re-read (Action wiring 64, 65), the cascade's whole-or-nothing commit (Cascade 14), the pairing datum (Capability requirement 37, 38), the write-ownership leg (Reconciliation 20, 50) and the rebuild's alerts (Composition state 22, 23). Only this page can check these: Recoverable Invocation's model does not model an adopter's probe or its database.
- **Layering:** no model imports another. Approval Step enters as its contract — a step decides once, from Pending, by its approver or its submitter, stamping the injected now (its Invariant 3, 4, 5, proved in `atoms/approval-step.tla`); Assignment as recall answering ok on an Active assignment and not-active on a Recalled one (`atoms/assignment.tla`); Recoverable Invocation as its open, close, refuse, yield, sweep and resolve contracts (`compositions/recoverable-invocation.tla`).

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/multi-party-approval.tla` → `HOLDS` ✓ *(926,652 states, exhaustive under TLC; about 30 seconds at eight workers, about three minutes at four under load)*
- Buggy twins and probes: each `node check.mjs ../../compositions/multi-party-approval-<name>.tla --buggy` → `CAUGHT` ✓ *(25 files; the twin × check table names the check that finds each)*

## Step 2 — coverage matrix

**The model in brief.**
- **The chain.** One chain of three approver slots under a quorum rule the initial state chooses: [All Of N], or [M Of N] with M = 1 or 2 ([One Of N] is M = 1; M = 3 reads as [All Of N]). The chain record carries its state, its initiated instant, and its terminal summary: the terminal instant, the path, the cascade-withdrawn steps and the terminating invocation's id. Each step carries its Approval Step state, how it was decided (routed, cascade or out of band), its decision instant and, as a ghost, the invocation that wrote it; each step its assignment.
- **Bound invocations: three slots,** taken in order: an initiation, a decision (approve, reject or withdraw one Pending step), or a chain withdrawal (on a Pending chain, ahead of its open).
  - Each open takes a fresh now as its pairing datum: an ordinal clock, the host's injection, which the composition stamps on the chain record and Approval Step on the step (Capability requirement 19, 37, 38). A decision's open computes the trailing flag from the chain state.
  - Its status is live, committed, dead (yielded, died or close failed: the intent open for the sweep), closed, refused, escalated or abandoned. `cby` says who wrote the closing; `osum` the terminal state the outcome's terminal summary carries; `osh` whether an initiation outcome's chain shape is the chain record's.
  - The commit answers committed (the transaction's writes together), pre-commit (any refusal inside it, nothing written) or unknown (written or not, as the environment chooses). The decision transaction re-reads the chain state against the intent's trailing flag, and evaluates the quorum and cascades unless trailing; the withdrawal transaction re-reads Pending.
  - One failure among the invocations: a pre-commit refusal, an unknown arm, or a close that does not land.
- **The sweep** runs only on a dead intent. Its probe matches the record of the intent's kind and pairing datum (the chain record by initiated instant, the step by its decision instant and the kind's state, the chain record Withdrawn by a withdrawal at its terminal instant): one match gives a recovered outcome carrying the terminal summary where the chain record names the invocation; none, an escalation.
- **The operator** closes a dead or escalated intent with a faithful or a wrong outcome (a terminal summary the chain record does not carry, a chain shape it does not hold), or abandons it, and supersedes an abandonment with an outcome; nothing checks the outcome (resolve 28, 31).
- **One step decided out of band,** with no intent.
- **The leg** is one step that reads every decided step, the chain record and its terminal against the intents; **the rebuild** is one step that reads the outcomes for the terminal-data and shape alerts. Each answer is compared with what the records hold (the ghosts), as Chain of Custody's and Capability-Backed Sharing's legs are.

| Spec rule (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — a quiescent chain has its full step list | YES | **covered** | `Inv1_1`. Twin `-split` (a refused submit keeps the steps before it: the initiation transaction dropped) |
| Invariant 1.3, 1.4 — step ids name Approval Step records; the step-chain index maps each back | no | out-of-scope | the derived indexes are not modelled; a lost entry is rebuilt before any rule reads it (Composition state 21) |
| Invariant 1.5 — no chainless step of a quiescent chain | no | by-construction | the initiation transaction commits its submits whole or not at all; open line 2026-11-10-c carries the leg's reading of it |
| Invariant 2.1 — a resolution-terminated chain's state is the quorum's answer on its routed vector | YES | **covered** | `Inv2_1`, at every state. Twin `-oob` (the evaluation counts an out-of-band transition) breaks it alone. Held against an operator's closing too: the routed vector reads no outcome (the page's Invariant 2 NOTE) |
| Invariant 2.2 — the quorum answers Pending on a withdrawal-terminated chain's pre-withdrawal vector | YES | **covered** | `Inv2_2`, at every state. Twin `-withdraw-terminal` (the withdrawal transaction skips its Pending re-read and overwrites a terminal) breaks it alone |
| Bypass resistance — no chain Approved without the quorum's routed, non-trailing approvals | YES | **covered** | `Bypass`. Twin `-oob` breaks it alone. Probe `-approved` |
| Invariant 3.1 through 3.3 — permission enforcement | no | out-of-scope | a gate ahead of every open (Action wiring 1, 40, 51), not an interleaving; Permissions is not modelled |
| Invariant 4.1 — at quiescence an open step carries one Active assignment | YES | **covered** | `Inv4_1`. Twin `-unstaffed` |
| Invariant 4.2 — at quiescence a settled step carries none | YES | **covered** | `Inv4_2`, steps decided around the composition aside (Composes 11). Twin `-norecall` (Cascade 1 dropped) |
| Invariant 4.3 — no recall of a Pending step's assignment in a Pending chain | no | by-construction | only a decision recalls its own step's assignment, and a cascade runs on a terminal chain alone |
| Invariant 5.1 — every committed transition on a quiescent chain resolves to its one audit record, an escalation, a false closing or a finding | YES | **covered** (invocation, sweep); **detected** (operator) | `Owed_outcome`: an invocation whose commit wrote stands open or beside a closing, never a refusal. Twin `-close-skipped`. `Outcome_names_record`: every outcome the invocation or the sweep wrote names the record its datum finds; twins `-close-on-refused`, `-unanswered-committed`. Probes `-initiation-recovered`, `-terminating-recovered`, `-escalated` |
| Invariant 5.2, 5.3 — every record names a chain; an orphan attestation alerted | no | out-of-scope | the records' fields and Audit Trail's own reconciliation |
| Invariant 7.1 — a terminal chain's state never changes | YES | **covered** | `Inv7_1`. Twin `-withdraw-terminal` breaks it alone (the 2026-10-26 model had no twin for it: every write was guarded by the chain's Pending inside one transaction, and the withdrawal's re-read is that guard under the split arc) |
| Invariant 7.2 — a terminal chain's terminal instant never changes | no | out-of-scope | the clock |
| Invariant 7.3 — two terminal events carry no one chain id | no | **detected** (operator) | the invocation's close and the sweep's closing are one per intent, and one intent terminates a chain; an operator's second terminal outcome opens the terminal-data alert (`Terminal_alert`) |
| Invariant 8.1 — declared fields immutable | no | by-construction | no action writes a declared field |
| Invariant 9.1 — a chain's lifecycle resolves from its records | no | out-of-scope | [Read Chain] is not modelled |
| Composition state 6, 7; Check 7.1 — the terminating act's outcome carries the chain record's terminal summary | no | **covered** (invocation, sweep); **detected** (operator) | `Terminal_outcome_matches`. Twin `-terminal-data` (the decision probe leaves the summary out). Probe `-terminating-recovered` |
| Composition state 22, 23 — the terminal-data alert and the shape alert | no | **covered** | `Terminal_alert`, `Shape_alert`. Twins `-no-terminal-alert`, `-no-shape-alert` |
| Action wiring 9, 12 — a refused submit or assign fails the initiation transaction whole | no | **covered** | `CommitPre` writes nothing; `Inv1_1`, twin `-split` |
| Action wiring 64, 65 — the decision transaction re-reads the chain state against the trailing flag | no | **covered** | `Trailing_matches`. Twin `-stale-trailing`. Probe `-trailing` |
| Action wiring 66, 67 — the withdrawal transaction re-reads Pending | no | **covered** | `Inv7_1`, `Inv2_2`. Twin `-withdraw-terminal` |
| Cascade 2, Cascade 14 — the cascade withdraws every still-Pending step, a temporal refusal failing the commit | no | **covered** | `No_withdrawn_residue`. Twin `-partial-cascade` (the retired partial-flag reading). Probe `-temporal-refused` |
| Cascade 8, 10, 15 — deterministic and superseded arms named in the terminal summary | no | out-of-scope | the model's cascade withdraws the steps Approval Step holds Pending (open line 2026-11-06-c), and its deterministic arms are conformance faults not modelled |
| Capability requirement 37, 38; Term initiation probe, decision probe, withdrawal probe — the probes pair on the injected now, never equal for two invocations of one act key | YES | **covered** | `Pairing_unique`: a record carries one intent at most, and the sweep closes only the intent whose commit wrote the record. Twin `-equal-now` (Capability requirement 38 dropped) |
| Recoverable Invocation reconcile step 3.5 — an intent with no commit escalated | no | **covered** | `SweepEscalate`. Probe `-escalated` |
| Reconciliation 20 — a step decided out of band opens a write-ownership finding | no | **covered** | `Write_ownership_finding`: every out-of-band step has a finding, and no other step does. Twins `-no-finding` (any intent of the kind naming the step, no datum), `-finding-for-carried` (only intents an outcome closed read as carrying). Probe `-outofband` |
| Reconciliation 48, 49 — a chain record or terminal no intent carries opens a finding | no | out-of-scope | a chain record written outside every invocation breaks the chain's own invariants, which hold over the composition's writes (Composes 12); not modelled |
| Reconciliation 50 — a false closing is alerted | no | **covered** | `False_closing_alert`: the leg alerts exactly the records whose own intent an abandonment or a refusal closed. Twin `-no-false-closing-alert`. Probe `-false-closing` |
| Reconciliation 2, 5, 39, 44 through 47 — the leg's cadence, edges, answered read, run reading, enumeration instant | no | out-of-scope | the clock; a read that fails decides nothing and is no step |
| Composes 1 through 17; Composition state 1 through 4, 8 through 21, 24, 25; Capability requirement 1 through 7, 12, 14, 19 through 27, 36, 39 through 43; Primitive policy 1 through 17; Audit arm 5; Action wiring 1 through 8, 10, 11, 13, 14, 16 through 32, 34 through 38, 40, 41, 44 through 63, 68 through 71; Wiring decision 1 through 9; Scope vocabulary 1, 2; Cascade 1, 3, 7, 11, 12, 13 | no | out-of-scope | wiring, the records' fields, deployment configuration, the Recoverable Invocation instance's settings, input validation ahead of the open, the indexes and [Read Chain]; the quorum, the cascade and the open-commit-close order they state are the model's shape |
| Check 1.1 through 10.2 other than the rows above; External check 1 through 7 | no | out-of-scope | the auditor's reads of the records and external evidence; the model checks the state they read |
| Non-goal 1 through 17; Clock semantics 1 through 3; Retention asymmetry 1 through 2a; Cross-record consistency 1 | no | out-of-scope | non-goals bound the claim; Non-goal 15 (open, commit and close are not atomic) and Cross-record consistency 1 are the model's shape (`Owed_outcome`) |

**Inherited: the rows that left.** The page tombstoned these rules, so the matrix carries no row for them. Each is owned by Recoverable Invocation, and recoverable-invocation.tla or its coverage carries it:

| Former row (former check) | Owner now |
|---|---|
| Invariant 10.1 through 10.3 — authentication precedes commitment (owed a) | Recoverable Invocation Invariant 1.1 (`Inv1_IntentFirst`). The owed row of `owed-2026-11-10.md` closes here as inherited |
| Reconciliation 26, 30; Check 5.4 — every call a partial flag names closes (`NoStuck`) | retired without an owner: Cascade 14 makes the partial flag unreachable |
| Reconciliation 28, 29 — the recovery intent before the closure (open line 2026-08-29-u) | Recoverable Invocation Invariant 5.1, reconcile step 3.2a (`Inv9_RecoveryIntentFirst`) |
| Reconciliation 5, 17, 26, 32 — the sweep's aged edge (owed b) | Recoverable Invocation Invariant 7.2, reconcile step 1.2; the leg's own aged edge (Reconciliation 5) stays out of scope with the clock |
| the compensation window (Capability requirement 8, 11; unmodelled) | Recoverable Invocation Invariant 4.2, Instance start 4 (`Inv4_BoundedClosure`, in its window configurations) |
| Invariant 1.2 — a recovery-closed chain's step list (owed b) | retired without an owner: no initiation recovery closes a chain (Action wiring 9, 12) |
| Invariant 8.2 — the quarantine flag (owed b) | Recoverable Invocation Invariant 4.1: the open initiation intent stands for it |

No check of this page moves onto a rule Recoverable Invocation's model leaves unchecked: **Recoverable Invocation owes nothing in this unit.**

## Twin × check matrix

Each twin was run against the check it exists for, alone (a one-entry .cfg), 19 runs, and every one is `CAUGHT`. Every check but `TypeOK` rejects at least one twin on its own. The full product of 17 twins and 18 checks was not run.

| Twin | Check it breaks alone (states at the violation) |
|---|---|
| `-split` | `Inv1_1` (18) |
| `-oob` | `Inv2_1` (2,168), `Bypass` (2,798) |
| `-withdraw-terminal` | `Inv2_2` (22,549), `Inv7_1` (24,649) |
| `-unstaffed` | `Inv4_1` (51) |
| `-norecall` | `Inv4_2` (24,692) |
| `-partial-cascade` | `No_withdrawn_residue` (825) |
| `-stale-trailing` | `Trailing_matches` (23,091) |
| `-close-skipped` | `Owed_outcome` (54) |
| `-close-on-refused` | `Outcome_names_record` (131) |
| `-unanswered-committed` | `Outcome_names_record` (156) |
| `-terminal-data` | `Terminal_outcome_matches` (3,004) |
| `-no-terminal-alert` | `Terminal_alert` (25,275) |
| `-no-shape-alert` | `Shape_alert` (646) |
| `-equal-now` | `Pairing_unique` (2,878) |
| `-no-finding` | `Write_ownership_finding` (2,907) |
| `-finding-for-carried` | `Write_ownership_finding` (2,595) |
| `-no-false-closing-alert` | `False_closing_alert` (943) |

## Readings (named, not counterexamples)

1. **The operator's closing.** The invocation resolve checks neither an operator's outcome nor its data against the chain records or Approval Step (Recoverable Invocation resolve 28, 31). So Invariant 5.1, 7.3 and Check 7.1, 8.1 are detected for an operator's closing, not prevented, as the page's Invariant 5 NOTE says: the terminal-data and shape alerts and the false-closing alert find it. Invariant 2.1, 2.2 and bypass resistance are not affected: the routed vector reads Approval Step's records, the decision intents and the chain record, never an outcome.
2. **What takes nothing from outside.** No ASSUME, CONSTRAINT or ACTION_CONSTRAINT: the one thing the page takes from outside, the host's fresh now per act key (Capability requirement 38), is the `Nows` the open draws from, and `-equal-now` drops it.
3. **Distinct nows.** The model's clock gives every invocation and the out-of-band write a distinct now. Capability requirement 38 asks this only per act key, so two act keys sharing a now are not explored; the probes pair on the key, the kind's state and the datum, and an out-of-band write at an intent's exact datum would be read as the act — a reading the page shares with every adopter that pairs on a seam-injected now.
4. **A trailing decision cannot move the quorum.** With no Pending step left on a Withdrawn chain, and the met and lost vectors closed under further decisions, no reachable trailing decision changes the quorum's answer; the trailing flag's work is the re-read's (Action wiring 64, 65) and the auditor's reading of a late decision.
5. **One failure.** `MaxFail = 1` reaches every twin's violation; `MaxFail = 2` adds no new violation (Step 3).

## Step 3 — bound saturation

Each run explores the state space exhaustively under TLC and holds, but where it says otherwise.
- `N = 3, NI = 3, MaxOob = 1, MaxFail = 1` → 926,652 states. This is the canonical run.
- `N = 2, NI = 3` → 138,548 states. An [All Of N] chain reaches Approved inside this bound.
- `N = 2, NI = 4` → 1,805,456 states, with no new violation (about 7 minutes at three workers, under load).
- `MaxFail = 2` → 3,853,011 states, with no new violation (about 11 minutes at three workers, under load).
- `MaxOob = 2` → 5,537,874 states, with no new violation (about 12.5 minutes at three workers, under load).

Why these sizes: `NI = 3` is the initiation and two more acts, the fewest that reach a decision opened as not trailing on a chain another decision then terminates (`-stale-trailing`), a withdrawal racing a terminating decision (`-withdraw-terminal`), and an act retried on one key after an abandonment (`-equal-now`). `NI = 4` at `N = 3` (an [All Of N] chain Approved through three routed approvals) did not finish inside nine minutes at eight workers: more than 9.3 million states with 5.4 million left on its queue, past the audit's fifteen-minute limit; `N = 2, NI = 4` stands in for it.

**saturated** ✓ within the audit's reach. This is not a claim that `NI = 4` is enough.

## Outcome

- GAP rows: none on the page's live rules. No by-construction row is load-bearing.
- Inherited: Invariant 10.1 through 10.3 and the closure window are Recoverable Invocation's (Invariant 1.1, 4.2), which recoverable-invocation.tla checks; open line 2026-08-29-u closes onto Recoverable Invocation Invariant 5.1.
- Owed: **(b)** Invariant 1.3, 1.4 (the derived indexes), 1.5, 3.1 through 3.3 (Permissions), 4.3, 5.2, 5.3, 7.2 (the clock) and 8.1: Alloy, the static data model, or a model with a clock. **(c)** Invariant 9.1 (a read) stays with its reason.
- Result: clean — *Coverage cross-check 2026-11-10 — clean (all load-bearing invariants covered on the invocation and the sweep; the operator's closing detected, not prevented, where the page says so; saturation confirmed within the audit's reach).*

# Coverage matrix — `customer-onboarding`

- **Pattern:** `compositions/customer-onboarding.md`
- **Model:** one model, `customer-onboarding.tla`, re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 27 through 31, Term onboarding bindings). Each acting action is an open, a commit and a close (three commits, not one transaction: Non-goal 22), and an act whose outcome never landed is closed by Recoverable Invocation's sweep or an operator's resolve, both modelled as contracts. The model follows the three kinds the open-trigger set rests on — the adverse trigger (the suspension transaction, with its re-run pre-check), the clearance (verify and reinstate in one transaction, with its re-read of the open triggers and of the adverse trigger intents carrying no closing) and the closure (with its re-read) — over one party verified under an active case, and adds a state change written on Party Identity outside every invocation and the reconciliation's write-ownership finding and false-closing alert (Reconciliation 37 through 39). With it, **10 buggy twins** `customer-onboarding-buggy.tla` and `customer-onboarding-buggy-<name>.tla`: `voided-kept`, `onsuspended-dropped`, `escalated-dropped`, `clear-stale`, `clear-inflight`, `close-stale`, `equal-now`, `no-finding`, `no-false-closing-alert`; and **7 reachability probes** `customer-onboarding-probe-<name>.tla`: `suspend-recovered`, `escalated`, `clear-refused`, `onsuspended`, `triggers-changed`, `false-closing`, `finding`.
- **What retired.** The model of 2026-06 was a counter: `RaiseTrigger` set the trigger count and the suspended state in one step, `ResolveTrigger` reinstated on the last clear, so `Inv_OpenTriggerIffSuspended` held by construction, and the recovery was never in it. The split arc, the rebuild of the open-trigger set from intents and closings, and the re-reads are the page's now.
  - Twin `-buggy` (a suspend with no trigger) is re-pointed: the suspension transaction commits and the action closes it through the refuse, so the rebuild drops the trigger the suspension rests on (Invariant 7.2; `Inv_OpenTriggerIffSuspended`, `Rebuild_faithful`, `Owed_outcome`).
  - Invariant 3.1's order, by construction in the old model, moves onto Recoverable Invocation Invariant 1.1 and Check 1.1 (`Inv1_IntentFirst` in recoverable-invocation.tla): the trigger record is the suspension's own intent. No check of this page moves onto a rule Recoverable Invocation's model leaves unchecked.
- **Reviewer / date:** the model's author, the session that re-derived it — 2026-11-10. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes for the adverse-monitoring coupling (Invariant 7.1, 7.2, and the order of 3.1). What the page now stands on:
  - the coupling at the restated quiescence (Term quiescent case), over a trigger set rebuilt from the trigger intents and their closings (Composition state 31 through 34);
  - the collisions the split exposes, refused inside the commits (Action wiring 162 through 167) — among them one the map did not name and this model found: an adverse trigger whose intent a clearance named and whose suspend committed after the clearance re-suspended a reinstated party with no open trigger left, cured by the clearance's re-read of the adverse trigger intents carrying no closing (Action wiring 164, 165);
  - the probes' pairing datum (Capability requirement 48, 49), the write-ownership finding and the false-closing alert.

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/customer-onboarding.tla` → `HOLDS` ✓ *(64,020 states, about 6 seconds under TLC)*
- Buggy twins and probes: each `node check.mjs ../../compositions/customer-onboarding-<name>.tla --buggy` → `CAUGHT` ✓ *(17 files; `node audit.mjs --only compositions/customer-onboarding` → 18 models: 1 HOLDS, 17 CAUGHT, 0 problems)*

## Step 2 — coverage matrix

**The model in brief.**
- **The party.** One party, verified under an active case at the start. Party Identity's state (verified, suspended, closed) and its state change events, each carrying the instant Party Identity stamped (the injected now), the new state and, as a ghost, the invocation that wrote it (0: a write outside every invocation).
- **Bound invocations: three slots,** taken in order, each an adverse trigger (taking the next of two trigger ids), a clearance or a closure. Each open takes a fresh now as its pairing datum. One live, committed or dead intent per kind (the act section; one party, so one act key).
  - An adverse trigger opens on an active case whatever the party's state (the validation ahead of the open is stale by construction), and its suspension transaction re-runs the pre-check: verified → suspend; suspended → refused already-suspended; closed → refused not-verified.
  - A clearance opens on a non-empty open-trigger set, naming it; its transaction re-reads the set and the adverse trigger intents carrying no closing — refused triggers-changed on a difference — then verifies and reinstates together, or is refused verification-failed where the party is not suspended.
  - A closure opens on an active case, naming the open-trigger set; its transaction re-reads it — refused triggers-changed — then closes, or is refused not-active on a closed party.
  - Every commit may also answer unknown, written or not, as the environment chooses; the close may fail.
- **The rebuild.** The open-trigger set is the adverse trigger intents minus those abandoned or refused with a code other than already-suspended, minus those a closed clearance or closure intent names. A ghost `gt` holds the triggers under investigation as the facts stand: entered at the intent, left at a not-verified refusal, an abandonment of a suspend that never committed, or a committed clearance or closure that named it.
- **The sweep** runs only on a dead intent. Its probe matches the state changes at the intent's pairing datum carrying the kind's new state: one match gives a recovered outcome naming it; none or several, an escalation.
- **The operator** closes a dead or escalated intent with an outcome, or abandons it.
- **One write outside any invocation:** a suspend or a reinstate on Party Identity, with no intent.
- **The reconciliation** is one step that reads every state change against the intents; each answer is compared with the ghosts, as Chain of Custody's and Capability-Backed Sharing's legs are.

| Spec rule (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1 — `Activity Permitted` answers permitted only if the index names the party and Party Identity reports verified | yes | out-of-scope (named reason) | No gate in the model; the gate reads the index and Party Identity and never an outcome, so composing did not move it. Owed (b). |
| Invariant 1.2, 1.3 — the converse; no path around the gate | yes | out-of-scope (named reason) | The same. Owed (b). |
| Invariant 2.1 — a transitioning verification carries exactly one of its outcome, an open or escalated carrying intent, a false-closing alert, a write-ownership finding | yes | out-of-scope (named reason) | No verification kind in the model. The shape is the one `Write_ownership_finding` and `False_closing_alert` check for a state change; owed (b) for the verification event. |
| Invariant 2.2 — a verification outcome under a seal | no | out-of-scope (named reason) | Audit Trail's seal cadence (a). |
| Invariant 2.3 — a quiescent verified party carries a verification outcome | yes | out-of-scope (named reason) | No verification kind. Owed (b). |
| Invariant 3.1 — a suspension outcome stands later in the log than its adverse trigger intent | yes | **inherited** | Recoverable Invocation Invariant 1.1, Check 1.1 (`Inv1_IntentFirst`): every outcome follows its intent, a recovered or an operator's included. The model's commit runs only on a live intent. |
| Invariant 3.2 — a refusal record carrying already-suspended stands later than its intent | no | **inherited** | Recoverable Invocation's refuse writes after the open (Invariant 1.1). Probe `-onsuspended` reaches the refusal. |
| Invariant 3.3, 3.4 — later in the log is insertion order, never a timestamp | no | out-of-scope (named reason) | Reading rules (c). |
| Invariant 4.1 — a reinstated party carries a passed verification later than the most recent suspension | yes | out-of-scope (named reason) | Party Identity Operation 18 (`party-identity.tla`, a); the clearance transaction's verify and reinstate commit together here, the verify rolled back with a refused reinstate (probe `-clear-refused`). |
| Invariant 4.2, 4.3 — a reinstated party carries a clearance outcome naming the verification id; the clearing actor attests the clearance intent | yes | out-of-scope (named reason) | No ids, no actors. Owed (b). |
| Invariant 4.4 — no claim the verifying actor stands authenticated | no | out-of-scope (named reason) | A rule about what is claimed (c). |
| Invariant 5.1 through 5.6 — the placements | yes (5.1–5.4, 5.6) | out-of-scope (named reason) | No Retention Window in the model. Owed (b); 5.5 (c). |
| Invariant 6.1, 6.2 — the monitoring entry and its next review due | yes (6.1) | out-of-scope (named reason) | No schedule. Owed (b); 6.2 to Alloy. |
| Invariant 7.1 — a quiescent active case carries a non-empty open-trigger set only if the party is suspended | YES | **covered** (invocation, sweep); **detected** (operator, outside write) | `Inv_OpenTriggerIffSuspended`. Twins `-clear-stale` (no re-read: a trigger landed since stays open over a reinstated party), `-buggy`. An operator's closing or an outside write that breaks it is read apart and alerted (Reconciliation 38, 39, 43; the 43 alert reads state the model holds directly, not modelled). |
| Invariant 7.2 — a quiescent suspended party under an active case carries a non-empty open-trigger set | YES | **covered** (invocation, sweep); **detected** (operator, outside write) | `Inv_OpenTriggerIffSuspended`, the other direction — now with twins of its own: `-buggy` (a committed suspend refused, its trigger dropped) and `-clear-inflight` (the clearance sweeps a trigger whose suspend commits after it). Probe `-suspend-recovered`. |
| Invariant 7.4, 7.5 — a quiescent closed case carries no open trigger; the closure intent names every trigger swept | YES | **covered** | `Closed_case_empty`. Twin `-close-stale` (no re-read). Probe `-triggers-changed` reaches the refusal at the clearance |
| Invariant 8.2 through 8.7 — one credential per action; what a validation does not establish | no | out-of-scope (named reason) | (c). |
| Composition state 31 through 34 — the open-trigger set's rebuild from the adverse trigger intents and their closings | YES | **covered** | `Rebuild_faithful`: the rebuilt set always holds every trigger under investigation and, at quiescence, no other. Twins `-voided-kept` (a not-verified refusal kept), `-onsuspended-dropped` (an already-suspended refusal dropped: the direction the 2026-11-10 matrix said no twin broke), `-escalated-dropped` (an escalated trigger dropped before the operator settles it), `-buggy`. Probe `-onsuspended` |
| Action wiring 162, 163 — the suspension transaction's re-run pre-check | no | **covered** | `AdvRefuseNv`: an adverse trigger whose intent landed before a closure committed is refused not-verified and drops; `Rebuild_faithful`, `Closed_case_empty` |
| Action wiring 164, 165 — the clearance's re-read of the open triggers and of the adverse trigger intents carrying no closing | YES | **covered** | `Clear_names_current`: a committed clearance names exactly the triggers under investigation at its commit. Twins `-clear-stale`, `-clear-inflight` (the second breaks `Inv_OpenTriggerIffSuspended`). Probe `-triggers-changed` |
| Action wiring 166, 167 — the closure's re-read | YES | **covered** | `Closed_case_empty`. Twin `-close-stale` |
| Action wiring 96 through 100, 155 — a refused reinstate rolls the verify back, refused | no | **covered** | `ClrRefuseVf`. Probe `-clear-refused` |
| Action wiring 155, 156, 157 — pre-commit to the refuse, unknown to the yield, the codes | no | **covered** | the refusal steps and `CommitLost`; `Owed_outcome` |
| Cross-record consistency 1 — a committed write whose close never landed stands beside an open intent, closed by the sweep | no | **covered** | `Owed_outcome`. Twin `-buggy`. Probe `-suspend-recovered`. *Within the closure window* is Recoverable Invocation's (the clock) |
| Term suspension probe, clearance probe, closure probe; Capability requirement 48, 49 — the probes pair on the injected now, never equal for two invocations of one act key | YES | **covered** | `Pairing_unique`. Twin `-equal-now` (Capability requirement 49 dropped). Probe `-suspend-recovered` |
| Recoverable Invocation reconcile step 3.5 — an intent with no commit escalated | no | **covered** | `SweepEscalate`. Probe `-escalated` |
| Reconciliation 37, 38 — a state change no intent carries opens a write-ownership finding | no | **covered** | `Write_ownership_finding`. Twin `-no-finding` (the kind alone, no datum). Probe `-finding` |
| Reconciliation 39 — a false closing is alerted | no | **covered** | `False_closing_alert`. Twin `-no-false-closing-alert` (an abandonment never alerted). Probe `-false-closing` |
| Reconciliation 2, 5, 22, 23, 25, 34, 35, 36, 40 through 43 — the cadence, the edges, the run reading, the enumeration instant, the lapse and state alerts, the cut-over | no | out-of-scope (named reason) | the clock, Retention Window, and alerts that read state the model holds directly (Not modelled). Owed (b) for 23, 25 and 43 as twins that drop the alert |
| Every other rule of Composes, Composition state, Capability requirement, Primitive policy, Identity, Action wiring, Wiring decision, Check, External check, Non-goal, Atomic writes, Clock semantics, Concurrency | no | out-of-scope (named reason) | wiring, fields, deployment configuration, validation ahead of the open, the other four act kinds, the gate, the auditor's reads and external evidence |

**Inherited: the rows that left.** The page tombstoned these rules, so the matrix carries no row for them. Each is owned by Recoverable Invocation, and recoverable-invocation.tla or its coverage carries it:

| Former row (former check) | Owner now |
|---|---|
| Invariant 2.4 — an owed verification record within the compensation window (owed 2a: a window counter, a twin of a marker open past the window) | Recoverable Invocation Invariant 4.2, Check 3.1, Instance start 4, which recoverable-invocation.tla checks in its window configurations (`Inv4_BoundedClosure`). The 2a row of the Ledger and `owed-2026-11-10.md` closes here as inherited |
| Invariant 7.3 — a verified party carrying a closed trigger inside the clearance window | retired without an owner: the clearance is one transaction, so no clearance window stands (Term clearance transaction) |
| Invariant 8.1 — no constituent write under an unvalidated credential | Recoverable Invocation Invariant 1.1 (`Inv1_IntentFirst`) |
| Reconciliation 3 through 20, 24, 27 through 33 — the page's own reconciliation (the open markers, the commitment window, the recovery intent and outcome, the compensation window, the escalations) | Recoverable Invocation reconcile step 1 through 5, Invariant 3.2 through 3.4, 4.1, 4.2, 4.9, 5.1, 5.2, 9.2; Reconciliation 29's bar reverses into the enrollment probe |
| Audit arm 22, 23 — the recovery marker and the human in the payload | Recoverable Invocation Invariant 5.2 (`Inv10_RecoveryFlagged`) |

## Twin × check matrix

Each twin was run against the check it exists for, alone (a one-entry .cfg), 13 runs, and every one is `CAUGHT`. Every check but `TypeOK` rejects at least one twin on its own. The full product of 10 twins and 9 checks was not run.

| Twin | Check it breaks alone (distinct states at the violation) |
|---|---|
| `-buggy` | `Inv_OpenTriggerIffSuspended` (62), `Rebuild_faithful` (20), `Owed_outcome` (20) |
| `-voided-kept` | `Rebuild_faithful` (2,207) |
| `-onsuspended-dropped` | `Rebuild_faithful` (163) |
| `-escalated-dropped` | `Rebuild_faithful` (151) |
| `-clear-stale` | `Clear_names_current` (1,256), `Inv_OpenTriggerIffSuspended` (10,874) |
| `-clear-inflight` | `Inv_OpenTriggerIffSuspended` (32,622) |
| `-close-stale` | `Closed_case_empty` (1,320) |
| `-equal-now` | `Pairing_unique` (1,881) |
| `-no-finding` | `Write_ownership_finding` (150) |
| `-no-false-closing-alert` | `False_closing_alert` (312) |

## Readings (named, not counterexamples)

1. **The operator's closing.** The invocation resolve checks an operator's outcome against no constituent record (Recoverable Invocation resolve 28, 31). So Invariant 7.1 and 7.2 hold for the invocations and the sweep and are detected for an operator: `Inv_OpenTriggerIffSuspended`, `Rebuild_faithful`, `Clear_names_current` and `Closed_case_empty` read an operator's closing apart, and the page's Reconciliation 23, 39 and 43 alert it.
2. **What the model found.** The first run of the re-derived model broke `Inv_OpenTriggerIffSuspended` in ten steps: a trigger suspends; a second trigger's intent lands; a clearance names both; the clearance commits and reinstates; the second trigger's suspend then commits against the now-verified party; both close. The clearance swept a trigger whose suspend had not yet committed, and the party stood suspended with no open trigger. The map's G8 (c) compared the sets only. The page now refuses the clearance while an adverse trigger intent of the case carries no closing (Action wiring 164, 165), and `-clear-inflight` keeps the cure honest.
3. **What takes nothing from outside.** No ASSUME, CONSTRAINT or ACTION_CONSTRAINT: the host's fresh now per act key (Capability requirement 49) is the `Nows` the open draws from, and `-equal-now` drops it.
4. **One party, one act key.** The critical section is per kind; two adverse triggers serialize, and an adverse trigger, a clearance and a closure interleave between their opens and their commits, which is what the re-reads exist for.

## Step 3 — bound saturation

Each run explores the state space exhaustively under TLC and holds.
- `NT = 2, N = 3, MaxDirect = 1` → 64,020 states. The canonical run (about 6 seconds).
- `NT = 3` → 66,478 states, with no new violation.
- `N = 4` → 1,882,180 states, with no new violation (about 3 minutes).

Why these sizes: `N = 3` is the fewest invocations that reach the in-flight race (two adverse triggers and a clearance) and the equal-now mispairing (an adverse trigger, a clearance, an adverse trigger reusing the first's now).

**saturated** ✓ within the audit's reach. This is not a claim that `N = 4` is enough.

## Outcome

- GAP rows: none on the rules the model reaches. No by-construction row is load-bearing; Invariant 3.1's by-construction order is inherited from Recoverable Invocation Invariant 1.1.
- Inherited: Invariant 2.4, 3.1, 3.2 and 8.1 are Recoverable Invocation's (Invariant 4.2, 1.1), which recoverable-invocation.tla checks; the coverage unit's 2a row for Invariant 2.4 closes as inherited. Invariant 7.3 retired with the clearance window.
- Owed: **(b)** Invariant 1.1 through 1.3, 2.1, 2.3, 4.2, 4.3, 5.1 through 5.4, 5.6, 6.1, the enrollment, admission, verification and periodic review kinds and Reconciliation 23, 25 and 43 as dropped-alert twins. **(a)** Retention arithmetic is Retention Window's; Audit Trail seals are Audit Trail's; Invariant 4.1 is Party Identity's. **(c)** Invariant 3.3, 3.4, 4.4, 5.5, 8.2 through 8.7 stay with their reasons. **Tool owed:** Alloy for the static claims (Invariant 6.2, the placement chain's shape).
- Result: **findings routed** — one English defect found by the model and cured in the unit (Action wiring 164, 165: the in-flight adverse trigger at a clearance).

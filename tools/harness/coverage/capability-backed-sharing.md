# Coverage matrix — `capability-backed-sharing`

- **Pattern:** `compositions/capability-backed-sharing.md`
- **Model:** one model, `capability-backed-sharing.tla`, re-derived 2026-11-10 for the page's composition of Recoverable Invocation (Composes 16 through 20, Term sharing bindings). Each sharing action is an open, a commit and a close (three commits, not one transaction: Non-goal 9), and an act whose outcome never landed is closed by Recoverable Invocation's sweep or an operator's resolve, both modelled as contracts. [Redeem And Disclose]'s validation reads the capability-to-sharing index's rule ahead of the open, and its commit is the disclosure transaction (Capability's redeem and Selective Disclosure's record together). The model adds an allocation, a revocation or a disclosure record written outside every invocation, the write-ownership leg (Reconciliation 31 through 35) and the two rebuilds' alerts (Composition state 17, 18). Extended 2026-11-10 for the ttl cap (Scott's ruling, "cap it"): each authorization carries an effective ttl, supplied or the default, and the substrate stamps its authorization event's recording instant within one clock offset allowance of the reading; [Redeem And Disclose] refuses a spent token ahead of the index (Action wiring 65 through 67). With it, **15 buggy twins** `capability-backed-sharing-buggy-<name>.tla`: `close-skipped`, `close-on-refused`, `unanswered-committed`, `recovered-authorizes`, `redeem-kept`, `equal-now`, `no-finding`, `finding-for-carried`, `no-false-closing-alert`, `no-seal-alert`, `no-duplicate-alert`, `ttl-past-horizon`, `default-past-horizon`, `one-allowance`, `spent-opened`; and **9 reachability probes** `capability-backed-sharing-probe-<name>.tla`: `recovered`, `authorize-recovered`, `revocation-recovered`, `escalated`, `false-closing`, `operator-duplicate`, `finding`, `spent-refused`, `revoked-at-commit`.
- **What retired.** The 2026-08-27 model read [Redeem And Disclose] as one clean commit beside an unsealed partial and its compensating seal (`CommitClean`, `CommitUnsealed`, `RetrySeal`), and checked Invariant 2 alone. The split arc and the sweep are Recoverable Invocation's now.
  - Twin `-buggy` (silence: an unsealed disclosure never surfaced) is re-pointed as `-buggy-close-skipped`: a committed act whose close failed, routed to a refusal, so the open intent the sweep would close is gone (`Owed_outcome`, the restated Invariant 2.3).
  - Twin `-buggy-old-wiring` (the append lands while the transaction aborts: a seal with no committed disclosure) is re-pointed as `-buggy-close-on-refused`: a pre-commit arm routed to the close, so an outcome names a record nothing wrote (`Outcome_names_record`, Invariant 2.1). Under Recoverable Invocation the outcome is outside the commit by design (Recoverable Invocation Non-goal 1), so the old defect's shape no longer exists.
  - `Inv2_IntentPrecedesCommit`, `Inv2_RecoveryDistinguishable` and the closing half of `Inv2_NoUnsurfacedUnsealed` move onto Recoverable Invocation Invariant 1.1, 5.2 and 4.2, which recoverable-invocation.tla checks (`Inv1_IntentFirst`, `Inv10_RecoveryFlagged`, `Inv4_BoundedClosure` in its window configurations). No check of this page moves onto a rule Recoverable Invocation's model leaves unchecked.
- **What changed 2026-11-10 (the ttl cap).** Two checks join: `Lapse_before_aged` (Term ttl cap, Primitive policy 3, Capability requirement 33) and `Index_read_live` (Action wiring 65, 66), with four twins that break them. A redemption of a spent token is now refused ahead of the open, so the old `-probe-spent-refused` (a spent token refused at the commit with a refusal record) became unreachable with a single disclosure key: it is re-pointed at the refusal ahead of the index, and `-probe-revoked-at-commit` keeps Action wiring 26's arm reached (a revocation landing between the read and the redeem). No twin retired.
- **Reviewer / date:** the model's author, the session that re-derived it — 2026-11-10. Not a fresh-context read; the next scheduled rescan owes one.
- **Formal-layer vote load-bearing claims:** the vote was cast yes for Invariant 2 (the disclosure-accountability binding). What the page now stands on:
  - the acts against Capability and Selective Disclosure over the split commit: Invariant 2.1, 2.3, 3.1, 4.2 (the disclosure transaction), Cross-record consistency 1;
  - the allocation half the old model left out: Invariant 3.3 and 3.5 (a recovered authorization authorizes nothing: Composition state 6), Invariant 3.1, and [Revoke Sharing];
  - the probes' pairing datum (Term authorization probe, disclosure probe, revocation probe, Capability requirement 22, 23). Only this page can check these: Recoverable Invocation's model does not model an adopter's probe;
  - the write-ownership leg (Reconciliation 32 through 35) and the rebuilds' alerts (Composition state 17, 18);
  - the ttl cap (Term ttl cap, Primitive policy 3, Capability requirement 33) and the index read for a live token alone (Action wiring 65, 66), which together keep [Redeem And Disclose] off the audit horizon's far side.

## Step 1 — harness re-run (must pass)

- Correct model: `node check.mjs ../../compositions/capability-backed-sharing.tla` → `HOLDS` ✓ *(170,229 states, about 20 seconds under TLC)*
- Buggy twins and probes: each `node check.mjs ../../compositions/capability-backed-sharing-<name>.tla --buggy` → `CAUGHT` ✓ *(24 files; Step 2 and the twin × check table name the check that finds each)*

## Step 2 — coverage matrix

**The model in brief.**
- **Records.** Two capability tokens, minted at an allocation's commit. A capability carries its status (allocated, revoked, redeemed), its allocation instant, its revocation instant, its remaining redemptions (one use each), and, as ghosts, the invocation whose commit allocated it and the one whose commit revoked it (0: a write outside every invocation). A disclosure record carries its disclosure instant and, as ghosts, the token whose use it consumed and the invocation that wrote it. The sharing descriptor, the allocator and the disclosure key's fields are one value.
- **Bound invocations: three slots,** taken in order: an authorization, a redemption or a revocation, or a redemption refused ahead of its open (nothing written): invalid where Capability answers its token spent (redeemed or revoked; the index unread), not-authorized-sharing where the index's rule does not attest a live token.
  - An authorization supplies no ttl (the default, set at the cap), the cap exactly, or a ttl past the audit horizon, which the open's guard refuses (Primitive policy 3); the instance starts only with the default inside the cap (Capability requirement 33). The commit stamps the expiry instant, the allocation instant plus the effective ttl.
  - The close of an authorization lands its event with a recording instant the substrate stamps within one clock offset allowance of the reading then, any of the three values.
  - Each open takes a fresh now as its pairing datum: an ordinal clock, the host's injection, which Capability stamps as the allocation or revocation instant and Selective Disclosure as the disclosure instant (Capability requirement 14, 22, 23).
  - Its status is live, committed, dead (yielded, died or close failed: the intent open for the sweep), closed, refused, escalated or abandoned. `cby` says who wrote the closing; `oe` names the record the outcome names.
  - The commit answers committed, pre-commit (Capability's guard: a redeem answered invalid, a revoke answered already-terminal; or Selective Disclosure's foreclosed refusal, the transaction committing nothing) or unknown (written or not, as the environment chooses).
- **The index's rule.** A token is attested only by an authorization outcome the invocation's own close wrote (Composition state 6): never by one the sweep or an operator wrote. A ghost records whether the token stood allocated when the redemption read the index.
- **The ttl cap.** The audit horizon is 3 and the clock offset allowance 1, in the clock's units, so the cap is 1. The clock is ordinal and nothing lapses in the model; the cap is checked as an inequality on the stamps: an attested capability's expiry instant is no later than its authorization event's recording instant plus the horizon less one allowance, the instant Term aged event reads it aged.
- **The sweep** runs only on a dead intent. Its probe matches the records of the intent's kind and pairing datum: one match gives a recovered outcome naming it; none or several, an escalation.
- **The operator** closes a dead or escalated intent with an outcome naming any record id of the kind, or abandons it, and supersedes an abandonment with an outcome. The outcome is not checked against the constituents (resolve 28, 31).
- **One write outside any invocation:** an allocation, a revocation or a disclosure record, with no intent.
- **The leg** is one step that reads every capability and disclosure record against the intents; **the rebuild** is one step that reads the outcomes for the seal alert and the duplicate-authorization alert. Each answer is compared with what the records hold (the ghosts), as Chain of Custody's leg is.

| Spec rule (no. + name) | Load-bearing (vote)? | Verdict | Model construct / reason |
|---|---|---|---|
| Invariant 1.1, 1.3, 4.1 — the records name the allocator (a claimable disclosure), the addressee, the disclosed scope | no | `owed` out-of-scope | field claims; the descriptor and allocator are one value here. Alloy's (static), owed |
| Invariant 1.2 — no record carries a redeemer identity | no | `unstatable` out-of-scope | a rule about what no record carries; no redeemer exists in the model to record (Capability Invariant 3, by construction) |
| Invariant 1.4 — the allocator-named claim only for a claimable disclosure | no | `owed` out-of-scope | an event aging is the clock's passage, which the model does not explore; that a disclosure is claimable when made is `Lapse_before_aged` with `Index_read_live` |
| Invariant 2.1 — every disclosure event names a disclosure record | YES | `checked` **covered** (invocation, sweep); **detected** (operator) | `Outcome_names_record`. Twins `-close-on-refused` (a pre-commit arm closed), `-unanswered-committed` (a refused probe read mapped to committed). An operator's outcome naming no record opens the seal alert: `Seal_alert`, twin `-no-seal-alert` Broken by `capability-backed-sharing-buggy-close-on-refused.tla` (`Outcome_names_record`), `capability-backed-sharing-buggy-no-seal-alert.tla` (`Seal_alert`). |
| Invariant 2.2 — no disclosure record carries two disclosure events | YES | `checked` **covered** (invocation, sweep); **detected** (operator) | the invocation's close and the sweep's closing are one per intent, and unique pairing gives one intent per record (`Pairing_unique`); an operator's second outcome is reachable (`-probe-operator-duplicate`) and the seal alert opens for it (`Seal_alert`) Broken by `capability-backed-sharing-buggy-equal-now.tla` (`Pairing_unique`), `capability-backed-sharing-buggy-no-seal-alert.tla` (`Seal_alert`). |
| Invariant 2.3 — a committed disclosure whose event has not landed stands as a pending marker and an open intent | YES | `checked` **covered** | `Owed_outcome`: an invocation whose commit wrote stands open or beside a closing, never a refusal. Twin `-close-skipped`. Probe `-recovered` Broken by `capability-backed-sharing-buggy-close-skipped.tla`. |
| Invariant 3.1 — every authorization event names a capability | YES | `checked` **covered** (invocation, sweep); **detected** (operator) | `Outcome_names_record` for the authorization kind (and the revocation kind: the intent's token, revoked) Broken by `capability-backed-sharing-buggy-close-on-refused.tla`. |
| Invariant 3.2 — every entry names exactly one authorization event | YES | `checked` **detected** (operator) | an operator's second authorization outcome for one token opens the duplicate-authorization alert: `Duplicate_detected`, twin `-no-duplicate-alert` Broken by `capability-backed-sharing-buggy-no-duplicate-alert.tla`. |
| Invariant 3.3, 3.5 — a disclosure commits only under an allocator-attested authorization; a recovered one authorizes nothing | YES | `checked` **covered** | `Disclosure_attested`: every disclosure record an invocation wrote is under a token whose authorization outcome the invocation's own close wrote. Twin `-recovered-authorizes` (the index binds a recovered outcome). Probe `-authorize-recovered` (a recovered authorization's token refused not-authorized-sharing) Broken by `capability-backed-sharing-buggy-recovered-authorizes.tla`. |
| Invariant 4.2 — disclosure events naming a token whose authorization event is not aged do not exceed its consumed count | YES | `checked` **covered** | `Consumed_equals_disclosed`: a token's consumed uses equal the disclosure records the invocations wrote under it, so no use is consumed without its record (the disclosure transaction; Action wiring 31, 59). Twin `-redeem-kept` (a Selective Disclosure refusal keeps the redeem: the retired unfulfilled path). No authorization event ages in the model, so the bound the invariant carries (Term aged event, Check 7.3) changes no state it explores Broken by `capability-backed-sharing-buggy-redeem-kept.tla`. |
| Action wiring 2, 23, 40 — the open before the commit | no | `elsewhere` **covered** | the model's commit runs only on a live intent; that the open precedes it is Recoverable Invocation Invariant 1.1's, inherited |
| Action wiring 5, 26, 31, 32, 42, 43, 45 — a pre-commit arm refused with its refusal record, nothing written | no | `checked` **covered** | `CommitPre`, `SdRefuse`; `Owed_outcome`, `Consumed_equals_disclosed`. Probe `-revoked-at-commit` (a redemption that read its token live, refused at the commit after a revocation landed) Broken by `capability-backed-sharing-buggy-close-skipped.tla` (`Owed_outcome`), `capability-backed-sharing-buggy-redeem-kept.tla` (`Consumed_equals_disclosed`). |
| Action wiring 8, 36, 46 — the close after a committed arm | no | `checked` **covered** | `Close`; `Outcome_names_record` Broken by `capability-backed-sharing-buggy-close-on-refused.tla`. |
| Action wiring 18, 22 — an unattested token refused, nothing written | no | `owed` **covered** | `Reject`; probe `-authorize-recovered` No check of this model states it, so no twin can be said to break it (2026-11-10, unit `tooling: every check has a twin that breaks it`): an action's shape and a probe that reaches it. |
| Term ttl cap, Primitive policy 3, Capability requirement 33 — no effective ttl past the cap, so no live token outlives the record of its authorization | YES | `checked` **covered** | `Lapse_before_aged`: every attested capability's expiry instant is no later than its authorization event's aged instant, over every stamp the close can give, the default and a supplied ttl at the cap exactly included. Twins `-ttl-past-horizon` (Primitive policy 3's guard dropped), `-default-past-horizon` (the start check dropped, the default past the horizon), `-one-allowance` (the cap spends the allowance once) Broken by `capability-backed-sharing-buggy-default-past-horizon.tla`. |
| Action wiring 65 through 67 — a spent token refused invalid ahead of the index, nothing written | YES | `checked` **covered** | `RejectSpent`; `Index_read_live`: the redemption reads the index only for a token Capability answers allocated. Twin `-spent-opened` (the index read for a spent token). Probe `-spent-refused` Broken by `capability-backed-sharing-buggy-spent-opened.tla`. |
| Action wiring 60, 61 — an unknown arm yields; a failed close answers recording-failure(outcome) | no | `checked` **covered** | the unknown arms and `Close("fail")` leave the intent open for the sweep; `Owed_outcome`. Twin `-close-skipped` Broken by `capability-backed-sharing-buggy-close-skipped.tla`. |
| Cross-record consistency 1 — a committed write whose close never landed stands beside an open intent, closed by the sweep | no | `checked` **covered** | `Owed_outcome`. Probes `-recovered`, `-revocation-recovered`. *Within the closure window* is Recoverable Invocation's (the clock) Broken by `capability-backed-sharing-buggy-close-skipped.tla`. |
| Term authorization probe, disclosure probe, revocation probe; Capability requirement 22, 23 — the probes pair on the injected now, never equal for two invocations of one act key | YES | `checked` **covered** | `Pairing_unique`: the sweep answers committed only for the intent whose own commit wrote the record. Twin `-equal-now` (Capability requirement 23 dropped). Probes `-recovered`, `-revocation-recovered` Broken by `capability-backed-sharing-buggy-equal-now.tla`. |
| Recoverable Invocation reconcile step 3.5 — an intent with no commit escalated | no | `owed` **covered** | `SweepEscalate`. Probe `-escalated` No check of this model states it, so no twin can be said to break it (2026-11-10, unit `tooling: every check has a twin that breaks it`): an action's shape and a probe that reaches it. |
| Reconciliation 31 through 34 — a record no intent carries opens a write-ownership finding | no | `checked` **covered** | `Write_ownership_finding`: every record the outside write made has a finding, and no other record does. Twins `-no-finding` (the disclosure key alone, no datum), `-finding-for-carried` (only intents an outcome closed read as carrying). Probe `-finding` Broken by `capability-backed-sharing-buggy-equal-now.tla`. |
| Reconciliation 35 — a false closing is alerted | no | `checked` **covered** | `False_closing_alert`: the leg alerts exactly the records whose own intent an abandonment or a refusal closed. Twin `-no-false-closing-alert`. Probe `-false-closing` (an operator abandons a redemption whose record landed) Broken by `capability-backed-sharing-buggy-no-false-closing-alert.tla`. |
| Reconciliation 2, 29, 30, 36 through 38 — the leg's cadence, edges, answered read, run reading, enumeration instant | no | `owed` out-of-scope | the clock (Not modelled); a read that fails decides nothing and is no step |
| Composition state 17, 18 — the seal alert and the duplicate-authorization alert | no | `checked` **covered** | `Seal_alert`, `Duplicate_detected`. Twins `-no-seal-alert`, `-no-duplicate-alert`. Probe `-operator-duplicate` Broken by `capability-backed-sharing-buggy-no-seal-alert.tla` (`Seal_alert`), `capability-backed-sharing-buggy-no-duplicate-alert.tla` (`Duplicate_detected`). |
| Composition state 7, 21; Action wiring 56 through 58; Term aged event | no | `owed` out-of-scope | an event aging past the audit horizon is the clock's passage; [Redeem And Disclose] reaches these rules for a live token only where it was allocated before the cap (`Lapse_before_aged`, `Index_read_live` keep every capped token off them), and [Authorization Provenance] is a read-only query |
| Composes 1 through 20; Composition state 1 through 16, 19, 20; Capability requirement 1 through 6, 14 through 18, 24 through 32; Primitive policy 1 through 18; Audit arm 17; Action wiring 4, 10 through 17, 19 through 22, 24, 28, 29, 35, 38, 41, 47 through 55, 59, 62 | no | `unstatable` out-of-scope | wiring, the records' fields, deployment configuration, the Recoverable Invocation instance's settings, input validation before any write, the indexes' content and the read-only queries (a read over the records, not an interleaving) |
| Check 1.1 through 7.2 other than the rows above; External check 1 through 9 | no | `unstatable` out-of-scope | the auditor's reads of the records and external evidence; the model checks the state they read |
| Non-goal 1 through 10; Clock semantics 1, 2 | no | `unstatable` out-of-scope | non-goals bound the claim; Non-goal 9 (open, commit and close are not atomic) is the model's shape |

**Inherited: the rows that left.** The page tombstoned these rules, so the matrix carries no row for them. Each is owned by Recoverable Invocation, and recoverable-invocation.tla or its coverage carries it:

| Former row (former check) | Owner now |
|---|---|
| Invariant 2.4 — every pending marker sealed within the compensation window (owed 2a: a window counter and a PROPERTY) | Recoverable Invocation Invariant 4.2, Check 3.1, Instance start 4, which recoverable-invocation.tla checks in its window configurations (`Inv4_BoundedClosure`). The owed row of `owed-2026-11-10.md` closes here as inherited |
| Invariant 2.5 — the binding claim only with the bounds declared | Recoverable Invocation Instance start 4 through 8, Check 4.1 |
| Invariant 3.4 — every allocated capability settled within the compensation window (owed 2a) | Recoverable Invocation Invariant 4.2, as Invariant 2.4. Closes as inherited |
| Invariant 6.1, 6.2 — authentication before the allocate and the revoke | Recoverable Invocation Invariant 1.1 (`Inv1_IntentFirst`) |
| `Inv2_IntentPrecedesCommit` | Recoverable Invocation Invariant 1.1 |
| `Inv2_RecoveryDistinguishable` — a compensating seal flagged | Recoverable Invocation Invariant 5.2 (`Inv10_RecoveryFlagged`, since v8) |
| Reconciliation 4 through 28 — the page's own reconciliation (the recovery intent, the flag, the pairing window, the revoke of an unattested capability, the abandonments, the remainder, the escalation reach) | Recoverable Invocation reconcile step 1 through 5, Invariant 3.3, 3.5a, 4.2, 4.9, 5.1 through 5.3, 7.2; the revoke and the remainder retire without an owner (Composition state 6 and Action wiring 31 make them unreachable) |
| Capability requirement 21 — the reconciliation run bound (owed c, a deployment duty) | Recoverable Invocation run bound, Instance start 7 |

## Twin × check matrix

Each twin was run against the check it exists for, alone (a one-entry .cfg), 15 runs, and every one is `CAUGHT`. Every check but `TypeOK` rejects at least one twin on its own. The full product of 15 twins and 12 checks was not run.

| Twin | Check it breaks alone (states at the violation) |
|---|---|
| `-close-skipped` | `Owed_outcome` (112) |
| `-close-on-refused` | `Outcome_names_record` (693) |
| `-unanswered-committed` | `Outcome_names_record` (146) |
| `-recovered-authorizes` | `Disclosure_attested` (837) |
| `-redeem-kept` | `Consumed_equals_disclosed` (761) |
| `-equal-now` | `Pairing_unique` (750) |
| `-no-finding` | `Write_ownership_finding` (1,463) |
| `-finding-for-carried` | `Write_ownership_finding` (147) |
| `-no-false-closing-alert` | `False_closing_alert` (7,339) |
| `-no-seal-alert` | `Seal_alert` (5,243) |
| `-no-duplicate-alert` | `Duplicate_detected` (4,811) |
| `-ttl-past-horizon` | `Lapse_before_aged` (140) |
| `-default-past-horizon` | `Lapse_before_aged` (156) |
| `-one-allowance` | `Lapse_before_aged` (127) |
| `-spent-opened` | `Index_read_live` (357) |

## Readings (named, not counterexamples)

1. **The operator's closing.** The invocation resolve checks neither an operator's outcome nor the record it names against Capability or Selective Disclosure (Recoverable Invocation resolve 28, 31). So Invariant 2.1, 2.2, 3.1 and 3.2 are detected for an operator's closing, not prevented, as the page's Invariant 2 and 3 NOTEs say: the seal alert, the duplicate-authorization alert, Check 2.1, 2.2 and 3.2 find it.
2. **What takes nothing from outside.** No ASSUME, CONSTRAINT or ACTION_CONSTRAINT: the one thing the page takes from outside, the host's fresh now per act key (Capability requirement 23), is the `Nows` the open draws from, and `-equal-now` drops it.
3. **Distinct nows.** The model's clock gives every invocation and the outside write a distinct now. Capability requirement 23 asks this only per act key, so two act keys sharing a now are not explored; the probes and the leg pair on the key and the datum.
4. **One descriptor.** The authorization key and the disclosure key are one value each, so two tokens' redemptions serialize on one disclosure key, as two shares with one descriptor do on the page (Term disclosure key).
5. **One use per token.** `MaxRed = 1` reaches the spent-token refusal (`-probe-spent-refused`); `MaxRed = 2` adds no new violation (Step 3).
6. **The ttl cap as an inequality.** The model's clock orders invocations; it is no duration, so no token lapses and no event ages in it. `Lapse_before_aged` checks the cap where it is decided, on the stamps: Capability's lapse (now no earlier than the expiry instant) and Term aged event (now not preceding the aged instant) both hold from the instant they reach, so an expiry instant no later than the aged instant is the claim that no reading of now finds a live token whose authorization event has aged. The stamp ranges over the three values one allowance gives, so the earliest recording instant is explored; `-one-allowance` is the cap that leaves it out. `A = 0` (a ttl equal to the horizon exactly) and wider horizons hold (Step 3).

## Step 3 — bound saturation

Each run explores the state space exhaustively under TLC and holds.
- `NT = 2, N = 3, MaxRed = 1, MaxDirect = 1, Hz = 3, A = 1, DefTtl = 1` → 170,229 states. This is the canonical run (about 20 seconds).
- `N = 2` → 4,251 states.
- `MaxRed = 2` → 181,893 states, with no new violation.
- `NT = 3` → 302,098 states, with no new violation.
- `MaxDirect = 2` → 1,316,285 states, with no new violation.
- `N = 4` → 7,049,712 states, with no new violation (about 3 minutes).
- `A = 0, DefTtl = 3` (the cap is the horizon: a ttl equal to the horizon exactly) → 108,157 states, with no new violation.
- `Hz = 5, DefTtl = 3` → 170,229 states; `Hz = 5, A = 2, DefTtl = 1` → 220,933 states; each with no new violation.

Why these sizes: `N = 3` is the fewest invocations that reach a redemption retried on one key after an authorization (the `-equal-now` twin needs it), and an authorization recovered by the sweep followed by a refused redemption of its token.

**saturated** ✓ within the audit's reach. This is not a claim that `N = 4` is enough.

## Outcome

- GAP rows: none on the page's live rules. No by-construction row is load-bearing.
- Inherited: Invariant 2.4, 2.5, 3.4, 6.1, 6.2 are Recoverable Invocation's (Invariant 4.2, Instance start, Invariant 1.1), which recoverable-invocation.tla checks; the coverage unit's owed 2a rows for 2.4 and 3.4 close as inherited.
- Owed: **(b)** Invariant 1.1, 1.3, 1.4 and 4.1 (field claims): Alloy, the static data model. **(c)** Invariant 1.2 (what no record carries) stays with its reason.
- Result: clean — *Coverage cross-check 2026-11-10 — clean (all load-bearing invariants covered on the invocation and the sweep; the operator's closing detected, not prevented; the ttl cap and the spent token's refusal ahead of the index covered; saturation confirmed within the audit's reach).*

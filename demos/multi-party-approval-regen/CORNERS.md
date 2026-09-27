# CORNERS — Multi-Party Approval, cold regeneration

Findings and preferences from regenerating the demo from today's specs. A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

Seven, all cured in the specs on 2026-09-26 (council read 232); the render follows the cured pages.

**1. What [Initiate Chain] answers after a recovery it ran itself was undeclared.** Action wiring 9 and 12 run the initiation recovery on a failed submit or assign and say nothing of the answer; Action wiring 15 does the same for an unlanded initiation event. *Cured:* Action wiring 62 — recording-failure carrying outcome, because constituent writes committed (Audit arm 15).

**2. Disposition d was carried by no record.** The Term *disposition* declares a | b | c | d, but only the initiation-failed record carries a disposition, and d's path records an initiation event instead. *Cured:* Reconciliation 10's initiation event carries disposition d.

**3. The partial flag was a boolean that "names" calls.** The Term *partial flag* was `cascade_partial` set to true; Reconciliation 24 through 26 and Check 5.4 speak of the calls a partial flag names. *Cured:* the flag names each call left unanswered by its step id and its call.

**4. The recovery intent was a service-identity write Check 5.3 excluded.** The sweep attests every write under the service identity (Reconciliation 31), including its recovery intents; Check 5.3 listed what that identity attests "AND nothing else", without them. *Cured:* Check 5.3 lists the recovery intent.

**5. An example's rule reason did not match the rule.** The rejection walkthrough's reason was free prose; the Term *rule reason* fixes its form. *Cured:* the example reads `quorum unreachable: all-of-N; 2 remain achievable; rejections present`.

**6. A WHY derived a flag from stamps a rule forbids comparing.** The transition leg's WHY said the re-emitted trailing flag is derived from the chain's terminal stamps; Clock semantics 2 forbids comparing the terminal instant with a step's decided instant. *Cured:* the WHY reads it from the candidates' decision intents, which carry it (Action wiring 20).

**7. Audit Trail delegated to an action Retention Window never declared.** Composes 11 and purge eligible 1 named `RetentionWindow.purge_eligible`; Retention Window declares purge eligibility as a projection its read answers. *Cured:* both read eligibility through Retention Window's declared read.

## Preferences

- **Audit Trail is rendered to the depth this composition reaches:** [Record Action] steps 1 through 5 and 7, [Read Record], [Verify Record] steps 1 through 3 and the log read. No seal, no purge contract, no substrate reconciliation; `purge_for_test` stands in for the retention layer where a test reaches past the horizon.
- **One process, no concurrency.** The chain exclusion is an in-memory set. Where a test holds it, the sweep leaves the chain (Reconciliation 7) and [Withdraw Chain] answers recording-failure carrying intent — nothing committed — where a real host would wait.
- **A present but blank initiation reason is refused** as invalid-request. Primitive policy 9 names only the reason-bearing actions; the prefix keeps Approval Step from ever seeing a blank reason, but the audit data would store one.
- **The recall leg treats a lost recall and a named partial call alike,** and writes a closure record for each call it closes.
- **A terminal chain with no terminal event** is re-emitted as a withdrawal where a withdrawal intent exists, and as a resolution otherwise (Reconciliation 34).
- **The rebuilds** (Composition state 12 through 18) are not rendered; every store here is primary.
- **The credential mechanism** is an HMAC over the action and actor references under the actor's registered secret.

---

## Against the 2026-05 render

The old render's `CORNERS.md` predicted two differences. Both hold: it records no intent and takes no credential, so `invalid-credential` is never answered; and its `recording-failure` carries no position.

The regeneration found eight more, none of them predicted:

- **The chain state is set after the cascade,** not before it (Action wiring 36).
- **The composition reads actors' stored secrets** to attest cascade withdrawals and resolutions, where the spec attests a cascade under the initiator's validated credential or the service identity (Cascade 5 and 6; Primitive policy 15).
- **`recalled_step_ids` lists every Pending step,** not the recalls that answered ok (Cascade 13).
- **No quarantine, no partial flag, no sweep and no chain exclusion:** `cascade_partial` is always false and `audit_pending` never set.
- **Rule reasons name neither the rule nor the counts** (Wiring decision 9).
- **The Approval Step store carries a chain id and a position,** and no step carries the prefixed reason; Approval Step knows no chain (Composes 6; Action wiring 7).
- **A retention policy travels with every audit write** (Capability requirement 6).
- **Every decided step counts toward quorum;** nothing tells a routed transition from an out-of-band one (Wiring decision 6 through 8).

Test counts are not comparable: the old render's 67 tests cover its HTTP routes and its own hash chain as well as its domain; this render's 31 cover the domain only.

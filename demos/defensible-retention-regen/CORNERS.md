# CORNERS — Defensible Retention, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

**1. The sweep owned a destruction record it could never write.** When a purge's outcome cannot land, the record is the sweep's (Action wiring 72, and the 2026-09-14 decision that made it so). A record purged outcome carries the hold check result (Action wiring 60), which no constituent store holds and which the intent did not carry, so Reconciliation 27 closed every such marker as abandoned: a committed destruction with no destruction record, for good. *Closed:* the purge intent carries the hold check result (Action wiring 76). A test fails the outcome, lets the sweep run twice, and finds one recovered record naming the result.

**2. The sweep's closing was not an outcome.** Reconciliation 5 reads an intent with no outcome as open, and the four outcomes named no closing, so a marker the sweep closed as abandoned read open on the next run and was closed again, every run; Invariant 5.6's one outcome per admitted invocation failed for every abandoned one. *Closed:* intent_abandoned is an outcome, and Invariant 4.6 now forbids an outcome only for a refusal no intent preceded. A test abandons a failed placement, sweeps twice, and counts one closing.

**3. Three purge refusals had no order.** Action wiring 47 (a live sibling), 50 (an unreadable hold store), 53 (a hold under strict mode) and 57 (the named retention running) each answered on one condition, and a call meeting two was owed two answers. Invariant 1.2 settled only the hold. *Closed:* not-eligible and under-active-retention apply once the hold check admitted the destruction, and under-active-retention only over an elapsed named retention, as the page's own account of the refusal already said. A test puts a hold against the running clock and against a live sibling.

**4. A gate record's failure had no position.** A strict refusal writes a gate record, which is neither an intent nor an outcome, and Invariant 1.2 admits recording-failure for it; the position token had only intent and outcome. *Closed:* position gains gate. A test fails the gate record and reads `recording-failure(gate)` with nothing destroyed.

## Preferences

- **An invocation retries a record three times, then yields.** The host clock does not move inside one call, so the retention completion bound (Action wiring 71) is stood in by a count.
- **The serialization is an in-memory set keyed by record reference** (Capability requirement 34, 35) and by invocation id for a sweep leg (Reconciliation 20). The host is synchronous, so a held key is a holder that never released: the render throws.
- **A blank retention id answers not-known** through the index miss and rebuild; Primitive policy names no blank retention id.
- **One field cap serves every field** (Capability requirement 14).
- **A future placement instant is Legal Hold's refusal,** after the intent lands, since the composition supplies no now to a constituent (Composes 18); the marker then closes as abandoned.
- **The sweep matches a marker to its act** by the intent's inputs and, for a retention, the intent instant; a hold carries no entry instant, so a hold placement matches on its inputs alone. Where several markers name one act, the earliest writes the recovery and the rest close on the next run (Reconciliation 10, 12).
- **A recovered destruction's purge instant is the intent instant** — the invocation's one reading (Action wiring 8, 60), not the retention's own stamp (Clock semantics 12).
- **An unreadable hold store is a fault on Legal Hold's read;** the atom declares no such answer, so the render adds one outside its contract (Action wiring 75).
- **Not rendered:** events past the audit horizon beyond skipping a payload the substrate destroyed (Reconciliation 23, 24); the checks an auditor runs; the horizon alert, which is a flag at start.
- **Carried code.** The substrate's `RetentionRecord` type lacked the purge deadline its table already stored; the type is fixed here and in the Audit Trail regeneration.

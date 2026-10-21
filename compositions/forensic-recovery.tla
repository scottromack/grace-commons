---- MODULE forensic-recovery ----
\* Grace Commons — Forensic Recovery composition.
\* Spec-level formal sibling of compositions/forensic-recovery.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* WHAT THIS MODEL CHECKS (revised 2026-06-11 — closes the Invariant-4 coverage-gap finding;
\* comments re-pointed 2026-10-20 at Execution Contract Database 1, no logic change)
\* The composition's load-bearing wiring decision is Invariant 4 (binding
\* bijection / no dangling partial), restated as safety + liveness. The headline
\* consequence is Invariant 2 (purge accountability): "no record reaches Purged
\* without an attributed audit event" — and the most consequential partial
\* failure is exactly a purge without its audit record. A lifecycle action's
\* intent record, Soft Delete transition and Audit Trail outcome event are
\* store writes of one action, which Execution Contract Database 1 commits
\* together. The one partial the spec keeps is the ORPHAN Audit Trail's
\* refusal of the outcome record leaves (a lifecycle transition with no audit
\* event, Audit arm 15 and Audit arm 16): the transition commits, the action
\* answers recording-failure carrying outcome and surfaces the orphan as a
\* compliance finding, and the reconciliation compensates it, marking the
\* compensating event `cascade_recovery = true`.
\*
\* This model covers BOTH arms of Invariant 4 — the one transaction and the
\* compensated arm the earlier model idealized away (the coverage-matrix GAP
\* closed by the Invariant-4 coverage-gap finding; immutable-transaction-ledger.tla, revised for
\* the compensated-arm finding, is the worked template):
\*   CommitClean(t)  — the lifecycle action's writes commit together
\*                     (Execution Contract Database 1).
\*   FailPartial(t)  — the Soft Delete transition commits and Audit Trail
\*                     refuses the outcome record; the orphan is reachable AND
\*                     surfaced in the same outcome (the action's declared
\*                     failure path: rejected(recording-failure(outcome)) plus
\*                     the dashboard finding). The orphan is a real
\*                     inter-action state other actions can observe.
\*   RetryAudit(t)   — the compensation: the reconciliation's compensating
\*                     event, marked cascade_recovery; the bijection is
\*                     restored and the recovered binding stays distinguishable
\*                     from a clean one.
\*
\* Per lifecycle transition t, TWO truth-bearing sub-writes (the
\* record_to_events list is a derived index per execution-contract.md
\* section Composition state — rebuildable by enumerating Audit Trail events whose
\* `data.record_id` names the record, grouped by lifecycle `action_ref`; outside
\* the atomicity surface; omitted from the model per that section's
\* obligation 2):
\*   softState  : absent | present                      (Soft Delete lifecycle
\*                                                       transition committed)
\*   auditState : absent | clean | recovered            (Audit Trail record_action
\*                                                       event; `recovered` carries
\*                                                       the cascade_recovery marker)
\*   surfaced   : BOOLEAN                               (orphan surfaced as a
\*                                                       compliance finding)
\*
\* SAFETY (checked here): no UNSURFACED orphan — every reachable configuration
\* is uncommitted, fully bound, or a surfaced orphan-under-compensation; a
\* lifecycle audit event never exists without its Soft Delete transition;
\* recovered bindings are distinguishable from clean ones via the
\* cascade_recovery marker. Because purge is one of the modeled transitions,
\* the safety arm carries Invariant 2's compensated path: a Purged record's
\* missing audit event can exist only as a surfaced finding under compensation.
\* LIVENESS (canonical in the English spec; see Invariant 4's liveness arm):
\* every orphan is eventually bound — Orphan(t) ~> Bound(t) under weak fairness
\* on RetryAudit. The harness checks safety invariants only; the model carries
\* the structural guarantee that discharges the obligation's enabledness half:
\* RetryAudit's enabling condition is exactly the orphan configuration, so no
\* orphan state is a dead end (the buggy twin, which deletes the compensation
\* action and the surfacing, is rejected on safety — sequential-without-
\* compensation is unsafe).
\*
\* NOT MODELED (out of scope for the load-bearing property)
\* - the Active/Deleted/Purged state machine itself (Soft Delete's own model);
\* - the order of the writes inside one lifecycle action (Execution Contract
\*   Database 1 commits them together, and a crash inside the action leaves
\*   nothing; the model's states are action OUTCOMES — clean commit, surfaced
\*   partial failure).
\* - the reconciliation's pairing, its recovery intent and the recovery
\*   identity it attests under (Reconciliation 5, Reconciliation 9 through
\*   17): attribution and pairing rules, not interleavings; RetryAudit
\*   abstracts the compensating event into the one `recovered` outcome.
\* - the record_to_events derived index (outside the atomicity surface per
\*   execution-contract.md section Composition state; a lost entry is a rebuild
\*   trigger, not data loss).
\* - recover_history outcome plumbing (Invariant 3 — a query-shape property);
\* - constituent invariants (Invariant 5) — each checked in its own model.

CONSTANT Transitions            \* finite set of lifecycle transitions

VARIABLES softState, auditState, surfaced
vars == <<softState, auditState, surfaced>>

TypeOK ==
    /\ softState  \in [Transitions -> {"absent", "present"}]
    /\ auditState \in [Transitions -> {"absent", "clean", "recovered"}]
    /\ surfaced   \in [Transitions -> BOOLEAN]

\* Every transition begins uncommitted: no Soft Delete write, no audit event,
\* no finding.
Init ==
    /\ softState  = [t \in Transitions |-> "absent"]
    /\ auditState = [t \in Transitions |-> "absent"]
    /\ surfaced   = [t \in Transitions |-> FALSE]

\* Happy path: the Soft Delete lifecycle transition and the Audit Trail
\* outcome event commit together (Execution Contract Database 1). The audit event
\* is a CLEAN binding.
CommitClean(t) ==
    /\ softState[t] = "absent"
    /\ softState'  = [softState  EXCEPT ![t] = "present"]
    /\ auditState' = [auditState EXCEPT ![t] = "clean"]
    /\ UNCHANGED surfaced

\* Partial failure: the Soft Delete transition commits and Audit Trail
\* refuses the outcome record (Audit arm 15, Audit arm 16). The action's
\* declared failure path returns rejected(recording-failure(outcome)) AND
\* surfaces the orphan to the compliance dashboard in the same outcome — the
\* orphan is reachable, durable until compensated, and never silent. For a
\* purge transition this is Invariant 2's worst case: a destroyed record
\* awaiting its compensating audit event, visible the whole time.
FailPartial(t) ==
    /\ softState[t] = "absent"
    /\ softState'  = [softState EXCEPT ![t] = "present"]
    /\ surfaced'   = [surfaced  EXCEPT ![t] = TRUE]
    /\ UNCHANGED auditState

\* Compensation: the reconciliation records the compensating event
\* (Reconciliation 9 through 17); it carries cascade_recovery = true, so the
\* recovered binding stays distinguishable from a clean one. Enabled in exactly
\* the orphan configuration — no orphan state is a dead end (the liveness arm's
\* enabledness half; eventuality is weak fairness on this action).
\* The enabling condition auditState[t] = "absent" IS the reconciliation's
\* pairing made structural (Reconciliation 5): it appends only for an intent no
\* outcome event names, so an outcome whose lost append landed after all is
\* bound, never doubled (the state where the audit event already landed
\* disables this action). Two compensations of one record are serialized by
\* Execution Contract Database 2; the model's one-action-per-step semantics
\* carries that for free.
RetryAudit(t) ==
    /\ softState[t] = "present"
    /\ auditState[t] = "absent"
    /\ auditState' = [auditState EXCEPT ![t] = "recovered"]
    /\ UNCHANGED <<softState, surfaced>>

Next == \E t \in Transitions : CommitClean(t) \/ FailPartial(t) \/ RetryAudit(t)
Spec == Init /\ [][Next]_vars

\* @isolate-facets Inv4_SafetyBijection Inv4_NoUnsurfacedOrphan Inv4_NoOrphanAudit Inv4_RecoveryDistinguishable
\* --- composition-level safety invariants (Invariant 4, safety arm; Invariant 2
\* --- rides the same predicates for purge transitions) ---

\* The orphan configuration: a committed lifecycle transition with no audit
\* event — the partial-failure signature, detectable from the records alone
\* (enumerate Soft Delete state against the Audit Trail events through the
\* substrate's read surface).
Orphan(t) == softState[t] = "present" /\ auditState[t] = "absent"

\* The coherent configurations: uncommitted, or fully bound (clean or recovered).
Coherent(t) ==
    \/ (softState[t] = "absent"  /\ auditState[t] = "absent" /\ ~surfaced[t])
    \/ (softState[t] = "present" /\ auditState[t] \in {"clean", "recovered"})

\* Invariant 4, safety arm — every reachable configuration is coherent or a
\* SURFACED orphan-under-compensation. There is no silent dangling partial.
Inv4_SafetyBijection == \A t \in Transitions : Coherent(t) \/ (Orphan(t) /\ surfaced[t])

\* No unsurfaced orphan: a lifecycle transition lacking its audit event is
\* always a visible finding, never a quiet inconsistency. For purge transitions
\* this is Invariant 2's compensated path made checkable.
Inv4_NoUnsurfacedOrphan == \A t \in Transitions : Orphan(t) => surfaced[t]

\* No lifecycle audit event without its Soft Delete transition (the inverse
\* orphan — unchanged from the prior model).
Inv4_NoOrphanAudit ==
    \A t \in Transitions : (auditState[t] # "absent") => (softState[t] = "present")

\* Recovered bindings are distinguishable: a clean binding never went through
\* compensation (no finding was surfaced); a recovered binding always did.
Inv4_RecoveryDistinguishable ==
    \A t \in Transitions :
        /\ (auditState[t] = "clean")     => ~surfaced[t]
        /\ (auditState[t] = "recovered") => surfaced[t]

Safety ==
    /\ TypeOK
    /\ Inv4_SafetyBijection
    /\ Inv4_NoUnsurfacedOrphan
    /\ Inv4_NoOrphanAudit
    /\ Inv4_RecoveryDistinguishable

====

---- MODULE chain-of-custody ----
\* Grace Commons — Chain of Custody composition.
\* Spec-level formal sibling of compositions/chain-of-custody.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* WHAT THIS MODEL CHECKS (revised 2026-06-11 — closes the Invariant-4 coverage-gap finding;
\* comments re-pointed 2026-10-20 at Execution Contract Database 1, no logic change)
\* The composition's load-bearing wiring decision is Invariant 4 (binding
\* bijection / no dangling partial), restated as safety + liveness. A custody
\* action's intent, Provenance custody entry and Audit Trail outcome event are
\* store writes of one action, which Execution Contract Database 1 commits
\* together. The one partial the spec keeps is the ORPHAN Audit Trail's
\* refusal of the outcome event leaves (a custody entry with no audit event,
\* Audit arm 19 and Audit arm 26): the entry commits, the action answers
\* recording-failure carrying outcome and surfaces the orphan as a
\* high-priority compliance finding, and the reconciliation compensates it,
\* marking the compensating event `cascade_recovery = true`.
\*
\* This model covers BOTH arms of Invariant 4 — the one transaction and the
\* compensated arm the earlier model idealized away (the coverage-matrix GAP
\* closed by the Invariant-4 coverage-gap finding; immutable-transaction-ledger.tla, revised for
\* the compensated-arm finding, is the worked template):
\*   CommitClean(e)  — the custody action's writes commit together (Execution
\*                     Contract Database 1).
\*   FailPartial(e)  — the Provenance entry commits and Audit Trail refuses
\*                     the outcome event; the orphan is reachable AND surfaced
\*                     in the same outcome (the action's declared failure
\*                     path: rejected(recording-failure(outcome)) plus the
\*                     dashboard finding). The orphan is a real inter-action
\*                     state other actions can observe.
\*   RetryAudit(e)   — the compensation: the reconciliation's compensating
\*                     event, marked cascade_recovery; the bijection is
\*                     restored and the recovered binding stays distinguishable
\*                     from a clean one.
\*
\* Per custody entry e, TWO truth-bearing sub-writes (the entry_to_event map is
\* a derived index per execution-contract.md section Composition state — rebuildable by
\* enumerating Audit Trail events whose `data.entry_id` names the entry; outside
\* the atomicity surface; omitted from the model per that section's obligation 2):
\*   intentState: absent | present                      (the pre-commit intent record —
\*                the AuditTrail.record_action written BEFORE the Provenance
\*                write, inside which the substrate validates the acting
\*                custodian's credential; added 2026-08-26 by the
\*                authentication-precedence round)
\*   provState  : absent | present                      (Provenance custody entry)
\*   auditState : absent | clean | recovered            (Audit Trail record_action
\*                                                       event; `recovered` carries
\*                                                       the cascade_recovery marker)
\*   surfaced   : BOOLEAN                               (orphan surfaced as a high-
\*                                                       priority compliance finding)
\*
\* SAFETY (checked here): no UNSURFACED orphan — every reachable configuration
\* is uncreated, fully bound, or a surfaced orphan-under-compensation; an audit
\* custody event never exists without its Provenance entry; recovered bindings
\* are distinguishable from clean ones via the cascade_recovery marker.
\* LIVENESS (canonical in the English spec; see Invariant 4's liveness arm):
\* every orphan is eventually bound — Orphan(e) ~> Bound(e) under weak fairness
\* on RetryAudit. The harness checks safety invariants only; the model carries
\* the structural guarantee that discharges the obligation's enabledness half:
\* RetryAudit's enabling condition is exactly the orphan configuration, so no
\* orphan state is a dead end (the buggy twin, which deletes the compensation
\* action and the surfacing, is rejected on safety — sequential-without-
\* compensation is unsafe).
\*
\* NOT MODELED (out of scope for the load-bearing property)
\* - per-action orchestration, rejection guards, the acting-custodian rule.
\* - the order of the writes inside one custody action (Execution Contract
\*   Database 1 commits them together, and a crash inside the action leaves
\*   nothing; the model's states are action OUTCOMES — clean commit, surfaced
\*   partial failure).
\* - the reconciliation's pairing, its recovery intent and the recovery
\*   identity it attests under (Reconciliation 10 through 27): attribution and
\*   pairing rules, not interleavings; RetryAudit abstracts the compensating
\*   event into the one `recovered` outcome.
\* - the entry_to_event derived index (outside the atomicity surface per
\*   execution-contract.md section Composition state; a lost entry is a rebuild
\*   trigger, not data loss).
\* - verify_custody outcome plumbing (Invariant 5) — a query-shape property.
\* - constituent invariants (Invariant 6) — each checked in its own model
\*   (provenance.als, audit-trail.tla, ...), not re-proven here.

CONSTANT Entries                \* finite set of custody entry creations

VARIABLES intentState, provState, auditState, surfaced
vars == <<intentState, provState, auditState, surfaced>>

TypeOK ==
    /\ intentState \in [Entries -> {"absent", "present"}]
    /\ provState  \in [Entries -> {"absent", "present"}]
    /\ auditState \in [Entries -> {"absent", "clean", "recovered"}]
    /\ surfaced   \in [Entries -> BOOLEAN]

\* Every entry begins uncreated: no Provenance entry, no audit event, no finding.
Init ==
    /\ intentState = [e \in Entries |-> "absent"]
    /\ provState  = [e \in Entries |-> "absent"]
    /\ auditState = [e \in Entries |-> "absent"]
    /\ surfaced   = [e \in Entries |-> FALSE]

\* Happy path: the Provenance custody entry and the Audit Trail outcome event
\* commit together (Execution Contract Database 1). The audit event is a CLEAN
\* binding.
\* The intent record: written before any Provenance call that commits. This is
\* where the acting custodian's credential is validated (the substrate's
\* ActorIdentity.attest guard inside record_action), so it is the enabling
\* condition for every committing action below. It commits nothing itself —
\* an intent record with no outcome is an authenticated attempt, not an orphan.
WriteIntent(e) ==
    /\ intentState[e] = "absent"
    /\ intentState' = [intentState EXCEPT ![e] = "present"]
    /\ UNCHANGED <<provState, auditState, surfaced>>

CommitClean(e) ==
    /\ intentState[e] = "present"
    /\ provState[e] = "absent"
    /\ provState'  = [provState  EXCEPT ![e] = "present"]
    /\ auditState' = [auditState EXCEPT ![e] = "clean"]
    /\ UNCHANGED <<intentState, surfaced>>

\* Partial failure: the Provenance entry commits and Audit Trail refuses the
\* outcome event (Audit arm 19, Audit arm 26). The action's declared failure
\* path returns rejected(recording-failure(outcome)) AND surfaces the orphan to
\* the compliance dashboard in the same outcome — the orphan is reachable,
\* durable until compensated, and never silent.
FailPartial(e) ==
    /\ intentState[e] = "present"
    /\ provState[e] = "absent"
    /\ provState'  = [provState EXCEPT ![e] = "present"]
    /\ surfaced'   = [surfaced  EXCEPT ![e] = TRUE]
    /\ UNCHANGED <<intentState, auditState>>

\* Compensation: the reconciliation records the compensating event
\* (Reconciliation 21 through 27); it carries cascade_recovery = true, so the
\* recovered binding stays distinguishable from a clean one. Enabled in exactly
\* the orphan configuration — no orphan state is a dead end (the liveness arm's
\* enabledness half; eventuality is weak fairness on this action).
\* The enabling condition auditState[e] = "absent" IS the reconciliation's
\* re-read made structural (Reconciliation 25 and Reconciliation 26): it
\* appends only when no
\* event names the entry, so an outcome whose lost append landed after all is
\* bound, never doubled (the state where the audit event already landed
\* disables this action). Two compensations of one entry are serialized by
\* Execution Contract Database 2; the model's one-action-per-step semantics
\* carries that for free.
RetryAudit(e) ==
    /\ provState[e] = "present"
    /\ auditState[e] = "absent"
    /\ auditState' = [auditState EXCEPT ![e] = "recovered"]
    /\ UNCHANGED <<intentState, provState, surfaced>>

Next == \E e \in Entries :
            WriteIntent(e) \/ CommitClean(e) \/ FailPartial(e) \/ RetryAudit(e)
Spec == Init /\ [][Next]_vars

\* @isolate-facets Inv4_SafetyBijection Inv4_NoUnsurfacedOrphan Inv4_NoOrphanAudit Inv4_RecoveryDistinguishable Inv7_AuthPrecedence
\* --- composition-level safety invariants (Invariant 4, safety arm) ---

\* The orphan configuration: a Provenance custody entry with no audit event —
\* the partial-failure signature, provable (enumerate
\* the Provenance chain against the Audit Trail events through the substrate's
\* read surface).
Orphan(e) == provState[e] = "present" /\ auditState[e] = "absent"

\* The coherent configurations: uncreated, or fully bound (clean or recovered).
Coherent(e) ==
    \/ (provState[e] = "absent"  /\ auditState[e] = "absent" /\ ~surfaced[e])
    \/ (provState[e] = "present" /\ auditState[e] \in {"clean", "recovered"})

\* Invariant 4, safety arm — every reachable configuration is coherent or a
\* SURFACED orphan-under-compensation. There is no silent dangling partial.
Inv4_SafetyBijection == \A e \in Entries : Coherent(e) \/ (Orphan(e) /\ surfaced[e])

\* No unsurfaced orphan: a custody entry lacking its audit event is always a
\* visible high-priority finding, never a quiet inconsistency.
Inv4_NoUnsurfacedOrphan == \A e \in Entries : Orphan(e) => surfaced[e]

\* No custody audit event without its Provenance entry (the inverse orphan —
\* unchanged from the prior model).
Inv4_NoOrphanAudit ==
    \A e \in Entries : (auditState[e] # "absent") => (provState[e] = "present")

\* Recovered bindings are distinguishable: a clean binding never went through
\* compensation (no finding was surfaced); a recovered binding always did.
Inv4_RecoveryDistinguishable ==
    \A e \in Entries :
        /\ (auditState[e] = "clean")     => ~surfaced[e]
        /\ (auditState[e] = "recovered") => surfaced[e]

\* --- Invariant 7, authentication precedence (added 2026-08-26) ---

\* No custody entry is ever committed without its intent record already present.
\* The intent record is where the acting custodian's credential was validated,
\* so this is the model form of "custody never moves on an unverified identity."
\* Note the asymmetry, which is the point: the converse does NOT hold — an
\* intent record with no Provenance entry is an authenticated attempt the chain
\* refused, a reachable and desirable state, not a violation.
Inv7_AuthPrecedence ==
    \A e \in Entries : (provState[e] = "present") => (intentState[e] = "present")

Safety ==
    /\ TypeOK
    /\ Inv7_AuthPrecedence
    /\ Inv4_SafetyBijection
    /\ Inv4_NoUnsurfacedOrphan
    /\ Inv4_NoOrphanAudit
    /\ Inv4_RecoveryDistinguishable

====

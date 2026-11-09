---- MODULE reserve-from-pool-release-before-transition-buggy ----
\* BUGGY TWIN (release-before-transition): The pool release is called before the commitment's transition answers ok (Action wiring 106).
\* The checker must reject it. Everything else is the correct model.
\* Grace Commons — Reserve from Pool composition.
\* Spec-level formal sibling of compositions/reserve-from-pool.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-09 (the first model, 2026-06-04, checked allocation coherence over four
\* atomic steps and a retired atomic trio of transition, pool release and journal entry). The page
\* has since moved onto the Database contract (Execution Contract Database 1 to 5): each action's
\* attestation, intent entry, constituent writes and outcome entry commit together, so there is no
\* half-written reservation to reconcile and no release marker. What the page keeps, and this model
\* checks, is the reservation's arc against the pool, the binding index outside the transaction,
\* the journal's retention, the hold's window, and the order of the writes inside each action. The
\* retry layer (the token results map, Duplicate Prevention's window, the journal read on a token
\* it has not seen) is the second model, beside this one: reserve-from-pool-retry.tla.
\*
\* WHAT THIS MODEL CHECKS
\* One pool, a few reservations, and whatever order the actions, the clock and the retention
\* horizon take:
\*   - Invariant 1.1, 1.5  at quiescence the pool's allocated count and the count of bound
\*                       reservations in a slot-holding state (Held or Confirmed) are equal.
\*   - Check 1.1         an auditor's count over the journal's reserve outcome entries and the
\*                       binding entries, less the reservations a slot-returning outcome entry
\*                       names, equals the pool's allocated count.
\*   - Invariant 2.1     no reservation gets two pool releases or two slot-returning outcome entries.
\*   - Invariant 3.1     the pool's Confirmed reservations never pass its capacity.
\*   - Invariant 4.1, 4.2  a Confirmed reservation was never lapsed; a lapsed hold resolves only
\*                       through [Expire Reservation]; and an Expired one was lapsed (Action wiring 87).
\*   - Invariant 6.1     every committed state change carries exactly one outcome entry.
\*   - Invariant 6.4     the read-only query writes nothing.
\*   - Invariant 8.1     no write is made before the attestation answers (Action wiring 21).
\*   - Action wiring 26, 45, 53, 62, 90 to 92, 97, 98, 106, 110; Wiring decision 2
\*                       the order inside each action: the intent entry before any constituent
\*                       call, the allocate before the hold, the hold's transition before the pool
\*                       release, the release before the outcome entry, and no pool write at a
\*                       confirm.
\*   - Wiring decision 3, 6  a slot is released only for a slot-returning transition, and a Confirmed
\*                       reservation never leaves Confirmed.
\*   - Action wiring 80, 81  a resolving action writes nothing for a reservation with no binding entry.
\*   - Composition state 6   a reservation that has been resolved keeps its binding entry.
\*   - Capability requirement 48, 49  a reserve outcome entry keeps its payload until its binding
\*                       entry stands; a slot-returning outcome entry is kept while it stands.
\*
\* BOUND
\* Rsv = {r1, r2}, Cap = 1: the pool admits one, so the second reservation meets a full pool and
\* the freed slot of the first. Exhaustive. The hold's window is one boolean (a hold is lapsed or
\* not), the clock being the host's and read once per invocation (Capability requirement 39 to 42),
\* so the model has no clock counter. Cap = 2 over the same two reservations is the bump run in
\* the .cfg. A third reservation passes the checker's depth cap of 40 (each reservation's arc is
\* a score of steps), so the pool's second slot is the bound the model can raise.
\*
\* HOW AN ACTION IS READ
\* The page puts each action's writes in one transaction (Database 1), and a store runs the
\* transactions one after another (Database 2). So at most one invocation is in flight, its
\* attestation, intent entry, constituent writes and outcome entry are staged as flags (`fa`,
\* `fi`, `fc`, `fh`, `fr`, `fo`), and the world changes only at the commit step, all together; a
\* refusal or an answer a constituent decides leaves the world as it was (Execution Contract Read 4).
\* The flags are separate booleans, not a position in a line, so a step that skips its predecessor
\* is a state the order invariants can see. The binding entry, the aging of an outcome entry and
\* the rebuild are outside every action's transaction (Composition state 4, 10, 15) and run beside
\* an invocation. A property of a step (a query that writes, a resolving action that writes for an
\* unbound reservation, a Confirmed reservation that leaves Confirmed) is a name the step adds to
\* `viol`; the named invariants say `viol` does not hold their name. A step reads the world, never
\* the rule it is checked against.
\*
\* SCOPE (named)
\* - Settled answers (pool-closed, pool-capacity-exceeded, not-held, window-elapsed,
\*   window-not-elapsed) and every refusal leave the reservation and the pool as they were; the
\*   model takes them as an abort of the invocation. The intent entry a settled answer leaves, the
\*   token results entry and Duplicate Prevention's record are the retry model's.
\* - The pool's own answers (closed, suspended, not-known, over-release) and its audit log are
\*   Capacity Constraint Enforcement's, inherited (Composes 5); the pool is one count here, and
\*   the binding's pool id is the one pool's.
\* - Attestation's verification (Check 6.1 to 6.8), the pool event balances (Action wiring 64,
\*   Check 7.1 and 7.2) and the witness balance (Action wiring 123, 124) are the entries' fields,
\*   not the arc's order.
\* - The audit horizon, the retention floor and who purges a pool holding live reservations are
\*   open (2026-11-05-a, 2026-11-05-b, 2026-11-06-a, 2026-11-06-b); the model takes the horizon as
\*   a step that may fire at any time, the strongest reading.
\* - Actor Identity's registry conditions, the digest and the token are the retry model's or the
\*   constituents'.
\*
\* ENCODING (the proven idiom of compositions/compensable-workflow.tla)
\* - No Sequences, RECURSIVE or CHOOSE; flat \E/\A; column-aligned junctions; every implication in
\*   a junction list parenthesized (the checker binds `=>` tighter than `/\`); the operators below
\*   are pure over their arguments and read no state variable free.

EXTENDS Naturals, FiniteSets

CONSTANTS Rsv,          \* the reservations a pool may hold, by the id place hold answers
          Cap           \* the pool's declared capacity

Kinds == {"reserve", "confirm", "cancel", "expire"}

\* A reservation's state in Provisional Commitment.
RStates == {"none", "held", "confirmed", "released", "expired"}

\* A reservation in either of these counts against the pool's allocated (Term slot-holding state).
Holding(s) == s \in {"held", "confirmed"}

VARIABLES
    cs,         \* Rsv -> the reservation's state in Provisional Commitment
    lap,        \* Rsv -> the hold's window has elapsed (its window reading is lapsed)
    alloc,      \* the pool's allocated count in Capacity Constraint Enforcement
    bnd,        \* Rsv -> a binding entry stands for the reservation
    rout,       \* Rsv -> the reserve outcome entry: none | present | aged (payload destroyed)
    cnf,        \* Rsv -> confirm outcome entries naming the reservation
    sout,       \* Rsv -> slot-returning outcome entries naming the reservation
    rel,        \* Rsv -> pool release events naming the reservation
    inv,        \* the invocation in flight: idle | reserve | confirm | cancel | expire
    tgt,        \* the reservation the invocation acts on ("none" until place hold answers one)
    fa,         \* the attestation answered
    fi,         \* the intent entry staged
    fc,         \* the pool allocate staged (reserve only)
    fh,         \* the hold placed (reserve) or the transition made (resolving action)
    fr,         \* the pool release staged (slot-returning actions only)
    fo,         \* the outcome entry staged
    viol        \* the names of the rules a step has broken

vars == <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

\* ----- pure helpers over their arguments -----

\* Whether the window reading lets the transition through: Provisional Commitment's confirm and
\* release need an open window, its expire a lapsed one.
WindowOK(k, l) == IF k = "expire" THEN l ELSE ~l

\* The count of a pool's bound reservations in a slot-holding state (Term bound slot-holding count).
BoundHolding(c, b) == Cardinality({r \in Rsv : b[r] /\ Holding(c[r])})

\* Quiescence: no [Reserve] against the pool is in flight, the reserve whose outcome entry landed
\* but whose binding entry has not yet been written among them (Term quiescence, Action wiring 78).
Quiet(i, ro, b) == (i = "idle") /\ (\A r \in Rsv : (ro[r] /= "none") => b[r])

\* An auditor's count of a pool's slot-holding reservations (Check 1.1): the reservations reached
\* by traversing the journal's reserve outcome entries, and those the binding names that the
\* traversal does not reach, each counted only if no slot-returning outcome entry names it.
AuditCount(ro, b, so) == Cardinality({r \in Rsv : ((ro[r] = "present") \/ b[r]) /\ so[r] = 0})

\* ----- state -----

\* The shape of every variable.
TypeOK ==
    /\ cs \in [Rsv -> RStates]
    /\ lap \in [Rsv -> BOOLEAN]
    /\ alloc \in 0..Cardinality(Rsv)
    /\ bnd \in [Rsv -> BOOLEAN]
    /\ rout \in [Rsv -> {"none", "present", "aged"}]
    /\ cnf \in [Rsv -> 0..2]
    /\ sout \in [Rsv -> 0..2]
    /\ rel \in [Rsv -> 0..2]
    /\ inv \in {"idle"} \cup Kinds
    /\ tgt \in Rsv \cup {"none"}
    /\ fa \in BOOLEAN
    /\ fi \in BOOLEAN
    /\ fc \in BOOLEAN
    /\ fh \in BOOLEAN
    /\ fr \in BOOLEAN
    /\ fo \in BOOLEAN
    /\ viol \subseteq {"Invariant_6_4", "Wiring_decision_3", "Action_81"}

\* No reservation, an empty pool, nothing in the journal and no invocation.
Init ==
    /\ cs = [r \in Rsv |-> "none"]
    /\ lap = [r \in Rsv |-> FALSE]
    /\ alloc = 0
    /\ bnd = [r \in Rsv |-> FALSE]
    /\ rout = [r \in Rsv |-> "none"]
    /\ cnf = [r \in Rsv |-> 0]
    /\ sout = [r \in Rsv |-> 0]
    /\ rel = [r \in Rsv |-> 0]
    /\ inv = "idle"
    /\ tgt = "none"
    /\ fa = FALSE
    /\ fi = FALSE
    /\ fc = FALSE
    /\ fh = FALSE
    /\ fr = FALSE
    /\ fo = FALSE
    /\ viol = {}

\* ----- the clock -----

\* A hold's window elapses (Term window reading, lapsed). The host reads the clock once per
\* invocation (Capability requirement 39), so time passes between invocations, not inside one.
Tick(r) ==
    /\ inv = "idle"
    /\ cs[r] = "held"
    /\ ~lap[r]
    /\ lap' = [lap EXCEPT ![r] = TRUE]
    /\ UNCHANGED <<cs, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

\* ----- the invocation: begin, then the staged writes, then commit or abort -----

\* [Reserve] begins. It names no reservation yet: place hold answers the id.
BeginReserve ==
    /\ inv = "idle"
    /\ inv' = "reserve"
    /\ tgt' = "none"
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, fa, fi, fc, fh, fr, fo, viol>>

\* A resolving action begins on a reservation. A reservation id naming no binding entry answers
\* not-known and writes nothing (Action wiring 80, 81), so it never begins.
BeginResolve(k, r) ==
    /\ inv = "idle"
    /\ bnd[r]
    /\ inv' = k
    /\ tgt' = r
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, fa, fi, fc, fh, fr, fo, viol>>

\* Actor Identity's attest answers the attestation id (Action wiring 20, 119).
Attest ==
    /\ inv /= "idle"
    /\ ~fa
    /\ fa' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fi, fc, fh, fr, fo, viol>>

\* The intent entry lands, only after the attestation (Action wiring 26).
Intent ==
    /\ inv /= "idle"
    /\ fa
    /\ ~fi
    /\ fi' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fc, fh, fr, fo, viol>>

\* [Reserve] calls the pool's allocate, only after the intent entry lands and only while the pool
\* has a slot to give (Action wiring 45 to 47, 53).
Allocate ==
    /\ inv = "reserve"
    /\ fi
    /\ ~fc
    /\ alloc < Cap
    /\ fc' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fh, fr, fo, viol>>

\* [Reserve] calls place hold, only after allocate answers (Action wiring 53, Wiring decision 2);
\* it answers the id of a fresh reservation.
Hold ==
    /\ inv = "reserve"
    /\ fc
    /\ ~fh
    /\ \E r \in Rsv :
        /\ cs[r] = "none"
        /\ tgt' = r
    /\ fh' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, fa, fi, fc, fr, fo, viol>>

\* A resolving action calls the commitment's transition, only after the intent entry lands. It goes
\* through only for a Held reservation inside the window each transition needs: confirm and release
\* an open window, expire a lapsed one. Any other answer (not-held, window-elapsed,
\* window-not-elapsed) is settled and leaves the world as it was.
Transition ==
    /\ inv \in {"confirm", "cancel", "expire"}
    /\ fi
    /\ ~fh
    /\ cs[tgt] = "held"
    /\ WindowOK(inv, lap[tgt])
    /\ fh' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fr, fo, viol>>

\* A slot-returning action calls the pool's release, only after the transition answers ok
\* (Action wiring 106). A confirm calls no pool write (Action wiring 91).
Release ==
    /\ inv \in {"cancel", "expire"}
    /\ fi
    /\ ~fr
    /\ fr' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fo, viol>>

\* The outcome entry is staged, only after the act it records: the hold for a [Reserve] (Action
\* wiring 62), the confirm for a confirm (Action wiring 92), the pool release for a slot-returning
\* action (Action wiring 110).
Outcome ==
    /\ inv /= "idle"
    /\ ~fo
    /\ ((inv \in {"reserve", "confirm"} /\ fh) \/ (inv \in {"cancel", "expire"} /\ fr))
    /\ fo' = TRUE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, viol>>

\* The action's writes commit together (Execution Contract Database 1). A [Reserve] leaves a Held
\* reservation, one more allocated and a reserve outcome entry, and no binding entry yet; a confirm
\* leaves the slot where it was; a cancel or an expire returns the slot once, and a pool with
\* nothing allocated refuses the release, which fails the whole action (Action wiring 120). The step
\* names the rules it breaks if it writes for an unbound reservation or moves a Confirmed one.
Commit ==
    /\ inv /= "idle"
    /\ fo
    /\ ((inv \in {"cancel", "expire"}) => (alloc > 0))
    /\ cs' = [cs EXCEPT ![tgt] = CASE inv = "reserve" -> "held"
                                    [] inv = "confirm" -> "confirmed"
                                    [] inv = "cancel" -> "released"
                                    [] OTHER -> "expired"]
    /\ lap' = [lap EXCEPT ![tgt] = IF inv = "reserve" THEN FALSE ELSE lap[tgt]]
    /\ alloc' = IF inv = "reserve" THEN alloc + 1
                ELSE IF inv \in {"cancel", "expire"} THEN alloc - 1
                ELSE alloc
    /\ rout' = [rout EXCEPT ![tgt] = IF inv = "reserve" THEN "present" ELSE rout[tgt]]
    /\ cnf' = [cnf EXCEPT ![tgt] = IF inv = "confirm" THEN cnf[tgt] + 1 ELSE cnf[tgt]]
    /\ sout' = [sout EXCEPT ![tgt] = IF inv \in {"cancel", "expire"} THEN sout[tgt] + 1 ELSE sout[tgt]]
    /\ rel' = [rel EXCEPT ![tgt] = IF inv \in {"cancel", "expire"} THEN rel[tgt] + 1 ELSE rel[tgt]]
    /\ viol' = viol \cup (IF inv /= "reserve" /\ ~bnd[tgt] THEN {"Action_81"} ELSE {})
                     \cup (IF inv /= "reserve" /\ cs[tgt] = "confirmed" THEN {"Wiring_decision_3"} ELSE {})
    /\ inv' = "idle"
    /\ tgt' = "none"
    /\ fa' = FALSE
    /\ fi' = FALSE
    /\ fc' = FALSE
    /\ fh' = FALSE
    /\ fr' = FALSE
    /\ fo' = FALSE
    /\ UNCHANGED <<bnd>>

\* The invocation ends with nothing written: a refusal, a constituent's storage failure, or an
\* answer a constituent decides and the retry model settles (Execution Contract Read 4).
Abort ==
    /\ inv /= "idle"
    /\ inv' = "idle"
    /\ tgt' = "none"
    /\ fa' = FALSE
    /\ fi' = FALSE
    /\ fc' = FALSE
    /\ fh' = FALSE
    /\ fr' = FALSE
    /\ fo' = FALSE
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, viol>>

\* ----- outside every action's transaction -----

\* The binding entry is written, only after the reserve outcome entry lands (Action wiring 78), or
\* rebuilt from the journal on a miss (Composition state 10): the pool id comes from the reserve
\* outcome entry (Composition state 11), which therefore must still carry its payload.
Bind(r) ==
    /\ rout[r] = "present"
    /\ ~bnd[r]
    /\ bnd' = [bnd EXCEPT ![r] = TRUE]
    /\ UNCHANGED <<cs, lap, alloc, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

\* A reserve outcome entry ages past the audit horizon and its payload may be destroyed, but only
\* once the reservation's binding entry stands (Capability requirement 48).
Age(r) ==
    /\ rout[r] = "present"
    /\ bnd[r]
    /\ rout' = [rout EXCEPT ![r] = "aged"]
    /\ UNCHANGED <<cs, lap, alloc, bnd, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

\* A slot-returning outcome entry may be destroyed only while no binding entry stands
\* (Capability requirement 49). A resolved reservation has one and the binding is never removed
\* (Composition state 6), so the step is never enabled: the rule is a bound on this step.
PurgeReturn(r) ==
    /\ sout[r] > 0
    /\ ~bnd[r]
    /\ sout' = [sout EXCEPT ![r] = 0]
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

\* [Query Reservation] reads the state, the binding's pool and the slot-held reading, and writes no
\* journal entry (Action wiring 114 to 118, Invariant 6.4).
Query(r) ==
    /\ inv = "idle"
    /\ UNCHANGED <<cs, lap, alloc, bnd, rout, cnf, sout, rel, inv, tgt, fa, fi, fc, fh, fr, fo, viol>>

Next ==
    \/ BeginReserve
    \/ Attest
    \/ Intent
    \/ Allocate
    \/ Hold
    \/ Transition
    \/ Release
    \/ Outcome
    \/ Commit
    \/ Abort
    \/ \E r \in Rsv :
        \/ Tick(r)
        \/ Bind(r)
        \/ Age(r)
        \/ PurgeReturn(r)
        \/ Query(r)
        \/ \E k \in {"confirm", "cancel", "expire"} : BeginResolve(k, r)

Spec == Init /\ [][Next]_vars

\* ----- the invariants -----

\* Invariant 1.1: at quiescence the pool's allocated never passes the bound slot-holding count.
Invariant_1_1 == Quiet(inv, rout, bnd) => (alloc <= BoundHolding(cs, bnd))

\* Invariant 1.5: at quiescence the bound slot-holding count never passes the pool's allocated.
Invariant_1_5 == Quiet(inv, rout, bnd) => (BoundHolding(cs, bnd) <= alloc)

\* Check 1.1: the auditor's count over the journal and the binding equals the pool's allocated. It
\* is read at every idle state, the unbound window included, which the traversal covers.
Check_1_1 == (inv = "idle") => (AuditCount(rout, bnd, sout) = alloc)

\* Invariant 2.1: no reservation gets two pool releases or two slot-returning outcome entries
\* (Check 3.1).
Invariant_2_1 == \A r \in Rsv : rel[r] <= 1 /\ sout[r] <= 1

\* Invariant 3.1: the pool's Confirmed reservations never pass its capacity.
Invariant_3_1 == Cardinality({r \in Rsv : cs[r] = "confirmed"}) <= Cap

\* Invariant 4.1: no reservation was confirmed with its window lapsed. A hold lapses only while
\* Held, so a Confirmed reservation carrying the lapsed reading was confirmed after the lapse.
Invariant_4_1 == \A r \in Rsv : (cs[r] = "confirmed") => ~lap[r]

\* Invariant 4.2: a lapsed hold resolves only through [Expire Reservation]: a Released reservation
\* was cancelled inside its window.
Invariant_4_2 == \A r \in Rsv : (cs[r] = "released") => ~lap[r]

\* Action wiring 87: [Expire Reservation] resolves only a lapsed hold.
Action_87 == \A r \in Rsv : (cs[r] = "expired") => lap[r]

\* Invariant 6.1: every committed state change carries exactly one outcome entry: a reserve outcome
\* entry for each reservation past none, a confirm outcome entry for each Confirmed one, a
\* slot-returning outcome entry for each Released or Expired one, and no entry for the rest.
Invariant_6_1 ==
    \A r \in Rsv :
        /\ ((cs[r] = "none") => (rout[r] = "none"))
        /\ ((cs[r] /= "none") => (rout[r] /= "none"))
        /\ (cnf[r] = (IF cs[r] = "confirmed" THEN 1 ELSE 0))
        /\ (sout[r] = (IF cs[r] \in {"released", "expired"} THEN 1 ELSE 0))

\* Invariant 6.4: the read-only query writes no journal entry. Read from the step.
Invariant_6_4 == "Invariant_6_4" \notin viol

\* Invariant 8.1: no write is made before Actor Identity's attest answers (Action wiring 21).
Invariant_8_1 == (fi \/ fc \/ fh \/ fr \/ fo) => fa

\* Action wiring 26, 45, 90, 97, 98: no constituent call and no outcome entry before the intent entry.
Action_26_45 == (fc \/ fh \/ fr \/ fo) => fi

\* Wiring decision 2, Action wiring 53: [Reserve] places no hold before allocating its slot.
Wiring_decision_2 == (inv = "reserve") => (fh => fc)

\* Action wiring 62, 92, 110: the outcome entry is staged after the act it records.
Action_62_92_110 ==
    /\ ((inv \in {"reserve", "confirm"}) => (fo => fh))
    /\ ((inv \in {"cancel", "expire"}) => (fo => fr))

\* Action wiring 106: the pool release follows the transition's ok.
Action_106 == fr => fh

\* Action wiring 91: [Confirm Reservation] makes no pool write.
Action_91 == (inv = "confirm") => (~fc /\ ~fr)

\* Wiring decision 6: a pool release names a reservation only for a slot-returning transition: a
\* reservation has a release event exactly when it is Released or Expired.
Wiring_decision_6 ==
    \A r \in Rsv : (rel[r] > 0) = (cs[r] \in {"released", "expired"})

\* Wiring decision 3 (Non-goal 7): a Confirmed reservation keeps its slot and never leaves
\* Confirmed. Read from the step.
Wiring_decision_3 == "Wiring_decision_3" \notin viol

\* Action wiring 80, 81: a resolving action writes nothing for a reservation with no binding entry.
Action_81 == "Action_81" \notin viol

\* Composition state 6: a resolved reservation keeps its binding entry.
Composition_state_6 ==
    \A r \in Rsv : (cs[r] \in {"confirmed", "released", "expired"}) => bnd[r]

\* Capability requirement 48: a reserve outcome entry with no binding entry keeps its payload,
\* so the rebuild can take the pool id from it.
Capability_48 == \A r \in Rsv : ((rout[r] /= "none") /\ ~bnd[r]) => (rout[r] = "present")

====

---- MODULE propagate-consent-revocation-downstream-probe-history-answered ----
\* EXPECT: violation — reachability probe: a consent history is answered.
\* Grace Commons — Propagate Consent Revocation Downstream.
\* Consent + Permissions + Audit Trail (substrate) + Retention Window.
\* Spec-level formal sibling of compositions/propagate-consent-revocation-downstream.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* Re-derived 2026-11-09 (the first model, 2026-08-27, checked a withdrawal's revoke, propagation
\* event and compensation over a single-writer invocation with no terminus). The page has since
\* moved onto the Database contract (Execution Contract Database 1 to 5): each action's intent,
\* constituent writes and outcome event commit together, so there is no half-written withdrawal to
\* interleave with a scan. What the page keeps, and this model checks, is the arc of the acts
\* against the Consent records, the registered set a withdrawal carries, the three indexes outside
\* every transaction, and the order of the writes inside each action. The reconciliation (the
\* clock, the cadence, the run bound, the compensation and the escalation) is the second model,
\* beside this one: propagate-consent-revocation-downstream-reconciliation.tla.
\*
\* WHAT THIS MODEL CHECKS
\* Two Consent records for one subject and purpose, two downstream pairs for the first, and
\* whatever order the actions, the index writes and the horizon's purge of a registration event take:
\*   - Invariant 1.1     [Processing Permitted] answers permitted only if the consent check answers
\*                       granted.
\*   - Invariant 1.3     two Granted records never carry one subject reference and purpose.
\*   - Invariant 3.1     a propagation event names a Revoked record; Wiring decision 1 puts the
\*                       event after the revoke answers revoked.
\*   - Invariant 3.2     two propagation events never carry one consent id.
\*   - Invariant 3.3     a propagation event's set is the registered set at the event's boundary:
\*                       the pairs whose registration event precedes the withdrawal's intent, the
\*                       purged downstream entries included, a registration after the intent left out.
\*   - Invariant 4.1     a binding names a registration event.
\*   - Invariant 5.1     the lifecycle resolves from the records: a grant intent and event with a
\*                       Granted record, a withdrawal intent and event (or the owed outcome) with a
\*                       Revoked one, an access event with every history answered.
\*   - Invariant 6.1     a governed consent carries its retention.
\*   - Invariant 7.1     no constituent write for an actor the permission check denied.
\*   - Invariant 8.1 to 8.4  no grant write, revoke write, binding or history answer before Audit
\*                       Trail validates the caller's credential.
\*   - Action wiring 24, 25, 29, 30, 31; Composition state 6, 13, 14   an index entry is written
\*                       after the event it derives from lands; the propagation set is derived from
\*                       the registration events and the purged entries, never from a live entry;
\*                       a derivation adds a binding it finds missing; a binding is never removed;
\*                       a purged entry is truth-bearing.
\*
\* BOUND
\* Cs = {c1, c2}, Qs = {q1, q2}, and C1 = c1 the consent registrations bind: the second consent meets
\* the first one's grant, withdrawal and the re-grant that follows it (Examples, *Re-consent path*),
\* and a registration may fall before or after a withdrawal's intent. A registration on the second
\* consent adds no rule the first does not already cross, and doubles the state space. One history
\* read: a second raises the longest path past the checker's depth cap of 40. Exhaustive.
\*
\* HOW AN ACTION IS READ
\* The page puts each action's writes in one transaction (Database 1), and a store runs the
\* transactions one after another (Database 2). So at most one invocation is in flight, its permission
\* check, credential check, derivation, constituent write and outcome event are staged as flags
\* (`ip` and `icr` are what the permission check and the credential check answer; `fd`, `fi`, `fw`,
\* `fe` are the derivation, the intent, the constituent write and the event), and the world changes
\* only at the commit step, all together; a refusal leaves the world as it was (Execution Contract
\* Read 4). The flags are separate booleans, not a position in a line, so a step that skips its
\* predecessor is a state the order invariants can see. The three indexes are outside every
\* transaction (Composition state 8): a binding is written after its registration event lands, and
\* the horizon purges a registration event only once its binding stands. A property of a step (a gate
\* that disagrees with the consent check, a write for a denied actor, a binding removed) is a name the
\* step adds to `viol`; the named invariants say `viol` does not hold their name. A step reads the
\* world, never the rule it is checked against.
\*
\* SCOPE (named)
\* - Not modeled: the Permissions scopes and the retention policy (the permission check is a boolean
\*   the environment answers; the placement always answers a retention id), the Consent expiry, the
\*   record read's answers beyond Retained and Purged, the key entries (the subject index and the
\*   retention index) and their rebuild, the field caps and the envelope, and the clock. The horizon
\*   purges a registration event only after its binding stands: the reconciliation's third leg
\*   repairs a missing binding within the cadence plus the run bound, and the audit horizon exceeds
\*   the escalation reach (Capability requirement 34), so no run is late for the purge.
\* - A call that gives no answer decides nothing (Execution Contract Error model 1) and is the
\*   abort step. A repeat registration records an event and changes no binding (Action wiring 22,
\*   Composition state 5): the model takes it as a call that leaves the world as it was.
\* - Recording-failure carrying outcome is modeled for a withdrawal only: the Consent record stands
\*   and the event is owed (Audit arm 12, 15, 17). What closes it is the reconciliation model.
EXTENDS Naturals, FiniteSets

CONSTANTS Cs, Qs, C1

\* What the permission check and the credential check answer for an invocation: the environment's.
Perms == {"ok", "denied"}
Creds == {"ok", "bad"}

VARIABLES cs, gi, ge, ret, wi, pe, pset, bset, ow, re, bind, hEv, hAns,
          ik, ic, iq, ip, icr, fd, dset, fi, fw, fe, fo, viol
vars == <<cs, gi, ge, ret, wi, pe, pset, bset, ow, re, bind, hEv, hAns,
          ik, ic, iq, ip, icr, fd, dset, fi, fw, fe, fo, viol>>

\* The Consent records in Granted: the consent check for the one subject reference and purpose
\* answers granted exactly when there is one (Consent's check evaluates the grant).
Granted == {c \in Cs : cs[c] = "granted"}

\* The pairs a registration event carries that the log still holds in full, and the pairs whose
\* event the horizon has purged and the downstream entry still holds (Term registered set, Action
\* wiring 29).
LiveSet(c) == {q \in Qs : re[c][q] = 1}
PurgedSet(c) == {q \in Qs : re[c][q] = 2 /\ bind[c][q]}

\* The pairs whose registration event has landed: what a withdrawal's transaction reads, a
\* registration that lands after the withdrawal commits following its intent in the Event Log. This
\* is the truth Invariant 3.3 states, held per consent as the ghost `bset` at the commit.
Registered(c) == {q \in Qs : re[c][q] # 0}

TypeOK ==
    /\ cs \in [Cs -> {"none", "granted", "revoked"}]
    /\ gi \in [Cs -> BOOLEAN]
    /\ ge \in [Cs -> 0..1]
    /\ ret \in [Cs -> BOOLEAN]
    /\ wi \in [Cs -> BOOLEAN]
    /\ pe \in [Cs -> 0..2]
    /\ pset \in [Cs -> SUBSET Qs]
    /\ bset \in [Cs -> SUBSET Qs]
    /\ ow \in [Cs -> BOOLEAN]
    /\ re \in [Cs -> [Qs -> 0..2]]
    /\ bind \in [Cs -> [Qs -> BOOLEAN]]
    /\ hEv \in 0..2
    /\ hAns \in 0..2
    /\ ik \in {"none", "grant", "reg", "wd", "hist"}
    /\ ic \in Cs \cup {"-"}
    /\ iq \in Qs \cup {"-"}
    /\ ip \in Perms
    /\ icr \in Creds
    /\ fd \in BOOLEAN
    /\ dset \subseteq Qs
    /\ fi \in BOOLEAN
    /\ fw \in BOOLEAN
    /\ fe \in BOOLEAN
    /\ fo \in {"none", "refused"}
    /\ viol \subseteq {"gate-disagrees", "denied-write", "grant-bad-credential",
                       "revoke-bad-credential", "reg-bad-credential", "unbind"}

Init ==
    /\ cs = [c \in Cs |-> "none"]
    /\ gi = [c \in Cs |-> FALSE]
    /\ ge = [c \in Cs |-> 0]
    /\ ret = [c \in Cs |-> FALSE]
    /\ wi = [c \in Cs |-> FALSE]
    /\ pe = [c \in Cs |-> 0]
    /\ pset = [c \in Cs |-> {}]
    /\ bset = [c \in Cs |-> {}]
    /\ ow = [c \in Cs |-> FALSE]
    /\ re = [c \in Cs |-> [q \in Qs |-> 0]]
    /\ bind = [c \in Cs |-> [q \in Qs |-> FALSE]]
    /\ hEv = 0
    /\ hAns = 0
    /\ ik = "none"
    /\ ic = "-"
    /\ iq = "-"
    /\ ip = "ok"
    /\ icr = "ok"
    /\ fd = FALSE
    /\ dset = {}
    /\ fi = FALSE
    /\ fw = FALSE
    /\ fe = FALSE
    /\ fo = "none"
    /\ viol = {}

\* The world: everything an invocation commits or the indexes hold.
World == <<cs, gi, ge, ret, wi, pe, pset, bset, ow, re, bind, hEv, hAns, viol>>

\* A call starts. The permission check and the credential check answer whatever the environment
\* does; nothing is written yet (Action wiring 1 to 3). Fields a call does not use hold "-".
Start(k, c, q, p, cr) ==
    /\ ik = "none"
    /\ ik' = k
    /\ ic' = c
    /\ iq' = q
    /\ ip' = p
    /\ icr' = cr
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED World

\* A grant is for a consent id not yet minted.
BeginGrant(c, p, cr) ==
    /\ cs[c] = "none"
    /\ ~gi[c]
    /\ Start("grant", c, "-", p, cr)

\* A registration is for a consent the subject index resolves and a pair it does not hold yet.
BeginReg(q, p, cr) ==
    /\ cs[C1] # "none"
    /\ re[C1][q] = 0
    /\ Start("reg", C1, q, p, cr)

\* A withdrawal is for a consent the subject index resolves.
BeginWd(c, p, cr) ==
    /\ cs[c] # "none"
    /\ Start("wd", c, "-", p, cr)

\* A history read is for a subject; the model has the one.
BeginHist(p, cr) ==
    /\ Start("hist", "-", "-", p, cr)

\* A refusal: a permission denied, a credential not validated, a storage failure or a call that
\* gives no answer. Nothing is written (Execution Contract Read 4), the staged flags are dropped.
Abort ==
    /\ ik # "none"
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED World

\* A withdrawal derives the propagation set before its intent (Action wiring 28 to 31): from the
\* registration events the log still holds and the purged downstream entries, never from a live
\* entry alone.
Derive ==
    /\ ik = "wd"
    /\ ip = "ok"
    /\ ~fd
    /\ fd' = TRUE
    /\ dset' = LiveSet(ic) \cup PurgedSet(ic)
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fi, fw, fe, fo>>
    /\ UNCHANGED World

\* The intent: Audit Trail validates the caller's credential at the grant intent and the withdrawal
\* intent, before any Consent write (Action wiring 4, 32; Invariant 8.1, 8.2). A call whose
\* permission check denied or whose credential did not validate cannot get here (Action wiring 3).
Intent ==
    /\ ik \in {"grant", "wd"}
    /\ ~fi
    /\ ip = "ok"
    /\ icr = "ok"
    /\ (ik = "wd") => fd
    /\ fi' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fw, fe, fo>>
    /\ UNCHANGED World

\* The grant write, after the consent check answers a withheld state (Action wiring 7 to 9) and the
\* retention placement (Action wiring 13): the consent record and its retention (Invariant 6.1).
WriteGrant ==
    /\ ik = "grant"
    /\ fi
    /\ ~fw
    /\ Granted = {}
    /\ fw' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fe, fo>>
    /\ UNCHANGED World

\* Where a record is Granted for the subject and purpose the call answers already-granted
\* (Action wiring 8, Invariant 1.3): the intent stands and nothing else is written.
AlreadyGranted ==
    /\ ik = "grant"
    /\ fi
    /\ ~fw
    /\ Granted # {}
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED World

\* The revoke write, after the intent (Action wiring 34).
WriteRevoke ==
    /\ ik = "wd"
    /\ fi
    /\ ~fw
    /\ cs[ic] = "granted"
    /\ fw' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fe, fo>>
    /\ UNCHANGED World

\* A record already Revoked answers already-revoked: the intent stands, no outcome event is written
\* (Action wiring 35).
AlreadyRevoked ==
    /\ ik = "wd"
    /\ fi
    /\ ~fw
    /\ cs[ic] = "revoked"
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED World

\* The outcome event of a grant, after the constituent write it records (Action wiring 17).
EventGrant ==
    /\ ik = "grant"
    /\ fw
    /\ ~fe
    /\ fe' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fw, fo>>
    /\ UNCHANGED World

\* The outcome event of a withdrawal, after the revoke (Action wiring 41, Wiring decision 1). It may
\* be refused with recording-failure carrying outcome: an answer and not a refusal, so the Consent
\* record stands and the event is owed (Audit arm 12, 15, 17).
EventWd(o) ==
    /\ ik = "wd"
    /\ fw
    /\ ~fe
    /\ fo = "none"
    /\ o \in {"ok", "refused"}
    /\ fe' = (o = "ok")
    /\ fo' = IF o = "ok" THEN "none" ELSE "refused"
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fw>>
    /\ UNCHANGED World

\* The registration event, the one audit write of a registration: Audit Trail validates the
\* caller's credential there (Invariant 8.3).
EventReg ==
    /\ ik = "reg"
    /\ ~fe
    /\ ip = "ok"
    /\ icr = "ok"
    /\ fe' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fw, fo>>
    /\ UNCHANGED World

\* The access event of a history read, the one audit write of the read (Invariant 8.4).
EventHist ==
    /\ ik = "hist"
    /\ ~fe
    /\ ip = "ok"
    /\ icr = "ok"
    /\ fe' = TRUE
    /\ UNCHANGED <<ik, ic, iq, ip, icr, fd, dset, fi, fw, fo>>
    /\ UNCHANGED World

\* The commit: the staged writes land together (Execution Contract Database 1), and the world
\* changes all at once. Each branch names what its action writes.
CommitGrant ==
    /\ ik = "grant"
    /\ fi
    /\ fw
    /\ fe
    /\ cs' = [cs EXCEPT ![ic] = "granted"]
    /\ gi' = [gi EXCEPT ![ic] = TRUE]
    /\ ge' = [ge EXCEPT ![ic] = 1]
    /\ ret' = [ret EXCEPT ![ic] = TRUE]
    /\ viol' = viol \cup (IF ip = "denied" THEN {"denied-write"} ELSE {})
                       \cup (IF icr = "bad" THEN {"grant-bad-credential"} ELSE {})
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED <<wi, pe, pset, bset, ow, re, bind, hEv, hAns>>

CommitWd ==
    /\ ik = "wd"
    /\ fi
    /\ fw
    /\ (fe \/ fo = "refused")
    /\ cs' = [cs EXCEPT ![ic] = "revoked"]
    /\ wi' = [wi EXCEPT ![ic] = TRUE]
    /\ bset' = [bset EXCEPT ![ic] = Registered(ic)]
    /\ pe' = [pe EXCEPT ![ic] = IF fe THEN pe[ic] + 1 ELSE pe[ic]]
    /\ pset' = [pset EXCEPT ![ic] = IF fe THEN dset ELSE pset[ic]]
    /\ ow' = [ow EXCEPT ![ic] = (fo = "refused")]
    /\ bind' = [bind EXCEPT ![ic] = [q \in Qs |-> bind[ic][q] \/ (re[ic][q] = 1)]]
    /\ viol' = viol \cup (IF ip = "denied" THEN {"denied-write"} ELSE {})
                       \cup (IF icr = "bad" THEN {"revoke-bad-credential"} ELSE {})
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED <<gi, ge, ret, re, hEv, hAns>>

CommitReg ==
    /\ ik = "reg"
    /\ fe
    /\ re' = [re EXCEPT ![ic][iq] = 1]
    /\ viol' = viol \cup (IF ip = "denied" THEN {"denied-write"} ELSE {})
                       \cup (IF icr = "bad" THEN {"reg-bad-credential"} ELSE {})
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED <<cs, gi, ge, ret, wi, pe, pset, bset, ow, bind, hEv, hAns>>

CommitHist ==
    /\ ik = "hist"
    /\ fe
    /\ hEv < 1
    /\ hEv' = hEv + 1
    /\ hAns' = hAns + 1
    /\ ik' = "none"
    /\ fd' = FALSE
    /\ dset' = {}
    /\ fi' = FALSE
    /\ fw' = FALSE
    /\ fe' = FALSE
    /\ fo' = "none"
    /\ UNCHANGED <<ic, iq, ip, icr>>
    /\ UNCHANGED <<cs, gi, ge, ret, wi, pe, pset, bset, ow, re, bind, viol>>

\* The downstream entry, outside every transaction: written only after the registration event lands
\* (Action wiring 25), and the same write repairs a binding a crash lost (Reconciliation 22).
Bind(q) ==
    /\ re[C1][q] # 0
    /\ ~bind[C1][q]
    /\ bind' = [bind EXCEPT ![C1][q] = TRUE]
    /\ UNCHANGED <<cs, gi, ge, ret, wi, pe, pset, bset, ow, re, hEv, hAns,
                   ik, ic, iq, ip, icr, fd, dset, fi, fw, fe, fo, viol>>

\* The audit horizon destroys a registration event's payload (Retained to Purged) once its binding
\* stands; the downstream entry then carries the pair on its own (Composition state 13, 14, 16, 18).
Purge(q) ==
    /\ re[C1][q] = 1
    /\ bind[C1][q]
    /\ re' = [re EXCEPT ![C1][q] = 2]
    /\ UNCHANGED <<cs, gi, ge, ret, wi, pe, pset, bset, ow, bind, hEv, hAns,
                   ik, ic, iq, ip, icr, fd, dset, fi, fw, fe, fo, viol>>

\* The gate: [Processing Permitted] answers permitted exactly when the consent check answers granted,
\* and writes nothing (Action wiring 53 to 57). The step adds a name to `viol` where the answer it
\* gives is not the consent check's.
Gate ==
    /\ ik = "none"
    /\ viol' = viol \cup (IF (IF Granted # {} THEN "permitted" ELSE "not-permitted")
                                 # (IF Granted # {} THEN "permitted" ELSE "not-permitted")
                          THEN {"gate-disagrees"} ELSE {})
    /\ UNCHANGED <<cs, gi, ge, ret, wi, pe, pset, bset, ow, re, bind, hEv, hAns,
                   ik, ic, iq, ip, icr, fd, dset, fi, fw, fe, fo>>

Next ==
    \/ \E c \in Cs : \E p \in Perms : \E cr \in Creds : BeginGrant(c, p, cr)
    \/ \E q \in Qs : \E p \in Perms : \E cr \in Creds : BeginReg(q, p, cr)
    \/ \E c \in Cs : \E p \in Perms : \E cr \in Creds : BeginWd(c, p, cr)
    \/ \E p \in Perms : \E cr \in Creds : BeginHist(p, cr)
    \/ Abort
    \/ Derive
    \/ Intent
    \/ WriteGrant
    \/ AlreadyGranted
    \/ WriteRevoke
    \/ AlreadyRevoked
    \/ EventGrant
    \/ \E o \in {"ok", "refused"} : EventWd(o)
    \/ EventReg
    \/ EventHist
    \/ CommitGrant
    \/ CommitWd
    \/ CommitReg
    \/ CommitHist
    \/ \E q \in Qs : Bind(q)
    \/ \E q \in Qs : Purge(q)
    \/ Gate
Spec == Init /\ [][Next]_vars

\* --- composition-level safety invariants ---

\* Invariant 1.1: the gate answers permitted only if the consent check answers granted.
Invariant_1_1 == ~("gate-disagrees" \in viol)

\* Invariant 1.3: two Granted records never carry one subject reference and purpose.
Invariant_1_3 == Cardinality(Granted) <= 1

\* Invariant 3.1: every propagation event names a consent the Consent records hold in Revoked
\* (and Wiring decision 1: the event follows the revoke).
Invariant_3_1 == \A c \in Cs : (pe[c] >= 1) => (cs[c] = "revoked")

\* Invariant 3.2: two propagation events never carry one consent id.
Invariant_3_2 == \A c \in Cs : pe[c] <= 1

\* Invariant 3.3: a propagation event's set equals the registered set at the event's boundary:
\* the pairs whose registration event precedes the withdrawal's intent (the ghost `bset`).
Invariant_3_3 == \A c \in Cs : (pe[c] >= 1) => (pset[c] = bset[c])

\* Invariant 4.1: every binding carries a registration event carrying its pair and consent id.
Invariant_4_1 == \A c \in Cs : \A q \in Qs : bind[c][q] => (re[c][q] # 0)

\* Invariant 5.1: the lifecycle resolves from the records: a Granted or Revoked record has its grant
\* intent and grant event; a Revoked one its withdrawal intent and its propagation event or the
\* owed outcome; every history answered has its access event.
Invariant_5_1 ==
    /\ \A c \in Cs : (cs[c] # "none") => (gi[c] /\ ge[c] = 1)
    /\ \A c \in Cs : (cs[c] = "revoked") => (wi[c] /\ (pe[c] >= 1 \/ ow[c]))
    /\ hAns <= hEv

\* Invariant 6.1: every governed consent carries its consent retention.
Invariant_6_1 == \A c \in Cs : (cs[c] # "none") => ret[c]

\* Invariant 7.1: no constituent write for an actor the permission check denied.
Invariant_7_1 == ~("denied-write" \in viol)

\* Invariant 8.1 to 8.4: no grant write, revoke write, binding or history answer before Audit Trail
\* validates the caller's credential.
Invariant_8_1 == ~("grant-bad-credential" \in viol)
Invariant_8_2 == ~("revoke-bad-credential" \in viol)
Invariant_8_3 == ~("reg-bad-credential" \in viol)
Invariant_8_4 == hAns <= hEv

\* Action wiring 17, 41, Wiring decision 1: the staged order inside an action. An event is staged
\* only after the constituent write it records, and the write only after the intent.
Action_wiring_order ==
    /\ (ik \in {"grant", "wd"} /\ fw) => fi
    /\ (ik \in {"grant", "wd"} /\ fe) => fw

\* Composition state 6: a binding is never removed.
Composition_state_6 == ~("unbind" \in viol)

\* Composition state 13, 14: a purged entry is truth-bearing: a purged registration event always
\* has the downstream entry that carries its pair.
Composition_state_13 == \A c \in Cs : \A q \in Qs : (re[c][q] = 2) => bind[c][q]

\* An owed outcome is always a Revoked record with no event.
Owed_outcome == \A c \in Cs : ow[c] => (cs[c] = "revoked" /\ pe[c] = 0)

Probe_history == ~(hAns = 1)
====

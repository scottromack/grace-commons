---- MODULE authenticated-actor-buggy-unlogged ----
\* Grace Commons — Authenticated Actor: the namespace binding with its re-entry arm, the
\* cascade gate inside the attesting transaction, rotation, lapse, a revoke whose clock
\* reading precedes its commit, and a new credential registered for a bound principal.
\* Spec-level formal sibling of compositions/authenticated-actor.md. Derived validator;
\* the English spec is the single source of truth. On any disagreement, diagnose per the
\* entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE PRINCIPAL, two actor references, three credential ids and two attestation ids, each
\* id taken lowest first, so a later id was always registered later and the pair's current
\* credential is its highest effective-active id (Term current credential; Credential
\* Operation 70). One credential type. Two actor references racing for the principal stand
\* for two principals racing for one actor reference: the two maps are symmetric.
\*
\* ONE TRANSACTION PER ACTION (Execution Contract Database 1, 2; Capability requirement 12).
\* A registration's guard, its Credential register or verify and its binding commit as one
\* step (Action wiring 2 to 9; with GuardInTxn = FALSE the guard is read in one step and the
\* binding written in a later one, -buggy-race). An attestation's gate read, Actor
\* Identity's attest and the success entry commit as one step (Action wiring 17 to 24; with
\* GateInTxn = FALSE the gate is read in one step and the attestation written in a later
\* one, -buggy-staleread; with LogInTxn = FALSE the attestation can commit without its
\* entry, -buggy-unlogged). A storage failure commits nothing and is no step (Action wiring
\* 11, 32, 40; Invariant 4.2). A namespace conflict, an invalid credential and not-bound
\* write nothing the model tracks.
\*
\* THE RE-ENTRY ARM (Action wiring 5 to 7): where the pair already holds an effective-active
\* credential, Credential's register answers duplicate-active-credential and the registration
\* binds the current credential only if the presenter proves possession through Credential's
\* verify (with Possession = FALSE it binds on the presenter's say-so, -buggy-adopt).
\*
\* AROUND THE COMPOSITION: the deployment revokes and rotates through Credential's own
\* actions (Composes 6, 7; Composition note 4) and registers a credential for the principal
\* through Credential's own register (Composition note 7), before the principal is bound
\* (the credential the re-entry arm adopts) or after its credential was revoked or lapsed
\* (the credential that opens the gate again, Composes 9). A credential lapses by the clock
\* (Credential's window reading) and never reads live again.
\*
\* THE CLOCK is kept only as the order of readings. A revoke takes its reading (revoked_at)
\* in one step and commits in a later one; an attestation that commits in between takes its
\* reading (attested_at) after the revoke's, and serializes before the revoke, which read a
\* record the attestation did not write: Database 2 orders the two by the store, not by the
\* clock.
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1     every attestation's gate credential stood effective-active at the
\*              attestation's commit, computed from the state the commit wrote over, not from
\*              the guard (Invariant 1.1; Check 2.2's reading at the entry's commit).
\*   Inv3       the principal binding and its inverse agree, each injective (Invariant 3.1 to
\*              3.3; Check 1.1 to 1.3).
\*   Inv4       every attestation carries its success entry, and the entry names a credential
\*              of the attestation's principal (Invariant 4.1, 4.3; Check 2.1, 3.1).
\*   AuthBinding no binding adopted an existing credential without a verified presenter
\*              (Action wiring 5 to 7; the section titled Authentication precedence in
\*              pressure-testing.md).
\*   CnaEntry   every credential-not-active entry names the pair's last credential, which did
\*              not stand effective-active at the entry's commit (Action wiring 18, 34; Check
\*              3.2), as the page stands; open line 2026-10-27-a asks whether Execution
\*              Contract Read 4 leaves a refused call's entry so.
\*
\* THE RULES, as constants, each TRUE here; each twin is this module with one turned FALSE:
\*   GateInTxn   the gate read and the attestation commit together (Database 2;
\*               Action wiring 19)                                        -buggy-staleread
\*   GuardInTxn  the namespace guard and the binding commit together (Database 2;
\*               Action wiring 2 to 4)                                    -buggy-race
\*   LogInTxn    an attestation commits with its success entry (Database 1;
\*               Action wiring 24, 25)                                    -buggy-unlogged
\*   Possession  the re-entry arm binds only after verify answers verified
\*               (Action wiring 5 to 7)                                   -buggy-adopt
\*
\* THE PROBES, each this module with one deliberate falsehood added to its configuration:
\*   -probe-attest     an attestation stands.
\*   -probe-rotated    an attestation's gate credential is newer than a rotated credential of
\*                     the principal: rotation keeps the surface open (the rotation example;
\*                     Composes 9, 10).
\*   -probe-reentry    a binding adopts an existing credential its presenter proved.
\*   -probe-refused    a credential-not-active entry is written.
\*   -probe-stampgap   an attestation whose reading came after its credential's revoke reading
\*                     stands over a credential now revoked, Inv1_1 held: a stamp proves nothing
\*                     alone, so Check 2.2 reads the credential at the entry's commit (the breach
\*                     scenario).
\*   -probe-reopen     an attestation's gate credential was registered after an earlier
\*                     credential of the principal was revoked: a new credential opens the gate,
\*                     which the deleted Invariant 1.3 forbade.
\*
\* NOT MODELLED: the boundary predicate and its invalid-request; not-bound's entry; Actor
\* Identity's registry-unavailable and invalid-credential (each lands before any write, its
\* entry naming the current credential as a success entry does); the attest credential and
\* secret-surface separation (Invariant 2, a deployment obligation); the verify action (a
\* read); clock values, the clock offset allowance and a second seam's clock; a second
\* principal and a second credential type; registration instants that tie or run backward
\* (Credential Operation 69, 70).

EXTENDS Naturals, FiniteSets

CONSTANTS GateInTxn, GuardInTxn, LogInTxn, Possession

P == 1..1
X == 1..2
C == 1..3
A == 1..2
NONE == 0

VARIABLES
    cstat,    \* C -> "free" | "active" | "rotated" | "revoked": Credential's stored status
    cown,     \* C -> P \cup {NONE}: the principal reference the credential carries
    clapsed,  \* C -> BOOLEAN: an active credential reading lapsed (effective status expired)
    prev,     \* C -> BOOLEAN: a revoke in flight, its reading taken
    pmap,     \* P -> X \cup {NONE}: the principal binding
    xmap,     \* X -> P \cup {NONE}: the inverse map
    bproof,   \* P -> "none" | "fresh" | "proved" | "unproved": how the binding's credential came
    preg,     \* SUBSET (P \X X): twin only, registrations whose guard was read
    attp,     \* A -> P \cup {NONE}: the principal an attestation was produced for
    attc,     \* A -> C \cup {NONE}: the credential id its success entry carries
    attok,    \* A -> BOOLEAN: that credential stood effective-active at the attestation's commit
    attafter, \* A -> BOOLEAN: its reading came after a revoke reading on that credential not yet committed
    logged,   \* A -> BOOLEAN: the success entry was written
    pgate,    \* P -> C \cup {NONE}: twin only, a gate read in flight and the credential it found
    cna,      \* P -> BOOLEAN: a credential-not-active entry was written
    cnaok     \* P -> BOOLEAN: every such entry named the pair's last credential, not effective-active at its commit

vars == <<cstat, cown, clapsed, prev, pmap, xmap, bproof, preg,
          attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

Lowest(S) == IF S = {} THEN NONE ELSE CHOOSE x \in S : \A y \in S : x <= y
Highest(S) == IF S = {} THEN NONE ELSE CHOOSE x \in S : \A y \in S : y <= x
FreeCreds == {c \in C : cstat[c] = "free"}
FreeAtts == {a \in A : attp[a] = NONE}
EA(c) == cstat[c] = "active" /\ ~clapsed[c]
EAOf(p) == {c \in C : cown[c] = p /\ EA(c)}
Current(p) == Highest(EAOf(p))
LastOf(p) == Highest({c \in C : cown[c] = p})

TypeOK ==
    /\ cstat \in [C -> {"free", "active", "rotated", "revoked"}]
    /\ cown \in [C -> (P \cup {NONE})]
    /\ clapsed \in [C -> BOOLEAN]
    /\ prev \in [C -> BOOLEAN]
    /\ pmap \in [P -> (X \cup {NONE})]
    /\ xmap \in [X -> (P \cup {NONE})]
    /\ bproof \in [P -> {"none", "fresh", "proved", "unproved"}]
    /\ preg \subseteq (P \X X)
    /\ attp \in [A -> (P \cup {NONE})]
    /\ attc \in [A -> (C \cup {NONE})]
    /\ attok \in [A -> BOOLEAN]
    /\ attafter \in [A -> BOOLEAN]
    /\ logged \in [A -> BOOLEAN]
    /\ pgate \in [P -> (C \cup {NONE})]
    /\ cna \in [P -> BOOLEAN]
    /\ cnaok \in [P -> BOOLEAN]

Init ==
    /\ cstat = [c \in C |-> "free"]
    /\ cown = [c \in C |-> NONE]
    /\ clapsed = [c \in C |-> FALSE]
    /\ prev = [c \in C |-> FALSE]
    /\ pmap = [p \in P |-> NONE]
    /\ xmap = [x \in X |-> NONE]
    /\ bproof = [p \in P |-> "none"]
    /\ preg = {}
    /\ attp = [a \in A |-> NONE]
    /\ attc = [a \in A |-> NONE]
    /\ attok = [a \in A |-> FALSE]
    /\ attafter = [a \in A |-> FALSE]
    /\ logged = [a \in A |-> FALSE]
    /\ pgate = [p \in P |-> NONE]
    /\ cna = [p \in P |-> FALSE]
    /\ cnaok = [p \in P |-> TRUE]

\* The binding a registration writes, with how its credential came (Action wiring 4 to 9):
\* a fresh credential where the pair holds none effective-active, else the re-entry arm.
Bind(p, x, holds) ==
    LET fresh == EAOf(p) = {}
        c == Lowest(FreeCreds)
    IN /\ (fresh => c # NONE)
       /\ ((~fresh /\ Possession) => holds)
       /\ cstat' = IF fresh THEN [cstat EXCEPT ![c] = "active"] ELSE cstat
       /\ cown' = IF fresh THEN [cown EXCEPT ![c] = p] ELSE cown
       /\ pmap' = [pmap EXCEPT ![p] = x]
       /\ xmap' = [xmap EXCEPT ![x] = p]
       /\ bproof' = [bproof EXCEPT ![p] = IF fresh THEN "fresh" ELSE IF holds THEN "proved" ELSE "unproved"]

\* [Register Authenticated Actor], admitted: the guard, the register or the verify, and the
\* binding in one transaction.
Register(p, x, holds) ==
    /\ GuardInTxn
    /\ pmap[p] = NONE
    /\ xmap[x] = NONE
    /\ Bind(p, x, holds)
    /\ UNCHANGED <<clapsed, prev, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* Twin only: the guard read in one step ...
RegisterGuard(p, x) ==
    /\ ~GuardInTxn
    /\ pmap[p] = NONE
    /\ xmap[x] = NONE
    /\ <<p, x>> \notin preg
    /\ preg' = preg \cup {<<p, x>>}
    /\ UNCHANGED <<cstat, cown, clapsed, prev, pmap, xmap, bproof, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* ... and the binding written in a later one, the guard not read again.
RegisterWrite(p, x, holds) ==
    /\ <<p, x>> \in preg
    /\ preg' = preg \ {<<p, x>>}
    /\ Bind(p, x, holds)
    /\ UNCHANGED <<clapsed, prev, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* A credential registered through Credential's own register (Composition note 7): refused
\* where the pair already holds one effective-active (Credential Operation 6).
DirectRegister(p) ==
    /\ EAOf(p) = {}
    /\ FreeCreds # {}
    /\ cstat' = [cstat EXCEPT ![Lowest(FreeCreds)] = "active"]
    /\ cown' = [cown EXCEPT ![Lowest(FreeCreds)] = p]
    /\ UNCHANGED <<clapsed, prev, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* Credential's rotate (Composition note 4): the successor carries the pair, active.
Rotate(c) ==
    /\ EA(c)
    /\ FreeCreds # {}
    /\ cstat' = [cstat EXCEPT ![c] = "rotated", ![Lowest(FreeCreds)] = "active"]
    /\ cown' = [cown EXCEPT ![Lowest(FreeCreds)] = cown[c]]
    /\ UNCHANGED <<clapsed, prev, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* Credential's revoke takes its clock reading (Credential Operation 43: now as revocation
\* instant) and decides on an effective-active credential (Operation 29) ...
RevokeStart(c) ==
    /\ EA(c)
    /\ ~prev[c]
    /\ prev' = [prev EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<cstat, cown, clapsed, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* ... and commits later; where a write it read over committed first, it reads again and
\* refuses already-terminal, writing nothing (Database 2).
RevokeCommit(c) ==
    /\ prev[c]
    /\ prev' = [prev EXCEPT ![c] = FALSE]
    /\ cstat' = IF cstat[c] = "active" THEN [cstat EXCEPT ![c] = "revoked"] ELSE cstat
    /\ UNCHANGED <<cown, clapsed, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* An active credential's expiry instant passes: it reads lapsed, and never live again.
Lapse(c) ==
    /\ cstat[c] = "active"
    /\ ~clapsed[c]
    /\ clapsed' = [clapsed EXCEPT ![c] = TRUE]
    /\ UNCHANGED <<cstat, cown, prev, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate, cna, cnaok>>

\* The attestation a gate passed for p commits, naming credential g, with its success entry
\* (with LogInTxn = FALSE the entry can be lost). attok is computed from the state the commit
\* writes over; attafter records that a revoke had taken its reading on g and not committed.
Commit(p, g) ==
    /\ FreeAtts # {}
    /\ \E w \in (IF LogInTxn THEN {TRUE} ELSE BOOLEAN) :
         /\ attp' = [attp EXCEPT ![Lowest(FreeAtts)] = p]
         /\ attc' = [attc EXCEPT ![Lowest(FreeAtts)] = g]
         /\ attok' = [attok EXCEPT ![Lowest(FreeAtts)] = EA(g)]
         /\ attafter' = [attafter EXCEPT ![Lowest(FreeAtts)] = prev[g]]
         /\ logged' = [logged EXCEPT ![Lowest(FreeAtts)] = w]

\* [Attest As Actor], admitted, the gate open: the gate read, the attest and the success entry
\* in one transaction (Action wiring 14 to 24).
Attest(p) ==
    /\ GateInTxn
    /\ pmap[p] # NONE
    /\ EAOf(p) # {}
    /\ Commit(p, Current(p))
    /\ UNCHANGED <<cstat, cown, clapsed, prev, pmap, xmap, bproof, preg, pgate, cna, cnaok>>

\* Twin only: the gate read in one step ...
GateRead(p) ==
    /\ ~GateInTxn
    /\ pmap[p] # NONE
    /\ EAOf(p) # {}
    /\ pgate[p] = NONE
    /\ pgate' = [pgate EXCEPT ![p] = Current(p)]
    /\ UNCHANGED <<cstat, cown, clapsed, prev, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, cna, cnaok>>

\* ... and the attestation written in a later one, the gate not read again.
AttestLate(p) ==
    /\ pgate[p] # NONE
    /\ pgate' = [pgate EXCEPT ![p] = NONE]
    /\ Commit(p, pgate[p])
    /\ UNCHANGED <<cstat, cown, clapsed, prev, pmap, xmap, bproof, preg, cna, cnaok>>

\* [Attest As Actor], admitted, the gate closed: credential-not-active, and the entry names the
\* pair's last credential and its observed status (Action wiring 18, 34).
AttestRefused(p) ==
    /\ pmap[p] # NONE
    /\ EAOf(p) = {}
    /\ cna' = [cna EXCEPT ![p] = TRUE]
    /\ cnaok' = [cnaok EXCEPT ![p] = (cnaok[p] /\ LastOf(p) # NONE /\ ~EA(LastOf(p)))]
    /\ UNCHANGED <<cstat, cown, clapsed, prev, pmap, xmap, bproof, preg, attp, attc, attok, attafter, logged, pgate>>

Next ==
    \/ \E p \in P, x \in X, h \in BOOLEAN : Register(p, x, h)
    \/ \E p \in P, x \in X : RegisterGuard(p, x)
    \/ \E p \in P, x \in X, h \in BOOLEAN : RegisterWrite(p, x, h)
    \/ \E p \in P : DirectRegister(p)
    \/ \E c \in C : Rotate(c)
    \/ \E c \in C : RevokeStart(c)
    \/ \E c \in C : RevokeCommit(c)
    \/ \E c \in C : Lapse(c)
    \/ \E p \in P : Attest(p)
    \/ \E p \in P : GateRead(p)
    \/ \E p \in P : AttestLate(p)
    \/ \E p \in P : AttestRefused(p)

Spec == Init /\ [][Next]_vars

\* ---- the page's guarantees -------------------------------------------------

Inv1_1 == \A a \in A : (attp[a] # NONE => attok[a])

Inv3 ==
    /\ \A p \in P : (pmap[p] # NONE => xmap[pmap[p]] = p)
    /\ \A x \in X : (xmap[x] # NONE => pmap[xmap[x]] = x)

Inv4 == \A a \in A : (attp[a] # NONE => (logged[a] /\ attc[a] # NONE /\ cown[attc[a]] = attp[a]))

AuthBinding == \A p \in P : bproof[p] # "unproved"

CnaEntry == \A p \in P : cnaok[p]

\* ---- reachability probes (each must be violated) ----------------------------

\* an attestation stands.
Probe_NoAttest == \A a \in A : attp[a] = NONE
\* an attestation's gate credential is newer than a rotated credential of its principal.
Probe_NoRotatedGate == ~(\E a \in A, c \in C : attp[a] # NONE /\ cown[c] = attp[a] /\ cstat[c] = "rotated" /\ c < attc[a])
\* a binding adopts an existing credential its presenter proved.
Probe_NoReentry == \A p \in P : bproof[p] # "proved"
\* a credential-not-active entry is written.
Probe_NoRefused == \A p \in P : ~cna[p]
\* an attestation whose reading came after its credential's revoke reading stands over a
\* credential now revoked, Inv1_1 held.
Probe_NoStampGap == ~(\E a \in A : attp[a] # NONE /\ attok[a] /\ attafter[a] /\ cstat[attc[a]] = "revoked")
\* an attestation's gate credential was registered after the principal's earlier credential
\* was revoked.
Probe_NoReopen == ~(\E a \in A, c \in C : attp[a] # NONE /\ cown[c] = attp[a] /\ cstat[c] = "revoked" /\ ~clapsed[c] /\ c < attc[a])

====

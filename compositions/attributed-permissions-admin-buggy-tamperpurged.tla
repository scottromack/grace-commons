---- MODULE attributed-permissions-admin-buggy-tamperpurged ----
\* BUGGY TWIN: an absent attestation reads as the tamper reading even where the purge record names it (the reading the 2026-09-15 Decision retired; Action wiring 62, 63, 65).
\* Grace Commons — Attributed Permissions Admin: the three administrative actions, the
\* orphan they leave, writes made around the composition, the retention purge and the
\* attribution query's purge and tamper readings.
\* Spec-level formal sibling of compositions/attributed-permissions-admin.md. Derived
\* validator; the English spec is the single source of truth. On any disagreement,
\* diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* ONE PAIR, two grant ids and four attestation ids, each id taken lowest first, so no
\* trace differs from another by the ids it drew; at most one orphan is logged, and the
\* adversary and a per-store purge act on attestations an entry names, the only ones an
\* attribution record reads (an orphan goes under Composition state 28 below).
\*
\* ONE TRANSACTION PER ACTION (Execution Contract Database 1, Capability requirement 34).
\* Every write one action makes, its constituents' included, commits together, so each
\* action below is one step. A storage failure anywhere in an act commits nothing and is
\* no step (Action wiring 88, 90, 95; with OneTxn = FALSE a failed grant write leaves its
\* attestation behind, -buggy-storageorphan). A constituent's refusal after the attest
\* (Permissions' invalid-request at an issuance, its not-known or not-active at a
\* revocation) keeps the attestation and writes its orphan log entry (Action wiring 8, 10,
\* 26; Wiring decision 4, 5), as the page stands; open line 2026-10-27-a asks whether
\* Execution Contract Read 4 leaves it so. An attest refusal writes nothing and is no step.
\* A pair-scoped revocation enumerates the pair's active grants inside the transaction that
\* revokes them (Execution Contract Database 2), each under its own attestation (Composes
\* 23, 24; with OwnAttest = FALSE one attestation serves the set, -buggy-sharedattest); an
\* empty set answers not-permitted and writes nothing (Action wiring 43, 44).
\*
\* AROUND THE COMPOSITION (Composes 19, Invariant 1.4, 2.4): a direct database write may
\* issue or revoke a grant with no attestation, and an adversary may remove an attestation
\* record outside any purge (the breach-forensics scenario), which is what the tamper
\* reading exists to find.
\*
\* RETENTION. The deployment's retention scope is pair-scoped or per-store, chosen at the
\* start (Capability requirement 27). Under the pair-scoped scope a purge takes a grant, its
\* attestations and its attribution entries as one unit (Composition state 27; with
\* PairPurge = FALSE an attestation goes alone, -buggy-attestpurge); under the per-store
\* scope an attestation goes alone. An orphan attestation goes under its own retention
\* (Composition state 28). Every purge names what it took in the purge record (Capability
\* requirement 28). The orphan log entry stays (open line 2026-10-27-b).
\*
\* THE ATTRIBUTION QUERY ([Verify Grant Attribution]) is a read, so it is no step: VR(a) is
\* the verify result an attribution record carries for the attestation a names (Action
\* wiring 61 to 67): verified while Actor Identity holds the record; for an absent one the
\* tamper reading under the pair-scoped scope (Action wiring 67), and under the per-store
\* scope not-applicable(purged) where the purge record names it (Action wiring 62, 63;
\* with PurgeNamed = FALSE an absent attestation always reads as tamper, the reading the
\* 2026-09-15 Decision retired, -buggy-tamperpurged) and the tamper reading where it does
\* not (Action wiring 64). The record is answered over a consistent attribution (Action
\* wiring 56 to 60, 79; Term consistent attribution).
\*
\* WHAT THIS MODEL CHECKS
\*   Inv1_1         a grant the composition issued carries a grant attribution entry
\*                  (Invariant 1.1, 1.4; Check 1.1).
\*   Inv2_1         a grant the composition revoked carries a revocation attribution entry
\*                  (Invariant 2.1, 2.4; Invariant 9.2; Check 2.1, 7.2).
\*   Inv7           the two maps injective, each naming an attestation of its own kind
\*                  (Invariant 7.1 to 7.3; Check 6.1 to 6.4).
\*   NoActiveRevEntry  no revocation attribution entry names an active grant (Invariant 9.1;
\*                  Composition state 13).
\*   OrphanLogged   every held attestation no entry names carries an orphan log entry
\*                  (Atomic writes 8; Housekeeping 16, 17: no non-conformant purge arises).
\*   OrphanUnpaired no entry names an orphan-logged attestation: an orphan is evidence and
\*                  a retry a fresh act (Wiring decision 4, 5; Housekeeping 7, 8; Action
\*                  wiring 38, 39; with ReportOnly = FALSE the leg completes an orphan's
\*                  grant, the posture the 2026-08-30 Decision retired, -buggy-completeorphan).
\*   PairScopeHeld  under the pair-scoped scope no standing grant's attestation was lawfully
\*                  destroyed (Composition state 27; Invariant 1.2, 2.2).
\*   NoFalseTamper  the tamper reading never stands for a lawful destruction (Action wiring
\*                  65; Term lawful destruction).
\*   TamperFound    an attestation removed outside a purge reads as the tamper reading
\*                  (Action wiring 64, 67, 73).
\*
\* THE RULES, as constants, each TRUE here; each twin is this module with one turned FALSE:
\*   OneTxn       a storage failure commits nothing (Database 1; Action wiring 88)  -buggy-storageorphan
\*   OwnAttest    each revocation of a sweep has its own attestation (Composes 24)  -buggy-sharedattest
\*   ReportOnly   the failed-grant leg never completes an orphan (Housekeeping 8)    -buggy-completeorphan
\*   PairPurge    a pair-scoped purge takes the pair as one unit (Comp. state 27)    -buggy-attestpurge
\*   PurgeNamed   an absent attestation the purge record names reads purged
\*                (Action wiring 62, 63)                                            -buggy-tamperpurged
\*
\* NOT MODELLED: the boundary predicate, credentials and the verify outcomes Actor Identity
\* computes for a held attestation (each reads verified here), the evaluation passthrough,
\* the clock and its offset allowance (Invariant 4), the request instant and the auditor's
\* grouping (Identity 9, 10), the failed-grant leg's ages and horizon (Housekeeping 13 to 18),
\* a second pair, and writes to the composition's own maps around it (Invariant 6.4,
\* External check 5).

EXTENDS Naturals, FiniteSets

CONSTANTS OneTxn, OwnAttest, ReportOnly, PairPurge, PurgeNamed

G == 1..2
A == 1..4
NONE == 0

VARIABLES
    gstat,     \* G -> "none" | "active" | "revoked" | "purged": Permissions' grant records
    gdirect,   \* G -> BOOLEAN: issued by a direct database write
    rdirect,   \* G -> BOOLEAN: revoked by a direct database write
    att,       \* A -> "free" | "issue" | "revoke": the attestations Actor Identity minted
    agone,     \* SUBSET A: attestation records no longer held (purged, or removed around it)
    precord,   \* SUBSET A: the purge record, the attestations a lawful destruction took
    gmap,      \* G -> A \cup {NONE}: the grant attribution map
    rmap,      \* G -> A \cup {NONE}: the revocation attribution map
    olog,      \* SUBSET A: the orphan log
    scope,     \* "pair" | "store": the deployment's retention scope
    swept      \* SUBSET G: the enumerated set of the last pair-scoped revocation

vars == <<gstat, gdirect, rdirect, att, agone, precord, gmap, rmap, olog, scope, swept>>

Lowest(S) == IF S = {} THEN NONE ELSE CHOOSE x \in S : \A y \in S : x <= y
FreeAtts == {a \in A : att[a] = "free"}
FreeGrants == {g \in G : gstat[g] = "none"}
Stands(g) == gstat[g] \in {"active", "revoked"}
Named(a) == \E g \in G : (gmap[g] = a \/ rmap[g] = a)
Consistent(g) == /\ Stands(g)
                 /\ gmap[g] # NONE
                 /\ (gstat[g] = "revoked" => rmap[g] # NONE)

\* The verify result the attribution record carries for the attestation a names.
VR(a) == IF a \notin agone THEN "verified"
         ELSE IF scope = "pair" THEN "tamper"
         ELSE IF (PurgeNamed /\ a \in precord) THEN "purged"
         ELSE "tamper"

TypeOK ==
    /\ gstat \in [G -> {"none", "active", "revoked", "purged"}]
    /\ gdirect \in [G -> BOOLEAN]
    /\ rdirect \in [G -> BOOLEAN]
    /\ att \in [A -> {"free", "issue", "revoke"}]
    /\ agone \subseteq A
    /\ precord \subseteq agone
    /\ gmap \in [G -> A \cup {NONE}]
    /\ rmap \in [G -> A \cup {NONE}]
    /\ olog \subseteq A
    /\ scope \in {"pair", "store"}
    /\ swept \subseteq G

Init ==
    /\ gstat = [g \in G |-> "none"]
    /\ gdirect = [g \in G |-> FALSE]
    /\ rdirect = [g \in G |-> FALSE]
    /\ att = [a \in A |-> "free"]
    /\ agone = {}
    /\ precord = {}
    /\ gmap = [g \in G |-> NONE]
    /\ rmap = [g \in G |-> NONE]
    /\ olog = {}
    /\ scope \in {"pair", "store"}
    /\ swept = {}

\* [Issue Grant], admitted: attest, grant, pair (Action wiring 1 to 7, 15).
Issue ==
    /\ FreeAtts # {}
    /\ FreeGrants # {}
    /\ att' = [att EXCEPT ![Lowest(FreeAtts)] = "issue"]
    /\ gstat' = [gstat EXCEPT ![Lowest(FreeGrants)] = "active"]
    /\ gmap' = [gmap EXCEPT ![Lowest(FreeGrants)] = Lowest(FreeAtts)]
    /\ UNCHANGED <<gdirect, rdirect, agone, precord, rmap, olog, scope, swept>>

\* [Issue Grant], Permissions answering invalid-request: the attestation stays as evidence
\* and the orphan is logged (Action wiring 8, 10; Atomic writes 8).
IssueRefused ==
    /\ olog = {}
    /\ FreeAtts # {}
    /\ att' = [att EXCEPT ![Lowest(FreeAtts)] = "issue"]
    /\ olog' = olog \cup {Lowest(FreeAtts)}
    /\ UNCHANGED <<gstat, gdirect, rdirect, agone, precord, gmap, rmap, scope, swept>>

\* Twin only: Permissions' storage-failure committing the attestation alone.
StorageOrphan ==
    /\ ~OneTxn
    /\ FreeAtts # {}
    /\ att' = [att EXCEPT ![Lowest(FreeAtts)] = "issue"]
    /\ UNCHANGED <<gstat, gdirect, rdirect, agone, precord, gmap, rmap, olog, scope, swept>>

\* [Revoke Grant], admitted: attest, revoke, pair (Action wiring 16 to 22, 41).
Revoke(g) ==
    /\ gstat[g] = "active"
    /\ FreeAtts # {}
    /\ att' = [att EXCEPT ![Lowest(FreeAtts)] = "revoke"]
    /\ gstat' = [gstat EXCEPT ![g] = "revoked"]
    /\ rmap' = [rmap EXCEPT ![g] = Lowest(FreeAtts)]
    /\ UNCHANGED <<gdirect, rdirect, agone, precord, gmap, olog, scope, swept>>

\* [Revoke Grant], Permissions answering not-known or not-active: the attestation stays as
\* evidence and the orphan is logged (Action wiring 23, 24, 26).
RevokeRefused(g) ==
    /\ gstat[g] \in {"none", "revoked", "purged"}
    /\ olog = {}
    /\ FreeAtts # {}
    /\ att' = [att EXCEPT ![Lowest(FreeAtts)] = "revoke"]
    /\ olog' = olog \cup {Lowest(FreeAtts)}
    /\ UNCHANGED <<gstat, gdirect, rdirect, agone, precord, gmap, rmap, scope, swept>>

\* [Revoke Permission] over a non-empty enumerated set: every active grant of the pair
\* revoked, each under an attestation of its own, lowest first (Action wiring 42 to 48,
\* 92 to 95).
Sweep ==
    LET E == {g \in G : gstat[g] = "active"}
        first == Lowest(FreeAtts)
        second == IF OwnAttest THEN Lowest(FreeAtts \ {first}) ELSE first
        used == IF Cardinality(E) = 2 THEN {first, second} ELSE {first}
    IN /\ E # {}
       /\ FreeAtts # {}
       /\ (OwnAttest => Cardinality(FreeAtts) >= Cardinality(E))
       /\ att' = [a \in A |-> IF a \in used THEN "revoke" ELSE att[a]]
       /\ gstat' = [g \in G |-> IF g \in E THEN "revoked" ELSE gstat[g]]
       /\ rmap' = [g \in G |-> IF g \notin E THEN rmap[g] ELSE IF (g = 2 /\ 1 \in E) THEN second ELSE first]
       /\ swept' = E
       /\ UNCHANGED <<gdirect, rdirect, agone, precord, gmap, olog, scope>>

\* Twin only: the failed-grant leg completing an orphan's grant on its attestation.
CompleteOrphan(a) ==
    /\ ~ReportOnly
    /\ a \in olog
    /\ att[a] = "issue"
    /\ a \notin agone
    /\ FreeGrants # {}
    /\ gstat' = [gstat EXCEPT ![Lowest(FreeGrants)] = "active"]
    /\ gmap' = [gmap EXCEPT ![Lowest(FreeGrants)] = a]
    /\ UNCHANGED <<gdirect, rdirect, att, agone, precord, rmap, olog, scope, swept>>

\* A grant written around the composition (Composes 19, Invariant 1.4).
DirectGrant ==
    /\ FreeGrants # {}
    /\ gstat' = [gstat EXCEPT ![Lowest(FreeGrants)] = "active"]
    /\ gdirect' = [gdirect EXCEPT ![Lowest(FreeGrants)] = TRUE]
    /\ UNCHANGED <<rdirect, att, agone, precord, gmap, rmap, olog, scope, swept>>

\* A revocation written around the composition (Composes 19, Invariant 2.4).
DirectRevoke(g) ==
    /\ gstat[g] = "active"
    /\ gstat' = [gstat EXCEPT ![g] = "revoked"]
    /\ rdirect' = [rdirect EXCEPT ![g] = TRUE]
    /\ UNCHANGED <<gdirect, att, agone, precord, gmap, rmap, olog, scope, swept>>

\* A pair-scoped purge: the grant, its attestations and its entries as one unit
\* (Composition state 27, Capability requirement 28).
PurgePair(g) ==
    LET took == {gmap[g], rmap[g]} \ {NONE}
    IN /\ scope = "pair"
       /\ Stands(g)
       /\ gstat' = [gstat EXCEPT ![g] = "purged"]
       /\ agone' = agone \cup took
       /\ precord' = precord \cup took
       /\ gmap' = [gmap EXCEPT ![g] = NONE]
       /\ rmap' = [rmap EXCEPT ![g] = NONE]
       /\ UNCHANGED <<gdirect, rdirect, att, olog, scope, swept>>

\* A per-store purge of one attestation; under the pair-scoped scope only in the twin.
PurgeAtt(a) ==
    /\ (scope = "store" \/ ~PairPurge)
    /\ Named(a)
    /\ a \notin agone
    /\ agone' = agone \cup {a}
    /\ precord' = precord \cup {a}
    /\ UNCHANGED <<gstat, gdirect, rdirect, att, gmap, rmap, olog, scope, swept>>

\* An orphan attestation purged under its own retention (Composition state 28).
PurgeOrphan(a) ==
    /\ a \in olog
    /\ a \notin agone
    /\ agone' = agone \cup {a}
    /\ precord' = precord \cup {a}
    /\ UNCHANGED <<gstat, gdirect, rdirect, att, gmap, rmap, olog, scope, swept>>

\* An attestation record removed outside any purge (the breach-forensics scenario).
Tamper(a) ==
    /\ Named(a)
    /\ a \notin agone
    /\ agone' = agone \cup {a}
    /\ UNCHANGED <<gstat, gdirect, rdirect, att, precord, gmap, rmap, olog, scope, swept>>

Next ==
    \/ Issue
    \/ IssueRefused
    \/ StorageOrphan
    \/ \E g \in G : Revoke(g)
    \/ \E g \in G : RevokeRefused(g)
    \/ Sweep
    \/ \E a \in A : CompleteOrphan(a)
    \/ DirectGrant
    \/ \E g \in G : DirectRevoke(g)
    \/ \E g \in G : PurgePair(g)
    \/ \E a \in A : PurgeAtt(a)
    \/ \E a \in A : PurgeOrphan(a)
    \/ \E a \in A : Tamper(a)

Spec == Init /\ [][Next]_vars

\* ---- the page's guarantees -------------------------------------------------

Inv1_1 == \A g \in G : ((Stands(g) /\ ~gdirect[g]) => gmap[g] # NONE)

Inv2_1 == \A g \in G : ((gstat[g] = "revoked" /\ ~rdirect[g]) => rmap[g] # NONE)

Inv7 ==
    /\ \A g1, g2 \in G : ((gmap[g1] # NONE /\ gmap[g1] = gmap[g2]) => g1 = g2)
    /\ \A g1, g2 \in G : ((rmap[g1] # NONE /\ rmap[g1] = rmap[g2]) => g1 = g2)
    /\ \A g \in G : (gmap[g] # NONE => att[gmap[g]] = "issue")
    /\ \A g \in G : (rmap[g] # NONE => att[rmap[g]] = "revoke")

NoActiveRevEntry == \A g \in G : (gstat[g] = "active" => rmap[g] = NONE)

OrphanLogged == \A a \in A : ((att[a] # "free" /\ ~Named(a) /\ a \notin agone) => a \in olog)

OrphanUnpaired == \A a \in olog : ~Named(a)

PairScopeHeld == \A g \in G : ((scope = "pair" /\ Stands(g)) => ({gmap[g], rmap[g]} \cap precord = {}))

NoFalseTamper ==
    \A g \in G : (Consistent(g) =>
        (/\ (VR(gmap[g]) = "tamper" => gmap[g] \notin precord)
         /\ (gstat[g] = "revoked" => (VR(rmap[g]) = "tamper" => rmap[g] \notin precord))))

TamperFound ==
    \A g \in G : (Consistent(g) =>
        (/\ ((gmap[g] \in agone /\ gmap[g] \notin precord) => VR(gmap[g]) = "tamper")
         /\ ((gstat[g] = "revoked" /\ rmap[g] \in agone /\ rmap[g] \notin precord) => VR(rmap[g]) = "tamper")))

\* ---- reachability probes (each must be violated) ----------------------------

\* an attributed grant stands.
Probe_NoIssue == \A g \in G : ~(Stands(g) /\ gmap[g] # NONE)
\* an orphan is logged.
Probe_NoOrphan == olog = {}
\* one pair-scoped revocation revokes two grants under two attestations.
Probe_NoSweepTwo == Cardinality(swept) < 2
\* a grant committed after a pair-scoped revocation stands active beside it (Concurrency 7).
Probe_NoSurvivor == ~(swept # {} /\ \E g \in G : (gstat[g] = "active" /\ g \notin swept))
\* a standing grant has no consistent attribution: one written around the composition
\* (the state Invariant 3.1 read per known grant could not hold over; row 5).
Probe_AllConsistent == \A g \in G : (Stands(g) => Consistent(g))
\* a grant the composition issued, revoked around it (Invariant 2.4's state; row 6).
Probe_NoDirectRevoke == \A g \in G : ~(gstat[g] = "revoked" /\ gmap[g] # NONE /\ rmap[g] = NONE)
\* a consistent attribution reads not-applicable(purged): a per-store purge.
Probe_NoPurgedRead == \A g \in G : (Consistent(g) => VR(gmap[g]) # "purged")
\* a consistent attribution reads the tamper reading.
Probe_NoTamperRead == \A g \in G : (Consistent(g) => VR(gmap[g]) # "tamper")
\* a standing grant's entry names an attestation a lawful destruction took: Invariant 1.2
\* as it read before Final Critique 8's model unit (the Actor Identity records hold it).
Probe_EntryHeld == \A g \in G : ((Stands(g) /\ gmap[g] # NONE) => gmap[g] \notin precord)

====

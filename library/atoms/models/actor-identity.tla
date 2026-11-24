---- MODULE actor-identity ----
\* Grace Commons — Actor Identity atom (atoms/actor-identity.md).
\* Grounded on Final Critique 16, 2026-11-06 at ad732c0 — TLA+ layer authored 2026-11-12;
\* re-derived 2026-11-20 on the cures of open lines 2026-11-05-a (a revocation
\* read as of attestation instant), 2026-11-04-b (a cached verification),
\* 2026-11-03-a (the era) and 2026-10-20-f (the [Read] entry).
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: the attestations [Attest] records over a
\* sequence of calls while the actor registry's view moves (a rotation, an
\* outage, a removal) and revocation statuses arrive, each with the effective
\* instant the credential mechanism supplies or none, what [Verify] and [Read]
\* answer at each point, and what a [Verify] and a [Read] leave. What one state
\* of the records must carry (State 1, 3, 4, 7, Identity 2, Invariant 2.1, 3.1
\* and 5.1, and which calls [Attest] admits: Operation 1, 3, 6 to 9, 31, 33,
\* 36 to 40) is the Alloy model's, actor-identity.als; the two models spell the
\* page's terms alike (attested, the registry answer, the current material, the
\* proof check, the attestation id).
\*
\* HOW THE ANSWERS ARE CHECKED
\* [Verify] and [Read] write nothing, so a call of either is no step that
\* changes a variable here. What [Verify] answers is the operator
\* VerifyAnswers(id, up), and what [Read] answers is ReadIds; the checks on
\* answers (Operation 14 to 19, 27, 32, 41, 42) are invariants that hold them, in
\* every reachable state, for every id, with the mechanism up and down, which
\* is every [Verify] and [Read] the state admits. Invariant 6.3, 7.1 and 8.2
\* compare answers across every step: one verification before it and one after. The
\* model keeps no history of calls (a model that did ran past 850,000 states).
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1  — no attestation field of a recorded attestation
\*                    changes                                       (Inv1_1_FieldsFixed)
\*   Invariant 6.3  — [Verify] consults nothing outside the
\*                    verification set: one set, one answer         (Inv6_3_VerificationSetOnly)
\*   Invariant 7.1  — two verifications of one attestation under one
\*                    registry view and revocation status, neither
\*                    mechanism-unavailable, answer alike           (Inv7_1_ConsistentUnderOneView)
\*   Invariant 8.2  — a revocation effective after an attestation's
\*                    instant (a later compromise) leaves every
\*                    [Verify] of it answering as before (Non-goal 9
\*                    with it)                                      (Inv8_2_NoLaterReinterpretation)
\*   Invariant 9.1  — the atom deletes no attestation (State 6)     (Inv9_1_NoDeletion)
\*   State 5        — no step moves an attestation out of attested  (State5_NoRevocation)
\*   Capability requirement 6 — the host's attestation id is one
\*                    no attestation has carried (Identity 2)       (Cap6_HostIdFresh)
\*   Operation 2    — exactly one attestation per admitted attest,
\*                    an action, actor or instant already attested
\*                    included (Identity 6, 7, 8 through it)        (Op2_OneAttestationPerAttest)
\*   Operation 14   — [Verify] answers exactly one outcome          (Op14_ExactlyOneAnswer)
\*   Operation 15   — no attestation under the id: not-known        (Op15_NotKnown)
\*   Operation 16   — registry unknown-actor: actor-unknown-in-registry (Op16_ActorUnknown)
\*   Operation 17   — registry unreachable: registry-unavailable    (Op17_RegistryUnavailable)
\*   Operation 18   — material, proof check failed: proof-invalid   (Op18_ProofInvalid)
\*   Operation 19   — material, proof check held: verified
\*                    (Operation 21 through it)                     (Op19_Verified)
\*   Operation 20, 29 — [Verify] and [Read] write nothing: only an
\*                    [Attest] writes                               (Op20_29_OnlyAttestWrites)
\*   Operation 27   — [Read] answers every attestation              (Op27_ReadAnswersEvery)
\*   Operation 32   — with no cached result (always, here), verified
\*                    only if the proof check held                  (Op32_VerifiedOnlyIfHeld)
\*   Operation 41   — material, proof check unavailable:
\*                    mechanism-unavailable                         (Op41_MechanismUnavailable)
\*   Operation 42   — [Verify] reads a revocation status as of
\*                    attestation instant: a revocation effective no
\*                    later than it fails the proof, one effective
\*                    after it does not                             (Op42_RevocationAsOfAttestationInstant)
\*
\* WHAT THE MODEL TAKES FROM OUTSIDE THE PAGE (its inputs; no ASSUME, no CONSTRAINT)
\* - The clock (Term now; Capability requirement 1): the variable `now`, moved
\*   by a step of its own (Tick).
\* - The actor registry (Capability requirement 3; Registry view 1 to 3): its
\*   answer for the actor (material, unknown-actor, unreachable), the current
\*   material `cur` and the historical material `kept` it keeps, each moved by
\*   a step of the registry's own: an answer change (an outage, a removal, a
\*   return) or a rotation that keeps the old material or does not.
\* - Revocation statuses (Term revocation status; Revocation status 1, 3, 5):
\*   `revAt`, for each key, whether a status names its credential revoked and,
\*   where it does, the revocation's effective instant, any instant of the
\*   clock's, earlier than now, now or later, which the credential mechanism
\*   supplies (Revocation status 5), or none where the mechanism supplies none
\*   (the case Term proof check reads as unavailable). A revocation arrives by a
\*   step of its own and is not withdrawn or moved. A status names the
\*   credential revoked as of an instant where its effective instant is no
\*   later than that instant: [Attest] reads it as of now (Operation 36),
\*   [Verify] as of attestation instant (Operation 42).
\* - The credential mechanism (Capability requirement 4, Term cryptographic
\*   material): the proof [Attest] records is the one it computes, over the
\*   call's action and actor references under the credential's key; the proof
\*   check [Verify] reads is the one it computes at the seam, as Term proof check
\*   defines it; whether it supplies one at all is the input `up` of each
\*   [Verify].
\* - The host allocates each [Attest]'s attestation id at the seam (Identity
\*   2); Capability requirement 6 binds it to one no attestation has carried,
\*   and that is the guard on Attest and a check here.
\*
\* BOUNDS (the .cfg)
\* One action reference and one actor reference (every second attestation
\* is then of an action, an actor and possibly an instant already attested:
\* Operation 2 and Identity 6 to 8); three attestation ids and room for two
\* attestations, so an id names nothing; two keys, so a rotation keeping the
\* old material, or dropping it, turns a proof made under the first key into
\* one held under historical material, or failing (Registry view 1); the
\* clock from 0 to 1, so a revocation's effective instant is no later than an
\* attestation's instant (both 0, or the attestation at 1) or after it (the
\* attestation at 0, the revocation effective at 1), and a revocation effective
\* at 1 arriving at 0 leaves an [Attest] at 0 admitted and refuses one at 1.
\* Every [Verify] answer is reached.
\*
\* NOT MODELED HERE
\* - Refused [Attest] calls (Operation 6 to 10, 31, 33, 36, 37, 40): each
\*   writes nothing (Execution Contract Read 4); which calls [Attest] admits is
\*   the Alloy model's to check. Here an [Attest] is admitted: the registry
\*   answers material, the credential is under the current material, no
\*   revocation status names it revoked as of now, and none names it revoked
\*   with no effective instant: the model reads Operation 36's bare text ("a
\*   revocation status names the credential revoked") as refusing such a call,
\*   where Term revocation status gives it no as-of-now reading and Term
\*   credential check does not read it as unavailable (recorded in the
\*   coverage matrix as found, not cured).
\* - What [Attest] answers (Operation 4) and the fields [Read] carries
\*   (Operation 28): [Read] here answers the ids of the attestations it carries.
\* - A verification cache (Verification caching 1 to 5): the model's [Verify]
\*   caches nothing, so no cached verification result exists for any
\*   attestation id and registry view, the condition Operation 32 and
\*   Operation 41 add holds in every state, and both are checked as they read
\*   with it; Verification caching 5 (a cached result answers without the
\*   seam's proof check) is not reached.
\* - The era of each public material (Capability requirement 3, Term era) and
\*   the current material at attestation instant: the registry here carries
\*   its current and its kept material with no era, since no check of this
\*   model reads one; what an auditor confirms where the current material at
\*   attestation instant is not in the public material (Check 3.3) is an
\*   auditor's act outside the atom.
\* - What Invariant 8.2 checks is the answer side: a step on which a
\*   revocation effective after an attestation's instant comes to name its
\*   credential, and nothing else in its verification set moves. A revocation
\*   effective no later than attestation instant does turn the attestation
\*   proof-invalid (Term proof check), and a revocation with no effective
\*   instant turns it mechanism-unavailable; neither is a later compromise.
\*   The write side is Invariant 1.1's and State 5's checks.

EXTENDS Integers, FiniteSets

CONSTANTS
    Ids,        \* the attestation ids the host may allocate, and a caller present
    Actions,    \* the action references an [Attest] may carry
    Actors,     \* the actor references an [Attest] may carry
    Keys,       \* the keys a credential may be under: the registry's material
    MaxAtt,     \* how many attestations the model's database holds room for
    MaxTime     \* the last instant the clock reaches in the model

\* NONE: the value of a field not yet written.
NONE == "none"

\* Slots: the places an attestation can occupy, in the order they are recorded.
Slots == 1..MaxAtt

\* RegAnswers: the registry's three answers (Term registry answer).
RegAnswers == {"material", "unknown-actor", "unreachable"}

\* Outcomes: what [Verify] may answer: verified, not-known, or a failed
\* verification carrying one of its four reasons (Term verification failure).
Outcomes == {"verified", "not-known", "proof-invalid", "actor-unknown-in-registry",
             "registry-unavailable", "mechanism-unavailable"}

\* NoProof: the proof field of a slot holding no attestation.
NoProof == [a |-> NONE, u |-> NONE, k |-> NONE]

\* NotRevoked: the revocation status of a key no status names revoked.
NotRevoked == -1

\* NoInstant: the revocation status of a key a status names revoked with no
\* effective instant supplied (Revocation status 5 broken by the mechanism).
NoInstant == -2

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    regAns,     \* the registry's answer for the actor
    cur,        \* the current material the registry holds for the actor
    kept,       \* the historical material the registry keeps for the actor
    revAt,      \* key -> its revocation's effective instant, NotRevoked or NoInstant
    now,        \* the host's clock reading, injected at the seam
    n,          \* the next slot an attestation takes
    aid,        \* slot -> attestation id
    act,        \* slot -> action reference
    actr,       \* slot -> actor reference
    pf,         \* slot -> proof: what it was computed over, and under which key
    at,         \* slot -> attestation instant
    st          \* slot -> the attestation's state ("none": no attestation)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<regAns, cur, kept, revAt, now, n, aid, act, actr, pf, at, st>>

\* records: every variable that holds an attestation's fields: what the
\* database holds.
records == <<n, aid, act, actr, pf, at, st>>

\* world: what lies outside the atom: the registry, the revocation statuses
\* and the clock.
world == <<regAns, cur, kept, revAt, now>>

\* Recorded: the slot holds an attestation.
Recorded(s) == st[s] # NONE

\* Live: the slots holding an attestation; its size is the attestation count.
Live == {s \in Slots : Recorded(s)}

\* Carried: the attestation ids the recorded attestations carry.
Carried == {aid[s] : s \in Live}

\* SlotOf: the slot whose attestation the id names, or 0 where it names none.
SlotOf(i) == IF \E s \in Live : aid[s] = i
             THEN CHOOSE s \in Live : aid[s] = i
             ELSE 0

\* View: the registry view (Term registry view): the answer and the public
\* material it carries.
View == <<regAns, cur, kept>>

\* PublicMaterial: the public material the registry answer carries for the
\* actor: the current material and every historical one it keeps; none where
\* the answer is not material (Term public material).
PublicMaterial == IF regAns = "material" THEN {cur} \cup kept ELSE {}

\* RevokedAsOf: a revocation status names the credential under key k revoked as
\* of instant t: its effective instant is no later than t (Term revocation
\* status).
RevokedAsOf(k, t) == revAt[k] >= 0 /\ revAt[k] <= t

\* MechCheck: the proof check the mechanism computes at the seam for the
\* attestation in slot s (Term proof check): failed where the proof verifies
\* under no material the public material holds for the recorded action and
\* actor, or a revocation status names its credential revoked as of
\* attestation instant (Operation 42); unavailable where the mechanism
\* supplies no check (up = FALSE) or a status names the credential revoked
\* with no effective instant (Revocation status 5); held otherwise.
MechCheck(s, up) ==
    IF \/ ~(pf[s].a = act[s] /\ pf[s].u = actr[s] /\ pf[s].k \in PublicMaterial)
       \/ RevokedAsOf(pf[s].k, at[s])
    THEN "failed"
    ELSE IF ~up \/ revAt[pf[s].k] = NoInstant THEN "unavailable" ELSE "held"

\* VerifyAnswers: what [Verify] answers for an id, each of the page's rules
\* adding the answer its condition calls for: not-known where the id names no
\* attestation (Operation 15); actor-unknown-in-registry and
\* registry-unavailable on the registry's answer (Operation 16, 17); with
\* material in hand, proof-invalid, mechanism-unavailable or verified on the
\* proof check (Operation 18, 41, 19). Operation 14 asks that exactly one rule
\* fires.
VerifyAnswers(i, up) ==
    LET s == SlotOf(i) IN
    IF s = 0 THEN {"not-known"}
    ELSE (IF regAns = "unknown-actor" THEN {"actor-unknown-in-registry"} ELSE {})
         \cup (IF regAns = "unreachable" THEN {"registry-unavailable"} ELSE {})
         \cup (IF regAns = "material" /\ MechCheck(s, up) = "failed"
               THEN {"proof-invalid"} ELSE {})
         \cup (IF regAns = "material" /\ MechCheck(s, up) = "unavailable"
               THEN {"mechanism-unavailable"} ELSE {})
         \cup (IF regAns = "material" /\ MechCheck(s, up) = "held"
               THEN {"verified"} ELSE {})

\* Fields: the five attestation fields of the slot (Term attestation field).
Fields(s) == <<aid[s], act[s], actr[s], pf[s], at[s]>>

\* RevOf: the revocation status of the slot's credential: whether a status
\* names it revoked and, where it does, the effective instant or none.
RevOf(s) == revAt[pf[s].k]

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page). The state may hold a value other than attested, so a
\* write that moved an attestation would show (State 1 is the Alloy model's).
TypeOK ==
    /\ regAns \in RegAnswers
    /\ cur \in Keys
    /\ kept \subseteq Keys
    /\ revAt \in [Keys -> {NotRevoked, NoInstant} \cup 0..MaxTime]
    /\ now \in 0..MaxTime
    /\ n \in 1..(MaxAtt + 1)
    /\ aid \in [Slots -> Ids \cup {NONE}]
    /\ act \in [Slots -> Actions \cup {NONE}]
    /\ actr \in [Slots -> Actors \cup {NONE}]
    /\ at \in [Slots -> Int]
    /\ st \in [Slots -> {NONE, "attested", "revoked", "verified"}]

\* Init: no attestation; the registry answering material under one key and
\* keeping no history; no revocation; the clock at its first instant.
Init ==
    /\ regAns = "material"
    /\ cur = CHOOSE k \in Keys : TRUE
    /\ kept = {}
    /\ revAt = [k \in Keys |-> NotRevoked]
    /\ now = 0
    /\ n = 1
    /\ aid = [s \in Slots |-> NONE]
    /\ act = [s \in Slots |-> NONE]
    /\ actr = [s \in Slots |-> NONE]
    /\ pf = [s \in Slots |-> NoProof]
    /\ at = [s \in Slots |-> -1]
    /\ st = [s \in Slots |-> NONE]

\* ---------------------------------------------------------------------------
\* Steps of the world outside the atom
\* ---------------------------------------------------------------------------

\* Tick: the host's clock moves on by a second.
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<regAns, cur, kept, revAt>>
    /\ UNCHANGED records

\* RegistryAnswers: the registry's answer for the actor changes: an outage
\* (unreachable), a removal (unknown-actor), or a return to material.
RegistryAnswers(a) ==
    /\ a # regAns
    /\ regAns' = a
    /\ UNCHANGED <<cur, kept, revAt, now>>
    /\ UNCHANGED records

\* Rotate: the registry rotates the actor's material to a new key, keeping the
\* old one as historical material or not (Registry view 1, 2).
Rotate(k, keep) ==
    /\ k # cur
    /\ cur' = k
    /\ kept' = IF keep THEN (kept \cup {cur}) \ {k} ELSE kept \ {k}
    /\ UNCHANGED <<regAns, revAt, now>>
    /\ UNCHANGED records

\* RevocationArrives: a revocation status comes to name the credential under
\* key k revoked, with the effective instant e the credential mechanism
\* supplies (any instant of the clock's), or NoInstant where it supplies none
\* (Term revocation status, Revocation status 5).
RevocationArrives(k, e) ==
    /\ revAt[k] = NotRevoked
    /\ revAt' = [revAt EXCEPT ![k] = e]
    /\ UNCHANGED <<regAns, cur, kept, now>>
    /\ UNCHANGED records

\* ---------------------------------------------------------------------------
\* The atom's actions
\* ---------------------------------------------------------------------------

\* Attest: an admitted [Attest] (the registry answers material, the credential
\* is under the current material and no revocation status names it revoked as
\* of now, nor with no effective instant: Operation 9, 31, 33, 36, 40) records one attestation in the next slot,
\* carrying the id the host allocated, one no attestation has carried
\* (Identity 2, Capability requirement 6), the call's action and actor
\* references (Operation 38, 39), the proof the mechanism computed over them
\* under the credential's key (Operation 1), the injected now (Operation 3),
\* standing in attested (State 1), and answers the id (Operation 4).
Attest(i, a, u) ==
    /\ n <= MaxAtt
    /\ i \notin Carried
    /\ regAns = "material"
    /\ ~RevokedAsOf(cur, now)
    /\ revAt[cur] # NoInstant
    /\ aid' = [aid EXCEPT ![n] = i]
    /\ act' = [act EXCEPT ![n] = a]
    /\ actr' = [actr EXCEPT ![n] = u]
    /\ pf' = [pf EXCEPT ![n] = [a |-> a, u |-> u, k |-> cur]]
    /\ at' = [at EXCEPT ![n] = now]
    /\ st' = [st EXCEPT ![n] = "attested"]
    /\ n' = n + 1
    /\ UNCHANGED world

\* ReadIds: what [Read] answers: the ids of every attestation the records hold
\* (Operation 27).
ReadIds == Carried

\* Verify: a [Verify] step. It answers VerifyAnswers(i, up) and writes nothing
\* (Operation 20), so in this model it changes no variable; the answer is
\* checked in every reachable state, for every id, with the mechanism up and
\* down (the invariants below), which is every [Verify] the state admits.
Verify(i, up) ==
    /\ UNCHANGED world
    /\ UNCHANGED records

\* Read: a [Read] step. It answers ReadIds and writes nothing (Operation 29);
\* its answer is checked in every reachable state (Op27_ReadAnswersEvery).
Read ==
    /\ UNCHANGED world
    /\ UNCHANGED records

\* Next: a step of the world, or any call: an [Attest] of any id, action and
\* actor, a [Verify] of any id with the mechanism up or down, or a [Read].
Next ==
    \/ Tick
    \/ \E a \in RegAnswers : RegistryAnswers(a)
    \/ \E k \in Keys, keep \in BOOLEAN : Rotate(k, keep)
    \/ \E k \in Keys, e \in {NoInstant} \cup 0..MaxTime : RevocationArrives(k, e)
    \/ \E i \in Ids, a \in Actions, u \in Actors : Attest(i, a, u)
    \/ \E i \in Ids, up \in BOOLEAN : Verify(i, up)
    \/ Read

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface). Each spells the page's condition itself,
\* so a defect in an action's own reading of it shows.
\* ---------------------------------------------------------------------------

\* Names: the slot holds an attestation carrying the id.
Names(i, s) == Recorded(s) /\ aid[s] = i

\* ProofVerifies: the recorded proof verifies under a material the public
\* material holds for the recorded action and actor reference, the current
\* and the historical alike, the revocation status aside.
ProofVerifies(s) ==
    LET pm == IF regAns = "material" THEN {cur} \cup kept ELSE {} IN
    /\ pf[s].a = act[s]
    /\ pf[s].u = actr[s]
    /\ pf[s].k \in pm

\* RevokedAtInstant: a revocation status names the slot's credential revoked
\* as of its attestation instant: an effective instant is supplied and is no
\* later than attestation instant (Term revocation status, Operation 42).
RevokedAtInstant(s) ==
    /\ revAt[pf[s].k] \notin {NotRevoked, NoInstant}
    /\ ~(revAt[pf[s].k] > at[s])

\* ProofCheck: the proof check as Term proof check defines it, spelled for the
\* checks: failed where the recorded proof does not verify, or a revocation
\* status names the credential revoked as of attestation instant; else
\* unavailable where the mechanism supplies none, or a status names the
\* credential revoked with no effective instant; else held.
ProofCheck(s, up) ==
    IF ~ProofVerifies(s) \/ RevokedAtInstant(s)
    THEN "failed"
    ELSE IF up /\ revAt[pf[s].k] # NoInstant THEN "held" ELSE "unavailable"

\* AttestShaped: the step records one new attestation in the next slot and
\* touches no other slot: the only write an [Attest] makes (Operation 1, 2).
AttestShaped ==
    /\ n' = n + 1
    /\ \A s \in Slots \ {n} :
          /\ aid'[s] = aid[s] /\ act'[s] = act[s] /\ actr'[s] = actr[s]
          /\ pf'[s] = pf[s] /\ at'[s] = at[s] /\ st'[s] = st[s]

\* NewlyRecorded: the slots a step fills.
NewlyRecorded == {s \in Slots : st[s] = NONE /\ st'[s] # NONE}

\* Inv1_1_FieldsFixed: no step changes a recorded attestation's id, action
\* reference, actor reference, proof or attestation instant (Invariant 1.1).
Inv1_1_FieldsFixed ==
    [][\A s \in Slots : Recorded(s) =>
          /\ aid'[s] = aid[s]
          /\ act'[s] = act[s]
          /\ actr'[s] = actr[s]
          /\ pf'[s] = pf[s]
          /\ at'[s] = at[s]]_vars

\* Inv6_3_VerificationSetOnly: across any step that leaves an attestation's
\* verification set as it was (its fields, the registry view and its
\* revocation status; the mechanism's proof check, up or down, taken alike on
\* both sides), a [Verify] of its id answers the same before and after:
\* [Verify] reads nothing outside the set, so nothing else (the clock, another
\* attestation) moves its answer (Invariant 6.3).
Inv6_3_VerificationSetOnly ==
    [][\A s \in Slots, up \in BOOLEAN :
          (/\ Recorded(s) /\ Recorded(s)'
           /\ Fields(s)' = Fields(s) /\ View' = View /\ RevOf(s)' = RevOf(s))
          => VerifyAnswers(aid[s], up)' = VerifyAnswers(aid[s], up)]_vars

\* Inv7_1_ConsistentUnderOneView: two verifications of one attestation under
\* one registry view and one revocation status, in one state or on either side
\* of a step that keeps both, answer alike, unless one of them answers
\* mechanism-unavailable (Invariant 7.1).
Inv7_1_ConsistentUnderOneView ==
    [][\A s \in Slots, u1 \in BOOLEAN, u2 \in BOOLEAN :
          (/\ Recorded(s) /\ Recorded(s)' /\ aid'[s] = aid[s]
           /\ View' = View /\ RevOf(s)' = RevOf(s)
           /\ "mechanism-unavailable" \notin VerifyAnswers(aid[s], u1)
           /\ "mechanism-unavailable" \notin VerifyAnswers(aid[s], u2)')
          => VerifyAnswers(aid[s], u2)' = VerifyAnswers(aid[s], u1)]_vars

\* Inv8_2_NoLaterReinterpretation: across any step on which a revocation
\* status comes to name an attestation's credential revoked with an effective
\* instant after that attestation's instant (a later compromise), its fields
\* and the registry view kept, a [Verify] of it (the mechanism up or down)
\* answers the same before and after: the atom does not reinterpret it
\* (Invariant 8.2, Non-goal 9).
Inv8_2_NoLaterReinterpretation ==
    [][\A s \in Slots, up \in BOOLEAN :
          (/\ Recorded(s) /\ Fields(s)' = Fields(s) /\ View' = View
           /\ revAt[pf[s].k] = NotRevoked
           /\ revAt'[pf[s].k] \notin {NotRevoked, NoInstant}
           /\ revAt'[pf[s].k] > at[s])
          => VerifyAnswers(aid[s], up)' = VerifyAnswers(aid[s], up)]_vars

\* Inv9_1_NoDeletion: no step takes an attestation away: every id the records
\* carry, they carry after (Invariant 9.1, State 6).
Inv9_1_NoDeletion ==
    [][Carried \subseteq Carried']_vars

\* State5_NoRevocation: no step moves a recorded attestation out of attested:
\* no surface revokes, invalidates or marks one (State 5, State 1).
State5_NoRevocation ==
    [][\A s \in Slots : st[s] = "attested" => st'[s] = "attested"]_vars

\* Cap6_HostIdFresh: no step records an attestation under an id an
\* attestation already carries (Capability requirement 6, Identity 2).
Cap6_HostIdFresh ==
    [][\A s \in NewlyRecorded : aid'[s] \notin Carried]_vars

\* Op2_OneAttestationPerAttest: a step that records an attestation id the
\* records did not carry adds exactly one attestation, where an attestation of
\* the same action, the same actor or the same instant stands already: the
\* atom identifies an attestation by none of them (Operation 2; Identity 6,
\* 7, 8).
Op2_OneAttestationPerAttest ==
    [][(Carried' \ Carried # {}) => Cardinality(Live') = Cardinality(Live) + 1]_vars

\* Op20_29_OnlyAttestWrites: every step that changes the records is an
\* [Attest]'s write, one new attestation in the next slot: a [Verify] and a
\* [Read] write nothing (Operation 20, Operation 29).
Op20_29_OnlyAttestWrites ==
    [][records' # records => AttestShaped]_vars

\* Op14_ExactlyOneAnswer: every [Verify], of any id, with the mechanism up or
\* down, answers exactly one outcome (Operation 14, Check 4.1).
Op14_ExactlyOneAnswer ==
    \A i \in Ids, up \in BOOLEAN :
        /\ Cardinality(VerifyAnswers(i, up)) = 1
        /\ VerifyAnswers(i, up) \subseteq Outcomes

\* Op15_NotKnown: a [Verify] of an id no attestation carries answers
\* not-known (Operation 15).
Op15_NotKnown ==
    \A i \in Ids, up \in BOOLEAN :
        (~\E s \in Slots : Names(i, s)) => VerifyAnswers(i, up) = {"not-known"}

\* Op16_ActorUnknown: a [Verify] of an attestation while the registry holds no
\* material for the actor answers actor-unknown-in-registry (Operation 16,
\* Check 4.2).
Op16_ActorUnknown ==
    \A i \in Ids, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ regAns = "unknown-actor")
            => VerifyAnswers(i, up) = {"actor-unknown-in-registry"}

\* Op17_RegistryUnavailable: a [Verify] of an attestation while the registry is
\* unreachable answers registry-unavailable (Operation 17, Check 4.2).
Op17_RegistryUnavailable ==
    \A i \in Ids, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ regAns = "unreachable")
            => VerifyAnswers(i, up) = {"registry-unavailable"}

\* Op18_ProofInvalid: a [Verify] of an attestation with material in hand and
\* the proof check failed answers proof-invalid (Operation 18).
Op18_ProofInvalid ==
    \A i \in Ids, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ regAns = "material" /\ ProofCheck(s, up) = "failed")
            => VerifyAnswers(i, up) = {"proof-invalid"}

\* Op19_Verified: a [Verify] of an attestation with material in hand and the
\* proof check held, under the current or any historical material the
\* registry answer carries, answers verified (Operation 19, Operation 21).
Op19_Verified ==
    \A i \in Ids, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ regAns = "material" /\ ProofCheck(s, up) = "held")
            => VerifyAnswers(i, up) = {"verified"}

\* Op41_MechanismUnavailable: a [Verify] of an attestation with material in
\* hand and the proof check unavailable answers mechanism-unavailable
\* (Operation 41, Check 4.2; no cached verification result exists here).
Op41_MechanismUnavailable ==
    \A i \in Ids, up \in BOOLEAN :
        (\E s \in Slots : Names(i, s) /\ regAns = "material" /\ ProofCheck(s, up) = "unavailable")
            => VerifyAnswers(i, up) = {"mechanism-unavailable"}

\* Op32_VerifiedOnlyIfHeld: a [Verify] answers verified only where the proof
\* check held (Operation 32; no cached verification result exists here, so its
\* condition holds).
Op32_VerifiedOnlyIfHeld ==
    \A i \in Ids, up \in BOOLEAN :
        "verified" \in VerifyAnswers(i, up)
            => \E s \in Slots : Names(i, s) /\ ProofCheck(s, up) = "held"

\* Op42_RevocationAsOfAttestationInstant: a [Verify] of an attestation whose
\* proof verifies, with material in hand and the mechanism up or down, answers
\* proof-invalid exactly where a revocation status names its credential
\* revoked as of attestation instant: one effective no later than it, never
\* one effective after it (Operation 42, Term proof check).
Op42_RevocationAsOfAttestationInstant ==
    \A i \in Ids, up \in BOOLEAN :
        \A s \in Slots :
            (Names(i, s) /\ regAns = "material" /\ ProofVerifies(s))
                => (("proof-invalid" \in VerifyAnswers(i, up)) <=> RevokedAtInstant(s))

\* Op27_ReadAnswersEvery: a [Read] answers every attestation the records hold
\* (Operation 27).
Op27_ReadAnswersEvery ==
    ReadIds = {aid[s] : s \in {x \in Slots : Recorded(x)}}

====

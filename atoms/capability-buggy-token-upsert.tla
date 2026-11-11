---- MODULE capability-buggy-token-upsert ----
\* DELIBERATELY WRONG twin of capability.tla (unit: `atoms/capability.md formal layer`).
\*
\* INJECTED DEFECT: [Allocate] on a token a retained capability carries overwrites that capability
\* (an upsert keyed on the token) instead of the database refusing the write (Invariant 12.2):
\* a redeemed or revoked capability comes back Allocated with a fresh counter and new provenance.
\*
\* BREAKS: Inv1_1_ProvenanceFixed, Inv2_1_CounterNeverRises, Inv7_1_RedeemedStays, Inv7_2_RevokedStays.
\* Everything else is capability.tla as written; read its comments there.

EXTENDS Integers, FiniteSets

CONSTANTS
    Slots,       \* the capability slots: how many capabilities the database can hold
    Tokens,      \* the capability tokens the seam may draw
    Refs,        \* the references a call may carry as allocator or revoked by: one, and blank ""
    ScopeCalls,  \* the scopes a call may carry: one, and blank ""
    Reasons,     \* the reasons a [Revoke] may carry: one, and blank ""
    MaxRed,      \* the largest max redemptions a call supplies
    MaxTTL,      \* the longest ttl a call supplies, in seconds
    DefaultTTL,  \* the default capability ttl of a deployment that configures one
    MaxTime      \* the last clock reading the model reaches

\* ---------------------------------------------------------------------------
\* Values
\* ---------------------------------------------------------------------------

\* Blank: the stand-in for a count or a window a call leaves blank; no count or
\* window a call supplies equals it.
Blank == -100

\* NoInstant: the value of an instant a capability does not carry (a
\* redemption instant before exhaustion, a revocation instant before revoke).
NoInstant == -1

\* MaxCalls: the max redemptions a call may carry: blank, the refused zero and
\* minus one (Operation 8, 9), and 1 to MaxRed.
MaxCalls == {Blank, -1, 0} \cup 1..MaxRed

\* TTLCalls: the ttls a call may carry: blank, the refused zero and minus one
\* (Operation 13), and 1 to MaxTTL seconds.
TTLCalls == {Blank, -1, 0} \cup 1..MaxTTL

\* Statuses: the stored status (Term status) and "none" for an empty slot.
\* Expired is not one of them (Invariant 13.1): it is derived.
Statuses == {"none", "Allocated", "Redeemed", "Revoked"}

\* NoCap: an empty slot, holding no capability.
NoCap == [status |-> "none", token |-> "none", allocator |-> "none", scope |-> "none",
          maxRed |-> 0, remRed |-> 0, allocatedAt |-> NoInstant, expiresAt |-> NoInstant,
          redeemedAt |-> NoInstant, revokedAt |-> NoInstant,
          revokedBy |-> "none", revReason |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    cap,    \* slot -> the capability record the slot holds, or NoCap
    uses,   \* slot -> the successful [Redeem] calls on the slot's capability (a history the checks read; the atom stores none)
    now,    \* the deployment's clock reading (Term now)
    deflt   \* the deployment's default capability ttl, or Blank where it configured none

\* vars: every variable, the tuple a step that changes nothing leaves as it was.
vars == <<cap, uses, now, deflt>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ \A s \in Slots :
         /\ cap[s].status \in Statuses
         /\ cap[s].token \in Tokens \cup {"none"}
         /\ cap[s].maxRed \in Int /\ cap[s].remRed \in Int
         /\ cap[s].expiresAt \in Int
    /\ uses \in [Slots -> Nat]
    /\ now \in 0..MaxTime
    /\ deflt \in {Blank, DefaultTTL}

\* ---------------------------------------------------------------------------
\* Derived (never stored)
\* ---------------------------------------------------------------------------

\* Recorded: the slot holds a capability.
Recorded(s) == cap[s].status # "none"

\* Lapsed: the capability stands in Allocated and the clock reading n is no
\* earlier than its expiry instant (Term lapsed; Expiry 6).
Lapsed(s, n) == cap[s].status = "Allocated" /\ n >= cap[s].expiresAt

\* EffStatus: Expired where the capability is lapsed, the stored status
\* otherwise (Term effective status; Invariant 13.4).
EffStatus(s, n) == IF Lapsed(s, n) THEN "Expired" ELSE cap[s].status

\* Holding: the slots whose capability carries token t (Identity 1: a
\* capability is named by its token).
Holding(t) == {s \in Slots : Recorded(s) /\ cap[s].token = t}

\* Window: the ttl the call supplied, or the default capability ttl where it
\* supplied none (Operation 10).
Window(ttl) == IF ttl = Blank THEN deflt ELSE ttl

\* Count: the max redemptions the call supplied, or the single-use default of
\* one where it supplied none (Operation 6).
Count(m) == IF m = Blank THEN 1 ELSE m

\* Provenance: the fields Invariant 1.1 holds fixed: capability token,
\* allocator reference, scope, max redemptions, allocation instant, expiry
\* instant.
Provenance(r) == <<r.token, r.allocator, r.scope, r.maxRed, r.allocatedAt, r.expiresAt>>

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* Init: the deployment has configured a default capability ttl or not; the
\* database holds no capability; the clock reads 0.
Init ==
    /\ cap = [s \in Slots |-> NoCap]
    /\ uses = [s \in Slots |-> 0]
    /\ now = 0
    /\ deflt \in {Blank, DefaultTTL}

\* Allocate: [Allocate] with token t drawn at the seam, allocator reference a,
\* scope sc, max redemptions m and ttl w. Refused, writing nothing, on a blank
\* reference or scope (Operation 4, 5), a count not above zero (Operation 7
\* to 9), a ttl not above the zero duration (Operation 12, 13), or no
\* configured default (Operation 11); and the database refuses a write that
\* would reuse a token a retained capability carries (Invariant 12.2), which
\* answers storage-failure. Otherwise one capability lands in the first free
\* slot, in Allocated, its counter at max redemptions, stamped from now with the
\* expiry deadline now + window (Operation 1, 2, 14, 15, 17).
Allocate(t, a, sc, m, w) ==
    /\ a # ""
    /\ sc # ""
    /\ (m = Blank \/ m > 0)
    /\ (w = Blank \/ w > 0)
    /\ deflt # Blank
    /\ \E s \in Slots :
         /\ IF Holding(t) # {} THEN s \in Holding(t)     \* BUG: overwrite the capability carrying t
            ELSE /\ ~Recorded(s)
                 /\ \A x \in Slots : ~Recorded(x) => s <= x
         /\ cap' = [cap EXCEPT ![s] =
                      [status |-> "Allocated", token |-> t, allocator |-> a, scope |-> sc,
                       maxRed |-> Count(m), remRed |-> Count(m),
                       allocatedAt |-> now, expiresAt |-> now + Window(w),
                       redeemedAt |-> NoInstant, revokedAt |-> NoInstant,
                       revokedBy |-> "none", revReason |-> "none"]]
         /\ uses' = [uses EXCEPT ![s] = 0]
    /\ UNCHANGED <<now, deflt>>

\* Redeem: [Redeem] presenting token t and nothing else (Invariant 3.1). A
\* token no capability carries answers not-known and is no step (Operation 23).
\* Where the effective status is Allocated the call redeems: the counter falls
\* by one, and where it reaches zero the capability stands in Redeemed stamped
\* from now (Operation 69, 71, 32, 33). Where it is Redeemed, Revoked or
\* Expired the call answers exhausted, revoked or expired and writes nothing
\* (Operation 24, 25, 26, 31).
Redeem(t) ==
    /\ Holding(t) # {}
    /\ LET s == CHOOSE x \in Holding(t) : TRUE
       IN  IF EffStatus(s, now) = "Allocated"
           THEN /\ cap' = [cap EXCEPT
                             ![s].remRed = cap[s].remRed - 1,
                             ![s].status = IF cap[s].remRed = 1 THEN "Redeemed" ELSE "Allocated",
                             ![s].redeemedAt = IF cap[s].remRed = 1 THEN now ELSE NoInstant]
                /\ uses' = [uses EXCEPT ![s] = uses[s] + 1]
           ELSE UNCHANGED <<cap, uses>>
    /\ UNCHANGED <<now, deflt>>

\* Revoke: [Revoke] on token t by reference by with reason why. Refused,
\* writing nothing, where no capability carries t (Operation 35), where it is
\* not revocable — stored Redeemed or Revoked, or lapsed (Operation 36 to 38) —
\* or where the reference or the reason is blank (Operation 39, 40).
\* Otherwise the capability stands in Revoked, stamped from now, carrying the
\* reference and the reason, its counter untouched (Operation 41 to 44, 46).
Revoke(t, by, why) ==
    /\ Holding(t) # {}
    /\ LET s == CHOOSE x \in Holding(t) : TRUE
       IN  /\ EffStatus(s, now) = "Allocated"
           /\ by # ""
           /\ why # ""
           /\ cap' = [cap EXCEPT ![s].status = "Revoked", ![s].revokedAt = now,
                                 ![s].revokedBy = by, ![s].revReason = why]
    /\ UNCHANGED <<uses, now, deflt>>

\* Tick: the clock moves on a second. Nothing is called, so nothing is written:
\* a window that closes is read, never stamped (Expiry 2 to 5).
Tick ==
    /\ now < MaxTime
    /\ now' = now + 1
    /\ UNCHANGED <<cap, uses, deflt>>

\* Next: any call of any arguments, or the clock moving on.
Next ==
    \/ \E t \in Tokens, a \in Refs, sc \in ScopeCalls, m \in MaxCalls, w \in TTLCalls :
          Allocate(t, a, sc, m, w)
    \/ \E t \in Tokens : Redeem(t)
    \/ \E t \in Tokens, by \in Refs, why \in Reasons : Revoke(t, by, why)
    \/ Tick

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_ProvenanceFixed: no step changes a recorded capability's token,
\* allocator reference, scope, max redemptions, allocation instant or expiry
\* instant (Invariant 1.1; Identity 7, Invariant 8.1, Operation 16; Check 1.2).
Inv1_1_ProvenanceFixed ==
    [][\A s \in Slots : Recorded(s) => Provenance(cap'[s]) = Provenance(cap[s])]_vars

\* Inv2_1_CounterNeverRises: no step raises a capability's remaining
\* redemptions (Invariant 2.1).
Inv2_1_CounterNeverRises ==
    [][\A s \in Slots : Recorded(s) => cap'[s].remRed <= cap[s].remRed]_vars

\* Inv2_3_CounterAtMostMax: in every reachable state, no capability's
\* remaining redemptions exceed its max redemptions (Invariant 2.3, Check 2.2).
Inv2_3_CounterAtMostMax ==
    \A s \in Slots : Recorded(s) => cap[s].remRed <= cap[s].maxRed

\* Inv2_5_CounterNotNegative: in every reachable state, no capability's
\* remaining redemptions are below zero (Invariant 2.5, Check 2.1).
Inv2_5_CounterNotNegative ==
    \A s \in Slots : Recorded(s) => cap[s].remRed >= 0

\* Inv4_4_RedeemsAtMostMax: the successful [Redeem] calls on one capability,
\* over the whole behaviour, never exceed its max redemptions (Invariant 4.4).
Inv4_4_RedeemsAtMostMax ==
    \A s \in Slots : Recorded(s) => uses[s] <= cap[s].maxRed

\* Op31_71_OnlyARedemptionLowers: a step that moves a capability's counter, or
\* counts a successful redemption on it, does both: it lowers the counter by
\* exactly one and counts exactly one redemption. So a refused [Redeem], a
\* [Revoke] and a lapse lower nothing (Operation 31, 46; Expiry 3), and a
\* redeeming [Redeem] lowers by one (Operation 71).
Op31_71_OnlyARedemptionLowers ==
    [][\A s \in Slots :
         (Recorded(s) /\ (cap'[s].remRed # cap[s].remRed \/ uses'[s] # uses[s]))
            => (cap'[s].remRed = cap[s].remRed - 1 /\ uses'[s] = uses[s] + 1)]_vars

\* Inv6_1_RedeemedStamped: every redeemed capability carries a redemption
\* instant and a counter of zero (Invariant 6.1, State 4; Check 2.3).
Inv6_1_RedeemedStamped ==
    \A s \in Slots : cap[s].status = "Redeemed" =>
        (cap[s].redeemedAt # NoInstant /\ cap[s].remRed = 0)

\* Inv7_1_RedeemedStays: no step takes a capability out of Redeemed
\* (Invariant 7.1, State 11).
Inv7_1_RedeemedStays ==
    [][\A s \in Slots : cap[s].status = "Redeemed" => cap'[s] = cap[s]]_vars

\* Inv7_2_RevokedStays: no step takes a capability out of Revoked
\* (Invariant 7.2, State 12).
Inv7_2_RevokedStays ==
    [][\A s \in Slots : cap[s].status = "Revoked" => cap'[s] = cap[s]]_vars

\* Inv7_3_LapsedAdmitsNoWrite: no step writes to a capability that is lapsed
\* at the step's clock reading: neither [Redeem] nor [Revoke] nor anything else
\* (Invariant 7.3; Operation 26, 38).
Inv7_3_LapsedAdmitsNoWrite ==
    [][\A s \in Slots : Lapsed(s, now) => cap'[s] = cap[s]]_vars

\* Inv9_RevocationAttributed: every revoked capability carries a revocation
\* instant, and a revoked by reference and a revocation reason that are not
\* blank (Invariant 9.1 to 9.3, 6.2; Check 6.1).
Inv9_RevocationAttributed ==
    \A s \in Slots : cap[s].status = "Revoked" =>
        /\ cap[s].revokedAt # NoInstant
        /\ cap[s].revokedBy \notin {"", "none"}
        /\ cap[s].revReason \notin {"", "none"}

\* Inv10_FiniteLifetime: every capability the atom records carries an expiry
\* instant (Invariant 10.1, 10.2; Check 1.1).
Inv10_FiniteLifetime ==
    \A s \in Slots : Recorded(s) => cap[s].expiresAt # NoInstant

\* Inv11_2_NeverRemoved: no step removes a capability from the database
\* (Invariant 11.2, State 13).
Inv11_2_NeverRemoved ==
    [][\A s \in Slots : Recorded(s) => cap'[s].status # "none"]_vars

\* Inv12_1_TokensUnique: no two retained capabilities share a capability
\* token, so [Redeem] and [Revoke] find one capability or none (Invariant 12.1,
\* 12.4; Identity 6).
Inv12_1_TokensUnique ==
    \A s1, s2 \in Slots :
        (s1 # s2 /\ Recorded(s1) /\ Recorded(s2)) => cap[s1].token # cap[s2].token

\* Inv13_3_LapseWritesNothing: a step in which only the clock moves writes no
\* capability: a window closing fires no transition and lowers no counter
\* (Invariant 13.3; Expiry 2, 3, 4).
Inv13_3_LapseWritesNothing ==
    [][now' # now => (cap' = cap /\ uses' = uses)]_vars

\* Emergent_ZeroCounterRedeemed: a capability whose remaining redemptions are
\* zero stands in Redeemed (the page's first entailed property, from
\* Operation 71, 32, 46 and Expiry 3; Check 2.4).
Emergent_ZeroCounterRedeemed ==
    \A s \in Slots : (Recorded(s) /\ cap[s].remRed = 0) => cap[s].status = "Redeemed"

\* Emergent_RevokedKeepsUses: a revoked capability's remaining redemptions are
\* above zero (the page's second entailed property, from [Revoke]'s guard and
\* Operation 46; Check 5.2).
Emergent_RevokedKeepsUses ==
    \A s \in Slots : cap[s].status = "Revoked" => cap[s].remRed > 0

====

---- MODULE credential-buggy-overdue ----
\* Grace Commons — Credential atom: BUGGY TWIN — Capability requirement 23.
\* Mirrors credential.tla (re-derived 2026-09-29) with one change: a call whose
\* section was released as overdue still commits. A second register takes the
\* section, passes its check and commits, and the overdue holder's stale commit
\* lands beside it.
\* Expected result: Safety VIOLATED (Inv_EffectiveActiveUniqueness).

EXTENDS Naturals, FiniteSets

CONSTANT MaxClock           \* the clock saturates here
CONSTANT MaxC               \* credential slots for the pair
CONSTANT Calls              \* concurrent register and rotate calls

Slots      == 1..MaxC
Ids        == 1..Calls
NoDeadline == MaxClock + 1  \* a credential with no expiry instant (never lapses)
StoredStatus == {"none", "Active", "Rotated", "Revoked"}

VARIABLES
    status,      \* Slots -> StoredStatus; no stored Expired (State 6)
    successor,   \* Slots -> 0..MaxC; 0 = no link
    deadline,    \* Slots -> 0..NoDeadline; the credential's own expiry instant
    registered,  \* Slots -> 0..MaxClock; the registration instant
    now,         \* the host clock
    kind,        \* Ids -> {"idle", "reg", "rot", "done"}
    reading,     \* Ids -> 0..MaxClock; the call's one reading of now
    target,      \* Ids -> 0..MaxC; the prior credential a rotate names
    phase,       \* Ids -> {"begun", "checked"}
    holder       \* 0..Calls; who holds the pair's critical section

vars == <<status, successor, deadline, registered, now, kind, reading, target, phase, holder>>

TypeOK ==
    /\ status \in [Slots -> StoredStatus]
    /\ successor \in [Slots -> 0..MaxC]
    /\ deadline \in [Slots -> 0..NoDeadline]
    /\ registered \in [Slots -> 0..MaxClock]
    /\ now \in 0..MaxClock
    /\ kind \in [Ids -> {"idle", "reg", "rot", "done"}]
    /\ reading \in [Ids -> 0..MaxClock]
    /\ target \in [Ids -> 0..MaxC]
    /\ phase \in [Ids -> {"begun", "checked"}]
    /\ holder \in 0..Calls

\* The store may begin empty or holding one active credential registered at 0,
\* with any deadline or none, so two calls reach every race over one prior.
Init ==
    /\ status \in {[k \in Slots |-> IF k = 1 THEN s1 ELSE "none"] : s1 \in {"none", "Active"}}
    /\ deadline \in {[k \in Slots |-> IF k = 1 THEN d1 ELSE 0] : d1 \in 1..NoDeadline}
    /\ successor = [k \in Slots |-> 0]
    /\ registered = [k \in Slots |-> 0]
    /\ now = 0
    /\ kind = [i \in Ids |-> "idle"]
    /\ reading = [i \in Ids |-> 0]
    /\ target = [i \in Ids |-> 0]
    /\ phase = [i \in Ids |-> "begun"]
    /\ holder = 0

\* The window reading (Term live, lapsed): a stored-active credential reads
\* lapsed once the reading does not precede its deadline. Derived, never stored.
Lapsed(k, c)    == status[k] = "Active" /\ c >= deadline[k]
EffActive(k, c) == status[k] = "Active" /\ ~Lapsed(k, c)
EffActiveCount(c) == Cardinality({k \in Slots : EffActive(k, c)})
EffStatus(k, c) == IF Lapsed(k, c) THEN "Expired" ELSE status[k]

\* A settled reading: no registration instant of the pair follows it.
Settled(c) == \A k \in Slots : status[k] # "none" => registered[k] <= c

Tick ==
    /\ now < MaxClock
    /\ now' = now + 1
    /\ UNCHANGED <<status, successor, deadline, registered, kind, reading, target, phase, holder>>

\* A call begins: it takes its one reading of now.
BeginRegister(i) ==
    /\ kind[i] = "idle"
    /\ kind' = [kind EXCEPT ![i] = "reg"]
    /\ reading' = [reading EXCEPT ![i] = now]
    /\ UNCHANGED <<status, successor, deadline, registered, now, target, phase, holder>>

BeginRotate(i) ==
    /\ kind[i] = "idle"
    /\ \E t \in Slots :
        /\ status[t] # "none"                      \* Operation 27: a known credential
        /\ kind' = [kind EXCEPT ![i] = "rot"]
        /\ target' = [target EXCEPT ![i] = t]
        /\ reading' = [reading EXCEPT ![i] = now]
    /\ UNCHANGED <<status, successor, deadline, registered, now, phase, holder>>

\* The call takes the pair's section and runs its checks at its own reading.
Pass(i) ==
    LET r == reading[i]
        t == target[i]
    IN  IF kind[i] = "reg"
        THEN EffActiveCount(r) = 0                  \* Operation 6, 8
        ELSE EffActive(t, r) /\ ~(\E k \in Slots : k # t /\ EffActive(k, r))           \* Operation 28, 65

Enter(i) ==
    /\ kind[i] \in {"reg", "rot"}
    /\ phase[i] = "begun"
    /\ holder = 0
    /\ IF Pass(i)
       THEN /\ phase' = [phase EXCEPT ![i] = "checked"]
            /\ holder' = i
            /\ UNCHANGED kind
       ELSE /\ kind' = [kind EXCEPT ![i] = "done"]    \* refused; the section is not kept
            /\ UNCHANGED <<phase, holder>>
    /\ UNCHANGED <<status, successor, deadline, registered, now, reading, target>>

\* The commit: a fresh slot, the call's reading as registration instant, and a
\* deadline after the reading or none (Operation 5, 12, 13, 61 through 63, 71, 72).
Commit(i) ==
    /\ phase[i] = "checked"
    /\ kind[i] \in {"reg", "rot"}
    /\ TRUE
    /\ \E m \in Slots, d \in (reading[i] + 1)..NoDeadline :
        /\ status[m] = "none"
        /\ registered' = [registered EXCEPT ![m] = reading[i]]
        /\ deadline' = [deadline EXCEPT ![m] = d]
        /\ IF kind[i] = "reg"
           THEN /\ status' = [status EXCEPT ![m] = "Active"]
                /\ UNCHANGED successor
           ELSE /\ status' = [status EXCEPT ![m] = "Active", ![target[i]] = "Rotated"]
                /\ successor' = [successor EXCEPT ![target[i]] = m]
    /\ kind' = [kind EXCEPT ![i] = "done"]
    /\ holder' = 0
    /\ UNCHANGED <<now, reading, target, phase>>

\* A holder released as overdue (Capability requirement 21, 22), and its write
\* then refused as storage-failure (Capability requirement 23).
Overdue(i) ==
    /\ holder = i
    /\ holder' = 0
    /\ UNCHANGED <<status, successor, deadline, registered, now, kind, reading, target, phase>>

Refused(i) ==
    /\ phase[i] = "checked"
    /\ kind[i] \in {"reg", "rot"}
    /\ holder # i
    /\ kind' = [kind EXCEPT ![i] = "done"]
    /\ UNCHANGED <<status, successor, deadline, registered, now, reading, target, phase, holder>>

\* Revoke: no section; the standing check and the write are one step at now.
Revoke ==
    /\ \E k \in Slots :
        /\ EffActive(k, now)
        /\ status' = [status EXCEPT ![k] = "Revoked"]
    /\ UNCHANGED <<successor, deadline, registered, now, kind, reading, target, phase, holder>>

Next ==
    \/ Tick \/ Revoke
    \/ \E i \in Ids : BeginRegister(i) \/ BeginRotate(i) \/ Enter(i) \/ Commit(i) \/ Overdue(i) \/ Refused(i)

Spec == Init /\ [][Next]_vars

\* Invariant 2.1, at every settled reading.
Inv_EffectiveActiveUniqueness ==
    \A c \in 0..MaxClock : Settled(c) => EffActiveCount(c) <= 1

\* Invariant 7.1.
Inv_RotationChain == \A k \in Slots : status[k] = "Rotated" => successor[k] # 0

\* State 6: no stored Expired; Invariant 12: a stored terminal reads as itself.
Inv_NoStoredExpired == \A k \in Slots : status[k] \in StoredStatus
Inv_DerivedExpiryCoherent ==
    \A k \in Slots, c \in 0..MaxClock : status[k] \in {"Rotated", "Revoked"} => EffStatus(k, c) = status[k]

Safety ==
    /\ TypeOK
    /\ Inv_EffectiveActiveUniqueness
    /\ Inv_RotationChain
    /\ Inv_NoStoredExpired
    /\ Inv_DerivedExpiryCoherent

====

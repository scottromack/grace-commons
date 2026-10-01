---- MODULE audit-trail-binding ----
\* The binding-set predicate against an in-flight cascade (Second half 14, Second half 15).
\* One attestation: either its event exists (hasEvent) and is purged by [Purge Event] steps 1, 2, 3, or no event exists (a real orphan).
\* The scan reads the payloads first, then the destruction records, and compensates an attestation in neither read.
\* NOT MODELED: the critical sections, the age filters, the horizon, the reconciliation writes themselves (audit-trail.tla, audit-trail-record.tla carry those).
\* The scan's read of a purged event's payload as unreadable rather than refused or omitted rests on erasure mechanism 6a, which the model assumes.
EXTENDS Naturals

VARIABLES hasEvent, ret, dest, content, sc, seenP, seenD, comp
vars == <<hasEvent, ret, dest, content, sc, seenP, seenD, comp>>

TypeOK ==
    /\ hasEvent \in BOOLEAN
    /\ ret \in {"Retained", "Purged"}
    /\ dest \in BOOLEAN
    /\ content \in {"readable", "destroyed"}
    /\ sc \in {"idle", "p1", "p2", "done"}
    /\ seenP \in BOOLEAN
    /\ seenD \in BOOLEAN
    /\ comp \in BOOLEAN

Init ==
    /\ hasEvent \in BOOLEAN
    /\ ret = "Retained"
    /\ dest = FALSE
    /\ content = "readable"
    /\ sc = "idle"
    /\ seenP = FALSE
    /\ seenD = FALSE
    /\ comp = FALSE

PStep1 ==
    /\ hasEvent
    /\ ret = "Retained"
    /\ ret' = "Purged"
    /\ UNCHANGED <<hasEvent, dest, content, sc, seenP, seenD, comp>>

PStep2 ==
    /\ hasEvent
    /\ ret = "Purged"
    /\ ~dest
    /\ dest' = TRUE
    /\ UNCHANGED <<hasEvent, ret, content, sc, seenP, seenD, comp>>

PStep3 ==
    /\ hasEvent
    /\ dest
    /\ content = "readable"
    /\ content' = "destroyed"
    /\ UNCHANGED <<hasEvent, ret, dest, sc, seenP, seenD, comp>>

\* First enumeration: every payload the full enumeration reads, whatever the retention state.
SReadPayload ==
    /\ sc = "idle"
    /\ seenP' = (hasEvent /\ content = "readable")
    /\ sc' = "p1"
    /\ UNCHANGED <<hasEvent, ret, dest, content, seenD, comp>>

\* Second enumeration: the destruction records, read after the first.
SReadDest ==
    /\ sc = "p1"
    /\ seenD' = (hasEvent /\ dest)
    /\ sc' = "p2"
    /\ UNCHANGED <<hasEvent, ret, dest, content, seenP, comp>>

SDecide ==
    /\ sc = "p2"
    /\ comp' = (~seenP /\ ~seenD)
    /\ sc' = "done"
    /\ UNCHANGED <<hasEvent, ret, dest, content, seenP, seenD>>

Next == PStep1 \/ PStep2 \/ PStep3 \/ SReadPayload \/ SReadDest \/ SDecide

Spec == Init /\ [][Next]_vars

\* No lawfully held attestation is compensated.
Inv_NoFalseOrphan == comp => ~hasEvent
\* Non-vacuity: a real orphan is found.
Inv_FindsRealOrphan == (sc = "done" /\ ~hasEvent) => comp
====

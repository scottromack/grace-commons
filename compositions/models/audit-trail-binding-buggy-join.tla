---- MODULE audit-trail-binding-buggy-join ----
\* BUGGY TWIN: the first enumeration matches the attestation against any readable payload, not against its own event (the join drops the event-exists key), so a real orphan reads as bound and is never compensated (Inv_FindsRealOrphan violated).
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
    \* BUG: the payload read does not key on the attestation's own event.
    /\ seenP' = (content = "readable")
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

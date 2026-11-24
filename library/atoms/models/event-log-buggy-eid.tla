---- MODULE event-log-buggy-eid ----
\* Grace Commons — Event Log atom: BUGGY TWIN — Invariant 6 (no id reuse).
\* Identical to event-log.tla EXCEPT it adds the EidRestart action: the event_id
\* allocator is an in-memory counter that a process restart starts again at 1,
\* while the committed log survives. The next landed event is minted an event_id
\* an earlier event already carries. The sequence allocator is left durable, so
\* Invariant 3 and Invariant 4 still hold.
\*
\* Expected result: Inv6_NoIdReuse VIOLATED by  AppendOk -> EidRestart ->
\* AppendOk : position 1 and position 2 both carry event_id 1.

EXTENDS Naturals

CONSTANTS MaxLen,           \* bound on number of landed events (finiteness)
          MaxSeq            \* bound on the sequence-number allocator (finiteness)

EmptyEvt == [eid |-> 0, seq |-> 0]   \* marks an unfilled log slot

VARIABLES
    log,                    \* 1..MaxLen -> event record ; insertion order
    len,                    \* number of landed events
    next_seq,               \* next sequence_number to allocate (starts at 1)
    next_eid                \* next event_id to allocate (opaque, here a counter)

vars == <<log, len, next_seq, next_eid>>

TypeOK ==
    /\ len \in 0..MaxLen
    /\ next_seq \in 1..(MaxSeq + 1)
    /\ next_eid \in 1..(MaxLen + 1)
    /\ log \in [1..MaxLen -> [eid: 0..(MaxLen + 1), seq: 0..MaxSeq]]

Init ==
    /\ log = [i \in 1..MaxLen |-> EmptyEvt]
    /\ len = 0
    /\ next_seq = 1                     \* fresh log: sequence numbers begin at 1
    /\ next_eid = 1

\* append(data) success: allocate seq = next_seq, fresh event_id, land at tail.
AppendOk ==
    /\ len < MaxLen
    /\ next_seq <= MaxSeq
    /\ log' = [log EXCEPT ![len + 1] = [eid |-> next_eid, seq |-> next_seq]]
    /\ len' = len + 1
    /\ next_seq' = next_seq + 1
    /\ next_eid' = next_eid + 1

\* append(data) storage-failure, more generous than the page: a sequence number
\* is consumed and no event lands. The page leaves next_seq unchanged on a
\* refused append (State 6, Execution Contract Database 1); the action is kept so
\* monotonicity is checked over gapped runs too.
AppendStorageFail ==
    /\ next_seq <= MaxSeq
    /\ next_seq' = next_seq + 1
    /\ UNCHANGED <<log, len, next_eid>>

\* BUG: a restart loses the event_id counter and starts it again at 1.
EidRestart ==
    /\ next_eid' = 1
    /\ UNCHANGED <<log, len, next_seq>>

Next == AppendOk \/ AppendStorageFail \/ EidRestart
Spec == Init /\ [][Next]_vars

\* --- safety invariants (the verification surface) ---

\* Invariant 4 — sequence-number monotonicity. Earlier append (smaller position
\* in insertion order) => strictly smaller sequence_number. THE load-bearing
\* claim; holds over landed events even when storage-failure gaps the sequence.
Inv4_Monotonic ==
    \A i, j \in 1..len : (i < j) => (log[i].seq < log[j].seq)

\* Invariant 3 — total order: distinct landed events have distinct seq numbers.
Inv3_TotalOrder ==
    \A i, j \in 1..len : (i # j) => (log[i].seq # log[j].seq)

\* Invariant 6 — no event_id reuse.
Inv6_NoIdReuse ==
    \A i, j \in 1..len : (i # j) => (log[i].eid # log[j].eid)

\* Invariant 1 — append-only. Promoted from a by-construction assumption to an
\* explicit check (2026-06-04 coverage cross-check): the log is a contiguous
\* filled prefix — every position <= len is a landed event, every position > len
\* is empty. A malformed append (a hole, or a write past the tail, or a removal
\* leaving a gap) violates this; append-only/monotonic growth is the consequence.
Inv1_AppendOnlyPrefix ==
    \A i \in 1..MaxLen : (i <= len) <=> (log[i] # EmptyEvt)

Safety == TypeOK /\ Inv4_Monotonic /\ Inv3_TotalOrder /\ Inv6_NoIdReuse
              /\ Inv1_AppendOnlyPrefix

\* NOTE Invariant 2 (event immutability) remains enforced by construction: no
\* action rewrites a filled slot — AppendOk only ever writes position len+1.

====

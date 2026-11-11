---- MODULE event-log-buggy-remove ----
\* Grace Commons — Event Log atom: BUGGY TWIN — Invariant 1 (append-only).
\* Identical to event-log.tla EXCEPT it adds the Remove action: a delete-by-id
\* surface (an erasure or cleanup endpoint) that blanks a landed event in place,
\* which Invariant 1.2 forbids — the atom MUST NOT remove an event.
\*
\* Expected result: Inv1_AppendOnlyPrefix VIOLATED by  AppendOk -> Remove(1) :
\* position 1 is at or below len but holds no event.

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

\* BUG: an event already in the log is removed.
Remove(i) ==
    /\ i \in 1..len
    /\ log' = [log EXCEPT ![i] = EmptyEvt]
    /\ UNCHANGED <<len, next_seq, next_eid>>

Next == AppendOk \/ AppendStorageFail \/ \E i \in 1..MaxLen : Remove(i)
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

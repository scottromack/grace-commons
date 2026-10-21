---- MODULE event-log ----
\* Grace Commons — Event Log atom.
\* Spec-level formal sibling of atoms/event-log.md.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* WHAT THIS MODEL CHECKS
\* The load-bearing claims (per the atom's formal-layer vote) are Invariant 4
\* (sequence-number monotonicity: an event appended earlier has a strictly
\* smaller sequence_number) and Invariant 1 (append-only). Also checked:
\* Invariant 3 (total order — distinct events have distinct sequence_numbers)
\* and Invariant 6 (no event_id reuse). These are the *replay* and *identity*
\* properties that distinguish an Event Log from a mutable record set.
\*
\* MODELING CHOICES
\* - The log is an insertion-ordered function 1..MaxLen -> event record
\*   {eid, seq}, with `len` filled positions; `next_seq`/`next_eid` are the
\*   monotonic allocators. The Sequences module is avoided to stay in the
\*   checker's supported fragment (Naturals/FiniteSets/functions).
\* - AppendStorageFail consumes a sequence number without landing an event,
\*   which the page rules out: a refused append writes nothing (Execution
\*   Contract Store 1), and State 6 raises next_seq only for an append that
\*   answers event id (Final Critique 5, 2026-10-20, tombstoned the Sequence
\*   gap rules). The model is more generous than the page, so the check still
\*   confronts monotonicity over a gapped sequence; holding there, it holds
\*   over the page's dense one.
\*
\* NOT MODELED (out of scope for the load-bearing property)
\* - Payload validation (invalid-payload) and query well-formedness
\*   (invalid-query) — input guards, not ordering claims.
\* - Read consistency (Invariant 5) — a query-shape property; the ordering it
\*   relies on is exactly Invariant 4, which is checked here.
\* - Recording instant (Invariant 7) — an annotation the English promises no
\*   order for (Invariant 7.1 tombstoned to Invariant 7.2 at Final Critique 5);
\*   sequence_number is the authoritative order, checked here.

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
\* refused append (State 6, Execution Contract Store 1); the action is kept so
\* monotonicity is checked over gapped runs too.
AppendStorageFail ==
    /\ next_seq <= MaxSeq
    /\ next_seq' = next_seq + 1
    /\ UNCHANGED <<log, len, next_eid>>

Next == AppendOk \/ AppendStorageFail
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

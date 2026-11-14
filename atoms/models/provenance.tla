---- MODULE provenance ----
\* Grace Commons — Provenance atom (atoms/provenance.md).
\* Grounded on Final Critique 13, 2026-11-03 at e0a85af — TLA+ layer authored 2026-11-12.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: a chain opened by [Originate] and appended to
\* by [Transfer], [Transform], [Disclose] and [Archive] over a sequence of calls,
\* while the host's clock reads whatever it reads (a skewed or dishonest clock
\* included), what [Read] answers, and what a refused call leaves. What one
\* state of a chain's entries must carry about custody (Invariant 4.2 to 4.4,
\* 5.1, 7.1 and 7.2) is the Alloy model's, provenance.als.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1  — a recorded entry's fields never change     (Inv1_1_EntryFixed)
\*   Invariant 2.1  — a chain's entry count never falls          (Inv2_1_CountNeverFalls)
\*   Invariant 2.2  — a recorded entry's sequence number never
\*                    changes                                    (Inv2_2_SequenceFixed)
\*   Invariant 3.1  — every chain carries exactly one genesis
\*                    entry                                      (Inv3_1_OneGenesis)
\*   Invariant 3.2  — the genesis entry stands at sequence one   (Inv3_2_GenesisAtOne)
\*   Invariant 3.3  — no originate against a recorded chain      (Inv3_3_NoSecondOriginate)
\*   Invariant 4.1  — every open chain carries exactly one
\*                    current custodian, the one its entries
\*                    name (State 18 with it)                    (Inv4_1_OneCurrentCustodian)
\*   Invariant 5.2  — a chain's sequence numbers stand from one
\*                    to its entry count                         (Inv5_2_DenseFromOne)
\*   Invariant 5.3  — a chain's order rests on sequence number
\*                    alone (Operation 46 and 58 with it)        (Inv5_3_OrderBySequence)
\*   Invariant 6.1  — an archived chain never leaves archived    (Inv6_1_ArchivedStays)
\*   Invariant 6.2  — an archived chain admits no entry          (Inv6_2_ArchivedAdmitsNothing)
\*   Invariant 8.2  — a genesis entry's event type is a genesis
\*                    type                                       (Inv8_2_GenesisTyped)
\*   Invariant 8.3  — a non-genesis entry's event type is not a
\*                    genesis type                               (Inv8_3_LaterNotGenesis)
\*   Invariant 8.4  — an archived chain's last entry is the
\*                    archived entry                             (Inv8_4_ArchivedLast)
\*   Invariant 10.1 — the chain count never falls                (Inv10_1_ChainsNeverFall)
\*   Operation 42 to 44 — a refused action leaves the chain as
\*                    the call found it, appends no entry and
\*                    takes no sequence number                   (Op42_RefusedLeavesChain)
\*
\* THE WORLD AROUND THE CHAIN
\* The host allocates a chain id (Identity 3, 15) and an entry id (Identity 4,
\* 16) at the seam: a call here names a chain slot, and [Originate] takes a slot
\* no chain holds; the entry ids come from the host's own counter. The host
\* injects now (Capability requirement 1), and the clock may read any instant at
\* any step, backwards too (Skew): the page orders by sequence number so that a
\* dishonest clock changes nothing else (Summary, Operation 58).
\*
\* THE MODEL'S OWN RECORDS
\* log[c] holds a chain's entries in the order the model appended them: the
\* store holds a set, and [Read] orders it by sequence number, never by place
\* in log. Each entry carries one field of the model's own, op, the action that
\* appended it, so the genesis entry is the one [Originate] appended (the page
\* stores no genesis type, State 10). last is the call just made and what it
\* answered.
\*
\* BOUNDS (the .cfg)
\* One chain slot, room for three entries, two custodian references and the
\* blank one, three genesis-type inputs (one outside the genesis types), two
\* clock readings: 8,314 distinct states, about 20 s on one worker. Every chain
\* state, a transfer, a transform, a disclose, an archive after a transfer, a
\* storage failure and a read after a skewed append are reached.
\*
\* NOT MODELED HERE
\* - Artifact references, metadata and the content of a descriptor or a
\*   recipient reference (Operation 61 to 65): opaque values the atom stores
\*   as given; no rule here reads them, and the Alloy model checks no write of
\*   them either.
\* - The refusals a guard answers (Operation 1 to 3, 10 to 17, 23 to 26, String
\*   7 to 9, state-unavailable): each is one call that writes nothing
\*   (Execution Contract Read 4), and which code answers is Execution Contract
\*   Refusal 1's. Here a guard is an admitted action's precondition, and an
\*   input it refuses (a blank reference, a genesis type outside the two, a
\*   caller not the current custodian, an archived chain) enables no step.
\*   Op42_RefusedLeavesChain is checked on storage-failure, the one refusal
\*   that comes after every guard passed, where an append could be half made.
\*   Blank descriptors and recipients are not passed (Operation 24, 25).
\* - [Read]'s filters (Operation 47 to 49, 59, 60): a well-formed query's answer
\*   is a sub-sequence of the unfiltered one, in the same order; only the
\*   unfiltered order is checked.
\* - Two chains: a second chain for one artifact (Identity 10) needs a second
\*   slot in Chains, at many times the states; the checks quantify over Chains.
\* - What one state's entries carry about custody (Invariant 4.2 to 4.4, 5.1,
\*   7.1, 7.2): the Alloy model's. Invariant 8.1 (an event type is one of the
\*   six) holds by both models' typing, so no twin could break it.

EXTENDS Integers, Sequences, FiniteSets, TLC

CONSTANTS
    Chains,         \* the chain ids the host may allocate (Identity 3)
    Custodians,     \* the non-blank custodian references a call may carry
    GenesisInputs,  \* the genesis types an [Originate] may name, one outside the two
    Instants,       \* the clock readings the host may inject
    MaxLen          \* how many entries the model lets one chain hold

\* NONE: a field an entry does not carry, or a chain's custodian before it opens.
NONE == "none"

\* BLANK: a blank or whitespace-only reference (String 5); one value for all.
BLANK == "blank"

\* Descriptor, Recipient: the one transformation descriptor and the one
\* recipient reference the calls carry (opaque; see NOT MODELED HERE).
Descriptor == "d1"
Recipient == "r1"

\* GenesisTypes: what a genesis entry's event type may be (Term genesis types).
GenesisTypes == {"originated", "received"}

\* GuardedOps: the custodian-guarded actions (Term custodian-guarded action),
\* each with the event type its admitted call writes (Operation 69, 71, 73).
GuardedOps == {"transform", "disclose", "archive"}
EventOf(op) == IF op = "transform" THEN "transformed"
               ELSE IF op = "disclose" THEN "disclosed" ELSE "archived"

\* Inputs: the custodian references a caller may pass, the blank one included.
Inputs == Custodians \cup {BLANK}

\* Refused: what the model records of a call the database refused.
Refused == "refused"

\* NoChain: the chain the record before any call names.
NoChain == "nochain"

\* Answer: the record of a call: the action, the chain it named, what it
\* answered ("ok" or Refused) and, for [Read], the entry ids answered.
Answer(op, c, ans, rd) == [op |-> op, ch |-> c, ans |-> ans, read |-> rd]

\* NoCall: the record before any call, and after the clock moves.
NoCall == Answer("none", NoChain, "none", <<>>)

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    now,     \* the host's clock reading, injected at the seam
    cstate,  \* chain -> "none" (no chain), "open" or "archived" (Term chain state)
    cur,     \* chain -> the cached current custodian (Term current custodian)
    nseq,    \* chain -> next sequence number (Term next sequence number)
    log,     \* chain -> its entries, in the order the model appended them
    neid,    \* the host's next entry id (Identity 4)
    last     \* the last call made and what it answered (Answer's shape)

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<now, cstate, cur, nseq, log, neid, last>>

\* chains: the variables that hold the chain records and their entries.
chains == <<cstate, cur, nseq, log>>

\* Ent: the entries of a chain, as a set (the store's view).
Ent(c) == {log[c][i] : i \in DOMAIN log[c]}

\* Genesis: the chain's genesis entries, the ones [Originate] appended.
Genesis(c) == {e \in Ent(c) : e.op = "originate"}

\* Replay: the current custodian the chain's entries name, read as the page
\* defines it (Term current custodian): the to custodian reference of the
\* latest transferred entry by sequence number, or the genesis entry's
\* custodian reference where no transfer has landed.
Replay(c) ==
    LET T == {e \in Ent(c) : e.etype = "transferred"}
        G == Genesis(c)
    IN IF T # {} THEN (CHOOSE e \in T : \A f \in T : f.seq <= e.seq).to
       ELSE IF G # {} THEN (CHOOSE e \in G : \A f \in G : e.seq <= f.seq).cust
       ELSE NONE

\* AppendOrder: the ids of a chain's entries in the order they were appended.
AppendOrder(c) == [i \in DOMAIN log[c] |-> log[c][i].eid]

\* ReadAnswer: what [Read] answers for a chain: its entries in sequence number
\* ascending order (Operation 46), as entry ids.
ReadAnswer(c) ==
    LET s == SortSeq(log[c], LAMBDA x, y : x.seq < y.seq)
    IN [i \in DOMAIN s |-> s[i].eid]

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ now \in Instants
    /\ cstate \in [Chains -> {"none", "open", "archived"}]
    /\ cur \in [Chains -> Custodians \cup {BLANK, NONE}]
    /\ nseq \in [Chains -> Nat]
    /\ neid \in Nat

\* Init: no chain; every counter at its beginning (a next sequence number
\* begins at one); the clock at any reading.
Init ==
    /\ now \in Instants
    /\ cstate = [c \in Chains |-> "none"]
    /\ cur = [c \in Chains |-> NONE]
    /\ nseq = [c \in Chains |-> 1]
    /\ log = [c \in Chains |-> <<>>]
    /\ neid = 1
    /\ last = NoCall

\* ---------------------------------------------------------------------------
\* Actions
\* ---------------------------------------------------------------------------

\* AppendEntry: an appending action's write: one entry taking its sequence
\* number from next sequence number (Operation 36), its recording instant from
\* the injected now (Operation 40) and its id from the host; next sequence
\* number raised by one (Operation 37).
AppendEntry(c, op, et, cu, fr, to, d, r) ==
    /\ Len(log[c]) < MaxLen
    /\ log' = [log EXCEPT ![c] = Append(@, [eid |-> neid, seq |-> nseq[c], etype |-> et,
                                            at |-> now, cust |-> cu, from |-> fr, to |-> to,
                                            desc |-> d, recip |-> r, op |-> op])]
    /\ nseq' = [nseq EXCEPT ![c] = @ + 1]
    /\ neid' = neid + 1

\* Skew: the host's clock reads another instant, earlier or later; nothing is
\* written.
Skew ==
    /\ \E t \in Instants \ {now} : now' = t
    /\ last' = NoCall
    /\ UNCHANGED <<cstate, cur, nseq, log, neid>>

\* Originate: an admitted [Originate] on a chain id the host allocated, which no
\* chain holds (Identity 3, 15): a non-blank custodian reference (Operation 2)
\* and a genesis type in the two (Operation 3). It records one chain (Operation
\* 5) and appends the genesis entry (Operation 6) of the call's genesis type
\* (Operation 7) and custodian reference (Operation 63), stands the chain open
\* (Operation 8), sets the current custodian to the call's custodian reference
\* (Operation 75) and answers the chain id (Operation 9).
Originate(c, cu, g) ==
    /\ cstate[c] = "none"
    /\ cu \in Custodians
    /\ g \in GenesisTypes
    /\ AppendEntry(c, "originate", g, cu, NONE, NONE, NONE, NONE)
    /\ cstate' = [cstate EXCEPT ![c] = "open"]
    /\ cur' = [cur EXCEPT ![c] = cu]
    /\ last' = Answer("originate", c, "ok", <<>>)
    /\ UNCHANGED now

\* Transfer: an admitted [Transfer] on an open chain (Operation 12) with a
\* non-blank to custodian reference (Operation 17), guarding no caller
\* (Operation 22). It appends a transferred entry (Operation 20, 66) whose from
\* custodian reference is read from the current custodian (Operation 18, 19,
\* 67) and whose to custodian reference is the call's (Operation 68), and sets
\* the current custodian to it (Operation 21).
Transfer(c, to) ==
    /\ cstate[c] = "open"
    /\ to \in Custodians
    /\ AppendEntry(c, "transfer", "transferred", NONE, cur[c], to, NONE, NONE)
    /\ cur' = [cur EXCEPT ![c] = to]
    /\ last' = Answer("transfer", c, "ok", <<>>)
    /\ UNCHANGED <<now, cstate>>

\* Guarded: an admitted [Transform], [Disclose] or [Archive] on an open chain
\* (Operation 13 to 15) by a non-blank custodian reference (Operation 23) that
\* is the current custodian (Operation 26). It appends an entry of its event
\* type (Operation 28 to 30, 69, 71, 73) carrying the call's custodian
\* reference (Operation 70, 72, 74), the descriptor or the recipient reference
\* (Operation 64, 65); [Archive] stands the chain archived (Operation 31); none
\* changes the current custodian (Operation 32 to 34).
Guarded(c, op, cu) ==
    /\ cstate[c] = "open"
    /\ cu \in Custodians
    /\ cu = cur[c]
    /\ AppendEntry(c, op, EventOf(op), cu, NONE, NONE,
                   IF op = "transform" THEN Descriptor ELSE NONE,
                   IF op = "disclose" THEN Recipient ELSE NONE)
    /\ cstate' = [cstate EXCEPT ![c] = IF op = "archive" THEN "archived" ELSE @]
    /\ last' = Answer(op, c, "ok", <<>>)
    /\ UNCHANGED <<now, cur>>

\* StorageFailure: an appending call on an open chain whose every precondition
\* passed and whose write the database refused answers storage-failure
\* (Operation 41) and writes nothing.
StorageFailure(c, op) ==
    /\ cstate[c] = "open"
    /\ last' = Answer(op, c, Refused, <<>>)
    /\ UNCHANGED <<now, cstate, cur, nseq, log, neid>>

\* Read: [Read] of a recorded chain, open or archived (Operation 53), answers
\* its entries in sequence number order (Operation 46) and writes nothing
\* (Operation 50).
Read(c) ==
    /\ cstate[c] # "none"
    /\ last' = Answer("read", c, "ok", ReadAnswer(c))
    /\ UNCHANGED <<now, cstate, cur, nseq, log, neid>>

\* Next: the clock moving, or any call with any input a caller may pass: a call
\* its guards admit, a write the database refuses, or a read. A call a guard
\* refuses is no step here (see NOT MODELED HERE).
Next ==
    \/ Skew
    \/ \E c \in Chains, cu \in Inputs, g \in GenesisInputs : Originate(c, cu, g)
    \/ \E c \in Chains, to \in Inputs : Transfer(c, to)
    \/ \E c \in Chains, op \in GuardedOps, cu \in Inputs : Guarded(c, op, cu)
    \/ \E c \in Chains, op \in {"transfer"} \cup GuardedOps : StorageFailure(c, op)
    \/ \E c \in Chains : Read(c)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_EntryFixed: no step changes a recorded entry: the entry with the same
\* entry id after the step carries every field it carried (Invariant 1.1,
\* Check 6.1; Correction 1).
Inv1_1_EntryFixed ==
    [][\A c \in Chains : \A i \in DOMAIN log[c] : \A j \in DOMAIN log'[c] :
          log'[c][j].eid = log[c][i].eid => log'[c][j] = log[c][i]]_vars

\* Inv2_1_CountNeverFalls: no step lowers a chain's entry count (Invariant 2.1;
\* Correction 2).
Inv2_1_CountNeverFalls ==
    [][\A c \in Chains : Len(log'[c]) >= Len(log[c])]_vars

\* Inv2_2_SequenceFixed: no step changes a recorded entry's sequence number
\* (Invariant 2.2).
Inv2_2_SequenceFixed ==
    [][\A c \in Chains : \A i \in DOMAIN log[c] : \A j \in DOMAIN log'[c] :
          log'[c][j].eid = log[c][i].eid => log'[c][j].seq = log[c][i].seq]_vars

\* Inv3_1_OneGenesis: every recorded chain carries exactly one genesis entry
\* (Invariant 3.1, Check 2.1).
Inv3_1_OneGenesis ==
    \A c \in Chains : cstate[c] # "none" => Cardinality(Genesis(c)) = 1

\* Inv3_2_GenesisAtOne: every genesis entry stands at sequence number one
\* (Invariant 3.2, Check 2.2).
Inv3_2_GenesisAtOne ==
    \A c \in Chains : \A e \in Genesis(c) : e.seq = 1

\* Inv3_3_NoSecondOriginate: an [Originate] lands only on a chain id no chain
\* held before it: none is offered against a recorded chain (Invariant 3.3).
Inv3_3_NoSecondOriginate ==
    [][(last'.op = "originate" /\ last'.ans = "ok") => cstate[last'.ch] = "none"]_vars

\* Inv4_1_OneCurrentCustodian: every open chain has a current custodian, a
\* non-blank custodian reference, and it is the one the chain's entries name, so
\* the cache and the entries never stand two custodians current (Invariant 4.1,
\* State 12, 13 and 18, Check 3.1).
Inv4_1_OneCurrentCustodian ==
    \A c \in Chains : cstate[c] = "open" => (cur[c] \in Custodians /\ cur[c] = Replay(c))

\* Inv5_2_DenseFromOne: a chain's sequence numbers are exactly one to its entry
\* count (Invariant 5.2, Check 4.1).
Inv5_2_DenseFromOne ==
    \A c \in Chains : {e.seq : e \in Ent(c)} = 1..Len(log[c])

\* Inv5_3_OrderBySequence: what [Read] answers is the chain's entries in the
\* order they were appended, however the clock read at each append (Invariant
\* 5.3, Operation 46 and 58, Check 4.2).
Inv5_3_OrderBySequence ==
    last.op = "read" => last.read = AppendOrder(last.ch)

\* Inv6_1_ArchivedStays: no step moves an archived chain out of archived
\* (Invariant 6.1, State 11).
Inv6_1_ArchivedStays ==
    [][\A c \in Chains : cstate[c] = "archived" => cstate'[c] = "archived"]_vars

\* Inv6_2_ArchivedAdmitsNothing: no step adds an entry to an archived chain
\* (Invariant 6.2, Check 5.1).
Inv6_2_ArchivedAdmitsNothing ==
    [][\A c \in Chains : cstate[c] = "archived" =>
          {e.eid : e \in Ent(c)'} \subseteq {e.eid : e \in Ent(c)}]_vars

\* Inv8_2_GenesisTyped: every genesis entry's event type is a genesis type
\* (Invariant 8.2).
Inv8_2_GenesisTyped ==
    \A c \in Chains : \A e \in Genesis(c) : e.etype \in GenesisTypes

\* Inv8_3_LaterNotGenesis: no entry but the genesis entry carries a genesis
\* type (Invariant 8.3).
Inv8_3_LaterNotGenesis ==
    \A c \in Chains : \A e \in Ent(c) \ Genesis(c) : e.etype \notin GenesisTypes

\* Inv8_4_ArchivedLast: an archived chain's last entry, by sequence number, is
\* an archived entry (Invariant 8.4, Check 7.2).
Inv8_4_ArchivedLast ==
    \A c \in Chains : cstate[c] = "archived" =>
        \E e \in Ent(c) : e.etype = "archived" /\ \A f \in Ent(c) : f.seq <= e.seq

\* Inv10_1_ChainsNeverFall: no step lowers the number of recorded chains
\* (Invariant 10.1).
Inv10_1_ChainsNeverFall ==
    [][Cardinality({c \in Chains : cstate'[c] # "none"})
         >= Cardinality({c \in Chains : cstate[c] # "none"})]_vars

\* Op42_RefusedLeavesChain: a refused call leaves every chain as the call found
\* it: no entry appended, no sequence number taken, no custodian or state
\* changed (Operation 42 to 44).
Op42_RefusedLeavesChain ==
    [][last'.ans = Refused => UNCHANGED chains]_vars

====

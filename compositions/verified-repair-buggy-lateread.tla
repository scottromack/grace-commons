---- MODULE verified-repair-buggy-lateread ----
\* BUGGY TWIN: [Repair] opens the invocation before it reads the head and builds the tree (Action wiring 33's order reversed).
\* Grace Commons — Verified Repair, the commit path. Spec-level formal sibling of
\* compositions/verified-repair.md. Derived validator; the English spec is the single
\* source of truth. On any disagreement, diagnose per the entry *The conflict protocol*
\* in pressure-testing.md. The round's settling is verified-repair-settle.tla; the
\* round budget is verified-repair-budget.tla.
\*
\* ONE repository with two pages: P, with two sites a and b, and Q, with one site q.
\* Every site holds the base text 0 at the base commit, commit 0. Two rounds, each
\* already settled and frozen at commit 0: round 1 on page P, whose change set writes
\* text 1 at site a; round 2 on page Q, whose change set writes text 2 at site q. Each
\* round has a [Repair] caller that may call up to MaxTries times. A person may commit
\* to any site once (text 9). The repository is the store the page describes: a commit
\* takes a tree, a parent and a trailer, and lands only on the head it names as its
\* parent (Capability requirement 13), moving the head (Capability requirement 20).
\*
\* A [Repair] call, in the page's order:
\*   read   reads the head; the page at the head must equal the round's snapshot
\*          (Action wiring 15); every fragment's old text is found verbatim at its
\*          site (Action wiring 18); the repair tree is the head's files with the
\*          change set applied (Action wiring 23);
\*   open   the invocation open records the intent, which takes the next position
\*          in the journal's order (Action wiring 22, 33);
\*   issue  the commit is sent with the head the read took as its parent (Action
\*          wiring 26). The kind has no commit fence, so nothing bounds when a sent
\*          commit lands: it may land after its caller's reply was lost and a later
\*          call of the same round has read, opened and sent its own (Concurrency 1);
\*   end    the call ends on the reply: committed, a refusal with nothing written
\*          (conflict), or no answer, with the commit still in flight
\*          (Action wiring 27, 28, 29).
\*
\* WHAT THIS MODEL CHECKS, each read off the repository's commits alone:
\*   Inv2_1          every council commit's parent holds the round's snapshot of the
\*                   round's page (Invariant 2.1).
\*   Inv2_2          every site a council commit changes is in the round's change set,
\*                   carrying the change set's text (Invariant 2.2).
\*   Inv7_3          no council commit's intent precedes, in the journal's order, the
\*                   intent of any council-commit ancestor (Invariant 7.3).
\*   Conc1_OneWriter every commit the repository took stays on the head's history: of
\*                   two commits built on one head, at most one lands (Concurrency 1,
\*                   Capability requirement 13, 20).
\*
\* WHAT CARRIES THEM  Recoverable Invocation's critical section is not modelled, so
\* any number of invocations may be open at once. The section only removes behaviours,
\* and every invariant here holds without it: with no commit fence it bounds when a
\* commit is sent, not when one lands, so two council commits are in flight together
\* whatever it does (Probe_NeverTwoInFlight is rejected), and the head compare is what
\* lets at most one of them land. Invariant 2 rests on Action wiring 15, 23 and 26 and
\* Capability requirement 13, and not on the section, which the page's WHY of
\* Invariant 2 named at e54d344; Invariant 7.3 rests on the read coming before
\* the open (Action wiring 23, 33): a commit's council-commit ancestors had landed
\* before its call read the head, so their intents precede its own.
\*
\* THE BUDGET  MaxTries calls a round and MaxPerson person commits. Two calls give the
\* second occurrence: a call whose reply was lost leaves its commit in flight while the
\* next call of the same round reads, opens and sends. The deeper run, two person
\* commits, holds too and passes the harness's state cap (263,067 states).
\*
\* NOT MODELED
\*   - The refusals that write nothing and order nothing here: Primitive policy, the
\*     settle checks (verified-repair-settle.tla), the claim gate, the corpus gate, the
\*     diff check (Action wiring 25 is met by construction: the tree is the read head's
\*     files with the change set applied), and the patch and records rules.
\*   - Recoverable Invocation's journal writes after the intent (close, refusal, yield)
\*     and the sweep: the sweep's probe reads the repository and its closings go to the
\*     journal, so neither can change a commit (Indeterminate outcome 1).
\*   - Trailers: only a [Repair] call makes a council commit here, so Capability
\*     requirement 18, 19 and 22 hold by construction.
\*   - A person's merge commit. Every council commit lands on the head (Capability
\*     requirement 13), so every council commit is on the head's history, and a merge
\*     adds no council-commit ancestor the head lacks.
\*   - Time. No rule on this path reads the clock: the call pause bound (Action wiring
\*     26) bounds when a commit is sent, and with no commit fence nothing bounds when
\*     one lands, so every landing order is reachable here.
\*
\* TWINS AND PROBES  Each is this module byte for byte below its header, with one
\* constant or one invariant changed in its .cfg: -buggy-nocas, -buggy-nostale,
\* -buggy-basetree, -buggy-lateread; -probe-inflight, -probe-conflict, -probe-both.
EXTENDS Naturals, FiniteSets

\* Cas            TRUE: the repository refuses a commit whose parent is not the head
\*                (Capability requirement 13). FALSE: it takes the commit on the parent
\*                the commit names and moves the head there.
\* StaleCheck     TRUE: [Repair] refuses stale where the page at the head is not the
\*                snapshot (Action wiring 15).
\* TreeFromHead   TRUE: the repair tree is built from the head the read took (Action
\*                wiring 23). FALSE: from the round's base commit.
\* ReadAfterOpen  FALSE: the head is read and the tree built before the invocation
\*                open (Action wiring 23, 33). TRUE: after it.
\* MaxTries       [Repair] calls per round. MaxPerson: person commits.
CONSTANTS Cas, StaleCheck, TreeFromHead, ReadAfterOpen, MaxTries, MaxPerson

Rounds == {1, 2}
Sites == {"a", "b", "q"}
Texts == {0, 1, 2, 9}
Tries == 1..MaxTries
\* Commit ids: 0 is the base commit; each landing takes the next id.
MaxC == 2 * MaxTries + MaxPerson
Ids == 0..MaxC
\* Journal positions of intents: one per [Repair] call at most.
MaxSeq == 2 * MaxTries
Seqs == 0..MaxSeq

\* The page each round repairs, and the sites its change set writes.
PageSites(r) == IF r = 1 THEN {"a", "b"} ELSE {"q"}
ChangeSites(r) == IF r = 1 THEN {"a"} ELSE {"q"}
\* Every site holds 0 at the base commit, so every round's snapshot is all zeros.
Base == [s \in Sites |-> 0]
\* The round's change set applied to a commit's files: round r writes text r.
Apply(r, files) == [s \in Sites |-> IF s \in ChangeSites(r) THEN r ELSE files[s]]

VARIABLES
    head,     \* the repository's head
    nextId,   \* the id the next landing takes
    files,    \* files[c]: the text at each site in commit c
    par,      \* par[c]: commit c's parent
    rnd,      \* rnd[c]: the round a council commit answers; 0 for a person's commit
    cseq,     \* cseq[c]: the journal position of the intent a council commit's trailer names
    pc,       \* pc[r]: where round r's current [Repair] call stands
    tries,    \* tries[r]: [Repair] calls round r has started
    rd,       \* rd[r]: the head the current call read
    iseq,     \* iseq[r]: the journal position of the current call's intent
    nextSeq,  \* the journal position the next intent takes
    rqSt,     \* rqSt[r][t]: the commit call t sent — none, pending, landed or refused
    rqPar,    \* rqPar[r][t]: the parent that commit names
    rqSeq,    \* rqSeq[r][t]: the intent its trailer names
    persons   \* person commits so far
vars == <<head, nextId, files, par, rnd, cseq, pc, tries, rd, iseq, nextSeq, rqSt, rqPar, rqSeq, persons>>

TypeOK ==
    /\ head \in Ids
    /\ nextId \in 1..(MaxC + 1)
    /\ files \in [Ids -> [Sites -> Texts]]
    /\ par \in [Ids -> Ids]
    /\ rnd \in [Ids -> {0, 1, 2}]
    /\ cseq \in [Ids -> Seqs]
    /\ pc \in [Rounds -> {"idle", "opened0", "built", "opened", "issued", "done"}]
    /\ tries \in [Rounds -> 0..MaxTries]
    /\ rd \in [Rounds -> Ids]
    /\ iseq \in [Rounds -> Seqs]
    /\ nextSeq \in 1..(MaxSeq + 1)
    /\ rqSt \in [Rounds -> [Tries -> {"none", "pending", "landed", "refused"}]]
    /\ rqPar \in [Rounds -> [Tries -> Ids]]
    /\ rqSeq \in [Rounds -> [Tries -> Seqs]]
    /\ persons \in 0..MaxPerson
    /\ MaxC <= 7

Init ==
    /\ head = 0
    /\ nextId = 1
    /\ files = [c \in Ids |-> Base]
    /\ par = [c \in Ids |-> 0]
    /\ rnd = [c \in Ids |-> 0]
    /\ cseq = [c \in Ids |-> 0]
    /\ pc = [r \in Rounds |-> "idle"]
    /\ tries = [r \in Rounds |-> 0]
    /\ rd = [r \in Rounds |-> 0]
    /\ iseq = [r \in Rounds |-> 0]
    /\ nextSeq = 1
    /\ rqSt = [r \in Rounds |-> [t \in Tries |-> "none"]]
    /\ rqPar = [r \in Rounds |-> [t \in Tries |-> 0]]
    /\ rqSeq = [r \in Rounds |-> [t \in Tries |-> 0]]
    /\ persons = 0

\* The commits that have landed, and the council commits among them.
Landed == {c \in Ids : c < nextId}
Council == {c \in Landed : rnd[c] # 0}

\* The ancestors of commit c: its parent, its parent's parent, and so on down to the
\* base commit. Every landing takes a larger id than its parent, so seven steps reach
\* the base commit (TypeOK holds MaxC to 7).
P1(c) == par[c]
P2(c) == par[P1(c)]
P3(c) == par[P2(c)]
P4(c) == par[P3(c)]
P5(c) == par[P4(c)]
P6(c) == par[P5(c)]
P7(c) == par[P6(c)]
Anc(c) == IF c = 0 THEN {} ELSE {P1(c), P2(c), P3(c), P4(c), P5(c), P6(c), P7(c)}

\* What a read of the head finds for round r: the page at the head is the snapshot
\* (Action wiring 15), and every fragment's old text, the base text, is found
\* verbatim at its site (Action wiring 18).
PageIsSnapshot(r) == \A s \in PageSites(r) : files[head][s] = 0
OldTextFound(r) == \A s \in ChangeSites(r) : files[head][s] = 0
ReadPasses(r) == (StaleCheck => PageIsSnapshot(r)) /\ OldTextFound(r)

\* The repair tree a call of round r sends with a commit whose parent is p.
Tree(r, p) == IF TreeFromHead THEN Apply(r, files[p]) ELSE Apply(r, Base)

\* A [Repair] call starts. In the page's order it reads the head first: a read that
\* fails answers stale or mismatch and writes nothing; one that passes builds the
\* tree from the head it read (Action wiring 15, 18, 23).
StartRead(r) ==
    /\ ~ReadAfterOpen
    /\ pc[r] = "idle"
    /\ tries[r] < MaxTries
    /\ tries' = [tries EXCEPT ![r] = tries[r] + 1]
    /\ IF ReadPasses(r)
         THEN /\ pc' = [pc EXCEPT ![r] = "built"]
              /\ rd' = [rd EXCEPT ![r] = head]
         ELSE UNCHANGED <<pc, rd>>
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, iseq, nextSeq, rqSt, rqPar, rqSeq, persons>>

\* The invocation open records the intent, which takes the next journal position
\* (Action wiring 22). In the page's order it comes after the read (Action wiring 33).
Open(r) ==
    /\ ~ReadAfterOpen
    /\ pc[r] = "built"
    /\ pc' = [pc EXCEPT ![r] = "opened"]
    /\ iseq' = [iseq EXCEPT ![r] = nextSeq]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, rd, rqSt, rqPar, rqSeq, persons>>

\* ReadAfterOpen: the call opens first and reads the head afterwards.
StartOpen(r) ==
    /\ ReadAfterOpen
    /\ pc[r] = "idle"
    /\ tries[r] < MaxTries
    /\ tries' = [tries EXCEPT ![r] = tries[r] + 1]
    /\ pc' = [pc EXCEPT ![r] = "opened0"]
    /\ iseq' = [iseq EXCEPT ![r] = nextSeq]
    /\ nextSeq' = nextSeq + 1
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, rd, rqSt, rqPar, rqSeq, persons>>

LateRead(r) ==
    /\ ReadAfterOpen
    /\ pc[r] = "opened0"
    /\ IF ReadPasses(r)
         THEN /\ pc' = [pc EXCEPT ![r] = "opened"]
              /\ rd' = [rd EXCEPT ![r] = head]
         ELSE /\ pc' = [pc EXCEPT ![r] = "idle"]
              /\ rd' = [rd EXCEPT ![r] = 0]
    /\ iseq' = IF ReadPasses(r) THEN iseq ELSE [iseq EXCEPT ![r] = 0]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, nextSeq, rqSt, rqPar, rqSeq, persons>>

\* The commit is sent: the repair tree, the read head as its parent, and the council
\* trailer naming the intent (Action wiring 26).
Issue(r) ==
    /\ pc[r] = "opened"
    /\ pc' = [pc EXCEPT ![r] = "issued"]
    /\ rqSt' = [rqSt EXCEPT ![r][tries[r]] = "pending"]
    /\ rqPar' = [rqPar EXCEPT ![r][tries[r]] = rd[r]]
    /\ rqSeq' = [rqSeq EXCEPT ![r][tries[r]] = iseq[r]]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, rd, iseq, nextSeq, persons>>

\* A call that has opened may die before it sends the commit; the council may call
\* again. Its intent is the sweep's, which writes only to the journal.
Die(r) ==
    /\ pc[r] \in {"opened0", "opened"}
    /\ pc' = [pc EXCEPT ![r] = "idle"]
    /\ rd' = [rd EXCEPT ![r] = 0]
    /\ iseq' = [iseq EXCEPT ![r] = 0]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, nextSeq, rqSt, rqPar, rqSeq, persons>>

\* The repository takes a sent commit. With Cas it lands only on the head the commit
\* names as its parent and otherwise refuses with nothing written (Capability
\* requirement 13); without it, it lands on the named parent and the head moves there.
Land(r, t) ==
    /\ rqSt[r][t] = "pending"
    /\ nextId <= MaxC
    /\ (Cas => head = rqPar[r][t])
    /\ files' = [files EXCEPT ![nextId] = Tree(r, rqPar[r][t])]
    /\ par' = [par EXCEPT ![nextId] = rqPar[r][t]]
    /\ rnd' = [rnd EXCEPT ![nextId] = r]
    /\ cseq' = [cseq EXCEPT ![nextId] = rqSeq[r][t]]
    /\ head' = nextId
    /\ nextId' = nextId + 1
    /\ rqSt' = [rqSt EXCEPT ![r][t] = "landed"]
    /\ rqPar' = [rqPar EXCEPT ![r][t] = 0]
    /\ rqSeq' = [rqSeq EXCEPT ![r][t] = 0]
    /\ UNCHANGED <<pc, tries, rd, iseq, nextSeq, persons>>

Refuse(r, t) ==
    /\ rqSt[r][t] = "pending"
    /\ Cas
    /\ head # rqPar[r][t]
    /\ rqSt' = [rqSt EXCEPT ![r][t] = "refused"]
    /\ rqPar' = [rqPar EXCEPT ![r][t] = 0]
    /\ rqSeq' = [rqSeq EXCEPT ![r][t] = 0]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, pc, tries, rd, iseq, nextSeq, persons>>

\* The call ends on its reply. Committed ends the round's repairs; a refusal, or no
\* answer while the commit may still be in flight, leaves the round free to call again
\* (Action wiring 27, 28, 29).
EndCommitted(r) ==
    /\ pc[r] = "issued"
    /\ rqSt[r][tries[r]] = "landed"
    /\ pc' = [pc EXCEPT ![r] = "done"]
    /\ rd' = [rd EXCEPT ![r] = 0]
    /\ iseq' = [iseq EXCEPT ![r] = 0]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, nextSeq, rqSt, rqPar, rqSeq, persons>>

EndOther(r) ==
    /\ pc[r] = "issued"
    /\ pc' = [pc EXCEPT ![r] = "idle"]
    /\ rd' = [rd EXCEPT ![r] = 0]
    /\ iseq' = [iseq EXCEPT ![r] = 0]
    /\ UNCHANGED <<head, nextId, files, par, rnd, cseq, tries, nextSeq, rqSt, rqPar, rqSeq, persons>>

\* A person commits to one site on the head, text 9.
Person(s) ==
    /\ persons < MaxPerson
    /\ nextId <= MaxC
    /\ files' = [files EXCEPT ![nextId] = [files[head] EXCEPT ![s] = 9]]
    /\ par' = [par EXCEPT ![nextId] = head]
    /\ head' = nextId
    /\ nextId' = nextId + 1
    /\ persons' = persons + 1
    /\ UNCHANGED <<rnd, cseq, pc, tries, rd, iseq, nextSeq, rqSt, rqPar, rqSeq>>

Next ==
    \/ \E r \in Rounds : StartRead(r)
    \/ \E r \in Rounds : Open(r)
    \/ \E r \in Rounds : StartOpen(r)
    \/ \E r \in Rounds : LateRead(r)
    \/ \E r \in Rounds : Issue(r)
    \/ \E r \in Rounds : Die(r)
    \/ \E r \in Rounds, t \in Tries : Land(r, t)
    \/ \E r \in Rounds, t \in Tries : Refuse(r, t)
    \/ \E r \in Rounds : EndCommitted(r)
    \/ \E r \in Rounds : EndOther(r)
    \/ \E s \in Sites : Person(s)

Spec == Init /\ [][Next]_vars

\* --- invariants, named as the page names them; each reads the commits alone ---

\* Invariant 2.1: every council commit changes a page whose bytes at the commit's
\* parent equal the round's snapshot (every site 0).
Inv2_1 ==
    \A c \in Council : \A s \in PageSites(rnd[c]) : files[par[c]][s] = 0

\* Invariant 2.2: every site a council commit changes belongs to the round's change
\* set and carries the change set's text.
Inv2_2 ==
    \A c \in Council : \A s \in Sites :
        files[c][s] # files[par[c]][s] => (s \in ChangeSites(rnd[c]) /\ files[c][s] = rnd[c])

\* Invariant 7.3: the intent a council commit's trailer names does not precede, in
\* the journal's order, the intent the trailer of any council-commit ancestor names.
Inv7_3 ==
    \A c \in Council : \A a \in Council : a \in Anc(c) => ~(cseq[c] < cseq[a])

\* Concurrency 1, with Capability requirement 13 and 20: every commit the repository
\* took is the head or an ancestor of it, so of two commits built on one head at most
\* one landed.
Conc1_OneWriter ==
    \A c \in Landed : c = head \/ c \in Anc(head)

\* --- reachability probes: deliberate falsehoods the checker must reject ---

\* Two council commits are never in flight at once. Rejected: with no commit fence a
\* call whose reply was lost leaves its commit in flight while a later call sends.
Pending(r, t) == rqSt[r][t] = "pending"
Probe_NeverTwoInFlight ==
    \A r \in Rounds : \A u \in Rounds : \A t \in Tries : \A w \in Tries :
        (Pending(r, t) /\ Pending(u, w)) => (r = u /\ t = w)

\* No commit is ever refused for a head that moved. Rejected: the head compare is
\* exercised.
Probe_NeverConflict ==
    \A r \in Rounds, t \in Tries : rqSt[r][t] # "refused"

\* Both rounds never land. Rejected: Invariant 7.3 compares two council commits.
Probe_NeverBoth ==
    ~(\E c, d \in Council : rnd[c] = 1 /\ rnd[d] = 2)

====

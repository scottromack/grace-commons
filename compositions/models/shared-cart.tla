---- MODULE shared-cart ----
\* Grace Commons — Shared Cart composition (compositions/shared-cart.md).
\* Grounded on Final Critique 2, 2026-11-05 at b430bcf — TLA+ layer authored 2026-11-12.
\* Derived validator; the English spec is the single source of truth. On any
\* disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
\*
\* PURPOSE
\* Check what happens across steps: one call of the composition after another,
\* by the opener and a friend, each a whole action that commits its writes
\* together or not at all (Execution Contract Database 1) and runs one at a
\* time (Database 2): a cart opened, shared verb by verb, unshared, its lines
\* added, changed, removed and cleared, viewed and read back, with every call
\* that is denied or refused along the way. What one call asks, calls, appends
\* and answers, and what one state must carry (every grant naming a cart, one
\* add event per line, every scope a cart scope: Invariant 2.1, 3.1, Scope
\* vocabulary 2 and the Action wiring beside them) is the Alloy model's,
\* shared-cart.als.
\*
\* RULES CHECKED (named by the page's own labels)
\*   Invariant 1.1     — a denied answer reaches no constituent write: a gated
\*                       call whose caller holds no active grant of the
\*                       action's verb scope changes no record
\*                       (Action wiring 1, 3 through it)          (Inv1_1_DeniedReachesNoWrite)
\*   Invariant 3.2     — a refused act appends no cart event
\*                       (Action wiring 23)                        (Inv3_2_RefusedActUnrecorded)
\*   Invariant 4.1     — [Unshare Cart] changes no line            (Inv4_1_UnshareKeepsLines)
\*   Action wiring 28  — [View Cart] and [Cart History] write
\*                       nothing                                    (AW28_ReadsWriteNothing)
\*
\* THE STEPS
\* A call that commits nothing (a refusal, a denial, a view, a history) leaves
\* every variable as it was: the composition keeps no record of its own
\* (Composition state 1), so such a call is no step (a stutter, which
\* [Next]_vars always allows). A step that changes
\* anything names its call in `last`; each check reads that call and the
\* records before and after it, so a call that wrote where the page forbids it
\* (on a denial, on a refusal, on an unshare's lines, on a read) is caught.
\*
\* THE RECORDS
\* Cart's carts and lines, Permissions' grants and the number of events in
\* Event Log. Which verb scope gates which action is the page's (Scope
\* vocabulary 3 to 7); whether the caller holds it is Permissions' permitted,
\* an active grant matching the actor reference and the cart scope exactly
\* (Permissions Operation 17, 18). A cart scope is the pair of a cart id and a
\* cart verb, compared whole (Term cart scope). Cart's own refusals
\* (already-in-cart, invalid-quantity, invalid-currency) and Permissions'
\* not-active are answered as the constituents' pages give them.
\*
\* BOUNDS (the .cfg)
\* Two actor references, two cart ids of which one is opened (the other is
\* `c404`, a cart id no grant names), one item, quantities 0 to 2 (0 refused),
\* room for seven grants (the opener's five and two shares), two lines and
\* five events: a friend given add who adds a line, then unshared; a friend
\* calling for a scope they do not hold; a line added, changed, removed and the
\* item added again on a new line; a second unshare of one grant. Larger bounds
\* (eight grants, three lines, six events) hold the same; see the coverage
\* matrix, tools/harness/coverage/shared-cart.md.
\*
\* NOT MODELED HERE
\* - Blank references, the string cap and storage-failure: a call refused for
\*   them changes nothing here as any refusal does; the Alloy model checks the
\*   blank checks (Action wiring 5, 10).
\* - What an event carries and what a view or a history answers (Action wiring
\*   22, 25 to 27, Term cart event): one call's content, the Alloy model's.

EXTENDS Integers, FiniteSets

CONSTANTS
    Actors,      \* the actor references (none blank)
    NCartIds,    \* how many cart ids the model names: 1..NCartIds
    MaxOpens,    \* how many carts the model opens; cart ids past it are never opened
    Items,       \* the item references
    Currencies,  \* the currencies a caller may send
    Accepted,    \* the currencies the deployment accepts
    MaxQty,      \* quantities run 0..MaxQty; 0 is no positive count
    MaxGrants,   \* how many grants Permissions' records hold room for
    MaxLines,    \* how many lines Cart's records hold room for (line ids 1..MaxLines)
    MaxEvents    \* how many events Event Log holds room for

\* CartIdSet: the cart ids a call may name.
CartIdSet == 1..NCartIds

\* GrantSlots, LineSlots: the grant ids and line ids, in the order the host
\* allocates them; a slot's record is "none" until its id is allocated.
GrantSlots == 1..MaxGrants
LineSlots == 1..MaxLines

\* Qtys: the quantities a call may carry.
Qtys == 0..MaxQty

\* Verbs: the cart verbs (Term cart verbs); OwnVerb, a verb outside them.
Verbs == {"view", "add", "change", "remove", "share"}
OwnVerb == "own"

\* VerbAt: the five cart verbs in the order [Open Cart] grants them.
VerbAt(i) == CASE i = 0 -> "view"
              [] i = 1 -> "add"
              [] i = 2 -> "change"
              [] i = 3 -> "remove"
              [] i = 4 -> "share"

\* GatedOps: every action but [Open Cart] (Term gated action).
GatedOps == {"share", "unshare", "add", "change", "remove", "clear", "view", "history"}

\* Gate: the cart verb whose scope gates an action (Scope vocabulary 3 to 7).
Gate(op) == CASE op \in {"view", "history"} -> "view"
              [] op = "add" -> "add"
              [] op = "change" -> "change"
              [] op \in {"remove", "clear"} -> "remove"
              [] op \in {"share", "unshare"} -> "share"

\* Refusals: every refusal code a call of the model can answer.
Refusals == {"permission-denied", "invalid-request", "not-known", "not-active",
             "invalid-currency", "invalid-quantity", "already-in-cart"}

\* NoGrant, NoLine: the record of an id not yet allocated.
NoGrant == [subj |-> "none", cart |-> 0, verb |-> "none", st |-> "none"]
NoLine == [cart |-> 0, item |-> "none", qty |-> 0, by |-> "none", st |-> "none"]

\* ---------------------------------------------------------------------------
\* State
\* ---------------------------------------------------------------------------

VARIABLES
    carts,    \* the cart ids Cart's records carry
    grants,   \* grant id -> its grant: subject, the cart and verb of its scope, status
    ng,       \* the next grant id the host allocates
    lines,    \* line id -> its line: cart, item, quantity, who added it, status ("live", "gone")
    nl,       \* the next line id the host allocates
    nlog,     \* how many events Event Log holds
    last      \* the last call that changed anything: its action, actor reference, cart id and answer

\* vars: every variable; a step that changes none of them is a stutter.
vars == <<carts, grants, ng, lines, nl, nlog, last>>

\* records: the constituents' records, everything a call can write.
records == <<carts, grants, ng, lines, nl, nlog>>

\* TypeOK: each variable holds a value of its kind (the model's typing, not a
\* rule of the page).
TypeOK ==
    /\ carts \subseteq CartIdSet
    /\ grants \in [GrantSlots -> [subj : Actors \cup {"none"}, cart : 0..NCartIds,
                                  verb : Verbs \cup {OwnVerb, "none"},
                                  st : {"none", "active", "revoked"}]]
    /\ ng \in 1..(MaxGrants + 1)
    /\ lines \in [LineSlots -> [cart : 0..NCartIds, item : Items \cup {"none"}, qty : Qtys,
                                by : Actors \cup {"none"}, st : {"none", "live", "gone"}]]
    /\ nl \in 1..(MaxLines + 1)
    /\ nlog \in 0..MaxEvents

\* Permitted: Permissions' permitted: an active grant matches the subject
\* reference and the cart scope exactly (Permissions Operation 17, 18, 21, 22).
Permitted(a, c, v) ==
    \E g \in GrantSlots : /\ grants[g].st = "active"
                          /\ grants[g].subj = a
                          /\ grants[g].cart = c
                          /\ grants[g].verb = v

\* Answer: the record of a call: its action, actor, cart id and answer.
Answer(op, a, c, ans) == [op |-> op, actor |-> a, cart |-> c, ans |-> ans]

\* Init: no cart, no grant, no line, no event, no call yet.
Init ==
    /\ carts = {}
    /\ grants = [g \in GrantSlots |-> NoGrant]
    /\ ng = 1
    /\ lines = [l \in LineSlots |-> NoLine]
    /\ nl = 1
    /\ nlog = 0
    /\ last = Answer("none", "none", 0, "none")

\* ---------------------------------------------------------------------------
\* The composition's actions, one call each
\* ---------------------------------------------------------------------------

\* Refuse: the call answers the refusal code and commits nothing (Execution
\* Contract Database 1); the composition keeps no record of a call (Composition
\* state 1), so the call changes no variable and is no step of its own: the
\* behaviour stays where it was, a stutter [Next]_vars always allows. A call
\* that wrote on a refusal would be a step, the one naming a refusal in `last`.
Refuse(op, a, c, code) ==
    FALSE

\* OpenCart: Cart's open with the currency (invalid-currency answered
\* unchanged); on its cart id, a grant to the opener of each of the five verb
\* scopes and the open event (Action wiring 6 to 8, 22). The one action no
\* permission gates.
OpenCart(a, cur) ==
    /\ Cardinality(carts) < MaxOpens
    /\ IF cur \notin Accepted
          THEN Refuse("open", a, 0, "invalid-currency")
          ELSE LET c == Cardinality(carts) + 1 IN
               /\ ng + 4 <= MaxGrants
               /\ nlog < MaxEvents
               /\ carts' = carts \cup {c}
               /\ grants' = [g \in GrantSlots |->
                               IF g >= ng /\ g < ng + 5
                                  THEN [subj |-> a, cart |-> c, verb |-> VerbAt(g - ng),
                                        st |-> "active"]
                                  ELSE grants[g]]
               /\ ng' = ng + 5
               /\ nlog' = nlog + 1
               /\ last' = Answer("open", a, c, "ok")
               /\ UNCHANGED <<lines, nl>>

\* ShareCart: gated on the share scope; a verb outside the cart verbs answers
\* invalid-request (Action wiring 9); otherwise a grant to the friend of the
\* cart's verb scope and the share event (Action wiring 11, 12, 22).
ShareCart(a, c, f, v) ==
    IF ~Permitted(a, c, "share")
       THEN Refuse("share", a, c, "permission-denied")
       ELSE IF v \notin Verbs
               THEN Refuse("share", a, c, "invalid-request")
               ELSE /\ ng <= MaxGrants
                    /\ nlog < MaxEvents
                    /\ grants' = [grants EXCEPT ![ng] = [subj |-> f, cart |-> c, verb |-> v,
                                                         st |-> "active"]]
                    /\ ng' = ng + 1
                    /\ nlog' = nlog + 1
                    /\ last' = Answer("share", a, c, "ok")
                    /\ UNCHANGED <<carts, lines, nl>>

\* UnshareCart: gated on the share scope; a grant id naming no grant of the
\* cart answers not-known (Action wiring 13); a revoked one, Permissions'
\* not-active; otherwise revoke and the unshare event (Action wiring 14, 22).
UnshareCart(a, c, g) ==
    IF ~Permitted(a, c, "share")
       THEN Refuse("unshare", a, c, "permission-denied")
       ELSE IF grants[g].st = "none" \/ grants[g].cart # c
               THEN Refuse("unshare", a, c, "not-known")
               ELSE IF grants[g].st = "revoked"
                       THEN Refuse("unshare", a, c, "not-active")
                       ELSE /\ nlog < MaxEvents
                            /\ grants' = [grants EXCEPT ![g].st = "revoked"]
                            /\ nlog' = nlog + 1
                            /\ last' = Answer("unshare", a, c, "ok")
                            /\ UNCHANGED <<carts, ng, lines, nl>>

\* AddLine: gated on the add scope; Cart's add refuses an item the cart
\* already carries and a quantity that is no positive count (answered
\* unchanged); otherwise a new line and the add event (Action wiring 15, 16, 22).
AddLine(a, c, i, q) ==
    IF ~Permitted(a, c, "add")
       THEN Refuse("add", a, c, "permission-denied")
       ELSE IF \E l \in LineSlots : lines[l].st = "live" /\ lines[l].cart = c /\ lines[l].item = i
               THEN Refuse("add", a, c, "already-in-cart")
               ELSE IF q = 0
                       THEN Refuse("add", a, c, "invalid-quantity")
                       ELSE /\ nl <= MaxLines
                            /\ nlog < MaxEvents
                            /\ lines' = [lines EXCEPT ![nl] = [cart |-> c, item |-> i, qty |-> q,
                                                               by |-> a, st |-> "live"]]
                            /\ nl' = nl + 1
                            /\ nlog' = nlog + 1
                            /\ last' = Answer("add", a, c, "ok")
                            /\ UNCHANGED <<carts, grants, ng>>

\* ChangeQuantity: gated on the change scope; a line the cart does not carry
\* answers not-known (Action wiring 17); a quantity that is no positive count,
\* Cart's invalid-quantity; otherwise the new quantity and the change event,
\* even for the quantity the line holds (Action wiring 18, Wiring decision 2).
ChangeQuantity(a, c, l, q) ==
    IF ~Permitted(a, c, "change")
       THEN Refuse("change", a, c, "permission-denied")
       ELSE IF lines[l].st # "live" \/ lines[l].cart # c
               THEN Refuse("change", a, c, "not-known")
               ELSE IF q = 0
                       THEN Refuse("change", a, c, "invalid-quantity")
                       ELSE /\ nlog < MaxEvents
                            /\ lines' = [lines EXCEPT ![l].qty = q]
                            /\ nlog' = nlog + 1
                            /\ last' = Answer("change", a, c, "ok")
                            /\ UNCHANGED <<carts, grants, ng, nl>>

\* RemoveLine: gated on the remove scope; a line the cart does not carry
\* answers not-known (Action wiring 19); otherwise the line is taken out and
\* the remove event appended (Action wiring 20, 22).
RemoveLine(a, c, l) ==
    IF ~Permitted(a, c, "remove")
       THEN Refuse("remove", a, c, "permission-denied")
       ELSE IF lines[l].st # "live" \/ lines[l].cart # c
               THEN Refuse("remove", a, c, "not-known")
               ELSE /\ nlog < MaxEvents
                    /\ lines' = [lines EXCEPT ![l].st = "gone"]
                    /\ nlog' = nlog + 1
                    /\ last' = Answer("remove", a, c, "ok")
                    /\ UNCHANGED <<carts, grants, ng, nl>>

\* ClearCart: gated on the remove scope; every line of the cart taken out and
\* the clear event appended (Action wiring 21, 22).
ClearCart(a, c) ==
    IF ~Permitted(a, c, "remove")
       THEN Refuse("clear", a, c, "permission-denied")
       ELSE /\ nlog < MaxEvents
            /\ lines' = [l \in LineSlots |->
                           IF lines[l].st = "live" /\ lines[l].cart = c
                              THEN [lines[l] EXCEPT !.st = "gone"]
                              ELSE lines[l]]
            /\ nlog' = nlog + 1
            /\ last' = Answer("clear", a, c, "ok")
            /\ UNCHANGED <<carts, grants, ng, nl>>

\* ViewCart: gated on the view scope; reads Cart and Event Log and answers the
\* shared cart (Action wiring 25, 27), committing nothing, so it is no step.
ViewCart(a, c) ==
    IF ~Permitted(a, c, "view")
       THEN Refuse("view", a, c, "permission-denied")
       ELSE FALSE   \* answers the shared cart, commits nothing: no step

\* CartHistory: gated on the view scope; reads Event Log and answers the cart
\* events (Action wiring 26, 27), committing nothing.
CartHistory(a, c) ==
    IF ~Permitted(a, c, "view")
       THEN Refuse("history", a, c, "permission-denied")
       ELSE FALSE   \* answers the cart events, commits nothing: no step

\* Next: any one call, by any actor, naming any cart id, grant id, line id,
\* item, quantity, currency or verb.
Next ==
    \/ \E a \in Actors, cur \in Currencies : OpenCart(a, cur)
    \/ \E a \in Actors, c \in CartIdSet, f \in Actors, v \in Verbs \cup {OwnVerb} :
          ShareCart(a, c, f, v)
    \/ \E a \in Actors, c \in CartIdSet, g \in GrantSlots : UnshareCart(a, c, g)
    \/ \E a \in Actors, c \in CartIdSet, i \in Items, q \in Qtys : AddLine(a, c, i, q)
    \/ \E a \in Actors, c \in CartIdSet, l \in LineSlots, q \in Qtys : ChangeQuantity(a, c, l, q)
    \/ \E a \in Actors, c \in CartIdSet, l \in LineSlots : RemoveLine(a, c, l)
    \/ \E a \in Actors, c \in CartIdSet : ClearCart(a, c)
    \/ \E a \in Actors, c \in CartIdSet : ViewCart(a, c)
    \/ \E a \in Actors, c \in CartIdSet : CartHistory(a, c)

\* Spec: every behaviour from Init by Next steps.
Spec == Init /\ [][Next]_vars

\* ---------------------------------------------------------------------------
\* Checks (the verification surface)
\* ---------------------------------------------------------------------------

\* Inv1_1_DeniedReachesNoWrite: a gated call whose caller held, before it, no
\* active grant of the cart's verb scope for the action (the page's gate,
\* Scope vocabulary 3 to 7) changes no record of any constituent: a denied
\* answer reaches no write (Invariant 1.1, Action wiring 1, 3).
Inv1_1_DeniedReachesNoWrite ==
    [][(last'.op \in GatedOps /\ ~Permitted(last'.actor, last'.cart, Gate(last'.op)))
          => records' = records]_vars

\* Inv3_2_RefusedActUnrecorded: a call the composition answers with a refusal
\* appends no cart event (Invariant 3.2, Action wiring 23).
Inv3_2_RefusedActUnrecorded ==
    [][last'.ans \in Refusals => nlog' = nlog]_vars

\* Inv4_1_UnshareKeepsLines: an [Unshare Cart] changes no line: the lines the
\* friend added stay, with who added them (Invariant 4.1).
Inv4_1_UnshareKeepsLines ==
    [][last'.op = "unshare" => (lines' = lines /\ nl' = nl)]_vars

\* AW28_ReadsWriteNothing: a [View Cart] or a [Cart History] changes no record
\* and appends no event (Action wiring 28).
AW28_ReadsWriteNothing ==
    [][last'.op \in {"view", "history"} => records' = records]_vars

====

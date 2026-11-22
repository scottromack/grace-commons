---- MODULE privileged-access-provisioning-buggy-sweep-unattested ----
\* BUGGY TWIN: the recovery record is attested under the owed record's own actor (the requestor, for a request event) in place of the service identity (Reconciliation 11 dropped); breaks SweepAttestedByService.
(*
  TLA+ model for compositions/privileged-access-provisioning.md
  Grounded on Final Critique 4.

  PURPOSE
  Verify the composition's three temporal commitments under concurrent action
  interleavings that the English spec defends but the three-pass review cannot
  exhaustively enumerate:

    1. ApprovalGatesProvisioning  — a capability_token enters request_to_capability
                                    only when the chain for that request is Approved.
    2. CascadeFiresAtMostOnce     — the provisioning cascade fires at most once per
                                    request, even when a decision lands on a chain
                                    already Approved (the substrate answers
                                    not-pending and the chain evaluation runs again,
                                    Action wiring 38). The model counts the cascade's
                                    firings per request in cascade_fired.
    3. TerminalAbsorbingProp      — no request in a terminal request state (Denied,
                                    Withdrawn, Revoked, ProvisioningFailed) ever
                                    changes state, and a Provisioned request moves
                                    only to Revoked (Composition state 6 and 7,
                                    Invariant 8.2). An action property, checked as
                                    a PROPERTY.
    4. MapInverseConsistency      — request_to_capability and capability_to_request
                                    are always strict inverses of each other.
    5. DeniedNamesRejectedChain   — every Denied request names a chain whose state
                                    is Rejected (Invariant 7.2).

  THE SWEEP (extended 2026-11-22, open line 2026-08-29-a: "the model's sweep carries
  no pre-check, no identity, no recovery record, and no age bound")
  The model keeps the minimum of the trail the reconciliation's sweep rules read:
  per request, the set of recorded events (each an original, a recovery intent or a
  recovery record, with its action reference, its invocation id, its attesting actor,
  and two stamps of the moment it landed: whether the owed record was aged then, and
  whether the recovery intent was already on the trail), and the open pending
  entries that owe a record. Two owed records are modeled: the request event
  (attested by the requestor; its outcome is chosen in Init) and the exercise event
  (attested by the service identity, Action wiring 89). Each original write lands,
  is refused (a pending entry opens, Action wiring 7), or lands with its answer lost
  (the event is on the trail and the entry opens too), the case the pre-check is for.
  The reconciliation retries every open entry (Reconciliation 2) in three steps: the
  pre-check finds the event and closes the entry, writing nothing (Reconciliation 4
  to 6); or, the owed record not aged (Reconciliation 10), it lands a recovery intent
  under the service identity (Reconciliation 11 through 14) and then the recovery record
  carrying the owed record's action reference and invocation id (Reconciliation 15),
  and a later run's pre-check closes the entry. A crash between any two steps is an
  interleaving. An entry ages (its owed record's instant plus the audit horizon
  precedes now) at any step, never back.

    6. SweepPreCheckNoDuplicate   — no two events of one request carry the same
                                    action reference and invocation id, reading a
                                    recovery record as the event it names, and no
                                    write landed an event already carried
                                    (Reconciliation 4, 5, 6).
    7. SweepAttestedByService     — every reconciliation write is attested under the
                                    service identity (Reconciliation 11).
    8. SweepNoAgedWrite           — no reconciliation write lands for an aged event
                                    (Reconciliation 10).
    9. RecoveryRecordNamesOwed    — a recovery record carries the action reference
                                    and invocation id of a record the request owed
                                    (Reconciliation 15).
   10. RecoveryRecordFollowsIntent — a recovery record lands only after the leg's
                                    recovery intent for the same owed record
                                    (Reconciliation 12 through 14).

  SCOPE
  Bounded: up to N_REQ requests, N_APP approvers, one Capability token per request.
  Credential and Session checks are abstracted as always-passing (they gate entry
  to actions; their correctness is an atom-level Alloy concern, not a composition-
  level interleaving concern). Audit Trail writes other than the two owed records
  above (decision, denial, withdrawal, provisioning and failed exercise events) are
  abstracted away (append-only; their correctness is the Audit Trail composition's
  concern).

  TOOL
  TLA+ model checker (TLC). Run with TLC; all invariants should hold and no
  deadlock should be reachable from Init. A violated invariant is a spec finding
  for compositions/privileged-access-provisioning.md.

  NOT MODELED
  - Credential.verify / Session.validate / Permissions.permitted (abstracted as
    always-pass; their guards are atom-level concerns)
  - Audit Trail event writes other than the request event, the exercise event and
    the sweep's writes for them (abstracted away; append-only, no state feedback)
  - The evaluation entry and the approval leg (its retry is the chain evaluation,
    which DecisionNotPending already runs again), so Reconciliation 12's constituent
    state clause is not modeled; Reconciliation 16 (a recovery record's data never
    from a composition index): the model carries no event data
  - Clock / TTL / expiry (time is not a first-class value in this model; the age
    of an owed record is one flag per pending entry)
  - Capability.redeem counter (modeled as a binary redeemable/exhausted flag
    sufficient for the composition-level temporal properties)
*)

EXTENDS Naturals, FiniteSets, TLC

----

CONSTANTS
  RequestIDs,     \* finite set of request identifiers  e.g. {"r1","r2"}
  ApproverIDs,    \* finite set of approver identifiers e.g. {"a1","a2"}
  CapTokens,      \* finite set of capability tokens    e.g. {"cap1","cap2"}
  QuorumSize      \* number of approvals required (e.g. 2 for all-of-2)

ASSUME QuorumSize \in Nat /\ QuorumSize >= 1
ASSUME Cardinality(ApproverIDs) >= QuorumSize
ASSUME Cardinality(RequestIDs) >= 1
ASSUME Cardinality(CapTokens) >= Cardinality(RequestIDs)

----

(* Request states *)
RequestStates == {"Pending", "Approved", "Provisioned",
                  "Denied", "Withdrawn", "Revoked", "ProvisioningFailed"}

TerminalStates == {"Provisioned", "Denied", "Withdrawn", "Revoked", "ProvisioningFailed"}

(* Chain states (simplified Multi-Party Approval model) *)
ChainStates == {"Pending", "Approved", "Rejected", "Withdrawn"}

(* ─── The trail, as the sweep reads it ──────────────────────────────────── *)

(* The action references of the two owed records the model carries. *)
ActRefs == {"access_requested", "access_exercised"}

(*
  Invocation ids: the request's [Request Access] and [Exercise Access] invocations
  (Term invocation id; one of each per request, and trails are per request), and
  "i_sweep", a reconciliation run's own id, which no correct write carries.
*)
InvIds == {"i_req", "i_ex", "i_sweep"}

(* The attesting actors: the requestor and the service identity (Term service identity). *)
Actors == {"requestor", "svc"}

(*
  An event on the trail. kind: an original write, a recovery intent (Term recovery
  intent) or a recovery record (Term recovery record; act and inv are the owed
  record's, Reconciliation 15, so it is read as the event it names). aged and
  after_intent are stamps of the moment the event landed: the owed record was aged
  then; the leg's recovery intent for the same owed record was already on the
  trail then. An original carries FALSE in both.
*)
Events == [kind : {"orig", "intent", "rec"}, act : ActRefs, inv : InvIds,
           actor : Actors, aged : BOOLEAN, after_intent : BOOLEAN]

(*
  A pending entry: the action reference and the invocation id of the record it owes
  (Composition state 31), who attests the owed record (part of its data), and
  whether the owed record is aged (Term aged event).
*)
Entries == [act : ActRefs, inv : InvIds, who : Actors, aged : BOOLEAN]

(* The key the pre-check reads the trail for: an action reference and an invocation id. *)
Keys == [act : ActRefs, inv : InvIds]

KeyOf(x) == [act |-> x.act, inv |-> x.inv]

(* Original-write outcomes: the event lands; Audit Trail refuses it; it lands and the answer is lost. *)
Outcomes == {"landed", "refused", "lost"}

(* An original write of the record act / inv attested by who. *)
Orig(act, inv, who) ==
  [kind |-> "orig", act |-> act, inv |-> inv, actor |-> who,
   aged |-> FALSE, after_intent |-> FALSE]

(* The pending entry owing that record, fresh (not aged). *)
NewEntry(act, inv, who) == [act |-> act, inv |-> inv, who |-> who, aged |-> FALSE]

----

VARIABLES
  \* --- Composition-level state ---
  request_state,        \* request_id -> RequestState
  request_to_cap,       \* request_id -> CapToken (partial function; defined only when Provisioned)
  cap_to_request,       \* CapToken -> request_id (strict inverse of request_to_cap)

  \* --- Multi-Party Approval (simplified) ---
  chain_state,          \* request_id -> ChainState
  approvals,            \* request_id -> SUBSET ApproverIDs (approvers who have decided)
  rejections,           \* request_id -> SUBSET ApproverIDs

  \* --- Capability atom (simplified) ---
  cap_allocated,        \* SUBSET CapTokens: tokens that have been allocated
  cap_exhausted,        \* SUBSET CapTokens: tokens that have been fully redeemed

  \* --- Token supply ---
  next_token,           \* function: request_id -> CapToken (pre-assigned for determinism)

  \* --- History ---
  cascade_fired,        \* request_id -> 0..2: the cascade's firings for the request (2 = twice or more)

  \* --- The trail and the pending entries (the sweep) ---
  trail,                \* request_id -> SUBSET Events: the request's recorded events
  pending,              \* request_id -> SUBSET Entries: the request's open pending entries
  owed,                 \* request_id -> SUBSET Keys: history, every record an entry ever owed
  rewritten             \* request_id -> BOOLEAN: history, a write landed an event the trail already carried

sweep_vars == <<trail, pending, owed, rewritten>>

vars == <<request_state, request_to_cap, cap_to_request,
          chain_state, approvals, rejections,
          cap_allocated, cap_exhausted, next_token, cascade_fired,
          trail, pending, owed, rewritten>>

----

(* ─── Type invariant ─────────────────────────────────────────────────────── *)

TypeOK ==
  /\ request_state  \in [RequestIDs -> RequestStates]
  /\ request_to_cap \in [RequestIDs -> CapTokens \cup {"none"}]
  /\ cap_to_request \in [CapTokens  -> RequestIDs \cup {"none"}]
  /\ chain_state    \in [RequestIDs -> ChainStates]
  /\ approvals      \in [RequestIDs -> SUBSET ApproverIDs]
  /\ rejections     \in [RequestIDs -> SUBSET ApproverIDs]
  /\ cap_allocated  \subseteq CapTokens
  /\ cap_exhausted  \subseteq CapTokens
  /\ cascade_fired  \in [RequestIDs -> 0..2]
  /\ DOMAIN trail = RequestIDs   /\ \A r \in RequestIDs : trail[r]   \subseteq Events
  /\ DOMAIN pending = RequestIDs /\ \A r \in RequestIDs : pending[r] \subseteq Entries
  /\ DOMAIN owed = RequestIDs    /\ \A r \in RequestIDs : owed[r]    \subseteq Keys
  /\ rewritten      \in [RequestIDs -> BOOLEAN]

----

(* ─── Initial state ──────────────────────────────────────────────────────── *)

Init ==
  /\ request_state  = [r \in RequestIDs |-> "Pending"]
  /\ request_to_cap = [r \in RequestIDs |-> "none"]
  /\ cap_to_request = [t \in CapTokens  |-> "none"]
  /\ chain_state    = [r \in RequestIDs |-> "Pending"]
  /\ approvals      = [r \in RequestIDs |-> {}]
  /\ rejections     = [r \in RequestIDs |-> {}]
  /\ cap_allocated  = {}
  /\ cap_exhausted  = {}
  /\ cascade_fired  = [r \in RequestIDs |-> 0]
  \* Pre-assign one distinct token per request (tokens are a finite pool)
  /\ next_token     \in [RequestIDs -> CapTokens]
      \* Injectivity: each request gets a distinct token
      /\ \A r1, r2 \in RequestIDs : r1 # r2 => next_token[r1] # next_token[r2]
  \* [Request Access] has run for every request: its request event, attested by the
  \* requestor, landed, was refused (an initiation entry opens), or landed with its
  \* answer lost (the event is on the trail and the entry opens too).
  /\ \E out \in [RequestIDs -> Outcomes] :
       /\ trail   = [r \in RequestIDs |->
                       IF out[r] \in {"landed", "lost"}
                       THEN {Orig("access_requested", "i_req", "requestor")} ELSE {}]
       /\ pending = [r \in RequestIDs |->
                       IF out[r] \in {"refused", "lost"}
                       THEN {NewEntry("access_requested", "i_req", "requestor")} ELSE {}]
       /\ owed    = [r \in RequestIDs |->
                       IF out[r] \in {"refused", "lost"}
                       THEN {[act |-> "access_requested", inv |-> "i_req"]} ELSE {}]
  /\ rewritten      = [r \in RequestIDs |-> FALSE]

----

(* ─── Helpers ────────────────────────────────────────────────────────────── *)

(* The trail carries the record keyed k: an original, or a recovery record read as the event it names. *)
Carries(r, k) ==
  \E x \in trail[r] : x.kind \in {"orig", "rec"} /\ KeyOf(x) = k

(* The leg's recovery intent for the owed record keyed k is on the trail. *)
HasIntent(r, k) ==
  \E x \in trail[r] : x.kind = "intent" /\ KeyOf(x) = k

(*
  Land event e on request r's trail; rewritten keeps the history of a write that
  landed a record the trail already carried (a set would read the second as one).
*)
Land(r, e) ==
  /\ trail'     = [trail EXCEPT ![r] = @ \cup {e}]
  /\ rewritten' = IF e.kind # "intent" /\ Carries(r, KeyOf(e))
                  THEN [rewritten EXCEPT ![r] = TRUE] ELSE rewritten

(*
  An original write of the record act / inv attested by who, with outcome out
  (Action wiring 7: a refused record following a committed act opens a pending
  entry carrying it).
*)
RecordOriginal(r, act, inv, who, out) ==
  /\ IF out \in {"landed", "lost"}
     THEN Land(r, Orig(act, inv, who))
     ELSE UNCHANGED <<trail, rewritten>>
  /\ pending' = IF out \in {"refused", "lost"}
                THEN [pending EXCEPT ![r] = @ \cup {NewEntry(act, inv, who)}]
                ELSE pending
  /\ owed'    = IF out \in {"refused", "lost"}
                THEN [owed EXCEPT ![r] = @ \cup {[act |-> act, inv |-> inv]}]
                ELSE owed

QuorumReached(r) ==
  Cardinality(approvals[r]) >= QuorumSize

QuorumBlocked(r) ==
  Cardinality(rejections[r]) > 0  \* any rejection blocks all-of-N quorum

----

(* ─── Actions ────────────────────────────────────────────────────────────── *)

(*
  Provisioning conjunction (Term provisioning conjunction): the request state is
  open (Pending or Approved) and no token parses to the request. The pending-entry
  clause is not modeled (no audit writes).
*)
ProvisioningConjunction(r) ==
  /\ request_state[r] \in {"Pending", "Approved"}
  /\ request_to_cap[r] = "none"

(*
  The provisioning cascade (Provisioning cascade 2 through 15): allocate answers a
  token, and the maps and the request state are written in one transaction.
*)
Cascade(r) ==
  LET tok == next_token[r]
  IN
    /\ request_state'  = [request_state EXCEPT ![r] = "Provisioned"]
    /\ request_to_cap' = [request_to_cap EXCEPT ![r] = tok]
    /\ cap_to_request' = [cap_to_request EXCEPT ![tok] = r]
    /\ cap_allocated'  = cap_allocated \cup {tok}
    /\ cascade_fired'  = [cascade_fired EXCEPT ![r] = IF @ = 0 THEN 1 ELSE 2]

(*
  The cascade's failure arm (Provisioning cascade 3 through 5): allocate answers
  invalid-request; the request moves to ProvisioningFailed and nothing is allocated.
*)
CascadeFails(r) ==
  /\ request_state'  = [request_state EXCEPT ![r] = "ProvisioningFailed"]
  /\ request_to_cap' = request_to_cap
  /\ cap_to_request' = cap_to_request
  /\ cap_allocated'  = cap_allocated
  /\ cascade_fired'  = [cascade_fired EXCEPT ![r] = IF @ = 0 THEN 1 ELSE 2]

(*
  The chain evaluation (Action wiring 47, 48, 57, 58): on a chain whose state is
  cs, fire the cascade only if cs is Approved and the provisioning conjunction
  holds; otherwise write nothing.
*)
ChainEvaluation(r, cs) ==
  IF cs = "Approved" /\ ProvisioningConjunction(r)
  THEN Cascade(r) \/ CascadeFails(r)
  ELSE /\ request_state'  = request_state
       /\ request_to_cap' = request_to_cap
       /\ cap_to_request' = cap_to_request
       /\ cap_allocated'  = cap_allocated
       /\ cascade_fired'  = cascade_fired

(*
  approve_step: an approver records a decision on a chain still in Pending state.
  If quorum is now reached, chain transitions to Approved. The chain evaluation
  then reads the chain's new state and fires the cascade if it is Approved.
*)
ApproveStep(r, a) ==
  \* Preconditions
  /\ request_state[r] \in {"Pending", "Approved"}  \* request still live
  /\ chain_state[r] = "Pending"                    \* chain not yet terminal
  /\ a \notin approvals[r]                         \* not yet decided
  /\ a \notin rejections[r]
  \* Record the approval
  /\ approvals' = [approvals EXCEPT ![r] = approvals[r] \cup {a}]
  /\ rejections' = rejections
  \* The substrate evaluates quorum
  /\ LET cs == IF Cardinality(approvals[r] \cup {a}) >= QuorumSize
               THEN "Approved" ELSE "Pending"
     IN
       /\ chain_state' = [chain_state EXCEPT ![r] = cs]
       /\ ChainEvaluation(r, cs)
  /\ cap_exhausted' = cap_exhausted
  /\ next_token'    = next_token
  /\ UNCHANGED sweep_vars

(*
  A decision that lands on a chain already Approved (two approve_step calls race;
  the second reads the chain after the first moved it): the substrate answers
  not-pending and records nothing, and the decision action runs the chain
  evaluation again (Action wiring 38). The provisioning conjunction keeps the
  cascade from firing a second time.
*)
DecisionNotPending(r, a) ==
  /\ chain_state[r] = "Approved"
  /\ a \in ApproverIDs
  /\ ChainEvaluation(r, chain_state[r])
  /\ chain_state'   = chain_state
  /\ approvals'     = approvals
  /\ rejections'    = rejections
  /\ cap_exhausted' = cap_exhausted
  /\ next_token'    = next_token
  /\ UNCHANGED sweep_vars

(*
  reject_step: an approver rejects. Any rejection blocks all-of-N quorum.
  Chain transitions to Rejected; request transitions to Denied.
*)
RejectStep(r, a) ==
  /\ request_state[r] = "Pending"
  /\ chain_state[r]   = "Pending"
  /\ a \notin approvals[r]
  /\ a \notin rejections[r]
  /\ rejections'     = [rejections EXCEPT ![r] = rejections[r] \cup {a}]
  /\ approvals'      = approvals
  /\ chain_state'    = [chain_state EXCEPT ![r] = "Rejected"]
  /\ request_state'  = [request_state EXCEPT ![r] = "Denied"]
  /\ request_to_cap' = request_to_cap
  /\ cap_to_request' = cap_to_request
  /\ cap_allocated'  = cap_allocated
  /\ cap_exhausted'  = cap_exhausted
  /\ next_token'     = next_token
  /\ cascade_fired'  = cascade_fired
  /\ UNCHANGED sweep_vars

(*
  withdraw_request: requestor withdraws before approval completes.
  Only valid when request is Pending and chain is Pending.
*)
WithdrawRequest(r) ==
  /\ request_state[r] = "Pending"
  /\ chain_state[r]   = "Pending"
  /\ chain_state'    = [chain_state EXCEPT ![r] = "Withdrawn"]
  /\ request_state'  = [request_state EXCEPT ![r] = "Withdrawn"]
  /\ approvals'      = approvals
  /\ rejections'     = rejections
  /\ request_to_cap' = request_to_cap
  /\ cap_to_request' = cap_to_request
  /\ cap_allocated'  = cap_allocated
  /\ cap_exhausted'  = cap_exhausted
  /\ next_token'     = next_token
  /\ cascade_fired'  = cascade_fired
  /\ UNCHANGED sweep_vars

(*
  exercise_access: bearer presents a valid capability token.
  Session validation is abstracted as always-passing.
  Redeem decrements the counter; here modeled as token -> exhausted.
*)
ExerciseAccess(r) ==
  /\ request_state[r] = "Provisioned"
  /\ request_to_cap[r] # "none"
  /\ LET tok == request_to_cap[r]
     IN
       /\ tok \in cap_allocated
       /\ tok \notin cap_exhausted         \* token not yet exhausted
       /\ cap_exhausted' = cap_exhausted \cup {tok}
  /\ request_state'  = request_state
  /\ request_to_cap' = request_to_cap
  /\ cap_to_request' = cap_to_request
  /\ cap_allocated'  = cap_allocated
  /\ chain_state'    = chain_state
  /\ approvals'      = approvals
  /\ rejections'     = rejections
  /\ next_token'     = next_token
  /\ cascade_fired'  = cascade_fired
  \* The exercise event, under the service identity (Action wiring 89), lands, is
  \* refused (its exercise entry stays open), or lands with its answer lost.
  /\ \E out \in Outcomes :
       RecordOriginal(r, "access_exercised", "i_ex", "svc", out)

(*
  revoke_access: administrator revokes a provisioned request.
  Capability may already be exhausted (already-terminal path — non-fatal).
*)
RevokeAccess(r) ==
  /\ request_state[r] = "Provisioned"
  /\ request_state'  = [request_state EXCEPT ![r] = "Revoked"]
  /\ request_to_cap' = request_to_cap   \* map entries are immutable
  /\ cap_to_request' = cap_to_request
  /\ cap_allocated'  = cap_allocated
  /\ cap_exhausted'  = cap_exhausted
  /\ chain_state'    = chain_state
  /\ approvals'      = approvals
  /\ rejections'     = rejections
  /\ next_token'     = next_token
  /\ cascade_fired'  = cascade_fired
  /\ UNCHANGED sweep_vars

(* ─── The reconciliation's sweep ──────────────────────────────────────────── *)

(* The composition's own variables, which no sweep step writes. *)
comp_vars == <<request_state, request_to_cap, cap_to_request,
               chain_state, approvals, rejections,
               cap_allocated, cap_exhausted, next_token, cascade_fired>>

(*
  The pre-check finds the event (Reconciliation 4, 5, 6): the trail carries an
  event with the owed record's action reference and invocation id, so the run
  closes the entry and emits nothing. Closing writes no event, so it runs for an
  aged entry too.
*)
SweepFound(r, e) ==
  /\ e \in pending[r]
  /\ Carries(r, KeyOf(e))
  /\ pending' = [pending EXCEPT ![r] = @ \ {e}]
  /\ UNCHANGED <<trail, owed, rewritten>>
  /\ UNCHANGED comp_vars

(*
  The leg's recovery intent (Reconciliation 12 through 14): the pre-check found no event
  and the owed record is not aged (Reconciliation 10), so the leg lands its intent,
  carrying the owed record's invocation id, under the service identity
  (Reconciliation 11), before the recovery record.
*)
SweepIntent(r, e) ==
  /\ e \in pending[r]
  /\ ~e.aged
  /\ ~Carries(r, KeyOf(e))
  /\ ~HasIntent(r, KeyOf(e))
  /\ Land(r, [kind |-> "intent", act |-> e.act, inv |-> e.inv, actor |-> "svc",
              aged |-> e.aged, after_intent |-> FALSE])
  /\ UNCHANGED <<pending, owed>>
  /\ UNCHANGED comp_vars

(*
  The recovery record (Reconciliation 15): the pre-check found no event, the owed
  record is not aged, and the leg's intent has landed; the record carries the owed
  record's action reference and invocation id, attested under the service identity.
  The entry stays open until a later run's pre-check finds the record (SweepFound),
  so a crash here leaves the case the pre-check exists for.
*)
SweepRecord(r, e) ==
  /\ e \in pending[r]
  /\ ~e.aged
  /\ ~Carries(r, KeyOf(e))
  /\ HasIntent(r, KeyOf(e))
  /\ Land(r, [kind |-> "rec", act |-> e.act, inv |-> e.inv, actor |-> e.who,   \* BUG: the owed record's actor
              aged |-> e.aged, after_intent |-> HasIntent(r, KeyOf(e))])
  /\ UNCHANGED <<pending, owed>>
  /\ UNCHANGED comp_vars

(*
  An entry's owed record ages (Term aged event): its instant plus the audit horizon
  comes to precede now. Never back.
*)
EntryAges(r, e) ==
  /\ e \in pending[r]
  /\ ~e.aged
  /\ pending' = [pending EXCEPT ![r] = (@ \ {e}) \cup {[e EXCEPT !.aged = TRUE]}]
  /\ UNCHANGED <<trail, owed, rewritten>>
  /\ UNCHANGED comp_vars

----

(* ─── Next-state relation ────────────────────────────────────────────────── *)

Next ==
  \/ \E r \in RequestIDs, a \in ApproverIDs : ApproveStep(r, a)
  \/ \E r \in RequestIDs, a \in ApproverIDs : DecisionNotPending(r, a)
  \/ \E r \in RequestIDs, a \in ApproverIDs : RejectStep(r, a)
  \/ \E r \in RequestIDs                    : WithdrawRequest(r)
  \/ \E r \in RequestIDs                    : ExerciseAccess(r)
  \/ \E r \in RequestIDs                    : RevokeAccess(r)
  \/ \E r \in RequestIDs : \E e \in pending[r] : SweepFound(r, e)
  \/ \E r \in RequestIDs : \E e \in pending[r] : SweepIntent(r, e)
  \/ \E r \in RequestIDs : \E e \in pending[r] : SweepRecord(r, e)
  \/ \E r \in RequestIDs : \E e \in pending[r] : EntryAges(r, e)

Spec == Init /\ [][Next]_vars

----

(* ─── Safety invariants ──────────────────────────────────────────────────── *)

(*
  Invariant 1 — Approval-gates-provisioning.
  Every request_id that has a capability token must have an Approved chain.
  A token in request_to_cap without an Approved chain is a provisioning bypass.
*)
ApprovalGatesProvisioning ==
  \A r \in RequestIDs :
    request_to_cap[r] # "none" => chain_state[r] = "Approved"

(*
  Invariant 2 — Request-capability bijection.
  Each request maps to at most one token; each token maps to at most one request.
  request_to_cap and cap_to_request are strict inverses.
*)
MapInverseConsistency ==
  /\ \A r \in RequestIDs :
       request_to_cap[r] # "none" =>
         cap_to_request[request_to_cap[r]] = r
  /\ \A t \in CapTokens :
       cap_to_request[t] # "none" =>
         request_to_cap[cap_to_request[t]] = t

(*
  Invariant 8.2, Composition state 6 and 7 — Terminal state absorbing.
  A request in a terminal request state (Denied, Withdrawn, Revoked,
  ProvisioningFailed) never changes state, so never returns to Pending; a
  Provisioned request moves only to Revoked (the request progression). A step
  formula, checked as the action property TerminalAbsorbingProp.
*)
TerminalAbsorbingAction ==
  \A r \in RequestIDs :
    /\ (request_state[r] \in TerminalStates \ {"Provisioned"}) =>
         (request_state'[r] = request_state[r])
    /\ (request_state[r] = "Provisioned") =>
         (request_state'[r] \in {"Provisioned", "Revoked"})

TerminalAbsorbingProp == [][TerminalAbsorbingAction]_vars

(*
  CascadeFiresAtMostOnce (Invariant 2.1, Composition state 37).
  The provisioning cascade fires at most once per request, whether it allocates
  or fails: a second firing would allocate a second token (or reopen a failed
  request). Read off the history counter cascade_fired, so a second firing that
  writes the same token, and leaves the maps strict inverses, still breaks it.
*)
CascadeFiresAtMostOnce ==
  \A r \in RequestIDs : cascade_fired[r] <= 1

(*
  DeniedNamesRejectedChain (Invariant 7.2).
  Every Denied request names a chain whose state is Rejected.
*)
DeniedNamesRejectedChain ==
  \A r \in RequestIDs :
    request_state[r] = "Denied" => chain_state[r] = "Rejected"

(*
  TokensAllocatedOnlyForProvisioned.
  Every allocated token corresponds to a request that is Provisioned or Revoked.
  (Revoked is included because revoke_access does not remove the token from the map.)
*)
TokensAllocatedOnlyForProvisioned ==
  \A t \in cap_allocated :
    \E r \in RequestIDs :
      /\ request_to_cap[r] = t
      /\ request_state[r] \in {"Provisioned", "Revoked"}

(*
  NoPendingRequestHasToken.
  A request in Pending state never has a capability token.
*)
NoPendingRequestHasToken ==
  \A r \in RequestIDs :
    request_state[r] = "Pending" => request_to_cap[r] = "none"

(*
  NoExhaustedTokenBeforeExercise.
  A token cannot be exhausted unless it was allocated.
*)
ExhaustedSubsetAllocated ==
  cap_exhausted \subseteq cap_allocated

(* ─── The sweep's invariants ──────────────────────────────────────────────── *)

(* A reconciliation write: a recovery intent or a recovery record. *)
SweepWrite(x) == x.kind \in {"intent", "rec"}

(*
  SweepPreCheckNoDuplicate (Reconciliation 4, 5, 6).
  No two events of one request carry the same action reference and invocation id,
  a recovery record read as the event it names, and no write ever landed a record
  the trail already carried: the pre-check reads the trail before every emit, and
  a found event closes the entry with nothing emitted.
*)
SweepPreCheckNoDuplicate ==
  \A r \in RequestIDs :
    /\ ~rewritten[r]
    /\ \A x, y \in trail[r] :
         (x # y /\ ~(x.kind = "intent") /\ ~(y.kind = "intent")) => (KeyOf(x) # KeyOf(y))

(*
  SweepAttestedByService (Reconciliation 11).
  Every reconciliation write is attested under the service identity, never under
  the actor of the record it stands in for.
*)
SweepAttestedByService ==
  \A r \in RequestIDs : \A x \in trail[r] :
    SweepWrite(x) => (x.actor = "svc")

(*
  SweepNoAgedWrite (Reconciliation 10).
  No reconciliation write landed while the owed record it served was aged.
*)
SweepNoAgedWrite ==
  \A r \in RequestIDs : \A x \in trail[r] :
    SweepWrite(x) => ~x.aged

(*
  RecoveryRecordNamesOwed (Reconciliation 15).
  A recovery record carries the action reference and the invocation id of a record
  the request owed (one a pending entry carried), so it reads as the event it names.
*)
RecoveryRecordNamesOwed ==
  \A r \in RequestIDs : \A x \in trail[r] :
    (x.kind = "rec") => (KeyOf(x) \in owed[r])

(*
  RecoveryRecordFollowsIntent (Reconciliation 12 through 14).
  A recovery record landed only after the leg's recovery intent for the same owed
  record (its action reference and invocation id) was on the trail.
*)
RecoveryRecordFollowsIntent ==
  \A r \in RequestIDs : \A x \in trail[r] :
    (x.kind = "rec") => x.after_intent

----

(* ─── Liveness (optional; requires fairness assumption) ─────────────────── *)

(*
  Under weak fairness on all actions, a request with enough approvals
  eventually reaches a terminal state.
  Uncomment to check with TLC under fairness.

FairnessSpec ==
  /\ Spec
  /\ \A r \in RequestIDs : WF_vars(WithdrawRequest(r))
  /\ \A r \in RequestIDs : WF_vars(RevokeAccess(r))
  /\ \A r \in RequestIDs, a \in ApproverIDs : WF_vars(ApproveStep(r, a))

EventuallyTerminal ==
  \A r \in RequestIDs :
    <>(request_state[r] \in TerminalStates)
*)

----

(* ─── TLC configuration ──────────────────────────────────────────────────── *)

(*
  Suggested TLC model values for a small but meaningful scope:
    RequestIDs  <- {"r1", "r2"}
    ApproverIDs <- {"a1", "a2", "a3"}
    CapTokens   <- {"cap1", "cap2"}
    QuorumSize  <- 2

  Invariants to check:
    TypeOK
    ApprovalGatesProvisioning
    MapInverseConsistency
    CascadeFiresAtMostOnce
    TokensAllocatedOnlyForProvisioned
    NoPendingRequestHasToken
    ExhaustedSubsetAllocated
    DeniedNamesRejectedChain
    SweepPreCheckNoDuplicate
    SweepAttestedByService
    SweepNoAgedWrite
    RecoveryRecordNamesOwed
    RecoveryRecordFollowsIntent

  Property (PROPERTY in the .cfg; not an ACTION_CONSTRAINT, which would only
  prune transitions and assert nothing):
    TerminalAbsorbingProp

  Expected result: all invariants hold; no deadlock.
  A violated invariant is a spec finding for the composition.
*)

====

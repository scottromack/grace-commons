-- approval-step-buggy-approver-unguarded.als
-- DELIBERATELY WRONG twin of approval-step.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: the deciding actions drop Operation 21's guard (the deciding actor must be the
-- approver reference), modeling an endpoint that checks only that the caller is
-- signed in: any actor may approve or reject.
--
-- BREAKS: A_Invariant_4_1, A_Invariant_4_2.
-- Everything else is approval-step.als as written; read its comments there.

module approval_step_buggy_approver_unguarded

open util/ordering[Instant] as T

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a string value a call carries or a record holds — a reference, a scope or a
-- reason. The atom compares strings byte-exactly and never interprets them (Identity 10
-- to 13, String 1 to 4), so a string here is an uninterpreted token.
sig Str {}

-- Blank: the strings the atom reads as blank, the whitespace-only ones (String 5). Which
-- strings these are is the world's, not the atom's, so it is a subset with no rule on it.
sig Blank in Str {}

-- Instant: a moment on the deployment's clock. Only the order of instants matters to
-- the page's rules ("precedes"), so instants are ordered atoms.
sig Instant {}

-- State: the four states of a step (Term states); approved, rejected and withdrawn are
-- the terminal ones (Term terminal state).
abstract sig State {}
one sig Pending, Approved, Rejected, Withdrawn extends State {}

-- Step: the record this atom keeps (Term records). Every field the page names is here,
-- and every one may be absent, so a write that forgot one would show. The state is a set
-- of state flags, so a write that ADDED a state instead of replacing one would show too:
-- what the page promises (exactly one) is checked, never built into the type.
sig Step {
    stepId           : lone Str,      -- step id (Identity 1)
    subject          : lone Str,      -- subject reference
    approver         : lone Str,      -- approver reference, the authorization anchor of a decision
    submitter        : lone Str,      -- submitter reference, the authorization anchor of a withdrawal
    scope            : lone Str,      -- scope
    submittedAt      : lone Instant,  -- submission instant
    reason           : lone Str,      -- the optional submission reason (State 8)
    state            : set State,     -- the step's state (State 7)
    decidedBy        : lone Str,      -- deciding actor (approved, rejected)
    decisionReason   : lone Str,      -- decision reason (rejected; optional on approved)
    decidedAt        : lone Instant,  -- decision instant (approved, rejected)
    withdrawnBy      : lone Str,      -- withdrawing actor (withdrawn)
    withdrawalReason : lone Str,      -- withdrawal reason (withdrawn)
    withdrawnAt      : lone Instant   -- withdrawal instant (withdrawn)
}

-- SubmitCall: one [Submit] call, its inputs as they reach the seam. The caller supplies
-- the references, the scope and the optional reason and submission instant; the host
-- injects now (Capability requirement 1) and the step id it allocates (Identity 2).
sig SubmitCall {
    allocatedId   : one Str,       -- the step id the host injects (Capability requirement 7)
    now           : one Instant,   -- the clock reading at the call (Term now)
    subjectIn     : lone Str,      -- subject_ref
    approverIn    : lone Str,      -- approver_ref
    submitterIn   : lone Str,      -- submitter_ref
    scopeIn       : lone Str,      -- scope
    reasonIn      : lone Str,      -- optional reason
    submittedAtIn : lone Instant   -- optional submitted_at
}

-- ResolveCall: one resolving action (Term resolving action), its inputs as they reach
-- the seam: the deciding reference, the reason, the optional instant, and now. Which
-- step it names is given by the record it finds (see `resolveWrites`).
abstract sig ResolveCall {
    actorIn : lone Str,      -- decided_by, or withdrawn_by on [Withdraw] (Term deciding reference)
    reasonIn : lone Str,     -- reason (optional on [Approve])
    atIn    : lone Instant,  -- optional decided_at / withdrawn_at
    now     : one Instant    -- the clock reading at the call (Term now)
}
-- The three resolving actions; [Approve] and [Reject] are the deciding actions.
sig ApproveCall, RejectCall, WithdrawCall extends ResolveCall {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host allocates a step id that is not blank (Execution Contract Input 2, which the
-- page cites in Capability requirement 6). The page's own guards never look at the step
-- id on [Submit], so this is where Invariant 8.1's step-id half comes from.
fact HostAllocatesANonBlankId {
    all c : SubmitCall | c.allocatedId not in Blank
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a string is present and not whitespace-only. An absent input reads as blank
-- (String 6), and so does an absent field.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- resolvedInstant: an instant a call leaves blank is now (Execution Contract Logic
-- confinement 12, Term resolved submission instant, Term resolved decision instant).
fun resolvedInstant[supplied : lone Instant, now : one Instant] : one Instant {
    some supplied => supplied else now
}

-- precedes: one instant is strictly earlier than another.
pred precedes[a, b : Instant] {
    T/lt[a, b]
}

-- terminal: the step stands in a terminal state.
pred terminal[s : Step] {
    some s.state & (Approved + Rejected + Withdrawn)
}

-- terminalInstant: the instant of the terminal state the step stands in — the decision
-- instant of an approved or rejected step, the withdrawal instant of a withdrawn one.
fun terminalInstant[s : Step] : set Instant {
    (some s.state & (Approved + Rejected) => s.decidedAt else none)
    + (Withdrawn in s.state => s.withdrawnAt else none)
}

-- noAttribution: the step carries no attribution field (Term attribution field).
pred noAttribution[s : Step] {
    no s.decidedBy
    no s.decisionReason
    no s.decidedAt
    no s.withdrawnBy
    no s.withdrawalReason
    no s.withdrawnAt
}

-- ─────────────────────────────────────────────────────────────────────────────
-- [Submit]: its guards and its write
-- ─────────────────────────────────────────────────────────────────────────────

-- submitAdmitted: the guards of [Submit] admit the call (Term admitted submit).
pred submitAdmitted[c : SubmitCall] {
    nonBlank[c.subjectIn]                                      -- Operation 1
    nonBlank[c.approverIn]                                     -- Operation 2
    nonBlank[c.submitterIn]                                    -- Operation 3
    nonBlank[c.scopeIn]                                        -- Operation 4
    some c.reasonIn implies nonBlank[c.reasonIn]               -- Operation 5
    not precedes[c.now, resolvedInstant[c.submittedAtIn, c.now]]  -- Operation 6
}

-- submitWrites: the record an admitted [Submit] leaves. It sets the submission fields
-- (Term submission field) and the state, and nothing a resolving action sets.
pred submitWrites[c : SubmitCall, s : Step] {
    submitAdmitted[c]
    s.stepId      = c.allocatedId                               -- Identity 2
    s.subject     = c.subjectIn                                 -- Operation 62
    s.approver    = c.approverIn                                -- Operation 62
    s.submitter   = c.submitterIn                               -- Operation 62
    s.scope       = c.scopeIn                                   -- Operation 62
    s.submittedAt = resolvedInstant[c.submittedAtIn, c.now]     -- Operation 62
    s.reason      = c.reasonIn                                  -- Operation 61
    s.state       = Pending                                     -- Operation 8
    noAttribution[s]                                            -- Term submission field
}

-- submitted: the record is one an admitted [Submit] left.
pred submitted[s : Step] {
    some c : SubmitCall | submitWrites[c, s]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The resolving actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- resolveAdmitted: the guards of a resolving action admit the call on the step it finds
-- (Term admitted resolve). The step must be pending (Operation 13); the attribution
-- checks must pass (Term attribution check); the deciding reference must be the step's
-- authorization anchor (Term authorization anchor).
pred resolveAdmitted[pre : Step, c : ResolveCall] {
    pre.state = Pending                                                 -- Operation 13
    nonBlank[c.actorIn]                                                 -- Operation 15
    c in RejectCall   implies nonBlank[c.reasonIn]                      -- Operation 16
    c in WithdrawCall implies nonBlank[c.reasonIn]                      -- Operation 17
    c in ApproveCall  implies (some c.reasonIn implies nonBlank[c.reasonIn])  -- Operation 57
    not precedes[c.now, resolvedInstant[c.atIn, c.now]]                 -- Operation 18
    not precedes[resolvedInstant[c.atIn, c.now], pre.submittedAt]       -- Operation 19
    -- BUG: Operation 21's guard is gone; any actor may approve or reject
    c in WithdrawCall implies c.actorIn = pre.submitter                 -- Operation 22
}

-- keepsSubmission: the resolve leaves every submission field as it found it (Operation 33).
pred keepsSubmission[pre, post : Step] {
    post.stepId      = pre.stepId
    post.subject     = pre.subject
    post.approver    = pre.approver
    post.submitter   = pre.submitter
    post.scope       = pre.scope
    post.submittedAt = pre.submittedAt
    post.reason      = pre.reason
}

-- keepsDecision / keepsWithdrawal: the resolve leaves the other action's fields as it
-- found them (a resolve sets only the fields its own rule names).
pred keepsDecision[pre, post : Step] {
    post.decidedBy      = pre.decidedBy
    post.decisionReason = pre.decisionReason
    post.decidedAt      = pre.decidedAt
}
pred keepsWithdrawal[pre, post : Step] {
    post.withdrawnBy      = pre.withdrawnBy
    post.withdrawalReason = pre.withdrawalReason
    post.withdrawnAt      = pre.withdrawnAt
}

-- approveWrites: the record an admitted [Approve] leaves over the pending step.
pred approveWrites[pre : Step, c : ApproveCall, post : Step] {
    post.state          = Approved                                -- Operation 24
    post.decidedBy      = c.actorIn                               -- Operation 27
    post.decidedAt      = resolvedInstant[c.atIn, c.now]          -- Operation 27
    post.decisionReason = c.reasonIn                              -- Operation 30
    keepsWithdrawal[pre, post]
}

-- rejectWrites: the record an admitted [Reject] leaves over the pending step.
pred rejectWrites[pre : Step, c : RejectCall, post : Step] {
    post.state          = Rejected                                -- Operation 25
    post.decidedBy      = c.actorIn                               -- Operation 28
    post.decisionReason = c.reasonIn                              -- Operation 28
    post.decidedAt      = resolvedInstant[c.atIn, c.now]          -- Operation 28
    keepsWithdrawal[pre, post]
}

-- withdrawWrites: the record an admitted [Withdraw] leaves over the pending step.
pred withdrawWrites[pre : Step, c : WithdrawCall, post : Step] {
    post.state            = Withdrawn                             -- Operation 26
    post.withdrawnBy      = c.actorIn                             -- Operation 29
    post.withdrawalReason = c.reasonIn                            -- Operation 29
    post.withdrawnAt      = resolvedInstant[c.atIn, c.now]        -- Operation 29
    keepsDecision[pre, post]
}

-- resolveWrites: the record an admitted resolving action leaves over the step it finds.
pred resolveWrites[pre : Step, c : ResolveCall, post : Step] {
    resolveAdmitted[pre, c]
    keepsSubmission[pre, post]
    c in ApproveCall  implies approveWrites[pre, c, post]
    c in RejectCall   implies rejectWrites[pre, c, post]
    c in WithdrawCall implies withdrawWrites[pre, c, post]
}

-- resolved: the record is one an admitted resolving action left over a record [Submit] left.
pred resolved[s : Step] {
    some pre : Step, c : ResolveCall | submitted[pre] and resolveWrites[pre, c, s]
}

-- recorded: a record the page lets a step hold (see SCOPE): what [Submit] wrote, or what
-- one admitted resolve wrote over it.
pred recorded[s : Step] {
    submitted[s] or resolved[s]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_2_1: every step stands in exactly one of the four states. [Submit] stands
-- it pending and each resolve replaces pending with its own terminal state.
assert A_Invariant_2_1 {
    all s : Step | recorded[s] implies one s.state
}
check A_Invariant_2_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_4_1: an approved step's deciding actor is its approver reference. Only the
-- named approver may approve (Operation 21), and [Approve] records who did (Operation 27).
assert A_Invariant_4_1 {
    all s : Step | (recorded[s] and Approved in s.state) implies s.decidedBy = s.approver
}
check A_Invariant_4_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_4_2: a rejected step's deciding actor is its approver reference
-- (Operation 21, Operation 28).
assert A_Invariant_4_2 {
    all s : Step | (recorded[s] and Rejected in s.state) implies s.decidedBy = s.approver
}
check A_Invariant_4_2 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_5_1: a withdrawn step's withdrawing actor is its submitter reference. Only
-- the submitter may withdraw (Operation 22), and [Withdraw] records who did (Operation 29).
assert A_Invariant_5_1 {
    all s : Step | (recorded[s] and Withdrawn in s.state) implies s.withdrawnBy = s.submitter
}
check A_Invariant_5_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_6_1: every terminal step names, non-blank, who closed it: the deciding
-- actor of an approved or rejected step, the withdrawing actor of a withdrawn one (Term
-- attribution reference). No anonymous decision.
assert A_Invariant_6_1 {
    all s : Step | recorded[s] implies {
        some s.state & (Approved + Rejected) implies nonBlank[s.decidedBy]
        Withdrawn in s.state implies nonBlank[s.withdrawnBy]
    }
}
check A_Invariant_6_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_6_2: every terminal step carries its terminal state's instant: the decision
-- instant of an approved or rejected step, the withdrawal instant of a withdrawn one.
assert A_Invariant_6_2 {
    all s : Step | recorded[s] implies {
        some s.state & (Approved + Rejected) implies some s.decidedAt
        Withdrawn in s.state implies some s.withdrawnAt
    }
}
check A_Invariant_6_2 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_6_3: every rejected step carries a non-blank decision reason. A rejection
-- with no stated reason is not an audit record (Operation 16, Operation 28).
assert A_Invariant_6_3 {
    all s : Step | (recorded[s] and Rejected in s.state) implies nonBlank[s.decisionReason]
}
check A_Invariant_6_3 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_6_4: every withdrawn step carries a non-blank withdrawal reason
-- (Operation 17, Operation 29).
assert A_Invariant_6_4 {
    all s : Step | (recorded[s] and Withdrawn in s.state) implies nonBlank[s.withdrawalReason]
}
check A_Invariant_6_4 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_7_1: a terminal step's terminal instant is never earlier than its
-- submission instant: a decision cannot predate the thing it decides (Operation 19). The
-- clock is not assumed to run forward (Non-goal 22), so the guard, not the clock, holds it.
assert A_Invariant_7_1 {
    all s : Step | (recorded[s] and terminal[s]) implies
        (all t : terminalInstant[s] | not precedes[t, s.submittedAt])
}
check A_Invariant_7_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_8_1: every step's step id, subject reference, approver reference,
-- submitter reference and scope stand non-blank (Operation 1 to 4; the host's id, see
-- the fact above).
assert A_Invariant_8_1 {
    all s : Step | recorded[s] implies {
        nonBlank[s.stepId]
        nonBlank[s.subject]
        nonBlank[s.approver]
        nonBlank[s.submitter]
        nonBlank[s.scope]
    }
}
check A_Invariant_8_1 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_Invariant_8_2: every step carries a submission instant: a submit that supplies none
-- records now (Operation 62, Execution Contract Logic confinement 12).
assert A_Invariant_8_2 {
    all s : Step | recorded[s] implies some s.submittedAt
}
check A_Invariant_8_2 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- A_State_13: a pending step carries no attribution field (Check 5.1): nothing about a
-- decision or a withdrawal is on a gate that is still open.
assert A_State_13 {
    all s : Step | (recorded[s] and Pending in s.state) implies noAttribution[s]
}
check A_State_13 for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowPendingStep: a step just submitted, with no submission reason (its absence is valid).
run ShowPendingStep {
    some s : Step | submitted[s] and no s.reason
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowPendingWithReason: a step submitted with a reason (State 8, Operation 61).
run ShowPendingWithReason {
    some s : Step | submitted[s] and some s.reason
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowApprovedWithoutReason: an approval that gives no reason (State 12: a reason is optional).
run ShowApprovedWithoutReason {
    some s : Step | resolved[s] and s.state = Approved and no s.decisionReason
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowApprovedWithReason: an approval that gives one (Operation 30).
run ShowApprovedWithReason {
    some s : Step | resolved[s] and s.state = Approved and some s.decisionReason
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowRejected: a rejection, with its reason (the SOX example's misclassified entry).
run ShowRejected {
    some s : Step | resolved[s] and s.state = Rejected
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowWithdrawn: a withdrawal by the submitter, with its reason (the wrong-approver example).
run ShowWithdrawn {
    some s : Step | resolved[s] and s.state = Withdrawn
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowSubmitterIsApprover: the atom does not refuse a step whose submitter is its approver
-- (Non-goal 13: segregation of duties is a composing pattern's), and that actor may decide it.
run ShowSubmitterIsApprover {
    some s : Step | resolved[s] and s.state = Approved and s.submitter = s.approver
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowDecidedAtTheSubmissionInstant: a decision at the very instant of submission is
-- admitted ("MUST NOT PRECEDE" allows equality, Invariant 7.1).
run ShowDecidedAtTheSubmissionInstant {
    some s : Step | resolved[s] and terminalInstant[s] = s.submittedAt
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowBackdatedSubmission: a submission instant the caller supplies in the past is
-- recorded as supplied (Non-goal 20: the atom does not bound it from below).
run ShowBackdatedSubmission {
    some c : SubmitCall, s : Step | submitWrites[c, s] and precedes[s.submittedAt, c.now]
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

-- ShowTwoStepsOneSubject: two steps on one subject, each with its own id and approver
-- (Identity 9; the cross-border example's finance and tax gates).
run ShowTwoStepsOneSubject {
    some disj s1, s2 : Step | submitted[s1] and submitted[s2]
        and s1.subject = s2.subject and s1.stepId != s2.stepId and s1.approver != s2.approver
} for 4 but 3 Step, 2 SubmitCall, 2 ResolveCall

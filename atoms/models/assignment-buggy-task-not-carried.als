-- assignment-buggy-task-not-carried.als
-- DELIBERATELY WRONG twin of assignment.als (unit: every check has a twin that breaks it).
--
-- INJECTED DEFECT: [Reassign] records the new assignment without the task reference of the one it
-- hands on (Operation 19: the new active assignment is for the task reference).
--
-- BREAKS: A_State_2.
-- Everything else is assignment.als as written; read its comments there.

module assignment_buggy_task_not_carried

open util/ordering[Instant] as T
open util/ordering[Call] as C

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Ref: an opaque reference, a task reference or an assignee reference (Term task
-- reference, Term assignee reference). The atom never interprets one.
sig Ref {}

-- Id: an opaque assignment id (Term assignment id). It means nothing by itself.
sig Id {}

-- Instant: a moment on the deployment's clock. Only the order of instants matters to the
-- page's rules ("precede"), so instants are ordered atoms.
sig Instant {}

-- Status: the three statuses of an assignment (Term status); recalled and transferred are
-- the terminal ones.
abstract sig Status {}
one sig Active, Recalled, Transferred extends Status {}

-- Call: one call of a writing action, as it reaches the seam. Calls happen in one order,
-- the order Execution Contract Order 1 gives every commit; `now` is the clock reading the
-- host injects for the call (Term now, Capability requirement 1).
abstract sig Call {
    now : one Instant
}

-- RecordingCall: a call that records a new assignment, [Assign] or [Reassign]. The host
-- allocates its assignment id at the seam (Identity 2); the transition allocates none
-- (Identity 3).
abstract sig RecordingCall extends Call {
    allocatedId : one Id
}

-- AssignCall: one [Assign] call and its inputs, assign(task_ref, assignee_ref).
sig AssignCall extends RecordingCall {
    taskIn     : lone Ref,   -- task_ref
    assigneeIn : lone Ref    -- assignee_ref
}

-- ReassignCall: one [Reassign] call and its new assignee reference,
-- reassign(assignment_id, new_assignee_ref). The assignment it names is the version it
-- finds (see `written`).
sig ReassignCall extends RecordingCall {
    newAssigneeIn : lone Ref -- new_assignee_ref (Term new assignee reference)
}

-- RecallCall: one [Recall] call, recall(assignment_id). The assignment it names is the
-- version it finds.
sig RecallCall extends Call {}

-- Assignment: one version of an assignment record (Term records), as the call that wrote
-- it left it. Every field the page names is here and every one may be absent, so a write
-- that forgot one would show. The status is a set of status flags, so a write that ADDED a
-- status instead of replacing one would show too: what the page promises (exactly one) is
-- checked, never built into the type. The last three fields are the model's own: which
-- call wrote this version and which version that call found; the page has no such fields.
sig Assignment {
    assignmentId  : lone Id,        -- assignment id (Identity 1)
    task          : lone Ref,       -- task reference
    assignee      : lone Ref,       -- assignee reference
    assignedAt    : lone Instant,   -- assignment instant
    status        : set Status,     -- status (State 1)
    recalledAt    : lone Instant,   -- recall instant (State 3)
    transferredAt : lone Instant,   -- transfer instant (State 4)
    writtenBy     : one Call,       -- the call whose write left this version
    found         : lone Assignment,-- the version of this assignment that call found ([Recall], [Reassign])
    handedFrom    : lone Assignment -- for the assignment a [Reassign] recorded: the version of the old one it found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The clock never runs backward: a later call's reading does not precede an earlier
-- call's (Execution Contract Logic confinement 7, which the page cites for its clock:
-- monotonicity is the deployment's). It may repeat a reading. No guard of the page
-- compares instants, so this is where Invariant 8.1 and 8.2 come from.
fact ClockNeverRunsBackward {
    all a, b : Call | C/lt[a, b] implies not T/lt[b.now, a.now]
}

-- The host supplies an id it allocates to one call only (Execution Contract Logic
-- confinement 16). The page's own rules say only that the host allocates the id
-- (Identity 2) and the transition does not (Identity 3), so this is where Invariant 6.1
-- comes from.
fact HostSuppliesAnIdToOneCall {
    all disj a, b : RecordingCall | a.allocatedId != b.allocatedId
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- precedes: one instant is strictly earlier than another.
pred precedes[a, b : Instant] {
    T/lt[a, b]
}

-- noEnd: the version carries neither end instant. A call writes only the fields its own
-- rules name, so a newly recorded assignment carries none.
pred noEnd[s : Assignment] {
    no s.recalledAt
    no s.transferredAt
}

-- keepsRecord: the call leaves the fields it does not write as it found them (a call
-- writes only the fields its own rules name).
pred keepsRecord[pre, post : Assignment] {
    post.assignmentId = pre.assignmentId
    post.task         = pre.task
    post.assignee     = pre.assignee
    post.assignedAt   = pre.assignedAt
}

-- origin: the call that recorded the assignment this version belongs to — the writer of
-- the first version along the chain of versions found.
fun origin[s : Assignment] : set Call {
    { v : s.*found | no v.found }.writtenBy
}

-- named: the actor a recording call handed the task to — the assignee reference of an
-- [Assign], the new assignee reference of a [Reassign].
fun named[c : Call] : set Ref {
    c.assigneeIn + c.newAssigneeIn
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- assignWrites: the record an admitted [Assign] leaves.
pred assignWrites[c : AssignCall, s : Assignment] {
    some c.taskIn                                  -- Operation 4
    some c.assigneeIn                              -- Operation 5
    s.assignmentId = c.allocatedId                 -- Identity 2, Invariant 5.1
    s.task         = c.taskIn                      -- Term Assign
    s.assignee     = c.assigneeIn                  -- Term Assign
    s.assignedAt   = c.now                         -- State 5
    s.status       = Active                        -- Operation 2
    noEnd[s]
}

-- recallWrites: the version an admitted [Recall] leaves over the active one it found.
pred recallWrites[pre : Assignment, c : RecallCall, s : Assignment] {
    pre.status = Active                            -- Operation 9, 10
    keepsRecord[pre, s]
    s.status        = Recalled                     -- Operation 11
    s.recalledAt    = c.now                        -- State 6
    s.transferredAt = pre.transferredAt
}

-- transferWrites: the version an admitted [Reassign] leaves of the active one it found.
pred transferWrites[pre : Assignment, c : ReassignCall, s : Assignment] {
    pre.status = Active                            -- Operation 15, 16
    some c.newAssigneeIn                           -- Operation 17
    keepsRecord[pre, s]
    s.status        = Transferred                  -- Operation 18
    s.transferredAt = c.now                        -- State 7
    s.recalledAt    = pre.recalledAt
}

-- handoffWrites: the new assignment an admitted [Reassign] records for the task of the
-- active one it found.
pred handoffWrites[pre : Assignment, c : ReassignCall, s : Assignment] {
    pre.status = Active                            -- Operation 15, 16
    some c.newAssigneeIn                           -- Operation 17
    s.assignmentId = c.allocatedId                 -- Identity 2
    no s.task                                      -- BUG: the task reference is not carried over
    s.assignee     = c.newAssigneeIn               -- Operation 38
    s.assignedAt   = c.now                         -- Operation 30b
    s.status       = Active                        -- Operation 19
    noEnd[s]
}

-- written: the version is what its call's write left, over a version an earlier call wrote
-- (a call finds only what was committed before it, Execution Contract Database 2).
pred written[v : Assignment] {
    let c = v.writtenBy {
        (c in AssignCall and no v.found and no v.handedFrom
            and assignWrites[c, v])
        or (c in RecallCall and some v.found and no v.handedFrom
            and C/lt[v.found.writtenBy, c] and recallWrites[v.found, c, v])
        or (c in ReassignCall and some v.found and no v.handedFrom
            and C/lt[v.found.writtenBy, c] and transferWrites[v.found, c, v])
        or (c in ReassignCall and no v.found and some v.handedFrom
            and C/lt[v.handedFrom.writtenBy, c] and handoffWrites[v.handedFrom, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): it and every version
-- it was built from are what an admitted call wrote.
pred recorded[s : Assignment] {
    all v : s.*(found + handedFrom) | written[v]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave that violates this
-- assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every assignment stands in exactly one status. [Assign] and [Reassign] record
-- it active, and [Recall] and [Reassign] replace active with their terminal status.
assert A_State_1 {
    all s : Assignment | recorded[s] implies one s.status
}
check A_State_1 for 4 but 5 Assignment, 3 Call

-- A_State_2: every assignment carries its assignment id, task reference, assignee
-- reference, assignment instant and status, however it was recorded and whatever ended it.
assert A_State_2 {
    all s : Assignment | recorded[s] implies {
        some s.assignmentId
        some s.task
        some s.assignee
        some s.assignedAt
        some s.status
    }
}
check A_State_2 for 4 but 5 Assignment, 3 Call

-- A_State_3: a recalled assignment carries the instant it was withdrawn.
assert A_State_3 {
    all s : Assignment | (recorded[s] and Recalled in s.status) implies some s.recalledAt
}
check A_State_3 for 4 but 5 Assignment, 3 Call

-- A_State_4: a transferred assignment carries the instant it was handed on.
assert A_State_4 {
    all s : Assignment | (recorded[s] and Transferred in s.status) implies some s.transferredAt
}
check A_State_4 for 4 but 5 Assignment, 3 Call

-- A_Invariant_5_1: an assignment [Assign] recorded carries the assignment id the host
-- allocated for that call (Identity 2): [Assign] sets the id, and no later call changes
-- which id the assignment is known by.
assert A_Invariant_5_1 {
    all s : Assignment | (recorded[s] and origin[s] in AssignCall)
        implies s.assignmentId = origin[s].allocatedId
}
check A_Invariant_5_1 for 4 but 5 Assignment, 3 Call

-- A_Invariant_6_1: two assignments never share an assignment id. Two versions recorded by
-- different calls are different assignments, and no two carry one id, so an id names one
-- assignment and its whole history.
assert A_Invariant_6_1 {
    all s1, s2 : Assignment | (recorded[s1] and recorded[s2] and origin[s1] != origin[s2])
        implies s1.assignmentId != s2.assignmentId
}
check A_Invariant_6_1 for 4 but 5 Assignment, 3 Call

-- A_Invariant_7_2: the assignment a [Reassign] handed on stands in transferred once the
-- reassign lands, so the task's responsibility moves to the new assignment rather than
-- being held twice.
assert A_Invariant_7_2 {
    all s : Assignment | (recorded[s] and s.writtenBy in ReassignCall and some s.found)
        implies s.status = Transferred
}
check A_Invariant_7_2 for 4 but 5 Assignment, 3 Call

-- A_Invariant_8_1: a recall instant never precedes the assignment instant: an assignment
-- is not withdrawn before it began. No guard compares them; the stamps (State 5, State 6)
-- and the clock (the fact above) hold it.
assert A_Invariant_8_1 {
    all s : Assignment | (recorded[s] and some s.recalledAt)
        implies not precedes[s.recalledAt, s.assignedAt]
}
check A_Invariant_8_1 for 4 but 5 Assignment, 3 Call

-- A_Invariant_8_2: a transfer instant never precedes the assignment instant: an assignment
-- is not handed on before it began (State 5, Operation 30b, State 7, and the clock).
assert A_Invariant_8_2 {
    all s : Assignment | (recorded[s] and some s.transferredAt)
        implies not precedes[s.transferredAt, s.assignedAt]
}
check A_Invariant_8_2 for 4 but 5 Assignment, 3 Call

-- A_Invariant_9_1: every assignment names, as its assignee reference, the actor the call
-- that recorded it handed the task to — the assignee of an [Assign], the new assignee of a
-- [Reassign] — so the records for a task name every actor a call made responsible for it.
-- (That no such record is later lost is Invariant 10.1's, across steps.)
assert A_Invariant_9_1 {
    all s : Assignment | recorded[s] implies s.assignee = named[origin[s]]
}
check A_Invariant_9_1 for 4 but 5 Assignment, 3 Call

-- A_Invariant_9_2: every assignment records when its holding began: its assignment instant
-- is the clock reading of the call that recorded it (State 5, Operation 30b).
assert A_Invariant_9_2 {
    all s : Assignment | recorded[s] implies s.assignedAt = origin[s].now
}
check A_Invariant_9_2 for 4 but 5 Assignment, 3 Call

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAssigned: an assignment just recorded by [Assign], active (the sprint board's a1).
run ShowAssigned {
    some s : Assignment | recorded[s] and s.writtenBy in AssignCall
} for 4 but 5 Assignment, 3 Call

-- ShowRecalled: an assignment withdrawn with nobody after (the rejection-path a1).
run ShowRecalled {
    some s : Assignment | recorded[s] and s.status = Recalled
} for 4 but 5 Assignment, 3 Call

-- ShowTransferred: an assignment handed on by [Reassign] (Alice's a1 after the handoff).
run ShowTransferred {
    some s : Assignment | recorded[s] and s.status = Transferred
} for 4 but 5 Assignment, 3 Call

-- ShowHandedOn: the active assignment a [Reassign] recorded, for the same task as the one
-- it handed on and naming a different actor (Bob's a2).
run ShowHandedOn {
    some s : Assignment | recorded[s] and some s.handedFrom and s.status = Active
        and s.task = s.handedFrom.task and s.assignee != s.handedFrom.assignee
} for 4 but 5 Assignment, 3 Call

-- ShowSuccessorRecalled: an assignment a [Reassign] recorded, later recalled (the support
-- ticket: tier-1, escalated to tier-2, then recalled on resolution).
run ShowSuccessorRecalled {
    some s : Assignment | recorded[s] and s.status = Recalled and origin[s] in ReassignCall
} for 4 but 5 Assignment, 3 Call

-- ShowSuccessorTransferred: a chain of handoffs, an assignment a [Reassign] recorded and
-- then handed on again (a ward's nurse handed on at each shift change).
run ShowSuccessorTransferred {
    some s : Assignment | recorded[s] and s.status = Transferred and origin[s] in ReassignCall
} for 4 but 5 Assignment, 3 Call

-- ShowRecalledAtItsAssignmentInstant: a recall at the very reading the assignment was
-- recorded at is admitted (the clock may repeat a reading; "MUST NOT PRECEDE" allows
-- equality, Invariant 8.1).
run ShowRecalledAtItsAssignmentInstant {
    some s : Assignment | recorded[s] and s.status = Recalled and s.recalledAt = s.assignedAt
} for 4 but 5 Assignment, 3 Call

-- ShowTransferredAtItsAssignmentInstant: likewise a handoff at the reading the assignment
-- was recorded at (Invariant 8.2).
run ShowTransferredAtItsAssignmentInstant {
    some s : Assignment | recorded[s] and s.status = Transferred and s.transferredAt = s.assignedAt
} for 4 but 5 Assignment, 3 Call

-- ShowReassignedToTheSameActor: a [Reassign] naming the actor who already holds the task is
-- admitted: only a blank new assignee reference is refused (Operation 17).
run ShowReassignedToTheSameActor {
    some s : Assignment | recorded[s] and some s.handedFrom and s.assignee = s.handedFrom.assignee
} for 4 but 5 Assignment, 3 Call

-- ShowOneActorTwoTasks: one actor holds two tasks at once: the atom caps no assignee's
-- active assignments (Non-goal 9).
run ShowOneActorTwoTasks {
    some s1, s2 : Assignment | recorded[s1] and recorded[s2] and origin[s1] != origin[s2]
        and s1.status = Active and s2.status = Active
        and s1.assignee = s2.assignee and s1.task != s2.task
} for 4 but 5 Assignment, 3 Call

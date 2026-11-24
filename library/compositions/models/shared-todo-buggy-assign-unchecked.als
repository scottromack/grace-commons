-- shared-todo-buggy-assign-unchecked.als
-- DELIBERATELY WRONG twin of shared-todo.als (unit: compositions/shared-todo.md formal layer).
--
-- INJECTED DEFECT: [Assign Task] calls Assignment's assign without the existence check, for a task id
-- the Personal Todo instance does not carry too (Action wiring 13, 14).
--
-- BREAKS: A_Invariant_3_2.
-- Everything else is shared-todo.als as written; read its comments there.

module shared_todo_buggy_assign_unchecked

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Ref: an opaque reference — an actor reference a call carries (Term actor reference) or an
-- assignee reference an assignment binds (Term assignee reference). Never interpreted.
sig Ref {}

-- TaskId: the Personal Todo id a call names a task by (Term task id).
sig TaskId {}

-- Scope: an action scope Permissions checks. The composition's vocabulary (Term action
-- scopes) is seven fixed scopes; a deployment may add finer ones (Scope vocabulary 10).
abstract sig Scope {}
abstract sig Vocab extends Scope {}
one sig TasksView, TasksAdd, TasksEdit, TasksComplete, TasksDelete, TasksAssign,
    TasksRecall extends Vocab {}

-- Finer: a finer action scope a deployment defines (Scope vocabulary 10). It names the
-- vocabulary scope it refines and the actions it gates in addition to that scope (Scope
-- vocabulary 11).
sig Finer extends Scope {
    refines : one Vocab,
    gates   : set Action
}

-- Action: the composition's actions (Action wiring signatures). The seven writing actions
-- and the [Responsible Actor] read.
abstract sig Action {}
one sig AddTask, EditTask, CompleteTask, DeleteTask, AssignTask, ReassignTask,
    RecallAssignment, ResponsibleActor extends Action {}

-- Constituent: whom a call can reach beyond the gate — the three constituents (Composes 1
-- to 3). Permissions is reached beyond the gate only by a call other than permitted.
abstract sig Constituent {}
one sig PersonalTodo, Permissions, Assignments extends Constituent {}

-- Assignment: one assignment record of the Assignment instance: the task id it names and
-- the assignee reference it binds. Whether it stands active is read per call.
sig Assignment {
    task     : one TaskId,
    assignee : one Ref
}

-- Answer: the answers of [Responsible Actor] beside an assignee reference.
abstract sig Answer {}
one sig NotKnown, Unassigned, PermissionDenied extends Answer {}

-- Call: one call of a composition action and what its transaction reads and writes.
--   actor       the actor reference the call carries (Action wiring 4).
--   granted     the scopes for which Permissions' permitted answers permitted for that
--               reference when the call reads it — Permissions' answer, taken as given.
--   checked     the scopes the composition asked Permissions' permitted about (the gate).
--   reached     the constituents the call called beyond the gate's permitted calls.
--   wrote       the constituents whose records the call changed (its commit).
--   carried     the task ids the Personal Todo instance carries as the call reads it.
--   active      the assignments the Assignment instance holds active as the call reads it.
--   recalled    the assignments the call had Assignment recall.
--   transferred the assignment the call had Assignment stand transferred ([Reassign Task]).
--   recorded    the assignments Assignment recorded active for the call.
--   removed     the task id the call had Personal Todo delete.
--   added       the task id Personal Todo's add answered the call.
--   task, named, assigneeIn  the call's inputs: a task id, an assignment id, an assignee
--               reference (or new assignee reference).
--   answer      what a read answered.
abstract sig Call {
    actor       : one Ref,
    granted     : set Scope,
    checked     : set Scope,
    reached     : set Constituent,
    wrote       : set Constituent,
    carried     : set TaskId,
    active      : set Assignment,
    recalled    : set Assignment,
    transferred : set Assignment,
    recorded    : set Assignment,
    removed     : set TaskId,
    added       : set TaskId,
    task        : lone TaskId,
    named       : lone Assignment,
    assigneeIn  : lone Ref,
    answer      : lone (Ref + Answer)
}

-- One sig per action: add_task, edit_task, complete_task, delete_task, assign_task,
-- reassign_task, recall_assignment and responsible_actor (Action wiring signatures).
sig AddCall, EditCall, CompleteCall, DeleteCall, AssignCall, ReassignCall, RecallCall,
    RespCall extends Call {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Assignment's active_for answers an assignment or none for a task id (Assignment's own
-- signature and its at-most-one-active guarantee, which the composition inherits under
-- Composes 6): no call reads two active assignments for one task id.
fact AssignmentAnswersOneActivePerTask {
    all c : Call, t : TaskId | lone (c.active & task.t)
}

-- An assignment Assignment records for a call is a new one: it was not standing active when
-- the call read the records (Assignment Identity 2: the host allocates a fresh id).
fact RecordedAssignmentsAreNew {
    all c : Call | no c.recorded & c.active
}

-- A deployment's finer scope gates only actions the scope it refines gates (Scope
-- vocabulary 11: the deployment names the scope its finer scope refines). Which of those
-- actions it gates is the deployment's choice: see finding (a).
fact FinerScopesRefineTheirActions {
    all f : Finer | f.gates in vocabOf.(f.refines)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- kindOf: the action each call is a call of.
fun kindOf : Call -> Action {
    AddCall -> AddTask + EditCall -> EditTask + CompleteCall -> CompleteTask
    + DeleteCall -> DeleteTask + AssignCall -> AssignTask + ReassignCall -> ReassignTask
    + RecallCall -> RecallAssignment + RespCall -> ResponsibleActor
}

-- vocabOf: the vocabulary scope each action is gated on (Scope vocabulary 2 to 9).
fun vocabOf : Action -> Vocab {
    ResponsibleActor -> TasksView + AddTask -> TasksAdd + EditTask -> TasksEdit
    + CompleteTask -> TasksComplete + DeleteTask -> TasksDelete + AssignTask -> TasksAssign
    + ReassignTask -> TasksAssign + RecallAssignment -> TasksRecall
}

-- gatedOn: every scope a call's action is gated on: its vocabulary scope and each finer
-- scope the deployment gates the action on (Scope vocabulary 11).
fun gatedOn[c : Call] : set Scope {
    c.kindOf.vocabOf + { f : Finer | c.kindOf in f.gates }
}

-- activeFor: what Assignment's active_for answers the call for a task id.
fun activeFor[c : Call, t : TaskId] : set Assignment {
    c.active & task.t
}

-- activeAfter: the assignments standing active once the call commits: those it read active,
-- less those it had recalled or transferred, with those recorded for it.
fun activeAfter[c : Call] : set Assignment {
    (c.active - c.recalled - c.transferred) + c.recorded
}

-- admitted: every scope the gate asked about answered permitted (Action wiring 1, 2).
pred admitted[c : Call] {
    c.checked in c.granted
}

-- quiet: the call changes nothing in Assignment's or Personal Todo's records.
pred quiet[c : Call] {
    no c.recalled
    no c.transferred
    no c.recorded
    no c.removed
    no c.added
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The composition's wiring: the gate, then each action's constituent calls
-- ─────────────────────────────────────────────────────────────────────────────

-- asks: the scopes the gate asks Permissions' permitted about, with the call's actor
-- reference (Action wiring 4): the action's vocabulary scope and each finer scope the
-- deployment gates it on.
pred asks[c : Call] {
    c in RespCall     implies c.checked & Vocab = TasksView       -- Scope vocabulary 2
    c in AddCall      implies c.checked & Vocab = TasksAdd        -- Scope vocabulary 3
    c in EditCall     implies c.checked & Vocab = TasksEdit       -- Scope vocabulary 4
    c in CompleteCall implies c.checked & Vocab = TasksComplete   -- Scope vocabulary 5
    c in DeleteCall   implies c.checked & Vocab = TasksDelete     -- Scope vocabulary 6
    c in AssignCall   implies c.checked & Vocab = TasksAssign     -- Scope vocabulary 7
    c in ReassignCall implies c.checked & Vocab = TasksAssign     -- Scope vocabulary 8
    c in RecallCall   implies c.checked & Vocab = TasksRecall     -- Scope vocabulary 9
    c.checked & Finer = { f : Finer | c.kindOf in f.gates }       -- Scope vocabulary 11
}

-- refused: a denied answer stops the call at the gate: no constituent is called, nothing is
-- written, and a read answers permission-denied (Action wiring 2, 3).
pred refused[c : Call] {
    no c.reached
    no c.wrote
    quiet[c]
    c in RespCall implies c.answer = PermissionDenied
    c not in RespCall implies no c.answer
}

-- addWired: an admitted add calls Personal Todo's add with the description (Action wiring
-- 5); Personal Todo answers a fresh id (its Identity 2), or refuses and writes nothing.
pred addWired[c : AddCall] {
    c.reached = PersonalTodo
    no c.recalled + c.transferred + c.recorded + c.removed
    (c.wrote = PersonalTodo and one c.added and no c.added & c.carried)
        or (no c.wrote and no c.added)
    no c.answer
}

-- editWired: an admitted edit calls Personal Todo's edit with the task id and the new
-- description (Action wiring 6); Personal Todo writes the unit or refuses.
pred editWired[c : EditCall] {
    c.reached = PersonalTodo
    quiet[c]
    c.wrote in PersonalTodo
    no c.answer
}

-- completeWired: an admitted complete calls Personal Todo's complete with the task id
-- (Action wiring 7) and recalls nothing (Action wiring 8).
pred completeWired[c : CompleteCall] {
    c.reached = PersonalTodo
    quiet[c]
    c.wrote in PersonalTodo
    no c.answer
}

-- deleteWired: an admitted delete calls active_for with the task id and recalls the
-- assignment it answers, if any, then calls Personal Todo's delete (Action wiring 9, 10,
-- 10a). Personal Todo answers not-known for a task id it does not carry, and then nothing
-- the delete wrote commits (Action wiring 18; Execution Contract Database 1).
pred deleteWired[c : DeleteCall] {
    some c.task
    c.reached = Assignments + PersonalTodo
    no c.transferred + c.recorded + c.added
    c.task in c.carried implies {
        c.recalled = activeFor[c, c.task]
        c.removed  = c.task
        c.wrote    = PersonalTodo + (some c.recalled implies Assignments else none)
    } else {
        no c.recalled
        no c.removed
        no c.wrote
    }
    no c.answer
}

-- assignWired: an admitted assign reads Personal Todo for the task id and answers not-known
-- if it is not carried; only then calls Assignment's assign with the task id and assignee
-- reference (Action wiring 13, 14, 26). Assignment refuses a blank assignee reference
-- (invalid-request) and a task id it holds active (already-assigned), writing nothing.
pred assignWired[c : AssignCall] {
    some c.task
    no c.recalled + c.transferred + c.removed + c.added
    no c.answer
    (c.task in c.carried or c.task not in c.carried) implies {  -- BUG: Action wiring 13 is gone
        c.reached = PersonalTodo + Assignments
        (some c.assigneeIn and no activeFor[c, c.task]) implies {
            one c.recorded
            c.recorded.task = c.task
            c.recorded.assignee = c.assigneeIn
            c.wrote = Assignments
        } else {
            no c.recorded
            no c.wrote
        }
    } else {
        c.reached = PersonalTodo
        no c.recorded
        no c.wrote
    }
}

-- reassignWired: an admitted reassign calls Assignment's reassign with the assignment id and
-- the new assignee reference (Action wiring 16). Assignment stands the named assignment
-- transferred and records a new active one for its task, naming the new assignee (Assignment
-- Operation 18, 19, 38), or refuses (not-active, invalid-request) and writes nothing.
pred reassignWired[c : ReassignCall] {
    some c.named
    c.reached = Assignments
    no c.recalled + c.removed + c.added
    no c.answer
    (c.named in c.active and some c.assigneeIn) implies {
        c.transferred = c.named
        one c.recorded
        c.recorded.task = c.named.task
        c.recorded.assignee = c.assigneeIn
        c.wrote = Assignments
    } else {
        no c.transferred
        no c.recorded
        no c.wrote
    }
}

-- recallWired: an admitted recall calls Assignment's recall with the assignment id (Action
-- wiring 17). Assignment recalls it if it stands active, or refuses and writes nothing.
pred recallWired[c : RecallCall] {
    some c.named
    c.reached = Assignments
    no c.transferred + c.recorded + c.removed + c.added
    no c.answer
    c.named in c.active implies {
        c.recalled = c.named
        c.wrote = Assignments
    } else {
        no c.recalled
        no c.wrote
    }
}

-- respWired: an admitted [Responsible Actor] reads Personal Todo for the task id and answers
-- not-known if it is not carried (Action wiring 20, 26); otherwise calls active_for and
-- answers the assignee reference of the assignment it answers, or unassigned for none
-- (Composition state 2, Action wiring 21). A read writes nothing.
pred respWired[c : RespCall] {
    some c.task
    quiet[c]
    no c.wrote
    c.task in c.carried implies {
        c.reached = PersonalTodo + Assignments
        some activeFor[c, c.task] implies c.answer = activeFor[c, c.task].assignee
            else c.answer = Unassigned
    } else {
        c.reached = PersonalTodo
        c.answer = NotKnown
    }
}

-- wired: the call is what the composition's wiring makes of it: the gate first, and only on
-- its permitted answers the action's constituent calls.
pred wired[c : Call] {
    asks[c]
    not admitted[c] implies refused[c]
    admitted[c] implies {
        c in AddCall      implies addWired[c]
        c in EditCall     implies editWired[c]
        c in CompleteCall implies completeWired[c]
        c in DeleteCall   implies deleteWired[c]
        c in AssignCall   implies assignWired[c]
        c in ReassignCall implies reassignWired[c]
        c in RecallCall   implies recallWired[c]
        c in RespCall     implies respWired[c]
    }
}

-- composed: every call in the instance is a call the composition's wiring makes.
pred composed {
    all c : Call | wired[c]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any call the composition can make, over any records it can
-- read, that violates this assertion? No counterexample (UNSAT) = the guarantee holds.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every call that changes a constituent's records follows a permitted
-- answer for every scope its action is gated on — the vocabulary's scope and every finer
-- scope the deployment gates the action on. (A delete's cascade recall is the delete's own
-- call, gated on tasks:delete, not tasks:recall.)
assert A_Invariant_1_1 {
    composed implies all c : Call | some c.wrote implies gatedOn[c] in c.checked & c.granted
}
check A_Invariant_1_1 for 3 but 3 Call, 9 Scope

-- A_Invariant_1_2: a call any of whose scopes Permissions answered denied reaches no
-- constituent beyond the gate: no Personal Todo read or write, no Assignment call, no other
-- Permissions call.
assert A_Invariant_1_2 {
    composed implies all c : Call | some c.checked - c.granted implies no c.reached
}
check A_Invariant_1_2 for 3 but 3 Call, 9 Scope

-- A_Invariant_3_1: a delete that takes a task out of the Personal Todo instance leaves no
-- assignment active for it: the one active_for answered is recalled in the same commit.
assert A_Invariant_3_1 {
    composed implies all c : DeleteCall | some c.removed implies no activeAfter[c] & task.(c.removed)
}
check A_Invariant_3_1 for 3 but 3 Call, 9 Scope

-- A_Invariant_3_2: no call leaves an active assignment naming a task id the Personal Todo
-- instance does not carry: none it leaves active names a task id it took out, and every
-- assignment recorded for it names a task id the instance carried as the call read it, or
-- one an assignment it read active already named (a reassign's successor). Whether that
-- earlier assignment named a carried id is the earlier call's, across calls (the TLA+
-- model's Inv_CascadeOnDelete).
assert A_Invariant_3_2 {
    composed implies all c : Call | {
        no activeAfter[c].task & c.removed
        c.recorded.task in c.carried + c.active.task
    }
}
check A_Invariant_3_2 for 3 but 3 Call, 9 Scope

-- A_Invariant_4_1: [Responsible Actor], admitted, answers by joining Personal Todo's records
-- with Assignment's active_for (Term responsible actor): not-known for a task id the Personal
-- Todo instance does not carry, unassigned for one it carries with no active assignment, and
-- otherwise the assignee reference of the task's active assignment — never the assignee of a
-- recalled or transferred one.
assert A_Invariant_4_1 {
    composed implies all c : RespCall | gatedOn[c] in c.checked & c.granted implies {
        c.task not in c.carried implies c.answer = NotKnown
        (c.task in c.carried and no c.active & task.(c.task)) implies c.answer = Unassigned
        (c.task in c.carried and some c.active & task.(c.task))
            implies c.answer in (c.active & task.(c.task)).assignee
    }
}
check A_Invariant_4_1 for 3 but 3 Call, 9 Scope

-- A_Invariant_5_2: a task's delete changes no grant record: no delete writes the Permissions
-- instance's records.
assert A_Invariant_5_2 {
    composed implies all c : DeleteCall | Permissions not in c.wrote
}
check A_Invariant_5_2 for 3 but 3 Call, 9 Scope

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a call the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAdd: an admitted add records a task (Dev Alice's add_task, the sprint board).
run ShowAdd {
    composed and some c : AddCall | some c.added
} for 3 but 3 Call, 9 Scope

-- ShowDeniedDelete: a delete by an actor without tasks:delete answers permission-denied and
-- reaches nothing (Dev Carol's delete_task).
run ShowDeniedDelete {
    composed and some c : DeleteCall | TasksDelete not in c.granted and no c.reached
} for 3 but 3 Call, 9 Scope

-- ShowDeleteCascade: a delete of a task with an active assignment recalls it and takes the
-- task out, by an actor holding tasks:delete but not tasks:recall (the sprint board's
-- manager deleting task_t1 with Bob's a2 active).
run ShowDeleteCascade {
    composed and some c : DeleteCall | some c.recalled and some c.removed
        and TasksRecall not in c.granted
} for 3 but 3 Call, 9 Scope

-- ShowDeleteUnassigned: a delete of a task with no active assignment calls no recall
-- (Action wiring 10a).
run ShowDeleteUnassigned {
    composed and some c : DeleteCall | no c.recalled and some c.removed
} for 3 but 3 Call, 9 Scope

-- ShowAssign: an admitted assign records an active assignment for a carried task.
run ShowAssign {
    composed and some c : AssignCall | some c.recorded
} for 3 but 3 Call, 9 Scope

-- ShowSelfAssign: an actor assigns a task to itself, which the composition does not refuse
-- (Non-goal 3).
run ShowSelfAssign {
    composed and some c : AssignCall | some c.recorded and c.recorded.assignee = c.actor
} for 3 but 3 Call, 9 Scope

-- ShowAssignUnknown: an assign naming a task id the Personal Todo instance does not carry
-- answers not-known and records nothing (Action wiring 13).
run ShowAssignUnknown {
    composed and some c : AssignCall | admitted[c] and c.task not in c.carried and no c.recorded
} for 3 but 3 Call, 9 Scope

-- ShowReassign: a reassign stands the old assignment transferred and records the new one
-- (the manager's handoff from Alice to Bob).
run ShowReassign {
    composed and some c : ReassignCall | some c.transferred and some c.recorded
        and c.recorded.assignee != c.transferred.assignee
} for 3 but 3 Call, 9 Scope

-- ShowRecall: an admitted recall withdraws an active assignment.
run ShowRecall {
    composed and some c : RecallCall | some c.recalled
} for 3 but 3 Call, 9 Scope

-- ShowCompleteKeepsAssignment: a complete of a task with an active assignment leaves it
-- standing (Action wiring 8; Bob's a2 after complete_task).
run ShowCompleteKeepsAssignment {
    composed and some c : CompleteCall | some c.wrote and some activeFor[c, c.task]
        and activeFor[c, c.task] in activeAfter[c]
} for 3 but 3 Call, 9 Scope

-- ShowResponsible: [Responsible Actor] answers the assignee of a task's active assignment.
run ShowResponsible {
    composed and some c : RespCall | c.answer in Ref
} for 3 but 3 Call, 9 Scope

-- ShowUnassigned: [Responsible Actor] answers unassigned for a carried task with no active
-- assignment (Action wiring 21).
run ShowUnassigned {
    composed and some c : RespCall | c.answer = Unassigned
} for 3 but 3 Call, 9 Scope

-- ShowNotKnown: [Responsible Actor] answers not-known for a task id the Personal Todo
-- instance does not carry, a deleted task's included (Action wiring 20).
run ShowNotKnown {
    composed and some c : RespCall | c.answer = NotKnown
} for 3 but 3 Call, 9 Scope

-- ShowFinerScope: a deployment's finer scope refining tasks:assign gates [Reassign Task],
-- and a reassign by an actor holding both commits (Scope vocabulary 10, 11).
run ShowFinerScope {
    composed and some c : ReassignCall, f : Finer | f.refines = TasksAssign
        and ReassignTask in f.gates and some c.wrote
} for 3 but 3 Call, 9 Scope

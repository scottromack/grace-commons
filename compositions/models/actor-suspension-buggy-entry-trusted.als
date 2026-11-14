-- actor-suspension-buggy-entry-trusted.als
-- DELIBERATELY WRONG twin of actor-suspension.als (unit: `compositions/actor-suspension.md formal layer`).
--
-- INJECTED DEFECT: the reader answers the index entry wherever one stands, never the tail read over a later event
-- (Composition state 22, 27 dropped).
--
-- BREAKS: A_Invariant_1_5, A_Invariant_1_6, A_Invariant_1_7, A_Composition_state_22, A_Check_3_2.
-- Everything else is actor-suspension.als as written; read its comments there.

module actor_suspension_buggy_entry_trusted

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Actor: an actor reference, the identity the composition suspends; under the unified
-- actor namespace it is also the subject of the actor's grants and the principal of its
-- sessions and credentials (Capability requirement 12 to 15).
sig Actor {}

-- Principal: a principal a record attests or names — an operator, a resumer, a reinstating
-- actor, or the composition's service identity.
sig Principal {}

-- Service: the composition's service identity (Term service identity), the attested emitter
-- of every record the sweep writes.
one sig Service extends Principal {}

-- Reason: the reason a call carries. Its content is never read here.
sig Reason {}

-- InvId: an invocation id the seam allocates (Identity 1, 2), compared by identity only.
sig InvId {}

-- Member: a grant, a session or a credential, as its constituent records it, held by one
-- actor (the grant's subject, the session's or credential's principal).
abstract sig Member {
    holder : one Actor
}

-- Grant, Session, Credential: the three kinds of member, one per constituent (Permissions,
-- Session, Credential).
sig Grant, Session, Credential extends Member {}

-- Constituents: the constituents' records in this state. live: the members standing
-- stored active (a grant, a session) or effective active (a credential); known: the members
-- the constituent still knows (one it answers not-known for is outside it).
one sig Constituents {
    live  : set Member,
    known : set Member
}

-- CredentialArm: present when the credential arm stands composed (Term credential arm).
lone sig CredentialArm {}

-- Deployment: the deployment's planned set cap (Capability requirement 36).
one sig Deployment {
    cap : one Int
}

-- LState: the actor lifecycle states (Composition state 5).
abstract sig LState {}
one sig Active, Suspending, Suspended extends LState {}

-- Writer: the model's own record of which cascade closed a cascade — the fresh cascade's
-- own call, a resume, or the sweep (Term cascade).
abstract sig Writer {}
one sig Fresh, Resume, Sweep extends Writer {}

-- Event: one record_action this composition made, in the audit trail. inv: the invocation
-- id it carries; actor: the actor it names; attester: the principal whose credential the
-- substrate verified for it; earlier: the model's own, the events the substrate inserted
-- before it.
abstract sig Event {
    inv      : one InvId,
    actor    : one Actor,
    attester : lone Principal,
    earlier  : set Event
}

-- SuspensionIntended: actor.suspension_intended, a fresh cascade's intent, carrying the plan,
-- the operator and the reason (Identity 5, 17; Action wiring 19).
sig SuspensionIntended extends Event {
    plan     : set Member,
    operator : lone Principal,
    reason   : lone Reason
}

-- Follower: an event naming a cascade's intent by its event id (intentRef).
abstract sig Follower extends Event {
    intentRef : lone Event
}

-- ResumeIntended: actor.resume_intended, a resume's intent: the resumer and the open members
-- it will close (Action wiring 60).
sig ResumeIntended extends Follower {
    resumer     : lone Principal,
    openMembers : set Member
}

-- RecoveryIntended: actor.recovery_intended, the sweep's intent (Reconciliation 17, 19).
sig RecoveryIntended extends Follower {}

-- ActorSuspended: actor.suspended, a suspended outcome: the operator it names, the revoked
-- set and the unresolved members (Action wiring 48), the resumer and resume event of a
-- resumed cascade (Action wiring 49); writer is the model's own.
sig ActorSuspended extends Follower {
    namedOperator : lone Principal,
    revoked       : set Member,
    unresolved    : set Member,
    resumedBy     : lone Principal,
    resumeEvent   : lone Event,
    writer        : one Writer
}

-- Recovered: the outcomes carrying the recovery marker (Term recovery marker).
sig Recovered in ActorSuspended {}

-- PlanUnavailable: the outcomes carrying the plan-unavailable marker (Reconciliation 26).
sig PlanUnavailable in ActorSuspended {}

-- ActorReinstated: actor.reinstated, a reinstated outcome (Action wiring 84).
sig ActorReinstated extends Event {}

-- EscalationRecorded: actor.escalation_recorded, the sweep's escalation of an open cascade
-- (Reconciliation 29, 35); neither an intent nor an outcome.
sig EscalationRecorded extends Follower {}

-- Aged: the events whose payload the audit instance has destroyed (Term aged-out event).
sig Aged in Event {}

-- Entry: one suspension-state index entry (Term suspension-state index): the actor it is
-- keyed by, its lifecycle state as a set of state flags (so a write that ADDED a state would
-- show), and what Composition state 6 and 7 and Identity 20 have it carry; backing is the
-- model's own, the landed record the write followed.
sig Entry {
    key               : one Actor,
    state             : set LState,
    entryInv          : lone InvId,
    intentEventId     : lone Event,
    entryOperator     : lone Principal,
    entryReason       : lone Reason,
    suspensionEventId : lone Event,
    backing           : one Event
}

-- Mark: the high-water mark, the last log event the sweep has reconciled through; none is
-- the log's first position (Term high-water mark).
one sig Mark {
    through : lone Event
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The substrate inserts the events in one total order, the authoritative order (Clock
-- semantics 6; Audit Trail's log).
fact InsertionOrder {
    all e : Event | e not in e.earlier
    all e : Event | e.earlier.earlier in e.earlier
    all disj x, y : Event | x in y.earlier or y in x.earlier
}

-- The audit instance destroys the oldest payloads first: an event older than an aged-out
-- one is aged out too (Term audit horizon; Audit Trail's retention policy).
fact AgedOutOldestFirst {
    all e : Aged | e.earlier in Aged
}

-- A member a constituent no longer knows has no status in its records, so it stands
-- neither stored active nor effective active.
fact UnknownIsNotLive {
    Constituents.live in Constituents.known
}

-- The host allocates an invocation id to one invocation only (Capability requirement 2,
-- Identity 2), and every suspension intent is a fresh cascade's own invocation: the model
-- offers no writer that records a second one (Identity 13, 14).
fact HostAllocatesOnce {
    all disj s1, s2 : SuspensionIntended | s1.inv != s2.inv
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- Lifecycle: the events that bear a lifecycle state (Composition state 33 through 35); a
-- resume intent, a recovery intent and an escalation record bear none (36, 37, 56).
fun Lifecycle : set Event {
    SuspensionIntended + ActorSuspended + ActorReinstated
}

-- eventsOf: an actor's lifecycle-bearing events.
fun eventsOf[a : Actor] : set Event {
    actor.a & Lifecycle
}

-- latest: the last of some events in the log's order.
fun latest[s : set Event] : set Event {
    { e : s | no x : s | e in x.earlier }
}

-- above: the events above the high-water mark (all of them when the mark stands at the
-- log's first position).
fun above : set Event {
    { e : Event | Mark.through in e.earlier }
}

-- cascadeIntent: the suspension intent carrying an event's invocation id (Identity 10).
fun cascadeIntent[f : Event] : set SuspensionIntended {
    SuspensionIntended & inv.(f.inv)
}

-- isOpen: an open cascade — an intent no outcome carries the invocation id of (Term open
-- cascade).
pred isOpen[s : Event] {
    no o : ActorSuspended | o.inv = s.inv
}

-- stateOn: the model's own reading of an actor's state over some events — its latest
-- lifecycle-bearing event's: an intent is suspending, a suspended outcome suspended, a
-- reinstatement active, and no event active. The truth the composition's readings are
-- held to.
fun stateOn[a : Actor, upto : set Event] : one LState {
    let l = latest[eventsOf[a] & upto] |
        (some l and l in SuspensionIntended) => Suspending
        else ((some l and l in ActorSuspended) => Suspended else Active)
}

-- paired: an outcome closes an intent when it carries the intent's invocation id (Identity
-- 10), never by a resemblance or by the actor (Identity 11, 12).
pred paired[o : ActorSuspended, s : Event] {
    o.inv = s.inv
}

-- readLife: the composition's reading of one lifecycle-bearing event (Composition state 33
-- through 35, 54): an intent carrying no outcome under its invocation id is suspending, a
-- suspended outcome suspended, a reinstated outcome active.
fun readLife[e : Event] : set LState {
    e in SuspensionIntended => ((some o : ActorSuspended | paired[o, e]) => Suspended else Suspending)
    else (e in ActorSuspended => Suspended else Active)
}

-- tail: the tail read for an actor — its lifecycle-bearing events above the mark whose
-- payload the audit instance still holds (Term tail read; Composition state 25, 26).
fun tail[a : Actor] : set Event {
    (eventsOf[a] & above) - Aged
}

-- resolved: the state a reader answers for an actor (Composition state 20 through 29, 54):
-- the tail read's latest event where it stands later in the log than the entry's event or
-- the key is absent, the entry's state otherwise, and active for an absent key the tail
-- read finds nothing for.
fun resolved[a : Actor] : set LState {
    let e = key.a, t = latest[tail[a]] |
        some e => e.state                                  -- DEFECT: the entry always answers
        else (some t => readLife[t] else Active)
}

-- rebuilt: the state the rebuild gives an actor (Term rebuild; Composition state 32 through
-- 40): its latest lifecycle-bearing event the audit instance still holds, read as the
-- reader reads it; with none, the entry it already has (additive, dropping nothing).
fun rebuilt[a : Actor] : set LState {
    let r = latest[eventsOf[a] - Aged] |
        some r => readLife[r] else (key.a).state
}

-- rebuiltAnswer: what a reader answers over the rebuilt index: an absent key reads active.
fun rebuiltAnswer[a : Actor] : set LState {
    some rebuilt[a] => rebuilt[a] else Active
}

-- clear: no lifecycle-bearing event of the actor stands aged out above the mark (see FOUND).
pred clear[a : Actor] {
    no (eventsOf[a] & above & Aged)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be, over the log before it
-- ─────────────────────────────────────────────────────────────────────────────

-- intentWrites: a fresh cascade's intent — opened only on an active actor (Action wiring 9,
-- Wiring decision 6), its plan the actor's own members (Action wiring 10 to 12, credentials
-- only under the credential arm), sized against the cap before it lands (Primitive policy
-- 17 to 19), attested under the operator's credential (Audit arm 2, Composes 25).
pred intentWrites[s : SuspensionIntended] {
    stateOn[s.actor, s.earlier] = Active                   -- Action wiring 9
    s.plan.holder in s.actor                               -- Action wiring 10 to 12
    no CredentialArm implies no (s.plan & Credential)      -- Action wiring 12
    #s.plan <= Deployment.cap                              -- Primitive policy 19
    some s.operator
    s.attester = s.operator                                -- Audit arm 2, Composes 25
    some s.reason                                          -- Primitive policy 5
}

-- resumeWrites: a resume's intent — on an open cascade of its actor, under the cascade's
-- invocation id (Identity 7, Action wiring 63), attested under the resumer (Composes 26),
-- its open members the plan less the members the constituents show closed (Action wiring 56).
pred resumeWrites[r : ResumeIntended] {
    let s = r.intentRef {
        one s
        s in SuspensionIntended
        s in r.earlier
        s.actor = r.actor
        r.inv = s.inv                                      -- Identity 7
        no o : ActorSuspended & r.earlier | o.inv = s.inv  -- Action wiring 8
        some r.resumer
        r.attester = r.resumer                             -- Composes 26
        r.openMembers.holder in r.actor
        s not in Aged implies r.openMembers in s.plan      -- Action wiring 56
        s not in Aged implies no ((s.plan - r.openMembers) & Constituents.live)
    }
}

-- recoveryWrites: the sweep's intent — on an open cascade its pre-check found no outcome for
-- (Reconciliation 15, 17), under the cascade's invocation id (Identity 9), attested under
-- the service identity (Reconciliation 20, Composes 27).
pred recoveryWrites[v : RecoveryIntended] {
    let s = v.intentRef {
        one s
        s in SuspensionIntended
        s in v.earlier
        s.actor = v.actor
        v.inv = s.inv                                      -- Identity 9
        no o : ActorSuspended & v.earlier | o.inv = s.inv  -- Reconciliation 15, 17
        v.attester = Service                               -- Reconciliation 20
    }
}

-- outcomeWrites: a suspended outcome — it names its intent and the operator (Action wiring
-- 48), is the cascade's only one (the fresh call writes its own once, Audit arm 23; a
-- resume found the actor suspending, Action wiring 8; the sweep's pre-check found none,
-- Reconciliation 15), is attested by and marked for its writer (Action wiring 49 to 51,
-- Reconciliation 20), and names the members as the cascade answered them: every planned
-- member closed or found terminal in the revoked set, every one the constituent no longer
-- knows unresolved, and nothing else (Action wiring 21, 25 to 36, 45; Wiring decision 8;
-- Primitive policy 22); with the intent aged out, the actor's members, marked
-- (Reconciliation 25, 26). A member the cascade counted closed stays closed (the
-- constituents' own invariants; Composes 24, Action wiring 38).
pred outcomeWrites[o : ActorSuspended] {
    let s = cascadeIntent[o] {
        one s
        s in o.earlier
        o.actor = s.actor
        o.intentRef = s                                    -- Action wiring 48
        no x : ActorSuspended & o.earlier | x.inv = o.inv  -- one closer
        o.namedOperator = s.operator                       -- Action wiring 48, Reconciliation 22
        o.writer = Fresh implies {
            o.attester = s.attester
            o not in Recovered                             -- Action wiring 51
            no o.resumedBy
            no o.resumeEvent
        }
        o.writer = Resume implies {
            some r : ResumeIntended & o.earlier {          -- Action wiring 58, 59
                r.inv = o.inv
                o.resumeEvent = r                          -- Action wiring 49
                o.resumedBy = r.resumer
                o.attester = r.resumer                     -- Action wiring 62
            }
            o in Recovered                                 -- Action wiring 49
        }
        o.writer = Sweep implies {
            some v : RecoveryIntended & o.earlier | v.inv = o.inv   -- Reconciliation 17, 18
            o.attester = Service                           -- Reconciliation 20
            o in Recovered                                 -- Action wiring 50
            no o.resumedBy
            no o.resumeEvent
        }
        o in PlanUnavailable implies (s in Aged and o.writer != Fresh)   -- Reconciliation 25, 26
        no (o.revoked & Constituents.live)                 -- Action wiring 25 to 30
        o.unresolved in Member - Constituents.known        -- Action wiring 34
        o not in PlanUnavailable implies {
            o.revoked in s.plan                            -- Action wiring 21
            o.unresolved in s.plan
            (s.plan & Constituents.known) in o.revoked     -- Action wiring 25 to 31, 45
            (s.plan - Constituents.known) in o.unresolved  -- Action wiring 34
        }
        o in PlanUnavailable implies {
            o.revoked.holder in o.actor                    -- Reconciliation 25
            o.unresolved.holder in o.actor
        }
    }
}

-- reinstateWrites: a reinstated outcome — only for a suspended actor (Action wiring 80 to
-- 83), attested under the reinstating actor's credential (Invariant 5.6).
pred reinstateWrites[n : ActorReinstated] {
    stateOn[n.actor, n.earlier] = Suspended
    some n.attester
}

-- escalationWrites: the sweep's escalation record — on an open cascade (Reconciliation 29),
-- carrying the cascade's invocation id, intent event id and actor (Reconciliation 35), once
-- per invocation id (Reconciliation 33), attested under the service identity
-- (Reconciliation 20).
pred escalationWrites[x : EscalationRecorded] {
    let s = x.intentRef {
        one s
        s in SuspensionIntended
        s in x.earlier
        s.actor = x.actor
        x.inv = s.inv                                      -- Reconciliation 35
        no o : ActorSuspended & x.earlier | o.inv = s.inv  -- Reconciliation 29
        no y : EscalationRecorded & x.earlier | y.inv = x.inv   -- Reconciliation 33
        x.attester = Service                               -- Reconciliation 20
    }
}

-- entryWrites: an index entry, written only after its landed record and from it
-- (Composition state 41; Action wiring 20, 52, 85): a suspending entry from an intent
-- (Composition state 6), a suspended entry from an outcome (Composition state 7), an active
-- entry from a reinstatement; each carries the record's invocation id (Identity 20).
pred entryWrites[e : Entry] {
    let b = e.backing {
        b in Lifecycle
        b.actor = e.key
        e.entryInv = b.inv                                 -- Identity 20
        b in SuspensionIntended implies {
            e.state = Suspending
            e.intentEventId = b                            -- Composition state 6
            e.entryOperator = b.operator
            e.entryReason = b.reason
            no e.suspensionEventId
        }
        b in ActorSuspended implies {
            e.state = Suspended
            e.suspensionEventId = b                        -- Composition state 7
            e.intentEventId = b.intentRef
            e.entryOperator = b.namedOperator
            e.entryReason = b.intentRef.reason
        }
        b in ActorReinstated implies {
            e.state = Active
            no e.intentEventId
            no e.suspensionEventId
            no e.entryOperator
            no e.entryReason
        }
    }
}

-- indexAsLeft: the index as its writers and the sweep leave it: one entry per actor, each
-- from its record, and every lifecycle event at or below the mark indexed — its actor's
-- entry standing on it or on a later event (Term high-water mark; Reconciliation 4, 6, 7;
-- Composition state 55).
pred indexAsLeft {
    all e : Entry | entryWrites[e]
    all a : Actor | lone key.a
    all a : Actor | let l = latest[eventsOf[a] - above] |
        some l implies (some e : key.a | e.backing = l or l in e.backing.earlier)
}

-- conforms: every record in the state is one its writer's rules let it write.
pred conforms {
    all s : SuspensionIntended | intentWrites[s]
    all r : ResumeIntended | resumeWrites[r]
    all v : RecoveryIntended | recoveryWrites[v]
    all o : ActorSuspended | outcomeWrites[o]
    all n : ActorReinstated | reinstateWrites[n]
    all x : EscalationRecorded | escalationWrites[x]
    indexAsLeft
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Primitive_policy_19: no intent carries a plan with more members than the planned set cap.
assert A_Primitive_policy_19 {
    conforms implies all s : SuspensionIntended | #s.plan <= Deployment.cap
}
check A_Primitive_policy_19 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_1: a suspended actor holds no stored-active grant from its cascade's plan.
assert A_Invariant_1_1 {
    conforms implies all a : Actor | stateOn[a, Event] = Suspended implies
        (let o = latest[eventsOf[a]] | o not in PlanUnavailable implies
            no (cascadeIntent[o].plan & Grant & Constituents.live))
}
check A_Invariant_1_1 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_2: a suspended actor holds no stored-active session from its cascade's plan.
assert A_Invariant_1_2 {
    conforms implies all a : Actor | stateOn[a, Event] = Suspended implies
        (let o = latest[eventsOf[a]] | o not in PlanUnavailable implies
            no (cascadeIntent[o].plan & Session & Constituents.live))
}
check A_Invariant_1_2 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_3: where the credential arm stands composed, a suspended actor holds no
-- effective-active credential from its cascade's plan.
assert A_Invariant_1_3 {
    conforms implies (some CredentialArm implies all a : Actor | stateOn[a, Event] = Suspended implies
        (let o = latest[eventsOf[a]] | o not in PlanUnavailable implies
            no (cascadeIntent[o].plan & Credential & Constituents.live)))
}
check A_Invariant_1_3 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_5: an actor whose cascade stands open reads suspending.
assert A_Invariant_1_5 {
    conforms implies all s : SuspensionIntended | (isOpen[s] and clear[s.actor])
        implies resolved[s.actor] = Suspending
}
check A_Invariant_1_5 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_6: an actor whose cascade stands open does not read active.
assert A_Invariant_1_6 {
    conforms implies all s : SuspensionIntended | (isOpen[s] and clear[s.actor])
        implies Active not in resolved[s.actor]
}
check A_Invariant_1_6 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_7: an actor whose cascade stands open does not read suspended.
assert A_Invariant_1_7 {
    conforms implies all s : SuspensionIntended | (isOpen[s] and clear[s.actor])
        implies Suspended not in resolved[s.actor]
}
check A_Invariant_1_7 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_1_10: one writer closes one cascade — no two suspended outcomes carry one
-- invocation id (Identity 15; Check 6.2, 6.3).
assert A_Invariant_1_10 {
    conforms implies all disj o1, o2 : ActorSuspended | o1.inv != o2.inv
}
check A_Invariant_1_10 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_2: an outcome names every planned grant the constituent still knows in its
-- revoked set, closed by the cascade or found already terminal (Check 2.8).
assert A_Invariant_2_2 {
    conforms implies all o : ActorSuspended | o not in PlanUnavailable implies
        (cascadeIntent[o].plan & Grant & Constituents.known) in o.revoked
}
check A_Invariant_2_2 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_3: an outcome names every planned session the constituent still knows.
assert A_Invariant_2_3 {
    conforms implies all o : ActorSuspended | o not in PlanUnavailable implies
        (cascadeIntent[o].plan & Session & Constituents.known) in o.revoked
}
check A_Invariant_2_3 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_4: where the credential arm stands composed, an outcome names every planned
-- credential the constituent still knows.
assert A_Invariant_2_4 {
    conforms implies (some CredentialArm implies all o : ActorSuspended | o not in PlanUnavailable
        implies (cascadeIntent[o].plan & Credential & Constituents.known) in o.revoked)
}
check A_Invariant_2_4 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_5: an outcome names every planned member the constituent no longer knows as
-- unresolved (Check 2.5).
assert A_Invariant_2_5 {
    conforms implies all o : ActorSuspended | o not in PlanUnavailable implies
        (cascadeIntent[o].plan - Constituents.known) in o.unresolved
}
check A_Invariant_2_5 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_7: an outcome names its intent — the suspension intent carrying its
-- invocation id, earlier in the log (Check 2.3).
assert A_Invariant_2_7 {
    conforms implies all o : ActorSuspended {
        one o.intentRef
        o.intentRef in SuspensionIntended
        o.intentRef.inv = o.inv
        o.intentRef in o.earlier
    }
}
check A_Invariant_2_7 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_8: every planned member stands accounted — in the revoked set, in the
-- unresolved members, or terminal in its constituent's records (Check 2.4, 2.6).
assert A_Invariant_2_8 {
    conforms implies all o : ActorSuspended | o not in PlanUnavailable implies
        cascadeIntent[o].plan in o.revoked + o.unresolved + (Constituents.known - Constituents.live)
}
check A_Invariant_2_8 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_2_9: every revoked set member stands in the plan (Check 2.7).
assert A_Invariant_2_9 {
    conforms implies all o : ActorSuspended | o not in PlanUnavailable implies
        o.revoked in cascadeIntent[o].plan
}
check A_Invariant_2_9 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_5_4: a resumed outcome names its resumer and follows a resume intent attested
-- under that resumer under the cascade's invocation id (Check 4.4).
assert A_Invariant_5_4 {
    conforms implies all o : ActorSuspended | o.writer = Resume implies {
        some o.resumedBy
        some r : ResumeIntended & o.earlier | r.inv = o.inv and r.attester = o.resumedBy
    }
}
check A_Invariant_5_4 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Invariant_5_5: a swept outcome follows a recovery intent attested under the service
-- identity under the cascade's invocation id (Check 4.5).
assert A_Invariant_5_5 {
    conforms implies all o : ActorSuspended | o.writer = Sweep implies
        (some v : RecoveryIntended & o.earlier | v.inv = o.inv and v.attester = Service)
}
check A_Invariant_5_5 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Reconciliation_22: an outcome names as its operator the actor its intent was attested
-- under, whichever writer closed it (Check 4.2).
assert A_Reconciliation_22 {
    conforms implies all o : ActorSuspended {
        some o.namedOperator
        o.namedOperator = cascadeIntent[o].attester
    }
}
check A_Reconciliation_22 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Reconciliation_33: no two escalation records carry one invocation id.
assert A_Reconciliation_33 {
    conforms implies all disj x, y : EscalationRecorded | x.inv != y.inv
}
check A_Reconciliation_33 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Action_wiring_50: a swept outcome carries the recovery marker, so a reader tells a
-- completed act from a clean one.
assert A_Action_wiring_50 {
    conforms implies all o : ActorSuspended | o.writer = Sweep implies o in Recovered
}
check A_Action_wiring_50 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_5: every index entry carries exactly one lifecycle state.
assert A_Composition_state_5 {
    conforms implies all e : Entry | one e.state
}
check A_Composition_state_5 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_6: a suspending entry carries the cascade's invocation id, its intent
-- event id, the operator and the reason.
assert A_Composition_state_6 {
    conforms implies all e : Entry | Suspending in e.state implies {
        one e.entryInv
        one e.intentEventId
        e.intentEventId in SuspensionIntended
        e.intentEventId.inv = e.entryInv
        some e.entryOperator
        some e.entryReason
    }
}
check A_Composition_state_6 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_7: a suspended entry carries its outcome's event id as suspension
-- event id.
assert A_Composition_state_7 {
    conforms implies all e : Entry | Suspended in e.state implies {
        one e.suspensionEventId
        e.suspensionEventId in ActorSuspended
        e.suspensionEventId.actor = e.key
    }
}
check A_Composition_state_7 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_21: an absent key does not read active for an actor the trail holds
-- suspending or suspended (the issuance gate's reading, Capability requirement 40 to 42).
assert A_Composition_state_21 {
    conforms implies all a : Actor | (clear[a] and no key.a and stateOn[a, Event] != Active)
        implies Active not in resolved[a]
}
check A_Composition_state_21 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_22: an entry a later event above the mark contradicts is not the
-- answer: the reader answers the trail's state (Composition state 23, 27).
assert A_Composition_state_22 {
    conforms implies all a : Actor | (some key.a and some t : tail[a] | (key.a).backing in t.earlier)
        implies resolved[a] = stateOn[a, Event]
}
check A_Composition_state_22 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_29: an absent key with no suspension intent above the mark reads
-- active, and the actor is active.
assert A_Composition_state_29 {
    conforms implies all a : Actor | (clear[a] and no key.a and no (tail[a] & SuspensionIntended))
        implies stateOn[a, Event] = Active
}
check A_Composition_state_29 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_32: the rebuild, over the open-ended sequence range, gives every actor
-- whose latest lifecycle event the audit instance still holds its state in the trail: an
-- open intent suspending, a suspended outcome suspended, a later reinstatement active
-- (Composition state 33 through 35).
assert A_Composition_state_32 {
    conforms implies all a : Actor | (let l = latest[eventsOf[a]] |
        (some l and l not in Aged) implies rebuiltAnswer[a] = stateOn[a, Event])
}
check A_Composition_state_32 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_33: the rebuild reads an actor whose latest readable lifecycle event is
-- a suspension intent as suspending — the intent carries no outcome under its invocation id.
assert A_Composition_state_33 {
    conforms implies all a : Actor | (let r = latest[eventsOf[a] - Aged] |
        (some r and r in SuspensionIntended) implies rebuilt[a] = Suspending)
}
check A_Composition_state_33 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Composition_state_44: no actor carries two open cascades (Wiring decision 7).
assert A_Composition_state_44 {
    conforms implies all a : Actor | lone { s : SuspensionIntended | s.actor = a and isOpen[s] }
}
check A_Composition_state_44 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- A_Check_3_2: the rebuild agrees with the index as a reader reads it, for every actor —
-- aged-out actors included, whose state the rebuild keeps from the index (Check 1.6).
assert A_Check_3_2 {
    conforms implies all a : Actor | rebuiltAnswer[a] = resolved[a]
}
check A_Check_3_2 for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowCleanSuspension: the offboarding walkthrough — a fresh cascade over a grant, a session
-- and a credential under the credential arm, closed in one act, its actor indexed suspended.
run ShowCleanSuspension {
    conforms
    some o : ActorSuspended {
        o.writer = Fresh
        some CredentialArm
        some (cascadeIntent[o].plan & Grant)
        some (cascadeIntent[o].plan & Session)
        some (cascadeIntent[o].plan & Credential)
        some e : key.(o.actor) | e.state = Suspended
    }
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowStoppedCascade: an intent landed and its outcome owed — the actor indexed suspending.
run ShowStoppedCascade {
    conforms
    some s : SuspensionIntended | isOpen[s] and some s.plan
        and (some e : key.(s.actor) | e.state = Suspending)
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowResumedCascade: the compromised account — a cascade stopped at its outcome and
-- completed by a resume under another operator.
run ShowResumedCascade {
    conforms
    some o : ActorSuspended | o.writer = Resume and o.resumedBy != o.namedOperator
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowSweptCascade: a stopped cascade the sweep completed under the service identity.
run ShowSweptCascade {
    conforms
    some o : ActorSuspended | o.writer = Sweep
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowUnresolvedMember: a planned member the constituent no longer knows, named unresolved,
-- and the actor suspended.
run ShowUnresolvedMember {
    conforms
    some o : ActorSuspended | some o.unresolved and stateOn[o.actor, Event] = Suspended
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowPlanUnavailable: a cascade whose intent aged out, completed from the actor's members
-- and marked (Reconciliation 25, 26).
run ShowPlanUnavailable {
    conforms
    some o : ActorSuspended | o in PlanUnavailable and some o.revoked
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowEmptyPlan: a suspension of an actor holding nothing — an empty snapshot is a valid
-- plan (Action wiring 18).
run ShowEmptyPlan {
    conforms
    some o : ActorSuspended | no cascadeIntent[o].plan
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowSecondCascade: an actor suspended, reinstated and suspended again.
run ShowSecondCascade {
    conforms
    some disj s1, s2 : SuspensionIntended | s1.actor = s2.actor and some ActorReinstated
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowMissResolvedByTail: an absent key resolved by the tail read to suspended.
run ShowMissResolvedByTail {
    conforms
    some a : Actor | no key.a and resolved[a] = Suspended
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowAgedOutActor: an actor every one of whose lifecycle events aged out, its state taken
-- from the index (Check 1.6, Composition state 10).
run ShowAgedOutActor {
    conforms
    some a : Actor | some eventsOf[a] and eventsOf[a] in Aged and resolved[a] = Suspended
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowEscalatedCascade: an open cascade the sweep escalated (an escalated finding).
run ShowEscalatedCascade {
    conforms
    some x : EscalationRecorded | isOpen[x.intentRef]
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

-- ShowAgedAboveTheMark: the shape FOUND names — an actor suspended in the trail, its events
-- aged out above the mark and never indexed, reading active.
run ShowAgedAboveTheMark {
    conforms
    some a : Actor | not clear[a] and stateOn[a, Event] != Active and resolved[a] = Active
} for 3 but 4 Int, 2 Actor, 5 Event, 2 Entry

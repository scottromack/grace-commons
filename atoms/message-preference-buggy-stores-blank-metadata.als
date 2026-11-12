-- message-preference-buggy-stores-blank-metadata.als
-- DELIBERATELY WRONG twin of message-preference.als (unit: atoms/message-preference.md formal layer).
--
-- INJECTED DEFECT: [Set] stores blank metadata (State 21).
--
-- BREAKS: A_State_21.
-- Everything else is message-preference.als as written; read its comments there.

module message_preference_buggy_stores_blank_metadata

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: a principal reference a call carries or a record holds. The atom never interprets
-- or normalizes one and matches it exactly (Identity 8 to 10), so it is an uninterpreted
-- token compared by identity.
sig Str {}

-- Blank: the principal references that are blank (empty or whitespace-only), which [Set]
-- refuses (Operation 4). Which tokens these are is the world's, not the atom's, so it is a
-- subset with no rule on it.
sig Blank in Str {}

-- Id: an opaque preference id (Term preference id), allocated by the host at the seam
-- (Identity 2). It means nothing by itself and is compared by identity only.
sig Id {}

-- Name: a channel name, as a declared channel set lists it and a channel preferences map
-- keys it ("email", "sms"). The atom declares no channel name (Non-goal 12).
sig Name {}

-- BlankName: the channel names that are blank; a set carrying one is degenerate (Term
-- degenerate). Which names these are is the world's, so it is a subset with no rule on it.
sig BlankName in Name {}

-- Entry: one place in a declared channel set as the host injects it, naming one channel. A
-- set listing one name at two places repeats it (Term degenerate).
sig Entry {
    name : one Name
}

-- ChannelList: a declared channel set as the host injects it at the seam (Instance 9, 10)
-- and as [Set] stamps it onto a record (Instance 12; Term declared channels).
sig ChannelList {
    entries : set Entry
}

-- ChanMap: a channel preferences map (Term channel preferences). Its per-channel values are
-- opaque and the atom never reads them (Operation 10), so a map is the set of its keys; a
-- map with no keys is the empty map, which is blank (State 4; the tombstone of Operation 6).
sig ChanMap {
    keys : set Name
}

-- Val: an opaque value — a frequency limit, quiet hours, a format or metadata. The atom
-- stores it and never interprets it (Operation 10, 11).
sig Val {}

-- BlankVal: the opaque values that are blank. Which values these are is the world's, so it
-- is a subset with no rule on it.
sig BlankVal in Val {}

-- Status: the three statuses (Term status): in force, paused, retired and terminal.
abstract sig Status {}
one sig Active, Suspended, Deleted extends Status {}

-- Call: one call as it reaches the seam, with the clock reading the host injects for it
-- (Term now, Capability requirement 1).
abstract sig Call {
    now : one Int
}

-- SetCall: one [Set] call, set(principal_ref, optional channel_preferences, optional
-- frequency_limit, optional quiet_hours, optional format, optional metadata), with what the
-- host injects for it: the preference id it allocates (Identity 2, Capability requirement
-- 9) and the declared channel set (Capability requirement 8, Instance 10). An optional input
-- left out is absent. The last field is the model's own: the principal's record in effect
-- the call found, if any (Operation 14).
sig SetCall extends Call {
    allocatedId  : one Id,           -- the preference id the host injects
    injected     : one ChannelList,  -- the declared channel set the host injects
    setPrincipal : lone Str,         -- principal_ref
    chanPrefsIn  : lone ChanMap,     -- channel_preferences, optional
    frequencyIn  : lone Val,         -- frequency_limit, optional
    quietIn      : lone Val,         -- quiet_hours, optional
    formatIn     : lone Val,         -- format, optional
    metadataIn   : lone Val,         -- metadata, optional
    supersedes   : lone PrefRecord   -- the prior record in effect the call found
}

-- SuspendCall: one [Suspend] call, suspend(preference_id).
sig SuspendCall extends Call {
    suspendId : lone Id
}

-- DeleteCall: one [Delete] call, delete(preference_id).
sig DeleteCall extends Call {
    deleteId : lone Id
}

-- CurrentForCall: one [Current For] call, current_for(principal_ref), with the records the
-- database held when it read (cfDb) and the record it answered (none where empty).
sig CurrentForCall extends Call {
    forPrincipal : lone Str,
    cfDb         : set PrefRecord,
    cfAnswer     : lone PrefRecord
}

-- ReadCall: one [Read] call, read(preference_id), with the records the database held when
-- it read (readDb) and the record it answered (none for not-known).
sig ReadCall extends Call {
    readId     : lone Id,
    readDb     : set PrefRecord,
    readAnswer : lone PrefRecord
}

-- PrefRecord: one version of a preference record (Term records), as the call that wrote it
-- left it. Every field the page names may be absent, and the status is a set of status
-- flags, so a write that forgot a field, or ADDED a status instead of replacing one, would
-- show: what the page promises (State 1, State 2, the stamps) is checked, never built into
-- the type. The last two fields are the model's own: which call wrote this version and which
-- version that call found.
sig PrefRecord {
    prefId         : lone Id,           -- preference id (Identity 1)
    principal      : lone Str,          -- principal reference
    declared       : lone ChannelList,  -- declared channels (Instance 12)
    setAt          : lone Int,          -- set instant (State 11)
    status         : set Status,        -- status (State 1)
    chanPrefs      : lone ChanMap,      -- channel preferences
    frequencyLimit : lone Val,          -- frequency limit
    quietHours     : lone Val,          -- quiet hours
    format         : lone Val,          -- format
    metadata       : lone Val,          -- metadata
    suspendedAt    : lone Int,          -- suspension instant (State 6, 7)
    deletedAt      : lone Int,          -- deletion instant (State 8)
    writtenBy      : one Call,          -- the call whose write left this version
    found          : lone PrefRecord    -- the version that call found
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The host supplies an id it allocates to one call only (Execution Contract Logic
-- confinement 16, which the page does not cite): two [Set] calls never carry one preference
-- id. The page leaves the id to the host (Identity 2, Capability requirement 9) and promises
-- no reuse (Identity 4, Instance 2), which rests on this.
fact HostSuppliesEachIdOnce {
    all disj a, b : SetCall | a.allocatedId != b.allocatedId
}

-- The deployment's clock never goes backward (Execution Contract Logic confinement 7, which
-- gives the clock's guarantees to the deployment; the page cites it where it deleted
-- Temporal property 5): a call that finds a version reads a now no earlier than the call
-- that wrote it, which committed before it (Execution Contract Database 2).
fact ClockNeverGoesBackward {
    all v : PrefRecord | some v.found implies v.found.writtenBy.now <= v.writtenBy.now
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- nonBlank: a principal reference is present and not blank. An absent input reads as blank.
pred nonBlank[x : lone Str] {
    some x and x not in Blank
}

-- givenVal: an opaque value is present and not blank (State 3, 4).
pred givenVal[x : lone Val] {
    some x and x not in BlankVal
}

-- givenMap: a channel preferences map is present and not empty: an empty map is blank
-- (State 4; the tombstones of Operation 6 and 7).
pred givenMap[m : lone ChanMap] {
    some m and some m.keys
}

-- names: the channel names a declared channel set lists.
fun names[l : set ChannelList] : set Name {
    l.entries.name
}

-- degenerate: a declared channel set that is empty, that repeats a channel name, or that
-- carries a blank channel name (Term degenerate).
pred degenerate[l : ChannelList] {
    no l.entries
    or (some disj e1, e2 : l.entries | e1.name = e2.name)
    or some (l.entries.name & BlankName)
}

-- inEffect: the record is currently in effect, its status active or suspended (Term
-- currently in effect).
pred inEffect[v : PrefRecord] {
    v.status = Active or v.status = Suspended
}

-- originOf: the version [Set] recorded, the first along the chain of versions found.
fun originOf[v : PrefRecord] : set PrefRecord {
    { w : v.*found | no w.found }
}

-- originCall: the [Set] call that recorded the record this version belongs to.
fun originCall[v : PrefRecord] : set Call {
    originOf[v].writtenBy
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writing actions: their guards and their writes
-- ─────────────────────────────────────────────────────────────────────────────

-- someFieldGiven: the call carries at least one preference field that is not blank;
-- metadata is not a preference field (Term preference field, Operation 12).
pred someFieldGiven[c : SetCall] {
    givenMap[c.chanPrefsIn] or givenVal[c.frequencyIn] or givenVal[c.quietIn] or givenVal[c.formatIn]
}

-- setAdmitted: the guards an admitted [Set] passed: the injected set is not degenerate (on a
-- degenerate one [Set] writes nothing, Instance 14), the principal reference is not blank,
-- a preference field is given, and every channel preferences key is in the injected set.
pred setAdmitted[c : SetCall] {
    not degenerate[c.injected]                         -- Instance 13, 14
    nonBlank[c.setPrincipal]                           -- Operation 4
    someFieldGiven[c]                                  -- Operation 5
    c.chanPrefsIn.keys in names[c.injected]            -- Operation 8, Resumption 3
}

-- setWrites: the record an admitted [Set] records: the host's id, the call's principal
-- reference, the injected set stamped as declared channels, now as set instant, in active,
-- each preference field and the metadata stored where given and absent where blank, and no
-- suspension or deletion instant. The prior it found, if any, is the principal's record in
-- effect (Operation 14).
pred setWrites[c : SetCall, v : PrefRecord] {
    setAdmitted[c]
    all p : c.supersedes | p.principal = c.setPrincipal and inEffect[p]
    v.prefId    = c.allocatedId                        -- Identity 2
    v.principal = c.setPrincipal
    v.declared  = c.injected                           -- Instance 12
    v.setAt     = c.now                                -- State 11
    v.status    = Active                               -- Operation 2
    givenMap[c.chanPrefsIn] => v.chanPrefs = c.chanPrefsIn else no v.chanPrefs   -- State 3, 4
    givenVal[c.frequencyIn] => v.frequencyLimit = c.frequencyIn else no v.frequencyLimit
    givenVal[c.quietIn] => v.quietHours = c.quietIn else no v.quietHours
    givenVal[c.formatIn] => v.format = c.formatIn else no v.format
    some c.metadataIn => v.metadata = c.metadataIn else no v.metadata   -- BUG: blank stored (State 21)
    no v.suspendedAt
    no v.deletedAt
}

-- keepsValues: the call leaves every field but the status and the two lifecycle instants as
-- it found them (Invariant 1, Operation 21; written so here, checked across steps by TLA+).
pred keepsValues[pre, v : PrefRecord] {
    v.prefId         = pre.prefId
    v.principal      = pre.principal
    v.declared       = pre.declared
    v.setAt          = pre.setAt
    v.chanPrefs      = pre.chanPrefs
    v.frequencyLimit = pre.frequencyLimit
    v.quietHours     = pre.quietHours
    v.format         = pre.format
    v.metadata       = pre.metadata
}

-- supersedeWrites: the version an admitted [Set] leaves of the principal's prior record in
-- effect: stood in deleted, its deletion instant stamped from the call's now, in the same
-- call that records the new record (Operation 14, State 12; Term supersession).
pred supersedeWrites[pre : PrefRecord, c : SetCall, v : PrefRecord] {
    setAdmitted[c]
    pre = c.supersedes
    pre.principal = c.setPrincipal                     -- the principal's record
    inEffect[pre]                                      -- currently in effect
    keepsValues[pre, v]
    v.status      = Deleted                            -- Operation 14
    v.deletedAt   = c.now                              -- State 12
    v.suspendedAt = pre.suspendedAt
}

-- suspendWrites: the version an admitted [Suspend] leaves of the record it names: not
-- suspended and not deleted, stood in suspended with the suspension instant stamped from
-- now, its values untouched.
pred suspendWrites[pre : PrefRecord, c : SuspendCall, v : PrefRecord] {
    some c.suspendId and c.suspendId = pre.prefId      -- the record named (Operation 17)
    Suspended not in pre.status                        -- Operation 18
    Deleted not in pre.status                          -- Operation 19
    keepsValues[pre, v]                                -- Operation 21
    v.status      = Suspended                          -- Operation 20
    v.suspendedAt = c.now                              -- State 9
    v.deletedAt   = pre.deletedAt
}

-- deleteWrites: the version an admitted [Delete] leaves of the record it names: not yet
-- deleted, stood in deleted with the deletion instant stamped from now, kept in the
-- database (Operation 27).
pred deleteWrites[pre : PrefRecord, c : DeleteCall, v : PrefRecord] {
    some c.deleteId and c.deleteId = pre.prefId        -- the record named (Operation 24)
    Deleted not in pre.status                          -- Operation 25
    keepsValues[pre, v]
    v.status      = Deleted                            -- Operation 26
    v.deletedAt   = c.now                              -- State 10
    v.suspendedAt = pre.suspendedAt
}

-- written: the version is what its call's write left: a [Set]'s new record over nothing,
-- or a [Set]'s supersession, a [Suspend] or a [Delete] over a version an earlier call wrote.
pred written[v : PrefRecord] {
    let c = v.writtenBy, pre = v.found {
        (c in SetCall and no pre and setWrites[c, v])
        or (c in SetCall and some pre and supersedeWrites[pre, c, v])
        or (c in SuspendCall and some pre and suspendWrites[pre, c, v])
        or (c in DeleteCall and some pre and deleteWrites[pre, c, v])
    }
}

-- recorded: a version the page lets the records hold (see SCOPE): its chain ends at a [Set]'s
-- new record, and it and every version it was built from are what an admitted call wrote.
pred recorded[v : PrefRecord] {
    some originOf[v]
    all w : v.*found | written[w]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The reads: what they read and what they answer
-- ─────────────────────────────────────────────────────────────────────────────

-- aDatabase: what a read reads is a state of the records — recorded versions, one version
-- per record.
pred aDatabase[db : set PrefRecord] {
    all v : db | recorded[v]
    all disj a, b : db | originCall[a] != originCall[b]
}

-- inEffectFor: the records in a database currently in effect for a principal reference,
-- matched exactly (Identity 10; Term currently in effect).
fun inEffectFor[db : set PrefRecord, p : lone Str] : set PrefRecord {
    { v : db | some p and v.principal = p and inEffect[v] }
}

-- currentForAnswers: the answer [Current For] gives from the records it read: a record in
-- effect for the principal reference, never a deleted one, or none where there is none
-- (Operation 31, 32, 33); it writes nothing (Operation 37).
pred currentForAnswers[c : CurrentForCall] {
    aDatabase[c.cfDb]
    c.cfAnswer in inEffectFor[c.cfDb, c.forPrincipal]
    some inEffectFor[c.cfDb, c.forPrincipal] implies some c.cfAnswer
}

-- readAnswers: the answer [Read] gives from the records it read: the whole record carrying
-- the preference id, in any status, or not-known where none carries it (Operation 34, 35,
-- 36); it writes nothing (Operation 38).
pred readAnswers[c : ReadCall] {
    aDatabase[c.readDb]
    c.readAnswer = { v : c.readDb | some c.readId and v.prefId = c.readId }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any record the page's calls can leave, or any answer a read
-- can give over such records, that violates this assertion? No counterexample (UNSAT) =
-- the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_State_1: every record stands in exactly one of active, suspended, deleted. [Set] stands
-- a record active, and each later write replaces the status.
assert A_State_1 {
    all v : PrefRecord | recorded[v] implies one v.status
}
check A_State_1 for 4 but 4 Int

-- A_Invariant_2_3: an active record carries no suspension instant. A record carries one
-- exactly when it has stood in suspended (State 6, 7), so an active record carrying one
-- came back from suspended.
assert A_Invariant_2_3 {
    all v : PrefRecord | (recorded[v] and Active in v.status) implies no v.suspendedAt
}
check A_Invariant_2_3 for 4 but 4 Int

-- A_Invariant_2_4: an active record carries no deletion instant (State 13). A deleted
-- record carries one and keeps it (State 8, Invariant 1.6), so an active record carrying
-- one came back from deleted.
assert A_Invariant_2_4 {
    all v : PrefRecord | (recorded[v] and Active in v.status) implies no v.deletedAt
}
check A_Invariant_2_4 for 4 but 4 Int

-- A_Invariant_2_5: a suspended record carries no deletion instant (State 13), so none went
-- from deleted to suspended.
assert A_Invariant_2_5 {
    all v : PrefRecord | (recorded[v] and Suspended in v.status) implies no v.deletedAt
}
check A_Invariant_2_5 for 4 but 4 Int

-- A_State_6: a suspended record carries its suspension instant.
assert A_State_6 {
    all v : PrefRecord | (recorded[v] and Suspended in v.status) implies one v.suspendedAt
}
check A_State_6 for 4 but 4 Int

-- A_State_8: a deleted record carries its deletion instant, whether an explicit [Delete] or
-- a supersession retired it.
assert A_State_8 {
    all v : PrefRecord | (recorded[v] and Deleted in v.status) implies one v.deletedAt
}
check A_State_8 for 4 but 4 Int

-- A_Invariant_5_1: every channel preferences key stands in the record's own declared
-- channels, so an auditor clears it from the record alone (Check 5.1, Channel set
-- evolution 3).
assert A_Invariant_5_1 {
    all v : PrefRecord | recorded[v] implies v.chanPrefs.keys in names[v.declared]
}
check A_Invariant_5_1 for 4 but 4 Int

-- A_Invariant_10_1: every record carries declared channels, its own validation context.
assert A_Invariant_10_1 {
    all v : PrefRecord | recorded[v] implies one v.declared
}
check A_Invariant_10_1 for 4 but 4 Int

-- A_Invariant_10_2: a recorded declared channels is not empty (Check 5.2).
assert A_Invariant_10_2 {
    all v : PrefRecord | recorded[v] implies (all l : v.declared | some l.entries)
}
check A_Invariant_10_2 for 4 but 4 Int

-- A_Instance_14: no record carries a degenerate declared channels: [Set] stamps the injected
-- set (Instance 12) and writes nothing when it is degenerate.
assert A_Instance_14 {
    all v : PrefRecord | recorded[v] implies (all l : v.declared | not degenerate[l])
}
check A_Instance_14 for 4 but 4 Int

-- A_Instance_2: two records recorded by different [Set] calls never share a preference id —
-- a principal's new record and the prior it superseded included (Identity 4, 6).
assert A_Instance_2 {
    all v1, v2 : PrefRecord | (recorded[v1] and recorded[v2] and originCall[v1] != originCall[v2])
        implies v1.prefId != v2.prefId
}
check A_Instance_2 for 4 but 4 Int

-- A_Invariant_7_1: where the records hold one record in effect for the principal reference
-- (Invariant 3.1, the TLA+ model's), [Current For] answers that record.
assert A_Invariant_7_1 {
    all c : CurrentForCall | (currentForAnswers[c] and lone inEffectFor[c.cfDb, c.forPrincipal])
        implies (all r : inEffectFor[c.cfDb, c.forPrincipal] | c.cfAnswer = r)
}
check A_Invariant_7_1 for 4 but 4 Int

-- A_Invariant_7_2: [Current For] answers none only where no record in effect for the
-- principal reference stands in the records it read.
assert A_Invariant_7_2 {
    all c : CurrentForCall | (currentForAnswers[c] and no c.cfAnswer)
        implies no inEffectFor[c.cfDb, c.forPrincipal]
}
check A_Invariant_7_2 for 4 but 4 Int

-- A_Invariant_7_3: [Current For] rests on the records alone: two calls reading the same
-- records for the same principal reference answer alike, whatever now each carries
-- (Clock dependence 1), where the records hold at most one record in effect for it.
assert A_Invariant_7_3 {
    all disj c1, c2 : CurrentForCall |
        (currentForAnswers[c1] and currentForAnswers[c2]
            and c1.cfDb = c2.cfDb and c1.forPrincipal = c2.forPrincipal
            and lone inEffectFor[c1.cfDb, c1.forPrincipal])
        implies c1.cfAnswer = c2.cfAnswer
}
check A_Invariant_7_3 for 4 but 4 Int

-- A_Invariant_9_3: [Read] answers a deleted record: a read naming the id of a deleted record
-- in the records it read answers that record, whole (Operation 35).
assert A_Invariant_9_3 {
    all c : ReadCall | readAnswers[c] implies
        (all v : c.readDb | (some c.readId and v.prefId = c.readId and Deleted in v.status)
            implies c.readAnswer = v)
}
check A_Invariant_9_3 for 4 but 4 Int

-- A_Temporal_property_1: a record's suspension instant does not precede its set instant.
assert A_Temporal_property_1 {
    all v : PrefRecord | (recorded[v] and one v.suspendedAt and one v.setAt)
        implies v.suspendedAt >= v.setAt
}
check A_Temporal_property_1 for 4 but 4 Int

-- A_Temporal_property_2: a record's deletion instant does not precede its set instant,
-- whether a [Delete] or a supersession stamped it.
assert A_Temporal_property_2 {
    all v : PrefRecord | (recorded[v] and one v.deletedAt and one v.setAt)
        implies v.deletedAt >= v.setAt
}
check A_Temporal_property_2 for 4 but 4 Int

-- A_Temporal_property_3: a record carrying both instants was deleted no earlier than it was
-- suspended.
assert A_Temporal_property_3 {
    all v : PrefRecord | (recorded[v] and one v.deletedAt and one v.suspendedAt)
        implies v.deletedAt >= v.suspendedAt
}
check A_Temporal_property_3 for 4 but 4 Int

-- A_Operation_4: every record carries a principal reference that is not blank, the key the
-- at-most-one rule ranges over.
assert A_Operation_4 {
    all v : PrefRecord | recorded[v] implies nonBlank[v.principal]
}
check A_Operation_4 for 4 but 4 Int

-- A_Operation_5: every record carries at least one preference field that is not blank;
-- metadata alone is not a preference set (Term metadata).
assert A_Operation_5 {
    all v : PrefRecord | recorded[v] implies
        (givenMap[v.chanPrefs] or givenVal[v.frequencyLimit] or givenVal[v.quietHours] or givenVal[v.format])
}
check A_Operation_5 for 4 but 4 Int

-- A_State_4: a record carries no blank preference field: an empty channel preferences map
-- is stored as absent (Term channel preferences), and a blank value is not stored.
assert A_State_4 {
    all v : PrefRecord | recorded[v] implies {
        no v.chanPrefs or some v.chanPrefs.keys
        no (v.frequencyLimit + v.quietHours + v.format) & BlankVal
    }
}
check A_State_4 for 4 but 4 Int

-- A_State_21: a record carries no blank metadata.
assert A_State_21 {
    all v : PrefRecord | recorded[v] implies no v.metadata & BlankVal
}
check A_State_21 for 4 but 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a record or an answer the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowOnboarding: a principal's first record, just set, with channel preferences and a
-- format (the Consumer SaaS example's pref_001).
run ShowOnboarding {
    some v : PrefRecord | recorded[v] and v.writtenBy in SetCall and no v.found
        and no v.writtenBy.supersedes and some v.chanPrefs and some v.format
} for 4 but 4 Int

-- ShowFieldsWithoutChannels: a record carrying a frequency limit and no channel preferences
-- (any one preference field suffices, Term preference field).
run ShowFieldsWithoutChannels {
    some v : PrefRecord | recorded[v] and no v.chanPrefs and some v.frequencyLimit
} for 4 but 4 Int

-- ShowSupersession: one [Set] call recording a principal's new record and standing the prior
-- in deleted, both instants from its one now (the onboarding example's pref_088).
run ShowSupersession {
    some n, d : PrefRecord | recorded[n] and recorded[d] and no n.found and some d.found
        and n.writtenBy = d.writtenBy and d.status = Deleted and n.status = Active
        and n.principal = d.principal
} for 4 but 4 Int

-- ShowSuspended: a record paused, its values kept and its suspension instant stamped (the
-- vacation suspend).
run ShowSuspended {
    some v : PrefRecord | recorded[v] and v.status = Suspended
} for 4 but 4 Int

-- ShowSuspendedThenSuperseded: a deleted record keeping its suspension instant, retired by
-- the [Set] that replayed its values (pref_088 on return).
run ShowSuspendedThenSuperseded {
    some v : PrefRecord | recorded[v] and v.status = Deleted and some v.suspendedAt
        and v.writtenBy in SetCall
} for 4 but 4 Int

-- ShowDeletedFromSuspended: a suspended record deleted explicitly, which [Delete] admits.
run ShowDeletedFromSuspended {
    some v : PrefRecord | recorded[v] and v.status = Deleted and v.writtenBy in DeleteCall
        and v.found.status = Suspended
} for 4 but 4 Int

-- ShowWithdrawnChannel: two records of one principal under different declared channels, the
-- older keyed by a channel the newer's set no longer lists (Channel set evolution 2, 3).
run ShowWithdrawnChannel {
    some disj a, b : PrefRecord | recorded[a] and recorded[b]
        and originCall[a] != originCall[b] and a.principal = b.principal
        and some (a.chanPrefs.keys - names[b.declared])
} for 4 but 4 Int

-- ShowCurrentForSuspended: [Current For] answering a suspended record, which a fanout reads
-- as suppress (Composition note 4).
run ShowCurrentForSuspended {
    some c : CurrentForCall | currentForAnswers[c] and c.cfAnswer.status = Suspended
} for 4 but 4 Int

-- ShowCurrentForNone: [Current For] answering none while the principal's deleted record
-- stands in the database (the account closure).
run ShowCurrentForNone {
    some c : CurrentForCall | currentForAnswers[c] and no c.cfAnswer
        and some v : c.cfDb | v.principal = c.forPrincipal and v.status = Deleted
} for 4 but 4 Int

-- ShowReadDeleted: [Read] answering a deleted record in full (the access request).
run ShowReadDeleted {
    some c : ReadCall | readAnswers[c] and c.readAnswer.status = Deleted
} for 4 but 4 Int

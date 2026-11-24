-- attributed-permissions-admin-buggy-issue-grantfirst.als
-- DELIBERATELY WRONG twin of attributed-permissions-admin.als (unit: `compositions/attributed-permissions-admin.md formal layer`).
--
-- INJECTED DEFECT: [Issue Grant] records the grant first and attests after it, at the act's later reading (Composes 16; Wiring decision 1).
--
-- BREAKS: A_Invariant_4_1.
-- Everything else is attributed-permissions-admin.als as written; read its comments there.

module attributed_permissions_admin_buggy_issue_grantfirst

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Str: an opaque reference a call carries: a subject reference, an action scope, a grantor
-- or a revoker reference. The composition compares them case-sensitively and never reads
-- inside one (Primitive policy 9, 10), so a reference is an uninterpreted token.
sig Str {}

-- Nonce: the value the host supplies at the seam for each issuance (Capability requirement
-- 2), which carries a grant proposal's uniqueness (Clock semantics 6).
sig Nonce {}

-- Pfx: a namespace prefix on a proposal. Ours is this deployment's (Capability requirement
-- 11, 13); a Foreign one marks another composing system's attestation in a shared Actor
-- Identity records (Term namespace prefix).
abstract sig Pfx {}

-- Ours: this deployment's namespace prefix.
one sig Ours extends Pfx {}

-- Foreign: a prefix another composing system put on its proposals.
sig Foreign extends Pfx {}

-- Reason: the underlying reason an orphan log entry carries (Term underlying reason).
abstract sig Reason {}

-- InvalidRequest, NotKnown, NotActive: Permissions' refusal at the grant, and its two at
-- the revoke.
one sig InvalidRequest, NotKnown, NotActive extends Reason {}

-- RetScope: the retention scope the deployment declares (Capability requirement 27, Term
-- retention scope).
abstract sig RetScope {}

-- PairScoped, PerStore: a grant, its attestations and its entries purged as one unit; or
-- each record on its own.
one sig PairScoped, PerStore extends RetScope {}

-- Deploy: what the deployment declares and supplies: the clock offset allowance
-- (Capability requirement 20), the retention horizon (Capability requirement 35) and the
-- retention scope (Capability requirement 27); and how far Actor Identity's seam and
-- Permissions' seam read off the composition's own (each constituent stamps at its own seam,
-- Clock semantics 9).
one sig Deploy {
    allowance : one Int,       -- the clock offset allowance
    horizon   : one Int,       -- the retention horizon
    retention : one RetScope,  -- the retention scope
    offA      : one Int,       -- Actor Identity's seam, read against the composition's
    offP      : one Int        -- Permissions' seam, read against the composition's
}

-- Call: one call of an action that writes, or a write around the composition. actor is the
-- grantor or the revoker the call names; early is the composition's seam reading at the
-- invocation, the request instant (Identity 7, 8); late is a later reading inside the same
-- act, since the clock moves while an act runs.
abstract sig Call {
    actor : one Str,
    early : one Int,
    late  : one Int
}

-- IssueCall: one [Issue Grant] call whose attest landed: issue_grant(subject_ref,
-- action_scope, grantor_ref, grantor_credential), with the nonce the host supplied.
sig IssueCall extends Call {
    isubj : one Str,    -- subject_ref
    iscp  : one Str,    -- action_scope
    nonce : one Nonce   -- the host's nonce for this issuance
}

-- IssueRefused: the issuances Permissions answered invalid-request after the attest landed
-- (Action wiring 8): Permissions' answer, taken from outside.
sig IssueRefused in IssueCall {}

-- RevokeCall: one [Revoke Grant] call whose attest landed: revoke_grant(grant_id,
-- revoker_ref, revoker_credential); target is the grant the handle names.
sig RevokeCall extends Call {
    target : one Grant
}

-- RevokeRefused: the revocations Permissions answered not-active (Action wiring 24):
-- Permissions' answer, taken from outside.
sig RevokeRefused in RevokeCall {}

-- SweepCall: one [Revoke Permission] call: revoke_permission(subject_ref, action_scope,
-- revoker_ref, revoker_credential); enumerated is the pair's active grants as Permissions'
-- declared read answered them, inside the transaction that revokes (Action wiring 42,
-- Execution Contract Database 2).
sig SweepCall extends Call {
    ssubj      : one Str,
    sscp       : one Str,
    enumerated : set Grant
}

-- DirectWrite: a grant issued or revoked by a direct database write, around the
-- composition (Composes 19, Invariant 1.4, 2.4).
sig DirectWrite extends Call {}

-- ForeignCall: another composing system's attest in the shared Actor Identity records.
sig ForeignCall extends Call {}

-- Grant: one Permissions grant record: its pair, the call that issued it and Permissions'
-- grant instant (its own seam's stamp), and, once revoked, the call that revoked it and the
-- revocation instant. Permissions revokes a grant at most once (its own invariant), so
-- revoked is lone.
sig Grant {
    gsubj     : one Str,
    gscp      : one Str,
    issued    : one Call,
    grantedAt : one Int,
    revoked   : lone Call,
    revokedAt : lone Int
}

-- Prop: a proposal an attestation binds its actor's proof to. Every field the two formats
-- name may be absent, so a write that left one out would show; what a proposal carries is
-- checked, never built into the type (Identity 11, 12, 13; Term grant proposal format,
-- Term revocation proposal format).
sig Prop {
    pfx    : lone Pfx,     -- the namespace prefix
    psubj  : lone Str,     -- subject_ref (a grant proposal)
    pscp   : lone Str,     -- action_scope (a grant proposal)
    pnonce : lone Nonce,   -- nonce (a grant proposal)
    pgrant : lone Grant,   -- grant_id (a revocation proposal)
    preq   : lone Int      -- requested_at, the request instant
}

-- Att: one Actor Identity attestation record: its proposal, the call whose attest minted it
-- and Actor Identity's stamp (its own seam's). Actor Identity mints a distinct attestation
-- per attest call (Invariant 7.4, its own guarantee), so every Att is one call's.
sig Att {
    prop  : one Prop,
    by    : one Call,
    stamp : one Int
}

-- GEntry: one grant attribution entry: the grant it is keyed by (Composition state 5), the
-- attestations it names (a set, so an entry naming two would show: Composition state 11)
-- and the call that wrote it.
sig GEntry {
    eg : one Grant,
    ea : set Att,
    ew : one Call
}

-- REntry: one revocation attribution entry, the same shape (Composition state 12).
sig REntry {
    rg : one Grant,
    ra : set Att,
    rw : one Call
}

-- OLE: one orphan log entry: the attestation, the proposal, the request instant and the
-- underlying reason it carries (Composition state 19), each a set so a missing or doubled
-- field would show, and the call that wrote it.
sig OLE {
    oa  : set Att,
    op  : set Prop,
    ot  : set Int,
    ors : set Reason,
    ow  : one Call
}

-- Purge: one purge record, the retention layer's record that a named attestation was
-- lawfully destroyed (Capability requirement 28, Term purge record), with its instant.
sig Purge {
    pa : one Att,
    pt : one Int
}

-- AI: the attestations Actor Identity holds in this state.
one sig AI {
    held : set Att
}

-- Report: what the failed-grant leg reports an attestation as (Housekeeping 5, 16, 17), and
-- Benign, the reading Housekeeping 18 forbids, in the type so a leg that gave it would show.
abstract sig Report {}

-- RptOrphan, RptPurgePending, RptNonConformant, RptBenign: an orphan; a purge-pending
-- orphan; a non-conformant purge; benign.
one sig RptOrphan, RptPurgePending, RptNonConformant, RptBenign extends Report {}

-- Leg: the failed-grant leg's one run, at its own clock reading.
one sig Leg {
    now : one Int
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The deployment's clock is monotonic and reads an instant from 0 to 3 in the model's span
-- (Capability requirement 1); a later reading inside one act reads no earlier (Invariant 4.3
-- claims nothing under a clock that does). Every proposal's request instant is such a
-- reading. The leg and the retention layer read the same clock, up to 7. The span is the
-- model's bound, not a rule of the page.
fact ClockIsMonotonic {
    all c : Call | c.early >= 0 and c.early <= 3 and c.late >= c.early and c.late <= 3
    all p : Prop, t : p.preq | t >= 0 and t <= 3
    Leg.now >= 0 and Leg.now <= 7
    all p : Purge | p.pt >= 0 and p.pt <= 7
}

-- Each constituent stamps at its own seam (Clock semantics 9), within one instant of the
-- composition's, and the two constituents' seams within the clock offset allowance of each
-- other: the envelope the deployment declares (Capability requirement 20, Term clock offset
-- allowance). The allowance is 0 or 1 and the horizon 0 to 2 (Capability requirement 35):
-- the model's bounds.
fact SeamsWithinTheAllowance {
    Deploy.allowance >= 0 and Deploy.allowance <= 1
    Deploy.horizon >= 0 and Deploy.horizon <= 2
    Deploy.offA >= -1 and Deploy.offA <= 1
    Deploy.offP >= -1 and Deploy.offP <= 1
    minus[Deploy.offA, Deploy.offP] <= Deploy.allowance
    minus[Deploy.offP, Deploy.offA] <= Deploy.allowance
    all a : Att | a.stamp >= -1 and a.stamp <= 4
}

-- The host supplies one nonce per issuance at the seam, never another issuance's
-- (Capability requirement 2, Identity 5).
fact HostSuppliesAFreshNonce {
    all disj c1, c2 : IssueCall | c1.nonce != c2.nonce
}

-- Permissions answers not-active only for a grant another call already revoked (its own
-- contract: Action wiring 24 relays it).
fact PermissionsAnswersNotActiveTruly {
    all c : RevokeRefused | some c.target.revoked and c.target.revoked != c
}

-- Permissions' declared read answers a sweep the pair's grants: each enumerated grant
-- carries the sweep's subject and scope (Action wiring 42).
fact PermissionsEnumeratesThePair {
    all c : SweepCall, g : c.enumerated | g.gsubj = c.ssubj and g.gscp = c.sscp
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- attOf: the attestations one call's attest (or attests) minted.
fun attOf[c : Call] : set Att {
    by.c
}

-- named: the attestations an attribution entry names.
fun named : set Att {
    GEntry.ea + REntry.ra
}

-- sameProp: two proposals carry the same fields: one serialized proposal, as Invariant 7.5
-- and 7.6 compare them.
pred sameProp[p, q : Prop] {
    p.pfx = q.pfx and p.psubj = q.psubj and p.pscp = q.pscp
    p.pnonce = q.pnonce and p.pgrant = q.pgrant and p.preq = q.preq
}

-- grantProp: a proposal per the grant proposal format: the namespace prefix, the subject,
-- the scope and the host's nonce, and no grant handle (Identity 11, 13; Capability
-- requirement 10, 11). The request instant is set by the writer.
pred grantProp[c : IssueCall, p : Prop] {
    p.pfx = Ours
    p.psubj = c.isubj
    p.pscp = c.iscp
    p.pnonce = c.nonce
    no p.pgrant
}

-- revokeProp: a proposal per the fixed revocation proposal format: the namespace prefix and
-- the grant's handle (Identity 12; Capability requirement 12, 13). The request instant is
-- set by the writer.
pred revokeProp[g : Grant, p : Prop] {
    p.pfx = Ours
    no p.psubj
    no p.pscp
    no p.pnonce
    p.pgrant = g
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writes: what each call leaves in the records
-- ─────────────────────────────────────────────────────────────────────────────

-- issueWrites: an [Issue Grant] whose attest landed. The attest comes first, at the act's
-- first reading: one attestation over a grant proposal carrying the request instant
-- (Action wiring 1, 2; Composes 15, 16; Identity 8). Where Permissions grants, the grant is
-- recorded after it, at the act's later reading, with its grant attribution entry naming
-- the call's attestation (Action wiring 7, 15; Composition state 25). Where Permissions
-- answers invalid-request, no grant and no entry; the attestation stands and the orphan log
-- entry is written (Action wiring 8, 10, 101; Wiring decision 4).
pred issueWrites[c : IssueCall] {
    one attOf[c]
    all a : attOf[c] {
        grantProp[c, a.prop]
        a.prop.preq = c.early                                      -- Identity 7, 8
        a.stamp = plus[c.late, Deploy.offA]  -- BUG: attested after the grant
    }
    no revoked.c
    no rw.c
    c not in IssueRefused implies {
        one issued.c
        all g : issued.c {
            g.gsubj = c.isubj
            g.gscp = c.iscp
            g.grantedAt = plus[c.early, Deploy.offP]  -- BUG: the grant recorded first
        }
        one ew.c
        all e : ew.c | e.eg = issued.c and e.ea = attOf[c]         -- Action wiring 15
        no ow.c
    }
    c in IssueRefused implies {
        no issued.c
        no ew.c
        one ow.c
        all o : ow.c {
            o.oa = attOf[c]
            o.op = attOf[c].prop
            o.ot = c.early
            o.ors = InvalidRequest
        }
    }
}

-- revokeWrites: a [Revoke Grant] whose attest landed: one attestation over the revocation
-- proposal, first (Action wiring 16, 17). Where Permissions revokes, the grant stands revoked
-- by this call at the act's later reading, with its revocation attribution entry naming
-- the call's attestation (Action wiring 22, 41). Where Permissions answers not-active, no
-- revocation and no entry; the attestation stands and the orphan log entry is written
-- (Action wiring 24, 26, 102).
pred revokeWrites[c : RevokeCall] {
    one attOf[c]
    all a : attOf[c] {
        revokeProp[c.target, a.prop]
        a.prop.preq = c.early                                      -- Identity 7, 8
        a.stamp = plus[c.early, Deploy.offA]                       -- attest first
    }
    no issued.c
    no ew.c
    c not in RevokeRefused implies {
        revoked.c = c.target
        c.target.revokedAt = plus[c.late, Deploy.offP]             -- the revoke after
        one rw.c
        all r : rw.c | r.rg = c.target and r.ra = attOf[c]
        no ow.c
    }
    c in RevokeRefused implies {
        no revoked.c
        no rw.c
        one ow.c
        all o : ow.c {
            o.oa = attOf[c]
            o.op = attOf[c].prop
            o.ot = c.early
            o.ors = NotActive
        }
    }
}

-- sweepWrites: a [Revoke Permission]. An empty enumerated set attests nothing and writes
-- nothing (Action wiring 43, 44). Otherwise every enumerated grant is revoked by this call
-- (Action wiring 46), each under an attestation of its own over its revocation proposal, all
-- carrying the invocation's one request instant (Composes 23, 24; Identity 8, 9), and each
-- paired by one revocation attribution entry; no attestation is minted beside them.
pred sweepWrites[c : SweepCall] {
    no issued.c
    no ew.c
    no ow.c
    revoked.c = c.enumerated                                       -- Action wiring 46
    all g : c.enumerated | g.revokedAt = plus[c.late, Deploy.offP]
    rw.c.rg = c.enumerated                                         -- each one paired
    all g : c.enumerated | one (rw.c & rg.g)
    all r : rw.c | one r.ra and r.ra in attOf[c]
    all disj r1, r2 : rw.c | no (r1.ra & r2.ra)                    -- Composes 24
    rw.c.ra = attOf[c]
    all r : rw.c {
        revokeProp[r.rg, r.ra.prop]
        r.ra.prop.preq = c.early                                   -- Identity 9
        r.ra.stamp = plus[c.early, Deploy.offA]                    -- attest first
    }
}

-- directWrites: a write around the composition issues or revokes grants and nothing else:
-- no attestation, no entry, no orphan log entry (Composes 19).
pred directWrites[c : DirectWrite] {
    no attOf[c]
    no ew.c
    no rw.c
    no ow.c
}

-- foreignWrites: another composing system's attest: one attestation under its own prefix,
-- and nothing of this composition's.
pred foreignWrites[c : ForeignCall] {
    one attOf[c]
    attOf[c].prop.pfx in Foreign
    no issued.c
    no revoked.c
    no ew.c
    no rw.c
    no ow.c
}

-- purgeWrites: the retention layer's lawful destruction of one of this composition's
-- attestations, recorded in the purge record: only past the attestation's retention horizon
-- from its request instant (Term retention horizon); a paired attestation goes alone only
-- under the per-store scope (Composition state 27: under the pair-scoped scope it goes with
-- its unit, which the TLA+ model's PurgePair is); an orphan under its own retention
-- (Composition state 28).
pred purgeWrites[p : Purge] {
    p.pa.prop.pfx = Ours
    p.pt > plus[p.pa.prop.preq, Deploy.horizon]
    p.pa in named implies Deploy.retention = PerStore
}

-- Built: the state is what its calls wrote. Every call wrote what its action writes; every
-- grant was issued by an issuance or a direct write and revoked, if at all, by a revocation,
-- a sweep or a direct write, with a revocation instant exactly when revoked; every purge
-- record is the retention layer's, one per purged attestation; and Actor Identity holds
-- every attestation no purge took.
pred Built {
    all c : IssueCall | issueWrites[c]
    all c : RevokeCall | revokeWrites[c]
    all c : SweepCall | sweepWrites[c]
    all c : DirectWrite | directWrites[c]
    all c : ForeignCall | foreignWrites[c]
    all g : Grant | g.issued in IssueCall + DirectWrite
    all g : Grant | g.revoked in RevokeCall + SweepCall + DirectWrite
    all g : Grant | (some g.revoked) iff (some g.revokedAt)
    all p : Purge | purgeWrites[p]
    all a : Att | lone pa.a
    AI.held = Att - Purge.pa
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The failed-grant leg: what it reports, as the Housekeeping rules have it run
-- ─────────────────────────────────────────────────────────────────────────────

-- legPop: the leg's population: the attestations Actor Identity's declared read enumerates
-- (Housekeeping 2), filtered to this deployment's namespace prefix (Housekeeping 3), that no
-- attribution entry names (Housekeeping 4), detected against the records and the maps,
-- never the orphan log (Composition state 23, 24).
fun legPop : set Att {
    { a : AI.held | a.prop.pfx = Ours and a not in named }
}

-- legAged: the leg reads the attestation as past the horizon: aged by the request instant
-- its proposal carries (Housekeeping 13).
pred legAged[a : Att] {
    minus[Leg.now, a.prop.preq] > Deploy.horizon
}

-- report: what the leg reports a population member as: inside the horizon an orphan
-- (Housekeeping 5); aged out, a purge-pending orphan where its orphan log entry stands
-- (Housekeeping 16) and a non-conformant purge where none does (Housekeeping 17). Nothing
-- for an attestation outside the population.
fun report[a : Att] : set Report {
    a in legPop
        => (legAged[a] => (a in OLE.oa => RptPurgePending else RptNonConformant)
                       else RptOrphan)
        else none
}

-- agedOut: the term aged-out attestation: its age, taken from the request instant its
-- proposal carries, exceeds the retention horizon.
pred agedOut[a : Att] {
    one a.prop.preq
    minus[Leg.now, a.prop.preq] > Deploy.horizon
}

-- unpairedOurs: an attestation Actor Identity holds under this deployment's prefix that no
-- attribution entry names: what the page calls unpaired.
pred unpairedOurs[a : Att] {
    a in AI.held
    a.prop.pfx = Ours
    no (GEntry.ea + REntry.ra) & a
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the calls can leave (or, for the leg, any state it
-- can read) that violates this assertion? No counterexample (UNSAT) = the guarantee holds
-- within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every grant an [Issue Grant] recorded carries a grant attribution entry
-- (Invariant 1.1, Check 1.1). A grant a direct write produced is not claimed (Invariant 1.4).
assert A_Invariant_1_1 {
    Built implies all g : Grant | g.issued in IssueCall implies some eg.g
}
check A_Invariant_1_1 for 4 but 5 Int

-- A_Invariant_2_1: every grant a [Revoke Grant] or a [Revoke Permission] revoked carries a
-- revocation attribution entry (Invariant 2.1, Check 2.1). A direct revocation is not
-- claimed (Invariant 2.4).
assert A_Invariant_2_1 {
    Built implies all g : Grant | (some g.revoked and g.revoked in RevokeCall + SweepCall) implies some rg.g
}
check A_Invariant_2_1 for 4 but 5 Int

-- A_Invariant_4_1: an issuance attestation's stamp does not exceed its grant's grant instant
-- taken with the clock offset allowance (Invariant 4.1, Check 3.1, 3.2): the attest comes
-- before the grant, and the two seams differ by no more than the allowance.
assert A_Invariant_4_1 {
    Built implies all e : GEntry, a : e.ea | a.stamp <= plus[e.eg.grantedAt, Deploy.allowance]
}
check A_Invariant_4_1 for 4 but 5 Int

-- A_Invariant_4_2: a revocation attestation's stamp does not exceed its grant's revocation
-- instant taken with the clock offset allowance (Invariant 4.2).
assert A_Invariant_4_2 {
    Built implies all r : REntry, a : r.ra, t : r.rg.revokedAt | a.stamp <= plus[t, Deploy.allowance]
}
check A_Invariant_4_2 for 4 but 5 Int

-- A_Invariant_7_1: the grant attribution map is injective: no attestation is named by the
-- entries of two grants (Invariant 7.1, Check 6.1, 6.4).
assert A_Invariant_7_1 {
    Built implies all a : Att | lone (ea.a).eg
}
check A_Invariant_7_1 for 4 but 5 Int

-- A_Invariant_7_2: the revocation attribution map is injective (Invariant 7.2, Check 6.2).
assert A_Invariant_7_2 {
    Built implies all a : Att | lone (ra.a).rg
}
check A_Invariant_7_2 for 4 but 5 Int

-- A_Invariant_7_3: no attestation is named in both maps (Invariant 7.3, Check 6.3).
assert A_Invariant_7_3 {
    Built implies no (GEntry.ea & REntry.ra)
}
check A_Invariant_7_3 for 4 but 5 Int

-- A_Invariant_7_5: no two issuance attestations carry the same grant proposal (Invariant
-- 7.5): the nonce carries its uniqueness, not the request instant (Clock semantics 6, 7).
assert A_Invariant_7_5 {
    Built implies all disj a1, a2 : Att |
        (a1.by in IssueCall and a2.by in IssueCall) implies not sameProp[a1.prop, a2.prop]
}
check A_Invariant_7_5 for 4 but 5 Int

-- A_Invariant_7_6: no revocation proposal equals a grant proposal (Invariant 7.6).
assert A_Invariant_7_6 {
    Built implies all a1, a2 : Att |
        (a1.by in IssueCall and a2.by in RevokeCall + SweepCall) implies not sameProp[a1.prop, a2.prop]
}
check A_Invariant_7_6 for 4 but 5 Int

-- A_Invariant_9_1: every grant of a sweep's enumerated set stands revoked by that sweep
-- (Invariant 9.1, Check 7.1). It is stated over the enumerated set, never the pair
-- (Invariant 9.3).
assert A_Invariant_9_1 {
    Built implies all c : SweepCall, g : c.enumerated | g.revoked = c
}
check A_Invariant_9_1 for 4 but 5 Int

-- A_Invariant_9_2: every grant of a sweep's enumerated set carries a revocation attribution
-- entry naming one of that sweep's attestations (Invariant 9.2, Check 7.2).
assert A_Invariant_9_2 {
    Built implies all c : SweepCall, g : c.enumerated | some r : rg.g | r.ra in attOf[c] and some r.ra
}
check A_Invariant_9_2 for 4 but 5 Int

-- A_Composition_state_11: a grant attribution entry names exactly one attestation
-- (Composition state 11).
assert A_Composition_state_11 {
    Built implies all e : GEntry | one e.ea
}
check A_Composition_state_11 for 4 but 5 Int

-- A_Composition_state_12: a revocation attribution entry names exactly one attestation
-- (Composition state 12).
assert A_Composition_state_12 {
    Built implies all r : REntry | one r.ra
}
check A_Composition_state_12 for 4 but 5 Int

-- A_Composition_state_13: a grant carries at most one revocation attribution entry
-- (Composition state 13).
assert A_Composition_state_13 {
    Built implies all g : Grant | lone rg.g
}
check A_Composition_state_13 for 4 but 5 Int

-- A_Composition_state_19: an orphan log entry carries one attestation, that attestation's
-- proposal, the proposal's request instant and one underlying reason (Composition state 19).
assert A_Composition_state_19 {
    Built implies all o : OLE {
        one o.oa
        o.op = o.oa.prop
        one o.ot
        o.ot = o.oa.prop.preq
        one o.ors
    }
}
check A_Composition_state_19 for 4 but 5 Int

-- A_Composition_state_28: a purge record naming one of this composition's orphan
-- attestations was written past the orphan's own retention horizon, taken from its own
-- request instant (Composition state 28, Term retention horizon).
assert A_Composition_state_28 {
    Built implies all p : Purge | p.pa not in named implies p.pt > plus[p.pa.prop.preq, Deploy.horizon]
}
check A_Composition_state_28 for 4 but 5 Int

-- A_Identity_9: every attestation of one pair-scoped revocation carries one request instant
-- (Identity 9), the key the auditor groups them by (Identity 10).
assert A_Identity_9 {
    Built implies all c : SweepCall | lone attOf[c].prop.preq
}
check A_Identity_9 for 4 but 5 Int

-- A_Identity_11: an issuance proposal carries the subject, the scope, the nonce and the
-- request instant (Identity 11).
assert A_Identity_11 {
    Built implies all a : Att | a.by in IssueCall implies {
        one a.prop.psubj
        one a.prop.pscp
        one a.prop.pnonce
        one a.prop.preq
    }
}
check A_Identity_11 for 4 but 5 Int

-- A_Identity_12: a revocation proposal carries the grant's handle and the request instant
-- (Identity 12).
assert A_Identity_12 {
    Built implies all a : Att | a.by in RevokeCall + SweepCall implies {
        one a.prop.pgrant
        one a.prop.preq
    }
}
check A_Identity_12 for 4 but 5 Int

-- A_Identity_13: an issuance proposal carries no grant handle: the grant does not exist when
-- the attestation is written (Identity 13).
assert A_Identity_13 {
    Built implies all a : Att | a.by in IssueCall implies no a.prop.pgrant
}
check A_Identity_13 for 4 but 5 Int

-- A_Housekeeping_3: the leg reports only attestations under this deployment's namespace
-- prefix, never a foreign composing system's (Housekeeping 3, Check 5.2). Over every state.
assert A_Housekeeping_3 {
    all a : Att | some report[a] implies a.prop.pfx = Ours
}
check A_Housekeeping_3 for 4 but 5 Int

-- A_Housekeeping_4: every unpaired attestation of ours inside the horizon is reported as an
-- orphan, whether or not the orphan log holds it (Housekeeping 4, 5; Check 5.3, 5.9;
-- Composition state 23). Over every state.
assert A_Housekeeping_4 {
    all a : Att | (unpairedOurs[a] and one a.prop.preq and not agedOut[a]) implies report[a] = RptOrphan
}
check A_Housekeeping_4 for 4 but 5 Int

-- A_Housekeeping_13: the leg reads an unpaired attestation of ours as aged out exactly when
-- the term does: by the request instant its proposal carries (Housekeeping 13). Over every
-- state.
assert A_Housekeeping_13 {
    all a : Att | (unpairedOurs[a] and one a.prop.preq) implies
        (agedOut[a] iff report[a] in RptPurgePending + RptNonConformant + RptBenign)
}
check A_Housekeeping_13 for 4 but 5 Int

-- A_Housekeeping_15: no aged-out attestation is reported as an orphan (Housekeeping 15).
-- Over every state.
assert A_Housekeeping_15 {
    all a : Att | agedOut[a] implies RptOrphan not in report[a]
}
check A_Housekeeping_15 for 4 but 5 Int

-- A_Housekeeping_16: an aged-out unpaired attestation carrying an orphan log entry is
-- reported as a purge-pending orphan (Housekeeping 16, Check 5.6). Over every state.
assert A_Housekeeping_16 {
    all a : Att | (unpairedOurs[a] and agedOut[a] and a in OLE.oa) implies report[a] = RptPurgePending
}
check A_Housekeeping_16 for 4 but 5 Int

-- A_Housekeeping_17: an aged-out unpaired attestation carrying no orphan log entry is
-- reported as a non-conformant purge (Housekeeping 17, Check 5.7). Over every state.
assert A_Housekeeping_17 {
    all a : Att | (unpairedOurs[a] and agedOut[a] and a not in OLE.oa) implies report[a] = RptNonConformant
}
check A_Housekeeping_17 for 4 but 5 Int

-- A_Housekeeping_18: no aged-out unpaired attestation is read as benign (Housekeeping 18,
-- Check 5.8). Over every state.
assert A_Housekeeping_18 {
    all a : Att | (unpairedOurs[a] and agedOut[a]) implies RptBenign not in report[a]
}
check A_Housekeeping_18 for 4 but 5 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowAttributedGrant: a grant issued through the composition with its attestation and its
-- entry, as the nurse's read grant in the walkthrough.
run ShowAttributedGrant {
    Built
    some g : Grant | g.issued in IssueCall
} for 4 but 5 Int

-- ShowTwoGrantsOnePair: two issuances over one pair, two grants and two attestations
-- (Concurrency 1, 2, 3; Wiring decision 8).
run ShowTwoGrantsOnePair {
    Built
    some disj g1, g2 : Grant | g1.issued in IssueCall and g2.issued in IssueCall
        and g1.gsubj = g2.gsubj and g1.gscp = g2.gscp
} for 4 but 5 Int

-- ShowRevokedGrant: a grant issued and revoked through the composition, with both entries.
run ShowRevokedGrant {
    Built
    some g : Grant | g.issued in IssueCall and g.revoked in RevokeCall
} for 4 but 5 Int

-- ShowSweepTwo: one [Revoke Permission] revoking two grants of a pair under two
-- attestations and one request instant (the permission, not the grant).
run ShowSweepTwo {
    Built
    some c : SweepCall | #c.enumerated = 2
} for 4 but 5 Int

-- ShowEmptySweep: a [Revoke Permission] over a pair holding no active grant attests and
-- writes nothing (Action wiring 43, 44: not-permitted).
run ShowEmptySweep {
    Built
    some c : SweepCall | no c.enumerated
} for 4 but 5 Int

-- ShowIssueOrphan: an issuance Permissions refused after the attest: the attestation stands
-- unpaired with its orphan log entry (the failure path the ordering accepts).
run ShowIssueOrphan {
    Built
    some IssueRefused
} for 4 but 5 Int

-- ShowRevokeOrphan: a [Revoke Grant] of a grant already revoked: answered not-active, the
-- attestation stands with its orphan log entry (Action wiring 28, 30, 102).
run ShowRevokeOrphan {
    Built
    some RevokeRefused
} for 4 but 5 Int

-- ShowDirectGrant: a grant written around the composition carries no entry (Composes 19,
-- Invariant 1.4): the attribution-inconsistency the forensic finding reads.
run ShowDirectGrant {
    Built
    some g : Grant | g.issued in DirectWrite and no eg.g
} for 4 but 5 Int

-- ShowPerStorePurge: under the per-store scope an issuance attestation purged while its
-- grant stands; its entry stays and the purge record names it (the lawfully purged
-- attestation).
run ShowPerStorePurge {
    Built
    some p : Purge | p.pa in GEntry.ea
} for 4 but 5 Int

-- ShowOrphanPurged: an orphan attestation purged under its own retention, its orphan log
-- entry standing (Composition state 28; open line 2026-10-27-b).
run ShowOrphanPurged {
    Built
    some p : Purge | p.pa in OLE.oa
} for 4 but 5 Int

-- ShowTwoSweepsOneKey: two [Revoke Permission] calls over one pair, by one revoker, at one
-- request instant, each revoking a grant: the auditor's grouping key (Identity 10) reads
-- them as one administrative act. A finding (see the header).
run ShowTwoSweepsOneKey {
    Built
    some disj c1, c2 : SweepCall | some c1.enumerated and some c2.enumerated
        and c1.ssubj = c2.ssubj and c1.sscp = c2.sscp
        and c1.actor = c2.actor and c1.early = c2.early
} for 4 but 5 Int

-- ShowForeignUnreported: a foreign composing system's attestation in the shared records,
-- unpaired, which the leg does not report.
run ShowForeignUnreported {
    Built
    some a : Att | a.by in ForeignCall and a in AI.held and no report[a]
} for 4 but 5 Int

-- ShowLegOrphan: the leg reports an orphan inside the horizon.
run ShowLegOrphan {
    Built
    some a : Att | report[a] = RptOrphan
} for 4 but 5 Int

-- ShowLegPurgePending: the leg reports an aged-out orphan whose orphan log entry stands as a
-- purge-pending orphan: a purge the retention layer still owes.
run ShowLegPurgePending {
    Built
    some a : Att | report[a] = RptPurgePending
} for 4 but 5 Int

-- ShowLegNonConformant: a state the composition's own writes never leave — an attestation of
-- ours past the horizon, no entry naming it and no orphan log entry (a pairing purged
-- without its attestation) — which the leg reports as a non-conformant purge.
run ShowLegNonConformant {
    some a : Att | report[a] = RptNonConformant
} for 4 but 5 Int

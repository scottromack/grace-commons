-- authenticated-actor-buggy-notbound-unstamped.als
-- DELIBERATELY WRONG twin of authenticated-actor.als (unit: `compositions/authenticated-actor.md formal layer`).
--
-- INJECTED DEFECT: the not-bound arm appends its entry without the outcome (Action wiring
-- 15's entry carries no not-bound).
--
-- BREAKS: A_Composition_state_13 (and A_Action_wiring_24, whose condition an entry with no outcome meets).
-- Everything else is authenticated-actor.als as written; read its comments there.

module authenticated_actor_buggy_notbound_unstamped

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Principal: a principal reference, the key Credential and the principal binding use.
sig Principal {}

-- ActorRef: an actor reference, the key Actor Identity's attestations and the inverse map
-- use.
sig ActorRef {}

-- ActionRef: an action reference the caller supplies; the composition never interprets it
-- (Primitive policy 11).
sig ActionRef {}

-- CType: a credential type; the gate keys on a principal reference and a credential type
-- (Composes 9).
sig CType {}

-- Cred: one of Credential's credentials, carrying the pair it was registered for.
sig Cred {
    owner : one Principal,
    ctype : one CType
}

-- Status: what the attest log records as the observed status of a credential; none is the
-- status Action wiring 46 names for a pair with no credential.
abstract sig Status {}
one sig SActive, SRotated, SRevoked, SNone extends Status {}

-- Outcome: what an attest log entry records the call answered: the arms of the attest
-- answer (Term attest answer), and attest-failed, which no entry may carry (Invariant 4.2).
abstract sig Outcome {}
one sig Success, NotBound, CredentialNotActive, RegistryUnavailable, MechanismUnavailable,
    InvalidAttestCredential, AttestFailed extends Outcome {}

-- Attestation: one of Actor Identity's attestation records, with the actor reference and
-- the action reference it binds. Attestations other callers of Actor Identity made stand
-- here too (Non-goal 13).
sig Attestation {
    actor : one ActorRef,
    action : one ActionRef
}

-- Event: one commit in the store's one order (Execution Contract Database 1, 2); earlier
-- holds the commits before it.
abstract sig Event {
    earlier : set Event
}

-- CredRegistered: the deployment's own call of Credential's register (Composition note 7),
-- outside the composition.
sig CredRegistered extends Event {
    cred : one Cred
}

-- CredRotated: the deployment's call of Credential's rotate (Composition note 4): the prior
-- credential stands rotated and its successor active, for the same pair.
sig CredRotated extends Event {
    prior : one Cred,
    successor : one Cred
}

-- CredRevoked: the deployment's call of Credential's revoke (Composition note 4).
sig CredRevoked extends Event {
    revoked : one Cred
}

-- Arm: which arm of [Register Authenticated Actor] wrote a binding — the fresh arm, where
-- Credential's register answered a credential id (Action wiring 9), or the re-entry arm,
-- where it answered duplicate-active-credential (Action wiring 5 to 7).
abstract sig Arm {}
one sig Fresh, Reentry extends Arm {}

-- Binding: one admitted registration's commit: the principal binding (Term principal
-- binding: the actor reference, the bound credential type and the credential id), its
-- inverse map entry, and on the fresh arm the credential Credential's register wrote in the
-- same transaction (Action wiring 9).
sig Binding extends Event {
    bPrincipal : one Principal,
    bActor : one ActorRef,
    btype : one CType,
    bcred : one Cred,
    arm : one Arm,
    registers : lone Cred,
    invActor : lone ActorRef,
    invPrincipal : lone Principal
}

-- Entry: one attest log entry, committed with its call (Action wiring 45; Execution
-- Contract Database 1): what the call supplied, what it answered, and the attestation id,
-- credential id and observed status it carries.
sig Entry extends Event {
    ePrincipal : lone Principal,
    eAction : lone ActionRef,
    outcome : lone Outcome,
    attestation : lone Attestation,
    ecred : lone Cred,
    observed : lone Status
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- The store commits in one order (Execution Contract Database 1, 2): earlier is a strict
-- total order.
fact OneStoreOrder {
    all e : Event | e not in e.earlier
    all e : Event | e.earlier.earlier in e.earlier
    all disj x, y : Event | x in y.earlier or y in x.earlier
}

-- Credential writes each credential once: by its register (the deployment's, or the one
-- nested in a fresh registration) or as a rotation's successor.
fact CredentialRegistersOnce {
    all c : Cred | one regEv[c]
}

-- Credential's register lands only where the pair holds no effective-active credential;
-- otherwise it answers duplicate-active-credential (Credential Operation 6).
fact CredentialRefusesDuplicate {
    all r : CredRegistered | no effActive[r.cred.owner, r.cred.ctype, r.earlier]
    all b : Binding | some b.registers implies
        no effActive[b.registers.owner, b.registers.ctype, b.earlier]
}

-- Credential rotates and revokes only an effective-active credential (Credential
-- Operation 28, 29), a rotation's successor carrying the prior's pair (Operation 35 to
-- 37), and a credential leaves active once (rotated and revoked are permanent ends).
fact CredentialEnds {
    all r : CredRotated | activeOver[r.prior, r.earlier]
        and r.successor.owner = r.prior.owner and r.successor.ctype = r.prior.ctype
    all v : CredRevoked | activeOver[v.revoked, v.earlier]
    all c : Cred | lone endEv[c]
}

-- Actor Identity's attest answers a new attestation id for each attestation it records.
fact FreshAttestationIds {
    all disj e1, e2 : Entry | no (e1.attestation & e2.attestation)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- regEv: the commit that registered a credential.
fun regEv[c : Cred] : set Event {
    cred.c + successor.c + registers.c
}

-- endEv: the commit that took a credential out of active — its rotation or its revoke.
fun endEv[c : Cred] : set Event {
    prior.c + revoked.c
}

-- activeOver: a credential stands active over some commits — registered among them, not
-- yet rotated or revoked (effective-active, expiry left out).
pred activeOver[c : Cred, s : set Event] {
    some (regEv[c] & s)
    no (endEv[c] & s)
}

-- pairCreds: the credentials Credential's read answers for a pair over some commits.
fun pairCreds[p : set Principal, t : set CType, s : set Event] : set Cred {
    { c : Cred | c.owner in p and c.ctype in t and some (regEv[c] & s) }
}

-- effActive: the pair's credentials standing effective-active over some commits.
fun effActive[p : set Principal, t : set CType, s : set Event] : set Cred {
    { c : pairCreds[p, t, s] | activeOver[c, s] }
}

-- lastOf: of some credentials, the one Credential's read answers last, the latest
-- registered (Credential Operation 69).
fun lastOf[cs : set Cred] : set Cred {
    { c : cs | no d : cs - c | regEv[c] in regEv[d].earlier }
}

-- current: the pair's current credential (Term current credential): of its effective-active
-- credentials, the one Credential's read answers last.
fun current[p : set Principal, t : set CType, s : set Event] : set Cred {
    lastOf[effActive[p, t, s]]
}

-- statusOver: a credential's stored status over some commits.
fun statusOver[c : set Cred, s : set Event] : Status {
    some (revoked.c & s) => SRevoked else (some (prior.c & s) => SRotated else SActive)
}

-- bindingOf: the principal binding for a principal reference over some commits.
fun bindingOf[p : set Principal, s : set Event] : set Binding {
    { b : Binding & s | b.bPrincipal in p }
}

-- pmap: the principal binding as a map, principal reference to actor reference.
fun pmap : Principal -> ActorRef {
    { p : Principal, x : ActorRef | some b : Binding | b.bPrincipal = p and b.bActor = x }
}

-- xmap: the inverse map, actor reference to principal reference.
fun xmap : ActorRef -> Principal {
    { x : ActorRef, p : Principal | some b : Binding | b.invActor = x and b.invPrincipal = p }
}

-- gatePassed: the outcomes an entry records past an open gate.
fun gatePassed : set Outcome {
    Success + RegistryUnavailable + MechanismUnavailable + InvalidAttestCredential
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be, over the commits before it
-- ─────────────────────────────────────────────────────────────────────────────

-- bindingWrites: an admitted registration's binding — the guard clear on both maps (Action
-- wiring 2 to 4); on the fresh arm the credential Credential's register wrote for the
-- call's pair (Action wiring 9); on the re-entry arm the pair's current credential, which
-- Credential's register refused as a duplicate (Action wiring 5, 7); the inverse map entry
-- with it (Action wiring 7, 9).
pred bindingWrites[b : Binding] {
    no b2 : Binding & b.earlier | b2.bPrincipal = b.bPrincipal      -- Action wiring 2
    no b2 : Binding & b.earlier | b2.invActor = b.bActor            -- Action wiring 3
    b.arm = Fresh implies {
        b.registers = b.bcred                                       -- Action wiring 9
        b.bcred.owner = b.bPrincipal
        b.bcred.ctype = b.btype
    }
    b.arm = Reentry implies {
        no b.registers
        b.bcred = current[b.bPrincipal, b.btype, b.earlier]         -- Action wiring 5, 7
    }
    b.invActor = b.bActor                                           -- Action wiring 7, 9
    b.invPrincipal = b.bPrincipal
}

-- entryOver: an admitted attestation's entry, its gate read taking the commits r: what the
-- call supplied (Composition state 12; Primitive policy 1, 5); not-bound where no binding
-- stands (Action wiring 15); credential-not-active where the pair holds no effective-active
-- credential, with the observed status and credential id of the credential Credential's
-- read answers last, or none (Action wiring 18, 34, 46); past an open gate, the current
-- credential's id (Action wiring 24), and on success the attestation Actor Identity made
-- for the call's action reference and the bound actor reference (Action wiring 19 to 22,
-- 48). Every call answering an attest answer writes one (Action wiring 45).
pred entryOver[e : Entry, r : set Event] {
    one e.ePrincipal
    one e.eAction                                                   -- Composition state 12
    let p = e.ePrincipal, bs = bindingOf[p, r] {
        no bs implies {
            no e.outcome                                            -- DEFECT: no outcome recorded
            no e.attestation and no e.ecred and no e.observed
        }
        some bs implies {
            let t = bs.btype, ok = effActive[p, t, r], cs = pairCreds[p, t, r] {
                no ok implies {
                    e.outcome = CredentialNotActive                 -- Action wiring 18
                    no e.attestation
                    no cs implies (e.observed = SNone and no e.ecred)            -- Action wiring 46
                    some cs implies {
                        e.ecred = lastOf[cs]                                     -- Action wiring 34
                        e.observed = statusOver[e.ecred, r]
                    }
                }
                some ok implies {
                    some o : gatePassed | e.outcome = o             -- Action wiring 45
                    e.ecred = current[p, t, r]                      -- Action wiring 24
                    no e.observed
                    e.outcome = Success implies {
                        one e.attestation                           -- Action wiring 48
                        e.attestation.action = e.eAction            -- Action wiring 20
                        e.attestation.actor = bs.bActor             -- Action wiring 20, 21
                    }
                    e.outcome != Success implies no e.attestation
                }
            }
        }
    }
}

-- entryWrites: the gate read inside the attesting transaction, over every commit before the
-- entry (Execution Contract Database 2; Action wiring 17, 19).
pred entryWrites[e : Entry] {
    entryOver[e, e.earlier]
}

-- conforms: every binding and every entry in the state is one its writer's rules let it
-- write.
pred conforms {
    all b : Binding | bindingWrites[b]
    all e : Entry | entryWrites[e]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: no success entry for a principal reference that carried no
-- effective-active credential of its bound credential type at the entry's commit.
assert A_Invariant_1_1 {
    conforms implies all e : Entry | e.outcome = Success implies
        some effActive[e.ePrincipal, bindingOf[e.ePrincipal, e.earlier].btype, e.earlier]
}
check A_Invariant_1_1 for 3 but 5 Event

-- A_Check_2_2: no success entry's credential id names a credential standing revoked at the
-- entry's commit, as an auditor reads the credential's earlier versions.
assert A_Check_2_2 {
    conforms implies no e : Entry | e.outcome = Success and statusOver[e.ecred, e.earlier] = SRevoked
}
check A_Check_2_2 for 3 but 5 Event

-- A_Invariant_3_1: every principal reference the principal binding carries maps to exactly
-- one actor reference.
assert A_Invariant_3_1 {
    conforms implies all p : Principal | some pmap[p] implies one pmap[p]
}
check A_Invariant_3_1 for 3 but 5 Event

-- A_Invariant_3_2: every actor reference the inverse map carries maps to exactly one
-- principal reference.
assert A_Invariant_3_2 {
    conforms implies all x : ActorRef | some xmap[x] implies one xmap[x]
}
check A_Invariant_3_2 for 3 but 5 Event

-- A_Invariant_3_3: the principal binding and the inverse map agree, pair for pair.
assert A_Invariant_3_3 {
    conforms implies pmap = ~xmap
}
check A_Invariant_3_3 for 3 but 5 Event

-- A_Composition_state_4: no two principal bindings share a principal reference.
assert A_Composition_state_4 {
    conforms implies all disj b1, b2 : Binding | b1.bPrincipal != b2.bPrincipal
}
check A_Composition_state_4 for 3 but 5 Event

-- A_Composition_state_5: no two inverse map entries share an actor reference.
assert A_Composition_state_5 {
    conforms implies all disj b1, b2 : Binding | no (b1.invActor & b2.invActor)
}
check A_Composition_state_5 for 3 but 5 Event

-- A_Composition_state_12: every attest log entry carries the principal reference and the
-- action reference.
assert A_Composition_state_12 {
    conforms implies all e : Entry | one e.ePrincipal and one e.eAction
}
check A_Composition_state_12 for 3 but 5 Event

-- A_Composition_state_13: every attest log entry carries the outcome of its call.
assert A_Composition_state_13 {
    conforms implies all e : Entry | one e.outcome
}
check A_Composition_state_13 for 3 but 5 Event

-- A_Invariant_4_2: no attest log entry records a call that answered attest-failed.
assert A_Invariant_4_2 {
    conforms implies no e : Entry | e.outcome = AttestFailed
}
check A_Invariant_4_2 for 3 but 5 Event

-- A_Invariant_4_3: every success entry carries its attestation id and the current
-- credential's credential id, as the credential records stood at the entry's commit.
assert A_Invariant_4_3 {
    conforms implies all e : Entry | e.outcome = Success implies {
        one e.attestation
        one e.ecred
        e.ecred = current[e.ePrincipal, bindingOf[e.ePrincipal, e.earlier].btype, e.earlier]
    }
}
check A_Invariant_4_3 for 3 but 5 Event

-- A_Action_wiring_7: every binding carries the credential id of its pair's current
-- credential as the records stood at its commit.
assert A_Action_wiring_7 {
    conforms implies all b : Binding |
        b.bcred = current[b.bPrincipal, b.btype, b.earlier + b]
}
check A_Action_wiring_7 for 3 but 5 Event

-- A_Action_wiring_18: a credential-not-active entry stands only where its principal is
-- bound and the bound pair held no effective-active credential at the entry's commit.
assert A_Action_wiring_18 {
    conforms implies all e : Entry | e.outcome = CredentialNotActive implies {
        some bindingOf[e.ePrincipal, e.earlier]
        no effActive[e.ePrincipal, bindingOf[e.ePrincipal, e.earlier].btype, e.earlier]
    }
}
check A_Action_wiring_18 for 3 but 5 Event

-- A_Action_wiring_20: a success entry's attestation binds the call's action reference to
-- the actor reference the principal binding carries, never another.
assert A_Action_wiring_20 {
    conforms implies all e : Entry | e.outcome = Success implies {
        e.attestation.action = e.eAction
        e.attestation.actor = bindingOf[e.ePrincipal, e.earlier].bActor
    }
}
check A_Action_wiring_20 for 3 but 5 Event

-- A_Action_wiring_24: an entry written past an open gate that names no attestation carries
-- the current credential's credential id.
assert A_Action_wiring_24 {
    conforms implies all e : Entry |
        e.outcome in RegistryUnavailable + MechanismUnavailable + InvalidAttestCredential implies {
            one e.ecred
            e.ecred = current[e.ePrincipal, bindingOf[e.ePrincipal, e.earlier].btype, e.earlier]
        }
}
check A_Action_wiring_24 for 3 but 5 Event

-- A_Action_wiring_34: a credential-not-active entry for a pair with credentials names the
-- one Credential's read answers last, and its status at the entry's commit.
assert A_Action_wiring_34 {
    conforms implies all e : Entry | e.outcome = CredentialNotActive implies
        let cs = pairCreds[e.ePrincipal, bindingOf[e.ePrincipal, e.earlier].btype, e.earlier] |
            some cs implies (e.ecred = lastOf[cs] and e.observed = statusOver[e.ecred, e.earlier])
}
check A_Action_wiring_34 for 3 but 5 Event

-- A_Check_3_2: every credential-not-active entry carries an observed status.
assert A_Check_3_2 {
    conforms implies all e : Entry | e.outcome = CredentialNotActive implies one e.observed
}
check A_Check_3_2 for 3 but 5 Event

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowWalkthrough: the walkthrough — a fresh registration, a success entry, the credential
-- revoked, and a later credential-not-active entry naming it revoked.
run ShowWalkthrough {
    conforms
    some b : Binding, s, n : Entry, v : CredRevoked {
        b.arm = Fresh
        s.outcome = Success and n.outcome = CredentialNotActive
        s.ecred = b.bcred and v.revoked = b.bcred and n.ecred = b.bcred
        n.observed = SRevoked
        b in s.earlier and s in v.earlier and v in n.earlier
    }
} for 3 but 5 Event

-- ShowRotation: the rotation example — after a rotation the gate stays open and the success
-- entry names the successor.
run ShowRotation {
    conforms
    some r : CredRotated, s : Entry {
        s.outcome = Success
        s.ecred = r.successor
        r.prior = bindingOf[s.ePrincipal, s.earlier].bcred
    }
} for 3 but 5 Event

-- ShowReentry: a registration on the re-entry arm, binding a credential the deployment
-- registered for the pair first.
run ShowReentry {
    conforms
    some b : Binding | b.arm = Reentry
} for 3 but 5 Event

-- ShowReopen: a new credential registered after the revoke opens the gate again (Composes
-- 9; the deleted Invariant 1.3).
run ShowReopen {
    conforms
    some v : CredRevoked, r : CredRegistered, s : Entry {
        s.outcome = Success and s.ecred = r.cred
        v.revoked.owner = s.ePrincipal
        v in r.earlier and r in s.earlier
    }
} for 3 but 5 Event

-- ShowNotBound: an attestation for a principal never registered through the composition.
run ShowNotBound {
    conforms
    some e : Entry | e.outcome = NotBound
} for 3 but 5 Event

-- ShowInvalidAttestCredential: the gate open and Actor Identity's attest refusing the
-- attest credential.
run ShowInvalidAttestCredential {
    conforms
    some e : Entry | e.outcome = InvalidAttestCredential
} for 3 but 5 Event

-- ShowRegistryUnavailable: the gate open and the actor registry unreachable (Action wiring
-- 47).
run ShowRegistryUnavailable {
    conforms
    some e : Entry | e.outcome = RegistryUnavailable
} for 3 but 5 Event

-- ShowMechanismUnavailable: the gate open and the attestation mechanism unavailable (Action
-- wiring 49).
run ShowMechanismUnavailable {
    conforms
    some e : Entry | e.outcome = MechanismUnavailable
} for 3 but 5 Event

-- ShowTwoActors: two principals bound, each to its own actor reference.
run ShowTwoActors {
    conforms
    some disj b1, b2 : Binding | b1.bActor != b2.bActor
} for 3 but 5 Event

-- ShowForeignAttestation: an attestation another caller of Actor Identity made, whose actor
-- reference the inverse map does not carry (Non-goal 13).
run ShowForeignAttestation {
    conforms
    some a : Attestation | no xmap[a.actor] and a not in Entry.attestation
} for 3 but 5 Event

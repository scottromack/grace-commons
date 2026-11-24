-- capability-backed-sharing.als
-- Alloy structural model for the Capability-Backed Sharing composition (Grace Commons
-- compositions/capability-backed-sharing.md)
-- Alloy layer authored 2026-11-11 (unit `compositions/capability-backed-sharing.md formal layer`).
-- Derived validator; the English spec is the single source of truth. On any
-- disagreement, diagnose per the entry *The conflict protocol* in pressure-testing.md.
--
-- PURPOSE
-- Verify, by bounded exhaustive search, the STATIC data model of the composition: what one
-- state of its records must satisfy — the Capability records, the Selective Disclosure
-- records, the sharing events in the trail (the authorization and disclosure intents, the
-- outcomes the invocation's close, Recoverable Invocation's sweep or an operator wrote, and
-- the disclosure refusal records), the capability-to-sharing index and the
-- disclosure-to-redemption index — whatever admitted calls, sweeps and resolves wrote them,
-- and what [Sharing Disclosures] answers over that state at its now. How an invocation moves
-- through its open, its commit and its close, the sweep's timing, the pairing datum and the
-- ttl cap are the TLA+ model's, capability-backed-sharing.tla, which owns the operation
-- sequences.
--
-- RULES ENCODED (named by the page's own labels)
--   Invariant 1.1 — every claimable disclosure carries records naming the allocator as the
--                   authorizing party: its disclosure-to-redemption entry, and every
--                   disclosure event the invocation's close or the sweep wrote for it, name
--                   the capability's allocator reference (Check 1.1, Action wiring 36,
--                   Term disclosure probe, Composition state 10).
--   Invariant 1.2 — no record carries the redeemer: the disclosure intent, and every outcome
--                   the close or the sweep writes for it, are attested under the redemption
--                   identity or the recovery identity, never under the bearer who presented
--                   the token (Term redemption identity, Action wiring 23, Primitive
--                   policy 12).
--   Invariant 1.3 — every disclosure record the composition produces carries the
--                   capability's addressee as the recipient: the addressee the capability's
--                   scope parses to, and the one its authorization event names (Check 1.3).
--   Invariant 1.4 — the allocator-named claim [Sharing Disclosures] makes at its now is made
--                   only for a claimable disclosure (Action wiring 49, Composition state 21,
--                   Term claimable disclosure).
--   Invariant 2.1 — every disclosure event the close or the sweep wrote names a disclosure
--                   record (a cross-check with Outcome_names_record).
--   Invariant 2.2 — no disclosure record carries two disclosure events the close or the
--                   sweep wrote (a cross-check with Pairing_unique).
--   Invariant 2.3 — a committed disclosure whose disclosure event has not landed stands as a
--                   pending marker beside an intent no refusal and no outcome closed (a
--                   cross-check with Owed_outcome).
--   Invariant 3.1 — every authorization event the close or the sweep wrote names a capability
--                   token in the Capability records (a cross-check with Outcome_names_record).
--   Invariant 3.2 — every capability-to-sharing entry's token is named by exactly one
--                   authorization event the close or the sweep wrote (Check 3.2).
--   Invariant 3.3 — every authorization event carrying no recovery flag is attested under the
--                   capability's allocator, the one its entry carries (Check 3.3).
--   Invariant 3.5 — a disclosure record commits only under a token whose capability-to-sharing
--                   entry names an authorization event carrying no recovery flag (a
--                   cross-check with Disclosure_attested).
--   Invariant 4.1 — every disclosure record the composition produces carries the capability's
--                   disclosed scope as the scope: the one its scope parses to, and the one its
--                   authorization event names (Check 4.1).
--
-- NOT CHECKED HERE
--   Invariant 4.2 (disclosure events within the consumed count): the consumed count is
--   Capability's counter, moved by each redeem, and one state holds no redeem to count
--   against it; that a use is consumed only with its record is the disclosure transaction,
--   a step (Action wiring 31, 59), which the TLA+ model checks (Consumed_equals_disclosed).
--   An operator's closing (Recoverable Invocation resolve 28, 31): its payload is the
--   operator's, unchecked against the constituents, so Invariant 1.1, 2.1, 2.2, 3.1 and 3.2
--   are checked over the outcomes the close and the sweep wrote, and the operator's are
--   detected (the seal alert, the duplicate-authorization alert: the TLA+ model's); see
--   FOUND for 1.1. An operator's abandonment and the false-closing alert (Reconciliation 35)
--   are the TLA+ model's.
--
-- FOUND (recorded, not cured; see the Ledger's formal line)
--   Invariant 1.1 (Check 1.1: every claimable disclosure's disclosure event names an
--   allocator reference) holds only for the outcomes the close and the sweep write. An
--   operator's disclosure outcome is checked for its outcome reference alone (Recoverable
--   Invocation resolve 31), so it may name no allocator or another one, for a disclosure
--   that is claimable; the NOTEs under Invariant 2 and 3 make 2.1, 2.2, 3.1 and 3.2
--   detected, not prevented, for an operator's closing, but no NOTE, alert or check names
--   1.1, and the seal alert (Composition state 17) fires only for an outcome naming no
--   record or a second one. Run ShowOperatorNamesAnotherAllocator shows the state.
--
-- SCOPE
-- One state: up to three of each record, four parties (the redemption identity, the
-- recovery identity and two others: allocators, addressees, bearers and operators). Each
-- record is what its writer's rules let it be (`conforms`); some no run reaches. Instants
-- are not modelled: whether an event is aged at the state's now is a set the reader tests
-- (Term aged event), with no order between events, so the checks over-approximate the
-- clock. No trace, no `var`, no stepping.
--
-- NOT MODELED HERE
--   - [Revoke Sharing] and the revocation records: no rule this model checks reads them.
--   - The spent token, the ttl and the lapse (Action wiring 65 to 67, Term ttl cap): the
--     clock's passage, the TLA+ model's.
--   - The pairing datum and the probes' matching (Capability requirement 22, 23): the TLA+
--     model's (Pairing_unique); here the sweep's probe finds the intent's own record.
--   - The write-ownership leg and the alerts: an alert writes no record.
--
-- HOW TO READ RESULTS
-- Every "check A_*" must return "No counterexample found" (UNSAT) — the asserted guarantee holds.
-- Every "run Show*" must return at least one instance (SAT) — confirms non-vacuity.
-- A "check" returning a counterexample is a spec finding.

module capability_backed_sharing

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Party: anyone a record can name — an allocator, an addressee, a bearer who presents a
-- token, an operator, or one of the composition's own identities.
sig Party {}

-- RedemptionIdentity: the composition's own registered actor, under which [Redeem And
-- Disclose]'s intent and outcome are attested, the bearer presenting none (Term redemption
-- identity).
one sig RedemptionIdentity extends Party {}

-- RecoveryIdentity: the service identity of the three act kinds, under which the sweep
-- attests what it writes; never the redemption identity (Term recovery identity,
-- Capability requirement 26).
one sig RecoveryIdentity extends Party {}

-- Subject: a subject reference, the data subject a share discloses about.
sig Subject {}

-- Authority: the authority a sharing descriptor carries (its type and reference as one value).
sig Authority {}

-- Text: a string — a capability's scope (the encoded descriptor) or a disclosed scope. One
-- sig for both, so a record carrying the capability's whole scope where the disclosed scope
-- belongs is a state the model can build.
sig Text {
    -- parsed: what the sharing scope grammar parses this text back into, if it parses
    -- (Term sharing scope grammar; the deployment declares it, so no fact constrains it).
    parsed : lone Descriptor
}

-- Descriptor: a sharing descriptor — the subject reference, the addressee, the disclosed
-- scope and the authority (Term sharing descriptor) — with the grammar's encoding of it.
sig Descriptor {
    subject        : one Subject,
    addressee      : one Party,
    disclosedScope : one Text,
    authority      : one Authority,
    encoding       : one Text
}

-- Token: a capability token, compared byte-exact (Primitive policy 10).
sig Token {}

-- Capability: a capability record in the Capability instance: its token, its allocator
-- reference and its immutable scope (Capability, by possession).
sig Capability {
    token     : one Token,
    allocator : one Party,
    scope     : one Text
}

-- Writer: the model's own record of who wrote an outcome — the invocation's close, the
-- sweep (a recovered outcome) or an operator through the invocation resolve.
abstract sig Writer {}
one sig ByClose, BySweep, ByOperator extends Writer {}

-- Recovered: the recovery flag an outcome carries (Term recovery flag).
one sig Recovered {}

-- AuthIntent: a sharing.authorize.intended record — the open of a validated authorization,
-- attested under the actor reference it takes, carrying the sharing descriptor (Action
-- wiring 2). minted: the model's own, the capability its allocate minted (none: refused, or
-- never answered).
sig AuthIntent {
    actor      : one Party,
    descriptor : one Descriptor,
    minted     : lone Capability
}

-- AuthEvent: a sharing.authorize.authorized outcome — its intent, its writer, its recovery
-- flag, the principal it is attested under, and the capability token, the allocator
-- reference and the sharing descriptor it carries (Action wiring 8, Term authorization
-- probe).
sig AuthEvent {
    intent     : one AuthIntent,
    writer     : one Writer,
    recovery   : lone Recovered,
    attester   : one Party,
    token      : lone Token,
    allocator  : lone Party,
    descriptor : lone Descriptor
}

-- C2SEntry: a capability-to-sharing entry, keyed by its token, carrying the allocator
-- reference, the sharing descriptor and the authorization event id (Composition state 1
-- to 3).
sig C2SEntry {
    token      : one Token,
    allocator  : one Party,
    descriptor : one Descriptor,
    authEvent  : one AuthEvent
}

-- DiscIntent: a sharing.disclosure.intended record — the open of a resolved redemption,
-- under the actor reference it is attested by, carrying the capability token, the
-- allocator reference, the sharing descriptor and the authorization event id (Action
-- wiring 23). presenter: the model's own, the bearer who presented the token, whom no rule
-- lets a record name. committed: the model's own, the disclosure record its disclosure
-- transaction wrote (none: a pre-commit arm, or never answered).
sig DiscIntent {
    token      : one Token,
    allocator  : one Party,
    descriptor : one Descriptor,
    authEvent  : one AuthEvent,
    actor      : one Party,
    presenter  : one Party,
    committed  : lone DiscRecord
}

-- DiscRecord: a disclosure record in the Selective Disclosure instance: the subject
-- reference, the recipient, the scope and the authority (Action wiring 29).
sig DiscRecord {
    subject   : one Subject,
    recipient : one Party,
    scope     : one Text,
    authority : one Authority
}

-- DiscEvent: a sharing.disclosure.disclosed outcome — its intent, its writer, its recovery
-- flag, the principal it is attested under, the disclosure id it names and the allocator
-- reference it carries (Action wiring 36, Term disclosure probe).
sig DiscEvent {
    intent    : one DiscIntent,
    writer    : one Writer,
    recovery  : lone Recovered,
    attester  : one Party,
    record    : lone DiscRecord,
    allocator : lone Party
}

-- DiscRefusal: a sharing.disclosure.refused record — the invocation refuse closing a
-- pre-commit arm of its intent (Action wiring 26, 31, 64).
sig DiscRefusal {
    intent : one DiscIntent
}

-- D2REntry: a disclosure-to-redemption entry, keyed by its disclosure record, carrying the
-- capability token, the allocator reference, the intent and the seal marker: none for
-- pending, else the disclosure event (Composition state 8 to 10, Term seal marker).
sig D2REntry {
    record    : one DiscRecord,
    token     : one Token,
    allocator : one Party,
    intent    : one DiscIntent,
    seal      : lone DiscEvent
}

-- Clock: the state's now, read only as which sharing events it finds aged (Term aged event).
one sig Clock {
    aged : set (AuthEvent + DiscEvent)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- DescriptorIsItsValue: a sharing descriptor is its four fields; two with the same fields
-- are one descriptor (the model's representation of a value, no claim of the page).
fact DescriptorIsItsValue {
    all disj d1, d2 : Descriptor |
        d1.subject != d2.subject or d1.addressee != d2.addressee or
        d1.disclosedScope != d2.disclosedScope or d1.authority != d2.authority
}

-- CapabilityMintsFreshTokens: Capability mints a fresh token at each allocate, so two
-- capability records carry two tokens, and one allocate mints one capability (Capability's
-- own guarantee).
fact CapabilityMintsFreshTokens {
    all disj c1, c2 : Capability | c1.token != c2.token
    all c : Capability | lone minted.c
}

-- OneRecordPerWrite: Selective Disclosure mints a fresh disclosure id per record, so one
-- record is the write of at most one disclosure transaction (Selective Disclosure's own).
fact OneRecordPerWrite {
    all r : DiscRecord | lone committed.r
}

-- RecoveryFlagByWriter: Recoverable Invocation sets the recovery flag on the sweep's
-- recovered outcome and on an operator's closing, and on no outcome the invocation's own
-- close writes (Recoverable Invocation Term recovery, resolve 21).
fact RecoveryFlagByWriter {
    all e : AuthEvent | some e.recovery iff e.writer != ByClose
    all e : DiscEvent | some e.recovery iff e.writer != ByClose
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- capOf: the capability record carrying a token (Capability's read filtered to it,
-- Action wiring 13).
fun capOf[t : Token] : set Capability {
    { c : Capability | c.token = t }
}

-- c2sOf: the capability-to-sharing entry keyed by a token.
fun c2sOf[t : Token] : set C2SEntry {
    { en : C2SEntry | en.token = t }
}

-- writtenBy: the disclosure intent whose transaction wrote a record (none: a write outside
-- the composition's surface).
fun writtenBy[r : DiscRecord] : set DiscIntent {
    committed.r
}

-- eventsNaming: the disclosure events naming a record's disclosure id.
fun eventsNaming[r : DiscRecord] : set DiscEvent {
    { e : DiscEvent | e.record = r }
}

-- closingsOf: every record closing a disclosure intent — its outcomes and its refusals.
fun closingsOf[i : DiscIntent] : set (DiscEvent + DiscRefusal) {
    { e : DiscEvent | e.intent = i } + { f : DiscRefusal | f.intent = i }
}

-- claimable: Term claimable disclosure — a capability-backed disclosure whose authorization
-- event is not aged and whose disclosure event, where one has landed, is not aged.
pred claimable[r : DiscRecord] {
    some writtenBy[r]
    writtenBy[r].authEvent not in Clock.aged
    no (eventsNaming[r] & Clock.aged)
}

-- c2sAnswer: the capability-to-sharing entry the composition answers for a token: none
-- where the token's authorization event is aged (Composition state 21).
fun c2sAnswer[t : Token] : set C2SEntry {
    { en : c2sOf[t] | en.authEvent not in Clock.aged }
}

-- history: the allocator-named claims [Sharing Disclosures] makes at the state's now — each
-- record whose disclosure is claimable joined to its disclosure-to-redemption entry's
-- allocator reference, read through the index the composition answers and the disclosure
-- events in the trail; every other record is carried with no allocator named (Action
-- wiring 49).
fun history : DiscRecord -> Party {
    { r : DiscRecord, a : Party |
        some en : D2REntry | en.record = r and en.allocator = a
            and some c2sAnswer[en.token]
            and no (eventsNaming[r] & Clock.aged) }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The writers: what each record may be
-- ─────────────────────────────────────────────────────────────────────────────

-- authIntentWrites: an authorization's open and its allocate — the descriptor's encoding
-- parses back into the same descriptor (Primitive policy 5, 7), the open is attested under
-- the allocator reference it takes (Action wiring 2), and the allocate mints a capability
-- under that allocator reference with the encoded descriptor as its scope (Action wiring 4).
pred authIntentWrites[i : AuthIntent] {
    i.descriptor.encoding.parsed = i.descriptor            -- Primitive policy 5
    some i.minted implies {
        i.minted.allocator = i.actor                       -- Action wiring 4
        i.minted.scope = i.descriptor.encoding             -- Action wiring 4
    }
}

-- authEventWrites: an authorization outcome — the close's for an allocate that answered its
-- token, under the allocator's credential, carrying the token, the allocator and the
-- descriptor (Action wiring 8, Term sharing bindings); the sweep's for an intent whose
-- probe found its capability, under the recovery identity, carrying what the probe read
-- (Term authorization probe); an operator's, under the operator's own credential, its
-- payload unchecked (Recoverable Invocation resolve 21, 31). Each writes only for an intent
-- no other outcome closed (Recoverable Invocation: one closing per intent).
pred authEventWrites[e : AuthEvent] {
    let i = e.intent {
        e.writer = ByClose implies {
            some i.minted                                  -- Action wiring 8
            e.token = i.minted.token
            e.attester = i.actor                           -- Term sharing bindings
            e.allocator = i.actor
            e.descriptor = i.descriptor
        }
        e.writer = BySweep implies {
            some i.minted                                  -- the probe answers committed
            e.token = i.minted.token
            e.attester = RecoveryIdentity                  -- Term recovery identity
            e.allocator = i.minted.allocator
            e.descriptor = i.minted.scope.parsed
        }
        e.writer = ByOperator implies
            e.attester not in RedemptionIdentity + RecoveryIdentity
        all e2 : AuthEvent - e | e2.intent != i            -- one closing per intent
    }
}

-- c2sWrites: a capability-to-sharing entry — written from an authorization event carrying
-- no recovery flag, its fields that event's (Composition state 3, 4, 6), one per token
-- (Composition state 2).
pred c2sWrites[en : C2SEntry] {
    no en.authEvent.recovery                               -- Composition state 6
    en.token = en.authEvent.token
    en.allocator = en.authEvent.allocator
    en.descriptor = en.authEvent.descriptor
    one c2sOf[en.token]                                    -- Composition state 2
}

-- discIntentWrites: a redemption's resolution and open — the token's capability read, its
-- scope parsed (Action wiring 13 to 15), its entry attested and agreeing with the
-- capability (Action wiring 17 to 20), the open under the redemption identity carrying the
-- token, the entry's allocator and authorization event id and the parsed descriptor
-- (Action wiring 23); then the disclosure transaction's record, its fields the descriptor's,
-- the addressee as the recipient (Action wiring 29).
pred discIntentWrites[i : DiscIntent] {
    let c = capOf[i.token], en = c2sOf[i.token] {
        some c                                             -- Action wiring 14
        some c.scope.parsed                                -- Action wiring 15
        some en                                            -- Action wiring 17, 18
        en.descriptor = c.scope.parsed                     -- Action wiring 19, 20
        en.allocator = c.allocator                         -- Action wiring 19, 20
        i.descriptor = c.scope.parsed                      -- Action wiring 12
        i.allocator = en.allocator                         -- Action wiring 23
        i.authEvent = en.authEvent                         -- Action wiring 23
        i.actor = RedemptionIdentity                       -- Action wiring 23
        some i.committed implies {
            i.committed.subject = i.descriptor.subject     -- Action wiring 29
            i.committed.recipient = i.descriptor.addressee
            i.committed.scope = i.descriptor.disclosedScope
            i.committed.authority = i.descriptor.authority
        }
    }
}

-- discEventWrites: a disclosure outcome — the close's for a transaction that answered its
-- disclosure id, under the redemption identity, carrying the id and the allocator (Action
-- wiring 36); the sweep's for an intent whose probe found its record, under the recovery
-- identity, carrying the allocator Capability's read of the intent's token answers (Term
-- disclosure probe); an operator's, its payload unchecked. Each only for an intent no other
-- closing closed.
pred discEventWrites[e : DiscEvent] {
    let i = e.intent {
        e.writer = ByClose implies {
            some i.committed                               -- Action wiring 36
            e.record = i.committed
            e.attester = i.actor                           -- Term sharing bindings
            e.allocator = i.allocator
        }
        e.writer = BySweep implies {
            some i.committed                               -- the probe answers committed
            e.record = i.committed
            e.attester = RecoveryIdentity                  -- Term recovery identity
            e.allocator = capOf[i.token].allocator         -- Term disclosure probe
        }
        e.writer = ByOperator implies
            e.attester not in RedemptionIdentity + RecoveryIdentity
        closingsOf[i] = e                                  -- one closing per intent
    }
}

-- discRefusalWrites: the invocation refuse closes only a pre-commit arm, the transaction
-- having committed nothing (Action wiring 26, 31, 64), and only an intent no other
-- closing closed.
pred discRefusalWrites[f : DiscRefusal] {
    no f.intent.committed                                  -- Action wiring 31, 64
    closingsOf[f.intent] = f
}

-- d2rWrites: a disclosure-to-redemption entry — written inside the disclosure transaction
-- for its record, carrying the intent's token and allocator (Composition state 10, 12), one
-- per record (Composition state 9); its seal marker, once set, a disclosure event naming
-- the record (Composition state 13, 16).
pred d2rWrites[en : D2REntry] {
    en.intent.committed = en.record                        -- Composition state 12
    en.token = en.intent.token                             -- Composition state 10
    en.allocator = en.intent.allocator
    en.seal in eventsNaming[en.record]                     -- Composition state 13, 16
    all en2 : D2REntry - en | en2.record != en.record      -- Composition state 9
}

-- conforms: every record in the state is one its writer's rules let it write, and every
-- committed disclosure has its entry (Action wiring 59).
pred conforms {
    all i : AuthIntent | authIntentWrites[i]
    all e : AuthEvent | authEventWrites[e]
    all en : C2SEntry | c2sWrites[en]
    all i : DiscIntent | discIntentWrites[i]
    all e : DiscEvent | discEventWrites[e]
    all f : DiscRefusal | discRefusalWrites[f]
    all en : D2REntry | d2rWrites[en]
    all i : DiscIntent | some i.committed implies some en : D2REntry | en.intent = i
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's writers can leave that violates
-- this assertion? No counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: every claimable disclosure carries records naming its capability's
-- allocator as the authorizing party — its disclosure-to-redemption entry, and every
-- disclosure event the close or the sweep wrote for it.
assert A_Invariant_1_1 {
    conforms implies all r : DiscRecord | claimable[r] implies
        (let a = capOf[writtenBy[r].token].allocator {
            some en : D2REntry | en.record = r and en.allocator = a
            all e : eventsNaming[r] | e.writer != ByOperator implies e.allocator = a
        })
}
check A_Invariant_1_1 for 3 but 4 Party

-- A_Invariant_1_2: no record carries the bearer who redeemed — every disclosure intent is
-- attested under the redemption identity, and every outcome the close or the sweep wrote
-- for it under the redemption identity or the recovery identity, whoever presented the token.
assert A_Invariant_1_2 {
    conforms implies all i : DiscIntent {
        i.actor = RedemptionIdentity
        all e : DiscEvent | e.intent = i and e.writer != ByOperator implies
            e.attester in RedemptionIdentity + RecoveryIdentity
    }
}
check A_Invariant_1_2 for 3 but 4 Party

-- A_Invariant_1_3: every disclosure record the composition produced carries as its recipient
-- the addressee its capability's scope parses to and the one its authorization event names.
assert A_Invariant_1_3 {
    conforms implies all r : DiscRecord | some writtenBy[r] implies {
        r.recipient = capOf[writtenBy[r].token].scope.parsed.addressee
        r.recipient = writtenBy[r].authEvent.descriptor.addressee
    }
}
check A_Invariant_1_3 for 3 but 4 Party

-- A_Invariant_1_4: [Sharing Disclosures] names an allocator only for a disclosure that is
-- claimable at its now.
assert A_Invariant_1_4 {
    conforms implies all r : DiscRecord | some history[r] implies claimable[r]
}
check A_Invariant_1_4 for 3 but 4 Party

-- A_Invariant_2_1: every disclosure event the close or the sweep wrote names a disclosure
-- record.
assert A_Invariant_2_1 {
    conforms implies all e : DiscEvent | e.writer != ByOperator implies some e.record
}
check A_Invariant_2_1 for 3 but 4 Party

-- A_Invariant_2_2: no disclosure record carries two disclosure events the close or the
-- sweep wrote.
assert A_Invariant_2_2 {
    conforms implies all r : DiscRecord |
        lone { e : eventsNaming[r] | e.writer != ByOperator }
}
check A_Invariant_2_2 for 3 but 4 Party

-- A_Invariant_2_3: a committed disclosure no disclosure event names stands as a pending
-- marker, its intent closed by no refusal and no outcome of the close or the sweep (an
-- operator's closing of it is the false closing Reconciliation 35 alerts).
assert A_Invariant_2_3 {
    conforms implies all r : DiscRecord | (some writtenBy[r] and no eventsNaming[r]) implies {
        some en : D2REntry | en.record = r and no en.seal
        no { f : DiscRefusal | f.intent = writtenBy[r] }
        no { e : DiscEvent | e.intent = writtenBy[r] and e.writer != ByOperator }
    }
}
check A_Invariant_2_3 for 3 but 4 Party

-- A_Invariant_3_1: every authorization event the close or the sweep wrote names a token
-- the Capability records carry.
assert A_Invariant_3_1 {
    conforms implies all e : AuthEvent | e.writer != ByOperator implies
        (some e.token and some capOf[e.token])
}
check A_Invariant_3_1 for 3 but 4 Party

-- A_Invariant_3_2: every capability-to-sharing entry's token is named by exactly one
-- authorization event the close or the sweep wrote.
assert A_Invariant_3_2 {
    conforms implies all en : C2SEntry |
        one { e : AuthEvent | e.token = en.token and e.writer != ByOperator }
}
check A_Invariant_3_2 for 3 but 4 Party

-- A_Invariant_3_3: every authorization event carrying no recovery flag is attested under
-- its capability's allocator, the allocator its capability-to-sharing entry carries.
assert A_Invariant_3_3 {
    conforms implies all e : AuthEvent | no e.recovery implies {
        e.attester = capOf[e.token].allocator
        all en : c2sOf[e.token] | en.allocator = e.attester
    }
}
check A_Invariant_3_3 for 3 but 4 Party

-- A_Invariant_3_5: a disclosure record the composition produced stands under a token whose
-- capability-to-sharing entry names an authorization event carrying no recovery flag.
assert A_Invariant_3_5 {
    conforms implies all r : DiscRecord | some writtenBy[r] implies
        some en : c2sOf[writtenBy[r].token] | no en.authEvent.recovery
}
check A_Invariant_3_5 for 3 but 4 Party

-- A_Invariant_4_1: every disclosure record the composition produced carries as its scope
-- the disclosed scope its capability's scope parses to and the one its authorization event
-- names.
assert A_Invariant_4_1 {
    conforms implies all r : DiscRecord | some writtenBy[r] implies {
        r.scope = capOf[writtenBy[r].token].scope.parsed.disclosedScope
        r.scope = writtenBy[r].authEvent.descriptor.disclosedScope
    }
}
check A_Invariant_4_1 for 3 but 4 Party

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (each shape the page admits is reachable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowSealedDisclosure: a disclosure whose close landed its event, the entry sealed with it,
-- answered with its allocator.
run ShowSealedDisclosure {
    conforms
    some en : D2REntry | some en.seal and en.seal.writer = ByClose and some history[en.record]
} for 3 but 4 Party

-- ShowPendingDisclosure: a committed disclosure whose event has not landed — a pending
-- marker beside an open intent (Invariant 2.3's shape).
run ShowPendingDisclosure {
    conforms
    some r : DiscRecord | some writtenBy[r] and no eventsNaming[r] and no closingsOf[writtenBy[r]]
} for 3 but 4 Party

-- ShowRecoveredDisclosure: a disclosure whose outcome the sweep recovered, naming the
-- allocator.
run ShowRecoveredDisclosure {
    conforms
    some e : DiscEvent | e.writer = BySweep and some e.allocator
} for 3 but 4 Party

-- ShowRefusedRedemption: a redemption refused at the commit, its intent closed by a refusal
-- record and no disclosure record written.
run ShowRefusedRedemption {
    conforms
    some f : DiscRefusal | no f.intent.committed
} for 3 but 4 Party

-- ShowRecoveredAuthorizationUnattested: a capability whose only authorization event the
-- sweep recovered — no entry binds it, so no disclosure stands under it (Composition state 6).
run ShowRecoveredAuthorizationUnattested {
    conforms
    some e : AuthEvent | e.writer = BySweep and no c2sOf[e.token]
} for 3 but 4 Party

-- ShowMultiUse: two disclosures under one capability, each its own record (Multi-use
-- capabilities).
run ShowMultiUse {
    conforms
    some disj r1, r2 : DiscRecord | some writtenBy[r1] and some writtenBy[r2]
        and writtenBy[r1].token = writtenBy[r2].token
} for 3 but 4 Party

-- ShowAgedCarriedUnnamed: a disclosure whose authorization event has aged, carried in the
-- history with no allocator named (Action wiring 49, Composition state 21).
run ShowAgedCarriedUnnamed {
    conforms
    some r : DiscRecord | some writtenBy[r] and writtenBy[r].authEvent in Clock.aged
        and no history[r]
} for 3 but 4 Party

-- ShowOutsideRecord: a disclosure record written outside the composition's surface, no
-- intent carrying it (Reconciliation 34's write-ownership finding).
run ShowOutsideRecord {
    conforms
    some r : DiscRecord | no writtenBy[r]
} for 3 but 4 Party

-- ShowOperatorNamesAnotherAllocator: the shape FOUND names — an operator's disclosure
-- outcome for a claimable disclosure naming an allocator other than the capability's.
run ShowOperatorNamesAnotherAllocator {
    conforms
    some e : DiscEvent | e.writer = ByOperator and some e.record and claimable[e.record]
        and e.allocator != capOf[writtenBy[e.record].token].allocator
} for 3 but 4 Party

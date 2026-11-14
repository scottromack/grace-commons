-- chain-of-custody-buggy-purged-payload-checked.als
-- DELIBERATELY WRONG twin of chain-of-custody.als (unit: compositions/chain-of-custody.md formal layer).
--
-- INJECTED DEFECT: [Verify Custody] checks the original event payloads for a Purged event and lands payload-not-supplied where its range is not presented (Action wiring 40, 39).
--
-- BREAKS: A_Invariant_3_2.
-- Everything else is chain-of-custody.als as written; read its comments there.

module chain_of_custody_buggy_purged_payload_checked

open util/integer

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Actor: whoever an outcome event's attestation names — a custodian, the recovery identity
-- the sweep writes under (Term recovery identity), or an operator resolving an intent.
abstract sig Actor {}

-- Custodian: an opaque custodian reference (Term custodian reference), compared byte-exact.
sig Custodian extends Actor {}

-- RecoveryIdentity: the deployment-provisioned actor the sweep attests under (Capability
-- requirement 15).
one sig RecoveryIdentity extends Actor {}

-- OperatorActor: the operator who closes or abandons an intent through the invocation resolve.
one sig OperatorActor extends Actor {}

-- Artifact: an opaque artifact reference (Term artifact reference).
sig Artifact {}

-- Descriptor: a transformation descriptor (Term transformation descriptor).
sig Descriptor {}

-- Now: an instant — an invocation's injected now, its pairing datum, and an entry's
-- recording instant. Compared for equality only.
sig Now {}

-- EntryId: the opaque id Provenance mints for an entry (Term entry id). An outcome event
-- carries one, which may name no entry the chain holds (Invariant 4.4).
sig EntryId {}

-- GenesisLookup: present when the deployment supplies the genesis lookup (Capability
-- requirement 22), the originate probe's read.
lone sig GenesisLookup {}

-- Chain: a custody chain, its chain id minted by an origination, for one artifact.
sig Chain {
    artifact : one Artifact
}

-- EType: an entry's event type (Provenance's): the two genesis types, transferred and
-- transformed (transformed standing for the three custodian-guarded steps).
abstract sig EType {}
one sig Originated, Received, Transferred, Transformed extends EType {}

-- Entry: one Provenance entry: its id, chain, sequence number, event type, the custodian
-- reference (a genesis or transformed entry), the outgoing and incoming custodians (a
-- transferred entry), the descriptor (a transformed entry), the recording instant, the holder
-- the chain shows after it, and — a ghost — the invocation whose commit wrote it (none: a
-- write outside every invocation).
sig Entry {
    id     : one EntryId,
    chain  : one Chain,
    sn     : one Int,
    etype  : one EType,
    cust   : lone Custodian,
    from   : lone Custodian,
    to     : lone Custodian,
    desc   : lone Descriptor,
    at     : one Now,
    holder : one Custodian,
    by     : lone Intent
}

-- Young, Aged: the entries whose recording instant the sweep's now reads as young or aged
-- (Term young entry, Term aged entry). The clock's; inputs.
sig Young in Entry {}
sig Aged in Entry {}

-- Settled: the entries settled at the auditor's read (Term settled entry). The clock's; an input.
sig Settled in Entry {}

-- Kind: an intent's act kind: custody.originate, custody.transfer, and custody.transform
-- standing for the three custodian-guarded kinds.
abstract sig Kind {}
one sig KOrig, KXfer, KXform extends Kind {}

-- IState: where an intent stands (the states Invariant 1.1 and Check 5.9 name): open, closed
-- by an outcome, escalated, abandoned, refused.
abstract sig IState {}
one sig IOpen, IClosed, IEscalated, IAbandoned, IRefused extends IState {}

-- Intent: one intent record the invocation open wrote: its act kind, the actor reference it
-- was attested under, its act key and intent data (a chain id; or, for an origination, the
-- artifact, the custodian reference and the genesis type), a transfer's outgoing and incoming
-- custodians, a transformation's custodian and descriptor, its pairing datum; for a transfer,
-- the entry its resolution read saw as the chain's latest; and where it stands.
sig Intent {
    kind       : one Kind,
    actor      : one Custodian,
    key        : lone Chain,
    art        : lone Artifact,
    cref       : lone Custodian,
    gtype      : lone EType,
    out        : lone Custodian,
    inc        : lone Custodian,
    xdesc      : lone Descriptor,
    datum      : one Now,
    resolvedOn : lone Entry,
    state      : one IState
}

-- Writer: who wrote an outcome event: the invocation close, the sweep (under the recovery
-- identity) or an operator (through the invocation resolve).
abstract sig Writer {}
one sig ByClose, BySweep, ByOperator extends Writer {}

-- ORef: an outcome event's action reference (Term value sets).
abstract sig ORef {}
one sig ROriginated, RReceived, RTransferred, RTransformed extends ORef {}

-- RAns: what Audit Trail's record read answers for a bound event: Retained, unresolved in
-- its compensation window, Purged, or not-known. Audit Trail's; an input.
abstract sig RAns {}
one sig RRetained, RUnresolved, RPurged, RNotKnown extends RAns {}

-- AVal: an attestation verification (Term attestation verification): one of the outcomes
-- Audit Trail's verification answers, payload-not-supplied, or unknown carrying not-known.
abstract sig AVal {}
one sig VVerified, VFailPurged, VFailAttestation, VFailSeal, VFailUnsealed, VUnverifiable,
        PayloadNotSupplied, AVUnknownNotKnown extends AVal {}

-- EPM: an entry payload match (Term entry payload match).
abstract sig EPM {}
one sig EMatch, EMismatch, EUnanchored, ENAPurged extends EPM {}

-- AM: an actor match (Term actor match).
abstract sig AM {}
one sig AMatch, AMatchRecovery, AMismatch, AMUnknownPurged, AMUnknownNotKnown extends AM {}

-- RA: a recovery attestation (Term recovery attestation).
abstract sig RA {}
one sig RATrue, RAFalse, RAUnknownPurged, RAUnknownNotKnown extends RA {}

-- BStat: the binding class of an entry with no binding after the rebuild (Action wiring 36, 37).
abstract sig BStat {}
one sig BGap, BUnknown extends BStat {}

-- Outcome: one outcome event: its action reference, the chain id and entry id it carries
-- (Action wiring 5), its attesting actor, who wrote it, the intent it closes, its audit-log
-- sequence number; and, for [Verify Custody], what Audit Trail's record read answers for it,
-- what the verification answers where called, and how the entry's compared fields compare
-- with its payload (Action wiring 45). The last three are Audit Trail's and the payload's.
sig Outcome {
    oref     : one ORef,
    ochain   : one Chain,
    oentry   : one EntryId,
    attester : one Actor,
    writer   : one Writer,
    intent   : one Intent,
    oseq     : one Int,
    rread    : one RAns,
    vout     : one AVal,
    cmp      : one EPM
}

-- Recovered: the outcome events carrying the recovery flag (Term recovery flag).
sig Recovered in Outcome {}

-- Partly: the bound events the record read answers partially-purged coverage for.
sig Partly in Outcome {}

-- Presented: the bound events every member of whose whole covering range the original event
-- payloads carry (Action wiring 41, 42). The caller's; an input.
sig Presented in Outcome {}

-- Finding: the entries the leg opened a write-ownership finding for (Reconciliation 11).
sig Finding in Entry {}

-- Alerted: the entries the leg alerted the finding surface for as a false closing
-- (Reconciliation 32).
sig Alerted in Entry {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers: the page's terms over one state
-- ─────────────────────────────────────────────────────────────────────────────

-- Genesis: the two genesis types (Term genesis type).
fun Genesis : set EType { Originated + Received }

-- Live: the record read's answers for a live event (Term live event).
fun Live : set RAns { RRetained + RUnresolved }

-- VerifyOutcomes: the outcomes Audit Trail's verification answers.
fun VerifyOutcomes : set AVal {
    VVerified + VFailPurged + VFailAttestation + VFailSeal + VFailUnsealed + VUnverifiable
}

-- prev: the entry before e in its chain (the chain's latest when e was appended).
fun prev[e : Entry] : set Entry { { p : Entry | p.chain = e.chain and p.sn = minus[e.sn, 1] } }

-- refFor: the outcome reference an entry's event type takes (Action wiring 15, 26, 66).
fun refFor[e : Entry] : one ORef {
    (e.etype = Originated) => ROriginated
    else ((e.etype = Received) => RReceived
    else ((e.etype = Transferred) => RTransferred else RTransformed))
}

-- refsOf: the outcome references of an act kind (Term custody bindings).
fun refsOf[k : Kind] : set ORef {
    (k = KOrig) => ROriginated + RReceived else ((k = KXfer) => RTransferred else RTransformed)
}

-- attested: an entry's attested custodian (Term attested custodian): a transferred entry's
-- outgoing custodian, another entry's custodian reference.
fun attested[e : Entry] : set Custodian { (e.etype = Transferred) => e.from else e.cust }

-- carriedBy: the intents that make e a carried entry (Term carried entry): of the act kind e's
-- event type names; for a genesis entry, an origination intent whose act key carries e's
-- custodian reference and genesis type; for any other, an intent whose act key is e's chain
-- id; in either case one whose pairing datum equals e's recording instant.
fun carriedBy[e : Entry] : set Intent {
    { i : Intent | i.datum = e.at
        and (e.etype in Genesis implies (i.kind = KOrig and i.cref = e.cust and i.gtype = e.etype))
        and (e.etype = Transferred implies (i.kind = KXfer and i.key = e.chain))
        and (e.etype = Transformed implies (i.kind = KXform and i.key = e.chain)) }
}

-- outcomesFor: the outcome events carrying e's entry id.
fun outcomesFor[e : Entry] : set Outcome { oentry.(e.id) }

-- orphan: an entry carrying no outcome event (Term orphan entry).
pred orphan[e : Entry] { no outcomesFor[e] }

-- examined: an entry the leg reads, neither young nor aged (Reconciliation 4, 7, 34).
fun examined : set Entry { Entry - Young - Aged }

-- probe: the entries the act probe matches for intent i. The originate probe (Term originate
-- probe): through the genesis lookup, the chains for the intent's artifact, each one's entry
-- at sequence number one of the intent's genesis type at its pairing datum, carrying its
-- custodian reference; none where the deployment supplies no lookup (undecidable,
-- Recoverable Invocation Deviation 4c). The step probe (Term step probe): the intent's chain,
-- the kind's event type, the pairing datum, the intent's parameters.
fun probe[i : Intent] : set Entry {
    (i.kind = KOrig) =>
        ((some GenesisLookup) =>
            { e : Entry | e.chain.artifact = i.art and e.sn = 1 and e.etype = i.gtype
                          and e.at = i.datum and e.cust = i.cref }
         else none)
    else ((i.kind = KXfer) =>
        { e : Entry | e.chain = i.key and e.etype = Transferred and e.at = i.datum
                      and e.from = i.out and e.to = i.inc }
    else
        { e : Entry | e.chain = i.key and e.etype = Transformed and e.at = i.datum
                      and e.cust = i.cref and e.desc = i.xdesc })
}

-- probeChain: the chain id a committed probe answer carries: the matched genesis entry's
-- chain for an origination, the intent's act key otherwise (the probe reads that chain).
fun probeChain[i : Intent] : set Chain {
    (i.kind = KOrig) => probe[i].chain else i.key
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- Provenance mints each entry its own id, numbers a chain's entries from one without a gap,
-- opens a chain with one genesis entry at sequence number one, and writes each type's fields
-- (Provenance's records and Invariant 4).
fact ProvenanceRecords {
    all disj e1, e2 : Entry | e1.id != e2.id
    all disj e1, e2 : Entry | e1.chain = e2.chain implies e1.sn != e2.sn
    all e : Entry | e.sn >= 1 and (e.sn > 1 implies some prev[e])
    all e : Entry | e.sn = 1 iff e.etype in Genesis
    all c : Chain | some chain.c
    all e : Entry | e.etype in Genesis implies (some e.cust and no e.from and no e.to and no e.desc)
    all e : Entry | e.etype = Transferred implies (no e.cust and some e.from and some e.to and no e.desc)
    all e : Entry | e.etype = Transformed implies (some e.cust and no e.from and no e.to and some e.desc)
}

-- Provenance keeps the chain: the holder after a genesis is its custodian, after a transfer
-- its incoming custodian, and a transformation leaves it; a transfer's outgoing custodian is
-- read from chain state, and only the holder may transform (Provenance Invariant 4 and its
-- holder guard).
fact ProvenanceKeepsTheChain {
    all e : Entry | e.etype in Genesis implies e.holder = e.cust
    all e : Entry | e.etype = Transferred implies (e.holder = e.to and e.from = prev[e].holder)
    all e : Entry | e.etype = Transformed implies (e.holder = prev[e].holder and e.cust = prev[e].holder)
}

-- A commit appends one entry (Provenance's write), and Event Log numbers each outcome event
-- with its own sequence number (Event Log Invariant 3).
fact OneEntryPerCommit {
    all i : Intent | lone by.i
    all disj o1, o2 : Outcome | o1.oseq != o2.oseq
}

-- The host injects the invocation's now into Provenance's seam, so the entry an invocation
-- wrote carries its pairing datum as its recording instant (Capability requirement 34), and
-- never an equal now into two invocations of one act key, nor into two originations of one
-- custodian reference and genesis type (Capability requirement 35).
fact HostInjectsNow {
    all e : Entry | some e.by implies e.at = e.by.datum
    all disj i1, i2 : Intent | (i1.kind = i2.kind and i1.kind != KOrig and i1.key = i2.key)
        implies i1.datum != i2.datum
    all disj i1, i2 : Intent | (i1.kind = KOrig and i2.kind = KOrig and i1.cref = i2.cref
        and i1.gtype = i2.gtype) implies i1.datum != i2.datum
}

-- Recoverable Invocation's outcome shape and closing: the invocation close attests under the
-- intent's actor reference with no recovery flag; the sweep under the recovery identity, the
-- operator under the operator's own credential, both with it (Term outcome shape, resolve 21);
-- an intent stands closed exactly when an outcome closes it, one closing per intent; and an
-- operator's outcome reference is one of the kind's (resolve 31).
fact RecoverableInvocationOutcomes {
    all o : Outcome | o.writer = ByClose implies (o.attester = o.intent.actor and o not in Recovered)
    all o : Outcome | o.writer = BySweep implies (o.attester = RecoveryIdentity and o in Recovered)
    all o : Outcome | o.writer = ByOperator implies (o.attester = OperatorActor and o in Recovered)
    all i : Intent | lone intent.i
    all i : Intent | i.state = IClosed iff some intent.i
    all o : Outcome | o.writer = ByOperator implies o.oref in refsOf[o.intent.kind]
}

-- The young and aged edges are the clock's: an entry is not both.
fact ClockEdges {
    no Young & Aged
}

-- Audit Trail's verification answers failed-verification(purged) for a Purged event and only
-- for one (Audit Trail verify record step 1.2, Invariant 8.4); partially-purged coverage is
-- answered for a live event; the payload comparison answers match or mismatch.
fact AuditTrailAnswers {
    all o : Outcome | o.vout in VerifyOutcomes
    all o : Outcome | o.rread = RPurged iff o.vout = VFailPurged
    all o : Partly | o.rread in Live
    all o : Outcome | o.cmp in EMatch + EMismatch
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part A — the writes: what each admitted write leaves
-- ─────────────────────────────────────────────────────────────────────────────

-- openWiring: what the invocation open was called with (Action wiring 12, 20, 27; Primitive
-- policy 16; Wiring decision 3 through 6). An origination: the origination key, the custodian
-- reference as the actor. A transfer: the chain id, the custodian its resolution read showed
-- as holder (Term resolved custodian) as the actor and the outgoing custodian, the incoming
-- custodian. A transformation: the chain id, the custodian reference as the actor, the
-- descriptor.
pred openWiring[i : Intent] {
    i.kind = KOrig implies {
        no i.key and some i.art and some i.cref and i.gtype in Genesis
        i.actor = i.cref
        no i.out and no i.inc and no i.xdesc and no i.resolvedOn
    }
    i.kind = KXfer implies {
        some i.key and one i.resolvedOn and i.resolvedOn.chain = i.key
        i.out = i.resolvedOn.holder
        i.actor = i.out
        some i.inc
        no i.art and no i.cref and no i.gtype and no i.xdesc
    }
    i.kind = KXform implies {
        some i.key and some i.cref and some i.xdesc
        i.actor = i.cref
        no i.art and no i.gtype and no i.out and no i.inc and no i.resolvedOn
    }
}

-- commitWiring: what the intent's commit wrote, if anything. A refused intent wrote nothing
-- (Action wiring 9). An origination appends a genesis entry of its custodian and genesis type
-- on a chain for its artifact (Action wiring 13). A transfer appends after the entry then
-- latest, which is the one its resolution read saw or a later one, only where the re-read
-- inside the transfer transaction finds the intent's outgoing custodian still the holder
-- (Action wiring 21, 63, 65). A transformation appends its custodian and descriptor (Action
-- wiring 28).
pred commitWiring[i : Intent] {
    i.state = IRefused implies no by.i
    all e : by.i {
        i.kind = KOrig implies (e.etype = i.gtype and e.cust = i.cref and e.chain.artifact = i.art)
        i.kind = KXfer implies {
            e.chain = i.key and e.etype = Transferred and e.to = i.inc
            i.resolvedOn.sn <= prev[e].sn
            prev[e].holder = i.out
        }
        i.kind = KXform implies
            (e.chain = i.key and e.etype = Transformed and e.cust = i.cref and e.desc = i.xdesc)
    }
}

-- closeWiring: the invocation close after a committed arm names the entry the commit
-- answered, its chain, and the outcome reference its event type takes (Action wiring 5, 15,
-- 26, 66).
pred closeWiring[o : Outcome] {
    some by.(o.intent)
    o.oentry = (by.(o.intent)).id
    o.ochain = (by.(o.intent)).chain
    o.oref = refFor[by.(o.intent)]
}

-- sweepWiring: the sweep writes the recovered outcome only on a committed probe — exactly one
-- entry matched — naming the chain id and entry id the probe answered and the outcome
-- reference re-derived from the entry (Term originate probe, Term step probe; Recoverable
-- Invocation reconcile step 3.2, act probe 6).
pred sweepWiring[o : Outcome] {
    one probe[o.intent]
    o.oentry = probe[o.intent].id
    o.ochain = probeChain[o.intent]
    o.oref = refFor[probe[o.intent]]
}

-- legWiring: over the entries it examines, the leg opens a write-ownership finding for each
-- that is no carried entry (Reconciliation 7, 11) and alerts each carried entry whose carrying
-- intent an abandonment or a refusal closed (Reconciliation 32, Term false closing).
pred legWiring {
    Finding = { e : examined | no carriedBy[e] }
    Alerted = { e : examined | some i : carriedBy[e] | i.state in IAbandoned + IRefused }
}

-- built: every record in the state is what an admitted write left: each intent's open and
-- commit, each outcome by its writer's rule, and the leg's findings and alerts.
pred built {
    all i : Intent | openWiring[i] and commitWiring[i]
    all o : Outcome | o.writer = ByClose implies closeWiring[o]
    all o : Outcome | o.writer = BySweep implies sweepWiring[o]
    legWiring
}

-- operatorNamesItsEntry: every operator's outcome names an entry its intent carries, with the
-- outcome reference that entry's event type takes. The page relies on it and states it
-- nowhere: Recoverable Invocation resolve 28 and 31 do not check it (finding (a), header).
pred operatorNamesItsEntry {
    all o : Outcome | o.writer = ByOperator implies
        some e : Entry | o.intent in carriedBy[e] and o.oentry = e.id and o.oref = refFor[e]
}

-- outsideWritesOffDatum: no entry an invocation did not write is a carried entry — a write
-- outside the composition's surface never takes the pairing datum of an intent of its act
-- key. The page relies on it and states it nowhere (finding (b), header).
pred outsideWritesOffDatum {
    all e : Entry | no e.by implies no carriedBy[e]
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Part B — [Verify Custody]: what a found verification lands for each entry
-- ─────────────────────────────────────────────────────────────────────────────

-- bindingOf: the entry's binding as the rebuild reads it: of the outcome events carrying its
-- entry id, the first by sequence number (Composition state 7, 8, Term binding rebuild).
fun bindingOf[e : Entry] : set Outcome {
    { o : outcomesFor[e] | no o2 : outcomesFor[e] | lt[o2.oseq, o.oseq] }
}

-- purgedLater: the entries later in e's chain whose bound event the record read answers
-- Purged (Term purged later entry).
fun purgedLater[e : Entry] : set Entry {
    { l : Entry | l.chain = e.chain and gt[l.sn, e.sn] and bindingOf[l].rread = RPurged }
}

-- bstat: the binding class of an entry with no binding: binding-unknown where a purged later
-- entry exists, binding-gap where none (Action wiring 36, 37).
fun bstat[e : Entry] : set BStat {
    ((no bindingOf[e] and some purgedLater[e]) => BUnknown else none)
  + ((no bindingOf[e] and no purgedLater[e]) => BGap else none)
}

-- av: every attestation verification a rule lands for a bound entry, rule by rule.
fun av[e : Entry] : set AVal {
    let o = bindingOf[e] |
        ((some o and o.rread = RNotKnown) => AVUnknownNotKnown else none)                 -- AW 62
      + ((some o and o.rread = RPurged and o in Presented) => o.vout else none)
      + ((some o and o.rread = RPurged and o not in Presented) => PayloadNotSupplied else none)
      + ((some o and o.rread in Live and o in Partly) => o.vout else none)                -- AW 56, 43
      + ((some o and o.rread in Live and o not in Partly and o not in Presented)
            => PayloadNotSupplied else none)                                              -- AW 41
      + ((some o and o.rread in Live and o not in Partly and o in Presented)
            => o.vout else none)                                                          -- AW 42, 43
}

-- epm: every entry payload match a rule lands for a bound entry.
fun epm[e : Entry] : set EPM {
    let o = bindingOf[e] |
        ((some o and VVerified in av[e]) => o.cmp else none)                              -- AW 45
      + ((some o and some av[e] and no av[e] & (VVerified + VFailPurged))
            => EUnanchored else none)                                                     -- AW 46
      + ((some o and VFailPurged in av[e]) => ENAPurged else none)                        -- AW 57
      + ((some o and o.rread = RNotKnown) => EUnanchored else none)                       -- AW 62
}

-- actorMatch: Term actor match for a bound event the record read answers live: match where it
-- carries no recovery flag and its attesting actor names the attested custodian; match
-- carrying recovery where it carries the flag, its acting actor reference (the intent's actor,
-- Recoverable Invocation Term outcome shape) names the attested custodian and its attesting
-- actor is the recovery identity or the resolving operator; attribution-mismatch otherwise.
fun actorMatch[o : Outcome, e : Entry] : set AM {
    (o not in Recovered and o.attester in attested[e]) => AMatch
    else ((o in Recovered and o.intent.actor in attested[e]
           and o.attester in RecoveryIdentity + OperatorActor) => AMatchRecovery
    else AMismatch)
}

-- am: every actor match a rule lands for a bound entry.
fun am[e : Entry] : set AM {
    let o = bindingOf[e] |
        ((some o and o.rread in Live) => actorMatch[o, e] else none)                      -- AW 47
      + ((some o and o.rread = RPurged) => AMUnknownPurged else none)                     -- AW 58
      + ((some o and o.rread = RNotKnown) => AMUnknownNotKnown else none)                 -- AW 62
}

-- ra: every recovery attestation a rule lands for a bound entry.
fun ra[e : Entry] : set RA {
    let o = bindingOf[e] |
        ((some o and o.rread in Live) => ((o in Recovered) => RATrue else RAFalse) else none) -- AW 48
      + ((some o and o.rread = RPurged) => RAUnknownPurged else none)                     -- AW 49
      + ((some o and o.rread = RNotKnown) => RAUnknownNotKnown else none)                 -- AW 62
}

-- ret: the retention state a found verification carries, the record read's unchanged
-- (Action wiring 50).
fun ret[e : Entry] : set RAns {
    let o = bindingOf[e] | (some o and o.rread != RNotKnown) => o.rread else none
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the page's writes can leave (Part A), or any state
-- [Verify Custody] reads (Part B), that violates this assertion? No counterexample (UNSAT) =
-- the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_1: a settled carried entry whose carrying intent stands closed — not open,
-- escalated, abandoned or refused — carries an outcome event whose action reference matches
-- its event type. Under the two premises the page relies on (header, findings (a) and (b)).
assert A_Invariant_1_1 {
    (built and operatorNamesItsEntry and outsideWritesOffDatum) implies
        all e : Settled, i : carriedBy[e] | i.state = IClosed implies
            some o : outcomesFor[e] | o.oref = refFor[e]
}
check A_Invariant_1_1 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_1_2: an outcome event with no recovery flag is attested by the acting custodian
-- of the entry it names (Term attested custodian).
assert A_Invariant_1_2 {
    built implies all o : Outcome - Recovered, e : Entry | e.id = o.oentry implies
        o.attester in attested[e]
}
check A_Invariant_1_2 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_3_2: for a lawfully destroyed event — a bound event the record read answers
-- Purged — [Verify Custody] carries failed-verification(purged) as the attestation
-- verification, and nothing else.
assert A_Invariant_3_2 {
    all e : Entry | (some bindingOf[e] and bindingOf[e].rread = RPurged) implies av[e] = VFailPurged
}
check A_Invariant_3_2 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_4_1: every orphan entry the leg examines is surfaced: its carrying intent stands
-- open (the sweep's) or escalated, or the leg alerted it as a false closing, or opened a
-- write-ownership finding for it. Under the two premises the page relies on.
assert A_Invariant_4_1 {
    (built and operatorNamesItsEntry and outsideWritesOffDatum) implies
        all e : examined | orphan[e] implies
            ((some i : carriedBy[e] | i.state in IOpen + IEscalated) or e in Alerted or e in Finding)
}
check A_Invariant_4_1 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_4_3: two outcome events the invocation close or the sweep wrote never carry one
-- entry id.
assert A_Invariant_4_3 {
    built implies all disj o1, o2 : Outcome |
        (o1.writer in ByClose + BySweep and o2.writer in ByClose + BySweep) implies o1.oentry != o2.oentry
}
check A_Invariant_4_3 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_4_4: every outcome event the invocation close or the sweep wrote names an entry
-- the chain it carries holds.
assert A_Invariant_4_4 {
    built implies all o : Outcome | o.writer in ByClose + BySweep implies
        some e : Entry | e.id = o.oentry and e.chain = o.ochain
}
check A_Invariant_4_4 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_5_1: [Verify Custody] answers every entry: a bound entry gets exactly one
-- attestation verification (carrying the seal's answer), actor match, recovery attestation and
-- entry payload match, and its retention state wherever the record read answers one; an
-- unbound entry exactly one binding class.
assert A_Invariant_5_1 {
    all e : Entry | some bindingOf[e] implies {
        one av[e]
        one am[e]
        one ra[e]
        one epm[e]
        bindingOf[e].rread != RNotKnown implies one ret[e]
    }
    all e : Entry | no bindingOf[e] implies one bstat[e]
}
check A_Invariant_5_1 for 3 but 4 Entry, 5 Actor, 4 Int

-- A_Invariant_7_2: a transferred entry an invocation wrote was authenticated under its
-- outgoing custodian: the intent's actor reference is the entry's outgoing custodian.
assert A_Invariant_7_2 {
    built implies all e : Entry | (some e.by and e.etype = Transferred) implies e.by.actor = e.from
}
check A_Invariant_7_2 for 3 but 4 Entry, 5 Actor, 4 Int

-- ─────────────────────────────────────────────────────────────────────────────
-- Satisfiability runs — non-vacuity guards, one for each shape the page admits
-- Each run must find at least one instance (SAT).
-- UNSAT means the model forbids a state the page admits.
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowCustodyJourney: one chain, its genesis, a transfer and a transformation, each written by
-- its invocation and closed by its invocation close.
run ShowCustodyJourney {
    built and some c : Chain | #(chain.c) = 3 and #(chain.c).etype = 3
        and all e : chain.c | some e.by and some o : intent.(e.by) | o.writer = ByClose
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowRecoveredTransfer: a transfer whose close never landed, closed by the sweep on the step
-- probe.
run ShowRecoveredTransfer {
    built and some o : Outcome | o.writer = BySweep and o.intent.kind = KXfer
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowRecoveredOrigination: an origination closed by the sweep through the genesis lookup.
run ShowRecoveredOrigination {
    built and some o : Outcome | o.writer = BySweep and o.intent.kind = KOrig
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowNoLookupEscalated: no genesis lookup; an origination whose write landed and whose close
-- did not stands escalated (Recoverable Invocation Deviation 4c).
run ShowNoLookupEscalated {
    built and no GenesisLookup and some i : Intent | i.kind = KOrig and i.state = IEscalated and some by.i
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowStaleTransferRefused: a transfer resolved before another entry changed the holder,
-- refused inside the transfer transaction with nothing written (Action wiring 65).
run ShowStaleTransferRefused {
    built and some i : Intent | i.kind = KXfer and i.state = IRefused and
        some e : Entry | e.chain = i.key and gt[e.sn, i.resolvedOn.sn] and e.holder != i.out
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowWriteOwnershipFinding: a transfer written outside every invocation, examined and found.
run ShowWriteOwnershipFinding {
    built and outsideWritesOffDatum and some e : Finding | no e.by and e.etype = Transferred
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowFalseClosing: an operator abandoned an intent whose write landed; the leg alerts it.
run ShowFalseClosing {
    built and some e : Alerted | e.by.state = IAbandoned
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowOperatorDuplicate: an operator's outcome names an entry the invocation close also named
-- (Invariant 4 NOTE: detected by the rebuild's binding-duplicate finding, not prevented).
run ShowOperatorDuplicate {
    built and some disj o1, o2 : Outcome | o1.oentry = o2.oentry and o1.writer = ByClose
        and o2.writer = ByOperator
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowOperatorClosingElsewhere: finding (a). An operator closed an intent whose write landed
-- with an outcome naming another entry; the settled carried entry carries no outcome and no
-- rule surfaces it.
run ShowOperatorClosingElsewhere {
    built and outsideWritesOffDatum and some e : Settled & examined, i : carriedBy[e] |
        i.state = IClosed and orphan[e] and e not in Alerted + Finding
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowOutsideWriteOnDatum: finding (b). A write outside every invocation on its act key at an
-- intent's pairing datum is a carried entry: no finding, and an orphan beside a closed intent.
run ShowOutsideWriteOnDatum {
    built and operatorNamesItsEntry and some e : examined |
        no e.by and some carriedBy[e] and e not in Finding and orphan[e] and carriedBy[e].state = IClosed
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowVerifiedEntry: a bound live event verified, its payload matching, its actor the attested
-- custodian.
run ShowVerifiedEntry {
    built and some e : Entry | av[e] = VVerified and epm[e] = EMatch and am[e] = AMatch
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowRecoveryAttested: a bound event the sweep wrote, read live: recovery attestation true,
-- actor match carrying recovery.
run ShowRecoveryAttested {
    built and some e : Entry | ra[e] = RATrue and am[e] = AMatchRecovery
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowLawfullyDestroyed: a bound event Purged: failed-verification(purged), not-applicable
-- payload match, unknown actor match and recovery attestation.
run ShowLawfullyDestroyed {
    some e : Entry | some bindingOf[e] and bindingOf[e].rread = RPurged and epm[e] = ENAPurged
        and am[e] = AMUnknownPurged
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowRecordNotKnown: a bound event the record read answers not-known for (Action wiring 62).
run ShowRecordNotKnown {
    some e : Entry | some bindingOf[e] and bindingOf[e].rread = RNotKnown and av[e] = AVUnknownNotKnown
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowPayloadNotSupplied: a live event whose whole covering range the caller did not present.
run ShowPayloadNotSupplied {
    some e : Entry | av[e] = PayloadNotSupplied and epm[e] = EUnanchored
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowPartlyPurged: a live event under partially-purged coverage, verified through the
-- members presented (Action wiring 56).
run ShowPartlyPurged {
    some e : Entry | some bindingOf[e] and bindingOf[e] in Partly and one av[e]
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowBindingUnknown: an entry with no binding before a purged later entry.
run ShowBindingUnknown {
    some e : Entry | bstat[e] = BUnknown
} for 3 but 4 Entry, 5 Actor, 4 Int

-- ShowBindingGap: an entry with no binding and no purged later entry.
run ShowBindingGap {
    some e : Entry | bstat[e] = BGap
} for 3 but 4 Entry, 5 Actor, 4 Int

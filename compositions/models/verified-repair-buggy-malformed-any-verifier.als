-- verified-repair-buggy-malformed-any-verifier.als
-- DELIBERATELY WRONG twin of verified-repair.als (unit: `compositions/verified-repair.md formal layer`).
--
-- INJECTED DEFECT: Term counted finding counts the findings of any recorded malformed verdict, a formal engine's included (the word reader's dropped), so a finding of a model that did not compile is triaged and cured.
--
-- BREAKS: A_Invariant_6_1.
-- Everything else is verified-repair.als as written; read its comments there.

module verified_repair_buggy_malformed_any_verifier

-- ─────────────────────────────────────────────────────────────────────────────
-- Signatures (types)
-- ─────────────────────────────────────────────────────────────────────────────

-- Page: a canonical document under the repository (Term page).
sig Page {}

-- Bytes: a page's bytes. The snapshot hash is the SHA-256 of a page's bytes (Term snapshot
-- hash), so two snapshots with one hash are one Bytes atom, compared byte-exact (Primitive
-- policy 6).
sig Bytes {}

-- Actor: an actor reference that calls the composition's actions or commits to the
-- repository.
sig Actor {}

-- Writer: the council's one writer to the repository (Term writer).
one sig Writer in Actor {}

-- Maintainer: the maintainer's actor reference (Capability requirement 7). Nothing on the
-- page sets it apart from the writer's, so the model lets the two coincide (see FINDINGS).
one sig Maintainer in Actor {}

-- Key: a round key, the nonce minted at [Freeze]'s seam (Term round key).
sig Key {}

-- Nonce: a council nonce, injected at the writer's seam for one [Repair] call (Term council
-- nonce).
sig Nonce {}

-- Commit: a commit of the repository: its parent, the bytes it holds for each page it holds
-- (a page it does not hold is absent), the actor that committed it, and its trailer — for a
-- council commit, the council nonce and the intent event the invocation open answered (Term
-- council trailer). changes is the fragments whose lines it changes from its parent (its
-- diff, read as the fragments it applies).
sig Commit {
    parent    : lone Commit,
    at        : Page -> lone Bytes,
    committer : one Actor,
    tnonce    : lone Nonce,
    tintent   : lone Intent,
    changes   : set Fragment
}

-- Round: a round's record (Action wiring 2): the page, the base commit, the snapshot hash
-- and the round key. The round budget is the budget model's.
sig Round {
    page : one Page,
    base : one Commit,
    snap : one Bytes,
    key  : one Key
}

-- Verifier: a reader or a formal engine (Term verifier).
abstract sig Verifier {}
sig Reader, Engine extends Verifier {}

-- Pass: the reader's pass a verdict answers, or formal for a formal engine's run (Term pass).
abstract sig Pass {}
one sig Grid, Eos, Linus, Formal extends Pass {}

-- Value: the one verdict a verdict carries (Verdict 1).
abstract sig Value {}
one sig Holds, Counterexample, Malformed extends Value {}

-- Verdict: a verdict presented to [Report] for a round: the snapshot hash and base commit it
-- carries, its verifier, its pass and its value (Verdict 1, 2).
sig Verdict {
    vround    : one Round,
    vhash     : one Bytes,
    vbase     : one Commit,
    verifier  : one Verifier,
    pass      : one Pass,
    value     : one Value
}

-- Recorded: the verdicts [Report] recorded (Action wiring 7). A refused report writes
-- nothing (Primitive policy 8), so a verdict outside this set has no record.
sig Recorded in Verdict {}

-- Finding: one failure a verifier reports, carried by one verdict (Term finding; its finding
-- id is that verdict's key and an ordinal, Term finding id).
sig Finding {
    fverdict : one Verdict
}

-- Role, Class, Side, Disp: a triage record's role, the finding's class, the side the
-- finding indicts and its disposition (Term role, class, side, disposition).
abstract sig Role {}
one sig First, Second, Third extends Role {}
abstract sig Class {}
one sig Foundational, Refining, Rhetorical extends Class {}
abstract sig Side {}
one sig ModelSide, EnglishSide, BothSides extends Side {}
abstract sig Disp {}
one sig Cure, Route, Reject, Decline extends Disp {}

-- Triage: one triager's sorting of one finding — its role, class, side and disposition, and
-- the patch whole where the disposition is cure (Term triage record). The model holds the
-- counted triages only (Term counted triage); kind and blame decide no rule it checks.
sig Triage {
    tfinding : one Finding,
    trole    : one Role,
    tclass   : one Class,
    tside    : one Side,
    tdisp    : one Disp,
    tpatch   : lone Patch
}

-- Site: a span of the page a fragment sits in (Term site). ClaimSite: a site in the claim
-- families other than the status lines — an Invariant, a Check, an External check, a Term
-- they name, the Intent (Term claim families). PlainSite: every other rule or Term site.
-- StatusLines: the page's status line with the Ledger's status and formal lines, both
-- records sites and claim families. LastGateLine and OpenList: records sites outside the
-- claim families (Term records fragment).
abstract sig Site {}
sig ClaimSite, PlainSite extends Site {}
one sig StatusLines, LastGateLine, OpenList extends Site {}

-- Patch: a patch — the finding it answers (none for the patch carrying the round's
-- records) and its fragments (Term patch).
sig Patch {
    answers : lone Finding
}

-- Fragment: one sentence's change, belonging to one patch: the site it targets and the
-- rule labels or Term names its new text declares (Term fragment, target, declared name).
sig Fragment {
    fpatch   : one Patch,
    target   : one Site,
    declared : set (ClaimSite + PlainSite)
}

-- Ruling: a ruling record: the page, and where given the round and the patch whole, under
-- the actor reference that recorded it (Action wiring 39).
sig Ruling {
    rpage  : one Page,
    rround : lone Round,
    rpatch : lone Patch,
    ractor : one Actor
}

-- Intent: a council.commit intent the invocation open recorded, carrying as intent data the
-- round key, the snapshot hash, the patches and the council nonce (Action wiring 22).
sig Intent {
    ikey     : one Key,
    isnap    : one Bytes,
    ipatches : set Patch,
    inonce   : one Nonce
}

-- Repair: a [Repair] call that committed: its round, the patches it carried, the head it
-- read (Action wiring 15), the council nonce injected for it, the intent its open recorded
-- and the commit it made.
sig Repair {
    rnd      : one Round,
    patches  : some Patch,
    head     : one Commit,
    nonce    : one Nonce,
    intent   : one Intent,
    commit   : one Commit
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Facts: only what the page takes from outside
-- ─────────────────────────────────────────────────────────────────────────────

-- RepositoryHistory: no commit is its own ancestor; the repository is a history of commits
-- (Capability requirement 1, 11, 20).
fact RepositoryHistory {
    no c : Commit | c in c.^parent
}

-- TrailerOnlyFromWriter: the repository refuses a commit carrying a council trailer from any
-- actor but the writer, and a commit from the writer carrying none (Capability requirement
-- 18, 22). A council trailer is the nonce and the intent event id together.
fact TrailerOnlyFromWriter {
    all c : Commit | (some c.tnonce or some c.tintent) iff c.committer = Writer
    all c : Commit | some c.tnonce iff some c.tintent
}

-- NonceUnique: the repository refuses a commit whose council nonce another commit carries
-- (Capability requirement 19), and the deployment injects a council nonce no other [Repair]
-- call carries (Capability requirement 21).
fact NonceUnique {
    all disj c1, c2 : Commit | some c1.tnonce implies c1.tnonce != c2.tnonce
    all disj r1, r2 : Repair | r1.nonce != r2.nonce
}

-- KeyUnique: the deployment injects a round key the journal holds for no other record
-- (Capability requirement 24).
fact KeyUnique {
    all disj r1, r2 : Round | r1.key != r2.key
}

-- FormalPassIsEngine: a formal engine's verdict carries the pass formal, and a reader's one
-- of the three reader passes (Verdict 10, Term pass): what a verifier hands [Report] is the
-- deployment's, held to the verdict contract.
fact FormalPassIsEngine {
    all v : Verdict | v.pass = Formal iff v.verifier in Engine
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Derived readings (the page's Terms)
-- ─────────────────────────────────────────────────────────────────────────────

-- counted: a counted verdict — recorded, sound (holds or counterexample), for a reader pass
-- (Term counted verdict, Term sound verdict, Verdict 9). The earliest-per-pass selection is
-- an order and is left out (see NOT CHECKED HERE).
pred counted[v : Verdict] {
    v in Recorded
    v.value in Holds + Counterexample
    v.pass in Grid + Eos + Linus
}

-- countedFinding: a finding a counted verdict carries, or a finding a reader's recorded
-- malformed verdict carries (Term counted finding).
pred countedFinding[f : Finding] {
    counted[f.fverdict] or
    (f.fverdict in Recorded and f.fverdict.value = Malformed)  -- BUG: any verifier's malformed verdict
}

-- engineSoundFinding: a finding a formal engine's sound verdict of the round carries
-- (Action wiring 35, 69).
pred engineSoundFinding[f : Finding] {
    f.fverdict in Recorded
    f.fverdict.verifier in Engine
    f.fverdict.value in Holds + Counterexample
}

-- trs: a finding's counted triages in one role.
fun trs[f : Finding, ro : Role] : set Triage {
    tfinding.f & trole.ro
}

-- settledT: a finding's settled triage — the third where one exists, otherwise the second,
-- otherwise the first (Term settled triage).
fun settledT[f : Finding] : set Triage {
    some trs[f, Third] => trs[f, Third] else (some trs[f, Second] => trs[f, Second] else trs[f, First])
}

-- gateT: the triage [Repair]'s patch checks read for a finding: its settled triage
-- (Action wiring 20, 40, 62).
fun gateT[f : Finding] : set Triage {
    settledT[f]
}

-- claimFamilies: the sites in the claim families (Term claim families).
fun claimFamilies : set Site {
    ClaimSite + StatusLines
}

-- recordsSites: the sites a records fragment changes (Term records fragment).
fun recordsSites : set Site {
    StatusLines + LastGateLine + OpenList
}

-- frags: a patch's fragments.
fun frags[p : Patch] : set Fragment {
    fpatch.p
}

-- maintainersRuling: a maintainer's ruling carrying round ro and patch p byte for byte
-- (Term maintainer's ruling).
pred maintainersRuling[ro : Round, p : Patch] {
    some ru : Ruling | ru.ractor = Maintainer and ru.rround = ro and ru.rpatch = p
}

-- ─────────────────────────────────────────────────────────────────────────────
-- The wiring: what the composition's actions write
-- ─────────────────────────────────────────────────────────────────────────────

-- freezeWrites: a round is recorded from the page the repository holds at the base commit
-- (Action wiring 2, Primitive policy 2).
pred freezeWrites[r : Round] {
    some r.base.at[r.page]
    r.snap = r.base.at[r.page]
}

-- reportWrites: [Report] records a verdict only where it carries the round's snapshot hash
-- and base commit (Action wiring 4).
pred reportWrites[v : Verdict] {
    v in Recorded implies (v.vhash = v.vround.snap and v.vbase = v.vround.base)
}

-- triageWrites: [Triage] records a finding's triage only for a counted finding or one a
-- formal engine's sound verdict carries (Action wiring 35), one counted triage a role
-- (Action wiring 36), a second only after a first (Action wiring 43), a third only for a
-- parted finding (Action wiring 44, Term parted finding), and a cure only with its patch
-- (Primitive policy 19).
pred triageWrites[t : Triage] {
    countedFinding[t.tfinding] or engineSoundFinding[t.tfinding]
    one trs[t.tfinding, t.trole]
    t.trole = Second implies some trs[t.tfinding, First]
    t.trole = Third implies (some trs[t.tfinding, First] and some trs[t.tfinding, Second] and
        (trs[t.tfinding, First].tclass != trs[t.tfinding, Second].tclass or
         trs[t.tfinding, First].tside != trs[t.tfinding, Second].tside or
         trs[t.tfinding, First].tdisp != trs[t.tfinding, Second].tdisp))
    t.tdisp = Cure implies some t.tpatch
}

-- ruleWrites: [Rule] records a ruling only under the maintainer's actor reference (Action
-- wiring 38), with a round exactly where a patch is given (Primitive policy 14), on the
-- round's own page (Primitive policy 20).
pred ruleWrites[ru : Ruling] {
    ru.ractor = Maintainer
    some ru.rround iff some ru.rpatch
    some ru.rround implies ru.rround.page = ru.rpage
}

-- patchAdmitted: [Repair]'s checks on one patch of round ro. Every patch carries a fragment
-- (Primitive policy 4). A patch answering a finding: the finding is the round's, its settled
-- triage is a cure (Action wiring 40) carrying this patch byte-exact (Action wiring 62), and
-- does not side with the model (Action wiring 20). A patch answering no finding carries
-- records fragments only (Action wiring 41). A fragment targeting a site in the claim
-- families, or declaring a name there, has the maintainer's ruling carrying the round and
-- the patch (Action wiring 19, 56).
pred patchAdmitted[ro : Round, p : Patch] {
    some frags[p]
    some p.answers implies {
        p.answers.fverdict.vround = ro
        gateT[p.answers].tdisp = Cure
        gateT[p.answers].tpatch = p
        ModelSide not in gateT[p.answers].tside
    }
    no p.answers implies frags[p].target in recordsSites
    all fr : frags[p] | fr.target in claimFamilies implies maintainersRuling[ro, p]
    all fr : frags[p] | some (fr.declared & claimFamilies) implies maintainersRuling[ro, p]
}

-- repairWrites: an admitted repair that committed. The writer called it (Action wiring 49);
-- the page at the head it read is the snapshot (Action wiring 15); every patch passes the
-- patch checks; the change set carries a records fragment replacing the last gate line
-- (Action wiring 61); the open recorded the intent with the round key, the snapshot hash,
-- every patch whole and the council nonce (Action wiring 22); the commit's parent is the
-- head read, its trailer the nonce and the intent, and its diff the change set (Action wiring
-- 23, 25, 26).
pred repairWrites[r : Repair] {
    r.commit.committer = Writer
    r.head.at[r.rnd.page] = r.rnd.snap
    all p : r.patches | patchAdmitted[r.rnd, p]
    LastGateLine in frags[r.patches].target
    r.intent.ikey = r.rnd.key
    r.intent.isnap = r.rnd.snap
    r.intent.ipatches = r.patches
    r.intent.inonce = r.nonce
    r.commit.parent = r.head
    r.commit.tnonce = r.nonce
    r.commit.tintent = r.intent
    r.commit.changes = frags[r.patches]
}

-- Built: every record in the state is one the composition's actions wrote, and the
-- composition writes the repository only through [Repair] (Composes 5): every commit of the
-- writer is one [Repair] call's commit.
pred Built {
    all r : Round | freezeWrites[r]
    all v : Verdict | reportWrites[v]
    all t : Triage | triageWrites[t]
    all ru : Ruling | ruleWrites[ru]
    all r : Repair | repairWrites[r]
    all c : Commit | c.committer = Writer implies one commit.c
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertions (verified guarantees)
-- Each "check" asks: is there any state the composition's actions can write, over any
-- verdicts, triages and rulings the actors can give, that violates this assertion? No
-- counterexample (UNSAT) = the guarantee holds within scope.
-- ─────────────────────────────────────────────────────────────────────────────

-- A_Invariant_1_2: every counted verdict carries its round's snapshot hash (Invariant 1.2,
-- Check 1.2).
assert A_Invariant_1_2 {
    Built implies all v : Verdict | counted[v] implies v.vhash = v.vround.snap
}
check A_Invariant_1_2 for 3 but 5 Site

-- A_Invariant_2_1: every council commit's parent holds, for the round's page, the round's
-- snapshot bytes (Invariant 2.1, Check 2.1). A cross-check with verified-repair.tla.
assert A_Invariant_2_1 {
    Built implies all r : Repair | r.commit.parent.at[r.rnd.page] = r.rnd.snap
}
check A_Invariant_2_1 for 3 but 5 Site

-- A_Invariant_3_1: for every council commit changing a site in the claim families — a
-- fragment targeting one, or declaring a name in one — a ruling under the maintainer's actor
-- reference carries the commit's round and the patch byte for byte (Invariant 3.1, Check
-- 3.1).
assert A_Invariant_3_1 {
    Built implies all r : Repair, fr : r.commit.changes |
        (fr.target in claimFamilies or some (fr.declared & claimFamilies)) implies
            (some ru : Ruling | ru.ractor = Maintainer and ru.rround = r.rnd and ru.rpatch = fr.fpatch)
}
check A_Invariant_3_1 for 3 but 5 Site

-- A_Invariant_4_1: no council commit applies a patch answering a finding whose settled
-- triage's side is the model (Invariant 4.1, Check 4.1).
assert A_Invariant_4_1 {
    Built implies all r : Repair, p : r.commit.changes.fpatch |
        some p.answers implies ModelSide not in settledT[p.answers].tside
}
check A_Invariant_4_1 for 3 but 5 Site

-- A_Invariant_6_1: no council commit applies a patch answering a finding a formal engine's
-- malformed verdict carries (Invariant 6.1, Check 6.1).
assert A_Invariant_6_1 {
    Built implies no r : Repair, p : r.commit.changes.fpatch |
        p.answers.fverdict.verifier in Engine and p.answers.fverdict.value = Malformed
}
check A_Invariant_6_1 for 3 but 5 Site

-- A_Invariant_7_1: every council commit's trailer names an intent carrying the key of a
-- round the journal holds, that round's snapshot hash, every patch the commit applies whole,
-- and the commit's council nonce (Invariant 7.1, Check 7.1).
assert A_Invariant_7_1 {
    Built implies all c : Commit | some c.tintent implies {
        some ro : Round | ro.key = c.tintent.ikey and ro.snap = c.tintent.isnap
        c.changes.fpatch in c.tintent.ipatches
        frags[c.tintent.ipatches] in c.changes
        c.tintent.inonce = c.tnonce
    }
}
check A_Invariant_7_1 for 3 but 5 Site

-- ─────────────────────────────────────────────────────────────────────────────
-- Runs (the shapes the page admits; each must be satisfiable)
-- ─────────────────────────────────────────────────────────────────────────────

-- ShowCleanRepair: a council commit carrying the round's records alone, the last gate line
-- replaced, after three counted reader verdicts (Walkthrough — a clean round).
run ShowCleanRepair {
    Built
    some r : Repair | no r.patches.answers and
        Grid + Eos + Linus in { v : Verdict | counted[v] and v.vround = r.rnd }.pass
} for 3 but 4 Verdict, 5 Site

-- ShowCureCommitted: a council commit carrying a cure answering a counted finding beside
-- the records.
run ShowCureCommitted {
    Built
    some r : Repair, p : r.patches | some p.answers and countedFinding[p.answers]
} for 3 but 5 Site

-- ShowSecondTriageDecides: a finding the first triage cured on the page's side and the
-- second sided with the model is not repaired, while a commit lands.
run ShowSecondTriageDecides {
    Built
    some f : Finding | trs[f, First].tside = EnglishSide and trs[f, First].tdisp = Cure and
        trs[f, Second].tside = ModelSide and some Repair
} for 3 but 5 Site

-- ShowThirdTriage: a parted finding settled by a third triage, cured and repaired.
run ShowThirdTriage {
    Built
    some r : Repair, p : r.patches | some trs[p.answers, Third]
} for 3 but 5 Site

-- ShowClaimPatchRuled: a cure into the claim families committed under the maintainer's
-- ruling carrying the round and the patch (Wiring decision 2).
run ShowClaimPatchRuled {
    Built
    some r : Repair, fr : r.commit.changes | fr.target in ClaimSite
} for 3 but 5 Site

-- ShowStatusUnderRuling: the round's records rewrite the status lines under a ruling (Term
-- round's records: the status is the maintainer's).
run ShowStatusUnderRuling {
    Built
    some r : Repair | StatusLines in r.commit.changes.target
} for 3 but 5 Site

-- ShowStaleVerdictUnrecorded: a verdict carrying another snapshot hash than its round's is
-- not recorded (Action wiring 4; Rejection path — the page moved under the round).
run ShowStaleVerdictUnrecorded {
    Built
    some v : Verdict | v.vhash != v.vround.snap and v.value = Holds and v.pass = Grid
} for 3 but 5 Site

-- ShowEngineMalformedLeftAlone: a formal engine's recorded malformed verdict carries a
-- finding, and a council commit lands without answering it (Rejection path — the model did
-- not compile).
run ShowEngineMalformedLeftAlone {
    Built
    some f : Finding | f.fverdict in Recorded and f.fverdict.verifier in Engine and
        f.fverdict.value = Malformed and some r : Repair | r.rnd = f.fverdict.vround
} for 3 but 5 Site

-- ShowEngineSoundTriaged: a formal engine's counterexample is triaged on the model's side
-- and repairs nothing on the page (Rejection path — the engine indicts an invariant).
run ShowEngineSoundTriaged {
    Built
    some t : Triage | t.tfinding.fverdict.verifier in Engine and t.tside = ModelSide
} for 3 but 5 Site

-- ShowReaderMalformedCounts: a finding a reader's malformed verdict carries is counted,
-- triaged and cured (Term counted finding).
run ShowReaderMalformedCounts {
    Built
    some r : Repair, p : r.patches | p.answers.fverdict.value = Malformed
} for 3 but 5 Site

-- ShowWriterRulesItsOwnPatch: the writer and the maintainer one actor reference, and the
-- ruling admitting a claim-family patch recorded under it (FINDINGS).
run ShowWriterRulesItsOwnPatch {
    Built
    Writer = Maintainer
    some r : Repair, fr : r.commit.changes | fr.target in ClaimSite
} for 3 but 5 Site

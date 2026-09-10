#!/usr/bin/env python3
"""Generate the .cfg and the five buggy twins of recoverable-invocation.tla.

Three twins are the correct model with ONE exact edit. Two are the correct
model with ONE constant flipped — and those two ARE THE PROSE AS IT STANDS:
the corpus declares no journal fence, and the visibility requirement it states
is bounded only by time since issue. Every replacement asserts its count, so a
drifted anchor fails loudly instead of silently."""
import os
D = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(D, "recoverable-invocation.tla")
src = open(SRC).read()
CFG = open(os.path.join(D, "recoverable-invocation.cfg")).read()

def rep(text, old, new, count=1):
    n = text.count(old)
    assert n == count, (n, count, old[:70])
    return text.replace(old, new)

HEADER_END = "\\*   recoverable-invocation-buggy-opclock.tla  — OperatorSkew > 0 (gate 9, F7).\n"
assert src.count(HEADER_END) == 1
body = HEADER_END + src.split(HEADER_END)[1]

def twin(name, blurb, edits=(), cfg=CFG):
    t = "---- MODULE recoverable-invocation-buggy-%s ----\n" % name
    t += "\\* Grace Commons — Recoverable Invocation: BUGGY TWIN (vacuity guard).\n\\*\n"
    t += blurb
    t += "\n" + body.split("\n", 1)[1]
    for old, new in edits:
        t = rep(t, old, new)
    return t, cfg

twins = {}

def flip(cfg, **over):
    out = []
    for line in cfg.rstrip().split("\n"):
        k = line.strip().split(" =")[0]
        if k in over:
            out.append("    %s = %s" % (k, over.pop(k)))
        else:
            out.append(line)
    return "\n".join(out) + "\n"


twins["death"] = twin("death",
"""\\* Identical to recoverable-invocation.tla EXCEPT the section host RELEASES ON
\\* THE HOLDER'S DEATH: Crash and SweepCrash free the section instead of letting
\\* the lease run out. A run that dies with its closing write in flight frees the
\\* section at once; the other node's run takes it, re-reads before the write is
\\* visible, probes, and issues a SECOND closing.
\\*
\\* Expected result: Inv2_OneWriter VIOLATED. If every invariant holds here, the
\\* harness is vacuous: `act_section`'s released-on-return-or-expiry-never-on-
\\* death rule would be decoration.
""",
[("""    /\\ invPhase' = "crashed"
    /\\ UNCHANGED <<now, fence, holder, invExpiry, heldUntil,
""", """    /\\ invPhase' = "crashed"
    /\\ holder' = IF holder = "inv" THEN "none" ELSE holder    \\* BUG: released on death
    /\\ heldUntil' = IF holder = "inv" THEN 0 ELSE heldUntil
    /\\ UNCHANGED <<now, fence, invExpiry,
"""),
 ("""    /\\ SetPhase(s, "idle")
    /\\ UNCHANGED <<now, fence, invPhase, holder, invExpiry, heldUntil,
""", """    /\\ SetPhase(s, "idle")
    /\\ holder' = IF holder = s THEN "none" ELSE holder        \\* BUG: released on death
    /\\ heldUntil' = IF holder = s THEN 0 ELSE heldUntil
    /\\ UNCHANGED <<now, fence, invPhase, invExpiry,
""")])

twins["reread"] = twin("reread",
"""\\* Identical to recoverable-invocation.tla EXCEPT a sweep run DOES NOT RE-READ
\\* THE JOURNAL UNDER THE SECTION: it keeps the enumeration's answer from step 1
\\* and goes straight from the take to the probe. Between the enumeration and
\\* the take the run waits for the section — and the holder it is waiting for is
\\* the invocation, which closes the act while it waits.
\\*
\\* Expected result: Inv2_OneWriter VIOLATED. If every invariant holds here, the
\\* harness is vacuous: [Reconcile] step 2's re-read under the section would be
\\* decoration. This twin replaces an earlier one that removed the invocation's
\\* `remaining >= journal_write_bound` gate — that twin HELD, which is the
\\* finding recorded against Invariant 2: the gate is not what carries it.
""",
[("""    /\\ holder = s
    /\\ ~Closed
    /\\ SweepGateOpen(s)
    /\\ ServiceIdentity
    /\\ storeState = "committed"
""", """    /\\ holder = s
    /\\ SweepGateOpen(s)                      \\* BUG: no re-read under the section
    /\\ ServiceIdentity
    /\\ storeState = "committed"
"""),
 ("""    /\\ holder = s
    /\\ ~Closed
    /\\ SweepGateOpen(s)
    /\\ ServiceIdentity
    /\\ storeState \\in {"none", "pending", "dropped"}
""", """    /\\ holder = s
    /\\ SweepGateOpen(s)                      \\* BUG: no re-read under the section
    /\\ ServiceIdentity
    /\\ storeState \\in {"none", "pending", "dropped"}
""")])

twins["fence"] = twin("fence",
"""\\* Identical to recoverable-invocation.tla EXCEPT the sweep ABANDONS A
\\* FENCELESS ACT: it writes `abandoned` whatever the act kind, so on a kind
\\* with no commit_fence a commit still in flight lands after the abandonment
\\* and contradicts it.
\\*
\\* Expected result: Inv5_NoFalseAbandon VIOLATED. If every invariant holds
\\* here, the harness is vacuous: the fenceless kind's `escalated` degree
\\* ([Reconcile] step 3) would be decoration.
""",
[("""    /\\ closingKind' = IF fence THEN "abandoned" ELSE "escalated"
""", """    /\\ closingKind' = "abandoned"            \\* BUG: abandons whatever the kind
""")])

twins["journal"] = twin("journal",
"""\\* THE PROSE AS IT STANDS. Identical to recoverable-invocation.tla, with
\\* JournalFence = FALSE: the substrate honours no deadline on a journal write.
\\* That is the corpus today — record_action(action_ref, actor_ref, credential,
\\* data) carries no deadline and no journal fence is declared anywhere — while
\\* `act_section` gates every journal write on a RELATIVE bound (`remaining` at
\\* least journal_write_bound) and concludes that a write issued inside the
\\* lease lands inside it. The spec refutes that itself two sections away, under
\\* `commit_fence`: "a relative request timeout is not a fence: it bounds the
\\* landing only of a write issued inside the lease, and nothing bounds when a
\\* paused process issues one."
\\*
\\* Expected result: Inv2_OneWriter VIOLATED — a writer passes the gate, pauses,
\\* and its write lands after another writer has closed the act. Found by the
\\* sixth fresh-reader gate (F2) and missed by model v1, which fused the gate
\\* with the write so the pause could not be expressed.
""", (), CFG.replace("JournalFence = TRUE", "JournalFence = FALSE"))

twins["visible"] = twin("visible",
"""\\* THE PROSE AS IT STANDS. Identical to recoverable-invocation.tla, with
\\* VisibleOnReturn = FALSE: a journal write is visible to another node's read
\\* only once journal_write_bound has elapsed SINCE ITS ISSUE, which is the only
\\* visibility this composition declares over the substrate. The section,
\\* meanwhile, is released on the holder's RETURN — which can be well inside
\\* that bound. A waiter admitted at the release re-reads, sees nothing, and
\\* closes the act a second time.
\\*
\\* Expected result: Inv2_OneWriter VIOLATED. Found by the sixth fresh-reader
\\* gate (F3) and missed by model v1, whose sweep held the section until its
\\* write had LANDED — a discipline the prose does not state.
""", (), CFG.replace("VisibleOnReturn = TRUE", "VisibleOnReturn = FALSE"))

twins["skew"] = twin("skew",
"""\\* THE PROSE AS IT STANDS. Identical to recoverable-invocation.tla, with
\\* FenceMargin = 0: the journal fence's instant is minted bare from the section
\\* host's `expires_at`, while the refusal is judged on the SUBSTRATE's clock.
\\* The page budgets exactly this two-clock gap for `commit_fence` — the abandon
\\* edge is one allowance later — and budgets nothing for the journal fence it
\\* now declares.
\\*
\\* Expected result: Inv2_OneWriter VIOLATED — a substrate lagging the host by
\\* one allowance admits a dead holder's append after the section has passed.
\\* Gate 7, F1. Note the control: with JournalSkew = 0 the bare margin holds, so
\\* it is the skew and not the margin's absence that breaks it.
""", (), CFG.replace("FenceMargin = 1", "FenceMargin = 0"))

# Derived from the main config rather than written out, so that a constant
# added to the model cannot leave this twin behind — which is exactly what
# happened when v4 added three and the checker reported MissingConstants.
PERWRITE_CFG = flip(CFG,
                    CompletionBound="7", SweepLease="7", LateLanding="2",
                    Cadence="20", Window="30", MaxTime="11", OpenBy="0",
                    MaxSweepDeaths="0", MaxPauses="1", MaxLand="5",
                    PerWriteFence="FALSE")

# ---- gate 9's two, and the passing sibling the second one needs ------------

twins["supersede"] = twin("supersede",
"""\\* THE PROSE AS IT STANDS, for the escalated case. Identical to
\\* recoverable-invocation.tla with SupersedesNamed = FALSE: an operator's
\\* resolution written over an ESCALATED record carries `resolved_by` and no
\\* `supersedes`. `resolved_by` names the OPERATOR, not a record — so the
\\* precedence rule ("replaces the one it names") and Generation acceptance
\\* check 2's exemption ("together with the one it names") have no referent,
\\* and both records fall into "supersede nothing and are superseded by
\\* nothing".
\\*
\\* Expected result: Inv2_OneWriter and Inv6_SupersessionNamed VIOLATED — two
\\* unsuperseded closings for one act on the page's own headline recovery path,
\\* a lawful resolution read as a duplicate by both surfaces. Gate 9, F6.
""", (), flip(CFG, SupersedesNamed="FALSE"))

# The report-only pair. The twin flips ONE constant against a sibling that must
# HOLD, or the violation would say only that report-only deployments are
# broken — which is not the claim.
REPORT_ONLY = flip(CFG, ServiceIdentity="FALSE")

twins["opclock"] = twin("opclock",
"""\\* THE PROSE AS IT STANDS. Identical to the report-only configuration with
\\* OperatorSkew = 1: [Resolve]'s too-young guard compares a present reading
\\* against the substrate's `recorded_at`, and NO SEAM SUPPLIES THAT READING.
\\* The page enumerates its clocks exhaustively twice and [Resolve] is at none
\\* of them, so the only way to close the step is a clock read inside the
\\* action — and nothing then bounds how far it runs ahead.
\\*
\\* `service_identity = none`, because only in a report-only deployment does
\\* the operator decide an act's fate against the edge rather than after
\\* another writer already has. Its passing sibling is
\\* probe-reportonly-clean.tla, which differs by this one constant.
\\*
\\* Expected result: Inv5_NoFalseAbandon VIOLATED — the operator writes
\\* `abandoned` one tick before the edge, on a reading that says otherwise, and
\\* the invocation's commit still lands. Gate 9, F7.
""", (), flip(REPORT_ONLY, OperatorSkew="1"))

twins["perwrite"] = twin("perwrite",
"""\\* THE PROSE AS IT STANDS. Identical to recoverable-invocation.tla, with
\\* PerWriteFence = FALSE: a write is fenced at the lease's expiry and nowhere
\\* else, so a write may land later than `journal_write_bound` — which is a
\\* DISCLOSED BOUND with headroom, an SLO, and which the page's own commit_fence
\\* doctrine says decides nothing — while still inside the lease. Primitive
\\* policies then read absence after that bound and retry.
\\*
\\* The constants differ from the main model's: the lease is long enough that a
\\* write issued early still has fence room after the read-back, which is the
\\* ordinary case in a real deployment and unreachable at the main model's
\\* smaller bounds. The sweeps are pushed out so the race is the invocation
\\* against its own retry.
\\*
\\* Expected result: Inv2_OneWriter VIOLATED — the read-back misses a write
\\* still in flight and the retry is the second record. Gate 7, F2.
""", (), PERWRITE_CFG)

for name, (text, cfg) in twins.items():
    edits = text.count("BUG:")
    assert edits == (2 if name in ("death", "reread") else 0 if name in ("journal", "visible", "skew", "perwrite", "supersede", "opclock") else 1), (name, edits)
    open(os.path.join(D, "recoverable-invocation-buggy-%s.tla" % name), "w").write(text)
    open(os.path.join(D, "recoverable-invocation-buggy-%s.cfg" % name), "w").write(cfg)
# The passing sibling of the opclock twin: same report-only deployment, the
# operator's reading injected at a declared seam. It must HOLD, or the twin
# proves nothing about the clock.
sib = twin("REPLACE",
"""\\* NOT A TWIN — the PASSING SIBLING of recoverable-invocation-buggy-opclock.
\\* The same report-only deployment with OperatorSkew = 0: `now` is injected at
\\* a declared operator seam, as every other reading on this page is injected.
\\* It must HOLD. A twin that differs from nothing is evidence of nothing.
""", (), REPORT_ONLY)[0].replace("recoverable-invocation-buggy-REPLACE",
                                "probe-reportonly-clean")
sib = sib.replace("BUGGY TWIN (vacuity guard)", "PASSING SIBLING")
open(os.path.join(D, "probe-reportonly-clean.tla"), "w").write(sib)
open(os.path.join(D, "probe-reportonly-clean.cfg"), "w").write(REPORT_ONLY)
print("wrote %d twins + the report-only passing sibling" % len(twins))

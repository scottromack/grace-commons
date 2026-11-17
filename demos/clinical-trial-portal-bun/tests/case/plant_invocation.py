#!/usr/bin/env python3
"""Fault Plants on Recoverable Invocation's Open, Close, Refuse, Yield and Reconcile: each plant changes one thing in one source file, that
file's own test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules
and XTDB up:  python3 tests/case/plant_invocation.py"""
import re, subprocess

PLANTS = [
    ("src/recoverable_invocation.ts", "tests/recoverable_invocation.test.ts", [
        ("an unbound kind not refused", 'if (!b) return { refused: "invalid-request" };', ''),
        ("the service identity may open", 'if (b.serviceIdentity !== null && actor_ref === b.serviceIdentity) return { refused: "invalid-request" };', ""),
        ("an in-flight intent not refused before the take", 'if (first) return { refused: "act-in-flight", invocation_id: first.invocation_id };', ""),
        ("an aged intent refused as in-flight only", "open.find((r) => inflight(r) || b.serviceIdentity !== null)", "open.find((r) => inflight(r))"),
        ("act-landed never answered", "if (!b.repeatable) {", "if (false) {"),
        ("the intent written without a write-floor reading", 'if (!(await this.above(kind, act_key, invocation_id, this.writeFloor))) return out({ refused: "section-unavailable" });', ""),
        ("the commit floor never read", "if (!(await this.above(kind, act_key, invocation_id, this.commitFloor))) {", "if (false) {"),
        ("an outcome ref outside the enumerated refs written", "if (!b || !b.outcomes.includes(outcome_action_ref)) {", "if (!b) {"),
        ("an escalation adopted as the outcome", 'if (stands.role !== "outcome") return done(fail);', ""),
        ("landing actor always the invocation", 'stands.resolving_actor ? "operator" : stands.recovery ? "sweep" : "invocation"', '"invocation"'),
        ("a failed outcome write not retried", 'if (w.t === "retry") continue;', 'if (w.t === "retry") return done(fail);'),
        ("a closing already naming the invocation not found at refuse", 'if (stands) return done({ refused: "already-accounted"', 'if (false) return done({ refused: "already-accounted"'),
        ("a lost reply's grant released at yield", 'if (reply === "lost") return "ok";', ""),
        ("the mark advanced before settle bound", "if (this.ms(ev.recorded_at) + this.settleBound > now) break;", ""),
        ("retention end never dropped", "&& this.ms(r.recorded_at) + b.retentionPeriodMs - this.cfg.clockAllowanceMs > now", "&& true"),
        ("supersession not read", "const named = new Set(closings.map((c) => c.supersedes).filter((s): s is string => !!s));", "const named = new Set<string>();"),
        ("a lost reply read back before journal write bound", "while (this.ms(this.seam.now()) < issued + this.cfg.journalWriteBoundMs) await this.sleep(Math.max(1, issued + this.cfg.journalWriteBoundMs - this.ms(this.seam.now())));", ""),
        ("a step-4 read-back finding the record raises no alert", "{ t: \"landed\", event_id: found.event_id, alert: true }", "{ t: \"landed\", event_id: found.event_id, alert: false }"),
    ]),
    ("src/recoverable_invocation.ts", "tests/recoverable_invocation.sweep.test.ts", [
        ("an in-flight intent examined", "const aged = this.ms(r.recorded_at) + b.invocationCompletionBoundMs + allow <= now;", "const aged = true;"),
        ("an intent past its horizon edge examined", "if (aged && now < horizonEdge) kept.push(r);", "if (aged) kept.push(r);"),
        ("the intents examined latest first", "kept.sort((a, c) => a.seq - c.seq);", "kept.sort((a, c) => c.seq - a.seq);"),
        ("a closing found at the re-read not honoured", "if (this.standing(rec.invocation_id) || this.sweepClosed.has(rec.invocation_id)) { landed.add", "if (false) { landed.add"),
        ("the write floor never read before the probe", 'if (!(await this.above(rec.kind, rec.act_key, holder, this.writeFloor))) return "skipped";', ""),
        ("an unavailable probe not counted skipped", 'mark(seen, "store-unavailable", rec.kind); return "skipped"; }', 'mark(seen, "store-unavailable", rec.kind); return "closed"; }'),
        ("an unavailable probe opens no finding", 'if (probe.answer === "unavailable") { mark(seen, "store-unavailable", rec.kind); return "skipped"; }', 'if (probe.answer === "unavailable") { return "skipped"; }'),
        ("the probe's answer is no condition read", 'mark(gone, "store-unavailable", rec.kind);', ""),
        ("a rejection of the probe read as not-committed", 'catch { return { answer: "unavailable" }; }', 'catch { return { answer: "not-committed" }; }'),
        ("a missing probe read as not-committed", ': { answer: "unavailable" }; } catch', ': { answer: "not-committed" }; } catch'),
        ("a not-committed act escalated with the wrong cause", 'return escalate(rec, holder, { cause: "not-observed" });', 'return escalate(rec, holder, { cause: "undecidable" });'),
        ("candidates not capped", "database_candidates: probe.candidates.slice(0, this.cfg.intentCandidatesCap),", "database_candidates: probe.candidates,"),
        ("the count and range past the cap dropped", "...(over ? {", "...(false ? {"),
        ("a report-only act counted closed", 'return "reported";', 'return "closed";'),
        ("a probe's outcome outside the enumerated refs written", "if (!b.outcomes.includes(probe.outcome_action_ref)) {", "if (false) {"),
        ("the acting actor reference left off the outcome", "recovery: true, acting_actor_ref: rec.actor_ref })", "recovery: true })"),
        ("an outcome that cannot be recorded not escalated", 'if (closing.t === "unrecordable") return escalate(rec, holder, { cause: "outcome-unrecordable" });', 'if (closing.t === "unrecordable") return "skipped";'),
        ("a left write opens no outage finding", 'if (closing.journal) mark(seen, "journal-unavailable", null);', ""),
        ("a retry not made", 'case "retry": retried = true; continue;', 'case "retry": return { t: "later", journal: false };'),
        ("a lost reply with no answer opens the outage finding", 'case "lost-nothing": return { t: "later", journal: w.step3 };', 'case "lost-nothing": return { t: "later", journal: true };'),
        ("a step-4 read-back finding nothing raises no alert", 'this.cfg.compliance.hardAlert({ invocation_id, arm: "invalid-request-step-4" });', ""),
        ("a step-4 read-back finding the record raises no alert", 'if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "sweep-read-back" });', ""),
        ("a refused credential raises no alert", 'this.cfg.compliance.hardAlert({ invocation_id: rec.invocation_id, arm: "credential-refused" });', ""),
        ("the kind's other intents still written after a refused credential", "unreachedKinds.add(rec.kind);", ""),
        ("the unreached intents not counted", 'if (unreachedKinds.has(rec.kind)) { tally.unreached++; continue; }', 'if (unreachedKinds.has(rec.kind)) { continue; }'),
        ("a refused credential surfaces nothing at risk", "for (const k of kept) if (k.kind === rec.kind) safe(", "for (const k of kept) if (false) safe("),
        ("the escalation of a refused credential counts as done", 'if (closing.t === "credential") { credentialRefused(rec); return "skipped"; }', 'if (closing.t === "credential") { return "skipped"; }'),
        ("a release that fails leaves the act counted", 'if (!(await this.release(rec.kind, rec.act_key, holder))) count = "skipped";', ""),
        ("a take that answers unavailable goes on", 'if (took === "unavailable") { tally.skipped++; continue; }', ""),
        ("a stalled read gives an answer", 'if (first === "stalled") return "no-answer";', ""),
        ("a failed enumeration opens no outage finding", 'if (!e.invalidQuery) mark(seen, "journal-unavailable", null);                                                 // reconcile 1b', "                                                                                                                  // reconcile 1b"),
        ("an invalid-query at the re-read opens the outage finding", "        if (!e.invalidQuery) mark(seen, \"journal-unavailable\", null);", "        mark(seen, \"journal-unavailable\", null);"),
        ("a run that enumerates closes no outage finding", 'mark(gone, "journal-unavailable", null);', ""),
        ("an unbound intent named by a record still surfaced", 'if (recs.some((x) => x.role === "unbound-named")) continue;', ""),
        ("the unbound pass not bounded by retention", "if (this.ms(r.recorded_at) + maxRetention <= now) continue;", ""),
        ("an unbound intent not counted", "tally.surfaced++;", ""),
        ("a second run beside the first", "if (this.runInFlight) return this.runInFlight;", ""),
        ("closure-at-risk surfaced before the threshold", "if (landed.has(rec.invocation_id) || atRisk > now - this.ms(rec.recorded_at)) continue;", "if (landed.has(rec.invocation_id)) continue;"),
        ("an escalation not watched near the horizon", "if (now >= settlingEdge) safe(", "if (false) safe("),
        ("the settling period left out of the settling edge", "- (b.settlingPeriodMs ?? 0);", ";"),
        ("a condition that stands closed beside its own sighting", "for (const [k, [f, kind]] of gone) if (!seen.has(k))", "for (const [k, [f, kind]] of gone) if (true)"),
        ("an act finding recorded twice", "if (this.acts.some((f) => f.invocation_id === invocation_id && f.finding === finding)) return;", ""),
        ("an instance finding not advanced", "standing.last_seen = run; return;", "return;"),
        ("an instance finding named as an act finding", "if (!ACT_FINDINGS.has(finding)) throw new Error", "if (false) throw new Error"),
        ("an operator's outcome read as the sweep's", "(rec.role === \"outcome\" && rec.recovery && !rec.resolving_actor)", "(rec.role === \"outcome\" && rec.recovery)"),
        ("Instance start 4 not checked", "if (!(s.closureWindowMs > worstClosure))", "if (false)"),
        ("Instance start 5 not checked", "if (!(b.retentionPeriodMs > retentionFloor))", "if (false)"),
        ("Instance start 6 not checked", "if (!(icb > leaseSpend))", "if (false)"),
        ("Instance start 7 not checked", "if (runFloor > s.runBoundMs)", "if (false)"),
        ("Instance start 8 not checked", "if (!(s.closureLatencyMs > sweepLeaseSpend))", "if (false)"),
    ]),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

seen = total = 0

def fresh_stack():
    # the in-memory XTDB runs out of room after some twenty test files; a plant is only counted against a stack that is up
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)
for src, test, plants in PLANTS:
    orig = open(src).read()
    try:
        for name, old, new in plants:
            if old not in orig:
                print("NOT APPLIED:", src, name); continue
            open(src, "w").write(orig.replace(old, new, 1))
            if total % 8 == 0: fresh_stack()
            n = fails(test); total += 1; seen += n > 0
            print("%-12s %-46s %d fail" % (src.split("/")[-1][:12], name, n))
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))

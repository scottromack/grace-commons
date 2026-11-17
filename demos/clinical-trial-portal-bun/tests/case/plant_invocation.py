#!/usr/bin/env python3
"""Fault Plants on Recoverable Invocation's Open, Close, Refuse, Yield, Reconcile, Resolve and Read Invocation: each plant changes one thing in one source file, that
file's own test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules
and XTDB up:  python3 tests/case/plant_invocation.py [part of a test file's name [part of a plant's name]]"""
import re, subprocess, sys

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
    ("src/recoverable_invocation.ts", "tests/recoverable_invocation.resolve.test.ts", [
        ("an unbound kind resolved", "if (!b) return malformed;", ""),
        ("an outcome ref outside the enumerated refs written", "|| !b.outcomes.includes(d.outcome_action_ref)) return malformed;", ") return malformed;"),
        ("a disposition outside the three forms written", "} else return malformed;", "}"),
        ("the candidates cap not checked", "if (d.candidates.length > this.cfg.intentCandidatesCap) return", "if (false) return"),
        ("the candidates cap's boundary refused", "if (d.candidates.length > this.cfg.intentCandidatesCap)", "if (d.candidates.length >= this.cfg.intentCandidatesCap)"),
        ("the operator run id the invocation id", "const holder = this.seam.idMaterial();", "const holder = invocation_id;"),
        ("the take's term not the sweep lease", "holder, sw.closureLatencyMs + this.cfg.journalWriteBoundMs); }", "holder, this.cfg.journalWriteBoundMs); }"),
        ("a take that answers unavailable goes on", 'if (took === "unavailable") return { refused: "section-unavailable" };\n    const out = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, holder);', 'const out = async <T>(r: T): Promise<T> => { await this.release(kind, act_key, holder);'),
        ("the write floor never read before the re-read", '(resolve 38, 8).\n    if (!(await this.above(kind, act_key, holder, this.writeFloor))) return out({ refused: "section-unavailable" });', "(resolve 38, 8)."),
        ("the write floor never read before the closing", '(resolve 39, 21).\n    if (!(await this.above(kind, act_key, holder, this.writeFloor))) return out({ refused: "section-unavailable" });', "(resolve 39, 21)."),
        ("a re-read that fails goes on", "try { await this.refresh(); } catch (e) {\n      if (e instanceof ReadFailed) return out(failed);", "try { await this.refresh(); } catch (e) {\n      if (e instanceof ReadFailed) {}"),
        ("no re-read under the section", "try { await this.refresh(); } catch (e) {\n      if (e instanceof ReadFailed) return out(failed);", "try { } catch (e) {\n      if (e instanceof ReadFailed) return out(failed);"),
        ("a read_record with no answer read as not-known", 'if (rec === "no-answer") return out(failed);', 'if (rec === "no-answer") return out({ refused: "not-known" });'),
        ("a read_record that fails read as not-known", "if (e instanceof ReadFailed || e instanceof Unavailable) return out(failed);", 'if (e instanceof ReadFailed || e instanceof Unavailable) return out({ refused: "not-known" });'),
        ("read_record's read bound not applied", "readBound === undefined ? await call : await Promise.race([call,", "true ? await call : await Promise.race([call,"),
        ("a not-known read_record read as recording-failure", 'if (rec === "not-known") return out({ refused: "not-known" });', 'if (rec === "not-known") return out(failed);'),
        ("a Purged payload not refused", 'if (typeof rec.retention === "object" && rec.retention.state === "purged") return out({ refused: "invalid-request", cause: "purged" });', ""),
        ("a record that is no intent accepted", "rec.action_ref !== `${kind}.intended` ||", ""),
        ("an intent of another invocation accepted", "named?.invocation_id !== invocation_id ||", ""),
        ("an intent of another act accepted", "|| named?.act_key !== act_key", ""),
        ("a refusal or the sweep's outcome superseded", 'if (stands.role === "refused" || (stands.role === "outcome" && !stands.resolving_actor)) return out({ refused: "already-accounted", closing_event_id: stands.event_id });', ""),
        ("an operator's outcome superseded by any disposition", 'if (d.form !== "outcome") return out({ refused: "already-accounted", closing_event_id: stands.event_id });', ""),
        ("an abandonment superseded by any disposition", 'if (d.form !== "outcome") return out({ refused: "invalid-request", cause: "already-abandoned" });', ""),
        ("an escalation not named in supersedes", '} else if (stands.role === "escalated") supersedes = stands.event_id;', '} else if (stands.role === "escalated") {}'),
        ("supersedes never carried", "...(supersedes ? { supersedes } : {})", ""),
        ("too-young never refused", 'if (inflight) return out({ refused: "invalid-request", cause: "too-young" });', ""),
        ("too-young compared without the allowance", "+ this.cfg.clockAllowanceMs > this.ms(this.seam.now())", "> this.ms(this.seam.now())"),
        ("too-young guarding every disposition", 'if (d.form === "abandoned") {\n      const intent =', 'if (true) {\n      const intent ='),
        ("the resolving actor left off the closing", "resolving_actor: actor_ref, acting_actor_ref: rec.actor_ref,", "acting_actor_ref: rec.actor_ref,"),
        ("the acting actor left off the closing", "acting_actor_ref: rec.actor_ref, ...(supersedes", "...(supersedes"),
        ("recovery not set on the closing", "intent_event_id, recovery: true, resolving_actor: actor_ref", "intent_event_id, resolving_actor: actor_ref"),
        ("the closing written under the service identity", "this.write(ref, actor_ref, credential, payload, invocation_id, supersedes)", "this.write(ref, b.serviceIdentity ?? actor_ref, b.serviceCredential ?? credential, payload, invocation_id, supersedes)"),
        ("an abandonment written as an escalation", "[`${kind}.abandoned`, { ...base, cause: d.cause }]", "[`${kind}.escalated`, { ...base, cause: d.cause }]"),
        ("the candidates left off the escalation", "database_candidates: d.candidates", "database_candidates: []"),
        ("the outcome data left off", "{ ...base, data: d.outcome_data }", "{ ...base }"),
        ("the cause left off the abandonment", "{ ...base, cause: d.cause }", "{ ...base }"),
        ("a refused credential read as recording-failure", 'case "invalid-credential": return out({ refused: "invalid-credential" });', 'case "invalid-credential": return out(failed);'),
        ("an invalid-request raises no alert", 'this.cfg.compliance.hardAlert({ invocation_id, arm: "invalid-request" });', "void 0;"),
        ("a step-4 read-back finding the record raises no alert", 'if (w.alert) this.cfg.compliance.hardAlert({ invocation_id, arm: "resolution-read-back" });', ""),
        ("a write that failed read as landed", "default: return out(failed);", 'default: return out({ closing_event_id: "unwritten" });'),
        ("a lost reply adopts an earlier closing of the same reference", "(supersedes === undefined || r.supersedes === supersedes)", "true"),
        ("the section not released after the write", "return out({ closing_event_id: w.event_id });", "return { closing_event_id: w.event_id };"),
        ("an unbound kind read", 'if (!b) return { refused: "not-known" };', 'if (false) return { refused: "not-known" };'),
        ("a failed range read answered not-known", '(Term read path)\n      if (e instanceof ReadFailed) return { refused: "journal-unavailable" };', '(Term read path)\n      if (e instanceof ReadFailed) return { refused: "not-known" };'),
        ("an act with no intent answered with a report", 'if (!intents.length) return { refused: "not-known" };', ""),
        ("retention not applied to a readable intent", '.filter((r) => r.role === "intent" && this.ms(r.recorded_at) + b.retentionPeriodMs - this.cfg.clockAllowanceMs > now)', '.filter((r) => r.role === "intent")'),
        ("the invocations latest first", ".sort((x, y) => x.seq - y.seq);\n    if (!intents.length)", ".sort((x, y) => y.seq - x.seq);\n    if (!intents.length)"),
        ("the records latest first", '&& r.role !== "unbound-named")\n        .sort((x, y) => x.seq - y.seq);', '&& r.role !== "unbound-named")\n        .sort((x, y) => y.seq - x.seq);'),
        ("a superseded closing excluded", '&& r.role !== "unbound-named")', '&& r.role !== "unbound-named" && !(this.byInvocation.get(intent.invocation_id) ?? []).some((c) => c.supersedes === r.event_id))'),
        ("the recovery_intended records left out", 'filter((r) => r.role !== "intent" && ', 'filter((r) => r.role !== "intent" && r.role !== "recovery_intended" && '),
        ("every state read as open", 'if (!s) return "open";', 'if (true) return "open";'),
        ("an operator's abandonment read as abandoned", 's.resolving_actor ? "resolved" : "abandoned"', '"abandoned"'),
        ("a refusal read as closed", ': s.role === "refused" ? "refused"', ': s.role === "refused" ? "closed"'),
        ("an escalation read as open", 's.role === "escalated" ? "escalated"', 's.role === "escalated" ? "open"'),
        ("an unknown invocation id given an entry", 'if (!one) return { refused: "not-known" };', ""),
        ("a blank invocation id read as one", "if (invocation_id !== undefined && !isBlank(invocation_id)) {", "if (invocation_id !== undefined) {"),
        ("the read cap not applied to records", "const kept = all.length > cap ? all.slice(all.length - cap) : all;", "const kept = all;"),
        ("the oldest records kept at the read cap", "all.slice(all.length - cap)", "all.slice(0, cap)"),
        ("the oldest invocations kept at the read cap", "intents.slice(intents.length - cap)", "intents.slice(0, cap)"),
        ("more not set on an entry", "more: all.length > kept.length", "more: false"),
        ("more not set on a report", "more: intents.length > recent.length", "more: false"),
    ]),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

seen = total = 0
only = sys.argv[1] if len(sys.argv) > 1 else ""      # a substring of a test file's name: run that file's plants alone
named = sys.argv[2] if len(sys.argv) > 2 else ""     # a substring of a plant's name: run the plants it names alone

def fresh_stack():
    # the in-memory XTDB runs out of room after some twenty test files; a plant is only counted against a stack that is up
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)
for src, test, plants in PLANTS:
    if only not in test: continue
    orig = open(src).read()
    try:
        for name, old, new in plants:
            if named not in name: continue
            if old not in orig:
                print("NOT APPLIED:", src, name); continue
            open(src, "w").write(orig.replace(old, new, 1))
            if total % 8 == 0: fresh_stack()
            n = fails(test); total += 1; seen += n > 0
            print("%-12s %-46s %d fail" % (src.split("/")[-1][:12], name, n))
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))

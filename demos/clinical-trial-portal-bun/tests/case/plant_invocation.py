#!/usr/bin/env python3
"""Fault Plants on Recoverable Invocation's Open, Close, Refuse and Yield: each plant changes one thing in one source file, that
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
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

seen = total = 0
for src, test, plants in PLANTS:
    orig = open(src).read()
    try:
        for name, old, new in plants:
            if old not in orig:
                print("NOT APPLIED:", src, name); continue
            open(src, "w").write(orig.replace(old, new, 1))
            n = fails(test); total += 1; seen += n > 0
            print("%-12s %-46s %d fail" % (src.split("/")[-1][:12], name, n))
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))

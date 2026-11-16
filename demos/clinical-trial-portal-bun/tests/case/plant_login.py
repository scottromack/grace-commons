#!/usr/bin/env python3
"""Fault Plants on the rendered Login: each plant changes one thing in src/login.ts, the tests run, the plant is put back.
A plant is seen when some test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_login.py
Prints, for each plant, the failures of the whole login suite and of the Case Tests alone (a plant only the hand-written suite sees is a rule no closure-table row owns)."""
import re, subprocess

SRC = "src/login.ts"
orig = open(SRC).read()
PLANTS = [
    ("issue a session without the verify gate", 'if (verified !== "verified") {', "if (false) {"),
    ("blank principal not refused", 'if (isBlank(principal_ref) || isBlank(credential_type) || isBlank(presented_material)) return { refused: "invalid-request" };', ""),
    ("issuer references not checked", 'if (!this.cfg.issuerReferences.includes(issued_by_ref)) return { refused: "invalid-request" };', ""),
    ("no duration, none set, not refused", 'if (seconds === null || seconds === undefined) return { refused: "invalid-request" };', ""),
    ("a wrong password answers a session", 'if ("event_id" in r) return "invalid-credential";', 'if ("event_id" in r) return { session_token: "x" } as never;'),
    ("cascade reason prefix dropped", "const cascadeReason = `${CASCADE_REASON_PREFIX}${init.event_id}: ${reason}`;", "const cascadeReason = reason;"),
    ("a revoked session counted skipped", 'if ("event_id" in r) tally.revoked++;', 'if ("event_id" in r) tally.skipped++;'),
    ("map write failure surfaces", "} catch { /* Action wiring 10, Reconciliation 20 */ }", "} catch (e) { throw e; }"),
    ("logout skips the map check", 'if (!(await this.credentialOf(session_token))) return { refused: "not-known" };', ""),
    ("state-unavailable not answered", 'catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }', "catch (e) { throw e; }"),
    ("cascade skips its initiation event", 'const init = await this.commitWithEvent([], "credential_revocation_cascade_initiated", { credential_id, revoked_by_ref, reason });', 'const init = { event_id: "evt-init" } as { event_id: string };'),
    ("login event not mirrored with the entry id", "{ ...call, entry_id, credential_id: cred.credential_id, session_token: issued.session_token }", "{ ...call, credential_id: cred.credential_id, session_token: issued.session_token }"),
    ("the credential id lookup not refused", 'if (!cred) return { refused: "storage-failure", stage: "credential-id-lookup" };', ""),
    ("logout accepts a cascade-prefixed reason", 'if (typeof reason === "string" && reason.startsWith(CASCADE_REASON_PREFIX)) return { refused: "invalid-request" };', ""),
    ("cascade never completes", 'const done = await note("credential_revocation_cascade_completed"', 'const done = await note("credential_revocation_cascade_completed_NOT"'),
]

def fails(*files):
    r = subprocess.run(["./node_modules/.bin/bun", "test", *files], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

seen = case_seen = 0
try:
    for name, old, new in PLANTS:
        if old not in orig:
            print("NOT APPLIED:", name); continue
        open(SRC, "w").write(orig.replace(old, new, 1))
        total, case = fails("tests/login.test.ts", "tests/case"), fails("tests/case")
        seen += total > 0; case_seen += case > 0
        print("%-46s suite %d fail, Case Tests %d fail" % (name, total, case))
finally:
    open(SRC, "w").write(orig)
print("%d of %d planted faults seen by the login suite; %d by the Case Tests alone" % (seen, len(PLANTS), case_seen))

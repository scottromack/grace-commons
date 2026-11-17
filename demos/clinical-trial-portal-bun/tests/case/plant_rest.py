#!/usr/bin/env python3
"""Fault Plants on Credential, Session, Event Log, Tamper Evidence, Actor Identity, Retention Window, Party Identity and Audit Trail's Record Action: each plant changes one thing in one source file, that
file's own test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules
and XTDB up:  python3 tests/case/plant_atoms.py"""
import re, subprocess

PLANTS = [
    ("src/credential.ts", "tests/credential.test.ts", [
        ("EQUIVALENT MUTANT, not counted: the pre-check of a held pair dropped (the guard in the write answers the same)", 'if ((await this.pair(principal_ref, credential_type)).some((c) => Credential.live(c, now))) return { refused: "duplicate-active-credential" };', ""),
        ("a lapse read from the stored status", 'return c.status === "active" && (c.expires_at === null || now < c.expires_at);', 'return c.status === "active";'),
        ("a revoke with blank attribution accepted", 'if (isBlank(revoked_by_ref) || isBlank(reason)) return { refused: "invalid-request" };', ""),
        ("a wrong material verifies", 'return ok ? "verified" : { failed: "material-mismatch" };', 'return "verified";'),
    ]),
    ("src/session.ts", "tests/session.test.ts", [
        ("a lapsed session validates", 'if (Session.lapsed(s, this.seam.now())) return { invalid: "expired" };', ""),
        ("a revoked session validates", 'if (s.status === "revoked") return { invalid: "revoked" };', ""),
        ("a zero duration accepted", 'if (session_duration <= 0) return { refused: "invalid-request" };', ""),
    ]),
    ("src/event_log.ts", "tests/event_log.test.ts", [
        ("the head guard dropped", 'this.store.assertSome(H, "_id = $1 AND next_seq = $2", [this.cfg.name, first], "log-moved")', 'this.store.assertNone(H, "_id = $1 AND next_seq > 999999999", [this.cfg.name], "log-moved")'),
        ("the payload cap ignored", 'if (texts.some((t) => new TextEncoder().encode(t).length > this.cfg.payloadCap)) return { refused: "invalid-payload" };', ""),
        ("a malformed sequence query accepted", 'if (!whole(s.from) || (s.to !== undefined && !whole(s.to)) || (s.to !== undefined && s.from > s.to)) return { refused: "invalid-query" };', ""),
    ]),
    ("src/tamper_evidence.ts", "tests/tamper_evidence.test.ts", [
        ("a tampered record set verifies", 'if (check === "failed") return { failed: "proof-invalid" };', ""),
        ("the wrong record set not told apart", 'if (!this.mech.match(e.record_set_ref, original)) return { failed: "record-set-mismatch" };', ""),
        ("a keyed seal with a blank credential accepted", 'if (isBlank(mechanism_credential) && !this.mech.unkeyed) return { refused: "invalid-request" };', ""),
    ]),
    ("src/actor_identity.ts", "tests/actor_identity.test.ts", [
        ("a failed credential attests", 'if (check === "failed") return { refused: "invalid-credential" };', ""),
        ("an unknown actor refused as a different answer", 'if (reg.answer === "unknown-actor") return { refused: "invalid-credential" };', 'if (reg.answer === "unknown-actor") return { refused: "invalid-request" };'),
        ("an earlier material not tried", "const materials = [reg.current, ...(reg.historical ?? [])];", "const materials = [reg.current];"),
    ]),
    ("src/retention_window.ts", "tests/retention_window.test.ts", [
        ("an early purge allowed", 'if (now < Date.parse(r.retention_until)) return { refused: "retention-period-not-elapsed" };', ""),
        ("a zero duration policy accepted", 'if (!Number.isFinite(durationMs) || !(durationMs > 0)) return { refused: "invalid-policy" };', ""),
    ]),
    ("src/party_identity.ts", "tests/party_identity.test.ts", [
        ("a verify result outside passed and failed accepted", 'if (verification_result !== "passed" && verification_result !== "failed") return { refused: "invalid-request" };', ""),
        ("a closed party acted on", 'if (p.state === "closed") return "already-closed";', ""),
        ("a verification before the suspend counts as fresh", 'v.verification_result === "passed" && v.insertion > lastSuspend', 'v.verification_result === "passed"'),
    ]),
    ("src/audit_trail.ts", "tests/audit_trail.test.ts", [
        ("the reserved namespace open to any caller", 'if (reserved && actor_ref !== this.cfg.reconciliationOperator) return false;', ""),
        ("invalid-credential not passed through", 'if (att.refused === "invalid-credential") return { refusal: { refused: "invalid-credential" }, keep: [] };', ""),
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

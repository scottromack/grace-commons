#!/usr/bin/env python3
"""Fault Plants on Permissions, Session-Gated Authorization, Invitation and Lease: each plant changes one thing in one source file, that
file's own test file runs, the plant is put back. A plant is seen when a test fails. Run from the demo directory in a copy with node_modules
and XTDB up:  python3 tests/case/plant_atoms.py"""
import re, subprocess

PLANTS = [
    ("src/permissions.ts", "tests/permissions.test.ts", [
        ("a second grant on a held pair writes again", "if (inForce.length > 0) return { held: inForce[0]._id };", ""),
        ("blank subject not refused", "if (isBlank(subject_ref) || isBlank(action_scope)) return { refused: \"invalid-request\" };", ""),
        ("an equivalent mutant, not a gap: revoke's own status check dropped (the guard in the write answers the same)", "if (g.status === \"revoked\") return { refused: \"not-active\" };", ""),
        ("permitted matches case-folded", "WHERE subject_ref = $1 AND action_scope = $2 AND status = 'active'`, [subject_ref, action_scope]);", "WHERE LOWER(subject_ref) = LOWER($1) AND action_scope = $2 AND status = 'active'`, [subject_ref, action_scope]);"),
        ("the pair guard dropped", "this.store.assertNone(this.T, \"subject_ref = $1 AND action_scope = $2 AND status = 'active'\", [subject_ref, action_scope], \"pair-held\"), // Identity 7, Database 2", ""),
    ]),
    ("src/session_gated_authorization.ts", "tests/session_gated_authorization.test.ts", [
        ("permissions called for an invalid session", "if (\"invalid\" in v) return { refused: \"session-invalid\", reason: v.invalid };", "if (\"invalid\" in v) await this.permissions.permitted(\"x\", action_scope);\n      if (\"invalid\" in v) return { refused: \"session-invalid\", reason: v.invalid };"),
        ("inputs trimmed", "if (isBlank(session_token) || isBlank(action_scope)) return { refused: \"invalid-request\" };", "session_token = session_token.trim(); action_scope = action_scope.trim();\n    if (isBlank(session_token) || isBlank(action_scope)) return { refused: \"invalid-request\" };"),
        ("length bound ignored", "if ([...session_token].length > this.lengthBound || [...action_scope].length > this.lengthBound) return { refused: \"invalid-request\" };", ""),
        ("state-unavailable not answered", "if (e instanceof Unavailable) return { refused: \"state-unavailable\" };", "if (e instanceof Unavailable) throw e;"),
    ]),
    ("src/invitation.ts", "tests/invitation.test.ts", [
        ("a stored terminal can be resolved again", "if (i.status !== \"pending\") return { refused: \"already-resolved\", status: i.status };", ""),
        ("a lapsed invitation not refused", "if (Invitation.lapsed(i, this.seam.now())) return { refused: \"expired\" };", ""),
        ("the single-resolution guard dropped", "this.store.assertSome(this.T, \"_id = $1 AND status = 'pending'\", [i._id], \"resolved\"),               // Invariant 2.1: one stored terminal at most", ""),
        ("ttl bounds ignored", "if (ttl < this.cfg.ttlBounds.min || ttl > this.cfg.ttlBounds.max) return { refused: \"invalid-request\" };", ""),
        ("status filter matches the effective status", "status: i.status, effective_status", "status: Invitation.lapsed(i, now) ? \"expired\" : i.status, effective_status"),
    ]),
    ("src/lease.ts", "tests/lease.test.ts", [
        ("a held key taken again", "if (!s.free || (await this.standing(key, true)).length > 0) return \"held\";", "if ((await this.standing(key, true)).length > 0) return \"held\";"),
        ("release reaches another holder", "if (s.free || !s.lease || s.lease.holder !== holder) return \"not-held\";\n      try {", "if (s.free || !s.lease) return \"not-held\";\n      try {"),
        ("remaining answers any party", "if (s.free || !s.lease || s.lease.holder !== holder) return \"none\";", "if (s.free || !s.lease) return \"none\";"),
        ("the version guard on a take dropped", "seen ? this.store.assertSome(this.L, \"_id = $1 AND version = $2\", [key, Number(seen.version)], \"lease-moved\") : this.store.assertNone(this.L, \"_id = $1\", [key], \"lease-moved\"),", "this.store.assertNone(this.L, \"_id = $1 AND version > 99999\", [key], \"lease-moved\"),"),
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

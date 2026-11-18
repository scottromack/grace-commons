#!/usr/bin/env python3
"""Fault Plants on Session-Gated Authorization, against the Edge Finder's Case Tests (tests/case/session_gated_authorization.case.test.ts)
and not the hand tests of plant_atoms.py: each plant changes one thing in src/session_gated_authorization.ts, the Case Tests run, the plant
is put back. A plant is seen when a test fails; one not seen is said. Run from the demo directory:  python3 tests/case/plant_sga_case.py"""
import re, subprocess

SRC, TEST = "src/session_gated_authorization.ts", "tests/case/session_gated_authorization.case.test.ts"
PLANTS = [
    ("permissions called for an invalid session", "if (\"invalid\" in v) return { refused: \"session-invalid\", reason: v.invalid };", "if (\"invalid\" in v) await this.permissions.permitted(\"x\", action_scope); if (\"invalid\" in v) return { refused: \"session-invalid\", reason: v.invalid };"),
    ("the invalid reason dropped", "return { refused: \"session-invalid\", reason: v.invalid };", "return { refused: \"session-invalid\", reason: \"not-known\" as never };"),
    ("session token trimmed", "const v = await this.session.validate(session_token);", "const v = await this.session.validate(session_token.trim());"),
    ("action scope case-folded", "return await this.permissions.permitted(v.valid.principal_ref, action_scope);", "return await this.permissions.permitted(v.valid.principal_ref, action_scope.toLowerCase());"),
    ("the caller's token asked of Permissions, not Session's principal", "return await this.permissions.permitted(v.valid.principal_ref, action_scope);", "return await this.permissions.permitted(session_token, action_scope);"),
    ("a denied answer changed to permitted", "return await this.permissions.permitted(v.valid.principal_ref, action_scope);", "{ await this.permissions.permitted(v.valid.principal_ref, action_scope); return \"permitted\"; }"),
    ("state-unavailable not answered", "if (e instanceof Unavailable) return { refused: \"state-unavailable\" };", "if (e instanceof Unavailable) throw e;"),
    ("a failed validate answered as session-invalid", "if (e instanceof Unavailable) return { refused: \"state-unavailable\" };", "if (e instanceof Unavailable) return { refused: \"session-invalid\", reason: \"not-known\" };"),
    ("blank scope not refused", "if (isBlank(session_token) || isBlank(action_scope)) return { refused: \"invalid-request\" };", "if (isBlank(session_token)) return { refused: \"invalid-request\" };"),
    ("length bound ignored", "if ([...session_token].length > this.lengthBound || [...action_scope].length > this.lengthBound) return { refused: \"invalid-request\" };", ""),
    ("length bound counted in bytes' place of one side only", "[...action_scope].length > this.lengthBound", "false"),
]

def fails():
    r = subprocess.run(["./node_modules/.bin/bun", "test", TEST, "--timeout", "30000"], capture_output=True, text=True)
    m = re.search(r"\n\s*(\d+) fail", r.stdout + r.stderr)
    return int(m.group(1)) if m else 0

if __name__ == "__main__":
    src = open(SRC).read()
    assert fails() == 0, "the Case Tests are not green before the plants"
    seen = 0
    for name, old, new in PLANTS:
        assert src.count(old) == 1, (name, src.count(old))
        open(SRC, "w").write(src.replace(old, new))
        try:
            f = fails()
        finally:
            open(SRC, "w").write(src)
        seen += f > 0
        print("%-4s %s (%d failing)" % ("SEEN" if f else "NOT SEEN", name, f), flush=True)
    print("%d of %d plants seen" % (seen, len(PLANTS)))

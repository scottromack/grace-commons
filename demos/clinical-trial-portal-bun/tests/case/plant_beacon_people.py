#!/usr/bin/env python3
"""Fault Plants on Beacon's people and the keys they sign with: each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_beacon_people.py [part of a plant's name]"""
import re, subprocess, sys

BP = "src/beacon_people.ts"
TEST = "tests/beacon_people.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("the salt not a person's own", BP, "const salt = randomBytes(16)", "randomBytes(16)", "Buffer.alloc(16)"),
    ("a password read without normalizing", BP, "scrypt(password.normalize(", '.normalize("NFC")', ""),
    ("an email not lowered", BP, "export const normalEmail", ".toLowerCase()", ""),
    ("an email not trimmed", BP, "export const normalEmail", "e.trim()", "e"),
    ("one email to many people", BP, 'this.store.assertNone(this.T, "email = $1"', 'this.store.assertNone(this.T, "email = $1", [email], "email-taken"),', ""),
    ("a blank input admitted", BP, "if (isBlank(a.party_id) || isBlank(a.email)", 'return { refused: "invalid-request" };', "{}"),
    ("an empty password admitted", BP, "if (isBlank(a.party_id) || isBlank(a.email)", ' || a.password === ""', ""),
    ("a display name not trimmed", BP, "display_name: a.display_name.trim()", "a.display_name.trim()", "a.display_name"),
    ("the seal's tag not checked", BP, "d.setAuthTag(", 'd.setAuthTag(Buffer.from(s.tag, "base64"));', ""),
    ("an unknown actor read as a person", BP, 'if (!p || typeof password !== "string") return null;', "!p || ", ""),
    ("the stored cost not used to open", BP, 'derive(password, Buffer.from(s.salt, "base64"), s)', ", s)", ", DEFAULT_SCRYPT)"),
    ("an email looked up as typed", BP, "[normalEmail(email)]", "normalEmail(email)", "email"),
    ("people listed newest first", BP, ".sort((a, b) => (a.created_at < b.created_at", "a.created_at < b.created_at ? -1 : a.created_at > b.created_at ? 1 : a._id < b._id ? -1 : 1", "a.created_at > b.created_at ? -1 : 1"),
    ("a session key held past its time", BP, "if (this.now() >= h.until)", ">=", ">"),
    ("an expired key kept", BP, "if (this.now() >= h.until)", "this.held.delete(session_token); ", ""),
    ("a key not dropped at sign-out", BP, "drop(session_token: string): void {", "this.held.delete(session_token);", ""),
]

def fails(f):
    r = subprocess.run(["./node_modules/.bin/bun", "test", f, "--timeout", "30000", "--bail"], capture_output=True, text=True)
    out = r.stdout + r.stderr
    return len(re.findall(r"^\(fail\)", out, re.M)) + (1 if "error: " in out and "Ran " not in out else 0)   # --bail prints no count; a file that does not load prints no "Ran"

def fresh_stack():
    subprocess.run(["bash", "stack/stack.sh", "restart"], capture_output=True, text=True)

named = sys.argv[1] if len(sys.argv) > 1 else ""
seen = total = 0
for name, src, tag, find, repl in PLANTS:
    if named not in name: continue
    orig = open(src).read()
    lines = orig.split("\n")
    hit = [i for i, l in enumerate(lines) if re.search(re.escape(tag) + (r"(?!\d)" if tag[-1].isdigit() else ""), l)]
    if len(hit) != 1 or (find and find not in lines[hit[0]]):
        print("NOT APPLIED:", name, len(hit), flush=True); continue
    lines[hit[0]] = lines[hit[0]].replace(find, repl, 1) if find else lines[hit[0]]
    try:
        open(src, "w").write("\n".join(lines))
        if total % 8 == 0: fresh_stack()
        n = fails(TEST); total += 1; seen += n > 0
        print("%-62s %d fail" % (name, n), flush=True)
    finally:
        open(src, "w").write(orig)
print("%d of %d planted faults seen" % (seen, total))

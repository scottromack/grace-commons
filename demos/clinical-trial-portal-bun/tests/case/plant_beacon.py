#!/usr/bin/env python3
"""Fault Plants on Beacon's composition root (the seed, signing in and out): each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_beacon.py [part of a plant's name]"""
import re, subprocess, sys

BR = "src/beacon.ts"
TEST = "tests/beacon.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("a seed account's password changed", BR, 'password: "demo-pi"', "demo-pi", "demo-p"),
    ("the second account's name changed", BR, 'name: "Jordan Lee"', "Jordan Lee", "Jordan"),
    ("the principal investigator holding no grant_permission", BR, 'holds: ["invite_actor", "grant_permission"', '"grant_permission", ', ""),
    ("the monitor holding another permission", BR, 'holds: ["view_audit"] }', '["view_audit"]', '["view_audit", "view_own_audit"]'),
    ("the date of birth placeholder changed", BR, 'export const partyFor', '"1900-01-01"', '"1990-01-01"'),
    ("the document type placeholder changed", BR, 'export const partyFor', '"beacon-account"', '"passport"'),
    ("the document reference not the email", BR, 'export const partyFor', "document_ref: email", "document_ref: name"),
    ("a person's actor reference not the party id", BR, "const m = await this.people.create({ party_id: e.party_id", "party_id: e.party_id", "party_id: e.party_id + 'x'"),
    ("the credential's principal not the party id", BR, "const c = await this.credentials.register(e.party_id", "e.party_id", "s.email"),
    ("a seeded person made twice", BR, "let p = await this.people.byEmail(s.email);", "await this.people.byEmail(s.email)", "null as never"),
    ("the grants given under another key", BR, "const r = await this.admin.issueGrant(m.actor_ref, code, pi.actor_ref, key);", "pi.actor_ref, key", "m.actor_ref, key"),
    ("a wrong email answered differently", BR, "const principal = person ? person.party_id", ": `unknown:${normalEmail(email)}`", ': ""'),
    ("a blank field admitted at sign-in", BR, 'if (isBlank(email) || typeof password !== "string" || password === "")', 'return { refused: "invalid-request" };', "{}"),
    ("the session issued by another reference", BR, 'const r = await this.login.login(principal, "password", password, "beacon");', '"beacon"', '"nobody"'),
    ("the key not held for the session", BR, "this.keys.hold(r.session_token, key,", "this.keys.hold(r.session_token, key,", "(() => {})(r.session_token, key,"),
    ("the key held past the session", BR, "this.keys.hold(r.session_token, key,", 'Date.parse(v.valid.expires_at)', "Date.parse(v.valid.expires_at) + 86400000 * 365"),
    ("the key not dropped at sign-out", BR, "    this.keys.drop(session_token);", "this.keys.drop(session_token);", ""),
    ("a session not revoked at sign-out", BR, 'if ("valid" in v) await this.login.logout(session_token, v.valid.principal_ref, "sign-out");', 'await this.login.logout(session_token, v.valid.principal_ref, "sign-out");', "{}"),
    ("an invalid session still someone", BR, 'if (!("valid" in v)) { this.keys.drop(session_token); return null; }', "return null;", ""),
    ("a session's holds not read", BR, "return { person, holds: await this.domain.held(person.actor_ref) };", "await this.domain.held(person.actor_ref)", "[]"),
    ("the session lasting a day", BR, "const WEEK_S = 7 * 86_400;", "7 * 86_400", "86_400"),
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

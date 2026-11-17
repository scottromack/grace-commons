#!/usr/bin/env python3
"""Fault Plants on Beacon's own domain (the study, subjects and visits): each plant changes one thing on the one line a tag names, the onboard test file runs, the plant is put back. A plant is seen
when a test fails. Run from the demo directory in a copy with node_modules and XTDB up:  python3 tests/case/plant_beacon_domain.py [part of a plant's name]"""
import re, subprocess, sys

BD = "src/beacon_domain.ts"
TEST = "tests/beacon_domain.test.ts"
# (name, file, tag: a substring of the one line to change, find: the text in that line, replace)
PLANTS = [
    ("a permission's words changed", BD, '{ code: "invite_actor", words: "Invite people" }', "Invite people", "Invite"),
    ("a visit kind dropped", BD, "export const VISIT_KINDS", '"week 12", ', ""),
    ("the study seeded on every start", BD, "if ((await store.read(`SELECT _id FROM ${STUDIES}", ".length === 0", ".length >= 0"),
    ("enrolling without enroll_subject", BD, "// SPEC.md, who may enroll", '!(await this.may(actor_ref, "enroll_subject"))', "false"),
    ("the enrollment event under another actor", BD, 'const done = await this.write("subject.enrolled"', '"subject.enrolled", actor_ref', '"subject.enrolled", "someone"'),
    ("the enrollment event's code left out", BD, 'const done = await this.write("subject.enrolled"', "{ target: row._id, study: STUDY.code, code }", "{ target: row._id, study: STUDY.code }"),
    ("a subject starting enrolled", BD, "const row: Subject = {", 'status: "screening"', 'status: "enrolled"'),
    ("the code the count and not the highest", BD, "Math.max(0, ...used) + 1", "Math.max(0, ...used) + 1", "used.length + 1"),
    ("the code padded to two digits", BD, 'padStart(3, "0")', 'padStart(3, "0")', 'padStart(2, "0")'),
    ("the code guard dropped", BD, 'this.store.assertNone(this.SUBJECTS, "code = $1"', 'this.store.assertNone(this.SUBJECTS, "code = $1", [code], "code-held"),', ""),
    ("a blank subject note kept", BD, "const row: Subject = {", "isBlank(notes) ? null : (notes as string)", "notes as string"),
    ("every subject seen by everyone", BD, "return { s: all.filter((x) => seeAll", "seeAll || ", "true || "),
    ("a person with no enroll or record permission seeing subjects", BD, 'if (!(await this.may(actor_ref, "enroll_subject", "record_visit")))', '!(await this.may(actor_ref, "enroll_subject", "record_visit"))', "false"),
    ("enroll_subject alone recording a visit", BD, "// SPEC.md, who records a visit", 'this.may(actor_ref, "record_visit")', 'this.may(actor_ref, "record_visit", "enroll_subject")'),
    ("a visit with any kind admitted", BD, "if (isBlank(kind) ||", " || !(VISIT_KINDS as readonly string[]).includes(kind)", ""),
    ("the visit-type message changed", BD, "if (isBlank(kind) ||", "message: MESSAGES.visitType", 'message: "invalid"'),
    ("visits newest first", BD, "(a.recorded_at < b.recorded_at ? -1", "a.recorded_at < b.recorded_at ? -1 : a.recorded_at > b.recorded_at ? 1 : a._id < b._id ? -1 : 1", "a.recorded_at > b.recorded_at ? -1 : 1"),
    ("another's subject answering access-denied", BD, "// another's subject answers as if it did not exist", '{ refused: "not-found", message: MESSAGES.notFound }', '{ refused: "access-denied", needs: ["record_visit"] }'),
    ("the event left out of the transaction", BD, "await this.store.commit([...change, ...p.stmts]);", ", ...p.stmts", ""),
    ("the change left out of the transaction", BD, "await this.store.commit([...change, ...p.stmts]);", "...change, ", ""),
    ("a moved log not planned again", BD, 'if (e instanceof Guard && e.guard === "log-moved") continue;', 'e.guard === "log-moved"', "false"),
    ("a refused credential answered storage-failure", BD, 'p.refusal.refused === "invalid-credential" ?', '=== "invalid-credential"', '=== "never"'),
    ("the record-visit mark by enroll_subject", BD, 'may_record: await this.may(actor_ref, "record_visit")', '"record_visit"', '"enroll_subject"'),
    ("the access-denied names for subjects", BD, 'return { refused: "access-denied", needs: ["enroll_subject", "record_visit"] };', '["enroll_subject", "record_visit"]', '["enroll_subject"]'),
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

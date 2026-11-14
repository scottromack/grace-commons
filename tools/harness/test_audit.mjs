// node --test test_audit.mjs — every check has a twin that breaks it (audit.mjs, twins.mjs).
// Each fixture is a tiny corpus in a temporary directory, audited with --root.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, existsSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { parseCfg, cfgWithChecks, checksOf, twinsOf, tautologies, tlaDefinitions } from "./twins.mjs";
import { appendLedger } from "./ledger.mjs";
import { hasProof, findTlapm } from "./tlapm.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

/** A corpus of files { "atoms/x.tla": text, ... } in a fresh directory. */
function corpus(files) {
  const root = mkdtempSync(join(tmpdir(), "audit-"));
  for (const [p, text] of Object.entries(files)) {
    mkdirSync(dirname(join(root, p)), { recursive: true });
    writeFileSync(join(root, p), text);
  }
  return root;
}
const audit = (root, env = {}, more = []) => spawnSync("node", [join(HERE, "audit.mjs"), "--root", root, "--jobs", "4", ...more],
  { env: { ...process.env, GRACE_STATES_LEDGER: "off", ...env }, encoding: "utf8" });

// A counter that climbs to 3. `step` is what a twin changes.
const counter = (name, { step = "x' = x + 1", extra = "", guard = "x < 3" } = {}) => `---- MODULE ${name} ----
EXTENDS Naturals
CONSTANT N
VARIABLE x
vars == <<x>>
Init == x = 0
Next == ${guard} /\\ ${step}
Spec == Init /\\ [][Next]_vars
TypeOK == x \\in Nat
Bounded == x <= 3
NotFive == x # 5
Safety == TypeOK /\\ Bounded /\\ NotFive
${extra}
====
`;
const cfg = (checks, more = "") => `SPECIFICATION Spec\n${checks.map((c) => `INVARIANT ${c}`).join("\n")}\n${more}CHECK_DEADLOCK FALSE\nCONSTANTS\n    N = 2\n`;

test("twins.mjs: an aggregate counts as its conjuncts, TypeOK not at all; a cfg's checks are replaced", () => {
  const root = corpus({ "atoms/c.tla": counter("c"), "atoms/c.cfg": cfg(["Safety"]) });
  assert.deepEqual(checksOf(join(root, "atoms/c.tla")), ["Bounded", "NotFive"]);
  const text = cfg(["Safety"], "ACTION_CONSTRAINT Up Down\n");
  assert.deepEqual(parseCfg(text).actionConstraints, ["Up", "Down"]);
  const out = cfgWithChecks(text, { invariants: ["Bounded"], drop: ["Up"] });
  assert.deepEqual(parseCfg(out), { invariants: ["Bounded"], properties: [], constraints: [], actionConstraints: ["Down"] });
  assert.match(out, /CONSTANTS\n {4}N = 2/);
  assert.equal(tlaDefinitions(counter("c")).get("Safety").body, "TypeOK /\\ Bounded /\\ NotFive");
});

test("twins.mjs: a twin belongs to the longest model name it extends", () => {
  const m = ["/r/a/x.tla", "/r/a/x-settle.tla", "/r/a/x.als"];
  const t = ["/r/a/x-buggy.tla", "/r/a/x-settle-buggy-y.tla", "/r/a/x-settle-z-buggy.tla", "/r/a/x-buggy.als", "/r/b/x-buggy.tla"];
  const f = twinsOf(m, t);
  assert.deepEqual(f.get("/r/a/x.tla"), ["/r/a/x-buggy.tla"]);
  assert.deepEqual(f.get("/r/a/x-settle.tla"), ["/r/a/x-settle-buggy-y.tla", "/r/a/x-settle-z-buggy.tla"]);
  assert.deepEqual(f.get("/r/a/x.als"), ["/r/a/x-buggy.als"]);
});

// A pattern's models sit in its folder's models folder (atoms/models/, compositions/models/;
// Scott, 2026-11-13, ruling 6): a twin is its model's in the same folder, there as beside a page.
test("twins.mjs: in a models folder a twin is its model's, and a twin in another folder is not", () => {
  const m = ["/r/atoms/models/x.tla", "/r/compositions/models/x.tla"];
  const t = ["/r/atoms/models/x-buggy.tla", "/r/compositions/models/x-buggy-y.tla", "/r/atoms/x-buggy-z.tla"];
  const f = twinsOf(m, t);
  assert.deepEqual(f.get("/r/atoms/models/x.tla"), ["/r/atoms/models/x-buggy.tla"]);
  assert.deepEqual(f.get("/r/compositions/models/x.tla"), ["/r/compositions/models/x-buggy-y.tla"]);
});

test("models in a models folder are audited, and --only and --except name them by their page", () => {
  const root = corpus({
    "atoms/models/c.tla": counter("c"), "atoms/models/c.cfg": cfg(["Safety"]),
    "atoms/models/c-buggy.tla": counter("c-buggy", { guard: "x < 5" }), "atoms/models/c-buggy.cfg": cfg(["Safety"]),
    "compositions/models/d.tla": counter("d"), "compositions/models/d.cfg": cfg(["Bounded"]),
    "compositions/models/d-buggy.tla": counter("d-buggy", { guard: "x < 4" }), "compositions/models/d-buggy.cfg": cfg(["Bounded"]),
  });
  const all = audit(root);
  assert.equal(all.status, 0, all.stdout);
  assert.match(all.stdout, /4 models: 2 HOLDS, 2 CAUGHT/);
  assert.match(all.stdout, /HOLDS  \[correct\] {2}atoms\/models\/c\.tla/);
  for (const [flag, re] of [["--only", "^atoms/c"], ["--only", "^atoms/models/c"], ["--except", "^compositions/d"]]) {
    const r = audit(root, {}, [flag, re]);
    assert.equal(r.status, 0, r.stdout);
    assert.match(r.stdout, /2 models: 1 HOLDS, 1 CAUGHT/, `${flag} ${re}`);
    assert.match(r.stdout, /atoms\/models\/c-buggy\.tla/);
    assert.doesNotMatch(r.stdout, /compositions\/models\/d/);
  }
});

test("every check broken by a twin, one of them found past the first violation: no red", () => {
  const root = corpus({
    "atoms/c.tla": counter("c"), "atoms/c.cfg": cfg(["Safety"]),
    // Climbs to 5: Bounded fails first (at 4); NotFive only at 5, which the audit asks next.
    "atoms/c-buggy.tla": counter("c-buggy", { guard: "x < 5" }), "atoms/c-buggy.cfg": cfg(["Safety"]),
  });
  const r = audit(root);
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /Bounded\s+c-buggy\.tla/);
  assert.match(r.stdout, /NotFive\s+c-buggy\.tla/);
  assert.match(r.stdout, /2 checks in 1 correct models, 0 red/);
  // No page holds a proof, so tlapm is not asked for.
  assert.match(r.stdout, /0 proofs, 0 failures/);
});

test("a check no twin breaks is red, named with its file", () => {
  const root = corpus({
    "atoms/c.tla": counter("c"), "atoms/c.cfg": cfg(["Bounded", "NotFive"]),
    "atoms/c-buggy.tla": counter("c-buggy", { guard: "x < 4" }), "atoms/c-buggy.cfg": cfg(["Bounded", "NotFive"]),
  });
  const r = audit(root);
  assert.equal(r.status, 1);
  assert.match(r.stdout, /RED {4}atoms\/c\.tla {2}NotFive: no twin breaks it/);
  assert.match(r.stdout, /2 checks in 1 correct models, 1 red/);
});

test("tautology: a check that restates an ASSUME, or an Alloy fact, is red", () => {
  const tla = counter("c", { extra: "ASSUME N > 1\nTwoPlus == N > 1" });
  const als = `sig E { next: lone E }
fact NoLoop { all e: E | e not in e.^next }
assert NoLoopHolds { all e: E | e not in e.^next }
check NoLoopHolds for 3
run {} for 3
`;
  const root = corpus({
    "atoms/c.tla": tla, "atoms/c.cfg": cfg(["TwoPlus"]),
    "atoms/a.als": als, "atoms/a-buggy.als": als.replace(/fact NoLoop .*\n/, ""),
  });
  assert.deepEqual(tautologies(join(root, "atoms/c.tla")), [{ check: "TwoPlus", why: "the same expression as an ASSUME" }]);
  assert.deepEqual(tautologies(join(root, "atoms/a.als")), [{ check: "NoLoopHolds", why: "the same expression as fact NoLoop" }]);
  const r = audit(root);
  assert.equal(r.status, 1);
  // The twin that drops the fact breaks the restatement, and it is red all the same.
  assert.match(r.stdout, /NoLoopHolds\s+a-buggy\.als/);
  assert.match(r.stdout, /RED {4}atoms\/a\.als {2}NoLoopHolds: restates its model: the same expression as fact NoLoop/);
  assert.match(r.stdout, /RED {4}atoms\/c\.tla {2}TwoPlus: restates its model: the same expression as an ASSUME; no twin breaks it/);
});

test("pruned property: a constraint the model never violates is red; one that bounds the model is not", () => {
  const extra = "Up == x' >= x\nStop == x <= 3";
  const root = corpus({
    // Up never fails: as an ACTION_CONSTRAINT it prunes nothing and asserts nothing.
    "atoms/p.tla": counter("p", { extra }), "atoms/p.cfg": cfg(["Bounded"], "ACTION_CONSTRAINT Up\n"),
    "atoms/p-buggy.tla": counter("p-buggy", { extra, guard: "x < 4" }), "atoms/p-buggy.cfg": cfg(["Bounded"], "ACTION_CONSTRAINT Up\n"),
    // Stop is a bound: without it the counter climbs past 3 (the guard is gone).
    "atoms/q.tla": counter("q", { extra, guard: "TRUE" }), "atoms/q.cfg": cfg(["NotFive"], "CONSTRAINT Stop\n"),
    "atoms/q-buggy.tla": counter("q-buggy", { extra, guard: "TRUE", step: "x' = x + 5" }), "atoms/q-buggy.cfg": cfg(["NotFive"], "CONSTRAINT Stop\n"),
  });
  const r = audit(root);
  assert.equal(r.status, 1, r.stdout);
  assert.match(r.stdout, /RED {4}atoms\/p\.tla {2}Up: a constraint the model never violates/);
  assert.doesNotMatch(r.stdout, /RED {4}atoms\/q\.tla/);
  assert.match(r.stdout, /2 checks in 2 correct models, 1 red/);
});

test("pruned property: a check that is its own constraint is red", () => {
  const root = corpus({
    "atoms/s.tla": counter("s", { extra: "Prop == [][x' >= x]_vars" }),
    "atoms/s.cfg": "SPECIFICATION Spec\nINVARIANT Bounded\nPROPERTY Prop\nCONSTRAINT Bounded\nCHECK_DEADLOCK FALSE\nCONSTANTS\n    N = 2\n",
  });
  assert.deepEqual(tautologies(join(root, "atoms/s.tla")), [{ check: "Bounded", why: "the same expression as CONSTRAINT Bounded" }]);
});

test("the ledger keeps no line for a model outside the repository", () => {
  const dir = mkdtempSync(join(tmpdir(), "ledger-"));
  const path = join(dir, "states.tsv");
  process.env.GRACE_STATES_LEDGER = path;
  appendLedger({ file: join(dir, "elsewhere.tla"), role: "model", engine: "tla", states: 9, capped: 0, verdict: "HOLDS" });
  assert.equal(existsSync(path), false);
  appendLedger({ file: join(HERE, "../../atoms/models/approval-step.tla"), role: "model", engine: "tla", states: 9, capped: 0, verdict: "HOLDS" });
  assert.equal(readFileSync(path, "utf8").trim().split("\n").length, 2);
  delete process.env.GRACE_STATES_LEDGER;
});

// ---- TLAPS: a theorem with a proof goes to tlapm (tlapm.mjs) ----------------------------
const twin = (extra) => ({
  "atoms/t.tla": counter("t", { extra }), "atoms/t.cfg": cfg(["Bounded"]),
  "atoms/t-buggy.tla": counter("t-buggy", { extra, guard: "x < 4" }), "atoms/t-buggy.cfg": cfg(["Bounded"]),
});
const THEOREM_TRUE = "THEOREM ZeroIsNat == 0 \\in Nat\nPROOF OBVIOUS";
const THEOREM_FALSE = "THEOREM AllPositive == \\A n \\in Nat : n > 0\nPROOF OBVIOUS";

test("tlapm.mjs: a theorem with a proof is one tlapm is asked for; a comment, a bare statement or a check is not", () => {
  assert.equal(hasProof(counter("c", { extra: THEOREM_TRUE })), true);
  assert.equal(hasProof(counter("c", { extra: "THEOREM Lemma1 == TRUE\n<1>1. QED\n  OBVIOUS" })), true);
  assert.equal(hasProof(counter("c", { extra: "THEOREM Bare == TRUE" })), false);
  assert.equal(hasProof(counter("c", { extra: "\\* THEOREM Said == TRUE PROOF OBVIOUS" })), false);
  assert.equal(hasProof(counter("c", { extra: "(* THEOREM Said == TRUE\n   PROOF OBVIOUS *)" })), false);
  assert.equal(hasProof(counter("c")), false);
});

test("a theorem with a proof tlapm cannot prove is a problem; one it proves is not", { skip: findTlapm() ? false : "tlapm not installed: run bootstrap.sh" }, () => {
  const proved = audit(corpus(twin(THEOREM_TRUE)));
  assert.equal(proved.status, 0, proved.stdout);
  assert.match(proved.stdout, /PROVED {1,2}atoms\/t\.tla/);
  assert.match(proved.stdout, /1 proofs, 0 failures/);
  const failed = audit(corpus(twin(THEOREM_FALSE)));
  assert.equal(failed.status, 1, failed.stdout);
  assert.match(failed.stdout, /FAILED {1,2}atoms\/t\.tla/);
  assert.match(failed.stdout, /1 proofs, 1 failures/);
});

test("a proof no tlapm is installed for is an error, not a pass", () => {
  const r = audit(corpus(twin(THEOREM_TRUE)), { TLAPM: "", TLAPM_HOME: join(tmpdir(), "no-tlapm-here") });
  assert.equal(r.status, 1, r.stdout);
  assert.match(r.stdout, /ERROR {1,2}atoms\/t\.tla {2}tlapm not found/);
  assert.match(r.stdout, /1 proofs, 1 failures/);
});

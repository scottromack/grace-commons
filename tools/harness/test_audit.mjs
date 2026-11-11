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
const audit = (root) => spawnSync("node", [join(HERE, "audit.mjs"), "--root", root, "--jobs", "4"],
  { env: { ...process.env, GRACE_STATES_LEDGER: "off" }, encoding: "utf8" });

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
  appendLedger({ file: join(HERE, "../../atoms/approval-step.tla"), role: "model", engine: "tla", states: 9, capped: 0, verdict: "HOLDS" });
  assert.equal(readFileSync(path, "utf8").trim().split("\n").length, 2);
  delete process.env.GRACE_STATES_LEDGER;
});

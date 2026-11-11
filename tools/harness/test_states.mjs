// node --test test_states.mjs — the ledger line, and check.mjs writing it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, existsSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { COLUMNS, ledgerLine, appendLedger } from "./ledger.mjs";
import { statesIn, runTlc } from "./tlc.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const DAY = new Date("2026-11-09T13:00:00Z");

test("a TLA+ line carries the states and the cap, and dashes for Alloy's columns", () => {
  const f = ledgerLine({ file: "atoms/x.tla", role: "model", engine: "tla", states: 25, capped: 0, verdict: "HOLDS" }, DAY);
  const c = f.split("\t");
  assert.equal(c.length, COLUMNS.length);
  assert.deepEqual(c.slice(0, 6), ["2026-11-09", "atoms/x.tla", "model", "tla", "25", "0"]);
  assert.deepEqual(c.slice(6, 11), ["-", "-", "-", "-", "-"]);
  assert.equal(c[11], "HOLDS");
  assert.equal(c[12], "-");
});

test("an Alloy line carries the commands and their verdicts", () => {
  const c = ledgerLine({ file: "atoms/y.als", role: "twin", engine: "als", commands: 5, holds: 2,
    satisfiable: 1, counterexamples: 2, vacuous: 0, verdict: "CAUGHT" }, DAY).split("\t");
  assert.deepEqual(c.slice(3, 12), ["als", "-", "-", "5", "2", "1", "2", "0", "CAUGHT"]);
});

test("the first append writes the header; the file is the repo-relative path; off writes nothing", () => {
  const dir = mkdtempSync(join(tmpdir(), "ledger-"));
  const path = join(dir, "states.tsv");
  process.env.GRACE_STATES_LEDGER = path;
  const abs = join(HERE, "../../atoms/approval-step.tla");
  appendLedger({ file: abs, role: "model", engine: "tla", states: 25, capped: 0, verdict: "HOLDS" }, DAY);
  appendLedger({ file: abs, role: "model", engine: "tla", states: 26, capped: 0, verdict: "HOLDS" }, DAY);
  const lines = readFileSync(path, "utf8").trim().split("\n");
  assert.equal(lines.length, 3);
  assert.ok(lines[0].startsWith("# date\tfile"));
  assert.equal(lines[1].split("\t")[1], "atoms/approval-step.tla");
  process.env.GRACE_STATES_LEDGER = "off";
  appendLedger({ file: abs, role: "model", engine: "tla", states: 1, capped: 0, verdict: "HOLDS" }, DAY);
  assert.equal(readFileSync(path, "utf8").trim().split("\n").length, 3);
  delete process.env.GRACE_STATES_LEDGER;
});

test("check.mjs appends one line for a TLA+ model and one for its twin", () => {
  const dir = mkdtempSync(join(tmpdir(), "ledger-"));
  const path = join(dir, "states.tsv");
  const env = { ...process.env, GRACE_STATES_LEDGER: path };
  const run = (...a) => spawnSync("node", [join(HERE, "check.mjs"), ...a], { env, encoding: "utf8" });
  assert.equal(run(join(HERE, "../../atoms/approval-step.tla")).status, 0);
  assert.equal(run(join(HERE, "../../atoms/approval-step-buggy.tla"), "--buggy").status, 0);
  assert.ok(existsSync(path));
  const rows = readFileSync(path, "utf8").trim().split("\n").slice(1).map((l) => l.split("\t"));
  assert.deepEqual(rows.map((r) => [r[1], r[2], r[11]]), [
    ["atoms/approval-step.tla", "model", "HOLDS"],
    ["atoms/approval-step-buggy.tla", "twin", "CAUGHT"],
  ]);
  assert.ok(Number(rows[0][4]) > 0);
  assert.equal(rows[0][12], "tlc");
});

test("--engine wasm runs the WASM checker, and the ledger says so", () => {
  const dir = mkdtempSync(join(tmpdir(), "ledger-"));
  const path = join(dir, "states.tsv");
  const r = spawnSync("node", [join(HERE, "check.mjs"), join(HERE, "../../atoms/approval-step.tla"), "--engine", "wasm"],
    { env: { ...process.env, GRACE_STATES_LEDGER: path }, encoding: "utf8" });
  assert.equal(r.status, 0);
  const row = readFileSync(path, "utf8").trim().split("\n")[1].split("\t");
  assert.deepEqual([row[4], row[11], row[12]], ["25", "HOLDS", "wasm"]);
});

test("statesIn reads the last count, progress lines with thousands separators included", () => {
  assert.equal(statesIn("nothing here"), null);
  assert.equal(statesIn("Progress(9) at x: 15,248 states generated (15,248 s/min), 13,922 distinct states found (13,922 ds/min), 9,670 states left on queue."), 13922);
  assert.equal(statesIn("2725 states generated, 1630 distinct states found, 1123 states left on queue.\n146043 states generated, 71971 distinct states found, 0 states left on queue."), 71971);
});

test("TLC: a correct model holds, a twin is violated, a run past the limit is an error naming why", () => {
  const model = join(HERE, "../../atoms/approval-step.tla");
  assert.equal(runTlc(model).kind, "hold");
  const twin = runTlc(join(HERE, "../../atoms/approval-step-buggy.tla"));
  assert.equal(twin.kind, "violated");
  assert.match(twin.message, /Invariant Safety is violated/);
  const slow = runTlc(model, { limitMs: 50 });
  assert.equal(slow.kind, "error");
  assert.equal(slow.capped, true);
  assert.match(slow.message, /TLC stopped at/);
});

test("TLC: a model with no .cfg beside it is an error, not a hold", () => {
  const dir = mkdtempSync(join(tmpdir(), "ledger-"));
  const tla = join(dir, "lone.tla");
  writeFileSync(tla, "---- MODULE lone ----\nVARIABLE x\nInit == x = 0\nNext == x' = x\n====\n");
  const r = runTlc(tla);
  assert.equal(r.kind, "error");
  assert.match(r.message, /no \.cfg/);
});

test("audit.mjs runs checks side by side and prints them in the models' order", () => {
  const r = spawnSync("node", [join(HERE, "audit.mjs"), "--only", "atoms/approval-step.*\\.tla$", "--jobs", "2"],
    { env: { ...process.env, GRACE_STATES_LEDGER: "off" }, encoding: "utf8" });
  assert.equal(r.status, 0, r.stdout);
  assert.match(r.stdout, /\d+ models: 1 HOLDS, \d+ CAUGHT, 0 BROKEN, 0 MISSED, 0 ERROR/);
  assert.match(r.stdout, /checks in 1 correct models, 0 red/);
  assert.ok(r.stdout.indexOf("approval-step-buggy.tla") < r.stdout.indexOf("approval-step.tla"));
});

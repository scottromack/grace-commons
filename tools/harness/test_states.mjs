// node --test test_states.mjs — the ledger line, and check.mjs writing it.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { COLUMNS, ledgerLine, appendLedger } from "./ledger.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const DAY = new Date("2026-11-09T13:00:00Z");

test("a TLA+ line carries the states and the cap, and dashes for Alloy's columns", () => {
  const f = ledgerLine({ file: "atoms/x.tla", role: "model", engine: "tla", states: 25, capped: 0, verdict: "HOLDS" }, DAY);
  const c = f.split("\t");
  assert.equal(c.length, COLUMNS.length);
  assert.deepEqual(c.slice(0, 6), ["2026-11-09", "atoms/x.tla", "model", "tla", "25", "0"]);
  assert.deepEqual(c.slice(6, 11), ["-", "-", "-", "-", "-"]);
  assert.equal(c[11], "HOLDS");
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
});

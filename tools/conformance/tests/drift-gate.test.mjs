// tools/conformance/tests/drift-gate.test.mjs
//   node --test tools/conformance/tests/
//
// The drift gate's verdict (drift-gate.mjs): a count above the record fails, at or below passes,
// and the tool never writes the record.

import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { decide, countFrom, readRecord } from "../drift-gate.mjs";

const GATE = join(dirname(fileURLToPath(import.meta.url)), "..", "drift-gate.mjs");

test("a count above the record fails and names both numbers", () => {
  const v = decide(107, 106);
  assert.equal(v.ok, false);
  assert.match(v.message, /107/);
  assert.match(v.message, /106/);
});

test("a count at the record passes; one below passes and says to lower the record", () => {
  assert.equal(decide(106, 106).ok, true);
  const v = decide(90, 106);
  assert.equal(v.ok, true);
  assert.match(v.message, /lower the record to 90/);
});

test("no count or no record fails: a gate that reads nothing is not a gate", () => {
  assert.equal(decide(NaN, 106).ok, false);
  assert.equal(decide(106, NaN).ok, false);
});

test("the count is read from the reconcile's last line", () => {
  assert.equal(countFrom("\n— reconcile clinical-trial-portal: 106 drift finding(s), 0 advisory.\n"), 106);
  assert.ok(Number.isNaN(countFrom("nothing here")));
});

test("the record is one integer in a file; a missing file reads as no record", () => {
  const dir = mkdtempSync(join(tmpdir(), "drift-"));
  writeFileSync(join(dir, "r"), "12\n");
  assert.equal(readRecord(join(dir, "r")), 12);
  assert.ok(Number.isNaN(readRecord(join(dir, "none"))));
});

test("run against the real reconcile: a record below today's count fails, one at or above passes, and the file is never written", () => {
  const dir = mkdtempSync(join(tmpdir(), "drift-"));
  const record = join(dir, "record");
  const run = (n) => { writeFileSync(record, `${n}\n`); return spawnSync(process.execPath, [GATE, "clinical-trial-portal", "--record", record], { encoding: "utf-8" }); };
  assert.equal(run(0).status, 1);
  assert.equal(run(100000).status, 0);
  assert.equal(readFileSync(record, "utf-8"), "100000\n");
});

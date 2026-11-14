// Tests for changed-patterns.mjs (unit `tooling: the public audit finishes`): which models a push audits.
import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { selection, render, patternNames } from "./changed-patterns.mjs";

const NAMES = {
  atoms: ["event-log", "event-log-extra", "gift-card", "cart"],
  compositions: ["audit-trail", "recoverable-invocation", "shared-cart"],
};

test("a push touching one atom's model, one composition's history file, and nothing else audits those two patterns", () => {
  const sel = selection(["atoms/models/gift-card-buggy-spend.tla", "compositions/audit-trail.hist.md", "README.md"], NAMES);
  assert.equal(sel.mode, "only");
  assert.deepEqual(sel.patterns, ["atoms/gift-card", "compositions/audit-trail"]);
  assert.equal(sel.only, "^(atoms|compositions)/(audit-trail|gift-card)[-.]");
  const re = new RegExp(sel.only);
  assert.ok(re.test("atoms/gift-card.tla"));              // a model by the audit's page-folder spelling
  assert.ok(re.test("compositions/audit-trail-buggy-x.als"));
  assert.ok(!re.test("atoms/cart.tla"));                   // another pattern is not selected
  assert.ok(!re.test("atoms/gift-cardigan.tla"));          // a name that merely starts the same is not selected
});

test("a push touching no pattern, history or model file audits nothing and says so", () => {
  const sel = selection(["readme.md", "status.md", "tools/linter/lint.py", "_data/stats.json", "atoms/index.md"], NAMES);
  assert.deepEqual(sel, { mode: "none" });
  assert.equal(render(sel), "none");
  assert.deepEqual(selection([], NAMES), { mode: "none" });
});

test("a push touching tools/harness, or the workflow itself, audits the whole library", () => {
  assert.deepEqual(selection(["atoms/models/gift-card.tla", "tools/harness/audit.mjs"], NAMES), { mode: "all" });
  assert.deepEqual(selection([".github/workflows/verify.yml"], NAMES), { mode: "all" });
  assert.equal(render({ mode: "all" }), "all");
});

test("a model file belongs to the longest page name it extends, not a shorter prefix", () => {
  const sel = selection(["atoms/models/event-log-extra-buggy-late.tla"], NAMES);
  assert.deepEqual(sel.patterns, ["atoms/event-log-extra"]);
  assert.deepEqual(selection(["atoms/models/event-log-buggy-late.tla"], NAMES).patterns, ["atoms/event-log"]);
});

test("a page alone, and a model beside the page before the move, both name the pattern", () => {
  assert.deepEqual(selection(["atoms/cart.md"], NAMES).patterns, ["atoms/cart"]);
  assert.deepEqual(selection(["compositions/shared-cart.tla"], NAMES).patterns, ["compositions/shared-cart"]);
});

test("a pattern's coverage matrix names the pattern, and no other harness file does", () => {
  const sel = selection(["tools/harness/coverage/gift-card.md", "atoms/models/gift-card.tla"], NAMES);
  assert.deepEqual(sel.patterns, ["atoms/gift-card"]);
  assert.deepEqual(selection(["tools/harness/coverage/shared-cart.md"], NAMES).patterns, ["compositions/shared-cart"]);
  assert.deepEqual(selection(["tools/harness/coverage/unknown.md"], NAMES), { mode: "none" }); // a matrix of no page
  assert.deepEqual(selection(["tools/harness/coverage/gift-card.md", "tools/harness/audit.mjs"], NAMES), { mode: "all" });
  assert.deepEqual(selection(["tools/harness/coverage/event-log-extra.md"], NAMES).patterns, ["atoms/event-log-extra"]);
});

test("Recoverable Invocation is left to its own workflow", () => {
  assert.deepEqual(selection(["compositions/models/recoverable-invocation.tla"], NAMES), { mode: "none" });
  const both = selection(["compositions/models/recoverable-invocation.tla", "atoms/models/cart.als"], NAMES);
  assert.deepEqual(both.patterns, ["atoms/cart"]);
});

test("a file that names no page is no pattern file", () => {
  assert.deepEqual(selection(["atoms/models/unknown-thing.tla", "atoms/notes.txt"], NAMES), { mode: "none" });
});

test("the command line reads paths from stdin and a root, and prints one line", () => {
  const root = mkdtempSync(join(tmpdir(), "changed-patterns-"));
  try {
    mkdirSync(join(root, "atoms"));
    mkdirSync(join(root, "compositions"));
    for (const f of ["atoms/cart.md", "atoms/cart.hist.md", "atoms/README.md", "compositions/shared-cart.md"]) writeFileSync(join(root, f), "# x\n");
    assert.deepEqual(patternNames(root, "atoms"), ["cart"]);
    const run = (input) => spawnSync(process.execPath, [fileURLToPath(new URL("./changed-patterns.mjs", import.meta.url)), "--root", root],
      { input, encoding: "utf-8" });
    assert.equal(run("atoms/models/cart-buggy-add.tla\n").stdout.trim(), "only ^(atoms|compositions)/(cart)[-.]");
    assert.equal(run("status.md\n").stdout.trim(), "none");
    assert.equal(run("tools/harness/audit.mjs\n").stdout.trim(), "all");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

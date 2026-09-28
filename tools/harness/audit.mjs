// Grace Commons — audit every existing formal model through the harness.
// Walks the repo for .als/.tla, runs each via check.mjs, and prints a summary.
// A model the checker must reject is marked one of two ways: its file name
// contains "buggy" (a twin), or its second line reads `\* EXPECT: violation`
// (a reachability probe checking a deliberate falsehood). Everything else is a
// correct model (must hold / be non-vacuous).
//
//   node audit.mjs

import { execFileSync } from "node:child_process";
import { dirname, join, relative, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { readdirSync, readFileSync, statSync } from "node:fs";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, "../..");

function walk(dir, acc = []) {
  for (const e of readdirSync(dir)) {
    if (e === "node_modules" || e === ".git" || e.endsWith(".work")) continue;
    const p = join(dir, e);
    const st = statSync(p);
    if (st.isDirectory()) walk(p, acc);
    else if (/\.(als|tla)$/i.test(e)) acc.push(p);
  }
  return acc;
}

const models = walk(REPO).sort();
const rows = [];
for (const m of models) {
  const expectsViolation = (readFileSync(m, "utf-8").split("\n")[1] ?? "").startsWith("\\* EXPECT: violation");
  const buggy = /buggy/i.test(basename(m)) || expectsViolation;
  const argv = buggy ? [join(HERE, "check.mjs"), m, "--buggy"] : [join(HERE, "check.mjs"), m];
  let pass = false, log = "";
  try {
    log = execFileSync("node", argv, { encoding: "utf-8", maxBuffer: 64 * 1024 * 1024 });
    pass = true;
  } catch (e) {
    log = (e.stdout || "") + (e.stderr || "");
    pass = false;
  }
  console.log("─".repeat(72));
  console.log(log.trimEnd());
  rows.push({ file: relative(REPO, m), buggy, pass });
}

console.log("═".repeat(72));
console.log("AUDIT SUMMARY");
console.log("═".repeat(72));
let fails = 0;
for (const r of rows) {
  const tag = r.buggy ? "[buggy]" : "[correct]";
  const status = r.pass ? "PASS" : "FAIL";
  if (!r.pass) fails++;
  console.log(`  ${status.padEnd(5)} ${tag.padEnd(10)} ${r.file}`);
}
console.log("─".repeat(72));
console.log(`  ${rows.length} models, ${fails} FAIL`);
process.exit(fails ? 1 : 0);

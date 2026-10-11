// Grace Commons — audit every existing formal model through the harness.
// Walks the repo for .als/.tla, runs each via check.mjs, and prints a summary.
// A model the checker must reject is marked one of two ways: its file name
// contains "buggy" (a twin), or its second line reads `\* EXPECT: violation`
// (a reachability probe checking a deliberate falsehood). Everything else is a
// correct model (must hold / be non-vacuous).
//
//   node audit.mjs                    every model
//   node audit.mjs --only <regex>     models whose repo-relative path matches
//   node audit.mjs --except <regex>   models whose repo-relative path does not

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

const flag = (name) => { const i = process.argv.indexOf(name); return i < 0 ? null : new RegExp(process.argv[i + 1]); };
const only = flag("--only"), except = flag("--except");
const models = walk(REPO).sort().filter((m) => {
  const rel = relative(REPO, m);
  return (!only || only.test(rel)) && (!except || !except.test(rel));
});
const rows = [];
for (const m of models) {
  const expectsViolation = (readFileSync(m, "utf-8").split("\n")[1] ?? "").startsWith("\\* EXPECT: violation");
  const buggy = /buggy/i.test(basename(m)) || expectsViolation;
  const argv = buggy ? [join(HERE, "check.mjs"), m, "--buggy"] : [join(HERE, "check.mjs"), m];
  let code = 0, log = "";
  try {
    log = execFileSync("node", argv, { encoding: "utf-8", maxBuffer: 64 * 1024 * 1024 });
  } catch (e) {
    log = (e.stdout || "") + (e.stderr || "");
    code = e.status ?? 2;
  }
  const verdict = code === 0 ? (buggy ? "CAUGHT" : "HOLDS")
    : code === 1 ? (buggy ? "MISSED" : "BROKEN")
    : "ERROR";
  console.log("─".repeat(72));
  console.log(log.trimEnd());
  rows.push({ file: relative(REPO, m), buggy, verdict });
}

console.log("═".repeat(72));
console.log("AUDIT SUMMARY");
console.log("═".repeat(72));
// HOLDS and CAUGHT are the outcomes each model's role requires; BROKEN,
// MISSED and ERROR are problems.
const count = { HOLDS: 0, CAUGHT: 0, BROKEN: 0, MISSED: 0, ERROR: 0 };
for (const r of rows) {
  count[r.verdict]++;
  const tag = r.buggy ? "[buggy]" : "[correct]";
  console.log(`  ${r.verdict.padEnd(6)} ${tag.padEnd(10)} ${r.file}`);
}
const problems = count.BROKEN + count.MISSED + count.ERROR;
console.log("─".repeat(72));
console.log(`  ${rows.length} models: ${Object.entries(count).map(([k, v]) => `${v} ${k}`).join(", ")}`);
console.log(`  ${problems} problem${problems === 1 ? "" : "s"}`);
process.exit(problems ? 1 : 0);

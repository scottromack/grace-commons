// Grace Commons — audit every existing formal model through the harness.
// Walks the repo for .als/.tla, runs each via check.mjs, and prints a summary.
// A model the checker must reject is marked one of two ways: its file name
// contains "buggy" (a twin), or its second line reads `\* EXPECT: violation`
// (a reachability probe checking a deliberate falsehood). Everything else is a
// correct model (must hold / be non-vacuous).
//
// Then every check of every correct model must be broken by one of its twins
// (unit `tooling: every check has a twin that breaks it`, Scott 2026-11-10). A
// check no twin breaks is RED: it holds, and nothing shows it could fail. So is a
// check that restates a fact, an ASSUME or a constraint of its own model, and a
// constraint the correct model never violates (it prunes nothing, so it is a
// property no twin can break: make it a check). What a check and a twin are is
// twins.mjs's. Which twin breaks which check: TLC names the invariant a twin
// violates and Alloy reports every check, so each twin's own run says most of it;
// a TLA+ check no run named is asked of the twins side by side, each twin run
// against the checks still unbroken until it violates none of them.
//
//   node audit.mjs                    every model
//   node audit.mjs --only <regex>     models whose repo-relative path matches
//                                     (a correct model brings its twins)
//   node audit.mjs --except <regex>   models whose repo-relative path does not
//   node audit.mjs --jobs N           checks run side by side, N at a time (default:
//                                     one per core), each TLC run on one worker
//   node audit.mjs --engine wasm      the WASM checker instead of TLC (comparison)
//   node audit.mjs --limit-min N      stop a TLC check at N minutes (default 15)
//   node audit.mjs --twin-limit-min N stop a twin asked about its model's checks at N minutes (10)
//   node audit.mjs --root <dir>       walk <dir> instead of the repo (the tests' fixtures)

import { execFile } from "node:child_process";
import { cpus } from "node:os";
import { dirname, join, relative, basename, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { runTlcAsync, DEFAULT_LIMIT_MS } from "./tlc.mjs";
import { checksOf, twinsOf, tautologies, constraintsOf, cfgWithChecks, parseCfg, tlaDefinitions, tlaVariables, isTla } from "./twins.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const optArg = (name) => { const i = process.argv.indexOf(name); return i < 0 ? null : process.argv[i + 1]; };
const REPO = optArg("--root") ? resolve(optArg("--root")) : join(HERE, "../..");

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

const expectsViolation = (m) => (readFileSync(m, "utf-8").split("\n")[1] ?? "").startsWith("\\* EXPECT: violation");
const isTwin = (m) => /buggy/i.test(basename(m));
const flag = (name) => optArg(name) === null ? null : new RegExp(optArg(name));
const only = flag("--only"), except = flag("--except");
const all = walk(REPO).sort();
const families = twinsOf(all.filter((m) => !isTwin(m) && !expectsViolation(m)), all.filter(isTwin));
const picked = new Set(all.filter((m) => {
  const rel = relative(REPO, m);
  return (!only || only.test(rel)) && (!except || !except.test(rel));
}));
for (const m of [...picked]) for (const t of families.get(m) ?? []) picked.add(t);
const models = all.filter((m) => picked.has(m));
const jobs = Math.max(1, Number(optArg("--jobs") ?? cpus().length));
const passThrough = [["--engine"], ["--limit-min"]].flatMap(([f]) => optArg(f) ? [f, optArg(f)] : []);
const limitMs = optArg("--limit-min") ? Number(optArg("--limit-min")) * 60000 : DEFAULT_LIMIT_MS;
// A twin asked about its model's checks explores its whole space unless it breaks one, and a
// twin's space can be far larger than its model's; such a run stops at --twin-limit-min (10),
// and a check it leaves undecided stays red.
const twinLimitMs = Number(optArg("--twin-limit-min") ?? 10) * 60000;

// The checks a run's log says were broken: TLC's one named violation, or each Alloy check with a counterexample.
const brokenIn = (log) => [
  ...[...log.matchAll(/-> VIOLATION: (?:Invariant|Action property) (\S+) is violated/g)].map((m) => m[1]),
  ...[...log.matchAll(/^\s+check\s+(\S+)\s+COUNTEREXAMPLE/gm)].map((m) => m[1]),
];

function run(m) {
  const buggy = isTwin(m) || expectsViolation(m);
  // Checks run side by side, so each TLC run takes one worker and a bounded heap.
  const argv = [join(HERE, "check.mjs"), m, ...(buggy ? ["--buggy"] : []), "--workers", "1", "--heap", "2048", ...passThrough];
  return new Promise((resolve) => {
    execFile("node", argv, { encoding: "utf-8", maxBuffer: 64 * 1024 * 1024 }, (e, stdout, stderr) => {
      const code = e ? (typeof e.code === "number" ? e.code : 2) : 0;
      const log = e ? (stdout || "") + (stderr || "") : stdout;
      const verdict = code === 0 ? (buggy ? "CAUGHT" : "HOLDS")
        : code === 1 ? (buggy ? "MISSED" : "BROKEN")
        : "ERROR";
      resolve({ log, row: { file: relative(REPO, m), path: m, buggy, verdict, broken: brokenIn(log) } });
    });
  });
}

// A pool of `jobs` tasks; `each` gets the task's index and its result goes to the same index.
async function pool(n, each) {
  const out = new Array(n);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(jobs, n) }, async () => {
    while (next < n) { const i = next++; out[i] = await each(i); }
  }));
  return out;
}

const byPath = new Map();

// ---- every check has a twin that breaks it ------------------------------------
const tlc = (path, opts) => runTlcAsync(path, { workers: 1, heapMb: 2048, limitMs, ...opts });
// At most `jobs` checker runs at once: the models' own and the questions put to twins.
// The models' own runs go first, so the questions put to twins never hold up a model's verdict.
let running = 0;
const waiting = { first: [], then: [] };
async function slot(f, first = false) {
  if (running >= jobs) await new Promise((go) => (first ? waiting.first : waiting.then).push(go));
  running++;
  try { return await f(); } finally { running--; (waiting.first.shift() ?? waiting.then.shift())?.(); }
}

/** check -> the twin that breaks it (null: none), and each red for this model. */
async function twinPerCheck(m) {
  const checks = checksOf(m);
  const twins = (families.get(m) ?? []).filter((t) => byPath.get(t)?.verdict === "CAUGHT");
  const breaker = new Map(checks.map((c) => [c, null]));
  for (const t of twins) for (const c of byPath.get(t).broken) if (breaker.get(c) === null) breaker.set(c, t);
  const red = [];
  if (isTla(m)) {
    // A twin's run names one violation, the shortest; the twins are asked about the rest side
    // by side, each until it violates no check still open, and a check goes to the twin that
    // first reports it.
    const props = new Set(parseCfg(readFileSync(m.replace(/\.tla$/, ".cfg"), "utf-8")).properties);
    const open = new Set(checks.filter((c) => breaker.get(c) === null));
    // A twin that breaks a check usually does so within a minute and a half; one that breaks
    // none explores its whole space. So every twin is asked briefly first, and only a check
    // still open after that is asked again at the full --twin-limit-min.
    const held = new Set();   // twins that explored their whole space and broke nothing still open
    const ask = (limit) => Promise.all(twins.filter((t) => !held.has(t)).map(async (t) => {
      const defined = tlaDefinitions(readFileSync(t, "utf-8"));
      const twinCfg = t.replace(/\.tla$/, ".cfg");
      const cfg = readFileSync(existsSync(twinCfg) ? twinCfg : m.replace(/\.tla$/, ".cfg"), "utf-8");
      for (;;) {
        const r = await slot(async () => {
          const left = [...open].filter((c) => defined.has(c));
          if (!left.length) return null;
          const res = await tlc(t, { limitMs: limit, cfgText: cfgWithChecks(cfg, { invariants: left.filter((c) => !props.has(c)), properties: left.filter((c) => props.has(c)) }) });
          return { ...res, left };
        });
        if (!r) return;
        if (r.kind !== "violated" || !r.left.includes(r.check)) {
          if (r.kind === "hold") held.add(t);
          if (r.kind === "error" && !(r.capped && limit < twinLimitMs)) console.log(`  ! ${relative(REPO, t)} against ${r.left.join(", ")}: ${r.message}`);
          return;
        }
        if (open.delete(r.check)) breaker.set(r.check, t);
      }
    }));
    await ask(Math.min(90000, twinLimitMs));
    if (open.size) await ask(twinLimitMs);
    // A constraint the correct model never violates prunes nothing: it is a property no twin can break.
    const src = readFileSync(m, "utf-8");
    const defs = tlaDefinitions(src);
    const vars = defs.has("vars") ? "vars" : `<<${tlaVariables(src).join(", ")}>>`;
    const cfg = readFileSync(m.replace(/\.tla$/, ".cfg"), "utf-8");
    const { invariants, properties } = parseCfg(cfg);
    for (const k of constraintsOf(m)) {
      const prop = `GraceAudit_${k.name}`;
      const r = await slot(() => tlc(m, {
        cfgText: cfgWithChecks(cfg, { invariants: k.action ? invariants : [...invariants, k.name], properties: k.action ? [...properties, prop] : properties, drop: [k.name] }),
        append: k.action ? `${prop} == [][${k.name}]_${vars}` : undefined,
      }));
      if (r.kind === "hold") red.push({ check: k.name, why: `a constraint the model never violates: it prunes nothing, so it is a property no twin can break (state it as a check)` });
      else if (r.kind === "error") red.push({ check: k.name, why: `the constraint could not be checked as a property: ${r.message}` });
    }
  }
  for (const t of tautologies(m)) red.push({ check: t.check, why: `restates its model: ${t.why}` });
  for (const [c, t] of breaker) if (t === null) red.push({ check: c, why: "no twin breaks it" });
  // One red a check, whatever the number of reasons.
  const reasons = new Map();
  for (const r of red) reasons.set(r.check, [...(reasons.get(r.check) ?? []), r.why]);
  return { breaker, red: [...reasons].map(([check, why]) => ({ check, why: why.join("; ") })) };
}

// The logs print in the models' order as each one's turn comes. A correct model's twins are
// asked about its checks as soon as it and its twins have run, while the rest still run.
const rows = [];
const results = new Array(models.length);
const asked = new Map();
let printed = 0;
const isCorrect = (m) => !isTwin(m) && !expectsViolation(m);
// The longest runs start first, by each file's last line in the ledger; the logs still print in order.
const lastStates = new Map();
try {
  for (const l of readFileSync(join(HERE, "states.tsv"), "utf-8").split("\n")) {
    const c = l.split("\t");
    if (c.length > 4 && /^\d+$/.test(c[4])) lastStates.set(c[1], Number(c[4]));
  }
} catch { /* no ledger: file order */ }
const order = models.map((m, i) => i).sort((a, b) =>
  (lastStates.get(relative(join(HERE, "../.."), models[b])) ?? 0) - (lastStates.get(relative(join(HERE, "../.."), models[a])) ?? 0) || a - b);
await pool(models.length, async (k) => {
  const i = order[k];
  results[i] = await slot(() => run(models[i]), true);
  byPath.set(models[i], results[i].row);
  for (const m of models.filter(isCorrect)) {
    if (asked.has(m) || ![m, ...(families.get(m) ?? [])].every((x) => byPath.has(x))) continue;
    asked.set(m, byPath.get(m).verdict === "HOLDS" ? twinPerCheck(m) : null);
  }
  while (printed < models.length && results[printed]) {
    console.log("─".repeat(72));
    console.log(results[printed].log.trimEnd());
    rows.push(results[printed].row);
    printed++;
  }
});
const correct = models.filter((m) => isCorrect(m) && byPath.get(m)?.verdict === "HOLDS");
const verdicts = await Promise.all(correct.map((m) => asked.get(m)));

console.log("═".repeat(72));
console.log("TWIN PER CHECK");
console.log("═".repeat(72));
const reds = [];
correct.forEach((m, i) => {
  const { breaker, red } = verdicts[i];
  console.log(`  ${relative(REPO, m)}`);
  for (const [c, t] of breaker) console.log(`    ${c.padEnd(44)} ${t ? basename(t) : "RED"}`);
  for (const r of red) reds.push({ file: relative(REPO, m), ...r });
});

console.log("═".repeat(72));
console.log("AUDIT SUMMARY");
console.log("═".repeat(72));
// HOLDS and CAUGHT are the outcomes each model's role requires; BROKEN,
// MISSED and ERROR are problems, and so is every red check.
const count = { HOLDS: 0, CAUGHT: 0, BROKEN: 0, MISSED: 0, ERROR: 0 };
for (const r of rows) {
  count[r.verdict]++;
  const tag = r.buggy ? "[buggy]" : "[correct]";
  console.log(`  ${r.verdict.padEnd(6)} ${tag.padEnd(10)} ${r.file}`);
}
for (const r of reds) console.log(`  RED    ${r.file}  ${r.check}: ${r.why}`);
const problems = count.BROKEN + count.MISSED + count.ERROR;
console.log("─".repeat(72));
console.log(`  ${rows.length} models: ${Object.entries(count).map(([k, v]) => `${v} ${k}`).join(", ")}`);
console.log(`  ${verdicts.reduce((n, v) => n + v.breaker.size, 0)} checks in ${correct.length} correct models, ${reds.length} red`);
console.log(`  ${problems + reds.length} problem${problems + reds.length === 1 ? "" : "s"}`);
process.exit(problems + reds.length ? 1 : 0);

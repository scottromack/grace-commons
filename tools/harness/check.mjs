// Grace Commons — reproducible dual checker harness.
//
//   node check.mjs <model.tla|model.als> [--buggy] [--scope N]
//                  [--engine tlc|wasm] [--workers N] [--heap MB] [--limit-min N]
//
// TLA+ (.tla): runs TLC (tools/tlc/tla2tools.jar, through tlc.mjs) on the model
//   and its same-name .cfg as written: no state cap; a check still running at
//   --limit-min minutes (15) stops as ERROR and names the states it reached.
//   --workers N sets TLC's workers (auto: every core); --heap MB its heap.
//   --engine wasm runs the tla-checker WASM model checker instead, for
//   comparison only (one thread, a 200,000-state cap, constants from a sibling
//   <base>.constants.json if present, otherwise the .cfg's own CONSTANTS block).
//   - default twin: HOLDS iff every invariant holds (no violation).
//   - --buggy twin: CAUGHT iff some invariant is violated (the vacuity guard:
//     a deliberately-wrong model the checker MUST reject).
//
// Alloy (.als): runs the alloy.dist `exec` headless under the npm JRE 17 and
//   parses the per-command SAT/UNSAT result line.
//   - check command  => UNSAT means the asserted guarantee holds.
//   - run   command  => SAT   means the configuration space is non-empty
//                              (the assertion is not vacuously satisfied).
//   - default twin: HOLDS iff every `check` is UNSAT AND every `run` is SAT.
//   - --buggy twin: CAUGHT iff at least one `check` is SAT (counterexample found).
//   A model that fails to typecheck is an ERROR: an assertion that does not
//   typecheck was never actually checked (see capability.als line 193).
//
// The last line is one verdict word, each meaning one thing:
//   HOLDS   a correct model held           exit 0
//   CAUGHT  a buggy model was rejected     exit 0
//   BROKEN  a correct model was violated   exit 1
//   MISSED  a buggy model was not rejected exit 1
//   ERROR   the model was never checked (no Java, no .cfg, a parse or
//           type error)                     exit 2

import { readFileSync, existsSync, mkdtempSync, rmSync } from "node:fs";
import { dirname, join, basename, extname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { spawnSync } from "node:child_process";
import { appendLedger } from "./ledger.mjs";
import { runTlc, findJava as findJavaRaw, DEFAULT_LIMIT_MS } from "./tlc.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

function die(msg) { console.error(msg); console.log("  ERROR"); process.exit(2); }

// ---- locate provisioned tools (npm-only; see bootstrap.sh) -----------------
function findTlaPkg() {
  const candidates = [
    join(HERE, "node_modules/tla-checker"),
    "/tmp/tla_install/node_modules/tla-checker",
  ];
  const p = candidates.find(existsSync);
  if (!p) die("tla-checker not found — run tools/harness/bootstrap.sh first.");
  return p;
}
function findJava() {
  try { return findJavaRaw(); } catch (e) { die(e.message); }
}
function findAlloyJar() {
  const candidates = [
    join(HERE, "../alloy/alloy.jar"),
    resolve(HERE, "../alloy/alloy.jar"),
  ];
  const p = candidates.find(existsSync);
  if (!p) die("alloy.jar not found at tools/alloy/alloy.jar.");
  return p;
}

// ---- TLA+ -------------------------------------------------------------------
function optArg(name) {
  const i = process.argv.indexOf(name);
  return i < 0 ? null : process.argv[i + 1];
}

function checkTlaTlc(modelPath, buggy) {
  const limitMin = optArg("--limit-min");
  const heap = optArg("--heap");
  const res = runTlc(modelPath, {
    workers: optArg("--workers") ?? "auto",
    limitMs: limitMin ? Number(limitMin) * 60000 : DEFAULT_LIMIT_MS,
    heapMb: heap ? Number(heap) : undefined,
  });
  console.log(`  TLA+  ${basename(modelPath)}${res.kind === "error" ? "" : `  (states: ${res.states}, TLC ${res.seconds.toFixed(1)} s)`}`);
  if (res.kind === "error") {
    console.log(`  MODEL/HARNESS ERROR: ${res.message}`);
    return { pass: false, kind: "error", detail: res.message,
      ledger: res.states == null ? null : { engine: "tla", checker: "tlc", states: res.states, capped: res.capped ? 1 : 0 } };
  }
  const violated = res.kind === "violated";
  console.log(violated ? `  -> VIOLATION: ${res.message}` : `  -> all invariants hold`);
  return { pass: buggy ? violated : !violated, kind: buggy ? "buggy" : "correct", violated,
    ledger: { engine: "tla", checker: "tlc", states: res.states, capped: 0 } };
}

async function checkTla(modelPath, buggy) {
  return optArg("--engine") === "wasm" ? checkTlaWasm(modelPath, buggy) : checkTlaTlc(modelPath, buggy);
}

async function checkTlaWasm(modelPath, buggy) {
  const base = modelPath.slice(0, -extname(modelPath).length);
  const cfgPath = base + ".cfg";
  if (!existsSync(cfgPath)) die(`no .cfg beside ${basename(modelPath)}`);
  const constPath = base + ".constants.json";
  const constants = existsSync(constPath)
    ? JSON.parse(readFileSync(constPath, "utf-8"))
    : {};

  const TLA_PKG = findTlaPkg();
  const wasmBytes = readFileSync(join(TLA_PKG, "tla_checker_bg.wasm"));
  const checker = await import(join(TLA_PKG, "tla_checker.js"));
  checker.initSync({ module: wasmBytes });

  const raw = checker.check_spec_with_cfg(
    readFileSync(modelPath, "utf-8"),
    readFileSync(cfgPath, "utf-8"),
    JSON.stringify(constants),
    /* max_states */ 200000,
    /* max_depth  */ 40,
    /* allow_deadlock */ true,
    /* export_dot */ false,
  );
  let res;
  try { res = JSON.parse(raw); }
  catch { die(`tla-checker did not return JSON:\n${raw}`); }

  const violated = !res.success;
  if (res.error_type && res.error_type !== "InvariantViolation" && !res.success) {
    // Parse / translation error, not a real counterexample.
    console.log(`  TLA+  ${basename(modelPath)}`);
    console.log(`  MODEL/HARNESS ERROR: ${res.error_type} — ${res.error_message}`);
    const capped = res.error_type === "MaxStatesExceeded";
    return { pass: false, kind: "error", detail: res.error_message,
      ledger: capped ? { engine: "tla", checker: "wasm", states: res.states_explored, capped: 1 } : null };
  }

  console.log(`  TLA+  ${basename(modelPath)}  (states: ${res.states_explored})`);
  if (violated) {
    console.log(`  -> VIOLATION: ${res.error_message}`);
  } else {
    console.log(`  -> all invariants hold`);
  }
  const pass = buggy ? violated : !violated;
  return { pass, kind: buggy ? "buggy" : "correct", violated,
    ledger: { engine: "tla", checker: "wasm", states: res.states_explored, capped: 0 } };
}

// ---- Alloy ------------------------------------------------------------------
function checkAls(modelPath, buggy) {
  const java = findJava();
  const jar = findAlloyJar();
  const work = mkdtempSync(join(tmpdir(), "alloy-"));
  let out = "";
  try {
    // Alloy writes its per-command SAT/UNSAT lines to stderr (slf4j), so we
    // capture both streams unconditionally via spawnSync.
    const r = spawnSync(java, ["-jar", jar, "exec", "-f", resolve(modelPath)], {
      cwd: work, encoding: "utf-8", maxBuffer: 64 * 1024 * 1024,
    });
    out = (r.stdout || "") + "\n" + (r.stderr || "");
  } finally {
    rmSync(work, { recursive: true, force: true });
  }

  if (/Type error|ERROR alloy|LinkageError|Exception in thread/.test(out)) {
    const line = (out.split("\n").find(l => /Type error|ERROR alloy/.test(l)) || "").trim();
    console.log(`  ALLOY ${basename(modelPath)}`);
    console.log(`  model does not typecheck (never actually checked):`);
    console.log(`    ${line}`);
    return { pass: false, kind: "typecheck", detail: line };
  }

  // Parse command result lines: "NN. check Name <depth> [..] SAT|UNSAT"
  const cmds = [];
  for (const l of out.split("\n")) {
    const m = l.match(/^\s*\d+\.\s+(check|run)\s+(\S+).*\b(SAT|UNSAT)\s*$/);
    if (m) cmds.push({ type: m[1], name: m[2], sat: m[3] === "SAT" });
  }
  if (cmds.length === 0) {
    console.log(`  ALLOY ${basename(modelPath)}`);
    console.log(`  no check/run commands parsed from output (never actually checked).`);
    return { pass: false, kind: "noresult" };
  }

  console.log(`  ALLOY ${basename(modelPath)}  (${cmds.length} commands)`);
  const checks = cmds.filter(c => c.type === "check");
  const runs = cmds.filter(c => c.type === "run");
  const counterexamples = checks.filter(c => c.sat);     // check SAT = guarantee broken
  const vacuousRuns = runs.filter(c => !c.sat);          // run UNSAT = vacuous

  for (const c of cmds) {
    const verdict = c.type === "check"
      ? (c.sat ? "COUNTEREXAMPLE" : "holds")
      : (c.sat ? "satisfiable" : "VACUOUS (no instance)");
    console.log(`    ${c.type.padEnd(5)} ${c.name.padEnd(40)} ${verdict}`);
  }

  let pass;
  if (buggy) {
    pass = counterexamples.length > 0;
    console.log(`  -> buggy twin ${pass ? "correctly rejected" : "NOT rejected (vacuity guard)"}`);
  } else {
    pass = counterexamples.length === 0 && vacuousRuns.length === 0;
    if (counterexamples.length) console.log(`  -> ${counterexamples.length} guarantee(s) broken`);
    if (vacuousRuns.length) console.log(`  -> ${vacuousRuns.length} vacuous run(s)`);
    if (pass) console.log(`  -> all guarantees hold, all runs non-vacuous`);
  }
  return { pass, kind: buggy ? "buggy" : "correct", counterexamples, vacuousRuns,
    ledger: { engine: "als", checker: "alloy", commands: cmds.length, holds: checks.length - counterexamples.length,
      satisfiable: runs.length - vacuousRuns.length, counterexamples: counterexamples.length,
      vacuous: vacuousRuns.length } };
}

// ---- main -------------------------------------------------------------------
const args = process.argv.slice(2);
const buggy = args.includes("--buggy");
const valued = new Set(["--engine", "--workers", "--heap", "--limit-min", "--scope"]);
const model = args.find((a, i) => !a.startsWith("--") && !valued.has(args[i - 1]));
if (!model) die("usage: node check.mjs <model.tla|model.als> [--buggy]");
if (!existsSync(model)) die(`no such file: ${model}`);

const ext = extname(model).toLowerCase();
const result = ext === ".tla" ? await checkTla(model, buggy)
  : ext === ".als" ? checkAls(model, buggy)
  : die(`unsupported model type: ${ext}`);

const verdict = ["error", "typecheck", "noresult"].includes(result.kind) ? "ERROR"
  : buggy ? (result.pass ? "CAUGHT" : "MISSED")
  : (result.pass ? "HOLDS" : "BROKEN");
if (result.ledger) appendLedger({ ...result.ledger, file: model, role: buggy ? "twin" : "model", verdict });
console.log(`  ${verdict}`);
process.exit(verdict === "ERROR" ? 2 : result.pass ? 0 : 1);

// Grace Commons — the ledger of what the model checks explored.
//
// Every check.mjs run appends one line to tools/harness/states.tsv (tracked), so the
// count of states the corpus's models have been checked over is kept, not
// recalled from an entry that happened to quote one (unit `tooling: count the
// states the models check`, Scott 2026-11-09). _data/stats.json totals the
// latest line of each file (tools/taxonomy/generate_graph.py).
//
// Columns, tab-separated; "-" where a column does not apply to the engine:
//   date      UTC date of the run
//   file      repo-relative path of the model
//   role      model | twin   (twin = run with --buggy)
//   engine    tla | als
//   states    TLA+: states explored
//   capped    TLA+: 1 if the 200,000-state cap stopped the run, else 0
//   commands  Alloy: check and run commands parsed
//   holds     Alloy: checks UNSAT      satisfiable  Alloy: runs SAT
//   counterexamples  Alloy: checks SAT   vacuous  Alloy: runs UNSAT
//   verdict   HOLDS | CAUGHT | BROKEN | MISSED | ERROR
//
// GRACE_STATES_LEDGER=<path> writes there instead; "off" writes nothing.

import { appendFileSync, existsSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, "../..");

export const COLUMNS = [
  "date", "file", "role", "engine", "states", "capped",
  "commands", "holds", "satisfiable", "counterexamples", "vacuous", "verdict",
];

export function ledgerLine(e, now = new Date()) {
  const row = { date: now.toISOString().slice(0, 10), ...e };
  return COLUMNS.map((c) => String(row[c] ?? "-")).join("\t");
}

export function appendLedger(e, now = new Date()) {
  const target = process.env.GRACE_STATES_LEDGER ?? join(HERE, "states.tsv");
  if (target === "off") return;
  const fresh = !existsSync(target);
  const file = relative(REPO, resolve(e.file)).split(sep).join("/");
  const head = fresh ? "# " + COLUMNS.join("\t") + "\n" : "";
  appendFileSync(target, head + ledgerLine({ ...e, file }, now) + "\n");
}

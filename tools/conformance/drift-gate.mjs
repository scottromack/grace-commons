// tools/conformance/drift-gate.mjs
//   node drift-gate.mjs <render> [--record <file>]
//
// The drift gate (unit `verify.md: the twenty checks say their date, and the gate
// watches the drift`). The render's manifest was hand-authored off the specs'
// Generation-acceptance sections as they stood on 2026-06-05; the specs have moved since,
// and `extract-manifest.mjs --reconcile <render>` counts how far. This runs that
// reconcile and fails when the count is above the number recorded beside the manifest
// (manifests/<render>.drift-record, one integer). It prints the number either way.
//
// The tool never raises the record: a count above it is a failure, a count below it is
// a notice to lower the record, and lowering is a commit. Nothing here writes the file.

import { readFileSync, existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));

// The verdict for a count against a record: { ok, message }.
export function decide(count, record) {
  if (!Number.isInteger(count) || count < 0) return { ok: false, message: `drift: no count read from the reconcile` };
  if (!Number.isInteger(record) || record < 0) return { ok: false, message: `drift: no record to hold the count to` };
  if (count > record) return { ok: false, message: `drift: ${count} difference(s), above the recorded ${record}: the specs moved away from the manifest; cure the drift, never raise the record` };
  if (count < record) return { ok: true, message: `drift: ${count} difference(s), below the recorded ${record}: lower the record to ${count} in a commit` };
  return { ok: true, message: `drift: ${count} difference(s), the recorded number` };
}

// The count the reconcile prints on its last line: `— reconcile <render>: N drift finding(s), ...`.
export function countFrom(text) {
  const found = /— reconcile \S+: (\d+) drift finding\(s\)/.exec(text);
  return found ? Number(found[1]) : NaN;
}

export function readRecord(path) {
  return existsSync(path) ? Number.parseInt(readFileSync(path, "utf-8").trim(), 10) : NaN;
}

const isMain = import.meta.url === pathToFileURL(process.argv[1] ?? "").href;
if (isMain) {
  const argv = process.argv.slice(2);
  const render = argv.find((a) => !a.startsWith("--") && argv[argv.indexOf(a) - 1] !== "--record");
  if (!render) { console.error("usage: drift-gate.mjs <render> [--record <file>]"); process.exit(2); }
  const record = argv.includes("--record") ? resolve(argv[argv.indexOf("--record") + 1]) : join(HERE, "manifests", `${render}.drift-record`);
  const done = spawnSync(process.execPath, [join(HERE, "extract-manifest.mjs"), "--reconcile", render], { encoding: "utf-8", maxBuffer: 64 * 1024 * 1024 });
  const verdict = decide(countFrom(`${done.stdout}\n${done.stderr}`), readRecord(record));
  console.log(verdict.message);
  process.exit(verdict.ok ? 0 : 1);
}

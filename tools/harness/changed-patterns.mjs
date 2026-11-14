#!/usr/bin/env node
// Which models a push must audit (unit `tooling: the public audit finishes`, 2026-11-13).
//
// The whole-library audit takes over two hours, and a push that cancels the run before it ends proves
// nothing: thirteen runs in a row were cancelled on 2026-11-13. So a push audits what it changed, and the
// whole library is audited every night in a run no push can cancel (.github/workflows/verify.yml).
//
//   git diff --name-only <before> <after> | node changed-patterns.mjs [--root <repo>]
//
// prints one line:
//   all           the push touched tools/harness or the workflow itself: audit the whole library
//   none          the push touched no pattern, history or model file: audit nothing, and say so
//   only <regex>  the patterns the push touched, as an `audit.mjs --only` regex
//
// A pattern is touched when its page (`atoms/x.md`), its history (`atoms/x.hist.md`) or one of its models
// or twins (`atoms/models/x.tla`, `atoms/models/x-buggy-y.als`, ...) is in the push. Recoverable Invocation
// is left out: its models are audited by their own workflow (verify-recoverable-invocation.yml).
import { existsSync, readdirSync } from "node:fs";
import { join, basename } from "node:path";
import { fileURLToPath } from "node:url";

const FOLDERS = ["atoms", "compositions"];
const NOT_PATTERNS = new Set(["README", "TAXONOMY", "index"]);
const OWN_WORKFLOW = new Set(["compositions/recoverable-invocation"]);

// The pattern names of a folder: every page there but history files and the folder's own index pages.
export function patternNames(root, folder) {
  const dir = join(root, folder);
  if (!existsSync(dir)) return [];
  return readdirSync(dir)
    .filter((f) => f.endsWith(".md") && !f.endsWith(".hist.md"))
    .map((f) => f.slice(0, -3))
    .filter((n) => !NOT_PATTERNS.has(n));
}

// The page a file of a pattern belongs to: its own name, or the longest page name it extends with a dash
// (`gift-card-buggy-spend.tla` belongs to `gift-card`, never to a shorter name that is a prefix of it).
function owner(base, names) {
  let best = null;
  for (const n of names) {
    if ((base === n || base.startsWith(n + "-")) && (best === null || n.length > best.length)) best = n;
  }
  return best;
}

export function selection(paths, names = {}) {
  const touched = new Set();
  for (const raw of paths) {
    const path = raw.trim();
    if (!path) continue;
    if (path.startsWith("tools/harness/") || path === ".github/workflows/verify.yml") return { mode: "all" };
    const m = /^(atoms|compositions)\/(?:models\/)?([^/]+)$/.exec(path);
    if (!m) continue;
    const [, folder, file] = m;
    const base = basename(file).replace(/\.(hist\.md|md|als|tla|cfg)$/, "");
    if (base === basename(file)) continue; // not a page, history or model file
    const name = owner(base, names[folder] ?? []);
    if (name !== null && !OWN_WORKFLOW.has(`${folder}/${name}`)) touched.add(`${folder}/${name}`);
  }
  if (touched.size === 0) return { mode: "none" };
  const alt = [...touched].map((t) => t.split("/")[1]).sort().join("|");
  return { mode: "only", only: `^(atoms|compositions)/(${alt})[-.]`, patterns: [...touched].sort() };
}

export function render(sel) {
  return sel.mode === "only" ? `only ${sel.only}` : sel.mode;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const root = args.includes("--root") ? args[args.indexOf("--root") + 1] : join(fileURLToPath(import.meta.url), "..", "..", "..");
  let input = "";
  process.stdin.setEncoding("utf-8");
  for await (const chunk of process.stdin) input += chunk;
  const names = Object.fromEntries(FOLDERS.map((f) => [f, patternNames(root, f)]));
  const sel = selection(input.split("\n"), names);
  if (sel.mode === "only") console.error(`audits: ${sel.patterns.join(", ")}`);
  console.log(render(sel));
}

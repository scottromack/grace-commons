// Grace Commons — what a model checks, and what no twin can break.
//
// audit.mjs reads every correct model through these functions (unit `tooling:
// every check has a twin that breaks it`, Scott 2026-11-10 7:20 AM Central):
//
//   checksOf       the checks a correct model makes: each INVARIANT and PROPERTY
//                  its .cfg names (an operator that is only a conjunction of
//                  other operators counts as those operators, so a `Safety`
//                  aggregate is its conjuncts), or each `check` command of an
//                  .als. TypeOK is the model's typing, not a page's rule, and is
//                  not counted.
//   twinsOf        the twins of each correct model, by name: a `-buggy` file in
//                  the same directory and language whose name extends the
//                  model's (the longest such model owns it). A model that is
//                  another's module in another configuration says so in its
//                  header, `\* @twins-of <model>`, and takes that model's twins.
//   tautologies    a check whose statement is a fact, an ASSUME, a CONSTRAINT or
//                  an ACTION_CONSTRAINT of the same model, the same expression
//                  once comments and whitespace are gone: it restates what the
//                  model assumes, so no twin of the model can break it.
//   cfgWithChecks  a .cfg with its checks replaced (and constraints dropped),
//                  for the runs that ask which twin breaks which check and
//                  whether a constraint prunes anything.
//
// Every function here is pure text; audit.mjs runs the checkers.

import { readFileSync, existsSync } from "node:fs";
import { basename, dirname, extname, join } from "node:path";

// ---- TLA+ -------------------------------------------------------------------

/** The module with its comments blanked to spaces, so line and column survive. */
export function stripTlaComments(src) {
  let out = "", depth = 0;
  for (let i = 0; i < src.length; i++) {
    const two = src.slice(i, i + 2);
    if (two === "(*") { depth++; out += "  "; i++; continue; }
    if (depth && two === "*)") { depth--; out += "  "; i++; continue; }
    if (depth) { out += src[i] === "\n" ? "\n" : " "; continue; }
    if (two === "\\*") {
      while (i < src.length && src[i] !== "\n") { out += " "; i++; }
      if (i < src.length) out += "\n";
      continue;
    }
    out += src[i];
  }
  return out;
}

const TOP = /^(?:[A-Za-z_][A-Za-z0-9_]*\s*(?:\([^)]*\))?\s*==|-{4,}|={4,}|(?:VARIABLES?|CONSTANTS?|ASSUME|EXTENDS|LOCAL|INSTANCE|THEOREM|LEMMA|AXIOM|RECURSIVE)\b)/;

/** Each operator definition at the left margin: name -> { params, body }. */
export function tlaDefinitions(src) {
  const lines = stripTlaComments(src).split("\n");
  const defs = new Map();
  for (let i = 0; i < lines.length; i++) {
    const m = /^([A-Za-z_][A-Za-z0-9_]*)\s*(\([^)]*\))?\s*==(.*)$/.exec(lines[i]);
    if (!m) continue;
    const body = [m[3]];
    for (let j = i + 1; j < lines.length && !TOP.test(lines[j]); j++) body.push(lines[j]);
    defs.set(m[1], { params: m[2] ? m[2].slice(1, -1).split(",").map((s) => s.trim()) : [], body: body.join("\n").trim() });
  }
  return defs;
}

/** The expression of each ASSUME at the left margin. */
export function tlaAssumes(src) {
  const lines = stripTlaComments(src).split("\n");
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const m = /^ASSUME\b(.*)$/.exec(lines[i]);
    if (!m) continue;
    const body = [m[1]];
    for (let j = i + 1; j < lines.length && !TOP.test(lines[j]); j++) body.push(lines[j]);
    out.push(body.join("\n").trim());
  }
  return out;
}

/** The module's variables, in declaration order. */
export function tlaVariables(src) {
  const lines = stripTlaComments(src).split("\n");
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const m = /^VARIABLES?\b(.*)$/.exec(lines[i]);
    if (!m) continue;
    const text = [m[1]];
    for (let j = i + 1; j < lines.length && !TOP.test(lines[j]); j++) text.push(lines[j]);
    out.push(...text.join(" ").split(",").map((s) => s.trim()).filter((s) => /^[A-Za-z_]\w*$/.test(s)));
  }
  return out;
}

const CFG_KEYWORDS = new Set(["SPECIFICATION", "INIT", "NEXT", "INVARIANT", "INVARIANTS", "PROPERTY", "PROPERTIES",
  "CONSTANT", "CONSTANTS", "CONSTRAINT", "CONSTRAINTS", "ACTION_CONSTRAINT", "ACTION_CONSTRAINTS", "SYMMETRY",
  "VIEW", "CHECK_DEADLOCK", "POSTCONDITION", "ALIAS"]);
const SECTION = { INVARIANTS: "INVARIANT", PROPERTIES: "PROPERTY", CONSTRAINTS: "CONSTRAINT", ACTION_CONSTRAINTS: "ACTION_CONSTRAINT" };

/** The names a .cfg lists under INVARIANT, PROPERTY, CONSTRAINT and ACTION_CONSTRAINT. */
export function parseCfg(text) {
  const out = { INVARIANT: [], PROPERTY: [], CONSTRAINT: [], ACTION_CONSTRAINT: [] };
  let section = null;
  for (const tok of stripTlaComments(text).split(/\s+/).filter(Boolean)) {
    if (CFG_KEYWORDS.has(tok)) { section = SECTION[tok] ?? tok; continue; }
    if (section in out && /^[A-Za-z_]\w*$/.test(tok)) out[section].push(tok);
  }
  return { invariants: out.INVARIANT, properties: out.PROPERTY, constraints: out.CONSTRAINT, actionConstraints: out.ACTION_CONSTRAINT };
}

/** The .cfg with its INVARIANT and PROPERTY lines replaced by these, and the named constraints dropped. */
export function cfgWithChecks(text, { invariants = [], properties = [], drop = [] } = {}) {
  const kept = [];
  let section = null;
  for (const line of text.split("\n")) {
    const words = stripTlaComments(line).trim().split(/\s+/).filter(Boolean);
    if (words.length && CFG_KEYWORDS.has(words[0])) section = SECTION[words[0]] ?? words[0];
    if (section === "INVARIANT" || section === "PROPERTY") continue;
    if ((section === "CONSTRAINT" || section === "ACTION_CONSTRAINT") && words.length) {
      const names = words.filter((w) => !CFG_KEYWORDS.has(w) && !drop.includes(w));
      if (names.length === 0) continue;
      kept.push((CFG_KEYWORDS.has(words[0]) ? `${section} ` : "    ") + names.join(" "));
      continue;
    }
    kept.push(line);
  }
  return [...kept, ...invariants.map((i) => `INVARIANT ${i}`), ...properties.map((p) => `PROPERTY ${p}`), ""].join("\n");
}

/** A nullary operator whose body is only a conjunction of nullary operators stands for them. */
function conjuncts(name, defs, seen = new Set()) {
  const d = defs.get(name);
  if (!d || d.params.length || seen.has(name)) return [name];
  const parts = d.body.split(/\/\\|∧/).map((s) => s.trim()).filter(Boolean);
  const pure = parts.length > 1 && parts.every((p) => /^[A-Za-z_]\w*$/.test(p) && defs.has(p) && !defs.get(p).params.length);
  if (!pure) return [name];
  seen.add(name);
  return parts.flatMap((p) => conjuncts(p, defs, seen));
}

const NOT_A_RULE = new Set(["TypeOK"]);

// ---- Alloy ------------------------------------------------------------------

export function stripAlloyComments(src) {
  return src.replace(/\/\*[\s\S]*?\*\//g, (c) => c.replace(/[^\n]/g, " "))
    .replace(/(--|\/\/).*$/gm, (c) => " ".repeat(c.length));
}

/** Each `fact` and `assert` block: { kind, name, body }. A fact may be unnamed. */
export function alloyBlocks(src) {
  const text = stripAlloyComments(src);
  const out = [];
  const re = /\b(fact|assert)\s+([A-Za-z_][\w']*)?\s*\{/g;
  let m;
  while ((m = re.exec(text))) {
    let depth = 1, i = re.lastIndex;
    for (; i < text.length && depth; i++) depth += text[i] === "{" ? 1 : text[i] === "}" ? -1 : 0;
    out.push({ kind: m[1], name: m[2] ?? null, body: text.slice(re.lastIndex, i - 1).trim() });
    re.lastIndex = i;
  }
  return out;
}

/** The names of the `check` commands, in order. */
export function alloyChecks(src) {
  return [...stripAlloyComments(src).matchAll(/^\s*check\s+([A-Za-z_][\w']*)/gm)].map((m) => m[1]);
}

// ---- both ---------------------------------------------------------------------

export const normalize = (s) => s.replace(/\s+/g, "");
export const isTla = (p) => extname(p).toLowerCase() === ".tla";

/** The checks a correct model makes (see the header). */
export function checksOf(modelPath) {
  const src = readFileSync(modelPath, "utf-8");
  if (!isTla(modelPath)) return alloyChecks(src);
  const cfg = modelPath.replace(/\.tla$/, ".cfg");
  if (!existsSync(cfg)) return [];
  const { invariants, properties } = parseCfg(readFileSync(cfg, "utf-8"));
  const defs = tlaDefinitions(src);
  const names = [...invariants.flatMap((n) => conjuncts(n, defs)), ...properties];
  return [...new Set(names)].filter((n) => !NOT_A_RULE.has(n));
}

/** The model whose twins this one takes (`\* @twins-of <model>` in its first lines), or null. */
export function twinsOfDeclared(modelPath) {
  const m = /^\\\* @twins-of (\S+)/m.exec(readFileSync(modelPath, "utf-8").split("\n").slice(0, 10).join("\n"));
  return m ? join(dirname(modelPath), m[1] + extname(modelPath)) : null;
}

/** model path -> its twins' paths, for the correct models and twins given. */
export function twinsOf(correct, twins) {
  const stem = (p) => basename(p, extname(p));
  const out = new Map(correct.map((m) => [m, []]));
  for (const t of twins) {
    const owner = correct
      .filter((m) => dirname(m) === dirname(t) && extname(m) === extname(t) && stem(t).startsWith(stem(m) + "-"))
      .sort((a, b) => stem(b).length - stem(a).length)[0];
    if (owner) out.get(owner).push(t);
  }
  for (const m of correct) {
    const of = existsSync(m) ? twinsOfDeclared(m) : null;
    if (of && out.has(of)) out.set(m, [...out.get(m), ...out.get(of)]);
  }
  return out;
}

/** Each check of the model that restates what the model assumes: { check, why }. */
export function tautologies(modelPath) {
  const src = readFileSync(modelPath, "utf-8");
  const out = [];
  if (!isTla(modelPath)) {
    const blocks = alloyBlocks(src);
    const facts = blocks.filter((b) => b.kind === "fact");
    for (const name of alloyChecks(src)) {
      const a = blocks.find((b) => b.kind === "assert" && b.name === name);
      const f = a && facts.find((x) => normalize(x.body) === normalize(a.body));
      if (f) out.push({ check: name, why: `the same expression as fact ${f.name ?? "(unnamed)"}` });
    }
    return out;
  }
  const cfgPath = modelPath.replace(/\.tla$/, ".cfg");
  if (!existsSync(cfgPath)) return out;
  const cfg = parseCfg(readFileSync(cfgPath, "utf-8"));
  const defs = tlaDefinitions(src);
  const body = (n) => normalize(defs.get(n)?.body ?? "");
  const assumes = tlaAssumes(src).map(normalize);
  const constraints = [...cfg.constraints.map((n) => ["CONSTRAINT", n]), ...cfg.actionConstraints.map((n) => ["ACTION_CONSTRAINT", n])];
  for (const check of checksOf(modelPath)) {
    const b = body(check);
    if (b && assumes.includes(b)) out.push({ check, why: "the same expression as an ASSUME" });
    for (const [kind, k] of constraints) {
      const kb = body(k);
      // A PROPERTY [][K]_v or []K over a constraint K holds of whatever K leaves.
      const boxed = new RegExp(`^\\[\\]\\[?${k}(\\]_.+)?$`).test(b);
      if (check === k || (b && kb && b === kb) || boxed) out.push({ check, why: `the same expression as ${kind} ${k}` });
    }
  }
  return out;
}

/** The constraints of a correct TLA+ model: [{ name, action }], action when it reads a primed variable. */
export function constraintsOf(modelPath) {
  const cfgPath = modelPath.replace(/\.tla$/, ".cfg");
  if (!isTla(modelPath) || !existsSync(cfgPath)) return [];
  const cfg = parseCfg(readFileSync(cfgPath, "utf-8"));
  const defs = tlaDefinitions(readFileSync(modelPath, "utf-8"));
  const primed = (n) => /[A-Za-z0-9_)\]]'/.test(defs.get(n)?.body ?? "");
  return [...cfg.constraints.map((name) => ({ name, action: primed(name) })),
    ...cfg.actionConstraints.map((name) => ({ name, action: true }))];
}

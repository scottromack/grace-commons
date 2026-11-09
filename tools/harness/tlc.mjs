// Grace Commons — run a TLA+ model under TLC (tools/tlc/tla2tools.jar).
//
// check.mjs and isolate.mjs both go through runTlc. A run copies the model into
// a temporary directory by tla-adapter.mjs (TLC needs a module name that is an
// identifier and matches the file name), writes its .cfg beside it as written
// (or the cfg text isolate.mjs synthesizes), runs TLC there with its working
// files there, and removes the directory. TLC's exit status decides:
//   0   no error                                  -> kind "hold"
//   12  an invariant is violated (13: a property) -> kind "violated"
//   else, or a run still going at the time limit  -> kind "error"
// No state cap: the limit is time, 15 minutes unless the caller says otherwise.
// `-deadlock` turns TLC's deadlock check off, as the harness has always allowed
// deadlock. `states` is TLC's distinct-states count.

import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { adaptOne } from "./tla-adapter.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
export const TLC_JAR = join(HERE, "../tlc/tla2tools.jar");
export const DEFAULT_LIMIT_MS = 15 * 60 * 1000;

export function javaMajor(java) {
  const r = spawnSync(java, ["-version"], { encoding: "utf8" });
  const m = /version "(\d+)/.exec(`${r.stderr || ""}${r.stdout || ""}`);
  return m ? Number(m[1]) : 0;
}

/** The first JDK 17+ found (Linux: bootstrap.sh's JRE in /tmp; macOS: any installed JDK). Throws if none. */
export function findJava() {
  // The JRE is provisioned on the native /tmp FS, not in the mounted repo
  // node_modules: unpacking the JRE into the mount drops libjli.so and the
  // launcher fails with exit 127. bootstrap.sh installs it to /tmp/javajre.
  const candidates = [
    "/tmp/javajre/node_modules/javajre-linux-64/jre/bin/java",
    join(HERE, "node_modules/javajre-linux-64/jre/bin/java"),
  ];
  // macOS: the npm JRE is Linux-only, so take any installed JDK 17+.
  if (process.env.JAVA_HOME) candidates.push(join(process.env.JAVA_HOME, "bin/java"));
  if (process.platform === "darwin") {
    const jh = spawnSync("/usr/libexec/java_home", ["-v", "17+"], { encoding: "utf8" });
    if (jh.status === 0 && jh.stdout.trim()) candidates.push(join(jh.stdout.trim(), "bin/java"));
    candidates.push(
      "/opt/homebrew/opt/openjdk@17/bin/java",
      "/usr/local/opt/openjdk@17/bin/java",
      "/opt/homebrew/opt/openjdk/bin/java",
      "/usr/local/opt/openjdk/bin/java",
    );
  }
  const p = candidates.find((c) => existsSync(c) && javaMajor(c) >= 17);
  if (!p) throw new Error("JRE 17 not found — on Linux run tools/harness/bootstrap.sh; on macOS install a JDK 17+ (brew install openjdk@17) or set JAVA_HOME to one.");
  return p;
}

/** The distinct-states count in TLC's output: the last "N states generated … M distinct states found" (a progress line carries thousands separators). */
export function statesIn(out) {
  let last = null;
  for (const l of out.replace(/(\d),(?=\d{3})/g, "$1").split("\n")) {
    const m = /(\d+) states generated.*?(\d+) distinct states found/.exec(l);
    if (m) last = Number(m[2]);
  }
  return last;
}

export function runTlc(tlaPath, { cfgText, workers = "auto", limitMs = DEFAULT_LIMIT_MS, heapMb } = {}) {
  const started = Date.now();
  const done = (r) => ({ ...r, seconds: (Date.now() - started) / 1000 });
  if (!existsSync(TLC_JAR)) return done({ kind: "error", message: `TLC not found at ${TLC_JAR}` });
  const base = tlaPath.replace(/\.tla$/, "");
  if (cfgText === undefined && !existsSync(base + ".cfg")) return done({ kind: "error", message: `no .cfg beside ${basename(tlaPath)}` });
  if (existsSync(base + ".constants.json")) return done({ kind: "error", message: `${basename(base)}.constants.json: TLC reads the .cfg alone` });
  let java;
  try { java = findJava(); } catch (e) { return done({ kind: "error", message: e.message }); }

  const work = mkdtempSync(join(tmpdir(), "tlc-"));
  try {
    const tla = adaptOne(tlaPath, work, { quiet: true });
    if (!tla) return done({ kind: "error", message: `no MODULE header in ${basename(tlaPath)}` });
    if (cfgText !== undefined) writeFileSync(tla.replace(/\.tla$/, ".cfg"), cfgText);
    // TLC unpacks the standard modules (Naturals.tla and the rest) into java.io.tmpdir; side by
    // side, in the shared system directory, one run rewrites a module another is parsing.
    const args = ["-XX:+UseParallelGC", `-Djava.io.tmpdir=${work}`, ...(heapMb ? [`-Xmx${heapMb}m`] : []),
      "-cp", TLC_JAR, "tlc2.TLC", "-deadlock", "-workers", String(workers),
      "-metadir", join(work, "states"), basename(tla)];
    const r = spawnSync(java, args, { cwd: work, encoding: "utf8", maxBuffer: 256 * 1024 * 1024, timeout: limitMs });
    const out = `${r.stdout || ""}\n${r.stderr || ""}`;
    const states = statesIn(out);
    if (r.error && r.error.code === "ETIMEDOUT") {
      return done({ kind: "error", capped: true, states,
        message: `TLC stopped at ${+(limitMs / 60000).toFixed(2)} minutes${states === null ? "" : ` after ${states} distinct states`}`, out });
    }
    if (r.status === 0) return done({ kind: "hold", states, out });
    const viol = /Error: (Invariant \S+ is violated|Temporal properties were violated|Action property \S+ is violated)/.exec(out);
    if ((r.status === 12 || r.status === 13) && viol) return done({ kind: "violated", states, message: viol[1], out });
    const err = (out.split("\n").find((l) => /^Error:/.test(l)) || out.trim().split("\n").slice(-1)[0] || `exit ${r.status}`).trim();
    return done({ kind: "error", states, message: `TLC exit ${r.status}: ${err}`, out });
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
}

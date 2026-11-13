// Grace Commons — prove a TLA+ theorem under TLAPS (tlapm), the TLA+ Proof System.
//
// audit.mjs calls runTlapm on every correct .tla model that holds a THEOREM with a
// PROOF (hasProof): a law that must hold at every size, where TLC can only check
// the sizes it is given. Unit `tooling: TLAPS installed and wired`, Scott 2026-11-10
// ("yes" to the 1.6.0 rolling pre-release, a named exception to his "only stable
// versions" rule: the last stable TLAPS, 1.5.0, is an Intel-only installer).
//
// tlapm is not in the repo: bootstrap.sh unpacks the pinned 1.6.0-pre build, by
// checksum, into $TLAPM_HOME (default ~/.local/share/tlapm/1.6.0-pre). A run copies
// the model into a temporary directory by tla-adapter.mjs (tlapm, like TLC, wants a
// module name that is an identifier and matches the file name), runs tlapm there so
// its .tlacache stays out of the repo, and removes the directory. `--strict` makes
// tlapm exit non-zero on an incomplete proof, an empty proof target or a failed
// obligation, so its exit status decides:
//   0                                      -> kind "proved"  (`obligations`: how many)
//   a failed or unproved obligation        -> kind "failed"  (`failed`, `obligations`)
//   else, or a run still going at the limit -> kind "error"

import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join, basename } from "node:path";
import { spawnSync } from "node:child_process";
import { adaptOne } from "./tla-adapter.mjs";

export const TLAPM_HOME = process.env.TLAPM_HOME || join(homedir(), ".local/share/tlapm/1.6.0-pre");
export const DEFAULT_PROOF_LIMIT_MS = 15 * 60 * 1000;

/** The tlapm binary: $TLAPM, else the one bootstrap.sh unpacked; null when neither exists. */
export function findTlapm() {
  const candidates = [process.env.TLAPM, join(TLAPM_HOME, "tlapm/bin/tlapm")].filter(Boolean);
  return candidates.find((c) => existsSync(c)) ?? null;
}

/** A module's text without its comments: `(* ... *)` (nested) and `\* ...` to the end of the line. */
function withoutComments(src) {
  let out = "", depth = 0;
  for (let i = 0; i < src.length; i++) {
    if (src.startsWith("(*", i)) { depth++; i++; }
    else if (depth && src.startsWith("*)", i)) { depth--; i++; }
    else if (!depth && src.startsWith("\\*", i)) { while (i < src.length && src[i] !== "\n") i++; out += "\n"; }
    else if (!depth) out += src[i];
  }
  return out;
}

/** True when the module states a THEOREM (or LEMMA, PROPOSITION, COROLLARY) and gives it a proof: PROOF, a step `<1>`, BY or OBVIOUS. */
export function hasProof(src) {
  const text = withoutComments(src);
  const stated = /^[ \t]*(?:THEOREM|LEMMA|PROPOSITION|COROLLARY)\b/m.exec(text);
  if (!stated) return false;
  return /\bPROOF\b|^[ \t]*<\d+>|\bBY\b|\bOBVIOUS\b/m.test(text.slice(stated.index));
}

export function runTlapm(tlaPath, { limitMs = DEFAULT_PROOF_LIMIT_MS } = {}) {
  const started = Date.now();
  const done = (r) => ({ ...r, seconds: (Date.now() - started) / 1000 });
  const tlapm = findTlapm();
  if (!tlapm) return done({ kind: "error", message: `tlapm not found (TLAPM_HOME ${TLAPM_HOME}): run tools/harness/bootstrap.sh` });
  const work = mkdtempSync(join(tmpdir(), "tlapm-"));
  try {
    const tla = adaptOne(tlaPath, work, { quiet: true });
    if (!tla) return done({ kind: "error", message: `no MODULE header in ${basename(tlaPath)}` });
    const r = spawnSync(tlapm, ["--strict", basename(tla)], { cwd: work, encoding: "utf8", maxBuffer: 64 * 1024 * 1024, timeout: limitMs });
    const out = `${r.stdout || ""}\n${r.stderr || ""}`;
    if (r.error && r.error.code === "ETIMEDOUT") return done({ kind: "error", message: `tlapm stopped at ${+(limitMs / 60000).toFixed(2)} minutes`, out });
    const all = /All (\d+) obligations? proved/.exec(out);
    if (r.status === 0 && all) return done({ kind: "proved", obligations: Number(all[1]), out });
    const failed = /(\d+)\/(\d+) obligations? failed/.exec(out);
    if (failed) return done({ kind: "failed", failed: Number(failed[1]), obligations: Number(failed[2]), message: `${failed[1]} of ${failed[2]} obligations failed`, out });
    const err = (out.split("\n").find((l) => /\[ERROR\]/.test(l)) || out.trim().split("\n").slice(-1)[0] || `exit ${r.status}`).trim();
    return done({ kind: "error", message: `tlapm exit ${r.status}: ${err}`, out });
  } finally {
    rmSync(work, { recursive: true, force: true });
  }
}

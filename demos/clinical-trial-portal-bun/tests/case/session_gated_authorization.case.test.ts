// The Edge Finder's Case Tests for Session-Gated Authorization, run on the rendered src/session_gated_authorization.ts.
//
// session_gated_authorization.scenarios.json is derived, never edited: `gen_tests_calls.py --scenarios-json` over the IR of
// compositions/session-gated-authorization.md (the closure tables are the source; one test a row, a row the generator cannot run
// is skipped with its reason). The two constituents are fakes that answer by script under the pattern's names (`session/validate`,
// `permissions/permitted`) and record every call in order, the world of login.case.test.ts; the composition under test is the real
// src/session_gated_authorization.ts, unchanged. A miss is reported with its row and its Owner, and is never explained away.
import { test, expect, afterAll } from "bun:test";
import { readFileSync } from "node:fs";
import { SessionGatedAuthorization } from "../../src/session_gated_authorization.ts";
import { Unavailable } from "../../src/store.ts";
import { World, bag, type Script } from "./world.ts";

type Assert = [string, ...unknown[]];
type Scenario = { label: string; action: "check_permitted"; args: { session_token: string; action_scope: string }; settings: { length_bound: number | null }; script: Script; asserts: Assert[] };
const doc = JSON.parse(readFileSync(new URL("./session_gated_authorization.scenarios.json", import.meta.url), "utf8")) as {
  commit: string; rows: { n: number; line: number; caption: string; text: string }[]; scenarios: Record<string, (Scenario | ["skip", string])[]>;
};
const norm = (s: unknown) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");

/** What the rendered answer is, as the page names the arm. */
function arm(a: unknown): [string, unknown] {
  if (typeof a === "string") return [a, null];
  const o = a as { refused: string; reason?: string };
  return [o.refused, o.reason ?? null];
}

async function run(sc: Scenario) {
  const w = new World();
  w.setScript(sc.script);
  const answered = (target: string, action: string, args: unknown[]) => {
    const [name, payload] = w.answer(target, action, args);
    if (name === "state-unavailable") throw new Unavailable();
    return [name, payload] as [string, any];
  };
  const session = {
    validate: async (t: string) => {
      const [name, p] = answered("session", "validate", [t]);
      return name === "valid" ? { valid: { principal_ref: p.principal_ref, expires_at: "later" } } : { invalid: p };
    },
  };
  const permissions = { stringCap: 64, permitted: async (s: string, a: string) => answered("permissions", "permitted", [s, a])[0] };
  const gate = new SessionGatedAuthorization(session as never, permissions as never, sc.settings.length_bound ?? undefined);
  const answer = arm(await gate.checkPermitted(sc.args.session_token, sc.args.action_scope));
  const made = (t: string, a: string) => w.calls.filter((c) => c[0] === t && c[1] === a);

  for (const a of sc.asserts) {
    switch (a[0]) {
      case "answer": expect(norm(answer[0]), `answered ${JSON.stringify(answer)}, the page says ${a[1]}`).toBe(norm(a[1])); break;
      case "payload_has": for (const v of a[1] as unknown[]) expect(bag(answer[1]).includes(v), `the answer's payload ${JSON.stringify(answer[1])} lacks ${v}`).toBe(true); break;
      case "no_call": expect(made(String(a[1]), String(a[2])), `called ${a[1]}'s ${a[2]}`).toEqual([]); break;
      case "called": expect(made(String(a[1]), String(a[2])).length, `never called ${a[1]}'s ${a[2]}`).toBeGreaterThan(0); break;
      case "call_args_exact":
        expect(made(String(a[1]), String(a[2])).some((c) => JSON.stringify(c[2]) === JSON.stringify(a[3])), `no call to ${a[1]}'s ${a[2]} carries exactly ${JSON.stringify(a[3])} (its calls: ${JSON.stringify(made(String(a[1]), String(a[2])).map((c) => c[2]))})`).toBe(true);
        break;
      default: throw new Error(`the runner does not know the assertion ${a[0]}`);
    }
  }
}

const ran = { rows: 0, passed: 0, skipped: 0, scenarios: 0 };
const failures: string[] = [];
for (const r of doc.rows) {
  const scs = doc.scenarios[String(r.n)] ?? [];
  const runnable = scs.filter((s): s is Scenario => !Array.isArray(s));
  if (!runnable.length) {
    ran.skipped++;
    test.skip(`row ${String(r.n).padStart(2, "0")} (line ${r.line}) ${r.text}  [skipped: ${(scs[0] as [string, string])?.[1]?.slice(0, 90)}]`, () => {});
    continue;
  }
  ran.rows++;
  test(`row ${String(r.n).padStart(2, "0")} (line ${r.line}) ${r.text}`, async () => {
    let bad = 0;
    for (const sc of runnable) {
      ran.scenarios++;
      try { await run(sc); } catch (e) { bad++; failures.push(`row ${r.n} | ${sc.label}: ${(e as Error).message.split("\n")[0]}`); }
    }
    if (!bad) ran.passed++;
    expect(bad, failures.filter((f) => f.startsWith(`row ${r.n} `)).join("\n")).toBe(0);
  });
}
afterAll(() => {
  console.log(`\nCase Tests, Session-Gated Authorization @ ${doc.commit}: ${doc.rows.length} rows, ${ran.rows} run (${ran.scenarios} scenarios), ${ran.passed} passing, ${ran.skipped} skipped (a row the generator cannot run)`);
  for (const f of failures) console.log("  MISS " + f);
});

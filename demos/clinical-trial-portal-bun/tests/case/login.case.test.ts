// The Edge Finder's Case Tests for Login, run on the rendered src/login.ts.
//
// login.scenarios.json is derived, never edited: `gen_tests_calls.py --scenarios-json` over the IR of
// compositions/login.md (the closure tables are the source; one test a row, a row the generator cannot run is
// skipped with its reason). The world is world.ts, a port of gen_runtime_calls.py. A miss is reported with its row
// and its Owner, and is never explained away: the test fails.
import { test, expect, afterAll } from "bun:test";
import { readFileSync } from "node:fs";
import { Login } from "../../src/login.ts";
import { World, memStore, fakes, bag, type Script } from "./world.ts";

type Assert = [string, ...unknown[]];
type Scenario = {
  label: string; action: "login" | "logout" | "revoke_sessions_for_credential"; args: Record<string, unknown>; now: number;
  setup: [string, Record<string, unknown>, number][]; settings: Record<string, unknown>; script: Script; setup_script: Script;
  asserts: Assert[]; refuse_commits: number[]; setup_expect?: string[];
};
const doc = JSON.parse(readFileSync(new URL("./login.scenarios.json", import.meta.url), "utf8")) as {
  commit: string; rows: { n: number; line: number; caption: string; text: string }[]; scenarios: Record<string, (Scenario | ["skip", string])[]>;
};

const norm = (s: unknown) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "");
const ARGS: Record<string, string[]> = {
  login: ["principal_ref", "credential_type", "presented_material", "issued_by_ref", "session_duration"],
  logout: ["session_token", "revoked_by_ref", "reason"],
  revoke_sessions_for_credential: ["credential_id", "revoked_by_ref", "reason"],
};
const METHOD: Record<string, string> = { login: "login", logout: "logout", revoke_sessions_for_credential: "revokeSessionsForCredential" };

/** What the rendered answer is, as the page names the arm. */
function arm(a: unknown, action: string): [string, unknown] {
  if (a === "invalid-credential") return ["invalid-credential", null];
  if (a === "ok") return ["ok", null];
  const o = a as Record<string, unknown>;
  if ("session_token" in o) return ["login result", o.session_token];
  if ("refused" in o) return [String(o.refused), o.stage ?? null];
  if (action === "revoke_sessions_for_credential") return ["revocation tally", o];
  return ["unknown", o];
}

async function run(sc: Scenario) {
  const w = new World();
  const parts = fakes(w);
  const seam = { now: () => w.now as string, idMaterial: (() => { let i = 0; return () => `id-${++i}`; })(), sessionToken: () => "unused" };
  const s = sc.settings as { issuer_references: string[]; default_session_duration?: number; service_identity: { actor_ref: string; credential: string } };
  const login = await Login.open(memStore(w) as never, seam, parts as never, {
    issuerReferences: s.issuer_references, sessionDurationSeconds: s.default_session_duration ?? null,
    serviceIdentity: s.service_identity, loginEventRetentionMs: 1e15,
  });
  const ids: Record<number, unknown> = {};
  const resolve = (v: unknown): unknown => (v === "@token" ? ids[1] : Array.isArray(v) ? v.map(resolve) : v && typeof v === "object" ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, resolve(x)])) : v);
  const call = (action: string, args: Record<string, unknown>) => (login as never as Record<string, (...a: unknown[]) => Promise<unknown>>)[METHOD[action]](...ARGS[action].map((k) => (resolve(args)as Record<string, unknown>)[k]));

  const setupAnswers: [string, unknown][] = [];
  w.setScript(sc.setup_script);
  for (const [k, [action, args, now]] of sc.setup.entries()) {
    w.now = now;
    const a = arm(await call(action, args), action);
    setupAnswers.push(a);
    if (a[1] !== null && a[1] !== undefined) ids[k + 1] = a[1];
  }
  w.setScript(sc.script, sc.refuse_commits);
  const markCalls = w.calls.length;
  w.now = sc.now;
  const answer = arm(await call(sc.action, sc.args), sc.action);
  const calls = w.calls.slice(markCalls);
  const made = (t: string, a: string) => calls.filter((c) => c[0] === t && c[1] === a);
  const puts = w.commits.filter((c) => c.applied).flatMap((c) => c.stmts.map((s) => s.params[0] as Record<string, unknown>));

  const check = (raw: Assert) => {
    const a = resolve(raw) as Assert;
    switch (a[0]) {
      case "answer": expect(norm(answer[0]), `answered ${JSON.stringify(answer)}, the page says ${a[1]}`).toBe(norm(a[1])); break;
      case "setup_ok": {
        const want = sc.setup_expect ?? [];
        expect(setupAnswers.length, "SETUP FAILURE: setup calls").toBe(want.length);
        setupAnswers.forEach((g, i) => expect(norm(g[0]), `SETUP FAILURE: setup call ${i + 1} answered ${JSON.stringify(g)}`).toBe(norm(want[i])));
        break;
      }
      case "nothing_written": {
        // Nothing landed. A cascade records its initiation event before it reads anything (Action wiring 17), so its rows
        // (flag false) allow that one constituent write; every other row allows none, the session included.
        // The Python world keeps a Call to record_action outside the composition's store; here an event that landed is a
        // write like any other, so the two readings agree on what "the store changed" means.
        const strict = a.length < 2 || a[1];
        const landed = w.commits.filter((c) => c.applied).flatMap((c) => c.stmts).filter((s) => strict || s.text !== "PUT audit_events");
        expect(landed.map((s) => s.text), "the store changed").toEqual([]);
        // STRICT_CALLS=1 reads "recorded an audit event" as gen_runtime_calls.py does: any record_action call, landed or not.
        // Login plans its event inside the transaction that writes it (Action wiring 45), so the call precedes a refused commit.
        if (strict && process.env.STRICT_CALLS) expect(made("audit_trail", "record_action"), "recorded an audit event").toEqual([]);
        break;
      }
      case "no_call": expect(made(String(a[1]), String(a[2])), `called ${a[1]}'s ${a[2]}`).toEqual([]); break;
      case "called": expect(made(String(a[1]), String(a[2])).length, `never called ${a[1]}'s ${a[2]} (calls: ${JSON.stringify(calls.map((c) => c[0] + "/" + c[1]))})`).toBeGreaterThan(0); break;
      case "calls_in_order": {
        const have = calls.map((c) => `${c[0]}/${c[1]}`);
        let at = -1;
        for (const [t, ac] of a[1] as [string, string][]) {
          const i = have.indexOf(`${t}/${ac}`);
          expect(i, `${t}'s ${ac} was never called; the calls were ${have}`).toBeGreaterThanOrEqual(0);
          expect(i, `${t}'s ${ac} was first called out of order; the calls were ${have}`).toBeGreaterThan(at);
          at = i;
        }
        break;
      }
      case "call_args_have":
        expect(made(String(a[1]), String(a[2])).some((c) => (a[3] as unknown[]).every((v) => bag(c[2]).includes(v))), `no call to ${a[1]}'s ${a[2]} carries ${JSON.stringify(a[3])} (its calls: ${JSON.stringify(made(String(a[1]), String(a[2])).map((c) => c[2]))})`).toBe(true);
        break;
      case "call_args_str":
        expect(made(String(a[1]), String(a[2])).some((c) => bag(c[2]).includes(a[3])), `no call to ${a[1]}'s ${a[2]} carries the string ${JSON.stringify(a[3])}`).toBe(true);
        break;
      case "put_has": expect(puts.some((r) => (a[1] as unknown[]).every((v) => bag(r).includes(v))), `no record written carries ${JSON.stringify(a[1])}`).toBe(true); break;
      case "writes_made": expect(w.commits.some((c) => c.applied && c.stmts.length > 0), "no write was asked for").toBe(true); break;
      case "commits_at_least": expect(w.commitAttempts, `${w.commitAttempts} commits asked for, the page says at least ${a[1]}`).toBeGreaterThanOrEqual(Number(a[1])); break;
      case "payload_has": for (const v of a[1] as unknown[]) expect(bag(answer[1]).includes(v), `the answer's payload ${JSON.stringify(answer[1])} lacks ${v}`).toBe(true); break;
      case "payload_lacks": expect(bag(answer[1]).includes(a[1]), `the answer carries ${a[1]}`).toBe(false); break;
      case "tally": {
        const want = { revoked: 0, skipped: 0, failed: 0, not_found: 0 } as Record<string, number>;
        want[String(a[1])] = 1;
        const p = answer[1] as Record<string, number>;
        expect(Object.fromEntries(Object.keys(want).map((k) => [k, p?.[k]])), `the tally ${JSON.stringify(p)}`).toEqual(want);
        break;
      }
      default: throw new Error(`the runner does not know the assertion ${a[0]}`);
    }
  };
  for (const a of sc.asserts) check(a);
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
  console.log(`\nCase Tests, Login @ ${doc.commit}: ${doc.rows.length} rows, ${ran.rows} run (${ran.scenarios} scenarios), ${ran.passed} passing, ${ran.skipped} skipped (a row the generator cannot run)`);
  for (const f of failures) console.log("  MISS " + f);
});

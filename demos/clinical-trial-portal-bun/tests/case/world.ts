// The test world of the Edge Finder's Case Tests for a composition, in TypeScript: a port of the semantics of
// seam-trial-code/gen_runtime_calls.py (a Call is answered by a script and every call is recorded in order; the
// store is the composition's own and is recorded commit by commit) over the rendered Login. The constituents are
// fakes that answer by script under the pattern's names (`credential/verify`, `session/issue`, `audit_trail/record_action`);
// the composition under test is the real src/login.ts, unchanged.
import { Unavailable, type Stmt } from "../../src/store.ts";

export type Arm = [string, unknown];
export type Script = Record<string, Arm[]>;
export type Call = [string, string, unknown[]];

/** Every primitive value nested in a value, whatever its layout (the world's `bag`). */
export function bag(v: unknown, out: unknown[] = []): unknown[] {
  if (v === null || v === undefined) return out;
  if (Array.isArray(v)) v.forEach((x) => bag(x, out));
  else if (typeof v === "object") Object.values(v as object).forEach((x) => bag(x, out));
  else out.push(v);
  return out;
}

export class World {
  calls: Call[] = [];
  private script: Script = {};
  private seen = new Map<string, number>();
  private events = 0;
  commitAttempts = 0;
  commits: { n: number; applied: boolean; stmts: Stmt[] }[] = [];
  refuse = new Set<number>();
  tables: Record<string, Map<string, Record<string, unknown>>> = {};
  now: unknown = 0;

  setScript(s: Script, refuse: number[] = []) {
    this.script = Object.fromEntries(Object.entries(s).map(([k, v]) => [k, v.map(([n, p]) => [n, p] as Arm)]));
    this.seen = new Map();
    this.commitAttempts = 0;
    this.commits = [];
    this.refuse = new Set(refuse);
  }

  /** The k-th call to an action gets the k-th answer; the last answer repeats. */
  answer(target: string, action: string, args: unknown[]): Arm {
    this.calls.push([target, action, args]);
    const key = `${target}/${action}`;
    const arms = this.script[key];
    if (!arms?.length) throw new TypeError(`a Call to ${key}: the scripted world has no answer for it`);
    const k = this.seen.get(key) ?? 0;
    this.seen.set(key, k + 1);
    const [name, payload] = arms[Math.min(k, arms.length - 1)];
    if (typeof payload === "string" && payload.startsWith("@seq:")) return [name, `${payload.slice(5)}-${++this.events}`];
    return [name, structuredClone(payload)];
  }

  snapshot(): string {
    return JSON.stringify(Object.entries(this.tables).map(([t, m]) => [t, [...m.entries()]]));
  }
}

const put = (table: string, row: Record<string, unknown> & { _id: string }): Stmt => ({ text: `PUT ${table}`, params: [row as never] });

/** The composition's own store, in memory: it holds the two maps and the login event log, and records every commit. */
export function memStore(w: World) {
  return {
    declare: async () => {},
    put: (table: string, row: Record<string, unknown> & { _id: string }) => put(table, row),
    async read(text: string, params: unknown[] = []) {
      const m = /SELECT (\w+) FROM (\w+) WHERE (\w+) = \$1/.exec(text);
      if (!m) throw new Error(`the in-memory store does not read: ${text}`);
      const [, col, table, by] = m;
      return [...(w.tables[table]?.values() ?? [])].filter((r) => r[by] === params[0]).map((r) => ({ [col]: r[col] }));
    },
    async commit(stmts: Stmt[]) {
      const n = ++w.commitAttempts;
      if (w.refuse.has(n)) { w.commits.push({ n, applied: false, stmts }); throw new Error("the database refuses the write"); }
      for (const s of stmts) {
        const table = s.text.replace(/^PUT /, "");
        const row = s.params[0] as unknown as Record<string, unknown> & { _id: string };
        (w.tables[table] ??= new Map()).set(row._id, { ...row });
      }
      w.commits.push({ n, applied: true, stmts });
    },
  };
}

const unavailable = (): never => { throw new Unavailable(); };

/** The constituents, answering by script. */
export function fakes(w: World) {
  const marker = (table: string, id: unknown): Stmt => put(table, { _id: String(id) });
  const credential = {
    async verify(...args: unknown[]) {
      const [name, p] = w.answer("credential", "verify", args);
      if (name === "state-unavailable") return unavailable();
      return name === "verified" ? "verified" : { failed: String(p) };
    },
    async read(...args: unknown[]) {
      const [name, p] = w.answer("credential", "read", args);
      return name === "state-unavailable" ? unavailable() : (p as unknown[]);
    },
  };
  const session = {
    planIssue(...args: unknown[]) {
      const [name, p] = w.answer("session", "issue", args);
      if (name === "state-unavailable") return unavailable();
      if (name === "session_token") return { session_token: p as string, stmts: [marker("sessions", p)] };
      return { refused: name };
    },
    async planRevoke(...args: unknown[]) {
      const [name] = w.answer("session", "revoke", args);
      if (name === "state-unavailable") return unavailable();
      return name === "revoked" ? { stmts: [marker("sessions", args[0])] } : { refused: name };
    },
    async validate(...args: unknown[]) {
      const [name, p] = w.answer("session", "validate", args);
      if (name === "state-unavailable") return unavailable();
      if (name === "valid") return { valid: { principal_ref: (p as [string, unknown][])[0][0], expires_at: (p as [string, unknown][])[0][1] } };
      return { invalid: p };
    },
  };
  const audit = {
    log: {
      async read(...args: unknown[]) {
        const [name, p] = w.answer("event_log", "read", args);
        return name === "state-unavailable" ? unavailable() : (p as unknown[]);
      },
    },
    async plan(...args: unknown[]) {
      const [name, p] = w.answer("audit_trail", "record_action", args);
      if (name === "state-unavailable") return unavailable();
      if (name === "event_id") return { event_id: p as string, stmts: [marker("audit_events", p)], indexStmt: marker("audit_index", p) };
      return { refusal: { refused: name, step: p }, keep: [] };
    },
    async index() {},
  };
  return { credential, session, audit };
}

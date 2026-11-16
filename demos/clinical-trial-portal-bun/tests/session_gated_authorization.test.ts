// Session-Gated Authorization. One test for each row of the page's closure tables, by hand: the Edge Finder's
// generator reads Login's table captions and not these, so the rows are named untested by it, not passed over.
import { test, expect, afterAll } from "bun:test";
import { Store, Unavailable } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Session } from "../src/session.ts";
import { Permissions } from "../src/permissions.ts";
import { SessionGatedAuthorization } from "../src/session_gated_authorization.ts";

const store = new Store();
afterAll(() => store.close());

const world = async (lengthBound?: number) => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const px = `sga_${crypto.randomUUID().replaceAll("-", "_")}`;
  const session = await Session.open(store, seam, { defaultDurationSeconds: 3600, table: `${px}_sessions` });
  const perm = await Permissions.open(store, seam, { table: `${px}_grants`, stringCap: 64 });
  const calls: string[] = [];
  const spied = {
    session: { validate: async (t: string) => { calls.push("validate"); return session.validate(t); } } as unknown as Session,
    permissions: Object.assign(Object.create(perm), { permitted: async (s: string, a: string) => { calls.push(`permitted:${s}:${a}`); return perm.permitted(s, a); } }) as Permissions,
  };
  const gate = new SessionGatedAuthorization(spied.session, spied.permissions, lengthBound);
  return { seam, session, perm, gate, calls, spied };
};

test("Row: a blank session token or action scope: invalid-request, no constituent called (Primitive policy 2, 3, 9)", async () => {
  const w = await world();
  for (const [t, s] of [["", "invoice:read"], ["   ", "invoice:read"], ["tok", ""], ["tok", "  "]]) expect(await w.gate.checkPermitted(t, s)).toEqual({ refused: "invalid-request" });
  expect(w.calls).toEqual([]);
});

test("Row: an input over the length bound: invalid-request, no constituent called (Primitive policy 4, 9, 10)", async () => {
  const w = await world(8);
  expect(await w.gate.checkPermitted("t".repeat(9), "scope")).toEqual({ refused: "invalid-request" });
  expect(await w.gate.checkPermitted("tok", "s".repeat(9))).toEqual({ refused: "invalid-request" });
  expect(w.calls).toEqual([]);
  expect(() => new SessionGatedAuthorization(w.spied.session, w.spied.permissions, 65)).toThrow(/string cap/);   // Primitive policy 10: not above the Permissions cap
});

test("Row: an opaque input is compared byte-exact, never trimmed, case-folded or normalized (Primitive policy 5 to 8)", async () => {
  const w = await world();
  const u = "usr_42";
  const tok = (await w.session.issue(u, "gw", 3600) as { session_token: string }).session_token;
  await w.perm.grant(u, "invoice:read");
  expect(await w.gate.checkPermitted(tok, "invoice:read")).toBe("permitted");
  expect(await w.gate.checkPermitted(tok, "Invoice:read")).toBe("denied");
  expect(await w.gate.checkPermitted(tok, "invoice:read ")).toBe("denied");
  expect(await w.gate.checkPermitted(tok.toUpperCase(), "invoice:read")).toEqual({ refused: "session-invalid", reason: "not-known" });
  expect(await w.gate.checkPermitted(` ${tok}`, "invoice:read")).toEqual({ refused: "session-invalid", reason: "not-known" });
});

test("Rows: Session's validate valid: Permissions is called with the principal reference and the scope; permitted and denied answered unchanged, the expiry never answered (Action wiring 5, 6, 10 to 12; Invariant 4.1)", async () => {
  const w = await world();
  const tok = (await w.session.issue("usr_42", "gw", 3600) as { session_token: string }).session_token;
  await w.perm.grant("usr_42", "invoice:read");
  expect(await w.gate.checkPermitted(tok, "invoice:read")).toBe("permitted");
  expect(await w.gate.checkPermitted(tok, "invoice:delete")).toBe("denied");                         // a valid session is not sufficient for access (Invariant 4.2)
  expect(w.calls).toEqual(["validate", "permitted:usr_42:invoice:read", "validate", "permitted:usr_42:invoice:delete"]);
});

test("Row: Session's validate invalid(expired, revoked or not-known): session-invalid naming the reason, Permissions not called (Action wiring 9, Invariant 1.1, 3.2, 3.3)", async () => {
  const w = await world();
  await w.perm.grant("usr_42", "invoice:read");
  const expired = (await w.session.issue("usr_42", "gw", 60) as { session_token: string }).session_token;
  const revoked = (await w.session.issue("usr_42", "gw", 3600) as { session_token: string }).session_token;
  await w.session.revoke(revoked, "usr_42", "logout");
  w.seam.advance(120_000);
  expect(await w.gate.checkPermitted(expired, "invoice:read")).toEqual({ refused: "session-invalid", reason: "expired" });
  expect(await w.gate.checkPermitted(revoked, "invoice:read")).toEqual({ refused: "session-invalid", reason: "revoked" });
  expect(await w.gate.checkPermitted("tok_unknown", "invoice:read")).toEqual({ refused: "session-invalid", reason: "not-known" });
  expect(w.calls.filter((c) => c.startsWith("permitted"))).toEqual([]);
});

test("Rows: state-unavailable from Session's validate or Permissions' permitted is answered state-unavailable, and Permissions is not called after Session's (Constituent failure 3)", async () => {
  const w = await world();
  const down = () => { throw new Unavailable(); };
  const g1 = new SessionGatedAuthorization({ validate: down } as unknown as Session, w.spied.permissions);
  expect(await g1.checkPermitted("tok", "invoice:read")).toEqual({ refused: "state-unavailable" });
  expect(w.calls).toEqual([]);
  const tok = (await w.session.issue("usr_42", "gw", 3600) as { session_token: string }).session_token;
  const g2 = new SessionGatedAuthorization(w.spied.session, { stringCap: 64, permitted: down } as unknown as Permissions);
  expect(await g2.checkPermitted(tok, "invoice:read")).toEqual({ refused: "state-unavailable" });
});

test("Invariant 2.1, 2.2, Action wiring 7, 8, 14, 15: the gate takes no principal; a revocation between two calls changes the second answer, nothing is written, nothing is remembered", async () => {
  const w = await world();
  const tok = (await w.session.issue("usr_42", "gw", 3600) as { session_token: string }).session_token;
  await w.perm.grant("usr_42", "invoice:read");
  expect(w.gate.checkPermitted.length).toBe(2);                                                       // (session_token, action_scope): no subject reference to take
  expect(await w.gate.checkPermitted(tok, "invoice:read")).toBe("permitted");
  await w.session.revoke(tok, "usr_42", "logout");
  expect(await w.gate.checkPermitted(tok, "invoice:read")).toEqual({ refused: "session-invalid", reason: "revoked" });
  expect(await store.history((w.session as unknown as { T: string }).T, tok)).toHaveLength(2);       // active, revoked: the gate wrote no version
});

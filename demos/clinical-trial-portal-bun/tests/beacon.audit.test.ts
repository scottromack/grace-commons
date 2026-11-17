// Beacon's audit screens' own part: who reads how much of the trail, the filters, the retention switch, and the events they write (SPEC.md, The screens, Audit Trail; What each action writes).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon } from "../src/beacon.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { AUDIT_WORDS, RETENTION_DAYS, WITHHELD, withhold, type AuditView } from "../src/beacon_audit.ts";

const store = new Store();
afterAll(() => store.close());
const DAY = 86_400_000;
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `ba_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const sign = async (email: string, pw: string) => { const s = (await b.signIn(email, pw)) as { session_token: string; person: { actor_ref: string } }; return { token: s.session_token, ref: s.person.actor_ref, key: b.keyOf(s.session_token)! }; };
  const anya = await sign("anya@beacon.clinical", "demo-pi"), jordan = await sign("jordan@beacon.clinical", "demo-cra");
  /** A person who holds only what is given (here, `view_own_audit`), made by an invitation Anya sends. */
  let n = 0;
  const pat = async (...give: ("view_own_audit" | "view_audit")[]) => {
    const t = ((await b.invite(anya.token, `pat${++n}@beacon.clinical`, "Pat Rivera", "coordinator")) as { invitation_token: string }).invitation_token;
    const a = (await b.acceptInvitation(t, "password1", "password1")) as { session_token: string; person: { actor_ref: string } };
    for (const g of give) await b.admin.issueGrant(a.person.actor_ref, g, anya.ref, anya.key);
    return { token: a.session_token, ref: a.person.actor_ref, key: b.keyOf(a.session_token)! };
  };
  const events = async () => ((await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[]).map((e) => ({ seq: e.sequence_number, ...(e.data as { action_ref: string; actor_ref: string; data: Record<string, unknown> }) }));
  return { b, seam, anya, jordan, pat, events };
};
const ok = (r: unknown) => { expect(r).not.toHaveProperty("refused"); return r as AuditView; };

test("SPEC.md Audit Trail: a person who holds `view_audit` sees everyone's events newest first, each with its number, time, action, target, actor and payload", async () => {
  const w = await world();
  const v = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  expect(v.scope).toBe("all");
  expect(v.rows.map((r) => r.number)).toEqual([...v.rows.map((r) => r.number)].sort((a, b) => b - a));
  expect(v.rows.some((r) => r.actor === "Beacon" && r.action.startsWith("login_"))).toBe(true);                      // the service identity is named
  const again = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  expect(again.rows.some((r) => r.actor === "Dr. Anya Okonkwo")).toBe(true);                                         // her own opening, read by the next
  const signedIn = v.rows.find((r) => r.action === "login_succeeded")!;
  expect(signedIn.payload).toContain(`"session_token":"${WITHHELD}"`);                                               // Login's event holds the bearer token; no screen shows it
  expect(signedIn.payload).not.toContain(w.anya.token);
  expect(withhold({ a: [{ session_token: "x", b: 1 }], session_token: "y" })).toEqual({ a: [{ session_token: WITHHELD, b: 1 }], session_token: WITHHELD });
  expect(Object.keys(signedIn).sort()).toEqual(["action", "actor", "actor_ref", "event_id", "number", "payload", "recorded_at", "target"]);
}, 60000);

test("SPEC.md Audit Trail: opening the page is itself an event (named beacon.audit_viewed, since Audit Trail reserves audit.*), written under the person who opened it, carrying the filters, the scope and the result count, which does not count the event itself", async () => {
  const w = await world();
  const before = (await w.events()).length;
  const v = ok(await w.b.audits.view(w.anya.ref, w.anya.key, { action: "login_succeeded" }));
  const e = (await w.events()).filter((x) => x.action_ref === "beacon.audit_viewed");
  expect(e).toHaveLength(1);
  expect(e[0]).toMatchObject({ actor_ref: w.anya.ref, data: { target: "audit", scope: "all", result_count: v.rows.length, filters: { action: "login_succeeded", from: null, to: null } } });
  expect((await w.events()).length).toBe(before + 1);
  const again = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  expect(again.rows.some((r) => r.action === "beacon.audit_viewed" && r.actor === "Dr. Anya Okonkwo")).toBe(true);        // the first opening is there for the second to read
}, 60000);

test("SPEC.md The permissions, Audit Trail: a person who holds only `view_own_audit` sees only the events that person made; a person who holds neither is refused and no event is written", async () => {
  const w = await world();
  const own = await w.pat("view_own_audit");
  ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  const first = ok(await w.b.audits.view(own.ref, own.key));
  expect([first.scope, first.rows.length]).toEqual(["own", 0]);
  const second = ok(await w.b.audits.view(own.ref, own.key));
  expect(second.rows.map((r) => [r.action, r.actor_ref])).toEqual([["beacon.audit_viewed", own.ref]]);
  const none = await w.pat();
  const before = (await w.events()).length;
  expect(await w.b.audits.view(none.ref, none.key)).toEqual({ refused: "access-denied", needs: ["view_audit", "view_own_audit"] });
  expect((await w.events()).length).toBe(before);
}, 60000);

test("SPEC.md Audit Trail: the events are filtered by action and by a from and a to date, each end whole (the whole day), and a filter that matches nothing shows none", async () => {
  const w = await world();
  const all = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  expect(all.actions).toContain("login_succeeded");
  const by = ok(await w.b.audits.view(w.anya.ref, w.anya.key, { action: "login_succeeded" }));
  expect(by.rows.length).toBeGreaterThan(0);
  expect(by.rows.every((r) => r.action === "login_succeeded")).toBe(true);
  expect(ok(await w.b.audits.view(w.anya.ref, w.anya.key, { action: "no.such" })).rows).toEqual([]);
  w.seam.advance(2 * DAY);                                                                                           // 2026-09-03
  await w.b.audits.view(w.anya.ref, w.anya.key);
  const onlyToday = ok(await w.b.audits.view(w.anya.ref, w.anya.key, { from: "2026-09-03", to: "2026-09-03" }));
  expect(onlyToday.rows.length).toBeGreaterThan(0);
  expect(onlyToday.rows.every((r) => r.recorded_at.startsWith("2026-09-03"))).toBe(true);
  const earlier = ok(await w.b.audits.view(w.anya.ref, w.anya.key, { to: "2026-09-01" }));
  expect(earlier.rows.every((r) => r.recorded_at < "2026-09-02")).toBe(true);
  expect(earlier.rows.map((r) => r.number)).toEqual(expect.arrayContaining(all.rows.map((r) => r.number)));          // the day's end is whole: everything of 09-01 is there
  expect(ok(await w.b.audits.view(w.anya.ref, w.anya.key, { from: "2026-09-02", to: "2026-09-02" })).rows).toEqual([]);
}, 60000);

test("SPEC.md Audit Trail: a date that is not a date, or a from after a to, is refused with the words and writes no event", async () => {
  const w = await world();
  const before = (await w.events()).length;
  for (const f of [{ from: "yesterday" }, { to: "2026-13-40" }, { from: "2026-9-1" }]) expect(await w.b.audits.view(w.anya.ref, w.anya.key, f)).toEqual({ refused: "invalid-request", message: AUDIT_WORDS.date });
  expect(await w.b.audits.view(w.anya.ref, w.anya.key, { from: "2026-09-05", to: "2026-09-01" })).toEqual({ refused: "invalid-request", message: AUDIT_WORDS.range });
  expect((await w.events()).length).toBe(before);
  expect(ok(await w.b.audits.view(w.anya.ref, w.anya.key, { from: "", to: " " })).filters).toEqual({ action: undefined, from: undefined, to: undefined });   // a blank filter is no filter
}, 60000);

test("SPEC.md What each action writes: the retention window starts off so the whole chain is visible; turning it on hides events older than 2555 days from the page and deletes nothing; turning it off shows them again", async () => {
  const w = await world();
  expect(await w.b.audits.retentionOn()).toBe(false);
  const count = (await w.events()).length;
  w.seam.advance((RETENTION_DAYS + 5) * DAY);
  expect(ok(await w.b.audits.view(w.anya.ref, w.anya.key)).retention_on).toBe(false);
  expect(await w.b.audits.setRetention(w.anya.ref, w.anya.key, true)).toEqual({ on: true });
  expect(await w.b.audits.retentionOn()).toBe(true);
  const v = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  expect(v.retention_on).toBe(true);
  expect(v.rows.map((r) => r.action).sort()).toEqual(["beacon.audit_viewed", "beacon.retention_switched"]);                // the seed's and the openings of the long ago are cut; today's stay
  expect((await w.events()).length).toBeGreaterThan(count);                                                         // nothing deleted
  expect(await w.b.audits.setRetention(w.anya.ref, w.anya.key, false)).toEqual({ on: false });
  expect(await w.b.audits.retentionOn()).toBe(false);                                                               // the change is kept, off as well as on
  expect((await w.events()).filter((e) => e.action_ref === "beacon.retention_switched").map((e) => e.data.retention)).toEqual(["on", "off"]);
  expect(ok(await w.b.audits.view(w.anya.ref, w.anya.key)).rows.length).toBeGreaterThan(count);
}, 60000);

test("SPEC.md Audit Trail: switching the retention window writes its event (target audit, the new state and the days) under the person who switched it, in the transaction that changes it", async () => {
  const w = await world();
  await w.b.audits.setRetention(w.jordan.ref, w.jordan.key, true);
  const e = (await w.events()).filter((x) => x.action_ref === "beacon.retention_switched");
  expect(e).toHaveLength(1);
  expect(e[0]).toMatchObject({ actor_ref: w.jordan.ref, data: { target: "audit", retention: "on", days: 2555 } });
}, 60000);

test("SPEC.md Audit Trail: only a person who holds `view_audit` turns the window; one who holds `view_own_audit` alone, or neither, is refused and nothing changes", async () => {
  const w = await world();
  const own = await w.pat("view_own_audit");
  const before = (await w.events()).length;
  expect(await w.b.audits.setRetention(own.ref, own.key, true)).toEqual({ refused: "access-denied", needs: ["view_audit"] });
  expect(await w.b.audits.retentionOn()).toBe(false);
  expect((await w.events()).length).toBe(before);
  expect(await w.b.audits.setRetention(w.anya.ref, w.anya.key, "yes" as never)).toEqual({ refused: "invalid-request" });
}, 60000);

test("SPEC.md the person's key: a key the system will not attest is refused, and nothing is written, for the page and for the switch", async () => {
  const w = await world();
  const before = (await w.events()).length;
  const other = (await w.b.signIn("jordan@beacon.clinical", "demo-cra")) as { session_token: string };
  const wrong = w.b.keyOf(other.session_token)!;
  expect(await w.b.audits.view(w.anya.ref, wrong)).toEqual({ refused: "invalid-credential" });
  expect(await w.b.audits.setRetention(w.anya.ref, wrong, true)).toEqual({ refused: "invalid-credential" });
  expect(await w.b.audits.view(w.anya.ref, "")).toEqual({ refused: "invalid-request" });
  expect(await w.b.audits.retentionOn()).toBe(false);
  expect((await w.events()).length).toBe(before + 1);                                                               // only Jordan's own sign-in above
}, 60000);

test("SPEC.md Audit Trail: a payload is shown without the target, and an event with no payload shows none", async () => {
  const w = await world();
  const v = ok(await w.b.audits.view(w.anya.ref, w.anya.key));
  const viewed = ok(await w.b.audits.view(w.anya.ref, w.anya.key)).rows.find((r) => r.action === "beacon.audit_viewed")!;
  expect(viewed.target).toBe("audit");
  expect(JSON.parse(viewed.payload)).toEqual({ filters: { action: null, from: null, to: null }, scope: "all", result_count: v.rows.length });
  const out = v.rows.find((r) => r.action === "login_succeeded")!;
  expect(out.payload).not.toContain("target");
}, 60000);

// Beacon's Audit Trail page and its retention switch, one test for each thing SPEC.md says of them (The screens, Audit Trail).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon } from "../src/beacon.ts";
import { buildApp, COOKIE } from "../src/server.ts";
import { AUDIT_WORDS } from "../src/beacon_audit.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `sa_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  return { b, seam, app: buildApp(b) };
};
type W = Awaited<ReturnType<typeof world>>;
const form = (f: Record<string, string>) => ({ method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(f).toString() });
const signIn = async (w: W, email: string, password: string) => /beacon_session=([^;]*)/.exec((await w.app.request("/login", form({ email, password }))).headers.get("set-cookie") ?? "")?.[1] ?? "";
const get = (w: W, path: string, cookie?: string) => w.app.request(path, cookie ? { headers: { cookie: `${COOKIE}=${cookie}` } } : {});
const post = (w: W, path: string, cookie: string, f: Record<string, string>) => w.app.request(path, { ...form(f), headers: { "content-type": "application/x-www-form-urlencoded", cookie: `${COOKIE}=${cookie}` } });

test("SPEC.md Audit Trail: a person with no session is sent to sign-in; a person who holds neither audit permission is answered \"Access denied\" naming both, and nothing is written", async () => {
  const w = await world();
  expect((await get(w, "/audit")).headers.get("location")).toBe("/login");
  expect((await post(w, "/audit/retention", "nope", { on: "true" })).headers.get("location")).toBe("/login");
  const t = ((await w.b.invite((await w.b.signIn("anya@beacon.clinical", "demo-pi") as { session_token: string }).session_token, "p@q.r", "P", "r")) as { invitation_token: string }).invitation_token;
  const acc = await w.app.request(`/invitations/accept/${t}`, form({ password: "password1", confirm: "password1" }));
  const pat = /beacon_session=([^;]*)/.exec(acc.headers.get("set-cookie") ?? "")![1];
  const r = await get(w, "/audit", pat);
  expect(r.status).toBe(403);
  const html = await r.text();
  expect(html).toContain("Access denied");
  expect(html).toContain("See everyone&#39;s audit events");
  expect(html).toContain("See my own audit events");
  expect((await post(w, "/audit/retention", pat, { on: "true" })).status).toBe(403);
}, 60000);

test("SPEC.md Audit Trail: the page shows the events newest first with number, time, action, target, actor and payload, says whose events they are, and has the filters and the switch", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  await get(w, "/audit", anya);
  const r = await get(w, "/audit", anya);
  expect(r.status).toBe(200);
  const html = await r.text();
  for (const h of ["<th>#</th>", "<th>Time</th>", "<th>Action</th>", "<th>Target</th>", "<th>Actor</th>", "<th>Payload</th>"]) expect(html).toContain(h);
  expect(html).toContain("Everyone's events.");
  expect(html).toContain("login_succeeded");
  expect(html).toContain("beacon.audit_viewed");
  expect(html).toContain("Dr. Anya Okonkwo");
  expect(html).not.toContain(anya);                                                                                     // the cookie's value, which Login's event holds, is nowhere on the page
  expect(html).toContain("[withheld]");
  expect(html).toContain('name="action"');
  expect(html).toContain('name="from"');
  expect(html).toContain('name="to"');
  expect(html).not.toContain("<script");
  const nums = [...html.matchAll(/<tr><td>(\d+)<\/td>/g)].map((m) => Number(m[1]));
  expect(nums.length).toBeGreaterThan(1);
  expect(nums).toEqual([...nums].sort((a, b) => b - a));
}, 60000);

test("SPEC.md Audit Trail: the filters are read from the address; an action that matches nothing says so; a date that is not a date answers with the words and no table", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const some = await (await get(w, "/audit?action=login_succeeded", anya)).text();
  expect(some).toContain("login_succeeded</td>");
  expect(some).toContain('<option value="login_succeeded" selected>');
  const none = await (await get(w, "/audit?action=no.such", anya)).text();
  expect(none).toContain("No events match.");
  const bad = await get(w, "/audit?from=yesterday", anya);
  expect(bad.status).toBe(400);
  const html = await bad.text();
  expect(html).toContain(AUDIT_WORDS.date);
  expect(html).not.toContain("<table");
  expect((await get(w, "/audit?from=2026-09-05&to=2026-09-01", anya)).status).toBe(400);
}, 60000);

test("SPEC.md Audit Trail: the retention switch is a form that turns the window on and off, says which it is, and goes back to the page", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const off = await (await get(w, "/audit", anya)).text();
  expect(off).toContain("off, every event is shown");
  expect(off).toContain('name="on" value="true"');
  const r = await post(w, "/audit/retention", anya, { on: "true" });
  expect([r.status, r.headers.get("location")]).toEqual([302, "/audit"]);
  const on = await (await get(w, "/audit", anya)).text();
  expect(on).toContain("on, the last 2555 days");
  expect(on).toContain('name="on" value="false"');
  await post(w, "/audit/retention", anya, { on: "false" });
  expect(await w.b.audits.retentionOn()).toBe(false);
}, 60000);

test("SPEC.md Audit Trail: an event's target, actor and payload are written as text, never as markup", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  await get(w, "/audit?action=%3Cscript%3E1%3C/script%3E", anya);
  const html = await (await get(w, "/audit", anya)).text();
  expect(html).toContain("&lt;script&gt;1&lt;/script&gt;");
  expect(html).not.toContain("<script");
}, 60000);

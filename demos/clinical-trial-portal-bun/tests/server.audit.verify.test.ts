// Beacon's chain verification page and the export, one test for each thing SPEC.md says of them (The screens, Chain verification, Audit export).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon } from "../src/beacon.ts";
import { buildApp, COOKIE } from "../src/server.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `sv2_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  return { b, seam, app: buildApp(b) };
};
type W = Awaited<ReturnType<typeof world>>;
const form = (f: Record<string, string>) => ({ method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(f).toString() });
const signIn = async (w: W, email: string, password: string) => /beacon_session=([^;]*)/.exec((await w.app.request("/login", form({ email, password }))).headers.get("set-cookie") ?? "")?.[1] ?? "";
const get = (w: W, path: string, cookie?: string) => w.app.request(path, cookie ? { headers: { cookie: `${COOKIE}=${cookie}` } } : {});

test("SPEC.md Audit Trail: the page offers Verify chain and Export CSV; both are for a person with a session, and a person who holds neither audit permission is answered Access denied", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const html = await (await get(w, "/audit", anya)).text();
  expect(html).toContain('<a href="/audit/verify">Verify chain</a>');
  expect(html).toContain('<a href="/audit/export.csv">Export CSV</a>');
  for (const path of ["/audit/verify", "/audit/export.csv"]) expect((await get(w, path)).headers.get("location")).toBe("/login");
  const t = ((await w.b.invite((await w.b.signIn("anya@beacon.clinical", "demo-pi") as { session_token: string }).session_token, "p@q.r", "P", "r")) as { invitation_token: string }).invitation_token;
  const acc = await w.app.request(`/invitations/accept/${t}`, form({ password: "password1", confirm: "password1" }));
  const pat = /beacon_session=([^;]*)/.exec(acc.headers.get("set-cookie") ?? "")![1];
  for (const path of ["/audit/verify", "/audit/export.csv"]) expect((await get(w, path, pat)).status).toBe(403);
}, 90000);

test("SPEC.md Chain verification: an untouched trail answers \"Chain intact\" with the number of events checked", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const r = await get(w, "/audit/verify", anya);
  expect(r.status).toBe(200);
  const html = await r.text();
  expect(html).toContain("Chain intact.");
  expect(html).toMatch(/\d+ events? checked\./);
  expect(html).not.toContain("Tampering detected");
  expect(html).toContain('<a href="/audit">Back to the audit trail</a>');
}, 90000);

test("SPEC.md Chain verification: a changed event answers \"Tampering detected\" with the event and why, and says how many events before it were checked", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  await get(w, "/audit/verify", anya);
  await get(w, "/audit", anya);
  await get(w, "/audit", anya);
  await get(w, "/audit/verify", anya);
  const evs = (await w.b.log.read({ sequence: { from: 1 } })) as { event_id: string; sequence_number: number }[];
  const e = evs.at(-1)!;
  const row = (await store.read<Record<string, unknown>>(`SELECT * FROM events WHERE _id = $1`, [e.event_id]))[0];
  await store.commit([store.put("events", { ...row, seq: Number(row.seq), data: String(row.data).replace(/"action_ref":"[^"]*"/, '"action_ref":"forged.action"') } as never)]);
  const html = await (await get(w, "/audit/verify", anya)).text();
  expect(html).toContain("Tampering detected.");
  expect(html).toContain("seal-proof-invalid");
  expect(html).toMatch(/Event \d+ \(/);
  expect(html).toMatch(/\d+ events? before it were checked/);
  expect(html).not.toContain("Chain intact");
}, 90000);

test("SPEC.md Audit export: the file is a CSV named for the day, offered as a download, every event oldest first with the columns; exporting is itself an event", async () => {
  const w = await world();
  const anya = await signIn(w, "anya@beacon.clinical", "demo-pi");
  const r = await get(w, "/audit/export.csv", anya);
  expect(r.status).toBe(200);
  expect(r.headers.get("content-type")).toContain("text/csv");
  expect(r.headers.get("content-disposition")).toBe('attachment; filename="beacon-audit-2026-09-01.csv"');
  const lines = (await r.text()).split("\r\n").filter(Boolean);
  expect(lines[0]).toStartWith("number,time,action,target,actor");
  expect(lines.length).toBeGreaterThan(1);
  const html = await (await get(w, "/audit?action=beacon.audit_exported", anya)).text();
  expect(html).toContain("beacon.audit_exported</td>");
  expect(html).toContain("row_count");
}, 90000);

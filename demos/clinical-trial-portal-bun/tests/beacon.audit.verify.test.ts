// Beacon's chain verification and export (SPEC.md, The screens, Chain verification and Audit export; What each action writes).
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon } from "../src/beacon.ts";
import { type LoggedEvent } from "../src/event_log.ts";
import { csvCell, WITHHELD } from "../src/beacon_audit.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `bv_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  const sign = async (email: string, pw: string) => { const s = (await b.signIn(email, pw)) as { session_token: string; person: { actor_ref: string } }; return { token: s.session_token, ref: s.person.actor_ref, key: b.keyOf(s.session_token)! }; };
  const anya = await sign("anya@beacon.clinical", "demo-pi");
  let n = 0;
  const pat = async (name = "Pat Rivera", ...give: "view_own_audit"[]) => {
    const t = ((await b.invite(anya.token, `pat${++n}@beacon.clinical`, name, "coordinator")) as { invitation_token: string }).invitation_token;
    const a = (await b.acceptInvitation(t, "password1", "password1")) as { session_token: string; person: { actor_ref: string } };
    for (const g of give) await b.admin.issueGrant(a.person.actor_ref, g, anya.ref, anya.key);
    return { token: a.session_token, ref: a.person.actor_ref, key: b.keyOf(a.session_token)! };
  };
  const events = async () => (await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[];
  /** Change one stored event's payload where it lies: the way a tamper would. */
  const tamper = async (seq: number) => {
    const e = (await events()).find((x) => x.sequence_number === seq)!;
    const row = (await store.read<Record<string, unknown>>(`SELECT * FROM events WHERE _id = $1`, [e.event_id]))[0];
    await store.commit([store.put("events", { ...row, seq: Number(row.seq), data: String(row.data).replace(/"action_ref":"[^"]*"/, '"action_ref":"forged.action"') } as never)]);
    return e;
  };
  return { b, seam, anya, pat, events, tamper };
};

test("SPEC.md Chain verification: the unsealed events are sealed, each event the person may see is checked, and an untouched trail is intact with the number checked", async () => {
  const w = await world();
  expect(await w.b.audit.sealNow()).toHaveProperty("evidence_id");                                                  // sealing is wired: the first seal answers evidence
  await w.pat();
  const total = (await w.events()).length;
  const v = await w.b.audits.verifyChain(w.anya.ref, w.anya.key);
  expect(v).toEqual({ intact: true, checked: total, unsealed: 0 });
  expect(await w.b.audit.sealNow()).toEqual({ refused: "nothing-to-seal" });                                        // the pass sealed everything
  await w.pat("Sam Ng");
  const again = await w.b.audits.verifyChain(w.anya.ref, w.anya.key);                                               // a second slice, covering the new events
  expect(again).toMatchObject({ intact: true, unsealed: 0 });
  expect((again as { checked: number }).checked).toBeGreaterThan(total);
}, 90000);

test("SPEC.md Chain verification: an event changed where it is stored fails its slice's proof and the page names the first event that failed and why; the events before it were checked", async () => {
  const w = await world();
  await w.pat();
  await w.b.audits.verifyChain(w.anya.ref, w.anya.key);                                                             // sealed intact
  const firstSlice = (await w.events()).length;
  await w.pat("Sam Ng");
  await w.b.audits.verifyChain(w.anya.ref, w.anya.key);                                                             // a second slice, sealed intact
  const last = (await w.events()).at(-1)!.sequence_number;
  const hit = await w.tamper(last);
  const v = await w.b.audits.verifyChain(w.anya.ref, w.anya.key);
  expect(v).toMatchObject({ intact: false, reason: "seal-proof-invalid", checked: firstSlice });                    // the first slice's events were checked and held
  expect((v as { event: { number: number } }).event.number).toBe(firstSlice + 1);                                  // the failure is named at the first event of the slice that holds the changed one
  expect(hit.sequence_number).toBe(last);
}, 90000);

test("SPEC.md Chain verification: a person who holds only `view_own_audit` verifies the events that person may see; a person who holds neither is refused; verifying and sealing write no event", async () => {
  const w = await world();
  const own = await w.pat("Own Person", "view_own_audit");
  await w.b.audits.view(own.ref, own.key);
  const before = (await w.events()).length;
  const v = await w.b.audits.verifyChain(own.ref, own.key);
  expect(v).toMatchObject({ intact: true });
  expect((v as { checked: number }).checked).toBe(1);                                                               // the one opening that person made
  expect((await w.events()).length).toBe(before);
  const none = await w.pat("No Person");
  expect(await w.b.audits.verifyChain(none.ref, none.key)).toEqual({ refused: "access-denied", needs: ["view_audit", "view_own_audit"] });
  expect(await w.b.audits.verifyChain(w.anya.ref, "")).toEqual({ refused: "invalid-request" });
}, 90000);

test("SPEC.md Audit export: every event the person may see, oldest first, one line each with its columns, the file named for the day; exporting is itself an event that carries the row count and the scope", async () => {
  const w = await world();
  await w.pat();                                                                                                    // several events, so an order can show
  const before = (await w.events()).length;
  expect(before).toBeGreaterThan(3);
  const r = await w.b.audits.exportCsv(w.anya.ref, w.anya.key);
  expect(r).toHaveProperty("csv");
  const { filename, csv } = r as { filename: string; csv: string };
  expect(filename).toBe("beacon-audit-2026-09-01.csv");
  const lines = csv.split("\r\n");
  expect(lines.pop()).toBe("");
  expect(lines[0]).toBe("number,time,action,target,actor,actor reference,payload,event id,attestation id,sealed by");
  expect(lines.length - 1).toBe(before);
  const nums = lines.slice(1).map((l) => Number(l.split(",")[0]));
  expect(nums).toEqual([...nums].sort((a, b) => a - b));
  const e = (await w.events()).filter((x) => (x.data as { action_ref: string }).action_ref === "beacon.audit_exported");
  expect(e).toHaveLength(1);
  expect(e[0].data).toMatchObject({ actor_ref: w.anya.ref, data: { target: "audit", row_count: before, scope: "all" } });
}, 90000);

test("SPEC.md Audit export: an event not yet sealed says so, a sealed one names the seal that covers it, and the session token is withheld", async () => {
  const w = await world();
  const a = (await w.b.audits.exportCsv(w.anya.ref, w.anya.key)) as { csv: string };
  expect(a.csv).toContain(",unsealed\r\n");
  expect(a.csv).toContain(WITHHELD);
  expect(a.csv).not.toContain(w.anya.token);
  await w.b.audits.verifyChain(w.anya.ref, w.anya.key);
  const b = (await w.b.audits.exportCsv(w.anya.ref, w.anya.key)) as { csv: string };
  const sealedBy = b.csv.split("\r\n").slice(1).filter(Boolean).map((l) => l.split(",").at(-1)!);
  expect(sealedBy.filter((x) => x !== "unsealed").length).toBeGreaterThan(0);                                       // a seal's id, a uuid, names the cover
  expect(sealedBy.filter((x) => x !== "unsealed").every((x) => /^[0-9a-f-]{36}$/.test(x))).toBe(true);
  expect(sealedBy.filter((x) => x === "unsealed")).toEqual([]);                                                      // the pass sealed all of them, the first export's own event among them
}, 90000);

test("SPEC.md Audit export: a person who holds only `view_own_audit` exports only their own events; a person who holds neither is refused and no event is written", async () => {
  const w = await world();
  const own = await w.pat("Own Person", "view_own_audit");
  await w.b.audits.view(own.ref, own.key);
  const r = (await w.b.audits.exportCsv(own.ref, own.key)) as { csv: string };
  const rows = r.csv.split("\r\n").slice(1).filter(Boolean);
  expect(rows).toHaveLength(1);
  expect(rows[0]).toContain("beacon.audit_viewed");
  const none = await w.pat("No Person");
  const before = (await w.events()).length;
  expect(await w.b.audits.exportCsv(none.ref, none.key)).toEqual({ refused: "access-denied", needs: ["view_audit", "view_own_audit"] });
  expect((await w.events()).length).toBe(before);
}, 90000);

test("SPEC.md Audit export: a cell that would open as a formula is written inert, and a cell with a comma, a quote or a line break is quoted", async () => {
  expect(csvCell("=SUM(A1)")).toBe("'=SUM(A1)");
  for (const f of ["+1", "-1", "@x", "\tx"]) expect(csvCell(f)).toBe(`'${f}`);
  expect(csvCell("plain")).toBe("plain");
  expect(csvCell("a,b")).toBe('"a,b"');
  expect(csvCell('a,"b"')).toBe('"a,""b"""');
  expect(csvCell("a\nb")).toBe('"a\nb"');
  const w = await world();
  const p = await w.pat("=SUM(A1)", "view_own_audit");
  await w.b.audits.view(p.ref, p.key);                                                                               // an event made by a person whose name is a formula
  const r = (await w.b.audits.exportCsv(w.anya.ref, w.anya.key)) as { csv: string };
  expect(r.csv).toContain(",'=SUM(A1),");
  expect(r.csv).not.toContain(",=SUM(A1),");
}, 90000);

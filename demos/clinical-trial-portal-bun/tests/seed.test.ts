// What a render starts from, read against SPEC.md's own sentences (The data a render starts from; The permissions; The study, subjects and visits; What each action writes).
// The seed makes the two accounts, the seven permissions with their words, Anya's six and Jordan's one, the study and the retention setting, and nothing else.
import { test, expect, afterAll } from "bun:test";
import { readFileSync } from "node:fs";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { Beacon, SEED } from "../src/beacon.ts";
import { PERMISSIONS, STUDY, VISIT_KINDS } from "../src/beacon_domain.ts";
import { type LoggedEvent } from "../src/event_log.ts";

const store = new Store();
afterAll(() => store.close());
const SPEC = readFileSync(new URL("../SPEC.md", import.meta.url), "utf8");
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const prefix = `sd_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const b = await Beacon.open(store, { seam, prefix, argon: { memoryCost: 1024, timeCost: 1 }, scrypt: { N: 1024, r: 8, p: 1 } });
  await b.seed();
  return { b, seam };
};

test("SPEC.md The permissions: the seven permissions and the words every screen uses are the ones the table in SPEC.md names, in its order", () => {
  const table = [...SPEC.matchAll(/^\| `([a-z_]+)` \| ([^|]+) \|/gm)].map((m) => [m[1], m[2].trim()]);
  expect(table.length).toBe(7);
  expect(PERMISSIONS.map((p) => [p.code, p.words])).toEqual(table);
});

test("SPEC.md The data a render starts from, What the seeded people hold: the two accounts with the names and passwords the page shows, Anya's six and Jordan's one", async () => {
  const { b } = await world();
  const people = await b.people.list();
  expect(people.map((p) => [p.email, p.display_name]).sort()).toEqual(SEED.map((s) => [s.email, s.name]).sort());
  expect(SEED.map((s) => s.email)).toEqual(["anya@beacon.clinical", "jordan@beacon.clinical"]);
  for (const s of SEED) expect(await b.signIn(s.email, s.password)).toHaveProperty("session_token");
  const held = async (email: string) => b.domain.held((await b.people.byEmail(email))!.actor_ref);
  expect(await held("anya@beacon.clinical")).toEqual(["invite_actor", "grant_permission", "enroll_subject", "record_visit", "view_audit", "view_all_subjects"]);
  expect(await held("jordan@beacon.clinical")).toEqual(["view_audit"]);
  expect(SPEC).toContain("- Anya: `invite_actor`, `grant_permission`, `enroll_subject`, `record_visit`, `view_audit`, `view_all_subjects`.");
  expect(SPEC).toContain("- Jordan: `view_audit`.");
});

test("SPEC.md The data a render starts from: nothing else is made: seven grants and no reach, one study, no subject, no visit, no invitation, no event beyond the sign-ins, the retention switch off", async () => {
  const { b } = await world();
  const grants = await b.permissions.read();
  expect(grants).toHaveLength(7);
  expect(grants.every((g) => g.status === "active" && Object.keys(g).sort().join() === "action_scope,grant_id,granted_at,revoked_at,status,subject_ref")).toBe(true);   // the old reach, all or own, does not exist
  expect(new Set(grants.map((g) => `${g.subject_ref}:${g.action_scope}`)).size).toBe(7);                              // each held at most once
  const rows = async (t: string) => (await store.read<Record<string, unknown>>(`SELECT _id FROM ${t}`)).length;
  const px = (b as unknown as { people: { T: string } }).people.T.replace(/people$/, "");
  expect([await rows(`${px}studies`), await rows(`${px}subjects`), await rows(`${px}visits`), await rows(`${px}invitations`)]).toEqual([1, 0, 0, 0]);
  expect(await b.invitations.read()).toEqual([]);
  expect(await b.audits.retentionOn()).toBe(false);
  const events = (await b.log.read({ sequence: { from: 1 } })) as LoggedEvent[];
  expect(events.filter((e) => !(e.data as { action_ref: string }).action_ref.startsWith("login_"))).toEqual([]);          // the seed's grants write no event of their own
});

test("SPEC.md The study, subjects and visits: the one study is BCN-OX-201, the visit kinds are the five SPEC names, and the first subject's code is BCN-001", async () => {
  const { b } = await world();
  expect(STUDY.code).toBe("BCN-OX-201");
  expect(SPEC).toContain("`BCN-OX-201`");
  expect([...VISIT_KINDS]).toEqual(["screening", "week 4", "week 12", "week 24", "end of study"]);
  expect(SPEC).toContain("`screening`, `week 4`, `week 12`, `week 24`, `end of study`");
  const anya = (await b.people.byEmail("anya@beacon.clinical"))!.actor_ref;
  expect(await b.domain.nextSubjectCode(anya)).toBe("BCN-001");
});

test("SPEC.md The data a render starts from: running the seed again makes nothing twice", async () => {
  const { b } = await world();
  await b.seed();
  expect(await b.people.list()).toHaveLength(2);
  expect((await b.permissions.read()).length).toBe(7);
});

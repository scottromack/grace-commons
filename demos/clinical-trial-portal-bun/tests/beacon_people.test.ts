// Beacon's people and the keys they sign with, one test for each thing the module says.
import { test, expect, afterAll } from "bun:test";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { ActorIdentity } from "../src/actor_identity.ts";
import { People, SessionKeys, normalEmail } from "../src/beacon_people.ts";

const store = new Store();
afterAll(() => store.close());
const world = async () => {
  const seam = testSeam("2026-09-01T10:00:00.000Z");
  const tablePrefix = `pp_${crypto.randomUUID().replaceAll("-", "_")}_`;
  const people = await People.open(store, seam, { tablePrefix, scrypt: { N: 1024, r: 8, p: 1 } });
  return { seam, people, T: `${tablePrefix}people` };
};
const mk = (w: Awaited<ReturnType<typeof world>>, email = `p-${crypto.randomUUID()}@beacon.clinical`, password = "correct horse", name = "Ada") =>
  w.people.create({ party_id: `party-${crypto.randomUUID()}`, email, display_name: name, password });

test("create: a person has an actor reference, the party, a normalized email and a display name, and a public key; nothing in the record is the private key", async () => {
  const w = await world();
  const r = await mk(w, "  Anya@Beacon.Clinical ", "demo-pi", "  Dr. Anya Okonkwo ") as { actor_ref: string };
  expect(r.actor_ref).toBeDefined();
  const p = (await w.people.byActor(r.actor_ref))!;
  expect(p).toMatchObject({ actor_ref: r.actor_ref, email: "anya@beacon.clinical", display_name: "Dr. Anya Okonkwo", created_at: "2026-09-01T10:00:00.000Z" });
  const row = (await store.read<Record<string, string>>(`SELECT * FROM ${w.T} WHERE _id = $1`, [r.actor_ref]))[0];
  const key = (await w.people.unlock(r.actor_ref, "demo-pi"))!;
  expect(JSON.stringify(row)).not.toContain(key);                                                                   // the key is kept sealed
  expect(JSON.stringify(row)).not.toContain("demo-pi");
  expect(normalEmail(" X@Y.Z ")).toBe("x@y.z");
});

test("unlock: the password opens the key, a wrong one does not, and the key signs through Actor Identity as the person (the registry answers the public half)", async () => {
  const w = await world();
  const { actor_ref } = await mk(w, undefined, "demo-pi") as { actor_ref: string };
  expect(await w.people.unlock(actor_ref, "wrong")).toBeNull();
  expect(await w.people.unlock(actor_ref, "")).toBeNull();
  expect(await w.people.unlock("no-such-actor", "demo-pi")).toBeNull();
  const key = (await w.people.unlock(actor_ref, "demo-pi"))!;
  const ai = await ActorIdentity.open(store, w.seam, w.people.registry);
  expect(await ai.attest("grant-proposal", actor_ref, key)).toHaveProperty("attestation_id");                      // the person attests with the unlocked key
  expect(await ai.attest("grant-proposal", actor_ref, (await mk(w).then(async (o) => w.people.unlock((o as { actor_ref: string }).actor_ref, "correct horse")))!)).toEqual({ refused: "invalid-credential" });   // another person's key is not this person's
});

test("unlock: a password is read in its normalized form, so a composed and a decomposed character open the same key", async () => {
  const w = await world();
  const { actor_ref } = await mk(w, undefined, "café-pass") as { actor_ref: string };
  expect(await w.people.unlock(actor_ref, "café-pass")).not.toBeNull();
});

test("sealing: two people with one password hold different sealed keys (a salt each), and a tampered seal opens for no password", async () => {
  const w = await world();
  const a = (await mk(w, undefined, "same password")) as { actor_ref: string };
  const b = (await mk(w, undefined, "same password")) as { actor_ref: string };
  const sealed = async (id: string) => JSON.parse((await store.read<{ sealed_key: string }>(`SELECT sealed_key FROM ${w.T} WHERE _id = $1`, [id]))[0].sealed_key) as { salt: string; ct: string; iv: string };
  const [sa, sb] = [await sealed(a.actor_ref), await sealed(b.actor_ref)];
  expect(sa.salt).not.toBe(sb.salt);
  expect(sa.ct).not.toBe(sb.ct);
  const tampered = JSON.stringify({ ...sa, ct: Buffer.from(sa.ct, "base64").map((x, i) => (i === 0 ? x ^ 1 : x)).toString("base64") });
  await store.commit([{ text: `UPDATE ${w.T} SET sealed_key = $1 WHERE _id = $2`, params: [JSON.stringify({ ...JSON.parse((await store.read<{ sealed_key: string }>(`SELECT sealed_key FROM ${w.T} WHERE _id = $1`, [a.actor_ref]))[0].sealed_key), ct: JSON.parse(tampered).ct }), a.actor_ref] }]);
  expect(await w.people.unlock(a.actor_ref, "same password")).toBeNull();
});

test("registry: the public material of a known person, and unknown-actor for none", async () => {
  const w = await world();
  const { actor_ref } = await mk(w) as { actor_ref: string };
  const r = await w.people.registry(actor_ref);
  expect(r).toMatchObject({ answer: "material" });
  expect((r as { current: string }).current.length).toBeGreaterThan(40);
  expect(await w.people.registry("nobody")).toEqual({ answer: "unknown-actor" });
});

test("create: one person to an email in any case; a blank input or an empty password is invalid-request; nothing second is written", async () => {
  const w = await world();
  expect(await mk(w, "Jordan@Beacon.Clinical")).toHaveProperty("actor_ref");
  expect(await mk(w, " jordan@beacon.CLINICAL ")).toEqual({ refused: "email-taken" });
  expect(await w.people.list()).toHaveLength(1);
  for (const bad of [{ party_id: " ", email: "a@b.c", display_name: "n", password: "p" }, { party_id: "x", email: "", display_name: "n", password: "p" }, { party_id: "x", email: "a@b.c", display_name: " ", password: "p" }, { party_id: "x", email: "a@b.c", display_name: "n", password: "" }])
    expect(await w.people.create(bad)).toEqual({ refused: "invalid-request" });
  expect(await w.people.list()).toHaveLength(1);
});

test("byEmail, byActor, byParty, list: each person once, found by any of the three, listed oldest first", async () => {
  const w = await world();
  const a = await w.people.create({ party_id: "party-a", email: "a@x.y", display_name: "A", password: "p" }) as { actor_ref: string };
  w.seam.advance(1000);
  const b = await w.people.create({ party_id: "party-b", email: "b@x.y", display_name: "B", password: "p" }) as { actor_ref: string };
  expect((await w.people.byEmail(" A@X.Y "))!.actor_ref).toBe(a.actor_ref);
  expect((await w.people.byParty("party-b"))!.actor_ref).toBe(b.actor_ref);
  expect((await w.people.byActor(b.actor_ref))!.email).toBe("b@x.y");
  expect(await w.people.byEmail("c@x.y")).toBeNull();
  expect(await w.people.byEmail(" ")).toBeNull();
  expect(await w.people.byParty("party-zzz")).toBeNull();
  expect((await w.people.list()).map((p) => p.display_name)).toEqual(["A", "B"]);
});

test("SessionKeys: a key is held for its session's time and no longer, and dropped at sign-out", async () => {
  let now = 1000;
  const k = new SessionKeys(() => now);
  k.hold("s1", "key-1", 5000);
  k.hold("s2", "key-2", 9000);
  expect(k.get("s1")).toBe("key-1");
  expect(k.get("nope")).toBeNull();
  now = 5000;
  expect(k.get("s1")).toBeNull();                                                                                   // the session's time has come
  expect(k.get("s2")).toBe("key-2");
  expect(k.size).toBe(1);
  k.drop("s2");
  expect(k.get("s2")).toBeNull();
  expect(k.size).toBe(0);
});

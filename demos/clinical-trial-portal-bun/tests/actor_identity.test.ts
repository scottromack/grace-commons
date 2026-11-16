// Actor Identity, one test for each rule the render answers, named by the rule's label.
import { test, expect, afterAll } from "bun:test";
import { generateKeyPairSync } from "node:crypto";
import { Store } from "../src/store.ts";
import { testSeam } from "../src/seam.ts";
import { ActorIdentity, ed25519, type Registry, type RegistryAnswer, type Mechanism } from "../src/actor_identity.ts";

const store = new Store();
afterAll(() => store.close());

const keys = () => {
  const { publicKey, privateKey } = generateKeyPairSync("ed25519");
  return { pub: publicKey.export({ format: "der", type: "spki" }).toString("base64"), priv: privateKey.export({ format: "der", type: "pkcs8" }).toString("base64") };
};
// An actor registry the test moves: material for the known, unknown-actor for the rest, or unreachable.
const world = async (mech: Mechanism = ed25519) => {
  const seam = testSeam("2026-03-01T09:00:00.000Z");
  const book = new Map<string, RegistryAnswer>();
  let down = false;
  const registry: Registry = (ref) => (down ? { answer: "unreachable" } : book.get(ref) ?? { answer: "unknown-actor" });
  const ai = await ActorIdentity.open(store, seam, registry, mech);
  const enrol = (ref = `actor-${crypto.randomUUID()}`) => { const k = keys(); book.set(ref, { answer: "material", current: k.pub }); return { ref, ...k }; };
  return { seam, ai, book, enrol, outage: (v: boolean) => { down = v; } };
};

test("Operation 1 to 5, State 3, 4, Invariant 2.1, 3.1: an attest records one attestation with proof and instant, stores no credential, and its proof verifies", async () => {
  const { ai, enrol } = await world();
  const a = enrol();
  const r = await ai.attest("wire-w91", a.ref, a.priv) as { attestation_id: string };
  const rows = (await ai.read()).filter((x) => x.attestation_id === r.attestation_id);
  expect(rows).toHaveLength(1);
  expect([rows[0].action_ref, rows[0].actor_ref, rows[0].attested_at]).toEqual(["wire-w91", a.ref, "2026-03-01T09:00:00.000Z"]);
  expect(JSON.stringify(await store.history("attestations", r.attestation_id))).not.toContain(a.priv);
  expect(await ai.verify(r.attestation_id)).toBe("verified");
});

test("Operation 6 to 8, 37: a blank action reference, actor reference or credential, or a string over the cap, is invalid-request", async () => {
  const { ai, enrol } = await world();
  const a = enrol();
  expect(await ai.attest(" ", a.ref, a.priv)).toEqual({ refused: "invalid-request" });
  expect(await ai.attest("act-1", "", a.priv)).toEqual({ refused: "invalid-request" });
  expect(await ai.attest("act-1", a.ref, "")).toEqual({ refused: "invalid-request" });
  expect(await ai.attest("x".repeat(4097), a.ref, a.priv)).toEqual({ refused: "invalid-request" });
});

test("Operation 31, 9, 36: an unknown actor, a credential that fails the current material, and a revoked credential are invalid-credential; none records", async () => {
  const revoked = new Set<string>();
  const { ai, enrol } = await world({ ...ed25519, revoked: (ref) => revoked.has(ref) });
  const before = (await ai.read()).length;
  const a = enrol(), b = enrol(), c = enrol();
  expect(await ai.attest("act-1", `nobody-${crypto.randomUUID()}`, a.priv)).toEqual({ refused: "invalid-credential" });
  expect(await ai.attest("act-1", a.ref, b.priv)).toEqual({ refused: "invalid-credential" });
  expect(await ai.attest("act-1", a.ref, "not-a-key")).toEqual({ refused: "invalid-credential" });
  revoked.add(c.ref);
  expect(await ai.attest("act-1", c.ref, c.priv)).toEqual({ refused: "invalid-credential" });
  expect((await ai.read()).length).toBe(before);
});

test("Operation 33, 40: an unreachable registry is registry-unavailable; a mechanism that supplies no credential check is mechanism-unavailable", async () => {
  const w = await world();
  const a = w.enrol();
  w.outage(true);
  expect(await w.ai.attest("act-1", a.ref, a.priv)).toEqual({ refused: "registry-unavailable" });
  const noMech = await world({ ...ed25519, credentialCheck: () => "unavailable" });
  const b = noMech.enrol();
  expect(await noMech.ai.attest("act-1", b.ref, b.priv)).toEqual({ refused: "mechanism-unavailable" });
});

test("Operation 15, 16, 17, 41: verify answers not-known, actor-unknown-in-registry, registry-unavailable and mechanism-unavailable each as its own", async () => {
  const w = await world();
  const a = w.enrol();
  const { attestation_id } = await w.ai.attest("act-1", a.ref, a.priv) as { attestation_id: string };
  expect(await w.ai.verify("no-such-attestation")).toBe("not-known");
  w.book.delete(a.ref);
  expect(await w.ai.verify(attestation_id)).toEqual({ failed: "actor-unknown-in-registry" });
  w.book.set(a.ref, { answer: "material", current: a.pub });
  w.outage(true);
  expect(await w.ai.verify(attestation_id)).toEqual({ failed: "registry-unavailable" });
  w.outage(false);
  const none = await world({ ...ed25519, proofCheck: () => "unavailable" });
  const b = none.enrol();
  const r = await none.ai.attest("act-1", b.ref, b.priv) as { attestation_id: string };
  expect(await none.ai.verify(r.attestation_id)).toEqual({ failed: "mechanism-unavailable" });
});

test("Operation 18, Invariant 2.2, 3.2: a proof does not verify for another action or another actor; a tampered attestation record is proof-invalid", async () => {
  const w = await world();
  const a = w.enrol(), b = w.enrol();
  const { attestation_id } = await w.ai.attest("act-1", a.ref, a.priv) as { attestation_id: string };
  // the proof made for act-1 by a is checked against act-2, and against b, by the mechanism itself
  const rows = await w.ai.read();
  const proof = rows.find((r) => r.attestation_id === attestation_id)!.proof;
  expect(ed25519.proofCheck(proof, "act-2", a.ref, [a.pub])).toBe("failed");
  expect(ed25519.proofCheck(proof, "act-1", b.ref, [b.pub])).toBe("failed");
  expect(ed25519.proofCheck(proof, "act-1", a.ref, [b.pub])).toBe("failed");
  // someone rewrites the stored action reference: the proof no longer holds
  await store.commit([store.put("attestations", { _id: attestation_id, action_ref: "act-FORGED", actor_ref: a.ref, proof, attested_at: "2026-03-01T09:00:00.000Z" })]);
  expect(await w.ai.verify(attestation_id)).toEqual({ failed: "proof-invalid" });
});

test("Term proof check, Operation 21: a proof verifies under any one material the registry holds, the current or an earlier one; a revocation status turns it proof-invalid", async () => {
  const revoked = new Set<string>();
  const w = await world({ ...ed25519, revoked: (ref) => revoked.has(ref) });
  const a = w.enrol();
  const { attestation_id } = await w.ai.attest("act-1", a.ref, a.priv) as { attestation_id: string };
  const rotated = keys();
  w.book.set(a.ref, { answer: "material", current: rotated.pub });                                    // the key rotated
  expect(await w.ai.verify(attestation_id)).toEqual({ failed: "proof-invalid" });                     // history not kept
  w.book.set(a.ref, { answer: "material", current: rotated.pub, historical: [a.pub] });               // the registry keeps it
  expect(await w.ai.verify(attestation_id)).toBe("verified");
  revoked.add(a.ref);
  expect(await w.ai.verify(attestation_id)).toEqual({ failed: "proof-invalid" });
});

test("Invariant 1.1, 5.1, 9.1, Operation 20, 29: an attestation is one version; two attests carry two ids; verify and read write nothing", async () => {
  const { ai, enrol } = await world();
  const a = enrol();
  const x = await ai.attest("act-1", a.ref, a.priv) as { attestation_id: string };
  const y = await ai.attest("act-1", a.ref, a.priv) as { attestation_id: string };
  expect(x.attestation_id).not.toBe(y.attestation_id);
  await ai.verify(x.attestation_id); await ai.read();
  expect(await store.history("attestations", x.attestation_id)).toHaveLength(1);
});

test("Database 1: an attestation planned beside another write of one action lands with it", async () => {
  const { ai, enrol } = await world();
  const a = enrol();
  const p = await ai.plan("act-9", a.ref, a.priv);
  if ("refused" in p) throw new Error(p.refused);
  await store.commit(p.stmts);
  expect(await ai.verify(p.attestation_id)).toBe("verified");
});

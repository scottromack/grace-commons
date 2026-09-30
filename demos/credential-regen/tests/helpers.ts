import { generateKeyPairSync, sign } from "node:crypto";
import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { REGISTRY } from "../src/registry.ts";
import { type Config, Credential } from "../src/credential.ts";

export const DAY = 86_400_000;
export const CONFIG: Config = { defaultValidityMs: 90 * DAY, lengthBound: 64, leaseMs: 5_000 };

export function world(cfg: Partial<Config> = {}) {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  return { db, seam, f, c: new Credential(db, seam, f, REGISTRY, { ...CONFIG, ...cfg }) };
}

// A key pair and a signed challenge, as a composing pattern would hand them over (Non-goal 30).
export function keys() {
  const { publicKey, privateKey } = generateKeyPairSync("ed25519");
  const pem = publicKey.export({ type: "spki", format: "pem" }).toString();
  const signed = (challenge: string) => JSON.stringify({ challenge, signature: sign(null, Buffer.from(challenge), privateKey).toString("base64") });
  return { pem, signed };
}

export function ok<T>(r: { ok: T } | { refused: unknown }): T {
  if (!("ok" in r)) throw new Error(JSON.stringify(r));
  return r.ok;
}

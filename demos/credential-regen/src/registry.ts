// The deployment's derivation registry (Capability requirement 3 through 6, 18
// through 20): per credential type a one-way derivation function and a check
// function. Both run at the seam, outside the transition: they are
// cryptography (Execution Contract Logic confinement 1). A function that
// cannot process its input refuses (Operation 66 through 68).
import { createHash, createPublicKey, scryptSync, timingSafeEqual, verify as sigVerify } from "node:crypto";

export type Derive = (material: string, salt: Uint8Array) => string | "refused";
export type Check = (presented: string, verifier: string) => "match" | "no-match" | "refused";
export interface Registry { [type: string]: { derive: Derive; check: Check } }

const hex = (b: Uint8Array) => Buffer.from(b).toString("hex");
const eq = (a: string, b: string) => {
  const x = Buffer.from(a), y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y); // Operation 24
};

export const REGISTRY: Registry = {
  // A salted, costed hash: the check re-derives under the salt the verifier carries.
  password: {
    derive: (m, salt) => `scrypt$${hex(salt)}$${scryptSync(m, salt, 32, { N: 1024 }).toString("hex")}`,
    check: (p, v) => {
      const [, salt, hash] = v.split("$");
      return eq(scryptSync(p, Buffer.from(salt, "hex"), 32, { N: 1024 }).toString("hex"), hash) ? "match" : "no-match";
    },
  },
  // An unsalted hash of a high-entropy token.
  "api-token": {
    derive: (m) => createHash("sha256").update(m).digest("hex"),
    check: (p, v) => eq(createHash("sha256").update(p).digest("hex"), v) ? "match" : "no-match",
  },
  // A public key: the verifier is the key; the presented material is a signed challenge.
  "public-key": {
    derive: (m) => { try { return createPublicKey(m).export({ type: "spki", format: "pem" }).toString(); } catch { return "refused"; } },
    check: (p, v) => {
      let msg: { challenge: string; signature: string };
      try { msg = JSON.parse(p); } catch { return "refused"; }
      if (typeof msg?.challenge !== "string" || typeof msg?.signature !== "string") return "refused";
      return sigVerify(null, Buffer.from(msg.challenge), createPublicKey(v), Buffer.from(msg.signature, "base64")) ? "match" : "no-match";
    },
  },
};

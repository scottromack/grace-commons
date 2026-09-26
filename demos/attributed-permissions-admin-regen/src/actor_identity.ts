// Actor Identity, as much of the atom as this composition reaches: attest,
// verify, and the enumeration Composes 20 relies on. The credential mechanism
// is an HMAC over the action reference and the actor reference under the
// actor's registered secret; a credential validates when it is that secret.
import type { Database } from "@db/sqlite";
import { createHmac } from "node:crypto";
import type { Faults } from "./store.ts";

export type AttestAnswer =
  | { ok: string }
  | { refused: "invalid-request" | "invalid-credential" | "storage-failure" };

export type VerifyAnswer =
  | "verified"
  | { "failed-verification": "proof-invalid" | "actor-unknown-in-registry" | "registry-unavailable" }
  | "not-known";

const blank = (s: string) => s.trim() === "";
const proofOf = (secret: string, action: string, actor: string) =>
  createHmac("sha256", secret).update(`${action}\n${actor}`).digest("hex");

export function register(db: Database, actor_ref: string, secret: string) {
  db.prepare("INSERT INTO actor (actor_ref, secret) VALUES (?, ?)").run(actor_ref, secret);
}

export function attest(
  db: Database, seam: { now(): string; attestationId(): string }, faults: Faults,
  action_ref: string, actor_ref: string, credential: string,
): AttestAnswer {
  if (blank(action_ref) || blank(actor_ref) || blank(credential)) return { refused: "invalid-request" };
  const row = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(actor_ref);
  if (!row || row.secret !== credential) return { refused: "invalid-credential" };
  if (faults.attestStorage) return { refused: "storage-failure" };
  const id = seam.attestationId();
  db.prepare("INSERT INTO attestation VALUES (?, ?, ?, ?, ?)")
    .run(id, action_ref, actor_ref, proofOf(credential, action_ref, actor_ref), seam.now());
  return { ok: id };
}

export function verify(db: Database, attestation_id: string, registryUp = true): VerifyAnswer {
  const a = db.prepare("SELECT action_ref, actor_ref, proof FROM attestation WHERE attestation_id = ?")
    .get<{ action_ref: string; actor_ref: string; proof: string }>(attestation_id);
  if (!a) return "not-known";
  if (!registryUp) return { "failed-verification": "registry-unavailable" };
  const r = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(a.actor_ref);
  if (!r) return { "failed-verification": "actor-unknown-in-registry" };
  return proofOf(r.secret, a.action_ref, a.actor_ref) === a.proof ? "verified" : { "failed-verification": "proof-invalid" };
}

// The enumeration Composes 20 and Housekeeping 2 require. Actor Identity's
// signature block declares no such read; see CORNERS.md.
export function enumerate(db: Database): { attestation_id: string; action_ref: string; attested_at: string }[] {
  return db.prepare("SELECT attestation_id, action_ref, attested_at FROM attestation ORDER BY attested_at").all();
}

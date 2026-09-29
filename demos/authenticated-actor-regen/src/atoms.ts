// Credential and Actor Identity, as much of each as Authenticated Actor reaches.
// Carried from the Login regeneration (Credential) and the atoms Audit Trail
// reaches there (Actor Identity); Credential's register gains its storage-failure
// arm, which Login never reached. Rule numbers are each atom's own. Each reads
// the host clock once per call at its own seam.
import type { Database } from "@db/sqlite";
import { createHash, createHmac, timingSafeEqual } from "node:crypto";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
type R<T, E extends string> = { ok: T } | { refused: E };

// ---- Credential ----
// The derivation registry: one one-way function per credential type (Term derivation registry).
const DERIVATIONS: Record<string, (m: string) => string> = {
  password: (m) => createHash("sha256").update(`pw\n${m}`).digest("hex"),
  fido2: (m) => createHash("sha256").update(`fido2\n${m}`).digest("hex"),
};
export interface CredentialRecord {
  credential_id: string; principal_ref: string; credential_type: string; verifier: string; registered_at: string;
  expires_at: string | null; status: "active" | "rotated" | "revoked"; successor_id: string | null; ended_at: string | null;
}
const live = (c: CredentialRecord, now: string) => c.status === "active" && (c.expires_at === null || c.expires_at > now);  // Term live
export const credential = {
  // Operation 1 through 17.
  register(db: Database, seam: Seam, f: Faults, principal_ref: string, credential_type: string, material: string, expires_at?: string):
    R<string, "invalid-request" | "duplicate-active-credential" | "storage-failure"> {
    const now = seam.now();
    if (blank(principal_ref) || blank(material) || blank(credential_type) || !DERIVATIONS[credential_type]) return { refused: "invalid-request" };
    if (expires_at !== undefined && !(now < expires_at)) return { refused: "invalid-request" };
    if (credential.effectiveActive(db, principal_ref, credential_type, now)) return { refused: "duplicate-active-credential" };
    if (f.hit("credential.register")) return { refused: "storage-failure" };
    const id = seam.id("credential");
    db.prepare("INSERT INTO credential VALUES (?, ?, ?, ?, ?, ?, 'active', NULL, NULL, NULL, NULL)")
      .run(id, principal_ref, credential_type, DERIVATIONS[credential_type](material), now, expires_at ?? null);
    return { ok: id };
  },
  // Operation 18 through 26: window first, then a constant-time comparison.
  verify(db: Database, seam: Seam, principal_ref: string, credential_type: string, presented: string):
    "verified" | { "failed-verification": "material-mismatch" | "no-active-credential" } {
    const c = credential.effectiveActive(db, principal_ref, credential_type, seam.now());
    if (!c) return { "failed-verification": "no-active-credential" };
    const a = Buffer.from(DERIVATIONS[credential_type](presented), "hex"), b = Buffer.from(c.verifier, "hex");
    return a.length === b.length && timingSafeEqual(a, b) ? "verified" : { "failed-verification": "material-mismatch" };
  },
  // Operation 35 through 41.
  rotate(db: Database, seam: Seam, credential_id: string, material: string): { ok: string } | { refused: string } {
    const now = seam.now();
    const c = db.prepare("SELECT * FROM credential WHERE credential_id = ?").get<CredentialRecord>(credential_id);
    if (!c) return { refused: "not-known" };
    if (!live(c, now)) return { refused: "not-active" };
    if (blank(material)) return { refused: "invalid-request" };
    const id = seam.id("credential");
    db.exec("BEGIN");
    db.prepare("INSERT INTO credential VALUES (?, ?, ?, ?, ?, ?, 'active', NULL, NULL, NULL, NULL)")
      .run(id, c.principal_ref, c.credential_type, DERIVATIONS[c.credential_type](material), now, c.expires_at);
    db.prepare("UPDATE credential SET status='rotated', successor_id=?, ended_at=? WHERE credential_id=?").run(id, now, credential_id);
    db.exec("COMMIT");
    return { ok: id };
  },
  // Operation 42 and 43.
  revoke(db: Database, seam: Seam, credential_id: string, by: string, reason: string): { ok: "revoked" } | { refused: string } {
    const now = seam.now();
    const c = db.prepare("SELECT * FROM credential WHERE credential_id = ?").get<CredentialRecord>(credential_id);
    if (!c) return { refused: "not-known" };
    if (!live(c, now)) return { refused: "already-terminal" };
    if (blank(by) || blank(reason)) return { refused: "invalid-request" };
    db.prepare("UPDATE credential SET status='revoked', ended_at=?, revoked_by_ref=?, revocation_reason=? WHERE credential_id=?").run(now, by, reason, credential_id);
    return { ok: "revoked" };
  },
  // Operation 51 through 55: the matching credentials with their effective status, never the verifier.
  read(db: Database, seam: Seam, filter: { principal_ref?: string; credential_type?: string; credential_id?: string }) {
    const now = seam.now();
    return db.prepare("SELECT * FROM credential ORDER BY registered_at, credential_id").all<CredentialRecord>()
      .filter((c) => Object.entries(filter).every(([k, v]) => (c as unknown as Record<string, unknown>)[k] === v))
      .map(({ verifier: _v, ...c }) => ({ ...c, effective_status: c.status === "active" && !live(c as CredentialRecord, now) ? "expired" : c.status }));
  },
  effectiveActive(db: Database, principal_ref: string, credential_type: string, now: string): CredentialRecord | undefined {
    return db.prepare("SELECT * FROM credential WHERE principal_ref = ? AND credential_type = ? AND status = 'active'")
      .all<CredentialRecord>(principal_ref, credential_type).find((c) => live(c, now));
  },
};

// ---- Actor Identity ----
const proofOf = (secret: string, action: string, actor: string) =>
  createHmac("sha256", secret).update(`${action}\n${actor}`).digest("hex");
export const actorIdentity = {
  register(db: Database, actor_ref: string, secret: string) {
    db.prepare("INSERT INTO actor VALUES (?, ?)").run(actor_ref, secret);
  },
  retire(db: Database, actor_ref: string) { db.prepare("DELETE FROM actor WHERE actor_ref = ?").run(actor_ref); },
  // Operation 1 through 13.
  attest(db: Database, seam: Seam, f: Faults, action_ref: string, actor_ref: string, credential: string):
    R<string, "invalid-request" | "invalid-credential" | "storage-failure"> {
    if (blank(action_ref) || blank(actor_ref) || blank(credential)) return { refused: "invalid-request" };
    const a = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(actor_ref);
    if (!a || a.secret !== credential) return { refused: "invalid-credential" };
    if (f.hit("identity.attest")) return { refused: "storage-failure" };
    const id = seam.id("attestation");
    db.prepare("INSERT INTO attestation VALUES (?, ?, ?, ?, ?)").run(id, action_ref, actor_ref, proofOf(credential, action_ref, actor_ref), seam.now());
    return { ok: id };
  },
  // Operation 14 through 21.
  verify(db: Database, attestation_id: string): "verified" | { "failed-verification": string } | "not-known" {
    const a = db.prepare("SELECT * FROM attestation WHERE attestation_id = ?").get<{ action_ref: string; actor_ref: string; proof: string }>(attestation_id);
    if (!a) return "not-known";
    const r = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(a.actor_ref);
    if (!r) return { "failed-verification": "actor-unknown-in-registry" };
    return proofOf(r.secret, a.action_ref, a.actor_ref) === a.proof ? "verified" : { "failed-verification": "proof-invalid" };
  },
  // Operation 27 through 30.
  read(db: Database) {
    return db.prepare("SELECT * FROM attestation ORDER BY attested_at, attestation_id")
      .all<{ attestation_id: string; action_ref: string; actor_ref: string; proof: string; attested_at: string }>();
  },
};

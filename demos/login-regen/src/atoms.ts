// Credential and Session, as much of each as Login and its tests reach. Rule
// numbers are each atom's own. Each reads the host clock once per call.
import type { Database } from "@db/sqlite";
import { createHash, timingSafeEqual } from "node:crypto";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";

// ---- Credential ----
// The derivation registry: one one-way function per credential type (Term derivation registry).
const DERIVATIONS: Record<string, (m: string) => string> = {
  password: (m) => createHash("sha256").update(`pw\n${m}`).digest("hex"),
};
export interface CredentialRecord {
  credential_id: string; principal_ref: string; credential_type: string; verifier: string; registered_at: string;
  expires_at: string | null; status: "active" | "rotated" | "revoked"; successor_id: string | null; ended_at: string | null;
}
const live = (c: CredentialRecord, now: string) => c.status === "active" && (c.expires_at === null || c.expires_at > now);  // Term live
export const credential = {
  // Operation 1 through 17; the deployment's surface, never Login's (Composes 8).
  register(db: Database, seam: Seam, principal_ref: string, credential_type: string, material: string, expires_at?: string):
    { ok: string } | { refused: "invalid-request" | "duplicate-active-credential" } {
    const now = seam.now();
    if (blank(principal_ref) || blank(material) || blank(credential_type) || !DERIVATIONS[credential_type]) return { refused: "invalid-request" };
    if (expires_at !== undefined && !(now < expires_at)) return { refused: "invalid-request" };
    if (credential.effectiveActive(db, principal_ref, credential_type, now)) return { refused: "duplicate-active-credential" };
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

// ---- Session ----
export interface SessionRecord {
  session_token: string; principal_ref: string; issued_by_ref: string; issued_at: string; expires_at: string;
  status: "active" | "revoked"; revoked_at: string | null; revoked_by_ref: string | null; revocation_reason: string | null;
}
export type Validation = { valid: { principal_ref: string; expires_at: string } } | { invalid: "expired" | "revoked" | "not-known" };
export const session = {
  // Operation 1 through 12 and 48.
  issue(db: Database, seam: Seam, f: Faults, principal_ref: string, issued_by_ref: string, durationMs: number | undefined, defaultMs: number | undefined):
    { ok: string } | { refused: "invalid-request" | "storage-failure" } {
    const now = seam.now();
    if (blank(principal_ref) || blank(issued_by_ref)) return { refused: "invalid-request" };
    const d = durationMs ?? defaultMs;
    if (d === undefined || !(d > 0)) return { refused: "invalid-request" };
    if (f.hit("session.issue", principal_ref)) return { refused: "storage-failure" };
    const token = seam.id("session");
    db.prepare("INSERT INTO session VALUES (?, ?, ?, ?, ?, 'active', NULL, NULL, NULL)")
      .run(token, principal_ref, issued_by_ref, now, new Date(Date.parse(now) + d).toISOString());
    return { ok: token };
  },
  // Operation 13 through 21.
  validate(db: Database, seam: Seam, token: string): Validation {
    const s = db.prepare("SELECT * FROM session WHERE session_token = ?").get<SessionRecord>(token);
    if (!s) return { invalid: "not-known" };
    if (s.status === "revoked") return { invalid: "revoked" };
    if (!(seam.now() < s.expires_at)) return { invalid: "expired" };
    return { valid: { principal_ref: s.principal_ref, expires_at: s.expires_at } };
  },
  // Operation 22 through 36; a lapsed session is accepted (27).
  revoke(db: Database, seam: Seam, f: Faults, token: string, by: string, reason: string):
    { ok: "revoked" } | { refused: "not-known" | "already-terminal" | "invalid-request" | "storage-failure" } {
    const s = db.prepare("SELECT * FROM session WHERE session_token = ?").get<SessionRecord>(token);
    if (!s) return { refused: "not-known" };
    if (s.status === "revoked") return { refused: "already-terminal" };
    if (blank(by) || blank(reason)) return { refused: "invalid-request" };
    if (f.hit("session.revoke", token)) return { refused: "storage-failure" };
    db.prepare("UPDATE session SET status='revoked', revoked_at=?, revoked_by_ref=?, revocation_reason=? WHERE session_token=?").run(seam.now(), by, reason, token);
    return { ok: "revoked" };
  },
  // Operation 37 through 41.
  read(db: Database): SessionRecord[] {
    return db.prepare("SELECT * FROM session ORDER BY issued_at, session_token").all<SessionRecord>();
  },
};

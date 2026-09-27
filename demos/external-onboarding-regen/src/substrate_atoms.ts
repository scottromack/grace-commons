// The atoms Audit Trail reaches, as much of each as it reaches. Each reads
// the host clock once per call at its own seam. Rule numbers are each atom's own.
import type { Database } from "@db/sqlite";
import { createHmac } from "node:crypto";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
type R<T, E extends string> = { ok: T } | { refused: E };

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
    if (f.hit("identity.attest", action_ref)) return { refused: "storage-failure" };
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

// ---- Event Log ----
export interface LoggedEvent { seq: number; event_id: string; recorded_at: string; data: string | null }
export const eventLog = {
  append(db: Database, seam: Seam, f: Faults, data: string, cap: number, qualifier?: string): R<string, "invalid-payload" | "storage-failure"> {
    if (data.length > cap) return { refused: "invalid-payload" };
    if (f.hit("log.append", qualifier)) return { refused: "storage-failure" };
    const id = seam.id("event");
    db.prepare("INSERT INTO event (event_id, recorded_at, data) VALUES (?, ?, ?)").run(id, seam.now(), data);
    return { ok: id };
  },
  // Operation 13 through 17: a sequence-number range, rising; an open upper bound when to is absent.
  read(db: Database, from: number, to?: number): LoggedEvent[] {
    return to === undefined
      ? db.prepare("SELECT * FROM event WHERE seq >= ? ORDER BY seq").all<LoggedEvent>(from)
      : db.prepare("SELECT * FROM event WHERE seq >= ? AND seq <= ? ORDER BY seq").all<LoggedEvent>(from, to);
  },
};

// ---- Retention Window ----
export const retentionWindow = {
  place(db: Database, seam: Seam, f: Faults, record_ref: string, policy: { ref: string; durationMs: number; maxPurgeDelayMs: number }, qualifier?: string):
    R<string, "invalid-request" | "storage-failure"> {
    if (blank(record_ref) || blank(policy.ref)) return { refused: "invalid-request" };
    if (f.hit("retention.place", qualifier)) return { refused: "storage-failure" };
    const now = seam.now(), t = Date.parse(now), id = seam.id("retention");
    db.prepare("INSERT INTO retention VALUES (?, ?, ?, ?, ?, ?, 'retained', NULL)").run(id, record_ref, policy.ref, now,
      new Date(t + policy.durationMs).toISOString(), new Date(t + policy.durationMs + policy.maxPurgeDelayMs).toISOString());
    return { ok: id };
  },
  read(db: Database) {
    return db.prepare("SELECT * FROM retention").all<{ retention_id: string; record_ref: string; state: string; purged_at: string | null }>();
  },
};


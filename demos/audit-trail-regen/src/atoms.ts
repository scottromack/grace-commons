// The four constituent atoms, as far as Audit Trail reaches them. Rule numbers
// are each atom's own. Each reads the host clock once per call.
import type { Database } from "@db/sqlite";
import { createHash, createHmac } from "node:crypto";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { Vault } from "./vault.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
type R<T, E extends string> = { ok: T } | { refused: E };

// ---- Actor Identity ----
const proofOf = (secret: string, action: string, actor: string) => createHmac("sha256", secret).update(`${action}\n${actor}`).digest("hex");
export interface Attestation { attestation_id: string; action_ref: string; actor_ref: string; attested_at: string }
export const actorIdentity = {
  register(db: Database, actor_ref: string, secret: string) { db.prepare("INSERT INTO actor VALUES (?, ?)").run(actor_ref, secret); },
  retire(db: Database, actor_ref: string) { db.prepare("DELETE FROM actor WHERE actor_ref = ?").run(actor_ref); },
  attest(db: Database, seam: Seam, f: Faults, v: Vault, action_ref: string, actor_ref: string, credential: string):
    R<string, "invalid-request" | "invalid-credential" | "storage-failure"> {
    if (blank(action_ref) || blank(actor_ref) || blank(credential)) return { refused: "invalid-request" };
    const a = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(actor_ref);
    if (!a || a.secret !== credential) return { refused: "invalid-credential" };
    if (f.hit("identity.attest", action_ref)) return { refused: "storage-failure" };
    const id = seam.id("attestation");
    db.prepare("INSERT INTO attestation VALUES (?, ?, ?, ?, ?)").run(id, action_ref, actor_ref, v.seal(`att:${id}`, proofOf(credential, action_ref, actor_ref)), seam.now());
    return { ok: id };
  },
  verify(db: Database, v: Vault, attestation_id: string, registryUp = true):
    "verified" | { "failed-verification": "proof-invalid" | "actor-unknown-in-registry" | "registry-unavailable" } | "not-known" {
    const a = db.prepare("SELECT * FROM attestation WHERE attestation_id = ?").get<{ action_ref: string; actor_ref: string; proof: string }>(attestation_id);
    if (!a) return "not-known";
    if (!registryUp) return { "failed-verification": "registry-unavailable" };
    const r = db.prepare("SELECT secret FROM actor WHERE actor_ref = ?").get<{ secret: string }>(a.actor_ref);
    if (!r) return { "failed-verification": "actor-unknown-in-registry" };
    return v.open(`att:${attestation_id}`, a.proof) === proofOf(r.secret, a.action_ref, a.actor_ref) ? "verified" : { "failed-verification": "proof-invalid" };
  },
  // Operation 27 through 30; the composition reads only the surviving fields (Composes 7).
  read(db: Database): Attestation[] {
    return db.prepare("SELECT attestation_id, action_ref, actor_ref, attested_at FROM attestation ORDER BY attested_at, attestation_id").all<Attestation>();
  },
};

// ---- Event Log ----
export interface LoggedEvent { seq: number; event_id: string; recorded_at: string; data: string | null }
export const eventLog = {
  append(db: Database, seam: Seam, f: Faults, v: Vault, data: string, cap: number, qualifier?: string): R<string, "invalid-payload" | "storage-failure"> {
    if (new TextEncoder().encode(data).length > cap) return { refused: "invalid-payload" };
    if (f.hit("log.append", qualifier)) return { refused: "storage-failure" };
    const id = seam.id("event");
    db.prepare("INSERT INTO event (event_id, recorded_at, data) VALUES (?, ?, ?)").run(id, seam.now(), v.seal(`ev:${id}`, data));
    return { ok: id };
  },
  // Operation 13 through 17: a sequence-number range; the data field unreadable once shredded.
  read(db: Database, v: Vault, from: number, to?: number): LoggedEvent[] {
    const rows = to === undefined
      ? db.prepare("SELECT * FROM event WHERE seq >= ? ORDER BY seq").all<LoggedEvent>(from)
      : db.prepare("SELECT * FROM event WHERE seq >= ? AND seq <= ? ORDER BY seq").all<LoggedEvent>(from, to);
    return rows.map((e) => ({ ...e, data: v.open(`ev:${e.event_id}`, e.data!) }));
  },
};

// ---- Retention Window ----
export interface Policy { ref: string; durationMs: number; maxPurgeDelayMs: number }
export interface RetentionRecord { retention_id: string; record_ref: string; policy_ref: string; retained_at: string; retention_deadline: string; state: "retained" | "purged"; purged_at: string | null; purge_eligible?: boolean }
export const retentionWindow = {
  place(db: Database, seam: Seam, f: Faults, record_ref: string, policy: Policy | undefined, qualifier?: string):
    R<string, "invalid-request" | "invalid-policy" | "policy-not-found" | "storage-failure"> {
    if (blank(record_ref)) return { refused: "invalid-request" };
    if (!policy) return { refused: "policy-not-found" };
    if (!(policy.durationMs > 0) || policy.maxPurgeDelayMs < 0) return { refused: "invalid-policy" };
    if (f.hit("retention.place", qualifier)) return { refused: "storage-failure" };
    const now = seam.now(), t = Date.parse(now), id = seam.id("retention");
    db.prepare("INSERT INTO retention VALUES (?, ?, ?, ?, ?, ?, 'retained', NULL)").run(id, record_ref, policy.ref, now,
      new Date(t + policy.durationMs).toISOString(), new Date(t + policy.durationMs + policy.maxPurgeDelayMs).toISOString());
    return { ok: id };
  },
  purge(db: Database, seam: Seam, f: Faults, retention_id: string): R<"ok", "not-known" | "not-retained" | "retention-period-not-elapsed" | "storage-failure"> {
    const now = seam.now();
    const r = db.prepare("SELECT * FROM retention WHERE retention_id = ?").get<RetentionRecord>(retention_id);
    if (!r) return { refused: "not-known" };
    if (r.state === "purged") return { refused: "not-retained" };
    if (now < r.retention_deadline) return { refused: "retention-period-not-elapsed" };
    if (f.hit("retention.purge", retention_id)) return { refused: "storage-failure" };
    db.prepare("UPDATE retention SET state='purged', purged_at=? WHERE retention_id=?").run(now, retention_id);
    return { ok: "ok" };
  },
  // Operation 29 through 33: every retention, purge eligible derived for a retained one.
  read(db: Database, seam: Seam): RetentionRecord[] {
    const now = seam.now();
    return db.prepare("SELECT * FROM retention ORDER BY retained_at, retention_id").all<RetentionRecord>()
      .map((r) => r.state === "retained" ? { ...r, purge_eligible: !(now < r.retention_deadline) } : r);
  },
};

// ---- Tamper Evidence: a chained hash over the presented record set ----
export interface Evidence { evidence_id: string; record_set_ref: string; proof: string; sealed_at: string }
export const tamperEvidence = {
  // Operation 1 through 12. The host renders the record set the reference names.
  seal(db: Database, seam: Seam, f: Faults, record_set_ref: string, credential: string | undefined, render: (ref: string) => string[] | null):
    R<string, "invalid-request" | "mechanism-failure" | "storage-failure"> & { reason?: string } {
    const now = seam.now();
    if (blank(record_set_ref) || credential === undefined) return { refused: "invalid-request" };
    const set = render(record_set_ref);
    if (!set || f.hit("seal.mechanism")) return { refused: "mechanism-failure", reason: "unreadable-records" };
    if (f.hit("seal.storage")) return { refused: "storage-failure" };
    const prev = db.prepare("SELECT proof FROM evidence ORDER BY sealed_at DESC, evidence_id DESC LIMIT 1").get<{ proof: string }>()?.proof ?? "";
    const id = seam.id("evidence");
    db.prepare("INSERT INTO evidence VALUES (?, ?, ?, ?, NULL)").run(id, record_set_ref, tamperEvidence.proofOf(prev, set, credential), now);
    return { ok: id };
  },
  proofOf(prev: string, set: string[], credential: string) {
    return createHash("sha256").update(prev).update("\n").update(credential).update("\n").update(set.join("\u0000")).digest("hex");
  },
  // Operation 13 through 20; record set match is the host's answer at the seam (22a).
  verify(db: Database, evidence_id: string, presented: string[], recordSetMatch: boolean, credential: string, mechanismUp = true):
    "verified" | { "failed-verification": "proof-invalid" | "record-set-mismatch" | "mechanism-verification-unavailable" } | "not-known" {
    const e = db.prepare("SELECT * FROM evidence WHERE evidence_id = ?").get<Evidence>(evidence_id);
    if (!e) return "not-known";
    if (!recordSetMatch) return { "failed-verification": "record-set-mismatch" };
    if (!mechanismUp) return { "failed-verification": "mechanism-verification-unavailable" };
    const all = db.prepare("SELECT * FROM evidence ORDER BY sealed_at, evidence_id").all<Evidence>();
    const prev = all[all.findIndex((x) => x.evidence_id === evidence_id) - 1]?.proof ?? "";
    return tamperEvidence.proofOf(prev, presented, credential) === e.proof ? "verified" : { "failed-verification": "proof-invalid" };
  },
  read(db: Database): Evidence[] { return db.prepare("SELECT * FROM evidence ORDER BY sealed_at, evidence_id").all<Evidence>(); },
};

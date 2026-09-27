// Audit Trail, rendered to the depth External Onboarding reaches: [Record Action]
// steps 1 through 5 and 7, [Read Record], [Verify Record] steps 1 through 3, and
// the log read passed through to Event Log (Action wiring 1). Sealing, purging
// and the substrate's own reconciliation are not rendered; see CORNERS.md.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { actorIdentity, eventLog, retentionWindow } from "./substrate_atoms.ts";

export interface AuditConfig {
  referenceCap: number;          // Term reference length cap
  payloadCap: number;            // Term payload cap
  attestationIdWidth: number;    // Primitive policy 21
  retentionPolicy: { ref: string; durationMs: number; maxPurgeDelayMs: number };
}
export interface Envelope { action_ref: string; actor_ref: string; attestation_id: string; data: Record<string, unknown> }
export type RecordAnswer =
  | { ok: string }
  | { refused: "invalid-credential" | "invalid-request" }
  | { refused: "recording-failure"; step: "step-2" | "step-3" | "step-4" };

export class AuditTrail {
  constructor(private db: Database, private seam: Seam, private f: Faults, readonly config: AuditConfig) {}

  // [Record Action].
  record_action(action_ref: string, actor_ref: string, credential: string, data: Record<string, unknown>): RecordAnswer {
    const c = this.config;
    // Step 1: Primitive policy 1 through 8, 21 and 22; nothing recorded on refusal.
    for (const r of [action_ref, actor_ref]) if (r.trim() === "" || new TextEncoder().encode(r).length > c.referenceCap) return { refused: "invalid-request" };
    if (action_ref.startsWith("audit.")) return { refused: "invalid-request" };
    const sized = JSON.stringify({ action_ref, actor_ref, attestation_id: "x".repeat(c.attestationIdWidth), data });
    if (sized.length > c.payloadCap) return { refused: "invalid-request" };
    // Step 2: attest.
    const att = actorIdentity.attest(this.db, this.seam, this.f, action_ref, actor_ref, credential);
    if ("refused" in att) return att.refused === "storage-failure" ? { refused: "recording-failure", step: "step-2" } : { refused: att.refused };
    // Step 3: append the full constructed payload.
    const payload = JSON.stringify({ action_ref, actor_ref, attestation_id: att.ok, data });
    const ev = eventLog.append(this.db, this.seam, this.f, payload, c.payloadCap + 64, action_ref);
    if ("refused" in ev) return ev.refused === "storage-failure" ? { refused: "recording-failure", step: "step-3" } : { refused: "invalid-request" };
    // Step 4: place the retention.
    const ret = retentionWindow.place(this.db, this.seam, this.f, ev.ok, c.retentionPolicy, action_ref);
    if ("refused" in ret) return ret.refused === "storage-failure" ? { refused: "recording-failure", step: "step-4" } : { refused: "invalid-request" };
    // Step 5: the indexes, the sequence number from the read-back.
    const seq = this.db.prepare("SELECT seq FROM event WHERE event_id = ?").get<{ seq: number }>(ev.ok)!.seq;
    this.db.prepare("INSERT INTO at_event_attestation VALUES (?, ?)").run(ev.ok, att.ok);
    this.db.prepare("INSERT INTO at_event_retention VALUES (?, ?)").run(ev.ok, ret.ok);
    this.db.prepare("INSERT INTO at_event_seq VALUES (?, ?)").run(ev.ok, seq);
    return { ok: ev.ok };
  }

  // [Read Record].
  read_record(event_id: string): AuditRecord | "not-known" {
    const ev = this.db.prepare("SELECT * FROM event WHERE event_id = ?").get<{ seq: number; recorded_at: string; data: string | null }>(event_id);
    const ret = this.db.prepare("SELECT r.* FROM at_event_retention x JOIN retention r ON r.retention_id = x.retention_id WHERE x.event_id = ?")
      .get<{ state: string; purged_at: string | null }>(event_id);
    if (!ev && !ret) return "not-known";
    if (ret?.state === "purged") {
      const pair = this.db.prepare("SELECT attestation_id FROM at_destruction WHERE event_id = ?").get<{ attestation_id: string }>(event_id);
      const a = pair && actorIdentity.read(this.db).find((x) => x.attestation_id === pair.attestation_id);
      return { event_id, seq: ev?.seq ?? null, retention: "Purged", action_ref: a?.action_ref ?? null, actor_ref: a?.actor_ref ?? null,
        attestation_id: pair?.attestation_id ?? null, data: null };
    }
    const env = JSON.parse(ev!.data!) as Envelope;
    return { event_id, seq: ev!.seq, retention: ret ? "Retained" : "unresolved", action_ref: env.action_ref, actor_ref: env.actor_ref,
      attestation_id: env.attestation_id, data: env.data };
  }

  // [Verify Record] steps 1 through 3.
  verify_record(event_id: string): "verified" | { "failed-verification": string } | "not-known" {
    const r = this.read_record(event_id);
    if (r === "not-known") return "not-known";
    if (r.retention === "Purged") return { "failed-verification": "purged" };
    const v = actorIdentity.verify(this.db, r.attestation_id!);
    if (v === "verified") return "verified";
    if (v === "not-known") return { "failed-verification": "attestation-not-known" };
    return { "failed-verification": `attestation-${v["failed-verification"]}` };
  }

  // The log read: Event Log's sequence-number range, passed through unchanged.
  log_read(from = 1): { seq: number; event_id: string; recorded_at: string; envelope: Envelope | null }[] {
    return eventLog.read(this.db, from).map((e) => ({ seq: e.seq, event_id: e.event_id, recorded_at: e.recorded_at,
      envelope: e.data === null ? null : JSON.parse(e.data) as Envelope }));
  }

  // The retention layer's purge, for tests that reach past the audit horizon: the
  // retention stands Purged, the payload goes, the destruction pair stays.
  purge_for_test(event_id: string) {
    const x = this.db.prepare("SELECT retention_id FROM at_event_retention WHERE event_id = ?").get<{ retention_id: string }>(event_id)!;
    const att = this.db.prepare("SELECT attestation_id FROM at_event_attestation WHERE event_id = ?").get<{ attestation_id: string }>(event_id)!;
    this.db.prepare("INSERT INTO at_destruction VALUES (?, ?)").run(event_id, att.attestation_id);
    this.db.prepare("UPDATE retention SET state='purged', purged_at=? WHERE retention_id=?").run(this.seam.now(), x.retention_id);
    this.db.prepare("UPDATE event SET data = NULL WHERE event_id = ?").run(event_id);
  }
}

export interface AuditRecord {
  event_id: string; seq: number | null; retention: "Retained" | "Purged" | "unresolved";
  action_ref: string | null; actor_ref: string | null; attestation_id: string | null; data: Record<string, unknown> | null;
}

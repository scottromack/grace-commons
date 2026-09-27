// Audit Trail, rendered from compositions/audit-trail.md. Every rule cited is
// that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { Vault } from "./vault.ts";
import { actorIdentity, eventLog, type Policy, retentionWindow, tamperEvidence } from "./atoms.ts";

export type Cadence = { kind: "per-event" } | { kind: "interval"; events?: number; timeMs?: number } | { kind: "on-demand" };
export type Selector = (action_ref: string, actor_ref: string, data: unknown) => string;
export interface ErasureMechanism { destroy(event_id: string, attestation_id: string): { outcome: "destroyed" } | { outcome: "destruction-failed"; reason: string } }

export class CriticalSection {                                                         // Per-act critical section 1 through 8
  private held = new Set<string>();
  take(key: string) { if (this.held.has(key)) return false; this.held.add(key); return true; }
  release(key: string) { this.held.delete(key); }
}

export interface Config {
  retentionPolicy?: string | Selector;         // retention policy
  policies: Record<string, Policy>;            // the Retention Window instance's registry
  sealCadence?: Cadence;
  sealMechanism?: "chained-hash";
  mechanismCredential?: string;                // empty for the unkeyed mechanism
  unsealedTailMode?: "strict" | "lenient";
  erasureMechanism?: ErasureMechanism;
  compensationWindowMs?: number;
  reconciliationCadenceMs?: number;
  reconciliationOperator?: string;
  reconciliationOperatorCredential?: string;
  payloadCap?: number;
  referenceCapBytes?: number;
  attestationIdWidth?: number;
  recordActionCompletionBoundMs?: number;
  purgeCompletionBoundMs?: number;
  compensationClosureLatencyMs?: number;
  clockOffsetAllowanceMs?: number;
  criticalSection?: CriticalSection;
  legalHold?: (event_id: string) => boolean;   // present only where Legal Hold is composed
}
export type RecordAnswer = { ok: string } | { refused: "invalid-credential" | "invalid-request" } | { refused: "recording-failure"; step: "step-2" | "step-3" | "step-4" };
export type Coverage =
  | { status: "covered"; evidence_id: string; range: [number, number]; sealed_at: string }
  | { status: "unsealed-tail" } | { status: "records-purged"; evidence_id: string; range: [number, number] }
  | { status: "partially-purged"; evidence_id: string; range: [number, number] };
export interface AuditRecord {
  event_id: string; seq: number; recorded_at: string; action_ref: string | null; actor_ref: string | null; attestation_instant?: string | null;
  attestation_id: string | null; data: unknown; attribution?: "not-recoverable";
  retention: { retention_id: string; policy_ref: string; state: "Retained" | "Purged"; retention_deadline: string; purged_at: string | null } | "unresolved (compensation window)";
  coverage: Coverage;
}
export type VerifyOutcome = { outcome: "verified" | { "failed-verification": string } | { unverifiable: string }; compensationWindow: boolean } | "not-known";
type Env = { action_ref: string; actor_ref: string; attestation_id: string; data: Record<string, unknown> };

export class AuditTrail {
  readonly alerts: { kind: string; detail: string }[] = [];
  registryUp = true;           // the actor registry's reachability, for Verify Record step 6
  mechanismUp = true;          // the seal mechanism's
  private unsealedSinceSeal = 0;
  private constructor(private db: Database, private seam: Seam, private f: Faults, private v: Vault, readonly c: Required<Omit<Config, "legalHold" | "reconciliationCadenceMs" | "mechanismCredential">> & Config) {}

  // ---- Instance start 1 through 17 ----
  static start(db: Database, seam: Seam, f: Faults, v: Vault, config: Config): AuditTrail {
    const c = { unsealedTailMode: "strict" as const, referenceCapBytes: 1024, ...config };       // unsealed tail mode 3; reference length cap 4
    const t = c.sealCadence?.kind === "interval" ? c.sealCadence.timeMs : undefined;
    if (c.reconciliationCadenceMs === undefined && t !== undefined) c.reconciliationCadenceMs = t;  // reconciliation cadence 4
    const required: (keyof Config)[] = ["retentionPolicy", "sealCadence", "sealMechanism", "erasureMechanism", "compensationWindowMs", "reconciliationCadenceMs",
      "reconciliationOperator", "reconciliationOperatorCredential", "payloadCap", "attestationIdWidth", "recordActionCompletionBoundMs",
      "purgeCompletionBoundMs", "compensationClosureLatencyMs", "clockOffsetAllowanceMs", "criticalSection"];
    for (const k of required) if (c[k] === undefined) throw new Error(`instance will not start: ${k} is blank`);
    const sum = Math.max(c.recordActionCompletionBoundMs!, c.purgeCompletionBoundMs!) + c.clockOffsetAllowanceMs! + c.reconciliationCadenceMs! + c.compensationClosureLatencyMs!;
    if (!(c.compensationWindowMs! > sum)) throw new Error("instance will not start: the compensation window does not exceed the closure sum");  // 16, 17
    return new AuditTrail(db, seam, f, v, c as AuditTrail["c"]);
  }

  private alert(kind: string, detail: string) { this.alerts.push({ kind, detail }); }
  private resolvePolicy(action_ref: string, actor_ref: string, data: unknown): Policy | undefined {        // Term resolved policy
    const p = this.c.retentionPolicy;
    return this.c.policies[typeof p === "function" ? p(action_ref, actor_ref, data) : p!];
  }

  // ---- the derived indexes, each with its rebuild (Composition state) ----
  private logRead(from = 1) { return eventLog.read(this.db, this.v, from); }
  private envelope(data: string | null): Env | null { return data === null ? null : JSON.parse(data) as Env; }
  seqOf(event_id: string): number | undefined {                                         // event to sequence 4, with rebuild-on-miss
    const hit = this.db.prepare("SELECT seq FROM event_to_sequence WHERE event_id = ?").get<{ seq: number }>(event_id);
    if (hit) return hit.seq;
    this.rebuildSequence();
    return this.db.prepare("SELECT seq FROM event_to_sequence WHERE event_id = ?").get<{ seq: number }>(event_id)?.seq;
  }
  rebuildSequence() {                                                                   // event to sequence 3
    for (const e of this.logRead()) this.db.prepare("INSERT OR IGNORE INTO event_to_sequence VALUES (?, ?)").run(e.event_id, e.seq);
  }
  retentionOf(event_id: string) {                                                       // event to retention, with rebuild-on-miss
    const q = () => this.db.prepare("SELECT r.* FROM event_to_retention x JOIN retention r ON r.retention_id = x.retention_id WHERE x.event_id = ?")
      .get<{ retention_id: string; policy_ref: string; state: string; retention_deadline: string; purged_at: string | null }>(event_id);
    const hit = q();
    if (hit) return hit;
    this.rebuildRetention();
    return q();
  }
  rebuildRetention() {                                                                  // event to retention 3
    for (const r of retentionWindow.read(this.db, this.seam)) this.db.prepare("INSERT OR IGNORE INTO event_to_retention VALUES (?, ?)").run(r.record_ref, r.retention_id);
  }
  attestationOf(event_id: string): string | undefined {                                // event to attestation 2, 3
    const hit = this.db.prepare("SELECT attestation_id FROM event_to_attestation WHERE event_id = ?").get<{ attestation_id: string }>(event_id);
    if (hit) return hit.attestation_id;
    const pair = this.db.prepare("SELECT attestation_id FROM destruction_record WHERE event_id = ?").get<{ attestation_id: string }>(event_id);
    if (pair) return pair.attestation_id;
    this.rebuildAttestation();
    return this.db.prepare("SELECT attestation_id FROM event_to_attestation WHERE event_id = ?").get<{ attestation_id: string }>(event_id)?.attestation_id;
  }
  rebuildAttestation() {                                                                // event to attestation 2b
    for (const e of this.logRead()) { const env = this.envelope(e.data); if (env) this.db.prepare("INSERT OR IGNORE INTO event_to_attestation VALUES (?, ?)").run(e.event_id, env.attestation_id); }
  }
  rebuildCoverage() {                                                                   // seal coverage 3, 4: from the seal store alone
    for (const e of tamperEvidence.read(this.db)) {
      const [a, b] = e.record_set_ref.slice(4).split("-").map(Number);
      this.db.prepare("INSERT OR IGNORE INTO seal_coverage VALUES (?, ?, ?)").run(e.evidence_id, a, b);
    }
  }
  sealedThrough(): number {                                                              // Term sealed through
    return (this.db.prepare("SELECT COALESCE(MAX(last_seq), 0) AS n FROM seal_coverage").get<{ n: number }>())!.n;
  }
  coveringSeal(seq: number) {
    return this.db.prepare("SELECT * FROM seal_coverage WHERE first_seq <= ? AND last_seq >= ?").get<{ evidence_id: string; first_seq: number; last_seq: number }>(seq, seq);
  }
  private reservedSet(action_ref: "audit.compensation" | "audit.reconciliation", pred: (d: Record<string, unknown>) => boolean): Set<string> {
    const out = new Set<string>();
    for (const e of this.logRead()) {
      const env = this.envelope(e.data);
      if (env && env.action_ref === action_ref && env.actor_ref === this.c.reconciliationOperator && pred(env.data))
        out.add(String(env.data.attestation_id ?? env.data.event_id));
    }
    return out;
  }
  narratedFindings() {                                                                  // Term narrated; Compensation 10, 11
    const out = new Set<string>();
    for (const e of this.logRead()) {
      const env = this.envelope(e.data);
      if (env && env.action_ref === "audit.reconciliation" && env.actor_ref === this.c.reconciliationOperator)
        out.add(`${env.data.subject}:${env.data.subject === "attestation" ? env.data.attestation_id : env.data.event_id}`);
    }
    return out;
  }
  compensatedAttestations() { return this.reservedSet("audit.compensation", (d) => d.subject === "attestation"); }  // compensated attestations 2 through 4
  reportedBeyondHorizon() { return this.reservedSet("audit.reconciliation", (d) => d.subject === "attestation" && d.disposition === "beyond-horizon"); }

  // ---- [Record Action] ----
  record_action(action_ref: string, actor_ref: string, credential: string, data: Record<string, unknown>): RecordAnswer {
    const c = this.c, enc = (s: string) => new TextEncoder().encode(s).length;
    // Step 1: Primitive policy 1 through 9, 21 through 23; record action step 1.4.
    for (const r of [action_ref, actor_ref]) if (r.trim() === "" || enc(r) > c.referenceCapBytes!) return { refused: "invalid-request" };
    const operator = actor_ref === c.reconciliationOperator;
    if (action_ref.startsWith("audit.") && (!operator || !["audit.compensation", "audit.reconciliation"].includes(action_ref))) return { refused: "invalid-request" };
    if (operator && action_ref === "audit.compensation") {
      if (data.subject !== "attestation" && data.subject !== "event") return { refused: "invalid-request" };
      if (!(data.subject === "attestation" ? data.attestation_id : data.event_id)) return { refused: "invalid-request" };
    }
    if (enc(JSON.stringify({ action_ref, actor_ref, attestation_id: "x".repeat(c.attestationIdWidth!), data })) > c.payloadCap!) return { refused: "invalid-request" };
    // Step 2: attest, then the per-act critical section on the attestation id.
    const att = actorIdentity.attest(this.db, this.seam, this.f, this.v, action_ref, actor_ref, credential);
    if ("refused" in att) return att.refused === "storage-failure" ? { refused: "recording-failure", step: "step-2" } : { refused: att.refused };
    const cs = c.criticalSection!;
    cs.take(att.ok);
    try {
      // Step 3: append the full constructed payload.
      const payload = JSON.stringify({ action_ref, actor_ref, attestation_id: att.ok, data });
      const ev = eventLog.append(this.db, this.seam, this.f, this.v, payload, c.payloadCap!, action_ref);
      if ("refused" in ev) {
        if (ev.refused === "invalid-payload") { this.alert("invalid-payload", action_ref); return { refused: "invalid-request" }; }  // payload cap 4
        return { refused: "recording-failure", step: "step-3" };
      }
      // Step 4: re-read event to retention under the section, then place.
      let retention_id = this.db.prepare("SELECT retention_id FROM event_to_retention WHERE event_id = ?").get<{ retention_id: string }>(ev.ok)?.retention_id;
      if (!retention_id) {
        const r = retentionWindow.place(this.db, this.seam, this.f, ev.ok, this.resolvePolicy(action_ref, actor_ref, data), action_ref);
        if ("refused" in r) {
          if (r.refused === "storage-failure") return { refused: "recording-failure", step: "step-4" };
          if (r.refused !== "invalid-request") this.alert("policy-fault", r.refused);                          // record action step 4.7
          return { refused: "invalid-request" };
        }
        retention_id = r.ok;
      }
      // Step 5: the indexes; a failure here is a rebuild trigger, never a refusal.
      if (!this.f.hit("index.write", action_ref)) {
        const seq = this.logRead(this.sealedThrough() + 1).find((e) => e.event_id === ev.ok)?.seq;
        this.db.prepare("INSERT OR IGNORE INTO event_to_attestation VALUES (?, ?)").run(ev.ok, att.ok);
        this.db.prepare("INSERT OR IGNORE INTO event_to_retention VALUES (?, ?)").run(ev.ok, retention_id);
        if (seq !== undefined) this.db.prepare("INSERT OR IGNORE INTO event_to_sequence VALUES (?, ?)").run(ev.ok, seq);
        else this.rebuildSequence();                                                                           // record action step 5.5
      }
      // Step 6: seal under the cadence; a seal failure never rejects.
      this.unsealedSinceSeal++;
      const cad = c.sealCadence!;
      if (cad.kind === "per-event" || (cad.kind === "interval" && cad.events !== undefined && this.unsealedSinceSeal >= cad.events)) {
        const s = this.seal_now();
        if ("refused" in s && s.refused !== "nothing-to-seal") this.alert("seal-failure", JSON.stringify(s));   // record action step 6.4, 6.5
      }
      return { ok: ev.ok };                                                                                     // step 7
    } finally { cs.release(att.ok); }
  }

  // ---- [Seal Now] ----
  seal_now(): { ok: string } | { refused: "nothing-to-seal" | "invalid-request" | "recording-failure" } | { refused: "mechanism-failure"; reason: string } {
    const from = this.sealedThrough() + 1;
    const tail = this.logRead(from);                                                     // seal now 1, 2
    if (tail.length === 0) return { refused: "nothing-to-seal" };                        // 3
    const ref = `seq:${from}-${tail.at(-1)!.seq}`;
    const s = tamperEvidence.seal(this.db, this.seam, this.f, ref, this.c.mechanismCredential ?? "", () =>
      tail.some((e) => e.data === null) ? null : tail.map((e) => e.data!));             // 4: the host renders the slice
    if ("refused" in s) {
      if (s.refused === "mechanism-failure") return { refused: "mechanism-failure", reason: s.reason! };          // 6
      return s.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "recording-failure" };  // 7, 8
    }
    this.db.prepare("INSERT INTO seal_coverage VALUES (?, ?, ?)").run(s.ok, from, tail.at(-1)!.seq);            // 5
    this.unsealedSinceSeal = 0;
    return { ok: s.ok };
  }

  // ---- [Read Record] ----
  read_record(event_id: string): AuditRecord | "not-known" {
    const ret = this.retentionOf(event_id);                                              // step 1
    const seq = this.seqOf(event_id);
    const ev = seq === undefined ? undefined : this.logRead(seq).find((e) => e.seq === seq);  // step 2: the singleton range
    if (!ret && !ev) return "not-known";                                                 // step 3
    if (ret && !ev) { this.alert("retention-without-log-entry", event_id); return "not-known"; }
    const coverage = this.coverage(ev!.seq);
    const retention = ret ? { retention_id: ret.retention_id, policy_ref: ret.policy_ref, state: ret.state === "purged" ? "Purged" as const : "Retained" as const,
      retention_deadline: ret.retention_deadline, purged_at: ret.purged_at } : "unresolved (compensation window)" as const;   // step 5
    if (ret?.state === "purged") {                                                       // step 4.4
      const pair = this.db.prepare("SELECT attestation_id FROM destruction_record WHERE event_id = ?").get<{ attestation_id: string }>(event_id);
      const a = pair && actorIdentity.read(this.db).find((x) => x.attestation_id === pair.attestation_id);
      if (!a) return { event_id, seq: ev!.seq, recorded_at: ev!.recorded_at, action_ref: null, actor_ref: null, attestation_id: null, data: null,
        attribution: "not-recoverable", retention, coverage };
      return { event_id, seq: ev!.seq, recorded_at: ev!.recorded_at, action_ref: a.action_ref, actor_ref: a.actor_ref, attestation_instant: a.attested_at,
        attestation_id: a.attestation_id, data: null, retention, coverage };
    }
    const env = this.envelope(ev!.data)!;
    return { event_id, seq: ev!.seq, recorded_at: ev!.recorded_at, action_ref: env.action_ref, actor_ref: env.actor_ref, attestation_id: env.attestation_id,
      data: env.data, retention, coverage };
  }
  private coverage(seq: number): Coverage {
    const s = this.coveringSeal(seq);
    if (!s) return { status: "unsealed-tail" };
    const range: [number, number] = [s.first_seq, s.last_seq];
    const purged = this.db.prepare("SELECT seq FROM purged_events WHERE evidence_id = ?").all<{ seq: number }>(s.evidence_id).map((r) => r.seq);
    if (purged.includes(seq)) return { status: "records-purged", evidence_id: s.evidence_id, range };
    if (purged.length) return { status: "partially-purged", evidence_id: s.evidence_id, range };
    const e = tamperEvidence.read(this.db).find((x) => x.evidence_id === s.evidence_id)!;
    return { status: "covered", evidence_id: s.evidence_id, range, sealed_at: e.sealed_at };
  }

  // ---- [Verify Record] ----
  verify_record(event_id: string, presentation: string[]): VerifyOutcome {
    const ret = this.retentionOf(event_id);
    if (ret?.state === "purged") return { outcome: { "failed-verification": "purged" }, compensationWindow: false };  // step 1
    const seq = this.seqOf(event_id);
    const ev = seq === undefined ? undefined : this.logRead(seq).find((e) => e.seq === seq);
    if (!ret && !ev) return "not-known";                                                 // step 2
    const qualifier = !ret;                                                              // step 2.3
    const out = (outcome: Exclude<VerifyOutcome, "not-known">["outcome"]) => ({ outcome, compensationWindow: qualifier });
    let unavailable: string | null = null;
    const a = actorIdentity.verify(this.db, this.v, this.attestationOf(event_id)!, this.registryUp);   // step 3
    if (a === "not-known") return out({ "failed-verification": "attestation-not-known" });
    if (a !== "verified") {
      if (a["failed-verification"] === "registry-unavailable") unavailable = "attestation-registry-unavailable";
      else return out({ "failed-verification": `attestation-${a["failed-verification"]}` });
    }
    if (!unavailable) {
      const s = this.coveringSeal(ev!.seq);                                              // step 4
      if (s) {
        const purged = this.db.prepare("SELECT COUNT(*) AS n FROM purged_events WHERE evidence_id = ?").get<{ n: number }>(s.evidence_id)!.n;
        if (purged > 0) return out({ unverifiable: "partially-purged-coverage" });
        const match = presentation.length === s.last_seq - s.first_seq + 1;              // the host's record set match (Tamper Evidence Operation 22a)
        const t = tamperEvidence.verify(this.db, s.evidence_id, presentation, match, this.c.mechanismCredential ?? "", this.mechanismUp);  // step 5
        if (t === "not-known") return out({ "failed-verification": "seal-not-known" });
        if (t !== "verified") {
          if (t["failed-verification"] === "mechanism-verification-unavailable") unavailable = "seal-mechanism-verification-unavailable";
          else return out({ "failed-verification": `seal-${t["failed-verification"]}` });
        }
      } else if (this.c.unsealedTailMode === "strict") return out({ "failed-verification": "unsealed" });
    }
    if (unavailable) return out({ unverifiable: unavailable });                          // step 6
    return out("verified");                                                              // step 7
  }

  // ---- [Purge Eligible] ----
  purge_eligible(): string[] {
    return retentionWindow.read(this.db, this.seam).filter((r) => r.purge_eligible).map((r) => r.record_ref);  // purge eligible 1 through 6
  }

  // ---- [Purge Event] ----
  purge_event(event_id: string): { ok: "ok" } | { refused: "not-known" | "not-eligible" | "retention-unresolved" | "under-legal-hold" } | { refused: "cascade-failure"; step: "seal" | "step-1" | "step-2" | "step-3" } {
    const ret0 = this.retentionOf(event_id), seq = this.seqOf(event_id);
    if (!ret0 && seq === undefined) return { refused: "not-known" };                      // purge event 1
    const cs = this.c.criticalSection!;
    // Concurrency 2 serializes the cascade per event id. This host is synchronous and every holder releases on return
    // (Per-act critical section 2), so a held section here is a holder that never released: a host fault, not an answer.
    if (!cs.take(event_id)) throw new Error("Per-act critical section 2: a holder did not release");
    try { return this.cascade(event_id); } finally { cs.release(event_id); }
  }
  // The cascade, run by the holder of the event's critical section: [Purge Event] or the first half.
  private cascade(event_id: string): ReturnType<AuditTrail["purge_event"]> {
    const ret0 = this.retentionOf(event_id), seq = this.seqOf(event_id);
    if (this.c.legalHold && this.c.legalHold(event_id)) return { refused: "under-legal-hold" };  // purge event 5
    {
      if (!this.coveringSeal(seq!)) {                                                    // step 0
        const s = this.seal_now();
        if ("refused" in s) return { refused: "cascade-failure", step: "seal" };
      }
      if (!ret0) return { refused: "retention-unresolved" };                              // step 0½
      const p = retentionWindow.purge(this.db, this.seam, this.f, ret0.retention_id);    // step 1
      if ("refused" in p) {
        if (p.refused === "retention-period-not-elapsed") return { refused: "not-eligible" };
        if (p.refused === "not-known") return { refused: "not-known" };
        if (p.refused === "storage-failure") return { refused: "cascade-failure", step: "step-1" };
      }                                                                                  // not-retained resumes from step 2
      const attestation_id = this.attestationOf(event_id)!;
      if (!this.db.prepare("SELECT 1 FROM destruction_record WHERE event_id = ?").get(event_id)) {  // step 2: one durable write
        if (this.f.hit("cascade.step2", event_id)) return { refused: "cascade-failure", step: "step-2" };
        const s = this.coveringSeal(seq!)!;
        this.db.exec("BEGIN");
        this.db.prepare("INSERT OR IGNORE INTO purged_events VALUES (?, ?)").run(s.evidence_id, seq!);
        this.db.prepare("INSERT INTO destruction_record VALUES (?, ?, ?)").run(event_id, attestation_id, seq!);
        this.db.exec("COMMIT");
      }
      if (this.closedEntry(event_id)) return { ok: "ok" };                                // step 3's pre-check: a destroyed outcome is adopted
      if (this.f.hit("cascade.delegate", event_id)) return { refused: "cascade-failure", step: "step-3" };  // step 3.6
      const o = this.c.erasureMechanism!.destroy(event_id, attestation_id);              // step 3.1 through 3.3
      this.db.prepare("INSERT INTO erasure_outcome (event_id, outcome, reason, recorded_at) VALUES (?, ?, ?, ?)")
        .run(event_id, o.outcome, o.outcome === "destruction-failed" ? o.reason : null, this.seam.now());   // 3.4
      if (o.outcome === "destruction-failed") { this.alert("divergence", event_id); return { refused: "cascade-failure", step: "step-3" }; }  // 3.5; Boundary one 3, 4
      return { ok: "ok" };
    }
  }
  closedEntry(event_id: string) {                                                        // Term closed entry
    return !!this.db.prepare("SELECT 1 FROM erasure_outcome WHERE event_id = ? AND outcome = 'destroyed'").get(event_id);
  }

  // ---- the reconciliation scan (Reconciliation 1 through 7; the three halves; Compensation 1 through 11) ----
  scan(): void {
    const c = this.c, now = Date.parse(this.seam.now());                                 // Reconciliation 5
    const recordEdge = c.recordActionCompletionBoundMs! + c.clockOffsetAllowanceMs!;
    const purgeEdge = c.purgeCompletionBoundMs! + c.clockOffsetAllowanceMs!;
    const horizon = this.resolvePolicy("audit.compensation", c.reconciliationOperator!, {})!.durationMs;  // Term horizon
    const op = (action: "audit.reconciliation" | "audit.compensation", data: Record<string, unknown>) => {
      const r = this.record_action(action, c.reconciliationOperator!, c.reconciliationOperatorCredential!, data);
      if ("refused" in r) this.alert("reconciliation-write-refused", JSON.stringify(r));    // Third half 11: retried next run
      return "ok" in r;
    };
    // First half: the half-completed cascade.
    for (const r of retentionWindow.read(this.db, this.seam).filter((r) => r.state === "purged")) {
      if (purgeEdge > now - Date.parse(r.purged_at!)) continue;                          // First half 2
      const whole = () => {
        const seq = this.seqOf(r.record_ref);
        return seq !== undefined && !!this.db.prepare("SELECT 1 FROM purged_events WHERE seq = ?").get(seq) &&
          !!this.db.prepare("SELECT 1 FROM destruction_record WHERE event_id = ?").get(r.record_ref) && this.closedEntry(r.record_ref);
      };
      if (whole()) continue;                                                             // First half 3, 4
      if (!c.criticalSection!.take(r.record_ref)) continue;                              // First half 6; Per-act critical section 5
      try {
        if (whole()) continue;                                                           // First half 7
        this.alert("half-completed-cascade", r.record_ref);                              // Reconciliation 2
        this.cascade(r.record_ref);                                                      // First half 5, 8
      } finally { c.criticalSection!.release(r.record_ref); }
    }
    // Second half: the orphan attestation.
    const log = this.logRead();
    const binding = new Set<string>([...log.map((e) => this.envelope(e.data)?.attestation_id).filter((x): x is string => !!x),
      ...this.db.prepare("SELECT attestation_id FROM destruction_record").all<{ attestation_id: string }>().map((r) => r.attestation_id)]);  // Term binding set
    for (const a of actorIdentity.read(this.db)) {
      if (binding.has(a.attestation_id)) continue;                                       // Second half 2
      const age = now - Date.parse(a.attested_at);
      if (recordEdge > age) continue;                                                    // 3
      if (!c.criticalSection!.take(a.attestation_id)) continue;                          // Per-act critical section 5, 6
      try {
        if (age > horizon) {                                                             // 4 through 8
          if (!this.reportedBeyondHorizon().has(a.attestation_id))
            op("audit.reconciliation", { subject: "attestation", attestation_id: a.attestation_id, disposition: "beyond-horizon" });
          continue;
        }
        if (this.compensatedAttestations().has(a.attestation_id)) continue;             // 9, 10
        this.alert("orphan-attestation", a.attestation_id);
        if (!this.narratedFindings().has(`attestation:${a.attestation_id}`) &&                                           // Compensation 10, 11
          !op("audit.reconciliation", { subject: "attestation", attestation_id: a.attestation_id })) continue;            // Compensation 1 through 3, 9
        op("audit.compensation", { subject: "attestation", attestation_id: a.attestation_id });                          // 4; Second half 13
      } finally { c.criticalSection!.release(a.attestation_id); }
    }
    // Third half: the unretained event.
    for (const e of this.logRead()) {
      const env = this.envelope(e.data);
      if (!env || recordEdge > now - Date.parse(e.recorded_at)) continue;                // Third half 4
      if (this.retentionOf(e.event_id)) continue;                                        // 2, 3: rebuild-on-miss first
      if (!c.criticalSection!.take(env.attestation_id)) continue;                        // 5
      try {
        this.rebuildRetention();
        if (this.retentionOf(e.event_id)) continue;                                      // 6
        this.alert("unretained-event", e.event_id);
        if (!this.narratedFindings().has(`event:${e.event_id}`) &&                                                       // Compensation 10, 11
          !op("audit.reconciliation", { subject: "event", event_id: e.event_id })) continue;                            // Third half 8; Compensation 9
        const r = retentionWindow.place(this.db, this.seam, this.f, e.event_id, this.resolvePolicy(env.action_ref, env.actor_ref, env.data), e.event_id);  // Composes 9
        if ("refused" in r) continue;
        this.db.prepare("INSERT OR IGNORE INTO event_to_retention VALUES (?, ?)").run(e.event_id, r.ok);
        op("audit.compensation", { subject: "event", event_id: e.event_id });            // 9, 10
      } finally { c.criticalSection!.release(env.attestation_id); }
    }
    // Third half 12, 13: an owed narration — an intent past the bound with no compensation, the retention confirmed.
    const all = this.logRead().map((e) => ({ e, env: this.envelope(e.data) })).filter((x) => x.env && x.env.actor_ref === c.reconciliationOperator);
    for (const { e, env } of all) {
      if (env!.action_ref !== "audit.reconciliation" || env!.data.subject !== "event") continue;
      const id = String(env!.data.event_id);
      if (recordEdge > now - Date.parse(e.recorded_at) || now - Date.parse(e.recorded_at) > horizon) continue;  // 14
      if (all.some((x) => x.env!.action_ref === "audit.compensation" && x.env!.data.subject === "event" && x.env!.data.event_id === id)) continue;
      const key = this.attestationOf(id);
      if (!key || !c.criticalSection!.take(key)) continue;                               // Third half 13; Reconciliation 6
      try { if (this.retentionOf(id)) op("audit.compensation", { subject: "event", event_id: id }); } finally { c.criticalSection!.release(key); }
    }
  }
}

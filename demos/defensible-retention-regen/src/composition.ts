// Defensible Retention, rendered from compositions/defensible-retention.md.
// Every rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import type { Vault } from "./vault.ts";
import { eventLog, type Policy, retentionWindow, type RetentionRecord } from "./audit_atoms.ts";
import { type Hold, legalHold } from "./atoms.ts";
import type { AuditTrail } from "./audit_trail.ts";

export const INTENT_OUTCOME = {
  retention_placement_intended: "retention_placed", hold_placement_intended: "hold_placed",
  hold_release_intended: "hold_released", purge_intended: "record_purged",
} as const;
type IntentName = keyof typeof INTENT_OUTCOME;
const INTENTS = Object.keys(INTENT_OUTCOME) as IntentName[];
const OUTCOMES = [...Object.values(INTENT_OUTCOME), "intent_abandoned"] as string[];
export const GATE = "purge_blocked_by_hold", RECOVERY = "retention.recovery_intended";

export interface Config {
  holdCheckMode: "strict" | "advisory";                    // Capability requirement 24, 25
  policies: Record<string, Policy>;                        // resolved at Retention Window's seam (Capability requirement 31)
  longestHoldMs: number | "unbounded";                     // Capability requirement 12
  horizonAlert?: boolean;                                  // Capability requirement 13
  fieldCapBytes: number;                                   // Capability requirement 14, 15
  holdIdsCap: number;                                      // Capability requirement 16
  serviceActor: string; serviceCredential: string;         // Capability requirement 17
  retentionCompletionBoundMs: number;                      // 19
  compensationWindowMs: number;                            // 20
  reconciliationCadenceMs: number;                         // 21
  auditWriteLatencyMs: number;                             // 22
  clockOffsetAllowanceMs: number;                          // 36
  recordAttempts?: number;                                 // an invocation's retries before it yields (see CORNERS.md)
}
export interface Substrate { trail: AuditTrail; db: Database; v: Vault }   // the Audit Trail instance and the Event Log it carries
export type HoldCheckResult = { hold_ids: string[]; count: number };
export type Position = "intent" | "outcome" | "gate";                     // Term position
type RecordFailure = { refused: "recording-failure"; position: Position };
type Common = { refused: "invalid-request" | "invalid-credential" | "storage-failure" } | RecordFailure;
export type PurgeAnswer = { ok: "ok" } | Common | { refused: "not-known" | "not-eligible" | "under-active-retention" | "hold-check-unavailable" }
  | { refused: "under-legal-hold"; hold_ids: string[]; count: number };
export interface Tuple { retention_id: string; record_ref: string; retention_deadline: string; purge_deadline: string; hold_count: number | "unavailable" }
interface Ev { seq: number; event_id: string; recorded_at: string; action_ref: string | null; actor_ref: string | null; data: Record<string, unknown> | null }
type Wrote = { landed: string } | { refused: "invalid-credential" } | { owed: "cap" | "retries" };

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
const bytes = (s: string) => new TextEncoder().encode(s).length;
const iso = (s: string) => /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{3})?Z$/.test(s) && !isNaN(Date.parse(s));

export class DefensibleRetention {
  readonly alerts: { kind: string; detail: string }[] = [];
  private held = new Set<string>();   // the deployment's per-record and per-act serialization (Capability requirement 34, 35; Reconciliation 20)
  private constructor(private sub: Substrate, private db: Database, private seam: Seam, private f: Faults, readonly c: Config) {}

  static start(sub: Substrate, db: Database, seam: Seam, f: Faults, c: Config): DefensibleRetention {
    const horizon = sub.trail.c.policies[sub.trail.c.retentionPolicy as string].durationMs;           // Term audit horizon
    const longestPolicy = Math.max(0, ...Object.values(c.policies).map((p) => p.durationMs));
    if (c.longestHoldMs === "unbounded") { if (!c.horizonAlert) throw new Error("instance will not start: an unbounded hold needs the horizon alert"); }  // 13
    else if (longestPolicy + c.longestHoldMs > horizon) throw new Error("instance will not start: the evidence floor exceeds the audit horizon");        // 11
    if (c.fieldCapBytes > sub.trail.c.payloadCap!) throw new Error("instance will not start: a field cap exceeds the payload cap");                    // 15
    const floor = c.retentionCompletionBoundMs + c.reconciliationCadenceMs + c.auditWriteLatencyMs;
    if (!(c.compensationWindowMs > floor)) throw new Error("instance will not start: the compensation window does not exceed the closure floor");      // 23
    const dr = new DefensibleRetention(sub, db, seam, f, c);
    dr.sweep();                                                                                        // Reconciliation 1
    return dr;
  }
  private alert(kind: string, detail: string) { this.alerts.push({ kind, detail }); }
  private take(key: string) { if (this.held.has(key)) throw new Error(`a holder did not release ${key}`); this.held.add(key); }
  private release(key: string) { this.held.delete(key); }

  // ---- the substrate: its Event Log's open-ended read, and record_action under the Audit arm ----
  events(): Ev[] {                                                                   // Composes 12, 13
    return eventLog.read(this.sub.db, this.sub.v, 1).map((e) => {
      const env = e.data === null ? null : JSON.parse(e.data);
      return { seq: e.seq, event_id: e.event_id, recorded_at: e.recorded_at, action_ref: env?.action_ref ?? null, actor_ref: env?.actor_ref ?? null, data: env?.data ?? null };
    });
  }
  private readBack(action: string, invocation_id: unknown): string | undefined {    // Audit arm 5
    return this.events().filter((e) => e.action_ref === action && e.data?.invocation_id === invocation_id).at(-1)?.event_id;
  }
  private write(action: string, actor: string, credential: string, data: Record<string, unknown>, by: "caller" | "sweep"): Wrote {
    for (let i = 0; i < (this.c.recordAttempts ?? 3); i++) {
      const r = this.sub.trail.record_action(action, actor, credential, data);
      if ("ok" in r) return { landed: r.ok };
      if (r.refused === "recording-failure") {
        if (r.step !== "step-4") continue;                                            // Audit arm 1, 2
        this.alert("landed-without-retention", action);                               // Audit arm 3, 4, 6
        return { landed: this.readBack(action, data.invocation_id)! };
      }
      if (r.refused === "invalid-credential") {                                       // Audit arm 7 through 10
        if (by === "sweep") this.alert("service-credential-fault", action);
        return { refused: "invalid-credential" };
      }
      this.alert("audit-invalid-request", action);                                    // Audit arm 11, 14, 15
      const landed = this.readBack(action, data.invocation_id);
      return landed ? { landed } : { owed: "cap" };                                   // Audit arm 12, 13
    }
    return { owed: "retries" };                                                        // Action wiring 71: the invocation yields
  }
  private intentFailure(w: Wrote): Common {
    if ("refused" in w) return { refused: "invalid-credential" };
    if ("landed" in w) throw new Error("a landed record is not a failure");
    return w.owed === "cap" ? { refused: "invalid-request" } : { refused: "recording-failure", position: "intent" };
  }
  private outcome(action: string, actor: string, credential: string, data: Record<string, unknown>): { ok: true } | RecordFailure {
    const w = this.write(action, actor, credential, data, "caller");
    if ("landed" in w) return { ok: true };
    this.alert("owed-outcome", `${action}:${data.invocation_id}`);                    // Action wiring 70; Invariant 5.6's window
    return { refused: "recording-failure", position: "outcome" };
  }
  private capped(...xs: (string | undefined)[]) { return xs.some((x) => x !== undefined && bytes(x) > this.c.fieldCapBytes); }  // Primitive policy 12, 14

  // ---- the indexes (Composition state) ----
  private indexAdd(r: RetentionRecord) {
    this.db.prepare("INSERT OR IGNORE INTO record_to_retentions VALUES (?, ?)").run(r.record_ref, r.retention_id);
    this.db.prepare("INSERT OR IGNORE INTO retention_to_record VALUES (?, ?, ?, ?)").run(r.retention_id, r.record_ref, r.retention_deadline, r.purge_deadline);
  }
  private indexDrop(retention_id: string) {
    this.db.prepare("DELETE FROM record_to_retentions WHERE retention_id = ?").run(retention_id);
    this.db.prepare("DELETE FROM retention_to_record WHERE retention_id = ?").run(retention_id);
  }
  indexEntry(retention_id: string) {
    return this.db.prepare("SELECT * FROM retention_to_record WHERE retention_id = ?").get<{ retention_id: string; record_ref: string; retention_deadline: string; purge_deadline: string }>(retention_id);
  }
  rebuild() {                                                                         // Term rebuild; Composition state 12 through 25
    const evs = this.events(), store = retentionWindow.read(this.db, this.seam);
    const placed = new Set<string>();
    let lapsed = false;
    for (const e of evs) {
      if (e.action_ref === "retention_placed") placed.add(String(e.data!.retention_id));   // 12: a surviving placement event
      else if (e.data === null) {
        const r = this.sub.trail.read_record(e.event_id);
        if (r !== "not-known" && r.action_ref === "retention_placed") lapsed = true;       // a purged placement event: recognized, binding gone (14)
      }
    }
    if (lapsed) for (const r of store) placed.add(r.retention_id);                   // 13, 16: the store-sourced rebuild over-includes
    const claimed = this.purgedByOutcome(evs);
    const stale = this.db.prepare("SELECT retention_id FROM retention_to_record").all<{ retention_id: string }>().map((x) => x.retention_id);
    for (const id of new Set([...placed, ...stale])) {
      const r = store.find((x) => x.retention_id === id);
      if (!r) continue;
      if (r.state === "purged") {                                                     // 23
        this.indexDrop(id);
        if (!claimed.has(id)) this.alert("bypass", id);                               // 24, 25
      } else this.indexAdd(r);
    }
  }
  private purgedByOutcome(evs: Ev[]) {
    const out = new Set<string>();
    for (const e of evs) if (e.action_ref === "record_purged") {
      out.add(String(e.data!.retention_id));
      for (const p of e.data!.purged_retention_ids as { retention_id: string; disposition: string }[]) if (p.disposition === "purged") out.add(p.retention_id);
    }
    return out;
  }

  // ---- [Place Record Under Retention] ----
  place_record_under_retention(record_ref: string, policy_ref: string, actor_ref: string, credential: string): { ok: string } | Common {
    if (blank(record_ref) || blank(policy_ref) || blank(actor_ref) || blank(credential)) return { refused: "invalid-request" };  // Primitive policy 1 through 3, 7
    if (this.capped(record_ref, policy_ref, actor_ref)) return { refused: "invalid-request" };                                   // 12
    const invocation_id = this.seam.id("invocation"), now = this.seam.now();
    const i = this.write("retention_placement_intended", actor_ref, credential, { invocation_id, record_ref, policy_ref, actor_ref, intent_instant: now }, "caller");
    if (!("landed" in i)) return this.intentFailure(i);
    const p = retentionWindow.place(this.db, this.seam, this.f, record_ref, this.c.policies[policy_ref], record_ref);           // Action wiring 9
    if ("refused" in p) return { refused: p.refused === "storage-failure" ? "storage-failure" : "invalid-request" };             // 13 through 16
    const r = retentionWindow.read(this.db, this.seam).find((x) => x.retention_id === p.ok)!;                                    // 10
    this.indexAdd(r);                                                                                                            // Composition state 3, 4
    const o = this.outcome("retention_placed", actor_ref, credential, { invocation_id, retention_id: r.retention_id, record_ref, policy_ref,
      retention_deadline: r.retention_deadline, purge_deadline: r.purge_deadline });                                             // 11
    return "ok" in o ? { ok: p.ok } : o;                                                                                         // 12
  }

  // ---- [Place Hold] ----
  place_hold(record_ref: string, placed_by: string, credential: string, reason: string, case_ref?: string, placed_at?: string): { ok: string } | Common {
    if (blank(record_ref) || blank(placed_by) || blank(reason) || blank(credential)) return { refused: "invalid-request" };      // Primitive policy 1, 4, 6, 7
    if (case_ref !== undefined && blank(case_ref)) return { refused: "invalid-request" };                                        // 9
    if (placed_at !== undefined && !iso(placed_at)) return { refused: "invalid-request" };                                       // 10
    if (this.capped(record_ref, placed_by, reason, case_ref)) return { refused: "invalid-request" };
    this.take(`record:${record_ref}`);                                                                                           // Capability requirement 35
    try {
      const invocation_id = this.seam.id("invocation"), now = this.seam.now();
      const i = this.write("hold_placement_intended", placed_by, credential, { invocation_id, record_ref, placed_by, reason, case_ref: case_ref ?? null,
        placed_at: placed_at ?? null, intent_instant: now }, "caller");
      if (!("landed" in i)) return this.intentFailure(i);
      const h = legalHold.place(this.db, this.seam, this.f, record_ref, placed_by, reason, case_ref, placed_at);                // Action wiring 17
      if ("refused" in h) return { refused: h.refused };                                                                          // 20, 21
      const hold = (legalHold.read(this.db, this.f, { hold_id: h.ok }) as { ok: Hold[] }).ok[0];
      const o = this.outcome("hold_placed", placed_by, credential, { invocation_id, hold_id: h.ok, record_ref, placed_by, reason,
        case_ref: hold.case_ref, placed_at: hold.placed_at });                                                                    // 18; Invariant 3.3
      return "ok" in o ? { ok: h.ok } : o;                                                                                        // 19
    } finally { this.release(`record:${record_ref}`); }
  }

  // ---- [Release Hold] ----
  release_hold(hold_id: string, released_by: string, credential: string, reason: string, released_at?: string): { ok: "released" } | Common | { refused: "not-known" | "already-released" } {
    if (blank(hold_id) || blank(released_by) || blank(reason) || blank(credential)) return { refused: "invalid-request" };       // Primitive policy 5 through 8
    if (released_at !== undefined && !iso(released_at)) return { refused: "invalid-request" };                                   // 11
    if (this.capped(hold_id, released_by, reason)) return { refused: "invalid-request" };
    const read = legalHold.read(this.db, this.f, { hold_id });                                                                   // Action wiring 22
    if (!("ok" in read)) return { refused: "storage-failure" };
    if (read.ok.length === 0) return { refused: "not-known" };                                                                   // 23
    if (read.ok[0].state === "released") return { refused: "already-released" };                                                 // 24
    const invocation_id = this.seam.id("invocation"), now = this.seam.now();
    const i = this.write("hold_release_intended", released_by, credential, { invocation_id, hold_id, released_by, reason, released_at: released_at ?? null,
      intent_instant: now }, "caller");
    if (!("landed" in i)) return this.intentFailure(i);
    const r = legalHold.release(this.db, this.seam, this.f, hold_id, released_by, reason, released_at);                         // 25
    if ("refused" in r) return { refused: r.refused };                                                                            // 28 through 31
    const hold = (legalHold.read(this.db, this.f, { hold_id }) as { ok: Hold[] }).ok[0];
    const o = this.outcome("hold_released", released_by, credential, { invocation_id, hold_id, reason, released_at: hold.released_at });  // 26
    return "ok" in o ? { ok: "released" } : o;                                                                                    // 27
  }

  // ---- [Purge Eligible] ----
  purge_eligible(): Tuple[] {
    const now = this.seam.now();
    const rows = this.db.prepare("SELECT * FROM retention_to_record ORDER BY retention_deadline, retention_id")
      .all<{ retention_id: string; record_ref: string; retention_deadline: string; purge_deadline: string }>();          // Action wiring 32, 39, 40
    return rows.filter((r) => !(now < r.retention_deadline)).map((r) => {                                                  // 33
      const h = legalHold.read(this.db, this.f, { record_ref: r.record_ref, hold_state: "active" });                       // 34
      return { ...r, hold_count: "ok" in h ? h.ok.length : "unavailable" as const };                                        // 35 through 38
    });
  }

  // ---- [Purge Record] ----
  private holdCheck(record_ref: string): HoldCheckResult | "unavailable" {                                                  // Term gate read
    const h = legalHold.read(this.db, this.f, { record_ref, hold_state: "active" });                                        // Action wiring 48
    if ("refused" in h) { this.alert("hold-read-defect", record_ref); return "unavailable"; }                               // 74, 75
    if ("unreachable" in h) return "unavailable";                                                                           // 50; Invariant 1.3
    return { hold_ids: h.ok.slice(0, this.c.holdIdsCap).map((x) => x.hold_id), count: h.ok.length };                       // Primitive policy 20, 21
  }
  purge_record(retention_id: string, actor_ref: string, credential: string): PurgeAnswer {
    if (blank(actor_ref) || blank(credential)) return { refused: "invalid-request" };                                       // Primitive policy 3, 7
    if (this.capped(retention_id, actor_ref)) return { refused: "invalid-request" };
    if (!this.indexEntry(retention_id)) this.rebuild();                                                                     // Action wiring 44
    const entry = this.indexEntry(retention_id);
    if (!entry) return { refused: "not-known" };                                                                            // 45
    const record_ref = entry.record_ref;
    this.take(`record:${record_ref}`);                                                                                      // Capability requirement 34
    try {
      const now = this.seam.now(), elapsed = (r: { retention_deadline: string }) => !(now < r.retention_deadline);        // Clock semantics 4, 5
      const store = retentionWindow.read(this.db, this.seam);
      const named = store.find((r) => r.retention_id === retention_id)!;
      if (named.state === "purged") { this.indexDrop(retention_id); return { refused: "not-known" }; }                    // Action wiring 73
      const siblings = store.filter((r) => r.record_ref === record_ref && r.state === "retained" && r.retention_id !== retention_id);  // Composition state 19
      const hold = this.holdCheck(record_ref);                                                                              // Action wiring 49
      if (hold === "unavailable") return { refused: "hold-check-unavailable" };                                             // 50
      const invocation_id = this.seam.id("invocation");
      if (hold.count > 0 && this.c.holdCheckMode === "strict") {                                                            // 52 through 54
        const g = this.write(GATE, actor_ref, credential, { invocation_id, retention_id, record_ref, hold_check_result: hold }, "caller");
        if ("landed" in g) return { refused: "under-legal-hold", hold_ids: hold.hold_ids, count: hold.count };
        const fail = this.intentFailure(g);                                                                                  // Invariant 1.2
        return fail.refused === "recording-failure" ? { refused: "recording-failure", position: "gate" } : fail;
      }
      if (!elapsed(named)) return { refused: "not-eligible" };                                                              // 57
      if (siblings.some((s) => !elapsed(s))) return { refused: "under-active-retention" };                                 // 47
      const override = hold.count > 0;                                                                                       // 55: advisory
      const i = this.write("purge_intended", actor_ref, credential, { invocation_id, retention_id, actor_ref, intent_instant: now,
        hold_check_result: hold }, "caller");                                                                                // Action wiring 76
      if (!("landed" in i)) return this.intentFailure(i);
      const p = retentionWindow.purge(this.db, this.seam, this.f, retention_id);                                            // 58
      if ("refused" in p) {
        if (p.refused === "storage-failure") return { refused: "storage-failure" };                                         // 67; Atomic writes 8
        return { refused: p.refused === "retention-period-not-elapsed" ? "not-eligible" : "not-known" };                    // 64 through 66
      }
      const dispositions = siblings.map((s) => {                                                                             // 59, 61, 62, 68
        const r = retentionWindow.purge(this.db, this.seam, this.f, s.retention_id);
        return { retention_id: s.retention_id, disposition: "refused" in r && r.refused === "storage-failure" ? "pending" : "purged" };
      });
      for (const id of [retention_id, ...dispositions.filter((d) => d.disposition === "purged").map((d) => d.retention_id)]) this.indexDrop(id);  // 69; Composition state 5 through 8
      const o = this.outcome("record_purged", actor_ref, credential, { invocation_id, retention_id, record_ref, purged_retention_ids: dispositions,
        hold_check_result: hold, ...(override ? { hold_override: true } : {}), purge_instant: now });                       // 60
      return "ok" in o ? { ok: "ok" } : o;                                                                                    // 63
    } finally { this.release(`record:${record_ref}`); }
  }

  // ---- the sweep (Reconciliation 1 through 27) ----
  sweep(): void {
    const now = Date.parse(this.seam.now());
    const sa = this.c.serviceActor, sc = this.c.serviceCredential;
    const svc = (action: string, data: Record<string, unknown>) => "landed" in this.write(action, sa, sc, data, "sweep");   // Composes 16, 17
    const open = () => {
      const evs = this.events().filter((e) => e.data !== null);                                                             // Reconciliation 23
      const closed = new Set(evs.filter((e) => OUTCOMES.includes(e.action_ref!)).map((e) => e.data!.invocation_id));      // 6, 7
      return { evs, markers: evs.filter((e) => INTENTS.includes(e.action_ref as IntentName) && !closed.has(e.data!.invocation_id)) };  // 5
    };
    const store = () => retentionWindow.read(this.db, this.seam);
    const holds = () => (legalHold.read(this.db, this.f, {}) as { ok: Hold[] }).ok;
    for (const m of open().markers) {
      const d = m.data!, inv = String(d.invocation_id);
      if (Date.parse(String(d.intent_instant)) + this.c.retentionCompletionBoundMs > now) continue;                        // 4
      this.take(`act:${inv}`);                                                                                              // 20
      try {
        const { evs, markers } = open();                                                                                     // 21, 22
        if (!markers.some((x) => x.data!.invocation_id === inv)) continue;
        const outs = evs.filter((e) => OUTCOMES.includes(e.action_ref!));
        const act = this.actOf(m, evs, outs, store(), holds());                                                              // 8
        if (act === null) { svc("intent_abandoned", { invocation_id: inv, act: "not-committed" }); continue; }              // 9, 10
        const candidates = markers.filter((x) => x.action_ref === m.action_ref && this.actOf(x, evs, outs, store(), holds())?.key === act.key)
          .sort((a, b) => a.seq - b.seq);                                                                                    // 12
        if (candidates[0].data!.invocation_id !== inv) continue;                                                            // the earliest marker's leg writes it
        const outcome = act.outcome();
        if (outcome === null) { svc("intent_abandoned", { invocation_id: inv, act: "datum-missing" }); continue; }          // 26, 27
        if (!svc(RECOVERY, { invocation_id: inv, leg: m.action_ref, plan: act.key })) continue;                            // 17, 18
        act.commit?.();                                                                                                      // 19
        svc(INTENT_OUTCOME[m.action_ref as IntentName], { ...act.outcome()!, invocation_id: inv, recovery: true,           // 11, 13 through 16
          attributed_actors: candidates.map((x) => x.actor_ref), acting_actor: m.actor_ref });
      } finally { this.release(`act:${inv}`); }
    }
    // Pending siblings a landed destruction named (Reconciliation 19; Check 3.3).
    for (const e of open().evs.filter((e) => e.action_ref === "record_purged")) {
      const pending = (e.data!.purged_retention_ids as { retention_id: string; disposition: string }[]).filter((p) => p.disposition === "pending")
        .filter((p) => store().find((r) => r.retention_id === p.retention_id)?.state === "retained");
      if (pending.length === 0) continue;
      const inv = String(e.data!.invocation_id);
      this.take(`act:${inv}`);
      try {
        if (!svc(RECOVERY, { invocation_id: inv, leg: "pending-sibling", plan: pending.map((p) => p.retention_id) })) continue;
        for (const p of pending) if (!("refused" in retentionWindow.purge(this.db, this.seam, this.f, p.retention_id))) this.indexDrop(p.retention_id);
      } finally { this.release(`act:${inv}`); }
    }
    for (const m of open().markers)                                                                                          // 25
      if (Date.parse(String(m.data!.intent_instant)) + this.c.compensationWindowMs < now) this.alert("escalation", String(m.data!.invocation_id));
  }

  // The act an open marker names, read from the constituent store (Reconciliation 8): its key, and the outcome a recovery would carry.
  private actOf(m: Ev, evs: Ev[], outs: Ev[], store: RetentionRecord[], holds: Hold[]):
    { key: string; outcome: () => Record<string, unknown> | null; commit?: () => void } | null {
    const d = m.data!, at = String(d.intent_instant);
    const named = (k: string) => new Set(outs.filter((o) => o.action_ref === INTENT_OUTCOME[m.action_ref as IntentName]).map((o) => String(o.data![k])));
    switch (m.action_ref as IntentName) {
      case "retention_placement_intended": {
        const r = store.find((r) => r.record_ref === d.record_ref && r.policy_ref === d.policy_ref && !(r.retained_at < at) && !named("retention_id").has(r.retention_id));
        return r ? { key: r.retention_id, outcome: () => ({ retention_id: r.retention_id, record_ref: r.record_ref, policy_ref: r.policy_ref,
          retention_deadline: r.retention_deadline, purge_deadline: r.purge_deadline }) } : null;
      }
      case "hold_placement_intended": {
        const h = holds.find((h) => h.record_ref === d.record_ref && h.placed_by === d.placed_by && h.reason === d.reason && h.case_ref === d.case_ref &&
          (d.placed_at === null || h.placed_at === d.placed_at) && !named("hold_id").has(h.hold_id));
        return h ? { key: h.hold_id, outcome: () => ({ hold_id: h.hold_id, record_ref: h.record_ref, placed_by: h.placed_by, reason: h.reason,
          case_ref: h.case_ref, placed_at: h.placed_at }) } : null;
      }
      case "hold_release_intended": {
        const h = holds.find((h) => h.hold_id === d.hold_id && h.state === "released" && !named("hold_id").has(h.hold_id));
        return h ? { key: h.hold_id, outcome: () => ({ hold_id: h.hold_id, reason: h.release_reason, released_at: h.released_at }) } : null;
      }
      case "purge_intended": {
        const r = store.find((r) => r.retention_id === d.retention_id && r.state === "purged" && !named("retention_id").has(r.retention_id));
        if (!r) return null;
        const siblings = store.filter((s) => s.record_ref === r.record_ref && s.retention_id !== r.retention_id && (s.state === "retained" || !(s.purged_at! < at)));
        void evs;
        return { key: r.retention_id,
          outcome: () => {
            const hold = d.hold_check_result as { count: number } | undefined;                                               // Action wiring 76
            if (hold === undefined) return null;                                                                              // Reconciliation 27
            return { retention_id: r.retention_id, record_ref: r.record_ref, purged_retention_ids: siblings.map((s) => ({ retention_id: s.retention_id, disposition: "purged" })),
              hold_check_result: hold, ...(hold.count > 0 ? { hold_override: true } : {}), purge_instant: at };             // the invocation's one reading
          },
          commit: () => { for (const s of siblings) if (s.state === "retained" && !("refused" in retentionWindow.purge(this.db, this.seam, this.f, s.retention_id))) this.indexDrop(s.retention_id); } };
      }
    }
  }
}

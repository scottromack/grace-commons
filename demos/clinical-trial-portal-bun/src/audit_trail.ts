// Audit Trail — the regulated-audit substrate, to the depth Login reaches: [Record Action].
// Rendered from compositions/audit-trail.md (the page at the commit the entry names), with no code of
// any other render opened. A rule's label is in the comment where the code answers it.
//
// [Record Action] validates the primitives, attests the actor, appends the event, places the retention,
// and links the three in the derived indexes. Steps 2 to 4 commit in one transaction (Execution
// Contract Database 1); the indexes are derived and sit outside it (Composition state 1), so a failed
// index write never rejects the action (step 5.10). What the page keeps on a non-storage refusal at
// step 3 or 4 is written in the refusal's own transaction (step 7.11): the attestation, and at step 4
// the event too, with their ids carried on the refusal.
//
// Not rendered here, said so and not hidden: [Seal Now] and its sealing lock (Lease), [Read Record],
// [Verify Record], [Record Destruction], the reconciliation scan and Defensible Retention. They are
// the audit surface of the portal, rendered with it; Login reaches none of them.
import { Store, Guard, type Row } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { EventLog } from "./event_log.ts";
import { ActorIdentity } from "./actor_identity.ts";
import { RetentionWindow } from "./retention_window.ts";

export type RecordRefusal =
  | { refused: "invalid-credential" }
  | { refused: "invalid-request"; step: "step-1" | "step-2" | "step-3" | "step-4"; committed_ids: string[] }
  | { refused: "recording-failure"; step: "step-2" | "step-3" | "step-4" };

export interface AuditTrailConfig {
  /** A Retention Window policy reference, or a selector (action_ref, actor_ref, data) → policy_ref (Term retention policy). */
  retentionPolicy: string | ((action_ref: string, actor_ref: string, data: unknown) => string);
  /** The actor reference of the reconciliation path, the only caller that may record under the reserved namespace (Primitive policy 8). */
  reconciliationOperator: string;
}

const T = "audit_index";
const COLUMNS = ["attestation_id", "retention_id", "sequence_number"];
const RESERVED = "audit.";
const RECONCILIATION_REFS = ["audit.compensation", "audit.reconciliation"];

export class AuditTrail {
  private constructor(
    private store: Store,
    private seam: Seam,
    readonly log: EventLog,
    readonly actors: ActorIdentity,
    readonly retention: RetentionWindow,
    private cfg: AuditTrailConfig,
  ) {}

  static async open(store: Store, seam: Seam, parts: { log: EventLog; actors: ActorIdentity; retention: RetentionWindow }, cfg: AuditTrailConfig): Promise<AuditTrail> {
    await store.declare(T, COLUMNS);
    return new AuditTrail(store, seam, parts.log, parts.actors, parts.retention, cfg);
  }

  /** Step 1: the primitives, before any constituent is called (Primitive policy 3, 4). Nothing is recorded on a refusal (step 1.3). */
  private step1(action_ref: string, actor_ref: string, data: unknown): boolean {
    if (isBlank(action_ref) || isBlank(actor_ref)) return false;                                              // Primitive policy 1, 2, 5
    const reserved = action_ref.startsWith(RESERVED);                                                          // Primitive policy 7: byte-identity, `Audit.` is not reserved
    if (reserved && actor_ref !== this.cfg.reconciliationOperator) return false;                              // Primitive policy 8
    if (reserved && !RECONCILIATION_REFS.includes(action_ref)) return false;                                  // Primitive policy 9a
    if (reserved) {                                                                                           // step 1.4: a reconciliation payload names its subject
      const d = data as { subject?: unknown; id?: unknown } | null;
      if (!d || (d.subject !== "attestation" && d.subject !== "event")) return false;                        // step 1.4a (the page names the field `subject`)
      if (isBlank(d.id)) return false;                                                                        // step 1.4b (the page does not name the id's field; this render calls it `id`)
    }
    // step 1.2, Primitive policy 21, 22: the envelope sized with the attestation id's width. Data is not canonicalized for the log twice: the log does it.
    const probe = canonical({ action_ref, actor_ref, attestation_id: this.seam.idMaterial(), data: data ?? null });
    return new TextEncoder().encode(probe).length <= this.log.payloadCap;
  }

  private policyFor(action_ref: string, actor_ref: string, data: unknown): string {
    const p = this.cfg.retentionPolicy;
    return typeof p === "function" ? p(action_ref, actor_ref, data) : p;                                      // Primitive policy 17: only a selector reads data
  }

  async recordAction(action_ref: string, actor_ref: string, credential: string, data?: unknown): Promise<{ event_id: string } | RecordRefusal> {
    if (!this.step1(action_ref, actor_ref, data)) return { refused: "invalid-request", step: "step-1", committed_ids: [] }; // step 1, 7.10
    for (let attempt = 0; attempt < 50; attempt++) {
      // Step 2: attest. The credential is consumed here and nowhere else (Primitive policy 10 to 14).
      const att = await this.actors.plan(action_ref, actor_ref, credential);
      if ("refused" in att) {
        if (att.refused === "invalid-credential") return { refused: "invalid-credential" };                    // step 2.2: unchanged
        if (att.refused === "invalid-request") return { refused: "invalid-request", step: "step-2", committed_ids: [] }; // step 2.3
        return { refused: "recording-failure", step: "step-2" };                                              // step 2.4, 2.14: storage and registry; a mechanism that cannot answer is read the same way
      }
      // Step 3: append the full constructed payload (step 3.1); the log stamps the instant (step 3.2).
      const payload = { action_ref, actor_ref, attestation_id: att.attestation_id, data: data ?? null };
      const ev = await this.log.plan([payload]);
      if ("refused" in ev) {                                                                                  // step 3.4: invalid-payload
        await this.keep(att.stmts);                                                                           // step 7.11: the attestation stays committed
        return { refused: "invalid-request", step: "step-3", committed_ids: [att.attestation_id] };           // step 7.15
      }
      const event_id = ev.event_ids[0];
      // Step 4: place the retention, record reference the event id (step 4.3).
      const ret = await this.retention.plan(event_id, this.policyFor(action_ref, actor_ref, data));
      if ("refused" in ret) {
        if (ret.refused === "invalid-request" || ret.refused === "invalid-policy" || ret.refused === "policy-not-found") {
          await this.keep([...att.stmts, ...ev.stmts]);                                                       // step 7.11: the attestation and the event stay committed
          return { refused: "invalid-request", step: "step-4", committed_ids: [att.attestation_id, event_id] }; // step 4.5, 4.6, 7.16
        }
        return { refused: "recording-failure", step: "step-4" };                                              // step 4.8, 4.10: storage and registry; nothing committed
      }
      try {
        await this.store.commit([...att.stmts, ...ev.stmts, ...ret.stmts]);                                   // Database 1: the three writes of one action
      } catch (e) {
        if (e instanceof Guard) continue;                                                                     // another event landed first: plan again
        return { refused: "recording-failure", step: "step-3" };                                              // the joint write failed; the page names no finer step for it
      }
      // Step 5: the indexes, derived and outside the action's atomicity; a failure here is a rebuild trigger and never a refusal (5.9, 5.10).
      try {
        await this.store.commit([this.store.put(T, { _id: event_id, attestation_id: att.attestation_id, retention_id: ret.retention_id, sequence_number: ev.sequence_numbers[0] })]);
      } catch { /* rebuilt on a miss */ }
      return { event_id };                                                                                    // step 7.1
    }
    return { refused: "recording-failure", step: "step-3" };
  }

  /** What an invalid-request(step-3) or (step-4) refusal keeps, written in the refusal's own transaction (step 7.11, 7.12). */
  private async keep(stmts: import("./store.ts").Stmt[]): Promise<void> {
    try { await this.store.commit(stmts); } catch { /* the refusal still answers; the partial state is what the committed ids name */ }
  }

  /** The derived index entry for an event, or null on a miss (Composition state 2; the rebuild is not rendered here). */
  async indexOf(event_id: string): Promise<{ attestation_id: string; retention_id: string; sequence_number: number } | null> {
    const r = (await this.store.read<Row & { attestation_id: string; retention_id: string; sequence_number: number | string }>(`SELECT * FROM ${T} WHERE _id = $1`, [event_id]))[0];
    return r ? { attestation_id: r.attestation_id, retention_id: r.retention_id, sequence_number: Number(r.sequence_number) } : null;
  }
}

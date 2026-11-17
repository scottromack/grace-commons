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
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { EventLog } from "./event_log.ts";
import { ActorIdentity } from "./actor_identity.ts";
import { RetentionWindow } from "./retention_window.ts";
import { TamperEvidence } from "./tamper_evidence.ts";
import { LeaseHost } from "./lease.ts";

export type RecordRefusal =
  | { refused: "invalid-credential" }
  | { refused: "invalid-request"; step: "step-1" | "step-2" | "step-3" | "step-4"; committed_ids: string[] }
  | { refused: "recording-failure"; step: "step-2" | "step-3" | "step-4" };

export interface AuditTrailConfig {
  /** A Retention Window policy reference, or a selector (action_ref, actor_ref, data) → policy_ref (Term retention policy). */
  retentionPolicy: string | ((action_ref: string, actor_ref: string, data: unknown) => string);
  /** The actor reference of the reconciliation path, the only caller that may record under the reserved namespace (Primitive policy 8). */
  reconciliationOperator: string;
  /** The sealing: the instance's Tamper Evidence and the host of its sealing lock, the mechanism credential passed through unchanged (mechanism credential 1 to 3), the slice cap and the lock's term. Absent where the deployment seals nothing. */
  sealing?: { tamper: TamperEvidence; lease: LeaseHost; mechanismCredential: string; sliceCap?: number; lockTermMs?: number; unsealedTailMode?: "strict" | "lenient" };
}

/** The record set a slice names: the byte-exact payloads of its events, in ascending sequence order (Term verify-time presentation). */
export const sliceRef = (first: number, last: number, count: number) => `slice:${first}-${last}:${count}`;
/** Record set match for Tamper Evidence: no only where the presented set's count of events differs from the count the slice reference carries (Capability requirement 6, 6a, 6b). */
export const matchBySliceCount = (ref: string, original: unknown): boolean => Array.isArray(original) && original.length === Number(/:(\d+)$/.exec(ref)?.[1]);

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
    if (cfg.sealing) {                                                                                         // the seal coverage and the uncovered mark exist before the first read of either
      await store.declare("seal_coverage", ["log_name", "first_seq", "last_seq", "slice_ref", "count"]);
      await store.declare("uncovered_mark", ["state", "holder"]);
    }
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

  /**
   * Steps 1 to 4 as statements, to commit alone (`recordAction`) or beside the other writes of one action
   * (a composing pattern's own transaction, Database 1), or the refusal with what step 7.11 keeps. The
   * index write of step 5 is `indexStmt`, to run after the commit (Composition state 1).
   */
  async plan(action_ref: string, actor_ref: string, credential: string, data?: unknown): Promise<
    | { event_id: string; stmts: Stmt[]; indexStmt: Stmt }
    | { refusal: RecordRefusal; keep: Stmt[] }
  > {
    if (!this.step1(action_ref, actor_ref, data)) return { refusal: { refused: "invalid-request", step: "step-1", committed_ids: [] }, keep: [] }; // step 1, 7.10
    // Step 2: attest. The credential is consumed here and nowhere else (Primitive policy 10 to 14).
    const att = await this.actors.plan(action_ref, actor_ref, credential);
    if ("refused" in att) {
      if (att.refused === "invalid-credential") return { refusal: { refused: "invalid-credential" }, keep: [] };                  // step 2.2: unchanged
      if (att.refused === "invalid-request") return { refusal: { refused: "invalid-request", step: "step-2", committed_ids: [] }, keep: [] }; // step 2.3
      return { refusal: { refused: "recording-failure", step: "step-2" }, keep: [] };                                              // step 2.4, 2.14: storage and registry; a mechanism that cannot answer is read the same way
    }
    // Step 3: append the full constructed payload (step 3.1); the log stamps the instant (step 3.2).
    const payload = { action_ref, actor_ref, attestation_id: att.attestation_id, data: data ?? null };
    const ev = await this.log.plan([payload]);
    if ("refused" in ev) {                                                                                  // step 3.4: invalid-payload
      return { refusal: { refused: "invalid-request", step: "step-3", committed_ids: [att.attestation_id] }, keep: att.stmts };   // step 7.11, 7.15
    }
    const event_id = ev.event_ids[0];
    // Step 4: place the retention, record reference the event id (step 4.3).
    const ret = await this.retention.plan(event_id, this.policyFor(action_ref, actor_ref, data));
    if ("refused" in ret) {
      if (ret.refused === "invalid-request" || ret.refused === "invalid-policy" || ret.refused === "policy-not-found")
        return { refusal: { refused: "invalid-request", step: "step-4", committed_ids: [att.attestation_id, event_id] }, keep: [...att.stmts, ...ev.stmts] }; // step 4.5, 4.6, 7.11, 7.16
      return { refusal: { refused: "recording-failure", step: "step-4" }, keep: [] };                      // step 4.8, 4.10: storage and registry; nothing committed
    }
    return {
      event_id,
      stmts: [...att.stmts, ...ev.stmts, ...ret.stmts],                                                   // Database 1: the three writes of one action
      indexStmt: this.store.put(T, { _id: event_id, attestation_id: att.attestation_id, retention_id: ret.retention_id, sequence_number: ev.sequence_numbers[0] }),
    };
  }

  /** Step 5: the indexes, derived and outside the action's atomicity; a failure is a rebuild trigger and never a refusal (5.9, 5.10). */
  async index(indexStmt: Stmt): Promise<void> {
    try { await this.store.commit([indexStmt]); } catch { /* rebuilt on a miss */ }
  }

  async recordAction(action_ref: string, actor_ref: string, credential: string, data?: unknown): Promise<{ event_id: string } | RecordRefusal> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.plan(action_ref, actor_ref, credential, data);
      if ("refusal" in p) {
        if (p.keep.length) await this.keep(p.keep);                                                       // step 7.11: what the refusal keeps is written in its own transaction
        return p.refusal;
      }
      try {
        await this.store.commit(p.stmts);
      } catch (e) {
        if (e instanceof Guard) continue;                                                                 // another event landed first: plan again
        return { refused: "recording-failure", step: "step-3" };                                          // the joint write failed; the page names no finer step for it
      }
      await this.index(p.indexStmt);
      return { event_id: p.event_id };                                                                    // step 7.1
    }
    return { refused: "recording-failure", step: "step-3" };
  }

  /** What an invalid-request(step-3) or (step-4) refusal keeps, written in the refusal's own transaction (step 7.11, 7.12). */
  private async keep(stmts: Stmt[]): Promise<void> {
    try { await this.store.commit(stmts); } catch { /* the refusal still answers; the partial state is what the committed ids name */ }
  }

  sealNow() { return sealNowImpl.call(this); }
  readRecord(event_id: string) { return readRecordImpl.call(this, event_id); }
  verifyRecord(event_id: string, original_event_payload: unknown) { return verifyRecordImpl.call(this, event_id, original_event_payload); }

  /** The derived index entry for an event, or null on a miss (Composition state 2; the rebuild is not rendered here). */
  async indexOf(event_id: string): Promise<{ attestation_id: string; retention_id: string; sequence_number: number } | null> {
    const r = (await this.store.read<Row & { attestation_id: string; retention_id: string; sequence_number: number | string }>(`SELECT * FROM ${T} WHERE _id = $1`, [event_id]))[0];
    return r ? { attestation_id: r.attestation_id, retention_id: r.retention_id, sequence_number: Number(r.sequence_number) } : null;
  }
}

// ---------------------------------------------------------------------------------------------------------
// [Seal Now], [Read Record], [Verify Record]: the audit surface of the portal. Rendered from the same page.
// Not rendered, said so: [Record Destruction] and the purged-event paths of both reads (Beacon wires no Defensible
// Retention, so no destruction record exists), the reconciliation scan, rebuild of the ranges from the seal records
// (the uncovered mark is set and cleared, and a stale mark is read as a reason to take the coverage as it stands).
// ---------------------------------------------------------------------------------------------------------
import { type LoggedEvent } from "./event_log.ts";

type Seal = NonNullable<AuditTrailConfig["sealing"]>;
export type AuditRecord = {
  event_id: string; sequence_number: number; recorded_at: string; action_ref: string; actor_ref: string; data: unknown;
  attestation_id: string; retention: { retention_id: string; policy_ref: string; state: "retained" | "purged"; retention_until: string } | "unresolved";
  coverage: { status: "covered"; evidence_id: string; first: number; last: number; sealed_at: string } | { status: "unsealed-tail" };
};
export type VerifyOutcome = "verified" | { failed: string } | { unverifiable: string };

const COV = "seal_coverage";
const MARK = "uncovered_mark";

function sealing(at: AuditTrail): Seal {
  const s = (at as unknown as { cfg: AuditTrailConfig }).cfg.sealing;
  if (!s) throw new Error("this Audit Trail instance seals nothing");
  return s;
}
const priv = (at: AuditTrail) => at as unknown as { store: Store; seam: Seam };

async function covering(at: AuditTrail, seq: number) {
  const rows = await priv(at).store.read<Row & { first_seq: number | string; last_seq: number | string; evidence_id: string }>(`SELECT _id AS evidence_id, first_seq, last_seq FROM ${COV} WHERE log_name = $1`, [at.log.logName]);
  return rows.map((r) => ({ evidence_id: r.evidence_id, first: Number(r.first_seq), last: Number(r.last_seq) })).find((r) => seq >= r.first && seq <= r.last) ?? null;
}
async function sealedThrough(at: AuditTrail): Promise<number> {
  const rows = await priv(at).store.read<Row & { last_seq: number | string }>(`SELECT last_seq FROM ${COV} WHERE log_name = $1`, [at.log.logName]);
  return rows.reduce((m, r) => Math.max(m, Number(r.last_seq)), 0);                                          // Term sealed through: the maximum over the coverage ranges, zero for none
}

export async function sealNowImpl(this: AuditTrail) {
  const cfg = sealing(this);
  const { store, seam } = priv(this);
  await store.declare(COV, ["log_name", "first_seq", "last_seq", "slice_ref", "count"]);
  await store.declare(MARK, ["state", "holder"]);
  const key = `sealing:${this.log.logName}`;
  const holder = seam.idMaterial();                                                                          // Identity 6 of Lease: a fresh holder for every take
  const got = await cfg.lease.take(key, holder, cfg.lockTermMs ?? 30_000);                                   // seal now 17: the sealing lock serializes read, seal, advance
  if (got === "unavailable") return { refused: "recording-failure" };                                        // seal now 20
  const live = async () => (await cfg.lease.remaining(key, holder)) !== "none";                              // seal now 19, 25: an expired lease writes nothing more
  try {
    const sealed = await sealedThrough(this);                                                                // seal now 1, 17: read from the coverage ranges under the lock, never a cache (18)
    const cap = cfg.sliceCap ?? 1000;
    const read = await this.log.read({ sequence: { from: sealed + 1, to: sealed + cap } });                  // Term slice read: through (sealed through + slice cap)
    if (!Array.isArray(read)) return { refused: "invalid-request" };
    const events = read as LoggedEvent[];
    if (events.length === 0) return { refused: "nothing-to-seal" };                                          // seal now 3
    const first = events[0].sequence_number, last = events[events.length - 1].sequence_number;
    const ref = sliceRef(first, last, events.length);                                                        // seal coverage 13, 14: first, last and the count
    if (!(await live())) return { refused: "recording-failure" };
    await store.commit([store.put(MARK, { _id: `mark:${this.log.logName}`, state: "set", holder })]);                            // seal now 15, 22: the mark is set, with this holder, before the seal call
    const made = await cfg.tamper.seal(ref, cfg.mechanismCredential, events.map((e) => canonical(e.data)));  // seal now 4; mechanism credential 1, 2: passed unchanged
    if ("mechanism_failure" in made) {
      await store.commit([store.assertSome(MARK, "_id = $2 AND holder = $1", [holder, `mark:${this.log.logName}`], "mark-moved"), store.put(MARK, { _id: `mark:${this.log.logName}`, state: "clear", holder })]);   // seal now 16: a rejection that wrote no evidence clears the mark
      return { refused: "mechanism-failure", reason: made.mechanism_failure };                              // seal now 6
    }
    if ("refused" in made) {
      await store.commit([store.put(MARK, { _id: `mark:${this.log.logName}`, state: "clear", holder })]);
      return made.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "recording-failure" };   // seal now 7, 8
    }
    if (!(await live())) return { refused: "recording-failure" };                                            // seal now 19, 20: the evidence landed, the coverage is not written; the mark stays set
    try {
      await store.commit([store.put(COV, { _id: made.evidence_id, log_name: this.log.logName, first_seq: first, last_seq: last, slice_ref: ref, count: events.length })]);   // seal now 5: the coverage entry and the advance of sealed through
    } catch {
      return { refused: "recording-failure" };                                                               // seal now 14: the mark stays set
    }
    await store.commit([store.assertSome(MARK, "_id = $2 AND holder = $1", [holder, `mark:${this.log.logName}`], "mark-moved"), store.put(MARK, { _id: `mark:${this.log.logName}`, state: "clear", holder })]).catch(() => {});   // seal now 16, 23: cleared by a compare against this holder
    return { evidence_id: made.evidence_id };
  } finally {
    await cfg.lease.release(key, holder);                                                                    // seal now 21
  }
}

/** An id the index lacks is looked up in the whole log once (rebuild-on-miss, Composition state 2, 3). */
async function resolve(at: AuditTrail, event_id: string): Promise<{ seq: number; event: LoggedEvent } | null> {
  let idx = await at.indexOf(event_id);
  const all = await at.log.read({ sequence: { from: 1 } });
  if (!Array.isArray(all)) return null;
  const events = all as LoggedEvent[];
  const ev = idx ? events.find((e) => e.sequence_number === idx!.sequence_number) : events.find((e) => e.event_id === event_id);
  return ev ? { seq: ev.sequence_number, event: ev } : null;
}

export async function readRecordImpl(this: AuditTrail, event_id: string): Promise<AuditRecord | "not-known"> {
  const hit = await resolve(this, event_id);                                                                 // read record step 2: event to sequence 4, 5
  const ret = (await this.retention.read()).find((r) => r.record_ref === event_id) ?? null;                   // step 1
  if (!hit && !ret) return "not-known";                                                                      // step 3.1
  if (!hit) return "not-known";                                                                              // a retention with no log entry is a deployment fault (3.3), the record cannot be assembled
  const d = hit.event.data as unknown as { action_ref: string; actor_ref: string; attestation_id: string; data: unknown };
  const cov = (await covering(this, hit.seq));
  const sealed = sealing_or_null(this) ? await sealedThrough(this) : 0;
  void sealed;
  return {                                                                                                   // step 4.1 to 4.3, 5.1: a live event; no retention record is the orphan window and none is made up (5.2)
    event_id, sequence_number: hit.seq, recorded_at: hit.event.recorded_at, action_ref: d.action_ref, actor_ref: d.actor_ref, data: d.data, attestation_id: d.attestation_id,
    retention: ret ? { retention_id: ret.retention_id, policy_ref: ret.policy_ref, state: ret.state, retention_until: ret.retention_until } : "unresolved",
    coverage: cov ? { status: "covered", evidence_id: cov.evidence_id, first: cov.first, last: cov.last, sealed_at: ((await sealing_or_null(this)?.tamper.read()) ?? []).find((e) => e.evidence_id === cov.evidence_id)?.sealed_at ?? "" } : { status: "unsealed-tail" },
  } as AuditRecord;                                                                                          // read record 1 to 4: no state change, no event, no verification
}
function sealing_or_null(at: AuditTrail) { return (at as unknown as { cfg: AuditTrailConfig }).cfg.sealing ?? null; }

export async function verifyRecordImpl(this: AuditTrail, event_id: string, original_event_payload: unknown): Promise<{ outcome: VerifyOutcome; qualifier?: "compensation-window" } | "not-known"> {
  const cfgS = sealing(this);
  const retNow = async () => (await this.retention.read()).find((r) => r.record_ref === event_id) ?? null;
  const ret = await retNow();
  if (ret?.state === "purged") return { outcome: { failed: "purged" } };                                    // step 1.2
  const hit = await resolve(this, event_id);                                                                 // step 2.1
  if (!ret && !hit) return "not-known";                                                                      // step 2.2
  const qualifier = !ret ? ("compensation-window" as const) : undefined;                                     // step 2.3: a log entry with no retention proceeds and carries the qualifier beside the outcome
  const finish = async (outcome: VerifyOutcome) => {
    if (typeof outcome !== "string" && (await retNow())?.state === "purged") return { outcome: { failed: "purged" } };   // verify record 5, 6: a failure re-reads the retention first
    return qualifier ? { outcome, qualifier } : { outcome };                                                  // verify record 1 to 3: the qualifier rides its own channel
  };
  if (!hit) return finish({ unverifiable: "event-log-unavailable" });
  const d = hit.event.data as unknown as { attestation_id: string };
  const att = await this.actors.verify(d.attestation_id);                                                    // step 3.1: on event to attestation's entry
  if (att === "not-known") return finish({ failed: "attestation-not-known" });                               // step 3.4
  if (typeof att === "object") {
    if (att.failed === "registry-unavailable") return finish({ unverifiable: "attestation-registry-unavailable" });   // step 3.3, 6.1: steps 4 and 5 do not run
    return finish({ failed: `attestation-${att.failed}` });                                                  // step 3.2, 3.6
  }
  const cov = await covering(this, hit.seq);                                                                 // step 4.1
  if (!cov) {
    if ((cfgS.unsealedTailMode ?? "strict") === "strict") return finish({ failed: "unsealed" });             // step 4.4: unsealed tail mode strict, the default
    return finish("verified");                                                                               // step 4.5: lenient takes coverage as satisfied and skips the seal
  }
  const t = await cfgS.tamper.verify(cov.evidence_id, original_event_payload, cfgS.mechanismCredential);    // step 5.1: the presentation passed through unchanged (Primitive policy 25)
  if (t === "not-known") return finish({ failed: "seal-not-known" });                                        // step 5.4
  if (typeof t === "object") {
    if (t.failed === "mechanism-verification-unavailable") return finish({ unverifiable: "seal-mechanism-verification-unavailable" });   // step 5.3, 6.2
    return finish({ failed: `seal-${t.failed}` });                                                           // step 5.2
  }
  return finish("verified");                                                                                 // step 7.1, 7.2
}

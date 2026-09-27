// Multi-Party Approval, rendered from compositions/multi-party-approval.md.
// Every rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { approvalStep, assignment, permissions, type StepRecord, validStepQuery } from "./atoms.ts";
import type { AuditTrail, RecordAnswer } from "./audit_trail.ts";

export type Quorum = { rule: "all-of-N" } | { rule: "M-of-N"; m: number } | { rule: "one-of-N" };
export type ChainState = "Pending" | "Approved" | "Rejected" | "Withdrawn";
export type Position = "intent" | "outcome";
export type Refusal =
  | { refused: "permission-denied" | "invalid-request" | "invalid-credential" | "not-known" | "not-pending" | "unauthorized" | "invalid-query" }
  | { refused: "recording-failure"; position: Position };

export interface Config {
  approverSetMinimum: number;           // Capability requirement 1
  approverSetUniqueness: boolean;       // Capability requirement 2
  allowedQuorumRules: Quorum["rule"][]; // Capability requirement 3
  fieldLengthCap: number;               // Term field length cap
  idWidth: number;                      // Capability requirement 22
  decisionCompletionBoundMs: number;    // Capability requirement 7
  compensationWindowMs: number;         // Capability requirement 8
  reconciliationCadenceMs: number;      // Capability requirement 9
  outcomeWriteLatencyMs: number;        // Capability requirement 10
  auditHorizonMs: number;               // Term audit horizon
  serviceActor: string;                 // Capability requirement 12
  serviceCredential: string;
}

export const SCOPES = { initiate: "chains:initiate", withdraw: "chains:withdraw", read: "chains:read" } as const;  // Scope vocabulary 1

export interface ChainRecord {
  chain_id: string; subject_ref: string; scope: string; initiator_ref: string; approver_set: string[]; quorum_rule: Quorum;
  initiated_at: string; invocation_id: string; state: ChainState; terminal_at: string | null; audit_pending: boolean;
  landed_ids: { steps: string[]; assignments: string[] };
}
interface Invocation { id: string; now: string; actor?: string; credential?: string }
interface PartialCall { step_id: string; call: "recall" | "withdraw" }

export class MultiPartyApproval {
  readonly alerts: { kind: string; detail: string }[] = [];     // the deployment's alert surface
  readonly findings: { chain_id: string; marker: string }[] = []; // Reconciliation 32
  private held = new Set<string>();                               // the chain exclusion (Capability requirement 15 through 18)

  private constructor(private db: Database, private seam: Seam, private f: Faults, private audit: AuditTrail, readonly config: Config) {}

  // Capability requirement 11: the window must strictly exceed the liveness sum.
  static start(db: Database, seam: Seam, f: Faults, audit: AuditTrail, config: Config): MultiPartyApproval {
    const sum = config.decisionCompletionBoundMs + config.reconciliationCadenceMs + config.outcomeWriteLatencyMs;
    if (!(config.compensationWindowMs > sum)) throw new Error("compensation window does not exceed the liveness sum");
    return new MultiPartyApproval(db, seam, f, audit, config);
  }

  // ---- the exclusion ----
  holdForTest(chain_id: string) { this.held.add(chain_id); }
  releaseForTest(chain_id: string) { this.held.delete(chain_id); }
  private take(chain_id: string): boolean { if (this.held.has(chain_id)) return false; this.held.add(chain_id); return true; }
  private release(chain_id: string) { this.held.delete(chain_id); }

  // Capability requirement 19. The credential joins the invocation only once an intent
  // has validated it (Cascade 5: "the initiator's validated credential").
  private begin(actor?: string): Invocation {
    return { id: this.seam.id("invocation"), now: this.seam.now(), actor };
  }

  // ---- reads over the composition's own stores ----
  chain(chain_id: string): ChainRecord | undefined {
    const r = this.db.prepare("SELECT * FROM chain WHERE chain_id = ?").get<Record<string, unknown>>(chain_id);
    return r ? toChain(r) : undefined;
  }
  chains(): ChainRecord[] {
    return this.db.prepare("SELECT * FROM chain ORDER BY initiated_at, chain_id").all<Record<string, unknown>>().map(toChain);
  }
  stepList(chain_id: string): string[] {
    return this.db.prepare("SELECT step_id FROM chain_step WHERE chain_id = ? ORDER BY pos").all<{ step_id: string }>(chain_id).map((r) => r.step_id);
  }
  stepChain(step_id: string): string | undefined {
    return this.db.prepare("SELECT chain_id FROM step_chain WHERE step_id = ?").get<{ chain_id: string }>(step_id)?.chain_id;
  }
  stepAssignment(step_id: string): string | undefined {
    return this.db.prepare("SELECT assignment_id FROM step_assignment WHERE step_id = ?").get<{ assignment_id: string }>(step_id)?.assignment_id;
  }
  eventIndex(chain_id: string): { event_id: string; step_id: string | null }[] {
    return this.db.prepare("SELECT event_id, step_id FROM event_index WHERE chain_id = ? ORDER BY ord").all(chain_id);
  }

  // ---- the audit write and its arms ----
  private index(chain_id: string, event_id: string, step_id: string | null = null) {
    const ord = (this.db.prepare("SELECT COALESCE(MAX(ord), -1) + 1 AS n FROM event_index WHERE chain_id = ?").get<{ n: number }>(chain_id)!).n;
    this.db.prepare("INSERT INTO event_index VALUES (?, ?, ?, ?)").run(chain_id, ord, event_id, step_id);  // Action wiring 57
  }
  private write(action_ref: string, actor: string, credential: string, data: Record<string, unknown>, chain_id?: string, step_id?: string | null): RecordAnswer {
    const r = this.audit.record_action(action_ref, actor, credential, data);
    if ("ok" in r && chain_id) this.index(chain_id, r.ok, step_id ?? null);
    return r;
  }
  private service(action_ref: string, data: Record<string, unknown>, chain_id: string, step_id?: string | null): RecordAnswer {
    const r = this.write(action_ref, this.config.serviceActor, this.config.serviceCredential, data, chain_id, step_id);
    if ("refused" in r && r.refused === "invalid-credential") this.alert("service-credential", action_ref);  // Reconciliation 33
    return r;
  }
  // Audit arm 1 through 5: an intent's refusal becomes the action's.
  private intentRefusal(r: RecordAnswer): Refusal | undefined {
    if ("ok" in r) return undefined;
    if (r.refused === "invalid-request") this.alert("audit-invalid-request", "intent");
    if (r.refused === "recording-failure") return { refused: "recording-failure", position: "intent" };
    return { refused: r.refused };
  }
  // Audit arm 6 through 13: an outcome lands, is read back, or fails; never retried here.
  private outcome(inv: Invocation, action_ref: string, actor: string, credential: string, data: Record<string, unknown>,
    chain_id: string, step_id: string | null = null): { landed: string } | Refusal {
    const r = this.write(action_ref, actor, credential, data, chain_id, step_id);
    if ("ok" in r) return { landed: r.ok };
    if (r.refused === "invalid-credential") return { refused: "invalid-credential" };
    if (r.refused === "invalid-request") this.alert("audit-invalid-request", action_ref);
    if (r.refused === "invalid-request" || (r.refused === "recording-failure" && r.step === "step-4")) {
      const back = this.audit.log_read().find((e) => e.envelope?.action_ref === action_ref && e.envelope.data.invocation_id === inv.id);
      if (back) { this.index(chain_id, back.event_id, step_id); return { landed: back.event_id }; }
    }
    return { refused: "recording-failure", position: "outcome" };
  }
  private alert(kind: string, detail: string) { this.alerts.push({ kind, detail }); }

  // ---- Primitive policy ----
  private refOk(r: string) { return r.trim() !== "" && new TextEncoder().encode(r).length <= this.audit.config.referenceCap; }
  private cappedOk(s: string) { return s.trim() !== "" && new TextEncoder().encode(s).length <= this.config.fieldLengthCap; }
  private fits(actor: string, ...payloads: Record<string, unknown>[]): boolean {          // Primitive policy 10
    const c = this.audit.config;
    const who = actor.length > this.config.serviceActor.length ? actor : this.config.serviceActor;
    return payloads.every((data) => JSON.stringify({ action_ref: "chain_initiation_failed", actor_ref: who,
      attestation_id: "x".repeat(c.attestationIdWidth), data }).length <= c.payloadCap);
  }
  private pad(prefix = "") { return prefix + "x".repeat(this.config.idWidth); }

  // ---- [Initiate Chain] (Action wiring 1 through 16) ----
  initiate_chain(actor_ref: string, credential: string, subject_ref: string, scope: string, approver_set: string[],
    quorum_rule: Quorum, reason?: string): { ok: string } | Refusal {
    const c = this.config;
    if (!this.refOk(actor_ref) || !approver_set.every((a) => this.refOk(a))) return { refused: "invalid-request" };  // Primitive policy 1, 2
    if (![subject_ref, scope, ...approver_set].every((s) => this.cappedOk(s))) return { refused: "invalid-request" }; // 3, 4
    if (approver_set.length < c.approverSetMinimum) return { refused: "invalid-request" };                              // 5
    if (c.approverSetUniqueness && new Set(approver_set).size !== approver_set.length) return { refused: "invalid-request" }; // 6
    if (!c.allowedQuorumRules.includes(quorum_rule.rule)) return { refused: "invalid-request" };                        // 7
    if (quorum_rule.rule === "M-of-N" && !(Number.isInteger(quorum_rule.m) && quorum_rule.m >= 1 && quorum_rule.m <= approver_set.length))
      return { refused: "invalid-request" };                                                                             // 8
    if (reason !== undefined && reason.trim() === "") return { refused: "invalid-request" };                            // see CORNERS.md
    const n = approver_set.length;
    const shapeSize = { chain_id: this.pad(), subject_ref, scope, initiator_ref: actor_ref, approver_set, quorum_rule,
      initiated_at: new Date(0).toISOString(), invocation_id: this.pad(), step_ids: Array(n).fill(this.pad()), assignment_ids: Array(n).fill(this.pad()) };
    if (!this.fits(actor_ref, { invocation_id: this.pad(), intent_event_id: this.pad(), chain_shape: shapeSize, reason: reason ?? null, disposition: "a",
      initiator_ref: actor_ref, recovery: true })) return { refused: "invalid-request" };                                 // 10

    if (permissions.permitted(this.db, actor_ref, SCOPES.initiate) === "denied") return { refused: "permission-denied" };  // Action wiring 1, 2
    const inv = this.begin(actor_ref);
    const intent = this.write("chain_initiation_intended", actor_ref, credential,
      { invocation_id: inv.id, subject_ref, scope, approver_set, quorum_rule, reason: reason ?? null, intended_at: inv.now });  // 3, 4
    const refused = this.intentRefusal(intent);
    if (refused) return refused;
    const intent_event_id = (intent as { ok: string }).ok;
    inv.credential = credential;

    const chain_id = this.seam.id("chain");                                                   // Capability requirement 20
    this.take(chain_id);                                                                      // Action wiring 5
    try {
      this.db.prepare(`INSERT INTO chain (chain_id, subject_ref, scope, initiator_ref, approver_set, quorum_rule, initiated_at, invocation_id, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending')`).run(chain_id, subject_ref, scope, actor_ref, JSON.stringify(approver_set),
        JSON.stringify(quorum_rule), inv.now, inv.id);                                        // 6
      this.index(chain_id, intent_event_id);                                                  // Term event rebuild: the intent against its chain
      const prefixed = `chain:${chain_id}` + (reason !== undefined ? `: ${reason}` : "");     // Term prefixed reason
      for (const approver of approver_set) {                                                  // 7, 8
        const s = approvalStep.submit(this.db, this.seam, this.f, subject_ref, approver, actor_ref, scope, prefixed);
        if ("refused" in s) return this.recoverInInvocation(inv, chain_id, "a", intent_event_id);  // 9
        this.land(chain_id, "steps", s.ok);
      }
      for (const step_id of this.stepList(chain_id)) {                                        // 10, 11
        const a = assignment.assign(this.db, this.seam, this.f, step_id, approvalStep.get(this.db, step_id)!.approver_ref);
        if ("refused" in a) {
          if (a.refused === "already-assigned") this.alert("id-reuse", step_id);              // 13
          return this.recoverInInvocation(inv, chain_id, "b", intent_event_id);               // 12
        }
        this.land(chain_id, "assignments", a.ok, step_id);
      }
      const out = this.outcome(inv, "chain_initiated", actor_ref, credential,
        { invocation_id: inv.id, intent_event_id, chain_id, chain_shape: this.shape(chain_id), reason: reason ?? null }, chain_id);  // 14
      if ("refused" in out) {
        this.recoverInInvocation(inv, chain_id, "c", intent_event_id);                        // 15
        return out;
      }
      return { ok: chain_id };                                                                // 16
    } finally { this.release(chain_id); }                                                     // Action wiring 58
  }

  private land(chain_id: string, kind: "steps" | "assignments", id: string, step_id?: string) {
    const c = this.chain(chain_id)!;
    c.landed_ids[kind].push(id);
    this.db.prepare("UPDATE chain SET landed_ids = ? WHERE chain_id = ?").run(JSON.stringify(c.landed_ids), chain_id);
    if (kind === "steps") {
      this.db.prepare("INSERT INTO chain_step VALUES (?, ?, ?)").run(chain_id, c.landed_ids.steps.length - 1, id);
      this.db.prepare("INSERT INTO step_chain VALUES (?, ?)").run(id, chain_id);
    } else this.db.prepare("INSERT INTO step_assignment VALUES (?, ?)").run(step_id!, id);
  }

  // Term chain shape: the declared fields, the ordered step ids, the paired assignment ids.
  private shape(chain_id: string) {
    const c = this.chain(chain_id)!;
    const steps = this.stepList(chain_id);
    return { chain_id, subject_ref: c.subject_ref, scope: c.scope, initiator_ref: c.initiator_ref, approver_set: c.approver_set,
      quorum_rule: c.quorum_rule, initiated_at: c.initiated_at, invocation_id: c.invocation_id,
      step_ids: steps, assignment_ids: steps.map((s) => this.stepAssignment(s) ?? null) };
  }

  // Action wiring 62: a recovery run inside the invocation answers at the outcome.
  private recoverInInvocation(inv: Invocation, chain_id: string, d: "a" | "b" | "c", intent_event_id: string): Refusal {
    this.initiationRecovery(inv, chain_id, d, intent_event_id);
    return { refused: "recording-failure", position: "outcome" };
  }

  // ---- the initiation recovery (Reconciliation 9 through 16) ----
  private initiationRecovery(inv: Invocation, chain_id: string, disposition: "a" | "b" | "c", intent_event_id?: string) {
    this.evaluate(inv, chain_id);                                                              // 9
    const c = this.chain(chain_id)!;
    if (c.state !== "Pending") {                                                               // 10: disposition d
      const r = this.service("chain_initiated", { invocation_id: inv.id, chain_id, chain_shape: this.shape(chain_id), disposition: "d", recovery: true }, chain_id);
      if ("ok" in r) this.db.prepare("UPDATE chain SET audit_pending = 0 WHERE chain_id = ?").run(chain_id);  // 16
      return;
    }
    this.db.prepare("UPDATE chain SET audit_pending = 1 WHERE chain_id = ?").run(chain_id);    // 11
    const failed = this.service("chain_initiation_failed", { invocation_id: inv.id, chain_id, chain_shape: this.shape(chain_id),
      disposition, initiator_ref: c.initiator_ref, intent_event_id: intent_event_id ?? null, recovery: true }, chain_id);  // 12
    if (!("ok" in failed)) return;                                                             // the marker stays for the sweep
    this.db.prepare("UPDATE chain SET audit_pending = 0 WHERE chain_id = ?").run(chain_id);    // 16
    this.db.prepare("UPDATE chain SET state = 'Withdrawn', terminal_at = ? WHERE chain_id = ?").run(inv.now, chain_id);  // 13
    const reason = `initiation-failed recovery (disposition ${disposition})`;                  // Term recovery reason
    const cascade = this.cascade(inv, chain_id, reason, this.chainlessSteps(chain_id));      // 13, 14; Cascade 5 and 6 pick the identity
    this.service("chain_withdrawn", { invocation_id: inv.id, chain_id, reason, terminal_at: inv.now, recovery: true,
      initiation_failed_event_id: failed.ok, ...partialFields(cascade.partial) }, chain_id);    // 15
  }

  // Term chainless step: Pending, same subject, submitter and scope, the chain's id in its reason, landed nowhere.
  private chainlessSteps(chain_id: string): string[] {
    const c = this.chain(chain_id)!;
    const landed = new Set(this.chains().flatMap((x) => x.landed_ids.steps));
    const r = approvalStep.read(this.db, { subject_ref: c.subject_ref, submitter_ref: c.initiator_ref, scope: c.scope, state: "pending" });
    return "ok" in r ? r.ok.filter((s) => (s.reason === `chain:${chain_id}` || (s.reason ?? "").startsWith(`chain:${chain_id}: `)) && !landed.has(s.step_id)).map((s) => s.step_id) : [];
  }

  // ---- the quorum rule (Wiring decision 1 through 9) ----
  // Term routed vector: counts over the step list, a step counted only through a routed transition.
  routedVector(chain_id: string): { A: number; R: number; W: number; P: number; N: number; outOfBand: string[] } {
    const steps = this.stepList(chain_id);
    let A = 0, R = 0, W = 0;
    const outOfBand: string[] = [];
    for (const step_id of steps) {
      const s = approvalStep.get(this.db, step_id)!;
      if (s.state === "pending") continue;
      if (!this.routed(chain_id, s)) { outOfBand.push(step_id); continue; }  // Wiring decision 7, 8
      if (s.state === "approved") A++; else if (s.state === "rejected") R++; else W++;
    }
    return { A, R, W, P: steps.length - A - R - W, N: steps.length, outOfBand };
  }

  // Term routed transition: a decision a decision intent pairs, by chain, step and decider;
  // or a cascade withdrawal a cascade step withdrawal event or a closure record names.
  private routed(chain_id: string, s: StepRecord): boolean {
    const decider = s.state === "withdrawn" ? s.withdrawn_by : s.decided_by;
    for (const e of this.eventIndex(chain_id).filter((x) => x.step_id === s.step_id)) {
      const r = this.audit.read_record(e.event_id);
      if (r === "not-known") continue;
      if (r.action_ref === "step_decision_intended" && r.actor_ref === decider &&
          (r.retention === "Purged" || (r.data?.chain_id === chain_id && r.data?.step_id === s.step_id))) return true;
      if (s.state === "withdrawn" && r.action_ref === "step_withdrawn" && r.data?.cascade === true) return true;
      if (s.state === "withdrawn" && r.action_ref === "cascade_completed") return true;
    }
    return false;
  }

  static quorum(q: Quorum, v: { A: number; R: number; W: number; N: number }): ChainState {
    const m = q.rule === "all-of-N" ? v.N : q.rule === "one-of-N" ? 1 : q.m;
    const met = q.rule === "all-of-N" ? v.A === v.N : v.A >= m;                                   // Term met vectors
    const lost = q.rule === "all-of-N" ? v.R + v.W >= 1 : v.N - v.R - v.W < m;                    // Term lost vectors
    if (met) return "Approved";                                                                  // Wiring decision 1
    if (lost) return v.R > 0 ? "Rejected" : "Withdrawn";                                         // 2, 3
    return "Pending";                                                                            // 4
  }
  static ruleName(q: Quorum) { return q.rule === "M-of-N" ? `M-of-N(${q.m})` : q.rule; }
  // Term rule reason.
  static ruleReason(q: Quorum, state: ChainState, v: { A: number; R: number; W: number; N: number }) {
    const rule = MultiPartyApproval.ruleName(q);
    if (state === "Approved") return `quorum met: ${v.A} of ${v.N} approved under ${rule}`;
    if (state === "Rejected") return `quorum unreachable: ${rule}; ${v.N - v.R - v.W} remain achievable; rejections present`;
    return `chain withdrawn by cascade: ${rule}; quorum unreachable by withdrawal alone`;
  }

  // ---- the chain evaluation (Action wiring 33 through 39) ----
  private evaluate(inv: Invocation, chain_id: string): ChainState {
    const c = this.chain(chain_id)!;
    if (c.state !== "Pending") return c.state;                                                  // 34
    const v = this.routedVector(chain_id);
    const state = MultiPartyApproval.quorum(c.quorum_rule, v);
    if (state === "Pending") return state;
    this.db.prepare("UPDATE chain SET state = ?, terminal_at = ? WHERE chain_id = ?").run(state, inv.now, chain_id);  // 35, 36
    const reason = MultiPartyApproval.ruleReason(c.quorum_rule, state, v);
    const cascade = this.cascade(inv, chain_id, reason);                                        // 37
    this.service("chain_resolved", { invocation_id: inv.id, chain_id, state, terminal_at: inv.now, reason,
      recalled_step_ids: cascade.recalled, ...partialFields(cascade.partial) }, chain_id);     // 38, 39
    return state;
  }

  // ---- the cascade (Cascade 1 through 13) ----
  private cascade(inv: Invocation, chain_id: string, reason: string, extra: string[] = []): { recalled: string[]; partial: PartialCall[] } {
    const c = this.chain(chain_id)!;
    const recalled: string[] = [], partial: PartialCall[] = [];
    for (const step_id of [...this.stepList(chain_id), ...extra]) {
      const s = approvalStep.get(this.db, step_id)!;
      if (s.state !== "pending") continue;                                                      // still-Pending steps only
      if (c.state === "Withdrawn") {                                                            // 2
        const w = approvalStep.resolve(this.db, this.seam, this.f, "withdraw", step_id, c.initiator_ref, reason);
        if ("refused" in w) {
          if (w.refused === "not-pending") {                                                    // 10
            this.service("cascade_completed", { invocation_id: inv.id, chain_id, step_id, closure_mark: "superseded_by_decision" }, chain_id, step_id);
          } else if (w.refused === "unauthorized" || w.refused === "not-known") {
            this.alert(w.refused === "unauthorized" ? "conformance" : "index-anomaly", step_id);  // 12; Action wiring 28
          } else partial.push({ step_id, call: "withdraw" });                                   // 9: a transient arm
          continue;                                                                             // 3: no recall before withdraw answers
        }
        // 4 through 6: under the initiator's credential where the invocation holds it, else the service identity.
        const data = { invocation_id: inv.id, chain_id, step_id, reason, trailing: false, cascade: true };
        if (inv.actor === c.initiator_ref && inv.credential) this.write("step_withdrawn", inv.actor, inv.credential, data, chain_id, step_id);
        else this.service("step_withdrawn", { ...data, recovery: true }, chain_id, step_id);
      }
      const a = this.stepAssignment(step_id);
      if (!a) continue;                                                                         // 7
      const r = assignment.recall(this.db, this.seam, this.f, a);                               // 1
      if ("ok" in r) recalled.push(step_id);                                                    // 13
      else if (r.refused === "storage-failure") partial.push({ step_id, call: "recall" });      // 8, 9
      else if (r.refused === "not-known") this.alert("index-anomaly", a);                       // Action wiring 28
      // 11: not-active reads as done.
    }
    return { recalled, partial };
  }

  // ---- the decision actions (Action wiring 17 through 32, 59 through 61) ----
  approve_step(actor_ref: string, credential: string, chain_id: string, step_id: string, reason?: string) {
    return this.decide("approve", actor_ref, credential, chain_id, step_id, reason);
  }
  reject_step(actor_ref: string, credential: string, chain_id: string, step_id: string, reason: string) {
    return this.decide("reject", actor_ref, credential, chain_id, step_id, reason);
  }
  withdraw_step(actor_ref: string, credential: string, chain_id: string, step_id: string, reason: string) {
    return this.decide("withdraw", actor_ref, credential, chain_id, step_id, reason);
  }

  private decide(decision: "approve" | "reject" | "withdraw", actor_ref: string, credential: string, chain_id: string, step_id: string, reason?: string):
    { ok: "approved" | "rejected_outcome" | "withdrawn" } | Refusal {
    if (!this.refOk(actor_ref)) return { refused: "invalid-request" };                          // Primitive policy 1, 2
    if (decision !== "approve" && (reason === undefined || reason.trim() === "")) return { refused: "invalid-request" };  // 9
    if (decision === "approve" && reason !== undefined && reason.trim() === "") return { refused: "invalid-request" };
    if (!this.fits(actor_ref, { invocation_id: this.pad(), intent_event_id: this.pad(), acting_actor_ref: actor_ref, chain_id: this.pad(),
      step_id: this.pad(), reason: reason ?? null, trailing: false, cascade: false, cascade_partial: true, intent_event_candidates: [this.pad()],
      recovery: true })) return { refused: "invalid-request" };                                 // 10
    if (this.stepChain(step_id) !== chain_id) return { refused: "not-known" };                  // 17
    const trailing = this.chain(chain_id)!.state !== "Pending";                                 // 18, 19
    const inv = this.begin(actor_ref);
    const intent = this.write("step_decision_intended", actor_ref, credential,
      { invocation_id: inv.id, chain_id, step_id, decision, reason: reason ?? null, trailing, intended_at: inv.now }, chain_id, step_id);  // 20
    const refused = this.intentRefusal(intent);
    if (refused) return refused;
    inv.credential = credential;
    const w = approvalStep.resolve(this.db, this.seam, this.f, decision, step_id, actor_ref, reason);  // 21
    if ("refused" in w) {
      if (w.refused === "storage-failure") return { refused: "recording-failure", position: "intent" };  // 23
      return { refused: w.refused };                                                            // 22
    }
    let partial = false;
    const a = this.stepAssignment(step_id);                                                     // 24, 25
    if (a) {
      const r = assignment.recall(this.db, this.seam, this.f, a);
      if ("refused" in r && r.refused === "storage-failure") partial = true;                    // 27
      if ("refused" in r && r.refused === "not-known") this.alert("index-anomaly", a);          // 28
    }
    const action_ref = decision === "approve" ? "step_approved" : decision === "reject" ? "step_rejected" : "step_withdrawn";
    const out = this.outcome(inv, action_ref, actor_ref, credential, { invocation_id: inv.id, intent_event_id: (intent as { ok: string }).ok,
      acting_actor_ref: actor_ref, chain_id, step_id, reason: reason ?? null, trailing, cascade: false,
      ...(partial ? { cascade_partial: true, partial_steps: [{ step_id, call: "recall" }] } : {}) }, chain_id, step_id);  // 29
    if (!trailing && this.take(chain_id)) {                                                     // 30, 31, 33
      try { this.evaluate(inv, chain_id); } finally { this.release(chain_id); }
    }
    return "refused" in out ? out : { ok: w.ok };                                               // 32
  }

  // ---- [Withdraw Chain] (Action wiring 40 through 50) ----
  withdraw_chain(actor_ref: string, credential: string, chain_id: string, reason: string): { ok: "withdrawn" } | Refusal {
    if (!this.refOk(actor_ref)) return { refused: "invalid-request" };
    if (reason === undefined || reason.trim() === "") return { refused: "invalid-request" };    // Primitive policy 9
    if (!this.fits(actor_ref, { invocation_id: this.pad(), intent_event_id: this.pad(), acting_actor_ref: actor_ref, chain_id: this.pad(),
      reason, terminal_at: new Date(0).toISOString(), cascade_partial: true })) return { refused: "invalid-request" };
    if (permissions.permitted(this.db, actor_ref, SCOPES.withdraw) === "denied") return { refused: "permission-denied" };  // 40
    if (!this.chain(chain_id)) return { refused: "not-known" };                                 // 41
    if (!this.take(chain_id)) return { refused: "recording-failure", position: "intent" };      // see CORNERS.md
    try {
      const inv = this.begin(actor_ref);
      if (this.evaluate(inv, chain_id) !== "Pending") return { refused: "not-pending" };        // 43, 44
      if (this.chain(chain_id)!.initiator_ref !== actor_ref) return { refused: "unauthorized" };  // 45
      const intent = this.write("chain_withdrawal_intended", actor_ref, credential,
        { invocation_id: inv.id, chain_id, reason, intended_at: inv.now }, chain_id);          // 46
      const refused = this.intentRefusal(intent);
      if (refused) return refused;
      inv.credential = credential;
      this.db.prepare("UPDATE chain SET state = 'Withdrawn', terminal_at = ? WHERE chain_id = ?").run(inv.now, chain_id);  // 47
      const cascade = this.cascade(inv, chain_id, reason);                                      // 48
      const out = this.outcome(inv, "chain_withdrawn", actor_ref, credential, { invocation_id: inv.id,
        intent_event_id: (intent as { ok: string }).ok, acting_actor_ref: actor_ref, chain_id, reason, terminal_at: inv.now,
        ...partialFields(cascade.partial) }, chain_id);                                         // 49
      return "refused" in out ? out : { ok: "withdrawn" };                                      // 50
    } finally { this.release(chain_id); }
  }

  // ---- [Read Chain] (Action wiring 51 through 56) ----
  read_chain(actor_ref: string, query: ChainQuery): { ok: ChainResult[] } | Refusal {
    if (!this.refOk(actor_ref)) return { refused: "invalid-request" };
    if (permissions.permitted(this.db, actor_ref, SCOPES.read) === "denied") return { refused: "permission-denied" };  // 51
    if (!validChainQuery(query)) return { refused: "invalid-query" };                           // 52
    const out: ChainResult[] = [];
    for (const c of this.chains()) {                                                            // 55: initiated instant, then chain id bytes
      if (!chainMatches(c, query)) continue;
      const v = this.routedVector(c.chain_id);
      out.push({
        chain: c,
        steps: this.stepList(c.chain_id).map((id) => ({
          step: approvalStep.get(this.db, id)!,
          assignments: assignment.history_for(this.db, id),                                     // 54
          out_of_band: v.outOfBand.includes(id),
        })),
        event_ids: this.eventIndex(c.chain_id).map((e) => e.event_id),
      });
    }
    return { ok: out };                                                                         // 53, 56: no audit event
  }

  // ---- the sweep (Reconciliation 1 through 34) ----
  sweep(): void {
    const inv = this.begin(this.config.serviceActor);
    const now = Date.parse(inv.now);
    const inHorizon = (c: ChainRecord) => !(Date.parse(c.initiated_at) + this.config.auditHorizonMs < now);  // 5
    const young = (at: string) => !(Date.parse(at) + this.config.decisionCompletionBoundMs < now);          // 4
    const live = this.chains().filter(inHorizon);
    for (const c of live) this.withChain(c.chain_id, () => this.transitionLeg(inv, c.chain_id, young));
    for (const c of live) this.withChain(c.chain_id, () => {                                            // 23: the evaluation leg
      const x = this.chain(c.chain_id)!;
      if (x.state === "Pending" && MultiPartyApproval.quorum(x.quorum_rule, this.routedVector(x.chain_id)) !== "Pending") this.evaluate(inv, x.chain_id);
    });
    for (const c of live) this.withChain(c.chain_id, () => this.recallLeg(inv, c.chain_id));
    for (const c of live) this.withChain(c.chain_id, () => this.initiationLeg(inv, c.chain_id, young));  // 3: after the evaluation leg
    this.escalate(now);                                                                                    // 32
  }

  // 6, 7: take the exclusion first; a chain another holder holds waits for the next run.
  private withChain(chain_id: string, leg: () => void) {
    if (!this.take(chain_id)) return;
    try { leg(); } finally { this.release(chain_id); }
  }

  private records(chain_id: string) {
    return this.eventIndex(chain_id).map((e) => ({ ...e, r: this.audit.read_record(e.event_id) }))
      .filter((e): e is { event_id: string; step_id: string | null; r: Exclude<ReturnType<AuditTrail["read_record"]>, "not-known"> } => e.r !== "not-known");
  }

  // Reconciliation 17 through 22 and 34: the transition leg.
  private transitionLeg(inv: Invocation, chain_id: string, young: (at: string) => boolean) {
    const recs = this.records(chain_id);
    for (const step_id of this.stepList(chain_id)) {
      const s = approvalStep.get(this.db, step_id)!;
      if (s.state === "pending") continue;
      const mine = recs.filter((e) => e.step_id === step_id);
      const audited = mine.some((e) => ["step_approved", "step_rejected", "step_withdrawn", "cascade_completed"].includes(e.r.action_ref ?? ""));
      if (audited) continue;
      if (!this.routed(chain_id, s)) { this.alert("out-of-band", step_id); continue; }                   // 19, 20
      const decider = s.state === "withdrawn" ? s.withdrawn_by : s.decided_by;
      const intents = mine.filter((e) => e.r.action_ref === "step_decision_intended" && e.r.actor_ref === decider);
      if (intents.some((e) => young(String(e.r.data?.intended_at ?? "")))) continue;                     // 4
      const candidates = intents.map((e) => e.event_id);                                                 // Term intent candidates
      if (!("ok" in this.service("chain_recovery_intended", { invocation_id: inv.id, chain_id, leg: "transition",
        intent_event_candidates: candidates, recovery: true }, chain_id, step_id))) continue;              // 28, 29
      const action_ref = s.state === "approved" ? "step_approved" : s.state === "rejected" ? "step_rejected" : "step_withdrawn";
      const trailing = intents.at(-1)?.r.data?.trailing ?? false;
      this.service(action_ref, { invocation_id: inv.id, intent_event_candidates: candidates, acting_actor_ref: decider, chain_id, step_id,
        reason: s.state === "withdrawn" ? s.withdrawal_reason : s.decision_reason, trailing, cascade: false, recovery: true }, chain_id, step_id);  // 21
      const a = this.stepAssignment(step_id);                                                            // 22
      if (a) assignment.recall(this.db, this.seam, this.f, a);
      if (!trailing) this.evaluate(inv, chain_id);
    }
    const c = this.chain(chain_id)!;                                                                     // a terminal with no terminal event
    if (c.state === "Pending" || young(c.terminal_at!)) return;
    if (recs.some((e) => ["chain_resolved", "chain_withdrawn"].includes(e.r.action_ref ?? ""))) return;
    if (!("ok" in this.service("chain_recovery_intended", { invocation_id: inv.id, chain_id, leg: "transition", intent_event_candidates: [],
      recovery: true }, chain_id))) return;
    const byInitiator = recs.some((e) => e.r.action_ref === "chain_withdrawal_intended");
    const late = this.stepList(chain_id).filter((id) => {                                                // Term late-recalled steps
      const a = this.stepAssignment(id);
      const h = a ? assignment.history_for(this.db, id).find((x) => x.assignment_id === a) : undefined;
      return h?.ended_at != null && !(h.ended_at < c.terminal_at!);
    });
    const v = this.routedVector(chain_id);
    this.service(byInitiator ? "chain_withdrawn" : "chain_resolved", { invocation_id: inv.id, chain_id, state: c.state, terminal_at: c.terminal_at,
      reason: byInitiator ? null : MultiPartyApproval.ruleReason(c.quorum_rule, c.state, v), recalled_step_ids: late, recovery: true }, chain_id);  // 34
  }

  // Reconciliation 24 through 30: the recall leg.
  private recallLeg(inv: Invocation, chain_id: string) {
    const c = this.chain(chain_id)!;
    for (const step_id of this.stepList(chain_id)) {
      const s = approvalStep.get(this.db, step_id)!;
      if (c.state === "Withdrawn" && s.state === "pending") {                                            // 25
        if (!("ok" in this.service("chain_recovery_intended", { invocation_id: inv.id, chain_id, leg: "recall", intent_event_candidates: [],
          recovery: true }, chain_id, step_id))) continue;                                                // 28
        const w = approvalStep.resolve(this.db, this.seam, this.f, "withdraw", step_id, c.initiator_ref, this.cascadeReason(chain_id));
        if ("ok" in w) {
          this.service("step_withdrawn", { invocation_id: inv.id, chain_id, step_id, reason: this.cascadeReason(chain_id), trailing: false,
            cascade: true, recovery: true }, chain_id, step_id);
          this.service("cascade_completed", { invocation_id: inv.id, chain_id, step_id, closure_mark: "retried", recovery: true }, chain_id, step_id);  // 30
        } else if (w.refused === "not-pending") {
          this.service("cascade_completed", { invocation_id: inv.id, chain_id, step_id, closure_mark: "superseded_by_decision", recovery: true }, chain_id, step_id);
        } else continue;                                                                                  // 26, 27: transient waits; deterministic alerted
      }
      const settled = approvalStep.get(this.db, step_id)!.state !== "pending" || c.state !== "Pending";  // Term settled step
      const a = this.stepAssignment(step_id);
      if (!settled || !a || assignment.active_for(this.db, step_id) === "none") continue;
      if (!("ok" in this.service("chain_recovery_intended", { invocation_id: inv.id, chain_id, leg: "recall", intent_event_candidates: [],
        recovery: true }, chain_id, step_id))) continue;                                                  // 24, 28
      const r = assignment.recall(this.db, this.seam, this.f, a);
      const mark = "ok" in r ? "retried" : r.refused === "not-known" ? "store_anomaly" : null;           // Term closure mark
      if (mark) this.service("cascade_completed", { invocation_id: inv.id, chain_id, step_id, closure_mark: mark, recovery: true }, chain_id, step_id);
    }
  }
  private cascadeReason(chain_id: string): string {
    const e = this.records(chain_id).find((x) => ["chain_withdrawn", "chain_resolved"].includes(x.r.action_ref ?? ""));
    return String(e?.r.data?.reason ?? "chain withdrawn");
  }

  // Reconciliation 8 through 16: the initiation leg.
  private initiationLeg(inv: Invocation, chain_id: string, young: (at: string) => boolean) {
    const c = this.chain(chain_id)!;
    const recs = this.records(chain_id);
    if (recs.some((e) => ["chain_initiated", "chain_initiation_failed"].includes(e.r.action_ref ?? ""))) return;
    if (young(c.initiated_at)) return;                                                                   // 4
    const d = c.landed_ids.steps.length < c.approver_set.length ? "a" : c.landed_ids.assignments.length < c.landed_ids.steps.length ? "b" : "c";
    this.initiationRecovery(inv, chain_id, d);                                                           // 8
  }

  // Reconciliation 32: an open marker past its escalation instant opens a finding.
  private escalate(now: number) {
    const w = this.config.compensationWindowMs;
    for (const c of this.chains()) {
      if (c.audit_pending && Date.parse(c.initiated_at) + w < now) this.findings.push({ chain_id: c.chain_id, marker: "quarantine" });
      for (const e of this.records(c.chain_id)) {
        const parts = (e.r.data?.partial_steps ?? []) as PartialCall[];
        for (const p of parts) {
          const closed = this.records(c.chain_id).some((x) => x.r.action_ref === "cascade_completed" && x.step_id === p.step_id);
          const opened = this.audit.log_read().find((x) => x.event_id === e.event_id)!.recorded_at;
          if (!closed && Date.parse(opened) + w < now) this.findings.push({ chain_id: c.chain_id, marker: `partial:${p.step_id}` });
        }
      }
    }
  }
}

function partialFields(p: PartialCall[]) { return p.length ? { cascade_partial: true, partial_steps: p } : {}; }

function toChain(r: Record<string, unknown>): ChainRecord {
  return { ...(r as unknown as ChainRecord), approver_set: JSON.parse(r.approver_set as string), quorum_rule: JSON.parse(r.quorum_rule as string),
    audit_pending: r.audit_pending === 1, landed_ids: JSON.parse(r.landed_ids as string) };
}

export type ChainQuery = Partial<Record<"chain_id" | "subject_ref" | "scope" | "initiator_ref" | "state", string>> &
  Partial<Record<"initiated_at" | "terminal_at", { after?: string; before?: string }>>;
export interface ChainResult {
  chain: ChainRecord;
  steps: { step: StepRecord; assignments: ReturnType<typeof assignment.history_for>; out_of_band: boolean }[];
  event_ids: string[];
}
const CHAIN_AXES = ["chain_id", "subject_ref", "scope", "initiator_ref", "state", "initiated_at", "terminal_at"];
// Action wiring 52: Approval Step's read rules — a known axis, no blank value, a known state, a range in order.
function validChainQuery(q: Record<string, unknown>): boolean {
  for (const [k, v] of Object.entries(q)) {
    if (!CHAIN_AXES.includes(k)) return false;
    if (k === "state") { if (!["Pending", "Approved", "Rejected", "Withdrawn"].includes(v as string)) return false; continue; }
    const as = k === "initiated_at" ? "submitted_at" : k === "terminal_at" ? "decided_at" : "subject_ref";
    if (!validStepQuery({ [as]: v })) return false;
  }
  return true;
}
function chainMatches(c: ChainRecord, q: ChainQuery): boolean {
  for (const [k, v] of Object.entries(q)) {
    const field = (c as unknown as Record<string, string | null>)[k];
    if (typeof v === "string") { if (field !== v) return false; continue; }
    const r = v as { after?: string; before?: string };
    if (field === null) return false;
    if (r.after && field <= r.after) return false;
    if (r.before && field >= r.before) return false;
  }
  return true;
}

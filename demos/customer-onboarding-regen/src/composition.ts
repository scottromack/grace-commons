// Customer Onboarding, rendered from compositions/customer-onboarding.md, to the
// depth CORNERS.md states: the six actions, the gate and the four indexes. Every
// rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { type Policy, retentionWindow } from "./audit_atoms.ts";
import type { AuditTrail } from "./audit_trail.ts";
import { partyIdentity } from "./atoms.ts";

export interface Config {
  policies: Record<string, Policy>;              // the party retention instance's registry (Capability requirement 37)
  activeRelationshipPolicy: string;              // 15
  postClosurePolicy: string;                     // 16
  monitoringIntervalMs?: number;                 // 18
  schedulerToleranceMs: number;                  // 19
  adverseTriggerTypes: string[];                 // 21, 22
  triggerSetCap: number;                         // 32
  recordAttempts?: number;                       // an owed record's retries inside the bound (see CORNERS.md)
}
type Fail = { refused: string; position?: "intent" | "outcome"; state?: string };
const PERIODIC = "periodic-review-due";
const A = (s: string) => `customer-onboarding.${s}`;
const blank = (s: unknown) => s === undefined || s === null || (typeof s === "string" && s.trim() === "");

export class CustomerOnboarding {
  readonly alerts: { kind: string; detail: string }[] = [];
  constructor(private trail: AuditTrail, private db: Database, private seam: Seam, private f: Faults, readonly c: Config) {
    const p = c.policies[c.activeRelationshipPolicy];
    if (c.monitoringIntervalMs !== undefined && !(p.durationMs > c.monitoringIntervalMs + c.schedulerToleranceMs))
      throw new Error("instance will not start: the active relationship policy does not exceed the renewal floor");     // Capability requirement 20
    if (c.adverseTriggerTypes.includes(PERIODIC)) throw new Error("instance will not start: an adverse type is the periodic type");  // 22
  }

  // ---- the substrate under the Audit arm ----
  private intent(action: string, actor: string, credential: string, data: Record<string, unknown>): { landed: string } | Fail {
    const r = this.trail.record_action(A(action), actor, credential, data);                                               // Audit arm 1
    if ("ok" in r) return { landed: r.ok };
    if (r.refused === "recording-failure") return { refused: "recording-failure", position: "intent" };                   // 4 through 7
    return { refused: r.refused };                                                                                         // 2, 3
  }
  private outcome(action: string, actor: string, credential: string, data: Record<string, unknown>): { landed: string } | Fail {
    for (let i = 0; i < (this.c.recordAttempts ?? 3); i++) {                                                               // 14
      const r = this.trail.record_action(A(action), actor, credential, data);
      if ("ok" in r) return { landed: r.ok };
      if (r.refused === "recording-failure" && r.step === "step-4") break;                                                 // 18
      if (r.refused !== "recording-failure") break;                                                                        // 20, 21
    }
    this.alert("owed-record", `${action}:${data.case_id}`);                                                                // 19
    return { refused: "recording-failure", position: "outcome" };                                                         // 8 through 10
  }
  private alert(kind: string, detail: string) { this.alerts.push({ kind, detail }); }

  // ---- the indexes ----
  monitoring(case_id: string) { return this.db.prepare("SELECT * FROM case_to_monitoring WHERE case_id = ?").get<{ party_id: string; next_review_due: string }>(case_id); }
  caseOf(party_id: string) { return this.db.prepare("SELECT * FROM party_to_case WHERE party_id = ?").get<{ case_id: string; active: number }>(party_id); }
  active(case_id: string) { return !!this.db.prepare("SELECT active FROM party_to_case WHERE case_id = ?").get<{ active: number }>(case_id)?.active; }
  openTriggers(case_id: string) { return this.db.prepare("SELECT trigger_id, trigger_ref FROM case_to_open_triggers WHERE case_id = ? ORDER BY trigger_instant, trigger_id").all<{ trigger_id: string; trigger_ref: string }>(case_id); }
  placements(case_id: string) { return this.db.prepare("SELECT * FROM case_to_retentions WHERE case_id = ?").get<{ current_placement: string; post_closure_placement: string | null }>(case_id)!; }
  private placement(id: string) { return retentionWindow.read(this.db, this.seam).find((r) => r.retention_id === id)!; }
  private triggerSet(case_id: string) {                                                                                   // Primitive policy 20
    const s = this.openTriggers(case_id);
    return s.length > this.c.triggerSetCap ? { count: s.length, digest: s.map((t) => t.trigger_id).join(",") } : s;
  }
  // Clock semantics 4: the next review due, capped below the current placement's cover.
  private nextReviewDue(now: string, current: string) {
    const cover = Date.parse(this.placement(current).retention_deadline) - this.c.schedulerToleranceMs;
    return new Date(Math.min(Date.parse(now) + this.c.monitoringIntervalMs!, cover)).toISOString();
  }
  private place(party_id: string, policy_ref: string) {
    return retentionWindow.place(this.db, this.seam, this.f, party_id, this.c.policies[policy_ref], `party:${party_id}`);
  }

  // ---- [Initiate Onboarding] ----
  initiate_onboarding(party_id: string | undefined, fields: Record<string, string> | undefined, actor_ref: string, credential: string, retention_policy_ref: string): { ok: string } | Fail {
    if ((party_id !== undefined) === (fields !== undefined)) return { refused: "invalid-request" };                       // Action wiring 1, 2
    if (this.c.monitoringIntervalMs === undefined) return { refused: "invalid-request" };                                 // 3
    if ([actor_ref, credential, retention_policy_ref].some(blank) || (party_id !== undefined && blank(party_id))) return { refused: "invalid-request" };  // Primitive policy 2, 3, 21
    const path = party_id === undefined ? "direct" : "external";
    if (party_id !== undefined) {
      const r = partyIdentity.read(this.db, this.f, party_id);                                                             // 4
      if (r === "unanswered") return { refused: "state-unavailable" };                                                     // see CORNERS.md, finding 2
      if (r.ok.length === 0) return { refused: "party-not-known" };                                                        // 5
      if (r.ok[0].state !== "unverified") return { refused: "party-not-admissible", state: r.ok[0].state };                // 6
      const existing = this.caseOf(party_id);
      if (existing?.active) return { refused: "already-onboarded" };                                                       // 7
    }
    const case_id = this.seam.id("case"), now = this.seam.now();                                                          // Capability requirement 2
    const i = this.intent("initiation-intended", actor_ref, credential, { case_id, ...(party_id ? { party_id } : {}), enrollment_path: path,
      retention_policy_ref, intent_instant: now });                                                                        // 8, 9; Identity 9 through 12
    if (!("landed" in i)) return i;
    if (party_id === undefined) {
      const e = partyIdentity.enroll(this.db, this.seam, this.f, fields as never, actor_ref);                              // 10
      if ("refused" in e) return { refused: "enrollment-failed", state: e.refused };                                       // 11, 12
      party_id = e.ok;
    }
    const p = this.place(party_id, retention_policy_ref);                                                                  // 13, 14
    if ("refused" in p) {
      if (p.refused === "storage-failure") return { refused: "recording-failure", position: path === "direct" ? "outcome" : "intent" };  // 17, 18
      return { refused: "invalid-request" };                                                                               // 15, 16
    }
    const next = this.nextReviewDue(now, p.ok);
    const o = this.outcome("initiated", actor_ref, credential, { intent_event_id: i.landed, case_id, party_id, enrollment_path: path,
      current_placement: p.ok, opening_instant: now, next_review_due: next });                                            // 19; 146
    if (!("landed" in o)) return o;
    this.db.prepare("INSERT OR REPLACE INTO party_to_case VALUES (?, ?, ?, 1)").run(party_id, case_id, path);             // Composition state 35
    this.db.prepare("INSERT INTO case_to_monitoring VALUES (?, ?, ?, ?)").run(case_id, party_id, now, next);
    this.db.prepare("INSERT INTO case_to_retentions VALUES (?, ?, NULL)").run(case_id, p.ok);
    return { ok: case_id };                                                                                                // 20
  }

  // ---- [Record Verification] ----
  record_verification(case_id: string, verifying_actor_ref: string, method: string, verification_result: string, evidence_ref: string, credential: string): { ok: "recorded" } | Fail {
    if ([case_id, verifying_actor_ref, method, evidence_ref, credential].some(blank)) return { refused: "invalid-request" };
    if (verification_result !== "passed" && verification_result !== "failed") return { refused: "invalid-request" };       // Primitive policy 8
    const m = this.monitoring(case_id);                                                                                    // Action wiring 21
    if (!m) return { refused: "not-known" };                                                                               // 22
    if (!this.active(case_id)) return { refused: "not-active" };                                                           // 23
    const now = this.seam.now();
    const i = this.intent("verification-intended", verifying_actor_ref, credential, { case_id, party_id: m.party_id, method, verification_result, evidence_ref, intent_instant: now });  // 24
    if (!("landed" in i)) return i;
    const v = partyIdentity.verify(this.db, this.seam, this.f, m.party_id, verifying_actor_ref, method, verification_result, evidence_ref);  // 25
    if ("refused" in v) {
      if (v.refused === "already-closed") return { refused: "already-closed" };                                            // 26
      if (v.refused === "invalid-request") return { refused: "invalid-request" };                                          // Primitive policy 15
      return { refused: "recording-failure", position: "intent" };                                                         // 27, 28
    }
    const transitioning = v.ok.state_change_id !== undefined;
    const next = transitioning ? this.nextReviewDue(now, this.placements(case_id).current_placement) : undefined;         // 30 through 33
    const o = this.outcome("verification-recorded", verifying_actor_ref, credential, { intent_event_id: i.landed, case_id, party_id: m.party_id,
      verification_id: v.ok.verification_id, state_change_id: v.ok.state_change_id ?? null, verification_result, ...(next ? { next_review_due: next } : {}) });  // 29
    if (!("landed" in o)) return o;                                                                                        // 34
    if (next) this.db.prepare("UPDATE case_to_monitoring SET next_review_due = ? WHERE case_id = ?").run(next, case_id);
    return { ok: "recorded" };                                                                                             // 35
  }

  // ---- [Trigger Monitoring Review] ----
  trigger_monitoring_review(case_id: string, trigger_type: string, trigger_ref: string, actor_ref: string, credential: string): { ok: "recorded" } | Fail {
    if ([case_id, trigger_ref, actor_ref, credential].some(blank)) return { refused: "invalid-request" };
    if (trigger_type !== PERIODIC && !this.c.adverseTriggerTypes.includes(trigger_type)) return { refused: "invalid-request" };  // Primitive policy 7
    const reason = `monitoring-trigger:${trigger_type}:${trigger_ref}`;
    if (reason.length > 2000) return { refused: "invalid-request" };                                                       // 9
    const m = this.monitoring(case_id);                                                                                    // Action wiring 37
    if (!m) return { refused: "not-known" };                                                                               // 38
    if (!this.active(case_id)) return { refused: "not-active" };                                                           // 39
    const r = partyIdentity.read(this.db, this.f, m.party_id);                                                             // 40
    if (r === "unanswered" || r.ok.length === 0) return { refused: "state-unavailable" };                                  // 41
    const state = r.ok[0].state, adverse = trigger_type !== PERIODIC;
    if (adverse && state !== "verified" && state !== "suspended") return { refused: "not-verified", state };               // 44, 45
    const trigger_id = this.seam.id("trigger"), now = this.seam.now();                                                    // Capability requirement 3
    const current = this.placements(case_id).current_placement;
    const next = !adverse && state !== "suspended" ? this.nextReviewDue(now, current) : undefined;                        // 47 through 49
    const t = this.intent("monitoring-triggered", actor_ref, credential, { case_id, party_id: m.party_id, trigger_id, trigger_type, trigger_ref,
      trigger_instant: now, ...(next ? { next_review_due: next } : {}) });                                                // 46; Identity 17
    if (!("landed" in t)) return t;                                                                                        // 50, 51
    const addTrigger = () => this.db.prepare("INSERT INTO case_to_open_triggers VALUES (?, ?, ?, ?, ?)").run(case_id, trigger_id, trigger_type, trigger_ref, now);
    if (adverse) {
      const s = partyIdentity.suspend(this.db, this.seam, this.f, m.party_id, actor_ref, reason);                         // 52
      if ("refused" in s && s.refused === "already-suspended") {                                                           // 53, 54
        addTrigger();
        const o = this.outcome("trigger-on-suspended-party", actor_ref, credential, { intent_event_id: t.landed, case_id, party_id: m.party_id, trigger_id });
        return "landed" in o ? { ok: "recorded" } : o;
      }
      if ("refused" in s) {                                                                                                // 55, 56
        const o = this.outcome("trigger-voided", actor_ref, credential, { intent_event_id: t.landed, case_id, trigger_id, answer: s.refused });
        if (!("landed" in o)) return { refused: "recording-failure", position: "intent" };                                 // 62
        const map: Record<string, Fail> = { "not-verifiable": { refused: "not-verified", state: "unverified" }, "already-closed": { refused: "not-verified", state: "closed" },
          "not-known": { refused: "not-known" }, "invalid-request": { refused: "invalid-request" }, "storage-failure": { refused: "recording-failure", position: "intent" } };
        return map[s.refused];                                                                                             // 57 through 61
      }
      addTrigger();                                                                                                        // 64
      const o = this.outcome("party-suspended", actor_ref, credential, { intent_event_id: t.landed, case_id, party_id: m.party_id, trigger_id, trigger_type,
        trigger_ref, state_change_id: s.ok, suspension_instant: now });                                                    // 63; 148
      return "landed" in o ? { ok: "recorded" } : o;                                                                       // 65
    }
    if (next) this.db.prepare("UPDATE case_to_monitoring SET next_review_due = ? WHERE case_id = ?").run(next, case_id);  // 76, 77
    const policy_ref = this.placement(current).policy_ref;                                                                 // 66
    const p = this.place(m.party_id, policy_ref);                                                                          // 67 through 69
    if ("refused" in p) return p.refused === "storage-failure" ? { refused: "recording-failure", position: "intent" } : { refused: "invalid-request" };  // 70 through 72
    const path = this.caseOf(m.party_id)!;
    const o = this.outcome("retention-renewed", actor_ref, credential, { intent_event_id: t.landed, case_id, party_id: m.party_id,
      enrollment_path: (path as unknown as { enrollment_path: string }).enrollment_path, trigger_id, prior_placement: current, renewed_placement: p.ok, policy_ref, renewal_instant: now });  // 73; 149
    if (!("landed" in o)) return o;                                                                                        // 74
    this.db.prepare("UPDATE case_to_retentions SET current_placement = ? WHERE case_id = ?").run(p.ok, case_id);          // 75
    return { ok: "recorded" };                                                                                             // 79
  }

  // ---- [Clear Review] ----
  clear_review(case_id: string, verifying_actor_ref: string, method: string, evidence_ref: string, actor_ref: string, credential: string, reason: string): { ok: "cleared" } | Fail {
    if ([case_id, verifying_actor_ref, method, evidence_ref, actor_ref, credential, reason].some(blank)) return { refused: "invalid-request" };
    const m = this.monitoring(case_id);                                                                                    // Action wiring 80
    if (!m) return { refused: "not-known" };                                                                               // 81
    const open = this.openTriggers(case_id);
    if (open.length === 0) return { refused: "no-open-trigger" };                                                          // 82
    const now = this.seam.now();
    const i = this.intent("clearance-intended", actor_ref, credential, { case_id, party_id: m.party_id, verifying_actor_ref, method, evidence_ref, reason,
      open_triggers: this.triggerSet(case_id), intent_instant: now });                                                     // 83
    if (!("landed" in i)) return i;
    const v = partyIdentity.verify(this.db, this.seam, this.f, m.party_id, verifying_actor_ref, method, "passed", evidence_ref);  // 84, 85
    if ("refused" in v) return v.refused === "storage-failure" ? { refused: "recording-failure", position: "intent" } : { refused: v.refused };  // 86 through 89
    const closed = open.map((t) => t.trigger_id);
    const c = this.outcome("review-cleared", actor_ref, credential, { intent_event_id: i.landed, case_id, party_id: m.party_id, verification_id: v.ok.verification_id,
      closed_triggers: closed, reason, clearance_instant: now });                                                          // 90, 91; 150
    if (!("landed" in c)) return c;                                                                                        // 92, 93
    const r = partyIdentity.reinstate(this.db, this.seam, this.f, m.party_id, actor_ref, reason);                          // 94, 95
    if ("refused" in r) {
      const map: Record<string, Fail> = { "no-passed-verification-since-suspend": { refused: "verification-failed" }, "not-suspended": { refused: "verification-failed" },
        "already-closed": { refused: "already-closed" }, "not-known": { refused: "not-known" }, "invalid-request": { refused: "invalid-request" },
        "storage-failure": { refused: "recording-failure", position: "outcome" } };
      return map[r.refused];                                                                                               // 96 through 101
    }
    const next = this.nextReviewDue(now, this.placements(case_id).current_placement);
    const o = this.outcome("party-reinstated", actor_ref, credential, { intent_event_id: i.landed, case_id, party_id: m.party_id, state_change_id: r.ok,
      reinstatement_instant: now, next_review_due: next });                                                                // 102; 151
    if (!("landed" in o)) return o;                                                                                        // 103
    for (const t of closed) this.db.prepare("DELETE FROM case_to_open_triggers WHERE case_id = ? AND trigger_id = ?").run(case_id, t);  // 104, 105
    this.db.prepare("UPDATE case_to_monitoring SET next_review_due = ? WHERE case_id = ?").run(next, case_id);            // 107
    return { ok: "cleared" };                                                                                              // 111
  }

  // ---- [Close Party] ----
  close_party(case_id: string, closing_actor_ref: string, reason: string, credential: string): { ok: "closed" } | Fail {
    if ([case_id, closing_actor_ref, reason, credential].some(blank)) return { refused: "invalid-request" };
    const m = this.monitoring(case_id);                                                                                    // Action wiring 112
    if (!m) return { refused: "not-known" };                                                                               // 113
    if (!this.active(case_id)) return { refused: "not-active" };                                                           // 114
    const now = this.seam.now();
    const i = this.intent("closure-intended", closing_actor_ref, credential, { case_id, party_id: m.party_id, reason, post_closure_policy: this.c.postClosurePolicy, intent_instant: now });  // 115
    if (!("landed" in i)) return i;
    let state_change_id: string, closure_instant = now;
    const cl = partyIdentity.close(this.db, this.seam, this.f, m.party_id, closing_actor_ref, reason);                     // 116
    if ("refused" in cl) {
      if (cl.refused === "already-closed") {
        const named = this.trail_events().some((e) => e.action === A("party-closed") && e.data?.case_id === case_id);
        if (named) return { refused: "not-active" };                                                                       // 119
        const r = partyIdentity.read(this.db, this.f, m.party_id);                                                         // 117, 118: complete the earlier closure
        const last = r === "unanswered" ? undefined : r.ok[0].log.filter((e) => e.kind === "state-change" && e.next === "closed").at(-1);
        if (!last) return { refused: "recording-failure", position: "intent" };
        state_change_id = last.id; closure_instant = last.at;
      } else if (cl.refused === "storage-failure") return { refused: "recording-failure", position: "intent" };             // 122
      else return { refused: cl.refused };                                                                                 // 120, 121
    } else state_change_id = cl.ok;
    const p = this.place(m.party_id, this.c.postClosurePolicy);                                                            // 123
    if ("refused" in p) return p.refused === "storage-failure" ? { refused: "recording-failure", position: "outcome" } : { refused: "invalid-request" };  // 124 through 126
    const o = this.outcome("party-closed", closing_actor_ref, credential, { intent_event_id: i.landed, case_id, party_id: m.party_id, state_change_id,
      post_closure_placement: p.ok, reason, closure_instant, open_triggers_at_close: this.triggerSet(case_id) });           // 127; 152
    if (!("landed" in o)) return o;                                                                                        // 128
    this.db.prepare("UPDATE case_to_retentions SET post_closure_placement = ? WHERE case_id = ?").run(p.ok, case_id);     // 129
    this.db.prepare("UPDATE party_to_case SET active = 0 WHERE case_id = ?").run(case_id);                                // 130
    this.db.prepare("DELETE FROM case_to_open_triggers WHERE case_id = ?").run(case_id);                                  // 131
    return { ok: "closed" };                                                                                               // 132
  }
  private trail_events(): { action: string; data: Record<string, unknown> | null }[] {
    // Composes 12, 13: an open-ended read through the substrate, filtered in composition code.
    return this.trailRead();
  }
  trailRead: () => { action: string; data: Record<string, unknown> | null }[] = () => [];

  // ---- [Activity Permitted] ----
  activity_permitted(party_id: string): { ok: "permitted" } | Fail {
    if (!this.caseOf(party_id)) return { refused: "not-known" };                                                           // Action wiring 134, 135
    const r = partyIdentity.read(this.db, this.f, party_id);                                                               // 136
    if (r === "unanswered" || r.ok.length === 0) return { refused: "state-unavailable" };                                  // 139 through 141
    return r.ok[0].state === "verified" ? { ok: "permitted" } : { refused: "not-verified", state: r.ok[0].state };        // 137, 138
  }
}

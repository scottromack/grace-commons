// The atoms, as much of each as the composition and Audit Trail reach. Each reads
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

// ---- Permissions ----
export const permissions = {
  grant(db: Database, seam: Seam, subject_ref: string, action_scope: string): R<string, "invalid-request"> {
    if (subject_ref.trim() === "" || action_scope.trim() === "") return { refused: "invalid-request" };
    const id = seam.id("grant");
    db.prepare("INSERT INTO grant_record VALUES (?, ?, ?, 'active', ?, NULL)").run(id, subject_ref, action_scope, seam.now());
    return { ok: id };
  },
  revoke(db: Database, seam: Seam, grant_id: string) {
    db.prepare("UPDATE grant_record SET status = 'revoked', revoked_at = ? WHERE grant_id = ? AND status = 'active'").run(seam.now(), grant_id);
  },
  permitted(db: Database, subject_ref: string, action_scope: string): "permitted" | "denied" {
    return db.prepare("SELECT 1 FROM grant_record WHERE subject_ref = ? AND action_scope = ? AND status = 'active'").get(subject_ref, action_scope)
      ? "permitted" : "denied";
  },
};

// ---- Approval Step ----
export interface StepRecord {
  step_id: string; subject_ref: string; approver_ref: string; submitter_ref: string; scope: string; submitted_at: string;
  reason: string | null; state: "pending" | "approved" | "rejected" | "withdrawn";
  decided_by: string | null; decision_reason: string | null; decided_at: string | null;
  withdrawn_by: string | null; withdrawal_reason: string | null; withdrawn_at: string | null;
}
export type StepRefusal = "invalid-request" | "not-known" | "not-pending" | "unauthorized" | "storage-failure";
export type StepQuery = Partial<Record<"step_id" | "subject_ref" | "approver_ref" | "submitter_ref" | "scope" | "state", string>> &
  Partial<Record<"submitted_at" | "decided_at" | "withdrawn_at", { after?: string; before?: string }>>;
const STEP_AXES = ["step_id", "subject_ref", "approver_ref", "submitter_ref", "scope", "state", "submitted_at", "decided_at", "withdrawn_at"];

export const approvalStep = {
  // Operation 1 through 9; no submitted_at is passed, so the atom's now resolves it.
  submit(db: Database, seam: Seam, f: Faults, subject_ref: string, approver_ref: string, submitter_ref: string, scope: string, reason?: string):
    R<string, "invalid-request" | "storage-failure"> {
    if ([subject_ref, approver_ref, submitter_ref, scope].some(blank)) return { refused: "invalid-request" };
    if (reason !== undefined && blank(reason)) return { refused: "invalid-request" };
    if (f.hit("step.submit", approver_ref)) return { refused: "storage-failure" };
    const id = seam.id("step");
    db.prepare(`INSERT INTO step (step_id, subject_ref, approver_ref, submitter_ref, scope, submitted_at, reason, state)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`).run(id, subject_ref, approver_ref, submitter_ref, scope, seam.now(), reason ?? null);
    return { ok: id };
  },
  // Operation 10 through 37, for the three resolving actions.
  resolve(db: Database, seam: Seam, f: Faults, action: "approve" | "reject" | "withdraw", step_id: string, by: string, reason?: string):
    { ok: "approved" | "rejected_outcome" | "withdrawn" } | { refused: StepRefusal } {
    if (blank(step_id)) return { refused: "invalid-request" };
    const s = db.prepare("SELECT * FROM step WHERE step_id = ?").get<StepRecord>(step_id);
    if (!s) return { refused: "not-known" };
    if (s.state !== "pending") return { refused: "not-pending" };
    if (blank(by)) return { refused: "invalid-request" };
    if (action !== "approve" && blank(reason)) return { refused: "invalid-request" };
    if (action === "approve" && reason !== undefined && blank(reason)) return { refused: "invalid-request" };
    const now = seam.now();
    if (now < s.submitted_at) return { refused: "invalid-request" };
    if (action !== "withdraw" && by !== s.approver_ref) return { refused: "unauthorized" };
    if (action === "withdraw" && by !== s.submitter_ref) return { refused: "unauthorized" };
    if (f.hit(`step.${action}`, step_id)) return { refused: "storage-failure" };
    if (action === "withdraw") {
      db.prepare("UPDATE step SET state='withdrawn', withdrawn_by=?, withdrawal_reason=?, withdrawn_at=? WHERE step_id=?").run(by, reason!, now, step_id);
      return { ok: "withdrawn" };
    }
    db.prepare(`UPDATE step SET state=?, decided_by=?, decision_reason=?, decided_at=? WHERE step_id=?`)
      .run(action === "approve" ? "approved" : "rejected", by, reason ?? null, now, step_id);
    return { ok: action === "approve" ? "approved" : "rejected_outcome" };
  },
  // Operation 38 through 48.
  read(db: Database, q: StepQuery): { ok: StepRecord[] } | { refused: "invalid-query" } {
    if (!validStepQuery(q)) return { refused: "invalid-query" };
    const rows = db.prepare("SELECT * FROM step ORDER BY submitted_at, step_id").all<StepRecord>();
    return { ok: rows.filter((s) => stepMatches(s, q)) };
  },
  get(db: Database, step_id: string) { return db.prepare("SELECT * FROM step WHERE step_id = ?").get<StepRecord>(step_id); },
};
export function validStepQuery(q: Record<string, unknown>): boolean {
  for (const [k, v] of Object.entries(q)) {
    if (!STEP_AXES.includes(k)) return false;
    if (typeof v === "string") {
      if (v.trim() === "") return false;
      if (k === "state" && !["pending", "approved", "rejected", "withdrawn"].includes(v)) return false;
    } else if (typeof v === "object" && v !== null) {
      const r = v as { after?: string; before?: string };
      if (r.after && r.before && r.before < r.after) return false;
    } else return false;
  }
  return true;
}
function stepMatches(s: StepRecord, q: StepQuery): boolean {
  for (const [k, v] of Object.entries(q)) {
    const field = (s as unknown as Record<string, string | null>)[k];
    if (typeof v === "string") { if (field !== v) return false; continue; }
    const r = v as { after?: string; before?: string };
    if (field === null) return false;                      // Operation 43
    if (r.after && field <= r.after) return false;
    if (r.before && field >= r.before) return false;
  }
  return true;
}

// ---- Assignment ----
export interface AssignmentRecord { assignment_id: string; task_ref: string; assignee_ref: string; status: string; assigned_at: string; ended_at: string | null }
export const assignment = {
  // Operation 1 through 7.
  assign(db: Database, seam: Seam, f: Faults, task_ref: string, assignee_ref: string): R<string, "invalid-request" | "already-assigned" | "storage-failure"> {
    if (blank(task_ref) || blank(assignee_ref)) return { refused: "invalid-request" };
    if (db.prepare("SELECT 1 FROM assignment WHERE task_ref = ? AND status = 'active'").get(task_ref)) return { refused: "already-assigned" };
    if (f.hit("assignment.assign", task_ref)) return { refused: "storage-failure" };
    const id = seam.id("assignment");
    db.prepare("INSERT INTO assignment VALUES (?, ?, ?, 'active', ?, NULL)").run(id, task_ref, assignee_ref, seam.now());
    return { ok: id };
  },
  // Operation 8 through 13.
  recall(db: Database, seam: Seam, f: Faults, assignment_id: string): R<"ok", "not-known" | "not-active" | "storage-failure"> {
    const a = db.prepare("SELECT status FROM assignment WHERE assignment_id = ?").get<{ status: string }>(assignment_id);
    if (!a) return { refused: "not-known" };
    if (a.status !== "active") return { refused: "not-active" };
    if (f.hit("assignment.recall", assignment_id)) return { refused: "storage-failure" };
    db.prepare("UPDATE assignment SET status='recalled', ended_at=? WHERE assignment_id=?").run(seam.now(), assignment_id);
    return { ok: "ok" };
  },
  active_for(db: Database, task_ref: string): AssignmentRecord | "none" {
    return db.prepare("SELECT * FROM assignment WHERE task_ref = ? AND status = 'active'").get<AssignmentRecord>(task_ref) ?? "none";
  },
  history_for(db: Database, task_ref: string): AssignmentRecord[] {
    return db.prepare("SELECT * FROM assignment WHERE task_ref = ? ORDER BY assigned_at, assignment_id").all<AssignmentRecord>(task_ref);
  },
};

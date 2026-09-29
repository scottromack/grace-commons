// Personal Todo, Permissions and Assignment, as much of each as Shared Todo
// reaches. Permissions and Assignment are carried from the Multi-Party Approval
// regeneration; Assignment gains [Reassign], which that composition never
// reached, and Permissions its read. Personal Todo is rendered here. Rule
// numbers are each atom's own.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
type R<T, E extends string> = { ok: T } | { refused: E };

// ---- Personal Todo ----
export interface Unit { id: string; description: string; state: "pending" | "done"; added_at: string; edited_at: string | null; completed_at: string | null }
const DESCRIPTION_CAP = 1024; // Term description cap, where a deployment declares none
const normalize = (d: string) => d.trim().normalize("NFC"); // Description 1 through 3
const valid = (d: string) => d.length > 0 && [...d].length <= DESCRIPTION_CAP; // Description 4, 5
// The active set is every unit, pending and done (Term active set); compared case-sensitively on the normalized form.
const taken = (db: Database, d: string, except?: string) =>
  db.prepare("SELECT 1 FROM unit WHERE description = ? AND id IS NOT ?").get(d, except ?? null) !== undefined;
export const personalTodo = {
  // Operation 1 through 6.
  add(db: Database, seam: Seam, f: Faults, description: string): R<string, "invalid-description" | "duplicate-active" | "storage-failure"> {
    const d = normalize(description ?? "");
    if (!valid(d)) return { refused: "invalid-description" };
    if (taken(db, d)) return { refused: "duplicate-active" };
    if (f.hit("todo.add")) return { refused: "storage-failure" };
    const id = seam.id("task");
    db.prepare("INSERT INTO unit VALUES (?, ?, 'pending', ?, NULL, NULL)").run(id, d, seam.now());
    return { ok: id };
  },
  // Operation 7 through 14, 21.
  edit(db: Database, seam: Seam, f: Faults, id: string, new_description: string):
    R<"ok", "not-known" | "not-editable" | "invalid-description" | "duplicate-active" | "storage-failure"> {
    const u = db.prepare("SELECT * FROM unit WHERE id = ?").get<Unit>(id);
    if (!u) return { refused: "not-known" };
    if (u.state === "done") return { refused: "not-editable" };
    const d = normalize(new_description ?? "");
    if (!valid(d)) return { refused: "invalid-description" };
    if (d === u.description) return { ok: "ok" };
    if (taken(db, d, id)) return { refused: "duplicate-active" };
    if (f.hit("todo.edit")) return { refused: "storage-failure" };
    db.prepare("UPDATE unit SET description = ?, edited_at = ? WHERE id = ?").run(d, seam.now(), id);
    return { ok: "ok" };
  },
  // Operation 15 through 17, 22.
  complete(db: Database, seam: Seam, f: Faults, id: string): R<"ok", "not-known" | "not-pending" | "storage-failure"> {
    const u = db.prepare("SELECT state FROM unit WHERE id = ?").get<{ state: string }>(id);
    if (!u) return { refused: "not-known" };
    if (u.state === "done") return { refused: "not-pending" };
    if (f.hit("todo.complete")) return { refused: "storage-failure" };
    db.prepare("UPDATE unit SET state = 'done', completed_at = ? WHERE id = ?").run(seam.now(), id);
    return { ok: "ok" };
  },
  // Operation 18 through 20, 23: the unit leaves the list; its id is never reused (Identity 5).
  delete(db: Database, f: Faults, id: string): R<"ok", "not-known" | "storage-failure"> {
    if (!db.prepare("SELECT 1 FROM unit WHERE id = ?").get(id)) return { refused: "not-known" };
    if (f.hit("todo.delete")) return { refused: "storage-failure" };
    db.prepare("DELETE FROM unit WHERE id = ?").run(id);
    return { ok: "ok" };
  },
  // Operation 28 through 31.
  read(db: Database): Unit[] { return db.prepare("SELECT * FROM unit ORDER BY added_at, id").all<Unit>(); },
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
  // Operation 26: every grant, active and revoked.
  read(db: Database) { return db.prepare("SELECT * FROM grant_record ORDER BY granted_at, grant_id").all<Record<string, string | null>>(); },
  permitted(db: Database, subject_ref: string, action_scope: string): "permitted" | "denied" {
    return db.prepare("SELECT 1 FROM grant_record WHERE subject_ref = ? AND action_scope = ? AND status = 'active'").get(subject_ref, action_scope)
      ? "permitted" : "denied";
  },
};

// ---- Assignment ----
export interface AssignmentRecord { assignment_id: string; task_ref: string; assignee_ref: string; status: string; assigned_at: string; ended_at: string | null }
export const assignment = {
  // Operation 1 through 7.
  assign(db: Database, seam: Seam, f: Faults, task_ref: string, assignee_ref: string): R<string, "invalid-request" | "already-assigned" | "storage-failure"> {
    if (blank(task_ref) || blank(assignee_ref)) return { refused: "invalid-request" };
    if (db.prepare("SELECT 1 FROM assignment WHERE task_ref = ? AND status = 'active'").get(task_ref)) return { refused: "already-assigned" };
    if (f.hit("assignment.assign")) return { refused: "storage-failure" };
    const id = seam.id("assignment");
    db.prepare("INSERT INTO assignment VALUES (?, ?, ?, 'active', ?, NULL)").run(id, task_ref, assignee_ref, seam.now());
    return { ok: id };
  },
  // Operation 8 through 13.
  recall(db: Database, seam: Seam, f: Faults, assignment_id: string): R<"ok", "not-known" | "not-active" | "storage-failure"> {
    const a = db.prepare("SELECT status FROM assignment WHERE assignment_id = ?").get<{ status: string }>(assignment_id);
    if (!a) return { refused: "not-known" };
    if (a.status !== "active") return { refused: "not-active" };
    if (f.hit("assignment.recall")) return { refused: "storage-failure" };
    db.prepare("UPDATE assignment SET status='recalled', ended_at=? WHERE assignment_id=?").run(seam.now(), assignment_id);
    return { ok: "ok" };
  },
  // Operation 14 through 23: the old assignment transferred and the new one active, in one transaction.
  reassign(db: Database, seam: Seam, f: Faults, assignment_id: string, new_assignee_ref: string):
    R<string, "not-known" | "not-active" | "invalid-request" | "storage-failure"> {
    const a = db.prepare("SELECT * FROM assignment WHERE assignment_id = ?").get<AssignmentRecord>(assignment_id);
    if (!a) return { refused: "not-known" };
    if (a.status !== "active") return { refused: "not-active" };
    if (blank(new_assignee_ref)) return { refused: "invalid-request" };
    if (f.hit("assignment.reassign")) return { refused: "storage-failure" };
    const now = seam.now(), id = seam.id("assignment");
    db.exec("BEGIN");
    db.prepare("UPDATE assignment SET status='transferred', ended_at=? WHERE assignment_id=?").run(now, assignment_id);
    db.prepare("INSERT INTO assignment VALUES (?, ?, ?, 'active', ?, NULL)").run(id, a.task_ref, new_assignee_ref, now);
    db.exec("COMMIT");
    return { ok: id };
  },
  active_for(db: Database, task_ref: string): AssignmentRecord | "none" {
    return db.prepare("SELECT * FROM assignment WHERE task_ref = ? AND status = 'active'").get<AssignmentRecord>(task_ref) ?? "none";
  },
  history_for(db: Database, task_ref: string): AssignmentRecord[] {
    return db.prepare("SELECT * FROM assignment WHERE task_ref = ? ORDER BY assigned_at, assignment_id").all<AssignmentRecord>(task_ref);
  },
};

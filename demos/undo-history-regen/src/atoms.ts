// Personal Todo and Event Log, as much of each as Undo History reaches.
// Personal Todo is carried from the Shared Todo regeneration, Event Log from
// the atoms Audit Trail reaches in the Login regeneration; Event Log's read
// takes a query and answers invalid-query, which Login never reached. Rule
// numbers are each atom's own.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

type R<T, E extends string> = { ok: T } | { refused: E };

// ---- Personal Todo ----
export interface Unit { id: string; description: string; state: "pending" | "done"; added_at: string; edited_at: string | null; completed_at: string | null }
const DESCRIPTION_CAP = 1024; // Term description cap, where a deployment declares none
export const normalize = (d: string) => d.trim().normalize("NFC"); // Description 1 through 3
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

// ---- Event Log ----
export interface LoggedEvent { seq: number; event_id: string; recorded_at: string; data: string | null }
export const eventLog = {
  append(db: Database, seam: Seam, f: Faults, data: string, cap: number): R<string, "invalid-payload" | "storage-failure"> {
    if (data.length > cap) return { refused: "invalid-payload" };
    if (f.hit("log.append")) return { refused: "storage-failure" };
    const id = seam.id("event");
    db.prepare("INSERT INTO event (event_id, recorded_at, data) VALUES (?, ?, ?)").run(id, seam.now(), data);
    return { ok: id };
  },
  // Operation 13 through 18: the query is a sequence-number range, rising; an open upper bound when to is absent.
  read(db: Database, query: { from: number; to?: number }): R<LoggedEvent[], "invalid-query"> {
    const { from, to } = query ?? {} as { from: number };
    if (!Number.isInteger(from) || from < 1 || (to !== undefined && (!Number.isInteger(to) || to < from))) return { refused: "invalid-query" };
    return { ok: eventLog.rows(db, from, to) };
  },
  rows(db: Database, from: number, to?: number): LoggedEvent[] {
    return to === undefined
      ? db.prepare("SELECT * FROM event WHERE seq >= ? ORDER BY seq").all<LoggedEvent>(from)
      : db.prepare("SELECT * FROM event WHERE seq >= ? AND seq <= ? ORDER BY seq").all<LoggedEvent>(from, to);
  },
};


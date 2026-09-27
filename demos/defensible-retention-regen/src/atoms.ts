// Legal Hold, from atoms/legal-hold.md; rule numbers are the atom's own. The
// business Retention Window instance is the same atom Audit Trail carries
// (audit_atoms.ts), run over the business database.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";
export interface Hold { hold_id: string; record_ref: string; placed_by: string; reason: string; case_ref: string | null; placed_at: string;
  state: "active" | "released"; released_by: string | null; release_reason: string | null; released_at: string | null }
export type HoldQuery = { hold_id?: string; record_ref?: string; placed_by?: string; case_ref?: string; hold_state?: string };
const AXES: Record<string, string> = { hold_id: "hold_id", record_ref: "record_ref", placed_by: "placed_by", case_ref: "case_ref", hold_state: "state" };

export const legalHold = {
  place(db: Database, seam: Seam, f: Faults, record_ref: string, placed_by: string, reason: string, case_ref?: string, placed_at?: string):
    { ok: string } | { refused: "invalid-request" | "storage-failure" } {
    const now = seam.now();
    if (blank(record_ref) || blank(placed_by) || blank(reason)) return { refused: "invalid-request" };          // Operation 4 through 6
    if (case_ref !== undefined && blank(case_ref)) return { refused: "invalid-request" };                     // 7
    if (placed_at !== undefined && now < placed_at) return { refused: "invalid-request" };                    // 8, 10
    if (f.hit("hold.place", record_ref)) return { refused: "storage-failure" };                                // 11
    const id = seam.id("hold");
    db.prepare("INSERT INTO hold VALUES (?, ?, ?, ?, ?, ?, 'active', NULL, NULL, NULL)").run(id, record_ref, placed_by, reason, case_ref ?? null, placed_at ?? now);  // 9
    return { ok: id };
  },
  release(db: Database, seam: Seam, f: Faults, hold_id: string, released_by: string, reason: string, released_at?: string):
    { ok: "released" } | { refused: "invalid-request" | "not-known" | "already-released" | "storage-failure" } {
    const now = seam.now();
    if (blank(hold_id)) return { refused: "invalid-request" };                                                  // 12
    const h = db.prepare("SELECT * FROM hold WHERE hold_id = ?").get<Hold>(hold_id);
    if (!h) return { refused: "not-known" };                                                                    // 13
    if (h.state === "released") return { refused: "already-released" };                                        // 14
    if (blank(released_by) || blank(reason)) return { refused: "invalid-request" };                            // 15, 16
    if (released_at !== undefined && now < released_at) return { refused: "invalid-request" };                 // 18
    const at = released_at ?? now;                                                                              // 18a
    if (at < h.placed_at) return { refused: "invalid-request" };                                               // 17
    if (f.hit("hold.release", hold_id)) return { refused: "storage-failure" };                                  // 21, 22
    db.prepare("UPDATE hold SET state='released', released_by=?, release_reason=?, released_at=? WHERE hold_id=?").run(released_by, reason, at, hold_id);
    return { ok: "released" };
  },
  // Operation 23 through 34. A fault here stands for a store the read cannot reach.
  read(db: Database, f: Faults, query: HoldQuery): { ok: Hold[] } | { refused: "invalid-query" } | { unreachable: true } {
    const where: string[] = [], args: string[] = [];
    for (const [k, v] of Object.entries(query)) {
      if (!(k in AXES)) return { refused: "invalid-query" };                                                    // 27
      if (blank(v)) return { refused: "invalid-query" };                                                        // 28
      if (k === "hold_state" && v !== "active" && v !== "released") return { refused: "invalid-query" };       // 29
      where.push(`${AXES[k]} = ?`); args.push(v!);
    }
    if (f.hit("hold.read", query.record_ref)) return { unreachable: true };
    const sql = `SELECT * FROM hold ${where.length ? "WHERE " + where.join(" AND ") : ""} ORDER BY placed_at, hold_id`;  // 24, 25
    return { ok: db.prepare(sql).all<Hold>(...args) };
  },
};

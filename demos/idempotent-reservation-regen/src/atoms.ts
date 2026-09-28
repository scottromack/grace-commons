// Provisional Commitment and Duplicate Prevention, from their pages; rule numbers
// are each atom's own. Each reads the host clock once per call.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: unknown) => s === undefined || s === null || (typeof s === "string" && s.trim() === "");
export interface Commitment { id: string; resource: string; requester: string; placed_at: string; expires_at: string; state: string; terminal_at: string | null }
export type PcAnswer = { ok: string } | { refused: string };

export const provisionalCommitment = {
  // Operation 1 through 13. The resource registry is the host's: here, a resource is unavailable while a held or confirmed commitment covers it.
  place_hold(db: Database, seam: Seam, f: Faults, resource: string, requester: string, durationMs: number, bounds: [number, number]): PcAnswer {
    const now = seam.now();
    if (blank(resource) || blank(requester) || blank(durationMs)) return { refused: "invalid-request" };
    if (durationMs < bounds[0] || durationMs > bounds[1]) return { refused: "invalid-request" };                  // 4
    const busy = db.prepare("SELECT 1 FROM commitment WHERE resource = ? AND (state = 'confirmed' OR (state = 'held' AND expires_at > ?))").get(resource, now);
    if (busy) return { refused: "resource-unavailable" };                                                          // 5, 6
    if (f.hit("pc.write", resource)) return { refused: "storage-failure" };                                        // 28, 31
    const id = seam.id("hold");
    db.prepare("INSERT INTO commitment VALUES (?, ?, ?, ?, ?, 'held', NULL)").run(id, resource, requester, now, new Date(Date.parse(now) + durationMs).toISOString());
    return { ok: id };
  },
  // Operation 14 through 32.
  resolve(db: Database, seam: Seam, f: Faults, kind: "confirm" | "release" | "expire", id: string): PcAnswer {
    const now = seam.now();
    const c = db.prepare("SELECT * FROM commitment WHERE id = ?").get<Commitment>(id);
    if (!c) return { refused: "not-known" };                                                                       // 14
    if (c.state !== "held") return { refused: "not-held" };                                                        // 15
    const lapsed = !(c.expires_at > now);
    if (lapsed && kind !== "expire") return { refused: "window-elapsed" };                                         // 17, 18
    if (!lapsed && kind === "expire") return { refused: "window-not-elapsed" };                                    // 19
    if (f.hit("pc.write", id)) return { refused: "storage-failure" };
    const state = { confirm: "confirmed", release: "released", expire: "expired" }[kind];
    db.prepare("UPDATE commitment SET state = ?, terminal_at = ? WHERE id = ?").run(state, now, id);             // 21 through 27
    return { ok: "ok" };
  },
  read(db: Database): Commitment[] { return db.prepare("SELECT * FROM commitment ORDER BY placed_at, id").all<Commitment>(); },  // 38 through 41
};

export const duplicatePrevention = {
  record(db: Database, seam: Seam, identity: string): "ok" {                                                       // Operation 1 through 4
    db.prepare("INSERT INTO guard VALUES (?, ?) ON CONFLICT(identity) DO UPDATE SET recorded_at = excluded.recorded_at").run(identity, seam.now());
    return "ok";
  },
  // Operation 5 through 7. A fault stands for an unreachable store; the deployment resolves it (Capability requirement 16).
  check(db: Database, seam: Seam, f: Faults, identity: string, windowMs: number): "seen" | "not-seen" | "unavailable" {
    if (f.hit("dp.check", identity)) return "unavailable";
    const r = db.prepare("SELECT recorded_at FROM guard WHERE identity = ?").get<{ recorded_at: string }>(identity);
    return r && Date.parse(seam.now()) - Date.parse(r.recorded_at) < windowMs ? "seen" : "not-seen";
  },
};

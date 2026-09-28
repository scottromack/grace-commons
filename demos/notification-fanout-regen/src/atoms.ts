// Subscription and Notification, as far as the fanout reaches them; rule numbers
// are each atom's own.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: unknown) => s === undefined || s === null || (typeof s === "string" && s.trim() === "");
export const subscription = {
  subscribe(db: Database, seam: Seam, subscriber_ref: string, event_scope: string): { ok: string } | { refused: string } {
    if (blank(subscriber_ref) || blank(event_scope)) return { refused: "invalid-request" };                      // Operation 4, 5
    if (db.prepare("SELECT 1 FROM subscription WHERE subscriber_ref = ? AND event_scope = ? AND status = 'active'").get(subscriber_ref, event_scope))
      return { refused: "already-subscribed" };                                                                   // 6
    const id = seam.id("sub");
    db.prepare("INSERT INTO subscription VALUES (?, ?, ?, 'active', ?, NULL)").run(id, subscriber_ref, event_scope, seam.now());
    return { ok: id };
  },
  cancel(db: Database, seam: Seam, id: string): { ok: "ok" } | { refused: string } {
    const s = db.prepare("SELECT status FROM subscription WHERE subscription_id = ?").get<{ status: string }>(id);
    if (!s) return { refused: "not-known" };                                                                      // 9
    if (s.status === "cancelled") return { refused: "not-active" };                                               // 10
    db.prepare("UPDATE subscription SET status = 'cancelled', cancelled_at = ? WHERE subscription_id = ?").run(seam.now(), id);
    return { ok: "ok" };
  },
  // Operation 19 through 23. A fault stands for a store the read cannot reach, outside the signature.
  subscribers_for(db: Database, f: Faults, event_scope: string): string[] | "unavailable" {
    if (f.hit("sub.read", event_scope)) return "unavailable";
    return db.prepare("SELECT subscriber_ref FROM subscription WHERE event_scope = ? AND status = 'active'").all<{ subscriber_ref: string }>(event_scope).map((r) => r.subscriber_ref);
  },
};

// Create's answers: the declared two, and a call that never answers — a timeout, or a commit whose id is lost.
export type CreateAnswer = { ok: string } | { refused: "invalid-request" | "storage-failure" } | "no-answer";
export const notification = {
  create(db: Database, seam: Seam, f: Faults, recipient_ref: string, payload: string, cap: number): CreateAnswer {
    if (blank(recipient_ref) || recipient_ref.length > cap || payload.length > cap) return { refused: "invalid-request" };  // Operation 4, 5; String 5, 6
    if (f.hit("notif.hang", recipient_ref)) return "no-answer";
    if (f.hit("notif.store", recipient_ref)) return { refused: "storage-failure" };                              // Operation 7: nothing recorded
    const id = seam.id("notif");
    db.prepare("INSERT INTO notification VALUES (?, ?, ?, 'pending', ?, NULL)").run(id, recipient_ref, payload, seam.now());
    if (f.hit("notif.lost", recipient_ref)) return "no-answer";                                                   // committed; the id never came back
    return { ok: id };
  },
  status_of(db: Database, id: string) { return db.prepare("SELECT * FROM notification WHERE notification_id = ?").get<{ recipient_ref: string; payload: string; status: string }>(id) ?? "not-known"; },
};

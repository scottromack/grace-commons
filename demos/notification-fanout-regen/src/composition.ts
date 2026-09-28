// Notification Fanout, rendered from compositions/notification-fanout.md. Every
// rule cited is that page's unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { notification, subscription } from "./atoms.ts";

export interface FanoutResult { fanout_id: string; created: string[]; failed: string[]; fired_at: string }
export interface Config { notificationStringCap: number }   // the Notification instance's string cap, which the fanout does not own

export function fanout(db: Database, seam: Seam, f: Faults, c: Config, event_scope: string, payload: unknown):
  FanoutResult | { refused: "invalid-request" | "subscribers-unavailable" } {
  const blank = (s: unknown) => s === undefined || s === null || (typeof s === "string" && s.trim() === "");
  if (blank(event_scope) || payload === undefined || payload === null) return { refused: "invalid-request" };  // Primitive policy 1, 2, 4
  const fired_at = seam.now(), fanout_id = seam.id("fanout");                                 // Primitive policy 3; Action wiring 2, 3; Invariant 8.2
  const subs = subscription.subscribers_for(db, f, event_scope);                              // Action wiring 1; Composes 5
  if (subs === "unavailable") return { refused: "subscribers-unavailable" };                  // 4 through 6: the id is discarded
  const body = typeof payload === "string" ? payload : JSON.stringify(payload);               // one payload for every record (Invariant 2.1)
  const created: string[] = [], failed: string[] = [];
  for (const ref of subs) {                                                                   // 7, 9, 12; Wiring decision 1 through 3
    const a = notification.create(db, seam, f, ref, body, c.notificationStringCap);          // 8
    if (a !== "no-answer" && "ok" in a) created.push(a.ok);                                   // 10
    else failed.push(ref);                                                                    // 11, 18; an unrecordable create is indeterminate (Indeterminate outcome 1, 2)
  }
  return { fanout_id, created, failed, fired_at };                                            // 13, 14
}

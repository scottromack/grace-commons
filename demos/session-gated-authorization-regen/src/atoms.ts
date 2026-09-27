// Session and Permissions, as much of each as the gate and its tests reach.
// Rule numbers are each atom's own. The host's clock is one function, read
// once per call at each constituent's seam.
import type { Database } from "@db/sqlite";

export type Clock = () => string;
let n = 0;
const nextId = (kind: string) => `${kind}-${String(++n).padStart(3, "0")}`;  // the host mints; the atoms never do

// ---- Session ----
export type Validation = { valid: { principal_ref: string; expires_at: string } } | { invalid: "expired" | "revoked" | "not-known" };
export const session = {
  issue(db: Database, now: Clock, principal_ref: string, issued_by_ref: string, durationMs: number): string {
    const t = now(), token = nextId("tok");
    db.prepare("INSERT INTO session VALUES (?, ?, ?, ?, ?, 'active', NULL, NULL, NULL)")
      .run(token, principal_ref, issued_by_ref, t, new Date(Date.parse(t) + durationMs).toISOString());
    return token;
  },
  // Operation 13 through 21: revoked before lapsed; never writes, never refuses.
  validate(db: Database, now: Clock, token: string): Validation {
    const s = db.prepare("SELECT * FROM session WHERE session_token = ?").get<{ principal_ref: string; expires_at: string; status: string }>(token);
    if (!s) return { invalid: "not-known" };
    if (s.status === "revoked") return { invalid: "revoked" };
    if (!(now() < s.expires_at)) return { invalid: "expired" };
    return { valid: { principal_ref: s.principal_ref, expires_at: s.expires_at } };
  },
  revoke(db: Database, now: Clock, token: string, by: string, reason: string) {
    db.prepare("UPDATE session SET status='revoked', revoked_at=?, revoked_by_ref=?, revocation_reason=? WHERE session_token=? AND status='active'")
      .run(now(), by, reason, token);
  },
};

// ---- Permissions ----
export const permissions = {
  // String 6: the deployment's string cap.
  stringCap: 256,
  grant(db: Database, now: Clock, subject_ref: string, action_scope: string): string {
    const id = nextId("grant");
    db.prepare("INSERT INTO grant_record VALUES (?, ?, ?, 'active', ?, NULL)").run(id, subject_ref, action_scope, now());
    return id;
  },
  revoke(db: Database, now: Clock, grant_id: string) {
    db.prepare("UPDATE grant_record SET status='revoked', revoked_at=? WHERE grant_id=? AND status='active'").run(now(), grant_id);
  },
  // Operation 16 through 22; String 7: an over-length argument matches nothing.
  permitted(db: Database, subject_ref: string, action_scope: string): "permitted" | "denied" {
    if (subject_ref.length > permissions.stringCap || action_scope.length > permissions.stringCap) return "denied";
    return db.prepare("SELECT 1 FROM grant_record WHERE subject_ref = ? AND action_scope = ? AND status = 'active'").get(subject_ref, action_scope)
      ? "permitted" : "denied";
  },
};

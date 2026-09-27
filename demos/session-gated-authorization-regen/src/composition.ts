// Session-Gated Authorization, rendered from
// compositions/session-gated-authorization.md. One action, no stored state
// (Composition state 1 through 3).
import type { Database } from "@db/sqlite";
import { type Clock, permissions, session } from "./atoms.ts";

export type Answer = "permitted" | "denied" | "invalid-request" | { "session-invalid": "expired" | "revoked" | "not-known" };

export class SessionGatedAuthorization {
  private constructor(private db: Database, private now: Clock, readonly lengthBound: number) {}

  // Primitive policy 1 and 10: the deployment pins the bound, never above the
  // Permissions instance's string cap.
  static start(db: Database, now: Clock, lengthBound: number): SessionGatedAuthorization {
    if (!(lengthBound > 0)) throw new Error("the length bound is not pinned");
    if (lengthBound > permissions.stringCap) throw new Error("the length bound exceeds the Permissions string cap");
    return new SessionGatedAuthorization(db, now, lengthBound);
  }

  // [Check Permitted]: takes no principal reference (Action wiring 7).
  check_permitted(session_token: string, action_scope: string): Answer {
    // Primitive policy 2 through 9: blank or over the bound, refused before either constituent; nothing trimmed.
    for (const s of [session_token, action_scope]) {
      if (s.trim() === "" || new TextEncoder().encode(s).length > this.lengthBound) return "invalid-request";
    }
    const v = session.validate(this.db, this.now, session_token);                        // Action wiring 2, 3, 13, 14
    if ("invalid" in v) return { "session-invalid": v.invalid };                        // 9
    // Wiring decision 1; Action wiring 5, 6, 8, 10, 11: the session's own principal, the answer unchanged,
    // and the expiry instant goes no further (12).
    return permissions.permitted(this.db, v.valid.principal_ref, action_scope);
  }
}

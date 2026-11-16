// Session-Gated Authorization — may this session's principal do this?
// Rendered from compositions/session-gated-authorization.md (the page at the commit the entry names), with no
// code of any other render opened. A rule's label is in the comment where the code answers it.
//
// The composition holds no state and writes nothing (Composition state 1, 2; Action wiring 15). One action,
// [Check Permitted]: the session gates the permission check, and the principal Permissions is asked about is the
// one Session's validate answered, never one the caller names (Action wiring 7, 8; Invariant 2).
import { Unavailable } from "./store.ts";
import { isBlank } from "./seam.ts";
import { type Session } from "./session.ts";
import { type Permissions } from "./permissions.ts";

export type CheckAnswer =
  | "permitted"
  | "denied"
  | { refused: "invalid-request" }
  | { refused: "session-invalid"; reason: "expired" | "revoked" | "not-known" }
  | { refused: "state-unavailable" };

export class SessionGatedAuthorization {
  private readonly lengthBound: number;

  constructor(private session: Session, private permissions: Permissions, lengthBound?: number) {
    this.lengthBound = lengthBound ?? permissions.stringCap;                                                 // Term length bound: the Permissions instance's string cap where none is declared
    if (this.lengthBound > permissions.stringCap) throw new Error("the length bound must not exceed the Permissions instance's string cap"); // Primitive policy 10
  }

  async checkPermitted(session_token: string, action_scope: string): Promise<CheckAnswer> {
    // Action wiring 1, 2; Primitive policy 2, 3, 4, 9: the boundary predicate first, no constituent called for an input it refuses.
    // Inputs are compared as they stand: not trimmed, case-folded or normalized (Primitive policy 5 to 8).
    if (isBlank(session_token) || isBlank(action_scope)) return { refused: "invalid-request" };
    if ([...session_token].length > this.lengthBound || [...action_scope].length > this.lengthBound) return { refused: "invalid-request" };
    try {
      const v = await this.session.validate(session_token);                                                   // Action wiring 3, 13, 14: every call, fresh
      if ("invalid" in v) return { refused: "session-invalid", reason: v.invalid };                           // Action wiring 9: Permissions is not called (Invariant 1.1)
      return await this.permissions.permitted(v.valid.principal_ref, action_scope);                           // Action wiring 5, 6, 10, 11: the principal is Session's, the answer is Permissions' unchanged; the expiry is not answered (12)
    } catch (e) {
      if (e instanceof Unavailable) return { refused: "state-unavailable" };                                  // Execution Contract Constituent failure 3
      throw e;
    }
  }
}

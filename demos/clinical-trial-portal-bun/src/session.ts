// Session — is this login still good, and for whom?
// Rendered from atoms/session.md (the page at the commit the entry names), with no code of any other
// render opened. A rule's label is in the comment where the code answers it.
//
// A session is one record in the table `sessions`, whose _id is the session token (Identity 1, 7). The deployment
// holds the token raw (Capability requirement 6 leaves that to it; Beacon's choice, said in the entry),
// and no read answers it (Operation 52). A revoke is a new version of the record under the same _id
// (Execution Contract Database 5); a lapse writes nothing (Expiry 2, Invariant 12.3).
import { Store, Guard, type Row } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";

export type SessionRefusal = "invalid-request" | "not-known" | "already-terminal" | "storage-failure";
export type ValidationFailure = "expired" | "revoked" | "not-known";

export interface SessionView {
  principal_ref: string;
  issued_by_ref: string;
  issued_at: string;
  expires_at: string;
  status: "active" | "revoked";
  /** expired where an active session is lapsed, the stored status otherwise (Operation 38; Invariant 12.4). */
  effective_status: "active" | "revoked" | "expired";
  revoked_at: string | null;
  revoked_by_ref: string | null;
  revocation_reason: string | null;
}

export interface SessionConfig {
  /** The default session duration in seconds (Capability requirement 2); null is blank, which refuses every issue (Operation 48). */
  defaultDurationSeconds: number | null;
  /** The cap on a reference's length in Unicode code points (Execution Contract Input 2). */
  referenceCap?: number;
}

type Stored = Row & {
  _id: string; principal_ref: string; issued_by_ref: string; issued_at: string; expires_at: string;
  status: "active" | "revoked"; revoked_at: string | null; revoked_by_ref: string | null; revocation_reason: string | null;
};

const T = "sessions"; // not `session`: that is a reserved word of XTDB SQL
const COLUMNS = ["principal_ref", "issued_by_ref", "issued_at", "expires_at", "status", "revoked_at", "revoked_by_ref", "revocation_reason"];
const FILTER_FIELDS = ["principal_ref", "issued_by_ref"];

export class Session {
  private constructor(private store: Store, private seam: Seam, private config: SessionConfig) {}

  static async open(store: Store, seam: Seam, config: SessionConfig): Promise<Session> {
    await store.declare(T, COLUMNS);
    return new Session(store, seam, config);
  }

  private tooLong(v: string): boolean {
    return [...v].length > (this.config.referenceCap ?? 256);
  }

  // Term lapsed: stored active and now no earlier than the expiry instant.
  private static lapsed(s: Stored, now: string): boolean {
    return s.status === "active" && now >= s.expires_at;
  }

  async issue(principal_ref: string, issued_by_ref: string, session_duration?: number | null): Promise<{ session_token: string } | { refused: SessionRefusal }> {
    if (isBlank(principal_ref) || isBlank(issued_by_ref)) return { refused: "invalid-request" };              // Operation 4, 5
    if (this.tooLong(principal_ref) || this.tooLong(issued_by_ref)) return { refused: "invalid-request" };    // String 7
    const d = this.config.defaultDurationSeconds;
    if (d === null) return { refused: "invalid-request" };                                                   // Operation 48
    if (!(Number.isFinite(d) && d > 0)) return { refused: "invalid-request" };                               // Operation 56
    let seconds = d;                                                                                         // Operation 6
    if (session_duration !== undefined && session_duration !== null) {
      if (typeof session_duration !== "number" || !Number.isInteger(session_duration)) return { refused: "invalid-request" }; // Operation 55
      if (session_duration <= 0) return { refused: "invalid-request" };                                      // Operation 8
      seconds = session_duration;
    }
    const now = this.seam.now();                                                                             // Operation 9
    const expires = new Date(Date.parse(now) + seconds * 1000).toISOString();                                // Operation 10, 11
    const token = this.seam.sessionToken();                                                                  // Identity 3, Operation 58
    try {
      await this.store.commit([
        this.store.assertNone(T, "_id = $1", [token], "token-held"),                                         // Invariant 7.1
        this.store.put(T, {
          _id: token, principal_ref, issued_by_ref, issued_at: now, expires_at: expires, status: "active",   // Operation 2, 50, 51
          revoked_at: null, revoked_by_ref: null, revocation_reason: null,
        }),
      ]);
    } catch {
      return { refused: "storage-failure" };                                                                 // Operation 12
    }
    return { session_token: token };                                                                         // Operation 3
  }

  async validate(session_token: string): Promise<{ valid: { principal_ref: string; expires_at: string } } | { invalid: ValidationFailure }> {
    const s = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [session_token ?? ""]))[0];
    if (!s) return { invalid: "not-known" };                                                                 // Operation 14
    if (s.status === "revoked") return { invalid: "revoked" };                                               // Operation 15, Invariant 3.3
    if (Session.lapsed(s, this.seam.now())) return { invalid: "expired" };                                   // Operation 16, 17
    return { valid: { principal_ref: s.principal_ref, expires_at: s.expires_at } };                          // Operation 18, 19
  }

  async revoke(session_token: string, revoked_by_ref: string, reason: string): Promise<"revoked" | { refused: SessionRefusal }> {
    const s = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [session_token ?? ""]))[0];
    if (!s) return { refused: "not-known" };                                                                 // Operation 22
    if (s.status === "revoked") return { refused: "already-terminal" };                                      // Operation 23, 24
    if (isBlank(revoked_by_ref) || this.tooLong(revoked_by_ref)) return { refused: "invalid-request" };      // Operation 25, String 9
    if (isBlank(reason) || typeof reason !== "string") return { refused: "invalid-request" };                // Operation 26, 57
    const now = this.seam.now();                                                                             // Operation 27: a lapsed session is accepted
    try {
      await this.store.commit([
        this.store.assertSome(T, "_id = $1 AND status = 'active'", [s._id], "terminal"),
        this.store.put(T, { ...s, status: "revoked", revoked_at: now, revoked_by_ref, revocation_reason: reason }), // Operation 28 to 31
      ]);
    } catch (e) {
      if (e instanceof Guard) return { refused: "already-terminal" };
      return { refused: "storage-failure" };                                                                 // Operation 34
    }
    return "revoked";                                                                                        // Operation 33
  }

  /** Every matching session with its effective status; never the token (Operation 37, 38, 52, 59, 60). */
  async read(filter: { principal_ref?: string; issued_by_ref?: string } & Record<string, string | undefined> = {}): Promise<SessionView[]> {
    const named = Object.entries(filter).filter(([, v]) => v !== undefined);
    if (named.some(([k]) => !FILTER_FIELDS.includes(k))) return [];                                          // Operation 61: a field other than the two
    if (named.some(([, v]) => isBlank(v) || this.tooLong(v as string))) return [];                           // Operation 53, 61
    const where = named.map(([k], i) => `${k} = $${i + 1}`).join(" AND ");
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T}${where ? " WHERE " + where : ""}`, named.map(([, v]) => v as string));
    const now = this.seam.now();
    rows.sort((a, b) => (a.issued_at < b.issued_at ? -1 : a.issued_at > b.issued_at ? 1 : 0));
    return rows.map((s) => ({
      principal_ref: s.principal_ref, issued_by_ref: s.issued_by_ref, issued_at: s.issued_at, expires_at: s.expires_at,
      status: s.status, effective_status: Session.lapsed(s, now) ? "expired" : s.status,
      revoked_at: s.revoked_at, revoked_by_ref: s.revoked_by_ref, revocation_reason: s.revocation_reason,
    }));
  }
}

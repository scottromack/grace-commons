// Invitation — the life of an invitation issued to an outside party before that party has an identity.
// Rendered from atoms/invitation.md (the page at the commit the entry names), with no code of any other
// render opened. A rule's label is in the comment where the code answers it.
//
// An invitation is one record under its invitation token, the bearer credential a holder presents
// (Identity 1, 2). A resolving write is a new version of the record under the same token (Execution
// Contract Database 5); a stored terminal is absorbing, so a second resolution of one invitation is
// refused whole: the guard is an ASSERT on the pending status inside the write's own transaction
// (Database 2). Expiry is derived at each read and never stored (State 7, Invariant 12.1).
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";

export type Status = "pending" | "accepted" | "declined" | "revoked";
export interface InvitationView {
  invitation_token: string; inviter_ref: string; invitee_ref: string | null; context: string; initiated_at: string; expires_at: string;
  status: Status; effective_status: Status | "expired";
  accepting_identity_ref: string | null; accepted_at: string | null; declined_at: string | null;
  revoked_by_ref: string | null; revocation_reason: string | null; revoked_at: string | null;
}
export type ResolveRefusal =
  | { refused: "not-known" | "expired" | "invalid-request" | "storage-failure" }
  | { refused: "already-resolved"; status: "accepted" | "declined" | "revoked" };

export interface InvitationConfig {
  /** The ttl bounds, in whole seconds, inclusive: every admitted value exceeds zero (Term ttl bounds). */
  ttlBounds: { min: number; max: number };
  /** The default ttl in seconds, inside the bounds (Capability requirement 4); null where the deployment declares none (Operation 5). */
  defaultTtl: number | null;
  /** The string cap in code points (Capability requirement 13): 256 where none is declared. */
  stringCap?: number;
  /** The table this instance keeps its invitations in (a test world names its own). */
  table?: string;
}

type Stored = Row & {
  _id: string; inviter_ref: string; invitee_ref: string | null; context: string; initiated_at: string; expires_at: string; status: Status;
  accepting_identity_ref: string | null; accepted_at: string | null; declined_at: string | null; revoked_by_ref: string | null; revocation_reason: string | null; revoked_at: string | null;
};

const T = "invitations";
const COLUMNS = ["inviter_ref", "invitee_ref", "context", "initiated_at", "expires_at", "status", "accepting_identity_ref", "accepted_at", "declined_at", "revoked_by_ref", "revocation_reason", "revoked_at"];

export class Invitation {
  private readonly T: string;
  private constructor(private store: Store, private seam: Seam, private cfg: InvitationConfig) {
    this.T = cfg.table ?? T;
  }

  static async open(store: Store, seam: Seam, cfg: InvitationConfig): Promise<Invitation> {
    if (cfg.defaultTtl !== null && !(cfg.defaultTtl >= cfg.ttlBounds.min && cfg.defaultTtl <= cfg.ttlBounds.max)) throw new Error("the default ttl must lie inside the ttl bounds"); // Capability requirement 4
    if (!(cfg.ttlBounds.min > 0 && cfg.ttlBounds.max >= cfg.ttlBounds.min)) throw new Error("every admitted ttl exceeds zero");                                // Term ttl bounds
    await store.declare(cfg.table ?? T, COLUMNS);
    return new Invitation(store, seam, cfg);
  }

  private long(v: string): boolean {
    return [...v].length > (this.cfg.stringCap ?? 256);
  }
  private static lapsed(i: Stored, now: string): boolean {
    return i.status === "pending" && now >= i.expires_at;                                                     // Term lapsed: the boundary instant reads lapsed
  }

  async initiate(inviter_ref: string, invitee_ref: string | null | undefined, context: string, ttl?: number | null): Promise<{ invitation_token: string } | { refused: "invalid-request" | "storage-failure" }> {
    if (isBlank(inviter_ref) || isBlank(context)) return { refused: "invalid-request" };                      // Operation 1, 2
    if ([inviter_ref, context, ...(isBlank(invitee_ref) ? [] : [invitee_ref as string])].some((v) => this.long(v))) return { refused: "invalid-request" }; // Operation 49
    let seconds: number;
    if (ttl === undefined || ttl === null) {                                                                  // Operation 4: a blank ttl reads the default
      if (this.cfg.defaultTtl === null) return { refused: "invalid-request" };                                // Operation 5
      seconds = this.cfg.defaultTtl;
    } else {
      if (typeof ttl !== "number" || !Number.isInteger(ttl)) return { refused: "invalid-request" };           // Operation 48: a ttl is a whole number of seconds
      if (ttl < this.cfg.ttlBounds.min || ttl > this.cfg.ttlBounds.max) return { refused: "invalid-request" }; // Operation 3
      seconds = ttl;
    }
    const now = this.seam.now();                                                                              // Operation 11
    const token = this.seam.tokenMaterial();                                                                  // Identity 2, 3: the token comes from the seam
    try {
      await this.store.commit([
        this.store.assertNone(this.T, "_id = $1", [token], "token-held"),                                     // Identity 5, 6: a token the database holds is a storage failure
        this.store.put(this.T, {
          _id: token, inviter_ref, invitee_ref: isBlank(invitee_ref) ? null : (invitee_ref as string), context, // Operation 9, 10
          initiated_at: now, expires_at: new Date(Date.parse(now) + seconds * 1000).toISOString(), status: "pending",   // Operation 12, 13
          accepting_identity_ref: null, accepted_at: null, declined_at: null, revoked_by_ref: null, revocation_reason: null, revoked_at: null,
        }),
      ]);
    } catch {
      return { refused: "storage-failure" };                                                                  // Operation 35
    }
    return { invitation_token: token };                                                                       // Operation 14
  }

  /** The status check every resolving write makes before it reads the call's inputs (Term status check). */
  private async standing(token: string): Promise<Stored | ResolveRefusal> {
    const i = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE _id = $1`, [token ?? ""]))[0];
    if (!i) return { refused: "not-known" };                                                                  // Operation 15
    if (i.status !== "pending") return { refused: "already-resolved", status: i.status };                     // Operation 16, 17: names the stored status
    if (Invitation.lapsed(i, this.seam.now())) return { refused: "expired" };                                 // Operation 20: expired is never a stored terminal (18)
    return i;
  }

  /** The statements of one resolving write, to commit alone or beside an action's other writes, or the refusal. */
  private async plan(token: string, inputs: () => { ok: false } | { ok: true; patch: Partial<Stored> }): Promise<{ stmts: Stmt[] } | ResolveRefusal> {
    const i = await this.standing(token);
    if ("refused" in i) return i;
    const r = inputs();
    if (!r.ok) return { refused: "invalid-request" };
    return {
      stmts: [
        this.store.assertSome(this.T, "_id = $1 AND status = 'pending'", [i._id], "resolved"),               // Invariant 2.1: one stored terminal at most
        this.store.put(this.T, { ...i, ...r.patch }),                                                         // Invariant 1.1: no property changes
      ],
    };
  }

  planAccept(token: string, accepting_identity_ref: string) {
    return this.plan(token, () => (isBlank(accepting_identity_ref) || this.long(accepting_identity_ref) ? { ok: false } : { ok: true, patch: { status: "accepted", accepting_identity_ref, accepted_at: this.seam.now() } })); // Operation 23, 28, 29, 50
  }
  planDecline(token: string) {
    return this.plan(token, () => ({ ok: true, patch: { status: "declined", declined_at: this.seam.now() } })); // Operation 27, 30, 31: no acting reference
  }
  planRevoke(token: string, revoked_by_ref: string, reason: string) {
    return this.plan(token, () => (isBlank(revoked_by_ref) || isBlank(reason) || this.long(revoked_by_ref) || this.long(reason) ? { ok: false } : { ok: true, patch: { status: "revoked", revoked_by_ref, revocation_reason: reason, revoked_at: this.seam.now() } })); // Operation 24, 25, 32, 33, 51
  }

  private async resolve(p: { stmts: Stmt[] } | ResolveRefusal, ok: string): Promise<string | ResolveRefusal> {
    if ("refused" in p) return p;
    try {
      await this.store.commit(p.stmts);
    } catch (e) {
      if (e instanceof Guard) return { refused: "already-resolved", status: "accepted" };                   // another call resolved it first; the next read names its status
      return { refused: "storage-failure" };                                                                  // Operation 35
    }
    return ok;
  }

  async accept(token: string, accepting_identity_ref: string) { return this.resolve(await this.planAccept(token, accepting_identity_ref), "accepted"); }
  async decline(token: string) { return this.resolve(await this.planDecline(token), "declined"); }
  async revoke(token: string, revoked_by_ref: string, reason: string) { return this.resolve(await this.planRevoke(token, revoked_by_ref, reason), "revoked"); }

  /** Every matching invitation with its effective status (Operation 41, 42). A status filter matches the stored status (Term filter). */
  async read(filter: Record<string, string | undefined> = {}): Promise<InvitationView[]> {
    const fields: Record<string, string> = { invitation_token: "_id", context: "context", status: "status", accepting_identity_ref: "accepting_identity_ref" };
    const named = Object.entries(filter).filter(([, v]) => v !== undefined);
    if (named.some(([k]) => !(k in fields))) return [];                                                       // a filter naming any other field matches no invitation
    if (named.some(([, v]) => isBlank(v))) return [];                                                         // Operation 47
    if (named.some(([k, v]) => k === "status" && !["pending", "accepted", "declined", "revoked"].includes(v as string))) return [];
    const where = named.map(([k], i) => `${fields[k]} = $${i + 1}`).join(" AND ");
    const rows = await this.store.read<Stored>(`SELECT * FROM ${this.T}${where ? " WHERE " + where : ""}`, named.map(([, v]) => v as string));
    const now = this.seam.now();
    rows.sort((a, b) => (a.initiated_at < b.initiated_at ? -1 : a.initiated_at > b.initiated_at ? 1 : a._id < b._id ? -1 : 1));
    return rows.map((i) => ({
      invitation_token: i._id, inviter_ref: i.inviter_ref, invitee_ref: i.invitee_ref, context: i.context, initiated_at: i.initiated_at, expires_at: i.expires_at,
      status: i.status, effective_status: Invitation.lapsed(i, now) ? "expired" : i.status,
      accepting_identity_ref: i.accepting_identity_ref, accepted_at: i.accepted_at, declined_at: i.declined_at,
      revoked_by_ref: i.revoked_by_ref, revocation_reason: i.revocation_reason, revoked_at: i.revoked_at,
    }));
  }
}

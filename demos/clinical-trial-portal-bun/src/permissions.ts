// Permissions — who holds which permission, now, and was it ever given?
// Rendered from atoms/permissions.md (the page at the commit the entry names), with no code of any other
// render opened. A rule's label is in the comment where the code answers it.
//
// A grant is one record under its grant id. A revoke is a new version of the record under the same id
// (Execution Contract Database 5), so the earlier version is there to read. A subject holds at most one
// active grant over one action scope (Identity 7, Invariant 11.1): [Grant] on a pair an active grant
// covers answers that grant's id and writes nothing (Operation 33, 34), and two calls on one pair at once
// leave one grant: the guard is an ASSERT in the write's own transaction (Database 2), and the call that
// loses it reads again and decides again (Grant concurrency 1). The atom carries no grantor (Non-goal 9).
import { Store, Guard, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";

export interface GrantView {
  grant_id: string;
  subject_ref: string;
  action_scope: string;
  granted_at: string;
  status: "active" | "revoked";
  revoked_at: string | null;
}

type Stored = Row & { _id: string; subject_ref: string; action_scope: string; granted_at: string; status: "active" | "revoked"; revoked_at: string | null };

const T = "grants";
const COLUMNS = ["subject_ref", "action_scope", "granted_at", "status", "revoked_at"];

export interface PermissionsConfig {
  /** The string cap in Unicode code points (Term string cap): 256 where a deployment declares none; fixed for the life of the instance (Capability requirement 6). */
  stringCap?: number;
  /** The table this instance keeps its grants in; one instance serves a deployment, so the default stands (a test world names its own). */
  table?: string;
}

export class Permissions {
  readonly stringCap: number;
  private readonly T: string;
  private constructor(private store: Store, private seam: Seam, cfg: PermissionsConfig) {
    this.stringCap = cfg.stringCap ?? 256;
    this.T = cfg.table ?? T;
  }

  static async open(store: Store, seam: Seam, cfg: PermissionsConfig = {}): Promise<Permissions> {
    await store.declare(cfg.table ?? T, COLUMNS);
    return new Permissions(store, seam, cfg);
  }

  private tooLong(v: string): boolean {
    return [...v].length > this.stringCap;
  }

  private async active(subject_ref: string, action_scope: string): Promise<Stored[]> {
    return this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE subject_ref = $1 AND action_scope = $2 AND status = 'active'`, [subject_ref, action_scope]);
  }

  /** The statements that record one grant where the pair is unheld, or the grant id already in force, to commit alone (`grant`) or beside an action's other writes. */
  async plan(subject_ref: string, action_scope: string): Promise<{ held: string } | { grant_id: string; stmts: Stmt[] } | { refused: "invalid-request" }> {
    if (isBlank(subject_ref) || isBlank(action_scope)) return { refused: "invalid-request" };                // Operation 4, 5
    if (this.tooLong(subject_ref) || this.tooLong(action_scope)) return { refused: "invalid-request" };       // String 6
    const inForce = await this.active(subject_ref, action_scope);
    if (inForce.length > 0) return { held: inForce[0]._id };                                                  // Operation 33, 34: the id of that grant, nothing written
    const id = this.seam.idMaterial();                                                                        // Identity 2: the host allocates the id
    return {
      grant_id: id,
      stmts: [
        this.store.assertNone(this.T, "subject_ref = $1 AND action_scope = $2 AND status = 'active'", [subject_ref, action_scope], "pair-held"), // Identity 7, Database 2
        this.store.assertNone(this.T, "_id = $1", [id], "id-held"),
        this.store.put(this.T, { _id: id, subject_ref, action_scope, granted_at: this.seam.now(), status: "active", revoked_at: null }), // Operation 1, 2; State 2
      ],
    };
  }

  async grant(subject_ref: string, action_scope: string): Promise<{ grant_id: string } | { refused: "invalid-request" | "storage-failure" }> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.plan(subject_ref, action_scope);
      if ("refused" in p) return p;
      if ("held" in p) return { grant_id: p.held };
      try {
        await this.store.commit(p.stmts);
        return { grant_id: p.grant_id };                                                                      // Operation 3
      } catch (e) {
        if (e instanceof Guard && e.guard === "pair-held") continue;                                          // Grant concurrency 1: another call won; read again, decide again
        return { refused: "storage-failure" };                                                                // Operation 7
      }
    }
    return { refused: "storage-failure" };
  }

  async revoke(grant_id: string): Promise<"ok" | { refused: "not-known" | "not-active" | "storage-failure" }> {
    const g = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE _id = $1`, [grant_id ?? ""]))[0];
    if (!g) return { refused: "not-known" };                                                                  // Operation 9
    if (g.status === "revoked") return { refused: "not-active" };                                             // Operation 10
    try {
      await this.store.commit([
        this.store.assertSome(this.T, "_id = $1 AND status = 'active'", [g._id], "revoked"),
        this.store.put(this.T, { ...g, status: "revoked", revoked_at: this.seam.now() }),                     // Operation 11; the grant instant and the pair stand (Invariant 1.1)
      ]);
    } catch (e) {
      if (e instanceof Guard) return { refused: "not-active" };                                               // revoked between the read and the write
      return { refused: "storage-failure" };                                                                  // Operation 13
    }
    return "ok";
  }

  /** The action [Check] is named by the signature `permitted` (open line 2026-10-26-b). Exactly one of permitted, denied; never writes (Operation 16 to 22). */
  async permitted(subject_ref: string, action_scope: string): Promise<"permitted" | "denied"> {
    if (isBlank(subject_ref) || isBlank(action_scope)) return "denied";                                       // a blank pair matches no grant
    return (await this.active(subject_ref, action_scope)).length > 0 ? "permitted" : "denied";                // exact match, byte for byte (Operation 21, 22)
  }

  /** Every grant, active and revoked, with every field (Operation 26, 27). */
  async read(): Promise<GrantView[]> {
    const rows = await this.store.read<Stored>(`SELECT * FROM ${this.T}`);
    return rows
      .sort((a, b) => (a.granted_at < b.granted_at ? -1 : a.granted_at > b.granted_at ? 1 : a._id < b._id ? -1 : 1))
      .map((g) => ({ grant_id: g._id, subject_ref: g.subject_ref, action_scope: g.action_scope, granted_at: g.granted_at, status: g.status, revoked_at: g.revoked_at }));
  }
}

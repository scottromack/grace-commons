// Attributed Permissions Admin — every grant and every revocation comes with an attestation of who authorized it.
// Rendered from compositions/attributed-permissions-admin.md (the page at the commit the entry names), with no code
// of any other render opened. A rule's label is in the comment where the code answers it.
//
// The composition stores three things (Composition state 1 to 3): the grant attribution map, the revocation attribution
// map (each a grant's handle to one attestation, written once and never changed or dropped) and the orphan log (an
// attestation that landed whose administrative write a constituent refused, keyed by that attestation, so the
// composition mints no identity of its own, Composition state 4).
// Each administrative act is one transaction (Database 1): Actor Identity's attestation, Permissions' write and the
// attribution entry are planned in that order and committed together, so an act that fails leaves a committed nothing.
// Where Permissions refuses a write after the attestation was planned, the attestation and its orphan log entry are
// committed instead (Action wiring 101, 102, Atomic writes 8): the attempt stands as evidence (Wiring decision 5).
// The three actions attest ONLY AFTER the boundary predicate (Primitive policy 1) and call no constituent write before
// the landed attestation (Atomic writes 2); an evaluation passes through unchanged (Composes 9, 10).
//
// Where the render does not meet the page: the failed-grant leg (Housekeeping, which the page says the composition MAY
// compose) is not rendered, and neither is the retention purge (Composition state 27, 28: the deployment's layer); the
// purge record is what the deployment supplies. [Revoke Permission]'s answer where a grant of its enumerated set is
// refused by Permissions (revoked by another call between the enumeration and the write) is the page's to say and it
// says none: the render commits the revocations that stood before it, logs the orphan, and answers storage-failure.
import { Store, Guard, Unavailable, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";
import { type Permissions, type GrantView } from "./permissions.ts";
import { type ActorIdentity, type AttestRefusal, type VerificationFailure } from "./actor_identity.ts";

export interface AdminConfig {
  /** Capability requirement 11, 13: the marker on every proposal, by which an auditor tells this composition's attestations from a foreign one's. */
  namespacePrefix: string;
  /** Capability requirement 9, 10, 15: the deployment's canonical serialization of a grant proposal; it carries the nonce and the prefix. Default: the prefix and the canonical form of the four fields. */
  grantProposalFormat?: (p: { subject_ref: string; action_scope: string; nonce: string; requested_at: string }) => string;
  /** Capability requirement 29, 36: the composition's length cap, in code points; the Permissions instance's where none is declared. */
  lengthCap?: number;
  /** Capability requirement 20: the declared bound on the difference between the two constituents' stamps. Blank, the composition does not start. */
  clockOffsetAllowanceMs: number | null;
  /** Capability requirement 35: the retention horizon. Blank, the composition does not start. */
  retentionHorizonMs: number | null;
  /** Capability requirement 28: the retention layer's purge record, answering whether a named attestation was lawfully destroyed. Absent, no attestation is. */
  purgeRecord?: (attestation_id: string) => Promise<boolean>;
  /** Primitive policy 16: an invalid-request from a constituent at the attestation step is a deployment fault, alerted. */
  alert?: (a: { arm: string; action: string }) => void;
}

export type Refusal =
  | { refused: "invalid-request" }
  | { refused: "invalid-credential" }
  | { refused: "attribution-storage-failure" }
  | { refused: "registry-unavailable" }
  | { refused: "mechanism-unavailable" }
  | { refused: "storage-failure" }
  | { refused: "state-unavailable" };

export type IssueResult = { grant_id: string; attestation_id?: string } | { orphan: "pre-grant"; attestation_id: string };
export type OrphanReason = "invalid-request" | "not-known" | "not-active" | "already-held";
export type VerifyResult = "verified" | { failed: VerificationFailure } | "not-known" | { "not-applicable": "purged" };
export type AttributionRecord = {
  grant_record: GrantView;
  issuance_attestation_id: string;
  issuance_verify_result: VerifyResult;
  revocation_attestation_id?: string;
  revocation_verify_result?: VerifyResult;
};

const GRANT_MAP = "grant_attribution";
const REVOKE_MAP = "revocation_attribution";
const ORPHAN_LOG = "orphan_log";
const TRIES = 50;

/** Trim an administered opaque input, once: the White_Space code points off both ends (Primitive policy 6, 7). */
const trim = (v: string): string => v.replace(/^[\p{White_Space}]+|[\p{White_Space}]+$/gu, "");

export class AttributedPermissionsAdmin {
  private readonly cap: number;
  private constructor(private store: Store, private seam: Seam, private perms: Permissions, private actors: ActorIdentity, private cfg: AdminConfig) {
    this.cap = cfg.lengthCap ?? perms.stringCap;
  }

  /** Capability requirement 20, 35: a blank declaration, and the composition does not start. Capability requirement 29, 30: the composition's cap does not exceed Permissions' own, checked at start. */
  static async open(store: Store, seam: Seam, parts: { permissions: Permissions; actors: ActorIdentity }, cfg: AdminConfig): Promise<AttributedPermissionsAdmin> {
    if (cfg.clockOffsetAllowanceMs === null || cfg.clockOffsetAllowanceMs === undefined) throw new Error("Attributed Permissions Admin does not start: the clock offset allowance is blank");   // Capability requirement 20
    if (cfg.retentionHorizonMs === null || cfg.retentionHorizonMs === undefined) throw new Error("Attributed Permissions Admin does not start: the retention horizon is blank");                // Capability requirement 35
    if (isBlank(cfg.namespacePrefix)) throw new Error("Attributed Permissions Admin does not start: the namespace prefix is blank");                                                            // Capability requirement 11, 13
    if (cfg.lengthCap !== undefined && cfg.lengthCap > parts.permissions.stringCap) throw new Error("Attributed Permissions Admin does not start: the length cap exceeds the Permissions instance's");   // Capability requirement 29, 30
    await store.declare(GRANT_MAP, ["attestation_id"]);
    await store.declare(REVOKE_MAP, ["attestation_id"]);
    await store.declare(ORPHAN_LOG, ["attestation_id", "proposal", "requested_at", "reason"]);
    return new AttributedPermissionsAdmin(store, seam, parts.permissions, parts.actors, cfg);
  }

  // ---- The boundary predicate (Primitive policy 1 to 8) --------------------------------------------------------------

  /** Blank, over the cap, a blank credential: refused before any constituent call; the opaque inputs come back trimmed, once (Primitive policy 2 to 8). */
  private boundary(opaque: string[], credential: string): string[] | null {
    if (opaque.some((v) => typeof v !== "string" || isBlank(v))) return null;                                        // Primitive policy 2
    if (typeof credential !== "string" || isBlank(credential)) return null;                                          // Primitive policy 4
    const t = opaque.map(trim);                                                                                      // Primitive policy 6, 7: a credential is not trimmed (Primitive policy 12)
    if (t.some((v) => [...v].length > this.cap)) return null;                                                        // Primitive policy 3
    return t;                                                                                                        // Primitive policy 8: the trimmed value goes on
  }

  private proposalOfGrant(subject_ref: string, action_scope: string, nonce: string, requested_at: string): string {
    const fields = { subject_ref, action_scope, nonce, requested_at };
    return this.cfg.grantProposalFormat ? this.cfg.grantProposalFormat(fields) : `${this.cfg.namespacePrefix}${canonical(fields)}`;   // Capability requirement 9 to 11
  }
  /** Term revocation proposal format: fixed, the grant's handle and the request instant behind the prefix (Capability requirement 12, 13, 14). */
  private proposalOfRevocation(grant_id: string, requested_at: string): string {
    return `${this.cfg.namespacePrefix}${canonical({ grant_id, requested_at })}`;
  }

  /** What Actor Identity's refusal of the attest answers (Action wiring 3 to 5, 18 to 20, 92 to 98, Primitive policy 14 to 16). */
  private attestRefused(action: string, r: AttestRefusal): Refusal {
    if (r === "invalid-request") { this.cfg.alert?.({ arm: "primitive-policy-16", action }); return { refused: "invalid-request" }; }   // Primitive policy 14, 16
    if (r === "storage-failure") return { refused: "attribution-storage-failure" };                                  // Action wiring 5, 20, 94: Execution Contract Constituent failure 1
    return { refused: r };                                                                                           // invalid-credential, registry-unavailable, mechanism-unavailable
  }

  private async held(subject_ref: string, action_scope: string): Promise<GrantView | undefined> {
    return (await this.perms.read()).find((g) => g.status === "active" && g.subject_ref === subject_ref && g.action_scope === action_scope);   // Action wiring 103: Permissions' declared read, filtered here
  }

  /** Is a grant's handle named by the grant attribution map already (Concurrency 10)? */
  private async attributed(grant_id: string): Promise<boolean> {
    return (await this.store.read(`SELECT _id FROM ${GRANT_MAP} WHERE _id = $1`, [grant_id])).length > 0;
  }

  // ---- The records the composition keeps ----------------------------------------------------------------------------

  /** An attribution entry: written once, under the grant's handle, naming one attestation, and no other entry names it (Composition state 5, 11 to 15, Invariant 7.1 to 7.3). */
  private entry(table: typeof GRANT_MAP | typeof REVOKE_MAP, grant_id: string, attestation_id: string): Stmt[] {
    return [
      this.store.assertNone(table, "_id = $1", [grant_id], "entry-held"),                                            // Composition state 13, Invariant 6.1: never changed
      this.store.assertNone(GRANT_MAP, "attestation_id = $1", [attestation_id], "attestation-named"),               // Invariant 7.1, 7.3: one attestation, one entry, across the two maps
      this.store.assertNone(REVOKE_MAP, "attestation_id = $1", [attestation_id], "attestation-named"),
      this.store.put(table, { _id: grant_id, attestation_id }),
    ];
  }

  /** An orphan log entry (Composition state 19): the attestation, the proposal, the request instant and the underlying reason, never changed or dropped (Composition state 16, 17). */
  private orphan(attestation_id: string, proposal: string, requested_at: string, reason: OrphanReason): Stmt[] {
    return [this.store.assertNone(ORPHAN_LOG, "_id = $1", [attestation_id], "orphan-held"), this.store.put(ORPHAN_LOG, { _id: attestation_id, attestation_id, proposal, requested_at, reason })];
  }

  // ---- [Issue Grant] (Action wiring 1 to 15, 96, 103 to 106) ---------------------------------------------------------

  async issueGrant(subject_ref: string, action_scope: string, grantor_ref: string, grantor_credential: string): Promise<IssueResult | Refusal> {
    const t = this.boundary([subject_ref, action_scope, grantor_ref], grantor_credential);
    if (!t) return { refused: "invalid-request" };                                                                   // Primitive policy 5
    const [subject, scope, grantor] = t;
    try {
      const inForce = await this.held(subject, scope);                                                               // Action wiring 103: read the pair first
      if (inForce) return { grant_id: inForce.grant_id };                                                            // Action wiring 104 to 106: the grant in force, no attestation, no write
      const requested_at = this.seam.now();                                                                          // Identity 8: the invocation's seam reading
      const nonce = this.seam.nonce();                                                                               // Identity 4, 5: one per issuance, from the seam
      const proposal = this.proposalOfGrant(subject, scope, nonce, requested_at);                                    // Action wiring 1
      const a = await this.actors.plan(proposal, grantor, grantor_credential);                                       // Action wiring 2: the attestation, before any Permissions call
      if ("refused" in a) return this.attestRefused("issue_grant", a.refused);                                       // Action wiring 3 to 6, 96: Permissions' grant is not called
      for (let tries = 0; tries < TRIES; tries++) {
        const g = await this.perms.plan(subject, scope);                                                             // Action wiring 7: only after the landed attestation
        if ("refused" in g) return await this.orphaned(a, proposal, requested_at, "invalid-request");                // Action wiring 8, 10, 101
        const handle = "held" in g ? g.held : g.grant_id;
        if ("held" in g && (await this.attributed(handle))) return await this.orphaned(a, proposal, requested_at, "already-held");   // Concurrency 10, 11
        const stmts = [...a.stmts, ...("held" in g ? [] : g.stmts), ...this.entry(GRANT_MAP, handle, a.attestation_id)];   // Composition state 25: the entry follows the write
        try {
          await this.store.commit(stmts);                                                                            // Database 1
        } catch (e) {
          if (e instanceof Guard && (e.guard === "pair-held" || e.guard === "entry-held")) continue;                // another issuance won the pair: read again, decide again (Concurrency 1, 2)
          return { refused: "storage-failure" };                                                                     // a committed nothing
        }
        return { grant_id: handle, attestation_id: a.attestation_id };                                               // Action wiring 15
      }
      return { refused: "storage-failure" };
    } catch (e) {
      if (e instanceof Unavailable) return { refused: "state-unavailable" };                                         // Execution Contract Constituent failure 3
      throw e;
    }
  }

  /** The attestation lands and the orphan log entry with it; the issuance answers orphan-attestation carrying pre-grant (Action wiring 101). */
  private async orphaned(a: { attestation_id: string; stmts: Stmt[] }, proposal: string, requested_at: string, reason: OrphanReason): Promise<IssueResult | Refusal> {
    try { await this.store.commit([...a.stmts, ...this.orphan(a.attestation_id, proposal, requested_at, reason)]); } catch { return { refused: "storage-failure" }; }
    return { orphan: "pre-grant", attestation_id: a.attestation_id };                                                // Action wiring 8
  }

  // ---- [Revoke Grant] (Action wiring 16 to 30, 41, 91, 97, 102) ------------------------------------------------------

  async revokeGrant(grant_id: string, revoker_ref: string, revoker_credential: string): Promise<{ ok: true; attestation_id: string } | { refused: "not-known" | "not-active" } | Refusal> {
    const t = this.boundary([grant_id, revoker_ref], revoker_credential);
    if (!t) return { refused: "invalid-request" };
    const [grant, revoker] = t;
    try {
      const r = await this.revokeOne(grant, revoker, revoker_credential, this.seam.now(), "revoke_grant");
      if ("refused" in r) return r;
      return { ok: true, attestation_id: r.attestation_id };                                                         // Action wiring 41
    } catch (e) {
      if (e instanceof Unavailable) return { refused: "state-unavailable" };
      throw e;
    }
  }

  /** One revocation: attest (the revocation proposal), Permissions' revoke, the entry; or the orphan where Permissions refuses (Action wiring 16 to 26). */
  private async revokeOne(grant_id: string, revoker: string, credential: string, requested_at: string, action: string, ahead: Stmt[] = []):
    Promise<{ attestation_id: string; stmts: Stmt[] } | { refused: "not-known" | "not-active" } | Refusal> {
    const proposal = this.proposalOfRevocation(grant_id, requested_at);                                              // Action wiring 16
    const a = await this.actors.plan(proposal, revoker, credential);                                                 // Action wiring 17
    if ("refused" in a) return this.attestRefused(action, a.refused);                                                // Action wiring 18 to 21, 92 to 98: Permissions' revoke is not called
    const p = await this.perms.planRevoke(grant_id);                                                                 // Action wiring 22: only after the landed attestation
    if ("refused" in p) {                                                                                            // Action wiring 23, 24, 26, 102: the attestation and the orphan log entry commit
      try { await this.store.commit([...ahead, ...a.stmts, ...this.orphan(a.attestation_id, proposal, requested_at, p.refused)]); } catch { return { refused: "storage-failure" }; }
      return p;                                                                                                      // Action wiring 27 to 30: a caller reads it as a caller fault and as an orphan
    }
    const stmts = [...a.stmts, ...p.stmts, ...this.entry(REVOKE_MAP, grant_id, a.attestation_id)];                  // Composition state 25
    if (ahead.length === 0 && action === "revoke_grant") {
      try { await this.store.commit(stmts); } catch (e) {
        if (e instanceof Guard && e.guard === "revoked") {                                                           // revoked between the read and the write: read again, now not-active
          try { await this.store.commit([...a.stmts, ...this.orphan(a.attestation_id, proposal, requested_at, "not-active")]); } catch { return { refused: "storage-failure" }; }
          return { refused: "not-active" };                                                                          // Atomic writes 5: the constituent write is not retried; its refusal answers
        }
        return { refused: "storage-failure" };                                                                       // a committed nothing
      }
    }
    return { attestation_id: a.attestation_id, stmts };
  }

  // ---- [Revoke Permission] (Action wiring 42 to 54, 92 to 98, Identity 9) ----------------------------------------------

  async revokePermission(subject_ref: string, action_scope: string, revoker_ref: string, revoker_credential: string): Promise<{ ok: true; revoked_grant_ids: string[]; attestation_ids: string[] } | { refused: "not-permitted" } | Refusal> {
    const t = this.boundary([subject_ref, action_scope, revoker_ref], revoker_credential);
    if (!t) return { refused: "invalid-request" };
    const [subject, scope, revoker] = t;
    try {
      const set = (await this.perms.read()).filter((g) => g.status === "active" && g.subject_ref === subject && g.action_scope === scope);   // Action wiring 42: the enumerated set, one read
      if (set.length === 0) return { refused: "not-permitted" };                                                     // Action wiring 43 to 45: no attestation, not not-known
      const requested_at = this.seam.now();                                                                          // Identity 9: one request instant for every attestation of the invocation
      const stmts: Stmt[] = [];
      const ids: string[] = [], attestations: string[] = [];
      for (const g of set) {                                                                                         // Action wiring 46: a revocation per enumerated grant
        const r = await this.revokeOne(g.grant_id, revoker, revoker_credential, requested_at, "revoke_permission", stmts);
        if ("refused" in r) {
          if (r.refused === "not-known" || r.refused === "not-active") return { refused: "storage-failure" };       // the page names no answer here (said in the file's head); the orphan and the earlier revocations are committed
          if (stmts.length) { try { await this.store.commit(stmts); } catch { return { refused: "storage-failure" }; } }   // Atomic writes 6: the first refusal answers; what stood before it is committed
          return r;
        }
        stmts.push(...r.stmts);
        ids.push(g.grant_id); attestations.push(r.attestation_id);
      }
      try { await this.store.commit(stmts); } catch {                                                               // Database 1: every revocation of the invocation, one transaction
        return { refused: "storage-failure" };                                                                       // a committed nothing
      }
      return { ok: true, revoked_grant_ids: ids, attestation_ids: attestations };                                   // Action wiring 48: the two lists in one order
    } catch (e) {
      if (e instanceof Unavailable) return { refused: "state-unavailable" };
      throw e;
    }
  }

  // ---- [Verify Grant Attribution] (Action wiring 55 to 80, Invariant 3) ---------------------------------------------------

  async verifyGrantAttribution(grant_id: string): Promise<AttributionRecord | "not-known" | "attribution-inconsistency"> {
    const grant = (await this.perms.read()).find((g) => g.grant_id === grant_id);                                    // Action wiring 55: Permissions' declared read
    if (!grant) return "not-known";                                                                                  // Action wiring 56
    const issued = (await this.store.read<{ attestation_id: string }>(`SELECT attestation_id FROM ${GRANT_MAP} WHERE _id = $1`, [grant_id]))[0];   // Action wiring 57
    if (!issued) return "attribution-inconsistency";                                                                 // Action wiring 58
    let revoked: { attestation_id: string } | undefined;
    if (grant.status === "revoked") {                                                                                // Action wiring 59: only a revoked grant's revocation entry is read
      revoked = (await this.store.read<{ attestation_id: string }>(`SELECT attestation_id FROM ${REVOKE_MAP} WHERE _id = $1`, [grant_id]))[0];
      if (!revoked) return "attribution-inconsistency";                                                              // Action wiring 60
    }
    const out: AttributionRecord = { grant_record: grant, issuance_attestation_id: issued.attestation_id, issuance_verify_result: await this.verifyOne(issued.attestation_id) };   // Action wiring 61, 79
    if (revoked) { out.revocation_attestation_id = revoked.attestation_id; out.revocation_verify_result = await this.verifyOne(revoked.attestation_id); }                        // Action wiring 80
    return out;                                                                                                      // Action wiring 78: nothing written
  }

  /** Actor Identity's verify per named attestation; an absent one reads the purge record, and only then (Action wiring 61 to 66). */
  private async verifyOne(attestation_id: string): Promise<VerifyResult> {
    const v = await this.actors.verify(attestation_id);
    if (v !== "not-known") return v;                                                                                 // verified, or failed with its reason: retryable ones are the caller's to read (Action wiring 75, 99)
    if (await this.cfg.purgeRecord?.(attestation_id)) return { "not-applicable": "purged" };                         // Action wiring 62, 63, 65: a lawful destruction is no tamper reading
    return "not-known";                                                                                              // Action wiring 64: the tamper reading
  }

  // ---- The evaluation passes through (Composes 9, 10, Action wiring 81 to 83) -----------------------------------------------

  /** Untrimmed, unrecorded, unattributed (Primitive policy 11, Action wiring 82, 83). */
  permitted(subject_ref: string, action_scope: string): Promise<"permitted" | "denied"> {
    return this.perms.permitted(subject_ref, action_scope);                                                          // Action wiring 81
  }
}

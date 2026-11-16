// Login — the full lifecycle of logging in: verify a credential, issue a time-limited session, log out,
// and cancel every session that came from a credential when the credential is revoked.
// Rendered from compositions/login.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// What lives here that no constituent holds (Composition state): the two maps, a credential to its
// sessions and its strict inverse, written together after the login commits and rebuilt from the
// substrate's login succeeded events when an entry is missing (a derived index); and the login event
// log, one immutable entry for every login call that answers a login result or invalid-credential.
// Every audit event this composition writes is attested under its own service identity (Composes 12).
// A login writes its log entry, its login event and (where the credential verified) the session in one
// transaction (Action wiring 45, 46); a logout writes the revoke and the logout event in one; a
// cascade's per-session revoke and its event in one.
//
// Not rendered here, said so: the sweep (Reconciliation 2 to 23) and the deployment's escalation
// surface (Capability requirement 20), which is the next part.
import { Store, Guard, Unavailable, type Stmt, type Row } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { Credential } from "./credential.ts";
import { Session } from "./session.ts";
import { AuditTrail } from "./audit_trail.ts";

export const CASCADE_REASON_PREFIX = "credential-revocation-cascade:";    // Term cascade reason prefix: compared as it stands, case-sensitive

export type Stage = "credential-id-lookup" | "session-issue" | "login-event-log" | "login-event-record";

export interface LoginConfig {
  /** The issued by references the deployment's calling layers pass into login (Capability requirement 10). */
  issuerReferences: string[];
  /** The default session duration in seconds (Capability requirement 6); null where the deployment sets none. */
  sessionDurationSeconds: number | null;
  /** Credential's length bound on a principal reference and a credential type, in code points (Primitive policy 10, 11). */
  lengthBound?: number;
  /** The service identity: this composition's own registered actor and credential (Capability requirement 8; Term service identity). */
  serviceIdentity: { actor_ref: string; credential: string };
  /** The retention period the substrate gives a login succeeded event, in milliseconds (Primitive policy 18). */
  loginEventRetentionMs: number;
}

export type LoginAnswer =
  | { session_token: string }
  | "invalid-credential"
  | { refused: "invalid-request" }
  | { refused: "storage-failure"; stage: Stage }
  | { refused: "state-unavailable" };
export type LogoutAnswer = "ok" | { refused: "invalid-request" | "not-known" | "already-terminal" | "storage-failure" | "state-unavailable" };
export type CascadeAnswer = { revoked: number; skipped: number; failed: number; not_found: number } | { refused: "invalid-request" | "storage-failure" | "state-unavailable" };

const ENTRIES = "login_event_log";
const S2C = "session_credential";
const C2S = "credential_sessions";
const ENTRY_COLUMNS = ["principal_ref", "credential_type", "issued_by_ref", "attempted_at", "outcome", "credential_id", "session_token"];

type LoggedEvent = { event_id: string; sequence_number: number; data: { action_ref: string; actor_ref: string; data: Record<string, unknown> } };

export class Login {
  private constructor(
    private store: Store, private seam: Seam, private credential: Credential, private session: Session,
    private audit: AuditTrail, private cfg: Required<Omit<LoginConfig, "lengthBound">> & { lengthBound: number },
  ) {}

  static async open(store: Store, seam: Seam, parts: { credential: Credential; session: Session; audit: AuditTrail }, cfg: LoginConfig): Promise<Login> {
    await store.declare(ENTRIES, ENTRY_COLUMNS);
    await store.declare(S2C, ["credential_id"]);
    await store.declare(C2S, ["credential_id", "session_token"]);
    return new Login(store, seam, parts.credential, parts.session, parts.audit, { ...cfg, lengthBound: cfg.lengthBound ?? 256 });
  }

  private long(v: string): boolean {
    return [...v].length > this.cfg.lengthBound;
  }

  /** Plan an audit event under the service identity, to commit beside the action's own writes (Composes 12, 14). */
  private eventPlan(action_ref: string, data: Record<string, unknown>) {
    return this.audit.plan(action_ref, this.cfg.serviceIdentity.actor_ref, this.cfg.serviceIdentity.credential, data);
  }

  /**
   * Commit an action's own statements and one audit event together, planning the event again where another
   * event landed first. The audit refusals all land as one: Audit arm 13.
   */
  private async commitWithEvent(own: Stmt[], action_ref: string, data: Record<string, unknown>): Promise<{ event_id: string } | { refused: "audit" | "guard"; guard?: string } | { refused: "store" }> {
    for (let attempt = 0; attempt < 50; attempt++) {
      const p = await this.eventPlan(action_ref, data);
      if ("refusal" in p) return { refused: "audit" };
      try {
        await this.store.commit([...own, ...p.stmts]);
      } catch (e) {
        if (e instanceof Guard && e.guard === "log-moved") continue;                                           // the log moved: plan the event again
        if (e instanceof Guard) return { refused: "guard", guard: e.guard };
        return { refused: "store" };
      }
      await this.audit.index(p.indexStmt);
      return { event_id: p.event_id };
    }
    return { refused: "store" };
  }

  private entry(id: string, c: { principal_ref: string; credential_type: string; issued_by_ref: string }, outcome: string, credential_id: string | null, session_token: string | null): Stmt {
    return this.store.put(ENTRIES, { _id: id, ...c, attempted_at: this.seam.now(), outcome, credential_id, session_token }); // Composition state 9, 10, 16: immutable, with its entry id
  }

  // ---------------------------------------------------------------- login

  /** A read a constituent or the database could not serve answers state-unavailable and writes nothing (Execution Contract Constituent failure 3, Read 1). */
  private async unserved<T>(fn: () => Promise<T>): Promise<T | { refused: "state-unavailable" }> {
    try { return await fn(); } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  login(principal_ref: string, credential_type: string, presented_material: string, issued_by_ref: string, session_duration?: number): Promise<LoginAnswer> {
    return this.unserved(() => this.doLogin(principal_ref, credential_type, presented_material, issued_by_ref, session_duration));
  }

  private async doLogin(principal_ref: string, credential_type: string, presented_material: string, issued_by_ref: string, session_duration?: number): Promise<LoginAnswer> {
    // The boundary predicate: nothing is written for an input that does not clear it.
    if (isBlank(principal_ref) || isBlank(credential_type) || isBlank(presented_material)) return { refused: "invalid-request" }; // Primitive policy 1 to 3
    if (this.long(principal_ref) || this.long(credential_type)) return { refused: "invalid-request" };            // Primitive policy 10, 11
    if (!this.cfg.issuerReferences.includes(issued_by_ref)) return { refused: "invalid-request" };                // Primitive policy 12
    const seconds = session_duration ?? this.cfg.sessionDurationSeconds;
    if (seconds === null || seconds === undefined) return { refused: "invalid-request" };                         // Primitive policy 5
    if (seconds * 1000 > this.cfg.loginEventRetentionMs) return { refused: "invalid-request" };                   // Primitive policy 18
    const call = { principal_ref, credential_type, issued_by_ref };
    const entry_id = this.seam.idMaterial();                                                                      // Capability requirement 16: one entry id for this call

    const verified = await this.credential.verify(principal_ref, credential_type, presented_material);           // Action wiring 1
    if (verified !== "verified") {
      // Action wiring 2, 3, 12, 13, 37, 45: invalid-credential, an answer; its entry and its login failed event commit together.
      const r = await this.commitWithEvent([this.entry(entry_id, call, `failed-verification(${verified.failed})`, null, null)], "login_failed", { ...call, entry_id, reason: verified.failed });
      if ("event_id" in r) return "invalid-credential";
      return { refused: "storage-failure", stage: r.refused === "audit" ? "login-event-record" : "login-event-log" }; // Action wiring 38; Audit arm 13
    }
    const cred = (await this.credential.read({ principal_ref, credential_type })).filter((c) => c.effective_status === "active").pop(); // Action wiring 5: the effective-active credential
    if (!cred) return { refused: "storage-failure", stage: "credential-id-lookup" };                             // Action wiring 30
    const issued = this.session.planIssue(principal_ref, issued_by_ref, seconds);                                 // Action wiring 4, 8: only after verified
    if ("refused" in issued) return issued.refused === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure", stage: "session-issue" }; // Action wiring 40, 31
    // Action wiring 45, 46: the entry, the session and the login succeeded event in one transaction.
    const r = await this.commitWithEvent(
      [this.entry(entry_id, call, "success", cred.credential_id, issued.session_token), ...issued.stmts],
      "login_succeeded", { ...call, entry_id, credential_id: cred.credential_id, session_token: issued.session_token },  // Action wiring 39; the pair the rebuild reads
    );
    if (!("event_id" in r)) return { refused: "storage-failure", stage: r.refused === "audit" ? "login-event-record" : "login-event-log" };
    await this.writeMaps(cred.credential_id, issued.session_token);                                               // Action wiring 9: after the login transaction
    return { session_token: issued.session_token };                                                               // Action wiring 10: the token, whether or not the maps were written
  }

  /** Both maps in one transaction (Composition state 3). A failure leaves the pair on the login succeeded event for the rebuild. */
  private async writeMaps(credential_id: string, session_token: string): Promise<void> {
    try {
      await this.store.commit([
        this.store.put(S2C, { _id: session_token, credential_id }),
        this.store.put(C2S, { _id: `${credential_id}|${session_token}`, credential_id, session_token }),
      ]);
    } catch { /* Action wiring 10, Reconciliation 20 */ }
  }

  /** Every login succeeded event of the substrate, read through the log by an open-ended range from sequence one and selected here (Composes 15 to 18). */
  private async loginSucceededEvents(): Promise<{ credential_id: string; session_token: string }[]> {
    const all = await this.audit.log.read({ sequence: { from: 1 } });
    if (!Array.isArray(all)) return [];
    return (all as unknown as LoggedEvent[])
      .filter((e) => e.data?.action_ref === "login_succeeded")
      .map((e) => ({ credential_id: String(e.data.data.credential_id), session_token: String(e.data.data.session_token) }));
  }

  /** Rebuild both maps from the login succeeded events, writing the pairs they lack (Composition state 7; Reconciliation 20). */
  async rebuildMaps(): Promise<number> {
    let wrote = 0;
    for (const p of await this.loginSucceededEvents()) {
      const have = await this.store.read<Row>(`SELECT _id FROM ${S2C} WHERE _id = $1`, [p.session_token]);
      const haveInverse = await this.store.read<Row>(`SELECT _id FROM ${C2S} WHERE _id = $1`, [`${p.credential_id}|${p.session_token}`]);
      if (have.length === 0 || haveInverse.length === 0) { await this.writeMaps(p.credential_id, p.session_token); wrote++; }
    }
    return wrote;
  }

  /** The credential id a session token rests on, from the map, rebuilt once on a miss (Composition state 2 and 7; Action wiring 14, 43). */
  private async credentialOf(session_token: string): Promise<string | null> {
    const find = async () => (await this.store.read<Row & { credential_id: string }>(`SELECT credential_id FROM ${S2C} WHERE _id = $1`, [session_token]))[0]?.credential_id ?? null;
    return (await find()) ?? ((await this.rebuildMaps(), await find()));
  }

  // ---------------------------------------------------------------- logout

  logout(session_token: string, revoked_by_ref: string, reason: string): Promise<LogoutAnswer> {
    return this.unserved(() => this.doLogout(session_token, revoked_by_ref, reason));
  }

  private async doLogout(session_token: string, revoked_by_ref: string, reason: string): Promise<LogoutAnswer> {
    if (isBlank(session_token)) return { refused: "invalid-request" };                                            // Primitive policy 4
    if (typeof reason === "string" && reason.startsWith(CASCADE_REASON_PREFIX)) return { refused: "invalid-request" }; // Primitive policy 13
    if (!(await this.credentialOf(session_token))) return { refused: "not-known" };                              // Action wiring 43: Session's revoke is not called
    const p = await this.session.planRevoke(session_token, revoked_by_ref, reason);                               // Action wiring 14
    if ("refused" in p) return { refused: p.refused === "invalid-request" ? "invalid-request" : p.refused };      // Action wiring 15, 27, 29
    const now = this.seam.now();
    const r = await this.commitWithEvent(p.stmts, "logout_succeeded", { session_token, revoked_by_ref, reason, requested_by: revoked_by_ref, now }); // Action wiring 16
    if ("event_id" in r) return "ok";
    if (r.refused === "guard") return { refused: "already-terminal" };                                            // the session was revoked between the read and the write
    return { refused: "storage-failure" };                                                                        // Audit arm 13
  }

  // ---------------------------------------------------------------- cascade

  revokeSessionsForCredential(credential_id: string, revoked_by_ref: string, reason: string): Promise<CascadeAnswer> {
    return this.unserved(() => this.doCascade(credential_id, revoked_by_ref, reason));
  }

  private async doCascade(credential_id: string, revoked_by_ref: string, reason: string): Promise<CascadeAnswer> {
    if (isBlank(credential_id) || isBlank(revoked_by_ref) || isBlank(reason)) return { refused: "invalid-request" }; // Primitive policy 15 to 17
    // Action wiring 17, 32: the initiation event first, and only then the cascade set is read.
    const init = await this.commitWithEvent([], "credential_revocation_cascade_initiated", { credential_id, revoked_by_ref, reason });
    if (!("event_id" in init)) return { refused: "storage-failure" };                                             // Action wiring 33
    const cascadeReason = `${CASCADE_REASON_PREFIX}${init.event_id}: ${reason}`;                                  // Term cascade reason
    // Action wiring 18, Invariant 2.3, 2.4: the union of the map's entry and the event-derived set.
    const set = new Set<string>();
    for (const r of await this.store.read<Row & { session_token: string }>(`SELECT session_token FROM ${C2S} WHERE credential_id = $1`, [credential_id])) set.add(r.session_token);
    for (const p of await this.loginSucceededEvents()) if (p.credential_id === credential_id) set.add(p.session_token);

    const tally = { revoked: 0, skipped: 0, failed: 0, not_found: 0 };
    const note = (action: string, data: Record<string, unknown>) => this.commitWithEvent([], action, data);
    for (const token of [...set].sort()) {
      const v = await this.session.validate(token);                                                               // Action wiring 19
      if ("invalid" in v) {
        if (v.invalid === "not-known") { tally.not_found++; await note("session_not_found_during_cascade", { credential_id, session_token: token }); } // Action wiring 35
        else tally.skipped++;                                                                                     // Action wiring 21, 22
        continue;
      }
      const p = await this.session.planRevoke(token, revoked_by_ref, cascadeReason);                              // Action wiring 20, 34
      if ("refused" in p) {
        if (p.refused === "storage-failure") return { refused: "storage-failure" };                               // Execution Contract Constituent failure 1: nothing more is written; the initiation stands for the sweep
        if (p.refused === "already-terminal") tally.skipped++;                                                    // Action wiring 41
        else if (p.refused === "not-known") { tally.not_found++; await note("session_not_found_during_cascade", { credential_id, session_token: token }); } // Action wiring 42
        else { tally.failed++; await note("session_revoke_failure_during_cascade", { credential_id, session_token: token, refused: p.refused }); }     // Action wiring 36
        continue;
      }
      const r = await this.commitWithEvent(p.stmts, "session_revoked_by_cascade", { credential_id, session_token: token, revoked_by_ref, reason: cascadeReason, now: this.seam.now() }); // Action wiring 23
      if ("event_id" in r) tally.revoked++;
      else if (r.refused === "guard") tally.skipped++;                                                            // revoked by another call between the validate and the write
      else tally.failed++;
    }
    const done = await note("credential_revocation_cascade_completed", { initiation_event_id: init.event_id, credential_id, ...tally }); // Action wiring 25
    if (!("event_id" in done)) return { refused: "storage-failure" };
    return tally;                                                                                                 // Action wiring 26; Action wiring 24: the credential to sessions map is not changed
  }
}

// Login, rendered from compositions/login.md. Every rule cited is that page's
// unless another page is named.
import type { Database } from "@db/sqlite";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";
import { credential, session } from "./atoms.ts";
import type { AuditTrail } from "./audit_trail.ts";

export interface Config {
  defaultSessionDurationMs?: number;  // Capability requirement 6
  issuerRefs: string[];               // 10
  reconciliationWindowMs: number;     // 11
  reconciliationCadenceMs: number;    // 12
  loginCompletionBoundMs: number;     // 14
  auditFailedLogins: boolean;         // 15
  auditHorizonMs: number;             // the substrate's retention horizon (Reconciliation 14)
  serviceActor: string;               // Composes 12; Capability requirement 8
  serviceCredential: string;
}
export type Stage = "credential-id-lookup" | "credential-id-confirm" | "session-issue";
export type LoginAnswer =
  | { ok: { session_token: string; expires_at: string } }
  | { refused: "invalid-request" | "invalid-credential" }
  | { refused: "storage-failure"; stage: Stage };
export interface Tally { revoked: number; skipped: number; failed: number; not_found: number }
export const CASCADE_PREFIX = "credential-revocation-cascade:";
export const ORPHAN_REASON = "unattributed-issuance-recovery";                           // Term orphan reason
const LOGIN_FAMILY = ["login_succeeded", "login_map_write_failure", "login_failed"];
const REVOCATION_FAMILY = ["logout_succeeded", "session_revoked_by_cascade", "orphan_session_revoked"];

export class Login {
  readonly alerts: { kind: string; detail: string }[] = [];
  readonly findings: { discrepancy: string; opened_at: string }[] = [];

  private constructor(private db: Database, private seam: Seam, private f: Faults, private audit: AuditTrail, readonly config: Config) {}

  // Capability requirement 13: the cadence never exceeds the window.
  static start(db: Database, seam: Seam, f: Faults, audit: AuditTrail, config: Config): Login {
    if (config.reconciliationCadenceMs > config.reconciliationWindowMs) throw new Error("reconciliation cadence exceeds the window");
    return new Login(db, seam, f, audit, config);
  }

  // ---- the audit write under the service identity, and its arms (Composes 12; Audit arm 1 through 10) ----
  private record(action_ref: string, data: Record<string, unknown>): string | null {
    for (let attempt = 0; attempt < 2; attempt++) {                                    // Audit arm 1, 2: one retry here; the sweep owns the rest
      const r = this.audit.record_action(action_ref, this.config.serviceActor, this.config.serviceCredential, data);
      if ("ok" in r) return r.ok;
      if (r.refused === "invalid-credential") { this.alert("service-credential", action_ref); return null; }  // 4, 5
      if (r.refused === "invalid-request") {                                           // 6 through 10
        this.alert("audit-invalid-request", action_ref);
        return this.findEvent((e) => e.action_ref === action_ref && JSON.stringify(e.data) === JSON.stringify(data))?.event_id ?? null;
      }
      if (r.refused === "recording-failure" && r.step === "step-4") return this.findEvent((e) => e.action_ref === action_ref && JSON.stringify(e.data) === JSON.stringify(data))?.event_id ?? null;
    }
    this.alert("owed-record", action_ref);
    return null;                                                                       // 3: owed, re-derived by the sweep
  }
  private alert(kind: string, detail: string) { this.alerts.push({ kind, detail }); }

  // Composes 15 through 17: the open-ended sequence range, filtered in this code.
  events() {
    return this.audit.log_read(1).filter((e) => e.envelope && e.envelope.actor_ref === this.config.serviceActor)
      .map((e) => ({ event_id: e.event_id, seq: e.seq, recorded_at: e.recorded_at, action_ref: e.envelope!.action_ref, data: e.envelope!.data }));
  }
  private findEvent(p: (e: ReturnType<Login["events"]>[number]) => boolean) { return this.events().find(p); }

  // ---- login (Action wiring 1 through 13, 30, 31) ----
  login(principal_ref: string, credential_type: string, presented_material: string, issued_by_ref: string, session_duration_ms?: number): LoginAnswer {
    const c = this.config;
    if ([principal_ref, credential_type, presented_material].some((s) => s.trim() === "")) return { refused: "invalid-request" };  // Primitive policy 1 through 3
    if (session_duration_ms === undefined && c.defaultSessionDurationMs === undefined) return { refused: "invalid-request" };       // 5
    const attempted_at = this.seam.now();                                              // Capability requirement 1: one reading per invocation
    const base = { principal_ref, credential_type, issued_by_ref, attempted_at };

    const v = credential.verify(this.db, this.seam, principal_ref, credential_type, presented_material);  // 1
    if (v !== "verified") {
      const reason = v["failed-verification"];
      const entry = this.entry({ ...base, outcome: "failed-verification", reason });
      if (c.auditFailedLogins) this.record("login_failed", { login_entry_id: entry, ...base, reason });
      return { refused: "invalid-credential" };                                        // 2, 3: the reason is never answered
    }
    const first = this.effectiveActiveId(principal_ref, credential_type);             // 5
    if (!first) return this.stageFailure(base, "credential-id-lookup", null);          // 30
    const issued = session.issue(this.db, this.seam, this.f, principal_ref, issued_by_ref, session_duration_ms, c.defaultSessionDurationMs);  // 4, 8
    if ("refused" in issued) {
      if (issued.refused === "storage-failure") return this.stageFailure(base, "session-issue", first);  // 31
      return { refused: "invalid-request" };
    }
    const token = issued.ok;
    const second = this.effectiveActiveId(principal_ref, credential_type);             // 6
    if (second !== first) return this.stageFailure(base, "credential-id-confirm", first);  // 7
    const expires_at = session.read(this.db).find((x) => x.session_token === token)!.expires_at;  // Term login result
    if (!this.writeMaps(first, token)) {                                               // 9 through 11
      const entry = this.entry({ ...base, outcome: "success-with-map-failure", credential_id: first, session_token: token });
      this.record("login_map_write_failure", { login_entry_id: entry, ...base, credential_id: first, session_token: token });
      return { ok: { session_token: token, expires_at } };
    }
    const entry = this.entry({ ...base, outcome: "success", credential_id: first, session_token: token });  // 12
    this.record("login_succeeded", { login_entry_id: entry, ...base, credential_id: first, session_token: token });  // 13
    return { ok: { session_token: token, expires_at } };
  }

  private effectiveActiveId(principal_ref: string, credential_type: string): string | undefined {
    return credential.read(this.db, this.seam, { principal_ref, credential_type }).find((x) => x.effective_status === "active")?.credential_id;
  }
  private stageFailure(base: Record<string, string>, stage: Stage, credential_id: string | null): LoginAnswer {
    const entry = this.entry({ ...base, outcome: "failed-storage-failure", stage, credential_id });
    if (this.config.auditFailedLogins) this.record("login_failed", { login_entry_id: entry, ...base, reason: `${stage}-failure`, credential_id });
    return { refused: "storage-failure", stage };
  }
  // Composition state 3: both maps under one transaction.
  private writeMaps(credential_id: string, token: string): boolean {
    this.db.exec("BEGIN");
    try {
      if (this.f.hit("maps.write", token)) throw new Error("map write refused");
      this.db.prepare("INSERT INTO credential_to_sessions VALUES (?, ?)").run(credential_id, token);
      this.db.prepare("INSERT INTO session_to_credential VALUES (?, ?)").run(token, credential_id);
      this.db.exec("COMMIT");
      return true;
    } catch { this.db.exec("ROLLBACK"); return false; }
  }
  // Composition state 9 through 11.
  private entry(e: Record<string, string | null | undefined>): number {
    this.db.prepare(`INSERT INTO login_event_log (attempted_at, principal_ref, credential_type, issued_by_ref, outcome, reason, stage, credential_id, session_token)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(e.attempted_at!, e.principal_ref!, e.credential_type!, e.issued_by_ref!, e.outcome!,
      e.reason ?? null, e.stage ?? null, e.credential_id ?? null, e.session_token ?? null);
    return (this.db.prepare("SELECT MAX(entry_id) AS id FROM login_event_log").get<{ id: number }>())!.id;
  }
  loginEventLog() { return this.db.prepare("SELECT * FROM login_event_log ORDER BY entry_id").all<Record<string, string | number | null>>(); }

  // ---- logout (Action wiring 14 through 16, 27 through 29) ----
  logout(session_token: string, revoked_by_ref: string, reason: string):
    { ok: "ok" } | { refused: "invalid-request" | "not-known" | "already-terminal" | "storage-failure" } {
    if (session_token.trim() === "") return { refused: "invalid-request" };            // Primitive policy 4
    const r = session.revoke(this.db, this.seam, this.f, session_token, revoked_by_ref, reason);
    if ("refused" in r) return { refused: r.refused };
    this.record("logout_succeeded", { session_token, requested_by: revoked_by_ref, reason });
    return { ok: "ok" };
  }

  // ---- revoke_sessions_for_credential (Action wiring 17 through 26, 32 through 36) ----
  revoke_sessions_for_credential(credential_id: string, revoked_by_ref: string, reason: string):
    { ok: Tally } | { refused: "invalid-request" | "storage-failure" } {
    if ([credential_id, revoked_by_ref, reason].some((s) => s.trim() === "")) return { refused: "invalid-request" };  // see CORNERS.md
    const init = this.record("credential_revocation_cascade_initiated", { credential_id, revoked_by_ref, reason });  // 17, 32
    if (!init) return { refused: "storage-failure" };                                  // 33
    const set = this.cascadeSet(credential_id);                                        // 18
    const t: Tally = { revoked: 0, skipped: 0, failed: 0, not_found: 0 };
    const join = { credential_id, revoked_by_ref, initiation_event_id: init };
    for (const token of set) {
      const v = session.validate(this.db, this.seam, token);                           // 19
      if ("valid" in v) {
        const r = session.revoke(this.db, this.seam, this.f, token, revoked_by_ref, `${CASCADE_PREFIX}${init}: ${reason}`);  // 20, 34
        if ("ok" in r) { t.revoked++; this.record("session_revoked_by_cascade", { session_token: token, ...join }); }  // 23
        else { t.failed++; this.record("session_revoke_failure_during_cascade", { session_token: token, ...join, error: r.refused }); }  // 36
      } else if (v.invalid === "not-known") {
        t.not_found++; this.record("session_not_found_during_cascade", { session_token: token, ...join });  // 35
      } else t.skipped++;                                                              // 21, 22
    }
    this.record("credential_revocation_cascade_completed", { initiation_event_id: init, credential_id, ...t });  // 25
    return { ok: t };                                                                  // 26
  }

  // Term cascade set: the map's entry and the pairs the login-family events carry, read once.
  cascadeSet(credential_id: string): string[] {
    const fromMap = this.db.prepare("SELECT session_token FROM credential_to_sessions WHERE credential_id = ?").all<{ session_token: string }>(credential_id).map((r) => r.session_token);
    const fromEvents = this.events().filter((e) => ["login_succeeded", "login_map_write_failure"].includes(e.action_ref) && e.data.credential_id === credential_id)
      .map((e) => String(e.data.session_token));
    return [...new Set([...fromMap, ...fromEvents])].sort();
  }

  // Composition state 7: both maps rebuilt from the login-family events.
  rebuildMaps(): { credential_id: string; session_token: string }[] {
    return this.events().filter((e) => ["login_succeeded", "login_map_write_failure"].includes(e.action_ref))
      .map((e) => ({ credential_id: String(e.data.credential_id), session_token: String(e.data.session_token) }))
      .sort((a, b) => a.session_token.localeCompare(b.session_token));
  }
  maps() {
    return {
      c2s: this.db.prepare("SELECT credential_id, session_token FROM credential_to_sessions ORDER BY session_token").all<{ credential_id: string; session_token: string }>(),
      s2c: this.db.prepare("SELECT credential_id, session_token FROM session_to_credential ORDER BY session_token").all<{ credential_id: string; session_token: string }>(),
    };
  }

  // ---- the sweep (Reconciliation 1 through 20) ----
  sweep(): void {
    const now = this.seam.now(), t = Date.parse(now), c = this.config;
    const old = (at: string) => Date.parse(at) + c.loginCompletionBoundMs < t;         // 6, 11: the lower edge
    const inHorizon = (at: string) => !(Date.parse(at) + c.auditHorizonMs < t);         // 14: the upper edge
    const open = (what: string, at: string, closed: boolean) => {                      // 13
      if (!closed && Date.parse(at) + c.reconciliationWindowMs < t) this.findings.push({ discrepancy: what, opened_at: at });
    };
    let evs = this.events();

    // 5: entries vs events — re-emit an owed record from the durable entry.
    for (const e of this.loginEventLog()) {
      const obliged = String(e.outcome).startsWith("success") || c.auditFailedLogins;
      if (!obliged || !inHorizon(String(e.attempted_at))) continue;
      if (evs.some((x) => LOGIN_FAMILY.includes(x.action_ref) && x.data.login_entry_id === e.entry_id)) continue;
      const action_ref = e.outcome === "success" ? "login_succeeded" : e.outcome === "success-with-map-failure" ? "login_map_write_failure" : "login_failed";
      const { entry_id, outcome: _o, stage, reason, ...rest } = e;
      const landed = this.record(action_ref, { login_entry_id: entry_id, ...rest, ...(action_ref === "login_failed" ? { reason: reason ?? `${stage}-failure` } : {}) });
      open(`entry:${entry_id}`, String(e.attempted_at), landed !== null);
    }
    evs = this.events();

    // 20: a map write failure's pair is written into both maps.
    for (const x of evs.filter((x) => x.action_ref === "login_map_write_failure")) {
      const token = String(x.data.session_token);
      if (!this.db.prepare("SELECT 1 FROM session_to_credential WHERE session_token = ?").get(token)) this.writeMaps(String(x.data.credential_id), token);
    }

    for (const s of session.read(this.db)) {
      if (!c.issuerRefs.includes(s.issued_by_ref) || !inHorizon(s.issued_at)) continue;  // 7, 14
      const named = evs.some((x) => LOGIN_FAMILY.includes(x.action_ref) && x.data.session_token === s.session_token) ||
        this.loginEventLog().some((e) => e.session_token === s.session_token);
      // 8, 9, 16, 18: an orphan session is revoked and recorded, after a recovery intent.
      if (s.status === "active" && !named && old(s.issued_at)) {
        if (!this.record("login_recovery_intended", { session_token: s.session_token })) { open(`orphan:${s.session_token}`, s.issued_at, false); continue; }
        const r = session.revoke(this.db, this.seam, this.f, s.session_token, c.serviceActor, ORPHAN_REASON);
        if ("ok" in r) this.record("orphan_session_revoked", { session_token: s.session_token, principal_ref: s.principal_ref });
        continue;
      }
      // 10, 15: a revoked session carrying no revocation-family event gets the member its stored reason names.
      const fresh = session.read(this.db).find((x) => x.session_token === s.session_token)!;
      if (fresh.status !== "revoked" || !old(fresh.revoked_at!)) continue;
      if (this.events().some((x) => REVOCATION_FAMILY.includes(x.action_ref) && x.data.session_token === s.session_token)) continue;
      const reason = fresh.revocation_reason ?? "";
      let landed: string | null;
      if (reason.startsWith(CASCADE_PREFIX)) {
        const initiation_event_id = reason.slice(CASCADE_PREFIX.length).split(": ")[0];
        const credential_id = this.db.prepare("SELECT credential_id FROM session_to_credential WHERE session_token = ?").get<{ credential_id: string }>(s.session_token)?.credential_id ?? null;
        landed = this.record("session_revoked_by_cascade", { session_token: s.session_token, credential_id, revoked_by_ref: fresh.revoked_by_ref, initiation_event_id });
      } else if (reason === ORPHAN_REASON) {
        landed = this.record("orphan_session_revoked", { session_token: s.session_token, principal_ref: s.principal_ref });
      } else {
        landed = this.record("logout_succeeded", { session_token: s.session_token, requested_by: fresh.revoked_by_ref, reason });
      }
      open(`revocation:${s.session_token}`, fresh.revoked_at!, landed !== null);
    }

    // 11, 12, 17, 19: an initiation with no completion is abandoned, then the cascade runs again.
    evs = this.events();
    for (const x of evs.filter((x) => x.action_ref === "credential_revocation_cascade_initiated")) {
      if (!old(x.recorded_at) || !inHorizon(x.recorded_at)) continue;
      const closed = evs.some((y) => ["credential_revocation_cascade_completed", "credential_revocation_cascade_abandoned"].includes(y.action_ref) &&
        y.data.initiation_event_id === x.event_id);
      if (closed) continue;
      const abandoned = this.record("credential_revocation_cascade_abandoned", { initiation_event_id: x.event_id, credential_id: x.data.credential_id, reason: "process-failure" });
      if (!abandoned) { open(`initiation:${x.event_id}`, x.recorded_at, false); continue; }
      if (!this.record("login_recovery_intended", { initiation_event_id: x.event_id })) continue;
      this.revoke_sessions_for_credential(String(x.data.credential_id), String(x.data.revoked_by_ref), String(x.data.reason));
    }
  }
}

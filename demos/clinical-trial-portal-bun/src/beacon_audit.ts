// Beacon's audit screens' own part: what a person may read of the trail, the filters, the retention switch, and the two events they write.
// Rendered from SPEC.md in this directory (The screens, Audit Trail; What each action writes to the audit trail; The permissions) and from the patterns it names:
// the events are Audit Trail's records read through Event Log, and a new event is planned through Audit Trail beside the change it records (Database 1).
// Retention filters what the page shows and never deletes an event (SPEC.md): the setting is one record, and the page reads the log whole and cuts it.
import { Store, Guard, Unavailable, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { type EventLog, type LoggedEvent } from "./event_log.ts";
import { type People } from "./beacon_people.ts";
import { type BeaconDomain, type PermissionCode, type Refusal } from "./beacon_domain.ts";
import { type Trail } from "./external_onboarding.ts";
import { type AuditTrail, type AuditRecord } from "./audit_trail.ts";
import { canonical } from "./canonical.ts";

const DAY = 86_400_000;
/** Seven years, in days (SPEC.md, What each action writes). */
export const RETENTION_DAYS = 2555;
export const AUDIT_WORDS = { date: "A date is written year, month, day, for example 2026-09-01.", range: "The from date is after the to date." } as const;

export interface AuditRow { number: number; recorded_at: string; action: string; target: string; actor: string; actor_ref: string; payload: string; event_id: string }
export type VerifyView =
  | { intact: true; checked: number; unsealed: number }
  | { intact: false; checked: number; event: { number: number; event_id: string; action: string }; reason: string };
export interface AuditFilter { action?: string; from?: string; to?: string }
export interface AuditView { rows: AuditRow[]; scope: "all" | "own"; retention_on: boolean; actions: string[]; filters: AuditFilter }

const SETTINGS = "settings";
const RETENTION_KEY = "retention";
const TRIES = 50;
type Setting = Row & { _id: string; enabled: string };

/** What a page shows in place of a session token: the token is the bearer of a sign-in, and Login writes it into its login event (Login, derived index), so no screen or file shows it (SPEC.md, What each action writes). */
export const WITHHELD = "[withheld]";
export const withhold = (v: unknown): unknown =>
  Array.isArray(v) ? v.map(withhold) : v && typeof v === "object" ? Object.fromEntries(Object.entries(v as Record<string, unknown>).map(([k, x]) => [k, k === "session_token" ? WITHHELD : withhold(x)])) : v;

/** One CSV cell: quoted where it holds a comma, a quote or a line break, and made inert where a spreadsheet would run it as a formula. */
export const csvCell = (v: string): string => {
  const t = /^[=+\-@\t\r]/.test(v) ? `'${v}` : v;
  return /[",\r\n]/.test(t) ? `"${t.replaceAll('"', '""')}"` : t;
};

/** A calendar day as an instant: its first millisecond, or its last. */
const dayStart = (d: string) => `${d}T00:00:00.000Z`, dayEnd = (d: string) => `${d}T23:59:59.999Z`;
const isDay = (d: unknown): d is string => typeof d === "string" && /^\d{4}-\d\d-\d\d$/.test(d) && !Number.isNaN(Date.parse(`${d}T00:00:00.000Z`)) && new Date(`${d}T00:00:00.000Z`).toISOString().startsWith(d);

export class BeaconAudit {
  private constructor(private store: Store, private seam: Seam, private log: EventLog, private trail: Trail, private people: People, private domain: BeaconDomain, private audit: AuditTrail, private T: string, private serviceName: (ref: string) => string | null) {}

  static async open(store: Store, seam: Seam, parts: { log: EventLog; trail: Trail; people: People; domain: BeaconDomain; audit: AuditTrail }, cfg: { prefix?: string; serviceName?: (ref: string) => string | null } = {}): Promise<BeaconAudit> {
    const T = `${cfg.prefix ?? ""}${SETTINGS}`;
    await store.declare(T, ["enabled"]);
    return new BeaconAudit(store, seam, parts.log, parts.trail, parts.people, parts.domain, parts.audit, T, cfg.serviceName ?? (() => null));
  }

  /** The retention switch: off where none was ever written, so the whole chain is visible (SPEC.md, What each action writes). */
  async retentionOn(): Promise<boolean> {
    const s = (await this.store.read<Setting>(`SELECT * FROM ${this.T} WHERE _id = $1`, [RETENTION_KEY]))[0];
    return s?.enabled === "true";
  }

  /** Who may read the trail, and how much: everyone's with `view_audit`, one's own with `view_own_audit` alone (SPEC.md, The permissions). */
  async scopeOf(actor_ref: string): Promise<"all" | "own" | null> {
    const held = await this.domain.held(actor_ref);
    return held.includes("view_audit") ? "all" : held.includes("view_own_audit") ? "own" : null;
  }

  private async nameOf(): Promise<(ref: string) => string> {
    const names = new Map((await this.people.list()).map((p) => [p.actor_ref, p.display_name]));
    return (ref) => names.get(ref) ?? this.serviceName(ref) ?? ref;
  }

  /** The events a person may see: their scope's, and where the retention window is on, the ones inside it. */
  private async visible(actor_ref: string, scope: "all" | "own") {
    const on = await this.retentionOn();
    const floor = on ? new Date(Date.parse(this.seam.now()) - RETENTION_DAYS * DAY).toISOString() : null;
    const name = await this.nameOf();
    const events = (await this.log.read({ sequence: { from: 1 } })) as LoggedEvent[];
    const mine = events.filter((e) => (scope === "all" || (e.data as { actor_ref: string }).actor_ref === actor_ref) && (floor === null || e.recorded_at >= floor));
    return { on, name, mine };
  }

  /**
   * Chain verification (SPEC.md, Chain verification): the events not yet sealed are sealed first (Audit Trail's [Seal Now], until it has nothing to seal), then each
   * event the person may see is verified through [Verify Record] against the payloads the log holds now for the slice that covers it; a changed event shows as the
   * seal's proof not holding. The first failure is the answer; an event sealed after the pass began is not a failure and is counted apart.
   */
  async verifyChain(actor_ref: string, credential: string): Promise<VerifyView | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };
    try {
      const scope = await this.scopeOf(actor_ref);
      if (!scope) return { refused: "access-denied", needs: ["view_audit", "view_own_audit"] };                // verifying: who may
      for (let i = 0; i < 10_000; i++) {
        const r = await this.audit.sealNow();
        if ("refused" in r) { if (r.refused === "nothing-to-seal") break; return { refused: "storage-failure" }; }
      }
      const { mine } = await this.visible(actor_ref, scope);
      const slices = new Map<string, unknown[]>();
      let checked = 0, unsealed = 0;
      for (const e of mine) {
        const d = e.data as { action_ref: string };
        const rec = await this.audit.readRecord(e.event_id);
        if (rec === "not-known") return { intact: false, checked, event: { number: e.sequence_number, event_id: e.event_id, action: d.action_ref }, reason: "the audit trail does not know this event" };
        if (rec.coverage.status !== "covered") { unsealed++; continue; }
        const key = rec.coverage.evidence_id;
        if (!slices.has(key)) slices.set(key, ((await this.log.read({ sequence: { from: rec.coverage.first, to: rec.coverage.last } })) as LoggedEvent[]).map((x) => canonical(x.data)));
        const v = await this.audit.verifyRecord(e.event_id, slices.get(key));
        const outcome = v === "not-known" ? { failed: "not-known" } : v.outcome;
        if (outcome === "verified") { checked++; continue; }
        if (typeof outcome === "object" && "failed" in outcome && outcome.failed === "unsealed") { unsealed++; continue; }
        const reason = typeof outcome === "object" ? ("failed" in outcome ? outcome.failed : `could not be checked: ${outcome.unverifiable}`) : String(outcome);
        return { intact: false, checked, event: { number: e.sequence_number, event_id: e.event_id, action: d.action_ref }, reason };
      }
      return { intact: true, checked, unsealed };
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  /**
   * The export (SPEC.md, Audit export): every event the person may see, oldest first, as a CSV file named for the day; exporting is itself an event. A cell that would
   * open as a formula in a spreadsheet is written with a leading apostrophe, and the session token is withheld as on the page.
   */
  async exportCsv(actor_ref: string, credential: string): Promise<{ filename: string; csv: string } | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };
    try {
      const scope = await this.scopeOf(actor_ref);
      if (!scope) return { refused: "access-denied", needs: ["view_audit", "view_own_audit"] };                // exporting: who may
      const { name, mine } = await this.visible(actor_ref, scope);
      const lines: string[][] = [["number", "time", "action", "target", "actor", "actor reference", "payload", "event id", "attestation id", "sealed by"]];
      for (const e of mine) {
        const d = e.data as { action_ref: string; actor_ref: string; attestation_id?: string; data?: Record<string, unknown> };
        const { target, ...rest } = d.data && typeof d.data === "object" ? d.data : ({} as Record<string, unknown>);
        const rec = await this.audit.readRecord(e.event_id) as AuditRecord | "not-known";
        const sealed = rec !== "not-known" && rec.coverage.status === "covered" ? rec.coverage.evidence_id : "unsealed";
        lines.push([String(e.sequence_number), e.recorded_at, d.action_ref, typeof target === "string" ? target : "", name(d.actor_ref), d.actor_ref, Object.keys(rest).length ? JSON.stringify(withhold(rest)) : "", e.event_id, d.attestation_id ?? "", sealed]);
      }
      const wrote = await this.write("beacon.audit_exported", actor_ref, credential, { target: "audit", row_count: mine.length, scope }, []);
      if (wrote !== "ok") return wrote;
      return { filename: `beacon-audit-${this.seam.now().slice(0, 10)}.csv`, csv: lines.map((l) => l.map(csvCell).join(",")).join("\r\n") + "\r\n" };
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  /** What the person may see, newest first, cut by the filters and by the retention window where it is on; opening the page is itself an event (SPEC.md, Audit Trail). */
  async view(actor_ref: string, credential: string, filters: AuditFilter = {}): Promise<AuditView | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };
    try {
      const scope = await this.scopeOf(actor_ref);
      if (!scope) return { refused: "access-denied", needs: ["view_audit", "view_own_audit"] };
      const f: AuditFilter = { action: isBlank(filters.action) ? undefined : filters.action, from: isBlank(filters.from) ? undefined : filters.from!.trim(), to: isBlank(filters.to) ? undefined : filters.to!.trim() };
      if ((f.from && !isDay(f.from)) || (f.to && !isDay(f.to))) return { refused: "invalid-request", message: AUDIT_WORDS.date };
      if (f.from && f.to && f.from > f.to) return { refused: "invalid-request", message: AUDIT_WORDS.range };
      const { on, name, mine } = await this.visible(actor_ref, scope);
      const actions = [...new Set(mine.map((e) => (e.data as { action_ref: string }).action_ref))].sort();
      const rows = mine.filter((e) => {
        const d = e.data as { action_ref: string };
        return (!f.action || d.action_ref === f.action) && (!f.from || e.recorded_at >= dayStart(f.from)) && (!f.to || e.recorded_at <= dayEnd(f.to));
      }).map((e): AuditRow => {
        const d = e.data as { action_ref: string; actor_ref: string; data?: Record<string, unknown> };
        const { target, ...rest } = d.data && typeof d.data === "object" ? d.data : ({} as Record<string, unknown>);
        return { number: e.sequence_number, recorded_at: e.recorded_at, action: d.action_ref, target: typeof target === "string" ? target : "", actor: name(d.actor_ref), actor_ref: d.actor_ref, payload: Object.keys(rest).length ? JSON.stringify(withhold(rest)) : "", event_id: e.event_id };
      }).sort((a, b) => b.number - a.number);
      const wrote = await this.write("beacon.audit_viewed", actor_ref, credential, { target: "audit", filters: { action: f.action ?? null, from: f.from ?? null, to: f.to ?? null }, scope, result_count: rows.length }, []);
      if (wrote !== "ok") return wrote;
      return { rows, scope, retention_on: on, actions, filters: f };
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  /** Turn the retention switch on or off: a person who holds `view_audit`; the change and its event are one transaction. Nothing is deleted either way. */
  async setRetention(actor_ref: string, credential: string, on: boolean): Promise<{ on: boolean } | Refusal> {
    if (isBlank(actor_ref) || isBlank(credential) || typeof on !== "boolean") return { refused: "invalid-request" };
    try {
      if (!(await this.domain.held(actor_ref)).includes("view_audit")) return { refused: "access-denied", needs: ["view_audit"] };
      const wrote = await this.write("beacon.retention_switched", actor_ref, credential, { target: "audit", retention: on ? "on" : "off", days: RETENTION_DAYS }, [this.store.put(this.T, { _id: RETENTION_KEY, enabled: String(on) })]);
      return wrote === "ok" ? { on } : wrote;
    } catch (e) { if (e instanceof Unavailable) return { refused: "state-unavailable" }; throw e; }
  }

  /** Plan the event, commit it beside the change (Database 1), index it after. */
  async write(action_ref: string, actor_ref: string, credential: string, data: unknown, change: Stmt[]): Promise<"ok" | Refusal> {
    for (let tries = 0; tries < TRIES; tries++) {
      const p = await this.trail.plan(action_ref, actor_ref, credential, data, 0);
      if ("refusal" in p) return p.refusal.refused === "invalid-credential" ? { refused: "invalid-credential" } : { refused: "storage-failure" };
      try { await this.store.commit([...change, ...p.stmts]); }
      catch (e) {
        if (e instanceof Guard && e.guard === "log-moved") continue;
        return { refused: "storage-failure" };
      }
      await this.trail.index(p.indexStmt);
      return "ok";
    }
    return { refused: "storage-failure" };
  }
}

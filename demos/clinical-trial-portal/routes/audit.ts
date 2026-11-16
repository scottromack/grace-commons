// routes/audit.ts — Audit trail: view, verify, export
//
// Requires view_audit (everyone's events) or view_own_audit (only this actor's events).
// A person who holds view_audit sees every event; a person who holds only view_own_audit
// sees the events this actor made.
// View components called as plain functions (no JSX syntax in .ts file).

import { Hono } from "hono";
import type { AppEnv } from "../lib/env.ts";
import { requireSession } from "../middleware/require_session.ts";
import { requirePermission } from "../middleware/require_permission.ts";
import * as eventLog from "../domain/event_log.ts";
import * as grants from "../domain/grants.ts";
import * as retentionPolicy from "../domain/retention_policy.ts";
import { appendEvent } from "../domain/event_log.ts";
import { withTx } from "../lib/db.ts";
import { AuditListPage } from "../views/audit_list.tsx";
import { AuditVerifyPage } from "../views/audit_verify.tsx";
import type { AuditFilters } from "../views/audit_list.tsx";

export const auditRouter = new Hono<AppEnv>();

const canViewAudit = requirePermission("view_audit", "view_own_audit");

/** The recorded form of what a person may see: "all" (everyone's events) or "own". */
const reachOf = (db: Parameters<typeof grants.holds>[0], actor_id: number): "all" | "own" =>
  grants.holds(db, actor_id, "view_audit") ? "all" : "own";

auditRouter.get("/audit", requireSession, canViewAudit, (c) => {
  const ctx = c.get("ctx");
  const db = ctx.db;
  const actor = ctx.actor!;
  const scope = reachOf(db, actor.id);

  const filters: AuditFilters = {
    action: c.req.query("action") || undefined,
    from_date: c.req.query("from_date") || undefined,
    to_date: c.req.query("to_date") || undefined,
  };

  const policy = retentionPolicy.getPolicy(db);

  const domainFilters: eventLog.EventFilters = {
    action: filters.action ?? null,
    from_date: filters.from_date ?? null,
    to_date: filters.to_date ? filters.to_date + "T23:59:59Z" : null,
    actor_id: scope === "own" ? actor.id : null,
  };

  let events = eventLog.listFiltered(db, domainFilters);

  if (policy?.enforce_on_read) {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - policy.days);
    const cutoffISO = cutoff.toISOString();
    events = events.filter((e) => e.occurred_at >= cutoffISO);
  }

  // Emit audit.viewed — under Part 11, viewing the regulated record is itself
  // a regulated act. This event is recorded after the query so the row count
  // is known; it will not appear in the current page render (already fetched).
  withTx(ctx, (tx) => {
    appendEvent(tx, {
      action: "audit.viewed",
      target_kind: "audit",
      payload: {
        filters: {
          action: filters.action ?? null,
          from_date: filters.from_date ?? null,
          to_date: filters.to_date ?? null,
          scope,
        },
        result_count: events.length,
      },
    });
  });

  return c.html(AuditListPage({ actor, events, filters, policy, scope }) as string);
});

auditRouter.get("/audit/verify", requireSession, canViewAudit, (c) => {
  const ctx = c.get("ctx");
  const db = ctx.db;
  const actor = ctx.actor!;
  const result = eventLog.verifyChain(db);
  return c.html(AuditVerifyPage({ actor, result }) as string);
});

auditRouter.get("/audit/export.csv", requireSession, canViewAudit, (c) => {
  const ctx = c.get("ctx");
  const db = ctx.db;
  const actor = ctx.actor!;
  const scope = reachOf(db, actor.id);

  const domainFilters: eventLog.EventFilters = {
    actor_id: scope === "own" ? actor.id : null,
  };
  const events = eventLog.listFiltered(db, domainFilters).reverse(); // oldest first

  // RFC 4180: wrap every field in double-quotes, escape inner quotes as "".
  const csvField = (v: string | number | null | undefined): string => {
    const s = v == null ? "" : String(v);
    return '"' + s.replace(/"/g, '""') + '"';
  };

  const header =
    "id,occurred_at,actor_id,session_id,action,target_kind,target_id,payload_json,prev_hash,this_hash\n";

  const rows = events.map((e) =>
    [
      csvField(e.id),
      csvField(e.occurred_at),
      csvField(e.actor_id),
      csvField(e.session_id),
      csvField(e.action),
      csvField(e.target_kind),
      csvField(e.target_id),
      csvField(e.payload_json),   // already a JSON string — do NOT re-serialize
      csvField(e.prev_hash),
      csvField(e.this_hash),
    ].join(",")
  ).join("\n");

  // Emit audit.exported — exporting the audit log is itself a regulated act.
  withTx(ctx, (tx) => {
    appendEvent(tx, {
      action: "audit.exported",
      target_kind: "audit",
      payload: {
        row_count: events.length,
        scope,
      },
    });
  });

  const ts = new Date().toISOString().slice(0, 10);
  return new Response(header + rows, {
    status: 200,
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="beacon-audit-${ts}.csv"`,
    },
  });
});

auditRouter.post("/audit/toggle-retention", requireSession, canViewAudit, (c) => {
  const ctx = c.get("ctx");
  retentionPolicy.toggleEnforcement(ctx.db);
  return c.redirect("/audit");
});

// routes/people.ts — PI surface: actors, invitations, grants
//
// All routes require session + invite_actor or grant_permission.
// View component called as plain function (no JSX syntax in .ts file).

import { Hono } from "hono";
import type { AppEnv } from "../lib/env.ts";
import { requireSession } from "../middleware/require_session.ts";
import { requirePermission } from "../middleware/require_permission.ts";
import * as actors from "../domain/actors.ts";
import * as grants from "../domain/grants.ts";
import * as invitations from "../domain/invitations.ts";
import * as permissions from "../domain/permissions.ts";
import * as parties from "../domain/parties.ts";
import * as composition from "../composition.ts";
import { sendInvitationEmail } from "../lib/mailer.ts";
import { PeoplePage } from "../views/people.tsx";
import type { ActorRow, HeldPermission, InvitationRow } from "../views/people.tsx";

const canManagePeople = requirePermission("invite_actor", "grant_permission");

export const peopleRouter = new Hono<AppEnv>();

peopleRouter.get("/people", requireSession, canManagePeople, (c) => {
  const ctx = c.get("ctx");
  const db = ctx.db;
  const actor = ctx.actor!;

  const allPermissions = permissions.listAll(db);
  const actorList = actors.listAll(db);
  const actorRows: ActorRow[] = actorList.map((a) => {
    const party = parties.getById(db, a.party_id);
    // Each permission the person holds now, once, with the number of active
    // grants behind it (more than one only where grants were recorded before a
    // person held a permission once).
    const active = grants.listForActor(db, a.id).filter((g) => g.revoked_at === null);
    const held: HeldPermission[] = [];
    for (const g of active) {
      const seen = held.find((h) => h.permission_id === g.permission_id);
      if (seen) seen.grants += 1;
      else held.push({ permission_id: g.permission_id, label: g.permission_label, grants: 1 });
    }
    return {
      id: a.id,
      display_name: a.display_name,
      email: party?.email ?? "—",
      held,
      available: allPermissions.filter((p) => !held.some((h) => h.permission_id === p.id)),
    };
  });

  const pending = invitations.listPending(db);
  const pendingRows: InvitationRow[] = pending.map((inv) => {
    const party = parties.getById(db, inv.party_id);
    return { ...inv, email: party?.email ?? "—" };
  });

  const history = grants.listHistory(db);
  const flash = c.req.query("flash") ?? null;
  const inviteLink = c.req.query("inviteLink") ?? null;

  return c.html(
    PeoplePage({ actor, actorRows, pendingInvitations: pendingRows, history, flash, inviteLink }) as string,
  );
});

peopleRouter.post(
  "/invitations",
  requireSession,
  requirePermission("invite_actor"),
  async (c) => {
    const ctx = c.get("ctx");
    const form = await c.req.formData();
    const email = (form.get("email") as string | null)?.trim() ?? "";
    const display_name = (form.get("display_name") as string | null)?.trim() ?? "";
    const intended_role = (form.get("intended_role") as string | null)?.trim() ?? "";

    if (!email || !display_name || !intended_role) {
      return c.redirect("/people?flash=Missing+required+fields.");
    }

    let invitation;
    try {
      invitation = composition.issueInvitation(ctx, { email, display_name, intended_role });
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      return c.redirect(`/people?flash=${encodeURIComponent(msg)}`);
    }

    const baseUrl = c.get("baseUrl");
    const acceptUrl = `${baseUrl}/invitations/accept/${invitation.token}`;
    const result = await sendInvitationEmail({ to: email, displayName: display_name, acceptUrl });

    if (result.status === "sent") {
      return c.redirect(`/people?flash=${encodeURIComponent(`Invitation emailed to ${email}.`)}`);
    } else if (result.status === "skipped") {
      return c.redirect(
        `/people?flash=${encodeURIComponent("Invitation created. SMTP not configured — share the link below.")}&inviteLink=${encodeURIComponent(acceptUrl)}`,
      );
    } else {
      console.error("[people] Email delivery failed:", result.error);
      return c.redirect(
        `/people?flash=${encodeURIComponent("Invitation created, but email delivery failed. Share the link below manually.")}&inviteLink=${encodeURIComponent(acceptUrl)}`,
      );
    }
  },
);

peopleRouter.post(
  "/invitations/:id/revoke",
  requireSession,
  requirePermission("invite_actor"),
  (c) => {
    const ctx = c.get("ctx");
    const id = parseInt(c.req.param("id"), 10);
    if (!isNaN(id)) {
      try {
        composition.revokeInvitation(ctx, { invitation_id: id });
      } catch { /* already resolved */ }
    }
    return c.redirect("/people");
  },
);

peopleRouter.post(
  "/grants",
  requireSession,
  requirePermission("grant_permission"),
  async (c) => {
    const ctx = c.get("ctx");
    const form = await c.req.formData();
    const grantee_actor_id = parseInt(form.get("grantee_actor_id") as string, 10);
    const permission_id = parseInt(form.get("permission_id") as string, 10);

    if (!isNaN(grantee_actor_id) && !isNaN(permission_id)) {
      try {
        composition.grantPermission(ctx, { grantee_actor_id, permission_id });
      } catch { /* invalid */ }
    }
    return c.redirect("/people");
  },
);

// Withdraw a permission whole: every active grant the person has over it.
peopleRouter.post(
  "/permissions/revoke",
  requireSession,
  requirePermission("grant_permission"),
  async (c) => {
    const ctx = c.get("ctx");
    const form = await c.req.formData();
    const grantee_actor_id = parseInt(form.get("grantee_actor_id") as string, 10);
    const permission_id = parseInt(form.get("permission_id") as string, 10);

    if (!isNaN(grantee_actor_id) && !isNaN(permission_id)) {
      try {
        composition.revokePermission(ctx, {
          grantee_actor_id,
          permission_id,
          reason: "withdrawn by PI",
        });
      } catch { /* nothing to withdraw */ }
    }
    return c.redirect("/people");
  },
);

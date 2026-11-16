import type { FC } from "hono/jsx";
import { Layout } from "./_layout.tsx";
import type { Actor } from "../lib/db.ts";
import type { GrantHistoryRow } from "../domain/grants.ts";
import type { Invitation } from "../domain/invitations.ts";
import type { Permission } from "../domain/permissions.ts";

/** A permission a person holds now, shown once, with the grants behind it. */
export interface HeldPermission {
  permission_id: number;
  label: string;
  grants: number;
}

export interface ActorRow {
  id: number;
  display_name: string;
  email: string;
  held: HeldPermission[];
  /** The permissions the person does not hold now: all the Give control offers. */
  available: Permission[];
}

export interface InvitationRow extends Invitation {
  email: string;
}

const Badge: FC<{ label: string; color?: "green" | "yellow" | "gray" }> = ({ label, color = "gray" }) => {
  const cls = color === "green"
    ? "bg-green-100 text-green-800"
    : color === "yellow"
    ? "bg-yellow-100 text-yellow-800"
    : "border opacity-60";
  return (
    <span class={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${cls}`}>
      {label}
    </span>
  );
};

export const PeoplePage: FC<{
  actor: Actor;
  actorRows: ActorRow[];
  pendingInvitations: InvitationRow[];
  history: GrantHistoryRow[];
  flash?: string | null;
  inviteLink?: string | null;
}> = ({ actor, actorRows, pendingInvitations, history, flash, inviteLink }) => (
  <Layout title="People &amp; Permissions" actor={actor} path="/people">
    <h1 class="text-2xl font-semibold mb-6">People &amp; Permissions</h1>

    {flash && (
      <p class="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded px-3 py-2">
        {flash}
      </p>
    )}

    {inviteLink && (
      <div class="mb-4 bg-yellow-50 border border-yellow-200 rounded px-3 py-2 text-sm">
        <p class="font-medium text-yellow-800 mb-1">Invite link — copy and share this with the invitee:</p>
        <code class="block break-all text-xs bg-white border border-yellow-200 rounded px-2 py-1.5 select-all text-yellow-900">
          {inviteLink}
        </code>
      </div>
    )}

    {/* ── Actors ─────────────────────────────────────────────── */}
    <section class="mb-8">
      <h2 class="text-base font-semibold mb-3">People</h2>
      <div class="raised rounded overflow-hidden p-0">
        <table class="w-full text-sm">
          <thead>
            <tr>
              <th class="text-left px-4 py-2 font-medium opacity-50">Name</th>
              <th class="text-left px-4 py-2 font-medium opacity-50">Email</th>
              <th class="text-left px-4 py-2 font-medium opacity-50">Permissions</th>
              <th class="text-left px-4 py-2 font-medium opacity-50">Give a permission</th>
            </tr>
          </thead>
          <tbody>
            {actorRows.map((row) => (
              <tr class="border-t">
                <td class="px-4 py-2">{row.display_name}</td>
                <td class="px-4 py-2 opacity-50">{row.email}</td>
                <td class="px-4 py-2">
                  <div class="flex flex-wrap gap-1">
                    {row.held.length === 0
                      ? <span class="text-xs opacity-40">none</span>
                      : row.held.map((h) => (
                        <span class="inline-flex items-center gap-1">
                          <Badge
                            label={h.grants > 1 ? `${h.label} (${h.grants} grants)` : h.label}
                            color="green"
                          />
                          <form method="post" action="/permissions/revoke" class="inline">
                            <input type="hidden" name="grantee_actor_id" value={String(row.id)} />
                            <input type="hidden" name="permission_id" value={String(h.permission_id)} />
                            <button type="submit" class="text-xs text-red-500 hover:text-red-700" title={`Take away: ${h.label}`}>
                              ✕
                            </button>
                          </form>
                        </span>
                      ))}
                  </div>
                </td>
                <td class="px-4 py-2">
                  {row.available.length === 0
                    ? <span class="text-xs opacity-40">holds every permission</span>
                    : (
                      <form method="post" action="/grants" class="flex items-center gap-1">
                        <input type="hidden" name="grantee_actor_id" value={String(row.id)} />
                        <select name="permission_id" class="border rounded px-1 py-1 text-xs">
                          {row.available.map((p) => (
                            <option value={String(p.id)}>{p.label}</option>
                          ))}
                        </select>
                        <button type="submit" class="inks-gray-1000 text-xs px-2 py-1 rounded hover:opacity-80">
                          Give
                        </button>
                      </form>
                    )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>

    {/* ── Permissions History ────────────────────────────────── */}
    <section class="mb-8">
      <h2 class="text-base font-semibold mb-3">Permissions History</h2>
      {history.length === 0
        ? <p class="text-sm opacity-50">No permission has been given yet.</p>
        : (
          <div class="raised rounded overflow-hidden p-0">
            <table class="w-full text-sm">
              <thead>
                <tr>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Given</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">To</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Permission</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Given by</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Now</th>
                </tr>
              </thead>
              <tbody>
                {history.map((g) => (
                  <tr class="border-t">
                    <td class="px-4 py-2 opacity-50 text-xs">{g.issued_at.slice(0, 16).replace("T", " ")}</td>
                    <td class="px-4 py-2">{g.grantee_name}</td>
                    <td class="px-4 py-2">{g.permission_label}</td>
                    <td class="px-4 py-2 opacity-50">{g.grantor_name}</td>
                    <td class="px-4 py-2">
                      {g.revoked_at === null
                        ? <Badge label="Held" color="green" />
                        : <Badge label={`Taken away ${g.revoked_at.slice(0, 10)}`} />}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
    </section>

    {/* ── Pending Invitations ────────────────────────────────── */}
    <section class="mb-8">
      <h2 class="text-base font-semibold mb-3">Pending Invitations</h2>
      {pendingInvitations.length === 0
        ? <p class="text-sm opacity-50">No pending invitations.</p>
        : (
          <div class="raised rounded overflow-hidden p-0">
            <table class="w-full text-sm">
              <thead>
                <tr>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Email</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Role</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Expires</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50">Accept link</th>
                  <th class="text-left px-4 py-2 font-medium opacity-50"></th>
                </tr>
              </thead>
              <tbody>
                {pendingInvitations.map((inv) => (
                  <tr class="border-t">
                    <td class="px-4 py-2">{inv.email}</td>
                    <td class="px-4 py-2"><Badge label={inv.intended_role} color="yellow" /></td>
                    <td class="px-4 py-2 opacity-50 text-xs">{inv.expires_at.slice(0, 10)}</td>
                    <td class="px-4 py-2">
                      <code class="text-xs bg-black/5 px-1 rounded break-all">
                        /invitations/accept/{inv.token}
                      </code>
                    </td>
                    <td class="px-4 py-2">
                      <form method="post" action={`/invitations/${inv.id}/revoke`}>
                        <button type="submit" class="text-xs text-red-500 hover:text-red-700">Revoke</button>
                      </form>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
    </section>

    {/* ── Issue Invitation ──────────────────────────────────── */}
    <section>
      <h2 class="text-base font-semibold mb-3">Invite someone</h2>
      <form method="post" action="/invitations" class="raised rounded flex flex-wrap items-end gap-3">
        <div>
          <label class="block text-xs font-medium mb-1">Email</label>
          <input name="email" type="email" required placeholder="new@example.com" class="border rounded px-3 py-1.5 text-sm w-52" />
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Display name</label>
          <input name="display_name" type="text" required placeholder="Jane Smith" class="border rounded px-3 py-1.5 text-sm w-40" />
        </div>
        <div>
          <label class="block text-xs font-medium mb-1">Role</label>
          <input name="intended_role" type="text" required placeholder="coordinator" class="border rounded px-3 py-1.5 text-sm w-32" />
        </div>
        <button type="submit" class="inks-gray-900 px-4 py-1.5 rounded text-sm">
          Send invitation
        </button>
      </form>
    </section>
  </Layout>
);

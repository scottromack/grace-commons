// Beacon's People & Permissions part: who may see the people and what they hold, giving a permission and taking it away whole, the history of every grant, and the
// invitations still pending. Rendered from SPEC.md in this directory (People & Permissions; The permissions; What each action writes) and from Attributed Permissions
// Admin and Permissions as they stand at the commit the entry names: every grant and every taking-away is attested by the person doing it, with that person's key.
// The invitation actions themselves (invite, revoke) are Beacon's (src/beacon.ts); this part reads the pending ones.
import { isBlank } from "./seam.ts";
import { type Permissions } from "./permissions.ts";
import { type AttributedPermissionsAdmin } from "./attributed_permissions_admin.ts";
import { type ActorIdentity } from "./actor_identity.ts";
import { type Invitation } from "./invitation.ts";
import { type People, type PersonView } from "./beacon_people.ts";
import { type BeaconAudit } from "./beacon_audit.ts";
import { PERMISSIONS, type BeaconDomain, type PermissionCode, type Refusal } from "./beacon_domain.ts";

export const ADMIN_WORDS = {
  notHeld: "That person does not hold that permission.",
  noPerson: "Not Found.",
  noPermission: "That is not a permission Beacon has.",
} as const;

export interface PersonRow { person: PersonView; held: PermissionCode[]; offered: PermissionCode[] }
export interface HistoryRow { grant_id: string; granted_at: string; to: string; code: PermissionCode | string; by: string; held_now: boolean; revoked_at: string | null }
export interface PendingRow { invitation_token: string; email: string; role: string; display_name: string; expires_at: string }
export interface PeopleView { people: PersonRow[]; history: HistoryRow[]; pending: PendingRow[]; may_grant: boolean; may_invite: boolean }

const isCode = (c: unknown): c is PermissionCode => PERMISSIONS.some((p) => p.code === c);

export class BeaconAdmin {
  constructor(private p: { people: People; domain: BeaconDomain; perms: Permissions; admin: AttributedPermissionsAdmin; actors: ActorIdentity; invitations: Invitation; audits: BeaconAudit }) {}

  /** The page's data for a person who holds `invite_actor` or `grant_permission`: each person once with what is held now, every grant ever made oldest first, and the pending invitations. */
  async view(actor_ref: string, readContext: (c: string) => { role: string; display_name: string } | null): Promise<PeopleView | Refusal> {
    if (isBlank(actor_ref)) return { refused: "invalid-request" };
    const mine = await this.p.domain.held(actor_ref);
    const may_grant = mine.includes("grant_permission"), may_invite = mine.includes("invite_actor");
    if (!may_grant && !may_invite) return { refused: "access-denied", needs: ["invite_actor", "grant_permission"] };
    const people = await this.p.people.list();
    const rows: PersonRow[] = [];
    for (const person of people) {
      const held = await this.p.domain.held(person.actor_ref);
      rows.push({ person, held, offered: PERMISSIONS.map((x) => x.code).filter((c) => !held.includes(c)) });         // the permissions the person does not hold are the ones offered
    }
    const name = new Map(people.map((x) => [x.actor_ref, x.display_name]));
    const attestations = new Map((await this.p.actors.read()).map((a) => [a.attestation_id, a.actor_ref]));
    const grants = (await this.p.perms.read()).sort((a, b) => (a.granted_at < b.granted_at ? -1 : a.granted_at > b.granted_at ? 1 : a.grant_id < b.grant_id ? -1 : 1));
    const history: HistoryRow[] = [];
    for (const g of grants) {
      const a = await this.p.admin.verifyGrantAttribution(g.grant_id);
      const by = typeof a === "object" && "issuance_attestation_id" in a ? attestations.get(a.issuance_attestation_id) : undefined;
      history.push({ grant_id: g.grant_id, granted_at: g.granted_at, to: name.get(g.subject_ref) ?? g.subject_ref, code: g.action_scope, by: by ? name.get(by) ?? by : "", held_now: g.status === "active", revoked_at: g.revoked_at });
    }
    const pending: PendingRow[] = [];
    for (const i of await this.p.invitations.read({ status: "pending" })) {
      const c = readContext(i.context);
      if (i.effective_status === "pending" && c && !isBlank(i.invitee_ref)) pending.push({ invitation_token: i.invitation_token, email: i.invitee_ref as string, role: c.role, display_name: c.display_name, expires_at: i.expires_at });
    }
    return { people: rows, history, pending, may_grant, may_invite };
  }

  /** Give a permission: a person who holds `grant_permission`, attested with that person's key; a permission already held is no error and makes no grant and no event. */
  async give(actor_ref: string, key: string, grantee_ref: string, code: string): Promise<{ grant_id: string } | { already: true } | Refusal> {
    const gate = await this.gate(actor_ref, key, grantee_ref, code);
    if (gate) return gate;
    if ((await this.p.domain.held(grantee_ref)).includes(code as PermissionCode)) return { already: true };               // not an error, and nothing is written: the screen answers as it would have (SPEC.md, The permissions)
    const r = await this.p.admin.issueGrant(grantee_ref, code, actor_ref, key);
    if ("orphan" in r) return { already: true };                                                                       // two people giving the same permission at once: the second finds it held
    if ("refused" in r) return this.map(r.refused);
    const wrote = await this.p.audits.write("grant.issued", actor_ref, key, { target: r.grant_id, grantee: grantee_ref, permission: code }, []);   // after the grant: Attributed Permissions Admin has no plan form, so not one transaction (SPEC.md, What is not written yet)
    return wrote === "ok" ? { grant_id: r.grant_id } : wrote;
  }

  /** Take a permission away, whole: every grant of it the person holds, one event for each (SPEC.md, What each action writes). */
  async take(actor_ref: string, key: string, grantee_ref: string, code: string): Promise<{ revoked: number } | Refusal> {
    const gate = await this.gate(actor_ref, key, grantee_ref, code);
    if (gate) return gate;
    const r = await this.p.admin.revokePermission(grantee_ref, code, actor_ref, key);
    if ("refused" in r) return r.refused === "not-permitted" ? { refused: "invalid-request", message: ADMIN_WORDS.notHeld } : this.map(r.refused);
    for (const id of r.revoked_grant_ids) {
      const wrote = await this.p.audits.write("grant.revoked", actor_ref, key, { target: id, grantee: grantee_ref, permission: code, reason: "taken away from People & Permissions" }, []);
      if (wrote !== "ok") return wrote;
    }
    return { revoked: r.revoked_grant_ids.length };
  }

  private async gate(actor_ref: string, key: string, grantee_ref: string, code: string): Promise<Refusal | null> {
    if (isBlank(actor_ref) || isBlank(key) || isBlank(grantee_ref)) return { refused: "invalid-request" };
    if (!(await this.p.domain.held(actor_ref)).includes("grant_permission")) return { refused: "access-denied", needs: ["grant_permission"] };
    if (!isCode(code)) return { refused: "invalid-request", message: ADMIN_WORDS.noPermission };
    if (!(await this.p.people.byActor(grantee_ref))) return { refused: "not-found", message: ADMIN_WORDS.noPerson };
    return null;
  }

  private map(r: string): Refusal {
    return r === "invalid-credential" ? { refused: "invalid-credential" } : r === "state-unavailable" || r === "registry-unavailable" || r === "mechanism-unavailable" ? { refused: "state-unavailable" } : r === "invalid-request" ? { refused: "invalid-request" } : { refused: "storage-failure" };
  }
}

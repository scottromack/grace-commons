// Invitation, Party Identity and Credential, as much of each as External
// Onboarding and its tests reach. Rule numbers are each atom's own; each reads
// the host clock once per call.
import type { Database } from "@db/sqlite";
import { createHash } from "node:crypto";
import type { Seam } from "./seam.ts";
import type { Faults } from "./faults.ts";

const blank = (s: string | undefined | null) => s === undefined || s === null || s.trim() === "";

// ---- Invitation ----
export interface InvitationConfig { ttlBoundsMs: [number, number]; defaultTtlMs?: number }
export interface InvitationRecord {
  invitation_token: string; inviter_ref: string; invitee_ref: string | null; context: string; initiated_at: string; expires_at: string;
  status: "pending" | "accepted" | "declined" | "revoked"; accepting_identity_ref: string | null; accepted_at: string | null;
}
export type Resolving = "not-known" | "already-resolved" | "expired" | "invalid-request" | "storage-failure";
export const invitation = {
  validInitiate(c: InvitationConfig, inviter_ref: string, context: string, ttlMs?: number): boolean {  // Operation 1 through 5
    const ttl = ttlMs ?? c.defaultTtlMs;
    return !blank(inviter_ref) && !blank(context) && ttl !== undefined && ttl >= c.ttlBoundsMs[0] && ttl <= c.ttlBoundsMs[1];
  },
  initiate(db: Database, seam: Seam, f: Faults, c: InvitationConfig, inviter_ref: string, invitee_ref: string | undefined, context: string, ttlMs?: number):
    { ok: string } | { refused: "invalid-request" | "storage-failure" } {
    const now = seam.now();
    if (!invitation.validInitiate(c, inviter_ref, context, ttlMs)) return { refused: "invalid-request" };
    if (f.hit("invitation.initiate")) return { refused: "storage-failure" };
    const token = seam.id("invitation");
    db.prepare("INSERT INTO invitation (invitation_token, inviter_ref, invitee_ref, context, initiated_at, expires_at, status) VALUES (?, ?, ?, ?, ?, ?, 'pending')")
      .run(token, inviter_ref, invitee_ref ?? null, context, now, new Date(Date.parse(now) + (ttlMs ?? c.defaultTtlMs!)).toISOString());
    return { ok: token };
  },
  // Operation 15 through 39, for the three resolving writes.
  resolve(db: Database, seam: Seam, f: Faults, kind: "accept" | "decline" | "revoke", token: string, args: { accepting_identity_ref?: string; revoked_by_ref?: string; reason?: string }):
    { ok: "accepted" | "declined" | "revoked" } | { refused: Resolving; stored?: string } {
    const now = seam.now();
    const i = db.prepare("SELECT * FROM invitation WHERE invitation_token = ?").get<InvitationRecord>(token);
    if (!i) return { refused: "not-known" };
    if (i.status !== "pending") return { refused: "already-resolved", stored: i.status };
    if (!(now < i.expires_at)) return { refused: "expired" };
    if (kind === "accept" && blank(args.accepting_identity_ref)) return { refused: "invalid-request" };
    if (kind === "revoke" && (blank(args.revoked_by_ref) || blank(args.reason))) return { refused: "invalid-request" };
    if (f.hit(`invitation.${kind}`, token)) return { refused: "storage-failure" };
    if (kind === "accept") db.prepare("UPDATE invitation SET status='accepted', accepting_identity_ref=?, accepted_at=? WHERE invitation_token=?").run(args.accepting_identity_ref!, now, token);
    else if (kind === "decline") db.prepare("UPDATE invitation SET status='declined', declined_at=? WHERE invitation_token=?").run(now, token);
    else db.prepare("UPDATE invitation SET status='revoked', revoked_by_ref=?, revocation_reason=?, revoked_at=? WHERE invitation_token=?").run(args.revoked_by_ref!, args.reason!, now, token);
    return { ok: kind === "accept" ? "accepted" : kind === "decline" ? "declined" : "revoked" };
  },
  // Operation 41 through 44.
  read(db: Database, seam: Seam, filter: { invitation_token?: string }) {
    const now = seam.now();
    return db.prepare("SELECT * FROM invitation").all<InvitationRecord>()
      .filter((i) => filter.invitation_token === undefined || i.invitation_token === filter.invitation_token)
      .map((i) => ({ ...i, effective_status: i.status === "pending" && !(now < i.expires_at) ? "expired" : i.status }));
  },
};

// ---- Party Identity ----
export interface PartyRecord {
  party_id: string; name: string; date_of_birth: string; document_type: string; document_ref: string; enrolling_actor_ref: string; enrolled_at: string; state: string;
}
export const partyIdentity = {
  validEnroll(now: string, name: string, dob: string, document_type: string, document_ref: string, enrolling_actor_ref: string): boolean {  // Operation 1 through 3
    if ([name, dob, document_type, document_ref, enrolling_actor_ref].some(blank)) return false;
    const d = Date.parse(dob);
    return !Number.isNaN(d) && /^\d{4}-\d{2}-\d{2}$/.test(dob) && !(now < dob);
  },
  enroll(db: Database, seam: Seam, f: Faults, name: string, dob: string, document_type: string, document_ref: string, enrolling_actor_ref: string):
    { ok: string } | { refused: "invalid-request" | "storage-failure" } {
    const now = seam.now();
    if (!partyIdentity.validEnroll(now, name, dob, document_type, document_ref, enrolling_actor_ref)) return { refused: "invalid-request" };
    if (f.hit("party.enroll", document_ref)) return { refused: "storage-failure" };
    const id = seam.id("party");
    const ord = (db.prepare("SELECT COUNT(*) AS n FROM party").get<{ n: number }>())!.n;
    db.prepare("INSERT INTO party VALUES (?, ?, ?, ?, ?, ?, ?, 'unverified', ?)").run(id, name, dob, document_type, document_ref, enrolling_actor_ref, now, ord);
    return { ok: id };
  },
  // Operation 48 through 56: party id, state and a range over enrollment instant.
  read(db: Database, query: { party_id?: string; state?: string; enrolled_at?: { from?: string; to?: string } }): { ok: PartyRecord[] } | { refused: "invalid-query" } {
    for (const k of Object.keys(query)) if (!["party_id", "state", "enrolled_at"].includes(k)) return { refused: "invalid-query" };
    if (query.state !== undefined && !["unverified", "verified", "suspended", "closed"].includes(query.state)) return { refused: "invalid-query" };
    const r = query.enrolled_at;
    return { ok: db.prepare("SELECT * FROM party ORDER BY ord").all<PartyRecord>().filter((p) =>
      (query.party_id === undefined || p.party_id === query.party_id) && (query.state === undefined || p.state === query.state) &&
      (!r || ((r.from === undefined || p.enrolled_at >= r.from) && (r.to === undefined || p.enrolled_at <= r.to)))) };
  },
};

// ---- Credential ----
export const DERIVATIONS: Record<string, (m: string) => string> = {
  password: (m) => createHash("sha256").update(`pw\n${m}`).digest("hex"),
};
export interface CredentialRecord { credential_id: string; principal_ref: string; credential_type: string; registered_at: string; expires_at: string | null; status: string; successor_id: string | null }
export const credential = {
  validRegister(now: string, principal_ref: string, material: string, type: string, expires_at?: string): boolean {  // Operation 1 through 5
    return !blank(principal_ref) && !blank(material) && !blank(type) && !!DERIVATIONS[type] && (expires_at === undefined || now < expires_at);
  },
  register(db: Database, seam: Seam, f: Faults, principal_ref: string, material: string, type: string, expires_at?: string):
    { ok: string } | { refused: "invalid-request" | "duplicate-active-credential" | "storage-failure" } {
    const now = seam.now();
    if (!credential.validRegister(now, principal_ref, material, type, expires_at)) return { refused: "invalid-request" };
    const live = db.prepare("SELECT expires_at FROM credential WHERE principal_ref = ? AND credential_type = ? AND status = 'active'").all<{ expires_at: string | null }>(principal_ref, type)
      .some((c) => c.expires_at === null || now < c.expires_at);
    if (live) return { refused: "duplicate-active-credential" };
    if (f.hit("credential.register", principal_ref)) return { refused: "storage-failure" };
    const id = seam.id("credential");
    db.prepare("INSERT INTO credential VALUES (?, ?, ?, ?, ?, ?, 'active', NULL, NULL)").run(id, principal_ref, type, DERIVATIONS[type](material), now, expires_at ?? null);
    return { ok: id };
  },
  // Operation 51 through 55: never the verifier.
  read(db: Database, filter: { principal_ref?: string; credential_type?: string }): CredentialRecord[] {
    return db.prepare("SELECT credential_id, principal_ref, credential_type, registered_at, expires_at, status, successor_id FROM credential ORDER BY registered_at, credential_id")
      .all<CredentialRecord>().filter((c) => Object.entries(filter).every(([k, v]) => (c as unknown as Record<string, unknown>)[k] === v));
  },
};

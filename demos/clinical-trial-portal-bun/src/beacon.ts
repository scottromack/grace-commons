// Beacon — the composition root: the patterns SPEC.md names, wired once, and the seed a render starts from.
// Built from SPEC.md (Built from, People, The data a render starts from) and the patterns' own declared surfaces.
//
// One instance of each constituent serves the deployment (External Onboarding Composes 1 to 4, 17; Attributed Permissions Admin Composes 1, 2;
// Login, Session-Gated Authorization). Login's audit events and the attempt records of the actions are attested under identities Beacon keeps:
// the people's own keys (SessionKeys, for what a person does) and the service identity Login writes under (Login Composes 12), which is a key
// made at start and held only in this process: it is registered with Actor Identity through the registry below and nowhere else.
// The seed makes the two accounts SPEC names, with their passwords, and the permissions they start with; the grants are made through
// Attributed Permissions Admin under the principal investigator's own key, so every one carries an attestation of who gave it.
import { generateKeyPairSync } from "node:crypto";
import { Store } from "./store.ts";
import { hostSeam, isBlank, type Seam } from "./seam.ts";
import { Credential, type CredentialType } from "./credential.ts";
import { Session } from "./session.ts";
import { EventLog } from "./event_log.ts";
import { ActorIdentity, type RegistryAnswer } from "./actor_identity.ts";
import { RetentionWindow } from "./retention_window.ts";
import { AuditTrail } from "./audit_trail.ts";
import { Login } from "./login.ts";
import { Permissions } from "./permissions.ts";
import { PartyIdentity } from "./party_identity.ts";
import { Invitation } from "./invitation.ts";
import { LeaseHost } from "./lease.ts";
import { RecoverableInvocation, type Journal, type JournalAnswer } from "./recoverable_invocation.ts";
import { ExternalOnboarding, onboardingBinding, onboardingProbe, ONBOARDING, type Trail } from "./external_onboarding.ts";
import { AttributedPermissionsAdmin } from "./attributed_permissions_admin.ts";
import { SessionGatedAuthorization } from "./session_gated_authorization.ts";
import { BeaconDomain, PERMISSIONS, type PermissionCode, type Refusal as DomainRefusal } from "./beacon_domain.ts";
import { People, SessionKeys, normalEmail, type PersonView } from "./beacon_people.ts";

const DAY = 86_400_000;
/** The seven days an invitation and a session last (SPEC.md, People & Permissions). */
const WEEK_S = 7 * 86_400;
/** Seven years, in days, the retention setting (SPEC.md, What each action writes). */
const RETENTION_MS = 2555 * DAY;

export interface BeaconOptions {
  seam?: Seam;
  /** Table prefix, for a test world; one deployment, none. */
  prefix?: string;
  /** The password hash's cost (argon2id); the default is Bun's own. A test world lowers it. */
  argon?: { memoryCost: number; timeCost: number };
  /** scrypt's cost for sealing a person's key; the default is the library's. A test world lowers it. */
  scrypt?: { N: number; r: number; p: number };
}

/** The seeded accounts and what they hold (SPEC.md, People; The permissions; The data a render starts from). */
export const SEED: { email: string; name: string; password: string; holds: PermissionCode[] }[] = [
  { email: "anya@beacon.clinical", name: "Dr. Anya Okonkwo", password: "demo-pi", holds: ["invite_actor", "grant_permission", "enroll_subject", "record_visit", "view_audit", "view_all_subjects"] },
  { email: "jordan@beacon.clinical", name: "Jordan Lee", password: "demo-cra", holds: ["view_audit"] },
];

/** What Party Identity is given where Beacon asks nothing (SPEC.md, People, "What Party Identity is given"). */
export const partyFor = (name: string, email: string) => ({ name, date_of_birth: "1900-01-01", document_type: "beacon-account", document_ref: email });

/** The words an invitation's page gives a link it will not take (SPEC.md, The screens, Accept an invitation). */
export const INVITATION_WORDS = {
  unknown: "This invitation link is invalid.",
  resolved: "This invitation has already been used or revoked.",
  expired: "This invitation has expired. Please ask for a new one.",
} as const;
/** The words for what a form leaves wrong; SPEC.md names none of these, so they are the plainest that keep the meaning. */
export const FORM_WORDS = {
  invite: "An email, a name and a role are required.",
  hasAccount: "That email already has an account.",
  password: "Choose a password of at least 8 characters.",
  confirm: "The two passwords do not match.",
} as const;
export const MIN_PASSWORD = 8;

/** An invitation's context holds what Beacon asks of the invitee's account and the form never asks again: the role and the display name (SPEC.md, People & Permissions, 3). */
export const invitationContext = (role: string, display_name: string): string => JSON.stringify({ role, display_name });
export const readContext = (context: string): { role: string; display_name: string } | null => {
  try { const c = JSON.parse(context); return typeof c?.role === "string" && typeof c?.display_name === "string" ? { role: c.role, display_name: c.display_name } : null; } catch { return null; }
};

export type InvitationFor = { email: string; role: string; display_name: string; expires_at: string } | { invalid: keyof typeof INVITATION_WORDS };
export type Accepted = { session_token: string; person: PersonView } | { invalid: keyof typeof INVITATION_WORDS } | DomainRefusal;

export type SignIn = { session_token: string; person: PersonView } | { refused: "invalid-credential" | "invalid-request" | "storage-failure" | "state-unavailable" };

export class Beacon {
  private constructor(
    readonly seam: Seam, readonly store: Store, readonly people: People, readonly keys: SessionKeys, readonly permissions: Permissions, readonly credentials: Credential,
    readonly session: Session, readonly login: Login, readonly gate: SessionGatedAuthorization, readonly audit: AuditTrail, readonly log: EventLog, readonly actors: ActorIdentity,
    readonly parties: PartyIdentity, readonly invitations: Invitation, readonly onboarding: ExternalOnboarding, readonly admin: AttributedPermissionsAdmin, readonly domain: BeaconDomain,
    readonly ri: RecoverableInvocation, readonly trail: Trail, private readonly service: { actor_ref: string; credential: string },
  ) {}

  static async open(store: Store, o: BeaconOptions = {}): Promise<Beacon> {
    const seam = o.seam ?? hostSeam;
    const prefix = o.prefix ?? "";
    const people = await People.open(store, seam, { tablePrefix: prefix, ...(o.scrypt ? { scrypt: o.scrypt } : {}) });
    const sk = generateKeyPairSync("ed25519");
    const service = { actor_ref: `beacon-service-${crypto.randomUUID()}`, credential: sk.privateKey.export({ format: "der", type: "pkcs8" }).toString("base64"), pub: sk.publicKey.export({ format: "der", type: "spki" }).toString("base64") };
    const registry = async (ref: string): Promise<RegistryAnswer> => (ref === service.actor_ref ? { answer: "material", current: service.pub } : people.registry(ref));
    const log = await EventLog.open(store, seam, { name: `${prefix}beacon` });
    const actors = await ActorIdentity.open(store, seam, registry);
    const retention = await RetentionWindow.open(store, seam, (ref) => (ref === "seven-years" ? { answer: "policy", policy: { durationMs: RETENTION_MS, maxPurgeDelayMs: 30 * DAY } } : { answer: "not-found" }), { resolutionMs: 1000, prefix: `${prefix}rw_` } as never);
    const audit = await AuditTrail.open(store, seam, { log, actors, retention }, { retentionPolicy: "seven-years", reconciliationOperator: "beacon-reconciliation" });
    const argon = o.argon ?? { memoryCost: 65536, timeCost: 2 };
    const password: CredentialType = {
      derive: async (m) => (m.length > 1024 ? null : Bun.password.hash(m.normalize("NFC"), { algorithm: "argon2id", ...argon })),
      check: (p, v) => Bun.password.verify(p.normalize("NFC"), v),
    };
    const credentials = await Credential.open(store, seam, { types: { password }, defaultValidityMs: null });
    const session = await Session.open(store, seam, { defaultDurationSeconds: WEEK_S, table: `${prefix}sessions` });
    const login = await Login.open(store, seam, { credential: credentials, session, audit }, { issuerReferences: ["beacon"], sessionDurationSeconds: WEEK_S, serviceIdentity: { actor_ref: service.actor_ref, credential: service.credential }, loginEventRetentionMs: RETENTION_MS, tablePrefix: prefix });
    const permissions = await Permissions.open(store, seam, { table: `${prefix}grants` });
    const gate = new SessionGatedAuthorization(session, permissions);
    const parties = await PartyIdentity.open(store, seam, { table: `${prefix}parties_identity`, headTable: `${prefix}party_heads` });
    const invitations = await Invitation.open(store, seam, { ttlBounds: { min: 60, max: 30 * 86_400 }, defaultTtl: WEEK_S, table: `${prefix}invitations` });
    const trail: Trail = { log: { payloadCap: log.payloadCap, read: (q) => log.read(q) }, index: (s) => audit.index(s), plan: (a, r, c, d, h = 0) => audit.plan(a, r, c, d, h) };
    const journal: Journal = { log, readRecord: (id) => audit.readRecord(id), recordAction: (a, r, c, d) => audit.recordAction(a, r, c, d) as Promise<JournalAnswer> };
    const lease = await LeaseHost.open(store, seam, { prefix: `${prefix}lease_` });
    const widths = { invitationToken: 43, partyId: 36, credentialId: 36, eventId: 36 };
    const probe = onboardingProbe({ invitation: invitations, parties, credentials });
    const binding = onboardingBinding({ onboardingCompletionBoundMs: 10_000, auditHorizonMs: RETENTION_MS, settlingPeriodMs: 100_000, referenceLengthCap: 128, mintedIdWidths: widths, probe });
    const ri = await RecoverableInvocation.start(seam, {
      journal, actSection: lease, bindings: { [ONBOARDING]: binding },
      compliance: { hardAlert: (x) => console.error("[beacon] hard alert", x), surface: (x) => console.error("[beacon] surfaced", x) },
      journalWriteBoundMs: 1000, pauseBoundMs: 100, commitRoundTripMs: 2000, clockAllowanceMs: 50, intentCandidatesCap: 5, referenceLengthCap: 128,
    });
    const onboarding = await ExternalOnboarding.open(store, seam, { invitation: invitations, parties, credentials, trail, ri }, {
      referenceLengthCap: 128, onboardingCompletionBoundMs: 10_000, clockOffsetAllowanceMs: 50, commitRoundTripMs: 2000, mintedIdWidths: widths,
      alert: (a) => console.error("[beacon] audit alert", a),
    });
    const admin = await AttributedPermissionsAdmin.open(store, seam, { permissions, actors }, { namespacePrefix: "beacon:", clockOffsetAllowanceMs: 50, retentionHorizonMs: RETENTION_MS });
    const domain = await BeaconDomain.open(store, seam, { permissions, trail }, { prefix });
    return new Beacon(seam, store, people, new SessionKeys(() => Date.parse(seam.now())), permissions, credentials, session, login, gate, audit, log, actors, parties, invitations, onboarding, admin, domain, ri, trail, service);
  }

  /** A render starts from its seed and nothing else (SPEC.md): the two accounts, their permissions. Run again, it makes nothing twice. */
  async seed(): Promise<void> {
    const made: { actor_ref: string; password: string; holds: PermissionCode[] }[] = [];
    for (const s of SEED) {
      let p = await this.people.byEmail(s.email);
      if (!p) {
        const e = await this.parties.enroll(...(Object.values(partyFor(s.name, s.email)) as [string, string, string, string]), "seed");
        if ("refused" in e) throw new Error(`seed: Party Identity refused ${s.email}: ${e.refused}`);
        const c = await this.credentials.register(e.party_id, s.password, "password");
        if ("refused" in c) throw new Error(`seed: Credential refused ${s.email}: ${c.refused}`);
        const m = await this.people.create({ party_id: e.party_id, email: s.email, display_name: s.name, password: s.password });
        if ("refused" in m) throw new Error(`seed: People refused ${s.email}: ${m.refused}`);
        p = (await this.people.byActor(m.actor_ref))!;
      }
      made.push({ actor_ref: p.actor_ref, password: s.password, holds: s.holds });
    }
    // Each permission is given through Attributed Permissions Admin under the principal investigator's own key, so each carries an attestation (SPEC.md, What is not written yet, 1).
    const pi = made[0];
    const key = await this.people.unlock(pi.actor_ref, pi.password);
    if (!key) throw new Error("seed: the principal investigator's key did not open");
    for (const m of made) for (const code of m.holds) {
      const r = await this.admin.issueGrant(m.actor_ref, code, pi.actor_ref, key);
      if ("refused" in r || "orphan" in r) throw new Error(`seed: grant ${code} to ${m.actor_ref} refused: ${JSON.stringify(r)}`);
    }
  }

  // ---- Signing in and out (Login; SPEC.md, Sign in) -----------------------------------------------------------------------

  /** Sign in: Login verifies the password and issues the session; the person's key is opened with the same password and held for the session. A wrong email and a wrong password answer alike. */
  async signIn(email: string, password: string): Promise<SignIn> {
    if (isBlank(email) || typeof password !== "string" || password === "") return { refused: "invalid-request" };
    const person = await this.people.byEmail(email);
    // An email nobody holds is a login that fails like any other, and is logged as one (Login Action wiring 2, 3).
    const principal = person ? person.party_id : `unknown:${normalEmail(email)}`;
    const r = await this.login.login(principal, "password", password, "beacon");
    if (r === "invalid-credential") return { refused: "invalid-credential" };
    if ("refused" in r) return { refused: r.refused === "invalid-request" ? "invalid-request" : r.refused === "state-unavailable" ? "state-unavailable" : "storage-failure" };
    const key = await this.people.unlock(person!.actor_ref, password);
    if (!key) { await this.login.logout(r.session_token, person!.actor_ref, "sign-in key did not open"); return { refused: "storage-failure" }; }
    const v = await this.session.validate(r.session_token);
    this.keys.hold(r.session_token, key, "valid" in v ? Date.parse(v.valid.expires_at) : Date.parse(this.seam.now()));
    return { session_token: r.session_token, person };
  }

  /** Sign out: the session is revoked through the system's own call, and the key it held is dropped. */
  async signOut(session_token: string): Promise<void> {
    const v = await this.session.validate(session_token);
    this.keys.drop(session_token);
    if ("valid" in v) await this.login.logout(session_token, v.valid.principal_ref, "sign-out");
  }

  /** Who a session is, and what that person holds now; null where the session is not valid (expired, revoked, unknown). */
  async who(session_token: string): Promise<{ person: PersonView; holds: PermissionCode[] } | null> {
    if (isBlank(session_token)) return null;
    const v = await this.session.validate(session_token);
    if (!("valid" in v)) { this.keys.drop(session_token); return null; }
    const person = await this.people.byActor(v.valid.principal_ref);
    if (!person) return null;
    return { person, holds: await this.domain.held(person.actor_ref) };
  }

  /** The signing key a signed-in person holds for the session, or null (a restart drops it, and the person signs in again). */
  keyOf(session_token: string): string | null { return this.keys.get(session_token); }

  // ---- Invitations (External Onboarding; SPEC.md, The screens, Accept an invitation; People & Permissions, 3) ------------------

  /** Invite someone: the inviter holds `invite_actor` and signs the invitation with the key held for the session. The invitee is the email, trimmed and in lower case; the role and the display name travel as the context. */
  async invite(session_token: string, email: string, display_name: string, role: string): Promise<{ invitation_token: string } | DomainRefusal> {
    const me = await this.who(session_token), key = this.keyOf(session_token);
    if (!me || !key) return { refused: "invalid-credential" };                                                       // inviting: a session with no key
    if (!me.holds.includes("invite_actor")) return { refused: "access-denied", needs: ["invite_actor"] };           // who may invite
    if (isBlank(email) || isBlank(display_name) || isBlank(role)) return { refused: "invalid-request", message: FORM_WORDS.invite };
    const invitee = normalEmail(email);
    if (await this.people.byEmail(invitee)) return { refused: "invalid-request", message: FORM_WORDS.hasAccount };
    const r = await this.onboarding.invite(me.person.actor_ref, invitee, invitationContext(role.trim(), display_name.trim()), WEEK_S, key);
    if ("invitation_token" in r) return r;
    return r.refused === "invalid-request" ? { refused: "invalid-request", message: FORM_WORDS.invite } : r.refused === "invalid-credential" ? { refused: "invalid-credential" } : r.refused === "state-unavailable" ? { refused: "state-unavailable" } : { refused: "storage-failure" };
  }

  /** Revoke a pending invitation: a person who holds `invite_actor`, signing with the session's key. */
  async revokeInvitation(session_token: string, invitation_token: string): Promise<"revoked" | DomainRefusal> {
    const me = await this.who(session_token), key = this.keyOf(session_token);
    if (!me || !key) return { refused: "invalid-credential" };                                                       // revoking: a session with no key
    if (!me.holds.includes("invite_actor")) return { refused: "access-denied", needs: ["invite_actor"] };           // who may revoke
    const r = await this.onboarding.revoke(invitation_token, me.person.actor_ref, "revoked by the inviter", key);
    if (r === "revoked") return r;
    if (r.refused === "invitation-invalid") return r.cause === "not-known" ? { refused: "not-found", message: "Not Found." } : { refused: "invalid-request", message: INVITATION_WORDS[r.cause === "expired" ? "expired" : "resolved"] };
    return r.refused === "invalid-request" ? { refused: "invalid-request" } : r.refused === "invalid-credential" ? { refused: "invalid-credential" } : r.refused === "state-unavailable" ? { refused: "state-unavailable" } : { refused: "storage-failure" };
  }

  /** What the accept page shows for a link: the invited email, the intended role and the name, or why the link will not do. */
  async invitationFor(invitation_token: string): Promise<InvitationFor> {
    if (isBlank(invitation_token)) return { invalid: "unknown" };
    const i = (await this.invitations.read({ invitation_token }))[0];
    if (!i) return { invalid: "unknown" };
    if (i.effective_status === "expired") return { invalid: "expired" };
    if (i.effective_status !== "pending") return { invalid: "resolved" };
    const c = readContext(i.context);
    if (!c || isBlank(i.invitee_ref)) return { invalid: "unknown" };                                                 // an invitation Beacon did not make
    return { email: i.invitee_ref as string, role: c.role, display_name: c.display_name, expires_at: i.expires_at };
  }

  /**
   * Accept an invitation: the person sets a password; External Onboarding enrolls the party and registers the password under the service identity
   * (the one acting where the person has no key yet), then the person and the person's key are made under that party id, and the person is signed in.
   * A stop between the onboarding and the person's creation leaves a party with no person: the link is then spent and no repair is written (SPEC.md, What is not written yet).
   */
  async acceptInvitation(invitation_token: string, password: string, confirmation: string): Promise<Accepted> {
    const i = await this.invitationFor(invitation_token);
    if ("invalid" in i) return i;
    if (typeof password !== "string" || [...password].length < MIN_PASSWORD) return { refused: "invalid-request", message: FORM_WORDS.password };
    if (password !== confirmation) return { refused: "invalid-request", message: FORM_WORDS.confirm };
    if (await this.people.byEmail(i.email)) return { refused: "invalid-request", message: FORM_WORDS.hasAccount };
    const p = partyFor(i.display_name, i.email);
    const r = await this.onboarding.onboard(invitation_token, i.email, p.name, p.date_of_birth, p.document_type, p.document_ref, "password", password, undefined, this.service.actor_ref, this.service.credential);
    if ("refused" in r) {
      if (r.refused === "invitation-invalid") return { invalid: r.cause === "not-known" ? "unknown" : r.cause === "expired" ? "expired" : "resolved" };
      if (r.refused === "invalid-request") return { refused: "invalid-request", message: FORM_WORDS.password };
      return r.refused === "state-unavailable" ? { refused: "state-unavailable" } : { refused: "storage-failure" };
    }
    const m = await this.people.create({ party_id: r.party_id, email: i.email, display_name: i.display_name, password });
    if ("refused" in m) return m.refused === "email-taken" ? { refused: "invalid-request", message: FORM_WORDS.hasAccount } : { refused: m.refused === "invalid-request" ? "invalid-request" : "storage-failure" } as DomainRefusal;
    const s = await this.signIn(i.email, password);
    return "refused" in s ? { refused: s.refused === "invalid-credential" ? "invalid-credential" : s.refused === "invalid-request" ? "invalid-request" : s.refused === "state-unavailable" ? "state-unavailable" : "storage-failure" } : s;
  }
}

export { PERMISSIONS };

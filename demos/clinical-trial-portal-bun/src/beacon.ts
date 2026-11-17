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
import { BeaconDomain, PERMISSIONS, type PermissionCode } from "./beacon_domain.ts";
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

export type SignIn = { session_token: string; person: PersonView } | { refused: "invalid-credential" | "invalid-request" | "storage-failure" | "state-unavailable" };

export class Beacon {
  private constructor(
    readonly seam: Seam, readonly store: Store, readonly people: People, readonly keys: SessionKeys, readonly permissions: Permissions, readonly credentials: Credential,
    readonly session: Session, readonly login: Login, readonly gate: SessionGatedAuthorization, readonly audit: AuditTrail, readonly log: EventLog, readonly actors: ActorIdentity,
    readonly parties: PartyIdentity, readonly invitations: Invitation, readonly onboarding: ExternalOnboarding, readonly admin: AttributedPermissionsAdmin, readonly domain: BeaconDomain,
    readonly ri: RecoverableInvocation, readonly trail: Trail,
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
    return new Beacon(seam, store, people, new SessionKeys(() => Date.parse(seam.now())), permissions, credentials, session, login, gate, audit, log, actors, parties, invitations, onboarding, admin, domain, ri, trail);
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
}

export { PERMISSIONS };

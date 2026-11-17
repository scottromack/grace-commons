// Beacon's people and the keys they sign with. Beacon's own, no library atom (SPEC.md, Built from; What is not written yet, 1).
//
// A person has a name, an email and an actor reference, and one signing key made for that person when the person is created (at
// accepting an invitation, or in the seed). Attributed Permissions Admin has every grant and every taking-away attested by the person
// doing it, through Actor Identity, with that person's credential (Action wiring 2, 17): in Beacon that credential is this key.
// Scott's answer (2026-11-16 10:36 PM Central, rounds/escalations.md 04:36Z, "Yes to both." "Agree with the mayor."): a key made for each
// person at invitation acceptance, kept by the server, unlocked by that person's password at sign-in, held for the session.
//
// The key is an Ed25519 private key. It is kept SEALED: AES-256-GCM under a key scrypt derives from the person's password and a salt of
// the person's own, so the server holds nothing a person's signature can be made from except while that person is signed in. The public
// half is what Actor Identity's registry answers for the person's actor reference (Actor Identity Term registry). The unsealed key is
// held in this process's memory for the session and dropped at sign-out or at the session's end (SessionKeys); a restart signs everyone out.
import { generateKeyPairSync, randomBytes, scrypt, createCipheriv, createDecipheriv } from "node:crypto";
import { Store, Guard, type Row } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { type RegistryAnswer } from "./actor_identity.ts";

export interface PersonView { actor_ref: string; party_id: string; email: string; display_name: string; created_at: string }

export interface PeopleConfig {
  /** A prefix for the table this instance keeps; one instance serves a deployment, so the default is none (a test world names its own). */
  tablePrefix?: string;
  /** scrypt's cost; the default is the library's recommended interactive cost. A test world lowers it. */
  scrypt?: { N: number; r: number; p: number };
}

type Stored = Row & { _id: string; party_id: string; email: string; display_name: string; public_key: string; sealed_key: string; created_at: string };
const T = "people";
const DEFAULT_SCRYPT = { N: 16384, r: 8, p: 1 };

/** The email as Beacon compares it: trimmed, and in lower case (SPEC.md does not say; an address is read as one whatever its case). */
export const normalEmail = (e: string): string => e.trim().toLowerCase();

const derive = (password: string, salt: Buffer, c: { N: number; r: number; p: number }) =>
  new Promise<Buffer>((res, rej) => scrypt(password.normalize("NFC"), salt, 32, { N: c.N, r: c.r, p: c.p, maxmem: 256 * c.N * c.r }, (e, k) => (e ? rej(e) : res(k))));

export class People {
  private constructor(private store: Store, private seam: Seam, private T: string, private cost: { N: number; r: number; p: number }) {}

  static async open(store: Store, seam: Seam, cfg: PeopleConfig = {}): Promise<People> {
    const T_ = `${cfg.tablePrefix ?? ""}${T}`;
    await store.declare(T_, ["party_id", "email", "display_name", "public_key", "sealed_key", "created_at"]);
    return new People(store, seam, T_, cfg.scrypt ?? DEFAULT_SCRYPT);
  }

  /** Make a person and the person's key: the key pair, the private half sealed under the password. The actor reference is the seam's id material. */
  async create(a: { party_id: string; email: string; display_name: string; password: string }): Promise<{ actor_ref: string } | { refused: "invalid-request" | "email-taken" | "storage-failure" }> {
    if (isBlank(a.party_id) || isBlank(a.email) || isBlank(a.display_name) || typeof a.password !== "string" || a.password === "") return { refused: "invalid-request" };
    const email = normalEmail(a.email);
    const k = generateKeyPairSync("ed25519");
    const salt = randomBytes(16), iv = randomBytes(12);
    const key = await derive(a.password, salt, this.cost);
    const c = createCipheriv("aes-256-gcm", key, iv);
    const ct = Buffer.concat([c.update(k.privateKey.export({ format: "der", type: "pkcs8" })), c.final()]);
    const sealed = JSON.stringify({ v: 1, kdf: "scrypt", ...this.cost, salt: salt.toString("base64"), iv: iv.toString("base64"), tag: c.getAuthTag().toString("base64"), ct: ct.toString("base64") });
    const actor_ref = this.seam.idMaterial();
    try {
      await this.store.commit([
        this.store.assertNone(this.T, "email = $1", [email], "email-taken"),                                        // one person to an email
        this.store.assertNone(this.T, "_id = $1", [actor_ref], "id-held"),
        this.store.put(this.T, { _id: actor_ref, party_id: a.party_id, email, display_name: a.display_name.trim(), public_key: k.publicKey.export({ format: "der", type: "spki" }).toString("base64"), sealed_key: sealed, created_at: this.seam.now() }),
      ]);
    } catch (e) {
      if (e instanceof Guard && e.guard === "email-taken") return { refused: "email-taken" };
      return { refused: "storage-failure" };
    }
    return { actor_ref };
  }

  /** The person's private key as base64 PKCS8 (what Actor Identity's credential check takes), or null where the password does not open it. */
  async unlock(actor_ref: string, password: string): Promise<string | null> {
    const p = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE _id = $1`, [actor_ref ?? ""]))[0];
    if (!p || typeof password !== "string") return null;
    const s = JSON.parse(p.sealed_key) as { N: number; r: number; p: number; salt: string; iv: string; tag: string; ct: string };
    try {
      const key = await derive(password, Buffer.from(s.salt, "base64"), s);
      const d = createDecipheriv("aes-256-gcm", key, Buffer.from(s.iv, "base64"));
      d.setAuthTag(Buffer.from(s.tag, "base64"));
      return Buffer.concat([d.update(Buffer.from(s.ct, "base64")), d.final()]).toString("base64");
    } catch { return null; }                                                                                        // the tag does not match: a wrong password
  }

  /** What Actor Identity asks of its deployment for an actor reference: the public material in force, or that the actor is unknown (Actor Identity Term registry). */
  registry = async (actor_ref: string): Promise<RegistryAnswer> => {
    const p = (await this.store.read<Stored>(`SELECT public_key FROM ${this.T} WHERE _id = $1`, [actor_ref ?? ""]))[0];
    return p ? { answer: "material", current: p.public_key } : { answer: "unknown-actor" };
  };

  private view = (p: Stored): PersonView => ({ actor_ref: p._id, party_id: p.party_id, email: p.email, display_name: p.display_name, created_at: p.created_at });
  async byEmail(email: string): Promise<PersonView | null> {
    if (isBlank(email)) return null;
    const p = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE email = $1`, [normalEmail(email)]))[0];
    return p ? this.view(p) : null;
  }
  async byActor(actor_ref: string): Promise<PersonView | null> {
    const p = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE _id = $1`, [actor_ref ?? ""]))[0];
    return p ? this.view(p) : null;
  }
  async byParty(party_id: string): Promise<PersonView | null> {
    const p = (await this.store.read<Stored>(`SELECT * FROM ${this.T} WHERE party_id = $1`, [party_id ?? ""]))[0];
    return p ? this.view(p) : null;
  }
  /** Every person, once, oldest first (SPEC.md, People & Permissions, 1). */
  async list(): Promise<PersonView[]> {
    return (await this.store.read<Stored>(`SELECT * FROM ${this.T}`)).sort((a, b) => (a.created_at < b.created_at ? -1 : a.created_at > b.created_at ? 1 : a._id < b._id ? -1 : 1)).map(this.view);
  }
}

/** The unsealed keys of the people signed in, each for the session's life and no longer: in this process's memory and nowhere else. */
export class SessionKeys {
  private held = new Map<string, { key: string; until: number }>();
  constructor(private now: () => number) {}
  hold(session_token: string, key: string, untilMs: number): void { this.held.set(session_token, { key, until: untilMs }); }
  /** The key a session holds, or null where there is none or the session's time has come. */
  get(session_token: string): string | null {
    const h = this.held.get(session_token);
    if (!h) return null;
    if (this.now() >= h.until) { this.held.delete(session_token); return null; }
    return h.key;
  }
  drop(session_token: string): void { this.held.delete(session_token); }
  get size(): number { return this.held.size; }
}

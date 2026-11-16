// Credential — does this presented material belong to this principal, for this kind of credential?
// Rendered from atoms/credential.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// A credential is one record, `credential`, whose _id is its credential id. A change of status is a
// new version of the record under the same _id (Execution Contract Database 5), so the earlier
// version is there to read. The guard of a write is an ASSERT in the write's own transaction
// (Database 2), so two registrations of one pair at once leave one.
import { Store, Guard, type Row } from "./store.ts";
import { type Seam, isBlank, instant } from "./seam.ts";

export type Status = "active" | "rotated" | "revoked";
export type Refusal = "invalid-request" | "duplicate-active-credential" | "not-known" | "not-active" | "already-terminal" | "storage-failure";
export type Failure = "material-mismatch" | "no-active-credential";

/** A credential type's two functions and bound (Capability requirement 4, 18, 27, 29 to 32). */
export interface CredentialType {
  /** Derive the verifier from the material; null refuses it (Operation 66, 67). */
  derive(material: string): Promise<string | null>;
  /** Does the presented material match the verifier; constant time over a secret verifier (Capability requirement 40). */
  check(presented: string, verifier: string): Promise<boolean>;
}
export interface Registry {
  types: Record<string, CredentialType>;
  /** The default validity in milliseconds, or null for unbounded (Capability requirement 7). */
  defaultValidityMs: number | null;
}

export interface CredentialView {
  credential_id: string;
  principal_ref: string;
  credential_type: string;
  registered_at: string;
  expires_at: string | null;
  status: Status;
  /** expired where an active credential reads lapsed, the stored status otherwise (Operation 52, Invariant 12.2). */
  effective_status: Status | "expired";
  rotated_at: string | null;
  successor_credential_id: string | null;
  revoked_by_ref: string | null;
  revocation_reason: string | null;
  revoked_at: string | null;
}

type Stored = Row & {
  _id: string; principal_ref: string; credential_type: string; verifier: string; registered_at: string;
  expires_at: string | null; status: Status; rotated_at: string | null; successor_credential_id: string | null;
  revoked_by_ref: string | null; revocation_reason: string | null; revoked_at: string | null;
};

const T = "credential";

const COLUMNS = ["principal_ref", "credential_type", "verifier", "registered_at", "expires_at", "status", "rotated_at",
  "successor_credential_id", "revoked_by_ref", "revocation_reason", "revoked_at"];

export class Credential {
  private constructor(private store: Store, private seam: Seam, private registry: Registry) {}

  static async open(store: Store, seam: Seam, registry: Registry): Promise<Credential> {
    await store.declare(T, COLUMNS);
    return new Credential(store, seam, registry);
  }

  // Term window reading: an active credential lives while its expiry is absent or still ahead of now;
  // the boundary instant reads lapsed.
  private static live(c: Stored, now: string): boolean {
    return c.status === "active" && (c.expires_at === null || now < c.expires_at);
  }

  private async pair(principal: string, type: string): Promise<Stored[]> {
    return this.store.read<Stored>(`SELECT * FROM ${T} WHERE principal_ref = $1 AND credential_type = $2`, [principal, type]);
  }

  /** The expiry a register or rotate records: the one supplied, else the default expiry (Operation 12, 13, 71, 72). */
  private expiry(now: string, supplied: unknown): { expires: string | null } | Refusal {
    if (!isBlank(supplied)) {
      const at = instant(supplied);
      if (at === null) return "invalid-request";            // Operation 80, 81
      if (!(now < at)) return "invalid-request";            // Operation 5, 63
      return { expires: at };
    }
    const d = this.registry.defaultValidityMs;
    return { expires: d === null ? null : new Date(Date.parse(now) + d).toISOString() };
  }

  async register(principal_ref: string, material: string, credential_type: string, expires_at?: string): Promise<{ credential_id: string } | { refused: Refusal }> {
    if (isBlank(principal_ref) || isBlank(credential_type)) return { refused: "invalid-request" };       // Operation 1, 3
    if (material === undefined || material === null || material === "") return { refused: "invalid-request" }; // Operation 2 (empty material)
    const type = this.registry.types[credential_type];
    if (!type) return { refused: "invalid-request" };                                                        // Operation 4
    const now = this.seam.now();
    const ex = this.expiry(now, expires_at);
    if (typeof ex === "string") return { refused: ex };
    const verifier = await type.derive(material);
    if (verifier === null) return { refused: "invalid-request" };                                            // Operation 66
    // Operation 6: an effective-active credential for the pair refuses; Operation 8: a lapsed one does not.
    if ((await this.pair(principal_ref, credential_type)).some((c) => Credential.live(c, now))) return { refused: "duplicate-active-credential" };
    const id = this.seam.idMaterial();                                                                       // Operation 9, Identity 2
    try {
      await this.store.commit([
        this.store.assertNone(T, "principal_ref = $1 AND credential_type = $2 AND status = 'active' AND (expires_at IS NULL OR expires_at > $3)", [principal_ref, credential_type, now], "duplicate"),
        this.store.assertNone(T, "_id = $1", [id], "id-held"),                                               // Identity 5
        this.store.put(T, {
          _id: id, principal_ref, credential_type, verifier, registered_at: now,                            // Operation 10, 11, 14
          expires_at: ex.expires, status: "active",                                                         // Operation 12, 13, 15
          rotated_at: null, successor_credential_id: null, revoked_by_ref: null, revocation_reason: null, revoked_at: null,
        }),
      ]);
    } catch (e) {
      if (e instanceof Guard) return { refused: e.guard === "duplicate" ? "duplicate-active-credential" : "storage-failure" };
      return { refused: "storage-failure" };                                                                 // Operation 45
    }
    return { credential_id: id };                                                                            // Operation 16
  }

  async verify(principal_ref: string, credential_type: string, presented: string): Promise<"verified" | { failed: Failure }> {
    const now = this.seam.now();
    const type = this.registry.types[credential_type];
    // Operation 70: check against the effective-active credential with the latest registration instant.
    const live = isBlank(principal_ref) || isBlank(credential_type) ? [] : (await this.pair(principal_ref, credential_type)).filter((c) => Credential.live(c, now));
    live.sort((a, b) => (a.registered_at < b.registered_at ? 1 : a.registered_at > b.registered_at ? -1 : a._id < b._id ? 1 : -1));
    // Operation 18, 19: no effective-active credential answers one reason, whatever the cause. Operation 20: the window is read before the material.
    if (live.length === 0 || !type) return { failed: "no-active-credential" };
    const ok = await type.check(presented ?? "", live[0].verifier);                                         // Operation 21, 68
    return ok ? "verified" : { failed: "material-mismatch" };                                              // Operation 22, 23; Invariant 3.1
  }

  async rotate(credential_id: string, new_material: string, expires_at?: string): Promise<{ credential_id: string } | { refused: Refusal }> {
    const now = this.seam.now();
    const cur = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [credential_id ?? ""]))[0];
    if (!cur) return { refused: "not-known" };                                                               // Operation 27
    // Operation 28, 65: the credential must be effective-active, and no other may be for the pair.
    const siblings = (await this.pair(cur.principal_ref, cur.credential_type)).filter((c) => Credential.live(c, now));
    if (!Credential.live(cur, now) || siblings.some((c) => c._id !== cur._id)) return { refused: "not-active" };
    if (new_material === undefined || new_material === null || new_material === "") return { refused: "invalid-request" }; // Operation 31
    const ex = this.expiry(now, expires_at);
    if (typeof ex === "string") return { refused: ex };
    const verifier = await this.registry.types[cur.credential_type].derive(new_material);
    if (verifier === null) return { refused: "invalid-request" };                                            // Operation 67
    const id = this.seam.idMaterial();                                                                       // Operation 58
    try {
      await this.store.commit([
        this.store.assertSome(T, "_id = $1 AND status = 'active' AND (expires_at IS NULL OR expires_at > $2)", [cur._id, now], "not-active"),
        this.store.assertNone(T, "_id = $1", [id], "id-held"),
        this.store.put(T, {
          _id: id, principal_ref: cur.principal_ref, credential_type: cur.credential_type, verifier,         // Operation 35, 59
          registered_at: now, expires_at: ex.expires, status: "active",                                      // Operation 36, 60, 61, 62
          rotated_at: null, successor_credential_id: null, revoked_by_ref: null, revocation_reason: null, revoked_at: null,
        }),
        // Operation 37 to 39; Invariant 6.1, 6.2: the prior credential changes only status, rotation instant and successor.
        this.store.put(T, { ...cur, status: "rotated", rotated_at: now, successor_credential_id: id }),
      ]);
    } catch (e) {
      if (e instanceof Guard) return { refused: e.guard === "not-active" ? "not-active" : "storage-failure" };
      return { refused: "storage-failure" };
    }
    return { credential_id: id };                                                                            // Operation 41
  }

  async revoke(credential_id: string, revoked_by_ref: string, reason: string): Promise<"revoked" | { refused: Refusal }> {
    const now = this.seam.now();
    const cur = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [credential_id ?? ""]))[0];
    if (!cur) return { refused: "not-known" };                                                               // Operation 27
    if (!Credential.live(cur, now)) return { refused: "already-terminal" };                                  // Operation 29
    if (isBlank(revoked_by_ref) || isBlank(reason)) return { refused: "invalid-request" };                   // Operation 32, 33
    try {
      await this.store.commit([
        this.store.assertSome(T, "_id = $1 AND status = 'active' AND (expires_at IS NULL OR expires_at > $2)", [cur._id, now], "terminal"),
        this.store.put(T, { ...cur, status: "revoked", revoked_by_ref, revocation_reason: reason, revoked_at: now }), // Operation 42, 43
      ]);
    } catch (e) {
      if (e instanceof Guard) return { refused: "already-terminal" };
      return { refused: "storage-failure" };
    }
    return "revoked";
  }

  /** Every matching credential, effective status computed, never the verifier (Operation 51 to 53, 69; Invariant 12.2). */
  async read(filter: { principal_ref?: string; credential_type?: string; credential_id?: string } = {}): Promise<CredentialView[]> {
    const now = this.seam.now();
    const named = Object.entries(filter).filter(([, v]) => v !== undefined);
    if (named.some(([, v]) => isBlank(v))) return [];                                                       // Operation 73
    const col: Record<string, string> = { principal_ref: "principal_ref", credential_type: "credential_type", credential_id: "_id" };
    const where = named.map(([k], i) => `${col[k]} = $${i + 1}`).join(" AND ");
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T}${where ? " WHERE " + where : ""}`, named.map(([, v]) => v as string));
    rows.sort((a, b) => (a.registered_at < b.registered_at ? -1 : a.registered_at > b.registered_at ? 1 : a._id < b._id ? -1 : 1)); // Operation 69
    return rows.map((c) => ({
      credential_id: c._id, principal_ref: c.principal_ref, credential_type: c.credential_type, registered_at: c.registered_at,
      expires_at: c.expires_at, status: c.status,
      effective_status: c.status === "active" && !Credential.live(c, now) ? "expired" : c.status,
      rotated_at: c.rotated_at, successor_credential_id: c.successor_credential_id,
      revoked_by_ref: c.revoked_by_ref, revocation_reason: c.revocation_reason, revoked_at: c.revoked_at,
    }));
  }
}

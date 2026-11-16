// Tamper Evidence — has this set of records changed since it was sealed?
// Rendered from atoms/tamper-evidence.md (the page at the commit the entry names), with no code of
// any other render opened. A rule's label is in the comment where the code answers it.
//
// A seal is one record, `evidence`, under its evidence id, written once and never again (Invariant
// 1.1, State 6, 7). The mechanism is the deployment's (Operation 26): it computes the proof, checks it,
// and says whether a presented record set is the one the evidence names (Capability requirement 3 to 5).
// The atom reads no proof's structure (Invariant 8.2). Two mechanisms are given here, both over a
// record set that is a list of records: an unkeyed SHA-256 hash chain and a keyed HMAC-SHA-256 chain.
import { createHash, createHmac } from "node:crypto";
import { Store, type Row } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";

export type MechanismFailureReason = "unreadable-records" | "keying-precondition" | "anchor-unreachable";
export type VerificationFailure = "proof-invalid" | "record-set-mismatch" | "mechanism-verification-unavailable";

/** What the deployment supplies at the seam (Capability requirement 3, 4, 5, 7 to 9). */
export interface Mechanism {
  /** A mechanism that computes the proof from no keying material (Term unkeyed mechanism). */
  unkeyed: boolean;
  /** The proof over the record set the reference names, or the reason it cannot be computed (Operation 9). */
  compute(recordSet: unknown, credential: string): Promise<{ proof: string; anchored_at?: string } | { failure: MechanismFailureReason }>;
  /** The mechanism's verification function over the presented record set and the recorded proof. */
  check(proof: string, original: unknown, credential?: string): Promise<"held" | "failed" | "unavailable">;
  /** Is the presented original record set the one the reference names (Term record set match; Operation 22b). */
  match(recordSetRef: string, original: unknown): boolean;
}

export interface EvidenceView {
  evidence_id: string;
  record_set_ref: string;
  proof: string;
  sealed_at: string;
  anchored_at: string | null;
}

type Stored = Row & { _id: string; record_set_ref: string; proof: string; sealed_at: string; anchored_at: string | null };

const T = "evidence";
const COLUMNS = ["record_set_ref", "proof", "sealed_at", "anchored_at"];
const STRING_CAP = 4096; // Term string cap: code points, where a deployment declares none

const chain = (records: unknown[], hash: (s: string) => string): string => {
  let h = "";
  for (const r of records) h = hash(h + canonical(r));
  return h;
};

/** An unkeyed hash chain: each record's hash covers the one before and the record (Term unkeyed mechanism). */
export const sha256Chain = (match: Mechanism["match"]): Mechanism => ({
  unkeyed: true,
  match,
  compute: async (rs) => (Array.isArray(rs) ? { proof: chain(rs, (s) => createHash("sha256").update(s).digest("hex")) } : { failure: "unreadable-records" }),
  check: async (proof, original) => (Array.isArray(original) && chain(original, (s) => createHash("sha256").update(s).digest("hex")) === proof ? "held" : "failed"),
});

/** The same chain keyed: HMAC-SHA-256 under the mechanism credential, so a proof cannot be made without the key. */
export const hmacChain = (match: Mechanism["match"]): Mechanism => ({
  unkeyed: false,
  match,
  compute: async (rs, key) => (isBlank(key) ? { failure: "keying-precondition" } : Array.isArray(rs) ? { proof: chain(rs, (s) => createHmac("sha256", key).update(s).digest("hex")) } : { failure: "unreadable-records" }),
  check: async (proof, original, key) => (isBlank(key) ? "unavailable" : Array.isArray(original) && chain(original, (s) => createHmac("sha256", key!).update(s).digest("hex")) === proof ? "held" : "failed"),
});

export class TamperEvidence {
  private constructor(private store: Store, private seam: Seam, private mech: Mechanism) {}

  static async open(store: Store, seam: Seam, mechanism: Mechanism): Promise<TamperEvidence> {
    await store.declare(T, COLUMNS);
    return new TamperEvidence(store, seam, mechanism);
  }

  async seal(record_set_ref: string, mechanism_credential: string, recordSet: unknown): Promise<{ evidence_id: string } | { refused: "invalid-request" | "storage-failure" } | { mechanism_failure: MechanismFailureReason }> {
    if (isBlank(record_set_ref)) return { refused: "invalid-request" };                                       // Operation 6
    if (isBlank(mechanism_credential) && !this.mech.unkeyed) return { refused: "invalid-request" };           // Operation 7; Operation 8: a blank credential is fine for an unkeyed mechanism
    if ([...record_set_ref].length > STRING_CAP || [...(mechanism_credential ?? "")].length > STRING_CAP) return { refused: "invalid-request" }; // Operation 34
    const made = await this.mech.compute(recordSet, mechanism_credential ?? "");                              // Operation 1, 5
    if ("failure" in made) return { mechanism_failure: made.failure };                                        // Operation 9
    const id = this.seam.idMaterial();                                                                        // Identity 2
    try {
      await this.store.commit([
        this.store.assertNone(T, "_id = $1", [id], "id-held"),                                                // Invariant 6.1
        this.store.put(T, { _id: id, record_set_ref, proof: made.proof, sealed_at: this.seam.now(), anchored_at: made.anchored_at ?? null }), // Operation 2, 3, 4; State 5: the credential is not stored
      ]);
    } catch {
      return { refused: "storage-failure" };                                                                  // Operation 10, 11: the proof is dropped with the call
    }
    return { evidence_id: id };
  }

  async verify(evidence_id: string, original: unknown, mechanism_credential?: string): Promise<"verified" | { failed: VerificationFailure } | "not-known"> {
    const e = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [evidence_id ?? ""]))[0];
    if (!e) return "not-known";                                                                               // Operation 15
    if (!this.mech.match(e.record_set_ref, original)) return { failed: "record-set-mismatch" };               // Operation 16
    const check = await this.mech.check(e.proof, original, mechanism_credential);                             // Invariant 4.1: the verification set alone
    if (check === "unavailable") return { failed: "mechanism-verification-unavailable" };                     // Operation 17
    if (check === "failed") return { failed: "proof-invalid" };                                               // Operation 18
    return "verified";                                                                                        // Operation 19, 33
  }

  /** Every evidence with every field it carries (Operation 27, 28); the credential is never one (State 5). */
  async read(): Promise<EvidenceView[]> {
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T}`);
    return rows
      .sort((a, b) => (a.sealed_at < b.sealed_at ? -1 : a.sealed_at > b.sealed_at ? 1 : a._id < b._id ? -1 : 1))
      .map((e) => ({ evidence_id: e._id, record_set_ref: e.record_set_ref, proof: e.proof, sealed_at: e.sealed_at, anchored_at: e.anchored_at }));
  }
}

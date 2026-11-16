// Actor Identity — who authorized this action, and can you prove it?
// Rendered from atoms/actor-identity.md (the page at the commit the entry names), with no code of any
// other render opened. A rule's label is in the comment where the code answers it.
//
// An attestation is one record under its attestation id, written once and never again (Invariant 1.1,
// State 5, 6). The deployment supplies at the seam the actor registry's answer for an actor reference
// (Capability requirement 3) and the cryptographic mechanism (Capability requirement 4): the proof, the
// credential check and the proof check. The atom stores no credential (State 4) and no public material
// (State 7). The mechanism given here is Ed25519: the credential is the actor's private key, the public
// material the matching public key, the proof a signature over the canonical action and actor references.
import { createPrivateKey, createPublicKey, sign, verify as cryptoVerify } from "node:crypto";
import { Store, type Row, type Stmt } from "./store.ts";
import { type Seam, isBlank } from "./seam.ts";
import { canonical } from "./canonical.ts";

/** What the actor registry gives for an actor reference (Term registry answer). */
export type RegistryAnswer =
  | { answer: "material"; current: string; historical?: string[] }   // public material in force now, and any the registry keeps from before
  | { answer: "unknown-actor" }
  | { answer: "unreachable" };
export type Registry = (actor_ref: string) => Promise<RegistryAnswer> | RegistryAnswer;

export type Check = "held" | "failed" | "unavailable";
/** The deployment's credential mechanism (Term cryptographic material). */
export interface Mechanism {
  /** The supplied credential run against the current material (Term credential check). */
  credentialCheck(credential: string, currentMaterial: string): Check;
  /** The proof over the action and actor references, computed from the credential. */
  prove(action_ref: string, actor_ref: string, credential: string): string | null;
  /** The recorded proof run against the recorded references under the material (Term proof check): held under any one material given. */
  proofCheck(proof: string, action_ref: string, actor_ref: string, materials: string[]): Check;
  /** Does a revocation status name the credential revoked (Term revocation status)? Absent: none does. */
  revoked?(actor_ref: string, currentMaterial: string): boolean;
}

export type AttestRefusal = "invalid-request" | "registry-unavailable" | "mechanism-unavailable" | "invalid-credential" | "storage-failure";
export type VerificationFailure = "proof-invalid" | "actor-unknown-in-registry" | "registry-unavailable" | "mechanism-unavailable";

export interface AttestationView {
  attestation_id: string;
  action_ref: string;
  actor_ref: string;
  proof: string;
  attested_at: string;
}

type Stored = Row & { _id: string; action_ref: string; actor_ref: string; proof: string; attested_at: string };

const T = "attestations";
const COLUMNS = ["action_ref", "actor_ref", "proof", "attested_at"];
const STRING_CAP = 4096; // Term string cap: code points, where a deployment declares none

const signedBytes = (action_ref: string, actor_ref: string) => Buffer.from(canonical({ action_ref, actor_ref }));

/** Ed25519: the credential is the private key as base64 PKCS8, the material the public key as base64 SPKI. */
export const ed25519: Mechanism = {
  credentialCheck(credential, currentMaterial) {
    try {
      const pub = createPublicKey(createPrivateKey({ key: Buffer.from(credential, "base64"), format: "der", type: "pkcs8" }));
      return pub.export({ format: "der", type: "spki" }).toString("base64") === currentMaterial ? "held" : "failed";
    } catch { return "failed"; }
  },
  prove(action_ref, actor_ref, credential) {
    try {
      const key = createPrivateKey({ key: Buffer.from(credential, "base64"), format: "der", type: "pkcs8" });
      return sign(null, signedBytes(action_ref, actor_ref), key).toString("base64");
    } catch { return null; }
  },
  proofCheck(proof, action_ref, actor_ref, materials) {
    for (const m of materials) {
      try {
        const key = createPublicKey({ key: Buffer.from(m, "base64"), format: "der", type: "spki" });
        if (cryptoVerify(null, signedBytes(action_ref, actor_ref), key, Buffer.from(proof, "base64"))) return "held";
      } catch { /* this material does not read; try the next */ }
    }
    return "failed";
  },
};

export interface AttestPlan { attestation_id: string; stmts: Stmt[] }

export class ActorIdentity {
  private constructor(private store: Store, private seam: Seam, private registry: Registry, private mech: Mechanism) {}

  static async open(store: Store, seam: Seam, registry: Registry, mechanism: Mechanism = ed25519): Promise<ActorIdentity> {
    await store.declare(T, COLUMNS);
    return new ActorIdentity(store, seam, registry, mechanism);
  }

  /**
   * The statements that record one attestation, to commit alone (`attest`) or beside the other writes of
   * one action (Database 1), or the refusal. Where two refusals hold at once the one listed first on
   * [Attest]'s refuses line answers (Execution Contract Refusal 1): invalid-request, registry-unavailable,
   * mechanism-unavailable, invalid-credential.
   */
  async plan(action_ref: string, actor_ref: string, credential: string): Promise<AttestPlan | { refused: AttestRefusal }> {
    if (isBlank(action_ref) || isBlank(actor_ref) || isBlank(credential)) return { refused: "invalid-request" };         // Operation 6 to 8
    if ([action_ref, actor_ref, credential].some((s) => [...s].length > STRING_CAP)) return { refused: "invalid-request" }; // Operation 37
    const reg = await this.registry(actor_ref);
    if (reg.answer === "unreachable") return { refused: "registry-unavailable" };                                        // Operation 33
    if (reg.answer === "unknown-actor") return { refused: "invalid-credential" };                                        // Operation 31
    const check = this.mech.credentialCheck(credential, reg.current);
    if (check === "unavailable") return { refused: "mechanism-unavailable" };                                            // Operation 40
    if (check === "failed") return { refused: "invalid-credential" };                                                    // Operation 9
    if (this.mech.revoked?.(actor_ref, reg.current)) return { refused: "invalid-credential" };                           // Operation 36
    const proof = this.mech.prove(action_ref, actor_ref, credential);                                                    // Operation 1, 5; Operation 13: only the references are read
    if (proof === null) return { refused: "mechanism-unavailable" };
    const id = this.seam.idMaterial();                                                                                   // Identity 2
    return {
      attestation_id: id,
      stmts: [
        this.store.assertNone(T, "_id = $1", [id], "id-held"),                                                           // Invariant 5.1
        this.store.put(T, { _id: id, action_ref, actor_ref, proof, attested_at: this.seam.now() }),                      // Operation 2, 3, 38, 39; State 3, 4
      ],
    };
  }

  async attest(action_ref: string, actor_ref: string, credential: string): Promise<{ attestation_id: string } | { refused: AttestRefusal }> {
    const p = await this.plan(action_ref, actor_ref, credential);
    if ("refused" in p) return p;
    try {
      await this.store.commit(p.stmts);
    } catch {
      return { refused: "storage-failure" };                                                                             // Operation 10
    }
    return { attestation_id: p.attestation_id };                                                                         // Operation 4
  }

  async verify(attestation_id: string): Promise<"verified" | { failed: VerificationFailure } | "not-known"> {
    const a = (await this.store.read<Stored>(`SELECT * FROM ${T} WHERE _id = $1`, [attestation_id ?? ""]))[0];
    if (!a) return "not-known";                                                                                          // Operation 15
    const reg = await this.registry(a.actor_ref);
    if (reg.answer === "unknown-actor") return { failed: "actor-unknown-in-registry" };                                  // Operation 16
    if (reg.answer === "unreachable") return { failed: "registry-unavailable" };                                         // Operation 17
    const materials = [reg.current, ...(reg.historical ?? [])];                                                          // Operation 21, Term proof check: any one material
    let check = this.mech.proofCheck(a.proof, a.action_ref, a.actor_ref, materials);
    if (check !== "unavailable" && this.mech.revoked?.(a.actor_ref, reg.current)) check = "failed";                      // a revocation status names the credential revoked
    if (check === "failed") return { failed: "proof-invalid" };                                                          // Operation 18: failed, then unavailable, then held
    if (check === "unavailable") return { failed: "mechanism-unavailable" };                                             // Operation 41
    return "verified";                                                                                                   // Operation 19, 32
  }

  /** Every attestation with its stored fields (Operation 27, 28); never the credential (State 4). */
  async read(): Promise<AttestationView[]> {
    const rows = await this.store.read<Stored>(`SELECT * FROM ${T}`);
    return rows
      .sort((a, b) => (a.attested_at < b.attested_at ? -1 : a.attested_at > b.attested_at ? 1 : a._id < b._id ? -1 : 1))
      .map((a) => ({ attestation_id: a._id, action_ref: a.action_ref, actor_ref: a.actor_ref, proof: a.proof, attested_at: a.attested_at }));
  }
}

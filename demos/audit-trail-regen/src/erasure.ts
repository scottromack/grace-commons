// A shredding-class erasure mechanism over the vault: it destroys the keys the
// data field and the proof were stored under, and rewrites no stored field
// (erasure mechanism 1 through 8).
import type { Vault } from "./vault.ts";
import type { Faults } from "./faults.ts";
import type { ErasureMechanism } from "./composition.ts";

export function shredder(v: Vault, f: Faults): ErasureMechanism {
  return {
    destroy(event_id, attestation_id) {
      if (f.hit("erasure.fail", event_id)) return { outcome: "destruction-failed", reason: "key-store-unreachable" };
      v.shred(`ev:${event_id}`);
      v.shred(`att:${attestation_id}`);
      return { outcome: "destroyed" };
    },
  };
}

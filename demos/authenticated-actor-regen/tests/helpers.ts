import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { Sections } from "../src/host.ts";
import { actorIdentity } from "../src/atoms.ts";
import { AuthenticatedActor, type Config } from "../src/composition.ts";

export const CONFIG: Config = {
  attestSurfaceSeparation: "enforced", gatingCredentialTypeDefault: "fido2",
  registrationCompletionBoundMs: 30_000, attestCompletionBoundMs: 10_000,
  reconciliationCadenceMs: 300_000, clockOffsetAllowanceMs: 2_000,
};

export function world(config: Partial<Config> = CONFIG) {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  const sections = new Sections(seam);
  // The actor registry is provisioned outside the composition (Composes 8).
  actorIdentity.register(db, "actor_smith", "smith-signing-key");
  actorIdentity.register(db, "actor_jones", "jones-signing-key");
  const { instance: aa, report } = AuthenticatedActor.start(db, seam, f, sections, config);
  return { db, seam, f, sections, aa, report };
}

export function smith(w: ReturnType<typeof world>) {
  const r = w.aa.register("dev_smith", "actor_smith", "smith-fido2");
  if (!("ok" in r)) throw new Error(JSON.stringify(r));
  return r.ok;
}

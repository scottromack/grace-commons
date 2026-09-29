import { openLog } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { type Config, UndoHistory } from "../src/composition.ts";

// The two atoms' defaults: Event Log's 64 kilobytes, Personal Todo's 1024 codepoints.
export const CONFIG: Config = { payloadCap: 65_536, descriptionCap: 1024 };

export function world(config: Config = CONFIG) {
  const log = openLog();
  const seam = manualSeam();
  const f = new Faults();
  const tick = () => seam.advance(60_000);
  return { log, seam, f, tick, uh: UndoHistory.start(log, seam, f, config) };
}

export function ok<T>(r: { ok: T } | { refused: unknown }): T {
  if (!("ok" in r)) throw new Error(JSON.stringify(r));
  return r.ok;
}

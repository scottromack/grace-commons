import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { permissions } from "../src/atoms.ts";
import { type Scope, SharedTodo } from "../src/composition.ts";

// The sprint board: the manager holds view, assign, delete and recall; developers add, edit, complete and view.
export const GRANTS: Record<string, Scope[]> = {
  manager: ["tasks:view", "tasks:assign", "tasks:delete", "tasks:recall"],
  alice: ["tasks:add", "tasks:edit", "tasks:complete", "tasks:view"],
  bob: ["tasks:add", "tasks:edit", "tasks:complete", "tasks:view"],
  carol: ["tasks:add", "tasks:edit", "tasks:complete"],
};

export function world() {
  const db = openStore();
  const seam = manualSeam();
  const f = new Faults();
  const grants: Record<string, string> = {};
  // Grants are administered by the deployment, never through the composition (Non-goal 11; Composition note 4).
  for (const [who, scopes] of Object.entries(GRANTS)) {
    for (const s of scopes) grants[`${who} ${s}`] = (permissions.grant(db, seam, who, s) as { ok: string }).ok;
  }
  return { db, seam, f, grants, st: new SharedTodo(db, seam, f) };
}

export function ok<T>(r: { ok: T } | { refused: unknown }): T {
  if (!("ok" in r)) throw new Error(JSON.stringify(r));
  return r.ok;
}

// The host's seam: the clock, every id, and the parameters digest (Composition
// state 9, 10). Nothing inside a transition reads a clock, mints an id or hashes.
import { createHash } from "node:crypto";
export interface Seam { now(): string; id(kind: string): string; digest(params: unknown): string }
export function manualSeam(start = Date.UTC(2026, 8, 28)): Seam & { advance(ms: number): void } {
  let t = start;
  const n: Record<string, number> = {};
  return {
    now: () => new Date(t).toISOString(),
    id: (kind) => `${kind}-${String(n[kind] = (n[kind] ?? 0) + 1).padStart(3, "0")}`,
    digest: (params) => createHash("sha256").update(JSON.stringify(params)).digest("hex"),
    advance: (ms) => { t += ms; },
  };
}

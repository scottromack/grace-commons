// The host's seam: the clock and every id. Nothing inside a transition reads a
// clock or mints an id; each constituent reads the clock once per call.
export interface Seam {
  now(): string;
  id(kind: "task" | "assignment" | "grant"): string;
}

export function manualSeam(start = Date.UTC(2026, 8, 29)): Seam & { advance(ms: number): void } {
  let t = start;
  const n: Record<string, number> = {};
  return {
    now: () => new Date(t).toISOString(),
    id: (kind) => `${kind}-${String(n[kind] = (n[kind] ?? 0) + 1).padStart(3, "0")}`,
    advance: (ms) => { t += ms; },
  };
}

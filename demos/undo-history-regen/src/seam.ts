// The host's seam: the clock and every id. The host supplies a new unit's id
// (Term seam; Action wiring 8, 9) and Event Log's event id and recording
// instant at the log's own seam (Event schema 2).
export interface Seam {
  now(): string;
  id(kind: "task" | "event"): string;
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

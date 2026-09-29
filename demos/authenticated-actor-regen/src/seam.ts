// The host's seam: the clock and every id. Nothing inside a transition reads a
// clock or mints an id. One clock serves the composition's seam and both
// constituents', each reading it once per call; the three are never claimed
// equal (Capability requirement 10).
export interface Seam {
  now(): string;
  id(kind: "credential" | "attestation"): string;
}

export function manualSeam(start = Date.UTC(2026, 8, 29)): Seam & { advance(ms: number): void; ms(): number } {
  let t = start;
  const n: Record<string, number> = {};
  return {
    now: () => new Date(t).toISOString(),
    ms: () => t,
    id: (kind) => `${kind}-${String(n[kind] = (n[kind] ?? 0) + 1).padStart(3, "0")}`,
    advance: (ms) => { t += ms; },
  };
}

// The host's seam: the clock and every id. Nothing inside a transition reads a
// clock or mints an id (Capability requirement 19 and 20; execution-contract.md,
// the section titled Logic Confinement Principle). One clock serves every
// constituent's own seam, each reading it once per call.
export interface Seam {
  now(): string;
  id(kind: "chain" | "invocation" | "step" | "assignment" | "event" | "attestation" | "retention" | "grant"): string;
}

export function manualSeam(start = Date.UTC(2026, 8, 26)): Seam & { advance(ms: number): void; at(): number } {
  let t = start;
  const n: Record<string, number> = {};
  return {
    now: () => new Date(t).toISOString(),
    id: (kind) => `${kind}-${String(n[kind] = (n[kind] ?? 0) + 1).padStart(3, "0")}`,
    advance: (ms) => { t += ms; },
    at: () => t,
  };
}

// The host's seam: the clock, the id material and the entropy a derivation
// function consumes. Nothing inside a transition reads a clock, mints an id or
// draws entropy (Execution Contract Logic confinement 1, 3). A test sets the
// reading a call takes, which is how two calls come to hold two readings.
export interface Seam {
  now(): string;       // one reading per call (Capability requirement 1)
  id(): string;        // id material (Capability requirement 2; Identity 13, 14)
  entropy(): Uint8Array; // a salt for a derivation function that takes one (Capability requirement 24)
  ms(): number;        // the host's own clock, for the section's lease
}

export function manualSeam(start = Date.UTC(2026, 3, 1)) {
  let t = start, n = 0, e = 0;
  return {
    now: () => new Date(t).toISOString(),
    id: () => `cred_${String(++n).padStart(3, "0")}`,
    entropy: () => { const b = new Uint8Array(16); b[0] = ++e; return b; },
    ms: () => t,
    set: (iso: string) => { t = Date.parse(iso); },
    advance: (ms: number) => { t += ms; },
  };
}
export type ManualSeam = ReturnType<typeof manualSeam>;

// The seam: the host injects the clock reading, the nonce and the handles.
// Nothing inside a transition reads a clock or mints an id (Capability
// requirement 1 through 8; Actor Identity Operation 25).
export interface Seam {
  now(): string;           // one wall-time reading per invocation
  nonce(): string;         // one nonce per issuance (Capability requirement 2)
  grantId(): string;       // Permissions' handle, minted by the host for the atom
  attestationId(): string; // Actor Identity's handle, minted by the host for the atom
}

export function counterSeam(start = Date.UTC(2026, 8, 26)): Seam {
  let t = start, n = 0, g = 0, a = 0;
  return {
    now: () => new Date(t += 1000).toISOString(),
    nonce: () => `n${++n}`,
    grantId: () => `g${++g}`,
    attestationId: () => `a${++a}`,
  };
}

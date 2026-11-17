// The seam: what the host supplies to an atom (Execution Contract, Logic Confinement Principle).
// The clock reading, the id material and the entropy come in here and are never made inside an atom.
export interface Seam {
  /** The deployment's clock reading, ISO 8601 UTC with milliseconds. */
  now(): string;
  /** Id material naming nothing yet held (Credential Capability requirement 2, 34, 35, 38). */
  idMaterial(): string;
  /** A session token's random material, at least 128 bits from a secure source (Session Capability requirement 3, 4; Identity 9). */
  sessionToken(): string;
  /** An invitation token's random material, from a cryptographically random source (Invitation Capability requirement 2, 3). */
  tokenMaterial(): string;
  /** One nonce per issuance, from a cryptographically random source (Attributed Permissions Admin Capability requirement 2). */
  nonce(): string;
}

const token = () => Buffer.from(crypto.getRandomValues(new Uint8Array(32))).toString("base64url");

export const hostSeam: Seam = {
  now: () => new Date().toISOString(),
  idMaterial: () => crypto.randomUUID(),
  sessionToken: token,
  tokenMaterial: token,
  nonce: token,
};

/** A seam whose clock a test sets and moves. */
export function testSeam(start = "2026-01-01T00:00:00.000Z"): Seam & { set(iso: string): void; advance(ms: number): void } {
  let t = Date.parse(start);
  return {
    now: () => new Date(t).toISOString(),
    idMaterial: () => crypto.randomUUID(),
    sessionToken: token,
    tokenMaterial: token,
    nonce: token,
    set: (iso) => { t = Date.parse(iso); },
    advance: (ms) => { t += ms; },
  };
}

/** A string that is absent, empty, or only White_Space code points (GRACE-lang Term blank). */
export const isBlank = (v: unknown): boolean => v === undefined || v === null || (typeof v === "string" && /^[\p{White_Space}]*$/u.test(v));

/** ISO 8601 UTC instant with a Z, normalised to milliseconds; null if the value is not one (Execution Contract Input 1). */
export function instant(v: unknown): string | null {
  if (typeof v !== "string" || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{1,3})?Z$/.test(v)) return null;
  const t = Date.parse(v);
  return Number.isNaN(t) ? null : new Date(t).toISOString();
}

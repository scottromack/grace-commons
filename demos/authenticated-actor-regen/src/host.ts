// The host's critical section, keyed by principal reference (Capability
// requirement 3 through 6). A holding's lease is exactly the holding action's
// completion bound; it ends on the holder's return, and on its expiry, which
// is how the holder's death is modelled. A lapsed holder writes nothing more
// until it takes the section again.
import type { Seam } from "./seam.ts";

export interface Holding { lapsed(): boolean; release(): void }

export class Sections {
  private held = new Map<string, { until: number; token: object }>();
  constructor(private clock: Seam & { ms(): number }) {}
  take(principal_ref: string, leaseMs: number): Holding {
    const cur = this.held.get(principal_ref);
    // Single-threaded: a live holding here would block, which no test reaches.
    if (cur && cur.until > this.clock.ms()) throw new Error(`critical section for ${principal_ref} is held`);
    const token = {};
    const until = this.clock.ms() + leaseMs;
    this.held.set(principal_ref, { until, token });
    return {
      lapsed: () => this.held.get(principal_ref)?.token !== token || this.clock.ms() >= until,
      release: () => { if (this.held.get(principal_ref)?.token === token) this.held.delete(principal_ref); },
    };
  }
}

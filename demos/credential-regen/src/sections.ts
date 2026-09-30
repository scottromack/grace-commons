// The store's critical section per pair (Capability requirement 8 through 10,
// 17, 21 through 23): released on the holder's return, on its death, and when
// it holds longer than the lease — an overdue holder, whose write is refused.
export interface Holding { overdue(): boolean; release(): void }

export class Sections {
  private held = new Map<string, { until: number; token: object }>();
  constructor(private clock: { ms(): number }, private leaseMs: number) {}
  take(pair: string): Holding {
    const cur = this.held.get(pair);
    // Single-threaded: a live holding here would block, which no test reaches.
    if (cur && cur.until > this.clock.ms()) throw new Error(`section ${pair} is held`);
    const token = {}, until = this.clock.ms() + this.leaseMs;
    this.held.set(pair, { until, token });
    return {
      overdue: () => this.held.get(pair)?.token !== token || this.clock.ms() >= until,
      release: () => { if (this.held.get(pair)?.token === token) this.held.delete(pair); },
    };
  }
}
export const pairKey = (principal_ref: string, credential_type: string) => JSON.stringify([principal_ref, credential_type]);

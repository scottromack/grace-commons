// Fault injection for the failure arms the specs name. A test arms a key with a
// count; the next matching write refuses and the count falls. A key may carry an
// action reference after a colon to aim at one audit write.
export class Faults {
  private armed = new Map<string, number>();
  arm(key: string, times = 1) { this.armed.set(key, (this.armed.get(key) ?? 0) + times); }
  clear() { this.armed.clear(); }
  hit(key: string, qualifier?: string): boolean {
    for (const k of qualifier ? [`${key}:${qualifier}`, key] : [key]) {
      const n = this.armed.get(k) ?? 0;
      if (n > 0) { this.armed.set(k, n - 1); return true; }
    }
    return false;
  }
}

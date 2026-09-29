// Fault injection for the failure arms the specs name, and the hooks a test
// uses to put another caller's work between two of an invocation's steps. A
// test arms a key with a count; the next matching write refuses and the count
// falls. A hook runs once, at the step it names.
export class Faults {
  private armed = new Map<string, number>();
  private hooks = new Map<string, () => void>();
  arm(key: string, times = 1) { this.armed.set(key, (this.armed.get(key) ?? 0) + times); }
  hit(key: string): boolean {
    const n = this.armed.get(key) ?? 0;
    if (n > 0) { this.armed.set(key, n - 1); return true; }
    return false;
  }
  between(step: string, fn: () => void) { this.hooks.set(step, fn); }
  at(step: string) {
    const fn = this.hooks.get(step);
    if (fn) { this.hooks.delete(step); fn(); }
  }
}

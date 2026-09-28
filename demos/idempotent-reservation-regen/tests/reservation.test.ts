import { assert, assertEquals, assertThrows } from "@std/assert";
import { openStore } from "../src/store.ts";
import { manualSeam } from "../src/seam.ts";
import { Faults } from "../src/faults.ts";
import { duplicatePrevention } from "../src/atoms.ts";
import { type Config, IdempotentReservation } from "../src/composition.ts";

const MIN = 60_000, HOUR = 60 * MIN;
const CONFIG: Config = { windowMs: 10 * MIN, tokenMaxLength: 64, completionBoundMs: MIN, atomicAck: true, durationBounds: [MIN, 48 * HOUR] };
function world(over: Partial<Config> = {}) {
  const db = openStore(), seam = manualSeam(), f = new Faults();
  const ir = IdempotentReservation.start(db, seam, f, { ...CONFIG, ...over });
  const entry = (t: string) => db.prepare("SELECT * FROM token_results WHERE token = ?").get<{ result: string; recovered: number; completed_at: string | null }>(t);
  const commitments = () => ir.read().length;
  const pendingEntry = (t: string, action: string, params: unknown) =>
    db.prepare("INSERT INTO token_results VALUES (?, ?, ?, 'pending', ?, NULL, 0)").run(t, action, seam.digest(params), seam.now());
  return { db, seam, f, ir, entry, commitments, pendingEntry };
}
const room = { resource: "room_307", requester: "guest_g91", duration: 24 * HOUR };

Deno.test("the walkthrough: one hold however often it is retried, a replayed confirm, a fresh request past the window", () => {
  const w = world();
  const a = w.ir.place_hold(room.resource, room.requester, room.duration, "idem_x73a");
  assert("ok" in a);
  assertEquals(w.ir.place_hold(room.resource, room.requester, room.duration, "idem_x73a"), a);
  assertEquals(w.ir.place_hold(room.resource, room.requester, room.duration, "idem_x73a"), a);
  assertEquals(w.commitments(), 1, "Invariant 8.2");
  assertEquals(w.ir.confirm(a.ok, "idem_y22"), { ok: "ok" });
  assertEquals(w.ir.confirm(a.ok, "idem_y22"), { ok: "ok" }, "the replay hides the terminal-absorption rejection");
  w.seam.advance(11 * MIN);
  assertEquals(w.ir.place_hold(room.resource, room.requester, room.duration, "idem_x73a"), { refused: "resource-unavailable" }, "Invariant 7.2");
  assertEquals(w.commitments(), 1);
});

Deno.test("a rejection is cached against its token", () => {
  const w = world(), a = w.ir.place_hold("bed_1", "p1", HOUR, "t1") as { ok: string };
  assertEquals(w.ir.place_hold("bed_1", "p2", HOUR, "t2"), { refused: "resource-unavailable" });
  w.ir.release(a.ok, "t3");
  assertEquals(w.ir.place_hold("bed_1", "p2", HOUR, "t2"), { refused: "resource-unavailable" }, "Wiring decision 2");
  assert("ok" in w.ir.place_hold("bed_1", "p2", HOUR, "t4"));
});

Deno.test("a token binds one action and one digest", () => {
  const w = world(), a = w.ir.place_hold("r", "q", HOUR, "t") as { ok: string };
  assertEquals(w.ir.confirm(a.ok, "t"), { refused: "token-collision" });
  assertEquals(w.ir.place_hold("r", "q", 2 * HOUR, "t"), { refused: "token-collision" });
});

Deno.test("a pending entry binds its action too: a confirm under a place_hold token collides", () => {
  const w = world();
  w.f.arm("map.result:t", 3);
  const r = w.ir.place_hold("r", "q", HOUR, "t");
  assertEquals((r as { position: string }).position, "outcome");
  const id = ((r as { answer: { ok: string } }).answer).ok;
  assertEquals(w.ir.confirm(id, "t"), { refused: "token-collision" }, "Invariant 4.1 over a pending entry");
  assertEquals(w.ir.read()[0].state, "held");
});

Deno.test("a pending place_hold names its candidates, records the guard, and replays", () => {
  const w = world();
  w.f.arm("map.result:t", 3);
  const r = w.ir.place_hold("r", "q", HOUR, "t") as { answer: { ok: string } };
  const again = w.ir.place_hold("r", "q", HOUR, "t");
  assertEquals(again, { refused: "outcome-unknown", candidates: [r.answer.ok] });
  assertEquals(w.entry("t")!.recovered, 1, "Indeterminate outcome 8");
  assertEquals(duplicatePrevention.check(w.db, w.seam, w.f, "t", CONFIG.windowMs), "seen", "the re-entry records the guard");
  assertEquals(w.ir.place_hold("r", "q", HOUR, "t"), again);
  assertEquals(w.commitments(), 1);
});

Deno.test("a pending place_hold with no candidates proceeds as never delegated", () => {
  const w = world();
  w.pendingEntry("t", "place_hold", { resource: "r", requester: "q", duration: HOUR });
  const r = w.ir.place_hold("r", "q", HOUR, "t");
  assert("ok" in r);
  assertEquals(w.entry("t")!.recovered, 1);
  assertEquals(w.commitments(), 1);
});

Deno.test("a resolving action runs again, pending or seen with no entry", () => {
  const w = world(), a = w.ir.place_hold("r", "q", HOUR, "t0") as { ok: string };
  w.pendingEntry("t1", "confirm", { id: a.ok });
  assertEquals(w.ir.confirm(a.ok, "t1"), { ok: "ok" });
  assertEquals(w.entry("t1")!.recovered, 1);
  duplicatePrevention.record(w.db, w.seam, "t2");
  assertEquals(w.ir.confirm(a.ok, "t2"), { refused: "not-held" }, "re-run: effect-free by Provisional Commitment Invariant 2");
  assertEquals(w.entry("t2")!.recovered, 1);
  assertEquals(w.ir.confirm(a.ok, "t2"), { refused: "not-held" });
});

Deno.test("a seen place_hold token with no entry answers outcome-unknown and records nothing", () => {
  const w = world();
  w.ir.place_hold("r", "q", HOUR, "other");
  duplicatePrevention.record(w.db, w.seam, "t");
  assertEquals(w.ir.place_hold("r", "q", HOUR, "t"), { refused: "outcome-unknown", candidates: ["hold-001"] });
  assertEquals(w.entry("t"), undefined, "Wiring decision 4");
});

Deno.test("an unavailable guard fails closed", () => {
  const w = world();
  w.f.arm("dp.check:t");
  assertEquals(w.ir.place_hold("r", "q", HOUR, "t"), { refused: "outcome-unknown", candidates: [] });
  assertEquals(w.commitments(), 0);
  assert("ok" in w.ir.place_hold("r", "q", HOUR, "t"), "decided afresh once check can answer");
});

Deno.test("boundary: a blank or overlong token commits nothing", () => {
  const w = world();
  assertEquals(w.ir.place_hold("r", "q", HOUR, " "), { refused: "invalid-request" });
  assertEquals(w.ir.place_hold("r", "q", HOUR, "x".repeat(65)), { refused: "invalid-request" });
  assertEquals(w.db.prepare("SELECT COUNT(*) AS n FROM token_results").get<{ n: number }>()!.n, 0);
  assertEquals(w.ir.place_hold("r", "q", 5, "t"), { refused: "invalid-request" }, "a constituent rejection is cached");
  assert(w.entry("t")!.completed_at);
});

Deno.test("a failed pending write answers recording-failure at the intent", () => {
  const w = world();
  w.f.arm("map.pending:t");
  assertEquals(w.ir.place_hold("r", "q", HOUR, "t"), { refused: "recording-failure", position: "intent" });
  assertEquals(w.commitments(), 0);
});

Deno.test("without atomic acknowledgement a storage failure is cached as outcome-unknown", () => {
  const w = world({ atomicAck: false });
  w.f.arm("pc.write:r");
  assertEquals(w.ir.place_hold("r", "q", HOUR, "t"), { refused: "outcome-unknown", candidates: [] });
  const x = world();
  x.f.arm("pc.write:r");
  assertEquals(x.ir.place_hold("r", "q", HOUR, "t"), { refused: "storage-failure" });
  const id = (w.ir.place_hold("r2", "q", HOUR, "t2") as { ok: string }).ok;
  w.f.arm(`pc.write:${id}`);
  assertEquals(w.ir.confirm(id, "t3"), { refused: "outcome-unknown", candidates: [id] }, "Indeterminate outcome 14");
});

Deno.test("the eviction leg: past the window and unguarded, pending or complete; never younger, guarded or held", () => {
  const w = world();
  w.ir.place_hold("r1", "q", HOUR, "done");
  w.pendingEntry("dead", "place_hold", { resource: "r2", requester: "q", duration: HOUR });
  assertEquals(w.ir.evict(), [], "the guard and the window both still stand");
  w.seam.advance(11 * MIN);
  w.ir.holdSection("done");
  assertEquals(w.ir.evict(), ["dead"], "Housekeeping 2 skips a held token");
  w.ir.releaseSection("done");
  assertEquals(w.ir.evict(), ["done"]);
});

Deno.test("instance start refuses a window that does not exceed the completion bound", () => {
  assertThrows(() => world({ completionBoundMs: 10 * MIN }), Error, "does not exceed");
});

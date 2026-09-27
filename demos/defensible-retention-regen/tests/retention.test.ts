import { assert, assertEquals, assertThrows } from "@std/assert";
import { BOUND, config, DAY, world } from "./helpers.ts";
import { retentionWindow } from "../src/audit_atoms.ts";

const PAST = 31 * DAY;

Deno.test("the gate fires under a hold, records its firing, and passes once the hold is released", () => {
  const w = world(), id = w.place(), h = w.hold();
  w.seam.advance(PAST);
  assertEquals(w.purge(id), { refused: "under-legal-hold", hold_ids: [h], count: 1 });
  assertEquals(w.trailOf("purge_blocked_by_hold").length, 1, "Invariant 4.3: the firing is a record");
  assertEquals(w.trailOf("purge_intended").length, 0, "Invariant 5.4: a gate record follows no intent");
  assertEquals(w.retention(id).state, "retained");
  assertEquals(w.dr.release_hold(h, "counsel", "counsel_secret", "matter closed"), { ok: "released" });
  assertEquals(w.purge(id), { ok: "ok" });
  const [out] = w.trailOf("record_purged");
  assertEquals(out.hold_check_result, { hold_ids: [], count: 0 });
  assertEquals(out.hold_override, undefined);
  assertEquals(w.retention(id).state, "purged");
  assertEquals(w.dr.indexEntry(id), undefined, "Composition state 6");
  assertEquals(w.purge(id), { refused: "not-known" }, "Action wiring 73: a re-invoked purge reads as committed");
  assertEquals(w.trailOf("hold_placed")[0].placed_by, "counsel");
});

Deno.test("a gate record that cannot land names its own position", () => {
  const w = world(), id = w.place();
  w.hold();
  w.f.arm("log.append:purge_blocked_by_hold", 3);
  assertEquals(w.purge(id), { refused: "recording-failure", position: "gate" });
  assertEquals(w.retention(id).state, "retained");
});

Deno.test("refusal precedence: a hold outranks the clock and the sibling (Invariant 1.2)", () => {
  const w = world(), id = w.place();
  assertEquals(w.purge(id), { refused: "not-eligible" });
  w.hold();
  assertEquals((w.purge(id) as { refused: string }).refused, "under-legal-hold", "the hold check runs whatever the named retention's eligibility");
  const x = world(), short = x.place("txn-2", "p_10d");
  x.place("txn-2", "p_30d");
  x.seam.advance(11 * DAY);
  assertEquals(x.purge(short), { refused: "under-active-retention" });
  x.hold("txn-2");
  assertEquals((x.purge(short) as { refused: string }).refused, "under-legal-hold");
});

Deno.test("an unreadable hold store is never zero holds", () => {
  const w = world(), id = w.place();
  w.seam.advance(PAST);
  w.f.arm("hold.read:txn-1", 2);
  assertEquals(w.dr.purge_eligible()[0].hold_count, "unavailable");
  assertEquals(w.purge(id), { refused: "hold-check-unavailable" });
  assertEquals(w.retention(id).state, "retained");
});

Deno.test("advisory mode destroys past a hold, marks the override, and leaves the hold standing", () => {
  const w = world({ holdCheckMode: "advisory" }), id = w.place(), h = w.hold();
  w.seam.advance(PAST);
  assertEquals(w.purge(id), { ok: "ok" });
  const [out] = w.trailOf("record_purged");
  assertEquals([out.hold_override, out.hold_check_result], [true, { hold_ids: [h], count: 1 }]);
  assertEquals(w.trailOf("purge_blocked_by_hold").length, 0);
  assertEquals(w.db.prepare("SELECT state FROM hold").get<{ state: string }>()!.state, "active", "Wiring decision 6");
});

Deno.test("siblings travel with the destruction; a failed sibling stands pending and the sweep finishes it", () => {
  const w = world(), a = w.place("txn-3", "p_10d"), b = w.place("txn-3", "p_30d");
  w.seam.advance(PAST);
  w.f.arm(`retention.purge:${b}`);
  assertEquals(w.purge(a), { ok: "ok" });
  assertEquals(w.trailOf("record_purged")[0].purged_retention_ids, [{ retention_id: b, disposition: "pending" }]);
  assertEquals(w.retention(b).state, "retained");
  w.dr.sweep();
  assertEquals(w.retention(b).state, "purged", "Reconciliation 19");
  assertEquals(w.trailOf("retention.recovery_intended").length, 1, "Reconciliation 18");
  assertEquals(w.dr.purge_eligible(), []);
});

Deno.test("boundary: blanks, a malformed instant and a bad credential commit nothing", () => {
  const w = world(), n = () => w.dr.events().length, before = n();
  assertEquals(w.dr.place_hold("txn-1", "counsel", "counsel_secret", " "), { refused: "invalid-request" });
  assertEquals(w.dr.place_hold("txn-1", "counsel", "counsel_secret", "r", undefined, "yesterday"), { refused: "invalid-request" });
  assertEquals(w.dr.place_record_under_retention("txn-1", "p_30d", "clerk", "wrong"), { refused: "invalid-credential" });
  assertEquals(w.dr.place_record_under_retention("x".repeat(300), "p_30d", "clerk", "clerk_secret"), { refused: "invalid-request" });
  assertEquals(n(), before);
  assertEquals(w.db.prepare("SELECT COUNT(*) AS n FROM retention").get<{ n: number }>()!.n, 0);
  const h = w.hold();
  assertEquals(w.dr.release_hold("hold-999", "counsel", "counsel_secret", "r"), { refused: "not-known" });
  w.dr.release_hold(h, "counsel", "counsel_secret", "done");
  assertEquals(w.dr.release_hold(h, "counsel", "counsel_secret", "done"), { refused: "already-released" });
});

Deno.test("purge eligible: elapsed only, ordered by deadline, with hold counts", () => {
  const w = world(), a = w.place("txn-a", "p_30d"), b = w.place("txn-b", "p_10d");
  w.place("txn-c", "p_30d");
  w.seam.advance(11 * DAY);
  assertEquals(w.dr.purge_eligible().map((t) => t.retention_id), [b]);
  w.hold("txn-a");
  w.seam.advance(20 * DAY);
  assertEquals(w.dr.purge_eligible().map((t) => [t.retention_id, t.hold_count]).slice(0, 2), [[b, 0], [a, 1]]);
});

Deno.test("an intent that cannot land commits nothing; an outcome that cannot land leaves the destruction and its owed record", () => {
  const w = world(), id = w.place();
  w.seam.advance(PAST);
  w.f.arm("log.append:purge_intended", 3);
  assertEquals(w.purge(id), { refused: "recording-failure", position: "intent" });
  assertEquals(w.retention(id).state, "retained");
  w.f.arm("log.append:record_purged", 3);
  assertEquals(w.purge(id), { refused: "recording-failure", position: "outcome" });
  assertEquals(w.retention(id).state, "purged");
  assert(w.dr.alerts.some((a) => a.kind === "owed-outcome"), "Action wiring 70");
  w.dr.sweep();
  assertEquals(w.trailOf("record_purged").length, 0, "Reconciliation 4: a young marker waits");
  w.seam.advance(BOUND + 1);
  w.dr.sweep();
  w.dr.sweep();
  const outs = w.trailOf("record_purged");
  assertEquals(outs.length, 1, "Action wiring 72: the sweep writes the owed record, once");
  assertEquals([outs[0].recovery, outs[0].hold_check_result, outs[0].acting_actor], [true, { hold_ids: [], count: 0 }, "clerk"]);
});

Deno.test("the sweep recovers a committed placement and abandons an uncommitted one, once each", () => {
  const w = world();
  w.f.arm("log.append:retention_placed", 3);
  assertEquals(w.dr.place_record_under_retention("txn-8", "p_30d", "clerk", "clerk_secret"), { refused: "recording-failure", position: "outcome" });
  w.f.arm("retention.place:txn-9");
  assertEquals(w.dr.place_record_under_retention("txn-9", "p_30d", "clerk", "clerk_secret"), { refused: "storage-failure" });
  w.seam.advance(BOUND + 1);
  w.dr.sweep();
  w.dr.sweep();
  const placed = w.trailOf("retention_placed");
  assertEquals(placed.map((p) => [p.record_ref, p.recovery]), [["txn-8", true]]);
  assertEquals(w.trailOf("intent_abandoned").length, 1, "a closed marker is not closed again");
});

Deno.test("a released hold whose outcome was lost is recovered from the hold store", () => {
  const w = world(), h = w.hold();
  w.f.arm("log.append:hold_released", 3);
  assertEquals(w.dr.release_hold(h, "counsel", "counsel_secret", "closed"), { refused: "recording-failure", position: "outcome" });
  w.seam.advance(BOUND + 1);
  w.dr.sweep();
  assertEquals(w.trailOf("hold_released").map((o) => [o.hold_id, o.reason, o.recovery]), [[h, "closed", true]]);
});

Deno.test("a lost index entry rebuilds; a direct atom purge surfaces as a bypass", () => {
  const w = world(), id = w.place(), other = w.place("txn-2");
  w.db.exec("DELETE FROM retention_to_record; DELETE FROM record_to_retentions");
  w.seam.advance(PAST);
  assertEquals(w.purge(id), { ok: "ok" }, "Action wiring 44: a miss rebuilds before not-known");
  retentionWindow.purge(w.db, w.seam, w.f, other);
  w.dr.rebuild();
  assertEquals(w.dr.alerts.filter((a) => a.kind === "bypass").map((a) => a.detail), [other], "Composition state 24");
});

Deno.test("instance start refuses a short audit horizon and a short compensation window", () => {
  assertThrows(() => world({ longestHoldMs: 380 * DAY }), Error, "evidence floor");
  assertThrows(() => world({ compensationWindowMs: 600_000 }), Error, "closure floor");
  assertThrows(() => world({ longestHoldMs: "unbounded" }), Error, "horizon alert");
  world({ longestHoldMs: "unbounded", horizonAlert: true });
  void config;
});

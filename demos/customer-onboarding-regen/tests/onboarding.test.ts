import { assert, assertEquals, assertThrows } from "@std/assert";
import { CONFIG, DAY, FIELDS, world } from "./helpers.ts";
import { partyIdentity } from "../src/atoms.ts";

Deno.test("the direct path: enrol, place, verify, and the gate opens only once verified", () => {
  const w = world(), c = w.open(), p = w.partyOf(c);
  assertEquals(w.co.activity_permitted(p), { refused: "not-verified", state: "unverified" });
  assertEquals(w.verify(c), { ok: "recorded" });
  assertEquals(w.co.activity_permitted(p), { ok: "permitted" });
  assertEquals(w.of("initiation-intended")[0].party_id, undefined, "Action wiring 9");
  const [i] = w.of("initiated"), [v] = w.of("verification-recorded");
  assert(v.state_change_id && v.next_review_due, "Action wiring 29, 30");
  assertEquals(w.co.monitoring(c)!.next_review_due, v.next_review_due);
  assert(Date.parse(String(i.next_review_due)) <= Date.parse(w.seam.now()) + CONFIG.monitoringIntervalMs!, "Clock semantics 4");
});

Deno.test("the external path: an unverified party only, once", () => {
  const w = world(), p = (partyIdentity.enroll(w.db, w.seam, w.f, FIELDS, "upstream") as { ok: string }).ok;
  const r = w.co.initiate_onboarding(p, undefined, "officer", "officer_secret", "active_1y");
  assert("ok" in r);
  assertEquals(w.co.initiate_onboarding(p, undefined, "officer", "officer_secret", "active_1y"), { refused: "already-onboarded" });
  assertEquals(w.co.initiate_onboarding("party-999", undefined, "officer", "officer_secret", "active_1y"), { refused: "party-not-known" });
  assertEquals(w.co.initiate_onboarding(p, FIELDS, "officer", "officer_secret", "active_1y"), { refused: "invalid-request" }, "Action wiring 1");
  w.verify(r.ok);
  const x = world(), q = (partyIdentity.enroll(x.db, x.seam, x.f, FIELDS, "upstream") as { ok: string }).ok;
  partyIdentity.verify(x.db, x.seam, x.f, q, "upstream", "m", "passed", "e");
  assertEquals(x.co.initiate_onboarding(q, undefined, "officer", "officer_secret", "active_1y"), { refused: "party-not-admissible", state: "verified" });
});

Deno.test("an unanswered read at initiation answers state-unavailable", () => {
  const w = world(), p = (partyIdentity.enroll(w.db, w.seam, w.f, FIELDS, "upstream") as { ok: string }).ok;
  w.f.arm(`pi.read:${p}`);
  assertEquals(w.co.initiate_onboarding(p, undefined, "officer", "officer_secret", "active_1y"), { refused: "state-unavailable" });
  assertEquals(w.of("initiation-intended").length, 0);
});

Deno.test("an adverse trigger records first, then suspends; a second finds the party suspended; a clearance empties the set", () => {
  const w = world(), c = w.open(), p = w.partyOf(c);
  w.verify(c);
  assertEquals(w.trig(c), { ok: "recorded" });
  assertEquals(w.state(p), "suspended");
  assertEquals(w.trig(c, "adverse-media", "news-7"), { ok: "recorded" });
  assertEquals(w.of("trigger-on-suspended-party").length, 1);
  assertEquals(w.co.openTriggers(c).length, 2);
  assertEquals(w.co.activity_permitted(p), { refused: "not-verified", state: "suspended" });
  assertEquals(w.co.clear_review(c, "officer", "manual-review", "ev-2", "officer", "officer_secret", "false positive"), { ok: "cleared" });
  assertEquals(w.co.openTriggers(c), [], "the healthy clearance drops every trigger it names, which is all of them");
  assertEquals(w.co.activity_permitted(p), { ok: "permitted" });
  assertEquals(w.co.clear_review(c, "officer", "m", "e", "officer", "officer_secret", "r"), { refused: "no-open-trigger" });
});

Deno.test("an adverse trigger against an unverified party is refused before anything is recorded", () => {
  const w = world(), c = w.open();
  assertEquals(w.trig(c), { refused: "not-verified", state: "unverified" });
  assertEquals(w.of("monitoring-triggered").length, 0);
});

Deno.test("a periodic trigger renews the placement and advances the schedule; a suspended party is renewed and frozen", () => {
  const w = world(), c = w.open();
  w.verify(c);
  const first = w.co.placements(c).current_placement, due = w.co.monitoring(c)!.next_review_due;
  w.seam.advance(300 * DAY);
  assertEquals(w.trig(c, "periodic-review-due", "sched-1"), { ok: "recorded" });
  assert(w.co.placements(c).current_placement !== first, "Action wiring 75");
  assert(w.co.monitoring(c)!.next_review_due > due, "Action wiring 76");
  w.trig(c);
  const frozen = w.co.monitoring(c)!.next_review_due, second = w.co.placements(c).current_placement;
  w.seam.advance(DAY);
  w.trig(c, "periodic-review-due", "sched-2");
  assert(w.co.placements(c).current_placement !== second, "Action wiring 68");
  assertEquals(w.co.monitoring(c)!.next_review_due, frozen, "Action wiring 77");
});

Deno.test("close: the floor placed, the case inactive, monitoring refused, and an earlier closure completed", () => {
  const w = world(), c = w.open(), p = w.partyOf(c);
  w.verify(c);
  assertEquals(w.co.close_party(c, "officer", "customer left", "officer_secret"), { ok: "closed" });
  assert(w.co.placements(c).post_closure_placement);
  assertEquals(w.co.activity_permitted(p), { refused: "not-verified", state: "closed" });
  assertEquals(w.trig(c), { refused: "not-active" });
  const x = world(), d = x.open(), q = x.partyOf(d);
  partyIdentity.close(x.db, x.seam, x.f, q, "officer", "an earlier invocation that died");
  x.seam.advance(DAY);
  assertEquals(x.co.close_party(d, "officer", "finishing", "officer_secret"), { ok: "closed" }, "Action wiring 117");
  assertEquals(x.of("party-closed")[0].closure_instant, new Date(Date.parse(x.seam.now()) - DAY).toISOString(), "Action wiring 118");
});

Deno.test("positions: nothing committed at the intent, a committed act at the outcome", () => {
  const w = world(), c = w.open();
  w.f.arm("log.append:customer-onboarding.verification-intended");
  assertEquals(w.verify(c), { refused: "recording-failure", position: "intent" });
  assertEquals(w.state(w.partyOf(c)), "unverified");
  w.f.arm("log.append:customer-onboarding.verification-recorded", 3);
  assertEquals(w.verify(c), { refused: "recording-failure", position: "outcome" });
  assertEquals(w.state(w.partyOf(c)), "verified");
  const x = world();
  x.f.arm("retention.place:party:party-001");
  assertEquals((x.co.initiate_onboarding(undefined, FIELDS, "officer", "officer_secret", "active_1y") as { position?: string }).position, "outcome", "Action wiring 18: the enrolment committed");
});

Deno.test("the gate fails closed on an unanswered read", () => {
  const w = world(), c = w.open(), p = w.partyOf(c);
  w.verify(c);
  w.f.arm(`pi.read:${p}`);
  assertEquals(w.co.activity_permitted(p), { refused: "state-unavailable" });
  assertEquals(w.co.activity_permitted("party-999"), { refused: "not-known" });
});

Deno.test("instance start refuses a relationship policy no longer than the renewal floor", () => {
  assertThrows(() => world({ policies: { ...CONFIG.policies, active_1y: { ref: "active_1y", durationMs: 370 * DAY, maxPurgeDelayMs: DAY } } }), Error, "renewal floor");
});

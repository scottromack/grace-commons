# CORNERS — Notification Fanout, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

Three of the four are the page describing its constituents as they stood before 2026-09-15; the constituents moved and the page did not. One is the 2026-09-14 rewrite. Each is closed in the spec (council read 250).

**1. Notification's storage-failure.** The page named its *unrecordable create* "because Notification declares no infrastructure arm". Notification now declares storage-failure on create, and its case space says the store is left untouched. So a storage-failure is a determinate, recordless refusal, and only a call that never answers is indeterminate. *Closed:* the term names the unrecordable create by what it is, and the failed list is read as three failures, not two. A test fails one create with storage-failure and one without an answer, and counts the records.

**2. The whitespace-only subscriber.** The one-subscriber-failing reading rested on Subscription admitting a whitespace-only ref that Notification refuses. Subscription now refuses it. *Closed:* the reading rests on the length cap alone, which Subscription still lacks. A test subscribes an over-long ref and finds it failing alone.

**3. A read Subscription does not declare.** Check 1.2 reconstructed the subscriber set from "Subscription's historical-state filter", and Subscription's signature has no such read. *Closed:* the check reads the subscription store's stored subscribed and cancelled instants, which an auditor given the store can read.

**4. The payload check grew in the rewrite.** The prose refused an absent payload; the rewrite refused a blank one, which includes an empty payload that Notification accepts (Notification Operation 5), and its WHY claimed a Notification refusal no Notification rule states. *Closed:* Primitive policy 2 refuses an absent payload. A test fans out an empty payload.

## Preferences

- **An unreachable subscription store** is a fault on `subscribers_for`, which declares no refusal; the composition names it at the boundary (Action wiring 4).
- **A create that never answers** is rendered twice: a timeout that recorded nothing, and a commit whose id was lost. The composition cannot tell them apart, and puts both in the failed list.
- **The payload** is serialized once and handed to every create, so every record carries one payload (Invariant 2.1).

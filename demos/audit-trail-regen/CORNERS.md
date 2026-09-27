# CORNERS — Audit Trail, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

**1. One record per finding had no read behind it.** Compensation 2 allows one `audit.reconciliation` record per finding, and the scan writes that intent before its repair. When the repair failed after the intent landed — the orphan's compensating write refused, or the unretained event's placement refused — the next run met the same finding and, with no pre-check that reads a landed intent, wrote a second one. The render did exactly that in both halves. *Closed:* the intent carries its subject and id (Compensation 9), and the scan reads *narrated* under the critical section before writing one (Compensation 10, 11). A test fails each repair once and counts one intent.

**2. The pre-check list left out the cascade's own reads.** Term *proceed as landed* names the destruction record and the erasure outcomes as the pre-checks of Purge Event steps 2 and 3; Term *pre-check*, which Per-act critical section 12 has a writer re-read, listed neither. On a lease host a re-driven cascade then had no rule keeping it from rewriting its destruction record or re-delegating a destruction already reported. *Closed:* the pre-check names the destruction record and a destroyed outcome. A test re-runs a completed purge and counts one delegation.

## Preferences

- **The critical section is an in-memory set.** The host is synchronous and every holder releases on return, so Concurrency 2's serialization holds by construction, and a held section at Purge Event is a holder that never released: the render throws. A first draft answered `cascade-failure(seal)` there; Concurrency 2 says *serialize*, not refuse. A test holds a section to show the first half skipping the act for the run (Per-act critical section 5). Lease expiry mid-invocation (Per-act critical section 9) and the death-detected host are not rendered.
- **The first half takes the event's section and re-reads its predicate before re-driving,** and runs the cascade as the holder rather than through a second take (First half 6, 7).
- **The seal mechanism is a chain:** SHA-256 over the previous seal's proof, the credential and the records. An empty credential is the unkeyed class. Keyed and anchored mechanisms are not rendered.
- **The record set match is the presentation's length against the covering range** — the host's answer at Tamper Evidence's seam (Operation 22a).
- **The interval cadence fires on its event count.** Its time arm sets only the reconciliation cadence's default (reconciliation cadence 4); no timer fires a seal.
- **An index write that fails skips all three index writes;** every read rebuilds on miss (Check 7.1).
- **A step-4 refusal leaves the event in the unsealed tail** until the next seal, since step 6 never ran.
- **Legal Hold is a predicate the deployment supplies.**
- **The beyond-horizon report adds its disposition** to the subject and id every intent carries (Second half 6).

---

## Against the portal's audit trail

The portal's drift section predicted nothing for its audit trail. The regeneration found six differences:

- **The seal lives in the record.** Each row carries its own `prev_hash` and `this_hash`, so there is no seal store to hold apart: one write reaches both, which is the adversary Tamper Evidence says it cannot stop, in the passage the portal's code quotes. The spec seals ranges into a seal store of Tamper Evidence's own. The render keeps that store in the same database, behind no-update triggers, so its separation goes no further than a deployment's grants would take it.
- **Nothing attests the actor.** The actor is a nullable column; the spec attests every action through Actor Identity and verifies the proof at read time (Record Action step 2; Verify Record step 3).
- **Retention is one setting and a display filter.** There is no retention record per event, no eligibility and no purge (Record Action step 4; Purge Eligible).
- **Nothing can be erased.** A chain over every row cannot survive a shredded row; the spec seals ranges, records the destroyed members against the covering seal, and reads the *who / what / when* through the pair afterwards (Purge Event steps 0 through 4).
- **Every write is one transaction,** so there is no orphan attestation, no unretained event and no reconciliation scan (Reconciliation).
- **Verification answers the whole chain at once,** with one divergence row, where the spec answers per record: verified, failed with a reason, or unverifiable during an outage (Verify Record).

Two hold: the proof chains each seal to the one before it, and the log is ordered by a sequence number. The portal keeps its log append-only by convention; the render enforces it with triggers.

# CORNERS — Idempotent Reservation, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All six are the 2026-09-14 rewrite losing what the prose spec before it had decided, in the re-entry arms and one knob. The rewrite's Decisions entry says nothing changed but language. Each is closed in the spec (council read 248).

**1. A pending entry did not bind its action.** Action wiring 7 and 8 checked the action type and digest of a *complete* entry only, so a confirm under a token still pending for a place hold ran under a token bound to another act. The prose checked the pending arm too. *Closed:* both rules read every entry. A test fails a place hold's result write, then confirms under its token and meets token-collision.

**2. A re-entry's result was never guarded.** Action wiring 20 orders the guard after the result and Composes 7 counts first invocations, so nothing obliged a pending place hold closed as outcome-unknown to record the guard. The prose did. *Closed:* Action wiring 25 records the guard for every result that lands. A test reads the guard after the re-entry.

**3. A resolving action on a seen token with no entry answered outcome-unknown.** Indeterminate outcome 10 applied to all four actions, where the prose re-ran a resolving action — effect-free, as Indeterminate outcome 9 already relies on for the pending arm. *Closed:* Indeterminate outcome 10 is scoped to place hold, Indeterminate outcome 13 re-runs a resolving action, and Wiring decision 4 no longer forbids recording that result. A test re-runs a confirm on a guarded token with no entry.

**4. A resolving action's candidates were undefined.** The signatures carry `outcome-unknown(candidates)` on all four actions, and the term filtered by resource and requester, which a resolving call does not carry. *Closed:* the term and Indeterminate outcome 14 name the call's commitment. A test fails a confirm's write on a store that does not acknowledge atomically.

**5. The window and the bound disagreed at equality.** Capability requirement 10 allowed a completion bound equal to the window; Capability requirement 11 refused to start on it. The prose said strictly less. *Closed:* Capability requirement 10 now reads as Capability requirement 11 does. A test starts an instance at equality and is refused.

**6. One rule conditioned on a fact the map does not carry.** Composition state 8 forbade evicting a pending entry *whose invocation returned*, and nothing in an entry tells a returned invocation from a dead one. The prose said an entry younger than the window is kept, pending or complete, which Housekeeping 5 already states. *Closed:* tombstoned to Housekeeping 5. A test evicts a pending entry past the window.

## Preferences

- **The critical section is an in-memory set.** The host is synchronous, so an invocation that finds its token held is a holder that never released: the render throws. The eviction leg skips a held token (Housekeeping 2). A section lost mid-invocation (Action wiring 6) is not rendered.
- **The result write retries three times, then yields** — the reservation completion bound stood in by a count, since the clock does not move inside one call (Action wiring 17, 18).
- **The resource registry** answers unavailable while an unexpired held or a confirmed commitment covers the resource.
- **The digest** is SHA-256 over the non-token parameters, taken at the seam.
- **An unreachable guard answers seen** (Capability requirement 16).
- **A candidate** is an unexpired held commitment; an expired hold is the resource's history.

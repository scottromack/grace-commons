# CORNERS — Undo History, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

Both are closed in the spec (council read 260). Neither is the 2026-09-14 rewrite's: the page was already in rule form, and both stood before it.

**1. A foreclosure resting on an undeclared bound.** Event schema 8 maps Event Log's invalid-payload to no caller rejection, because every payload is *built by machine from already-validated inputs* and the arm cannot be reached. The inputs are validated against Personal Todo's description cap; the arm fires on Event Log's payload cap. The deployment sets both, and an edit event carries two descriptions, so a deployment that lowers the one or raises the other reaches the arm — with nothing on the page to say it may not. *Closed:* Event schema 9, the largest event within the payload cap; the WHY says what the claim rests on. A test starts under a 512-character cap without the check, reaches invalid-payload on an edit, and finds the checked start refusing that cap.

**2. A rule the page's own mechanism breaks.** Wiring decision 5 forbade calling Personal Todo's add to restore an undone delete's unit, and the replay restores it by running the unit's own add event again — which the Composes WHY describes, *the atom only ever sees forward valid actions during replay*. What the rule meant is the Memento its WHY rejects: a fresh add, a new id, reset instants. *Closed:* the rule forbids appending an add event to restore; a WHY sentence says the replay's add is the only one a restore involves. A test undoes a delete and finds the unit at its id with its instants.

## Preferences

- **The replay runs Personal Todo's own actions** over a fresh store, with each event's unit id and recording instant injected at the atom's seam (Replay 5 through 13). A forward action validates the same way, against a fresh replay, before its append.
- **An event's descriptions are stored normalized**, as Personal Todo shows them.
- **No materialization:** every read replays (Replay 15 permits a cache; this render keeps none).
- **The largest event** is an edit carrying two descriptions at the cap, each codepoint at JSON's widest escape.
- **A replay refusal** throws: a surviving event succeeded once and cannot fail again (the Replay WHY), so a refusal is a defect, not an answer.
- **Event Log's query** is a sequence-number range; invalid-query answers a range that is not one.

# CORNERS — Customer Onboarding, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All four are closed in the specs (council read 254).

**1. A rule every healthy clearance broke.** Action wiring 106 said a clearance *MUST NOT empty the open-trigger set*, and in the healthy path the triggers a clearance names are the whole set, so dropping them empties it. The prose said *never clear the set* — never sweep it wholesale, since a trigger may land between the reinstate and its record. The 2026-09-14 rewrite made that a prohibition on the result. *Closed:* Action wiring 106 forbids dropping a trigger the review cleared record does not name. A test clears two triggers and finds the set empty.

**2. An unanswered read at initiation had no landing.** The external path reads the party (Action wiring 4) and the page answered an empty read and a closed party, but not a read that did not answer; the signature carried no state-unavailable, where the trigger and the gate both answer it. *Closed:* Action wiring 154, and the signature gains the arm. A test fails the read and finds nothing recorded.

**3. Position meant two things.** Its term said *the record a write lands*, and eleven rules use it for *whether a constituent write had committed*: a storage failure at the placement carries intent on the external path and outcome on the direct one (Action wiring 17, 18), and a trigger voided record that fails carries intent (Action wiring 62) though it is an outcome. *Closed:* the term states the meaning the rules use, with Audit arm 11 and 12. A test reads intent and outcome on the two sides of a verify's commit, and outcome for a placement failure on the direct path.

**4. Party Identity: one name, two things.** `Term verification result` was declared as *verification id and an optional state change id — what verify answers*, while the same name is the passed-or-failed input its Operation 21 checks, its value sets list and its term entry defines. *Closed:* verify's answer is `verify answer`. No rule's meaning moved, so Party Identity stays grounded.

## Preferences

- **Not rendered:** the rebuild of each index (Composition state 15 through 34), the reconciliation (Reconciliation 1 through 33), the per-case serialization (Concurrency), and field truncation (Primitive policy 18, 19).
- **The trigger's read answering no party** answers state-unavailable, as the gate does (Action wiring 140); Action wiring 41 names only an unanswered read.
- **An owed record** is retried three times inside the invocation, then left to the reconciliation (Audit arm 14 through 16).
- **A periodic trigger's next review due** is capped by the placement current when the trigger lands, before the renewal, as the trigger record carries it.
- **The trail is read** through the substrate's Event Log, open-ended from sequence one, filtered in composition code (Composes 12, 13).

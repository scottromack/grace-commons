# CORNERS — Shared Todo, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All four are closed in the spec (council read 258). The first three are the 2026-09-14 rewrite's; the fourth was in the prose too.

**1. No signatures.** The prose gave every action a projected contract — parameters, answer, refusals — and the rewrite kept the rules that gate and relay and dropped all nine. Nothing on the page said an action takes an actor reference, what reassign answers, or that [Responsible Actor] answers unassigned for a task with no active assignment and not-known for a task the store does not carry; Check 5.1 and 5.2 cited Composition state 2, which says neither. *Closed:* the nine signatures, as the prose had them, and Action wiring 20, 21; the checks cite those. A test drives all three answers, the last on a deleted task.

**2. An empty list the page forbids.** Term visible tasks said *none otherwise* for a caller without tasks:view, which reads as the empty set Action wiring 19 forbids answering. *Closed:* the term defines the tasks a caller holding tasks:view sees; the denied caller's answer is permission-denied. A test tells the two apart.

**3. A grant keyed on a task.** Invariant 5.2 said a grant record outlives *the task the grant governed*, and Check 4.2 asked an auditor for *a grant record for a task id* — but a grant carries a subject and a scope, and every scope here covers the whole list. No grant governs a task, and the check could find nothing. *Closed:* Invariant 5.2 says a task's delete changes no grant, which is what the wiring holds, and since no record shows a change that did not happen, its check is External check 5. A test deletes a task and finds the grants unchanged.

**4. A mislabelled bill.** The WHY on the single instance's cost named Non-goal 14, which is about the authenticating pattern; the rule it explains is Non-goal 15. It also said two actors cannot hold *pending* tasks with equal descriptions, where Personal Todo's active set is pending and done. *Closed:* both. A test is refused a duplicate of a done task.

## Preferences

- **Edit's refusals** land in the order not-known, not-editable, invalid-description, then the unchanged-description ok, then duplicate-active; Personal Todo states no precedence.
- **The description cap** is Personal Todo's default, 1024 codepoints.
- **A delete's recall** answering not-known or not-active cannot land while the host serializes calls naming one task id (Concurrency 1); the render throws rather than invent an answer the signature does not carry.
- **Visible tasks** answer the units with their fields, as Personal Todo's read does.
- **Not rendered:** a finer action scope (Scope vocabulary 10, 11), and the history reads an auditor makes against the stores directly (Invariant 4.2, 5.1).

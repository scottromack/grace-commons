# CORNERS — External Onboarding, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

**1. Two resume rules named two stages for one arc.** A resume that dies after its resume record lands and before the acceptance record Resume 30 writes leaves a dead resume record and no acceptance record. Resume 9 then read the stage as unrecorded and Resume 11 as acceptance-unrecorded. The arc still owes its acceptance record, which only acceptance-unrecorded writes. *Closed:* Resume 9 applies only where an acceptance record exists (council read 240). A test drives the arc through exactly that death.

## Preferences

- **The critical section is an in-memory set with a lease length and no expiry.** A test holds it to exercise Action wiring 11 and Resume 2; an invocation that loses it mid-arc (Action wiring 13 through 16) is not rendered.
- **An attempt record refused at the retention step answers storage-failure at the intent,** as Audit arm 2 says of every recording-failure at an attempt; the appended attempt stands, harmlessly, as the page's WHY says.
- **The trail is read from sequence one** for the resume arm's stage reading; the read-back runs from the invocation's own attempt record (Audit arm 9).
- **A date of birth is valid when it is a calendar date in `YYYY-MM-DD` no later than now** — the composition's reading of Party Identity's rule, run before the gate (Primitive policy 3).
- **The derivation function** is a SHA-256 stand-in for the deployment's password function.

---

## Against the portal's onboarding

The portal's drift section predicted nothing for its invitation flow. The regeneration found eight differences:

- **The party exists before the invitation is accepted.** Issuing an invitation creates the party from the inviter's email; the spec enrolls only after an accept, binding the identity the acceptor supplies (Wiring decision 1, 4).
- **Nothing authenticates the accept.** There is no attempt record and no credential check; the events are attributed to the actor the accept itself creates (Composes 14; Action wiring 1, 2).
- **The whole arc is one transaction.** A failure rolls everything back, so there is no interruption, no resume and no completion record naming the invitation, the party and the credential together (Invariant 5).
- **The composition hashes the password,** where the spec passes the material raw to Credential's register (Term credential material).
- **Refusals are thrown errors,** so expired, unknown and already-resolved reach the caller only as message text (Action wiring 17 through 19).
- **There is no decline** (Action wiring 40 through 47).
- **A revocation carries no reason** (Action wiring 48, 54).
- **The composition mints the token and reads the clock** (Capability requirement 1 through 4).

One holds: an invitation resolves once.

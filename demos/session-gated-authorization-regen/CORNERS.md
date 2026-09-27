# CORNERS — Session-Gated Authorization, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

**1. Nothing held the length bound under the Permissions string cap.** Permissions reads an over-length argument as matching nothing and answers denied (Permissions String 7). A deployment pinning the gate's bound above that cap would let a scope the boundary should refuse through to Permissions, and report a malformed request as a refusal — the collapse Primitive policy 2 through 4 exist to prevent. *Closed:* Primitive policy 10. It is a load-bearing edit on a grounded page, so the page stands `partially resolved` until the three-pass round the entry *Touch triggers re-pass* in `pressure-testing.md` requires (council read 236).

**2. Four sentences had lost their verbs.** "shows expired at the disputed instant" read "shows lapse instant the disputed instant"; "revoked at", "revoked at time T" and "revoked by the time" read the same way. The noun-final rename of 2026-09-23 turned declared names such as *expired at* into *lapse instant*, and took these ordinary verb phrases with them. *Closed:* the four restored. The same collateral stands elsewhere in the corpus; see council read 236.

## Preferences

- **The seam is a clock function and a counter,** read once per constituent call.
- **Permissions' string cap is 256** here; the gate's bound is set per test.

---

## Against the portal's gate

The portal's drift section predicted nothing for its gate. The regeneration found five differences:

- **A refused session carries no reason.** Every failure redirects to the login page, so an expired, a revoked and an unknown session read alike (Action wiring 9).
- **Malformed input is not its own class.** A missing token takes the same redirect as an invalid session (Primitive policy 2 through 4; Invariant 3).
- **The gate asks for any of several scopes** in one query, where the spec asks Permissions one pair (Action wiring 6; Non-goal 5, 6).
- **The answer is not binary.** The matched grant's own scope, `all` or `own`, travels to the handler (Action wiring 11).
- **The gate joins the grant and permission tables itself,** beside Permissions' declared surface (Composes 5).

Two hold: the principal is the session's own (Invariant 2), and every request validates afresh (Action wiring 13).

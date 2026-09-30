# CORNERS — Credential, cold regeneration

A **finding** names a contradiction or a gap inside the specs and goes to the review channel; a **preference** is a choice where the specs leave room (the section titled *Implementation-discovered findings* in `contributing.md`).

---

## Findings

All three are closed in the spec (council read 266).

**1. A salt with no source.** Final Critique 7 gave every type a check function so a salted hash could be verified. Deriving one still needs a salt, and a salt is entropy — which Execution Contract Logic confinement 3 says is injected at the seam, never drawn in a transition. The page supplied the clock and the id material there and nothing else. *Closed:* Capability requirement 24. A test registers two principals with the same password and finds two different verifiers.

**2. Cryptography inside the transition.** The page supplied the derivation registry *at* the seam, which reads as the functions being handed to the transition to call. Logic confinement 1 allows no cryptography in core. *Closed:* the host runs the derivation and check functions at the seam and the transition records what they answer (Capability requirement 25, 26; the seam term).

**3. A default the page both required and let a deployment omit.** Capability requirement 7 obliges the deployment to declare the default validity; the term said *a deployment declaring none* leaves the deadline absent. *Closed:* a deployment may declare it unbounded. Operation 20 also spoke of comparing a verifier, the language the check function replaced; it now speaks of checking presented material.

## Preferences

- **Three credential types:** `password` (scrypt, a fresh salt per derivation, carried in the verifier), `api-token` (SHA-256), `public-key` (Ed25519; the presented material is a JSON challenge and signature, the challenge the composing pattern's, Non-goal 30).
- **Revoke takes no section.** Capability requirement 8 names [Register] and [Rotate]; revoke's standing check and status change are one conditional statement (Concurrency 1), and a rotate a revoke overtakes loses at its own conditional update (Concurrency 2). A test drives it.
- **The lease runs on the host's clock**, read when the store writes, not on the call's reading.
- **The default validity** is 90 days in the tests; `null` is the unbounded declaration.

## Against Login's carried Credential

The Credential that three regenerations carried from Login derived an unsalted SHA-256 inside the transition and compared hashes for equality, which is exactly the shape Final Critique 7's finding c said cannot host a salted hash or a signature. It never met either, because Login used one password type. It also inherited the prior credential's deadline on rotate, which the page never said and now does not: a rotate records a supplied deadline or now plus the default validity (Operation 61, 62).
